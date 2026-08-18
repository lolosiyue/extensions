local pattern_handlers = {}
local skill_handlers = {}

local function register_handler(registry, key, handler)
    if type(key) ~= "string" or key == "" or type(handler) ~= "function" then
        error("invalid isolated askForUseCard handler")
    end
    registry[key] = handler
end

ai_skill_use = setmetatable({}, {
    __index = pattern_handlers,
    __newindex = function(_, pattern, handler)
        register_handler(pattern_handlers, pattern, handler)
    end
})

function ai_register_use_card_handler(pattern, handler)
    ai_skill_use[pattern] = handler
end

function ai_register_use_card_skill_handler(skill_name, handler)
    register_handler(skill_handlers, skill_name, handler)
end

ai_register_handler("use_card", function(self, request)
    local handler
    if type(request.skill_action) == "table" then
        handler = skill_handlers[request.skill_action.activation_skill]
    end
    if not handler then
        handler = pattern_handlers[request.pattern]
    end
    if not handler then
        return nil
    end
    return handler(self, request.prompt, request)
end)
