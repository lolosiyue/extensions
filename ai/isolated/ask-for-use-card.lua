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
        -- Package ownership snapshots and post-registration wrappers must see
        -- the same callbacks as indexed reads, without changing either ABI.
        __pairs = function()
            return function(_, key) return next(registry, key) end, nil, nil
        end,
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

-- Normalization reports returned signals as (nil, "unsupported"). Preserve the
-- signal itself before that conversion so the request boundary retains its
-- reason/key, exactly as when a callback throws the same signal.
local function covered_value(value)
    if AIUnsupported.is(value) then error(value, 0) end
    return value
end

local function normalize_handler_result(value, kind)
    return AIResultValue.normalize(covered_value(value), kind)
end

-- The legacy request view exists only for skill actions, like the native
-- AiLegacyRequestView legacy AI receives; a plain pattern request passes nil.
local function call_handler(self, request, key, registry, legacy_registry, pattern)
    local handler = registry[key]
    if handler then
        return normalize_handler_result(handler(self, request.prompt, request), request.kind)
    end
    handler = legacy_registry[key]
    if not handler then return nil, "unhandled" end
    local value = covered_value(handler(self, request.prompt, request.handling_method,
        pattern, AILegacyRequest.new(request, self.room)))
    -- Ordinary SmartAI ignores scalar non-string callback returns. Pure typed
    -- action tables are the migration ABI for the donor's serialized answer.
    if type(value) ~= "string" and type(value) ~= "table" then return nil, "unhandled" end
    local answer, status = normalize_handler_result(value, request.kind)
    if value == "" then status = "empty_string" end
    if type(value) == "table" and value.accepted ~= nil and type(request.skill_action) == "table" then status = "request_table" end
    return answer, status
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

local shared_response

local function response_handler(card)
    local object_name, class_name = card:objectName(), card:getClassName()
    return (object_name and response_use_handlers[object_name])
        or (class_name and response_use_handlers[class_name])
        or (card:isKindOf("Slash") and response_use_handlers.Slash)
        or (card:isKindOf("EquipCard") and response_use_handlers.EquipCard)
        or shared_response
end

local function response_candidate_ready(candidate, key, is_conversion, planning_only, skip_match)
    if not candidate then
        ai_unsupported("the response candidate is missing", key)
    end
    local is_available = candidate.isAvailable
    if type(is_available) ~= "function" then
        ai_unsupported("the response candidate has no availability metadata", key)
    end
    local available = covered_value(is_available(candidate))
    if type(available) ~= "boolean" then
        ai_unsupported("the response candidate has no availability metadata", key)
    end
    if not skip_match and not available then return false end
    if not planning_only and not is_conversion and type(candidate.isLimited) ~= "function" then
        ai_unsupported("the response candidate does not describe its limits", key)
    end
    if not planning_only and not is_conversion then
        local limited = covered_value(candidate:isLimited())
        if type(limited) ~= "boolean" then ai_unsupported("response limits are unknown", key) end
        if limited then return false end
    end
    if type(candidate.hasCompleteCoverage) ~= "function"
        or type(candidate.getLegalTargets) ~= "function"
        or type(candidate.getTargetCombinations) ~= "function" then
        ai_unsupported("response target coverage metadata is missing", key)
    end
    if covered_value(candidate:hasCompleteCoverage()) ~= true
        or covered_value(candidate:getLegalTargets()) == nil
        or covered_value(candidate:getTargetCombinations()) == nil then
        ai_unsupported("response target coverage is incomplete", key)
    end
    return true
end

local function rejected_response(reason, key)
    local signal = AIUnsupported.new(reason, key)
    signal.native_rejected = true
    signal.terminal_response_selection = true
    error(signal, 0)
end

local function selected_targets(candidate, names, reason)
    local _, finish = candidate:getTargetSelection(names)
    covered_value(finish)
    if type(finish) ~= "boolean" then ai_unsupported("selected response target coverage is unknown", "targets") end
    if not finish then rejected_response(reason, "response_selection") end
end

local function response_plan(self, card, candidate, request, submission_card, mode)
    local handler = response_handler(card)
    if not handler then
        ai_unsupported("no response-use strategy for this offered card", card:getClassName())
    end
    local result = handler(self, card, candidate, request, mode)
    if AIUnsupported and AIUnsupported.is and AIUnsupported.is(result) then
        error(result, 0)
    end
    if result and type(result.toAnswer) == "function" then
        local selected, answer = AIUnsupported.capture(function()
        local names = {}
        for _, target in ipairs(result.to or {}) do names[#names + 1] = target:objectName() end
        if not submission_card and result.card ~= card then
            candidate = result.card and covered_value(self:getCardCandidate(result.card:getEffectiveId()))
            if not candidate then ai_unsupported("revised response card has no candidate", "targets") end
        end
        selected_targets(candidate, names, "response strategy proposed illegal targets")
        if submission_card and type(submission_card.isEvaluationOnly) == "function" and submission_card:isEvaluationOnly() then
            local ok, bound = AIUnsupported.capture(function()
                local materializer = self._response_selected_specs and self._response_selected_specs[submission_card]
                    and self.materializeResponseSelectedCard or self.materializeOriginalSelectedCard
                if type(materializer) ~= "function" then
                    ai_unsupported("selected response materializer is unavailable", "response_selection")
                end
                local selected = covered_value(materializer(self, submission_card))
                if not AIValue.isConversion(selected) then ai_unsupported("Original selected response has no receipt", "Original.getCard") end
                local native = covered_value(self:getCardCandidate(selected:getEffectiveId()))
                if not native then ai_unsupported("Original selected response has no native candidate", "Original.getCard") end
                local matches = covered_value(selected:matchesResponsePattern())
                if type(matches) ~= "boolean" then ai_unsupported("Original selected response pattern is unknown", "Original.getCard") end
                if not matches or not response_candidate_ready(native, selected:getClassName(), true) then
                    rejected_response("Original selected response is not native admissible", "Original.getCard")
                end
                selected_targets(native, names, "Original selected response targets were rejected")
                return selected
            end)
            if not ok then
                -- The donor already selected this use. Native rejection must
                -- not cause the class loop to choose a different policy result.
                bound.terminal_response_selection = true
                error(bound, 0)
            end
            submission_card = bound
        end
        local final_card = submission_card or result.card
        local final_candidate = covered_value(self:getCardCandidate(final_card:getEffectiveId()))
        if not final_candidate then ai_unsupported("selected response has no native candidate", "response_selection") end
        if not response_candidate_ready(final_candidate, final_card:getClassName(), AIValue.isConversion(final_card)) then
            rejected_response("selected response is rejected by native availability or limits", "response_selection")
        end
        selected_targets(final_candidate, names, "selected response targets are rejected by native authority")
        if submission_card then
            local planned_card, evaluation = result.card, result._evaluation_only
            result.card, result._evaluation_only = submission_card, nil
            local ok, answer = pcall(result.toAnswer, result)
            result.card, result._evaluation_only = planned_card, evaluation
            if not ok then error(answer, 0) end
            return covered_value(answer)
        end
        return covered_value(result:toAnswer())
        end)
        if not selected then
            answer.terminal_response_selection = true
            error(answer, 0)
        end
        return answer
    end
    local answer, status = normalize_handler_result(result, request.kind)
    if status == "declined" or status == "pass" then
        return mode == "physical" and answer or nil
    end
    if status == "unhandled" then return nil end
    return answer
end

-- Legacy response policy callbacks choose their own costs. A policy proposal is
-- only a description to match against a current authority ticket, never a card
-- constructor. Keep this dispatch separate from legal-candidate enumeration.
local response_identity = {
    {"activation_owner", "getActivationOwner"},
    {"activation_skill", "getActivationSkillName"},
    {"activation_instance", "getActivationInstanceId"},
    {"source_owner", "getSourceOwner"},
    {"source_skill", "getSourceSkillName"},
    {"source_instance", "getSourceInstanceID"}
}

local function policy_known(value, field)
    covered_value(value)
    if value == nil then ai_unsupported("response policy projection is unknown: " .. field, "conversion_policy") end
    return value
end

function SmartAIView:getConversionPolicy(class_name, context)
    local projected = self.request.conversion_policy
    local policy = type(projected) == "table" and type(projected.by_class) == "table"
        and projected.by_class[class_name] or nil
    if policy then
        if policy.complete ~= true or not AIValue.isList(policy.skills) then
            ai_unsupported("response class policy is incomplete", class_name)
        end
        if context then
            for _, field in ipairs({"reason", "pattern", "prompt"}) do
                if context[field] ~= nil and (type(policy.context) ~= "table"
                    or context[field] ~= policy.context[field]) then
                    ai_unsupported("response policy belongs to another callback context", class_name)
                end
            end
        end
        return policy
    end
    -- This VM's registries decide which skills can convert: a skill without an
    -- isolated view-as, cardsView or guhuo callback contributes nothing. Whether a
    -- V1 view-as is enabled at this response is not projected, so a skill that
    -- does have a callback stays unknown until that field exists.
    local skills = policy_known(self.player:getSkills(), "skill roster")
    local registries = {"ai_view_as", "ai_cardsview_valuable", "ai_cardsview", "ai_guhuo_card"}
    -- SmartAI asks isEnabledAtResponse with the class's card name (peach+analeptic
    -- while the viewer is dying); the owner's skill views carry the basic ones.
    local pattern = AICardCatalog.patternName(class_name) or nil
    local dying = (class_name == "Peach" or class_name == "Analeptic") and self.room:getCurrentDyingPlayer()
    if dying and dying:objectName() == self.player:objectName() then
        pattern = "peach+analeptic"
    end
    local rows, seen = {}, {}
    for _, skill in ipairs(skills) do
        local name = skill:objectName()
        if type(name) == "string" and not seen[name] then
            seen[name] = true
            local hooks, keys, any = {}, {}, false
            for _, registry in ipairs(registries) do
                local callbacks = sgs[registry]
                hooks[registry] = type(callbacks) == "table" and type(callbacks[name]) == "function"
                keys[registry] = name
                any = any or hooks[registry]
            end
            if any then
                -- A V2 skill offered for this request answers with the request's own
                -- conversion tickets; a V1 skill's response enablement is not projected.
                local action = self:getSkillAction(name)
                local identity
                if action and type(action._view) == "table" then
                    identity = {}
                    for key, value in pairs(action._view) do identity[key] = value end
                end
                local ids = {}
                for _, row in ipairs(self.request.card_conversions or {}) do
                    if row.activation_skill == name then ids[#ids + 1] = row.conversion_id end
                end
                local responses = skill._view and skill._view.enabled_at_response
                local enabled = identity and true or nil
                if enabled == nil and type(responses) == "table" and pattern then enabled = responses[pattern] end
                rows[#rows + 1] = {skill_name = name, legacy_hooks = hooks, legacy_hook_keys = keys,
                    request = false, view_as_exists = skill._view and skill._view.has_view_as_skill,
                    enabled_at_response = enabled, identity = identity,
                    conversion_ids = ids}
            end
        end
    end
    return {complete = true, skills = rows, card_name = AICardCatalog.patternName(class_name) or nil}
end

local function policy_has_callback(row, registry)
    if type(row.legacy_hooks) ~= "table" then
        ai_unsupported("legacy response callback presence is unknown", registry)
    end
    local presence = row.legacy_hooks[registry]
    if type(presence) ~= "boolean" then
        ai_unsupported("legacy response callback presence is unknown", registry)
    end
    return presence
end

local function policy_callback(row, registry, request)
    if not policy_has_callback(row, registry) then return nil end
    -- The donor may choose a source-skill fallback even when a stale isolated
    -- primary callback happens to exist. Only native lookup metadata selects it.
    local key = type(row.legacy_hook_keys) == "table" and row.legacy_hook_keys[registry]
    if type(key) ~= "string" or key == "" or (key ~= row.skill_name
        and (not request or key ~= request:getSourceSkillName())) then
        ai_unsupported("legacy response callback lookup key is unknown", row.skill_name .. ":" .. registry)
    end
    local callbacks = sgs[registry]
    local callback = type(callbacks) == "table" and callbacks[key]
    if type(callback) ~= "function" then
        ai_unsupported("legacy response callback has no isolated policy", key .. ":" .. registry)
    end
    return callback, key
end

local function policy_request(self, row, context)
    if row.request == false then return nil end
    if type(row.request) ~= "table" then
        ai_unsupported("cardsView action-context presence is unknown", row.skill_name)
    end
    local request = {viewer = self.request.viewer, decision_id = self.request.decision_id,
        state_revision = self.request.state_revision, kind = self.request.kind}
    for _, field in ipairs({"reason", "pattern", "prompt", "handling_method"}) do
        request[field] = row.request[field]
    end
    if type(context) == "table" and context.prompt ~= nil then request.prompt = context.prompt end
    if type(row.request.skill_action) == "table" then
        request.skill_action = {}
        for _, field in ipairs(response_identity) do
            request.skill_action[field[1]] = row.request.skill_action[field[1]]
        end
        for _, field in ipairs({"activation_quota_available", "source_quota_available"}) do
            request.skill_action[field] = row.request.skill_action[field]
        end
    end
    local value = AILegacyRequest.new(request, self.room)
    if not value or not value:isValid() then
        ai_unsupported("cardsView action context is invalid", row.skill_name)
    end
    return value
end

local function same_costs(left, right)
    if not AIValue.isList(left) or not AIValue.isList(right) or #left ~= #right then return false end
    for i, id in ipairs(left) do if id ~= right[i] then return false end end
    return true
end

local function policy_scalar(value, method, label)
    if type(value[method]) ~= "function" then
        ai_unsupported("response ticket metadata is unknown: " .. label, "conversion_policy")
    end
    return policy_known(value[method](value), label)
end

-- A receipt is registered only after the narrow native resolver returned it.
-- expected is the six-field native source identity, not caller-authored metadata.
function SmartAIView:registerResolvedConversion(result, expected)
    covered_value(result)
    local key = type(expected) == "table" and expected.activation_skill or "conversion"
    if type(result) ~= "table" or type(result.ticket) ~= "table" then
        if type(result) == "table" and result.native_rejected == true then
            rejected_response(result.error or "native conversion selection was rejected", result.key or key)
        end
        ai_unsupported(type(result) == "table" and result.error
            or "native conversion policy proposal was rejected",
            type(result) == "table" and result.key or key)
    end
    local ticket = result.ticket
    if type(ticket.conversion_id) ~= "number" or ticket.conversion_id % 1 ~= 0
        or type(ticket.name) ~= "string" then
        ai_unsupported("native conversion receipt lacks identity", key)
    end
    if expected then
        for _, field in ipairs(response_identity) do
            if expected[field[1]] == nil or ticket[field[1]] ~= expected[field[1]] then
                ai_unsupported("native conversion receipt has a different source identity", key)
            end
        end
    end
    local indexes = self._indexes
    if type(indexes) ~= "table" or type(indexes.conversions) ~= "table"
        or type(indexes.conversions_by_id) ~= "table" or type(indexes.conversions_by_name) ~= "table" then
        ai_unsupported("conversion ticket index is unavailable", key)
    end
    if indexes.conversions_by_id[ticket.conversion_id] then
        ai_unsupported("native conversion receipt reused a ticket ID", key)
    end
    local card = ConversionView.new(ticket)
    if not card then ai_unsupported("native conversion receipt is malformed", key) end
    indexes.conversions[#indexes.conversions + 1] = ticket
    indexes.conversions_by_id[ticket.conversion_id] = ticket
    indexes.conversions_by_name[ticket.name] = indexes.conversions_by_name[ticket.name] or {}
    table.insert(indexes.conversions_by_name[ticket.name], ticket)
    if result.legacy_policy==nil then return self:observeOlClanPolicyAllocation(card) end
    return card
end

-- SecondJincaiwang stores the selected material natively, but its current V2
-- product has no subcards until payment. Keep source policy and authority apart.
local function second_material_policy(self, authority, row, spec)
    local classes={jink="Jink",nullification="Nullification",slash="Slash"}
    if type(row)~="table" or spec.skill~="secondjincaiwang" or not classes[spec.name]
        or not AIValue.isList(spec.subcards) or #spec.subcards~=1
        or row.name~=spec.name or row.class_name~=classes[spec.name]
        or row.skill_name~="secondjincaiwang" or row.suit~=spec.suit or row.number~=spec.number
        or row.virtual_card~=true or row.evaluation_only~=true
        or row.evaluation_owner~=self.player:objectName()
        or not same_costs(row.subcards,spec.subcards)
        or type(row.legacy_string_key)~="string" or type(row.legacy_sort_key)~="string"
        or type(row.evaluation_rules)~="table" or type(row.locked)~="boolean" or type(row.using)~="boolean"
        or authority:objectName()~=spec.name or authority:getClassName()~=classes[spec.name]
        or authority:getSkillName(false)~="secondjincaiwang" or authority:getSuit()~=spec.suit
        or authority:getNumber()~=spec.number or not same_costs(authority:getSubcards(),{}) then
        ai_unsupported("SecondJincaiwang source material policy differs from its native zero-cost product","secondjincaiwang")
    end
    local policy={}
    for _,key in ipairs({"name","class_name","type_id","kind_of","name_length","legacy_string_key","legacy_sort_key",
        "subcards","suit","number","damage_card","can_recast","handling_method","effective_id","will_throw",
        "red","black","skill_name","skill_names"}) do policy[key]=row[key] end
    local result=self:legacyPolicyCard(authority,policy,CardView.new(row))
    -- These are source-clone rules, not the native product's payment metadata.
    for _,key in ipairs({"locked","using","target_fixed"}) do result._view[key]=row[key] end
    return result
end

function SmartAIView:resolveResponseConversion(proposal, row)
    if AIUnsupported.is(proposal) then error(proposal, 0) end
    if proposal == nil or proposal == false then return nil end
    if type(proposal) == "table" and getmetatable(proposal) == nil and proposal.legacy_class ~= nil then
        -- A legacy skill-card response was built by a native resolver; the authority
        -- accepts only its own conversion tickets for a response.
        ai_unsupported("legacy skill-card response is not projected", tostring(proposal.skill or row.skill_name))
    end
    local spec, proposed_identity
    if AIValue.isConversion(proposal) then
        proposed_identity = {}
        for _, field in ipairs(response_identity) do
            proposed_identity[field[1]] = policy_scalar(proposal, field[2], field[1])
        end
        spec = {conversion_id = policy_scalar(proposal, "getConversionId", "conversion ID"),
            name = policy_scalar(proposal, "objectName", "card name"),
            suit = policy_scalar(proposal, "getSuit", "card suit"),
            number = policy_scalar(proposal, "getNumber", "card number"),
            skill = policy_scalar(proposal, "getActivationSkillName", "activation skill"),
            subcards = covered_value(proposal:getSubcards())}
    elseif type(proposal) == "table" and getmetatable(proposal) == nil then spec = proposal
    else ai_unsupported("response policy must return a ticket or pure card specification", row.skill_name) end
    local fields = {conversion_id = true, name = true, suit = true, number = true,
        skill = true, subcards = true, user_string = true}
    for field in pairs(spec) do
        if not fields[field] then
            ai_unsupported("response policy specification has an unrepresented field", tostring(field))
        end
    end
    if type(spec.name) ~= "string" or type(spec.suit) ~= "number"
        or type(spec.number) ~= "number" or not AIValue.isList(spec.subcards) then
        ai_unsupported("response policy did not specify exact card identity and costs", row.skill_name)
    end
    local identity = type(row.request) == "table" and row.request.skill_action or row.identity
    if type(identity) ~= "table" or not AIValue.isList(row.conversion_ids) then
        ai_unsupported("response policy source/ticket scope is incomplete", row.skill_name)
    end
    if proposed_identity then
        for _, field in ipairs(response_identity) do
            if proposed_identity[field[1]] ~= policy_known(identity[field[1]], field[1]) then
                ai_unsupported("response policy ticket belongs to another source instance", row.skill_name)
            end
        end
    end
    local owned, seen = {}, {}
    for _, card in ipairs(policy_known(self:addHandPile("he"), "owned payment cards")) do owned[card:getEffectiveId()] = true end
    for _, id in ipairs(spec.subcards) do
        if not owned[id] and row.authority_validated_costs == true
            and self.room and type(self.room.isCardKnown) == "function"
            and self.room:isCardKnown(id) then owned[id] = true end
        if not owned[id] and self.room and type(self.room.getCardOwner) == "function" then
            local owner = self.room:getCardOwner(id)
            if owner and owner:objectName() == self.player:objectName() then owned[id] = true end
        end
        if type(id) ~= "number" or id < 0 or id % 1 ~= 0 or seen[id] or not owned[id] then
            ai_unsupported("response policy selected duplicate or unprojected payments", row.skill_name)
        end
        seen[id] = true
    end
    for _, id in ipairs(row.conversion_ids) do
        if spec.conversion_id == nil or spec.conversion_id == id then
            local ticket = covered_value(self:getConversion(id))
            if not ticket then ai_unsupported("response policy references a missing ticket", row.skill_name) end
            local matches = true
            for _, field in ipairs(response_identity) do
                local expected = policy_known(identity[field[1]], field[1])
                local getter = ticket[field[2]]
                if type(getter) ~= "function" or covered_value(getter(ticket)) ~= expected then matches = false end
            end
            -- insertCardsViewResult overwrites the produced skill name when
            -- an action context exists. Its source/instance still comes only
            -- from that context and the matching authority ticket.
            if type(row.request) ~= "table" and spec.skill ~= nil
                and spec.skill ~= identity.activation_skill
                and spec.skill ~= identity.source_skill
                and (type(ticket.getSkillName) ~= "function" or spec.skill ~= ticket:getSkillName(false)) then matches = false end
            if matches and policy_scalar(ticket, "objectName", "card name") == spec.name
                and policy_scalar(ticket, "getSuit", "card suit") == spec.suit
                and policy_scalar(ticket, "getNumber", "card number") == spec.number then
                if spec.user_string ~= nil then
                    local declared = policy_scalar(ticket, "getUserString", "card declaration")
                    if spec.user_string ~= declared then
                        ai_unsupported("response declaration differs from authority ticket", row.skill_name)
                    end
                end
                local count
                if type(ticket.getCostCount) == "function" then count = covered_value(ticket:getCostCount()) end
                if type(count) ~= "number" or count < 0 or count % 1 ~= 0 then
                    ai_unsupported("response ticket cost protocol is unknown", row.skill_name)
                end
                if count >= 2 then
                    local bound = covered_value(ticket:withSubcards(spec.subcards))
                    if bound then return bound end
                elseif (count == 0 or #spec.subcards == count)
                    and same_costs(ticket:getSubcards(), spec.subcards) then
                    return ticket
                end
            end
        end
    end
    ai_unsupported("response policy proposal has no exact authorized source/cost ticket", row.skill_name)
end

-- Ordinary cardsView constructs a policy card before rule admission. Spear's
-- donor intentionally does not filter the material's `using` flag: an unused
-- hypothesis must not abort a later strategy. Keep this audited provider's
-- descriptor separate from receipts until its caller selects it.
local function copy_response_policy(value)
    if type(value) ~= "table" then return value end
    local copied = {}
    for key, child in pairs(value) do copied[key] = copy_response_policy(child) end
    return copied
end

function SmartAIView:evaluateResponseConversion(proposal, row)
    if type(proposal) ~= "table" or getmetatable(proposal) ~= nil
        or row.skill_name ~= "spear" or proposal.skill ~= "spear" or proposal.name ~= "slash"
        or proposal.number ~= 0 or (proposal.suit ~= 4 and proposal.suit ~= 5 and proposal.suit ~= 6)
        or not AIValue.isList(proposal.subcards) or #proposal.subcards ~= 2 then
        ai_unsupported("ordinary response hypothesis is outside the audited Spear contract", "spear")
    end
    local allowed = {name=true, skill=true, suit=true, number=true, subcards=true}
    for key in pairs(proposal) do
        if not allowed[key] then ai_unsupported("response hypothesis has an unrepresented field", tostring(key)) end
    end
    local spec = copy_response_policy(proposal)
    local evaluation_spec = copy_response_policy(spec)
    evaluation_spec.source_key = "spear"
    local card = covered_value(self:evaluateOwnerViewAsCard(evaluation_spec))
    if not AIValue.isCard(card) or card:isEvaluationOnly() ~= true
        or card:getClassName() ~= "Slash" or card:objectName() ~= spec.name
        or card:getSkillName(false) ~= spec.skill or card:getSuit() ~= spec.suit
        or card:getNumber() ~= spec.number or not same_costs(card:getSubcards(), spec.subcards) then
        ai_unsupported("ordinary response hypothesis changed its source identity", "spear")
    end
    self._response_selected_specs = self._response_selected_specs or {}
    self._response_selected_specs[card] = {spec=spec, row=copy_response_policy(row), request=self.request}
    return card
end

function SmartAIView:evaluateTongyiResponsePolicy(proposal, row)
    ai_unsupported("Tongyi readonly policy evaluation is not projected", "tongyiTQ")
end

function SmartAIView:materializeResponseSelectedCard(card)
    if not card or type(card.isEvaluationOnly) ~= "function" or card:isEvaluationOnly() ~= true then return card end
    local saved = self._response_selected_specs and self._response_selected_specs[card]
    if not saved or saved.request ~= self.request then
        ai_unsupported("selected response hypothesis has no current source mapping", "response_selection")
    end
    if saved.stamp then
        for _, key in ipairs({"viewer","decision_id","state_revision","kind","reason","pattern"}) do
            if saved.stamp[key]~=self.request[key] then
                ai_unsupported("selected response request stamp changed", "response_selection")
            end
        end
        local spec=saved.identity_spec
        if not spec or card:objectName()~=spec.name or card:getSkillName(false)~=spec.skill
            or card:getSuit()~=spec.suit or card:getNumber()~=spec.number
            or not same_costs(card:getSubcards(),spec.subcards) then
            ai_unsupported("selected response hypothesis changed its source face", "response_selection")
        end
    end
    if saved.authority then return saved.authority end
    local ok, selected = AIUnsupported.capture(function()
        local authority = covered_value(self:resolveResponseConversion(saved.spec, saved.row))
        if not AIValue.isConversion(authority) then
            ai_unsupported("selected response hypothesis has no conversion receipt", "response_selection")
        end
        return authority
    end)
    if not ok then
        selected.terminal_response_selection = true
        error(selected, 0)
    end
    saved.authority = selected
    return selected
end

-- getCardId(class,true) exposes donor toString values, not paid actions. Keep
-- an additional explicit identity for callers that select a hypothetical
-- conversion later. Neither this token nor policy_key is an authority ticket.
local function same_policy_value(left, right)
    if type(left) ~= type(right) then return false end
    if type(left) ~= "table" then return left == right end
    if getmetatable(left) ~= nil or getmetatable(right) ~= nil then return false end
    for key, value in pairs(left) do
        if not same_policy_value(value, right[key]) then return false end
    end
    for key in pairs(right) do if left[key] == nil then return false end end
    return true
end

local function readonly_source(self, card)
    local entry = self._response_selected_specs and self._response_selected_specs[card]
    if entry then
        if entry.request ~= self.request then
            ai_unsupported("readonly conversion belongs to another request", "getCardId.list")
        end
        return {mode="response",spec=copy_response_policy(entry.spec),row=copy_response_policy(entry.row),
            identity_spec=entry.identity_spec and copy_response_policy(entry.identity_spec)}
    end
    entry = self._original_selected_specs and self._original_selected_specs[card]
    if entry then
        if entry.request ~= self.request then
            ai_unsupported("readonly Original conversion belongs to another request", "getCardId.list")
        end
        return {mode="original",spec=copy_response_policy(entry.spec),class_name=entry.class_name,source_key=entry.source_key}
    end
    ai_unsupported("readonly conversion has no source mapping", "getCardId.list")
end

function SmartAIView:getReadonlyConversionIdentity(card)
    if type(rawget(self, "request")) ~= "table" then
        ai_unsupported("readonly conversion has no current request", "getCardId.list")
    end
    if not AIValue.isCard(card) or card:isEvaluationOnly() ~= true then
        ai_unsupported("readonly identity requires a mapped hypothetical card", "getCardId.list")
    end
    local source = readonly_source(self, card)
    local policy_key = covered_value(card:getLegacyStringKey())
    if type(policy_key) ~= "string" or policy_key == "" then
        ai_unsupported("readonly conversion lacks its exact donor string", "getCardId.list")
    end
    local index = self._readonly_conversion_identities
    if index and index.request == self.request and (index.decision_id ~= self.request.decision_id
        or index.state_revision ~= self.request.state_revision or index.viewer ~= self.request.viewer) then
        ai_unsupported("readonly enumeration request stamps changed", "getCardId.list")
    end
    if not index or index.request ~= self.request then
        index = {request=self.request, decision_id=self.request.decision_id, state_revision=self.request.state_revision,
            viewer=self.request.viewer, by_card={}, by_token={}, by_policy={}, next_token=0}
        self._readonly_conversion_identities = index
    end
    local existing = index.by_card[card]
    if existing then
        if not same_policy_value(existing.source, source) or existing.identity.policy_key ~= policy_key then
            ai_unsupported("readonly conversion source changed after enumeration", "getCardId.list")
        end
        return copy_response_policy(existing.identity)
    end
    local spec = source.identity_spec or source.spec
    if type(spec) ~= "table" or type(spec.name) ~= "string" or type(spec.skill) ~= "string"
        or type(spec.suit) ~= "number" or type(spec.number) ~= "number" or not AIValue.isList(spec.subcards) then
        ai_unsupported("readonly conversion source descriptor is incomplete", "getCardId.list")
    end
    local request = self.request
    local function stamp(value) return type(value)=="string" or type(value)=="number" end
    local source_key = source.mode=="response" and source.row.skill_name or source.source_key
    if not stamp(request.decision_id) or not stamp(request.state_revision) or type(request.viewer)~="string"
        or type(source_key)~="string" or source_key=="" then
        ai_unsupported("readonly conversion request or source identity is incomplete", "getCardId.list")
    end
    index.next_token = index.next_token + 1
    -- Use only this viewer's existing request stamps and a request-local index;
    -- a VM-global counter would disclose other viewers' enumeration activity.
    local identity = {kind="readonly_conversion_identity", selection_key=table.concat({"readonly-policy",request.viewer,
        tostring(request.decision_id),tostring(request.state_revision),tostring(index.next_token)},":"),
        policy_key=policy_key, source_key=source_key,
        name=spec.name,skill=spec.skill,suit=spec.suit,number=spec.number,subcards=copy_response_policy(spec.subcards)}
    local saved = {card=card,source=source,identity=identity}
    index.by_card[card], index.by_token[identity.selection_key] = saved, saved
    local values = index.by_policy[policy_key] or {}
    values[#values+1] = saved
    index.by_policy[policy_key] = values
    return copy_response_policy(identity)
end

function SmartAIView:materializeReadonlyConversionIdentity(identity)
    if type(rawget(self, "request")) ~= "table" then
        ai_unsupported("readonly selection has no current request", "response_selection")
    end
    local index = self._readonly_conversion_identities
    if not index or index.request ~= self.request or index.decision_id ~= self.request.decision_id
        or index.state_revision ~= self.request.state_revision or index.viewer ~= self.request.viewer then
        ai_unsupported("readonly selection has no current enumeration", "response_selection")
    end
    local saved
    if type(identity) == "string" then
        local values = index.by_policy[identity]
        saved = values and values[1]
        for _, value in ipairs(values or {}) do
            if not same_policy_value(saved.source, value.source) then
                ai_unsupported("donor string identifies multiple conversion sources", "response_selection")
            end
        end
    elseif type(identity) == "table" and getmetatable(identity) == nil then
        saved = index.by_token[identity.selection_key]
        if saved and not same_policy_value(saved.identity, identity) then saved = nil end
    end
    if not saved then ai_unsupported("readonly selection was not enumerated exactly", "response_selection") end
    if not same_policy_value(saved.source, readonly_source(self, saved.card)) then
        ai_unsupported("readonly selected source changed after enumeration", "response_selection")
    end
    local materializer = saved.source.mode=="response" and self.materializeResponseSelectedCard or self.materializeOriginalSelectedCard
    if type(materializer) ~= "function" then ai_unsupported("readonly selected source binder is unavailable", "response_selection") end
    local authority = covered_value(materializer(self, saved.card))
    if not AIValue.isConversion(authority) then ai_unsupported("readonly selection produced no authority receipt", "response_selection") end
    return authority
end

-- Collectors preserve source values and parse timing. In particular Guhuo
-- finishes every callback before getCard parses its first result. Weak array
-- keys also distinguish identical strings returned by different skill sources.
local response_collections = setmetatable({}, {__mode="k"})
local function response_stamp(request)
    if type(request) ~= "table" then return nil end
    return {viewer=request.viewer,decision_id=request.decision_id,state_revision=request.state_revision,
        kind=request.kind,reason=request.reason,pattern=request.pattern}
end
local function stamp_matches(stamp, request)
    if not stamp or type(request) ~= "table" then return false end
    for _, key in ipairs({"viewer","decision_id","state_revision","kind","reason","pattern"}) do
        if stamp[key] ~= request[key] then return false end
    end
    return true
end
local function source_spec(value)
    return type(value)=="table" and getmetatable(value)==nil and type(value.skill)=="string"
        and (type(value.name)=="string" or type(value.legacy_class)=="string")
        and type(value.subcards)=="table"
end
local function remember_response_value(self, output, value, row, registry, hook_key, attach, parsed)
    output[#output+1]=value
    local collection=response_collections[output]
    if not collection then
        collection={owner=self,request=self.request,stamp=response_stamp(self.request),entries={}}
        response_collections[output]=collection
    end
    collection.entries[#output]={value=value,value_spec=source_spec(value) and copy_response_policy(value) or nil,
        row=copy_response_policy(row),registry=registry,
        hook_key=hook_key,attach=attach,parsed=parsed}
end

local cardsview_invocations=setmetatable({}, {__mode="k"})
local cardsview_source_objects=setmetatable({}, {__mode="k"})
function SmartAIView:createCardsViewSourceCard(skill, class_name, costs)
    local call=cardsview_invocations[self]
    if not call or call.request~=self.request or not stamp_matches(call.stamp,self.request)
        or skill~="sxzhitu" or call.hook~="sxzhitu" or call.registry~="ai_cardsview"
        or call.row.class_name~=class_name or not call.attach or not AIValue.isList(costs) then
        ai_unsupported("Card-object constructor is outside its exact source callback",skill)
    end
    return self:evaluateCollectedResponsePolicy({source_object_create=copy_response_policy(costs)},
        call.row,call.registry,call.hook,true)
end

-- The authority's fixed-cost ticket of this skill for the same product and material.
local function offered_ticket(self, skill, spec)
    for _, row in ipairs(self.request.card_conversions or {}) do
        if row.activation_skill == skill and row.cost_count == 0
            and (row.name == spec.name or row.class_name == spec.name)
            and same_costs(row.subcards, spec.subcards) then
            return self:getConversion(row.conversion_id)
        end
    end
end

-- A policy callback names an owned card by ID, or a view-as product by its
-- legacy string name:skill[suit:number]=ids or as a spec table. A product the
-- request issued a V2 ticket for answers with that ticket; any other product is
-- evaluated locally, and submitting it falls back to SmartAI.
function SmartAIView:evaluateCollectedResponsePolicy(proposal, row, registry, hook_key, attach)
    local skill = type(row) == "table" and row.skill_name or "response_policy"
    if type(proposal) == "number" or type(proposal) == "string" and proposal:match("^%d+$") then
        local card = self:getKnownCardById(tonumber(proposal))
        if not card then ai_unsupported("response policy card is not visible to the viewer", skill) end
        return card
    end
    local spec
    if type(proposal) == "string" then
        local name, source, suit, number, ids = proposal:match("^([%w_]+):([%w_]*)%[([%w_]+):([%w%-]*)%]=([%d%+%.]*)$")
        local suits = {spade = 0, club = 1, heart = 2, diamond = 3, no_suit_black = 4, no_suit_red = 5, no_suit = 6}
        local numbers = {A = 1, J = 11, Q = 12, K = 13, ["-"] = 0, [""] = 0}
        spec = name and {name = name, skill = source, suit = suits[suit],
            number = numbers[number] or tonumber(number), subcards = {}}
        if spec then for id in ids:gmatch("%d+") do spec.subcards[#spec.subcards + 1] = tonumber(id) end end
    elseif source_spec(proposal) and type(proposal.name) == "string" then
        spec = {name = proposal.name, skill = proposal.skill, suit = proposal.suit, number = proposal.number, subcards = {}}
        for _, id in ipairs(proposal.subcards) do spec.subcards[#spec.subcards + 1] = id end
    end
    if not spec or type(spec.suit) ~= "number" or type(spec.number) ~= "number" then
        ai_unsupported("readonly response policy evaluation is not projected", skill)
    end
    local ticket = offered_ticket(self, skill, spec)
    if ticket then return ticket end
    local face = self:evaluateOwnerViewAsCard(spec)
    return self:registerViewAsReceipt(face._view)
end

local function parse_collected_response(self, value, index, values, cardsview)
    covered_value(value)
    local collection=response_collections[values]
    local record=collection and collection.entries[index]
    if not record or collection.owner~=self or collection.request~=self.request
        or not stamp_matches(collection.stamp,self.request) or record.value~=value
        or (record.value_spec and not same_policy_value(record.value_spec,copy_response_policy(value))) then
        ai_unsupported("response parser value has no current collector provenance","response_policy")
    end
    if record.parsed then return value end
    if cardsview and (AIValue.isCard(value) or AIValue.isConversion(value)) then
        -- insertCardsViewResult's no-request userdata branch returns the same
        -- object, rather than reparsing a string and losing its original flags.
        return value
    end
    if not source_spec(value) and type(value)~="string" and type(value)~="number" then
        error("Card_Parse: string argument expected, got "..type(value),0)
    end
    if type(value)=="number" then value=tostring(value) end
    return self:evaluateCollectedResponsePolicy(value,record.row,record.registry,record.hook_key,record.attach)
end
function SmartAIView:parseGuhuoPolicyResult(value,index,values)
    return parse_collected_response(self,value,index,values,false)
end
function SmartAIView:parseCardsViewPolicyResult(value,index,values)
    return parse_collected_response(self,value,index,values,true)
end

local function append_policy_result(self, result, row, output, registry, hook_key, attach)
    covered_value(result)
    if result==nil or result==false then return end
    local cardsview=registry~="ai_guhuo_card"
    local function append(value)
        covered_value(value)
        local cardValue=AIValue.isCard(value) or AIValue.isConversion(value)
        local represented=source_spec(value)
        if cardsview and type(value)~="string" and not cardValue and not represented then return end
        if cardsview and attach then
            local card=self:evaluateCollectedResponsePolicy(value,row,registry,hook_key,true)
            if card then remember_response_value(self,output,card,row,registry,hook_key,true,true) end
        else remember_response_value(self,output,value,row,registry,hook_key,false,false) end
    end
    -- Source uses ipairs on any table; holes stop enumeration, dictionary keys
    -- are ignored. Pure specifications/brand objects represent source strings/
    -- userdata and are the only explicit migration exception to that shape.
    if type(result)=="table" and not source_spec(result)
        and not AIValue.isCard(result) and not AIValue.isConversion(result) then
        for _, value in ipairs(result) do append(value) end
    else append(result) end
end

local function direct_policy_row(row)
    if type(row.request) ~= "table" then return row end
    local direct = {}
    for key, value in pairs(row) do direct[key] = value end
    direct.request = false
    if row.lazy == true then
        if type(row.direct_scope_id) ~= "number" then
            ai_unsupported("direct response policy source scope is unknown", row.skill_name)
        end
        direct.scope_id = row.direct_scope_id
    end
    return direct
end

-- Original getters rank readonly view-as products before authorizing the one
-- selected result. Registry source and printed skill are separate (fan/Fan).
-- This adapter does not rank, retry another source, or manufacture a receipt.
function SmartAIView:bindOriginalSelectedConversion(spec, class_name, source_key, readonly)
    local key = type(source_key) == "string" and source_key or "Original.getCard"
    if type(spec) ~= "table" or getmetatable(spec) ~= nil
        or type(class_name) ~= "string" or class_name == ""
        or type(source_key) ~= "string" or source_key == ""
        or type(spec.name) ~= "string" or type(spec.skill) ~= "string"
        or type(spec.suit) ~= "number" or type(spec.number) ~= "number"
        or not AIValue.isList(spec.subcards) then
        ai_unsupported("Original selected conversion lacks its exact source/product", key)
    end
    local allowed = {name=true, skill=true, suit=true, number=true, subcards=true, source_key=true}
    for field in pairs(spec) do
        if not allowed[field] then ai_unsupported("Original selected conversion has an unexpected field", tostring(field)) end
    end
    if spec.source_key ~= nil and spec.source_key ~= source_key then
        ai_unsupported("Original selected conversion source key changed", key)
    end
    local exact = {name=spec.name, skill=spec.skill, suit=spec.suit, number=spec.number, subcards={}}
    local seen = {}
    for _, id in ipairs(spec.subcards) do
        if type(id) ~= "number" or id < 0 or id % 1 ~= 0 or seen[id] then
            ai_unsupported("Original selected conversion has invalid or duplicate costs", key)
        end
        seen[id], exact.subcards[#exact.subcards + 1] = true, id
    end
    local adapter = (source_key == "fan" and exact.skill == "Fan" and exact.name == "fire_slash" and #exact.subcards == 1)
        or (source_key == "spear" and exact.skill == "Spear" and exact.name == "slash" and #exact.subcards == 2)
    adapter = adapter and readonly ~= nil
    local policy_identity
    if adapter then
        local view = type(readonly) == "table" and readonly._view
        if not view or type(readonly.isEvaluationOnly) ~= "function" or not readonly:isEvaluationOnly()
            or view.evaluation_owner ~= self.player:objectName() or readonly:objectName() ~= exact.name
            or readonly:getClassName() ~= class_name or readonly:getSkillName(false) ~= exact.skill
            or readonly:getSuit() ~= exact.suit or readonly:getNumber() ~= exact.number
            or not same_costs(readonly:getSubcards(), exact.subcards)
            or type(view.legacy_string_key) ~= "string" or type(view.legacy_sort_key) ~= "string" then
            ai_unsupported("Original equipment policy adapter lacks the exact readonly identity", key)
        end
        policy_identity = {skill_name=exact.skill, skill_names={exact.skill},
            legacy_string_key=view.legacy_string_key, legacy_sort_key=view.legacy_sort_key}
    end
    local authority_skill = adapter and source_key or exact.skill
    local function finish(card)
        if not card or card:getSkillName(false) ~= authority_skill or card:objectName() ~= exact.name
            or card:getSuit() ~= exact.suit or card:getNumber() ~= exact.number
            or not same_costs(card:getSubcards(), exact.subcards) then
            ai_unsupported("Original selected conversion receipt changed its exact product", key)
        end
        if adapter then return self:legacyPolicyCard(card, policy_identity, readonly) end
        return card
    end
    local policy = self:getConversionPolicy(class_name)
    local selected
    for _, row in ipairs(policy.skills) do
        if row.skill_name == source_key then
            if selected then ai_unsupported("Original selected conversion source is ambiguous", key) end
            selected = {}
            for field, value in pairs(row) do selected[field] = value end
        end
    end
    if not selected then ai_unsupported("Original selected conversion has no native source scope", key) end
    local play = self.request.kind == "activate" and self.request.reason == 0x01
    if play then
        selected.scope_id, selected.identity = selected.play_scope_id, selected.play_identity
        selected.request = false
        selected.lazy = true
    elseif type(selected.request) == "table" and selected.direct_scope_id == nil then
        -- V2 canActivate may issue an action scope even though the inherited
        -- isEnabledAtResponse is false. It is usable here only in this exact
        -- caller context; final printed-skill equality remains mandatory.
        if selected.request.reason ~= self.request.reason or selected.request.pattern ~= self.request.pattern then
            ai_unsupported("Original selected conversion action belongs to another context", key)
        end
        selected.identity = selected.request.skill_action
        selected.request = false
    else
        selected = direct_policy_row(selected)
    end
    local identity = selected.identity
    if type(identity) ~= "table" or identity.activation_owner ~= self.player:objectName() then
        ai_unsupported("Original selected conversion source belongs to another viewer", key)
    end
    for _, field in ipairs(response_identity) do
        policy_known(identity[field[1]], field[1])
    end
    if selected.lazy == true and (type(selected.scope_id) ~= "number"
        or selected.scope_id % 1 ~= 0 or selected.scope_id < 0) then
        ai_unsupported("Original selected conversion has no authorized context scope", key)
    end
    -- Reuse only an exact receipt from this same producer context. A response
    -- receipt cannot authorize Play merely because its printed product matches.
    for _, ticket in ipairs(policy_known(self:getConversions(), "issued conversion inventory")) do
        local view = ticket._view
        local matches = type(view) == "table" and view.producer_reason == self.request.reason
            and view.producer_pattern == self.request.pattern and view.policy_class == class_name
            and ticket:objectName() == exact.name and ticket:getSuit() == exact.suit
            and ticket:getNumber() == exact.number and ticket:getSkillName(false) == authority_skill
            and same_costs(ticket:getSubcards(), exact.subcards)
        for _, field in ipairs(response_identity) do
            if matches and policy_scalar(ticket, field[2], field[1]) ~= identity[field[1]] then matches = false end
        end
        if matches then return finish(ticket) end
    end
    local authority_spec = {}
    for field, value in pairs(exact) do authority_spec[field] = value end
    authority_spec.skill = authority_skill
    return finish(self:resolveResponseConversion(authority_spec, selected))
end

-- Legacy asks isEnabledAtResponse(player, patterns(class)) before it runs a V1
-- response callback; the projection covers the basic patterns only. An unknown
-- answer is settled by running the callback: one that proposes nothing for this
-- class has the same outcome whether or not the skill was enabled.
local function proposes_nothing(value)
    if value == nil or value == false then return true end
    return type(value) == "table" and not source_spec(value) and not AIValue.isCard(value)
        and not AIValue.isConversion(value) and value[1] == nil
end

-- Whether a view-as proposal is of class_name: true/false, or nil when unknown.
local function proposal_of_class(self, proposal, class_name)
    if AIValue.isCard(proposal) or AIValue.isConversion(proposal) then return proposal:isKindOf(class_name) end
    local id = tonumber(proposal)
    if id then
        local card = self:getKnownCardById(id)
        if not card then return nil end
        return card:isKindOf(class_name)
    end
    local name = type(proposal) == "string" and proposal:match("^([%w_]+):")
        or type(proposal) == "table" and proposal.name
    local row = type(name) == "string" and AICardCatalog.get(name)
    if type(row) ~= "table" or not AIValue.isList(row.kind_of) then return nil end
    for _, kind in ipairs(row.kind_of) do if kind == class_name then return true end end
    return false
end

-- run reports whether the callbacks proposed anything relevant.
local function settle_unknown_enablement(run)
    local ok, proposed = pcall(run)
    if not ok and AIUnsupported.is(proposed) then error(proposed, 0) end
    if not ok or proposed then policy_known(nil, "response enablement") end
end

function SmartAIView:getGuhuoCard(class_name)
    local policy, result = self:getConversionPolicy(class_name), {}
    for _, row in ipairs(policy.skills) do
        local enabled = row.enabled_at_response
        if policy_has_callback(row, "ai_guhuo_card")
            and policy_known(row.view_as_exists, "view-as existence") and enabled ~= false then
            local callback, hook_key = policy_callback(row, "ai_guhuo_card")
            local function propose()
                return callback(self, policy_known(policy.card_name, "class pattern"), class_name)
            end
            if enabled == true then
                append_policy_result(self, propose(), direct_policy_row(row), result, "ai_guhuo_card", hook_key, false)
            else
                settle_unknown_enablement(function() return not proposes_nothing(covered_value(propose())) end)
            end
        end
    end
    return result
end

function SmartAIView:cardsView(class_name, context)
    local policy, result = self:getConversionPolicy(class_name, context), {}
    for _, row in ipairs(policy.skills) do
        if policy_known(row.view_as_exists, "view-as existence") then
            local request = policy_request(self, row, context)
            local enabled = row.enabled_at_response
            -- Without append, run only reports whether a callback proposed anything.
            local function run(append)
                local proposed = false
                for _, registry in ipairs({"ai_cardsview_valuable", "ai_cardsview"}) do
                    local callback, hook_key = policy_callback(row, registry, request)
                    if callback then
                        local previous=cardsview_invocations[self]
                        cardsview_invocations[self]={row=row,registry=registry,hook=hook_key,attach=request~=nil,
                            request=self.request,stamp=response_stamp(self.request)}
                        local ok,value=pcall(callback,self,class_name,self.player,request)
                        cardsview_invocations[self]=previous
                        if not ok then error(value,0) end
                        if append then append_policy_result(self,value,row,result,registry,hook_key,request~=nil)
                        else proposed = proposed or not proposes_nothing(covered_value(value)) end
                    end
                end
                return proposed
            end
            if request or enabled == true then run(true)
            elseif enabled == nil then settle_unknown_enablement(function() return run(false) end) end
        end
    end
    return result
end

local function policy_proposal_matches(self, proposal, class_name)
    if AIValue.isConversion(proposal) then
        return policy_known(proposal:isKindOf(class_name), "converted card class")
    end
    if type(proposal) ~= "table" or type(proposal.name) ~= "string" then return nil end
    local policy = self.request.conversion_policy
    local catalog = type(policy) == "table" and policy.card_catalog
    if type(catalog) ~= "table" then return nil end
    local card = catalog[proposal.name]
    if card == nil then return nil end
    local kinds = type(card) == "table" and card.kind_of_names
    if not AIValue.isList(kinds) then
        ai_unsupported("response proposal catalogue classification is unknown", proposal.name)
    end
    for _, kind in ipairs(kinds) do if kind == class_name then return true end end
    return false
end

local function visit_skill_view_as(self, class_name, card, player, place, consume)
    player = player or self.player
    if player:objectName() ~= self.player:objectName() then
        ai_unsupported("response policy is scoped to the request viewer", "getSkillViewCard")
    end
    local policy = self:getConversionPolicy(class_name)
    for _, row in ipairs(policy.skills) do
        local enabled = row.enabled_at_response
        if policy_has_callback(row, "ai_view_as")
            and policy_known(row.view_as_exists, "view-as existence") and enabled ~= false then
            local callback, hook_key = policy_callback(row, "ai_view_as")
            local function propose()
                local actual_place = place
                if not actual_place then actual_place = self.room:getCardPlace(card:getId()) end
                actual_place = policy_known(actual_place, "card place")
                if actual_place == sgs.Player_PlaceSpecial then
                    local pile = policy_known(player:getHandPile(), "hand pile")
                    if pile:contains(card:getId()) and (self.request.reason == 0x12 or self.request.reason == 0x02) then
                        actual_place = policy_known(sgs.Player_PlaceHand, "hand place enum")
                    end
                end
                local proposal = covered_value(callback(card, player, actual_place, class_name))
                -- Unlike cardsView/getGuhuoCard, this donor skips only nil before
                -- Card_Parse. SWIG rejects either boolean as an ordinary argument
                -- error; false must not silently become a known absent conversion.
                if type(proposal) == "boolean" then
                    error("getSkillViewCard: Card_Parse rejects a boolean callback result", 0)
                end
                return proposal
            end
            if enabled == true then
                local proposal = propose()
                if proposal ~= nil then
                    local value = consume(proposal, row, hook_key)
                    if value ~= nil and value ~= false then return value end
                end
            else
                -- The donor keeps only products of this class.
                settle_unknown_enablement(function()
                    local proposal = propose()
                    return proposal ~= nil and proposal_of_class(self, proposal, class_name) ~= false
                end)
            end
        end
    end
end

function SmartAIView:getSkillViewCard(class_name, card, player, place)
    return visit_skill_view_as(self, class_name, card, player, place, function(proposal,row,hook_key)
        if not source_spec(proposal) and type(proposal)~="string" and type(proposal)~="number" then
            error("Card_Parse: string argument expected, got "..type(proposal),0)
        end
        if type(proposal)=="number" then proposal=tostring(proposal) end
        local converted=self:evaluateCollectedResponsePolicy(proposal,direct_policy_row(row),"ai_view_as",hook_key,false)
        if converted and policy_known(converted:isKindOf(class_name), "converted card class") then return converted end
    end)
end

-- AG/Guanxing isCard asks what a disclosed card would be for this player, before they
-- acquire it. The donor only parses the callback product and checks its class;
-- it does not pay the offered card or require a legal view-as action here.
-- This deliberately returns only true/nil, never a Card or receipt.
function SmartAIView:classifyOfferedSkillViewCard(class_name, card, player, place)
    local key = "isCard.acquisition"
    local options = self.request.options
    if (self.request.kind ~= "amazing_grace" and self.request.kind ~= "guanxing") or type(class_name) ~= "string"
        or class_name == "" or not AIValue.isCard(card) or not player
        or player:objectName() ~= self.player:objectName()
        or type(options) ~= "table" or not AIValue.isList(options.card_ids) then
        ai_unsupported("readonly view-as classification requires this viewer's AG/Guanxing question", key)
    end
    local id, in_domain = card:getEffectiveId(), false
    for _, offered_id in ipairs(options.card_ids) do if offered_id == id then in_domain = true end end
    local offered = in_domain and self:getChoiceCard(id) or nil
    if not offered then ai_unsupported("readonly view-as material is not an offered public card", key) end
    if covered_value(card:isVirtualCard()) ~= false or covered_value(offered:isVirtualCard()) ~= false then
        ai_unsupported("readonly acquisition requires an offered physical face", key)
    end
    for _, method in ipairs({"getId", "objectName", "getClassName", "getSuit", "getNumber"}) do
        if type(card[method]) ~= "function" or type(offered[method]) ~= "function"
            or card[method](card) == nil or card[method](card) ~= offered[method](offered) then
            ai_unsupported("readonly view-as material differs from the offered public face", key)
        end
    end
    -- Use the canonical disclosed descriptor, including its known flags. Do
    -- not let a caller replace unknown public flags with a manufactured value.
    return visit_skill_view_as(self, class_name, offered, player, place, function(proposal,row)
        if AIUnsupported.is(proposal) then error(proposal, 0) end
        if not AIValue.isConversion(proposal) then
            if type(proposal) ~= "table" or getmetatable(proposal) ~= nil then
                ai_unsupported("readonly view-as callback returned an unsupported product shape", row.skill_name)
            end
            local fields={name=true,skill=true,suit=true,number=true,subcards=true,conversion_id=true,user_string=true}
            for field in pairs(proposal) do
                if not fields[field] then ai_unsupported("readonly view-as product has an unknown field", tostring(field)) end
            end
            if type(proposal.name) ~= "string" or type(proposal.suit) ~= "number"
                or type(proposal.number) ~= "number" or not AIValue.isList(proposal.subcards) then
                ai_unsupported("readonly view-as product is not an exact supported card specification", row.skill_name)
            end
        end
        local matches = policy_proposal_matches(self, proposal, class_name)
        if type(matches) ~= "boolean" then
            ai_unsupported("readonly view-as product classification is absent from the public catalog", class_name)
        end
        return matches and true or nil
    end)
end

-- SmartAI asks getCard(class, true) for an ordered class, then tries each card
-- until aiUseCard proposes a use. Do not rank successful plans globally, or use
-- payment keep values as a second priority: neither is a legacy response rule.
local function generic_response_use(self, request)
    if request.handling_method ~= sgs.Card_MethodUse then return nil end
    if type(request.pattern) == "string" and string.sub(request.pattern, 1, 1) == "@" then return nil end

    local unknown
    local function mark_unknown(reason, key)
        unknown = unknown or (AIUnsupported.is(reason) and reason or AIUnsupported.new(reason, key))
    end
    local function finish(answer)
        -- A known result cannot repair a preceding gap in candidate discovery,
        -- source ordering or policy evaluation. Preserve typed failure at the
        -- decision boundary instead of logging it beside a handled answer.
        if unknown then error(unknown, 0) end
        return answer
    end
    if covered_value(self:hasEnumeratedConversions()) ~= true then
        mark_unknown("response conversion enumeration is incomplete", "getCard")
    end
    if type(request.conversion_policy) == "table" and request.conversion_policy.complete ~= true then
        mark_unknown("response conversion policy inventory is incomplete", "getCard")
    end
    local conversions = covered_value(self:getConversions())
    if conversions == nil then
        mark_unknown("response conversions are unknown", "getCard")
    elseif #conversions > 0 and (type(request.conversion_policy) ~= "table"
        or request.conversion_policy.complete ~= true) then
        mark_unknown("response conversion source order and cost policy are incomplete", "getCard")
    end
    -- Legacy skill-request dispatch stops after explicit handlers. It does not
    -- fall through to an unrelated physical card or an arbitrary matching ticket.
    if type(request.skill_action) == "table" then return finish(nil) end

    local candidates = covered_value(self:getCardCandidates())
    if candidates == nil then
        ai_unsupported("response physical candidates are unknown", "getCard")
    end
    local offered = {}
    for _, candidate in ipairs(candidates) do offered[candidate:getCardId()] = candidate end
    local owned = covered_value(self:addHandPile("he"))
    if not owned then ai_unsupported("response owned card order is unknown", "getCard") end
    local classes, seen, owned_ids = {}, {}, {}
    for _, card in ipairs(owned) do
        local id = card:getEffectiveId()
        owned_ids[id] = true
        -- The authority's row proves this physical card matches the pattern.
        -- Preserve he + hand-pile discovery order, even for unavailable rows.
        if offered[id] then
            local class = card:isKindOf("Slash") and "Slash" or card:getClassName()
            if not seen[class] then classes[#classes + 1], seen[class] = class, true end
        end
    end
    local physical_order
    if type(request.conversion_policy) == "table" then
        physical_order = request.conversion_policy.physical_class_order
    end
    if physical_order ~= nil then
        if not AIValue.isList(physical_order) then
            ai_unsupported("response physical class order is malformed", "getCard")
        end
        if request.conversion_policy.physical_class_order_complete ~= true then
            mark_unknown("response physical class order is incomplete", "getCard")
        end
        classes, seen = {}, {}
        for _, class in ipairs(physical_order) do
            if type(class) ~= "string" then ai_unsupported("response physical class is malformed", "getCard") end
            if not seen[class] then classes[#classes + 1], seen[class] = class, true end
        end
    end
    for id in pairs(offered) do
        if not owned_ids[id] then
            mark_unknown("response candidate is absent from visible owned cards", "getCard")
        end
    end
    local policy = request.conversion_policy
    if type(policy) == "table" and policy.class_order_complete == true
        and AIValue.isList(policy.class_order) then
        -- Only an explicitly complete projection proves the donor's actual
        -- patterns(true) discovery order. A reconstructed public catalogue is
        -- not that proof, and must not cause additional sorts or RNG draws.
        for _, entry in ipairs(policy.class_order) do
            local class = type(entry) == "table" and entry.class_name or entry
            if type(class) ~= "string" then ai_unsupported("response class order is invalid", "getCard") end
            if not seen[class] then classes[#classes + 1], seen[class] = class, true end
        end
    elseif conversions == nil or #conversions > 0 or covered_value(self:hasEnumeratedConversions()) ~= true
        or (type(policy) == "table" and policy.complete ~= true) then
        mark_unknown("response conversion class discovery order is unknown", "getCard")
    end
    for _, class in ipairs(classes) do
        local ok, cards = AIUnsupported.capture(function()
            local ordered = covered_value(self:getCard(class, true))
            if not ordered then ai_unsupported("response card order is unknown", "getCard") end
            return ordered
        end)
        if not ok then
            mark_unknown(cards)
        else
            -- Sort the complete class before filtering the request pattern. This
            -- preserves priority RNG draws for nonmatching cards of that class.
            for _, card in ipairs(cards) do
                local converted = AIValue.isConversion(card)
                local readonly = type(card.isEvaluationOnly) == "function" and card:isEvaluationOnly()
                local candidate
                if readonly then candidate = self:getEvaluationCandidate(card)
                elseif converted then candidate = self:getCardCandidate(card:getEffectiveId())
                else candidate = offered[card:getEffectiveId()] end
                covered_value(candidate)
                if readonly and card:getTypeId() ~= 0 and not candidate then
                    ai_unsupported("Original response evaluation has no target metadata", class)
                end
                if candidate or readonly and card:getTypeId() == 0 then
                    local planned, answer = AIUnsupported.capture(function()
                        local skill_card = card:getTypeId() == 0
                        if readonly and skill_card then
                            local proxy, proxy_candidate, exists = self:getResponsePlanningCard(card, "class")
                            covered_value(proxy); covered_value(proxy_candidate); covered_value(exists)
                            if type(exists) ~= "boolean" then ai_unsupported("readonly SkillCard class proxy presence is unknown", class) end
                            if not exists then return nil end
                            if not proxy or not proxy_candidate then ai_unsupported("readonly SkillCard class proxy is incomplete", class) end
                            local locked = proxy._view and proxy._view.locked
                            if type(locked) ~= "boolean" then ai_unsupported("readonly class proxy lock is unknown", class) end
                            if locked then return nil end
                            local planning = card._view.response_class_planning
                            local matches = planning.source_pattern_match
                            if type(matches) ~= "boolean" then ai_unsupported("readonly class proxy pattern match is unknown", class) end
                            if not matches then return nil end
                            -- Donor matches and plans the class dummy, not the
                            -- original SkillCard's own target/availability rules.
                            response_candidate_ready(proxy_candidate, class, false, true, true)
                            return response_plan(self, proxy, proxy_candidate, request, card)
                        end
                        if readonly then
                            local matches = card._view and card._view.matches_response_pattern
                            if type(matches) ~= "boolean" then ai_unsupported("Original readonly response pattern match is unknown", class) end
                            if not matches then return nil end
                        end
                        if converted then
                            local matches
                            if type(candidate.matchesResponsePattern) == "function" then
                                matches = covered_value(candidate:matchesResponsePattern())
                            end
                            if type(matches) ~= "boolean" then
                                ai_unsupported("conversion request-pattern match is unknown", class)
                            end
                            if not matches then return nil end
                        end
                        if not response_candidate_ready(candidate, class, converted, true) then return nil end
                        if card:isKindOf("SkillCard") == true
                            or (type(card.getTypeId) == "function" and card:getTypeId() == 0) then
                            if type(self.getResponsePlanningCard) ~= "function" then
                                ai_unsupported("SkillCard response-use requires an authority-issued planning proxy for " .. class,
                                    "forResponseUse")
                            end
                            local proxy, proxy_candidate = self:getResponsePlanningCard(card)
                            covered_value(proxy); covered_value(proxy_candidate)
                            if not proxy or not proxy_candidate then
                                ai_unsupported("SkillCard response-use planning proxy is unknown", "forResponseUse")
                            end
                            local locked = proxy._view and proxy._view.locked
                            if type(locked) ~= "boolean" then ai_unsupported("response planning lock is unknown", "forResponseUse") end
                            if locked then return nil end
                            if not response_candidate_ready(proxy_candidate, class, false, true) then return nil end
                            return response_plan(self, proxy, proxy_candidate, request, card)
                        end
                        return response_plan(self, card, candidate, request, card)
                    end)
                    if not planned then
                        if answer.terminal_response_selection then error(answer, 0) end
                        mark_unknown(answer)
                    elseif answer then return finish(answer) end
                end
            end
        end
    end
    -- No physical class succeeded. Additional classes from patterns(true) only
    -- matter through conversions; an incomplete list cannot prove a decline.
    if unknown then return finish(nil) end
    return {kind = "pass"}
end

-- ResponseUse calls the same card-family and revise pipeline as legacy
-- aiUseCard. The original request context is retained; a family that has not
-- implemented ResponseUse must report unsupported instead of an enemy/HP/count
-- approximation. The outer request remains responsible for choosing a use.
shared_response = function(self, card, candidate, request, mode)
    local use = AIUsePlan.new()
    use.isDummy = true
    local plan, status
    if type(card.isEvaluationOnly) == "function" and card:isEvaluationOnly() == true then
        -- The native planning descriptor has its own target contract. Keep the
        -- evaluation object out of serialization; response_plan submits only the
        -- original authority conversion after checking these targets.
        local previous = self._evaluation_scope
        self._evaluation_scope = {card = card, candidate = candidate}
        local ok
        ok, plan = pcall(self.evaluateCard, self, card, use)
        self._evaluation_scope = previous
        if not ok then error(plan, 0) end
        covered_value(plan)
        status = plan and plan.card and "planned" or "declined"
    else
        plan, status = self:tryUseCard(card, use, false, true)
    end
    covered_value(plan)
    if status == "unsupported" then error(plan, 0) end
    if status == "declined" then return nil end
    if (status ~= "planned" and status ~= "proposed") or not plan or not plan.card then
        ai_unsupported("response planning returned an unknown status", card:getClassName())
    end
    local recast_method = (mode == "class" or mode == "physical")
        and policy_known(sgs.Card_MethodRecast, "recast method enum") or sgs.Card_MethodResponse
    if #plan.to == 0 and request.handling_method ~= recast_method then
        local recast
        if type(card.canRecast) == "function" then recast = covered_value(card:canRecast()) end
        if type(recast) ~= "boolean" then
            ai_unsupported("response recast capability is unknown", card:getClassName())
        end
        if recast then return mode == "physical" and {kind="pass"} or nil end
    end
    return plan
end
for _, name in ipairs({"Slash", "Peach", "Jink", "ExNihilo", "EquipCard", "Duel",
    "Snatch", "Dismantlement", "Indulgence", "SupplyShortage", "AmazingGrace",
    "GodSalvation", "SavageAssault", "ArcheryAttack"}) do
    register_response_use_handler(name, shared_response)
end

-- This decline belongs between the raw-pattern and prompt handlers. An explicit
-- effect uses the same canDamageHp predicate as SmartAI, with no extra HP rule.
local function decline_damage_effect(self, request, pattern, compulsory)
    if compulsory or string.sub(pattern, 1, 1) == "@" then return false end
    local context = self:getDecisionContext()
    local effect = context.effect
    if effect == nil then
        if context.effect_present == false then return false end
        ai_unsupported("legacy cardEffect presence is not projected", "cardEffect")
    end
    if not effect.card or not effect.from or not effect.to
        or effect.to:objectName() ~= self.player:objectName() then return false end
    local name = effect.card:objectName()
    if type(name) ~= "string" or type(request.prompt) ~= "string"
        or not string.find(request.prompt, name) then return false end
    local damage
    if type(effect.card.isDamageCard) == "function" then damage = effect.card:isDamageCard() end
    if type(damage) ~= "boolean" then ai_unsupported("response damage classification is unknown", "cardEffect") end
    if not damage then return false end
    -- canDamageHp raises when an input is unknown; its nil is SmartAI's "no".
    return covered_value(self:canDamageHp(effect.from, effect.card)) == true
end

-- standard_cards-ai.lua:904 reads the last *original* CardEffect data, not
-- SmartAI's separately cloned sgs.cardEffect used by the decline above.
ai_skill_use["slash-jink"] = function(self, prompt, request)
    local effect = self:getLastCardEffect()
    if type(effect) ~= "table" then
        ai_unsupported("last original CardEffect is unavailable", "slash-jink")
    end
    local callback = self.selectSlashJink
    if type(callback) ~= "function" then
        ai_unsupported("slash-jink cardask policy is unavailable", "slash-jink")
    end
    local adapted, options = {}, {}
    for key, value in pairs(request) do adapted[key] = value end
    for key, value in pairs(request.options or {}) do options[key] = value end
    local immediate = {}
    for key, value in pairs(options.context or {}) do immediate[key] = value end
    immediate.effect, immediate.effect_present = effect, true
    options.context = immediate
    adapted.options = options
    adapted.prompt = "slash-jink:" .. (type(effect.from) == "string" and effect.from or "")
    local prior = self.request
    self.request = adapted -- getDecisionContext consumes this request-local DTO.
    local ok, answer = pcall(function()
        local selected = covered_value(callback(self, options, adapted))
        if AIValue.isCard(selected) and selected:isEvaluationOnly() then
            local materializer
            if self._response_selected_specs and self._response_selected_specs[selected] then
                materializer = self.materializeResponseSelectedCard
            elseif self._original_selected_specs and self._original_selected_specs[selected] then
                materializer = self.materializeOriginalSelectedCard
            end
            if type(materializer) ~= "function" then
                ai_unsupported("slash-jink selected hypothesis has no source mapping", "slash-jink")
            end
            -- The selection and its mapping belong to the adapted inquiry.
            -- Restore the outer request after binding (also on failure).
            selected = covered_value(materializer(self, selected))
            if not AIValue.isConversion(selected) then
                ai_unsupported("slash-jink selected hypothesis has no receipt", "slash-jink")
            end
        end
        return selected
    end)
    self.request = prior
    if not ok then error(answer, 0) end
    if AIUnsupported.is(answer) then error(answer, 0) end
    if answer == "." then return {kind="pass"} end
    if AIValue.isConversion(answer) then return {kind="use_card", card_spec=answer:toCardSpec()} end
    if AIValue.isCard(answer) then
        local id = answer:getEffectiveId()
        if type(id) == "number" and id >= 0 then return {kind="use_card", card_id=id} end
    end
    ai_unsupported("slash-jink cardask returned an invalid typed answer", "slash-jink")
end

-- Fixed SmartAI-generated ai_skill_use closures are real early hooks, not
-- aliases for the fallback scan. Their source reads a single class (or one
-- printed physical ID), and only a nil result proceeds to cardEffect/prompt.
local function generated_response_use(self, request, row)
    local cards
    if row.kind == "class" then
        if type(row.class_name) ~= "string" or row.class_name == "" then
            ai_unsupported("generated response class is unknown", "use_card_dispatch")
        end
        cards = covered_value(self:getCard(row.class_name, true))
        if not AIValue.isList(cards) then ai_unsupported("generated response class order is unknown", row.class_name) end
    else
        if type(row.card_id) ~= "number" or row.card_id % 1 ~= 0 or row.card_id < 0 then
            ai_unsupported("generated physical response identity is unknown", "use_card_dispatch")
        end
        local card = covered_value(self:getKnownCardById(row.card_id))
        if not card then ai_unsupported("generated physical response face is not disclosed", "use_card_dispatch") end
        local locked = covered_value(self.player:isLocked(card))
        if type(locked) ~= "boolean" then ai_unsupported("generated physical response lock is unknown", "use_card_dispatch") end
        if locked then return {kind="pass"} end
        cards = {card}
    end
    for _, original in ipairs(cards) do
        local card, candidate = original
        local card_type = covered_value(original:getTypeId())
        if type(card_type) ~= "number" then ai_unsupported("generated response card type is unknown", "use_card_dispatch") end
        if row.kind == "class" and card_type < 1 then
            local exists
            card, candidate, exists = self:getResponsePlanningCard(original, "class")
            covered_value(card); covered_value(candidate); covered_value(exists)
            if type(exists) ~= "boolean" then
                ai_unsupported("generated class response proxy presence is unknown", "use_card_dispatch")
            end
            if exists then
                if not card or not candidate then ai_unsupported("generated class response proxy is incomplete", "use_card_dispatch") end
                local locked = policy_known(card._view and card._view.locked, "generated class proxy lock")
                if type(locked) ~= "boolean" then ai_unsupported("generated class proxy lock is malformed", "use_card_dispatch") end
                if locked then card = nil end
            else card = nil end
        elseif type(original.isEvaluationOnly) == "function" and original:isEvaluationOnly() then
            candidate = covered_value(self:getEvaluationCandidate(original))
        else candidate = covered_value(self:getCardCandidate(original:getEffectiveId())) end
        if card then
            -- The source hook does not test the question pattern or native
            -- MethodUse limits before aiUseCard. Those checks belong to final
            -- admission of the first selected source result, never to a retry.
            response_candidate_ready(candidate, row.key, AIValue.isConversion(card), true, true)
            local answer = response_plan(self, card, candidate, request, original, row.kind)
            if answer then return answer end
        end
    end
end

-- Dispatch reads this VM's own registries (spec 15.2.3). Like SmartAI, a card name
-- or class pattern and a physical card id also get the generated response handler.
local function isolated_use_row(key)
    if type(key) ~= "string" or key == "" then return {known=true, key=key, present=false} end
    if pattern_handlers[key] ~= nil or legacy_pattern_handlers[key] ~= nil then
        return {known=true, key=key, present=true, kind="callback"}
    end
    local classes = AICardCatalog.patternClassNames()
    if classes then
        if classes[key] then return {known=true, key=key, present=true, kind="class", class_name=key} end
        for class_name, name in pairs(classes) do
            if name == key then return {known=true, key=key, present=true, kind="class", class_name=class_name} end
        end
    end
    local id = tonumber(key)
    if id and id >= 0 and id % 1 == 0 and tostring(id) == key then
        return {known=true, key=key, present=true, kind="physical", card_id=id}
    end
    return {known=true, key=key, present=false}
end

local function isolated_use_dispatch(self, request)
    local variant = self.world.enable_hegemony == true and "original" or "ordinary"
    local metadata = {known=true, entry_variant=variant,
        request_present=type(request.skill_action) == "table"}
    if metadata.request_present then
        local legacy = AILegacyRequest.new(request, self.room)
        metadata.request_valid = legacy ~= nil and legacy:isValid() == true
    end
    metadata.raw = isolated_use_row(request.pattern)
    metadata.prompt = isolated_use_row(type(request.prompt) == "string"
        and string.match(request.prompt, "^[^:]*") or "")
    return metadata
end

ai_register_handler("use_card", function(self, request)
    local metadata = isolated_use_dispatch(self, request)
    local original = metadata.entry_variant == "original"
    local raw_pattern = type(request.pattern) == "string" and request.pattern or ""
    local compulsory = not original and string.sub(raw_pattern, -1) == "!"
    local pattern = compulsory and string.sub(raw_pattern, 1, -2) or raw_pattern
    local prompt_key = type(request.prompt) == "string" and string.match(request.prompt, "^[^:]*") or ""
    if not original then
        if type(metadata.request_present) ~= "boolean" then
            ai_unsupported("legacy use request presence is unknown", "use_card_dispatch")
        end
        if metadata.request_present then
            if type(metadata.request_valid) ~= "boolean" then
                ai_unsupported("legacy use request validity is unknown", "use_card_dispatch")
            end
            if not metadata.request_valid then return nil end
            if type(request.skill_action) ~= "table" then
                ai_unsupported("legacy use request identity is not projected", "use_card_dispatch")
            end
        elseif type(request.skill_action) == "table" then
            ai_unsupported("legacy use request presence disagrees with its identity", "use_card_dispatch")
        end
    end
    local function dispatch(row, expected_key)
        if type(row) ~= "table" or row.known ~= true or row.key ~= expected_key
            or type(row.present) ~= "boolean" then
            ai_unsupported("use-card hook presence or key is unknown", expected_key)
        end
        if not row.present then return nil, false end
        if row.kind == "nonfunction" then
            if not original then return nil, false end
            if type(row.truthy) ~= "boolean" then ai_unsupported("Original nonfunction hook truthiness is unknown", expected_key) end
            if not row.truthy then return nil, false end
            error("Original askForUseCard attempted to call a nonfunction hook: " .. expected_key, 0)
        end
        local answer, status
        if row.kind == "class" or row.kind == "physical" then
            answer, status = normalize_handler_result(generated_response_use(self, request, row), request.kind)
        elseif row.kind == "callback" then
            if not pattern_handlers[expected_key] and not legacy_pattern_handlers[expected_key] then
                ai_unsupported("effective use-card callback has no isolated policy", expected_key)
            end
            if original then
                -- The Original override passes only self/prompt/method and
                -- never supplies the ordinary pattern or legacy request args.
                local callback = legacy_pattern_handlers[expected_key]
                if callback then
                    local value = covered_value(callback(self, request.prompt, request.handling_method))
                    answer, status = normalize_handler_result(value or ".", request.kind)
                else answer, status = call_handler(self, request, expected_key, pattern_handlers, legacy_pattern_handlers, pattern) end
            else answer, status = call_handler(self, request, expected_key, pattern_handlers, legacy_pattern_handlers, pattern) end
        else ai_unsupported("effective use-card hook kind is unknown", expected_key) end
        if original then return answer or {kind="pass"}, true end
        local handled = status ~= "unhandled" and not (compulsory and (status == "declined" or status == "pass"))
        return answer, handled
    end
    local answer, handled = dispatch(metadata.raw, raw_pattern)
    if handled then return answer end
    if original then return {kind="pass"} end
    if decline_damage_effect(self, request, pattern, compulsory) then return {kind="pass"} end
    answer, handled = dispatch(metadata.prompt, prompt_key)
    if handled then return answer end
    if metadata.request_present then return nil end
    if string.sub(pattern, 1, 1) == "@" or request.handling_method ~= sgs.Card_MethodUse then
        return {kind="pass"}
    end
    return generic_response_use(self, request)
end)
