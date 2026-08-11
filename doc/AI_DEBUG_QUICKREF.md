# Smart AI Crash Debug - Quick Reference

## Quick Start

### 1. Enable Debugging (in smart-ai.lua, line ~10)
```lua
_G.AI_DEBUG_MODE = true  -- Turn on logging
```

### 2. Run Game Until Crash

### 3. Check Logs
```powershell
cd c:\Users\tomchan\Documents\working\git
.\analyze-ai-logs.ps1 -Action errors
```

## Log Files Location
```
lua/ai/logs/
  ├── ai-debug-[timestamp].log    (all function calls)
  ├── ai-errors-[timestamp].log   (crashes only)
  └── ai-perf-[timestamp].log     (performance stats)
```

## Quick Commands

```powershell
# Show summary of latest logs
.\analyze-ai-logs.ps1

# Analyze errors in detail
.\analyze-ai-logs.ps1 -Action errors

# View performance report
.\analyze-ai-logs.ps1 -Action performance

# Watch errors in real-time
.\analyze-ai-logs.ps1 -Action watch

# View last 50 log lines
.\analyze-ai-logs.ps1 -Action tail

# Clean old logs (7+ days)
.\analyze-ai-logs.ps1 -Action clean
```

## Reading Error Logs

### Error Entry Format
```
=== ERROR IN: Callback:askForCard ===
Error: attempt to index a nil value (field 'player')
Call Stack:
  1. SmartAI:initialize (depth=1)
  2. Callback:askForCard (depth=2)
  3. SmartAI:getCardRandomly (depth=3)
Additional Info: {player=zhangfei, event=CardUsed}
```

### What It Means
- **Function**: `getCardRandomly` (depth 3, bottom of stack)
- **Error**: Tried to access `player` field on a nil value
- **Path**: initialize → askForCard → getCardRandomly
- **Context**: Player was "zhangfei", during "CardUsed" event

## Common Errors & Fixes

### Nil Value Access
```
Error: attempt to index a nil value
```
**Fix**: Add nil checks
```lua
-- Before:
local cards = player:getCards("hs")

-- After:
if not player or player:isDead() then return nil end
local cards = player:getCards("hs")
```

### Bad Argument Type
```
Error: bad argument #1 to 'hasSkill' (userdata expected, got nil)
```
**Fix**: Validate argument before passing
```lua
-- Before:
if target:hasSkill("skill") then

-- After:
if target and not target:isDead() and target:hasSkill("skill") then
```

### Infinite Recursion
```
ERROR: Call stack too deep! Possible infinite recursion
```
**Fix**: Add recursion limit
```lua
function SmartAI:recursive(depth)
    depth = depth or 0
    if depth > 10 then return nil end  -- Safety limit
    -- ... your code ...
    return self:recursive(depth + 1)
end
```

## Performance Issues

Check `ai-perf-[timestamp].log`:

```
Function                                  Calls  Total(s)  Max(s)  Errors
------------------------------------------------------------------------
Callback:filterEvent                       523    2.35     0.05      0
SmartAI:getCardRandomly                   1247    1.89     0.02      3  ← Has errors!
SmartAI:isFriend                          3421    0.92     0.00      0  ← Called often
```

**High Errors**: Function crashes frequently → fix bugs  
**High Calls + Total Time**: Performance bottleneck → optimize  
**High Max Time**: Slow execution → profile/optimize

## Toggle Debug Mode

### For Development
```lua
_G.AI_DEBUG_MODE = true
logger.config.logLevel = "DEBUG"
```

### For Testing  
```lua
_G.AI_DEBUG_MODE = true
logger.config.logLevel = "WARN"
```

### For Production
```lua
_G.AI_DEBUG_MODE = false
-- No overhead, all logging disabled
```

## Configuration (ai-debug-logger.lua)

```lua
AILogger.config = {
    enabled = true,              -- Master switch
    logToFile = true,            -- Write log files
    logToConsole = true,         -- Print to console
    trackPerformance = true,     -- Time function calls
    logLevel = "DEBUG",          -- DEBUG|INFO|WARN|ERROR
    logPath = "lua/ai/logs/",    -- Log directory
    maxStackDepth = 50           -- Recursion limit
}
```

## Adding Protection to Your Functions

### Method 1: Inline Protection
```lua
function SmartAI:myFunction(arg1, arg2)
    if _G.AI_DEBUG_MODE then
        return logger:protect("SmartAI:myFunction", function()
            -- Your code here
            return result
        end)
    else
        -- Your code here (faster, no logging)
        return result
    end
end
```

### Method 2: safecall Helper
```lua
local result = safecall("myFunction", someFunction, arg1, arg2)
```

### Method 3: Manual Logging
```lua
if _G.AI_DEBUG_MODE then
    logger:writeLog("INFO", "Checkpoint reached", {
        player = player:getGeneralName(),
        state = "processing"
    })
end
```

## Troubleshooting Logger

### Logs not created?
1. Check directory exists: `lua/ai/logs/`
2. Check file permissions
3. Try `logToConsole = true` instead

### Too much output?
```lua
logger.config.logLevel = "ERROR"  -- Only errors
logger.config.trackPerformance = false
```

### Logger crashes?
```lua
_G.AI_DEBUG_MODE = false  -- Disable temporarily
```

## File Structure

```
git/
├── ai/
│   ├── smart-ai.lua              (main AI, now with logging)
│   ├── ai-debug-logger.lua       (logger module)
│   └── logs/                     (log files go here)
│       ├── ai-debug-*.log
│       ├── ai-errors-*.log
│       └── ai-perf-*.log
├── AI_DEBUG_GUIDE.md             (detailed documentation)
├── AI_DEBUG_QUICKREF.md          (this file)
└── analyze-ai-logs.ps1           (log analysis tool)
```

## Typical Workflow

1. **Enable debug mode**: `_G.AI_DEBUG_MODE = true`
2. **Run game** until crash
3. **Check errors**: `.\analyze-ai-logs.ps1 -Action errors`
4. **Find problematic function** in call stack
5. **Check that function** in smart-ai.lua
6. **Add nil checks** or fix logic
7. **Test again** and verify fix

## Pro Tips

- Keep DEBUG mode OFF in production (performance)
- Check error log FIRST when crashes occur
- Use `watch` to monitor real-time during testing
- Performance log shows which functions are slow
- Clean old logs regularly to save space

## Need Help?

1. Check `AI_DEBUG_GUIDE.md` for detailed explanations
2. Look at error log for crash details
3. Check performance log for slow functions
4. Add custom logging points to track execution

---
**Remember**: The goal is to prevent "crash without information"  
Now you have detailed logs showing exactly what went wrong!
