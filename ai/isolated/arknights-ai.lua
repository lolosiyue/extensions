-- Arknights: port the SmartAI branch order using viewer-visible values only.
-- V1 card construction and opponent Slash legality remain explicit coverage gaps.
local function known(value, key)
    if value == nil then ai_unsupported("required visible value is unknown", key) end
    return value
end

local function relation(self, player, key)
    local value = self:relationTo(player)
    if value ~= "friend" and value ~= "enemy" and value ~= "neutral" then
        ai_unsupported("player relation is unknown", key)
    end
    return value
end

local function targets(self, options, key)
    if not options or options.candidates_complete ~= true or not AIValue.isList(options.players) then
        ai_unsupported("complete player candidates are required", key)
    end
    local result = AIList.new({})
    for _, name in ipairs(options.players) do
        local player = self.room:findPlayerByObjectName(name)
        if not player then ai_unsupported("candidate is absent from the visible roster", key) end
        result:append(player)
    end
    return result
end

local function choose_many(options, names, key)
    if type(options.min_count) ~= "number" or type(options.max_count) ~= "number"
        or #names < options.min_count or #names > options.max_count then
        ai_unsupported("legacy selection does not fit the offered bounds", key)
    end
    return names
end

local function active_action(self, key)
    local action = self:getSkillAction()
    if action then
        if action:getActivationSkillName() ~= key then
            ai_unsupported("activation belongs to another skill", key)
        end
    else
        -- General activation has no bound probe; refuse an ambiguous instance.
        for _, candidate in ipairs(known(self:getSkillActions(), key)) do
            if candidate:getActivationSkillName() == key then
                if action then ai_unsupported("activation instance is ambiguous", key) end
                action = candidate
            end
        end
    end
    if not action or not action:isValid() then ai_unsupported("activation ticket is missing", key) end
    return action
end

-- The legacy card counter includes view-as responses. Do not replace an unknown
-- conversion with a physical-card count when deciding whether revival is needed.
local function rescue_count(self, key)
    for _, skill in ipairs(known(self.player:getSkills(), key)) do
        if not skill:isInvalid() then
            local capability = skill._view.has_view_as_skill
            if capability == nil or capability then
                ai_unsupported("rescue view-as counting is not covered", key)
            end
        end
    end
    return known(self:getCardsNum("Peach"), key) + known(self:getCardsNum("Analeptic"), key)
end

ai_skill_activate.ark_guozai = function(self)
    local key = "ark_guozai"
    if known(self.player:getMark("&ark_guozai-PlayClear"), key) >= known(self.player:getMaxHp(), key) then return nil end
    local action = active_action(self, key)
    for _, conversion in ipairs(known(self:getConversions(), key)) do
        if conversion:getActivationSkillName() == key
            and conversion:getActivationOwner() == action:getActivationOwner()
            and conversion:getActivationInstanceId() == action:getActivationInstanceId()
            and conversion:getSourceOwner() == action:getSourceOwner()
            and conversion:getSourceSkillName() == action:getSourceSkillName()
            and conversion:getSourceInstanceID() == action:getSourceInstanceID()
            and conversion:getClassName() == "Slash" then
            -- Exactly the authority-issued Slash replaces the original dummy Slash.
            local plan, status = self:tryUseCard(conversion)
            if status == "unsupported" then error(plan, 0) end
            if status == "planned" then return plan:toAnswer() end
            return nil
        end
    end
    ai_unsupported("ark_guozai requires an authorized Slash conversion", key)
end
sgs.ai_use_priority.ark_guozai = 8

ai_skill_playerchosen.ark_gongzhen = function(self, options)
    local key, enemies = "ark_gongzhen", {}
    for _, player in ipairs(targets(self, options, key)) do
        if relation(self, player, key) == "enemy" then enemies[#enemies + 1] = player end
    end
    if #enemies == 0 then return nil end
    enemies = known(self:sort(enemies, "defense"), key)
    if known(self.player:hasFlag("ark_gongzhenBasicCard"), key) then
        for _, player in ipairs(enemies) do
            if known(player:getMark("&ark_gongzhen_recordtypeBasicCard"), key) == 0
                or known(player:getHandcardNum(), key) >= 3 then return player:objectName() end
        end
    elseif known(self.player:hasFlag("ark_gongzhenTrickCard"), key) then
        -- Reverse the sorted list, including ties, as the original sgs.reverse did.
        local reversed = {}
        for i = #enemies, 1, -1 do reversed[#reversed + 1] = enemies[i] end
        enemies = reversed
        for _, player in ipairs(enemies) do
            if known(player:getMark("&ark_gongzhen_recordtypeTrickCard"), key) == 0 then return player:objectName() end
        end
    elseif known(self.player:hasFlag("ark_gongzhenEquipCard"), key) then
        -- The original equip branch intentionally checks the TrickCard record.
        for _, player in ipairs(enemies) do
            if known(player:getMark("&ark_gongzhen_recordtypeTrickCard"), key) == 0 then return player:objectName() end
        end
    end
    return enemies[math.random(1, #enemies)]:objectName()
end

ai_skill_invoke.ark_jianmo = function(self)
    for _, player in ipairs(known(self.room:getAlivePlayers(), "ark_jianmo")) do
        if known(player:hasFlag("ark_jianmotarget"), "ark_jianmo") then
            return relation(self, player, "ark_jianmo") == "enemy"
        end
    end
    return nil
end

local function select_relation(self, options, key, predicate)
    local result = {}
    for _, player in ipairs(targets(self, options, key)) do
        if predicate(relation(self, player, key)) then result[#result + 1] = player:objectName() end
    end
    return choose_many(options, result, key)
end
ai_skill_playerschosen.ark_jianmo = function(self, options)
    return select_relation(self, options, "ark_jianmo", function(value) return value == "enemy" end)
end
ai_skill_playerschosen.ark_jianyu = function(self, options)
    return select_relation(self, options, "ark_jianyu", function(value) return value ~= "enemy" end)
end

ai_skill_activate.ark_zhuilie = function(self)
    local key = "ark_zhuilie"
    local enemies = known(self.enemies, key)
    if #enemies == 0 then return nil end
    local action = active_action(self, key)
    local ordered = known(self:sort(enemies, "hp"), key)
    local hp = known(self.player:getHp(), key)
    for _, enemy in ipairs(ordered) do
        -- Retain the original short circuit: hp > 1 needs no canSlash query.
        if hp > 1 then
            return {kind = "use_card", skill_action = action:toAnswer(), targets = {enemy:objectName()}}
        end
        -- The next operand is enemy:canSlash; later rescue/card-count operands
        -- must not hide this unprojected legality query or change its ordering.
        ai_unsupported("opponent Slash legality is not projected", key)
    end
end

ai_skill_playerschosen.ark_tanshuo = function(self, options)
    local key, enemies, nonfriends = "ark_tanshuo", {}, {}
    local candidates = targets(self, options, key)
    for _, player in ipairs(candidates) do
        local value = relation(self, player, key)
        if value == "enemy" then enemies[#enemies + 1] = player:objectName() end
        if value ~= "friend" then nonfriends[#nonfriends + 1] = player:objectName() end
    end
    if #enemies > 0 then return choose_many(options, enemies, key) end
    if #nonfriends > 0 then return choose_many(options, nonfriends, key) end
    if #candidates == 0 then ai_unsupported("no offered player", key) end
    return choose_many(options, {candidates[math.random(1, #candidates)]:objectName()}, key)
end

ai_skill_invoke.ark_zhige = function(self)
    return relation(self, known(self:getDecisionContext().player, "ark_zhige"), "ark_zhige") == "enemy"
end

ai_skill_choice.ark_wanxiang = function(self, options)
    local key, items = "ark_wanxiang", {}
    if not options or not AIValue.isList(options.choices) or #options.choices == 0 then
        ai_unsupported("offered choices are missing", key)
    end
    local chongying = known(self.player:getMark("&ark_chongying"), key)
    local fuchen = known(self.player:getMark("&ark_fuchen"), key)
    for _, choice in ipairs(options.choices) do
        if not (choice == "ark_chongying" and chongying > 0)
            and not (choice == "ark_fuchen" and fuchen > 0) then items[#items + 1] = choice end
    end
    if math.random(1, 2) == 1 then
        for _, choice in ipairs(options.choices) do if choice == "ark_wowu" then return choice end end
        ai_unsupported("legacy ark_wowu choice was not offered", key)
    end
    if #items == 0 then ai_unsupported("legacy random choice pool is empty", key) end
    return items[math.random(1, #items)]
end

ai_skill_invoke.ark_zhuye = function(self)
    return rescue_count(self, "ark_zhuye") < 1 - known(self.player:getHp(), "ark_zhuye")
end
ai_skill_playerchosen.ark_poxiao = function(self, options)
    local key, enemies = "ark_poxiao", {}
    for _, player in ipairs(targets(self, options, key)) do
        if relation(self, player, key) == "enemy" then enemies[#enemies + 1] = player end
    end
    if #enemies == 0 then return nil end
    return known(self:sort(enemies, "hp"), key)[1]:objectName()
end

sgs.ai_ajustdamage_from.ark_douzheng = function(self, from, to)
    if from:objectName() ~= to:objectName() then return 1 end
end
sgs.ai_ajustdamage_from.ark_chujue = function(self, from, to)
    if from:objectName() ~= to:objectName() then return known(to:getLostHp(), "ark_chujue") - 1 end
end
sgs.ai_ajustdamage_from["&ark_chongying"] = function(self, from, to)
    if from:objectName() ~= to:objectName() then return math.min(known(to:getMark("&ark_chongying"), "ark_chongying"), 3) end
end
sgs.ai_ajustdamage_from.ark_zhuye = function(self, from)
    if known(from:getMark("&ark_zhuye"), "ark_zhuye") > 0 then return 1 end
end
sgs.ai_canNiepan_skill.ark_zhuye = function(player)
    return known(player:getMark("@ark_zhuye_mark"), "ark_zhuye") > 0
end
sgs.ai_use_revises.ark_yaoyang = function(self, card)
    if card:isKindOf("Slash") then
        -- CardView is immutable; an unconsumed use.card_flags field would silently
        -- drop Qinggang's effect. Keep this branch unhandled until it is projected.
        ai_unsupported("Qinggang planning effects are not projected", "ark_yaoyang")
    end
end
sgs.double_slash_skill = (sgs.double_slash_skill or "") .. "|ark_yaoyang"
sgs.exclusive_skill = (sgs.exclusive_skill or "") .. "|ark_tanshuo"
