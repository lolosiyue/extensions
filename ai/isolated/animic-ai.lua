-- Animic 隔離 AI。這裡保留 lua/ai/animic-ai.lua 的分支順序與隨機決策，
-- 只使用 viewer-scoped value facade；未知資料交回 ai_unsupported，不能猜成拒絕。

local function unsupported(reason, key)
    return ai_unsupported(reason, key)
end

local function choices(options, key)
    return type(options) == "table" and AIValue.isList(options[key]) and options[key] or nil
end

local function offered(options, value)
    for _, item in ipairs(options or {}) do if item == value then return true end end
    return false
end

local function known(value, key)
    if value == nil then unsupported("required visible value is unknown", key or "animic") end
    return value
end
local function relation(self, player)
    local value = self:relationTo(player)
    if value ~= "friend" and value ~= "enemy" and value ~= "neutral" then
        unsupported("player relation is unknown", "animic")
    end
    return value
end
local function is_friend(self, player) return relation(self, player) == "friend" end
local function is_enemy(self, player) return relation(self, player) == "enemy" end

local function target(self, name)
    return type(name) == "string" and self.room:findPlayerByObjectName(name) or nil
end

local function require_helper(self, name, key)
    if type(self[name]) ~= "function" then
        return unsupported(name .. " is not covered by the isolated common layer", key)
    end
    return true
end

local function offered_targets(self, names)
    if not AIValue.isList(names) then return nil end
    local result = AIList.new({})
    for _, name in ipairs(names) do
        local player = target(self, name)
        if not player then return nil end
        result:append(player)
    end
    return result
end

-- 魔道：空手先選 1；原版會依手牌逐張測試決鬥、火攻，再測試群攻牌。
ai_skill_invoke.modao = function(self)
    if not self.enemies then return unsupported("modao enemies are unknown", "modao") end
    return #self.enemies > 0
end

ai_skill_choice.modao = function(self, options)
    local items = choices(options, "choices")
    if not items or #items == 0 then return unsupported("modao choices are missing", "modao") end
    local hand = self.player:getHandcards()
    if not hand then return unsupported("modao hand is unknown", "modao") end
    if #hand == 0 and offered(items, "1") then return "1" end
    for _, card in ipairs(hand) do
        if card:isKindOf("Duel") or (card:isKindOf("FireAttack") and #hand > 2) then
            local plan, status = self:tryUseCard(card)
            if status == "unsupported" then return unsupported(plan.reason, "modao") end
            if status == "planned" and plan and plan.to and #plan.to > 0 and offered(items, "2") then
                return "2"
            end
        elseif card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
            return unsupported("modao dummy AOE identity and effects are not projected", "modao")
        end
    end
    if offered(items, "1") then return "1" end
    return unsupported("modao choice 1 was not offered", "modao")
end

ai_skill_playerchosen.modao = function(self, options)
    -- The original orders by handcard_defense and reads getTag("modao"), not
    -- getMark("modao"). Neither may be silently replaced by another value.
    return unsupported("modao tag and handcard_defense ordering are not projected", "modao")
end

ai_skill_invoke.cuisheng = function(self)
    local current = self.room:getCurrent()
    if not current then return unsupported("cuisheng current player is unknown", "cuisheng") end
    local friend = is_friend(self, current)
    if friend == nil then return unsupported("cuisheng relation is unknown", "cuisheng") end
    return friend
end

-- @@huayuan：原版目標過濾順序完整保留；最後由 skill_action／authority 做合法性確認。
ai_skill_use["@@huayuan"] = function(self, prompt, request)
    local action = self:getSkillAction()
    local candidates = choices(request.options or {}, "players")
    local players = offered_targets(self, candidates)
    if not action or not action:isValid() or action:getActivationSkillName() ~= "huayuan" or not players or not self.enemies or not self.friends then return unsupported("huayuan action, candidates or relations are unknown", "huayuan") end
    if not require_helper(self, "isGoodTarget", "huayuan") or not require_helper(self, "needToLoseHp", "huayuan") then return nil end
    local selected = {}
    for _, enemy in ipairs(self.enemies) do
        local objective = self:objectiveLevel(enemy)
        if objective == nil then return unsupported("huayuan objective is unknown", "huayuan") end
        if players:contains(enemy) and not enemy:isChained() and not enemy:hasSkill("danlao") and not enemy:hasSkill("sheyan")
            and not enemy:hasSkill("qianjie") and not enemy:hasSkills("chenghao+yinshi")
            and not enemy:hasSkill("Tianhuo") and not enemy:hasSkill("fatefapao")
            and objective > 3
            and self:needToLoseHp(enemy) == false
            and self:isGoodTarget(enemy, self.enemies, nil) == true then
            selected[#selected + 1] = enemy:objectName()
            if #selected == 2 then break end
        end
    end
    if #selected < 2 then
        for _, friend in ipairs(self.friends) do
            if players:contains(friend) and not friend:isChained() and self:needToLoseHp(friend) == true then
                selected[#selected + 1] = friend:objectName()
                if #selected == 2 then break end
            end
        end
    end
    if #selected == 0 then return {kind = "pass"} end
    return {kind = "use_card", skill_action = action:toAnswer(), targets = selected}
end

ai_skill_playerchosen.jiaosha = function(self, options)
    local names = choices(options, "players")
    local players = offered_targets(self, names)
    if not players then return unsupported("jiaosha candidates are unknown", "jiaosha") end
    local sorted = self:sort(players, "handcard")
    if not sorted then return unsupported("jiaosha hand ordering is unknown", "jiaosha") end
    if not require_helper(self, "willSkipPlayPhase", "jiaosha") or not require_helper(self, "isGoodTarget", "jiaosha") then return nil end
    for _, p in ipairs(sorted) do
        local friend, skip, lose, effective = is_friend(self, p), self:willSkipPlayPhase(p), self:needToLoseHp(p), self:damageIsEffective(p, sgs.DamageStruct_Normal)
        if friend == nil or skip == nil or lose == nil or effective == nil then return unsupported("jiaosha policy is unknown", "jiaosha") end
        if friend and not skip and (lose or not effective) then
            return p:objectName()
        end
    end
    for _, p in ipairs(sorted) do
        local enemy, skip, effective, lose, good = is_enemy(self, p), self:willSkipPlayPhase(p), self:damageIsEffective(p, sgs.DamageStruct_Normal), self:needToLoseHp(p), self:isGoodTarget(p, self.enemies, nil)
        if enemy == nil or skip == nil or effective == nil or lose == nil or good == nil then return unsupported("jiaosha policy is unknown", "jiaosha") end
        if enemy and skip and effective and not lose and good then
            return p:objectName()
        end
    end
    return nil
end

-- 黃略是 askForCard：只在原版允許的關係與牌點條件下出牌。
ai_skill_cardask["@huanglue"] = function(self, options)
    local use = self:getDecisionContext().use
    if not use or not use.card or not use.to then unsupported("huanglue card use is not projected", "huanglue") end
    local cards = known(self:sortByKeepValue(known(self.player:getCards("he"), "huanglue")), "huanglue")
    local wanted = false
    if use.card:isKindOf("Jink") or use.card:isKindOf("Nullification") then
        wanted = use.from and is_enemy(self, use.from)
    elseif use.card:isKindOf("Peach") then
        if use.from and is_enemy(self, use.from) then
            for _, player in ipairs(use.to) do
                if is_enemy(self, player) then wanted = true; break end
            end
        end
    elseif not known(self:isWeak(), "huanglue") and use.from and not is_friend(self, use.from) then
        for _, player in ipairs(use.to) do
            if is_friend(self, player) then wanted = true; break end
        end
    end
    if wanted then
        local number = known(use.card:getNumber(), "huanglue")
        for _, card in ipairs(cards) do
            if known(card:getNumber(), "huanglue") > number then
                -- Preserve the first legacy choice; an unoffered cost is unknown,
                -- not a reason to silently switch to the next card.
                for _, id in ipairs(choices(options, "card_ids") or {}) do
                    if id == card:getEffectiveId() then return id end
                end
                unsupported("huanglue selected card was not offered", "huanglue")
            end
        end
    end
    return {kind = "pass"}
end

ai_skill_playerchosen.luafenwei = function(self, options)
    local keep_empty = self:needKongcheng(self.player, true)
    if keep_empty == nil then return unsupported("luafenwei empty-hand policy is unknown", "luafenwei") end
    if keep_empty then return {kind = "pass"} end
    local names = choices(options, "players")
    local players = offered_targets(self, names)
    if not players then return unsupported("luafenwei candidates are unknown", "luafenwei") end
    local sorted = self:sort(players, "defense")
    if not sorted then return unsupported("luafenwei defense ordering is unknown", "luafenwei") end
    for _, p in ipairs(sorted) do
        local judging = p:getJudgingArea()
        if not judging then return unsupported("luafenwei judging area is unknown", "luafenwei") end
        local friend = is_friend(self, p)
        if friend == nil then return unsupported("luafenwei relation is unknown", "luafenwei") end
        if friend and #judging > 0 and not p:containsTrick("YanxiaoCard") then return p:objectName() end
    end
    for _, p in ipairs(sorted) do
        local enemy = is_enemy(self, p)
        if enemy == nil then return unsupported("luafenwei relation is unknown", "luafenwei") end
        if enemy and p:containsTrick("YanxiaoCard") then return p:objectName() end
    end
    for _, p in ipairs(sorted) do
        local enemy, legal = is_enemy(self, p), self:doDisCard(p, "ej", true)
        if enemy == nil or legal == nil then return unsupported("luafenwei relation or discard legality is unknown", "luafenwei") end
        if enemy and not (p:hasSkills(sgs.lose_equip_skill) or legal) then return p:objectName() end
    end
    for _, p in ipairs(sorted) do
        local equips = p:getEquips()
        if not equips then return unsupported("luafenwei equipment is unknown", "luafenwei") end
        local friend = is_friend(self, p)
        if friend == nil then return unsupported("luafenwei relation is unknown", "luafenwei") end
        if friend then
            if p:hasSkills(sgs.lose_equip_skill) and #equips > 0 then return p:objectName() end
            require_helper(self, "needToThrowArmor", "luafenwei")
            local throw = self:needToThrowArmor(p)
            if throw == nil then return unsupported("luafenwei armor policy is unknown", "luafenwei") end
            if throw then return p:objectName() end
        end
    end
    return sorted[1] and sorted[1]:objectName() or nil
end

ai_skill_cardchosen.luafenwei = function(self, options)
    local context = self:getDecisionContext()
    local who = context.who or context.target
    if type(who) == "string" then who = self.room:findPlayerByObjectName(who, true) end
    if not who then return unsupported("luafenwei target is unknown", "luafenwei") end
    local flags = context.flags or ""
    if flags:find("e", 1, true) then
        local enemy = is_enemy(self, who)
        if enemy == nil then return unsupported("luafenwei relation is unknown", "luafenwei") end
        if (enemy and not who:hasSkills(sgs.lose_equip_skill)) or (not enemy and who:hasSkills(sgs.lose_equip_skill)) then
            local equips = who:getCards("e")
            if not equips then return unsupported("luafenwei equipment is unknown", "luafenwei") end
            if equips[1] then return equips[1]:getEffectiveId() end
        end
    end
    if flags:find("j", 1, true) then
        local judges = who:getJudgingArea()
        if not judges then return unsupported("luafenwei judging area is unknown", "luafenwei") end
        if is_enemy(self, who) and who:containsTrick("YanxiaoCard") then
            for _, card in ipairs(judges) do if card:isKindOf("YanxiaoCard") then return card:getEffectiveId() end end
        elseif is_friend(self, who) then
            for _, card in ipairs(judges) do if not card:isKindOf("YanxiaoCard") then return card:getEffectiveId() end end
        end
    end
    return nil
end

-- 鬼豪：轉化必須使用 authority 已列出的 conversion ticket，不能拼牌字串。
ai_skill_activate.guihao = function(self)
    local key = "guihao"
    local cards = known(self.player:getHandcards(), key)
    local pile_ids = AIList.new({})
    for _, name in ipairs(known(self.player:getPileNames(), key)) do
        if name == "wooden_ox" then pile_ids = known(self.player:getPile(name), key); break end
    end
    if #pile_ids > 0 then
        local indexed = {}
        for _, card in ipairs(known(self.player:getHandPileCards(), key)) do indexed[card:getEffectiveId()] = card end
        for _, id in ipairs(pile_ids) do cards:append(known(indexed[id], key)) end
    end
    local selected
    for _, card in ipairs(known(self:sortByUseValue(cards, true), key)) do
        if known(card:isBlack(), key) then selected = card; break end
    end
    if not selected or known(self.player:getMark("guihao"), key) == 0 then return nil end
    local action = self:getSkillAction()
    if not action then
        for _, candidate in ipairs(known(self:getSkillActions(), key)) do
            if candidate:getActivationSkillName() == key then
                if action then unsupported("guihao activation instance is ambiguous", key) end
                action = candidate
            end
        end
    end
    if not action or not action:isValid() or action:getActivationSkillName() ~= key then
        unsupported("guihao activation ticket is missing", key)
    end
    for _, conversion in ipairs(known(self:getConversions(), key)) do
        if conversion:getActivationSkillName() == key
            and conversion:getActivationOwner() == action:getActivationOwner()
            and conversion:getActivationInstanceId() == action:getActivationInstanceId()
            and conversion:getSourceOwner() == action:getSourceOwner()
            and conversion:getSourceSkillName() == action:getSourceSkillName()
            and conversion:getSourceInstanceID() == action:getSourceInstanceID()
            and conversion:getClassName() == "Analeptic" then
            local costs = known(conversion:getSubcards(), key)
            if #costs == 1 and costs[1] == selected:getEffectiveId() then
                local available = known(conversion:isAvailable(), key)
                if not available then return nil end
                local plan, status = self:tryUseCard(conversion)
                if status == "unsupported" then error(plan, 0) end
                if status == "planned" then return plan:toAnswer() end
                return nil
            end
        end
    end
    unsupported("guihao first black card has no authorized Analeptic conversion", key)
end

sgs.ai_cardneed.guihao = function(to, card, self)
    if not known(card:isBlack(), "guihao") then return false end
    for _, known_card in ipairs(known(to:getKnownCards(), "guihao")) do
        local suit = known(known_card:getSuitString(), "guihao")
        if suit == "club" or suit == "spade" then return false end
    end
    return true
end

ai_skill_invoke.guihao = function(self)
    local weak = self:isWeak(self.player)
    if weak == nil then return unsupported("guihao weakness is unknown", "guihao") end
    if weak then
        local peach = self:getAllPeachNum()
        if peach == nil then return unsupported("guihao rescue estimate is unknown", "guihao") end
        if peach == 0 then return false end
    end
    if not require_helper(self, "willSkipPlayPhase", "guihao") then return nil end
    local skip = self:willSkipPlayPhase(self.player)
    if skip == nil then return unsupported("guihao skipped phase is unknown", "guihao") end
    if skip then return false end
    local hand = self.player:getHandcards()
    if not hand then return unsupported("guihao hand is unknown", "guihao") end
    for _, card in ipairs(hand) do
        if card:isKindOf("Peach") or card:isKindOf("Analeptic") or card:isKindOf("Slash") then return true end
    end
    return math.random() < 0.6
end

ai_skill_use["@@caiduan"] = function(self, prompt, request)
    local cards = self.player:getHandcards()
    if not cards then return unsupported("caiduan hand is unknown", "caiduan") end
    local sorted = self:sortByKeepValue(cards)
    if not sorted then return unsupported("caiduan keep ordering is unknown", "caiduan") end
    for _, card in ipairs(sorted) do
        if not card:targetFixed() then
            local plan, status = self:tryUseCard(card)
            if status == "unsupported" then return unsupported(plan.reason, "caiduan") end
            if status == "planned" and plan then
                return plan:toAnswer()
            end
        end
    end
    return {kind = "pass"}
end

ai_skill_invoke.caiduan = function(self)
    local current = self.room:getCurrent()
    if not current then return unsupported("caiduan current player is unknown", "caiduan") end
    local enemy = is_enemy(self, current)
    local weak = self:isWeak()
    if enemy == nil or weak == nil then return unsupported("caiduan relation or weakness is unknown", "caiduan") end
    return enemy and not weak
end

ai_skill_invoke.shenni = function(self, options)
    -- Legacy data:toMoveOneTime().card_ids has no isolated move projection yet;
    -- getChoiceCards() is a different request and cannot stand in for moved cards.
    return unsupported("shenni move card projection is not covered", "shenni")
end

ai_skill_playerchosen.yui_changxin = function(self, options)
    local names = choices(options, "players")
    local players = offered_targets(self, names)
    if not players then return unsupported("yui_changxin candidates are unknown", "yui_changxin") end
    local result = self:findPlayerToDiscard("he", true, true, players, false)
    if not result then return unsupported("yui_changxin discard target is unknown", "yui_changxin") end
    return result[1] and result[1]:objectName() or nil
end

sgs.need_kongcheng = (sgs.need_kongcheng or "") .. "|luafenwei"
-- Missing coverage: legacy intention callbacks and guihao legacy view-as;
-- moved cards for shenni are not interchangeable with choice-card candidates.
