# Smart AI Crash Debug System

## Problem Solved
The Smart AI code (circa 2008) was crashing without error messages, making debugging nearly impossible. This system adds comprehensive crash tracking, logging, and protection to identify and fix crashes.

## What's Included

### Core Files
1. **ai/ai-debug-logger.lua** - Main logging module with crash protection
2. **ai/smart-ai.lua** - Modified to integrate logger (lines 1-25, 194-275, 1833-2432)
3. **ai/PROTECTION_PATTERNS.lua** - Code examples for adding protection to more functions

### Documentation
4. **AI_DEBUG_GUIDE.md** - Complete guide (usage, troubleshooting, examples)
5. **AI_DEBUG_QUICKREF.md** - Quick reference card for daily use

### Tools
6. **analyze-ai-logs.ps1** - PowerShell script to analyze logs
7. **lua/ai/logs/** - Directory for log files (auto-created)

## Quick Start

### 1. Enable Debug Mode
Edit `ai/smart-ai.lua` (around line 12):
```lua
_G.AI_DEBUG_MODE = true  -- Enable logging
```

### 2. Run Your Game
Play until a crash occurs (or just play normally to monitor AI)

### 3. Analyze Crash
```powershell
.\analyze-ai-logs.ps1 -Action errors
```

### 4. Read Error Details
Check: `lua/ai/logs/ai-errors-[timestamp].log`

You'll see exactly:
- Which function crashed
- What the error was (nil value, bad argument, etc.)
- Complete call stack (how it got there)
- Context (player names, game state, etc.)

## Features

✅ **Automatic crash detection** - pcall wraps critical functions  
✅ **Detailed error logging** - Stack traces show exact crash location  
✅ **Performance tracking** - Identify slow functions  
✅ **Safe file operations** - Prevents I/O crashes  
✅ **Zero overhead when disabled** - Set `AI_DEBUG_MODE = false` for production  
✅ **Multiple log files** - Separate debug, error, and performance logs  
✅ **Real-time monitoring** - Watch logs as game runs  

## Log Files

All logs are in `lua/ai/logs/`:

- **ai-debug-[timestamp].log** - All function calls and checkpoints
- **ai-errors-[timestamp].log** - Crashes and errors only
- **ai-perf-[timestamp].log** - Performance statistics

## Usage Examples

### View Error Summary
```powershell
.\analyze-ai-logs.ps1 -Action errors
```

### Monitor in Real-Time
```powershell
.\analyze-ai-logs.ps1 -Action watch
```

### Check Performance
```powershell
.\analyze-ai-logs.ps1 -Action performance
```

### View Recent Activity
```powershell
.\analyze-ai-logs.ps1 -Action tail
```

## Configuration

Edit `ai/ai-debug-logger.lua` to customize:

```lua
AILogger.config = {
    enabled = true,              -- Master on/off switch
    logToFile = true,            -- Write to log files
    logToConsole = true,         -- Print to console
    trackPerformance = true,     -- Track function timing
    logLevel = "DEBUG",          -- DEBUG, INFO, WARN, ERROR
    logPath = "lua/ai/logs/",    -- Where to save logs
    maxStackDepth = 50           -- Recursion limit
}
```

## Protected Functions

Currently protected:
- **SmartAI:initialize** - AI initialization
- **SmartAI:filterEvent** - Main event handler (most crashes here)
- **All callbacks** - Method invocations from C++ side
- **Event callbacks** - Custom event handlers

## Adding More Protection

See `ai/PROTECTION_PATTERNS.lua` for code examples.

Priority functions to protect next (check your error logs):
1. SmartAI:askForCard
2. SmartAI:askForUseCard
3. SmartAI:getCardRandomly
4. SmartAI:askForCardChosen
5. SmartAI:askForDiscard

## Performance Impact

| Mode | Impact |
|------|--------|
| `AI_DEBUG_MODE = true` + `logLevel = "DEBUG"` | High (full logging) |
| `AI_DEBUG_MODE = true` + `logLevel = "ERROR"` | Low (errors only) |
| `AI_DEBUG_MODE = false` | **Zero** (all logging stripped) |

**Recommendation**: 
- Development: `true` + `DEBUG`
- Testing: `true` + `WARN`
- Production: `false`

## Typical Debugging Workflow

1. **Enable**: `_G.AI_DEBUG_MODE = true`
2. **Reproduce**: Run game until crash
3. **Analyze**: `.\analyze-ai-logs.ps1 -Action errors`
4. **Identify**: Check error log for crash function
5. **Fix**: Add nil checks or fix logic in that function
6. **Verify**: Test and check logs show no errors

## Example Error Output

```
=== ERROR IN: Callback:askForCard ===
Error: attempt to index a nil value (field 'player')
Call Stack:
  1. SmartAI:initialize (depth=1)
  2. Callback:askForCard (depth=2)
  3. SmartAI:getCardRandomly (depth=3)
Additional Info: {player=zhangfei, pattern=slash, event=CardUsed}
```

This tells you:
- **What**: Tried to access `player` field on nil value
- **Where**: In `getCardRandomly` function
- **How**: Called from `askForCard` → `initialize`
- **When**: Player was "zhangfei", looking for "slash" card

## Common Crash Patterns & Fixes

### Nil Value Access
```lua
-- Before (crashes):
local hp = player:getHp()

-- After (safe):
if not player or player:isDead() then return nil end
local hp = player:getHp()
```

### Bad Arguments
```lua
-- Before (crashes):
if target:hasSkill("skill") then

-- After (safe):
if target and not target:isDead() and target:hasSkill("skill") then
```

### Infinite Recursion
```lua
-- Add depth limit:
function recursive(depth)
    depth = depth or 0
    if depth > 10 then return nil end
    -- ... code ...
end
```

## Troubleshooting

### Logs not created?
1. Check `lua/ai/logs/` directory exists
2. Verify file permissions
3. Try `logToConsole = true` to test

### Too much output?
```lua
-- In ai-debug-logger.lua:
AILogger.config.logLevel = "ERROR"  -- Only errors
AILogger.config.trackPerformance = false
```

### Logger causes crashes?
```lua
-- Temporarily disable:
_G.AI_DEBUG_MODE = false
```

## Integration with Existing Code

The logger preserves existing log files:
- `lua/ai/cstring` - Hand card visibility (unchanged)
- `lua/ai/cstringEvent` - Event logs (unchanged)
- `lua/ai/logs/*` - New debug logs (separate)

No conflicts with existing logging!

## For More Help

- **Quick Reference**: See `AI_DEBUG_QUICKREF.md`
- **Detailed Guide**: See `AI_DEBUG_GUIDE.md`
- **Code Examples**: See `ai/PROTECTION_PATTERNS.lua`

## Summary

Before this system:
- ❌ Crashes with no error message
- ❌ No way to track what caused crash
- ❌ Hard to reproduce bugs
- ❌ Blind debugging

After this system:
- ✅ Detailed error messages and stack traces
- ✅ Know exactly which function crashed
- ✅ See full execution context
- ✅ Easy to identify and fix bugs
- ✅ Performance profiling bonus

## Credits

System created 2025-11-18 to debug legacy Smart AI code (2008).

**Key Principle**: Fail gracefully with detailed logs instead of silent crashes.
