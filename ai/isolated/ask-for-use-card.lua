-- Two registries, one per callback ABI. The argument lists never mix: a new handler
-- takes (self, prompt, request); a legacy-style handler takes
-- (self, prompt, method, pattern, request) exactly as SmartAI:askForUseCard calls it.
local pattern_handlers = {}
local skill_handlers = {}
local legacy_pattern_handlers = {}
local legacy_skill_handlers = {}

-- One key belongs to one ABI. A key registered in both has no verifiable dispatch
-- rule, so the conflict is refused at registration instead of resolved silently.
local function register_handler(registry, conflicting, key, handler)
    if type(key) ~= "string" or key == "" or type(handler) ~= "function" then
        error("invalid isolated askForUseCard handler")
    end
    if conflicting[key] then
        error("askForUseCard handler already registered with the other ABI: " .. key)
    end
    registry[key] = handler
end

local function registry_table(registry, conflicting)
    return setmetatable({}, {
        __index = registry,
        __newindex = function(_, pattern, handler)
            register_handler(registry, conflicting, pattern, handler)
        end
    })
end

ai_skill_use = registry_table(pattern_handlers, legacy_pattern_handlers)
ai_skill_use_legacy = registry_table(legacy_pattern_handlers, pattern_handlers)

function ai_register_use_card_handler(pattern, handler)
    ai_skill_use[pattern] = handler
end

function ai_register_use_card_skill_handler(skill_name, handler)
    register_handler(skill_handlers, legacy_skill_handlers, skill_name, handler)
end

function ai_register_use_card_legacy_handler(pattern, handler)
    ai_skill_use_legacy[pattern] = handler
end

function ai_register_use_card_legacy_skill_handler(skill_name, handler)
    register_handler(legacy_skill_handlers, skill_handlers, skill_name, handler)
end

-- The legacy request view exists only for skill actions, like the native
-- AiLegacyRequestView legacy AI receives; a plain pattern request passes nil.
local function call_handler(self, request, key, registry, legacy_registry, pattern)
    local handler = registry[key]
    if handler then
        return AIResultValue.normalize(handler(self, request.prompt, request), request.kind)
    end
    handler = legacy_registry[key]
    if not handler then return nil, "unhandled" end
    return AIResultValue.normalize(handler(self, request.prompt, request.handling_method,
        pattern, AILegacyRequest.new(request, self.room)), request.kind)
end

local function registry_keys(...)
    local registries = {...}
    return function()
        local keys = {}
        for _, registry in ipairs(registries) do
            for key in pairs(registry) do keys[#keys + 1] = key end
        end
        return keys
    end
end

if type(ai_coverage) == "table" then
    ai_coverage.declare("use_card", registry_keys(pattern_handlers, legacy_pattern_handlers))
    ai_coverage.declare("use_card_skill", registry_keys(skill_handlers, legacy_skill_handlers))
end

-- ResponseUse has a different question from Play: the authority already offered
-- cards that match the response pattern, while the AI still has to choose targets
-- and, for view-as actions, name an authority-issued conversion ticket.  Keep this
-- registry separate from ai_card_use so a play-only strategy cannot answer a response.
local response_use_handlers = {}

local function register_response_use_handler(key, handler)
    if type(key) ~= "string" or key == "" or type(handler) ~= "function" then
        error("invalid isolated response-use handler")
    end
    if response_use_handlers[key] ~= nil then
        error("isolated response-use handler already registered: " .. key)
    end
    response_use_handlers[key] = handler
end

ai_card_response_use = setmetatable({}, {
    __index = response_use_handlers,
    __newindex = function(_, key, handler)
        register_response_use_handler(key, handler)
    end,
})

function ai_register_response_use_handler(key, handler)
    register_response_use_handler(key, handler)
end

if type(ai_coverage) == "table" then
    ai_coverage.declare("response_use", function()
        local keys = {}
        for key in pairs(response_use_handlers) do keys[#keys + 1] = key end
        return keys
    end)
end

local function response_handler(card)
    local object_name, class_name = card:objectName(), card:getClassName()
    return (object_name and response_use_handlers[object_name])
        or (class_name and response_use_handlers[class_name])
        or (card:isKindOf("Slash") and response_use_handlers.Slash)
        or (card:isKindOf("EquipCard") and response_use_handlers.EquipCard)
end

local function response_candidate_ready(candidate, key, is_conversion)
    if not candidate then
        ai_unsupported("the response candidate is missing", key)
    end
    local is_available = candidate.isAvailable
    if type(is_available) ~= "function" then
        ai_unsupported("the response candidate has no availability metadata", key)
    end
    local available = is_available(candidate)
    if available == nil then
        ai_unsupported("the response candidate has no availability metadata", key)
    end
    if available ~= true then return false end
    if not is_conversion and type(candidate.isLimited) ~= "function" then
        ai_unsupported("the response candidate does not describe its limits", key)
    end
    if not is_conversion then
        if candidate:isLimited() == nil then ai_unsupported("response limits are unknown", key) end
        if candidate:isLimited() then return false end
    end
    if type(candidate.hasCompleteCoverage) ~= "function"
        or type(candidate.getLegalTargets) ~= "function"
        or type(candidate.getTargetCombinations) ~= "function" then
        ai_unsupported("response target coverage metadata is missing", key)
    end
    if candidate:hasCompleteCoverage() ~= true
        or candidate:getLegalTargets() == nil
        or candidate:getTargetCombinations() == nil then
        ai_unsupported("response target coverage is incomplete", key)
    end
    return true
end

local function response_owned_cards(self)
    local hand = self.player:getHandcards()
    local equips = self.player:getEquips()
    local by_id = {}
    for _, cards in ipairs({hand or {}, equips or {}}) do
        if cards then
            for _, card in ipairs(cards) do
                by_id[card:getEffectiveId()] = card
            end
        end
    end
    return by_id, not hand or not equips
end

local function response_plan(self, card, candidate, request)
    local handler = response_handler(card)
    if not handler then
        ai_unsupported("no response-use strategy for this offered card", card:getClassName())
    end
    local result = handler(self, card, candidate, request)
    if AIUnsupported and AIUnsupported.is and AIUnsupported.is(result) then
        error(result, 0)
    end
    if result and type(result.toAnswer) == "function" then
        local names = {}
        for _, target in ipairs(result.to or {}) do names[#names + 1] = target:objectName() end
        local _, finish = candidate:getTargetSelection(names)
        if finish ~= true then ai_unsupported("response strategy proposed illegal targets", "targets") end
        return result:toAnswer()
    end
    local answer, status = AIResultValue.normalize(result, request.kind)
    if status == "declined" or status == "pass" or status == "unhandled" then return nil end
    return answer
end

local function generic_response_use(self, request)
    local method_use = sgs.Card_MethodUse
    if request.reason ~= 0x12 or request.handling_method ~= method_use then return nil end
    if type(request.pattern) == "string" and string.sub(request.pattern, 1, 1) == "@" then return nil end

    -- A skill probe is answered only by its explicit skill tier, or by an
    -- authority-issued conversion carrying the same activation/source identity.
    -- Never let an unrelated physical card satisfy that probe.
    local skill_action = type(request.skill_action) == "table"
        and request.skill_action or nil

    local unknown_coverage
    local function mark_unknown(reason, key)
        unknown_coverage = unknown_coverage or AIUnsupported.new(reason, key)
    end
    -- A partial conversion list is retained as an unknown branch.  It must not
    -- hide a separately offered, fully legal physical response.
    if self:hasEnumeratedConversions() ~= true then
        mark_unknown("the response request does not enumerate all conversions", "conversion")
    end

    local actions = {}
    local owned, owned_unknown = response_owned_cards(self)
    if owned_unknown then mark_unknown("owned card projection is incomplete", "response_use") end
    local candidates = self:getCardCandidates()
    if candidates == nil then
        mark_unknown("the response request does not describe physical candidates", "response_use")
        candidates = {}
    end
    if not skill_action then
        for _, candidate in ipairs(candidates) do
            local ok, ready = AIUnsupported.capture(function()
                return response_candidate_ready(candidate, "response_use")
            end)
            if not ok then mark_unknown(ready.reason, ready.key) end
            if ok and ready == true then
                local card = owned[candidate:getCardId()]
                if not card then
                    mark_unknown("an offered response card is not in the viewer hand", "response_use")
                else
                    actions[#actions + 1] = {card = card, candidate = candidate}
                end
            end
        end
    end

    local conversions = self:getConversions()
    if conversions == nil then
        mark_unknown("the response request does not describe conversions", "conversion")
        conversions = {}
    end
    for _, conversion in ipairs(conversions) do
        local ok, matches = AIUnsupported.capture(function()
            if type(conversion.isAvailable) ~= "function" then
                ai_unsupported("a conversion has no response availability flag", "conversion")
            end
            local available = conversion:isAvailable()
            if available == nil then
                ai_unsupported("a conversion has no response availability flag", "conversion")
            end
            return available
        end)
        if not ok then
            mark_unknown(matches.reason, matches.key)
        elseif matches then
            -- The authority already applied the request pattern and handling method
            -- while building this conversion row.  Reimplementing expression-pattern
            -- matching here would create a second, weaker legality gate.
            local matches_skill = true
            if skill_action then
                matches_skill = conversion:getActivationOwner() == skill_action.activation_owner
                    and conversion:getActivationSkillName() == skill_action.activation_skill
                    and conversion:getActivationInstanceId() == skill_action.activation_instance
                    and conversion:getSourceOwner() == skill_action.source_owner
                    and conversion:getSourceSkillName() == skill_action.source_skill
                    and conversion:getSourceInstanceID() == skill_action.source_instance
            end
            local bound_ok, bound = true, conversion
            if matches_skill then
                bound_ok, bound = AIUnsupported.capture(function()
                    return self:bindConversionCosts(conversion, owned)
                end)
                if not bound_ok then mark_unknown(bound.reason, bound.key) end
            end
            if not matches_skill then
                -- This conversion belongs to another skill probe.
            elseif not bound_ok then
                -- Cost binding is unknown; keep the branch audited without
                -- calling methods on the unsupported signal object.
            else
                conversion = bound
                local candidate = conversion
                local candidate_ok, candidate_ready = AIUnsupported.capture(function()
                    return response_candidate_ready(candidate, conversion:getClassName(), true)
                end)
                if not candidate_ok then mark_unknown(candidate_ready.reason, candidate_ready.key) end
                if candidate_ok and candidate_ready == true then
                    actions[#actions + 1] = {card = conversion, candidate = candidate}
                end
            end
        end
    end

    -- Validate each offered action independently. Unknown branches are recorded
    -- while known actions remain eligible to answer this request.
    for _, action in ipairs(actions) do
        if not response_handler(action.card) then
            mark_unknown("an offered response action has no strategy", action.card:getClassName())
        end
    end
    local best, best_priority, best_cost, best_id
    for _, action in ipairs(actions) do
        local card = action.card
        local ok, answer = AIUnsupported.capture(function()
            if not response_handler(card) then return nil end
            return response_plan(self, card, action.candidate, request)
        end)
        if not ok then
            mark_unknown(answer.reason, answer.key)
            answer = nil
        end
        if answer ~= nil then
            local score_ok, score = AIUnsupported.capture(function()
                local total = 0
                local priority = self:getUsePriority(card)
                local payments = AIValue.isConversion(card) and card:getSubcards()
                    or {card:getEffectiveId()}
                if not payments then ai_unsupported("response costs are unknown", "conversion") end
                for _, id in ipairs(payments) do
                    local payment = owned[id]
                    if not payment then ai_unsupported("response payment is not projected", "conversion") end
                    total = total + self:getKeepValue(payment)
                end
                return {priority = priority, cost = total}
            end)
            if not score_ok then
                mark_unknown(score.reason, score.key)
                score = nil
            end
            if score ~= nil then
                local id = card:getEffectiveId()
                if not best or score.priority > best_priority
                    or score.priority == best_priority
                        and (score.cost < best_cost or score.cost == best_cost and id < best_id) then
                    best, best_priority, best_cost, best_id = answer, score.priority, score.cost, id
                end
            end
        end
    end
    if best then
        if unknown_coverage and type(ai_coverage) == "table" then
            ai_coverage.notCovered(request.kind, unknown_coverage.reason, unknown_coverage.key)
        end
        return best
    end
    if unknown_coverage then
        error(unknown_coverage, 0)
    end
    return nil
end

-- Standard response strategies.  They deliberately cover only the safe common
-- cases; skill-specific response effects stay extensible through the registry.
register_response_use_handler("Slash", function(self, card, candidate, request)
    -- Matching expression patterns is authority-owned; a literal "slash" gate
    -- would reject valid Slash|red or combined response patterns.
    local chosen = self:planTargetSequence(candidate, "enemy")
    if not chosen then return nil end
    local plan = AIUsePlan.new()
    plan.card, plan.to = card, chosen
    local get_candidate_id = candidate.getCandidateId
    if type(get_candidate_id) == "function" then
        plan.candidate_id = get_candidate_id(candidate)
    end
    return plan
end)

register_response_use_handler("Peach", function(self, card, candidate, request)

    if not self.player:isWounded() then return nil end
    if candidate:needsATarget() then
        ai_unsupported("Peach response unexpectedly requires a target", "Peach")
    end
    local plan = AIUsePlan.new()
    plan.card = card
    local get_candidate_id = candidate.getCandidateId
    if type(get_candidate_id) == "function" then
        plan.candidate_id = get_candidate_id(candidate)
    end
    return plan
end)

-- Common response decisions use the offered action space directly. They never
-- change request.reason/kind to sneak through a play-only ai_card_use handler.
local function fixed_response(_, card, candidate)
    if not candidate:targetFixed() or candidate:isFeasibleWithNoTarget() ~= true then
        ai_unsupported("response requires an effect-specific target strategy", card:getClassName())
    end
    local plan = AIUsePlan.new()
    plan.card = card
    if type(candidate.getCandidateId) == "function" then plan.candidate_id = candidate:getCandidateId() end
    return plan
end
register_response_use_handler("ExNihilo", fixed_response)
register_response_use_handler("Jink", fixed_response)
register_response_use_handler("EquipCard", function(self, card, candidate)
    local slot = card:getEquipSlot()
    if type(slot) ~= "number" or slot < 0 then ai_unsupported("response equipment slot is unknown", "EquipCard") end
    local id = self.player:getEquip(slot)
    if id ~= nil then
        local equips, current = self.player:getEquips(), nil
        if not equips then ai_unsupported("equipped card projection is unknown", "EquipCard") end
        for _, equip in ipairs(equips) do if equip:getEffectiveId() == id then current = equip break end end
        if not current then ai_unsupported("equipped card identity is unknown", "EquipCard") end
        if self:getUseValue(card) <= self:getUseValue(current) then return nil end
    end
    return fixed_response(self, card, candidate)
end)

local function hostile_response(self, card, candidate)
    local chosen = self:planTargetSequence(candidate, "enemy")
    if not chosen then return nil end
    local plan = AIUsePlan.new()
    plan.card, plan.to = card, chosen
    if type(candidate.getCandidateId) == "function" then plan.candidate_id = candidate:getCandidateId() end
    return plan
end
for _, name in ipairs({"Duel", "Snatch", "Dismantlement", "Indulgence", "SupplyShortage"}) do
    register_response_use_handler(name, hostile_response)
end

local function global_response(self, card, candidate)
    local affected = candidate:getAffectedTargets()
    if not affected then ai_unsupported("response affected targets are unknown", card:getClassName()) end
    local score = 0
    for _, name in ipairs(affected) do
        local target = self.room:findPlayerByObjectName(name, true)
        if not target then ai_unsupported("response affected player is unknown", "targets") end
        local friend, enemy = self:isFriend(target), self:isEnemy(target)
        if friend ~= true and enemy ~= true then ai_unsupported("response relation is unknown", "targets") end
        local hook = ai_card_effect and (ai_card_effect[card:getClassName()] or ai_card_effect[card:objectName()])
        local value
        if type(hook) == "function" then
            value = hook(self, card, target, friend and "friend" or "enemy")
        elseif card:getClassName() == "GodSalvation" then
            value = target:isWounded() and (friend and 1 or -1) or 0
        elseif card:getClassName() == "AmazingGrace" then
            value = friend and 1 or -1
        else
            value = enemy and 1 or -1
        end
        if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
            ai_unsupported("invalid response effect value", card:getClassName())
        end
        score = score + value
    end
    if score <= 0 then return nil end
    return fixed_response(self, card, candidate)
end
for _, name in ipairs({"AmazingGrace", "GodSalvation", "SavageAssault", "ArcheryAttack"}) do
    register_response_use_handler(name, global_response)
end

ai_register_handler("use_card", function(self, request)
    -- Legacy keeps the trailing "!" in the registry key, hands the stripped pattern to
    -- the callback, and refuses a "." answer for a compulsory request. The legacy
    -- cardEffect decline between the pattern and prompt tiers needs event context that
    -- the snapshot does not carry, so it stays uncovered instead of being guessed.
    local raw_pattern = type(request.pattern) == "string" and request.pattern or ""
    local compulsory = string.sub(raw_pattern, -1) == "!"
    local pattern = compulsory and string.sub(raw_pattern, 1, -2) or raw_pattern
    local prompt_key = type(request.prompt) == "string"
        and string.match(request.prompt, "^[^:]*") or nil
    local tiers = {}
    if type(request.skill_action) == "table" then
        tiers[#tiers + 1] = {skill_handlers, legacy_skill_handlers,
            request.skill_action.activation_skill}
    end
    tiers[#tiers + 1] = {pattern_handlers, legacy_pattern_handlers, raw_pattern}
    tiers[#tiers + 1] = {pattern_handlers, legacy_pattern_handlers, prompt_key}
    for _, tier in ipairs(tiers) do
        local key = tier[3]
        if type(key) == "string" and key ~= "" then
            local result, status = call_handler(self, request, key, tier[1], tier[2], pattern)
            if status ~= "unhandled" and not (compulsory
                and (status == "declined" or status == "pass")) then
                return result
            end
        end
    end
    -- Generic ResponseUse is intentionally after all explicit legacy/new handlers:
    -- extension callbacks keep their original precedence, while the common planner
    -- only claims a whole request when every offered action is covered.
    if request.reason == 0x12 then
        local result, status = AIResultValue.normalize(
            generic_response_use(self, request), request.kind)
        if compulsory and (status == "declined" or status == "pass") then
            return nil
        end
        return result
    end
    return nil
end)
