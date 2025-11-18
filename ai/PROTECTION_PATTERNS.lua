-- Example: How to Add Crash Protection to Specific Functions
-- Copy these patterns to protect other critical functions in smart-ai.lua

-- Pattern 1: Protect entire function body with pcall wrapper
-- Use for complex functions with multiple operations
--[[
function SmartAI:criticalFunction(player, card, data)
	if _G.AI_DEBUG_MODE then
		local stackIndex = logger:logFunctionEntry("SmartAI:criticalFunction", {
			player = player:getGeneralName(),
			card = card:toString()
		})
		
		local success, result1, result2 = pcall(function()
			-- Original function body here
			-- ... your code ...
			return value1, value2
		end)
		
		if success then
			logger:logFunctionExit("SmartAI:criticalFunction", stackIndex, true)
			return result1, result2
		else
			logger:logError("SmartAI:criticalFunction", result1, {
				player = player:getGeneralName(),
				card = card:toString()
			})
			logger:logFunctionExit("SmartAI:criticalFunction", stackIndex, false)
			return nil  -- Safe fallback
		end
	else
		-- Original function body (no overhead when debugging disabled)
		-- ... your code ...
		return value1, value2
	end
end
]]

-- Pattern 2: Use logger:protect for simple functions
-- Quick one-liner protection
--[[
function SmartAI:simpleFunction(arg1, arg2)
	if _G.AI_DEBUG_MODE then
		return logger:protect("SmartAI:simpleFunction", function()
			-- Your code here
			local result = arg1 + arg2
			return result
		end)
	else
		-- Your code here
		local result = arg1 + arg2
		return result
	end
end
]]

-- Pattern 3: Use safecall helper (defined in smart-ai.lua top)
-- Good for calling other functions safely
--[[
function SmartAI:callsOtherFunction(player)
	local result
	if _G.AI_DEBUG_MODE then
		result = safecall("externalFunction", externalFunction, player)
	else
		result = externalFunction(player)
	end
	return result
end
]]

-- Pattern 4: Add checkpoints in long functions
-- Useful for tracking where crashes occur in big functions
--[[
function SmartAI:longComplexFunction(...)
	if _G.AI_DEBUG_MODE then
		logger:writeLog("DEBUG", "Starting longComplexFunction phase 1")
	end
	
	-- Phase 1 code
	
	if _G.AI_DEBUG_MODE then
		logger:writeLog("DEBUG", "Starting longComplexFunction phase 2")
	end
	
	-- Phase 2 code
	
	if _G.AI_DEBUG_MODE then
		logger:writeLog("DEBUG", "Completed longComplexFunction")
	end
end
]]

-- Pattern 5: Protect nil-prone operations
-- Add safety checks before dangerous operations
--[[
-- BEFORE (crash-prone):
function SmartAI:dangerousFunction(player, target)
	local cards = target:getCards("hs")
	return cards:length() > 0
end

-- AFTER (safe):
function SmartAI:dangerousFunction(player, target)
	-- Validate inputs
	if not player then
		if _G.AI_DEBUG_MODE then
			logger:writeLog("WARN", "dangerousFunction: player is nil")
		end
		return false
	end
	
	if not target or target:isDead() then
		if _G.AI_DEBUG_MODE then
			logger:writeLog("WARN", "dangerousFunction: target is nil or dead", {
				player = player:getGeneralName()
			})
		end
		return false
	end
	
	-- Safe to proceed
	local cards = target:getCards("hs")
	if not cards then
		return false
	end
	
	return cards:length() > 0
end
]]

-- Pattern 6: Protect callbacks and event handlers
-- Important for filterEvent and similar functions
--[[
-- Wrap callback execution
for _, callback in pairs(callbacks) do
	if type(callback) == "function" then
		if _G.AI_DEBUG_MODE then
			local success, error_msg = pcall(callback, self, player, data)
			if not success then
				logger:logError("Callback execution", error_msg, {
					callback_type = "event_handler"
				})
			end
		else
			callback(self, player, data)
		end
	end
end
]]

-- Pattern 7: Safe file I/O
-- Prevent crashes from file operations
--[[
-- BEFORE (crash-prone):
local file = io.open("somefile.txt", "w")
file:write("data")
file:close()

-- AFTER (safe):
local success, err = pcall(function()
	local file = io.open("somefile.txt", "w")
	if file then
		file:write("data")
		file:close()
	else
		if _G.AI_DEBUG_MODE then
			logger:writeLog("WARN", "Could not open file: somefile.txt")
		end
	end
end)

if not success and _G.AI_DEBUG_MODE then
	logger:logError("File I/O", err)
end
]]

-- PRIORITY FUNCTIONS TO PROTECT (from most crash-prone to least):
--
-- 1. SmartAI:filterEvent - DONE (already protected in smart-ai.lua)
-- 2. SmartAI:askForCard - High crash rate
-- 3. SmartAI:askForUseCard - Called frequently
-- 4. SmartAI:getCardRandomly - Nil value issues
-- 5. SmartAI:askForCardChosen - Player/target validation needed
-- 6. SmartAI:askForDiscard - Card validation issues
-- 7. SmartAI:isFriend / isEnemy - Logic errors
-- 8. SmartAI:sortByKeepValue - Comparison function crashes
-- 9. Any function using :getCards(), :getHandcardNum() without nil checks
-- 10. Event callbacks in sgs.ai_event_callback

-- EXAMPLE: Protecting askForCard (one of the most crash-prone)
--[[
function SmartAI:askForCard(pattern, prompt, data, method)
	if _G.AI_DEBUG_MODE then
		local stackIndex = logger:logFunctionEntry("SmartAI:askForCard", {
			pattern = pattern,
			prompt = prompt,
			player = self.player:getGeneralName()
		})
		
		local success, result = pcall(function()
			-- Original askForCard implementation here
			-- ... (hundreds of lines) ...
			return final_result
		end)
		
		if success then
			logger:logFunctionExit("SmartAI:askForCard", stackIndex, true)
			return result
		else
			logger:logError("SmartAI:askForCard", result, {
				pattern = pattern,
				prompt = prompt,
				player = self.player:getGeneralName()
			})
			logger:logFunctionExit("SmartAI:askForCard", stackIndex, false)
			return nil  -- Safe fallback prevents cascade crashes
		end
	else
		-- Original implementation without logging (for production)
		-- ... (hundreds of lines) ...
		return final_result
	end
end
]]

-- TIP: Start with the functions that show up most in your error logs!
-- Run with debugging enabled, check ai-errors-*.log, and protect those functions first.

-- Remember: Balance between protection and performance
-- - Development: Protect everything, detailed logging
-- - Testing: Protect critical functions, warn-level logging
-- - Production: AI_DEBUG_MODE = false (no overhead at all)
