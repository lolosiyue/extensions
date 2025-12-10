# Named Pile System - Complete Implementation

## 📋 Overview

This implementation provides a flexible, extensible system for creating custom card piles in Sanguosha, similar to the "仁" (Ren) pile but with customizable names, display text, and limits. **The original RenPile system is fully preserved and continues to work unchanged.**

## 🎯 Key Features

- ✅ **Multiple Independent Piles**: Create unlimited piles (Yi, De, Zhi, Xin, Li, etc.)
- ✅ **Custom Display Names**: Each pile can have unique display text
- ✅ **Configurable Limits**: Set different max card counts per pile
- ✅ **Backward Compatible**: Original `addToRenPile()` unchanged
- ✅ **Full UI Integration**: Automatic logging and tracking
- ✅ **Easy to Use**: Simple Lua API with sensible defaults

## 📁 Files Included

### Documentation
- **`NAMED_PILE_SYSTEM.md`** - Complete system documentation
- **`IMPLEMENTATION_SUMMARY.md`** - Summary of all changes
- **`NAMED_PILE_QUICK_REFERENCE.md`** - Quick developer reference
- **`ARCHITECTURE_DIAGRAM.md`** - Visual system architecture
- **`README_NAMED_PILE.md`** - This file

### Code Files
- **`named_pile_example.lua`** - Usage examples
- **`named_pile_test_extension.lua`** - Complete test package with working generals

### Modified Source Files
- `src/new/src/server/serverplayer.h` - Added function declarations
- `src/new/src/server/serverplayer.cpp` - Added implementations
- `src/new/src/ui/roomscene.h` - Added member variable
- `src/new/src/ui/roomscene.cpp` - Enhanced UI processing

## 🚀 Quick Start

### 1. Basic Usage

```lua
-- Add card to custom pile
player:addToNamedPile(
    card,              -- The card to add
    "yi_pile",         -- Internal pile name
    "义",              -- Display name
    "skill_name",      -- Skill triggering this
    6                  -- Max cards (optional, default 6)
)
```

### 2. Retrieve Pile Contents

```lua
-- Get all cards from pile
local pile = room:getTag("yi_pile"):toIntList()
for _, id in sgs.qlist(pile) do
    local card = sgs.Sanguosha:getCard(id)
    -- Use card
end

-- Get count
local count = room:getTag("yi_pile"):toIntList():length()
```

### 3. Add Localization

```lua
-- In Common.lua
["yi_pile"] = "义",
["$addyi_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$removeyi_pile"] = "%arg2 区移出 %arg 张牌 %card",
```

## 📖 Complete Examples

### Example 1: Righteousness (义) Pile
```lua
local yi_skill = sgs.CreateTriggerSkill{
    name = "yi_skill",
    events = {sgs.CardUsed},
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        if use.card:isKindOf("Slash") then
            player:addToNamedPile(use.card, "yi_pile", "义", self:objectName(), 6)
        end
        return false
    end,
}
```

### Example 2: Virtue (德) Pile with Higher Limit
```lua
local de_skill = sgs.CreateTriggerSkill{
    name = "de_skill",
    events = {sgs.CardsMoveOneTime},
    on_trigger = function(self, event, player, data, room)
        local move = data:toMoveOneTime()
        if move.to and move.to:objectName() == player:objectName() then
            if not move.card_ids:isEmpty() then
                player:addToNamedPile(
                    move.card_ids:first(),
                    "de_pile",
                    "德",
                    self:objectName(),
                    8  -- Higher limit
                )
            end
        end
        return false
    end,
}
```

### Example 3: Multiple Cards at Once
```lua
-- Add multiple cards to pile
local cards = sgs.IntList()
for i = 1, 3 do
    cards:append(room:drawCard())
end
player:addToNamedPile(cards, "xin_pile", "信", "skill", 10)
```

## 🧪 Testing

A complete test package is provided in `named_pile_test_extension.lua`:

1. **Test General 1: Zhang Wude (张武德)**
   - Demonstrates Yi/De/Zhi/Xin piles
   - Shows different limits and triggers
   - Includes debug commands

2. **Test General 2: Li Dexin (李德信)**
   - Compares original RenPile with new system
   - Shows both can coexist

### To Test:
```lua
-- Load the test extension
-- Select test general in game
-- Use cards to trigger pile additions
-- Use "show_piles" skill to see contents
```

## 📊 Comparison Table

| Feature | Original RenPile | New Named Pile |
|---------|------------------|----------------|
| **Multiple Piles** | ❌ Single only | ✅ Unlimited |
| **Custom Display** | ❌ Fixed "仁" | ✅ Any text |
| **Custom Limits** | ❌ Fixed 6 | ✅ Configurable |
| **Backward Compat** | ✅ N/A | ✅ Preserved |
| **Easy to Use** | ✅ Simple | ✅ Simple |
| **UI Integration** | ✅ Complete | ✅ Complete |

## 🔧 API Reference

### C++ Functions

```cpp
void ServerPlayer::addToNamedPile(
    const Card *card,
    const QString &pile_name,
    const QString &pile_display_name,
    const QString &skill_name = "",
    int max_cards = 6
);

void ServerPlayer::addToNamedPile(
    int card_id,
    const QString &pile_name,
    const QString &pile_display_name,
    const QString &skill_name = "",
    int max_cards = 6
);

void ServerPlayer::addToNamedPile(
    QList<int> card_ids,
    const QString &pile_name,
    const QString &pile_display_name,
    const QString &skill_name = "",
    int max_cards = 6
);
```

### Lua Wrapper (Auto-generated)

```lua
player:addToNamedPile(card, pile_name, display_name, skill_name, max_cards)
player:addToNamedPile(card_id, pile_name, display_name, skill_name, max_cards)
player:addToNamedPile(card_ids, pile_name, display_name, skill_name, max_cards)
```

## 💡 Common Use Cases

### 1. Virtue System (德行系统)
```lua
-- Five virtues: 仁义礼智信
player:addToNamedPile(card, "ren_virtue", "仁", skill, 6)
player:addToNamedPile(card, "yi_virtue", "义", skill, 6)
player:addToNamedPile(card, "li_virtue", "礼", skill, 6)
player:addToNamedPile(card, "zhi_virtue", "智", skill, 6)
player:addToNamedPile(card, "xin_virtue", "信", skill, 6)
```

### 2. Element System (元素系统)
```lua
-- Five elements: 金木水火土
player:addToNamedPile(card, "jin_element", "金", skill, 8)
player:addToNamedPile(card, "mu_element", "木", skill, 8)
player:addToNamedPile(card, "shui_element", "水", skill, 8)
player:addToNamedPile(card, "huo_element", "火", skill, 8)
player:addToNamedPile(card, "tu_element", "土", skill, 8)
```

### 3. Resource System (资源系统)
```lua
-- Different resources with different limits
player:addToNamedPile(card, "gold", "金币", skill, 20)
player:addToNamedPile(card, "food", "粮草", skill, 15)
player:addToNamedPile(card, "weapon", "兵器", skill, 10)
```

## 🛠️ Troubleshooting

### Problem: Cards not appearing in pile
**Solution**: Check if localization is added to Common.lua

### Problem: Pile overflow not working
**Solution**: Verify max_cards parameter is set correctly

### Problem: Log messages not showing
**Solution**: Ensure log keys ("$add{pile_name}") are in Common.lua

### Problem: Multiple generals using same pile
**Solution**: Use unique pile names per general or make it intentional

## 📝 Migration Guide

### From RenPile to Named Pile

**Before:**
```lua
player:addToRenPile(card, skill_name)
```

**After (both work!):**
```lua
-- Old way still works
player:addToRenPile(card, skill_name)

-- New flexible way
player:addToNamedPile(card, "yi_pile", "义", skill_name, 6)
```

## 🎓 Learning Path

1. **Start Here**: `NAMED_PILE_QUICK_REFERENCE.md`
2. **See Examples**: `named_pile_example.lua`
3. **Test It**: `named_pile_test_extension.lua`
4. **Deep Dive**: `NAMED_PILE_SYSTEM.md`
5. **Understand Design**: `ARCHITECTURE_DIAGRAM.md`

## 🤝 Contributing

To add more features:
1. Modify `serverplayer.h/cpp` for server logic
2. Update `roomscene.h/cpp` for UI handling
3. Add examples to `named_pile_example.lua`
4. Update documentation

## 📄 License

Same as the main Sanguosha project.

## 🙏 Acknowledgments

- Original RenPile system design
- Sanguosha engine architecture
- Community feedback and testing

## 📞 Support

For questions or issues:
1. Read the documentation thoroughly
2. Check the examples
3. Test with the provided test extension
4. Review the architecture diagram

---

**Version**: 1.0  
**Date**: 2025-11-18  
**Status**: Complete and tested

**Summary**: This implementation provides a complete, backward-compatible, flexible pile system that extends the original RenPile concept while preserving all existing functionality.
