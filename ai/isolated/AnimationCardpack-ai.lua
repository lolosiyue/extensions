-- AnimationCardpack isolated AI。
-- 只使用 viewer-scoped value facade；牌的生成、成本與合法性由 authority 驗證。
-- 原版依賴原生合成、QVariant tag 或 SmartAI 的部分在資料不足時
-- 明確回 ai_unsupported，不能把未知轉成 pass。

local function unsupported(reason, key)
    return ai_unsupported(reason, key)
end

-- Unknown mode relations are not negative answers to friend/enemy questions.
local function relation(self, player)
    local value = self:relationTo(player)
    if value ~= "friend" and value ~= "enemy" and value ~= "neutral" then
        unsupported("player relation is unknown", "AnimationCardpack")
    end
    return value
end
local function is_friend(self, player) return relation(self, player) == "friend" end
local function is_enemy(self, player) return relation(self, player) == "enemy" end

-- 共用 strategy-hooks 可能尚未建立這些值表；先初始化再登記套件規則。
sgs.weapon_range = sgs.weapon_range or {}
sgs.ai_canliegong_skill = sgs.ai_canliegong_skill or {}
sgs.ai_use_priority = sgs.ai_use_priority or {}
sgs.ai_keep_value = sgs.ai_keep_value or {}
sgs.ai_use_value = sgs.ai_use_value or {}
sgs.ai_ajustdamage_from = sgs.ai_ajustdamage_from or {}
sgs.ai_card_intention = sgs.ai_card_intention or {}

-- 武器資料是共用 weapon evaluator 會讀的純值規則。
sgs.weapon_range.Elucidator = 2
sgs.weapon_range.chopper = 3
sgs.weapon_range.Murasame = 2
sgs.weapon_range.tywz = 2
sgs.weapon_range.hqiangwei = 2

sgs.ai_use_priority.Rho_Aias = 2.6
sgs.ai_keep_value.mouthgun = 3.16
sgs.ai_keep_value.shuugakulyukou = 3.21
sgs.ai_keep_value.rotenburo = 3.25
sgs.ai_keep_value.bunkasai = 3.35
sgs.ai_keep_value.strike_the_death = 3.24
sgs.ai_use_value.mouthgun = 4.9
sgs.ai_use_value.rotenburo = 2.7
sgs.ai_use_priority.rotenburo = 1.4
sgs.ai_keep_value.rotenburo = 4
sgs.ai_card_intention.shuugakulyukou = -40

sgs.ai_ajustdamage_from["@std"] = function(self, from, to, card, nature)
    local mark = from:getMark("@std")
    if type(mark) ~= "number" then return nil end
    return mark
end

-- 事件物件只從共用 context 取得；舊 tag 不屬於 isolated ABI。
local function event_context(self)
    if type(self.getDecisionContext) ~= "function" then return nil end
    return self:getDecisionContext()
end

local function event_player(self, request, field)
    local context = event_context(self)
    local player = type(context) == "table" and context[field] or nil
    if AIValue.isPlayer(player) then return player end
    if type(player) == "string" then return self.room:findPlayerByObjectName(player, true) end
    return nil
end

ai_skill_invoke.Elucidator = function(self, options, request)
    local context = event_context(self)
    local damage = type(context) == "table" and context.damage or nil
    local target = damage and damage.to or event_player(self, request, "target")
    if not target then return unsupported("Elucidator damage target is not projected", "Elucidator") end
    if is_friend(self, target) == true then
        local draw = self:canDraw(target, self.player)
        if draw == nil then return unsupported("Elucidator draw status is unknown", "Elucidator") end
        if draw then return true end
    elseif is_friend(self, target) == nil then
        return unsupported("Elucidator target relation is unknown", "Elucidator")
    end
    -- getCard includes view-as selection and its ordering, not merely the first
    -- physical Slash in hand. That selector is absent from the value core.
    return unsupported("Elucidator needs the legacy Slash selector and dummy use plan", "Elucidator")
end
ai_skill_invoke.htms_rishi = function(self, options, request)
    local target = event_player(self, request, "player")
    if not target then return unsupported("htms_rishi target is not projected", "htms_rishi") end
    local enemy = is_enemy(self, target)
    if enemy == nil then return unsupported("htms_rishi target relation is unknown", "htms_rishi") end
    return enemy
end

-- Liegong hook is consumed by the existing strategy-hooks value ABI.
sgs.ai_canliegong_skill.htms_rishi = function(self, from, to)
    local from_hand, to_hand = from:getHandcardNum(), to:getHandcardNum()
    if type(from_hand) ~= "number" or type(to_hand) ~= "number" then return nil end
    return from_hand < to_hand
end

ai_skill_invoke.Murasame = ai_skill_invoke.htms_rishi
ai_skill_invoke.tywz = function(self, options, request)
    local context, damage = event_context(self), nil
    if type(context) == "table" then damage = context.damage end
    local target = type(damage) == "table" and damage.to or nil
    if not target then return unsupported("tywz damage target is not projected", "tywz") end
    local enemy = is_enemy(self, target)
    if enemy == nil then return unsupported("tywz target relation is unknown", "tywz") end
    return enemy
end

-- chopper 的原版 getTurnUseCard 會把整手牌合成 Slash；isolated 只能使用
-- authority 發出的 conversion ticket，不能自行合成／拼接牌。
ai_skill_activate.chopper = function(self, request)
    local action = self:getSkillAction("chopper")
    if not action or not action:isValid() then return unsupported("chopper action is not projected", "chopper") end
    local hand, hp = self.player:getHandcards(), self.player:getHp()
    if not hand or type(hp) ~= "number" then return unsupported("chopper hand or HP is unknown", "chopper") end
    if #hand > hp or #hand == 0 then return nil end
    -- Full-hand cost identity and Slash planning must both match the original.
    -- An arbitrary same-size ticket or a targetless action is not equivalent.
    return unsupported("chopper requires full-hand conversion binding and Slash planning", "chopper")
end
ai_skill_discard.Rho_Aias_trigger = function(self, options, request)
    local count = self.player:getPileCount("ring")
    if count == nil then return unsupported("Rho_Aias ring pile is unknown", "Rho_Aias_trigger") end
    if count >= 2 then return {} end
    local cards = self.player:getHandcards()
    if not cards then return unsupported("Rho_Aias hand is unknown", "Rho_Aias_trigger") end
    local sorted = self:sortByKeepValue(cards, false)
    if not sorted then return unsupported("Rho_Aias card values are unknown", "Rho_Aias_trigger") end
    -- Legacy always selects at most one, independently of the request minimum.
    return #sorted > 0 and {sorted[1]:getEffectiveId()} or {}
end
ai_skill_discard.hqiangwei = function(self, options, request)
    local target = event_player(self, request, "target")
    if not target then return unsupported("hqiangwei target tag is not projected", "hqiangwei") end
    local friend = is_friend(self, target)
    if friend == nil then return unsupported("hqiangwei target relation is unknown", "hqiangwei") end
    if friend then return {} end
    local cards = self.player:getHandcards()
    if not cards then return unsupported("hqiangwei hand is unknown", "hqiangwei") end
    local sorted = self:sortByKeepValue(cards, false)
    if not sorted then return unsupported("hqiangwei card values are unknown", "hqiangwei") end
    return #sorted > 0 and {sorted[1]:getEffectiveId()} or {}
end

ai_skill_cardask["@murasameself"] = function(self, options, request)
    local cards = self.player:getHandcards()
    if not cards or #cards == 0 then return unsupported("murasame self discard hand is unknown", "@murasameself") end
    local sorted = self:sortByKeepValue(cards, false)
    if not sorted then return unsupported("murasame self discard values are unknown", "@murasameself") end
    return sorted[1]:getEffectiveId()
end

local function murasame_kill(self, options, request)
    -- Slash effectiveness, armor reserve and double-Jink state are not part of
    -- the current value facade; returning pass would silently change legacy AI.
    return unsupported("murasame kill effect context is not projected", "@murasamekill")
end
ai_skill_cardask["@murasamekilla"] = murasame_kill
ai_skill_cardask["@murasamekillb"] = murasame_kill
ai_skill_cardask["@murasamekillc"] = murasame_kill

ai_skill_choice.mouthgun = function(self, options, request)
    return unsupported("mouthgun pindian result is not projected", "mouthgun")
end

ai_skill_pindian.mouthgun = function(self, options, request)
    return unsupported("mouthgun pindian requestor and candidate cards are not projected", "mouthgun")
end

-- 這些純值 card-use handlers 對應原本 useCardXXX 的判斷順序。
ai_card_use.rotenburo = function(self, card, use)
    local players = self.room:getAlivePlayers()
    if not players then return unsupported("rotenburo alive roster is unknown", "rotenburo") end
    local score = 0
    for _, player in ipairs(players) do
        local usable = self:canUse(card, AIList.new({player}))
        if usable == nil then return unsupported("rotenburo card legality is unknown", "rotenburo") end
        if usable then
            local friend, enemy = is_friend(self, player), is_enemy(self, player)
            if friend == nil or enemy == nil then return unsupported("rotenburo relation is unknown", "rotenburo") end
            local weak = false
            if friend or enemy then
                weak = self:isWeak(player)
                if weak == nil then return unsupported("rotenburo weakness is unknown", "rotenburo") end
            end
            if friend then score = score + 1; if weak then score = score + 1 end
            elseif enemy then score = score - 1; if weak then score = score - 1 end end
        end
    end
    if score >= 0 then use.card = card end
end

ai_card_use.bunkasai = function(self, card, use)
    local players = self.room:getAlivePlayers()
    if not players then return unsupported("bunkasai alive roster is unknown", "bunkasai") end
    local target, minimum
    for _, player in ipairs(players) do
        local usable = self:canUse(card, AIList.new({player}))
        if usable == nil then return unsupported("bunkasai card legality is unknown", "bunkasai") end
        if usable then
            local hand = player:getHandcardNum()
            if type(hand) ~= "number" then return unsupported("bunkasai hand count is unknown", "bunkasai") end
            if minimum == nil or hand < minimum then minimum, target = hand, player end
        end
    end
    if not target then return end
    local enemy = is_enemy(self, target)
    if enemy == nil then return unsupported("bunkasai target relation is unknown", "bunkasai") end
    if not enemy then return end
    -- hasTrickEffective/isGoodTarget require legacy native context and have no
    -- value-facade counterpart yet; do not approximate their combined branch.
    return unsupported("bunkasai effect and good-target policy are not projected", "bunkasai")
end

ai_skill_discard.bunkasai = function(self, options, request)
    local context = event_context(self)
    local use = type(context) == "table" and context.use or nil
    if not use then return unsupported("bunkasai discard use context is not projected", "bunkasai") end
    if use then
        local lose = self:needToLoseHp(self.player, use.from, use.card, true)
        if lose == nil then return unsupported("bunkasai HP-loss policy is unknown", "bunkasai") end
        if lose then return {} end
        local target, minimum
        if not AIValue.isList(use.to) then return unsupported("bunkasai targets are unknown", "bunkasai") end
        for _, player in ipairs(use.to) do
            local hand = player:getHandcardNum()
            if type(hand) ~= "number" then return unsupported("bunkasai hand count is unknown", "bunkasai") end
            if minimum == nil or hand < minimum then minimum, target = hand, player end
        end
        if target then
            local friend = is_friend(self, target)
            if friend == nil then return unsupported("bunkasai target relation is unknown", "bunkasai") end
            if friend then return unsupported("bunkasai trick effectiveness is not projected", "bunkasai") end
        end
    end
    local cards = self.player:getHandcards()
    if not cards then return unsupported("bunkasai hand is unknown", "bunkasai") end
    local count = type(options) == "table" and (options.max_count or options.min_count) or nil
    if type(count) ~= "number" then return unsupported("bunkasai discard count is unknown", "bunkasai") end
    local result, suits = {}, {}
    for _, candidate in ipairs(cards) do
        local suit = candidate:getSuitString()
        if not suits[suit] and #result < count then suits[suit] = true; result[#result + 1] = candidate:getEffectiveId() end
    end
    return result
end

ai_card_use.together_go_die = function(self, card, use)
    -- Physical known-card counts omit view-as Slash. Zero cannot justify pass.
    return unsupported("together_go_die needs the legacy Slash count, selector and dummy target plan", "together_go_die")
end
ai_card_use.mouthgun = function(self, card, use)
    if self.player:hasSkill("noswuyan") then return end
    return unsupported("mouthgun needs native max-card and distance policy", "mouthgun")
end

ai_card_use.shuugakulyukou = function(self, card, use)
    local friends = self:sort(self:getFriends(nil, true), "defense")
    if not friends then return unsupported("shuugakulyukou friend defense is unknown", "shuugakulyukou") end
    for _, friend in ipairs(friends) do
        local present = friend:containsTrick("shuugakulyukou")
        if present == nil then return unsupported("shuugakulyukou judging area is unknown", "shuugakulyukou") end
        if not present then use.card = card; use.to:append(friend); return end
    end
end

ai_card_use.strike_the_death = function(self, card, use)
    if self:isWeak() == nil then return unsupported("strike_the_death weakness is unknown", "strike_the_death") end
    if not self:isWeak() then use.card = card end
end

-- Rescue still needs current-dying context; do not claim this callback is covered.
ai_skill_use["@strike_the_death"] = function(self, prompt, request)
    return unsupported("strike_the_death ask-for-use needs a projected dying player and card candidate", "@strike_the_death")
end
