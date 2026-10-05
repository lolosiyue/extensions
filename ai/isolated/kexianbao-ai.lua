-- 仙包隔離 AI。決策順序沿用 lua/ai/kexianbao-ai.lua。
-- 共用函式在 smart-ai-functions.lua；本檔只擴充技能名單與各技能 handler。
-- 快照沒有的旗標、拼點點數或忌雷回 unsupported，不把未知當成安全或敵人。

sgs.append_skill_list("wizard_skill", "kexianhuiyan")
sgs.append_skill_list("wizard_skill", "kejiexianhuiyan")
sgs.append_skill_list("wizard_harm_skill", "kejiexianhuiyan")
sgs.append_skill_list("double_slash_skill", "kexianfeijian")
sgs.append_skill_list("double_slash_skill", "kejiexianfeijian")

sgs.ai_cardneed = sgs.ai_cardneed or {}
sgs.ai_ajustdamage_from = sgs.ai_ajustdamage_from or {}
sgs.ai_use_value = sgs.ai_use_value or {}
sgs.ai_use_priority = sgs.ai_use_priority or {}
sgs.ai_card_intention = sgs.ai_card_intention or {}
sgs.ai_damage_reason_suppress_intention = sgs.ai_damage_reason_suppress_intention or {}
sgs.ai_suppress_intention = sgs.ai_suppress_intention or {}
sgs.ai_can_damagehp = sgs.ai_can_damagehp or {}
sgs.dynamic_value = sgs.dynamic_value or {}
sgs.dynamic_value.benefit = sgs.dynamic_value.benefit or {}

sgs.ai_damage_reason_suppress_intention.kexianhuoqi = true
sgs.ai_damage_reason_suppress_intention.kejiexianhuoqi = true
sgs.ai_suppress_intention.kejiexianaoce = true
sgs.ai_cardneed.kexianguiyi = sgs.ai_cardneed.bignumber
sgs.ai_cardneed.kejiexianjibian = sgs.ai_cardneed.slash
sgs.ai_use_value.kejiexianchanxinCard = 9
sgs.ai_use_priority.kejiexianchanxinCard = 2.61
sgs.dynamic_value.benefit.kejiexianchanxinCard = true
sgs.ai_use_value.kexianfenshenCard = 8.5
sgs.ai_use_priority.kexianfenshenCard = 9.5
sgs.ai_card_intention.kexianfenshenCard = -80
sgs.ai_use_value.kejiexianfenshenCard = 8.5
sgs.ai_use_priority.kejiexianfenshenCard = 9.5
sgs.ai_card_intention.kejiexianfenshenCard = -80
sgs.ai_use_value.kexianjishiCard = 8
sgs.ai_use_priority.kexianjishiCard = 9.5

local function known(value, key, reason)
    if value == nil then ai_unsupported(reason or (key .. " is unknown"), key) end
    return value
end

local function relation_friend(self, player, key)
    return known(self:isFriend(player), key, key .. " relation is unknown")
end

local function relation_enemy(self, player, key)
    return known(self:isEnemy(player), key, key .. " relation is unknown")
end

local function choice_items(options, key)
    local items = type(options) == "table" and options.choices or nil
    if type(items) ~= "table" or #items == 0 then
        ai_unsupported(key .. " choices are missing", key)
    end
    local offered = {}
    for _, item in ipairs(items) do offered[item] = true end
    return items, offered
end

local function offered_players(self, options, key)
    if type(options) ~= "table" or options.candidates_complete ~= true or not AIValue.isList(options.players) then
        ai_unsupported(key .. " requires complete candidates", key)
    end
    local list = AIList.new({})
    for _, name in ipairs(options.players) do
        local player = self.room:findPlayerByObjectName(name, true)
        if not player then ai_unsupported(key .. " candidate is missing", key) end
        list:append(player)
    end
    return list
end

local function decline_player(options)
    if options and options.optional then return {kind = "pass"} end
    return nil
end

local function skill_use(self, skill, cards, targets)
    local action = self:getSkillAction(skill)
    if not action or not action:isValid() then return nil end
    local answer = {kind = "use_card", skill_action = action:toAnswer(), cards = cards}
    if targets then answer.targets = targets end
    return answer
end

-- 出牌候選有忌雷旗標才排除。棄牌題通常已經濾過，沒有候選就當可棄。
local function not_jilei(self, card, key)
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate or type(candidate.isJilei) ~= "function" then return true end
    local banned = candidate:isJilei()
    if banned == nil then ai_unsupported(key .. " jilei state is unknown", key) end
    return not banned
end

-- 原版用新 table 比較 playerschosen 結果，空表也會選拼點。這裡保留那個結果：
-- 至少兩名能拼點就選 pindian，不再要求選出的目標非空。
local function huoqi_choice(self, key)
    if known(self:isWeak(), key) then return "recover" end
    local players = self.room:getAlivePlayers()
    if not players then ai_unsupported(key .. " roster is unknown", key) end
    local ready = 0
    for _, player in ipairs(players) do
        local can = self:canPindian(player)
        if can == nil then ai_unsupported(key .. " pindian legality is unknown", key) end
        if can then ready = ready + 1 end
    end
    if ready >= 2 then return "pindian" end
    return "cancel"
end

local function huoqi_targets(self, options, key)
    local players = offered_players(self, options, key)
    local ordered = known(self:sort(players, "hp"), key, key .. " hp order is unknown")
    local names = {}
    local function take(want_friend)
        for _, left in ipairs(ordered) do
            for _, right in ipairs(ordered) do
                if #names >= 2 then return end
                local right_is_friend = want_friend and relation_friend(self, right, key)
                local right_is_enemy = not want_friend and relation_enemy(self, right, key)
                if left:objectName() ~= right:objectName() and relation_enemy(self, left, key)
                    and (right_is_friend or right_is_enemy) then
                    local can = self:canPindian(left, right)
                    if can == nil then ai_unsupported(key .. " pindian pair is unknown", key) end
                    local seen = false
                    for _, name in ipairs(names) do if name == right:objectName() then seen = true end end
                    if can and not seen then names[#names + 1] = right:objectName() end
                end
            end
        end
    end
    take(false)
    -- 界火氣：兩個敵人都湊不齊時，保留已選的敵人，再補一名友方。
    if key == "kejiexianhuoqi" and #names < 2 then take(true) end
    if #names < 2 then return {kind = "pass"} end
    return names
end

ai_skill_invoke.xianchangetupo = function()
    return false
end

ai_skill_choice.kexianhuoqi = function(self, options)
    local _, offered = choice_items(options, "kexianhuoqi")
    local choice = huoqi_choice(self, "kexianhuoqi")
    if offered[choice] then return choice end
    ai_unsupported("kexianhuoqi choice was not offered", "kexianhuoqi")
end

ai_skill_invoke.kexianhuoqi = function(self, options)
    return ai_skill_choice.kexianhuoqi(self, options) ~= "cancel"
end

ai_skill_playerschosen.kexianhuoqi = function(self, options)
    return huoqi_targets(self, options, "kexianhuoqi")
end

-- 獲勝者旗標只投影給旗標持有者。棄牌的人通常不是獲勝者，看不到就不假設傷害無效。
ai_skill_discard.kexianhuoqi = function(self, options)
    local key = "kexianhuoqi"
    if type(options) ~= "table" or options.candidates_complete ~= true or not AIValue.isList(options.card_ids) then
        ai_unsupported(key .. " discard candidates are incomplete", key)
    end
    local winner = self.player:hasFlag("kexianhuoqi_winner")
    if winner == nil then ai_unsupported(key .. " winner flag is unknown", key) end
    if winner then
        local effective = self:damageIsEffective(self.player, sgs.DamageStruct_Normal, self.player)
        local lose = self:needToLoseHp(self.player, self.player)
        if effective == nil or lose == nil then ai_unsupported(key .. " damage desire is unknown", key) end
        if not effective or lose then return {kind = "pass"} end
    end
    local hand = self.player:getHandcards()
    if not hand then ai_unsupported(key .. " hand is unknown", key) end
    local peaches, offered = 0, {}
    for _, id in ipairs(options.card_ids) do offered[id] = true end
    for _, card in ipairs(hand) do
        if isCard("Peach", card, self.player) then peaches = peaches + 1 end
    end
    local overflow = known(self:getOverflow(), key)
    if peaches >= 2 and overflow <= 0 then return {kind = "pass"} end
    local sorted = known(self:sortByKeepValue(hand), key, key .. " keep order is unknown")
    local ids = {}
    for _, card in ipairs(sorted) do
        if #ids >= 2 then break end
        local id = card:getEffectiveId()
        if offered[id] and not isCard("Peach", card, self.player) and not_jilei(self, card, key) then
            ids[#ids + 1] = id
        end
    end
    if #ids < 2 then return {kind = "pass"} end
    return ids
end

local function pindian_numbers(self, key)
    local context = self:getDecisionContext()
    local pindian = type(context) == "table" and context.pindian or nil
    if type(pindian) ~= "table" then
        ai_unsupported(key .. " pindian is not projected", key)
    end
    local from, to = pindian.from, pindian.to
    if type(from) == "string" then from = self.room:findPlayerByObjectName(from, true) end
    if type(to) == "string" then to = self.room:findPlayerByObjectName(to, true) end
    if not from or not to or type(pindian.from_number) ~= "number" or type(pindian.to_number) ~= "number" then
        ai_unsupported(key .. " pindian cards are not projected", key)
    end
    return from, to, pindian.from_number, pindian.to_number
end

local function tianbian_answer(self, key, card_ok)
    local from, to, from_number, to_number = pindian_numbers(self, key)
    local hand = self.player:getHandcards()
    if not hand then ai_unsupported(key .. " hand is unknown", key) end
    local sorted = known(self:sortByKeepValue(hand), key, key .. " keep order is unknown")
    local function pick(predicate, target)
        for _, card in ipairs(sorted) do
            local number = card:getNumber()
            if type(number) ~= "number" then ai_unsupported(key .. " card number is unknown", key) end
            if not isCard("Peach", card, self.player) and predicate(number) then
                return {kind = "use_card", cards = {card:getEffectiveId()}, targets = {target:objectName()}}
            end
        end
    end
    local friend_to = relation_friend(self, to, key) and relation_enemy(self, from, key)
    local friend_from = relation_friend(self, from, key) and relation_enemy(self, to, key)
    if friend_to and to_number < from_number then
        return pick(function(number) return number >= from_number end, to)
            or pick(function(number) return number < to_number end, from)
            or {kind = "pass"}
    end
    if friend_from and to_number >= from_number then
        return pick(function(number) return number > to_number end, from)
            or pick(function(number) return number < from_number end, to)
            or {kind = "pass"}
    end
    if card_ok and card_ok(from, to, from_number, to_number) then
        if to_number >= from_number then
            return pick(function(number) return number > to_number end, from)
                or pick(function(number) return number < from_number end, to)
                or {kind = "pass"}
        end
        return pick(function(number) return number >= from_number end, to)
            or pick(function(number) return number < to_number end, from)
            or {kind = "pass"}
    end
    return {kind = "pass"}
end

ai_skill_use["@kexiantianbian"] = function(self)
    return tianbian_answer(self, "kexiantianbian")
end

ai_skill_invoke.kexianyuli = function()
    return true
end

ai_skill_choice.kejiexianhuoqi = function(self, options)
    local _, offered = choice_items(options, "kejiexianhuoqi")
    local choice = huoqi_choice(self, "kejiexianhuoqi")
    if offered[choice] then return choice end
    ai_unsupported("kejiexianhuoqi choice was not offered", "kejiexianhuoqi")
end

ai_skill_invoke.kejiexianhuoqi = function(self, options)
    return ai_skill_choice.kejiexianhuoqi(self, options) ~= "cancel"
end

ai_skill_playerschosen.kejiexianhuoqi = function(self, options)
    return huoqi_targets(self, options, "kejiexianhuoqi")
end

ai_skill_choice.jienhlxloser = function(self, options)
    local _, offered = choice_items(options, "jienhlxloser")
    local context = self:getDecisionContext()
    local pindian = type(context) == "table" and context.pindian or nil
    if type(pindian) ~= "table" or not pindian.to or not pindian.from then
        ai_unsupported("jienhlxloser pindian is not projected", "jienhlxloser")
    end
    local target = pindian.to
    if type(target) == "string" then target = self.room:findPlayerByObjectName(target, true) end
    local source = pindian.from
    if type(source) == "string" then source = self.room:findPlayerByObjectName(source, true) end
    if not target or not source then ai_unsupported("jienhlxloser players are missing", "jienhlxloser") end
    local friend = relation_friend(self, target, "jienhlxloser")
    local enemy = relation_enemy(self, target, "jienhlxloser")
    local lose = known(self:needToLoseHp(target, source, nil), "jienhlxloser")
    local choice
    if friend and lose then choice = "damage"
    elseif enemy and not lose then choice = "damage"
    else choice = "qipai" end
    if offered[choice] then return choice end
    ai_unsupported("jienhlxloser choice was not offered", "jienhlxloser")
end

ai_skill_use["@kejiexiantianbian"] = function(self)
    return tianbian_answer(self, "kejiexiantianbian", function()
        return math.random() < 0.5
    end)
end

ai_skill_activate.kexianchanxin = function(self)
    local key = "kexianchanxin"
    local hand = self.player:getHandcards()
    if not hand then ai_unsupported(key .. " hand is unknown", key) end
    local slashes = AIList.new({})
    for _, card in ipairs(hand) do
        if card:isKindOf("Slash") then slashes:append(card) end
    end
    if #slashes == 0 then return nil end
    local sorted = known(self:sortByKeepValue(slashes), key, key .. " keep order is unknown")
    for _, card in ipairs(sorted) do
        local _, status = self:tryUseCard(card)
        if status == "unsupported" then ai_unsupported(key .. " slash plan is unknown", key) end
        -- 這張殺本身打得出去就留著；打不出去才拿來付禪心。
        if status ~= "planned" then
            return skill_use(self, key, {card:getEffectiveId()})
        end
    end
    return nil
end

sgs.ai_cardneed.kexianchanxin = function(to, _, self)
    if not self or self.player:objectName() ~= to:objectName() then return false end
    local action = self:getSkillAction("kexianchanxin")
    return action ~= nil and action:isValid()
end

ai_skill_invoke.xianhuiyanfadong = function()
    return true
end

local function retrial_or_best(self, options, key, tag_name)
    if type(options) ~= "table" or options.candidates_complete ~= true or not AIValue.isList(options.card_ids) then
        ai_unsupported(key .. " cards are incomplete", key)
    end
    local cards = AIList.new({})
    for _, id in ipairs(options.card_ids) do
        local card = self:getChoiceCard(id, options)
        if not card then ai_unsupported(key .. " card metadata is missing", key) end
        cards:append(card)
    end
    local context = self:getDecisionContext()
    local judge = type(context) == "table" and context.judge or nil
    if type(judge) == "table" then
        local id = self:getRetrialCardId(cards, judge)
        if type(id) == "number" and id >= 0 then return id end
    elseif tag_name then
        ai_unsupported(key .. " judge is not projected", key)
    end
    local sorted = known(self:sortByUseValue(cards, true), key, key .. " use order is unknown")
    return sorted[1]:getEffectiveId()
end

ai_skill_askforag.kexianhuiyan = function(self, options)
    return retrial_or_best(self, options, "kexianhuiyan", true)
end

ai_skill_invoke.kejiexianhuiyan = function()
    return true
end

ai_skill_askforag.kejiexianhuiyan = function(self, options)
    return retrial_or_best(self, options, "kejiexianhuiyan", true)
end

local function guiyi_target(self, options, key)
    local targets = offered_players(self, options, key)
    local max_card = self:getMaxCard()
    if not max_card then return decline_player(options) end
    local point = max_card:getNumber()
    if type(point) ~= "number" then ai_unsupported(key .. " point is unknown", key) end
    if self.player:hasSkill("tianbian") and max_card:getSuit() == sgs.Card_Heart then point = 13 end
    local ordered = known(self:sort(targets, "handcard"), key, key .. " hand order is unknown")
    if point >= 7 then
        for _, player in ipairs(ordered) do
            if relation_enemy(self, player, key) then
                local can = self:canPindian(self.player, player)
                if can == nil then ai_unsupported(key .. " pindian legality is unknown", key) end
                if can then
                    local theirs = self:getMaxCard(player)
                    if theirs then
                        local number = theirs:getNumber()
                        if type(number) ~= "number" then ai_unsupported(key .. " enemy point is unknown", key) end
                        if player:hasSkill("tianbian") and theirs:getSuit() == sgs.Card_Heart then number = 13 end
                        if number < point then return player:objectName() end
                    end
                end
            end
        end
    end
    if point >= 10 then
        for _, player in ipairs(ordered) do
            if relation_enemy(self, player, key) and known(self:canPindian(self.player, player), key) then
                return player:objectName()
            end
        end
    end
    return decline_player(options)
end

ai_skill_playerchosen.kexianguiyi = function(self, options)
    return guiyi_target(self, options, "kexianguiyi")
end

ai_skill_invoke.kexianguiyi = function(self, options)
    local names = type(options) == "table" and options.players or nil
    if type(names) ~= "table" then
        local others = self.room:getOtherPlayers(self.player)
        if not others then ai_unsupported("kexianguiyi roster is unknown", "kexianguiyi") end
        names = {}
        for _, player in ipairs(others) do
            local can = self:canPindian(self.player, player)
            if can == nil then ai_unsupported("kexianguiyi pindian legality is unknown", "kexianguiyi") end
            if can then names[#names + 1] = player:objectName() end
        end
    end
    local picked = guiyi_target(self, {players = names, candidates_complete = true, optional = true}, "kexianguiyi")
    return type(picked) == "string"
end

ai_skill_activate.kejiexianchanxin = function(self)
    local key = "kejiexianchanxin"
    local cards = self.player:getCards("he")
    if not cards then ai_unsupported(key .. " cards are unknown", key) end
    local hp = known(self.player:getHp(), key)
    local picked = {}
    local function consider(card)
        if not (card:isDamageCard() or card:isKindOf("Weapon")) then return end
        if not not_jilei(self, card, key) then return end
        local _, status = self:tryUseCard(card)
        if status == "unsupported" then ai_unsupported(key .. " card plan is unknown", key) end
        if status ~= "planned" then picked[#picked + 1] = card:getEffectiveId() end
    end
    if hp < 3 then
        for _, card in ipairs(cards) do consider(card) end
    end
    if #picked == 0 then
        local hand = known(self:sortByKeepValue(self.player:getHandcards() or cards), key)
        local slash_used = false
        for _, card in ipairs(hand) do
            if card:isKindOf("Slash") then
                local _, status = self:tryUseCard(card)
                if status == "unsupported" then ai_unsupported(key .. " slash plan is unknown", key) end
                if status == "planned" and not slash_used then slash_used = true
                elseif not_jilei(self, card, key) then picked[#picked + 1] = card:getEffectiveId() end
            elseif card:isKindOf("Weapon") and known(self.player:getHandcardNum(), key) < 3 then
                if not_jilei(self, card, key) then picked[#picked + 1] = card:getEffectiveId() end
            elseif card:getTypeId() == sgs.Card_TypeTrick and card:isDamageCard() then
                consider(card)
            end
        end
    end
    if #picked == 0 then return nil end
    return skill_use(self, key, picked)
end

sgs.ai_cardneed.kejiexianchanxin = function(_, card)
    return card:isKindOf("Weapon") or card:isDamageCard()
end

local function discard_enemy(self, key, flags)
    if not self.enemies then ai_unsupported(key .. " enemies are unknown", key) end
    local ordered = known(self:sort(self.enemies, "defense"), key, key .. " defense order is unknown")
    for _, enemy in ipairs(ordered) do
        local nude = enemy:isNude()
        if nude == nil then ai_unsupported(key .. " nude state is unknown", key) end
        if not nude then
            local discard = self:doDisCard(enemy, flags or "he")
            if discard == nil then ai_unsupported(key .. " discard value is unknown", key) end
            local dangerous = self:getDangerousCard(enemy)
            local valuable = self:getValuableCard(enemy)
            if discard or dangerous or valuable then return enemy:objectName() end
        end
    end
    return nil
end

ai_skill_playerchosen.kejiexianchanxinCard = function(self, options)
    return discard_enemy(self, "kejiexianchanxin") or decline_player(options)
end

ai_skill_invoke.kejiexianguiyi = function(self)
    local target = self:getDecisionContext().player
    if not target then ai_unsupported("kejiexianguiyi target is not projected", "kejiexianguiyi") end
    if relation_friend(self, target, "kejiexianguiyi") then return false end
    return true
end

ai_skill_choice.kejiexianguiyi = function(self, options)
    local _, offered = choice_items(options, "kejiexianguiyi")
    local target = self:getDecisionContext().player
    if not target then ai_unsupported("kejiexianguiyi target is not projected", "kejiexianguiyi") end
    if relation_friend(self, target, "kejiexianguiyi") then
        if offered.have then return "have" end
        ai_unsupported("kejiexianguiyi have was not offered", "kejiexianguiyi")
    end
    local cards = target:getKnownCards()
    if not cards then ai_unsupported("kejiexianguiyi known cards are missing", "kejiexianguiyi") end
    for _, card in ipairs(cards) do
        if card:isDamageCard() and offered.have then return "have" end
    end
    if offered.nothave then return "nothave" end
    ai_unsupported("kejiexianguiyi nothave was not offered", "kejiexianguiyi")
end

ai_skill_invoke.kexianlunhui = function()
    return true
end

local function fenshen_activate(self, key, mark, limit_mark, limit)
    if known(self.player:getMark(mark), key) <= 0 then return nil end
    if limit_mark and known(self.player:getMark(limit_mark), key) >= limit then return nil end
    local hand = self.player:getHandcards()
    if not hand or #hand == 0 then return nil end
    local sorted = known(self:sortByKeepValue(hand), key, key .. " keep order is unknown")
    for _, card in ipairs(sorted) do
        if not_jilei(self, card, key) then
            return skill_use(self, key, {card:getEffectiveId()})
        end
    end
    return nil
end

ai_skill_activate.kexianfenshen = function(self)
    return fenshen_activate(self, "kexianfenshen", "&xianzuociji")
end

sgs.ai_cardneed.kexianfenshen = function()
    return true
end

ai_skill_invoke.kejiexianlunhui = function()
    return true
end

ai_skill_activate.kejiexianfenshen = function(self)
    return fenshen_activate(self, "kejiexianfenshen", "&jiexianzuociji", "&kexianfenshen", 3)
end

sgs.ai_cardneed.kejiexianfenshen = function(to, _, self)
    if not self then return nil end
    if known(self.player:getMark("&kexianfenshen"), "kejiexianfenshen") >= 3 then return false end
    if known(self.player:getMark("&jiexianzuociji"), "kejiexianfenshen") <= 0 then return false end
    return true
end

ai_skill_invoke.kejiexianfeijian = function()
    return true
end

ai_skill_playerchosen.kejiexianfeijian = function(self, options)
    local targets = offered_players(self, options, "kejiexianfeijian")
    local target = self:zeroCardSlashTarget(targets)
    if target == nil then ai_unsupported("kejiexianfeijian slash target is unknown", "kejiexianfeijian") end
    if target then return target:objectName() end
    return decline_player(options)
end

local function mabi_invoke(self, key, marks)
    local damage = self:getDecisionContext().damage
    local target = type(damage) == "table" and damage.to or nil
    if not target or type(damage.damage) ~= "number" then
        ai_unsupported(key .. " damage is not projected", key)
    end
    for _, mark in ipairs(marks) do
        if known(target:getMark(mark), key) > 0 then return false end
    end
    if relation_friend(self, target, key) then
        local lose = known(self:needToLoseHp(target, self.player, damage.card), key)
        if lose then return false end
        local chained = target:isChained()
        if chained == nil then ai_unsupported(key .. " chain state is unknown", key) end
        if chained and known(self:isGoodChainTarget(target, damage.card), key) then return false end
        if known(self:isWeak(target), key) or damage.damage > 1 then return true end
        local lost = target:getLostHp()
        if type(lost) ~= "number" then ai_unsupported(key .. " lost hp is unknown", key) end
        return lost >= 1
    end
    if known(self:isWeak(target), key) then return false end
    local adjusted = known(self:ajustDamage(self.player, target, 1, damage.card), key)
    if damage.damage > 1 or adjusted > 1 then return false end
    if target:hasSkill("lirang") then
        local friends = self:getFriends(target, true)
        if not friends then ai_unsupported(key .. " friends are unknown", key) end
        if #friends > 0 then return false end
    end
    local armor = target:getArmor()
    if armor then
        local value = known(self:evaluateArmor(armor, target), key)
        local lion = target:hasArmorEffect("silver_lion")
        local wounded = target:isWounded()
        if lion == nil or wounded == nil then ai_unsupported(key .. " armor state is unknown", key) end
        if value > 3 and not (lion and wounded) then return true end
    end
    if self.player:hasSkill("tieji") or known(self:canLiegong(target, self.player), key) then return false end
    local count = target:getCardCount()
    if type(count) ~= "number" then ai_unsupported(key .. " card count is unknown", key) end
    return count < 4 and count > 1
end

ai_skill_invoke.kexianmabi = function(self)
    return mabi_invoke(self, "kexianmabi", {"&kexianmabimopai"})
end

ai_skill_invoke.kexianxiuzhen = function(self)
    local damage = self:getDecisionContext().damage
    local target = type(damage) == "table" and damage.from or nil
    if target and relation_friend(self, target, "kexianxiuzhen") and known(self:isWeak(target), "kexianxiuzhen") then
        return false
    end
    return true
end

local function damage_hp_hook(self, from, card, to, enemy_only)
    if not from or not to then return nil end
    local hp = to:getHp()
    local rescue = self:getAllPeachNum()
    local damage = self:ajustDamage(from, to, 1, card)
    local lose = self:canLoseHp(from, card, to)
    if type(hp) ~= "number" or type(rescue) ~= "number" or type(damage) ~= "number" or lose == nil then
        return nil
    end
    if hp + rescue - damage > 0 and lose then
        if enemy_only then return self:isEnemy(from) end
        return true
    end
    return false
end

sgs.ai_can_damagehp.kexianxiuzhen = function(self, from, card, to)
    return damage_hp_hook(self, from, card, to, true)
end

ai_skill_invoke.kejiexianmabi = function(self)
    return mabi_invoke(self, "kejiexianmabi", {"&kejiexianmabimp", "&kejiexianmabicp"})
end

ai_skill_invoke.kejiexianxiuzhenpd = function()
    return true
end

ai_skill_playerchosen.kejiexianxiuzhen = function(self, options)
    local key = "kejiexianxiuzhen"
    known(self:updatePlayers(), key, key .. " relations are unknown")
    local enemies = self:getEnemies(self.player)
    if not enemies then ai_unsupported(key .. " enemies are unknown", key) end
    local offered = {}
    for _, name in ipairs(offered_players(self, options, key) and options.players or {}) do
        offered[name] = true
    end
    local function score(enemy)
        if not offered[enemy:objectName()] then return nil end
        local effective = known(self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player), key)
        if not effective then return 99 end
        local hurt = known(self:cantbeHurt(enemy, self.player, 1), key)
        local objective = known(self:objectiveLevel(enemy), key)
        local chained = enemy:isChained()
        if chained == nil then ai_unsupported(key .. " chain state is unknown", key) end
        local good = false
        if chained then
            good = self:isGoodChainTarget(enemy, sgs.DamageStruct_Thunder, self.player, 1)
            if good == nil then ai_unsupported(key .. " chain value is unknown", key) end
        end
        if hurt or objective < 3 or (chained and not good) then return 100 end
        local value = 0
        if enemy:hasSkills(sgs.exclusive_skill) then value = value + 10 end
        if enemy:hasSkills(sgs.masochism_skill) then value = value + 5 end
        local chain_enemies = self:getChainedEnemies(self.player)
        if not chain_enemies then ai_unsupported(key .. " chained enemies are unknown", key) end
        if chained and good and #chain_enemies > 1 then value = value - 25 end
        if enemy:isLord() then value = value - 5 end
        local hp = known(enemy:getHp(), key)
        local defense = known(self:getDefenseSlash(enemy), key)
        return value + hp + defense * 0.01
    end
    local best, best_value
    for _, enemy in ipairs(enemies) do
        local value = score(enemy)
        if type(value) == "number" and value > 0 and (not best or value < best_value) then
            best, best_value = enemy, value
        end
    end
    if best then return best:objectName() end
    return decline_player(options)
end

ai_skill_playerchosen.kejiexianxiuzhendis = function(self, options)
    return discard_enemy(self, "kejiexianxiuzhendis") or decline_player(options)
end

sgs.ai_can_damagehp.kejiexianxiuzhen = function(self, from, card, to)
    return damage_hp_hook(self, from, card, to, false)
end

ai_skill_choice.kejiexianxiuzhen = function(self, options)
    local items = choice_items(options, "kejiexianxiuzhen")
    local lord = self.room:getLord()
    if lord then
        local friend = known(self:isFriend(lord), "kejiexianxiuzhen")
        if friend then
            local kingdom = lord:getKingdom()
            for _, item in ipairs(items) do
                if item == kingdom then return item end
            end
        end
    end
    return items[math.random(1, #items)]
end

local function give_or_throw(self, options, key)
    local enemy = discard_enemy(self, key)
    if enemy then return enemy end
    if not self.friends_noself then ai_unsupported(key .. " friends are unknown", key) end
    for _, friend in ipairs(self.friends_noself) do
        local equips = friend:getEquips()
        if not equips then ai_unsupported(key .. " equips are unknown", key) end
        local lose = type(sgs.lose_equip_skill) == "string" and friend:hasSkills(sgs.lose_equip_skill) or false
        local armor = self:needToThrowArmor(friend)
        local discard = self:doDisCard(friend, "he")
        if armor == nil or discard == nil then ai_unsupported(key .. " friend discard is unknown", key) end
        if (lose and #equips > 0) or (armor and friend:getArmor()) or discard then
            return friend:objectName()
        end
    end
    return decline_player(options)
end

ai_skill_playerchosen.kexianhanyan = function(self, options)
    return give_or_throw(self, options, "kexianhanyan")
end

ai_skill_invoke.kexianxiaocai = function()
    return true
end

ai_skill_playerchosen.kejiexianliwei = function(self, options)
    return give_or_throw(self, options, "kejiexianliwei")
end

ai_skill_cardchosen.kejiexianliwei = function(self, options)
    local key = "kejiexianliwei"
    if type(options) ~= "table" or not AIValue.isList(options.card_ids) or #options.card_ids == 0 then
        ai_unsupported(key .. " cards are missing", key)
    end
    local who_name = type(options.context) == "table" and (options.context.who or options.context.target) or nil
    local who = who_name and self.room:findPlayerByObjectName(who_name, true) or nil
    if not who then return options.card_ids[1] end
    local equips = who:getEquips() or {}
    if #equips > 0 then return equips[1]:getEffectiveId() end
    local known_cards = who:getKnownCards() or {}
    if #known_cards > 0 then return known_cards[1]:getEffectiveId() end
    return options.card_ids[1]
end

ai_skill_invoke.kejiexianaoce = function(self)
    local key = "kejiexianaoce"
    local use = self:getDecisionContext().use
    local target = type(use) == "table" and use.from or nil
    if not target then return false end
    if relation_friend(self, target, key) then return false end
    local hp = known(self.player:getHp(), key)
    local hit = known(self:canHit(self.player, target), key)
    local sword = target:hasWeapon("double_sword")
    if sword == nil then ai_unsupported(key .. " weapon is unknown", key) end
    local gender_diff = self.player:getGender() ~= target:getGender()
    if hp > 1 and not hit and not (sword and gender_diff) then return true end
    local slashes = known(self:getCardsNum("Slash", target), key)
    local leiji = known(self:needLeiji(self.player, target), key)
    local lose = known(self:needToLoseHp(self.player, target, nil), key)
    if slashes < 1 or leiji or lose then return true end
    local overflow = known(self:getOverflow(), key)
    local jinks = known(self:getCardsNum("Jink"), key)
    if overflow and jinks > 1 then return true end
    local hand = self.player:getHandcards()
    if not hand then ai_unsupported(key .. " hand is unknown", key) end
    for _, card in ipairs(hand) do
        if card:isKindOf("Jink") then return true end
    end
    return false
end

ai_skill_invoke.kexianbenxi = function(self)
    local key = "kexianbenxi"
    local skipped = self.player:isSkipped(sgs.Player_Play)
    if skipped == nil then ai_unsupported(key .. " skip state is unknown", key) end
    if skipped or known(self:needBear(), key) then return false end
    if not self.enemies then ai_unsupported(key .. " enemies are unknown", key) end
    local enemies = known(self:sort(self.enemies, "hp"), key, key .. " enemy order is unknown")
    local hand = self.player:getHandcards()
    if not hand then ai_unsupported(key .. " hand is unknown", key) end
    for _, card in ipairs(hand) do
        if card:isKindOf("Slash") then
            for _, enemy in ipairs(enemies) do
                local reach = known(self:canSlash(self.player, enemy, card, true), key)
                local effective = known(self:slashIsEffective(card, enemy), key)
                local objective = known(self:objectiveLevel(enemy), key)
                local good = known(self:isGoodTarget(enemy, enemies, card), key)
                if reach and effective and objective > 3 and good then
                    local jinks = known(self:getCardsNum("Jink", enemy), key)
                    local axe = self.player:hasWeapon("axe")
                    local count = self.player:getCardCount()
                    if axe == nil or type(count) ~= "number" then
                        ai_unsupported(key .. " axe state is unknown", key)
                    end
                    if jinks < 1 or (axe and count > 4) then return true end
                end
            end
        end
    end
    return false
end

ai_skill_playerchosen.kexianbenxi = function(self, options)
    local key = "kexianbenxi"
    if not self.enemies then ai_unsupported(key .. " enemies are unknown", key) end
    local enemies = known(self:sort(self.enemies, "handcard"), key)
    local names = {}
    for _, name in ipairs((offered_players(self, options, key) and options.players) or {}) do names[name] = true end
    for index = #enemies, 1, -1 do
        local enemy = enemies[index]
        local empty = enemy:isKongcheng()
        if empty == nil then ai_unsupported(key .. " hand emptiness is unknown", key) end
        if names[enemy:objectName()] and not empty and known(self:objectiveLevel(enemy), key) > 0 then
            return enemy:objectName()
        end
    end
    return decline_player(options)
end

sgs.ai_ajustdamage_from.kexianbenxi = function(_, from, _, card)
    local mark = from:getMark("&kexianbenxi-PlayClear")
    if type(mark) ~= "number" then return nil end
    if mark > 0 and card and card:isKindOf("Slash") then return 1 end
    return 0
end

sgs.ai_cardneed.kexianbenxi = function(to, card, self)
    if not self or not self.enemies then return nil end
    local enemies = self:sort(self.enemies, "defenseSlash")
    if not enemies then return nil end
    local need_slash = true
    local hand = to:getKnownCards()
    if to:objectName() == self.player:objectName() then hand = to:getHandcards() end
    if not hand then return nil end
    for _, owned in ipairs(hand) do
        if isCard("Slash", owned, to) then need_slash = false break end
    end
    if not need_slash or not isCard("Slash", card, to) then return false end
    for _, enemy in ipairs(enemies) do
        local reach = to:distanceTo(enemy)
        local range = to:getAttackRange()
        if type(reach) ~= "number" or type(range) ~= "number" then return nil end
        if reach <= range and not self:slashProhibit(nil, enemy, to)
            and self:slashIsEffective(nil, enemy, to) and (self:getDefenseSlash(enemy) or 99) <= 2 then
            return true
        end
    end
    return false
end

ai_skill_invoke.kejiexianjibian = function()
    return true
end

ai_skill_playerchosen.kejiexianjibian = function(self, options)
    local key = "kejiexianjibian"
    if not self.enemies then ai_unsupported(key .. " enemies are unknown", key) end
    local names = {}
    for _, name in ipairs(options and options.players or {}) do names[name] = true end
    for _, enemy in ipairs(self.enemies) do
        if names[enemy:objectName()] then
            local can = self.player:canDiscard(enemy, "h")
            if can == nil then ai_unsupported(key .. " discard legality is unknown", key) end
            if can then
                local discard = self:doDisCard(enemy, "h")
                if discard == nil then ai_unsupported(key .. " discard value is unknown", key) end
                if discard or self:getDangerousCard(enemy) or self:getValuableCard(enemy) then
                    return enemy:objectName()
                end
            end
        end
    end
    return decline_player(options)
end

ai_skill_choice.kejiexianjibian = function(self, options)
    local items, offered = choice_items(options, "kejiexianjibian")
    if offered.benxione then return "benxione" end
    if offered.benxitwo then
        local others = self.room:getOtherPlayers(self.player)
        if not others then ai_unsupported("kejiexianjibian roster is unknown", "kejiexianjibian") end
        local names = {}
        for _, player in ipairs(others) do names[#names + 1] = player:objectName() end
        local target = ai_skill_playerchosen.kejiexianjibian(self, {players = names, candidates_complete = true})
        if type(target) == "string" then return "benxitwo" end
    end
    if offered.benxithree and ai_skill_invoke.kexianbenxi(self) then return "benxithree" end
    return items[1]
end

sgs.ai_ajustdamage_from.kejiexianjibian = function(_, from, _, card)
    local mark = from:getMark("&kejiexianjibianda-PlayClear")
    if type(mark) ~= "number" then return nil end
    if mark > 0 and card and card:isKindOf("Slash") then return 1 end
    return 0
end

ai_skill_invoke.kexianwuqin = function()
    return true
end

ai_skill_activate.kexianjishi = function(self)
    local key = "kexianjishi"
    if known(self.player:getMark("@xianjishi"), key) == 0 then return nil end
    if known(self.player:getHandcardNum(), key) < 4 then return nil end
    local players = self.room:getAllPlayers(true)
    if not players then ai_unsupported(key .. " roster is unknown", key) end
    local role = self.player:getRole()
    local found = false
    for _, player in ipairs(players) do
        local dead = player:isDead()
        if dead == nil then ai_unsupported(key .. " death state is unknown", key) end
        if dead and (player:getRole() == role or (player:getRole() == "loyalist" and self.player:isLord())) then
            found = true
            break
        end
    end
    if not found then return nil end
    local hand = known(self:sortByUseValue(self.player:getHandcards(), true), key)
    local need, seen = {}, {}
    for _, card in ipairs(hand) do
        local suit = card:getSuit()
        if type(suit) == "number" and not seen[suit] then
            seen[suit] = true
            need[#need + 1] = card:getEffectiveId()
        end
    end
    if #need < 4 then return nil end
    return skill_use(self, key, {need[1], need[2], need[3], need[4]})
end
