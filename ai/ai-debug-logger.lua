-- AI Debug Logger Module
-- Comprehensive crash tracking and logging system for Smart AI
-- Created: 2025-11-18

local AILogger = {}

-- Configuration
AILogger.config = {
	enabled = true,
	logToFile = true,
	logToConsole = true,
	trackPerformance = true,
	maxLogFileSize = 5 * 1024 * 1024, -- 5MB
	logLevel = "DEBUG", -- DEBUG, INFO, WARN, ERROR
	logPath = "lua/ai/logs/",
	maxStackDepth = 50
}

-- Log levels
AILogger.LogLevel = {
	DEBUG = 1,
	INFO = 2,
	WARN = 3,
	ERROR = 4,
	FATAL = 5
}

-- Current log level threshold
local currentLogLevel = AILogger.LogLevel.DEBUG

-- Performance tracking
AILogger.perfStats = {}
AILogger.callStack = {}
AILogger.callDepth = 0

-- Initialize logger
function AILogger:init()
	-- Create log directory if it doesn't exist
	os.execute('mkdir "' .. self.config.logPath .. '" 2>nul')
	
	-- Initialize log file with timestamp
	self.logFile = self.config.logPath .. "ai-debug-" .. os.date("%Y%m%d-%H%M%S") .. ".log"
	self.errorFile = self.config.logPath .. "ai-errors-" .. os.date("%Y%m%d-%H%M%S") .. ".log"
	self.perfFile = self.config.logPath .. "ai-perf-" .. os.date("%Y%m%d-%H%M%S") .. ".log"
	
	self:writeLog("INFO", "=== AI Debug Logger Initialized ===")
	self:writeLog("INFO", "Log file: " .. self.logFile)
	self:writeLog("INFO", "Timestamp: " .. os.date("%Y-%m-%d %H:%M:%S"))
end

-- Safe file write with error handling
function AILogger:safeFileWrite(filename, content, mode)
	mode = mode or "a"
	local success, result = pcall(function()
		local file = io.open(filename, mode)
		if file then
			file:write(content)
			file:flush()
			file:close()
			return true
		end
		return false
	end)
	
	if not success then
		-- Fallback: try to write to console if file write fails
		if self.config.logToConsole then
			print("[LOG WRITE ERROR] " .. tostring(result))
		end
		return false
	end
	return result
end

-- Format log message
function AILogger:formatMessage(level, message, context)
	local timestamp = os.date("%H:%M:%S")
	local depth = string.rep("  ", math.min(self.callDepth, 10))
	local contextStr = ""
	
	if context then
		if type(context) == "table" then
			contextStr = " | " .. self:tableToString(context, 1)
		else
			contextStr = " | " .. tostring(context)
		end
	end
	
	return string.format("[%s] %s %s%s%s\n", timestamp, level, depth, message, contextStr)
end

-- Convert table to string (safe)
function AILogger:tableToString(tbl, depth)
	depth = depth or 1
	if depth > 3 then return "{...}" end
	
	if type(tbl) ~= "table" then
		return tostring(tbl)
	end
	
	local result = "{"
	local count = 0
	local maxItems = 10
	
	for k, v in pairs(tbl) do
		if count >= maxItems then
			result = result .. "..."
			break
		end
		
		local key = tostring(k)
		local value
		
		if type(v) == "table" then
			value = self:tableToString(v, depth + 1)
		elseif type(v) == "function" then
			value = "<function>"
		elseif type(v) == "userdata" then
			value = "<userdata>"
		else
			value = tostring(v)
		end
		
		if count > 0 then result = result .. ", " end
		result = result .. key .. "=" .. value
		count = count + 1
	end
	
	return result .. "}"
end

-- Write log entry
function AILogger:writeLog(level, message, context)
	if not self.config.enabled then return end
	
	local levelNum = self.LogLevel[level] or self.LogLevel.INFO
	if levelNum < currentLogLevel then return end
	
	local formattedMsg = self:formatMessage(level, message, context)
	
	-- Write to console
	if self.config.logToConsole and levelNum >= self.LogLevel.WARN then
		print(formattedMsg)
	end
	
	-- Write to file
	if self.config.logToFile then
		local targetFile = self.logFile
		if levelNum >= self.LogLevel.ERROR then
			targetFile = self.errorFile
		end
		self:safeFileWrite(targetFile, formattedMsg)
	end
end

-- Log function entry
function AILogger:logFunctionEntry(funcName, args)
	self.callDepth = self.callDepth + 1
	
	if self.callDepth > self.config.maxStackDepth then
		self:writeLog("ERROR", "Call stack too deep! Possible infinite recursion in: " .. funcName)
		return nil
	end
	
	table.insert(self.callStack, {
		name = funcName,
		startTime = os.clock(),
		depth = self.callDepth
	})
	
	if self.config.trackPerformance then
		if not self.perfStats[funcName] then
			self.perfStats[funcName] = {
				calls = 0,
				totalTime = 0,
				maxTime = 0,
				errors = 0
			}
		end
		self.perfStats[funcName].calls = self.perfStats[funcName].calls + 1
	end
	
	local argStr = ""
	if args and type(args) == "table" then
		argStr = self:tableToString(args, 1)
	end
	
	self:writeLog("DEBUG", ">> ENTER: " .. funcName, argStr)
	
	return #self.callStack
end

-- Log function exit
function AILogger:logFunctionExit(funcName, stackIndex, success, result)
	if stackIndex and self.callStack[stackIndex] then
		local entry = self.callStack[stackIndex]
		local elapsed = os.clock() - entry.startTime
		
		if self.config.trackPerformance then
			local stats = self.perfStats[funcName]
			if stats then
				stats.totalTime = stats.totalTime + elapsed
				if elapsed > stats.maxTime then
					stats.maxTime = elapsed
				end
				if not success then
					stats.errors = stats.errors + 1
				end
			end
		end
		
		local status = success and "OK" or "ERROR"
		local timeStr = string.format("%.4fs", elapsed)
		
		self:writeLog("DEBUG", "<< EXIT: " .. funcName .. " [" .. status .. "] " .. timeStr)
		
		table.remove(self.callStack, stackIndex)
	end
	
	self.callDepth = math.max(0, self.callDepth - 1)
end

-- Log error with stack trace
function AILogger:logError(funcName, errorMsg, additionalInfo)
	local stackTrace = "Call Stack:\n"
	for i = #self.callStack, 1, -1 do
		local entry = self.callStack[i]
		stackTrace = stackTrace .. string.format("  %d. %s (depth=%d)\n", 
			#self.callStack - i + 1, entry.name, entry.depth)
	end
	
	local fullError = string.format(
		"=== ERROR IN: %s ===\nError: %s\n%s",
		funcName, tostring(errorMsg), stackTrace
	)
	
	if additionalInfo then
		fullError = fullError .. "\nAdditional Info: " .. self:tableToString(additionalInfo)
	end
	
	self:writeLog("ERROR", fullError)
	
	-- Also write to separate error file for easy access
	self:safeFileWrite(self.errorFile, 
		"[" .. os.date("%Y-%m-%d %H:%M:%S") .. "]\n" .. fullError .. "\n\n")
end

-- Wrap function with error handling and logging
function AILogger:wrapFunction(obj, funcName, originalFunc)
	return function(...)
		local stackIndex = self:logFunctionEntry(funcName, {...})
		
		local success, result1, result2, result3 = pcall(originalFunc, ...)
		
		if success then
			self:logFunctionExit(funcName, stackIndex, true, result1)
			return result1, result2, result3
		else
			self:logError(funcName, result1, {args = {...}})
			self:logFunctionExit(funcName, stackIndex, false, result1)
			
			-- Return nil on error to prevent crash propagation
			return nil
		end
	end
end

-- Auto-wrap all functions in a table/class
function AILogger:wrapAllFunctions(obj, prefix)
	prefix = prefix or ""
	local wrapped = {}
	
	for key, value in pairs(obj) do
		if type(value) == "function" then
			local funcName = prefix .. "." .. key
			wrapped[key] = self:wrapFunction(obj, funcName, value)
			self:writeLog("INFO", "Wrapped function: " .. funcName)
		end
	end
	
	return wrapped
end

-- Save performance report
function AILogger:savePerformanceReport()
	if not self.config.trackPerformance then return end
	
	local report = "=== AI Performance Report ===\n"
	report = report .. "Generated: " .. os.date("%Y-%m-%d %H:%M:%S") .. "\n\n"
	
	-- Sort by total time
	local sortedFuncs = {}
	for name, stats in pairs(self.perfStats) do
		table.insert(sortedFuncs, {name = name, stats = stats})
	end
	
	table.sort(sortedFuncs, function(a, b)
		return a.stats.totalTime > b.stats.totalTime
	end)
	
	report = report .. string.format("%-50s %10s %10s %10s %8s\n", 
		"Function", "Calls", "Total(s)", "Max(s)", "Errors")
	report = report .. string.rep("-", 100) .. "\n"
	
	for _, entry in ipairs(sortedFuncs) do
		if entry.stats.calls > 0 then
			local avgTime = entry.stats.totalTime / entry.stats.calls
			report = report .. string.format("%-50s %10d %10.4f %10.4f %8d\n",
				entry.name:sub(1, 50),
				entry.stats.calls,
				entry.stats.totalTime,
				entry.stats.maxTime,
				entry.stats.errors)
		end
	end
	
	self:safeFileWrite(self.perfFile, report, "w")
	self:writeLog("INFO", "Performance report saved to: " .. self.perfFile)
end

-- Simple wrapper for quick function protection
function AILogger:protect(funcName, func, ...)
	local args = {...}
	local stackIndex = self:logFunctionEntry(funcName, args)
	
	local results = {pcall(func, ...)}
	local success = table.remove(results, 1)
	
	if success then
		self:logFunctionExit(funcName, stackIndex, true)
		return unpack(results)
	else
		self:logError(funcName, results[1], {args = args})
		self:logFunctionExit(funcName, stackIndex, false)
		return nil
	end
end

-- Clean up
function AILogger:shutdown()
	self:savePerformanceReport()
	self:writeLog("INFO", "=== AI Debug Logger Shutdown ===")
end

return AILogger
