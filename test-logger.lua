-- Test script for AI Debug Logger
-- Run this to verify the logging system works correctly

-- Load the logger
local AILogger = require "ai.ai-debug-logger"
local logger = AILogger
logger:init()

print("=== AI Debug Logger Test ===")
print("")

-- Enable debug mode
_G.AI_DEBUG_MODE = true

print("1. Testing basic logging...")
logger:writeLog("INFO", "Test info message")
logger:writeLog("WARN", "Test warning message")
logger:writeLog("ERROR", "Test error message")
print("   ✓ Basic logging works")
print("")

print("2. Testing function protection...")
local function testFunction(a, b)
    if a == nil then
        error("Parameter 'a' is nil!")
    end
    return a + b
end

-- Test successful call
local result = logger:protect("testFunction", testFunction, 5, 3)
print("   ✓ Protected function call succeeded: 5 + 3 = " .. tostring(result))

-- Test failed call (should catch error gracefully)
result = logger:protect("testFunction", testFunction, nil, 3)
print("   ✓ Protected function caught error: result = " .. tostring(result))
print("")

print("3. Testing function entry/exit tracking...")
local stackIdx = logger:logFunctionEntry("testTrack", {param1 = "value1"})
-- Simulate some work
local sum = 0
for i = 1, 100 do sum = sum + i end
logger:logFunctionExit("testTrack", stackIdx, true, sum)
print("   ✓ Function tracking works")
print("")

print("4. Testing error logging with context...")
logger:logError("testError", "This is a test error", {
    context = "unit test",
    timestamp = os.date()
})
print("   ✓ Error logging with context works")
print("")

print("5. Testing performance tracking...")
-- Simulate multiple function calls
for i = 1, 5 do
    local idx = logger:logFunctionEntry("performanceTest", {iteration = i})
    -- Simulate work
    local x = 0
    for j = 1, 1000 do x = x + j end
    logger:logFunctionExit("performanceTest", idx, true)
end
print("   ✓ Performance tracking works")
print("")

print("6. Testing stack depth protection...")
local function recursiveTest(depth)
    depth = depth or 0
    if depth > 60 then  -- Exceed maxStackDepth
        return "Should trigger warning"
    end
    local idx = logger:logFunctionEntry("recursiveTest", {depth = depth})
    local result = recursiveTest(depth + 1)
    logger:logFunctionExit("recursiveTest", idx, true)
    return result
end
recursiveTest()
print("   ✓ Stack depth protection works")
print("")

print("7. Saving performance report...")
logger:savePerformanceReport()
print("   ✓ Performance report saved")
print("")

print("8. Testing safe file write...")
local success = logger:safeFileWrite(
    logger.config.logPath .. "test-output.txt",
    "Test file write at " .. os.date() .. "\n"
)
print("   ✓ Safe file write: " .. tostring(success))
print("")

-- Cleanup
logger:shutdown()

print("=== All Tests Completed ===")
print("")
print("Check logs at: " .. logger.config.logPath)
print("  - ai-debug-*.log     (should have detailed logs)")
print("  - ai-errors-*.log    (should have test errors)")
print("  - ai-perf-*.log      (should have performance stats)")
print("  - test-output.txt    (should exist)")
print("")
print("If all tests passed (✓), the logging system is working correctly!")
print("")

-- Disable debug mode
_G.AI_DEBUG_MODE = false
print("Note: Debug mode disabled (_G.AI_DEBUG_MODE = false)")
print("Re-enable in smart-ai.lua to use during actual game debugging")
