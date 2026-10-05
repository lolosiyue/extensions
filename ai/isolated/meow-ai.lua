-- Meow 隔離 AI。SmartAI 相等函式在 smart-ai-functions.lua。
-- 本檔只擴充技能名單與各 Meow handler，不改基礎層。
-- 主動技走已授權的轉化票；缺投影回 nil／unsupported，不猜成不出牌。

sgs.append_skill_list("notActive_cardneed_skill", "MeowBeige")
sgs.append_skill_list("exclusive_skill", "MeowDuanchang")
sgs.append_skill_list("Active_cardneed_skill", "MeowQiangwu")
sgs.append_skill_list("lose_equip_skill", "MeowXiaoji")
sgs.append_skill_list("jueqing_skill", "MeowJueqing")

local function relations(self, key)
    if not self.enemies or not self.friends or not self.friends_noself then
        ai_unsupported(key .. " relations are unknown", key)
    end
end

local function role_of(player)
    if not player or type(player.getRole) ~= "function" then return nil end
    local role = player:getRole()
    if role == "lord" or role == "loyalist" or role == "rebel" or role == "renegade" then return role end
    return nil
end

local function choices_of(options, key)
    local items = type(options) == "table" and options.choices or nil
    if type(items) ~= "table" or #items == 0 then
        ai_unsupported(key .. " choices are missing", key)
    end
    return items
end

local function pick(items, wanted)
    for _, choice in ipairs(items) do
        if choice == wanted then return choice end
    end
end

local function damage_of(self, key)
    local damage = self:getDecisionContext().damage
    if type(damage) ~= "table" or not damage.to then
        ai_unsupported(key .. " damage is not projected", key)
    end
    return damage
end

local function use_of(self, key)
    local use = self:getDecisionContext().use
    if type(use) ~= "table" or not use.card then
        ai_unsupported(key .. " card use is not projected", key)
    end
    return use
end

local function same(left, right)
    return left and right and left:objectName() == right:objectName()
end

local function activate(skill)
    return function(self)
        return self:playAuthorizedConversion(skill)
    end
end

local function bind_use(name, handler)
    sgs.ai_skill_use_func["#" .. name] = handler
    sgs.ai_skill_use_func[name] = handler
end

-- 悲歌：先看來源翻面，再依目標回血、摸牌、棄牌選花色。
local function beige_friend(self, player)
    local relation = self:relationTo(player)
    -- isFriend() folds the string "unknown" into false; this strategy needs certainty.
    if relation == nil or relation == "unknown" then return nil end
    return relation == "friend"
end

local function beige_suit(self, damage)
    if damage.from then
        local friend = beige_friend(self, damage.from)
        if friend == nil then return nil end
        local turn = self:toTurnOver(damage.from, 0)
        if turn == nil then return nil end
        if friend and not turn then return "Spade" end
        if not friend and turn then return "Spade" end
    end
    local target_friend = beige_friend(self, damage.to)
    if target_friend == nil then return nil end
    local hp = damage.to:getHp()
    local best = getBestHp(damage.to)
    if type(hp) ~= "number" or type(best) ~= "number" then return nil end
    if hp < best and target_friend then return "Heart" end
    local draw = self:canDraw(damage.to)
    if draw == nil then return nil end
    if target_friend and draw then return "Diamond" end
    if damage.from then
        local discard = self:doDisCard(damage.from, "he")
        if discard == nil then return nil end
        if discard then return "Club" end
    end
    return false
end

ai_skill_cardask["@MeowBeige"] = function(self, options)
    local damage = damage_of(self, "MeowBeige")
    local help = beige_friend(self, damage.to)
    local source_friend = false
    if damage.from then source_friend = beige_friend(self, damage.from) end
    if help == nil or (damage.from and source_friend == nil) then
        ai_unsupported("MeowBeige relations are unknown", "MeowBeige")
    end
    if not help or source_friend then return {kind = "pass"} end
    local cards = self.player:getCards("he")
    if not cards then ai_unsupported("MeowBeige cards are unknown", "MeowBeige") end
    cards = self:sortByUseValue(cards, true)
    if not cards then ai_unsupported("MeowBeige card order is unknown", "MeowBeige") end
    local suit = beige_suit(self, damage)
    if suit == nil then ai_unsupported("MeowBeige suit policy is unknown", "MeowBeige") end
    local function give(wanted)
        for _, card in ipairs(cards) do
            if card:getSuitString() == string.lower(wanted) then return card:getEffectiveId() end
        end
    end
    if suit and suit ~= false then
        local id = give(suit)
        if id then return id end
    end
    for _, card in ipairs(cards) do
        local card_suit = card:getSuitString()
        local best = getBestHp(damage.to)
        local draw = self:canDraw(damage.to)
        if (card_suit == "heart" and type(best) == "number" and damage.to:getHp() < best and help)
            or (card_suit == "diamond" and help and draw)
            or (card_suit == "club" and damage.from and self:doDisCard(damage.from, "he")) then
            return card:getEffectiveId()
        end
    end
    local discard = self:askForDiscard("beige", 1, 1, false, true)
    -- An unknown discard order is not an intentional refusal to pay.
    if discard == nil then ai_unsupported("MeowBeige discard is unknown", "MeowBeige") end
    if discard and discard[1] then return discard[1] end
    return {kind = "pass"}
end

function sgs.ai_cardneed.MeowBeige(to, card)
    local count = to:getCardCount()
    if type(count) ~= "number" then return nil end
    return count <= 2
end

ai_skill_choice.MeowBeige = function(self, options)
    local items = choices_of(options, "MeowBeige")
    local suit = beige_suit(self, damage_of(self, "MeowBeige"))
    if suit == nil then ai_unsupported("MeowBeige suit policy is unknown", "MeowBeige") end
    if suit and suit ~= false then
        local chosen = pick(items, suit)
        if chosen then return chosen end
    end
    return items[math.random(1, #items)]
end

function sgs.ai_slash_prohibit.MeowDuanchang(self, from, to)
    local jueqing = self:hasJueqingEffect(from, to)
    if jueqing == nil then return nil end
    if jueqing or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
    if from:hasFlag("NosJiefanUsed") then return false end
    local hp = to:getHp()
    local enemies = self:getEnemies(from)
    if type(hp) ~= "number" or not enemies then return nil end
    if hp > 1 or #enemies == 1 then return false end
    if from:getMaxHp() == 3 and from:getArmor() and from:getDefensiveHorse() then return false end
    local weak = self:isWeak(from)
    if weak == nil then return nil end
    if from:getMaxHp() <= 3 or (from:isLord() and weak) then return true end
    local lord = self.room:getLord()
    if from:getMaxHp() <= 3 or (lord and role_of(from) == "renegade") then return true end
    return false
end

-- 離間：沿用原版先主忠、再武魂、再敵方配對。決鬥有效性用類別探測，不出假牌。
local function use_lijian(card, use, self)
    relations(self, "Meowlijian")
    local alive = self.player:aliveCount()
    if alive == nil then ai_unsupported("Meowlijian player count is unknown", "Meowlijian") end
    local nude = self.player:isNude()
    if nude == nil then ai_unsupported("Meowlijian cards are unknown", "Meowlijian") end
    if nude or alive < 3 then return end
    local n = (self.player:getHandcardNum() or 0) + #(self.player:getEquips() or {})
    if not self.player:hasSkill("Meowdoumiao") then n = n + 1 end
    if n <= 1 then return end
    local duel = self:classProbe("Duel")
    local function trick_ok(to, from)
        local effective = self:hasTrickEffective(duel, to, from)
        if effective ~= nil then return effective end
        return self:damageIsEffective(to, sgs.DamageStruct_Normal, from)
    end
    local targets = {}
    local lord = self.room:getLord()
    local my_role = role_of(self.player)
    if my_role == "rebel" and lord and not same(lord, self.player) and not lord:isNude() then
        local enemies = self:sort(self.enemies, "handcard")
        if not enemies then ai_unsupported("Meowlijian enemy order is unknown", "Meowlijian") end
        for _, enemy in ipairs(enemies) do
            if enemy:getHp() == 1 and not same(enemy, lord) and trick_ok(enemy, lord) then
                targets[#targets + 1] = enemy
                targets[#targets + 1] = lord
                break
            end
        end
    end
    if #targets < n then
        local ordered = self:sort(self.enemies, "defense")
        if not ordered then ai_unsupported("Meowlijian defense order is unknown", "Meowlijian") end
        local first
        for _, enemy in ipairs(ordered) do
            if not enemy:hasSkills("wuyan|noswuyan") and not first then first = enemy end
        end
        if first then
            for _, enemy in ipairs(ordered) do
                if not same(enemy, first) and trick_ok(first, enemy) and not table.contains(targets, enemy) then
                    if not table.contains(targets, first) then targets[#targets + 1] = first end
                    targets[#targets + 1] = enemy
                    if #targets >= n then break end
                end
            end
        end
    end
    if #targets >= 2 and n >= #targets then
        use.card = card
        for _, target in ipairs(targets) do use.to:append(target) end
    end
end
bind_use("MeowlijianCard", use_lijian)
ai_skill_activate.Meowlijian = activate("Meowlijian")
sgs.ai_use_value.MeowlijianCard = 8.5
sgs.ai_use_priority.MeowlijianCard = 4
sgs.dynamic_value.damage_card.MeowlijianCard = true

ai_skill_invoke.MeowQieting = function() return true end

ai_skill_choice.MeowQieting = function(self, options)
    local items = choices_of(options, "MeowQieting")
    local target = self:getDecisionContext().player
    if not target then ai_unsupported("MeowQieting target is missing", "MeowQieting") end
    if pick(items, "draw") and self:isFriend(target) then return "draw" end
    local hand = getChoice(items, "getHCrad")
    local equip = getChoice(items, "get")
    if (target:getHandcardNum() or 0) >= 2 and hand then return hand end
    local equips = target:getEquips()
    if equips and #equips > 0 and equip then return equip end
    if pick(items, "draw") then return "draw" end
    return items[1]
end

local function xianzhou_target(self, card)
    relations(self, "Meowxianzhou")
    local weak = self:isWeak()
    if weak == nil then ai_unsupported("Meowxianzhou weakness is unknown", "Meowxianzhou") end
    if weak then
        for _, friend in ipairs(self.friends_noself) do
            local blocked = hasManjuanEffect(friend)
            local draw = self:canDraw(friend, self.player)
            if blocked == nil or draw == nil then
                ai_unsupported("Meowxianzhou draw policy is unknown", "Meowxianzhou")
            end
            if not blocked and draw then return friend end
        end
    end
    if not self.player:isWounded() then
        for _, friend in ipairs(self.friends_noself) do
            for _, target in ipairs(self.room:getOtherPlayers(self.player) or {}) do
                local reach = friend:inMyAttackRange(target)
                local effective = self:damageIsEffective(target, nil, friend)
                local lose = self:needToLoseHp(target, friend)
                local target_weak = self:isWeak(target)
                if reach and effective and lose == false and target_weak then return friend end
            end
        end
    end
    local equips = self.player:getEquips()
    if equips and (#equips > 2 or (#self.enemies > 0 and #equips > #self.enemies)) then
        local friends = self:sort(self.friends_noself, "defense")
        return friends and friends[1] or nil
    end
    return nil
end

local function use_xianzhou(card, use, self)
    if self.player:getMark("@handover") == 0 then return end
    local equips = self.player:getEquips()
    if not equips or #equips == 0 then return end
    local ids = card:getSubcards()
    if ids and #ids == 0 then return end
    local target = xianzhou_target(self, card)
    if target then
        use.card = card
        use.to:append(target)
    end
end
bind_use("MeowxianzhouCard", use_xianzhou)
ai_skill_activate.Meowxianzhou = activate("Meowxianzhou")
sgs.ai_use_priority.MeowxianzhouCard = 2

ai_skill_use["@@Meowxianzhou"] = function(self)
    relations(self, "Meowxianzhou")
    local current = self.room:getCurrent()
    local limit = tonumber(self.player:getMark("Meowxianzhou_count")) or 0
    if limit <= 0 then return {kind = "pass"} end
    if current and self:isWeak(current) and self:isFriend(current) then return {kind = "pass"} end
    local targets = {}
    local function add(pool)
        for _, target in ipairs(pool) do
            local reach = self.player:inMyAttackRange(target)
            local effective = self:damageIsEffective(target, nil, self.player)
            local lose = self:needToLoseHp(target, self.player)
            if reach and effective and lose == false then
                targets[#targets + 1] = target:objectName()
                if #targets == limit then return true end
            end
        end
    end
    local enemies = self:sort(self.enemies, "hp")
    if not enemies then ai_unsupported("Meowxianzhou enemy order is unknown", "Meowxianzhou") end
    if not add(enemies) then
        local friends = sgs.reverse(self.friends_noself)
        if friends then add(friends) end
    end
    if #targets == 0 then return {kind = "pass"} end
    local action = self:getSkillAction("Meowxianzhou")
    return {
        kind = "use_card",
        skill_action = action and action:toAnswer() or nil,
        targets = targets
    }
end

ai_skill_choice.Meowxianzhou = function(self, options)
    local items = choices_of(options, "Meowxianzhou")
    local answer = ai_skill_use["@@Meowxianzhou"](self)
    if type(answer) == "table" and answer.kind == "use_card" and pick(items, "damage") then
        return "damage"
    end
    return pick(items, "recover") or items[1]
end

sgs.ai_cardneed.MeowQiangwu = sgs.ai_cardneed.slash

sgs.ai_target_revises.MeowJuxiang = function(to, card)
    if card and card:isKindOf("SavageAssault") then return true end
end

function sgs.ai_cardneed.MeowLieren(to, card, self)
    if not self or not isCard("Slash", card, to) then return false end
    local known = getKnownCard(to, self.player, "Slash", true)
    if known == nil then return nil end
    return known == 0
end

ai_skill_invoke.MeowLieren = function(self)
    local use = use_of(self, "MeowLieren")
    if not use.to then return false end
    for _, target in ipairs(use.to) do
        if self:doDisCard(target, "he", true) then return true end
    end
    return false
end

ai_skill_use["@@MeowLieren"] = function(self)
    relations(self, "MeowLieren")
    local enemies = self:sort(self.enemies, "handcard")
    if not enemies then ai_unsupported("MeowLieren enemy order is unknown", "MeowLieren") end
    for _, enemy in ipairs(enemies) do
        local marked = enemy:hasFlag("MeowLierenMarkto")
        local from_mark = self.player:hasFlag("MeowLierenMarkfrom")
        local pindian = self.player:canPindian(enemy)
        if pindian == nil then ai_unsupported("MeowLieren pindian state is unknown", "MeowLieren") end
        if pindian and ((marked and from_mark) or not from_mark) and self:doDisCard(enemy, "he", true, 2) then
            local action = self:getSkillAction("MeowLieren")
            return {
                kind = "use_card",
                skill_action = action and action:toAnswer() or nil,
                targets = {enemy:objectName()}
            }
        end
    end
    return {kind = "pass"}
end

sgs.ai_skill_pindian.MeowLieren = function(minusecard, self, requestor)
    local cards = self.player:getHandcards()
    if not cards or #cards == 0 then return nil end
    cards = self:sortByKeepValue(cards)
    if not cards then return nil end
    if requestor and same(requestor, self.player) then return cards[1] end
    local maximum = self:getMaxCard(self.player)
    return maximum or cards[#cards]
end

function sgs.ai_cardneed.MeowJizhi(to, card)
    return card and card:isKindOf("TrickCard")
end

local function guose_diamond(self)
    local cards = self:addHandPile("he")
    if not cards then return nil end
    cards = self:sortByUseValue(cards, true)
    if not cards then return nil end
    for _, card in ipairs(cards) do
        if card:getSuit() == sgs.Card_Diamond then
            local value = self:getUseValue(card)
            local indulgence = sgs.ai_use_value.Indulgence
            if type(value) == "number" and type(indulgence) == "number" and value < indulgence then
                return card
            end
        end
    end
    return false
end

local function use_guose_remove(card, use, self)
    relations(self, "MeowGuose")
    if (self.player:getMark("MeowGuoseUsed") or 0) >= 4 then return end
    local friends = self:sort(self.friends)
    if not friends then return end
    for _, friend in ipairs(friends) do
        if friend:containsTrick("Indulgence") and self:willSkipPlayPhase(friend) then
            local judging = friend:getJudgingArea()
            if judging then
                for _, judge in ipairs(judging) do
                    if judge:isKindOf("Indulgence")
                        and self.player:canDiscard(friend, judge:getEffectiveId()) then
                        use.card = card
                        use.to:append(friend)
                        return
                    end
                end
            end
        end
    end
end
bind_use("MeowGuoseCard", use_guose_remove)

local function use_guose_play(card, use, self)
    if (self.player:getMark("MeowGuoseUsed") or 0) >= 4 then return end
    local diamond = self:conversionSubcard(card)
    if diamond == nil then ai_unsupported("MeowGuose subcard is unknown", "MeowGuose") end
    if diamond == false or diamond:getSuit() ~= sgs.Card_Diamond then return end
    if type(ai_card_use.Indulgence) == "function" then
        ai_card_use.Indulgence(self, card, use)
        if use.card then use.card = card end
    end
end
bind_use("MeowGuoseCard2", use_guose_play)
ai_skill_activate.MeowGuose = function(self)
    if (self.player:getMark("MeowGuoseUsed") or 0) >= 4 then return nil end
    local diamond = guose_diamond(self)
    if diamond == nil then ai_unsupported("MeowGuose cards are unknown", "MeowGuose") end
    if diamond then
        local played = self:playAuthorizedConversion("MeowGuose", {
            accept = function(ai, conversion)
                local sub = ai:conversionSubcard(conversion)
                return sub and sub:getEffectiveId() == diamond:getEffectiveId()
            end
        })
        if played then return played end
    end
    return self:playAuthorizedConversion("MeowGuose", {
        accept = function(ai, conversion)
            local name = conversion:getName()
            return name == "MeowGuoseCard" or name == "#MeowGuoseCard"
        end
    })
end
sgs.ai_use_priority["#MeowGuoseCard"] = 5.5
sgs.ai_use_value["#MeowGuoseCard"] = 5
sgs.ai_use_priority["#MeowGuoseCard2"] = 5.5
sgs.ai_use_value["#MeowGuoseCard2"] = 5

function sgs.ai_cardneed.MeowGuose(to, card)
    return card and card:getSuit() == sgs.Card_Diamond
end

local function liuli_card(self, who, cards, range_fix)
    if not cards then return nil end
    cards = self:sortByKeepValue(cards)
    if not cards then return nil end
    for _, card in ipairs(cards) do
        local reach = true
        if range_fix then
            local extra = 0
            if card:isKindOf("Weapon") then
                local weapon_range = card:getRange() or (sgs.weapon_range or {})[card:getClassName()]
                local bare = self.player:getAttackRange()
                if type(weapon_range) ~= "number" or type(bare) ~= "number" then return nil end
                extra = weapon_range - bare
            end
            if card:isKindOf("OffensiveHorse") then extra = extra + 1 end
            reach = self:canSlash(self.player, who, nil, true)
            if reach == nil then return nil end
        else
            reach = self:canSlash(self.player, who)
            if reach == nil then return nil end
        end
        if reach then return card:getEffectiveId() end
    end
    return false
end

ai_skill_use["@@MeowLiuli"] = function(self)
    relations(self, "MeowLiuli")
    local source
    for _, player in ipairs(self.room:getOtherPlayers(self.player) or {}) do
        if player:hasFlag("MeowLiuliSlashSource") then source = player break end
    end
    local limit = self.player:hasSkill("Meowdoumiao") and 1 or 2
    local targets, paid_id = {}, nil
    local function consider(who)
        if source and same(source, who) then return end
        if #targets >= limit then return end
        local hand = liuli_card(self, who, self.player:getCards("h"), false)
        if hand == nil then ai_unsupported("MeowLiuli hand is unknown", "MeowLiuli") end
        if type(hand) == "number" then
            paid_id = paid_id or hand
            targets[#targets + 1] = who:objectName()
            return
        end
        local equip = liuli_card(self, who, self.player:getCards("e"), true)
        if equip == nil then ai_unsupported("MeowLiuli equips are unknown", "MeowLiuli") end
        if type(equip) == "number" then
            paid_id = paid_id or equip
            targets[#targets + 1] = who:objectName()
        end
    end
    local enemies = self:sort(self.enemies, "defense")
    if not enemies then ai_unsupported("MeowLiuli enemy order is unknown", "MeowLiuli") end
    for _, enemy in ipairs(enemies) do consider(enemy) end
    if #targets < limit then
        local friends = sgs.reverse(self:sort(self.friends_noself, "defense") or {})
        for _, friend in ipairs(friends or {}) do
            local context = self:getDecisionContext().use
            local slash = type(context) == "table" and context.card or nil
            local effective = self:slashIsEffective(slash, friend)
            local lose = self:needToLoseHp(friend, source)
            if effective == false or lose then consider(friend) end
        end
    end
    if #targets == 0 or type(paid_id) ~= "number" then return {kind = "pass"} end
    local action = self:getSkillAction("MeowLiuli")
    return {
        kind = "use_card",
        skill_action = action and action:toAnswer() or nil,
        cards = {paid_id},
        targets = targets
    }
end

function sgs.ai_slash_prohibit.MeowLiuli(self, from, to, card)
    local friend = self:isFriend(to, from)
    if friend == nil then return nil end
    if friend or from:hasFlag("NosJiefanUsed") or to:isNude() then return false end
    local friends = self:getFriends(from, true)
    if not friends then return nil end
    for _, ally in ipairs(friends) do
        local reach = self:canSlash(to, ally, card)
        local effective = self:slashIsEffective(card, ally, from)
        if reach == nil or effective == nil then return nil end
        if reach and effective then return true end
    end
    return false
end

function sgs.ai_cardneed.MeowLiuli(to, card)
    local cards = to:getCards("he")
    if not cards then return nil end
    return #cards <= 2
end

ai_skill_use["@@MeowTianxiang"] = function(self)
    relations(self, "MeowTianxiang")
    local damage = self:getDecisionContext().damage
    if type(damage) ~= "table" then ai_unsupported("MeowTianxiang damage is missing", "MeowTianxiang") end
    local cards = self:sortByUseValue(self.player:getCards("h") or {}, true)
    if not cards then ai_unsupported("MeowTianxiang hand is unknown", "MeowTianxiang") end
    local card_id
    for _, card in ipairs(cards) do
        if card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") then
            card_id = card:getEffectiveId()
            break
        end
    end
    if not card_id then return {kind = "pass"} end
    local amount = damage.damage or damage.amount or 1
    local function answer(target)
        local action = self:getSkillAction("MeowTianxiang")
        return {
            kind = "use_card",
            skill_action = action and action:toAnswer() or nil,
            cards = {card_id},
            targets = {target:objectName()}
        }
    end
    local enemies = self:sort(self.enemies, "hp")
    if not enemies then ai_unsupported("MeowTianxiang enemy order is unknown", "MeowTianxiang") end
    for _, enemy in ipairs(enemies) do
        local hp = enemy:getHp()
        if type(hp) == "number" and hp <= amount and enemy:isAlive() then
            local attack = self:canAttack(enemy, damage.from or self.room:getCurrent(), damage.nature)
            if attack then return answer(enemy) end
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        local lose = self:needToLoseHp(friend)
        local chained = friend:isChained()
        if chained and damage.nature and damage.nature ~= sgs.DamageStruct_Normal then
            local good = self:isGoodChainTarget(friend, damage.card or damage.nature, damage.from, amount)
            if good == false or lose or hasBuquEffect(friend) then return answer(friend) end
        elseif lose or hasBuquEffect(friend) then
            return answer(friend)
        end
    end
    return {kind = "pass"}
end

function sgs.ai_slash_prohibit.MeowTianxiang(self, from, to)
    local jueqing = self:hasJueqingEffect(from, to)
    if jueqing == nil then return nil end
    if jueqing or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
    if from:hasFlag("NosJiefanUsed") or self:isFriend(to, from) then return false end
    return self:cantbeHurt(to, from)
end

function sgs.ai_cardneed.MeowTianxiang(to, card, self)
    if not card or not self then return nil end
    local heart = card:getSuit() == sgs.Card_Heart
        or (to:hasSkill("MeowHongyan") and card:getSuit() == sgs.Card_Spade)
    if not heart then return false end
    local known_heart = getKnownCard(to, self.player, "heart", false)
    local known_spade = getKnownCard(to, self.player, "spade", false)
    if known_heart == nil or known_spade == nil then return nil end
    return known_heart + known_spade < 2
end

local function jieyi_id(self, male)
    local cards = self.player:getCards("he")
    if not cards then return nil end
    cards = self:sortByKeepValue(cards)
    if not cards then return nil end
    for _, card in ipairs(cards) do
        if card:isKindOf("EquipCard") then
            local slot = card:isKindOf("Weapon") and 0 or card:isKindOf("Armor") and 1
                or card:isKindOf("DefensiveHorse") and 2 or card:isKindOf("OffensiveHorse") and 3
                or card:isKindOf("Treasure") and 4
            if type(slot) == "number" and not male:hasEquip(slot) then
                if self.player:canDiscard(self.player, card:getEffectiveId()) then
                    return card:getEffectiveId()
                end
            end
        end
    end
    for _, card in ipairs(cards) do
        if self.player:canDiscard(self.player, card:getEffectiveId()) then
            return card:getEffectiveId()
        end
    end
    return false
end

local function use_jieyi(card, use, self)
    relations(self, "MeowJieyi")
    local function give(pool, predicate)
        for _, target in ipairs(pool) do
            if predicate(target) then
                local id = jieyi_id(self, target)
                if type(id) == "number" then
                    use.card = card
                    use.to:append(target)
                    return true
                end
            end
        end
    end
    local friends = self.friends_noself
    if self:isWeak() and self.player:getLostHp() > 0 then
        if give(friends, function(target)
            return target:getHp() > self.player:getHp() and self:canDraw(target)
        end) then return end
    end
    if give(friends, function(target)
        return self:isWeak(target) and target:getHp() < self.player:getHp() and target:getLostHp() > 0
    end) then return end
    if give(friends, function(target)
        return target:getHp() > self.player:getHp() and self:canDraw(target)
    end) then return end
end
bind_use("MeowJieyiCard", use_jieyi)
ai_skill_activate.MeowJieyi = activate("MeowJieyi")
sgs.ai_use_priority["#MeowJieyiCard"] = 0

ai_skill_choice.MeowJieyi = function(self, options)
    local items = choices_of(options, "MeowJieyi")
    local target = self:getDecisionContext().player
    if not target then ai_unsupported("MeowJieyi target is missing", "MeowJieyi") end
    local best = getBestHp(target)
    if self:isFriend(target) and type(best) == "number" and target:getHp() < best then
        sgs.updateIntention(self.player, target, -80)
        return pick(items, "yes") or "yes"
    end
    return pick(items, "no") or "no"
end

ai_skill_invoke.MeowXiaoji_dis = function(self)
    relations(self, "MeowXiaoji")
    for _, enemy in ipairs(self.enemies) do
        local dangerous = self:getDangerousCard(enemy)
        local valuable = self:getValuableCard(enemy)
        if dangerous == nil or valuable == nil then
            ai_unsupported("MeowXiaoji card value is unknown", "MeowXiaoji")
        end
        if (self:doDisCard(enemy, "he") or dangerous or valuable) and not enemy:isNude() then
            return true
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        local equips = friend:getEquips()
        if self:hasSkills(sgs.lose_equip_skill, friend) and equips and #equips > 0 then return true end
        if self:needToThrowArmor(friend) and friend:getArmor() then return true end
        if self:doDisCard(friend, "he") then return true end
    end
    return false
end

ai_skill_playerchosen.MeowXiaoji = function(self, options)
    relations(self, "MeowXiaoji")
    local names = type(options) == "table" and options.players or nil
    if type(names) ~= "table" then ai_unsupported("MeowXiaoji candidates are missing", "MeowXiaoji") end
    local function offered(player)
        for _, name in ipairs(names) do
            if name == player:objectName() then return true end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if offered(enemy) and not enemy:isNude()
            and (self:doDisCard(enemy, "je") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) then
            return enemy:objectName()
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if offered(friend) and self:doDisCard(friend, "je") then return friend:objectName() end
    end
    return {kind = "pass"}
end

sgs.ai_use_revises.MeowXiaoji = function(self, card, use)
    if card:isKindOf("EquipCard") then
        local value = self:evaluateArmor(card)
        if type(value) == "number" and value > -5 then
            use.card = card
            return true
        end
    end
end

ai_skill_activate.MeowQingguo = function(self)
    if self.player:hasSkill("Meowdoumiao") then return nil end
    local best_id, best_value
    local conversions = self:getConversions()
    if not conversions then ai_unsupported("MeowQingguo conversions are unknown", "MeowQingguo") end
    for _, conversion in ipairs(conversions) do
        if conversion:getActivationSkillName() == "MeowQingguo" and conversion:isKindOf("Peach") then
            local sub = self:conversionSubcard(conversion)
            if sub and sub:isKindOf("Jink") then
                local value = self:getUseValue(sub)
                if type(value) == "number" and (not best_value or value < best_value) then
                    best_id, best_value = sub:getEffectiveId(), value
                end
            end
        end
    end
    if not best_id then return nil end
    return self:playAuthorizedConversion("MeowQingguo", {
        kind = "Peach",
        accept = function(ai, conversion)
            local sub = ai:conversionSubcard(conversion)
            return sub and sub:getEffectiveId() == best_id
        end
    })
end

function sgs.ai_cardneed.MeowQingguo(to, card)
    local hand = to:getCards("h")
    if not hand or not card then return nil end
    return #hand < 2 and (card:isBlack() or card:isKindOf("Jink"))
end

ai_skill_invoke.MeowJueqing = function(self)
    local damage = damage_of(self, "MeowJueqing")
    if damage.to:isDead() or self:isFriend(damage.to) then return false end
    if self:cantDamageMore(self.player, damage.to) then return false end
    local hp = self.player:getHp()
    local amount = damage.damage or damage.amount
    if type(hp) ~= "number" or type(amount) ~= "number" then
        ai_unsupported("MeowJueqing damage size is unknown", "MeowJueqing")
    end
    local gap = amount - hp
    if gap < 0 or hasBuquEffect(self.player) then return true end
    local saved = self:getSaveNum(true)
    if saved == nil then ai_unsupported("MeowJueqing rescue count is unknown", "MeowJueqing") end
    return saved >= gap
end

sgs.ai_getLeastHandcardNum_skill.Meowshangshi = function(self, player, least)
    local lost = player:getLostHp()
    if type(lost) ~= "number" or type(least) ~= "number" then return nil end
    if least < lost then return math.max(lost, 1) end
end

ai_skill_invoke.MeowZhenlie = function(self)
    local use = use_of(self, "MeowZhenlie")
    if not use.from or use.from:isDead() then return false end
    local enemy = self:isEnemy(use.from)
    if enemy == nil then ai_unsupported("MeowZhenlie relation is unknown", "MeowZhenlie") end
    if not enemy then return false end
    local card = use.card
    if card:isKindOf("Slash") then
        local effective = self:slashIsEffective(card, self.player, use.from)
        if effective == false then return false end
        local damage = self:ajustDamage(use.from, self.player, 1, card)
        if type(damage) == "number" and damage > 1 then return true end
        local jinks = self:getCardsNum("Jink")
        local expected = self:getExpectedJinkNum(use)
        if jinks == nil then ai_unsupported("MeowZhenlie jink count is unknown", "MeowZhenlie") end
        if expected == nil or jinks < (expected or 1) or jinks == 0 then
            if card:isKindOf("NatureSlash") and self.player:isChained()
                and self:isGoodChainTarget(self.player, card, use.from) == false then
                return true
            end
            if self:doDisCard(use.from, "he") then return true end
        end
    elseif card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")
        or card:isKindOf("FireAttack") or card:isKindOf("AOE") then
        if self:doDisCard(use.from, "he") then return true end
    end
    return false
end

ai_skill_invoke.MeowMiji = function() return true end

ai_skill_playerchosen.MeowMiji = function(self, options)
    local names = type(options) == "table" and options.players or nil
    if type(names) ~= "table" or #names == 0 then
        ai_unsupported("MeowMiji candidates are missing", "MeowMiji")
    end
    local best, lost = nil, -1
    for _, name in ipairs(names) do
        local player = self.room:findPlayerByObjectName(name)
        local value = player and player:getLostHp()
        if type(value) ~= "number" then ai_unsupported("MeowMiji lost hp is unknown", "MeowMiji") end
        if value > lost then best, lost = name, value end
    end
    return best
end

ai_skill_use["@@MeowMiji"] = function() return {kind = "pass"} end

ai_skill_playerchosen.Meowdoumiao = function(self, options)
    relations(self, "Meowdoumiao")
    local names = type(options) == "table" and options.players or {}
    local function offered(player)
        if #names == 0 then return true end
        for _, name in ipairs(names) do
            if name == player:objectName() then return true end
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if offered(enemy) and not enemy:isNude() and (
            self:doDisCard(enemy, "h") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)
            or enemy:hasSkills("MeowZhenlie|Meowshangshi|MeowJueqing|MeowQingguo|MeowXiaoji|MeowJizhi|MeowDuanchang|MeowBeige")
        ) then
            return enemy:objectName()
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        if offered(friend) and (self:doDisCard(friend, "h")
            or friend:hasSkills("Meowxianzhou|MeowQiangwu|MeowLieren")) then
            return friend:objectName()
        end
    end
    return {kind = "pass"}
end

ai_skill_invoke.Meowdoumiao = function(self)
    local others = self.room:getOtherPlayers(self.player)
    if not others then ai_unsupported("Meowdoumiao players are unknown", "Meowdoumiao") end
    local names = {}
    for _, player in ipairs(others) do names[#names + 1] = player:objectName() end
    local chosen = ai_skill_playerchosen.Meowdoumiao(self, {players = names})
    return type(chosen) == "string"
end

ai_skill_invoke.MeowGuowu = function() return true end
sgs.ai_cardneed.MeowGuowu = sgs.ai_cardneed.slash
