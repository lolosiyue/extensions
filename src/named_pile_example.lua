--[[
    Named Pile System - Flexible Alternative to RenPile
    
    This example demonstrates how to use the new addToNamedPile function
    which allows you to create custom piles with custom display names.
    
    The original addToRenPile is preserved and still works:
    - player:addToRenPile(card, skill_name)
    
    The new addToNamedPile provides more flexibility:
    - player:addToNamedPile(card, pile_name, display_name, skill_name, max_cards)
    
    Parameters:
    - card/card_id/card_ids: The card(s) to add to the pile
    - pile_name: Internal identifier for the pile (e.g., "yi_pile", "ren_pile")
    - display_name: The text shown to players (e.g., "义", "仁", "德")
    - skill_name: The skill triggering this (optional, default "")
    - max_cards: Maximum cards in pile before old ones are discarded (optional, default 6)
]]--

-- Example 1: Creating a "Yi" (义) pile similar to Ren pile
local yipile_skill = sgs.CreateTriggerSkill{
    name = "yipile",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") then
            -- Add card to "yi_pile" with display name "义", max 6 cards
            player:addToNamedPile(use.card, "yi_pile", "义", self:objectName(), 6)
        end
        return false
    end,
}

-- Example 2: Creating a "De" (德) pile with custom limit
local depile_skill = sgs.CreateTriggerSkill{
    name = "depile",
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() 
           and move.to_place == sgs.Player_PlaceHand then
            -- Add first card to "de_pile" with display name "德", max 8 cards
            if not move.card_ids:isEmpty() then
                local card_id = move.card_ids:first()
                player:addToNamedPile(card_id, "de_pile", "德", self:objectName(), 8)
            end
        end
        return false
    end,
}

-- Example 3: Creating a "Zhi" (智) pile with different max
local zhipile_skill = sgs.CreateTriggerSkill{
    name = "zhipile",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Finish then
            local cards = room:getNCards(1)
            if not cards:isEmpty() then
                -- Add to "zhi_pile" with display "智", max 4 cards
                player:addToNamedPile(cards:first(), "zhi_pile", "智", self:objectName(), 4)
            end
        end
        return false
    end,
}

-- Example 4: Using multiple cards at once
local multipile_skill = sgs.CreateTriggerSkill{
    name = "multipile",
    events = {sgs.EventPhaseEnd},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Draw then
            local cards = sgs.IntList()
            -- Get some cards
            for i = 1, 3 do
                local id = room:drawCard()
                cards:append(id)
            end
            -- Add multiple cards to "xin_pile" with display "信", max 10 cards
            player:addToNamedPile(cards, "xin_pile", "信", self:objectName(), 10)
        end
        return false
    end,
}

--[[
    How to retrieve cards from the pile in Lua:
    
    local pile_cards = room:getTag("yi_pile"):toIntList()
    for _, id in sgs.qlist(pile_cards) do
        -- Process each card
    end
    
    How to add pile name translations in Common.lua:
    
    ["yi_pile"] = "义",
    ["$addyi_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
    ["$removeyi_pile"] = "%arg2 区移出 %arg 张牌 %card",
    
    ["de_pile"] = "德",
    ["$addde_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
    ["$removede_pile"] = "%arg2 区移出 %arg 张牌 %card",
    
    Benefits over original RenPile:
    1. Create multiple different piles (yi, de, zhi, xin, etc.)
    2. Customize display name dynamically
    3. Different max card limits per pile
    4. Original RenPile still works unchanged
    5. More flexible for custom skills
]]--
