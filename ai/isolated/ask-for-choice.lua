-- 值型詢問的 registry。每個 decision kind 一張表，鍵是 request 的 reason
-- （技能名或詢問原因）。handler 統一收 (self, options, request)：options 帶候選、
-- 上下限、可取消與預設值，與舊 callback 的 QVariant data 無關，也不共用同一張表。
local function register_handler(handlers, reason, handler)
    if type(reason) ~= "string" or reason == "" or type(handler) ~= "function" then
        error("invalid isolated value decision handler")
    end
    handlers[reason] = handler
end

-- Legacy aliases have a separate ABI; never invoke an old callback with options
-- in the position where SmartAI supplied data, targets, or a count.
ai_choice_legacy_registries = {}
local legacy_by_kind = {}
local response_card_default
local function legacy_registry(kind, name)
    local values = {}
    legacy_by_kind[kind] = values
    local registry = setmetatable({}, {
        __index = values,
        __newindex = function(_, key, value)
            local t = type(value)
            if type(key) ~= "string" or key == "" or (t ~= "nil" and t ~= "function"
                and t ~= "boolean" and t ~= "number" and t ~= "string" and t ~= "table") then
                error("invalid isolated legacy decision callback")
            end
            values[key] = value
        end
    })
    ai_choice_legacy_registries[name] = registry
    return registry
end

local function decision_context(self, options, request)
    if type(self.getDecisionContext) == "function" then return self:getDecisionContext(request) end
    return options and options.context or {}
end

local function legacy_player(self, value)
    if type(value) == "string" then return self.room:findPlayerByObjectName(value, true) end
    return value
end

local function legacy_call(self, kind, callback, options, request)
    options = options or {}
    local context = decision_context(self, options, request) or {}
    local targets = AIList.new({})
    for _, name in ipairs(options.players or {}) do
        local target = legacy_player(self, name)
        if target then targets:append(target) end
    end
    -- Explicit typed conversions such as data:toJudge() remain value proxies;
    -- unsupported QVariant operations are intentionally not impersonated.
    local data = type(self.getDecisionData) == "function" and self:getDecisionData()
        or context.data or context
    local result, extra
    if type(callback) ~= "function" then result = callback
    elseif kind == "skill_invoke" then result = callback(self, data)
    elseif kind == "choice" then result = callback(self, table.concat(options.choices or {}, "+"), data)
    elseif kind == "suit" or kind == "kingdom" then result = callback(self)
    elseif kind == "general" then result = callback(self, options.choices, options.default_choice)
    elseif kind == "discard" then
        result = callback(self, options.max_count, options.min_count, options.optional,
            context.include_equip == true or context.equiped == true, request.pattern or ".")
    elseif kind == "amazing_grace" then result = callback(self, options.card_ids)
    elseif kind == "card_chosen" then
        result = callback(self, legacy_player(self, context.who or context.target),
            context.flags, context.method or request.handling_method)
    elseif kind == "yiji" then result, extra = callback(self, options.card_ids, targets)
    elseif kind == "player_chosen" then result = callback(self, targets)
    elseif kind == "players_chosen" then result = callback(self, targets, options.max_count, options.min_count)
    elseif kind == "guanxing" then result, extra = callback(self, options.card_ids, tonumber(options.default_choice))
    elseif kind == "trigger_order" then result = callback(self, options.choices, data)
    elseif kind == "askForCard" then
        local parts = {}
        for part in string.gmatch((request.prompt or "") .. ":", "(.-):") do parts[#parts + 1] = part end
        local pattern = (request.pattern or ""):gsub("!$", "")
        result = callback(self, data, pattern, legacy_player(self, parts[2]),
            legacy_player(self, parts[3]), parts[4], parts[5])
    elseif kind == "askForNullification" then
        result = callback(self, context.card, legacy_player(self, context.from),
            legacy_player(self, context.to), context.positive)
    elseif kind == "askForCardShow" then result = callback(self, targets[1])
    elseif kind == "askForSinglePeach" then result = callback(self, targets[1])
    elseif kind == "askForPindian" then
        -- The original callback receives lowest-use, self, requestor, max and min.
        local cards = self:getChoiceCards()
        if not cards or #cards == 0 then return nil end
        local low, high, cheap = cards[1], cards[1], cards[1]
        for _, card in ipairs(cards) do
            if card:getNumber() < low:getNumber() then low = card end
            if card:getNumber() > high:getNumber() then high = card end
            if self:getUseValue(card) < self:getUseValue(cheap) then cheap = card end
        end
        result = callback(cheap, self, targets[1], high, low)
    end
    if result == nil then return nil end
    if kind == "askForNullification" and type(result) == "boolean" then
        if result then return response_card_default(self, options, request) end
        return {kind="pass"}
    end
    if kind == "suit" and type(result) == "number" then
        return ({[0]="spade", "club", "heart", "diamond", "no_suit"})[result]
    end
    if kind == "yiji" then
        if not result or type(extra) ~= "number" or extra < 0 then return nil end
        return {kind="answer", cards={extra}, targets={type(result)=="string" and result or result:objectName()}}
    end
    if kind == "guanxing" and type(result) == "table" then
        return {kind="answer", cards=result, bottom_cards=extra or {}}
    end
    if type(result) == "table" and type(result.objectName) == "function" and kind == "player_chosen" then
        return result:objectName()
    end
    if type(result) == "table" and type(result.getEffectiveId) == "function" then return result:getEffectiveId() end
    if kind == "players_chosen" or kind == "discard" then
        if type(result) == "number" and kind == "discard" then return {result} end
        if type(result) == "table" and result.kind == nil then
            local values = {}
            for _, value in ipairs(result) do
                values[#values + 1] = type(value) == "table" and
                    (kind == "discard" and value:getEffectiveId() or value:objectName()) or value
            end
            return #values == 0 and {kind="pass"} or values
        end
    end
    if result == "." or result == -1 then return {kind="pass"} end
    if kind == "askForCard" or kind == "askForSinglePeach" or kind == "askForCardShow"
        or kind == "askForPindian" then
        if type(result) == "string" then
            local id = result:match("^%$?(%d+)$")
            if not id then
                ai_unsupported("legacy converted response requires an authorized card spec", kind)
            end
            return tonumber(id)
        end
    end
    return result
end

local function make_registry(kind, default_name, name)
    local handlers = {}
    legacy_registry(kind, name)
    if type(ai_coverage) == "table" then
        ai_coverage.declare(kind, function()
            local keys = {}
            for key in pairs(handlers) do keys[#keys + 1] = key end
            for key in pairs(legacy_by_kind[kind]) do keys[#keys + 1] = "legacy:" .. key end
            return keys
        end)
    end
    ai_register_handler(kind, function(self, request)
        local options = type(request.options) == "table" and request.options or nil
        local reason = options and options.reason
        local handler = type(reason) == "string" and handlers[reason] or nil
        if handler then
            local result = handler(self, options, request)
            if result ~= nil then return result end
        end
        local legacy = legacy_by_kind[kind]
        local callback
        if type(reason) == "string" then callback = legacy[reason] end
        if callback == nil and type(reason) == "string" then callback = legacy[reason:gsub("%-", "_")] end
        if callback ~= nil then
            local result = legacy_call(self, kind, callback, options, request)
            if result ~= nil then return result end
        end
        -- 理由專用策略優先；共用預設仍可明確回 nil，表示這題未覆蓋。
        local fallback = default_name and _G[default_name]
        if type(fallback) == "function" then return fallback(self, options, request) end
        return nil
    end)
    return setmetatable({}, {
        __index = handlers,
        __newindex = function(_, reason, handler)
            register_handler(handlers, reason, handler)
        end
    })
end

ai_skill_invoke = make_registry("skill_invoke", "ai_skill_invoke_default", "ai_skill_invoke")
ai_skill_choice = make_registry("choice", "ai_skill_choice_default", "ai_skill_choice")
ai_skill_suit = make_registry("suit", "ai_skill_suit_default", "ai_skill_suit")
ai_skill_kingdom = make_registry("kingdom", "ai_skill_kingdom_default", "ai_skill_kingdom")
ai_general_choice = make_registry("general", "ai_general_choice_default", "ai_general_choice")

-- 選牌與選人族沿用同一種註冊形狀；候選在 options.card_ids／options.players。
ai_skill_discard = make_registry("discard", "ai_skill_discard_default", "ai_skill_discard")
ai_skill_askforag = make_registry("amazing_grace", "ai_skill_askforag_default", "ai_skill_askforag")
ai_skill_cardchosen = make_registry("card_chosen", "ai_skill_cardchosen_default", "ai_skill_cardchosen")
ai_skill_askforyiji = make_registry("yiji", "ai_skill_askforyiji_default", "ai_skill_askforyiji")
ai_skill_playerchosen = make_registry("player_chosen", "ai_skill_playerchosen_default", "ai_skill_playerchosen")
ai_skill_playerschosen = make_registry("players_chosen", "ai_skill_playerschosen_default", "ai_skill_playerschosen")
ai_skill_guanxing = make_registry("guanxing", "ai_skill_guanxing_default", "ai_skill_guanxing")
ai_skill_triggerorder = make_registry("trigger_order", "ai_skill_triggerorder_default", "ai_skill_triggerorder")

-- 回應牌族共用 respond_card 一種 kind，所以再用 options.question 分辨是哪個詢問；
-- 實體答案使用 ID；轉化答案攜帶權威 conversion ticket，不以合成 ID 冒充實體牌。
local respond_handlers = {}
local respond_defaults = {}

ai_register_handler("respond_card", function(self, request)
    local options = type(request.options) == "table" and request.options or nil
    local question = options and options.question
    local handlers = type(question) == "string" and respond_handlers[question] or nil
    local keys = {}
    if question == "askForCard" then
        -- Explicit pattern policies precede prompt-specific policies. Keep the
        -- original trailing ! as the registry key but strip it for legacy ABI.
        keys[#keys + 1] = request.pattern or ""
        keys[#keys + 1] = (request.prompt or ""):match("^[^:]*") or ""
    elseif question == "askForNullification" then
        local context = decision_context(self, options, request)
        local card = context and context.card
        if card and type(card.getClassName) == "function" then
            keys[#keys + 1] = card:getClassName() or ""
        end
    end
    keys[#keys + 1] = options and options.reason or ""
    local seen = {}
    for _, key in ipairs(keys) do
        if key ~= "" and not seen[key] then
            seen[key] = true
            local handler = handlers and handlers[key]
            local result
            if handler then result = handler(self, options, request) end
            if result == nil then
                local legacy = legacy_by_kind[question]
                local callback = legacy and legacy[key]
                if callback ~= nil then result = legacy_call(self, question, callback, options, request) end
            end
            local compulsory = question == "askForCard" and (request.pattern or ""):sub(-1) == "!"
            local declined = result == "." or (type(result) == "table" and result.kind == "pass")
            if result ~= nil and not (compulsory and declined) then return result end
        end
    end
    local fallback = type(question) == "string" and respond_defaults[question] or nil
    if type(fallback) == "function" then return fallback(self, options, request) end
    return nil
end)

local function respond_registry(question, name)
    local handlers = {}
    legacy_registry(question, name)
    if type(ai_coverage) == "table" then
        ai_coverage.declare("respond_card", function()
            local keys = {}
            for key in pairs(handlers) do keys[#keys + 1] = question .. ":" .. key end
            for key in pairs(legacy_by_kind[question]) do keys[#keys + 1] = question .. ":legacy:" .. key end
            return keys
        end)
    end
    respond_handlers[question] = handlers
    return setmetatable({}, {
        __index = handlers,
        __newindex = function(_, reason, handler)
            register_handler(handlers, reason, handler)
        end
    })
end

ai_skill_cardask = respond_registry("askForCard", "ai_skill_cardask")
ai_nullification = respond_registry("askForNullification", "ai_nullification")
ai_cardshow = respond_registry("askForCardShow", "ai_cardshow")
ai_skill_pindian = respond_registry("askForPindian", "ai_skill_pindian")
ai_skill_singlepeach = respond_registry("askForSinglePeach", "ai_skill_singlepeach")

-- Default values deliberately use only the request's offered values and the viewer's
-- visible cards.  An absent value is unknown, never a reason to inspect another hand.
local function offered(options, field)
    local values = options and options[field]
    return type(values) == "table" and #values > 0 and values or nil
end

local function unsupported(reason, key)
    if type(ai_unsupported) == "function" then ai_unsupported(reason, key) end
    return nil
end

local function finite_number(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function note_unknown(kind, signal)
    if signal and type(ai_coverage) == "table" then
        ai_coverage.notCovered(kind, signal.reason, signal.key)
    end
end

local function valid_choice(values, wanted)
    if type(wanted) == "string" and wanted ~= "" then
        for _, value in ipairs(values) do if value == wanted then return wanted end end
    end
    return values[1]
end

local function card_index(self, options)
    local index = {}
    if type(self) ~= "table" or not self.player then return index end
    if type(self.getChoiceCard) == "function" then
        index._facade = true
    end
    for _, card in ipairs(options and options.cards or {}) do
        if type(card) == "table" and (card.id ~= nil or card.effective_id ~= nil) then
            index[card.effective_id or card.id] = CardView.new(card)
        end
    end
    local cards = self.player:getCards("he")
    if cards then
        for _, card in ipairs(cards) do index[card:getEffectiveId()] = index[card:getEffectiveId()] or card end
    end
    local discard = self.room and self.room:getDiscardCards()
    if discard then
        for _, card in ipairs(discard) do index[card:getEffectiveId()] = index[card:getEffectiveId()] or card end
    end
    return index
end

local function known_cards(self, ids, options)
    local index = card_index(self, options)
    local result = {}
    for _, id in ipairs(ids or {}) do
        local card = index[id]
        if index._facade and type(self.getChoiceCard) == "function" then
            card = self:getChoiceCard(id, options) or card
        end
        if not card then return nil end
        result[#result + 1] = card
    end
    return result
end

local function lowest_keep(self, ids, options)
    local cards = known_cards(self, ids, options)
    if not cards then return nil end
    local best, best_value, best_id
    for _, card in ipairs(cards) do
        local value, id = self:getKeepValue(card), card:getEffectiveId()
        if not best or value < best_value or (value == best_value and id < best_id) then
            best, best_value, best_id = card, value, id
        end
    end
    return best_id
end

local function default_choice(self, options)
    local choices = offered(options, "choices")
    return choices and valid_choice(choices, options.default_choice) or nil
end
ai_skill_invoke_default = ai_skill_invoke_default or function(self, options)
    local frequency = options and options.context and options.context.skill_frequency
    -- Like SmartAI's no-hook rule, only an explicitly frequent skill opts in.
    return type(frequency) == "number" and frequency == sgs.Skill_Frequent
end
ai_skill_choice_default = ai_skill_choice_default or function(self, options)
    local choices = offered(options, "choices")
    if not choices then return nil end
    local allowed = {}
    for _, choice in ipairs(choices) do
        if choice ~= "benghuai" then allowed[#allowed + 1] = choice end
    end
    -- Prefer ordinary choices, but a sole mandatory option is still legal.
    if #allowed == 0 then allowed = choices end
    for _, choice in ipairs(allowed) do
        if choice == options.default_choice then return choice end
    end
    return allowed[math.random(1, #allowed)]
end
ai_skill_suit_default = ai_skill_suit_default or function(self, options)
    local choices = offered(options, "choices")
    if not choices then return nil end
    local allowed, weighted = {}, {}
    for _, suit in ipairs(choices) do allowed[suit] = true end
    -- Original nosfanjian fallback weights, restricted to authority-offered suits.
    for _, suit in ipairs({"spade", "spade", "club", "heart", "heart", "diamond", "diamond", "diamond"}) do
        if allowed[suit] then weighted[#weighted + 1] = suit end
    end
    if #weighted == 0 then return choices[math.random(1, #choices)] end
    local selected = weighted[math.random(1, #weighted)]
    local current, counts, best_count, best = self.room:getCurrent(), {}, 0, nil
    -- Known cards are already viewer-redacted; never enumerate a hidden hand.
    for _, card in ipairs(current and current:getKnownCards() or {}) do
        local suit = card:getSuitString()
        if allowed[suit] then
            counts[suit] = (counts[suit] or 0) + 1
            if counts[suit] > best_count then best, best_count = suit, counts[suit] end
        end
    end
    if self.player:hasSkill("hongyan") and allowed.heart
        and (best == "spade" or selected == "spade") then return "heart" end
    return best or selected
end
ai_skill_kingdom_default = ai_skill_kingdom_default or default_choice
ai_general_choice_default = ai_general_choice_default or function(self, options)
    local choices = offered(options, "choices")
    if not choices then return nil end
    local selectable = {}
    for _, name in ipairs(choices) do
        if name:sub(1, 1) ~= "~" then
            if name == options.default_choice then return name end
            selectable[#selectable + 1] = name
        end
    end
    if #selectable == 0 then return unsupported("no selectable general is offered", "general") end
    return selectable[math.random(1, #selectable)]
end

ai_skill_discard_default = ai_skill_discard_default or function(self, options)
    if not options or options.candidates_complete ~= true then
        return unsupported("discard candidate completeness is unknown", "discard")
    end
    local ids = offered(options, "card_ids")
    if not ids then
        return options and options.optional and {kind = "pass"}
            or unsupported("discard candidates are missing", "discard")
    end
    local min_count = type(options.min_count) == "number" and options.min_count or 0
    local max_count = type(options.max_count) == "number" and options.max_count or #ids
    if max_count < min_count then return nil end
    if options.optional then
        local context = options.context or {}
        local result, offered_ids = {}, {}
        for _, id in ipairs(ids) do offered_ids[id] = true end
        -- Like SmartAI, optional discard only removes poisonous equipment; the
        -- authority-provided IDs still enforce pattern and discard limitations.
        if context.include_equip == true or context.equiped == true then
            if type(self.poisonCards) ~= "function" then
                return unsupported("poison equipment policy is unavailable", "discard")
            end
            local poisonous = self:poisonCards("e")
            if not poisonous then return unsupported("poison equipment policy is unknown", "discard") end
            for _, card in ipairs(poisonous) do
                if #result >= max_count then break end
                local id = card:getEffectiveId()
                if offered_ids[id] then result[#result + 1] = id end
            end
        end
        return #result >= min_count and #result > 0 and result or {kind="pass"}
    end
    local cards = known_cards(self, ids, options)
    if not cards then return nil end
    local keep_values = {}
    for _, card in ipairs(cards) do keep_values[card] = self:getKeepValue(card) end
    table.sort(cards, function(a, b)
        local av, bv = keep_values[a], keep_values[b]
        if av ~= bv then return av < bv end
        return a:getEffectiveId() < b:getEffectiveId()
    end)
    if min_count == 0 then return {kind = "pass"} end
    local result = {}
    local count = math.min(min_count, #cards, max_count)
    for i = 1, count do result[i] = cards[i]:getEffectiveId() end
    if #result < min_count then
        return options.optional and {kind = "pass"}
            or unsupported("the offered cards cannot satisfy the discard minimum", "discard")
    end
    return result
end

ai_skill_askforag_default = ai_skill_askforag_default or function(self, options)
    if not options or options.candidates_complete ~= true then
        return unsupported("amazing-grace candidate completeness is unknown", "amazing_grace")
    end
    local ids = offered(options, "card_ids")
    if not ids then
        return options.optional and {kind = "pass"}
            or unsupported("amazing-grace candidates are missing", "amazing_grace")
    end
    local cards = known_cards(self, ids, options)
    if not cards then return unsupported("amazing-grace card metadata is incomplete", "amazing_grace") end
    local best, best_id
    for _, card in ipairs(cards) do
        local peach, use, keep, id = card:isKindOf("Peach"), self:getUseValue(card),
            self:getKeepValue(card), card:getEffectiveId()
        local better = not best or (peach and not best.peach)
            or (peach == best.peach and (use > best.use
                or (use == best.use and (keep < best.keep
                    or (keep == best.keep and id < best.id)))))
        if better then best, best_id = {peach = peach, use = use, keep = keep, id = id}, id end
    end
    return best_id
end

ai_skill_cardchosen_default = ai_skill_cardchosen_default or function(self, options)
    local ids = offered(options, "card_ids")
    if not ids then
        if options and options.optional and options.candidates_complete == true then return {kind="pass"} end
        return unsupported("card-chosen candidates are missing", "card_chosen")
    end
    local context = options.context or {}
    local target_name = context.who or context.target
    local target = target_name and self.room:findPlayerByObjectName(target_name, true)
    local relation = target == self.player and "friend" or (target and self:relationTo(target))
    local index, zones = card_index(self, options), {}
    -- Read only visible target zones. An offered opaque/native random slot can
    -- be returned unchanged, but it never becomes a fabricated CardView or ID.
    if target then
        for _, card in ipairs(target:getEquips() or {}) do zones[card:getEffectiveId()] = "e" end
        for _, card in ipairs(target:getJudgingArea() or {}) do zones[card:getEffectiveId()] = "j" end
        for _, card in ipairs(target:getKnownCards() or {}) do zones[card:getEffectiveId()] = "h" end
    end
    local poison, lose_equip, unknown = {}, false, nil
    if relation == "friend" then
        local equips = target:getEquips()
        if equips and #equips > 0 and type(self.poisonCards) == "function" then
            local ok, result = AIUnsupported.capture(function() return self:poisonCards(equips, target) end)
            if ok and result then
                for _, card in ipairs(result) do poison[card:getEffectiveId()] = true end
            elseif not ok then unknown = result end
        end
        if equips and #equips > 0 and type(self.loseEquipEffect) == "function" then
            local ok, result = AIUnsupported.capture(function() return self:loseEquipEffect(target) end)
            if ok then lose_equip = result == true else unknown = unknown or result end
        end
    end
    local best_id, best_priority, best_value
    for _, id in ipairs(ids) do
        local card = index._facade and self:getChoiceCard(id, options) or index[id]
        card = card or index[id]
        if card then
            local zone = zones[id]
            local priority, useful = 0, false
            -- Harmful judgments precede beneficial equipment loss; their fixed
            -- preference does not depend on an unrelated hand-card keep hook.
            if relation == "friend" and zone == "j"
                and (card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")) then
                priority, useful = 3, true
            elseif relation == "friend" and zone == "e" and (poison[id] or lose_equip) then
                priority, useful = 2, true
            elseif target and (relation == "friend" or relation == "enemy") then
                local ok, result = AIUnsupported.capture(function()
                    -- doDisCard is effect desirability, not the authority's
                    -- selection legality. False must not erase a forced option.
                    return self:doDisCard(target, id, context.method ~= sgs.Card_MethodDiscard)
                end)
                if ok then useful = result == true else unknown = unknown or result end
                if useful then priority = 1 end
            end
            local ok, value = true, 0
            if priority ~= 3 then ok, value = AIUnsupported.capture(function() return self:getKeepValue(card) end) end
            if not ok then unknown = unknown or value end
            if ok and finite_number(value) and (not options.optional or useful) then
                -- Against an enemy remove higher utility; ally/unknown forced
                -- selections minimize loss without inventing relation knowledge.
                if relation == "enemy" then value = -value end
                if best_id == nil or priority > best_priority or (priority == best_priority
                    and (value < best_value or value == best_value and id < best_id)) then
                    best_id, best_priority, best_value = id, priority, value
                end
            end
        end
    end
    note_unknown("card_chosen", unknown)
    if best_id ~= nil then return best_id end
    if options.optional then return {kind="pass"} end
    -- Each offered ID is authorized independently of metadata/completeness of
    -- other choices. Native validation still resolves/rejects opaque selections.
    return ids[math.random(#ids)]
end

ai_skill_askforyiji_default = ai_skill_askforyiji_default or function(self, options)
    if not options or options.candidates_complete ~= true then
        return unsupported("yiji candidate completeness is unknown", "yiji")
    end
    local ids, players = offered(options, "card_ids"), offered(options, "players")
    if not ids or not players then
        return options.optional and {kind = "pass"}
            or unsupported("yiji candidates are missing", "yiji")
    end
    local cards = known_cards(self, ids, options)
    local targets = AIList.new({})
    local allowed_targets, allowed_cards = {}, {}
    for _, id in ipairs(ids) do allowed_cards[id] = true end
    for _, name in ipairs(players) do
        allowed_targets[name] = true
        local target = self.room:findPlayerByObjectName(name, true)
        if target then targets[#targets + 1] = target end
    end
    local unknown
    if cards and type(self.getCardNeedPlayer) == "function" then
        local ok, gift = AIUnsupported.capture(function()
            local card, target = self:getCardNeedPlayer(AIList.new(cards), true, targets)
            if card and target then
                local id, name = card:getEffectiveId(), target:objectName()
                if allowed_cards[id] and allowed_targets[name] then
                    return {kind="answer", cards={id}, targets={name}}
                end
            end
        end)
        if ok and gift then return gift end
        if not ok then unknown = gift end
    end
    -- No profitable optional gift is a deliberate decline. A compulsory gift
    -- still needs an offered recipient, even when none is a known friend.
    if options.optional then
        if unknown then error(unknown, 0) end
        return {kind="pass"}
    end
    local pool, best_id, best_value = {}, nil, nil
    for _, target in ipairs(targets) do
        if self:relationTo(target) == "friend" then pool[#pool + 1] = target:objectName() end
    end
    if #pool == 0 then pool = players end
    for _, card in ipairs(cards or {}) do
        local ok, value = AIUnsupported.capture(function() return self:getKeepValue(card) end)
        local id = card:getEffectiveId()
        if ok and finite_number(value) and (best_id == nil or value < best_value
            or value == best_value and id < best_id) then
            best_id, best_value = id, value
        elseif not ok then
            unknown = unknown or value
        end
    end
    note_unknown("yiji", unknown)
    return {kind="answer", cards={best_id or ids[math.random(#ids)]},
        targets={pool[math.random(#pool)]}}
end

ai_skill_playerchosen_default = ai_skill_playerchosen_default or function(self, options)
    if options and options.optional then return {kind = "pass"} end
    local players = offered(options, "players")
    if not players then return unsupported("player-chosen candidates are missing", "player_chosen") end
    -- Match the server's mandatory fallback within the supplied candidates.
    return players[math.random(#players)]
end

ai_skill_playerschosen_default = ai_skill_playerschosen_default or function(self, options)
    local players = offered(options, "players")
    if not players then return unsupported("players-chosen candidates are missing", "players_chosen") end
    local min_count = type(options.min_count) == "number" and options.min_count or 0
    local max_count = type(options.max_count) == "number" and options.max_count or #players
    if min_count == 0 then return {kind = "pass"} end
    if min_count > #players or max_count < min_count then
        return unsupported("players-chosen bounds do not fit the candidate set", "players_chosen")
    end
    -- SmartAI fills an unhandled multi-player question to its minimum using
    -- RandomList. This VM's math.random is seeded and bounded by the authority.
    local candidates = {}
    for _, name in ipairs(players) do candidates[#candidates + 1] = name end
    for i = #candidates, 2, -1 do
        local j = math.random(i)
        candidates[i], candidates[j] = candidates[j], candidates[i]
    end
    local result = {}
    for i = 1, min_count do result[i] = candidates[i] end
    return result
end

ai_skill_guanxing_default = ai_skill_guanxing_default or function(self, options)
    local ids = offered(options, "card_ids")
    if not ids then return unsupported("guanxing cards are missing", "guanxing") end
    local mode = tostring(options.default_choice or "")
    if mode == "-1" then return {kind = "answer", cards = {}, bottom_cards = ids} end
    if mode ~= "0" and mode ~= "1" then return unsupported("guanxing direction is unknown", "guanxing") end
    local current = self.room:getCurrent()
    local phase = current and current:getPhase()
    local own_draw = current and current:objectName() == self.player:objectName()
        and type(phase) == "number" and phase <= sgs.Player_Draw
    local enemy_draw = current and type(phase) == "number" and phase <= sgs.Player_Draw
        and self:relationTo(current) == "enemy"
    local index, ordered, values = card_index(self, options), {}, {}
    local unknown
    for _, id in ipairs(ids) do
        ordered[#ordered + 1] = id
        local card = index._facade and self:getChoiceCard(id, options) or index[id]
        card = card or index[id]
        local value
        if card and own_draw then
            local ok, score = AIUnsupported.capture(function() return self:cardNeed(card) end)
            if ok and finite_number(score) then value = score end
            if not ok then unknown = unknown or score end
        end
        if card and value == nil then
            local ok, score = AIUnsupported.capture(function() return self:getUseValue(card) end)
            if ok and finite_number(score) then value = score end
            if not ok then unknown = unknown or score end
        end
        values[id] = value
    end
    -- A missing future beneficiary does not prevent a useful generic ordering.
    -- Unvalued cards retain their offered order, after cards with known utility.
    local positions = {}
    for position, id in ipairs(ids) do positions[id] = position end
    table.sort(ordered, function(a, b)
        local av, bv = values[a], values[b]
        if av == nil or bv == nil then
            if av ~= nil then return true end
            if bv ~= nil then return false end
            return positions[a] < positions[b]
        end
        if av ~= bv then
            if enemy_draw then return av < bv end
            return av > bv
        end
        return a < b
    end)
    -- Only an explicitly projected current judge can reserve the first card.
    -- Pending judging-area cards alone do not provide exact outcome semantics.
    local judge = type(self.getJudge) == "function" and self:getJudge() or nil
    if judge and judge.who and type(judge.isGood) == "function" then
        local relation = self:relationTo(judge.who)
        if relation == "friend" or relation == "enemy" then
            for position, id in ipairs(ordered) do
                local card = index._facade and self:getChoiceCard(id, options) or index[id]
                local good = card and judge:isGood(card)
                if type(good) == "boolean" and good == (relation == "friend") then
                    table.remove(ordered, position)
                    table.insert(ordered, 1, id)
                    break
                end
            end
        end
    end
    -- No draw-count prediction: absent an explicit count, retain all cards on
    -- top in utility order. An authority count can partition the same ordering.
    local count = options.context and options.context.draw_count
    if count == nil or mode == "1" then count = #ordered end
    if not finite_number(count) or count < 0 or count % 1 ~= 0 then
        return unsupported("guanxing draw count is invalid", "guanxing")
    end
    local top, bottom = {}, {}
    for position, id in ipairs(ordered) do
        local pile = position <= count and top or bottom
        pile[#pile + 1] = id
    end
    note_unknown("guanxing", unknown)
    return {kind="answer", cards=top, bottom_cards=bottom}
end

ai_skill_triggerorder_default = ai_skill_triggerorder_default or function(self, options)
    if options and options.optional then return {kind="pass"} end
    local choices = offered(options, "choices")
    if not choices then return unsupported("trigger-order candidates are missing", "trigger_order") end
    return choices[math.random(#choices)]
end

response_card_default = function(self, options, request)
    if not options then
        return unsupported("response options are missing", "respond_card")
    end
    local unknown
    local function mark_unknown(reason)
        unknown = unknown or AIUnsupported.new(reason, "respond_card")
    end
    local incomplete = options.candidates_complete ~= true
    if incomplete then
        mark_unknown("response candidate completeness is unknown")
    end
    if request.conversions_enumerated ~= true then mark_unknown("response conversion enumeration is unknown") end
    local ids = type(options.card_ids) == "table" and options.card_ids or nil
    if not ids then
        mark_unknown("response card candidates are missing")
        ids = {}
    end
    -- C++ already filtered this list against pattern, handling method and limits.
    -- Do not duplicate that rule engine in Lua.
    local virtual_ids = {}
    for _, card in ipairs(options.cards or {}) do
        if card.virtual_card == true or (type(card.subcards) == "table" and #card.subcards > 0) then
            if card.id ~= nil then virtual_ids[card.id] = true end
            if card.effective_id ~= nil then virtual_ids[card.effective_id] = true end
        end
    end
    local index = card_index(self, options)
    local best, best_id, best_value
    for _, id in ipairs(ids) do
        local card = index[id]
        if index._facade then card = self:getChoiceCard(id, options) or card end
        local subcards = card and card:getSubcards()
        local virtual = card and type(card.isVirtualCard) == "function" and card:isVirtualCard() == true
        if virtual_ids[id] or virtual or (subcards and #subcards > 0) then
            mark_unknown("response conversions need an explicit card spec")
        elseif not card then
            mark_unknown("response card metadata is incomplete")
        else
            local ok, value = AIUnsupported.capture(function() return self:getKeepValue(card) end)
            if not ok then
                unknown = unknown or value
            elseif not finite_number(value) then
                mark_unknown("response card value is invalid")
            elseif best_id == nil or value < best_value or value == best_value and id < best_id then
                best, best_id, best_value = id, id, value
            end
        end
    end

    -- A payment must be in the viewer's owned projection; offered response IDs
    -- alone cannot prove ownership of another card used to pay a conversion.
    local owned = {}
    for _, cards in ipairs({self.player:getHandcards() or {}, self.player:getEquips() or {}}) do
        for _, card in ipairs(cards) do owned[card:getId()] = card end
    end
    local conversions = self:getConversions() or {}
    for _, conversion in ipairs(conversions) do
        local ok, proposal = AIUnsupported.capture(function()
            local function field(method)
                local getter = conversion[method]
                if type(getter) ~= "function" then
                    return unsupported("response conversion metadata is missing: " .. method, "conversion")
                end
                return getter(conversion)
            end
            if type(conversion.isAvailable) ~= "function"
                or type(conversion:isAvailable()) ~= "boolean" then
                return unsupported("response conversion availability is unknown", "conversion")
            end
            if conversion:isAvailable() == false then return nil end
            local activation_quota, source_quota = field("isActivationQuotaAvailable"), field("isSourceQuotaAvailable")
            if activation_quota == false or source_quota == false then return nil end
            if activation_quota ~= true or source_quota ~= true then
                return unsupported("response conversion quota is unknown", "conversion")
            end
            if field("hasCompleteCoverage") ~= true then
                return unsupported("response conversion coverage is incomplete", "conversion")
            end
            for _, method in ipairs({"getActivationOwner", "getActivationSkillName", "getSourceOwner", "getSourceSkillName"}) do
                local value = field(method)
                if type(value) ~= "string" or value == "" then
                    return unsupported("response conversion provenance is incomplete", "conversion")
                end
            end
            for _, method in ipairs({"getActivationInstanceId", "getSourceInstanceID"}) do
                local value = field(method)
                if not finite_number(value) or value < 1 or value % 1 ~= 0 then
                    return unsupported("response conversion instance is invalid", "conversion")
                end
            end
            local ticket, name, suit, number = field("getConversionId"), field("getName"),
                field("getSuit"), field("getNumber")
            if not finite_number(ticket) or ticket < 1 or ticket % 1 ~= 0
                or type(name) ~= "string" or name == ""
                or not finite_number(suit) or suit % 1 ~= 0
                or not finite_number(number) or number % 1 ~= 0 then
                return unsupported("response conversion identity is incomplete", "conversion")
            end
            local bound = self:bindConversionCosts(conversion, owned)
            local payments, total, seen = bound:getSubcards(), 0, {}
            if not payments then return unsupported("response conversion costs are unknown", "conversion") end
            for _, id in ipairs(payments) do
                local payment = owned[id]
                if not finite_number(id) or id < 0 or id % 1 ~= 0 or seen[id]
                    or not payment or payment:getId() ~= id then
                    return unsupported("response conversion payment is not an owned unique card", "conversion")
                end
                seen[id] = true
                local value = self:getKeepValue(payment)
                if not finite_number(value) then return unsupported("response conversion cost value is invalid", "conversion") end
                total = total + value
            end
            local spec = bound:toCardSpec()
            if not finite_number(total) then return unsupported("response conversion total cost is invalid", "conversion") end
            -- Pattern/method matching and native construction belong to C++.
            -- Keep the exact ticket; a response does not invent target choices.
            return {answer={kind="answer", card_spec=spec}, value=total, id=bound:getEffectiveId()}
        end)
        if not ok then
            unknown = unknown or proposal
        elseif proposal and (best_id == nil or proposal.value < best_value
            or proposal.value == best_value and proposal.id < best_id) then
            best, best_id, best_value = proposal.answer, proposal.id, proposal.value
        end
    end
    if best ~= nil then
        note_unknown(request.kind, unknown)
        return best
    end
    -- Defer a discovered gap until every physical and converted answer was considered.
    if unknown then error(unknown, 0) end
    local compulsory = (request.pattern or ""):sub(-1) == "!"
    if options.optional and not compulsory then return {kind = "pass"} end
    return unsupported("response card has no known answer", "respond_card")
end

respond_defaults.askForCard = function(self, options, request)
    local effect = decision_context(self, options, request).effect
    local compulsory = (request.pattern or ""):sub(-1) == "!"
    -- A projected damage effect can justify declining a defence. Unknown desire
    -- retains the existing physical-card baseline, not a guessed damage benefit.
    if not compulsory and effect and effect.card and effect.from
        and (effect.card:isKindOf("Slash")
            or (type(effect.card.isDamageCard) == "function" and effect.card:isDamageCard()))
        and type(self.needToLoseHp) == "function"
        and self:needToLoseHp(self.player, legacy_player(self, effect.from), effect.card) == true then
        return {kind="pass"}
    end
    return response_card_default(self, options, request)
end
respond_defaults.askForNullification = function(self, options, request)
    local context = decision_context(self, options, request) or {}
    local card = context.card
    if type(card) == "table" and type(card.isKindOf) ~= "function" then card = CardView.new(card) end
    if not card or type(card.getClassName) ~= "function" or type(card.objectName) ~= "function"
        or type(card:getClassName()) ~= "string" or card:getClassName() == ""
        or type(card:objectName()) ~= "string" or card:objectName() == "" then
        return unsupported("nullification trick is unknown", "askForNullification")
    end
    if type(context.positive) ~= "boolean" then return unsupported("nullification polarity is unknown", "askForNullification") end
    local to, from = legacy_player(self, context.to), legacy_player(self, context.from)
    local to_relation = to == self.player and "friend" or (to and self:relationTo(to))
    if to_relation ~= "friend" and to_relation ~= "enemy" then return {kind="pass"} end
    -- Trick inheritance is not an effect classification: ExNihilo is a
    -- SingleTargetTrick too. Only these standard effects have a shared policy.
    local harmful = card:isKindOf("Duel") or card:isKindOf("SavageAssault")
        or card:isKindOf("ArcheryAttack") or card:isKindOf("FireAttack")
        or card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage") or card:isKindOf("Lightning")
    local beneficial = card:isKindOf("ExNihilo") or card:isKindOf("GodSalvation")
        or card:isKindOf("AmazingGrace")
    if card:isKindOf("Snatch") or card:isKindOf("Dismantlement") then
        local judging, equips, hand = to:getJudgingArea(), to:getEquips(), to:getHandcardNum()
        if not judging or not equips or not finite_number(hand) then return {kind="pass"} end
        local harmful_judge = false
        for _, delayed in ipairs(judging) do
            if delayed:isKindOf("Indulgence") or delayed:isKindOf("SupplyShortage") then harmful_judge = true end
        end
        local from_relation = from == self.player and "friend" or (from and self:relationTo(from))
        -- Removing an ally's detrimental judgment is a benefit. If ordinary
        -- cards coexist, source alignment supplies intent, never a guessed ID.
        if harmful_judge and ((hand == 0 and #equips == 0) or from_relation == to_relation) then
            beneficial, harmful = true, false
        elseif hand > 0 or #equips > 0 then
            if #judging > 0 and from_relation ~= "friend" and from_relation ~= "enemy" then return {kind="pass"} end
            harmful, beneficial = true, false
        else
            return {kind="pass"}
        end
    elseif card:isKindOf("IronChain") then
        local chained
        if type(to.isChained) == "function" then chained = to:isChained() end
        if type(chained) ~= "boolean" then return {kind="pass"} end
        -- The shared visible-state baseline values unchaining allies and
        -- chaining enemies; no elemental hit or secret hand is predicted.
        harmful, beneficial = not chained, chained
    elseif card:isKindOf("Collateral") then
        local weapon = to:getWeapon()
        local from_relation = from == self.player and "friend" or (from and self:relationTo(from))
        -- Weapon pressure is visible. The eventual Slash victim is not in this
        -- question, so same-side or unknown-source interactions conserve a card.
        if not weapon or (from_relation ~= "friend" and from_relation ~= "enemy")
            or from_relation == to_relation then return {kind="pass"} end
        harmful, beneficial = true, false
    elseif not harmful and not beneficial then
        local dynamic = type(sgs.dynamic_value) == "table" and sgs.dynamic_value or {}
        local function classified(key)
            local values = dynamic[key]
            if type(values) ~= "table" then return false end
            return values[card:getClassName()] == true or values[card:objectName()] == true
        end
        harmful = classified("damage_card") or classified("control_card") or classified("control_usecard")
        beneficial = classified("benefit")
    end
    if not harmful and not beneficial then
        return {kind="pass"}
    end
    if harmful and beneficial then return {kind="pass"} end
    local should_null = harmful and to_relation == "friend" or beneficial and to_relation == "enemy"
    if not context.positive then should_null = not should_null end
    if not should_null then return {kind = "pass"} end
    return response_card_default(self, options, request)
end
local function physical_choice_cards(self, ids, options)
    local cards = known_cards(self, ids, options)
    if not cards then return nil end
    local physical = {}
    for _, card in ipairs(cards) do
        local id, subcards = card:getEffectiveId(), card:getSubcards()
        local virtual = type(card.isVirtualCard) == "function" and card:isVirtualCard() == true
        if finite_number(id) and id >= 0 and id % 1 == 0 and not virtual
            and (not subcards or #subcards == 0) then
            physical[#physical + 1] = card
        end
    end
    return physical
end
respond_defaults.askForCardShow = function(self, options)
    local ids = offered(options, "card_ids")
    if not ids then return unsupported("card-show candidates are missing", "askForCardShow") end
    local cards = physical_choice_cards(self, ids, options)
    local selected, best_value, unknown
    for _, card in ipairs(cards or {}) do
        local ok, value = AIUnsupported.capture(function() return self:getKeepValue(card) end)
        local id = card:getEffectiveId()
        if not ok then unknown = unknown or value end
        if ok and finite_number(value) and (selected == nil or value < best_value
            or value == best_value and id < selected) then
            selected, best_value = id, value
        end
    end
    if selected == nil and cards and #cards > 0 then selected = cards[math.random(#cards)]:getEffectiveId() end
    note_unknown("askForCardShow", unknown)
    return selected or unsupported("card-show physical metadata is incomplete", "askForCardShow")
end
respond_defaults.askForPindian = function(self, options)
    if not options or options.candidates_complete ~= true then
        return unsupported("pindian candidate completeness is unknown", "askForPindian")
    end
    local ids = offered(options, "card_ids")
    local cards = ids and physical_choice_cards(self, ids, options)
    if not cards or #cards == 0 then return unsupported("pindian card metadata is incomplete", "askForPindian") end
    local requestor = options.players and options.players[1]
    local target = requestor and self.room:findPlayerByObjectName(requestor, true)
    local relation = target and self:relationTo(target) or nil
    local friend = relation == "friend" and target ~= self.player
    local best_id, best_number, best_keep, unknown
    for _, card in ipairs(cards) do
        local number = type(card.getNumber) == "function" and card:getNumber() or nil
        local id = card:getEffectiveId()
        local ok, keep = AIUnsupported.capture(function() return self:getKeepValue(card) end)
        if not ok then unknown = unknown or keep end
        if not ok or not finite_number(keep) then keep = math.huge end
        local known_number = finite_number(number)
        local better_number = known_number and (best_number == nil
            or (friend and number < best_number) or (not friend and number > best_number))
        local same_number = (known_number and number == best_number) or (not known_number and best_number == nil)
        if best_id == nil or better_number or (same_number and (keep < best_keep
            or keep == best_keep and id < best_id)) then
            best_id, best_number, best_keep = id, known_number and number or nil, keep
        end
    end
    note_unknown("askForPindian", unknown)
    return best_id
end

-- Peach response is safe only when the authority's pattern identifies a Peach
-- response; whether spending it is desirable remains an effect-level decision.
respond_defaults.askForSinglePeach = function(self, options, request)
    local pattern = request and request.pattern or ""
    if not string.lower(pattern):find("peach", 1, true) then return nil end
    local target_name = options and options.players and options.players[1]
    if not target_name then return unsupported("dying player is not projected", "askForSinglePeach") end
    local target = self.room:findPlayerByObjectName(target_name, true)
    if not target then return unsupported("dying player is unknown", "askForSinglePeach") end
    local relation = target == self.player and "friend" or self:relationTo(target)
    -- Saving an enemy or an unclassified player needs an explicit skill policy;
    -- conserving Peach is a valid shared strategy, not a missing legal answer.
    if relation ~= "friend" then return {kind="pass"} end
    return response_card_default(self, options, request)
end
