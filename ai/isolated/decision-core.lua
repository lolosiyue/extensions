-- 通用決策流程的隔離版本：估值、排序、威脅評估與回合候選。
-- 全部只靠快照與 request 的候選運作，沒有 gameplay 全域，也不查 Engine。
-- 個別武將策略仍然用註冊表擴充，不寫進這裡。

-- 值型規則註冊表。鍵是牌名或類別名，值是數字或 function(self, card) 回數字。
ai_keep_value = ai_keep_value or {}
ai_use_value = ai_use_value or {}
ai_use_priority = ai_use_priority or {}

-- 拆牌與決鬥這一族的 use／keep 直接取 legacy standard_cards-ai.lua 的數字
-- （Snatch 9／3.46、Dismantlement 5.6／3.44、Duel 3.7／3.42），放進來之後與這裡
-- 既有的項目維持 legacy 的相對順序。priority 不能照搬：legacy 的 9.3／9.4 與這裡
-- 的 0–5 不是同一把尺，所以只搬相對順序（拆 > 順 > 決鬥 > 殺），數字重新落在本尺上。
local default_keep_value = {Peach = 8, Analeptic = 5, Jink = 4, Slash = 3,
    Snatch = 3.46, Dismantlement = 3.44, Duel = 3.42, ExNihilo = 3.9,
    AmazingGrace = -1, GodSalvation = 3.32, Indulgence = 3.5,
    SupplyShortage = 3.4, Lightning = -1, Collateral = 3.4, IronChain = 2.5}
local default_use_value = {Peach = 8, Analeptic = 5, Slash = 4, Jink = 3,
    Snatch = 9, Dismantlement = 5.6, Duel = 3.7, ExNihilo = 9,
    AmazingGrace = 3, GodSalvation = 4.1, Indulgence = 8,
    SupplyShortage = 6, Lightning = 0, Collateral = 5.8, IronChain = 4}
local default_use_priority = {Peach = 5, Analeptic = 4.5, Slash = 4, Jink = 1,
    Dismantlement = 6.2, Snatch = 6.1, Duel = 4.1, ExNihilo = 9,
    AmazingGrace = 1.2, GodSalvation = 4.1, Indulgence = 0.5,
    SupplyShortage = 0.4, Lightning = 0, Collateral = 2.75, IronChain = 2.7}

local function finite_number(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function skill_hooks(self, name, player)
    if type(self.forSkillHooks) ~= "function" then
        ai_unsupported("strategy-hooks.lua must load before decision-core helpers", name)
    end
    return self:forSkillHooks(name, player)
end

local function rule_value(registry, defaults, self, card)
    if not card then return nil end
    local names = {card:objectName(), card:getClassName()}
    for _, name in ipairs(names) do
        local rule = name and registry[name]
        if type(rule) == "function" then
            local value = rule(self, card)
            if type(value) == "number" then
                if not finite_number(value) then ai_unsupported("non-finite card value", name) end
                return value
            end
        elseif type(rule) == "number" then
            if not finite_number(rule) then ai_unsupported("non-finite card value", name) end
            return rule
        end
    end
    for _, name in ipairs(names) do
        local value = name and defaults[name]
        if value then return value end
    end
    return nil
end

function SmartAIView:getKeepValue(card)
    local value = rule_value(ai_keep_value, default_keep_value, self, card)
    if card and card:isKindOf("Peach") then
        -- The reserve hook affects real discard/response/gift cost decisions,
        -- not only a compatibility getter that no decision ever reads.
        local reserve = self:getNeedPeach(self.player)
        if reserve == nil then return nil end
        value = (value or 0) + math.max(0, reserve) * 2
    end
    return value or 0
end

function SmartAIView:getUseValue(card)
    local value = rule_value(ai_use_value, default_use_value, self, card)
    if value == nil then value = 0 end
    -- Equipment value is deliberately small and value-only.  Package hooks can
    -- still account for the owner's visible skills without receiving userdata.
    if card and card:isKindOf("Weapon") then
        local bonus = self:evaluateWeapon(card)
        if bonus == nil then return nil end
        value = value + bonus
    end
    if card and card:isKindOf("Armor") then
        local bonus = self:evaluateArmor(card)
        if bonus == nil then return nil end
        value = value + bonus
    end
    if card then
        local class_name = card:getClassName()
        if sgs.dynamic_value.damage_card[class_name] then value = value + 0.5 end
        if sgs.dynamic_value.benefit[class_name] then value = value + 0.25 end
    end
    return value
end

function SmartAIView:adjustUsePriority(card, value)
    value = value or 0
    if not card then return value end
    -- With no package priority rules there is nothing to inspect. This is the
    -- common path and must not add unrelated skill/colour metadata dependencies.
    if getmetatable(sgs.ai_card_priority) == nil and next(sgs.ai_card_priority) == nil
        and getmetatable(sgs.ai_suit_priority) == nil and next(sgs.ai_suit_priority) == nil then
        return value
    end
    local skills = self.player and self.player:getSkills()
    if not skills then return nil end
    local seen, selected_suit = {}, nil
    for _, skill in ipairs(skills) do
        local key = skill:objectName()
        if not seen[key] and not skill:isInvalid() then
            seen[key] = true
            local rule = sgs.ai_card_priority[key]
            if type(rule) == "table" then
                if type(card.getNumber) ~= "function" or type(card.isRed) ~= "function"
                    or type(card.isBlack) ~= "function" then return nil end
                local suit, number, class_name, object_name = card:getSuitString(),
                    tostring(card:getNumber()), card:getClassName(), card:objectName()
                local color = card:isRed() and "red" or card:isBlack() and "black" or nil
                for _, field in ipairs({suit or false, number, class_name, object_name, color or false,
                    type(card.getSkillName) == "function" and card:getSkillName() or nil}) do
                    local delta = field and rule[field]
                    if finite_number(delta) then value = value + delta end
                end
            elseif type(rule) == "function" then
                local delta = rule(self, card, value)
                if delta ~= nil and not finite_number(delta) then return nil end
                if finite_number(delta) then value = value + delta end
            end
            -- The first active suit rule owns the ordering, matching legacy
            -- adjustUsePriority while keeping the callback ABI value-only.
            local suit_rule = sgs.ai_suit_priority[key]
            if selected_suit == nil and suit_rule ~= nil then
                local order = type(suit_rule) == "function"
                    and suit_rule(self, card) or suit_rule
                if type(order) ~= "string" then return nil end
                selected_suit = order
            end
        end
    end
    -- A suit rule selects only the suit ordering; later card-priority hooks
    -- still run, once per skill name even when multiple instances are visible.
    if selected_suit ~= nil then
        local suit = card:getSuitString()
        if type(suit) ~= "string" then return nil end
        local rank, best = 0, 0
        for name in string.gmatch(selected_suit, "[^|]+") do
            rank = rank + 1
            if name == suit then break end
        end
        if rank > 0 and not selected_suit:find(suit, 1, true) then rank = 0 end
        if rank > 0 then best = (5 - rank) * 0.01 end
        value = value + best
    end
    return value
end

function SmartAIView:getUsePriority(card)
    local value = rule_value(ai_use_priority, default_use_priority, self, card)
    value = value or 0
    local adjusted = self:adjustUsePriority(card, value)
    return adjusted
end

-- 排序一律在副本上做，快照順序不動；同分時用牌 ID 保持穩定，避免不同 VM 排出不同結果。
local function sorted_copy(cards, score, ascending)
    if not AIValue.isList(cards) then return nil end
    local result = AIList.new({})
    for _, card in ipairs(cards) do result[#result + 1] = card end
    local scores = {}
    for _, card in ipairs(result) do
        local value = score(card)
        -- Unknown equipment/skill values cannot become a known zero ranking.
        if not finite_number(value) then return nil end
        scores[card] = value
    end
    table.sort(result, function(first, second)
        if scores[first] ~= scores[second] then
            if ascending then return scores[first] < scores[second] end
            return scores[first] > scores[second]
        end
        return (first:getEffectiveId() or 0) < (second:getEffectiveId() or 0)
    end)
    return result
end

function SmartAIView:sortByKeepValue(cards, descending)
    return sorted_copy(cards, function(card) return self:getKeepValue(card) end, not descending)
end

function SmartAIView:sortByUseValue(cards, ascending)
    return sorted_copy(cards, function(card) return self:getUseValue(card) end, ascending == true)
end

function SmartAIView:sortByUsePriority(cards, ascending)
    return sorted_copy(cards, function(card) return self:getUsePriority(card) end, ascending == true)
end

-- 快照沒有這個欄位時，getter 本身就不存在；先確認再呼叫，缺值回 fallback，
-- 不讓一個少掉的欄位變成 "attempt to call a nil value"。
local function scalar(player, method_name, fallback)
    local getter = player and player[method_name]
    if type(getter) ~= "function" then return fallback end
    local value = getter(player)
    if type(value) ~= "number" then return fallback end
    return value
end

-- 相容版 self:sort(players, key, anti)：回排序過的副本，快照順序不動。
-- 與舊版的兩點差別都是刻意的：
--   1. 同分用 object name 決勝，不用 sgs.ai_compare_funcs.chaofeng，也不用 os.time 快取——
--      牆鐘會讓同一個局面在兩次執行排出不同順序，違反決定性要求。
--   2. 快照答不出來的鍵（例如 chaofeng）回 nil，不偷偷退回 defense：舊版對打錯的鍵
--      靜默改排防禦，那是缺陷，不是契約。
local sort_keys = {
    defense = function(self, player) return self:getDefense(player) or 0 end,
    chaofeng = function(self, player) return self:getChaofeng(player) end,
    hp = function(self, player)
        return scalar(player, "getHp", 0) + scalar(player, "getHujia", 0)
    end,
    HP = function(self, player) return scalar(player, "getHp", 0) end,
    maxhp = function(self, player) return scalar(player, "getMaxHp", 0) end,
    maxcards = function(self, player) return scalar(player, "getMaxCards", 0) end,
    handcard = function(self, player) return scalar(player, "getHandcardNum", 0) end,
    equip = function(self, player) return #(player:getEquips() or {}) end,
    card = function(self, player)
        return scalar(player, "getHandcardNum", 0) + #(player:getEquips() or {})
    end
}

function SmartAIView:sort(players, key, anti)
    if not AIValue.isList(players) then return nil end
    local score = sort_keys[key == nil and "defense" or key]
    if not score then return nil end
    local result = AIList.new({})
    for _, player in ipairs(players) do result[#result + 1] = player end
    local scores = {}
    for _, player in ipairs(result) do
        scores[player] = score(self, player)
        if scores[player] == nil then return nil end
    end
    table.sort(result, function(first, second)
        if scores[first] ~= scores[second] then
            if anti then return scores[first] > scores[second] end
            return scores[first] < scores[second]
        end
        return first:objectName() < second:objectName()
    end)
    return result
end

-- 威脅與防禦評估：只用快照裡的公開值與自己看得見的牌，缺資料就回 nil。
function SmartAIView:getCardsNum(class_name, player)
    player = player or self.player
    local cards = player:getKnownCards()
    if not cards then return nil end
    local count = 0
    for _, card in ipairs(cards) do
        if card:isKindOf(class_name) or card:objectName() == class_name then
            count = count + 1
        end
    end
    return count
end

-- 已知與估計是兩個答案（計畫 §6.3）。上面的 getCardsNum 只數看得見的牌：別人的
-- 暗牌在那裡是「沒看到」，不是「沒有」。要把暗牌算進去的呼叫者改用 estimateCardsNum，
-- 拿回來的是估計值，而且呼叫端知道自己拿到的是估計值。

-- 這名玩家有幾張牌是這個觀察者看不見的。手牌全開時是 0；快照答不出張數時回 nil。
function SmartAIView:getUnknownCardsNum(player)
    player = player or self.player
    local total = player:getHandcardNum()
    if type(total) ~= "number" then return nil end
    local known = player:getKnownCards()
    if not known then return total end
    local unknown = total - #known
    if unknown < 0 then return 0 end
    return unknown
end

-- 暗牌裡大概有幾張這種牌。密度取自本倉庫 standard 牌堆的實際張數
-- （108 張裡殺 30、閃 15、桃 8，見 src/package/standard-cards.cpp 的牌表）。
-- 換牌包會讓這個比例偏掉，這是估計不是規則；沒有登記密度的牌名回 nil，
-- 讓呼叫者知道這裡沒有可用的估計，而不是拿到一個看起來像已知的 0。
local unknown_density = {Slash = 30 / 108, Jink = 15 / 108, Peach = 8 / 108}

function SmartAIView:estimateCardsNum(class_name, player)
    player = player or self.player
    local known = self:getCardsNum(class_name, player)
    if known == nil then return nil end
    local unknown = self:getUnknownCardsNum(player)
    if unknown == nil then return nil end
    if unknown <= 0 then return known end
    local density = unknown_density[class_name]
    if density == nil then return nil end
    return known + unknown * density
end

function SmartAIView:getDefense(player)
    player = player or self.player
    local hp = player:getHp()
    if type(hp) ~= "number" then return nil end
    local defense = hp
    local hujia = player:getHujia()
    if type(hujia) == "number" then defense = defense + hujia end
    local jinks = self:getCardsNum("Jink", player)
    if jinks then defense = defense + jinks end
    -- 看不見的手牌按張數折算，明說這是估計而不是已知。
    local unknown = (player:getHandcardNum() or 0) - #(player:getKnownCards() or {})
    if unknown > 0 then defense = defense + unknown * 0.4 end
    local peaches = self:getCardsNum("Peach", player)
    if peaches then defense = defense + peaches * 1.5 end
    local hooks = skill_hooks(self, "ai_skill_defense", player)
    if not hooks then return nil end
    for _, hook in ipairs(hooks) do
        local bonus = self:callHook("ai_skill_defense", hook.key, self, player)
        if bonus ~= nil and not finite_number(bonus) then return nil end
        defense = defense + (bonus or 0)
    end
    return defense
end

function SmartAIView:getNeedPeach(player)
    player = player or self.player
    if not player then return nil end
    local value = sgs.ai_NeedPeach[player:objectName()]
    if type(value) == "function" then value = value(self, player) end
    if value ~= nil then return finite_number(value) and value or nil end
    return 0
end

function SmartAIView:isWeak(player)
    local defense = self:getDefense(player)
    if defense == nil then return nil end
    local hp = (player or self.player):getHp()
    return defense <= 2.5 or hp <= 1
end

function SmartAIView:getThreat(player)
    -- 威脅是「他能打到我多重」：攻擊牌數量加上能打到的距離優勢。
    player = player or self.player
    local slashes = self:getCardsNum("Slash", player)
    if slashes == nil then return nil end
    local threat = slashes
    if self.player:inMyAttackRange(player) then threat = threat + 1 end
    if player:inMyAttackRange(self.player) then threat = threat + 1 end
    return threat
end

function SmartAIView:getChaofeng(player)
    player = player or self.player
    if not player then return nil end
    local value = sgs.ai_chaofeng[player:objectName()]
    if type(value) == "function" then value = value(self, player) end
    -- Missing policy data remains uncovered; zero must be an explicit value.
    return finite_number(value) and value or nil
end

-- These two evaluators are the pure-value counterparts of evaluateWeapon and
-- evaluateArmor.  Range/effect legality stays with the authority projection;
-- callbacks only receive the same value facade ABI as legacy SmartAI.
function SmartAIView:evaluateWeapon(card, owner, target)
    owner = owner or self.player
    if not card or not card:isKindOf("Weapon") or not owner then return -1 end
    local value, in_attack_range = 0, false
    local range = type(card.getRange) == "function" and card:getRange() or nil
    if range == nil and type(sgs.weapon_range) == "table" then
        range = sgs.weapon_range[card:getClassName()]
    end
    if not finite_number(range) or range < 1 then return nil end
    local candidates = target and AIList.new({target}) or self.room:getOtherPlayers(owner)
    if not candidates or not owner:getSkills() then return nil end
    local callback = sgs.ai_weapon_value[card:objectName()]
    if type(callback) == "number" then
        if not finite_number(callback) then return nil end
        value = value + callback
    elseif type(callback) == "function" then
        local base = callback(self, nil, owner)
        if base ~= nil and not finite_number(base) then return nil end
        value = value + (base or 0)
    end
    -- Target callbacks are additive to the owner baseline. Scan the visible
    -- enemies once; projected distance and the offered weapon's range suffice.
    for _, enemy in ipairs(candidates) do
        local relation = target and "enemy" or self:relationTo(enemy, owner)
        if relation == nil or relation == "unknown" then return nil end
        if relation == "enemy" then
            local distance = owner:distanceTo(enemy)
            if not finite_number(distance) then return nil end
            if distance > 0 and distance <= range then
                in_attack_range = true
                if type(callback) == "function" then
                    local filter = sgs.ai_slash_weaponfilter[card:objectName()]
                    if type(filter) == "function" then
                        local extra = filter(self, enemy, owner)
                        if extra ~= nil and type(extra) ~= "boolean" then return nil end
                        if extra then value = value + 1 end
                    end
                    local bonus = callback(self, enemy, owner)
                    if bonus ~= nil and not finite_number(bonus) then return nil end
                    value = value + (bonus or 0)
                end
            end
        end
    end
    if card:isKindOf("Weapon") and owner:hasSkills("jijiu") and card:isRed() then value = value + 0.5 end
    if card:isKindOf("Weapon") and owner:hasSkills("qixi|guidao") and card:isBlack() then value = value + 0.5 end
    return value, in_attack_range
end

function SmartAIView:evaluateArmor(card, owner)
    owner = owner or self.player
    if not owner then return nil end
    if card == nil then
        if owner:getEquips() == nil then return nil end
        card = owner:getArmor()
    end
    local value, seen = 0, {}
    local skills = owner:getSkills()
    if not skills then return nil end
    for _, skill in ipairs(skills) do
        local key = skill:objectName()
        if not seen[key] and not skill:isInvalid() then
            seen[key] = true
            local callback = sgs.ai_armor_value[key]
            if type(callback) == "number" then
                if not finite_number(callback) then return nil end
                value = value + callback
            elseif type(callback) == "function" then
                local result = callback(owner, self, card)
                if result ~= nil and not finite_number(result) then return nil end
                value = value + (result or 0)
            end
        end
    end
    if card then
        value = value + 0.1
        if owner:hasSkill("jijiu") and card:isRed() then value = value + 0.5 end
        if owner:hasSkills("qixi|guidao") and card:isBlack() then value = value + 0.5 end
        local callback = sgs.ai_armor_value[card:objectName()]
        if type(callback) == "number" then
            if not finite_number(callback) then return nil end
            value = value + callback
        elseif type(callback) == "function" then
            local result = callback(owner, self, card)
            if result ~= nil and not finite_number(result) then return nil end
            value = value + (result or 0)
        end
    end
    return value
end

-- 回合候選：把 request 的合法候選轉成值型出牌方案，按優先序排好。
-- 這裡只產生「可以這樣打」的清單，要不要打、打誰由上層決定。
function SmartAIView:bindConversionCosts(conversion, owned_by_id)
    if not AIValue.isConversion(conversion) then
        ai_unsupported("conversion cost binding needs a conversion", "conversion")
    end
    local getter = conversion.getCostCount
    local declared = type(getter) == "function" and getter(conversion) or nil
    if declared ~= nil and (not finite_number(declared) or declared < 0 or declared % 1 ~= 0) then
        ai_unsupported("conversion cost count is invalid", "conversion")
    end
    -- The facade's parameterized protocol starts at two cards. Fixed tickets
    -- already carry authority-bound subcards, even when cost_count is annotated.
    if declared == nil or declared < 2 then
        local subcards = conversion:getSubcards()
        -- Native cost_count=0 means an exact-subcards ticket, not a free card.
        if not subcards or (declared == 1 and #subcards ~= declared) then
            ai_unsupported("fixed conversion costs are incomplete", "conversion")
        end
        return conversion
    end
    local eligible, count = conversion:getCostSelection()
    if not eligible or count ~= declared then
        ai_unsupported("conversion cost projection is incomplete", "conversion")
    end
    owned_by_id = owned_by_id or {}
    local payments, seen = {}, {}
    for _, id in ipairs(eligible) do
        if not finite_number(id) or id < 0 or id % 1 ~= 0 then
            ai_unsupported("conversion cost id is invalid", "conversion")
        end
        if not seen[id] then
            seen[id] = true
            local card = owned_by_id[id]
            if not card or card:getId() ~= id then ai_unsupported("unknown conversion cost", "conversion") end
            local value = self:getKeepValue(card)
            if not finite_number(value) then ai_unsupported("invalid conversion cost value", "conversion") end
            payments[#payments + 1] = {id = id, value = value}
        end
    end
    local ids = {}
    -- O(k*n) minimum selection; score each unique card once, never pay an ID
    -- twice. withSubcards checks membership/count, not coupled native rules.
    for index = 1, count do
        local best, best_index
        for payment_index, payment in ipairs(payments) do
            if not best or payment.value < best.value
                or (payment.value == best.value and payment.id < best.id) then
                best, best_index = payment, payment_index
            end
        end
        if not best then ai_unsupported("conversion cost is too short", "conversion") end
        ids[index] = best.id
        table.remove(payments, best_index)
    end
    local bound = conversion:withSubcards(ids)
    if not bound then ai_unsupported("conversion cost membership rejected", "conversion") end
    return bound
end
function SmartAIView:getTurnUse(allow_partial)
    local candidates, conversions = self:getCardCandidates(), self:getConversions()
    local unknown
    local function record(reason, key)
        local signal = AIUnsupported.new(reason, key)
        if not allow_partial then error(signal, 0) end
        unknown = unknown or signal
    end
    if not candidates then
        if not allow_partial then return nil end
        record("physical candidate projection is unknown", "candidate")
    end
    local by_id = {}
    for _, cards in ipairs({self.player:getHandcards() or {}, self.player:getEquips() or {}}) do
        for _, card in ipairs(cards) do by_id[card:getId()] = card end
    end
    local uses = AIList.new({})
    local function append(card, candidate, candidate_id)
        local targets = candidate:getLegalTargets()
        local rows = candidate:getTargetCombinations()
        if candidate:hasCompleteCoverage() ~= true or not targets or not rows then
            ai_unsupported("target combinations are incomplete", card:getClassName())
        end
        if #rows > 0 then
            uses:append({card = card, card_id = card:getEffectiveId(), candidate_id = candidate_id,
                targets = targets, target_fixed = candidate:targetFixed(),
                needs_a_target = candidate:needsATarget(), priority = self:getUsePriority(card),
                value = self:getUseValue(card)})
        end
    end
    local function collect(fn)
        local ok, signal = AIUnsupported.capture(fn)
        if not ok then
            if not allow_partial then error(signal, 0) end
            unknown = unknown or signal
        end
    end
    for _, candidate in ipairs(candidates or {}) do
        collect(function()
            if type(candidate.isAvailable) ~= "function" or type(candidate.isLimited) ~= "function" then
                ai_unsupported("physical availability is unknown", "candidate")
            end
            local available, limited = candidate:isAvailable(), candidate:isLimited()
            if available == false or limited == true then return end
            if available ~= true or limited ~= false then ai_unsupported("physical availability is unknown", "candidate") end
            local card = by_id[candidate:getCardId()]
            if not card then ai_unsupported("candidate card metadata is unknown", "candidate") end
            append(card, candidate, candidate:getCandidateId())
        end)
    end
    if not conversions and allow_partial then record("conversion projection is unknown", "conversion") end
    for _, conversion in ipairs(conversions or {}) do
        collect(function()
            if type(conversion.isAvailable) ~= "function" then
                ai_unsupported("conversion availability is unknown", "conversion")
            end
            local available = conversion:isAvailable()
            if available == false then return end
            if available ~= true then ai_unsupported("conversion availability is unknown", "conversion") end
            local bound = self:bindConversionCosts(conversion, by_id)
            append(bound, bound)
        end)
    end
    if #uses > 128 then ai_unsupported("candidate budget exceeded", "planning") end
    table.sort(uses, function(first, second)
        if first.priority ~= second.priority then return first.priority > second.priority end
        if first.value ~= second.value then return first.value > second.value end
        return first.card_id < second.card_id
    end)
    return uses, unknown
end
-- 共用的目標排序。activate、aiUseCard 與每一張牌的策略都只用這一份：同一張牌無論
-- 由哪條路徑問，挑出來的人要一樣。stance 說這張牌想打誰——傷害牌找敵人，增益牌找
-- 友軍，"any" 才照原順序全收。回傳 PlayerView，不是名字。
function SmartAIView:rankTargets(target_names, stance)
    if not AIValue.isList(target_names) then return nil end
    stance = stance or "any"
    local ranked = {}
    for _, name in ipairs(target_names) do
        local target = self.room:findPlayerByObjectName(name, true)
        if not target then return nil end -- Missing roster data is not an empty target set.
        ranked[#ranked + 1] = {name = name, player = target}
    end
    -- 關係未知就是不知道，不是「沒有敵人」，也不是「誰都可以打」：認得出陣營才
    -- 排得出敵友，認不出時只有 "any" 還答得出東西。
    if not self:isModeManaged() then
        if stance ~= "any" then return nil end
        local plain = AIList.new({})
        for index, entry in ipairs(ranked) do plain[index] = entry.player end
        return plain
    end
    for _, entry in ipairs(ranked) do
        local relation = self:relationTo(entry.player)
        -- A managed policy may still leave this particular relationship unknown.
        if stance ~= "any" and (relation == nil or relation == "unknown") then return nil end
        entry.enemy = relation == "enemy"
        entry.friend = relation == "friend"
        entry.score = (entry.enemy and 100 or 0)
            + (self:isWeak(entry.player) and 10 or 0)
            + (self:getThreat(entry.player) or 0)
    end
    table.sort(ranked, function(first, second)
        if first.score ~= second.score then return first.score > second.score end
        return first.name < second.name
    end)
    local chosen = AIList.new({})
    for _, entry in ipairs(ranked) do
        local wanted = stance == "any"
            or (stance == "enemy" and entry.enemy)
            or (stance == "friend" and entry.friend)
        if wanted then chosen[#chosen + 1] = entry.player end
    end
    return chosen
end

-- 名字版的薄入口，保留舊呼叫方式；排序本身還是上面那一份。
function SmartAIView:pickTargets(use, count)
    if type(use) ~= "table" or not use.targets then return nil end
    count = count or 1
    local ranked = self:rankTargets(use.targets, "enemy")
    if not ranked then return nil end
    local chosen = AIList.new({})
    for _, target in ipairs(ranked) do
        if #chosen >= count then break end
        chosen[#chosen + 1] = target:objectName()
    end
    return chosen
end

-- 出牌計劃：作者看到的 use。沿用舊寫法——use.card 有值代表「打算這樣打」，
-- use.to 是目標集合，append／first／length／isEmpty 都在。差別只有兩點且不可混淆：
-- use.to 是純 Lua 的 AIList，不是 SPlayerList；裡面是 PlayerView，不是 ServerPlayer。
AIUsePlan = {}
AIUsePlan.__index = AIUsePlan

function AIUsePlan.new()
    return setmetatable({to = AIList.new({})}, AIUsePlan)
end

-- 轉成值型答案。目標只送 object name，權威端自己重查人、重驗完整目標；
-- 這裡不宣稱這個組合合法，只宣稱「策略想這樣打」。
function AIUsePlan:toAnswer()
    if not self.card then return nil end
    local answer = {kind = "use_card"}
    -- 轉化送的是票。牌名／花色／點數／成本一起送，只是讓權威端能比對出不一致並拒絕；
    -- 授權來自票，不來自這些欄位，所以偽造其中任何一欄都只會被擋下。
    if AIValue.isConversion(self.card) then
        answer.card_spec = self.card:toCardSpec()
    elseif self.card_spec ~= nil then
        answer.card_spec = self.card_spec
    else
        local id = self.card:getEffectiveId()
        if type(id) ~= "number" then return nil end
        answer.card_id = id
        -- 實體牌也帶票：持有一張牌不等於這一題問過它。權威端沒有發票給這個候選時
        -- （candidate_id 是 -1），就不要宣稱有票——送一個不存在的票號比不送更糟。
        local candidate = self.candidate_id
        if type(candidate) == "number" and candidate >= 0 then
            answer.candidate_id = candidate
        end
    end
    if self.to and #self.to > 0 then
        local names = {}
        for index, target in ipairs(self.to) do names[index] = target:objectName() end
        answer.targets = names
    end
    return answer
end

-- 牌策略註冊表。鍵是牌名（objectName）或類別名（getClassName），值是
-- function(self, card, use)，參數順序與舊 SmartAI:useCardXXX 相同。
-- 舊寫法 function SmartAIView:useCardSlash(card, use) 仍然有效：那是同一組策略的薄入口，
-- 不是第二套演算法。查找順序固定：牌名 → 類別名 → useCard<類別名>。
ai_card_use = ai_card_use or {}

local function find_card_use(card)
    local object_name = card:objectName()
    if type(object_name) == "string" and object_name ~= ""
        and type(ai_card_use[object_name]) == "function" then
        return ai_card_use[object_name], object_name
    end
    local class_name = card:getClassName()
    if type(class_name) ~= "string" or class_name == "" then
        return nil, type(object_name) == "string" and object_name or nil
    end
    if type(ai_card_use[class_name]) == "function" then
        return ai_card_use[class_name], class_name
    end
    local legacy = sgs.ai_skill_use_func or {}
    local names = {class_name, object_name}
    if card:isKindOf("LuaSkillCard") then names = {"#" .. object_name, class_name, object_name} end
    if card:isKindOf("ActiveSkillCard") and type(card.getSkillName) == "function" then
        names = {card:getSkillName(), class_name, object_name}
    end
    for _, name in ipairs(names) do
        if type(legacy[name]) == "function" then
            return function(self, offered, use)
                local request = AILegacyRequest.new(self.request, self.room)
                return legacy[name](offered, use, self, request)
            end, name
        end
    end
    -- Family fallbacks preserve the legacy `useBasicCard`/`useTrickCard` breadth
    -- without claiming an extension-specific effect is understood.
    local family = card:isKindOf("EquipCard") and "EquipCard"
        or card:isKindOf("AOE") and "AOE"
        or card:isKindOf("GlobalEffect") and "GlobalEffect"
        or card:isKindOf("DelayedTrick") and "DelayedTrick"
        or nil
    if family and type(ai_card_use[family]) == "function" then
        return ai_card_use[family], family
    end
    local method = rawget(SmartAIView, "useCard" .. class_name)
    if type(method) == "function" then return method, class_name end
    return nil, class_name
end

-- 規劃一張牌怎麼用，不真的出牌。沒有這張牌的策略就是未覆蓋，不是「決定不出牌」：
-- 預設丟出受控訊號記錄未知；整合規劃器可繼續評估其他已授權候選。要比較多個候選、自己決定怎麼
-- 處理未覆蓋的呼叫者改用 tryUseCard，拿回 (plan, status) 自己判斷。
function SmartAIView:aiUseCard(card, use)
    local plan, status = self:tryUseCard(card, use)
    if status == "unsupported" then error(plan, 0) end
    return plan
end

SmartAIView.aiUsecard = SmartAIView.aiUseCard

-- status：planned（提出計劃）／declined（有策略，決定不打）／unsupported（接不住）。
-- 三者分開，因為最外層對它們的處置不同：前兩者可以作答，最後一個必須保留未覆蓋原因。
-- Private counters cannot be reset by writing scratch. All nested branches share
-- one request budget; only their pure-value reservations are copied.
local planning = setmetatable({}, {__mode = "k"})
-- Dispatch starts a new decision explicitly. Replacing public scratch during a
-- decision must not replenish its private budget or change the saved context.
function SmartAIView.resetPlanning(request)
    planning[request] = nil
end

-- Shared SmartAI helper compatibility.  These helpers consume only value facades;
-- skill/card callbacks are optional pure hooks and never receive engine userdata.
-- Preserve each legacy callback ABI explicitly; never infer arguments from strings.
local function known_skill(player, skill)
    return player and player:hasSkill(skill) == true
end
local function category(player, name)
    local names = sgs[name]
    return type(names) == "string" and player:hasSkills(names) == true
end
local function mark_value(player, name)
    return player:getMark(name)
end
local function count_cards(player)
    local hand, equips = scalar(player, "getHandcardNum"), player:getEquips()
    if hand == nil or equips == nil then return nil end
    return hand + #equips
end

function SmartAIView:getLeastHandcardNum(player)
    player = player or self.player
    local least = player:hasSkills("lianying|noslianying|kezhuanmanjuan") and 1 or 0
    if known_skill(player, "shoucheng") then least = math.max(least, 1) end
    -- The snapshot is immutable for this decision. Index the small set of
    -- support owners once instead of rebuilding every player's friend list
    -- inside card-need/draw scans (which otherwise scan the room quadratically).
    local supporters = rawget(self, "_least_handcard_supporters")
    if supporters == nil then
        supporters = {}
        for _, owner in ipairs(self.room:getAlivePlayers() or {}) do
            if known_skill(owner, "shoucheng") then supporters[#supporters + 1] = owner end
        end
        rawset(self, "_least_handcard_supporters", supporters)
    end
    for _, owner in ipairs(supporters) do
        if self:isFriend(owner, player) then
            least = math.max(least, 1)
            break
        end
    end
    local hp, max_hp = scalar(player, "getHp"), scalar(player, "getMaxHp")
    if player:hasSkills("shangshi|nosshangshi") then
        if hp == nil or max_hp == nil then return nil end
        local lost = math.max(0, max_hp - hp)
        if known_skill(player, "shangshi") then least = math.max(least, math.min(2, lost)) end
        if known_skill(player, "nosshangshi") then least = math.max(least, lost) end
    end
    local hooks = skill_hooks(self, "ai_getLeastHandcardNum_skill", player)
    if not hooks then return nil end
    for _, hook in ipairs(hooks) do
        local value = self:callHook("ai_getLeastHandcardNum_skill", hook.key, self, player, least)
        if finite_number(value) then least = math.max(least, value) end
    end
    return least
end

function SmartAIView:hasLoseHandcardEffective(player, count)
    player = player or self.player
    count = count or scalar(player, "getHandcardNum")
    local least = self:getLeastHandcardNum(player)
    if count == nil or least == nil then return nil end
    return count > least
end

local awaken_empty = {"zhiji", "mobilezhiji", "olzhiji"}
function SmartAIView:needKongcheng(player, keep)
    player = player or self.player
    local hand = scalar(player, "getHandcardNum")
    if hand == nil or not player:getSkills() then return nil end
    local awakening = false
    for _, name in ipairs(awaken_empty) do
        if known_skill(player, name) and mark_value(player, name) < 1 then awakening = true end
    end
    if keep then return hand < 1 and (known_skill(player, "kongcheng") or awakening) end
    local hooks = skill_hooks(self, "ai_need_kongcheng", player)
    for _, hook in ipairs(hooks or {}) do
        local value = self:callHook("ai_need_kongcheng", hook.key, self, player, keep)
        if type(value) == "boolean" then return value end
    end
    if hand > 0 then
        local effective = self:hasLoseHandcardEffective(player)
        if effective == nil then return nil end
        if not effective then return true end
    end
    if awakening then return true end
    if known_skill(player, "shude") then
        local phase = scalar(player, "getPhase")
        if phase == nil or sgs.Player_Play == nil then return nil end
        if phase == sgs.Player_Play then return true end
    end
    return category(player, "need_kongcheng")
end

-- Stable precedence replaces the original pairs() ambiguity when skills coexist.
local best_hp_reductions = {{"ganlu", 1}, {"yinghun", 2}, {"nosmiji", 1}, {"xueji", 1}, {"baobian", false}}
local function core_best_hp(owner)
    local max_hp = scalar(owner, "getMaxHp")
    if max_hp == nil or not owner:getSkills() then return nil end
    if known_skill(owner, "longhun") then
        local count = count_cards(owner)
        if count == nil then return nil end
        if count > 2 then return 1 end
    end
    if known_skill(owner, "hunzi") and mark_value(owner, "hunzi") < 1 then return 2 end
    for _, rule in ipairs(best_hp_reductions) do
        if known_skill(owner, rule[1]) then
            local lord
            if type(owner.isLord) == "function" then lord = owner:isLord() end
            if type(lord) ~= "boolean" then
                local role = type(owner.getRole) == "function" and owner:getRole() or nil
                if role == nil then return nil end
                lord = role == "lord"
            end
            local delta = rule[2] or math.max(0, max_hp - 3)
            return math.max(lord and 3 or 2, max_hp - delta)
        end
    end
    if owner:hasSkills("renjie+baiyin") and mark_value(owner, "baiyin") < 1
        or owner:hasSkills("quanji+zili") and mark_value(owner, "zili") < 1 then
        return max_hp - 1
    end
    return max_hp, true
end

function getBestHp(owner)
    if not owner then return nil end
    local value, extended = core_best_hp(owner)
    if not extended then return value end
    local registry, seen = sgs.ai_getBestHp_skill or {}, {}
    for _, skill in ipairs(owner:getSkills()) do
        local name = skill:objectName()
        if not seen[name] and not skill:isInvalid() then
            seen[name] = true
            if type(registry[name]) == "function" then
                local result = registry[name](owner)
                if finite_number(result) then return result end
            end
        end
    end
    return value
end
function SmartAIView:getBestHp(player) return getBestHp(player or self.player) end

-- This is the shared baseline, with package adjustments supplied by exact-ABI
-- hooks. It is an estimate for strategy, never an authoritative damage ruling.
local function damage_estimate(self, from, to, card, damage, raw_nature)
    if damage == nil then damage = 1 end
    if not finite_number(damage) or damage < 0 then return nil end
    if raw_nature == nil then
        raw_nature = card and (sgs.card_damage_nature or {})[card:getClassName()] or sgs.DamageStruct_Normal
    end
    local nature = type(raw_nature) == "string" and raw_nature or nil
    for _, entry in ipairs({{"DamageStruct_Normal", "N"}, {"DamageStruct_Fire", "F"}, {"DamageStruct_Thunder", "T"},
        {"DamageStruct_Ice", "I"}, {"DamageStruct_Poison", "P"}, {"DamageStruct_God", "G"}}) do
        if sgs[entry[1]] ~= nil and raw_nature == sgs[entry[1]] then nature = entry[2] end
    end
    if nature == nil and raw_nature == nil then nature = "N" end
    if type(nature) ~= "string" or not nature:match("^[NFTIPG]$") then return nil end
    for _, entry in ipairs({{"ai_ajustdamage_from", from}, {"ai_ajustdamage_to", to}}) do
        local hooks = skill_hooks(self, entry[1], entry[2])
        if not hooks then return nil end
        for _, hook in ipairs(hooks) do
            local delta = self:callHook(entry[1], hook.key, self, from, to, card, nature)
            if delta ~= nil then
                if not finite_number(delta) then return nil end
                damage = damage + delta
            end
        end
    end
    return damage
end

-- Failure cases for the cardless damage port: incomplete skills/marks/piles,
-- unknown armor bypass or role, elemental/chain damage, room event tags and
-- unported enemy damage-benefit policy. Never turn these into one damage.
local function damage_known(value, label)
    if value == nil then ai_unsupported("damage projection is unknown: " .. label, "ajustDamage") end
    return value
end

local function damage_call(object, method, ...)
    if not object or type(object[method]) ~= "function" then
        ai_unsupported("damage getter is unavailable: " .. method, "ajustDamage")
    end
    return damage_known(object[method](object, ...), method)
end

local function damage_player(player)
    if not AIValue.isPlayer(player) or not player:getSkills() or not player:getEquips()
        or type(player._view.public_marks) ~= "table" then
        ai_unsupported("damage needs skills, equipment and public marks", "ajustDamage")
    end
    return player
end

local function special_damage_mark(player, prefix)
    local count = 0
    for name, value in pairs(player._view.public_marks) do
        if name:sub(1, #prefix) == prefix then
            if not finite_number(value) then ai_unsupported("invalid damage mark", prefix) end
            if value > 0 then count = count + 1 end
        end
    end
    return count
end

local function damage_relation(self, to, from)
    if to:objectName() == from:objectName() then return "friend" end
    local relation = self:relationTo(to, from)
    if relation == nil or relation == "unknown" then
        ai_unsupported("damage relation is unknown", "canLoseHp")
    end
    return relation
end

-- Same early loss-of-HP substitution checks as hasJueqingEffect. Pile names
-- establish known absence; a missing projection is not an empty sp_ss pile.
local function damage_replaces_hp(from, to)
    if from:hasSkills("jueqing|gangzhi|MeowJueqing|exjueqing|sy_xushu")
        or to:hasSkills("gangzhi|xinnian|sy_xushu|s3_yijue") then return true end
    if from:hasSkill("tenyearjueqing") and from:getMark("tenyearjueqing") > 0
        or to:hasSkill("nyarz_shibei") and to:getMark("nyarz_shibei-Clear") > 1 then return true end
    if from:hasSkill("meizlwuqing") and damage_known(from:isWounded(), "wounded") then return true end
    for _, name in ipairs(damage_known(from:getPileNames(), "pile names")) do
        if name == "sp_ss" and damage_known(from:getPileCount(name), "sp_ss size") > 0 then return true end
    end
    if from:hasSkill("bffeedingpoisoning") and from:objectName() ~= to:objectName() then
        ai_unsupported("beFriend role policy is not projected", "bffeedingpoisoning")
    end
    return false
end

local function damage_ignores_armor(from, to)
    if damage_known(from:hasWeapon("QinggangSword"), "weapon")
        or not damage_known(to:hasArmorEffect(nil), "armor effect")
        or from:hasSkills("keshengqinggang|Qinggang")
        or from:hasSkill("SE_Wuwei") and from:getMark("@Wuwei") > 2 then return true end
    if from:hasSkills("luaqiangwang|s3_xiaoyong") then
        local distance = damage_known(from:distanceTo(to), "armor bypass distance")
        return from:hasSkill("luaqiangwang") and distance > 1
            or from:hasSkill("s3_xiaoyong") and distance == 1
    end
    return false
end

function SmartAIView:ajustDamage(from, to, damage, card, nature, depth)
    from = damage_player(from or self.room:getCurrent() or self.player)
    to = damage_player(to or self.player)
    damage = damage == nil and 1 or damage
    if not finite_number(damage) or damage < 0 then ai_unsupported("invalid damage", "ajustDamage") end
    -- This port deliberately covers skill-generated, normal damage. A physical
    -- card carries flags/tags and chain policy not present in this contract.
    if card ~= nil or nature ~= nil and nature ~= "N" and nature ~= sgs.DamageStruct_Normal
        or depth ~= nil and depth ~= 0 then
        ai_unsupported("card or elemental damage is not covered", "ajustDamage")
    end
    if damage_replaces_hp(from, to) then return -damage end
    local players = damage_known(self.room:getAlivePlayers(), "alive roster")
    for _, player in ipairs(players) do damage_player(player) end
    if (damage_known(to:hasArmorEffect("SilverLion"), "armor effect") or to:getMark("@silver_lion") > 0)
        and not damage_ignores_armor(from, to) then return 1 end
    if to:hasSkill("gongqing") then
        if damage_known(scalar(from, "getAttackRange"), "attack range") < 3 then return 1 end
    end
    for _, player in ipairs(players) do
        if player:hasSkill("huaiju") and to:getMark("&orange") > 0 then return 1 end
        if player:hasSkill("jgchiying") then
            if damage_call(player, "getRole") == damage_call(to, "getRole") then return 1 end
        end
    end
    local fortune4, fortune5 = special_damage_mark(to, "&tiansuan4"), special_damage_mark(to, "&tiansuan5")
    if fortune4 + fortune5 < 1
        and special_damage_mark(to, "&tiansuan2") + special_damage_mark(to, "&tiansuan3") > 0 then return 1 end
    if to:hasSkills("keyaoliandu|kejieyaoliandu|s2_gangzhi|s4_s_gedang") then return 1 end
    if special_damage_mark(to, "&tiansuan1") > 0 then return 0 end
    for _, player in ipairs(players) do
        if player:hasSkill("wuling") and player:getMark("@fire") > 0 then
            ai_unsupported("wuling changes damage nature", "ajustDamage")
        end
    end
    if from:hasSkills("keyaoleimu|TH_SubterraneanSun")
        or to:getMark("&undershouli-Clear") > 0 or to:getMark("&tyshouli-Clear") > 0
        or to:getMark("&shouli_debuff-Clear") > 0 then
        ai_unsupported("skill changes damage nature", "ajustDamage")
    end
    if from:hasSkill("Zhena") and from:getWeapon() and from:objectName() ~= to:objectName() then
        ai_unsupported("Zhena role and fire damage policy is not covered", "ajustDamage")
    end
    local mode = damage_known(self.room:getMode(), "game mode")
    if mode:find("guandu", 1, true) then ai_unsupported("guandu event tags are not projected", "ajustDamage") end
    self.to, self.from, self.card, self.nature = to, from, nil, "N"
    local function adjustments(registry, player)
        for _, hook in ipairs(damage_known(skill_hooks(self, registry, player), registry)) do
            local delta = self:callHook(registry, hook.key, self, from, to, nil, "N")
            if delta ~= nil then
                if not finite_number(delta) then ai_unsupported("non-numeric damage adjustment", hook.key) end
                damage = damage + delta
            end
        end
    end
    adjustments("ai_ajustdamage_from", from)
    for _, player in ipairs({from, to}) do
        if player:hasSkill("jiaozi") then
            local hand = damage_known(scalar(player, "getHandcardNum"), "jiaozi hand count")
            local most = true
            for _, other in ipairs(players) do
                if other:objectName() ~= player:objectName()
                    and damage_known(scalar(other, "getHandcardNum"), "jiaozi sibling hand count") >= hand then most = false end
            end
            if most then damage = damage + 1 end
        end
    end
    damage = damage + fortune4 + fortune5
    local hp = damage_known(scalar(to, "getHp"), "target hp")
    if from:hasSkill("se_yezhan") and damage >= hp then damage = damage + 1 end
    adjustments("ai_ajustdamage_to", to)
    if to:getMark("&kechengyechou") > 0 and damage >= hp then damage = damage * 2 * to:getMark("&kechengyechou") end
    if to:hasSkill("Sixu") and damage == 1 and not damage_call(to, "faceUp") then damage = 0 end
    if to:hasSkill("DSTP") and damage > 1 then damage = 1 end
    -- Preserve the donor's Lua truthiness: getMark("@inu_to") is truthy even
    -- at zero. This is donor policy, not an engine damage ruling.
    if damage > 1 then damage = damage - 1 end
    if to:hasSkill("luaRkuangyan") then
        if damage == 1 then damage = 0 end
        if damage > 1 then damage = damage + 1 end
    end
    if to:hasSkill("ark_kewang") and damage > 1 then damage = 0 end
    if to:hasSkill("sk_kuangyan") then
        if damage == 1 then damage = 0 end
        if damage >= 2 then damage = damage + 1 end
    end
    if to:hasSkill("Djianxiong") and damage > 1 then ai_unsupported("Djianxiong needs card history", "ajustDamage") end
    if to:hasSkill("zhouchu") and damage > 1 then damage = damage - 1 end
    if to:hasSkill("optimistic") and damage > 1 and to:getMark("@SuperLimitBreak") > 0 then damage = 0 end
    if to:hasSkill("cheerful") and damage > 1 then damage = 1 end
    return damage < -10 and 0 or damage
end

function SmartAIView:damageIsEffective(to, card_nature, from)
    local card = AIValue.isCard(card_nature) and card_nature or nil
    if self:ajustDamage(from, to, 1, card, card and nil or card_nature) <= 0 then return false end
    return not sgs.ai_humanized or math.random() < 0.95
end

function SmartAIView:canDamage(to, from, card)
    from, to = from or self.room:getCurrent() or self.player, to or self.player
    if not self:damageIsEffective(to, card, from) then return false end
    if damage_relation(self, to, self.player) == "enemy" then
        ai_unsupported("enemy damage benefit and cantbeHurt policy are not covered", "canDamage")
    end
    return true
end

function SmartAIView:canLoseHp(from, card, to)
    from, to = from or self.room:getCurrent() or self.player, to or self.player
    local damage = self:ajustDamage(from, to, 1, card)
    if damage < 0 then return false end
    if damage_relation(self, to, from) ~= "friend" then
        if from:hasSkill("jinyimie") and from:getMark("jinyimie-Clear") < 1
            or from:hasSkill("fcj_yimie") and from:getMark("fcj_yimie-Clear") < 1 then return false end
        if from:hasSkill("jieyuan") and damage_known(scalar(from, "getHp"), "source hp") <= damage_known(scalar(to, "getHp"), "target hp")
            and damage_known(scalar(from, "getHandcardNum"), "source hand count") > 0 then return false end
        if damage_known(self:isWeak(to), "target weakness")
            and (from:hasSkill("zhenyi") and from:getMark("@flyuqing") > 0 or from:hasSkill("pojun")) then return false end
        if from:hasSkill("jiedao") and from:getMark("jiedao-Clear") > 0
            and damage_known(from:getLostHp(), "lost hp") >= damage_known(scalar(to, "getHp"), "target hp") then return false end
        if from:hasSkill("shanzhuan") and #damage_known(to:getJudgingArea(), "judging area") == 0 then return false end
        if from:hasSkill("duorui") then ai_unsupported("duorui skill property is not projected", "canLoseHp") end
        if from:hasSkills("nosdanshou|chuanxin") then return false end
        if from:hasSkill("kuanggu") and damage_known(from:distanceTo(to), "kuanggu distance") == 1 then return false end
    end
    if damage_known(self:isWeak(to), "target weakness") then
        if to:getMark("@brutal") > 0 and from:hasSkill("xionghuo") then return false end
        if from:hasSkill("zhuixi") and damage_call(from, "faceUp") ~= damage_call(to, "faceUp") then return false end
    end
    if damage >= damage_known(scalar(to, "getHp"), "target hp") then return false end
    if from:hasSkill("jiaozi") and damage_known(scalar(from, "getHandcardNum"), "source hand count")
        > damage_known(scalar(to, "getHandcardNum"), "target hand count") then return false end
    if from:hasSkill("ov_equan") and damage_known(scalar(from, "getPhase"), "source phase")
        ~= damage_known(sgs.Player_NotActive, "NotActive phase") then return false end
    return true
end

function SmartAIView:needToLoseHp(to, from, card, passive, recover)
    to, from = to or self.player, from or self.room:getCurrent() or self.player
    local hp, max_hp = scalar(to, "getHp"), scalar(to, "getMaxHp")
    if hp == nil or max_hp == nil then return nil end
    local damage = damage_estimate(self, from, to, card)
    if damage == nil then return nil end
    if damage <= 0 or damage >= hp then return false end
    if card and card:isKindOf("Slash") and damage > 1 then return false end
    local hooks = skill_hooks(self, "ai_need_damaged", to)
    if not hooks then return nil end
    for _, hook in ipairs(hooks) do
        local wanted = self:callHook("ai_need_damaged", hook.key, self, from, to, card)
        -- shichou's legacy hook uses 1 for redirected damage; other hooks use booleans.
        if hook.key == "shichou" then return wanted == 1 end
        if type(wanted) == "boolean" then return wanted end
    end
    local best = self:getBestHp(to)
    if best == nil then return nil end
    if not passive and max_hp > 2 and to:hasSkills("longluo|miji|yinghun|nosrende|rende") then
        local friends = self:getFriends(to, true)
        if not friends then return nil end
        for _, friend in ipairs(friends) do
            if not self:needKongcheng(friend) and not known_skill(friend, "manjuan") then
                best = math.min(best, max_hp - 1)
                break
            end
        end
    end
    if recover then return hp >= best end
    return hp > best
end
SmartAIView.needToloseHp = SmartAIView.needToLoseHp

local function card_in_player(player, id)
    for _, entry in ipairs({{player:getKnownCards(), "hand"}, {player:getEquips(), "equip"},
        {player:getJudgingArea(), "judge"}}) do
        for _, card in ipairs(entry[1] or {}) do
            if card:getEffectiveId() == id then return card, entry[2] end
        end
    end
end

-- Shared bad-card classification is extensible; callbacks receive the original
-- (self, card, owner) ABI. Unknown retrial outcomes are not guessed.
local function harmful_card(self, card, owner, zone)
    local custom = self:callHook("ai_poison_card", card:objectName(), self, card, owner)
    if type(custom) == "boolean" then return custom end
    if card:isKindOf("Shit") then return true end
    if zone == "judge" then
        if card:isKindOf("Xumou") or card:isKindOf("YanxiaoCard") then return false end
        if card:isKindOf("Lightning") then return nil end
        if owner:containsTrick("YanxiaoCard") or owner:containsTrick("shuugakulyukou") then return false end
        return card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")
    end
    if zone == "equip" then
        if category(owner, "lose_equip_skill") then return true end
        if card:isKindOf("SilverLion") then
            local hp, max_hp = scalar(owner, "getHp"), scalar(owner, "getMaxHp")
            if hp == nil or max_hp == nil then return nil end
            return hp < max_hp
        end
    end
    return false
end

function SmartAIView:loseEquipEffect(player)
    player = player or self.player
    if not player:getSkills() then return nil end
    return category(player, "lose_equip_skill")
end

function SmartAIView:poisonCards(cards, owner)
    owner = owner or self.player
    local by_id, zones = {}, {}
    -- Materialize each visible zone only once, regardless of selection length.
    for _, entry in ipairs({{"h", "hand", "getKnownCards"}, {"e", "equip", "getEquips"},
        {"j", "judge", "getJudgingArea"}}) do
        local values = owner[entry[3]](owner)
        zones[entry[1]] = values
        for _, card in ipairs(values or {}) do
            by_id[card:getEffectiveId()] = {card = card, zone = entry[2]}
        end
    end
    if type(cards) == "string" then
        if cards == "" or cards:find("[^hej]") then return nil end
        local flags = cards
        cards = AIList.new({})
        for _, flag in ipairs({"h", "e", "j"}) do
            if flags:find(flag, 1, true) then
                if not zones[flag] then return nil end
                for _, card in ipairs(zones[flag]) do cards:append(card) end
            end
        end
    end
    if not AIValue.isList(cards) then return nil end
    local result = AIList.new({})
    for _, entry in ipairs(cards) do
        local card, zone
        if type(entry) == "number" then
            local row = by_id[entry]
            if row then card, zone = row.card, row.zone end
        elseif AIValue.isCard(entry) then
            card = entry
            local row = by_id[card:getEffectiveId()]
            if row then zone = row.zone end
        end
        if not card then return nil end
        local harmful = harmful_card(self, card, owner, zone)
        if harmful == nil then return nil end
        if harmful then result:append(card) end
    end
    return result
end
function SmartAIView:doDisCard(to, flags, obtain, n)
    to, flags, n = to or self.player, flags or "hej", n or 1
    if not finite_number(n) or n < 1 or n % 1 ~= 0 then return nil end
    local relation = self:relationTo(to)
    if relation ~= "friend" and relation ~= "enemy" then return nil end
    local friend = relation == "friend"
    if type(flags) == "number" then
        local card, zone = card_in_player(to, flags)
        if not card then return nil end
        local harmful = harmful_card(self, card, to, zone)
        if harmful == nil then return nil end
        if zone == "judge" and not friend then return card:isKindOf("YanxiaoCard") end
        if friend then return harmful end
        return not harmful
    end
    if type(flags) ~= "string" or flags:find("[^hej]") then return nil end
    local unknown = false
    for _, entry in ipairs({{"e", "equip", "getEquips"}, {"j", "judge", "getJudgingArea"}}) do
        if flags:find(entry[1], 1, true) then
            local cards = to[entry[3]](to)
            if not cards then unknown = true else
                local good = 0
                for _, card in ipairs(cards) do
                    local harmful = harmful_card(self, card, to, entry[2])
                    local value
                    if harmful ~= nil then
                        if entry[2] == "judge" and not friend then value = card:isKindOf("YanxiaoCard")
                        elseif friend then value = harmful
                        else value = not harmful end
                    end
                    if value then good = good + 1 elseif value == nil then unknown = true end
                end
                if good >= n / 2 then return true end
            end
        end
    end
    if flags:find("h", 1, true) then
        local hand, least = scalar(to, "getHandcardNum"), self:getLeastHandcardNum(to)
        if hand == nil or least == nil then unknown = true elseif hand > 0 then
            local empty = self:needKongcheng(to)
            if empty == nil then unknown = true
            elseif friend then
                if hand <= n and empty or least >= n then return true end
            elseif not empty or least < n then return true end
        end
    end
    if unknown then return nil end
    return false
end
SmartAIView.dodiscard = SmartAIView.doDisCard

-- Original shared cardNeed priorities, evaluated from visible values and the
-- existing per-skill value tables. No native card lookup or guessed hand IDs.
function SmartAIView:cardNeed(card)
    if not AIValue.isCard(card) and not AIValue.isConversion(card) then return nil end
    local value = self:getUseValue(card)
    local hp, max_hp = scalar(self.player, "getHp"), scalar(self.player, "getMaxHp")
    if hp == nil or max_hp == nil then return nil end
    local friends = self:getFriends() or {}
    if card:isKindOf("Peach") then
        for _, friend in ipairs(friends) do
            if self:isWeak(friend) then value = value + 4 break end
        end
        if hp < 3 or max_hp - hp > 1 or self.player:hasSkills("kurou|benghuai") then
            value = value + 6
        end
    end
    if not card:isKindOf("BasicCard") and not card:isKindOf("SkillCard") then
        for _, friend in ipairs(friends) do
            if known_skill(friend, "buyi") then
                if hp < 3 or (max_hp - hp > 1 and self:isWeak())
                    or self.player:hasSkills("kurou|benghuai") then value = value + 5 end
                break
            end
        end
    end
    local skills, seen, divisor = self.player:getSkills(), {}, 1
    if not skills then return nil end
    for _, skill in ipairs(skills) do
        local name = skill:objectName()
        if not seen[name] and not skill:isInvalid() then
            seen[name] = true
            local keep, suit = sgs[name .. "_keep_value"], sgs[name .. "_suit_value"]
            local bonus = type(keep) == "table" and keep[card:getClassName()] or nil
            if finite_number(bonus) then value, divisor = value + bonus / divisor, divisor + 1 end
            if type(suit) == "table" then
                if type(card.getSuitString) ~= "function" then return nil end
                bonus = suit[card:getSuitString()]
                if finite_number(bonus) then value, divisor = value + bonus / divisor, divisor + 1 end
            end
        end
    end
    if not card:isKindOf("EquipCard") then
        local count = self:getCardsNum(card:getClassName())
        if count == nil then return nil end
        value = value - count / 4 * value
        local poisoned = self:callHook("ai_poison_card", card:objectName(), self, card, self.player)
        if poisoned then value = value - 10 end
    end
    if self:isWeak() and (card:isKindOf("Jink") or card:isKindOf("Analeptic")) then
        value = value + 5
    elseif card:isKindOf("Slash") then
        local crossbows = self:getCardsNum("Crossbow")
        if crossbows == nil then return nil end
        if crossbows > 0 or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then value = value + 3 end
    elseif card:isKindOf("Crossbow") then
        if self.player:hasSkills("luoshen|yongsi|kurou|keji|wusheng|tenyearwusheng|wushen|olwushen|chixin") then
            local slashes = self:getCardsNum("Slash")
            if slashes == nil then return nil end
            value = value + slashes * 2
        end
    elseif card:isKindOf("Axe") then
        if self.player:hasSkills("luoyi|jiushi|jiuchi|pojun") then value = value + 5 end
    elseif card:isKindOf("Nullification") then
        local count = self:getCardsNum("Nullification")
        if count == nil then return nil end
        if count < 2 then
            for _, friend in ipairs(friends) do
                local judging = friend:getJudgingArea()
                if judging == nil then return nil end
                if #judging > 0 then value = value + 5 break end
            end
        end
    end
    return value
end

function SmartAIView:sortByCardNeed(cards, inverse, flags)
    if not AIValue.isList(cards) then return nil end
    -- Jilei is a rule result, not derivable from public skill names.
    if flags == "j" then return nil end
    local values = {}
    for _, card in ipairs(cards) do
        local value = self:cardNeed(card)
        if not finite_number(value) then return nil end
        values[card] = value
    end
    return sorted_copy(cards, function(card) return values[card] end, inverse ~= true)
end

-- Pure-value canUse accepts a candidate pool, matching the native list overload.
-- It only answers the viewer's current MethodUse request; no temporary xiyan
-- marks or rule reruns occur. Unlike the native first-target filter, a known
-- target-fixed empty sequence is usable with a nonempty pool.
function SmartAIView:canUse(card, players, from)
    from = from or self.player
    if not AIValue.isPlayer(from) or from:objectName() ~= self.player:objectName() then return nil end
    if not AIValue.isCard(card) and not AIValue.isConversion(card) then return nil end
    local is_use = self.request.kind == "activate"
        or (sgs.Card_MethodUse ~= nil and self.request.handling_method == sgs.Card_MethodUse)
    if not is_use then return nil end
    players = players or self.room:getAlivePlayers()
    if not AIValue.isList(players) then return nil end
    if #players == 0 then return false end
    local pool = {}
    for _, player in ipairs(players) do
        if not AIValue.isPlayer(player) then return nil end
        pool[player:objectName()] = true
    end
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate then return nil end
    if type(candidate.isLimited) ~= "function" or type(candidate.isAvailable) ~= "function" then return nil end
    local limited, available = candidate:isLimited(), candidate:isAvailable()
    if limited == true or available == false then return false end
    if limited ~= false or available ~= true or candidate:hasCompleteCoverage() ~= true then return nil end
    local offset = 0
    repeat
        local rows, next_offset = candidate:getTargetCombinations(offset)
        if not rows then return nil end
        for _, row in ipairs(rows) do
            if #row == 0 and candidate:targetFixed() == true then return true end
            if pool[row[1]] then return true end
        end
        offset = next_offset
    until offset == nil
    return false
end

function SmartAIView:willUse(player, card, ignoreDistance, disWeapon, play)
    player = player or self.player
    if player:objectName() ~= self.player:objectName() or ignoreDistance or disWeapon then return nil end
    if not self:getCardCandidate(card:getEffectiveId()) then return nil end
    local use = AIUsePlan.new()
    use.isDummy = true
    local plan, status = self:tryUseCard(card, use)
    if status == "unsupported" then return nil end
    return status == "planned" and plan.card ~= nil
end

function SmartAIView:getCardNeedPlayer(cards, include_self, tos)
    cards = cards or self.player:getHandcards()
    tos = tos or (include_self and self.room:getAlivePlayers() or self.room:getOtherPlayers(self.player))
    if not AIValue.isList(cards) or not AIValue.isList(tos) then return nil end
    local poison_gift
    for _, card in ipairs(cards) do
        if not AIValue.isCard(card) and not AIValue.isConversion(card) then return nil end
        if not poison_gift and card:isKindOf("Shit") then poison_gift = card end
    end
    local friends, eligible_hooks = AIList.new({}), {}
    for _, player in ipairs(tos) do
        local relation = self:relationTo(player)
        if relation == "friend" and not known_skill(player, "manjuan") then
            local hand, hp = scalar(player, "getHandcardNum"), scalar(player, "getHp")
            if hand == nil or hp == nil then return nil end
            local excluded = self:needKongcheng(player)
            if excluded == nil then return nil end
            if hp - hand >= 3 or player:hasSkills("keji|qiaobian|shensu") then excluded = false end
            if not excluded then
                friends:append(player)
                eligible_hooks[player] = skill_hooks(self, "ai_cardneed", player)
                if not eligible_hooks[player] then return nil end
            end
        elseif relation == "enemy" and poison_gift then
            return poison_gift, player
        end
    end
    friends = self:sort(friends, "defense")
    if friends == nil then return nil end
    -- Bucket once: ordinary survival/equipment priorities cost O(cards+players),
    -- while only registered package callbacks retain O(cards*matching hooks).
    local give, kept_jink = AIList.new({}), false
    local recovery, armor_card, horse_card
    for _, card in ipairs(cards) do
        if card:isKindOf("Jink") and not kept_jink then kept_jink = true
        else give:append(card) end
        if not recovery and (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then recovery = card end
        if not armor_card and card:isKindOf("Armor") then armor_card = card end
        if not horse_card and card:isKindOf("DefensiveHorse") then horse_card = card end
    end
    if recovery then
        for _, friend in ipairs(friends) do
            if friend:getHandcardNum() < 3 and self:isWeak(friend) then return recovery, friend end
        end
    end
    if armor_card or horse_card then
        for _, friend in ipairs(friends) do
            if friend:getHp() <= 2 then
                local equips = friend:getEquips()
                if equips then
                    local armor, horse = false, false
                    for _, equip in ipairs(equips) do
                        armor = armor or equip:isKindOf("Armor")
                        horse = horse or equip:isKindOf("DefensiveHorse")
                    end
                    if armor_card and not armor and not friend:hasSkills("yizhong|bazhen") then return armor_card, friend end
                    if horse_card and not horse then return horse_card, friend end
                end
            end
        end
    end
    -- Only registered active callbacks are visited, once per recipient; cards
    -- keep original high-number preference with deterministic ID tie-breaking.
    give = sorted_copy(give, function(card) return scalar(card, "getNumber", 0) end, false)
    for _, friend in ipairs(friends) do
        for _, hook in ipairs(eligible_hooks[friend]) do
            for _, card in ipairs(give) do
                if self:callHook("ai_cardneed", hook.key, friend, card, self) then return card, friend end
            end
        end
    end
    if #give == 0 then return nil end
    local maximum = scalar(self.player, "getMaxCards")
    local current_hand = scalar(self.player, "getHandcardNum")
    local overflow = maximum and current_hand and current_hand - maximum
    local hand = scalar(self.player, "getHandcardNum")
    if (overflow and overflow > 0) or (hand and hand > 3) then
        friends = self:sort(friends, "handcard")
        if friends == nil then return nil end
        for _, friend in ipairs(friends) do
            if not self:needKongcheng(friend, true) then return give[1], friend end
        end
    end
    return nil
end

local function unique_players(players)
    if not AIValue.isList(players) then return nil end
    local result, seen = AIList.new({}), {}
    for _, player in ipairs(players) do
        if not AIValue.isPlayer(player) then return nil end
        local name = player:objectName()
        if not seen[name] then seen[name] = true; result:append(player) end
    end
    return result
end

local function draw_context(self, from)
    local players = self.room:getAlivePlayers()
    if not players then return nil end
    local context = {jieyingg = {}, Godjieying = {}, zhafu = false,
        zhengu_blocked = false, zhengu_unknown = false}
    -- Collect room-wide effects once for a draw-target search. Zhengu's source
    -- relation is fixed for that search, so its marked targets need only one scan.
    for _, player in ipairs(players) do
        if not player:getSkills() then return nil end
        for _, name in ipairs({"jieyingg", "Godjieying"}) do
            if player:hasSkill(name) then
                context[name][#context[name] + 1] = player
            end
        end
        if player:hasSkill("zhafu") then context.zhafu = true end
        if player:getMark("&zhengu") > 0 then
            local relation = self:relationTo(player, from)
            if relation == "enemy" then
                local keep_empty = self:needKongcheng(player, true)
                if keep_empty == false then context.zhengu_blocked = true
                elseif keep_empty == nil then context.zhengu_unknown = true end
            elseif relation == nil or relation == "unknown" then
                context.zhengu_unknown = true
            end
        end
    end
    return context
end

local function can_draw(self, to, from, context)
    if not to or not to:getSkills() then return nil end
    local keep_empty = self:needKongcheng(to, true)
    if keep_empty == nil then return nil end
    if keep_empty or to:hasSkill("sfofl_suiqu") then return false end
    local phase = scalar(to, "getPhase")
    if to:hasSkills("manjuan|zishu") then
        if phase == nil or sgs.Player_NotActive == nil then return nil end
        if phase == sgs.Player_NotActive then return false end
    end
    if not context then return nil end
    if phase == nil or phase > 4 and phase < 7 then
        -- zhafu_from is not projected. Other known phases make this effect
        -- irrelevant; in its active window we must retain the unknown result.
        if context.zhafu then return nil end
        for _, effect in ipairs({{"&jygying", "jieyingg"}, {"&Godying", "Godjieying"}}) do
            if to:getMark(effect[1]) > 0 and not to:hasSkill(effect[2]) then
                for _, owner in ipairs(context[effect[2]]) do
                    local relation = self:relationTo(owner, to)
                    if relation == nil or relation == "unknown" then return nil end
                    if relation ~= "friend" then
                        if phase == nil then return nil end
                        return false
                    end
                end
            end
        end
    end
    if to:hasSkill("zhengu") then
        local hp, hand = scalar(to, "getHp"), scalar(to, "getHandcardNum")
        if hp == nil or hand == nil then return nil end
        if hp < 2 and hand < 2 then
            local weak = self:isWeak(to)
            if weak == nil then return nil end
            if weak then return true end
        end
        if context.zhengu_blocked then return false end
        if context.zhengu_unknown then return nil end
    end
    return true
end

function SmartAIView:canDraw(to, from)
    from = from or self.player
    return can_draw(self, to or self.player, from, draw_context(self, from))
end

function SmartAIView:findPlayerToDraw(include_self, drawnum, count, players)
    drawnum = drawnum or 1
    if not finite_number(drawnum) or drawnum < 1 then return nil end
    players = players or (include_self and self.room:getAlivePlayers()
        or self.room:getOtherPlayers(self.player))
    players = unique_players(players)
    if not players then return nil end
    local ranked, context = {}, draw_context(self, self.player)
    for _, player in ipairs(players) do
        local relation = self:relationTo(player)
        if relation == "friend" or player:objectName() == self.player:objectName() then
            local drawable = can_draw(self, player, self.player, context)
            local hand, max_cards = scalar(player, "getHandcardNum"), scalar(player, "getMaxCards")
            local kongcheng = self:needKongcheng(player)
            if drawable == nil or hand == nil or max_cards == nil or kongcheng == nil then return nil end
            if drawable and not (not include_self and player:objectName() == self.player:objectName())
                and not (drawnum <= 2 and hand == 0 and kongcheng) then
                ranked[#ranked + 1] = {player = player, score = (hand < 2 and 20 or 0)
                    + math.max(0, max_cards - hand)}
            end
        end
    end
    table.sort(ranked, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.player:objectName() < b.player:objectName()
    end)
    local result = AIList.new({})
    for _, entry in ipairs(ranked) do result:append(entry.player) end
    return count and result or result[1]
end

function SmartAIView:findPlayerToDiscard(flags, include_self, no_dis, players, reason)
    flags = flags or "he"
    if type(flags) ~= "string" or flags:find("[^hej]") then return nil end
    players = unique_players(players or (include_self and self.room:getAlivePlayers()
        or self.room:getOtherPlayers(self.player)))
    if not players then return nil end
    local result, scored = AIList.new({}), {}
    for _, player in ipairs(players) do
        local relation = self:relationTo(player)
        if player:objectName() == self.player:objectName() then relation = "friend" end
        if relation == "friend" or relation == "enemy" then
            local useful = self:doDisCard(player, flags, false, 1)
            if useful == nil then return nil end
            if useful then
                scored[#scored + 1] = {player = player,
                    score = (relation == "enemy" and 100 or 20)
                        + scalar(player, "getHandcardNum", 0)}
            end
        end
    end
    table.sort(scored, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.player:objectName() < b.player:objectName()
    end)
    for _, entry in ipairs(scored) do result:append(entry.player) end
    return result
end

function SmartAIView:findPlayerToDamage(damage, player, nature, targets, base_value, card)
    damage = damage or 1; player = player or self.player; base_value = base_value or 0
    if not finite_number(damage) or not finite_number(base_value) then return nil end
    targets = unique_players(targets or self.room:getOtherPlayers(player))
    if not targets then return nil end
    if not nature and card then nature = (sgs.card_damage_nature or {})[card:getClassName()] end
    nature = nature or "N"
    local scored = {}
    for _, target in ipairs(targets) do
        local relation = self:relationTo(target)
        if relation == nil or relation == "unknown" then return nil end
        local estimated = damage_estimate(self, player, target, card, damage, nature)
        if estimated == nil then return nil end
        local hp = scalar(target, "getHp")
        if hp == nil then return nil end
        local weak = self:isWeak(target)
        if weak == nil then return nil end
        local score = estimated > 0 and estimated * 20 + (weak and 15 or 0) or nil
        if score and relation == "friend" then
            local wants = self:needToLoseHp(target, player, card)
            if wants == nil then return nil end
            if wants ~= true then score = nil else score = -score end
        end
        if score and score > base_value then scored[#scored + 1] = {player = target, score = score} end
    end
    table.sort(scored, function(a, b)
        if a.score ~= b.score then return a.score > b.score end
        return a.player:objectName() < b.player:objectName()
    end)
    local result = AIList.new({})
    for _, entry in ipairs(scored) do result:append(entry.player) end
    return result
end

function SmartAIView:findBestDamageTarget(damage, nature, min_value, card)
    local targets = self:findPlayerToDamage(damage, self.player, nature, nil, min_value or 5, card)
    return targets and targets[1] or nil
end

local function clone_scratch(value, depth, seen, budget)
    budget.n = budget.n - 1
    if budget.n < 0 or depth > 16 then ai_unsupported("scratch budget exceeded", "planning") end
    if type(value) ~= "table" then
        if type(value) ~= "nil" and type(value) ~= "boolean" and type(value) ~= "number"
            and type(value) ~= "string" then
            ai_unsupported("scratch must contain pure values", "planning")
        end
        return value
    end
    if getmetatable(value) ~= nil or seen[value] then
        ai_unsupported("scratch must be an acyclic pure value", "planning")
    end
    seen[value] = true
    local copy = {}
    for key, item in pairs(value) do
        if type(key) ~= "string" and type(key) ~= "number" then
            ai_unsupported("scratch key must be a value", "planning")
        end
        copy[key] = clone_scratch(item, depth + 1, seen, budget)
    end
    seen[value] = nil
    return copy
end

-- Revises use legacy positional ABIs. Merely registering an empty table never
-- supplies a strategy; only an explicit use.card proposal does.
local function apply_use_revises(self, card, use, strategy)
    local function run_strategy()
        local hooks = skill_hooks(self, "ai_skill_carduse", self.player)
        if not hooks then ai_unsupported("card use skills are unknown", "ai_skill_carduse") end
        for _, hook in ipairs(hooks) do
            -- Exact true means a skill took over, including an explicit decline.
            if type(hook.value) == "function"
                and self:callHook("ai_skill_carduse", hook.key, self, card, use) == true then return end
        end
        if not strategy then ai_unsupported("no isolated strategy for this card", card:objectName()) end
        strategy(self, card, use, use.context)
    end
    local function pre(name, player, with_target)
        local hooks = skill_hooks(self, name, player)
        if not hooks then ai_unsupported("skill hooks need a complete projection", name) end
        for _, hook in ipairs(hooks) do
            local value
            if type(hook.value) == "function" then
                if with_target then value = self:callHook(name, hook.key, self, card, use, player)
                else value = self:callHook(name, hook.key, self, card, use) end
            end
            if value == false then use.card = nil return false end
            if value == true then
                if not use.card then run_strategy() end
                if use.card then break end
            end
        end
        return true
    end
    if not pre("ai_use_revises", self.player, false) then return end
    local players = self.room:getAlivePlayers()
    if not players then ai_unsupported("use revises need the player roster", "ai_useto_revises") end
    for _, player in ipairs(players) do
        if not pre("ai_useto_revises", player, true) then return end
        local judging = player:getJudgingArea()
        if not judging then ai_unsupported("use revises need the judging area", "ai_useto_revises") end
        for _, trick in ipairs(judging) do
            local value = self:callHook("ai_useto_revises", trick:objectName(), self, card, use, player)
            if value == false then use.card = nil return end
            if value == true and not use.card then run_strategy() end
        end
    end
    if not use.card then run_strategy() end
    if not use.card then return end
    -- Target exclusions stay in request scratch, not native player properties.
    -- Replanning uses whole authority-approved combinations and is bounded by
    -- the number of visible players; a non-cooperating strategy is unsupported.
    local excluded = use.scratch.revised_targets or {}
    use.scratch.revised_targets = excluded
    for attempt = 1, #players + 1 do
        -- A strategy may replace the card; query only its authority-issued ticket.
        local candidate = self:getCardCandidate(use.card:getEffectiveId())
        if not candidate then ai_unsupported("proposed card has no authority candidate", "candidate") end
        local targets = use.to
        if #targets == 0 then
            if type(candidate.targetFixed) ~= "function" then
                ai_unsupported("target mode is unknown", "targets")
            end
            local fixed = candidate:targetFixed()
            if fixed == nil then ai_unsupported("target mode is unknown", "targets") end
            if fixed then targets = {self.player} end
        end
        if use.card:isKindOf("AOE") or use.card:isKindOf("GlobalEffect") then
            local names = candidate:getAffectedTargets()
            if not names then ai_unsupported("implicit effect targets are unknown", "ai_target_revises") end
            targets = AIList.new({})
            for _, name in ipairs(names) do
                local target = self.room:findPlayerByObjectName(name)
                if not target then ai_unsupported("implicit target is missing", "ai_target_revises") end
                targets:append(target)
            end
        end
        local revised = false
        if not use.card:isKindOf("EquipCard") then
            for _, target in ipairs(targets) do
                local hooks = skill_hooks(self, "ai_target_revises", target)
                if not hooks then ai_unsupported("target skills are unknown", "ai_target_revises") end
                for _, hook in ipairs(hooks) do
                    local original = use.card
                    local reject = self:callHook("ai_target_revises", hook.key, target, use.card, self, use)
                    if use.card ~= original then return end
                    if reject then
                        local name = target:objectName()
                        if excluded[name] then ai_unsupported("strategy ignores target revise", hook.key) end
                        excluded[name], revised = true, true
                        break
                    end
                end
            end
        end
        if not revised then break end
        use.card, use.to = nil, AIList.new({})
        run_strategy()
        if not use.card then return end
        if attempt == #players + 1 then ai_unsupported("target revise budget exceeded", "planning") end
    end

end

function SmartAIView:tryUseCard(card, use)
    if not AIValue.isCard(card) and not AIValue.isConversion(card) then
        return AIUnsupported.new("aiUseCard needs a card view"), "unsupported"
    end
    local strategy, key = find_card_use(card)
    -- Connected skill/revise callbacks may supply a proposal without a family
    -- strategy. Only run_strategy's final fallback can reject that path.
    key = key or card:objectName() or card:getClassName() or "unknown"
    self.request.scratch = self.request.scratch or {}
    local state = planning[self.request]
    if not state then
        state = {depth = 0, candidates = 0, context = {
            kind = self.request.kind, reason = self.request.reason,
            pattern = self.request.pattern, handling_method = self.request.handling_method}}
        planning[self.request] = state
    end
    state.candidates = state.candidates + 1
    if state.depth >= 8 or state.candidates > 128 then
        return AIUnsupported.new("planning budget exceeded", "planning"), "unsupported"
    end
    -- Check coverage before a strategy can decline on an empty/partial projection.
    local offered = self:getCardCandidate(card:getEffectiveId())
    if offered and (offered:hasCompleteCoverage() ~= true
        or offered:getTargetCombinations() == nil) then
        return AIUnsupported.new("target combinations are incomplete", "targets"), "unsupported"
    end
    local parent = self.request.scratch or {}
    local copied, branch = AIUnsupported.capture(clone_scratch, parent, 0, {}, {n = 4096})
    if not copied then return branch, "unsupported" end
    use = use or AIUsePlan.new()
    use.to = use.to or AIList.new({})
    use.context = {}
    for k, v in pairs(state.context) do use.context[k] = v end
    use.scratch = branch
    branch.reserved_cards = branch.reserved_cards or {}
    branch.uses = branch.uses or {}
    branch.selected_targets = branch.selected_targets or {}
    local costs = AIValue.isConversion(card) and card:getSubcards() or {card:getEffectiveId()}
    for _, id in ipairs(costs or {}) do
        if branch.reserved_cards[id] then
            return AIUnsupported.new("a planning cost is already reserved", "planning"), "unsupported"
        end
        branch.reserved_cards[id] = true
    end
    branch.uses[key] = (branch.uses[key] or 0) + 1
    self.request.scratch = branch
    state.depth = state.depth + 1
    -- Always unwind, including programmer errors; pcall must not convert them to pass.
    local ok, signal = pcall(apply_use_revises, self, card, use, strategy)
    state.depth = state.depth - 1
    self.request.scratch = parent
    if not ok then
        if AIUnsupported.is(signal) then return signal, "unsupported" end
        error(signal, 0)
    end
    if use.card == nil then return use, "declined" end
    branch.selected_targets = {}
    for i, target in ipairs(use.to) do branch.selected_targets[i] = target:objectName() end
    local candidate = self:getCardCandidate(use.card:getEffectiveId())
    if not candidate then
        return AIUnsupported.new("proposed card has no authority candidate", "candidate"), "unsupported"
    end
    local is_conversion = AIValue.isConversion(use.card)
    if AIValue.isConversion(candidate) ~= is_conversion then
        return AIUnsupported.new("proposal and authority ticket kinds differ", "candidate"), "unsupported"
    end
    if type(candidate.isAvailable) ~= "function" or candidate:isAvailable() ~= true then
        return AIUnsupported.new("proposed card is unavailable or availability is unknown", "candidate"), "unsupported"
    end
    -- Conversion availability already includes its activation/cost restrictions;
    -- physical candidates carry a separate authoritative MethodUse limit bit.
    if not is_conversion and (type(candidate.isLimited) ~= "function" or candidate:isLimited() ~= false) then
        return AIUnsupported.new("proposed card is limited or limits are unknown", "candidate"), "unsupported"
    end
    if is_conversion then
        local proposed, authority = use.card:toCardSpec(), candidate:toCardSpec()
        for _, field in ipairs({"name", "suit", "number", "skill"}) do
            if proposed[field] ~= authority[field] then
                return AIUnsupported.new("proposed conversion identity does not match its authority ticket", "conversion"), "unsupported"
            end
        end
        local valid = self:validatePlannedIntent("cost", {
            conversion_id = use.card:getConversionId(), subcards = use.card:getSubcards()})
        if valid ~= true then
            return AIUnsupported.new("proposed conversion costs do not match its authority ticket", "conversion"), "unsupported"
        end
    end
    if candidate then
        if candidate:hasCompleteCoverage() ~= true then
            return AIUnsupported.new("target combinations are incomplete", "targets"), "unsupported"
        end
        if candidate:targetFixed() then
            if #use.to ~= 0 or candidate:isFeasibleWithNoTarget() ~= true then
                return AIUnsupported.new("strategy proposed an illegal target sequence", "targets"), "unsupported"
            end
        else
            local _, finish = candidate:getTargetSelection(branch.selected_targets)
            if finish ~= true then
                return AIUnsupported.new("strategy proposed an illegal target sequence", "targets"), "unsupported"
            end
        end
    end
    -- A revise may replace the original card. Its final ticket, never the input
    -- candidate's ticket, belongs in the answer. Conversions serialize their own.
    use.candidate_id = nil
    if not is_conversion and type(candidate.getCandidateId) == "function" then
        use.candidate_id = candidate:getCandidateId()
    end
    -- Only a validated, selected proposal fires commit-time revise callbacks.
    if not use.isDummy then
        for _, hook in ipairs(skill_hooks(self, "ai_used_revises", self.player) or {}) do
            if type(hook.value) == "function" then self:callHook("ai_used_revises", hook.key, self, use) end
        end
    end
    return use, "planned"
end

-- Standard play strategies require a play context. Response/ResponseUse callers
-- retain their actual reason and must use a strategy that explicitly covers it.
local function require_single_target(candidate, key)
    local page, cursor = candidate:getTargetCombinations()
    if not page then ai_unsupported("target combinations are incomplete", key) end
    repeat
        for _, row in ipairs(page) do
            if #row ~= 1 then ai_unsupported("multi-target strategy is not covered", key) end
        end
        if cursor then page, cursor = candidate:getTargetCombinations(cursor) else break end
    until false
end

local function require_play(use, key)
    local context = use.context
    if context.kind ~= "activate" or (context.reason ~= nil and context.reason ~= 0
        and context.reason ~= 1) then
        ai_unsupported("card strategy does not cover this request context", key)
    end
end

-- Choose only whole authority-approved sequences. Ranking stays in rankTargets;
-- this helper does no targetFilter/distance simulation and cannot invent pairs.
function SmartAIView:planTargetSequence(candidate, stance, accept)
    local page, cursor = candidate:getTargetCombinations()
    if not page then ai_unsupported("target combinations are incomplete", "targets") end
    local names, seen, rows = {}, {}, {}
    repeat
        for _, row in ipairs(page) do
            rows[#rows + 1] = row
            for _, name in ipairs(row) do
                if not seen[name] then seen[name] = true names[#names + 1] = name end
            end
        end
        if cursor then page, cursor = candidate:getTargetCombinations(cursor) else break end
    until false
    local ranked = self:rankTargets(names, stance)
    if not ranked then ai_unsupported("target relations are unknown", "targets") end
    local score, players = {}, {}
    for i, player in ipairs(ranked) do
        local name = player:objectName()
        score[name], players[name] = #ranked - i + 1, player
    end
    local best, best_score
    for _, row in ipairs(rows) do
        local value, chosen = 0, AIList.new({})
        for _, name in ipairs(row) do
            local excluded = self.request.scratch and self.request.scratch.revised_targets
            if not score[name] or (excluded and excluded[name])
                or (accept and not accept(players[name])) then value = nil break end
            value = value + score[name]
            chosen:append(players[name])
        end
        if value and #chosen > 0 and (not best_score or value > best_score) then
            best, best_score = chosen, value
        end
    end
    return best
end

-- Family strategies use only projected relations and authority-approved rows.  A row is
-- never invented from legal_targets, so partial/unknown effect data still falls back.
local function projected_relation(self, target)
    if not self:isModeManaged() then return nil end
    local relation = self:relationTo(target)
    if relation == nil or relation == "unknown" then return nil end
    return relation
end

local function sequence_rows(candidate)
    local page, cursor = candidate:getTargetCombinations()
    if not page then ai_unsupported("target combinations are incomplete", "targets") end
    local rows = {}
    repeat
        for _, row in ipairs(page) do rows[#rows + 1] = row end
        if cursor then page, cursor = candidate:getTargetCombinations(cursor) else break end
    until false
    return rows
end

local function choose_sequence(self, candidate, scorer, key)
    local rows = sequence_rows(candidate)
    local players = {}
    local roster = self.room:getPlayers()
    if not roster then ai_unsupported("target roster is incomplete", key) end
    for _, player in ipairs(roster) do players[player:objectName()] = player end
    local best, best_score
    for _, row in ipairs(rows) do
        local chosen, score = AIList.new({}), 0
        for _, name in ipairs(row) do
            local target = players[name]
            if not target then ai_unsupported("target roster is incomplete", key) end
            local relation = projected_relation(self, target)
            if relation == nil then ai_unsupported("target relations are unknown", key) end
            chosen:append(target)
            score = score + scorer(target, relation)
        end
        if #chosen > 0 and (best_score == nil or score > best_score) then
            best, best_score = chosen, score
        end
    end
    return best, best_score
end

local family_effect_score

-- AOE/global cards are target-fixed, but their effect roster is still part of the
-- projection.  Never infer it from legal_targets or the room roster.
local function choose_affected(self, candidate, card, key)
    local getter = candidate.getAffectedTargets
    if type(getter) ~= "function" then
        ai_unsupported("affected target projection is missing", key)
    end
    local names = getter(candidate)
    if not AIValue.isList(names) then
        ai_unsupported("affected target projection is unknown", key)
    end
    local players = {}
    local roster = self.room:getPlayers()
    if not roster then ai_unsupported("target roster is incomplete", key) end
    for _, player in ipairs(roster) do players[player:objectName()] = player end
    local chosen, score = AIList.new({}), 0
    for _, name in ipairs(names) do
        local target = players[name]
        if not target then ai_unsupported("target roster is incomplete", key) end
        local relation = projected_relation(self, target)
        if relation == nil then ai_unsupported("target relations are unknown", key) end
        chosen:append(target)
        score = score + family_effect_score(self, card, target, relation)
    end
    return chosen, score
end

local function plan_no_target(self, card, use, key)
    require_play(use, key)
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate then ai_unsupported("this request carries no candidate for the " .. key, key) end
    if candidate:hasCompleteCoverage() ~= true then
        ai_unsupported("target combinations are incomplete", key)
    end
    if candidate:needsATarget() then ai_unsupported("card requires a target sequence", key) end
    local rows = sequence_rows(candidate)
    -- Native target-fixed cards expose one empty authority row (`{{}}`).  An empty
    -- row list means no feasible sequence and must remain declined/unsupported.
    if #rows ~= 1 or #rows[1] ~= 0 then
        ai_unsupported("card target projection is not fixed", key)
    end
    use.card = card
end

if type(ai_coverage) == "table" then
    ai_coverage.declare("card_use", function()
        local keys = {}
        for key in pairs(ai_card_use) do keys[#keys + 1] = key end
        return keys
    end)
end

-- 第一批實體牌策略：殺與桃。這兩支放在共用核心而不是某個套件 handler，因為
-- activate 的通用出牌流程本身就要靠它們；套件 handler 仍可用 ai_card_use 覆寫。

-- 實體殺：只打敵人，優先打快死的、威脅大的。打不到敵人就不打，不硬找友軍下手。
ai_card_use.Slash = function(self, card, use)
    require_play(use, "Slash")
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate then
        ai_unsupported("this request carries no candidate for the Slash", "Slash")
    end
    -- 認不出敵友就不是「沒有敵人」，是這個情境沒被覆蓋：回報此候選未知，
    -- 不亂挑一個人打。
    if not self:isModeManaged() then
        ai_unsupported("the mode policy does not describe relations", "Slash")
    end
    local targets = candidate:getLegalTargets()
    if not targets then ai_unsupported("legal targets are unknown", "Slash") end
    local chosen = self:planTargetSequence(candidate, "enemy", function(target)
        local hooks = skill_hooks(self, "ai_slash_prohibit", target)
        if not hooks then ai_unsupported("slash target skills are unknown", "ai_slash_prohibit") end
        for _, hook in ipairs(hooks) do
            if self:callHook("ai_slash_prohibit", hook.key, self, self.player, target, card) then return false end
        end
        return true
    end)
    if not chosen then return end
    use.card = card
    use.to = chosen
end

-- 桃：只在自己受傷時用，而且留一張救命。血量到底線才把最後一張喝掉。
ai_card_use.Peach = function(self, card, use)
    require_play(use, "Peach")
    if not self.player:isWounded() then return end
    local hp = self.player:getHp()
    if type(hp) ~= "number" then
        ai_unsupported("the snapshot does not carry the viewer's hp", "Peach")
    end
    local held = self:getCardsNum("Peach", self.player)
    if hp > 1 and (held == nil or held <= 1) then return end
    use.card = card
end

-- 決鬥：被指的人先出殺，兩邊輪流，先拿不出殺的那個受傷。所以這一張不是「打誰最痛」
-- 的問題，是「誰的殺多」：對方先出，所以我方張數追平就已經贏。兩邊的張數來源不同，
-- 不可以混用——自己的手牌是完全已知的，對方的只能估計。
ai_card_use.Duel = function(self, card, use)
    require_play(use, "Duel")
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate then
        ai_unsupported("this request carries no candidate for the Duel", "Duel")
    end
    if not self:isModeManaged() then
        ai_unsupported("the mode policy does not describe relations", "Duel")
    end
    require_single_target(candidate, card:getClassName())
    local targets = candidate:getLegalTargets()
    if not targets then ai_unsupported("legal targets are unknown", "Duel") end
    local ranked = self:rankTargets(targets, "enemy")
    if not ranked then ai_unsupported("target roster is incomplete", card:getClassName()) end
    if ranked:isEmpty() then return end
    local mine = self:getCardsNum("Slash", self.player)
    if mine == nil then
        ai_unsupported("the snapshot does not carry the viewer's own hand", "Duel")
    end
    -- 輸掉決鬥就是挨一下。挨不起的時候要有餘裕才開：血剩一點又沒有桃，追平不夠。
    local hp = self.player:getHp()
    local margin = 0
    if type(hp) == "number" and hp <= 1
        and (self:getCardsNum("Peach", self.player) or 0) < 1 then
        margin = 1
    end
    for _, target in ipairs(ranked) do
        local theirs = self:estimateCardsNum("Slash", target)
        -- 估不出來就不賭。那是「這裡沒有可用的估計」，不是「對方沒有殺」。
        if theirs ~= nil and mine >= theirs + margin then
            use.card = card
            use.to:append(target)
            return
        end
    end
end

-- 順手牽羊與過河拆橋共用同一份「拆誰最划算」的估值：能拿走／打掉的東西越多越好。
-- 裝備是看得見的實物所以算兩分，手牌只知道張數所以一張一分，判定區不算收穫——
-- 把敵人的樂不思蜀拆掉是幫他解套，不是打他。全身只剩判定區的人因此是 0 分，不指。
-- Strip usefulness is shared with the subsequent card_chosen handler. Friendly
-- harmful judgment/equipment relief and enemy denial use identical predicates;
-- every proposed sequence still comes from authoritative target combinations.
local function plan_strip(self, card, use, key)
    require_play(use, key)
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate then ai_unsupported("this request carries no strip candidate", key) end
    local targets = candidate:getLegalTargets()
    if not targets then ai_unsupported("legal strip targets are unknown", key) end
    local useful, unknown = {}, false
    for _, name in ipairs(targets) do
        local target = self.room:findPlayerByObjectName(name)
        if not target then ai_unsupported("strip target is missing", key) end
        local benefit = self:doDisCard(target, "hej", key == "Snatch")
        useful[name] = benefit == true
        if benefit == nil then unknown = true end
    end
    local chosen = self:planTargetSequence(candidate, "any", function(target)
        return useful[target:objectName()]
    end)
    if not chosen then
        if unknown then ai_unsupported("strip usefulness needs a missing projection", key) end
        return
    end
    use.card, use.to = card, chosen
end

ai_card_use.Snatch = function(self, card, use)
    return plan_strip(self, card, use, "Snatch")
end
ai_card_use.Dismantlement = function(self, card, use)
    return plan_strip(self, card, use, "Dismantlement")
end
-- Standard card families mapped from standard_cards-ai.lua.  These handlers deliberately
-- stay generic: extension-specific side effects can register ai_card_effect[class_name]
-- and return a pure target score, without adding another per-general branch here.
ai_card_effect = ai_card_effect or {}

family_effect_score = function(self, card, target, relation)
    local hook = ai_card_effect[card:getClassName()] or ai_card_effect[card:objectName()]
    if type(hook) == "function" then
        local value = hook(self, card, target, relation)
        if not finite_number(value) then ai_unsupported("card effect hook returned no value", card:getClassName()) end
        return value
    end
    if card:isKindOf("AOE") then
        return relation == "enemy" and 2 + (self:isWeak(target) and 1 or 0) or -2
    elseif card:isKindOf("GlobalEffect") then
        return relation == "friend" and (target:isWounded() and 3 or 1) or -2
    elseif card:isKindOf("IronChain") then
        local chained = target.isChained
        if type(chained) ~= "function" then
            ai_unsupported("the snapshot does not describe chained state", "IronChain")
        end
        local value = chained(target)
        if type(value) ~= "boolean" then
            ai_unsupported("the snapshot does not describe chained state", "IronChain")
        end
        return (relation == "friend" and value) and 2
            or (relation == "enemy" and not value) and 2 or -2
    end
    return relation == "enemy" and 1 or -1
end

local function plan_projected_family(self, card, use, key)
    require_play(use, key)
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate then ai_unsupported("this request carries no candidate for the " .. key, key) end
    local chosen, score
    if not candidate:needsATarget() and (card:isKindOf("AOE")
        or card:isKindOf("GlobalEffect")) then
        chosen, score = choose_affected(self, candidate, card, key)
    else
        if not candidate:getLegalTargets() then ai_unsupported("legal targets are unknown", key) end
        chosen, score = choose_sequence(self, candidate,
            function(target, relation) return family_effect_score(self, card, target, relation) end, key)
    end
    if not chosen or score <= 0 then return end
    use.card = card
    -- AOE/global cards are target-fixed: affected_targets is for scoring only and
    -- must never be emitted as explicit use targets.
    use.to = candidate:targetFixed() and AIList.new({}) or chosen
end

-- Equipment and draw cards have no target sequence.  The authority still has to explicitly
-- project a no-target candidate; an absent row is not treated as an empty answer.
ai_card_use.EquipCard = function(self, card, use)
    local slot_getter = card.getEquipSlot
    if type(slot_getter) ~= "function" then
        ai_unsupported("the snapshot does not describe the equipment slot", "EquipCard")
    end
    local slot = slot_getter(card)
    if type(slot) ~= "number" or slot < 0 then
        ai_unsupported("the snapshot does not describe the equipment slot", "EquipCard")
    end
    local current_id = self.player:getEquip(slot)
    local current
    if current_id ~= nil then
        local equips = self.player:getEquips()
        if not equips then ai_unsupported("equipment projection is missing", "EquipCard") end
        for _, existing in ipairs(equips) do
            if existing:getEffectiveId() == current_id then current = existing break end
        end
        if not current then ai_unsupported("equipped card metadata is missing", "EquipCard") end
    end
    if current and self:getUseValue(card) <= self:getUseValue(current) then return end
    return plan_no_target(self, card, use, card:getClassName())
end
ai_card_use.ExNihilo = function(self, card, use)
    return plan_no_target(self, card, use, "ExNihilo")
end

-- Analeptic's attack follow-up is effect-dependent; without an explicit pure-value
-- projection this action remains unknown; another authorized action may be chosen.
ai_card_use.Analeptic = function(self, card, use)
    local hook = ai_card_effect.Analeptic or ai_card_effect[card:getClassName()]
    if type(hook) ~= "function" then
        ai_unsupported("analeptic follow-up intent is not projected", "Analeptic")
    end
    local value = hook(self, card, self.player, "play")
    if not finite_number(value) then
        ai_unsupported("card effect hook returned no value", "Analeptic")
    end
    if value <= 0 then return end
    return plan_no_target(self, card, use, "Analeptic")
end

ai_card_use.AmazingGrace = function(self, card, use)
    return plan_projected_family(self, card, use, "AmazingGrace")
end
ai_card_use.GodSalvation = function(self, card, use)
    return plan_projected_family(self, card, use, "GodSalvation")
end
ai_card_use.SavageAssault = function(self, card, use)
    return plan_projected_family(self, card, use, "SavageAssault")
end
ai_card_use.ArcheryAttack = function(self, card, use)
    return plan_projected_family(self, card, use, "ArcheryAttack")
end
ai_card_use.IronChain = function(self, card, use)
    return plan_projected_family(self, card, use, "IronChain")
end

local function plan_delayed(self, card, use, key)
    require_play(use, key)
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate then ai_unsupported("this request carries no candidate for the " .. key, key) end
    if not candidate:needsATarget() and not card:isKindOf("Lightning") then
        return plan_no_target(self, card, use, key)
    end
    if card:isKindOf("Lightning") then
        local hook = ai_card_effect.Lightning or ai_card_effect[card:getClassName()]
        if type(hook) ~= "function" then
            ai_unsupported("lightning effect value is not projected", key)
        end
        local value = hook(self, card, self.player, "play")
        if not finite_number(value) then
            ai_unsupported("card effect hook returned no value", key)
        end
        if value <= 0 then return end
        return plan_no_target(self, card, use, key)
    end
    if not self:isModeManaged() then ai_unsupported("the mode policy does not describe relations", key) end
    local chosen = self:planTargetSequence(candidate, "enemy")
    -- Preserve the entire authorized sequence, including a target modifier's
    -- multi-target delayed trick. A valid row cannot be truncated to its first ID.
    if chosen and chosen:first() then use.card, use.to = card, chosen end
end
ai_card_use.Indulgence = function(self, card, use) return plan_delayed(self, card, use, "Indulgence") end
ai_card_use.SupplyShortage = function(self, card, use) return plan_delayed(self, card, use, "SupplyShortage") end
ai_card_use.Lightning = function(self, card, use) return plan_delayed(self, card, use, "Lightning") end
ai_card_use.AOE = function(self, card, use) return plan_projected_family(self, card, use, "AOE") end
ai_card_use.GlobalEffect = function(self, card, use)
    return plan_projected_family(self, card, use, "GlobalEffect")
end
ai_card_use.DelayedTrick = function(self, card, use)
    return plan_delayed(self, card, use, "DelayedTrick")
end

-- Collateral needs two authority-approved targets and an equipped first target.  The
-- second Slash response is a separate request, so this handler stops at the plan boundary.
ai_card_use.Collateral = function(self, card, use)
    require_play(use, "Collateral")
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate then ai_unsupported("this request carries no candidate for the Collateral", "Collateral") end
    local rows = sequence_rows(candidate)
    local players, best, best_score = {}, nil, nil
    for _, player in ipairs(self.room:getPlayers() or {}) do players[player:objectName()] = player end
    for _, row in ipairs(rows) do
        if #row == 2 then
            local from, victim = players[row[1]], players[row[2]]
            if not from or not victim then ai_unsupported("target roster is incomplete", "Collateral") end
            local relation = projected_relation(self, victim)
            if relation == nil then ai_unsupported("target relations are unknown", "Collateral") end
            if from:hasEquip() then
                local hook = ai_card_effect.Collateral or ai_card_effect[card:getClassName()]
                local bonus
                if relation == "enemy" then
                    bonus = 3
                elseif type(hook) == "function" then
                    bonus = hook(self, card, victim, relation)
                    if not finite_number(bonus) then
                        ai_unsupported("card effect hook returned no value", "Collateral")
                    end
                    if bonus <= 0 then bonus = nil end
                end
                -- A friendly victim needs an explicit effect hook.  The generic
                -- Collateral policy must never invent a positive victim choice.
                if bonus then
                    local score = bonus + (self:getThreat(victim) or 0)
                    if best_score == nil or score > best_score then
                        best, best_score = AIList.new({from, victim}), score
                    end
                end
            end
        end
    end
    if best then use.card, use.to = card, best end
end

-- 通用出牌流程：照優先序問每一張牌的策略，第一個提出計劃的就是答案。
-- 這裡不自己挑目標——activate 與 aiUseCard 是同一條路徑，同一張牌的判斷只有一份。
function SmartAIView:planTurnUse()
    -- Incomplete alternatives affect our ability to pass, not the authority of
    -- an actually offered legal action. Each candidate is handled independently.
    local uses, unknown = self:getTurnUse(true)
    if self:hasEnumeratedConversions() ~= true then
        unknown = unknown or AIUnsupported.new("available conversions are not fully enumerated", "conversion")
    end
    for _, use in ipairs(uses or {}) do
        local plan, status = self:tryUseCard(use.card)
        if status == "unsupported" then
            unknown = unknown or plan
        elseif status == "planned" then
            local answer = plan:toAnswer()
            if answer then return answer, use, unknown end
            unknown = unknown or AIUnsupported.new("planned action cannot be serialized", "planning")
        end
    end
    -- Never convert an unknown alternative into a strategic pass.
    if unknown then error(unknown, 0) end
    return nil
end
-- 逐技能 activate registry：key 是 activation_skill 名。各技能腳本用
-- ai_skill_activate["xxx"] = function(self, request) ... end 掛自己的出牌策略，
-- 回 nil 表示這次不啟動，繼續問下一個；都沒人接才落到通用出牌規劃。
ai_skill_activate = {}

-- 通用 activate：沒有任何武將策略時的預設出牌流程。
if type(ai_coverage) == "table" then
    ai_coverage.declare("activate", function()
        local keys = {"generic"}
        for key in pairs(ai_skill_activate) do keys[#keys + 1] = key end
        return keys
    end)
end

ai_register_handler("activate", function(self, request)
    -- 逐實例探測（request.skill_action）問的是「要不要啟動這個實例」：只派給
    -- 該技能的 handler，沒註冊或拒答就回 nil 記錄未處理，不讓通用規劃的答案
    -- 套到不相干的實例上。
    local probe = type(request.skill_action) == "table" and request.skill_action or nil
    if probe then
        local handler = ai_skill_activate[probe.activation_skill]
        return handler and handler(self, request) or nil
    end
    -- 一般 activate：按權威端給的 skill_actions 順序，先命中的技能 handler 先答。
    if type(request.skill_actions) == "table" then
        for _, action in ipairs(request.skill_actions) do
            local handler = type(action) == "table"
                and ai_skill_activate[action.activation_skill] or nil
            if handler then
                local result = handler(self, request)
                if result ~= nil then return result end
            end
        end
    end
    -- Unknown active skills prevent a pass, but do not veto an independently
    -- authorized card proposal. Defer their coverage debt until after planning.
    local unknown_skill
    if type(request.skill_actions) == "table" then
        local conversions = self:getConversions()
        -- Build the authorized conversion coverage index once per request.  The old
        -- action x conversion nested scan repeated the same lookup for every skill.
        local conversion_by_skill = {}
        if self:hasEnumeratedConversions() and conversions then
            for _, conversion in ipairs(conversions) do
                -- Unknown identity does not cover a skill or abort other cards.
                local key = type(conversion.getActivationSkillName) == "function"
                    and conversion:getActivationSkillName() or nil
                if type(key) == "string" and key ~= "" then
                    conversion_by_skill[key] = conversion_by_skill[key] or {}
                    conversion_by_skill[key][#conversion_by_skill[key] + 1] = conversion
                end
            end
        end
        for _, action in ipairs(request.skill_actions) do
            local key = type(action) == "table" and action.activation_skill or nil
            if type(key) == "string" and key ~= "" and not ai_skill_activate[key] then
                local covered = false
                -- 列不完就不能宣稱覆蓋：那是「不知道這個技能變得出什麼」。
                if self:hasEnumeratedConversions() and conversion_by_skill[key] then
                    covered = true
                    -- planTurnUse evaluates these conversions, including actual
                    -- connected hook probes when no family strategy exists.
                end
                if not covered then
                    unknown_skill = unknown_skill or AIUnsupported.new(
                        "an active skill in this turn has no isolated strategy", key)
                end
            end
        end
    end
    local plan, _, unknown = self:planTurnUse()
    if not plan then
        if unknown_skill then error(unknown_skill, 0) end
        return {kind = "pass"}
    end
    -- Partial handling is still an autonomous answer. Preserve only already
    -- discovered coverage gaps; do not probe unused strategies just for auditing.
    if type(ai_coverage) == "table" and type(ai_coverage.notCovered) == "function" then
        if unknown then ai_coverage.notCovered(request.kind, unknown.reason, unknown.key) end
        if unknown_skill and (not unknown or unknown_skill.reason ~= unknown.reason
            or unknown_skill.key ~= unknown.key) then
            ai_coverage.notCovered(request.kind, unknown_skill.reason, unknown_skill.key)
        end
    end
    return plan
end)
