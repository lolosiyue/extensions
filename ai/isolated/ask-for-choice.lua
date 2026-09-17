-- 值型詢問的 registry。每個 decision kind 一張表，鍵是 request 的 reason
-- （技能名或詢問原因）。handler 統一收 (self, options, request)：options 帶候選、
-- 上下限、可取消與預設值，與舊 callback 的 QVariant data 無關，也不共用同一張表。
local function register_handler(handlers, reason, handler)
    if type(reason) ~= "string" or reason == "" or type(handler) ~= "function" then
        error("invalid isolated value decision handler")
    end
    handlers[reason] = handler
end

local function make_registry(kind)
    local handlers = {}
    if type(ai_coverage) == "table" then
        ai_coverage.declare(kind, function()
            local keys = {}
            for key in pairs(handlers) do keys[#keys + 1] = key end
            return keys
        end)
    end
    ai_register_handler(kind, function(self, request)
        local options = type(request.options) == "table" and request.options or nil
        local reason = options and options.reason
        local handler = type(reason) == "string" and handlers[reason] or nil
        -- 沒有註冊就是未覆蓋，交回舊 AI；不在這裡編一個預設答案。
        if not handler then return nil end
        return handler(self, options, request)
    end)
    return setmetatable({}, {
        __index = handlers,
        __newindex = function(_, reason, handler)
            register_handler(handlers, reason, handler)
        end
    })
end

ai_skill_invoke = make_registry("skill_invoke")
ai_skill_choice = make_registry("choice")
ai_skill_suit = make_registry("suit")
ai_skill_kingdom = make_registry("kingdom")
ai_general_choice = make_registry("general")

-- 選牌與選人族沿用同一種註冊形狀；候選在 options.card_ids／options.players。
ai_skill_discard = make_registry("discard")
ai_skill_askforag = make_registry("amazing_grace")
ai_skill_cardchosen = make_registry("card_chosen")
ai_skill_askforyiji = make_registry("yiji")
ai_skill_playerchosen = make_registry("player_chosen")
ai_skill_playerschosen = make_registry("players_chosen")
ai_skill_guanxing = make_registry("guanxing")
ai_skill_triggerorder = make_registry("trigger_order")

-- 回應牌族共用 respond_card 一種 kind，所以再用 options.question 分辨是哪個詢問；
-- 答案是自己手上一張實體牌的 ID，轉化牌要等值型出牌批次。
local respond_handlers = {}

ai_register_handler("respond_card", function(self, request)
    local options = type(request.options) == "table" and request.options or nil
    local question = options and options.question
    local handlers = type(question) == "string" and respond_handlers[question] or nil
    local handler = handlers and type(options.reason) == "string"
        and handlers[options.reason] or nil
    if not handler then return nil end
    return handler(self, options, request)
end)

local function respond_registry(question)
    local handlers = {}
    if type(ai_coverage) == "table" then
        ai_coverage.declare("respond_card", function()
            local keys = {}
            for key in pairs(handlers) do keys[#keys + 1] = question .. ":" .. key end
            return keys
        end)
    end
    respond_handlers[question] = handlers
    return setmetatable({}, {
        __index = handlers,
        __newindex = function(_, reason, handler)
            register_handler(handlers, reason, handler)
        end
    })
end

ai_skill_cardask = respond_registry("askForCard")
ai_nullification = respond_registry("askForNullification")
ai_cardshow = respond_registry("askForCardShow")
ai_skill_pindian = respond_registry("askForPindian")
ai_skill_singlepeach = respond_registry("askForSinglePeach")
