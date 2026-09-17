-- 通用決策流程的隔離版本：估值、排序、威脅評估與回合候選。
-- 全部只靠快照與 request 的候選運作，沒有 gameplay 全域，也不查 Engine。
-- 個別武將策略仍然用註冊表擴充，不寫進這裡。

-- 值型規則註冊表。鍵是牌名或類別名，值是數字或 function(self, card) 回數字。
ai_keep_value = ai_keep_value or {}
ai_use_value = ai_use_value or {}
ai_use_priority = ai_use_priority or {}

local default_keep_value = {Peach = 8, Analeptic = 5, Jink = 4, Slash = 3}
local default_use_value = {Peach = 8, Analeptic = 5, Slash = 4, Jink = 3}
local default_use_priority = {Peach = 5, Analeptic = 4.5, Slash = 4, Jink = 1}

local function rule_value(registry, defaults, self, card)
    if not card then return nil end
    local names = {card:objectName(), card:getClassName()}
    for _, name in ipairs(names) do
        local rule = name and registry[name]
        if type(rule) == "function" then
            local value = rule(self, card)
            if type(value) == "number" then return value end
        elseif type(rule) == "number" then
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
    return value or 0
end

function SmartAIView:getUseValue(card)
    local value = rule_value(ai_use_value, default_use_value, self, card)
    return value or 0
end

function SmartAIView:getUsePriority(card)
    local value = rule_value(ai_use_priority, default_use_priority, self, card)
    return value or 0
end

-- 排序一律在副本上做，快照順序不動；同分時用牌 ID 保持穩定，避免不同 VM 排出不同結果。
local function sorted_copy(cards, score, ascending)
    if not AIValue.isList(cards) then return nil end
    local result = AIList.new({})
    for _, card in ipairs(cards) do result[#result + 1] = card end
    local scores = {}
    for _, card in ipairs(result) do scores[card] = score(card) or 0 end
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
    return defense
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

-- 回合候選：把 request 的合法候選轉成值型出牌方案，按優先序排好。
-- 這裡只產生「可以這樣打」的清單，要不要打、打誰由上層決定。
function SmartAIView:getTurnUse()
    local candidates = self:getCardCandidates()
    if not candidates then return nil end
    local hand = self.player:getHandcards()
    local by_id = {}
    if hand then
        for _, card in ipairs(hand) do by_id[card:getId()] = card end
    end
    local equips = self.player:getEquips()
    if equips then
        for _, card in ipairs(equips) do by_id[card:getId()] = card end
    end
    local uses = AIList.new({})
    for _, candidate in ipairs(candidates) do
        local card = by_id[candidate:getCardId()]
        if card and candidate:isAvailable() and not candidate:isLimited() then
            local targets = candidate:getLegalTargets()
            if candidate:targetFixed() or (targets and #targets > 0) then
                uses[#uses + 1] = {
                    card = card,
                    card_id = candidate:getCardId(),
                    targets = targets,
                    target_fixed = candidate:targetFixed(),
                    max_targets = candidate:getMaxTargets(),
                    priority = self:getUsePriority(card),
                    value = self:getUseValue(card)
                }
            end
        end
    end
    table.sort(uses, function(first, second)
        if first.priority ~= second.priority then return first.priority > second.priority end
        if first.value ~= second.value then return first.value > second.value end
        return first.card_id < second.card_id
    end)
    return uses
end

-- 通用選目標：先敵後友，同陣營內用威脅／虛弱排序；關係未知時不亂猜，保持候選順序。
function SmartAIView:pickTargets(use, count)
    if type(use) ~= "table" or not use.targets then return nil end
    count = count or 1
    local ranked = {}
    for _, name in ipairs(use.targets) do
        local target = self.room:findPlayerByObjectName(name, true)
        if target then ranked[#ranked + 1] = {name = name, player = target} end
    end
    if not self:isModeManaged() then
        local plain = AIList.new({})
        for index = 1, math.min(count, #ranked) do plain[index] = ranked[index].name end
        return plain
    end
    for _, entry in ipairs(ranked) do
        entry.enemy = self:isEnemy(entry.player) == true
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
        if #chosen >= count then break end
        -- 只打敵人；沒有敵人時不硬找一個友軍下手。
        if entry.enemy then chosen[#chosen + 1] = entry.name end
    end
    return chosen
end

-- 通用出牌流程：照優先序挑第一個能打得動的方案。沒有就 pass 交回上層。
function SmartAIView:planTurnUse()
    local uses = self:getTurnUse()
    if not uses then return nil end
    for _, use in ipairs(uses) do
        if use.target_fixed then
            return {kind = "use_card", card_id = use.card_id}, use
        end
        local targets = self:pickTargets(use, use.max_targets > 0 and 1 or 0)
        if targets and #targets > 0 then
            local names = {}
            for index, name in ipairs(targets) do names[index] = name end
            return {kind = "use_card", card_id = use.card_id, targets = names}, use
        end
    end
    return nil
end

-- 通用 activate：沒有任何武將策略時的預設出牌流程。註冊成 handler 讓 Shadow 先跑，
-- 個別技能仍由 ask-for-use-card 的 registry 擴充，不經過這裡。
if type(ai_coverage) == "table" then
    ai_coverage.declare("activate", function() return {"generic"} end)
end

ai_register_handler("activate", function(self, request)
    if not self:getCardCandidates() then return nil end
    local plan = self:planTurnUse()
    if not plan then return {kind = "pass"} end
    return plan
end)
