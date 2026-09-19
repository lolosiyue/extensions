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

function AIValue.kind(value)
    if type(value) ~= "table" then return nil end
    return facade_kinds[value]
end

function AIValue.isPlayer(value) return AIValue.kind(value) == "player" end
function AIValue.isCard(value) return AIValue.kind(value) == "card" end
function AIValue.isSkill(value) return AIValue.kind(value) == "skill" end

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
    for _, item in ipairs(self) do if item == value then return true end end
    return false
end
function AIList:append(value)
    assert(value ~= nil, "AIList:append cannot insert nil")
    self[#self + 1] = value
end
function AIList:removeOne(value)
    for index, item in ipairs(self) do
        if item == value then table.remove(self, index) return true end
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
    local result = new_facade(PlayerView, view, player_scalar_aliases)
    if result then facade_kinds[result] = "player" end
    return result
end

function CardView.new(view)
    local result = new_facade(CardView, view, card_scalar_aliases)
    if result then facade_kinds[result] = "card" end
    return result
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
    if not pile or not AIValue.isList(pile.card_ids) then return nil end
    return AIList.new(pile.card_ids)
end

function PlayerView:getPileCount(pile_name)
    local pile = pile_entry(rawget(self, "_view"), pile_name)
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

function PlayerView:getPileName(card_id)
    local view = rawget(self, "_view")
    local piles = type(view) == "table" and view.piles or nil
    if not AIValue.isList(piles) then return nil end
    for _, pile in ipairs(piles) do
        if AIValue.isList(pile.card_ids) then
            for _, id in ipairs(pile.card_ids) do
                if id == card_id then return pile.name end
            end
        end
    end
    return nil
end

function PlayerView:getDisplayCards()
    local view = rawget(self, "_view")
    if type(view) ~= "table" or not AIValue.isList(view.display_cards) then return nil end
    return AIList.new(view.display_cards)
end

function PlayerView:getSkills()
    local view = rawget(self, "_view")
    return wrap_values(type(view) == "table" and view.skills or nil, SkillView.new)
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

-- 卡牌結構與技能種類：子牌與類別鏈是純值，`inherits` 只比對快照裡的類別名，
-- 不會回查 Engine 的技能物件。
function CardView:getSubcards()
    local view = rawget(self, "_view")
    if type(view) ~= "table" or not AIValue.isList(view.subcards) then return nil end
    return AIList.new(view.subcards)
end

function CardView:subcardsLength()
    local subcards = self:getSubcards()
    return subcards and #subcards or nil
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
        return equips and #equips > 0 or nil
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
    local room = setmetatable({_world = world, _players = {}}, RoomView)
    facade_kinds[room] = "room"
    local function add(view)
        if type(view) ~= "table" or type(view.object_name) ~= "string"
            or view.object_name == "" or room._players[view.object_name] then return false end
        room._players[view.object_name] = PlayerView.new(view)
        room._players[view.object_name]._room = room
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

function RoomView:getCurrent()
    return self._players[self._world.current_player]
end

function RoomView:getPlayers()
    return players_in_order(self, self._world.player_order)
end

function RoomView:getAlivePlayers()
    return players_in_order(self, self._world.alive_player_order)
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
    local players = self:getAllPlayers(include_dead)
    if not players then return nil end
    for _, player in ipairs(players) do
        if player:objectName() == name then return player end
    end
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
    local located = self._card_locations[card_id]
    return located and located.place or nil
end

function RoomView:isCardKnown(card_id)
    return self._card_locations[card_id] ~= nil
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
    local room = RoomView.new(request.world_view)
    if not room then return nil end
    local ai = setmetatable({
        request = request,
        world = request.world_view,
        room = room,
        player = room._players[request.viewer]
    }, SmartAIView)
    facade_kinds[ai] = "ai"
    if ai.world.mode_policy and ai.world.mode_policy.managed then
        ai.friends = ai:getFriends()
        ai.friends_noself = ai:getFriends(nil, true)
        ai.enemies = ai:getEnemies()
    end
    return ai
end

-- 合法候選：全部由權威端在建立 request 時算好，這裡只查表。查不到就是「這次沒問到」，
-- 回 nil，不會現場推規則，也沒有回頭問 Engine 的路。
CandidateView = {}
CandidateView.__index = function(self, key)
    return facade_index(CandidateView, self, key)
end

local candidate_scalar_aliases = {
    card_id = "getCardId",
    target_fixed = "targetFixed",
    max_targets = "getMaxTargets"
}

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

function CandidateView:canTarget(player_name)
    local targets = self:getLegalTargets()
    if not targets then return nil end
    for _, name in ipairs(targets) do
        if name == player_name then return true end
    end
    return false
end

function SmartAIView:getCardCandidates()
    local candidates = self.request.card_candidates
    if not AIValue.isList(candidates) then return nil end
    return wrap_values(candidates, CandidateView.new)
end

function SmartAIView:getCardCandidate(card_id)
    local candidates = self:getCardCandidates()
    if not candidates then return nil end
    for _, candidate in ipairs(candidates) do
        if candidate:getCardId() == card_id then return candidate end
    end
    return nil
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

function PlayerView:distanceTo(other)
    local room = rawget(self, "_room")
    if not room then return nil end
    return room:distanceTo(self, other)
end

function PlayerView:inMyAttackRange(other)
    local distance = self:distanceTo(other)
    local view = rawget(self, "_view")
    local range = type(view) == "table" and view.attack_range or nil
    if distance == nil or type(range) ~= "number" then return nil end
    return distance > 0 and distance <= range
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
    return wrap_values(self.request.skill_actions, SkillActionView.new)
end

function SmartAIView:getSkillAction(skill_name, instance_id)
    if skill_name == nil then
        local action = self.request.skill_action
        return type(action) == "table" and SkillActionView.new(copy_value(action)) or nil
    end
    local actions = self:getSkillActions()
    if not actions then return nil end
    for _, action in ipairs(actions) do
        if action:getActivationSkillName() == skill_name
            and (instance_id == nil or action:getActivationInstanceId() == instance_id) then
            return action
        end
    end
    return nil
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

-- Mode policy is evaluated in the owning Room and copied into this snapshot.
-- No gameplay VM callbacks, native players, or mutable shared beliefs cross here.
-- 模式與身份：規則關係（mode policy 算出來的）與推測關係（這名觀察者自己相信的）
-- 是兩回事，查詢分開，缺一不會拿另一個頂替。
function SmartAIView:isModeManaged()
    local policy = self.world.mode_policy
    return type(policy) == "table" and policy.managed == true
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

function RoomView:getLieges(kingdom)
    local lord = self:getLord()
    local players = self:getAlivePlayers()
    if not players then return nil end
    local result = AIList.new({})
    for _, player in ipairs(players) do
        if player ~= lord then
            local view = rawget(player, "_view")
            local player_kingdom = type(view) == "table" and view.kingdom or nil
            if kingdom == nil or player_kingdom == kingdom then
                result[#result + 1] = player
            end
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
    if type(policy) ~= "table" or not policy.managed then return nil end
    local from = another or self.player
    if not from or not other then return "unknown" end
    local rows = policy.relations or {}
    local row = rows[from:objectName()]
    return row and row[other:objectName()] or "unknown"
end

function SmartAIView:isFriend(other, another)
    local relation = self:relationTo(other, another)
    if relation == nil then return nil end
    return relation == "friend"
end

function SmartAIView:isEnemy(other, another)
    local relation = self:relationTo(other, another)
    if relation == nil then return nil end
    return relation == "enemy"
end

function SmartAIView:objectiveLevel(other)
    local policy = self.world.mode_policy
    if type(policy) ~= "table" or not policy.managed then return nil end
    return other and (policy.objectives or {})[other:objectName()] or 0
end

function SmartAIView:isRolePredictable()
    local policy = self.world.mode_policy
    if not policy or not policy.managed then return nil end
    return policy.predictable == true
end

function SmartAIView:getFriends(player, no_self)
    if not self.world.mode_policy or not self.world.mode_policy.managed then return nil end
    player = player or self.player
    local result, players = AIList.new({}), {self.world.self}
    for _, view in ipairs(self.world.players) do players[#players + 1] = view end
    for _, view in ipairs(players) do
        local target = self.room._players[view.object_name]
        if view.alive and (not no_self or target:objectName() ~= player:objectName())
            and self:isFriend(target, player) then result[#result + 1] = target end
    end
    return result
end

function SmartAIView:getEnemies(player)
    if not self.world.mode_policy or not self.world.mode_policy.managed then return nil end
    player = player or self.player
    local result, players = AIList.new({}), {self.world.self}
    for _, view in ipairs(self.world.players) do players[#players + 1] = view end
    for _, view in ipairs(players) do
        local target = self.room._players[view.object_name]
        if view.alive and self:isEnemy(target, player) then result[#result + 1] = target end
    end
    return result
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

-- Result conversion shared by both callback ABIs. The status separates the cases the
-- legacy dispatcher treats differently: "unhandled" keeps searching, "declined" is the
-- legacy "." answer a compulsory request refuses, "pass"/"use_card" are decisions.
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
    assert(type(spec.name) == "string" and spec.name ~= "",
        "a card spec needs the engine card name")
    local result = {name = spec.name}
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
