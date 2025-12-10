# Named Pile Quick Reference

## Quick Comparison

### Original RenPile
```lua
player:addToRenPile(card, "skill_name")
```
- Fixed name: "仁" (ren)
- Fixed limit: 6 cards
- Single global pile
- Display always "仁"

### New Named Pile
```lua
player:addToNamedPile(card, "pile_name", "display_name", "skill_name", max_cards)
```
- Custom name: "yi_pile", "de_pile", etc.
- Custom limit: any number
- Multiple independent piles
- Display: "义", "德", "智", "信", or any text

## Function Signatures

```cpp
// C++ (three overloads)
void addToNamedPile(const Card *card, const QString &pile_name, const QString &pile_display_name, const QString &skill_name = "", int max_cards = 6);
void addToNamedPile(int card_id, const QString &pile_name, const QString &pile_display_name, const QString &skill_name = "", int max_cards = 6);
void addToNamedPile(QList<int> card_ids, const QString &pile_name, const QString &pile_display_name, const QString &skill_name = "", int max_cards = 6);
```

```lua
-- Lua (auto-wrapped)
player:addToNamedPile(card, "yi_pile", "义", "skill", 6)
player:addToNamedPile(card_id, "de_pile", "德", "skill", 8)
player:addToNamedPile(card_ids, "zhi_pile", "智", "skill", 4)
```

## Common Patterns

### Pattern 1: Fixed Display Name
```lua
-- Classic virtue piles
player:addToNamedPile(card, "yi_pile", "义", skill, 6)  -- Righteousness
player:addToNamedPile(card, "de_pile", "德", skill, 6)  -- Virtue
player:addToNamedPile(card, "zhi_pile", "智", skill, 6) -- Wisdom
player:addToNamedPile(card, "xin_pile", "信", skill, 6) -- Trust
player:addToNamedPile(card, "li_pile", "礼", skill, 6)  -- Courtesy
```

### Pattern 2: Skill-Based Pile
```lua
-- Pile named after skill
local skill_name = "my_skill"
player:addToNamedPile(card, skill_name .. "_pile", "技", skill_name, 5)
```

### Pattern 3: Dynamic Display
```lua
-- Display includes count or info
local count = #room:getTag("my_pile"):toIntList()
player:addToNamedPile(card, "my_pile", "存(" .. count .. ")", skill, 10)
```

### Pattern 4: Conditional Limits
```lua
-- Vary limit based on player HP
local limit = player:getHp() * 2
player:addToNamedPile(card, "hp_pile", "生", skill, limit)
```

## Retrieval Patterns

### Get All Cards
```lua
local pile = room:getTag("yi_pile"):toIntList()
for _, id in sgs.qlist(pile) do
    local card = sgs.Sanguosha:getCard(id)
    -- use card
end
```

### Get Count
```lua
local count = room:getTag("yi_pile"):toIntList():length()
```

### Check If Empty
```lua
local is_empty = room:getTag("yi_pile"):toIntList():isEmpty()
```

### Get Display Name
```lua
local display = room:getTag("yi_pile_display"):toString()
```

## Localization Template

```lua
-- In Common.lua, add for each pile:

-- Internal name to display name
["pile_name"] = "显示",

-- Add message
["$addpile_name"] = "%from 置入 %arg2 区 %arg 张牌 %card ",

-- Remove message  
["$removepile_name"] = "%arg2 区移出 %arg 张牌 %card",
```

### Example for "Yi" Pile
```lua
["yi_pile"] = "义",
["$addyi_pile"] = "%from 置入 %arg2 区 %arg 张牌 %card ",
["$removeyi_pile"] = "%arg2 区移出 %arg 张牌 %card",
```

## Common Pile Names

| Chinese | Pinyin | English | Suggested Max |
|---------|--------|---------|---------------|
| 仁 | rén | benevolence | 6 |
| 义 | yì | righteousness | 6 |
| 礼 | lǐ | courtesy | 6 |
| 智 | zhì | wisdom | 5 |
| 信 | xìn | trust | 6 |
| 德 | dé | virtue | 8 |
| 忠 | zhōng | loyalty | 6 |
| 孝 | xiào | filial piety | 6 |
| 勇 | yǒng | courage | 5 |
| 和 | hé | harmony | 6 |

## Error Handling

```lua
-- Check card exists
if card then
    player:addToNamedPile(card, "yi_pile", "义", skill, 6)
end

-- Check card_id valid
if card_id >= 0 then
    player:addToNamedPile(card_id, "yi_pile", "义", skill, 6)
end

-- Check list not empty
if not card_ids:isEmpty() then
    player:addToNamedPile(card_ids, "yi_pile", "义", skill, 6)
end
```

## Debugging

```lua
-- Log pile contents
local pile = room:getTag("yi_pile"):toIntList()
room:sendLog("#CustomLog", "Pile has " .. pile:length() .. " cards")

-- Check display name
local display = room:getTag("yi_pile_display"):toString()
room:sendLog("#CustomLog", "Display: " .. display)

-- Verify limit working
player:addToNamedPile(card, "test", "测试", skill, 2)
local after = room:getTag("test"):toIntList():length()
-- should be <= 2
```

## Performance Tips

1. **Avoid frequent small additions**: Batch cards when possible
2. **Set appropriate limits**: Lower limits = better performance
3. **Clean up unused piles**: Remove pile tags when no longer needed
4. **Cache pile contents**: Don't query room tag repeatedly

## Common Mistakes

❌ **Forgetting localization**
```lua
player:addToNamedPile(card, "my_pile", "My", skill, 6)
-- Won't show up in logs properly
```

✅ **Correct**
```lua
-- Add to Common.lua first
player:addToNamedPile(card, "my_pile", "我的", skill, 6)
```

❌ **Using same pile name for different purposes**
```lua
player1:addToNamedPile(card, "shared", "共", skill, 6)
player2:addToNamedPile(card, "shared", "共", skill, 6)
-- Both write to same global pile!
```

✅ **Correct**
```lua
player1:addToNamedPile(card, "player1_pile", "共", skill, 6)
player2:addToNamedPile(card, "player2_pile", "共", skill, 6)
```

❌ **Forgetting max_cards parameter**
```lua
-- Always defaults to 6
player:addToNamedPile(card, "big_pile", "大")
```

✅ **Correct**
```lua
player:addToNamedPile(card, "big_pile", "大", skill, 20)
```

## Migration Checklist

- [ ] Identify skills using piles
- [ ] Choose pile names and display names
- [ ] Add localization to Common.lua
- [ ] Replace or add addToNamedPile calls
- [ ] Test with various card counts
- [ ] Test limit enforcement (add max_cards + 1)
- [ ] Verify log messages appear correctly
- [ ] Test retrieval logic
- [ ] Document skill behavior

## Support

- **Examples**: `named_pile_example.lua`
- **Full docs**: `NAMED_PILE_SYSTEM.md`
- **Summary**: `IMPLEMENTATION_SUMMARY.md`
- **Original**: Search for `addToRenPile` usage in codebase
