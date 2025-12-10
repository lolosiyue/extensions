-- REFACTORED_scarletayuhuo_SAMPLE.lua
-- This shows actual refactored sections from scarletayuhuo.lua using ExtraTurnUtils
-- Add this at the top of scarletayuhuo.lua: require "ExtraTurnUtils"

-- =============================================================================
-- REFACTORED SECTION 1: s2_houqi (Lines 4362-4380)
-- =============================================================================

-- 🔴 DELETE THE OLD CODE (19 lines) and replace with:

s2_houqiGive = CreateExtraTurnGiveSkill("#s2_houqi-give", "s2_houqi", sgs.Player_NotActive, 1)

-- =============================================================================
-- REFACTORED SECTION 2: s2_jubing (Lines 7770-7790)
-- =============================================================================

-- 🔴 DELETE THE OLD CODE (21 lines) and replace with:

s2_jubingGive = CreateExtraTurnGiveSkill("#s2_jubing-give", "s2_jubingTarget", sgs.Player_NotActive, 1)

-- =============================================================================
-- REFACTORED SECTION 3: s2_andu (Lines 8475-8495)
-- =============================================================================

-- 🔴 DELETE THE OLD CODE (21 lines) and replace with:

s2_anduGive = CreateExtraTurnGiveSkill("#s2_andu-give", "s2_andu", sgs.Player_Start, 1)

-- =============================================================================
-- HOW TO REFACTOR THE ENTIRE FILE
-- =============================================================================

--[[
1. Add at the very top of scarletayuhuo.lua (after any existing requires):
   require "ExtraTurnUtils"

2. Search for all patterns like this:
   - Skill name ending in "Give" or "give"
   - Contains "gainAnExtraTurn()"
   - Has tag checking pattern: room:getTag(...):toPlayer()

3. For each match, identify:
   a. skill_name (e.g., "#s2_houqi-give")
   b. tag_name (e.g., "s2_houqi")
   c. trigger_phase (usually sgs.Player_NotActive or sgs.Player_Start)
   d. priority (usually 1)
   e. Any additional code before/after gainAnExtraTurn()

4. Replace with:
   - If no additional code: Single line CreateExtraTurnGiveSkill call
   - If additional code: Use before_grant/after_grant callbacks

5. Test each refactored skill to ensure behavior is unchanged

ESTIMATED IMPACT for scarletayuhuo.lua:
- Found 5 instances of gainAnExtraTurn in this file
- Estimated ~100 lines of duplicate code can be reduced to ~25 lines
- 75% reduction in boilerplate code
- Easier maintenance and less error-prone
]]

-- =============================================================================
-- ADDITIONAL INSTANCES TO REFACTOR
-- =============================================================================

-- If you find these patterns in scarletayuhuo.lua, refactor them similarly:

-- Line ~9145: Direct gainAnExtraTurn() call
-- Consider if this should use the scheduling system for consistency

-- Line ~11177: Direct gainAnExtraTurn() call  
-- Consider if this should use the scheduling system for consistency

-- =============================================================================
-- VERIFICATION CHECKLIST
-- =============================================================================

--[[
After refactoring, verify:
☐ All *Give skills compile without errors
☐ Tag names match between skill logic and Give skill
☐ Trigger phases are correct (NotActive vs Start vs Finish)
☐ Priority values are preserved
☐ Any additional effects (marks, flags, etc.) are in callbacks
☐ Test in-game that extra turns are granted correctly
☐ Test with multiple players if using queue system
☐ Test edge cases (dead players, invalid targets)
]]
