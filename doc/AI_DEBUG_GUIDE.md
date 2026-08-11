# AI Debug Logger - Crash Tracking and Diagnostic Guide

## Overview
This logging system was added on 2025-11-18 to help track down crashes and errors in the Smart AI system (circa 2008 codebase). It provides comprehensive logging, error tracking, performance profiling, and crash protection.

## Features

### 1. **Automatic Crash Detection**
- Wraps critical functions with `pcall()` for error handling
- Catches and logs errors before they crash the game
- Provides detailed stack traces showing the exact call sequence

### 2. **Function Call Tracing**
- Logs entry/exit of all wrapped functions
- Tracks call depth to detect infinite recursion
- Records function arguments and return values

### 3. **Performance Monitoring**
- Tracks execution time for each function
- Counts function calls
- Identifies slow/problematic functions
- Generates performance reports

### 4. **Safe File I/O**
- All file operations are wrapped in protected calls
- Prevents crashes from file access errors
- Falls back to console logging if files can't be written

### 5. **Multiple Log Files**
- `ai-debug-[timestamp].log` - General debug information
- `ai-errors-[timestamp].log` - Error-only log for easy troubleshooting
- `ai-perf-[timestamp].log` - Performance statistics report

## How to Use

### Enable/Disable Logging

In `smart-ai.lua`, near the top of the file:

```lua
_G.AI_DEBUG_MODE = true  -- Enable logging
_G.AI_DEBUG_MODE = false -- Disable logging (for production)
```

### Configure Logging Behavior

Edit `ai/ai-debug-logger.lua`:

```lua
AILogger.config = {
	enabled = true,              -- Master switch
	logToFile = true,            -- Write to log files
	logToConsole = true,         -- Print warnings/errors to console
	trackPerformance = true,     -- Track function timing
	maxLogFileSize = 5242880,    -- 5MB max per log file
	logLevel = "DEBUG",          -- DEBUG, INFO, WARN, ERROR
	logPath = "lua/ai/logs/",    -- Where to save logs
	maxStackDepth = 50           -- Max recursion depth before warning
}
```

### Log Levels
- **DEBUG**: Detailed function entry/exit, arguments
- **INFO**: General information, initialization
- **WARN**: Potential issues, missing methods
- **ERROR**: Actual errors and crashes
- **FATAL**: Critical failures

## Reading the Logs

### Log File Format
```
[HH:MM:SS] LEVEL  Function_Name | Context_Info
  [HH:MM:SS] DEBUG    >> ENTER: SmartAI:initialize
  [HH:MM:SS] DEBUG      >> ENTER: Callback:askForCard | {pattern=slash, prompt=...}
  [HH:MM:SS] DEBUG      << EXIT: Callback:askForCard [OK] 0.0023s
  [HH:MM:SS] ERROR    === ERROR IN: Callback:filterEvent ===
```

### Understanding Stack Traces
When a crash occurs, you'll see:
```
=== ERROR IN: Callback:filterEvent ===
Error: attempt to index a nil value
Call Stack:
  1. SmartAI:filterEvent (depth=1)
  2. Callback:askForCard (depth=2)
  3. SmartAI:getCardRandomly (depth=3)
Additional Info: {player=zhangfei, event=CardUsed, ...}
```

This tells you:
1. **Where it crashed**: `filterEvent` function
2. **What went wrong**: "attempt to index a nil value"
3. **How it got there**: The chain of function calls
4. **Context**: Player name, event type, etc.

## Common Crash Patterns

### Pattern 1: Nil Value Access
```
Error: attempt to index a nil value
```
**Cause**: Trying to access a field on a nil object (e.g., `player.name` when `player` is nil)
**Fix**: Add nil checks before accessing objects

### Pattern 2: Infinite Recursion
```
ERROR: Call stack too deep! Possible infinite recursion in: SmartAI:isFriend
```
**Cause**: Function calls itself repeatedly without exit condition
**Fix**: Check recursion logic and add depth limits

### Pattern 3: Invalid Card/Player References
```
Error: bad argument #1 to 'hasSkill' (userdata expected, got nil)
```
**Cause**: Using a card or player object that no longer exists
**Fix**: Validate objects before using them

## Performance Analysis

After running with `trackPerformance = true`, check `ai-perf-[timestamp].log`:

```
Function                                           Calls  Total(s)    Max(s)  Errors
--------------------------------------------------------------------------------
Callback:filterEvent                                 523     2.3451    0.0523       0
SmartAI:getCardRandomly                             1247     1.8923    0.0234       3
SmartAI:isFriend                                    3421     0.9234    0.0012       0
```

This shows:
- **Calls**: How many times the function was called
- **Total(s)**: Total time spent in this function
- **Max(s)**: Longest single execution
- **Errors**: Number of times this function crashed

**Look for:**
- High error counts → function has bugs
- High max times → function is slow
- Many calls + high total time → performance bottleneck

## Adding Protection to More Functions

To protect additional critical functions, use the logger:

```lua
-- Protect a single function
function SmartAI:criticalFunction(arg1, arg2)
	if _G.AI_DEBUG_MODE then
		return logger:protect("SmartAI:criticalFunction", function()
			-- Your function body here
			return result
		end)
	else
		-- Your function body here (unprotected, faster)
		return result
	end
end

-- Quick inline protection
local result = safecall("functionName", someFunction, arg1, arg2)
```

## Troubleshooting the Logger

### Logger itself causes crashes
1. Check that `ai-debug-logger.lua` is in the correct path
2. Ensure the `lua/ai/logs/` directory can be created
3. Set `enabled = false` in logger config to disable temporarily

### Logs aren't being written
1. Check file permissions on `lua/ai/logs/` directory
2. Try setting `logToConsole = true` to see if logging works at all
3. Check disk space

### Too much log output
1. Increase `logLevel` to "WARN" or "ERROR"
2. Set `trackPerformance = false`
3. Disable with `_G.AI_DEBUG_MODE = false`

## Best Practices

### For Development
- Keep `AI_DEBUG_MODE = true`
- Use `logLevel = "DEBUG"`
- Enable all logging features

### For Testing
- Keep `AI_DEBUG_MODE = true`
- Use `logLevel = "WARN"`
- Focus on errors and performance

### For Production
- Set `AI_DEBUG_MODE = false`
- This removes all logging overhead
- No performance impact when disabled

## Integration with Existing Logs

The logger works alongside existing logging:
- `lua/ai/cstring` - Hand card visibility logs (preserved)
- `lua/ai/cstringEvent` - Event logs (preserved)
- New logs are in `lua/ai/logs/` directory (separate)

## Advanced: Custom Log Points

Add custom logging anywhere in the code:

```lua
if _G.AI_DEBUG_MODE then
	logger:writeLog("INFO", "Custom checkpoint reached", {
		player = player:getGeneralName(),
		cards_count = #cards
	})
end
```

## Example Debugging Session

1. **Enable debugging**:
   ```lua
   _G.AI_DEBUG_MODE = true
   ```

2. **Run the game until it crashes**

3. **Check error log**:
   ```
   Open: lua/ai/logs/ai-errors-[latest].log
   ```

4. **Find the crash**:
   ```
   === ERROR IN: Callback:askForCard ===
   Error: attempt to call method 'getCards' (a nil value)
   Call Stack:
     1. SmartAI:initialize (depth=1)
     2. Callback:askForCard (depth=2)
     3. SmartAI:getCardRandomly (depth=3)
   ```

5. **Identify the problem**:
   - Crash is in `getCardRandomly`
   - It's trying to call `getCards()` on a nil object
   - Look at line in `getCardRandomly` where this happens

6. **Fix the code**:
   ```lua
   -- Before (crashes):
   local cards = who:getCards("hs")
   
   -- After (safe):
   if not who or who:isDead() then return nil end
   local cards = who:getCards("hs")
   ```

7. **Verify the fix** - rerun and check logs show no errors

## Summary

The AI Debug Logger provides:
- ✅ Crash protection with detailed error reporting
- ✅ Function call tracing for debugging
- ✅ Performance profiling to find bottlenecks
- ✅ Zero overhead when disabled
- ✅ Safe file operations
- ✅ Easy to enable/disable

This should significantly reduce the "crash without information" problem and help you identify and fix bugs much faster.

## Questions?

Check the logs first! The answer is usually in:
- `ai-errors-[timestamp].log` for crashes
- `ai-debug-[timestamp].log` for execution flow
- `ai-perf-[timestamp].log` for performance issues
