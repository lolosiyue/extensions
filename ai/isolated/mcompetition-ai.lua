-- mcompetition 隔離 AI。SmartAI 相等函式在 smart-ai-functions.lua，
-- 本檔只擴充技能名單與各技能 handler，不把武將判斷寫進基礎層。
-- 舊版 lua/ai/mcompetition-ai.lua 仍留在 gameplay VM。
-- 字串 data、房間 tag、cloneCard 都沒有投影：那些詢問回 unsupported，
-- 不把缺資料猜成否或第一選項。

sgs.append_skill_list("recover_hp_skill", "tianlai")
sgs.append_skill_list("recover_hp_skill", "lingyin")
sgs.append_skill_list("exclusive_skill", "jilian")
sgs.append_skill_list("double_slash_skill", "luahuojianzhuixi")
sgs.append_skill_list("double_slash_skill", "luabaozhahuohua")

sgs.ai_use_priority = sgs.ai_use_priority or {}
sgs.ai_card_intention = sgs.ai_card_intention or {}
sgs.ai_cardneed = sgs.ai_cardneed or {}
sgs.dynamic_value = sgs.dynamic_value or {}
sgs.dynamic_value.benefit = sgs.dynamic_value.benefit or {}

sgs.ai_cardneed.zhuanshan = sgs.ai_cardneed.bignumber
sgs.ai_cardneed.luabaozhahuohua = sgs.ai_cardneed.slash
sgs.ai_cardneed.langmanpaotai = sgs.ai_cardneed.slash
sgs.ai_use_priority.caoduoCard = (sgs.ai_use_priority.Slash or 2.6) + 1
sgs.ai_use_priority.tianlaiCard = 4.2
sgs.ai_use_priority.dongxi = 4.2
sgs.ai_use_priority.zzy_weimianCard = 4.2
sgs.ai_use_priority.luahuojianzhuixiCard = (sgs.ai_use_priority.Slash or 2.6) - 0.1
sgs.ai_use_priority.lingyincard = 4.2
sgs.ai_card_intention.tianlaiCard = -100
sgs.ai_card_intention.zzy_weimianCard = -100
sgs.ai_card_intention.lingyincard = -100
sgs.ai_card_intention.zhanmeiqiyuecard = -50
sgs.dynamic_value.benefit.tianlaiCard = true
sgs.dynamic_value.benefit.lingyincard = true
if sgs.ai_card_intention.Collateral ~= nil then
    sgs.ai_card_intention.caoduoCard = sgs.ai_card_intention.Collateral
end

local function probed(request, name)
    local action = type(request) == "table" and request.skill_action or nil
    return type(action) == "table" and action.activation_skill == name
end

local function unknown_activate(request, name, reason)
    if probed(request, name) then ai_unsupported(reason, name) end
    return nil
end

local function skill_answer(self, name, cards, targets, user_string)
    local action = self:getSkillAction(name)
    if not action or type(action.isValid) ~= "function" or not action:isValid() then
        return nil
    end
    local answer = {
        kind = "use_card",
        skill_action = action:toAnswer(),
        cards = cards or {},
        targets = targets or {}
    }
    if user_string then answer.user_string = user_string end
    return answer
end

local function players_of(self, options, key)
    if type(options) ~= "table" or options.candidates_complete ~= true then
        ai_unsupported(key .. " candidates are incomplete", key)
    end
    local result = {}
    for _, name in ipairs(options.players or {}) do
        local player = self.room:findPlayerByObjectName(name)
        if not player then ai_unsupported(key .. " candidate is not visible", key) end
        result[#result + 1] = player
    end
    return result
end

local function choose(options, wanted)
    for _, value in ipairs(options and options.choices or {}) do
        if value == wanted then return value end
    end
end

local function payment_card(self)
    local cards = self.player:getHandcards()
    if not cards then return nil, "unknown" end
    if #cards < 1 then return nil end
    local best, best_value
    for _, card in ipairs(cards) do
        local keep = self:getKeepValue(card)
        if type(keep) ~= "number" then return nil, "unknown" end
        local value = keep + (card:isRed() and 50 or 0) + (card:isKindOf("Peach") and 50 or 0)
        if not best or value < best_value then best, best_value = card, value end
    end
    return best
end

local function id_of(card, key)
    local id = card and card:getEffectiveId()
    if type(id) ~= "number" then ai_unsupported(key .. " card id is missing", key) end
    return id
end

local function lowest_ids(self, max_count, zone, key)
    local cards = self.player:getCards(zone or "he")
    if not cards then ai_unsupported(key .. " cards are not visible", key) end
    local ranked = {}
    for _, card in ipairs(cards) do
        if type(self:getKeepValue(card)) ~= "number" then
            ai_unsupported(key .. " keep value is unknown", key)
        end
        ranked[#ranked + 1] = card
    end
    table.sort(ranked, function(a, b)
        return self:getKeepValue(a) < self:getKeepValue(b)
    end)
    local ids = {}
    for _, card in ipairs(ranked) do
        if #ids >= max_count then break end
        ids[#ids + 1] = id_of(card, key)
    end
    return ids
end

local function female_player(player)
    local gender = type(player.getGender) == "function" and player:getGender() or nil
    if type(gender) ~= "number" then return nil end
    return gender == (sgs.General_Female or 2)
end

-- 神異的階段紀錄是字串 data，快照沒有這段，不能用選項順序代替。
ai_skill_invoke.shenyi = function() return true end
ai_skill_choice.shenyi = function()
    ai_unsupported("shenyi phase record is not in the decision context", "shenyi")
end

ai_skill_invoke.zhuanshan = function(self)
    local hand = self.player:getHandcardNum()
    local weak = self:isWeak()
    if type(hand) ~= "number" or weak == nil then
        ai_unsupported("zhuanshan hand or hp is unknown", "zhuanshan")
    end
    if hand <= (weak and 2 or 1) then return false end
    local current = self.room:getCurrent()
    if not current then return false end
    local friend = self:isFriend(current)
    if friend == nil then ai_unsupported("zhuanshan relation is unknown", "zhuanshan") end
    if friend then return false end
    local max_card = self:getMaxCard()
    if not max_card then ai_unsupported("zhuanshan max card is not visible", "zhuanshan") end
    local max_point = max_card:getNumber()
    if type(max_point) ~= "number" then
        ai_unsupported("zhuanshan card number is unknown", "zhuanshan")
    end
    if self.player:hasSkill("yingyang") then max_point = math.min(max_point + 3, 13) end
    local blocked = current:hasSkill("zhiji") and current:getMark("zhiji") == 0
        and current:getHandcardNum() == 1
    if not blocked then
        local enemy_card = self:getMaxCard(current)
        local enemy_point = enemy_card and enemy_card:getNumber() or 100
        if type(enemy_point) ~= "number" then
            ai_unsupported("zhuanshan enemy point is unknown", "zhuanshan")
        end
        if enemy_card and current:hasSkill("yingyang") then
            enemy_point = math.min(enemy_point + 3, 13)
        end
        if max_point > enemy_point or max_point > 10 then
            self:remember("mcompetition.zhuanshan", id_of(max_card, "zhuanshan"))
            return true
        end
    end
    local distance = current:distanceTo(self.player)
    local valuable = self:isValuableCard(max_card)
    if type(distance) ~= "number" or valuable == nil then
        ai_unsupported("zhuanshan distance or card value is unknown", "zhuanshan")
    end
    if distance == 1 and not valuable then
        self:remember("mcompetition.zhuanshan", id_of(max_card, "zhuanshan"))
        return true
    end
    return false
end

ai_skill_pindian.zhuanshan = function(self, options)
    local saved = self:recall("mcompetition.zhuanshan")
    if type(saved) ~= "number" then return nil end
    for _, id in ipairs(options and options.card_ids or {}) do
        if id == saved then return id end
    end
    return nil
end

ai_skill_playerchosen.wuqiongdewulian = function(self, options)
    local targets = players_of(self, options, "wuqiongdewulian")
    local found = self:findPlayerToDiscard("hej", true, false, targets)
    if found == nil then
        ai_unsupported("wuqiongdewulian discard target is unknown", "wuqiongdewulian")
    end
    if found[1] then return found[1]:objectName() end
    return {kind = "pass"}
end

ai_skill_activate.wuqiongdewulian = function(self, request)
    local cards = self:addHandPile("he")
    if not cards then
        return unknown_activate(request, "wuqiongdewulian", "wuqiongdewulian cards are unknown")
    end
    for _, card in ipairs(cards) do
        if card:isKindOf("Slash") then return nil end
    end
    if not self.enemies then
        return unknown_activate(request, "wuqiongdewulian", "wuqiongdewulian relation is unknown")
    end
    for _, enemy in ipairs(self.enemies) do
        local banned = self:slashProhibit(nil, enemy)
        local effective = self:slashIsEffective(nil, enemy)
        -- 原版 canSlash 第三參 false：這次不把距離當門檻，禁止出殺仍看 slashProhibit。
        local in_range = self:canSlash(self.player, enemy, nil, false)
        if banned == nil or effective == nil or in_range == nil then
            return unknown_activate(request, "wuqiongdewulian", "wuqiongdewulian slash check is unknown")
        end
        if not banned and effective and in_range then
            return skill_answer(self, "wuqiongdewulian", {}, {enemy:objectName()}, "slash")
        end
    end
    return nil
end

-- 巴比倫的目標必須在可見敵方裡，距離用攻擊範圍近似；權威端仍會重驗能否出殺。
ai_skill_use["@@Babylon"] = function(self)
    self:updatePlayers()
    if not self.enemies then
        ai_unsupported("Babylon relation is unknown", "Babylon")
    end
    local enemies = self:sort(self.enemies, "defense") or self.enemies
    local function pick(limit, use_slash_defense)
        for _, enemy in ipairs(enemies) do
            local defense = use_slash_defense and self:getDefenseSlash(enemy) or self:getDefense(enemy)
            local banned = self:slashProhibit(nil, enemy)
            local effective = self:slashIsEffective(nil, enemy)
            local good = self:isGoodTarget(enemy, self.enemies, nil)
            local in_range = self:canSlash(self.player, enemy, nil, false)
            if defense == nil or banned == nil or effective == nil or good == nil or in_range == nil then
                ai_unsupported("Babylon target check is unknown", "Babylon")
            end
            if in_range and not banned and effective and good and defense < limit then
                return {targets = {enemy:objectName()}}
            end
        end
    end
    return pick(6, true) or pick(8, false) or {kind = "pass"}
end

ai_skill_askforag.Babylon = function(self, options)
    local cards = {}
    for _, id in ipairs(options and options.card_ids or {}) do
        local card = self:getChoiceCard(id)
        if not card then ai_unsupported("Babylon choice card is not visible", "Babylon") end
        if type(self:getUseValue(card)) ~= "number" then
            ai_unsupported("Babylon card value is unknown", "Babylon")
        end
        cards[#cards + 1] = card
    end
    table.sort(cards, function(a, b) return self:getUseValue(a) < self:getUseValue(b) end)
    if cards[1] then return id_of(cards[1], "Babylon") end
    return {kind = "pass"}
end

ai_skill_playerchosen.zhisimoyan = function(self, options)
    local targets = self:sort(players_of(self, options, "zhisimoyan"), "handcard")
    if not targets then ai_unsupported("zhisimoyan hand sort is unknown", "zhisimoyan") end
    for _, enemy in ipairs(targets) do
        local hostile = self:isEnemy(enemy)
        if hostile == nil then ai_unsupported("zhisimoyan relation is unknown", "zhisimoyan") end
        if hostile and not enemy:isKongcheng() then
            local good = self:isGoodTarget(enemy, self.enemies, nil)
            local hurt = self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player)
            local level = self:objectiveLevel(enemy)
            local safe = self:cantbeHurt(enemy)
            if good == nil or hurt == nil or type(level) ~= "number" or safe == nil then
                ai_unsupported("zhisimoyan target check is unknown", "zhisimoyan")
            end
            if good and hurt and level > 3 and not safe then return enemy:objectName() end
        end
    end
    return {kind = "pass"}
end

-- 標記裡的牌與房間 tag 目標沒有進快照。標記已存在時不能把傷害加成當成 0。
sgs.ai_ajustdamage_from = sgs.ai_ajustdamage_from or {}
sgs.ai_ajustdamage_from.zhisimoyan = function(_, from)
    if from and from:getMark("zhisimoyan") > 0 then return "unknown" end
end

ai_skill_choice.zhisimoyan = function(self, options)
    local items = options and options.choices or {}
    if #items == 1 then return items[1] end
    if choose(options, "zhisimoyan_get") then return "zhisimoyan_get" end
    local source = self:getDecisionData():toPlayer()
    if choose(options, "zhisimoyan_damage") then
        if not source then ai_unsupported("zhisimoyan source is missing", "zhisimoyan") end
        local level = self:objectiveLevel(source)
        local safe = self:cantbeHurt(source)
        if type(level) ~= "number" or safe == nil then
            ai_unsupported("zhisimoyan damage choice is unknown", "zhisimoyan")
        end
        if level > 3 and not safe then return "zhisimoyan_damage" end
    end
    return choose(options, "cancel") or items[1]
end

ai_skill_activate.zhiluan = function(self, request)
    if self.player:isKongcheng() then return nil end
    if not self.enemies or not self.friends_noself then
        return unknown_activate(request, "zhiluan", "zhiluan relation is unknown")
    end
    local function status(player)
        local manjuan = self:hasManjuanEffect(player)
        local tuntian = self:hasTuntianEffect(player, true)
        local phase = player:getPhase()
        if manjuan == nil or tuntian == nil or phase == nil then return nil end
        return manjuan, tuntian, phase
    end
    local function take(player)
        return skill_answer(self, "zhiluan", {}, {player:objectName()})
    end
    for _, friend in ipairs(self.friends_noself) do
        local manjuan, tuntian, phase = status(friend)
        if manjuan == nil then return unknown_activate(request, "zhiluan", "zhiluan draw status is unknown") end
        if not manjuan and tuntian and phase == sgs.Player_NotActive and not friend:isKongcheng() then
            return take(friend)
        end
        if not manjuan and friend:hasSkill("enyuan") and not friend:isKongcheng() then
            return take(friend)
        end
    end
    for _, enemy in ipairs(self.enemies) do
        local manjuan, tuntian = status(enemy)
        if manjuan == nil then return unknown_activate(request, "zhiluan", "zhiluan draw status is unknown") end
        if (manjuan or not tuntian) and not enemy:isKongcheng() then return take(enemy) end
    end
    for _, friend in ipairs(self.friends_noself) do
        local manjuan = self:hasManjuanEffect(friend)
        if manjuan == nil then return unknown_activate(request, "zhiluan", "zhiluan draw status is unknown") end
        if not manjuan and not friend:isKongcheng() then return take(friend) end
    end
    return nil
end

ai_skill_discard.zhiluan = function(self, options)
    local count = options and options.max_count or 1
    if type(count) ~= "number" or count < 1 then return {kind = "pass"} end
    return lowest_ids(self, count, "he", "zhiluan")
end

ai_skill_choice.zhiluan = function(self, options)
    local source = self:getDecisionData():toPlayer()
    if source then
        local friend = self:isFriend(source)
        if friend == nil then ai_unsupported("zhiluan relation is unknown", "zhiluan") end
        if friend and choose(options, "add") then return "add" end
    end
    return choose(options, "reset") or (options.choices or {})[1]
end

ai_skill_invoke.caoduo = function()
    ai_unsupported("caoduo invoke payload is not in the decision context", "caoduo")
end

ai_skill_use["@@caoduo"] = function()
    ai_unsupported("caoduo response tag is not projected", "caoduo")
end

ai_skill_activate.caoduo = function(self, request)
    local cards = self.player:getHandcards()
    if not cards or #cards < 1 then return nil end
    local club, club_keep, club_use
    for _, card in ipairs(cards) do
        if card:getSuitString() == "club" then
            local keep, use = self:getKeepValue(card), self:getUseValue(card)
            if type(keep) ~= "number" or type(use) ~= "number" then
                return unknown_activate(request, "caoduo", "caoduo card value is unknown")
            end
            if not club or keep < club_keep then
                club, club_keep, club_use = card, keep, use
            end
        end
    end
    if not club or club_keep > 18 or club_use > 12 then return nil end
    if not self.enemies then
        return unknown_activate(request, "caoduo", "caoduo relation is unknown")
    end
    local others = self.room:getOtherPlayers(self.player)
    if not others then return unknown_activate(request, "caoduo", "caoduo players are unknown") end
    local ranked = {}
    for _, player in ipairs(others) do
        if type(self:objectiveLevel(player)) ~= "number" or self:getCardsNum("Slash", player) == nil then
            return unknown_activate(request, "caoduo", "caoduo source ranking is unknown")
        end
        ranked[#ranked + 1] = player
    end
    table.sort(ranked, function(a, b)
        local left, right = self:objectiveLevel(a), self:objectiveLevel(b)
        if left == right then return self:getCardsNum("Slash", a) < self:getCardsNum("Slash", b) end
        return left > right
    end)
    others = ranked
    local victims = self:sort(self.room:getAlivePlayers(), "defense")
    if not victims then return unknown_activate(request, "caoduo", "caoduo defense sort is unknown") end
    local function pair(source, victim)
        if source:objectName() == victim:objectName() or source:isKongcheng() then return nil end
        local level = self:objectiveLevel(victim)
        if type(level) ~= "number" then return "unknown" end
        local range = source:inMyAttackRange(victim)
        local slashable = self:canSlash(source, victim, nil, true)
        if range == nil or slashable == nil then return "unknown" end
        if not range or not slashable then return nil end
        return level
    end
    local function collateral(source, victim)
        return skill_answer(self, "caoduo", {id_of(club, "caoduo")},
            {source:objectName(), victim:objectName()}, "collateral")
    end
    for _, source in ipairs(others) do
        local source_level = self:objectiveLevel(source)
        if type(source_level) ~= "number" then
            return unknown_activate(request, "caoduo", "caoduo objective is unknown")
        end
        if source_level >= 0 and not source:isKongcheng() then
            local lose = self:loseEquipEffect(source)
            local tuntian = self:hasTuntianEffect(source)
            if lose == nil or tuntian == nil then
                return unknown_activate(request, "caoduo", "caoduo source status is unknown")
            end
            if not lose and not tuntian then
                for _, victim in ipairs(victims) do
                    local level = pair(source, victim)
                    if level == "unknown" then
                        return unknown_activate(request, "caoduo", "caoduo victim check is unknown")
                    end
                    if type(level) == "number" and level > 2 then
                        return collateral(source, victim)
                    end
                end
            end
        elseif source_level < 0 and self:getCardsNum("Slash", source) > 0 and not source:isKongcheng() then
            for _, victim in ipairs(victims) do
                local level = pair(source, victim)
                if level == "unknown" then
                    return unknown_activate(request, "caoduo", "caoduo victim check is unknown")
                end
                if type(level) == "number" and level > 2 then
                    local good = self:isGoodTarget(victim, self.enemies, nil)
                    if good == nil then
                        return unknown_activate(request, "caoduo", "caoduo target check is unknown")
                    end
                    if good then return collateral(source, victim) end
                end
            end
        end
    end
    return nil
end

local function recover_target(self, require_cards)
    local urgent, later = self:getWoundedFriend(false, false)
    if not urgent or not later then return nil, "unknown" end
    local overflow = self:getOverflow()
    if type(overflow) ~= "number" then return nil, "unknown" end
    if urgent[1] then
        local target = urgent[1]
        local weak = self:isWeak(target)
        local hp, best = target:getHp(), self:getBestHp(target)
        local draw = self:canDraw(target, self.player)
        if weak == nil or type(hp) ~= "number" or type(best) ~= "number" or draw == nil then
            return nil, "unknown"
        end
        local cards_ok = not require_cards or target:isKongcheng() ~= true
        if cards_ok and (weak or overflow >= 1) and hp < best and draw then return target end
    end
    if overflow > 0 then
        for _, friend in ipairs(later) do
            local draw = self:canDraw(friend, self.player)
            if draw == nil then return nil, "unknown" end
            local cards_ok = not require_cards or friend:isKongcheng() ~= true
            if cards_ok and draw and not friend:hasSkills("hunzi|longhun") then return friend end
        end
    end
end

local function give_activate(self, request, name, require_cards)
    local card, status = payment_card(self)
    if status == "unknown" then return unknown_activate(request, name, name .. " payment is unknown") end
    if not card then return nil end
    local target, target_status = recover_target(self, require_cards)
    if target_status == "unknown" then
        return unknown_activate(request, name, name .. " recover target is unknown")
    end
    if not target then return nil end
    return skill_answer(self, name, {id_of(card, name)}, {target:objectName()})
end

ai_skill_activate.tianlai = function(self, request)
    return give_activate(self, request, "tianlai", true)
end
ai_skill_activate.lingyin = function(self, request)
    return give_activate(self, request, "lingyin", false)
end

ai_skill_invoke.shengkong = function() return true end

ai_skill_playerchosen.shengkong = function(self, options)
    local targets = players_of(self, options, "shengkong")
    local function pick(require_tuntian)
        for _, player in ipairs(targets) do
            local friend = self:isFriend(player)
            local draw = self:canDraw(player, self.player)
            if friend == nil or draw == nil then
                ai_unsupported("shengkong relation is unknown", "shengkong")
            end
            if friend and draw then
                if not require_tuntian then return player:objectName() end
                local tuntian = self:hasTuntianEffect(player)
                if tuntian == nil then ai_unsupported("shengkong tuntian is unknown", "shengkong") end
                if tuntian then return player:objectName() end
            end
        end
    end
    return pick(true) or pick(false) or (targets[1] and targets[1]:objectName()) or {kind = "pass"}
end

ai_skill_cardask["@shengkong-use"] = function(self, options, request)
    local target = self:getDecisionData():toPlayer()
    if target then
        local friend = self:isFriend(target)
        if friend == nil then ai_unsupported("shengkong relation is unknown", "shengkong") end
        if not friend then return {kind = "pass"} end
    end
    local pattern = request and request.pattern or ""
    if not pattern:match("^[%w_]+$") then
        ai_unsupported("shengkong pattern is not a card class", "shengkong")
    end
    local id = self:getCardId(pattern)
    if type(id) ~= "number" then ai_unsupported("shengkong has no visible response card", "shengkong") end
    return id
end

sgs.ai_choicemade_filter = sgs.ai_choicemade_filter or {}
sgs.ai_choicemade_filter.cardResponded = sgs.ai_choicemade_filter.cardResponded or {}
sgs.ai_choicemade_filter.cardResponded["@shengkong-use"] = function(self, player, promptlist)
    if type(promptlist) ~= "table" or promptlist[#promptlist] == "" then return end
    local target = self.room:findPlayerByObjectName(promptlist[4])
    if target then sgs.updateIntention(player, target, -40) end
end

-- 靈變要權威端的轉化票才能知道虛擬牌能否使用。沒有票時不猜目標。
ai_skill_activate.lingbian = function(self, request)
    if self:getConversions() == nil then
        return unknown_activate(request, "lingbian", "lingbian conversions are unknown")
    end
    return self:playAuthorizedConversion("lingbian", {
        accept = function(ai, conversion)
            local kind = conversion:getClassName()
            if type(kind) ~= "string" or kind == "" then return nil end
            local basic = conversion:isKindOf("BasicCard")
            local trick = conversion:isKindOf("TrickCard")
            local delayed = conversion:isKindOf("DelayedTrick")
            if basic == nil or trick == nil or delayed == nil then return nil end
            if not basic and not (trick and not delayed) then return false end
            local count = ai:getCardsNum(kind)
            if count == nil then return nil end
            return count < 1
        end
    })
end

ai_skill_invoke.xingyou = function(self)
    local damage = self:getDecisionData():toDamage()
    if not damage or not damage.to then
        ai_unsupported("xingyou needs the damage target", "xingyou")
    end
    local lose = self:needToLoseHp(damage.to, damage.from, damage.card)
    if lose == nil then ai_unsupported("xingyou lose-hp check is unknown", "xingyou") end
    return not lose
end

local function first_discard_target(self, options, flags, key)
    local targets = players_of(self, options, key)
    for _, player in ipairs(targets) do
        local discard = self:doDisCard(player, flags)
        if discard == nil then ai_unsupported(key .. " discard value is unknown", key) end
        if discard then return player:objectName() end
    end
    return {kind = "pass"}
end

ai_skill_playerchosen.zuiyou = function(self, options)
    return first_discard_target(self, options, "he", "zuiyou")
end
ai_skill_playerchosen.duotian = function(self, options)
    return first_discard_target(self, options, "ej", "duotian")
end

local function visible_nonbasic(self, player)
    local cards = player:getCards("h")
    if cards == nil then return nil end
    for _, card in ipairs(cards) do
        -- 只看這名觀察者看得見的手牌，看不見不能當成基本牌。
        local visible = self:cardVisibleTo(player, card)
        if visible == nil then return nil end
        if visible and not card:isKindOf("BasicCard") then return card end
    end
    return false
end

ai_skill_playerchosen.pomou = function(self, options)
    local targets = players_of(self, options, "pomou")
    for _, player in ipairs(targets) do
        local hostile = self:isEnemy(player)
        if hostile == nil then ai_unsupported("pomou relation is unknown", "pomou") end
        if hostile then
            local card = visible_nonbasic(self, player)
            if card == nil then ai_unsupported("pomou hand visibility is unknown", "pomou") end
            if card then return player:objectName() end
        end
    end
    return first_discard_target(self, options, "h", "pomou")
end

ai_skill_cardchosen.pomou = function(self, options)
    local who = self:getDecisionData():toPlayer()
    if not who and options and options.context then
        who = self.room:findPlayerByObjectName(options.context.who or options.context.target)
    end
    if not who then ai_unsupported("pomou card owner is missing", "pomou") end
    local card = visible_nonbasic(self, who)
    if card == nil then ai_unsupported("pomou hand visibility is unknown", "pomou") end
    if card then return id_of(card, "pomou") end
    return {kind = "pass"}
end

ai_skill_activate.dongxi = function(self, request)
    local card, status = payment_card(self)
    if status == "unknown" then return unknown_activate(request, "dongxi", "dongxi payment is unknown") end
    if not card then return nil end
    if not self.enemies or not self.friends_noself then
        return unknown_activate(request, "dongxi", "dongxi relation is unknown")
    end
    local function give(player)
        local draw = self:canDraw(player, self.player)
        if draw == nil then return nil, "unknown" end
        if not draw then return nil end
        return skill_answer(self, "dongxi", {id_of(card, "dongxi")}, {player:objectName()})
    end
    for _, enemy in ipairs(self.enemies) do
        local hand = enemy:getHandcardNum()
        if type(hand) ~= "number" then
            return unknown_activate(request, "dongxi", "dongxi hand count is unknown")
        end
        if enemy:getMark("dongxi") == 0 and hand >= 3 then
            local answer, draw_status = give(enemy)
            if draw_status == "unknown" then
                return unknown_activate(request, "dongxi", "dongxi draw status is unknown")
            end
            if answer then return answer end
        end
    end
    local overflow = self:getOverflow()
    if type(overflow) ~= "number" then
        return unknown_activate(request, "dongxi", "dongxi overflow is unknown")
    end
    if overflow <= 0 then return nil end
    for _, friend in ipairs(self.friends_noself) do
        if friend:getMark("dongxi") == 0 then
            local answer, draw_status = give(friend)
            if draw_status == "unknown" then
                return unknown_activate(request, "dongxi", "dongxi draw status is unknown")
            end
            if answer then return answer end
        end
    end
    for _, friend in ipairs(self.friends_noself) do
        local answer, draw_status = give(friend)
        if draw_status == "unknown" then
            return unknown_activate(request, "dongxi", "dongxi draw status is unknown")
        end
        if answer then return answer end
    end
    return nil
end

ai_skill_cardask["@huanxing"] = function(self, _, request)
    if math.random() >= 0.6 then return {kind = "pass"} end
    local pattern = request and request.pattern or ""
    if not pattern:match("^[%w_]+$") then
        ai_unsupported("huanxing pattern is not a card class", "huanxing")
    end
    local id = self:getCardId(pattern)
    if type(id) ~= "number" then return {kind = "pass"} end
    return id
end

ai_skill_invoke.huanxing = function()
    ai_unsupported("huanxing used-state tag is not projected", "huanxing")
end

ai_skill_activate.zzy_weimian = function(self, request)
    local card, status = payment_card(self)
    if status == "unknown" then
        return unknown_activate(request, "zzy_weimian", "zzy_weimian payment is unknown")
    end
    if not card or not self.friends_noself then
        if not self.friends_noself then
            return unknown_activate(request, "zzy_weimian", "zzy_weimian relation is unknown")
        end
        return nil
    end
    local function give(require_hand)
        for _, friend in ipairs(self.friends_noself) do
            local hand = friend:getHandcardNum()
            local draw = self:canDraw(friend, self.player)
            if type(hand) ~= "number" or draw == nil then return nil, "unknown" end
            if draw and (not require_hand or hand >= 3) then return friend end
        end
    end
    local friend, friend_status = give(true)
    if friend_status == "unknown" then
        return unknown_activate(request, "zzy_weimian", "zzy_weimian draw status is unknown")
    end
    if not friend then friend, friend_status = give(false) end
    if friend_status == "unknown" then
        return unknown_activate(request, "zzy_weimian", "zzy_weimian draw status is unknown")
    end
    if not friend then return nil end
    return skill_answer(self, "zzy_weimian", {id_of(card, "zzy_weimian")}, {friend:objectName()})
end

ai_skill_activate.luahuojianzhuixi = function(self, request)
    if not self.enemies then
        return unknown_activate(request, "luahuojianzhuixi", "luahuojianzhuixi relation is unknown")
    end
    local enemies = self:sort(self.enemies, "defense") or self.enemies
    for _, enemy in ipairs(enemies) do
        local weak = self:isWeak(enemy)
        local effective = self:slashIsEffective(nil, enemy)
        if weak == nil or effective == nil then
            return unknown_activate(request, "luahuojianzhuixi", "luahuojianzhuixi target check is unknown")
        end
        if weak and effective then
            return skill_answer(self, "luahuojianzhuixi", {}, {enemy:objectName()}, "slash")
        end
    end
    return nil
end

ai_skill_invoke.luabaozhahuohua = function(self)
    local damage = self:getDecisionData():toDamage()
    if not damage or not damage.to then
        ai_unsupported("luabaozhahuohua needs the damage target", "luabaozhahuohua")
    end
    local before_target, next_target = self:adjacentPlayers(damage.to)
    if not before_target or not next_target then
        ai_unsupported("luabaozhahuohua neighbors are unknown", "luabaozhahuohua")
    end
    local before_ok = self:doDisCard(before_target, "he")
    if before_ok == nil then ai_unsupported("luabaozhahuohua discard value is unknown", "luabaozhahuohua") end
    if before_target:objectName() == next_target:objectName() then return before_ok == true end
    local next_ok = self:doDisCard(next_target, "he")
    if next_ok == nil then ai_unsupported("luabaozhahuohua discard value is unknown", "luabaozhahuohua") end
    return before_ok == true and next_ok == true
end

ai_skill_invoke.xuezou = function(self)
    local alive = self.room:getAlivePlayers()
    if not alive then ai_unsupported("xuezou players are unknown", "xuezou") end
    for _, player in ipairs(alive) do
        for _, zone in ipairs({"e", "j"}) do
            local cards = zone == "e" and player:getEquips() or player:getJudgingArea()
            if not cards then ai_unsupported("xuezou cards are unknown", "xuezou") end
            for _, card in ipairs(cards) do
                local discard = self:doDisCard(player, id_of(card, "xuezou"))
                if discard == nil then ai_unsupported("xuezou discard value is unknown", "xuezou") end
                if discard then return true end
            end
        end
    end
    return false
end

ai_skill_suit.xuezou = function(self, options)
    local counts, best, best_count = {}, nil, 0
    local alive = self.room:getAlivePlayers()
    if not alive then ai_unsupported("xuezou players are unknown", "xuezou") end
    for _, player in ipairs(alive) do
        for _, zone in ipairs({"e", "j"}) do
            local cards = zone == "e" and player:getEquips() or player:getJudgingArea()
            if not cards then ai_unsupported("xuezou cards are unknown", "xuezou") end
            for _, card in ipairs(cards) do
                local discard = self:doDisCard(player, id_of(card, "xuezou"))
                if discard == nil then ai_unsupported("xuezou discard value is unknown", "xuezou") end
                if discard then
                    local suit = card:getSuitString()
                    if type(suit) ~= "string" or suit == "" then
                        ai_unsupported("xuezou suit is unknown", "xuezou")
                    end
                    counts[suit] = (counts[suit] or 0) + 1
                    if counts[suit] > best_count then best, best_count = suit, counts[suit] end
                end
            end
        end
    end
    if best and choose(options, best) then return best end
    local offered = options and options.choices or {}
    if #offered > 0 then return offered[math.random(#offered)] end
    ai_unsupported("xuezou has no offered suit", "xuezou")
end

ai_skill_use["@@zhanmeiqiyue"] = function(self)
    self:updatePlayers()
    if not self.friends then ai_unsupported("zhanmeiqiyue relation is unknown", "zhanmeiqiyue") end
    local function pick(include_self)
        local list = include_self and self.friends or self.friends_noself
        if not list then ai_unsupported("zhanmeiqiyue friends are unknown", "zhanmeiqiyue") end
        for _, friend in ipairs(list) do
            local draw = self:canDraw(friend, self.player)
            local female = female_player(friend)
            if draw == nil or female == nil then
                ai_unsupported("zhanmeiqiyue target check is unknown", "zhanmeiqiyue")
            end
            if draw and female then return {targets = {friend:objectName()}} end
        end
    end
    return pick(false) or pick(true) or {kind = "pass"}
end

ai_skill_activate.feitianshuangzhan = function(self, request)
    if self:getConversions() then
        return self:playAuthorizedConversion("feitianshuangzhan", {
            kind = "Slash",
            accept = function(ai, conversion)
                local card = ai:conversionSubcard(conversion)
                if card == nil then return nil end
                if not card or card:isKindOf("Slash") or card:isKindOf("Peach") then return false end
                local red_used = ai.player:hasFlag("feitianshuangzhan_RedUsed")
                local black_used = ai.player:hasFlag("feitianshuangzhan_BlackUsed")
                if red_used == nil or black_used == nil then return nil end
                if card:isRed() then return not red_used end
                if card:isBlack() then return not black_used end
                return false
            end
        })
    end
    return unknown_activate(request, "feitianshuangzhan", "feitianshuangzhan conversions are unknown")
end

sgs.ai_card_priority = sgs.ai_card_priority or {}
sgs.ai_card_priority.feitianshuangzhan = function(_, card)
    if card and card:getSkillName() == "feitianshuangzhan" then return 0.08 end
end

ai_skill_invoke.jinyanmofa = function(self)
    local use = self:getDecisionData():toCardUse()
    if not use or not use.card or type(use.card.getSuit) ~= "function" then
        ai_unsupported("jinyanmofa card use is not projected", "jinyanmofa")
    end
    local suit = use.card:getSuit()
    if type(suit) ~= "number" then ai_unsupported("jinyanmofa suit is unknown", "jinyanmofa") end
    local alive = self.room:getAlivePlayers()
    if not alive then ai_unsupported("jinyanmofa players are unknown", "jinyanmofa") end
    for _, player in ipairs(alive) do
        local judges = player:getJudgingArea()
        local equips = player:getEquips()
        if not judges or not equips then ai_unsupported("jinyanmofa cards are unknown", "jinyanmofa") end
        for _, card in ipairs(judges) do
            if card:getSuit() == suit then
                local friend = self:isFriend(player)
                if friend == nil then ai_unsupported("jinyanmofa relation is unknown", "jinyanmofa") end
                if friend then
                    self:remember("mcompetition.jinyanmofa", player:objectName())
                    return true
                end
            end
        end
        for _, card in ipairs(equips) do
            if card:getSuit() == suit then
                local discard = self:doDisCard(player, id_of(card, "jinyanmofa"))
                if discard == nil then ai_unsupported("jinyanmofa discard value is unknown", "jinyanmofa") end
                if discard then
                    self:remember("mcompetition.jinyanmofa", player:objectName())
                    return true
                end
            end
        end
    end
    return false
end

ai_skill_playerchosen.jinyanmofa = function(self, options)
    local targets = players_of(self, options, "jinyanmofa")
    local saved = self:recall("mcompetition.jinyanmofa")
    if type(saved) == "string" then
        for _, player in ipairs(targets) do
            if player:objectName() == saved then return saved end
        end
    end
    return first_discard_target(self, options, "ej", "jinyanmofa")
end

ai_skill_invoke.busizhixue = function(self)
    local damage = self:getDecisionData():toDamage()
    if not damage or not damage.to then
        ai_unsupported("busizhixue needs the damage target", "busizhixue")
    end
    if damage.to:objectName() == self.player:objectName() then return true end
    local friend = self:isFriend(damage.to)
    if friend == nil then ai_unsupported("busizhixue relation is unknown", "busizhixue") end
    if not friend then return false end
    local weak = self:isWeak()
    local target_weak = self:isWeak(damage.to)
    if weak == nil or target_weak == nil then
        ai_unsupported("busizhixue hp is unknown", "busizhixue")
    end
    if weak and not (type(damage.to.isLord) == "function" and damage.to:isLord() and target_weak) then
        return false
    end
    local lose = self:needToLoseHp(damage.to, damage.from, damage.card)
    if lose == nil then ai_unsupported("busizhixue lose-hp check is unknown", "busizhixue") end
    return not lose
end

ai_skill_invoke.boyi = function(self)
    local use = self:getDecisionData():toCardUse()
    if not use or not use.from or not use.to then
        ai_unsupported("boyi card use is not projected", "boyi")
    end
    local discard = self:doDisCard(self.player, "he")
    if discard == nil then ai_unsupported("boyi discard value is unknown", "boyi") end
    if discard then return true end
    if use.from:objectName() == self.player:objectName() then
        local first = use.to[1]
        if first then
            local liegong = self:canLiegong(first, self.player)
            if liegong == nil then ai_unsupported("boyi liegong is unknown", "boyi") end
            if liegong then return false end
        end
        for _, player in ipairs(use.to) do
            local jinks = self:getCardsNum("Jink", player)
            if jinks == nil then ai_unsupported("boyi jink count is unknown", "boyi") end
            if jinks >= 1 then return true end
        end
        return false
    end
    ai_unsupported("boyi response jink policy is not on the isolated base", "boyi")
end

ai_skill_discard.boyi = function(self, options)
    local count = options and options.max_count or 1
    if type(count) ~= "number" or count < 1 then return {kind = "pass"} end
    return lowest_ids(self, count, "he", "boyi")
end

ai_skill_playerchosen.langmanpaotai = function(self, options)
    local use = self:getDecisionData():toCardUse()
    if not use or not use.from or not use.to then
        ai_unsupported("langmanpaotai card use is not projected", "langmanpaotai")
    end
    for _, player in ipairs(use.to) do
        local heavy = self:hasHeavyDamage(use.from, use.card, player)
        if heavy == nil then ai_unsupported("langmanpaotai damage check is unknown", "langmanpaotai") end
        if heavy then return {kind = "pass"} end
    end
    local should = false
    for _, player in ipairs(use.to) do
        local friend = self:isFriend(player)
        local hostile = self:isEnemy(player)
        local lose = self:needToLoseHp(player, use.from, use.card)
        if friend == nil or hostile == nil or lose == nil then
            ai_unsupported("langmanpaotai relation is unknown", "langmanpaotai")
        end
        if (friend and not lose) or (hostile and lose) then should = true end
    end
    local overflow = self:getOverflow()
    if type(overflow) ~= "number" then
        ai_unsupported("langmanpaotai overflow is unknown", "langmanpaotai")
    end
    if should or overflow <= 0 then
        return first_discard_target(self, options, "eh", "langmanpaotai")
    end
    return {kind = "pass"}
end

ai_skill_activate.DuriNoko = function(self, request)
    local card, status = payment_card(self)
    if status == "unknown" then return unknown_activate(request, "DuriNoko", "DuriNoko payment is unknown") end
    if not card then return nil end
    if not self.enemies then
        return unknown_activate(request, "DuriNoko", "DuriNoko relation is unknown")
    end
    local lost = self.player:getLostHp()
    if type(lost) ~= "number" then
        return unknown_activate(request, "DuriNoko", "DuriNoko lost hp is unknown")
    end
    local targets = {}
    for _, enemy in ipairs(self.enemies) do
        local distance = self.player:distanceTo(enemy)
        if type(distance) ~= "number" then
            return unknown_activate(request, "DuriNoko", "DuriNoko distance is unknown")
        end
        if distance <= 1 then
            local discard = self:doDisCard(enemy, "he")
            if discard == nil then
                return unknown_activate(request, "DuriNoko", "DuriNoko discard value is unknown")
            end
            if discard then
                targets[#targets + 1] = enemy:objectName()
                if lost > 0 and #targets >= lost then break end
            end
        end
    end
    if #targets < 1 then return nil end
    return skill_answer(self, "DuriNoko", {id_of(card, "DuriNoko")}, targets)
end
