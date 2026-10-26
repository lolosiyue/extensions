-- Source: b6025acc ai/SoulA-ai.lua.
local query = AIValue.bindQuery {
    missing = function(method) ai_unsupported("SoulA policy requires " .. method, "SoulA") end,
    known = function(value, method)
        if value == nil then ai_unsupported("SoulA policy requires known " .. method, "SoulA") end
        return value
    end,
}

ai_skill_invoke.Rcekuiwei = function(self, options, request)
    local current = query(self.room, "getCurrent")
    local next_alive = query(current, "getNextAlive")
    if query(next_alive, "objectName") == query(self.player, "objectName")
        and query(self.player, "faceUp") then
        return (false) or false
    end
    return (true) or false
end

sgs.ai_view_as.Rceyanzheng = function(card, player, card_place)
    -- The donor formats getSuitString/getNumberString before its place test.
    -- Preserve both Card::Parse storage and Card::getNumber effective identity:
    -- a parsed zero (including JOKER) inherits this one subcard's number.
    local suit = query(card, "getSuitString")
    local number = query(card, "getNumberString")
    local id = query(card, "getEffectiveId")
    local hand_place = sgs.Player_PlaceHand
    if type(hand_place) ~= "number" then
        ai_unsupported("SoulA policy requires hand place enum", "Rceyanzheng")
    end
    if card_place == hand_place then
        if query(player, "getHandcardNum") > query(player, "getHp") then
            local suit_keys = {spade="Spade", club="Club", heart="Heart", diamond="Diamond",
                no_suit_red="NoSuitRed", no_suit_black="NoSuitBlack", no_suit="NoSuit"}
            local suit_value = sgs["Card_" .. (suit_keys[suit] or "NoSuit")]
            if type(suit_value) ~= "number" then
                ai_unsupported("SoulA policy requires card suit enum", "Rceyanzheng")
            end
            local parsed_number = ({A=1,J=11,Q=12,K=13})[number] or tonumber(number) or 0
            if parsed_number <= 0 then parsed_number = query(card, "getNumber") end
            return {name="nullification", skill="Rceyanzheng", suit=suit_value,
                number=parsed_number, subcards={id}}
        end
    end
end
