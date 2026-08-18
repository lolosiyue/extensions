local handlers = {}

function ai_register_handler(kind, handler)
    if type(kind) ~= "string" or type(handler) ~= "function" then
        error("invalid isolated AI handler")
    end
    handlers[kind] = handler
end

function ai_decide(request)
    if type(request) ~= "table" then
        return nil
    end
    local handler = handlers[request.kind]
    if not handler then
        return nil
    end
    if type(SmartAIView) ~= "table" or type(SmartAIView.new) ~= "function" then
        return nil
    end
    local self_view = SmartAIView.new(request)
    if not self_view then
        return nil
    end
    return handler(self_view, request)
end
