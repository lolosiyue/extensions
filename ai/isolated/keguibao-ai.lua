-- keguibao isolated AI。決策對齊 lua/ai/keguibao-ai.lua，只使用 isolated 基礎：
-- 單張／零成本主動技走權威轉化票與 ai_card_use；多張支付走 skill_action。
-- 關係、賣血、覺醒估值、傷害調整都呼叫 SmartAIView，不在這裡重寫。

local function known(value, key)
    if value == nil then ai_unsupported("required visible value is unknown", key) end
    return value
end

local function offered_names(options, key)
    if type(options) ~= "table" or options.candidates_complete ~= true
        or not AIValue.isList(options.players) then
        ai_unsupported(key .. " candidates are incomplete", key)
    end
    local names = {}
    for _, name in ipairs(options.players) do names[name] = true end
    return names
end

local function choice_of(options, wanted, key)
    for _, value in ipairs(options and options.choices or {}) do
        if value == wanted then return value end
    end
    ai_unsupported(key .. " choice was not offered", key)
end

local function enemy_names(self, names, limit, key)
    local picked = {}
    for _, name in ipairs(names) do
        if #picked >= limit then break end
        local player = known(self.room:findPlayerByObjectName(name, true), key)
        if known(self:isEnemy(player), key) then picked[#picked + 1] = name end
    end
    return picked
end

local function first_relation(self, names, want_enemy, key)
    for _, name in ipairs(names) do
        local player = known(self.room:findPlayerByObjectName(name, true), key)
        local enemy = known(self:isEnemy(player), key)
        if want_enemy == enemy then return name end
    end
    return nil
end

local function visible_slashes(self, player)
    local own = player:objectName() == self.player:objectName()
    local cards = own and player:getHandcards() or player:getKnownCards()
    if not cards then return nil end
    local count = 0
    for _, card in ipairs(cards) do
        if card:isKindOf("Slash") then count = count + 1 end
    end
    return count
end

local function same_visible_side(self, other)
    if other:isDead() ~= true then return false end
    local mine, theirs = self.player:getRole(), other:getRole()
    if type(mine) ~= "string" or mine == "" or type(theirs) ~= "string" or theirs == "" then
        return nil
    end
    if theirs == mine then return true end
    return theirs == "loyalist" and self.player:isLord() == true
end

local function dead_allies(self, key)
    local players = known(self.room:getAllPlayers(true), key)
    local found = false
    for _, player in ipairs(players) do
        local same = same_visible_side(self, player)
        if same == nil then ai_unsupported(key .. " dead role is unknown", key) end
        if same then found = true end
    end
    return found
end

local function single_target_names(card, key)
    if type(card.getTargetCombinations) ~= "function" then
        ai_unsupported(key .. " target rows are missing", key)
    end
    local allowed, page, cursor = {}, card:getTargetCombinations()
    if not page then ai_unsupported(key .. " target rows are incomplete", key) end
    repeat
        for _, row in ipairs(page) do
            if #row == 1 then allowed[row[1]] = true end
        end
        if cursor then page, cursor = card:getTargetCombinations(cursor) else break end
    until false
    return allowed
end

local function lowest_subcard(self, skill, score)
    local conversions = self:getConversions()
    if not conversions then return nil end
    local best_id, best_score
    for _, conversion in ipairs(conversions) do
        if conversion:getActivationSkillName() == skill then
            local payment = self:conversionSubcard(conversion)
            if payment then
                local value = score(payment)
                local id = payment:getEffectiveId()
                if type(value) == "number" and type(id) == "number"
                    and (best_score == nil or value < best_score
                        or (value == best_score and id < best_id)) then
                    best_id, best_score = id, value
                end
            end
        end
    end
    return best_id
end

local function fill_lord_gift(self, card, use, skill, lord_skill)
    if self:needBear() ~= false then return end
    local payment = self:conversionSubcard(card)
    if not payment or not payment:isKindOf("TrickCard")
        or payment:getEffectiveId() ~= lowest_subcard(self, skill, function(owned)
            if not owned:isKindOf("TrickCard") then return nil end
            return self:getUseValue(owned)
        end) then return end
    local friends = self.friends_noself
    if not friends then ai_unsupported(skill .. " friends are unknown", skill) end
    local pool = {}
    for _, friend in ipairs(friends) do
        if friend:hasLordSkill(lord_skill) == true
            and friend:hasFlag(lord_skill .. "Invoked") == false
            and self:hasManjuanEffect(friend) == false then
            pool[#pool + 1] = friend
        end
    end
    local ordered = self:sort(pool, "defense") or pool
    local allowed = single_target_names(card, skill)
    for _, friend in ipairs(ordered) do
        if allowed[friend:objectName()] then
            use.card = card
            use.to:append(friend)
            return
        end
    end
end

local function fill_draw_gift(self, card, use, skill, self_first)
    local payment = self:conversionSubcard(card)
    if not payment or payment:getEffectiveId() ~= lowest_subcard(self, skill, function(owned)
        return self:getKeepValue(owned)
    end) then return end
    local allowed = single_target_names(card, skill)
    local function give(target)
        if target and allowed[target:objectName()] then
            use.card = card
            use.to:append(target)
            return true
        end
        return false
    end
    if self_first() and give(self.player) then return end
    local friends = self.friends
    if not friends then ai_unsupported(skill .. " friends are unknown", skill) end
    for _, friend in ipairs(friends) do
        if self:hasSkills(sgs.cardneed_skill, friend) and self:canDraw(friend, self.player) == true
            and give(friend) then return end
    end
    local ordered = self:sort(friends, "defense") or friends
    for _, friend in ipairs(ordered) do
        if self:isWeak(friend) == true and self:canDraw(friend, self.player) == true
            and give(friend) then return end
    end
    for _, friend in ipairs(friends) do
        if give(friend) then return end
    end
end

local function distinct_suits(cards, limit)
    local seen, ids = {}, {}
    for _, card in ipairs(cards) do
        local suit = card:getSuit()
        if type(suit) == "number" and suit >= sgs.Card_Spade and suit <= sgs.Card_Diamond
            and not seen[suit] and #ids < limit then
            seen[suit] = true
            ids[#ids + 1] = card:getEffectiveId()
        end
    end
    return ids, seen
end

local function skill_use(self, skill, cards, targets)
    local action = self:getSkillAction(skill)
    if not action or not action:isValid() then
        ai_unsupported(skill .. " activation is missing", skill)
    end
    local answer = {kind = "use_card", skill_action = action:toAnswer(), cards = cards}
    if targets and #targets > 0 then answer.targets = targets end
    return answer
end

local function better_card_planned(self, priority, value)
    local uses = self:getTurnUse(true)
    if not uses then return false end
    for _, use in ipairs(uses) do
        local better = (use.priority or 0) > priority
            or ((use.priority or 0) == priority and (use.value or 0) > value)
        if not better then break end
        local ok, plan = AIUnsupported.capture(function() return self:tryUseCard(use.card) end)
        if ok and type(plan) == "table" and plan.card then return true end
    end
    return false
end

local function activate_when_best(self, skill, priority, value, build)
    local answer = build()
    if answer == nil then return nil end
    if better_card_planned(self, priority, value) then return nil end
    return answer
end

-- 換英雄：原版固定不發動。
ai_skill_invoke.guichangetupo = function() return false end

local function duoyi_targets(self, options, key)
    local names = options and options.players or {}
    if options and options.candidates_complete ~= true then
        ai_unsupported(key .. " candidates are incomplete", key)
    end
    return enemy_names(self, names, options.max_count or #names, key)
end

ai_skill_invoke.keguiduoyi = function(self)
    local use = self:getDecisionContext().use
    if type(use) ~= "table" or not use.to then return false end
    local names = {}
    for _, player in ipairs(use.to) do names[#names + 1] = player:objectName() end
    return #enemy_names(self, names, #names, "keguiduoyi") > 0
end
ai_skill_playerschosen.keguiduoyi = function(self, options)
    local names = duoyi_targets(self, options, "keguiduoyi")
    if #names == 0 then return {kind = "pass"} end
    return names
end
ai_skill_invoke.kejieguiduoyi = ai_skill_invoke.keguiduoyi
ai_skill_playerschosen.kejieguiduoyi = function(self, options)
    local names = duoyi_targets(self, options, "kejieguiduoyi")
    if #names == 0 then return {kind = "pass"} end
    return names
end

ai_card_use.keguixianjiCard = function(self, card, use)
    if self.player:hasFlag("Forbidkeguixianji") == true then return end
    fill_lord_gift(self, card, use, "keguixianjiVS", "keguixianji")
end
ai_card_use.kejieguixianjiCard = function(self, card, use)
    fill_lord_gift(self, card, use, "kejieguixianjiVS", "kejieguixianji")
end
sgs.ai_use_value.keguixianjiCard = 8.5
sgs.ai_use_value.kejieguixianjiCard = 8.5
sgs.ai_use_priority.kejieguixianjiCard = 10
sgs.ai_card_intention.keguixianjiCard = -80
sgs.ai_card_intention.kejieguixianjiCard = -80

local function colored_slash_need(to, card, self, color)
    local slashes = visible_slashes(self, to)
    if slashes == nil then return nil end
    local matched = color == "red" and card:isRed() or color == "black" and card:isBlack() or true
    if matched ~= true then return false end
    return card:isKindOf("Slash") or (slashes > 1 and card:isKindOf("Analeptic"))
end
sgs.ai_cardneed.keguihuxiao = function(to, card, self)
    return colored_slash_need(to, card, self, "red")
end
sgs.ai_cardneed.keguilongyin = function(to, card, self)
    return colored_slash_need(to, card, self, "black")
end
sgs.ai_cardneed.keguisheji = function(to, card, self)
    return colored_slash_need(to, card, self, "any")
end
sgs.ai_cardneed.kejieguixiaoyin = function(to, card, self)
    return colored_slash_need(to, card, self, "any")
end
sgs.ai_canliegong_skill.keguisheji = function(_, from, to)
    if from:getPhase() ~= sgs.Player_Play then return false end
    local forward, back = from:inMyAttackRange(to), to:inMyAttackRange(from)
    if forward == nil or back == nil then return nil end
    return forward and back
end

sgs.ai_cardneed.keguijueluone = function(to, card, self)
    local slashes = visible_slashes(self, to)
    if slashes == nil then return nil end
    return card:isKindOf("Slash") and slashes == 0
end
sgs.ai_cardneed.kejieguijuelu = sgs.ai_cardneed.slash

ai_skill_invoke.keguiwumo = function() return true end
ai_skill_invoke.kejieguiwumo = function() return true end
ai_skill_invoke.jueqiaogainslash = function() return true end
sgs.ai_cardneed.kejieguiwumo = function(_, card)
    return card:isKindOf("Slash") and card:isRed()
end
sgs.ai_card_priority.kejieguiwumo = function(_, card)
    if card:isKindOf("Slash") and card:isRed() then return 0.05 end
end

ai_skill_playerchosen.keguituodao = function(self, options)
    offered_names(options, "keguituodao")
    local names = {}
    for _, name in ipairs(options.players) do names[#names + 1] = name end
    return first_relation(self, names, true, "keguituodao") or {kind = "pass"}
end

local function survive_discard(self, from, card, to, flags)
    if not from or not to then return false end
    local hp, peaches = to:getHp(), self:getAllPeachNum()
    if type(hp) ~= "number" or type(peaches) ~= "number" then return nil end
    local damage = self:ajustDamage(from, to, 1, card)
    if type(damage) ~= "number" then return nil end
    if hp + peaches - damage <= 0 then return false end
    if self:canLoseHp(from, card, to) ~= true then return false end
    local equips = from:getEquips()
    if not equips or #equips == 0 then return false end
    return self:doDisCard(from, flags, true)
end

sgs.ai_can_damagehp.keguixiaoshou = function(self, from, card, to)
    return survive_discard(self, from, card, to, "he")
end
sgs.ai_can_damagehp.kejieguixiaoshou = function(self, from, card, to)
    return survive_discard(self, from, card, to, "e")
end
sgs.ai_can_damagehp.kejieguifuwang = function(self, from, card, to)
    local hp, peaches = to:getHp(), self:getAllPeachNum()
    if type(hp) ~= "number" or type(peaches) ~= "number" then return nil end
    local damage = self:ajustDamage(from, to, 1, card)
    if type(damage) ~= "number" then return nil end
    local lord = self.room:getLord()
    if not lord or not from then return false end
    return hp + peaches - damage > 0 and self:canLoseHp(from, card, to) == true
        and lord:getGender() == sgs.General_Male and from:getGender() == sgs.General_Female
end

local function xiaoshou_invoke(self, flags, both_sides)
    local damage = self:getDecisionContext().damage
    if type(damage) ~= "table" then return true end
    local from = damage.from
    if not from then return true end
    if both_sides and damage.to and damage.to:objectName() == self.player:objectName() then
        return self:doDisCard(from, flags, true) == true
    end
    if both_sides and from:objectName() == self.player:objectName() and damage.to then
        return self:doDisCard(damage.to, flags, true) == true
    end
    if not both_sides then return self:doDisCard(from, flags, true) == true end
    return true
end
ai_skill_invoke.keguixiaoshou = function(self) return xiaoshou_invoke(self, "he", false) end
ai_skill_invoke.kejieguixiaoshou = function(self) return xiaoshou_invoke(self, "e", true) end
ai_skill_choice.keguixiaoshou = function(self, options) return choice_of(options, "move", "keguixiaoshou") end
ai_skill_choice.kejieguixiaoshou = function(self, options)
    return choice_of(options, "move", "kejieguixiaoshou")
end

local function equip_choice(self, options, key, random_rest)
    local choices = options and options.choices or {}
    local target = self:getDecisionContext().player
    if target and self:isFriend(target) == true and self:needToThrowArmor(target) == true then
        for _, choice in ipairs(choices) do
            if choice == "1" then return choice end
        end
    end
    if #choices == 0 then ai_unsupported(key .. " has no choice", key) end
    if not random_rest then return choices[1] end
    local index = math.random(0, #choices)
    if index == 0 then return nil end
    return choices[index]
end
ai_skill_choice.keguixiaoshou_equip = function(self, options)
    return equip_choice(self, options, "keguixiaoshou_equip", true)
end
ai_skill_choice.kejieguixiaoshou_equip = function(self, options)
    return equip_choice(self, options, "kejieguixiaoshou_equip", false)
end

local function xiaoshou_player(self, options, key)
    local allowed = offered_names(options, key)
    local friends = self.friends_noself
    if not friends then ai_unsupported(key .. " friends are unknown", key) end
    for _, friend in ipairs(friends) do
        if allowed[friend:objectName()] and self:loseEquipEffect(friend) == true then
            return friend:objectName()
        end
    end
    for _, friend in ipairs(friends) do
        if allowed[friend:objectName()] and self:hasSkills(sgs.need_equip_skill, friend) then
            return friend:objectName()
        end
    end
    if allowed[self.player:objectName()] then return self.player:objectName() end
    return {kind = "pass"}
end
ai_skill_playerchosen.keguixiaoshou = function(self, options)
    return xiaoshou_player(self, options, "keguixiaoshou")
end
ai_skill_playerchosen.kejieguixiaoshou = function(self, options)
    return xiaoshou_player(self, options, "kejieguixiaoshou")
end

ai_skill_invoke.keguizhuangshen = function() return true end
ai_skill_invoke.kejieguizhuangshen = function() return true end
local function random_offered(self, options, key)
    local names = options and options.players or {}
    if options and options.candidates_complete ~= true or #names == 0 then
        ai_unsupported(key .. " candidates are incomplete", key)
    end
    return names[math.random(#names)]
end
ai_skill_playerchosen.keguizhuangshen = function(self, options)
    return random_offered(self, options, "keguizhuangshen")
end
ai_skill_playerchosen.kejieguizhuangshen = function(self, options)
    return random_offered(self, options, "kejieguizhuangshen")
end

local function zhuangshen_choice(self, options, key)
    local skills = options and options.choices or {}
    if #skills == 0 then ai_unsupported(key .. " has no skill", key) end
    local player = self:getDecisionContext().player or self.player
    for _, high in ipairs({true, false}) do
        for _, skill in ipairs(skills) do
            if self:isValueSkill(skill, player, high) == true then return skill end
        end
    end
    local pool = {}
    for _, skill in ipairs(skills) do
        local bad = type(sgs.bad_skills) == "string"
            and string.find("|" .. sgs.bad_skills .. "|", "|" .. skill .. "|", 1, true)
        if not bad then pool[#pool + 1] = skill end
    end
    if #pool == 0 then pool = skills end
    return pool[math.random(#pool)]
end
ai_skill_choice.keguizhuangshen = function(self, options)
    return zhuangshen_choice(self, options, "keguizhuangshen")
end
ai_skill_choice.kejieguizhuangshen = function(self, options)
    return zhuangshen_choice(self, options, "kejieguizhuangshen")
end

-- 大霧／狂風的舊字串目標不在 isolated ABI。原版對不上時回自己，這裡同樣回自己。
ai_skill_playerchosen.kejieguizhuangshenbuff = function(self, options)
    local allowed = offered_names(options, "kejieguizhuangshenbuff")
    if allowed[self.player:objectName()] then return self.player:objectName() end
    return options.players[1]
end
ai_skill_choice.kejieguizhuangshenbuff = function(self, options)
    local player = self:getDecisionContext().player
    local friend = player and self:isFriend(player)
    if friend == nil then ai_unsupported("buff target relation is unknown", "kejieguizhuangshenbuff") end
    return choice_of(options, friend and "guidawu" or "guikuangfeng", "kejieguizhuangshenbuff")
end

ai_skill_activate.keguitiqi = function(self)
    return activate_when_best(self, "keguitiqi", 0, 2.5, function()
        if self.player:canDiscard(self.player, "he") ~= true then return nil end
        local enemies = self.enemies
        if not enemies or #enemies == 0 then return nil end
        local cards = self.player:getCards("he")
        if not cards or #cards == 0 then return nil end
        local ordered = self:sortByKeepValue(cards) or cards
        local ids = {}
        if self:needToThrowArmor() == true and self.player:getArmor() then
            ids[#ids + 1] = self.player:getArmor():getEffectiveId()
        end
        for _, card in ipairs(ordered) do
            local id = card:getEffectiveId()
            local seen = false
            for _, have in ipairs(ids) do if have == id then seen = true break end end
            if not seen then ids[#ids + 1] = id end
        end
        local targets = {}
        for _, enemy in ipairs(enemies) do
            local level = self:objectiveLevel(enemy)
            local hp, enemy_hp = self.player:getHp(), enemy:getHp()
            if type(level) == "number" and level > 3 and self:cantbeHurt(enemy) == false
                and self:damageIsEffective(enemy) == true
                and type(hp) == "number" and type(enemy_hp) == "number"
                and hp > enemy_hp and hp > 1 then
                targets[#targets + 1] = enemy:objectName()
                if #targets >= #ids then break end
            end
        end
        while #ids > #targets do table.remove(ids) end
        if #targets == 0 or #ids == 0 then return nil end
        return skill_use(self, "keguitiqi", ids, targets)
    end)
end
sgs.ai_use_value.keguitiqiCard = 2.5
sgs.ai_card_intention.keguitiqiCard = 80
sgs.dynamic_value.damage_card.keguitiqiCard = true

ai_card_use.keguishouyeCard = function(self, card, use)
    fill_draw_gift(self, card, use, "keguishouye", function()
        return self.player:getMark("@guijiehuo") > 0 and dead_allies(self, "keguishouye")
    end)
end
ai_card_use.kejieguishouyeCard = function(self, card, use)
    fill_draw_gift(self, card, use, "kejieguishouye", function()
        return self.player:getMark("&kejieguijiehuo") < 4
            and self.player:hasSkill("kejieguijiehuo")
            and dead_allies(self, "kejieguishouye")
    end)
end
sgs.ai_use_value.keguishouyeCard = 8.5
sgs.ai_use_priority.keguishouyeCard = 9.5
sgs.ai_card_intention.keguishouyeCard = -80
sgs.ai_use_value.kejieguishouyeCard = 8.5
sgs.ai_use_priority.kejieguishouyeCard = 9.5
sgs.ai_card_intention.kejieguishouyeCard = -80

local function jiehuo_cards(self, limit, key)
    if not dead_allies(self, key) then return nil end
    local cards = self.player:getHandcards()
    if not cards then ai_unsupported(key .. " hand is unknown", key) end
    local ordered = self:sortByUseValue(cards, true) or cards
    local ids = distinct_suits(ordered, limit)
    if #ids < limit then return nil end
    return ids
end
ai_skill_activate.keguijiehuo = function(self)
    return activate_when_best(self, "keguijiehuo", 9.5, 8, function()
        if self.player:getMark("@guijiehuo") <= 0 then return nil end
        local ids = jiehuo_cards(self, 4, "keguijiehuo")
        if not ids then return nil end
        return skill_use(self, "keguijiehuo", ids, nil)
    end)
end
ai_skill_activate.kejieguijiehuo = function(self)
    return activate_when_best(self, "kejieguijiehuo", 9.5, 8, function()
        if self.player:getMark("&kejieguijiehuo") >= 4 then return nil end
        local ids = jiehuo_cards(self, 3, "kejieguijiehuo")
        if not ids then return nil end
        return skill_use(self, "kejieguijiehuo", ids, nil)
    end)
end
sgs.ai_use_value.keguijiehuoCard = 8
sgs.ai_use_priority.keguijiehuoCard = 9.5
sgs.ai_use_value.kejieguijiehuoCard = 8
sgs.ai_use_priority.kejieguijiehuoCard = 9.5

ai_skill_choice["kexianjishi-ask"] = function(self, options)
    local items = options and options.choices or {}
    if #items == 0 then ai_unsupported("kexianjishi-ask has no general", "kexianjishi-ask") end
    local players = known(self.room:getAllPlayers(true), "kexianjishi-ask")
    for _, name in ipairs(items) do
        if name ~= "cancel" then
            for _, player in ipairs(players) do
                if player:getGeneralName() == name and same_visible_side(self, player) == true then
                    return name
                end
            end
        end
    end
    return items[math.random(#items)]
end

ai_skill_invoke.keguiqinwang = function(self)
    local target = self:getDecisionContext().player
    local damage = self:getDecisionContext().damage
    if not target or type(damage) ~= "table" then
        ai_unsupported("qinwang target or damage is not projected", "keguiqinwang")
    end
    if self:isFriend(target) ~= true then return false end
    if damage.from and self:isFriend(damage.from) == true then return false end
    if self:needToLoseHp(target, damage.from, damage.card) == true then return false end
    local hand, equips = self.player:getHandcardNum(), self.player:getEquips()
    if type(hand) ~= "number" or not equips then
        ai_unsupported("qinwang card count is unknown", "keguiqinwang")
    end
    if hand + #equips < 2 and self:isWeak(target) ~= true then return false end
    return self:isWeak(target) == true and self:isWeak(self.player) == false
end
sgs.ai_ajustdamage_from.keguiqinwang = function(_, from, _, card)
    if card and (card:isKindOf("Slash") or card:isKindOf("Duel"))
        and from:getPhase() == sgs.Player_Play then
        return from:getMark("@guiqinwang")
    end
end

ai_skill_invoke.kejieguiqideng = function(self)
    local peaches, hp = self:getAllPeachNum(), self.player:getHp()
    if type(peaches) ~= "number" or type(hp) ~= "number" then
        ai_unsupported("qideng rescue count is unknown", "kejieguiqideng")
    end
    if peaches < hp then return true end
    local dying = self:getDecisionContext().dying
    local card = type(dying) == "table" and type(dying.damage) == "table" and dying.damage.card or nil
    if card and type(card.hasFlag) == "function" and card:hasFlag("zhashicardflag") == true then
        return true
    end
    if type(dying) ~= "table" then
        ai_unsupported("qideng dying damage is not projected", "kejieguiqideng")
    end
    return false
end

ai_card_use.kejieguizhashiCard = function(self, card, use)
    local enemies = self.enemies
    if not enemies then ai_unsupported("zhashi enemies are unknown", "kejieguizhashi") end
    local ordered = self:sort(enemies, "defense")
    if ordered then
        enemies = {}
        for index = #ordered, 1, -1 do enemies[#enemies + 1] = ordered[index] end
    end
    local allowed = single_target_names(card, "kejieguizhashi")
    local targets = {}
    for index = #enemies, 1, -1 do
        local enemy = enemies[index]
        local distance, range = enemy:distanceTo(self.player), enemy:getAttackRange()
        if type(distance) == "number" and type(range) == "number" and distance <= range
            and self:isTiaoxinTarget(enemy) == true and (self:objectiveLevel(enemy) or 0) > 3
            and self:cantbeHurt(enemy) == false and allowed[enemy:objectName()] then
            -- 雷電調整尚未進共用 ajustDamage。接不住時沿用原版「仍然考慮這個敵人」。
            local ok, effective = AIUnsupported.capture(function()
                return self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player)
            end)
            if not ok or effective ~= false then
                targets[#targets + 1] = enemy
            end
        end
    end
    if #targets == 0 then return end
    sgs.ai_use_priority["#kejieguizhashiCard"] = 8
    if not self.player:getArmor() and self.player:isKongcheng() ~= true then
        local hand = self.player:getCards("h") or {}
        for _, held in ipairs(hand) do
            if held:isKindOf("Armor") and (self:evaluateArmor(held) or 0) > 3 then
                sgs.ai_use_priority["#kejieguizhashiCard"] = 5.9
                break
            end
        end
    end
    local ordered = self:sort(targets, "defenseSlash") or targets
    use.card = card
    use.to:append(ordered[1])
end
sgs.ai_use_value.kejieguizhashiCard = 8.5
sgs.ai_use_priority.kejieguizhashiCard = 9.5
sgs.ai_card_intention.kejieguizhashiCard = 80

local function longyin_target(self, options, key)
    local allowed = offered_names(options, key)
    if self.player:getRole() == "loyalist" then
        local lord = self.room:getLord()
        if lord and allowed[lord:objectName()] and self:isWeak(lord) == true then
            return lord:objectName()
        end
    end
    for _, name in ipairs(options.players) do
        local player = known(self.room:findPlayerByObjectName(name, true), key)
        if self:isFriend(player) == true then return name end
    end
    return nil
end
ai_skill_invoke.kejieguilongyin = function(self)
    local names = {}
    local players = known(self.room:getAlivePlayers(), "kejieguilongyin")
    for _, player in ipairs(players) do names[#names + 1] = player:objectName() end
    return longyin_target(self, {players = names, candidates_complete = true}, "kejieguilongyin") ~= nil
end
ai_skill_playerchosen.kejieguilongyin = function(self, options)
    return longyin_target(self, options, "kejieguilongyin") or {kind = "pass"}
end

sgs.ai_ajustdamage_from.kejieguixiaoyin = function(_, _, _, card)
    if card and card:isKindOf("Slash") and card:isRed() then return 1 end
end

ai_skill_choice.kejieguituodao = function(self, options)
    local current = self.room:getCurrent()
    local alive = self.room:getAlivePlayers()
    if current and alive and self.player:getMark("&jieguiwumozhuangbei-SelfClear") == 0 then
        local enemies = self:getEnemyNumBySeat(current, self.player, self.player, true)
        if type(enemies) == "number" and enemies > #alive / 2 then
            return choice_of(options, "dao", "kejieguituodao")
        end
    end
    -- 原版借 zero_card_as_slash 決定能不能出殺。這裡只看攻擊範圍內的敵人。
    local others = self.room:getOtherPlayers(self.player) or {}
    for _, player in ipairs(others) do
        if self:isEnemy(player) == true and self.player:inMyAttackRange(player) == true then
            return choice_of(options, "sha", "kejieguituodao")
        end
    end
    return choice_of(options, "dao", "kejieguituodao")
end
ai_skill_playerchosen.kejieguituodao = function(self, options)
    local names = {}
    for _, name in ipairs(options and options.players or {}) do names[#names + 1] = name end
    return first_relation(self, names, true, "kejieguituodao") or {kind = "pass"}
end

ai_skill_invoke.kejieguisheji = function(self)
    local use = self:getDecisionContext().use
    local target = self:getDecisionContext().player
    if type(use) ~= "table" or not use.card or not target then
        ai_unsupported("sheji use or target is not projected", "kejieguisheji")
    end
    if use.from and self:isFriend(use.from) == true then return false end
    if self:isFriend(target) == true and self:slashIsEffective(use.card, target, use.from) == true then
        return true
    end
    if use.from and self:isEnemy(use.from) == true
        and self:damageIsEffective(use.from, sgs.DamageStruct_Normal, self.player) == true
        and self:cantbeHurt(use.from) == false then
        return true
    end
    return false
end
sgs.ai_cardneed.kejieguisheji = sgs.ai_cardneed.bignumber
ai_skill_pindian.kejieguisheji = function(self, options)
    local cards = known(self.player:getHandcards(), "kejieguisheji")
    if #cards == 0 then ai_unsupported("sheji pindian hand is empty", "kejieguisheji") end
    local target
    local others = self.room:getOtherPlayers(self.player) or {}
    for _, player in ipairs(others) do
        if player:hasFlag("kejieguishejiPindianTarget") == true then target = player break end
    end
    local offered_ids = {}
    for _, id in ipairs(options and options.card_ids or {}) do offered_ids[id] = true end
    if not options or options.candidates_complete ~= true or next(offered_ids) == nil then
        ai_unsupported("sheji pindian cards are incomplete", "kejieguisheji")
    end
    local pool = {}
    for _, card in ipairs(cards) do
        if offered_ids[card:getEffectiveId()] then pool[#pool + 1] = card end
    end
    if #pool == 0 then ai_unsupported("sheji pindian hand is not offered", "kejieguisheji") end
    cards = pool
    local ordered = self:sortByKeepValue(cards) or cards
    local maximum = self:getKeepValue(ordered[#ordered]) or 0
    local requestor_name = options.players and options.players[1]
    local requestor = requestor_name and self.room:findPlayerByObjectName(requestor_name, true)
    local other_name = requestor and requestor:objectName()
    if other_name == self.player:objectName() then
        local use = self:getDecisionContext().use
        other_name = type(use) == "table" and use.from and use.from:objectName() or other_name
    end
    local low = target and self:isFriend(target) == true and self:isWeak(target) == true
        and other_name and self.player:objectName() ~= other_name
    table.sort(cards, function(a, b)
        if low then return a:getNumber() < b:getNumber() end
        return a:getNumber() > b:getNumber()
    end)
    for _, card in ipairs(cards) do
        local keep = self:getKeepValue(card)
        if maximum > 7 or (type(keep) == "number" and keep < 7) or card:isKindOf("EquipCard") then
            return card:getEffectiveId()
        end
    end
    return cards[1]:getEffectiveId()
end
