-- Mode policy is owned by the loading Room VM. No Engine-global AI state or userdata
-- is exported to the isolated AI VM; evaluateModeAI returns primitive snapshot data.
if sgs.registerModeAI then return end

local policies, minds = {}, {}
local standard_modes = {}
local generation = 0
local valid_relations = {friend=true, enemy=true, neutral=true, unknown=true}
local scores = {friend=-2, enemy=5, neutral=0, unknown=0}
local hook_names = {"relation", "objective", "rolePredictable", "gameProcess", "onIntention"}
local hook_errors = {
    relation="relation_hook", objective="objective_hook",
    rolePredictable="predictable_hook", gameProcess="process_hook",
    onIntention="intention_hook",
}

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function policy_role(role, selector)
    assert(type(role) == "string" and role ~= "", "invalid policy role")
    if sgs.Sanguosha and not (selector and role == "unknown") then
        assert(sgs.Sanguosha:getRoleAbbreviation(role) ~= "", "unregistered policy role: "..role)
    end
    return role
end

-- Hooks often resolve the same IDs several times.  Keep the index ephemeral: it
-- is an evaluation detail and never becomes part of the exported world/state.
local active_indexes = setmetatable({}, {__mode="k"})
local readonly_worlds = setmetatable({}, {__mode="k"})
local function view_player(world, id)
    local index = active_indexes[world]
    if index then return index[id] end
    if world.self.object_name == id then return world.self end
    for _, player in ipairs(world.players) do
        if player.object_name == id then return player end
    end
end

local function snapshot_players(world)
    local players, index = {world.self}, {[world.self.object_name]=world.self}
    for _, player in ipairs(world.players) do
        if not index[player.object_name] then
            players[#players + 1], index[player.object_name] = player, player
        end
    end
    return players, index
end

local function known_role(player, state)
    -- Visible facts override this observer's estimates; never read a hidden role.
    if player.role_visible then return player.role end
    return state.inferred_roles and state.inferred_roles[player.object_name] or "unknown"
end

local function compile_objectives(spec, fallback)
    assert(type(spec) == "table", "objectiveByRole requires a table")
    local targets = {}
    for role, callback in pairs(spec) do
        policy_role(role, true)
        assert(type(callback) == "function" or finite(callback) and callback >= -5 and callback <= 5,
            "target objective requires a callback or a score from -5 to 5")
        targets[role] = callback
    end
    return function(world, target_id, state, process)
        local target = view_player(world, target_id)
        if not target then return nil end
        local callback = targets[known_role(target, state)]
        if type(callback) == "function" then return callback(world, target_id, state, process) end
        if callback ~= nil then return callback end
        -- Only an absent mapping falls back. An explicit callback returning nil
        -- leaves the score unspecified, just like the original objective hook.
        if fallback then return fallback(world, target_id, state, process) end
    end
end

local function compile_intentions(spec)
    assert(type(spec) == "table", "intentions requires a table")
    local ignored, rules, inference = {}, {}, {}
    for _, field in ipairs({"ignoreActors", "rules", "infer"}) do
        assert(spec[field] == nil or type(spec[field]) == "table", "invalid intentions."..field)
        local count = 0
        for key in pairs(spec[field] or {}) do
            assert(type(key) == "number" and key >= 1 and key % 1 == 0, "intentions."..field.." requires an array")
            count = count + 1
        end
        for index = 1, count do
            assert(spec[field][index] ~= nil, "sparse intentions."..field)
        end
    end
    for _, role in ipairs(spec.ignoreActors or {}) do
        ignored[policy_role(role, true)] = true
    end
    for _, rule in ipairs(spec.rules or {}) do
        assert(type(rule) == "table" and type(rule.update) == "function", "invalid intention rule")
        rules[#rules + 1] = {
            actor=rule.actor ~= nil and policy_role(rule.actor, true) or nil,
            target=rule.target ~= nil and policy_role(rule.target, true) or nil,
            update=rule.update,
        }
    end
    local seen = {}
    for _, candidate in ipairs(spec.infer or {}) do
        assert(type(candidate) == "table" and type(candidate.test) == "function", "invalid intention inference")
        local role = policy_role(candidate.role, false)
        assert(not seen[role], "duplicate intention inference role: "..role)
        seen[role] = true
        inference[#inference + 1] = {role=role, test=candidate.test}
    end

    return function(world, from_id, to_id, level, state)
        local from, to = view_player(world, from_id), view_player(world, to_id)
        if not from or not to then return end
        local actor, target = known_role(from, state), known_role(to, state)
        if ignored[actor] then return end
        local event = {from=from_id, to=to_id, actor_role=actor, target_role=target, level=level}
        local values = {}
        for key, value in pairs(state.role_values and state.role_values[from_id] or {}) do
            values[key] = value
        end
        local matched = false
        for _, rule in ipairs(rules) do
            if (rule.actor == nil or rule.actor == actor) and (rule.target == nil or rule.target == target) then
                rule.update(world, event, values, state)
                matched = true
            end
        end
        if not matched then return end
        local estimate
        if not from.role_visible then
            for _, candidate in ipairs(inference) do
                local accepted = candidate.test(world, event, values, state)
                assert(type(accepted) == "boolean", "intention inference must return boolean")
                if accepted then estimate = candidate.role break end
            end
        end
        for key, value in pairs(values) do
            assert(type(key) == "string" and finite(value), "intention evidence must contain finite numeric values")
        end
        -- Commit only after all selected rules and inference have succeeded. Callbacks
        -- may edit values; world, event and state are read-only by contract.
        state.role_values = state.role_values or {}
        state.inferred_roles = state.inferred_roles or {}
        state.role_values[from_id] = values
        state.inferred_roles[from_id] = estimate
    end
end

local function copy_hooks(spec, defaults)
    assert(type(spec) == "table", "mode/role AI requires a table")
    local copy = {}
    for _, name in ipairs(hook_names) do
        assert(spec[name] == nil or type(spec[name]) == "function", "invalid AI hook: "..name)
        copy[name] = spec[name]
    end
    if spec.intentions ~= nil then
        assert(spec.onIntention == nil, "choose intentions or onIntention at the same policy level")
        copy.onIntention = compile_intentions(spec.intentions)
    end
    if spec.objectiveByRole ~= nil then
        copy.objective = compile_objectives(spec.objectiveByRole, copy.objective or defaults and defaults.objective)
    end
    return copy
end

function sgs.registerModeAI(mode, spec)
    assert(type(mode) == "string" and mode ~= "", "mode AI requires a mode ID")
    assert(type(spec) == "table", "mode AI requires a table")
    local policy = copy_hooks(spec)
    policy.teams, policy.roles = {}, {}
    assert(spec.roles == nil or type(spec.roles) == "table", "AI roles must be a table")
    for role, hooks in pairs(spec.roles or {}) do
        assert(type(role) == "string" and role ~= "", "invalid AI role")
        if sgs.Sanguosha then
            assert(sgs.Sanguosha:getRoleAbbreviation(role) ~= "", "unregistered AI role: "..role)
        end
        policy.roles[role] = copy_hooks(hooks, policy)
    end
    assert(spec.teams == nil or type(spec.teams) == "table", "teams must be a table")
    for team, roles in pairs(spec.teams or {}) do
        assert(type(team) == "string" and team ~= "" and type(roles) == "table", "invalid team")
        for _, role in ipairs(roles) do
            assert(type(role) == "string" and role ~= "" and not policy.teams[role], "duplicate/invalid team role")
            if sgs.Sanguosha then
                assert(sgs.Sanguosha:getRoleAbbreviation(role) ~= "", "unregistered team role: "..role)
            end
            policy.teams[role] = team
        end
    end
    policies[mode] = policy
    standard_modes[mode] = nil -- An author's replacement always takes precedence.
    minds[mode] = {} -- Definition replacement invalidates this VM's old inferred state.
    generation = generation + 1
end

-- The standard strategy uses the same observer minds and hook dispatcher as
-- extension modes. Its evidence follows SmartAI's allegiance direction, without
-- native role counts, hidden player roles, random hostility or gameplay mutation.
local function standard_process(world, state)
    local strength = 0
    for _, player in ipairs(snapshot_players(world)) do
        if player.alive then
            local role = known_role(player, state)
            local value = 3 + math.max(player.hp or 0, 0)
                + math.max(player.handcard_count or 0, 0) * 0.3
            if role == "lord" or role == "loyalist" then strength = strength + value
            elseif role == "rebel" then strength = strength - value end
        end
    end
    -- This is observed strength, not a claim about unobserved team membership.
    return strength, strength >= 4 and "loyalist" or strength <= -4 and "rebel" or "neutral"
end

local function standard_objective(world, target_id, state, process)
    local target = view_player(world, target_id)
    if not target then return nil end
    local own, other = known_role(world.self, state), known_role(target, state)
    if own == "unknown" or other == "unknown" then return nil end
    if target_id == world.self.object_name then return -3 end
    local label = process and process.label or "neutral"
    if own == "lord" or own == "loyalist" then
        if other == "lord" or other == "loyalist" then return -2 end
        if other == "rebel" then return 5 end
        if other == "renegade" then return label == "rebel" and -1 or 3 end
    elseif own == "rebel" then
        if other == "rebel" then return -2 end
        if other == "lord" or other == "loyalist" then return 5 end
        if other == "renegade" then return label == "loyalist" and -1 or 3 end
    elseif own == "renegade" then
        -- Preserve the lord until the final duel; press the currently stronger
        -- observed side instead of treating renegades as a shared team.
        if type(world.alive_player_order) == "table" and #world.alive_player_order == 2 then return 5 end
        if other == "lord" then
            if (target.hp or 0) <= 2 then return -2 end
            return label == "rebel" and -1 or label == "loyalist" and 1 or 0
        end
        if other == "renegade" then return 3 end
        if other == "loyalist" then return label == "loyalist" and 5 or label == "rebel" and 1 or 3 end
        if other == "rebel" then return label == "rebel" and 5 or label == "loyalist" and 1 or 3 end
    end
    return nil
end

local function standard_relation(world, from_id, to_id, state)
    local from, to = view_player(world, from_id), view_player(world, to_id)
    if not from or not to then return nil end
    local a, b = known_role(from, state), known_role(to, state)
    local camps = {lord="court", loyalist="court", rebel="rebel"}
    if camps[a] and camps[b] then return camps[a] == camps[b] and "friend" or "enemy" end
    -- Renegade policy depends on the observing player's own objective. Do not
    -- transplant that objective to another player's relation row.
    return nil
end

local function standard_intention(world, from_id, to_id, level, state)
    local from, to = view_player(world, from_id), view_player(world, to_id)
    if not from or not to or from.role_visible or level == 0 then return end
    local target_role = known_role(to, state)
    local direction = ({lord=-1, loyalist=-1, rebel=1})[target_role]
    if not direction then return end
    state.role_values = state.role_values or {}
    state.inferred_roles = state.inferred_roles or {}
    local values = state.role_values[from_id] or {loyalist=0, renegade=0}
    local delta = math.max(-100, math.min(100, level)) * direction
    -- Contradictory camp evidence is a renegade estimate, never a secret role fact.
    if values.loyalist * delta < 0 then
        values.renegade = math.min(1000, values.renegade + math.abs(delta))
    end
    values.loyalist = math.max(-1000, math.min(1000, values.loyalist + delta))
    state.role_values[from_id] = values
    local estimate
    if values.renegade >= 50 and math.abs(values.loyalist) < values.renegade then estimate = "renegade"
    elseif values.loyalist >= 20 then estimate = "loyalist"
    elseif values.loyalist <= -20 then estimate = "rebel" end
    state.inferred_roles[from_id] = estimate
end

function sgs.registerStandardModeAI(mode, normal_identity, hegemony)
    if policies[mode] then return false end
    -- Native admission supplies the existing normal-mode classification. Kingdom
    -- and scenario victory policies need their own explicit mode registration.
    if hegemony then
        -- Role visibility is the authorization boundary.  A public careerist
        -- recruitment can be known while its kingdom field is still empty.
        local function faction(player)
            if not player.role_visible then return nil end
            local role = player.role
            if type(role) == "string" and (role == "careerist" or role:match("^careerist_")) then
                return role
            end
            local kingdom = player.kingdom
            if type(kingdom) == "string" and kingdom ~= "" and kingdom ~= "unknown" and kingdom ~= "god" then
                return kingdom
            end
        end
        sgs.registerModeAI(mode, {relation=function(world, from_id, to_id)
            if from_id == to_id then return "friend" end
            local from, to = view_player(world, from_id), view_player(world, to_id)
            if not from or not to then return "unknown" end
            local a, b = faction(from), faction(to)
            if not a or not b then return "neutral" end
            if a == "careerist" or b == "careerist" then return "enemy" end
            return a == b and "friend" or "enemy"
        end})
        return true
    end
    local fixed_teams = {
        ["02_1v1"]={first={"lord"}, second={"renegade"}},
        ["03_1v2"]={first={"lord"}, second={"rebel"}},
        ["04_1v3"]={first={"lord"}, second={"rebel"}},
        ["04_boss"]={first={"lord"}, second={"rebel"}},
        ["04_2v2"]={first={"loyalist"}, second={"rebel"}},
        ["05_ol"]={first={"lord", "loyalist"}, second={"rebel"}},
        ["06_ol"]={first={"lord", "loyalist"}, second={"rebel"}},
        ["08_defense"]={first={"loyalist"}, second={"rebel"}},
    }
    if fixed_teams[mode] then
        sgs.registerModeAI(mode, {teams=fixed_teams[mode]})
    elseif normal_identity then
        sgs.registerModeAI(mode, {relation=standard_relation,
            objective=standard_objective, gameProcess=standard_process,
            onIntention=standard_intention})
    else
        return false
    end
    standard_modes[mode] = true
    return true
end

local function mind(mode, viewer)
    minds[mode] = minds[mode] or {}
    minds[mode][viewer] = minds[mode][viewer] or {}
    return minds[mode][viewer]
end

local function invoke(policy, name, world, ...)
    if not policy then return true, nil end
    -- Dispatch by the observer's known identity, never by a hidden target identity.
    local role_policy = world.self.role_visible and policy.roles[world.self.role]
    local callback = role_policy and role_policy[name] or policy[name]
    if not callback then return true, nil end
    local ok, value, extra = pcall(callback, readonly_worlds[world] or world, ...)
    local error_class
    if not ok then error_class = hook_errors[name] end
    return ok, value, extra, error_class
end

local function clone_value(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local copy = {}
    seen[value] = copy
    for key, item in pairs(value) do copy[clone_value(key, seen)] = clone_value(item, seen) end
    return copy
end

local function valid_state(value, seen, depth, budget)
    budget = budget or {remaining=1024}
    budget.remaining = budget.remaining - 1
    if budget.remaining < 0 then return false end
    if value == nil or type(value) == "string" or type(value) == "boolean" then return true end
    if type(value) == "number" then return finite(value) end
    if type(value) ~= "table" or getmetatable(value) ~= nil then return false end
    depth = depth or 0
    if depth > 6 then return false end
    seen = seen or {}
    if seen[value] then return false end
    seen[value] = true
    for key, item in pairs(value) do
        if (type(key) ~= "string" and type(key) ~= "number")
            or not valid_state(key, seen, depth + 1, budget)
            or not valid_state(item, seen, depth + 1, budget) then return false end
    end
    seen[value] = nil
    return true
end

-- Query hooks receive a read-only primitive view and cannot mutate the
-- persistent observer mind or leak changes into another target.
local function readonly(value, seen)
    if type(value) ~= "table" then return value end
    seen = seen or {}
    if seen[value] then return seen[value] end
    local proxy = {}
    seen[value] = proxy
    setmetatable(proxy, {
        __index=function(_, key) return readonly(value[key], seen) end,
        __newindex=function() end,
        __len=function() return #value end,
        __pairs=function() return function(_, key)
            local next_key, next_value = next(value, key)
            if next_key ~= nil then return next_key, readonly(next_value, seen) end
        end, proxy, nil end,
    })
    return proxy
end

function sgs.evaluateModeAI(world, options)
    local policy = policies[world.mode_id]
    -- The boolean form is the C++ boundary.  Keep the table form as a small
    -- Lua compatibility aid for callers that already pass option records.
    local viewer_only = options == true or options and options.viewer_only == true or world.viewer_only == true
    local result = {managed=policy ~= nil or world.custom_roles == true,
        relations={}, objectives={}, predictable=false, game_process=0, process_label="neutral",
        relation_scope=viewer_only and "viewer" or "full"}
    if not result.managed then return result end
    local state = mind(world.mode_id, world.self.object_name)
    local query_state = readonly(state)
    local players, index = snapshot_players(world)
    local previous_index = active_indexes[world]
    local query_world = readonly(world)
    active_indexes[world] = index
    active_indexes[query_world] = index
    readonly_worlds[world] = query_world
    local function fail(error_class)
        if not result.error then result.error = error_class end
    end
    local predictable = world.self.role_visible == true
    for _, player in ipairs(players) do
        if player.object_name ~= world.self.object_name
            and player.alive and not player.role_visible then predictable = false end
    end
    local ok, custom, _, hook_error = invoke(policy, "rolePredictable", world, query_state)
    if hook_error then fail(hook_error) end
    result.predictable = ok and (custom == true or custom == nil and predictable) or false
    -- Evaluate the selected mode/observer process once. Objective hooks receive
    -- its validated values, so overriding gameProcess also changes target scoring.
    local accepted, process_value, label, hook_error = invoke(policy, "gameProcess", world, query_state)
    if hook_error then fail(hook_error) end
    if accepted and finite(process_value) then
        result.game_process = process_value
        if type(label) == "string" then result.process_label = label end
    end
    local objectives = {}
    for _, to in ipairs(players) do
        local process = {value=result.game_process, label=result.process_label}
        local accepted, value, _, hook_error = invoke(policy, "objective", world, to.object_name, query_state, process)
        if hook_error then fail(hook_error) end
        objectives[to.object_name] = {valid=accepted and finite(value) and value >= -5 and value <= 5,
            supplied=not accepted or value ~= nil, value=value}
    end
    local relation_sources = viewer_only and {world.self} or players
    for _, from in ipairs(relation_sources) do
        local row = {}
        result.relations[from.object_name] = row
        for _, to in ipairs(players) do
            local relation = "unknown"
            if from.object_name == to.object_name
                or from.controller and from.controller ~= "" and from.controller == to.controller then
                relation = "friend"
            else
                local accepted, value, _, hook_error = invoke(policy, "relation", world, from.object_name, to.object_name, query_state)
                if hook_error then fail(hook_error) end
                if accepted and valid_relations[value] then relation = value
                elseif accepted and value == nil then
                    -- Never derive team membership from an invisible identity.
                    local a = policy and from.role_visible and policy.teams[from.role]
                    local b = policy and to.role_visible and policy.teams[to.role]
                    if a and b then
                        relation = a == b and "friend" or "enemy"
                    elseif from.object_name == world.self.object_name then
                        -- Legacy objectiveLevel also defines friends/enemies. A score is
                        -- viewer-relative; never transpose it into another player's row.
                        local score = objectives[to.object_name]
                        if score.valid then
                            relation = score.value < 0 and "friend" or score.value > 0 and "enemy" or "neutral"
                        end
                    end
                end
            end
            row[to.object_name] = relation
        end
    end
    for _, to in ipairs(players) do
        local value = scores[result.relations[world.self.object_name][to.object_name]]
        local score = objectives[to.object_name]
        if score.supplied then value = score.valid and score.value or 0 end
        if world.self.controller and world.self.controller ~= "" and world.self.controller == to.controller then value = -2 end
        result.objectives[to.object_name] = to.object_name == world.self.object_name and -3 or value
    end
    active_indexes[world] = previous_index
    readonly_worlds[world] = nil
    active_indexes[query_world] = nil
    return result
end

-- Opaque tokens never contain state. Keep only the latest preparation and let
-- an abandoned token disappear with its caller; no failed event retains a queue.
local prepared_intentions = setmetatable({}, {__mode="k"})

-- Preparation is budgeted by the host. It never replaces an observer mind,
-- including when an instruction hook interrupts after the callbacks finish.
function sgs.prepareModeAIIntentions(world, deltas)
    local pending = setmetatable({}, {__mode="k"})
    prepared_intentions = pending
    if type(deltas) ~= "table" or getmetatable(deltas) ~= nil then return "intention_input" end
    local present = {[world.self.object_name]=true}
    for _, player in ipairs(world.players) do present[player.object_name] = true end
    local count = 0
    for key in pairs(deltas) do
        if type(key) ~= "number" or key % 1 ~= 0 or key < 1 or key > 64 then return "intention_input" end
        count = count + 1
    end
    local fields = {from=true, to=true, level=true}
    for index = 1, count do
        local delta = deltas[index]
        if type(delta) ~= "table" or getmetatable(delta) ~= nil then return "intention_input" end
        for key in pairs(delta) do
            if not fields[key] then return "intention_input" end
        end
        if type(delta.from) ~= "string" or type(delta.to) ~= "string"
            or delta.from == delta.to or not present[delta.from] or not present[delta.to]
            or not finite(delta.level) then return "intention_input" end
    end
    local mode, viewer = world.mode_id, world.self.object_name
    local policy, owned = policies[mode], minds[mode]
    local original = owned and owned[viewer]
    local prepared_generation = generation
    local query_world = readonly(world)
    local shadow = clone_value(original or {})
    -- Pass the read-only view directly. No global lookup mapping needs cleanup
    -- if a host instruction hook aborts any part of this preparation.
    for delta_index = 1, count do
        local delta = deltas[delta_index]
        local ok, _, _, callback_error = invoke(policy, "onIntention",
            query_world, delta.from, delta.to, delta.level, shadow)
        if not ok then return callback_error end
    end
    if not valid_state(shadow) then return "intention_state" end
    if prepared_intentions ~= pending or generation ~= prepared_generation then return "intention_stale" end
    local token = {}
    pending[token] = {mode=mode, viewer=viewer, owned=owned,
        original=original, generation=prepared_generation,
        -- A hook may retain its mutable shadow. Detach the validated result so
        -- subsequent changes to that reference cannot alter the prepared mind.
        shadow=clone_value(shadow), noop=count == 0 or policy == nil}
    return token
end

-- Native callers disable their instruction hook before this tiny commit. Only
-- private, current, unused tokens can replace one viewer's state; no callbacks,
-- traversals, validation loops or exported mutable state occur here.
function sgs.commitModeAIIntentions(token)
    if type(token) ~= "table" then return "intention_prepared" end
    local prepared = prepared_intentions[token]
    if not prepared then return "intention_prepared" end
    prepared_intentions[token] = nil
    if prepared.generation ~= generation or prepared.owned ~= minds[prepared.mode]
        or prepared.original ~= (prepared.owned and prepared.owned[prepared.viewer]) then
        return "intention_stale"
    end
    if not prepared.noop then
        prepared.owned[prepared.viewer] = prepared.shadow
        generation = generation + 1
    end
    return nil
end

function sgs.updateModeAIIntentions(world, deltas)
    local prepared = sgs.prepareModeAIIntentions(world, deltas)
    if type(prepared) ~= "table" then return prepared end
    return sgs.commitModeAIIntentions(prepared)
end

-- Keep the legacy single-intention ABI while sharing the atomic batch consumer.
function sgs.updateModeAIIntention(world, from, to, level)
    if type(from) ~= "string" or type(to) ~= "string" or from == to or not finite(level) then return end
    local present = {[world.self.object_name]=true}
    for _, player in ipairs(world.players) do present[player.object_name] = true end
    if not present[from] or not present[to] then return end
    return sgs.updateModeAIIntentions(world, {{from=from, to=to, level=level}})
end

-- Cache only values, keyed by authoritative Room revision and hook/mind generation.
function sgs.modeAIWorld(ai)
    local revision = ai.room:aiStateRevision()
    local cache = ai._mode_world
    if cache and cache.revision == revision and ai._mode_generation == generation then return cache end
    cache = ai.room:buildAIWorldView(ai.player)
    ai._mode_world, ai._mode_generation = cache, generation
    return cache
end

local function current_ai()
    if current_self and current_self.room == global_room then return current_self end
    for _, ai in pairs(sgs.ais or {}) do
        if ai.room == global_room then return ai end
    end
end

local managed_rooms = setmetatable({}, {__mode="k"})
function sgs.modeAIEnabled(room, viewer)
    if standard_modes[room:getMode()] then return false end
    if policies[room:getMode()] then return true end
    -- This is exactly evaluateModeAI's admission rule. Ordinary identity SmartAI
    -- must not compute geometry, card zones and skill callbacks just to return false.
    local revision = room:aiStateRevision()
    local cached = managed_rooms[room]
    if cached and cached.revision == revision then return cached.custom_roles end
    local custom_roles = false
    for _, player in sgs.qlist(room:getAllPlayers(true)) do
        if player:getRoleEnum() == sgs.Player_UnknownRole then
            custom_roles = true
            break
        end
    end
    managed_rooms[room] = {revision=revision, custom_roles=custom_roles}
    return custom_roles
end

function sgs.installModeAI(SmartAI)
    local objective, friend, enemy = SmartAI.objectiveLevel, SmartAI.isFriend, SmartAI.isEnemy
    local update, compare, adjust = SmartAI.updatePlayers, SmartAI.compareRoleEvaluation, SmartAI.adjustAIRole
    local friends, enemies = SmartAI.getFriends, SmartAI.getEnemies
    local predictable, intentions = isRolePredictable, sgs.updateIntention
    local process, evaluate, counts = sgs.gameProcess, evaluateAlivePlayersRole, updateAlivePlayerRoles

    local function policy(ai)
        if not sgs.modeAIEnabled(ai.room, ai.player) then return nil end
        local world = sgs.modeAIWorld(ai)
        return world.mode_policy.managed and world or nil
    end
    local function relation(ai, from, to)
        if not from or not to then return "unknown" end
        if ai:isDualControlLinked(from, to) then return "friend" end
        local world = sgs.modeAIWorld(ai)
        local row = world.mode_policy.relations[from:objectName()]
        return row and row[to:objectName()] or "unknown"
    end
    function SmartAI:objectiveLevel(to)
        local world = policy(self)
        if not world then return objective(self, to) end
        if not to then return 0 end
        if to == self.player then return -3 end
        if self:isDualControlLinked(self.player, to) then return -2 end
        return world.mode_policy.objectives[to:objectName()] or 0
    end
    function SmartAI:isFriend(other, another)
        if not policy(self) then return friend(self, other, another) end
        return relation(self, another or self.player, other) == "friend"
    end
    function SmartAI:isEnemy(other, another)
        if not policy(self) then return enemy(self, other, another) end
        return relation(self, another or self.player, other) == "enemy"
    end
    function SmartAI:updatePlayers(changed)
        if not policy(self) then return update(self, changed) end
        self.role = self.player:getRole()
        evaluateAlivePlayersRole()
        updateAlivePlayerRoles()
        self.friends, self.friends_noself, self.enemies = {}, {}, {}
        for _, p in sgs.qlist(self.room:getAlivePlayers()) do
            if self:isFriend(p) then
                table.insert(self.friends, p)
                if p ~= self.player then table.insert(self.friends_noself, p) end
            elseif self:isEnemy(p) then table.insert(self.enemies, p) end
        end
        self.harsh_retain = false
    end
    function SmartAI:getFriends(player, no_self)
        if not policy(self) then return friends(self, player, no_self) end
        player = player or self.player
        local result = {}
        for _, target in sgs.qlist(self.room:getAlivePlayers()) do
            if (not no_self or target ~= player) and self:isFriend(target, player) then
                result[#result + 1] = target
            end
        end
        return result
    end
    function SmartAI:getEnemies(player)
        if not policy(self) then return enemies(self, player) end
        local result = {}
        for _, target in sgs.qlist(self.room:getAlivePlayers()) do
            if self:isEnemy(target, player or self.player) then result[#result + 1] = target end
        end
        return result
    end
    function SmartAI:compareRoleEvaluation(player, first, second)
        local world = policy(self)
        if not world then return compare(self, player, first, second) end
        local role = self.room:canSeeRole(self.player, player) and player:getRole() or "neutral"
        return (role == first or role == second) and role or "neutral"
    end
    function SmartAI:adjustAIRole(...)
        if not policy(self) then return adjust(self, ...) end
        self:updatePlayers(false)
    end
    function isRolePredictable(classical)
        local ai = current_ai()
        if ai then
            local world = policy(ai)
            if world then return world.mode_policy.predictable end
        elseif global_room and policies[global_room:getMode()] and not standard_modes[global_room:getMode()] then
            return false -- Initialization must not populate hidden identities in shared legacy tables.
        end
        return predictable(classical)
    end
    function sgs.gameProcess(arg, changed)
        local ai = current_ai()
        local world = ai and policy(ai)
        if not world then return process(arg, changed) end
        if arg then return world.mode_policy.game_process or 0 end
        return world.mode_policy.process_label or "neutral"
    end
    function evaluateAlivePlayersRole()
        local ai = current_ai()
        if not ai or not policy(ai) then return evaluate() end
        -- The shared legacy compatibility table contains public identities only.
        for _, p in sgs.qlist(ai.room:getAlivePlayers()) do
            sgs.ai_role[p:objectName()] = ai.room:isRoleRevealed(p) and p:getRole() or "neutral"
        end
    end
    function updateAlivePlayerRoles()
        local ai = current_ai()
        if not ai or not policy(ai) then return counts() end
        sgs.playerRoles = {lord=0, loyalist=0, rebel=0, renegade=0}
        for _, p in sgs.qlist(ai.room:getAlivePlayers()) do
            local role = ai.room:isRoleRevealed(p) and p:getRole() or "unknown"
            sgs.playerRoles[role] = (sgs.playerRoles[role] or 0) + 1
        end
    end
    function sgs.updateIntention(from, to, level)
        local ai = current_ai()
        if not ai or not policy(ai) then return intentions(from, to, level) end
        if not from or not to or not finite(level) then return end
        if sgs.ai_doNotUpdateIntenion then level = 0 end
        sgs.ai_doNotUpdateIntenion = nil
        if from == to then return end
        -- Mixed routes keep legacy role scoring, but the independent event
        -- pipeline is the sole producer of managed mode-mind updates.
        if not sgs.modeAIUsesIsolatedEvents then
            for _, observer in pairs(sgs.ais) do
                if observer.room == ai.room then
                    local world = sgs.modeAIWorld(observer)
                    sgs.updateModeAIIntention(world, from:objectName(), to:objectName(), level)
                end
            end
        end
        for _, observer in pairs(sgs.ais) do
            if observer.room == ai.room then observer:updatePlayers(false) end
        end
    end
end
