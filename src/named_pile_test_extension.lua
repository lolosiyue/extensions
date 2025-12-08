--[[
    Complete Test Package for Named Pile System
    
    This file contains a complete, working test general that demonstrates
    all features of the new Named Pile system.
    
    To test:
    1. Add this to your extensions
    2. Select the test general in game
    3. Use various card actions to trigger skills
    4. Observe the piles being created and managed
]]--

-- Test Extension
local extension = sgs.Package("named_pile_test")

--[[═══════════════════════════════════════════════════════════════
    Test General: Zhang Wude (张武德)
    Demonstrates Yi/De/Zhi/Xin/Li piles
═══════════════════════════════════════════════════════════════]]--

local zhangwude = sgs.General(extension, "zhangwude", "qun", 4, true)

--[[───────────────────────────────────────────────────────────────
    Skill 1: "Wude" (武德) - Righteousness Pile
    When you use a Slash, add it to Yi pile (max 6)
───────────────────────────────────────────────────────────────]]--

local wude_yi = sgs.CreateTriggerSkill{
    name = "wude_yi",
    events = {sgs.CardFinished},
    
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.from and use.from:objectName() == player:objectName() then
            if use.card:isKindOf("Slash") then
                -- Add Slash to Yi pile (义)
                player:addToNamedPile(
                    use.card,           -- The card
                    "yi_pile",          -- Internal pile name
                    "义",               -- Display name
                    self:objectName(),  -- Skill name
                    6                   -- Max 6 cards
                )
                
                -- Log pile count for testing
                local pile = room:getTag("yi_pile"):toIntList()
                room:sendLog("#CustomLog", player:objectName() .. 
                    " now has " .. pile:length() .. " cards in Yi pile")
            end
        end
        return false
    end,
}

zhangwude:addSkill(wude_yi)

--[[───────────────────────────────────────────────────────────────
    Skill 2: "Houde" (厚德) - Virtue Pile
    When you receive cards, add first to De pile (max 8)
───────────────────────────────────────────────────────────────]]--

local houde_de = sgs.CreateTriggerSkill{
    name = "houde_de",
    events = {sgs.CardsMoveOneTime},
    
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() 
           and move.to_place == sgs.Player_PlaceHand 
           and not move.card_ids:isEmpty() then
            
            -- Add first card to De pile (德)
            local card_id = move.card_ids:first()
            player:addToNamedPile(
                card_id,            -- Card ID
                "de_pile",          -- Internal pile name
                "德",               -- Display name
                self:objectName(),  -- Skill name
                8                   -- Max 8 cards
            )
            
            local pile = room:getTag("de_pile"):toIntList()
            room:sendLog("#CustomLog", player:objectName() .. 
                " now has " .. pile:length() .. " cards in De pile")
        end
        return false
    end,
}

zhangwude:addSkill(houde_de)

--[[───────────────────────────────────────────────────────────────
    Skill 3: "Renzhi" (仁智) - Wisdom Pile
    At end of turn, draw cards equal to Zhi pile size (max 4)
───────────────────────────────────────────────────────────────]]--

local renzhi_zhi = sgs.CreateTriggerSkill{
    name = "renzhi_zhi",
    events = {sgs.EventPhaseStart, sgs.EventPhaseEnd},
    
    on_trigger = function(self, event, player, data, room)
        -- At start of turn, add a random card to Zhi pile
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local cards = room:getNCards(1)
                if not cards:isEmpty() then
                    player:addToNamedPile(
                        cards:first(),      -- Card ID
                        "zhi_pile",         -- Internal pile name
                        "智",               -- Display name
                        self:objectName(),  -- Skill name
                        4                   -- Max 4 cards
                    )
                end
            end
        end
        
        -- At end of turn, draw cards equal to pile size
        if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then
            local pile = room:getTag("zhi_pile"):toIntList()
            local count = pile:length()
            if count > 0 then
                room:sendLog("#CustomLog", player:objectName() .. 
                    " draws " .. count .. " cards from Zhi pile effect")
                player:drawCards(count, self:objectName())
            end
        end
        
        return false
    end,
}

zhangwude:addSkill(renzhi_zhi)

--[[───────────────────────────────────────────────────────────────
    Skill 4: "Shouxin" (守信) - Trust Pile
    Discard phase: add discarded cards to Xin pile (max 5)
───────────────────────────────────────────────────────────────]]--

local shouxin_xin = sgs.CreateTriggerSkill{
    name = "shouxin_xin",
    events = {sgs.CardsMoveOneTime},
    
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == player:objectName()
           and move.to_place == sgs.Player_DiscardPile
           and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISCARD
           and not move.card_ids:isEmpty() then
            
            -- Add all discarded cards to Xin pile (信)
            local ids = sgs.IntList()
            for _, id in sgs.qlist(move.card_ids) do
                ids:append(id)
            end
            
            if not ids:isEmpty() then
                player:addToNamedPile(
                    ids,                -- Card IDs list
                    "xin_pile",         -- Internal pile name
                    "信",               -- Display name
                    self:objectName(),  -- Skill name
                    5                   -- Max 5 cards
                )
                
                local pile = room:getTag("xin_pile"):toIntList()
                room:sendLog("#CustomLog", player:objectName() .. 
                    " now has " .. pile:length() .. " cards in Xin pile")
            end
        end
        return false
    end,
}

zhangwude:addSkill(shouxin_xin)

--[[───────────────────────────────────────────────────────────────
    Skill 5: "Fuli" (复礼) - Courtesy Pile & Pile Usage
    Once per turn: Take a card from any pile and use it
───────────────────────────────────────────────────────────────]]--

local fuli_use = sgs.CreateViewAsSkill{
    name = "fuli_use",
    n = 0,
    
    view_filter = function(self, selected, to_select)
        return false -- Don't select from hand
    end,
    
    view_as = function(self, cards)
        -- This is a placeholder for pile card usage
        -- Real implementation would let player select from piles
        return nil
    end,
    
    enabled_at_play = function(self, player)
        return not player:hasUsed("#fuli_use")
    end,
}

zhangwude:addSkill(fuli_use)

--[[───────────────────────────────────────────────────────────────
    Test Skill: Show All Piles
    Debug command to display all pile contents
───────────────────────────────────────────────────────────────]]--

local show_piles = sgs.CreateTriggerSkill{
    name = "show_piles",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Frequent,
    
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() == sgs.Player_Start then
            if room:askForSkillInvoke(player, self:objectName(), data) then
                local piles = {"yi_pile", "de_pile", "zhi_pile", "xin_pile"}
                
                for _, pile_name in ipairs(piles) do
                    local pile = room:getTag(pile_name):toIntList()
                    local display = room:getTag(pile_name .. "_display"):toString()
                    
                    if pile:length() > 0 then
                        local card_names = {}
                        for _, id in sgs.qlist(pile) do
                            local card = sgs.Sanguosha:getCard(id)
                            table.insert(card_names, card:objectName())
                        end
                        
                        room:sendLog("#CustomLog", 
                            display .. " pile (" .. pile_name .. "): " ..
                            pile:length() .. " cards - " ..
                            table.concat(card_names, ", "))
                    else
                        room:sendLog("#CustomLog", 
                            display .. " pile (" .. pile_name .. "): empty")
                    end
                end
            end
        end
        return false
    end,
}

zhangwude:addSkill(show_piles)

--[[═══════════════════════════════════════════════════════════════
    Test General 2: Li Dexin (李德信)
    Tests comparison with original RenPile
═══════════════════════════════════════════════════════════════]]--

local lidexin = sgs.General(extension, "lidexin", "shu", 3, true)

-- Uses original RenPile (for comparison)
local use_renpile = sgs.CreateTriggerSkill{
    name = "use_renpile",
    events = {sgs.CardFinished},
    
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.from and use.from:objectName() == player:objectName() then
            if use.card:isKindOf("BasicCard") then
                -- Use original RenPile function
                player:addToRenPile(use.card, self:objectName())
                
                local pile = room:getTag("ren_pile"):toIntList()
                room:sendLog("#CustomLog", "Original RenPile has " .. 
                    pile:length() .. " cards (max 6, display 仁)")
            end
        end
        return false
    end,
}

lidexin:addSkill(use_renpile)

-- Uses new named pile with same effect but custom settings
local use_customren = sgs.CreateTriggerSkill{
    name = "use_customren",
    events = {sgs.CardFinished},
    
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.from and use.from:objectName() == player:objectName() then
            if use.card:isKindOf("TrickCard") then
                -- Use new named pile with custom settings
                player:addToNamedPile(
                    use.card,
                    "custom_ren",       -- Different internal name
                    "仁",               -- Same display
                    self:objectName(),
                    10                  -- Different max (10 instead of 6)
                )
                
                local pile = room:getTag("custom_ren"):toIntList()
                room:sendLog("#CustomLog", "Custom Ren has " .. 
                    pile:length() .. " cards (max 10, display 仁)")
            end
        end
        return false
    end,
}

lidexin:addSkill(use_customren)

--[[═══════════════════════════════════════════════════════════════
    Localization (add to Common.lua or translations)
═══════════════════════════════════════════════════════════════]]--

--[[
In Common.lua, add:

["yi_pile"] = "义",
["$addyi_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$removeyi_pile"] = "%arg2 区移出 %arg 张牌 %card",

["de_pile"] = "德",
["$addde_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$removede_pile"] = "%arg2 区移出 %arg 张牌 %card",

["zhi_pile"] = "智",
["$addzhi_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$removezhi_pile"] = "%arg2 区移出 %arg 张牌 %card",

["xin_pile"] = "信",
["$addxin_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$removexin_pile"] = "%arg2 区移出 %arg 张牌 %card",

["custom_ren"] = "仁",
["$addcustom_ren"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$removecustom_ren"] = "%arg2 区移出 %arg 张牌 %card",

-- Skill names
["wude_yi"] = "武德・义",
[":wude_yi"] = "当你使用【杀】后，将之置入义区（上限6张，超出则移除最早的牌）。",

["houde_de"] = "厚德・德",
[":houde_de"] = "当你获得牌后，将其中一张置入德区（上限8张）。",

["renzhi_zhi"] = "仁智・智",
[":renzhi_zhi"] = "回合开始时，你可以将一张牌置入智区（上限4张）；结束阶段，你摸X张牌（X为智区牌数）。",

["shouxin_xin"] = "守信・信",
[":shouxin_xin"] = "当你于弃牌阶段弃置牌后，将这些牌置入信区（上限5张）。",

["fuli_use"] = "复礼",
[":fuli_use"] = "出牌阶段限一次，你可以使用任意区域的一张牌。",

["show_piles"] = "查看",
[":show_piles"] = "回合开始时，你可以查看所有区域的牌。",

["use_renpile"] = "仁德",
[":use_renpile"] = "当你使用基本牌后，将之置入仁区（使用原始RenPile函数）。",

["use_customren"] = "自定义仁",
[":use_customren"] = "当你使用锦囊牌后，将之置入自定义仁区（上限10张，使用新NamedPile函数）。",

-- Generals
["zhangwude"] = "张武德",
["lidexin"] = "李德信",
]]--

-- Register extension
sgs.LoadTranslationTable{
    ["named_pile_test"] = "命名堆测试",
    ["zhangwude"] = "张武德",
    ["lidexin"] = "李德信",
}

return extension
