PlayerView = {}
CardView = {}
SkillView = {}
RoomView = {}
RoomView.__index = RoomView

-- Keep facade identity separate from Lua's table/userdata distinction.
-- This metadata is not a native-object bridge or a security boundary.
AIValue = {}
AIList = {}
AIList.__index = AIList
local facade_kinds = setmetatable({}, {__mode = "k"})
local lua_array_origins = setmetatable({}, {__mode = "k"})
local r45_physical={rows=setmetatable({},{__mode="k"}),states=setmetatable({},{__mode="k"})}

function AIValue.kind(value)
    if type(value) ~= "table" then return nil end
    return facade_kinds[value]
end

function AIValue.isPlayer(value) return AIValue.kind(value) == "player" end
function AIValue.isDecisionData(value) return AIValue.kind(value) == 'decision_data' end
function AIValue.isCard(value) return AIValue.kind(value) == "card" end
function AIValue.isSkill(value) return AIValue.kind(value) == "skill" end

-- Legacy pointer equality is distinct from card names, printed faces and action
-- receipts. Players have one stable object per request RoomView; cards require
-- the native/policy opaque identity explicitly carried by their descriptor.
function AIValue.sameLegacyIdentity(left, right)
    if rawequal(left, right) then return true end
    local lk, rk = AIValue.kind(left), AIValue.kind(right)
    if lk == "player" and rk == "player" then
        local lr, rr = rawget(left, "_room"), rawget(right, "_room")
        if lr == nil or rr == nil then
            ai_unsupported("player equality requires a bound RoomView", "player_identity")
        end
        return rawequal(lr, rr) and left:objectName() == right:objectName()
    end
    if (lk == "card" or lk == "conversion") and (rk == "card" or rk == "conversion") then
        local first, second = left:getLegacyIdentityToken(), right:getLegacyIdentityToken()
        if type(first) ~= "string" or first == "" or type(second) ~= "string" or second == "" then
            ai_unsupported("native strategy card equality identity is unknown", "card_identity")
        end
        return first == second
    end
    return left == right
end

function AIValue.isList(value)
    if type(value) ~= "table" or AIValue.kind(value) then return false end
    local meta = getmetatable(value)
    if meta ~= nil and meta ~= AIList then return false end
    -- Reject dictionaries and sparse arrays instead of silently iterating zero items.
    local count = 0
    for key in pairs(value) do
        if type(key) ~= "number" or key < 1 or key % 1 ~= 0 then return false end
        count = count + 1
    end
    for index = 1, count do
        if rawget(value, index) == nil then return false end
    end
    return true
end

function AIList.new(values)
    if values == nil then return nil end -- Unknown is never an empty collection.
    assert(AIValue.isList(values), "AIList.new expects a dense value array")
    local result = setmetatable({}, AIList)
    for index, value in ipairs(values) do result[index] = value end
    return result
end

-- Native QList facades keep copy-on-QList2Table semantics. A translated
-- source Lua array can retain QList convenience methods without losing its
-- original in-place sorting/alias behavior. Origin metadata is never serialized.
function AIList.asLuaTable(values)
    assert(AIValue.isList(values), "AIList.asLuaTable expects a dense value array")
    lua_array_origins[values] = true
    return values
end
function AIList.isNativeList(values)
    return getmetatable(values) == AIList and not lua_array_origins[values]
end

function AIList:length() return #self end
function AIList:isEmpty() return #self == 0 end
function AIList:first() return self[1] end
function AIList:last() return self[#self] end
function AIList:at(index)
    -- QList-compatible zero-based access; [] and ipairs stay one-based.
    if type(index) ~= "number" or index % 1 ~= 0 or index < 0 then return nil end
    return self[index + 1]
end
function AIList:contains(value)
    for _, item in ipairs(self) do if AIValue.sameLegacyIdentity(item, value) then return true end end
    return false
end
function AIList:append(value)
    assert(value ~= nil, "AIList:append cannot insert nil")
    self[#self + 1] = value
end
function AIList:removeOne(value)
    for index, item in ipairs(self) do
        if AIValue.sameLegacyIdentity(item, value) then table.remove(self, index) return true end
    end
    return false
end

local function value_iterator(list, index)
    if index < #list - 1 then return index + 1, list[index + 2] end
end

-- The isolated VM has no gameplay utilities. Never replace existing SWIG-aware
-- helpers if this file is loaded beside them; sandbox helpers accept values only.
sgs.qlist = sgs.qlist or function(values)
    assert(AIValue.isList(values), "sgs.qlist expects a known value collection")
    return value_iterator, values, -1
end
sgs.list = sgs.list or function(values)
    assert(AIValue.isList(values), "sgs.list expects a known value collection")
    return ipairs(values)
end
sgs.QList2Table = sgs.QList2Table or function(values)
    if values == nil then return nil end
    assert(AIValue.isList(values), "sgs.QList2Table expects a value collection")
    if not AIList.isNativeList(values) then return values end
    local result = {}
    for index, value in ipairs(values) do result[index] = value end
    return result
end

-- 純值字串工具。共用入口大量使用這幾個方法，全部只做字串處理，不碰 gameplay。
-- 與 gameplay VM 同名同語意；若該環境已有實作則不覆寫。
string.split = string.split or function(self, separator)
    assert(type(self) == "string", "split expects a string")
    if separator == nil or separator == "" then separator = " " end
    local result = {}
    local pattern = "([^" .. separator:gsub("(%W)", "%%%1") .. "]+)"
    for piece in string.gmatch(self, pattern) do result[#result + 1] = piece end
    return result
end

string.contains = string.contains or function(self, text)
    assert(type(self) == "string", "contains expects a string")
    return string.find(self, text, 1, true) ~= nil
end

string.startsWith = string.startsWith or function(self, prefix)
    assert(type(self) == "string", "startsWith expects a string")
    return string.sub(self, 1, string.len(prefix)) == prefix
end

string.endsWith = string.endsWith or function(self, suffix)
    assert(type(self) == "string", "endsWith expects a string")
    return suffix == "" or string.sub(self, -string.len(suffix)) == suffix
end

local player_scalar_aliases = {
    object_name = "objectName",
    role_revealed = "hasShownRole",
    handcard_count = "getHandcardNum",
    face_up = "faceUp",
    in_yinni_state = "inYinniState",
    general = "getGeneralName",
    general2 = "getGeneral2Name"
}

local card_scalar_aliases = {
    id = "getId",
    target_fixed = "targetFixed",
    virtual_card = "isVirtualCard",
    effective_id = "getEffectiveId",
    name = "objectName",
    class_name = "getClassName",
    suit = "getSuit",
    number = "getNumber",
    skill_name = "getSkillName",
    source_skill = "getSourceSkillName",
    can_recast = "canRecast",
    will_throw = "willThrow",
    red = "isRed",
    black = "isBlack"
}

local skill_scalar_aliases = {
    name = "objectName",
    instance_id = "getInstanceId",
    source = "getSource",
    invalid = "isInvalid",
    has_amount_override = "hasAmountOverride",
    amount = "getAmount"
}

local function to_pascal_case(field_name)
    local converted = string.gsub(field_name, "_(%l)", string.upper)
    return string.gsub(converted, "^%l", string.upper)
end

-- Both are pure in their arguments; facades are built per query, so cache them.
local scalar_method_names = setmetatable({}, {__mode = "k"})
local function scalar_method_name(field_name, value_type, aliases)
    local by_aliases = scalar_method_names[aliases]
    if not by_aliases then
        by_aliases = {[true] = {}, [false] = {}}
        scalar_method_names[aliases] = by_aliases
    end
    local boolean = value_type == "boolean"
    local cached = by_aliases[boolean][field_name]
    if cached then return cached end
    local name = aliases[field_name] or ((boolean and "is" or "get") .. to_pascal_case(field_name))
    by_aliases[boolean][field_name] = name
    return name
end

local scalar_getters = {}
local function make_scalar_getter(field_name)
    local getter = scalar_getters[field_name]
    if getter then return getter end
    getter = function(self)
        local view = rawget(self, "_view")
        if type(view) ~= "table" then
            return nil
        end
        return view[field_name]
    end
    scalar_getters[field_name] = getter
    return getter
end

local function lua_facade_index(facade, self, key)
    local member = rawget(facade, key)
    if member ~= nil then
        return member
    end
    local scalar_methods = rawget(self, "_scalar_methods")
    if type(scalar_methods) == "table" then
        return scalar_methods[key]
    end
    return nil
end

-- The native primitive implements this exact table lookup, without caching or
-- native-object access. Bind it directly to avoid an extra Lua call per lookup.
local facade_index = lua_facade_index

local function new_facade(facade, view, aliases)
    if type(view) ~= "table" then
        return nil
    end
    local scalar_methods = {}
    for field_name, value in pairs(view) do
        local value_type = type(value)
        if value_type == "string" or value_type == "number" or value_type == "boolean" then
            local method_name = scalar_method_name(field_name, value_type, aliases)
            if rawget(facade, method_name) == nil and scalar_methods[method_name] == nil then
                scalar_methods[method_name] = make_scalar_getter(field_name)
            end
        end
    end
    return setmetatable({ _view = view, _scalar_methods = scalar_methods }, facade)
end

PlayerView.__index = function(self, key)
    return facade_index(PlayerView, self, key)
end

CardView.__index = function(self, key)
    local row=rawget(self,"_view");local request=type(row)=="table" and r45_physical.rows[row]
    local state=request and r45_physical.states[request]
    if state and state.poison then ai_unsupported(state.poison,"rushB.physical_mutation")end
    return facade_index(CardView, self, key)
end

SkillView.__index = function(self, key)
    return facade_index(SkillView, self, key)
end

-- Display labels are not projected; nil means unknown.
function PlayerView:screenName() return self._view.screen_name end
function PlayerView:getLogName() return self._view.log_name end

function PlayerView:speak(text)
    local ai = self._room and self._room._ai
    if not ai or type(ai._speech_source_key) ~= "string" then
        ai_unsupported("speech needs an active pure policy source", "speech")
    end
    return ai:emitSpeechLine(self, text, ai._speech_source_key)
end

function PlayerView.new(view)
    local result = new_facade(PlayerView, view, player_scalar_aliases)
    if result then
        facade_kinds[result] = "player"
        -- Build once per snapshot.  The raw values remain request-owned; this
        -- index only accelerates read-only skill queries.
        local skills = view.skills
        if AIValue.isList(skills) then
            local by_name, by_instance = {}, {}
            for _, skill in ipairs(skills) do
                if type(skill) == "table" and type(skill.name) == "string" then
                    by_name[skill.name] = by_name[skill.name] or {}
                    by_name[skill.name][#by_name[skill.name] + 1] = skill
                    if type(skill.instance_id) == "number" then
                        by_instance[skill.name .. "#" .. skill.instance_id] = skill
                    end
                end
            end
            result._skill_index = {by_name = by_name, by_instance = by_instance}
        end
    end
    return result
end

function CardView.new(view)
    if type(view)=="table" and r45_physical.card_view then view=r45_physical.card_view(view)end
    local result = new_facade(CardView, view, card_scalar_aliases)
    if result then
        facade_kinds[result] = "card"
        if r45_physical.card_created then r45_physical.card_created(result)end
    end
    return result
end

-- Equality keys reproduce legacy sorting only; they never grant card authority.
function CardView:getLegacyIdentityToken()
    local view = self._view
    local value = view and view.legacy_identity_token
    if type(value) == "string" and value ~= "" then return value end
    -- A physical card is one engine object, as SmartAI's userdata equality sees it.
    if view and view.virtual_card == false and type(view.effective_id) == "number" and view.effective_id >= 0 then
        return "card:" .. view.effective_id
    end
    return nil
end

function CardView:getLegacyStringKey()
    return self._view and self._view.legacy_string_key
end
-- Card::toString is an observed native serialization, never reconstructed
-- from a policy name/face/cost and never a submission capability.
CardView.toString = CardView.getLegacyStringKey
function CardView:getLegacySortKey()
    return self._view and self._view.legacy_sort_key
end

function CardView:getType()
    local view = rawget(self, "_view")
    return type(view) == "table" and ({[0] = "skill", "basic", "trick", "equip"})[view.type_id] or nil
end

function CardView:isVirtualCard()
    local view = rawget(self, "_view")
    if type(view) ~= "table" or type(view.virtual_card) ~= "boolean" then return nil end
    return view.virtual_card
end

function CardView:getNumberString()
    local view = rawget(self, "_view")
    local number = type(view) == "table" and view.number
    if type(number) ~= "number" or number < 0 or number % 1 ~= 0 then return nil end
    if number > 13 then return "JOKER" end
    if number == 10 then return "10" end
    return string.sub("0A23456789-JQK", number + 1, number + 1)
end

function SkillView.new(view)
    local result = new_facade(SkillView, view, skill_scalar_aliases)
    if result then facade_kinds[result] = "skill" end
    return result
end

local function copy_value(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, item in pairs(value) do
        copy[key] = copy_value(item)
    end
    r45_physical.rows[copy]=r45_physical.rows[value]
    return copy
end

local function wrap_values(values, constructor)
    if not AIValue.isList(values) then return nil end
    local result = AIList.new({})
    for _, value in ipairs(values) do
        local wrapped = constructor(copy_value(value))
        if not wrapped then return nil end -- Malformed input is not a partial collection.
        result[#result + 1] = wrapped
    end
    return result
end

function PlayerView:getMark(mark_name)
    local policy = self._room and self._room._world.mode_policy
    local rows = type(policy) == "table" and policy.strategy_marks
    local row = type(rows) == "table" and rows[self:objectName()]
    if type(row) == "table" and type(row[mark_name]) == "number" then return row[mark_name] end
    local view = rawget(self, "_view")
    local marks = type(view) == "table" and view.public_marks or nil
    local value = type(marks) == "table" and marks[mark_name] or nil
    if type(value) == "number" then return value end
    if type(view) == "table" and view.marks_complete == true then return 0 end
    ai_unsupported("mark absence is not visible to this observer", mark_name)
end

-- Explicit strategy priors never change the strict raw snapshot API.
function PlayerView:getStrategyMark(name)
    local policy = self._room and self._room._world.mode_policy
    local rows = type(policy) == "table" and policy.strategy_marks
    local row = type(rows) == "table" and rows[self:objectName()]
    if type(row) == "table" and type(row[name]) == "number" then return row[name] end
    local marks = self._view.public_marks
    if type(marks) == "table" and type(marks[name]) == "number" then return marks[name] end
    if self._view.marks_complete == true then return 0 end
    local ai = self._room and self._room._ai
    if not ai or self:objectName() == ai.player:objectName() then return nil end
    return ai:useKnowledgeEstimate({status="estimate", value=0, player=self:objectName(), mark=name,
        basis="unobserved_private_mark_inactive_prior"}, "Player.getStrategyMark")
end

local function standard_strategy_flag(player, name)
    if name == "AI_NosXuanhuoTarget" then return true end
    local room = player._room
    local world = room and room._world
    if type(name) ~= "string" or not world or not world.self
        or player:objectName() ~= world.self.object_name then return false end
    local h=AIHegemony.facts(world)
    if name=='willSkipPlayPhase' and h and h.enabled==true and h.original_overrides_loaded==true then return true end
    if name == "NosKurou_toDie" or name == "AI_doNotInvoke_qianxi" or name == "AI_doNotInvoke_luoshen"
        or name == "AI_Luoshen_Conflict_With_Guanxing" or name == "stack_overflow_jijiang"
        or name == "should_luawu" or name == "AI_doInvoke_luawu"
        or name == "vecter_friend" or name == "vecter_slash" or name == "AI_XiechanUsing" then return true end
    for _, prefix in ipairs({"nostuxi_isfriend_", "tuxi_isfriend_", "jieyin_isenemy_", "AI_XiansiToFriend_", "sp_qiangxi_isfriend_", "luajiejiang_isfriend_", "AI_TuxiToFriend_"}) do
        if name:sub(1,#prefix) == prefix and room:findPlayerByObjectName(name:sub(#prefix+1),true) then return true end
    end
    if name:find("yj_zhengyuUse",1,true) then
    for _, target in ipairs(room:getAllPlayers(true)) do
        local prefix=target:objectName().."yj_zhengyuUse"
        if name:sub(1,#prefix)==prefix then
            local suffix=name:sub(#prefix+1)
            local id=tonumber(suffix)
            if id and (id%1~=0 or id<0 or tostring(id)~=suffix) then id=nil end
            for _,card in ipairs(world.hand_cards or {}) do if card.effective_id==id then return true end end
            for _,card in ipairs(world.self.equips or {}) do if card.effective_id==id then return true end end
        end
    end
    end
    local suffix = "nosguhuoFailed"
    if name:sub(-#suffix) == suffix then
        local patterns = AICardCatalog.patternNames()
        for _, pattern in ipairs(patterns or {}) do
            if name == pattern .. suffix then return true end
        end
    end
    return false
end

function PlayerView:getStrategyFlag(name)
    local value = self:hasFlag(name)
    local ai = self._room and self._room._ai
    if value == true then return true end
    if not ai then return nil end
    if self:objectName() == ai.player:objectName() then return value end
    local policy = self._room._world.mode_policy
    local row = type(policy) == "table" and type(policy.strategy_flags) == "table" and policy.strategy_flags[self:objectName()]
    if type(row) == "table" and type(row[name]) == "boolean" then return row[name] end
    local strategy = standard_strategy_flag(self,name) or name == "AI_HuangtianPindian" or name == "AI_MizhaoTarget" or name == "AI_doNotSave" or name == "AIGlobal_NeedToWake" or name == "needCrossbow"
        or (type(name) == "string" and name:sub(1,7) == "duelTo_")
        or name == "weapon_done_" .. ai.player:objectName() .. "_" .. self:objectName()
    if strategy and type(policy) == "table" and type(policy.strategy_flags_cleared) == "table"
        and policy.strategy_flags_cleared[self:objectName()] then return false end
    if name == "CurrentPlayer" then return value end
    return ai:useKnowledgeEstimate({status="estimate", value=false, player=self:objectName(), flag=name,
        basis="unobserved_private_flag_inactive_prior"}, "Player.getStrategyFlag")
end

function PlayerView:hasLordSkill(skill_name)
    if type(skill_name) ~= "string" or skill_name == "" then return false end
    local skills = self:getSkills()
    if not skills then return nil end
    for _, skill in ipairs(skills) do
        if skill:objectName() == skill_name then
            local effective = skill:isLordSkillEffective()
            if type(effective) ~= "boolean" then return nil end
            return effective
        end
    end
    return false
end

function PlayerView:hasSkill(skill_name, include_lose)
    if type(skill_name) ~= "string" or skill_name == "" then
        return false
    end
    local base_name, instance_text
    if string.find(skill_name, "#", 1, true) then
        base_name, instance_text = string.match(skill_name, "^(.-)#(%d+)$")
    end
    local instance_id
    if base_name then
        instance_id = tonumber(instance_text)
    else
        base_name = skill_name
    end
    local view = rawget(self, "_view")
    local index = rawget(self, "_skill_index")
    if type(index) ~= "table" then
        return nil
    end
    if instance_id ~= nil then
        local skill = index.by_instance[base_name .. "#" .. instance_id]
        if type(skill) == "table" and (include_lose == true or not skill.invalid) then
            return true
        end
        return false
    end
    for _, skill in ipairs(index.by_name[base_name] or {}) do
        if include_lose == true or not skill.invalid then return true end
    end
    return false
end

-- Snapshot stand-ins for Player::getSkillInstanceIds / hasSkillInstance /
-- isSkillInvalid / getSkillInstanceStateValue. Missing skill projection is
-- unknown (nil); a projected player with no matching instance is empty/false.
function PlayerView:getSkillInstanceIds(skill_name)
    if type(skill_name) ~= "string" or skill_name == "" then return nil end
    local index = rawget(self, "_skill_index")
    if type(index) ~= "table" then return nil end
    local ids = AIList.new({})
    for _, skill in ipairs(index.by_name[skill_name] or {}) do
        if type(skill.instance_id) == "number" and skill.instance_id > 0 then
            ids:append(skill.instance_id)
        end
    end
    return ids
end

function PlayerView:hasSkillInstance(skill_name, instance_id)
    if type(skill_name) ~= "string" or type(instance_id) ~= "number" then
        return false
    end
    local index = rawget(self, "_skill_index")
    if type(index) ~= "table" then return nil end
    return type(index.by_instance[skill_name .. "#" .. instance_id]) == "table"
end

function PlayerView:isSkillInvalid(skill_name, instance_id)
    if type(skill_name) ~= "string" or type(instance_id) ~= "number" then
        return false
    end
    local index = rawget(self, "_skill_index")
    if type(index) ~= "table" then return nil end
    local skill = index.by_instance[skill_name .. "#" .. instance_id]
    if type(skill) ~= "table" then return false end
    return skill.invalid == true
end

function PlayerView:getSkillInstanceStateValue(skill_name, instance_id, key, default_value)
    if type(skill_name) ~= "string" or type(instance_id) ~= "number"
        or type(key) ~= "string" then
        return default_value
    end
    local index = rawget(self, "_skill_index")
    if type(index) ~= "table" then return nil end
    local skill = index.by_instance[skill_name .. "#" .. instance_id]
    if type(skill) ~= "table" then return default_value end
    if type(skill.state) ~= "table" then
        -- Other viewers do not receive private instance state.
        return default_value
    end
    local value = skill.state[key]
    if value == nil then return default_value end
    return copy_value(value)
end

function PlayerView:getSkillInstanceCorrectStateValue(skill_name, instance_id, key, default_value)
    if type(skill_name) ~= "string" or type(instance_id) ~= "number"
        or type(key) ~= "string" then
        return default_value
    end
    local index = rawget(self, "_skill_index")
    if type(index) ~= "table" then return nil end
    local skill = index.by_instance[skill_name .. "#" .. instance_id]
    if type(skill) ~= "table" then return default_value end
    local state = skill.correct_state
    if type(state) ~= "table" then return default_value end
    local value = state[key]
    if value == nil then return default_value end
    return copy_value(value)
end

function PlayerView:getMarkNames()
    local view = rawget(self, "_view")
    local marks = type(view) == "table" and view.public_marks or nil
    if type(marks) ~= "table" then return nil end
    local names = AIList.new({})
    for name in pairs(marks) do
        if type(name) == "string" then names:append(name) end
    end
    table.sort(names) -- Player::getMarkNames iterates QMap keys, not hash order.
    return names
end

function PlayerView:getEquips()
    local view = rawget(self, "_view")
    return wrap_values(type(view) == "table" and view.equips or nil, CardView.new)
end

function PlayerView:getJudgingArea()
    local view = rawget(self, "_view")
    return wrap_values(type(view) == "table" and view.judging_area or nil, CardView.new)
end

-- Common SmartAI queries derived from visible facts; hidden zones never become
-- invented card identities. Missing scalar data stays unknown.
function PlayerView:getLostHp()
    local view = self._view
    if type(view.hp) ~= "number" or type(view.max_hp) ~= "number" then return nil end
    return math.max(0, view.max_hp - view.hp)
end

function PlayerView:isKongcheng()
    local count = self:getHandcardNum()
    if type(count) ~= "number" then return nil end
    return count == 0
end

function PlayerView:isWounded()
    local lost = self:getLostHp()
    if type(lost) ~= "number" then return nil end
    return lost > 0
end

function PlayerView:getAliveSiblings(include_self)
    assert(include_self == nil or type(include_self) == "boolean", "invalid sibling self selector")
    -- Siblings follow the Room roster; player_order is that roster.
    local room = self._room
    local order = room and room._world and room._world.player_order
    if not AIValue.isList(order) then return nil end
    local result, seen = {}, {}
    for _, name in ipairs(order) do
        if type(name) ~= "string" or seen[name] then return nil end
        seen[name] = true
        local player = room:findPlayerByObjectName(name, true)
        if not player then return nil end
        if include_self or name ~= self:objectName() then
            local alive = player:isAlive()
            if type(alive) ~= "boolean" then return nil end
            if alive then result[#result + 1] = player end
        end
    end
    return AIList.new(result)
end

function PlayerView:isAlive()
    local view = self._view
    if type(view) ~= "table" or type(view.alive) ~= "boolean" then return nil end
    return view.alive
end

-- Match Player::getCardCount(bool include_equip=true, bool include_judging=false).
-- SWIG accepts omitted defaults, but explicit arguments must be booleans.
function PlayerView:getCardCount(...)
    local argc = select("#", ...)
    local include_equip, include_judging = ...
    if argc > 2 or (argc >= 1 and type(include_equip) ~= "boolean")
        or (argc >= 2 and type(include_judging) ~= "boolean") then
        error("getCardCount expects zero, one, or two boolean arguments", 2)
    end
    if argc == 0 then include_equip = true end
    if argc < 2 then include_judging = false end
    local view = self._view
    if type(view.handcard_count) ~= "number" then return nil end
    if include_equip and not AIValue.isList(view.equips) then return nil end
    if include_judging and not AIValue.isList(view.judging_area) then return nil end
    return view.handcard_count + (include_equip and #view.equips or 0)
        + (include_judging and #view.judging_area or 0)
end

function PlayerView:isNude()
    local count = self:getCardCount()
    if count == nil then return nil end
    return count == 0
end

function PlayerView:isAllNude()
    local count = self:getCardCount(true, true)
    if count == nil then return nil end
    return count == 0
end

-- Authority facts preserve discard locks; a nonempty zone alone is not legality.
-- The viewer's Player::canDiscard(who, zones); zones is one of h/e/j/he/hj/ej/hej.
function PlayerView:canDiscard(who, flags)
    who = who or self
    if not AIValue.isPlayer(who) then return nil end
    local rows = self._view.can_discard
    local row = type(rows) == "table" and rows[who:objectName()]
    if type(row) ~= "table" then return nil end
    if type(flags) == "number" then
        -- canDiscard(to, card_id): the viewer's own card is its jilei bit; a public
        -- card of another player follows that player's zone answer.
        local card = self._room._ai and self._room._ai:getKnownCardById(flags)
        if not card then return nil end
        if who:objectName() == self:objectName() and card._view.jilei ~= nil then return not card._view.jilei end
        local place = self._room:getCardPlace(flags)
        local zone = place == sgs.Player_PlaceEquip and "e" or place == sgs.Player_PlaceDelayedTrick and "j"
            or place == sgs.Player_PlaceHand and "h" or nil
        return zone and row[zone] or nil
    end
    return row[tostring(flags)]
end

function PlayerView:containsTrick(name)
    local cards = self:getJudgingArea()
    if not cards then return nil end
    for _, card in ipairs(cards) do
        if card:objectName() == name or card:isKindOf(name) then return true end
    end
    return false
end

function PlayerView:getEquipsId()
    local cards = self:getEquips()
    if not cards then return nil end
    local ids = AIList.new({})
    for _, card in ipairs(cards) do ids:append(card:getEffectiveId()) end
    return ids
end

function PlayerView:getJudgingAreaID()
    local cards = self:getJudgingArea()
    if not cards then return nil end
    local ids = AIList.new({})
    for _, card in ipairs(cards) do ids:append(card:getEffectiveId()) end
    return ids
end

local function equipped_kind(player, kind)
    local cards = player:getEquips()
    if not cards then return nil end
    for _, card in ipairs(cards) do if card:isKindOf(kind) then return card end end
end
function PlayerView:getWeapon() return equipped_kind(self, "Weapon") end
function PlayerView:getArmor() return equipped_kind(self, "Armor") end
function PlayerView:getDefensiveHorse() return equipped_kind(self, "DefensiveHorse") end
function PlayerView:getOffensiveHorse() return equipped_kind(self, "OffensiveHorse") end
function PlayerView:getTreasure() return equipped_kind(self, "Treasure") end
function PlayerView:hasWeapon(name)
    if not self:getEquips() then return nil end
    local card = self:getWeapon()
    return card ~= nil and (name == nil or card:objectName() == name or card:isKindOf(name))
end

function PlayerView:hasArmorEffect(name, source)
    -- The snapshot covers the source-independent equipped armor query only.
    if source ~= nil then return nil end
    -- With a view-as equipment source the authority lists every effective armor
    -- name; a class name matches the physical armor only, as in Player.
    local effects = self._view.armor_effect_names
    if AIValue.isList(effects) then
        if name == nil or name == "" then return #effects > 0 end
        local physical = self:getArmor()
        for _, effect in ipairs(effects) do
            if effect == name or physical and physical:objectName() == effect and physical:isKindOf(name) then return true end
        end
        return false
    end
    local active = self._view.active_armor_name
    if type(active) ~= "string" then
        -- Finite Original source names only. A pure host proof may establish
        -- absence from an empty public equipment domain; never infer true or
        -- read foreign private armor/nullification state.
        local ai=self._room and self._room._ai
        local h=ai and ai.world and AIHegemony.facts(ai.world)
        if (name=='SilverLion'or name=='EightDiagram'or name=='bazhen'or name=='Vine'or name=='IronArmor'or name=='RenwangShield'or name=='PeaceSpell'or name=='Breastplate')
            and ai.request and ai.request.kind~='event'
            and h and h.enabled==true and h.original_overrides_loaded==true
            and type(ai_original_sd_choice)=='function' then
            local result=ai_original_sd_choice{op='public_armor_absence',target=self:objectName(),name=name}
            if type(result)=='table'and result.kind=='original_sd_choice'and result.known==true and result.value==false then return false end
        end
        return nil
    end
    if name == nil or name == "" then return active ~= "" end
    local armor = self:getArmor()
    return active ~= "" and (active == name or armor ~= nil and armor:isKindOf(name))
end

function PlayerView:hasFlag(name)
    local kurouAI=self._room and self._room._ai
    local kurouFacts=kurouAI and AIHegemony.facts(kurouAI.world)
    if name=='Kurou_toDie' and kurouAI and kurouFacts and kurouFacts.enabled==true and kurouFacts.original_overrides_loaded==true then
        if self:objectName()~=kurouAI.player:objectName()then
            ai_unsupported('foreign Original Kurou policy flag is private','Kurou_toDie')
        end
        return kurouAI:getOriginalKurouToDie()
    end
    local ai=self._room and self._room._ai
    local h=ai and AIHegemony.facts(ai.world)
    if name=='willSkipPlayPhase' and ai and self:objectName()==ai.player:objectName()
        and h and h.enabled==true and h.original_overrides_loaded==true then
        return ai:readOriginalGuanxingShadow()
    end
    local policy = self._room and self._room._world.mode_policy
    local strategy = standard_strategy_flag(self,name) or name == "AI_HuangtianPindian" or name == "AI_MizhaoTarget" or name == "AI_doNotSave" or name == "AIGlobal_NeedToWake" or name == "needCrossbow"
        or (self._room and self._room._world.self and name == "weapon_done_" .. self._room._world.self.object_name .. "_" .. self:objectName())
        or (type(name) == "string" and name:sub(1,7) == "duelTo_")
    if strategy and type(policy) == "table" then
        local rows = policy.strategy_flags
        local row = type(rows) == "table" and rows[self:objectName()]
        if type(row) == "table" and type(row[name]) == "boolean" then return row[name] end
        if type(policy.strategy_flags_cleared) == "table" and policy.strategy_flags_cleared[self:objectName()] then return false end
    end
    if name == "CurrentPlayer" and self._room then
        local current = self._room._world.current_player
        if type(current) ~= "string" then return nil end
        return self:objectName() == current
    end
    local flags = self._view.flags
    if not AIValue.isList(flags) then return nil end
    for _, flag in ipairs(flags) do if flag == name then return true end end
    return false
end

function PlayerView:isSkipped(phase)
    local skipped = self._view.skipped_phases
    if type(skipped) ~= "table" then return nil end
    local value = skipped[phase]
    if value == nil then value = skipped[tostring(phase)] end
    return value
end

function PlayerView:getHandcards()
    -- Only the request viewer receives hand identities. Unknown is not an empty hand.
    local cards = rawget(self, "_hand_cards")
    if type(cards) ~= "table" then return nil end
    return wrap_values(cards, CardView.new)
end

function PlayerView:handCards()
    local cards = self:getHandcards()
    if not cards then return nil end
    local ids = AIList.new({})
    for _, card in ipairs(cards) do ids[#ids + 1] = card:getId() end
    return ids
end

function PlayerView:isLastHandCard(card, contain)
    if not AIValue.isCard(card) then return nil end
    local hand = self:handCards()
    if hand == nil then return nil end
    local virtual = card:isVirtualCard()
    if virtual == nil then return nil end
    if virtual then
        local ids = card:getSubcards()
        if ids == nil then return nil end
        if #ids > 0 then
            if contain then
                for _, id in ipairs(hand) do if not ids:contains(id) then return false end end
                return true
            elseif #ids >= #hand then
                for _, id in ipairs(ids) do if not hand:contains(id) then return false end end
                return true
            end
        end
    end
    return #hand == 1 and hand:contains(card:getEffectiveId())
end

function PlayerView:isJilei(card)
    if not AIValue.isCard(card) then return nil end
    local view = rawget(card, "_view")
    if type(view) == "table" and (view.evaluation_owner or view.activation_owner) == self:objectName()
        and type(view.jilei) == "boolean" then return view.jilei end
    if card:isVirtualCard() ~= false then return nil end
    local own = rawget(self, "_own_card_rows")
    local state = type(own) == "table" and own[card:getEffectiveId()]
    if type(state) == "table" and type(state.jilei) == "boolean" then return state.jilei end
    local rows = rawget(self, "_card_candidates")
    local row = type(rows) == "table" and rows[card:getEffectiveId()]
    if type(row) ~= "table" or type(row.jilei) ~= "boolean" then return nil end
    return row.jilei
end

function PlayerView:isLocked(card)
    if not AIValue.isCard(card) then return nil end
    local view = rawget(card, "_view")
    if type(view) == "table" and (view.evaluation_owner or view.activation_owner) == self:objectName()
        and type(view.locked) == "boolean" then return view.locked end
    if card:isVirtualCard() ~= false then return nil end
    local own = rawget(self, "_own_card_rows")
    local state = type(own) == "table" and own[card:getEffectiveId()]
    if type(state) ~= "table" or type(state.locked) ~= "boolean" then return nil end
    return state.locked
end

function PlayerView:getCards(flags)
    if type(flags) ~= "string" or flags == "" or string.find(flags, "[^hej]") then
        return nil
    end
    local result = AIList.new({})
    local zones = {{"h", "getHandcards"}, {"e", "getEquips"}, {"j", "getJudgingArea"}}
    for _, zone in ipairs(zones) do
        if string.find(flags, zone[1], 1, true) then
            local cards = self[zone[2]](self)
            -- Never return a partial selection when a requested zone is hidden.
            if not cards then return nil end
            for _, card in ipairs(cards) do result[#result + 1] = card end
        end
    end
    return result
end

-- 牌區投影。未知、部分可見與已知為空是三種不同的答案：查不到的牌區回 nil，
-- 已知為空回空集合，而且任何查詢都只用快照，不會拿 ID 去問 Engine。
function PlayerView:getKnownCards()
    local view = rawget(self, "_view")
    if type(view) ~= "table" then return nil end
    local own = rawget(self, "_hand_cards")
    if type(own) == "table" then return wrap_values(own, CardView.new) end
    return wrap_values(view.known_cards, CardView.new)
end

function PlayerView:isHandVisible()
    local view = rawget(self, "_view")
    if type(view) ~= "table" or view.hand_visible == nil then return nil end
    return view.hand_visible == true
end

local function pile_entry(view, pile_name)
    local piles = type(view) == "table" and view.piles or nil
    if not AIValue.isList(piles) then return nil end
    for _, pile in ipairs(piles) do
        if type(pile) == "table" and pile.name == pile_name then return pile end
    end
    return nil
end

-- Notified selection piles are viewer disclosures, not real owned piles.
-- Piles notified to the viewer without being its own are not projected: unknown.
function PlayerView:getNotifiedPile(name) return nil end
function PlayerView:getNotifiedPileCards(name) return nil end
function PlayerView:getNotifiedTag(key) return nil end

function PlayerView:getPileNames()
    local view = rawget(self, "_view")
    local piles = type(view) == "table" and view.piles or nil
    if not AIValue.isList(piles) then return nil end
    local names = AIList.new({})
    for _, pile in ipairs(piles) do names[#names + 1] = pile.name end
    return names
end

function PlayerView:getPile(pile_name)
    -- 關閉的牌堆沒有 card_ids：那是「看不到」，不是「沒有牌」。
    local pile = pile_entry(rawget(self, "_view"), pile_name)
    if not pile and AIValue.isList(self._view.piles) then return AIList.new({}) end
    if not pile or not AIValue.isList(pile.card_ids) then return nil end
    return AIList.new(pile.card_ids)
end

function PlayerView:getPileCount(pile_name)
    local pile = pile_entry(rawget(self, "_view"), pile_name)
    if not pile and AIValue.isList(self._view.piles) then return 0 end
    return pile and pile.count or nil
end

function PlayerView:getHandPile()
    local view = rawget(self, "_view")
    local piles = type(view) == "table" and view.piles or nil
    if not AIValue.isList(piles) then return nil end
    local result = AIList.new({})
    for _, pile in ipairs(piles) do
        if pile.hand_pile then
            if not AIValue.isList(pile.card_ids) then return nil end
            for _, id in ipairs(pile.card_ids) do result[#result + 1] = id end
        end
    end
    return result
end

-- Failure boundaries: closed pile, missing metadata, or mismatched ids are unknown.
-- A known empty pile remains empty; no Engine lookup is allowed from this VM.
function PlayerView:getHandPileCards()
    local piles = self._view.piles
    if not AIValue.isList(piles) then return nil end
    local result = AIList.new({})
    for _, pile in ipairs(piles) do
        if pile.hand_pile then
            if not AIValue.isList(pile.card_ids) then return nil end
            if #pile.card_ids > 0 then
                local cards = wrap_values(pile.cards, CardView.new)
                if not cards or #cards ~= #pile.card_ids then return nil end
                for i, card in ipairs(cards) do
                    if card:getId() ~= pile.card_ids[i] then return nil end
                    result:append(card)
                end
            end
        end
    end
    return result
end

-- Player::canSeeHandcard is projected for the actual viewer only. A public
-- target face does not grant a query from some other player's perspective.
function PlayerView:canSeeHandcard(other)
    if not AIValue.isPlayer(other) then return nil end
    local room = rawget(self, "_room")
    local world = room and rawget(room, "_world")
    if type(world) ~= "table" or type(world.self) ~= "table"
        or self:objectName() ~= world.self.object_name or rawget(other, "_room") ~= room then return nil end
    if self:objectName() == other:objectName() then return true end
    local visible = rawget(other, "_view").hand_visible
    if type(visible) == "boolean" then return visible end
    return nil
end

function PlayerView:getPileName(card_id)
    local view = rawget(self, "_view")
    local piles = type(view) == "table" and view.piles or nil
    if not AIValue.isList(piles) then return nil end
    local complete = true -- every pile is listed; a closed one clears this below
    for _, pile in ipairs(piles) do
        if AIValue.isList(pile.card_ids) then
            for _, id in ipairs(pile.card_ids) do
                if id == card_id then return pile.name end
            end
        else complete = false end
    end
    for _, zone in ipairs{{"getHandcards","hand_area"},{"getEquips","equip_area"},{"getJudgingArea","judge_area"}} do
        local cards=self[zone[1]](self)
        if cards then for _,card in ipairs(cards)do if card:getEffectiveId()==card_id then return zone[2] end end end
    end
    if complete then return "" end
    return nil
end

function PlayerView:getDisplayCards()
    local view = rawget(self, "_view")
    if type(view) ~= "table" or not AIValue.isList(view.display_cards) then return nil end
    return AIList.new(view.display_cards)
end

function PlayerView:hasCard(card)
    -- Player::hasCard(Card*) delegates to effective ID, then checks printed
    -- hand/equipment IDs only. Judgment and special piles are not ownership
    -- for this query; a virtual card's subcards are not checked individually.
    if card == nil then return false end
    local id = AIValue.isCard(card) and card:getEffectiveId() or card
    if type(id) ~= "number" or id ~= id or id == math.huge or id == -math.huge
        or id % 1 ~= 0 then return nil end
    if id < 0 then return false end
    local hand, equips = self:getHandcards(), self:getEquips()
    local known = hand or self:getKnownCards()
    for _, cards in ipairs({known or {}, equips or {}}) do
        for _, item in ipairs(cards) do if item:getId() == id then return true end end
    end
    -- An identity lawfully located elsewhere cannot also be a hidden hand card.
    if self._room and self._room:isCardKnown(id) then return false end
    local count = self:getHandcardNum()
    local hand_complete = hand ~= nil or type(count) == "number"
        and (count == 0 or known ~= nil and #known == count)
    if hand_complete and equips ~= nil then return false end
    return nil
end

function PlayerView:getSkills()
    local view = rawget(self, "_view")
    if type(view) ~= "table" or not AIValue.isList(view.skills) then return nil end
    return wrap_values(copy_value(view.skills), SkillView.new)
end

-- Player::getVisibleSkillList uses the deduplicated, name-ordered skill map.
-- Invalid instances remain visible; validity is a separate hasSkill question.
function PlayerView:getVisibleSkillList(include_equip)
    local skills = self:getSkills()
    if not skills then return nil end
    -- Player::hasEquipSkill: a skill named after an equipment card.
    local equips
    if type(ai_card_catalog) == "table" then
        equips = {}
        for _, row in ipairs(ai_card_catalog) do
            if row.type_id == sgs.Card_TypeEquip then equips[row.name] = true end
        end
    end
    local rows, seen = {}, {}
    for _, skill in sgs.qlist(skills) do
        local name = skill:objectName()
        if type(name) ~= "string" then return nil end
        if not seen[name] then
            seen[name] = true
            local converted = skill:inherits("SPConvertSkill")
            if name:sub(1, 1) ~= "#" and converted ~= true then
                if converted == nil then return nil end
                if not include_equip and type(equips) ~= "table" then return nil end
                if include_equip or equips[name] ~= true then rows[#rows + 1] = skill end
            end
        end
    end
    table.sort(rows, function(a, b) return a:objectName() < b:objectName() end)
    return AIList.new(rows)
end

function PlayerView:hasSkills(skill_names)
    if type(skill_names) ~= "string" then return false end
    local view = rawget(self, "_view")
    if type(view) ~= "table" or not AIValue.isList(view.skills) then return nil end
    -- Match Player::hasSkills: OR groups of AND terms, including empty terms.
    for group in string.gmatch(skill_names .. "|", "(.-)|") do
        local matches = true
        for name in string.gmatch(group .. "+", "(.-)%+") do
            if not self:hasSkill(name) then matches = false break end
        end
        if matches then return true end
    end
    return false
end

function CardView:getRange()
    return self._view.weapon_range
end

function CardView:getSuitString()
    local suit = self._view.suit
    for _, entry in ipairs({{"Spade", "spade"}, {"Club", "club"}, {"Heart", "heart"},
        {"Diamond", "diamond"}, {"NoSuitRed", "no_suit_red"},
        {"NoSuitBlack", "no_suit_black"}, {"NoSuit", "no_suit"}}) do
        local value = sgs["Card_" .. entry[1]]
        if value ~= nil and suit == value then return entry[2] end
    end
    return nil -- Missing/unknown suit is not the known no-suit value.
end

-- Fixed Card::getColor(card.cpp289): already-projected effective suit only.
function CardView:getColor()
    local suit=self._view.suit
    if type(suit)~='number' or suit%1~=0 or suit < -1 or suit > 6 then return nil end
    if suit==0 or suit==1 or suit==4 then return 1 end
    if suit==2 or suit==3 or suit==5 then return 0 end
    return 2
end

-- Card::sameColorWith: null short-circuits, otherwise compare disclosed colors.
function CardView:sameColorWith(other)
    if other == nil then return false end
    if not AIValue.isCard(other) and not AIValue.isConversion(other) then
        error("sameColorWith expects a Card", 2)
    end
    local first, second = CardView.getColor(self), CardView.getColor(other)
    if first == nil or second == nil then
        ai_unsupported("sameColorWith requires both disclosed effective suits", "sameColorWith")
    end
    return first == second
end

function CardView:getColorString()
    if self:isRed() then return "red" end
    if self:isBlack() then return "black" end
    return nil
end

function CardView:hasSuit()
    local suit = self:getSuitString()
    return suit == "spade" or suit == "club" or suit == "heart" or suit == "diamond"
end

-- R53 Diou source dependency. Native owner-hand observation only; flags or
-- material identity alone never manufacture a known tip result.
function CardView:hasTip(name, split)
    local view=rawget(self,"_view")
    local tips=type(view)=="table" and view.known_tips
    if name=="tanban" and (split==nil or split==true)
        and type(tips)=="table" and type(tips.tanban)=="boolean" then
        return tips.tanban
    end
    ai_unsupported("card tip requires its current owner-hand native observation","hasTip")
end

function CardView:hasFlag(name)
    if type(name) ~= "string" or name == "" then return false end
    local view = rawget(self, "_view")
    if name == "using" and type(view) == "table" and type(view.using) == "boolean" then
        return view.using
    end
    if name == "AIGlobal_KillOff" and type(view) == "table" and type(view.kill_off) == "boolean" then
        return view.kill_off
    end
    local known = type(view) == "table" and view.known_flags
    if type(known) == "table" and type(known[name]) == "boolean" then return known[name] end
    -- Owning a physical card does not disclose another observer's private
    -- visibility relationship. This is unknown for the entire namespace,
    -- independent of whether a hidden marker actually exists.
    if type(view) == "table" and view.flags_complete_scope == "owner_non_visibility"
        and name:sub(1, 8) == "visible_" then return nil end
    if type(view) == "table" and view.flags_complete == true then return false end
    local flags = type(view) == "table" and view.flags or nil
    if not AIValue.isList(flags) then return nil end
    for _, flag in ipairs(flags) do if flag == name then return true end end
    return false
end

function CardView:isKindOf(card_type)
    if type(card_type) ~= "string" or card_type == "" then
        return false
    end
    local view = rawget(self, "_view")
    local kind_of = type(view) == "table" and view.kind_of or nil
    if type(kind_of) ~= "table" then
        return nil
    end
    for _, name in ipairs(kind_of) do
        if name == card_type then
            return true
        end
    end
    return false
end

-- 卡牌結構與技能種類：子牌與類別鏈是純值，`inherits` 只比對快照裡的類別名，
-- 不會回查 Engine 的技能物件。
function CardView:getSubcards()
    local view = rawget(self, "_view")
    if type(view) ~= "table" or not AIValue.isList(view.subcards) then return nil end
    return AIList.new(view.subcards)
end

function CardView:subcardsLength()
    local subcards = self:getSubcards()
    if subcards then return #subcards end
    -- A scoped public use may disclose the count without disclosing cost IDs.
    local count = self._view.subcard_count
    if type(count)=="number" and count>=0 and count<math.huge and count%1==0 then return count end
end

function SkillView:getLimitMark() return self._view.limit_mark end
function SkillView:getDescription() return self._view.description end
function SkillView:isLimitedSkill()
    local frequency = self._view.frequency
    if type(frequency) ~= "number" or type(sgs.Skill_Limited) ~= "number" then return nil end
    return frequency == sgs.Skill_Limited
end

function SkillView:getSkillClass()
    local view = rawget(self, "_view")
    local classes = type(view) == "table" and view.skill_classes or nil
    if not AIValue.isList(classes) then return nil end
    return classes[1]
end

function SkillView:inherits(class_name)
    local view = rawget(self, "_view")
    local classes = type(view) == "table" and view.skill_classes or nil
    if not AIValue.isList(classes) then return nil end
    for _, name in ipairs(classes) do
        if name == class_name then return true end
    end
    return false
end


-- Engine::getTriggerSkill(name) casts the same registered Skill whose complete
-- native metaobject chain is projected in this lawful SkillView. Missing class
-- metadata remains unknown; no skill-name convention or ownership inference.
function SkillView:isTriggerSkill()
    return self:inherits("TriggerSkill")
end

-- 裝備欄位以原生槽號索引；空欄位就是沒有這個鍵，不是 0。
function PlayerView:getEquip(slot)
    local view = rawget(self, "_view")
    local slots = type(view) == "table" and view.equip_slots or nil
    if type(slots) ~= "table" or type(slot) ~= "number" then return nil end
    return slots[slot + 1]
end

function PlayerView:hasEquip(slot)
    if slot == nil then
        local equips = self:getEquips()
        if equips == nil then return nil end
        return #equips > 0
    end
    if AIValue.isCard(slot) then
        local equips = self:getEquips()
        if equips == nil then return nil end
        local virtual = slot:isVirtualCard()
        if virtual == nil then return nil end
        local ids = virtual and slot:getSubcards() or AIList.new({slot:getId()})
        if ids == nil then return nil end
        for _, equip in ipairs(equips) do
            if ids:contains(equip:getId()) then return true end
        end
        return false
    end
    local equipped = self:getEquip(slot)
    if equipped == nil then
        local view = rawget(self, "_view")
        if type(view) ~= "table" or type(view.equip_slots) ~= "table" then return nil end
    end
    return equipped ~= nil
end

function SkillView:getState()
    local view = rawget(self, "_view")
    if type(view) ~= "table" or type(view.state) ~= "table" then
        return nil
    end
    return copy_value(view.state)
end

function SkillView:getStateValue(key, default_value)
    local view = rawget(self, "_view")
    local state = type(view) == "table" and view.state or nil
    local value = type(state) == "table" and state[key] or nil
    if value == nil then
        return default_value
    end
    return copy_value(value)
end

function SkillView:getCorrectState()
    local view = rawget(self, "_view")
    local state = type(view) == "table" and view.correct_state or nil
    return copy_value(type(state) == "table" and state or {})
end

function SkillView:getCorrectStateValue(key, default_value)
    local view = rawget(self, "_view")
    local state = type(view) == "table" and view.correct_state or nil
    local value = type(state) == "table" and state[key] or nil
    if value == nil then
        return default_value
    end
    return copy_value(value)
end

-- 牌的位置索引完全由快照組成：本人手牌、各玩家可見牌／裝備／判定區／開放牌堆與棄牌堆。
-- 沒建到索引裡的 ID 就是未知，回 nil，不會改用 Engine 補讀。
local function index_card_locations(room)
    local locations = {}
    local function add(card_id, owner, place)
        if type(card_id) == "number" and locations[card_id] == nil then
            locations[card_id] = {owner = owner, place = place}
        end
    end
    local world = room._world
    local function add_cards(cards, owner, place)
        if not AIValue.isList(cards) then return end
        for _, card in ipairs(cards) do
            if type(card) == "table" then add(card.id, owner, place) end
        end
    end
    local function add_player(view)
        if type(view) ~= "table" then return end
        local owner = view.object_name
        add_cards(view.equips, owner, sgs.Player_PlaceEquip)
        add_cards(view.judging_area, owner, sgs.Player_PlaceJudge)
        add_cards(view.known_cards, owner, sgs.Player_PlaceHand)
        if AIValue.isList(view.piles) then
            for _, pile in ipairs(view.piles) do
                if type(pile) == "table" and AIValue.isList(pile.card_ids) then
                    for _, id in ipairs(pile.card_ids) do
                        add(id, owner, sgs.Player_PlaceSpecial)
                    end
                end
            end
        end
    end
    add_player(world.self)
    add_cards(world.hand_cards, world.self and world.self.object_name, sgs.Player_PlaceHand)
    if AIValue.isList(world.players) then
        for _, view in ipairs(world.players) do add_player(view) end
    end
    add_cards(world.discard_pile, nil, sgs.Player_DiscardPile)
    return locations
end

function RoomView.new(world)
    if type(world) ~= "table" or type(world.self) ~= "table"
        or not AIValue.isList(world.players) then return nil end
    local room = setmetatable({_world = world, _players = {}, _player_order = {}}, RoomView)
    facade_kinds[room] = "room"
    local function add(view)
        if type(view) ~= "table" or type(view.object_name) ~= "string"
            or view.object_name == "" or room._players[view.object_name] then return false end
        room._players[view.object_name] = PlayerView.new(view)
        room._players[view.object_name]._room = room
        room._player_order[#room._player_order + 1] = view.object_name
        return true
    end
    if not add(world.self) then return nil end
    for _, view in ipairs(world.players) do
        if not add(view) then return nil end
    end
    -- A fresh identity map belongs to this decision, never to a VM-global cache.
    room._players[world.self.object_name]._hand_cards = world.hand_cards
    room._card_locations = index_card_locations(room)
    return room
end

local function players_in_order(room, order)
    if not AIValue.isList(order) then return nil end
    local result = AIList.new({})
    for _, name in ipairs(order) do
        local player = room._players[name]
        if not player then return nil end
        result[#result + 1] = player
    end
    return result
end

function RoomView:getMode()
    return self._world.mode_id
end

function RoomView:getTurnCount()
    local count = self._world.turn_count
    if type(count) ~= "number" then return nil end
    return count
end

function RoomView:getCurrent()
    return self._players[self._world.current_player]
end

function RoomView:getCurrentDyingPlayer()
    local name = self._world.current_dying
    if type(name) ~= "string" then
        ai_unsupported("current dying player is not projected", "current_dying")
    end
    if name == "" then return nil end
    local player = self._players[name]
    if not player then ai_unsupported("current dying player is outside viewer snapshot", "current_dying_player") end
    return player
end

function RoomView:getPlayers()
    return players_in_order(self, self._world.player_order)
end

function RoomView:getAlivePlayers()
    return players_in_order(self, self._world.alive_player_order)
end

function RoomView:alivePlayerCount()
    local players = self:getAlivePlayers()
    if not players then return nil end
    return #players
end

-- 存活玩家裡第一個持有該技能的人。技能表不完整時回 nil，掃完沒有則也是 nil。
function RoomView:findPlayerBySkillName(skill_name)
    if type(skill_name) ~= "string" or skill_name == "" then return nil end
    local players = self:getAlivePlayers()
    if not players then return nil end
    for _, player in ipairs(players) do
        local has = player:hasSkill(skill_name)
        if has == nil then return nil end
        if has then return player end
    end
end

function RoomView:getAllPlayers(include_dead)
    local players = self:getPlayers()
    if not players then return nil end
    local first
    for index, player in ipairs(players) do
        if player == self:getCurrent() then first = index break end
    end
    -- Match RoomRoster::orderedFrom, including its no-current roster fallback.
    if not first then return players end
    local result = AIList.new({})
    for offset = 0, #players - 1 do
        local player = players[(first + offset - 1) % #players + 1]
        if include_dead or player:isAlive() then result[#result + 1] = player end
    end
    return result
end

function RoomView:getOtherPlayers(except, include_dead)
    local players = self:getAllPlayers(include_dead)
    if not players then return nil end
    local result = AIList.new({})
    for _, player in ipairs(players) do
        if player ~= except then result[#result + 1] = player end
    end
    return result
end

function RoomView:findPlayerByObjectName(name, include_dead)
    local player = self._players[name]
    if not player then return nil end
    if include_dead or player:isAlive() then return player end
end


function RoomView:getDiscardPile()
    local cards = self._world.discard_pile
    if not AIValue.isList(cards) then return nil end
    local ids = AIList.new({})
    for _, card in ipairs(cards) do ids[#ids + 1] = card.id end
    return ids
end

function RoomView:getDiscardCards()
    return wrap_values(self._world.discard_pile, CardView.new)
end

function RoomView:getCardOwner(card_id)
    local located = self._card_locations[card_id]
    return located and located.owner and self._players[located.owner] or nil
end

function RoomView:getCardPlace(card_id)
    -- Native CardLocationIndex::place returns PlaceUnknown for virtual IDs;
    -- undisclosed positive IDs still carry no location information here.
    if type(card_id) == "number" and card_id < 0 and card_id % 1 == 0 then
        return sgs.Player_PlaceUnknown
    end
    local located = self._card_locations[card_id]
    return located and located.place or nil
end

function RoomView:isCardKnown(card_id)
    if self._card_locations[card_id] ~= nil then return true end
    -- A card the current question discloses is known even without a location.
    return self._ai ~= nil and self._ai:getChoiceCard(card_id) ~= nil
end

-- Lifecycle epochs from public turn structure. GameRule clears a player's flags and
-- "-Clear" marks when that player's turn ends, "-PlayClear" marks when its Play phase
-- ends, and every mark at burial. Global_TurnCount is a broadcast mark, so a missing
-- entry is zero. The counters only ever grow, which is all an observer cache needs.
AIWorldLifecycle = {}

local function lifecycle_epoch(world, view, kind)
    local marks = type(view.public_marks) == "table" and view.public_marks or {}
    local turns = tonumber(marks.Global_TurnCount) or 0
    local in_turn = world.current_player == view.object_name
        and world.current_phase ~= sgs.Player_NotActive
    local dead = view.alive == false and 1 or 0
    if kind == "all_mark" then return dead end
    if kind == "play" then
        local in_play = in_turn and type(world.current_phase) == "number"
            and world.current_phase <= sgs.Player_Play
        return math.max(0, turns - (in_play and 1 or 0)) + dead
    end
    return math.max(0, turns - (in_turn and 1 or 0)) + dead
end

-- Static engine card kinds, pushed once by the host as ai_card_catalog (engine
-- order, one row per card name). Nil means the host did not provide it.
AICardCatalog = {}

-- The catalog never changes after initialization, so its indexes are built once.
local catalog_index
local function catalog()
    if catalog_index then return catalog_index end
    if type(ai_card_catalog) ~= "table" then return nil end
    local by_name, names, classes = {}, {}, {}
    for _, row in ipairs(ai_card_catalog) do
        by_name[row.name] = by_name[row.name] or row
        classes[row.class_name] = row.name
        if not row.banned and row.name:sub(1, 1) ~= "_" and row.type_id < sgs.Card_TypeEquip then
            names[#names + 1] = row.name
        end
    end
    catalog_index = {by_name = by_name, names = names, classes = classes}
    return catalog_index
end

function AICardCatalog.get(name)
    local index = catalog()
    return index and index.by_name[name] or nil
end

-- SmartAI's patterns(): unbanned basic and trick names without a leading "_".
function AICardCatalog.patternNames()
    local index = catalog()
    return index and copy_value(index.names) or nil
end

-- SmartAI's class_to_name: the last card name registered for each class.
function AICardCatalog.patternClassNames()
    local index = catalog()
    return index and copy_value(index.classes) or nil
end

-- One class_to_name entry, without copying the whole map.
function AICardCatalog.patternName(class_name)
    local index = catalog()
    if not index then return nil end
    return index.classes[class_name] or false
end

-- Hegemony facts from the viewer's snapshot and this VM's own registries. The
-- original-hegemony overrides load exactly when hegemony is enabled.
AIHegemony = {}

local function registry_presence(registry)
    return setmetatable({}, {__index = function(_, name)
        local callbacks = sgs[registry]
        return type(callbacks) == "table" and type(callbacks[name]) == "function"
    end})
end

local hegemony_cache = setmetatable({}, {__mode = "k"})
function AIHegemony.facts(world)
    if type(world) ~= "table" or type(world.enable_hegemony) ~= "boolean" then return nil end
    if hegemony_cache[world] then return hegemony_cache[world] end
    local enabled = world.enable_hegemony
    local players = {}
    local function add(view)
        if type(view) ~= "table" or type(view.object_name) ~= "string" then return end
        local head = type(view.general) == "string" and view.general ~= "" and view.general ~= "anjiang"
        local deputy = type(view.general2) == "string" and view.general2 ~= "" and view.general2 ~= "anjiang"
        local kingdom = (head or deputy or not enabled) and view.kingdom or ""
        players[view.object_name] = {shown_head = head, shown_deputy = deputy,
            shown_one = head or deputy, shown_all = head and (deputy or not enabled and view.general2 == ""),
            public_kingdom = kingdom or "",
            public_careerist = enabled and (head or deputy) and view.role == "careerist"}
    end
    add(world.self)
    for _, view in ipairs(type(world.players) == "table" and world.players or {}) do add(view) end
    local trick_prohibit = {}
    for name, callback in pairs(type(sgs.ai_trick_prohibit) == "table" and sgs.ai_trick_prohibit or {}) do
        if type(name) == "string" and type(callback) == "function" then trick_prohibit[#trick_prohibit + 1] = name end
    end
    local own = world.self and world.self.kingdom
    if world.self and world.self.role == "careerist" then own = "careerist" end
    local facts = {enabled = enabled, original_overrides_loaded = enabled, players = players,
        own_kingdom = (type(own) == "string" and own ~= "") and own or "unknown",
        view_as_presence = registry_presence("ai_view_as"),
        cardsview_presence = registry_presence("ai_cardsview"),
        need_damaged_presence = registry_presence("ai_need_damaged"),
        armor_value_presence = registry_presence("ai_armor_value"),
        trick_prohibit_functions = trick_prohibit}
    hegemony_cache[world] = facts
    return facts
end

-- kind: "flag" (alias "turn"), "play" or "all_mark". Returns name -> epoch.
function AIWorldLifecycle.epochs(world, kind)
    if type(world) ~= "table" or type(world.self) ~= "table"
        or not AIValue.isList(world.players) then return nil end
    local result = {}
    result[world.self.object_name] = lifecycle_epoch(world, world.self, kind)
    for _, view in ipairs(world.players) do
        if type(view) == "table" and type(view.object_name) == "string" then
            result[view.object_name] = lifecycle_epoch(world, view, kind)
        end
    end
    return result
end

SmartAIView = {}
SmartAIView.__index = function(self, key)
    local member = rawget(SmartAIView, key)
    if member ~= nil then
        return member
    end
    return self.request[key]
end

function SmartAIView.new(request)
    if type(request) ~= "table" or type(request.world_view) ~= "table"
        or type(request.world_view.self) ~= "table"
        or request.world_view.self.object_name ~= request.viewer then
        return nil
    end
    r45_physical.mark(request)
    local room = RoomView.new(request.world_view)
    if not room then return nil end
    local ai = setmetatable({
        request = request,
        world = request.world_view,
        room = room,
        player = room._players[request.viewer]
    }, SmartAIView)
    ai.role = request.world_view.self.role
    -- Build immutable-by-convention lookup tables once for this request.  The
    -- source rows are copied into facades; returned collections are fresh lists
    -- so callers cannot alter the authoritative snapshot or its indexes.
    local indexes = {candidates_by_card = {}, candidates_by_id = {},
        conversions_by_id = {}, conversions_by_name = {}, skill_actions = nil,
        choice_cards_by_id = {}}
    local choice_cards = type(request.options) == "table" and request.options.cards or nil
    if AIValue.isList(choice_cards) then
        indexes.choice_cards = {}
        for _, row in ipairs(choice_cards) do
            local card = CardView.new(copy_value(row))
            if card and type(card:getId()) == "number" then
                indexes.choice_cards[#indexes.choice_cards + 1] = copy_value(row)
                indexes.choice_cards_by_id[card:getId()] = copy_value(row)
            end
        end
    end
    local candidates = request.card_candidates
    if AIValue.isList(candidates) then
        indexes.candidates = {}
        for _, row in ipairs(candidates) do
            local candidate = CandidateView.new(copy_value(row))
            if candidate then
                indexes.candidates[#indexes.candidates + 1] = copy_value(row)
                local card_id, candidate_id = candidate:getCardId(), candidate:getCandidateId()
                if type(card_id) == "number" then indexes.candidates_by_card[card_id] = copy_value(row) end
                if type(candidate_id) == "number" then indexes.candidates_by_id[candidate_id] = copy_value(row) end
            end
        end
    end
    local conversions = request.card_conversions
    if AIValue.isList(conversions) then
        indexes.conversions = {}
        for _, source in ipairs(conversions) do
            -- Each issued conversion is its own product, distinct across requests.
            local row = copy_value(source)
            if type(row.conversion_id) == "number" and row.legacy_identity_token == nil then
                row.legacy_identity_token = "conversion:" .. tostring(request.decision_id) .. ":" .. row.conversion_id
            end
            local conversion = ConversionView.new(copy_value(row))
            if conversion then
                indexes.conversions[#indexes.conversions + 1] = copy_value(row)
                -- Incomplete rows remain available for coverage reporting, but
                -- absent identity fields cannot contribute an index entry.
                local id, name = row.conversion_id, row.name
                if type(id) == "number" then indexes.conversions_by_id[id] = copy_value(row) end
                if type(name) == "string" then
                    indexes.conversions_by_name[name] = indexes.conversions_by_name[name] or {}
                    indexes.conversions_by_name[name][#indexes.conversions_by_name[name] + 1] = copy_value(row)
                end
            end
        end
    end
    local actions = request.skill_actions
    if AIValue.isList(actions) then
        indexes.skill_actions = {}
        indexes.skill_actions_by_name = {}
        for _, row in ipairs(actions) do
            local action = SkillActionView.new(copy_value(row))
            if action then
                indexes.skill_actions[#indexes.skill_actions + 1] = copy_value(row)
                local skill, instance = action:getActivationSkillName(), action:getActivationInstanceId()
                if type(skill) == "string" then
                    indexes.skill_actions_by_name[skill] = indexes.skill_actions_by_name[skill] or {}
                    indexes.skill_actions_by_name[skill][#indexes.skill_actions_by_name[skill] + 1] = copy_value(row)
                    if type(instance) == "number" then indexes.skill_actions[skill .. "#" .. instance] = copy_value(row) end
                end
            end
        end
    end
    room._ai = ai
    ai._indexes = indexes
    ai.player._card_candidates = copy_value(indexes.candidates_by_card)
    local own = {}
    local function index_own(rows)
        if not AIValue.isList(rows) then return end
        for _, row in ipairs(rows) do
            if type(row) == "table" and type(row.effective_id) == "number" then
                own[row.effective_id] = copy_value(row)
            end
        end
    end
    index_own(request.world_view.hand_cards)
    index_own(request.world_view.self.equips)
    for _, pile in ipairs(request.world_view.self.piles or {}) do
        if pile.open == true then index_own(pile.cards) end
    end
    ai.player._own_card_rows = own
    facade_kinds[ai] = "ai"
    -- Activate rebuilds relations from the prior completed planner before the
    -- current request's friend/enemy lists are materialized.
    if ai:isModeManaged() then
        if ai.world.mode_policy.standard_identity == true then
            -- These stored lists are updatePlayers' objective-sign lists.
            -- getEnemies(player) has a different legacy two-player predicate.
            ai.friends, ai.friends_noself, ai.enemies = AIList.asLuaTable(AIList.new({})), AIList.asLuaTable(AIList.new({})), AIList.asLuaTable(AIList.new({}))
            local row = (ai.world.mode_policy.relations or {})[request.viewer] or {}
            for _, player in ipairs(room:getAlivePlayers()) do
                local relation = row[player:objectName()]
                if relation == "friend" then
                    ai.friends:append(player)
                    if player:objectName() ~= request.viewer then ai.friends_noself:append(player) end
                elseif relation == "enemy" then ai.enemies:append(player) end
            end
        else
            ai.friends = AIList.asLuaTable(ai:getFriends())
            ai.friends_noself = AIList.asLuaTable(ai:getFriends(nil, true))
            ai.enemies = AIList.asLuaTable(ai:getEnemies())
        end
    end
    if type(ai.installOriginalHegemonyHelpers) == "function" then ai:installOriginalHegemonyHelpers() end
    if type(ai.restoreEventKeepState) == "function" then ai:restoreEventKeepState() end
    return ai
end

-- Choice-card projections are request-local and intentionally separate from
-- hand cards: a choice may expose a visible card without granting ownership.
function SmartAIView:getChoiceCards()
    if type(self._indexes) ~= "table" or self._indexes.choice_cards == nil then return nil end
    local result = AIList.new({})
    for _, card in ipairs(self._indexes.choice_cards) do result:append(CardView.new(copy_value(card))) end
    return result
end

function SmartAIView:getChoiceCard(card_id)
    if type(card_id) ~= "number" or type(self._indexes) ~= "table" then return nil end
    local card = self._indexes.choice_cards_by_id[card_id]
    return card and CardView.new(copy_value(card)) or nil
end

-- Question context is an explicit pure-value schema. Wrap only named player/card
-- fields; never imitate an unrestricted QVariant conversion or native tag lookup.
-- SmartAI keeps the last CardEffect it saw (sgs.cardEffect). The event log holds it
-- as the latest card_effect event; an effect older than the log reads as absent.
-- Returns {from=name, to=name, card=row} or nil.
function SmartAIView:getLastCardEffect()
    local events = self.world.events
    for index = AIValue.isList(events) and #events or 0, 1, -1 do
        local event = events[index]
        if event.trigger_event == sgs.CardEffect and event.kind == "card_effect" then
            local details = type(event.details) == "table" and event.details or {}
            return {from = event.from, to = event.to, card = copy_value(details.card),
                offset_num = details.offset_num, no_respond = details.no_respond,
                no_offset = details.no_offset}
        end
    end
    return nil
end

-- Room tag "UseHistory"..key: a card use still in flight, as {from, to, card,
-- nullified_list} with player names and a public card row; nil when there is none.
function SmartAIView:getUseHistory(key)
    local rows = self.world.use_history
    if type(rows) ~= "table" then ai_unsupported("use history is not projected", "UseHistory") end
    return copy_value(rows[key])
end

function SmartAIView:getDecisionContext()
    local options = self.request.options
    local raw = type(options) == "table" and options.context or nil
    local context = copy_value(self.world.decision_context or {})
    for key, value in pairs(raw or {}) do context[key] = copy_value(value) end
    local last_effect = self:getLastCardEffect()
    if context.effect == nil then
        if last_effect then context.effect = last_effect else context.effect_present = false end
    end
    local function wrap_event(event)
        if type(event) ~= "table" then return end
        for _, key in ipairs({"who", "from", "to"}) do
            if type(event[key]) == "string" then
                event[key .. "_name"] = event[key]
                event[key] = self.room:findPlayerByObjectName(event[key], true)
            end
        end
        if type(event.card) == "table" then event.card = CardView.new(event.card) end
    end
    if type(context.card) == "table" then context.card = CardView.new(context.card) end
    wrap_event(context.judge)
    wrap_event(context.damage)
    wrap_event(context.effect)
    wrap_event(context.slash_effect)
    if type(context.pindian) == "table" then
        wrap_event(context.pindian)
        for _, key in ipairs({"from_card", "to_card"}) do
            if type(context.pindian[key]) == "table" then context.pindian[key] = CardView.new(context.pindian[key]) end
        end
    end
    if type(context.move) == "table" then
        wrap_event(context.move)
        if AIValue.isList(context.move.card_ids) then
            context.move.card_ids = AIList.new(context.move.card_ids)
        end
    end
    if type(context.player) == "string" then
        context.player = self.room:findPlayerByObjectName(context.player, true)
    end
    if type(context.dying) == "table" then
        if type(context.dying.who) == "string" then
            context.dying.who = self.room:findPlayerByObjectName(context.dying.who, true)
        end
        wrap_event(context.dying.damage)
    end
    for _, use_key in ipairs({"use", "bunkasai_use"}) do
      local use = context[use_key]
      if type(use) == "table" then
        wrap_event(use)
        if AIValue.isList(use.to) then
            local targets = AIList.new({})
            for _, name in ipairs(use.to) do
                local target = self.room:findPlayerByObjectName(name, true)
                if not target then
                    ai_unsupported("card-use target is absent from the visible roster", "context.use")
                end
                targets:append(target)
            end
            use.to = targets
        end
      end
    end
    if context.damage then context.damage.damage = context.damage.amount end
    return context
end

-- Source writes persist natively; the delegated question view is lexical only.
do
    local states=setmetatable({},{__mode='k'})
    local writes=setmetatable({},{__mode='k'})
    local originalContext=SmartAIView.getDecisionContext
    function SmartAIView:getDecisionContext()
        local context=originalContext(self)
        local overlays={}
        for _,row in ipairs(writes[self] or {}) do overlays[#overlays+1]=row end
        for _,row in ipairs(states[self] or {}) do overlays[#overlays+1]=row end
        for _,row in ipairs(overlays) do
            if row.destination=='JincanmouData' then
                context.jie_package=context.jie_package or {}
                context.jie_package.JincanmouData=copy_value(row.use)
            else
                context.yingbian=context.yingbian or {}
                context.yingbian.use=copy_value(row.use)
            end
        end
        return context
    end
    -- Finite native CardUse observations. The source setTag persists even when
    -- its subsequent delegate returns nil or raises; no gameplay tag is written.
    function SmartAIView:observeOverseasDelegateUse(key,destination,use)
        local keys={ov_zenhui={yb_zhuzhan2_data=true},ov_qirang={yb_fujia2_data=true,yb_zhuzhan2_data=true},ov_yizhu={yb_zhuzhan2_data=true},ov_ronggui={JincanmouData=true}}
        if not keys[key] or not keys[key][destination] then
            ai_unsupported('unaudited Overseas delegate destination','nested-temporary-delegates')
        end
        local nativeKey=key=='ov_qirang' and key..':'..destination or key
        local rows=originalContext(self).overseas_delegate_uses
        local row=type(rows)=='table' and rows[nativeKey]
        if type(row)~='table' or row.known~=true or row.source_key~=nativeKey or row.destination~=destination
            or type(row.use)~='table' or type(row.use.card)~='table' or not AIValue.isList(row.use.to)
            or type(use)~='table' or not AIValue.isPlayer(use.from) or not AIValue.isCard(use.card)
            or not AIValue.isList(use.to) or use.from:objectName()~=row.use.from or #use.to~=#row.use.to
            or type(row.use.card.legacy_identity_token)~='string'
            or use.card:getLegacyIdentityToken()~=row.use.card.legacy_identity_token then
            ai_unsupported('Overseas delegate is not the current observed native use','nested-temporary-delegates')
        end
        for i,name in ipairs(row.use.to) do
            if not AIValue.isPlayer(use.to[i]) or use.to[i]:objectName()~=name then
                ai_unsupported('Overseas delegate target order changed','nested-temporary-delegates')
            end
        end
        if type(ai_record_nested_delegate_use)~='function' then ai_unsupported('native delegate observer absent','nested-temporary-delegates') end
        local recorded=ai_record_nested_delegate_use(nativeKey)
        if recorded~=true then ai_unsupported(type(recorded)=='table' and recorded.error or 'delegate write rejected','nested-temporary-delegates') end
        local history=writes[self] or {};writes[self]=history
        history[#history+1]={destination=destination,use=copy_value(row.use)}
    end

    -- The native query creates the fresh source FireSlash and records its
    -- reached owner observation before returning. It cannot issue payment.
    function SmartAIView:observeOverseasLihuoHypothesis()
        local r=self.request;local options=r.options or{}
        local witness=self:getDecisionContext().overseas_lihuo_hypothesis
        if r.kind~='skill_invoke' or options.reason~='ov_lihuo' or type(witness)~='table'
            or witness.known~=true or witness.source_key~='ov_lihuo_hypothesis'
            or type(ai_observe_overseas_lihuo)~='function' then
            ai_unsupported('Lihuo owner incoming Slash is not observed','ov_lihuo.hypothesis')
        end
        local row=ai_observe_overseas_lihuo()
        if AIUnsupported.is(row)then error(row,0)end
        local use=type(row)=='table'and row.use
        local face=type(use)=='table'and use.card
        if type(row)~='table' or row.kind~='overseas_lihuo_hypothesis' or row.viewer~=r.viewer
            or row.decision_id~=r.decision_id or row.state_revision~=r.state_revision
            or row.destination~='yb_zhuzhan2_data' or type(face)~='table'
            or use.from~=r.viewer or not AIValue.isList(use.to) or face.evaluation_only~=true
            or face.name~='fire_slash' or face.skill_name~='mobilelihuo'
            or type(face.readonly_recipe_key)~='string' or face.readonly_recipe_key==''
            or type(row.candidate)~='table' then
            ai_unsupported(type(row)=='table'and row.error or'Lihuo readonly constructor response malformed','ov_lihuo.hypothesis')
        end
        local history=writes[self]or{};writes[self]=history
        history[#history+1]={destination='yb_zhuzhan2_data',use=copy_value(use)}
        local card=CardView.new(copy_value(face));card._ai=self;card._evaluation_candidate=copy_value(row.candidate)
        return card
    end
    local function pack(...) return {n=select('#',...),...} end
    local unpackValues=table.unpack or unpack
    function SmartAIView:bindZhifengQuestion(card)
    local request=self.request;local row=self:getDecisionContext().zhifeng_question
    if type(request)~="table" or request.kind~="use_card" or request.pattern~="@@zhifeng"
        or request.prompt~="zhifeng0" or type(row)~="table" or row.known~=true
        or row.kind~="zhifeng_native_question" or not AIValue.isCard(card) or not card:isEvaluationOnly()
        or card:getSkillName(false)~="zhifeng" or type(ai_bind_zhifeng_question)~="function" then
        ai_unsupported("native ThWeijing recipient question is not projected","zhifeng.question")
    end
    local ids={};for _,id in ipairs(card:getSubcards())do ids[#ids+1]=id end
    if #ids~=1 then ai_unsupported("Zhifeng source recipe requires one material","zhifeng.question")end
    local result=ai_bind_zhifeng_question({name=card:objectName(),suit=card:getSuit(),number=card:getNumber(),subcards=ids})
    if type(result)=="table" and result.native_rejected==true then
        local signal=AIUnsupported.new(result.error,"zhifeng.question");signal.native_rejected=true;signal.terminal_response_selection=true;error(signal,0)
    end
    local spec=type(result)=="table" and result.card_spec
    if type(result)~="table" or result.kind~="zhifeng_native_question" or result.class_name~=card:getClassName()
        or result.viewer~=request.viewer or result.decision_id~=request.decision_id or result.state_revision~=request.state_revision
        or type(spec)~="table" or type(spec.conversion_id)~="number" or spec.conversion_id<1 or spec.conversion_id%1~=0
        or spec.name~=card:objectName() or spec.suit~=card:getSuit() or spec.number~=card:getNumber()
        or spec.skill~=nil or not AIValue.isList(spec.subcards) or #spec.subcards~=1 or spec.subcards[1]~=ids[1] then
        ai_unsupported(type(result)=="table" and result.error or "invalid native Zhifeng receipt","zhifeng.question")
    end
    return copy_value(spec)
end

    function SmartAIView:bindJieyinghQuestion()
    local request=self.request
    local row=self:getDecisionContext().jieyingh_question
    if type(request)~="table" or request.kind~="use_card" or request.pattern~="@@jieyingh"
        or type(row)~="table" or row.known~=true or row.kind~="jieyingh_native_question"
        or row.prototype~="JieyinghCard" or type(ai_bind_jieyingh_question)~="function" then
        ai_unsupported("native Jieyingh recipient question is not projected","jieyingh.question")
    end
    local ok,result=pcall(ai_bind_jieyingh_question)
    if not ok then error(result,0) end
    local spec=type(result)=="table" and result.card_spec
    if type(result)~="table" or result.kind~="jieyingh_native_question" or result.class_name~="JieyinghCard"
        or result.viewer~=request.viewer or result.decision_id~=request.decision_id
        or result.state_revision~=request.state_revision or type(spec)~="table"
        or type(spec.conversion_id)~="number" or spec.conversion_id<1 or spec.conversion_id%1~=0
        or type(spec.name)~="string" or type(spec.suit)~="number"
        or type(spec.number)~="number" or spec.skill~=nil
        or not AIValue.isList(spec.subcards) or #spec.subcards~=0 then
        ai_unsupported(type(result)=="table" and result.error or "invalid native Jieyingh receipt","jieyingh.question")
    end
    return copy_value(spec)
end

function SmartAIView:withNestedDelegateUse(key,closure)
        local request=self.request
        local options=request.options or {}
        local valid=(key=='mobilebenxi' or key=='fanyin') and request.kind=='players_chosen' and options.reason==key
            or key=='@@jieyingh' and request.kind=='use_card' and request.pattern==key
        local row=self:getDecisionContext().nested_delegate
        local destination=key=='mobilebenxi' and 'JincanmouData' or 'yb_zhuzhan2_data'
        if not valid or type(closure)~='function' or type(row)~='table' or row.source_key~=key
            or row.destination~=destination or row.known~=true then
            ai_unsupported('current delegated use unavailable','nested-temporary-delegates')
        end
        if key=='@@jieyingh' and row.use==false then return closure(nil,row) end
        if type(row.use)~='table' or type(ai_record_nested_delegate_use)~='function' then
            ai_unsupported('native delegated observation unavailable','nested-temporary-delegates')
        end
        local recorded=ai_record_nested_delegate_use(key)
        if recorded~=true then ai_unsupported(type(recorded)=='table' and recorded.error or 'delegate write rejected','nested-temporary-delegates') end
        local raw=copy_value(row.use)
        if raw.from~=self.player:objectName() or type(raw.card)~='table' or not AIValue.isList(raw.to) then
            ai_unsupported('delegated owner use malformed','nested-temporary-delegates')
        end
        local use={from=self.player,card=CardView.new(copy_value(raw.card)),to=AIList.new({})}
        use.card._ai=self
        use.card._evaluation_candidate=copy_value(raw.card.evaluation_candidate)
        for _,name in ipairs(raw.to) do
            local target=self.room:findPlayerByObjectName(name,true)
            if not target then ai_unsupported('delegated target unavailable','nested-temporary-delegates') end
            use.to:append(target)
        end
        local stack=states[self] or {};states[self]=stack
        stack[#stack+1]={destination=destination,use=raw}
        local result=pack(pcall(closure,use,row))
        stack[#stack]=nil
        if #stack==0 then states[self]=nil end
        if not result[1] then error(result[2],0) end
        return unpackValues(result,2,result.n)
    end
end

function SmartAIView:getJudge()
    local judge = self:getDecisionContext().judge
    if type(judge) ~= "table" then return nil end
    function judge:isGood(card)
        if card == nil then return self.good end
        if self.outcomes_complete ~= true or not AIValue.isCard(card) then return nil end
        local outcomes = self.outcome_by_id
        if type(outcomes) ~= "table" then return nil end
        local id = card:getEffectiveId()
        local value = outcomes[tostring(id)]
        if value == nil then value = outcomes[id] end
        return value
    end
    function judge:isBad(card)
        local value = self:isGood(card)
        if type(value) ~= "boolean" then return nil end
        return not value
    end
    return judge
end

function SmartAIView:getDecisionData()
    local ai, context = self, self:getDecisionContext()
    local result = {
        toJudge = function() return ai:getJudge() end,
        toDamage = function() return context.damage end,
        toCardEffect = function() return context.effect end,
        toSlashEffect = function()
            if context.slash_effect_present == false then
                -- QVariant::value<SlashEffectStruct>() returns a default struct,
                -- not nil, when the actual QVariant holds another type.
                return {jink_num=1,drank=0,nature=sgs.DamageStruct_Normal,
                    multiple=false,nullified=false,no_respond=false,no_offset=false}
            end
            if context.slash_effect_present ~= true or type(context.slash_effect) ~= "table" then
                ai_unsupported("actual SlashEffect QVariant projection is unavailable","toSlashEffect")
            end
            local effect=context.slash_effect
            if type(effect.card_present) ~= "boolean" then
                ai_unsupported("actual SlashEffect card presence is unknown","toSlashEffect")
            end
            if effect.card_present and (not AIValue.isCard(effect.card) or type(effect.nature)~="number") then
                ai_unsupported("actual SlashEffect card/nature is unknown","toSlashEffect")
            end
            effect.slash=effect.card
            if effect.card_present == false then effect.slash=nil end
            return effect
        end,
        toCardUse = function() return context.use end,
        toPindian = function() return context.pindian end,
        toMoveOneTime = function() return context.move end,
        toStringList = function()
            -- Native projects QStringList decision data as context.string_list.
            if AIValue.isList(context.string_list) then
                return AIList.new(copy_value(context.string_list))
            end
            -- Finite original CardAsked input from the active Goddess writer.
            -- This does not expose arbitrary QVariant string lists or tags.
            local request=ai.request
            if type(request)=="table" and request.kind=="respond_card"
                and request.pattern=="Kai" and request.prompt=="Kai-Jink"
                and request.handling_method==sgs.Card_MethodResponse then
                local goddess=context.goddess
                local asked=type(goddess)=="table" and goddess.kai_asked
                local fields=type(asked)=="table" and asked.fields
                if type(asked)~="table" or asked.known~=true or not AIValue.isList(fields)
                    or #fields<1 or fields[1]~="jink" then
                    ai_unsupported("Kai CardAsked source input is unavailable","Kai-Jink.asked")
                end
                for _,field in ipairs(fields) do
                    if type(field)~="string" then
                        ai_unsupported("Kai CardAsked source input is malformed","Kai-Jink.asked")
                    end
                end
                return AIList.new(copy_value(fields))
            end
            -- Actual Yitian CardAsked invocation only outside the finite Kai case.
            local invocation=context.lianli_slash_invoke
            if type(request)~="table" or request.kind~="skill_invoke"
                or type(request.options)~="table" or request.options.reason~="lianli-slash"
                or type(invocation)~="table" or invocation.known~=true
                or not AIValue.isList(invocation.asked) then
                ai_unsupported("LianliSlash asked data is unavailable","lianli_slash.invoke")
            end
            return copy_value(invocation.asked)
        end,
        toString = function()
            -- Native projects QString decision data as context.value; other kinds stay unknown.
            if type(context.value) ~= "string" then
                ai_unsupported("decision string data is unavailable","toString")
            end
            return context.value
        end,
        toPlayer = function() return context.player end,
        toDying = function() return context.dying end,
        isNull = function() return next(context) == nil end
    }    facade_kinds[result] = 'decision_data'
    return result
end

-- 合法候選：全部由權威端在建立 request 時算好，這裡只查表。查不到就是「這次沒問到」，
-- 回 nil，不會現場推規則，也沒有回頭問 Engine 的路。
CandidateView = {}
CandidateView.__index = function(self, key)
    return facade_index(CandidateView, self, key)
end

local candidate_scalar_aliases = {
    candidate_id = "getCandidateId",
    card_id = "getCardId",
    target_fixed = "targetFixed",
    complete_coverage = "hasCompleteCoverage"
}

-- Optional ticket fields stay queryable and return unknown when not projected.
CandidateView.getCandidateId = make_scalar_getter("candidate_id")
CandidateView.getCardId = make_scalar_getter("card_id")

function CandidateView.new(view)
    local result = new_facade(CandidateView, view, candidate_scalar_aliases)
    if result then facade_kinds[result] = "candidate" end
    return result
end

function AIValue.isCandidate(value) return AIValue.kind(value) == "candidate" end

function CandidateView:getLegalTargets()
    local view = rawget(self, "_view")
    local targets = type(view) == "table" and view.legal_targets or nil
    if not AIValue.isList(targets) then return nil end
    return AIList.new(targets)
end

function CandidateView:getAffectedTargets()
    local view = rawget(self, "_view")
    local targets = type(view) == "table" and view.affected_targets or nil
    if not AIValue.isList(targets) then return nil end
    return AIList.new(targets)
end

-- Complete combinations are paged locally; missing data is never an empty page.
function CandidateView:getTargetCombinations(offset, limit)
    if self:hasCompleteCoverage() ~= true then return nil end
    local rows = rawget(self, "_view").target_combinations
    if not AIValue.isList(rows) then return nil end
    offset, limit = offset or 0, limit or 32
    assert(offset >= 0 and offset % 1 == 0 and limit >= 1 and limit <= 32
        and limit % 1 == 0, "invalid target page")
    local page = AIList.new({})
    for i = offset + 1, math.min(#rows, offset + limit) do
        page:append(AIList.new(rows[i]))
    end
    return page, offset + #page < #rows and offset + #page or nil
end

-- Return (next names, may finish). Order is significant, including the empty prefix.
function CandidateView:getTargetSelection(prefix)
    if not AIValue.isList(prefix) then return nil end
    local page, cursor = self:getTargetCombinations()
    if not page then return nil end
    local next_names, seen, finish = AIList.new({}), {}, false
    repeat
        for _, row in ipairs(page) do
            local matches = #prefix <= #row
            for i, name in ipairs(prefix) do
                if row[i] ~= name then matches = false break end
            end
            if matches then
                if #prefix == #row then finish = true
                elseif not seen[row[#prefix + 1]] then
                    local name = row[#prefix + 1]
                    seen[name] = true
                    next_names:append(name)
                end
            end
        end
        if cursor then page, cursor = self:getTargetCombinations(cursor) else break end
    until false
    return next_names, finish
end

function CandidateView:canTarget(player_name)
    local targets = self:getLegalTargets()
    if not targets then return nil end
    for _, name in ipairs(targets) do
        if name == player_name then return true end
    end
    return false
end

-- 同一個人最多能被選幾次。權威端只送「大於一次」的人，所以查不到就是一次，
-- 不是未知；這個數字是 targetFilter 的票數，不是可選目標總數。
function CandidateView:getMaxVotes(player_name)
    if self:canTarget(player_name) ~= true then return 0 end
    local view = rawget(self, "_view")
    local votes = type(view) == "table" and type(view.max_votes) == "table"
        and view.max_votes[player_name] or nil
    if type(votes) ~= "number" then return 1 end
    return votes
end

-- 「這次沒有合法目標」與「這張牌本來就不用指定目標」是兩個答案，不能混。
function CandidateView:needsATarget()
    if self:targetFixed() then return false end
    return not self:isFeasibleWithNoTarget()
end

function SmartAIView:getCardCandidates()
    if type(self._indexes) ~= "table" or self._indexes.candidates == nil then return nil end
    local result = AIList.new({})
    for _, candidate in ipairs(self._indexes.candidates) do result:append(CandidateView.new(copy_value(candidate))) end
    return result
end

function SmartAIView:getCardCandidate(card_id)
    local evaluation = self._response_planning_candidates and self._response_planning_candidates[card_id]
    if evaluation then return CandidateView.new(copy_value(evaluation)) end
    -- 轉化的合成 id 是負數。它自己就描述得出合法目標與完整性，所以在這裡查回它本身，
    -- 策略那一行 self:getCardCandidate(card:getEffectiveId()) 完全不用改。
    if type(card_id) == "number" and card_id < 0 then
        return self:getConversion(-card_id)
    end
    local row = self._indexes and self._indexes.candidates_by_card[card_id]
    local candidate = row and CandidateView.new(copy_value(row)) or nil
    if candidate then rawset(candidate, "_ai", self) end
    return candidate
end

-- 已授權的轉化：權威端自己用玩家真的持有的那個技能實例造出一張牌，再把那張牌的身分
-- 與造它的成本記下來的一筆紀錄。作者不能把名字變成牌——只能指名一個 conversion_id，
-- 權威端照自己的紀錄重造同一張並逐欄比對。牌名、class_name 與技能名都不是授權。
ConversionView = {}
ConversionView.__index = function(self, key)
    return facade_index(ConversionView, self, key)
end

local conversion_scalar_aliases = {
    conversion_id = "getConversionId",
    name = "getName",
    class_name = "getClassName",
    activation_owner = "getActivationOwner",
    activation_skill = "getActivationSkillName",
    activation_instance = "getActivationInstanceId",
    source_owner = "getSourceOwner",
    source_skill = "getSourceSkillName",
    source_instance = "getSourceInstanceID",
    activation_quota_available = "isActivationQuotaAvailable",
    source_quota_available = "isSourceQuotaAvailable",
    target_fixed = "targetFixed",
    complete_coverage = "hasCompleteCoverage"
}

function ConversionView.new(view)
    local result = new_facade(ConversionView, view, conversion_scalar_aliases)
    if result then facade_kinds[result] = "conversion" end
    return result
end

ConversionView.getLegacyIdentityToken = CardView.getLegacyIdentityToken
ConversionView.getLegacyStringKey = CardView.getLegacyStringKey
ConversionView.toString = CardView.toString
ConversionView.getLegacySortKey = CardView.getLegacySortKey

function AIValue.isConversion(value) return AIValue.kind(value) == "conversion" end

-- 分類來自受控卡牌目錄（權威端那張牌自己的 meta chain），不是作者宣稱的字串。
function ConversionView:isKindOf(name)
    local view = rawget(self, "_view")
    local names = type(view) == "table" and view.kind_of_names or nil
    if not AIValue.isList(names) then return nil end
    for _, entry in ipairs(names) do
        if entry == name then return true end
    end
    return false
end

-- 牌型同樣取自那張牌的 meta chain；認不出時回 nil。
function ConversionView:getTypeId()
    for _, row in ipairs({{"SkillCard", sgs.Card_TypeSkill}, {"BasicCard", sgs.Card_TypeBasic},
        {"TrickCard", sgs.Card_TypeTrick}, {"EquipCard", sgs.Card_TypeEquip}}) do
        local kind = self:isKindOf(row[1])
        if kind == nil then return nil end
        if kind then return row[2] end
    end
    return nil
end


-- Exact pure-value Card::sameNameWith overloads (fixed card.cpp1292).
function CardView:sameNameWith(other, different_slash)
    if different_slash ~= nil and type(different_slash) ~= "boolean" then
        ai_unsupported("sameNameWith requires a boolean Slash discriminator", "sameNameWith")
    end
    if type(other) ~= "string" and not AIValue.isCard(other) and not AIValue.isConversion(other) then
        ai_unsupported("sameNameWith requires a disclosed card or printed name", "sameNameWith")
    end
    if not different_slash then
        local slash = self:isKindOf("Slash")
        if slash == nil then return nil end
        if slash then
            if type(other) == "string" then return other:sub(-5) == "slash" end
            return other:isKindOf("Slash")
        end
    end
    if type(self.objectName) ~= "function"
        or (type(other) ~= "string" and type(other.objectName) ~= "function") then return nil end
    local name = self:objectName()
    local other_name = type(other) == "string" and other or other:objectName()
    if name == nil or other_name == nil then return nil end
    return name == other_name
end
ConversionView.sameNameWith = CardView.sameNameWith

-- 借用：activation 是入口，source 是根來源。兩者不同就是借來的，而配額記在 source 上，
-- 所以同一個 root 用完時，每一個借用它的入口都一起用完。
function ConversionView:isBorrowed()
    local view = rawget(self, "_view")
    if type(view) ~= "table" then return nil end
    return view.activation_skill ~= view.source_skill
        or view.activation_instance ~= view.source_instance
end

function ConversionView:getSubcards()
    local view = rawget(self, "_view")
    local ids = type(view) == "table" and view.subcards or nil
    if not AIValue.isList(ids) then return nil end
    return AIList.new(ids)
end

function ConversionView:getLegalTargets()
    local view = rawget(self, "_view")
    local targets = type(view) == "table" and view.legal_targets or nil
    if not AIValue.isList(targets) then return nil end
    return AIList.new(targets)
end

ConversionView.getAffectedTargets = CandidateView.getAffectedTargets

ConversionView.getTargetCombinations = CandidateView.getTargetCombinations
ConversionView.getTargetSelection = CandidateView.getTargetSelection

-- Bind parameters to a fresh proposal. The ticket and source remain authority-owned.
local policy_identity_counters = {}
local function fresh_policy_identity(scope)
    scope = tostring(scope or "local")
    local count = (policy_identity_counters[scope] or 0) + 1
    policy_identity_counters[scope] = count
    return "policy:" .. scope .. ":" .. count
end
local function policy_identity_scope(ai)
    local request = ai.request or {}
    return tostring(request.viewer or "local") .. ":" .. tostring(request.decision_id or "local")
end
function SmartAIView:inheritLegacyCardIdentity(result, source)
    if not (AIValue.isCard(result) or AIValue.isConversion(result))
        or not (AIValue.isCard(source) or AIValue.isConversion(source)) then
        ai_unsupported("legacy identity inheritance requires card values", "legacy_identity")
    end
    local token = source:getLegacyIdentityToken()
    if not token then ai_unsupported("source card identity is not projected", "legacy_identity") end
    result._view.legacy_identity_token = token
    return result
end

function ConversionView:withSubcards(ids)
    if not AIValue.isList(ids) then return nil end
    local view = rawget(self, "_view")
    if type(view.cost_count) ~= "number" or view.cost_count < 2
        or #ids ~= view.cost_count or not AIValue.isList(view.eligible_subcards) then
        return nil
    end
    local eligible, seen = {}, {}
    for _, id in ipairs(view.eligible_subcards) do eligible[id] = true end
    for _, id in ipairs(ids) do
        if not eligible[id] or seen[id] then return nil end
        seen[id] = true
    end
    local bound = copy_value(view)
    bound.legacy_identity_token = fresh_policy_identity(view._policy_identity_scope or view.legacy_identity_token)
    bound.subcards = copy_value(ids)
    local parts = type(view.evaluation_rules) == "table" and view.evaluation_rules.legacy_key_parts
    if type(parts) == "table" and type(parts.prefix) == "string" and type(parts.suffix) == "string"
        and type(parts.sort_suffix) == "string" then
        bound.legacy_string_key = parts.prefix .. table.concat(ids, "+") .. parts.suffix
        bound.legacy_sort_key = bound.legacy_string_key .. parts.sort_suffix
    else
        -- A prototype's old cost sequence is never an exact key for new costs.
        bound.legacy_string_key, bound.legacy_sort_key = nil, nil
    end
    return ConversionView.new(bound)
end

function ConversionView:getCostSelection()
    local view = rawget(self, "_view")
    if not view.cost_count or view.cost_count < 2 then return nil end
    return AIList.new(view.eligible_subcards), view.cost_count
end

function ConversionView:canTarget(player_name)
    local targets = self:getLegalTargets()
    if not targets then return nil end
    for _, name in ipairs(targets) do
        if name == player_name then return true end
    end
    return false
end

function ConversionView:getMaxVotes(player_name)
    if self:canTarget(player_name) ~= true then return 0 end
    local view = rawget(self, "_view")
    local votes = type(view) == "table" and type(view.max_votes) == "table"
        and view.max_votes[player_name] or nil
    if type(votes) ~= "number" then return 1 end
    return votes
end

function ConversionView:needsATarget()
    if self:targetFixed() then return false end
    return not self:isFeasibleWithNoTarget()
end

-- 策略是對「一張牌」寫的，所以轉化也要答得出牌的那幾個問題。這不是把轉化偽裝成牌：
-- objectName 與 class_name 都是權威端造出來那張牌自己的身分，只有 id 是合成的。
function ConversionView:objectName() return self._view.name end

-- 合成 id。實體牌 id 一律 >= 0，所以負數不可能撞到任何一張真的牌，而 getCardCandidate
-- 用它查回這一筆轉化——策略照舊寫 self:getCardCandidate(card:getEffectiveId())。
function ConversionView:getEffectiveId()
    local id = self:getConversionId()
    if type(id) ~= "number" then return nil end
    return -id
end

function ConversionView:getId() return self:getEffectiveId() end
function ConversionView:getPhysicalProductId()
    local rules = self._view.evaluation_rules
    local id = type(rules) == "table" and rules.physical_product_id or nil
    if type(id) ~= "number" or id < 0 or id % 1 ~= 0 then return nil end
    return id -- Native disclosed product identity, never a payment/receipt ID.
end

-- 值型答案。送出去的是票；牌名、花色、點數與成本一起送，只是讓權威端能比對出不一致
-- 並拒絕，不是授權來源。V1 技能的評估收據沒有答案，送出時改由 SmartAI 回答。
function ConversionView:toCardSpec()
    if self._view.legacy_v1 then ai_unsupported("V1 skill falls back to SmartAI", self:getActivationSkillName()) end
    local subcards = self:getSubcards()
    local ids = {}
    if subcards then
        for index, card_id in ipairs(subcards) do ids[index] = card_id end
    end
    return {conversion_id = self:getConversionId(), name = self:objectName(),
        suit = self:getSuit(), number = self:getNumber(),
        skill = self:getActivationSkillName(), subcards = ids,
        receipt_answer = copy_value(self._view.skill_action_answer)}
end

-- A donor's planning placeholder is a strategy value, never a payment
-- capability. All action serialization and native target rules retain the
-- original receipt even when the donor values a different legacy card class.
function ConversionView:getAuthorityCard() return self end
function SmartAIView:legacyPolicyCard(authority, policy, evaluation)
    if not AIValue.isConversion(authority) or type(policy) ~= "table" then
        error("legacyPolicyCard requires a native conversion receipt and pure policy")
    end
    authority = authority:getAuthorityCard()
    local registered = self:getConversion(authority:getConversionId())
    if not registered then error("legacyPolicyCard receipt was not issued to this decision") end
    local original = authority:toCardSpec()
    local expected = registered:toCardSpec()
    for _, key in ipairs({"conversion_id", "name", "suit", "number", "skill"}) do
        if original[key] ~= expected[key] then error("legacyPolicyCard altered receipt") end
    end
    if #original.subcards ~= #expected.subcards then error("legacyPolicyCard altered costs") end
    for i, id in ipairs(original.subcards) do
        if id ~= expected.subcards[i] then error("legacyPolicyCard altered costs") end
    end
    local allowed = {name=true, class_name=true, type_id=true, kind_of=true, name_length=true,
        legacy_string_key=true, legacy_sort_key=true, subcards=true, suit=true, number=true,
        damage_card=true, can_recast=true, handling_method=true, effective_id=true,
        will_throw=true, red=true, black=true, skill_name=true, skill_names=true}
    for key in pairs(policy) do
        if not allowed[key] then error("unsupported legacy policy identity field: " .. tostring(key)) end
    end
    local view = copy_value(rawget(authority, "_view"))
    view._policy_identity_scope = policy_identity_scope(self)
    view.legacy_identity_token = fresh_policy_identity(view._policy_identity_scope)
    if policy.name ~= nil and policy.name ~= view.name then view.name_length = nil end
    if policy.name_length ~= nil then
        if type(policy.name_length) ~= "number" or policy.name_length < 0 or policy.name_length % 1 ~= 0 then error("invalid policy name length") end
        view.name_length = policy.name_length
    end
    for _, key in ipairs({"name", "class_name", "legacy_string_key", "skill_name"}) do
        if policy[key] ~= nil then
            if type(policy[key]) ~= "string" then error("invalid legacy policy string") end
            view[key] = policy[key]
        end
    end
    if policy.legacy_string_key ~= nil then
        view.legacy_sort_key = policy.legacy_sort_key or policy.legacy_string_key
    end
    for _, key in ipairs({"suit", "number", "handling_method", "effective_id"}) do
        if policy[key] ~= nil then
            if type(policy[key]) ~= "number" or policy[key] % 1 ~= 0 then error("invalid legacy policy number") end
            view[key] = policy[key]
        end
    end
    for _, key in ipairs({"damage_card", "can_recast", "will_throw", "red", "black"}) do
        if policy[key] ~= nil then
            if type(policy[key]) ~= "boolean" then error("invalid legacy policy boolean") end
            view[key] = policy[key]
        end
    end
    if policy.type_id ~= nil then
        if policy.type_id ~= 0 and policy.type_id ~= authority:getTypeId() then
            error("legacy policy must retain its native card type")
        end
        view.type_id = policy.type_id
    end
    if policy.kind_of ~= nil then
        if not AIValue.isList(policy.kind_of) then error("invalid legacy policy classes") end
        for _, value in ipairs(policy.kind_of) do
            if type(value) ~= "string" then error("invalid legacy policy class") end
        end
        view.kind_of_names = copy_value(policy.kind_of)
    end
    if policy.skill_names ~= nil then
        if not AIValue.isList(policy.skill_names) then error("invalid legacy policy skill names") end
        for _, name in ipairs(policy.skill_names) do if type(name) ~= "string" then error("invalid legacy skill name") end end
        view.skill_names = copy_value(policy.skill_names)
    end
    if policy.subcards ~= nil then
        if not AIValue.isList(policy.subcards) then error("invalid planning subcards") end
        for _, id in ipairs(policy.subcards) do
            if type(id) ~= "number" or id < 0 or id % 1 ~= 0 then error("invalid planning subcard") end
        end
        view.subcards = copy_value(policy.subcards)
    end
    if evaluation ~= nil then
        if not AIValue.isCard(evaluation) or not evaluation:isEvaluationOnly()
            or evaluation:objectName() ~= authority:objectName() or evaluation:getTypeId() ~= authority:getTypeId() then
            error("legacy policy evaluation must match its authority class")
        end
        view.evaluation_rules = copy_value(evaluation._view.evaluation_rules)
        view.evaluation_owner = evaluation._view.evaluation_owner
        view.target_residue = copy_value(evaluation._view.target_residue)
    end
    local result = ConversionView.new(view)
    if evaluation ~= nil then
        result._evaluation_candidate = copy_value(rawget(evaluation,"_evaluation_candidate"))
        result.getPolicyEvaluationCard = function() return evaluation end
    end
    if policy.effective_id ~= nil then
        result.getEffectiveId = function() return view.effective_id end
    end
    -- Native allocation counters never cross the sandbox. Keep a stable opaque
    -- virtual identity, distinct from any planning material effective ID.
    result.getId = function() return authority:getId() end
    result.getAuthorityCard = function() return authority end
    result.toCardSpec = function() return authority:toCardSpec() end
    -- Cost rebinding must go through the native binder again.
    result.withSubcards = function() error("legacy policy costs require a new native receipt") end
    return result
end

function SmartAIView:getConversions()
    if type(self._indexes) ~= "table" or self._indexes.conversions == nil then return nil end
    local result = AIList.new({})
    for _, conversion in ipairs(self._indexes.conversions) do result:append(ConversionView.new(copy_value(conversion))) end
    return result
end

-- A skill card the strategy proposes. The authority builds it on submission: a V2
-- instance from its skill action, costs and user string (canActivate and quota are
-- rechecked). A V1 skill card is evaluated only; submitting it falls back to SmartAI.
-- Targets are the authority's to validate, so the receipt claims no target legality
-- of its own.
local skill_action_receipt_base = 1000000
function SmartAIView:registerSkillActionReceipt(spec)
    local indexes = self._indexes
    if type(indexes) ~= "table" or type(indexes.conversions) ~= "table" then
        ai_unsupported("conversion index is unavailable", spec.skill)
    end
    local identity = spec.identity or {}
    -- Same face as a readonly turn seed of this class (evaluateTurnSkillCard).
    local lua_card = spec.legacy_class and spec.legacy_class:sub(1, 1) == "#"
    local class_name = lua_card and "LuaSkillCard" or spec.legacy_class or "SkillCard"
    local name = lua_card and spec.legacy_class:sub(2) or spec.legacy_class or spec.skill
    local costs = copy_value(spec.costs)
    local ids = #costs > 0 and table.concat(costs, "+") or "."
    local user = spec.user_string and spec.user_string ~= "" and (":" .. spec.user_string) or ""
    local prototype = spec.legacy_class or spec.skill
    -- The legacy card string doubles as the planner's sort key.
    local wire = prototype:sub(1, 1) == "#" and (prototype .. ":" .. ids .. ":" .. (spec.user_string or ""))
        or ("@" .. prototype .. "=" .. ids .. user)
    local answer = spec.identity and {skill_action = {skill = identity.activation_skill,
        instance = identity.activation_instance, owner = identity.activation_owner},
        cards = costs, user_string = spec.user_string} or nil
    local id = skill_action_receipt_base + #indexes.conversions + 1
    local row = {conversion_id = id, name = name, class_name = class_name,
        kind_of_names = {class_name, "SkillCard", "Card"}, type_id = sgs.Card_TypeSkill,
        suit = sgs.Card_NoSuit, number = 0, skill_name = spec.skill, subcards = costs,
        activation_owner = identity.activation_owner or self.player:objectName(),
        activation_skill = identity.activation_skill or spec.skill,
        activation_instance = identity.activation_instance,
        source_owner = identity.source_owner or self.player:objectName(),
        source_skill = identity.source_skill or spec.skill,
        source_instance = identity.source_instance,
        available = true, declared_name = spec.user_string, can_recast = false, virtual_card = true,
        legacy_string_key = wire, legacy_sort_key = wire,
        legacy_identity_token = fresh_policy_identity(policy_identity_scope(self)),
        authority_validates_targets = true, skill_action_answer = answer,
        legacy_v1 = answer == nil}
    indexes.conversions[#indexes.conversions + 1] = row
    indexes.conversions_by_id[id] = row
    return ConversionView.new(copy_value(row))
end

function SmartAIView:getConversion(conversion_id)
    local row = self._indexes and self._indexes.conversions_by_id[conversion_id]
    return row and ConversionView.new(copy_value(row)) or nil
end

-- 權威端有沒有把這次能用的轉化列完。false 是「列不完」而不是「沒有轉化」：兩者分開，
-- 規劃端保留這個未知分支，但可選其他完整合法方案；沒有方案時不能把它當作合法 pass。
function SmartAIView:hasEnumeratedConversions()
    local flag = self.request.conversions_enumerated
    if type(flag) ~= "boolean" then return nil end
    return flag
end

-- 計畫 7.1 的 newCard：它只「找出」一個已授權的轉化，不製造授權。proposal 只有
-- 「我想這樣做」的意義，所以找不到對應、完整且已授權的轉化能力時回 nil，呼叫端據此
-- 回 unsupported，而不是 clone 一張照用。
-- Called at the source-equivalent allocation site, never during restoration.
-- It replaces only the strategy object; its original issued authority remains
-- independent. Native accepts no card name, wire, suit, number or material IDs.
function SmartAIView:observeOlClanPolicyAllocation(card,legacyResponse)
    local request=self.request
    local nested=self:getReadonlyPlayContext()
    local play=nested~=nil and nested~=false or request.kind=='activate' and request.reason==0x01 and request.pattern==''
    local fuxun=request.kind=='amazing_grace' and type(request.options)=='table' and request.options.reason=='kezufuxun'
    if not play and not fuxun then return card end
    local row=type(card)=='table' and rawget(card,'_view')
    if not AIValue.isConversion(card) or type(row)~='table' then return card end
    if row.class_name~='GodSalvation' and row.policy_class~='GodSalvation' then return card end
    if play and self.player:hasSkill('zuchengqi')~=true then return card end
    if fuxun and self.player:hasSkill('kezufuxun')~=true then return card end
    if type(ai_allocate_olclan_policy_card)~='function' then ai_unsupported('native source policy allocation unavailable','olClan.saved_plan') end
    local original=self:getConversion(card:getConversionId())
    if not original then ai_unsupported('source policy allocation has no issued authority','olClan.saved_plan') end
    local result=ai_allocate_olclan_policy_card(card:getConversionId(),legacyResponse==true and "legacy_response" or "ordinary")
    if AIUnsupported.is(result) then error(result,0)end
    local face=type(result)=='table' and result.card
    if type(face)~='table' or result.error~=nil or type(face.readonly_recipe_key)~='string'
        or face.readonly_recipe_key=='' or type(face.legacy_identity_token)~='string'
        or face.legacy_identity_token=='' or face.evaluation_only~=true then
        ai_unsupported(type(result)=='table' and result.error or 'invalid source policy observation','olClan.saved_plan')
    end
    -- Only an exact existing strategy face may use the native template. This
    -- rejects parameterized cost edits or another legacy policy class.
    if card:objectName()~=face.name or card:getClassName()~=face.class_name
        or card:getLegacyStringKey()~=face.legacy_string_key or card:getSuit()~=face.suit or card:getNumber()~=face.number then
        ai_unsupported('source policy face differs from native parsed template','olClan.saved_plan')
    end
    local ids=card:getSubcards()
    if not AIValue.isList(ids) or not AIValue.isList(face.subcards) or #ids~=#face.subcards then
        ai_unsupported('source policy materials differ from native template','olClan.saved_plan')
    end
    for i,id in ipairs(ids)do if id~=face.subcards[i]then ai_unsupported('source policy material order differs','olClan.saved_plan')end end
    local value=copy_value(row)
    value.legacy_identity_token=face.legacy_identity_token
    value.readonly_recipe_key=face.readonly_recipe_key
    local policy=ConversionView.new(value)
    for key,v in pairs(card)do if key~='_view'then policy[key]=v end end
    policy.getAuthorityCard=function()return original end
    policy.toCardSpec=function()return original:toCardSpec()end
    return policy
end

function SmartAIView:newCard(name, options)
    if type(name) ~= "string" or name == "" then return nil end
    local conversions = self._indexes and self._indexes.conversions_by_name[name]
    if conversions == nil then return nil end
    options = options or {}
    for _, row in ipairs(conversions) do
        local value = copy_value(row)
        value._policy_identity_scope = policy_identity_scope(self)
        value.legacy_identity_token = fresh_policy_identity(value._policy_identity_scope)
        local conversion = ConversionView.new(value)
        local matched = conversion:objectName() == name
            and (options.skill == nil
                or conversion:getActivationSkillName() == options.skill)
            and (options.instance == nil
                or conversion:getActivationInstanceId() == options.instance)
            and (options.suit == nil or conversion:getSuit() == options.suit)
            and (options.number == nil or conversion:getNumber() == options.number)
        if matched and options.subcards ~= nil and conversion:getCostSelection() then
            local bound = conversion:withSubcards(options.subcards)
            if bound then return self:observeOlClanPolicyAllocation(bound) end
            -- Another instance/source may authorize these costs; keep searching.
            matched = false
        end
        if matched and options.subcards ~= nil then
            local have = conversion:getSubcards()
            if not have or #have ~= #options.subcards then
                matched = false
            else
                for index = 1, #options.subcards do
                    if options.subcards[index] ~= have[index] then
                        matched = false
                        break
                    end
                end
            end
        end
        if matched then return self:observeOlClanPolicyAllocation(conversion) end
    end
    return nil
end

-- Public filter knowledge describes an observed face; it is never a native
-- simulation or an action right. Callers must establish complete public inputs.
function SmartAIView:publicKnowledgeCard(row)
    if type(row) ~= "table" then ai_unsupported("public card knowledge is not a value", "publicKnowledgeCard") end
    local allowed = {name=true,class_name=true,engine_class_name=true,kind_of=true,subtype=true,
        suit=true,number=true,type_id=true,red=true,black=true,skill_name=true,legacy_string_key=true}
    local view = {}
    for key,value in pairs(row) do
        if not allowed[key] then ai_unsupported("public card knowledge contains non-face data", "publicKnowledgeCard:" .. tostring(key)) end
        view[key] = copy_value(value)
    end
    if type(view.name) ~= "string" or type(view.class_name) ~= "string"
        or type(view.suit) ~= "number" or type(view.number) ~= "number"
        or type(view.type_id) ~= "number" or not AIValue.isList(view.kind_of) then
        ai_unsupported("public card face is incomplete", "publicKnowledgeCard")
    end
    view.id,view.effective_id = -1,-1
    view.evaluation_only,view.virtual_card,view.subcards = true,true,{}
    view._policy_identity_scope = policy_identity_scope(self)
    view.legacy_identity_token = fresh_policy_identity(view._policy_identity_scope)
    local card = CardView.new(view)
    card.getAuthorityCard = function() return nil end
    card.toCardSpec = function() ai_unsupported("public knowledge has no submission authority", "publicKnowledgeCard") end
    return card
end

-- 距離由權威端算（會受來源的技能與裝備影響），這裡只讀。
function RoomView:distanceTo(from, to)
    local distances = self._world.distances
    if type(distances) ~= "table" or not from or not to then return nil end
    local row = distances[from:objectName()]
    if type(row) ~= "table" then return nil end
    if from == to then return 0 end
    return row[to:objectName()]
end

local function r34_distance_integer(value)
    return type(value)=="number" and value==value and value~=math.huge
        and value~=-math.huge and value%1==0
end
-- Server Player::distanceTo adds the fix before clamping at 1. A projected distance
-- above 1 is unclamped; at 1 a positive fix cannot be recovered. Fixed distances
-- (which ignore the fix) are not projected separately.
function PlayerView:distanceTo(other, fix)
    if fix~=nil and fix~=0 then
        local world=self._room and self._room._world
        local name=type(other)=="string" and other or other and other:objectName()
        if not name then return nil end
        local from=self:objectName()
        if from==name then return 0 end
        local base=world and world.distances and world.distances[from]
        local zero=type(base)=="table" and base[name] or nil
        if not r34_distance_integer(zero) then return nil end
        if zero>1 or fix<0 then return math.max(zero+fix,1) end
        return nil
    end
    local room=rawget(self,"_room")
    if not room then return nil end
    return room:distanceTo(self,other)
end

function PlayerView:inMyAttackRange(other)
    local distance = self:distanceTo(other)
    local view = rawget(self, "_view")
    local range = type(view) == "table" and view.attack_range or nil
    if distance == nil or type(range) ~= "number" then return nil end
    return distance > 0 and distance <= range
end

-- 存活順序沿用快照的座位環。步數未知或名冊對不上時不猜下家。
function PlayerView:getNextAlive(steps)
    local room = rawget(self, "_room")
    if not room then return nil end
    if steps == nil then steps = 1 end
    if type(steps) ~= "number" or steps % 1 ~= 0 then return nil end
    local alive = room:getAlivePlayers()
    if not alive then return nil end
    if #alive < 2 or steps <= 0 then return self end
    local world = rawget(room, "_world")
    local order = world and world.player_order
    if not AIValue.isList(order) or #order == 0 then return nil end
    local index
    for position, name in ipairs(order) do if name == self:objectName() then index = position break end end
    if not index then return nil end
    local next_player = self
    for _ = 1, steps do
        local found = false
        for _ = 1, #order do
            index = index % #order + 1
            local player = room:findPlayerByObjectName(order[index], true)
            if not player then return nil end
            local live = player:isAlive()
            if live == nil then return nil end
            if live then
                if player:objectName() == self:objectName() then
                    next_player, found = player, true
                    break
                end
                local removed = player:isRemoved()
                if removed == nil then return nil end
                if not removed then next_player, found = player, true break end
            end
        end
        -- Invalid rings that would loop forever in native code are not guessed.
        if not found then return nil end
    end
    return next_player
end

-- Exact owner native predicates; foreign private restrictions remain an
-- explicitly recorded visible-hand prior rather than a fabricated rule result.
function PlayerView:canPindian(other, except_self)
    if except_self == nil then except_self = true end
    local ai = self._room and self._room._ai
    if not other or type(other.isKongcheng) ~= "function" then return nil end
    local self_empty = self:isKongcheng()
    if self_empty == nil then return nil end
    if self_empty then return false end
    if except_self and self:objectName() == other:objectName() then return false end
    local other_empty = other:isKongcheng()
    if other_empty == nil then return nil end
    if other_empty then return false end
    if not ai or type(ai.useKnowledgeEstimate) ~= "function" then return nil end
    return ai:useKnowledgeEstimate({status="estimate",value=true,subject=self:objectName(),
        target=other:objectName(),basis="visible nonempty hands; foreign private pindian restrictions unknown"},"canPindian")
end

function PlayerView:getShuangxiongColors()
    local ai = self._room and self._room._ai
    if not ai or self:objectName() ~= ai.player:objectName() then return nil end
    local value = self:getPropertyValue("shuangxiong_colors_turn")
    if type(value) ~= "string" or value == "" then return nil end
    local result = {}
    for color in (value .. "+"):gmatch("(.-)%+") do result[#result+1] = color end
    return AIList.new(result)
end

function SmartAIView:getKnownCardById(id)
    if type(id) ~= "number" or id < 0 or id % 1 ~= 0 then return nil end
    local function find(rows)
        for _, row in ipairs(rows or {}) do
            if row.effective_id == id or row.id == id then return CardView.new(copy_value(row)) end
        end
    end
    local card = find(self.world.hand_cards) or find(self.world.discard_pile)
    if card then return card end
    for _, name in ipairs(self.room._player_order or {}) do
        local player = self.room._players[name]
        local view = player._view
        card = find(view.equips) or find(view.judging_area) or find(view.known_cards)
        if card then return card end
        for _, pile in ipairs(view.piles or {}) do
            if player:objectName() == self.player:objectName() or pile.open then
                card = find(pile.cards)
                if card then return card end
            end
        end
    end
    -- The current question's disclosed cards (an AG or Guanxing domain) are known too.
    return self:getChoiceCard(id)
end

-- 可見攻擊範圍內才視為能殺。距離或範圍沒投影時不猜；禁出牌仍由權威端重驗。
function PlayerView:canSlash(other, card, distance_limit, range_fix)
    if not AIValue.isPlayer(other) then return nil end
    if other:objectName() == self:objectName() then return false end
    if distance_limit == nil then distance_limit = true end
    if range_fix == nil then range_fix = 0 end
    local key = "name:slash"
    if card ~= nil then
        local row = type(card) == "table" and rawget(card, "_view")
        if type(row) ~= "table" then return nil end
        if type(row.effective_id) == "number" and row.effective_id >= 0 then key = "id:" .. row.effective_id
        elseif row.evaluation_only then key = "name:" .. row.name
        else return nil end
    end
    local room = rawget(self, "_room")
    -- The viewer's own physical card with a request candidate: its legal targets are
    -- the authority's answer to the plain question.
    if room and room._ai and self:objectName() == room._world.self.object_name
        and distance_limit == true and range_fix == 0 and key:sub(1, 3) == "id:" then
        local candidate = room._ai:getCardCandidate(tonumber(key:sub(4)))
        local legal = candidate and candidate:getLegalTargets()
        if legal then
            for _, target in ipairs(legal) do
                if target:objectName() == other:objectName() then return true end
            end
            return false
        end
    end
    if room and room._ai and type(distance_limit) == "boolean" and type(range_fix) == "number" then
        local alive = other:isAlive()
        if alive == false then return false end
        if alive ~= true then return nil end
        local value = true
        if distance_limit then
            local distance, range = self:distanceTo(other), self:getAttackRange()
            if type(distance) ~= "number" or type(range) ~= "number" then return nil end
            value = distance > 0 and distance + range_fix <= range
        end
        return room._ai:useKnowledgeEstimate({status="estimate", value=value,
            basis="public_slash_geometry_private_legality_unknown", viewer=room._world.self.object_name,
            observer=self:objectName()}, "canSlash")
    end
    return nil
end

function PlayerView:aliveCount()
    local room = rawget(self, "_room")
    if not room then return nil end
    local players = room:getAlivePlayers()
    if not players then return nil end
    return #players
end

function PlayerView:isMale()
    local gender = self:getGender()
    if type(gender) ~= "number" or sgs.General_Male == nil then return nil end
    return gender == sgs.General_Male
end

-- 技能實例候選：同名多實例各自是一筆，來源關係（借用／轉化）由 source_* 保留。
SkillActionView = {}
SkillActionView.__index = function(self, key)
    return facade_index(SkillActionView, self, key)
end

local skill_action_aliases = {
    activation_owner = "getActivationOwner",
    activation_skill = "getActivationSkillName",
    activation_instance = "getActivationInstanceId",
    source_owner = "getSourceOwner",
    source_skill = "getSourceSkillName",
    source_instance = "getSourceInstanceID",
    activation_quota_available = "isActivationQuotaAvailable",
    source_quota_available = "isSourceQuotaAvailable"
}

function SkillActionView.new(view)
    local result = new_facade(SkillActionView, view, skill_action_aliases)
    if result then facade_kinds[result] = "skill_action" end
    return result
end

function AIValue.isSkillAction(value) return AIValue.kind(value) == "skill_action" end

function SkillActionView:isValid()
    local view = rawget(self, "_view")
    if type(view) ~= "table" then return false end
    return type(view.activation_skill) == "string" and view.activation_skill ~= ""
        and type(view.activation_instance) == "number" and view.activation_instance > 0
        and type(view.source_skill) == "string" and view.source_skill ~= ""
        and type(view.source_instance) == "number" and view.source_instance > 0
end

-- 借用／轉化：activation 是實際入口，source 是根來源；兩者不同就是借來的。
function SkillActionView:isBorrowed()
    local view = rawget(self, "_view")
    if type(view) ~= "table" then return nil end
    return view.activation_skill ~= view.source_skill
        or view.activation_instance ~= view.source_instance
end

function SmartAIView:getSkillActions()
    if type(self._indexes) ~= "table" or self._indexes.skill_actions == nil then return nil end
    local result = AIList.new({})
    for _, action in ipairs(self._indexes.skill_actions) do result:append(SkillActionView.new(copy_value(action))) end
    return result
end

function SmartAIView:getSkillAction(skill_name, instance_id)
    if skill_name == nil then
        local action = self.request.skill_action
        return type(action) == "table" and SkillActionView.new(copy_value(action)) or nil
    end
    if type(self._indexes) ~= "table" or self._indexes.skill_actions == nil then return nil end
    if instance_id ~= nil then
        local row = self._indexes.skill_actions[skill_name .. "#" .. instance_id]
        return row and SkillActionView.new(copy_value(row)) or nil
    end
    local actions = self._indexes.skill_actions_by_name
    if not actions then return nil end
    local row = actions[skill_name] and actions[skill_name][1] or nil
    return row and SkillActionView.new(copy_value(row)) or nil
end

-- 結果要指名用了哪個實例時的值型寫法。
function SkillActionView:toAnswer()
    return {skill = self:getActivationSkillName(),
        instance = self:getActivationInstanceId(),
        owner = self:getActivationOwner()}
end

-- 事件上下文：權威端在事件發生當下轉成純值，照順序留一段有界紀錄。
-- 這裡沒有 QVariant、沒有原生結構，也不會有「現在正在結算什麼」的即時查詢。
EventView = {}
EventView.__index = function(self, key)
    return facade_index(EventView, self, key)
end

local event_aliases = {
    kind = "getKind",
    sequence = "getSequence",
    revision = "getRevision",
    trigger_event = "getTriggerEvent",
    from = "getFrom",
    to = "getTo",
    card_name = "getCardName",
    reason = "getReason",
    amount = "getAmount",
    nature = "getNature",
    place = "getPlace",
    good = "isGood"
}

function EventView.new(view)
    local result = new_facade(EventView, view, event_aliases)
    if result then facade_kinds[result] = "event" end
    return result
end

function AIValue.isEvent(value) return AIValue.kind(value) == "event" end

function EventView:getCardIds()
    local view = rawget(self, "_view")
    local ids = type(view) == "table" and view.card_ids or nil
    if not AIValue.isList(ids) then return nil end
    return AIList.new(ids)
end

function EventView:getTargets()
    local view = rawget(self, "_view")
    local targets = type(view) == "table" and view.targets or nil
    if not AIValue.isList(targets) then return nil end
    return AIList.new(targets)
end

function SmartAIView:getEvents(kind)
    local events = self.world.events
    if not AIValue.isList(events) then return nil end
    local result = AIList.new({})
    for _, event in ipairs(events) do
        if kind == nil or event.kind == kind then
            result[#result + 1] = EventView.new(copy_value(event))
        end
    end
    return result
end

function SmartAIView:getLastEvent(kind)
    local events = self:getEvents(kind)
    if not events then return nil end
    return events:last()
end

function SmartAIView:hasSkills(skill_names, player)
    player = player or self.player
    if AIValue.isPlayer(player) then return player:hasSkills(skill_names) end
    assert(AIValue.isList(player), "hasSkills expects a PlayerView or player collection")
    -- Validate the entire input before searching so a mixed list cannot pass by luck.
    for _, candidate in ipairs(player) do
        assert(AIValue.isPlayer(candidate), "hasSkills collection contains a non-player")
    end
    for _, candidate in ipairs(player) do
        if candidate:hasSkills(skill_names) then return candidate end
    end
    return nil -- Legacy collection overload returns the matching player, or nil.
end

-- 記憶一律綁在這次請求的觀察者身上，handler 不能替別人記，也讀不到別人的記憶。
function SmartAIView:remember(key, value)
    if type(ai_memory) ~= "table" then return nil end
    ai_memory.remember(self.request.viewer, key, value)
    return true
end

function SmartAIView:recall(key)
    if type(ai_memory) ~= "table" then return nil end
    return ai_memory.recall(self.request.viewer, key)
end

-- 推測會過期：記下當時的 revision，之後自己判斷還算不算數。
function SmartAIView:rememberAt(key, value)
    return self:remember(key, {revision = self.request.state_revision, value = value})
end

function SmartAIView:recallAt(key)
    local stored = self:recall(key)
    if type(stored) ~= "table" then return nil end
    return stored.value, stored.revision
end

-- Planning intents survive requests only as pure values.  The caller receives
-- a stale/invalidated result and must fall back to a fresh snapshot decision.
function SmartAIView:planIntent(kind, intent)
    if type(ai_planning) ~= "table" or type(ai_planning.plan) ~= "function" then return nil end
    return ai_planning.plan(self.request.viewer, kind, self.request.state_revision,
        self.request.decision_id, intent)
end

function SmartAIView:getPlannedIntent(kind)
    if type(ai_planning) ~= "table" or type(ai_planning.peek) ~= "function" then
        return nil, "missing"
    end
    return ai_planning.peek(self.request.viewer, kind, self.request.state_revision,
        self.request.decision_id)
end

function SmartAIView:revalidatePlannedIntent(kind, valid)
    if type(ai_planning) ~= "table" or type(ai_planning.revalidate) ~= "function" then
        return nil, "missing"
    end
    if valid == nil then
        local intent, status = ai_planning.peek(self.request.viewer, kind,
            self.request.state_revision, self.request.decision_id)
        if status ~= "fresh" then return nil, status end
        valid, status = self:validatePlannedIntent(kind, intent)
        if valid == nil then return nil, status or "unknown" end
    end
    return ai_planning.revalidate(self.request.viewer, kind, self.request.state_revision,
        self.request.decision_id, valid)
end

-- Revalidation is deliberately conservative: absent projections remain
-- unknown, while a visible mismatch invalidates the intent before authority
-- sees it.  The final candidate/cost authorization still belongs to authority.
function SmartAIView:validatePlannedIntent(kind, intent)
    if type(intent) ~= "table" then return nil, "unknown" end
    if kind == "target" then
        local row = self._indexes and self._indexes.candidates_by_id[intent.candidate_id]
        local candidate = row and CandidateView.new(copy_value(row)) or nil
        if not candidate then return nil, "unknown" end
        local legal = candidate:getLegalTargets()
        if not legal then return nil, "unknown" end
        if not AIValue.isList(intent.targets) then return nil, "unknown" end
        if candidate:hasCompleteCoverage() ~= true then return nil, "unknown" end
        local function same(a, b)
            if #a ~= #b then return false end
            for index = 1, #a do if a[index] ~= b[index] then return false end end
            return true
        end
        local offset = 0
        repeat
            local combinations, next_offset = candidate:getTargetCombinations(offset)
            if not combinations then return nil, "unknown" end
            for _, row in ipairs(combinations) do
                if same(row, intent.targets) then return true, "valid" end
            end
            offset = next_offset
        until offset == nil
        return false, "invalidated"
    elseif kind == "cost" then
        local row = self._indexes and self._indexes.conversions_by_id[intent.conversion_id]
        local conversion = row and ConversionView.new(copy_value(row)) or nil
        if not conversion then return nil, "unknown" end
        if not AIValue.isList(intent.subcards) then return nil, "unknown" end
        local view = rawget(conversion, "_view")
        local expected = type(view) == "table" and view.subcards or nil
        if type(view) ~= "table" or type(view.cost_count) ~= "number" then return nil, "unknown" end
        if view.cost_count < 2 then
            if not AIValue.isList(expected) then return nil, "unknown" end
            local same = #expected == #intent.subcards
            for index = 1, #intent.subcards do
                if not same or expected[index] ~= intent.subcards[index] then same = false break end
            end
            return same, same and "valid" or "invalidated"
        end
        if not AIValue.isList(view.eligible_subcards) then return nil, "unknown" end
        local bound = conversion:withSubcards(intent.subcards)
        return bound ~= nil and true or false, bound ~= nil and "valid" or "invalidated"
    end
    return nil, "unknown"
end

function SmartAIView:invalidatePlannedIntent(kind)
    if type(ai_planning) == "table" and type(ai_planning.invalidate) == "function" then
        ai_planning.invalidate(self.request.viewer, kind)
    end
end

-- Mode policy is evaluated in the owning Room and copied into this snapshot.
-- No gameplay VM callbacks, native players, or mutable shared beliefs cross here.
-- 模式與身份：規則關係（mode policy 算出來的）與推測關係（這名觀察者自己相信的）
-- 是兩回事，查詢分開，缺一不會拿另一個頂替。
function SmartAIView:isModeManaged()
    local policy = self.world.mode_policy
    return type(policy) == "table" and policy.managed == true and policy.error == nil
end

-- 未覆蓋的模式回 nil：那是「不知道」，不是「中立」，也不是「沒有敵人」。
function SmartAIView:requireModePolicy()
    if self:isModeManaged() then return true end
    return nil
end

function RoomView:getLord()
    local players = self:getPlayers()
    if not players then return nil end
    for _, player in ipairs(players) do
        local view = rawget(player, "_view")
        if type(view) == "table" and view.lord == true then return player end
    end
    return nil
end

function RoomView:getLieges(kingdom, lord)
    if type(kingdom) ~= "string" or (lord ~= nil and not AIValue.isPlayer(lord)) then return nil end
    local players = self:getAllPlayers()
    if not players then return nil end
    local result = AIList.new({})
    for _, player in ipairs(players) do
        if not lord or player:objectName() ~= lord:objectName() then
            local player_kingdom = player._view.kingdom
            if type(player_kingdom) ~= "string" then return nil end
            if player_kingdom == kingdom then result:append(player) end
        end
    end
    return result
end

function PlayerView:isSameKingdom(other)
    local view, other_view = rawget(self, "_view"), other and rawget(other, "_view")
    local kingdom = type(view) == "table" and view.kingdom or nil
    local other_kingdom = type(other_view) == "table" and other_view.kingdom or nil
    -- 勢力沒公開就不知道，不能當成不同勢力。
    if type(kingdom) ~= "string" or kingdom == "" then return nil end
    if type(other_kingdom) ~= "string" or other_kingdom == "" then return nil end
    return kingdom == other_kingdom
end

-- 控制鏈：一人多控時，決策屬於控制者。
function PlayerView:isControlledBy(other)
    local view = rawget(self, "_view")
    local controller = type(view) == "table" and view.controller or nil
    if type(controller) ~= "string" or not other then return nil end
    return controller == other:objectName()
end

function SmartAIView:sharesController(first, second)
    local first_view = first and rawget(first, "_view")
    local second_view = second and rawget(second, "_view")
    local first_controller = type(first_view) == "table" and first_view.controller or nil
    local second_controller = type(second_view) == "table" and second_view.controller or nil
    if type(first_controller) ~= "string" or type(second_controller) ~= "string" then
        return nil
    end
    return first_controller == second_controller
end

-- 推測關係存在觀察者記憶裡，和規則關係分開，也附上當時的 revision。
function SmartAIView:believeRelation(other, relation)
    if not other then return nil end
    return self:rememberAt("relation:" .. other:objectName(), relation)
end

function SmartAIView:believedRelationTo(other)
    if not other then return nil end
    return self:recallAt("relation:" .. other:objectName())
end

function SmartAIView:relationTo(other, another)
    local policy = self.world.mode_policy
    if type(policy) ~= "table" or not policy.managed or policy.error ~= nil then return nil end
    local from = another or self.player
    if not from or not other then return "unknown" end
    local rows = policy.relations or {}
    local row = rows[from:objectName()]
    return row and row[other:objectName()] or "unknown"
end

local function objective_controller_linked(ai, first, second)
    if not first or not second then return false end
    if type(ai.isDualControlLinked)=="function" then return ai:isDualControlLinked(first,second) end
    local a,b=rawget(first,"_view"),rawget(second,"_view")
    if first:objectName()==second:objectName() then return true end
    if not a or not b then return false end
    local ac,bc=a.controller,b.controller
    return ac~=nil and ac~="" and (ac==second:objectName() or ac==bc)
        or bc~=nil and bc~="" and bc==first:objectName()
end

local function legacy_managed_relation(ai, other, another)
    local policy = ai.world and ai.world.mode_policy
    if type(policy) ~= "table" or policy.legacy_managed ~= true then return false end
    if not policy.managed or policy.error ~= nil or not other then return true, nil end
    local from = another or ai.player
    if objective_controller_linked(ai, from, other) then return true, "friend" end
    local rows = policy.relations
    local row = type(rows) == "table" and from and rows[from:objectName()]
    local relation = type(row) == "table" and row[other:objectName()]
    if relation == "friend" or relation == "enemy" or relation == "neutral" or relation == "unknown" then
        return true, relation
    end
    -- A missing matrix row is a missing capability, distinct from a provided
    -- source-level unknown relation whose friend/enemy predicates are false.
    return true, nil
end

function SmartAIView:isFriend(other, another)
    local managed, relation = legacy_managed_relation(self, other, another)
    if managed then
        if relation == nil then return nil end
        return relation == "friend"
    end
    if another then
        if objective_controller_linked(self,other,another) then return true end
        local first, second = self:isFriend(other), self:isFriend(another)
        if first == nil or second == nil then return nil end
        return first == second
    end
    if objective_controller_linked(self,self.player,other) then return true end
    local relation = self:relationTo(other)
    if relation ~= "friend" and relation ~= "enemy" and relation ~= "neutral" then return nil end
    return relation == "friend"
end

function SmartAIView:isEnemy(other, another)
    local managed, relation = legacy_managed_relation(self, other, another)
    if managed then
        if relation == nil then return nil end
        return relation == "enemy"
    end
    if another then
        if objective_controller_linked(self,other,another) then return false end
        local first, second = self:isFriend(other), self:isEnemy(another)
        if first == nil or second == nil then return nil end
        return first == second
    end
    if objective_controller_linked(self,self.player,other) then return false end
    local relation = self:relationTo(other)
    if relation ~= "friend" and relation ~= "enemy" and relation ~= "neutral" then return nil end
    return relation == "enemy"
end

function SmartAIView:objectiveLevel(other)
    local policy = self.world.mode_policy
    if type(policy) ~= "table" or not policy.managed or policy.error ~= nil then return nil end
    if not other then return 0 end
    local name=other:objectName()
    -- The mode policy evaluated every objective for this decision.
    return (policy.objectives or {})[name]
end

function SmartAIView:isRolePredictable()
    local policy = self.world.mode_policy
    if not self:isModeManaged() then return nil end
    return policy.predictable == true
end

function SmartAIView:getFriends(player, no_self)
    if not self:isModeManaged() then return nil end
    player = player or self.player
    local result, players = AIList.new({}), {self.world.self}
    for _, view in ipairs(self.world.players) do players[#players + 1] = view end
    for _, view in ipairs(players) do
        local target = self.room._players[view.object_name]
        if view.alive and (not no_self or target:objectName() ~= player:objectName())
            and self:isFriend(target, player) then result[#result + 1] = target end
    end
    return AIList.asLuaTable(result)
end

function SmartAIView:getEnemies(player)
    if not self:isModeManaged() then return nil end
    player = player or self.player
    local result, players = AIList.new({}), {self.world.self}
    for _, view in ipairs(self.world.players) do players[#players + 1] = view end
    for _, view in ipairs(players) do
        local target = self.room._players[view.object_name]
        if view.alive and self:isEnemy(target, player) then result[#result + 1] = target end
    end
    return AIList.asLuaTable(result)
end

-- addHandPile mutates a source Lua array, while a native QList projection
-- is copied before appending disclosed hand-pile cards.
function SmartAIView:addHandPile(cards, player)
    player = player or self.player
    local base = type(cards) == "string" and player:getCards(cards) or cards or player:getHandcards()
    local pile = player:getHandPileCards()
    if not AIValue.isList(base) or not pile then
        return ai_unsupported("addHandPile requires visible card metadata", "addHandPile")
    end
    local result = sgs.QList2Table(base)
    for _, card in ipairs(pile) do table.insert(result,card) end
    return result
end

-- Rescue is a viewer-scoped estimate, not proof that another player can respond.
-- Preserve SmartAI's Wansha gate and its small hidden-hand estimate; never inspect
-- another viewer's private cards. Missing zones/relations are not zero supplies.
function SmartAIView:getAllPeachNum(player)
    player = player or self.player
    local current = self.room:getCurrent() or self.player
    local wansha = current:hasSkill("wansha")
    local dying = self.player:hasFlag("Global_Dying")
    local players = self.room:getAlivePlayers()
    if wansha == nil or dying == nil or not players then
        return ai_unsupported("rescue context is unknown", "getAllPeachNum")
    end
    local total = 0
    for _, friend in ipairs(players) do
        local same = friend:objectName() == player:objectName()
        local relation = same and "friend" or self:relationTo(friend, player)
        if not same and wansha then relation = "excluded" end
        if relation == nil or relation == "unknown" then
            return ai_unsupported("rescue relation is unknown", "getAllPeachNum")
        end
        if relation == "friend" then
            local known, equips = friend:getKnownCards(), friend:getEquips()
            local hand = friend:getHandcardNum()
            if not known or not equips or type(hand) ~= "number" then
                return ai_unsupported("rescue cards are unknown", "getAllPeachNum")
            end
            -- Discover capability from native classification, not just installed
            -- Lua hooks: an unported view-as skill must not vanish from estimates.
            local skills, jijiu = friend:getSkills(), false
            if not skills then return ai_unsupported("rescue skills are unknown", "getAllPeachNum") end
            for _, skill in ipairs(skills) do
                if not skill:isInvalid() then
                    local capability = skill._view.has_view_as_skill
                    if type(capability) ~= "boolean" then
                        return ai_unsupported("rescue conversion capability is unknown", "getAllPeachNum")
                    end
                    if skill:objectName() == "jijiu" then
                        local active = friend:hasFlag("CurrentPlayer")
                        if active == nil then return ai_unsupported("Jijiu current player is unknown", "getAllPeachNum") end
                        -- Only the viewer's private prevention mark is available.
                        -- Other recipients require an explicit projected value.
                        local prevented = friend._view.public_marks and friend._view.public_marks.Global_PreventPeach
                        if prevented == nil and friend:objectName() ~= self.player:objectName() and not active then
                            return ai_unsupported("Jijiu prevention state is unknown", "getAllPeachNum")
                        end
                        jijiu = not active and (prevented or 0) < 1
                    elseif capability then
                        return ai_unsupported("rescue conversion is not covered: " .. skill:objectName(), "getAllPeachNum")
                    end
                end
            end
            for _, registry in ipairs({"ai_view_as", "ai_cardsview", "ai_cardsview_valuable"}) do
                local hooks = self:forSkillHooks(registry, friend)
                if not hooks then return ai_unsupported("rescue hooks are unknown", "getAllPeachNum") end
                for _, hook in ipairs(hooks) do
                    if hook.key ~= "jijiu" then
                        return ai_unsupported("rescue conversion needs a response projection", "getAllPeachNum")
                    end
                end
            end
            local cards = AIList.new(known)
            for _, card in ipairs(equips) do cards:append(card) end
            local classes = same and {"Peach", "Analeptic"} or {"Peach"}
            for _, class in ipairs(classes) do
                local count = 0
                for _, card in ipairs(cards) do
                    local matches = card:isKindOf(class)
                    if matches == nil then
                        return ai_unsupported("rescue card classification is unknown", "getAllPeachNum")
                    end
                    -- SmartAI's getKnownCard(viewas=true) counts Jijiu red he cards;
                    -- do not construct the legacy peach string or double-count it.
                    if not matches and jijiu and class == "Peach" then
                        matches = card:isRed()
                        if matches == nil then
                            return ai_unsupported("rescue card color is unknown", "getAllPeachNum")
                        end
                    end
                    if matches then count = count + 1 end
                end
                if #cards < hand / 2 and hand > 2 and count < hand / 3 and not dying then
                    count = count + 1
                end
                total = total + count
            end
        end
    end
    return total
end

-- Legacy callback ABI. A value-shaped stand-in for AiLegacyRequestView, built only for
-- requests that carry a skill action, exactly like the native view legacy AI receives.
-- getDecisionKind()/getReason() stay absent while their enums are not projected into the
-- sandbox: an error is honest, a comparison against a nil constant silently mis-branches.
AILegacyRequest = {}
AILegacyRequest.__index = AILegacyRequest

local function valid_instance_ref(owner, skill_name, instance_id)
    return type(owner) == "string" and owner ~= ""
        and type(skill_name) == "string" and skill_name ~= ""
        and type(instance_id) == "number" and instance_id > 0
end

function AILegacyRequest.new(request, room)
    if type(request) ~= "table" or type(request.skill_action) ~= "table" then return nil end
    local view = setmetatable({_request = request, _action = request.skill_action,
        _room = room}, AILegacyRequest)
    facade_kinds[view] = "request"
    return view
end

function AILegacyRequest:isValid()
    local action = self._action
    return type(self._request.viewer) == "string" and self._request.viewer ~= ""
        and valid_instance_ref(action.activation_owner, action.activation_skill,
            action.activation_instance)
        and valid_instance_ref(action.source_owner, action.source_skill,
            action.source_instance)
end

function AILegacyRequest:getDecisionId() return self._request.decision_id end
function AILegacyRequest:getStateRevision() return self._request.state_revision end
function AILegacyRequest:getPattern() return self._request.pattern end
function AILegacyRequest:getPrompt() return self._request.prompt end
function AILegacyRequest:getHandlingMethod() return self._request.handling_method end
function AILegacyRequest:getActivationOwner() return self._action.activation_owner end
function AILegacyRequest:getActivationSkillName() return self._action.activation_skill end
function AILegacyRequest:getActivationInstanceId() return self._action.activation_instance end
function AILegacyRequest:getSourceOwner() return self._action.source_owner end
function AILegacyRequest:getSourceSkillName() return self._action.source_skill end
function AILegacyRequest:getSourceInstanceID() return self._action.source_instance end

function AILegacyRequest:isActivationQuotaAvailable()
    return self._action.activation_quota_available == true
end

function AILegacyRequest:isSourceQuotaAvailable()
    return self._action.source_quota_available == true
end

function AILegacyRequest:getInitiator()
    -- Identity projection of the request owner within this decision, never a ServerPlayer.
    if not self._room then return nil end
    return self._room:findPlayerByObjectName(self._action.activation_owner, true)
end

-- 未覆蓋訊號。用有標記的表當 error 值，不用字串：dispatcher 才分得出「這題接不住」
-- 與「handler 壞了」，而不是去猜錯誤訊息長什麼樣。
-- 舊作者寫 `if use.card then ... end`，所以不支援時不能只回 card=nil —— 那會被讀成
-- 「AI 決定不出牌」。訊號預設一路丟到最外層 dispatcher，內層吞不掉；要自己接手的
-- 呼叫者用 AIUnsupported.capture 明說。
AIUnsupported = {}
AIUnsupported.__index = AIUnsupported
AIUnsupported.__tostring = function(signal)
    if signal.key then return "AI not covered (" .. signal.key .. "): " .. signal.reason end
    return "AI not covered: " .. signal.reason
end

function AIUnsupported.new(reason, key)
    assert(type(reason) == "string" and reason ~= "", "an unsupported signal needs a reason")
    assert(key == nil or type(key) == "string", "an unsupported key must be a name")
    return setmetatable({reason = reason, key = key}, AIUnsupported)
end

function AIUnsupported.is(value)
    return type(value) == "table" and getmetatable(value) == AIUnsupported
end

-- 丟出訊號。名字刻意與 error 不同：讀到這一行就知道這不是程式壞了。level 0 保持
-- 錯誤值原樣，不讓 Lua 在前面貼上檔名行號把表變成字串。
function ai_unsupported(reason, key)
    error(AIUnsupported.new(reason, key), 0)
end

-- 接手訊號：回 (true, value) 或 (false, signal)。真正的程式錯誤照樣往上丟，不會被
-- 當成未覆蓋而消失——未覆蓋要記錄並回退，錯誤要被稽核，兩者不能混。
function AIUnsupported.capture(fn, ...)
    local ok, value = pcall(fn, ...)
    if AIUnsupported.is(value) then return false, value end
    if not ok then error(value, 0) end
    return true, value
end

-- Result conversion shared by both callback ABIs. The status separates the cases the
-- legacy dispatcher treats differently: "unhandled" keeps searching, "declined" is the
-- legacy "." answer a compulsory request refuses, "pass"/"use_card" are decisions.
-- "unsupported" is none of those: the question was understood and could not be answered,
-- so it must reach the outermost dispatcher instead of turning into a pass.
-- A malformed answer raises, so a broken handler is audited as an error, never as a pass.
AIResultValue = {}

local function copy_result_list(values, message)
    if values == nil then return nil end
    assert(AIValue.isList(values), message)
    local result = {}
    for index, value in ipairs(values) do result[index] = value end
    return result
end

local function normalize_card_spec(spec)
    assert(type(spec) == "table", "a card spec must be a table")
    assert(type(spec.name) == "string" and (spec.name ~= ""
        or (type(spec.conversion_id) == "number" and spec.conversion_id > 0 and spec.conversion_id % 1 == 0)),
        "a card spec needs a native name or an issued nameless skill receipt")
    local result = {name = spec.name}
    if spec.conversion_id ~= nil then
        -- 授權票。其餘欄位是描述，這一個才是權威端據以放行的東西，所以形狀不對就拒絕，
        -- 不可以默默丟掉——丟掉等於把一個有票的答案變成沒票的答案。
        assert(type(spec.conversion_id) == "number" and spec.conversion_id >= 0,
            "a card spec conversion_id must be a conversion ticket")
        result.conversion_id = spec.conversion_id
    end
    if spec.suit ~= nil then
        assert(type(spec.suit) == "number", "a card spec suit must be a suit constant")
        result.suit = spec.suit
    end
    if spec.number ~= nil then
        assert(type(spec.number) == "number", "a card spec number must be a number")
        result.number = spec.number
    end
    if spec.skill ~= nil then
        assert(type(spec.skill) == "string", "a card spec skill must be a name")
        result.skill = spec.skill
    end
    if spec.subcards ~= nil then
        result.subcards = copy_result_list(spec.subcards,
            "card spec subcards must be a dense array")
    end
    return result
end

local function normalize_card_action(value)
    -- A locally registered receipt answers with its own skill action; it has no
    -- conversion ticket the authority issued.
    local receipt = type(value.card_spec) == "table" and value.card_spec.receipt_answer
    if type(receipt) == "table" then
        local merged = {}
        for key, item in pairs(value) do merged[key] = item end
        merged.card_spec = nil
        for key, item in pairs(receipt) do if merged[key] == nil then merged[key] = item end end
        value = merged
    end
    local result = {kind = "use_card"}
    if value.card ~= nil then
        assert(type(value.card) == "string", "AI result card must be a card string")
        result.card = value.card
    end
    if value.card_spec ~= nil then
        -- 值型造牌：只描述要哪張牌，實際造牌與扣次數留在權威端。
        assert(value.card == nil, "answer with a card string or a card spec, not both")
        result.card_spec = normalize_card_spec(value.card_spec)
    end
    if value.card_id ~= nil then
        -- 打自己手上那張實體牌：只給 ID，權威端驗持有後自己取牌。
        assert(type(value.card_id) == "number" and value.card_id >= 0,
            "card_id must be a card id")
        assert(value.card == nil and value.card_spec == nil,
            "name the card once: card, card_spec or card_id")
        result.card_id = value.card_id
    end
    if value.candidate_id ~= nil then
        assert(type(value.candidate_id) == "number" and value.candidate_id >= 0,
            "candidate_id must be a candidate ticket")
        result.candidate_id = value.candidate_id
    end
    if value.user_string ~= nil then
        assert(type(value.user_string) == "string", "AI result user_string must be a string")
        result.user_string = value.user_string
    end
    result.cards = copy_result_list(value.cards, "AI result cards must be a dense array")
    result.targets = copy_result_list(value.targets, "AI result targets must be a dense array")
    if value.skill_action ~= nil then
        -- 指名用哪個技能實例；權威端仍重跑 canActivate 與次數檢查，這裡只驗形狀。
        local action = value.skill_action
        assert(type(action) == "table" and type(action.skill) == "string"
            and action.skill ~= "" and type(action.instance) == "number"
            and action.instance > 0
            and (action.owner == nil or type(action.owner) == "string"),
            "AI result skill_action needs {skill, instance[, owner]}")
        result.skill_action = action
    end
    return result
end

-- 值型詢問的答案：只有 skill_invoke 能用 boolean，其餘一律字串候選。
local answer_kinds = {skill_invoke = true, choice = true, suit = true,
    kingdom = true, general = true, trigger_order = true}

local function normalize_answer(value, kind)
    if type(value) == "boolean" then
        assert(kind == "skill_invoke", "only a skill invoke answer may be a boolean")
        if not value then return {kind = "pass"}, "declined" end
        return {kind = "answer", answer = "yes"}, "answer"
    end
    if type(value) == "string" then
        -- 空字串是拒答，不是選了「空選項」。
        if value == "" then return {kind = "pass"}, "declined" end
        return {kind = "answer", answer = value}, "answer"
    end
    assert(type(value) == "table", "AI answer must be nil, a boolean, a string or a table")
    if value.kind == "pass" then return {kind = "pass"}, "pass" end
    assert(value.kind == "answer", "AI answer table needs kind=answer")
    if kind=='suit' and value.original_suit_value~=nil then
        local number=value.original_suit_value
        assert(type(number)=='number' and number%1==0 and number>=-1 and number<=6, 'invalid Original Suit enum')
        assert(value.answer==nil and value.original_empty_choice==nil, 'mixed Original Suit result')
        return {kind='answer',original_suit_value=number}, 'answer'
    end
    if kind=='choice' and value.original_empty_choice==true and value.answer==''then
        return {kind='answer',answer='',original_empty_choice=true},'answer'
    end
    assert(type(value.answer) == "string" and value.answer ~= "",
        "AI answer must carry a non-empty string")
    return {kind = "answer", answer = value.answer}, "answer"
end

-- 選牌與選人的答案。牌只收 ID，玩家只收 object name；yiji 兩者都要，所以只接受
-- 明示的表，避免用元素型別猜這是牌還是人。
local card_answer_kinds = {discard = true, amazing_grace = true,
    card_chosen = true, respond_card = true}
local player_answer_kinds = {player_chosen = true, players_chosen = true}
local selection_kinds = {discard = true, amazing_grace = true, card_chosen = true,
    yiji = true, player_chosen = true, players_chosen = true, respond_card = true,
    guanxing = true}

local function selection_list(values, item_type, message)
    assert(AIValue.isList(values), message)
    local result = {}
    for index, value in ipairs(values) do
        assert(type(value) == item_type, message)
        result[index] = value
    end
    return result
end

local function normalize_selection(value, kind)
    if type(value)=="table"and value.original_response_wire~=nil then
        assert(kind=="respond_card"and getmetatable(value)==nil,"source response wire outside card question")
        for key in pairs(value)do assert(key=="kind"or key=="cards"or key=="original_response_wire","mixed source-wire result")end
        local wire=value.original_response_wire
        assert(type(wire)=="string"and#wire<=32,"invalid source response wire")
        if wire=="."then
            assert(value.kind=="pass"and value.cards==nil,"source refusal has payment")
            return{kind="pass",original_response_wire=wire},"pass"
        end
        assert(wire:match("^[0-9]+$"),"source response wire is outside finite physical grammar")
        local id=tonumber(wire)
        assert(id and id>=0 and id<=2147483647 and id%1==0,"source response physical ID overflow")
        assert(value.kind=="answer"and AIValue.isList(value.cards)and#value.cards==1 and value.cards[1]==id,"source wire/result identity mismatch")
        return{kind="answer",cards={id},original_response_wire=wire},"answer"
    end
    if type(value) == "number" then
        assert(card_answer_kinds[kind], "only a card selection may answer with an id")
        return {kind = "answer", cards = {value}}, "answer"
    end
    if type(value) == "string" then
        if value == "" then return {kind = "pass"}, "declined" end
        assert(player_answer_kinds[kind], "only a player selection may answer with a name")
        return {kind = "answer", targets = {value}}, "answer"
    end
    assert(type(value) == "table", "AI selection must be nil, an id, a name or a table")
    if value.kind == "pass" then return {kind = "pass"}, "pass" end
    if value.kind == nil and AIValue.isList(value) then
        -- 陣列形式沿用同一條規則：牌族只收數字，人族只收字串。
        if card_answer_kinds[kind] then
            return {kind = "answer", cards = selection_list(value, "number",
                "a card selection answers with ids")}, "answer"
        end
        assert(player_answer_kinds[kind], "this selection needs an explicit answer table")
        return {kind = "answer", targets = selection_list(value, "string",
            "a player selection answers with object names")}, "answer"
    end
    assert(value.kind == "answer", "AI selection table needs kind=answer")
    if value.original_discard_error~=nil then
        assert(kind=='discard' and value.original_discard_error==true, 'invalid Original discard error marker')
        for key in pairs(value)do assert(key=='kind'or key=='cards'or key=='original_discard_error','mixed Original discard result')end
        return {kind='answer',original_discard_error=true,cards=selection_list(value.cards,'number','Original native discard IDs')},'answer'
    end
    if value.random_card_choice ~= nil then
        assert(kind == "card_chosen", "opaque random choice only answers CardChosen")
        for key in pairs(value) do
            assert(key == "kind" or key == "random_card_choice", "mixed random card choice")
        end
        local row = value.random_card_choice
        assert(type(row) == "table" and getmetatable(row) == nil and type(row.token) == "string"
            and type(row.index) == "number" and row.index >= 1 and row.index % 1 == 0
            and type(row.avoid_wounded_enemy_silver_lion) == "boolean", "invalid random card choice")
        local count = 0
        for key in pairs(row) do
            assert(key == "token" or key == "index" or key == "avoid_wounded_enemy_silver_lion", "invalid random field")
            count = count + 1
        end
        assert(count == 3, "incomplete random choice")
        return {kind="answer", random_card_choice=copy_value(row)}, "answer"
    end
    if value.card_spec ~= nil then
        -- Response conversions use the same issued ticket as a play conversion;
        -- physical selections and target lists cannot be mixed into that answer.
        assert(kind == "respond_card", "only a card response may select a conversion")
        assert(value.cards == nil and value.targets == nil and value.bottom_cards == nil
            and value.card_id == nil and value.card == nil and value.candidate_id == nil,
            "a converted response must carry only its card_spec")
        return {kind = "answer", card_spec = normalize_card_spec(value.card_spec)}, "answer"
    end
    local answer = {kind = "answer"}
    if value.cards ~= nil then
        answer.cards = selection_list(value.cards, "number", "selected cards must be ids")
    end
    if value.targets ~= nil then
        answer.targets = selection_list(value.targets, "string",
            "selected targets must be object names")
    end
    if value.bottom_cards ~= nil then
        -- 觀星的第二堆自己保留順序，不由上面那堆推算。
        answer.bottom_cards = selection_list(value.bottom_cards, "number",
            "the bottom pile must be ids")
    end
    assert(answer.cards or answer.targets or answer.bottom_cards,
        "an answer table must select something")
    return answer, "answer"
end

function AIResultValue.normalize(value, kind)
    if value == nil then return nil, "unhandled" end
    -- 回傳訊號與丟出訊號同一個意思，走同一條出口；兩種寫法都不會被讀成 pass。
    if AIUnsupported.is(value) then return nil, "unsupported" end
    if answer_kinds[kind] then return normalize_answer(value, kind) end
    if selection_kinds[kind] then return normalize_selection(value, kind) end
    if type(value) == "string" then
        -- "." declines; an empty answer is the same refusal at the legacy C++ boundary.
        if value == "." or value == "" then return {kind = "pass"}, "declined" end
        return {kind = "use_card", card = value}, "use_card"
    end
    assert(type(value) == "table", "AI result must be nil, a card string or a table")
    if value.kind ~= nil then
        assert(value.kind == "pass" or value.kind == "use_card", "unknown AI result kind")
        if value.kind == "pass" then return {kind = "pass"}, "pass" end
        return normalize_card_action(value), "use_card"
    end
    -- Legacy structured answers: { accepted = true, cards = ..., targets = ... } and the
    -- V2 shape that carries only cards/targets/user_string.
    if value.accepted ~= nil then
        assert(type(value.accepted) == "boolean", "AI result accepted must be a boolean")
        if not value.accepted then return {kind = "pass"}, "pass" end
    else
        assert(value.card ~= nil or value.cards ~= nil or value.targets ~= nil
            or value.user_string ~= nil, "AI result table needs kind, accepted or an action")
    end
    return normalize_card_action(value), "use_card"
end

-- Typed strategy projections. Missing fields remain unknown, including empty maps.
function CardView:getSkillNames()
    return AIValue.isList(self._view.skill_names) and AIList.new(self._view.skill_names) or nil
end
ConversionView.getSkillNames = CardView.getSkillNames
function CardView:getEquipOccupyLocations()
    local locations = self._view.equip_occupy_locations
    if not AIValue.isList(locations) then
        local row = AICardCatalog.get(self._view.name)
        locations = row and row.occupy_locations
    end
    return AIValue.isList(locations) and AIList.new(locations) or nil
end
ConversionView.getEquipOccupyLocations = CardView.getEquipOccupyLocations
function CardView:getTargetResidue(target)
    local rows = self._view.target_residue
    return type(rows) == "table" and rows[AIValue.isPlayer(target) and target:objectName() or target] or nil
end
-- The viewer's own tags and dynamic properties as plain values: gameplay structs are
-- tables with player names and public card rows. Another player's are not projected.
function PlayerView:getTag(name)
    local tags = self._view.tags
    if type(tags) ~= "table" then ai_unsupported("only the viewer's own tags are projected", "tag:" .. tostring(name)) end
    return copy_value(tags[name])
end
function PlayerView:getPropertyValue(name)
    local properties = self._view.properties
    if type(properties) ~= "table" then
        ai_unsupported("only the viewer's own properties are projected", "property:" .. tostring(name))
    end
    return copy_value(properties[name])
end
-- Pile sizes are public even when a pile is closed.
function PlayerView:getHandPileCount()
    local piles = self._view.piles
    if not AIValue.isList(piles) then return nil end
    local count = 0
    for _, pile in ipairs(piles) do
        if pile.hand_pile then
            if type(pile.count) ~= "number" then return nil end
            count = count + pile.count
        end
    end
    return count
end
function PlayerView:areSkillsComplete() return self._view.skills_complete end
-- SmartAI's temporary aiNoTo property: set around one nested planning call and
-- cleared after it, so it lives on this decision's view only.
local function target_revise_property(self, target, op, value)
    if not AIValue.isPlayer(target) then
        ai_unsupported("target revise property requires a player", "targetRevises.aiNoTo")
    end
    self._ai_no_to = self._ai_no_to or {}
    if op == "write" then
        assert(type(value)=="boolean", "target revise property requires boolean")
        self._ai_no_to[target:objectName()] = value or nil
        return value
    end
    return self._ai_no_to[target:objectName()] == true
end
function SmartAIView:getTargetRevisesProperty(target)
    return target_revise_property(self,target,"read")
end
function SmartAIView:setTargetRevisesProperty(target,value)
    return target_revise_property(self,target,"write",value)
end
function PlayerView:isAiNoTo()
    local ai=self._room and self._room._ai
    if not ai then ai_unsupported("target revise property has no current viewer", "targetRevises.aiNoTo") end
    return ai:getTargetRevisesProperty(self)
end

-- SmartAI: property("shuangxiong_colors_turn"):toString() ~= "" (the viewer's own).
function PlayerView:hasShuangxiongColors()
    local value = self:getPropertyValue("shuangxiong_colors_turn")
    return value ~= nil and tostring(value) ~= ""
end
-- used_history is the viewer's own Player::usedTimes per history key; a key that is
-- not there was not used. Other players' history is not projected.
function PlayerView:usedTimes(name)
    local rows = self._view.used_history
    if type(rows) ~= "table" then return nil end
    local value = rows[name]
    if value == nil then return 0 end
    if type(value) ~= "number" or value ~= value or value % 1 ~= 0 then return nil end
    return value
end
function PlayerView:hasUsed(name)
    local times = self:usedTimes(name)
    if times == nil then return nil end
    return times > 0
end
function SkillView:hasEvent(event)
    if event == sgs.AskForRetrial then return self._view.retrial_trigger end
    return nil
end
function SkillView:hasLoseEquipDescriptionTrigger() return self._view.lose_equip_description_trigger end
function CandidateView:getExtraTargetCount(target)
    if target ~= nil then
        local name = type(target) == "string" and target or target:objectName()
        local values = self._view.extra_target_by_player
        if type(values) == "table" then return values[name] end
        return nil
    end
    return self._view.extra_target_count
end
function CandidateView:canTargetWithEmptyPrefix(target)
    local rows = self._view.target_filter_empty
    if type(rows) ~= "table" then return nil end
    return rows[AIValue.isPlayer(target) and target:objectName() or target]
end
ConversionView.getExtraTargetCount = CandidateView.getExtraTargetCount
ConversionView.canTargetWithEmptyPrefix = CandidateView.canTargetWithEmptyPrefix
-- A conversion row without the field recasts as its printed card does.
function ConversionView:canRecast()
    local value = self._view.can_recast
    if value ~= nil then return value end
    local row = AICardCatalog.get(self._view.name)
    if row then return row.can_recast end
    return nil
end
ConversionView.willThrow = make_scalar_getter("will_throw")
ConversionView.containsJinchantuoqiao = make_scalar_getter("contains_jinchantuoqiao")
ConversionView.matchesResponsePattern = make_scalar_getter("matches_response_pattern")
-- Personality settings are this VM's own AI settings; timing comes from the world.
function SmartAIView:getResponsePolicy()
    local function lines(name)
        local value = rawget(_G, name)
        return type(value) == "table" and copy_value(value) or nil
    end
    local invoke, peach = lines("jl_bingfen1"), lines("jl_bingfen3")
    return {humanized = self.world.ai_humanized, turn_count = self.world.turn_count,
        jl_bingfen = sgs.jl_bingfen == true,
        bingfen_invoke_lines_present = invoke ~= nil, bingfen_invoke_lines = invoke,
        bingfen_invoke_line_count = invoke and #invoke or 0,
        bingfen_peach_lines_present = peach ~= nil, bingfen_peach_lines = peach,
        bingfen_peach_line_count = peach and #peach or 0}
end
function SmartAIView:getGameProcess()
    local policy = self.world.mode_policy
    return type(policy) == "table" and policy.error == nil and policy.process_label or nil
end
function SmartAIView:getRoleEstimate(player)
    local policy = self.world.mode_policy
    local rows = type(policy) == "table" and policy.error == nil and policy.role_estimates
    return type(rows) == "table" and AIValue.isPlayer(player) and rows[player:objectName()] or nil
end
SmartAIView.assessedRole = SmartAIView.getRoleEstimate
function SmartAIView:getRoleCounts()
    local rows = self.world.role_counts
    return type(rows) == "table" and copy_value(rows) or nil
end
function RoomView:getDuelRule() return self._world.duel_rule end

ConversionView.getSuitString = CardView.getSuitString
ConversionView.getNumberString = CardView.getNumberString
ConversionView.getColorString = CardView.getColorString
ConversionView.getColor = CardView.getColor
ConversionView.sameColorWith = CardView.sameColorWith
ConversionView.hasSuit = CardView.hasSuit
-- A conversion is a freshly built product: no flag row means no flags.
function ConversionView:hasFlag(name)
    if type(rawget(self, "_view")) == "table" and self._view.flags == nil then return false end
    return CardView.hasFlag(self, name)
end
ConversionView.subcardsLength = function(self) local cards = self:getSubcards(); return cards and #cards or nil end
ConversionView.getSkillName = make_scalar_getter("skill_name")
ConversionView.isRed = make_scalar_getter("red")
ConversionView.isBlack = make_scalar_getter("black")
-- A conversion is a card its skill built; rows without the field are virtual.
function ConversionView:isVirtualCard()
    local value = rawget(self, "_view") and self._view.virtual_card
    if value == nil then return true end
    return value
end
ConversionView.getType = CardView.getType
function SkillView:getDescription() return self._view.description end
function SkillView:hasTriggerEvent(event)
    local events = self._view.trigger_events
    if not AIValue.isList(events) then return nil end
    for _, value in ipairs(events) do if value == event then return true end end
    return false
end
function PlayerView:isFemale()
    local gender = self:getGender()
    if type(gender) ~= "number" or sgs.General_Female == nil then return nil end
    return gender == sgs.General_Female
end
function PlayerView:isAdjacentTo(other)
    if not AIValue.isPlayer(other) then return nil end
    local nextp, previous = self:getNextAlive(), other:getNextAlive()
    if not nextp or not previous then return nil end
    return nextp:objectName() == other:objectName() or previous:objectName() == self:objectName()
end

-- An AG question evaluates each offered name's printed card for the viewer.
local function printed_card_evaluation(ai, name)
    local options = type(ai.request) == "table" and ai.request.options
    local context = type(options) == "table" and options.context
    local rows = type(context) == "table" and context.printed_card_evaluations
    local row = type(rows) == "table" and rows[name]
    if type(row) == "table" and type(row.card_rules) == "table" and type(row.candidate) == "table" then return row end
    return nil
end

-- A printed prototype built from the static card catalog: the card kind's class,
-- type and rule flags, without an id, suit, number or target legality. Legality
-- belongs to request candidates, which a prototype has only when the question
-- evaluated that name (printed_card_evaluations).
function SmartAIView:getEvaluationCard(name)
    if type(ai_card_catalog) ~= "table" then ai_unsupported("card catalog is not projected", name) end
    local row = AICardCatalog.get(name)
    if not row then return nil end
    self._printed_evaluations = self._printed_evaluations or {}
    local view = self._printed_evaluations[name]
    if view == nil then
        view = {id = -1, effective_id = -1, name = row.name, class_name = row.class_name,
            kind_of = copy_value(row.kind_of), type_id = row.type_id, subtype = row.subtype,
            suit = sgs.Card_NoSuit, number = 0, red = false, black = false, skill_name = "",
            -- A fresh clone's Card::getSkillNames is its own empty skill name.
            skill_names = {""}, skill_names_complete = true, flags = {},
            virtual_card = true, evaluation_only = true, subcards = {},
            target_fixed = row.target_fixed, damage_card = row.damage_card,
            can_recast = row.can_recast, single_target = row.single_target,
            equip_slot = row.equip_slot, weapon_range = row.weapon_range,
            handling_method = sgs.Card_MethodUse}
        self._printed_evaluations[name] = view
    end
    local face, printed = copy_value(view), printed_card_evaluation(self, name)
    if printed then
        face.available, face.evaluation_owner = printed.card_rules.available, self.player:objectName()
        face.evaluation_rules, face.printed_evaluation = copy_value(printed.card_rules), true
    end
    local card = CardView.new(face)
    if printed then card._evaluation_candidate = copy_value(printed.candidate) end
    return card
end
-- Each source clone is a new strategy object even when its immutable printed
-- descriptor/rule cache is shared. This grants no payment capability.
function SmartAIView:cloneEvaluationCard(name)
    local card=self:getEvaluationCard(name)
    if not card then return nil end
    if not card:isEvaluationOnly() then ai_unsupported("clone base is not readonly",name)end
    card._view.legacy_identity_token=fresh_policy_identity(policy_identity_scope(self))
    return card
end

local function projected_card_rule(player, card)
    if type(card) ~= "table" then return nil end
    local key, row = nil, rawget(card, "_view")
    if type(row) == "table" and type(row.evaluation_rules) == "table" then
        if (row.evaluation_owner or row.activation_owner) == player:objectName() then return row.evaluation_rules end
        -- A printed card the question evaluated for the viewer still has every
        -- other player's prototype rules below.
        if row.printed_evaluation ~= true then return nil end
    end
    -- A locally evaluated face carries its owner's availability; a basic face
    -- takes its prototype's corrections (every Slash the Slash's).
    if type(row) == "table" and row.evaluation_only == true and type(row.available) == "boolean"
        and row.evaluation_owner == player:objectName() then
        local prototypes = type(player._view.prototype_rules) == "table" and player._view.prototype_rules or {}
        local rules = prototypes[row.class_name]
        for _, kind in ipairs(row.kind_of or {}) do if kind == "Slash" then rules = prototypes.Slash end end
        rules = type(rules) == "table" and rules or {}
        return {available = row.available, target_mod_residue = rules.target_mod_residue,
            target_mod_distance = rules.target_mod_distance, target_mod_extra = rules.target_mod_extra}
    end
    if type(row) == "table" and row.evaluation_only == true then key = "name:" .. row.name
    elseif type(card.getEffectiveId) == "function" and type(card:getEffectiveId()) == "number" and card:getEffectiveId() >= 0 then
        key = "id:" .. card:getEffectiveId()
    elseif type(row) ~= "table" and type(card.getClassName) == "function" then
        local names = {Jink="jink", Slash="slash", Peach="peach"}
        local name = names[card:getClassName()]
        if name then key = "name:" .. name end
    end
    -- The viewer's own physical cards carry their limits and prohibitions.
    if type(row) == "table" and key and key:sub(1, 3) == "id:" and type(row.limits) == "table"
        and player:objectName() == (player._room and player._room._world.self.object_name) then
        return {limits = row.limits, limits_hand = row.limits_hand, prohibited = row.prohibited,
            available = row.available, target_mod_residue = row.target_mod_residue,
            target_mod_distance = row.target_mod_distance, target_mod_extra = row.target_mod_extra}
    end
    -- A card the viewer may take in this question carries its taker's rules.
    if key and key:sub(1, 3) == "id:" and player:objectName() == (player._room and player._room._world.self.object_name) then
        local ai = player._room._ai
        local options = ai and type(ai.request) == "table" and ai.request.options
        local rows = type(options) == "table" and type(options.context) == "table" and options.context.acquired_card_evaluations
        local acquired = type(rows) == "table" and rows[key:sub(4)]
        if type(acquired) == "table" and type(acquired.card_rules) == "table" then return acquired.card_rules end
    end
    -- A printed basic prototype: every player's projected rules for that class.
    local class_name = type(row) == "table" and row.class_name
        or type(card.getClassName) == "function" and card:getClassName()
    local prototypes = key and key:sub(1, 5) == "name:" and player._view.prototype_rules
    local rules = type(prototypes) == "table" and prototypes[class_name]
    if type(rules) == "table" then
        local limits = {[tostring(sgs.Card_MethodUse)] = rules.use_limited,
            [tostring(sgs.Card_MethodResponse)] = rules.response_limited}
        return {limits = limits, limits_hand = limits, available = rules.available,
            target_mod_residue = rules.target_mod_residue, target_mod_distance = rules.target_mod_distance,
            target_mod_extra = rules.target_mod_extra}
    end
    return nil
end

-- SmartAI's Slash_IsAvailable / Analeptic_IsAvailable on the printed prototype.
local function prototype_available(player, class_name)
    local rules = AIValue.isPlayer(player) and type(player._view.prototype_rules) == "table"
        and player._view.prototype_rules[class_name]
    if type(rules) ~= "table" or type(rules.available) ~= "boolean" then
        ai_unsupported(class_name .. " prototype availability is not projected", class_name)
    end
    return rules.available
end
function sgs.Slash_IsAvailable(player) return prototype_available(player, "Slash") end
function sgs.Analeptic_IsAvailable(player) return prototype_available(player, "Analeptic") end
function CardView:getTargetModResidue(player)
    local rule
    if player then rule = projected_card_rule(player, self) else rule = self._view.evaluation_rules end
    if type(rule) == "table" then return rule.target_mod_residue end
end
ConversionView.getTargetModResidue = CardView.getTargetModResidue
function PlayerView:isCardLimited(card, method, is_handcard)
    local rule = projected_card_rule(self, card)
    local limits = type(rule)=="table" and (is_handcard == true and rule.limits_hand or not is_handcard and rule.limits)
    if type(limits) ~= "table" then return nil end
    return limits[tostring(method)]
end
function PlayerView:isProhibited(other, card)
    local rule = projected_card_rule(self, card)
    if type(rule) ~= "table" or type(rule.prohibited) ~= "table" or not AIValue.isPlayer(other) then return nil end
    return rule.prohibited[other:objectName()]
end

function CardView:isAnalepticAvailable(player)
    if not AIValue.isPlayer(player) or self:isKindOf("Analeptic") ~= true then return nil end
    local rule=projected_card_rule(player,self)
    if type(rule)~="table" then return nil end
    local value=rule.analeptic_static_available
    if type(value)=="boolean" then return value end
end
ConversionView.isAnalepticAvailable=CardView.isAnalepticAvailable

function CardView:isAvailable(player)
    if not AIValue.isPlayer(player) then return nil end
    local rule = projected_card_rule(player, self)
    if type(rule) ~= "table" then return nil end
    return rule.available
end
function ConversionView:isAvailable(player)
    if player == nil then return self._view.available end
    return CardView.isAvailable(self, player)
end

SkillView.hasEvent = SkillView.hasTriggerEvent
function PlayerView:getAttackRange(include_weapon)
    if include_weapon == false then return self._view.attack_range_without_weapon end
    return self._view.attack_range
end

-- Evaluation DTOs never grant authorization to submit a card.
function CardView:isEvaluationOnly() return self._view.evaluation_only == true end
function CardView:isStrategySeed() return self._view.strategy_seed == true end
function SmartAIView:getEvaluationCandidate(card)
    if type(card) ~= "table" then return nil end
    local scoped = rawget(card, "_evaluation_candidate")
    if ((AIValue.isCard(card) and card:isEvaluationOnly()) or AIValue.isConversion(card)) and type(scoped) == "table" then
        return CandidateView.new(copy_value(scoped))
    end
    -- A printed prototype has no target legality of its own.
    return nil
end
function SmartAIView:getAcquiredCardEvaluation(card)
    if type(card) ~= "table" then return nil end
    local context = type(self.request.options) == "table" and self.request.options.context
    local rows = type(context) == "table" and context.acquired_card_evaluations
    local row = type(rows) == "table" and rows[tostring(card:getEffectiveId())]
    local patterns = { ["@@zuguangu"]=true, ["@@zukaiji"]=true, ["@@zugaobian"]=true,
        ["@@zugaoshi"]=true, ["@@kezuliuju"]=true, ["@@kezuhuanjia"]=true, ["@@zujieli"]=true, ["@@zugezhi"]=true, ["@@poxi"]=true }
    if type(row) ~= "table" and patterns[self.request.pattern] and type(ai_evaluate_notified_card) == "function" then
        row = ai_evaluate_notified_card(card:getEffectiveId())
        if type(row) == "table" and row.error then self._notified_evaluation_error = row.error end
    end
    if type(row) ~= "table" or row.evaluation_only ~= true then return nil end
    local projected = CardView.new(copy_value(row.card))
    if not projected then return nil end
    projected._view.evaluation_rules = copy_value(row.card_rules)
    projected._evaluation_candidate = copy_value(row.candidate)
    -- Separate native-authenticated source observation; never change the
    -- hypothetical evaluation Card's identity, printing or rule profile.
    if type(row.observed_source) == "table" then
        projected._olclan_observed_source = copy_value(row.observed_source)
    end
    return projected, CandidateView.new(copy_value(row.candidate))
end
function SmartAIView:getResponsePlanningCard(conversion, variant)
    local row = type(conversion) == "table" and rawget(conversion, "_view")
    local planning = type(row) == "table" and row[variant == "class" and "response_class_planning" or "response_planning"]
    if variant == "class" then
        if type(planning) ~= "table" or type(planning.exists) ~= "boolean" then return nil, nil, nil end
        if not planning.exists then return nil, nil, false end
        if type(planning.card) ~= "table" or type(planning.candidate) ~= "table" then return nil, nil, nil end
    end
    if type(planning) ~= "table" or type(planning.card) ~= "table" then return nil end
    local card, candidate = copy_value(planning.card), copy_value(planning.candidate or planning)
    if AIValue.isCard(conversion) and conversion:isEvaluationOnly() then
        -- Native detached class dummy, not a conversion ticket. Keep its native
        -- identity and request-owned recipe; planning reads the scoped candidate.
        if variant ~= "class" or type(card.readonly_recipe_key) ~= "string"
            or card.readonly_recipe_key == "" then return nil, nil, nil end
        local projected = CardView.new(card)
        projected._ai, projected._evaluation_candidate = self, copy_value(candidate)
        return projected, CandidateView.new(candidate), true
    end
    local id = -(variant == "class" and 2000000 or 1000000) - conversion:getConversionId()
    card.id, card.effective_id, card.evaluation_only = id, id, true
    candidate.card_id = id
    self._response_planning_candidates = self._response_planning_candidates or {}
    self._response_planning_candidates[id] = candidate
    return CardView.new(card), CandidateView.new(copy_value(candidate)), true
end
function ConversionView:getUserString() return self._view.declared_name end
-- After `offset` more uses of `class`: the viewer's own card stays available while
-- some target's Residue still covers the history (Player::canSlashWithoutCrossbow).
function CandidateView:isAvailableWithHistoryOffset(offset, class)
    if type(offset) ~= "number" or offset % 1 ~= 0 then return nil end
    local rows = self._view.history_available
    if type(rows) == "table" then return rows[tostring(offset)] end
    local ai = rawget(self, "_ai")
    if not ai or type(class) ~= "string" then return nil end
    if self._view.available ~= true then return false end
    if offset == 0 then return true end
    local card = ai:getKnownCardById(self._view.card_id)
    local residue = card and card._view.target_residue
    local used = ai.player:usedTimes(class)
    if type(residue) ~= "table" or type(used) ~= "number" then return nil end
    for _, value in pairs(residue) do
        if used + offset <= value then return true end
    end
    return false
end
CandidateView.getAvailabilityWithHistoryOffset = CandidateView.isAvailableWithHistoryOffset
-- fillSkillCards' view of one skill at Play. An activatable V2 instance comes from
-- request.skill_actions with its play-time action; a V2 skill without one has
-- instance -1; any other skill is instance 0 with its owner-only view-as fields.
function SmartAIView:getFillSkillContext(name)
    local owner = self.player:objectName()
    local actions = type(self._indexes) == "table" and self._indexes.skill_actions_by_name
    for _, action in ipairs(actions and actions[name] or {}) do
        if action.activation_owner == owner then
            local request = {viewer = self.request.viewer, decision_id = self.request.decision_id,
                state_revision = self.request.state_revision, kind = self.request.kind,
                reason = sgs.CardUseStruct_CARD_USE_REASON_PLAY, pattern = "", prompt = "",
                handling_method = sgs.Card_MethodUse, skill_action = copy_value(action)}
            return {known = true, instance_id = action.activation_instance, has_view_as = true,
                enabled_at_play = true, request = AILegacyRequest.new(request, self.room)}
        end
    end
    local view
    for _, skill in ipairs(type(self.player._view.skills) == "table" and self.player._view.skills or {}) do
        if skill.name == name then view = skill break end
    end
    if view and view.view_as_v2 == true then return {known = true, instance_id = -1} end
    return {known = true, instance_id = 0, has_view_as = view and view.has_view_as_skill,
        enabled_at_play = view and view.enabled_at_play}
end
-- A skill definition is projected only where a visible player holds the skill.
function RoomView:getPublicSkill(name)
    for _, player_name in ipairs(self._player_order) do
        local view = self._players[player_name]._view
        for _, row in ipairs(type(view.skills) == "table" and view.skills or {}) do
            if row.name == name then return SkillView.new(copy_value(row)) end
        end
    end
    return nil
end
function SmartAIView:hasStrategyPlayerFlag(player, name)
    local policy = self.world.mode_policy
    local rows = type(policy) == "table" and policy.strategy_flags
    rows = type(rows) == "table" and rows[player:objectName()]
    if type(rows) == "table" and type(rows[name]) == "boolean" then return rows[name] end
    -- A complete overlay with an absent key means this AI has not set it.
    if type(policy) == "table" and type(policy.strategy_flags) == "table" then return false end
    return nil
end
function SmartAIView:setStrategyPlayerFlag(player, name, value)
    if name=='willSkipPlayPhase' then
        local hegemony=AIHegemony.facts(self.world)
        assert(player==self.player and self.request.kind=='guanxing' and hegemony
            and hegemony.original_overrides_loaded==true,'Original Guanxing strategy flag scope')
        return self:writeOriginalGuanxingShadow(value)
    end
    assert(AIValue.isPlayer(player) and type(value) == "boolean", "invalid strategy flag")
    local valid = standard_strategy_flag(player,name) or name == "AI_HuangtianPindian" or name == "AI_MizhaoTarget" or name == "AI_doNotSave" or name == "AIGlobal_NeedToWake" or name == "needCrossbow"
        or (type(name) == "string" and name:sub(1,7) == "duelTo_" and self.room:findPlayerByObjectName(name:sub(8)) ~= nil)
    valid = valid or name == "weapon_done_" .. self.player:objectName() .. "_" .. player:objectName()
    assert(valid, "unknown strategy flag")
    local policy = self.world.mode_policy
    assert(type(policy) == "table" and type(policy.strategy_flags) == "table", "strategy flags not projected")
    local player_name = player:objectName()
    policy.strategy_flags[player_name] = policy.strategy_flags[player_name] or {}
    policy.strategy_flags[player_name][name] = value
    if self._strategy_evaluation then return end
    if self._event_effect_sink then
        self:emitStrategyEffect({kind="strategy_flag",player=player_name,name=name,value=value})
        return
    end
    self._strategy_effects = self._strategy_effects or {}
    assert(#self._strategy_effects < 64, "strategy effect limit")
    self._strategy_effects[#self._strategy_effects+1] = {kind="strategy_flag",player=player_name,name=name,value=value,after_delta=0}
end

function SkillView:getViewAsEquipNames()
    local names = self._view.view_as_equip_names
    return AIValue.isList(names) and AIList.new(names) or nil
end

function CardView:getHandlingMethod() return self._view.handling_method end
function ConversionView:getHandlingMethod() return self._view.handling_method end

ConversionView.getTargetResidue = CardView.getTargetResidue

function PlayerView:canUse(card, target)
    local row = type(card)=="table" and rawget(card,"_view")
    local scoped = type(row)=="table" and row.can_use_by_player
    local public_values = type(scoped)=="table" and scoped[self:objectName()]
    if type(public_values)=="table" then
        if target then return public_values[target:objectName()] end
        for _, value in pairs(public_values) do if value==true then return true end end
        return false
    end
    local rule = projected_card_rule(self, card)
    local values = type(rule) == "table" and rule.can_use
    local ai = self._room and self._room._ai
    if type(values) ~= "table" and ai and self:objectName() == ai.player:objectName() then
        local candidate = ai:getCardCandidate(card:getEffectiveId())
        if not candidate and card:isEvaluationOnly() then candidate = ai:getEvaluationCandidate(card) end
        values = candidate and candidate._view.can_use_targets
        -- The request candidate's legal targets are Player::canUse with no selection.
        local legal = type(values) ~= "table" and candidate and candidate._view.legal_targets
        if AIValue.isList(legal) then
            values = {}
            for _, name in ipairs(legal) do values[name] = true end
            if target and values[target:objectName()] == nil then return false end
        end
    end
    if type(values) ~= "table" then return nil end
    if target then return values[target:objectName()] end
    for _, value in pairs(values) do if value == true then return true end end
    return false
end
function RoomView:hasCurrent(active)
    if active then
        -- Room::hasCurrent(true): the current player is alive and in its turn.
        local current = self:getCurrent()
        if not current then return false end
        return current:isAlive() == true and self._world.current_phase ~= sgs.Player_NotActive
    end
    return type(self._world.current_player) == "string" and self._world.current_player ~= ""
end

-- Damage bookkeeping facts are not projected; callers see unknown.
local function damage_facts(room)
    return nil
end
-- Only the Guandu scenario writes its event tag; other modes have none.
function RoomView:getGuanduEvent()
    if self._world.mode_id ~= "guandu" then return "" end
    return nil
end
-- keqiyanhuo sets its room tag to 1 when its owner dies, with a public log.
function RoomView:getKeqiyanhuoCount()
    for _, name in ipairs(self._player_order) do
        local player = self._players[name]
        if player:isDead() == true and player:hasSkill("keqiyanhuo") == true then return 1 end
    end
    return 0
end
function PlayerView:getDjianxiongRecord()
    local facts = damage_facts(self._room)
    local records = type(facts) == "table" and facts.records_by_player
    local names = type(records) == "table" and records[self:objectName()]
    return AIValue.isList(names) and AIList.new(names) or nil
end
function SmartAIView:getDamageCardState(card)
    if type(card) ~= "table" then return nil end
    local face = rawget(card,"_view")
    local origin = type(face) == "table" and face.source_damage_state
    if type(origin) == "table" and origin.basis == "r56_native_slash_constructor"
        and face.evaluation_only == true and face.evaluation_owner == self.player:objectName()
        and face.name == "slash" and type(face.readonly_recipe_key) == "string"
        and face.readonly_recipe_key ~= "" then return copy_value(origin) end
    local facts = damage_facts(self.room)
    local cards = type(facts) == "table" and facts.cards_by_id
    local row = type(cards) == "table" and cards[tostring(card:getEffectiveId())]
    return type(row) == "table" and copy_value(row) or nil
end

function PlayerView:hasEquipArea(index)
    local areas = self._view.equip_areas
    if not AIValue.isList(areas) then return nil end
    if index == nil then
        for _, area in ipairs(areas) do
            if type(area) ~= "number" or area % 1 ~= 0 or area < 0 or area > 4 then return nil end
        end
        return #areas > 0
    end
    for _, area in ipairs(areas) do if area == index then return true end end
    return false
end
function PlayerView:hasTreasure(name)
    if not self:getEquips() then return nil end
    local card = self:getTreasure()
    return card ~= nil and (name == nil or card:objectName() == name or card:isKindOf(name))
end

-- Engine::getPlayerCount(mode) is the size of this room's roster.
function RoomView:getModePlayerCount()
    local order = self._world.player_order
    return AIValue.isList(order) and #order or nil
end
function PlayerView:getJianyuanRecord()
    local facts = damage_facts(self._room)
    local records = type(facts) == "table" and facts.jianyuan_records_by_player
    local names = type(records) == "table" and records[self:objectName()]
    return AIValue.isList(names) and AIList.new(names) or nil
end
-- A Dismantlement converted from this card is not projected: unknown.
function SmartAIView:getDismantlementProbe(card)
    return nil
end
-- Every armor name among the engine's cards, from the (fixed) card catalog.
local catalog_armor_names
function RoomView:getArmorNames()
    if type(ai_card_catalog) ~= "table" then return nil end
    if not catalog_armor_names then
        catalog_armor_names = {}
        for _, row in ipairs(ai_card_catalog) do
            for _, kind in ipairs(type(row.kind_of) == "table" and row.kind_of or {}) do
                if kind == "Armor" then catalog_armor_names[#catalog_armor_names + 1] = row.name break end
            end
        end
    end
    return AIList.new(copy_value(catalog_armor_names))
end

function RoomView:findPlayersBySkillName(name)
    local players = self:getAlivePlayers()
    if not players then return nil end
    local result = AIList.new({})
    for _, player in ipairs(players) do
        local has = player:hasSkill(name)
        if has == nil then return nil end
        if has then result:append(player) end
    end
    return result
end

function PlayerView:getNewtypePattern()
    return self._view.newtype_pattern
end

-- This is distinct from the native response proxy; both remain evaluation only.
function ConversionView:getSlashWrapperPlanning()
    local rules = self._view.evaluation_rules
    local row = type(rules) == "table" and rules.slash_wrapper_planning
    if type(row) ~= "table" or type(row.card) ~= "table" or type(row.candidate) ~= "table" then return nil end
    local card = CardView.new(copy_value(row.card))
    card._evaluation_candidate = copy_value(row.candidate)
    return card, CandidateView.new(copy_value(row.candidate))
end

function PlayerView:getRoom() return self._room end

-- Player::getRandomHandCard: a uniform pick from the viewer's own hand.
function PlayerView:getRandomHandCard()
    local ai = self._room and self._room._ai
    local hand = ai and self:objectName() == ai.player:objectName() and self:getHandcards()
    if not hand then ai_unsupported("only the viewer's own hand can be sampled", "getRandomHandCard") end
    if #hand == 0 then return nil end
    return hand[math.random(1, #hand)]
end

-- A strategy seed deliberately has no payment capability. Source use_func must
-- replace it with bindSkillCard's real receipt after choosing its actual costs.
-- The evaluation face of a skill card this player could activate now. A V2
-- skill is usable when the authority offers its action; a V1 skill card when
-- its owner view-as skill is enabled at play. Targets and the final product are
-- checked by the authority when the selected card is bound.
function SmartAIView:skillCardFace(skill, class_name, costs, request, user_string)
    local selected = self:findOfferedSkillAction(skill, request)
    local available = selected ~= nil
    if not selected then
        local view
        for _, skill_view in ipairs(type(self.player._view.skills) == "table" and self.player._view.skills or {}) do
            if skill_view.name == skill then view = skill_view break end
        end
        if not view or type(view.view_as_v2) ~= "boolean" or type(view.enabled_at_play) ~= "boolean" then
            ai_unsupported("skill action has no matching source scope", skill)
        end
        available = not view.view_as_v2 and view.enabled_at_play
    end
    local identity = selected and selected.identity or {}
    local lua_card = class_name:sub(1, 1) == "#"
    local face = lua_card and "LuaSkillCard" or class_name
    local ids = #costs > 0 and table.concat(costs, "+") or "."
    local wire = lua_card and (class_name .. ":" .. ids .. ":" .. (user_string or ""))
        or ("@" .. class_name .. "=" .. ids .. (user_string and user_string ~= "" and (":" .. user_string) or ""))
    -- Synthetic ids stay clear of conversion ids (getCardCandidate maps negatives).
    self._turn_seed_serial = (self._turn_seed_serial or 0) + 1
    local seed_id = -(2000000 + self._turn_seed_serial)
    local row = {id = seed_id, effective_id = costs[1] or seed_id, name = lua_card and class_name:sub(2) or class_name,
        class_name = face, kind_of = {face, "SkillCard", "Card"}, type_id = sgs.Card_TypeSkill,
        suit = sgs.Card_NoSuit, number = 0, skill_name = skill, subcards = copy_value(costs),
        user_string = user_string, virtual_card = true, evaluation_only = true, strategy_seed = false,
        available = available, legacy_string_key = wire, legacy_sort_key = wire, flags = {}, can_recast = false,
        evaluation_owner = self.player:objectName()}
    for key, value in pairs({activation_owner = identity.activation_owner, activation_skill = identity.activation_skill,
        activation_instance = identity.activation_instance, source_owner = identity.source_owner,
        source_skill = identity.source_skill, source_instance = identity.source_instance}) do
        row[key] = value
    end
    return row
end

function SmartAIView:legacySkillSeed(skill, class_name, request)
    local row = self:skillCardFace(skill, class_name, {}, request)
    row.strategy_seed = true
    local seed = CardView.new(row)
    local fields = {activation_owner="getActivationOwner",activation_skill="getActivationSkillName",
        activation_instance="getActivationInstanceId",source_owner="getSourceOwner",
        source_skill="getSourceSkillName",source_instance="getSourceInstanceID"}
    for key, method in pairs(fields) do
        local field = key
        seed[method] = function() return row[field] end
    end
    seed.getAuthorityCard = function() return nil end
    seed.toCardSpec = function() ai_unsupported("unpaid strategy seed cannot be submitted",skill) end
    seed.isAvailable = function(_, player)
        if player == nil or player:objectName() == self.player:objectName() then return row.available end
    end
    return seed
end

-- The only alternative to complete target enumeration is an authentic,
-- request-local Qiuxin source-query profile. It never grants action authority.
local qiuxin_source_cards=setmetatable({}, {__mode='k'})
local function qiuxin_same(a,b,depth)
    if type(a)~=type(b) then return false end
    if type(a)~='table' then return a==b end
    depth=(depth or 0)+1
    if depth>24 or getmetatable(a)~=nil or getmetatable(b)~=nil then
        ai_unsupported('Qiuxin source profile is not pure bounded data','qiuxin_profile')
    end
    for k,v in pairs(a)do if not qiuxin_same(v,b[k],depth)then return false end end
    for k in pairs(b)do if a[k]==nil then return false end end
    return true
end
local function qiuxin_stamp(ai,key)
    local r=ai.request
    if type(r)~='table' or r.viewer~=ai.player:objectName()
        or (type(r.decision_id)~='number' and type(r.decision_id)~='string')
        or (type(r.state_revision)~='number' and type(r.state_revision)~='string')then
        ai_unsupported('source profile request identity unknown','source_extra99')
    end
    local nested
    if key=='kezuqiuxin' then
        if r.kind~='amazing_grace' or type(r.options)~='table' or r.options.reason~='kezuqiuxin'then
            ai_unsupported('Qiuxin profile requires current owner AG','source_extra99')
        end
    elseif key=='feihujue' or key=='feilangduo' then
        nested=ai:getReadonlyPlayContext()
        if (not nested and (r.kind~='activate' or r.reason~=0x01 or r.pattern~='')) or ai.player:hasSkill(key)~=true then
            ai_unsupported('FeiDIY profile requires its owner source Play','source_extra99')
        end
    elseif key=='newgenerals.mouxieji' then
        if r.kind~='use_card' or r.pattern~='@@mouxieji'
            or (r.reason~=0x02 and r.reason~=0x12) or ai.player:hasSkill('mouxieji')~=true then
            ai_unsupported('Mouxieji extra2 profile requires its current owner response','source_extra99')
        end
    elseif key=='newgenerals_context:moujiang' then
        if r.kind~='player_chosen' or type(r.options)~='table' or r.options.reason~='moujiang' or ai.player:hasSkill('moujiang')~=true then
            ai_unsupported('Moujiang profile requires exact owner question','source_extra99')
        end
    elseif key=='fcDIY_context:sp_hengsaoqianjun' or key=='fcDIY_context:sp_lvezhen'
        or key=='fcDIY_context:fcjielianhuan' or key=='fcDIY_context:fcmoujiang' then
        local skill=key:sub(15)
        local kind_ok=skill=='sp_hengsaoqianjun' and (r.kind=='choice' or r.kind=='players_chosen')
            or (skill=='sp_lvezhen' or skill=='fcjielianhuan') and r.kind=='player_chosen'
            or skill=='fcmoujiang' and r.kind=='players_chosen'
        if not kind_ok or type(r.options)~='table' or r.options.reason~=skill or ai.player:hasSkill(skill)~=true then
            ai_unsupported('FC profile requires its current source question','source_extra99')
        end
    else ai_unsupported('unknown extra99 source','source_extra99')end
    return {viewer=r.viewer,decision_id=r.decision_id,state_revision=r.state_revision,
        kind=r.kind,reason=r.reason,pattern=r.pattern,handling_method=r.handling_method,
        choice_reason=type(r.options)=='table' and r.options.reason or nil,source_key=key,nested=nested}
end
local function qiuxin_marker(candidate)
    local mark=type(candidate)=='table' and candidate.readonly_source_queries
    return type(mark)=='table' and (((mark.source_key=='kezuqiuxin' or mark.source_key=='feihujue' or mark.source_key=='feilangduo') and mark.extra_target==99)
        or (mark.source_key=='newgenerals.mouxieji' and mark.extra_target==2))
end
local function qiuxin_entry(ai,card)
    local entries=qiuxin_source_cards[ai]
    local saved=entries and entries[card]
    if not saved then return nil end
    if saved.request~=ai.request or not qiuxin_same(saved.stamp,qiuxin_stamp(ai,saved.source_key))
        or not qiuxin_same(saved.face,rawget(card,'_view'))
        or not qiuxin_same(saved.candidate,rawget(card,'_evaluation_candidate'))then
        ai_unsupported('Qiuxin source profile identity changed','qiuxin_profile')
    end
    return saved
end
local function qiuxin_register(ai,card,spec)
    if spec.source_key~='kezuqiuxin' and spec.source_key~='feihujue' and spec.source_key~='feilangduo' and spec.source_key~='newgenerals.mouxieji' then return end
    local face=rawget(card,'_view');local candidate=rawget(card,'_evaluation_candidate')
    local fei=spec.source_key=='feihujue' or spec.source_key=='feilangduo'
    local mox=spec.source_key=='newgenerals.mouxieji'
    if spec.skill~=(mox and '_mouxieji' or fei and 'feihujue' or '_kezuqiuxin')
        or (mox and spec.name~='slash') or (fei and spec.name~='duel') or spec.suit~=sgs.Card_NoSuit or spec.number~=0
        or not AIValue.isList(spec.subcards) or #spec.subcards~=0
        or not qiuxin_marker(candidate) or candidate.readonly_source_queries.source_key~=spec.source_key or candidate.complete_coverage~=false
        or type(face.readonly_recipe_key)~='string' or face.readonly_recipe_key=='' then
        ai_unsupported('Qiuxin source queries were not issued by the native producer','qiuxin_profile')
    end
    local entries=qiuxin_source_cards[ai]
    if not entries then entries=setmetatable({}, {__mode='k'});qiuxin_source_cards[ai]=entries end
    entries[card]={request=ai.request,source_key=spec.source_key,stamp=qiuxin_stamp(ai,spec.source_key),face=copy_value(face),
        candidate=copy_value(candidate),recipe_key=face.readonly_recipe_key}
end
function SmartAIView:isAuditedExtra99SourceQueryPlan(card,use)
    local saved=qiuxin_entry(self,card)
    if not saved then return false end
    return type(use)=='table' and use.isDummy==true
        and use.extra_target==saved.candidate.readonly_source_queries.extra_target
end
SmartAIView.isQiuxinSourceQueryPlan=SmartAIView.isAuditedExtra99SourceQueryPlan

-- Exact public printing of an owner-observed view-as material. This returns
-- knowledge for planning; callers bind a new native receipt after selection.
function SmartAIView:evaluateOwnerViewAsCard(spec)
    -- The owner's view-as product: the printed catalog face with this skill's
    -- printing, like Card::Parse of its legacy string. The authority rebuilds
    -- and checks the real product when the selected card is submitted.
    if type(spec) ~= "table" or type(spec.name) ~= "string" or type(spec.skill) ~= "string"
        or type(spec.suit) ~= "number" or type(spec.number) ~= "number" or not AIValue.isList(spec.subcards) then
        ai_unsupported("owner view-as face is incomplete", "evaluateOwnerViewAsCard")
    end
    local base = self:getEvaluationCard(spec.name)
    if not base then ai_unsupported("owner view-as product is outside the card catalog", spec.name) end
    local materials = {}
    for index, id in ipairs(spec.subcards) do
        materials[index] = self:getKnownCardById(id)
        if not materials[index] then ai_unsupported("owner view-as material is not visible", "evaluateOwnerViewAsCard") end
    end
    -- Card::getSuit/getNumber: an unset printing derives from the material.
    local suit, number = spec.suit, spec.number
    if suit < 0 or suit > 5 then
        suit = sgs.Card_NoSuit
        if #materials == 1 then
            suit = materials[1]:getSuit()
        elseif #materials > 1 then
            local color = materials[1]:getColor()
            for index = 2, #materials do
                if materials[index]:getColor() ~= color then color = nil break end
            end
            if color == 0 then suit = sgs.Card_NoSuitRed elseif color == 1 then suit = sgs.Card_NoSuitBlack end
        end
    end
    if number <= 0 then number = #materials == 1 and materials[1]:getNumber() or 0 end
    if type(suit) ~= "number" or type(number) ~= "number" then
        ai_unsupported("owner view-as material printing is unknown", "evaluateOwnerViewAsCard")
    end
    local suits = {[0] = "spade", "club", "heart", "diamond", "no_suit_black", "no_suit_red"}
    local number_string = number == 10 and "10" or number > 13 and "JOKER"
        or string.sub("0A23456789-JQK", number + 1, number + 1)
    local wire = spec.name .. ":" .. spec.skill .. "[" .. (suits[suit] or "no_suit") .. ":" .. number_string
        .. "]=" .. (#spec.subcards > 0 and table.concat(spec.subcards, "+") or ".")
    local face = copy_value(base._view)
    face.suit, face.number = suit, number
    face.red = suit == sgs.Card_Heart or suit == sgs.Card_Diamond or suit == sgs.Card_NoSuitRed
    face.black = suit == sgs.Card_Spade or suit == sgs.Card_Club or suit == sgs.Card_NoSuitBlack
    face.skill_name, face.skill_names = spec.skill, {spec.skill}
    face.subcards = copy_value(spec.subcards)
    if spec.can_recast ~= nil then face.can_recast = spec.can_recast end
    face.evaluation_owner = self.player:objectName()
    -- A basic product follows its printed prototype's rules (every Slash the Slash's).
    local prototypes = type(self.player._view.prototype_rules) == "table" and self.player._view.prototype_rules or {}
    local rules = prototypes[face.class_name]
    for _, kind in ipairs(face.kind_of or {}) do if kind == "Slash" then rules = prototypes.Slash end end
    face.available = type(rules) ~= "table" or (rules.available == true and rules.use_limited ~= true)
    -- Without materials the product is the printed card the question may have
    -- evaluated: its rules and complete targets. Otherwise targets are unknown.
    local printed = #spec.subcards == 0 and printed_card_evaluation(self, spec.name) or nil
    face.evaluation_rules = printed and copy_value(printed.card_rules) or nil
    if printed then face.available = printed.card_rules.available end
    face.legacy_identity_token = fresh_policy_identity(policy_identity_scope(self))
    face.legacy_string_key, face.legacy_sort_key = wire, wire
    local card = CardView.new(face)
    card._evaluation_candidate = printed and copy_value(printed.candidate) or {card_id = -1,
        available = face.available, limited = false, complete_coverage = false,
        target_filter_empty = type(rules) == "table" and copy_value(rules.target_filter_empty) or nil,
        extra_target_count = type(rules) == "table" and rules.extra_target or nil}
    card.getAuthorityCard = function() return nil end
    card.toCardSpec = function() ai_unsupported("owner view-as evaluation has no submission receipt", "evaluateOwnerViewAsCard") end
    qiuxin_register(self,card,spec)
    return card
end

-- A V1 view-as product is evaluated only; the receipt keeps the evaluated face,
-- and submitting it falls back to SmartAI.
function SmartAIView:registerViewAsReceipt(face)
    local indexes = self._indexes
    if type(indexes) ~= "table" or type(indexes.conversions) ~= "table" then
        ai_unsupported("conversion index is unavailable", face.skill_name)
    end
    local id = skill_action_receipt_base + #indexes.conversions + 1
    local row = copy_value(face)
    row.id, row.effective_id, row.evaluation_only, row.evaluation_owner = nil, nil, nil, nil
    row.conversion_id, row.kind_of_names, row.available = id, copy_value(face.kind_of), true
    row.activation_owner, row.activation_skill = self.player:objectName(), face.skill_name
    row.source_owner, row.source_skill = self.player:objectName(), face.skill_name
    row.authority_validates_targets, row.legacy_v1 = true, true
    indexes.conversions[#indexes.conversions + 1] = row
    indexes.conversions_by_id[id] = row
    return ConversionView.new(copy_value(row))
end

-- Named turn hypotheses are never receipts. Keep the binding recipe outside
-- public CardView rows, and validate its request and source again at selection.
local readonly_turn_cards = setmetatable({}, {__mode="k"})
local turn_identity_methods = {
    activation_owner="getActivationOwner",activation_skill="getActivationSkillName",activation_instance="getActivationInstanceId",
    source_owner="getSourceOwner",source_skill="getSourceSkillName",source_instance="getSourceInstanceID"
}
local turn_request_fields={"viewer","decision_id","state_revision","kind","reason","pattern","handling_method"}
local function turn_checked(value,key)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil then ai_unsupported("readonly turn input is unknown",key) end
    return value
end
local function turn_same(a,b)
    if type(a)~=type(b) then return false end
    if type(a)~="table" then return a==b end
    for k,v in pairs(a) do if not turn_same(v,b[k]) then return false end end
    for k in pairs(b) do if a[k]==nil then return false end end
    return true
end
-- A native-authored policy context does not replace the active inquiry or
-- carry payment capability. Every returned card remains parent-request bound.
function SmartAIView:getReadonlyPlayContext()
    local request=self.request
    local row=type(request)=="table" and request.readonly_play_context
    if row==nil then return nil end
    local options=type(request.options)=="table" and request.options
    local source_ok=type(row)=="table" and (
        (request.kind=="skill_invoke" and options and (
            (row.source=="olClan.zuheta" and (options.reason=="zuheta" or options.reason=="zuheta$-1"))
            or (row.source=="OverseasVersion.ov_xiafeng" and options.reason=="ov_xiafeng")))
        or (row.source=="OverseasVersion.ov_shelie" and request.kind=="choice" and options
            and options.reason=="ov_shelie" and AIValue.isList(options.choices)
            and #options.choices==2 and options.choices[1]=="Player_Draw" and options.choices[2]=="Player_Play")
        or (row.source=="OverseasVersion.ov_niwo" and request.kind=="use_card"
            and request.pattern=="@@ov_niwo" and request.prompt=="ov_niwo0"
            and request.reason==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
            and request.handling_method==sgs.Card_MethodUse))
    if type(row)~="table" or row.known~=true or row.readonly~=true
        or not source_ok
        or row.kind~="activate" or row.reason~=sgs.CardUseStruct_CARD_USE_REASON_PLAY
        or row.pattern~="" or row.handling_method~=sgs.Card_MethodUse
        or row.viewer~=request.viewer or row.viewer~=self.player:objectName()
        or row.decision_id~=request.decision_id or row.state_revision~=request.state_revision then
        ai_unsupported("nested readonly Play context is incomplete or stale","zuheta.planning")
    end
    return copy_value(row)
end
local function turn_snapshot(ai)
    local request=ai.request
    local readonly=ai:getReadonlyPlayContext()
    if type(request)~="table" or (not readonly and (request.kind~="activate" or request.reason~=0x01))
        or type(request.viewer)~="string" or request.viewer~=ai.player:objectName()
        or (type(request.decision_id)~="number" and type(request.decision_id)~="string")
        or (type(request.state_revision)~="number" and type(request.state_revision)~="string") then
        ai_unsupported("readonly turn query requires its current owner Play request","turn_conversion")
    end
    local result={};for _,key in ipairs(turn_request_fields) do result[key]=request[key] end
    if readonly then result.readonly_play_context=readonly end
    return result
end
local function turn_source(request)
    if request==nil then return nil end
    local result={}
    for key,method in pairs(turn_identity_methods) do
        if type(request[method])~="function" then ai_unsupported("readonly turn source identity is missing",key) end
        result[key]=turn_checked(request[method](request),key)
    end
    return result
end
local function turn_saved(ai,card)
    local entries=readonly_turn_cards[ai]
    local entry=entries and entries[card]
    if not entry or entry.request~=ai.request or not turn_same(entry.stamp,turn_snapshot(ai)) then
        ai_unsupported("readonly turn card belongs to another request","turn_conversion")
    end
    if not turn_same(entry.source,turn_source(entry.skill_request))
        or not turn_same(entry.face,card._view) or not turn_same(entry.candidate,card._evaluation_candidate) then
        ai_unsupported("readonly turn policy identity changed","turn_conversion")
    end
    return entry
end
-- A source addSubcard mutation keeps object identity. Validate the sealed
-- hypothesis first, then update only its comparison token in the saved face.
local inherit_unsealed_identity = SmartAIView.inheritLegacyCardIdentity
function SmartAIView:inheritLegacyCardIdentity(result, source)
    local entries=readonly_turn_cards[self]
    local entry=entries and entries[result] and turn_saved(self,result)
    -- Source-timed pure allocations keep their strategy identity when a native
    -- readonly profile is attached. Validate the existing seal before changing
    -- only its comparison token; recipe, request, face and candidate stay sealed.
    local query_entries=qiuxin_source_cards[self]
    local query_entry=query_entries and query_entries[result]
    query_entry=query_entry and query_entry.source_key=='newgenerals.mouxieji'
        and qiuxin_entry(self,result) or nil
    local value=inherit_unsealed_identity(self,result,source)
    if entry then entry.face.legacy_identity_token=result._view.legacy_identity_token end
    if query_entry then query_entry.face.legacy_identity_token=result._view.legacy_identity_token end
    return value
end
function SmartAIView:isReadonlyTurnConversion(card)
    local entries=readonly_turn_cards[self]
    return entries~=nil and entries[card]~=nil
end
-- Fixed GodYouhua source-timed clone/parse knowledge, never a receipt.
function SmartAIView:getGodYouhuaSourceObservation(material_id)
    if type(ai_evaluate_skill_card)~='function' then ai_unsupported('GodYouhua parser observation unavailable','GodYouhua')end
    if material_id~=nil and (type(material_id)~='number' or material_id<0 or material_id%1~=0)then
        ai_unsupported('GodYouhua source material is not an exact ID','GodYouhua')
    end
    local row=ai_evaluate_skill_card('GodYouhua',material_id~=nil and 'source_parse' or 'source_reference',material_id~=nil and {material_id}or{})
    if AIUnsupported.is(row)then error(row,0)end
    local request=self.request
    if type(request)~='table' or type(row)~='table' or row.kind~='god_youhua_source' or row.known~=true
        or row.viewer~=request.viewer or row.decision_id~=request.decision_id or row.state_revision~=request.state_revision
        or type(row.reference_id)~='number' or row.reference_id<=0 or row.reference_id%1~=0
        or type(row.clone_exists)~='boolean' then
        ai_unsupported(type(row)=='table'and row.error or 'GodYouhua observation identity mismatch','GodYouhua')
    end
    if row.clone_exists and (type(row.clone)~='table' or not AIValue.isList(row.clone.kind_of))then
        ai_unsupported('GodYouhua exact clone class is incomplete','GodYouhua')
    end
    if material_id~=nil and (row.material_id~=material_id or type(row.source_wire)~='string'
        or type(row.exists)~='boolean' or row.exists and (type(row.card)~='table'
            or type(row.card.name)~='string' or type(row.card.class_name)~='string'
            or row.card.skill_name~='GodYouhua' or not AIValue.isList(row.card.subcards)
            or #row.card.subcards~=1 or row.card.subcards[1]~=material_id))then
        ai_unsupported('GodYouhua exact parser result is incomplete','GodYouhua')
    end
    return row
end
function SmartAIView:evaluateTurnConversion(skill,class_name,spec,request)
    -- Expand only after auditing another source's hypothetical clone semantics.
    local audited={melee_peach={"Slash","slash"},noslonghun={"FireSlash","fire_slash"},jieyou={"Analeptic","analeptic"},LuaYanjiu={"Analeptic","analeptic"},jianhun={"Slash","slash"},GodQuxiang={"SavageAssault","savage_assault"},GodGongshen={"ArcheryAttack","archery_attack"}}
    audited.fan={"FireSlash","fire_slash"}
    audited.longdan={"Slash","slash"}
    audited.qixi={"Dismantlement","dismantlement"}
    audited.nosgongqi={"Slash","slash"}
    audited.nosguose={"Indulgence","indulgence"}
    audited.duanliang={"SupplyShortage","supply_shortage"}
    audited.zhanjue={"Duel","duel"}
    audited.olzhanjue={"Duel","duel"}
    audited.gdlonghun={"FireSlash","fire_slash"}
    audited.longhun={"FireSlash","fire_slash"}
    if skill=="newlonghun" and type(spec)=="table" then
        local products={fire_slash="FireSlash",peach="Peach"}
        if products[spec.name] then audited.newlonghun={products[spec.name],spec.name} end
    end
    audited.jijiu={"Peach","peach"}
    audited.jiuchi={"Analeptic","analeptic"}
    audited.krskitgjiamian={"Slash","slash"}
    audited.secondjincaiwang={"Slash","slash"}
    audited.touzhi={"Slash","slash"}
    audited.cihuai={"Slash","slash"}
    audited.chixin={"Slash","slash"}
    audited.peiniang={"Analeptic","analeptic"}
    if skill=="godlongnu" and type(spec)=="table" then
        local names={fire_slash="FireSlash",thunder_slash="ThunderSlash"}
        if names[spec.name] then audited.godlongnu={names[spec.name],spec.name} end
    end
    if skill=="zhifeng" and type(spec)=="table" then
        local names={slash="Slash",analeptic="Analeptic",duel="Duel"}
        if names[spec.name] then audited.zhifeng={names[spec.name],spec.name} end
    end
    audited.lxtx_zhangwu={"Slash","slash"}
    audited.lxtx_shouyue_wusheng={"Slash","slash"}
    audited.lxtx_wupao={"Slash","slash"}
    if type(spec)=="table" and (skill=="lxtx_shouyue_longdan" or skill=="lxtx_yizan") then
        local products=skill=="lxtx_yizan" and {slash="Slash",jink="Jink",peach="Peach",analeptic="Analeptic"}
            or {slash="Slash",jink="Jink"}
        if products[spec.name] then audited[skill]={products[spec.name],spec.name} end
    end
    audited.soulfire={"FireSlash","fire_slash"}
    audited.miuyan={"FireAttack","fire_attack"}
    audited.huiyun={"FireAttack","fire_attack"}
    audited.zonglve={"Slash","slash"}
    local r49Products={fuzhai={ex_nihilo="ExNihilo",collateral="Collateral"},olquxi={dismantlement="Dismantlement",snatch="Snatch"}}
    local r49Product=r49Products[skill]
    if r49Product and type(spec)=="table" and r49Product[spec.name] then audited[skill]={r49Product[spec.name],spec.name} end
    audited.olhuoji={"FireAttack","fire_attack"}
    audited.ollianhuan={"IronChain","iron_chain"}
    audited.xiedou={"Duel","duel"}
    audited.oljiuchi={"Analeptic","analeptic"}
    audited.olduanliang={"SupplyShortage","supply_shortage"}
    audited.olluanji={"ArcheryAttack","archery_attack"}
    audited.mouluanji={"ArcheryAttack","archery_attack"}
    audited.keolshuangxiong={"Duel","duel"}
    -- Fixed tenyear_hc returned ordinary products. Intermediate source clones
    -- remain readonly; selected provider/face/cost checks are unchanged.
    local hc49Products={tenyearjinggong={"Slash","slash"},kanpodz={"Slash","slash"},
        qiaoli={"Duel","duel"},jibing={"Slash","slash"},
        tenyearlingyin={"Duel","duel"},spniluan={"Slash","slash"}}
    local hc49Product=hc49Products[skill]
    if hc49Product then audited[skill]=hc49Product end
    -- The two fixed current-name records select their literal clone name. The
    -- native readonly authorizer independently rechecks that record and cost.
    if (skill=="jingong"or skill=="tenyearjingong")and type(spec)=="table"then
        local names=self.player:getPropertyValue(skill.."_tricks")
        if type(names)=="string"and type(class_name)=="string"then
            for _,name in ipairs(names:split("+"))do if name==spec.name then hc49Product={class_name,name};audited[skill]=hc49Product;break end end
        end
    end
    if skill=="hfgushi" and type(spec)=="table" then
        local names={peach="Peach",ex_nihilo="ExNihilo",duel="Duel"}
        if names[spec.name] then audited.hfgushi={names[spec.name],spec.name} end
    end
    audited.qhstandardqixi={"Dismantlement","dismantlement"}
    local qh49Products={qhfirelianhuan={thunder_slash="ThunderSlash",iron_chain="IronChain"},
        qhfireshuangxiong={duel="Duel",slash="Slash"},
        qhwindguhuo={ex_nihilo="ExNihilo",snatch="Snatch",peach="Peach",slash="Slash",
            archery_attack="ArcheryAttack",savage_assault="SavageAssault",dismantlement="Dismantlement",fire_attack="FireAttack"}}
    local qh49=qh49Products[skill]
    if qh49 and type(spec)=="table" and qh49[spec.name] then audited[skill]={qh49[spec.name],spec.name} end
    audited.oljiushi={"Analeptic","analeptic"}
    audited.heg_duoshi_flamemap={"AwaitExhausted","await_exhausted"}
    audited.heg_wusheng_xh={"Slash","slash"}
    audited.heg_longdan_xh={"Slash","slash"}
    audited.heg_duanliang_egf={"SupplyShortage","supply_shortage"}
    audited.sr_sheji={"Slash","slash"}
    if skill=="sr_hemouvs" and type(spec)=="table" then
        local products={duel="Duel",collateral="Collateral",snatch="Snatch",fire_attack="FireAttack"}
        if products[spec.name] then audited.sr_hemouvs={products[spec.name],spec.name} end
    end
    if skill=="ollongdan" and type(spec)=="table" then
        local products={slash="Slash",peach="Peach",analeptic="Analeptic"}
        if products[spec.name] then audited.ollongdan={products[spec.name],spec.name} end
    end
    if type(spec)=="table" then
        local products=skill=="heg_guishu" and {known_both="KnownBoth",befriend_attacking="BefriendAttacking"}
            or skill=="mumeng" and {befriend_attacking="BefriendAttacking"}
            or skill=="_heg_zhenxi" and {indulgence="Indulgence",supply_shortage="SupplyShortage"}
        if products and products[spec.name] then audited[skill]={products[spec.name],spec.name} end
    end
    local r45_turn={keolkenshang=true,keolyilie=true,moujiang=true,mobilexiaoni=true,keolweilin=true}
    local r45_product=r45_turn[skill] and type(spec)=="table" and {class_name,spec.name} or nil
    if r45_product then audited[skill]=r45_product end
    local r41_products={f_luanshe={"ArcheryAttack","archery_attack"},
        sp_taoyuanyi={"GodSalvation","god_salvation"},sp_qianlixing={"Slash","slash"},
        sp_hengsaoqianjun={"Slash","slash"}}
    local r41_product=r41_products[skill]
    if r41_product then audited[skill]=r41_product end
    -- Fixed Maotu/Yinhu names/materials are independently bounded by the
    -- native readonly constructor; these entries never mint selected authority.
    local r49my=(skill=="mtzhihe" or skill=="yhduwei" or skill=="yhxinghan")
    if r49my and type(spec)=="table" then
        if skill~="yhxinghan" or (class_name=="Slash" and spec.name=="slash") then audited[skill]={class_name,spec.name} end
    end
    local product=audited[skill]
    if skill=="DIT_duoshi" then product={"Slash","slash"} end
    if skill=="jinpozhu" then product={"Chuqibuyi","chuqibuyi"} end
    if skill=="jiuxian" then product={"Analeptic","analeptic"} end
    if skill=="MeowQingguo" then product={"Peach","peach"} end
    if skill=="zuzhanding" then product={"Slash","slash"} end
    if skill=="jiejiu" and type(spec)=="table" then product={class_name,spec.name} end
    -- Dynamic name is bounded by the native current disclosed LastId source,
    -- not an arbitrary declaration catalogue. Final selection still uses V2.
    if skill=="GodYouhua" and type(spec)=="table" then product={class_name,spec.name} end
    if skill=="kezujiexuan" and type(spec)=="table" then
        if spec.name=="snatch" then product={"Snatch","snatch"}
        elseif spec.name=="dismantlement" then product={"Dismantlement","dismantlement"} end
    end
    local overseasProducts={
        ov_sidai={slash="Slash"},ov_jiange={slash="Slash"},
        ov_chaofeng={slash="Slash",fire_slash="FireSlash",thunder_slash="ThunderSlash",ice_slash="IceSlash",yj_stabs_slash="Slash"},
        ov_lihuo={fire_slash="FireSlash"},ov_juexing={duel="Duel"},ov_liyuan={slash="Slash"},
        ov_cairu={fire_attack="FireAttack",iron_chain="IronChain",ex_nihilo="ExNihilo"},
        ov_xijun={slash="Slash",duel="Duel"},
    }
    local overseas=overseasProducts[skill]
    if skill=="ov_bimeng" and type(spec)=="table" then
        local declared=false
        for _,name in ipairs(AICardCatalog.patternNames() or{})do if name==spec.name then declared=true end end
        if declared then overseas={[spec.name]=class_name} end
    end
    if overseas and type(spec)=="table" and overseas[spec.name]==class_name then product={class_name,spec.name} end
    local source_skill=skill=="cihuai" and "_cihuai" or skill=="lxtx_zhangwu" and "lxtx_zhangwuu" or skill=="ov_lihuo" and "mobilelihuo" or skill
    local valid_costs=type(spec)=="table" and AIValue.isList(spec.subcards)
    if valid_costs then
        local count=#spec.subcards
        if skill=="hfgushi" then valid_costs=count==0
        elseif skill=="xiedou" then valid_costs=count>0
        elseif skill=="mtzhihe" then valid_costs=count>=1 and count<=4
        elseif r45_product then valid_costs=(skill=="keolkenshang" and count>=2 and count<=999)
            or (skill=="moujiang" and count>=1 and count<=999)
            or (skill=="keolyilie" and count==2)
            or ((skill=="mobilexiaoni" or skill=="keolweilin") and count==1)
        elseif r41_product then valid_costs=skill=="f_luanshe" and count>=1 and count<=999
            or skill=="sp_hengsaoqianjun" and count==2
            or (skill=="sp_qianlixing" or skill=="sp_taoyuanyi") and count==1
        elseif overseas then valid_costs=(skill=="ov_sidai" or skill=="ov_bimeng") and count>=0 and count<=256 or skill=="ov_cairu" and count==2 or skill=="ov_juexing" and count==0 or (skill~="ov_sidai" and skill~="ov_bimeng" and skill~="ov_cairu" and skill~="ov_juexing" and count==1)
        elseif skill=="zhanjue" or skill=="olzhanjue" then valid_costs=count>0
        elseif skill=="newlonghun" then valid_costs=count==1 or spec.name=="fire_slash" and count==2
        elseif skill=="lxtx_zhangwu" then valid_costs=count>0 and count<=128
        elseif skill=="lxtx_yizan" then valid_costs=count==1 or count==2
        else valid_costs=count==((skill=="DIT_duoshi" or skill=="olluanji" or skill=="mouluanji") and 2 or (skill=="oljiushi" or skill=="cihuai") and 0 or 1) end
    end
    if not product or class_name~=product[1] or type(spec)~="table"
        or getmetatable(spec)~=nil or spec.name~=product[2] or spec.skill~=source_skill
        or not valid_costs then
        ai_unsupported("turn hypothesis is outside the audited source catalog","turn_conversion")
    end
    local allowed={name=true,skill=true,suit=true,number=true,subcards=true}
    if skill=="ov_cairu" or r49Product then
        if spec.can_recast~=false then ai_unsupported("audited source disables recast","turn_conversion")end
        allowed.can_recast=true
    end
    for key in pairs(spec) do if not allowed[key] then ai_unsupported("turn hypothesis has an unexpected field",tostring(key)) end end
    local stamp,source=turn_snapshot(self),turn_source(request)
    local exact=copy_value(spec)
    local native=copy_value(exact);native.source_key=(skill=="mouluanji" or skill=="keolshuangxiong" or r45_product) and "newgenerals."..skill or r41_product and "fcDIY."..skill or skill
    local card=turn_checked(self:evaluateOwnerViewAsCard(native),"turn_conversion")
    if not AIValue.isCard(card) or card:getClassName()~=class_name
        or type(((skill=="LuaYanjiu" or skill=="jieyou" or skill=="oljiuchi" or skill=="jiuchi") and {card._view.source_analeptic_available} or {card._view.available})[1])~="boolean"
        or type(card:getLegacyIdentityToken())~="string"
        or type(card:getLegacyStringKey())~="string" or type(card:getLegacySortKey())~="string" then
        ai_unsupported("readonly Dan clone lacks its source availability or identity","turn_conversion")
    end
    local entries=readonly_turn_cards[self]
    if not entries then entries=setmetatable({}, {__mode="k"});readonly_turn_cards[self]=entries end
    -- Zuzhanding constructs NoSuit/0, then Card derives its face from the
    -- selected material. Bind precisely that observed face; final comparison
    -- still checks every native face, cost, skill and printing field.
    if skill=="jijiu" or skill=="nosguose" or skill=="fan" or skill=="touzhi" or skill=="zuzhanding" or skill=="lxtx_zhangwu" or skill=="peiniang" or skill=="zhifeng" or skill=="godlongnu" or overseas or r41_product or r45_product or skill=="mouluanji" or skill=="keolshuangxiong" or r49Product or skill=="miuyan" or skill=="huiyun" or skill=="zonglve" or skill=="newlonghun" or skill=="gdlonghun" or skill=="zhanjue" or skill=="olzhanjue" or skill=="qhstandardqixi" or r49my or skill=="soulfire" or hc49Product then exact.suit,exact.number=card:getSuit(),card:getNumber() end
    -- can_recast is readonly source state, not an action-spec field. The sealed
    -- face comparison below still requires the real provider product to match.
    if skill=="ov_cairu" or r49Product then exact.can_recast=nil end
    entries[card]={skill=skill,class_name=class_name,spec=exact,request=self.request,stamp=stamp,
        source=source,skill_request=request,face=copy_value(card._view),candidate=copy_value(card._evaluation_candidate),
        available=((skill=="LuaYanjiu" or skill=="jieyou" or skill=="oljiuchi" or skill=="jiuchi") and {card._view.source_analeptic_available} or {card._view.available})[1]}
    return card
end
-- Source SkillCard hypotheses share the sealed final-selection boundary with
-- conversions. Cost faces are visible metadata; they carry no action receipt.
local audited_skill_declarations = {
    mtjieli={ActiveSkillCard=true},
    ov_mouli={["#ov_mouliCard"]=true},ov_hanhong={["#ov_hanhongCard"]=true},
    heg_qice={HQiceCard=true},
    heg_yigui={HYiguiCard=true},
    olguhuo={OLGuhuoCard=true},
    inovation_fengzhu={InovationFengzhuCard=true},
    jinbingxin={JinBingxinCard=true},
    kezushengmo={["#kezushengmoCard"]=true},
    ["SevenJiujia"]={["#SevenJiujiaCard"]=true},
    ["chuifeng"]={["#chuifengCard"]=true},
    ["diy_k_shouli"]={["#diy_k_shouli"]=true},
    ["dunshi"]={["DunshiCard"]=true},
    ["huanpei"]={["HuanpeiCard"]=true},
    ["keolbixin"]={["#keolbixinCard"]=true},
    ["liangyuan"]={["#liangyuanCard"]=true},
    ["lucun"]={["LucunCard"]=true},
    ["nosjinwanyi"]={["#nosjinwanyi"]=true},
    ["ny_10th_huace"]={["#ny_10th_huace"]=true},
    ["ny_10th_zhaowen"]={["#ny_10th_zhaowen"]=true},
    ["ny_tenth_shizong"]={["#ny_tenth_shizong"]=true},
    ["ofyouchong"]={["#ofyouchongCard"]=true},
    ["ol2shanjia"]={["OL2ShanjiaCard"]=true},
    ["oljinjin"]={["OLJinjinCard"]=true},
    ["oljueyan"]={["OLJueyanCard"]=true},
    ["olspxixiang"]={["#olspxixiangCard"]=true},
    ["suyi"]={["SuyiCard"]=true},
    ["tc_zuoxing"]={["#tc_zuoxing"]=true},
    ["tyshouli"]={["#tyshouli"]=true},
    ["weijie"]={["WeijieCard"]=true},
    ["xdyifu"]={["#xdyifucard"]=true},
    ["xdyifuvs"]={["#xdyifucard"]=true},
    ["xiewei"]={["XieweiCard"]=true},
    ["xuanzhu"]={["XuanzhuCard"]=true},
    ["zonghu"]={["ZonghuCard"]=true},
    ["zuoxing"]={["#zuoxing"]=true},
}
function SmartAIView:evaluateTurnSkillCard(skill,class_name,costs,request,user_string)
    if type(skill)~="string" or type(class_name)~="string" or not AIValue.isList(costs)
        or (user_string~=nil and ((skill~="caozhao" and not (audited_skill_declarations[skill] and audited_skill_declarations[skill][class_name])) or type(user_string)~="string")) then
        ai_unsupported("readonly SkillCard is outside audited source vocabulary",skill)
    end
    local stamp,source=turn_snapshot(self),turn_source(request)
    local row=self:skillCardFace(skill,class_name,costs,request,user_string)
    local card=CardView.new(row)
    card._evaluation_candidate={card_id=-1,available=row.available,limited=false}
    card.getAuthorityCard=function()return nil end
    card.toCardSpec=function()ai_unsupported("readonly source SkillCard has no authority",skill)end
    local entries=readonly_turn_cards[self]
    if not entries then entries=setmetatable({}, {__mode="k"});readonly_turn_cards[self]=entries end
    entries[card]={skill=skill,class_name=class_name,binder="skill",costs=copy_value(costs),user_string=user_string,
        request=self.request,stamp=stamp,source=source,skill_request=request,
        face=copy_value(row),candidate=copy_value(card._evaluation_candidate),available=row.available}
    return card
end
function SmartAIView:legacySkillSeedWithCosts(skill,class_name,request,costs)
    return self:evaluateTurnSkillCard(skill,class_name,costs,request)
end
function PlayerView:canSlashWithoutCrossbow(slash)
    if slash~=nil then ai_unsupported("explicit Slash hypothesis is not projected","canSlashWithoutCrossbow") end
    if not self._room or self:objectName()~=self._room._world.self.object_name then
        ai_unsupported("canSlashWithoutCrossbow requires owner context","canSlashWithoutCrossbow")
    end
    return self._room._world.self.can_slash_without_crossbow
end
function SmartAIView:readonlyTurnConversionMatchesRequest(card,request)
    return turn_same(turn_saved(self,card).source,turn_source(request))
end
function SmartAIView:readonlyTurnAvailability(card)
    return turn_saved(self,card).available
end
function SmartAIView:materializeTurnSelectedCard(card)
    if self:getReadonlyPlayContext() then
        ai_unsupported("nested source planning cannot materialize an action","zuheta.planning")
    end
    local entry=turn_saved(self,card)
    if entry.failure then error(entry.failure,0) end
    if entry.authority then return entry.authority end
    local ok,result=pcall(function()
        local authority
        if entry.binder=="xuanzhu_raw" then
            return self:materializeXuanzhuFirst(card)
        elseif entry.binder=="xufa_raw" then
            return self:materializeXufaFirst(card)
        elseif entry.skill=="xiedou" then
            -- Fixed source Duel is replaced by ViewAsSkillV2::createCard in
            -- resolveCardSkillInstance. Keep its policy until selection; the
            -- selected native product has its own genuine class/face/authority.
            local source=entry.source
            if entry.class_name~="Duel" or entry.spec.name~="duel" or entry.spec.skill~="xiedou"
                or type(source)~="table" or source.activation_owner~=self.player:objectName()
                or source.activation_skill~="xiedou" or source.source_skill~="xiedou"
                or source.source_owner~=self.player:objectName() then
                ai_unsupported("Xiedou source identity changed","xiedou")
            end
            authority=turn_checked(self:bindSkillCard("xiedou",copy_value(entry.spec.subcards),entry.skill_request),"xiedou")
            turn_saved(self,card) -- A selected native query cannot drift this seal.
            if not AIValue.isConversion(authority) or authority:getClassName()~="ActiveSkillCard"
                or authority:getTypeId()~=0 or authority:getSkillName(false)~="xiedou"
                or not turn_same(authority:getSubcards(),entry.spec.subcards) then
                ai_unsupported("Xiedou selected V2 product changed","xiedou")
            end
            for field,method in pairs(turn_identity_methods) do
                if authority[method](authority)~=source[field] then
                    ai_unsupported("Xiedou selected source changed",field)
                end
            end
            return authority
        elseif entry.binder=="skill" then
            authority=turn_checked(self:bindSkillCard(entry.skill,copy_value(entry.costs),entry.skill_request,
                entry.user_string,entry.class_name),"turn_skill_card")
        elseif entry.skill=="cihuai" then
            -- Fixed smart-ai.lua insertAIFillCards attaches canonical activation
            -- and source refs to the raw _cihuai policy card before native use.
            local source=entry.source
            if type(source)~="table" or source.activation_owner~=self.player:objectName()
                or source.activation_skill~="cihuai" or type(source.activation_instance)~="number"
                or source.activation_instance<=0 or entry.class_name~="Slash"
                or entry.spec.name~="slash" or entry.spec.skill~="_cihuai"
                or entry.spec.suit~=sgs.Card_NoSuit or entry.spec.number~=0 or #entry.spec.subcards~=0 then
                ai_unsupported("Cihuai source lacks its exact fill activation identity","turn_conversion")
            end
            local native=copy_value(entry.spec);native.skill="cihuai"
            authority=turn_checked(self:bindTurnConversion("cihuai","Slash",native,entry.skill_request),"turn_conversion")
            if not AIValue.isConversion(authority) or authority:objectName()~="slash"
                or authority:getClassName()~="Slash" or authority:getSkillName(false)~="cihuai"
                or authority:getSuit()~=sgs.Card_NoSuit or authority:getNumber()~=0
                or #authority:getSubcards()~=0 then
                ai_unsupported("Cihuai native source product changed","turn_conversion")
            end
            for field,method in pairs(turn_identity_methods) do
                if authority[method](authority)~=source[field] then
                    ai_unsupported("Cihuai native source identity changed",field)
                end
            end
            authority=self:legacyPolicyCard(authority,{skill_name="_cihuai",
                skill_names=copy_value(card._view.skill_names),
                legacy_string_key=card:getLegacyStringKey(),legacy_sort_key=card:getLegacySortKey()},card)
        else
            authority=turn_checked(self:bindTurnConversion(entry.skill,entry.class_name,copy_value(entry.spec),entry.skill_request),"turn_conversion")
        end
        if not AIValue.isConversion(authority) or authority:objectName()~=card:objectName()
            or authority:getClassName()~=card:getClassName() or authority:getSkillName(false)~=card:getSkillName(false)
            or authority:getSuit()~=card:getSuit() or authority:getNumber()~=card:getNumber()
            or ((entry.skill=="ov_cairu" or entry.skill=="fuzhai" or entry.skill=="olquxi") and (card:canRecast()~=false or authority:canRecast()~=false))
            or not turn_same(authority:getSubcards(),card:getSubcards())
            or authority:getLegacyStringKey()~=card:getLegacyStringKey() or authority:getLegacySortKey()~=card:getLegacySortKey() then
            ai_unsupported("selected turn receipt changed its source product","turn_conversion")
        end
        return self:inheritLegacyCardIdentity(authority,card)
    end)
    if not ok then entry.failure=result;error(result,0) end
    entry.authority=result
    return result
end

local caokong_actual_cards=setmetatable({}, {__mode="k"})
-- Audited owner material simulations return policy facts without minting an action.
function SmartAIView:evaluateSkillCard(skill_name, name, costs)
    if type(ai_evaluate_skill_card) ~= "function" then ai_unsupported("native skill evaluation is unavailable",skill_name) end
    if not AIValue.isList(costs) then ai_unsupported("skill evaluation costs must be a list",skill_name) end
    local ids = {}
    for _,id in ipairs(costs) do ids[#ids+1] = id end
    local response = ai_evaluate_skill_card(skill_name,name,ids)
    if (skill_name=="tenyearbenxi:extra_collateral" or skill_name=="nyarz_zhishi" or skill_name=="nyarz_baguan"
        or skill_name=="ov_jinglve" or skill_name=="ov_gongxin"
        or skill_name=="use_revise:qiangxi" or skill_name=="use_revise:tiaoxin")
        and type(response)=="table" and response.exists==false then return nil end
    if type(response) ~= "table" or type(response.card) ~= "table" or type(response.candidate) ~= "table" then
        ai_unsupported(type(response)=="table" and response.error or "invalid readonly skill evaluation",skill_name)
    end
    local card = CardView.new(copy_value(response.card))
    if not card or not card:isEvaluationOnly() then ai_unsupported("skill evaluation was not marked readonly",skill_name) end
    card._evaluation_candidate = copy_value(response.candidate)
    if skill_name=='fcDIY_context:sp_hengsaoqianjun' or skill_name=='fcDIY_context:sp_lvezhen'
        or skill_name=='fcDIY_context:fcjielianhuan' or skill_name=='fcDIY_context:fcmoujiang' or skill_name=='newgenerals_context:moujiang' then
        local expected=skill_name=='fcDIY_context:sp_lvezhen' and 1
            or skill_name=='fcDIY_context:fcmoujiang' and math.min(turn_checked(self.player:getHp(),skill_name)-1,2) or 99
        local face=rawget(card,'_view');local candidate=rawget(card,'_evaluation_candidate')
        local marker=type(candidate)=='table' and candidate.readonly_source_queries
        if #ids~=0 or type(marker)~='table' or marker.source_key~=skill_name or marker.extra_target~=expected
            or candidate.complete_coverage~=false or type(face.readonly_recipe_key)~='string' or face.readonly_recipe_key==''
            or type(face.legacy_identity_token)~='string' or face.legacy_identity_token==''
            or card:objectName()~=name or face.evaluation_owner~=self.player:objectName() then
            ai_unsupported('FC actual-card readonly profile differs from its native source',skill_name)
        end
        local entries=qiuxin_source_cards[self]
        if not entries then entries=setmetatable({}, {__mode='k'});qiuxin_source_cards[self]=entries end
        entries[card]={request=self.request,source_key=skill_name,stamp=qiuxin_stamp(self,skill_name),
            face=copy_value(face),candidate=copy_value(candidate),recipe_key=face.readonly_recipe_key}
    end
    if skill_name=="luacaokong_context" then
        if card:isVirtualCard()~=false or type(card:getEffectiveId())~="number" or card:getEffectiveId()<0 then
            ai_unsupported("Caokong observation is not the actual physical card",skill_name)
        end
        caokong_actual_cards[card]={owner=self,id=card:getEffectiveId()}
    end
    return card
end

-- The printed face of a card is projected only where the card itself is visible.
function SmartAIView:getPrintedCardById(id)
    return self:getKnownCardById(id)
end

function CardView:getEquipSlot() return self._view.equip_slot end
ConversionView.getEquipSlot = CardView.getEquipSlot
function CardView:isSingleTargetCard() return self._view.single_target end
ConversionView.isSingleTargetCard = CardView.isSingleTargetCard
function CardView:getSubtype() return self._view.subtype end
ConversionView.getSubtype = CardView.getSubtype

function SmartAIView:legacyResponsePolicyCard(authority, row)
    if type(row) ~= "table" or row.type_id ~= 0 then error("invalid legacy response prototype") end
    local policy = {}
    for _, key in ipairs({"name","class_name","type_id","kind_of","name_length","legacy_string_key","legacy_sort_key",
        "subcards","suit","number","effective_id","damage_card","can_recast","handling_method","will_throw","red","black",
        "skill_name","skill_names"}) do policy[key] = row[key] end
    local result = self:legacyPolicyCard(authority,policy)
    for _, key in ipairs({"locked","jilei","using","target_fixed","subtype","evaluation_owner","evaluation_rules"}) do
        result._view[key] = copy_value(row[key])
    end
    return self:observeOlClanPolicyAllocation(result,true)
end

function CardView:nameLength()
    local n = self._view.name_length
    if type(n)=="number" and n>=0 and n%1==0 then return n end
end
ConversionView.nameLength = CardView.nameLength

function PlayerView:hasJudgeArea()
    local value=self._view.has_judge_area
    if type(value)=="boolean" then return value end
end
-- Player::getChangeSkillState: an unset or non-positive state reads as 1.
function PlayerView:getChangeSkillState(skill)
    local states=self._view.change_skill_states
    if type(states)~="table" then return nil end
    local n=states[skill]
    if type(n)~="number" or n<=0 then return 1 end
    return n
end

function CardView:isNDTrick()
    local trick, delayed = self:isKindOf("TrickCard"), self:isKindOf("DelayedTrick")
    if trick == false or delayed == true then return false end
    if trick == nil or delayed == nil then return nil end
    return true
end
ConversionView.isNDTrick = CardView.isNDTrick

function PlayerView:hasShownOneGeneral()
    local room = self._room
    local hegemony = room and AIHegemony.facts(room._world)
    local row = hegemony and hegemony.players[self:objectName()]
    if row then return row.shown_one end
end
function PlayerView:hasShownAllGenerals()
    local room=self._room
    local hegemony=room and AIHegemony.facts(room._world)
    local players=type(hegemony)=="table" and hegemony.players
    local row=type(players)=="table" and players[self:objectName()]
    if type(row)~="table" then return nil end
    local value=row.shown_all
    if type(value)=="boolean" then return value end
end
function PlayerView:isPublicHegemonyFriend(other)
    if not AIValue.isPlayer(other) then return nil end
    -- Both shown and the same public kingdom; careerists befriend nobody.
    local hegemony = self._room and AIHegemony.facts(self._room._world)
    local a = hegemony and hegemony.players[self:objectName()]
    local b = hegemony and hegemony.players[other:objectName()]
    if not a or not b then return nil end
    if not a.shown_one or not b.shown_one then return false end
    if a.public_careerist or b.public_careerist then return self:objectName() == other:objectName() end
    return a.public_kingdom ~= "" and a.public_kingdom == b.public_kingdom
end

-- Readonly native prefix test for an already-issued physical/conversion card.
function SmartAIView:cardTargetFilter(card, prefix, target)
    local qiuxin=qiuxin_entry(self,card)
    if qiuxin then
        if type(ai_qiuxin_target_filter)~='function' then ai_unsupported('Qiuxin prefix endpoint unavailable','targetFilter')end
        local names={};for _,p in ipairs(prefix or {})do names[#names+1]=p:objectName()end
        local result=ai_qiuxin_target_filter(qiuxin.recipe_key,names,target:objectName())
        if type(result)~='table' or type(result.accepted)~='boolean' then
            ai_unsupported(type(result)=='table' and result.error or 'Qiuxin prefix result unknown','targetFilter')
        end
        return result.accepted
    end
    if AIValue.isCard(card) and card:isEvaluationOnly()==true and #(prefix or {})==0 then
        local candidate=card._evaluation_candidate
        local values=type(candidate)=="table" and candidate.target_filter_empty
        local result=type(values)=="table" and values[target:objectName()]
        if type(result)~="boolean" then ai_unsupported("readonly empty-prefix target filter is unknown","targetFilter") end
        return result
    end
    -- An issued card, or an evaluation card with its own candidate, answers from
    -- complete legal combinations: the target may come next after this prefix.
    local issued = AIValue.isConversion(card) and card
        or AIValue.isCard(card) and (card:isEvaluationOnly() ~= true and self:getCardCandidate(card:getEffectiveId())
            or card:isEvaluationOnly() == true and self:getEvaluationCandidate(card))
    if issued and type(issued.hasCompleteCoverage) == "function" and issued:hasCompleteCoverage() == true then
        local selected = {}
        for _,p in ipairs(prefix or {}) do selected[#selected+1] = p:objectName() end
        local following = issued:getTargetSelection(AIList.new(selected))
        if following then
            for _,name in ipairs(following) do if name == target:objectName() then return true end end
            return false
        end
    end
    if type(ai_card_target_filter) ~= "function" then ai_unsupported("native target prefix query unavailable", "targetFilter") end
    local names = {}
    for _,p in ipairs(prefix or {}) do names[#names+1] = p:objectName() end
    local id
    if AIValue.isCard(card) and card:isEvaluationOnly()==true then
        local face=rawget(card,"_view")
        local observed=caokong_actual_cards[card]
        if observed and observed.owner==self then id=observed.id
        else
            id=type(face)=="table" and face.readonly_recipe_key
            if type(id)~="string" or id=="" then
                ai_unsupported("readonly target prefix needs a current native recipe","targetFilter")
            end
        end
    else
        id = card:getEffectiveId()
        if AIValue.isConversion(card) then id = -card:getConversionId() end
    end
    local result = ai_card_target_filter(id,names,target:objectName())
    if type(result) ~= "table" or type(result.accepted) ~= "boolean" then
        ai_unsupported(type(result)=="table" and result.error or "invalid native target prefix", "targetFilter")
    end
    return result.accepted
end
function SmartAIView:evaluateZenhuiCard()
    if type(ai_evaluate_zenhui_card) ~= "function" then ai_unsupported("native Zenhui evaluation unavailable","zenhui") end
    local result = ai_evaluate_zenhui_card()
    if type(result) ~= "table" or type(result.card) ~= "table" or type(result.candidate) ~= "table" then
        ai_unsupported(type(result)=="table" and result.error or "invalid Zenhui evaluation","zenhui")
    end
    local card = CardView.new(copy_value(result.card))
    card._evaluation_candidate = copy_value(result.candidate)
    return card
end

function SmartAIView:cardNoResponseNames(card)
    local authority = type(card.getAuthorityCard)=="function" and card:getAuthorityCard() or card
    local rule = projected_card_rule(self.player,authority)
    if type(rule)=="table" and AIValue.isList(rule.no_response) then return AIList.new(rule.no_response) end
    local rows = nil -- Per-card NoResponse tags are not projected.
    local names = type(rows)=="table" and rows[tostring(card:getEffectiveId())]
    return AIValue.isList(names) and AIList.new(names) or nil
end
function CardView:getTargetModDistance(player)
    local row
    if player then row=projected_card_rule(player,self) else row=self._view.evaluation_rules end
    return type(row)=="table" and row.target_mod_distance or nil
end
function CardView:getTargetModExtra(player)
    local row
    if player then row=projected_card_rule(player,self) else row=self._view.evaluation_rules end
    return type(row)=="table" and row.target_mod_extra or nil
end
ConversionView.getTargetModDistance=CardView.getTargetModDistance
ConversionView.getTargetModExtra=CardView.getTargetModExtra

-- Cross-question plan memory contains observations only. Rehydration never
-- reuses an issued ticket, candidate, request scope or hidden-card authority.
local prior_plan_observations=setmetatable({}, {__mode="k"})
function SmartAIView:capturePriorTurnPlan(card)
    local row={}
    for _,key in ipairs({"name","class_name","type_id","kind_of","suit","number",
        "skill_name","subcards","virtual_card","effective_id","legacy_identity_token",
        "legacy_string_key"}) do row[key]=copy_value(card._view[key]) end
    return row
end
function SmartAIView:restorePriorTurnPlan(row)
    if type(row)~="table" or not AIValue.isList(row.kind_of)
        or type(row.type_id)~="number" or type(row.virtual_card)~="boolean"
        or type(row.legacy_identity_token)~="string" then
        ai_unsupported("prior plan observation is incomplete","prior_turn_plan")
    end
    if not row.virtual_card then
        local current=self:getKnownCardById(row.effective_id)
        if current and current:getLegacyIdentityToken()==row.legacy_identity_token then return current end
        ai_unsupported("prior physical plan is no longer disclosed","prior_turn_plan")
    end
    local card=CardView.new(copy_value(row))
    card.toCardSpec=function()ai_unsupported("prior observation has no payment authority","prior_turn_plan")end
    local entries=prior_plan_observations[self]
    if not entries then entries=setmetatable({}, {__mode="k"});prior_plan_observations[self]=entries end
    entries[card]=copy_value(row)
    return card
end
function SmartAIView:resolvePriorTurnPlan(card)
    local entries=prior_plan_observations[self]
    local row=entries and entries[card]
    if not row then return card end
    if row.type_id==0 then ai_unsupported("prior SkillCard evaluation requires its current source scope","prior_turn_plan")end
    -- Native accepts only audited source products with currently disclosed,
    -- unchanged owner costs. Missing, foreign or stale material stays unknown.
    local current=self:evaluateOwnerViewAsCard({source_key=row.skill_name,skill=row.skill_name,
        name=row.name,suit=row.suit,number=row.number,subcards=copy_value(row.subcards)})
    if not current or current:getClassName()~=row.class_name
        or current:getLegacyStringKey()~=row.legacy_string_key then
        ai_unsupported("prior virtual plan printing changed","prior_turn_plan")
    end
    self:inheritLegacyCardIdentity(current,card)
    return current
end

function SmartAIView:addStrategyPlayerMark(player,name,amount)
    assert(AIValue.isPlayer(player) and (name=="yhpodi_to-PlayClear" or ((name=="AI_fangjian-Clear" or name=="AI_do_not_invoke_s2_longwei-Clear") and player:objectName()==self.player:objectName())) and amount==1,"unknown strategy mark")
    local epoch_key=name=="yhpodi_to-PlayClear" and "strategy_play_clear_epochs" or "strategy_turn_clear_epochs"
    local epochs=AIWorldLifecycle.epochs(self.world,epoch_key=="strategy_play_clear_epochs" and "play" or "turn")
    if type(epochs)~="table" or type(epochs[player:objectName()])~="number" then
        ai_unsupported("AI play mark requires native lifecycle witness","strategy_play_clear_epochs")
    end
    local policy=self.world.mode_policy
    if type(policy)~="table" or type(policy.strategy_marks)~="table" then ai_unsupported("strategy marks unavailable",name)end
    local value=player:getMark(name)
    if type(value)~="number" then ai_unsupported("initial play mark is unknown",name)end
    local id=player:objectName();policy.strategy_marks[id]=policy.strategy_marks[id] or {}
    policy.strategy_marks[id][name]=value+amount
    if self._strategy_evaluation then return end
    local effect={kind="strategy_mark",player=id,name=name,amount=amount}
    if self._event_effect_sink then self:emitStrategyEffect(effect);return end
    effect.after_delta=0;self._strategy_effects=self._strategy_effects or {}
    assert(#self._strategy_effects<64,"strategy effect limit")
    self._strategy_effects[#self._strategy_effects+1]=effect
end

-- Room.cpp6251 compares exact getAllPlayers(true) indices, including -1 for nil.
function RoomView:getFront(first,second)
    local a,b=-1,-1
    for i,p in ipairs(self:getAllPlayers(true)) do
        if p==first then a=i-1 end
        if p==second then b=i-1 end
    end
    if a<b then return first end
    return second
end


-- Card.cpp460 translates objectName, or className for an unnamed SkillCard.
function CardView:getName()
    local key=self:objectName()
    if key=="" then key=self:getClassName() end
    if type(key)~="string" or type(ai_translate_card_name)~="function" then
        ai_unsupported("public translated card name is unavailable","Card.getName")
    end
    return ai_translate_card_name(key)
end
ConversionView.getName=CardView.getName


-- Card.cpp473 defaults to removing exactly one leading underscore. Raw
-- printing remains available to receipt adapters through explicit false.
function CardView:getSkillName(removePrefix)
    local value=self._view.skill_name
    if type(value)~="string" then return nil end
    if removePrefix~=false and value:sub(1,1)=="_" then return value:sub(2) end
    return value
end
ConversionView.getSkillName=CardView.getSkillName

-- Public printed Skill metadata; absent projection remains unknown.
SkillView.isAttachedLordSkill=make_scalar_getter("attached_lord_skill")
function SmartAIView:translatePublicKey(key)
    if type(key)~="string" or type(ai_translate_card_name)~="function" then ai_unsupported("public translation unavailable",tostring(key))end
    return ai_translate_card_name(key)
end

-- Named public judgment hypotheses are values, never card-use authority. The
-- native question supplies exact construction faces and predicate outcomes.
function SmartAIView:getScopedJudge(row)
    if type(row)~="table" or (row.scope_key~="mouhongyan" and row.scope_key~="SixGuicai") then ai_unsupported("unknown named judgment", "getScopedJudge")end
    local judge=copy_value(row)
    judge.who=self.room:findPlayerByObjectName(row.who,true)
    judge.card=CardView.new(copy_value(row.card))
    if not judge.who or not judge.card then ai_unsupported("named judgment lacks public identity",row.scope_key)end
    function judge:cloneCandidate(suit,number)
        local key=tostring(suit)..":"..tostring(number)
        local face=type(self.readonly_candidates)=="table"and self.readonly_candidates[key]
        if type(face)~="table" then ai_unsupported("named judge constructor is not projected",key)end
        local card=CardView.new(copy_value(face))
        card._view.legacy_identity_token=fresh_policy_identity(policy_identity_scope(self._ai))
        return card
    end
    function judge:isGood(card)
        if card==nil then return self.good end
        local face=type(card)=="table"and rawget(card,"_view")
        if type(face)~="table"or face.named_judge_scope~=self.scope_key then ai_unsupported("unrelated card in named judge outcome",self.scope_key)end
        local value=type(self.candidate_outcomes)=="table"and self.candidate_outcomes[face.named_judge_key]
        if type(value)~="boolean"then ai_unsupported("named judge outcome is unknown",self.scope_key)end
        return value
    end
    function judge:isBad(card)return not self:isGood(card)end
    judge._ai=self
    return judge
end

-- Owner-only native range hypotheses. Profiles are query data, never action tickets.
local owner_range_states = setmetatable({}, {__mode="k"})
local owner_range_active_ai
local r44_card_owner=setmetatable({},{__mode="k"})
-- Only wrappers created here may attest their underlying provider. Entries live
-- for their lexical hypothesis scope; no name-based or upvalue inference.
local owner_range_providers=setmetatable({}, {__mode="k"})
function SmartAIView.isOwnerRangeProvider(self,name,provider,expected)
    if type(expected)~="function" or type(provider)~="function"
        or owner_range_active_ai~=self or self[name]~=provider then return false end
    local active=owner_range_states[self]
    if not active then return false end
    local live={}
    while active do live[active]=true;active=active.parent end
    local seen={}
    while provider~=expected do
        if seen[provider] then return false end
        seen[provider]=true
        local proof=owner_range_providers[provider]
        if not proof or proof.owner~=self or proof.name~=name or not live[proof.state] then return false end
        local state=proof.state
        local request=self.request
        if type(request)~="table" or request~=state.request or self.player~=state.player
            or request.viewer~=state.viewer or request.decision_id~=state.decision_id
            or request.state_revision~=state.state_revision then return false end
        provider=proof.underlying
    end
    return true
end
local function range_pack(...) return {n=select('#',...),...} end
local range_unpack = table.unpack or unpack
local function r44_current_state(ai)
    local state=owner_range_states[ai]
    if not state then return nil end
    if state.poisoned then ai_unsupported('owner range continuation is invalid','owner_range')end
    -- Ordinary R19 scopes remain lexical. R44 state may survive a source
    -- clear/error until this same decision ends, never beyond that boundary.
    if state.continuation or state.r44_live then
        local result=ai_evaluate_owner_range_card{session_current=true}
        local r=ai.request
        if type(result)~='table' or result.kind~='owner_range_session'
            or result.viewer~=r.viewer or result.decision_id~=r.decision_id
            or result.state_revision~=r.state_revision then
            ai_unsupported('owner range cached profile is outside its live native request','owner_range')
        end
    end
    return state
end
local function range_ai(player)
    local room=type(player)=="table" and rawget(player,"_room")
    local ai=room and room._ai
    return ai and ai.player==player and r44_current_state(ai) and ai or nil
end
local function range_spec(card)
    if not (AIValue.isCard(card) or AIValue.isConversion(card)) then
        ai_unsupported("range hypothesis requires a known card", "owner_range")
    end
    local row=rawget(card,"_view")
    if type(row)=="table" and type(row.readonly_recipe_key)=="string" and row.readonly_recipe_key~="" then
        return {recipe_key=row.readonly_recipe_key}
    end
    if card:isVirtualCard()==false then return {id=card:getEffectiveId()} end
    if type(row)~="table" or row.flags_complete~=true then
        ai_unsupported("range virtual card flags are incomplete", "owner_range")
    end
    local flags={}
    for flag,value in pairs(row.known_flags or {}) do if value==true then flags[#flags+1]=flag end end
    if AIValue.isList(row.flags) then
        for _,flag in ipairs(row.flags) do
            local found=false;for _,other in ipairs(flags) do if other==flag then found=true break end end
            if not found then flags[#flags+1]=flag end
        end
    end
    local recast=card:canRecast()
    if type(recast)~="boolean" then ai_unsupported("range recast metadata is unknown","owner_range") end
    return {name=card:objectName(),suit=card:getSuit(),number=card:getNumber(),
        rawskill=card:getSkillName(false),subcards=copy_value(sgs.QList2Table(card:getSubcards())),
        can_recast=recast,flags=flags}
end
local function range_profile(ai,card)
    local state=r44_current_state(ai)
    if not state then return nil end
    if state.poisoned then ai_unsupported('owner range continuation is invalid','owner_range')end
    r44_card_owner[card]=ai
    local qiuxin=qiuxin_entry(ai,card)
    local found=state.profiles[card]
    if found then
        if not qiuxin_same(found.face,card._view) then ai_unsupported('range card face changed in scope','owner_range') end
        if qiuxin and not qiuxin_same(found.candidate._view,found.row.candidate)then
            ai_unsupported('Qiuxin range candidate identity changed','qiuxin_profile')
        end
        return found
    end
    if type(ai_evaluate_owner_range_card)~="function" then ai_unsupported("native range card query unavailable","owner_range") end
    local spec=range_spec(card)
    local row=ai_evaluate_owner_range_card(spec)
    if type(row)~="table" or type(row.card)~="table" or type(row.card.evaluation_rules)~="table"
        or row.card.evaluation_owner~=ai.player:objectName() or type(row.candidate)~="table"
        or type(row.can_slash_map)~="table" then
        ai_unsupported(type(row)=="table" and row.error or "invalid native range card profile","owner_range")
    end
    if spec.recipe_key then
        local face=row.card
        if face.legacy_identity_token~=card:getLegacyIdentityToken()
            or face.legacy_string_key~=card:getLegacyStringKey()
            or face.can_recast~=card:canRecast() then
            ai_unsupported('range retained object identity/printing/recast changed','owner_range')
        end
        if face.name~=card:objectName() or face.class_name~=card:getClassName()
            or face.suit~=card:getSuit() or face.number~=card:getNumber()
            or face.skill_name~=card:getSkillName(false) or not AIValue.isList(face.subcards) then
            ai_unsupported("range recipe changed its issued public product","owner_range")
        end
        local costs=card:getSubcards()
        if not AIValue.isList(costs) or #costs~=#face.subcards then ai_unsupported("range recipe cost identity changed","owner_range") end
        for i,id in ipairs(costs) do if face.subcards[i]~=id then ai_unsupported("range recipe material order changed","owner_range") end end
    end
    local marker=row.candidate.readonly_source_queries
    local expected=({mouwusheng=99,sfofl_sitong=99,sfofl_qingjin=99,BearingDownBorder=99,['#sfofl_sixi']=1})[state.data.source_key]
    local rangeMarker=type(marker)=='table' and marker.source_key=='owner_range:'..state.data.source_key
    if rangeMarker then
        if not expected or marker.extra_target~=expected or row.candidate.complete_coverage~=false then
            ai_unsupported('range source extra-target profile changed','owner_range')
        end
    elseif expected then ai_unsupported('range source target overlay missing','owner_range') end
    if not rangeMarker and qiuxin_marker(row.candidate) then
        if not qiuxin or spec.recipe_key~=qiuxin.recipe_key or row.candidate.complete_coverage~=false
            or row.candidate.readonly_source_queries.source_key~=qiuxin.source_key then
            ai_unsupported('Qiuxin range query lacks its sealed source profile','qiuxin_profile')
        end
    elseif qiuxin then ai_unsupported('Qiuxin range profile lost its source target overlay','qiuxin_profile')end
    found={row=row,spec=spec,range_extra=rangeMarker and expected or nil,card=card,face=copy_value(card._view),candidate=CandidateView.new(copy_value(row.candidate))}
    state.profiles[card]=found
    return found
end
local range_base_residue=CardView.getTargetResidue
function CardView:getTargetResidue(target)
    local ai=owner_range_active_ai or r44_card_owner[self]
    if ai and owner_range_states[ai] then
        local rows=range_profile(ai,self).row.card.target_residue
        return type(rows)=="table" and rows[AIValue.isPlayer(target) and target:objectName() or target] or nil
    end
    return range_base_residue(self,target)
end
ConversionView.getTargetResidue=CardView.getTargetResidue
local base_projected_card_rule=projected_card_rule
projected_card_rule=function(player,card)
    local ai=range_ai(player)
    if ai then return range_profile(ai,card).row.card.evaluation_rules end
    return base_projected_card_rule(player,card)
end
local range_base_hasFlag=PlayerView.hasFlag
function PlayerView:hasFlag(flag)
    local ai=range_ai(self)
    if ai and (flag=="InfinityAttackRange" or flag=="slashNoDistanceLimit") then return owner_range_states[ai].data[flag] end
    return range_base_hasFlag(self,flag)
end
local range_base_attack=PlayerView.getAttackRange
function PlayerView:getAttackRange(include_weapon)
    local ai=range_ai(self)
    if ai then local data=owner_range_states[ai].data
        if include_weapon==false then return data.attack_range_without_weapon end
        return data.attack_range
    end
    return range_base_attack(self,include_weapon)
end
local range_base_distance=PlayerView.distanceTo
function PlayerView:distanceTo(other,fix)
    local ai=range_ai(self)
    if ai and owner_range_states[ai].data.distance_to then
        if fix~=nil and fix~=0 and fix~=1 and fix~=2 then ai_unsupported("distance fix is outside finite hypothesis","olqimou") end
        local name=type(other)=="string" and other or AIValue.isPlayer(other) and other:objectName()
        local data=owner_range_states[ai].data
        local value
        if fix==2 then
            ai_unsupported("distance fix 2 is not projected for a hypothetical range","olqimou")
        else
            value=(fix==1 and data.distance_fix_one or data.distance_to)[name]
        end
        if type(value)~="number" then ai_unsupported("owner distance target is not projected","olqimou") end
        return value
    end
    return range_base_distance(self,other,fix)
end
local range_base_inrange=PlayerView.inMyAttackRange
function PlayerView:inMyAttackRange(other,...)
    local ai=range_ai(self)
    if ai then
        if select('#',...)>0 and select(1,...)~=0 then ai_unsupported("nonzero range fix is not projected","owner_range") end
        if not AIValue.isPlayer(other) then return nil end
        return owner_range_states[ai].data.in_attack_range[other:objectName()]
    end
    return range_base_inrange(self,other,...)
end
local range_base_slash=PlayerView.canSlash
function PlayerView:canSlash(other,card,distance_limit,range_fix)
    local ai=range_ai(self)
    if ai then
        if not AIValue.isPlayer(other) then return nil end
        if other==self then return false end
        card=card or ai:getEvaluationCard("slash")
        local rows=range_profile(ai,card).row.can_slash_map[other:objectName()]
        if distance_limit==nil then distance_limit=true end
        if range_fix==nil then range_fix=0 end
        rows=type(rows)=="table" and rows[tostring(distance_limit)]
        local value=type(rows)=="table" and rows[tostring(range_fix)]
        if type(value)~="boolean" then
            local spec=copy_value(range_profile(ai,card).spec)
            spec.can_slash_target=other:objectName();spec.distance_limit=distance_limit;spec.range_fix=range_fix
            local result=ai_evaluate_owner_range_card(spec)
            value=type(result)=="table" and result.can_slash
            if type(value)~="boolean" then ai_unsupported("range Slash check is not projected","owner_range") end
        end
        return value
    end
    return range_base_slash(self,other,card,distance_limit,range_fix)
end
for _,name in ipairs({"isLocked","isJilei"}) do
    local previous=PlayerView[name]
    local key=name=="isLocked" and "locked" or "jilei"
    PlayerView[name]=function(self,card)
        local ai=range_ai(self)
        if ai then return range_profile(ai,card).row.card[key] end
        return previous(self,card)
    end
end
local range_base_eval=SmartAIView.getEvaluationCandidate
function SmartAIView:getEvaluationCandidate(card)
    if owner_range_states[self] then return range_profile(self,card).candidate end
    return range_base_eval(self,card)
end
local range_base_candidate=SmartAIView.getCardCandidate
function SmartAIView:getCardCandidate(id)
    if owner_range_states[self] then
        local card=id<0 and self:getConversion(-id) or self:getKnownCardById(id)
        if not card then ai_unsupported("range candidate card is unknown","owner_range") end
        return range_profile(self,card).candidate
    end
    return range_base_candidate(self,id)
end
local range_base_filter=SmartAIView.cardTargetFilter
function SmartAIView:cardTargetFilter(card,prefix,target)
    if owner_range_states[self] then
        local p=range_profile(self,card)
        if #(prefix or {})==0 then
            local value=p.row.candidate.target_filter_empty
            value=type(value)=="table" and value[target:objectName()]
            if type(value)=="boolean" then return value end
        end
        local spec=copy_value(p.spec);spec.target_prefix={};spec.target=target:objectName()
        for _,player in ipairs(prefix or {}) do spec.target_prefix[#spec.target_prefix+1]=player:objectName() end
        local result=ai_evaluate_owner_range_card(spec)
        if type(result)~="table" or type(result.target_filter)~="boolean" then
            ai_unsupported(type(result)=="table" and result.error or "range target prefix is unknown","owner_range")
        end
        return result.target_filter
    end
    return range_base_filter(self,card,prefix,target)
end
local r44_extra_base=SmartAIView.isAuditedExtra99SourceQueryPlan
function SmartAIView:isAuditedExtra99SourceQueryPlan(card,use)
    local state=owner_range_states[self]
    if state then
        local profile=range_profile(self,card)
        if profile.range_extra then
            return type(use)=='table' and use.isDummy==true and use.extra_target==profile.range_extra
        end
    end
    return r44_extra_base(self,card,use)
end
SmartAIView.isQiuxinSourceQueryPlan=SmartAIView.isAuditedExtra99SourceQueryPlan
function SmartAIView:writeOwnerRangeQinggang(card,enabled)
    local state=owner_range_states[self]
    if not state or state.data.source_key~='@@f_yonghunSlash' or not AIValue.isCard(card)
        or card:isVirtualCard()~=false or type(enabled)~='boolean' then
        ai_unsupported('Qinggang write outside its exact source scope','owner_range.Qinggang')
    end
    local id=card:getEffectiveId()
    local result=ai_evaluate_owner_range_card{id=id,card_flag='Qinggang',enabled=enabled}
    if type(result)~='table' or result.kind~='owner_range_card_flag' or result.id~=id
        or result.enabled~=enabled or result.viewer~=self.request.viewer
        or result.decision_id~=self.request.decision_id or result.state_revision~=self.request.state_revision then
        ai_unsupported(type(result)=='table'and result.error or'Qinggang writer result invalid','owner_range.Qinggang')
    end
    card._view.known_flags=copy_value(card._view.known_flags or{})
    card._view.known_flags.Qinggang=enabled
    state.profiles[card]=nil
    self:setStrategyCardFlag(card,'Qinggang',enabled)
end
local r44_live_source_keys={['GodShijun']=true,['kejieshengzhuihun']=true,['mouwusheng']=true,['@mouxianchou-slash']=true,['@@f_yonghunSlash']=true,['BearingDownBorder']=true,['@sfofl_bearing_down_border']=true,['sfofl_jubing']=true,['@@sfofl_qifeng']=true,['shenghua']=true,['shijun']=true,['@@luazhuixi']=true,['@@luayonglue']=true,['@PlusZhongyong']=true,['SixQiaoxie']=true,['#sfofl_shuangren']=true,['sfofl_sitong']=true,['sfofl_jiaozheng']=true,['sfofl_qingjin']=true,['#sfofl_zainei']=true,['#sfofl_sixi']=true,['sfofl_juedou']=true}
local function with_owner_range(self,flag,source_key,closure,invoke)
    if type(closure)~="function" then ai_unsupported("owner hypothesis callback unavailable","owner_range") end
    return invoke(function(data)
        if type(data)~="table" or data.kind~="owner_range_hypothesis" or data.viewer~=self.player:objectName()
            or data.flag~=flag or data.source_key~=source_key or type(data.in_attack_range)~="table"
            or type(data.InfinityAttackRange)~="boolean" or type(data.slashNoDistanceLimit)~="boolean"
            or type(data.attack_range)~="number" or type(data.attack_range_without_weapon)~="number" then
            ai_unsupported("invalid owner range scope projection","owner_range")
        end
        local previous=owner_range_states[self]
        local old_active_ai=owner_range_active_ai
        owner_range_active_ai=self
        local old_eval=rawget(self,"_evaluation_scope")
        local saved={}
        local request=self.request
        local state={data=data,profiles=setmetatable({},{__mode="k"}),parent=previous,
            request=request,player=self.player,viewer=request and request.viewer,
            decision_id=request and request.decision_id,state_revision=request and request.state_revision}
        owner_range_states[self]=state
        state.r44_live=r44_live_source_keys[source_key]==true
        local created={}
        self._evaluation_scope=nil
        -- Instance dispatch keeps the original planner (including void methods).
        for _,name in ipairs({"aiUseCard","useBasicCard","useTrickCard","useEquipCard","useCardSlash"}) do
            local method=self[name]
            if type(method)=="function" then
                saved[name]={rawget(self,name)}
                local wrapper=function(ai,card,...)
                    local prior=rawget(ai,"_evaluation_scope")
                    local profile=range_profile(ai,card)
                    ai._evaluation_scope={card=card,candidate=profile.candidate}
                    local result=range_pack(pcall(method,ai,card,...))
                    ai._evaluation_scope=prior
                    if not result[1] then error(result[2],0) end
                    return range_unpack(result,2,result.n)
                end
                owner_range_providers[wrapper]={owner=self,state=state,name=name,underlying=method}
                created[#created+1]=wrapper
                self[name]=wrapper
            end
        end
        local result=range_pack(pcall(closure))
        for _,wrapper in ipairs(created) do owner_range_providers[wrapper]=nil end
        for name,value in pairs(saved) do self[name]=value[1] end
        self._evaluation_scope=old_eval
        owner_range_states[self]=previous
        owner_range_active_ai=old_active_ai
        if not result[1] then error(result[2],0) end
        return range_unpack(result,2,result.n)
    end)
end
local r44_sources={InfinityAttackRange={GodShijun=true,kejieshengzhuihun=true,mouwusheng=true,
    ['@mouxianchou-slash']=true,['@@f_yonghunSlash']=true,BearingDownBorder=true,
    ['@sfofl_bearing_down_border']=true,sfofl_jubing=true,['@@sfofl_qifeng']=true},
    slashNoDistanceLimit={shenghua=true,shijun=true,['@@luazhuixi']=true,['@@luayonglue']=true,
    ['@PlusZhongyong']=true,SixQiaoxie=true,['#sfofl_shuangren']=true,sfofl_sitong=true,
    sfofl_jiaozheng=true,sfofl_qingjin=true,['#sfofl_zainei']=true,['#sfofl_sixi']=true,sfofl_juedou=true}}
local function r44_refresh(self)
    local data=ai_evaluate_owner_range_card{owner_state=true}
    if type(data)~='table' or data.kind~='owner_range_hypothesis' or data.viewer~=self.player:objectName()
        or type(data.in_attack_range)~='table' or type(data.InfinityAttackRange)~='boolean'
        or type(data.slashNoDistanceLimit)~='boolean' or type(data.attack_range)~='number'
        or type(data.attack_range_without_weapon)~='number' or type(data.source_key)~='string' then
        ai_unsupported(type(data)=='table'and data.error or'owner range continuation unavailable','owner_range')
    end
    local state=owner_range_states[self]
    if not state then
        local request=self.request
        state={request=request,player=self.player,viewer=request.viewer,decision_id=request.decision_id,
            state_revision=request.state_revision,continuation=true}
        owner_range_states[self]=state
    end
    local current=state
    while current do
        current.continuation=true;current.data=copy_value(data);current.profiles=setmetatable({},{__mode='k'});current.poisoned=nil
        -- The native current frame authenticates only the innermost source.
        -- Parent scopes are refreshed again when they resume.
        current=current.parent
    end
    local evaluation=rawget(self,'_evaluation_scope')
    if evaluation and evaluation.card then evaluation.candidate=range_profile(self,evaluation.card).candidate end
end
function SmartAIView:withOwnerRange(flag,source_key,closure)
    if type(ai_with_owner_range)~="function" then ai_unsupported("native owner range scope unavailable","owner_range") end
    local finite=r44_sources[flag] and r44_sources[flag][source_key]
    local result=range_pack(pcall(with_owner_range,self,flag,source_key,closure,function(callback)
        if finite then return ai_with_owner_range(flag,source_key,callback,closure)end
        return ai_with_owner_range(flag,source_key,callback)
    end))
    if finite then
        -- C++ has already performed the actual source clear on normal return,
        -- or retained the reached true prefix on error. Reflect that state even
        -- when an outer source pcall catches the error. No Lua state restamp.
        local synced=range_pack(pcall(r44_refresh,self))
        if not synced[1] then
            local old=owner_range_states[self]
            owner_range_states[self]={poisoned=true,data={},profiles={},parent=old}
            if result[1] then error(synced[2],0)end
        end
    end
    if r45_physical.refresh then
        local refreshed=range_pack(pcall(r45_physical.refresh,self))
        if not refreshed[1] and result[1] then error(refreshed[2],0)end
    end
    if not result[1] then error(result[2],0)end
    return range_unpack(result,2,result.n)
end

function SmartAIView:withOwnerDistanceAdjustment(source_key,delta,closure)
    if source_key~="olqimou" or type(delta)~="number" or delta%1~=0 or delta>=0
        or type(ai_with_owner_distance)~="function" then
        ai_unsupported("finite owner distance hypothesis unavailable","olqimou")
    end
    local result=range_pack(pcall(with_owner_range,self,"olqimou_distance",source_key,closure,function(callback)
        return ai_with_owner_distance(source_key,delta,function(data)
            if type(data)~="table" or data.distance_delta~=delta or type(data.distance_to)~="table"
                or type(data.distance_fix_one)~="table" then ai_unsupported("distance projection is incomplete","olqimou") end
            return callback(data)
        end)
    end))
    if r45_physical.refresh then
        local refreshed=range_pack(pcall(r45_physical.refresh,self))
        if not refreshed[1] and result[1] then error(refreshed[2],0)end
    end
    if not result[1] then error(result[2],0)end
    return range_unpack(result,2,result.n)
end
function SmartAIView:aiUseCardWithOwnerFlag(card,use,flag,source_key)
    return self:withOwnerRange(flag,source_key,function() return self:aiUseCard(card,use) end)
end

-- A producer may select a material without placing it in product.subcards.
-- Such selection is validated independently; an empty-cost receipt is not proof
-- that an arbitrary material was selected lawfully.
function SmartAIView:bindSelectedMaterialConversion(skill,class_name,spec,selected_ids,request)
    if type(spec)~="table" or getmetatable(spec)~=nil or not AIValue.isList(selected_ids)
        or #selected_ids<1 or #selected_ids>128 or type(ai_resolve_conversion)~="function" then
        ai_unsupported("selected material conversion input is unavailable",skill)
    end
    local fields={name=true,skill=true,suit=true,number=true,subcards=true}
    for key in pairs(spec) do if not fields[key] then ai_unsupported("unexpected selected product field",key) end end
    if type(spec.name)~="string" or type(spec.skill)~="string" or type(spec.suit)~="number"
        or type(spec.number)~="number" or not AIValue.isList(spec.subcards) or #spec.subcards~=0 then
        ai_unsupported("nonconsuming conversion must have an explicit empty product cost",skill)
    end
    local seen={}
    for _,id in ipairs(selected_ids) do
        if type(id)~="number" or id<0 or id%1~=0 or seen[id] then ai_unsupported("invalid selected material",skill) end
        seen[id]=true
    end
    local methods={activation_owner="getActivationOwner",activation_skill="getActivationSkillName",
        activation_instance="getActivationInstanceId",source_owner="getSourceOwner",
        source_skill="getSourceSkillName",source_instance="getSourceInstanceID"}
    local policy=self:getConversionPolicy(class_name)
    if type(policy)~="table" or not AIValue.isList(policy.skills) then ai_unsupported("selected material scope is unavailable",skill) end
    local selected
    for _,row in ipairs(policy.skills) do
        local identity=row.play_identity
        if type(identity)=="table" and identity.activation_owner==self.player:objectName() then
            local matches=request~=nil or row.skill_name==skill
            for field,method in pairs(methods) do
                if identity[field]==nil then matches=false end
                if request then
                    local getter=request[method]
                    if type(getter)~="function" or getter(request)~=identity[field] then matches=false end
                end
            end
            if matches then
                if selected then ai_unsupported("selected material source is ambiguous",skill) end
                if type(row.play_scope_id)~="number" or row.play_request==nil then ai_unsupported("selected material Play scope is incomplete",skill) end
                selected=row
            end
        end
    end
    if not selected then ai_unsupported("selected material conversion has no exact source scope",skill) end
    local result=ai_resolve_conversion(class_name,selected.play_scope_id,copy_value(spec),copy_value(sgs.QList2Table(selected_ids)))
    if AIUnsupported.is(result) then error(result,0) end
    if type(result)~="table" or result.error then
        local signal=AIUnsupported.new(type(result)=="table" and result.error or "invalid selected material result",skill)
        if type(result)=="table" and result.native_rejected==true then signal.native_rejected=true;signal.terminal_response_selection=true end
        error(signal,0)
    end
    local card=self:registerResolvedConversion(result,selected.play_identity)
    if not card or card:objectName()~=spec.name or card:getSuit()~=spec.suit or card:getNumber()~=spec.number
        or card:getSkillName(false)~=spec.skill or #card:getSubcards()~=0 then
        ai_unsupported("selected material result changed its source product",skill)
    end
    return card
end

local borrowed_preview_cards=setmetatable({},{__mode="k"})
local function preview_stamp(ai)
    if type(ai.request)~="table" or ai.request.viewer~=ai.player:objectName() then
        ai_unsupported("preview request viewer is unknown","preview")
    end
    local stamp={}
    for _,key in ipairs(turn_request_fields) do stamp[key]=ai.request[key] end
    return stamp
end
function SmartAIView:getPreviewCardEvaluation(id)
    if type(id)~="number" or id<0 or id%1~=0 or type(ai_evaluate_preview_card)~="function" then
        ai_unsupported("preview evaluation is unavailable","preview")
    end
    local stamp=preview_stamp(self)
    local row=ai_evaluate_preview_card(id)
    if type(row)~="table" or type(row.card)~="table" or type(row.candidate)~="table"
        or row.card.effective_id~=id or row.card.evaluation_only~=true or row.card.virtual_card~=false then
        ai_unsupported(type(row)=="table" and row.error or "invalid physical preview descriptor","preview")
    end
    local card=CardView.new(copy_value(row.card))
    card._evaluation_candidate=copy_value(row.candidate)
    card.getAuthorityCard=function()return nil end
    card.toCardSpec=function()ai_unsupported("preview has no card-spec authority","preview")end
    local entries=borrowed_preview_cards[self]
    if not entries then entries=setmetatable({},{__mode="k"});borrowed_preview_cards[self]=entries end
    entries[card]={request=self.request,stamp=stamp,face=copy_value(row.card),candidate=copy_value(row.candidate),id=id}
    return card
end
function SmartAIView:materializeBorrowedSelectedCard(card,targets,request)
    local entries=borrowed_preview_cards[self]
    local entry=entries and entries[card]
    if not entry or entry.request~=self.request or not turn_same(entry.stamp,preview_stamp(self))
        or not turn_same(entry.face,card._view) or not turn_same(entry.candidate,card._evaluation_candidate) then
        ai_unsupported("selected preview identity or request changed","preview")
    end
    local skill=({["@@caoduo"]="caoduo",["@@keolzhuri"]="keolzhuri",["@@keolsaoguslash"]="keolsaoguslash",["@@chuiti"]="chuiti",["@@boxuan"]="boxuan",["@@tanluan"]="tanluan"})[self.request.pattern]
    if not skill or type(ai_bind_preview_physical)~="function" then
        ai_unsupported("physical preview payment is outside Caoduo response","preview")
    end
    local scope=self:getNativeSkillActionScope(skill,request)
    if type(scope)~="table" or type(scope.scope_id)~="number" then ai_unsupported("Caoduo source scope is unknown","preview") end
    local result=ai_bind_preview_physical(scope.scope_id,entry.id)
    if AIUnsupported.is(result) then error(result,0) end
    if type(result)~="table" or result.accepted~=true or result.card_id~=entry.id then
        local signal=AIUnsupported.new(type(result)=="table" and result.error or "preview payment rejected","preview")
        if type(result)=="table" and result.native_rejected==true then signal.native_rejected=true;signal.terminal_response_selection=true end
        error(signal,0)
    end
    local physical=copy_value(entry.face)
    physical.evaluation_only=false
    return CardView.new(physical)
end

-- Proposed facade-only method; root owns the production facade. Mirrors
-- Player::isYourFriend, core/player.cpp3552, using only disclosed roles.
function PlayerView:isYourFriend(friend)
    if not AIValue.isPlayer(friend) then return nil end
    local own_role=self:getRole()
    if type(own_role)~="string" then return nil end
    if own_role=="renegade" then return self:objectName()==friend:objectName() end
    local other_role=friend:getRole()
    if type(other_role)~="string" then return nil end
    if other_role=="renegade" then return self:objectName()==friend:objectName() end
    if own_role=="" or other_role=="" then return false end
    return other_role:sub(1,1)==own_role:sub(1,1)
end

-- Finite selected boundary. Cached source policy is a proposal, never authority.
-- The raw _chuming source wire remains in the saved CardView. The true native
-- provider emits chuming; this explicit policy/authority distinction is audited.
function SmartAIView:bindChumingSelectedPlan(card)
    if self.request.kind~='use_card' or self.request.pattern~='@@chuming!'
        or not AIValue.isCard(card) or card:getSkillName(false)~='_chuming'
        or (card:objectName()~='collateral' and card:objectName()~='dismantlement') then
        ai_unsupported('cached Chuming plan is outside its exact source response','chuming')
    end
    local policy=self:getConversionPolicy(card:getClassName())
    local selected
    for _,row in ipairs(policy.skills or {})do
        if row.skill_name=='chuming' and type(row.scope_id)=='number' and type(row.identity)=='table' then
            if selected then ai_unsupported('Chuming response source is ambiguous','chuming')end
            selected=row
        end
    end
    if not selected then ai_unsupported('Chuming accepted response source is unavailable','chuming')end
    if type(ai_resolve_conversion)~='function' then ai_unsupported('Chuming response resolver unavailable','chuming')end
    local spec={name=card:objectName(),skill='chuming',suit=card:getSuit(),number=card:getNumber(),subcards=sgs.QList2Table(card:getSubcards())}
    local result=ai_resolve_conversion(selected.class_name,selected.scope_id,spec,{})
    local authority=self:registerResolvedConversion(result,selected.identity)
    if authority:objectName()~=spec.name or authority:getSuit()~=spec.suit or authority:getNumber()~=spec.number
        or authority:getSkillName(false)~='chuming' or #authority:getSubcards()~=#spec.subcards then
        ai_unsupported('Chuming authority differs from the selected policy face','chuming')
    end
    for i,id in ipairs(spec.subcards)do if authority:getSubcards()[i]~=id then ai_unsupported('Chuming authority changed selected materials','chuming')end end
    return authority
end

function SmartAIView:recordSrkillChoiceFlag(name,player,value)
    local context=self:getDecisionContext().round26_choice
    local witness=type(context)=='table' and context.flag_witness
    if not AIValue.isPlayer(player) or type(witness)~='table' or witness.player~=player:objectName()
        or witness.name~=name or witness.value~=value or self.request.kind~='choice'
        or witness.source_key~=(self.request.options or {}).reason then
        ai_unsupported('SR choice flag lacks native witness','srkill_choice_flag')
    end
    if self._strategy_evaluation then return end
    local flags=player._view.flags or {}
    local reflected={}
    for _,flag in ipairs(flags) do if flag~=name then reflected[#reflected+1]=flag end end
    if value then reflected[#reflected+1]=name end
    player._view.flags=reflected
    self._strategy_effects=self._strategy_effects or {}
    assert(#self._strategy_effects<64,'strategy effect limit')
    self._strategy_effects[#self._strategy_effects+1]={kind='srkill_choice_flag',source_key=witness.source_key,
        player=witness.player,name=name,value=value,after_delta=0}
end

-- Exact parent-response terminal, separate from readonly Play enumeration.
function SmartAIView:bindOverseasNiwoSelected(costs)
 local r=self.request;local ctx=self:getReadonlyPlayContext()
 if not ctx or ctx.source~='OverseasVersion.ov_niwo' or r.kind~='use_card'
  or r.pattern~='@@ov_niwo' or r.prompt~='ov_niwo0' or not AIValue.isList(costs)
  or #costs>998 or type(ai_bind_overseas_niwo_selected)~='function' then
  ai_unsupported('Niwo selected response requires its exact parent question','ov_niwo.selected')
 end
 local ids,seen={},{}
 for _,id in ipairs(costs)do
  if type(id)~='number'or id<0 or id%1~=0 or seen[id]then ai_unsupported('Niwo selected costs are invalid','ov_niwo.selected')end
  seen[id]=true;ids[#ids+1]=id
 end
 local result=ai_bind_overseas_niwo_selected(ids)
 if AIUnsupported.is(result)then error(result,0)end
 local t=type(result)=='table'and result.ticket
 if type(t)~='table'then return self:registerResolvedConversion(result)end
 if t.activation_owner~=r.viewer or t.source_owner~=r.viewer or t.activation_skill~='ov_niwo'
  or t.source_skill~='ov_niwo' or not AIValue.isList(t.subcards) or #t.subcards~=#ids then
  ai_unsupported('Niwo native receipt changed source or cost domain','ov_niwo.selected')
 end
 for i,id in ipairs(ids)do if t.subcards[i]~=id then ai_unsupported('Niwo native receipt changed ordered costs','ov_niwo.selected')end end
 local authority=self:registerResolvedConversion(result)
 local policy=result.legacy_policy
 if type(policy)~='table'or policy.legacy_selector~='#ov_niwoCard'or policy.class_name~='LuaSkillCard'or policy.type_id~=0 then
  ai_unsupported('Niwo exact source prototype missing from receipt','ov_niwo.selected')
 end
 return self:legacyResponsePolicyCard(authority,policy)
end

-- Finite R29 raw numeric registry continuity. No private foreign values are
-- returned; unknown provenance remains a typed refusal, including raw nil reads.
function SmartAIView:readOverseasPriority(key)
    if type(key)~='string' or type(ai_overseas_priority)~='function' then
        ai_unsupported('native priority continuity query unavailable','OverseasVersion.priority')
    end
    local row=ai_overseas_priority('read',key)
    if AIUnsupported.is(row)then error(row,0)end
    if type(row)~='table' or row.kind~='overseas_priority' then
        ai_unsupported(type(row)=='table'and row.error or'invalid priority result','OverseasVersion.priority')
    end
    if row.tracked==false then return false end
    local r=self.request
    if row.tracked~=true or row.key~=key or row.viewer~=r.viewer
        or row.decision_id~=r.decision_id or row.state_revision~=r.state_revision
        or row.known~=true or type(row.removed)~='boolean'
        or row.removed and row.value~=nil
        or not row.removed and (type(row.value)~='number' or row.value~=row.value or math.abs(row.value)==math.huge) then
        ai_unsupported(row.reason or'priority provenance is unavailable','OverseasVersion.priority:'..key)
    end
    return true,row.value,row.removed
end
function SmartAIView:writeOverseasPriority(key,value)
    if type(ai_overseas_priority)~='function' then ai_unsupported('native priority writer unavailable','OverseasVersion.priority')end
    local row=ai_overseas_priority('write',key,value)
    if AIUnsupported.is(row)then error(row,0)end
    if type(row)~='table'or row.kind~='overseas_priority'then
        ai_unsupported(type(row)=='table'and row.error or'invalid priority write','OverseasVersion.priority')
    end
    if row.tracked==false then return false end
    local r=self.request
    if row.tracked~=true or row.known~=true or row.key~=key or row.viewer~=r.viewer
        or row.decision_id~=r.decision_id or row.state_revision~=r.state_revision
        or row.removed~=(value==nil) or row.value~=value then
        ai_unsupported('priority write acknowledgement mismatch','OverseasVersion.priority:'..key)
    end
    return true
end
function SmartAIView:writeOverseasXiafengFlag(card,enabled)
    local r=self.request;local options=r.options or{}
    if r.kind~='skill_invoke'or options.reason~='ov_xiafeng' or type(enabled)~='boolean'
        or not AIValue.isCard(card) or card:isEvaluationOnly() or card:isVirtualCard()
        or type(ai_overseas_xiafeng_flag)~='function' then
        ai_unsupported('Xiafeng flag is not an owner physical source write','ov_xiafeng.card_flag')
    end
    local id=card:getEffectiveId()
    local row=ai_overseas_xiafeng_flag(id,enabled)
    if AIUnsupported.is(row)then error(row,0)end
    if type(row)~='table'or row.kind~='overseas_xiafeng_flag'or row.card_id~=id
        or row.enabled~=enabled or row.viewer~=r.viewer
        or row.decision_id~=r.decision_id or row.state_revision~=r.state_revision then
        ai_unsupported(type(row)=='table'and row.error or'Xiafeng flag write rejected','ov_xiafeng.card_flag')
    end
    self:setStrategyCardFlag(card,'AIGlobal_KillOff',enabled)
end

-- The draw pile's top card is hidden; its preview is not projected.
function SmartAIView:getShicaiPreviewEvaluation()
    ai_unsupported('Shicai top card is not projected','guandu_shicai')
end

-- SmartAI's getUseValue recursion guard; it only has to live for one decision.
function SmartAIView:getUseValueRecursionFlag()
    return rawget(self,'_use_value_recursion')==true
end
function SmartAIView:setUseValueRecursionFlag(value)
    if type(value)~='boolean' then ai_unsupported('valuation flag must be boolean','getUseValue') end
    self._use_value_recursion=value
end

-- Finite Original source diagnostics and offered-card class probes.
function SmartAIView:recordSourceWarning(message,source)
    if type(message)~='string'or type(source)~='string'or type(ai_original_source_warning)~='function'then
        ai_unsupported('source diagnostic sink unavailable',source)
    end
    if ai_original_source_warning(source,message)~=true then ai_unsupported('source diagnostic scope rejected',source)end
end
function SmartAIView:getOriginalGuanxingClone(name,suit,number)
    local request=self.request or{}
    local h=AIHegemony.facts(self.world)
    if request.kind~='guanxing'or not h or h.enabled~=true or h.original_overrides_loaded~=true then
        ai_unsupported('Original Guanxing clone requires its active question','Original Guanxing clone')
    end
    if suit==nil then suit=sgs.Card_SuitToBeDecided end
    if number==nil then number=-1 end
    local card=self:evaluateOwnerViewAsCard({source_key='original_guanxing',skill='',name=name,
        suit=suit,number=number,subcards={}})
    if not card then error('Original Hegemony cannot clone card: '..tostring(name),0)end
    return card
end

local function original_guanxing_shadow_host(value)
    if type(ai_original_guanxing_shadow)~='function'then ai_unsupported('Original Guanxing shadow host unavailable','willSkipPlayPhase')end
    local row
    if value==nil then row=ai_original_guanxing_shadow()else row=ai_original_guanxing_shadow(value)end
    if type(row)~='table'or getmetatable(row)~=nil or row.kind~='original_guanxing_shadow'
        or row.known~=true or type(row.value)~='boolean'or(value~=nil and row.value~=value)then
        ai_unsupported(type(row)=='table'and row.reason or'Original Guanxing shadow unknown','willSkipPlayPhase')
    end
    return row.value
end
function SmartAIView:readOriginalGuanxingShadow()
    if self._strategy_evaluation and type(self._original_guanxing_dummy)=='boolean'then
        return self._original_guanxing_dummy
    end
    return original_guanxing_shadow_host()
end
function SmartAIView:writeOriginalGuanxingShadow(value)
    assert(type(value)=='boolean','invalid Original Guanxing shadow')
    if self._strategy_evaluation then self._original_guanxing_dummy=value
    else original_guanxing_shadow_host(value)end
    local policy=self.world.mode_policy
    assert(type(policy)=='table'and type(policy.strategy_flags)=='table','strategy flags not projected')
    local name=self.player:objectName()
    policy.strategy_flags[name]=policy.strategy_flags[name]or{}
    policy.strategy_flags[name].willSkipPlayPhase=value
end

function PlayerView:getFormation()
    -- Hegemony formations are not projected.
    local row=nil
    if type(row)~='table'or row.known~=true or not AIValue.isList(row.names)
        or row.names[1]~=self:objectName()then
        ai_unsupported(type(row)=='table'and row.reason or'public formation is unavailable','getFormation')
    end
    local result={}
    for _,name in ipairs(row.names)do
        if type(name)~='string'then ai_unsupported('malformed public formation member','getFormation')end
        local p=self._room:findPlayerByObjectName(name,true)
        if not p then ai_unsupported('public formation member is outside roster','getFormation')end
        result[#result+1]=p
    end
    return AIList.new(result) -- Preserve source order and native duplicate predecessor.
end

-- Finite owner-only native shadow; source writes are not gameplay flag writes.
local function r36_kurou_host(value)
 if type(ai_original_kurou_shadow)~='function'then ai_unsupported('Original Kurou shadow host unavailable','Kurou_toDie')end
 local row;if value==nil then row=ai_original_kurou_shadow()else row=ai_original_kurou_shadow(value)end
 if type(row)~='table'or getmetatable(row)~=nil or row.kind~='original_kurou_shadow'or row.known~=true or type(row.value)~='boolean'or(value~=nil and row.value~=value)then
  ai_unsupported(type(row)=='table'and row.reason or'Original Kurou shadow unknown','Kurou_toDie')
 end
 return row.value
end
function SmartAIView:getOriginalKurouToDie()return r36_kurou_host()end
function SmartAIView:setOriginalKurouToDie(value)
 assert(type(value)=='boolean','Original Kurou shadow requires boolean')
 -- Reached source prefix remains written on both ordinary and typed errors.
 -- Unlike action authority, this private policy observation is not rolled back.
 return r36_kurou_host(value)
end

-- Fixed Original heg-standard_cards2411-2689 SD flag handoff. Pure private
-- handles; no concealed ID/face enters Lua. Native flags are never mutated.
do
local active=setmetatable({},{__mode='k'})
local handles=setmetatable({},{__mode='k'})
local answers=setmetatable({},{__mode='k'})
local function host(self,s)
 local h=self.world and AIHegemony.facts(self.world)
 if not h or h.enabled~=true or h.original_overrides_loaded~=true then ai_unsupported('Original SD provider admission missing','Original SD')end
 if type(ai_original_sd_choice)~='function'then ai_unsupported('Original SD finite host unavailable','Original SD')end
 local result=ai_original_sd_choice(s)
 if type(result)~='table'or result.kind~='original_sd_choice'or result.known~=true then
  ai_unsupported(type(result)=='table'and result.reason or'Original SD host result unknown','Original SD')
 end
 return result
end
function SmartAIView:withOriginalSDChoice(card,use,body)
 if type(body)~='function'or not(AIValue.isCard(card)or AIValue.isConversion(card))then ai_unsupported('Original SD source call shape invalid','Original SD')end
 local reason=card:objectName()
 if reason~='snatch'and reason~='dismantlement'then ai_unsupported('Original SD source class invalid','Original SD')end
 local view=card._view;local source
 if type(view)=='table'and type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then source={recipe_key=view.readonly_recipe_key}
 elseif AIValue.isCard(card)and not card:isVirtualCard()then source={id=card:getEffectiveId()}
 else ai_unsupported('Original SD source object lacks native retained/owner identity','Original SD')end
 local result=host(self,{op='enter',source=source,reason=reason})
 if type(result.scope)~='string'or result.scope==''then ai_unsupported('Original SD scope missing','Original SD')end
 local old=active[self];active[self]={scope=result.scope,reason=reason,use=use,request=self.request}
 local values=table.pack(pcall(body))
 active[self]=old
 -- Cleanup must not replace a prior ordinary/typed source error.
 local cleanup=table.pack(pcall(host,self,{op='leave',scope=result.scope}))
 if not values[1]then error(values[2],0)end
 if not cleanup[1]then error(cleanup[2],0)end
 return table.unpack(values,2,values.n)
end
function SmartAIView:hasOriginalSDPlanningScope()return active[self]~=nil end
function SmartAIView:originalSDHasSilverLion(target)
 if not AIValue.isPlayer(target)then ai_unsupported('Original SilverLion target malformed','Original SD')end
 local value=target:hasArmorEffect('SilverLion')
 if type(value)=='boolean'then return value end
 local scope=active[self]
 local proposal={op='silver_lion',target=target:objectName()}
 if scope then
  if scope.request~=self.request then ai_unsupported('Original SilverLion request changed','Original SD')end
  proposal.scope=scope.scope
 end
 local row=host(self,proposal)
 -- The extra proof only certifies this finite negative. It grants no general
 -- foreign armor predicate and cannot manufacture a positive value.
 if row.value~=false then ai_unsupported('Original SilverLion public absence unproved','Original SD')end
 return false
end
function SmartAIView:sampleOriginalSDRandom(target,flags)
 local scope=active[self]
 if not scope or scope.request~=self.request or not AIValue.isPlayer(target)then ai_unsupported('Original SD source sampling outside call tree','Original SD')end
 local row=host(self,{op='domain',scope=scope.scope,target=target:objectName(),flags=flags})
 if type(row.count)~='number'or row.count<0 or row.count%1~=0 or type(row.token)~='string'then ai_unsupported('Original SD source domain malformed','Original SD')end
 if row.count==0 then return nil end
 local ordinal=math.random(0,row.count-1)
 local avoid=false
 local armor=self:originalSDHasSilverLion(target)
 if armor then
  local enemy=self:isEnemy(target);if enemy==nil then ai_unsupported('Original target relation unknown','Original SD')end
  if enemy then local wounded=target:isWounded();if wounded==nil then ai_unsupported('Original wound state unknown','Original SD')end;avoid=wounded end
 end
 local result=host(self,{op='select',scope=scope.scope,token=row.token,ordinal=ordinal,avoid=avoid})
 if type(result.handle)~='string'or result.handle==''then ai_unsupported('Original SD selected handle missing','Original SD')end
 local handle={};handles[handle]={self=self,scope=scope,token=result.handle,target=target:objectName()};return handle
end
function SmartAIView:originalRandomHandCardSelection(target)
 local scope=active[self]
 if not scope or scope.request~=self.request or not AIValue.isPlayer(target)then ai_unsupported('Original native hand sample outside source scope','Original SD')end
 local row=host(self,{op='native_hand',scope=scope.scope,target=target:objectName()})
 if row.empty==true then return -1 end
 if type(row.handle)~='string'or row.handle==''then ai_unsupported('Original native hand sample receipt missing','Original SD')end
 local handle={};handles[handle]={self=self,scope=scope,token=row.handle,target=target:objectName()};return handle
end
function SmartAIView:rememberOriginalSDChoice(target,selection,reason)
 local scope=active[self]
 if not scope or scope.request~=self.request or reason~=scope.reason or not AIValue.isPlayer(target)then ai_unsupported('Original SD writer outside source scope','Original SD')end
 if scope.use and scope.use.isDummy then ai_unsupported('Original SD dummy attempted source flag write','Original SD')end
 local value=selection
 if type(value)=='table'then local h=handles[value];if not h or h.self~=self or h.scope~=scope or h.target~=target:objectName()then ai_unsupported('Original SD foreign/copied handle','Original SD')end;value=h.token end
 if type(value)~='number'and type(value)~='string'then ai_unsupported('Original SD selected material invalid','Original SD')end
 host(self,{op='write',scope=scope.scope,target=target:objectName(),reason=reason,selection=value})
end
function SmartAIView:readOriginalSDChoice(target,flags,reason)
 local row=host(self,{op='read',target=target:objectName(),flags=flags,reason=reason})
 if row.selected==false then return false end
 if row.selected~=true or type(row.receipt)~='table'then ai_unsupported('Original SD reader receipt malformed','Original SD')end
 local result={kind='answer',random_card_choice=row.receipt};answers[result]=self;return result
end
function SmartAIView:brandOriginalRandomChoice(result)
 -- The active question's native token is still verified at result admission.
 answers[result]=self;return result
end
function SmartAIView:isOriginalOpaqueCardChoice(result)return type(result)=='table'and answers[result]==self end
-- Insert inside choices-round37-sd-facade.inc before its final end.
function SmartAIView:originalHegemonyCanGet(target,key)
 local scope=active[self]
 if not scope or scope.request~=self.request or not AIValue.isPlayer(target)then ai_unsupported('Original canGet outside sealed source call tree','Original canGet')end
 if type(key)~='string'and type(key)~='number'then ai_unsupported('Original canGet malformed key','Original canGet')end
 local row=host(self,{op='can_get',scope=scope.scope,target=target:objectName(),key=key})
 if type(row.value)~='boolean'then ai_unsupported('Original canGet result unknown','Original canGet')end
 return row.value
end
end

-- Finite owner-only AI_needCrossbow observation. Foreign reader is deliberately
-- absent: the source's cross-viewer private strategy flag is not public fact.
do
local function crossbow(self,request)
 if type(ai_original_crossbow_shadow)~='function'then ai_unsupported('Original Crossbow observer unavailable','AI_needCrossbow')end
 local row=ai_original_crossbow_shadow(request)
 if type(row)~='table'or row.kind~='original_crossbow_shadow'or row.known~=true or type(row.value)~='boolean'then ai_unsupported(type(row)=='table'and row.reason or'Original Crossbow state unknown','AI_needCrossbow')end
 return row.value
end
function SmartAIView:getOriginalNeedCrossbow()return crossbow(self,{op='read'})end
function SmartAIView:setOriginalNeedCrossbow(value,card)
 if value~=true or not(AIValue.isCard(card)or AIValue.isConversion(card))or card:isKindOf('Collateral')~=true then ai_unsupported('Original Crossbow finite source write malformed','AI_needCrossbow')end
 local row=card._view;local source
 if type(row)=='table'and type(row.readonly_recipe_key)=='string'and row.readonly_recipe_key~=''then source={recipe_key=row.readonly_recipe_key}
 elseif AIValue.isCard(card)and card:isVirtualCard()==false then source={id=card:getEffectiveId()}
 else ai_unsupported('Original Crossbow source object has no owned/retained witness','AI_needCrossbow')end
 return crossbow(self,{op='write',source=source})
end
end

-- Fixed htms @@zhongerhx: disclosed physical metadata hypothesis only.
do
local entries=setmetatable({},{__mode='k'})
local function checked(self,id)
 local q=self.request
 if type(q)~='table'or q.kind~='use_card'or q.pattern~='@@zhongerhx'
  or q.viewer~=self.player:objectName()or type(id)~='number'or id<0 or id%1~=0 then
  ai_unsupported('Zhongerhx physical hypothesis request differs','zhongerhx')
 end
 return{request=q,decision=q.decision_id,revision=q.state_revision,viewer=q.viewer,pattern=q.pattern,id=id}
end
local function same_request(self,row)
 local now=checked(self,row.id)
 return row.request==now.request and row.decision==now.decision and row.revision==now.revision
  and row.viewer==now.viewer and row.pattern==now.pattern
end
function SmartAIView:getZhongerhxCardEvaluation(id)
 local stamp=checked(self,id)
 local existing=entries[self]
 if existing and existing.id==id then
  if not same_request(self,existing)or not turn_same(existing.face,existing.card._view)
   or not turn_same(existing.candidate,existing.card._evaluation_candidate)then
   ai_unsupported('Zhongerhx cached readonly identity changed','zhongerhx')
  end
  return existing.card
 end
 if type(ai_evaluate_skill_card)~='function'then ai_unsupported('Zhongerhx readonly endpoint unavailable','zhongerhx')end
 local result=ai_evaluate_skill_card('physical:zhongerhx','zhongerhx',{id})
 local face=type(result)=='table'and result.card
 if type(face)~='table'or type(result.candidate)~='table'
  or face.evaluation_only~=true or face.evaluation_owner~=stamp.viewer or face.virtual_card~=false
  or face.id~=id or face.effective_id~=id or face.skill_name~='zhongerhx'
  or face.legacy_string_key~=tostring(id)or type(face.legacy_identity_token)~='string'or face.legacy_identity_token==''then
  ai_unsupported(type(result)=='table'and result.error or'Zhongerhx physical metadata incomplete','zhongerhx')
 end
 local card=CardView.new(copy_value(face));card._ai=self;card._evaluation_candidate=copy_value(result.candidate)
 card.getAuthorityCard=function()return nil end
 card.toCardSpec=function()ai_unsupported('Zhongerhx physical hypothesis is not payment authority','zhongerhx')end
 stamp.card=card;stamp.face=copy_value(face);stamp.candidate=copy_value(result.candidate);entries[self]=stamp
 return card
end
function SmartAIView:zhongerhxSourceResult(text)
 if type(text)~='string'or text=='.'or text==''then return text end
 local wire,targets=text:match('^(%d+)%->(.*)$');local row=entries[self]
 if not wire or not row or tonumber(wire)~=row.id or not same_request(self,row)
  or not turn_same(row.face,row.card._view)or not turn_same(row.candidate,row.card._evaluation_candidate)then
  ai_unsupported('Zhongerhx source result does not name its readonly physical identity','zhongerhx')
 end
 -- Exact legacy physical ID/target output. No binder, conversion_id, scope,
 -- receipt or ownership exception: existing native final admission still rules.
 return{kind='use_card',card_ids={row.id},targets=targets==''and{}or targets:split('+')}
end
end

-- Fixed olddiy @@bu_stwo_guicai: disclosed physical metadata hypothesis only.
do
local entries=setmetatable({},{__mode='k'})
local function checked(self,id)
 local q=self.request
 if type(q)~='table'or q.kind~='use_card'or q.pattern~='@@bu_stwo_guicai'
  or q.viewer~=self.player:objectName()or type(id)~='number'or id<0 or id%1~=0 then
  ai_unsupported('Guicai physical hypothesis request differs','bu_stwo_guicai')
 end
 return{request=q,decision=q.decision_id,revision=q.state_revision,viewer=q.viewer,pattern=q.pattern,id=id}
end
local function same_request(self,row)
 local now=checked(self,row.id)
 return row.request==now.request and row.decision==now.decision and row.revision==now.revision
  and row.viewer==now.viewer and row.pattern==now.pattern
end
function SmartAIView:getGuicaiCardEvaluation(id)
 local stamp=checked(self,id)
 local existing=entries[self]
 if existing and existing.id==id then
  if not same_request(self,existing)or not turn_same(existing.face,existing.card._view)
   or not turn_same(existing.candidate,existing.card._evaluation_candidate)then
   ai_unsupported('Guicai cached readonly identity changed','bu_stwo_guicai')
  end
  return existing.card
 end
 if type(ai_evaluate_skill_card)~='function'then ai_unsupported('Guicai readonly endpoint unavailable','bu_stwo_guicai')end
 local result=ai_evaluate_skill_card('physical:bu_stwo_guicai','bu_stwo_guicai',{id})
 local face=type(result)=='table'and result.card
 if type(face)~='table'or type(result.candidate)~='table'
  or face.evaluation_only~=true or face.evaluation_owner~=stamp.viewer or face.virtual_card~=false
  or face.id~=id or face.effective_id~=id or face.skill_name~='bu_stwo_guicai'
  or face.legacy_string_key~=tostring(id)or type(face.legacy_identity_token)~='string'or face.legacy_identity_token==''then
  ai_unsupported(type(result)=='table'and result.error or'Guicai physical metadata incomplete','bu_stwo_guicai')
 end
 local card=CardView.new(copy_value(face));card._ai=self;card._evaluation_candidate=copy_value(result.candidate)
 card.getAuthorityCard=function()return nil end
 card.toCardSpec=function()ai_unsupported('Guicai physical hypothesis is not payment authority','bu_stwo_guicai')end
 stamp.card=card;stamp.face=copy_value(face);stamp.candidate=copy_value(result.candidate);entries[self]=stamp
 return card
end
function SmartAIView:guicaiSourceResult(text)
 if type(text)~='string'or text=='.'or text==''then return text end
 local wire,targets=text:match('^(%d+)%->(.*)$');local row=entries[self]
 if not wire or not row or tonumber(wire)~=row.id or not same_request(self,row)
  or not turn_same(row.face,row.card._view)or not turn_same(row.candidate,row.card._evaluation_candidate)then
  ai_unsupported('Guicai source result does not name its readonly physical identity','bu_stwo_guicai')
 end
 -- Exact legacy physical ID/target output. No binder, conversion_id, scope,
 -- receipt or ownership exception: existing native final admission still rules.
 return{kind='use_card',card_ids={row.id},targets=targets==''and{}or targets:split('+')}
end
end

do
-- Faqi's selected source object is native observation custody, not a saved ticket.
local function heqia_host(self,mode,payload)
 if type(ai_heqia_saved_plan)~='function'then ai_unsupported('native Heqia observation bridge missing','heqia_use')end
 local result=ai_heqia_saved_plan(mode,payload)
 if AIUnsupported.is(result)then error(result,0)end
 if type(result)~='table'or result.error then
  local why=type(result)=='table'and result.error or'Heqia bridge returned no exact result'
  if type(result)=='table'and result.native_rejected==true then
   local signal=AIUnsupported.new(why,'heqia_use')
   signal.native_rejected=true;signal.terminal_response_selection=true;error(signal,0)
  end
  ai_unsupported(why,'heqia_use')
 end
 return result
end
local function heqia_card_result(result)
 if result.exists==false then return nil end
 if result.evaluation_only~=true or type(result.card)~='table'or type(result.card.readonly_recipe_key)~='string'then ai_unsupported('Heqia readonly custody missing','heqia_use')end
 local c=CardView.new(copy_value(result.card));c._evaluation_candidate=copy_value(result.candidate);return c
end
function SmartAIView:evaluateHeqiaCard(offered,material,name)
 return heqia_card_result(heqia_host(self,'construct',{offered_id=offered,material=material,name=name}))
end
function SmartAIView:rememberHeqiaUse(d,offered)
 if type(d)~='table'or d.isDummy~=true then ai_unsupported('Heqia source dummy missing','heqia_use')end
 local card,targets=d.card,d.to;local selector={};local names={}
 if card then
  if not AIValue.isCard(card)and not AIValue.isConversion(card)then ai_unsupported('Heqia source card is not observed','heqia_use')end
  local v=rawget(card,'_view');if type(v)~='table'then ai_unsupported('Heqia card descriptor missing','heqia_use')end
  if type(v.readonly_recipe_key)=='string'then selector={readonly_recipe_key=v.readonly_recipe_key}
  elseif AIValue.isConversion(card)then selector={conversion_id=card:getConversionId(),legacy_identity_token=v.legacy_identity_token}
  else selector={physical_id=card:getEffectiveId(),legacy_identity_token=v.legacy_identity_token}end
 end
 if targets then
  if not AIValue.isList(targets)then ai_unsupported('Heqia default dummy target list missing','heqia_use')end
  for _,p in ipairs(targets)do if not AIValue.isPlayer(p)then ai_unsupported('Heqia source target not a player','heqia_use')end;names[#names+1]=p:objectName()end
 end
 local allowed={card=true,to=true,isDummy=true,extra_target=true,current_targets=true,_evaluation_only=true,context=true,scratch=true,candidate_id=true}
 for k in pairs(d)do if not allowed[k]then ai_unsupported('Heqia source dummy field unavailable: '..tostring(k),'heqia_use')end end
 local extra=d.extra_target or 0;if type(extra)~='number'or extra~=extra or extra%1~=0 or extra<-2147483648 or extra>2147483647 then ai_unsupported('Heqia extra target field malformed','heqia_use')end
 if d.current_targets~=nil and(type(d.current_targets)~='table'or next(d.current_targets)~=nil)then ai_unsupported('Heqia current_targets differs from fixed default dummy','heqia_use')end
 local f={isDummy=true,extra_target=extra,current_targets_empty=true,card_state=card and'card'or card==false and'false'or'nil',target_state=targets and'list'or targets==false and'false'or'nil'}
 local r=heqia_host(self,'capture',{selector=selector,targets=names,offered_id=offered,source_fields=f})
 if type(r.token)~='string'or r.token==''then ai_unsupported('Heqia source write custody missing','heqia_use')end
 self:setStrategyMemory('ol_sp.heqia_use',{token=r.token});return r.token
end
local function heqia_token(self)
 local saved,present=self:getStrategyMemory('ol_sp.heqia_use');if AIUnsupported.is(saved)then error(saved,0)end
 local token=present and type(saved)=='table'and saved.token or'';if type(token)~='string'then ai_unsupported('Heqia custody token malformed','heqia_use')end;return token
end
function SmartAIView:loadHeqiaUse()
 local r=heqia_host(self,'read',{token=heqia_token(self)})
 if type(r.source_error)=='string'then error(r.source_error,0)end
 if r.source_pass==true then return{}end
 local card=heqia_card_result(r);if not card or not AIValue.isList(r.targets)then ai_unsupported('Heqia actual plan unavailable','heqia_use')end
 local to=AIList.new{};for _,name in ipairs(r.targets)do local p=self.room:findPlayerByObjectName(name,true);if not p then ai_unsupported('Heqia source target left roster','heqia_use')end;to:append(p)end
 return{card=card,to=to}
end
local function heqia_selected(r)
 if type(r.source_error)=='string'then error(r.source_error,0)end
 if r.source_pass==true then return{kind='pass'}end
 if type(r.card_spec)~='table'or type(r.card_spec.conversion_id)~='number'or not AIValue.isList(r.targets)then ai_unsupported('Heqia selected receipt missing','heqia_use')end
 return{kind='use_card',card_spec=r.card_spec,targets=r.targets}
end
function SmartAIView:materializeHeqiaUse(names)
 return heqia_selected(heqia_host(self,'select',{token=heqia_token(self),targets=names}))
end
function SmartAIView:materializeHeqiaFirst(wire)
 if type(wire)~='string'then ai_unsupported('Heqia first source wire missing','heqia_use')end
 local costs,names=wire:match('^@HeqiaCard=([^:]+)%->(.+)$');if not costs then ai_unsupported('Heqia first source grammar malformed','heqia_use')end
 local ids={};if costs~='.'then for id in costs:gmatch('[^+]+')do local n=tonumber(id);if not n or n<0 or n%1~=0 then ai_unsupported('Heqia first payment malformed','heqia_use')end;ids[#ids+1]=n end end
 local targets={};for name in names:gmatch('[^+]+')do targets[#targets+1]=name end
 return heqia_selected(heqia_host(self,'first',{subcards=ids,targets=targets}))
end
local function leiluan_host(self,mode,payload)
 if type(ai_leiluan_saved_plan)~='function'then ai_unsupported('native Leiluan observation bridge missing','leiluanUse')end
 local result=ai_leiluan_saved_plan(mode,payload)
 if AIUnsupported.is(result)then error(result,0)end
 if type(result)~='table'or result.error then
  local why=type(result)=='table'and result.error or'Leiluan bridge returned no exact result'
  if type(result)=='table'and result.native_rejected==true then
   local signal=AIUnsupported.new(why,'leiluanUse')
   signal.native_rejected=true;signal.terminal_response_selection=true;error(signal,0)
  end
  ai_unsupported(why,'leiluanUse')
 end
 return result
end
function SmartAIView:rememberLeiluanUse(card,targets,offered,sourcePlan)
 local view=type(card)=='table'and rawget(card,'_view')
 if not AIValue.isCard(card)and not AIValue.isConversion(card)then ai_unsupported('Leiluan source did not select a policy card','leiluanUse')end
 if type(view)~='table'or not AIValue.isList(targets)then ai_unsupported('Leiluan selected observation shape missing','leiluanUse')end
 local selector
 if type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then selector={readonly_recipe_key=view.readonly_recipe_key}
 elseif AIValue.isConversion(card)then selector={conversion_id=card:getConversionId(),legacy_identity_token=view.legacy_identity_token}
 else selector={physical_id=card:getEffectiveId(),legacy_identity_token=view.legacy_identity_token}end
 local names={}
 for _,target in ipairs(targets)do
  if not AIValue.isPlayer(target)or type(target:objectName())~='string'then ai_unsupported('Leiluan target is not a player observation','leiluanUse')end
  names[#names+1]=target:objectName()
 end
 local payload={selector=selector,targets=names,offered_name=offered}
 if sourcePlan~=nil then
  if type(sourcePlan)~='table' or sourcePlan.card~=card or sourcePlan.to~=targets or sourcePlan.isDummy~=true then ai_unsupported('Leiluan source dummy plan identity unavailable','leiluanUse')end
  -- Only these adapter-owned fields are absent from the donor's dummy table.
  local internal={_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  local source={card=true,to=true,isDummy=true,extra_target=true,current_targets=true}
  for key in pairs(sourcePlan)do if not internal[key]and not source[key]then ai_unsupported('Leiluan source plan field has no exact native representation: '..tostring(key),'leiluanUse')end end
  local extra=sourcePlan.extra_target
  if extra==nil then extra=0 end -- donor dummy() initialization
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra < -2147483648 or extra > 2147483647 then ai_unsupported('Leiluan extra_target source field malformed','leiluanUse')end
  local current=sourcePlan.current_targets
  if current~=nil and (type(current)~='table'or next(current)~=nil)then ai_unsupported('Leiluan nonempty current_targets native representation unavailable','leiluanUse')end
  payload.source_fields={isDummy=true,extra_target=extra,current_targets_empty=true}
 end
 local result=leiluan_host(self,'capture',payload)
 if type(result.token)~='string'or result.token==''then ai_unsupported('Leiluan capture lacks native token','leiluanUse')end
 self:setStrategyMemory('ol_sp.leiluanUse',{token=result.token})
 return result.token
end
function SmartAIView:materializeLeiluanUse()
 local saved,present=self:getStrategyMemory('ol_sp.leiluanUse')
 if AIUnsupported.is(saved)then error(saved,0)end
 local token=present and type(saved)=='table'and saved.token or ''
 if type(token)~='string'then ai_unsupported('Leiluan stored custody key is malformed','leiluanUse')end
 local result=leiluan_host(self,'select',{token=token})
 if type(result.source_error)=='string'then error(result.source_error,0)end
 if result.source_pass==true then return{kind='pass'}end
 if not AIValue.isList(result.targets)then ai_unsupported('selected Leiluan target sequence missing','leiluanUse')end
 if type(result.card_spec)~='table' or type(result.card_spec.conversion_id)~='number' then
  ai_unsupported('selected Leiluan source has no fresh finite receipt','leiluanUse')
 end
 return{kind='use_card',card_spec=result.card_spec,targets=result.targets}
end
function SmartAIView:evaluateLeiluanCard(name)
 local result=leiluan_host(self,'construct',{name=name})
 if result.exists==false then return nil end
 if result.evaluation_only~=true or type(result.card)~='table'or result.card.evaluation_only~=true or type(result.card.readonly_recipe_key)~='string'then ai_unsupported('Leiluan construction has no exact readonly custody','leiluanUse')end
 local card=CardView.new(copy_value(result.card));card._evaluation_candidate=copy_value(result.candidate);return card
end
local function jianman_host(self,mode,payload)
 if type(ai_jianman_saved_plan)~='function'then ai_unsupported('native Jianman observation bridge missing','jianmanUse')end
 local result=ai_jianman_saved_plan(mode,payload)
 if AIUnsupported.is(result)then error(result,0)end
 if type(result)~='table'or result.error then
  local why=type(result)=='table'and result.error or'Jianman bridge returned no exact result'
  if type(result)=='table'and result.native_rejected==true then
   local signal=AIUnsupported.new(why,'jianmanUse')
   signal.native_rejected=true;signal.terminal_response_selection=true;error(signal,0)
  end
  ai_unsupported(why,'jianmanUse')
 end
 return result
end
function SmartAIView:rememberJianmanUse(card,targets,offered,sourcePlan)
 local view=type(card)=='table'and rawget(card,'_view')
 if not AIValue.isCard(card)and not AIValue.isConversion(card)then ai_unsupported('Jianman source did not select a policy card','jianmanUse')end
 if type(view)~='table'or not AIValue.isList(targets)then ai_unsupported('Jianman selected observation shape missing','jianmanUse')end
 local selector
 if type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then selector={readonly_recipe_key=view.readonly_recipe_key}
 elseif AIValue.isConversion(card)then selector={conversion_id=card:getConversionId(),legacy_identity_token=view.legacy_identity_token}
 else selector={physical_id=card:getEffectiveId(),legacy_identity_token=view.legacy_identity_token}end
 local names={}
 for _,target in ipairs(targets)do
  if not AIValue.isPlayer(target)or type(target:objectName())~='string'then ai_unsupported('Jianman target is not a player observation','jianmanUse')end
  names[#names+1]=target:objectName()
 end
 local payload={selector=selector,targets=names,offered_name=offered}
 if sourcePlan~=nil then
  if type(sourcePlan)~='table' or sourcePlan.card~=card or sourcePlan.to~=targets or sourcePlan.isDummy~=true then ai_unsupported('Jianman source dummy plan identity unavailable','jianmanUse')end
  -- Only these adapter-owned fields are absent from the donor's dummy table.
  local internal={_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  local source={card=true,to=true,isDummy=true,extra_target=true,current_targets=true}
  for key in pairs(sourcePlan)do if not internal[key]and not source[key]then ai_unsupported('Jianman source plan field has no exact native representation: '..tostring(key),'jianmanUse')end end
  local extra=sourcePlan.extra_target
  if extra==nil then extra=0 end -- donor dummy() initialization
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra < -2147483648 or extra > 2147483647 then ai_unsupported('Jianman extra_target source field malformed','jianmanUse')end
  local current=sourcePlan.current_targets
  if current~=nil and (type(current)~='table'or next(current)~=nil)then ai_unsupported('Jianman nonempty current_targets native representation unavailable','jianmanUse')end
  payload.source_fields={isDummy=true,extra_target=extra,current_targets_empty=true}
 end
 local result=jianman_host(self,'capture',payload)
 if type(result.token)~='string'or result.token==''then ai_unsupported('Jianman capture lacks native token','jianmanUse')end
 self:setStrategyMemory('ol_sp.jianmanUse',{token=result.token})
 return result.token
end
function SmartAIView:materializeJianmanUse()
 local saved,present=self:getStrategyMemory('ol_sp.jianmanUse')
 if AIUnsupported.is(saved)then error(saved,0)end
 local token=present and type(saved)=='table'and saved.token or ''
 if type(token)~='string'then ai_unsupported('Jianman stored custody key is malformed','jianmanUse')end
 local result=jianman_host(self,'select',{token=token})
 if type(result.source_error)=='string'then error(result.source_error,0)end
 if result.source_pass==true then return{kind='pass'}end
 if not AIValue.isList(result.targets)then ai_unsupported('selected Jianman target sequence missing','jianmanUse')end
 if type(result.card_spec)~='table' or type(result.card_spec.conversion_id)~='number' then
  ai_unsupported('selected Jianman source has no fresh finite receipt','jianmanUse')
 end
 return{kind='use_card',card_spec=result.card_spec,targets=result.targets}
end
function SmartAIView:evaluateJianmanCard(name)
 local result=jianman_host(self,'construct',{name=name})
 if result.exists==false then return nil end
 if result.evaluation_only~=true or type(result.card)~='table'or result.card.evaluation_only~=true or type(result.card.readonly_recipe_key)~='string'then ai_unsupported('Jianman construction has no exact readonly custody','jianmanUse')end
 local card=CardView.new(copy_value(result.card));card._evaluation_candidate=copy_value(result.candidate);return card
end
local function faqi_host(self,mode,payload)
 if type(ai_faqi_saved_plan)~='function'then ai_unsupported('native Faqi observation bridge missing','faqiUse')end
 local result=ai_faqi_saved_plan(mode,payload)
 if AIUnsupported.is(result)then error(result,0)end
 if type(result)~='table'or result.error then
  local why=type(result)=='table'and result.error or'Faqi bridge returned no exact result'
  if type(result)=='table'and result.native_rejected==true then
   local signal=AIUnsupported.new(why,'faqiUse')
   signal.native_rejected=true;signal.terminal_response_selection=true;error(signal,0)
  end
  ai_unsupported(why,'faqiUse')
 end
 return result
end
-- SmartAI kept the AG plan on self.faqiUse; this viewer's memory holds the card
-- name and targets, and @@faqi answers with the authorized Faqi conversion.
function SmartAIView:rememberFaqiUse(card,targets)
 if not AIValue.isCard(card)and not AIValue.isConversion(card)then ai_unsupported('Faqi source did not select a policy card','faqiUse')end
 if not AIValue.isList(targets)then ai_unsupported('Faqi selected observation shape missing','faqiUse')end
 local names={}
 for _,target in ipairs(targets)do
  if not AIValue.isPlayer(target)or type(target:objectName())~='string'then ai_unsupported('Faqi target is not a player observation','faqiUse')end
  names[#names+1]=target:objectName()
 end
 self:setStrategyMemory('doudizhu.faqiUse',{name=card:objectName(),targets=names})
 return true
end
function SmartAIView:materializeFaqiUse()
 local saved,present=self:getStrategyMemory('doudizhu.faqiUse')
 if AIUnsupported.is(saved)then error(saved,0)end
 if not present or type(saved)~='table'or type(saved.name)~='string'then ai_unsupported('source Faqi plan was not observed by this viewer','faqiUse')end
 local conversion=self:newCard(saved.name,{skill='faqi'})
 if not conversion then ai_unsupported('selected Faqi card has no authorized conversion','faqiUse')end
 return{kind='use_card',card_spec=conversion:toCardSpec(),targets=copy_value(saved.targets)}
end
function SmartAIView:evaluateFaqiReviseCard(kind,costs)
 if kind~='limu'and kind~='spear'then ai_unsupported('Faqi revise constructor is not audited','faqiUse')end
 local result=faqi_host(self,'construct',{constructor=kind,costs=costs})
 if result.exists==false then return nil end -- genuine Card::Parse miss
 if result.evaluation_only~=true or type(result.card)~='table'or result.card.evaluation_only~=true
  or type(result.card.readonly_recipe_key)~='string'then ai_unsupported('Faqi revise constructor lacks readonly custody','faqiUse')end
 local card=CardView.new(copy_value(result.card));card._evaluation_candidate=copy_value(result.candidate)
 return card
end

-- Current-question Limu constructors. No saved observation or Faqi authority.
function SmartAIView:evaluateLimuSourceCard(kind,costs,request)
 if kind~='limu'and kind~='indulgence'and kind~='spear'then ai_unsupported('Limu source constructor is not audited','limu')end
 if type(self.request)~='table'or self.request.kind~='activate'or self.request.reason~=sgs.CardUseStruct_CARD_USE_REASON_PLAY then
  if kind=='indulgence'then ai_unsupported('Limu fill hypothesis requires current Play','limu')end
  return self:evaluateFaqiReviseCard(kind,costs)
 end
 if kind=='limu'then
  -- Replacement uses the current unique Limu provider, not the input card's
  -- activation or a previous Faqi observer. Ambiguity remains explicit.
  local scope=self:getNativeSkillActionScope('limu',request)
  -- Native scope.request is the raw projected DTO. Preserve an actual fill's
  -- request facade; an unbound revise uses the uniquely selected native DTO.
  local source=request or AILegacyRequest.new(scope.request,self.room)
  if not source or type(source.isValid)~='function' or source:isValid()~=true then
   ai_unsupported('Limu current provider request is incomplete','limu')
  end
  return self:evaluateTurnSkillCard('limu','LimuCard',costs,source)
 end
 return self:evaluateSkillCard('limu_source',kind,costs)
end

end

-- R45 fixed RushB physical setters. Private row provenance follows only this
-- file's copies of actual request DTOs; neither IDs nor legacy tokens are tickets.
do
 local P=r45_physical
 local function state(request)
  local s=P.states[request];if not s then s={aliases={},views={},ids={}};P.states[request]=s end;return s
 end
 function P.mark(request)
  if P.states[request] then return end
  state(request)
  -- Only actual projected physical-card rows have request provenance. No
  -- recursive scan of strategy facts, class catalogues, candidates or recipes.
  -- Copying a genuine row preserves this private identity via copy_value.
  local function rows(values)
   if type(values)~='table' or getmetatable(values)~=nil then return end
   for _,v in ipairs(values)do
    if type(v)=='table' and getmetatable(v)==nil and v.virtual_card==false
     and v.evaluation_only~=true and v.conversion_id==nil and v.readonly_recipe_key==nil
     and type(v.effective_id)=='number' and v.effective_id>=0 and v.effective_id%1==0
     and type(v.legacy_identity_token)=='string' and v.legacy_identity_token~=''then
     P.rows[v]=request
    end
   end
  end
  local function player(v)
   if type(v)~='table' then return end
   rows(v.equips);rows(v.judging_area);rows(v.known_cards)
   for _,pile in ipairs(v.piles or{})do
    if type(pile)=='table' and (v.object_name==request.viewer or pile.open==true)then rows(pile.cards)end
   end
  end
  local world=request.world_view
  rows(world.hand_cards);rows(world.discard_pile);player(world.self)
  for _,v in ipairs(world.players or{})do player(v)end
  local options=request.options
  if type(options)=='table'then rows(options.cards)end
 end
 function P.card_view(view)
  if view.evaluation_only==true or view.conversion_id~=nil or view.readonly_recipe_key~=nil then return view end
  local r=P.rows[view];local s=r and P.states[r]
  local v=s and s.views[view.legacy_identity_token]
  if v then local copy=copy_value(v);P.rows[copy]=r;return copy end
  return view
 end
 function P.card_created(card)
  local v=card._view;local r=P.rows[v]
  if not r or v.evaluation_only==true or v.conversion_id~=nil or v.readonly_recipe_key~=nil or v.virtual_card~=false or type(v.effective_id)~='number' or v.effective_id<0 or type(v.legacy_identity_token)~='string'then return end
  local s=state(r);local token=v.legacy_identity_token
  local a=s.aliases[token];if not a then a=setmetatable({},{__mode='k'});s.aliases[token]=a end;a[card]=true
 end
 function P.sync(self,skill,card,refresh)
  local key='rushB.physical_mutation'
  if not AIValue.isCard(card) or P.rows[card._view]~=self.request or card:isVirtualCard()~=false
   or card:isEvaluationOnly() or type(ai_rushb_physical_skill)~='function'then ai_unsupported('physical mutation requires current issued owner Card',key)end
  local old=card._view
  local spec={skill=skill,id=card:getEffectiveId(),identity=card:getLegacyIdentityToken(),name=card:objectName(),
   class_name=card:getClassName(),suit=card:getSuit(),number=card:getNumber(),previous_skill=card:getSkillName(false)}
  if refresh then spec.refresh=true end
  local active=state(self.request);active.poison="physical mutation result not reconciled"
  local result=ai_rushb_physical_skill(spec,self.request)
  if AIUnsupported.is(result)then error(result,0)end
  local v=type(result)=='table' and result.card
  if type(v)~='table' or type(result.candidate)~='table' or result.kind~='rushb_physical_skill'
   or result.viewer~=self.request.viewer or result.decision_id~=self.request.decision_id or result.state_revision~=self.request.state_revision
   or v.effective_id~=spec.id or v.legacy_identity_token~=spec.identity or v.name~=spec.name or v.class_name~=spec.class_name
   or v.suit~=spec.suit or v.number~=spec.number or v.skill_name~=skill or v.virtual_card~=false or v.evaluation_only~=false
   or v.conversion_id~=nil or v.legacy_string_key~=old.legacy_string_key or not AIValue.isList(v.skill_names)then
   ai_unsupported(type(result)=='table' and result.error or'physical mutation result invalid',key)
  end
  P.rows[v]=self.request
  local s=state(self.request);s.views[spec.identity]=copy_value(v);s.ids[spec.id]=copy_value(result.candidate)
  for alias in pairs(s.aliases[spec.identity]or{})do
   -- Update the existing facade and its row in place: source aliases observe
   -- the same physical object; no conversion/readonly brand is introduced.
   local row=alias._view;for k in pairs(row)do row[k]=nil end
   for k,x in pairs(v)do row[k]=copy_value(x)end
  end
  if self._indexes then
   self._indexes.candidates_by_card[spec.id]=copy_value(result.candidate)
   for i,row in ipairs(self._indexes.candidates or{})do if row.card_id==spec.id then self._indexes.candidates[i]=copy_value(result.candidate)end end
  end
  if self.player._own_card_rows then self.player._own_card_rows[spec.id]=copy_value(v)end
  s.poison=nil
  -- All retained lexical states are invalidated, including a parent's profile
  -- restored later by its wrapper. Recompute under that parent's current state.
  local scope=owner_range_states[self]
  while scope do
   for c in pairs(scope.profiles or{})do
    if AIValue.isCard(c) and c:getLegacyIdentityToken()==spec.identity then scope.profiles[c]=nil end
   end
   scope=scope.parent
  end
  return card
 end
 function SmartAIView:acceptRushBPhysicalResponseAttachment(card,face)
  local v=AIValue.isCard(card)and card._view;local s=P.states[self.request]
  local skill=v and v.skill_name
  if not s or not v or P.rows[v]~=self.request or not s.views[v.legacy_identity_token]
   or (skill~='mk_danlve_yinyue'and skill~='mk_danlve_qinggang') or type(face)~='table'
   or face.effective_id~=v.effective_id or face.name~=v.name or face.class_name~=v.class_name
   or face.suit~=v.suit or face.number~=v.number or face.skill_name~=skill or face.virtual_card~=false then
   ai_unsupported('Danlve physical response attachment lost source identity','rushB.physical_mutation')
  end
  return P.sync(self,skill,card,true)
 end
 function SmartAIView:isRushBPhysicalResponseSelection(card)
  local v=AIValue.isCard(card)and card._view;local s=P.states[self.request]
  return not not (self.request.kind=='respond_card'and s and not s.poison and v and P.rows[v]==self.request
   and v.evaluation_only~=true and v.conversion_id==nil and v.readonly_recipe_key==nil
   and s.views[v.legacy_identity_token] and (v.skill_name=='mk_danlve_yinyue'or v.skill_name=='mk_danlve_qinggang'))
 end
 function SmartAIView:evaluatePhysicalSkillMutation(skill,card)return P.sync(self,skill,card,false)end
 function P.refresh(self)
  local s=P.states[self.request];if not s then return end
  for _,v in pairs(s.views)do
   local c=CardView.new(v)
   P.sync(self,v.skill_name,c,true)
  end
 end
 local baseCandidate=SmartAIView.getCardCandidate
 function SmartAIView:getCardCandidate(id)
  local s=P.states[self.request]
  if s and s.poison then ai_unsupported(s.poison,'rushB.physical_mutation')end
  return baseCandidate(self,id)
 end
 function SmartAIView:getPhysicalMutationCandidate(card)
  local s=P.states[self.request];local v=AIValue.isCard(card)and card._view
  if s and v and v.evaluation_only~=true and v.conversion_id==nil and v.readonly_recipe_key==nil and P.rows[v]==self.request and s.views[v.legacy_identity_token]then
   return self:getCardCandidate(v.effective_id)
  end
 end
 local prior=SmartAIView.getEvaluationCandidate
 function SmartAIView:getEvaluationCandidate(card)
  local s=P.states[self.request];local v=AIValue.isCard(card)and card._view
  if s and v and v.evaluation_only~=true and v.conversion_id==nil and v.readonly_recipe_key==nil and P.rows[v]==self.request and s.views[v.legacy_identity_token]then
   return self:getPhysicalMutationCandidate(card)
  end
  return prior(self,card)
 end
end

-- Xufa source evaluation and same-owner pure-value strategy history.
do
 local function host(self,mode,payload)
  if type(ai_xufa_actual_slot)~='function'then ai_unsupported('Xufa actual slot bridge missing','xufaUse')end
  local r=ai_xufa_actual_slot(mode,payload or{})
  if AIUnsupported.is(r)then error(r,0)end
  if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'Xufa slot result missing','xufaUse')end
  return r
 end
 local function card_result(r)
  if r.evaluation_only~=true or type(r.card)~='table'or r.card.evaluation_only~=true
    or type(r.card.readonly_recipe_key)~='string'or r.card.readonly_recipe_key==''then ai_unsupported('Xufa retained Card custody missing','xufaUse')end
  local c=CardView.new(copy_value(r.card));c._evaluation_candidate=copy_value(r.candidate);return c
 end
 function SmartAIView:evaluateXufaSourceCard(name,costs)
  local r=host(self,'construct',{name=name,costs=costs})
  if r.exists==false then return nil end
  return card_result(r)
 end
 -- Save only fields read by the fixed @@xufa consumer. No proxy, recipe key,
 -- identity token, conversion id or payment authority crosses the request.
 function SmartAIView:rememberXufaUse(d)
  local c=d.card
  if not AIValue.isCard(c)and not AIValue.isConversion(c)then
   ai_unsupported('Xufa selected plan card is unavailable','xufaUse')
  end
  local materials={};for _,id in ipairs(c:getSubcards())do materials[#materials+1]=id end
  local names={};for _,p in ipairs(d.to)do names[#names+1]=p:objectName()end
  local card={virtual=c:isVirtualCard(),id=c:getEffectiveId(),name=c:objectName(),
   suit=c:getSuit(),number=c:getNumber(),skill=c:getSkillName(false),
   materials=materials,can_recast=c:canRecast(),wire=c:toString()}
  -- Decision writes persist before later ordinary errors, exactly like the
  -- donor assignment. get/setStrategyMemory also use the existing event envelope.
  self:setStrategyMemory('xufa.use',{card=card,to=names})
  return true
 end
end

do
local r46_slots={xdyifuvsTo=true,xdyifuvsUse=true,godshenji_use=true}
local function r46_call(self,slot,op,payload)
 if not r46_slots[slot]or type(ai_newgenerals_saved_slot)~='function'then ai_unsupported('finite saved-plan bridge unavailable','newgenerals.saved_plan')end
 local r=ai_newgenerals_saved_slot(slot,op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'saved-plan bridge returned no observation','newgenerals.saved_plan')end
 if type(r.source_error)=='string'then error(r.source_error,0)end
 return r
end
function SmartAIView:writeNewgeneralsSavedSlot(slot,value,actualCard)
 if slot=='xdyifuvsTo'then
  if not AIValue.isPlayer(value)then ai_unsupported('source saved target is not a Player','newgenerals.saved_plan')end
  return r46_call(self,slot,'write',{target=value:objectName()})
 end
 if slot~='xdyifuvsUse'and slot~='godshenji_use'then ai_unsupported('unknown saved source slot','newgenerals.saved_plan')end
 if type(value)~='table'or(not AIValue.isCard(actualCard)and not AIValue.isConversion(actualCard))then ai_unsupported('source plan/Card shape unavailable','newgenerals.saved_plan')end
 local view=rawget(actualCard,'_view');if type(view)~='table'then ai_unsupported('saved Card native identity absent','newgenerals.saved_plan')end
 local selector
 if type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then selector={readonly_recipe_key=view.readonly_recipe_key}
 elseif AIValue.isConversion(actualCard)then selector={conversion_id=actualCard:getConversionId(),legacy_identity_token=view.legacy_identity_token}
 else selector={physical_id=actualCard:getEffectiveId(),legacy_identity_token=view.legacy_identity_token}end
 local fields
 if slot=='godshenji_use'and value.isDummy==nil then
  if type(value.to)~='table'or next(value.to)~=nil then ai_unsupported('Godshenji literal targets differ from source','newgenerals.saved_plan')end
  for k in pairs(value)do if k~='card'and k~='to'then ai_unsupported('Godshenji literal has extra source fields','newgenerals.saved_plan')end end
  fields={literal=true}
 else
  local internal={_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  local source={card=true,to=true,isDummy=true,extra_target=true,current_targets=true}
  for k in pairs(value)do if not internal[k]and not source[k]then ai_unsupported('saved dummy field has no exact representation: '..tostring(k),'newgenerals.saved_plan')end end
  if value.isDummy~=true or not AIValue.isList(value.to)then ai_unsupported('saved source dummy shape unavailable','newgenerals.saved_plan')end
  local extra=value.extra_target;if extra==nil then extra=0 end
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra< -2147483648 or extra>2147483647 then ai_unsupported('saved source extra_target malformed','newgenerals.saved_plan')end
  if value.current_targets~=nil and(type(value.current_targets)~='table'or next(value.current_targets)~=nil)then ai_unsupported('saved source current_targets not empty','newgenerals.saved_plan')end
  fields={isDummy=true,extra_target=extra,current_targets_empty=true}
 end
 local names={}
 for _,p in ipairs(value.to)do if not AIValue.isPlayer(p)then ai_unsupported('saved source target not Player','newgenerals.saved_plan')end;names[#names+1]=p:objectName()end
 return r46_call(self,slot,'write',{selector=selector,targets=names,source_fields=fields})
end
function SmartAIView:readNewgeneralsSavedSlot(slot)
 local r=r46_call(self,slot,'read',{})
 if r.status=='absent'then return nil end
 if r.status=='player'then
  local p=self.room:findPlayerByObjectName(r.target,true)
  if not p then ai_unsupported('saved source Player no longer projected','newgenerals.saved_plan')end
  return p
 end
 if r.status=='pass'then return{card=false}end
 if r.status~='plan'or type(r.wire)~='string'or not AIValue.isList(r.targets)then ai_unsupported('saved source plan result malformed','newgenerals.saved_plan')end
 local to={};for _,name in ipairs(r.targets)do local p=self.room:findPlayerByObjectName(name,true);if not p then ai_unsupported('saved source target not projected','newgenerals.saved_plan')end;to[#to+1]=p end
 -- The two fixed readers only call toString. This pure observation is neither a
 -- CardView nor an action descriptor; the normal response binder authorizes it.
 local wire=r.wire
 return{card={toString=function()return wire end},to=to}
end
end

do
local r47_slots={kezufuxunUse=true,zuchengqiUse=true,kezumingjieUse=true,kezulilunUse=true}
local function r47_call(self,slot,op,payload)
 if not r47_slots[slot]or type(ai_olclan_saved_slot)~='function'then ai_unsupported('finite saved-plan bridge unavailable','olClan.saved_plan')end
 local r=ai_olclan_saved_slot(slot,op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'saved-plan bridge returned no observation','olClan.saved_plan')end
 if type(r.source_error)=='string'then error(r.source_error,0)end
 return r
end
function SmartAIView:writeOlClanSavedSlot(slot,value,actualCard)
 if not r47_slots[slot]then ai_unsupported('unknown saved source slot','olClan.saved_plan')end
 if type(value)~='table'or(not AIValue.isCard(actualCard)and not AIValue.isConversion(actualCard))then ai_unsupported('source plan/Card shape unavailable','olClan.saved_plan')end
 local view=rawget(actualCard,'_view');if type(view)~='table'then ai_unsupported('saved Card native identity absent','olClan.saved_plan')end
 local selector
 local observed=rawget(actualCard,'_olclan_observed_source')
 if (slot=='kezumingjieUse'or slot=='kezulilunUse')and type(observed)=='table'then
  if type(observed.physical_id)~='number'or observed.physical_id~=actualCard:getEffectiveId()
   or type(observed.legacy_identity_token)~='string'or observed.legacy_identity_token==''
   or type(view.legacy_identity_token)~='string'or view.legacy_identity_token==''then
   ai_unsupported('saved acquired source observation malformed','olClan.saved_plan')
  end
  selector={acquired_source_id=observed.physical_id,legacy_identity_token=view.legacy_identity_token,
   observed_source_identity=observed.legacy_identity_token}
 elseif type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then selector={readonly_recipe_key=view.readonly_recipe_key}
 elseif AIValue.isConversion(actualCard)then selector={conversion_id=actualCard:getConversionId(),legacy_identity_token=view.legacy_identity_token}
 else selector={physical_id=actualCard:getEffectiveId(),legacy_identity_token=view.legacy_identity_token}end
 local fields
  local internal={_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  local source={card=true,to=true,isDummy=true,extra_target=true,current_targets=true}
  for k in pairs(value)do if not internal[k]and not source[k]then ai_unsupported('saved dummy field has no exact representation: '..tostring(k),'olClan.saved_plan')end end
  if value.isDummy~=true or not AIValue.isList(value.to)then ai_unsupported('saved source dummy shape unavailable','olClan.saved_plan')end
  local extra=value.extra_target;if extra==nil then extra=0 end
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra< -2147483648 or extra>2147483647 then ai_unsupported('saved source extra_target malformed','olClan.saved_plan')end
  if value.current_targets~=nil and(type(value.current_targets)~='table'or next(value.current_targets)~=nil)then ai_unsupported('saved source current_targets not empty','olClan.saved_plan')end
  fields={isDummy=true,extra_target=extra,current_targets_empty=true}
 local names={}
 for _,p in ipairs(value.to)do if not AIValue.isPlayer(p)then ai_unsupported('saved source target not Player','olClan.saved_plan')end;names[#names+1]=p:objectName()end
 return r47_call(self,slot,'write',{selector=selector,targets=names,source_fields=fields})
end
function SmartAIView:readOlClanSavedSlot(slot)
 local r=r47_call(self,slot,'read',{})
 if r.status=='pass'then return{card=false}end
 if r.status~='plan'or type(r.wire)~='string'or not AIValue.isList(r.targets)then ai_unsupported('saved source plan result malformed','olClan.saved_plan')end
 local to={};for _,name in ipairs(r.targets)do local p=self.room:findPlayerByObjectName(name,true);if not p then ai_unsupported('saved source target not projected','olClan.saved_plan')end;to[#to+1]=p end
 -- The two fixed readers only call toString. This pure observation is neither a
 -- CardView nor an action descriptor; the normal response binder authorizes it.
 local wire=r.wire
 return{card={toString=function()return wire end,getLegacyStringKey=function()return wire end},to=to}
end
end

do
local slots={zulianzhuEp=true,zujieliTo=true}
local function bridge(self,slot,op,value)
 if not slots[slot]or type(ai_olclan_saved_slot)~='function'then ai_unsupported('finite OlClan Player bridge unavailable','olClan.saved_player')end
 local r=ai_olclan_saved_slot(slot,op,value)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'Player slot response unavailable','olClan.saved_player')end
 return r
end
function SmartAIView:writeOlClanPlayerSlot(slot,player)
 if not AIValue.isPlayer(player)then ai_unsupported('source assignment requires Player','olClan.saved_player')end
 return bridge(self,slot,'write',{target=player:objectName()})
end
function SmartAIView:readOlClanPlayerSlot(slot)
 local r=bridge(self,slot,'read',{})
 if r.status=='absent'then return nil end
 if r.status~='player'or type(r.target)~='string'then ai_unsupported('source Player read shape unavailable','olClan.saved_player')end
 local p=self.room:findPlayerByObjectName(r.target,true)
 if not p then ai_unsupported('source Player no longer in projected roster','olClan.saved_player')end
 return p
end
end

do
local function scalar(self,op,payload)
 if type(ai_olclan_saved_slot)~='function'then ai_unsupported('Zujiewu actual slot bridge unavailable','olClan.zujiewusuit')end
 local r=ai_olclan_saved_slot('zujiewusuit',op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'Zujiewu slot unavailable','olClan.zujiewusuit')end
 return r
end
function SmartAIView:writeOlClanSuitSlot(suit)
 if type(suit)~='string'then ai_unsupported('source suit string unavailable','olClan.zujiewusuit')end
 return scalar(self,'write',{value=suit})
end
function SmartAIView:readOlClanSuitSlot()
 local r=scalar(self,'read',{})
 if r.status=='absent'then return nil end
 if r.status~='value'or(type(r.value)~='string'and type(r.value)~='number'and type(r.value)~='boolean')then ai_unsupported('source scalar response malformed','olClan.zujiewusuit')end
 return r.value
end
end

-- R50 finite actual-Self scalar fields. Calls occur only at reached source reads/writes.
do
 local slots={wannawin=true,jiewq_lose=true,s3_fans_handou_card=true,s3_jxwj_ganglichoice=true,
  guanxu_friends=true,isfriend=true,qianlong_use=true,thwuyanDp=true,thwuyanHs=true,shilie_n=true,yuanrongIds=true}
 -- SmartAI kept these fields on its per-player object. This observer's memory is
 -- their isolated home, so they persist across the viewer's decisions.
 local function query(self,key,op,value)
  if getmetatable(self)~=SmartAIView or not slots[key] then
   error(AIUnsupported.new('source slot is not declared',tostring(key)),0)
  end
  local memory_key='source_slot:'..key
  local stored=self:recall(memory_key)
  if op=='read' then
   if type(stored)~='table' then return {known=true,type='nil'} end
   return {known=true,type=stored.type,value=stored.value}
  elseif op=='write' then
   if value.ids then self:remember(memory_key,{type='ids',value=value.ids})
   elseif value.type=='nil' then self:remember(memory_key,nil)
   else self:remember(memory_key,{type=value.type,value=value.value}) end
   return {known=true}
  elseif op=='reset' then
   self:remember(memory_key,{type='ids',value={}})
   return {known=true,type='ids'}
  end
  if type(stored)~='table' then return {known=true,type='nil'} end
  local ids=stored.type=='ids' and stored.value or {}
  if op=='length' then return {known=true,type='number',value=#ids} end
  if op=='contains' then
   for _,id in ipairs(ids) do if id==value.id then return {known=true,type='boolean',value=true} end end
   return {known=true,type='boolean',value=false}
  end
  if op=='append' then
   ids[#ids+1]=value.id
   self:remember(memory_key,{type='ids',value=ids})
   return {known=true,type='ids'}
  end
  error(AIUnsupported.new('source slot operation is unknown',key),0)
 end
 function SmartAIView:writeCurrentSourceSlot(key,value)
  local t=type(value)
  if t~='nil' and t~='boolean' and t~='number' and t~='string' then
   error(AIUnsupported.new('source slot requires a finite scalar',key),0)
  end
  if t=='number' and(value~=value or value==math.huge or value==-math.huge)then
   error(AIUnsupported.new('source slot nonfinite number',key),0)
  end
  query(self,key,'write',{type=t,value=value})
 end
 function SmartAIView:readCurrentSourceSlot(key)
  local row=query(self,key,'read',{})
  if row.type=='nil' then return nil end
  if (row.type=='boolean' or row.type=='string' or row.type=='number')and type(row.value)==row.type then return row.value end
  error(AIUnsupported.new('invalid source scalar result',key),0)
 end
 function SmartAIView:sourceIntListOperation(op,id)
  local row=query(self,'shilie_n',op,id~=nil and {id=id}or{})
  if row.type=='nil'then error("attempt to index a nil value (field 'shilie_n')",0)end
  if op=='length'or op=='contains'then
   if (op=='length'and row.type=='number'and type(row.value)=='number')or(op=='contains'and row.type=='boolean'and type(row.value)=='boolean')then return row.value end
   error(AIUnsupported.new('source IntList result ABI changed','shilie_n'),0)
  end
 end
 function SmartAIView:writeCurrentSourceIds(ids)
  if type(ids)~='table'then error(AIUnsupported.new('Yuanrong input list unavailable','yuanrongIds'),0)end
  local values={};for i,id in ipairs(ids)do if type(id)~='number'or id<0 or id%1~=0 then error(AIUnsupported.new('Yuanrong non-ID input','yuanrongIds'),0)end;values[i]=id end
  query(self,'yuanrongIds','write',{ids=values})
 end
 function SmartAIView:readCurrentSourceIds()
  local row=query(self,'yuanrongIds','read',{})
  if row.type=='nil'then return nil end
  if row.type=='ids'and type(row.value)=='table'then return row.value end
  error(AIUnsupported.new('Yuanrong actual ID list unavailable','yuanrongIds'),0)
 end

end

-- R53 two finite actual-gameplay-Self target slots.
do
 local slots={luochong_to=true,cl_to=true,diting_to=true,youlong_to=true,secondjinzhi_to=true,xiaoxinf_to=true,fengying_to=true,fuping_to=true,jiusiTo=true,fuhui_to=true,jg_to=true,mx_to=true,shouli_to=true,tj_to=true,shouxingTo=true,geassTarget=true,tychendeTo=true}
 -- SmartAI kept these targets on its per-player object. Like the scalar slots
 -- above, this observer's memory is their isolated home (player names only).
 local function query(self,key,op,value)
  if getmetatable(self)~=SmartAIView or not slots[key] then
   error(AIUnsupported.new('source target slot is not declared',tostring(key)),0)
  end
  local memory_key='source_target:'..key
  if op=='write' then
   self:remember(memory_key,value.type~='nil' and {type=value.type,value=value.value} or nil)
   return {known=true}
  elseif op=='clear' then
   self:remember(memory_key,nil)
   return {known=true}
  end
  local stored=self:recall(memory_key)
  if type(stored)~='table' then stored={type='nil'} end
  if op=='read' then return {known=true,type=stored.type,value=stored.value} end
  if op=='truth' then
   -- A stored player or target list is truthy, as the source field was.
   return {known=true,type='boolean',value=stored.type~='nil' and stored.value~=nil and stored.value~=false}
  end
  error(AIUnsupported.new('source target slot operation is unknown',key),0)
 end
 local function player(self,name,key)
  if type(name)~='string'then error(AIUnsupported.new('source target name malformed',key),0)end
  local p=self.room:findPlayerByObjectName(name,true)
  if not AIValue.isPlayer(p)then error(AIUnsupported.new('current source target not projected',key),0)end
  return p
 end
 function SmartAIView:writeCurrentSourceTarget(key,p)
  if (key=='shouxingTo'or key=='geassTarget'or key=='tychendeTo')and p==nil then query(self,key,'write',{type='nil'});return end
  if (key~='luochong_to'and key~='diting_to'and key~='xiaoxinf_to'and key~='tj_to'and key~='shouxingTo'and key~='geassTarget'and key~='tychendeTo')or not AIValue.isPlayer(p)then error(AIUnsupported.new('source Player assignment malformed',tostring(key)),0)end
  query(self,key,'write',{type='player',value=p:objectName()})
 end
 function SmartAIView:readCurrentSourceTarget(key)
  if key~='luochong_to'and key~='diting_to'and key~='xiaoxinf_to'and key~='tj_to'and key~='shouxingTo'and key~='geassTarget'and key~='tychendeTo'then error(AIUnsupported.new('source Player slot unavailable',tostring(key)),0)end
  local row=query(self,key,'read')
  if row.type=='nil'then return nil end
  if row.type=='player'then return player(self,row.value,key)end
  if(row.type=='boolean'or row.type=='number'or row.type=='string')and type(row.value)==row.type then return row.value end
  error(AIUnsupported.new('source Player result malformed',key),0)
 end
 function SmartAIView:currentSourceTargetPresent(key)
  if key~='shouxingTo'and key~='geassTarget'and key~='tychendeTo'then error(AIUnsupported.new('source Player truth unavailable',tostring(key)),0)end
  local row=query(self,key,'truth')
  if row.type~='boolean'or type(row.value)~='boolean'then error(AIUnsupported.new('source Player truth malformed',key),0)end
  return row.value
 end
 function SmartAIView:writeCurrentSourceTargets(key,values)
  if key~='cl_to'and key~='youlong_to'and key~='secondjinzhi_to'and key~='fengying_to'and key~='fuping_to'and key~='jiusiTo'and key~='fuhui_to'and key~='jg_to'and key~='mx_to'and key~='shouli_to'then error(AIUnsupported.new('source target list unavailable',tostring(key)),0)end
  if values==nil then query(self,key,'write',{type='nil'});return end
  if not AIValue.isList(values)then error(AIUnsupported.new('source target list assignment malformed',key),0)end
  local names={};for _,p in ipairs(values)do
   if not AIValue.isPlayer(p)then error(AIUnsupported.new('source target list contains non-Player',key),0)end
   names[#names+1]=p:objectName()
  end
  query(self,key,'write',{type='players',value=names})
 end
 function SmartAIView:currentSourceTargetsPresent(key)
  if key~='cl_to'and key~='fuping_to'and key~='jiusiTo'and key~='shouli_to'then error(AIUnsupported.new('source target list unavailable',tostring(key)),0)end
  local row=query(self,key,'truth')
  if row.type~='boolean'or type(row.value)~='boolean'then error(AIUnsupported.new('source slot truth malformed',key),0)end
  return row.value
 end
 function SmartAIView:readCurrentSourceTargets(key)
  if key~='cl_to'and key~='youlong_to'and key~='secondjinzhi_to'and key~='fengying_to'and key~='fuping_to'and key~='jiusiTo'and key~='fuhui_to'and key~='jg_to'and key~='mx_to'and key~='shouli_to'then error(AIUnsupported.new('source target list unavailable',tostring(key)),0)end
  local row=query(self,key,'read')
  if row.type=='nil'then return nil end
  if row.type~='players'or type(row.value)~='table'then error(AIUnsupported.new('source target list result malformed',key),0)end
  local out={};for _,name in ipairs(row.value)do out[#out+1]=player(self,name,key)end
  return AIList.new(out)
 end
 function SmartAIView:clearCurrentSourceTargets(key)
  if key~='cl_to'then error(AIUnsupported.new('source target list unavailable',tostring(key)),0)end
  query(self,key,'clear')
 end
end

-- R53: true shared tag prefix; unknown foreign/entry history stays unknown.
function SmartAIView:goodatwepRoomTag(op,target)
 if (op~='read'and op~='write')or(op=='write'and not AIValue.isPlayer(target))
  or(op=='read'and target~=nil)or type(ai_source_immediate_effect)~='function'then
  ai_unsupported('goodatwep source Room tag shape unavailable','goodatwep')
 end
 local row=ai_source_immediate_effect{source='goodatwep',op=op,target=target and target:objectName()or''}
 if AIUnsupported.is(row)then error(row,0)end
 if type(row)~='table'or row.known~=true then ai_unsupported(type(row)=='table'and row.reason or'goodatwep tag unknown','goodatwep')end
 if op=='read'then
  if type(row.value)~='string'then ai_unsupported('goodatwep QString result malformed','goodatwep')end
  return row.value
 end
end

-- R53 exact HTMS shared-tag prefix. No generic Room tag API or foreign memory.
function SmartAIView:yohaneRoomTag(key,op,value)
 if(key~='ai_yohane_card_id'and key~='ai_yohane_player')or(op~='write'and op~='take')
  or type(ai_source_immediate_effect)~='function'then ai_unsupported('Yohane tag operation unavailable',tostring(key))end
 if op=='take'and value~=nil then ai_unsupported('Yohane take has unexpected value',key)end
 if op=='write'then
  if key=='ai_yohane_card_id'then
   if type(value)~='number'or value%1~=0 or value<0 or value>2147483647 then ai_unsupported('Yohane ID malformed',key)end
  elseif type(value)~='string'then ai_unsupported('Yohane player name malformed',key)end
 end
 local row=ai_source_immediate_effect{source='yohane',key=key,op=op,value=value}
 if AIUnsupported.is(row)then error(row,0)end
 if type(row)~='table'or row.known~=true then ai_unsupported(type(row)=='table'and row.reason or'Yohane tag unknown',key)end
 if op=='take'then
  if key=='ai_yohane_card_id'then
   if type(row.value)~='number'or row.value%1~=0 or row.value<0 or row.value>2147483647 then ai_unsupported('Yohane returned ID malformed',key)end
   return row.value
  end
  if type(row.value)~='string'then ai_unsupported('Yohane returned player malformed',key)end
  local p=self.room:findPlayerByObjectName(row.value,true)
  if not p then ai_unsupported('Yohane tagged player unavailable',key)end
  return p
 end
end

-- R50 source-timed native prefix, never a staged strategy-memory effect.
function SmartAIView:sourceImmediateEffect(source,op,target,key,costs)
 if type(ai_source_immediate_effect)~='function' or not AIValue.isPlayer(target)then
  ai_unsupported('finite native source effect unavailable',source)
 end
 local ids={};for _,v in ipairs(costs or{})do ids[#ids+1]=type(v)=='number'and v or v:getEffectiveId()end
 local row=ai_source_immediate_effect{source=source,op=op,key=key,target=target:objectName(),subcards=ids}
 if AIUnsupported.is(row)then error(row,0)end
 if type(row)~='table'or row.known~=true then ai_unsupported(type(row)=='table'and row.reason or'native effect unknown',source..'.'..key)end
 if op=='read'then
  if source=='maji'then
   if type(row.value)~='boolean'then ai_unsupported('native source flag missing',key)end
  elseif type(row.value)~='number'or row.value%1~=0 or row.value< -2147483648 or row.value>2147483647 then
   ai_unsupported('native source mark missing',key)
  end
  return row.value
 end
 return true
end


-- R50 fixed Nyarz source consumers. Keys are existing native-issued recipes,
-- never reconstructed cards or selected authority.
function SmartAIView:round50CanSlash(card,target)
 local row=AIValue.isCard(card) and rawget(card,'_view')
 if type(row)~='table' or row.round50_source~='gfengying' or row.evaluation_owner~=self.player:objectName()
  or type(row.readonly_recipe_key)~='string' or row.readonly_recipe_key=='' or type(ai_card_target_filter)~='function' then
  ai_unsupported('exact Gfengying Slash query unavailable','gfengying')end
 local value=ai_card_target_filter(row.readonly_recipe_key,{},target:objectName(),'can_slash')
 if type(value)~='table' or type(value.accepted)~='boolean' then ai_unsupported(type(value)=='table' and value.error or 'exact Gfengying Slash result unavailable','gfengying')end
 return value.accepted
end
function SmartAIView:round50Prefix(card,prefix,target,operation)
 local row=AIValue.isCard(card) and rawget(card,'_view')
 if type(row)~='table' or row.round50_source~='jxyangjie' or row.evaluation_owner~=self.player:objectName()
  or type(row.readonly_recipe_key)~='string' or row.readonly_recipe_key=='' or type(ai_card_target_filter)~='function'
  or (operation~='target_filter' and operation~='is_prohibited')then ai_unsupported('exact Jxyangjie prefix query unavailable','jxyangjie')end
 local names={};for _,p in ipairs(prefix)do names[#names+1]=p:objectName()end
 local v
 if operation=='is_prohibited' then v=ai_card_target_filter(row.readonly_recipe_key,names,target:objectName(),'is_prohibited')
 else v=ai_card_target_filter(row.readonly_recipe_key,names,target:objectName())end
 if type(v)~='table' or type(v.accepted)~='boolean'then ai_unsupported(type(v)=='table' and v.error or 'prefix native result missing','jxyangjie')end
 return v.accepted
end
function SmartAIView:round50SkillDescription(skill,player)
 local value=nil -- Skill descriptions are not projected.
 if type(value)~='string'then ai_unsupported('actor-specific public skill description unavailable','chenfusui')end
 return value
end

-- Fixed Sushou raw SkillCard response. This is selected native authority, never
-- a readonly constructor or a generic notification payment capability.
function SmartAIView:bindSushouNotifiedCosts(wire)
 if self.request.kind~='use_card' or self.request.pattern~='@@sushou' or type(wire)~='string'
  or not wire:match('^@SushouCard=%d+[+%d]*$') or type(ai_resolve_conversion)~='function' then
  ai_unsupported('Sushou raw source binding unavailable','sushou.notified_costs')
 end
 local row=ai_resolve_conversion('@r51_sushou_raw_costs',0,{wire=wire})
 if type(row)~='table' or type(row.card_spec)~='table' or type(row.card_spec.conversion_id)~='number'
  or not AIValue.isList(row.targets) or #row.targets~=0 then
  ai_unsupported(type(row)=='table' and row.error or 'Sushou native receipt unavailable','sushou.notified_costs')
 end
 return {kind='use_card',card_spec=copy_value(row.card_spec),targets={}}
end

-- Exact kearjsrgqi3255 catalogue prefix. These are opaque printed references,
-- not live physical CardViews or selected-card authority.
do
 local refs=setmetatable({},{__mode='k'})
 local function q(self,op,input)
  if getmetatable(self)~=SmartAIView or type(ai_manjuan_source)~='function'then ai_unsupported('Manjuan printed source unavailable','kezhuanmanjuan')end
  local r=ai_manjuan_source(op,input or{})
  if type(r)~='table'or r.known~=true then ai_unsupported(type(r)=='table'and r.reason or'Manjuan printed result malformed','kezhuanmanjuan')end
  return r
 end
 function SmartAIView:manjuanPrintedCount()
  local n=q(self,'printed_count').value
  if type(n)~='number'or n<0 or n%1~=0 then ai_unsupported('Manjuan source count malformed','kezhuanmanjuan')end
  return n
 end
 function SmartAIView:manjuanPrintedStep(id)
  local r=q(self,'printed_step',{id=id});if r.exists==false then return nil end
  if r.exists~=true or type(r.identity)~='string'or r.identity==''then ai_unsupported('Manjuan printed reference malformed','kezhuanmanjuan')end
  local c={};refs[c]={self=self,request=self.request,id=id,identity=r.identity}
  local function ask(c,op,player)
   local v=refs[c];if not v or v.self.request~=v.request then ai_unsupported('Manjuan printed reference expired','kezhuanmanjuan')end
   local arg={id=v.id,identity=v.identity};if player then
    if not AIValue.isPlayer(player)then ai_unsupported('Manjuan printed owner malformed','kezhuanmanjuan')end
    arg.player=player:objectName()
   end
   return q(v.self,op,arg).value
  end
  function c:getNumber()local v=ask(self,'printed_number');if type(v)~='number'then ai_unsupported('Manjuan printed number malformed','kezhuanmanjuan')end;return v end
  function c:isAvailable(player)local v=ask(self,'printed_available',player);if type(v)~='boolean'then ai_unsupported('Manjuan printed availability malformed','kezhuanmanjuan')end;return v end
  return c
 end
end

-- R51: exact Manjuan current reference and actual-Self scalar. No CardView or
-- payment capability is created for an opaque catalogue index.
do
 local refs=setmetatable({},{__mode='k'})
 local function query(self,op,input)
  if getmetatable(self)~=SmartAIView or type(ai_manjuan_source)~='function'then ai_unsupported('Manjuan source endpoint unavailable','kezhuanmanjuan')end
  local row=ai_manjuan_source(op,input or{})
  if type(row)~='table'or row.known~=true then error(AIUnsupported.new(type(row)=='table'and row.reason or'Manjuan source result malformed','kezhuanmanjuan'),0)end
  return row
 end
 local function cardQuery(c,op,extra)
  local row=refs[c]
  if not row or row.self.request~=row.request then ai_unsupported('Manjuan reference no longer belongs to current request','kezhuanmanjuan')end
  local data={id=row.id,identity=row.identity}
  if extra then for k,v in pairs(extra)do data[k]=v end end
  return query(row.self,op,data).value
 end
 function SmartAIView:manjuanSourceCount()
  local n=query(self,'count').value
  if type(n)~='number'or n<0 or n%1~=0 then ai_unsupported('Manjuan native catalogue count malformed','kezhuanmanjuan')end
  return n
 end
 function SmartAIView:manjuanSourceStep(id)
  local row=query(self,'step',{id=id})
  if row.exists==false then return nil end
  if row.exists~=true or type(row.identity)~='string'or row.identity==''then ai_unsupported('Manjuan native reference malformed','kezhuanmanjuan')end
  local c={}
  refs[c]={self=self,request=self.request,id=id,identity=row.identity}
  function c:getNumber()local v=cardQuery(self,'number');if type(v)~='number'then ai_unsupported('Manjuan number result malformed','kezhuanmanjuan')end;return v end
  function c:isKindOf(class)local v=cardQuery(self,'kind',{class=class});if type(v)~='boolean'then ai_unsupported('Manjuan class result malformed','kezhuanmanjuan')end;return v end
  function c:objectName()local v=cardQuery(self,'name');if type(v)~='string'then ai_unsupported('Manjuan name result malformed','kezhuanmanjuan')end;return v end
  return c
 end
 function SmartAIView:manjuanSourceLocked(c,player)
  local row=refs[c]
  if not row or row.self~=self or not AIValue.isPlayer(player)then ai_unsupported('Manjuan current reference/player unavailable','kezhuanmanjuan')end
  local v=cardQuery(c,'locked',{player=player:objectName()})
  if type(v)~='boolean'then ai_unsupported('Manjuan locked result malformed','kezhuanmanjuan')end
  return v
 end
 function SmartAIView:readManjuanSourceId()
  local row=query(self,'read')
  if row.type=='nil'then return nil end
  if (row.type=='number'or row.type=='string'or row.type=='boolean')and type(row.value)==row.type then return row.value end
  ai_unsupported('Manjuan actual scalar result malformed','kezhuanmanjuan')
 end
end

-- R52: exact reached Rangyi clone/add then selected raw-question receipt.
do
 local pending=setmetatable({},{__mode='k'})
 local function bad(why)ai_unsupported(why,'twyj_rangyi.question')end
 local function stamp(self)
  local r=self.request;local ctx=self:getDecisionContext().round52_rangyi
  if type(r)~='table'or r.kind~='use_card'or r.pattern~='@@twyj_rangyi'or r.prompt~='@twyj_rangyi'
   or type(ctx)~='table'or ctx.known~=true or not AIValue.isPlayer(self.player)
   or self.player:objectName()~=r.viewer or type(ai_rangyi_question)~='function'then bad('Rangyi actual recipient question unavailable')end
  return {ai=self,request=r,player=self.player,viewer=r.viewer,decision=r.decision_id,revision=r.state_revision}
 end
 local function current(self,s)
  local n=stamp(self)
  if n.ai~=s.ai or n.request~=s.request or n.player~=s.player or n.viewer~=s.viewer
   or n.decision~=s.decision or n.revision~=s.revision then bad('Rangyi source question identity changed')end
 end
 function SmartAIView:prepareRangyiResponse(card)
  local s=stamp(self)
  if not AIValue.isCard(card)or card:isEvaluationOnly()or card:isVirtualCard()then bad('Rangyi requires a disclosed physical hand card')end
  local id=card:getEffectiveId()
  if type(id)~='number'or id<0 or id%1~=0 then bad('Rangyi material identity malformed')end
  local row=ai_rangyi_question({op='prepare',id=id});current(self,s)
  if type(row)~='table'or row.kind~='rangyi_readonly'or type(row.key)~='string'or row.key==''then bad(type(row)=='table'and row.error or'Rangyi native source clone unavailable')end
  local handle={};s.key=row.key;s.id=id;pending[handle]=s;return handle
 end
 function SmartAIView:selectRangyiResponse(handle,targets)
  local s=pending[handle]
  if not s then bad('Rangyi source clone identity missing')end
  current(self,s)
  if not AIValue.isList(targets)then bad('Rangyi source targets malformed')end
  local names={};for _,name in ipairs(targets)do if type(name)~='string'or name==''then bad('Rangyi source target name malformed')end;names[#names+1]=name end
  local row=ai_rangyi_question({op='select',key=s.key});current(self,s)
  local spec=type(row)=='table'and row.card_spec
  if type(row)~='table'or row.kind~='rangyi_native_question'or row.viewer~=s.viewer
   or row.decision_id~=s.decision or row.state_revision~=s.revision or type(spec)~='table'
   or type(spec.conversion_id)~='number'or spec.conversion_id<1 or spec.conversion_id%1~=0
   or spec.name~='twyj_rangyiUse'or spec.skill~=nil or type(spec.suit)~='number'or type(spec.number)~='number'
   or not AIValue.isList(spec.subcards)or #spec.subcards~=1 or spec.subcards[1]~=s.id then
   bad(type(row)=='table'and row.error or'Rangyi native receipt malformed')
  end
  pending[handle]=nil
  return {kind='use_card',card_spec=copy_value(spec),targets=names}
 end
end

-- R53 ordinary Collateral only. This is the actual native flag, not the
-- Original AI_needCrossbow shadow or a deferred strategy-effect overlay.
function SmartAIView:collateralCrossbowFlag(op,target,card)
 if type(ai_source_immediate_effect)~='function'or not AIValue.isPlayer(target)then
  ai_unsupported('native Collateral source flag unavailable','needCrossbow')
 end
 local selector=false
 if op=='set'then
  if not(AIValue.isCard(card)or AIValue.isConversion(card))then ai_unsupported('Collateral source Card absent','needCrossbow')end
  local v=rawget(card,'_view');if type(v)~='table'then ai_unsupported('Collateral source view absent','needCrossbow')end
  if type(v.readonly_recipe_key)=='string'and v.readonly_recipe_key~=''then selector={readonly_recipe_key=v.readonly_recipe_key}
  elseif type(v.effective_id)=='number'and v.effective_id>=0 and type(v.legacy_identity_token)=='string'and v.legacy_identity_token~=''then
   selector={physical_id=v.effective_id,legacy_identity_token=v.legacy_identity_token}
  else ai_unsupported('Collateral source has no current native identity','needCrossbow')end
 end
 local row=ai_source_immediate_effect{source='ordinary_collateral',op=op,target=target:objectName(),card=selector}
 if AIUnsupported.is(row)then error(row,0)end
 if type(row)~='table'or row.known~=true then ai_unsupported(type(row)=='table'and row.reason or'native Collateral flag unknown','needCrossbow')end
 if op=='read'then if type(row.value)~='boolean'then ai_unsupported('native Collateral flag value absent','needCrossbow')end;return row.value end
 return true
end

-- R53 exact actual-own Diou saved plan; never reconstruct a remembered spec.
do
local r47_slots={diouUse=true}
local function r47_call(self,slot,op,payload)
 if not r47_slots[slot]or type(ai_olclan_saved_slot)~='function'then ai_unsupported('finite saved-plan bridge unavailable','diou.saved_plan')end
 local r=ai_olclan_saved_slot(slot,op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'saved-plan bridge returned no observation','diou.saved_plan')end
 if type(r.source_error)=='string'then error(r.source_error,0)end
 return r
end
function SmartAIView:writeDiouSavedPlan(value)
 local slot="diouUse";local actualCard=type(value)=="table"and value.card
 if not r47_slots[slot]then ai_unsupported('unknown saved source slot','diou.saved_plan')end
 if type(value)~='table'or(not AIValue.isCard(actualCard)and not AIValue.isConversion(actualCard))then ai_unsupported('source plan/Card shape unavailable','diou.saved_plan')end
 local view=rawget(actualCard,'_view');if type(view)~='table'then ai_unsupported('saved Card native identity absent','diou.saved_plan')end
 local selector
 if type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then selector={readonly_recipe_key=view.readonly_recipe_key}
 elseif AIValue.isConversion(actualCard)then selector={conversion_id=actualCard:getConversionId(),legacy_identity_token=view.legacy_identity_token}
 else selector={physical_id=actualCard:getEffectiveId(),legacy_identity_token=view.legacy_identity_token}end
 local fields
  local internal={_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  local source={card=true,to=true,isDummy=true,extra_target=true,current_targets=true}
  for k in pairs(value)do if not internal[k]and not source[k]then ai_unsupported('saved dummy field has no exact representation: '..tostring(k),'diou.saved_plan')end end
  if value.isDummy~=true or not AIValue.isList(value.to)then ai_unsupported('saved source dummy shape unavailable','diou.saved_plan')end
  local extra=value.extra_target;if extra==nil then extra=0 end
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra< -2147483648 or extra>2147483647 then ai_unsupported('saved source extra_target malformed','diou.saved_plan')end
  if value.current_targets~=nil and(type(value.current_targets)~='table'or next(value.current_targets)~=nil)then ai_unsupported('saved source current_targets not empty','diou.saved_plan')end
  fields={isDummy=true,extra_target=extra,current_targets_empty=true}
 local names={}
 for _,p in ipairs(value.to)do if not AIValue.isPlayer(p)then ai_unsupported('saved source target not Player','diou.saved_plan')end;names[#names+1]=p:objectName()end
 return r47_call(self,slot,'write',{selector=selector,targets=names,source_fields=fields})
end
function SmartAIView:readDiouSavedPlan()
 local slot="diouUse"
 local r=r47_call(self,slot,'read',{})
 if r.status~='plan'or type(r.wire)~='string'or not AIValue.isList(r.targets)then ai_unsupported('saved source plan result malformed','diou.saved_plan')end
 local to={};for _,name in ipairs(r.targets)do local p=self.room:findPlayerByObjectName(name,true);if not p then ai_unsupported('saved source target not projected','diou.saved_plan')end;to[#to+1]=p end
 -- The fixed Diou reader only calls toString after its target loop. This pure observation is neither a
 -- CardView nor an action descriptor; the normal response binder authorizes it.
 local wire=r.wire
 return{card={toString=function()return wire end,getLegacyStringKey=function()return wire end},to=to}
end
end

-- Fixed Xufa source first proposal and raw-wire selection. No GUI viewAs replay.
do
 local function call(self,op,payload)
  if type(ai_xufa_actual_slot)~='function'then ai_unsupported('Xufa source endpoint unavailable','xufa')end
  local r=ai_xufa_actual_slot(op,payload)
  if AIUnsupported.is(r)then error(r,0)end
  if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'Xufa source result missing','xufa')end
  return r
 end
 function SmartAIView:evaluateXufaFirst(costs)
  if not AIValue.isList(costs)then ai_unsupported('Xufa first costs are not ordered source IDs','xufa')end
  local stamp=turn_snapshot(self)
  local r=call(self,'first_construct',{costs=copy_value(costs)})
  if r.evaluation_only~=true or type(r.card)~='table'or r.card.evaluation_only~=true
   or type(r.card.readonly_recipe_key)~='string'or type(r.candidate)~='table'
   or r.card.class_name~='XufaCard'or r.card.skill_name~='xufa'
   or not turn_same(r.card.subcards,costs)then ai_unsupported('Xufa first source identity incomplete','xufa')end
  local c=CardView.new(copy_value(r.card));c._evaluation_candidate=copy_value(r.candidate)
  local entries=readonly_turn_cards[self];if not entries then entries=setmetatable({}, {__mode='k'});readonly_turn_cards[self]=entries end
  entries[c]={skill='xufa',class_name='XufaCard',binder='xufa_raw',costs=copy_value(costs),request=self.request,stamp=stamp,
   source=nil,skill_request=nil,face=copy_value(c._view),candidate=copy_value(c._evaluation_candidate),available=r.card.available}
  c.toCardSpec=function()ai_unsupported('Xufa source hypothesis is not a receipt','xufa')end
  return c
 end
 local function checked(r)
  if type(r.card_spec)~='table'or type(r.card_spec.conversion_id)~='number'or not AIValue.isList(r.targets)then
   ai_unsupported('Xufa selected raw-source receipt missing','xufa')end
  return r
 end
 function SmartAIView:materializeXufaFirst(card)
  local entry=turn_saved(self,card)
  if entry.binder~='xufa_raw'then ai_unsupported('Xufa first source is not this request proposal','xufa')end
  local r=checked(call(self,'first_select',{recipe_key=entry.face.readonly_recipe_key}))
  turn_saved(self,card)
  if #r.targets~=0 or r.card_spec.name~=card:objectName()or r.card_spec.suit~=card:getSuit()
   or r.card_spec.number~=card:getNumber()or r.card_spec.skill~=card:getSkillName(false)
   or not turn_same(r.card_spec.subcards,card:getSubcards())then ai_unsupported('Xufa raw reconstruction changed source face/costs','xufa')end
  local row=copy_value(entry.face);for k,v in pairs(entry.candidate)do row[k]=copy_value(v)end
  row.kind_of_names=copy_value(row.kind_of);row.conversion_id=r.card_spec.conversion_id
  row.evaluation_only=false;row.readonly_recipe_key=nil
  row.cost_count=0 -- exact bound sequence, not a rebindable cost catalogue
  -- A raw V1 receipt carries no fabricated instance/root. Its exact native
  -- CardUseStruct is authenticated by the Room-owned receipt on final apply.
  row.activation_skill=r.card_spec.skill;row.activation_instance=0;row.activation_owner=self.player:objectName()
  row.source_skill=r.card_spec.skill;row.source_instance=0;row.source_owner=self.player:objectName()
  local paid=ConversionView.new(row);local spec=copy_value(r.card_spec)
  paid.toCardSpec=function()return copy_value(spec)end
  self._indexes.conversions_by_id[row.conversion_id]=copy_value(row)
  return paid
 end
 function SmartAIView:materializeXufaSaved(card,names)
  -- This remembered value is a proposal, never a retained native Card or ticket.
  local r=checked(call(self,'value_select',{card=copy_value(card),targets=copy_value(names)}))
  if not turn_same(r.targets,names)then ai_unsupported('Xufa selected target order changed','xufaUse')end
  return{kind='use_card',card_spec=copy_value(r.card_spec),targets=copy_value(r.targets)}
 end
end

-- Finite reached source-global copies; downstream reads require their own authority.
function SmartAIView:copyNamedSourcePriority(key,card,source_class)
 if key~='YoulongCard'and key~='SecondJinzhiCard'and key~='genshunoYURICard'then ai_unsupported('priority target is outside fixed source catalog',key)end
 if not AIValue.isCard(card)or type(source_class)~='string'then ai_unsupported('priority source Card missing',key)end
 local v=rawget(card,'_view');local selector
 if type(v)=='table'and type(v.readonly_recipe_key)=='string'and v.readonly_recipe_key~=''then
  selector={readonly_recipe_key=v.readonly_recipe_key}
 elseif key=='YoulongCard'and type(v)=='table'and v.evaluation_only==true and type(v.name)=='string'
  and type(self.world.evaluation_cards)=='table'and type(self.world.evaluation_cards[v.name])=='table'then
  selector={printed_name=v.name}
 else ai_unsupported('priority source lacks exact current issued descriptor',key)end
 if type(ai_response_choice_continuity)~='function'then ai_unsupported('actual priority copy unavailable',key)end
 local r=ai_response_choice_continuity{op='source_priority',key=key,card=selector,source_class=source_class}
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.known~=true or r.written~=true then ai_unsupported('actual priority copy is not admitted',key)end
end

-- R53b exact actual own Zhuning plan and false proposal prefix.
do
local r47_slots={zhuning_d=true}
local function r47_call(self,slot,op,payload)
 if not r47_slots[slot]or type(ai_olclan_saved_slot)~='function'then ai_unsupported('finite saved-plan bridge unavailable','zhuning.saved_plan')end
 local r=ai_olclan_saved_slot(slot,op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'saved-plan bridge returned no observation','zhuning.saved_plan')end
 if type(r.source_error)=='string'then error(r.source_error,0)end
 return r
end
function SmartAIView:writeZhuningSavedPlan(value)
 local slot="zhuning_d";local actualCard=type(value)=="table"and value.card
 if not r47_slots[slot]then ai_unsupported('unknown saved source slot','zhuning.saved_plan')end
 if type(value)~='table'or(actualCard~=nil and actualCard~=false and not AIValue.isCard(actualCard)and not AIValue.isConversion(actualCard))then ai_unsupported('source plan/Card shape unavailable','zhuning.saved_plan')end
 local cardState=actualCard==nil and'nil'or actualCard==false and'false'or'card'
 local view=cardState=='card'and rawget(actualCard,'_view')or{};if type(view)~='table'then ai_unsupported('saved Card native identity absent','zhuning.saved_plan')end
 local selector={}
 if cardState~='card'then
 elseif type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then selector={readonly_recipe_key=view.readonly_recipe_key}
 elseif AIValue.isConversion(actualCard)then selector={conversion_id=actualCard:getConversionId(),legacy_identity_token=view.legacy_identity_token}
 else selector={physical_id=actualCard:getEffectiveId(),legacy_identity_token=view.legacy_identity_token}end
 local fields
  local internal={_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  local source={card=true,to=true,isDummy=true,extra_target=true,current_targets=true}
  for k in pairs(value)do if not internal[k]and not source[k]then ai_unsupported('saved dummy field has no exact representation: '..tostring(k),'zhuning.saved_plan')end end
  if value.isDummy~=true or not AIValue.isList(value.to)then ai_unsupported('saved source dummy shape unavailable','zhuning.saved_plan')end
  local extra=value.extra_target;if extra==nil then extra=0 end
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra< -2147483648 or extra>2147483647 then ai_unsupported('saved source extra_target malformed','zhuning.saved_plan')end
  if value.current_targets~=nil and(type(value.current_targets)~='table'or next(value.current_targets)~=nil)then ai_unsupported('saved source current_targets not empty','zhuning.saved_plan')end
  fields={isDummy=true,extra_target=extra,current_targets_empty=true}
 local names={}
 for _,p in ipairs(value.to)do if not AIValue.isPlayer(p)then ai_unsupported('saved source target not Player','zhuning.saved_plan')end;names[#names+1]=p:objectName()end
 return r47_call(self,slot,'write',{selector=selector,targets=names,source_fields=fields,card_state=cardState})
end
function SmartAIView:readZhuningSavedPlan()
 local slot="zhuning_d"
 local r=r47_call(self,slot,'read',{})
 if r.status=='absent'then return nil end
 if r.status~='plan'or type(r.wire)~='string'or not AIValue.isList(r.targets)then ai_unsupported('saved source plan result malformed','zhuning.saved_plan')end
 local to={};for _,name in ipairs(r.targets)do local p=self.room:findPlayerByObjectName(name,true);if not p then ai_unsupported('saved source target not projected','zhuning.saved_plan')end;to[#to+1]=p end
 -- The fixed Diou reader only calls toString after its target loop. This pure observation is neither a
 -- CardView nor an action descriptor; the normal response binder authorizes it.
 local wire=r.wire
 return{card={toString=function()return wire end,getLegacyStringKey=function()return wire end},to=to}
end
end
-- Fixed Xuanzhu own native source slot; no global policy continuation.
do
 local function host(self,mode,payload)
  if type(ai_xuanzhu_actual_slot)~='function'then ai_unsupported('Xuanzhu native slot bridge missing','xuanzhuUse')end
  local r=ai_xuanzhu_actual_slot(mode,payload or{})
  if AIUnsupported.is(r)then error(r,0)end
  if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'Xuanzhu native observation missing','xuanzhuUse')end
  return r
 end
 local call=host
 local function checked(r)
  if type(r.card_spec)~='table'or type(r.card_spec.conversion_id)~='number'or not AIValue.isList(r.targets)then ai_unsupported('Xuanzhu selected receipt malformed','xuanzhuUse')end
  return r
 end
 local function card_result(r)
  if r.evaluation_only~=true or type(r.card)~='table'or r.card.evaluation_only~=true or type(r.card.readonly_recipe_key)~='string'then ai_unsupported('Xuanzhu exact readonly custody absent','xuanzhuUse')end
  local c=CardView.new(copy_value(r.card));c._evaluation_candidate=copy_value(r.candidate);return c
 end
 function SmartAIView:evaluateXuanzhuSource(name)
  local r=host(self,'construct',{name=name});if r.exists==false then return nil end;return card_result(r)
 end
 function SmartAIView:rememberActualXuanzhuUse(d)
  if type(d)~='table'or d.isDummy~=true or not AIValue.isList(d.to)then ai_unsupported('Xuanzhu source dummy shape missing','xuanzhuUse')end
  local c=d.card;local v=type(c)=='table'and rawget(c,'_view')
  if (not AIValue.isCard(c)and not AIValue.isConversion(c))or type(v)~='table'then ai_unsupported('Xuanzhu source selected Card unavailable','xuanzhuUse')end
  local permitted={card=true,to=true,isDummy=true,extra_target=true,current_targets=true,_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  for k in pairs(d)do if not permitted[k]then ai_unsupported('Xuanzhu source dummy field has no native representation: '..tostring(k),'xuanzhuUse')end end
  local extra=d.extra_target;if extra==nil then extra=0 end
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra < -2147483648 or extra > 2147483647 then ai_unsupported('Xuanzhu dummy extra_target malformed','xuanzhuUse')end
  if d.current_targets~=nil and(type(d.current_targets)~='table'or next(d.current_targets)~=nil)then ai_unsupported('Xuanzhu nonempty current_targets unsupported','xuanzhuUse')end
  local selector
  if type(v.readonly_recipe_key)=='string'and v.readonly_recipe_key~=''then selector={readonly_recipe_key=v.readonly_recipe_key}
  elseif AIValue.isConversion(c)then selector={conversion_id=c:getConversionId(),legacy_identity_token=v.legacy_identity_token}
  else selector={physical_id=c:getEffectiveId(),legacy_identity_token=v.legacy_identity_token}end
  local names={};for _,p in ipairs(d.to)do if not AIValue.isPlayer(p)then ai_unsupported('Xuanzhu source target is not a player','xuanzhuUse')end;names[#names+1]=p:objectName()end
  local r=host(self,'capture',{selector=selector,targets=names,source_fields={isDummy=true,extra_target=extra,current_targets_empty=true}})
  if type(r.token)~='string'or r.token==''then ai_unsupported('Xuanzhu actual assignment was not witnessed','xuanzhuUse')end
  return r.token
 end
 function SmartAIView:evaluateXuanzhuFirst()
  local stamp=turn_snapshot(self)
  local r=call(self,'first_construct',{})
  if r.evaluation_only~=true or type(r.card)~='table'or r.card.evaluation_only~=true
   or type(r.card.readonly_recipe_key)~='string'or type(r.candidate)~='table'
   or r.card.class_name~='Xuanzhu2Card'or r.card.skill_name~='xuanzhu2'
   or not turn_same(r.card.subcards,{})then ai_unsupported('Xuanzhu first source identity incomplete','xuanzhu')end
  local c=CardView.new(copy_value(r.card));c._evaluation_candidate=copy_value(r.candidate)
  local entries=readonly_turn_cards[self];if not entries then entries=setmetatable({}, {__mode='k'});readonly_turn_cards[self]=entries end
  entries[c]={skill='xuanzhu',class_name='Xuanzhu2Card',binder='xuanzhu_raw',costs={},request=self.request,stamp=stamp,
   source=nil,skill_request=nil,face=copy_value(c._view),candidate=copy_value(c._evaluation_candidate),available=r.card.available}
  c.toCardSpec=function()ai_unsupported('Xuanzhu source hypothesis is not a receipt','xuanzhu')end
  return c
 end
 local function checked(r)
  if type(r.card_spec)~='table'or type(r.card_spec.conversion_id)~='number'or not AIValue.isList(r.targets)then
   ai_unsupported('Xuanzhu selected raw-source receipt missing','xuanzhu')end
  return r
 end
 function SmartAIView:materializeXuanzhuFirst(card)
  local entry=turn_saved(self,card)
  if entry.binder~='xuanzhu_raw'then ai_unsupported('Xuanzhu first source is not this request proposal','xuanzhu')end
  local r=checked(call(self,'first_select',{recipe_key=entry.face.readonly_recipe_key}))
  turn_saved(self,card)
  if #r.targets~=0 or r.card_spec.name~=card:objectName()or r.card_spec.suit~=card:getSuit()
   or r.card_spec.number~=card:getNumber()or r.card_spec.skill~=card:getSkillName(false)
   or not turn_same(r.card_spec.subcards,card:getSubcards())then ai_unsupported('Xuanzhu raw reconstruction changed source face/costs','xuanzhu')end
  local row=copy_value(entry.face);for k,v in pairs(entry.candidate)do row[k]=copy_value(v)end
  row.kind_of_names=copy_value(row.kind_of);row.conversion_id=r.card_spec.conversion_id
  row.evaluation_only=false;row.readonly_recipe_key=nil
  row.cost_count=0 -- exact bound sequence, not a rebindable cost catalogue
  -- A raw V1 receipt carries no fabricated instance/root. Its exact native
  -- CardUseStruct is authenticated by the Room-owned receipt on final apply.
  row.activation_skill=r.card_spec.skill;row.activation_instance=0;row.activation_owner=self.player:objectName()
  row.source_skill=r.card_spec.skill;row.source_instance=0;row.source_owner=self.player:objectName()
  local paid=ConversionView.new(row);local spec=copy_value(r.card_spec)
  paid.toCardSpec=function()return copy_value(spec)end
  self._indexes.conversions_by_id[row.conversion_id]=copy_value(row)
  return paid
 end
 function SmartAIView:readActualXuanzhuUse(include_card)
  if type(include_card)~='boolean'then ai_unsupported('Xuanzhu source card-read branch missing','xuanzhuUse')end
  local r=host(self,'read',{include_card=include_card})
  if r.status=='nil_plan'then return nil end
  if r.status=='boolean_plan'then return false end
  if r.status=='nil_targets'then return{}end
  if r.status=='boolean_targets'then return{to=false}end
  if not AIValue.isList(r.targets)then ai_unsupported('Xuanzhu target observation malformed','xuanzhuUse')end
  local d={to=AIList.new{}}
  for _,name in ipairs(r.targets)do local p=self.room:findPlayerByObjectName(name,true);if not p then ai_unsupported('Xuanzhu target left current roster','xuanzhuUse')end;d.to:append(p)end
  if not include_card then
   if r.status~='targets'then ai_unsupported('Xuanzhu empty-hand read returned a card','xuanzhuUse')end
   return d
  end
  if r.status=='nil_card'then return d end
  if r.status=='boolean_card'then d.card=false;return d end
  if r.status~='card'or type(r.name)~='string'then ai_unsupported('Xuanzhu actual Card name unavailable','xuanzhuUse')end
  d.card={objectName=function()return r.name end};return d
 end
 function SmartAIView:materializeXuanzhuSaved(material,name,targets)
  local r=checked(host(self,'saved_select',{material=material,name=name,targets=copy_value(targets)}))
  if not turn_same(r.targets,targets)or not turn_same(r.card_spec.subcards,{material})or r.card_spec.skill~='xuanzhu'then ai_unsupported('Xuanzhu selected source cost/targets/rawskill changed','xuanzhuUse')end
  return{kind='use_card',card_spec=copy_value(r.card_spec),targets=copy_value(r.targets)}
 end
end

-- Fixed Chuli/heg_yanxi actual Self scalar map. No userdata or map shadow crosses VMs.
do
 function SmartAIView:chuliSourceMap(op,player,id)
  if getmetatable(self)~=SmartAIView or type(ai_current_source_slot)~='function'
   or(op~='reset'and op~='set'and op~='state'and op~='entry')then
   error(AIUnsupported.new('Chuli actual map host unavailable','chuli_id_choice'),0)
  end
  local args={}
  if op=='set'or op=='entry'then
   if type(player)=='string'then args.player=player
   elseif AIValue.isPlayer(player)then args.player=player:objectName()
   else error(AIUnsupported.new('Chuli map requires a current player key','chuli_id_choice'),0)end
   if op=='set'then
    if type(id)~='number'or id<0 or id%1~=0 then
     error(AIUnsupported.new('Chuli original selected ID is unavailable; anonymous recommendations cannot populate its scalar map','chuli_id_choice'),0)
    end
    args.id=id
   end
  end
  local r=ai_current_source_slot('chuli_id_choice',op,args)
  if type(r)~='table'or r.known~=true then error(AIUnsupported.new(type(r)=='table'and r.reason or'Chuli source map response invalid','chuli_id_choice'),0)end
  if op=='reset'or op=='set'then
   if r.type=='nil_map'then error("attempt to index a nil value (field 'chuli_id_choice')",0)end
   return
  end
  if r.type=='nil_map'then error("attempt to index a nil value (field 'chuli_id_choice')",0)end
  if r.type=='nil'then return nil end
  if op=='state'and r.type=='map'then return true end
  if op=='state'and r.type=='boolean'and type(r.value)=='boolean'then return r.value end
  if op=='entry'and r.type=='number'and type(r.value)=='number'then return r.value end
  error(AIUnsupported.new('Chuli actual map scalar ABI changed','chuli_id_choice'),0)
 end
end

-- R53 exact actual-own Tyfenwu saved plan; never reconstruct a remembered spec.
do
local r47_slots={tyfenwuUse=true}
local function r47_call(self,slot,op,payload)
 if not r47_slots[slot]or type(ai_olclan_saved_slot)~='function'then ai_unsupported('finite saved-plan bridge unavailable','tyfenwu.saved_plan')end
 local r=ai_olclan_saved_slot(slot,op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'saved-plan bridge returned no observation','tyfenwu.saved_plan')end
 if type(r.source_error)=='string'then error(r.source_error,0)end
 return r
end
function SmartAIView:writeTyfenwuSavedPlan(value)
 local slot="tyfenwuUse";local actualCard=type(value)=="table"and value.card
 if not r47_slots[slot]then ai_unsupported('unknown saved source slot','tyfenwu.saved_plan')end
 if type(value)~='table'or(not AIValue.isCard(actualCard)and not AIValue.isConversion(actualCard))then ai_unsupported('source plan/Card shape unavailable','tyfenwu.saved_plan')end
 local view=rawget(actualCard,'_view');if type(view)~='table'then ai_unsupported('saved Card native identity absent','tyfenwu.saved_plan')end
 local selector
 if type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then selector={readonly_recipe_key=view.readonly_recipe_key}
 elseif AIValue.isConversion(actualCard)then selector={conversion_id=actualCard:getConversionId(),legacy_identity_token=view.legacy_identity_token}
 else selector={physical_id=actualCard:getEffectiveId(),legacy_identity_token=view.legacy_identity_token}end
 local fields
  local internal={_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  local source={card=true,to=true,isDummy=true,extra_target=true,current_targets=true}
  for k in pairs(value)do if not internal[k]and not source[k]then ai_unsupported('saved dummy field has no exact representation: '..tostring(k),'tyfenwu.saved_plan')end end
  if value.isDummy~=true or not AIValue.isList(value.to)then ai_unsupported('saved source dummy shape unavailable','tyfenwu.saved_plan')end
  local extra=value.extra_target;if extra==nil then extra=0 end
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra< -2147483648 or extra>2147483647 then ai_unsupported('saved source extra_target malformed','tyfenwu.saved_plan')end
  if value.current_targets~=nil and(type(value.current_targets)~='table'or next(value.current_targets)~=nil)then ai_unsupported('saved source current_targets not empty','tyfenwu.saved_plan')end
  fields={isDummy=true,extra_target=extra,current_targets_empty=true}
 local names={}
 for _,p in ipairs(value.to)do if not AIValue.isPlayer(p)then ai_unsupported('saved source target not Player','tyfenwu.saved_plan')end;names[#names+1]=p:objectName()end
 return r47_call(self,slot,'write',{selector=selector,targets=names,source_fields=fields})
end
function SmartAIView:readTyfenwuSavedPlan()
 local slot="tyfenwuUse"
 local r=r47_call(self,slot,'read',{})
 if r.status=='pass'then return{card=false}end
 if r.status~='plan'or type(r.wire)~='string'or type(r.class_name)~='string'or type(r.spec)~='table'or not AIValue.isList(r.targets)then ai_unsupported('Tyfenwu source observation malformed','tyfenwu.saved_plan')end
 local to=AIList.new{};for _,name in ipairs(r.targets)do local p=self.room:findPlayerByObjectName(name,true);if not p then ai_unsupported('Tyfenwu target not projected','tyfenwu.saved_plan')end;to:append(p)end
 local observed={wire=r.wire,spec=copy_value(r.spec),class_name=r.class_name,physical_id=r.physical_id}
 return{card=observed,to=to}

end
end

function SmartAIView:evaluateTyfenwuSource(name,id)
 return self:evaluateOwnerViewAsCard{source_key='tyfenwu',name=name,skill='_tyfenwu',suit=6,number=0,subcards={id}}
end
function SmartAIView:materializeTyfenwuSaved(card,targets)
 if type(card.physical_id)=='number'and card.physical_id>=0 then
  local c=self:getKnownCardById(card.physical_id)
  if not c or c:getLegacyStringKey()~=card.wire then ai_unsupported('Tyfenwu physical replacement is no longer exact disclosed source','tyfenwu.saved_plan')end
  return{kind='use_card',card_id=card.physical_id,targets=copy_value(targets)}
 end
 if card.spec.skill~='_tyfenwu'then ai_unsupported('Tyfenwu saved replacement needs its actual different provider','tyfenwu.saved_plan')end
 local paid=self:bindOriginalSelectedConversion(copy_value(card.spec),card.class_name,'tyfenwu')
 if paid:getLegacyStringKey()~=card.wire then ai_unsupported('Tyfenwu fresh provider changed exact source wire','tyfenwu.saved_plan')end
 return{kind='use_card',card_spec=paid:toCardSpec(),targets=copy_value(targets)}
end

-- R53 exact actual-own Tyqingkou saved plan; never reconstruct a remembered spec.
do
local r47_slots={tyqingkouUse=true}
local function r47_call(self,slot,op,payload)
 if not r47_slots[slot]or type(ai_olclan_saved_slot)~='function'then ai_unsupported('finite saved-plan bridge unavailable','tyqingkou.saved_plan')end
 local r=ai_olclan_saved_slot(slot,op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'saved-plan bridge returned no observation','tyqingkou.saved_plan')end
 if type(r.source_error)=='string'then error(r.source_error,0)end
 return r
end
function SmartAIView:writeTyqingkouSavedPlan(value)
 local slot="tyqingkouUse";local actualCard=type(value)=="table"and value.card
 if not r47_slots[slot]then ai_unsupported('unknown saved source slot','tyqingkou.saved_plan')end
 if type(value)~='table'or(not AIValue.isCard(actualCard)and not AIValue.isConversion(actualCard))then ai_unsupported('source plan/Card shape unavailable','tyqingkou.saved_plan')end
 local view=rawget(actualCard,'_view');if type(view)~='table'then ai_unsupported('saved Card native identity absent','tyqingkou.saved_plan')end
 local selector
 if type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then selector={readonly_recipe_key=view.readonly_recipe_key}
 elseif AIValue.isConversion(actualCard)then selector={conversion_id=actualCard:getConversionId(),legacy_identity_token=view.legacy_identity_token}
 else selector={physical_id=actualCard:getEffectiveId(),legacy_identity_token=view.legacy_identity_token}end
 local fields
  local internal={_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  local source={card=true,to=true,isDummy=true,extra_target=true,current_targets=true}
  for k in pairs(value)do if not internal[k]and not source[k]then ai_unsupported('saved dummy field has no exact representation: '..tostring(k),'tyqingkou.saved_plan')end end
  if value.isDummy~=true or not AIValue.isList(value.to)then ai_unsupported('saved source dummy shape unavailable','tyqingkou.saved_plan')end
  local extra=value.extra_target;if extra==nil then extra=0 end
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra< -2147483648 or extra>2147483647 then ai_unsupported('saved source extra_target malformed','tyqingkou.saved_plan')end
  if value.current_targets~=nil and(type(value.current_targets)~='table'or next(value.current_targets)~=nil)then ai_unsupported('saved source current_targets not empty','tyqingkou.saved_plan')end
  fields={isDummy=true,extra_target=extra,current_targets_empty=true}
 local names={}
 for _,p in ipairs(value.to)do if not AIValue.isPlayer(p)then ai_unsupported('saved source target not Player','tyqingkou.saved_plan')end;names[#names+1]=p:objectName()end
 return r47_call(self,slot,'write',{selector=selector,targets=names,source_fields=fields})
end
function SmartAIView:readTyqingkouSavedPlan()
 local slot="tyqingkouUse"
 local r=r47_call(self,slot,'read',{})
 if r.status=='pass'then return{card=false}end
 if r.status~='plan'or type(r.wire)~='string'or type(r.class_name)~='string'or type(r.spec)~='table'or not AIValue.isList(r.targets)then ai_unsupported('Tyqingkou source observation malformed','tyqingkou.saved_plan')end
 local to=AIList.new{};for _,name in ipairs(r.targets)do local p=self.room:findPlayerByObjectName(name,true);if not p then ai_unsupported('Tyqingkou target not projected','tyqingkou.saved_plan')end;to:append(p)end
 local observed={wire=r.wire,spec=copy_value(r.spec),class_name=r.class_name,physical_id=r.physical_id}
 return{card=observed,to=to}

end
end

function SmartAIView:evaluateTyqingkouSource(name,id)
 return self:evaluateOwnerViewAsCard{source_key='tyqingkou',name=name,skill='_tyqingkou',suit=6,number=0,subcards={id}}
end
function SmartAIView:materializeTyqingkouSaved(card,targets)
 if type(card.physical_id)=='number'and card.physical_id>=0 then
  local c=self:getKnownCardById(card.physical_id)
  if not c or c:getLegacyStringKey()~=card.wire then ai_unsupported('Tyqingkou physical replacement is no longer exact disclosed source','tyqingkou.saved_plan')end
  return{kind='use_card',card_id=card.physical_id,targets=copy_value(targets)}
 end
 if card.spec.skill~='_tyqingkou'then ai_unsupported('Tyqingkou saved replacement needs its actual different provider','tyqingkou.saved_plan')end
 -- Original raw Card::Parse submits its material/targets to the V2 resolver.
 -- That resolver replaces the old card with the current native factory product;
 -- it does not require the old raw underscore/name/face to equal the rebuilt card.
 local paid=self:bindSkillCard('tyqingkou',copy_value(card.spec.subcards))
 return{kind='use_card',card_spec=paid:toCardSpec(),targets=copy_value(targets)}
end

do
local r47_slots={gengduUse=true}
local function r47_call(self,slot,op,payload)
 if not r47_slots[slot]or type(ai_olclan_saved_slot)~='function'then ai_unsupported('finite saved-plan bridge unavailable','gengdu.saved_plan')end
 local r=ai_olclan_saved_slot(slot,op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'saved-plan bridge returned no observation','gengdu.saved_plan')end
 if type(r.source_error)=='string'then error(r.source_error,0)end
 return r
end
function SmartAIView:writeGengduSavedPlan(value)
 local slot="gengduUse";local actualCard=type(value)=="table"and value.card
 if not r47_slots[slot]then ai_unsupported('unknown saved source slot','gengdu.saved_plan')end
 if type(value)~='table'or(actualCard~=nil and actualCard~=false and not AIValue.isCard(actualCard)and not AIValue.isConversion(actualCard))then ai_unsupported('source plan/Card shape unavailable','gengdu.saved_plan')end
 local cardState=actualCard==nil and'nil'or actualCard==false and'false'or'card'
 local view=cardState=='card'and rawget(actualCard,'_view')or{};if type(view)~='table'then ai_unsupported('saved Card native identity absent','gengdu.saved_plan')end
 local selector={}
 if cardState~='card'then
 elseif type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then selector={readonly_recipe_key=view.readonly_recipe_key}
 elseif AIValue.isConversion(actualCard)then selector={conversion_id=actualCard:getConversionId(),legacy_identity_token=view.legacy_identity_token}
 else selector={physical_id=actualCard:getEffectiveId(),legacy_identity_token=view.legacy_identity_token}end
 local fields
  local internal={_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  local source={card=true,to=true,isDummy=true,extra_target=true,current_targets=true}
  for k in pairs(value)do if not internal[k]and not source[k]then ai_unsupported('saved dummy field has no exact representation: '..tostring(k),'gengdu.saved_plan')end end
  if value.isDummy~=true or not AIValue.isList(value.to)then ai_unsupported('saved source dummy shape unavailable','gengdu.saved_plan')end
  local extra=value.extra_target;if extra==nil then extra=0 end
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra< -2147483648 or extra>2147483647 then ai_unsupported('saved source extra_target malformed','gengdu.saved_plan')end
  if value.current_targets~=nil and(type(value.current_targets)~='table'or next(value.current_targets)~=nil)then ai_unsupported('saved source current_targets not empty','gengdu.saved_plan')end
  fields={isDummy=true,extra_target=extra,current_targets_empty=true}
 local names={}
 for _,p in ipairs(value.to)do if not AIValue.isPlayer(p)then ai_unsupported('saved source target not Player','gengdu.saved_plan')end;names[#names+1]=p:objectName()end
 return r47_call(self,slot,'write',{selector=selector,targets=names,source_fields=fields,card_state=cardState})
end
function SmartAIView:readGengduSavedPlan()
 local slot="gengduUse"
 local r=r47_call(self,slot,'read',{})
 if r.status=='absent'then return{card=false}end
 if r.status~='plan'or type(r.wire)~='string'or not AIValue.isList(r.targets)then ai_unsupported('saved source plan result malformed','gengdu.saved_plan')end
 local to={};for _,name in ipairs(r.targets)do local p=self.room:findPlayerByObjectName(name,true);if not p then ai_unsupported('saved source target not projected','gengdu.saved_plan')end;to[#to+1]=p end
 -- The fixed Diou reader only calls toString after its target loop. This pure observation is neither a
 -- CardView nor an action descriptor; the normal response binder authorizes it.
 local wire=r.wire
 return{card={toString=function()return wire end,getLegacyStringKey=function()return wire end},to=to}
end
end

-- Fixed Mingfa source: actual own Card slot, only reached native predicates.
do
local function call(self,op,payload)
 if type(ai_olclan_saved_slot)~='function'then ai_unsupported('Mingfa source Card bridge unavailable','tenyearmingfa.saved_card')end
 local r=ai_olclan_saved_slot('tenyearmingfa_c',op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'Mingfa source Card observation absent','tenyearmingfa.saved_card')end
 if type(r.source_error)=='string'then error(r.source_error,0)end
 return r
end
function SmartAIView:writeMingfaSavedCard(card)
 if not AIValue.isCard(card)and not AIValue.isConversion(card)then ai_unsupported('Mingfa source value is not a Card','tenyearmingfa.saved_card')end
 local v=rawget(card,'_view');local selector
 if type(v)=='table'and type(v.readonly_recipe_key)=='string'and v.readonly_recipe_key~=''then selector={readonly_recipe_key=v.readonly_recipe_key}
 else ai_unsupported('Mingfa source Card lacks exact readonly identity','tenyearmingfa.saved_card')end
 return call(self,'write',{selector=selector})
end
function SmartAIView:queryMingfaSavedCard(method,target)
 local payload={method=method}
 if method=='can_use'then if not AIValue.isPlayer(target)then ai_unsupported('Mingfa source target absent','tenyearmingfa.saved_card')end;payload.target=target:objectName()
 elseif method~='target_fixed'or target~=nil then ai_unsupported('Mingfa source predicate unavailable','tenyearmingfa.saved_card')end
 local r=call(self,'query',payload)
 if r.known~=true or type(r.value)~='boolean'then ai_unsupported('Mingfa native predicate unknown','tenyearmingfa.saved_card')end
 return r.value
end
end

-- R53 actual game-Self Peiqi record. Each source field access stays a separate operation.
do
 local function query(self,op,key,value)
  if getmetatable(self)~=SmartAIView or type(ai_peiqi_source_record)~='function'then error(AIUnsupported.new('Peiqi actual record host unavailable','peiqiData'),0)end
  local row=ai_peiqi_source_record(op,key,value or{})
  if AIUnsupported.is(row)then error(row,0)end
  if type(row)~='table'or row.known~=true then error(AIUnsupported.new(type(row)=='table'and row.reason or'Peiqi record response malformed','peiqiData'),0)end
  if row.ordinary_error~=nil then
   if type(row.ordinary_error)~='string'then error(AIUnsupported.new('Peiqi ordinary error malformed','peiqiData'),0)end
   error(row.ordinary_error,0)
  end
  return row
 end
 function SmartAIView:resetPeiqiSourceRecord()query(self,'reset','')end
 function SmartAIView:writePeiqiSourceField(key,value)
  if key=='from'or key=='to'then
   if not AIValue.isPlayer(value)then error(AIUnsupported.new('Peiqi source target malformed',key),0)end
   query(self,'write',key,{value=value:objectName()})
  elseif key=='cid'and type(value)=='number'and value>=0 and value<=2147483647 and value%1==0 then query(self,'write',key,{value=value})
  else error(AIUnsupported.new('Peiqi source field malformed',tostring(key)),0)end
 end
 function SmartAIView:readPeiqiSourceField(key)
  if key~='from'and key~='to'and key~='cid'then error(AIUnsupported.new('Peiqi source field unavailable',tostring(key)),0)end
  local row=query(self,'read',key)
  if row.type=='nil'then return nil end
  if row.type=='player'then
   if type(row.value)~='string'then error(AIUnsupported.new('Peiqi target malformed',key),0)end
   local p=self.room:findPlayerByObjectName(row.value,true)
   if not AIValue.isPlayer(p)then error(AIUnsupported.new('Peiqi target outside current roster',key),0)end
   return p
  end
  if(row.type=='number'or row.type=='boolean'or row.type=='string')and type(row.value)==row.type then return row.value end
  error(AIUnsupported.new('Peiqi field value malformed',key),0)
 end
end

-- R53 Daoji actual Card identity, not a saved-face reconstruction.
do
 local function query(self,op,input)
  if getmetatable(self)~=SmartAIView or type(ai_daoji_source_card)~='function'then error(AIUnsupported.new('Daoji actual Card host unavailable','daoji_throwcard'),0)end
  local row=ai_daoji_source_card(op,input or{})
  if AIUnsupported.is(row)then error(row,0)end
  if type(row)~='table'or row.known~=true then error(AIUnsupported.new(type(row)=='table'and row.reason or'Daoji host response malformed','daoji_throwcard'),0)end
  return row
 end
 function SmartAIView:writeDaojiSourceCard(card)
  if card==nil then query(self,'write',{clear=true});return end
  if not AIValue.isCard(card)then error(AIUnsupported.new('Daoji source Card malformed','daoji_throwcard'),0)end
  query(self,'write',{id=card:getEffectiveId()})
 end
 function SmartAIView:daojiSourceCardPresent()
  local row=query(self,'truth');if row.type~='boolean'or type(row.value)~='boolean'then error(AIUnsupported.new('Daoji truth malformed','daoji_throwcard'),0)end;return row.value
 end
 local function list(who,cards)
  if not AIValue.isPlayer(who)or not AIValue.isList(cards)then error(AIUnsupported.new('Daoji actual equipment list malformed','daoji_throwcard'),0)end
  local ids={};for _,c in ipairs(cards)do if not AIValue.isCard(c)then error(AIUnsupported.new('Daoji equipment Card malformed','daoji_throwcard'),0)end;ids[#ids+1]=c:getEffectiveId()end
  return{who=who:objectName(),ids=ids}
 end
 function SmartAIView:daojiSourceCardInEquips(who,cards)
  local row=query(self,'contains',list(who,cards));if row.type~='boolean'or type(row.value)~='boolean'then error(AIUnsupported.new('Daoji contains malformed','daoji_throwcard'),0)end;return row.value
 end
 function SmartAIView:readDaojiSourceCard(who,cards)
  local row=query(self,'read',list(who,cards));local i=row.index
  if type(i)~='number'or i%1~=0 or not AIValue.isCard(cards[i])then error(AIUnsupported.new('Daoji current equipment index malformed','daoji_throwcard'),0)end
  return cards[i]
 end
end


-- R53 exact actual-own Tychende saved plan; never reconstruct a remembered spec.
do
local r47_slots={tychendeUse=true}
local function r47_call(self,slot,op,payload)
 if not r47_slots[slot]or type(ai_olclan_saved_slot)~='function'then ai_unsupported('finite saved-plan bridge unavailable','tychende.saved_plan')end
 local r=ai_olclan_saved_slot(slot,op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'saved-plan bridge returned no observation','tychende.saved_plan')end
 if type(r.source_error)=='string'then error(r.source_error,0)end
 return r
end
function SmartAIView:writeTychendeSavedPlan(value)
 local slot="tychendeUse";local actualCard=type(value)=="table"and value.card
 if not r47_slots[slot]then ai_unsupported('unknown saved source slot','tychende.saved_plan')end
 if type(value)~='table'or(not AIValue.isCard(actualCard)and not AIValue.isConversion(actualCard))then ai_unsupported('source plan/Card shape unavailable','tychende.saved_plan')end
 local view=rawget(actualCard,'_view');if type(view)~='table'then ai_unsupported('saved Card native identity absent','tychende.saved_plan')end
 local selector
 if type(view.readonly_recipe_key)=='string'and view.readonly_recipe_key~=''then selector={readonly_recipe_key=view.readonly_recipe_key}
 elseif AIValue.isConversion(actualCard)then selector={conversion_id=actualCard:getConversionId(),legacy_identity_token=view.legacy_identity_token}
 else selector={physical_id=actualCard:getEffectiveId(),legacy_identity_token=view.legacy_identity_token}end
 local fields
  local internal={_evaluation_only=true,context=true,scratch=true,candidate_id=true}
  local source={card=true,to=true,isDummy=true,extra_target=true,current_targets=true}
  for k in pairs(value)do if not internal[k]and not source[k]then ai_unsupported('saved dummy field has no exact representation: '..tostring(k),'tychende.saved_plan')end end
  if value.isDummy~=true or not AIValue.isList(value.to)then ai_unsupported('saved source dummy shape unavailable','tychende.saved_plan')end
  local extra=value.extra_target;if extra==nil then extra=0 end
  if type(extra)~='number'or extra~=extra or extra%1~=0 or extra< -2147483648 or extra>2147483647 then ai_unsupported('saved source extra_target malformed','tychende.saved_plan')end
  if value.current_targets~=nil and(type(value.current_targets)~='table'or next(value.current_targets)~=nil)then ai_unsupported('saved source current_targets not empty','tychende.saved_plan')end
  fields={isDummy=true,extra_target=extra,current_targets_empty=true}
 local names={}
 for _,p in ipairs(value.to)do if not AIValue.isPlayer(p)then ai_unsupported('saved source target not Player','tychende.saved_plan')end;names[#names+1]=p:objectName()end
 return r47_call(self,slot,'write',{selector=selector,targets=names,source_fields=fields})
end
function SmartAIView:readTychendeSavedPlan()
 local slot="tychendeUse"
 local r=r47_call(self,slot,'read',{})
 if r.status=='pass'then return{card=false}end
 if r.status~='plan'or type(r.wire)~='string'or type(r.class_name)~='string'or type(r.spec)~='table'or not AIValue.isList(r.targets)then ai_unsupported('Tychende source observation malformed','tychende.saved_plan')end
 local to=AIList.new{};for _,name in ipairs(r.targets)do local p=self.room:findPlayerByObjectName(name,true);if not p then ai_unsupported('Tychende target not projected','tychende.saved_plan')end;to:append(p)end
 local observed={wire=r.wire,spec=copy_value(r.spec),class_name=r.class_name,physical_id=r.physical_id}
 return{card=observed,to=to}

end
end

function SmartAIView:evaluateTychendeSource(name)
 return self:evaluateOwnerViewAsCard{source_key='tychende',name=name,skill='_tychende',suit=6,number=0,subcards={}}
end
function SmartAIView:materializeTychendeSaved(card,targets)
 if type(card.physical_id)=='number'and card.physical_id>=0 then
  local c=self:getKnownCardById(card.physical_id)
  if not c or c:getLegacyStringKey()~=card.wire then ai_unsupported('Tychende physical replacement is no longer exact disclosed source','tychende.saved_plan')end
  return{kind='use_card',card_id=card.physical_id,targets=copy_value(targets)}
 end
 if card.spec.skill~='_tychende'then ai_unsupported('Tychende saved replacement needs its actual different provider','tychende.saved_plan')end
 -- Original raw Card::Parse submits its material/targets to the V2 resolver.
 -- That resolver replaces the old card with the current native factory product;
 -- it does not require the old raw underscore/name/face to equal the rebuilt card.
 local paid=self:bindSkillCard('tychende',copy_value(card.spec.subcards))
 return{kind='use_card',card_spec=paid:toCardSpec(),targets=copy_value(targets)}
end

-- Lianzhan saves an actual CardUseStruct, never a dummy plan or card spec.
do
local function call(op,payload)
 if type(ai_olclan_saved_slot)~='function'then ai_unsupported('Lianzhan native source slot unavailable','lianzhan.saved_use')end
 local r=ai_olclan_saved_slot('lianzhanUse',op,payload)
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'Lianzhan source slot unavailable','lianzhan.saved_use')end
 if type(r.source_error)=='string'then error(r.source_error,0)end
 return r
end
function SmartAIView:writeLianzhanSavedUse(use)
 if type(use)~='table'or not AIValue.isPlayer(use.from)or not AIValue.isList(use.to)
  or(not AIValue.isCard(use.card)and not AIValue.isConversion(use.card))then ai_unsupported('Lianzhan actual use fields unavailable','lianzhan.saved_use')end
 local to={};for _,p in ipairs(use.to)do if not AIValue.isPlayer(p)then ai_unsupported('Lianzhan actual target unavailable','lianzhan.saved_use')end;to[#to+1]=p:objectName()end
 return call('write',{from=use.from:objectName(),card_identity=use.card:getLegacyIdentityToken(),to=to})
end
function SmartAIView:readLianzhanSavedUse()
 local r=call('read',{})
 if r.status~='use'or(type(r.from)~='string'and r.from~=false)or not AIValue.isList(r.to)
  or(type(r.card)~='table'and r.card~=false)then ai_unsupported('Lianzhan native use row malformed','lianzhan.saved_use')end
 local function player(n)local p=self.room:findPlayerByObjectName(n,true);if not p then ai_unsupported('Lianzhan saved Player left roster','lianzhan.saved_use')end;return p end
 local use={from=r.from and player(r.from)or nil,to=AIList.new{}}
 if r.card~=false then
  if type(r.card.legacy_identity_token)~='string'or r.card.legacy_identity_token==''or r.card.evaluation_only~=true then ai_unsupported('Lianzhan saved Card lacks exact observed identity','lianzhan.saved_use')end
  use.card=CardView.new(r.card)
 end
 for _,n in ipairs(r.to)do if type(n)~='string'then ai_unsupported('Lianzhan target row malformed','lianzhan.saved_use')end;use.to:append(player(n))end
 return use
end
end

function SmartAIView:materializeDiouSavedWire(wire,targets)
 if type(wire)~='string'or not AIValue.isList(targets)or type(ai_olclan_saved_slot)~='function'then ai_unsupported('Diou selected source envelope unavailable','diou.selected_source')end
 local r=ai_olclan_saved_slot('diouUse','select',{wire=wire,targets=copy_value(targets)})
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.error then ai_unsupported(type(r)=='table'and r.error or'Diou native selected source unavailable','diou.selected_source')end
 if type(r.card_spec)~='table'or not AIValue.isList(r.targets)then ai_unsupported('Diou native receipt malformed','diou.selected_source')end
 return{kind='use_card',card_spec=copy_value(r.card_spec),targets=copy_value(r.targets)}
end

-- Actual source arithmetic prefixes; never grant a sorter value from the write.
function SmartAIView:incrementNamedSourcePriority(writer,card,source_class)
 if writer~='sijyu_qizhan'and writer~='TenyearJianying'then ai_unsupported('unregistered source arithmetic writer',writer)end
 if not AIValue.isCard(card)or type(source_class)~='string'then ai_unsupported('source arithmetic card unavailable',writer)end
 local v=rawget(card,'_view');local selector
 if type(v)=='table'and type(v.readonly_recipe_key)=='string'and v.readonly_recipe_key~=''then selector={readonly_recipe_key=v.readonly_recipe_key}
 elseif type(v)=='table'and v.evaluation_only==true and type(v.name)=='string'then selector={printed_name=v.name}
 elseif type(v)=='table'and type(v.legacy_identity_token)=='string'then selector={physical_id=card:getEffectiveId(),legacy_identity_token=v.legacy_identity_token}
 else ai_unsupported('source arithmetic lacks issued card identity',writer)end
 -- Mark before entering the actual VM. A preceding increment remains real if
 -- a later mark iteration errors; no stale local priority may then be read.
 local keys,present=self:getStrategyMemory('r53_actual_priority_unread')
 if not present or type(keys)~='table'then keys={}end
 keys[source_class]=true;self:setStrategyMemory('r53_actual_priority_unread',keys)
 if type(ai_response_choice_continuity)~='function'then ai_unsupported('source arithmetic host unavailable',writer)end
 local row=ai_response_choice_continuity{op='source_priority_increment',writer=writer,source_class=source_class,card=selector}
 if AIUnsupported.is(row)then error(row,0)end
 if type(row)=='table'and type(row.source_error)=='string'then error(row.source_error,0)end
 if type(row)~='table'or row.known~=true or row.completed~=true then ai_unsupported('source arithmetic prefix unavailable',writer)end
end

-- Current actual-cell reader. Native provenance, not a cached RHS, grants data.
function SmartAIView:readNamedSourcePriority(key)
 local fixed=key=='ZunweiCard'or key=='YoulongCard'or key=='SecondJinzhiCard'or key=='genshunoYURICard'
 local written,present=self:getStrategyMemory('r53_actual_priority_unread')
 if not fixed and not(present and type(written)=='table'and written[key])then return false end
 if type(ai_response_choice_continuity)~='function'then ai_unsupported('actual priority reader unavailable',key)end
 local r=ai_response_choice_continuity{op='source_priority_read',key=key}
 if AIUnsupported.is(r)then error(r,0)end
 if type(r)~='table'or r.known~=true or type(r.present)~='boolean'then ai_unsupported('actual priority source provenance unavailable',key)end
 if not r.present then return true,nil,true end
 if (type(r.value)~='number'and type(r.value)~='boolean')or(type(r.value)=='number'and(r.value~=r.value or r.value==math.huge or r.value==-math.huge))then ai_unsupported('actual priority source value unavailable',key)end
 return true,r.value,false
end

-- OLJijiang keeps policy memory as observer-owned values. Only the real native
-- askForCard operation identifies a liege's current source; saved names cannot
-- make a new operation or authorize a response/payment.
local function oljijiang_source_operation(op)
    if type(ai_ol_jijiang_state) ~= "function" then
        ai_unsupported("OLJijiang native response source is unavailable", "oljijiang")
    end
    local row = ai_ol_jijiang_state(op)
    if type(row) ~= "table" or row.kind ~= "ol_jijiang_state" or row.known ~= true then
        ai_unsupported(type(row) == "table" and row.reason or "invalid OLJijiang response source", "oljijiang")
    end
    return row
end
function SmartAIView:getOLJijiangResponseSource()
    local row = oljijiang_source_operation("source_read")
    if row.present == false then return nil end
    if row.present ~= true or type(row.player) ~= "string" or type(row.operation) ~= "string" then
        ai_unsupported("invalid OLJijiang operation source", "oljijiang")
    end
    local player = self.room:findPlayerByObjectName(row.player, true)
    if not player then ai_unsupported("OLJijiang source is absent from the current roster", "oljijiang") end
    self:remember("ol_jijiang.source", row.player)
    self:remember("ol_jijiang.operation", row.operation)
    return player
end
function SmartAIView:clearOLJijiangResponseSource()
    local row = oljijiang_source_operation("source_clear")
    if row.present ~= false then ai_unsupported("OLJijiang source clear failed", "oljijiang") end
    return true
end
