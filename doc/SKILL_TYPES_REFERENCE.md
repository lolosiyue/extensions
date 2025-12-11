# Sanguosha Extension Skill Types Reference

This document provides a comprehensive overview of different skill types used in the Sanguosha extensions project. Each skill type serves a specific purpose in the game mechanics.

## Skill Type Classification

### 1. Basic Skill Types

| Skill Type | Description | Common Use Cases |
|------------|-------------|------------------|
| **CreateTriggerSkill** | Triggers on specific game events | Most common skill type; handles card usage, damage, phase changes, etc. |
| **CreateViewAsSkill** | Converts cards into other cards | Transform hand cards into different card types (e.g., treating any card as Slash) |
| **CreateTargetModSkill** | Modifies targeting rules | Changes target numbers, distance requirements for card usage |

### 2. Card Conversion Skills

| Skill Type | Description | Common Use Cases |
|------------|-------------|------------------|
| **CreateViewAsSkill** | Multi-card conversion | Convert multiple cards into one card (flexible combinations) |
| **CreateOneCardViewAsSkill** | Single-card conversion | Convert exactly one card into another card type |
| **CreateZeroCardViewAsSkill** | Zero-card conversion | Convert exactly one card into another card type |

### 3. Modification Skills

| Skill Type | Description | Common Use Cases |
|------------|-------------|------------------|
| **CreateFilterSkill** | Filters/modifies card properties | Change card suits, colors, or types (e.g., all hearts become diamonds) |
| **CreateTargetModSkill** | Modifies targeting parameters | Change number of targets, extra targets, or distance requirements |
| **CreateProhibitSkill** | Prohibits certain actions | Prevent specific cards from being used or players from being targeted |
| **CreateInvalidSkill** | Invalidates certain effects | Make certain cards or skills ineffective against a player |

### 4. Range and Distance Skills

| Skill Type | Description | Common Use Cases |
|------------|-------------|------------------|
| **CreateDistanceSkill** | Modifies distance between players | Increase/decrease distance calculation (like horses) |
| **CreateAttackRangeSkill** | Modifies attack range | Change the attack range of a player |

### 5. Capacity Skills

| Skill Type | Description | Common Use Cases |
|------------|-------------|------------------|
| **CreateMaxCardsSkill** | Modifies hand card limit | Change the maximum number of cards a player can hold during discard phase |

### 6. Equipment Skills

| Skill Type | Description | Common Use Cases |
|------------|-------------|------------------|
| **CreateViewAsEquipSkill** | View as equipment effects | Useing equip effect without equip |

## Skill Type Details

### CreateTriggerSkill

**Most Common Skill Type**

**Typical Structure:**
```lua
skill_name = sgs.CreateTriggerSkill {
    name = "skill_name",
    events = {sgs.EventName},
    on_trigger = function(self, event, player, data, room)
        -- skill logic
    end,
    can_trigger = function(self, event, room, player, data)
        -- trigger conditions
    end,
    -- other optional properties
}
```

**Common Events:**
- Card usage/response events
- Damage dealing/receiving events
- Phase change events
- Drawing/discarding events

#### Common TriggerSkill Migration Quick Reference

| Old Pattern | New Pattern | Reason |
|-------------|-------------|--------|
| `EventPhaseStart` | `EventPhaseProceeding` | Correct timing for phase actions |
| `DamageCaused` (for +damage) | `ConfirmDamage` | Better timing for damage mods |
| `Player_Extra` | `Player_PhaseExtra` | Correct phase constant |
| `card:getSkillName() == "x"` | `table.contains(card:getSkillNames(), "x")` | Multiple skill support |
| Duplicate extra turn code | Helper function or consolidated check | Reduce duplication |
| Not cleaning up on skill loss | Clean piles, marks, descriptions | Prevent memory/state issues |
| `judge.card` without throw_card | `judge.throw_card = false` | Keep judge card |
| No marks for shiming | `skillname__success`, `skillname__fail` | Track shiming results |
| Double resolution without alive check | Check `isAlive()` for each target | Targets may die during first use |
| Custom effect without nullification check | Check `effect.nullified` and `room:isCanceled()` | Ignores armor/skills that nullify |

#### Maintenance Requirements for CreateTriggerSkill

**1. Phase Event Selection - CRITICAL CHANGE**

**EventPhaseStart vs EventPhaseProceeding:**

Most skills using `EventPhaseStart` should be changed to `EventPhaseProceeding`.

| Event | When It Triggers | Use Case |
|-------|------------------|----------|
| **EventPhaseStart** | Before phase begins | Phase setup, initialization, rarely needed |
| **EventPhaseProceeding** | During phase execution | Most skill effects, normal phase actions |

**Migration Pattern:**

```lua
-- ❌ OLD - Usually incorrect
skill_name = sgs.CreateTriggerSkill {
    name = "skill_name",
    events = {sgs.EventPhaseStart},
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() ~= sgs.Player_Play then return false end
        -- skill logic
    end,
}

-- ✅ NEW - Correct for most cases
skill_name = sgs.CreateTriggerSkill {
    name = "skill_name",
    events = {sgs.EventPhaseProceeding},  -- Changed!
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() ~= sgs.Player_Play then return false end
        -- skill logic
    end,
}
```

**When to use EventPhaseStart:**
- Setting up phase-specific flags/marks BEFORE phase begins
- Preventing phase from starting (rare)

**When to use EventPhaseProceeding:**
- Normal skill effects during a phase
- Most card usage, drawing, damage skills
- Skills that interact with phase actions

---

**2. Skill Invoked Timing**

Consider when `room:notifySkillInvoked()` or `room:broadcastSkillInvoke()` should be called:

```lua
on_trigger = function(self, event, player, data, room)
    -- Check conditions first
    if not player:hasSkill(self:objectName()) then return false end
    
    -- THEN notify/invoke (after validation, before effects)
    room:notifySkillInvoked(player, self:objectName())
    room:broadcastSkillInvoke(self:objectName(), player)
    
    -- Finally apply effects
    player:drawCards(2)
    return false
end,
```

**Best Practice:**
1. Validate all conditions
2. Notify/invoke skill
3. Apply effects

---

**3. Dynamic Skill Descriptions (changeTranslation)**

For skills with dynamic text (showing accumulated cards/counts):

**Complete Pattern:**

```lua
-- Step 1: Read existing record
local names = player:property("SkillDescriptionRecord_skillname"):toString():split("+")
local new_name = card:objectName()

-- Step 2: Add new data
table.insert(names, new_name)

-- Step 3: Save to property
room:setPlayerProperty(
    player,
    "SkillDescriptionRecord_skillname",
    sgs.QVariant(table.concat(names, "+"))
)

-- Step 4: Set description swap (placeholder → actual data)
player:setSkillDescriptionSwap(
    "skillname",     -- skill name
    "%arg11",        -- placeholder in translation
    table.concat(names, "+")  -- actual data to display
)

-- Step 5: Change translation to refresh
room:changeTranslation(player, "skillname", 11)
```

**Example - Leiji (Collecting Cards):**

```lua
on_trigger = function(self, event, player, data, room)
    local card = data:toCard()
    
    -- Read existing record
    local names = player:property("SkillDescriptionRecord_hmrleiji"):toString():split("+")
    local name = card:objectName()
    
    -- Add new card
    table.insert(names, name)
    
    -- Save record
    room:setPlayerProperty(
        player,
        "SkillDescriptionRecord_hmrleiji",
        sgs.QVariant(table.concat(names, "+"))
    )
    
    -- Update description display
    player:setSkillDescriptionSwap("hmrleiji", "%arg11", table.concat(names, "+"))
    room:changeTranslation(player, "hmrleiji", 11)
    
    return false
end,
```

**Key Points:**
- Property name: `SkillDescriptionRecord_[skillname]`
- Use `split("+")` to parse existing data
- Use `table.concat(names, "+")` to save
- Placeholder format: `%arg` followed by number
- `changeTranslation` second parameter matches placeholder number

---

**4. Damage +1 Event Change**

**Event Selection for Damage Increase:**

| Old Event | New Event | Reason |
|-----------|-----------|--------|
| **DamageCaused** | **ConfirmDamage** | Better timing, prevents issues |

**Migration Pattern:**

```lua
-- ❌ OLD - May have timing issues
damage_skill = sgs.CreateTriggerSkill {
    name = "damage_skill",
    events = {sgs.DamageCaused},
    
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        damage.damage = damage.damage + 1
        data:setValue(damage)
        return false
    end,
}

-- ✅ NEW - Correct timing
damage_skill = sgs.CreateTriggerSkill {
    name = "damage_skill",
    events = {sgs.ConfirmDamage},  -- Changed!
    
    on_trigger = function(self, event, player, data, room)
        local damage = data:toDamage()
        damage.damage = damage.damage + 1
        data:setValue(damage)
        return false
    end,
}
```

**Why ConfirmDamage is Better:**
- Triggers after damage is fully confirmed
- Avoids conflicts with prevention skills
- More reliable for damage modifications

---

**5. Skill Loss - Cleanup Requirements**

**When a player loses a skill, clean up associated resources:**

**What to Clean:**
- Skill piles (cards stored by the skill)
- Skill marks (counters, flags, states)
- Skill-specific tags
- Dynamic skill descriptions

**Standard Cleanup Pattern:**

```lua
-- On EventLoseSkill or similar
on_trigger = function(self, event, player, data, room)
    if data:toString() ~= self:objectName() then return false end
    
    -- 1. Clear skill piles
    local pile_name = self:objectName() .. "_pile"
    if not player:getPile(pile_name):isEmpty() then
        player:clearPrivatePiles()  -- or specific pile removal
    end
    
    -- 2. Remove skill marks
    room:setPlayerMark(player, self:objectName() .. "_mark", 0)
    room:setPlayerMark(player, "@" .. self:objectName(), 0)  -- visible marks
    
    -- 3. Clear skill description records
    room:setPlayerProperty(
        player,
        "SkillDescriptionRecord_" .. self:objectName(),
        sgs.QVariant("")
    )
    
    -- 4. Reset skill description swap
    player:setSkillDescriptionSwap(self:objectName(), "", "")
    
    return false
end,
```

**Example - Complete Skill Loss Handler:**

```lua
-- EventLoseSkill trigger for skill with pile and marks
skill_lose = sgs.CreateTriggerSkill {
    name = "#skill_lose",
    events = {sgs.EventLoseSkill},
    
    on_trigger = function(self, event, player, data, room)
        if data:toString() ~= "main_skill" then return false end
        
        -- Clear pile
        local pile = player:getPile("main_skill")
        if not pile:isEmpty() then
            local dummy = sgs.DummyCard()
            for _, id in sgs.qlist(pile) do
                dummy:addSubcard(id)
            end
            local reason = sgs.CardMoveReason(
                sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,
                player:objectName()
            )
            room:throwCard(dummy, reason, nil)
            dummy:deleteLater()
        end
        
        -- Clear marks
        room:setPlayerMark(player, "main_skill_count", 0)
        room:setPlayerMark(player, "@main_skill_token", 0)
        
        return false
    end,
}
```

**Checklist for Skill Loss:**
- [ ] Remove all skill-related piles
- [ ] Clear all skill marks (both hidden and visible @marks)
- [ ] Clear skill description records
- [ ] Remove skill tags
- [ ] Reset any modified player properties

---

**6. Judge Card Handling**

**When getting judge cards, set throw_card = false to prevent auto-discard:**

**Standard Judge Pattern:**

```lua
on_trigger = function(self, event, player, data, room)
    local judge = data:toJudge()
    
    -- Set throw_card to false to keep the card
    judge.throw_card = false
    data:setValue(judge)
    
    -- Now you can manipulate the judge card
    local card_id = judge.card:getEffectiveId()
    
    -- Move to specific location or give to player
    room:obtainCard(player, card_id, false)
    
    return false
end,
```

**When to Use:**
- Getting judge card into hand/equipment
- Moving judge card to pile
- Preventing automatic discard of judge card

**Example - Guicai (Ghost Talent) Style:**

```lua
guicai_style = sgs.CreateTriggerSkill {
    name = "guicai_style",
    events = {sgs.AskForRetrial},
    
    on_trigger = function(self, event, player, data, room)
        local judge = data:toJudge()
        
        -- Ask player to change judge
        local card = room:askForCard(player, ".|.|.|hand", "@guicai", data, sgs.Card_MethodResponse)
        if card then
            -- Keep original judge card (don't throw it)
            judge.throw_card = false
            data:setValue(judge)
            
            -- Get original card to hand
            room:obtainCard(player, judge.card, false)
            
            -- Replace with new card
            judge.card = sgs.Sanguosha:getCard(card:getEffectiveId())
            data:setValue(judge)
            
            room:broadcastSkillInvoke(self:objectName())
        end
        
        return false
    end,
}
```

---

**7. Shiming (Show/Reveal) Skill Standard Pattern**

**Use success/fail marks to track shiming skill results:**

**Standard Mark Names:**
- `skillname__success` - Successful shiming (single underscore before mark type)
- `skillname__fail` - Failed shiming

**Complete Shiming Pattern:**

```lua
shiming_skill = sgs.CreateTriggerSkill {
    name = "shiming_skill",
    events = {sgs.CardAsked},
    
    on_trigger = function(self, event, player, data, room)
        -- Ask to show/reveal cards
        local pattern = data:toStringList()[1]
        
        local ids = room:askForExchange(
            player,
            self:objectName(),
            1,
            1,
            true,
            "@shiming:" .. pattern,
            true
        )
        
        if ids:isEmpty() then return false end
        
        -- Show the card
        local card_id = ids:first()
        local card = sgs.Sanguosha:getCard(card_id)
        
        room:showCard(player, card_id)
        
        -- Check if it matches
        if card:objectName() == pattern or card:isKindOf(pattern) then
            -- Success
            room:setPlayerMark(player, self:objectName() .. "__success", 1)
            room:setPlayerMark(player, self:objectName() .. "__fail", 0)
            
            -- Provide the card
            room:provide(card)
            return true
        else
            -- Fail
            room:setPlayerMark(player, self:objectName() .. "__fail", 1)
            room:setPlayerMark(player, self:objectName() .. "__success", 0)
            
            -- Optional penalty for failure
            room:loseHp(player, 1)
        end
        
        return false
    end,
}
```

**Mark Usage Benefits:**
- Track success/failure state
- Trigger follow-up effects based on result
- AI can evaluate risk/reward
- Clear state tracking

**Mark Naming Convention:**
```lua
-- Double underscore before state type
player:getMark("skillname__success")  -- Success state
player:getMark("skillname__fail")     -- Failure state
player:getMark("skillname__active")   -- Active state
player:getMark("skillname__used")     -- Used state
```

---

**8. Card Double Resolution (此牌结算两次)**

**For skills that make cards resolve twice, check target alive status:**

**Standard Double Resolution Pattern:**

```lua
double_resolution = sgs.CreateTriggerSkill {
    name = "double_resolution",
    events = {sgs.CardFinished},
    frequency = sgs.Skill_Frequent,
    
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        
        -- Check if this is the original user
        if use.from:objectName() ~= player:objectName() then
            return false
        end
        
        -- Check card type (usually Slash, but can be others)
        if not use.card:isKindOf("Slash") then
            return false
        end
        
        -- Build list of alive targets only
        local targets = sgs.SPlayerList()
        for _, to in sgs.qlist(use.to) do
            if to:isAlive() then  -- CRITICAL: Check alive
                targets:append(to)
            end
        end
        
        -- Only proceed if there are valid targets
        if targets:isEmpty() then
            return false
        end
        
        -- Ask if want to use again (for frequent skills)
        if not room:askForSkillInvoke(player, self:objectName(), data) then
            return false
        end
        
        room:broadcastSkillInvoke(self:objectName())
        
        -- Create new use struct with alive targets only
        local use_again = sgs.CardUseStruct(use.card, player, targets)
        
        -- Set UseHistory tag to track this usage
        room:setTag("UseHistory" .. use.card:toString(), sgs.QVariant_fromValue(use_again))
        
        -- Execute the card again
        use.card:use(room, player, targets)
        
        return false
    end,
}
```

**Critical Points for Double Resolution:**

1. **Always check isAlive()** - Targets may die during first resolution
2. **Build new target list** - Don't reuse original use.to
3. **Check isEmpty()** - Don't proceed if no valid targets remain
4. **Update UseHistory** - Prevents infinite loops and tracks usage
5. **Create new CardUseStruct** - Fresh struct for second resolution

**Common Mistakes:**

```lua
-- ❌ WRONG - Doesn't check if targets are alive
for _, to in sgs.qlist(use.to) do
    targets:append(to)  -- May append dead players!
end

-- ❌ WRONG - Reuses original use struct
use.card:use(room, player, use.to)  -- Original targets may be dead

-- ✅ CORRECT - Checks alive and builds new list
local targets = sgs.SPlayerList()
for _, to in sgs.qlist(use.to) do
    if to:isAlive() then
        targets:append(to)
    end
end
if not targets:isEmpty() then
    local use_again = sgs.CardUseStruct(use.card, player, targets)
    room:setTag("UseHistory" .. use.card:toString(), sgs.QVariant_fromValue(use_again))
    use.card:use(room, player, targets)
end
```

**Example - Lianhuan (Chain) Style Double Slash:**

```lua
lianhuan_double = sgs.CreateTriggerSkill {
    name = "lianhuan",
    events = {sgs.CardFinished},
    
    on_trigger = function(self, event, player, data, room)
        local use = data:toCardUse()
        
        if use.from:objectName() ~= player:objectName() then return false end
        if not use.card:isKindOf("Slash") then return false end
        
        -- Collect alive chained targets
        local targets = sgs.SPlayerList()
        for _, to in sgs.qlist(use.to) do
            if to:isAlive() and to:isChained() then
                targets:append(to)
            end
        end
        
        if targets:isEmpty() then return false end
        
        room:broadcastSkillInvoke(self:objectName())
        room:sendLog("#skill_double_resolution", player, self:objectName())
        
        -- Second resolution
        local use_again = sgs.CardUseStruct(use.card, player, targets)
        room:setTag("UseHistory" .. use.card:toString(), sgs.QVariant_fromValue(use_again))
        use.card:use(room, player, targets)
        
        return false
    end,
}
```

---

**9. Custom Card Effect Resolution (改結算方式)**

**For skills that completely override card resolution logic:**

When implementing custom card effects, you must handle nullification and cancellation properly.

**Critical Checks Required:**

1. **effect.nullified** - Effect was nullified by skills/armor
2. **room:isCanceled(effect)** - Effect was canceled (stored in effect.offset_card)

**Complete Custom Resolution Pattern:**

```lua
custom_effect = sgs.CreateTriggerSkill {
    name = "custom_effect",
    events = {sgs.CardEffected},  -- Use CardEffected for custom resolution
    
    on_trigger = function(self, event, player, data, room)
        local effect = data:toCardEffect()
        
        -- Check if this is our card
        if not effect.card:isKindOf("Duel") then return false end
        if not table.contains(effect.card:getSkillNames(), self:objectName()) then
            return false
        end
        
        -- STEP 1: Check if effect is nullified
        if effect.nullified then
            local log = sgs.LogMessage()
            log.type = "#CardNullified"
            log.from = effect.to
            log.card_str = effect.card:toString()
            room:sendLog(log)
            return true  -- Stop here, effect is nullified
        end
        
        -- STEP 2: Check if effect is canceled (offset)
        if not effect.offset_card then
            effect.offset_card = room:isCanceled(effect)
        end
        
        if effect.offset_card then
            data:setValue(effect)
            
            -- Trigger CardOffset event
            if not room:getThread():trigger(sgs.CardOffset, room, effect.from, data) then
                effect.to:setFlags("Global_NonSkillNullify")
                return true  -- Effect was offset
            end
        end
        
        -- STEP 3: Trigger CardOnEffect (for other skills to respond)
        room:getThread():trigger(sgs.CardOnEffect, room, effect.to, data)
        
        -- STEP 4: Custom resolution logic
        if effect.to:isAlive() then
            -- Your custom card effect implementation here
            -- Example: Custom Duel resolution
            local second = effect.from
            local first = effect.to
            
            room:setEmotion(second, "duel")
            room:setEmotion(first, "duel")
            
            while first:isAlive() do
                local slash = "slash"
                
                -- Special handling for first player
                if first == effect.to then
                    for _, c in sgs.list(first:getHandcards()) do
                        if c:isKindOf("Slash") and not first:isCardLimited(c, sgs.Card_MethodResponse, true) then
                            slash = "Slash!"
                            break
                        end
                    end
                    
                    if slash ~= "Slash!" then
                        room:showAllCards(first)
                    end
                end
                
                slash = room:askForCard(
                    first,
                    slash,
                    "duel-slash:" .. second:objectName(),
                    data,
                    sgs.Card_MethodResponse,
                    second,
                    false,
                    "duel",
                    false,
                    effect.card
                )
                
                if slash == nil then break end
                
                -- Swap players
                local temp = first
                first = second
                second = temp
            end
            
            -- Deal damage to loser
            local damage = sgs.DamageStruct(effect.card, second, first)
            damage.by_user = (second == effect.from)
            room:damage(damage)
        end
        
        -- STEP 5: Skip default game rule handling
        room:setTag("SkipGameRule", sgs.QVariant(event))
        
        return true  -- Custom resolution complete
    end,
}
```

**Key Points for Custom Resolution:**

**1. Event Selection:**
- Use `sgs.CardEffected` event
- This triggers when card effect is about to resolve
- Allows you to replace default resolution

**2. Nullification Check (effect.nullified):**
```lua
if effect.nullified then
    -- Log the nullification
    local log = sgs.LogMessage()
    log.type = "#CardNullified"
    log.from = effect.to
    log.card_str = effect.card:toString()
    room:sendLog(log)
    return true  -- Stop processing
end
```

**3. Cancellation Check (effect.offset_card):**
```lua
-- Check if not already set
if not effect.offset_card then
    effect.offset_card = room:isCanceled(effect)
end

if effect.offset_card then
    data:setValue(effect)
    
    -- Trigger CardOffset for skills to respond
    if not room:getThread():trigger(sgs.CardOffset, room, effect.from, data) then
        effect.to:setFlags("Global_NonSkillNullify")
        return true
    end
end
```

**4. CardOnEffect Trigger:**
```lua
-- Allow other skills to respond to the effect
room:getThread():trigger(sgs.CardOnEffect, room, effect.to, data)
```

**5. Skip Game Rule:**
```lua
-- Prevent default resolution from running
room:setTag("SkipGameRule", sgs.QVariant(event))
```

**Complete Flow Chart:**

```
CardEffected Event
       ↓
Check effect.nullified? → YES → Log nullification, RETURN TRUE
       ↓ NO
Check/Set effect.offset_card (room:isCanceled)
       ↓
effect.offset_card? → YES → Trigger CardOffset → Failed? → Set NonSkillNullify flag, RETURN TRUE
       ↓ NO                                      ↓ Success
Trigger CardOnEffect                           Continue
       ↓
Target alive?
       ↓
Custom resolution logic
       ↓
Set SkipGameRule tag
       ↓
RETURN TRUE
```

**Common Mistakes:**

```lua
-- ❌ WRONG - Not checking nullified
on_trigger = function(self, event, player, data, room)
    local effect = data:toCardEffect()
    -- Directly implementing effect without nullification check
    room:damage(...)  -- This ignores armor/nullification!
end

-- ❌ WRONG - Not checking offset_card
on_trigger = function(self, event, player, data, room)
    local effect = data:toCardEffect()
    if effect.nullified then return true end
    -- Missing offset check - card might be canceled!
    -- Custom logic...
end

-- ❌ WRONG - Not triggering CardOnEffect
on_trigger = function(self, event, player, data, room)
    local effect = data:toCardEffect()
    if effect.nullified then return true end
    -- Missing CardOnEffect trigger - other skills can't respond!
    -- Custom logic...
end

-- ❌ WRONG - Not setting SkipGameRule
on_trigger = function(self, event, player, data, room)
    local effect = data:toCardEffect()
    -- All checks done...
    -- Custom logic...
    return true  -- Missing SkipGameRule - default resolution runs too!
end

-- ✅ CORRECT - Complete pattern
on_trigger = function(self, event, player, data, room)
    local effect = data:toCardEffect()
    
    -- Check nullified
    if effect.nullified then
        -- Log and return
        return true
    end
    
    -- Check offset
    if not effect.offset_card then
        effect.offset_card = room:isCanceled(effect)
    end
    if effect.offset_card then
        data:setValue(effect)
        if not room:getThread():trigger(sgs.CardOffset, room, effect.from, data) then
            effect.to:setFlags("Global_NonSkillNullify")
            return true
        end
    end
    
    -- Trigger CardOnEffect
    room:getThread():trigger(sgs.CardOnEffect, room, effect.to, data)
    
    -- Custom logic
    if effect.to:isAlive() then
        -- ... your implementation
    end
    
    -- Skip default
    room:setTag("SkipGameRule", sgs.QVariant(event))
    return true
end
```

**When to Use Custom Resolution:**

- Completely different card effect logic
- Complex interaction patterns (like modified Duel)
- Skills that fundamentally change how a card works
- Custom card implementations

**When NOT to Use:**

- Simple modifications (use other triggers)
- Just adding damage (+1 damage → use ConfirmDamage)
- Just changing targets (use CardTargetFixed)
- Responding to effects (use CardEffected without custom logic)

---

**10. Extra Phase/Turn Handling**

**Phase Constant Update:**

```lua
-- ❌ OLD - Wrong constant
if player:getPhase() == sgs.Player_Extra then
    -- ...
end

-- ✅ NEW - Correct constant
if player:getPhase() == sgs.Player_PhaseExtra then
    -- ...
end
```

**Improved Extra Turn Pattern:**

Instead of duplicate checks everywhere:

```lua
-- ❌ OLD - Duplicate pattern repeated everywhere
p:removeTag("sfofl_feishengTarget")
if p and p:isAlive() then
    p:gainAnExtraTurn()
end
```

Create a helper function:

```lua
-- ✅ NEW - Centralized helper
local function giveExtraTurn(room, player, tag_to_remove)
    if tag_to_remove then
        player:removeTag(tag_to_remove)
    end
    
    if player and player:isAlive() then
        player:gainAnExtraTurn()
    end
end

-- Usage
giveExtraTurn(room, p, "sfofl_feishengTarget")
```

**Or inline with validation:**

```lua
-- Clean inline pattern
on_trigger = function(self, event, player, data, room)
    local target = room:findPlayerByObjectName(data:toString())
    
    -- Single consolidated check
    if target and target:isAlive() then
        target:removeTag("special_tag")
        target:gainAnExtraTurn()
    end
    
    return false
end,
```

**Best Practices:**
- Always check `player:isAlive()` before giving extra turn
- Remove relevant tags before granting turn
- Consider creating helper functions for repeated patterns
- Consolidate validation checks

---

**Handling Pile Cards (player:getPile()) - CRITICAL**

When your TriggerSkill controls or removes cards from player piles:

**Common Mistake:** Not using proper card move reason when removing pile cards.

**Correct Pattern for Pile Card Removal in TriggerSkill:**

```lua
skill_name = sgs.CreateTriggerSkill {
    name = "skill_name",
    events = {sgs.EventPhaseProceeding},  -- Note: Changed from EventPhaseStart
    
    on_trigger = function(self, event, player, data, room)
        if player:getPhase() ~= sgs.Player_Play then return false end
        
        local pile_name = "example_pile"
        local pile = player:getPile(pile_name)
        
        if pile:isEmpty() then return false end
        
        -- Get card from pile
        local card_id = pile:first()
        
        -- CORRECT: Use proper CardMoveReason for pile removal
        local skillName = self:objectName()
        local reason = sgs.CardMoveReason(
            sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,
            player:objectName(),
            nil,
            skillName,
            ""
        )
        
        -- Throw card with proper reason
        room:throwCard(card_id, reason, nil)
        
        return false
    end,
}
```

**Key Points for TriggerSkill with Piles:**
- ❌ **WRONG**: Direct card removal without proper reason
- ✅ **CORRECT**: Use `CardMoveReason_S_REASON_REMOVE_FROM_PILE` when removing from piles
- Use `player:getPile(pile_name)` to access pile cards
- Create proper `CardMoveReason` with skill name
- Call `room:throwCard()` with the reason
- This applies to ANY manipulation of `player:getPile()` cards

**Example - Moving Pile Card to Hand:**

```lua
-- Moving from pile to hand
local pile = player:getPile("my_pile")
if not pile:isEmpty() then
    local card_id = pile:first()
    local reason = sgs.CardMoveReason(
        sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,
        player:objectName(),
        nil,
        self:objectName(),
        ""
    )
    room:obtainCard(player, card_id, reason, false)
end
```

**Example - Discarding All Pile Cards:**

```lua
-- Clear entire pile
local pile = player:getPile("my_pile")
if not pile:isEmpty() then
    local reason = sgs.CardMoveReason(
        sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,
        player:objectName(),
        nil,
        self:objectName(),
        ""
    )
    
    local dummy = sgs.DummyCard()
    for _, card_id in sgs.qlist(pile) do
        dummy:addSubcard(card_id)
    end
    room:throwCard(dummy, reason, nil)
    dummy:deleteLater()
end
```

---

### CreateViewAsSkill

**Card Transformation Skill**

**Typical Structure:**
```lua
skill_name = sgs.CreateViewAsSkill {
    name = "skill_name",
    n = 0, -- number of cards required (0 = any number)
    view_filter = function(self, selected, to_select)
        -- filter which cards can be selected
    end,
    view_as = function(self, cards)
        -- return the converted card
    end,
    enabled_at_play = function(self, player)
        -- can use during play phase
    end,
    enabled_at_response = function(self, player, pattern)
        -- can use when responding
    end,
}
```

#### Maintenance Requirements for CreateViewAsSkill (ZeroCard/OneCard variants)

**1. enabled_at_response Implementation (Pattern Loop Check)**

For skills that need to check multiple patterns (with `+` separator):

```lua
enabled_at_response = function(self, player, pattern)
    for _, p in sgs.list(pattern:split("+")) do
        local c = dummyCard(p)
        if c and c:isNDTrick() and player:getMark("ov_jichou_"..p) < 1
        then return true end
    end
end,
```

**Key Points:**
- Use `pattern:split("+")` to handle multiple patterns
- Loop through each pattern component
- Use `dummyCard(p)` to create test card
- Check specific conditions for each pattern
- Return true if any pattern matches conditions

**2. enabled_at_play for Guhuo-Type Skills**

For skills with `guhuo_type` or `setGuhuoType`:

```lua
enabled_at_play = function(self, player)
    for _, patt in ipairs(patterns()) do
        local dc = dummyCard(patt)
        if dc and (dc:isKindOf("Slash") or dc:isKindOf("Analeptic")) then
            dc:setSkillName(self:objectName())
            if dc:isAvailable(player)
            then return true end
        end
    end
end,
```

**Key Points:**
- Iterate through all patterns from `patterns()` function
- Create dummy card for each pattern
- Check if card is Slash or Analeptic (or other required types)
- Set skill name to the dummy card
- Verify card availability with `dc:isAvailable(player)`
- Return true if any pattern is available

**3. AI Considerations**

When implementing AI for ViewAsSkill variants:

```lua
-- In AI card selection logic
-- Consider extra handcards when using or responding
self:addHandPile("he")  -- Adds equipment cards to available card pool
```

**Important AI Notes:**
- Use `self:addHandPile("he")` to include both hand and equipment cards
- This allows AI to consider extra cards for skill usage
- Essential for skills that can convert equipment cards
- Improves AI decision-making for card responses

**Example Complete Implementation:**

```lua
example_viewas = sgs.CreateViewAsSkill {
    name = "example_viewas",
    n = 1,
    
    view_filter = function(self, selected, to_select)
        return #selected == 0
    end,
    
    view_as = function(self, cards)
        if #cards ~= 1 then return nil end
        local card = sgs.Sanguosha:cloneCard("amazing_grace")
        card:addSubcard(cards[1])
        card:setSkillName(self:objectName())
        return card
    end,
    
    enabled_at_play = function(self, player)
        for _, patt in ipairs(patterns()) do
            local dc = dummyCard(patt)
            if dc and (dc:isKindOf("Slash") or dc:isKindOf("Analeptic")) then
                dc:setSkillName(self:objectName())
                if dc:isAvailable(player)
                then return true end
            end
        end
    end,
    
    enabled_at_response = function(self, player, pattern)
        for _, p in sgs.list(pattern:split("+")) do
            local c = dummyCard(p)
            if c and c:isNDTrick() and player:getMark("ov_jichou_"..p) < 1
            then return true end
        end
    end,
}

-- Corresponding AI implementation
sgs.ai_skill_use["@@example_viewas"] = function(self, prompt)
    self:addHandPile("he")  -- Consider equipment cards
    -- ... rest of AI logic
end
```

---

### CreateSkillCard

**Custom Skill Card for ViewAsSkill**

ViewAsSkill often converts cards into custom SkillCards. Understanding on_use vs on_effect is critical.

**Typical Structure:**
```lua
SkillCardName = sgs.CreateSkillCard {
    name = "SkillCardName",
    target_fixed = false,
    will_throw = true,
    handling_method = sgs.Card_MethodDiscard,
    
    filter = function(self, targets, to_select)
        -- target selection filter
        return #targets == 0
    end,
    
    feasible = function(self, targets)
        -- check if targets are valid
        return #targets == 1
    end,
    
    on_use = function(self, room, source, targets)
        -- Code that runs ONCE when card is used
        -- General effects, animations, and card effect triggering
        
        -- IMPORTANT: Use cardEffect loop to handle each target
        for _, target in ipairs(targets) do
            room:cardEffect(self, source, target)
        end
    end,
    
    on_effect = function(self, effect)
        -- Code that runs for EACH target
        -- Specific effects on individual targets
        local room = effect.to:getRoom()
        local source = effect.from
        local target = effect.to
        
        -- Individual target effects here
    end,
}
```

#### Maintenance Requirements for CreateSkillCard

**1. Understanding on_use vs on_effect**

| Aspect | on_use | on_effect |
|--------|--------|-----------|
| **Execution** | Runs ONCE when card is used | Runs for EACH target |
| **Parameters** | `(self, room, source, targets)` | `(self, effect)` |
| **Purpose** | General setup, animations, global effects | Individual target effects |
| **Nullification** | Cannot be nullified | Can be nullified by skills/armor |
| **When to Use** | Card-wide effects, logging, cost payment | Damage, card operations on each target |

**2. Handling Pile Cards (extend_pile) - CRITICAL**

**Common Mistake:** Using `will_throw = true` with pile cards causes errors.

**Correct Pattern for Pile Cards:**

When converting cards from player piles (extend_pile):

```lua
SkillCardWithPile = sgs.CreateSkillCard {
    name = "SkillCardWithPile",
    target_fixed = false,
    will_throw = false,  -- IMPORTANT: Set to false for pile cards!
    handling_method = sgs.Card_MethodNone,  -- Or appropriate method
    
    on_use = function(self, room, source, targets)
        -- CORRECT: Manual card removal with proper reason
        local skillName = self:getSkillName()
        local reason = sgs.CardMoveReason(
            sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,
            "",
            nil,
            skillName,
            ""
        )
        room:throwCard(self, reason, nil)
        
        -- Then trigger effects
        for _, target in ipairs(targets) do
            room:cardEffect(self, source, target)
        end
    end,
    
    on_effect = function(self, effect)
        -- Individual target effects
    end,
}
```

**Key Points for Pile Cards:**
- ❌ **WRONG**: `will_throw = true` - causes automatic throwing that doesn't work with piles
- ✅ **CORRECT**: `will_throw = false` + manual `room:throwCard()` with proper reason
- Use `CardMoveReason_S_REASON_REMOVE_FROM_PILE` for pile card removal
- Call `room:throwCard()` in `on_use` before `cardEffect()` loop
- This applies to ANY card from `player:getPile(pile_name)`

**3. Proper Separation Pattern**

```lua
on_use = function(self, room, source, targets)
    -- Part 1: Effects that happen ONCE (cannot be nullified)
    -- - Pay costs (discard cards, lose HP, etc.)
    -- - Global announcements/broadcasts
    -- - One-time stat modifications
    -- - Room-wide effects
    
    room:broadcastSkillInvoke(self:getSkillName())
    room:doAnimate(...)
    
    -- Part 2: Trigger card effect for each target
    -- This allows proper nullification handling
    for _, target in ipairs(targets) do
        room:cardEffect(self, source, target)
    end
end,

on_effect = function(self, effect)
    -- Part 3: Effects for EACH target (can be nullified)
    -- - Damage to target
    -- - Drawing/discarding target's cards
    -- - Target-specific modifications
    
    local room = effect.to:getRoom()
    local source = effect.from
    local target = effect.to
    
    -- Effects that can be nullified by armor/skills
    room:damage(sgs.DamageStruct(self, source, target, 1))
end,
```

**4. Why Separate on_use and on_effect?**

**Nullification Support:**
- Skills like "Wuzhong" (无中) or armor effects can nullify card effects
- Nullification happens at the `cardEffect` level
- If all code is in `on_use`, nullification cannot work properly
- Separating allows each target to be handled independently

**Example - Incorrect (No Nullification Support):**
```lua
-- BAD: Everything in on_use
on_use = function(self, room, source, targets)
    for _, target in ipairs(targets) do
        -- This CANNOT be nullified!
        room:damage(sgs.DamageStruct(self, source, target, 1))
    end
end,
```

**Example - Correct (With Nullification Support):**
```lua
-- GOOD: Proper separation
on_use = function(self, room, source, targets)
    room:broadcastSkillInvoke(self:getSkillName())
    
    -- Trigger effect for each target (allows nullification)
    for _, target in ipairs(targets) do
        room:cardEffect(self, source, target)
    end
end,

on_effect = function(self, effect)
    local room = effect.to:getRoom()
    local source = effect.from
    local target = effect.to
    
    -- This CAN be nullified by skills/armor
    room:damage(sgs.DamageStruct(self, source, target, 1))
end,
```

**5. Complete Implementation Example**

```lua
-- Skill Card Definition
ExampleSkillCard = sgs.CreateSkillCard {
    name = "ExampleSkillCard",
    target_fixed = false,
    will_throw = true,
    
    filter = function(self, targets, to_select)
        return #targets == 0 and to_select:objectName() ~= sgs.Self:objectName()
    end,
    
    on_use = function(self, room, source, targets)
        -- Step 1: Pay costs (ONCE, cannot be nullified)
        room:loseHp(source, 1)
        
        -- Step 2: Broadcast skill animation (ONCE)
        room:broadcastSkillInvoke("example_skill")
        
        -- Step 3: Trigger effect for each target (allows nullification)
        for _, target in ipairs(targets) do
            room:cardEffect(self, source, target)
        end
    end,
    
    on_effect = function(self, effect)
        -- Step 4: Apply effect to each target (can be nullified)
        local room = effect.to:getRoom()
        local source = effect.from
        local target = effect.to
        
        -- This can be prevented by armor or skills
        room:damage(sgs.DamageStruct(self, source, target, 2, sgs.DamageStruct_Normal))
        
        -- Additional per-target effects
        if not target:isKongcheng() then
            room:askForDiscard(target, "example_skill", 1, 1, false, true)
        end
    end,
}

-- ViewAsSkill that uses this SkillCard
example_skill = sgs.CreateViewAsSkill {
    name = "example_skill",
    n = 1,
    
    view_as = function(self, cards)
        if #cards ~= 1 then return nil end
        local card = ExampleSkillCard:clone()
        card:addSubcard(cards[1])
        card:setSkillName(self:objectName())
        return card
    end,
    
    enabled_at_play = function(self, player)
        return not player:hasUsed("ExampleSkillCard")
    end,
}
```

**6. Maintenance Checklist for SkillCard**

- [ ] **on_use**: Contains only global/once-per-use effects
- [ ] **on_use**: Includes `room:cardEffect()` loop for targets
- [ ] **on_effect**: Contains all target-specific effects
- [ ] **on_effect**: Effects that should be nullifiable are here
- [ ] Cost payment (HP loss, card discard) is in `on_use`
- [ ] Damage dealing is in `on_effect`
- [ ] Target card operations are in `on_effect`
- [ ] Test nullification with armor/skills
- [ ] **Pile cards**: Use `will_throw = false` + manual `room:throwCard()` with `CardMoveReason_S_REASON_REMOVE_FROM_PILE`

---

### CreateTargetModSkill

**Target Modification Skill**

**Typical Structure:**
```lua
skill_name = sgs.CreateTargetModSkill {
    name = "skill_name",
    pattern = "Slash", -- card pattern affected
    residue_func = function(self, from)
        -- extra uses (for Slash, etc.)
    end,
    distance_limit_func = function(self, from)
        -- modify distance limit
    end,
    extra_target_func = function(self, from)
        -- add extra targets
    end,
}
```

---

### CreateFilterSkill

**Card Property Modification**

**Typical Structure:**
```lua
skill_name = sgs.CreateFilterSkill {
    name = "skill_name",
    view_filter = function(self, to_select)
        -- which cards to filter
    end,
    view_as = function(self, card)
        -- return modified card
    end,
}
```

---

### CreateDistanceSkill

**Distance Calculation Modification**

**Typical Structure:**
```lua
skill_name = sgs.CreateDistanceSkill {
    name = "skill_name",
    correct_func = function(self, from, to)
        -- return distance modification value
        -- positive = increase distance
        -- negative = decrease distance
    end,
}
```

---

### CreateProhibitSkill

**Action Prohibition**

**Typical Structure:**
```lua
skill_name = sgs.CreateProhibitSkill {
    name = "skill_name",
    is_prohibited = function(self, from, to, card)
        -- return true to prohibit
    end,
}
```

---

### CreateMaxCardsSkill

**Hand Limit Modification**

**Typical Structure:**
```lua
skill_name = sgs.CreateMaxCardsSkill {
    name = "skill_name",
    extra_func = function(self, target)
        -- return extra hand card limit
    end,
    fixed_func = function(self, target)
        -- return fixed hand card limit (overrides calculation)
    end,
}
```

---

### CreateAttackRangeSkill

**Attack Range Modification**

**Typical Structure:**
```lua
skill_name = sgs.CreateAttackRangeSkill {
    name = "skill_name",
    extra_func = function(self, target)
        -- return extra attack range
    end,
    fixed_func = function(self, target)
        -- return fixed attack range
    end,
}
```

---

## Examples from Codebase

### Example 1: CreateTriggerSkill
```lua
-- From sijyuoffline.lua line 3142
sfofl_zhonghun = sgs.CreateTriggerSkill {
    -- Triggers when using/playing red cards
}
```

### Example 2: CreateViewAsSkill
```lua
-- From sijyuoffline.lua line 3271
sfofl_longyiVS = sgs.CreateViewAsSkill {
    -- Convert cards to basic cards
}
```

### Example 3: CreateTargetModSkill
```lua
-- From sijyuoffline.lua line 4128
sfofl_sheji_Target = sgs.CreateTargetModSkill {
    -- Modify targeting for specific cards
}
```

### Example 4: CreateDistanceSkill
```lua
-- From sijyuoffline.lua line 10296
sfofl_whitehorse_distance = sgs.CreateDistanceSkill {
    -- Horse equipment distance modification
}
```

### Example 5: CreateFilterSkill
```lua
-- From sijyuoffline.lua line 9892
sfofl_shuangrenFilter = sgs.CreateFilterSkill {
    -- Modify card properties
}
```

## Notes for Maintenance

- **Most Common**: CreateTriggerSkill (90%+ of skills)
- **Card Conversion**: CreateViewAsSkill and CreateOneCardViewAsSkill
- **Targeting**: CreateTargetModSkill for distance/target modifications
- **Passive Effects**: CreateFilterSkill, CreateDistanceSkill, CreateMaxCardsSkill
- **Restrictions**: CreateProhibitSkill and CreateInvaliditySkill

### Critical Maintenance Points for TriggerSkill

**Phase Events - CRITICAL CHANGES:**
- **EventPhaseStart → EventPhaseProceeding**: Most skills should use EventPhaseProceeding
- **Player_Extra → Player_PhaseExtra**: Update phase constant
- **DamageCaused → ConfirmDamage**: For damage increase/modification

**Skill Invocation:**
- Call `notifySkillInvoked`/`broadcastSkillInvoke` after validation, before effects
- Proper timing prevents unnecessary animations

**Dynamic Descriptions:**
- Use `SkillDescriptionRecord_[skillname]` property pattern
- Call `setSkillDescriptionSwap` before `changeTranslation`
- Update descriptions when accumulated data changes

**Extra Turns:**
- Always check `player:isAlive()` before `gainAnExtraTurn()`
- Remove relevant tags before granting turn
- Consider helper functions to reduce duplication

**Skill Loss Cleanup:**
- On EventLoseSkill: Clear piles, marks, tags, and description records
- Prevent memory leaks and state corruption
- Use proper CardMoveReason for pile removal

**Judge Cards:**
- Set `judge.throw_card = false` to keep judge cards
- Essential for Guicai-type skills that obtain judge cards
- Prevents automatic discard

**Shiming Skills:**
- Use double underscore mark naming: `skillname__success`, `skillname__fail`
- Clear state tracking for reveal/show mechanics
- Enables AI evaluation and follow-up effects

**Double Resolution:**
- Always check `target:isAlive()` before second resolution
- Build new SPlayerList with only alive targets
- Set UseHistory tag to prevent infinite loops
- Create new CardUseStruct for second use

**Custom Card Resolution:**
- Use `CardEffected` event for custom resolution
- Check `effect.nullified` first (nullification by skills/armor)
- Check/set `effect.offset_card` with `room:isCanceled()` (cancellation)
- Trigger `CardOnEffect` to allow other skills to respond
- Set `SkipGameRule` tag to prevent default resolution
- Complete 5-step pattern: nullified → offset → CardOnEffect → custom logic → SkipGameRule

**System Mark**
- End with "-Keep"

### Critical Maintenance Points for ViewAsSkill Family

**Pattern Handling:**
- Always use `pattern:split("+")` in `enabled_at_response` for multiple patterns
- Loop through each pattern component with `for _, p in sgs.list(pattern:split("+"))`
- Use `dummyCard(p)` to validate each pattern

**Guhuo-Type Skills:**
- Use `patterns()` function to get all available patterns
- Check `dc:isAvailable(player)` for each pattern
- Set skill name with `dc:setSkillName(self:objectName())`

**AI Implementation:**
- **ALWAYS** use `self:addHandPile("he")` to include equipment cards
- This is critical for proper AI card selection
- Affects both usage and response scenarios

### Critical Maintenance Points for SkillCard

**on_use vs on_effect Separation:**
- **on_use**: Runs ONCE per card usage - put costs, animations, global effects here
- **on_effect**: Runs for EACH target - put nullifiable effects here
- **ALWAYS** use `room:cardEffect()` loop in `on_use` to trigger `on_effect`

**Nullification Support:**
- Separating on_use and on_effect enables proper nullification
- Armor effects (Eight Diagrams) and skills (Wuzhong) work at `cardEffect` level
- Effects in `on_use` only: Cannot be nullified
- Effects in `on_effect`: Can be nullified per target

**Common Mistakes:**
- ❌ Putting damage in `on_use` - prevents nullification
- ❌ Forgetting `room:cardEffect()` loop - breaks targeting
- ❌ Putting cost payment in `on_effect` - costs applied per target
- ❌ Using `will_throw = true` with pile cards - causes errors
- ✅ Costs in `on_use`, effects in `on_effect`
- ✅ Pile cards: `will_throw = false` + manual `room:throwCard()` with proper reason

### Critical Maintenance Points for Pile Cards (extend_pile)

**Applies to BOTH SkillCard and TriggerSkill:**

**The Problem:**
- Pile cards (from `player:getPile()`) require special handling
- Using standard card throwing mechanisms causes errors
- Automatic throwing (`will_throw = true`) doesn't work with piles

**The Solution:**
```lua
-- Create proper CardMoveReason
local reason = sgs.CardMoveReason(
    sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE,
    player:objectName(),  -- or "" if not applicable
    nil,
    skillName,
    ""
)
room:throwCard(card_or_id, reason, nil)
```

**When This Applies:**
- ✅ SkillCard using pile cards: Set `will_throw = false`, manually throw in `on_use`
- ✅ TriggerSkill manipulating piles: Always use `REMOVE_FROM_PILE` reason
- ✅ Any operation removing cards from `player:getPile(pile_name)`
- ✅ Moving pile cards to hand, discard, or removal

**Quick Reference:**
| Situation | will_throw | Handling |
|-----------|------------|----------|
| Normal hand cards | `true` | Automatic |
| Pile cards in SkillCard | `false` | Manual with `REMOVE_FROM_PILE` |
| Pile cards in TriggerSkill | N/A | Manual with `REMOVE_FROM_PILE` |

## File Locations

Primary skill implementations found in:
- `extensions/sijyuoffline.lua` - Main offline extensions
- `extensions/kearnews.lua` - News package skills
- `extensions/scarlet.lua` - Scarlet series skills
- `extensions/extra.lua` - Extra skills
- `extensions/newgenerals.lua` - New generals skills
- Other files in `extensions/` directory

---

## Quick Reference Checklist

### When Creating/Maintaining SkillCard:

- [ ] **on_use**: Global effects only (costs, animations, broadcasts)
- [ ] **on_use**: Include `room:cardEffect()` loop for all targets
- [ ] **on_effect**: All target-specific effects here
- [ ] **on_effect**: Nullifiable effects (damage, card ops) here
- [ ] Test nullification with armor/skills (e.g., Eight Diagrams, Wuzhong)
- [ ] Verify each target is handled independently
- [ ] Cost payment in `on_use`, effects in `on_effect`
- [ ] **Pile cards**: Use `will_throw = false` + manual `room:throwCard()` with `CardMoveReason_S_REASON_REMOVE_FROM_PILE`

### When Creating/Maintaining ViewAsSkill:

- [ ] `enabled_at_response`: Use `pattern:split("+")` loop
- [ ] `enabled_at_play` (Guhuo): Use `patterns()` iteration with `isAvailable()` check
- [ ] AI implementation: Include `self:addHandPile("he")`
- [ ] Test with multiple pattern combinations
- [ ] Verify equipment card consideration in AI
- [ ] If using SkillCard: Follow SkillCard checklist above
- [ ] **Pile cards**: Ensure SkillCard uses proper pile handling

### When Creating/Maintaining TriggerSkill:

- [ ] Define appropriate events
- [ ] **CRITICAL**: Use `EventPhaseProceeding` instead of `EventPhaseStart` for most skills
- [ ] Implement `can_trigger` for conditions
- [ ] Implement `on_trigger` for effects
- [ ] Call `notifySkillInvoked`/`broadcastSkillInvoke` after validation, before effects
- [ ] Consider timing priority
- [ ] Add corresponding AI logic
- [ ] **Pile cards**: Use `CardMoveReason_S_REASON_REMOVE_FROM_PILE` when manipulating `player:getPile()`
- [ ] **Phase constant**: Use `Player_PhaseExtra` not `Player_Extra`
- [ ] **Damage +1**: Use `ConfirmDamage` instead of `DamageCaused`
- [ ] **Dynamic descriptions**: Use `setSkillDescriptionSwap` + `changeTranslation` for variable text
- [ ] **Extra turns**: Check `isAlive()` and remove tags before `gainAnExtraTurn()`
- [ ] **Skill loss**: Clean up piles, marks, and description records on EventLoseSkill
- [ ] **Judge cards**: Set `judge.throw_card = false` when obtaining judge cards
- [ ] **Shiming skills**: Use `skillname__success` and `skillname__fail` marks
- [ ] **Double resolution**: Check `target:isAlive()` and build new target list for second resolution
- [ ] **Custom resolution**: Check `effect.nullified`, `room:isCanceled()`, trigger `CardOnEffect`, set `SkipGameRule`

### When Creating/Maintaining TargetModSkill:

- [ ] Define card pattern affected
- [ ] Implement residue_func for extra uses
- [ ] Implement distance_limit_func if needed
- [ ] Implement extra_target_func if needed
- [ ] Test with various card types

---

## AI Implementation Guidelines

### Smart-AI New Functions and Patterns

#### 1. Cost Nullification Decision Function

**Function:** `shouldInvokeCostNullifySkill(use, need_discard, need_losehp, discard_num, target)`

**Purpose:** Determines whether AI should invoke skills that nullify card effects at a cost.

**Usage:**
```lua
-- In AI skill invocation code
local should_invoke = self:shouldInvokeCostNullifySkill(
    use,           -- CardUseStruct
    need_discard,  -- boolean: requires discarding cards
    need_losehp,   -- boolean: requires losing HP
    discard_num,   -- number: how many cards to discard
    target         -- ServerPlayer: the target being affected
)

if should_invoke then
    -- Invoke the nullification skill
end
```

**Parameters:**
- `use`: The CardUseStruct being nullified
- `need_discard`: Whether the skill requires discarding cards
- `need_losehp`: Whether the skill requires losing HP
- `discard_num`: Number of cards that need to be discarded
- `target`: The player being targeted/affected

**Example:**
```lua
-- Wuzhong-type skill AI
sgs.ai_skill_invoke["wuzhong_skill"] = function(self, data)
    local use = data:toCardUse()
    local target = self.player
    
    -- Use smart decision function
    return self:shouldInvokeCostNullifySkill(use, true, false, 1, target)
end
```

---

#### 2. Finding Slash Targets

**Function:** `findPlayerToUseSlash(distance_limit, players, reason, slash, extra_targets, fixed_target)`

**Purpose:** Smart AI function to find optimal targets for Slash cards.

**Usage:**
```lua
local target = self:findPlayerToUseSlash(
    distance_limit,  -- number or nil: distance restriction
    players,         -- table or nil: candidate players
    reason,          -- string: reason for slashing
    slash,           -- Card: the slash being used
    extra_targets,   -- number: additional targets allowed
    fixed_target     -- ServerPlayer or nil: must-target player
)
```

**Parameters:**
- `distance_limit`: Maximum distance for targets (nil = no limit)
- `players`: Table of candidate players (nil = all valid targets)
- `reason`: String describing why this slash is being used
- `slash`: The actual Slash card object
- `extra_targets`: Number of extra targets the slash can hit (0 = single target)
- `fixed_target`: If specified, must include this player

**Example:**
```lua
-- Finding target for a skill that uses Slash
sgs.ai_skill_use["@@example_slash_skill"] = function(self, prompt)
    local slash = sgs.Sanguosha:cloneCard("slash")
    slash:setSkillName("example_slash_skill")
    
    -- Find best target within distance 1
    local target = self:findPlayerToUseSlash(1, nil, "offense", slash, 0, nil)
    
    if target then
        return "@ExampleSlashCard=.->" .. target:objectName()
    end
    return "."
end
```

---

#### 3. Finding Damage Targets

**Function:** `findPlayerToDamage(damage, player, nature, targets, base_value, card)`

**Purpose:** Find optimal target for dealing damage.

**Usage:**
```lua
local best_target = self:findPlayerToDamage(
    damage,      -- number: damage amount
    player,      -- ServerPlayer: source of damage (usually self.player)
    nature,      -- DamageNature: Fire/Thunder/Normal
    targets,     -- table: candidate targets
    base_value,  -- number: base evaluation value
    card         -- Card: the card dealing damage (or nil)
)
```

**Parameters:**
- `damage`: Amount of damage to be dealt
- `player`: The player dealing the damage (damage source)
- `nature`: Damage nature (sgs.DamageStruct_Fire, _Thunder, or _Normal)
- `targets`: Table of candidate target players
- `base_value`: Base value for evaluation (affects priority)
- `card`: The card being used (if any)

**Example:**
```lua
-- Skill that deals damage to chosen target
sgs.ai_skill_use["@@damage_skill"] = function(self, prompt)
    local targets = {}
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        if not p:isNude() then
            table.insert(targets, p)
        end
    end
    
    local target = self:findPlayerToDamage(
        2,                           -- 2 damage
        self.player,                 -- damage source
        sgs.DamageStruct_Fire,      -- fire damage
        targets,                     -- candidates
        0,                          -- base value
        nil                         -- no specific card
    )
    
    if target then
        return "@DamageCard=.->" .. target:objectName()
    end
    return "."
end
```

---

### AI Defense and Status Tables

#### 4. Defense Skill Registration

**Table:** `sgs.ai_skill_defense.skillName`

**Purpose:** Register skills that provide defensive capabilities for AI evaluation.

**Usage:**
```lua
-- Register a defensive skill
sgs.ai_skill_defense.example_defense = function(self, player)
    -- Return true if the skill is active/available
    return player:hasSkill("example_defense") and not player:isKongcheng()
end
```

**Example:**
```lua
-- Wuzhong-type defense
sgs.ai_skill_defense.wuzhong = function(self, player)
    if not player:hasSkill("wuzhong") then return false end
    if player:isNude() then return false end
    return true
end

-- Eight Diagrams defense
sgs.ai_skill_defense.eight_diagrams = function(self, player)
    local armor = player:getArmor()
    return armor and armor:isKindOf("EightDiagram")
end
```

---

#### 5. Suppress Intention (Force Card Use)

**Table:** `sgs.ai_suppress_intention`

**Purpose:** Force AI to use certain cards regardless of normal evaluation (user control override).

**Usage:**
```lua
-- Force AI to prioritize using this card
sgs.ai_suppress_intention["skillName"] = true
```

**When to Use:**
- Skills that must be used at specific times
- Override normal AI caution
- Testing or debugging purposes

**Example:**
```lua
-- Force AI to use this skill aggressively
sgs.ai_suppress_intention["aggressive_skill"] = true
```

---

#### 6. Least Handcard Number Skills

**Table:** `sgs.ai_getLeastHandcardNum_skill`

**Purpose:** Define skills that allow players to maintain fewer hand cards (affects AI evaluation).

**Usage:**
```lua
sgs.ai_getLeastHandcardNum_skill["skillName"] = function(self, player)
    -- Return the minimum safe handcard count for this player
    return 0  -- Can safely have 0 cards
end
```

**Example:**
```lua
-- Kongcheng (Empty City) skill - safe with 0 cards
sgs.ai_getLeastHandcardNum_skill["kongcheng"] = function(self, player)
    return 0
end

-- Shoucheng (Defend City) - safe with 1 card
sgs.ai_getLeastHandcardNum_skill["shoucheng"] = function(self, player)
    return 1
end
```

---

#### 7. Best HP Skills

**Table:** `ai_getBestHp_skill`

**Purpose:** Define optimal HP levels for skills that benefit from specific HP amounts.

**Usage:**
```lua
ai_getBestHp_skill["skillName"] = function(self, player)
    -- Return the optimal HP value for this player
    return 1  -- Best at 1 HP
end
```

**Example:**
```lua
-- Wuhun (Vengeful Spirit) - stronger at low HP
ai_getBestHp_skill["wuhun"] = function(self, player)
    return 1  -- Most dangerous at 1 HP
end

-- Nostalgia Xiangle - optimal at half HP
ai_getBestHp_skill["nosxiangle"] = function(self, player)
    return math.ceil(player:getMaxHp() / 2)
end
```

---

#### 8. Buqu Effect Detection

**Table:** `ai_hasBuquEffect_skill`

**Purpose:** Identify skills that provide Buqu-like effects (preventing death at 0 HP).

**Usage:**
```lua
ai_hasBuquEffect_skill["skillName"] = true
```

**Example:**
```lua
-- Original Buqu
ai_hasBuquEffect_skill["buqu"] = true

-- Niepan (Nirvana) - resurrection effect
ai_hasBuquEffect_skill["niepan"] = true

-- Custom resurrection skills
ai_hasBuquEffect_skill["custom_resurrection"] = true
```

---

#### 9. Niepan (Nirvana) Detection

**Table:** `ai_canNiepan_skill`

**Purpose:** Check if player can activate Niepan-type resurrection skills.

**Usage:**
```lua
ai_canNiepan_skill["skillName"] = function(self, player)
    -- Return true if the skill can be activated now
    return player:getMark("@nirvana") > 0
end
```

**Example:**
```lua
ai_canNiepan_skill["niepan"] = function(self, player)
    return player:getMark("@nirvana") > 0 and player:isDying()
end

ai_canNiepan_skill["fenghuang"] = function(self, player)
    return player:getMark("@phoenix") > 0 and not player:hasFlag("fenghuang_used")
end
```

---

#### 10. Tuntian Effect Detection

**Table:** `ai_hasTuntianEffect_skill`

**Purpose:** Identify skills that benefit from missed draw (like Tuntian).

**Usage:**
```lua
ai_hasTuntianEffect_skill["skillName"] = true
```

**Example:**
```lua
-- Original Tuntian (Field Cultivation)
ai_hasTuntianEffect_skill["tuntian"] = true

-- Similar skills that benefit from not drawing
ai_hasTuntianEffect_skill["custom_tuntian"] = true
```

---

### Common AI Pattern Changes

#### 11. Skill Name Detection - CRITICAL CHANGE

**Old Pattern (DEPRECATED):**
```lua
-- ❌ OLD - Single skill name check
if card:getSkillName() == "skillName" then
    -- do something
end
```

**New Pattern (REQUIRED):**
```lua
-- ✅ NEW - Multiple skill names support
if table.contains(card:getSkillNames(), "skillName") then
    -- do something
end
```

**Why This Matters:**
- Cards can now have multiple skill names
- `getSkillName()` returns only the first skill
- `getSkillNames()` returns a table of all skill names
- Using `table.contains()` ensures all skills are checked

**Migration Examples:**

```lua
-- Example 1: Card filter
-- OLD
if use.card:getSkillName() == "zhiheng" then
    return false
end

-- NEW
if table.contains(use.card:getSkillNames(), "zhiheng") then
    return false
end

-- Example 2: Skill effect check
-- OLD
for _, card in sgs.qlist(self:getCards("h")) do
    if card:getSkillName() == "longdan" then
        slash_count = slash_count + 1
    end
end

-- NEW
for _, card in sgs.qlist(self:getCards("h")) do
    if table.contains(card:getSkillNames(), "longdan") then
        slash_count = slash_count + 1
    end
end

-- Example 3: ViewAs skill checking
-- OLD
local is_zhiheng = (card:getSkillName() == "zhiheng" or 
                    card:getSkillName() == "nos_zhiheng")

-- NEW
local is_zhiheng = (table.contains(card:getSkillNames(), "zhiheng") or 
                    table.contains(card:getSkillNames(), "nos_zhiheng"))
```

#### 12. Function Reason
room:loseHp(target, 1, true, player, self:objectName())
room:loseMaxHp(source,1,self:getSkillName())

---

### AI Implementation Checklist

When implementing AI for skills:

- [ ] Use `shouldInvokeCostNullifySkill()` for nullification skills with costs
- [ ] Use `findPlayerToUseSlash()` for finding Slash targets
- [ ] Use `findPlayerToDamage()` for finding damage targets
- [ ] Register in `ai_skill_defense` if skill provides defense
- [ ] Set `ai_suppress_intention` if skill should be used aggressively
- [ ] Define `ai_getLeastHandcardNum_skill` if skill allows low hand cards
- [ ] Define `ai_getBestHp_skill` if skill has optimal HP
- [ ] Set `ai_hasBuquEffect_skill` if skill prevents death
- [ ] Define `ai_canNiepan_skill` if skill allows resurrection
- [ ] Set `ai_hasTuntianEffect_skill` if skill benefits from missed draw
- [ ] **CRITICAL**: Change all `card:getSkillName() == "name"` to `table.contains(card:getSkillNames(), "name")`

---

**Document Version**: 1.7  
**Last Updated**: December 10, 2025  
**Purpose**: Skill type reference for maintenance and development  
**Recent Updates**: 
- v1.1: Added ViewAsSkill maintenance requirements (enabled_at_response, enabled_at_play, AI considerations)
- v1.2: Added CreateSkillCard comprehensive guide (on_use vs on_effect, nullification support, separation patterns)
- v1.3: Added pile card (extend_pile) handling for both SkillCard and TriggerSkill with CardMoveReason_S_REASON_REMOVE_FROM_PILE
- v1.4: Added comprehensive Smart-AI guidelines (new functions, defense tables, skill name detection pattern change)
- v1.5: Added TriggerSkill common migrations (EventPhaseStart→EventPhaseProceeding, dynamic descriptions, extra turn patterns, damage event changes)
- v1.6: Added skill loss cleanup, judge card handling, shiming skill pattern, card double resolution with alive checks
- v1.7: Added custom card effect resolution pattern (CardEffected, nullification checking, offset handling, SkipGameRule)

---

## Waiting for Further Requirements

This document has been updated with custom card effect resolution (改結算方式) patterns, including:
- Complete 5-step custom resolution pattern (nullified → offset → CardOnEffect → custom logic → SkipGameRule)
- effect.nullified checking for armor/skill nullification
- effect.offset_card and room:isCanceled() for cancellation handling
- CardOnEffect trigger for other skills to respond
- SkipGameRule tag to prevent default resolution
- Complete flow chart and common mistake examples
- When to use vs when not to use custom resolution

Please provide any additional maintenance requirements or specifications you'd like to add.

