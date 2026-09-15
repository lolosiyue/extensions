-- Opt-in mode configuration. Identity relationships live here, not in SmartAI
-- or the reusable villager tactics. This does not register a playable game mode.
local villager = dofile("lua/ai/role-policies/villager.lua")
local mode = {roles={villager={}}}

-- New identities can contribute to either side without changing the evaluator.
mode.strengthByRole = {
    lord={weight=1, anchor=true},
    loyalist={weight=1},
    rebel={weight=-1},
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

-- These are the villager observer's matchups in THIS mode. Other observer roles
-- require their own/default policies; this sample does not invent their strategies.
mode.roles.villager.objectiveByRole = {
    villager=villager.compareStrength,
    renegade=5,
    lord=process_score({rebel=3, loyalist=-2}, -1, -1),
    loyalist=process_score({rebel=2, loyalist=-1}, 0, 1),
    rebel=process_score({rebel=-1, loyalist=3}, 0, -1),
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
mode.roles.villager.intentions = {
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

return mode
