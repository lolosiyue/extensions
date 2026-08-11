# AI Debug System - Visual Overview

## What Problem Does This Solve?

```
BEFORE:
  Game runs → Something crashes → Game exits → 😢 No information!
  
AFTER:
  Game runs → Something crashes → Logger catches it → 📝 Detailed log!
  ↓
  Developer checks log → Sees exactly what happened → 🔧 Fixes bug!
```

## The System in One Picture

```
                        🎮 Your Game
                             ↓
                    ┌─────────────────┐
                    │   smart-ai.lua  │
                    │   (Modified)    │
                    └────────┬────────┘
                             ↓
                    Is DEBUG MODE on?
                             │
                ┌────────────┴────────────┐
                │                         │
            ❌ NO                      ✅ YES
                │                         │
                │                         ↓
        Normal execution    ┌──────────────────────┐
        (fast, no logs)     │  ai-debug-logger.lua │
                            │  (Catches crashes)   │
                            └──────────┬───────────┘
                                       ↓
                            ┌─────────────────────┐
                            │   lua/ai/logs/      │
                            │   📄 Debug log      │
                            │   📄 Error log      │
                            │   📄 Perf log       │
                            └──────────┬──────────┘
                                       ↓
                            ┌─────────────────────┐
                            │ analyze-ai-logs.ps1 │
                            │ (Analysis tool)     │
                            └──────────┬──────────┘
                                       ↓
                               🔍 You see:
                               • What crashed
                               • Where it crashed
                               • Why it crashed
```

## Quick Command Reference

```bash
# Enable debugging (in smart-ai.lua):
_G.AI_DEBUG_MODE = true

# Check for errors:
.\analyze-ai-logs.ps1 -Action errors

# Watch live:
.\analyze-ai-logs.ps1 -Action watch

# Performance:
.\analyze-ai-logs.ps1 -Action performance

# Disable for production:
_G.AI_DEBUG_MODE = false
```

## What You Get

### Error Log Example
```
=== ERROR IN: Callback:askForCard ===
Error: attempt to index a nil value
Call Stack:
  1. SmartAI:initialize
  2. Callback:askForCard
  3. SmartAI:getCardRandomly  ← Crash here!
Context: {player=zhangfei, pattern=slash}
```

**Translation**: 
- Function `getCardRandomly` tried to access something that was nil
- It was called by `askForCard` 
- Which was called by `initialize`
- Happened for player "zhangfei" when looking for "slash" cards

### Performance Log Example
```
Function                    Calls  Time(s)  Errors
------------------------------------------------
Callback:filterEvent         523    2.35      0
SmartAI:getCardRandomly     1247    1.89      3  ← 3 crashes!
SmartAI:isFriend            3421    0.92      0
```

**Translation**:
- `getCardRandomly` crashed 3 times
- It's called 1247 times (frequently)
- Takes 1.89 seconds total
- **This function needs fixing!**

## File Organization

```
📁 Your Project
├── 📁 ai/
│   ├── 📄 smart-ai.lua              ← Modified (has logging)
│   ├── 📄 ai-debug-logger.lua       ← New (logger engine)
│   └── 📄 PROTECTION_PATTERNS.lua   ← New (code examples)
│
├── 📁 lua/ai/logs/                   ← New (log output)
│   ├── 📄 ai-debug-*.log
│   ├── 📄 ai-errors-*.log
│   └── 📄 ai-perf-*.log
│
├── 📄 analyze-ai-logs.ps1           ← New (analysis tool)
├── 📄 GETTING_STARTED.md            ← New (start here!)
├── 📄 AI_DEBUG_README.md            ← New (full docs)
└── 📄 AI_DEBUG_QUICKREF.md          ← New (quick reference)
```

## The Three Modes

```
┌──────────────────────────────────────────────┐
│ 🏭 PRODUCTION                                │
│ _G.AI_DEBUG_MODE = false                     │
│ • No logging                                 │
│ • No overhead                                │
│ • Maximum performance                        │
│ Use when: Deploying to users                 │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ 🧪 TESTING                                   │
│ _G.AI_DEBUG_MODE = true                      │
│ AILogger.config.logLevel = "WARN"            │
│ • Errors + warnings only                     │
│ • Low overhead (~5%)                         │
│ • Catch major issues                         │
│ Use when: QA testing                         │
└──────────────────────────────────────────────┘

┌──────────────────────────────────────────────┐
│ 🛠️ DEVELOPMENT                               │
│ _G.AI_DEBUG_MODE = true                      │
│ AILogger.config.logLevel = "DEBUG"           │
│ • Full logging                               │
│ • Higher overhead (~20-30%)                  │
│ • See everything                             │
│ Use when: Debugging crashes                  │
└──────────────────────────────────────────────┘
```

## Common Crash → Fix Examples

### Crash Type 1: Nil Value
```lua
❌ Error: attempt to index a nil value

🔍 Cause: Trying to use something that doesn't exist
    local hp = player:getHp()  ← player is nil

✅ Fix: Check before using
    if not player then return nil end
    local hp = player:getHp()
```

### Crash Type 2: Bad Argument
```lua
❌ Error: bad argument #1 to 'hasSkill' (userdata expected, got nil)

🔍 Cause: Passing nil to function expecting object
    target:hasSkill("skill")  ← target is nil

✅ Fix: Validate arguments
    if target and not target:isDead() then
        target:hasSkill("skill")
    end
```

### Crash Type 3: Infinite Loop
```lua
❌ Error: Call stack too deep! Possible infinite recursion

🔍 Cause: Function calls itself forever
    function f() return f() end

✅ Fix: Add depth limit
    function f(depth)
        depth = depth or 0
        if depth > 10 then return nil end
        return f(depth + 1)
    end
```

## How Protection Works

```
Without Protection:
  Function executes → Error occurs → 💥 CRASH! → Game dies

With Protection:
  Function executes → Error occurs → Logger catches → Game continues
                                          ↓
                                    Logs saved
                                          ↓
                               Developer fixes bug
```

## The Debugging Cycle

```
1. 🎮 Play game
   ↓
2. 💥 Crash happens
   ↓
3. 📊 Check logs: .\analyze-ai-logs.ps1 -Action errors
   ↓
4. 🔍 Read error:
   "Function X crashed because Y"
   ↓
5. 📝 Open smart-ai.lua
   Find function X
   ↓
6. 🔧 Add fix:
   • Nil checks
   • Validation
   • Error handling
   ↓
7. 🧪 Test again
   ↓
8. ✅ No error in logs?
   SUCCESS!
   ↓
9. 🔄 Repeat for next bug
```

## Benefits Summary

| Before | After |
|--------|-------|
| ❌ Silent crashes | ✅ Detailed error logs |
| ❌ No stack trace | ✅ Full call stack |
| ❌ Guessing bugs | ✅ Exact crash location |
| ❌ Hard to debug | ✅ Easy to fix |
| ❌ Fear old code | ✅ Confident changes |
| ⚠️ No perf data | ✅ Performance profiling |

## Memory Aid: The 3 Files You'll Use Most

```
1. 📄 smart-ai.lua (line ~12)
   ↳ _G.AI_DEBUG_MODE = true/false
   ↳ Turn logging on/off

2. 📄 lua/ai/logs/ai-errors-[timestamp].log
   ↳ Open this when crashes happen
   ↳ See what went wrong

3. 💻 .\analyze-ai-logs.ps1
   ↳ Your analysis tool
   ↳ Quick crash summaries
```

## One-Minute Setup

```bash
# 1. Enable (in smart-ai.lua)
_G.AI_DEBUG_MODE = true

# 2. Play game until crash

# 3. Check what happened
.\analyze-ai-logs.ps1 -Action errors

# 4. Fix the bug you found

# 5. Test again
```

## Bottom Line

```
Old way:  Crash → 😢 No info → Guess → Maybe fix?

New way:  Crash → 📝 Detailed log → 🔧 Fix → ✅ Done!
```

**You're now equipped to debug crashes systematically!** 🎉

---

Need details? Check these docs:
- Quick start: `GETTING_STARTED.md`
- Full guide: `AI_DEBUG_README.md`
- Quick ref: `AI_DEBUG_QUICKREF.md`
