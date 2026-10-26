-- Shared strategy hooks for the isolated VM.
local sgs = rawget(_G, "sgs")
if type(sgs) ~= "table" then sgs = {}; rawset(_G, "sgs", sgs) end

-- Category cache keys preserve empty parts and invalidate lazily, matching the source.
function sgs.getSkillList(skill_string_name)
    local cache_name = skill_string_name .. "_list"
    if not sgs[cache_name] then
        local skill_string = sgs[skill_string_name]
        if skill_string then
            local values, from = {}, 1
            if #skill_string > 0 then
                local delimiter = string.find(skill_string, "|", from, true)
                while delimiter do
                    values[#values + 1] = string.sub(skill_string, from, delimiter - 1)
                    from = delimiter + 1
                    delimiter = string.find(skill_string, "|", from, true)
                end
                values[#values + 1] = string.sub(skill_string, from)
            end
            sgs[cache_name] = values
        end
    end
    return sgs[cache_name] or {}
end

local registry_names = {
    "ai_card_intention", "ai_playerchosen_intention", "ai_playerschosen_intention",
    "ai_Yiji_intention", "ai_retrial_intention", "ai_keep_value", "ai_use_value",
    "ai_use_priority", "ai_suit_priority", "ai_chaofeng", "ai_skill_suit",
    "ai_skill_cardask", "ai_general_choice", "ai_general_choice_for_lord",
    "ai_skill_askforag", "ai_skill_askforyiji", "ai_skill_pindian", "ai_filterskill_filter",
    "ai_skill_playerchosen", "ai_skill_discard", "ai_cardshow", "ai_nullification",
    "ai_skill_cardchosen", "ai_cardneed", "ai_skills",
    "ai_slash_weaponfilter", "ai_slash_prohibit", "ai_view_as", "ai_cardsview",
    "ai_cardsview_valuable", "ai_choicemade_filter", "ai_need_damaged", "ai_event_callback",
    "ai_NeedPeach", "ai_judgeGood", "ai_need_kongcheng", "ai_need_retrial", "ai_need_retrial_func", "ai_retrial", "ai_draw_count", "ai_use_revises", "ai_guhuo_card",
    "ai_target_revises", "ai_useto_revises", "ai_skill_defense", "ai_card_priority",
    "ai_poison_card", "ai_skill_playerschosen", "ai_used_revises", "ai_skill_carduse",
    "ai_target_recommend", "ai_target_recommend_global", "ai_damage_reason_suppress_intention",
    "ai_damage_from_flag_intention", "ai_voluntary_give_skills", "ai_card_combo_use", "ai_dont_hurt_from",
    "ai_dont_hurt_to", "ai_hasBuquEffect_skill", "ai_canNiepan_skill", "ai_hasTuntianEffect_skill",
    "ai_getLeastHandcardNum_skill", "ai_getBestHp_skill", "ai_getOverflow_skill", "ai_hasManjuanEffect_skill",
    "ai_canliegong_skill", "damageSkillsList",
    "ai_compare_funcs", "ai_nullification_threat_table", "ai_weapon_value",
    "ai_armor_value", "ai_card_usage_limit", "ai_card_usage_penalty", "ai_suppress_intention",
    "ai_ajustdamage_from", "ai_ajustdamage_to", "ai_can_damagehp", "ai_lijian_effect", "ai_liuli_effect",
    "ai_quhu_effect", "ai_slash_benefit", "ai_type_name", "dynamic_value", "card_damage_nature",
    "card_value", "ai_target_damage", "ai_defense_slash"
}

local choice_legacy = rawget(_G, "ai_choice_legacy_registries")
    or rawget(sgs, "ai_choice_legacy_registries") or {}
if rawget(_G, "ai_choice_legacy_registries") == nil then
    rawset(_G, "ai_choice_legacy_registries", choice_legacy)
end
sgs.ai_choice_legacy_registries = choice_legacy

local choice_names = {
    ai_skill_suit = true, ai_skill_cardask = true,
    ai_general_choice = true, ai_general_choice_for_lord = true,
    ai_skill_askforag = true, ai_skill_askforyiji = true, ai_skill_pindian = true,
    ai_skill_playerchosen = true, ai_skill_discard = true, ai_cardshow = true,
    ai_nullification = true, ai_skill_cardchosen = true,
    ai_skill_playerschosen = true, ai_skill_carduse = true
}

local function bind_registry(name)
    if choice_names[name] and choice_legacy[name] ~= nil then
        sgs[name] = choice_legacy[name]
        return
    end
    local global_value = rawget(_G, name)
    if type(global_value) == "table" then
        sgs[name] = global_value
    elseif type(sgs[name]) == "table" then
        rawset(_G, name, sgs[name])
    else
        local value = {}
        rawset(_G, name, value)
        sgs[name] = value
    end
end

for _, name in ipairs(registry_names) do
    bind_registry(name)
end
-- Choice modules own their complete set of legacy aliases, including extensions
-- such as single Peach, Guanxing and trigger order. Do not maintain a second list.
for name, registry in pairs(choice_legacy) do sgs[name] = registry end

-- These aliases are the original SmartAI tables, not copies.  A package can
-- register through either spelling and every consumer sees the same object.
local aliases = {
    ai_use_revises = "ai_use_revises", ai_target_revises = "ai_target_revises",
    ai_useto_revises = "ai_useto_revises", ai_used_revises = "ai_used_revises",
    cardneed = "ai_cardneed", retrial = "ai_retrial",
    damage = "ai_damage_from_flag_intention",
    besthp = "ai_getBestHp_skill", need_kongcheng = "need_kongcheng",
    lose_equip_skill = "lose_equip_skill", masochism_skill = "masochism_skill",
    Active_cardneed_skill = "Active_cardneed_skill", notActive_cardneed_skill = "notActive_cardneed_skill",
    cardneed_skill = "cardneed_skill", need_equip_skill = "need_equip_skill",
    double_slash_skill = "double_slash_skill",
    drawpeach_skill = "drawpeach_skill", recover_hp_skill = "recover_hp_skill",
    recover_skill = "recover_skill", use_lion_skill = "use_lion_skill",
    straight_damage_skill = "straight_damage_skill", need_maxhp_skill = "need_maxhp_skill", hit_skill = "hit_skill",
    dynamic_value = "dynamic_value", card_damage_nature = "card_damage_nature"
}

local function canonical(name)
    if type(name) ~= "string" or name == "" then return nil end
    if type(sgs[name]) == "table" or type(sgs[name]) == "string" then return name end
    if aliases[name] then return aliases[name] end
    return string.sub(name, 1, 3) == "ai_" and name or "ai_" .. name
end

function SmartAIView:getHooks(name)
    local key = canonical(name)
    -- Migrated policies register only in the native registry; other hook
    -- families retain their existing tables and callback contracts.
    local registry
    if key == "ai_skill_use" then registry = ai_skill_use
    elseif key == "ai_card_use" then registry = ai_card_use
    elseif key == "ai_skill_invoke" then registry = ai_skill_invoke
    elseif key == "ai_fill_skill" then registry = ai_fill_skill
    elseif key == "ai_skill_choice" then registry = ai_skill_choice
    else registry = key and sgs[key] or nil end
    if type(registry)~="table"or type(ai_audited_aliases)~="table"then return registry end
    if getmetatable(registry)==nil and next(registry)==nil then return registry end
    -- Resolve only the hook actually requested. Eagerly scanning every alias
    -- would demand unrelated package metadata and alter presence tests.
    self._audited_hook_views=self._audited_hook_views or{}
    local cached=self._audited_hook_views[key]
    if cached and cached.source==registry then return cached.view end
    local view=setmetatable({}, {
        __index=function(_,hook)return ai_audited_aliases.resolve(self,registry[hook])end,
        __newindex=function(_,hook,value)registry[hook]=value end,
        __len=function()return #registry end,
        __pairs=function()
            local iter,state,first=pairs(registry)
            return function(_,previous)
                local hook,value=iter(state,previous)
                while hook~=nil do
                    value=ai_audited_aliases.resolve(self,value)
                    if value~=nil then return hook,value end
                    hook,value=iter(state,hook)
                end
            end,nil,first
        end })
    self._audited_hook_views[key]={source=registry,view=view}
    return view
end

function SmartAIView:callHook(name, key, ...)
    local registry = self:getHooks(name)
    if type(registry) ~= "table" then return nil end
    local value = registry[key]
    if type(value) == "function" then return value(...) end
    return value
end

function SmartAIView:forSkillHooks(name, player)
    local registry = self:getHooks(name)
    if type(registry) ~= "table" or not AIValue.isPlayer(player) then return nil end
    -- Empty ordinary registries need no skill projection. This also avoids
    -- repeatedly wrapping every skill in requests without package overrides.
    if getmetatable(registry) == nil and next(registry) == nil then return AIList.new({}) end
    local skills = player:getSkills()
    if not skills then return nil end
    local result, seen = {}, {}
    for _, skill in ipairs(skills) do
        local skill_name = skill:objectName()
        if not seen[skill_name] and not skill:isInvalid() then
            seen[skill_name] = true
            local value = registry[skill_name]
            if value ~= nil then result[#result + 1] = {key = skill_name, value = value, skill = skill} end
        end
    end
    return AIList.new(result)
end

-- Stage records contain hook names and ordering only. Policy functions live in
-- their package's ordinary sgs registry slot, preserving the original ABI.
local value_hook_abis = {
    ai_ajustdamage_from = "damage", ai_ajustdamage_to = "damage",
    ai_skill_defense = "defense", ai_getLeastHandcardNum_skill = "least",
    ai_getBestHp_skill = "best", ai_need_kongcheng = "empty",
    ai_getOverflow_skill = "overflow", ai_hasManjuanEffect_skill = "effect",
    ai_need_damaged = "needed", ai_defense_slash = "slash_defense", ai_target_damage = "target_value",
}
local value_contexts = setmetatable({}, {__mode = "k"})
function sgs.isValueHookContext(context)
    return type(context) == "table" and value_contexts[context] == true
end

function sgs.declareValueHookStages(registry_name, key, declarations)
    local registry, abi = sgs[registry_name], value_hook_abis[registry_name]
    assert(type(registry) == "table" and abi and type(key) == "string", "invalid value hook declaration")
    registry._value_hook_abi = abi
    registry._stages = registry._stages or {}
    for _, declaration in ipairs(declarations) do
        local phase, order, rule = declaration.phase, declaration.order, declaration.rule
        assert(type(phase) == "string" and type(order) == "number" and type(rule) == "string", "invalid value hook stage")
        local entries = registry._stages[phase] or {}
        registry._stages[phase] = entries
        local found
        for index, entry in ipairs(entries) do
            if entry.key == key and entry.rule == rule then found = index; break end
        end
        entries[found or #entries + 1] = {key=key, rule=rule, order=order,
            group=declaration.group, pairs_group=declaration.pairs_group}
    end
end

-- Compatibility order only: the source constructed these five keys in one Lua
-- hash part and used pairs. Numeric HP policies belong to the owning packages.
local best_hp_source_order = {ganlu=true,yinghun=true,nosmiji=true,xueji=true,baobian=true}
local function staged_entries(entries)
    local sorted = {}
    for _, entry in ipairs(entries) do sorted[#sorted + 1] = entry end
    table.sort(sorted, function(a, b)
        if a.order ~= b.order then return a.order < b.order end
        if a.key ~= b.key then return a.key < b.key end
        return a.rule < b.rule
    end)
    local result, expanded = {}, {}
    for _, entry in ipairs(sorted) do
        if entry.pairs_group == "best_hp" then
            if not expanded[entry.pairs_group] then
                expanded[entry.pairs_group] = true
                local members = {}
                for _, member in ipairs(sorted) do
                    if member.pairs_group == entry.pairs_group then members[member.key] = member end
                end
                for key in pairs(best_hp_source_order) do
                    if members[key] then result[#result + 1] = members[key] end
                end
            end
        else result[#result + 1] = entry end
    end
    return result
end

function sgs.runValueHookStages(registry, phase, self, player, value, query, ...)
    local entries = registry and registry._stages and registry._stages[phase]
    if not entries then return value, false end -- No enabled package declares this stage.
    local ordered, groups = staged_entries(entries), {}
    local extra = {...}
    for _, entry in ipairs(ordered) do
        local callback = registry[entry.key]
        if type(callback) ~= "function" then ai_unsupported("value hook provider is unavailable", entry.key) end
        local context = {phase=phase, rule=entry.rule, value=value, query=query, extra=extra, self=self}
        if entry.group then
            if groups[entry.group] == nil then
                local names = {}
                for _, member in ipairs(ordered) do
                    if member.group == entry.group then names[#names + 1] = member.key end
                end
                -- Equal-effect alternatives retain one combined visibility query.
                groups[entry.group] = {value=query(player, "hasSkills", table.concat(names, "|"))}
            end
            context.any_skill = groups[entry.group].value
        end
        value_contexts[context] = true
        local result, terminal
        local abi = registry._value_hook_abi
        if abi == "damage" then
            result, terminal = callback(self, extra[1], player, extra[2], type(value)=="table" and value.nature or nil, context)
        elseif abi == "defense" or abi == "target_value" then result, terminal = callback(self, player, context)
        elseif abi == "needed" then result, terminal = callback(self, extra[1], player, extra[2], context)
        elseif abi == "slash_defense" then result, terminal = callback(self, player, self.player, context)
        elseif abi == "best" then result, terminal = callback(player, context)
        elseif abi == "least" or abi == "overflow" then result, terminal = callback(self, player, value, context)
        elseif abi == "empty" then result, terminal = callback(self, player, phase == "keep", context)
        elseif abi == "effect" then result, terminal = callback(self, player, phase == "primary", context)
        else ai_unsupported("value hook ABI is unavailable", phase) end
        value_contexts[context] = nil
        if AIUnsupported.is(result) then error(result, 0) end
        value = result
        if terminal then return value, true end
    end
    return value, false
end

function sgs.getValueHookKeys(registry_name)
    local keys, registry = {}, sgs[registry_name]
    for phase, entries in pairs(registry and registry._stages or {}) do
        for _, entry in ipairs(entries) do keys[#keys + 1] = phase .. "." .. entry.key .. "." .. entry.rule end
    end
    return keys
end

if ai_coverage and type(ai_coverage.declare) == "function" then
    for registry_name in pairs(value_hook_abis) do
        ai_coverage.declare(registry_name, function() return sgs.getValueHookKeys(registry_name) end)
    end
end

return sgs
