-- ai_isolated_core：這個 runtime 少了哪幾支就答不出任何一題。
-- 對應 smart-ai.lua 開頭那幾行 dofile：要載入什麼由 Lua 這邊宣告，不寫在 C++ 裡。
-- sandbox 拿掉了 dofile，所以實際開檔由 host 代勞（AiLuaRuntime::loadConfiguredScripts），
-- 但清單的權威在這裡；host 只負責照這張清單去讀 lua/ai/isolated/ 底下的檔。
-- 武將／套件的 handler 不寫進這裡：那些照 <套件名>-ai.lua 由啟用的套件自己帶進來，
-- 規則與 smart-ai.lua 掃 lua/ai/ 找 <package>-ai.lua 相同。
ai_isolated_core = {
    "ask-for-use-card.lua",
    "ask-for-choice.lua",
    "decision-core.lua",
    "retrial.lua",
    "strategy-hooks.lua",
    "event-intention.lua",
}

-- ai_memory：跨 request 的推測記憶，按觀察者分區。
-- 這裡存的是「這名觀察者相信什麼」，不是權威狀態：權威資料一律看當次快照。
-- 只收純值（number／string／boolean 與它們組成的表），拒收代理、函式與 userdata，
-- 所以不可能有跨 request 的代理或別的觀察者的秘密被留下來。
-- VM 因為指令上限或記憶體重建時，這份記憶會一起消失，handler 必須容忍 recall 回 nil。
local memory = {}
local memory_limits = {depth = 8, values = 1024, entries = 256}

local function copy_pure_value(value, depth)
    local value_type = type(value)
    if value_type == "number" or value_type == "string" or value_type == "boolean" then
        return value, 1
    end
    assert(value_type == "table", "ai_memory only stores plain values")
    assert(depth <= memory_limits.depth, "ai_memory value is nested too deeply")
    assert(getmetatable(value) == nil, "ai_memory cannot store a proxy or a class instance")
    local copy, counted = {}, 1
    for key, item in pairs(value) do
        local key_type = type(key)
        assert(key_type == "string" or key_type == "number", "ai_memory keys must be plain")
        local copied_item, item_count = copy_pure_value(item, depth + 1)
        counted = counted + item_count
        assert(counted <= memory_limits.values, "ai_memory value is too large")
        copy[key] = copied_item
    end
    return copy, counted
end

local function memory_for(viewer, create)
    if type(viewer) ~= "string" or viewer == "" then return nil end
    local owned = memory[viewer]
    if not owned and create then
        owned = {}
        memory[viewer] = owned
    end
    return owned
end

ai_memory = {}

function ai_memory.recall(viewer, key)
    local owned = memory_for(viewer, false)
    local stored = owned and owned[key] or nil
    if stored == nil then return nil end
    return (copy_pure_value(stored, 1))
end

function ai_memory.remember(viewer, key, value)
    assert(type(key) == "string" and key ~= "", "ai_memory needs a string key")
    local owned = memory_for(viewer, true)
    assert(owned, "ai_memory needs the observer it belongs to")
    if value == nil then
        owned[key] = nil
        return
    end
    if owned[key] == nil then
        local used = 0
        for _ in pairs(owned) do used = used + 1 end
        assert(used < memory_limits.entries, "ai_memory has too many entries")
    end
    owned[key] = (copy_pure_value(value, 1))
end

function ai_memory.forget(viewer)
    if type(viewer) == "string" and viewer ~= "" then memory[viewer] = nil end
end

function ai_memory.clear()
    memory = {}
end

-- Cross-request planning is a bounded, viewer-scoped value store.  It carries
-- an intent only; the authoritative side must revalidate targets, costs and
-- candidate tickets before applying it.  A revision mismatch invalidates the
-- entry instead of pretending that an old plan is still legal.
local planning = {}
local planning_limit = 32
local planning_keys = {target = true, cost = true, intent = true}

ai_planning = {}

local function planning_for(viewer, create)
    if type(viewer) ~= "string" or viewer == "" then return nil end
    if not planning[viewer] and create then planning[viewer] = {} end
    return planning[viewer]
end

function ai_planning.plan(viewer, kind, revision, decision_id, intent)
    assert(planning_keys[kind], "ai_planning kind must be target, cost or intent")
    assert(revision ~= nil, "ai_planning needs a state revision")
    local owned = planning_for(viewer, true)
    assert(owned, "ai_planning needs its observer")
    if owned[kind] == nil then
        local used = 0
        for _ in pairs(owned) do used = used + 1 end
        assert(used < planning_limit, "ai_planning has too many entries")
    end
    assert(decision_id ~= nil, "ai_planning needs a decision identity")
    local copied = copy_pure_value(intent, 1)
    owned[kind] = {revision = copy_pure_value(revision, 1),
        decision_id = copy_pure_value(decision_id, 1), intent = copied}
    return true
end

function ai_planning.peek(viewer, kind, revision, decision_id)
    local owned = planning_for(viewer, false)
    local entry = owned and owned[kind] or nil
    if not entry then return nil, "missing" end
    if revision == nil or decision_id == nil or entry.revision ~= revision
        or (kind ~= "intent" and entry.decision_id ~= decision_id) then
        owned[kind] = nil
        return nil, "stale"
    end
    return copy_pure_value(entry.intent, 1), "fresh"
end

function ai_planning.revalidate(viewer, kind, revision, decision_id, valid)
    if valid ~= true then
        local current, status = ai_planning.peek(viewer, kind, revision, decision_id)
        if status ~= "fresh" then return current, status end
        local owned = planning_for(viewer, false)
        if owned then owned[kind] = nil end
        return nil, "invalidated"
    end
    return ai_planning.peek(viewer, kind, revision, decision_id)
end

function ai_planning.invalidate(viewer, kind)
    local owned = planning_for(viewer, false)
    if owned then owned[kind] = nil end
end

function ai_planning.clear(viewer)
    if viewer == nil then planning = {} else planning[viewer] = nil end
end

-- ai_coverage：這個 VM 目前接得住哪些決策。切換路由與驗收要靠它，而不是靠「試試看」。
-- 每個 registry 自己申報它的鍵，沒申報的就是沒覆蓋，不會被當成已接通。
local coverage_sources = {}

ai_coverage = {}
local outcome_counts = {}

local function record_outcome(kind, status)
    kind = type(kind) == "string" and kind or "invalid"
    local row = outcome_counts[kind]
    if not row then row = {}; outcome_counts[kind] = row end
    row[status] = (row[status] or 0) + 1
end

-- Registration coverage describes capabilities; outcomes describe actual requests.
-- Keep only counters, never hands, target IDs, prompts or callback error contents.
function ai_coverage.outcomes()
    return (copy_pure_value(outcome_counts, 1))
end

function ai_coverage.clearOutcomes()
    outcome_counts = {}
end

function ai_coverage.declare(kind, list_keys)
    if type(kind) ~= "string" or kind == "" or type(list_keys) ~= "function" then
        error("invalid coverage declaration")
    end
    coverage_sources[kind] = coverage_sources[kind] or {}
    table.insert(coverage_sources[kind], list_keys)
end

function ai_coverage.describe()
    local report = {}
    for kind, sources in pairs(coverage_sources) do
        local keys = {}
        for _, list_keys in ipairs(sources) do
            for _, key in ipairs(list_keys() or {}) do keys[#keys + 1] = key end
        end
        table.sort(keys)
        report[kind] = keys
    end
    return report
end

-- 給 C++／診斷用的一行摘要："kind=key,key;kind=..."，沒有覆蓋就是空字串。
function ai_coverage.summary()
    local report, kinds = ai_coverage.describe(), {}
    for kind in pairs(report) do kinds[#kinds + 1] = kind end
    table.sort(kinds)
    local parts = {}
    for _, kind in ipairs(kinds) do
        parts[#parts + 1] = kind .. "=" .. table.concat(report[kind], ",")
    end
    return table.concat(parts, ";")
end

-- 未覆蓋紀錄：哪一題接不住、為什麼。放行標準要的是「逐情境有原因」，所以這裡存原因
-- 而不是只計數；但這份紀錄跟著 VM 活整局，所以有上限，滿了只累加 dropped，不繼續長。
-- 只存自己的 kind／reason／key 這類已授權的字串，不倒任何觀察者的牌面資料進來。
local uncovered, uncovered_dropped = {}, 0
local uncovered_limit = 64

function ai_coverage.notCovered(kind, reason, key)
    if type(kind) ~= "string" or type(reason) ~= "string" then return end
    if #uncovered >= uncovered_limit then
        uncovered_dropped = uncovered_dropped + 1
        return
    end
    uncovered[#uncovered + 1] = {kind = kind, reason = reason,
        key = type(key) == "string" and key or nil}
end

function ai_coverage.uncovered()
    local report = {}
    for index, entry in ipairs(uncovered) do
        report[index] = {kind = entry.kind, reason = entry.reason, key = entry.key}
    end
    return report, uncovered_dropped
end

function ai_coverage.clearUncovered()
    uncovered, uncovered_dropped = {}, 0
end

function ai_coverage.covers(kind, key)
    local report = ai_coverage.describe()
    local keys = report[kind]
    if not keys then return false end
    if key == nil then return #keys > 0 end
    for _, known in ipairs(keys) do
        if known == key then return true end
    end
    return false
end

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
        record_outcome(request.kind, "unhandled")
        return nil
    end
    if type(SmartAIView) ~= "table" or type(SmartAIView.new) ~= "function" then
        return nil
    end
    -- 推演暫存只活在這次決策裡：不寫 Room、不跨 request、不共享給別的觀察者。
    request.scratch = {} -- A reused request starts a fresh decision, too.
    if type(SmartAIView.resetPlanning) == "function" then
        SmartAIView.resetPlanning(request)
    end
    local self_view = SmartAIView.new(request)
    if not self_view then
        record_outcome(request.kind, "invalid_snapshot")
        return nil
    end
    -- 未覆蓋是新版決策缺口：回 nil 並記錄原因，不能當作已處理或合法 pass。
    -- host 的故障保底不屬於策略；錯誤仍往上丟，記成 AI_RUNTIME_ERROR。
    local ok, answer = pcall(handler, self_view, request)
    if not ok and not AIUnsupported.is(answer) then
        record_outcome(request.kind, "error")
        error(answer, 0)
    end
    local covered = not AIUnsupported.is(answer)
    if not covered then
        record_outcome(request.kind, "unsupported")
        ai_coverage.notCovered(request.kind, answer.reason, answer.key)
        return nil
    end
    -- One conversion point for every decision kind: unhandled stays nil, a declined or
    -- explicit pass becomes a pass result, and a malformed answer raises.
    local normalized, result, status = pcall(AIResultValue.normalize, answer, request.kind)
    if not normalized then
        record_outcome(request.kind, "error")
        error(result, 0)
    end
    record_outcome(request.kind, status)
    if status == "unsupported" then
        ai_coverage.notCovered(request.kind, answer.reason, answer.key)
        return nil
    end
    return result
end
