-- Event callbacks consume one viewer-visible snapshot, never filterEvent or sgs.ais.
-- Card callbacks retain (self, CardView, PlayerView, targets); their calls to
-- sgs.updateIntention(s) are collected as values and committed by the host.
-- ai_event_callback[event][visibleSkill](self, eventPlayer, event) receives a
-- plain event DTO, NOT legacy QVariant data. ai_damage_intention[reason](self,
-- event) returns a numeric level or a dense delta list. These are explicit pure ABIs.
local max_deltas = 64
local active_sink
local sgs = assert(rawget(_G, "sgs"))
ai_damage_intention = ai_damage_intention or {}
sgs.ai_damage_intention = ai_damage_intention

-- Standard common evidence magnitudes from standard_cards-ai.lua and
-- maneuvering-ai.lua. These are the base policies, not the legacy global-state
-- special-skill exceptions; packages can replace any entry through the registry.
local standard_intentions = {Slash = 80, FireSlash = 80, ThunderSlash = 80,
    Duel = 66, Peach = -120, ExNihilo = -80, Indulgence = 120,
    SupplyShortage = 120, FireAttack = 80}
for name, value in pairs(standard_intentions) do
    if sgs.ai_card_intention[name] == nil then sgs.ai_card_intention[name] = value end
end

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

local function player_name(value)
    if type(value) == "string" then return value end
    if AIValue.isPlayer(value) then return value:objectName() end
    error("intention requires a player name or PlayerView", 0)
end

function sgs.updateIntention(from, to, level)
    assert(active_sink, "intention updates require an active isolated event")
    return active_sink(player_name(from), player_name(to), level)
end

function sgs.updateIntentions(from, targets, level)
    for _, target in ipairs(targets) do sgs.updateIntention(from, target, level) end
end

local function append_answer(answer, event, emit)
    if answer == nil then return end
    if type(answer) == "number" then
        emit(event.from, event.to, answer)
        return
    end
    assert(type(answer) == "table" and getmetatable(answer) == nil,
        "event callback result must be a plain delta array")
    local count = 0
    for key in pairs(answer) do
        assert(type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #answer,
            "event callback result must be a dense delta array")
        count = count + 1
        assert(count <= max_deltas, "too many event intention deltas")
    end
    assert(count == #answer, "event callback result is sparse")
    for _, delta in ipairs(answer) do
        assert(type(delta) == "table" and getmetatable(delta) == nil,
            "event intention delta must be plain")
        local fields = 0
        for key in pairs(delta) do
            assert(key == "from" or key == "to" or key == "level", "invalid intention field")
            fields = fields + 1
        end
        assert(fields == 3, "incomplete intention delta")
        emit(delta.from, delta.to, delta.level)
    end
end

local function card_callback(event)
    local card = event.details and event.details.card
    local class = event.card_class ~= "" and event.card_class or card and card.class_name
    local callback = sgs.ai_card_intention[class or ""]
    -- ActiveSkillCard dispatch uses the skill override before the class handler.
    local active = class == "ActiveSkillCard"
    for _, kind in ipairs(card and card.kind_of or {}) do
        if kind == "ActiveSkillCard" then active = true break end
    end
    if active then callback = sgs.ai_card_intention[event.card_skill or ""] or callback end
    return callback
end

local function card_intention(self, event, emit)
    if event.intention_suppressed then return end
    local callback = card_callback(event)
    if callback == nil then return end -- Unknown damage is handled at DamageInflicted.
    local from = self.room:findPlayerByObjectName(event.from, true)
    if not from then return end
    local targets = {}
    for _, name in ipairs(event.targets or {}) do
        local target = assert(self.room:findPlayerByObjectName(name, true), "unknown intention target")
        targets[#targets + 1] = target
    end
    if type(callback) == "number" then
        for _, target in ipairs(targets) do emit(event.from, target:objectName(), callback) end
    else
        assert(type(callback) == "function", "invalid card intention callback")
        local card = assert(event.details and event.details.card, "card intention needs card metadata")
        -- Legacy card callbacks emit through the bounded sink; they do not return actions.
        callback(self, assert(CardView.new(card)), from, targets)
    end
end

local function choice_intention(self, event, emit)
    local kind = event.details and event.details.choice_kind
    local reason = string.gsub(event.reason or "", "%-", "_")
    local from = self.room:findPlayerByObjectName(event.from, true)
    if not from then return end
    local targets = event.targets or {}
    if kind == "playerChosen" then
        local multiple = #targets > 1
        local registry = multiple and sgs.ai_playerschosen_intention or sgs.ai_playerchosen_intention
        local callback = registry[reason]
        if type(callback) == "number" then
            for _, to in ipairs(targets) do emit(event.from, to, callback) end
        elseif type(callback) == "function" then
            if multiple then callback(self, from, table.concat(targets, "+"))
            elseif targets[1] then
                callback(self, from, assert(self.room:findPlayerByObjectName(targets[1], true)))
            end
        elseif callback ~= nil then error("invalid player chosen intention", 0) end
    elseif kind == "Yiji" then
        -- No hidden card identities are reconstructed. This registry's isolated
        -- function ABI is (self, event), explicitly different from legacy cards.
        local callback = sgs.ai_Yiji_intention[event.reason or ""]
        if type(callback) == "number" then
            for _, to in ipairs(targets) do emit(event.from, to, callback) end
        elseif type(callback) == "function" then append_answer(callback(self, event), event, emit)
        elseif callback ~= nil then error("invalid Yiji intention", 0) end
    elseif kind == "skillInvoke" or kind == "skillChoice" then
        local registry = sgs.ai_choicemade_filter[kind]
        -- An absent registry is unhandled, not a registered boolean callback.
        local callback
        if type(registry) == "table" then callback = registry[event.reason or ""] end
        if callback ~= nil then
            assert(type(callback) == "function", "invalid choice event callback")
            -- Preserve the positional prompt-list ABI using only projected public fields.
            callback(self, from, {kind, event.reason, event.details.answer})
        end
    end
end

local function damage_intention(self, event, emit)
    if event.intention_suppressed or event.from == "" or event.to == "" then return end
    -- A registered card intention already consumed TargetSpecified; do not double count.
    if event.card_name ~= "" and card_callback(event) ~= nil then return end
    local reason = event.reason or ""
    if sgs.ai_damage_reason_suppress_intention[reason] then return end
    if reason == "" then
        if sgs.ai_damage_reason_suppress_intention[event.card_skill or ""] then return end
        for _, name in ipairs(event.details and event.details.card_skills or {}) do
            if sgs.ai_damage_reason_suppress_intention[name] then return end
        end
    end
    local callback = ai_damage_intention[reason]
    if callback ~= nil then
        local answer = callback
        if type(callback) == "function" then answer = callback(self, event) end
        append_answer(answer, event, emit)
        return
    end
    assert(finite(event.amount), "damage event needs a finite amount")
    local level = event.amount * 40
    local from = self.room:findPlayerByObjectName(event.from, true)
    if not from then return end
    -- Sort matched flags for deterministic precedence; absent flags are not inferred.
    local flags = {}
    for flag in pairs(sgs.ai_damage_from_flag_intention) do
        if from:hasFlag(flag) == true then flags[#flags + 1] = flag end
    end
    table.sort(flags)
    for _, flag in ipairs(flags) do
        local value = sgs.ai_damage_from_flag_intention[flag]
        assert(finite(value), "damage flag intention must be finite")
        if value == 0 then return end
        level = event.amount * value
    end
    if event.chain or event.transfer then level = event.amount * 20 end
    emit(event.from, event.to, level)
end

local function skill_events(self, world, event, emit)
    local callbacks = sgs.ai_event_callback[event.trigger_event]
        or sgs.ai_event_callback[event.kind]
    if callbacks == nil then return end
    assert(type(callbacks) == "table", "event callbacks must be keyed by visible skill")
    local visible = {}
    local function add(player)
        for _, skill in ipairs(player.skills or {}) do
            if not skill.invalid and type(skill.name) == "string" then visible[skill.name] = true end
        end
    end
    add(world.self)
    for _, player in ipairs(world.players or {}) do add(player) end
    local names = {}
    for name in pairs(visible) do
        if callbacks[name] ~= nil then names[#names + 1] = name end
    end
    table.sort(names)
    local actor = event.details and event.details.player or event.to
    local player = self.room:findPlayerByObjectName(actor, true)
    for _, name in ipairs(names) do
        local callback = callbacks[name]
        assert(type(callback) == "function", "invalid visible skill event callback")
        append_answer(callback(self, player, event), event, emit)
    end
end

function ai_event(world, event)
    assert(type(world) == "table" and type(event) == "table", "event needs pure snapshots")
    assert(active_sink == nil, "nested isolated events are not supported")
    local self = assert(SmartAIView.new({kind = "event", viewer = world.self.object_name,
        world_view = world, scratch = {}}), "invalid event world")
    local present = {[world.self.object_name] = true}
    for _, player in ipairs(world.players or {}) do present[player.object_name] = true end
    local deltas = {}
    local function emit(from, to, level)
        assert(type(from) == "string" and type(to) == "string" and present[from] and present[to],
            "intention players must belong to this viewer snapshot")
        assert(finite(level), "intention level must be finite")
        if from == to or level == 0 then return end
        assert(#deltas < max_deltas, "too many event intention deltas")
        deltas[#deltas + 1] = {from = from, to = to, level = level}
    end
    active_sink = emit
    local ok, failure = pcall(function()
        if event.trigger_event == sgs.TargetSpecified then card_intention(self, event, emit)
        elseif event.trigger_event == sgs.DamageInflicted then damage_intention(self, event, emit)
        elseif event.trigger_event == sgs.ChoiceMade then choice_intention(self, event, emit) end
        skill_events(self, world, event, emit)
    end)
    active_sink = nil
    if not ok then error(failure, 0) end -- Discard the entire batch, including earlier emissions.
    return deltas
end

ai_coverage.declare("event_intention", function()
    return {"TargetSpecified", "DamageInflicted", "ChoiceMade", "visible_skill_callback"}
end)
