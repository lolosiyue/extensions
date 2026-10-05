-- Shadow 隔離 AI。SmartAI 相等函式在 smart-ai-functions.lua／decision-core.lua。
-- 本檔只擴充技能名單、牌值與 y_ 決策，不改基礎層，也不呼叫 Engine。
-- 快照沒有的移動、標記、屬性回 unsupported，不編成預設答案。

sgs.append_skill_list("need_kongcheng", "y_lianying")
sgs.append_skill_list("notActive_cardneed_skill", "y_yangzheng")
sgs.append_skill_list("notActive_cardneed_skill", "y_caipei")
sgs.append_skill_list("hit_skill", "y_wuji")
sgs.append_skill_list("lose_equip_skill", "y_xiaoyi")

sgs.y_mayunlu_keep_value = {
    Peach = 6, Analeptic = 5.4, ExNihilo = 5.9, Snatch = 5.3,
    EightDiagram = 5.7, RenwangShield = 5.8, OffensiveHorse = 5.1,
    DefensiveHorse = 5.2, Indulgence = 5.6, Nullification = 5.5,
    Dismantlement = 5.1, Crossbow = 5.0, Jink = 4, Slash = 4.1,
    ThunderSlash = 4.5, FireSlash = 4.9
}
sgs.card_value = sgs.card_value or {}
sgs.card_value.y_mayunlu = sgs.y_mayunlu_keep_value

sgs.ai_use_value.y_rendecard = 8.5
sgs.ai_use_priority.y_rendecard = 8.8
sgs.ai_use_value.y_anxucard = 9
sgs.ai_use_priority.y_anxucard = 4.2
sgs.dynamic_value.benefit.y_anxucard = true
sgs.ai_use_value.y_wujicard = 4
sgs.ai_use_priority.y_wujicard = (sgs.ai_use_priority.Slash or 4) + 1
sgs.ai_card_intention.y_yangzhengcard = -60
sgs.ai_playerchosen_intention.y_caipei = -80
sgs.ai_playerchosen_intention.y_huaiju = -80
sgs.ai_playerchosen_intention.y_weiji = -80
sgs.ai_suppress_intention.y_huiyu = true

sgs.ai_getLeastHandcardNum_skill.y_lianying = function(self, player, least)
    if type(least) == "number" and least < 1 then return 1 end
end

local function skill_plan(self, name, cards, targets)
    local action = self:getSkillAction(name)
    if not (action and action:isValid()) then return nil end
    return {
        kind = "use_card",
        skill_action = action:toAnswer(),
        cards = cards or {},
        targets = targets or {}
    }
end

-- 整回合 activate 裡單技能未知不能擋掉其他牌；針對這個技能的探測才記未覆蓋。
local function play_conversion(self, name, options)
    local ok, value = AIUnsupported.capture(function()
        return self:playAuthorizedConversion(name, options)
    end)
    if ok then return value end
    local probe = type(self.request.skill_action) == "table" and self.request.skill_action or nil
    if probe and probe.activation_skill == name then error(value, 0) end
    return nil
end

local function relations(self, key)
    if self.friends and self.enemies and self.friends_noself then return true end
    local probe = type(self.request.skill_action) == "table" and self.request.skill_action or nil
    if probe and probe.activation_skill == key then
        ai_unsupported(key .. " relations are unknown", key)
    end
    return false
end

local function context_player(self)
    local data = self:getDecisionData()
    return data and data:toPlayer() or nil
end

local function number(value)
    if type(value) ~= "number" then return nil end
    return value
end

local function equip_slot(card)
    if card:isKindOf("Weapon") then return 0 end
    if card:isKindOf("Armor") then return 1 end
    if card:isKindOf("DefensiveHorse") then return 2 end
    if card:isKindOf("OffensiveHorse") then return 3 end
    if card:isKindOf("Treasure") then return 4 end
    return nil
end

local function empty_slot(player, slot)
    if type(slot) ~= "number" or type(player.hasEquip) ~= "function" then return nil end
    return player:hasEquip(slot) == false
end

local function low_cards(self, flags, count)
    local cards = self.player:getCards(flags)
    if not cards then return nil end
    local sorted = self:sortByUseValue(cards, true)
    if not sorted then return nil end
    local ids = {}
    for _, card in ipairs(sorted) do
        local id = card:getEffectiveId()
        if type(id) ~= "number" then return nil end
        ids[#ids + 1] = id
        if #ids == count then break end
    end
    return ids
end

-- 仁德：好友特殊技能、溢牌或已受傷才給。and 比 or 緊，faceUp 只掛在義舍那一段。
ai_skill_activate.y_rende = function(self)
    if not relations(self, "y_rende") then return nil end
    local count = number(self.player:getHandcardNum())
    if not count or count <= 1 then return nil end
    local want
    for _, player in ipairs(self.friends_noself) do
        local face = player:faceUp()
        local haoshi = player:hasSkill("haoshi")
        local shortage = player:containsTrick("supply_shortage")
        local longluo = player:hasSkill("longluo")
        local indulgence = player:containsTrick("indulgence")
        local yishe = player:hasSkill("yishe")
        local jijiu = player:hasSkill("jijiu")
        if face == nil or haoshi == nil or shortage == nil or longluo == nil
            or indulgence == nil or yishe == nil or jijiu == nil then
            return nil
        end
        if ((haoshi and not shortage) or longluo or ((not indulgence and yishe) and face)) or jijiu then
            want = true
            break
        end
    end
    if not want then
        local overflow = self:getOverflow()
        local lost = number(self.player:getLostHp())
        if lost == nil then return nil end
        want = lost > 0 or (type(overflow) == "number" and overflow > 0)
    end
    if not want then return nil end
    local give = count > 2 and 1 or count == 2 and 2 or nil
    if not give then return nil end
    local ids = low_cards(self, "h", give)
    if not ids or #ids ~= give then return nil end
    local friends = self:sort(self.friends_noself, "defense")
    if not friends or not friends[1] then return nil end
    return skill_plan(self, "y_rende", ids, {friends[1]:objectName()})
end

ai_skill_activate.y_anxu = function(self)
    if not relations(self, "y_anxu") then return nil end
    local friends = self:sort(self.friends, "hp")
    if not friends then return nil end
    local function pick(predicate)
        for _, friend in ipairs(friends) do
            local draw = self:canDraw(friend, self.player)
            if draw == nil then return nil, "unknown" end
            if draw and predicate(friend) then return friend end
        end
    end
    local target, status = pick(function(friend)
        return self:hasTuntianEffect(friend) == true
    end)
    if status == "unknown" then return nil end
    if not target then
        target, status = pick(function(friend)
            return self:doDisCard(friend, "he") == true
        end)
        if status == "unknown" then return nil end
    end
    if not target then
        target, status = pick(function() return true end)
        if status == "unknown" or not target then return nil end
    end
    return skill_plan(self, "y_anxu", {}, {target:objectName()})
end

sgs.ai_skill_discard.y_anxu = function(self, discard_num)
    local cards = self.player:getCards("he")
    if not cards or type(discard_num) ~= "number" then return nil end
    local sorted = self:sortByDynamicUsePriority(cards, true)
    if not sorted then return nil end
    local ids, count = {}, 0
    for _, card in ipairs(sorted) do
        ids[#ids + 1] = card:getEffectiveId()
        count = count + 1
        if count == discard_num then break end
    end
    return ids
end

sgs.ai_skill_playerchosen.y_anxu = function(self, targets)
    local found = self:findPlayerToDiscard("hej", true, false, targets)
    if found and found[1] then return found[1] end
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "hej") then return target end
    end
    return targets[1]
end

-- 戎装：殺要與裝備同花色，閃要不同花色。合法票已由權威端篩過，這裡只挑使用價值低的。
local function rongzhuang_accept(kind)
    return function(self, conversion)
        local card = self:conversionSubcard(conversion)
        if card == nil then return nil end
        if not card then return false end
        local equips = self.player:getCards("e")
        if not equips then return nil end
        local matched = false
        for _, equip in ipairs(equips) do
            if equip:getSuit() == card:getSuit() then matched = true break end
        end
        if kind == "Slash" then return matched end
        if kind == "Jink" then return not matched end
        return false
    end
end

ai_skill_activate.y_rongzhuang = function(self)
    local equips = number(self.player:getEquips() and #self.player:getEquips() or nil)
    if equips == nil or equips == 0 then return nil end
    return play_conversion(self, "y_rongzhuang", {
        kind = "Slash",
        accept = rongzhuang_accept("Slash")
    })
end

sgs.ai_skill_invoke.y_chongqi = function(self, data)
    local player = data:toPlayer()
    if not player then return nil end
    local enemy = self:isEnemy(player)
    if enemy == nil then return nil end
    if not enemy then return false end
    local discard = self:doDisCard(player, "he")
    if discard == nil then return nil end
    return discard == true
end

sgs.ai_skill_invoke.y_zhiji = true

ai_skill_activate.y_tiaoxin = function(self)
    if not relations(self, "y_tiaoxin") then return nil end
    local enemies = self:sort(self.enemies, "threat")
    if not enemies then return nil end
    local jinks = self:getCardsNum("Jink")
    local hp = number(self.player:getHp())
    if jinks == nil or hp == nil then return nil end
    for _, enemy in ipairs(enemies) do
        local distance = enemy:distanceTo(self.player)
        local range = number(enemy:getAttackRange())
        local nude = enemy:isNude()
        local slashes = self:getCardsNum("Slash", enemy)
        if distance == nil or range == nil or nude == nil or slashes == nil then return nil end
        if distance <= range and not nude and (slashes == 0 or jinks > 0 or hp >= 2) then
            return skill_plan(self, "y_tiaoxin", {}, {enemy:objectName()})
        end
    end
    return nil
end

sgs.ai_skill_invoke.y_yongjue = function(self, data)
    local player = data:toPlayer()
    if not player then return nil end
    return self:isFriend(player)
end

sgs.ai_skill_invoke.y_yjtargetmove = function(self, data)
    local use = data:toCardUse()
    local card = use and use.card
    if not card then return nil end
    if card:isKindOf("AmazingGrace") or card:isKindOf("ExNihilo") then return false end
    if card:isKindOf("GodSalvation") then
        local wounded = self.player:isWounded()
        if wounded == nil then return nil end
        if wounded then return false end
    end
    return true
end

sgs.ai_skill_invoke.y_cunsi = function(self)
    if type(self.player.getRole) ~= "function" then return nil end
    local role = self.player:getRole()
    if type(role) ~= "string" or role == "" then return nil end
    if role == "lord" then return false end
    if not self.friends_noself or #self.friends_noself < 1 then return false end
    local count = number(self.player:getHandcardNum())
    if count == nil then return nil end
    if count == 1 then return true end
    local cards = self.player:getCards("h")
    if not cards then return nil end
    for _, card in ipairs(cards) do
        if card:isKindOf("Peach") or card:isKindOf("Analeptic") then return false end
    end
    return true
end

sgs.ai_skill_playerchosen.y_cunsi = function(self, targets)
    if not self.friends_noself then return nil end
    for _, friend in ipairs(self.friends_noself) do
        if friend:hasSkill("longdan") then return friend end
    end
    for _, target in ipairs(targets) do
        if self:isFriend(target) then return target end
    end
end

sgs.ai_skill_cardchosen.y_cunsi = function(self)
    local cards = self.player:getCards("h")
    if not cards then return nil end
    local sorted = self:sortByUseValue(cards)
    local card = sorted and sorted[1]
    return card and card:getEffectiveId() or nil
end

ai_skill_activate.y_shenzhi = function(self)
    return play_conversion(self, "y_shenzhi", {
        kind = "Peach",
        gate = function(ai)
            local hp = number(ai.player:getHp())
            local hand = number(ai.player:getHandcardNum())
            if hp == nil or hand == nil then return nil end
            if hp < 0 then hp = 0 end
            return ai.player:isWounded() == true and hand > hp
        end
    })
end

sgs.ai_cardneed.y_shenzhi = function(to)
    local hand, hp = number(to:getHandcardNum()), number(to:getHp())
    if hand == nil or hp == nil then return nil end
    return hand < hp
end

sgs.ai_skill_invoke.y_shushen = function(self)
    if not self.friends_noself or not self.enemies then return nil end
    if #self.friends_noself > 0 then return true end
    for _, enemy in ipairs(self.enemies) do
        if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then return true end
    end
    return false
end

sgs.ai_skill_playerchosen.y_shushen = function(self)
    if not self.friends_noself or not self.enemies then return nil end
    local friends = self:sort(self.friends_noself, "defense")
    if not friends then return nil end
    for _, friend in ipairs(friends) do
        local draw = self:canDraw(friend, self.player)
        if draw == nil then return nil end
        if draw and not (friend:hasSkill("kongcheng") and friend:isKongcheng()) then
            return friend
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then return enemy end
    end
end

sgs.ai_skill_invoke.y_baiyi = function(self)
    local nude = self.player:isNude()
    if nude == nil then return nil end
    return not nude
end

sgs.ai_skill_invoke.y_baiyier = function(self)
    local players = self:findPlayerToDiscard("hej", true, false, nil, true)
    if not players then return nil end
    return #players > 0
end

sgs.ai_skill_playerchosen.y_baiyi = function(self)
    if not self.friends or not self.enemies then return nil end
    local players = self:findPlayerToDiscard("hej", true, false, nil, true)
    if players and players[1] then return players[1] end
    for _, friend in ipairs(self.friends) do
        local indulgence = friend:containsTrick("indulgence")
        local shortage = friend:containsTrick("supply_shortage")
        if indulgence or shortage then return friend end
        if friend:containsTrick("lightning") then
            for _, enemy in ipairs(self.enemies) do
                if enemy:hasSkill("guicai") or enemy:hasSkill("guidao") or enemy:hasSkill("guanxing") then
                    return friend
                end
            end
        end
    end
    local enemies = self:sort(self.enemies, "defense")
    if not enemies then return nil end
    for _, enemy in ipairs(enemies) do
        if enemy:isNude() == false then return enemy end
    end
end

sgs.ai_skill_invoke.y_yuanjiu = function(self, data)
    local pile = self.player:getPile("y_yuanjiuPile")
    if pile then
        for _, left in ipairs(pile) do
            for _, right in ipairs(pile) do
                if left ~= right and left:getNumber() == right:getNumber() then return true end
            end
        end
    end
    local dying = self:getDecisionContext().dying
    if type(dying) ~= "table" or not dying.who then
        ai_unsupported("y_yuanjiu dying target is not projected", "y_yuanjiu")
    end
    local who = dying.who
    local friend = self:isFriend(who)
    if friend == nil or type(self.askForSinglePeach) ~= "function" then return nil end
    return self:askForSinglePeach(who) == true and friend == true
end

ai_skill_activate.y_jiefan = function(self)
    if not relations(self, "y_jiefan") then return nil end
    local function use_on(player)
        return skill_plan(self, "y_jiefan", {}, {player:objectName()})
    end
    for _, friend in ipairs(self.friends) do
        local discard = self:doDisCard(friend, "he")
        local draw = self:canDraw(friend, self.player)
        if discard == nil or draw == nil then return nil end
        if discard and draw then return use_on(friend) end
    end
    for _, friend in ipairs(self.friends) do
        local tuntian = self:hasTuntianEffect(friend)
        local draw = self:canDraw(friend, self.player)
        if tuntian == nil or draw == nil then return nil end
        if tuntian and draw then return use_on(friend) end
    end
    for _, enemy in ipairs(self.enemies) do
        local equips = enemy:getEquips()
        if not equips then return nil end
        if #equips > 0 and self:doDisCard(enemy, "e") then return use_on(enemy) end
    end
    local discard_self = self.player:canDiscard(self.player, "he")
    if discard_self == nil then return nil end
    if discard_self then return use_on(self.player) end
    return nil
end

sgs.ai_skill_choice.y_jiefan = function()
    return "draw"
end

ai_skill_activate.y_huanshi = function(self)
    if not relations(self, "y_huanshi") then return nil end
    local friends = {}
    for _, friend in ipairs(self.friends_noself) do
        if friend:isKongcheng() == false then friends[#friends + 1] = friend end
    end
    if #friends >= 2 then
        return skill_plan(self, "y_huanshi", {}, {friends[1]:objectName(), friends[2]:objectName()})
    end
    if #friends == 1 then
        local enemies = self:sort(self.enemies, "defense")
        if not enemies then return nil end
        for _, enemy in ipairs(enemies) do
            if enemy:isKongcheng() == false then
                return skill_plan(self, "y_huanshi", {}, {enemy:objectName(), friends[1]:objectName()})
            end
        end
    end
    return nil
end

ai_skill_use["@@y_hongyuan"] = function(self)
    if not self.friends then return nil end
    local targets = {}
    for _, friend in ipairs(self.friends) do
        local ranged = self.player:inMyAttackRange(friend)
        local left = type(self.player.getSeat) == "function" and self.player:getSeat() or nil
        local right = type(friend.getSeat) == "function" and friend:getSeat() or nil
        if ranged == nil and (type(left) ~= "number" or type(right) ~= "number") then return nil end
        if ranged or (type(left) == "number" and left == right) then
            targets[#targets + 1] = friend:objectName()
        end
    end
    if #targets == 0 then return {kind = "pass"} end
    local plan = skill_plan(self, "y_hongyuan", {}, targets)
    return plan or {kind = "pass"}
end

sgs.ai_skill_invoke.y_zishou = function(self)
    local lost = number(self.player:getLostHp())
    local hp = number(self.player:getHp())
    local cards = self.player:getHandcards()
    if lost == nil or hp == nil or not cards then return nil end
    local jink, slash, nullification, peach = 0, 0, 0, 0
    for _, card in ipairs(cards) do
        if card:isKindOf("Jink") then jink = jink + 1
        elseif card:isKindOf("Slash") then slash = slash + 1
        elseif card:isKindOf("Nullification") then nullification = nullification + 1
        elseif card:isKindOf("Peach") then peach = peach + 1
        end
    end
    local basic = jink + slash + nullification
    if lost >= 2 then return true end
    if lost == 1 then
        if slash > 0 then return hp >= basic end
        return hp > basic
    end
    if slash > 0 then return (hp - (basic + peach)) >= 2 end
    return (hp - (basic + peach)) > 2
end

ai_skill_use["@@y_yangzheng"] = function(self)
    if self.player:getMark("y_yzRec") == 1 then return {kind = "pass"} end
    if not self.friends_noself or #self.friends_noself < 1 then return {kind = "pass"} end
    local count = number(self.player:getHandcardNum())
    local hp = number(self.player:getHp())
    if count == nil or hp == nil or count < hp then return {kind = "pass"} end
    local cards = self.player:getCards("h")
    if not cards then return nil end
    local sorted = self:sortByUseValue(cards, true)
    if not sorted then return nil end
    local card, friend = self:getCardNeedPlayer(sorted)
    if not (card and friend) then
        local friends = self:sort(self.friends_noself, "defense")
        if not friends then return nil end
        for _, candidate in ipairs(friends) do
            local skip = self:willSkipPlayPhase(candidate)
            local draw = self:canDraw(candidate, self.player)
            if skip == nil or draw == nil then return nil end
            if not skip and draw then
                card, friend = sorted[1], candidate
                break
            end
        end
    end
    if not (card and friend) then return {kind = "pass"} end
    return skill_plan(self, "y_yangzheng", {card:getEffectiveId()}, {friend:objectName()})
        or {kind = "pass"}
end

ai_skill_activate.y_fenying = function(self)
    if not relations(self, "y_fenying") then return nil end
    local enemies = self:sort(self.enemies, "defense")
    if not enemies then return nil end
    local mine = number(self.player:getHandcardNum())
    local hp = number(self.player:getHp())
    if mine == nil or hp == nil then return nil end
    for _, enemy in ipairs(enemies) do
        local theirs = number(enemy:getHandcardNum())
        local pindian = self.player:canPindian(enemy)
        if theirs == nil or pindian == nil then return nil end
        local fired, effective = AIUnsupported.capture(function()
            return self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player)
        end)
        local hurt = self:cantbeHurt(enemy)
        if not fired or effective == nil or hurt == nil then return nil end
        if not enemy:isKongcheng() and theirs < mine and pindian and effective and not hurt
            and (theirs < 3 or ((mine - hp) - theirs) > -1) then
            local ids = low_cards(self, "he", theirs)
            if ids and #ids == theirs then
                return skill_plan(self, "y_fenying", ids, {enemy:objectName()})
            end
        end
    end
    return nil
end

sgs.ai_skill_invoke.y_fenying = true

sgs.ai_skill_invoke.y_dushi = function(self)
    local hand = number(self.player:getHandcardNum())
    local hp = number(self.player:getHp())
    if hand == nil or hp == nil then return nil end
    if hand < hp then return true end
    if not self.enemies or not self.friends then return nil end
    local players = self:findPlayerToDiscard("hej", true, false, nil, true)
    if players and players[1] then return true end
    for _, enemy in ipairs(self.enemies) do
        if enemy:isNude() == false then return true end
    end
    for _, friend in ipairs(self.friends) do
        if friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage") then
            return true
        end
        if friend:containsTrick("lightning") then
            for _, other in ipairs(self.friends) do
                if other:hasSkill("guicai") or other:hasSkill("guidao") or other:hasSkill("guanxing") then
                    return false
                end
            end
            return true
        end
    end
    return false
end

sgs.ai_slash_prohibit.y_dushi = function(self, from, to)
    to = to or from
    if not to then return nil end
    local hand, hp = number(to:getHandcardNum()), number(to:getHp())
    if hand == nil or hp == nil then return nil end
    if hand == hp then return false end
    if hand > hp and hp > 1 then return true end
    return false
end

sgs.ai_skill_playerchosen.y_dushi = function(self, targets)
    if not self.friends or not self.enemies then return nil end
    for _, target in ipairs(targets) do
        local friend = self:isFriend(target)
        if friend == nil then return nil end
        if friend then
            if target:containsTrick("indulgence") or target:containsTrick("supply_shortage") then
                return target
            end
            if target:containsTrick("lightning") then
                local allowed = true
                for _, other in ipairs(self.friends) do
                    if other:hasSkill("guicai") or other:hasSkill("guidao") or other:hasSkill("guanxing") then
                        allowed = false
                    end
                end
                if allowed then return target end
            end
        elseif self:isEnemy(target) and number(target:getHandcardNum()) == 1 and self.player:isWounded() then
            return target
        end
    end
    local enemies = self:sort(self.enemies, "defense")
    if not enemies then return nil end
    for _, enemy in ipairs(enemies) do
        if enemy:isNude() == false then return enemy end
    end
end

sgs.ai_skill_invoke.y_zhensha = function(self, data)
    local player = data:toPlayer()
    if not player then return nil end
    return self:isEnemy(player)
end

sgs.ai_skill_invoke.y_shipo = function(self)
    if not self.enemies then return nil end
    for _, enemy in ipairs(self.enemies) do
        if enemy:isKongcheng() == false then return true end
    end
    return false
end

sgs.ai_skill_playerchosen.y_shipo = function(self)
    if not self.enemies then return nil end
    local enemies = self:sort(self.enemies, "defense")
    if not enemies then return nil end
    for _, enemy in ipairs(enemies) do
        if enemy:isKongcheng() == false then return enemy end
    end
end

sgs.ai_slash_prohibit.y_shipo = function(self, from, to)
    to = to or from
    local hp = to and number(to:getHp()) or nil
    local peach = self:getCardsNum("Peach")
    local analeptic = self:getCardsNum("Analeptic")
    local jink = self:getCardsNum("Jink")
    local hand = number(self.player:getHandcardNum())
    if hp == nil or peach == nil or analeptic == nil or jink == nil or hand == nil then return nil end
    if hp == 1 then return peach + analeptic > 0 end
    return jink > 0 and (hand - jink) < 2
end

ai_skill_activate.y_wuji = function(self)
    local add_jink = self.player:hasFlag("addjink")
    local add_tar = self.player:hasFlag("addtar")
    local add_range = self.player:hasFlag("addrange")
    if add_jink == nil or add_tar == nil or add_range == nil then return nil end
    if add_jink and add_tar and add_range then return nil end
    if not relations(self, "y_wuji") then return nil end
    local slash_count = self:getCardsNum("Slash")
    if slash_count == nil or slash_count <= 0 then return nil end
    local slash = self:getCard("Slash")
    if not slash then return nil end
    local plan, status = self:tryUseCard(slash)
    if status == "unsupported" or not plan or not plan.to or plan.to:isEmpty() then return nil end
    local choice = ""
    if plan.to:length() > 1 and not self.player:hasFlag("addtar") then choice = "addtar" end
    local range = number(self.player:getAttackRange())
    if choice == "" and range and not self.player:hasFlag("addrange") then
        for _, target in ipairs(plan.to) do
            local distance = self.player:distanceTo(target)
            local inside = self.player:inMyAttackRange(target)
            if type(distance) == "number" and inside == false and distance <= range + 1 then
                choice = "addrange"
                break
            end
        end
    end
    if choice == "" and not self.player:hasFlag("addjink") then choice = "addjink" end
    if choice == "" then return nil end
    local cards = self.player:getCards("h")
    if not cards then return nil end
    local sorted = self:sortByUseValue(cards, true)
    if not sorted then return nil end
    for _, card in ipairs(sorted) do
        if not card:isKindOf("Peach") and (slash_count > 1 or not card:isKindOf("Slash")) then
            self:remember("shadow.y_wuji", choice)
            return skill_plan(self, "y_wuji", {card:getEffectiveId()}, {})
        end
    end
    return nil
end

sgs.ai_skill_choice.y_wujicard = function(self, choices)
    local saved = self:recall("shadow.y_wuji")
    self:remember("shadow.y_wuji", nil)
    if type(saved) == "string" and saved ~= "" and string.find("+" .. choices .. "+", "+" .. saved .. "+", 1, true) then
        return saved
    end
    return nil
end

sgs.ai_skill_invoke.y_laoyue = true

sgs.ai_cardneed.y_wuji = function(to, card)
    if type(sgs.ai_cardneed.slash) == "function" then return sgs.ai_cardneed.slash(to, card) end
    return card and card:isKindOf("Slash") or false
end

ai_skill_activate.y_shenzhu = function(self)
    if self.player:isKongcheng() then return nil end
    local cards = self.player:getCards("h")
    if not cards then return nil end
    local slash
    for _, card in ipairs(cards) do
        if card:isKindOf("Slash") then slash = card break end
    end
    if not slash then return nil end
    local sorted = self:sortByKeepValue(cards, true)
    if sorted then
        for _, card in ipairs(sorted) do
            if card:isKindOf("Slash") then slash = card break end
        end
    end
    return skill_plan(self, "y_shenzhu", {slash:getEffectiveId()}, {})
end

sgs.ai_skill_askforag.y_shenzhu = function(self, card_ids)
    if type(card_ids) ~= "table" then return nil end
    if not self.friends then return nil end
    local function card_at(id)
        return self:getChoiceCard(id)
    end
    for _, id in ipairs(card_ids) do
        local card = card_at(id)
        if card and card:isKindOf("EquipCard") then
            local slot = equip_slot(card)
            for _, friend in ipairs(self.friends) do
                local empty = empty_slot(friend, slot)
                local lose = self:loseEquipEffect(friend)
                local need = friend:hasSkills(sgs.need_equip_skill)
                if empty and (lose == true or need == true) then return id end
            end
            for _, friend in ipairs(self.friends) do
                if empty_slot(friend, slot) then return id end
            end
        end
    end
    local chosen
    for _, id in ipairs(card_ids) do
        local card = card_at(id)
        if card and card:isKindOf("FireSlash") then return id end
        if card and card:isKindOf("ThunderSlash") then chosen = id
        elseif card and card:isKindOf("Slash") and not (card:isKindOf("ThunderSlash")) then chosen = id end
    end
    return chosen
end

sgs.ai_cardneed.y_shenzhu = sgs.ai_cardneed.y_wuji

sgs.ai_skill_playerchosen.y_shenzhu = function(self, targets)
    for _, target in ipairs(targets) do
        if self:isFriend(target) and (self:loseEquipEffect(target) or target:hasSkills(sgs.need_equip_skill)) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if self:isFriend(target) then return target end
    end
end

sgs.ai_skill_invoke.y_bailian = true

sgs.ai_skill_playerchosen.y_bailian = function(self, targets)
    for _, target in ipairs(targets) do
        if self:isFriend(target) and self:loseEquipEffect(target) then return target end
    end
    for _, target in ipairs(targets) do
        if self:isFriend(target) and self:doDisCard(target, "e") then return target end
    end
    for _, target in ipairs(targets) do
        if self:isEnemy(target) and self:doDisCard(target, "e") then return target end
    end
end

sgs.ai_skill_invoke.y_caipei = function(self)
    if not self.friends then return nil end
    local peach = self:getCardsNum("Peach")
    local hand = number(self.player:getHandcardNum())
    if peach == nil or hand == nil then return nil end
    for _, friend in ipairs(self.friends) do
        if friend:isKongcheng() == false then return peach < hand end
    end
    return false
end

sgs.ai_skill_playerchosen.y_caipei = function(self)
    local current = self.room:getCurrent()
    if current and self:isFriend(current) and self:canDraw(current, self.player) then return current end
    local drawn = self:findPlayerToDraw(true, 1)
    if drawn then return drawn end
    return self.player
end

sgs.ai_cardneed.y_caipei = function(to, card)
    return card and card:isKindOf("TrickCard") or false
end

sgs.ai_skill_invoke.y_kongzhen = function(self, data)
    local player = data:toPlayer()
    if not player then return nil end
    return self:isFriend(player)
end

sgs.ai_skill_invoke.y_huaiju = function()
    ai_unsupported("y_huaiju move context is not projected", "y_huaiju")
end

ai_skill_use["@@y_huntian"] = function(self)
    local cards = self.player:getHandcards()
    local next_player = self.player:getNextAlive()
    if not cards or not next_player then return nil end
    local sorted = self:sortByUseValue(cards, true)
    if not sorted then return nil end
    local function suit_match(player, card)
        local shortage = player:containsTrick("supply_shortage")
        local indulgence = player:containsTrick("indulgence")
        local lightning = player:containsTrick("lightning")
        if shortage == nil or indulgence == nil or lightning == nil then return nil end
        if (shortage and card:getSuit() == sgs.Card_Club)
            or (indulgence and card:getSuit() == sgs.Card_Heart)
            or (lightning and card:getSuit() ~= sgs.Card_Spade) then
            return true
        end
        return false
    end
    local chosen
    for _, card in ipairs(sorted) do
        local matched = suit_match(self.player, card)
        if matched == nil then return nil end
        if matched then chosen = card break end
    end
    if not chosen then
        local friend = self:isFriend(next_player)
        local enemy = self:isEnemy(next_player)
        if friend == nil or enemy == nil then return nil end
        for _, card in ipairs(sorted) do
            if friend and suit_match(next_player, card) then chosen = card break end
            if enemy and next_player:containsTrick("lightning") and card:getSuit() == sgs.Card_Spade then
                chosen = card
                break
            end
        end
    end
    chosen = chosen or sorted[1]
    if not chosen then return {kind = "pass"} end
    return skill_plan(self, "y_huntian", {chosen:getEffectiveId()}, {}) or {kind = "pass"}
end

sgs.ai_skill_choice.y_huntian = function(self)
    local cards = self.player:getCards("h")
    local next_player = self.player:getNextAlive()
    if not cards or not next_player then return nil end
    local heart, spade, club, not_spade, peach = false, false, false, false, 0
    for _, card in ipairs(cards) do
        local suit = card:getSuit()
        if suit == sgs.Card_Heart then heart = true end
        if suit == sgs.Card_Spade then spade = true else not_spade = true end
        if suit == sgs.Card_Club then club = true end
        if card:isKindOf("Peach") then peach = peach + 1 end
    end
    local function blocked(player)
        return player:containsTrick("supply_shortage") or player:containsTrick("indulgence")
            or player:containsTrick("lightning")
    end
    if (self.player:containsTrick("supply_shortage") and club)
        or (self.player:containsTrick("indulgence") and heart)
        or (self.player:containsTrick("lightning") and not_spade) then
        return "1"
    end
    if number(self.player:getHandcardNum()) == peach then
        if self.player:isWounded() then return "2" end
        if self:isFriend(next_player) and next_player:isWounded()
            and not next_player:containsTrick("supply_shortage")
            and not next_player:containsTrick("indulgence") then
            return "4"
        end
        return "2"
    end
    if self:isFriend(next_player) then
        if next_player:containsTrick("supply_shortage") then return club and "3" or "5" end
        if next_player:containsTrick("indulgence") then return heart and "3" or "2" end
        if next_player:containsTrick("lightning") then return not_spade and "3" or "5" end
        return "5"
    end
    if self:isEnemy(next_player) then
        if next_player:containsTrick("lightning") then return spade and "3" or "5" end
        return "4"
    end
    if blocked(self.player) == nil then return nil end
    return "4"
end

sgs.ai_skill_invoke.y_huntian2 = true

sgs.ai_skill_choice.y_huntian2 = function(self, choices, data)
    local player = data:toPlayer()
    if not player then return nil end
    local friend = self:isFriend(player)
    if friend == nil then return nil end
    return friend and "htdraw" or "htdiscard"
end

sgs.ai_skill_invoke.y_weiji = function(self)
    local max_hp = number(self.player:getMaxHp())
    if max_hp == nil then return nil end
    if max_hp == 1 then
        local peach = self:getCardsNum("Peach")
        local wine = self:getCardsNum("Analeptic")
        if peach == nil or wine == nil then return nil end
        return peach > 0 or wine > 0
    end
    return max_hp > 1
end

sgs.ai_skill_playerchosen.y_weiji = function(self)
    if not self.friends then return nil end
    local hp = number(self.player:getHp())
    if hp == nil then return nil end
    local drawn = self:findPlayerToDraw(true, hp)
    if drawn then return drawn end
    local friends = self:sort(self.friends, "defense")
    if not friends then return nil end
    local chosen, lowest = self.player, 9
    for _, friend in ipairs(friends) do
        local friend_hp = number(friend:getHp())
        if friend_hp == nil then return nil end
        local indulgence = friend:containsTrick("indulgence")
        local empty = friend:isKongcheng()
        local kongcheng = friend:hasSkill("kongcheng") or friend:hasSkill("kongzhen")
        if not indulgence and not (kongcheng and empty) and friend_hp < lowest then
            lowest = friend_hp
            chosen = friend
        end
    end
    return chosen
end

ai_skill_activate.y_jiushang = function(self)
    return play_conversion(self, "y_jiushang", {
        kind = "Analeptic",
        gate = function(ai)
            local max_hp = number(ai.player:getMaxHp())
            local lost = number(ai.player:getLostHp())
            if max_hp == nil or lost == nil then return nil end
            return max_hp > 1 and lost > 0
        end
    })
end

ai_skill_activate.y_xiangxi = function(self)
    if not relations(self, "y_xiangxi") or #self.friends_noself == 0 then return nil end
    local friends = self:sort(self.friends_noself, "handcard")
    if not friends then return nil end
    local mine = number(self.player:getHandcardNum())
    local hp = number(self.player:getHp())
    local kegou = self.player:getMark("y_kegou")
    if mine == nil or hp == nil or type(kegou) ~= "number" then return nil end
    local target
    local delay, equip, wounded, other
    for _, friend in ipairs(friends) do
        local shortage = friend:containsTrick("supply_shortage")
        local indulgence = friend:containsTrick("indulgence")
        local equips = friend:getEquips()
        local theirs = number(friend:getHandcardNum())
        if shortage == nil or indulgence == nil or not equips or theirs == nil then return nil end
        if (shortage or indulgence) and (mine - hp) < 2 then delay = friend
        elseif #equips > 0 and self:loseEquipEffect(friend) then equip = friend
        elseif kegou ~= 1 and mine - hp > 1 and theirs < mine then equip = friend
        elseif self.player:isWounded() then wounded = friend
        else other = friend
        end
    end
    target = delay or equip or wounded or other
    local overflow = self:getOverflow()
    if not target and type(overflow) == "number" and overflow > 0 then
        for _, friend in ipairs(friends) do
            if number(friend:getHandcardNum()) < mine then target = friend break end
        end
    end
    if not target then return nil end
    return skill_plan(self, "y_xiangxi", {}, {target:objectName()})
end

sgs.ai_skill_choice.y_xiangxi = function(self, choices, data)
    local target = data:toPlayer()
    if not target then return nil end
    local friend = self:isFriend(target)
    local mine = number(self.player:getHandcardNum())
    local theirs = number(target:getHandcardNum())
    if friend == nil or mine == nil or theirs == nil then return nil end
    if friend and self.player:isWounded() and math.abs(theirs - mine) < 2 then return "j" end
    if theirs - mine > 1 then return "h" end
    if self.player:containsTrick("supply_shortage") or self.player:containsTrick("indulgence") then return "j" end
    if friend and (target:containsTrick("supply_shortage") or target:containsTrick("indulgence")) then
        return "j"
    end
    local self_equips = self.player:getEquips()
    local target_equips = target:getEquips()
    if not self_equips or not target_equips then return nil end
    if (self:loseEquipEffect(self.player) and #self_equips > 0)
        or (friend and self:loseEquipEffect(target) and #target_equips > 0) then
        return "e"
    end
    if self:isWeak() then return "j" end
    return "h"
end

sgs.ai_skill_invoke.y_kegou = true
sgs.ai_target_revises.y_kegou = function(to, card)
    return card and card:isKindOf("Indulgence") or false
end

sgs.ai_skill_invoke.y_yingzi = true

sgs.ai_skill_invoke.y_shouju = function()
    ai_unsupported("y_shouju card id is not projected", "y_shouju")
end
sgs.ai_skill_playerchosen.y_shouju = function()
    ai_unsupported("y_shouju shown card is not projected", "y_shouju")
end
sgs.ai_skill_cardask.y_shouju = function()
    ai_unsupported("y_shouju card ask is not projected", "y_shouju")
end

sgs.ai_skill_invoke.y_wenliang = function(self, data)
    local player = data:toPlayer()
    if not player then return nil end
    local friend = self:isFriend(player)
    local enemy = self:isEnemy(player)
    if friend == nil or enemy == nil then return nil end
    local armor = player:getArmor()
    if friend then
        if armor and armor:objectName() == "silverlion" and player:isWounded() then return true end
        if not (armor and armor:isKindOf("EightDiagram")) then
            local hand = number(player:getHandcardNum())
            local hp = number(player:getHp())
            if hand == nil or hp == nil then return nil end
            if hand < 2 and hp == 1 then return true end
            local cards = self.player:getCards("h")
            if not cards then return nil end
            for _, card in ipairs(cards) do
                if not card:isKindOf("Peach") then return true end
            end
        else
            return player:isKongcheng() and number(player:getHp()) == 1
        end
    elseif enemy then
        local hand = number(player:getHandcardNum())
        local hp = number(player:getHp())
        if hand == nil or hp == nil then return nil end
        if hp == 1 or hand <= 1 then return false end
        if (armor and (armor:isKindOf("EightDiagram") or armor:isKindOf("RenwangShield")))
            or player:getDefensiveHorse() or player:getWeapon() or player:getOffensiveHorse() then
            return true
        end
    end
    return false
end

sgs.ai_skill_invoke.y_duoqi = true

sgs.ai_skill_invoke.y_youfang = function()
    ai_unsupported("y_youfang move context is not projected", "y_youfang")
end
sgs.ai_skill_choice.y_youfang = function()
    ai_unsupported("y_youfang move context is not projected", "y_youfang")
end
sgs.ai_skill_invoke.y_zhixi = function()
    ai_unsupported("y_zhixi move context is not projected", "y_zhixi")
end

sgs.ai_skill_invoke.y_xiaoyi = true
sgs.ai_skill_playerchosen.y_xiaoyi = function()
    ai_unsupported("y_xiaoyi card tag is not projected", "y_xiaoyi")
end

ai_skill_activate.y_lianzhu = function(self)
    if not relations(self, "y_lianzhu") then return nil end
    self:updatePlayers()
    local targets = {}
    for _, friend in ipairs(self.friends) do targets[#targets + 1] = friend:objectName() end
    if #targets == 0 then return nil end
    local cards = self.player:getCards("h")
    if not cards then return nil end
    local jinks = self:getCardsNum("Jink")
    local wines = self:getCardsNum("Analeptic")
    if jinks == nil or wines == nil then return nil end
    local ids = {}
    for _, card in ipairs(cards) do
        local keep = card:isKindOf("Peach") or card:isKindOf("Duel")
            or card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")
            or (jinks == 1 and card:isKindOf("Jink"))
            or (wines == 1 and card:isKindOf("Analeptic"))
        if not keep then
            ids[#ids + 1] = card:getEffectiveId()
            if #ids >= #targets then break end
        end
    end
    if #ids == 0 or #ids ~= #targets then return nil end
    return skill_plan(self, "y_lianzhu", ids, targets)
end

sgs.ai_skill_invoke.y_fanjin = true
sgs.ai_skill_playerchosen.y_fanjin = function()
    ai_unsupported("y_fanjin property list is not projected", "y_fanjin")
end
sgs.ai_skill_cardchosen.y_fanjin = function()
    ai_unsupported("y_fanjin property list is not projected", "y_fanjin")
end

ai_skill_use["@@y_xianzhou"] = function(self)
    local damage = self:getDecisionContext().damage
    if type(damage) ~= "table" or not damage.from then
        ai_unsupported("y_xianzhou damage is not projected", "y_xianzhou")
    end
    local from = damage.from
    if from:isAlive() == false then return {kind = "pass"} end
    local amount = number(damage.damage)
    local hp = number(self.player:getHp())
    local cards = self.player:getCards("he")
    if amount == nil or hp == nil or not cards then return nil end
    local sorted = self:sortByKeepValue(cards)
    if not sorted then return nil end
    local lose = self:needToLoseHp(self.player, from, damage.card)
    local effective = self:damageIsEffective(self.player, damage.nature, from)
    if lose == nil or effective == nil then return nil end
    if lose or not effective then return {kind = "pass"} end
    local friend = self:isFriend(from)
    if friend == nil then return nil end
    local ids = {}
    local function take(card)
        if #ids >= hp then return end
        ids[#ids + 1] = card:getEffectiveId()
    end
    if friend then
        for _, card in ipairs(sorted) do take(card) end
    else
        local heavy = self:hasHeavyDamage(from, damage.card, self.player, damage.nature)
        local throw = self:needToThrowCard(from)
        if heavy == nil or throw == nil then return nil end
        local urgent = amount > 1 or heavy or throw or hp <= 1
        for _, card in ipairs(sorted) do
            if urgent then
                if not card:isKindOf("Peach") then take(card) end
            elseif self:keepCard(card) == false then
                take(card)
            end
        end
    end
    if #ids ~= hp then return {kind = "pass"} end
    return skill_plan(self, "y_xianzhou", ids, {}) or {kind = "pass"}
end

sgs.ai_skill_invoke.y_huiyu = function(self, data)
    local use = data:toCardUse()
    local card = use and use.card
    local from = use and use.from
    if not card or not from or not use.to then return nil end
    if not self.enemies then return nil end
    local function usable(target)
        if type(self.player.canSlash) ~= "function" then return nil end
        local slash = self.player:canSlash(target)
        local banned = self:slashProhibit(card, target, self.player)
        local effective = self:slashIsEffective(card, target, self.player)
        if slash == nil or banned == nil or effective == nil then return nil end
        return slash and not banned and effective
    end
    if self.player:objectName() == from:objectName() then
        for _, target in ipairs(use.to) do
            local ok = usable(target)
            if ok == nil then return nil end
            if self:isFriend(target) and ok and self:dontHurt(target, self.player) then return false end
        end
        for _, target in ipairs(use.to) do
            local ok = usable(target)
            local good = self:isGoodTarget(target, self.enemies, card)
            if ok == nil or good == nil then return nil end
            if self:isEnemy(target) and ok and good then return true end
        end
        return true
    end
    local lose = self:needToLoseHp(self.player, from, card)
    if lose == nil then return nil end
    if lose then return true end
    for _, target in ipairs(use.to) do
        local ok = usable(target)
        local good = self:isGoodTarget(target, self.enemies, card)
        if ok == nil or good == nil then return nil end
        if self:isEnemy(target) and ok and good then return true end
    end
    return false
end
