-- Animecard isolated AI.  Weapon and card hooks retain the legacy branch order,
-- while card construction and target legality remain authority-owned.

sgs.weapon_range = sgs.weapon_range or {}
sgs.ai_weapon_value = sgs.ai_weapon_value or {}
sgs.ai_slash_weaponfilter = sgs.ai_slash_weaponfilter or {}
sgs.weapon_range.GreenRose = 2
sgs.weapon_range.Elucidator = 2

sgs.ai_weapon_value.GreenRose = function(self, enemy, player)
    if not enemy then return 5 end
    local armor = enemy:getArmor()
    local equips = enemy:getEquips()
    local lion = enemy:hasArmorEffect("SilverLion")
    if not equips or lion == nil then return ai_unsupported("GreenRose armor projection is unknown", "GreenRose") end
    if not lion and armor then return 6 end
    return 6
end
sgs.ai_slash_weaponfilter.GreenRose = function(self, to)
    local armor, equips, lion = to:getArmor(), to:getEquips(), to:hasArmorEffect("SilverLion")
    if not equips or lion == nil then return ai_unsupported("GreenRose armor projection is unknown", "GreenRose") end
    return armor ~= nil and not lion
end

sgs.ai_weapon_value.Elucidator = function(self, enemy, player)
    if not enemy then return 0 end
    local hand, owner_hand = enemy:getHandcardNum(), player:getHandcardNum()
    if hand == nil or owner_hand == nil then return ai_unsupported("Elucidator hand count is unknown", "Elucidator") end
    if hand < 3 and owner_hand > 2 then return 4 end
    if player:hasSkill("se_erdao") or player:hasSkill("LuaChanshi") then return 6 end
    return 3
end
sgs.ai_slash_weaponfilter.Elucidator = function(self, to)
    local hand = to:getHandcardNum()
    if hand == nil then return ai_unsupported("Elucidator hand count is unknown", "Elucidator") end
    return hand < 3
end

local function context(self, options, request, key)
    local value
    if type(self.getDecisionContext) == "function" then
        value = self:getDecisionContext(request)
    end
    if type(value) ~= "table" then return ai_unsupported("decision context is unknown", key) end
    return value
end
local function target(self, value, key)
    if type(value) == "table" and type(value.objectName) == "function" then return value end
    if type(value) ~= "string" then return ai_unsupported("target is unknown", key) end
    local result = self.room:findPlayerByObjectName(value)
    if not result then return ai_unsupported("target is not visible", key) end
    return result
end
local function rel(self, value, key)
    local relation = self:relationTo(value)
    if relation ~= "friend" and relation ~= "enemy" and relation ~= "neutral" then return ai_unsupported("target relation is unknown", key) end
    return relation
end

ai_skill_invoke["Se_Elucidator"] = function(self, options, request)
    local ctx = type(self.getDecisionContext) == "function"
        and self:getDecisionContext(request) or nil
    if type(ctx) ~= "table" then return ai_unsupported("Elucidator effect context is unknown", "Se_Elucidator") end
    local victim = ctx.effect and ctx.effect.to
    if not victim then return ai_unsupported("Elucidator damage target is not projected", "Se_Elucidator") end
    -- The legacy dummy Duel may be virtual.  Without an authority conversion
    -- ticket its card identity and costs are unknown, so do not substitute a
    -- physical Duel from hand or silently decline.
    return ai_unsupported("Elucidator virtual Duel conversion is not projected", "Se_Elucidator")
end

sgs.ai_use_value.reijyuu = 9
sgs.ai_use_priority.reijyuu = 4.55
sgs.ai_keep_value.reijyuu = 1.0
sgs.ai_card_intention.reijyuu = 40

ai_card_use.reijyuu = function(self, card, use)
    if self:isModeManaged() ~= true then return ai_unsupported("reijyuu mode policy is unknown", "reijyuu") end
    if type(self.enemies) ~= "table" then return ai_unsupported("reijyuu enemies are unknown", "reijyuu") end
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate then ai_unsupported("reijyuu has no authority candidate", "reijyuu") end
    local weak
    for _, enemy in ipairs(self.enemies or {}) do
        local is_weak = self:isWeak(enemy)
        if is_weak == nil then return ai_unsupported("reijyuu weakness is unknown", "reijyuu") end
        if is_weak then weak = enemy end
    end
    -- Legacy walks self.enemies in order and picks the first entry different
    -- from the last weak enemy; retain that order, then accept only an offered row.
    local desired
    for _, enemy in ipairs(self.enemies or {}) do
        if not weak or enemy:objectName() ~= weak:objectName() then desired = enemy; break end
    end
    if not desired then return end
    local page, cursor = candidate:getTargetCombinations()
    if not page then ai_unsupported("reijyuu target combinations are incomplete", "reijyuu") end
    repeat
        for _, row in ipairs(page or {}) do
            if #row == 1 and row[1] == desired:objectName() then
                use.card, use.to = card, AIList.new({desired})
                return
            end
        end
        if cursor then page, cursor = candidate:getTargetCombinations(cursor) else break end
    until false
end

-- The existing legacy-ABI adapter selects the offered Nullification card for
-- true, and continues the default policy for nil, exactly as the original hook.
sgs.ai_nullification.reijyuu = function(self, card, from, to, positive)
    if type(positive) ~= "boolean" or not from or not to then
        ai_unsupported("reijyuu nullification context is incomplete", "reijyuu")
    end
    if positive then
        if rel(self, to, "reijyuu") == "friend" and rel(self, from, "reijyuu") == "enemy" then return true end
    else
        if rel(self, to, "reijyuu") == "enemy" and rel(self, from, "reijyuu") == "friend" then return true end
    end
end

ai_skill_playerchosen.reijyuu = function(self, options)
    local names = type(options) == "table" and options.players
    if type(names) ~= "table" then return ai_unsupported("reijyuu candidates are unknown", "reijyuu") end
    for _, name in ipairs(names) do
        local value = target(self, name, "reijyuu")
        if rel(self, value, "reijyuu") == "enemy" then
            local weak = self:isWeak(value)
            if weak == nil then ai_unsupported("reijyuu weakness is unknown", "reijyuu") end
            if weak then return name end
        end
    end
    for _, name in ipairs(names) do if name == self.player:objectName() then return name end end
    return nil
end

ai_skill_choice.reijyuu = function(self, options, request)
    local choices = options and options.choices
    if type(choices) ~= "table" then return ai_unsupported("reijyuu choices are unknown", "reijyuu") end
    local alive = self.room:getAlivePlayers()
    if not alive then return ai_unsupported("reijyuu alive roster is unknown", "reijyuu") end
    for _, value in ipairs(alive) do
        if type(value.hasFlag) ~= "function" then return ai_unsupported("reijyuu flag projection is unknown", "reijyuu") end
        local flagged = value:hasFlag("reijyuuT")
        if flagged == nil then ai_unsupported("reijyuu flag is unknown", "reijyuu") end
        if flagged then
            local choice = rel(self, value, "reijyuu") == "friend" and "reijyuuMove" or "reijyuuDamage"
            for _, offered in ipairs(choices) do if offered == choice then return choice end end
        end
    end
    for _, offered in ipairs(choices) do if offered == "reijyuuMove" then return offered end end
    return ai_unsupported("reijyuuMove was not offered", "reijyuu")
end

ai_card_use.tacos = function(self, card, use)
    if self:isModeManaged() ~= true then return ai_unsupported("tacos mode policy is unknown", "tacos") end
    if type(self.enemies) ~= "table" or type(self.friends) ~= "table" then
        return ai_unsupported("tacos relation lists are unknown", "tacos")
    end
    for _, enemy in ipairs(self.enemies) do if enemy:hasSkill("eastfast") then return end end
    for _, friend in ipairs(self.friends) do if friend:hasSkill("SE_Jiawu") then return end end
    use.card = card
end
sgs.ai_card_intention.tacos = -40
sgs.ai_keep_value.tacos = 2.5
sgs.ai_use_value.tacos = 8
sgs.ai_use_priority.tacos = 4
sgs.dynamic_value.benefit.tacos = true
