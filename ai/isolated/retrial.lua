-- Shared retrial selection over primitive projections, never native CardFilter/Room.
sgs = sgs or {}
sgs.ai_need_retrial = sgs.ai_need_retrial or {}
sgs.ai_need_retrial_func = sgs.ai_need_retrial_func or {}
sgs.ai_judgeGood = sgs.ai_judgeGood or {}
sgs.ai_retrial = sgs.ai_retrial or {}
sgs.ai_draw_count = sgs.ai_draw_count or {}

local function finite(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function lookup(values, id)
    if type(values) ~= "table" then return nil end
    local value = values[tostring(id)]
    if value == nil then value = values[id] end
    return value
end

local function card_view(card)
    if type(card) ~= "table" then return nil end
    if type(card.getEffectiveId) == "function" then return card end
    return CardView and CardView.new(card) or nil
end

local function player_view(self, player)
    if type(player) == "table" and type(player.objectName) == "function" then return player end
    local name = type(player) == "string" and player or type(player) == "table" and player.object_name
    if name and self.room then return self.room:findPlayerByObjectName(name, true) end
end

local function normalize(self, judge)
    if type(judge) ~= "table" or type(judge.reason) ~= "string" then return nil end
    local copy = {}
    for key, value in pairs(judge) do copy[key] = value end
    copy.who = player_view(self, judge.who)
    copy.card = card_view(judge.card)
    return copy
end

local function relation(self, judge)
    if not judge.who then return nil end
    if self:isFriend(judge.who) == true then return "friend" end
    if self:isEnemy(judge.who) == true then return "enemy" end
end

local function need_hook(reason)
    local hook = sgs.ai_need_retrial[reason]
    if hook == nil then hook = sgs.ai_need_retrial_func[reason] end
    return hook
end

local function scalar(player, method)
    if player and type(player[method]) == "function" then return player[method](player) end
end

local function overflow(self, player)
    if type(self.getOverflow) == "function" then return self:getOverflow(player) end
    local hand, limit = scalar(player, "getHandcardNum"), scalar(player, "getMaxCards")
    if finite(hand) and finite(limit) then return hand - limit end
end

local function crossbow(self, player)
    if type(self.hasCrossbowEffect) == "function"
        and self:hasCrossbowEffect(player) == true then return true end
    local equips = scalar(player, "getEquips")
    if not equips then return nil end
    for _, card in ipairs(equips) do
        if card:isKindOf("Crossbow") then return true end
    end
    local known = scalar(player, "getKnownCards")
    if known then
        for _, card in ipairs(known) do
            if card:isKindOf("Crossbow") then return true end
        end
    end
    return false
end

local function draw_count(self, player)
    local count = 2
    local skills = scalar(player, "getSkills")
    if not skills then return nil end
    for _, skill in ipairs(skills) do
        local name = scalar(skill, "objectName") or scalar(skill, "getName")
        local hook = name and sgs.ai_draw_count[name]
        if hook ~= nil then
            local value = type(hook) == "function" and hook(self, player, count) or hook
            if not finite(value) or value < 0 then return nil end
            count = value
        end
    end
    return count
end

function SmartAIView:needRetrial(judge)
    judge = normalize(self, judge)
    if not judge or type(judge.good) ~= "boolean" then return nil end
    local rel = relation(self, judge)
    local hook = need_hook(judge.reason)
    -- Explicit false is an answer. Hook errors propagate; invalid results stay unknown.
    if type(hook) == "boolean" then return hook end
    if type(hook) == "function" then
        local result = hook(self, judge, judge.good, judge.who, rel == "friend", judge.lord)
        if result ~= nil then
            if type(result) == "boolean" then return result end
            return nil
        end
    end
    if not judge.who then return nil end
    local reason = judge.reason
    if reason:find("beige", 1, true) then return true end
    if reason:find("tuntian", 1, true) then
        if not judge.who:hasSkill("zaoxian") and judge.who:getMark("zaoxian") < 1 then return false end
    end
    if reason == "supply_shortage" and rel == "friend"
        and judge.who:hasSkills("guidao|tiandu") then return false end
    if reason == "lightning" then
        local hp, chained = scalar(judge.who, "getHp"), scalar(judge.who, "isChained")
        if not finite(hp) or type(chained) ~= "boolean"
            or type(judge.who.hasArmorEffect) ~= "function" then return nil end
        local lion = judge.who:hasArmorEffect("SilverLion")
        if type(lion) ~= "boolean" then return nil end
        if lion and hp > 1 then return false end
        if chained then return nil end -- multi-recipient chain effects require a hook
    elseif reason == "indulgence" and rel == "friend" then
        local hp, hand = scalar(judge.who, "getHp"), scalar(judge.who, "getHandcardNum")
        local own_overflow = overflow(self, self.player)
        if not finite(hp) or not finite(hand) or not finite(own_overflow) then return nil end
        -- These native active-skill exceptions can override low hand/draw heuristics.
        if hand == 0 and judge.who:hasSkills("shenfen|jixi|lihun|heg_xiongyi|kurou") then return nil end
        local draw = draw_count(self, judge.who)
        if not finite(draw) then return nil end
        if own_overflow < 0 and (hp - hand >= draw
            or judge.who:hasSkill("tuxi") and hp > 2) then return false end
    elseif reason:find("luoshen", 1, true) and rel == "friend" then
        local hand = scalar(judge.who, "getHandcardNum")
        if not finite(hand) then return nil end
        if hand > 30 then return false end
        local repeating = crossbow(self, judge.who)
        if repeating == nil then return nil end
        if not repeating then
            local excess, own_hand = overflow(self, judge.who), scalar(self.player, "getHandcardNum")
            if not finite(excess) or not finite(own_hand) then return nil end
            if excess > 1 and own_hand < 3 then return false end
        end
    end
    if rel == "friend" then return not judge.good end
    if rel == "enemy" then return judge.good end
    -- Neutral is not an enemy. Only an explicit weakness projection supplies the
    -- original neutral-player policy; absent knowledge stays unknown.
    if type(judge.weak) == "boolean" then
        if judge.weak then return not judge.good end
        return judge.good
    end
    return nil
end

function SmartAIView:getFinalRetrial(owner, reason)
    local judge = type(reason) == "table" and reason
        or type(owner) == "table" and owner.judge
    if not judge and type(self.getJudge) == "function" then judge = self:getJudge() end
    if type(judge) ~= "table" or judge.retrial_candidates_complete ~= true
        or type(judge.retrial_candidates) ~= "table" then return nil, nil end
    local final, wizard = 0, nil
    -- Candidates must be projected in the native owner-relative action order.
    -- The final capable wizard wins; an earlier enemy does not outrank a later ally.
    for _, candidate in ipairs(judge.retrial_candidates) do
        if type(candidate.can_retrial) ~= "boolean" then return nil, nil end
        if candidate.can_retrial then
            local player = player_view(self, candidate.player)
            if not player then return nil, nil end
            local rel = relation(self, {who=player})
            if not rel then return nil, nil end
            final, wizard = rel == "friend" and 1 or 2, player
        end
    end
    return final, wizard
end

local function outcome(self, judge, card)
    local hook = sgs.ai_judgeGood[judge.reason]
    -- A function is an explicit candidate-outcome hook. A stored boolean in the
    -- legacy table describes the old judgment, not every candidate's outcome.
    if type(hook) == "function" then
        local value = hook(self, judge, card)
        if value ~= nil then
            if type(value) == "boolean" then return value end
            return nil
        end
    end
    if judge.outcomes_complete ~= true then return nil end
    return lookup(judge.outcome_by_id, card:getEffectiveId())
end

local function lightning_reserve(self, judge)
    if judge.reason == "lightning" then return {}, 0 end
    if judge.lightning_reserve_complete == true then
        local count = judge.lightning_holder_count
        if not finite(count) or count < 0 or count % 1 ~= 0
            or type(judge.lightning_candidate_ids) ~= "table" then return nil end
        return judge.lightning_candidate_ids, count
    end
    local players = self.room and self.room:getPlayers()
    if not players then return nil end
    for _, player in ipairs(players) do
        local judging = player:getJudgingArea()
        if not judging then return nil end
        for _, card in ipairs(judging) do
            -- Printed suit cannot prove a reserve candidate after recipient filters.
            if card:isKindOf("Lightning") then return nil end
        end
    end
    return {}, 0
end

function SmartAIView:getRetrialCardId(cards, judge, self_card, exchange)
    judge = normalize(self, judge)
    if type(cards) ~= "table" or not judge then return nil end
    local views, allowed = {}, {}
    for _, card in ipairs(cards) do
        local view = card_view(card)
        if not view then return nil end
        local id = view:getEffectiveId()
        if not finite(id) or id < 0 or id % 1 ~= 0 then return nil end
        views[#views + 1], allowed[id] = view, true
    end
    local hook = sgs.ai_retrial[judge.reason]
    if type(hook) == "function" then
        local id = hook(self, views, judge, self_card, exchange)
        if id ~= nil then
            if id == -1 or finite(id) and allowed[id] then return id end
            return nil
        end
    end
    if judge.reason:find("beige", 1, true) then return nil end
    local rel = relation(self, judge)
    if not rel or type(judge.good) ~= "boolean" then return nil end
    local reserve, reserve_count = lightning_reserve(self, judge)
    if not reserve then return nil end
    local wanted = rel == "friend"
    local normal, swaps, unknown_peach = {}, {}, false
    -- First establish the native can_use order; reservations apply after filtering.
    for _, card in ipairs(views) do
        local id = card:getEffectiveId()
        local good = outcome(self, judge, card)
        if type(good) ~= "boolean" then return nil end
        local protected = lookup(judge.protected_ids, id) == true
        local unknown = false
        if self_card ~= false and card:isKindOf("Peach") then
            if type(judge.peach_protected) ~= "boolean" then unknown = true
            else protected = protected or judge.peach_protected end
        end
        if good == wanted and not protected then
            if unknown then unknown_peach = true
            else normal[#normal + 1] = card end
        end
        if exchange == true and (good == judge.good or judge.pattern == ".") then
            -- Legacy exchange runs after normal Peach/reserve filtering and can
            -- exchange a Peach while preserving the current judgment outcome.
            swaps[#swaps + 1] = card
        end
    end
    -- Each Lightning holder removes the last remaining spade 2..9 candidate.
    -- An authority-complete set proves identical filter semantics for this count.
    local reserved = {}
    for index = #normal, 1, -1 do
        if reserve_count <= 0 then break end
        local id = normal[index]:getEffectiveId()
        if lookup(reserve, id) == true then
            reserved[index], reserve_count = true, reserve_count - 1
        end
    end
    local function select(pool, excluded)
        local best, best_value, preferred
        for index, card in ipairs(pool) do
            if not excluded[index] then
                local id = card:getEffectiveId()
                local value = self:getKeepValue(card)
                if not finite(value) then return nil end
                if not preferred and type(self.doDisCard) == "function"
                    and self:doDisCard(self.player, id) == true then preferred = id end
                if not best or value < best_value or value == best_value and id < best then
                    best, best_value = id, value
                end
            end
        end
        return preferred or best or -1
    end
    local selected = select(normal, reserved)
    if selected == nil or selected ~= -1 then return selected end
    -- An uncertain Peach never blocks a known non-Peach alternative. It does
    -- prevent claiming no normal retrial when that Peach is the only possibility.
    if unknown_peach then return nil end
    if exchange == true then return select(swaps, {}) end
    return -1
end