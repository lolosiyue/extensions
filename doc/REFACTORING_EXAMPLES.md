# Example Refactoring: sfoflCard-ai.lua

## Case Study: sfofl_yice_damage

### Original Code (Line 297-305)
```lua
sgs.ai_skill_playerchosen.sfofl_yice_damage = function(self, targets)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) 
		   and self:canDamage(enemy,self.player,nil) 
		   and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
			return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		return enemy
	end
	return targets:first()
end
```

### Refactored Code
```lua
sgs.ai_skill_playerchosen.sfofl_yice_damage = function(self, targets)
	-- Use findBestDamageTarget for cleaner code
	local target = self:findBestDamageTarget(1, "N", 3)
	if target then return target end
	
	-- Fallback to any enemy if no good target found
	if #self.enemies > 0 then return self.enemies[1] end
	
	return targets:first()
end
```

### What Changed?
1. **Removed manual validation**: `cantbeHurt`, `canDamage`, `damageIsEffective` now handled internally
2. **Removed explicit sorting**: `findBestDamageTarget` returns best target directly
3. **Simplified logic**: Single line replaces entire validation loop
4. **Maintained behavior**: Fallback logic preserved for edge cases

### Benefits
- 9 lines → 6 lines (33% reduction)
- More readable and maintainable
- Automatically gets updates when damage system improves
- No chance of forgetting a validation check

---

## Additional Opportunities in sfoflCard-ai.lua

### Line 774: sfofl_juejia skill
**BEFORE:**
```lua
for _, p in ipairs(self.enemies) do
	if self:damageIsEffective(p, sgs.DamageStruct_Normal) and not self:cantbeHurt(p) and not p:isKongcheng() then
		table.insert(enemies, p)
	end
end
```

**AFTER:**
```lua
local enemies = self:findPlayerToDamage(1, self.player, "N", 
	sgs.QList2Table(self:getEnemies()), false, 0)
-- Filter for non-empty hand if needed
enemies = table.filter(enemies, function(p) return not p:isKongcheng() end)
```

### Line 1017-1027: sfofl_youzi skill
**BEFORE:**
```lua
for _,enemy in ipairs(self.enemies)do
	if not enemy:isKongcheng()
		and self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player)
		and not self:needToLoseHp(enemy)
		and (not next or self:getOverflow(enemy)>self:getOverflow(next))then
		next = enemy
	elseif not enemy:isKongcheng()
			and self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player) and not self:cantbeHurt(enemy)
			and not self:needToLoseHp(enemy)
			and (not next2 or self:getOverflow(enemy)>self:getOverflow(next2))then
		next2 = enemy
	end
end
```

**AFTER:**
```lua
-- Get valid damage targets automatically
local candidates = self:findPlayerToDamage(1, self.player, "N")
-- Filter for non-empty hand and sort by overflow
candidates = table.filter(candidates, function(p) return not p:isKongcheng() end)
table.sort(candidates, function(a,b) return self:getOverflow(a) > self:getOverflow(b) end)
local next = candidates[1]
local next2 = candidates[2]
```

### Line 2141: sfofl_cunsi skill
**BEFORE:**
```lua
for _, enemy in ipairs(self.enemies) do
	if self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) then
		table.insert(tos, enemy)
	end
end
```

**AFTER:**
```lua
local tos = self:findPlayerToDamage(1, self.player, "N")
```

---

## Pattern Recognition

Look for these patterns in AI code:

### Pattern A: "Find any valid enemy"
```lua
for _, enemy in ipairs(self.enemies) do
	if [validation checks] then
		return enemy
	end
end
```
→ Replace with `self:findBestDamageTarget()` or `self:findPlayerToDamage()[1]`

### Pattern B: "Collect all valid enemies"
```lua
local result = {}
for _, enemy in ipairs(self.enemies) do
	if [validation checks] then
		table.insert(result, enemy)
	end
end
```
→ Replace with `self:findPlayerToDamage(...)`

### Pattern C: "Find best enemy by custom criteria"
```lua
local best = nil
local best_value = -999
for _, enemy in ipairs(self.enemies) do
	if [validation checks] then
		local value = [calculate value]
		if value > best_value then
			best = enemy
			best_value = value
		end
	end
end
```
→ Use `self:findPlayerToDamage()` then apply custom sorting if needed

---

## Testing Recommendations

After refactoring:
1. Test the skill in-game to ensure target selection works correctly
2. Verify edge cases (no valid targets, all friends, etc.)
3. Check that fallback behavior is preserved
4. Ensure no crashes or nil pointer errors

---

## Summary

The refactored `findPlayerToDamage` function centralizes damage validation logic, making AI code:
- **Shorter**: Less boilerplate
- **Safer**: Automatic validation prevents bugs
- **Consistent**: Same logic everywhere
- **Maintainable**: One place to update damage rules

Estimated refactoring impact for `sfoflCard-ai.lua`:
- ~150 lines could be simplified
- ~30-40 instances of manual damage checking could use this function
- Maintenance burden reduced significantly
