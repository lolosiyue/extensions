-- ExtraTurnUtils.lua
-- Utility functions for managing extra turns in a standardized way
-- This reduces code duplication across extensions

-- Queue structure to manage multiple players needing extra turns
ExtraTurnQueue = ExtraTurnQueue or {}

-- Add a player to the extra turn queue with priority (times they should gain extra turns)
-- @param room: The game room
-- @param player: The player who should gain extra turn(s)
-- @param times: Number of extra turns to grant (default: 1)
-- @param tag: Optional unique tag identifier for this extra turn grant
function QueueExtraTurn(room, player, times, tag)
    if not player or not player:isAlive() then
        return
    end
    
    times = times or 1
    local queue_key = "ExtraTurnQueue"
    local queue = room:getTag(queue_key):toString()
    
    -- Format: playerName:times|playerName:times|...
    for i = 1, times do
        if queue ~= "" then
            queue = queue .. "|"
        end
        queue = queue .. player:objectName()
    end
    
    room:setTag(queue_key, sgs.QVariant(queue))
    
    -- If a specific tag is provided, store it for cleanup
    if tag then
        room:setTag(tag, sgs.QVariant(player:objectName()))
    end
end

-- Process the extra turn queue and grant turns in action order
-- @param room: The game room
-- @return: true if any turns were granted, false otherwise
function ProcessExtraTurnQueue(room)
    local queue_key = "ExtraTurnQueue"
    local queue_str = room:getTag(queue_key):toString()
    
    if queue_str == "" then
        return false
    end
    
    -- Parse the queue
    local player_names = queue_str:split("|")
    if #player_names == 0 then
        return false
    end
    
    -- Convert names to player objects
    local players = {}
    for _, name in ipairs(player_names) do
        local p = room:findPlayer(name)
        if p and p:isAlive() then
            table.insert(players, p)
        end
    end
    
    if #players == 0 then
        room:removeTag(queue_key)
        return false
    end
    
    -- Sort by action order if multiple players
    if #players > 1 then
        table.sort(players, function(a, b)
            return room:getFront(a, b) == a
        end)
    end
    
    -- Grant extra turns in order
    for _, p in ipairs(players) do
        if p:isAlive() then
            p:gainAnExtraTurn()
        end
    end
    
    -- Clear the queue
    room:removeTag(queue_key)
    return true
end

-- Create a standardized trigger skill for granting extra turns
-- @param skill_name: Name of the trigger skill (should start with #)
-- @param tag_name: The room tag to check for the target player
-- @param trigger_phase: The phase when extra turn should be granted (default: sgs.Player_NotActive)
-- @param priority: Skill priority (default: 1)
-- @param before_grant: Optional callback function(room, target) called before granting turn
-- @param after_grant: Optional callback function(room, target) called after granting turn
-- @return: The created trigger skill
function CreateExtraTurnGiveSkill(skill_name, tag_name, trigger_phase, priority, before_grant, after_grant)
    trigger_phase = trigger_phase or sgs.Player_NotActive
    priority = priority or 1
    
    return sgs.CreateTriggerSkill{
        name = skill_name,
        events = {sgs.EventPhaseStart},
        on_trigger = function(self, event, player, data)
            local room = player:getRoom()
            
            -- Check if using queue system
            if tag_name == "ExtraTurnQueue" then
                ProcessExtraTurnQueue(room)
                return false
            end
            
            -- Traditional single-player system
            if room:getTag(tag_name) then
                local target = room:getTag(tag_name):toPlayer()
                room:removeTag(tag_name)
                
                if target and target:isAlive() then
                    -- Execute before callback if provided
                    if before_grant then
                        before_grant(room, target)
                    end
                    
                    target:gainAnExtraTurn()
                    
                    -- Execute after callback if provided
                    if after_grant then
                        after_grant(room, target)
                    end
                end
            end
            
            return false
        end,
        can_trigger = function(self, target)
            return target and (target:getPhase() == trigger_phase)
        end,
        priority = priority
    }
end

-- Convenience function: Schedule a single player for extra turn using tag system
-- @param room: The game room
-- @param player: The player to grant extra turn
-- @param tag_name: Unique tag name for this skill
function ScheduleExtraTurn(room, player, tag_name)
    if player and player:isAlive() then
        room:setTag(tag_name, sgs.QVariant(player))
    end
end

-- Convenience function: Schedule multiple players for extra turns using queue system
-- @param room: The game room
-- @param players: Table of players to grant extra turns
-- @param times_per_player: Table of times for each player (optional, defaults to 1 for all)
function ScheduleMultipleExtraTurns(room, players, times_per_player)
    if not players or #players == 0 then
        return
    end
    
    times_per_player = times_per_player or {}
    
    for i, player in ipairs(players) do
        local times = times_per_player[i] or 1
        QueueExtraTurn(room, player, times)
    end
end

return {
    QueueExtraTurn = QueueExtraTurn,
    ProcessExtraTurnQueue = ProcessExtraTurnQueue,
    CreateExtraTurnGiveSkill = CreateExtraTurnGiveSkill,
    ScheduleExtraTurn = ScheduleExtraTurn,
    ScheduleMultipleExtraTurns = ScheduleMultipleExtraTurns
}
