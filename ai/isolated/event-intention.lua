-- Event callbacks consume one viewer-visible snapshot, never filterEvent or sgs.ais.
-- Card callbacks retain (self, CardView, PlayerView, targets); their calls to
-- sgs.updateIntention(s) are collected as values and committed by the host.
-- ai_event_callback[event][key](self, eventPlayer, event) receives a
-- pure event DTO with a strict, public CardUseStruct adapter. ai_damage_intention[reason](self,
-- event) returns a numeric level or a dense delta list. These are explicit pure ABIs.
local max_deltas = 64
local active_sink
local active_refresh
local memory_key = "filter_event"
-- Capture commit functions before package callbacks can replace them.
local memory_prepare, memory_commit, memory_recall = ai_memory.prepare, ai_memory.commit, ai_memory.recall
local sync_flag_clears = ai_sync_strategy_flag_clears
local sgs = assert(rawget(_G, "sgs"))
ai_damage_intention = ai_damage_intention or {}
sgs.ai_damage_intention = ai_damage_intention

-- Standard common evidence magnitudes from standard_cards-ai.lua and
-- maneuvering-ai.lua. Function policies below preserve their common special
-- cases through viewer memory; packages may replace registry entries.
local standard_intentions = {ExNihilo = -80, Indulgence = 120,
    SupplyShortage = 120, FireAttack = 80}
for name, value in pairs(standard_intentions) do
    if sgs.ai_card_intention[name] == nil then sgs.ai_card_intention[name] = value end
end

for _, flag in ipairs({"ShenfenUsing", "FenchengUsing"}) do
    if sgs.ai_damage_from_flag_intention[flag] == nil then
        sgs.ai_damage_from_flag_intention[flag] = 10
    end
end

local function finite(value)
    return type(value) == "number" and value == value
        and value ~= math.huge and value ~= -math.huge
end

-- Unwritten keys use GameReady defaults because this VM receives no GameReady event.
local initial_event_memory = {judge_good = {}, judge_patterns = {}, need_peach = {},
    damage_data = {}, draw_data = {}, convert_data = {}, throw_data = {},
    card_damage_nature = {}, aoe_lord = {}, estimation_branches = {},
    ai_response = {Slash = "Jink"}, is_chained = 0,
    ai_collateral = false, ai_liuli_effect = false, ai_lijian_effect = false, ai_quhu_effect = false}
local initial_nil_event_memory = {card_effect = true, target_use = true, used_data = true,
    filter_source = true, filter_intention = true, filter_level = true,
    nullification_source = true, nullification_intention = true, nullification_level = true,
    ai_liuli_user = true, ai_mobiletongji_user = true, shaoying_target = true, fenji_target = true}

local function initial_value(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for k, v in pairs(value) do result[k] = v end
    return result
end

function SmartAIView:getEventMemory(key)
    local state = rawget(self, "_event_state") or rawget(self, "_strategy_state")
    if not state and type(self.recall) == "function" then
        -- recall hands back a private copy; keep it for this decision's reads and writes.
        state = self:recall(memory_key)
        if state then self._strategy_state, self._strategy_state_owned = state, true end
    end
    if type(state) ~= "table" or type(state.known) ~= "table" or state.known[key] ~= true then
        if initial_event_memory[key] ~= nil then return initial_value(initial_event_memory[key]), true end
        if initial_nil_event_memory[key] then return nil, true end
        return nil, false
    end
    return state[key], true
end

function SmartAIView:setEventMemory(key, value)
    local state = rawget(self, "_event_state")
    assert(type(state) == "table", "event memory writes require an active event")
    assert(type(key) == "string" and key ~= "known", "invalid event memory key")
    state[key], state.known[key] = value, true
end

function SmartAIView:emitStrategyEffect(effect)
    local sink = rawget(self, "_event_effect_sink")
    assert(type(sink) == "function", "strategy event effects require an active event")
    sink(effect)
end

function SmartAIView:updateIntention(from, to, level)
    local from_name = type(from) == "string" and from or from and from:objectName()
    local to_name = type(to) == "string" and to or to and to:objectName()
    if not from_name or not to_name then return end
    if sgs.ai_doNotUpdateIntenion then level=0 end
    sgs.ai_doNotUpdateIntenion=nil
    if from_name == to_name then return end
    assert(finite(level), "intention must be finite")
    if active_sink then active_sink(from_name,to_name,level); return end
    self._strategy_effects = self._strategy_effects or {}
    assert(#self._strategy_effects < max_deltas, "strategy effect limit")
    self._strategy_effects[#self._strategy_effects+1] = {kind="intention",from=from_name,to=to_name,level=level,after_delta=0}
end

local function copy_memory(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, item in pairs(value) do result[key] = copy_memory(item) end
    return result
end

-- A clear epoch witnesses a completed public gameplay operation. Apply it before
-- opening the policy event transaction: a later callback failure must not revive
-- stale flags. The acknowledgement and all affected caches share one replacement.
local function synchronize_flag_memory(world, epochs)
    assert(active_sink == nil, "flag synchronization requires an idle event transaction")
    local viewer = world.self.object_name
    local state = memory_recall(viewer, memory_key) or {known={}}
    local applied = state.strategy_flag_clear_epochs or {}
    if type(applied) ~= "table" or getmetatable(applied) ~= nil then
        ai_unsupported("malformed applied flag-clear epoch map", "strategy_flag_clear_epochs")
    end
    local changed = {}
    for name, epoch in pairs(epochs) do
        local previous = applied[name] or 0
        if not (finite(previous) and previous >= 0 and previous % 1 == 0 and epoch >= previous) then
            ai_unsupported("regressed or malformed applied flag-clear epoch", "strategy_flag_clear_epochs")
        end
        if epoch > previous then changed[#changed+1] = name end
    end
    if #changed == 0 then return false end
    state = copy_memory(state)
    state.known = state.known or {}
    state.strategy_flag_clear_epochs = copy_memory(applied)
    local ganglie = state["cache:ling.ganglie_targets"]
    for _, name in ipairs(changed) do
        if state.known["cache:ling.ganglie_targets"] == true and type(ganglie) == "table" then
            ganglie[name] = nil
        end
        state.strategy_flag_clear_epochs[name] = epochs[name]
    end
    local token = memory_prepare(viewer, memory_key, state)
    memory_commit(token)
    return true
end
if type(ai_register_flag_clear_synchronizer) == "function" then
    ai_register_flag_clear_synchronizer(synchronize_flag_memory)
end

local function keep_state_format(self)
    local facts = self.world and AIHegemony.facts(self.world)
    return facts and facts.enabled == true and facts.original_overrides_loaded == true
        and "original_hegemony" or "ordinary"
end

-- The donor keep-skill cache contains only computed scalar contributions.
-- Preserve it in the same observer envelope as keepValue, never a CardView or
-- a native rule/authority descriptor. Validate before publishing restored state.
local function keep_skill_cache(self, cache)
    if cache == nil then return nil end
    local function malformed()
        ai_unsupported("numeric keep-skill cache is malformed", "keep_state.keep_skill_eval_cache")
    end
    if type(cache) ~= "table" or getmetatable(cache) ~= nil then malformed() end
    local result = {}
    for owner, entries in pairs(cache) do
        if type(owner) ~= "string" or owner == "" or not self.room:findPlayerByObjectName(owner, true)
            or keep_state_format(self) ~= "ordinary"
            or type(entries) ~= "table" or getmetatable(entries) ~= nil then malformed() end
        local values = {}
        for key, row in pairs(entries) do
            if type(key) ~= "string" or key == "" or type(row) ~= "table" or getmetatable(row) ~= nil then malformed() end
            for field in pairs(row) do
                if field ~= "ci" and field ~= "cvsum" and field ~= "suit_add" and field ~= "number_add" then malformed() end
            end
            if not finite(row.ci) or row.ci < 0 or row.ci % 1 ~= 0
                or not finite(row.cvsum) or not finite(row.suit_add) or not finite(row.number_add) then malformed() end
            values[key] = {ci=row.ci, cvsum=row.cvsum, suit_add=row.suit_add, number_add=row.number_add}
        end
        result[owner] = values
    end
    return result
end

function SmartAIView:restoreEventKeepState()
    local value, known = self:getEventMemory("keep_state")
    if known and type(value) == "table" then
        -- Ordinary SmartAI keys keepValue by its card-string cache; Original
        -- uses numeric effective IDs. Never substitute one method's cache for
        -- another after the admitted mode's per-request helpers are installed.
        if (value.format or "ordinary") ~= keep_state_format(self) then return false end
        local skill_cache = keep_skill_cache(self, value.keep_skill_eval_cache)
        for _, entry in ipairs(value.estimates or {}) do
            local estimate = copy_memory(entry)
            estimate.status, estimate.value, estimate.count = "estimate", true, nil
            self:useKnowledgeEstimate(estimate, entry.context or "keep_state.cached")
        end
        self.keepdata, self.keepValue = value.keepdata, value.keepValue
        self._keep_skill_eval_cache = skill_cache
        if type(value.kept) == "table" then
            local kept = {}
            for _, row in ipairs(value.kept) do
                local card = type(self.getKnownCardById) == "function" and self:getKnownCardById(row.id)
                if not card then
                    if type(row.card) ~= "table" then
                        ai_unsupported("kept card has neither current disclosure nor historical face", "keep_state.kept")
                    end
                    local historical = copy_memory(row.card)
                    historical.evaluation_only = true
                    historical.evaluation_owner = self.player:objectName()
                    card = assert(CardView.new(historical), "historical kept card is malformed")
                    self:useKnowledgeEstimate({status="estimate", value=true, card_id=row.id,
                        basis="keep_state.historical_card_face_not_currently_disclosed"}, "keep_state.kept")
                end
                kept[#kept+1] = card
            end
            self.kept = kept
        end
    end
    return known
end

-- assignKeep mutates the donor's observer cache even if its eventual answer is
-- rejected. Preserve that decision-time observation, but use the same atomic
-- envelope when assignKeep is called while filtering a CardsMove event.
-- A decision's first memory write copies the recalled state; later writes update
-- that private copy in place. ai_decide persists it once (flushDecisionMemory).
local function decision_state(self)
    local state = rawget(self, "_strategy_state")
    if not rawget(self, "_strategy_state_owned") then
        state = copy_memory(state or self:recall(memory_key) or {known={}})
        self._strategy_state, self._strategy_state_owned = state, true
    end
    state.known = state.known or {}
    self._strategy_state_dirty = true
    return state
end

-- A decision writes its keep state once, when its handler returns; an event
-- writes it into its own memory envelope at once.
function SmartAIView:persistKeepState()
    if not rawget(self, "_event_state") then
        self._keep_state_dirty = true
        return true
    end
    return self:writeKeepState()
end

function SmartAIView:flushDecisionMemory()
    if rawget(self, "_keep_state_dirty") then
        self._keep_state_dirty = nil
        self:writeKeepState()
    end
    if rawget(self, "_strategy_state_dirty") then
        self._strategy_state_dirty = nil
        return self:remember(memory_key, self._strategy_state)
    end
end

function SmartAIView:writeKeepState()
    local skill_cache = keep_skill_cache(self, self._keep_skill_eval_cache)
    local scratch = self.request and self.request.scratch
    local value = {keepdata=copy_memory(self.keepdata), keepValue=copy_memory(self.keepValue),
        keep_skill_eval_cache=skill_cache,
        format=keep_state_format(self), estimates=copy_memory(scratch and scratch.knowledge_estimates or {})}
    if type(self.kept) == "table" then
        value.kept = {}
        for _, card in ipairs(self.kept) do
            local id = card:getEffectiveId()
            assert(finite(id) and id >= 0 and id % 1 == 0, "kept cards must have physical identities")
            local source, face = rawget(card, "_view"), {}
            if type(source) == "table" then
                -- Only an already disclosed identity is remembered. Never keep
                -- candidate/rule maps, conversion receipts or source authority.
                for _, key in ipairs({"id", "effective_id", "name", "class_name", "kind_of", "type_id",
                    "suit", "number", "red", "black", "skill_name", "skill_names", "skill_names_complete",
                    "known_flags", "flags_complete", "flags_complete_scope", "legacy_string_key", "legacy_sort_key"}) do
                    if source[key] ~= nil then face[key] = copy_memory(source[key]) end
                end
                face.id, face.effective_id, face.virtual_card, face.subcards = id, id, false, {}
            end
            value.kept[#value.kept+1] = {id=id, card=next(face) and face or nil}
        end
    end
    if rawget(self, "_event_state") then return self:setEventMemory("keep_state", value) end
    local state = decision_state(self)
    state.keep_state, state.known.keep_state = value, true
    return true
end

-- These are observational caches: like the donor, decision-time evaluation
-- persists them even if its later card choice is rejected. Event callbacks
-- instead stage the same cache in the event's atomic memory envelope.
function SmartAIView:getStrategyMemory(key)
    return self:getEventMemory("cache:"..key)
end

function SmartAIView:setStrategyMemory(key, value)
    assert(type(key) == "string" and key ~= "", "invalid strategy cache key")
    if rawget(self, "_event_state") then return self:setEventMemory("cache:"..key, value) end
    if rawget(self, "_defense_refresh_active") then
        local state=assert(rawget(self,"_strategy_state"))
        state["cache:"..key],state.known["cache:"..key]=copy_memory(value),true
        return
    end
    local state = decision_state(self)
    state["cache:"..key], state.known["cache:"..key] = copy_memory(value), true
    return true
end

-- Original decision callbacks write these globals before the engine accepts
-- their answer. Retain that observational timing in the viewer envelope; during
-- event callbacks the same write joins the existing atomic event transaction.
function SmartAIView:setCommonEventMemory(key,value)
    local allowed={ai_liuli_effect="boolean",ai_lijian_effect="boolean",ai_liuli_user="player"}
    local kind=allowed[key]
    assert(kind,"unsupported common event observation")
    if kind=="player" then
        if type(value)=="table" and type(value.objectName)=="function" then value=value:objectName() end
        assert(value==nil or type(value)=="string" and self.room:findPlayerByObjectName(value,true),"invalid observed player")
    else assert(type(value)=="boolean","invalid observed boolean") end
    if rawget(self,"_event_state") then return self:setEventMemory(key,value) end
    local state=decision_state(self)
    state[key],state.known[key]=value,true
    return true
end

-- Source askForDiscard records the requested minimum before invoking a skill
-- callback, even if that callback later fails or its selected cards are rejected.
function SmartAIView:recordDiscardDemand(reason, minimum)
    assert(type(reason)=="string" and finite(minimum) and minimum>=0 and minimum%1==0,
        "invalid discard demand statistic")
    local event_state=rawget(self,"_event_state")
    local state=event_state and copy_memory(event_state) or decision_state(self)
    state.known=state.known or {}
    if state.known.throw_data~=true then
        state.throw_data={}
        state.throw_data_initial_history_unknown=true
    elseif type(state.throw_data)~="table" then
        ai_unsupported("discard observation history is malformed","throw_data")
    end
    local previous=state.throw_data[reason]
    if previous~=nil and (not finite(previous) or previous<0) then
        ai_unsupported("discard observation statistic is malformed","throw_data")
    end
    local total=(previous or 0)+minimum
    assert(finite(total),"discard demand statistic overflow")
    state.throw_data[reason],state.known.throw_data=total,true
    -- Donor throwData includes every AI in its VM. A complete local history
    -- still cannot observe another viewer's private discard questions.
    state.throw_data_viewer_only=true
    self:useKnowledgeEstimate({status="estimate",value=total,reason=reason,
        basis="throw_data.viewer_only_aggregate"},"recordDiscardDemand")
    if state.throw_data_initial_history_unknown then
        self:useKnowledgeEstimate({status="estimate",value=total,reason=reason,
            basis="throw_data.unobserved_initial_viewer_history"},"recordDiscardDemand")
    end
    if event_state then
        self:setEventMemory("throw_data",state.throw_data)
        self:setEventMemory("throw_data_viewer_only",true)
        self:setEventMemory("throw_data_initial_history_unknown",state.throw_data_initial_history_unknown)
    end
    return total
end

local function defense_refresh_cache(self,player)
    -- One cache per board revision stands in for SmartAI's one-second clock.
    local now=self.world and self.world.revision
    local turn=self.world and self.world.turn_count
    if type(now)~="string" or not finite(turn) then ai_unsupported("defense cache revision/turn is unknown","getDefense") end
    local cache,known=self:getStrategyMemory("defense_refresh_cache")
    if not known or type(cache)~="table" or cache.clock~=now then
        cache={clock=now,values={}}
        self:setStrategyMemory("defense_refresh_cache",cache)
    end
    local name=type(player)=="string" and player or player:objectName()
    return cache,name.."_"..turn
end

function SmartAIView:getDefenseRefreshCache(player)
    local cache,key=defense_refresh_cache(self,player)
    if cache.values[key]~=nil and type(self.useKnowledgeEstimate)=="function" then
        for _, entry in ipairs(cache.estimates and cache.estimates[key] or {}) do
            local estimate=copy_memory(entry)
            estimate.status,estimate.value="estimate",cache.values[key]
            estimate.count=nil -- replay one dependency, not a previous request's occurrence count
            self:useKnowledgeEstimate(estimate,entry.context or "getDefense.cached")
        end
    end
    return cache.values[key]
end

function SmartAIView:setDefenseRefreshCache(player,value)
    assert(finite(value),"defense cache must be finite")
    local cache,key=defense_refresh_cache(self,player)
    cache.values[key]=value
    local scratch=self.request and self.request.scratch
    cache.estimates=cache.estimates or {}
    cache.estimates[key]=copy_memory(scratch and scratch.knowledge_estimates or {})
    self:setStrategyMemory("defense_refresh_cache",cache)
end

-- The snapshot's controller field is already the root of the Controller_Name chain.
function SmartAIView:getActualController(player)
    if not player then return nil end
    local view=rawget(player,"_view")
    local name=type(view)=="table" and view.controller
    if type(name)~="string" then ai_unsupported("controller root is not projected", "getActualController") end
    if name=="" then return player end
    local controller=self.room:findPlayerByObjectName(name,true)
    if not controller then ai_unsupported("controller root is outside the lawful roster", "getActualController") end
    return controller
end

function SmartAIView:isDualControlLinked(first, second)
    if not first or not second then return false end
    local a,b = self:getActualController(first), self:getActualController(second)
    if not a or not b then return false end
    return a:objectName() == second:objectName() or b:objectName() == first:objectName() or a:objectName() == b:objectName()
end

function SmartAIView:getLordHealthLevel()
    for _, player in ipairs(self.room:getAlivePlayers()) do
        if player:isLord() then
            local hp = player:getHp()
            if hp>4 and player:hasSkill("benghuai") then hp=4 end
            return hp<=1 and 0 or hp==2 and 1 or hp==3 and 2 or 3
        end
    end
    return 3
end

local function queue_role_effect(self, effect)
    if rawget(self,"_event_effect_sink") then return self:emitStrategyEffect(effect) end
    self._strategy_effects=self._strategy_effects or {}
    assert(#self._strategy_effects<max_deltas,"strategy effect limit")
    effect.after_delta=0
    self._strategy_effects[#self._strategy_effects+1]=effect
end

function SmartAIView:adjustAIRole()
    return queue_role_effect(self,{kind="role_refresh",adjust=true})
end

function SmartAIView:evaluateAlivePlayersRole()
    return queue_role_effect(self,{kind="role_refresh",force=true})
end

SmartAIView.refreshAIsAfterIntention = SmartAIView.evaluateAlivePlayersRole

function SmartAIView:updateAlivePlayerRoles()
    local counts=self:getRoleCounts()
    if type(counts)~="table" then ai_unsupported("public role counts are unknown","updateAlivePlayerRoles") end
    self.playerRoles=copy_memory(counts)
    return self.playerRoles
end

local function defense_snapshot_complete(self)
    local snapshot, known = self:getEventMemory("defense_snapshot")
    if known ~= true or type(snapshot) ~= "table" then return false end
    for _, player in ipairs(self.room:getAllPlayers(true) or {}) do
        if snapshot[player:objectName()] == nil then return false end
    end
    return true
end

function SmartAIView:refreshDefenseSnapshotForSort(players, initialize_only)
    if #players < 2 and not initialize_only then return true end
    -- The board revision stands in for SmartAI's one-second sort clock: a sort
    -- refreshes the baselines once per revision.
    local now = self.world and self.world.revision
    if type(now) ~= "string" then ai_unsupported("defense sort needs the board revision", "sort.defense") end
    -- A complete baseline already refreshed at this revision would come out of
    -- the pass below unchanged; skip its deep copy of the viewer memory.
    if defense_snapshot_complete(self) then
        if initialize_only then return true end
        local sorted_at, sorted_known = self:getEventMemory("defense_sort_time")
        if sorted_known == true and sorted_at == now then return true end
    end
    local event_state = rawget(self, "_event_state")
    local previous, previous_owned = rawget(self, "_strategy_state"), rawget(self, "_strategy_state_owned")
    local state = copy_memory(event_state or previous or self:recall(memory_key) or {known={}})
    state.known = state.known or {}
    -- Baselines start at zero for each player this observer has not sorted yet.
    state.defense_snapshot = state.defense_snapshot or {}
    state.defense_estimates = state.defense_estimates or {}
    for _, player in ipairs(self.room:getAllPlayers(true) or {}) do
        local name = player:objectName()
        if state.defense_snapshot[name] == nil then
            state.defense_snapshot[name] = 0
            state.defense_estimates[name] = {}
        end
    end
    state.known.defense_snapshot, state.known.defense_sort_time = true, true
    state.known.defense_estimates = true
    local field = event_state and "_event_state" or "_strategy_state"
    self[field] = state
    self._defense_refresh_active = true
    local ok, failure = pcall(function()
        if not initialize_only and state.defense_sort_time ~= now then
            for _, player in ipairs(players) do
                -- Collect this cell's dependencies independently of earlier cells.
                local scratch = self.request and self.request.scratch
                local previous_estimates = scratch and scratch.knowledge_estimates
                if scratch then scratch.knowledge_estimates = {} end
                local ok_value, value = pcall(self.getDefense, self, player, true)
                local dependencies = copy_memory(scratch and scratch.knowledge_estimates or {})
                if scratch then scratch.knowledge_estimates = previous_estimates end
                if not ok_value then error(value, 0) end
                if not finite(value) then ai_unsupported("defense refresh returned unknown", "sort.defense") end
                local labels, seen = {}, {}
                for _, entry in ipairs(dependencies) do
                    if type(entry.basis) == "string" and not seen[entry.basis] then
                        labels[#labels+1], seen[entry.basis] = entry.basis, true
                    end
                    self:useKnowledgeEstimate(entry, entry.context or "sort.defense")
                end
                state.defense_snapshot[player:objectName()] = value
                state.defense_estimates[player:objectName()] = labels
            end
            state.defense_sort_time = now
        end
    end)
    self._defense_refresh_active = nil
    if not ok then
        self[field] = event_state or previous
        if not event_state then self._strategy_state_owned = previous_owned end
        error(failure,0)
    end
    if not event_state then
        -- Decision-time sort updates are the source helper's own persistent
        -- strategy side effect. They contain only this observer's derived values.
        self._strategy_state_owned, self._strategy_state_dirty = true, true
    end
    return true
end


function SmartAIView:ensureDefenseSnapshot()
    local snapshot, known = self:getEventMemory("defense_snapshot")
    return self:refreshDefenseSnapshotForSort({}, true)
end

local function estimate_branch(self, name)
    local event_estimates, seen = rawget(self, "_event_estimates"), rawget(self, "_event_estimates_seen")
    if event_estimates and not seen[name] then
        assert(#event_estimates < max_deltas, "too many event estimate branches")
        seen[name] = true; event_estimates[#event_estimates+1] = name
    end
    local branches, known = self:getEventMemory("estimation_branches")
    if not known then branches = {} end
    branches[name] = true
    self:setEventMemory("estimation_branches", branches)
    if type(self.useKnowledgeEstimate) == "function" then
        self:useKnowledgeEstimate({value=true,status="estimate",basis=name,observer=self.player:objectName()}, "filterEvent")
    end
end

local function memory_value(self, key)
    local value, known = self:getEventMemory(key)
    if not known then ai_unsupported("event history is incomplete: " .. key, "event.memory") end
    return value
end

local function state_table(self, key)
    local value = memory_value(self, key)
    assert(type(value) == "table", "event memory needs a table: " .. key)
    return value
end

local function source_attribution(self, event)
    local details = event.details or {}
    if details.intention_from_complete ~= true or type(details.intention_from) ~= "string" then
        if details.intention_from_private == true then
            estimate_branch(self, "attribution.hidden_skill_owner_uses_visible_holder")
            local reason = event.reason ~= "" and event.reason or event.card_skill
            for _, player in ipairs(self.room:getAllPlayers() or {}) do
                if player:hasSkill(reason) == true then return player:objectName() end
            end
            return ""
        end
        -- The reason skill's holder among players whose skills this observer
        -- sees in full; "" when nobody holds it.
        local skill = event.reason ~= "" and event.reason or event.card_skill or ""
        for _, player in ipairs(self.room:getAllPlayers(true) or {}) do
            local has = player:hasSkill(skill)
            if has == nil or player._view.skills_complete == false then
                ai_unsupported("event skill-owner attribution is not projected", "event.attribution")
            end
            if has then return player:objectName() end
        end
        return ""
    end
    return details.intention_from
end

local function card_use_value(event)
    return {from = event.from, targets = event.targets or {}, card = event.details and event.details.card}
end

local function initialize_event_memory(self)
    for key, value in pairs(initial_event_memory) do
        if self._event_state.known[key] ~= true then self:setEventMemory(key, initial_value(value)) end
    end
    for key in pairs(initial_nil_event_memory) do
        if self._event_state.known[key] ~= true then self:setEventMemory(key, nil) end
    end
end

local query = AIValue.bindQuery {
    missing = function(method) ai_unsupported("event helper is unavailable: " .. method, "event.policy") end,
    known = function(value, method)
        if value == nil then ai_unsupported("event fact is unknown: " .. method, "event.policy") end
        return value
    end,
}

local function slash_intention(self, card, from, targets)
    for _, key in ipairs({"ai_liuli_user", "ai_mobiletongji_user"}) do
        local redirected = memory_value(self, key)
        if redirected then
            sgs.updateIntention(from, redirected, 10)
            self:setEventMemory(key, nil)
            return
        end
    end
    if memory_value(self, "ai_collateral") then self:setEventMemory("ai_collateral", false); return end
    local skill = query(card, "getSkillName")
    if skill:match("huqi") or skill:match("mizhao") or query(card, "hasFlag", "nosjiefan-slash") then return end
    for _, target in ipairs(targets) do
        local damage = math.abs(query(self, "ajustDamage", from, target, 1, card))
        local qiuyuan = query(self, "hasQiuyuanEffect", from, target)
        local friendly_hit = false
        if qiuyuan and damage < 2 then
            local rebel = query(self, "hasExplicitRebel")
            if not rebel then
                local policy = self.world and self.world.mode_policy
                rebel = policy and policy.explicit_renegade
                if type(rebel) ~= "boolean" then ai_unsupported("explicit renegade inference is unknown", "event.slash") end
            end
            friendly_hit = rebel and not query(self, "canLiegong", target, from)
        end
        if not (friendly_hit or damage == 1 and query(self, "needToLoseHp", target, from, card, true)
            or query(target, "getHp") > 2 + damage and query(from, "hasSkill", "pojun")) then
            local level = 80
            if query(self, "needLeiji", target, from) then
                level = query(from, "getState") == "online" and 0 or -10
            end
            if query(target, "isLord") and query(self.room, "getTurnCount") < 2 and query(target, "hasSkill", "fangzhu") then level = 10 end
            sgs.updateIntention(from, target, level)
        end
    end
end

local function peach_intention(self, card, from, targets)
    for _, target in ipairs(targets) do
        if not query(target, "hasSkill", "wuhun") then
            if from:objectName() ~= target:objectName() then
                self:emitStrategyEffect({kind="peach_renegade", from=from:objectName(), to=target:objectName()})
            end
            sgs.updateIntention(from, target, -120)
        end
    end
end

local function duel_intention(self, card, from, targets)
    if query(card, "getSkillName"):find("lijian", 1, true) then return end
    sgs.updateIntentions(from, targets, 66)
end

local function iron_chain_intention(self, card, from, targets)
    for _, target in ipairs(targets) do
        local level = -60
        if not query(target, "isChained") then
            level = 60
            if #targets > 1 and (query(target, "hasSkill", "danlao") or query(self, "hasHuangenEffect", target)) then level = -30 end
        end
        sgs.updateIntention(from, target, level)
    end
end

local function drowning_intention(self, card, from, targets)
    for _, target in ipairs(targets) do
        if query(self, "hasTrickEffective", card, target, from) and not query(self, "needToThrowArmor", target) then
            sgs.updateIntention(from, target, 80)
        end
    end
end

for name, callback in pairs({Slash = slash_intention, FireSlash = slash_intention, ThunderSlash = slash_intention,
    Peach = peach_intention, Duel = duel_intention, IronChain = iron_chain_intention, Drowning = drowning_intention}) do
    if sgs.ai_card_intention[name] == nil then sgs.ai_card_intention[name] = callback end
end

local function player_name(value)
    if type(value) == "string" then return value end
    if AIValue.isPlayer(value) then return value:objectName() end
    error("intention requires a player name or PlayerView", 0)
end

function sgs.updateIntention(from, to, level, defer_refresh)
    assert(active_sink, "intention updates require an active isolated event")
    if from == nil or to == nil then return end
    if sgs.ai_doNotUpdateIntenion then level=0 end
    sgs.ai_doNotUpdateIntenion=nil
    return active_sink(player_name(from), player_name(to), level, defer_refresh)
end

function sgs.updateIntentions(from, targets, level)
    for _, target in ipairs(targets) do sgs.updateIntention(from, target, level, true) end
    active_refresh()
end

local function append_answer(answer, event, emit)
    if answer == nil then return end
    if type(answer) == "number" then
        emit(event.from, event.to, answer)
        return
    end
    assert(type(answer) == "table" and getmetatable(answer) == nil,
        "event callback result must be a plain delta array")
    local count = 0
    for key in pairs(answer) do
        assert(type(key) == "number" and key % 1 == 0 and key >= 1 and key <= #answer,
            "event callback result must be a dense delta array")
        count = count + 1
        assert(count <= max_deltas, "too many event intention deltas")
    end
    assert(count == #answer, "event callback result is sparse")
    for _, delta in ipairs(answer) do
        assert(type(delta) == "table" and getmetatable(delta) == nil,
            "event intention delta must be plain")
        local fields = 0
        for key in pairs(delta) do
            assert(key == "from" or key == "to" or key == "level", "invalid intention field")
            fields = fields + 1
        end
        assert(fields == 3, "incomplete intention delta")
        emit(delta.from, delta.to, delta.level)
    end
end

local function resolve_event_alias(self, callback)
    if ai_audited_aliases then return ai_audited_aliases.resolve(self, callback) end
    return callback
end

local function card_callback(self, event)
    local card = event.details and event.details.card
    local class = event.card_class ~= "" and event.card_class or card and card.class_name
    local callback = resolve_event_alias(self, sgs.ai_card_intention[class or ""])
    -- ActiveSkillCard dispatch uses the skill override before the class handler.
    local active = class == "ActiveSkillCard"
    for _, kind in ipairs(card and card.kind_of or {}) do
        if kind == "ActiveSkillCard" then active = true break end
    end
    if active then
        local activation = resolve_event_alias(self, sgs.ai_card_intention[event.card_skill or ""])
        if activation then return activation end
        if not card then ai_unsupported("active card metadata is not projected", "event.card_intention") end
        if type(card.source_skill) ~= "string" then
            -- The source/root may genuinely be another player's private skill.
            -- User-authorized public-class inference keeps this distinguishable
            -- from exact activation→source→class dispatch in the event trace.
            estimate_branch(self, "card_intention.private_source_uses_public_class")
            return callback
        end
        callback = resolve_event_alias(self, sgs.ai_card_intention[card.source_skill]) or callback
    end
    return callback
end

local function suppression_estimate(self,branch)
    if rawget(self,"_event_state") then estimate_branch(self,branch)
    else self:useKnowledgeEstimate({value=false,status="estimate",basis=branch,
        observer=self.player:objectName()},"shouldSuppressIntention") end
end

-- These flags include private speculative AI state. Only the card actor's
-- complete projection proves absence; a foreign omission is not a false fact.
-- Keep each reached flag distinct in telemetry and preserve donor short circuits.
local function suppression_card_flag(self, card, from, name)
    local value = card:hasFlag(name)
    if type(value) == "boolean" then return value end
    local actor = type(from) == "string" and from or from and from:objectName()
    if actor == self.player:objectName() then
        ai_unsupported("own intention suppression flag is not projected: " .. name, "event.card_intention")
    end
    suppression_estimate(self,"intention.private_card_flag."..name)
    return false
end

local function suppress_card_intention(self, event, card, from, targets)
    if suppression_card_flag(self, card, from, "AIGlobal_ComboFallback") then return true end
    local details = event.details or {}
    local function target_fact(target, field, method)
        local row = details.target_facts and details.target_facts[target:objectName()]
        if row and row[field] ~= nil then return row[field] end
        return query(from, method, target)
    end
    if not card:isKindOf("GlobalEffect") and not card:isKindOf("AOE") then
        for _, target in ipairs(targets) do
            if query(target, "hasSkill", "spjili") and target_fact(target, "distance_from", "distanceTo") == 1 then return true end
        end
    end
    if card:isKindOf("Slash") then
        for _, target in ipairs(targets) do
            if query(target, "hasSkill", "lolita") and target_fact(target, "in_from_attack_range", "inMyAttackRange") then return true end
        end
    end
    local zenhui=details.zenhui_user
    if type(zenhui)~="boolean" then
        if details.zenhui_user_private==true then
            suppression_estimate(self,"intention.private_source_flag.ZenhuiUser")
            zenhui=false
        elseif from:objectName()==self.player:objectName() then
            local key=query(card,"getLegacyStringKey")
            zenhui=query(from,"hasFlag","ZenhuiUser_"..key)
        else
            ai_unsupported("card-specific Zenhui source flag is unknown", "event.card_intention")
        end
    end
    if zenhui then return true end
    -- Keep this getter after the flag and target predicates: an early true
    -- suppression never needs the possibly private source/root skill chain.
    local names=details.card_skills
    local complete=details.card_skills_complete
    if names==nil then
        names=query(card,"getSkillNames")
        local row=rawget(card,"_view")
        if type(row)=="table" then complete=row.skill_names_complete end
    end
    if type(names)~="table" then ai_unsupported("card skill names are unknown", "event.card_intention") end
    if complete==false then
        suppression_estimate(self,"card_skill_chain_private.public_activation_only_private_skill_chain")
    end
    for _, name in ipairs(names) do if sgs.ai_suppress_intention[name] then return true end end
    for _, name in ipairs({"meihuomoyan", "sgkgodshunshi", "kenewmieyao"}) do
        if suppression_card_flag(self, card, from, name) then return true end
    end
    for _, target in ipairs(targets) do if query(target,"getMark","geass_target") > 0 then return true end end
    if memory_value(self, "ai_liuli_effect") then self:setCommonEventMemory("ai_liuli_effect", false); return true end
    if memory_value(self, "ai_lijian_effect") then self:setCommonEventMemory("ai_lijian_effect", false); return true end
    return false
end

function SmartAIView:shouldSuppressIntention(use)
    assert(type(use) == "table" and use.card and use.from, "card use requires pure views")
    local event = rawget(self, "_event_input")
    if not event then
        event = {details={zenhui_user=use.zenhui_user,zenhui_user_private=use.zenhui_user_private}}
    end
    return suppress_card_intention(self,event,use.card,use.from,use.to or use.targets or {})
end

-- SmartAI credits intention only when TargetSpecified carries the card its user
-- declared at the latest PreCardUsed; the event log holds both stages.
local function use_matches_previous(world, event)
    local events = type(world.events) == "table" and world.events or {}
    for index = #events, 1, -1 do
        local previous = events[index]
        if previous.sequence < event.sequence and previous.trigger_event == sgs.PreCardUsed
            and previous.kind == "card_use" then
            if previous.from ~= event.from then return false end
            local left, right = previous.card_ids or {}, event.card_ids or {}
            if #left > 0 or #right > 0 then
                if #left ~= #right then return false end
                for i, id in ipairs(left) do if right[i] ~= id then return false end end
                return true
            end
            return previous.card_name == event.card_name and previous.card_class == event.card_class
                and previous.card_skill == event.card_skill
        end
    end
    return false
end

local function card_intention(self, event, emit)
    local details = event.details or {}
    if not use_matches_previous(self.world, event) then return end
    local from = self.room:findPlayerByObjectName(event.from, true)
    if not from then return end
    local card = assert(details.card and CardView.new(details.card), "card intention needs metadata")
    local targets = {}
    for _, name in ipairs(event.targets or {}) do targets[#targets + 1] = assert(self.room:findPlayerByObjectName(name, true)) end
    if suppress_card_intention(self, event, card, from, targets) then return end
    local callback = card_callback(self, event)
    if type(callback) == "number" then
        sgs.updateIntentions(from, targets, callback)
    elseif type(callback) == "function" then callback(self, card, from, targets)
    elseif callback ~= nil then error("invalid card intention callback", 0) end
    if event.card_name ~= "collateral" then self:setEventMemory("ai_collateral", false) end
end

local function target_bookkeeping(self, event)
    local card = assert(event.details and event.details.card and CardView.new(event.details.card), "target use needs metadata")
    if not query(card, "isDamageCard") then return end
    local from = assert(self.room:findPlayerByObjectName(event.from, true))
    local function rescue_count(target)
        if from:objectName() ~= self.player:objectName() then
            estimate_branch(self,"target_bookkeeping.rescue_count_observer_substitution")
        end
        return query(self,"estimateCardsNum","Peach,Analeptic",target,from)
    end
    if query(self, "getRoleEstimate", from) == "rebel" then
        local next_alive = query(from, "getNextAlive")
        if not query(self, "isFriend", next_alive) then
            for _, name in ipairs(event.targets or {}) do
                local target = assert(self.room:findPlayerByObjectName(name, true))
                if query(target, "getHp") < 2 and query(target, "isKongcheng")
                    and query(self, "getRoleEstimate", target) == "rebel" and query(self, "isFriend", target)
                    and query(self, "isGoodTarget", target, nil, card)
                    and rescue_count(target) < 1
                    and query(self, "getEnemyNumBySeat", from, target) > 0 then
                    self:emitStrategyEffect({kind="strategy_flag", player=name, name="AI_doNotSave", value=true})
                end
            end
        end
    end
    if card:isKindOf("AOE") then
        self.aoeTos = AIList.new({})
        local includes = {}
        for _, name in ipairs(event.targets or {}) do
            self.aoeTos:append(assert(self.room:findPlayerByObjectName(name, true))); includes[name] = true
        end
        local lord = self.room:getLord()
        if lord and query(lord, "getHp") < 2 and includes[lord:objectName()]
            and query(self, "aoeIsEffective", card, lord, from) then
            local values = state_table(self, "aoe_lord")
            values[event.card_class] = true
            self:setEventMemory("aoe_lord", values)
        end
        self.aoeTos = nil
    end
end

local function choice_bookkeeping(self, event)
    local details = event.details or {}
    if details.fenxin_invoked ~= true then return end
    if details.fenxin_target_complete ~= true or type(details.fenxin_target) ~= "string" then
        estimate_branch(self, "fenxin.undisclosed_target_preserves_existing_estimate")
        return
    end
    if details.fenxin_target ~= "" and details.fenxin_target ~= event.from then
        self:emitStrategyEffect({kind="role_copy", from=details.fenxin_target, to=event.from})
    end
end

-- Both effective providers read the same lawful viewer snapshot, but their
-- predicates and persistent source variables are deliberately distinct.
local function original_intention_provider(self)
    local facts=self.world and AIHegemony.facts(self.world)
    if not facts or not facts.enabled then return false end
    if type(facts.original_overrides_loaded)~="boolean" then
        ai_unsupported("Original intention provider loading is unknown","original_hegemony_ai_loaded")
    end
    return facts.original_overrides_loaded
end
local function trick_query(target, method, ...)
    -- A genuinely absent source target is a donor ordinary error, not a
    -- missing projection. Do not silently turn it into a neutral intention.
    if target==nil then error("attempt to index a nil target",0) end
    local value=query(target,method,...)
    if (method=="hasSkills" or method=="hasSkill") and value==false then
        local row=type(target)=="table" and rawget(target,"_view")
        if type(row)=="table" and row.skills_complete~=true then
            ai_unsupported("trick intention skill absence is not visible","getTrickIntention")
        end
    end
    return value
end
local function trick_nullable(target,method,field,...)
    if target==nil then error("attempt to index a nil target",0) end
    local fn=target[method]
    if type(fn)~="function" then ai_unsupported("trick intention method is unavailable",method)end
    local value=fn(target,...)
    if AIUnsupported.is(value)then error(value,0)end
    if value==nil then
        local row=type(target)=="table" and rawget(target,"_view")
        if type(row)=="table" and not AIValue.isList(row[field])then
            ai_unsupported("trick intention public card zone is unknown",method)
        end
    end
    return value
end
function SmartAIView:getTrickIntention(class, target)
    local intention = resolve_event_alias(self, sgs.ai_card_intention[class])
    if type(intention)=="number" then return intention end
    if original_intention_provider(self) then
        -- Preserve fixed heg-common's type(intention == "function") typo:
        -- its string result is always truthy, so every nonnumeric IronChain
        -- row takes this branch, including an absent registry entry.
        if class=="IronChain" then
            if target and trick_query(target,"isChained")then return -60 else return 60 end
        end
        if class=="Collateral" then return 0 end
        if class=="AwaitExhausted" or class=="BefriendAttacking" then return -10 end
        if sgs.dynamic_value.damage_card[class] then return 70 end
        if sgs.dynamic_value.benefit[class] then return -40 end
        if target and (class=="Snatch" or class=="Dismantlement")then
            local judging=trick_nullable(target,"getCards","judging_area","j")
            if not judging or judging:isEmpty()then
                if not trick_query(target,"hasArmorEffect","SilverLion")
                    or not trick_query(target,"isWounded")then return 80 end
            end
        end
        return 0
    end
    if type(intention)=="function" then
        if class=="IronChain" then
            if trick_query(target,"isChained")then return -60 else return 60 end
        elseif class=="Drowning" then
            if trick_nullable(target,"getArmor","equips")
                and trick_query(target,"hasSkills","yizhong|bazhen")then return 0 end
            if trick_query(target,"isChained")then return -60 else return 60 end
        end
    end
    if sgs.dynamic_value.damage_card[class] then return 70 end
    if sgs.dynamic_value.benefit[class] then return -40 end
    if ("Snatch|Dismantlement|Zhujinqiyuan"):match(class)then
        local judging=trick_query(target,"getJudgingArea")
        if judging:isEmpty()then
            if not(trick_query(target,"hasArmorEffect","SilverLion")
                and trick_query(target,"isWounded"))then return 80 end
        end
    end
    return 0
end

local function nullification_intention(self, from, prompt)
    if original_intention_provider(self)then
        local class,target_name=prompt[2],prompt[3]
        if string.find(class,"Nullification")then
            local source=memory_value(self,"nullification_source")
            if not source then return end
            local intention=memory_value(self,"nullification_intention")
            if not intention or type(intention)~="number"then return end
            local level=memory_value(self,"nullification_level")+1
            self:setEventMemory("nullification_level",level)
            if level%2==0 then self:updateIntention(from,source,intention)
            elseif level%2==1 then self:updateIntention(from,source,-intention)end
        else
            -- Original's global lookup defaults to getAllPlayers(): alive
            -- only. Ordinary BeMan below scans the full roster including dead.
            local target=self.room:findPlayerByObjectName(target_name)
            self:setEventMemory("nullification_source",target and target:objectName()or nil)
            self:setEventMemory("nullification_level",1)
            local intention=self:getTrickIntention(class,target)
            self:setEventMemory("nullification_intention",intention)
            if from:objectName()~=target_name then self:updateIntention(from,target,-intention)end
        end
    elseif prompt[2]=="Nullification" then
        local level=memory_value(self,"filter_level")+1
        self:setEventMemory("filter_level",level)
        local source=memory_value(self,"filter_source")
        local intention=memory_value(self,"filter_intention")
        if level%2==0 then self:updateIntention(from,source,intention)
        else self:updateIntention(from,source,-intention)end
    else
        self:setEventMemory("filter_level",1)
        local target=self.room:findPlayerByObjectName(prompt[3],true)
        self:setEventMemory("filter_source",target and target:objectName() or nil)
        local intention=self:getTrickIntention(prompt[2],target)
        self:setEventMemory("filter_intention",intention)
        self:updateIntention(from,target,-intention)
    end
end

local function player_chosen_intention(self,from,prompt)
    if string.find(prompt[3],"+") then
        local reason=string.gsub(prompt[2],"%-","_")
        local callback=resolve_event_alias(self,sgs.ai_playerschosen_intention[reason])
        if type(callback)=="function" then callback(self,from,prompt[3]) end
    else
        if from:objectName()==prompt[3] then return end
        local reason=string.gsub(prompt[2],"%-","_")
        local to=self.room:findPlayerByObjectName(prompt[3],true)
        local callback=resolve_event_alias(self,sgs.ai_playerchosen_intention[reason])
        if type(callback)=="number" then self:updateIntention(from,to,callback)
        elseif type(callback)=="function" then callback(self,from,to) end
    end
end

local function view_cards_intention(self,from,prompt)
    local to=self.room:findPlayerByObjectName(prompt[2],true)
    if not to then return end
    local event=rawget(self,"_event_input")
    local details=event and event.details
    if not details or details.view_cards_observed~=true or event.from~=from:objectName()
        or from:objectName()~=self.player:objectName() then
        ai_unsupported("viewCards has no actual recipient disclosure witness","event.viewCards")
    end
    local count=details.view_cards_observed_count
    if not finite(count) then ai_unsupported("viewCards disclosure count is unknown","event.viewCards") end
    if count<query(to,"getHandcardNum") then
        estimate_branch(self,"viewCards.partial_disclosure_does_not_grant_full_hand")
    end
    -- The trusted event knowledge ledger records only these actual disclosed
    -- IDs. A source full-hand visibility overgrant is never reproduced here.
end

local function yiji_intention(self,from,prompt)
    local to=self.room:findPlayerByObjectName(prompt[3],true)
    if not to then return end
    local event=rawget(self,"_event_input")
    local details=event and event.details
    if not details or not finite(details.card_count) then
        ai_unsupported("Yiji public card count is unknown","event.Yiji")
    end
    local count=details.card_count
    local callback=resolve_event_alias(self,sgs.ai_Yiji_intention[prompt[2]])
    if type(callback)=="number" and not query(self,"hasManjuanEffect",to)
        and not(query(self,"needKongcheng",to,true) and count==1) then
        self:updateIntention(from,to,callback)
    elseif type(callback)=="function" then
        if details.yiji_cards_complete~=true or not AIValue.isList(details.yiji_cards) then
            ai_unsupported("Yiji callback cards are not lawfully disclosed","event.Yiji.cards")
        end
        local cards={}
        for _,row in ipairs(details.yiji_cards)do cards[#cards+1]=assert(CardView.new(row),"invalid disclosed Yiji card")end
        if #cards~=count then ai_unsupported("Yiji disclosed card count mismatch","event.Yiji.cards")end
        callback(self,from,to,cards)
    elseif not(query(self,"needKongcheng",to,true) and count==1 or query(self,"hasManjuanEffect",to)) then
        self:updateIntention(from,to,-10)
    end
end

-- Ordinary common entries retain their source callback ABI. Later effective
-- package/provider assignments remain authoritative through normal lookup.
sgs.ai_choicemade_filter.Nullification=sgs.ai_choicemade_filter.Nullification or nullification_intention
sgs.ai_choicemade_filter.playerChosen=sgs.ai_choicemade_filter.playerChosen or player_chosen_intention
sgs.ai_choicemade_filter.viewCards=sgs.ai_choicemade_filter.viewCards or view_cards_intention
sgs.ai_choicemade_filter.Yiji=sgs.ai_choicemade_filter.Yiji or yiji_intention

local function snatch_chosen_intention(self, player, prompt)
    local target = self.room:findPlayerByObjectName(prompt[4], true)
    if not target then return end
    local event = assert(rawget(self, "_event_input"), "cardChosen callback needs its typed event")
    local details, intention = event.details or {}, 70
    -- The donor compares a QList object itself with 2, not its length. Retain
    -- that always-false test; do not silently repair it into a pile-count policy.
    if type(self.hasTuntianEffect) == "function" then self:hasTuntianEffect(target, true) end
    local place = details.chosen_card_place
    if type(place) ~= "number" then ai_unsupported("chosen card place is not projected", "event.card_chosen") end
    local card = details.chosen_card and CardView.new(details.chosen_card)
    if place == sgs.Player_PlaceDelayedTrick then
        if not card then ai_unsupported("public chosen trick metadata is missing", "event.card_chosen") end
        if not card:isKindOf("Disaster") or card:isKindOf("YanxiaoCard") then intention = -intention else intention = 0 end
    elseif place == sgs.Player_PlaceEquip then
        if not card then ai_unsupported("public chosen equipment metadata is missing", "event.card_chosen") end
        if card:isKindOf("Armor") and query(self, "evaluateArmor", card, target) <= -2 then intention = 0
        elseif card:isKindOf("SilverLion") then
            if query(target, "getLostHp") > 1 then
                if query(target, "hasSkills", sgs.use_lion_skill) then intention = query(self, "willSkipPlayPhase", target) and -intention or 0
                else intention = query(self, "isWeak", target) and -intention or 0 end
            else intention = 0 end
        elseif query(target, "hasSkills", sgs.lose_equip_skill) then
            if query(self, "isWeak", target) and (card:isKindOf("DefensiveHorse") or card:isKindOf("Armor")) then intention = math.abs(intention)
            else intention = 0 end
        end
        if prompt[2] == "snatch" and query(self, "isFriend", target, player)
            and (card:isKindOf("OffensiveHorse") or card:isKindOf("Weapon")) then
            local can_attack = false
            for _, other in ipairs(query(self.room, "getOtherPlayers", player)) do
                if query(player, "inMyAttackRange", other) and query(self, "isEnemy", other, player) then can_attack = true break end
            end
            if not can_attack then intention = 0 end
        end
    elseif place == sgs.Player_PlaceHand and query(self, "needKongcheng", target, true)
        and query(target, "getHandcardNum") == 1 then intention = 0 end
    sgs.updateIntention(player, target, intention)
end
sgs.ai_choicemade_filter.cardChosen = sgs.ai_choicemade_filter.cardChosen or {}
if sgs.ai_choicemade_filter.cardChosen.snatch == nil then sgs.ai_choicemade_filter.cardChosen.snatch = snatch_chosen_intention end
if sgs.ai_choicemade_filter.cardChosen.dismantlement == nil then sgs.ai_choicemade_filter.cardChosen.dismantlement = snatch_chosen_intention end

local function choice_intention(self, event, emit)
    local kind = event.details and event.details.choice_kind
    local reason = string.gsub(event.reason or "", "%-", "_")
    local from = self.room:findPlayerByObjectName(event.from, true)
    if not from then return end
    local targets = event.targets or {}
    local prompt = event.details and event.details.prompt_list
    if kind=="Nullification" or kind=="playerChosen" or kind=="viewCards" or kind=="Yiji" then
        if type(prompt)~="table" then ai_unsupported("choice callback fields are not projected","event.choice")end
        local callback=resolve_event_alias(self,sgs.ai_choicemade_filter[kind])
        if type(callback)=="function" then callback(self,from,prompt) end
    elseif kind == "skillInvoke" or kind == "skillChoice" then
        local registry = sgs.ai_choicemade_filter[kind]
        -- An absent registry is unhandled, not a registered boolean callback.
        local callback
        if type(registry) == "table" then callback = resolve_event_alias(self, registry[event.reason or ""]) end
        if callback ~= nil then
            assert(type(callback) == "function", "invalid choice event callback")
            -- Preserve the positional prompt-list ABI using only projected public fields.
            callback(self, from, prompt or {kind, event.reason, event.details.answer})
        end
    elseif type(prompt) == "table" then
        local callback = sgs.ai_choicemade_filter[kind]
        if type(callback) == "table" then
            callback = callback[(kind == "cardResponded" or kind == "cardUsed") and prompt[3] or prompt[2]]
        end
        callback = resolve_event_alias(self, callback)
        if type(callback) == "function" then callback(self, from, prompt) end
    end
end

local function damage_intention(self, event, emit)
    if event.to == "" then return end
    if event.card_name ~= "" and card_callback(self, event) ~= nil then return end
    local reason = event.reason or ""
    local callback = ai_damage_intention[reason]
    if callback ~= nil then
        append_answer(type(callback) == "function" and callback(self, event) or callback, event, emit)
        return
    end
    assert(finite(event.amount), "damage event needs a finite amount")
    local details = event.details or {}
    local function calculate()
        local card = details.card and CardView.new(details.card)
        if card then
            if suppression_card_flag(self, card, event.from, "AIGlobal_ComboFallback") then return 0 end
        end
        if reason == "" and card then
            assert(type(details.card_skills) == "table", "damage card skill names are unknown")
            if details.card_skills_complete == false then
                estimate_branch(self, "card_skill_chain_private.public_activation_only_private_skill_chain")
            end
            for _, skill in ipairs(details.card_skills) do
                if sgs.ai_damage_reason_suppress_intention[skill] then return 0 end
            end
        end
        if sgs.ai_damage_reason_suppress_intention[reason] then return 0 end
        local level = event.amount * 40
        local from = self.room:findPlayerByObjectName(event.from, true)
        for flag, value in pairs(sgs.ai_damage_from_flag_intention) do
            if from then
                local set = from:hasFlag(flag)
                if set == nil then
                    if from:objectName() == self.player:objectName() then ai_unsupported("own damage source flag is not projected", "event.damage") end
                    estimate_branch(self, "damage.private_source_flag."..flag)
                    local skill = event.reason ~= "" and event.reason or event.card_skill or ""
                    set = flag == "ShenfenUsing" and skill:find("shenfen",1,true) ~= nil
                        or flag == "FenchengUsing" and skill:find("fencheng",1,true) ~= nil
                end
                if set then
                    if value == 0 then return 0 end
                    if type(value) == "number" then
                        assert(finite(value), "damage flag intention must be finite")
                        level = event.amount * value
                    end
                end
            end
        end
        local quhu = memory_value(self, "ai_quhu_effect")
        if quhu or reason:find("quhu", 1, true) then
            self:setEventMemory("ai_quhu_effect", false)
            level = event.amount * 30
        elseif reason:find("zhendu", 1, true) then level = event.amount * 10 end
        if event.chain or event.transfer then level = event.amount * 20 end
        return level
    end
    local level = calculate()
    local source_reason = reason ~= "" and reason or event.card_skill or ""
    if source_reason ~= "" then
        local values = state_table(self, "damage_data")
        values[source_reason] = (values[source_reason] or 0) + event.amount
        self:setEventMemory("damage_data", values)
    end
    if level == 0 then return end
    local attribution = source_reason ~= "" and source_attribution(self, event) or event.from
    -- Empty with complete=true proves there is no reason-skill owner. Legacy
    -- then uses damage.from; an undisclosed owner is rejected above, not here.
    if attribution == "" then attribution = event.from end
    if attribution and attribution ~= "" then emit(attribution, event.to, level) end
end

local function recover_intention(self, event, emit)
    -- HpRecover suppresses only registered number/function card callbacks. It
    -- has no TargetSpecified suppression check in legacy filterEvent.
    local callback = card_callback(self, event)
    if type(callback) == "number" or type(callback) == "function" then return end
    if event.from == nil or event.from == "" then return end
    assert(finite(event.amount), "recovery event needs a finite amount")
    emit(event.from, event.to, -66 * event.amount)
end

local function death_intention(self, event, emit)
    if event.from == nil or event.from == "" then return end
    local details = event.details or {}
    if type(details.player) ~= "string" then
        ai_unsupported("death event actor is unknown", "event.death")
    end
    -- filterEvent credits a kill only when damage.from is the trigger player.
    if event.from ~= details.player then return end
    local turn_count = details.turn_count
    if not finite(turn_count) then turn_count = self.room:getTurnCount() end
    if not finite(turn_count) then
        ai_unsupported("death turn count is unknown", "event.death")
    end
    if turn_count <= 1 then return end
    if type(event.chain) ~= "boolean" or type(event.transfer) ~= "boolean" then
        ai_unsupported("death damage chain/transfer state is unknown", "event.death")
    end
    emit(event.from, event.to, (event.chain or event.transfer) and 33 or 99)
end

local function judge_event(self, event, emit)
    local details = event.details or {}
    local raw = assert(details.judge, "judge event needs its typed judgment")
    local who = self.room:findPlayerByObjectName(raw.who or event.to, true)
    assert(who and type(raw.good) == "boolean" and type(raw.reason) == "string", "incomplete judgment")
    local judge = {who = who, reason = raw.reason, pattern = raw.pattern, good = raw.good,
        card = raw.card and CardView.new(raw.card)}
    function judge:isGood() return self.good end
    function judge:isBad() return not self.good end
    local values = state_table(self, "judge_good")
    if event.trigger_event == sgs.StartJudge then
        if judge.reason:find("beige", 1, true) then
            local from = source_attribution(self, event)
            if from ~= "" then emit(from, who:objectName(), -60) end
        end
        local patterns = state_table(self, "judge_patterns")
        patterns[judge.reason] = {judge.pattern, raw.pattern_good}
        self:setEventMemory("judge_patterns", patterns)
        values[judge.reason] = judge.good
        self:setEventMemory("judge_good", values)
        if judge.good and math.random() < 0.4 then
            local function speak(key)
                if type(self.speak) == "function" then return self:speak(key) end
                if self.world and self.world.ai_chat_enabled == false then return nil end
                ai_unsupported("judgment speech policy is not loaded", "event.judge_speech")
            end
            if speak(judge.reason .. "IsGood") or judge.pattern == "." or math.random() < 0.4 then return end
            speak("judgeIsGood")
        end
    else
        local intention = sgs.ai_retrial_intention[judge.reason]
        if type(intention) == "function" then intention = intention(self, judge, values[judge.reason]) end
        if type(intention) ~= "number" then
            if values[judge.reason] then
                if not judge.good then intention = 30 end
            elseif judge.good then intention = -30 end
        end
        if type(intention) == "number" then emit(details.player, who:objectName(), intention) end
        values[judge.reason] = judge.good
        self:setEventMemory("judge_good", values)
    end
end

local function pre_card_used(self, event)
    local details = event.details or {}
    local card = assert(details.card and CardView.new(details.card), "PreCardUsed needs card metadata")
    local lord = self.room:getLord()
    if lord and card:isKindOf("Duel") then
        self:emitStrategyEffect({kind="strategy_flag", player=lord:objectName(), name="AIGlobal_NeedToWake", value=false})
    end
    local skill = event.card_skill or ""
    if skill ~= "" and card:getTypeId() > 0 then
        local values = state_table(self, "convert_data")
        local value = self:getUseValue(card)
        assert(finite(value), "conversion use value is unknown")
        values[skill] = (values[skill] or 0) + value
        self:setEventMemory("convert_data", values)
    end
    if type(details.responded_card_class) == "string" and details.responded_card_class ~= "" then
        local response = state_table(self, "ai_response")
        response[details.responded_card_class] = event.card_class
        self:setEventMemory("ai_response", response)
    end
    self:setEventMemory("used_data", card_use_value(event))
    local key = event.card_name ~= "" and event.card_name or event.card_class
    local callback = resolve_event_alias(self, sgs.ai_choicemade_filter[key])
    if type(callback) == "function" then
        local from = self.room:findPlayerByObjectName(event.from, true)
        local use = card_use_value(event)
        use.card, use.from, use.to = card, from, AIList.new({})
        for _, name in ipairs(use.targets) do use.to:append(assert(self.room:findPlayerByObjectName(name, true))) end
        -- CardUseStruct in this authority has no m_reason field. RoomState
        -- current-use reason is a different value and must not replace nil.
        use.m_reason = nil
        callback(self, self.room:findPlayerByObjectName(details.player, true), use)
    end
end

local function card_effect(self, event)
    local details = event.details or {}
    self:setEventMemory("card_effect", {from = event.from, to = event.to, card = details.card})
    local card = details.card and CardView.new(details.card)
    local target = self.room:findPlayerByObjectName(event.to, true)
    if card and card:isKindOf("AOE") and target and target:isLord() then
        local values = state_table(self, "aoe_lord")
        values[event.card_class] = nil
        self:setEventMemory("aoe_lord", values)
    end
end

local function can_update_intention(self, player)
    local rebels = 0
    for _, other in ipairs(query(self.room, "getAlivePlayers")) do
        if query(self, "getRoleEstimate", other) == "rebel" then rebels = rebels + 1 end
    end
    local counts = query(self, "getRoleCounts")
    if not finite(counts.rebel) then ai_unsupported("public rebel count is unknown", "event.rule_discard") end
    local role = query(self, "getRoleEstimate", player)
    return not (role == "rebel" and rebels >= counts.rebel or role == "neutral" and rebels > counts.rebel / 2)
end

SmartAIView.CanUpdateIntention = can_update_intention

-- Cross-game aggregate history is not read in this VM; the observer keeps its own.
function SmartAIView:GetAiData()
    return nil
end

function SmartAIView:SetAiData(value)
    assert(type(value) == "table", "aggregate AI history must be a table")
    self:setEventMemory("defense_statistics", copy_memory(value))
    estimate_branch(self,"ai_data.viewer_shadow_no_cross_room_write")
end

local statistic_keys = {drawData="draw_data",convertData="convert_data",damageData="damage_data",throwData="throw_data"}
function SmartAIView:saveItemData(data_name, history)
    local key=assert(statistic_keys[data_name], "unknown aggregate statistic")
    local observed=state_table(self,key)
    if key=="throw_data" then
        -- Only a consumed nonempty map depends on the viewer aggregate. This
        -- also covers histories recorded before the provenance field existed.
        if next(observed)~=nil then estimate_branch(self,"throw_data.viewer_only_aggregate") end
        local state=rawget(self,"_event_state") or rawget(self,"_strategy_state") or self:recall(memory_key)
        if state and state.throw_data_initial_history_unknown then
            estimate_branch(self,"throw_data.unobserved_initial_viewer_history")
        end
    end
    history[data_name]=history[data_name] or {}
    for skill, amount in pairs(observed) do
        history[data_name][skill]=history[data_name][skill] or {}
        local owner, incomplete
        for _, player in ipairs(self.room:getAlivePlayers()) do
            local owns=player:hasSkill(skill,true)
            if owns==true then owner=player; break elseif owns==nil then incomplete=true end
        end
        if owner then
            local samples=history[data_name][skill]
            samples[#samples+1]=amount
            if #samples>99 then table.remove(samples,1) end
            observed[skill]=0
        elseif incomplete then
            estimate_branch(self,"ai_data.hidden_skill_owner_defers_sample")
        end
    end
    self:setEventMemory(key,observed)
end

local function move_card(self, row, branch)
    if row.card then return CardView.new(row.card) end
    estimate_branch(self, branch)
end

local function move_poison(self, row, owner, branch)
    local card = move_card(self, row, branch)
    if card then return #query(self, "poisonCards", {card}, owner) > 0 end
    -- A private moved hand card has no authorized identity. Preserve the source
    -- transfer intent using the ordinary useful-card prior, and report it as an
    -- estimate. No fabricated CardView, hidden ID or class enters the policy.
    return false
end

local function move_can_use(self, row, target, from, card)
    local value = row.can_use and row.can_use[target:objectName()]
    if type(value) == "boolean" then return value end
    if row.can_use_private == true and from:objectName() ~= self.player:objectName() then
        estimate_branch(self, "rule_discard.other_player_hypothetical_legality")
        -- Public opportunity estimate: another player's card limits or virtual
        -- hand conversions are not queried. Retain visible category/geometry.
        if from:objectName() == target:objectName() then return false end
        if card:isKindOf("Slash") then
            local range = from:inMyAttackRange(target)
            if type(range) == "boolean" then return range end
            local distance, attack = from:distanceTo(target), from:getAttackRange()
            return finite(distance) and finite(attack) and distance <= attack
        end
        if card:isKindOf("DelayedTrick") and target:containsTrick(card:objectName()) then return false end
        return not query(card, "targetFixed")
    end
    ai_unsupported("moved owner card target legality is not projected", "event.rule_discard")
end

local function rule_discard(self, event, move, row, from, card)
    if query(from, "getPhase") > sgs.Player_Discard
        or query(self, "getRoleEstimate", from) ~= "neutral" then return end
    local skipped = from:isSkipped(sgs.Player_Play)
    if skipped == nil then
        -- Another actor's private skip flag is unavailable. Public skip-phase
        -- policy preserves the intended lost opportunity test without disclosure.
        skipped = query(self, "willSkipPlayPhase", from)
        estimate_branch(self, "rule_discard.other_player_skip_phase")
    end
    if skipped or not can_update_intention(self, from) then return end
    local baiyin = from:hasSkill("baiyin", true)
    if baiyin == nil then estimate_branch(self, "rule_discard.hidden_baiyin"); baiyin = false end
    if baiyin then return end
    if not card then
        -- Rule discard cards are public after disposal. A missing card here is
        -- a legal public projection gap, not permission to invent its category.
        ai_unsupported("public rule-discard card metadata is missing", "event.rule_discard")
    end
    local enemies, friends = query(self, "getEnemies"), query(self, "getFriends")
    local delayed_card = card
    local delayed = card:isKindOf("DelayedTrick")
    if type(isCard) == "function" then
        local converted = isCard("DelayedTrick", card, from)
        if converted then delayed = true; if type(converted) == "table" then delayed_card = converted end end
    end
    if delayed and not query(delayed_card, "targetFixed") then
        local delayed_row = row
        if delayed_card ~= card then
            if from:objectName() == self.player:objectName() then
                ai_unsupported("converted delayed-trick target legality is not projected", "event.rule_discard")
            end
            delayed_row = {can_use_private=true}
        end
        local zhanghe = self.room:findPlayerBySkillName("qiaobian")
        for _, target in ipairs(enemies) do
            local skip = zhanghe and zhanghe:objectName() == target:objectName()
                or query(target, "containsTrick", "YanxiaoCard")
            if not skip and zhanghe and query(self, "playerGetRound", zhanghe) <= query(self, "playerGetRound", target)
                and query(self, "isFriend", zhanghe, target) then skip = true end
            if not skip and move_can_use(self, delayed_row, target, from, delayed_card) then
                self:emitStrategyEffect({kind="strategy_mark", player=event.details.player, name="Intention"..from:objectName(), amount=35})
                break
            end
        end
    end
    local function flag(name)
        local value = from:hasFlag(name)
        if value == nil then estimate_branch(self, "rule_discard.other_player_strategy_flags"); return false end
        return value
    end
    if flag("JiangchiInvoke") or flag("hasUsed"..query(card, "getClassName"))
        or card:isKindOf("Slash") and flag("hasUsedSlash") then return end
    if query(card, "isDamageCard") or not query(card, "targetFixed") then
        for _, target in ipairs(enemies) do
            if move_can_use(self, row, target, from, card) and query(self, "isGoodTarget", target, nil, card) then
                self:emitStrategyEffect({kind="strategy_mark", player=event.details.player, name="Intention"..from:objectName(), amount=35})
                break
            end
        end
        for _, target in ipairs(friends) do
            if query(self, "getRoleEstimate", target) ~= "neutral" and move_can_use(self, row, target, from, card)
                and query(self, "isGoodTarget", target, nil, card) then
                self:emitStrategyEffect({kind="strategy_mark", player=event.details.player, name="Intention"..from:objectName(), amount=-35})
                break
            end
        end
    end
end

local function cards_move(self, event, emit)
    local details, actor = event.details or {}, event.details and event.details.player
    local move = assert(details.move, "CardsMoveOneTime needs typed move provenance")
    local from = self.room:findPlayerByObjectName(move.from, true)
    local to = self.room:findPlayerByObjectName(move.to, true)
    local reason_player = self.room:findPlayerByObjectName(move.reason_player, true)
    local trigger = assert(self.room:findPlayerByObjectName(actor, true), "move actor is unknown")
    assert(type(move.cards) == "table" and type(move.skill) == "string", "invalid typed move")
    if move.skill == "fenji" then self:setEventMemory("fenji_target", from and from:objectName()) end
    local give = move.basic_reason == sgs.CardMoveReason_S_REASON_GIVE
    local discard = move.basic_reason == sgs.CardMoveReason_S_REASON_DISCARD
    for _, row in ipairs(move.cards) do
        local present = row.present_match
        if type(present) ~= "boolean" and to and to:objectName() == actor then
            -- Preserve the donor's GIVE=0x17 versus reason&0x0f comparison.
            -- An undisclosed private PresentCard match is explicitly estimated.
            estimate_branch(self, "cards_move.private_present_card_tag")
            present = false
        end
        if to and to:objectName() == actor and (give or present) then
            local voluntary = false
            for _, skill in ipairs(sgs.ai_voluntary_give_skills or {}) do if skill == move.skill then voluntary = true break end end
            if (present or give and (move.skill == "" or not voluntary)) and reason_player then
                local level = -33
                if move.to_place ~= sgs.Player_PlaceHand or row.public == true then
                    local card = assert(row.card and CardView.new(row.card), "public gift metadata is missing")
                    if #query(self, "poisonCards", {card}) > 0 then level = 33
                    else level = -2 * query(self, "getUseValue", card) end
                end
                emit(reason_player:objectName(), actor, level)
            end
        end
        if from then
            if discard then
                if move.reason_player ~= actor then
                    if from:objectName() == actor and reason_player then
                        local favorable = row.from_place == sgs.Player_PlaceDelayedTrick
                        if not favorable and row.from_place == sgs.Player_PlaceEquip then
                            local card = assert(row.card and CardView.new(row.card), "public discarded equipment is missing")
                            favorable = (sgs.ai_poison_card or {})[card:objectName()] or query(self, "evaluateArmor", card) < -5
                        end
                        emit(reason_player:objectName(), actor, favorable and -55 or 55)
                    end
                elseif move.reason == sgs.CardMoveReason_S_REASON_RULEDISCARD then
                    rule_discard(self, event, move, row, from, row.card and CardView.new(row.card))
                end
            elseif move.skill:find("qiaobian", 1, true) and to and self.room:getCurrent() == trigger then
                emit(actor, from:objectName(), move_poison(self, row, from, "qiaobian.private_source_card") and -70 or 70)
                emit(actor, to:objectName(), move_poison(self, row, to, "qiaobian.private_destination_card") and 70 or -70)
            end
        end
    end
    if to and to:objectName() == actor then
        if move.to_place == sgs.Player_PlaceHand then
            if move.skill ~= "" then
                local values = state_table(self, "draw_data")
                values[move.skill] = (values[move.skill] or 0) + move.card_count
                self:setEventMemory("draw_data", values)
            end
            self:assignKeep(query(trigger, "getPhase") < sgs.Player_Play)
            self:persistKeepState()
        elseif move.to_place == sgs.Player_PlaceEquip then
            self:assignKeep()
            self:persistKeepState()
        end
    end
end

local function damage_bookkeeping(self, event)
    local need = {}
    for _, player in ipairs(assert(self.room:getAlivePlayers())) do need[player:objectName()] = 0 end
    local target = self.room:findPlayerByObjectName(event.to, true)
    if event.nature ~= sgs.DamageStruct_Normal and not event.chain and target and query(target, "isChained") then
        local count = 0
        for _, other in ipairs(assert(self.room:getOtherPlayers(target))) do
            local chained = other:isChained()
            assert(type(chained) == "boolean", "chain state is unknown")
            if chained then need[other:objectName()] = event.amount - other:getHp(); count = count + 1 end
        end
        self:setEventMemory("is_chained", count)
    end
    self:setEventMemory("need_peach", need)
    if event.details and event.details.card then
        local nature = state_table(self, "card_damage_nature")
        nature[event.card_class] = event.nature
        self:setEventMemory("card_damage_nature", nature)
    end
end

local function round_start(self, event)
    local current = self.room:getCurrent()
    local actor = event.details and event.details.player
    if not current or type(actor) ~= "string" then
        ai_unsupported("RoundStart actor/current is unknown", "event.round_start")
    end
    if actor == current:objectName() then
        local count = event.details.turn_count
        if not finite(count) then ai_unsupported("RoundStart turn count is unknown", "event.round_start") end
        self:setEventMemory("turn_count", count)
        -- Donor reloads aggregate history at every RoundStart. A nil read keeps
        -- this viewer's prior state; a newly published revision replaces it.
        local history = self:GetAiData()
        if history == nil then history = self:getEventMemory("defense_statistics") end
        history = history or {drawData={},convertData={},damageData={},throwData={}}
        for _, category in ipairs({"drawData","convertData","damageData","throwData"}) do
            self:saveItemData(category,history)
        end
        for key, field in pairs({ai_response="aiResponse",card_damage_nature="card_damage_nature"}) do
            history[field]=history[field] or {}
            for name,value in pairs(state_table(self,key)) do history[field][name]=value end
            self:setEventMemory(key,copy_memory(history[field]))
        end
        self:SetAiData(history)
    else
        if type(self.world.ai_humanized) ~= "boolean" then ai_unsupported("humanization setting is unknown", "event.round_start") end
        if self.world.ai_humanized and math.random() < 0.2 - query(self.room, "getTurnCount") * 0.01 then
            self:emitStrategyEffect({kind="strategy_mark", player=actor, name="roleRobot", amount=math.random(1,11)})
        end
    end
end

-- original-hegemony/heg-common-ai.lua:61,196,252-297. This is its own
-- observation history, never an alias for ordinary targeted no-Jink marks.
local function original_lack_enabled(self)
    local heg=AIHegemony.facts(self.world)
    return type(heg)=='table' and heg.enabled==true and heg.original_overrides_loaded==true
end
local function original_lack_state(self)
    local state,known=self:getStrategyMemory('original_card_lack')
    if known and type(state)=='table' then return state end
    return {values={},known={}}
end
function SmartAIView:getOriginalHegemonyCardLack(player,kind)
    assert(kind=='Slash' or kind=='Jink' or kind=='Peach','invalid original card-lack kind')
    local name=type(player)=='string' and player or player:objectName()
    assert(self.room:findPlayerByObjectName(name,true),'unknown card-lack player')
    local state=original_lack_state(self)
    local value=state.values[name] and state.values[name][kind] or 0
    local complete=state.known[name] and state.known[name][kind]==true
    -- The current native ChoiceMade envelope is actor-private. Other viewers
    -- cannot silently treat missing response notifications as observed zeros.
    local facts=AIHegemony.facts(self.world)
    if name~=self.player:objectName() and not(facts and facts.card_lack_responses_complete==true)then complete=false end
    if complete then return value end
    return self:useKnowledgeEstimate({status='estimate',value=value,target=name,
        basis='original_hegemony.card_lack_incomplete_viewer_history',card_kind=kind},'original_card_lack')
end
local function original_lack_update(self,player,changes)
    local state=copy_memory(original_lack_state(self));local name=player:objectName()
    state.values[name]=state.values[name] or {};state.known[name]=state.known[name] or {}
    for kind,value in pairs(changes)do state.values[name][kind]=value;state.known[name][kind]=true end
    self:setStrategyMemory('original_card_lack',state)
end
local function original_lack_initialize(self)
    if not original_lack_enabled(self)then return end
    local state=original_lack_state(self)
    for _,player in ipairs(self.room:getAllPlayers(true))do
        local name=player:objectName()
        if not state.values[name]then original_lack_update(self,player,{Slash=0,Jink=0,Peach=0})end
    end
end
local function original_lack_choice(self,player,event)
    if not original_lack_enabled(self) or not player then return end
    local parts=event.details and event.details.prompt_list
    if type(parts)~='table' or parts[1]~='cardResponded' then return end
    local pattern,answer=parts[2] or '',parts[#parts]
    local missing=answer=='' or answer=='_nil_' or answer=='.'
    if pattern:find('jink',1,true)then
        if not missing or not query(self,'hasEightDiagramEffect',player)then original_lack_update(self,player,{Jink=missing and 1 or 0})end
    elseif pattern:find('slash',1,true)then original_lack_update(self,player,{Slash=missing and 1 or 0})
    elseif pattern:find('peach',1,true)then original_lack_update(self,player,{Peach=missing and 1 or 0})end
end
local function original_lack_move(self,player,event)
    if not original_lack_enabled(self) or not player then return end
    local move=event.details and event.details.move
    if type(move)~='table'then return end
    if move.to==player:objectName() and move.to_place==sgs.Player_PlaceHand then
        for _,row in ipairs(move.cards or{})do
            if row.open==false and row.public==false then
                original_lack_update(self,player,{Slash=0,Jink=0,Peach=0});break
            elseif row.open==true or row.public==true then
                local card=row.card and CardView.new(row.card)
                if not card then ai_unsupported('public gained card face is missing','original_card_lack.public_gain')end
                for _,kind in ipairs({'Slash','Jink','Peach'})do if card:isKindOf(kind)then original_lack_update(self,player,{[kind]=0})end end
            else
                ai_unsupported('move visibility provenance is missing','original_card_lack.visibility')
            end
        end
    end
    if move.from~=player:objectName() or player:getPhase()~=sgs.Player_Discard
        or player:getHandcardNum()<2 or move.to_place~=sgs.Player_DiscardPile
        or move.reason~=sgs.CardMoveReason_S_REASON_RULEDISCARD then return end
    local heg=AIHegemony.facts(self.world)
    local row=heg.players and heg.players[player:objectName()]
    if not row or type(row.shown_skills)~='table'then ai_unsupported('shown skill roster is missing','original_card_lack.nosleiji')end
    if row.shown_skills.nosleiji==nil then return end
    for _,moved in ipairs(move.cards or{})do
        local card=moved.card and CardView.new(moved.card)
        if not card then ai_unsupported('public discarded card face is missing','original_card_lack.discard')end
        if card:isKindOf('Jink')then original_lack_update(self,player,{Jink=2})end
    end
end
for event,callback in pairs({[sgs.ChoiceMade or 'ChoiceMade']=original_lack_choice,
    [sgs.CardsMoveOneTime or 'CardsMoveOneTime']=original_lack_move})do
    sgs.ai_event_callback[event]=sgs.ai_event_callback[event] or {}
    sgs.ai_event_callback[event].original_hegemony=callback
end

-- The donor protects each registered callback independently. Diagnostics are
-- request-local audit data, not knowledge estimates, intention or game effects.
local event_callback_diagnostics = {}
function ai_event_callback_diagnostics()
    return event_callback_diagnostics
end
local function event_callback_failure(self,event,key,classification,failure)
    local errors=event_callback_diagnostics
    if #errors>=64 then
        errors[64].truncated=(errors[64].truncated or 0)+1
        return
    end
    local reason=type(failure)=="string" and failure
        or AIUnsupported.is(failure) and failure.reason
        or "non-string Lua error ("..type(failure)..")"
    local deltas,effects=self._event_policy_prefix()
    errors[#errors+1]={kind="event_callback_failure",classification=classification,
        callback=type(key)=="string" and key:sub(1,160) or type(key)=="number" and tostring(key) or "<"..type(key)..">",
        reason=reason:sub(1,512),after_delta=#deltas,after_effect=#effects}
end
local function event_callback_resource_error(value)
    return type(value)=="string" and (value:find("AI instruction limit exceeded",1,true)
        or value:find("not enough memory",1,true) or value:find("C stack overflow",1,true)
        or value:find("stack overflow",1,true))
end
local function event_callback_data(self,event)
    local methods={}
    function methods.toString()
        -- Private exact branches are actor-only. Public playerChosen is also
        -- reconstructible when native proves its complete three-field frame;
        -- a Yiji public prefix is never mistaken for a complete private string.
        local prefixes={Nullification=true,cardResponded=true,cardUsed=true,
            cardChosen=true,viewCards=true,skillInvoke=true,skillChoice=true}
        local parts=type(event.details)=="table" and event.details.prompt_list
        local public_player_chosen=type(parts)=="table" and parts[1]=="playerChosen"
            and event.details.choice_kind=="playerChosen" and event.details.prompt_string_complete==true
        if event.trigger_event~=sgs.ChoiceMade or event.kind~="choice" or type(parts)~="table"
            or not public_player_chosen and (event.from~=self.player:objectName() or not prefixes[parts[1]])
            or event.details.choice_kind~=parts[1] then
            ai_unsupported("event string is not completely projected","event.toString")
        end
        local count=0
        for key,value in pairs(parts)do
            if type(key)~="number" or key<1 or key%1~=0 or type(value)~="string"
                or value:find(":",1,true)then
                ai_unsupported("event string fields are invalid","event.toString")
            end
            count=count+1
        end
        if count==0 then ai_unsupported("event string is empty","event.toString")end
        if public_player_chosen and count~=3 then
            ai_unsupported("public playerChosen frame is not exactly three fields","event.toString")
        end
        for index=1,count do
            if type(parts[index])~="string"then
                ai_unsupported("event string fields are sparse","event.toString")
            end
        end
        return table.concat(parts,":",1,count)
    end
    function methods.toCardUse()
        if event.kind~="card_use" then
            ai_unsupported("event does not carry a projected CardUseStruct","event.toCardUse")
        end
        if type(event.details)~="table" or type(event.details.card)~="table"
            or not AIValue.isList(event.targets) or type(event.from)~="string" then
            ai_unsupported("CardUseStruct public fields are incomplete","event.toCardUse")
        end
        local function player(name)
            if name=="" then return nil end
            local p=type(name)=="string" and self.room:findPlayerByObjectName(name,true)
            if not p then ai_unsupported("CardUseStruct player is outside the roster","event.toCardUse")end
            return p
        end
        local targets=AIList.new({})
        for _,name in ipairs(event.targets)do targets:append(player(name))end
        -- Reuse only the existing authorized descriptor; in particular never
        -- invent getSkillNames completeness or read a foreign skill chain.
        return {from=player(event.from),to=targets,card=CardView.new(event.details.card)}
    end
    -- Existing pure callbacks still see and iterate exactly their event fields.
    -- QVariant-like methods are not inserted into copyable/serializable data.
    return setmetatable({}, {__index=function(_,key)
        if methods[key]then return methods[key]end
        return event[key]
    end,__pairs=function()return next,event,nil end,__len=function()return #event end})
end

local function skill_events(self, world, event, emit)
    local callbacks = sgs.ai_event_callback[event.trigger_event]
        or sgs.ai_event_callback[event.kind]
    if callbacks == nil then return end
    if type(callbacks) ~= "table" then return end
    local actor = event.details and event.details.player or event.to
    local player = self.room:findPlayerByObjectName(actor, true)
    local data=event_callback_data(self,event)
    -- Preserve pairs order, writes before errors, and the source's ignored
    -- ordinary return values. Other typed intention registries retain their ABI.
    for key, callback in pairs(callbacks) do
        if type(callback) == "function" then
            local ok,value=pcall(callback,self,player,data)
            if AIUnsupported.is(value) then
                -- A callback whose inputs are not projected skips itself, as the
                -- donor's per-callback pcall does; the event still commits.
                event_callback_failure(self,event,key,"typed_unsupported",value)
            elseif not ok then
                if event_callback_resource_error(value)then
                    event_callback_failure(self,event,key,"resource_limit",value)
                    error(value,0)
                end
                event_callback_failure(self,event,key,"ordinary_error",value)
            end
        end
    end
end

function ai_event(world, event)
    event_callback_diagnostics={}
    assert(type(world) == "table" and type(event) == "table", "event needs pure snapshots")
    assert(active_sink == nil, "nested isolated events are not supported")
    if sync_flag_clears then sync_flag_clears(world) end
    local self = assert(SmartAIView.new({kind = "event", viewer = world.self.object_name,
        world_view = world, scratch = {}}), "invalid event world")
    local stored = type(self.recall) == "function" and self:recall(memory_key) or nil
    self._event_state = stored or {known = {}}
    self._event_input = event
    self._event_estimates, self._event_estimates_seen = {}, {}
    if event.trigger_event == sgs.GameReady then initialize_event_memory(self);original_lack_initialize(self) end
    local present = {[world.self.object_name] = true}
    for _, player in ipairs(world.players or {}) do present[player.object_name] = true end
    local deltas, effects = {}, {}
    self._event_policy_prefix=function() return deltas,effects end
    self._event_effect_sink = function(effect)
        assert(type(effect) == "table" and #effects < max_deltas, "invalid strategy event effect")
        effect.after_delta = #deltas
        effects[#effects + 1] = effect
        -- A callback later in this same event sees earlier strategy writes. The
        -- world is this observer's ephemeral value snapshot, never the Room.
        local policy = self.world and self.world.mode_policy
        if type(policy) == "table" then
            if effect.kind == "strategy_flag" or effect.kind == "strategy_flags_clear" then
                policy.strategy_flags = policy.strategy_flags or {}
                local flags = policy.strategy_flags[effect.player] or {}
                if effect.kind == "strategy_flags_clear" then flags = {}
                else flags[effect.name] = effect.value end
                policy.strategy_flags[effect.player] = flags
            elseif effect.kind == "phase_clear" then
                local marks = policy.strategy_marks and policy.strategy_marks[effect.player]
                for name in pairs(marks or {}) do
                    if name:match("^ai_NoJinkCard%-?%d+_targeted%-Clear$")
                        or name:match("^ai_NoJinkDummy%d+_%d+_targeted%-Clear$")
                        or name:match("^ai_NoJinkVirtualnative:[%x%-]+:%d+_targeted%-Clear$") then marks[name]=nil end
                end
            elseif effect.kind == "strategy_mark" then
                policy.strategy_marks = policy.strategy_marks or {}
                local marks = policy.strategy_marks[effect.player] or {}
                local player = self.room:findPlayerByObjectName(effect.player, true)
                local previous = marks[effect.name]
                if previous == nil then previous = player and player:getMark(effect.name) or 0 end
                marks[effect.name] = previous + effect.amount
                policy.strategy_marks[effect.player] = marks
            end
        end
    end
    local function emit(from, to, level, defer_refresh)
        assert(type(from) == "string" and type(to) == "string" and present[from] and present[to],
            "intention players must belong to this viewer snapshot")
        assert(finite(level), "intention level must be finite")
        if from == to then return end
        assert(#deltas < max_deltas, "too many event intention deltas")
        deltas[#deltas + 1] = {from = from, to = to, level = level}
        if defer_refresh ~= nil then
            assert(type(defer_refresh) == "boolean", "defer_refresh must be boolean")
            deltas[#deltas].defer_refresh = defer_refresh
        end
    end
    active_sink = emit
    active_refresh = function() self:emitStrategyEffect({kind="role_refresh"}) end
    local ok, failure = pcall(function()
        -- Player flags are synchronized from actual clear epochs before entry.
        -- A bare phase/event list is not a clear witness and must not erase a
        -- flag written after an already acknowledged native operation.
        for _, name in ipairs(event.details and event.details.strategy_marks_cleared or {}) do
            self:emitStrategyEffect({kind="phase_clear", player=name})
            if name == self.player:objectName() then
                self:setStrategyMemory("standard_mark:"..name..":NosJiefanFailed-Clear", 0)
            end
        end
        for _, name in ipairs(event.details and event.details.strategy_play_marks_cleared or {}) do
            if name == self.player:objectName() then
                self:setStrategyMemory("standard.nosguhuo_play_marks", {})
            end
        end
        -- All fixed-baseline revivePlayer callers use throwMark=true and
        -- visibleOnly=false. This happens before Revived callbacks. Bury alone
        -- clears only visible marks, so do not reset these AI-only observations
        -- on Death or at a phase boundary. KOF globals persist separately.
        if sgs.Revived~=nil and event.trigger_event==sgs.Revived
            and event.details and event.details.player==self.player:objectName() then
            self:setStrategyMemory("classical.kof_marks", {
                KOFControl=0,KFC_Control=0,KFC_Forbidden=0,StrictControl=0,KOFInterval=0})
            self:setStrategyMemory("standard_mark:"..self.player:objectName()..":NosJiefanFailed-Clear", 0)
            self:setStrategyMemory("standard_mark:"..self.player:objectName()..":AI_loushen_times", 0)
            self:setStrategyMemory("standard.nosguhuo_play_marks", {})
        end
        -- filterEvent calls registered event callbacks before its built-in branch.
        skill_events(self, world, event, emit)
        if event.trigger_event == sgs.TargetSpecified then
            self:setEventMemory("target_use", card_use_value(event))
            self:setEventMemory("ai_collateral", event.card_name == "collateral")
            card_intention(self, event, emit)
            target_bookkeeping(self, event)
        elseif event.trigger_event == sgs.DamageInflicted then
            damage_bookkeeping(self, event)
            damage_intention(self, event, emit)
        elseif event.trigger_event == sgs.StartJudge or event.trigger_event == sgs.AskForRetrial then judge_event(self, event, emit)
        elseif event.trigger_event == sgs.PreCardUsed then pre_card_used(self, event)
        elseif event.trigger_event == sgs.CardEffect then card_effect(self, event)
        elseif event.trigger_event == sgs.CardsMoveOneTime then cards_move(self, event, emit)
        elseif event.trigger_event == sgs.RoundStart then round_start(self, event)
        elseif event.trigger_event == sgs.HpRecover then recover_intention(self, event, emit)
        elseif event.trigger_event == sgs.Death then
            death_intention(self, event, emit)
            -- Revision-scoped caches already miss after a death; only the
            -- observer's remembered crossbow values need dropping.
            self:setStrategyMemory("crossbow_effect", {})
        elseif sgs.BeforeGameOverJudge~=nil and event.trigger_event==sgs.BeforeGameOverJudge
            or sgs.Revived~=nil and event.trigger_event==sgs.Revived then
            self:emitStrategyEffect({kind="role_refresh",force=true,refresh=true})
        elseif event.trigger_event == sgs.ChoiceMade then
            choice_intention(self, event, emit)
            choice_bookkeeping(self, event)
        end
    end)
    active_sink, active_refresh = nil, nil
    self._event_effect_sink = nil
    self._event_policy_prefix = nil
    self._event_input = nil
    if #deltas>0 and world.mode_policy and world.mode_policy.standard_identity then
        estimate_branch(self,"donor_error_repair.updateIntention_fractional_random")
    end
    -- Record event-local knowledge dependencies without replaying event history.
    for _,entry in ipairs(self.request and self.request.scratch and self.request.scratch.knowledge_estimates or {}) do
        if type(entry.basis)=="string" then estimate_branch(self,entry.basis) end
    end
    local estimates = self._event_estimates
    self._event_estimates, self._event_estimates_seen = nil, nil
    -- An unprojected input stops this event's policy where it stood, as an
    -- erroring donor filterEvent did; what ran before it still commits.
    if not ok and not AIUnsupported.is(failure) then self._event_state = nil; error(failure, 0) end
    -- The host takes the deltas but no longer calls ai_event_commit, so the
    -- observer's event memory commits here once the event succeeded.
    local staged_state = self._event_state
    self._event_state = nil
    memory_commit(memory_prepare(world.self.object_name, memory_key, staged_state))
    return deltas, effects, estimates
end

ai_coverage.declare("event_intention", function()
    return {"TargetSpecified", "DamageInflicted", "HpRecover", "Death", "ChoiceMade",
        "StartJudge", "AskForRetrial", "PreCardUsed", "CardEffect", "CardsMoveOneTime", "RoundStart", "GameReady", "BeforeGameOverJudge", "Revived", "registered_callback"}
end)
-- Resolve effective aliases only when the native load-order snapshot confirms their binding.
if ai_audited_aliases then
    sgs.ai_choicemade_filter.skillInvoke = sgs.ai_choicemade_filter.skillInvoke or {}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.PlusLangmou",registry="ai_choicemade_filter",path={"cardChosen","PlusLangmou"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","fankui"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.SixLangmou",registry="ai_choicemade_filter",path={"cardChosen","SixLangmou"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","fankui"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.#PlusRende_Card",registry="ai_card_intention",path={"#PlusRende_Card"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.#s3_fans_xianjia",registry="ai_card_intention",path={"#s3_fans_xianjia"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.Dragon_rendeCard",registry="ai_card_intention",path={"Dragon_rendeCard"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.SixRendeCard",registry="ai_card_intention",path={"SixRendeCard"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.TenyearRendeCard",registry="ai_card_intention",path={"TenyearRendeCard"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.sfofl_renwang",registry="ai_card_intention",path={"sfofl_renwang"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.songli",registry="ai_card_intention",path={"songli"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.tenyearrende",registry="ai_card_intention",path={"tenyearrende"},canonical_registry="ai_card_intention",canonical_path={"RendeCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.skillInvoke.qhstandardtieqi",registry="ai_choicemade_filter",path={"skillInvoke","qhstandardtieqi"},canonical_registry="ai_choicemade_filter",canonical_path={"skillInvoke","tieji"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.#LuaFanjianCard",registry="ai_card_intention",path={"#LuaFanjianCard"},canonical_registry="ai_card_intention",canonical_path={"FanjianCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.NeoFanjianCard",registry="ai_card_intention",path={"NeoFanjianCard"},canonical_registry="ai_card_intention",canonical_path={"FanjianCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.#sgkgodqianqiCard",registry="ai_card_intention",path={"#sgkgodqianqiCard"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.#sr_qingchengcard",registry="ai_card_intention",path={"#sr_qingchengcard"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.BawangCard",registry="ai_card_intention",path={"BawangCard"},canonical_registry="ai_card_intention",canonical_path={"ShensuCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.IceSlash",registry="ai_card_intention",path={"IceSlash"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.PlusShensu_Card",registry="ai_card_intention",path={"PlusShensu_Card"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.QingyiCard",registry="ai_card_intention",path={"QingyiCard"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.TenyearShensuCard",registry="ai_card_intention",path={"TenyearShensuCard"},canonical_registry="ai_card_intention",canonical_path={"ShensuCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.TouduCard",registry="ai_card_intention",path={"TouduCard"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.diancp",registry="ai_card_intention",path={"diancp"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.sr_xiahoucard",registry="ai_card_intention",path={"sr_xiahoucard"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.wangzhe",registry="ai_card_intention",path={"wangzhe"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.zhouchuCard",registry="ai_card_intention",path={"zhouchuCard"},canonical_registry="ai_card_intention",canonical_path={"Slash"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.#s3_jxwj_weiwan",registry="ai_card_intention",path={"#s3_jxwj_weiwan"},canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.#sr_fangxincard",registry="ai_card_intention",path={"#sr_fangxincard"},canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.JiuzhuCard",registry="ai_card_intention",path={"JiuzhuCard"},canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.SecondTenyearChunlaoWineCard",registry="ai_card_intention",path={"SecondTenyearChunlaoWineCard"},canonical_registry="ai_card_intention",canonical_path={"ChunlaoWineCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.SevenWeiYuan",registry="ai_card_intention",path={"SevenWeiYuan"},canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.SixChunlaoWineCard",registry="ai_card_intention",path={"SixChunlaoWineCard"},canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.TenyearChunlaoWineCard",registry="ai_card_intention",path={"TenyearChunlaoWineCard"},canonical_registry="ai_card_intention",canonical_path={"ChunlaoWineCard"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.WeidaiCard",registry="ai_card_intention",path={"WeidaiCard"},canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.kerenxinCard",registry="ai_card_intention",path={"kerenxinCard"},canonical_registry="ai_card_intention",canonical_path={"Peach"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.#sgkgodhuchiCard",registry="ai_card_intention",path={"#sgkgodhuchiCard"},canonical_registry="ai_card_intention",canonical_path={"Duel"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.FourYijue",registry="ai_choicemade_filter",path={"cardChosen","FourYijue"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.LuaJianzhi",registry="ai_choicemade_filter",path={"cardChosen","LuaJianzhi"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.LuaLongzhen_o",registry="ai_choicemade_filter",path={"cardChosen","LuaLongzhen_o"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.MeowXiaoji",registry="ai_choicemade_filter",path={"cardChosen","MeowXiaoji"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.PlusTieji",registry="ai_choicemade_filter",path={"cardChosen","PlusTieji"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.SE_Shanguang",registry="ai_choicemade_filter",path={"cardChosen","SE_Shanguang"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.SixWuzhiCard",registry="ai_choicemade_filter",path={"cardChosen","SixWuzhiCard"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.TH_ForbiddenFruits",registry="ai_choicemade_filter",path={"cardChosen","TH_ForbiddenFruits"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.anni",registry="ai_choicemade_filter",path={"cardChosen","anni"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.bf_xuanlve",registry="ai_choicemade_filter",path={"cardChosen","bf_xuanlve"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.bf_zhiman",registry="ai_choicemade_filter",path={"cardChosen","bf_zhiman"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.eweicheng",registry="ai_choicemade_filter",path={"cardChosen","eweicheng"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.ezhuanquan",registry="ai_choicemade_filter",path={"cardChosen","ezhuanquan"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.f_chongzhen",registry="ai_choicemade_filter",path={"cardChosen","f_chongzhen"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.feijiangts",registry="ai_choicemade_filter",path={"cardChosen","feijiangts"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.gonglzs",registry="ai_choicemade_filter",path={"cardChosen","gonglzs"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.haigu",registry="ai_choicemade_filter",path={"cardChosen","haigu"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.heg_jinfa",registry="ai_choicemade_filter",path={"cardChosen","heg_jinfa"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.heg_lianpian",registry="ai_choicemade_filter",path={"cardChosen","heg_lianpian"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.heg_mobile_tanfeng",registry="ai_choicemade_filter",path={"cardChosen","heg_mobile_tanfeng"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.heg_mouduan",registry="ai_choicemade_filter",path={"cardChosen","heg_mouduan"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.heg_tenyear_dechao",registry="ai_choicemade_filter",path={"cardChosen","heg_tenyear_dechao"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.heg_zhefu",registry="ai_choicemade_filter",path={"cardChosen","heg_zhefu"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.jianwushu",registry="ai_choicemade_filter",path={"cardChosen","jianwushu"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.jiuwei",registry="ai_choicemade_filter",path={"cardChosen","jiuwei"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.kanshi",registry="ai_choicemade_filter",path={"cardChosen","kanshi"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.kejiexianliwei",registry="ai_choicemade_filter",path={"cardChosen","kejiexianliwei"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.kejieyaoxieqin",registry="ai_choicemade_filter",path={"cardChosen","kejieyaoxieqin"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.kemumu",registry="ai_choicemade_filter",path={"cardChosen","kemumu"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.kenewgirlshibing",registry="ai_choicemade_filter",path={"cardChosen","kenewgirlshibing"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.keyaoxieqin",registry="ai_choicemade_filter",path={"cardChosen","keyaoxieqin"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.luafeiqi",registry="ai_choicemade_filter",path={"cardChosen","luafeiqi"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.luayonglue",registry="ai_choicemade_filter",path={"cardChosen","luayonglue"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.meizlfeiren",registry="ai_choicemade_filter",path={"cardChosen","meizlfeiren"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.meizlguiyuan",registry="ai_choicemade_filter",path={"cardChosen","meizlguiyuan"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.mouxiaoji",registry="ai_choicemade_filter",path={"cardChosen","mouxiaoji"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.mythluochong",registry="ai_choicemade_filter",path={"cardChosen","mythluochong"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.mythmumu",registry="ai_choicemade_filter",path={"cardChosen","mythmumu"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.qhfiremengjin",registry="ai_choicemade_filter",path={"cardChosen","qhfiremengjin"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.qhfirequhu",registry="ai_choicemade_filter",path={"cardChosen","qhfirequhu"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.qhstandardfanjian",registry="ai_choicemade_filter",path={"cardChosen","qhstandardfanjian"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.qhstandardpoxi",registry="ai_choicemade_filter",path={"cardChosen","qhstandardpoxi"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.qhwindfenji",registry="ai_choicemade_filter",path={"cardChosen","qhwindfenji"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.qhwindjiewei",registry="ai_choicemade_filter",path={"cardChosen","qhwindjiewei"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.qhwindshensu",registry="ai_choicemade_filter",path={"cardChosen","qhwindshensu"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.renzha",registry="ai_choicemade_filter",path={"cardChosen","renzha"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.s3_xiaoyong",registry="ai_choicemade_filter",path={"cardChosen","s3_xiaoyong"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.s3_youlong",registry="ai_choicemade_filter",path={"cardChosen","s3_youlong"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.s3_yt_qujin_caoxiu",registry="ai_choicemade_filter",path={"cardChosen","s3_yt_qujin_caoxiu"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.s4_fani",registry="ai_choicemade_filter",path={"cardChosen","s4_fani"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.s4_ganglie",registry="ai_choicemade_filter",path={"cardChosen","s4_ganglie"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.s4_jianghu",registry="ai_choicemade_filter",path={"cardChosen","s4_jianghu"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.s4_kuiwei",registry="ai_choicemade_filter",path={"cardChosen","s4_kuiwei"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.s4_txbw_chili",registry="ai_choicemade_filter",path={"cardChosen","s4_txbw_chili"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.se_mingqie",registry="ai_choicemade_filter",path={"cardChosen","se_mingqie"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.sfofl_lyre",registry="ai_choicemade_filter",path={"cardChosen","sfofl_lyre"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.thedolls",registry="ai_choicemade_filter",path={"cardChosen","thedolls"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.weareidle",registry="ai_choicemade_filter",path={"cardChosen","weareidle"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","dismantlement"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_choicemade_filter.cardChosen.xianzhencard",registry="ai_choicemade_filter",path={"cardChosen","xianzhencard"},canonical_registry="ai_choicemade_filter",canonical_path={"cardChosen","snatch"},self_index=1,defer_canonical=true}
    ai_audited_aliases.register{id="ai_card_intention.huayuanCard",registry="ai_card_intention",path={"huayuanCard"},canonical_registry="ai_card_intention",canonical_path={"IronChain"},self_index=1,defer_canonical=true}
end

function SmartAIView:applyDuTongqueRole(player)
    local witness=nil -- The Tongque choice is not projected.
    if type(witness)~="table" or witness.player~=player:objectName() then
        ai_unsupported("Tongque role effect lacks its current choice witness","du.tongque")
    end
    self:emitStrategyEffect({kind="du_tongque_role",player=player:objectName()})
    return true
end
