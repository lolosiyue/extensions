-- Reusable observer tactics. No mode, camp or identity names are assumed here;
-- a mode decides which target identities should use each tactic.
local tactics = {}

local function find_player(world, id)
    if id == world.self.object_name then return world.self end
    for _, player in ipairs(world.players) do
        if player.object_name == id then return player end
    end
end

local defensive_cards = {Jink=true, Peach=true, Analeptic=true}
local function defense_reserve(world)
    -- Event/compact snapshots can omit the hand. An incomplete hand is unknown,
    -- never evidence that its owner has no defensive cards.
    if type(world.hand_cards) ~= "table" or #world.hand_cards ~= world.self.handcard_count then return nil end
    local count = 0
    for _, card in ipairs(world.hand_cards) do
        local defensive = defensive_cards[card.class_name]
        for _, name in ipairs(card.kind_of or {}) do
            if defensive_cards[name] then defensive = true end
        end
        if defensive and not card.locked then count = count + 1 end
    end
    return count
end

function tactics.observeSelfIntention(world, event, values)
    if event.to ~= world.self.object_name or event.from == event.to then return end
    -- Positive intention is hostile; aid offsets hostility. This is the
    -- observer's own evidence, not another seat's hidden identity or memory.
    values.self_hostility = math.max(-200, math.min(200,
        (values.self_hostility or 0) + event.level))
end

function tactics.survivalObjective(world, target_id, state, presumed_threat, unresolved)
    local target = find_player(world, target_id)
    if not target then return nil end
    if target_id == world.self.object_name then return -3 end
    if not target.alive then return 0 end
    local values = state.role_values and state.role_values[target_id]
    local hostility = values and values.self_hostility or 0
    if hostility < 0 then return -1 end
    if hostility == 0 and unresolved then return nil end

    local own = world.self
    local hp = own.hp + (own.hujia or 0)
    local reserve = defense_reserve(world)
    local fragile = own.hp <= 1 or hp <= 2
        or hp <= 3 and (own.handcard_count <= 1 or reserve == 0)
    local own_power = hp + math.min(own.handcard_count, 4)
    local target_power = target.hp + (target.hujia or 0) + math.min(target.handcard_count, 4)
    local outmatched = target_power > own_power + 1

    if hostility > 0 then
        -- Retaliation must reduce exposure, not become a vendetta. Low HP,
        -- inadequate reserves or a stronger opponent cap offensive interest;
        -- the existing card AI still chooses legal defense/disruption actions.
        if fragile or outmatched then
            local row = world.distances and world.distances[target_id]
            local distance = row and row[own.object_name]
            local distant = type(distance) == "number" and type(target.attack_range) == "number"
                and distance > target.attack_range
            return distant and 1 or 2
        end
        return math.min(5, 3 + hostility / 40)
    end

    -- An unprovoked bystander is never attacked merely for being weaker or
    -- belonging to the losing camp. Even a mode-supplied threat is secondary
    -- while this observer is vulnerable or outmatched.
    if fragile or outmatched then return 0 end
    return presumed_threat
end

return tactics
