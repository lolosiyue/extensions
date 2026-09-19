-- Two registries, one per callback ABI. The argument lists never mix: a new handler
-- takes (self, prompt, request); a legacy-style handler takes
-- (self, prompt, method, pattern, request) exactly as SmartAI:askForUseCard calls it.
local pattern_handlers = {}
local skill_handlers = {}
local legacy_pattern_handlers = {}
local legacy_skill_handlers = {}

-- One key belongs to one ABI. A key registered in both has no verifiable dispatch
-- rule, so the conflict is refused at registration instead of resolved silently.
local function register_handler(registry, conflicting, key, handler)
    if type(key) ~= "string" or key == "" or type(handler) ~= "function" then
        error("invalid isolated askForUseCard handler")
    end
    if conflicting[key] then
        error("askForUseCard handler already registered with the other ABI: " .. key)
    end
    registry[key] = handler
end

local function registry_table(registry, conflicting)
    return setmetatable({}, {
        __index = registry,
        __newindex = function(_, pattern, handler)
            register_handler(registry, conflicting, pattern, handler)
        end
    })
end

ai_skill_use = registry_table(pattern_handlers, legacy_pattern_handlers)
ai_skill_use_legacy = registry_table(legacy_pattern_handlers, pattern_handlers)

function ai_register_use_card_handler(pattern, handler)
    ai_skill_use[pattern] = handler
end

function ai_register_use_card_skill_handler(skill_name, handler)
    register_handler(skill_handlers, legacy_skill_handlers, skill_name, handler)
end

function ai_register_use_card_legacy_handler(pattern, handler)
    ai_skill_use_legacy[pattern] = handler
end

function ai_register_use_card_legacy_skill_handler(skill_name, handler)
    register_handler(legacy_skill_handlers, skill_handlers, skill_name, handler)
end

-- The legacy request view exists only for skill actions, like the native
-- AiLegacyRequestView legacy AI receives; a plain pattern request passes nil.
local function call_handler(self, request, key, registry, legacy_registry, pattern)
    local handler = registry[key]
    if handler then
        return AIResultValue.normalize(handler(self, request.prompt, request), request.kind)
    end
    handler = legacy_registry[key]
    if not handler then return nil, "unhandled" end
    return AIResultValue.normalize(handler(self, request.prompt, request.handling_method,
        pattern, AILegacyRequest.new(request, self.room)), request.kind)
end

local function registry_keys(...)
    local registries = {...}
    return function()
        local keys = {}
        for _, registry in ipairs(registries) do
            for key in pairs(registry) do keys[#keys + 1] = key end
        end
        return keys
    end
end

if type(ai_coverage) == "table" then
    ai_coverage.declare("use_card", registry_keys(pattern_handlers, legacy_pattern_handlers))
    ai_coverage.declare("use_card_skill", registry_keys(skill_handlers, legacy_skill_handlers))
end

ai_register_handler("use_card", function(self, request)
    -- Legacy keeps the trailing "!" in the registry key, hands the stripped pattern to
    -- the callback, and refuses a "." answer for a compulsory request. The legacy
    -- cardEffect decline between the pattern and prompt tiers needs event context that
    -- the snapshot does not carry, so it stays uncovered instead of being guessed.
    local raw_pattern = type(request.pattern) == "string" and request.pattern or ""
    local compulsory = string.sub(raw_pattern, -1) == "!"
    local pattern = compulsory and string.sub(raw_pattern, 1, -2) or raw_pattern
    local prompt_key = type(request.prompt) == "string"
        and string.match(request.prompt, "^[^:]*") or nil
    local tiers = {}
    if type(request.skill_action) == "table" then
        tiers[#tiers + 1] = {skill_handlers, legacy_skill_handlers,
            request.skill_action.activation_skill}
    end
    tiers[#tiers + 1] = {pattern_handlers, legacy_pattern_handlers, raw_pattern}
    tiers[#tiers + 1] = {pattern_handlers, legacy_pattern_handlers, prompt_key}
    for _, tier in ipairs(tiers) do
        local key = tier[3]
        if type(key) == "string" and key ~= "" then
            local result, status = call_handler(self, request, key, tier[1], tier[2], pattern)
            if status ~= "unhandled" and not (compulsory and status == "declined") then
                return result
            end
        end
    end
    return nil
end)
