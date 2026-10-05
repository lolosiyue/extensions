-- SmartAI 相等的純值工具函式。套件只註冊 hook／技能名單，不改這層。
-- 缺投影回 nil（未知），不把未知當成 0、安全或敵人。不造牌、不呼叫 Engine。

sgs.bad_skills = sgs.bad_skills or "benghuai|wumou|shiyong|yaowu|zaoyao|chanyuan|chouhai|tenyearchouhai|lianhuo|ranshang"
sgs.ai_slash_benefit = sgs.ai_slash_benefit or {}
sgs.ai_valuable_card = sgs.ai_valuable_card or {}
sgs.ai_will_skip_play = sgs.ai_will_skip_play or {}
sgs.ai_turn_over = sgs.ai_turn_over or {}

-- 套件用這個接上 drawpeach／hit／dont_kongcheng 這類「|」名單，避免 nil 拼接。
function sgs.append_skill_list(name, token)
    if type(name) ~= "string" or name == "" or type(token) ~= "string" or token == "" then
        error("append_skill_list needs a list name and a skill token")
    end
    local current = sgs[name]
    if type(current) ~= "string" or current == "" then
        sgs[name] = token
        return
    end
    local padded = "|" .. current .. "|"
    if not string.find(padded, "|" .. token .. "|", 1, true) then
        sgs[name] = current .. "|" .. token
    end
end

local function same_player(left, right)
    return left and right and left:objectName() == right:objectName()
end

local function skill_named(player, names)
    local has = player:hasSkills(names)
    if has == nil then return nil end
    return has == true
end

local function card_count(self, class_name, player)
    local count = self:getCardsNum(class_name, player)
    if type(count) ~= "number" then return nil end
    return count
end

-- 自己的手牌一律可見；其他人只信已知手牌或明確可見旗標。旗標沒投影不是「看不見」。
function SmartAIView:cardVisibleTo(player, card)
    player = player or self.player
    if not player or not card then return nil end
    if same_player(player, self.player) then return true end
    local hand = player:isHandVisible()
    if hand == true then return true end
    local visible = card:hasFlag("visible")
    if visible == nil then return nil end
    if visible then return true end
    local named = card:hasFlag("visible_" .. self.player:objectName() .. "_" .. player:objectName())
    if named == nil then return nil end
    return named == true
end

function SmartAIView:getKnownNum(player)
    player = player or self.player
    if not player then return nil end
    if same_player(player, self.player) then
        local hand, pile = player:getHandcards(), player:getHandPileCards()
        if not hand or not pile then return nil end
        return #hand + #pile
    end
    local known = player:getKnownCards()
    if not known then return nil end
    return #known
end

function SmartAIView:getCards(class_name, flags)
    if type(class_name) ~= "string" or class_name == "" then return {} end
    if string.find(class_name, ",", 1, true) then
        local merged = {}
        for piece in string.gmatch(class_name, "[^,]+") do
            local part = self:getCards(piece, flags)
            if not part then return nil end
            for _, card in ipairs(part) do merged[#merged + 1] = card end
        end
        return merged
    end
    local zone = type(flags) == "string" and flags or "he"
    local cards = self.player:getCards(zone)
    if not cards then return nil end
    local result = {}
    local function take(card)
        if class_name == "." or card:isKindOf(class_name) then result[#result + 1] = card end
    end
    for _, card in ipairs(cards) do take(card) end
    -- 未指定區域時連手牌堆一起看，順序跟 addHandPile 一樣：先區域牌，再牌堆。
    if type(flags) ~= "string" then
        local pile = self.player:getHandPileCards()
        if not pile then return nil end
        for _, card in ipairs(pile) do take(card) end
    end
    return result
end

function SmartAIView:getCard(class_name, islist)
    local cards = self:getCards(class_name)
    if cards == nil then return nil end
    if #cards > 1 then
        if type(self.sortByUsePriority) ~= "function" then
            ai_unsupported("card priority sorter is unavailable", "getCard")
        end
        -- Callers use nil for no card; an unknown ranking needs its own signal.
        cards = self:sortByUsePriority(cards)
        if cards == nil then ai_unsupported("card priority order is unknown", "getCard") end
    end
    if islist then return cards end
    return cards[1]
end

function SmartAIView:isValuableCard(card, player)
    player = player or self.player
    if not card or not player then return nil end
    local phase = player:getPhase()
    if phase == nil or sgs.Player_Play == nil then return nil end
    if phase == sgs.Player_Play then
        if card:isKindOf("ExNihilo") then return true end
    else
        local nulls = card_count(self, "Nullification", player)
        local jinks = card_count(self, "Jink", player)
        if nulls == nil or jinks == nil then return nil end
        local trick_need = player:hasSkills("jizhi|nosjizhi|jilve")
        if trick_need == nil then return nil end
        if card:isKindOf("Nullification") and nulls < 2 and trick_need then return true end
        if card:isKindOf("Jink") and jinks < 2 then return true end
    end
    local peaches = card_count(self, "Peach", player)
    if peaches == nil then return nil end
    if card:isKindOf("Peach") and peaches <= 2 then return true end
    local weak = self:isWeak(player)
    if weak == nil then return nil end
    if weak and card:isKindOf("Analeptic") then return true end
    local extra = sgs.ai_valuable_card
    if type(extra) == "table" then
        for _, hook in pairs(extra) do
            if type(hook) == "function" then
                local value = hook(self, card, player)
                if value == nil then return nil end
                if value then return true end
            end
        end
    end
    return false
end

local function point_of(player, card)
    local point = card:getNumber()
    if type(point) ~= "number" then return nil end
    if player:hasSkill("tianbian") and sgs.Card_Heart ~= nil and card:getSuit() == sgs.Card_Heart then
        point = 13
    end
    return point
end

local function best_visible_card(self, player, cards, mode)
    if cards == nil then
        if same_player(player, self.player) then cards = player:getHandcards()
        else cards = player:getKnownCards() end
    end
    if not cards then return nil end
    local function scan(skip_valuable)
        local best, best_point
        for _, card in ipairs(cards) do
            -- 傳進來的清單已是自己的手牌或對方已知牌，不必再靠未投影的 visible 旗標過濾。
            local valuable = false
            if skip_valuable and same_player(player, self.player) then
                valuable = self:isValuableCard(card, player)
                if valuable == nil then return nil, "unknown" end
            end
            if not valuable then
                local point = point_of(player, card)
                if point == nil then return nil, "unknown" end
                if not best_point or (mode == "max" and point > best_point) or (mode == "min" and point < best_point) then
                    best, best_point = card, point
                end
            end
        end
        return best, best_point
    end
    local card, point = scan(true)
    if point == "unknown" then return nil end
    if same_player(player, self.player) and not card then
        card, point = scan(false)
        if point == "unknown" then return nil end
    end
    return card, point
end

function SmartAIView:getMaxCard(player, cards)
    player = player or self.player
    local card = best_visible_card(self, player, cards, "max")
    return card
end

function SmartAIView:getMinCard(player, cards)
    player = player or self.player
    return best_visible_card(self, player, cards, "min")
end

function SmartAIView:getPindianCard(player, mode, ctx)
    player = player or self.player
    mode = mode or "max"
    ctx = ctx or {}
    return best_visible_card(self, player, ctx.cards, mode)
end

function SmartAIView:getPindianMaxCard(player, ctx)
    return self:getPindianCard(player, "max", ctx)
end

function SmartAIView:getPindianMinCard(player, ctx)
    return self:getPindianCard(player, "min", ctx)
end

local function seat_delta(players, from, to)
    local from_seat, to_seat, count = from:getSeat(), to:getSeat(), #players
    if type(from_seat) ~= "number" or type(to_seat) ~= "number" or count < 1 then return nil end
    return (to_seat - from_seat) % count
end

function SmartAIView:getEnemyNumBySeat(from, to, target, include_neutral)
    local players = self.room:getAlivePlayers()
    if not players or not from or not to then return nil end
    local limit = seat_delta(players, from, to)
    if limit == nil then return nil end
    target = target or from
    local count = 0
    for _, player in ipairs(players) do
        local delta = seat_delta(players, from, player)
        if delta == nil then return nil end
        if delta < limit then
            local enemy = self:isEnemy(target, player)
            if enemy == nil then return nil end
            local friend = true
            if include_neutral and not enemy then
                friend = self:isFriend(target, player)
                if friend == nil then return nil end
            end
            if enemy or (include_neutral and not friend) then count = count + 1 end
        end
    end
    return count
end

function SmartAIView:slashProhibit(card, to, from)
    from = from or self.player
    if not to then return nil end
    local hooks = self:forSkillHooks("ai_slash_prohibit", to)
    if not hooks then return nil end
    for _, hook in ipairs(hooks) do
        local banned = self:callHook("ai_slash_prohibit", hook.key, self, from, to, card)
        if banned == true then return true end
    end
    return false
end

function SmartAIView:slashIsEffective(slash, to, from, ignore_armor)
    from = from or self.player
    if not to or not from then return nil end
    if slash then
        local hooks = self:forSkillHooks("ai_target_revises", to)
        if not hooks then return nil end
        for _, hook in ipairs(hooks) do
            if not (ignore_armor and type(sgs.armorName) == "table" and sgs.armorName[hook.key]) then
                local revised = self:callHook("ai_target_revises", hook.key, to, slash, self,
                    {card = slash, from = from, to = {to}})
                if revised == true then return false end
            end
        end
    end
    local damage = self:ajustDamage(from, to, 1, slash)
    if type(damage) ~= "number" then return nil end
    return damage ~= 0
end

function SmartAIView:hasTrickEffective(card, to, from)
    from = from or self.room:getCurrent() or self.player
    to = to or self.player
    if not card or not to or not from then return nil end
    if card:isDamageCard() then
        local nature = (sgs.card_damage_nature or {})[card:getClassName()]
        local damage = self:ajustDamage(from, to, 1, card, nature)
        if type(damage) ~= "number" then return nil end
        if damage == 0 then return false end
    end
    local hooks = self:forSkillHooks("ai_target_revises", to)
    if not hooks then return nil end
    for _, hook in ipairs(hooks) do
        local revised = self:callHook("ai_target_revises", hook.key, to, card, self,
            {card = card, from = from, to = {to}})
        if revised == true then return false end
    end
    return true
end

function SmartAIView:canHit(to, from, conservative)
    from = from or self.room:getCurrent()
    to = to or self.player
    if not to or not from then return nil end
    if type(sgs.hit_skill) == "string" and sgs.hit_skill ~= "" then
        local unblockable = skill_named(from, sgs.hit_skill)
        if unblockable == nil then return nil end
        if unblockable then return true end
    end
    local liegong = self:canLiegong(to, from)
    if liegong == nil then return nil end
    if liegong then return true end
    local jinks = card_count(self, "Jink", to)
    if jinks == nil then return nil end
    local female_from, female_to = from:getGender(), to:getGender()
    local double_jink = from:hasSkill("wushuang")
    if double_jink == nil then return nil end
    if not double_jink and sgs.General_Female ~= nil
        and type(female_from) == "number" and type(female_to) == "number" then
        local roulin_from, roulin_to = from:hasSkill("roulin"), to:hasSkill("roulin")
        if roulin_from == nil or roulin_to == nil then return nil end
        double_jink = (roulin_from and female_to == sgs.General_Female)
            or (roulin_to and female_from == sgs.General_Female)
    end
    if jinks == 0 or (double_jink and jinks < 2) then return true end
    if not conservative then
        local heavy = self:hasHeavyDamage(from, nil, to)
        if heavy == nil then return nil end
        if heavy then conservative = true end
    end
    if not conservative then
        local diagram = self:hasEightDiagramEffect(to)
        if diagram == nil then return nil end
        if diagram then return false end
    end
    return false
end

function SmartAIView:needLeiji(to, from)
    return self:findLeijiTarget(to, 50, from, -1)
end

function SmartAIView:needBear(player)
    player = player or self.player
    if not player then return nil end
    local skills = player:hasSkills("renjie+baiyin")
    if skills == nil then return nil end
    if not skills or player:hasSkill("jilve") then return false end
    return player:getMark("&bear") < 4
end

function SmartAIView:isTiaoxinTarget(enemy)
    if not enemy then return nil end
    local slashes = card_count(self, "Slash", enemy)
    local hp = self.player:getHp()
    if slashes == nil or type(hp) ~= "number" then return nil end
    local hit = self:canHit(self.player, enemy)
    if hit == nil then return nil end
    local genders_differ = false
    if enemy:hasWeapon("DoubleSword") then
        local mine, theirs = self.player:getGender(), enemy:getGender()
        if type(mine) ~= "number" or type(theirs) ~= "number" then return nil end
        genders_differ = mine ~= theirs
    end
    if slashes < 1 and hp > 1 and not hit and not genders_differ then return true end
    local leiji = self:needLeiji(self.player, enemy)
    if leiji == nil then return nil end
    local lose = self:needToLoseHp(self.player, enemy, nil)
    if lose == nil then return nil end
    if slashes < 1 or leiji or lose then return true end
    local overflow, jinks = self:getOverflow(), card_count(self, "Jink")
    if overflow == nil or jinks == nil then return nil end
    return overflow > 0 and jinks > 1
end

function SmartAIView:needToThrowArmor(player, reason)
    player = player or self.player
    if not player then return nil end
    local armor = player:getArmor()
    if player:hasArmorEffect(nil) == false and not armor then return false end
    if armor and not armor:isKindOf("EightDiagram") then
        local covered = skill_named(player, "bazhen|yizhong")
        if covered == nil then return nil end
        if covered then return true end
    end
    local armor_value = self:evaluateArmor(nil, player)
    if type(armor_value) == "number" and armor_value <= -2 then return true end
    local silver = player:hasArmorEffect("SilverLion")
    if silver == nil then return nil end
    if player:isWounded() and silver then
        if not same_player(player, self.player) then
            local friend = self:isFriend(player)
            if friend == nil then return nil end
            if friend then
                local weak = self:isWeak(player)
                if weak == nil then return nil end
                local lion = sgs.use_lion_skill
                if type(lion) == "string" and player:hasSkills(lion) then return false end
                return weak
            end
        end
        return true
    end
    if reason == "moukui" then return false end
    local phase = self.player:getPhase()
    if phase == nil or sgs.Player_Play == nil then return nil end
    local vine = player:hasArmorEffect("Vine")
    if vine == nil then return nil end
    if phase ~= sgs.Player_Play or not vine then return false end
    local enemy = self:isEnemy(player)
    local jinks = card_count(self, "Jink", player)
    if enemy == nil or jinks == nil then return nil end
    return enemy and jinks < 1
end

function SmartAIView:needToThrowCard(to, flags, dis, give, draw)
    to = to or self.player
    flags = flags or "he"
    if not to then return nil end
    if not give and not draw then dis = true end
    if string.find(flags, "h", 1, true) and not to:isKongcheng() then
        local lose_hand = self:hasLoseHandcardEffective(to)
        local kongcheng = self:needKongcheng(to, false)
        if lose_hand == nil or kongcheng == nil then return nil end
        if (not lose_hand and not dis) or ((dis or give) and kongcheng) then return true end
        if draw and to:hasSkill("lirang") then return nil end
    end
    if string.find(flags, "e", 1, true) then
        local equips = to:getEquips()
        if not equips then return nil end
        if #equips > 0 then
            local lose = self:loseEquipEffect(to)
            if lose == nil then return nil end
            if lose and (to:getOffensiveHorse() or to:getWeapon()) then return true end
            local throw_armor = self:needToThrowArmor(to)
            if throw_armor == nil then return nil end
            if throw_armor then return true end
        end
    end
    if string.find(flags, "j", 1, true) then
        local indulgence = to:containsTrick("indulgence")
        local shortage = to:containsTrick("supply_shortage")
        local qh = to:containsTrick("qhstandard_indulgence")
        local yanxiao = to:containsTrick("YanxiaoCard")
        if indulgence == nil or shortage == nil or qh == nil or yanxiao == nil then return nil end
        if (indulgence or shortage or qh) and not yanxiao then return true end
    end
    return false
end

function SmartAIView:damageStruct(struct)
    if type(struct) ~= "table" or not struct.to then return nil end
    local damage = self:ajustDamage(struct.from, struct.to, struct.damage or 1, struct.card, struct.nature)
    if type(damage) ~= "number" then return nil end
    if damage <= 0 then return false end
    if sgs.ai_humanized then return math.random() < 0.95 end
    return true
end

function SmartAIView:toTurnOver(to, n, reason)
    if not to then return nil end
    n = n or 0
    reason = reason or ""
    local hooks = sgs.ai_turn_over
    if type(hooks) == "table" then
        for _, hook in pairs(hooks) do
            if type(hook) == "function" then
                local value = hook(self, to, n, reason)
                if value ~= nil then return value end
            end
        end
    end
    if to:faceUp() == false and not to:hasFlag("ShenfenUsing")
        and not to:hasFlag("guixinUsing") and not to:hasFlag("newguixinUsing") then
        return false
    end
    local phase = to:getPhase()
    if phase == nil or sgs.Player_Play == nil or sgs.Player_Finish == nil
        or sgs.Player_NotActive == nil then
        return nil
    end
    if n > 1 then
        if phase ~= sgs.Player_NotActive and type(sgs.Active_cardneed_skill) == "string"
            and to:hasSkills(sgs.Active_cardneed_skill) then
            return false
        end
        if phase == sgs.Player_NotActive and type(sgs.notActive_cardneed_skill) == "string"
            and to:hasSkills(sgs.notActive_cardneed_skill) then
            return false
        end
    end
    if to:hasSkills("jushou|neojushou|nosjushou|kuiwei") and phase <= sgs.Player_Finish then
        return false
    end
    return true
end

local function find_skill(self, name)
    local players = self.room:getAlivePlayers()
    if not players then return nil end
    for _, player in ipairs(players) do
        if player:hasSkill(name) then return player end
    end
    return false
end

function SmartAIView:willSkipPlayPhase(player, skip_nullification)
    player = player or self.player
    if not player then return nil end
    if sgs.Player_Play == nil then return nil end
    -- 跳過階段只投影給觀察者自己；別人的 nil 要繼續看公開的樂不思蜀，不能直接當成不跳過。
    local skipped = player:isSkipped(sgs.Player_Play)
    if skipped == true then return true end
    local hooks = sgs.ai_will_skip_play
    if type(hooks) == "table" then
        local skills = player:getSkills()
        if not skills then return nil end
        for _, skill in ipairs(skills) do
            local hook = hooks[skill:objectName()]
            if type(hook) == "function" then
                local value = hook(self, player)
                if value ~= nil then return value end
            end
        end
    end
    local indulgence = player:containsTrick("indulgence")
    local qh_indulgence = player:containsTrick("qhstandard_indulgence")
    local yanxiao = player:containsTrick("YanxiaoCard")
    if indulgence == nil or qh_indulgence == nil or yanxiao == nil then return nil end
    if not indulgence and not qh_indulgence then
        if skipped == nil then return nil end
        return false
    end
    local escape = player:hasSkills("keji|conghui")
    local qiaobian = player:hasSkill("qiaobian")
    if escape == nil or qiaobian == nil then return nil end
    if yanxiao or escape then return false end
    local hand = player:getHandcardNum()
    if type(hand) ~= "number" then return nil end
    if hand > 0 and qiaobian then return false end
    if skip_nullification ~= true then
        local players = self.room:getAlivePlayers()
        if not players then return nil end
        local nulls = 0
        for _, other in ipairs(players) do
            local count = card_count(self, "Nullification", other)
            if count == nil then return nil end
            local friend = self:isFriend(other, player)
            if friend == nil then return nil end
            nulls = nulls + (friend and count or -count)
        end
        if nulls > 1 then return false end
    end
    local wizard = find_skill(self, "guicai") or find_skill(self, "guidao") or find_skill(self, "nosguicai")
    if wizard == nil then return nil end
    if wizard and self:isFriend(wizard, player) then return nil end
    return true
end

function SmartAIView:findPlayerToUseSlash(distance_limit, players, reason, slash, extra_targets, fixed_target)
    local friends = players or self.friends_noself
    local enemies = fixed_target and {fixed_target} or self.enemies
    if not friends or not enemies then return nil end
    local nature = sgs.DamageStruct_Normal
    if slash and type(slash.getClassName) == "function" then
        nature = (sgs.card_damage_nature or {})[slash:getClassName()] or nature
    end
    local best, best_value
    for _, friend in ipairs(friends) do
        local total = 0
        for _, benefit in pairs(sgs.ai_slash_benefit) do
            if type(benefit) == "function" then
                local result = benefit(self, friend, slash, reason, extra_targets)
                if type(result) == "table" and type(result.value) == "number" then
                    total = total + result.value
                end
            end
        end
        for _, enemy in ipairs(enemies) do
            local in_range = distance_limit == false or friend:inMyAttackRange(enemy)
            if in_range == nil then return nil end
            if in_range then
                local banned = self:slashProhibit(slash, enemy, friend)
                if banned == nil then return nil end
                local effective = self:slashIsEffective(slash, enemy, friend)
                if effective == nil then return nil end
                if not banned and effective then
                    local expected = self:ajustDamage(friend, enemy, 1, slash, nature)
                    if type(expected) ~= "number" then return nil end
                    if expected > 0 then total = total + expected * 10 end
                end
            end
        end
        if not best_value or total > best_value then best, best_value = friend, total end
    end
    if best_value and best_value > 0 then return best end
    return nil
end

function SmartAIView:askForDiscard(reason, max_num, min_num, optional, include_equip)
    local cards = self.player:getCards(include_equip and "he" or "h")
    if not cards then return nil end
    if type(self.sortByKeepValue) ~= "function" then return nil end
    -- Select from the returned order, never the unsorted input after a failed sort.
    cards = self:sortByKeepValue(cards)
    if cards == nil then return nil end
    max_num = max_num or 1
    min_num = min_num or max_num
    local picked = {}
    for _, card in ipairs(cards) do
        if #picked >= max_num then break end
        local id = card:getEffectiveId()
        if type(id) ~= "number" then return nil end
        picked[#picked + 1] = id
    end
    if #picked < min_num then
        if optional then return {} end
        return nil
    end
    return picked
end

-- 產出牌要比對類別名、kind 或牌名。分類沒投影是未知，不是「不是這類」。
local function conversion_matches(conversion, produced)
    if produced == nil then return true end
    local class_name = conversion:getClassName()
    local kind = conversion:isKindOf(produced)
    local name = conversion:getName()
    if class_name == produced or kind == true or name == produced then return true end
    if kind == nil and class_name ~= produced then return nil end
    return false
end

-- 取代 Card_Parse／cloneCard：只使用這次請求已經授權的轉化票。
-- options.kind 比對產出牌；options.gate(self) 為 false 就不出；
-- options.accept(self, conversion) 為 false 就跳過這張票；
-- options.fill(self, card, use) 負責寫 use.card／use.to。沒寫 fill 就沿用該牌族的共用策略。
-- 技能牌策略要留在 ai_card_use：這次不出，通用規劃才會decline，而不是當成沒策略。
function SmartAIView:playAuthorizedConversion(skill, options)
    options = options or {}
    local conversions = self:getConversions()
    if not conversions then
        ai_unsupported(skill .. " conversions are unknown", skill)
    end
    if options.gate or options.accept or options.kind then
        sgs.ai_use_revises = sgs.ai_use_revises or {}
        if type(sgs.ai_use_revises[skill]) ~= "function" then
            sgs.ai_use_revises[skill] = function(ai, card)
                if type(card.getActivationSkillName) ~= "function"
                    or card:getActivationSkillName() ~= skill then
                    return nil
                end
                if options.gate then
                    local allowed = options.gate(ai)
                    if allowed == nil then ai_unsupported(skill .. " precondition is unknown", skill) end
                    if not allowed then return false end
                end
                local matched = conversion_matches(card, options.kind)
                if matched == nil then ai_unsupported(skill .. " conversion kind is unknown", skill) end
                if not matched then return false end
                if options.accept then
                    local accepted = options.accept(ai, card)
                    if accepted == nil then ai_unsupported(skill .. " card filter is unknown", skill) end
                    if not accepted then return false end
                end
                return nil
            end
        end
    end
    if type(options.fill) == "function" then
        for _, conversion in ipairs(conversions) do
            if conversion:getActivationSkillName() == skill then
                local name = conversion:getName()
                if type(name) == "string" and name ~= "" and type(ai_card_use[name]) ~= "function" then
                    ai_card_use[name] = function(ai, card, use)
                        options.fill(ai, card, use)
                    end
                end
            end
        end
    end
    if options.gate then
        local allowed = options.gate(self)
        if allowed == nil then ai_unsupported(skill .. " precondition is unknown", skill) end
        if not allowed then return nil end
    end
    for _, conversion in ipairs(conversions) do
        if conversion:getActivationSkillName() == skill then
            local matches = conversion_matches(conversion, options.kind)
            if matches == nil then ai_unsupported(skill .. " conversion kind is unknown", skill) end
            if matches and options.accept then
                matches = options.accept(self, conversion)
                if matches == nil then ai_unsupported(skill .. " card filter is unknown", skill) end
            end
            if matches then
                local plan, status = self:tryUseCard(conversion)
                if status == "unsupported" then error(plan, 0) end
                if status == "planned" then
                    local answer = plan:toAnswer()
                    if not answer then ai_unsupported(skill .. " plan cannot be serialized", skill) end
                    return answer
                end
            end
        end
    end
    return nil
end

-- 固定成本的轉化票已經帶著那張子牌。回 false 表示這張票不是單張支付。
function SmartAIView:conversionSubcard(conversion)
    local ids = conversion:getSubcards()
    if not ids then return nil end
    if #ids ~= 1 then return false end
    local cards = self.player:getCards("he")
    if not cards then return nil end
    for _, card in ipairs(cards) do
        if card:getEffectiveId() == ids[1] then return card end
    end
    return false
end

-- 套件用 sgs.ai_defense_slash[技能名] 加成分數，函式回 number 才累加。
-- 武將名不寫在這層。只計看得見的【閃】；暗牌不估算，缺投影回 nil。
sgs.ai_defense_slash = sgs.ai_defense_slash or {}

function SmartAIView:getDefenseSlash(to)
    to = to or self.player
    if not to or not to:getSkills() then return nil end
    local jinks = self:getCardsNum("Jink", to)
    local hp = to:getHp()
    if type(jinks) ~= "number" or type(hp) ~= "number" then return nil end
    local defense = jinks * 1.2 + math.min(hp * 0.45, 10)
    if hp <= 2 then defense = defense - 0.4 end
    local diagram = to:hasArmorEffect("EightDiagram")
    if diagram == nil then return nil end
    if diagram then defense = defense + 1.3 end
    -- 受虐名單是策略層的擴充字串，不是武將分支。
    if not self.player:hasSkill("jueqing") and type(sgs.masochism_skill) == "string" then
        for skill in string.gmatch(sgs.masochism_skill, "[^|]+") do
            if to:hasSkill(skill) then defense = defense + 1 end
        end
    end
    local seen = {}
    for _, skill in ipairs(to:getSkills()) do
        local name = skill:objectName()
        local hook = name and not seen[name] and sgs.ai_defense_slash[name] or nil
        if name then seen[name] = true end
        if type(hook) == "function" then
            local extra = hook(self, to, self.player)
            if type(extra) == "number" then defense = defense + extra end
        end
    end
    return defense
end

-- 依 objective 由高到低，同分再比 getDefenseSlash。任一分數未知就不改順序，回 nil。
function SmartAIView:sortEnemies(players)
    if not AIValue.isList(players) then return nil end
    local objective, defense = {}, {}
    for _, player in ipairs(players) do
        local name = player:objectName()
        objective[name] = self:objectiveLevel(player)
        defense[name] = self:getDefenseSlash(player)
        if type(objective[name]) ~= "number" or type(defense[name]) ~= "number" then return nil end
    end
    table.sort(players, function(a, b)
        local left, right = a:objectName(), b:objectName()
        if objective[left] ~= objective[right] then return objective[left] > objective[right] end
        if defense[left] ~= defense[right] then return defense[left] < defense[right] end
        return left < right
    end)
    return players
end

-- 身份關係只從這次快照重算。模式沒接管時清掉名單，不沿用上一次的敵我。
function SmartAIView:updatePlayers()
    if not self:isModeManaged() then
        self.friends, self.friends_noself, self.enemies = nil, nil, nil
        return nil
    end
    self.friends = self:getFriends()
    self.friends_noself = self:getFriends(nil, true)
    self.enemies = self:getEnemies()
    return true
end

-- 回有效 ID，不回 legacy 牌字串。islist 為真時回 ID 陣列；沒有可見牌回 nil。
function SmartAIView:getCardId(class_name, islist)
    local cards = self:getCard(class_name, true)
    if cards == nil then return nil end
    if islist then
        local ids = {}
        for _, card in ipairs(cards) do
            local id = card:getEffectiveId()
            if type(id) ~= "number" then return nil end
            ids[#ids + 1] = id
        end
        return ids
    end
    local card = cards[1]
    if not card then return nil end
    return card:getEffectiveId()
end

local function lord_player(player)
    return type(player.isLord) == "function" and player:isLord() == true
end

local function male_player(player)
    local gender = type(player.getGender) == "function" and player:getGender() or nil
    if type(gender) ~= "number" then return nil end
    return gender == (sgs.General_Male or 1)
end

-- 沒有可見主公時沿用原版：視為健康。主公體力讀不到才是未知。
function SmartAIView:isLordHealthy()
    local lord = self.room:getLord()
    if not lord then return true end
    local hp = lord:getHp()
    if type(hp) ~= "number" then return nil end
    if hp > 4 and lord:hasSkill("benghuai") then hp = 4 end
    if hp > 3 then return true end
    if hp <= 2 then return false end
    local defense = self:getDefense(lord)
    if defense == nil then return nil end
    return defense > 3
end

-- list1 是該救的受傷友方，list2 是先不急著救的。關係或體力未知時整題回 nil。
function SmartAIView:getWoundedFriend(maleOnly, include_self, players)
    local friends
    if not players then
        friends = include_self and self.friends or self.friends_noself
        if not friends then return nil end
    else
        friends = {}
        for _, player in ipairs(players) do
            local friend = self:isFriend(player)
            if friend == nil then return nil end
            if friend then friends[#friends + 1] = player end
        end
        if not include_self then
            local self_name = self.player:objectName()
            local kept = {}
            for _, player in ipairs(friends) do
                if player:objectName() ~= self_name then kept[#kept + 1] = player end
            end
            friends = kept
        end
    end
    local function wounded(player)
        if type(player.isWounded) == "function" then
            local value = player:isWounded()
            if type(value) == "boolean" then return value end
        end
        local hp, max_hp = player:getHp(), player:getMaxHp()
        if type(hp) ~= "number" or type(max_hp) ~= "number" then return nil end
        return hp < max_hp
    end
    local function compare_hp(player)
        local hp = player:getHp()
        if type(hp) ~= "number" then return nil end
        if lord_player(player) and self:isWeak(player) then hp = hp - 10 end
        if player:objectName() == self.player:objectName() and self:isWeak(player)
            and player:hasSkill("qingnang") then hp = hp - 5 end
        if player:hasSkill("buqu") then
            local pile = player:getPile("buqu")
            if not pile then return nil end
            if #pile > 0 then hp = hp + math.max(0, 5 - #pile) end
        end
        if player:hasSkills("nosrende|rende|kuanggu|kofkuanggu|zaiqi") and hp >= 2 then hp = hp + 5 end
        return hp
    end
    local need_help, defer_help = {}, {}
    for _, friend in ipairs(friends) do
        local hurt = wounded(friend)
        if hurt == nil then return nil end
        local male = true
        if maleOnly then
            male = male_player(friend)
            if male == nil then return nil end
        end
        if hurt and male then
            -- 1 是該救，2 是先不救。健康主公兩邊都不進，和原版相同。
            local bucket
            if lord_player(friend) then
                local mark = friend:getMark("hunzi")
                local enemies = self:getEnemyNumBySeat(self.player, friend)
                local hp = friend:getHp()
                if type(enemies) ~= "number" or type(hp) ~= "number" then return nil end
                if mark == 0 and friend:hasSkill("hunzi") and enemies <= (hp >= 2 and 1 or 0) then
                    bucket = 2
                else
                    local lose = self:needToLoseHp(friend, nil, nil, true, true)
                    if lose == nil then return nil end
                    if lose then bucket = 2
                    else
                        local healthy = self:isLordHealthy()
                        if healthy == nil then return nil end
                        if not healthy then bucket = 1 end
                    end
                end
            else
                local lose = self:needToLoseHp(friend, nil, nil, nil, true)
                if lose == nil then return nil end
                local hp = friend:getHp()
                local skilled = friend:hasSkills("rende|kuanggu|zaiqi")
                if type(hp) ~= "number" or skilled == nil then return nil end
                bucket = (lose or (skilled and hp >= 2)) and 2 or 1
            end
            if bucket == 1 then need_help[#need_help + 1] = friend
            elseif bucket == 2 then defer_help[#defer_help + 1] = friend end
        end
    end
    local defense, hp_score = {}, {}
    local function score(player)
        local name = player:objectName()
        defense[name] = self:getDefenseSlash(player)
        hp_score[name] = compare_hp(player)
        return defense[name] ~= nil and hp_score[name] ~= nil
    end
    for _, player in ipairs(need_help) do
        if not score(player) then return nil end
    end
    for _, player in ipairs(defer_help) do
        if not score(player) then return nil end
    end
    local function by_need(a, b)
        local left, right = hp_score[a:objectName()], hp_score[b:objectName()]
        if left ~= right then return left < right end
        return defense[a:objectName()] < defense[b:objectName()]
    end
    table.sort(need_help, by_need)
    table.sort(defer_help, by_need)
    return need_help, defer_help
end

-- 標準屯田加上 sgs.ai_hasTuntianEffect_skill[技能名]。套件只登記 hook，不改這個函式。
function SmartAIView:hasTuntianEffect(player, need_zaoxian)
    player = player or self.player
    if not player or sgs.Player_NotActive == nil then return nil end
    local phase = player:getPhase()
    if phase == nil then return nil end
    local named = player:hasSkills("tuntian|mobiletuntian|oltuntian")
    if named == nil then return nil end
    if named and phase == sgs.Player_NotActive then
        if not need_zaoxian then return true end
        local ready = player:hasSkills("zaoxian|olzaoxian")
        if ready == nil then return nil end
        return ready == true
    end
    local skills = player:getSkills()
    if not skills then return nil end
    local hooks = sgs.ai_hasTuntianEffect_skill or {}
    local seen = {}
    for _, skill in ipairs(skills) do
        local name = skill:objectName()
        local hook = name and not seen[name] and hooks[name] or nil
        if name then seen[name] = true end
        if type(hook) == "function" then
            local value = hook(player, need_zaoxian)
            if value == nil then return nil end
            if value then return true end
        end
    end
    return false
end

-- 依座位環找上家與下家，對應 getNextAlive 走一整圈。座位缺了就回 nil。
function SmartAIView:adjacentPlayers(player)
    player = player or self.player
    local alive = self.room:getAlivePlayers()
    if not alive or not player then return nil end
    local seated = {}
    for _, other in ipairs(alive) do
        if type(other:getSeat()) ~= "number" then return nil end
        seated[#seated + 1] = other
    end
    if #seated < 2 then return nil end
    table.sort(seated, function(a, b) return a:getSeat() < b:getSeat() end)
    local index
    for i, other in ipairs(seated) do
        if other:objectName() == player:objectName() then index = i break end
    end
    if not index then return nil end
    local previous = seated[(index - 2) % #seated + 1]
    local following = seated[index % #seated + 1]
    return previous, following
end

-- 牌值偏好。未知的跳過階段或點數回 nil，呼叫端不能把 nil 當成不需要。
sgs.ai_cardneed = sgs.ai_cardneed or {}
if sgs.ai_cardneed.bignumber == nil then
    sgs.ai_cardneed.bignumber = function(to, card, self)
        if not self or not card then return nil end
        local skip = self:willSkipPlayPhase(to)
        local value = self:getUseValue(card)
        local number = card:getNumber()
        if skip == nil or type(value) ~= "number" or type(number) ~= "number" then return nil end
        if skip or value >= 6 then return false end
        return number > 10
    end
end
if sgs.ai_cardneed.slash == nil then
    sgs.ai_cardneed.slash = function(to, card, self)
        if not self or not card then return nil end
        local skip = self:willSkipPlayPhase(to)
        if skip == nil then return nil end
        if skip or not card:isKindOf("Slash") then return false end
        local known = self:getCardsNum("Slash", to)
        if known == nil then return nil end
        return known == 0
    end
end

-- 套件可覆寫的 SmartAI 相等工具。只讀快照；缺資料回 nil。不造引擎牌、不改 Room。

if type(sgs.weapon_range) ~= "table" then
    sgs.weapon_range = {
        Weapon = 1, Crossbow = 1, DoubleSword = 2, QinggangSword = 2, IceSword = 2,
        GudingBlade = 2, Axe = 3, Blade = 3, Spear = 3, Halberd = 4, KylinBow = 5
    }
end

function table.contains(list, value)
    if type(list) ~= "table" then return false end
    for _, item in ipairs(list) do
        if item == value then return true end
        if type(item) == "table" and type(value) == "table"
            and type(item.objectName) == "function" and type(value.objectName) == "function"
            and item:objectName() ~= nil and item:objectName() == value:objectName() then
            return true
        end
    end
    return false
end

function sgs.reverse(list)
    if type(list) ~= "table" then return nil end
    local copy = {}
    for index = #list, 1, -1 do copy[#copy + 1] = list[index] end
    return copy
end

function getChoice(choices, choice_name, index)
    if type(choices) == "string" then choices = choices:split("+") end
    if type(choices) ~= "table" or type(choice_name) ~= "string" then return nil end
    index = index or 1
    for _, choice in ipairs(choices) do
        if type(choice) == "string" then
            local parts = choice:split("=")
            if parts[index] == choice_name then return choice end
        end
    end
end

-- 值代理只認投影類別。CardFilter／Engine 回查不在這層。
function isCard(class_name, card, player)
    if type(class_name) ~= "string" or not card or type(card.isKindOf) ~= "function" then return nil end
    if string.find(class_name, ",", 1, true) then
        for piece in string.gmatch(class_name, "[^,]+") do
            local found = isCard(piece, card, player)
            if found then return found end
        end
        return nil
    end
    if card:isKindOf(class_name) then return card end
    return nil
end

function getKnownCard(player, from, class_name, viewas, flags)
    if type(class_name) ~= "string" or not player then return nil end
    if string.find(class_name, ",", 1, true) then
        local total = 0
        for piece in string.gmatch(class_name, "[^,]+") do
            local part = getKnownCard(player, from, piece, viewas, flags)
            if part == nil then return nil end
            total = total + part
        end
        return total
    end
    local cards
    if from and type(player.objectName) == "function" and type(from.objectName) == "function"
        and player:objectName() == from:objectName() and type(player.getCards) == "function" then
        cards = player:getCards("h")
    elseif type(player.getKnownCards) == "function" then
        cards = player:getKnownCards()
    end
    if not cards then return nil end
    local known = 0
    for _, card in ipairs(cards) do
        local suit = type(card.getSuitString) == "function" and card:getSuitString() or nil
        local color = type(card.getColorString) == "function" and card:getColorString() or nil
        if card:isKindOf(class_name) or suit == class_name or color == class_name
            or (viewas and isCard(class_name, card, player)) then
            known = known + 1
        end
    end
    -- 看得見的太少時，沿用原版的一張暗牌估計。手牌張數不明就不估計。
    local hand = type(player.getHandcardNum) == "function" and player:getHandcardNum() or nil
    if type(hand) == "number" and #cards < hand / 2 and hand > 2 and known < hand / 3 then
        known = known + 1
    end
    return known
end

function hasBuquEffect(player)
    if not player or type(player.hasSkill) ~= "function" then return nil end
    local function pile_small(skill_name, pile_name)
        local has = player:hasSkill(skill_name)
        if has == nil then return nil end
        if not has then return false end
        local pile = player:getPile(pile_name)
        if not pile then return nil end
        return #pile <= 4
    end
    local buqu = pile_small("buqu", "buqu")
    if buqu == nil then return nil end
    if buqu then return true end
    local nos = pile_small("nosbuqu", "nosbuqu")
    if nos == nil then return nil end
    if nos then return true end
    local hooks = sgs.ai_hasBuquEffect_skill
    local skills = type(player.getSkills) == "function" and player:getSkills() or nil
    if type(hooks) == "table" then
        if not skills then return nil end
        for _, skill in ipairs(skills) do
            local callback = hooks[skill:objectName()]
            if type(callback) == "function" then
                local value = callback(player)
                if value == nil then return nil end
                if value then return true end
            end
        end
    end
    return false
end

function hasManjuanEffect(player, manjuan_only)
    if not player or sgs.Player_NotActive == nil then return nil end
    local phase = player:getPhase()
    if type(phase) ~= "number" then return nil end
    if phase ~= sgs.Player_NotActive then return false end
    if player:hasSkill("manjuan") then return true end
    if not manjuan_only and player:hasSkill("zishu") then return true end
    return false
end

function isLord(player)
    if not player or type(player.isLord) ~= "function" then return nil end
    return player:isLord()
end

-- 策略探測用的類別替身，只回答類別與是否傷害牌。不能拿去出牌。
function SmartAIView:classProbe(class_name)
    if type(class_name) ~= "string" or class_name == "" then return nil end
    local tricks = {
        Duel = true, SavageAssault = true, ArcheryAttack = true, FireAttack = true,
        Indulgence = true, SupplyShortage = true, Snatch = true, Dismantlement = true,
        ExNihilo = true, Nullification = true, AmazingGrace = true, GodSalvation = true,
        Collateral = true, Lightning = true
    }
    local damage = {
        Slash = true, Duel = true, SavageAssault = true, ArcheryAttack = true, FireAttack = true
    }
    local probe = {}
    function probe:getClassName() return class_name end
    function probe:objectName() return class_name end
    function probe:isKindOf(kind)
        if kind == class_name then return true end
        if (kind == "TrickCard" or kind == "NDTrick") and tricks[class_name] then return true end
        return false
    end
    function probe:isDamageCard() return damage[class_name] == true end
    function probe:getTypeId()
        if tricks[class_name] then return sgs.Card_TypeTrick end
        return sgs.Card_TypeBasic
    end
    function probe:getEffectiveId() return nil end
    return probe
end

function SmartAIView:log() end

function SmartAIView:isGoodHp(to)
    to = to or self.player
    if not to then return nil end
    local hp = to:getHp()
    if type(hp) ~= "number" then return nil end
    if hp > 1 then return true end
    local buqu = hasBuquEffect(to)
    if buqu == nil then return nil end
    if buqu then return true end
    local peach = card_count(self, "Peach", to)
    local analeptic = card_count(self, "Analeptic", to)
    if peach == nil or analeptic == nil then return nil end
    if peach + analeptic > 0 then return true end
    local current = self.room:getCurrent()
    if current and current:hasSkill("wansha") then return false end
    local friends = self:getFriends(to, true)
    if not friends then return nil end
    for _, friend in ipairs(friends) do
        local saved = card_count(self, "Peach", friend)
        if saved == nil then return nil end
        if saved > 0 then return true end
    end
    return false
end

function SmartAIView:isGoodChainPartner(player)
    player = player or self.player
    local healthy = self:isGoodHp(player)
    if healthy == nil then return nil end
    if not healthy then return false end
    local lose = self:needToLoseHp(player)
    if lose == nil then return nil end
    return lose == true
end

function SmartAIView:getExpectedJinkNum(use)
    -- Jink_ 標籤沒進快照。context 若帶 jink_numbers 才答，否則未知。
    if type(use) ~= "table" then return nil end
    local numbers = use.jink_numbers or use.jink_list
    if type(numbers) ~= "table" or not use.to then return nil end
    local expected = 1
    for index, target in ipairs(use.to) do
        local name = type(target) == "table" and target.objectName and target:objectName() or target
        if name == self.player:objectName() then
            local count = tonumber(numbers[index])
            if count == nil then return nil end
            if count == 0 then return 0 end
            if count > expected then expected = count end
        end
    end
    return expected
end

function SmartAIView:getSaveNum(for_friend)
    local players = self.room:getAlivePlayers()
    if not players then return nil end
    local current = self.room:getCurrent()
    local wansha = current and current:hasSkill("wansha") or false
    local total = 0
    for _, player in ipairs(players) do
        local wanted = for_friend and self:isFriend(player) or (not for_friend and self:isEnemy(player))
        if wanted == nil then return nil end
        if wanted and (not wansha or player:objectName() == self.player:objectName() or player:hasSkill("spdushi")) then
            if player:hasSkill("jijiu") then
                local heart = self:getSuitNum("heart", true, player)
                local diamond = self:getSuitNum("diamond", true, player)
                local hand = player:getHandcardNum()
                if heart == nil or diamond == nil or type(hand) ~= "number" then return nil end
                total = total + heart + diamond + hand * 0.4
            end
            local peach = card_count(self, "Peach", player)
            if peach == nil then return nil end
            if player:objectName() == self.player:objectName() then total = total + peach end
        end
    end
    return total
end

function SmartAIView:hasExplicitRebel()
    if self:isRolePredictable() ~= true then return nil end
    local players = self.room:getAlivePlayers()
    if not players then return nil end
    for _, player in ipairs(players) do
        local role = type(player.getRole) == "function" and player:getRole() or nil
        if role == "rebel" then return true end
    end
    return false
end


-- 套件用 ai_jueqing_effect／ai_hasTuntianEffect_skill 擴充，不把擴展武將名寫進這層。
sgs.jueqing_skill = sgs.jueqing_skill or "jueqing|gangzhi"
sgs.ai_jueqing_effect = sgs.ai_jueqing_effect or {}

function SmartAIView:getDynamicUsePriority(card)
    if not card then return nil end
    local kill = card:hasFlag("AIGlobal_KillOff")
    if kill == nil then return nil end
    if kill then return 15 end
    local priority = self:getUsePriority(card)
    if type(priority) ~= "number" then return nil end
    local skill_name = type(card.getSkillName) == "function" and card:getSkillName() or ""
    if card:isKindOf("DelayedTrick") and skill_name ~= "" then return priority - 0.1 end
    return priority
end

function SmartAIView:sortByDynamicUsePriority(cards, inverse)
    if not AIValue.isList(cards) then return nil end
    local copy, scores = {}, {}
    for _, card in ipairs(cards) do
        copy[#copy + 1] = card
        local value = self:getDynamicUsePriority(card)
        if type(value) ~= "number" then return nil end
        scores[card] = value
    end
    table.sort(copy, function(left, right)
        if scores[left] ~= scores[right] then
            if inverse then return scores[left] < scores[right] end
            return scores[left] > scores[right]
        end
        return (left:getEffectiveId() or 0) < (right:getEffectiveId() or 0)
    end)
    return copy
end

function SmartAIView:hasJueqingEffect(from, to)
    local function named(player)
        if not player then return false end
        local hit = player:hasSkills(sgs.jueqing_skill)
        if hit == nil then return nil end
        return hit == true
    end
    local from_named, to_named = named(from), named(to)
    if from_named == nil or to_named == nil then return nil end
    if from_named or to_named then return true end
    local function extra(player)
        if not player then return false end
        local hooks = self:forSkillHooks("ai_jueqing_effect", player)
        if not hooks then return nil end
        for _, hook in ipairs(hooks) do
            local rule = hook.value
            local hit = type(rule) == "function" and rule(self, from, to) or rule
            if hit == nil then return nil end
            if hit then return true end
        end
        return false
    end
    local from_extra, to_extra = extra(from), extra(to)
    if from_extra == nil or to_extra == nil then return nil end
    return from_extra or to_extra
end

function SmartAIView:dontHurt(to, from)
    local jueqing = self:hasJueqingEffect(from, to)
    if jueqing == nil then return nil end
    if jueqing then return true end
    local function scan(player, registry)
        if not player then return false end
        local hooks = self:forSkillHooks(registry, player)
        if not hooks then return nil end
        for _, hook in ipairs(hooks) do
            local rule = hook.value
            local hit = type(rule) == "function" and rule(self, to, from) or rule
            if hit == nil then return nil end
            if hit then return true end
        end
        return false
    end
    local from_hit = scan(from, "ai_dont_hurt_from")
    if from_hit == nil or from_hit then return from_hit end
    return scan(to, "ai_dont_hurt_to")
end

function SmartAIView:keepCard(card, player, discard_peach)
    if not card then return true end
    player = player or self.player
    if card:isKindOf("WoodenOx") then
        local pile = player:getPile("wooden_ox")
        if not pile then return nil end
        if #pile > 0 then return true end
    end
    if not discard_peach and card:isKindOf("Peach") then return true end
    return false
end

-- 技能牌優先走套件登記的 ai_skill_use_func；沒有登記才用共用出牌推演。
function SmartAIView:useSkillCard(card, use)
    if not card or type(use) ~= "table" then return nil end
    local registry = sgs.ai_skill_use_func
    local handler = type(registry) == "table" and
        (registry[card:objectName()] or registry[card:getClassName()]) or nil
    if type(handler) == "function" then return handler(card, use, self) end
    if type(self.tryUseCard) ~= "function" then return nil end
    local plan, status = self:tryUseCard(card, use)
    if status == "unsupported" then return nil end
    return plan
end

local function skill_view(player, skill_name)
    local skills = player:getSkills()
    if not skills then return nil end
    for _, skill in ipairs(skills) do
        if skill:objectName() == skill_name and skill:isInvalid() ~= true then return skill end
    end
    return false
end

local function pile_at_least(player, pile_name, count)
    local names = player:getPileNames()
    if not names then return nil end
    local size = player:getPileCount(pile_name) or 0
    return size >= count
end

-- 高價值覺醒只保留能用可見標記、牌堆、體力判斷的條件。沒有 tag 投影的條件維持 false。
local function wake_high_value(player, skill_name)
    local mark = player.getMark and player:getMark(skill_name) or 0
    if skill_name == "fengliang" then return true end
    if skill_name == "baiyin" then
        return player:getMark("&bear") >= 4 or player:hasSkill("renjie") == true
    end
    if skill_name == "chuyuan" or skill_name == "tianxing" then
        local pile = pile_at_least(player, "cychu", 3)
        if pile == nil then return nil end
        return pile or player:hasSkill("chuyuan") == true
    end
    if skill_name == "baoling" then return player:getMark("HengzhengUsed") >= 1 end
    if skill_name == "zhiji" or skill_name == "mobilezhiji" or skill_name == "olzhiji" then
        return player:isKongcheng() == true
    end
    if skill_name == "mobilehunzi" then
        local hp = player:getHp()
        return type(hp) == "number" and hp <= 2
    end
    if skill_name == "hunzi" then
        local hp = player:getHp()
        return type(hp) == "number" and hp == 1
    end
    if skill_name == "qianxin" then return player:isWounded() == true end
    if mark == nil then return nil end
    return false
end

-- SmartAI:isValueSkill 的可見子集。技能不在這名角色身上就是 false；頻率讀不到才是未知。
function SmartAIView:isValueSkill(skill_name, player, high_value)
    player = player or self.player
    if type(skill_name) ~= "string" or skill_name == "" or not AIValue.isPlayer(player) then
        return nil
    end
    if type(sgs.bad_skills) == "string"
        and string.find("|" .. sgs.bad_skills .. "|", "|" .. skill_name .. "|", 1, true) then
        return false
    end
    if not high_value and (skill_name == "zhiheng" or skill_name == "tenyearzhiheng"
        or skill_name == "jijiu") then
        return true
    end
    local skill = skill_view(player, skill_name)
    if skill == nil then return nil end
    if skill == false then return false end
    local frequency = skill:getFrequency()
    if type(frequency) ~= "number" or sgs.Skill_Wake == nil then return nil end
    if frequency == sgs.Skill_Wake and player:getMark(skill_name) == 0 then
        if not high_value then return true end
        return wake_high_value(player, skill_name)
    end
    if sgs.Skill_Limited ~= nil and frequency == sgs.Skill_Limited then return nil end
    return false
end

-- 以下是套件會直接呼叫的 SmartAI 相等函式。武將名不寫在這裡；
-- 套件用 sgs.ai_can_damagehp、sgs.ai_dangerous_card、sgs.ai_valuable_equip、
-- sgs.ai_defense_slash、sgs.ai_pindian_without_card 擴充。

sgs.ai_can_damagehp = sgs.ai_can_damagehp or {}
sgs.ai_dangerous_card = sgs.ai_dangerous_card or {}
sgs.ai_valuable_equip = sgs.ai_valuable_equip or {}
sgs.ai_defense_slash = sgs.ai_defense_slash or {}
sgs.ai_pindian_without_card = sgs.ai_pindian_without_card or {}
sgs.ai_cardneed = sgs.ai_cardneed or {}

local function hook_id(hooks, ...)
    if type(hooks) ~= "table" then return false end
    for _, hook in pairs(hooks) do
        if type(hook) == "function" then
            local value = hook(...)
            if value == nil then return nil end
            if type(value) == "number" then return value end
        end
    end
    return false
end

local function zone_count(player)
    local hand, equips = player:getHandcardNum(), player:getEquips()
    if type(hand) ~= "number" or not equips then return nil end
    return hand + #equips
end

-- true 表示要這次傷害；false 表示掃過的 hook 都不要；nil 是某個 hook 答不出來。
function SmartAIView:canDamageHp(from, card, to)
    to = to or self.player
    if not to then return nil end
    local skills = to:getSkills()
    if not skills then return nil end
    for _, skill in ipairs(skills) do
        local hook = sgs.ai_can_damagehp[skill:objectName()]
        if type(hook) == "function" then
            local value = hook(self, from, card, to)
            if value == true then return true end
            if value == false then return false end
            if value ~= nil then return nil end
        end
    end
    return false
end

function SmartAIView:hasSkills(skill_names, player)
    player = player or self.player
    if type(player) == "table" and type(player.objectName) ~= "function" then
        for _, one in ipairs(player) do
            local has = one:hasSkills(skill_names)
            if has == nil then return nil end
            if has then return one end
        end
        return false
    end
    if not player or type(player.hasSkills) ~= "function" then return nil end
    return player:hasSkills(skill_names)
end

function SmartAIView:getChainedEnemies(player)
    local enemies = self:getEnemies(player or self.player)
    if not enemies then return nil end
    local chained = {}
    for _, enemy in ipairs(enemies) do
        local linked = enemy:isChained()
        if linked == nil then return nil end
        if linked then chained[#chained + 1] = enemy end
    end
    return chained
end

-- 空城不能拼點；沒手牌仍能拼的技能由 sgs.ai_pindian_without_card 補。
function SmartAIView:canPindian(left, right)
    local function ready(player)
        if not player then return nil end
        local empty = player:isKongcheng()
        if empty == nil then return nil end
        if not empty then return true end
        for _, hook in pairs(sgs.ai_pindian_without_card) do
            if type(hook) == "function" then
                local value = hook(self, player)
                if value == nil then return nil end
                if value == true then return true end
            end
        end
        return false
    end
    local first = ready(left)
    if first == nil or not right then return first end
    local second = ready(right)
    if second == nil then return nil end
    return first and second
end

-- 只核對已投影的距離與攻擊範圍。禁止、次數與牌種仍由 slashProhibit／slashIsEffective 管。
function SmartAIView:canSlash(from, to, card, distance_limit)
    from = from or self.player
    if not from or not to then return nil end
    if distance_limit == false then return true end
    local distance, range = from:distanceTo(to), from:getAttackRange()
    if type(distance) ~= "number" or type(range) ~= "number" then return nil end
    return distance <= range
end

function SmartAIView:getDangerousCard(who)
    if not who then return nil end
    local hooked = hook_id(sgs.ai_dangerous_card, self, who)
    if hooked == nil or type(hooked) == "number" then return hooked end
    local weapon = who:getWeapon()
    local friends = self.friends or self:getFriends()
    if friends == nil and weapon then return nil end
    if weapon and (weapon:isKindOf("Crossbow") or weapon:isKindOf("GudingBlade")) then
        local slashes = card_count(self, "Slash", who)
        if slashes == nil then return nil end
        for _, friend in ipairs(friends) do
            local reach = self:canSlash(who, friend, nil, true)
            if reach == nil then return nil end
            if weapon:isKindOf("Crossbow") and reach and slashes > 0 then return weapon:getEffectiveId() end
            if weapon:isKindOf("GudingBlade") and reach and friend:isKongcheng() and slashes > 0 then
                return weapon:getEffectiveId()
            end
        end
    elseif weapon and weapon:isKindOf("Spear") then
        local crossbow = self:hasCrossbowEffect(who)
        local hand = who:getHandcardNum()
        if crossbow == nil or type(hand) ~= "number" then return nil end
        if crossbow and hand >= 1 then return weapon:getEffectiveId() end
    elseif weapon and weapon:isKindOf("Axe") then
        local overflow = self:getOverflow(who)
        local count = zone_count(who)
        if overflow == nil or count == nil then return nil end
        if who:hasSkills("luoyi|pojun|jiushi|jiuchi|jie|wenjiu|shenli|jieyuan") or overflow > 0 or count >= 4 then
            return weapon:getEffectiveId()
        end
    end
    local armor = who:getArmor()
    if armor and armor:isKindOf("EightDiagram") then
        local lord = self.room:getLord()
        if lord and lord:hasSkill("hujia") and who:getKingdom() == "wei" then
            local friend = self:isFriend(lord, who)
            if friend == nil then return nil end
            if friend then return armor:getEffectiveId() end
        end
        if type(sgs.wizard_skill) == "string" and who:hasSkills(sgs.wizard_skill) then
            return armor:getEffectiveId()
        end
    end
    if weapon and who:hasSkills("liegong|anjian") then return weapon:getEffectiveId() end
    return false
end

function SmartAIView:getValuableCard(who)
    if not who then return nil end
    local hooked = hook_id(sgs.ai_valuable_equip, self, who)
    if hooked == nil or type(hooked) == "number" then return hooked end
    local friends = self.friends or self:getFriends()
    if not friends then return nil end
    local ordered = self:sort(friends, "hp")
    if not ordered then return nil end
    local friend = ordered[1]
    local weapon, horse = who:getWeapon(), who:getOffensiveHorse()
    if friend then
        local weak = self:isWeak(friend)
        local distance = who:distanceTo(friend)
        local bare = who:getAttackRange()
        if weak == nil or type(distance) ~= "number" or type(bare) ~= "number" then return nil end
        if weak and distance <= bare then
            if weapon and distance > 1 then return weapon:getEffectiveId() end
            if horse and distance > 1 then return horse:getEffectiveId() end
        end
    end
    local defense = who:getDefensiveHorse()
    local self_distance = self.player:distanceTo(who)
    if type(self_distance) ~= "number" then return nil end
    if defense and self_distance == 2 then return defense:getEffectiveId() end
    if weapon and who:hasSkills("qiangxi|zhulou|taichen") then return weapon:getEffectiveId() end
    local equips = who:getEquips()
    if not equips then return nil end
    for _, equip in ipairs(equips) do
        local hp = who:getHp()
        if type(hp) ~= "number" then return nil end
        if hp <= 2 and who:hasSkill("baobian") then return equip:getEffectiveId() end
        if equip:isRed() and who:hasSkills("wusheng|jijiu|xueji|nosfuhun") then return equip:getEffectiveId() end
        if equip:isBlack() and who:hasSkills("qixi|duanliang|yinling|guidao") then return equip:getEffectiveId() end
        if type(sgs.need_equip_skill) == "string" and who:hasSkills(sgs.need_equip_skill)
            and not (type(sgs.lose_equip_skill) == "string" and who:hasSkills(sgs.lose_equip_skill)) then
            return equip:getEffectiveId()
        end
    end
    local armor = who:getArmor()
    if armor then
        local value = self:evaluateArmor(armor, who)
        local throw = self:needToThrowArmor(who)
        if type(value) ~= "number" or throw == nil then return nil end
        if not throw then return armor:getEffectiveId() end
    end
    return false
end

-- 鐵索傳導：友方損失大於敵方才值得。普通傷害只看當前目標；屬性傷害才掃其他橫置角色。
function SmartAIView:isGoodChainTarget(who, nature_card, source, damagecount)
    source = source or self.player
    damagecount = damagecount or 1
    if not who or not source then return nil end
    local card = type(nature_card) == "table" and nature_card or nil
    local nature = nature_card
    if card then
        if card:isKindOf("FireSlash") or card:isKindOf("FireAttack") then nature = sgs.DamageStruct_Fire
        elseif card:isKindOf("ThunderSlash") then nature = sgs.DamageStruct_Thunder
        else nature = sgs.DamageStruct_Normal end
    end
    if type(nature) ~= "number" then nature = sgs.DamageStruct_Normal end
    local good, bad = 0, 0
    local function add(target)
        local friend, enemy = self:isFriend(target), self:isEnemy(target)
        if friend == nil or enemy == nil then return nil end
        local damage = self:ajustDamage(source, target, damagecount, card, nature)
        local weak = self:isWeak(target)
        local hurt = self:cantbeHurt(target, source, damagecount)
        local hp = target:getHp()
        if type(damage) ~= "number" or weak == nil or hurt == nil or type(hp) ~= "number" then return nil end
        if damage < 1 then return true end
        local value = -damage
        if weak then value = value - 1 end
        if hurt then value = value - 10 end
        if damage >= hp then value = value - 4 end
        if friend then good = good + value elseif enemy then bad = bad + value end
        return true
    end
    if not add(who) then return nil end
    if nature ~= sgs.DamageStruct_Normal then
        local others = self.room:getOtherPlayers(who)
        if not others then return nil end
        for _, other in ipairs(others) do
            local linked = other:isChained()
            if linked == nil then return nil end
            if linked and not add(other) then return nil end
        end
    end
    return bad ~= 0 and good > bad
end

-- 無實體殺時選額外目標。不造 dummy 牌；合法性仍交給 prohibit／effective。
function SmartAIView:zeroCardSlashTarget(targets)
    if not AIValue.isList(targets) then return nil end
    local ordered = self:sort(targets, "defenseSlash")
    if not ordered then return nil end
    local function usable(target, friend_ok)
        local enemy = self:isEnemy(target)
        local friend = self:isFriend(target)
        if enemy == nil or friend == nil then return nil end
        if friend_ok then
            if not friend then return false end
        elseif not enemy then return false end
        local banned = self:slashProhibit(nil, target)
        local good = self:isGoodTarget(target, ordered, nil)
        local effective = self:slashIsEffective(nil, target)
        if banned == nil or good == nil or effective == nil then return nil end
        if banned or not good or not effective then return false end
        local lose = self:needToLoseHp(target, self.player, nil)
        local leiji = self:needLeiji(target, self.player)
        if lose == nil or leiji == nil then return nil end
        if not friend_ok and (lose or leiji) then return false end
        if friend_ok and not (lose or leiji) then return false end
        return true
    end
    for _, target in ipairs(ordered) do
        local ok = usable(target, false)
        if ok == nil then return nil end
        if ok then return target end
    end
    for index = #ordered, 1, -1 do
        local ok = usable(ordered[index], true)
        if ok == nil then return nil end
        if ok then return ordered[index] end
    end
    return false
end
