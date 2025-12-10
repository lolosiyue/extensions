# Damage Function Refactoring Guide

## Overview
The `findPlayerToDamage` function has been updated to integrate all modern damage validation functions, making it easier to find valid damage targets without manual checking.

## What Was Updated

### Integrated Functions
The updated `findPlayerToDamage` now internally uses:
- **`damageIsEffective()`** - Checks if damage will actually happen
- **`canDamage()`** - Validates damage feasibility for enemies
- **`dontHurt()`** - Protects friends who shouldn't be damaged
- **`cantbeHurt()`** - Checks if target has immunity/protection
- **`needToLoseHp()`** - Determines if friend benefits from damage
- **`ajustDamage()`** - Calculates actual damage after all modifiers

### New Features
1. **Card object support**: Can pass a card instead of nature string for accurate calculations
2. **Better filtering**: Automatically excludes invalid targets
3. **Improved scoring**: Handles negative damage (healing), friend protection
4. **Helper function**: `findBestDamageTarget()` for common single-target use cases

## Common Refactoring Patterns

### Pattern 1: Manual Enemy Damage Check
**BEFORE:**
```lua
for _, enemy in ipairs(self.enemies) do
    if self:objectiveLevel(enemy) > 3 
       and not self:cantbeHurt(enemy) 
       and self:canDamage(enemy, self.player, nil) 
       and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
        return enemy
    end
end
```

**AFTER:**
```lua
return self:findBestDamageTarget(1, "N")
-- or for more control:
-- return self:findPlayerToDamage(1, self.player, "N")[1]
```

### Pattern 2: AOE Target Selection
**BEFORE:**
```lua
local targets = {}
for _, p in sgs.list(self.room:getOtherPlayers(self.player)) do
    if self:isEnemy(p) 
       and self:damageIsEffective(p, sgs.DamageStruct_Fire) 
       and not self:cantbeHurt(p) 
       and not self:needToLoseHp(p) then
        table.insert(targets, p)
    end
end
```

**AFTER:**
```lua
local targets = self:findPlayerToDamage(1, self.player, "F", nil, false, 5)
-- Returns already-sorted list of valid targets with value > 5
```

### Pattern 3: Thunder/Fire Damage with Card
**BEFORE:**
```lua
local target = nil
local max_value = 0
for _, enemy in ipairs(self.enemies) do
    if self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player)
       and not self:cantbeHurt(enemy) 
       and not self:cantDamageMore(self.player, enemy) then
        local value = self:ajustDamage(self.player, enemy, 1, thunderCard)
        if value > max_value then
            max_value = value
            target = enemy
        end
    end
end
```

**AFTER:**
```lua
-- Pass the card as 7th parameter for accurate damage calculation
local target = self:findPlayerToDamage(1, self.player, "T", nil, false, 0, thunderCard)[1]
-- or let it auto-detect nature from card:
local target = self:findPlayerToDamage(1, self.player, nil, nil, false, 0, thunderCard)[1]
```

### Pattern 4: Friend Beneficial Damage
**BEFORE:**
```lua
for _, friend in ipairs(self.friends) do
    if self:needToLoseHp(friend, self.player, card)
       and not self:dontHurt(friend, self.player)
       and self:damageIsEffective(friend, nil, self.player) then
        return friend
    end
end
```

**AFTER:**
```lua
local friends = sgs.QList2Table(self:getFriends(self.player))
return self:findPlayerToDamage(1, self.player, nil, friends, false, 0, card)[1]
-- The function automatically checks needToLoseHp and dontHurt for friends
```

### Pattern 5: Multi-Target with Threshold
**BEFORE:**
```lua
local valid_targets = {}
for _, p in sgs.list(targets) do
    if self:isEnemy(p) and self:damageIsEffective(p, "N", self.player) then
        local damage = self:ajustDamage(self.player, p, 1)
        if damage > 0 and not self:cantbeHurt(p) then
            table.insert(valid_targets, p)
        end
    end
end
-- Sort by some criteria...
```

**AFTER:**
```lua
-- Returns sorted by value, only targets with value > 10
local valid_targets = self:findPlayerToDamage(1, self.player, "N", targets, false, 10)
```

## Function Signatures

### Main Function
```lua
SmartAI:findPlayerToDamage(damage, player, nature, targets, include_self, base_value, card)
```
- **damage** (number, default: 1): Base damage amount
- **player** (Player): Source of damage
- **nature** (string, default: "N"): "N"/"F"/"T" for normal/fire/thunder
- **targets** (table, optional): Custom target list
- **include_self** (bool, default: false): Include self in search
- **base_value** (number, default: 0): Minimum value threshold
- **card** (Card, optional): Card object for accurate damage/nature calculation
- **Returns**: Sorted table of valid targets (best first)

**Note**: If `card` is provided but `nature` is nil, the function auto-detects nature from the card.

### Helper Function
```lua
SmartAI:findBestDamageTarget(damage, nature, min_value, card)
```
- **damage** (number, default: 1): Base damage amount
- **nature** (string, default: "N"): Damage nature
- **min_value** (number, default: 5): Minimum value threshold
- **card** (Card, optional): Card object for accurate calculation
- **Returns**: Best enemy target or nil

## Migration Checklist

When refactoring damage target selection code:
- [ ] Check if manually combining `damageIsEffective` + `canDamage` + `cantbeHurt`
- [ ] Look for loops iterating through enemies/players for damage targets
- [ ] Identify if `needToLoseHp` is checked for friends
- [ ] Check if `ajustDamage` is manually calculated and compared
- [ ] Replace with `findPlayerToDamage` or `findBestDamageTarget`
- [ ] Test to ensure behavior is preserved

## Benefits

1. **Less Code Duplication**: Eliminates repeated validation logic
2. **More Accurate**: Uses all modern damage checks automatically
3. **Better Maintained**: Updates to damage logic happen in one place
4. **Easier to Read**: Intent is clear from function name
5. **Consistent Behavior**: Same damage evaluation across all skills

## Examples in Codebase

See these files for good usage examples:
- `sfoflCard-ai.lua` (lines 2036, 4505, 8015, 8054, 9416)
- `scarletayuhuo-ai.lua` (lines 1482, 2678)
- `tenyearststandard-ai.lua` (lines 1691, 1744, 1801, 1818, 2948)
- `ol_sp-ai.lua` (line 3017)

## Questions?

If unsure whether to refactor a specific pattern, ask:
1. Am I manually checking if damage is effective?
2. Am I iterating through players to find damage targets?
3. Am I combining 3+ validation functions?

If yes to any, consider using `findPlayerToDamage`.
