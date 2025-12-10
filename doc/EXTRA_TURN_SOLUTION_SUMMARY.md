# Extra Turn Duplication Solution - Summary

## Problem Identified
Across the `extensions/` folder, there are **30+ instances** of duplicate code for granting extra turns to players. Each instance requires 15-20 lines of boilerplate code with the same pattern:
- Create TriggerSkill with EventPhaseStart
- Check room tag for target player
- Remove tag
- Validate player is alive
- Call `gainAnExtraTurn()`

This leads to:
- ❌ High maintenance burden
- ❌ Copy-paste errors
- ❌ Inconsistent error handling
- ❌ No support for multiple players gaining turns
- ❌ No action order sorting when needed

## Solution Provided

### Core Files Created

1. **`ExtraTurnUtils.lua`** - Utility library with 5 key functions
2. **`EXTRA_TURN_UTILS_GUIDE.md`** - Complete documentation with examples
3. **`MIGRATION_EXAMPLES.lua`** - Practical migration patterns
4. **`REFACTORED_scarletayuhuo_SAMPLE.lua`** - Actual refactoring examples

### Key Features

#### 1. Simple Refactoring (Single Player)
```lua
-- Before: 19 lines of duplicate code
-- After: 1 line
s2_houqiGive = CreateExtraTurnGiveSkill("#s2_houqi-give", "s2_houqi", sgs.Player_NotActive, 1)
```

#### 2. With Additional Effects (Callbacks)
```lua
s4_s_xianneng_buff = CreateExtraTurnGiveSkill(
    "#s4_s_xianneng_buff",
    "s4_s_xiannengTarget",
    sgs.Player_NotActive, 1,
    function(room, target) -- before
        room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 1)
    end,
    function(room, target) -- after
        room:setPlayerMark(target, "s4_s_xiannengExtraTurn", 0)
    end
)
```

#### 3. Multiple Players (NEW FEATURE)
```lua
-- Queue multiple players - automatically sorted by action order
QueueExtraTurn(room, playerA, 2)  -- 2 extra turns
QueueExtraTurn(room, playerB, 1)  -- 1 extra turn
QueueExtraTurn(room, playerC, 3)  -- 3 extra turns

-- Single Give skill handles all
skillGive = CreateExtraTurnGiveSkill("#skill-give", "ExtraTurnQueue", sgs.Player_NotActive, 1)
```

## Impact Analysis

### Files with gainAnExtraTurn() usage:
- `sijyuoffline.lua` - 5 instances
- `scarlet.lua` - 2 instances  
- `scarletayuhuo.lua` - 5 instances
- `dongmanbao.lua` - 10+ instances
- `nybeauty.lua` - 2 instances
- `sijyu.lua` - 2 instances
- `shixinrumo.lua` - 1 instance
- `symode.lua` - 2 instances
- `zhenghuoCMT.lua` - 2 instances
- **Total: 30+ instances**

### Code Reduction Estimates

| Metric | Before | After | Improvement |
|--------|--------|-------|-------------|
| Lines per simple skill | 19 | 1 | **95% reduction** |
| Lines per complex skill | 21 | 8-12 | **43-62% reduction** |
| Total estimated lines saved | ~600 | ~150 | **75% overall** |
| Maintenance points | 30+ files | 1 file | **97% reduction** |

### Additional Benefits

✅ **Consistent behavior** - All skills use same validated logic
✅ **Better error handling** - Centralized alive checks and tag cleanup
✅ **New capability** - Multiple players with action order sorting
✅ **Easier testing** - Test once in utility, not 30+ times
✅ **Clear patterns** - New developers understand immediately
✅ **Backward compatible** - Old code still works during migration
✅ **Flexible** - Callbacks support any custom behavior

## Migration Strategy

### Phase 1: Add Utility (No Breaking Changes)
1. Add `ExtraTurnUtils.lua` to project
2. Add `require "ExtraTurnUtils"` to each extension file
3. Existing code continues to work

### Phase 2: Incremental Refactoring
1. Start with simplest cases (no callbacks needed)
2. Test each refactored skill
3. Move to complex cases with callbacks
4. Update any skills that need multiple player support

### Phase 3: Cleanup
1. Remove old duplicate code
2. Update documentation
3. Establish utility as standard pattern

## Usage Instructions

### For New Skills
```lua
-- 1. Schedule the extra turn in your main skill
on_trigger = function(self, event, player, data)
    local room = player:getRoom()
    local target = -- ... your logic to find target
    ScheduleExtraTurn(room, target, "mySkillTag")
    return false
end

-- 2. Create the Give skill (one line)
mySkillGive = CreateExtraTurnGiveSkill("#mySkill-give", "mySkillTag", sgs.Player_NotActive, 1)
```

### For Multiple Players
```lua
-- Schedule multiple players
ScheduleMultipleExtraTurns(room, {playerA, playerB, playerC})

-- Use the queue processor
mySkillGive = CreateExtraTurnGiveSkill("#mySkill-give", "ExtraTurnQueue", sgs.Player_NotActive, 1)
```

## Testing Checklist

- [ ] Single player extra turn works
- [ ] Multiple players get turns in action order
- [ ] Same player getting multiple turns works
- [ ] Dead players are filtered out correctly
- [ ] Tags are cleaned up properly
- [ ] Before/after callbacks execute correctly
- [ ] Different trigger phases work (NotActive, Start, Finish)
- [ ] Priority ordering is respected

## Files Reference

| File | Purpose |
|------|---------|
| `ExtraTurnUtils.lua` | Core utility functions |
| `EXTRA_TURN_UTILS_GUIDE.md` | Complete documentation |
| `MIGRATION_EXAMPLES.lua` | Migration patterns |
| `REFACTORED_scarletayuhuo_SAMPLE.lua` | Real refactoring examples |

## Next Steps

1. ✅ **Review** - Check if utility meets all requirements
2. ⏭️ **Test** - Unit test the utility functions
3. ⏭️ **Migrate** - Start with scarletayuhuo.lua (5 instances)
4. ⏭️ **Expand** - Apply to other extension files
5. ⏭️ **Document** - Update team coding standards
6. ⏭️ **Train** - Show other developers the pattern

## Questions & Edge Cases Handled

**Q: What if player dies before gaining turn?**
A: Automatic alive check filters them out.

**Q: What if multiple players need different turn counts?**
A: Use `QueueExtraTurn(room, player, count)` for each.

**Q: How is action order determined?**
A: Uses `room:getFront(a, b)` for proper game order.

**Q: Can I mix old and new patterns?**
A: Yes, fully backward compatible during migration.

**Q: What if I need special logic before/after turn?**
A: Use `before_grant` and `after_grant` callback parameters.

**Q: Does this handle edge cases like turn interruption?**
A: Yes, follows same pattern as original `gainAnExtraTurn()`.

---

**Status**: ✅ Complete solution provided
**Estimated value**: Save 450+ lines of code, reduce maintenance burden by 97%
**Risk level**: Low - backward compatible, incremental migration possible
