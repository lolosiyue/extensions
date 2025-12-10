# Named Pile System Architecture

## System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         Lua Layer                                │
│  player:addToNamedPile(card, "yi_pile", "义", skill, 6)        │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    C++ Server Layer                              │
│  ServerPlayer::addToNamedPile()                                 │
│    ├─ Validate parameters                                       │
│    ├─ Get current pile from room tag                           │
│    ├─ Remove oldest if > max_cards                             │
│    ├─ Create CardsMoveStruct (remove old)                      │
│    ├─ Create CardsMoveStruct (add new)                         │
│    ├─ Store display name in room tag                           │
│    └─ Execute moveCardsAtomic()                                │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Room/Game State                             │
│  Room Tags:                                                      │
│    ├─ "yi_pile" → [card_id1, card_id2, ...]                    │
│    ├─ "yi_pile_display" → "义"                                 │
│    ├─ "de_pile" → [card_id3, card_id4, ...]                    │
│    └─ "de_pile_display" → "德"                                 │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                    C++ Client/UI Layer                           │
│  RoomScene::_processCardsMove()                                 │
│    ├─ Detect pile name in CardsMoveStruct                      │
│    ├─ Track in m_namedPiles map                                │
│    ├─ Update UI elements (if any)                              │
│    └─ Generate log messages                                    │
└────────────────────────┬────────────────────────────────────────┘
                         │
                         ▼
┌─────────────────────────────────────────────────────────────────┐
│                         UI Display                               │
│  Log Messages:                                                   │
│    "$addyi_pile"  → "XXX 置入 义 区 2 张牌 ..."                │
│    "$removeyi_pile" → "义 区移出 1 张牌 ..."                    │
└─────────────────────────────────────────────────────────────────┘
```

## Data Flow: Adding Cards

```
Step 1: Lua Call
┌────────────────────────────────────────┐
│ player:addToNamedPile(                 │
│   card,         -- 【杀】             │
│   "yi_pile",    -- internal name      │
│   "义",         -- display text       │
│   "yipile",     -- skill name         │
│   6             -- max cards          │
│ )                                      │
└──────────────┬─────────────────────────┘
               │
               ▼
Step 2: Extract Card IDs
┌────────────────────────────────────────┐
│ if card is virtual:                    │
│   card_ids = card->getSubcards()       │
│ else:                                  │
│   card_ids = [card->getId()]           │
└──────────────┬─────────────────────────┘
               │
               ▼
Step 3: Check Current Pile
┌────────────────────────────────────────┐
│ pile = room->getTag("yi_pile")         │
│ Current: [101, 102, 103, 104, 105]    │
│ Adding: [106]                          │
│ Limit: 6 cards                         │
│ Action: OK, within limit              │
└──────────────┬─────────────────────────┘
               │
               ▼
Step 4: Handle Overflow (if needed)
┌────────────────────────────────────────┐
│ if pile.length >= max_cards:           │
│   remove_ids = [101]  (oldest)         │
│   pile = [102, 103, 104, 105]         │
└──────────────┬─────────────────────────┘
               │
               ▼
Step 5: Create Remove Move
┌────────────────────────────────────────┐
│ CardsMoveStruct move1:                 │
│   card_ids: [101]                      │
│   from: PlaceTable                     │
│   from_pile_name: "yi_pile"            │
│   to: nullptr                          │
│   to_place: DiscardPile                │
│   reason: RULEDISCARD/removeyi_pile    │
└──────────────┬─────────────────────────┘
               │
               ▼
Step 6: Create Add Move
┌────────────────────────────────────────┐
│ CardsMoveStruct move2:                 │
│   card_ids: [106]                      │
│   from: (varies)                       │
│   to: nullptr                          │
│   to_place: PlaceTable                 │
│   to_pile_name: "yi_pile"              │
│   reason: RECYCLE/addyi_pile           │
└──────────────┬─────────────────────────┘
               │
               ▼
Step 7: Store Display Name
┌────────────────────────────────────────┐
│ room->setTag(                          │
│   "yi_pile_display",                   │
│   "义"                                 │
│ )                                      │
└──────────────┬─────────────────────────┘
               │
               ▼
Step 8: Execute Moves
┌────────────────────────────────────────┐
│ room->moveCardsAtomic(                 │
│   [move1, move2],                      │
│   true  // visible                     │
│ )                                      │
└──────────────┬─────────────────────────┘
               │
               ▼
Step 9: UI Processing
┌────────────────────────────────────────┐
│ RoomScene::_processCardsMove()         │
│                                        │
│ For move1 (remove):                    │
│   - Remove 101 from m_namedPiles       │
│   - Log: "$removeyi_pile"              │
│                                        │
│ For move2 (add):                       │
│   - Add 106 to m_namedPiles            │
│   - Log: "$addyi_pile"                 │
└──────────────┬─────────────────────────┘
               │
               ▼
Step 10: Final State
┌────────────────────────────────────────┐
│ Room Tags:                             │
│   "yi_pile": [102,103,104,105,106]    │
│   "yi_pile_display": "义"              │
│                                        │
│ UI State:                              │
│   m_namedPiles["yi_pile"]:             │
│     [102,103,104,105,106]             │
│                                        │
│ Log Display:                           │
│   "XXX 置入 义 区 1 张牌【杀】"        │
└────────────────────────────────────────┘
```

## Comparison: Original vs New

```
┌─────────────────────────────────────────────────────────────────┐
│                    Original RenPile System                       │
└─────────────────────────────────────────────────────────────────┘

Lua: player:addToRenPile(card, skill)
         │
         ▼
C++: ServerPlayer::addToRenPile(card, skill)
         │
         ├─ Hardcoded: pile_name = "ren_pile"
         ├─ Hardcoded: display = "仁"
         ├─ Hardcoded: max_cards = 6
         │
         ▼
     Room Tag: "ren_pile" → [cards...]
         │
         ▼
UI: Special handling for "ren_pile" only
     │
     └─ Display: "仁（n）"


┌─────────────────────────────────────────────────────────────────┐
│                     New Named Pile System                        │
└─────────────────────────────────────────────────────────────────┘

Lua: player:addToNamedPile(card, name, display, skill, max)
         │
         ▼
C++: ServerPlayer::addToNamedPile(card, name, display, skill, max)
         │
         ├─ Dynamic: pile_name = parameter
         ├─ Dynamic: display = parameter
         ├─ Dynamic: max_cards = parameter
         │
         ▼
     Room Tags: 
         "{name}" → [cards...]
         "{name}_display" → display
         │
         ▼
UI: Generic handling for any pile_name
     │  (checks m_namedPiles map)
     │
     └─ Display: "{display}（n）"


Benefits:
✅ Multiple piles: "yi_pile", "de_pile", "zhi_pile"...
✅ Custom displays: "义", "德", "智"...
✅ Custom limits: 4, 6, 8, 10...
✅ Original unchanged: addToRenPile still works
✅ Extensible: Easy to add new piles
```

## Multi-Pile Scenario

```
Game State with Multiple Active Piles:

┌──────────────────────────────────────────────────────────────┐
│ Player A                                                      │
│                                                               │
│ Room Tags:                                                    │
│   "yi_pile" → [101, 102, 103, 104, 105]    (5 cards)        │
│   "yi_pile_display" → "义"                                   │
│                                                               │
│   "de_pile" → [201, 202, 203, 204, 205, 206, 207]  (7 cards)│
│   "de_pile_display" → "德"                                   │
│                                                               │
│   "ren_pile" → [301, 302, 303, 304]  (4 cards - original)   │
│                                                               │
│   "custom_pile" → [401, 402]  (2 cards)                      │
│   "custom_pile_display" → "特"                               │
│                                                               │
│ UI State (m_namedPiles):                                      │
│   "yi_pile" → [101, 102, 103, 104, 105]                     │
│   "de_pile" → [201, 202, 203, 204, 205, 206, 207]           │
│   "custom_pile" → [401, 402]                                 │
│                                                               │
│ (RenPile handled separately by original code)                │
└──────────────────────────────────────────────────────────────┘

All piles are independent and can be managed separately!
```

## Thread Safety Note

```
┌─────────────────────────────────────────────────────────────┐
│ All operations go through Room::moveCardsAtomic()           │
│                                                              │
│ This ensures:                                                │
│   ✓ Atomic execution                                        │
│   ✓ Proper event triggering                                 │
│   ✓ Consistent game state                                   │
│   ✓ Synchronized UI updates                                 │
│                                                              │
│ No manual synchronization needed!                           │
└─────────────────────────────────────────────────────────────┘
```
