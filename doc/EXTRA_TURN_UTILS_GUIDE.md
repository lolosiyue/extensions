# Extra Turn Utilities - Usage Guide

## Overview
`ExtraTurnUtils.lua` provides standardized functions to handle extra turn mechanics, eliminating code duplication across extensions.

## Problem Solved
Previously, each skill that grants extra turns required duplicate boilerplate code:
- Creating a trigger skill
- Checking room tags
- Removing tags
- Validating player alive status
- Handling edge cases

Now this is centralized in reusable utility functions.

## Setup

Add this line at the top of your extension file:
```lua
require "ExtraTurnUtils"
```

## Usage Examples

### Example 1: Simple Single Player Extra Turn (Traditional Pattern)

**Before (Duplicated Code):**
```lua
s2_houqiGive = sgs.CreateTriggerSkill{
    name = "#s2_houqi-give",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("s2_houqi") then
            local target = room:getTag("s2_houqi"):toPlayer()
            room:removeTag("s2_houqi")
            if target and target:isAlive() then
                target:gainAnExtraTurn()
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and (target:getPhase() == sgs.Player_NotActive)
    end,
    priority = 1
}
```

**After (Using Utility):**
```lua
s2_houqiGive = CreateExtraTurnGiveSkill(
    "#s2_houqi-give",      -- skill name
    "s2_houqi",            -- tag name
    sgs.Player_NotActive,  -- trigger phase
    1                      -- priority
)
```

### Example 2: Extra Turn with Additional Effects

**Before:**
```lua
s4_s_xianneng_buff = sgs.CreateTriggerSkill{
    name = "#s4_s_xianneng_buff",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if room:getTag("s4_s_xiannengTarget") then
            local target = room:getTag("s4_s_xiannengTarget"):toPlayer()
            room:removeTag("s4_s_xiannengTarget")
            if target and target:isAlive() then
                room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 1)
                target:gainAnExtraTurn()
                room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 0)
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target and (target:getPhase() == sgs.Player_NotActive)
    end,
    priority = 1
}
```

**After:**
```lua
s4_s_xianneng_buff = CreateExtraTurnGiveSkill(
    "#s4_s_xianneng_buff",
    "s4_s_xiannengTarget",
    sgs.Player_NotActive,
    1,
    -- before_grant callback
    function(room, target)
        room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 1)
    end,
    -- after_grant callback
    function(room, target)
        room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 0)
    end
)
```

### Example 3: Multiple Players Need Extra Turns (New Feature)

**Scenario:** Multiple players should gain extra turns, sorted by action order.

**Code:**
```lua
-- In your main skill logic, schedule multiple players
s2_someSkill = sgs.CreateTriggerSkill{
    name = "s2_someSkill",
    events = {sgs.SomeEvent},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local targets = room:getOtherPlayers(player)
        
        -- Add multiple players to the queue
        local valid_targets = {}
        for _, p in sgs.qlist(targets) do
            if p:isAlive() and someCondition(p) then
                table.insert(valid_targets, p)
            end
        end
        
        -- Schedule them all (will be sorted by action order automatically)
        ScheduleMultipleExtraTurns(room, valid_targets)
        
        return false
    end
}

-- Create the give skill using the queue system
s2_someSkillGive = CreateExtraTurnGiveSkill(
    "#s2_someSkill-give",
    "ExtraTurnQueue",      -- Special tag for queue processing
    sgs.Player_NotActive,
    1
)
```

### Example 4: Player Gains Multiple Extra Turns

**Code:**
```lua
-- In your skill logic
on_trigger = function(self, event, player, data)
    local room = player:getRoom()
    local target = somePlayer
    
    -- Queue 2 extra turns for the same player
    QueueExtraTurn(room, target, 2)
    
    return false
end

-- Use the queue processor
someSkillGive = CreateExtraTurnGiveSkill(
    "#someSkill-give",
    "ExtraTurnQueue",
    sgs.Player_NotActive,
    1
)
```

### Example 5: Mixed - Different Players, Different Turn Counts

**Code:**
```lua
on_trigger = function(self, event, player, data)
    local room = player:getRoom()
    
    -- Player A gets 2 turns, Player B gets 1 turn, Player C gets 3 turns
    QueueExtraTurn(room, playerA, 2)
    QueueExtraTurn(room, playerB, 1)
    QueueExtraTurn(room, playerC, 3)
    
    -- They will be processed in action order
    -- Result: If action order is A->C->B, then:
    -- A gains turn, A gains turn, C gains turn, C gains turn, C gains turn, B gains turn
    
    return false
end
```

### Example 6: Scheduling with Simple Helper Function

**Code:**
```lua
-- Schedule a single player (traditional way)
ScheduleExtraTurn(room, target, "mySkillTarget")

-- Then use the traditional trigger
mySkillGive = CreateExtraTurnGiveSkill(
    "#mySkill-give",
    "mySkillTarget",
    sgs.Player_NotActive,
    1
)
```

## Function Reference

### `CreateExtraTurnGiveSkill(skill_name, tag_name, trigger_phase, priority, before_grant, after_grant)`
Creates a standardized trigger skill for granting extra turns.

**Parameters:**
- `skill_name` (string): Skill identifier (should start with #)
- `tag_name` (string): Room tag to check (use "ExtraTurnQueue" for multiple players)
- `trigger_phase` (Phase): When to trigger (default: `sgs.Player_NotActive`)
- `priority` (number): Skill priority (default: 1)
- `before_grant` (function, optional): Callback before granting turn `function(room, target)`
- `after_grant` (function, optional): Callback after granting turn `function(room, target)`

**Returns:** TriggerSkill object

### `QueueExtraTurn(room, player, times, tag)`
Add a player to the extra turn queue.

**Parameters:**
- `room`: Game room
- `player`: Player object
- `times` (number, optional): Number of extra turns (default: 1)
- `tag` (string, optional): Unique tag for tracking

### `ScheduleExtraTurn(room, player, tag_name)`
Schedule a single player for extra turn using traditional tag system.

**Parameters:**
- `room`: Game room
- `player`: Player object
- `tag_name`: Unique tag name

### `ScheduleMultipleExtraTurns(room, players, times_per_player)`
Schedule multiple players with automatic action order sorting.

**Parameters:**
- `room`: Game room
- `players`: Table of player objects
- `times_per_player` (table, optional): Table of turn counts per player

### `ProcessExtraTurnQueue(room)`
Process the queue and grant turns (called automatically by trigger).

**Parameters:**
- `room`: Game room

**Returns:** Boolean indicating if turns were granted

## Migration Guide

1. Add `require "ExtraTurnUtils"` to your extension file
2. Find all `*Give` trigger skills that use `gainAnExtraTurn()`
3. Replace with `CreateExtraTurnGiveSkill()` calls
4. For complex cases, use the callback parameters
5. For multiple players, switch to `QueueExtraTurn` system

## Benefits

✅ **Reduces code duplication** - 15+ lines → 3-5 lines per skill
✅ **Handles edge cases** - Automatic alive checks and tag cleanup
✅ **Supports multiple players** - New queue system with action order sorting
✅ **Flexible** - Callbacks for custom behavior before/after granting turns
✅ **Maintainable** - Single source of truth for extra turn logic
✅ **Backward compatible** - Traditional single-player pattern still works

## Notes

- The queue system automatically sorts players by action order using `room:getFront()`
- Dead players are automatically filtered out
- Tags are cleaned up automatically after processing
- The "ExtraTurnQueue" tag name is reserved for the queue system
- You can mix traditional and queue systems in the same extension
