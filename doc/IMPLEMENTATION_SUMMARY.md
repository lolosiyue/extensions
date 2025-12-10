# Named Pile System Implementation Summary

## What Was Done

I've created a flexible alternative to the RenPile system that allows you to create custom card piles with customizable display names, without disrupting the original RenPile implementation.

## Files Modified

### 1. `src/new/src/server/serverplayer.h`
**Added new function declarations:**
```cpp
void addToNamedPile(const Card *card, const QString &pile_name, const QString &pile_display_name, const QString &skill_name = "", int max_cards = 6);
void addToNamedPile(int card_id, const QString &pile_name, const QString &pile_display_name, const QString &skill_name = "", int max_cards = 6);
void addToNamedPile(QList<int> card_ids, const QString &pile_name, const QString &pile_display_name, const QString &skill_name = "", int max_cards = 6);
```

### 2. `src/new/src/server/serverplayer.cpp`
**Added new function implementations:**
- Three overloaded `addToNamedPile()` functions that accept cards, card_id, or card_ids
- Supports custom pile names (e.g., "yi_pile", "de_pile")
- Supports custom display names (e.g., "义", "德", "智", "信")
- Configurable max_cards limit (default: 6)
- Automatically discards oldest cards when limit is reached
- Stores display name in room tag for UI access

### 3. `src/new/src/ui/roomscene.h`
**Added member variable:**
```cpp
QMap<QString, QList<int>> m_namedPiles; // Generic named piles support
```

### 4. `src/new/src/ui/roomscene.cpp`
**Enhanced `_processCardsMove()` function:**
- Added handling for generic named piles
- Tracks cards added to any named pile
- Tracks cards removed from any named pile
- Generates appropriate log messages
- Original ren_pile code preserved unchanged
- Automatic cleanup of empty piles

## Files Created

### 1. `named_pile_example.lua`
Complete Lua examples demonstrating:
- Creating "Yi" (义) pile
- Creating "De" (德) pile with custom limit
- Creating "Zhi" (智) pile with different max
- Using multiple cards at once
- Retrieving pile contents
- How to add translations to Common.lua

### 2. `NAMED_PILE_SYSTEM.md`
Comprehensive documentation including:
- Feature overview
- Complete C++ API reference
- Lua usage examples
- Localization guide
- Technical details
- Migration guide
- Future enhancement suggestions

## Key Features

### ✅ Original RenPile Preserved
- All existing `addToRenPile()` functions work unchanged
- No breaking changes to existing code
- Ren_pile continues to function as before

### ✅ Flexible Named Piles
- Create unlimited custom piles
- Each pile has unique internal name
- Each pile has customizable display name
- Each pile can have different max card limits

### ✅ Easy to Use
```lua
-- Old way (still works)
player:addToRenPile(card, "skill_name")

-- New flexible way
player:addToNamedPile(card, "yi_pile", "义", "skill_name", 6)
player:addToNamedPile(card, "de_pile", "德", "skill_name", 8)
```

### ✅ Full Functionality
- Automatic oldest-card removal
- Proper card move tracking
- Log message generation
- UI integration
- Room tag management

## Usage Pattern

### 1. In Lua Skills
```lua
-- Add card to custom pile
player:addToNamedPile(use.card, "yi_pile", "义", self:objectName(), 6)

-- Retrieve pile contents
local cards = room:getTag("yi_pile"):toIntList()
```

### 2. In Common.lua (Localization)
```lua
["yi_pile"] = "义",
["$addyi_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$removeyi_pile"] = "%arg2 区移出 %arg 张牌 %card",
```

## How to Test

### Test Case 1: Basic Addition
```lua
-- Should add card to yi_pile with max 6 cards
player:addToNamedPile(card, "yi_pile", "义", "test_skill", 6)
```

### Test Case 2: Overflow Handling
```lua
-- Add 7 cards, oldest should be discarded
for i = 1, 7 do
    player:addToNamedPile(card, "de_pile", "德", "test_skill", 6)
end
-- Should have 6 cards in pile
```

### Test Case 3: Multiple Piles
```lua
-- Should handle multiple independent piles
player:addToNamedPile(card1, "yi_pile", "义", "skill", 6)
player:addToNamedPile(card2, "de_pile", "德", "skill", 8)
player:addToNamedPile(card3, "zhi_pile", "智", "skill", 4)
```

## Design Principles

1. **Non-Destructive**: Original RenPile code untouched
2. **Extensible**: Easy to add more functionality
3. **Consistent**: Follows existing code patterns
4. **Flexible**: Supports arbitrary pile configurations
5. **Clean**: No code duplication, clear separation

## Technical Implementation

### Server Side
- `addToNamedPile()` creates CardsMoveStruct for removal and addition
- Stores pile contents in room tag `{pile_name}`
- Stores display name in room tag `{pile_name}_display`
- Moves cards atomically to prevent inconsistencies

### Client/UI Side  
- `_processCardsMove()` detects named pile operations
- `m_namedPiles` map tracks all active piles
- Generates log messages using pile name as key
- Falls back to pile_name if display_name not found

## Benefits Over Original RenPile

| Feature | RenPile | Named Pile |
|---------|---------|------------|
| Multiple piles | ❌ Single only | ✅ Unlimited |
| Custom display | ❌ Fixed "仁" | ✅ Any text |
| Custom limits | ❌ Fixed 6 | ✅ Configurable |
| Backward compat | ✅ N/A | ✅ Preserved |
| Easy to use | ✅ Simple | ✅ Simple |

## Next Steps

To use the new system:

1. **Read the documentation**: `NAMED_PILE_SYSTEM.md`
2. **Check examples**: `named_pile_example.lua`
3. **Add translations**: Update `Common.lua` for your piles
4. **Implement skills**: Use `addToNamedPile()` in your Lua code
5. **Test thoroughly**: Verify pile limits and card tracking

## Example Implementation

See `named_pile_example.lua` for complete, working examples of:
- Yi (义) pile for collecting slash cards
- De (德) pile for cards received
- Zhi (智) pile with custom logic
- Xin (信) pile with multiple cards

All examples include proper error handling and follow best practices.
