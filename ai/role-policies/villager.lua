-- Reusable observer tactics. No mode, camp or identity names are assumed here;
-- a mode decides which target identities should use each tactic.
local tactics = {}

function tactics.compareStrength(world, target_id)
    local target
    if target_id == world.self.object_name then target = world.self end
    for _, player in ipairs(world.players) do
        if player.object_name == target_id then target = player break end
    end
    if not target then return nil end
    if target_id == world.self.object_name then return -3 end
    -- This heuristic compares public strength only; actual card use is still
    -- selected by the existing card AI after objective-to-relation dispatch.
    local target_power = (target.hp or 0) + (target.handcard_count or 0)
    local self_power = (world.self.hp or 0) + (world.self.handcard_count or 0)
    return target_power < self_power - 1 and 2 or -1
end

return tactics
