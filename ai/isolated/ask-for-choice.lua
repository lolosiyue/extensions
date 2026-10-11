-- 值型詢問的 registry。每個 decision kind 一張表，鍵是 request 的 reason
-- （技能名或詢問原因）。handler 統一收 (self, options, request)：options 帶候選、
-- 上下限、可取消與預設值，與舊 callback 的 QVariant data 無關，也不共用同一張表。
local function register_handler(handlers, reason, handler)
    if type(reason) ~= "string" or reason == "" or type(handler) ~= "function" then
        error("invalid isolated value decision handler")
    end
    handlers[reason] = handler
end

-- Legacy aliases have a separate ABI; never invoke an old callback with options
-- in the position where SmartAI supplied data, targets, or a count.
ai_choice_legacy_registries = {}
local legacy_by_kind = {}
local response_card_default
local response_answer
local original_single_peach_entry
local original_response_entry
local response_damage_decline
local response_nullfilter
local remember_cardask_targets
local amazing_grace_policy
local pindian_selection
local function legacy_registry(kind, name)
    local values = {}
    legacy_by_kind[kind] = values
    local registry = setmetatable({}, {
        __index = values,
        __newindex = function(_, key, value)
            local t = type(value)
            if type(key) ~= "string" or key == "" or (t ~= "nil" and t ~= "function"
                and t ~= "boolean" and t ~= "number" and t ~= "string" and t ~= "table") then
                error("invalid isolated legacy decision callback")
            end
            values[key] = value
        end
    })
    ai_choice_legacy_registries[name] = registry
    return registry
end

local function decision_context(self, options, request)
    if type(self.getDecisionContext) == "function" then return self:getDecisionContext(request) end
    return options and options.context or {}
end

local function legacy_player(self, value)
    if type(value) == "string" then
        local player = self.room:findPlayerByObjectName(value, true)
        if player then return player end
        if value ~= "" then
            for _, candidate in ipairs(self.room:getPlayers() or {}) do
                if candidate:getGeneralName() == value then return candidate end
            end
        end
        return nil
    end
    return value
end

-- Fixed Original heg-common1483/2459; mode facts are native admission evidence.
local function r35_original(self)
    local facts=self.world and self.world.strategy_facts and self.world.strategy_facts.hegemony
    if type(facts)~='table' or facts.enabled==false then return false end
    if facts.enabled~=true or type(facts.original_overrides_loaded)~='boolean' then
        ai_unsupported('Original provider admission is unknown','Original choice')
    end
    return facts.original_overrides_loaded
end
local function r35_choice_boundary(result)
    if AIUnsupported.is(result)then error(result,0)end
    -- SWIG lua_tostring accepts numbers; nil/boolean/table have no text. The
    -- legacy boundary returns empty QString for those nontext callback values.
    if type(result)=='number'then return tostring(result)end
    if type(result)=='string'and result~=''then return result end
    return {kind='answer',answer='',original_empty_choice=true}
end

local function legacy_call(self, kind, callback, options, request)
    if ai_audited_aliases then callback = ai_audited_aliases.resolve(self, callback) end
    if callback == nil then return nil end
    options = options or {}
    local context = decision_context(self, options, request) or {}
    local targets = AIList.new({})
    for _, name in ipairs(options.players or {}) do
        local target = legacy_player(self, name)
        if target then targets:append(target) end
    end
    -- Explicit typed conversions such as data:toJudge() remain value proxies;
    -- unsupported QVariant operations are intentionally not impersonated.
    local data = type(self.getDecisionData) == "function" and self:getDecisionData()
        or context.data or context
    local result, extra
    if type(callback) ~= "function" then result = callback
    elseif kind == "skill_invoke" then result = callback(self, data)
    elseif kind == "choice" then result = callback(self, table.concat(options.choices or {}, "+"), data)
    elseif kind == "suit" or kind == "kingdom" then result = callback(self)
    elseif kind == "general" then
        local selectable = {}
        for _, name in ipairs(options.choices or {}) do if name:sub(1, 1) ~= "~" then selectable[#selectable + 1] = name end end
        result = callback(self, selectable, options.default_choice)
    elseif kind == "discard" then
        result = callback(self, options.max_count, options.min_count, options.optional,
            context.include_equip == true or context.equiped == true, request.pattern or ".")
    elseif kind == "amazing_grace" then result = callback(self, options.card_ids)
    elseif kind == "card_chosen" then
        result = callback(self, legacy_player(self, context.who or context.target),
            context.flags, context.method or request.handling_method)
    elseif kind == "yiji" then result, extra = callback(self, options.card_ids, targets)
    elseif kind == "player_chosen" then result = callback(self, targets)
    elseif kind == "players_chosen" then result = callback(self, targets, options.max_count, options.min_count)
    elseif kind == "guanxing" then result, extra = callback(self, options.card_ids, tonumber(options.default_choice))
    elseif kind == "trigger_order" then result = callback(self, options.choices, data)
    elseif kind == "askForCard" then
        local parts = {}
        for part in string.gmatch((request.prompt or "") .. ":", "(.-):") do parts[#parts + 1] = part end
        local pattern = (request.pattern or ""):gsub("!$", "")
        remember_cardask_targets(self,request.prompt or "")
        result = callback(self, data, pattern, self.target,
            self.target2, parts[4], parts[5])
    elseif kind == "askForNullification" then
        result = callback(self, context.card, legacy_player(self, context.from),
            legacy_player(self, context.to), context.positive)
    elseif kind == "askForCardShow" then result = callback(self, targets[1])
    elseif kind == "askForSinglePeach" then result = callback(self, targets[1])
    elseif kind == "askForPindian" then
        local cards, high, low = pindian_selection(self, options)
        result = callback(cards[1], self, targets[1], high, low)
    end
    -- Pure policies may return the exact unsupported brand as well as throw it.
    -- Preserve that signal before invoke truthiness or list/default adapters can
    -- reinterpret it. Ordinary donor tables retain their original handling.
    if AIUnsupported and AIUnsupported.is(result)then error(result,0)end
    if kind=="choice" and r35_original(self)then return result end
    if kind == "players_chosen" then
        local seeded, selected, allowed = {}, {}, {}
        for key, value in pairs(options) do seeded[key] = value end
        for _, name in ipairs(options.players or {}) do allowed[name] = true end
        if type(result) == "table" then
            for _, player in ipairs(result) do
                local name = type(player) == "string" and player or player:objectName()
                if allowed[name] then selected[#selected + 1] = name end
            end
            local policy = type(self.getResponsePolicy) == "function" and self:getResponsePolicy() or {}
            if policy.jl_bingfen and math.random() > 0.67 then selected = {} end
            if #selected >= options.min_count then return #selected > 0 and selected or {kind="pass"} end
        end
        seeded.players_seed = selected
        return ai_skill_playerschosen_default(self, seeded, request)
    end
    if kind == "discard" then
        local seeded = {}
        for key, value in pairs(options) do seeded[key] = value end
        if type(result) == "number" then result = {result} end
        if type(result) == "table" and result.kind == nil then
            seeded.discard_seed = {}
            for _, card in ipairs(result) do
                seeded.discard_seed[#seeded.discard_seed + 1] = type(card) == "number" and card or card:getId()
            end
        end
        return ai_skill_discard_default(self, seeded, request)
    end
    if kind == "skill_invoke" and type(callback) ~= "function" and type(callback) ~= "boolean" then
        return ai_skill_invoke_default(self, options)
    end
    -- swig/ai.i:262 uses lua_toboolean after SmartAI:askForSkillInvoke.
    -- Function callbacks may intentionally return a Card, 0, or an empty string;
    -- all are Lua-truthy and are never response payment IDs.
    if kind == "skill_invoke" and type(callback) == "function" then return not not result end
    if result == nil then return nil end
    if kind == "general" then
        if type(result) ~= "string" or result == "" or result:sub(1, 1) == "~" then return nil end
        for _, name in ipairs(options.choices or {}) do if name == result then return result end end
        return nil
    end
    -- SmartAI:askForChoice accepts only string callback results. Numeric
    -- results reach its random default before the outer lua_tostring boundary.
    if kind == "choice" and type(result) ~= "string" then return nil end
    if kind == "suit" and type(result) ~= "number" then return nil end
    if kind == "amazing_grace" then
        if type(result) ~= "number" then return nil end
        local valid = false
        for _, id in ipairs(options.card_ids or {}) do if result == id then valid = true break end end
        if not valid then return options.optional and {kind="pass"} or nil end
    end
    if kind == "card_chosen" then
        if type(result) == "table" and type(result.getEffectiveId) == "function" then result = result:getEffectiveId() end
        if type(result) == "number" then
            for _, id in ipairs(options.card_ids or {}) do if id == result then return result end end
            return nil
        end
    end
    if kind == "askForNullification" and type(result) == "boolean" then
        if result then return response_card_default(self, options, request) end
        return {kind="pass"}
    end
    if kind == "suit" and type(result) == "number" then
        return ({[0]="spade", "club", "heart", "diamond", "no_suit"})[result]
    end
    if kind == "yiji" then
        local valid = false
        for _, id in ipairs(options.card_ids or {}) do if id == extra then valid = true end end
        if not result or not valid then return nil end
        local name = type(result)=="string" and result or result:objectName()
        for _, offered_name in ipairs(options.players or {}) do
            if name == offered_name then return {kind="answer", cards={extra}, targets={name}} end
        end
        return nil
    end
    if kind == "guanxing" and type(result) == "table" then
        return {kind="answer", cards=result, bottom_cards=extra or {}}
    end
    if kind == "player_chosen" then
        -- The donor accepts only a Player userdata contained in targets.
        -- Strings, Card views and arbitrary objectName tables are not players.
        if AIValue.isPlayer(result) then
            local name = result:objectName()
            for _, offered_name in ipairs(options.players or {}) do
                if name == offered_name then return name end
            end
        end
        return nil
    end
    if type(result) == "table" and (type(result.toCardSpec) == "function"
        or AIValue and AIValue.isCard(result))
        and (kind == "askForCard" or kind == "askForSinglePeach") then
        return response_answer(self,result,options) or {kind="pass"}
    end
    if type(result) == "table" and type(result.getEffectiveId) == "function" then return result:getEffectiveId() end
    -- These legacy callbacks accept only truthy card/player results. False means
    -- continue with the shared policy, unlike cardask's explicit refusal.
    if result == false and (kind == "askForPindian" or kind == "askForCardShow"
        or kind == "card_chosen" or kind == "player_chosen") then return nil end
    if kind == "players_chosen" or kind == "discard" then
        if type(result) == "number" and kind == "discard" then return {result} end
        if type(result) == "table" and result.kind == nil then
            local values = {}
            for _, value in ipairs(result) do
                values[#values + 1] = type(value) == "table" and
                    (kind == "discard" and value:getEffectiveId() or value:objectName()) or value
            end
            return #values == 0 and {kind="pass"} or values
        end
    end
    if result == "." or result == -1 then return {kind="pass"} end
    if kind == "askForCard" or kind == "askForSinglePeach" or kind == "askForCardShow"
        or kind == "askForPindian" then
        if type(result) == "string" then
            if kind=="askForCard" and context.aggregate_response=="axe"
                and result:match("^%$%d+%+%d+$") then
                local first,second=result:match("^%$(%d+)%+(%d+)$")
                first,second=tonumber(first),tonumber(second)
                if first==second then ai_unsupported("Axe repeated a discard cost","@axe") end
                return {kind="answer",cards={first,second}}
            end
            local id = result:match("^%$?(%d+)$")
            if not id then
                ai_unsupported("legacy converted response requires an authorized card spec", kind)
            end
            return tonumber(id)
        end
    end
    return result
end

local function inquiry_personality(self)
    if type(self.getResponsePolicy) == "function" then return self:getResponsePolicy() or {} end
    return {jl_bingfen=sgs.jl_bingfen == true}
end

local function finish_registry(self, kind, result)
    if kind == "skill_invoke" then
        local policy = inquiry_personality(self)
        if policy.jl_bingfen and math.random() > 0.8 then
            local present = policy.bingfen_invoke_lines_present
            if type(present) ~= "boolean" then ai_unsupported("invoke speech presence is unknown", kind) end
            if present and math.random() > 0.6 then
                local lines = policy.bingfen_invoke_lines
                if type(lines) ~= "table" then ai_unsupported("invoke speech lines are unknown", kind) end
                self:emitSpeechLine(self.player, lines[math.random(1, #lines)], "personality:skill_invoke")
            end
            self:setPersonalityTarget()
            result = not result
        end
    end
    return result
end

-- Native captures audited literal aliases once, before any AI callback runs.
-- The value VM never reads the donor registry or treats function presence as
-- proof that a package's optional alias existed in that actual load order.
ai_audited_aliases = ai_audited_aliases or {}
local audited_alias_callbacks = setmetatable({}, {__mode="k"})
local function alias_path(table_value, path)
    for _, key in ipairs(path) do
        if type(table_value) ~= "table" then return nil end
        table_value = table_value[key]
    end
    return table_value
end
function ai_audited_aliases.resolve(self, callback)
    local binding = audited_alias_callbacks[callback]
    if not binding then return callback end
    local facts = self and self.world and self.world.strategy_facts
    local snapshot = facts and facts.audited_aliases
    local row = snapshot and snapshot.entries and snapshot.entries[binding.id]
    if type(snapshot) ~= "table" or snapshot.captured ~= true or type(row) ~= "table" or row.known ~= true then
        ai_unsupported("audited alias identity is unknown", binding.id)
    end
    if row.present == false then return nil end
    if row.present ~= true or row.enabled ~= true or row.matched ~= true or row.source_matches ~= true
        or row.registry ~= binding.registry or row.canonical_registry ~= binding.canonical_registry then
        ai_unsupported("audited alias is present without matching source identity", binding.id)
    end
    for _, key in ipairs{"path", "canonical_path"} do
        local expected, actual = binding[key], row[key]
        if type(actual) ~= "table" or #actual ~= #expected then ai_unsupported("audited alias path differs", binding.id) end
        for i, value in ipairs(expected) do if actual[i] ~= value then ai_unsupported("audited alias path differs", binding.id) end end
    end
    local callback = binding.callback
    if binding.defer_canonical then callback = alias_path(sgs[binding.canonical_registry], binding.canonical_path) end
    if type(callback) ~= "function" then ai_unsupported("audited alias canonical policy is unavailable", binding.id) end
    return callback
end
function ai_audited_aliases.register(binding)
    local canonical = alias_path(sgs[binding.canonical_registry], binding.canonical_path)
    if type(canonical) ~= "function" and not binding.defer_canonical then ai_unsupported("audited alias canonical policy is unavailable", binding.id) end
    local registry = sgs[binding.registry]
    for i=1,#binding.path-1 do registry=registry[binding.path[i]] end
    -- A specific already-ported policy has priority over a generic alias bridge.
    if registry[binding.path[#binding.path]] ~= nil then return end
    binding.callback = canonical
    local wrapper
    wrapper = function(...)
        local arguments = table.pack(...)
        local self = arguments[binding.self_index or 1]
        if not (type(self) == "table" and self.world) then
            -- A few cardneed callers omit the third AI argument. Their player
            -- belongs to this same value room; never retrieve a different AI.
            local player = arguments[1]
            local room = AIValue.isPlayer(player) and player:getRoom() or nil
            self = room and room._ai or nil
        end
        local callback = ai_audited_aliases.resolve(self, wrapper)
        if callback then return callback(table.unpack(arguments, 1, arguments.n)) end
    end
    audited_alias_callbacks[wrapper] = binding
    registry[binding.path[#binding.path]] = wrapper
end

local function make_registry(kind, default_name, name)
    local handlers = {}
    legacy_registry(kind, name)
    if type(ai_coverage) == "table" then
        ai_coverage.declare(kind, function()
            local keys = {}
            for key in pairs(handlers) do keys[#keys + 1] = key end
            for key in pairs(legacy_by_kind[kind]) do keys[#keys + 1] = "legacy:" .. key end
            return keys
        end)
    end
    ai_register_handler(kind, function(self, request)
        local options = type(request.options) == "table" and request.options or nil
        local reason = options and options.reason
        -- Original asks own the full callback/default algorithm. This route is
        -- before typed reason handlers/personality gates, not a second callback.
        local original = self.world and self.world.strategy_facts and self.world.strategy_facts.hegemony
        if original and original.enabled == true and original.original_overrides_loaded == true
            and (kind=='discard'or kind=='suit'or kind=='player_chosen'or kind=='yiji') then
            if kind=='discard'then
                return finish_registry(self,kind,ai_skill_discard_default(self,options,request))
            end
            if type(options)~='table'then return ai_unsupported('Original ask options missing',kind)end
            if kind=='suit'then
                local ok,value=pcall(self.askForSuit,self,reason)
                if AIUnsupported.is(value)then error(value,0)end
                if type(ai_original_suit_result)~='function'then ai_unsupported('Original Suit native result bridge unavailable',kind)end
                local result=ai_original_suit_result(value,not ok)
                if type(result)~='table'or result.kind~='original_suit_result'or type(result.value)~='number'then
                    ai_unsupported(type(result)=='table'and result.error or'Original Suit result unknown',kind)
                end
                return finish_registry(self,kind,{kind='answer',original_suit_value=result.value})
            end
            if not AIValue.isList(options.players)then
                return ai_unsupported('Original ask target domain unknown',kind)
            end
            local targets=AIList.new({})
            for _,name in ipairs(options.players)do
                local player=self.room:findPlayerByObjectName(name,true)
                if not player then return ai_unsupported('Original offered player is unknown',kind)end
                targets:append(player)
            end
            if kind=='player_chosen'then
                local selected=self:askForPlayerChosen(targets,reason)
                if AIUnsupported.is(selected)then error(selected,0)end
                if selected==nil then return finish_registry(self,kind,{kind='pass'})end
                if not AIValue.isPlayer(selected)or not targets:contains(selected)then
                    return ai_unsupported('Original player selection is outside the native domain',kind)
                end
                return finish_registry(self,kind,selected:objectName())
            end
            if options.candidates_complete~=true or not AIValue.isList(options.card_ids)then return ai_unsupported('Original Yiji card domain unknown',kind)end
            local selected,id=self:askForYiji(options.card_ids,reason)
            if AIUnsupported.is(selected)then error(selected,0)end
            if AIUnsupported.is(id)then error(id,0)end
            if selected==nil then return finish_registry(self,kind,{kind='pass'})end
            if not AIValue.isPlayer(selected)or not targets:contains(selected)then return ai_unsupported('Original Yiji target outside native domain',kind)end
            local found=false;for _,offered in ipairs(options.card_ids)do if id==offered then found=true;break end end
            if not found then return ai_unsupported('Original Yiji card outside native domain',kind)end
            return finish_registry(self,kind,{kind='answer',cards={id},targets={selected:objectName()}})
        end

        if r35_original(self) and (kind=='skill_invoke'or kind=='card_chosen')then
            if type(options)~='table'then ai_unsupported('Original ask options missing',kind)end
            if kind=='skill_invoke'then
                local data=type(self.getDecisionData)=='function'and self:getDecisionData()or decision_context(self,options,request)
                local answer=self:askForSkillInvoke(reason,data)
                if AIUnsupported.is(answer)then error(answer,0)end
                -- SWIG lua_toboolean converts the source's absent/nonfrequent nil to false.
                return finish_registry(self,kind,answer==true)
            end
            local context=decision_context(self,options,request)
            local who=legacy_player(self,context.who or context.target)
            if not who or type(context.flags)~='string'or type(context.method)~='number'then
                ai_unsupported('Original card choice inquiry incomplete',kind)
            end
            local answer=self:askForCardChosen(who,context.flags,reason,context.method)
            if AIUnsupported.is(answer)then error(answer,0)end
            if type(answer)=='table'and answer.kind=='answer'and answer.random_card_choice then
                return finish_registry(self,kind,answer)
            end
            if type(answer)~='number'then ai_unsupported('Original card choice nonnumeric result',kind)end
            if type(ai_original_cardchosen_result)~='function'then ai_unsupported('Original numeric result boundary unavailable',kind)end
            answer=ai_original_cardchosen_result(answer)
            if answer<0 then return finish_registry(self,kind,{kind='pass'})end
            return finish_registry(self,kind,answer)
        end

        -- SmartAI exits an empty AG domain before invoking any reason hook.
        if kind == "amazing_grace" and options and options.candidates_complete == true
            and type(options.card_ids) == "table" and #options.card_ids == 0 then
            return {kind="pass"}
        end
        if kind == "player_chosen" and inquiry_personality(self).jl_bingfen and math.random() > 0.67 then
            return ai_skill_playerchosen_default(self, options, request)
        end
        if kind == "card_chosen" then
            -- SmartAI refreshes this viewer-owned cache before any skill or
            -- reason callback. Later play planning reuses the last refresh.
            if type(self.refreshDiscardPreferences) ~= "function" then
                return ai_unsupported("card-chosen preference refresh is unavailable", kind)
            end
            self:refreshDiscardPreferences()
            local context = decision_context(self, options, request) or {}
            local method = context.method
            if method == nil then method = request.handling_method end
            if type(method) ~= "number" then return ai_unsupported("card-chosen handling method is unknown", kind) end
            if method == sgs.Card_MethodDiscard then
                self:recordDiscardDemand(reason, 1)
            end
            local who = legacy_player(self, context.who or context.target)
            local skills = who and who:getSkills()
            if skills == nil then return ai_unsupported("card-chosen target skills are unknown", kind) end
            for _, skill in ipairs(skills) do
                local key = "#" .. skill:objectName()
                local skill_handler, callback = handlers[key], legacy_by_kind[kind][key]
                local answer
                if skill_handler then answer = skill_handler(self, options, request) end
                if answer == nil and type(callback) == "function" then
                    answer = legacy_call(self, kind, callback, options, request)
                end
                if answer ~= nil then
                    if type(answer) == "number" then
                        for _, id in ipairs(options.card_ids or {}) do if answer == id then return answer end end
                        return ai_unsupported("card-chosen skill selected an unoffered card", key)
                    end
                    return answer
                end
            end
        end
        if kind == "general" then
            local selectable = false
            for _, general in ipairs(options and options.choices or {}) do
                if general:sub(1, 1) ~= "~" then selectable = true break end
            end
            -- The donor exits before consulting any reason hook when the
            -- selectable list is empty, so callbacks must not consume RNG here.
            if not selectable or reason == "for_lord" then return ai_general_choice_default(self, options, request) end
        end
        if kind=="choice" and (reason=="jilve" or reason=="heg_tianxiang") and type(self.getStrategyMemory)=="function" then
            local override,present=self:getStrategyMemory("choice_override:"..reason)
            if present and type(override)=="string" then
                for _,choice in ipairs(options.choices or {}) do if choice==override then return override end end
            end
        end
        local handler = type(reason) == "string" and handlers[reason] or nil
        if handler then
            local result = handler(self, options, request)
            if result ~= nil then return finish_registry(self, kind, result) end
        end
        if kind == "discard" then
            -- The shared donor body owns callback dispatch, keep assignment and
            -- throw-data timing. Do not invoke its callback a second time here.
            return finish_registry(self, kind, ai_skill_discard_default(self, options, request))
        end
        local legacy = legacy_by_kind[kind]
        local callback
        local legacy_key = reason
        if type(reason) == "string" and (kind == "skill_invoke" or kind == "amazing_grace"
            or kind == "card_chosen" or kind == "yiji" or kind == "player_chosen") then
            legacy_key = reason:gsub("%-", "_")
        end
        if type(legacy_key) == "string" then callback = legacy[legacy_key] end
        callback = ai_audited_aliases.resolve(self, callback)
        if kind=="choice" and r35_original(self)then
            if type(callback)=='string' or type(callback)=='function'then
                return r35_choice_boundary(legacy_call(self,kind,callback,options,request))
            end
            if callback==nil and options.context and options.context.legacy_hook==true then
                return ai_unsupported('reason-specific Original choice policy is not ported',reason)
            end
            return ai_skill_choice_default(self,options,request)
        end
        if kind == "card_chosen" and type(callback) == "number" then legacy[legacy_key] = nil end
        if callback ~= nil then
            local result
            if kind=='skill_invoke' and reason=='lianli-slash' then
                -- The source SmartAI callback protects the entire invocation.
                -- Its ordinary error skips the later personality RNG and is
                -- converted from nil to native false, without legacy fallback.
                local ok,value=pcall(legacy_call,self,kind,callback,options,request)
                if AIUnsupported.is(value)then error(value,0)end
                if not ok then
                    if type(value)~='string' or type(ai_lianli_cardask_error)~='function'then
                        ai_unsupported('Lianli source error diagnostic is unavailable','lianli.source_error')
                    end
                    local reported=ai_lianli_cardask_error(value)
                    if AIUnsupported.is(reported)then error(reported,0)end
                    if type(reported)~='table' or reported.kind~='lianli_source_error'
                        or reported.error_class~='ordinary_lua_error' or reported.message~=value
                        or reported.invoke~=false then
                        ai_unsupported('Lianli source error diagnostic rejected','lianli.source_error')
                    end
                    return false
                end
                result=value
            else result = legacy_call(self, kind, callback, options, request) end
            if kind=="card_chosen" and type(result)=="number" then
                -- Source reason callbacks (unlike #skill hooks) fall through
                -- when their selected ID occurs in the refreshed disabled set.
                for _,id in ipairs(self.disabled_ids or {})do
                    if id==result then result=nil;break end
                end
            end
            if result ~= nil then return finish_registry(self, kind, result) end
        end
        -- 理由專用策略優先；共用預設仍可明確回 nil，表示這題未覆蓋。
        -- SmartAI 有此理由的 hook 時（C++ 標 legacy_hook），共用預設讓位給它。
        if callback == nil and options and type(options.context) == "table"
            and options.context.legacy_hook == true then
            return ai_unsupported("reason-specific legacy policy is not ported", reason)
        end
        local fallback = default_name and _G[default_name]
        if type(fallback) == "function" then return finish_registry(self, kind, fallback(self, options, request)) end
        return nil
    end)
    return setmetatable({}, {
        __index = handlers,
        __newindex = function(_, reason, handler)
            register_handler(handlers, reason, handler)
        end
    })
end

ai_skill_invoke = make_registry("skill_invoke", "ai_skill_invoke_default", "ai_skill_invoke")
ai_skill_choice = make_registry("choice", "ai_skill_choice_default", "ai_skill_choice")
ai_skill_suit = make_registry("suit", "ai_skill_suit_default", "ai_skill_suit")
ai_skill_kingdom = make_registry("kingdom", "ai_skill_kingdom_default", "ai_skill_kingdom")
ai_general_choice = make_registry("general", "ai_general_choice_default", "ai_general_choice")

-- 選牌與選人族沿用同一種註冊形狀；候選在 options.card_ids／options.players。
ai_skill_discard = make_registry("discard", "ai_skill_discard_default", "ai_skill_discard")
ai_skill_askforag = make_registry("amazing_grace", "ai_skill_askforag_default", "ai_skill_askforag")
ai_skill_cardchosen = make_registry("card_chosen", "ai_skill_cardchosen_default", "ai_skill_cardchosen")
ai_skill_askforyiji = make_registry("yiji", "ai_skill_askforyiji_default", "ai_skill_askforyiji")
ai_skill_playerchosen = make_registry("player_chosen", "ai_skill_playerchosen_default", "ai_skill_playerchosen")
ai_skill_playerschosen = make_registry("players_chosen", "ai_skill_playerschosen_default", "ai_skill_playerschosen")
ai_skill_guanxing = make_registry("guanxing", "ai_skill_guanxing_default", "ai_skill_guanxing")
ai_skill_triggerorder = make_registry("trigger_order", "ai_skill_triggerorder_default", "ai_skill_triggerorder")

-- 回應牌族共用 respond_card 一種 kind，所以再用 options.question 分辨是哪個詢問；
-- 實體答案使用 ID；轉化答案攜帶權威 conversion ticket，不以合成 ID 冒充實體牌。
local respond_handlers = {}
local respond_defaults = {}

ai_register_handler("respond_card", function(self, request)
    local options = type(request.options) == "table" and request.options or nil
    local question = options and options.question
    local original=self.world and self.world.strategy_facts and self.world.strategy_facts.hegemony
    if original and original.enabled==true and original.original_overrides_loaded==true
        and question=="askForSinglePeach"then return original_single_peach_entry(self,options,request)end
    if original and original.enabled==true and original.original_overrides_loaded==true
        and (question=="askForCard" or question=="askForNullification") then
        return original_response_entry(self,options,request,question)
    end
    if question == "askForNullification" then return respond_defaults.askForNullification(self, options, request) end
    if question == "askForCard" then
        if response_damage_decline(self, options, request)then return {kind="pass"}end
        remember_cardask_targets(self,request.prompt or "")
    end
    -- The initiating side's stored card precedes a reason callback in SmartAI.
    if question == "askForPindian" and options.players and options.players[1] == self.player:objectName()
        and not string.find("mizhao|lieren", options.reason or "") then
        return respond_defaults.askForPindian(self, options, request)
    end
    local forced = false
    local handlers = type(question) == "string" and respond_handlers[question] or nil
    local keys = {}
    if question == "askForCard" then
        -- Explicit pattern policies precede prompt-specific policies. Keep the
        -- original trailing ! as the registry key but strip it for legacy ABI.
        keys[#keys + 1] = request.pattern or ""
        keys[#keys + 1] = (request.prompt or ""):match("^[^:]*") or ""
    elseif question == "askForNullification" then
        local context = decision_context(self, options, request)
        local card = context and context.card
        if card and type(card.getClassName) == "function" then
            keys[#keys + 1] = card:getClassName() or ""
        end
    end
    keys[#keys + 1] = options and options.reason or ""
    local seen = {}
    for _, key in ipairs(keys) do
        if key ~= "" and not seen[key] then
            seen[key] = true
            local handler = handlers and handlers[key]
            local result
            if handler then result = handler(self, options, request) end
            if result == nil then
                local legacy = legacy_by_kind[question]
                local callback = legacy and legacy[key]
                -- SmartAI cardask uses the prompt key; pattern-specific new ABI
                -- policies are separate and must not invent a legacy lookup.
                if question == "askForCard" and key ~= ((request.prompt or ""):match("^[^:]*") or "") then callback = nil end
                -- Pindian owns one selection/sort/callback/fallback sequence;
                -- dispatching its legacy hook here would recompute that sequence
                -- after a nil/false result and lose callback side effects.
                if callback ~= nil and question ~= "askForPindian" then
                    result = legacy_call(self, question, callback, options, request)
                end
            end
            if question == "askForCard" and type(result) == "boolean" then
                if result then forced = true
                elseif not forced and (request.pattern or ""):sub(-1) ~= "!" then return {kind="pass"} end
                result = nil
            end
            local compulsory = question == "askForCard" and (forced or (request.pattern or ""):sub(-1) == "!")
            local declined = result == "." or (type(result) == "table" and result.kind == "pass")
            if question == "askForCard" and type(result) == "number" then
                local offered = false
                for _, id in ipairs(options.card_ids or {}) do if id == result then offered = true break end end
                if not offered then
                    if not compulsory then return {kind="pass"} end
                    result = nil
                end
            end
            if result ~= nil and not (compulsory and declined) then return result end
        end
    end
    if forced and (request.pattern or ""):sub(-1) ~= "!" then
        local forced_request = {}
        for key, value in pairs(request) do forced_request[key] = value end
        forced_request.response_compulsory = true
        request = forced_request
    end
    local fallback = type(question) == "string" and respond_defaults[question] or nil
    if type(fallback) == "function" then return fallback(self, options, request) end
    return nil
end)

local function respond_registry(question, name)
    local handlers = {}
    legacy_registry(question, name)
    if type(ai_coverage) == "table" then
        ai_coverage.declare("respond_card", function()
            local keys = {}
            for key in pairs(handlers) do keys[#keys + 1] = question .. ":" .. key end
            for key in pairs(legacy_by_kind[question]) do keys[#keys + 1] = question .. ":legacy:" .. key end
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

ai_skill_cardask = respond_registry("askForCard", "ai_skill_cardask")
ai_nullification = respond_registry("askForNullification", "ai_nullification")
ai_cardshow = respond_registry("askForCardShow", "ai_cardshow")
ai_skill_pindian = respond_registry("askForPindian", "ai_skill_pindian")
ai_skill_singlepeach = respond_registry("askForSinglePeach", "ai_skill_singlepeach")

-- Default values deliberately use only the request's offered values and the viewer's
-- visible cards.  An absent value is unknown, never a reason to inspect another hand.
local function offered(options, field)
    local values = options and options[field]
    return type(values) == "table" and #values > 0 and values or nil
end

local function unsupported(reason, key)
    if type(ai_unsupported) == "function" then ai_unsupported(reason, key) end
    return nil
end

local function finite_number(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function note_unknown(kind, signal)
    if signal and type(ai_coverage) == "table" then
        ai_coverage.notCovered(kind, signal.reason, signal.key)
    end
end

local function valid_choice(values, wanted)
    if type(wanted) == "string" and wanted ~= "" then
        for _, value in ipairs(values) do if value == wanted then return wanted end end
    end
    return values[1]
end

local function card_index(self, options)
    local index = {}
    if type(self) ~= "table" or not self.player then return index end
    if type(self.getChoiceCard) == "function" then
        index._facade = true
    end
    for _, card in ipairs(options and options.cards or {}) do
        if type(card) == "table" and (card.id ~= nil or card.effective_id ~= nil) then
            index[card.effective_id or card.id] = CardView.new(card)
        end
    end
    local cards = self.player:getCards("he")
    if cards then
        for _, card in ipairs(cards) do index[card:getEffectiveId()] = index[card:getEffectiveId()] or card end
    end
    local discard = self.room and self.room:getDiscardCards()
    if discard then
        for _, card in ipairs(discard) do index[card:getEffectiveId()] = index[card:getEffectiveId()] or card end
    end
    return index
end

local function known_cards(self, ids, options)
    local index = card_index(self, options)
    local result = {}
    for _, id in ipairs(ids or {}) do
        local card = index[id]
        if index._facade and type(self.getChoiceCard) == "function" then
            card = self:getChoiceCard(id, options) or card
        end
        if not card then return nil end
        result[#result + 1] = card
    end
    return result
end

local function lowest_keep(self, ids, options)
    local cards = known_cards(self, ids, options)
    if not cards then return nil end
    local best, best_value, best_id
    for _, card in ipairs(cards) do
        local value, id = self:getKeepValue(card), card:getEffectiveId()
        if not best or value < best_value or (value == best_value and id < best_id) then
            best, best_value, best_id = card, value, id
        end
    end
    return best_id
end

local function default_choice(self, options)
    local choices = offered(options, "choices")
    return choices and valid_choice(choices, options.default_choice) or nil
end
ai_skill_invoke_default = ai_skill_invoke_default or function(self, options)
    local frequency = options and options.context and options.context.skill_frequency
    -- Native uses -1 for a known missing skill. Missing metadata is unknown,
    -- not evidence that the donor no-hook rule would decline.
    if not finite_number(frequency) then
        return unsupported("invoke skill frequency is unknown", "skill_invoke")
    end
    return frequency == sgs.Skill_Frequent
end
ai_skill_choice_default = ai_skill_choice_default or function(self, options)
    local choices = offered(options, "choices")
    if not choices then return nil end
    if r35_original(self)then
        local allowed={};for _,choice in ipairs(choices)do allowed[#allowed+1]=choice end
        for index,choice in ipairs(allowed)do
            if choice=='heg_benghuai'then table.remove(allowed,index);break end
        end
        return allowed[math.random(1,#allowed)]
    end
    local allowed, removed = {}, false
    for _, choice in ipairs(choices) do
        if choice == "benghuai" and not removed then removed = true
        else allowed[#allowed + 1] = choice end
    end
    -- table.removeOne removes only the first occurrence. The sole-benghuai
    -- donor error has an explicitly authorized, audited repair: choose the
    -- only legal answer without making an invalid RNG call.
    if #allowed == 0 then
        if type(self.useKnowledgeEstimate) ~= "function" then
            return unsupported("choice error repair requires a knowledge audit", "choice")
        end
        return self:useKnowledgeEstimate({value=choices[1], status="estimate",
            basis="donor_error_repair:sole_benghuai_empty_random_domain",
            viewer=self.player:objectName()}, "choice.donor_error_repair")
    end
    return allowed[math.random(1, #allowed)]
end
ai_skill_suit_default = ai_skill_suit_default or function(self, options)
    local callback = legacy_by_kind.suit.nosfanjian
    if type(callback) == "function" then
        return legacy_call(self, "suit", callback, options, self.request or {})
    end
    local choices = offered(options, "choices")
    if not choices then return nil end
    local allowed, weighted = {}, {}
    for _, suit in ipairs(choices) do allowed[suit] = true end
    -- Original nosfanjian fallback weights, restricted to authority-offered suits.
    for _, suit in ipairs({"spade", "spade", "club", "heart", "heart", "diamond", "diamond", "diamond"}) do
        if allowed[suit] then weighted[#weighted + 1] = suit end
    end
    if #weighted == 0 then return choices[math.random(1, #choices)] end
    local selected = weighted[math.random(1, #weighted)]
    local current, counts, best_count, best = self.room:getCurrent(), {}, 0, nil
    -- Known cards are already viewer-redacted; never enumerate a hidden hand.
    for _, card in ipairs(current and current:getKnownCards() or {}) do
        local suit = card:getSuitString()
        if allowed[suit] then
            counts[suit] = (counts[suit] or 0) + 1
            if counts[suit] > best_count then best, best_count = suit, counts[suit] end
        end
    end
    if self.player:hasSkill("hongyan") and allowed.heart
        and (best == "spade" or selected == "spade") then return "heart" end
    return best or selected
end
ai_skill_kingdom_default = ai_skill_kingdom_default or default_choice
sgs.ai_general_choice_for_lord = sgs.ai_general_choice_for_lord or {}
function hp_loss_lord_strategy_scores(ai, generals, lord, prefer_same_kingdom)
    local options = ai.request and ai.request.options or {}
    local context = options.context or {}
    local catalog = context.general_catalog
    if type(catalog) ~= "table" then return unsupported("general catalog is not projected", "general") end
    local role = ai.player:getRole()
    if type(role) ~= "string" then return unsupported("owner role is unknown", "general") end
    local lord_kingdom = ""
    if lord then
        local projected_lord = ai.room:getLord()
        if not projected_lord or projected_lord:objectName() ~= lord:objectName()
            or type(context.lord_general_kingdom) ~= "string" then
            return unsupported("requested lord general kingdom is unknown", "general")
        end
        lord_kingdom = context.lord_general_kingdom
    end
    local scores = {}
    for _, name in ipairs(generals) do
        local row, score = catalog[name], 0
        if type(row) ~= "table" or type(row.exists) ~= "boolean" then return unsupported("general existence is unknown", "general") end
        if row.exists then
            if type(row.kingdom) ~= "string" or type(row.skill_description) ~= "string" then
                return unsupported("public general skill description/kingdom is unknown", "general")
            end
            local description = row.skill_description
            if role == "rebel" then
                if description:find("体力流失") then score = score + 8 end
                if description:find("失去") and description:find("体力") then score = score + 6 end
            elseif role == "loyalist" then
                if description:find("回复") and description:find("体力") then score = score + 8 end
                if description:find("造成过") then score = score + 5 end
                if description:find("桃") then score = score + 4 end
                if description:find("受到伤害") then score = score - 6 end
            end
            if prefer_same_kingdom and (row.kingdom == lord_kingdom or row.kingdom == "god") and role == "loyalist" then
                score = score + 5
            end
            local strategy = legacy_by_kind.general[name]
            if type(strategy) == "function" then
                local recommend = strategy(ai, lord, role)
                if recommend == 1 then score = score + 12 elseif recommend == -1 then score = score - 12 end
            end
        end
        scores[#scores + 1] = {name=name, score=score}
    end
    return scores
end

function select_best_general(scores, default)
    if not scores or #scores == 0 then return default end
    table.sort(scores, function(a, b) return a.score > b.score end)
    local best_score, best = scores[1] and scores[1].score or 0, {}
    for _, row in ipairs(scores) do
        if row.score ~= best_score then break end
        best[#best + 1] = row.name
    end
    if #best > 0 then return best[math.random(1, #best)] end
    return default
end

ai_general_choice_default = ai_general_choice_default or function(self, options)
    local choices = offered(options, "choices") or {}
    local selectable = {}
    for _, name in ipairs(choices) do if name:sub(1, 1) ~= "~" then selectable[#selectable + 1] = name end end
    if #selectable == 0 then
        local context = options and options.context or {}
        if type(context.empty_general_fallback) == "string" and context.empty_general_fallback ~= "" then
            return context.empty_general_fallback
        end
        -- LuaAI's empty-default wrapper uses gameplay RNG. Return its request
        -- capability without consuming this VM's independent decision RNG.
        local token = context.empty_general_random_token
        if (options.default_choice == nil or options.default_choice == "")
            and type(token) == "string" and token:match("^isolated%-default%-general:") then
            return token
        end
        local fallback = options and options.default_choice or "caocao"
        for _, name in ipairs(choices) do if name == fallback then return fallback end end
        return unsupported("legacy no-general fallback is outside offered choices", "general")
    end
    if options.reason == "for_lord" then
        local lord = self.room:getLord()
        if not lord then return selectable[math.random(1, #selectable)] end
        local callback = sgs.ai_general_choice_for_lord[lord:getGeneralName()]
        local choice = callback
        if type(callback) == "function" then choice = callback(self, selectable, options.default_choice, lord) end
        if type(choice) == "string" and choice ~= "" then
            for _, name in ipairs(selectable) do if name == choice then return choice end end
        end
        local catalog = options.context and options.context.general_catalog
        if type(catalog) ~= "table" then return unsupported("general catalog is not projected", "general") end
        local role, lord_kingdom = self.player:getRole(), options.context.lord_general_kingdom
        if role == nil or type(lord_kingdom) ~= "string" then return unsupported("lord-general role/kingdom is unknown", "general") end
        local best, best_score
        for _, name in ipairs(selectable) do
            local row = catalog[name]
            if type(row) ~= "table" or type(row.exists) ~= "boolean" then return unsupported("general existence is unknown", "general") end
            local score = 0
            if row.exists then
                if type(row.kingdom) ~= "string" then return unsupported("general kingdom is unknown", "general") end
                if role == "loyalist" and lord_kingdom ~= "" and (row.kingdom == lord_kingdom or row.kingdom == "god") then score = score + 5 end
                local strategy = legacy_by_kind.general[name]
                if type(strategy) == "function" then
                    local recommend = strategy(self, lord, role)
                    if recommend == 1 then score = score + 10 elseif recommend == -1 then score = score - 10 end
                end
            end
            if best_score == nil or score > best_score then best, best_score = name, score end
        end
        return best
    end
    for _, name in ipairs(selectable) do if name == options.default_choice then return name end end
    return selectable[math.random(1, #selectable)]
end

-- Read-only default selection for nested skill planners. This does not invent an
-- inquiry or an offered domain; the eventual action still needs native costs.
function SmartAIView:recommendDiscard(max_count,min_count,optional,equiped)
    local function require_value(value,key)
        if value==nil then ai_unsupported("nested discard input is unknown",key) end
        return value
    end
    local exchange=require_value(self.player:hasFlag("Global_AIDiscardExchanging"),"exchange")
    local chosen,seen={},{}
    local function append(card)
        local id=require_value(card:getId(),"discard ID")
        if not seen[id] then chosen[#chosen+1]=id;seen[id]=true end
    end
    if optional and equiped then
        for _,card in ipairs(require_value(self:poisonCards("e"),"poison equipment"))do
            if exchange or require_value(self.player:canDiscard(self.player,card:getId()),"can discard")then append(card)end
            if #chosen>=max_count then break end
        end
    end
    if #chosen<min_count then
        if optional then return {}end
        local cards=require_value(self.player:getCards(equiped and "he"or"h"),"owner discard cards")
        if exchange then
            for _,card in ipairs(require_value(self:poisonCards(cards),"exchange poison"))do
                if #chosen<min_count then append(card)end
            end
        end
        local deferred={}
        for _,card in ipairs(require_value(self:sortByKeepValue(cards,nil,not exchange and "j"),"discard order"))do
            if #chosen>=min_count or seen[card:getId()]then continue end
            if require_value(self.player:hasEquip(card),"equipment membership")
                and require_value(self:loseEquipEffect(),"equipment loss")
                or require_value(self:getUseValue(card),"discard use value")<6 then append(card)
            else deferred[#deferred+1]=card end
        end
        for _,card in ipairs(deferred)do if #chosen<min_count then append(card)end end
    end
    return chosen
end

ai_skill_discard_default = ai_skill_discard_default or function(self, options, request)
    request = request or self.request
    if type(options) ~= 'table' or options.candidates_complete ~= true
        or not AIValue.isList(options.card_ids) then
        return unsupported('discard candidate completeness is unknown', 'discard')
    end
    local context = options.context or {}
    local include_equip = context.include_equip
    if include_equip == nil then include_equip = context.equiped end
    if type(include_equip) ~= 'boolean' or type(options.optional) ~= 'boolean'
        or type(options.reason) ~= 'string' or not request then
        return unsupported('discard request inputs are incomplete', 'discard')
    end
    local minimum, maximum = options.min_count, options.max_count
    if not finite_number(minimum) or not finite_number(maximum)
        or minimum < 0 or minimum % 1 ~= 0 or maximum < minimum or maximum % 1 ~= 0 then
        return unsupported('discard count range is invalid', 'discard')
    end
    -- Compute the entire donor policy on its owner-card domain first. Offered
    -- IDs authorize the answer; they must not reorder or prune donor inputs.
    local original=self.askForDiscard==SmartAIView.originalHegemonyAskForDiscard
        and type(SmartAIView.originalHegemonyAskForDiscard)=='function'
    local selected
    if original then
        local ok,value=pcall(self.askForDiscard,self,options.reason,maximum,minimum,
            options.optional,include_equip,request.pattern)
        if AIUnsupported.is(value)then error(value,0)end
        if not ok then
            if type(ai_original_discard_error)~='function'then ai_unsupported('Original discard error bridge unavailable','discard')end
            local result=ai_original_discard_error(value)
            if type(result)~='table'or result.kind~='original_discard_error_result'or not AIValue.isList(result.cards)then
                ai_unsupported(type(result)=='table'and result.error or'Original discard fallback unknown','discard')
            end
            return{kind='answer',original_discard_error=true,cards=result.cards}
        end
        if options.optional and type(value)~='table'then return{kind='pass'}end
        selected=value
    else selected=self:askForDiscard(options.reason,maximum,minimum,
        options.optional,include_equip,request.pattern)end
    if AIUnsupported and AIUnsupported.is(selected) then error(selected, 0) end
    if not AIValue.isList(selected) then return unsupported('discard policy did not return IDs', 'discard') end
    local offered_ids, seen = {}, {}
    for _, id in ipairs(options.card_ids) do offered_ids[id] = true end
    for _, id in ipairs(selected) do
        if type(id) ~= 'number' or id % 1 ~= 0 or not offered_ids[id] or seen[id] then
            return unsupported('source discard selection is outside the native answer domain', 'discard')
        end
        seen[id] = true
    end
    if #selected > maximum or (#selected < minimum and not (options.optional and #selected == 0)) then
        return unsupported('source discard selection violates the native count range', 'discard')
    end
    if #selected == 0 and options.optional then return {kind='pass'} end
    return selected
end

ai_skill_askforag_default = ai_skill_askforag_default or function(self, options)
    if not options or options.candidates_complete ~= true then
        return unsupported("amazing-grace candidate completeness is unknown", "amazing_grace")
    end
    if type(options.card_ids) == "table" and #options.card_ids == 0 then return {kind="pass"} end
    local ids = offered(options, "card_ids")
    if not ids then return unsupported("amazing-grace candidates are missing", "amazing_grace") end
    local cards = known_cards(self, ids, options)
    if not cards then return unsupported("amazing-grace card metadata is incomplete", "amazing_grace") end
    if options.optional and options.reason == "xinzhan" then
        local next_player = self.player:getNextAlive()
        if not next_player then return unsupported("xinzhan next player is unknown", "amazing_grace") end
        local relation = self:relationTo(next_player)
        if relation == nil or relation == "unknown" then
            return unsupported("xinzhan next-player relation is unknown", "amazing_grace")
        end
        if relation == "friend" and next_player:containsTrick("indulgence")
            and not next_player:containsTrick("YanxiaoCard") and #cards == 1 then return {kind="pass"} end
        for _, card in ipairs(cards) do
            if not card:isKindOf("Shit") then return card:getEffectiveId() end
        end
        return {kind="pass"}
    end
    for _, card in ipairs(cards) do
        if self:isCardForAcquisition("Peach", card) then return card:getEffectiveId() end
    end
    for _, card in ipairs(cards) do
        -- Keep both source checks and their short-circuit order: owner filter
        -- and view-as classification can differ from printed card identity.
        for _, class in ipairs({"Indulgence", "AOE"}) do
            if self:isCardForAcquisition(class, card) then
                local weak = self:isWeak()
                if weak == nil then return unsupported("AG weakness is unknown", "amazing_grace") end
                local jinks = weak and self:getCardsNum("Jink") or 1
                if not finite_number(jinks) then return unsupported("AG Jink count is unknown", "amazing_grace") end
                if not (weak and jinks < 1) then return card:getEffectiveId() end
            end
        end
    end
    local callback = legacy_by_kind.amazing_grace.amazing_grace
    if type(callback) == "function" then
        return legacy_call(self, "amazing_grace", callback, options, self.request or {})
    end
    return amazing_grace_policy(self, ids, options)
end

-- Selection policy is shared by real questions and hypothetical evaluations.
-- A callback such as NosChengxiang delegates its current AG question back to
-- the common strategy with another reason. Preserve the real offered domain.
function SmartAIView:selectCurrentAmazingGrace(ids,optional,reason)
    local source=self.request and self.request.options
    if not source or source.candidates_complete~=true or type(source.card_ids)~="table"then
        return unsupported("nested AG selection needs the current native AG domain","amazing_grace")
    end
    local allowed={};for _,id in ipairs(source.card_ids)do allowed[id]=true end
    for _,id in ipairs(ids)do if not allowed[id]then return unsupported("nested AG selected outside its current native domain","amazing_grace")end end
    local options={};for key,value in pairs(source)do options[key]=value end
    options.card_ids,options.optional,options.reason=ids,optional,reason
    return ai_skill_askforag_default(self,options)
end

-- Direct source ai_skill_askforag.amazing_grace policy for Guanxing. This
-- intentionally skips askForAG's Peach/AOE preselection and callback dispatch.
-- The cards must already be disclosed by the current native inquiry.
function SmartAIView:selectAmazingGracePolicy(ids)
    local options=self.request and self.request.options
    if type(ids)~="table"or #ids==0 then return unsupported("AG policy requires a nonempty disclosed domain","amazing_grace")end
    for _,id in ipairs(ids)do
        if not self:getChoiceCard(id,options)then return unsupported("AG policy card is not disclosed","amazing_grace")end
    end
    return amazing_grace_policy(self,ids,options)
end

-- Selection policy is shared by real questions and hypothetical evaluations.
-- It receives a read-only domain, not a request or an action capability.
local function select_cardchosen(self,target,flags,method,ids,card_lookup,random_hidden,duel_2013)
    local relation = target == self.player and "friend" or self:relationTo(target)
    if relation == nil or relation == "unknown" then return unsupported("card-chosen relation is unknown", "card_chosen") end
    local allowed = {}
    for _, id in ipairs(ids) do allowed[id] = true end
    if type(flags) ~= "string" then return unsupported("card-chosen zones are unknown", "card_chosen") end
    local no_dis = method ~= sgs.Card_MethodDiscard
    if duel_2013 then
        local cards, jink = target:getHandcards(), nil
        if cards == nil and target:isHandVisible() == true then
            local known = target:getKnownCards()
            -- Native may authorize full disclosure for this inquiry without
            -- granting the foreign-player owner-only getHandcards interface.
            if known ~= nil and #known == target:getHandcardNum() then cards = known end
        end
        if cards == nil then return unsupported("1v1 dismantlement hand identity is not viewer-visible", "card_chosen") end
        for _, card in ipairs(cards) do
            local id = card:getEffectiveId()
            if allowed[id] then
                if isCard("Peach", card, target) then return id end
                if isCard("Jink", card, target) then jink = id end
            end
        end
        if jink then return jink end
        cards = self:sortByKeepValue(cards, true)
        if not cards then return unsupported("1v1 dismantlement keep order is unknown", "card_chosen") end
        for _, card in ipairs(cards) do if allowed[card:getEffectiveId()] then return card:getEffectiveId() end end
    end
    local function desirable(id)
        if not allowed[id] then return false end
        local provider = self.doDisCard
        local result = provider(self, target, id, no_dis)
        if AIUnsupported.is(result) then error(result, 0) end
        if result == nil and not SmartAIView.isKnownNilStrategyResult(self, "doDisCard", provider) then
            return unsupported("card-chosen discard benefit is unknown", "card_chosen")
        end
        return result
    end
    local function target_order(cards, descending, equipment)
        if #cards < 2 then return cards end
        if target == self.player and equipment then return self:sortByKeepValue(cards, descending) end
        local ranked = {}
        for _, card in ipairs(cards) do
            local value = self:getKeepValue(card)
            if not finite_number(value) then return unsupported("card-chosen visible keep estimate is unknown", "card_chosen") end
            if target ~= self.player then
                if type(self.useKnowledgeEstimate) ~= "function" then
                    return unsupported("card-chosen knowledge estimate protocol is unavailable", "card_chosen")
                end
                value = self:useKnowledgeEstimate({value=value, status="estimate",
                    basis="viewer keep value of visible card; target private keep cache and planned uses excluded",
                    viewer=self.player:objectName(), observer=target:objectName(), target=target:objectName()}, "card_chosen.keep")
            end
            ranked[#ranked + 1] = {card=card, value=value}
        end
        -- Display-card branches in the donor compare getKeepValue directly.
        -- They must not apply sortByKeepValue's locks/planned-use/display deltas.
        table.sort(ranked, function(a, b)
            if descending then return a.value > b.value end
            return a.value < b.value
        end)
        local ordered = {}
        for _, entry in ipairs(ranked) do ordered[#ordered + 1] = entry.card end
        return ordered
    end
    local function display_choice(descending)
        local display_ids = target:getDisplayCards()
        if display_ids == nil then return unsupported("display-card membership is unknown", "card_chosen") end
        local cards = {}
        for _, id in ipairs(display_ids) do
            if allowed[id] then
                local card = card_lookup(id)
                if not card then return unsupported("display-card metadata is unknown", "card_chosen") end
                cards[#cards + 1] = card
            end
        end
        local ordered = target_order(cards, descending)
        return ordered[1] and ordered[1]:getEffectiveId(), #display_ids
    end
    local function random_card(zones)
        local cards = target:getCards(zones)
        if cards == nil then
            local avoid = false
            if relation == "enemy" then
                local wounded = target:isWounded()
                if type(wounded) ~= "boolean" then return unsupported("random-choice wound state is unknown", "card_chosen") end
                if wounded then
                    avoid = target:hasArmorEffect("SilverLion")
                    if type(avoid) ~= "boolean" then return unsupported("random-choice armor effect is unknown", "card_chosen") end
                end
            end
            return random_hidden(zones,avoid)
        end
        if target == self.player then cards = self:sortByKeepValue(cards) end
        if cards == nil then return unsupported("random-choice keep order is unknown", "card_chosen") end
        local candidates = {}
        for _, card in ipairs(cards) do if allowed[card:getEffectiveId()] then candidates[#candidates + 1] = card end end
        if #candidates == 0 then return {kind="pass"} end
        if target == self.player then return candidates[1]:getEffectiveId() end
        local index = math.random(1, #candidates)
        local chosen = candidates[index]
        if chosen:isKindOf("SilverLion") and target:isWounded() and relation == "enemy"
            and target:hasArmorEffect("SilverLion") then
            if index ~= #candidates then chosen = candidates[index + 1]
            elseif index > 1 then chosen = candidates[index - 1] end
        end
        return chosen:getEffectiveId()
    end
    if relation == "friend" and flags:find("j", 1, true) then
        local hand = target:getHandcardNum()
        if not finite_number(hand) then return unsupported("card-chosen hand size is unknown", "card_chosen") end
        if not (target:hasSkill("qiaobian") and hand > 0) then
            local judging = target:getJudgingArea()
            if not judging then return unsupported("card-chosen judgments are unknown", "card_chosen") end
            local damage, indulgence, supply
            for _, card in ipairs(judging) do
                local id = card:getEffectiveId()
                if desirable(id) then
                    if card:isDamageCard() then damage = id
                    elseif card:isKindOf("Indulgence") then indulgence = id
                    elseif not card:isKindOf("Disaster") then supply = id end
                end
            end
            if damage then
                local enemies = self:getEnemies()
                if not enemies then return unsupported("card-chosen enemies are unknown", "card_chosen") end
                local wizard = self:hasWizard(enemies)
                if wizard == nil then return unsupported("card-chosen wizard ability is unknown", "card_chosen") end
                if wizard then return damage end
            end
            local hp = target:getHp()
            if supply and not finite_number(hp) then return unsupported("card-chosen HP is unknown", "card_chosen") end
            if supply and hp >= hand then return supply end
            if indulgence then return indulgence end
            if supply then return supply end
        end
    end
    if flags:find("e", 1, true) then
        local equips = target:getEquips()
        if not equips then return unsupported("card-chosen equipment is unknown", "card_chosen") end
        if relation ~= "friend" and #equips > 0 then
            for _, method in ipairs({"getDangerousCard", "getValuableCard"}) do
                local id = self[method](self, target)
                if id == nil then return unsupported("card-chosen " .. method .. " is unknown", "card_chosen") end
                if type(id) == "number" and desirable(id) then return id end
            end
        end
        equips = target_order(equips, relation ~= "friend", true)
        if not equips then return unsupported("card-chosen equipment order is unknown", "card_chosen") end
        for _, card in ipairs(equips) do if desirable(card:getEffectiveId()) then return card:getEffectiveId() end end
        if relation == "friend" and #equips > 0 and self:loseEquipEffect(target) and self:isWeak(target)
            and desirable(equips[1]:getEffectiveId()) then return equips[1]:getEffectiveId() end
    end
    if relation == "friend" and flags:find("j", 1, true) then
        local judging = target:getJudgingArea()
        if not judging then return unsupported("card-chosen judgments are unknown", "card_chosen") end
        for _, card in ipairs(judging) do if desirable(card:getEffectiveId()) then return card:getEffectiveId() end end
    end
    if relation == "friend" and flags:find("h", 1, true) and target:getHandcardNum() > 0 then
        if no_dis then
            local display_ids = target:getDisplayCards()
            if display_ids == nil then return unsupported("display-card membership is unknown", "card_chosen") end
            if target:getHandcardNum() - #display_ids > 0 then return random_card("h") end
            if #display_ids > 0 then
                local chosen = display_choice(false)
                if chosen then return chosen end
            end
        end
        return random_card("h")
    end
    if relation ~= "friend" and flags:find("h", 1, true) and target:getHandcardNum() <= 2
        and self:doDisCard(target, "h", no_dis) then
        if target:hasSkills("jijiu|qingnang|qiaobian|jieyin|beige|buyi|manjuan") then return random_card("h") end
        local chosen = display_choice(true)
        if chosen then return chosen end
    end
    if relation ~= "friend" and flags:find("j", 1, true) then
        local judging = target:getJudgingArea()
        if not judging then return unsupported("card-chosen judgments are unknown", "card_chosen") end
        local damage, yanxiao
        for _, card in ipairs(judging) do
            local id = card:getEffectiveId()
            if card:isDamageCard() and desirable(id) then damage = id
            elseif card:isKindOf("YanxiaoCard") and desirable(id) then yanxiao = id end
        end
        if damage then
            local retrial = self:getFinalRetrial(target)
            if not finite_number(retrial) then return unsupported("card-chosen final retrial is unknown", "card_chosen") end
            if retrial > 1 then return damage end
        end
        if yanxiao then return yanxiao end
    end
    if relation ~= "friend" and flags:find("h", 1, true) and self:doDisCard(target, "h", no_dis) then
        local chosen = display_choice(true)
        if chosen then return chosen end
        if target:getHandcardNum() <= 2 or target:hasSkills(sgs.cardneed_skill)
            or target:getHandcardNum() == 1 and target:getHp() <= 2 and self:getDefenseSlash(target) < 3 then
            return random_card("h")
        end
    end
    return random_card(flags)
end

ai_skill_cardchosen_default = ai_skill_cardchosen_default or function(self, options)
    local duel_2013 = false
    if options and options.reason == "dismantlement" then
        local mode = self.room:getMode()
        if mode == nil then return unsupported("dismantlement mode is unknown", "card_chosen") end
        if mode == "02_1v1" then
            local rule = self.room:getDuelRule()
            if type(rule) ~= "string" then return unsupported("1v1 dismantlement rule is unknown", "card_chosen") end
            duel_2013 = rule == "2013"
        end
    end
    local ids = offered(options, "card_ids")
    local random_choices = options and options.context and options.context.random_card_choices
    if not ids and options and type(options.card_ids) == "table" and type(random_choices) == "table" then ids = {} end
    if not ids then
        if options and options.optional and options.candidates_complete == true then return {kind="pass"} end
        return unsupported("card-chosen candidates are missing", "card_chosen")
    end
    local context = options.context or {}
    local target_name = context.who or context.target
    local target = target_name and self.room:findPlayerByObjectName(target_name, true)
    if not target then return unsupported("card-chosen target is unknown", "card_chosen") end
    local function random_hidden(zones,avoid)
        local ticket = type(random_choices)=="table" and random_choices[zones]
        if type(ticket)~="table" or type(ticket.token)~="string" or ticket.token==""
            or not finite_number(ticket.count) or ticket.count<0 or ticket.count%1~=0 then
            return unsupported("hidden-hand random choice ticket is missing or incomplete","card_chosen")
        end
        if ticket.count==0 then return {kind="pass"} end
        return {kind="answer",random_card_choice={token=ticket.token,index=math.random(1,ticket.count),
            avoid_wounded_enemy_silver_lion=avoid}}
    end
    return select_cardchosen(self,target,context.flags,context.method or context.handling_method,ids,
        function(id)return self:getChoiceCard(id,options)end,random_hidden,duel_2013)
end

-- Hypothetical recommendation for Guixin and similar pure scoring callers.
-- This never issues an action, invents an offer, or reveals a hidden card ID.
function SmartAIView:recommendCardChosen(target,flags,reason,method)
    if not AIValue.isPlayer(target) or type(flags)~="string" or flags=="" or flags:find("[^hej]") then
        return unsupported("invalid hypothetical card-choice domain","recommendCardChosen")
    end
    local function required(value,key)
        if value==nil then return unsupported("hypothetical choice fact is unknown",key) end
        return value
    end
    self:refreshDiscardPreferences()
    local disabled={}
    for _,id in ipairs(required(self.disabled_ids,"disabled card cache")) do disabled[id]=true end
    local ids,by_id,zones={}, {}, {}
    local function add(card,zone)
        local id=required(card:getEffectiveId(),"public card id")
        by_id[id],zones[id]=card,zone
        if not disabled[id] then ids[#ids+1]=id end
    end
    for _,zone in ipairs({{"h","getKnownCards"},{"e","getEquips"},{"j","getJudgingArea"}}) do
        if flags:find(zone[1],1,true) then
            for _,card in ipairs(required(target[zone[2]](target),zone[2])) do add(card,zone[1]) end
        end
    end
    local function chosen(id)
        if type(id)=="table" and type(id.getEffectiveId)=="function" then id=id:getEffectiveId() end
        if type(id)~="number" then return unsupported("hypothetical hook returned no pure card id","recommendCardChosen") end
        if id<0 then return {zone="none"} end
        if not by_id[id] then return unsupported("hypothetical hook selected an undisclosed card","recommendCardChosen") end
        return {id=id,zone=zones[id]}
    end
    local skills=required(target:getSkills(),"target skills")
    for _,skill in ipairs(skills) do
        local callback=legacy_by_kind.card_chosen["#"..skill:objectName()]
        if type(callback)=="function" then
            local answer=callback(self,target,flags,method)
            if answer then return chosen(answer) end
        end
    end
    local key=(reason or ""):gsub("%-","_")
    local callback=legacy_by_kind.card_chosen[key]
    if type(callback)=="function" then
        local answer=callback(self,target,flags,method)
        if answer then
            local id=type(answer)=="number" and answer or answer:getEffectiveId()
            if not disabled[id] then return chosen(id) end
        end
    elseif type(callback)=="number" then
        legacy_by_kind.card_chosen[key]=nil
        if not disabled[callback] then return chosen(callback) end
    end
    local function random_hidden(selected,avoid)
        local domain={}
        if selected:find("h",1,true) then
            local count=required(target:getHandcardNum(),"hand count")
            local known_disabled=0
            for id,zone in pairs(zones) do if zone=="h" and disabled[id] then known_disabled=known_disabled+1 end end
            count=math.max(0,count-known_disabled)
            if next(disabled)~=nil then
                count=self:useKnowledgeEstimate({value=count,status="estimate",
                    basis="public hand count minus disclosed disabled hand cards; undisclosed disabled membership excluded",
                    viewer=self.player:objectName(),observer=target:objectName(),target=target:objectName()},"card_chosen.hypothetical_domain")
            end
            if method==sgs.Card_MethodDiscard then
                local blocked=0
                for id,zone in pairs(zones)do
                    if zone=="h"and not disabled[id] and not required(self.player:canDiscard(target,id),"known hand discard legality")then
                        blocked=blocked+1
                    end
                end
                count=math.max(0,count-blocked)
                if not required(self.player:canDiscard(target,"h"),"public hand-zone discard legality")then count=0 end
                local visible=required(target:getKnownCards(),"disclosed hand cards")
                if #visible<required(target:getHandcardNum(),"hand count")then
                    count=self:useKnowledgeEstimate({value=count,status="estimate",
                        basis="public_zone_legality_and_hand_count; undisclosed_card_specific_limits_assumed_inactive",
                        viewer=self.player:objectName(),observer=target:objectName(),target=target:objectName()},
                        "card_chosen.hypothetical_discard_domain")
                end
            end
            for index=1,count do domain[#domain+1]={zone="h"} end
        end
        for _,zone in ipairs({{"e","getEquips"},{"j","getJudgingArea"}}) do
            if selected:find(zone[1],1,true) then
                for _,card in ipairs(required(target[zone[2]](target),zone[2])) do
                    local id=card:getEffectiveId()
                    if not disabled[id] and (method~=sgs.Card_MethodDiscard
                        or required(self.player:canDiscard(target,id),"discard legality")) then
                        domain[#domain+1]={id=id,zone=zone[1],card=card}
                    end
                end
            end
        end
        if #domain==0 then return {zone="none"} end
        local index=math.random(1,#domain)
        if avoid and domain[index].card and domain[index].card:isKindOf("SilverLion") then
            if index~=#domain then index=index+1 elseif index>1 then index=index-1 end
        end
        return {zone=domain[index].zone,id=domain[index].id}
    end
    local duel=reason=="dismantlement" and required(self.room:getMode(),"mode")=="02_1v1"
        and required(self.room:getDuelRule(),"duel rule")=="2013"
    local answer=select_cardchosen(self,target,flags,method,ids,function(id)return by_id[id]end,random_hidden,duel)
    if type(answer)=="number" then return chosen(answer) end
    if type(answer)=="table" and answer.zone then return answer end
    if type(answer)=="table" and answer.kind=="pass" then return {zone="none"} end
    return unsupported("hypothetical chooser returned an action instead of a recommendation","recommendCardChosen")
end

ai_skill_askforyiji_default = ai_skill_askforyiji_default or function(self, options)
    if not options or options.candidates_complete ~= true then
        return unsupported("yiji candidate completeness is unknown", "yiji")
    end
    local ids, players = offered(options, "card_ids"), offered(options, "players")
    if not ids or not players then
        return options.optional and {kind = "pass"}
            or unsupported("yiji candidates are missing", "yiji")
    end
    local cards = known_cards(self, ids, options)
    local targets = AIList.new({})
    local allowed_targets, allowed_cards = {}, {}
    for _, id in ipairs(ids) do allowed_cards[id] = true end
    for _, name in ipairs(players) do
        allowed_targets[name] = true
        local target = self.room:findPlayerByObjectName(name, true)
        if target then targets[#targets + 1] = target end
    end
    local unknown
    if cards and type(self.getCardNeedPlayer) == "function" then
        local ok, gift = AIUnsupported.capture(function()
            local card, target = self:getCardNeedPlayer(AIList.new(cards), true, targets)
            if card and target then
                local id, name = card:getEffectiveId(), target:objectName()
                if allowed_cards[id] and allowed_targets[name] then
                    return {kind="answer", cards={id}, targets={name}}
                end
            end
        end)
        if ok and gift then return gift end
        if not ok then unknown = gift end
    end
    if unknown then error(unknown, 0) end
    if not cards then return unsupported("yiji card metadata is incomplete", "yiji") end
    if #targets ~= #players then return unsupported("yiji target metadata is incomplete", "yiji") end
    if type(self.getCardNeedPlayer) ~= "function" then
        return unsupported("yiji card-need policy is unavailable", "yiji")
    end
    -- Legacy returns nil,-1 when no gift is found; it never invents a recipient.
    if options.optional then return {kind="pass"} end
    return unsupported("yiji has no strategic gift for a compulsory request", "yiji")
end

ai_skill_playerchosen_default = ai_skill_playerchosen_default or function(self, options)
    -- SmartAI returns nil without drawing RNG when no valid Player was chosen.
    -- Any mandatory server fallback belongs to the native decision service;
    -- it must not be simulated by a second, different Lua random selection.
    return {kind="pass"}
end

ai_skill_playerschosen_default = ai_skill_playerschosen_default or function(self, options)
    local players = options and options.players
    if type(players) ~= "table" then return unsupported("players-chosen candidates are missing", "players_chosen") end
    local min_count = type(options.min_count) == "number" and options.min_count or 0
    local max_count = type(options.max_count) == "number" and options.max_count or #players
    if min_count > #players or max_count < min_count then
        return unsupported("players-chosen bounds do not fit the candidate set", "players_chosen")
    end
    local result, selected = {}, {}
    for _, name in ipairs(options.players_seed or {}) do result[#result + 1], selected[name] = name, true end
    -- addFunction.lua RandomList draws from n down to one (including the last
    -- singleton), unlike Fisher-Yates. It shuffles even when minimum is zero.
    local pool, shuffled = {}, {}
    for _, name in ipairs(players) do pool[#pool + 1] = name end
    while #pool > 0 do
        local index = math.random(1, #pool)
        shuffled[#shuffled + 1] = table.remove(pool, index)
    end
    for _, name in ipairs(shuffled) do
        if #result < min_count and not selected[name] then result[#result + 1], selected[name] = name, true end
    end
    return #result > 0 and result or {kind="pass"}
end

ai_skill_guanxing_default = ai_skill_guanxing_default or function(self, options)
    local ids = offered(options, "card_ids")
    if not ids then return unsupported("guanxing cards are missing", "guanxing") end
    local mode=tonumber(options.default_choice)
    if mode~=-1 and mode~=0 and mode~=1 then return unsupported("guanxing direction is unknown", "guanxing")end
    if type(self.askForGuanxing)~="function"then return unsupported("source Guanxing strategy is unavailable","guanxing")end
    local up,down=self:askForGuanxing(ids,mode)
    if type(up)~="table"or type(down)~="table"then return unsupported("invalid Guanxing strategy result","guanxing")end
    return {kind="answer",cards=up,bottom_cards=down}
end


ai_skill_triggerorder_default = ai_skill_triggerorder_default or function(self, options)
    if options and options.optional then return {kind="pass"} end
    local choices = offered(options, "choices")
    if not choices then return unsupported("trigger-order candidates are missing", "trigger_order") end
    return choices[math.random(#choices)]
end

response_card_default = function(self, options, request)
    if not options then
        return unsupported("response options are missing", "respond_card")
    end
    local unknown
    local function mark_unknown(reason)
        unknown = unknown or AIUnsupported.new(reason, "respond_card")
    end
    local incomplete = options.candidates_complete ~= true
    if incomplete then
        mark_unknown("response candidate completeness is unknown")
    end
    if request.conversions_enumerated ~= true then mark_unknown("response conversion enumeration is unknown") end
    local ids = type(options.card_ids) == "table" and options.card_ids or nil
    if not ids then
        mark_unknown("response card candidates are missing")
        ids = {}
    end
    -- Preserve getCard's class and priority order before filtering authority
    -- candidates. Filtering before sorting would consume a different RNG stream.
    local allowed, classes, seen = {}, {}, {}
    for _, id in ipairs(ids) do allowed[id] = true end
    -- Native projects the complete source first pass over addHandPile's exact
    -- pattern zone, including locked/using cards excluded from action offers.
    -- Their class can still precede another class's Guhuo hypothesis. Offers
    -- therefore constrain submission only, never discovery or sorting order.
    local policy = request.conversion_policy
    local physical_order = type(policy) == "table" and policy.physical_class_order
    if type(policy) ~= "table" or policy.physical_class_order_complete ~= true
        or not AIValue.isList(physical_order) then
        return unsupported("response physical class order is unknown or incomplete", "respond_card")
    end
    for _, class in ipairs(physical_order) do
        if type(class) ~= "string" or class == "" or seen[class] then
            return unsupported("response physical class order is malformed", "respond_card")
        end
        seen[class], classes[#classes + 1] = true, class
    end
    if type(policy) == "table" and policy.class_order_complete == true
        and type(policy.class_order) == "table" then
        for _, entry in ipairs(policy.class_order) do
            local class = type(entry) == "table" and entry.class_name or entry
            if type(class) ~= "string" then return unsupported("response class order is invalid", "respond_card") end
            if not seen[class] then
                local row = type(policy.by_class) == "table" and policy.by_class[class]
                local name = type(entry) == "table" and entry.card_name or type(row) == "table" and row.card_name
                local matches
                if type(entry) == "table" then matches = entry.matches_response_pattern end
                -- Legacy filters its dummy card before calling getCard; sorting
                -- every catalogue class would consume extra decision RNG.
                if type(name) == "string" and type(request.pattern) == "string"
                    and string.find(request.pattern, name, 1, true) then matches = true end
                if matches == true then seen[class], classes[#classes + 1] = true, class
                elseif matches ~= false then mark_unknown("response catalogue pattern match is unknown") end
            end
        end
    elseif (type(policy) == "table" and policy.complete ~= true)
        or #(self:getConversions() or {}) > 0 then
        mark_unknown("response conversion class discovery order is unknown")
    end
    local best
    for _, class in ipairs(classes) do
        local ok, ordered = AIUnsupported.capture(function()
            return self:getCard(class, true, {pattern=request.pattern, prompt=request.prompt,
                method=request.handling_method, reason=request.reason})
        end)
        if not ok then unknown = unknown or ordered
        elseif type(ordered) ~= "table" then mark_unknown("response card ordering is unknown")
        else
            for _, card in ipairs(ordered) do
                local id = card:getEffectiveId()
                if AIValue and AIValue.isCard(card) and card:isEvaluationOnly() == true then
                    -- getCard has already applied the source lock filter and
                    -- full priority sort. A Basic-card hypothesis is selected
                    -- by its pattern match, not by payment feasibility: bind
                    -- only this chosen result, never an unselected Spear cost.
                    local matches
                    local type_id = card:getTypeId()
                    if type(type_id) ~= "number" then
                        return unsupported("readonly response card type is unknown", "respond_card")
                    elseif type_id < 1 then
                        -- SmartAI checks a class dummy for SkillCard policies,
                        -- retaining the original SkillCard as the answer. Its
                        -- own availability/pattern result is not this evidence.
                        local proxy = card._view and card._view.response_class_planning
                        if type(proxy) ~= "table" or type(proxy.exists) ~= "boolean" then
                            return unsupported("readonly response class dummy is unknown", "respond_card")
                        end
                        matches = false
                        if proxy.exists then
                            if type(proxy.source_limited) ~= "boolean" then
                                return unsupported("readonly response class limit is unknown", "respond_card")
                            end
                            if not proxy.source_limited then
                                matches = proxy.source_pattern_match
                                if type(matches) ~= "boolean" then
                                    return unsupported("readonly response class pattern match is unknown", "respond_card")
                                end
                            end
                        end
                    else
                        matches = card._view and card._view.matches_response_pattern
                        if type(matches) ~= "boolean" then
                            return unsupported("readonly response pattern match is unknown", "respond_card")
                        end
                    end
                    if matches then
                        if unknown then error(unknown, 0) end
                        best = response_answer(self, card, options)
                        break
                    end
                elseif AIValue and AIValue.isConversion(card) then
                    local function field(method)
                        if type(card[method]) == "function" then return card[method](card) end
                        mark_unknown("response conversion metadata is missing: " .. method)
                    end
                    local matches = field("matchesResponsePattern")
                    if type(matches) ~= "boolean" then mark_unknown("response conversion pattern match is unknown")
                    elseif matches then
                        local available, coverage = field("isAvailable"), field("hasCompleteCoverage")
                        local activation, source = field("isActivationQuotaAvailable"), field("isSourceQuotaAvailable")
                        if available == false or activation == false or source == false then
                            -- An unavailable policy candidate is not a usable answer.
                        elseif available ~= true or coverage ~= true or activation ~= true or source ~= true then
                            mark_unknown("response conversion availability/coverage/quota is unknown")
                        else best = {kind="answer", card_spec=card:toCardSpec()} break end
                    end
                elseif allowed[id] and (not card.isVirtualCard or not card:isVirtualCard()) then
                    best = id
                    break
                end
            end
        end
        if best ~= nil then break end
    end
    for _, conversion in ipairs(self:getConversions() or {}) do
        if conversion:isAvailable() ~= false and (type(policy) ~= "table" or policy.complete ~= true) then
            mark_unknown("response conversion requires its complete skill selection policy")
        end
    end
    if best ~= nil then
        note_unknown(request.kind, unknown)
        return best
    end
    local compulsory = request.response_compulsory == true or (request.pattern or ""):sub(-1) == "!"
    -- A forced response has a final physical keep-order scan even when getCard
    -- filtered every card (for example Jinchantuoqiao). Unresolved earlier policy
    -- gaps still cannot be silently replaced by this lower-priority fallback.
    if compulsory and not unknown then
        local pattern = request.pattern or ""
        if pattern:sub(-1) == "!" then pattern = pattern:sub(1, -2) end
        local fields = {}
        for field in (pattern .. "|"):gmatch("(.-)|") do fields[#fields + 1] = field end
        local zone = fields[4] == "hand" and "h" or fields[4] == "equipped" and "e" or "he"
        local cards = self:addHandPile(zone)
        if not cards then return unsupported("compulsory physical response order is unknown", "respond_card") end
        cards = self:sortByKeepValue(cards)
        if not cards then return unsupported("compulsory physical keep order is unknown", "respond_card") end
        for _, card in ipairs(cards) do
            local id = card:getEffectiveId()
            if allowed[id] then return id end
        end
    end
    -- Defer a discovered gap until every physical and converted answer was considered.
    if unknown then error(unknown, 0) end
    if options.optional and not compulsory then return {kind = "pass"} end
    return unsupported("response card has no known answer", "respond_card")
end

local function immediate_response_effect(self, options, request)
    local context = options and options.context or {}
    if context.effect ~= nil then return (decision_context(self, options, request) or {}).effect end
    if context.effect_present == false then return nil end
    return unsupported("response CardEffect presence is not projected", "askForCard")
end

response_damage_decline = function(self, options, request)
    local compulsory = request.response_compulsory == true or (request.pattern or ""):sub(-1) == "!"
    if compulsory then return false end
    -- askForCard/nullfilter inspect this invocation's data. The persistent
    -- world cardEffect belongs to askForUseCard and may describe a prior card.
    local effect = immediate_response_effect(self, options, request)
    if effect == nil then return false end
    if not effect.card or not effect.from then return false end
    local card = effect.card
    if type(card.isDamageCard) ~= "function" then card = CardView.new(card) end
    local damage = card:isDamageCard()
    if type(damage) ~= "boolean" then return unsupported("response damage classification is unknown", "askForCard") end
    if not damage then return false end
    local from = legacy_player(self, effect.from)
    if not from then return unsupported("response damage source is unknown", "askForCard") end
    -- These two audited providers legitimately return a source no-result nil.
    -- Retain their actual identity; arbitrary overrides/raw missing facts do not
    -- acquire that permission, and branded coverage signals are never truthy.
    local benefit_provider = self.canDamageHp
    local benefit = benefit_provider(self, from, card, self.player)
    if AIUnsupported.is(benefit) then error(benefit,0) end
    if benefit == nil and not SmartAIView.isKnownNilStrategyResult(self,"canDamageHp",benefit_provider) then
        return unsupported("response damage benefit is unknown", "askForCard")
    end
    if benefit then return true end
    local lose_provider = self.needToLoseHp
    local lose = lose_provider(self, self.player, from, card)
    if AIUnsupported.is(lose) then error(lose,0) end
    if lose == nil and not SmartAIView.isKnownNilStrategyResult(self,"needToLoseHp",lose_provider) then
        return unsupported("response desire to lose HP is unknown", "askForCard")
    end
    return lose == true
end
respond_defaults.askForCard = function(self, options, request)
    local callback = legacy_by_kind.askForCard.nullfilter
    local filtered
    if callback then filtered = legacy_call(self, "askForCard", callback, options, request)
    else filtered = response_nullfilter(self, options, request) end
    if type(filtered) == "table" and filtered.kind == "pass"
        and not request.response_compulsory and (request.pattern or ""):sub(-1) ~= "!" then return filtered end
    return response_card_default(self, options, request)
end

local function inquiry_known(value, label)
    if value == nil then return unsupported(label .. " is unknown", "inquiry_policy") end
    return value
end

local function inquiry_call(object, method, ...)
    if object and method == "getMark" and type(object.getStrategyMark) == "function" then method = "getStrategyMark" end
    if object and method == "hasFlag" and type(object.getStrategyFlag) == "function" then method = "getStrategyFlag" end
    if not object or type(object[method]) ~= "function" then
        return unsupported("inquiry helper is unavailable: " .. method, "inquiry_policy")
    end
    return object[method](object, ...)
end

local function inquiry_relation(self, player)
    if player == nil then return nil end
    if player == self.player then return "friend" end
    local relation = inquiry_known(self:relationTo(player), "player relation")
    if relation == "unknown" then return unsupported("player relation is unknown", "inquiry_policy") end
    return relation
end

response_answer = function(self, card, options)
    if not card then return nil end
    if type(card.isEvaluationOnly) == "function" and card:isEvaluationOnly() == true then
        local materializer
        if self._response_selected_specs and self._response_selected_specs[card] then
            materializer = self.materializeResponseSelectedCard
        elseif self._original_selected_specs and self._original_selected_specs[card] then
            materializer = self.materializeOriginalSelectedCard
        end
        if type(materializer) ~= "function" then
            return unsupported("selected response hypothesis has no current source mapping", "response_selection")
        end
        card = materializer(self, card)
        if AIUnsupported.is(card) then error(card, 0) end
        if not AIValue.isConversion(card) then
            return unsupported("selected response hypothesis did not produce a conversion receipt", "response_selection")
        end
    end
    if type(card.toCardSpec) == "function" then
        local matches = inquiry_known(inquiry_call(card, "matchesResponsePattern"), "response conversion pattern match")
        if not matches or inquiry_call(card, "isAvailable") == false or inquiry_call(card, "isActivationQuotaAvailable") == false
            or inquiry_call(card, "isSourceQuotaAvailable") == false then return nil end
        if inquiry_call(card, "isAvailable") ~= true or inquiry_call(card, "hasCompleteCoverage") ~= true
            or inquiry_call(card, "isActivationQuotaAvailable") ~= true or inquiry_call(card, "isSourceQuotaAvailable") ~= true then
            return unsupported("response conversion availability/coverage/quota is unknown", "respond_card")
        end
        return {kind="answer", card_spec=card:toCardSpec()}
    end
    local id = card:getEffectiveId()
    for _, offered_id in ipairs(options.card_ids or {}) do if id == offered_id then return id end end
    -- This exact reached native physical-pile selection is not an initial
    -- offered numeric answer. Keep its typed result through askForCard's
    -- ordinary numeric membership gate; native responseCard revalidates it.
    if self:isRushBPhysicalResponseSelection(card) then
        return {kind="answer", cards={id}}
    end
    return nil
end


-- R37 fixed Original askForSinglePeach precedes ordinary registry/personality.
-- No AiResult transition: this SWIG method parses its return without a tag write.
original_single_peach_entry=function(self,options,request)
    local name=options and options.players and options.players[1]
    local dying=name and self.room:findPlayerByObjectName(name,true)
    if not dying then return unsupported("Original dying player is not projected","askForSinglePeach")end
    local value=self:askForSinglePeach(dying)
    if AIUnsupported.is(value)then error(value,0)end
    if value=="."then return{kind="pass"}end
    if type(value)=="string"then
        if not value:match("^%d+$")then return unsupported("Original rescue wire is outside current physical/issued conversion domain","askForSinglePeach")end
        value=tonumber(value)
    end
    if type(value)=="number"and value>=0 and value<=2147483647 and value%1==0 then
        for _,id in ipairs(options.card_ids or{})do if id==value then return id end end
        return unsupported("Original rescue physical card is not offered","askForSinglePeach")
    end
    local origin=type(self.originalHegemonyRescueWireOrigin)=="function"and self:originalHegemonyRescueWireOrigin(value)==true
    if origin and type(value)=='table'and type(value.conversion_id)=='number'then
        local card=self:getConversion(value.conversion_id)
        if AIUnsupported.is(card)then error(card,0)end
        if not AIValue.isConversion(card)then return unsupported("Original rescue receipt is not current","askForSinglePeach")end
        local spec=card:toCardSpec()
        for _,key in ipairs{'name','suit','number','skill','user_string','activation_skill','source_skill','activation_instance','source_instance','scope_id'}do
            if spec[key]~=value[key]then return unsupported("Original rescue receipt identity changed","askForSinglePeach")end
        end
        local a,b=spec.subcards,value.subcards
        if type(a)~='table'or type(b)~='table'or#a~=#b then return unsupported("Original rescue receipt costs changed","askForSinglePeach")end
        for i,id in ipairs(a)do if b[i]~=id then return unsupported("Original rescue receipt costs changed","askForSinglePeach")end end
        local answer=response_answer(self,card,options)
        if answer then return answer end
        return unsupported("Original rescue receipt failed current native offer gate","askForSinglePeach")
    end
    -- Fixed body normally returns a string or its exact getCardId wire stand-in.
    -- An arbitrary callback userdata is not evidence of a string-origin answer.
    return unsupported("Original rescue result has no source wire provenance","askForSinglePeach")
end

-- Complete Original methods precede all ordinary personality/registry defaults.
original_response_entry=function(self,options,request,question)
    local value
    if question=="askForCard" then
        value=self:askForCard(request.pattern or "",request.prompt or "",self:getDecisionData())
    else
        local context=self:getDecisionContext()
        local trick=context.card
        if not AIValue.isCard(trick)then return unsupported("Original nullification actual trick is unknown",question)end
        local from,to=legacy_player(self,context.from),legacy_player(self,context.to)
        if context.from~=nil and context.from~="" and not from then return unsupported("Original nullification source is unknown",question)end
        if not to or type(context.positive)~="boolean"then return unsupported("Original nullification target/polarity is unknown",question)end
        value=self:askForNullification(trick,from,to,context.positive)
    end
    if AIUnsupported.is(value)then error(value,0)end
    if question=="askForNullification" then
        -- Native SWIG accepts Card* only. The donor's bare getCardId return in
        -- the HegNullification branch fails that cast and TrustAI returns null.
        if not AIValue.isCard(value)and not AIValue.isConversion(value)then return {kind="pass"}end
    else
        if value=="."then return{kind="pass",original_response_wire="."}end
        local source_wire
        if type(value)=="string"and value:match("^[0-9]+$")then source_wire=value
        elseif type(value)=="number"and value>=0 and value<=2147483647 and value%1==0 then
            local wire=tostring(value)
            if wire:match("^[0-9]+$")then source_wire=wire end
        end
        -- Invalid nonempty strings/negative numbers need their own parse-prefix
        -- provenance. They must not become a no-write refusal.
        if value==-1 then return unsupported("negative source wire commit is outside finite Original domain",question)end
        local wire_origin=type(self.originalHegemonyResponseWireOrigin)=="function"
            and self:originalHegemonyResponseWireOrigin(value)==true
        if value==nil or type(value)=="boolean"or value==""
            or (type(value)~="number"and type(value)~="string"and not wire_origin)then
            value=self:originalHegemonyTrustCardDefault()
            if AIUnsupported.is(value)then error(value,0)end
            if value==nil then return{kind="pass"}end
        end
        if type(value)=="string"then
            if value:sub(1,1)=="$"then return unsupported("Original DummyCard wire needs aggregate payment authority",question)end
            local id=value:match("^(%d+)$")
            if not id then return unsupported("Original response wire lacks current issued authority",question)end
            value=tonumber(id)
        end
        if type(value)=="number"then
            if source_wire then
                -- Payment is revalidated natively AFTER the synchronous
                -- AiResult/onTagSet transition; old offered legality is stale.
                return{kind="answer",cards={value},original_response_wire=source_wire}
            end
            for _,id in ipairs(options.card_ids or{})do if id==value then return id end end
            return unsupported("Original response ID is not offered",question)
        end
        if type(value)=="table"and not AIValue.isCard(value)and not AIValue.isConversion(value)
            and type(value.conversion_id)=="number"and wire_origin then
            return unsupported("Original conversion wire cannot cross its source tag revision",question)
        end
        if not AIValue.isCard(value)and not AIValue.isConversion(value)then return unsupported("Original response result is not a card",question)end
    end
    local answer=response_answer(self,value,options)
    if not answer then return unsupported("Original selected response failed current native offer gate",question)end
    return answer
end

-- R32: returned coverage signals are never truthy source decisions. Only
-- captured common providers may distinguish an ordinary source nil from a
-- missing facade input.
local function round32_null_query(object, method, ...)
    local provider = object and object[method]
    local value = inquiry_call(object, method, ...)
    if AIUnsupported.is(value) then error(value,0) end
    if value == nil and type(SmartAIView.isKnownNilStrategyResult) == "function"
        and SmartAIView.isKnownNilStrategyResult(object,method,provider) then return nil end
    return inquiry_known(value,method)
end

response_nullfilter = function(self, options, request, primitive_target, primitive_data)
    local hp = inquiry_known(self.player:getHp(), "own HP")
    if hp > 2 and round32_null_query(self,"needBear") then return {kind="pass"} end
    local effect
    if not primitive_data then effect=immediate_response_effect(self, options, request)end
    local card = effect and effect.card
    if primitive_data then card = false end
    if card and type(card.hasFlag) ~= "function" then card = CardView.new(card) end
    if card and inquiry_known(card:hasFlag("nosjiefan-slash"), "NosJiefan card flag") then
        local policy = inquiry_known(inquiry_call(self, "getResponsePolicy"), "response policy")
        local name = inquiry_known(policy.nosjiefan_target, "NosJiefan target")
        local target = name ~= "" and self.room:findPlayerByObjectName(name, true) or nil
        -- Source isFriend(nil) is false; do not read the rescuer until true.
        if target and round32_null_query(self,"isFriend",target) then
            local rescuer = self.room:findPlayerBySkillName("nosjiefan")
            if rescuer == nil and getmetatable(self.room) == RoomView then
                -- This facade getter shares nil for absent/unknown. Certify
                -- absence only from the complete ordered public skill domain.
                for _, player in ipairs(round32_null_query(self.room,"getAlivePlayers")) do
                    if round32_null_query(player,"hasSkill","nosjiefan") then rescuer = player; break end
                end
            end
            if not rescuer or not round32_null_query(self,"isEnemy",rescuer) then return {kind="pass"} end
        end
    end
    local target=primitive_target
    if not primitive_data then
        if rawget(self,"_cardask_targets_current")then target=self.target
        else
            local target_name = (request.prompt or ""):match("^[^:]*:([^:]*)")
            target = target_name and legacy_player(self, target_name)
        end
    end
    if target then
        if round32_null_query(self.player,"getRole") == "lord" and round32_null_query(target,"hasSkill","guagu")
            or round32_null_query(self,"ajustDamage",target,nil,1,card) == 0
            or round32_null_query(self,"needDeath")
            or inquiry_known(inquiry_call(self, "getRoleEstimate", target), "target role estimate") == "rebel"
                and self.role == "rebel" and round32_null_query(self.player,"hasFlag","AI_doNotSave")
            or round32_null_query(self,"needToLoseHp",self.player,target,card) then return {kind="pass"} end
    end
end


-- Direct ordinary provider for mode wrappers. This bypasses the registry
-- deliberately: the wrapper itself occupies that registry slot. Reuse the
-- complete response_nullfilter body and its literal refusal ABI.
function SmartAIView:ordinaryNullFilter(data,pattern,target)
    local request=self.request
    local result
    if data==1 then result=response_nullfilter(self,nil,nil,target,true)
    else result=response_nullfilter(self,request.options or {},request) end
    if AIUnsupported.is(result) then error(result,0) end
    if result=="." or type(result)=="table" and result.kind=="pass" then return "." end
end

-- Shared standard-card legacy callbacks ask the same nullfilter policy as
-- SmartAI:askForCard. This adapter preserves the legacy literal refusal ABI.
function SmartAIView:standardNullFilter(data,pattern,target)
    local request = self.request
    local options = request.options or {}
    local callback = legacy_by_kind.askForCard.nullfilter
    local result
    if data==1 then
        if callback then result=callback(self,data,pattern,target)
        else result=response_nullfilter(self,nil,nil,target,true)end
    elseif callback then result=legacy_call(self,"askForCard",callback,options,request)
    else result=response_nullfilter(self,options,request) end
    if AIUnsupported and AIUnsupported.is(result)then error(result,0)end
    if result=="." or type(result)=="table" and result.kind=="pass" then return "." end
end

-- Common standard-card responses retain the original ordered card traversal.
-- Their return values are converted only by the request-authorized answer layer.
local function inquiry_friends_noself(self)
    local result = {}
    for _, player in ipairs(inquiry_known(self:getFriends(), "response friends")) do
        if player ~= self.player then result[#result + 1] = player end
    end
    return result
end
local function record_no_jink(self, slash, primitive_data)
    local id, name, previous, scope, ordinal, card_token
    if primitive_data then
        -- Each donor dummy Slash is a new native card. A request-scoped ordinal
        -- preserves that fresh mark identity without inventing a physical ID or
        -- merging all readonly dummy cards into the same negative-ID mark.
        scope=self.world.strategy_facts and self.world.strategy_facts.aocai_nojink_scope
        if type(scope)~="string"or not scope:match("^[1-9]%d*$")then
            return unsupported("nested no-Jink request scope is unknown","aocai:slash-jink")
        end
        ordinal=(rawget(self,"_aocai_nojink_ordinal")or 0)+1
        if ordinal>64 then return unsupported("nested no-Jink ordinal limit exceeded","aocai:slash-jink")end
        self._aocai_nojink_ordinal=ordinal
        name="ai_NoJinkDummy"..scope.."_"..ordinal.."_targeted-Clear"
        previous=0
    else
        local row=rawget(slash,"_view")
        if type(row)=="table"and row.no_cost_virtual==true then
            -- Native proof distinguishes a genuinely empty virtual product
            -- from a public descriptor whose private costs were redacted.
            card_token=slash:getLegacyIdentityToken()
            local projected=self.world.strategy_facts and self.world.strategy_facts.response_effect_nojink_token
            if type(card_token)~="string"or card_token==""or projected~=card_token then
                return unsupported("no-Jink virtual effect identity is unknown","cardask_no_jink")
            end
            name="ai_NoJinkVirtual"..card_token.."_targeted-Clear"
        else
            id = inquiry_known(slash:getEffectiveId(), "no-Jink Slash id")
            if type(id)~="number"or id<0 or id%1~=0 then
                return unsupported("no-Jink paid card identity is not disclosed","cardask_no_jink")
            end
            name = "ai_NoJinkCard" .. id .. "_targeted-Clear"
        end
        previous = inquiry_known(self.player:getMark(name), "no-Jink mark")
    end
    local policy = inquiry_known(self.world.mode_policy, "strategy mark policy")
    policy.strategy_marks = policy.strategy_marks or {}
    local player = self.player:objectName()
    policy.strategy_marks[player] = policy.strategy_marks[player] or {}
    policy.strategy_marks[player][name] = previous + 1
    if self._strategy_evaluation then return end
    local effect = {kind="cardask_no_jink",player=player,amount=1}
    if primitive_data then
        effect.source_key="aocai:slash-jink";effect.scope=scope;effect.ordinal=ordinal
    elseif card_token then effect.card_token=card_token
    else effect.card_id=id end
    if self._event_effect_sink then return self:emitStrategyEffect(effect) end
    self._strategy_effects = self._strategy_effects or {}
    assert(#self._strategy_effects < 64, "strategy effect limit")
    effect.after_delta = 0
    self._strategy_effects[#self._strategy_effects + 1] = effect
end

local function common_slash_jink(self, options, request, target, primitive_data, primitive_pattern)
	local slash = inquiry_known(self:getEvaluationCard("slash"), "Slash evaluation descriptor")
	local j = 1
	local effect
    if primitive_data==nil then effect=immediate_response_effect(self,options,request)end
	if effect then
		slash = inquiry_known(effect.card, "Slash effect card")
		j = inquiry_known(effect.offset_num, "Slash effect offset count")
	end
	local function decline_filter()
        local callback = legacy_by_kind.askForCard.nullfilter
        local result
        if primitive_data~=nil then
            if callback then result=callback(self,primitive_data,primitive_pattern,target)
            else result=response_nullfilter(self,nil,nil,target,true)end
        elseif callback then result = legacy_call(self, "askForCard", callback, options, request)
        else result = response_nullfilter(self, options, request) end
        if AIUnsupported and AIUnsupported.is(result)then error(result,0)end
        return result == "." or type(result) == "table" and result.kind == "pass"
    end
	if not target or decline_filter()
	or slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player,slash,target)
	or self:isFriend(target) and slash:hasFlag("nosjiefan-slash") then return "." end
	local n = self:ajustDamage(target,nil,1,slash)
	if n==1 and self:needToLoseHp(self.player,target,slash)
	then return "." end
	local function getJink()
		if sgs.AIHumanized then
			self:stageSpeechDelay(math.random(self:getSpeechDelay()*0.3,self:getSpeechDelay()*1.3), "cardask:slash-jink")
		end
		--add
		if table.contains(slash:getSkillNames(), "s_w_wushuang") then
			for _,c in sgs.list(self:getCard("Jink",true))do
				if not (c:getSuit()~=slash:getSuit()) then
				return c end
			end
		end

		local js = self:getCard("Jink",true)
		if j>#js then return "." end
		--add
		if self.player:hasSkill("sfofl_yuanchou") or target:hasSkill("sfofl_yuanchou") then
			for _,c in sgs.list(js)do
				if not (c:getSuit()~=slash:getSuit()) then
				return c end
			end
			return "."
		end
		if target:hasSkill("sfofl_benyong") then
			for _,c in sgs.list(js)do
				if not (c:getNumber()<=slash:getNumber()) then
				return c end
			end
			return "."
		end
		if slash and slash:hasFlag("s4_wusheng") then
			for _,c in sgs.list(js)do
				if not (c:getSuit()==slash:getSuit()) then
				return c end
			end
			return "."
		end


		for _,c in sgs.list(js)do
			if not (self.player:hasFlag("dahe") and c:getSuit()~=sgs.Card_Heart) then
			return c end
		end
		if sgs.AIHumanized and math.random()<0.5 and #inquiry_friends_noself(self)>0
		and self:getCardsNum("Peach,Analeptic")<1 and self.player:getHp()<=math.abs(n) then
			self:speak("noJink")
			self:stageSpeechDelay(math.random(self:getSpeechDelay()*0.5,self:getSpeechDelay()*1.5), "cardask:slash-jink")
		end
		record_no_jink(self, slash, primitive_data~=nil)
		return "."
	end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player,50,target) then return getJink() end
		if self.player:getLostHp()==0 and self.player:isMale() and target:hasSkill("jieyin") then return "." end
		if not hasJueqingEffect(target,self.player) then
			if (target:hasSkill("nosrende") or target:hasSkill("rende") and not target:hasUsed("RendeCard")) and self.player:hasSkill("jieming")
			or target:hasSkill("pojun") and not self.player:faceUp()
			then return "." end
		end
	else
		if n>1 or n>=self.player:getHp() then return getJink() end
		local current = self.room:getCurrent()
		if current and current:hasSkill("juece") and self.player:getHp()>0 then
			for _,c in sgs.list(self:getCards("Jink"))do
				if self.player:isLastHandCard(c,true)
				then return "." end
			end
		end
		if self.player:getHandcardNum()==1 and self:needKongcheng()
		or not(self:hasLoseHandcardEffective() or self.player:isKongcheng()) then return getJink() end
		if target:hasSkill("mengjin") and not(target:hasSkill("nosqianxi") and target:distanceTo(self.player)==1) then
			if self.player:getCardCount()<2 and not self.player:getArmor() then return getJink() end
			if self:getCardsNum("Peach,Analeptic")>0 and self:isWeak() and not(hasTuntianEffect(self.player, true) or self:willSkipPlayPhase())
			or self.player:getCardCount()>1 and self.player:hasSkills("jijiu|qingnang")
			or self:canUseJieyuanDecrease(target) then return "." end
		end
		if self.player:getHp()>1 and getKnownCard(target,self.player,"Slash")>0
		and getKnownCard(target,self.player,"Analeptic")>0 and self:getCardsNum("Jink")<2
		and (target:getPhase()<=sgs.Player_Play or self:slashIsAvailable(target) and target:canSlash(self.player))
		then return "." end
		if not(target:hasSkill("nosqianxi") and target:distanceTo(self.player)==1) then
			if target:hasWeapon("Axe") then
				if target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length()>1 and target:getCardCount()>2
				or target:getHandcardNum()-target:getHp()>2 and not self:isWeak() and self:getOverflow()>0
				then return "." end
			elseif target:hasWeapon("Blade") then
				if math.abs(n)>1 or self.player:hasArmorEffect("EightDiagram")
				or self.player:hasArmorEffect("renwang_shield")
				or slash:isKindOf("NatureSlash") and self.player:hasArmorEffect("Vine")
				or self.player:getHp()<2 and #inquiry_friends_noself(self)<1 then
				elseif self.player:hasSkill("jijiu") and getKnownCard(self.player,self.player,"red")>0
				or (self:getCardsNum("Jink")<=getCardsNum("Slash",target,self.player) or self.player:hasSkill("qingnang")) and self.player:getHp()>1
				or self:canUseJieyuanDecrease(target)
				then return "." end
			end
		end
		if slash:objectName()=="yj_stabs_slash"
		and self.player:getHandcardNum()>1 and self.player:getHp()>1 then
			current = self:sortByKeepValue(self.player:getHandcards())
			if isCard("Jink",current[1],self.player) then if self:getKeepValue(current[2])>7 then return "." end
			elseif self:getKeepValue(current[1])>6 then return "." end
		end
	end
	return getJink()
end
local function common_collateral_slash(self, target2, target)
	if self:isFriend(target)
	and (self:collateralCrossbowFlag("read",target) or getCardsNum("Slash",target,self.player)>=2 and self.player:getWeapon():isKindOf("Crossbow")) then
		self:collateralCrossbowFlag("clear",target)
		return "."
	end
	if self:isFriend(target2)
	and self:needLeiji(target2,self.player) then
		for _,slash in sgs.list(self:getCards("Slash"))do
			if self:slashIsEffective(slash,target2)
			then return slash end
		end
	end
	if target2 and self:needToLoseHp(target2,self.player,inquiry_known(self:getEvaluationCard("slash"), "Slash evaluation descriptor")) then
		for _,slash in sgs.list(self:getCards("Slash"))do
			if self:slashIsEffective(slash,target2) and self:isFriend(target2) then return slash end
			if not self:slashIsEffective(slash,target2,self.player,true) and self:isEnemy(target2)
			then return slash end
		end
		for _,slash in sgs.list(self:getCards("Slash"))do
			if not self:needToLoseHp(target2,self.player,slash) and self:isEnemy(target2)
			then return slash end
		end
	end
	if target2 and not self:hasSkills(sgs.lose_equip_skill)
	and self:isEnemy(target2) then
		for _,slash in sgs.list(self:getCards("Slash"))do
			if self:slashIsEffective(slash,target2)
			then return slash end
		end
	end
	if target2 and not self:hasSkills(sgs.lose_equip_skill)
	and self:isFriend(target2) then
		for _,slash in sgs.list(self:getCards("Slash"))do
			if not self:slashIsEffective(slash,target2)
			then return slash end
		end
		for _,slash in sgs.list(self:getCards("Slash"))do
			if (target2:getHp()>3 or not self:canHit(target2,self.player,self:ajustDamage(self.player,target2,1,slash)>1))
			and not target2:isLord() and self.player:getHandcardNum()>1
			then return slash end
			if self:needToLoseHp(target2,self.player,slash) then return slash end
		end
	end
	self:speak("collateralNoslash",self.player:isFemale())
	return "."
end
local function cardask_target(self, request, index)
    local parts = {}
    for part in ((request.prompt or "") .. ":"):gmatch("(.-):") do parts[#parts + 1] = part end
    if rawget(self,"_cardask_targets_current")then return index==2 and self.target or index==3 and self.target2 or nil end
    return legacy_player(self, parts[index])
end
local function common_cardask_answer(self, value, options)
    if value == "." then return {kind="pass"} end
    return response_answer(self, value, options) or {kind="pass"}
end
-- Reusable source selection for askForUseCard's slash-jink wrapper. It returns
-- the selected CardView/conversion or "." before any inquiry-specific offering
-- gate; the caller retains its own native action authorization.
function SmartAIView:selectSlashJink(options, request, target)
    return common_slash_jink(self, options, request, target or cardask_target(self, request, 2))
end

function SmartAIView:selectCollateralSlash(victim, wielder)
    return common_collateral_slash(self, victim, wielder)
end

-- The lower-case Slash policy invokes the donor's positional cardask ABI.
-- The modern options/request registry above is deliberately a different table.
-- Keep both entries on the same complete ordinary policy body.
ai_choice_legacy_registries.ai_skill_cardask["collateral-slash"] = function(self,data,pattern,victim,wielder,prompt)
    if r35_original(self) then
        return unsupported("Original Collateral cardask provider is not this ordinary body","collateral-slash")
    end
    local result=common_collateral_slash(self,victim,wielder)
    if AIUnsupported.is(result) then error(result,0) end
    if type(result)=="string" or result==nil then return result end
    return inquiry_known(inquiry_call(result,"getLegacyStringKey"),"Collateral cardask source string")
end

ai_skill_cardask["slash-jink"] = function(self, options, request)
    return common_cardask_answer(self, common_slash_jink(self, options, request,
        cardask_target(self, request, 2)), options)
end
ai_skill_cardask["collateral-slash"] = function(self, options, request)
    return common_cardask_answer(self, common_collateral_slash(self,
        cardask_target(self, request, 2), cardask_target(self, request, 3)), options)
end

respond_defaults.askForNullification = function(self, options, request)
    local context = decision_context(self, options, request) or {}
    local trick = context.card
    if type(trick) == "table" and type(trick.isKindOf) ~= "function" then trick = CardView.new(trick) end
    if not trick then return unsupported("nullification trick is unknown", "askForNullification") end
    local from, to = legacy_player(self, context.from), legacy_player(self, context.to)
    if not to then return unsupported("nullification target is unknown", "askForNullification") end
    local positive = inquiry_known(context.positive, "nullification polarity")
    local function pass() return {kind="pass"} end
    local function friend(player) return inquiry_relation(self, player) == "friend" end
    local function enemy(player) return inquiry_relation(self, player) == "enemy" end
    local theft = ("snatch|dismantlement|zhujinqiyuan"):match(trick:objectName()) ~= nil
    if from and not inquiry_known(from:isAlive(), "source alive")
        or not inquiry_known(to:isAlive(), "target alive")
        or inquiry_known(inquiry_call(to, "hasFlag", "AIGlobal_NeedToWake"), "target wake flag")
        or theft and inquiry_known(to:isAllNude(), "target zones") then return pass() end
    local nulls = inquiry_known(self:getCard("Nullification", true), "Nullification card order")
    if #nulls < 1 or from and not friend(from) and from:hasSkill("funan")
        or self.player:getHp() < 2 and self:hasSkills("jgjingmiao", self:getEnemies()) then return pass() end
    local null_card, count = nulls[1], #nulls
    local function use_null()
        return response_answer(self, null_card, options)
            or unsupported("selected Nullification is not authority-offered", "askForNullification")
    end
    self.null_num = count
    if trick:isDamageCard() and positive then
        if self:needToLoseHp(to, from, trick) or self:canDamageHp(from, trick, to) then
            -- Keep the RNG before source/relation/weakness tests, including N=1.
            if math.random() >= 1 / count and from ~= self.player and enemy(to)
                and not inquiry_known(self:isWeak(to), "target weakness") then
                self:speak("null_card")
                return use_null()
            end
            return pass()
        elseif from and friend(to) then
            local damage = math.abs(inquiry_known(self:ajustDamage(from, to, 1, trick), "adjusted damage"))
            if damage > 1 or damage >= to:getHp() then return use_null() end
        end
    end
    self.to, self.from, self.trick, self.positive = to, from, trick, positive
    local function callback(key)
        local handler = respond_handlers.askForNullification[key]
        if handler then
            local answer = handler(self, options, request)
            if answer ~= nil then
                if answer == true then return use_null() end
                if answer == false then return pass() end
                return answer
            end
        end
        local fn = legacy_by_kind.askForNullification[key]
        if type(fn) == "function" then
            local result = fn(self, trick, from, to, positive, count)
            if result then return use_null() elseif result ~= nil then return pass() end
        end
    end
    for _, key in ipairs(inquiry_known(inquiry_call(self, "getConnections", to), "target connections")) do
        local answer = callback(key)
        if answer ~= nil then return answer end
    end
    local answer = callback(trick:getClassName())
    if answer ~= nil then return answer end
    if positive then
        if from and trick:isDamageCard() and friend(from)
            and (inquiry_call(self, "needDeath", to) or self:cantbeHurt(to, from)) then return use_null()
        elseif theft and enemy(from) and inquiry_known(inquiry_call(self, "getRoleEstimate", from), "source role estimate") ~= "neutral" then
            if friend(to) then
                if to == self.player or to:containsTrick("YanxiaoCard")
                    or self:getDangerousCard(to) or self:getValuableCard(to) then return use_null() end
                if to:getHandcardNum() == 1 and not self:needKongcheng(to) then
                    if inquiry_known(getKnownCard(to, self.player, "TrickCard,EquipCard,Slash"), "known last hand card") == 1 then
                        return pass()
                    else return use_null() end
                end
            elseif enemy(to) and #inquiry_known(to:getJudgingArea(), "target judgments") > 0 then return use_null() end
        end
        if trick:isKindOf("AOE") and friend(to) then
            local lord, current = self.room:getLord(), inquiry_known(self.room:getCurrent(), "current player")
            local count_alive = inquiry_known(to:aliveCount(), "alive count")
            local function offset(player) return (player:getSeat() - current:getSeat()) % count_alive end
            if lord and friend(lord) and self:isWeak(lord) and inquiry_call(self, "aoeIsEffective", trick, lord)
                and offset(lord) > offset(to)
                and not (self.player == to and self.player:getHp() < 2 and not inquiry_call(self, "canAvoidAOE", trick)) then return pass() end
            if self.player == to and not inquiry_call(self, "canAvoidAOE", trick) then return use_null() end
            if self:isWeak(to) and inquiry_call(self, "aoeIsEffective", trick, to) then
                if count > 1 or self.player:getHp() > 1 or to:isLord() and self.player:getRole() == "loyalist"
                    or inquiry_call(self, "canAvoidAOE", trick) or offset(to) > offset(self.player) then return use_null() end
            end
        end
    elseif from then
        if trick:isDamageCard() and enemy(from)
            and (inquiry_call(self, "needDeath", to) or self:cantbeHurt(to, from))
            or trick:targetFixed() and trick:isKindOf("SingleTargetTrick") and friend(to) then return use_null() end
        if trick:isKindOf("SingleTargetTrick") and friend(from) and not friend(to) then
            if not (theft and to:isNude()) then return use_null() end
        end
    elseif enemy(to) and math.random() > 1 / (count + 1) then return use_null() end
    return pass()
end

local function physical_choice_cards(self, ids, options)
    local cards = known_cards(self, ids, options)
    if not cards then return nil end
    local physical = {}
    for _, card in ipairs(cards) do
        local id = card:getEffectiveId()
        local virtual
        if type(card.isVirtualCard) == "function" then virtual = card:isVirtualCard() end
        if type(virtual) ~= "boolean" then return nil end
        -- Card::setId stores the physical card's own ID in subcards. A nonempty
        -- subcard list therefore does not imply a conversion; the native
        -- isVirtualCard projection is the authoritative distinction here.
        if finite_number(id) and id >= 0 and id % 1 == 0 and not virtual then
            physical[#physical + 1] = card
        end
    end
    return physical
end
respond_defaults.askForCardShow = function(self, options)
    if not options or options.candidates_complete ~= true then
        return unsupported("card-show candidate completeness is unknown", "askForCardShow")
    end
    local ids = type(options.card_ids) == "table" and options.card_ids or nil
    local cards = ids and physical_choice_cards(self, ids, options)
    if not cards or #cards ~= #ids then
        return unsupported("card-show physical metadata is incomplete", "askForCardShow")
    end
    local card = self.player:getRandomHandCard()
    return card and card:getEffectiveId() or {kind="pass"}
end

pindian_selection = function(self, options)
    if not options or options.candidates_complete ~= true then
        return unsupported("pindian candidate completeness is unknown", "askForPindian")
    end
    local ids = offered(options, "card_ids")
    local cards = ids and physical_choice_cards(self, ids, options)
    if not cards or #cards == 0 or #cards ~= #ids then
        return unsupported("pindian card metadata is incomplete", "askForPindian")
    end
    cards = self:sortByUseValue(cards)
    if not cards then return unsupported("pindian use order is unknown", "askForPindian") end
    -- Despite the legacy comment, sortByUseValue defaults to descending.
    local high, low = cards[1], cards[1]
    table.sort(cards, function(a,b)
        local first, second = a:getNumber(), b:getNumber()
        if not finite_number(first) or not finite_number(second) then
            return unsupported("pindian number is unknown", "askForPindian")
        end
        return first < second
    end)
    for _, card in ipairs(cards) do
        local value = self:getUseValue(card)
        if not finite_number(value) then return unsupported("pindian use value is unknown", "askForPindian") end
        if value < 6 then low = card break end
    end
    -- utilities.lua sgs.reverse mutates this same table. Preserve its input
    -- order for the next use-value sort, including equal-valued card ties.
    for i = 1, math.floor(#cards / 2) do
        cards[i], cards[#cards - i + 1] = cards[#cards - i + 1], cards[i]
    end
    for _, card in ipairs(cards) do
        local value = self:getUseValue(card)
        if not finite_number(value) then return unsupported("pindian use value is unknown", "askForPindian") end
        if value < 6 then high = card break end
    end
    cards = self:sortByUseValue(cards)
    if not cards then return unsupported("pindian use order is unknown", "askForPindian") end
    return cards, high, low
end

local function r35_pindian(self,options)
    if not options or options.candidates_complete~=true then
        return unsupported('pindian candidate completeness is unknown','Original askForPindian')
    end
    local ids=offered(options,'card_ids')
    local cards=ids and physical_choice_cards(self,ids,options)
    if not cards or #cards~=#ids then return unsupported('pindian physical cards are unknown','Original askForPindian')end
    local name=options.players and options.players[1]
    local requestor=name and self.room:findPlayerByObjectName(name,true)
    if not requestor then return unsupported('pindian requestor is unknown','Original askForPindian')end
    local reason=options.reason or ''
    local function id(card)
        if AIUnsupported.is(card)then error(card,0)end
        if not AIValue.isCard(card)or card:isVirtualCard()~=false then
            return unsupported('pindian result is not a physical Card','Original askForPindian')
        end
        return card:getEffectiveId()
    end
    if self.player:objectName()==requestor:objectName() and reason~='heg_lieren' then
        local remembered
        if reason=='s3_fans_handou'then remembered=self:readCurrentSourceSlot('s3_fans_handou_card')
        else remembered=self[reason..'_card'] or self:recall(reason..'_card')end
        if remembered then
            local card=self:getKnownCardById(remembered)or self:getChoiceCard(remembered)
            if not card then return unsupported('remembered pindian face is undisclosed','Original askForPindian')end
            return id(card)
        end
        -- The warning is a source diagnostic, not a knowledge estimate.
        if type(self.recordSourceWarning)~='function'then return unsupported('source warning sink is unavailable','Original askForPindian')end
        self:recordSourceWarning('Pindian card for '..reason..' not found!!','Original askForPindian')
        return self:getMaxCard(self.player):getId()
    end
    table.sort(cards,function(a,b)return a:getNumber()<b:getNumber()end)
    local high,low
    for _,card in ipairs(cards)do
        local value=self:getUseValue(card)
        if not finite_number(value)then return unsupported('pindian use value is unknown','Original askForPindian')end
        if value<6 then low=card;break end
    end
    -- Fixed utilities.lua53 mutates the original table and returns it.
    for i=1,math.floor(#cards/2)do cards[i],cards[#cards-i+1]=cards[#cards-i+1],cards[i]end
    for _,card in ipairs(cards)do
        local value=self:getUseValue(card)
        if not finite_number(value)then return unsupported('pindian use value is unknown','Original askForPindian')end
        if value<6 then high=card;break end
    end
    local sorted=self:sortByUseValue(cards,true)
    if sorted~=nil then cards=sorted end -- Original in-place provider may return nil.
    local minuse=cards[1]
    high=high or minuse;low=low or minuse
    local same,first=true,nil
    for _,card in ipairs(cards)do
        if not first then first=card elseif first:getClassName()~=card:getClassName()then same=false end
    end
    local function friend()
        local value=self:isFriend(requestor)
        if type(value)~='boolean'then return unsupported('pindian relation is unknown','Original askForPindian')end
        return value
    end
    if same then if friend()then return id(self:getMinCard())else return id(self:getMaxCard())end end
    local callback=ai_audited_aliases.resolve(self,legacy_by_kind.askForPindian[reason])
    if type(callback)=='function'then
        local value=callback(minuse,self,requestor,high,low)
        if AIUnsupported.is(value)then error(value,0)end
        if value then return id(value)end
    elseif callback==nil and options.context and options.context.legacy_hook==true then
        return unsupported('reason-specific pindian policy is not ported',reason)
    end
    return id(friend()and low or high)
end

respond_defaults.askForPindian = function(self, options)
    if r35_original(self)then return r35_pindian(self,options)end
    if not options or options.candidates_complete ~= true then
        return unsupported("pindian candidate completeness is unknown", "askForPindian")
    end
    local ids = offered(options, "card_ids")
    local original_cards = ids and physical_choice_cards(self, ids, options)
    if not original_cards or #original_cards == 0 or #original_cards ~= #ids then
        return unsupported("pindian card metadata is incomplete", "askForPindian")
    end
    local requestor = options.players and options.players[1]
    local target = requestor and self.room:findPlayerByObjectName(requestor, true)
    if not target then return unsupported("pindian requestor is unknown", "askForPindian") end
    local reason = options.reason or ""
    if target == self.player and not string.find("mizhao|lieren", reason) then
        local remembered
        if reason=='s3_fans_handou'then remembered=self:readCurrentSourceSlot('s3_fans_handou_card')
        else remembered = self:recall(reason .. "_card")end
        if remembered then
            for _, card in ipairs(original_cards) do if card:getEffectiveId() == remembered then return remembered end end
            return unsupported("remembered pindian card is no longer offered", "askForPindian")
        end
        local maximum = self:getMaxCard(self.player, original_cards)
        return maximum and maximum:getEffectiveId()
            or unsupported("pindian maximum is unknown", "askForPindian")
    end
    local cards, high, low = pindian_selection(self, options)
    local callback = ai_audited_aliases.resolve(self, legacy_by_kind.askForPindian[reason])
    if type(callback) == "function" then
        local chosen = callback(cards[1], self, target, high, low)
        if AIUnsupported.is(chosen) then error(chosen, 0) end
        if chosen then
            if not AIValue.isCard(chosen) or chosen:isVirtualCard() ~= false then
                return unsupported("pindian callback did not return a physical Card", "askForPindian")
            end
            return chosen:getEffectiveId()
        end
    elseif callback == nil and options.context and options.context.legacy_hook == true then
        return unsupported("reason-specific pindian policy is not ported", reason)
    end
    local same_class = true
    for _, card in ipairs(cards) do
        if card:getClassName() ~= cards[1]:getClassName() then same_class = false break end
    end
    local friend = self:isFriend(target)
    if type(friend) ~= "boolean" then
        return unsupported("pindian requestor relation is unknown", "askForPindian")
    end
    local selected
    if same_class then
        if friend then selected = self:getMinCard(self.player, original_cards)
        else selected = self:getMaxCard(self.player, original_cards) end
    elseif friend then selected = low
    else selected = high end
    return selected and selected:getEffectiveId()
        or unsupported("pindian extreme card is unknown", "askForPindian")
end

respond_defaults.askForSinglePeach = function(self, options, request)
    local target_name = options and options.players and options.players[1]
    local dying = target_name and self.room:findPlayerByObjectName(target_name, true)
    if not dying then return unsupported("dying player is not projected", "askForSinglePeach") end
    local function pass() return {kind="pass"} end
    local function friend(player) return inquiry_relation(self, player) == "friend" end
    local function enemy(player) return inquiry_relation(self, player) == "enemy" end
    local function estimate(player) return inquiry_known(inquiry_call(self, "getRoleEstimate", player), "role estimate") end
    local function count(class, player)
        if not player or player == self.player then return inquiry_known(self:getCardsNum(class), "own " .. class .. " count") end
        return inquiry_known(getCardsNum(class, player, self.player), "estimated " .. class .. " count")
    end
    if inquiry_call(self, "needDeath", dying) then return pass() end
    local lord = self.room:getLord()
    local role = inquiry_known(self.player:getRole(), "own role")
    if role == "loyalist" and lord and dying:objectName() ~= lord:objectName()
        and inquiry_known(self:isWeak(lord), "lord weakness") and count("Peach") <= 1 then
        -- The donor receives a Player, not a DyingStruct: dying.who is nil.
        -- Its important-friend conjunction is therefore false even for loyalists.
        return pass()
    end
    local peach
    local function use_peach(class)
        if peach ~= nil then return peach end
        for _, card in ipairs(inquiry_known(self:getCard(class or "Peach", true), "rescue card order")) do
            -- Native filters this inquiry's candidates against the actual dying
            -- player. The selection policy cannot infer prohibit rules itself.
            local answer = response_answer(self, card, options)
            if answer ~= nil then return answer end
        end
    end
    local policy
    local function setting(key)
        policy = policy or inquiry_known(inquiry_call(self, "getResponsePolicy"), "response policy")
        return inquiry_known(policy[key], "response policy " .. key)
    end
    local function aoe_has_lord(class)
        if type(self.getEventMemory) ~= "function" then return unsupported("AOE lord event memory is unavailable", "askForSinglePeach") end
        local values, known = self:getEventMemory("aoe_lord")
        if known ~= true or type(values) ~= "table" then return unsupported("AOE lord event memory is unknown", "askForSinglePeach") end
        return values[class] == true
    end
    if self.player == dying then
        peach = use_peach("Peach,Analeptic")
        if peach and inquiry_call(dying, "getState") == "robot" and setting("humanized")
            and math.random() < setting("turn_count") * 0.1
            and #inquiry_known(self:getFriends(), "friends") < dying:aliveCount() / 2
            and #inquiry_known(self:getCard("Analeptic,Peach", true), "rescue card order") < 2 then
            self:stageSpeechDelay(self:getSpeechDelay() * 2, "single_peach:self_refusal")
            self:speak("no_peach", inquiry_known(dying:isFemale(), "dying gender"))
            peach = nil
        end
        return peach or pass()
    elseif setting("humanized") then
        -- Preserve the actual donor's fractional-bound error; do not round it.
        self:stageSpeechDelay(self:getSpeechDelay() * math.random(1.5, 2.5), "single_peach:humanized_wait")
    end
    local process = inquiry_known(inquiry_call(self, "getGameProcess"), "game process")
    local roles = inquiry_known(inquiry_call(self, "getRoleCounts"), "role counts")
    local loyalists = inquiry_known(roles.loyalist, "loyalist count")
    local rebels = inquiry_known(roles.rebel, "rebel count")
    local renegades = inquiry_known(roles.renegade, "renegade count")
    local current = inquiry_known(self.room:getCurrent(), "current player")
    if lord == self.player and self:isWeak() and self:getEnemyNumBySeat(current, self.player, self.player) > 0
        or role == "renegade" and dying ~= lord and (current == self.player or process == "neutral" or loyalists >= rebels)
        or hasBuquEffect(dying) then return pass() end
    if estimate(dying) == "renegade" then
        if role == "loyalist" or role == "renegade" or role == "lord" then
            if loyalists + renegades >= rebels or process == "loyalist" or process == "loyalish" or process == "dilemma" then return pass() end
        end
        if role == "rebel" or role == "renegade" then
            if rebels + renegades - 1 >= loyalists + 1 or process == "rebelish" or process == "dilemma" or process == "rebel" then return pass() end
        end
    end
    if friend(dying) then
        if dying == lord then peach = use_peach()
        elseif lord then
            local peaches = count("Peach")
            if (role == "loyalist" or role == "renegade" and dying:aliveCount() > 2)
                and peaches <= inquiry_known(self:getNeedPeach(lord), "lord Peach reserve")
                or (peaches < 2 and (aoe_has_lord("SavageAssault") and count("Slash", lord) < 1
                    or aoe_has_lord("ArcheryAttack") and count("Jink", lord) < 1)) then return pass() end
            local friends = inquiry_known(self:getFriends(), "friends")
            local friends_noself = {}
            for _, player in ipairs(friends) do if player ~= self.player then friends_noself[#friends_noself + 1] = player end end
            for _, player in ipairs(friends_noself) do
                if inquiry_call(self, "playerGetRound", player) >= inquiry_call(self, "playerGetRound", self.player)
                    and inquiry_call(self, "ableToSave", player, dying) then peaches = peaches + count("Peach", player) end
            end
            if peaches + dying:getHp() < 1 then return pass() end
            if dying ~= lord and lord:getHp() < 2 and friend(lord) and enemy(current)
                and inquiry_call(self, "canSlash", current, lord)
                and count("Peach,Analeptic", lord) < 1 and #friends_noself <= 2
                and inquiry_call(self, "slashIsAvailable", current)
                and peaches <= self:getEnemyNumBySeat(current, lord, self.player) + 1
                and self:damageIsEffective(current, nil, lord) then return pass() end
            if lord:getHp() < 2 and not hasBuquEffect(lord) and (friend(lord) or role == "renegade")
                or inquiry_known(self:getAllPeachNum(), "all Peach count") + dying:getHp() > 0 then peach = use_peach() end
        elseif inquiry_known(inquiry_call(dying, "hasFlag", "Kurou_toDie"), "dying Kurou flag") and count("Crossbow", dying) < 1
            or dying:faceUp() and dying:getHp() >= 0 and dying:hasSkill("jiushi")
            or inquiry_call(self, "doNotSave", dying) then return pass() end
    else
        if (dying:hasSkill("wuhun") or dying:hasSkill("spwuhun")) and role ~= estimate(dying) then
            if lord and self.player:aliveCount() > 2 or rebels + renegades > 1 then
                local function revenge(targets)
                    for _, target in ipairs(inquiry_known(targets, "revenge targets")) do
                        -- Only lord status is needed; no other player's hidden
                        -- role is read to decide this public identity branch.
                        if target:isLord() then
                            local retrial, wizard = self:getFinalRetrial(nil, "wuhun")
                            retrial = inquiry_known(retrial, "Wuhun final retrial")
                            if retrial == 0 or retrial == 2 then peach = use_peach()
                            elseif retrial == 1 then
                                wizard = inquiry_known(wizard, "Wuhun final wizard")
                                local flags = wizard:hasSkill("huanshi") and "he" or "h"
                                if inquiry_known(getKnownCard(wizard, self.player, "Peach,GodSalvation", false, flags), "known retrial rescue cards") > 0 then
                                    return true
                                else peach = use_peach() end
                            end
                        end
                    end
                    return false
                end
                if revenge(inquiry_call(self, "getWuhunRevengeTargets", dying)) then return pass() end
                if revenge(inquiry_call(self, "getSpWuhunRevengeTargets")) then return pass() end
            end
            if setting("jl_bingfen") and math.random() < 0.30 then
                peach = use_peach()
                if peach and setting("bingfen_peach_lines_present") then
                    local lines = setting("bingfen_peach_lines")
                    if type(lines) ~= "table" then return unsupported("peach speech lines are unknown", "askForSinglePeach") end
                    self:setPersonalityTarget()
                    self:stageSpeechDelay(self:getSpeechDelay() * 2, "personality:single_peach")
                    self:emitSpeechLine(self.player, lines[math.random(1, #lines)], "personality:single_peach")
                end
            end
        end
        if self.player:hasSkill("KaiyuanShengshi") and not dying:isLord() and math.random() < 0.5 then peach = use_peach() end
    end
    return peach or pass()
end

-- Full standard-card AG policy; sorting helpers return copies in this VM.
amazing_grace_policy = function(self, card_ids, options)
    local function acquired_is_card(class_name, card)
        local request = self.request
        local domain = request and request.options and request.options.card_ids
        if request and (request.kind == "amazing_grace" or request.kind == "guanxing")
            and type(domain) == "table" then
            for _, id in ipairs(domain) do
                if id == card:getEffectiveId() then
                    return self:isCardForAcquisition(class_name, card)
                end
            end
        end
        -- Other callers retain their existing source classification context.
        -- This readonly acquisition capability never extends to another domain.
        return isCard(class_name, card, self.player)
    end
    local function required(method, ...)
        return inquiry_known(inquiry_call(self, method, ...), "AG " .. method)
    end
    local function can_slash(from, to, card, distance_limit, range_fix)
        local result = from:canSlash(to, card, distance_limit, range_fix)
        if type(result) ~= "boolean" then return unsupported("AG exact canSlash query is unknown", "amazing_grace") end
        return result
    end
    local enemies = inquiry_known(self:getEnemies(), "AG enemies")
    local friends = inquiry_known(self:getFriends(), "AG friends")
    local friends_noself = {}
    for _, friend in ipairs(friends) do if friend ~= self.player then friends_noself[#friends_noself + 1] = friend end end
    local function friend(player) return inquiry_relation(self, player) == "friend" end
    local function enemy(player) return inquiry_relation(self, player) == "enemy" end
	local NextPlayerCanUse,NextPlayerisEnemy
	local NextPlayer = self.player:getNextAlive()
	if self.room:getTurnCount()>1 and not required("willSkipPlayPhase",NextPlayer) then
		if friend(NextPlayer) and inquiry_known(inquiry_call(self, "getRoleEstimate", NextPlayer), "AG next-player role")~="neutral"
		then NextPlayerCanUse = true else NextPlayerisEnemy = true end
	end
	for _,enemy in ipairs(enemies)do
		if enemy:hasSkill("lihun")
		and not NextPlayer:faceUp()
		and NextPlayer:getHandcardNum()>4
		and NextPlayer:isMale() and enemy:faceUp()
		then NextPlayerCanUse = false break end
	end
	local cards = {}
	local trickNum = 0
	for _,id in ipairs(card_ids)do
		local c = inquiry_known(self:getChoiceCard(id, options), "AG card")
        -- Native readonly acquisition facts add owner residue/limits without
        -- turning a disclosed offered card into an owned or submit-capable card.
        if type(self.getAcquiredCardEvaluation)=="function"then
            c=self:getAcquiredCardEvaluation(c)or c
        end
		if c:isKindOf("TrickCard") then trickNum = trickNum+1 end
		table.insert(cards,c)
	end
	local nextfriend_num = 0
	local aplayer = self.player:getNextAlive()
	for i=1,self.player:aliveCount()do
		if friend(aplayer) then
			aplayer = aplayer:getNextAlive()
			nextfriend_num = nextfriend_num+1
		else break end
	end

	---------------

	cards = inquiry_known(self:sortByCardNeed(cards,true), "AG card-need order")

	if self:hasSkills("buyi",friends) then
		local maxvaluecard,minvaluecard
		local maxvalue,minvalue = -100,100
		for _,c in ipairs(cards)do
			if c:getTypeId()>1 then
				local value = required("getUseValue",c)
				if value>maxvalue then
					maxvalue = value
					maxvaluecard = c
				end
				if value<minvalue then
					minvalue = value
					minvaluecard = c
				end
			end
		end
		if minvaluecard and NextPlayerCanUse then
			return minvaluecard:getEffectiveId()
		end
		if maxvaluecard then
			return maxvaluecard:getEffectiveId()
		end
	end
	local CP = self.room:getCurrent()
	local SelfisCurrent = CP==self.player
	local friendneedpeach,peach
	if NextPlayerCanUse then
		if not self.player:isWounded() and NextPlayer:isWounded()
		or self.player:getLostHp()<required("getCardsNum","Peach")
		or not SelfisCurrent and required("willSkipPlayPhase") and self.player:getHandcardNum()+2>self.player:getMaxCards()
		then friendneedpeach = true end
	end
	local cid = {}
	local hand = self.player:getHandcards()
	hand = self:sortByKeepValue(hand,true)
	local peachnum,jinknum = 0,0
	for _,c in ipairs(cards)do
		for i,h in ipairs(hand)do
			if i<#hand/2 and required("cardNeed",c)>required("cardNeed",h)
			and required("getCardsNum",c:getClassName())<2
			then return c:getEffectiveId() end
		end
		cid[c:objectName()] = c:getEffectiveId()
		if acquired_is_card("Peach",c) then
			peachnum = peachnum+1
			cid.peach = c:getEffectiveId()
		elseif acquired_is_card("ExNihilo,Dongzhuxianji",c) then
			if not NextPlayerCanUse
			or (not required("willSkipPlayPhase")
				and (self.player:hasSkills("nosjizhi|jizhi|zhiheng|nosrende|rende")
				or not NextPlayer:hasSkills("nosjizhi|jizhi|zhiheng|nosrende|rende")))
			then cid.exnihilo = c:getEffectiveId() end
		elseif acquired_is_card("Jink",c) then
			jinknum = jinknum+1
			cid.jink = c:getEffectiveId()
		elseif acquired_is_card("Snatch",c) then cid.snatch = c
		elseif acquired_is_card("Analeptic",c) then cid.analeptic = c:getEffectiveId()
		elseif acquired_is_card("Dismantlement,Zhujinqiyuan",c) then cid.dismantlement = c
		elseif acquired_is_card("Nullification",c) then cid.nullification = c:getEffectiveId()
		elseif acquired_is_card("Indulgence",c) then cid.indulgence = c:getEffectiveId() end
		if c:isKindOf("Weapon") then cid.weapon = c:getEffectiveId()
		elseif c:isKindOf("Horse") and not self:getSameEquip(c)
		then cid[c:getClassName()] = c:getEffectiveId() end
		for _,skill in sgs.qlist(inquiry_known(self.player:getSkills(), "AG own skills"))do
			local callback = sgs.ai_cardneed[skill:objectName()]
			if type(callback)=="function" and callback(self.player,c,self)
			then return c:getEffectiveId() end
		end
	end
	if (not friendneedpeach and cid.peach) or peachnum>1 then return cid.peach end
	for _,target in sgs.qlist(self.room:getAlivePlayers())do
		if required("willSkipPlayPhase",target)
		or required("willSkipDrawPhase",target) then
			if cid.nullification then return cid.nullification
			elseif cid.snatch
			and friend(target)
			and not required("willSkipPlayPhase")
			and self.player:distanceTo(target)==1
			and required("hasTrickEffective",cid.snatch,target,self.player)
			then return cid.snatch:getEffectiveId()
			elseif cid.dismantlement
			and self.player~=target
			and friend(target)
			and not required("willSkipPlayPhase")
			and required("hasTrickEffective",cid.dismantlement,target,self.player)
			then return cid.dismantlement:getEffectiveId() end
		end
	end
	if SelfisCurrent then
		if cid.exnihilo then return cid.exnihilo end
		if (cid.jink or cid.analeptic)
		and (required("getCardsNum","Jink")<1 or required("isWeak") and required("getOverflow")<1)
		then return cid.jink or cid.analeptic end
		if cid.indulgence then return cid.indulgence end
	else
		local possible_attack = 0
		for _,enemy in ipairs(enemies)do
			if enemy:inMyAttackRange(self.player)
			and required("playerGetRound",CP,enemy)<required("playerGetRound",CP,self.player)
			then possible_attack = possible_attack+1 end
		end
		if possible_attack>required("getCardsNum","Jink") and required("getCardsNum","Jink")<=2 and required("getDefenseSlash")<=2
		then if cid.jink or cid.analeptic or cid.exnihilo then return cid.jink or cid.analeptic or cid.exnihilo end
		elseif cid.exnihilo or cid.indulgence then return cid.exnihilo or cid.indulgence end
	end
	if cid.nullification
	and (required("getCardsNum","Nullification")<2 or not NextPlayerCanUse)
	then return cid.nullification end
	if jinknum<2 and cid.jink and enemy(NextPlayer)
	and NextPlayer:isKongcheng()
	then return cid.jink end
	if cid.eight_diagram then
		local lord = self.room:getLord()
		if not self:hasSkills("yizhong|bazhen")
		and self:hasSkills("tiandu|leiji|nosleiji|noszhenlie|gushou|hongyan")
		and not self:getSameEquip(card) then return cid.eight_diagram end
		if NextPlayerisEnemy
		and self:hasSkills("tiandu|leiji|nosleiji|noszhenlie|gushou|hongyan",NextPlayer)
		and not self:getSameEquip(card,NextPlayer) then return cid.eight_diagram end
		if self.player:getRole()=="loyalist"
		and self.player:getKingdom()=="wei"
		and not self.player:hasSkill("bazhen")
		and lord and lord:hasLordSkill("hujia")
		and (lord:objectName()~=NextPlayer:objectName() and NextPlayerisEnemy or lord:getArmor())
		then return cid.eight_diagram end
	end
	if cid.silver_lion then
		local lightning,canRetrial
		for _,aplayer in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if aplayer:hasSkills("leiji|nosleiji") and enemy(aplayer)
			then return cid.silver_lion end
			if aplayer:containsTrick("lightning")
			then lightning = true end
			if enemy(aplayer)
			and self:hasSkills("guicai|guidao",aplayer)
			then canRetrial = true end
		end
		if lightning and canRetrial then return cid.silver_lion end
		if self.player:isChained() then
			for _,friend in ipairs(friends)do
				if friend:hasArmorEffect("Vine") and friend:isChained()
				then return cid.silver_lion end
			end
		end
		if self.player:isWounded() then return cid.silver_lion end
	end
	if cid.vine then
		if sgs.ai_armor_value.vine(self.player,self)>0
		and self.room:alivePlayerCount()<=3
		then return cid.vine end
	end
	if cid.renwang_shield then
		if sgs.ai_armor_value.renwang_shield(self.player,self)>0 and required("getCardsNum","Jink")<1
		then return cid.renwang_shield end
	end
	if cid.DefensiveHorse
	and (not self.player:hasSkill("leiji|nosleiji") or required("getCardsNum","Jink")<1) then
		local before_num,after_num = 0,0
		for _,enemy in ipairs(enemies)do
			if can_slash(enemy,self.player,nil,true)
			then before_num = before_num+1 end
			if can_slash(enemy,self.player,nil,true,1)
			then after_num = after_num+1 end
		end
		if before_num>after_num and (required("isWeak") or required("getCardsNum","Jink")<1)
		then return cid.DefensiveHorse end
	end
	if cid.analeptic then
		local hit_num = 0
		for _,slash in ipairs(required("getCards","Slash"))do
			local d = self:aiUseCard(slash)
			if d.card then
				hit_num = hit_num+1
				for _,enemy in sgs.qlist(d.to)do
					if getCardsNum("Jink",enemy)<1
					or required("canLiegong",enemy,self.player)
					or self.player:hasSkills("tieji|wushuang|dahe|qianxi")
					or self.player:hasSkill("roulin") and enemy:isFemale()
					or (self.player:hasWeapon("Axe") or required("getCardsNum","Axe")>0) and self.player:getCards("he"):length()>4
					or (self.player:hasWeapon("blade") or required("getCardsNum","Blade")>0) and getCardsNum("Jink",enemy)<=hit_num
					or required("hasCrossbowEffect") and hit_num>=2
					then return cid.analeptic end
				end
			end
		end
	end
	if cid.weapon
	and (required("getCardsNum","Slash")>0 and required("slashIsAvailable") or not SelfisCurrent) then
		local current_range = (self.player:getWeapon() and self.player:getWeapon():getRange()) or 1
		local slash
        if SelfisCurrent then slash = self:getCard("Slash")
        else
            slash = required("getEvaluationCard", "slash")
        end
		enemies = inquiry_known(self:sort(enemies,"defense"), "AG enemy order")
		if cid.crossbow then
			if required("getCardsNum","Slash")>1 or self:hasSkills("kurou|keji")
			or (self:hasSkills("luoshen|yongsi|luoying|guzheng") and not SelfisCurrent and self.room:alivePlayerCount()>=4)
			then return cid.crossbow end
			if self.player:hasSkill("guixin") and self.room:alivePlayerCount()>=6
			and (self.player:getHp()>1 or required("getCardsNum","Peach")>0)
			then return cid.crossbow end
			if self.player:hasSkill("rende") then
				for _,friend in ipairs(friends_noself)do
					if getCardsNum("Slash",friend)>1
					then return cid.crossbow end
				end
			end
			if enemy(NextPlayer) then
				local CanSave,huanggai,zhenji
				for _,enemy in ipairs(enemies)do
					if enemy:hasSkill("buyi") then CanSave = true end
					if enemy:hasSkill("jijiu") and getKnownCard(enemy,self.player,"red",nil,"he")>1 then CanSave = true end
					if enemy:hasSkill("chunlao") and enemy:getPile("wine"):length()>1 then CanSave = true end
					if enemy:hasSkill("kurou") then huanggai = enemy end
					if enemy:hasSkill("keji") then return cid.crossbow end
					if self:hasSkills("luoshen|yongsi|guzheng",enemy) then return cid.crossbow end
					if enemy:hasSkill("luoying") and card:getSuit()~=sgs.Card_Club then return cid.crossbow end
				end
				if huanggai then
					if huanggai:getHp()>2 then return cid.crossbow end
					if CanSave then return cid.crossbow end
				end
				if getCardsNum("Slash",NextPlayer)>=3 and NextPlayerisEnemy then return cid.crossbow end
			end
		end
		if cid.halberd then
			if self.player:hasSkills("nosrende|rende") and self:findFriendsByType(sgs.Friend_Draw)
			then return cid.halberd end
			if SelfisCurrent and required("getCardsNum","Slash")==1 and self.player:getHandcardNum()==1
			then return cid.halberd end
		end
		if cid.gudingdao then
			local range_fix = current_range-2
			for _,enemy in ipairs(enemies)do
				if can_slash(self.player,enemy,slash,true,range_fix)
				and enemy:isKongcheng() and not enemy:hasSkill("tianming")
				and (not SelfisCurrent or (required("getCardsNum","Dismantlement")>0 or (required("getCardsNum","Snatch")>0 and self.player:distanceTo(enemy)==1)))
				then return cid.gudingdao end
			end
		end
		if cid.axe then
			local range_fix = current_range-3
			local FFFslash = self:getCard("FireSlash")
			for _,enemy in ipairs(enemies)do
				if FFFslash and self.player:getCardCount(true)>=3
				and can_slash(self.player,enemy,FFFslash,true,range_fix)
				and required("ajustDamage",self.player,enemy,1,FFFslash)>1
				then return cid.axe
				elseif required("getCardsNum","Analeptic")>0
				and self.player:getCardCount(true)>=4
				and can_slash(self.player,enemy,slash,true,range_fix)
				and required("slashIsEffective",slash,enemy)
				then return cid.axe end
			end
		end
		if cid.double_sword then
			local range_fix = current_range-2
			for _,enemy in ipairs(enemies)do
				if self.player:getGender()~=enemy:getGender()
				and can_slash(self.player,enemy,nil,true,range_fix)
				then return cid.double_sword end
			end
		end
		if cid.qinggang_sword then
			local range_fix = current_range-2
			for _,enemy in ipairs(enemies)do
				if can_slash(self.player,enemy,slash,true,range_fix)
				and required("slashIsEffective",slash,enemy,self.player)
				then return cid.qinggang_sword end
			end
		end
	end
	for _,c in ipairs(cards)do
		if required("evaluateAcquiredCard",c).card
		then return c:getEffectiveId() end
	end
	if cid.weapon and not self.player:getWeapon() and required("getCardsNum","Slash")>0
	and (required("slashIsAvailable") or not SelfisCurrent)
	then
		local inAttackRange
		for _,enemy in sgs.list(enemies)do
			if can_slash(self.player,enemy) then inAttackRange = true break end
		end
		if not inAttackRange then return cid.weapon end
	end
	cid = self:poisonCards(cards)
	for _,c in ipairs(cards)do
		if table.contains(cid,c)
		or c:isKindOf("TrickCard")
		or c:isKindOf("Peach")
		then continue end
		return c:getEffectiveId()
	end
	for _,c in ipairs(cards)do
		if table.contains(cid,c) then continue end
		return c:getEffectiveId()
	end
	return cards[1]:getEffectiveId()
end

-- This source callback is also a real reason-specific entry. Register it in
-- the legacy-ABI table so a truthful native legacy_hook hint reaches the same
-- policy, rather than rejecting before the common default can call it.
ai_choice_legacy_registries.ai_skill_askforag.amazing_grace = function(self, card_ids)
    return self:selectAmazingGracePolicy(card_ids)
end

-- Shared AgCardsToName consumes ov_muyue's scalar declaration cache. An
-- uninitialized cache is the donor's initial nil; no match deliberately falls
-- through askForAG's common policy. Never infer an undisclosed card identity.
ai_choice_legacy_registries.ai_skill_askforag.AgCardsToName = function(self, ids)
    local declaration = rawget(self,"ACTN")
    if declaration == nil then declaration = self:getStrategyMemory("ACTN") end
    for _, id in ipairs(ids) do
        local card = self:getChoiceCard(id)
        if not card then return ai_unsupported("AgCardsToName offered face is unknown", tostring(id)) end
        local name = card:objectName()
        if type(name) ~= "string" then return ai_unsupported("AgCardsToName offered name is unknown", tostring(id)) end
        if declaration == name then return id end
    end
end

-- SmartAI retains target slots when a prompt has no matching player. Keep
-- only names across requests and rebind lawful facades in the current snapshot.
remember_cardask_targets=function(self,prompt,parts)
    if not parts then parts={};for part in(prompt..":"):gmatch("(.-):")do parts[#parts+1]=part end end
    for slot=1,2 do
        local key="askForCard_target"..slot
        local cached,present=self:getStrategyMemory(key)
        local selected=present and cached~=false and self.room:findPlayerByObjectName(cached,true)or nil
        if parts[slot+1]~=nil then
            for _,player in ipairs(inquiry_known(self.room:getPlayers(),"nested cardask roster"))do
                if player:getGeneralName()==parts[slot+1] or player:objectName()==parts[slot+1] then
                    selected=player
                    self:setStrategyMemory(key,player:objectName())
                    break
                end
            end
        end
        if slot==1 then self.target=selected else self.target2=selected end
    end
    self._cardask_targets_current=true
end

local function nested_common_cardask(self,key,proof,pattern,target,target2)
    local lines={["slash-jink"]=786,["collateral-slash"]=2411}
    local line=lines[key]
    if not line then return nil,false end
    if type(proof.source)~="string"or not proof.source:match("/standard_cards%-ai%.lua$")or proof.line~=line then
        return unsupported("nested common cardask source identity changed",key)
    end
    local card
    if key=="slash-jink"then card=common_slash_jink(self,nil,nil,target,1,pattern)
    else card=common_collateral_slash(self,target,target2)end
    if AIUnsupported and AIUnsupported.is(card)then error(card,0)end
    if type(card)=="string"or card==nil then return card,true end
    if not AIValue.isCard(card)and not AIValue.isConversion(card)then return unsupported("nested common policy returned a non-card",key)end
    return inquiry_known(inquiry_call(card,"getLegacyStringKey"),"nested selected card source string"),true
end

-- The effective SP Aocai invoke calls askForCard(pattern,prompt,1): 1 is
-- QVariant data, not MethodUse. Nil method skips the ordinary response search.
-- Keep this narrow source entry independent of native action admission.
function SmartAIView:askForCard(pattern,prompt,data,method)
    if data~=1 or method~=nil then
        return unsupported("nested askForCard signature is not projected","nested_askForCard")
    end
    -- These source operations intentionally retain ordinary Lua argument errors.
    local compulsory=pattern:sub(-1)=="!"
    local parts={};for part in (prompt..":"):gmatch("(.-):")do parts[#parts+1]=part end
    if compulsory then pattern=pattern:sub(1,-2)end
    local context=self:getDecisionContext()
    local invocation=context.aocai_invoke
    local request=self.request
    if type(request)=="table" and request.kind=="skill_invoke"
        and type(request.options)=="table" and request.options.reason=="lianli-slash" then
        invocation=context.lianli_slash_invoke
        if type(invocation)~="table" or invocation.known~=true
            or not AIValue.isList(invocation.asked) or pattern~="slash"
            or prompt~=invocation.asked[2] then
            return unsupported("LianliSlash nested inquiry does not match the native question","nested_askForCard")
        end
    end
    local proof=invocation and invocation.cardask
    if type(proof)~="table" or proof.known~=true or proof.key~=parts[1] then
        return unsupported("nested cardask registry presence is unknown","nested_askForCard")
    end
    remember_cardask_targets(self,prompt,parts)
    if proof.present then
        local callback=sgs.ai_skill_cardask[parts[1]]
        if ai_audited_aliases and ai_audited_aliases.resolve then
            callback=ai_audited_aliases.resolve(self,callback)
        end
        if proof.value_type=="function" then
            local result,handled
            local function run_callback()
                if type(callback)=="function"then
                    return callback(self,data,pattern,self.target,self.target2,parts[4],parts[5])
                end
                return nested_common_cardask(self,parts[1],proof,pattern,self.target,self.target2)
            end
            if type(request)=="table" and request.kind=="skill_invoke"
                and type(request.options)=="table" and request.options.reason=="lianli-slash" then
                if type(SmartAIView.withNestedCardaskIdentity)~="function"then
                    return unsupported("nested readonly identity adapter unavailable","nested_askForCard")
                end
                result,handled=SmartAIView.withNestedCardaskIdentity(self,pattern,prompt,run_callback)
            else result,handled=run_callback()end
            if type(callback)~="function"and not handled then
                return unsupported("nested source cardask is not ported",parts[1])
            end
            if AIUnsupported and AIUnsupported.is(result)then error(result,0)end
            -- Authored pure cardask adapters return branded card values where
            -- the donor returned Card:toString(). Preserve that source ABI only
            -- for those values; ordinary callback tables remain ignored.
            if AIValue.isCard(result)or AIValue.isConversion(result)then
                result=inquiry_known(inquiry_call(result,"getLegacyStringKey"),"nested selected card source string")
            end
            if type(result)=="number" then
                -- Generated SWIG requires a numeric HandlingMethod; the real
                -- donor calls isCardLimited(card,nil) here and raises.
                error("donor askForCard: Player_isCardLimited received nil HandlingMethod",0)
            elseif type(result)=="string" then
                if result=="." then
                    if not compulsory then return "."end
                else
                    if type(ai_inspect_nested_cardask_string)~="function"then
                        return unsupported("nested readonly Card_Parse classifier is unavailable",parts[1])
                    end
                    local parsed=ai_inspect_nested_cardask_string(result)
                    if AIUnsupported and AIUnsupported.is(parsed)then error(parsed,0)end
                    if type(parsed)~="table"or parsed.kind~="nested_card_parse"then
                        return unsupported("nested readonly Card_Parse classification is unknown",parts[1])
                    end
                    if parsed.outcome=="invalid"then
                        if not compulsory then return "."end
                        -- The donor sets should_discard, but then immediately
                        -- calls checklist:isKindOf on that nil parse result.
                        error("donor askForCard: invalid Card_Parse result dereferenced",0)
                    elseif parsed.outcome=="requires_nil_method"then
                        error("donor askForCard: Player_isCardLimited received nil HandlingMethod",0)
                    elseif parsed.outcome=="empty_virtual"then
                        return result
                    end
                    return unsupported("invalid nested Card_Parse classification",parts[1])
                end
            elseif type(result)=="boolean" then
                if result then compulsory=true elseif not compulsory then return "."end
            end
        end
    end
    if compulsory then
        local projection=invocation and invocation.compulsory
        if type(projection)~="table"or projection.known~=true or projection.pattern~=pattern
            or type(projection.by_id)~="table"then
            return unsupported("nested compulsory physical pattern domain is not projected","nested_askForCard")
        end
        local fields={};for field in (pattern.."|"):gmatch("(.-)|")do fields[#fields+1]=field end
        local zone="he"
        if #fields>=4 and fields[4]then
            local places={};for place in(fields[4]..","):gmatch("(.-),")do places[#places+1]=place end
            if #places==1 then
                if places[1]=="hand"then zone="h"elseif places[1]=="equipped"then zone="e"end
            end
        end
        local cards=inquiry_known(self:addHandPile(zone),"nested compulsory source cards")
        cards=inquiry_known(self:sortByKeepValue(cards),"nested compulsory keep order")
        for _,card in ipairs(cards)do
            local id=inquiry_known(card:getEffectiveId(),"nested compulsory card id")
            local matches=projection.by_id[tostring(id)]
            if type(matches)~="boolean"then return unsupported("nested physical pattern match is unknown",tostring(id))end
            if matches then
                error("donor askForCard: Player_isCardLimited received nil HandlingMethod",0)
            end
        end
    end
    return "."
end
