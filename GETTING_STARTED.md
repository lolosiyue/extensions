# Getting Started Checklist

## ✅ Installation Complete

The AI Debug System has been installed! Here's your checklist to start using it.

## 📝 Quick Start Steps

### ☐ Step 1: Verify Installation
Check that these files exist:
- [ ] `ai/ai-debug-logger.lua` - Logger module
- [ ] `ai/smart-ai.lua` - Modified with logging integration
- [ ] `lua/ai/logs/` - Log directory (should be empty initially)
- [ ] `AI_DEBUG_README.md` - Documentation
- [ ] `analyze-ai-logs.ps1` - Analysis tool

### ☐ Step 2: Enable Debug Mode
1. Open `ai/smart-ai.lua`
2. Find line ~12: `_G.AI_DEBUG_MODE = true`
3. Verify it says `true` (not `false`)
4. Save the file

### ☐ Step 3: (Optional) Test the Logger
Run the test script to verify everything works:
```powershell
# Adjust command based on your Lua setup
lua test-logger.lua
```

Expected output: Several checkmarks (✓) and confirmation message

### ☐ Step 4: Run Your Game
1. Launch the game normally
2. Play until a crash occurs (or just play normally)
3. The logger will capture everything automatically

### ☐ Step 5: Check for Logs
After running the game, verify logs were created:
```powershell
dir lua\ai\logs\
```

You should see files like:
- `ai-debug-[timestamp].log`
- `ai-errors-[timestamp].log`
- `ai-perf-[timestamp].log`

### ☐ Step 6: Analyze Results

#### If game crashed:
```powershell
.\analyze-ai-logs.ps1 -Action errors
```

#### For general health check:
```powershell
.\analyze-ai-logs.ps1
```

#### To watch in real-time:
```powershell
.\analyze-ai-logs.ps1 -Action watch
```

### ☐ Step 7: Fix Bugs
1. Look at the error log output
2. Find the function that crashed
3. Open `smart-ai.lua` and locate that function
4. Add appropriate error handling (see patterns below)
5. Test again

## 🔧 Common Fixes

### Fix Pattern 1: Nil Checks
```lua
-- Before (crashes):
local cards = player:getCards("hs")

-- After (safe):
if not player or player:isDead() then 
    return nil 
end
local cards = player:getCards("hs")
```

### Fix Pattern 2: Validate Arguments
```lua
-- Before (crashes):
if target:hasSkill("skill") then

-- After (safe):
if target and not target:isDead() and target:hasSkill("skill") then
```

### Fix Pattern 3: Check Return Values
```lua
-- Before (crashes):
local card = self:getCard()
local id = card:getId()

-- After (safe):
local card = self:getCard()
if not card then return nil end
local id = card:getId()
```

## 📚 Reference Documents

When you need help:

| Question | Document |
|----------|----------|
| "How do I use this?" | `AI_DEBUG_README.md` |
| "What commands are available?" | `AI_DEBUG_QUICKREF.md` |
| "How do I protect more functions?" | `ai/PROTECTION_PATTERNS.lua` |
| "How does it work internally?" | `AI_DEBUG_ARCHITECTURE.md` |
| "I need detailed examples" | `AI_DEBUG_GUIDE.md` |

## ⚙️ Configuration (Optional)

### Reduce Logging Overhead
Edit `ai/ai-debug-logger.lua`, line ~12:
```lua
AILogger.config.logLevel = "WARN"  -- Less logging
-- or
AILogger.config.logLevel = "ERROR"  -- Errors only
```

### Disable Performance Tracking
Edit `ai/ai-debug-logger.lua`, line ~12:
```lua
AILogger.config.trackPerformance = false
```

### Change Log Location
Edit `ai/ai-debug-logger.lua`, line ~12:
```lua
AILogger.config.logPath = "your/custom/path/"
```

## 🎯 Typical First Session

Here's what a typical debugging session looks like:

1. **Enable debug mode** ✓ (Step 2 above)
2. **Play game** → Crash occurs
3. **Check errors**: `.\analyze-ai-logs.ps1 -Action errors`
   ```
   Found 1 errors:
   Error Summary (by function):
     Callback:askForCard: 1 times
   
   Most Recent Error:
   === ERROR IN: Callback:askForCard ===
   Error: attempt to index a nil value
   Call Stack:
     1. SmartAI:initialize (depth=1)
     2. Callback:askForCard (depth=2)
     3. SmartAI:getCardRandomly (depth=3)
   ```

4. **Identify problem**: `getCardRandomly` has nil value access
5. **Find function**: Open `smart-ai.lua`, search for `getCardRandomly`
6. **Add fix**:
   ```lua
   function SmartAI:getCardRandomly(who, flags, no_dis)
       -- Add this at the start:
       if not who or who:isDead() then return nil end
       
       -- Rest of function...
   ```

7. **Test again**: Run game, check no errors
8. **Success!** 🎉

## 🚨 Troubleshooting

### "No log files created"
- Check `_G.AI_DEBUG_MODE = true` in `smart-ai.lua`
- Check `AILogger.config.enabled = true` in `ai-debug-logger.lua`
- Verify `lua/ai/logs/` directory exists
- Check file permissions

### "Can't run analyze-ai-logs.ps1"
```powershell
# May need to allow script execution:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### "Logger causes crashes"
Temporarily disable:
```lua
_G.AI_DEBUG_MODE = false  -- in smart-ai.lua
```
Then debug the logger itself.

### "Too many log files"
Clean old logs:
```powershell
.\analyze-ai-logs.ps1 -Action clean
```

### "Logs are huge"
Reduce logging level:
```lua
AILogger.config.logLevel = "ERROR"  -- in ai-debug-logger.lua
```

## 📊 What to Expect

### First Time Running:
- Larger log files (DEBUG level captures everything)
- Multiple errors might appear (finding all the bugs)
- Performance impact ~20-30%

### After Fixing Bugs:
- Smaller error logs (fewer crashes)
- Can reduce log level to WARN or ERROR
- Better game stability

### Production Ready:
- Set `AI_DEBUG_MODE = false`
- Zero performance impact
- Re-enable if new bugs appear

## 🎓 Learning Path

1. **Week 1**: Learn to read error logs
   - Run with DEBUG mode
   - Check errors daily
   - Fix obvious nil checks

2. **Week 2**: Add more protection
   - Use `ai/PROTECTION_PATTERNS.lua` examples
   - Protect your most crash-prone functions
   - Monitor error frequency

3. **Week 3**: Performance optimization
   - Check performance logs
   - Optimize slow functions
   - Consider reducing log level

4. **Production**: Disable debugging
   - Set `AI_DEBUG_MODE = false`
   - Keep code fixes
   - Re-enable if issues occur

## ✨ Pro Tips

- 💡 Check logs even when game doesn't crash - might reveal hidden issues
- 💡 Use `watch` mode during active testing
- 💡 Keep error log file open in a text editor during development
- 💡 Performance log reveals which functions are called most often
- 💡 Clean logs weekly to avoid clutter
- 💡 Add custom checkpoints in complex functions
- 💡 Share error logs when asking for help (they contain all context!)

## 🎉 You're Ready!

Everything is set up. Start by:
1. ✅ Enabling debug mode (Step 2)
2. ✅ Running your game (Step 4)
3. ✅ Checking for errors (Step 6)

**No more mysterious crashes!** Every crash now tells you exactly what went wrong, where, and why.

---

Questions? Check `AI_DEBUG_README.md` for comprehensive documentation.

Happy debugging! 🐛🔍
