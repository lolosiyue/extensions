-- Server-owned policy for the four villager modes declared by extensions/system.lua.
-- Identity relationships belong here; shared AI consumes only the evaluated hooks.
local villager = dofile("lua/ai/role-policies/villager.lua")
local mode = {roles={lord={}, loyalist={}, rebel={}, renegade={}, villager={}}}

-- New identities can contribute to either side without changing the evaluator.
mode.strengthByRole = {
    lord={weight=1, anchor=true, camp="court"},
    loyalist={weight=1, camp="court"},
    rebel={weight=-1, camp="rebels"},
}

local function players(world)
    local result = {world.self}
    for _, player in ipairs(world.players) do result[#result + 1] = player end
    return result
end

local function role_of(player, state)
    if player.role_visible then return player.role end
    return state.inferred_roles and state.inferred_roles[player.object_name] or "unknown"
end

local function anchor(world, state)
    for _, player in ipairs(players(world)) do
        local settings = mode.strengthByRole[role_of(player, state)]
        if settings and settings.anchor then return player end
    end
end

function mode.relation(world, from_id, to_id, state)
    -- Viewer objectives can include temporary cooperation. Do not transpose
    -- those scores into another player's private intentions.
    if from_id == world.self.object_name then return nil end
    local from, to
    for _, player in ipairs(players(world)) do
        if player.object_name == from_id then from = player end
        if player.object_name == to_id then to = player end
    end
    if not from or not to then return "unknown" end
    local from_role, to_role = role_of(from, state), role_of(to, state)
    if from_role == "villager" and to_role == "villager" then return "friend" end
    local a = mode.strengthByRole[from_role]
    local b = mode.strengthByRole[to_role]
    if a and b then return a.camp == b.camp and "friend" or "enemy" end
    return "unknown"
end

-- Estimate only from viewer-visible/inferred identities; no hidden role totals
-- or native getDefense access. Labels retain the legacy gameProcess vocabulary.
function mode.gameProcess(world, state)
    local difference = 0
    for _, player in ipairs(players(world)) do
        local settings = mode.strengthByRole[role_of(player, state)]
        if player.alive and settings then
            difference = difference + (3 + (player.hp or 0)) * (settings.weight or 0)
        end
    end
    local label = "neutral"
    if difference >= 2 then
        local leader = anchor(world, state)
        label = leader and leader.alive and (leader.hp or 0) > 2 and "loyalist" or "dilemma"
    elseif difference <= -2 then label = "rebel" end
    return difference, label
end

local function process_score(scores, otherwise, after_anchor_loss)
    return function(world, target_id, state, process)
        local value = scores[process.label]
        if value ~= nil then return value end
        local leader = anchor(world, state)
        if leader and not leader.alive then return after_anchor_loss end
        return otherwise
    end
end

-- Public/inferred identities select these matchups. Unresolved identities have
-- no mapping, so the evaluator preserves an unknown relationship.
local court_targets = {
    lord=-2, loyalist=-2, rebel=5, villager=0,
    renegade=process_score({rebel=-1}, 3, 5),
}
mode.roles.lord.objectiveByRole = court_targets
mode.roles.loyalist.objectiveByRole = court_targets
mode.roles.rebel.objectiveByRole = {
    lord=5, loyalist=4, rebel=-2, villager=0,
    renegade=process_score({loyalist=-1, dilemma=-1}, 3, 3),
}
mode.roles.renegade.objectiveByRole = {
    lord=function(world)
        -- A surviving villager prevents a lone-renegade win too. Count the
        -- public live roster, without guessing the identities of other seats.
        for _, player in ipairs(world.players) do
            if player.alive and not player.lord then return -2 end
        end
        return 5
    end,
    loyalist=process_score({loyalist=5, rebel=-1, dilemma=0}, 3, 5),
    rebel=process_score({loyalist=-1, rebel=5, dilemma=5}, 3, 5),
    renegade=5, villager=3,
}
local function survival_objective(presumed_threat, unresolved)
    return function(world, target_id, state)
        return villager.survivalObjective(world, target_id, state, presumed_threat, unresolved)
    end
end
local peaceful_objective = survival_objective(0)
mode.roles.villager.objectiveByRole = {
    -- Shared victory makes other villagers allies regardless of their strength.
    villager=-2,
    renegade=survival_objective(2),
    lord=peaceful_objective, loyalist=peaceful_objective, rebel=peaceful_objective,
    unknown=survival_objective(0, true),
}

local function loyalty_evidence(factor)
    return function(world, event, values)
        values.loyalist = (values.loyalist or 0) + event.level * factor
    end
end

local function cross_camp_help(world, event, values)
    if event.level < 0 then
        values.villager = (values.villager or 0) + math.abs(event.level) * 0.3
    end
end

-- These are this mode's configurable evidence rules, not facts known by the
-- core AI. New identities add entries; no identity dispatch function is edited.
-- Every identity observes its own evidence stream through the same mode hook;
-- role-specific objective tables never require another AI's private beliefs.
mode.intentions = {
    ignoreActors = {"lord"},
    rules = {
        {target="villager", update=function(world, event, values)
            values.renegade = (values.renegade or 0) + event.level * (event.level > 0 and 0.8 or 0.5)
        end},
        {target="rebel", update=loyalty_evidence(1)},
        {target="lord", update=loyalty_evidence(-0.5)},
        {target="loyalist", update=loyalty_evidence(-0.5)},
        {actor="rebel", target="lord", update=cross_camp_help},
        {actor="rebel", target="loyalist", update=cross_camp_help},
        {actor="loyalist", target="rebel", update=cross_camp_help},
    },
    -- First matching candidate wins; the ordering is part of this mode's policy.
    infer = {
        {role="villager", test=function(world, event, values) return (values.villager or 0) > 20 end},
        {role="renegade", test=function(world, event, values)
            return (values.renegade or 0) > 10 and (values.loyalist or 0) > -15
        end},
        {role="rebel", test=function(world, event, values) return (values.loyalist or 0) < -10 end},
        {role="loyalist", test=function(world, event, values) return (values.loyalist or 0) > 5 end},
    },
}

-- Keep the other identities' inference unchanged. Only this observer adds
-- personal danger/aid evidence, including actions by the publicly known lord.
local survival_intentions = {rules={}, infer=mode.intentions.infer}
for _, rule in ipairs(mode.intentions.rules) do
    survival_intentions.rules[#survival_intentions.rules + 1] = rule
end
survival_intentions.rules[#survival_intentions.rules + 1] = {
    target="villager", update=villager.observeSelfIntention,
}
mode.roles.villager.intentions = survival_intentions

-- package_ai is loaded for each Room after system.lua has registered the role.
-- This installs AI policies only; playable modes and victory stay in system.lua.
for _, id in ipairs({"06pv", "08pv", "09pv", "10pv"}) do
    sgs.registerModeAI(id, mode)
end

return mode
