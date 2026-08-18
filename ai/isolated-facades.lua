PlayerView = {}
CardView = {}
SkillView = {}

local player_scalar_aliases = {
    object_name = "objectName",
    handcard_count = "getHandcardNum",
    face_up = "faceUp",
    general = "getGeneralName",
    general2 = "getGeneral2Name"
}

local card_scalar_aliases = {
    id = "getId",
    effective_id = "getEffectiveId",
    name = "objectName",
    class_name = "getClassName",
    suit = "getSuit",
    number = "getNumber",
    skill_name = "getSkillName",
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

local function scalar_method_name(field_name, value_type, aliases)
    local alias = aliases[field_name]
    if alias then
        return alias
    end
    local prefix = value_type == "boolean" and "is" or "get"
    return prefix .. to_pascal_case(field_name)
end

local function make_scalar_getter(field_name)
    return function(self)
        local view = rawget(self, "_view")
        if type(view) ~= "table" then
            return nil
        end
        return view[field_name]
    end
end

local function facade_index(facade, self, key)
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
    return facade_index(CardView, self, key)
end

SkillView.__index = function(self, key)
    return facade_index(SkillView, self, key)
end

function PlayerView.new(view)
    return new_facade(PlayerView, view, player_scalar_aliases)
end

function CardView.new(view)
    return new_facade(CardView, view, card_scalar_aliases)
end

function SkillView.new(view)
    return new_facade(SkillView, view, skill_scalar_aliases)
end

local function copy_value(value)
    if type(value) ~= "table" then
        return value
    end
    local copy = {}
    for key, item in pairs(value) do
        copy[key] = copy_value(item)
    end
    return copy
end

local function wrap_values(values, constructor)
    local result = {}
    if type(values) ~= "table" then
        return result
    end
    for _, value in ipairs(values) do
        local wrapped = constructor(value)
        if wrapped then
            result[#result + 1] = wrapped
        end
    end
    return result
end

function PlayerView:getMark(mark_name)
    local view = rawget(self, "_view")
    local marks = type(view) == "table" and view.public_marks or nil
    local value = type(marks) == "table" and marks[mark_name] or nil
    return type(value) == "number" and value or 0
end

function PlayerView:hasSkill(skill_name)
    if type(skill_name) ~= "string" or skill_name == "" then
        return false
    end
    local base_name, instance_text = string.match(skill_name, "^(.-)#(%d+)$")
    local instance_id
    if base_name then
        instance_id = tonumber(instance_text)
    else
        base_name = skill_name
    end
    local view = rawget(self, "_view")
    local skills = type(view) == "table" and view.skills or nil
    if type(skills) ~= "table" then
        return false
    end
    for _, skill in ipairs(skills) do
        if type(skill) == "table" and skill.name == base_name and not skill.invalid
            and (instance_id == nil or skill.instance_id == instance_id) then
            return true
        end
    end
    return false
end

function PlayerView:getEquips()
    local view = rawget(self, "_view")
    return wrap_values(type(view) == "table" and view.equips or nil, CardView.new)
end

function PlayerView:getJudgingArea()
    local view = rawget(self, "_view")
    return wrap_values(type(view) == "table" and view.judging_area or nil, CardView.new)
end

function PlayerView:getSkills()
    local view = rawget(self, "_view")
    return wrap_values(type(view) == "table" and view.skills or nil, SkillView.new)
end

function CardView:isKindOf(card_type)
    if type(card_type) ~= "string" or card_type == "" then
        return false
    end
    local view = rawget(self, "_view")
    local kind_of = type(view) == "table" and view.kind_of or nil
    if type(kind_of) ~= "table" then
        return false
    end
    for _, name in ipairs(kind_of) do
        if name == card_type then
            return true
        end
    end
    return false
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
    return setmetatable({
        request = request,
        world = request.world_view,
        player = PlayerView.new(request.world_view.self)
    }, SmartAIView)
end
