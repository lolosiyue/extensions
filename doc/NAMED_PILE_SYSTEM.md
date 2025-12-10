# Named Pile System - Enhanced Pile Management

## Overview
This system provides a flexible way to create custom card piles (like the "仁" ren_pile) with customizable names and display text, without disrupting the original RenPile implementation.

## Features
- ✅ Original `addToRenPile()` functions are preserved and unchanged
- ✅ New `addToNamedPile()` functions for custom piles
- ✅ Customizable display names (义, 德, 智, 信, etc.)
- ✅ Configurable maximum card limits per pile
- ✅ Automatic oldest-card removal when limit is reached
- ✅ Full UI integration with logging

## C++ API

### Server Side (serverplayer.h/cpp)

#### Original RenPile Functions (Unchanged)
```cpp
void addToRenPile(const Card *card, const QString &skill_name = "");
void addToRenPile(int card_id, const QString &skill_name = "");
void addToRenPile(QList<int> card_ids, const QString &skill_name = "");
```

#### New Named Pile Functions
```cpp
void addToNamedPile(const Card *card, 
                    const QString &pile_name, 
                    const QString &pile_display_name, 
                    const QString &skill_name = "", 
                    int max_cards = 6);

void addToNamedPile(int card_id, 
                    const QString &pile_name, 
                    const QString &pile_display_name, 
                    const QString &skill_name = "", 
                    int max_cards = 6);

void addToNamedPile(QList<int> card_ids, 
                    const QString &pile_name, 
                    const QString &pile_display_name, 
                    const QString &skill_name = "", 
                    int max_cards = 6);
```

**Parameters:**
- `card/card_id/card_ids`: The card(s) to add to the pile
- `pile_name`: Internal identifier (e.g., "yi_pile", "de_pile")
- `pile_display_name`: Display text shown to players (e.g., "义", "德")
- `skill_name`: Name of the skill triggering this action (optional)
- `max_cards`: Maximum cards in pile (default: 6)

### UI Side (roomscene.h/cpp)
- Added `QMap<QString, QList<int>> m_namedPiles` to track multiple piles
- Enhanced `_processCardsMove()` to handle generic named piles
- Automatic logging for add/remove operations

## Lua Usage Examples

### Example 1: Simple Yi (义) Pile
```lua
-- Add a single card to "yi_pile" with display name "义"
player:addToNamedPile(card, "yi_pile", "义", "skill_name", 6)
```

### Example 2: De (德) Pile with Custom Limit
```lua
-- Add card to "de_pile" with display "德", max 8 cards
player:addToNamedPile(card_id, "de_pile", "德", "skill_name", 8)
```

### Example 3: Multiple Cards at Once
```lua
local cards = sgs.IntList()
cards:append(id1)
cards:append(id2)
cards:append(id3)
player:addToNamedPile(cards, "xin_pile", "信", "skill_name", 10)
```

### Example 4: Retrieving Pile Contents
```lua
-- Get all cards from a named pile
local pile_cards = room:getTag("yi_pile"):toIntList()
for _, id in sgs.qlist(pile_cards) do
    local card = sgs.Sanguosha:getCard(id)
    -- Process card
end
```

### Example 5: Complete Skill Implementation
```lua
local yipile = sgs.CreateTriggerSkill{
    name = "yipile",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("BasicCard") then
            -- Add used basic cards to yi pile
            player:addToNamedPile(use.card, "yi_pile", "义", self:objectName(), 6)
        end
        return false
    end,
}
```

## Localization (Common.lua)

Add translations for your custom piles:

```lua
-- Pile display name
["yi_pile"] = "义",
["de_pile"] = "德",
["zhi_pile"] = "智",
["xin_pile"] = "信",

-- Log messages for adding cards
["$addyi_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$addde_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$addzhi_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$addxin_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",

-- Log messages for removing cards
["$removeyi_pile"] = "%arg2 区移出 %arg 张牌 %card",
["$removede_pile"] = "%arg2 区移出 %arg 张牌 %card",
["$removezhi_pile"] = "%arg2 区移出 %arg 张牌 %card",
["$removexin_pile"] = "%arg2 区移出 %arg 张牌 %card",
```

## How It Works

1. **Card Addition**: When cards are added via `addToNamedPile()`:
   - Oldest cards are removed if pile exceeds `max_cards`
   - New cards are moved to PlaceTable with the pile name
   - Display name is stored in room tag `{pile_name}_display`
   - Move reason includes skill name for logging

2. **UI Processing**: In `_processCardsMove()`:
   - Detects cards moving to/from PlaceTable with pile names
   - Tracks cards in `m_namedPiles` map
   - Generates appropriate log messages
   - Original ren_pile handling is preserved

3. **Pile Management**:
   - Each pile is stored in room tag `{pile_name}`
   - Display name stored in `{pile_name}_display`
   - Automatic cleanup when piles become empty
   - Independent management of multiple piles

## Advantages

1. **Backward Compatible**: Original `addToRenPile()` works unchanged
2. **Flexible**: Create as many different piles as needed
3. **Customizable**: Each pile can have unique display name and limits
4. **Clean Design**: No code duplication, extends existing pattern
5. **Easy to Use**: Simple Lua API with sensible defaults

## Migration Guide

### Before (RenPile only):
```lua
player:addToRenPile(card, "skill_name")
```

### After (Still works!):
```lua
-- Old way still works
player:addToRenPile(card, "skill_name")

-- New flexible way
player:addToNamedPile(card, "yi_pile", "义", "skill_name", 6)
player:addToNamedPile(card, "de_pile", "德", "skill_name", 8)
player:addToNamedPile(card, "custom_pile", "自定义", "skill_name", 10)
```

## Technical Details

### Room Tag Structure
- `{pile_name}`: QVariantList of card IDs in the pile
- `{pile_name}_display`: QString display name for UI

### Card Move Reasons
- Add: `S_REASON_RECYCLE` with reason string `"add{pile_name}"`
- Remove: `S_REASON_RULEDISCARD` with reason string `"remove{pile_name}"`

### Place Information
- Cards are stored in `PlaceTable` (global table area)
- `to_pile_name` / `from_pile_name` identifies the pile
- Distinct from player private piles

## Future Enhancements

Possible future additions:
- Dashboard button generation for named piles
- Visual pile indicators in UI
- Pile-specific card selection dialogs
- Dynamic pile creation from Lua
- Pile interaction callbacks

## Support

For questions or issues:
1. Check the example file: `named_pile_example.lua`
2. Review existing RenPile usage in `newgenerals.lua`
3. Test with small card limits (2-4) for debugging
