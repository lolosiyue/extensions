-- Cache identity is one viewer, one question and one board revision, all read from
-- the request. A new question or any board change misses, so a cached value never
-- outlives the snapshot it was computed from.
local function snapshot_cache_stamp(room,op,player)
    local world=room and rawget(room,"_world")
    if type(world)~="table"or type(world.self)~="table"then
        ai_unsupported("observer cache needs a world snapshot",op)
    end
    local ai=rawget(room,"_ai")
    local request=ai and ai.request
    local revision=tostring(world.revision)
    return {known=true,snapshot=true,scope="revision",epoch=revision,revision=revision,
        question=tostring(request and request.kind or "event")..":"..tostring(request and request.decision_id or 0),
        viewer=world.self.object_name}
end
local function same_snapshot_cache(left,right)
    return left and right and left.scope==right.scope and left.epoch==right.epoch
        and left.viewer==right.viewer and left.question==right.question and left.revision==right.revision
end

-- SmartAI 相等的純值工具函式。套件只註冊 hook／技能名單，不改這層。
-- 缺投影保留未知或 typed unsupported；估算需明示 provenance。只用值描述，不呼叫 Engine。

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

-- Audited strategy functions may return a source no-result nil. Raw facade
-- inputs never inherit that permission; provider identity is checked below.
local source_nil_providers = {}
local required_query_providers = setmetatable({}, {__mode = "k"})
local function query_provider(provider)
    return required_query_providers[provider] or provider
end
local original_nil_providers = {willUsePeachTo="originalHegemonyWillUsePeachTo",willUseLightning="originalHegemonyWillUseLightning",findLijianTarget="originalHegemonyFindLijianTarget",useCardByClassName="originalHegemonyUseCardByClassName",useCardGodSalvation="originalHegemonyUseCardGodSalvation",getCardRandomly="originalHegemonyGetCardRandomly",askForSkillInvoke="originalHegemonyAskForSkillInvoke",askForCard="originalHegemonyAskForCard",askForNullification="originalHegemonyAskForNullification",askForPlayerChosen="originalHegemonyAskForPlayerChosen",askForSuit="originalHegemonyAskForSuit",askForYiji="originalHegemonyAskForYiji",getCardNeedPlayer="originalHegemonyGetCardNeedPlayer",getMaxNumberCard="originalHegemonyMaxNumberCard",getMinNumberCard="originalHegemonyMinNumberCard",getLijianCard="originalHegemonyGetLijianCard",toTurnOver="originalHegemonyToTurnOver",isValuableCard="originalHegemonyIsValuableCard",getMaxCard="originalHegemonyGetMaxCard",getMinCard="originalHegemonyGetMinCard",hasTrickEffective = "originalHegemonyHasTrickEffective", hasWizard = "originalHegemonyHasWizard"}
function SmartAIView.isKnownNilStrategyResult(object, method, provider)
    if type(object) ~= "table" or getmetatable(object) ~= SmartAIView or type(provider) ~= "function" then return false end
    provider = query_provider(provider)
    if query_provider(source_nil_providers[method]) == provider then return true end
    local inovation_nil = {isValuableCard=true,shouldUseRende=true,getLijianCard=true,findLijianTarget=true}
    if inovation_nil[method] and provider == query_provider(SmartAIView["inovation_"..method]) then return true end
    local original = original_nil_providers[method]
    return original ~= nil and provider == query_provider(SmartAIView[original])
end
local function strategy_known(value, label)
    if value == nil then ai_unsupported("shared strategy input is unknown: " .. label, label) end
    return value
end
local function strategy_call(object, method, ...)
    if AIValue.isPlayer(object) then
        if method == "getMark" and type(object.getStrategyMark) == "function" then method = "getStrategyMark" end
        if method == "hasFlag" and type(object.getStrategyFlag) == "function" then method = "getStrategyFlag" end
    end
    if not object or type(object[method]) ~= "function" then ai_unsupported("shared strategy method is unavailable", method) end
    local provider = object[method]
    local value = provider(object, ...)
    if AIUnsupported.is(value) then error(value, 0) end
    if value == nil and SmartAIView.isKnownNilStrategyResult(object, method, provider) then return nil end
    if value == nil and method == "hasUsed" and AIValue.isPlayer(object) then
        local room = rawget(object,"_room")
        local ai = room and room._ai
        if ai and not same_player(object,ai.player) then
            local history = ...
            return ai:useKnowledgeEstimate({value=false,status="estimate",basis="no observed public use; inactive action-history prior",
                viewer=ai.player:objectName(),observer=ai.player:objectName(),target=object:objectName(),history=history},"hasUsed")
        end
    end
    return strategy_known(value, method)
end
-- strategy_call that also rejects an unsupported signal coming back as a value
-- (the hasUsed estimate path returns one without raising it).
local function checked_strategy_call(object, method, ...)
    local value = strategy_call(object, method, ...)
    if AIUnsupported.is(value) then error(value, 0) end
    return value
end
-- Stand-in for a donor `object:method(...)` written as donor_call(object, "method", ...).
-- A nil receiver raises the same plain Lua error the donor would, not an unsupported signal.
local function donor_call(object, method, ...)
    if object == nil then error("attempt to index a nil value", 0) end
    return checked_strategy_call(object, method, ...)
end
local function strategy_pile_count(player, name)
    if type(player.getPileCount) == "function" then return strategy_call(player, "getPileCount", name) end
    return #strategy_call(player, "getPile", name)
end
-- Friend and enemy are separate donor predicates. In particular two neutral
-- players can satisfy both two-argument predicates, so never collapse them to
-- one relation enum or ask for another AI's private relation matrix.
local function strategy_mark(self, player, name)
    if AIValue.isPlayer(player) and type(player.getStrategyMark) == "function" then
        return strategy_known(player:getStrategyMark(name), name)
    end
    local view = rawget(player, "_view")
    local marks = type(view) == "table" and view.public_marks
    if type(marks) ~= "table" then ai_unsupported("public marks are unknown", name) end
    local value = marks[name]
    if value == nil and same_player(player, self.player) then return 0 end
    if type(value) ~= "number" then
        if type(player.getKnownMark) == "function" then value = player:getKnownMark(name) end
        if type(value) ~= "number" then ai_unsupported("mark absence is not authorized as zero", name) end
    end
    return value
end


-- Knowledge results separate observable facts from policy estimates. Consumers
-- use this gate so estimated decisions retain an auditable request-local basis.
function SmartAIView:cardSkillNamesKnowledge(card, context)
    context = context or "card.skill_names"
    if not AIValue.isCard(card) and not AIValue.isConversion(card) then
        ai_unsupported("card skill-chain knowledge needs a typed card", context)
    end
    local view = rawget(card, "_view")
    if type(view) ~= "table" then ai_unsupported("card skill-chain metadata is absent", context) end
    if view.skill_names_complete ~= nil and type(view.skill_names_complete) ~= "boolean" then
        ai_unsupported("invalid card skill-chain completeness", context)
    end
    if view.skill_names_complete == false then
        -- Native explicitly withholds the private change_cards chain while
        -- disclosing the activation on this public face. Card::getSkillNames
        -- appends the current getSkillName even when it is the empty string.
        local activation = view.skill_name
        if type(activation) ~= "string" then
            ai_unsupported("public card activation name is unknown", context)
        end
        if activation:sub(1, 1) == "_" then activation = activation:sub(2) end
        return self:useKnowledgeEstimate({value = {activation}, status = "estimate",
            basis = "public_activation_only_unobserved_private_change_card_chain_omitted",
            viewer = self.player:objectName(), observer = self.player:objectName(),
            public_activation = activation, card_name = view.name}, context)
    end
    local names = type(card.getSkillNames) == "function" and card:getSkillNames() or nil
    if not AIValue.isList(names) then
        ai_unsupported("complete card skill-chain metadata is unavailable", context)
    end
    local result = {}
    for _, name in ipairs(names) do
        if type(name) ~= "string" then ai_unsupported("invalid card skill-chain name", context) end
        result[#result + 1] = name
    end
    return result
end

-- Equal estimate entries share one signature of their scalar fields (count
-- aside). Each log keeps an index, caught up with entries appended elsewhere.
local estimate_indexes = setmetatable({}, {__mode = "k"})
local estimate_common_keys = {"context", "status", "value", "basis", "viewer", "observer"}
local estimate_common = {count = true}
for _, key in ipairs(estimate_common_keys) do estimate_common[key] = true end
local function estimate_scalar(value)
    if value == nil then return "~" end
    if type(value) == "number" then return string.format("n%.17g", value) end
    if type(value) == "boolean" then return value and "b1" or "b0" end
    return "s" .. value
end
local function estimate_signature(entry)
    local parts = {}
    for index, key in ipairs(estimate_common_keys) do parts[index] = estimate_scalar(entry[key]) end
    local extra
    for key in pairs(entry) do
        if not estimate_common[key] then extra = extra or {}; extra[#extra + 1] = key end
    end
    if extra then
        table.sort(extra)
        for _, key in ipairs(extra) do parts[#parts + 1] = key .. "=" .. estimate_scalar(entry[key]) end
    end
    return table.concat(parts, "\0")
end
local function estimate_lookup(log, entry)
    local index = estimate_indexes[log]
    if not index or index.size > #log then
        index = {size = 0, by_signature = {}}
        estimate_indexes[log] = index
    end
    for position = index.size + 1, math.min(#log, 255) do
        local signature = estimate_signature(log[position])
        index.by_signature[signature] = index.by_signature[signature] or log[position]
    end
    index.size = math.min(#log, 255)
    return index.by_signature[estimate_signature(entry)], index
end

function SmartAIView:useKnowledgeEstimate(result, context)
    if type(result) ~= "table" or (result.status ~= "exact" and result.status ~= "estimate" and result.status ~= "unknown") then
        ai_unsupported("invalid knowledge result", context)
    end
    if result.status == "unknown" or result.value == nil then ai_unsupported(result.basis or "knowledge is unavailable", context) end
    if result.status == "estimate" then
        self.request = self.request or {}
        self.request.scratch = self.request.scratch or {}
        local log = self.request.scratch.knowledge_estimates or {}
        self.request.scratch.knowledge_estimates = log
        local entry = {context = context}
        for key, value in pairs(result) do
            if type(value) == "string" or type(value) == "number" or type(value) == "boolean" then entry[key] = value end
        end
        -- Bound native result size without hiding repeated decisions. Compare
        -- every scalar metadata field, so distinct subjects/values stay apart.
        local matching
        if entry.count ~= nil then
            -- A count carried by the result itself is compared as a field.
            for _, previous in ipairs(log) do
                local same = true
                for key, value in pairs(entry) do if previous[key] ~= value then same = false; break end end
                if same then
                    for key, value in pairs(previous) do
                        if key ~= "count" and entry[key] ~= value then same = false; break end
                    end
                end
                if same then matching = previous; break end
            end
        else
            matching = estimate_lookup(log, entry)
        end
        if matching then matching.count = (matching.count or 1) + 1
        elseif #log < 255 then log[#log + 1] = entry
        else
            local summary = log[256]
            if not summary then
                summary = {status = "estimate", context = "knowledge_estimates.capacity", count = 0,
                    basis = "additional_distinct_estimate_details_omitted_after_255_entries"}
                log[256] = summary
            end
            summary.count = summary.count + 1
        end
    end
    return result.value, result.status
end

function SmartAIView:estimateKnownCards(player, class_name, observer, viewas, flags)
    observer = observer or self.player
    local ok, value, coverage = pcall(getKnownCard, player, self.player, class_name, viewas, flags)
    local unresolved_conversion = false
    if not ok then
        if not AIUnsupported.is(value) then error(value, 0) end
        if not viewas then return {status = "unknown", basis = value.reason} end
        -- Conversion classification can depend on a hidden cost or an unported
        -- policy. Retain the printed-card lower bound with an explicit estimate.
        value, coverage = getKnownCard(player, self.player, class_name, false, flags)
        unresolved_conversion = true
    end
    if value == nil then return {status = "unknown", basis = "viewer card classification unavailable"} end
    local result = coverage or {value = value, status = "exact", basis = "viewer_visible"}
    if unresolved_conversion then result.status, result.basis = "estimate", "printed_card_lower_bound_unresolved_viewas" end
    result.value, result.viewer, result.observer = value, self.player:objectName(), observer:objectName()
    if not same_player(observer, self.player) then
        -- This intentionally substitutes the acting viewer's legal knowledge for
        -- the donor's hypothetical observer. Never fetch that observer's hand.
        result.status, result.basis = "estimate", "observer_substitution_with_viewer_knowledge"
    end
    return result
end

function SmartAIView:estimateHasVirtualCard(player, class_name)
    if same_player(player, self.player) then
        local ok, cards = pcall(self.getCard, self, class_name, true)
        if ok and type(cards) == "table" then
            for _, card in ipairs(cards) do
                if AIValue.isConversion(card) or strategy_call(card, "getTypeId") < 1 or strategy_call(card, "isVirtualCard") then
                    return {value = true, status = "exact", basis = "owner_authoritative_card_selection"}
                end
            end
            return {value = false, status = "exact", basis = "owner_complete_card_selection"}
        elseif not ok and not AIUnsupported.is(cards) then error(cards, 0) end
    end
    local function result(value, basis, hidden)
        return {value = value, status = "estimate", basis = basis, hidden_count = hidden or 0,
            viewer = self.player:objectName(), observer = player:objectName()}
    end
    local hand, equips = player:getKnownCards(), player:getEquips()
    local total = player:getHandcardNum()
    if type(hand) ~= "table" or type(equips) ~= "table" or type(total) ~= "number" then
        return {status = "unknown", basis = "visible cards/counts unavailable"}
    end
    local hidden, candidates = math.max(0, total - #hand), {}
    local function add(skill, kind, predicate, equip, prior)
        if kind ~= class_name and not (class_name == "Slash" and kind == "FireSlash") then return end
        local has = player:hasSkill(skill)
        if has == nil then ai_unsupported("public skill presence is unknown", "estimateHasVirtualCard") end
        if has then candidates[#candidates + 1] = {predicate = predicate, equip = equip, prior = prior, skill = skill} end
    end
    add("wusheng", "Slash", function(card)return strategy_call(card,"isRed") and not strategy_call(card,"isKindOf","Peach")end, true, .45)
    add("longdan", "Slash", function(card)return strategy_call(card,"isKindOf","Jink")end, false, .15)
    add("longdan", "Jink", function(card)return strategy_call(card,"isKindOf","Slash")end, false, .25)
    add("qingguo", "Jink", function(card)return strategy_call(card,"isBlack")end, false, .5)
    add("kanpo", "Nullification", function(card)return strategy_call(card,"isBlack")end, false, .5)
    if player:hasSkill("jijiu") and strategy_call(player,"getPhase") == sgs.Player_NotActive then
        add("jijiu", "Peach", function(card)return strategy_call(card,"isRed")end, true, .5)
    end
    if player:hasSkill("longhun") and strategy_call(player,"getHp") <= 1 then
        for _, row in ipairs({{"FireSlash", "diamond"}, {"Jink", "club"}, {"Peach", "heart"}, {"Nullification", "spade"}}) do
            add("longhun", row[1], function(card)return strategy_call(card,"getSuitString") == row[2]end, true, .25)
        end
    end
    for _, candidate in ipairs(candidates) do
        for _, card in ipairs(hand) do
            if not strategy_call(card, "isKindOf", class_name) and candidate.predicate(card) then return result(true, "recognized_conversion_visible_cost:" .. candidate.skill, hidden) end
        end
        if candidate.equip then
            for _, card in ipairs(equips) do
                if not strategy_call(card, "isKindOf", class_name) and candidate.predicate(card) then return result(true, "recognized_conversion_visible_cost:" .. candidate.skill, hidden) end
            end
        end
        if hidden > 0 and 1 - (1 - candidate.prior) ^ hidden >= .5 then
            local r = result(true, "recognized_conversion_hidden_cost_prior:" .. candidate.skill, hidden)
            r.success_probability = 1 - (1 - candidate.prior) ^ hidden
            return r
        end
    end
    -- This conservative estimate is not a claim that no conversion exists.
    return result(false, #candidates > 0 and "recognized_conversion_insufficient_visible_or_likely_cost" or "no_recognized_conversion_from_public_skills", hidden)
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
        return #strategy_call(self, "addHandPile")
    end
    local known = getKnownCards(player, self.player)
    if not known then return nil end
    return #known
end

local function card_selection_known(value, field)
    if value == nil then ai_unsupported("card selection projection is unknown: " .. field, "getCards") end
    return value
end

local function physical_selection_only(self, include_guhuo)
    local skills = card_selection_known(self.player:getSkills(), "skills")
    for _, skill in ipairs(skills) do
        local name = skill:objectName()
        if not card_selection_known(skill:isInvalid(), "skill invalidity") then
            -- These callbacks require response enablement, ordered legacy policy
            -- and authority-issued tickets. Registry absence alone is not proof
            -- that a visible ViewAsSkill has no response conversion.
            local view_as = card_selection_known(skill:inherits("ViewAsSkill"), "skill classes")
            local filter = card_selection_known(skill:inherits("FilterSkill"), "skill classes")
            if view_as or filter or name == "weidi" then
                ai_unsupported("response conversion/filter policy is not ported", name)
            end
            for _, registry in ipairs({"ai_view_as", "ai_cardsview_valuable", "ai_cardsview"}) do
                if type(sgs[registry]) == "table" and sgs[registry][name] ~= nil then
                    ai_unsupported("response conversion callback needs a ticket policy", name)
                end
            end
            if include_guhuo and type(sgs.ai_guhuo_card) == "table" and sgs.ai_guhuo_card[name] ~= nil then
                ai_unsupported("Guhuo callback needs a ticket policy", name)
            end
        end
    end
end

local function selection_callback(self, method, class_name, ...)
    if type(self[method]) == "function" then
        local result = self[method](self, class_name, ...)
        if AIUnsupported and AIUnsupported.is(result) then error(result, 0) end
        return result
    end
    if method == "parseGuhuoPolicyResult" or method == "parseCardsViewPolicyResult" then
        ai_unsupported("source policy parser is unavailable", method)
    end
    physical_selection_only(self, method == "getGuhuoCard")
    if method == "getSkillViewCard" then return nil end
    return {}
end

local function physical_card_selection(self, class_name, flags, get_card, acards)
    local haspile = type(flags) ~= "string"
    local source = card_selection_known(self.player:getCards(haspile and "he" or flags), "owned zones")
    local cards = {}
    for _, card in ipairs(source) do cards[#cards + 1] = card end
    local handpile
    if acards then
        -- Fixed SWIG ServerPlayer::addCard accepts an integer, not a Card.
        -- An empty source list is legal; a nonempty Card list fails before
        -- any mutation. Numeric entries would mutate live hand state before
        -- the later card-method error, which this value VM must not perform.
        if type(acards) ~= "table" then error("sgs.qlist: list is not a valid type", 0) end
        for _, card in ipairs(acards) do
            if type(card) == "number" or type(card) == "string" and tonumber(card) ~= nil then
                ai_unsupported("source numeric acards mutates the native hand before a later ordinary error", "source.getCards.acards_numeric_prefix")
            end
            error("source ServerPlayer::addCard argument 2 requires int, not a card value", 0)
        end
        cards = acards
    elseif haspile then
        handpile = card_selection_known(self.player:getHandPile(), "hand pile IDs")
        for _, id in ipairs(handpile) do
            cards[#cards + 1] = card_selection_known(self:getKnownCardById(id), "hand pile card")
        end
    end
    -- getCards reads the membership list again after appending; getCard keeps
    -- its first list. Preserve both source read points, not a shared shortcut.
    if not get_card or not handpile then
        handpile = card_selection_known(self.player:getHandPile(), "hand pile IDs")
    end
    local result = {}
    for _, card in ipairs(cards) do
        if not card_selection_known(card:hasFlag("using"), "using") then
            local place = card_selection_known(self.room:getCardPlace(card:getId()), "card place")
            local matches = card_selection_known(card:isKindOf(class_name), "card class") or class_name == "."
            local in_handpile = false
            if matches and place == sgs.Player_PlaceSpecial then
                local id = card:getId()
                for _, pile_id in ipairs(handpile) do if pile_id == id then in_handpile = true; break end end
            end
            if matches and (place ~= sgs.Player_PlaceSpecial or in_handpile) then
                result[#result + 1] = card
            else
                local converted = selection_callback(self, "getSkillViewCard", class_name, card, self.player, place)
                if converted then result[#result + 1] = converted end
            end
        end
    end
    return result
end

local function selection_locked(self, card)
    if AIValue.isConversion(card) then
        if type(card.isLocked) ~= "function" then ai_unsupported("conversion lock projection is unavailable", "getCard") end
        return card_selection_known(card:isLocked(), "conversion locked")
    end
    if type(self.player.isLocked) ~= "function" then ai_unsupported("owner card lock projection is unavailable", "getCards") end
    return card_selection_known(self.player:isLocked(card), "locked")
end

function SmartAIView:getCards(class_name, flags, acards)
    if type(class_name) ~= "string" then return {} end
    if string.find(class_name, ",", 1, true) then
        local merged = {}
        for piece in string.gmatch(class_name .. ",", "(.-),") do
            for _, card in ipairs(self:getCards(piece, flags, acards)) do merged[#merged + 1] = card end
        end
        return merged
    end
    local cards = physical_card_selection(self, class_name, flags, false, acards)
    local views = selection_callback(self, "cardsView", class_name)
    for i, value in ipairs(views) do
        local card = selection_callback(self, "parseCardsViewPolicyResult", value, i, views)
        if card then cards[#cards + 1] = card end
    end
    for i = #cards, 1, -1 do
        if selection_locked(self, cards[i]) then table.remove(cards, i) end
    end
    return cards
end

local function selection_split(self, value, write)
    if write then
        local result = self:setStrategyMemory("card_selection_split", value)
        if AIUnsupported and AIUnsupported.is(result) then error(result, 0) end
        return value
    end
    local result, known = self:getStrategyMemory("card_selection_split")
    if AIUnsupported and AIUnsupported.is(result) then error(result, 0) end
    if known and result ~= 0 and result ~= 1 then
        ai_unsupported("malformed source split-selection state", "getCard.isSplit")
    end
    -- A never-written viewer cache retains nil, not an invented written zero.
    -- The old cross-viewer Lua global is deliberately not read in this VM.
    return known and result or nil
end

local function selection_sort(self, cards)
    local result = self:sortByUsePriority(cards)
    if AIUnsupported and AIUnsupported.is(result) then error(result, 0) end
    -- Source sorts its Lua array in place and ignores the helper return.
end

function SmartAIView:getCard(class_name, islist, cardsview_context)
    if type(class_name) ~= "string" then return islist and {} end
    local cards = {}
    if string.find(class_name, ",", 1, true) then
        selection_split(self, 1, true)
        for piece in string.gmatch(class_name .. ",", "(.-),") do
            for _, card in ipairs(self:getCard(piece, true, cardsview_context)) do cards[#cards + 1] = card end
        end
        selection_split(self, 0, true)
        selection_sort(self, cards)
        return islist and cards or cards[1]
    end
    -- Each comma component completes its own source filtering before the next
    -- component enumerates; only the enclosing split performs the final sort.
    local guhuo = selection_callback(self, "getGuhuoCard", class_name)
    for i, value in ipairs(guhuo) do
        local card = selection_callback(self, "parseGuhuoPolicyResult", value, i, guhuo)
        if card then cards[#cards + 1] = card end
    end
    local views = selection_callback(self, "cardsView", class_name, cardsview_context)
    for i, value in ipairs(views) do
        local card = selection_callback(self, "parseCardsViewPolicyResult", value, i, views)
        if card then cards[#cards + 1] = card end
    end
    for _, card in ipairs(physical_card_selection(self, class_name, nil, true)) do cards[#cards + 1] = card end
    for i = #cards, 1, -1 do
        local card, keep = cards[i], true
        local jinchan = card_selection_known(card:isKindOf("Jinchantuoqiao"), "Jinchantuoqiao class")
        if not jinchan then
            local key = card_selection_known(card:getLegacyStringKey(), "source card string")
            if type(key) ~= "string" then ai_unsupported("malformed source card string", "getCard") end
            jinchan = string.find(key, "jinchantuoqiao", 1, true) ~= nil
        end
        if jinchan then
            local ids = {}
            for _, id in ipairs(card_selection_known(self.player:handCards(), "hand IDs")) do ids[#ids + 1] = id end
            for _, paid in ipairs(card_selection_known(card:getSubcards(), "subcards")) do
                for j, id in ipairs(ids) do if id == paid then table.remove(ids, j); break end end
            end
            for _, id in ipairs(ids) do
                local hand = card_selection_known(self:getKnownCardById(id), "hand card face")
                if not card_selection_known(hand:isKindOf("Jinchantuoqiao"), "hand card class") then
                    keep = false
                    break
                end
            end
        end
        if not keep or selection_locked(self, card) then table.remove(cards, i) end
    end
    if selection_split(self) ~= 1 then selection_sort(self, cards) end
    return islist and cards or cards[1]
end

function SmartAIView:isValuableCard(card, player)
    player = player or self.player
    local function matches(class) return isCard(class, card, player) end
    if strategy_call(player, "getPhase") == sgs.Player_Play then
        if matches("ExNihilo") and not strategy_call(player, "isLocked", card) then return true end
    else
        if matches("Nullification") and getCardsNum("Nullification", player, self.player) < 2
            and strategy_call(player, "hasSkills", "jizhi|nosjizhi|jilve")
            or matches("Jink") and getCardsNum("Jink", player, self.player) < 2 then return true end
    end
    if matches("Peach") and getCardsNum("Peach", player, self.player) <= 2
        or strategy_call(self, "isWeak", player) and matches("Analeptic") then return true end
    -- Preserve this call's strategy/cache/RNG effects. The fixed donor compares
    -- its undefined global `dangerous`, rather than the returned local `id`.
    self:getDangerousCard(player)
    strategy_call(card, "getEffectiveId") -- retain donor comparison evaluation
    local id = self:getValuableCard(player)
    if strategy_call(card, "getEffectiveId") == id then return true end
    return false -- donor's known nil/no; shared predicate ABI preserves truthiness
end

local function pindian_known(value, field)
    if value == nil then ai_unsupported("Pindian projection is unknown: " .. field, "getPindianCard") end
    return value
end

local function point_of(player, card)
    local point = pindian_known(card:getNumber(), "number")
    if type(point) ~= "number" then ai_unsupported("Pindian number is invalid", "getPindianCard") end
    if pindian_known(player:hasSkill("tianbian"), "tianbian") then
        local suit = pindian_known(card:getSuit(), "suit")
        if sgs.Card_Heart == nil then ai_unsupported("heart enum is unavailable", "getPindianCard") end
        if suit == sgs.Card_Heart then point = 13 end
    end
    return point
end

local function best_visible_card(self, player, cards, mode)
    local own = same_player(player, self.player)
    if cards == nil then
        if own then cards = player:getHandcards()
        else cards = player:getKnownCards() end
    end
    cards = pindian_known(cards, "visible cards")
    -- Supplied opponent cards are not automatically authorized as visible.
    -- Only the viewer's own hand or the opponent's known-card projection may be used.
    local visible = {}
    if not own then
        for _, card in ipairs(pindian_known(player:getKnownCards(), "known cards")) do
            visible[pindian_known(card:getEffectiveId(), "card id")] = true
        end
    end
    local function scan(skip_valuable)
        local best, best_point = nil, mode == "max" and 0 or 14
        for _, card in ipairs(cards) do
            if own or visible[card:getEffectiveId()] then
                local valuable = false
                if skip_valuable and own then
                    valuable = pindian_known(self:isValuableCard(card, player), "valuable card")
                end
                if not valuable then
                    local point = point_of(player, card)
                    if (mode == "max" and point > best_point) or (mode == "min" and point < best_point) then
                        best, best_point = card, point
                    end
                end
            end
        end
        return best, best_point
    end
    -- Legacy min never skips valuable cards. Max retries all own cards only
    -- when its first pass found none, retaining first-in-input tie order.
    local card, point = scan(mode == "max")
    if own and mode == "max" and not card then card, point = scan(false) end
    if own and mode == "max" and point > 0 then
        local xiechan = pindian_known(player:hasFlag("AI_XiechanUsing"), "AI_XiechanUsing")
        local prefer_non_slash = xiechan
        if not prefer_non_slash then
            prefer_non_slash = pindian_known(player:hasSkills("tianyi|dahe|xianzhen"), "Pindian skills")
        end
        if prefer_non_slash then
            for _, candidate in ipairs(cards) do
                -- Deliberately compare printed number, as the donor does after
                -- tianbian; do not reinterpret this as an adjusted-point tie.
                if pindian_known(candidate:getNumber(), "number") == point
                    and not isCard("Slash", candidate, player) then return candidate, point end
            end
        end
        if pindian_known(player:hasSkill("qiaoshui"), "qiaoshui") then
            for _, candidate in ipairs(cards) do
                if pindian_known(candidate:getNumber(), "number") == point then
                    local ndtrick
                    if type(candidate.isNDTrick) == "function" then ndtrick = candidate:isNDTrick()
                    else ndtrick = candidate:isKindOf("NDTrick") end
                    if not pindian_known(ndtrick, "non-delayed trick") then return candidate, point end
                end
            end
        end
    end
    return card, point
end

-- Full fixed max/min bodies keep their different visibility and point-read
-- order. The omitted hidden hand faces cannot contribute to either result.
local function source_pindian_cards(self, player, cards)
    if not cards then
        if same_player(player, self.player) then cards = player:getHandcards()
        else cards = player:getKnownCards() end
    end
    return sgs.QList2Table(pindian_known(cards, "visible cards"))
end
local function source_can_see_hand(self, player)
    local method = self.player.canSeeHandcard
    if type(method) ~= "function" then ai_unsupported("viewer hand-visibility query is unavailable", "getPindianCard.visibility") end
    return method(self.player, player)
end
local function source_pindian_visible(self, player, card, minimum)
    local unknown = false
    local function test(value)
        if AIUnsupported and AIUnsupported.is(value) then error(value, 0) end
        if value == nil then unknown = true; return false end
        return value
    end
    -- An unknown disjunct is not false: another lawful true disjunct proves
    -- visibility; otherwise the whole predicate remains unknown.
    if minimum then
        if test(card:hasFlag("visible")) or test(source_can_see_hand(self, player)) then return true end
    else
        if test(source_can_see_hand(self, player)) or test(card:hasFlag("visible")) then return true end
    end
    if test(card:hasFlag("visible_" .. self.player:objectName() .. "_" .. player:objectName())) then return true end
    if unknown then ai_unsupported("source card visibility is unknown", "getPindianCard.visibility") end
    return false
end

function SmartAIView:getMaxCard(player, cards)
    player = player or self.player
    cards = source_pindian_cards(self, player, cards)
    if #cards < 1 then return end
    local max_card, max_point = nil, 0
    for _, card in ipairs(cards) do
        if not (same_player(player, self.player) and strategy_call(self, "isValuableCard", card))
            and source_pindian_visible(self, player, card, false) then
            local point = strategy_call(card, "getNumber")
            if strategy_call(player, "hasSkill", "tianbian") and strategy_call(card, "getSuit") == sgs.Card_Heart then point = 13 end
            if point > max_point then max_point, max_card = point, card end
        end
    end
    if same_player(player, self.player) and not max_card then
        for _, card in ipairs(cards) do
            local point = strategy_call(card, "getNumber")
            if strategy_call(player, "hasSkill", "tianbian") and strategy_call(card, "getSuit") == sgs.Card_Heart then point = 13 end
            if point > max_point then max_point, max_card = point, card end
        end
    end
    if not same_player(player, self.player) then return max_card end
    if max_point > 0 then
        if strategy_call(self.player, "hasFlag", "AI_XiechanUsing") or strategy_call(player, "hasSkills", "tianyi|dahe|xianzhen") then
            for _, card in ipairs(cards) do
                if strategy_call(card, "getNumber") == max_point and not isCard("Slash", card, player) then return card end
            end
        end
        if strategy_call(player, "hasSkill", "qiaoshui") then
            for _, card in ipairs(cards) do
                if strategy_call(card, "getNumber") == max_point and not strategy_call(card, "isNDTrick") then return card end
            end
        end
    end
    return max_card
end

function SmartAIView:getMinCard(player, cards)
    player = player or self.player
    cards = source_pindian_cards(self, player, cards)
    if #cards < 1 then return end
    local min_card, min_point = nil, 14
    for _, card in ipairs(cards) do
        if source_pindian_visible(self, player, card, true) then
            local point = strategy_call(card, "getNumber")
            if strategy_call(card, "getSuit") == sgs.Card_Heart and strategy_call(player, "hasSkill", "tianbian") then point = 13 end
            if point < min_point then min_point, min_card = point, card end
        end
    end
    return min_card
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

-- smart-ai.lua:4115–4145. Two-argument friendship/enmity use the
-- viewer predicates (including controller links), never a foreign AI matrix.
-- Keep the donor's getter order: friends are tested before seat arithmetic;
-- enemies after it, and getNumBySeat recomputes the destination per player.
function SmartAIView:getEnemyNumBySeat(from, to, target, include_neutral)
    local players = strategy_call(self.room, "getAlivePlayers")
    local to_seat = (strategy_call(to, "getSeat") - strategy_call(from, "getSeat"))
        % strategy_call(players, "length")
    local count = 0
    target = target or from
    for _, player in ipairs(players) do
        if (strategy_call(player, "getSeat") - strategy_call(from, "getSeat"))
            % strategy_call(players, "length") < to_seat
            and (strategy_call(self, "isEnemy", target, player)
                or include_neutral and not strategy_call(self, "isFriend", target, player)) then
            count = count + 1
        end
    end
    return count
end

function SmartAIView:getFriendNumBySeat(from, to)
    local players = sgs.QList2Table(strategy_call(self.room, "getAlivePlayers"))
    local count = 0
    for _, player in ipairs(players) do
        if strategy_call(self, "isFriend", from, player)
            and (strategy_call(player, "getSeat") - strategy_call(from, "getSeat")) % #players
                < (strategy_call(to, "getSeat") - strategy_call(from, "getSeat")) % #players then
            count = count + 1
        end
    end
    return count
end

function SmartAIView:getNumBySeat(from, to)
    local players = sgs.QList2Table(strategy_call(self.room, "getAlivePlayers"))
    local count = 0
    for _, player in ipairs(players) do
        if (strategy_call(player, "getSeat") - strategy_call(from, "getSeat")) % #players
            < (strategy_call(to, "getSeat") - strategy_call(from, "getSeat")) % #players then
            count = count + 1
        end
    end
    return count
end

function SmartAIView:hasWizard(players, onlyharm)
    local skills = onlyharm and sgs.wizard_harm_skill or sgs.wizard_skill
    for _, player in sgs.list(players) do
        -- Source reads each player's skill predicate in list order. Unknown
        -- is not the source no-result nil and must not satisfy `not hasWizard`.
        local has = strategy_call(player, "hasSkills", skills)
        local row = type(player)=="table" and rawget(player,"_view")
        if has==false and type(row)=="table" and row.skills_complete~=true then
            ai_unsupported("wizard skill absence is not visible", "hasWizard")
        end
        if has then return true end
    end
end

function SmartAIView:strategyProhibited(from, to, card)
    if type(from.isProhibited) ~= "function" then ai_unsupported("prohibition query is unavailable", "strategyProhibited") end
    local value = from:isProhibited(to, card)
    if type(value) == "boolean" then return value end
    if same_player(from, self.player) then ai_unsupported("owner prohibition rule is absent", "strategyProhibited") end
    strategy_call(from, "getSkills")
    strategy_call(to, "getSkills")
    -- The remaining Slash/Trick pipeline still evaluates public prohibit and
    -- target-revise callbacks. Only unobservable native rule state uses this
    -- explicit prior; the estimate grants no authority to play a card.
    return self:useKnowledgeEstimate({value = false, status = "estimate", viewer = self.player:objectName(),
        source = from:objectName(), target = to:objectName(), card = strategy_call(card, "objectName"),
        basis = "unobserved_private_prohibition_assumed_absent_public_ai_rules_evaluated_by_consumer"}, "strategyProhibited")
end

function SmartAIView:slashProhibit(card, to, from)
    local mode = strategy_call(self.room, "getMode")
    if mode:find("_mini_36") then return strategy_call(self.player, "hasSkill", "keji") end
    card, from = card or self:classProbe("Slash"), from or self.player
    if self:strategyProhibited(from, to, card) then return true end
    for _, skill in ipairs(strategy_call(to, "getSkills")) do
        local hook = sgs.ai_slash_prohibit[strategy_call(skill, "objectName")]
        if type(hook) == "function" and hook(self, from, to, card) then return true end
    end
    if strategy_call(self, "isFriend", to, from) and strategy_call(to, "isLord") and strategy_call(self, "isWeak", to) then return true end
    return false
end

function SmartAIView:slashIsEffective(slash, to, from, ignore_armor)
    from = from or self.player
    if self:strategyProhibited(from, to, slash) then return false end
    local use = {card = slash, from = from, to = AIList.new({to})}
    ignore_armor = ignore_armor or self:cardFlagKnowledge(slash, "Qinggang", "slashIsEffective.armor") or strategy_call(self, "ignoreArmor", from, to)
    local armor_names
    for _, name in ipairs(self:getConnections(to)) do
        if ignore_armor and armor_names == nil then
            armor_names = {}
            if type(self.room.getArmorNames) == "function" then
                for _, armor in ipairs(strategy_call(self.room, "getArmorNames")) do armor_names[armor] = true end
            else armor_names = strategy_known(sgs.armorName, "public armor names") end
        end
        if not (ignore_armor and armor_names[name]) then
            local hook = (sgs.ai_target_revises or {})[name]
            if type(hook) == "function" and hook(to, slash, self, use) then return false end
        end
    end
    return strategy_call(self, "ajustDamage", from, to, 1, slash) ~= 0
end

function SmartAIView:slashIsAvailable(player, slash)
    if slash == false then
        slash = self:getCard("Slash")
        if not slash then return false end
    else
        slash = slash or self:getCard("Slash") or self:classProbe("Slash")
    end
    player = player or self.player
    local available
    if type(slash.isAvailable) == "function" then available = slash:isAvailable(player)
    elseif type(player.isCardAvailable) == "function" then available = player:isCardAvailable(slash) end
    if type(available) == "boolean" then return available end
    if same_player(player, self.player) then ai_unsupported("owner Slash availability is unknown", "slashIsAvailable") end
    -- Current native Slash::IsAvailable asks whether any sibling passes the
    -- empty target filter. Foreign private rule/history queries are not exposed;
    -- use the public canSlash model and record this narrower target-filter prior.
    local possible = false
    for _, target in ipairs(strategy_call(self.room, "getAlivePlayers")) do
        if not same_player(target, player) and strategy_call(player, "canSlash", target, slash, true)
            and not self:strategyProhibited(player, target, slash) then possible = true; break end
    end
    return self:useKnowledgeEstimate({value = possible, status = "estimate",
        basis = "foreign_slash_availability_public_canSlash_targets_private_target_filter_rules_unobserved",
        viewer = self.player:objectName(), target = player:objectName()}, "slashIsAvailable")
end

function SmartAIView:hasTrickEffective(card, to, from)
    from = from or self.room:getCurrent() or self.player
    to = to or self.player
    local nature = card and (sgs.card_damage_nature or {})[strategy_call(card, "getClassName")]
    if self:strategyProhibited(from, to, card)
        or strategy_call(card, "isDamageCard") and strategy_call(self, "ajustDamage", from, to, 1, card, nature) == 0 then return end
    -- Preserve the donor's existing aoeTos alias and reached callback writes.
    local targets = self.aoeTos or AIList.new({})
    if not targets:contains(to) then targets:append(to) end
    local use = {card = card, from = from, to = targets}
    for _, name in ipairs(strategy_call(self, "getConnections", to)) do
        local hook = (sgs.ai_target_revises or {})[name]
        if type(hook) == "function" then
            local result = hook(to, card, self, use)
            if AIUnsupported.is(result) then error(result, 0) end
            if result then return end
        end
    end
    if strategy_call(from, "hasSkill", "SE_Jiepi") and strategy_call(from, "getHandcardNum") > strategy_call(to, "getHandcardNum") then return end
    return true
end

function SmartAIView:canHit(to, from, conservative)
    from = from or self.room:getCurrent()
    to = to or self.player
    if not from then ai_unsupported("Slash source is unknown", "canHit") end
    if strategy_call(to, "isCardLimited", self:classProbe("Jink"), strategy_known(sgs.Card_MethodUse, "MethodUse")) then return true end
    if strategy_call(self, "canLiegong", to, from) then return true end
    local function count(kind, owner)
        return self:useKnowledgeEstimate(self:estimateKnownCards(owner, kind, from, true, "he"), "canHit:" .. kind)
    end
    local function cards_in_he(player)
        return strategy_call(player, "getHandcardNum") + #strategy_call(player, "getEquips")
    end
    if not strategy_call(self, "isFriend", to, from) then
        if strategy_call(from, "hasWeapon", "Axe") and cards_in_he(from) > 2 then return true end
        if strategy_call(from, "hasWeapon", "blade") and count("Jink", to) <= count("Slash", from) then return true end
        if strategy_call(from, "hasSkill", "mengjin")
            and not (strategy_call(from, "hasSkill", "nosqianxi") and not strategy_call(from, "hasSkill", "jueqing")
                and strategy_call(from, "distanceTo", to) == 1)
            and strategy_call(self, "ajustDamage", from, to, 1, self:classProbe("Slash")) < 2
            and not strategy_call(self, "needLeiji", to, from) then
            if strategy_call(self, "doDisCard", to, "he", true) then
                strategy_call(to, "getEquips")
                if not (cards_in_he(to) == 1 and not to:getArmor()) then
                    if strategy_call(self, "canUseJieyuanDecrease", from, to) then return false end
                    if not strategy_call(self, "willSkipPlayPhase") then
                        if count("Peach", to) > 0 or count("Analeptic", to) > 0 then return true end
                        if not strategy_call(self, "isWeak", to) and to:getArmor()
                            and not strategy_call(self, "needToThrowArmor") then return true end
                        if not strategy_call(self, "isWeak", to) and to:getDefensiveHorse() then return true end
                    end
                end
            end
        end
    end
    local heart, red, black = false, false, false
    -- The donor intentionally scans the viewer's Jinks even when to differs.
    for _, jink in ipairs(strategy_call(self, "getCards", "Jink")) do
        if strategy_call(jink, "getSuit") == strategy_known(sgs.Card_Heart, "heart suit") then heart = true end
        if strategy_call(jink, "isRed") then red = true end
        if strategy_call(jink, "isBlack") then black = true end
    end
    if strategy_call(to, "hasFlag", "dahe") and not heart then return true end
    if strategy_mark(self, to, "@qianxi_red") > 0 and not black then return true end
    if strategy_mark(self, to, "@qianxi_black") > 0 and not red then return true end
    if not conservative and strategy_call(self, "ajustDamage", from, to, 1, self:classProbe("Slash")) > 1 then conservative = true end
    if not conservative and strategy_call(from, "hasSkill", "moukui") then conservative = true end
    if not conservative and strategy_call(to, "hasArmorEffect", "EightDiagram") and not strategy_known(IgnoreArmor(from, to), "IgnoreArmor") then return false end
    local double = strategy_call(from, "hasSkill", "wushuang")
        or strategy_call(from, "hasSkill", "roulin") and strategy_call(to, "isFemale")
        or strategy_call(from, "isFemale") and strategy_call(to, "hasSkill", "roulin")
    local jinks = count("Jink", to)
    if jinks == 0 then return true end
    if double and jinks < 2 then return true end
    return false
end

function SmartAIView:needLeiji(to, from)
    return self:findLeijiTarget(to, 50, from, -1)
end

function SmartAIView:needBear(player)
    player = player or self.player
    return strategy_call(player, "hasSkills", "renjie+baiyin")
        and not strategy_call(player, "hasSkill", "jilve", true)
        and strategy_call(player, "getMark", "&bear") < 4
end

function SmartAIView:isTiaoxinTarget(enemy)
    if not enemy then return nil end
    local function slashes()
        return self:useKnowledgeEstimate(self:estimateKnownCards(enemy, "Slash", self.room:getCurrent() or self.player, true, "he"), "isTiaoxinTarget.Slash")
    end
    if slashes() < 1 and strategy_call(self.player, "getHp") > 1
        and not strategy_call(self, "canHit", self.player, enemy)
        and not (strategy_call(enemy, "hasWeapon", "DoubleSword") and strategy_call(self.player, "getGender") ~= strategy_call(enemy, "getGender")) then return true end
    if slashes() < 1 or self:needLeiji(self.player, enemy)
        or strategy_call(self, "needToLoseHp", self.player, enemy, self:classProbe("Slash")) then return true end
    return strategy_call(self, "getOverflow") > 0 and strategy_call(self, "getCardsNum", "Jink") > 1
end

function IgnoreArmor(from, to)
    if not from or not to then return nil end
    local weapon = from:hasWeapon("QinggangSword")
    if weapon == nil then return nil end
    if weapon then return true end
    local armor = to:hasArmorEffect(nil)
    if armor == nil then return nil end
    if not armor then return true end
    local qinggang = from:hasSkill("keshengqinggang")
    if qinggang == nil then return nil end
    if qinggang then return true end
    local wuwei = from:hasSkill("SE_Wuwei")
    if wuwei == nil then return nil end
    if wuwei then
        local view = rawget(from, "_view")
        if type(view) ~= "table" or type(view.public_marks) ~= "table" then return nil end
        local mark = from:getMark("@Wuwei")
        if type(mark) ~= "number" then return nil end
        if mark > 2 then return true end
    end
    for _, entry in ipairs({{"luaqiangwang", false}, {"s3_xiaoyong", true}}) do
        local skill = from:hasSkill(entry[1])
        if skill == nil then return nil end
        if skill then
            local distance = from:distanceTo(to)
            if type(distance) ~= "number" then return nil end
            if (entry[2] and distance == 1) or (not entry[2] and distance > 1) then return true end
        end
    end
    return from:hasSkill("Qinggang")
end

function SmartAIView:ignoreArmor(from, to)
    return IgnoreArmor(from or self.player, to)
end

local function r32_optional_armor(player)
    local card=player:getArmor()
    if AIUnsupported.is(card) then error(card,0) end
    if card~=nil then return card end
    local row=rawget(player,"_view")
    if type(row)~="table" or not AIValue.isList(row.equips) then
        ai_unsupported("equipment zone is unavailable","needToThrowArmor")
    end
    return nil
end
local function r32_optional_selected_card(self,name)
    local card=self:getCard(name)
    if AIUnsupported.is(card) then error(card,0) end
    return card
end
function SmartAIView:needToThrowArmor(player,reason)
    player=player or self.player
    if not AIValue.isPlayer(player) or not strategy_call(player,"hasArmorEffect",nil) then return false end
    if r32_optional_armor(player) and not strategy_call(r32_optional_armor(player),"isKindOf","EightDiagram")
        and strategy_call(player,"hasSkills","bazhen|yizhong")
        or strategy_call(self,"evaluateArmor",nil,player)<=-2 then return true end
    if strategy_call(player,"isWounded") and strategy_call(player,"hasArmorEffect","SilverLion") then
        if player~=self.player and strategy_call(self,"isFriend",player) then
            return strategy_call(self,"isWeak",player) and not strategy_call(player,"hasSkills",strategy_known(sgs.use_lion_skill,"use_lion_skill"))
        end
        return true
    end
    if r32_optional_armor(player) and strategy_call(player,"hasSkill","sgkgodxiejia") then return true end
    if r32_optional_armor(player) and strategy_call(player,"hasSkill","s_nixing") then return true end
    return reason~="moukui"
        and strategy_call(self.player,"getPhase")==sgs.Player_Play
        and strategy_known(getCardsNum("Jink",player,self.player),"Jink estimate")<1
        and strategy_call(self,"isEnemy",player) and strategy_call(player,"hasArmorEffect","Vine")
        and not strategy_call(self,"slashProhibit",strategy_call(self,"cloneEvaluationCard","fire_slash"),player)
        and strategy_call(self,"slashIsAvailable",nil,false) and not strategy_call(self,"ignoreArmor",self.player,player)
        and (r32_optional_selected_card(self,"FireSlash") or (r32_optional_selected_card(self,"Slash") and (strategy_call(self.player,"hasSkills","lihuo|zonghuo") or strategy_call(self,"getCardsNum","fan")>0)))
end

function SmartAIView:needToThrowCard(to,flags,dis,give,draw)
	to = to or self.player
	flags = flags or "he"
	if not give and not draw then dis = true end
	if flags:find("h") and not strategy_call(to, "isKongcheng") then
		if not strategy_call(self, "hasLoseHandcardEffective",to) and not dis
		or (dis or give) and strategy_call(self, "needKongcheng",to,false,true)
		or draw and strategy_call(to, "hasSkill","lirang") and strategy_call(self, "findFriendsByType",sgs.Friend_Draw,to)
		or draw and strategy_call(to, "hasSkill","shangjian") and strategy_call(to, "getMark","shangjian-Clear")<strategy_call(to, "getHp")
		or strategy_call(self, "hasTuntianEffect",to)
		then return true end
	end
	if flags:find("e") and strategy_call(to, "hasEquip")
	and not(strategy_call(to, "getEquips"):length()==1 and strategy_call(self, "keepWoodenOx",to)) then
		if strategy_call(self, "loseEquipEffect",to) and (to:getOffensiveHorse() or to:getWeapon())
		or draw and strategy_call(to, "hasSkill","shangjian") and strategy_call(to, "getMark","shangjian_lose_card_num-Clear")<strategy_call(to, "getHp") and (to:getOffensiveHorse() or to:getWeapon())
		or not dis and strategy_call(to, "hasArmorEffect","SilverLion") and strategy_call(to, "isWounded") and not strategy_call(self, "needToLoseHp",to,self.player,false,true,true) and not strategy_call(to, "hasSkill","dingpan")
		or draw and strategy_call(to, "hasSkill","shanjia") and strategy_call(to, "getMark","&shanjia")<3
		or strategy_call(self, "needToThrowArmor",to)
		or strategy_call(self, "hasTuntianEffect",to)
		then return true end
	end
	if flags:find("j") then
		if (strategy_call(to, "containsTrick","indulgence") or strategy_call(to, "containsTrick","supply_shortage")) and not strategy_call(to, "containsTrick","YanxiaoCard") then return true end
		if (strategy_call(to, "containsTrick","qhstandard_indulgence")) and not strategy_call(to, "containsTrick","YanxiaoCard") then return true end
	end
	return false
end

function SmartAIView:damageStruct(struct)
    if type(struct) ~= "table" or not AIValue.isPlayer(struct.to) then
        -- Source writes a console traceback and returns nil. Retain a local
        -- diagnostic only; this value VM cannot reproduce Room console I/O.
        self._common_diagnostics = self._common_diagnostics or {}
        self._common_diagnostics[#self._common_diagnostics + 1] = "damageStruct: invalid source damage struct or target"
        return
    end
    local damage = self:ajustDamage(struct.from, struct.to, struct.damage, struct.card, struct.nature)
    if AIUnsupported.is(damage) then error(damage, 0) end
    if damage > 0 then
        return not strategy_known(self.world and self.world.ai_humanized, "ai_humanized") or math.random() < 0.95
    end
end

function SmartAIView:toTurnOver(to, n, reason)
    if not to then ai_unsupported("turnover target is absent", "toTurnOver") end
    n = n or 0
    if strategy_call(self, "isEnemy", to) then
        local manchong
        for _, player in ipairs(strategy_call(self.room, "getAlivePlayers")) do
            if strategy_call(player, "hasSkill", "junxing") then manchong = player break end
        end
        if manchong and strategy_call(self, "isFriend", to, manchong)
            and self:playerGetRound(manchong) < self:playerGetRound(to)
            and strategy_call(manchong, "faceUp") and not strategy_call(self, "willSkipPlayPhase", manchong)
            and not (strategy_call(manchong, "isKongcheng") and strategy_call(self, "willSkipDrawPhase", manchong)) then return false end
    end
    if not strategy_call(to, "faceUp") and not strategy_call(to, "hasFlag", "ShenfenUsing")
        and not strategy_call(to, "hasFlag", "guixinUsing") and not strategy_call(to, "hasFlag", "newguixinUsing") then return false end
    reason = reason or ""
    if reason:match("fangzhu") and strategy_call(to, "getHp") <= 1
        and self:playerGetRound(to) > self:playerGetRound(self.player) then
        local context = strategy_call(self, "getDecisionContext")
        local effect = context.effect
        if effect == nil and context.effect_present ~= false then
            if type(self.getEventMemory) ~= "function" then ai_unsupported("fangzhu cardEffect presence is unknown", "toTurnOver") end
            local known
            effect, known = self:getEventMemory("card_effect")
            if known ~= true then ai_unsupported("fangzhu cardEffect memory is unknown", "toTurnOver") end
        end
        local effect_card = effect and effect.card
        if effect_card and not AIValue.isCard(effect_card) and type(effect_card.isKindOf) ~= "function" then effect_card = CardView.new(effect_card) end
        if effect_card and strategy_call(effect_card, "isKindOf", "AOE") then
            local use = context.last_target_specified_use
            if use == nil and type(self.getEventMemory) == "function" then
                local known
                use, known = self:getEventMemory("target_use")
                if known ~= true then ai_unsupported("fangzhu TargetSpecified memory is unknown", "toTurnOver") end
            end
            local targets = type(use) == "table" and (use.to or use.targets)
            if not AIValue.isList(targets) then ai_unsupported("fangzhu TargetSpecified use is unknown", "toTurnOver") end
            local targeted = false
            for _, target in ipairs(targets) do
                local name = type(target) == "string" and target or strategy_call(target, "objectName")
                if name == to:objectName() then targeted = true break end
            end
            if targeted and strategy_call(self, "aoeIsEffective", effect_card, to) and strategy_call(to, "isKongcheng") then return false end
        end
    end
    local phase = strategy_call(to, "getPhase")
    local play = strategy_known(sgs.Player_Play, "Play phase")
    if phase <= play and (not strategy_call(to, "hasUsed", "ShenfenCard")
        and strategy_mark(self, to, "&wrath") >= 6 or strategy_call(to, "hasFlag", "ShenfenUsing"))
        or strategy_call(to, "hasUsed", "ShenfenCard") and strategy_call(to, "faceUp") then return false end
    if n > 1 then
        local inactive = strategy_known(sgs.Player_NotActive, "NotActive phase")
        if phase ~= inactive and (strategy_call(to, "hasSkills", strategy_known(sgs.Active_cardneed_skill, "active cardneed skills"))
            or strategy_call(to, "hasWeapon", "Crossbow"))
            or phase == inactive and strategy_call(to, "hasSkills", strategy_known(sgs.notActive_cardneed_skill, "inactive cardneed skills")) then return false end
    end
    if strategy_call(to, "hasSkills", "jushou|neojushou|nosjushou|kuiwei") and phase <= strategy_known(sgs.Player_Finish, "Finish phase")
        or strategy_call(to, "hasSkill", "lihun") and not strategy_call(to, "hasUsed", "LihunCard")
            and strategy_call(to, "faceUp") and phase <= play then return false end
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

local function common_phase_skipped(self, player, phase)
    local value = player:isSkipped(phase)
    if value ~= nil then return value end
    return self:useKnowledgeEstimate({value = false, status = "estimate", viewer = self.player:objectName(),
        target = player:objectName(), phase = phase, basis = "unobserved_private_skip_state_assumed_absent_public_skip_causes_evaluated_below"}, "willSkipPlayPhase.skipped")
end
function SmartAIView:willSkipPlayPhase(player,NotContains_Null)
	player = player or self.player
	--add
	if strategy_call(player, "hasSkill","zhiyujz_jx") or strategy_call(player, "hasSkill","zhiyujz_jz") then
		return true
	end
	if common_phase_skipped(self,player,sgs.Player_Play) then return true end
	local fhh = self.room:findPlayerBySkillName("noszhuikong")
	if fhh and fhh~=player and strategy_call(fhh, "getHandcardNum")>1 and strategy_call(fhh, "isWounded")
	and strategy_call(self, "isEnemy",player,fhh) and not strategy_call(player, "isKongcheng") and not strategy_call(self, "isWeak",fhh) then
		local max_card = self:getMaxCard(fhh)
		local player_max_card = self:getMaxCard(player)
		if max_card and player_max_card and strategy_call(max_card, "getNumber")>strategy_call(player_max_card, "getNumber")
		or max_card and strategy_call(max_card, "getNumber")>=12 then return true end
	end
	local friend_snatch_dismantlement,friend_null = 0,0
	if strategy_call(self.player, "getPhase")<=sgs.Player_Play and self.player~=player and strategy_call(self, "isFriend",player) then
		for _,h in ipairs(strategy_call(self.player, "getCards","he"))do
			if isCard("Snatch",h,self.player) and strategy_call(self.player, "distanceTo",player)==1
			or isCard("Dismantlement",h,self.player) then
				local trick = strategy_call(self, "getDismantlementProbe", h)
				if strategy_call(self, "hasTrickEffective",trick,player,self.player)
				then friend_snatch_dismantlement = friend_snatch_dismantlement+1 end
			end
		end
	end
	if NotContains_Null~=true then
		for _,p in ipairs(strategy_call(self.room, "getAlivePlayers"))do
			if strategy_call(self, "isFriend",p,player) then friend_null = friend_null+self:useKnowledgeEstimate(strategy_call(self, "estimateKnownCards",p, "Nullification", self.player, true, "he"), "willSkipPlayPhase.Nullification")
			elseif strategy_call(self, "isEnemy",p,player) then friend_null = friend_null-self:useKnowledgeEstimate(strategy_call(self, "estimateKnownCards",p, "Nullification", self.player, true, "he"), "willSkipPlayPhase.Nullification") end
		end
	end
	if strategy_call(player, "containsTrick","indulgence") then
		if strategy_call(player, "containsTrick","YanxiaoCard")
		or strategy_call(player, "hasSkills","keji|conghui")
		or strategy_call(player, "getHandcardNum")>0 and strategy_call(player, "hasSkill","qiaobian") then return false end
		if friend_null+friend_snatch_dismantlement>1 then return false end
		local i,to = self:getFinalRetrial(player)
        i = strategy_known(i, "final retrial side")
		if i==1 and strategy_call(self, "getSuitNum","heart",true,to)>0
		then return false end
		for _,c in ipairs(strategy_call(player, "getJudgingArea"))do
			if string.find(strategy_call(c, "objectName"),"kehexumou") and strategy_call(player, "hasSkill","dl_yanxiao") then
				return false
			end
		end
		return true
	end
	if strategy_call(player, "containsTrick","qhstandard_indulgence") then
		if strategy_call(player, "containsTrick","YanxiaoCard")
		or strategy_call(player, "hasSkills","keji|conghui")
		or not strategy_call(player, "isKongcheng") and strategy_call(player, "hasSkill","qiaobian") then return false end
		if friend_null+friend_snatch_dismantlement>1 then return false end
		local i,to = self:getFinalRetrial(player)
        i = strategy_known(i, "final retrial side")
		if i==1 and strategy_call(self, "getSuitNum","heart",true,to)>0
		then return false end
		for _,c in ipairs(strategy_call(player, "getJudgingArea"))do
			if string.find(strategy_call(c, "objectName"),"kehexumou") and strategy_call(player, "hasSkill","dl_yanxiao") then
				return false
			end
		end
		return true
	end
	--add
	local caifuren = self.room:findPlayerBySkillName("meizlduyan")
	if caifuren and strategy_call(caifuren, "objectName") ~= strategy_call(player, "objectName") and strategy_call(self, "isEnemy",player, caifuren)
		and strategy_call(caifuren, "canPindian",player) and not strategy_call(self, "isWeak",caifuren)
	then
		local max_card = self:getMaxCard(caifuren)
		local player_max_card = self:getMaxCard(player)
		if max_card and player_max_card and strategy_call(max_card, "getNumber") > strategy_call(player_max_card, "getNumber")
			or max_card and strategy_call(max_card, "getNumber") >= 12 then
			return true
		end
	end
	if strategy_call(player, "getMark","@meizlsepoxiao") > 0 then
		return true
	end
	if strategy_call(player, "getMark","&kejiexianmabicp") > 0 then
		return true
	end
	if strategy_call(player, "getMark","@SE_Mafuyu") > 0 then
		return true
	end
	if strategy_call(player, "hasSkill","SE_Qizhuang") then
		return true
	end
	if strategy_call(player, "hasSkill","chenmohy") then
		return true
	end
	--add
	if strategy_call(player, "getMark","&kejiexianmabicp") > 0 then
		return true
	end
	if strategy_call(player, "getMark","&basuran+:+play_lun") > 0 then
		return true
	end
	for _,p in ipairs(strategy_call(self.room, "getAllPlayers"))do
		if strategy_call(p, "getMark","fzndz_3") > 0	then return true end
	end
	for _,mark in ipairs(strategy_call(player, "getMarkNames")) do
		if string.find(mark, "sfofl_yufeng") and strategy_call(player, "getMark",mark) > 0 and mark:sub(1,#"sfofl_yufeng")=="sfofl_yufeng"  then
			local pieces = {}; for part in mark:gmatch("[^+]+") do pieces[#pieces+1] = part end
            if not pieces[3] then ai_unsupported("malformed public yufeng mark", mark) end
            local suit = pieces[3]:match("^[^_]+")
			if suit == "spade" then
				return true
			end
		end
	end
	return false
end

-- R32 callback adaptation: donor ordinary nil/tuple returns remain meaningful;
-- isolated control signals must never become truthy strategy answers.
local function r32_callback_result(value)
    if AIUnsupported and AIUnsupported.is(value) then error(value, 0) end
    return value
end
local function r32_optional_equipment(player, method)
    if type(player[method]) ~= "function" then ai_unsupported("equipment getter is unavailable", method) end
    return r32_callback_result(player[method](player))
end
local function r32_qiaobian(self, ...)
    local to, card = self:card_for_qiaobian(...)
    r32_callback_result(to)
    r32_callback_result(card)
    return to, card
end

function SmartAIView:findPlayerToUseSlash(distance_limit, players, reason, slash, extra_targets, fixed_target)
    -- distance_limit: 距離限制 (若為 false，則模擬無距離限制)
    -- players: 可選的玩家列表 (若為 nil 則檢查所有友方)
    -- reason: 原因字符串 (附加到技能名上)
    -- slash: 預想使用的殺牌
    -- extra_targets: 允許的額外目標數
    -- fixed_target: 指定的攻擊目標

    local friends = players or self.friends_noself
    local candidates = {}

    -- 若沒有傳入 slash，動態生成一張虛擬殺用於評估
    local dummy_slash = strategy_call(self, "getReasonSlash",reason, slash)
    extra_targets = extra_targets or 0
	fixed_target = fixed_target or nil
    if reason then
        dummy_slash:setSkillName(reason)
    end

    -- 緩存殺的屬性，避免在迴圈內重複獲取
    local nature = sgs.card_damage_nature[strategy_call(dummy_slash, "getClassName")] or sgs.DamageStruct_Normal

    -- 評估每個友方角色使用殺的價值
    for _, friend in ipairs(friends) do
		local total_value = 0
		local all_benefits = {}

		-- 1. 遍歷所有殺增益評估函數 O(1) 查表
		if sgs.ai_slash_benefit then
			for benefit_type, benefit_func in pairs(sgs.ai_slash_benefit) do
				if type(benefit_func) == "function" then
					local result = r32_callback_result(benefit_func(self, friend, dummy_slash))
					if result and result.value then
						total_value = total_value + result.value
						-- 合併增益信息 (可供後續擴展或 Debug 使用)
						for k, v in pairs(result) do
							if k ~= "value" then
								if type(v) == "table" then
									if not all_benefits[k] then all_benefits[k] = {} end
									for _, item in ipairs(v) do
										table.insert(all_benefits[k], item)
									end
								else
									all_benefits[k] = v
								end
							end
						end
					end
				end
			end
		end

		-- 【完美結合點】：輕量級構建 dummy_use，精準觸發 ai_use_revises
		local dummy_use = { isDummy = true, from = friend, to = AIList.new({}), card = dummy_slash }

		-- 記下原始狀態，防止 Flag 污染下一個隊友
		local had_qinggang = strategy_call(dummy_slash, "hasFlag","Qinggang")

		-- 調用我們優化後的 O(1) aiConnect 緩存
		local connects = strategy_call(self, "getConnections",friend)
		for _, ac in ipairs(connects) do
			local invoke = sgs.ai_use_revises[ac]
			if type(invoke) == "function" then
				r32_callback_result(invoke(self, dummy_slash, dummy_use))
			end
		end
		if dummy_use.card then
			local ignore_armor = strategy_call(dummy_slash, "hasFlag","Qinggang") or strategy_call(dummy_slash, "hasFlag","SlashIgnoreArmor")

			-- 3. 靜態評估目標威脅與傷害收益 (取代高成本的 aiUseCard 模擬)
			local valid_targets_count = 0

			if fixed_target then
				-- 針對指定目標進行評估
				if (not distance_limit or strategy_call(friend, "inMyAttackRange",fixed_target))
					and not strategy_call(self, "slashProhibit",dummy_slash, fixed_target, friend)
					and strategy_call(self, "slashIsEffective",dummy_slash, fixed_target, friend, ignore_armor) then

					local expected_damage = strategy_call(self, "ajustDamage",friend, fixed_target, 1, dummy_slash, nature)
					if expected_damage > 0 then
						total_value = total_value + (expected_damage * 15)
						valid_targets_count = 1

						-- 額外計算無視防具的收益
						if strategy_call(dummy_slash, "hasFlag","SlashIgnoreArmor") or ignore_armor then
							total_value = total_value + 12
						end
					end
				end
			else
				-- 尋找隊友攻擊範圍內的敵人
				for _, enemy in ipairs(self.enemies) do
					if (not distance_limit or strategy_call(friend, "inMyAttackRange",enemy))
						and not strategy_call(self, "slashProhibit",dummy_slash, enemy, friend)
						and strategy_call(self, "slashIsEffective",dummy_slash, enemy, friend, ignore_armor) then

						local expected_damage = strategy_call(self, "ajustDamage",friend, enemy, 1, dummy_slash, nature)
						if expected_damage > 0 then
							valid_targets_count = valid_targets_count + 1
							total_value = total_value + (expected_damage * 15)

							if strategy_call(dummy_slash, "hasFlag","SlashIgnoreArmor") or ignore_armor then
								total_value = total_value + 12
							end

							-- 若已滿足殺的額外目標上限，停止尋找更多目標
							if valid_targets_count >= (1 + extra_targets) then
								break
							end
						end
					end
				end
			end
			-- 4. 比較攻擊範圍內的敵人數量 (提供基礎威懾價值)
			local enemies_in_range = 0
			for _, enemy in ipairs(self.enemies) do
				if (not distance_limit or strategy_call(friend, "inMyAttackRange",enemy)) then
					enemies_in_range = enemies_in_range + 1
				end
			end
			total_value = total_value + enemies_in_range * 3

			-- 儲存候選人資料 (必須要有真實的輸出收益或範圍內有敵人才算有效)
			if total_value > 0 and (valid_targets_count > 0 or enemies_in_range > 0) then
				table.insert(candidates, {
					player = friend,
					value = total_value,
					benefits = all_benefits,
					enemies_in_range = enemies_in_range
				})
			end
		end
		if not had_qinggang and strategy_call(dummy_slash, "hasFlag","Qinggang") then
			dummy_slash:setFlags("-Qinggang")
		end
    end

    -- 按價值降序排序
    table.sort(candidates, function(a, b)
        return a.value > b.value
    end)

    -- 返回最佳候選人
    if #candidates > 0 then
        return candidates[1].player
    end

    return nil
end

-- The isolated registry is the authority for discard callbacks.
function SmartAIView:getDiscardCallback(reason)
    local value = sgs.ai_skill_discard and sgs.ai_skill_discard[reason]
    if value == nil then return nil end
    local row = {type = type(value), value = value}
    if row.type == 'function' then
        local callback = value
        if ai_audited_aliases then callback = ai_audited_aliases.resolve(self, callback) end
        if type(callback) ~= 'function' then
            ai_unsupported('legacy discard callback has no isolated implementation', reason)
        end
        return callback
    elseif row.type == 'number' then
        if type(row.value) ~= 'number' or row.value ~= row.value or math.abs(row.value) == math.huge then
            ai_unsupported('invalid discard numeric literal', reason)
        end
        return row.value
    elseif row.type == 'table' then
        if not AIValue.isList(row.value) then ai_unsupported('invalid discard array literal', reason) end
        local result = {}
        for _, value in ipairs(row.value) do
            if type(value) ~= 'number' or value ~= value or math.abs(value) == math.huge then
                ai_unsupported('invalid discard array entry', reason)
            end
            result[#result + 1] = value
        end
        return result
    elseif row.type == 'boolean' then return false
    elseif row.type == 'string' then return '' end
    ai_unsupported('unsupported discard registry value', reason)
end

-- A discard question's card_ids are the authority's cards matching its pattern.
-- A response question's candidates carry that match for every own hand/equip card.
function SmartAIView:matchesDiscardPattern(pattern, card)
    if pattern == '.' then return true end
    local request = self.request
    if type(request) == 'table' and request.kind == 'respond_card'
        and (request.pattern or ''):gsub('!$', '') == pattern then
        local id = checked_strategy_call(card, 'getId')
        for _, candidate in ipairs(request.card_candidates or {}) do
            if candidate.card_id == id then return candidate.available == true end
        end
        ai_unsupported('response pattern match is unknown for this card', 'discard.pattern')
    end
    local ids = type(request) == 'table' and request.kind == 'discard' and request.pattern == pattern
        and type(request.options) == 'table' and request.options.card_ids
    if not AIValue.isList(ids) then ai_unsupported('discard pattern is not the question pattern', 'discard.pattern') end
    local id = checked_strategy_call(card, 'getId')
    for _, candidate in ipairs(ids) do if candidate == id then return true end end
    return false
end

function SmartAIView:askForDiscard(reason, max_num, min_num, optional, include_equip, pattern)
    local exchange = checked_strategy_call(self.player, 'hasFlag', 'Global_AIDiscardExchanging')
    if not (optional or exchange) then
        local result = self:recordDiscardDemand(reason, min_num)
        if AIUnsupported and AIUnsupported.is(result) then error(result, 0) end
    end
    if type(pattern) == 'string' then
        local result = self:assignKeep()
        if AIUnsupported and AIUnsupported.is(result) then error(result, 0) end
    else pattern = '.' end
    local callback = self:getDiscardCallback(reason)
    if AIUnsupported and AIUnsupported.is(callback) then error(callback, 0) end
    if type(callback) == 'function' then
        callback = callback(self, max_num, min_num, optional, include_equip, pattern)
        if AIUnsupported and AIUnsupported.is(callback) then error(callback, 0) end
    end
    local to_discard = {}
    if type(callback) == 'number' then
        if exchange or checked_strategy_call(self.player, 'canDiscard', self.player, callback) then
            to_discard = {callback}
        end
    elseif type(callback) == 'table' then
        for _, id in ipairs(callback) do
            if type(id) ~= 'number' then id = checked_strategy_call(id, 'getId') end
            if exchange or checked_strategy_call(self.player, 'canDiscard', self.player, id) then
                to_discard[#to_discard + 1] = id
            end
        end
    elseif optional and include_equip then
        for _, card in ipairs(checked_strategy_call(self, 'poisonCards', 'e')) do
            if (exchange or checked_strategy_call(self.player, 'canDiscard', self.player, checked_strategy_call(card, 'getId')))
                and checked_strategy_call(self, 'matchesDiscardPattern', pattern, card) then
                to_discard[#to_discard + 1] = checked_strategy_call(card, 'getId')
            end
            if #to_discard >= max_num then break end
        end
    end
    if #to_discard < min_num then
        if optional then return {} end
        local cards = checked_strategy_call(self.player, 'getCards', include_equip and 'he' or 'h')
        if exchange then
            for _, card in ipairs(checked_strategy_call(self, 'poisonCards', cards)) do
                if #to_discard < min_num then
                    local id = checked_strategy_call(card, 'getId')
                    if not table.contains(to_discard, id) then to_discard[#to_discard + 1] = id end
                end
            end
        end
        local deferred = {}
        local sorted = checked_strategy_call(self, 'sortByKeepValue', cards, nil, not exchange and 'j')
        for _, card in ipairs(sorted) do
            if #to_discard < min_num and not table.contains(to_discard, checked_strategy_call(card, 'getId')) then
                if checked_strategy_call(self, 'matchesDiscardPattern', pattern, card) then
                    if checked_strategy_call(self.player, 'hasEquip', card) and checked_strategy_call(self, 'loseEquipEffect')
                        or checked_strategy_call(self, 'getUseValue', card) < 6 then
                        to_discard[#to_discard + 1] = checked_strategy_call(card, 'getId')
                    else deferred[#deferred + 1] = checked_strategy_call(card, 'getId') end
                end
            end
        end
        for _, id in ipairs(deferred) do
            if #to_discard < min_num and not table.contains(to_discard, id) then to_discard[#to_discard + 1] = id end
        end
    end
    return to_discard
end

-- Fixed ordinary gamerule callback; the outer helper handles source limits,
-- optionality and callback timing. Original mode captures/wraps this provider.
sgs.ai_skill_discard = sgs.ai_skill_discard or {}
sgs.ai_skill_discard.gamerule = function(self, maximum, minimum)
    local discard = {}
    for _, card in ipairs(checked_strategy_call(self, 'sortByKeepValue', checked_strategy_call(self.player, 'getHandcards'))) do
        if not checked_strategy_call(self.player, 'isCardLimited', card, sgs.Card_MethodDiscard, true) then
            discard[#discard + 1] = checked_strategy_call(card, 'getEffectiveId')
            if #discard >= minimum then break end
        end
    end
    return discard
end

-- 產出牌要比對類別名、kind 或牌名。分類沒投影是未知，不是「不是這類」。
local function conversion_matches(conversion, produced)
    if produced == nil then return true end
    local class_name = conversion:getClassName()
    local kind = conversion:isKindOf(produced)
    local name = conversion:objectName()
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
                local name = conversion:objectName()
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
    local function call(object, method, ...) return strategy_call(object, method, ...) end
    local function skill(name) return call(to, "hasSkill", name) end
    local hp, hand = call(to, "getHp"), call(to, "getHandcardNum")
    if call(self.room, "getTurnCount") < 1 then
        return hp * 2 + hand + call(to, "getHandPileCount")
    end
    local knownJink = strategy_known(getKnownCard(to, self.player, "Jink", true, "he"), "known Jink")
    local defense = knownJink * 1.2
    local ignore = strategy_known(self:ignoreArmor(self.player, to), "IgnoreArmor")
    local diagram = not ignore and call(to, "hasArmorEffect", "EightDiagram")
    if diagram then
        defense = defense + 1.3
        for _, row in ipairs({{"tiandu", .6}, {"gushou", .4}, {"leiji", .4}, {"nosleiji", .4}, {"noszhenlie", .2}, {"hongyan", .2}}) do
            if skill(row[1]) then defense = defense + row[2] end
        end
    else
        if skill("jijiu") then defense = defense - 3 end
        if skill("dimeng") then defense = defense - 2.5 end
        if knownJink < 1 and skill("guzheng") then defense = defense - 2.5 end
        if skill("qiaobian") then defense = defense - 2.4 end
        if skill("jieyin") then defense = defense - 2.3 end
        if call(to, "hasSkills", "noslijian|lijian") then defense = defense - 2.2 end
        if skill("nosmiji") and call(to, "isWounded") then defense = defense - 1.5 end
        if knownJink < 1 and skill("xiliang") then defense = defense - 2 end
        if skill("shouye") then defense = defense - 2 end
    end
    if knownJink > 0 then
        if skill("mingzhe") then defense = defense + .2 end
        if skill("gushou") then defense = defense + .2 end
        if call(self, "hasTuntianEffect", to, true) then defense = defense + 1.5 end
    end
    if call(to, "getPhase") == sgs.Player_NotActive and skill("aocai") then defense = defense + .5 end
    if skill("wanrong") and not call(self, "hasManjuanEffect", to) then defense = defense + .5 end
    local hujiaJink = 0
    if call(to, "hasLordSkill", "hujia") then
        -- getLieges excludes its supplied lord, which need not be room:getLord().
        for _, liege in ipairs(call(self.room, "getAlivePlayers")) do
            if not same_player(liege, to) and call(liege, "getKingdom") == "wei"
                and call(self, "compareRoleEvaluation", liege, "rebel", "loyalist") == call(self, "compareRoleEvaluation", to, "rebel", "loyalist") then
                hujiaJink = hujiaJink + strategy_known(getKnownCard(liege, self.player, "Jink", true, "he"), "hujia Jink")
                if call(liege, "hasArmorEffect", "EightDiagram") then hujiaJink = hujiaJink + .8 end
            end
        end
        defense = defense + hujiaJink
    end
    if skill("Lichang") then
        for _, player in ipairs(call(self.room, "getAlivePlayers")) do
            if call(player, "getHp") > call(self.player, "getHp") then defense = defense + 5; break end
        end
    end
    if skill("fatejiejie") then defense = defense + .2 end
    if strategy_mark(self, to, "@tied") > 0 and not call(self.player, "hasSkill", "jueqing") then defense = defense + 1 end
    if skill("qhstandardkongcheng") and hand < 2 then defense = defense + 5 end
    if skill("sr_youdi") and not call(to, "faceUp") then defense = defense + 5 end
    if call(self, "canLiegong", to) then defense = 0 end
    for _, name in ipairs(self:getConnections(to)) do
        local hook = sgs.ai_defense_slash[name]
        if type(hook) == "function" then
            local value = hook(self, to, self.player)
            if type(value) == "number" then defense = defense + value end
        end
    end
    local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
    local double = call(self.player, "hasSkills", "wushuang|drwushuang")
        or call(self.player, "hasSkill", "roulin") and call(to, "isFemale")
        or skill("roulin") and call(self.player, "isFemale")
        or jiangqin and call(jiangqin, "isAdjacentTo", to) and call(self.player, "isAdjacentTo", to)
            and strategy_call(self, "isFriend", jiangqin)
    if double and knownJink < 2 and (not call(to, "hasLordSkill", "hujia") or hujiaJink < 2) then defense = 0 end
    if call(self.player, "hasSkill", "dahe") and call(to, "hasFlag", "dahe") and knownJink < 1 then
        -- Legacy global getKnownNum uses the room current player as observer.
        local current = self.room:getCurrent()
        local substituted_observer = current and not same_player(current, self.player)
        local known = #call(to, "getKnownCards")
        local view = rawget(to, "_view")
        local piles = strategy_known(type(view) == "table" and view.piles or nil, "known hand piles")
        for _, pile in ipairs(piles) do
            if strategy_known(pile.hand_pile, "hand pile status") and strategy_known(pile.open, "hand pile visibility") then
                known = known + #strategy_known(pile.card_ids, "visible hand pile ids")
            end
        end
        if substituted_observer then
            known = self:useKnowledgeEstimate({value = known, status = "estimate", basis = "observer_substitution_visible_hand_count",
                viewer = self.player:objectName(), observer = current:objectName()}, "getDefenseSlash:dahe")
        end
        if known == hand and not (call(to, "hasLordSkill", "hujia") and hujiaJink >= 1) then defense = 0 end
    end
    if call(to, "isCardLimited", self:classProbe("Jink"), sgs.Card_MethodUse) then defense = 0 end
    if call(to, "hasFlag", "QianxiTarget") then
        if strategy_mark(self, to, "@qianxi_red") > 0 then
            if skill("qingguo") or skill("longhun") and call(to, "isWounded") then defense = defense - 1 else defense = 0 end
        elseif strategy_mark(self, to, "@qianxi_black") > 0 and skill("qingguo") then defense = defense - 1 end
    end
    defense = defense + math.min(hp * .45, 10)
    if not call(self.player, "hasSkill", "jueqing") then
        local names = strategy_known(sgs.masochism_skill, "masochism_skill")
        for name in names:gmatch("[^|]+") do
            if skill(name) and call(self, "isGoodHp", to) then defense = defense + 1 end
        end
        if skill("jieming") then defense = defense + 4 end
        if skill("yiji") then defense = defense + 4 end
        if skill("guixin") then defense = defense + 4 end
        if skill("yuce") then defense = defense + 2 end
    end
    if not call(self, "isGoodTarget", to) then defense = defense + 10 end
    if hp > 2 and call(to, "hasSkills", "nosrende|rende") then defense = defense + 1 end
    if hp > 1 and skill("kuanggu") then defense = defense + .2 end
    if hp > 1 and skill("zaiqi") then defense = defense + .35 end
    if skill("tianming") then defense = defense + .1 end
    if hp > call(self, "getBestHp", to) then defense = defense + .8 end
    if hp <= 2 then defense = defense - .4 end
    local count = call(self.room, "alivePlayerCount")
    if count > 3 and (call(to, "getSeat") - call(self.player, "getSeat")) % count >= count - 2 and hand <= 2 and hp <= 2 then defense = defense - .4 end
    if skill("tianxiang") then defense = defense + hand * .5 end
    if hand + hujiaJink < 1 and not skill("kongcheng") then
        if hp <= 1 then defense = defense - 2.5 end
        if hp == 2 then defense = defense - 1.5 end
        if not diagram then defense = defense - 2 end
        if call(self.player, "hasWeapon", "GudingBlade") and hand < 1
            and not (call(to, "hasArmorEffect", "SilverLion") and not ignore) then defense = defense - 2 end
    end
    for _, card in ipairs(call(self.player, "getHandcards")) do
        if (call(card, "isKindOf", "FireSlash") or call(card, "objectName") == "slash" and call(self.player, "hasWeapon", "Fan"))
            and not ignore and call(to, "hasArmorEffect", "Vine") then defense = defense - .6; break end
    end
    if call(to, "isLord") then
        defense = defense - .4
        if call(self, "isLordInDanger") then defense = defense - .7 end
    end
    if not call(to, "faceUp") then defense = defense - .35 end
    if call(to, "containsTrick", "indulgence") and not call(to, "containsTrick", "YanxiaoCard") then defense = defense - .15 end
    if call(to, "containsTrick", "supply_shortage") and not call(to, "containsTrick", "YanxiaoCard") then defense = defense - .15 end
    if call(to, "isFemale") and call(self.player, "hasSkill", "roulin") or call(self.player, "isFemale") and skill("roulin") then defense = defense - 2.4 end
    return defense
end

-- 依 objective 由高到低，同分再比 getDefenseSlash。任一分數未知就不改順序，回 nil。
function SmartAIView:sortEnemies(players)
    local objective, defense = {}, {}
    for _, player in ipairs(players) do
        objective[player:objectName()] = strategy_call(self, "objectiveLevel", player)
        defense[player:objectName()] = strategy_call(self, "getDefenseSlash", player)
    end
    table.sort(players, function(a, b)
        if objective[a:objectName()] ~= objective[b:objectName()] then
            return objective[a:objectName()] > objective[b:objectName()]
        end
        return defense[a:objectName()] < defense[b:objectName()]
    end)
    -- Source sorts the same Lua array and returns nil.
end

-- SmartAI:updatePlayers. The request's mode_policy is this decision's relation
-- evaluation (the host does not re-evaluate mid-decision), so the ordered lists are
-- rebuilt from it the same way SmartAIView.new builds them.
function SmartAIView:updatePlayers(update)
    local policy = self.world and self.world.mode_policy
    if type(policy) ~= "table" or policy.managed ~= true or policy.error ~= nil then
        ai_unsupported("updatePlayers mode domain is not implemented", "updatePlayers")
    end
    if policy.standard_identity == true then
        local friends, noself, enemies = AIList.asLuaTable(AIList.new({})),
            AIList.asLuaTable(AIList.new({})), AIList.asLuaTable(AIList.new({}))
        local row = (policy.relations or {})[self.player:objectName()] or {}
        for _, player in ipairs(self.room:getAlivePlayers()) do
            local relation = row[player:objectName()]
            if relation == "friend" then
                friends:append(player)
                if player:objectName() ~= self.player:objectName() then noself:append(player) end
            elseif relation == "enemy" then enemies:append(player) end
        end
        self.friends, self.friends_noself, self.enemies = friends, noself, enemies
    else
        self.friends = AIList.asLuaTable(self:getFriends())
        self.friends_noself = AIList.asLuaTable(self:getFriends(nil, true))
        self.enemies = AIList.asLuaTable(self:getEnemies())
    end
    return true -- isolated caller ABI; source callers ignore its nil return
end

-- 單選：實體 ID / 權威 card_spec。islist：原版 toString 純字串，枚舉不授票。
do
local nested_cardask_identity=setmetatable({}, {__mode="k"})
function SmartAIView.withNestedCardaskIdentity(self,pattern,prompt,callback)
    local request=self.request
    local context=self:getDecisionContext()
    local inquiry=type(context)=="table" and context.lianli_slash_invoke
    if type(callback)~="function" or type(request)~="table" or request.kind~="skill_invoke"
        or type(request.options)~="table" or request.options.reason~="lianli-slash"
        or type(inquiry)~="table" or inquiry.known~=true or not AIValue.isList(inquiry.asked)
        or pattern~="slash" or prompt~=inquiry.asked[2] then
        ai_unsupported("readonly card identity is outside the Lianli nested inquiry","nested_askForCard.identity")
    end
    local previous=nested_cardask_identity[self]
    nested_cardask_identity[self]={request=request,player=self.player,viewer=request.viewer,
        decision_id=request.decision_id,state_revision=request.state_revision}
    local function pack(...)return{n=select('#',...),...}end
    local result=pack(pcall(callback))
    nested_cardask_identity[self]=previous
    if not result[1]then error(result[2],0)end
    return (table.unpack or unpack)(result,2,result.n)
end
function SmartAIView:getCardId(class_name, islist)
    local inquiry=nested_cardask_identity[self]
    if inquiry then
        local request=self.request
        if request~=inquiry.request or self.player~=inquiry.player or type(request)~="table"
            or request.viewer~=inquiry.viewer or request.decision_id~=inquiry.decision_id
            or request.state_revision~=inquiry.state_revision then
            ai_unsupported("nested readonly identity request changed","nested_askForCard.identity")
        end
    end
    local cards = self:getCard(class_name, islist)
    if AIUnsupported and AIUnsupported.is(cards) then error(cards, 0) end
    if inquiry then
        local request=self.request
        if request~=inquiry.request or self.player~=inquiry.player or type(request)~="table"
            or request.viewer~=inquiry.viewer or request.decision_id~=inquiry.decision_id
            or request.state_revision~=inquiry.state_revision then
            ai_unsupported("nested readonly identity changed during selection","nested_askForCard.identity")
        end
    end
    if not cards then return nil end
    local function response_identity(card)
        if inquiry then
            -- Source getCardId returns Card:toString even for a virtual card.
            -- This inner inquiry never submits an action: do not mint payment.
            local value=strategy_call(card,"getLegacyStringKey")
            if type(value)~="string" or value=="" then
                ai_unsupported("nested selected source card string is unknown","nested_askForCard.identity")
            end
            return value
        end
        if type(card.isEvaluationOnly) == "function" and card:isEvaluationOnly() == true then
            if type(self.materializeResponseSelectedCard) ~= "function" then
                ai_unsupported("selected response hypothesis has no authority binder", "getCardId")
            end
            local selected = self:materializeResponseSelectedCard(card)
            if AIUnsupported.is(selected) then error(selected, 0) end
            if not AIValue.isConversion(selected) then
                ai_unsupported("selected response hypothesis did not produce a conversion receipt", "getCardId")
            end
            card = selected
        end
        if AIValue.isConversion(card) then
            for _, method in ipairs({"getConversionId", "getName", "getSuit", "getNumber", "getActivationSkillName", "getSubcards"}) do
                strategy_call(card, method)
            end
            local spec = card:toCardSpec()
            if type(spec.conversion_id) ~= "number" or type(spec.name) ~= "string"
                or type(spec.suit) ~= "number" or type(spec.number) ~= "number"
                or type(spec.skill) ~= "string" or card:getSubcards() == nil then
                ai_unsupported("conversion response identity is incomplete", "getCardId")
            end
            return spec
        end
        local id = card:getEffectiveId()
        if type(id) ~= "number" or id < 0 then ai_unsupported("physical card id is unknown", "getCardId") end
        return id
    end
    if islist then
        -- Donor smart-ai.lua5906 returns ordered toString() values, including
        -- duplicates. Policy strings are not action receipts: enumeration must
        -- not bind hypothetical costs, nor replace virtual identity with cost ID.
        local result = {}
        for _, card in ipairs(cards) do
            local key
            if type(card.isEvaluationOnly) == "function" and card:isEvaluationOnly() == true then
                if type(self.getReadonlyConversionIdentity) ~= "function" then
                    ai_unsupported("response hypothesis identity provider is unavailable", "getCardId.list")
                end
                local identity = self:getReadonlyConversionIdentity(card)
                if AIUnsupported.is(identity) then error(identity, 0) end
                if type(identity) ~= "table" or getmetatable(identity) ~= nil
                    or identity.kind ~= "readonly_conversion_identity" then
                    ai_unsupported("response hypothesis identity is invalid", "getCardId.list")
                end
                key = identity.policy_key
            else
                key = strategy_call(card, "getLegacyStringKey")
            end
            if type(key) ~= "string" or key == "" then
                ai_unsupported("exact legacy card string is unavailable", "getCardId.list")
            end
            result[#result + 1] = key
        end
        return result
    end
    return response_identity(cards)
end
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
function SmartAIView:getWoundedFriend(maleOnly,include_self,players)
	local friends = {}
	if not players then
		friends = include_self and self.friends or self.friends_noself
	else
		if type(players)=="table" then
			for _,p in ipairs(players)do
				if strategy_call(self, "isFriend", p) then
					table.insert(friends,p)
				end
			end
		else
			for _,p in ipairs(players)do
				if strategy_call(self, "isFriend", p) then
					table.insert(friends,p)
				end
			end
		end
		if not include_self and table.contains(friends,self.player) then table.removeOne(friends,self.player) end
	end
	local sorted = strategy_call(self, "sort", friends, "hp")
    for i, player in ipairs(sorted) do friends[i] = player end
	local list1 = {}    -- need help
	local list2 = {}    -- do not need help
	local addToList = function(p,index)
		if (not maleOnly or maleOnly and strategy_call(p, "isMale")) and strategy_call(p, "isWounded") then
			table.insert(index==1 and list1 or list2,p)
		end
	end

	local getCmpHp = function(p)
		local hp = strategy_call(p, "getHp")
		if strategy_call(p, "isLord") and strategy_call(self, "isWeak", p) then hp = hp-10 end
		if p:objectName()==self.player:objectName() and strategy_call(self, "isWeak", p) and strategy_call(p, "hasSkill", "qingnang") then hp = hp-5 end
		if strategy_call(p, "hasSkill", "buqu") and strategy_pile_count(p, "buqu")>0 then hp = hp+math.max(0,5-strategy_pile_count(p, "buqu")) end
		if strategy_call(p, "hasSkill", "nosbuqu") and strategy_pile_count(p, "nosbuqu")>0 then hp = hp+math.max(0,5-strategy_pile_count(p, "nosbuqu")) end
		if strategy_call(p, "hasSkills", "nosrende|rende|kuanggu|kofkuanggu|zaiqi") and strategy_call(p, "getHp")>=2 then hp = hp+5 end
		return hp
	end

	for _,friend in ipairs(friends)do
		if strategy_call(friend, "isLord") then
			if strategy_call(friend, "getMark", "hunzi")==0 and strategy_call(friend, "hasSkill", "hunzi")
			and strategy_call(self, "getEnemyNumBySeat", self.player,friend)<=(strategy_call(friend, "getHp")>=2 and 1 or 0)
			then addToList(friend,2)
			elseif strategy_call(self, "needToLoseHp", friend,nil,nil,true,true)
			then addToList(friend,2)
			elseif not strategy_call(self, "isLordHealthy")
			then addToList(friend,1) end
		else
			if strategy_call(self, "needToLoseHp", friend,nil,nil,nil,true) or (strategy_call(friend, "hasSkills", "rende|kuanggu|zaiqi") and strategy_call(friend, "getHp")>=2) then
				addToList(friend,2)
			else
				addToList(friend,1)
			end
		end
	end
	if #list2>0 then
		for _,p in ipairs(list2)do
			if table.contains(list1,p) then
				table.removeOne(list2,p)
			end
		end
	end
	local pds = {}
	for _,p in ipairs(list1)do
		pds[p:objectName()] = strategy_call(self, "getDefenseSlash", p)
	end
	for _,p in ipairs(list2)do
		pds[p:objectName()] = strategy_call(self, "getDefenseSlash", p)
	end
	local cmp = function (a,b)
		local cha = getCmpHp(a)
		local chb = getCmpHp(b)
		if cha==chb then
			return pds[a:objectName()]<pds[b:objectName()]
		end
		return cha<chb
	end
	table.sort(list1,cmp)
	table.sort(list2,cmp)
	return list1,list2
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
    local hooks = sgs.ai_hasTuntianEffect_skill or {}
    for _, name in ipairs(self:getConnections(player)) do
        local hook = hooks[name]
        if type(hook) == "function" and hook(player, need_zaoxian) then return true end
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

-- Fixed smart-ai.lua:4094-4114. Source no-result is nil; a missing
-- required facade value remains typed unsupported, never a negative answer.
sgs.ai_cardneed = sgs.ai_cardneed or {}
if sgs.ai_cardneed.bignumber == nil then
    sgs.ai_cardneed.bignumber = function(to, card, self)
        if not strategy_call(self, "willSkipPlayPhase", to) and strategy_call(self, "getUseValue", card) < 6 then
            return strategy_call(card, "getNumber") > 10
        end
    end
end
for _, entry in ipairs({{"equip", "EquipCard"}, {"weapon", "Weapon"}}) do
    local key, class = entry[1], entry[2]
    if sgs.ai_cardneed[key] == nil then
        sgs.ai_cardneed[key] = function(to, card, self)
            if not strategy_call(self, "willSkipPlayPhase", to) then return strategy_call(card, "isKindOf", class) end
        end
    end
end
if sgs.ai_cardneed.slash == nil then
    sgs.ai_cardneed.slash = function(to, card, self)
        if not strategy_call(self, "willSkipPlayPhase", to) then
            local slash = isCard("Slash", card, to)
            if AIUnsupported.is(slash) then error(slash, 0) end
            return slash and strategy_known(getKnownCard(to, self.player, "Slash", true), "cardneed.slash known count") == 0
        end
    end
end

-- 套件可覆寫的 SmartAI 相等工具。只讀快照；缺資料回 nil。不造引擎牌、不改 Room。

if type(sgs.weapon_range) ~= "table" then
    sgs.weapon_range = {
        Weapon = 1, Crossbow = 1, DoubleSword = 2, QinggangSword = 2, IceSword = 2,
        GudingBlade = 2, Axe = 3, Blade = 3, Spear = 3, Halberd = 4, KylinBow = 5
    }
end

-- Fixed lua/utilities.lua95/110: objectName comparison is opt-in; default
-- equality is the source object's identity, not its printed name or cost ID.
function table.removeOne(list, element)
    if #list < 1 then return false end
    for i = 1, #list do
        if AIValue.sameLegacyIdentity(list[i], element) then table.remove(list, i);return true end
    end
    return false
end

function table.contains(list, value, compare_objectName)
    if #list < 1 then return false end
    for _, item in ipairs(list) do
        if compare_objectName then
            if item:objectName() == value:objectName() then return true end
        elseif AIValue.sameLegacyIdentity(item, value) then return true end
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

-- Boolean strategy classification from a visible card, never a foreign ticket.
function SmartAIView:estimateCardClass(card, player, class_name)
    if strategy_call(card, "isKindOf", class_name) then
        return {value = true, status = "exact", basis = "visible_printed_class"}
    end
    local function result(value, basis, kind, skill, actual_class)
        return {value = value, status = "estimate", basis = basis, kind = kind, skill = skill,
            class = actual_class or class_name, viewer = self.player:objectName(), target = player:objectName(),
            card_id = strategy_call(card, "getEffectiveId")}
    end
    local skills = strategy_call(player, "getSkills")
    for _, skill in ipairs(skills) do
        if not strategy_call(skill, "isInvalid") then
            local name = strategy_call(skill, "objectName")
            if class_name == "Slash" and ((name == "wushen" or name == "olwushen") and strategy_call(card, "getSuit") == sgs.Card_Heart
                or name == "jinjiu" and strategy_call(card, "isKindOf", "Analeptic")) then
                return result(true, "public_filter_rule_visible_cost_private_filter_conditions_unobserved", "filter", name)
            end
        end
    end
    local place = self.room:getCardPlace(strategy_call(card, "getEffectiveId"))
    local hand = place == sgs.Player_PlaceHand
    local special = place == sgs.Player_PlaceSpecial
    for _, skill in ipairs(skills) do
        if not strategy_call(skill, "isInvalid") then
            local name = strategy_call(skill, "objectName")
            local matches, actual = false, class_name
            if name == "wusheng" and class_name == "Slash" then matches = strategy_call(card, "isRed") and not strategy_call(card, "isKindOf", "Peach")
            elseif name == "longdan" and (hand or special) then
                matches = class_name == "Slash" and strategy_call(card, "isKindOf", "Jink") or class_name == "Jink" and strategy_call(card, "isKindOf", "Slash")
            elseif name == "qingguo" and class_name == "Jink" and (hand or special) then matches = strategy_call(card, "isBlack")
            elseif name == "kanpo" and class_name == "Nullification" and (hand or special) then matches = strategy_call(card, "isBlack")
            elseif name == "jijiu" and class_name == "Peach" and strategy_call(player, "getPhase") == sgs.Player_NotActive then matches = strategy_call(card, "isRed")
            elseif name == "longhun" and strategy_call(player, "getHp") <= 1 then
                local suit = strategy_call(card, "getSuit")
                if (class_name == "Slash" or class_name == "FireSlash") and suit == sgs.Card_Diamond then matches, actual = true, "FireSlash"
                elseif class_name == "Jink" and suit == sgs.Card_Club or class_name == "Peach" and suit == sgs.Card_Heart
                    or class_name == "Nullification" and suit == sgs.Card_Spade then matches = true end
            end
            if matches then return result(true, "public_viewas_rule_visible_cost_private_enablement_and_limits_unobserved", "view_as", name, actual) end
        end
    end
    return result(false, "visible_printed_lower_bound_no_recognized_public_conversion")
end

local function estimated_class_card(self, card, player, class_name)
    local result = self:estimateCardClass(card, player, class_name)
    if not self:useKnowledgeEstimate(result, "isCard.foreign") then return nil, result end
    if result.status == "exact" or result.kind == "filter" then return card, result end
    local classes = {
        Slash = {"slash", 1, {"Slash", "BasicCard", "Card"}, false, true, 1},
        FireSlash = {"fire_slash", 1, {"FireSlash", "NatureSlash", "Slash", "BasicCard", "Card"}, false, true, 2},
        Jink = {"jink", 1, {"Jink", "BasicCard", "Card"}, true, false, 3},
        Peach = {"peach", 1, {"Peach", "BasicCard", "Card"}, true, false, 4},
        Nullification = {"nullification", 2, {"Nullification", "SingleTargetTrick", "TrickCard", "Card"}, true, false, 5}
    }
    local meta = strategy_known(classes[result.class], "estimated standard class metadata")
    local id = strategy_call(card, "getEffectiveId")
    local suit = strategy_call(card, "getSuit")
    local value = CardView.new({id = -6000000 - math.abs(id) * 8 - meta[6],
        effective_id = -6000000 - math.abs(id) * 8 - meta[6], name = meta[1], class_name = result.class,
        engine_class_name = result.class, kind_of = meta[3], type_id = meta[2], suit = suit,
        number = strategy_call(card, "getNumber"), virtual_card = true, subcards = {id},
        skill_name = result.skill, source_skill = result.skill, skill_names = {result.skill},
        target_fixed = meta[4], damage_card = meta[5], can_recast = false,
        red = suit == sgs.Card_Heart or suit == sgs.Card_Diamond,
        black = suit == sgs.Card_Club or suit == sgs.Card_Spade,
        flags = {}, evaluation_only = true, estimated = true, evaluation_owner = player:objectName()})
    -- Deliberately no availability, limitations, prohibition rules or ticket.
    return value, result
end

-- Printed identity, hand-place filtering, then the ordered skill view-as
-- dispatcher. Only the latter can return an authoritative conversion ticket.
function isCard(class_name, card, player, classification_only)
    if type(class_name) ~= "string" or not card or type(card.isKindOf) ~= "function" then return nil end
    local original_room=player and rawget(player,"_room")
    local original_ai=original_room and original_room._ai
    local original_mode=original_ai and original_ai.world and AIHegemony.facts(original_ai.world)
    if original_mode and original_mode.enabled and original_mode.original_overrides_loaded==true then
        return original_ai:originalHegemonyIsCard(class_name,card,player)
    end
    if string.find(class_name, ",", 1, true) then
        for piece in string.gmatch(class_name, "[^,]+") do
            local found = isCard(piece, card, player, classification_only)
            if found then return found end
        end
        return nil
    end
    if strategy_call(card, "isKindOf", class_name) then return card end
    if not player then return nil end
    local room = rawget(player, "_room")
    local ai = room and room._ai
    local skills = strategy_call(player, "getSkills")
    local conversion_skill = ai and same_player(player, ai.player) and #skills > 0 or false
    local filtered = false
    for _, skill in ipairs(skills) do
        if not strategy_call(skill, "isInvalid") then
            if strategy_call(skill, "inherits", "FilterSkill") and not filtered then
                local place = room and room:getCardPlace(strategy_call(card, "getEffectiveId"))
                if place ~= sgs.Player_PlaceEquip or place == nil then
                    -- The viewer's projected hand already carries filtered faces.
                    local row = same_player(player, ai and ai.player) and {complete=true, card=card._view} or nil
                    if type(row) ~= "table" or row.complete ~= true or type(row.card) ~= "table" then
                        if ai and not same_player(player, ai.player) then return estimated_class_card(ai, card, player, class_name) end
                        ai_unsupported("hand-place filter classification is not projected", "isCard.CardFilter")
                    end
                    if type(row.donor_error_repair) == "string" then
                        ai:useKnowledgeEstimate({value = true, status = "estimate", difference_kind = "donor_error_repair",
                            basis = "donor_error_repair:" .. row.donor_error_repair}, "isCard.CardFilter")
                    end
                    if strategy_call(CardView.new(row.card), "isKindOf", class_name) then return card end
                end
                filtered = true
            end
            local metadata = rawget(skill, "_view")
            if strategy_call(skill, "inherits", "ViewAsSkill")
                or type(metadata) == "table" and metadata.has_view_as_skill == true
                or type(sgs.ai_view_as) == "table" and type(sgs.ai_view_as[skill:objectName()]) == "function" then conversion_skill = true end
        end
    end
    if conversion_skill then
        if ai and not same_player(player, ai.player) then return estimated_class_card(ai, card, player, class_name) end
        if not ai then ai_unsupported("skill view-as classification needs a viewer context", "isCard") end
        -- Native legacy_hooks, not isolated registry absence, proves whether a
        -- donor callback exists. The dispatcher validates all gates and order.
        local owner = room:getCardOwner(strategy_call(card, "getEffectiveId"))
        local place = not same_player(owner, player) and strategy_known(sgs.Player_PlaceHand, "hand place enum") or nil
        if classification_only then
            if type(ai.classifyOfferedSkillViewCard) ~= "function" then ai_unsupported("acquired-card readonly classification dispatcher is unavailable", "isCard.acquisition") end
            return ai:classifyOfferedSkillViewCard(class_name, card, player, place)
        end
        if type(ai.getSkillViewCard) ~= "function" then ai_unsupported("owner view-as dispatcher is unavailable", "isCard") end
        return ai:getSkillViewCard(class_name, card, player, place)
    end
    return nil
end


-- Boolean-only counterpart for acquisition policies. Offered faces are not
-- payments; view-as recognition here must never issue a conversion receipt.
function SmartAIView:isCardForAcquisition(class_name,card)
    local request=self.request or{}
    local options=request.options
    if (request.kind~="amazing_grace"and request.kind~="guanxing")or type(options)~="table"or type(options.card_ids)~="table"then
        ai_unsupported("acquired-card classification requires a disclosed choice domain","isCard.acquisition")
    end
    local id=strategy_call(card,"getEffectiveId")
    local offered=false
    for _,candidate in ipairs(options.card_ids)do if candidate==id then offered=true;break end end
    local disclosed=self:getChoiceCard(id)
    if not offered or not disclosed then ai_unsupported("acquired card is outside the current disclosed choice","isCard.acquisition")end
    local original=AIHegemony.facts(self.world)
    if original and original.enabled and original.original_overrides_loaded==true then
        -- Original checks limitation even for its printed-class fast path.
        -- Reuse only this offered face's native hypothetical acquisition rules.
        disclosed=strategy_call(self,"getAcquiredCardEvaluation",disclosed)
    end
    local value=isCard(class_name,disclosed,self.player,true)
    return value~=nil and value~=false
end

function getKnownCards(player, from, flags)
    if not player then return nil end
    local room = rawget(player, "_room")
    if from == nil and room then from = room:getCurrent() or room._ai and room._ai.player end
    if AIValue.isPlayer(from) then
        local observer_room = rawget(from, "_room")
        local world = observer_room and rawget(observer_room, "_world")
        if type(world) ~= "table" or type(world.self) ~= "table" or world.self.object_name ~= from:objectName() then return nil end
    end
    flags = type(flags) == "string" and flags or "&h"
    local cards, visible_hand = {}, 0
    if string.find(flags, "h", 1, true) then
        local hand = player:getKnownCards()
        if not hand then return nil end
        visible_hand = #hand
        for _, card in ipairs(hand) do cards[#cards + 1] = card end
        if string.find(flags, "&", 1, true) then
            local view = rawget(player, "_view")
            local piles = type(view) == "table" and view.piles or nil
            if not AIValue.isList(piles) then return nil end
            for _, pile in ipairs(piles) do
                if type(pile.hand_pile) ~= "boolean" then return nil end
                if pile.hand_pile then
                    if type(pile.open) ~= "boolean" then return nil end
                    if pile.open then
                        if not AIValue.isList(pile.cards) or not AIValue.isList(pile.card_ids)
                            or #pile.cards ~= #pile.card_ids then return nil end
                        for i, row in ipairs(pile.cards) do
                            local card = CardView.new(row)
                            if not card or card:getEffectiveId() ~= pile.card_ids[i] then return nil end
                            cards[#cards + 1] = card
                        end
                    end
                end
            end
        end
    end
    if string.find(flags, "e", 1, true) then
        local equips = player:getEquips()
        if not equips then return nil end
        for _, card in ipairs(equips) do cards[#cards + 1] = card end
    end
    return AIList.new(cards), visible_hand
end

function SmartAIView:getKnownCards(player, from, flags)
    return getKnownCards(player or self.player, from or self.player, flags)
end
function getKnownNum(player, observer)
    local cards = getKnownCards(player, observer)
    return cards and #cards or nil
end

-- Donor global uses visible he cards with view-as classification. Resolve the
-- current viewer explicitly; a third observer uses the shared marked estimate,
-- never that observer's private hand or another AI instance's cache.
function getCardsNum(class_name, player, observer)
    local room = type(player) == "table" and rawget(player, "_room")
    local ai = room and rawget(room, "_ai")
    if not ai and type(observer) == "table" then
        room = rawget(observer, "_room")
        ai = room and rawget(room, "_ai")
    end
    if not ai then ai_unsupported("card-count viewer context is absent", "getCardsNum") end
    local mode=ai.world and AIHegemony.facts(ai.world)
    if mode and mode.enabled and mode.original_overrides_loaded==true then
        return strategy_call(ai,"originalHegemonyCardsNum",class_name,player,observer)
    end
    return ai:useKnowledgeEstimate(ai:estimateKnownCards(player, class_name, observer, true, "he"), "getCardsNum")
end

function getKnownCard(player, from, class_name, viewas, flags, return_table)
    if type(class_name) ~= "string" then return 0 end
    if not player then return nil end
    local playerRoom=type(player)=="table" and rawget(player,"_room")
    local viewer=playerRoom and playerRoom._ai
    local mode=viewer and viewer.world and AIHegemony.facts(viewer.world)
    if mode and mode.enabled and mode.original_overrides_loaded==true then
        if type(viewer.originalHegemonyKnownCard)~="function" then ai_unsupported("Original known-card policy is not loaded","getKnownCard") end
        return viewer:originalHegemonyKnownCard(player,from,class_name,viewas,flags,return_table)
    end
    if string.find(class_name, ",", 1, true) then
        local total, status, observed = 0, "exact", 0
        for piece in string.gmatch(class_name, "[^,]+") do
            local part, coverage = getKnownCard(player, from, piece, viewas, flags)
            if part == nil then return nil end
            total = total + part
            if coverage then
                observed = observed + coverage.known_count
                if coverage.status == "estimate" then status = "estimate" end
            end
        end
        return total, {value = total, status = status, basis = "class_sum", known_count = observed}
    end
    -- Only the current viewer's visibility is projected. A hypothetical third
    -- observer must not reuse this viewer's private knowledge.
    if AIValue.isPlayer(from) then
        local room = rawget(from, "_room")
        local world = room and rawget(room, "_world")
        local viewer = world and world.self
        if type(viewer) ~= "table" or viewer.object_name ~= from:objectName() then return nil end
    end
    flags = type(flags) == "string" and flags or "&h"
    local cards, visible_hand = getKnownCards(player, from, flags)
    if not cards then return nil end
    local known, estimated_classification, estimated_matches = 0, false, 0
    for _, card in ipairs(cards) do
        local suit = type(card.getSuitString) == "function" and card:getSuitString() or nil
        local color = type(card.getColorString) == "function" and card:getColorString() or nil
        local matches = card:isKindOf(class_name)
        if matches == nil then return nil end
        if (class_name == "heart" or class_name == "diamond" or class_name == "club" or class_name == "spade")
            and suit == nil then return nil end
        if (class_name == "red" or class_name == "black") and color == nil then return nil end
        local printed = matches or suit == class_name or color == class_name
        local converted, coverage
        if not printed and viewas then converted, coverage = isCard(class_name, card, player) end
        if coverage and coverage.status == "estimate" then
            estimated_classification = true
            if converted then estimated_matches = estimated_matches + 1 end
        end
        if printed or converted then known = known + 1 end
    end
    -- 看得見的太少時，沿用原版的一張暗牌估計。手牌張數不明就不估計。
    local hand = type(player.getHandcardNum) == "function" and player:getHandcardNum() or nil
    if type(hand) ~= "number" then return nil end
    local observed = known
    if #cards < hand / 2 and hand > 2 and known < hand / 3 then
        if not from or type(from.hasFlag) ~= "function" then return nil end
        local dying = from:hasFlag("Global_Dying")
        if dying == nil then return nil end
        if not dying then known = known + 1 end
    end
    local hidden = string.find(flags, "h", 1, true) and math.max(0, hand - visible_hand) or 0
    return known, {value = known, status = (estimated_classification or hidden > 0 or known > observed) and "estimate" or "exact",
        basis = estimated_classification and "viewer_visible_cards_with_public_conversion_estimates" or known > observed and "legacy_unseen_card_prior" or "viewer_visible_lower_bound",
        known_count = observed - estimated_matches, estimated_matches = estimated_matches, hidden_count = hidden, visible_count = #cards}
end

function hasBuquEffect(player)
    if strategy_call(player,"hasSkill","buqu") and strategy_pile_count(player,"buqu")<=4 then return true end
    if strategy_call(player,"hasSkill","nosbuqu") and strategy_pile_count(player,"nosbuqu")<=4 then return true end
    local room=rawget(player,"_room")
    local ai=room and room._ai
    if not ai then ai_unsupported("Buqu hooks require viewer connection context","hasBuquEffect") end
    for _,name in ipairs(strategy_call(ai,"getConnections",player))do
        local callback=sgs.ai_hasBuquEffect_skill[name]
        if type(callback)=="function" then
            local result=callback(player)
            if AIUnsupported.is(result) then error(result,0) end
            if result then return true end
        end
    end
    return false
end

function hasManjuanEffect(player, manjuan_only)
    if not player or sgs.Player_NotActive == nil then return nil end
    local phase = player:getPhase()
    if type(phase) ~= "number" then return nil end
    if phase ~= sgs.Player_NotActive then return false end
    if strategy_call(player, "hasSkill", "manjuan") then return true end
    if not manjuan_only and strategy_call(player, "hasSkill", "zishu") then return true end
    return false
end

function isLord(player)
    if not player or type(player.isLord) ~= "function" then return nil end
    return player:isLord()
end

-- SmartAI's getLord: the lord, else a same-role partner (which needs the roles), else
-- the player itself. Hegemony has none.
function getLord(player)
    local room = AIValue.isPlayer(player) and rawget(player, "_room")
    local world = room and rawget(room, "_world")
    if type(world) ~= "table" or world.enable_hegemony ~= false then return nil end
    local lord = room:getLord()
    if lord then return lord end
    local role = rawget(player, "_view").role
    if type(role) ~= "string" then ai_unsupported("getLord needs the player's role", "getLord") end
    if role ~= "renegade" then
        for _, other in ipairs(room:getOtherPlayers(player)) do
            local other_role = rawget(other, "_view").role
            if type(other_role) ~= "string" then ai_unsupported("getLord needs every role", "getLord") end
            if other_role == role then return other end
        end
    end
    return player
end

-- addFunction.lua's CanToCard: card:targetFilter(tos, to, from), answered for the
-- viewer's own use only.
function CanToCard(card, from, to, tos)
    local room = AIValue.isPlayer(from) and rawget(from, "_room")
    local ai = room and room._ai
    if not ai or not same_player(from, ai.player) then ai_unsupported("CanToCard needs the viewer as user", "CanToCard") end
    return ai:cardTargetFilter(card, tos or {}, to)
end

-- SmartAI's isCurrent: whether `to` is already among the plan's current targets.
function isCurrent(use, to)
    if AIList.isNativeList(use.current_targets) then return use.current_targets:contains(to) end
    if type(use.current_targets) == "table" then
        for _, p in ipairs(use.current_targets) do
            if p == to or p == to:objectName() then return true end
        end
    elseif type(use.current_targets) == "userdata" then return use.current_targets:contains(to) end
end

-- 策略探測用的類別替身，只回答類別與是否傷害牌。不能拿去出牌。
function SmartAIView:classProbe(class_name)
    if type(class_name) ~= "string" or class_name == "" then return nil end
    local names = {Jink = "jink", Slash = "slash", Peach = "peach", FireSlash = "fire_slash", ThunderSlash = "thunder_slash"}
    if self.world and type(self.getEvaluationCard) == "function" then
        local projected = self:getEvaluationCard(names[class_name] or class_name)
        if projected then return projected end
    end
    local tricks = {
        Duel = true, SavageAssault = true, ArcheryAttack = true, FireAttack = true,
        Indulgence = true, SupplyShortage = true, Snatch = true, Dismantlement = true,
        ExNihilo = true, Nullification = true, AmazingGrace = true, GodSalvation = true,
        Collateral = true, Lightning = true
    }
    local damage = {
        Slash = true, FireSlash = true, ThunderSlash = true, IceSlash = true, Duel = true, SavageAssault = true, ArcheryAttack = true, FireAttack = true
    }
    local probe = {}
    function probe:getClassName() return class_name end
    function probe:objectName() return class_name end
    function probe:isKindOf(kind)
        if kind == class_name then return true end
        if (kind == "Slash" or kind == "NatureSlash") and (class_name == "FireSlash" or class_name == "ThunderSlash" or class_name == "IceSlash") then return true end
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
    to=to or self.player
    if strategy_call(to,"getHp")>1 or strategy_known(hasBuquEffect(to),"Buqu effect")
        or strategy_call(self,"canNiepan",to)
        or strategy_known(getCardsNum("Peach,Analeptic",to,self.player),"rescue cards")>0 then return true
    elseif not(self.room:getCurrent() and strategy_call(self.room:getCurrent(),"hasSkill","wansha")) then
        for _,player in sgs.list(strategy_call(self,"getFriends",to,true))do
            if strategy_known(getCardsNum("Peach",player,self.player),"friendly Peach")>0 then return true end
        end
    end
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
    -- Native exposes only this viewer's required count, not another player's
    -- complete private Jink_<card> tag. Full lists remain a supported DTO shape.
    if type(use) ~= "table" then return nil end
    if use.source_expected_jink_error == true then
        error("source getExpectedJinkNum compares a missing or nonnumeric viewer slot", 0)
    elseif use.source_expected_jink_error ~= nil and type(use.source_expected_jink_error) ~= "boolean" then
        ai_unsupported("projected viewer Jink error witness is malformed", "getExpectedJinkNum")
    end
    if use.expected_jink_num ~= nil then
        local count = use.expected_jink_num
        if type(count) ~= "number" or count ~= count or count < 0 or count > 0 and count < 1 or count == math.huge then
            ai_unsupported("projected viewer Jink requirement is malformed", "getExpectedJinkNum")
        end
        return count
    end
    local numbers = use.jink_numbers or use.jink_list
    if type(use.to) ~= "table" then return nil end
    local expected = 1
    for index, target in ipairs(use.to) do
        local name = type(target) == "table" and target.objectName and target:objectName() or target
        if name == self.player:objectName() then
            if type(numbers) ~= "table" then return nil end
            local count = tonumber(numbers[index])
            if count == nil then return nil end
            if count == 0 then return 0 end
            if count > expected then expected = count end
        end
    end
    return expected
end

function SmartAIView:getSaveNum(for_friend)
    local num = 0
    local function call(object, method, ...) return strategy_call(object, method, ...) end
    local function count(player, kind)
        return self:useKnowledgeEstimate(self:estimateKnownCards(player, kind, self.player, true, "he"), "getSaveNum:" .. kind)
    end
    for _, player in ipairs(call(self.room, "getAllPlayers")) do
        if (for_friend and strategy_call(self,"isFriend",player)) or (not for_friend and strategy_call(self,"isEnemy",player)) then
            local current = self.room:getCurrent()
            local active = false
            if current then
                if self.world and type(self.world.has_current_active) == "boolean" then active = self.world.has_current_active
                else active = call(current, "hasFlag", "CurrentPlayer") end
            end
            if not (active and call(current, "hasSkill", "wansha")) or call(self.player, "hasSkill", "spdushi") or same_player(player, self.player) then
                if call(player, "hasSkill", "jijiu") then
                    num = num + call(self, "getSuitNum", "heart", true, player)
                    num = num + call(self, "getSuitNum", "diamond", true, player)
                    num = num + self:useKnowledgeEstimate({value = call(player, "getHandcardNum") * .4, status = "estimate", basis = "legacy_jijiu_hand_prior"}, "getSaveNum:jijiu")
                end
                if call(player, "hasSkill", "nosjiefan") and count(player, "Slash") > 0 then
                    if relation == "friend" or call(self, "getCardsNum", "Jink") == 0 then num = num + count(player, "Slash") end
                end
            end
            if call(player, "hasSkill", "mobilezhiyuejian") then
                local can_discard, uncertain = 0, 0
                local hand = call(player, "getKnownCards")
                local cards = {}
                for _, card in ipairs(hand) do cards[#cards + 1] = card end
                for _, card in ipairs(call(player, "getEquips")) do cards[#cards + 1] = card end
                for _, card in ipairs(cards) do
                    local allowed = player:canDiscard(player, call(card, "getEffectiveId"))
                    if allowed == true then can_discard = can_discard + 1
                    elseif allowed == nil then
                        if same_player(player, self.player) then ai_unsupported("owner discard legality is unavailable", "getSaveNum") end
                        uncertain = uncertain + 1
                    end
                    if can_discard >= 2 then break end
                end
                if can_discard >= 2 then num = num + 1
                else
                    uncertain = uncertain + math.max(0, call(player, "getHandcardNum") - #hand)
                    if uncertain > 0 then
                        -- No authority reads concealed card identities/locks. An
                        -- explicit symmetric prior models each unknown cost as
                        -- discardable with p=.5, producing expected rescue count.
                        local probability = 1 - .5 ^ uncertain
                        if can_discard == 0 then probability = probability - uncertain * .5 ^ uncertain end
                        num = num + self:useKnowledgeEstimate({value = probability, status = "estimate",
                            basis = "unknown_discardability_symmetric_prior", known_count = can_discard,
                            hidden_count = uncertain, success_probability = probability}, "getSaveNum:mobilezhiyuejian")
                    end
                end
                if same_player(player, self.player) then num = num + count(player, "Peach") end
            end
            if call(player, "hasSkill", "buyi") and not call(player, "isKongcheng") then num = num + .3 end
            if call(player, "hasSkills", "chunlao|tenyearchunlao|secondtenyearchunlao") then
                local wine = call(player, "getPileCount", "wine")
                if wine > 0 then num = num + wine end
            end
            if call(player, "hasSkill", "jiuzhu") and call(player, "getHp") > 1 and not call(player, "isNude") then
                num = num + .9 * math.max(0, math.min(call(player, "getHp") - 1, call(player, "getHandcardNum") + #call(player, "getEquips")))
            end
            if call(player, "hasSkill", "nosrenxin") and not same_player(player, self.player) and not call(player, "isKongcheng") then num = num + 1 end
            if call(player, "hasSkill", "luanfeng") and strategy_mark(self, player, "@luanfengMark") > 0
                and call(self.player, "getMaxHp") >= call(player, "getMaxHp") then
                num = num + math.min(3, call(self.player, "getMaxHp")) - call(self.player, "getHp")
            end
        end
    end
    return num
end

function SmartAIView:hasExplicitRebel()
    local predictable = strategy_call(self, "isRolePredictable")
    for _, player in ipairs(strategy_call(self.room, "getAllPlayers")) do
        if predictable and strategy_call(self, "getRoleEstimate", player) == "rebel" then return true end
        if self:compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then return true end
    end
    return false
end

-- 套件用 ai_jueqing_effect／ai_hasTuntianEffect_skill 擴充，不把擴展武將名寫進這層。
sgs.jueqing_skill = sgs.jueqing_skill or "jueqing|gangzhi"
sgs.ai_jueqing_effect = sgs.ai_jueqing_effect or {}





function SmartAIView:beFriend(to, from)
    if not to or not from then return false end
    if same_player(to, from) then return true end
    local estimated = false
    local predictable = strategy_call(self, "isRolePredictable")
    local function role(player)
        if strategy_call(player, "isLord") then return "lord" end
        if same_player(player, self.player) or predictable then return strategy_call(player, "getRole") end
        estimated = true
        return strategy_call(self, "getRoleEstimate", player)
    end
    local source_role, target_role = role(from), role(to)
    local value = false
    if source_role == "lord" or source_role == "loyalist" then
        value = target_role == "renegade" and strategy_call(self.room, "getTurnCount") <= 1 and strategy_call(from, "aliveCount") > 7
            or target_role == "lord" or target_role == "loyalist"
    elseif source_role == "rebel" then value = target_role == "rebel"
    elseif source_role == "renegade" then
        value = target_role == "loyalist" and strategy_call(self.room, "getTurnCount") <= 1 and strategy_call(from, "aliveCount") > 7
            or target_role == "lord" and strategy_call(from, "aliveCount") > 2
    end
    if estimated then
        return self:useKnowledgeEstimate({value = value, status = "estimate", viewer = self.player:objectName(), source = from:objectName(), target = to:objectName(),
            basis = "donor_true_role_alliance_replaced_by_viewer_role_estimates"}, "beFriend")
    end
    return value
end

function SmartAIView:hasJueqingEffect(from, to, nature)
    if from and strategy_call(from, "hasSkills", "jueqing|gangzhi") then return true end
    if from and strategy_call(from, "hasSkill", "tenyearjueqing") and strategy_call(from, "getMark", "tenyearjueqing") > 0 then return true end
    if to and strategy_call(to, "hasSkill", "gangzhi") then return true end
    nature = nature or sgs.DamageStruct_Normal
    if from and strategy_call(from, "hasSkill", "meizlwuqing") and strategy_call(from, "isWounded") and nature == sgs.DamageStruct_Normal then return true end
    if from and strategy_call(from, "hasSkill", "MeowJueqing") then return true end
    if from and strategy_call(from, "hasSkill", "exjueqing") then return true end
    if to and strategy_call(to, "hasSkill", "nyarz_shibei") and strategy_call(to, "getMark", "nyarz_shibei-Clear") > 1 then return true end
    if to and strategy_call(to, "hasSkill", "xinnian") then return true end
    if from and strategy_pile_count(from, "sp_ss") > 0 then return true end
    if from and strategy_call(from, "hasSkill", "sy_xushu") then return true end
    if to and strategy_call(to, "hasSkill", "sy_xushu") then return true end
    if to and strategy_call(to, "hasSkill", "s3_yijue") then return true end
    if from and to and strategy_call(from, "hasSkill", "bffeedingpoisoning")
        and (strategy_call(from, "distanceTo", to) == 1 or strategy_call(to, "distanceTo", from) == 1)
        and not self:beFriend(to, from) then return true end
    -- Pure package extension ABI follows the complete common donor predicates.
    for _, player in ipairs({from or false, to or false}) do
        if player then
            for _, hook in ipairs(strategy_known(self:forSkillHooks("ai_jueqing_effect", player), "jueqing hooks")) do
                if type(hook.value) == "function" then if hook.value(self, from, to, nature) then return true end
                elseif hook.value then return true end
            end
        end
    end
    return false
end

function SmartAIView:hasOrangeEffect(player)
    if not player then return false end
    local source = self.room:findPlayerBySkillName("huaiju")
    return source ~= nil and strategy_mark(self, player, "&orange") > 0 or false
end

function SmartAIView:dontHurt(to, from)
    if strategy_call(self, "hasJueqingEffect", from, to) or self:hasOrangeEffect(to) then return true end
    local function scan(player, registry)
        if not player then return false end
        for _, name in ipairs(self:getConnections(player)) do
            local rule = (sgs[registry] or {})[name]
            if rule then
                if type(rule) ~= "function" or rule(self, to, from) then return true end
            end
        end
        return false
    end
    return scan(from, "ai_dont_hurt_from") or scan(to, "ai_dont_hurt_to")
end

function SmartAIView:getAllPeachNum(player)
    local total = 0
    player = player or self.player
    local wansha = strategy_call(self.room:getCurrent() or self.player, "hasSkill", "wansha")
    for _, friend in ipairs(strategy_call(self, "getFriends", player)) do
        local class = same_player(player, friend) and "Peach,Analeptic" or "Peach"
        if same_player(player, friend) or not wansha then
            total = total + strategy_known(getCardsNum(class, friend, self.player), "known recovery count")
        end
    end
    return total
end

function SmartAIView:keepCard(card, player, discard_peach, as_peach)
    if not card then return true end
    player = player or self.player
    if strategy_call(card, "isKindOf", "WoodenOx") and strategy_pile_count(player, "wooden_ox") > 0 then
        if not as_peach then return true end
        local ids = player:getPile("wooden_ox")
        if ids == nil then
            if same_player(player, self.player) then ai_unsupported("owner WoodenOx IDs are unknown", "keepCard") end
            local count = strategy_pile_count(player, "wooden_ox")
            local probability = 1 - 0.85 ^ count
            return self:useKnowledgeEstimate({value = probability >= 0.5, status = "estimate",
                basis = "closed_foreign_woodenox_peach_presence_prior_0.15_per_card",
                viewer = self.player:objectName(), target = player:objectName(), hidden_count = count,
                success_probability = probability}, "keepCard.asPeach")
        end
        local view = rawget(player, "_view")
        local rows = {}
        for _, pile in ipairs(type(view) == "table" and view.piles or {}) do
            if pile.name == "wooden_ox" then
                for _, row in ipairs(pile.cards or {}) do rows[row.id] = row end
            end
        end
        for _, id in ipairs(ids) do
            local row = rows[id]
            if not row then ai_unsupported("WoodenOx Peach classification requires visible pile cost metadata", "keepCard") end
            local classified = isCard("Peach", CardView.new(row), player)
            if AIUnsupported.is(classified) then error(classified, 0) end
            if classified then return true end
        end
        return false
    end
    return not discard_peach and strategy_call(card, "isKindOf", "Peach") or false
end

-- Resolve only owner-visible costs. No ID is used to query the native engine.
local function owner_cost_card(self, id, action)
    for _, card in ipairs(strategy_call(self.player, "getCards", "he")) do
        if strategy_call(card, "getEffectiveId") == id then return card end
    end
    local view = rawget(self.player, "_view")
    for _, pile in ipairs(type(view) == "table" and view.piles or {}) do
        for _, row in ipairs(type(pile.cards) == "table" and pile.cards or {}) do
            if row.id == id then return CardView.new(row) end
        end
    end
    -- Xiansi alone pays another player's publicly exposed counter pile. The
    -- actual native receipt must authorize this exact cost and source identity;
    -- a policy prototype or an arbitrary foreign ID grants no such permission.
    if action and strategy_call(action,"getClassName")=="XiansiSlashCard" then
        local authority=type(action.getAuthorityCard)=="function" and action:getAuthorityCard()or action
        if AIValue.isConversion(authority) then
            local cid=authority:getConversionId()
            local registered=self._indexes and self._indexes.conversions_by_id and self._indexes.conversions_by_id[cid]
            local row=rawget(authority,"_view")
            local valid=type(registered)=="table" and registered.activation_skill=="xiansi_slash"
                and registered.activation_owner==self.player:objectName() and type(row)=="table"
            for _,key in ipairs({"activation_owner","activation_skill","activation_instance","source_owner","source_skill","source_instance"})do
                valid=valid and registered[key]==row[key]
            end
            local authorized=false
            if valid then for _,cost in ipairs(registered.subcards or{})do if cost==id then authorized=true end end end
            if authorized then
                for _,player in ipairs(strategy_call(self.room,"getAlivePlayers"))do
                    local pv=rawget(player,"_view")
                    for _,pile in ipairs(type(pv)=="table" and pv.piles or{})do
                        if pile.name=="counter" and pile.open==true then
                            for _,face in ipairs(pile.cards or{})do
                                if face.id==id then return CardView.new(face)end
                            end
                        end
                    end
                end
            end
        end
    end
    ai_unsupported("skill-card cost metadata is not owner-visible or an authorized public counter cost", "useSkillCard.cost")
end

function SmartAIView:useSkillCard(card, use)
    local name = strategy_call(card, "getClassName")
    local request
    local active = strategy_call(card, "isKindOf", "ActiveSkillCard")
    local authority = type(card.getAuthorityCard) == "function" and card:getAuthorityCard() or card
    local seed = type(card.isStrategySeed) == "function" and card:isStrategySeed() == true
    local conversion = type(authority.getConversionId) == "function" and authority:getConversionId() or nil
    local readonly = type(self.isReadonlyTurnConversion) == "function" and self:isReadonlyTurnConversion(card)
    if active or conversion ~= nil or seed or readonly then
        local key = tostring(strategy_call(authority, "getEffectiveId")) .. ":" .. tostring(conversion or "")
        request = self.active_skill_requests and self.active_skill_requests[key]
    end
    if active then
        name = strategy_call(card, "getSkillName")
    elseif strategy_call(card, "isKindOf", "LuaSkillCard") then
        name = "#" .. strategy_call(card, "objectName")
    end
    local registry = sgs.ai_skill_use_func or {}
    local invoke = registry[name]
    if type(invoke) ~= "function" and request then
        invoke = registry[strategy_call(request, "getSourceSkillName")]
    elseif type(invoke) ~= "function" and strategy_call(card, "isKindOf", "ActiveSkillCard") then
        invoke = registry[strategy_call(card, "getSourceSkillName")]
    end
    if type(invoke) == "function" then
        local result = invoke(card, use, self, request)
        if AIUnsupported.is(result) then error(result, 0) end
    else
        invoke = self["useCard" .. name]
        if invoke then
            local result = invoke(self, card, use)
            if AIUnsupported.is(result) then error(result, 0) end
        end
    end
    if use.card and strategy_call(use.card, "willThrow")
        and strategy_call(use.card, "subcardsLength") > 0 then
        local hp = strategy_call(self.player, "getHp")
        for _, id in ipairs(strategy_call(use.card, "getSubcards")) do
            local cost = owner_cost_card(self, id, use.card)
            if strategy_call(cost, "isKindOf", "Poison") or strategy_call(cost, "isKindOf", "Shit") then hp = hp - 1 end
        end
        if hp < 1 and hp + strategy_call(self, "getAllPeachNum") < 1 then use.card = nil end
    end
end

local function value_skill_tag(self, player, key, list)
    if same_player(player, self.player) and (key == "BaiyiUsed" or key == "Jinglve_targets") then
        local value = player:getTag(key)
        if value == nil then return list and {} or false end
        return value
    end
    local value = list and {} or false
    local basis = "foreign_awakening_history_unobserved_conservative_not_ready"
    if key:sub(1,13) == "liangzhu_draw" then
        value = strategy_call(player, "getMark", "@liangzhu_draw") > 0
        basis = "public_liangzhu_recipient_mark_used_without_private_source_attribution"
    end
    if list then
        self:useKnowledgeEstimate({value = 0, status = "estimate", basis = basis, viewer = self.player:objectName(), target = player:objectName(), class = key}, "isValueSkill.history")
        return value
    end
    return self:useKnowledgeEstimate({value = value, status = "estimate", basis = basis, viewer = self.player:objectName(), target = player:objectName(), class = key}, "isValueSkill.history")
end
local function value_skill_lowest(self, player)
    for _, other in ipairs(strategy_call(self.room, "getAlivePlayers")) do
        if strategy_call(other, "getHp") < strategy_call(player, "getHp") then return false end
    end
    return true
end
local function value_skill_equip_area(player)
    for index = 0, 4 do if strategy_call(player, "hasEquipArea", index) then return true end end
    return false
end
local function value_skill_lord_excludes(self, fragment)
    local lord = self.room:getLord()
    if not lord then return false end
    local first = type(lord.getGeneralName) == "function" and lord:getGeneralName()
    local second = type(lord.getGeneral2Name) == "function" and lord:getGeneral2Name()
    if type(first) == "string" and string.find(first, fragment) or type(second) == "string" and string.find(second, fragment) then return false end
    if type(first) ~= "string" or type(second) ~= "string" then
        return self:useKnowledgeEstimate({value = true, status = "estimate", basis = "unrevealed_lord_general_assumed_not_awakening_blocker", viewer = self.player:objectName(), target = lord:objectName(), class = fragment}, "isValueSkill.lord")
    end
    return true
end

local function r32_value_skill_role(self, player)
    local role = player:getRole()
    if AIUnsupported.is(role) then error(role, 0) end
    if role ~= nil then return role end
    return strategy_call(self, "useKnowledgeEstimate", {
        value = strategy_call(self, "getRoleEstimate", player), status = "estimate",
        viewer = self.player:objectName(), target = player:objectName(),
        basis = "viewer inferred role replaces hidden role in awakening policy"
    }, "isValueSkill.kegou")
end

local function r32_value_skill_lowest(self, player)
    local hp = strategy_call(player, "getHp")
    for _, other in ipairs(strategy_call(self.room, "getAlivePlayers")) do
        if strategy_call(other, "getHp") < hp then return false end
    end
    return true
end

local function r32_value_skill_lord_excludes(self, fragment)
    if not self.room:getLord() then return false end
    local lord = self.room:getLord()
    local first = lord:getGeneralName()
    if AIUnsupported.is(first) then error(first, 0) end
    if type(first) == "string" and first:find(fragment) then return false end
    if type(first) ~= "string" then
        return strategy_call(self, "useKnowledgeEstimate", {value=true,status="estimate",
            basis="unrevealed_lord_general_assumed_not_awakening_blocker",
            viewer=self.player:objectName(),target=lord:objectName(),class=fragment}, "isValueSkill.lord")
    end
    lord = self.room:getLord()
    local second = lord:getGeneral2Name()
    if AIUnsupported.is(second) then error(second, 0) end
    if second == "" then return true end
    if type(second) ~= "string" then
        return strategy_call(self, "useKnowledgeEstimate", {value=true,status="estimate",
            basis="unrevealed_lord_general_assumed_not_awakening_blocker",
            viewer=self.player:objectName(),target=lord:objectName(),class=fragment}, "isValueSkill.lord")
    end
    -- A disclosed nonempty deputy name witnesses the source getGeneral2 gate.
    return not strategy_call(self.room:getLord(), "getGeneral2Name"):find(fragment)
end

function SmartAIView:isValueSkill(skill_name,player,HighValue)
	player = player or self.player
	if string.find(sgs.bad_skills,skill_name) then return false end
	if (skill_name=="buqu" or skill_name=="nosbuqu") and strategy_known(hasBuquEffect(player), "Buqu effect") and (not HighValue or strategy_call(player, "getHp")<=1) then return true end
	if not HighValue then
		local powerful_skills = {"zhiheng","tenyearzhiheng","jijiu"}	--待补充
		if table.contains(powerful_skills,skill_name) then return true end
	end
	local skill = self.room:getPublicSkill(skill_name)
	if not skill then
        -- Definitions are projected only for skills a visible player holds.
        return false
    end
	if strategy_call(skill, "isLimitedSkill") and strategy_call(skill, "getLimitMark")~="" and strategy_call(player, "getMark", strategy_call(skill, "getLimitMark"))>0 then return true end
	if strategy_call(skill, "getFrequency")==sgs.Skill_Wake and strategy_call(player, "getMark", skill_name)==0 then
		if not HighValue then return true end
		if skill_name=="fengliang" then return true end
		if skill_name=="baiyin" and (strategy_call(player, "getMark", "&bear")>=4 or strategy_call(player, "hasSkill", "renjie")) then return true end
		if skill_name=="chuyuan" and (strategy_pile_count(player, "cychu")>=3 or strategy_call(player, "hasSkill", "chuyuan")) then return true end
		if skill_name=="tianxing" and (strategy_pile_count(player, "cychu")>=3 or strategy_call(player, "hasSkill", "chuyuan")) then return true end
		if skill_name=="baoling" and strategy_call(player, "getMark", "HengzhengUsed")>=1 then return true end
		if skill_name=="poshi" and (not strategy_call(player, "hasEquipArea") or strategy_call(player, "getHp")==1) then return true end
		if (skill_name=="hongju" or skill_name=="olhongju" or skill_name=="mobilehongju")	--暂且不管需不需要有死亡角色了
		and (strategy_pile_count(player, "rong")>=3 or strategy_call(player, "hasSkills", "zhengrong|olzhengrong|mobilezhengrong")) then return true end
		if (skill_name=="zhiji" or skill_name=="mobilezhiji" or skill_name=="olzhiji") and strategy_call(player, "isKongcheng") then return true end
		if skill_name=="mobilehunzi" and strategy_call(player, "getHp")<=2 then return true end
		if skill_name=="hunzi" and strategy_call(player, "getHp")==1 then return true end
		if skill_name=="mobilechengzhang" and strategy_call(player, "getMark", "&mobilechengzhang")+strategy_call(player, "getMark", "mobilechengzhang_num")>=7 then return true end
		if (skill_name=="zaoxian" or skill_name=="olzaoxian")
		and (strategy_pile_count(player, "field")>=3 or strategy_call(self, "hasTuntianEffect", player)) then return true end
		if (skill_name=="ruoyu" or skill_name=="olruoyu") and r32_value_skill_lowest(self, player) then return true end
		if skill_name=="nosbaijiang" and #strategy_call(player, "getEquips")>=3 then return true end
		if skill_name=="noszili" and (strategy_pile_count(player, "nospower")>=3 or strategy_call(player, "hasSkill", "nosyexin")) then return true end
		if skill_name=="zili" and (strategy_pile_count(player, "power")>=3 or strategy_call(player, "hasSkills", "quanji|mobilequanji")) then return true end
		if skill_name=="zhiri" and (strategy_pile_count(player, "burn")>=3 or strategy_call(player, "hasSkill", "fentian")) then return true end
		if skill_name=="oljixi" and strategy_call(player, "getMark", "oljixi_turn")>=2 then return true end
		if (skill_name=="wuji" or skill_name=="newwuji") and strategy_call(player, "getMark", "damage_point_round")>=3 then return true end
		if skill_name=="juyi" and strategy_call(player, "isWounded") and strategy_call(player, "getMaxHp")>strategy_call(player, "aliveCount") then return true end
		if skill_name=="choujue" and math.abs(strategy_call(player, "getHandcardNum")-strategy_call(player, "getHp"))>=3 then return true end
		if skill_name=="beishui" and (strategy_call(player, "getHandcardNum")<2 or strategy_call(player, "getHp")<2) then return true end
		if skill_name=="longyuan" and strategy_call(player, "getMark", "&yizan")>=3 then return true end
		if skill_name=="zhanyuan" and strategy_call(player, "getMark", "&zhanyuan_num")+strategy_call(player, "getMark", "zhanyuan_num")>7 then return true end
		if skill_name=="secondzhanyuan" and strategy_call(player, "getMark", "&secondzhanyuan_num")+strategy_call(player, "getMark", "secondzhanyuan_num")>7 then return true end
		if skill_name=="baijia" and strategy_call(player, "getMark", "&baijia_num")+strategy_call(player, "getMark", "baijia_num")>=7 then return true end
		if skill_name=="diaoling" and strategy_call(player, "getMark", "&mubing")+strategy_call(player, "getMark", "mubing_num")>=6 then return true end
		if skill_name=="shanli" and value_skill_tag(self, player, "BaiyiUsed") and #value_skill_tag(self, player, "Jinglve_targets", true)>=2 then return true end
		if skill_name=="zhanshen" and strategy_call(player, "isWounded") and (strategy_call(player, "getMark", "zhanshen_fight")>0 or strategy_call(player, "getMark", "@fight")>0) then return true end
		if skill_name=="qianxin" and strategy_call(player, "isWounded") then return true end
		if skill_name=="qinxue" then
			n = strategy_call(player, "getHandcardNum")-strategy_call(player, "getHp")
			if strategy_call(self.room, "getModePlayerCount")>=7 and n>=2
			or n>=3 then return true end
		end
		if skill_name=="jiehuo" and strategy_call(player, "getMark", "@shouye")>=7 then return true end
		if skill_name=="kegou" and strategy_call(player, "getKingdom")=="wu" then
			for _,p in ipairs(strategy_call(player, "getAliveSiblings"))do
				if strategy_call(p, "getKingdom")=="wu" and not r32_value_skill_role(self,p)=="lord" then return false end
			end
			return true
		end
		if skill_name=="fanxiang" then
			for _,p in ipairs(strategy_call(self.room, "getAlivePlayers"))do
				if value_skill_tag(self, p, "liangzhu_draw"..player:objectName()) and strategy_call(p, "isWounded") then return true end
			end
		end
		if skill_name=="jspdanqi" and strategy_call(player, "getHandcardNum")>strategy_call(player, "getHp") and r32_value_skill_lord_excludes(self, "liubei") then return true end
		if skill_name=="danji" and strategy_call(player, "getHandcardNum")>strategy_call(player, "getHp") and r32_value_skill_lord_excludes(self, "caocao") then return true end
		if skill_name=="jinsanchen" and (strategy_call(player, "getMark", "&jinsanchen")>=3 or strategy_call(player, "hasSkill", "jinsanchen")) then return true end
		if skill_name=="mobilezhisanchen" and (strategy_call(player, "getMark", "&mobilezhiwuku")>=3 or strategy_call(player, "hasSkill", "mobilezhiwuku")) then return true end
		if skill_name=="zongfan" and strategy_call(player, "getMark", "tunjiang_skip_play-Clear")<=0 and strategy_call(player, "getMark", "mouni-Clear")>0 then return true end
		if skill_name=="tenyearmoucheng" and strategy_call(player, "getMark", "tenyearlianji_choice_1")>0 and strategy_call(player, "getMark", "tenyearlianji_choice_2")>0 then return true end
		if skill_name=="olmoucheng" and (strategy_call(player, "getMark", "&ollianji")>=3 or strategy_call(player, "hasSkill", "ollianji")) then return true end
		if skill_name=="secondolmoucheng" and strategy_call(player, "getMark", "&ollianjidamage")>0 then return true end
		if skill_name=="mobilemoucheng" and strategy_call(player, "getMark", "&mobilelianji")>2 then return true end
	end
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

-- Legacy callbacks use nil for no opinion, false for an immediate veto, and
-- any truthy value for acceptance. Unknown projection is distinct from all three.
function SmartAIView:canDamageHp(from, card, to)
    to = to or self.player
    local function invoke(name, target)
        local hook = sgs.ai_can_damagehp[name]
        if type(hook) == "function" then
            local value = hook(self, from, card, target)
            if AIUnsupported.is(value) then error(value, 0) end
            if value then return true, true end
            if value ~= nil then return true, nil end
        end
        return false
    end
    for _, name in ipairs(strategy_call(self, "getConnections", to)) do
        local answered, value = invoke(name, to)
        if answered then return value end
    end
    -- Native source queries Yinni state before comparing owner names. Only
    -- the owner's original general skill groups may be read after that gate.
    local yinni
    local read_yinni = to.inYinniState
    if type(read_yinni) == "function" then yinni = read_yinni(to) end
    if AIUnsupported.is(yinni) then error(yinni, 0) end
    if yinni == nil and to:objectName() == self.player:objectName() then
        ai_unsupported("owner Yinni state is unknown", "canDamageHp.yinni")
    end
    if yinni and to:objectName() == self.player:objectName() then
        local row = rawget(to, "_view")
        local groups = row and row.yinni_original_skill_groups
        if type(groups) ~= "table" or groups.complete ~= true then
            ai_unsupported("owner original Yinni skill groups are unknown", "canDamageHp.yinni")
        end
        for _, group in ipairs({"general1", "general2"}) do
            local names = groups[group]
            if not AIValue.isList(names) then ai_unsupported("owner original Yinni group is invalid", "canDamageHp.yinni") end
            for _, name in ipairs(names) do
                if type(name) ~= "string" then ai_unsupported("owner original Yinni skill is invalid", "canDamageHp.yinni") end
                local answered, value = invoke(name, self.player)
                if answered then return value end
            end
        end
    end
    for _, mark in ipairs(strategy_call(to, "getMarkNames")) do
        if mark:sub(1,9) == "canDamage" and strategy_call(to, "getMark", mark) > 0 then
            if mark:sub(1,10) ~= "canDamage_"
                or from and mark:endsWith(from:objectName()) then
                return strategy_call(self, "canLoseHp", from, card, to)
            end
        end
    end
end

function SmartAIView:hasSkills(skill_names, player)
    player = player or self.player
    if type(player) == "table" and not AIValue.isPlayer(player) then
        for _, one in ipairs(player) do
            if strategy_call(one, "hasSkills", skill_names) then return one end
        end
        return nil -- Source collection branch has no explicit false return.
    end
    return strategy_call(player, "hasSkills", skill_names)
end

-- maneuvering-ai.lua:285. Preserve friend order and return a Lua list.
function SmartAIView:getChainedFriends(player)
    player = player or self.player
    local chained = {}
    for _, friend in ipairs(strategy_call(self, "getFriends", player)) do
        if strategy_call(friend, "isChained") then chained[#chained + 1] = friend end
    end
    return chained
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

-- Package compatibility adapters for Player::canPindian/canSlash, not
-- independent legality rules. Owner predicates use native snapshot capabilities;
-- foreign pairs retain the facade's explicitly marked privacy-safe estimates.
function SmartAIView:canPindian(left, right)
    if not left or type(left.canPindian) ~= "function" then return nil end
    local value = left:canPindian(right)
    if AIUnsupported.is(value) then error(value, 0) end
    if value ~= nil or right ~= nil or same_player(left, self.player) then return value end
    -- Player::canPindian(nullptr) first rejects an empty hand, then checks
    -- alive siblings in room order. The foreign facade has no private native
    -- any-target capability, so compose only its lawful pair predicates.
    local empty = left:isKongcheng()
    if empty == nil then return nil end
    if empty then return false end
    local players = self.room:getAlivePlayers()
    if players == nil then return nil end
    for _, other in ipairs(players) do
        if not same_player(left, other) then
            local possible = left:canPindian(other)
            if AIUnsupported.is(possible) then error(possible, 0) end
            if possible == nil then return nil end
            if possible then return true end
        end
    end
    return false
end

function SmartAIView:canSlash(from, to, card, distance_limit)
    from = from or self.player
    if not from or not to or type(from.canSlash) ~= "function" then return nil end
    local value = from:canSlash(to, card, distance_limit)
    if AIUnsupported.is(value) then error(value, 0) end
    return value
end

function SmartAIView:getDangerousCard(who)
    local function call(object, method, ...) return strategy_call(object, method, ...) end
    local friends = strategy_known(self.friends, "friends")
    local weapon = who:getWeapon()
    if weapon then
        if call(weapon, "isKindOf", "Crossbow") or call(weapon, "isKindOf", "GudingBlade") then
            for _, friend in ipairs(friends) do
                if call(weapon, "isKindOf", "Crossbow") and call(who, "canSlash", friend)
                    and strategy_known(getKnownCard(who, self.player, "Slash", true, "he"), "Crossbow Slash") > 0 then return call(weapon, "getEffectiveId") end
                if call(weapon, "isKindOf", "GudingBlade") and call(who, "canSlash", friend) and call(friend, "isKongcheng") then
                    local observer = self.room:getCurrent() or self.player
                    if self:useKnowledgeEstimate(self:estimateKnownCards(who, "Slash", observer, true, "he"), "getDangerousCard:GudingBlade") > 0 then return call(weapon, "getEffectiveId") end
                end
            end
        elseif call(weapon, "isKindOf", "Spear") and call(self, "hasCrossbowEffect", who) and call(who, "getHandcardNum") >= 1 then
            return call(weapon, "getEffectiveId")
        elseif call(weapon, "isKindOf", "Axe") and (call(who, "hasSkills", "luoyi|pojun|jiushi|jiuchi|jie|wenjiu|shenli|jieyuan")
            or call(self, "getOverflow", who) > 0 or call(who, "getHandcardNum") + #call(who, "getEquips") >= 4) then return call(weapon, "getEffectiveId") end
    end
    local armor = who:getArmor()
    if armor and call(armor, "isKindOf", "EightDiagram") then
        local lord = self.room:getLord()
        if lord and call(lord, "hasLordSkill", "hujia") and call(who, "getKingdom") == "wei"
            and strategy_call(self, "isFriend", lord, who) then return call(armor, "getEffectiveId") end
        for _, skill in ipairs(call(who, "getSkills")) do
            if call(skill, "inherits", "TriggerSkill") and (call(skill, "hasEvent", strategy_known(sgs.AskForRetrial, "AskForRetrial"))
                or call(skill, "hasEvent", strategy_known(sgs.FinishJudge, "FinishJudge"))) then return call(armor, "getEffectiveId") end
        end
    end
    if weapon then
        -- Donor uses singular hasSkill for this literal; do not turn it into an OR.
        if call(who, "hasSkill", "liegong|anjian") then return call(weapon, "getEffectiveId") end
        if call(weapon, "isKindOf", "SPMoonSpear") and call(who, "hasSkills", "guidao|longdan|guicai|jilve|huanshi|qingguo|kanpo") then return call(weapon, "getEffectiveId") end
        for _, friend in ipairs(friends) do
            if call(who, "distanceTo", friend) <= call(who, "getAttackRange")
                and call(who, "distanceTo", friend) > call(who, "getAttackRange", false) and call(self, "isWeak", friend) then return call(weapon, "getEffectiveId") end
        end
        for _, friend in ipairs(friends) do
            if call(who, "distanceTo", friend) <= call(who, "getAttackRange")
                and call(who, "distanceTo", friend) > call(who, "getAttackRange", false) then return call(weapon, "getEffectiveId") end
        end
    end
    return false
end

function SmartAIView:getValuableCard(who)
    local function call(object, method, ...) return strategy_call(object, method, ...) end
    local weapon, offhorse = who:getWeapon(), who:getOffensiveHorse()
    local sorted = call(self, "sort", strategy_known(self.friends, "friends"), "hp")
    -- Isolated sort returns a copy; the source mutates self.friends.
    for i, player in ipairs(sorted) do self.friends[i] = player end
    local friend = self.friends[1]
    if friend and call(self, "isWeak", friend) and call(who, "distanceTo", friend) <= call(who, "getAttackRange", false) then
        if weapon and call(who, "distanceTo", friend) > 1 then return call(weapon, "getEffectiveId") end
        if offhorse and call(who, "distanceTo", friend) > 1 then return call(offhorse, "getEffectiveId") end
    end
    local defhorse = who:getDefensiveHorse()
    if defhorse and call(self.player, "distanceTo", who) == 2 then return call(defhorse, "getEffectiveId") end
    if weapon and (call(weapon, "isKindOf", "MoonSpear") and call(who, "hasSkill", "keji") and call(who, "getHandcardNum") > 5
        or call(who, "hasSkills", "qiangxi|zhulou|taichen")) then return call(weapon, "getEffectiveId") end
    for _, equip in ipairs(call(who, "getEquips")) do
        if call(who, "getHp") <= 2 and call(who, "hasSkill", "baobian") then return call(equip, "getEffectiveId") end
        if call(equip, "getSuit") ~= strategy_known(sgs.Card_Diamond, "Diamond") and call(who, "hasSkill", "longhun") then return call(equip, "getEffectiveId") end
        if call(equip, "isRed") and call(who, "hasSkills", "wusheng|jijiu|xueji|nosfuhun") then return call(equip, "getEffectiveId") end
        if call(equip, "isBlack") and call(who, "hasSkills", "qixi|duanliang|yinling|guidao") then return call(equip, "getEffectiveId") end
        if call(equip, "getSuit") == sgs.Card_Diamond and call(who, "hasSkills", "guose|yanxiao") then return call(equip, "getEffectiveId") end
        if call(who, "hasSkills", strategy_known(sgs.need_equip_skill, "need_equip_skill"))
            and not call(who, "hasSkills", strategy_known(sgs.lose_equip_skill, "lose_equip_skill")) then return call(equip, "getEffectiveId") end
    end
    local armor = who:getArmor()
    if armor and call(self, "evaluateArmor", armor, who) > 3 and not call(self, "needToThrowArmor", who) then return call(armor, "getEffectiveId") end
    if offhorse and call(who, "hasSkills", "nosqianxi|kuanggu|duanbing|qianxi") then return call(offhorse, "getEffectiveId") end
    if defhorse and strategy_known(getKnownCard(who, self.player, "Jink", true, "he"), "valuable Jink") < 1
        and not (call(self.player, "hasWeapon", "kylin_bow") and call(self.player, "canSlash", who)
            and call(self, "slashIsEffective", self:classProbe("Slash"), who, self.player)) then return call(defhorse, "getEffectiveId") end
    if armor and not call(self, "needToThrowArmor", who) then return call(armor, "getEffectiveId") end
    if offhorse and call(who, "getHandcardNum") > 1 then
        for _, other in ipairs(self.friends) do
            if call(who, "distanceTo", other) == call(who, "getAttackRange") and call(who, "getAttackRange") > 1 then return call(offhorse, "getEffectiveId") end
        end
    end
    if weapon and call(who, "getHandcardNum") > 1 then
        for _, other in ipairs(self.friends) do
            if call(who, "distanceTo", other) <= call(who, "getAttackRange") and call(who, "distanceTo", other) > 1 then return call(weapon, "getEffectiveId") end
        end
    end
    local treasure = who:getTreasure()
    if treasure and call(treasure, "isKindOf", "WoodenOx") and call(who, "getPileCount", "wooden_ox") > 1 then return call(treasure, "getEffectiveId") end
    return false
end

-- 鐵索傳導：友方損失大於敵方才值得。普通傷害只看當前目標；屬性傷害才掃其他橫置角色。
function SmartAIView:isGoodChainTarget(who, nature_card, source, damagecount)
    source = source or self.player
    if strategy_call(self, "hasJueqingEffect", source, who) then
        return not strategy_call(self, "isFriend", who)
    end
    local card = type(nature_card) == "table" and type(nature_card.isKindOf) == "function" and nature_card or nil
    -- The donor explicitly chooses N for a card input, even a NatureSlash.
    -- String T/F/N must reach ajustDamage unchanged; nil uses its own default.
    local nature = card and "N" or nature_card
    damagecount = strategy_call(self, "ajustDamage", source, who, damagecount, card, nature)
    if damagecount < 1 then return false end
    local kills, good, bad, killlord, weak_enemy = 0, 0, 0, false, nil
    local function value(target)
        local result = -damagecount
        if strategy_call(self, "isGoodChainPartner", target) then result = result + 2 end
        if strategy_call(self, "isWeak", target) then result = result - 1 end
        if strategy_call(self, "cantbeHurt", target, source, damagecount) then result = result - 10 end
        if damagecount >= strategy_call(target, "getHp") then
            result = result - 4
            if strategy_call(target, "isLord") then killlord, result = true, result - 5 end
            if strategy_call(self, "isEnemy", target) then kills = kills + 1 end
        else
            if strategy_call(self, "isEnemy", target, source)
                and strategy_call(target, "hasSkills", "ganglie|neoganglie")
                and strategy_call(source, "getHandcardNum") + strategy_call(source, "getHp")
                    + strategy_known(getKnownCard(source, self.player, "Peach", true, "he"), "Peach estimate") < 3 then
                result = result + 3
            end
            if strategy_call(target, "hasSkill", "vsganglie") then
                for _, enemy in ipairs(strategy_call(self, "getEnemies", target)) do
                    if strategy_call(enemy, "getHp") + strategy_known(getKnownCard(enemy, self.player, "Peach", true, "he"), "Peach estimate")
                        + strategy_call(enemy, "getHandcardNum") < 3
                        and strategy_call(self, "damageIsEffective", enemy, nil, target) then
                        result = result + 3
                        if strategy_call(enemy, "isLord") then result, killlord = result + 5, true end
                    end
                end
            end
        end
        return result
    end
    local friends, enemies = 0, 0
    if strategy_call(self,"isFriend",who) then friends, good = 1, value(who)
    elseif strategy_call(self,"isEnemy",who) then enemies, bad = 1, value(who) end
    if nature == "N" then return bad ~= 0 and good > bad end
    for _, target in ipairs(strategy_call(self.room, "getOtherPlayers", who)) do
        if strategy_call(target, "isChained")
            and strategy_call(self, "ajustDamage", source, target, damagecount, card, nature) > 0 then
            if strategy_call(self,"isFriend",target) then friends, good = friends + 1, good + value(target)
            elseif strategy_call(self,"isEnemy",target) then
                enemies, bad = enemies + 1, bad + value(target)
                if strategy_call(target, "isKongcheng") and strategy_call(target, "getHp") < 2 then weak_enemy = target end
            end
            if killlord then
                local lord = self.room:getLord()
                if not lord then ai_unsupported("chain kill-lord reference is unknown", "isGoodChainTarget") end
                if strategy_call(self,"isFriend",lord) then
                    if strategy_call(self, "getCardsNum", "Peach") < 1 then return false end
                elseif strategy_call(self,"isEnemy",lord) then
                    if card then self:setStrategyCardFlag(card, "AIGlobal_KillOff", true) end
                    local world = self.world or rawget(self.room, "_world")
                    local hegemony = type(world) == "table" and world.enable_hegemony
                    if hegemony == nil then ai_unsupported("hegemony config is unknown", "isGoodChainTarget") end
                    if not hegemony or strategy_call(self, "getDefenseSlash", target) < 2 then return true end
                end
                killlord = false
            else
                local all_enemies = self.enemies or strategy_call(self, "getEnemies")
                if kills >= #all_enemies then
                    if card then self:setStrategyCardFlag(card, "AIGlobal_KillOff", true) end
                    return true
                end
            end
        end
    end
    if card and weak_enemy then
        for _, slash in ipairs(strategy_call(self, "getCards", "Slash")) do
            if not (strategy_call(slash, "isKindOf", "NatureSlash")
                or strategy_call(self, "slashProhibit", slash, weak_enemy, source)) then return false end
        end
    end
    return enemies > 0 and enemies >= friends and good > bad
end

-- 無實體殺時選額外目標。不造 dummy 牌；合法性仍交給 prohibit／effective。
function SmartAIView:zeroCardSlashTarget(targets)
    -- AI_ExtraTargetSlash has no writer, so SmartAI always uses a fresh Slash.
    local slash = self:classProbe("Slash")
    slash = strategy_known(slash, "extra-target Slash descriptor")
	local targetlist = AIList.new(targets)
	--add
	local function finalChecking(player)
		local use = {isDummy = true, extra_target = 0, current_targets = {}, to = AIList.new({})}
		use.card = self:classProbe("Slash")
		use.to:append(player)
		self:targetRevises(use)
		if use.card and not use.isDummy then
			return player
		end
		return false
	end


	local arrBestHp,canAvoidSlash,forbidden = {},{},{}
	targetlist = strategy_call(self, "sort", targetlist, "defenseSlash")
	for _,target in ipairs(targetlist)do
		if strategy_call(self, "isEnemy", target)
		and not strategy_call(self, "slashProhibit", slash,target)
		and strategy_call(self, "isGoodTarget", target,targetlist,slash) then
			if strategy_call(self, "slashIsEffective", slash,target) then
				if strategy_call(self, "needToLoseHp", target,self.player,slash)
				or self:needLeiji(target,self.player)
				then table.insert(forbidden,target)
				elseif strategy_call(self, "needToLoseHp", target,self.player,slash,true)
				then table.insert(arrBestHp,target)
				else if finalChecking(target) then return target end end
			else
				table.insert(canAvoidSlash,target)
			end
		end
	end
	local reverse = {}
    for index = #targetlist, 1, -1 do reverse[#reverse+1] = targetlist[index] end
    targetlist = reverse
	for _,target in ipairs(targetlist)do
		if not strategy_call(self, "slashProhibit", slash,target) then
			if strategy_call(self, "slashIsEffective", slash,target) then
				if strategy_call(self, "isFriend", target)
				and (strategy_call(self, "needToLoseHp", target,self.player,slash,true) or self:needLeiji(target,self.player))
				then if finalChecking(target) then return target end end
			else
				table.insert(canAvoidSlash,target)
			end
		end
	end
	if #canAvoidSlash>0 then return canAvoidSlash[1] end
	if #arrBestHp>0 then if finalChecking(arrBestHp[1]) then return arrBestHp[1] end end
	for _,target in ipairs(targetlist)do
		if target:objectName()~=self.player:objectName()
		and not strategy_call(self, "isFriend", target) and not table.contains(forbidden,target)
		then if finalChecking(target) then return target end end
	end
	return targetlist[1] or false
end

-- Replace SmartAIView:getConnections with this block. Also supplies the exact
-- admitted-room counterpart of sgs.getCachedAlivePlayers (smart-ai457).
do
local function q(object, method, ...)
    local fn = object and object[method]
    if type(fn)~='function' then ai_unsupported('connection getter unavailable',method) end
    local value=fn(object,...)
    if AIUnsupported.is(value)then error(value,0)end
    if value==nil then ai_unsupported('connection getter unknown',method) end
    return value
end
local function copy(value)
    if type(value)~='table' then return value end
    local out={};for k,v in pairs(value)do out[k]=copy(v)end;return out
end
local function replay(self, entries)
    for _,row in ipairs(entries or{})do
        local e=copy(row);e.status='estimate';e.value=e.value==nil and true or e.value
        self:useKnowledgeEstimate(e,row.context or 'aiConnect.cache')
    end
end
local function cache(self,stamp)
    -- Read a real native stamp even on a hit. Natural recordEvent and the
    -- donor's second Death clear advance the reset epoch; distinct questions
    -- and revisions also keep these value caches from crossing snapshots.
    stamp=stamp or snapshot_cache_stamp(self.room,'observer_epoch')
    local live=rawget(self,'_legacy_connection_cache')
    if same_snapshot_cache(live,stamp)then return live end
    local state,known=self:getStrategyMemory('observer_connections')
    if known and type(state)=='table'and same_snapshot_cache(state,stamp)then
        if type(state.by_player)~='table'then ai_unsupported('connection cache malformed','aiConnect')end
        state=copy(state)
    else
        state={scope=stamp.scope,epoch=stamp.epoch,viewer=stamp.viewer,question=stamp.question,
            revision=stamp.revision,by_player={}}
    end
    self._legacy_connection_cache=state
    self._legacy_connection_views={by_player={}}
    return state
end
local function save(self,state)
    self:setStrategyMemory('observer_connections',state)
end
local function estimates(self, before)
    local log=self.request and self.request.scratch and self.request.scratch.knowledge_estimates or{}
    if before==nil then return copy(log)end
    local added={}
    for i,row in ipairs(log)do
        local old=before[i]
        -- The shared logger coalesces matching rows by increasing count.
        if not old or (row.count or 1)~=(old.count or 1) then
            local entry=copy(row);entry.count=nil;added[#added+1]=entry
        end
    end
    return added
end
function SmartAIView:getCachedAlivePlayers()
    local stamp=snapshot_cache_stamp(self.room,"source_alive")
    local state=cache(self,stamp)
    local views=rawget(self,'_legacy_connection_views')
    if views.alive then return views.alive end
    local names=state.alive
    local result={}
    if names~=nil then
        if not AIValue.isList(names)then ai_unsupported('alive cache malformed','qlist_cached')end
        for _,name in ipairs(names)do
            if type(name)~='string'then ai_unsupported('alive cache identity malformed','qlist_cached')end
            local player=self.room:findPlayerByObjectName(name,true)
            if not player then ai_unsupported('cached alive player unavailable','qlist_cached')end
            result[#result+1]=player
        end
    else
        names={}
        for _,player in sgs.qlist(q(self.room,'getAlivePlayers'))do
            names[#names+1]=q(player,'objectName');result[#result+1]=player
        end
        state.alive=names;save(self,state)
    end
    views.alive=result
    return result
end
function SmartAIView:getConnections(player)
    player=player or self.player
    local stamp=snapshot_cache_stamp(self.room,"source_connections",player)
    local name=q(player,'objectName')
    local state=cache(self,stamp)
    local row=state.by_player[name]
    local views=rawget(self,'_legacy_connection_views')
    if row~=nil then
        if type(row)~='table'or not AIValue.isList(row.names)then ai_unsupported('connection cache entry malformed','aiConnect')end
        for _,v in ipairs(row.names)do if type(v)~='string'then ai_unsupported('connection name malformed','aiConnect')end end
        replay(self,row.estimates)
        if not views.by_player[name]then views.by_player[name]=copy(row.names)end
        return views.by_player[name]
    end
    local before=estimates(self)
    local names,seen={},{}
    local function append(value)
        if type(value)~='string'then ai_unsupported('connection name unknown','aiConnect')end
        if not seen[value]then names[#names+1]=value;seen[value]=true end
    end
    for _,skill in sgs.qlist(q(player,'getVisibleSkillList',true))do
        local sn=q(skill,'objectName');append(sn)
        if q(skill,'inherits','ViewAsEquipSkill')then
            local virtual=skill:getViewAsEquipNames()
            if virtual==nil and name~=q(self.player,'objectName')then
                self:useKnowledgeEstimate({status='estimate',value=false,basis='unprojected_virtual_equipment_excluded',viewer=self.player:objectName(),observer=name},'getConnections:virtual_equipment')
            else
                if not AIValue.isList(virtual)then ai_unsupported('virtual equipment names unavailable','aiConnect')end
                for _,en in ipairs(virtual)do append(en)end
            end
        end
    end
    if name~=q(self.player,'objectName')then
        self:useKnowledgeEstimate({status='estimate',value=true,basis='public_connections_only_private_marks_excluded',viewer=self.player:objectName(),observer=name},'getConnections')
    end
    for _,mark in ipairs(q(player,'getMarkNames'))do
        local value
        if type(player.getStrategyMark)=='function'then value=player:getStrategyMark(mark)else value=player:getMark(mark)end
        if value==nil then ai_unsupported('connection mark value unknown','aiConnect')end
        if value>0 and(mark:find('&',1,true)or mark:find('@',1,true))then
            local plus=mark:find('+',1,true)
            append(plus and mark:sub(1,plus-1)or mark)
        end
    end
    for _,pile in ipairs(q(player,'getPileNames'))do
        if pile:sub(1,1)~='#'and q(player,'getPileCount',pile)>0 then append(pile)end
    end
    for _,equip in sgs.qlist(q(player,'getEquips'))do append(q(equip,'objectName'))end
    state.by_player[name]={names=copy(names),estimates=estimates(self,before)}
    views.by_player[name]=names;save(self,state)
    return names
end
end

function SmartAIView:playerGetRound(player, source)
    if not player then ai_unsupported("round target is absent", "playerGetRound") end
    source = source or self.room:getCurrent()
    if not source then ai_unsupported("round source is absent", "playerGetRound") end
    if same_player(player, source) then return 0 end
    local players = strategy_call(self.room, "getAlivePlayers")
    if #players == 0 then ai_unsupported("alive roster is empty", "playerGetRound") end
    return (strategy_call(player, "getSeat") - strategy_call(source, "getSeat")) % #players
end

function SmartAIView:GetAskForPeachActionOrderSeat(player)
    player = player or self.player
    local current = self.room:getCurrent()
    if not current then ai_unsupported("rescue current player is unknown", "GetAskForPeachActionOrderSeat") end
    local alive, seated = strategy_call(self.room, "getAlivePlayers"), {}
    for _, other in ipairs(alive) do
        seated[#seated + 1] = {player = other, seat = strategy_call(other, "getSeat")}
    end
    table.sort(seated, function(a,b) return a.seat < b.seat end)
    local start
    for i, row in ipairs(seated) do if same_player(row.player, current) then start = i break end end
    if not start then ai_unsupported("current player is outside the alive roster", "GetAskForPeachActionOrderSeat") end
    for offset = 0, #seated - 1 do
        if same_player(seated[(start + offset - 1) % #seated + 1].player, player) then return offset + 1 end
    end
    return -1
end

local function revenge_targets(self, mark)
    local result, maximum = {}, 0
    for _, player in ipairs(strategy_call(self.room, "getAlivePlayers")) do
        local count = strategy_mark(self, player, mark)
        if count > maximum then result, maximum = {player}, count
        elseif count == maximum and maximum > 0 then result[#result + 1] = player end
    end
    return AIList.new(result)
end
function SmartAIView:getWuhunRevengeTargets(to)
    return revenge_targets(self, "&nightmare+#" .. strategy_call(to, "objectName"))
end
function SmartAIView:getSpWuhunRevengeTargets()
    return revenge_targets(self, "@spnightmare")
end

function SmartAIView:needDeath(player)
    player = player or self.player
    for _, entry in ipairs({{"wuhun", "&nightmare+#" .. strategy_call(player, "objectName")},
        {"spwuhun", "@spnightmare"}, {"sgkgodsuohun", "&sk_soul"}}) do
        if strategy_call(player, "hasSkill", entry[1]) and #strategy_call(self, "getFriends", player, true) > 0 then
            -- Preserve the donor's return INSIDE the first alive-player iteration.
            for _, other in ipairs(strategy_call(self.room, "getAlivePlayers")) do
                local mark = strategy_mark(self, other, entry[2])
                local friend = strategy_call(self,"isFriend",player,other) and not same_player(player, other) and mark or 0
                local enemy = strategy_call(self,"isEnemy",player,other) and mark or 0
                return not (friend > enemy or enemy < 1)
            end
        end
    end
    if strategy_mark(self, player, "&mobilezhixi") > 0 and strategy_call(player, "getCardCount") < 2 then
        for _, other in ipairs(strategy_call(self.room, "getAlivePlayers")) do
            if strategy_call(other, "hasSkill", "mobilezhishanxi") then return true end
        end
    end
    if same_player(player, self.player) and strategy_call(player, "hasSkill", "fengliao")
        and strategy_call(player, "getChangeSkillState", "fengliao") == 2 then return true end
    return strategy_mark(self, player, "&ov_xijun+no_recover-Clear") > 0
        or strategy_mark(self, player, "&keolranji_ban") > 0
end

function SmartAIView:doNotSave(player)
    for _, entry in ipairs({{"niepan", "@nirvana"}, {"fuli", "@laoji"}}) do
        if strategy_call(player, "hasSkill", entry[1]) and strategy_mark(self, player, entry[2]) > 0
            and #strategy_call(player, "getEquips") < 2 then return true end
    end
    return strategy_call(player, "hasFlag", "AI_doNotSave")
end

function SmartAIView:ableToSave(saver, dying)
    local current = self.room:getCurrent()
    -- Re-read the saver exception at each source occurrence. In particular the
    -- first lookup is after the current-player and Wansha short-circuit gates.
    local function exception()
        return strategy_call(saver, "hasSkills", "jiuzhu|chunlao|tenyearchunlao|secondtenyearchunlao|nosjiefan|renxin")
    end
    local function blocked_current()
        return current and not same_player(current, saver)
            and not (AIValue.isPlayer(dying) and same_player(current, dying))
    end
    if blocked_current() and strategy_call(current, "hasSkill", "wansha") and not exception() then return false end
    if not exception() and strategy_call(saver, "isCardLimited", self:classProbe("Peach"), sgs.Card_MethodUse) then return false end
    -- Deliberately retain the donor's nil-dying ordinary error and repeated
    -- dying.who reads; do not convert malformed source input into success.
    if dying.who and strategy_mark(self, dying.who, "@zhou") > 0 then return false end
    if dying.who and strategy_mark(self, dying.who, "@fatebimie") > 0 then return false end
    if dying.who and strategy_mark(self, dying.who, "@TH_HeartBreak") > 0 then return false end
    if blocked_current() and strategy_call(current, "hasSkill", "sfofl_longmu") and not exception() then return false end
    return true
end

function SmartAIView:hasHuangenEffect(targets)
    for _, owner in ipairs(strategy_call(self.room, "findPlayersBySkillName", "huangen")) do
        local friends = strategy_call(self, "getFriends", owner)
        if math.min(strategy_call(owner, "getHp"), #friends) > 0 then
            targets = targets or self.player
            if type(targets) ~= "table" or AIValue.isPlayer(targets) then targets = {targets} end
            for _, target in ipairs(targets) do
                if table.contains(friends, target) then return owner end
            end
        end
    end
end
function SmartAIView:aoeIsEffective(card, to, source)
    local owner = self:hasHuangenEffect(to)
    if AIUnsupported.is(owner) then error(owner, 0) end
    if owner then return end
    local result = self:hasTrickEffective(card, to, source)
    if AIUnsupported.is(result) then error(result, 0) end
    return result
end
function SmartAIView:canAvoidAOE(card)
    local effective = self:aoeIsEffective(card, self.player)
    if AIUnsupported.is(effective) then error(effective, 0) end
    if not effective or strategy_call(card, "isKindOf", "SavageAssault") and strategy_call(self, "getCardsNum", "Slash") > 0 then return true end
    if strategy_call(card, "isKindOf", "ArcheryAttack") then
        if strategy_call(self, "getCardsNum", "Jink") > 0
            or strategy_call(self.player, "getHp") > 1 and strategy_call(self.player, "hasArmorEffect", "EightDiagram") then return true end
    end
end

function hasChainEffect(to, from)
    if strategy_call(to, "isChained") then return true end
    if strategy_call(to, "hasSkill", "qianjie") then return false end
    return from ~= nil and strategy_call(from, "hasWeapon", "wutiesuolian") or false
end
function SmartAIView:hasWulingEffect(element)
    if element:sub(1, 1) ~= "@" then element = "@" .. element end
    for _, player in ipairs(strategy_call(self.room, "getAlivePlayers")) do
        if strategy_call(player, "hasSkill", "wuling") and strategy_mark(self, player, element) > 0 then return true end
    end
    return false
end

local function strategy_card_key(card)
    if AIValue.isConversion(card) then return "conversion:" .. strategy_call(card, "getConversionId") end
    local id = strategy_call(card, "getEffectiveId")
    if type(id) ~= "number" then ai_unsupported("card has no strategy identity", "card_flag") end
    if id < 0 then
        local row = rawget(card, "_view")
        if type(row) ~= "table" or row.evaluation_only ~= true then ai_unsupported("negative card is not an evaluation descriptor", "card_flag") end
        return "evaluation:" .. id .. ":" .. strategy_call(card, "objectName")
    end
    return "card:" .. id
end
function SmartAIView:setStrategyCardFlag(card, flag, enabled)
    if type(flag) ~= "string" or type(enabled) ~= "boolean" then ai_unsupported("invalid strategy flag", "card_flag") end
    local key = strategy_card_key(card)
    self.request.scratch = self.request.scratch or {}
    local flags = self.request.scratch.card_flags or {}
    self.request.scratch.card_flags = flags
    flags[key] = flags[key] or {}
    flags[key][flag] = enabled
end
function SmartAIView:hasStrategyCardFlag(card, flag)
    local scratch = self.request and self.request.scratch
    if scratch and scratch.card_flags then
        local row = scratch.card_flags[strategy_card_key(card)]
        if row and row[flag] ~= nil then return row[flag] end
    end
    return strategy_call(card, "hasFlag", flag)
end

-- Armor-policy knowledge only. Keep the raw CardView:hasFlag ABI unknown for
-- undisclosed flags; a public face is not proof of private AI modifiers.
function SmartAIView:cardFlagKnowledge(card, flag, context)
    context = context or "card.armor_flag"
    if flag ~= "Qinggang" and flag ~= "SlashIgnoreArmor" then
        ai_unsupported("card flag is outside audited armor-policy knowledge", context)
    end
    if not card or type(card.hasFlag) ~= "function" then
        ai_unsupported("card flag query is unavailable", context)
    end
    local scratch = self.request and self.request.scratch
    if scratch and scratch.card_flags then
        local id = type(card.getEffectiveId) == "function" and card:getEffectiveId()
        if AIValue.isConversion(card) or type(id) == "number" then
            local row = scratch.card_flags[strategy_card_key(card)]
            if row and type(row[flag]) == "boolean" then return row[flag], "exact" end
        end
    end
    local value = card:hasFlag(flag)
    if type(value) == "boolean" then return value, "exact" end
    local view = type(card) == "table" and rawget(card, "_view")
    -- This explicit native marker identifies a sanitized public descriptor,
    -- whose private predecessor/owner evaluation state was intentionally not
    -- granted. Absent owner metadata must not enter this estimate path.
    if (not AIValue.isCard(card) and not AIValue.isConversion(card))
        or type(view) ~= "table" or view.skill_names_complete ~= false
        or type(view.name) ~= "string" then
        ai_unsupported("owner or unspecified card flag knowledge is absent", context)
    end
    return self:useKnowledgeEstimate({value = false, status = "estimate",
        basis = "unobserved_public_card_armor_modifier_inactive_prior",
        viewer = self.player:objectName(), observer = self.player:objectName(),
        flag = flag, card_name = view.name, card_id = card:getEffectiveId()}, context)
end

function SmartAIView:canNiepan(player)
    player = player or self.player
    for _, entry in ipairs({{"niepan", "@nirvana"}, {"mobileniepan", "@mobileniepanMark"},
        {"olniepan", "@olniepanMark"}, {"mouniepan", "@mouniepan"}, {"mouzhiba", "@mouzhiba"},
        {"mouzhibas", "@mouzhibas"}, {"fuli", "@laoji"}}) do
        if strategy_call(player, "hasSkill", entry[1]) and strategy_mark(self, player, entry[2]) > 0 then return true end
    end
    for _,name in ipairs(strategy_call(self,"getConnections",player))do
        local callback=sgs.ai_canNiepan_skill[name]
        if type(callback)=="function" then
            local result=callback(player)
            if AIUnsupported.is(result) then error(result,0) end
            if result then return true end
        end
    end
    return false
end

function SmartAIView:canUseJieyuanDecrease(damage_from, player)
    if not damage_from then return false end
    player = player or self.player
    if not strategy_call(player, "hasSkill", "jieyuan")
        or strategy_call(damage_from, "getHp") < strategy_call(player, "getHp") then return false end
    local cards
    if same_player(player, self.player) then cards = strategy_call(player, "getHandcards")
    else
        local current = self.room:getCurrent()
        cards = strategy_call(player, "getKnownCards")
        if not current or not same_player(current, self.player) then
            self:useKnowledgeEstimate({value = #cards, status = "estimate", basis = "observer_substitution_visible_red_costs",
                viewer = self.player:objectName(), observer = current and current:objectName() or "unknown"}, "canUseJieyuanDecrease")
        end
    end
    for _, card in ipairs(cards) do
        if strategy_call(card, "isRed") and not isCard("Peach", card, player) then return true end
    end
    return false
end

function SmartAIView:findFriendsByType(prompt,player)
	player = player or self.player
	local friends = strategy_call(self, "getFriends", player,true)
	if #friends<1 then return false end
	if prompt==sgs.Friend_Draw then
		for _,friend in ipairs(friends)do
			if not strategy_call(friend, "hasSkill", "manjuan") and not strategy_call(self, "needKongcheng", friend,true) then return true end
		end
	elseif prompt==sgs.Friend_Male then
		for _,friend in ipairs(friends)do
			if strategy_call(friend, "isMale") then return true end
		end
	elseif prompt==sgs.Friend_MaleWounded then
		for _,friend in ipairs(friends)do
			if strategy_call(friend, "isMale") and strategy_call(friend, "isWounded") then return true end
		end
	elseif prompt==sgs.Friend_Weak then
		for _,friend in ipairs(friends)do
			if strategy_call(self, "isWeak", friend) then return true end
		end
	end
	return prompt==sgs.Friend_All
end
function SmartAIView:getJiemingChaofeng(player)
    local maximum = 0
    for _, friend in ipairs(strategy_call(self, "getFriends", player)) do
        maximum = math.max(maximum, math.min(strategy_call(friend, "getMaxHp"), 5) - strategy_call(friend, "getHandcardNum"))
    end
    return maximum < 2 and 5 - maximum * 2 or -maximum * 2
end
function SmartAIView:compareRoleEvaluation(player, first, second)
    if strategy_call(player, "isLord") then return "loyalist" end
    if strategy_call(self, "isRolePredictable") then return strategy_call(player, "getRole") end
    local role = strategy_call(self, "getRoleEstimate", player)
    if (first == "renegade" or second == "renegade") and role == "renegade" then return "renegade" end
    if role == second then return second end
    if role == first then return first end
    return "neutral"
end
function SmartAIView:isLordInDanger()
    local lord = self.room:getLord()
    if not lord then return false end
    local hp = strategy_call(lord, "getHp")
    if hp > 4 and strategy_call(lord, "hasSkill", "benghuai") then hp = 4 end
    return hp < 3
end

function SmartAIView:hasQiuyuanEffect(from, to)
    from = from or self.player
    if not to then return false end
    if strategy_call(to, "hasSkill", "nosqiuyuan") then
        local jinks = self:useKnowledgeEstimate(self:estimateKnownCards(to, "Jink", from, true, "he"), "hasQiuyuanEffect:Jink")
        for _, target in ipairs(strategy_call(self, "getEnemies", to)) do
            if not (strategy_call(target, "getHandcardNum") == 1 and strategy_call(self, "needKongcheng", target, true))
                and not same_player(from, target) and strategy_call(target, "getHandcardNum") > 0 then return true end
        end
        if jinks > 0 then
            for _, friend in ipairs(strategy_call(self, "getFriends", to)) do
                if strategy_call(friend, "getHandcardNum") == 1 and strategy_call(self, "needKongcheng", friend, true) then
                    local usable = not same_player(from, friend)
                    self:useKnowledgeEstimate({value = usable, status = "estimate", difference_kind = "donor_error_repair",
                        basis = "donor_error_repair:nosqiuyuan_undefined_target_replaced_with_current_friend",
                        viewer = self.player:objectName(), target = friend:objectName()}, "hasQiuyuanEffect")
                    if usable then return true end
                end
            end
        end
    end
    if strategy_call(to, "hasSkill", "qiuyuan") then
        for _, target in ipairs(strategy_call(self, "getEnemies", to)) do
            if strategy_call(self, "isFriend", target) and not same_player(from, target)
                and (not (strategy_call(target, "getHandcardNum") == 1 and strategy_call(self, "needKongcheng", target, true))
                    or strategy_call(self, "isWeak", target)) then return true end
        end
    end
    return false
end

function SmartAIView:isPriorFriendOfSlash(friend, card, source)
    source = source or self.player
    if strategy_call(card, "isKindOf", "NatureSlash") and hasChainEffect(friend, source)
        and strategy_call(self, "isGoodChainTarget", friend, card, source) then return true end
    local leiji = false
    if strategy_call(friend, "isWounded") then leiji = strategy_call(self, "findLeijiTarget", friend, 50, source, 1) end
    if not leiji then leiji = strategy_call(self, "findLeijiTarget", friend, 50, source, -1) end
    local benefit = leiji
    if not benefit and strategy_call(friend, "isLord") and strategy_call(source, "hasSkill", "guagu")
        and strategy_call(friend, "getLostHp") >= 1
        and self:useKnowledgeEstimate(self:estimateKnownCards(friend, "Jink", source, true, "he"), "isPriorFriendOfSlash:Guagu") < 1 then benefit = true end
    if not benefit and strategy_call(friend, "hasSkill", "jieming") and strategy_call(source, "hasSkill", "nosrende")
        and strategy_call(self, "hasSkills", "jijiu", strategy_known(self.friends, "friends")) then benefit = true end
    if not benefit and strategy_call(friend, "hasSkill", "hunzi") and strategy_call(friend, "getHp") == 2
        and strategy_call(self, "needToLoseHp", friend, source, card) then benefit = true end
    if benefit and strategy_call(card, "getSkillName") ~= "lihuo"
        and strategy_call(self, "ajustDamage", source, friend, 1, card) == 1 then return true end
    return self:hasQiuyuanEffect(source, friend)
end


-- Remaining common selection helpers preserve donor traversal and sorting
-- side effects. Isolated sort returns a copy, so write that order back here.
local function common_sort_in_place(self, players, key, reverse)
    local sorted = strategy_known(self:sort(players, key, reverse), "common helper sort")
    for i, player in ipairs(sorted) do players[i] = player end
    return players
end

function SmartAIView:getPriorTarget()
    if #strategy_known(self.enemies, "enemies") < 1 then return nil end
    local result = self:sort(self.enemies)
    if AIUnsupported and AIUnsupported.is(result) then error(result, 0) end
    -- Source ignores sort's ordinary return and observes its original array.
    return self.enemies[1]
end

function SmartAIView:needToThrowLastHandcard(player, handnum)
    player, handnum = player or self.player, handnum or 1
    if strategy_call(player, "getHandcardNum") > handnum then return false end
    if strategy_call(player, "hasSkill", "kongcheng") then return true end
    for _, name in ipairs({"zhiji", "mobilezhiji", "olzhiji"}) do
        if strategy_call(player, "hasSkill", name) and strategy_call(player, "getMark", name) < 1 then return true end
    end
    return false
end

function SmartAIView:hasSkill(skill)
    if AIValue.isSkill(skill) then skill = skill:objectName()
    elseif type(skill) == "table" then skill = skill.name
    elseif type(skill) ~= "string" then skill = skill:objectName() end
    -- getSkill's null result is meaningful only with the public complete
    -- registered-definition catalogue, never from absent owner membership.
    if type(skill) ~= "string" then error("source getSkill expects a string skill name", 0) end
    local definition = self.room:getPublicSkill(skill)
    if definition and strategy_call(definition, "isLordSkill") then return strategy_call(self.player, "hasLordSkill", skill) end
    return strategy_call(self.player, "hasSkill", skill)
end

function SmartAIView:exclude(players, card, from)
    local result = AIList.asLuaTable(AIList.new({}))
    for _, player in ipairs(players) do
        if strategy_call(from or self.player, "canUse", card, player) then result[#result + 1] = player end
    end
    return result
end

function SmartAIView:keepWoodenOx(player, flags)
    player, flags = player or self.player, flags or "e"
    if not strategy_call(player, "hasTreasure", "wooden_ox") or strategy_pile_count(player, "wooden_ox") < 1 then return false end
    -- The donor asks only for cardinality. Public hand counts avoid reading a
    -- foreign full hand merely to reconstruct getCards(flags):length().
    local count = 0
    if flags:find("h", 1, true) then count = count + strategy_call(player, "getHandcardNum") end
    if flags:find("e", 1, true) then count = count + #strategy_call(player, "getEquips") end
    if flags:find("j", 1, true) then count = count + #strategy_call(player, "getJudgingArea") end
    return count == 1
end

function SmartAIView:hasZhenguEffect(to, from)
    if not to or not strategy_call(to, "hasSkill", "zhengu") then return false end
    if strategy_call(to, "getHp") < 2 and strategy_call(to, "getHandcardNum") < 2 and strategy_call(self, "isWeak", to) then return false end
    for _, player in ipairs(strategy_call(self.room, "getAlivePlayers")) do
        if strategy_call(player, "getMark", "&zhengu") > 0
            and strategy_call(self, "isEnemy", player, from or self.player)
            and not strategy_call(self, "needKongcheng", player, true) then return true end
    end
    return false
end

function SmartAIView:hasZhaxiangEffect(player)
    return strategy_call(player, "hasSkill", "zhaxiang") or strategy_call(player, "hasSkill", "moukurou")
end

function SmartAIView:findPlayerToLoseHp(must)
    local second
    common_sort_in_place(self, strategy_known(self.enemies, "enemies"), "hp")
    for _, enemy in ipairs(self.enemies) do
        if not strategy_call(self, "hasZhaxiangEffect", enemy) and not strategy_call(self, "needToLoseHp", enemy, self.player, false, true) then return enemy end
        if must and not second then second = enemy end
    end
    if must then
        common_sort_in_place(self, strategy_known(self.friends_noself, "friends without self"), "hp", true)
        for _, friend in ipairs(self.friends_noself) do
            if strategy_call(self, "hasZhaxiangEffect", friend) and not strategy_call(self, "isWeak", friend)
                or strategy_call(self, "needToLoseHp", friend, self.player, false, true) then return friend end
        end
    end
    return second
end

function SmartAIView:disEquip(hand_only, equip_only)
    if strategy_call(self, "needToThrowArmor") then
        -- Complete public equipment distinguishes known nil (source ordinary
        -- indexing error) from a missing snapshot. Do not repair that error.
        if AIValue.isPlayer(self.player) then strategy_call(self.player,"getEquips") end
        local armor = self.player:getArmor()
        if AIUnsupported.is(armor) then error(armor,0) end
        return armor:getEffectiveId()
    end
    if hand_only and equip_only then return -1 end
    local cards = strategy_call(self.player, "getCards", "he")
    if hand_only then cards = strategy_call(self.player, "getHandcards") end
    if equip_only then cards = strategy_call(self.player, "getEquips") end
    local equips = {}
    for _, card in ipairs(cards) do
        if strategy_call(card, "isKindOf", "EquipCard") and not (strategy_call(card, "isKindOf", "WoodenOx")
            and strategy_pile_count(self.player, "wooden_ox") > 0) then equips[#equips + 1] = card end
    end
    if #equips < 1 then return nil end
    -- The fixed utility returns this Lua table unchanged. Preserve the
    -- source side-effecting call and ignore its ordinary return value.
    local sorted = self:sortByKeepValue(equips)
    if AIUnsupported.is(sorted) then error(sorted, 0) end
    return strategy_call(equips[1], "getEffectiveId")
end

function SmartAIView:throwEquipArea(choices,player)
	player = player or self.player
	local items = choices:split("+")
	if strategy_call(self, "isFriend", player) then--友方有sgs.lose_equip_skill待补充
		if strategy_call(self, "needToThrowArmor", player) and strategy_call(player, "hasEquipArea", 1) and table.contains(items,"1")
		then return "1"
		elseif strategy_call(player, "hasEquipArea", 4) and not r32_optional_equipment(player, "getTreasure") and table.contains(items,"4")
		then return "4"
		elseif strategy_call(player, "hasEquipArea", 1) and not r32_optional_equipment(player, "getArmor") and table.contains(items,"1")
		then return "1"
		elseif strategy_call(player, "hasEquipArea", 0) and not r32_optional_equipment(player, "getWeapon") and table.contains(items,"0")
		then return "0"
		elseif strategy_call(player, "hasEquipArea", 3) and not r32_optional_equipment(player, "getOffensiveHorse") and table.contains(items,"3")
		then return "3"
		elseif strategy_call(player, "hasEquipArea", 2) and not r32_optional_equipment(player, "getDefensiveHorse") and table.contains(items,"2")
		then return "2"
		elseif strategy_call(player, "hasEquipArea", 4) and not strategy_call(self, "keepWoodenOx", player) and table.contains(items,"4")
		then return "4"
		elseif strategy_call(player, "hasEquipArea", 1) and table.contains(items,"1")
		then return "1"
		elseif strategy_call(player, "hasEquipArea", 0) and table.contains(items,"0")
		then return "0"
		elseif strategy_call(player, "hasEquipArea", 3) and table.contains(items,"3")
		then return "3"
		elseif strategy_call(player, "hasEquipArea", 2) and table.contains(items,"2")
		then return "2"
		else
			return items[1]
		end
	else
		--待补充
	end
	return items[#items]
end

function SmartAIView:willSkipDiscardPhase(player)
    player = player or self.player
    if strategy_call(player, "getMark", "&mobilexinyinju") > 0 or strategy_call(player, "hasSkill", "conghui") then return true end
    if strategy_call(player, "hasSkill", "xingzhao") then
        local wounded = 0
        for _, other in ipairs(strategy_call(self.room, "getAlivePlayers")) do
            if strategy_call(other, "isWounded") then wounded = wounded + 1 end
            if wounded >= 3 then return true end
        end
    end
    for _, other in ipairs(strategy_call(self.room, "getAllPlayers")) do
        if strategy_call(other, "getMark", "fzndz_4") > 0 then return true end
    end
    if strategy_call(player, "getMark", "&basuran+:+discard_lun") > 0 then return true end
    for _, mark in ipairs(strategy_call(player, "getMarkNames")) do
        if mark:find("sfofl_yufeng") and strategy_call(player, "getMark", mark) > 0 then
            local suit = mark:split("+")[3]:split("_")[1]
            if suit == "spade" then return true end
        end
    end
    return false
end

-- smart-ai.lua:6509. Preserve the donor damage-card-before-Slash order
-- and GudingDlade spelling; neither is silently corrected here.
function SmartAIView:damageMinusHp(enemy,type)
	if not enemy then return 0 end
	local trick_effectivenum,slash_damagenum,analepticpowerup,effectivefireattacknum,basicnum = 0,0,0,0,0
	local cards = strategy_call(self.player, "getCards","he")
	for _,acard in ipairs(cards)do
		if strategy_call(acard, "getTypeId")==sgs.Card_TypeBasic and not strategy_call(acard, "isKindOf","Peach") then basicnum = basicnum+1 end
	end
	for _,acard in ipairs(cards)do
		if strategy_call(acard, "isDamageCard") and not strategy_call(self.player, "isProhibited",enemy,acard)
		or strategy_call(acard, "isKindOf","AOE") and strategy_call(self, "aoeIsEffective",acard,enemy) then
			if strategy_call(acard, "isKindOf","FireAttack") then
				if not strategy_call(enemy, "isKongcheng")
				then effectivefireattacknum = effectivefireattacknum+1
				else trick_effectivenum = trick_effectivenum-1 end
			end
			trick_effectivenum = trick_effectivenum+1
		elseif strategy_call(acard, "isKindOf","Slash") and strategy_call(self, "slashIsEffective",acard,enemy)
		and strategy_call(self.player, "distanceTo",enemy)<=strategy_call(self.player, "getAttackRange")
		and (slash_damagenum<1 or strategy_call(self, "hasCrossbowEffect")) then
			if not(basicnum<2 and strategy_call(enemy, "hasSkill","xiangle")) then slash_damagenum = slash_damagenum+1 end
			if analepticpowerup<1 and not strategy_call(self, "ignoreArmor",self.player,enemy) and strategy_call(self, "getCardsNum","Analeptic")>0
			and not(strategy_call(enemy, "hasArmorEffect","SilverLion") or strategy_call(enemy, "hasArmorEffect","EightDiagram")) then
				slash_damagenum = slash_damagenum+1
				analepticpowerup = analepticpowerup+1
			end
			if strategy_call(self.player, "hasWeapon","GudingDlade")
			and (strategy_call(enemy, "isKongcheng") or strategy_call(self.player, "hasSkill","lihun") and strategy_call(enemy, "isMale") and not strategy_call(enemy, "hasSkill","kongcheng"))
			and not(not strategy_call(self, "ignoreArmor",self.player,enemy) and strategy_call(enemy, "hasArmorEffect","SilverLion"))
			then slash_damagenum = slash_damagenum+1 end
		end
	end
	if type==0 then return trick_effectivenum+slash_damagenum-effectivefireattacknum-strategy_call(enemy, "getHp")
	else return trick_effectivenum+slash_damagenum-strategy_call(enemy, "getHp") end
	return -10
end


function SmartAIView:getRestCardsNum(class_name, observer)
    local discards = strategy_call(self.room, "getDiscardCards")
    observer = observer or self.player
    local known = 0
    for _, card in ipairs(discards) do
        if type(class_name) ~= "string" and type(class_name) ~= "number" then
            error("source Card::isKindOf expects a string class", 0)
        end
        if strategy_call(card, "isKindOf", class_name) then known = known + 1 end
    end
    for _, player in ipairs(strategy_call(self.room, "getOtherPlayers", observer)) do
        if same_player(observer, self.player) then
            known = known + strategy_known(getKnownCard(player, observer, class_name), "known deck count")
        else
            known = known + self:useKnowledgeEstimate(self:estimateKnownCards(player, class_name, observer), "getRestCardsNum.known")
        end
    end
    local function count(name)
        if type(name) == "table" then local total = 0; for _, entry in ipairs(name) do total = total + count(entry) end; return total end
        if type(name) ~= "string" then error("source PatternsCard name has no string match method", 0) end
        if name:find(",", 1, true) then
            local total, first = 0, 1
            while true do
                local comma = name:find(",", first, true)
                total = total + count(name:sub(first, comma and comma - 1 or #name))
                if not comma then return total end
                first = comma + 1
            end
        end
        -- Unbanned engine copies whose name, class or kind matches (PatternsCard).
        if type(ai_card_catalog) ~= "table" then ai_unsupported("card catalog is not projected", "getRestCardsNum") end
        local total = 0
        for _, row in ipairs(ai_card_catalog) do
            if not row.banned and (row.name == name or table.contains(row.kind_of or {}, name)) then
                total = total + (row.count or 0)
            end
        end
        return total
    end
    local total = count(class_name)
    local humanized = strategy_known(self.world.ai_humanized, "ai_humanized")
    return total - known - (humanized and math.random(0, total / 2) or 0)
end

function SmartAIView:hasJieyingyEffect(player)
    player = player or self.player
    if strategy_call(player, "getMark", "&jygying") > 0 and not strategy_call(player, "hasSkill", "jieyingg") then
        for _, owner in ipairs(strategy_call(self.room, "findPlayersBySkillName", "jieyingg")) do
            if not strategy_call(self, "isFriend", owner, player) then return true end
        end
    end
    for _, owner in ipairs(strategy_call(self.room, "findPlayersBySkillName", "zhafu")) do
        local row = rawget(player, "_view")
        local names = row and row.zhafu_from
        if not AIValue.isList(names) then ai_unsupported("public zhafu source names are absent", "zhafu_from") end
        if table.contains(names, owner:objectName()) and not strategy_call(self, "isFriend", owner, player) then return true end
    end
    if strategy_call(player, "getMark", "&Godying") > 0 and not strategy_call(player, "hasSkill", "Godjieying") then
        for _, owner in ipairs(strategy_call(self.room, "findPlayersBySkillName", "Godjieying")) do
            if not strategy_call(self, "isFriend", owner, player) then return true end
        end
    end
    return false
end

function SmartAIView:justDamage(to, from, is_slash, lock)
    if strategy_call(from, "hasFlag", "NosJiefanUsed") then return true end
    if strategy_call(self, "isFriend", to, from) then return false end
    if strategy_call(self, "dontHurt", to, from) then return true end
    if strategy_call(from, "hasSkill", "nosdanshou") then return true end
    do
        -- Source reads the property length BEFORE checking the skill.
        local ready
        if same_player(from, self.player) then
            local names = self.player:getPropertyValue("duorui_skills") or {}
            if type(names) ~= "table" then ai_unsupported("owner duorui skill state is malformed", "duorui_skills") end
            ready = #names < 1
        else
            ready = self:useKnowledgeEstimate({value = true, status = "estimate", viewer = self.player:objectName(), target = from:objectName(),
                basis = "foreign_duorui_readiness_assumed_from_public_skill_private_acquisitions_excluded"}, "justDamage.duorui")
        end
        if ready and strategy_call(from,"hasSkill","duorui") then return true end
    end
    if strategy_call(from, "hasSkill", "olduorui") then return true end
    if strategy_call(to, "getHp") <= 2 and strategy_call(to, "hasSkill", "chanyuan") then return true end
    if is_slash and strategy_call(from, "hasSkill", "chuanxin") then
        if #strategy_call(to, "getEquips") > 0 and not self:hasZhaxiangEffect(to) and strategy_call(self, "doDisCard", to, "e") then return true end
        if strategy_call(to, "getMark", "@chuanxin") < 1 and not strategy_call(to, "hasSkills", strategy_known(sgs.bad_skills, "bad_skills")) then
            if #strategy_call(to, "getVisibleSkillList") > 1 then return true end
        end
    end
    if strategy_call(from, "hasSkills", "zhiman|tenyearzhiman") and strategy_call(self, "doDisCard", to, "e") then return true end
    if is_slash then
        if not lock and strategy_call(from, "hasSkill", "tieji") then return true end
        if strategy_call(from, "hasSkill", "nosqianxi") and strategy_call(from, "distanceTo", to) == 1 then return true end
        if strategy_call(from, "hasWeapon", "IceSword") and strategy_call(self, "doDisCard", to, "he") then return true end
    end
    return false
end

function SmartAIView:noChoice(targets, reason)
    local function neutral(player)
        local role = strategy_call(self, "getRoleEstimate", player)
        if role == "unknown" then
            return self:useKnowledgeEstimate({value = true, status = "estimate", viewer = self.player:objectName(), target = player:objectName(),
                basis = "unclassified_role_treated_as_donor_neutral_for_intention"}, "noChoice.role")
        end
        return role == "neutral"
    end
    for _, player in ipairs(targets) do
        local skip, level = false, 10
        if reason == "damage" then
            skip = strategy_call(self, "needToLoseHp", player, self.player, nil, true) or neutral(player)
            if not skip then skip = not strategy_call(self, "damageIsEffective", player, nil, self.player) end
            level = -10
        elseif reason == "change" then
            skip = strategy_call(self, "hasManjuanEffect", player) or strategy_call(player, "isNude") or neutral(player)
        elseif reason == "discard" then
            skip = strategy_call(self, "doDisCard", player) or neutral(player); level = -10
        elseif reason == "letDis" then
            skip = strategy_call(self, "needToThrowCard", player) or strategy_call(player, "isNude") or neutral(player); level = -10
        else skip = neutral(player) or not strategy_call(self, "canDraw", player) end
        if not skip then
            if type(self.updateIntention) ~= "function" then ai_unsupported("intention staging is unavailable", "noChoice") end
            r32_callback_result(self:updateIntention(self.player, player, level))
        end
    end
end


-- Common smart-ai.lua implementation. Packages that override this method must
-- install their own isolated policy; no package override is inferred here.
function SmartAIView:willSkipDrawPhase(player, without_nullification)
    player = player or self.player
    if strategy_call(player, "getMark", "&yizheng") + strategy_call(player, "getMark", "&zhibian")
        + strategy_call(player, "getMark", "kuanshi_skip") > 0 then return true end
    local friend_null, removal = 0, 0
    if without_nullification ~= true then
        for _, other in ipairs(strategy_call(self.room, "getAlivePlayers")) do
            if strategy_call(self,"isFriend",other,player) then
                friend_null = friend_null + self:useKnowledgeEstimate(self:estimateKnownCards(other, "Nullification", self.player, true, "he"), "willSkipDrawPhase.Nullification")
            elseif strategy_call(self,"isEnemy",other,player) then
                friend_null = friend_null - self:useKnowledgeEstimate(self:estimateKnownCards(other, "Nullification", self.player, true, "he"), "willSkipDrawPhase.Nullification")
            end
        end
    end
    if strategy_call(self.player, "getPhase") <= sgs.Player_Play and not same_player(self.player, player)
        and strategy_call(self, "isFriend", player) then
        for _, card in ipairs(strategy_call(self.player, "getCards", "he")) do
            if isCard("Snatch", card, self.player) and strategy_call(self.player, "distanceTo", player) == 1
                or isCard("Dismantlement", card, self.player) then
                local trick = strategy_call(self, "getDismantlementProbe", card)
                if strategy_call(self, "hasTrickEffective", trick, player, self.player) then removal = removal + 1 end
            end
        end
    end
    if strategy_call(player, "containsTrick", "supply_shortage") then
        if strategy_call(player, "containsTrick", "YanxiaoCard") or strategy_call(player, "hasSkills", "shensu|jisu")
            or strategy_call(player, "getHandcardNum") > 0 and strategy_call(player, "hasSkill", "qiaobian") then return false end
        if friend_null + removal > 1 then return false end
        if type(self.getFinalRetrial) ~= "function" then ai_unsupported("retrial order is unavailable", "willSkipDrawPhase") end
        local side, wizard = self:getFinalRetrial(player)
        side = strategy_known(side, "final retrial side")
        if side == 1 and strategy_call(self, "getSuitNum", "club", true, wizard) > 0 then return false end
        for _, card in ipairs(strategy_call(player, "getJudgingArea")) do
            if strategy_call(card, "objectName"):find("kehexumou") and strategy_call(player, "hasSkill", "dl_yanxiao") then return false end
        end
        return true
    end
    if strategy_call(player, "getMark", "&kejiexianmabimp") > 0 or strategy_call(player, "getMark", "&basuran+:+draw_lun") > 0 then return true end
    for _, other in ipairs(strategy_call(self.room, "getAllPlayers")) do
        if strategy_call(other, "getMark", "fzndz_2") > 0 then return true end
    end
    for _, mark in ipairs(strategy_call(player, "getMarkNames")) do
        if mark:find("sfofl_yufeng") and strategy_call(player, "getMark", mark) > 0 and mark:sub(1,#"sfofl_yufeng") == "sfofl_yufeng" then
            local pieces = {}; for piece in mark:gmatch("[^+]+") do pieces[#pieces + 1] = piece end
            if not pieces[3] then ai_unsupported("malformed public yufeng mark", mark) end
            if pieces[3]:match("^[^_]+") == "heart" then return true end
        end
    end
    if strategy_pile_count(player, "sfofl_zhengjing") > 0 then return true end
    return false
end


-- SmartAI's disabled_ids: visible cards of the target that this card_chosen
-- question does not offer. Every other question offers no such list.
function SmartAIView:refreshDiscardPreferences(sourceAssignment)
    local ids = {}
    local request = self.request
    local options = type(request) == "table" and request.options
    if type(request) == "table" and request.kind == "card_chosen" and type(options) == "table"
        and AIValue.isList(options.card_ids) and type(options.context) == "table" then
        local offered = {}
        for _, id in ipairs(options.card_ids) do offered[id] = true end
        local who = self.room:findPlayerByObjectName(options.context.who, true)
        local flags = type(options.context.flags) == "string" and options.context.flags or ""
        local zones = {}
        if who and flags:find("e", 1, true) then zones[#zones + 1] = who:getEquips() end
        if who and flags:find("j", 1, true) then zones[#zones + 1] = who:getJudgingArea() end
        if who and flags:find("h", 1, true) then zones[#zones + 1] = who:getKnownCards() end
        for _, zone in ipairs(zones) do
            for _, card in ipairs(zone or {}) do
                local id = card:getEffectiveId()
                if type(id) == "number" and not offered[id] then ids[#ids + 1] = id end
            end
        end
    end
    self.disabled_ids = AIList.new(ids)
    if type(self.setStrategyMemory) ~= "function" then ai_unsupported("card-choice observation cache is unavailable", "refreshDiscardPreferences") end
    self:setStrategyMemory("discard_disabled_ids", ids)
    return self.disabled_ids
end

-- Strategy-only equipment choice for card_for_qiaobian. It never constructs a
-- candidate/answer ticket. All identities below come from public equipment.
local function common_choose_equipment(self, who)
    local equips = strategy_call(who, "getEquips")
    self:refreshDiscardPreferences()
    local registry = sgs.ai_skill_cardchosen or {}
    local function callback_result(callback)
        if type(callback) ~= "function" then return nil end
        local result = callback(self, who, "e", nil)
        if result and type(result) ~= "number" then result = strategy_call(result, "getEffectiveId") end
        return result
    end
    for _, skill in ipairs(strategy_call(who, "getSkills")) do
        local id = callback_result(registry["#" .. strategy_call(skill, "objectName")])
        -- The donor's #skill branch returns even a disabled id.
        if id then return id end
    end
    local callback = registry.snatch
    if type(callback) == "number" then
        registry.snatch = nil
        if not self.disabled_ids:contains(callback) then return callback end
    end
    local id = callback_result(callback)
    if id and not self.disabled_ids:contains(id) then return id end
    local friend = strategy_call(self, "isFriend", who)
    if not friend then
        for _, method in ipairs({"getDangerousCard", "getValuableCard"}) do
            id = strategy_call(self, method, who)
            if id and strategy_call(self, "doDisCard", who, id, true) then return id end
        end
    end
    local ordered = AIList.new(equips)
    if #ordered > 1 then
        if same_player(who, self.player) then ordered = strategy_call(self, "sortByKeepValue", ordered, not friend)
        else
            local values = {}
            for _, card in ipairs(ordered) do
                values[card] = self:useKnowledgeEstimate({value = strategy_call(self, "getKeepValue", card), status = "estimate",
                    basis = "viewer_keep_value_of_public_equipment_private_owner_cache_and_plans_excluded",
                    viewer = self.player:objectName(), target = who:objectName(), card_id = card:getEffectiveId()}, "moveField.equipment_keep")
            end
            table.sort(ordered, function(a,b) if friend then return values[a] < values[b] end; return values[a] > values[b] end)
        end
    end
    for _, card in ipairs(ordered) do
        if strategy_call(self, "doDisCard", who, strategy_call(card, "getEffectiveId"), true) then return card:getEffectiveId() end
    end
    if friend and #ordered > 0 and strategy_call(self, "loseEquipEffect", who) and strategy_call(self, "isWeak", who)
        and strategy_call(self, "doDisCard", who, ordered[1]:getEffectiveId(), true) then return ordered[1]:getEffectiveId() end
    local selectable = {}
    for _, card in ipairs(equips) do
        if not self.disabled_ids:contains(strategy_call(card, "getEffectiveId")) then selectable[#selectable + 1] = card end
    end
    if #selectable == 0 then return -1 end
    if same_player(who, self.player) then
        return strategy_call(self, "sortByKeepValue", selectable)[1]:getEffectiveId()
    end
    local index = math.random(1, #selectable)
    local chosen = selectable[index]
    if strategy_call(chosen, "isKindOf", "SilverLion") and strategy_call(who, "isWounded")
        and strategy_call(self, "isEnemy", who) and strategy_call(who, "hasArmorEffect", "SilverLion") then
        if index ~= #selectable then chosen = selectable[index+1] elseif index > 1 then chosen = selectable[index-1] end
    end
    return chosen:getEffectiveId()
end
local function common_public_equipment(who, id)
    for _, card in ipairs(strategy_call(who, "getEquips")) do if strategy_call(card, "getEffectiveId") == id then return card end end
    return nil
end

-- mountain-ai.lua:1, all judgment/equipment recipient branches.
function SmartAIView:card_for_qiaobian(who,flag,to_friends,to_enemies)
	flag = flag or "ej"
	to_friends = to_friends or self.friends
	to_enemies = to_enemies or self.enemies
	local card,target
	if strategy_call(self, "isFriend",who) then
		if flag:match("j") then
			for _,judge in ipairs(strategy_call(who, "getJudgingArea"))do
				if not strategy_call(judge, "isKindOf","YanxiaoCard") then
					for _,enemy in ipairs(to_enemies)do
						if not strategy_call(enemy, "containsTrick","YanxiaoCard")
						and not strategy_call(self.player, "isProhibited",enemy,judge)
						and not (strategy_call(enemy, "hasSkills","hongyan|olhongyan") or strategy_call(judge, "isKindOf","Lightning"))
						then return enemy,judge end
					end
				end
			end
		end
		if flag:match("e") and strategy_call(who, "hasEquip") then
			if strategy_call(who, "hasSkills",sgs.lose_equip_skill) then
				for _,equip in ipairs(strategy_call(who, "getCards","e"))do
					if strategy_call(self, "doDisCard",who,strategy_call(equip, "getEffectiveId"),true) then
						if strategy_call(equip, "isKindOf","DefensiveHorse")
						and not strategy_call(self, "isWeak",who) then card = equip break
						elseif strategy_call(equip, "isKindOf","Armor") and (not strategy_call(self, "isWeak",who) or strategy_call(self, "needToThrowArmor",who))
						then card = equip break else card = equip break end
					end
				end
				if card then
					local index = strategy_call(card, "getEquipSlot")
					if #strategy_call(self, "poisonCards",{card},who)>0 then
						common_sort_in_place(self,to_enemies,"defense")
						for _,friend in ipairs(to_enemies)do
							if not strategy_call(friend, "hasEquipArea",index) then continue end
							if not self:getSameEquip(card,friend) and strategy_call(friend, "objectName")~=strategy_call(who, "objectName")
							then return friend,card end
						end
					else
						if strategy_call(card, "isKindOf","Armor")
						or strategy_call(card, "isKindOf","DefensiveHorse") then
							common_sort_in_place(self,to_friends,"defense")
						else
							common_sort_in_place(self,to_friends,"handcard",true)
						end
						for _,friend in ipairs(to_friends)do
							if not strategy_call(friend, "hasEquipArea",index) then continue end
							if not self:getSameEquip(card,friend) and strategy_call(friend, "objectName")~=strategy_call(who, "objectName")
							and strategy_call(friend, "hasSkills",sgs.need_equip_skill.."|"..sgs.lose_equip_skill)
							then return friend,card end
						end
						for _,friend in ipairs(to_friends)do
							if not strategy_call(friend, "hasEquipArea",index) then continue end
							if not self:getSameEquip(card,friend) and strategy_call(friend, "objectName")~=strategy_call(who, "objectName")
							then return friend,card end
						end
					end
				end
			end
		end
	else
		if flag:match("j")
		and strategy_call(who, "containsTrick","YanxiaoCard") then
			for _,judge in ipairs(strategy_call(who, "getJudgingArea"))do
				if strategy_call(judge, "isKindOf","YanxiaoCard") then
					for _,friend in ipairs(to_friends)do
						if not strategy_call(friend, "containsTrick",strategy_call(judge, "objectName"))
						and not strategy_call(self.player, "isProhibited",friend,judge)
						and strategy_call(friend, "getJudgingArea"):length()>0
						then return friend,judge end
					end
					for _,friend in ipairs(to_friends)do
						if not strategy_call(friend, "containsTrick",strategy_call(judge, "objectName"))
						and not strategy_call(self.player, "isProhibited",friend,judge)
						then return friend,judge end
					end
				end
			end
		end
		if flag:match("e") and strategy_call(who, "hasEquip") then
			if strategy_call(who, "hasSkills",sgs.lose_equip_skill) then return end
			local card_id = common_choose_equipment(self,who)
			if card_id >= 0 then card = common_public_equipment(who, card_id) end
			if card and #strategy_call(self, "poisonCards",{card},who)<1 then
				local index = strategy_call(card, "getEquipSlot")
				if strategy_call(card, "isKindOf","Armor")
				or strategy_call(card, "isKindOf","DefensiveHorse") then
					common_sort_in_place(self,to_friends,"defense")
				else
					common_sort_in_place(self,to_friends,"handcard",true)
				end
				for _,friend in ipairs(to_friends)do
					if not strategy_call(friend, "hasEquipArea",index) then continue end
					if not self:getSameEquip(card,friend) and strategy_call(friend, "objectName")~=strategy_call(who, "objectName")
					and strategy_call(friend, "hasSkills",sgs.lose_equip_skill.."|shensu|tenyearshensu")
					then return friend,card end
				end
				for _,friend in ipairs(to_friends)do
					if not strategy_call(friend, "hasEquipArea",index) then continue end
					if not self:getSameEquip(card,friend) and strategy_call(friend, "objectName")~=strategy_call(who, "objectName")
					then return friend,card end
				end
			end
		end
	end
end

function SmartAIView:moveField(player,flag,froms,tos)
	froms = froms or strategy_call(self.room, "getAlivePlayers")
	tos = tos or strategy_call(self.room, "getAlivePlayers")
	player = player or self.player
	flag = flag or "ej"
	local from_friends,from_enemies,to_friends,to_enemies = {},{},{},{}
	for _,p in ipairs(froms)do
		if strategy_call(self, "isFriend",p) then table.insert(from_friends,p)
		else table.insert(from_enemies,p) end
	end
	for _,p in ipairs(tos)do
		if strategy_call(self, "isFriend",p) then table.insert(to_friends,p)
		else table.insert(to_enemies,p) end
	end
	local from_friends_noself = {}
	for _,p in ipairs(from_friends)do
		if strategy_call(p, "objectName")==strategy_call(player, "objectName") then continue end
		table.insert(from_friends_noself,p)
	end
	common_sort_in_place(self,from_enemies)
	common_sort_in_place(self,from_friends)
	common_sort_in_place(self,from_friends_noself)
	if flag:find("j") then
		for _,friend in ipairs(from_friends)do
			if strategy_call(friend, "getJudgingArea"):length()>0
			and not strategy_call(friend, "containsTrick","YanxiaoCard") then
				local to,c = r32_qiaobian(self,friend,flag,to_friends,to_enemies)
				if to and c then return friend,c,to end
			end
		end
		for _,enemy in ipairs(from_enemies)do
			if strategy_call(enemy, "getJudgingArea"):length()>0
			and strategy_call(enemy, "containsTrick","YanxiaoCard") then
				local to,c = r32_qiaobian(self,enemy,flag,to_friends,to_enemies)
				if to and c then return enemy,c,to end
			end
		end
	end
	if flag:find("e") then
		for _,friend in ipairs(from_friends_noself)do
			if strategy_call(friend, "hasEquip") and strategy_call(self, "loseEquipEffect",friend) then
				local to,c = r32_qiaobian(self,friend,flag,to_friends,to_enemies)
				if to and c then return friend,c,to end
			end
		end
		local targets = {}
		for _,enemy in ipairs(self.enemies)do
			if not strategy_call(self, "loseEquipEffect",enemy)
			and r32_qiaobian(self,enemy,flag,to_friends,to_enemies)
			then table.insert(targets,enemy) end
		end
		if #targets>0 then
			common_sort_in_place(self,targets)
			local to,c = r32_qiaobian(self,targets[1],flag,to_friends,to_enemies)
			if to and c then return targets[1],c,to end
		end
	end
end


function SmartAIView:AssistTarget()
    if type(self.getStrategyMemory) ~= "function" or type(self.setStrategyMemory) ~= "function" then
        ai_unsupported("strategy observation cache is unavailable", "AssistTarget")
    end
    local state = self:getStrategyMemory("assist_target")
    if type(state) ~= "table" then state = {} end
    if state.off then return nil end
    local target = state.player_name and self.room:findPlayerByObjectName(state.player_name, true)
    if not target or strategy_call(target, "isDead") then
        local humans = 0
        for _, player in ipairs(strategy_call(self.room, "getAlivePlayers")) do
            if strategy_call(player, "getState") ~= "robot" then humans = humans + 1; target = player end
        end
        state = {off = humans ~= 1, player_name = target and target:objectName() or nil}
        self:setStrategyMemory("assist_target", state)
        -- Donor intentionally checks off only on the next call.
    end
    if target and not same_player(target, self.player) and strategy_call(self, "isFriend", target)
        and strategy_call(self, "getOverflow", target) == 2 and not strategy_call(target, "hasSkill", "nosjuejing") then return target end
    return nil
end



-- A bounded native hypothetical descriptor, with only request-local mutable
-- flags. Switching variants switches their owner-bound rule facts as well.
-- Bind a strategy-selected exact cost set to an existing or lazily issued native
-- conversion. The callback chooses costs; this adapter never substitutes them.
function SmartAIView:bindTurnConversion(skill, class_name, spec, request)
    if type(self.getReadonlyPlayContext)=="function" and self:getReadonlyPlayContext() then
        return self:evaluateTurnConversion(skill,class_name,spec,request)
    end
    local identity_methods = {
        activation_owner="getActivationOwner", activation_skill="getActivationSkillName", activation_instance="getActivationInstanceId",
        source_owner="getSourceOwner", source_skill="getSourceSkillName", source_instance="getSourceInstanceID"
    }
    local function matches(candidate, raw)
        if not request then return true end
        for field, method in pairs(identity_methods) do
            local expected = strategy_call(request, method)
            local actual = raw and candidate[field] or strategy_call(candidate, method)
            if actual ~= expected then return false end
        end
        return true
    end
    local activation=request and strategy_call(request,"getActivationSkillName") or skill
    local options={skill=activation,suit=spec.suit,number=spec.number,subcards=spec.subcards}
    if request then options.instance=strategy_call(request,"getActivationInstanceId") end
    local card=self:newCard(spec.name,options)
    if card and matches(card) then return card end
    local policy=self:getConversionPolicy(class_name)
    local selected
    for _,row in ipairs(policy.skills) do
        local identity=row.play_identity
        if type(identity)=="table" and identity.activation_owner==self.player:objectName()
            and (request and identity.activation_skill==activation or not request and row.skill_name==skill)
            and matches(identity,true) then
            if type(row.play_scope_id)~="number" or row.play_request==nil then
                ai_unsupported("turn conversion Play scope is incomplete",skill)
            end
            if selected then ai_unsupported("turn conversion source is ambiguous",skill) end
            selected={}
            for key,value in pairs(row) do selected[key]=value end
            selected.scope_id,selected.identity,selected.request=row.play_scope_id,identity,row.play_request
            selected.lazy=true
        end
    end
    if not selected then
        -- An owned V1 view-as skill enabled at play is evaluated only (registerViewAsReceipt).
        local view
        for _,row in ipairs(type(self.player._view.skills)=="table" and self.player._view.skills or {}) do
            if row.name==skill then view=row break end
        end
        if request or not view or view.view_as_v2~=false or view.enabled_at_play~=true then
            ai_unsupported("turn conversion has no exact native source scope",skill)
        end
        local face=self:evaluateOwnerViewAsCard({name=spec.name,skill=skill,suit=spec.suit,number=spec.number,
            subcards=spec.subcards,can_recast=spec.can_recast})
        if face:getClassName()~=class_name then ai_unsupported("turn conversion product class changed",skill) end
        return self:registerViewAsReceipt(face._view)
    end
    card=self:resolveResponseConversion(spec,selected)
    if not card or not matches(card) then ai_unsupported("turn conversion source identity changed",skill) end
    return card
end

-- Resolve a single native scope for both hypothetical seeds and paid actions.
-- A scope is not a card receipt and cannot itself authorize submission.
-- The V2 skill action a proposal pays through: one the request offers for this
-- activation skill, matching the legacy request's identity when one is given.
function SmartAIView:getNativeSkillActionScope(skill, request)
    local selected = self:findOfferedSkillAction(skill, request)
    if not selected then ai_unsupported("skill action has no matching source scope", skill) end
    return selected
end
function SmartAIView:findOfferedSkillAction(skill, request)
    if type(skill) ~= "string" or skill == "" then ai_unsupported("invalid skill action source", "getNativeSkillActionScope") end
    local identity_methods = {
        activation_owner="getActivationOwner", activation_skill="getActivationSkillName", activation_instance="getActivationInstanceId",
        source_owner="getSourceOwner", source_skill="getSourceSkillName", source_instance="getSourceInstanceID"
    }
    local actions = type(self._indexes) == "table" and self._indexes.skill_actions_by_name
    -- Only a legacy skill request (with identity methods) scopes the action.
    if request and type(request.getActivationSkillName) ~= "function" then request = nil end
    local activation = request and strategy_call(request,"getActivationSkillName") or skill
    local selected
    for _, action in ipairs(actions and actions[activation] or {}) do
        if action.activation_owner == self.player:objectName() then
            local matches = true
            for field, method in pairs(identity_methods) do
                if request and action[field] ~= strategy_call(request, method) then matches = false end
            end
            if matches then
                if selected then ai_unsupported("skill action source is ambiguous", skill) end
                selected = {skill_name = activation, identity = action}
            end
        end
    end
    return selected
end

-- A SkillCard proposal specifies only source-authorized costs and user text.
-- Its product class/name is decided by the native skill factory, never guessed.
function SmartAIView:bindSkillCard(skill, costs, request, user_string, legacy_class)
    if type(skill) ~= "string" or skill == "" or not AIValue.isList(costs)
        or user_string ~= nil and type(user_string) ~= "string"
        or legacy_class ~= nil and (type(legacy_class) ~= "string" or legacy_class == "") then
        ai_unsupported("invalid exact skill action proposal", "bindSkillCard")
    end
    if type(self.getReadonlyPlayContext)=="function" and self:getReadonlyPlayContext() then
        local scope=self:getNativeSkillActionScope(skill,request)
        -- An omitted prototype must come from the native finite source catalog,
        -- never from guessing a class from the activation skill's name.
        local prototype=legacy_class or scope.readonly_prototype
        if type(prototype)~="string" or prototype=="" then
            ai_unsupported("nested source binding lacks an audited readonly prototype",skill)
        end
        return self:evaluateTurnSkillCard(skill,prototype,costs,request,user_string)
    end
    local exact, seen = {}, {}
    for _, id in ipairs(costs) do
        if type(id) ~= "number" or id < 0 or id % 1 ~= 0 or seen[id] then
            ai_unsupported("skill action costs must be unique physical IDs", skill)
        end
        seen[id], exact[#exact + 1] = true, id
    end
    -- A V2 skill answers through its offered skill action. A V1 skill card needs
    -- its card class for the evaluation face; submitting it falls back to SmartAI.
    local selected = self:findOfferedSkillAction(skill, request)
    if not selected and not legacy_class then
        ai_unsupported("skill action is not offered and has no legacy card class", skill)
    end
    return self:registerSkillActionReceipt({skill = skill, identity = selected and selected.identity,
        costs = exact, user_string = user_string, legacy_class = legacy_class})
end

function SmartAIView:getFanConversionProbe(card)
    local probe=nil -- The Fan hypothetical conversion is not projected.
    if type(probe)~="table" or type(probe.source)~="table" or type(probe.card)~="table" then
        ai_unsupported("Fan hypothetical use-card probe is not projected","fan")
    end
    for field,method in pairs({name="objectName",class_name="getClassName",suit="getSuit",number="getNumber"}) do
        if probe.source[field]~=strategy_call(card,method) then ai_unsupported("Fan probe belongs to another declared use","fan") end
    end
    return CardView.new(probe.card)
end

function SmartAIView:getReasonSlash(reason, original)
    local name = original and strategy_call(original, "objectName") or "slash"
    reason = reason or (original and strategy_call(original, "getSkillName", false)) or ""
    if original and (strategy_call(original, "getNumber") ~= 0 or strategy_call(original, "getSuit") ~= sgs.Card_NoSuit
        or #strategy_call(original, "getSubcards") > 0 or not strategy_call(original, "isVirtualCard")) then
        ai_unsupported("this hypothetical Slash cost/printing has no native reason probe", "getReasonSlash")
    end
    local mask = 0
    if original and strategy_call(original, "hasFlag", "Qinggang") then mask = mask + 1 end
    if original and strategy_call(original, "hasFlag", "SlashIgnoreArmor") then mask = mask + 2 end
    local function variant(skill, flags)
        local row = nil -- Reason/flag Slash probes are not projected.
        if type(row) ~= "table" then ai_unsupported("native reason/flag Slash probe is absent", skill .. ":" .. name .. ":" .. flags) end
        return row
    end
    if original and (not AIValue.isCard(original) or original:isEvaluationOnly() ~= true) then
        ai_unsupported("reason Slash mutation requires a fresh readonly card", "getReasonSlash")
    end
    local card = original or CardView.new(variant(reason, mask))
    local identity = original and strategy_call(original, "getLegacyIdentityToken")
    local original_id = original and original._view.id
    local original_effective_id = original and original._view.effective_id
    local function apply_variant(skill, flags)
        local row = variant(skill, flags)
        local face = {}
        for key, value in pairs(row) do face[key] = value end
        if original then
            face.legacy_identity_token = identity
            face.id, face.effective_id = original_id, original_effective_id
        end
        face.evaluation_only = true
        card._view = face
        -- Any old candidate was evaluated before the reached source mutation.
        card._evaluation_candidate = nil
    end
    apply_variant(reason, mask)
    function card:setSkillName(skill)
        reason = skill
        apply_variant(reason, mask)
    end
    function card:setFlags(flag)
        local remove = flag:sub(1,1) == "-"
        local key = remove and flag:sub(2) or flag
        local bit = key == "Qinggang" and 1 or key == "SlashIgnoreArmor" and 2
        if not bit then ai_unsupported("unprojected hypothetical Slash flag", key) end
        local present = math.floor(mask / bit) % 2 == 1
        if remove and present then mask = mask - bit elseif not remove and not present then mask = mask + bit end
        apply_variant(reason, mask)
    end
    return card
end

function SmartAIView:estimateSlashTargetMod(player, slash, kind)
    local row = type(slash) == "table" and rawget(slash, "_view")
    local own = same_player(player, self.player)
    local key = kind == "distance" and "target_mod_distance" or "target_mod_extra"
    if own then
        local value = row and row.evaluation_owner == player:objectName() and row[key]
        return {value = value, status = type(value) == "number" and "exact" or "unknown", basis = "owner_native_target_mod", target = player:objectName(), class = key}
    end
    local value, basis = 0, "foreign_target_mod_unmodelled_private_adjustments_excluded"
    if kind == "distance" then
        local explicit = strategy_call(player, "hasFlag", "InfinityAttackRange") or strategy_call(player, "hasFlag", "slashNoDistanceLimit")
            or strategy_call(player, "hasSkill", "jiangchi") and strategy_call(player, "hasFlag", "JiangchiInvoke")
            or strategy_call(player, "hasSkill", "tianyi") and strategy_call(player, "hasFlag", "TianyiSuccess")
        if explicit then value, basis = 1000, "foreign_unlimited_distance_inferred_from_visible_skill_flags"
        else
            for _, skill in ipairs(strategy_call(player, "getSkills")) do
                local text = strategy_call(skill, "getDescription")
                if (text:find("使用【杀】") or text:find("使用【殺】"))
                    and (text:find("無距離限制") or text:find("无距离限制") or text:find("無視距離") or text:find("无视距离")) then
                    value, basis = 1000, "foreign_unlimited_distance_inferred_from_public_skill_text"; break
                end
            end
        end
    else strategy_call(player, "getSkills") end
    return {value = value, status = "estimate", basis = basis, viewer = self.player:objectName(), target = player:objectName(), class = key}
end

sgs.ai_slash_benefit.unblockable = sgs.ai_slash_benefit.unblockable or function(self, player, slash)
	for _, skill in ipairs(strategy_call(self,"getConnections",player)) do
		if sgs.ai_canliegong_skill[skill] then
			return {value = 30, unblockable = true, skill = skill}
		end
	end

	if sgs.hit_skill and strategy_call(player, "hasSkills",sgs.hit_skill) then
		local skills = strategy_call(self,"getConnections",player)
		for _, skill in ipairs(skills) do
			if string.find(sgs.hit_skill, skill) then
				return {value = 28, unblockable = true, skill = skill}
			end
		end
	end

	-- 方法3: 檢查技能描述
	for _, skill in ipairs(strategy_call(player,"getVisibleSkillList",true)) do
		local desc = strategy_call(skill, "getDescription")
		if string.find(desc, "使用【杀】") or string.find(desc, "使用【殺】") then
			if string.find(desc, "不能使用【闪】")
			or string.find(desc, "不能使用【閃】")
			or string.find(desc, "不可以使用【闪】")
			or string.find(desc, "不可以使用【閃】")
			or string.find(desc, "無法使用【闪】")
			or string.find(desc, "無法使用【閃】")
			or string.find(desc, "不可闪避")
			or string.find(desc, "不可閃避") then
				return {value = 25, unblockable = true, skill = strategy_call(skill, "objectName")}
			end
		end
	end

	if strategy_call(player, "hasSkill","fuqi") or strategy_call(player, "hasSkill","tenyearfuqi") then
		return {value = 18, unblockable = true, skill = "fuqi"}
	end
	if  strategy_call(player, "hasSkill","jiandao") then
		if slash and strategy_call(slash, "isRed") then
			return {value = 18, unblockable = true, skill = "jiandao"}
		end
	end

	return nil
end

-- 無距離限制評估
sgs.ai_slash_benefit.no_distance_limit = sgs.ai_slash_benefit.no_distance_limit or function(self, player, slash)
	local value = 0
	local skills = {}

	local slash = slash or strategy_call(self,"getReasonSlash")
	local distance_correction = strategy_call(self,"useKnowledgeEstimate",strategy_call(self,"estimateSlashTargetMod",player, slash, "distance"), "slash_benefit.distance")
	if distance_correction > 10 then
		value = value + 18
	end

	for _, skill in ipairs(strategy_call(player,"getVisibleSkillList",true)) do
		local desc = strategy_call(skill, "getDescription")
		if (string.find(desc, "使用【杀】") or string.find(desc, "使用【殺】")) and
		   (string.find(desc, "無距離限制") or string.find(desc, "无距离限制") or
		    string.find(desc, "無視距離") or string.find(desc, "无视距离")) then
			value = value + 12
			table.insert(skills, strategy_call(skill, "objectName"))
		end
	end

	if strategy_call(player, "hasSkill","jiangchi") and strategy_call(player, "hasFlag","JiangchiInvoke") then
		value = value + 20
		table.insert(skills, "jiangchi")
	end

	if strategy_call(player, "hasSkill","tianyi") and strategy_call(player, "hasFlag","TianyiSuccess") then
		value = value + 25
		table.insert(skills, "tianyi")
	end

	if strategy_call(player, "hasFlag","InfinityAttackRange") or strategy_call(player, "hasFlag","slashNoDistanceLimit") then
		value = value + 15
	end

	if value > 0 then
		return {value = value, no_distance_limit = true, skills = skills}
	end

	return nil
end

-- 額外目標評估
sgs.ai_slash_benefit.extra_target = sgs.ai_slash_benefit.extra_target or function(self, player, slash)
	local slash = slash or strategy_call(self,"getReasonSlash")
	local extra_target_num = strategy_call(self,"useKnowledgeEstimate",strategy_call(self,"estimateSlashTargetMod",player, slash, "extra"), "slash_benefit.extra")

	if extra_target_num > 0 then
		return {value = extra_target_num * 10, extra_targets = extra_target_num}
	end

	return nil
end



function getDisplayCards(player, from)
    if not player then return {} end
    local ids = strategy_call(player, "getDisplayCards")
    local rows = nil -- Display card faces come from the visible hand below.
    local by_id = {}
    if type(rows) == "table" then
        for _, row in ipairs(rows) do
            local card = CardView.new(row)
            by_id[strategy_call(card, "getEffectiveId")] = card
        end
    else
        for _, card in ipairs(strategy_call(player, "getKnownCards")) do by_id[strategy_call(card, "getEffectiveId")] = card end
    end
    local cards = {}
    for _, id in ipairs(ids) do
        cards[#cards+1] = strategy_known(by_id[id], "public display card metadata")
    end
    return cards
end
function hasDisplaySkills(player)
    if not player then return false end
    -- display_cards lists the shown hand cards named by the public property.
    local view = rawget(player, "_view")
    local shown = type(view) == "table" and view.display_cards
    if not AIValue.isList(shown) then ai_unsupported("public display cards are not projected", "hasDisplaySkills") end
    return #shown > 0
end
function SmartAIView:getDisplayCards(player, observer) return getDisplayCards(player or self.player, observer or self.player) end
function SmartAIView:hasDisplaySkills(player) return hasDisplaySkills(player or self.player) end

function gdt(values)
    if #values == 0 then return 0 end
    local total = 0
    for _, value in ipairs(values) do total = total + value end
    return total / #values
end

function sgs.getCardNumAtCertainPlace(card, place, room)
    local count = 0
    if card and strategy_call(card, "isVirtualCard") then
        local ids = strategy_call(card, "getSubcards")
        if #ids > 0 and not room then ai_unsupported("virtual-card location requires a viewer RoomView argument", "getCardNumAtCertainPlace") end
        for _, id in ipairs(ids) do
            if strategy_call(room, "getCardPlace", id) == place then count = count + 1 end
        end
    elseif place == sgs.Player_PlaceHand then count = 1 end
    return count
end
function SmartAIView:getCardNumAtCertainPlace(card, place)
    return sgs.getCardNumAtCertainPlace(card, place, self.room)
end

function canAiSkills(name, ai)
    local registry = strategy_known(sgs.ai_fill_skill, "ai_fill_skill registry")
    if type(name) == "string" then
        for key, callback in pairs(registry) do if key == name then return {name = key, ai_fill_skill = callback} end end
        return nil
    end
    local names = nil -- The selectable general-skill catalogue is not projected.
    if type(names) ~= "table" then ai_unsupported("public general-skill catalog needs an explicit AI context", "canAiSkills") end
    local result = {}
    for _, skill in ipairs(names) do
        if registry[skill] then result[#result+1] = {name = skill, ai_fill_skill = registry[skill]} end
    end
    return result
end
function SmartAIView:canAiSkills(name) return canAiSkills(name, self) end
function addAiSkills(name)
    local skill = {name = name}
    sgs.ai_skills = sgs.ai_skills or {}
    sgs.ai_skills[#sgs.ai_skills+1] = skill
    return skill
end

function prohibitUseDirectly(card, player)
    return strategy_call(player, "isCardLimited", card, strategy_call(card, "getHandlingMethod"))
end
function hasYinshiEffect(player, has_armor)
    if strategy_call(player, "getMark", "&dragon_signet") + strategy_call(player, "getMark", "&phoenix_signet") >= 1 then return false end
    if not has_armor then
        -- A nil armor is known absence only with a complete public equipment zone.
        if AIValue.isPlayer(player) then strategy_call(player, "getEquips") end
        if player:getArmor() then return false end
    end
    return strategy_call(player, "hasSkill", "yinshi")
end
function ZishuEffect(player)
    local count = 0
    if strategy_call(player, "getPhase") == sgs.Player_Play and strategy_call(player, "hasSkill", "zhanji") then count = count + 1 end
    if strategy_call(player, "getPhase") ~= sgs.Player_NotActive and strategy_call(player, "hasSkill", "zishu") then count = count + 1 end
    if strategy_call(player, "hasSkill", "Luajianzai") then count = count + 1 end
    if strategy_call(player, "hasSkill", "nyarz_xunxun") then count = count + 1 end
    if strategy_call(player, "getPhase") ~= sgs.Player_NotActive and strategy_call(player, "hasSkill", "fcj_zishu") then count = count + 1 end
    return count
end

function canJiaozi(player)
    if strategy_call(player, "hasSkill", "jiaozi") then
        local others
        if type(player.getAliveSiblings) == "function" then others = strategy_call(player, "getAliveSiblings")
        else
            local room = rawget(player, "_room")
            others = strategy_call(room, "getOtherPlayers", player)
        end
        for _, other in ipairs(others) do
            if strategy_call(other, "getHandcardNum") >= strategy_call(player, "getHandcardNum") then return nil end
        end
        return true
    end
end

-- Pure dependency of thicket Guixin (bgm-ai.lua:100–133). This does not
-- register or initiate a BGM skill action, and does not read another AI.
function SmartAIView:isLihunTarget(player, drawCardNum)
    player, drawCardNum = player or self.player, drawCardNum or 1
    if type(player) == "table" and type(player.objectName) ~= "function" then
        for _, candidate in ipairs(player) do if self:isLihunTarget(candidate, drawCardNum) then return true end end
        return false
    end
    local hand = strategy_call(player,"getHandcardNum") + drawCardNum
    if not strategy_call(player,"isMale") then return false end
    local diaochan = self.room:findPlayerBySkillName("lihun")
    if not diaochan then return false end
    local used = diaochan:hasUsed("LihunCard")
    if used == nil then
        if same_player(diaochan,self.player) then ai_unsupported("owner Lihun history is unknown","isLihunTarget") end
        used = self:useKnowledgeEstimate({value=false,status="estimate",basis="no observed Lihun use; public action-history prior",
            viewer=self.player:objectName(),observer=self.player:objectName(),target=diaochan:objectName()},"isLihunTarget.history")
    end
    if used or strategy_call(self,"isFriend",diaochan) then return false end
    if strategy_call(diaochan,"getPhase") == sgs.Player_Play then
        if hand-strategy_call(player,"getHp")>=2
            or hand>0 and hand-strategy_call(player,"getHp")>=-1 and not strategy_call(diaochan,"faceUp") then return true end
    elseif strategy_call(diaochan,"faceUp") and not strategy_call(self,"willSkipPlayPhase",diaochan)
        and strategy_call(self,"playerGetRound",player)>strategy_call(self,"playerGetRound",diaochan)
        and hand>=strategy_call(player,"getHp")+2 then return true end
    return false
end

-- smart-ai.lua:470; cache is bound to this immutable PlayerView/request, not
-- shared between viewers or revisions. The source deliberately keeps order
-- and appends Weidi's lord skills without deduplication.
function sgs.getPlayerSkillList(player)
    local room=player and rawget(player,"_room")
    if not player or not room then ai_unsupported("skill-list player is missing","getPlayerSkillList")end
    local stamp=snapshot_cache_stamp(room,"source_skills",player)
    local cached=rawget(player,"_strategy_skill_list_cache")
    if cached and same_snapshot_cache(rawget(player,"_strategy_skill_list_stamp"),stamp)then return cached end
    local result=AIList.new{}
    for _,skill in ipairs(strategy_call(player,"getSkills")) do
        local name=strategy_call(skill,"objectName")
        if strategy_call(skill,"isLordSkill") then
            if strategy_call(player,"hasLordSkill",name) then result:append(skill) end
        elseif strategy_call(player,"hasSkill",name) then result:append(skill) end
    end
    if strategy_call(player,"hasSkill","weidi") then
        local room=rawget(player,"_room")
        if not room then ai_unsupported("Weidi lord roster is unknown","getPlayerSkillList") end
        local lord=room:getLord()
        if lord and not same_player(lord,player) then
            for _,skill in ipairs(strategy_call(lord,"getSkills")) do
                if strategy_call(skill,"isLordSkill") then result:append(skill) end
            end
        end
    end
    rawset(player,"_strategy_skill_list_cache",result)
    rawset(player,"_strategy_skill_list_stamp",stamp)
    return result
end

function SmartAIView:getShuibojianUse()
    local context=self.request and self.request.options and self.request.options.context
    local row=context and context.shuibojian_use
    if type(row)~="table" or type(row.card)~="table" or not AIValue.isList(row.to) then
        ai_unsupported("current owner Shuibojian execution is not projected","_shuibojian")
    end
    local from=self.room:findPlayerByObjectName(row.from)
    if not from or not same_player(from,self.player) then ai_unsupported("Shuibojian source is not the viewer","_shuibojian") end
    local targets=AIList.new{}
    for _,name in ipairs(row.to) do
        local target=self.room:findPlayerByObjectName(name)
        if not target then ai_unsupported("Shuibojian target is not in public roster","_shuibojian") end
        targets:append(target)
    end
    return {card=CardView.new(row.card),from=from,to=targets}
end
function SmartAIView:isShuibojianCandidate(player)
    local context=self.request and self.request.options and self.request.options.context
    local rows=context and context.shuibojian_candidates
    if type(rows)~="table" then ai_unsupported("Shuibojian candidate map is not projected","_shuibojian") end
    return rows[strategy_call(player,"objectName")]~=nil
end

-- Effective getLijianCard donor: inovation-ai.lua; shared by independent packages.
function SmartAIView:getLijianCard()
	local card_id
	local cards = strategy_call(self.player,"getHandcards")
	cards = sgs.QList2Table(cards)
	cards = self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")

	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum()>self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _,acard in ipairs(cards)do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		if self.player:getWeapon() then card_id = self.player:getWeapon():getId()
		elseif self.player:getOffensiveHorse() then card_id = self.player:getOffensiveHorse():getId()
		elseif self.player:getDefensiveHorse() then card_id = self.player:getDefensiveHorse():getId()
		elseif self.player:getArmor() and self.player:getHandcardNum()<=1 then card_id = self.player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _,acard in ipairs(cards)do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				  and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	return card_id
end


-- This VM's own cardask registry decides.
function SmartAIView:hasLegacyCardAsk(skill_name)
    return type(sgs.ai_skill_cardask)=="table" and sgs.ai_skill_cardask[skill_name]~=nil
end

-- imagine-ai.lua:691/829 and its fixed yjcm2012 Jiangchi choice dependency.
function SmartAIView:KingdomsCount(players)
	local kingdoms = {}
	for _,p in ipairs(players)do
		local kingdom = strategy_call(p,"getKingdom")
		local flag = true
		for _,k in pairs(kingdoms)do
			if k==kingdom then
				flag = false
			end
		end
		if flag then
			table.insert(kingdoms,kingdom)
		end
	end
	return #kingdoms
end

function SmartAIView:chooseJiangchiForDraw()
	local target = 0
	local goodtarget = 0
	local slashnum = 0
	local needburst = 0

	for _,slash in ipairs(strategy_call(self,"getCards","Slash"))do
		for _,enemy in ipairs(self.enemies)do
			if strategy_call(self,"slashIsEffective",slash,enemy) then
				slashnum = slashnum+1
				break
			end
		end
	end

	for _,enemy in ipairs(self.enemies)do
		for _,slash in ipairs(strategy_call(self,"getCards","Slash"))do
			if not strategy_call(self,"slashProhibit",slash,enemy) and strategy_call(self,"slashIsEffective",slash,enemy) and strategy_call(self,"isGoodTarget",enemy,self.enemies,slash) then
				goodtarget = goodtarget+1
				break
			end
		end
	end

	for _,enemy in ipairs(self.enemies)do
		if strategy_call(self.player,"canSlash",enemy) then
			target = target+1
			break
		end
	end

	if slashnum>1 or (slashnum>0 and goodtarget>0) then needburst = 1 end
	local sorted = strategy_call(self,"sort",self.enemies,"defenseSlash")
    for i,value in ipairs(sorted) do self.enemies[i]=value end
	local can_save_card_num = strategy_call(self.player,"getMaxCards")-strategy_call(self.player,"getHandcardNum")
	if target==0 or can_save_card_num>1 or strategy_call(self.player,"isSkipped",sgs.Player_Play) then return "jiang" end
	if strategy_call(self,"needBear") then return "jiang" end

	for _,enemy in ipairs(self.enemies)do
		local def = strategy_call(self,"getDefense",enemy)
		local slash = strategy_call(self,"getEvaluationCard","slash")
		local eff = strategy_call(self,"slashIsEffective",slash,enemy) and strategy_call(self,"isGoodTarget",enemy,self.enemies,slash)

		if strategy_call(self,"slashProhibit",slash,enemy) then
		elseif eff and def<8 and needburst>0 then return "chi"
		end
	end

	return "cancel"
end

function SmartAIView:ImitateResult_DrawNCards(player,skills,overall)
	if not player or strategy_call(player,"isSkipped",sgs.Player_Draw) then return 0 end
	skills = skills or strategy_call(player,"getVisibleSkillList",true)
	if #skills<1 then return 2 end
	local drawSkills = {}
	if overall then
		for _,skill in ipairs(skills)do
			table.insert(drawSkills,strategy_call(skill,"objectName"))
		end
	else
		for _,skill in ipairs(skills)do
			if strategy_call(player,"hasSkill",strategy_call(skill,"objectName")) then
				table.insert(drawSkills,strategy_call(skill,"objectName"))
			end
		end
	end
	local count = 2 --初始摸牌数目
	if #drawSkills>0 then
		local others = strategy_call(self.room,"getOtherPlayers",player) --其他角色
		local alives = strategy_call(self.room,"getAlivePlayers") --存活角色
		local lost = strategy_call(player,"getLostHp") --已损失体力值
		for _,skillname in pairs(drawSkills)do
			if skillname=="tuxi" then --突袭，放弃摸牌
				return math.min(2,#others)
			elseif skillname=="shuangxiong" then --双雄，放弃摸牌
				return 1
			elseif skillname=="zaiqi" then --再起，放弃摸牌（摸牌数目不定，返回期望值）
				return math.floor(lost*3/4)
			elseif skillname=="shelie" then --涉猎，放弃摸牌（摸牌数目不定，返回期望值）
				return 3
			elseif skillname=="xuanhuo" then --眩惑，放弃摸牌（摸牌数目不定，返回期望值）
				return 1
			elseif skillname=="nosfuhun" then --老父魂，放弃摸牌
				return 2
			elseif skillname=="luoyi" then --裸衣，少摸一张牌
				count = count-1
			elseif skillname=="yingzi" then --英姿，多摸一张牌
				count = count+1
			elseif skillname=="haoshi" then --好施，多摸两张牌
				count = count+2
			elseif skillname=="juejing" then --绝境，多摸已损失体力值数目的牌
				count = count+lost
			elseif skillname=="yongsi" then --庸肆，多摸现存势力数目的牌
				count = count+self:KingdomsCount(alives)
			elseif skillname=="shenwei" then --神威，多摸两张牌
				count = count+2
			elseif skillname=="jiangchi" then --将驰，多摸一张牌或少摸一张牌
				local choices = "jiang+chi+cancel"
				local func = sgs.ai_skill_choice.jiangchi
                if func == nil then
                    if type(self.chooseJiangchiForDraw)=="function" then func=function(ai) return ai:chooseJiangchiForDraw() end end
                end
				if func then
					local choice = func(self,choices)
					if choice=="jiang" then
						count = count+1
					elseif choice=="chi" then
						count = count-1
					end
				end
			elseif skillname=="noszishou" then --自守，多摸已损失体力值数目的牌
				count = count+lost
			elseif skillname=="hongyuan" then --弘援，少摸一张牌
				count = count-1
			elseif skillname=="kuiwei" then --溃围，弃置场上武器数目的牌
				if strategy_call(player,"getMark","@kuiwei")>0 then
					for _,p in ipairs(alives)do
						if p:getWeapon() then
							count = count-1
						end
					end
				end
			elseif skillname=="zhaolie" then --昭烈，少摸一张牌
				count = count-1
			elseif skillname=="ayshuijian" then --水箭，多摸(自身装备数目+1)的牌
				local equips = strategy_call(player,"getCards","e")
				count = count+1+math.floor(#equips/2)
			end
		end
	end
	return count
end

-- ServerPlayer::getAI availability is a knowledge predicate, never an AI bridge.
-- Native exposes public online/actual-controller cases and private state only
-- for this viewer or their authorized controlled actor.
function SmartAIView:getAIControlAvailability(player)
    player=player or self.player
    -- Robots and trusted players are AI controlled; the state is public.
    local state=strategy_call(player,"getState")
    if state=="robot" or state=="trust" then
        return {status="exact",value=true,basis="public_ai_state"}
    end
    -- Native's unconditional public-state branch is still provable when an
    -- older pure snapshot omits the narrow private-control metadata.
    if strategy_call(player,"getState")=="online"then
        return {status="exact",value=false,basis="public_online_player"}
    end
    return {status="unknown",basis="AI_control_availability_not_projected"}
end

-- Public subset of smart-ai5485 CardFilter. These five native providers read
-- only disclosed face/location facts; no foreign FilterSkill callback executes.
-- Exact describes the resulting public face, never use legality or authority.
function SmartAIView:publicCardFilterKnowledge(card, player, place)
    local function unknown(reason)return {status="unknown",basis="public_filter:"..reason}end
    if not AIValue.isCard(card) or not AIValue.isPlayer(player) then return unknown("invalid_value_view")end
    local id=card:getEffectiveId()
    if type(id)~="number" or id<0 or id%1~=0 then return unknown("physical_disclosure_required")end
    local canonical=self:getKnownCardById(id) or self:getChoiceCard(id)
    if not canonical then return unknown("card_not_disclosed")end
    for _,method in ipairs{"objectName","getClassName","getSuit","getNumber"}do
        local a,b=card[method](card),canonical[method](canonical)
        if a==nil or b==nil or a~=b then return unknown("disclosed_face_mismatch")end
    end
    local function exact(value,basis)return {status="exact",card=value,basis="public_filter:"..basis}end
    local actual_place=self.room:getCardPlace(id)
    if sgs.Player_PlaceEquip~=nil and actual_place==sgs.Player_PlaceEquip then
        -- Even an undisclosed FilterSkill cannot alter this branch: source
        -- breaks before viewFilter on the first filter, or returns gc if none.
        return exact(card,"actual_equipment_bypass")
    end
    local view=rawget(player,"_view")
    if not view or view.skills_complete~=true then return unknown("skill_roster_incomplete")end
    local skills=player:getSkills()
    if not AIValue.isList(skills)then return unknown("skill_roster_missing")end
    local effective={}
    for _,skill in ipairs(skills)do
        local lord,name=skill:isLordSkill(),skill:objectName()
        if type(lord)~="boolean" or type(name)~="string"then return unknown("skill_activation_metadata_missing")end
        local active
        if lord then active=player:hasLordSkill(name)else active=player:hasSkill(name)end
        if type(active)~="boolean"then return unknown("skill_activation_unknown")end
        if active then effective[#effective+1]=skill end
    end
    local weidi=player:hasSkill("weidi")
    if type(weidi)~="boolean"then return unknown("weidi_presence_unknown")end
    if weidi then
        local lord=self.room:getLord()
        if lord and lord:objectName()~=player:objectName()then
            local lord_view=rawget(lord,"_view")
            if not lord_view or lord_view.skills_complete~=true then return unknown("weidi_lord_roster_incomplete")end
            local lord_skills=lord:getSkills()
            if not AIValue.isList(lord_skills)then return unknown("weidi_lord_roster_missing")end
            for _,skill in ipairs(lord_skills)do
                local is_lord=skill:isLordSkill()
                if type(is_lord)~="boolean"then return unknown("weidi_lord_kind_unknown")end
                if is_lord then effective[#effective+1]=skill end
            end
        end
    end
    local filters={}
    local audited={hongyan=true,olhongyan=true,wushen=true,jinjiu=true,mobilejinjiu=true}
    for _,skill in ipairs(effective)do
        local filter=skill:inherits("FilterSkill")
        if type(filter)~="boolean"then return unknown("filter_kind_unknown")end
        if filter then
            local name=skill:objectName()
            if not audited[name]then return unknown("unaudited_provider:"..name)end
            filters[#filters+1]=name
        end
    end
    if #filters==0 then return exact(card,"complete_no_filter")end
    if actual_place==nil then return unknown("actual_location_unknown")end
    place=place or sgs.Player_PlaceJudge
    if type(place)~="number" or place%1~=0 then return unknown("hypothetical_place_unknown")end
    local suit,number=canonical:getSuit(),canonical:getNumber()
    if type(sgs.Card_Spade)~="number" or type(sgs.Card_Heart)~="number" or type(sgs.Player_PlaceHand)~="number"then return unknown("rule_constants_missing")end
    local result=card
    for _,skill in ipairs(filters)do
        -- Each donor filter sees gc, not the previously returned tc. The last
        -- matching clone wins; never compose Hongyan then Wushen on that clone.
        local name,new_suit=canonical:objectName(),suit
        local matches=false
        if skill=="hongyan" or skill=="olhongyan"then
            matches=suit==sgs.Card_Spade;new_suit=sgs.Card_Heart
        elseif skill=="wushen"then matches=suit==sgs.Card_Heart and place==sgs.Player_PlaceHand;name="slash"
        else matches=canonical:objectName()=="analeptic";name="slash"end
        if matches then
            -- A public printed prototype supplies the constructor class chain;
            -- do not copy a filtered wrapper's possibly different engine class.
            local ok,prototype=pcall(self.getEvaluationCard,self,name)
            if not ok then
                if AIUnsupported.is(prototype)then return unknown("printed_prototype_unavailable:"..name)end
                error(prototype,0)
            end
            if not prototype then return unknown("donor_clone_missing:"..name)end
            local raw=rawget(prototype,"_view")
            if not raw or not AIValue.isList(raw.kind_of) or type(prototype:getTypeId())~="number"then return unknown("printed_prototype_incomplete")end
            local row={name=name,class_name=prototype:getClassName(),kind_of=raw.kind_of,
                type_id=prototype:getTypeId(),suit=new_suit,number=number,skill_name=skill,
                engine_class_name=raw.engine_class_name,subtype=raw.subtype}
            local face=CardView.new(row)
            local suit_name,number_name=face:getSuitString(),face:getNumberString()
            if not suit_name or not number_name then return unknown("face_serialization_unknown")end
            row.red=new_suit==sgs.Card_Heart or new_suit==sgs.Card_Diamond or new_suit==sgs.Card_NoSuitRed
            row.black=new_suit==sgs.Card_Spade or new_suit==sgs.Card_Club or new_suit==sgs.Card_NoSuitBlack
            -- Card::toString634, getNumberString230, empty subcardString646.
            -- This is comparison metadata only, never parsed or submitted.
            row.legacy_string_key=name..":"..skill.."["..suit_name..":"..number_name.."]=."
            result=self:publicKnowledgeCard(row)
        end
    end
    return exact(result,result==card and "known_filters_no_match"or "audited_public_filter_clone")
end

-- jie_package-ai.lua29; target-revise policy only. No action/target authority is
-- created by copying the source's provisional use and appending one target.
function SmartAIView:canCanmou(to, use)
    if type(use)~="table" or not AIValue.isList(use.to) then
        ai_unsupported("Canmou provisional use targets are unknown","canCanmou")
    end
    local targets=AIList.new({})
    for _,target in ipairs(use.to)do targets:append(target)end
    targets:append(to)
    local candidate={from=use.from,card=use.card,to=targets}
    local hooks=self:getHooks("ai_target_revises")
    for _,name in ipairs(self:getConnections(to))do
        local callback=hooks and hooks[name]
        if type(callback)=="function" and callback(to,candidate.card,self,candidate)then return nil end
    end
    return true
end

-- Fixed b6025acc normal-bootstrap public suit metadata (74 tables).
-- Generated from /tmp/round17-static-metadata-runtime.json, no policy calls.
local source_suit_value_catalog={
 ["FourGuidao_suit_value"]={["club"]=2.7,["spade"]=3.9},
 ["FourQixi_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["Gilgamesh_suit_value"]={["heart"]=7},
 ["Irisviel_suit_value"]={["diamond"]=3.8,["heart"]=3.9},
 ["Kirei_suit_value"]={["club"]=2.7,["spade"]=2.7},
 ["Kojirou_suit_value"]={["club"]=4.8,["diamond"]=3.9},
 ["LuaDongcha_suit_value"]={["spade"]=3.9},
 ["LuaGuizha_suit_value"]={["club"]=3.9,["heart"]=3.9,["spade"]=3.5},
 ["LuaLonghun_suit_value"]={["club"]=4.2,["diamond"]=3.9,["heart"]=6.7,["spade"]=5},
 ["MeowGuose_suit_value"]={["diamond"]=3.9},
 ["MeowTianxiang_suit_value"]={["heart"]=4.9},
 ["NTD2_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["NTD3_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["NTD_suit_value"]={["diamond"]=3.9,["heart"]=3.9},
 ["PlusGuicai_suit_value"]={["club"]=3.9,["heart"]=3.9,["spade"]=3.5},
 ["PlusGuidao_suit_value"]={["club"]=2.7,["spade"]=3.9},
 ["PlusLongdan_suit_value"]={["club"]=4.2,["diamond"]=3.9,["heart"]=4,["spade"]=5},
 ["PlusMafei_suit_value"]={["diamond"]=6,["heart"]=6},
 ["PlusQixi_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["Rin_suit_value"]={["heart"]=6},
 ["SevenQuanBian_suit_value"]={["club"]=3.9,["heart"]=3.9,["spade"]=3.5},
 ["angel_suit_value"]={["diamond"]=6,["heart"]=6},
 ["anzhang_suit_value"]={["spade"]=3.9},
 ["duanliang_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["gaoda_jianhun_suit_value"]={["diamond"]=3.9,["heart"]=3.9},
 ["gaoda_zhanshi_suit_value"]={["club"]=3,["spade"]=3},
 ["guhuo_suit_value"]={["heart"]=5},
 ["guicai_suit_value"]={["club"]=3.9,["heart"]=3.9,["spade"]=3.5},
 ["guidao_suit_value"]={["club"]=2.7,["spade"]=3.9},
 ["guose_suit_value"]={["diamond"]=3.9},
 ["gzj_tiandao_suit_value"]={["club"]=3.9,["heart"]=3.9,["spade"]=3.5},
 ["heg_duanliang_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["huanshi_suit_value"]={["club"]=3.9,["diamond"]=3.4,["heart"]=3.9,["spade"]=3.5},
 ["huantong_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["japenknifejile_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["jieyou_suit_value"]={["spade"]=5},
 ["jijiu_suit_value"]={["diamond"]=6,["heart"]=6},
 ["jiuchi_suit_value"]={["spade"]=5},
 ["kanpo_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["keguose_suit_value"]={["diamond"]=3.9},
 ["kejieyaogongdu_suit_value"]={["club"]=6,["spade"]=6},
 ["keyaogongdu_suit_value"]={["club"]=6,["spade"]=6},
 ["longhun_suit_value"]={["club"]=4.2,["diamond"]=3.9,["heart"]=6.7,["spade"]=5},
 ["luazhiyong_suit_value"]={["heart"]=6},
 ["mingzhe_suit_value"]={["diamond"]=4,["heart"]=4},
 ["mouguose_suit_value"]={["diamond"]=3.9},
 ["mythxialei_suit_value"]={["diamond"]=6,["heart"]=6},
 ["newlonghun_suit_value"]={["club"]=4.2,["diamond"]=3.9,["heart"]=6.7,["spade"]=5},
 ["nos_sgkgodlonghun_suit_value"]={["club"]=4.2,["diamond"]=3.9,["heart"]=6.7,["spade"]=5},
 ["nosguhuo_suit_value"]={["heart"]=5},
 ["nosguicai_suit_value"]={["club"]=3.9,["heart"]=3.9,["spade"]=3.5},
 ["noslonghun_suit_value"]={["club"]=4.2,["diamond"]=3.9,["heart"]=6.7,["spade"]=5},
 ["nosxuanhuo_suit_value"]={["heart"]=3.9},
 ["qhstandardguose_suit_value"]={["diamond"]=4.3},
 ["qhstandardjijiu_suit_value"]={["diamond"]=6,["heart"]=6},
 ["qhwindhongyan_suit_value"]={["heart"]=7},
 ["qhwindtianxiang_suit_value"]={["heart"]=6,["spade"]=6},
 ["qingguo_suit_value"]={["club"]=4.2,["spade"]=4.1},
 ["qixi_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["quji_suit_value"]={["diamond"]=6,["heart"]=6},
 ["reedship_suit_value"]={["club"]=3,["spade"]=4},
 ["s2_gn_nixi_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["se_qidian_suit_value"]={["club"]=3.9,["heart"]=3.9,["spade"]=3.5},
 ["sgkgodyanmie_suit_value"]={["spade"]=4},
 ["sgkgodyoulong_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["shenzhang_suit_value"]={["heart"]=3.9},
 ["shixue_suit_value"]={["spade"]=5},
 ["tenyearduanliang_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["tianlang_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["tianxiang_suit_value"]={["heart"]=4.9},
 ["wisdom_s_suit_value"]={["club"]=3.9,["heart"]=3.9,["spade"]=3.5},
 ["yanxiao_suit_value"]={["diamond"]=3.9},
 ["yinling_suit_value"]={["club"]=3.9,["spade"]=3.9},
 ["zhixi_suit_value"]={["spade"]=4.9},
}
function SmartAIView:getSourceSuitValueTable(skill)
    if type(skill)~="string" then ai_unsupported("suit-value skill must be named","source_suit_value")end
    local key=skill.."_suit_value"
    local value=sgs[key]
    if value==nil then value=source_suit_value_catalog[key] end
    if value==nil then return nil,true end
    local result={};for k,v in pairs(value)do result[k]=v end
    return result,true
end

-- Fixed touhouproject-ai.lua:3677-3679, ordinary load-time metadata.
-- A later package registration retains normal Lua overwrite semantics.
sgs.TH_chao9_number_value = {["9"] = 1}

-- Fixed effective registry metadata, not callable legacy policy or userdata.
local source_cardneed_functions={
 ["BurningLove"]=true,
 ["DIT_if_mouhuoji"]=true,
 ["DIT_if_moukanpo"]=true,
 ["Dragon_feijiang"]=true,
 ["Dragon_guose"]=true,
 ["Dragon_jizhi"]=true,
 ["Dragon_luoyi"]=true,
 ["Dragon_qingguo"]=true,
 ["Dragon_wusheng"]=true,
 ["Dragon_wushuang"]=true,
 ["FiveYingzhan"]=true,
 ["FourHuoji"]=true,
 ["FourQixi"]=true,
 ["FourTianxiang"]=true,
 ["FourWusheng"]=true,
 ["GodJiuse"]=true,
 ["GodSaodang"]=true,
 ["Gposhi"]=true,
 ["Huansha"]=true,
 ["LuaBaozou"]=true,
 ["LuaBimie"]=true,
 ["LuaCangshan"]=true,
 ["LuaChanshi"]=true,
 ["LuaChuanyun"]=true,
 ["LuaDongcha"]=true,
 ["LuaDuanjian"]=true,
 ["LuaGongqi"]=true,
 ["LuaGuishen"]=true,
 ["LuaGuizha"]=true,
 ["LuaGungnir"]=true,
 ["LuaHuowei"]=true,
 ["LuaJiguangAsk"]=true,
 ["LuaLonghun"]=true,
 ["LuaPaoxiaoC"]=true,
 ["LuaPomo"]=true,
 ["LuaYanling"]=true,
 ["LuaYinyan"]=true,
 ["LuaZhuan"]=true,
 ["Luachuyi"]=true,
 ["Lualianji"]=true,
 ["Luayezhan"]=true,
 ["MeowBeige"]=true,
 ["MeowGuose"]=true,
 ["MeowGuowu"]=true,
 ["MeowJizhi"]=true,
 ["MeowLieren"]=true,
 ["MeowLiuli"]=true,
 ["MeowQiangwu"]=true,
 ["MeowQingguo"]=true,
 ["MeowTianxiang"]=true,
 ["NTD"]=true,
 ["NTD2"]=true,
 ["NTD3"]=true,
 ["PlusAnxi"]=true,
 ["PlusGuicai"]=true,
 ["PlusGuidao"]=true,
 ["PlusJie"]=true,
 ["PlusJizhi"]=true,
 ["PlusLeiji"]=true,
 ["PlusLiegong"]=true,
 ["PlusLiuli"]=true,
 ["PlusLongdan"]=true,
 ["PlusLuoyi"]=true,
 ["PlusMafei"]=true,
 ["PlusQixi"]=true,
 ["PlusShensu"]=true,
 ["PlusTieji"]=true,
 ["PlusWusheng"]=true,
 ["PlusYizhong"]=true,
 ["PlusYongyi"]=true,
 ["PlusZhiheng"]=true,
 ["PlusZhongyong"]=true,
 ["Promote_jizhi"]=true,
 ["Promote_luoyi"]=true,
 ["Promote_tieji"]=true,
 ["Promote_zhiheng"]=true,
 ["SE_Juji"]=true,
 ["SE_Juji_Reki"]=true,
 ["SE_Qixin"]=true,
 ["SE_Tiansuo"]=true,
 ["SE_Wuwei"]=true,
 ["SE_Zhiyuan"]=true,
 ["SE_Zhuzhen"]=true,
 ["SevenKanLuan"]=true,
 ["SevenQuanBian"]=true,
 ["SevenWeiYuan"]=true,
 ["SevenXiaoRui"]=true,
 ["SevenZhengBian"]=true,
 ["SixGuicai"]=true,
 ["SixJianCe"]=true,
 ["SixPaoxiao"]=true,
 ["SixQucai"]=true,
 ["SixShouLue"]=true,
 ["SixTaichen"]=true,
 ["SixWuzhi"]=true,
 ["TH_Eternal"]=true,
 ["TH_GreatestTreasure"]=true,
 ["TH_LastJudgement"]=true,
 ["TH_MissingPower"]=true,
 ["TH_Weapon_SpearTheGungnir"]=true,
 ["TH_aoyi_sanbubisha"]=true,
 ["TH_chao9"]=true,
 ["TH_fengyitianxiang"]=true,
 ["TH_hengong"]=true,
 ["TH_huaimiepaohou"]=true,
 ["TH_huanlongyueni"]=true,
 ["TH_huanzang"]=true,
 ["TH_nanti"]=true,
 ["TH_qiyaomofa"]=true,
 ["TH_scarlet"]=true,
 ["TH_wenwenxinwen"]=true,
 ["TH_xiepohuanjue"]=true,
 ["TH_zhongduotian"]=true,
 ["Tianhuo"]=true,
 ["Xuwu"]=true,
 ["Zhena"]=true,
 ["Zhudao"]=true,
 ["angel"]=true,
 ["anzhang"]=true,
 ["baotou"]=true,
 ["bawang"]=true,
 ["beige"]=true,
 ["bf_xuanlve"]=true,
 ["bignumber"]=true,
 ["bihu"]=true,
 ["bings"]=true,
 ["blmf"]=true,
 ["blood_hj"]=true,
 ["blooddry"]=true,
 ["bnjiuchi"]=true,
 ["bougairensha"]=true,
 ["chaogz"]=true,
 ["chenmu"]=true,
 ["chixin"]=true,
 ["chunlao"]=true,
 ["ckqishan"]=true,
 ["cqtieji"]=true,
 ["csmiaoyu"]=true,
 ["dahe"]=true,
 ["dangxian"]=true,
 ["defencefield"]=true,
 ["dev_chengzhi"]=true,
 ["dl_liuli"]=true,
 ["doubleslash"]=true,
 ["duXiaoguo"]=true,
 ["duancaiex"]=true,
 ["duandai"]=true,
 ["duanliang"]=true,
 ["eastfast"]=true,
 ["ejisi"]=true,
 ["empaidui"]=true,
 ["enyuan"]=true,
 ["eqiehu"]=true,
 ["equip"]=true,
 ["f_jiuwei"]=true,
 ["f_kuanglong"]=true,
 ["f_shengong"]=true,
 ["f_shennu"]=true,
 ["f_zhuifeng"]=true,
 ["fatebimie"]=true,
 ["fateguangbo"]=true,
 ["fateheijian"]=true,
 ["fatejuli"]=true,
 ["fatejuntuan_vs"]=true,
 ["fateqingxing"]=true,
 ["fateshengqi"]=true,
 ["fatesiji_vs"]=true,
 ["fcj_huanshi"]=true,
 ["fcj_leixi"]=true,
 ["fcj_qinguo"]=true,
 ["fcj_qizhou"]=true,
 ["fcjiehuoji"]=true,
 ["fcjielianhuan"]=true,
 ["fclongming"]=true,
 ["fcmouliegong"]=true,
 ["fcmouwusheng"]=true,
 ["feifengpo"]=true,
 ["feilianhuan"]=true,
 ["feiren"]=true,
 ["fengbi"]=true,
 ["fengge"]=true,
 ["gaoda_jianhun"]=true,
 ["gaoda_shenpan"]=true,
 ["gehou"]=true,
 ["goddess_new"]=true,
 ["guangge"]=true,
 ["guicai"]=true,
 ["guidao"]=true,
 ["guihao"]=true,
 ["guose"]=true,
 ["gushou"]=true,
 ["gzj_tiandao"]=true,
 ["haidao"]=true,
 ["hanrenzd"]=true,
 ["hanwei"]=true,
 ["haoshi"]=true,
 ["heg_chujue"]=true,
 ["heg_duanliang"]=true,
 ["heg_huyuan"]=true,
 ["heg_liegong"]=true,
 ["heg_luoyi"]=true,
 ["heg_mobile_liegong"]=true,
 ["heg_nos_xiaoni"]=true,
 ["heg_ol_liegong"]=true,
 ["heg_paoxiao"]=true,
 ["heg_qiangxi"]=true,
 ["heg_shensu"]=true,
 ["heg_xiaoji"]=true,
 ["htms_ranxin"]=true,
 ["htms_rishi"]=true,
 ["huangwu"]=true,
 ["huanshi"]=true,
 ["huantong"]=true,
 ["huazang"]=true,
 ["hujuzhiheng"]=true,
 ["huoji"]=true,
 ["hxss"]=true,
 ["jiang"]=true,
 ["jiangchi"]=true,
 ["jianshen"]=true,
 ["jiansu"]=true,
 ["jianwu"]=true,
 ["jie"]=true,
 ["jiefan"]=true,
 ["jieffan"]=true,
 ["jiewq"]=true,
 ["jieyou"]=true,
 ["jieyuan"]=true,
 ["jijiu"]=true,
 ["jingang"]=true,
 ["jiqiangs"]=true,
 ["jiuchi"]=true,
 ["jixieshenslash"]=true,
 ["jizhi"]=true,
 ["juedoujiasu"]=true,
 ["jueji"]=true,
 ["juji"]=true,
 ["kanpo"]=true,
 ["kechengnianen"]=true,
 ["kechengqingjiao"]=true,
 ["kechengxianzhu"]=true,
 ["kechengzhengbing"]=true,
 ["kechenniang"]=true,
 ["keguihuxiao"]=true,
 ["keguijueluone"]=true,
 ["keguilongyin"]=true,
 ["keguisheji"]=true,
 ["keguose"]=true,
 ["kehejinfaCard"]=true,
 ["kehexuanfeng"]=true,
 ["kehezhaotu"]=true,
 ["kehezhendan"]=true,
 ["kejiang"]=true,
 ["kejieguijuelu"]=true,
 ["kejieguisheji"]=true,
 ["kejieguiwumo"]=true,
 ["kejieguixiaoyin"]=true,
 ["kejieshenghuju"]=true,
 ["kejieshenghujutwo"]=true,
 ["kejieshengqinggang"]=true,
 ["kejieshengyuma"]=true,
 ["kejiexianchanxin"]=true,
 ["kejiexianfenshen"]=true,
 ["kejiexianjibian"]=true,
 ["kejieyaogongdu"]=true,
 ["kejieyaoshidu"]=true,
 ["kejieyaotongque"]=true,
 ["kenewgirlchandou"]=true,
 ["kenewhuoji"]=true,
 ["kenewkanpo"]=true,
 ["kenewpaoxiao"]=true,
 ["kenewqingran"]=true,
 ["kenewwangmiuCard"]=true,
 ["kenewwenxiang"]=true,
 ["keqifendi"]=true,
 ["keqijuezhi"]=true,
 ["keqiyizheng"]=true,
 ["kerongchang"]=true,
 ["keshenghuju"]=true,
 ["keshengyuma"]=true,
 ["keshengzhuihun"]=true,
 ["kexianbenxi"]=true,
 ["kexianchanxin"]=true,
 ["kexianguiyi"]=true,
 ["kexianjie"]=true,
 ["keyanzheng"]=true,
 ["keyaogongdu"]=true,
 ["keyaojiahuo"]=true,
 ["keyaoshidu"]=true,
 ["keyugongCard"]=true,
 ["khztbuff"]=true,
 ["kofliegong"]=true,
 ["kofqingguo"]=true,
 ["kofxiaoji"]=true,
 ["kuanggu"]=true,
 ["kuangnu"]=true,
 ["langmanpaotai"]=true,
 ["lanyuhua"]=true,
 ["lanyushanbi"]=true,
 ["leijijingyan"]=true,
 ["lgliegong"]=true,
 ["liangjian"]=true,
 ["lianhuan"]=true,
 ["lianxie"]=true,
 ["lieren"]=true,
 ["lihuo"]=true,
 ["lingbo"]=true,
 ["liuli"]=true,
 ["lol_zhiming"]=true,
 ["longhun"]=true,
 ["luaRshicai"]=true,
 ["luaRsihu"]=true,
 ["luaRyaowu"]=true,
 ["luaRziao"]=true,
 ["luaangyang"]=true,
 ["luabaozhahuohua"]=true,
 ["luabawang"]=true,
 ["luafeiqi"]=true,
 ["luagudan"]=true,
 ["luaguidao"]=true,
 ["luajieao"]=true,
 ["luajiezhi"]=true,
 ["luajuao"]=true,
 ["lualushou"]=true,
 ["luaposhi"]=true,
 ["luaqibing"]=true,
 ["luaqilin"]=true,
 ["luaqinglong"]=true,
 ["luashushenmr"]=true,
 ["luasynchrogazer"]=true,
 ["luaxianhai"]=true,
 ["luaxiaomeng"]=true,
 ["luayuehuang"]=true,
 ["luazhenshe"]=true,
 ["luazhiyong"]=true,
 ["luazhuiji"]=true,
 ["lukang_weiyan"]=true,
 ["luoyi"]=true,
 ["lxtx_jiangchi"]=true,
 ["lxtx_shouyue_liegong"]=true,
 ["lxtx_shouyue_paoxiao"]=true,
 ["lxtx_shouyue_tieqi"]=true,
 ["lxtx_shouyue_wusheng"]=true,
 ["lxtx_wupao"]=true,
 ["lxtx_xianzhen"]=true,
 ["lyduji"]=true,
 ["meisproulin"]=true,
 ["meispxiaoji"]=true,
 ["meispzhanhun"]=true,
 ["meizlchanhuo"]=true,
 ["meizlchijia"]=true,
 ["meizlchunshen"]=true,
 ["meizlduyan"]=true,
 ["meizlfeiren"]=true,
 ["meizlhujia"]=true,
 ["meizlhuyi"]=true,
 ["meizljianwu"]=true,
 ["meizljianwuskill2"]=true,
 ["meizllipo"]=true,
 ["meizlliuma"]=true,
 ["meizlmijian"]=true,
 ["meizlmuniu"]=true,
 ["meizlsebihui"]=true,
 ["meizlsejunwang"]=true,
 ["meizlsepoxiao"]=true,
 ["meizlshhujia"]=true,
 ["meizlshwuji"]=true,
 ["meizlshxianggui"]=true,
 ["meizlshxiangjie"]=true,
 ["meizlshyuguo"]=true,
 ["meizlsuxian"]=true,
 ["meizlwuji"]=true,
 ["meizlxianggui"]=true,
 ["meizlxiangjie"]=true,
 ["meizlyuguo"]=true,
 ["meizlyuxiang"]=true,
 ["meizlzenhui"]=true,
 ["mingce"]=true,
 ["mingzhe"]=true,
 ["miyund"]=true,
 ["mobilejiuchi"]=true,
 ["mobilelieren"]=true,
 ["mobilelihuo"]=true,
 ["mobilemouhuanshi"]=true,
 ["mobilemouxianzhen"]=true,
 ["mobileqiangxi"]=true,
 ["mobileshuangxiong"]=true,
 ["mobilexianzhen"]=true,
 ["mobilexiaoxi"]=true,
 ["mobilexuanfeng"]=true,
 ["mobilezhijian"]=true,
 ["molwf"]=true,
 ["mouguose"]=true,
 ["moujizhi"]=true,
 ["moulianhuan"]=true,
 ["moupaoxiao"]=true,
 ["mouqingguo"]=true,
 ["moying"]=true,
 ["mythjizhi"]=true,
 ["newfengwang"]=true,
 ["newlonghun"]=true,
 ["ningshi"]=true,
 ["nos_sgkgodlonghun"]=true,
 ["nosgongqi"]=true,
 ["nosguhuo"]=true,
 ["nosguicai"]=true,
 ["nosguose"]=true,
 ["nosjiefan"]=true,
 ["nosjizhi"]=true,
 ["nosluoyi"]=true,
 ["nosqianxi"]=true,
 ["nosxuanfeng"]=true,
 ["nosxuanhuo"]=true,
 ["nyarz_funing"]=true,
 ["nyarz_mieji"]=true,
 ["nyguose"]=true,
 ["nyqirang"]=true,
 ["nyxuechang"]=true,
 ["olguidao"]=true,
 ["olhuoji"]=true,
 ["oljiuchi"]=true,
 ["olkanpo"]=true,
 ["ollianhuan"]=true,
 ["olzhijian"]=true,
 ["os_chitu"]=true,
 ["paoxiao"]=true,
 ["poi_paoxiao"]=true,
 ["qhfirehuoji"]=true,
 ["qhfirekanpo"]=true,
 ["qhfirelianhuan"]=true,
 ["qhfiremengjin"]=true,
 ["qhfireqiangxiCARD"]=true,
 ["qhfirequhu"]=true,
 ["qhfireshuangxiong"]=true,
 ["qhfiretianyi"]=true,
 ["qhstandardguose"]=true,
 ["qhstandardjijiu"]=true,
 ["qhstandardjizhi"]=true,
 ["qhstandardliuli"]=true,
 ["qhstandardluoyi"]=true,
 ["qhstandardpaoxiao"]=true,
 ["qhstandardqiaomeng"]=true,
 ["qhstandardqicai"]=true,
 ["qhstandardqingguo"]=true,
 ["qhstandardqixi"]=true,
 ["qhstandardtieqi"]=true,
 ["qhstandardxiaoji"]=true,
 ["qhstandardyaowu"]=true,
 ["qhstandardzhangba"]=true,
 ["qhstandardzhiheng"]=true,
 ["qhwindgongshu"]=true,
 ["qhwindhongyan"]=true,
 ["qhwindkuanggu"]=true,
 ["qhwindleiji"]=true,
 ["qhwindliegong"]=true,
 ["qhwindtianxiang"]=true,
 ["qiangpao"]=true,
 ["qiangxi"]=true,
 ["qiaobian"]=true,
 ["qingguo"]=true,
 ["qixi"]=true,
 ["qrdag"]=true,
 ["quexie"]=true,
 ["quhu"]=true,
 ["quji"]=true,
 ["roulin"]=true,
 ["s2_2_zhanjiang"]=true,
 ["s2_baibu"]=true,
 ["s2_changsheng"]=true,
 ["s2_chengwu"]=true,
 ["s2_danqi"]=true,
 ["s2_feijun"]=true,
 ["s2_gn_nixi"]=true,
 ["s2_jianzu"]=true,
 ["s2_leiyin"]=true,
 ["s2_longhun"]=true,
 ["s2_qigong"]=true,
 ["s2_taoni"]=true,
 ["s2_tianjiang"]=true,
 ["s2_tieji"]=true,
 ["s2_tuxi"]=true,
 ["s2_wuhun"]=true,
 ["s2_xuezhan"]=true,
 ["s2_yezhan"]=true,
 ["s2_zhanjiang"]=true,
 ["s3_fans_feiyan"]=true,
 ["s3_fans_longxiao"]=true,
 ["s3_fans_pianji"]=true,
 ["s3_fans_wenjiu"]=true,
 ["s3_jxwj_fange"]=true,
 ["s3_jxwj_zhoudao"]=true,
 ["s3_lianzhan"]=true,
 ["s3_luofeng"]=true,
 ["s3_tianwei"]=true,
 ["s3_xiandao"]=true,
 ["s3_xiongyi"]=true,
 ["s3_yt_zhengtao"]=true,
 ["s4_banjiang"]=true,
 ["s4_cangzhuo"]=true,
 ["s4_cloud_liegong"]=true,
 ["s4_cloud_tuxi"]=true,
 ["s4_cloud_yongqian"]=true,
 ["s4_fuhan"]=true,
 ["s4_ganglu"]=true,
 ["s4_jiwu"]=true,
 ["s4_juejing"]=true,
 ["s4_liegong"]=true,
 ["s4_paoxiao"]=true,
 ["s4_s_jinggong"]=true,
 ["s4_txbw_general_duel"]=true,
 ["s4_wuhu_heduan"]=true,
 ["s4_wuhu_wusheng"]=true,
 ["s4_wusheng"]=true,
 ["s4_xianfeng"]=true,
 ["s_biaoqi"]=true,
 ["s_fire_sword"]=true,
 ["s_jieshu"]=true,
 ["s_lotus_stick"]=true,
 ["s_w_shenghun"]=true,
 ["s_w_shenyong"]=true,
 ["s_w_yuma"]=true,
 ["s_wuqiang"]=true,
 ["s_yanyu"]=true,
 ["sandun"]=true,
 ["se_dushe"]=true,
 ["se_erdao"]=true,
 ["se_gate"]=true,
 ["se_kuangquan"]=true,
 ["se_mingqie"]=true,
 ["se_origin"]=true,
 ["se_qidian"]=true,
 ["se_shengjian"]=true,
 ["se_wenchang"]=true,
 ["se_yezhan"]=true,
 ["se_zhijian"]=true,
 ["secondtenyearchunlao"]=true,
 ["secondtenyearlihuo"]=true,
 ["sexualadvantage"]=true,
 ["sfofl_baoquan"]=true,
 ["sfofl_boss_shayi"]=true,
 ["sfofl_boss_wusheng"]=true,
 ["sfofl_boss_wushuang"]=true,
 ["sfofl_guanghui"]=true,
 ["sfofl_jianjing"]=true,
 ["sfofl_qianmu"]=true,
 ["sfofl_shenglv"]=true,
 ["sfofl_shuangren"]=true,
 ["sfofl_suiluan"]=true,
 ["sfofl_tieti"]=true,
 ["sfofl_xingwei"]=true,
 ["sfofl_yaozhuo"]=true,
 ["sfofl_yijue"]=true,
 ["sfofl_youlong"]=true,
 ["sfofl_young_wushuang"]=true,
 ["sgkgodjuechen"]=true,
 ["sgkgodlonghun"]=true,
 ["sgkgodluezhen"]=true,
 ["sgkgodqianqi"]=true,
 ["sgkgodxianzhu"]=true,
 ["sgkgodyingshi"]=true,
 ["sgkgodyoulong"]=true,
 ["sgkgodzhiji"]=true,
 ["shanguang"]=true,
 ["shengdanny"]=true,
 ["shenghua"]=true,
 ["shengqiang"]=true,
 ["shengui"]=true,
 ["shenniao"]=true,
 ["shensu"]=true,
 ["shenyan"]=true,
 ["shenzhang"]=true,
 ["shenzhi"]=true,
 ["shihuo"]=true,
 ["shijiu"]=true,
 ["shouye"]=true,
 ["shuanglong"]=true,
 ["shuangren"]=true,
 ["shuangxiong"]=true,
 ["sijian"]=true,
 ["sijyu_wusheng"]=true,
 ["sijyu_zhanjiang"]=true,
 ["sinzhisi"]=true,
 ["sk_caijie"]=true,
 ["sk_feijun"]=true,
 ["sk_fenwei"]=true,
 ["sk_jiwu"]=true,
 ["sk_kuangfu"]=true,
 ["slash"]=true,
 ["smsy"]=true,
 ["sp_qianlixing"]=true,
 ["sp_weizhen"]=true,
 ["sp_yuanzhi"]=true,
 ["sp_zhishen"]=true,
 ["sp_zhujiu"]=true,
 ["spwushen"]=true,
 ["sr_aozhan"]=true,
 ["sr_benxi"]=true,
 ["sr_huxiao"]=true,
 ["sr_jiexi"]=true,
 ["sr_jiwu"]=true,
 ["sr_paoxiao"]=true,
 ["sr_sheji"]=true,
 ["sr_shixue"]=true,
 ["sr_wenjiu"]=true,
 ["sr_xiwu"]=true,
 ["sr_xujin"]=true,
 ["sr_yaozhan"]=true,
 ["suzhan"]=true,
 ["sy_longnu"]=true,
 ["sy_old_lingnue"]=true,
 ["sy_wushuang"]=true,
 ["sy_zhiheng"]=true,
 ["taichen"]=true,
 ["tanhu"]=true,
 ["tanlan"]=true,
 ["tcmfs"]=true,
 ["tengyun"]=true,
 ["tenyearbiluan"]=true,
 ["tenyearchunlao"]=true,
 ["tenyearduanliang"]=true,
 ["tenyearjiangchi"]=true,
 ["tenyearjiefan"]=true,
 ["tenyearshensu"]=true,
 ["tenyearwusheng"]=true,
 ["tenyearxianzhen"]=true,
 ["tenyearxuanfeng"]=true,
 ["tenyearzhiheng"]=true,
 ["tianbian"]=true,
 ["tianxiang"]=true,
 ["tianyi"]=true,
 ["tiexue"]=true,
 ["tongtian_zhiheng"]=true,
 ["tucao"]=true,
 ["twyj_huzhu"]=true,
 ["twyj_qijia"]=true,
 ["ujlianji"]=true,
 ["ujlianjig"]=true,
 ["ujyaozhan"]=true,
 ["ujzhongshi"]=true,
 ["wangzhe"]=true,
 ["wannawin"]=true,
 ["weapon"]=true,
 ["weixiao"]=true,
 ["wenjiu"]=true,
 ["wisdom_s"]=true,
 ["wujijian"]=true,
 ["wusheng"]=true,
 ["wushitexing"]=true,
 ["wuyuan"]=true,
 ["xiangyangshi"]=true,
 ["xianzhen"]=true,
 ["xiaoguo"]=true,
 ["xiaoji"]=true,
 ["xinyan"]=true,
 ["xionglie"]=true,
 ["xrshanjia"]=true,
 ["xuanfeng"]=true,
 ["xuechang"]=true,
 ["xueji"]=true,
 ["y_caipei"]=true,
 ["y_shenzhi"]=true,
 ["y_shenzhu"]=true,
 ["y_wuji"]=true,
 ["yanxiao"]=true,
 ["yijizho"]=true,
 ["yijue"]=true,
 ["yinghun_po"]=true,
 ["yizan"]=true,
 ["ytchengxiang"]=true,
 ["yuanhu"]=true,
 ["yueying"]=true,
 ["yuri_hagaku"]=true,
 ["yuri_xueji"]=true,
 ["zfduanhe"]=true,
 ["zhiheng"]=true,
 ["zhijian"]=true,
 ["zhixi"]=true,
 ["zhizun"]=true,
 ["zhuanshan"]=true,
 ["zhuisha"]=true,
 ["zhulou"]=true,
 ["zjyizhen"]=true,
}
function SmartAIView:hasSourceCardNeed(skill)
    if type(skill)~="string" then ai_unsupported("card-need key must be named","source_cardneed")end
    return source_cardneed_functions[skill]==true
end

-- sp-ai.lua10002: exact ordered target buckets, using public printed generals.
function SmartAIView:getYongdiTarget(targets,lord)
    local function q(o,k,...)
        if not o or type(o[k])~="function" then ai_unsupported("Yongdi helper unavailable",k)end
        local v=o[k](o,...)
        if AIUnsupported.is(v)then error(v,0)end
        if v==nil then ai_unsupported("Yongdi observation unknown",k)end
        return v
    end
    targets=q(self,"sort",sgs.QList2Table(targets),"chaofeng")
    local lords,good,weaks={},{},{}
    local islord,isgood,isweak={},{},{}
    for _,p in ipairs(targets)do
        if q(self,"isFriend",p)then
            if q(self,"hasSkills",sgs.need_maxhp_skill,p)then good[#good+1]=p;isgood[p]=true end
            local row=nil -- Printed general skill lists are not projected.
            if type(row)~="table" then ai_unsupported("printed general skills unknown","getYongdiTarget")end
            for _,part in ipairs({"primary","secondary"})do
                if islord[p]then break end
                local list=row[part]
                if list~=false then
                    if not AIValue.isList(list)then ai_unsupported("printed general skills concealed","getYongdiTarget")end
                    for _,skill in ipairs(list)do
                        if skill.visible and skill.lord then
                            local active=row.lord_effective_including_lose and row.lord_effective_including_lose[skill.name]
                            if type(active)~="boolean"then ai_unsupported("including-lose lord skill state unknown","getYongdiTarget")end
                            if not active and (not lord or not q(p,"isLord"))then
                                lords[#lords+1]=p;islord[p]=true;break
                            end
                        end
                    end
                elseif part=="primary"then error("attempt to index a nil value",0)end
            end
            if q(self,"isWeak",p)then weaks[#weaks+1]=p;isweak[p]=true end
        end
    end
    for _,which in ipairs({1,2,3,4})do
        for _,p in ipairs(targets)do
            if q(self,"isFriend",p)and (which==1 and islord[p]and isgood[p]and isweak[p]
                or which==2 and islord[p]and isgood[p] or which==3 and isgood[p]and isweak[p]
                or which==4 and islord[p]and isweak[p])then return p end
        end
    end
    return good[1]or lords[1]or weaks[1]
end

-- R28 fixed smart-ai.lua default damage/dontHurt registries. Package files load
-- afterward and retain donor override order. No callback is run at registration.
do
    sgs.ai_ajustdamage_from=sgs.ai_ajustdamage_from or {}
    sgs.ai_ajustdamage_to=sgs.ai_ajustdamage_to or {}
    sgs.ai_dont_hurt_to=sgs.ai_dont_hurt_to or {}
    sgs.ai_dont_hurt_from=sgs.ai_dont_hurt_from or {}
sgs.ai_dont_hurt_to["@Kekkai"] = true
sgs.ai_dont_hurt_to["@jujiman"] = true
sgs.ai_dont_hurt_to["@TH_exileddoll"] = true
sgs.ai_dont_hurt_to["@TH_terriblesouvenir"] = true
sgs.ai_dont_hurt_to["@mark_zhanshan"] = true
sgs.ai_dont_hurt_to["&KunPeng"] = true
sgs.ai_dont_hurt_to["sizhan"] = true
sgs.ai_dont_hurt_to["lixun"] = true
sgs.ai_dont_hurt_to["kehezhendan"] = true
sgs.ai_dont_hurt_to["Jianqiao"] = true
sgs.ai_dont_hurt_to["se_Fanshe"] = true
sgs.ai_dont_hurt_to["se_shenglong"] = true
sgs.ai_dont_hurt_to["keqinji"] = true
sgs.ai_dont_hurt_to["yuri_sizhan"] = true
sgs.ai_dont_hurt_to["heg_jilix"] = true
sgs.ai_dont_hurt_to["lol_hudun"] = true
sgs.ai_dont_hurt_from["TH_IllusionaryDominance"] = true
sgs.ai_dont_hurt_from["LuaRevenge"] = true
sgs.ai_dont_hurt_to["&beketinghu"] = true

sgs.ai_dont_hurt_to["meispliwu"] = function(self, to, from)
	return donor_call(to,"getMark","@meispliwuprevent") > 0
end

sgs.ai_dont_hurt_to["meispshliwu"] = function(self, to, from)
    return donor_call(to,"getMark","@meispshliwuprevent") > 0
end

sgs.ai_dont_hurt_to["meispshfengdan"] = function(self, to, from)
    return donor_call(to,"getMark","@meispshfeng") > 0
end

sgs.ai_dont_hurt_to["meispshengguangjiahu"] = function(self, to, from)
    return donor_call(to,"getMark","@meispniangzhaoyunmark") >= 2
end

sgs.ai_dont_hurt_to["kejieguiqideng"] = function(self, to, from)
    return donor_call(to,"getMark","@kedeng") > 0
end

sgs.ai_dont_hurt_to["kexianfenshen"] = function(self, to, from)
    return donor_call(to,"getMark","&kexianfenshen") > 0
end

sgs.ai_dont_hurt_to["kejiexianfenshen"] = function(self, to, from)
    return donor_call(to,"getMark","&kexianfenshen") > 0
end

sgs.ai_dont_hurt_to["SE_Wuwei"] = function(self, to, from)
    return donor_call(to,"getMark","@Wuwei") >= 2
end

sgs.ai_dont_hurt_to["fateheijian"] = function(self, to, from)
    return not (donor_call(to,"getPileCount","fateheijiancards")==0)
end

sgs.ai_dont_hurt_to["betacheater"] = function(self, to, from)
    return not (donor_call(to,"getPileCount","hide")==0)
end

sgs.ai_dont_hurt_to["sandun"] = function(self, to, from)
    return (#donor_call(to,"getEquips")==0) and donor_call(to,"getHandcardNum") > 2
end

sgs.ai_dont_hurt_to["ckshengyu"] = function(self, to, from)
    return donor_call(to,"getMark","ckshengyu-Clear") == 0
end

sgs.ai_dont_hurt_to["danyind"] = function(self, to, from)
    return donor_call(to,"hasSkill","miyund") and donor_call(to,"getMark","danyind-Clear") == 1
end

sgs.ai_dont_hurt_to["langke"] = function(self, to, from)
    return donor_call(to,"getMark","@langke") >= 4
end

sgs.ai_dont_hurt_to["tieren"] = function(self, to, from)
    return donor_call(to,"getMark","@tie") > 0
end

sgs.ai_dont_hurt_to["machiko"] = function(self, to, from)
    return donor_call(to,"getMark","@waked") == 0
end

sgs.ai_dont_hurt_to["s4_s_zhanchuan"] = function(self, to, from)
    return not (donor_call(to,"getPileCount","s4_s_zhanchuan")==0)
end

sgs.ai_dont_hurt_to["heg_qiuan"] = function(self, to, from)
    return (donor_call(to,"getPileCount","heg_qiuan_han")==0)
end

sgs.ai_dont_hurt_to["heg_caiyuan"] = function(self, to, from)
    return donor_call(to,"getMark","&heg_caiyuan+fail-Self" .. sgs.Player_Finish .. "Clear") == 0
end

sgs.ai_dont_hurt_to["TH_guilty"] = function(self, to, from)
    return donor_call(from,"getMark","@TH_Guilty") > 0
end

sgs.ai_ajustdamage_to.shenjun = function(self,from,to,card,nature)
	if donor_call(to,"getGender")~=donor_call(from,"getGender") and nature~="T"
	then return -99 end
end

sgs.ai_ajustdamage_to.fenyong = function(self,from,to,card,nature)
	if donor_call(to,"getMark","@fenyong")>0
	then return -99 end
end

sgs.ai_ajustdamage_to["&dawu"] = function(self,from,to,card,nature)
	if nature~="T"
	then return -99 end
end

sgs.ai_ajustdamage_to["&ollie"] = function(self,from,to,card,nature)
	--return -99
end

sgs.ai_ajustdamage_to.jgyuhuo = function(self,from,to,card,nature)
	if nature=="F" then return -99 end
end

sgs.ai_ajustdamage_to.shixin = function(self,from,to,card,nature)
	if nature=="F" then return -99 end
end

sgs.ai_ajustdamage_to["&jinxuanmu-Clear"] = function(self,from,to,card,nature)
	return -99
end

sgs.ai_ajustdamage_from.tenyearzishou = function(self,from,to,card,nature)
	if donor_call(from,"objectName")~=donor_call(to,"objectName")
	then return -99 end
end

sgs.ai_ajustdamage_from.olzishou = function(self,from,to,card,nature)
	if donor_call(from,"hasFlag","olzishou") and donor_call(from,"objectName")~=donor_call(to,"objectName")
	then return -99 end
end

sgs.ai_ajustdamage_from.olchezheng = function(self,from,to,card,nature)
	if donor_call(from,"getPhase")==sgs.Player_Play and not donor_call(to,"inMyAttackRange",from)
	then return -99 end
end

sgs.ai_ajustdamage_to.shichou = function(self,from,to,card,nature)
	if donor_call(to,"getMark","xhate")>0 then
		for _,p in sgs.list(donor_call(self.room,"getOtherPlayers",to))do
			if donor_call(p,"getMark","hate_"..donor_call(to,"objectName"))>0 and donor_call(p,"getMark","@hate_to")>0
			then return donor_call(self,"ajustDamage",from,p,0,card,nature) end
		end
	end
end

sgs.ai_ajustdamage_to.yuce = function(self,from,to,card,nature)
	if not donor_call(to,"isKongcheng") and donor_call(to,"getHp")>1 then
		if donor_call(self,"isFriend",to,from) then return -1
		else
			if donor_call(from,"objectName")~=donor_call(self.player,"objectName") then
				if donor_call(from,"getHandcardNum")<=2
				then return -1 end
			else
				if getKnownCard(to,self.player,"TrickCard,EquipCard",false,"h")<donor_call(to,"getHandcardNum")
				and getCardsNum("TrickCard,EquipCard",from,self.player)-#donor_call(from,"getEquips")<1
				or getCardsNum("BasicCard",from,self.player)<2
				then return -1 end
			end
		end
	end
end

sgs.ai_ajustdamage_to.shibei = function(self,from,to,card,nature)
	if getKnownCard(from,self.player,"TrickCard")>1
	or getKnownCard(from,self.player,"Slash")>1 and (getKnownCard(from,self.player,"Crossbow")>0 or donor_call(from,"hasSkills",sgs.double_slash_skill))
	or donor_call(from,"hasSkills",sgs.straight_damage_skill)
	or donor_call(self,"getOverflow",from)>0 then
	else
		return donor_call(to,"getMark","shibei")<1
	end
end

sgs.ai_ajustdamage_to.heg_mingshi = function(self,from,to,card,nature)
    -- V2 Mingshi checks the damage source's revealed generals, not equipment counts.
    if from and not donor_call(from,"hasShownAllGenerals") then return -1 end
end

sgs.ai_ajustdamage_to.ranshang = function(self,from,to,card,nature)
	if nature=="F"
	then return 1 end
end

sgs.ai_ajustdamage_to["&kuangfeng"] = function(self,from,to,card,nature)
	if nature=="F"
	then return 1 end
end

sgs.ai_ajustdamage_to.vine = function(self,from,to,card,nature)
	if nature=="F" and not strategy_known(IgnoreArmor(from,to),"IgnoreArmor")
	then return 1 end
end

sgs.ai_ajustdamage_to.gongqing = function(self,from,to,card,nature)
	if donor_call(from,"getAttackRange")>3
	then return 1 end
end

sgs.ai_ajustdamage_from.xionghuo = function(self,from,to,card,nature)
	if donor_call(to,"getMark","@brutal")>0
	then return 1 end
end

sgs.ai_ajustdamage_from.jinjian = function(self,from,to,card,nature)
	if donor_call(from,"getMark","&jinjianreduce-Clear")>0
	then return -donor_call(from,"getMark","&jinjianreduce-Clear") end
	if not donor_call(self,"isFriend",from)
	then return 1 end
end

sgs.ai_ajustdamage_to.jinjian = function(self,from,to,card,nature)
	if donor_call(to,"getMark","&jinjianadd-Clear")>0
	then return donor_call(to,"getMark","&jinjianadd-Clear") end
end

sgs.ai_ajustdamage_from.jieyuan = function(self,from,to,card,nature)
	if not donor_call(self,"beFriend",to,from)
	and (donor_call(to,"getHp")>=donor_call(from,"getHp") or donor_call(from,"getMark","jieyuan_rebel-Keep")>0)
	and (donor_call(from,"getHandcardNum")>=3 or (donor_call(from,"getMark","jieyuan_renegade-Keep")>0 and not donor_call(from,"isNude")))
	then return 1 end
end

sgs.ai_ajustdamage_to.chouhai = function(self,from,to,card,nature)
	if donor_call(to,"isKongcheng")
	then return 1 end
end

sgs.ai_ajustdamage_from.jiedao = function(self,from,to,card,nature)
	if donor_call(from,"getLostHp")>0 and not donor_call(self,"beFriend",to,from)
	then return donor_call(from,"getLostHp") end
end

sgs.ai_ajustdamage_from.lingren = function(self,from,to,card,nature)
	if donor_call(from,"getPhase")==sgs.Player_Play and donor_call(to,"hasFlag","lingren_damage_to")
	then return 1 end
end

sgs.ai_ajustdamage_from.zhuixi = function(self,from,to,card,nature)
	if donor_call(from,"faceUp")~=donor_call(to,"faceUp")
	then return 1 end
end

sgs.ai_ajustdamage_to.zhuixi = function(self,from,to,card,nature)
	if donor_call(from,"faceUp")~=donor_call(to,"faceUp")
	then return 1 end
end

sgs.ai_ajustdamage_from["@luoyi"] = function(self,from,to,card,nature)
	if card and donor_call(card,"isKindOf","Duel")
	then return 1 end
end

sgs.ai_ajustdamage_to.yj_yinfengyi = function(self,from,to,card,nature)
	if card and donor_call(card,"isKindOf","TrickCard")
	then return 1 end
end

sgs.ai_ajustdamage_to.zl_yinfengjia = function(self,from,to,card,nature)
	if card and donor_call(card,"isKindOf","TrickCard")
	then return 1 end
end

sgs.ai_ajustdamage_to.yinshi = function(self,from,to,card,nature)
	if card and hasYinshiEffect(to) and (donor_call(card,"getTypeId")==2 or donor_call(card,"isKindOf","NatureSlash") or nature~="N")
	then return -99 end
end

sgs.ai_ajustdamage_from.wenjiu = function(self,from,to,slash,nature)
	if slash and donor_call(slash,"isKindOf","Slash") and donor_call(slash,"isBlack")
	then return 1 end
end

sgs.ai_ajustdamage_from.shenli = function(self,from,to,slash,nature)
	if slash and donor_call(slash,"isKindOf","Slash") and donor_call(from,"getMark","@struggle")>0
	then return math.min(3,donor_call(from,"getMark","@struggle")) end
end

sgs.ai_ajustdamage_from["&mobileliyong"] = function(self,from,to,slash,nature)
	if slash and donor_call(slash,"isKindOf","Slash")
	then return 1 end
end

sgs.ai_ajustdamage_from.wangong = function(self,from,to,slash,nature)
	if slash and donor_call(slash,"isKindOf","Slash") and donor_call(from,"getMark","&wangong")+donor_call(from,"getMark","wangong")>0
	then return 1 end
end

sgs.ai_ajustdamage_from["&kannan"] = function(self,from,to,slash,nature)
	if slash and donor_call(slash,"isKindOf","Slash")
	then return donor_call(from,"getMark","&kannan") end
end

sgs.ai_ajustdamage_from.jie = function(self,from,to,slash,nature)
	if slash and donor_call(slash,"isKindOf","Slash") and donor_call(slash,"isRed")
	then return 1 end
end

sgs.ai_ajustdamage_from.zonghuo = function(self,from,to,slash,nature)
	if slash and donor_call(slash,"isKindOf","Slash")
	then nature = "F" end
end

sgs.ai_ajustdamage_from.anjian = function(self,from,to,slash,nature)
	if slash and donor_call(slash,"isKindOf","Slash") and not donor_call(to,"inMyAttackRange",from)
	then return 1 end
end

sgs.ai_ajustdamage_to.jiaojin = function(self,from,to,slash,nature)
	if slash and donor_call(slash,"isKindOf","Slash") and donor_call(from,"isMale") and #donor_call(to,"getEquips")>0
	then return -1 end
end

sgs.ai_ajustdamage_from.guding_blade = function(self,from,to,slash,nature)
	if slash and donor_call(slash,"isKindOf","Slash") and donor_call(to,"isKongcheng")
	then return 1 end
end
end

-- R28 source default priority and target-revision callbacks. Repeated source
-- assignments intentionally keep the final body (kuanggu, shuangxiong).
do
    sgs.ai_card_priority=sgs.ai_card_priority or {}
    sgs.ai_target_revises=sgs.ai_target_revises or {}
sgs.ai_card_priority.jianying = function(self,card,v)
	if donor_call(self.player,"getMark","JianyingSuit")==donor_call(card,"getSuit")+1
	or donor_call(self.player,"getMark","JianyingNumber")==donor_call(card,"getNumber")
	then return 10 end
end

sgs.ai_card_priority.yanxiao = function(self,card,v)
	if donor_call(card,"isKindOf","YanxiaoCard") and donor_call(self.player,"containsTrick","YanxiaoCard")
	then v = 0.10 end
end

sgs.ai_card_priority.luanji = function(self,card,v)
	if donor_call(card,"isKindOf","ArcheryAttack")
	then return 6 end
end

sgs.ai_card_priority.sp_moonspear = function(self,card,v)
	if donor_call(card,"isBlack") and donor_call(self.player,"getPhase")==sgs.Player_NotActive
	then return 5 end
end

sgs.ai_card_priority.moon_spear = function(self,card,v)
	if donor_call(card,"isBlack") and donor_call(self.player,"getPhase")==sgs.Player_NotActive
	then return 5 end
end

sgs.ai_card_priority.shuangxiong = function(self,card,v)
	if donor_call(card,"isKindOf","Duel")
	then return 6.3 end
end

sgs.ai_card_priority.cihuai = function(self,card,v)
	if donor_call(card,"isKindOf","Slash")
	and donor_call(self.player,"getMark","@cihuai")>0
	then return 9 end
end

sgs.ai_card_priority.danshou = function(self,card,v)
	if (donor_call(card,"isDamageCard") or sgs.dynamic_value.damage_card[donor_call(card,"getClassName")])
	and not donor_call(self.player,"hasSkill","jueqing")
	then v = 0 end
end

sgs.ai_card_priority.kuanggu = function(self,card,v)
	if donor_call(card,"isKindOf","Peach")
	then v = 1.09 end
end

sgs.ai_card_priority.kofkuanggu = function(self,card,v)
	if donor_call(card,"isKindOf","Peach")
	then v = 1.09 end
end

sgs.ai_card_priority.zhulou = function(self,card,v)
	if self.useValue
	and donor_call(card,"isKindOf","Weapon")
	then v = 2 end
end

sgs.ai_card_priority.taichen = function(self,card,v)
	if self.useValue
	and donor_call(card,"isKindOf","Weapon")
	then v = 2 end
end

sgs.ai_card_priority.qiangxi = function(self,card,v)
	if self.useValue
	and donor_call(card,"isKindOf","Weapon")
	then v = 2 end
end

sgs.ai_card_priority.kurou = function(self,card,v)
	if self.useValue
	and donor_call(card,"isKindOf","Crossbow")
	then return 9 end
end

sgs.ai_card_priority.yizhong = function(self,card,v)
	if self.useValue
	and donor_call(card,"isKindOf","Armor")
	then v = 2 end
end

sgs.ai_card_priority.bazhen = function(self,card,v)
	if self.useValue
	and donor_call(card,"isKindOf","Armor")
	then v = 2 end
end

sgs.ai_card_priority.kuanggu = function(self,card,v)
	if self.useValue
	and donor_call(card,"isKindOf","Shit")
	and donor_call(card,"getSuit")~=sgs.Card_Spade
	then v = 0.1 end
end

sgs.ai_card_priority.jizhi = function(self,card,v)
	if self.useValue
	and donor_call(card,"isKindOf","TrickCard")
	then v = v+3 end
end

sgs.ai_card_priority.nosjizhi = function(self,card,v)
	if self.useValue
	and donor_call(card,"isNDTrick")
	then v = v+4 end
end

sgs.ai_card_priority.shuangxiong = function(self,card,v)
	if self.useValue
	and table.contains(donor_call(card,"getSkillNames"), "shuangxiong")
	then v = 6 end
end

sgs.ai_card_priority.wumou = function(self,card,v)
	if self.useValue and donor_call(card,"isNDTrick") and not donor_call(card,"isKindOf","AOE")
	and not (donor_call(card,"isKindOf","Duel") and donor_call(self.player,"hasUsed","WuqianCard"))
	then v = 1 end
end

sgs.ai_card_priority.tenyearchouhai = function(self,card,v)
	if self.useValue
	and donor_call(self.player,"getHandcardNum")<=1
	then v = 1 end
end

sgs.ai_card_priority.chouhai = function(self,card,v)
	if self.useValue
	and donor_call(self.player,"hasFlag","canshi")
	and donor_call(self.player,"getHandcardNum")<=2
	then v = 1 end
end

sgs.ai_card_priority.canshi = function(self,card,v)
	if self.useValue and donor_call(self.player,"hasFlag","canshi")
	then v = v-2 end
end

sgs.ai_card_priority.halberd = function(self,card,v)
	if self.useValue and donor_call(card,"isKindOf","Slash")
	and donor_call(self.player,"isLastHandCard",card)
	then v = 10 end
end

sgs.ai_card_priority.spear = function(self,card)
	if table.contains(donor_call(card,"getSkillNames"), "spear")
	then
		if self.useValue
		then return -1 end
		return -0.2
	end
end

sgs.ai_card_priority.jie = function(self,card)
	if donor_call(card,"isKindOf","Slash") and donor_call(card,"isRed")
	then return 0.16 end
end

sgs.ai_card_priority.chongzhen = function(self,card)
	if table.contains(donor_call(card,"getSkillNames"), "longdan")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_card_priority.fuhun = function(self,card)
	if table.contains(donor_call(card,"getSkillNames"), "fuhun")
	then
		if self.useValue
		then return donor_call(self.player,"getPhase")==sgs.Player_Play and 1 or -1 end
		return donor_call(self.player,"getPhase")==sgs.Player_Play and 0.06 or -0.05
	end
end

sgs.ai_card_priority.jiang = function(self,card)
	if donor_call(card,"isKindOf","Slash") and donor_call(card,"isRed")
	then return 0.05 end
end

sgs.ai_card_priority.wushen = function(self,card)
	if donor_call(card,"isKindOf","Slash") and donor_call(card,"getSuit")==sgs.Card_Heart
	then return 0.03 end
end

sgs.ai_card_priority.olwushen = function(self,card)
	if donor_call(card,"isKindOf","Slash") and donor_call(card,"getSuit")==sgs.Card_Heart
	then return 0.03 end
end

sgs.ai_card_priority.lihuo = function(self,card)
	if table.contains(donor_call(card,"getSkillNames"), "lihuo")
	then return -0.02 end
end

sgs.ai_card_priority.mingzhe = function(self,card)
	if donor_call(card,"isRed") then return donor_call(self.player,"getPhase")~=sgs.Player_NotActive and 0.05 or -0.05 end
end

sgs.ai_card_priority.zenhui = function(self,card)
	if donor_call(card,"isBlack") and (donor_call(card,"isKindOf","Slash") or donor_call(card,"isNDTrick"))
	and donor_call(card,"getTargetModExtra",self.player)<1
	and not donor_call(self.player,"hasFlag","zenhui")
	then return 0.1 end
end

sgs.ai_target_revises.god_diagram = function(to,card)
	if donor_call(card,"isKindOf","Slash")
	then return true end
end

sgs.ai_target_revises.vine = function(to,card)
	if donor_call(card,"isKindOf","SavageAssault")
	or donor_call(card,"isKindOf","ArcheryAttack")
	or donor_call(card,"isKindOf","Chuqibuyi")
	or donor_call(card,"objectName")=="slash"
	then return true end
end

sgs.ai_target_revises["dream"] = function(to,card)
	if donor_call(to,"isLocked",card) then return true end
end

sgs.ai_target_revises.huoshou = function(to,card)
	if donor_call(card,"isKindOf","SavageAssault")
	then return true end
end

sgs.ai_target_revises.danlao = function(to,card,self,use)
	if donor_call(card,"isKindOf","TrickCard") and donor_call(use.to,"length")>1
	and not donor_call(self,"isFriend",to)
	then return true end
end

sgs.ai_target_revises.xiemu = function(to,card,self,use)
	if donor_call(card,"getTypeId")>0 and donor_call(card,"isBlack") and donor_call(self,"isEnemy",to)
	and donor_call(to,"getMark","@xiemu_"..donor_call(self.player,"getKingdom"))>0
	and not(donor_call(self,"isWeak",to) and donor_call(card,"isDamageCard"))
	then return true end
end

sgs.ai_target_revises.juxiang = function(to,card)
	if donor_call(card,"isKindOf","SavageAssault")
	then return true end
end

sgs.ai_target_revises.manyi = function(to,card)
	if donor_call(card,"isKindOf","SavageAssault")
	then return true end
end

sgs.ai_target_revises.olzhennan = function(to,card)
	if donor_call(card,"isKindOf","SavageAssault")
	then return true end
end

sgs.ai_target_revises.tenyearzongshi = function(to,card)
	if (donor_call(card,"isKindOf","DelayedTrick") or not donor_call(card,"isBlack") and not donor_call(card,"isRed"))
	and donor_call(to,"getPhase")==sgs.Player_NotActive and donor_call(to,"getHandcardNum")>=donor_call(to,"getMaxCards")
	then return true end
end

sgs.ai_target_revises["@late"] = function(to,card,self)
	return donor_call(card,"isKindOf","Slash") or donor_call(card,"isNDTrick")
end

sgs.ai_target_revises.noswuyan = function(to,card,self)
	return donor_call(card,"isNDTrick") and self.player~=to
	and not donor_call(self,"hasJueqingEffect",self.player,to)
end

sgs.ai_target_revises.wuyan = function(to,card,self)
	return donor_call(card,"isNDTrick") and donor_call(card,"isDamageCard")
	and not donor_call(self,"hasJueqingEffect",self.player,to)
end
end

-- R28 full fixed default use-revision bodies. Construction remains readonly;
-- evaluating an alternative never issues an action receipt or pays its cost.
do
    local nullable={getSameEquip=true,setStrategyCardFlag=true,addStrategyPlayerMark=true}
    -- Like donor_call, except the nullable methods skip strategy_call: they may
    -- legitimately return nil and must not be remapped to strategy marks/flags.
    -- A nil receiver is an unsupported signal here rather than a Lua error.
    local function revision_call(object,method,...)
        if nullable[method] then
            if not object or type(object[method])~="function" then ai_unsupported("shared revision method is unavailable",method) end
            local value=object[method](object,...)
            if AIUnsupported.is(value) then error(value,0) end
            return value
        end
        return checked_strategy_call(object,method,...)
    end
    local function r28_find_skill(self,name)
        for _,player in ipairs(revision_call(self.room,"getAlivePlayers")) do
            if revision_call(player,"hasSkill",name) then return player end
        end
    end
    sgs.ai_use_revises=sgs.ai_use_revises or {}
sgs.ai_use_revises.god_sword = function(self,card,use)
	if revision_call(card,"isKindOf","Slash") then
		revision_call(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end

sgs.ai_use_revises.qinggang_sword = function(self,card,use)
	if revision_call(card,"isKindOf","Slash") then
		revision_call(self,"setStrategyCardFlag",card,"Qinggang",true)
	end
end

sgs.ai_use_revises.wuyan = function(self,card,use)
	if revision_call(card,"isKindOf","SavageAssault") then
		local menghuo = r28_find_skill(self,"huoshou")
		if menghuo and (not revision_call(menghuo,"hasSkill","wuyan") or revision_call(self,"hasJueqingEffect",menghuo))
		then else return false end
	elseif revision_call(card,"isKindOf","AOE") then
		if revision_call(self,"hasHuangenEffect",self.friends_noself)
		then else return false end
	elseif revision_call(card,"isNDTrick") and revision_call(card,"isDamageCard")
	and not revision_call(self,"hasJueqingEffect",self.player)
	then return false end
end

sgs.ai_use_revises.noswuyan = function(self,card,use)
	if revision_call(card,"isKindOf","AOE") then
		if revision_call(self,"hasHuangenEffect",self.friends_noself)
		then else return false end
	elseif revision_call(card,"isKindOf","AmazingGrace") then use.card = card
	elseif revision_call(card,"isKindOf","GlobalEffect") then
		if revision_call(self.player,"isWounded") or revision_call(self.player,"hasSkills","nosjizhi|jizhi")
		then use.card = card else return false end
	elseif revision_call(card,"isNDTrick") and not revision_call(card,"targetFixed")
	then use.card = nil return false end
end

sgs.ai_use_revises.luanji = function(self,card,use)
	if revision_call(card,"isKindOf","AOE") and revision_call(self.player,"getRole")=="lord" and strategy_known(self.world.turn_count,"turncount")<2 and math.random()>0.7
	then revision_call(self,"addStrategyPlayerMark",self.player,"AI_fangjian-Clear",1) end
end

sgs.ai_use_revises.nosgongqi = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard") and revision_call(self,"getSameEquip",card)
	and revision_call(self,"slashIsAvailable",nil,false)
	then return false end
end

sgs.ai_use_revises.xiaoji = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard") and revision_call(self,"evaluateArmor",card)>-5
	then use.card = card return true end
end

sgs.ai_use_revises.kofxiaoji = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard") and revision_call(self,"evaluateArmor",card)>-5
	then use.card = card return true end
end

sgs.ai_use_revises.yongsi = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard") and revision_call(self,"getOverflow")<2
	then return false end
end

sgs.ai_use_revises.qixi = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard")
	and revision_call(card,"isBlack")
	then
		local same = revision_call(self,"getSameEquip",card)
		if same and revision_call(same,"isBlack")
		then return false end
	end
end

sgs.ai_use_revises.duanliang = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard")
	and revision_call(card,"isBlack")
	then
		local same = revision_call(self,"getSameEquip",card)
		if same and revision_call(same,"isBlack")
		then return false end
	end
end

sgs.ai_use_revises.yinling = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard")
	and revision_call(card,"isBlack")
	then
		local same = revision_call(self,"getSameEquip",card)
		if same and revision_call(same,"isBlack")
		then return false end
	end
end

sgs.ai_use_revises.guose = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard")
	and revision_call(card,"getSuit")==sgs.Card_Diamond
	then
		local same = revision_call(self,"getSameEquip",card)
		if same and revision_call(same,"getSuit")==sgs.Card_Diamond
		then return false end
	end
end

sgs.ai_use_revises.longhun = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard")
	and revision_call(card,"getSuit")==sgs.Card_Diamond
	then
		local same = revision_call(self,"getSameEquip",card)
		if same and revision_call(same,"getSuit")==sgs.Card_Diamond
		then return false end
	end
end

sgs.ai_use_revises.jijiu = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard") and revision_call(card,"isRed") then
		local same = revision_call(self,"getSameEquip",card)
		if same and revision_call(same,"isRed") then return false end
	end
end

sgs.ai_use_revises.guidao = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard")
	and revision_call(card,"isBlack")
	then
		local same = revision_call(self,"getSameEquip",card)
		if same and revision_call(same,"isBlack")
		then return false end
	end
end

sgs.ai_use_revises.junxing = function(self,card,use)
	if revision_call(card,"isKindOf","EquipCard")
	and revision_call(self,"getSameEquip",card)
	then return false end
end

sgs.ai_use_revises.jiehuo = function(self,card,use)
	if (revision_call(card,"isKindOf","Weapon") or revision_call(card,"isKindOf","OffensiveHorse"))
	and revision_call(self.player,"getMark","jiehuo")<0 and revision_call(card,"isRed")
	then return false end
end

sgs.ai_use_revises.zhulou = function(self,card,use)
	if revision_call(card,"isKindOf","Weapon") and revision_call(self,"getSameEquip",card)
	then return false end
end

sgs.ai_use_revises.taichen = function(self,card,use)
	if revision_call(card,"isKindOf","Weapon")
	then
		local same = revision_call(self,"getSameEquip",card)
		if same
		then
			local source_cost = revision_call(same,"getEffectiveId")
            -- Fixed yitian V2 retained the history key but removed the V1
            -- TaichenCard constructor. Source Card_Parse returns nil, then
            -- aiUseCard(nil).card errors. Do not invent a proxy as that card.
            ai_unsupported("fixed source TaichenCard parse is unavailable before aiUseCard(nil).card", "source.TaichenCard")
			if revision_call(self,"aiUseCard",same).card
			then return false end
		end
	end
end

-- R33: these fresh V1 cards are hypotheses in a synchronous revise call tree,
-- not activations. Keep the scope outside AI memory/state and always unwind it.
local r33_revise_scopes = setmetatable({}, {__mode="k"})
local r33_revise_classes = {qiangxi="QiangxiCard",tiaoxin="TiaoxinCard"}
local function r33_revise_scope(self,skill,class)
    local scope=r33_revise_scopes[self]
    if not scope then return nil end
    local request=self.request
    if request~=scope.request or request.viewer~=scope.viewer
        or request.decision_id~=scope.decision or request.state_revision~=scope.revision
        or self.player:objectName()~=scope.viewer then
        ai_unsupported("use-revise hypothesis belongs to an expired request","use_revise.scope")
    end
    if scope.skill~=skill or r33_revise_classes[skill]~=class then return nil end
    return scope
end
function SmartAIView:isUseReviseSkillEvaluation(skill,class)
    local scope=r33_revise_scope(self,skill,class)
    return scope~=nil and self._strategy_evaluation==true
end
function SmartAIView:evaluateUseReviseSkillCard(skill,class,costs)
    if not r33_revise_scope(self,skill,class) then
        ai_unsupported("use-revise hypothesis has no active source call tree","use_revise.scope")
    end
    local card=self:evaluateSkillCard("use_revise:"..skill,class,costs)
    if AIUnsupported.is(card) then error(card,0) end
    -- Actual Card_Parse nil must reach the donor's ordinary nil-index path.
    if card==nil then return nil end
    if not AIValue.isCard(card) or not card:isEvaluationOnly()
        or card:getClassName()~=class or card:getSkillName(false)~=skill then
        ai_unsupported("use-revise evaluator returned a different policy card","use_revise.scope")
    end
    return card
end
local function r33_revise_plan(self,skill,class,costs,use)
    local request=self.request
    if type(request)~="table" or type(request.viewer)~="string"
        or request.viewer~=self.player:objectName() or request.decision_id==nil
        or request.state_revision==nil then
        ai_unsupported("use-revise current owner request is unavailable","use_revise.scope")
    end
    local previous=r33_revise_scopes[self]
    r33_revise_scopes[self]={request=request,viewer=request.viewer,
        decision=request.decision_id,revision=request.state_revision,skill=skill}
    local ok,result=pcall(function()
        local card=self:evaluateUseReviseSkillCard(skill,class,costs)
        -- Source aiUseCard(nil) returns nil, then the revise indexes .card.
        if card==nil then return nil end
        local answer=self:aiUseCard(card,use)
        if AIUnsupported.is(answer) then error(answer,0) end
        return answer
    end)
    r33_revise_scopes[self]=previous
    if not ok then error(result,0) end
    return result
end

sgs.ai_use_revises.qiangxi = function(self,card,use)
	if revision_call(card,"isKindOf","Weapon")
	and not revision_call(self.player,"hasUsed","QiangxiCard")
	then
		local same = revision_call(self,"getSameEquip",card)
		if same
		then
			same = r33_revise_plan(self,"qiangxi","QiangxiCard",{revision_call(same,"getEffectiveId")})
			if same.card and revision_call(same.card,"subcardsLength")==1
			then return false end
		end
	end
end

sgs.ai_use_revises.paoxiao = function(self,card,use)
	if revision_call(card,"isKindOf","Crossbow")
	then return false end
end

sgs.ai_use_revises.tenyearpaoxiao = function(self,card,use)
	if revision_call(card,"isKindOf","Crossbow")
	then return false end
end

sgs.ai_use_revises.olpaoxiao = function(self,card,use)
	if revision_call(card,"isKindOf","Crossbow")
	then return false end
end

sgs.ai_use_revises.nosfuhun = function(self,card,use)
	if revision_call(card,"isKindOf","Crossbow")
	then return false end
end

sgs.ai_use_revises.zhiheng = function(self,card,use)
	if revision_call(card,"isKindOf","Weapon")
	and not revision_call(card,"isKindOf","Crossbow")
	and revision_call(self,"getSameEquip",card)
	and not revision_call(self.player,"hasUsed","ZhihengCard")
	then return false end
end

sgs.ai_use_revises.jilve = function(self,card,use)
	if revision_call(card,"isKindOf","Weapon")
	and revision_call(self.player,"getMark","&bear")>0
	and not revision_call(card,"isKindOf","Crossbow")
	and revision_call(self,"getSameEquip",card)
	and not revision_call(self.player,"hasUsed","ZhihengCard")
	then return false end
end

sgs.ai_use_revises.tiaoxin = function(self,card,use)
	if revision_call(card,"isKindOf","DefensiveHorse") then
		local dummy = {isDummy=true,to=AIList.new({})}
		dummy.defHorse = true
		if r33_revise_plan(self,"tiaoxin","TiaoxinCard",{},dummy).card
		then return false end
	end
end
end

-- R28 ordinary default nullification and can-damage-HP hooks. The current
-- AmazingGrace use comes from the projected use history.
do
    -- Legacy getUseStruct(trick) reads Room tag "UseHistory"..trick:toString(). A
    -- physical trick's string is its id; a virtual one is the only use with its face.
    local function r28_grace_use(self,trick)
        local rows=self.world.use_history
        if type(rows)~="table" then ai_unsupported("use history is not projected","smart.AmazingGrace.use") end
        local face=rawget(trick,"_view")
        if type(face)~="table" then ai_unsupported("AmazingGrace face is unknown","smart.AmazingGrace.use") end
        local row
        if face.virtual_card==false and type(face.id)=="number" and face.id>=0 then
            row=rows[tostring(face.id)]
        elseif face.virtual_card==true then
            for _,use in pairs(rows) do
                local card=type(use)=="table" and use.card
                if type(card)=="table" and card.virtual_card==true and card.name==face.name
                    and card.suit==face.suit and card.number==face.number and card.skill_name==face.skill_name then
                    if row then ai_unsupported("virtual AmazingGrace use is ambiguous","smart.AmazingGrace.use") end
                    row=use
                end
            end
        end
        if type(row)~="table" or not AIValue.isList(row.to) then
            ai_unsupported("current AmazingGrace use is not projected","smart.AmazingGrace.use")
        end
        local targets=AIList.new({})
        for _,name in ipairs(row.to) do
            if type(name)~="string" then ai_unsupported("malformed AmazingGrace target","smart.AmazingGrace.targets") end
            targets:append(strategy_known(self.room:findPlayerByObjectName(name,true),"AmazingGrace target"))
        end
        return {to=targets}
    end
    -- Legacy counts Room tag "AmazingGrace". This engine keeps the shown cards under
    -- "AmazingGrace"..toString(), and its one Lua writer (s2_lixian) only copies the
    -- empty tag back, so the donor's list is always empty.
    local function r28_grace_ids(self,trick) return {} end
    local function r28_grace_card(self,trick,id)
        ai_unsupported("AmazingGrace card face is not projected","smart.AmazingGrace.card")
    end
    sgs.ai_nullification=sgs.ai_nullification or {}
    sgs.ai_can_damagehp=sgs.ai_can_damagehp or {}
sgs.ai_nullification.FireAttack = function(self,trick,from,to,positive,null_num)
	if donor_call(to,"isKongcheng") or donor_call(from,"isKongcheng") or self.player==from and donor_call(self.player,"getHandcardNum")==1
	then return false
	elseif positive then
		if donor_call(self,"isEnemy",from)
		and donor_call(self,"isFriend",to) then
			if donor_call(from,"getHandcardNum")>2
			or donor_call(to,"isChained") and not donor_call(self,"isGoodChainTarget",to,trick,from)
			then return true end
		end
	else

	end
end

sgs.ai_nullification.ExNihilo = function(self,trick,from,to,positive,null_num)
	if positive then
		if donor_call(self,"isEnemy",to) and (donor_call(self,"isWeak",to) or donor_call(to,"hasSkills",sgs.cardneed_skill) or ZishuEffect(to)>0 or donor_call(to,"hasSkill","manjuan"))
		and not(self.role=="rebel" and not donor_call(self,"hasExplicitRebel") and strategy_known(self.world.turn_count,"turncount")<1 and donor_call(donor_call(self.room,"getCurrent"),"getNextAlive")~=self.player)
		then return true end--敌方在虚弱、需牌技、漫卷中使用无中生有->命中
	else

	end
end

sgs.ai_nullification.IronChain = function(self,trick,from,to,positive,null_num)
	if positive then
		if donor_call(self,"isEnemy",from) and donor_call(self,"isFriend",to)
		and not donor_call(to,"isChained") and donor_call(self,"hasHeavyDamage",from,nil,to,"F")
		then return true end--铁索连环的目标有加伤->命中
	else

	end
end

sgs.ai_nullification.Duel = function(self,trick,from,to,positive,null_num)
	if positive then
		if to==self.player then
			if donor_call(self,"hasSkills",sgs.masochism_skill)
			and (donor_call(self.player,"getHp")>1 or donor_call(self,"getCardsNum","Analeptic,Peach")>0)
			then elseif donor_call(self,"getCardsNum","Slash")<1 then return true end
		end
		if donor_call(to,"getHp")<2 and donor_call(self,"getRoleEstimate",to)=="rebel"
		and donor_call(self,"getRoleEstimate",from)=="rebel"
		then return end
		if donor_call(self,"isFriend",to) then
			if donor_call(self,"isEnemy",from) and donor_call(self,"isWeak",to)
			or (donor_call(self,"isWeak",to) or null_num>1 or donor_call(self,"getOverflow")>0 or not donor_call(self,"isWeak"))
			then return true end
		end
	else
		if donor_call(self,"isEnemy",to)
		and (donor_call(self,"isWeak",to) or null_num>1 or donor_call(self,"getOverflow")>0 or not donor_call(self,"isWeak"))
		then return true end
	end
end

sgs.ai_nullification.Indulgence = function(self,trick,from,to,positive,null_num)
	if positive then
		if donor_call(self,"isFriend",to)
		and not(donor_call(self,"hasGuanxingEffect",to) or donor_call(to,"isSkipped",sgs.Player_Play))
		then--无观星友方判定区有乐不思蜀->视“突袭”、“巧变”情形而定
			if donor_call(to,"getHp")-donor_call(to,"getHandcardNum")>=2
			or donor_call(to,"getHp")>2 and donor_call(to,"hasSkill","tuxi")
			or null_num<2 and donor_call(self,"getOverflow",to)<-1
			or not donor_call(to,"isKongcheng") and donor_call(to,"hasSkill","qiaobian")
			and (donor_call(to,"containsTrick","supply_shortage") or donor_call(self,"willSkipDrawPhase",to))
			then else return true end
		end
	else

	end
end

sgs.ai_nullification.SupplyShortage = function(self,trick,from,to,positive,null_num)
	if positive then
		if donor_call(self,"isFriend",to)
		and not(donor_call(self,"hasGuanxingEffect",to) or donor_call(to,"isSkipped",sgs.Player_Draw))
		then--无观星友方判定区有兵粮寸断->视“鬼道”、“天妒”、“溃围”、“巧变”情形而定
			if donor_call(self,"hasSkills","guidao|tiandu",to)
			or donor_call(to,"getMark","@kuiwei")<1
			or null_num<=1 and donor_call(self,"getOverflow",to)>1
			or not donor_call(to,"isKongcheng") and donor_call(to,"hasSkill","qiaobian")
			and (donor_call(to,"containsTrick","indulgence") or donor_call(self,"willSkipPlayPhase",to))
			then else return true end
		end
	else

	end
end

sgs.ai_nullification.GodSalvation = function(self,trick,from,to,positive,null_num)
	if positive then
		if donor_call(self,"isEnemy",to) and donor_call(self,"isWeak",to)
		and donor_call(to,"getLostHp")>0
		then return true end
	else

	end
end

sgs.ai_nullification.AmazingGrace = function(self,trick,from,to,positive,null_num)
	if positive then
		local use = r28_grace_use(self,trick)
		if donor_call(use.to,"last")~=to and donor_call(self,"isEnemy",to) then
			for i=1,null_num do
				local NP = donor_call(to,"getNextAlive",i)
				while not donor_call(use.to,"contains",NP) do
					NP = donor_call(NP,"getNextAlive")
				end
				if donor_call(self,"isFriend",NP) then
					local t = {p=0,e=0,s=0,a=0,c=0,i=0}
					for _,id in sgs.list(r28_grace_ids(self,trick))do
						local c = r28_grace_card(self,trick,id)
						if isCard("Peach",c,NP) then t.p = t.p+1 end
						if isCard("ExNihilo",c,NP) then t.e = t.e+1 end
						if isCard("Snatch",c,NP) then t.s = t.s+1 end
						if isCard("Analeptic",c,NP) then t.a = t.a+1 end
						if isCard("Crossbow",c,NP) then t.c = t.c+1 end
						if isCard("Indulgence",c,NP) then t.i = t.i+1 end
						if donor_call(c,"isDamageCard") then
							for _,friend in sgs.list(self.friends)do
								if donor_call(to,"canUse",c,friend) and donor_call(to,"getHandcardNum")>2
								and donor_call(self,"ajustDamage",to,friend,1,c)>1
								then return true end
							end
						end
					end
					if t.p==1 and donor_call(to,"getHp")<donor_call(self,"getBestHp",to)
					or t.p>0 and (donor_call(self,"isWeak",to) or donor_call(NP,"getHp")<donor_call(self,"getBestHp",NP) and donor_call(self,"getOverflow",NP)<1)
					then return true end
					if t.p<1 and not donor_call(self,"willSkipPlayPhase",NP) then
						if t.p>0 then
							if donor_call(NP,"hasSkills","nosjizhi|jizhi|nosrende|zhiheng")
							or donor_call(NP,"hasSkill","rende") and not donor_call(NP,"hasUsed","RendeCard")
							or donor_call(NP,"hasSkill","jilve") and donor_call(NP,"getMark","&bear")>0
							then return true end
						else
							for _,enemy in sgs.list(self.enemies)do
								if t.i>0 and not donor_call(self,"willSkipPlayPhase",enemy,true)
								or t.s>0 and donor_call(to,"distanceTo",enemy)==1 and (donor_call(self,"willSkipPlayPhase",enemy,true) or donor_call(self,"willSkipDrawPhase",enemy,true))
								or t.a>0 and (donor_call(enemy,"hasWeapon","Axe") or getCardsNum("Axe",enemy,self.player)>0)
								then return true
								elseif t.c>0
								and getCardsNum("Slash",enemy,self.player)>2 then
									for _,friend in sgs.list(self.friends)do
										if donor_call(enemy,"distanceTo",friend)==1
										and donor_call(self,"slashIsEffective",donor_call(self,"cloneEvaluationCard","slash"),friend,enemy)
										then return true end
									end
								end
							end
						end
					end
				end
			end
		end
	else

	end
end

sgs.ai_can_damagehp.zili = function(self,from,card,to)
	return not(donor_call(self,"isWeak",to) or donor_call(to,"hasSkill","paiyi"))
	and donor_call(self,"ajustDamage",from,to,1,card)>0
end

sgs.ai_can_damagehp.wumou = function(self,from,card,to)
	return donor_call(to,"getMark","&wrath")<7 and not donor_call(self,"isWeak",to)
	and donor_call(self,"ajustDamage",from,to,1,card)>0
end

sgs.ai_can_damagehp.longhun = function(self,from,card,to)
	return donor_call(to,"getHp")>1 and donor_call(self,"ajustDamage",from,to,1,card)~=0
end

sgs.ai_can_damagehp.tianxiang = function(self,from,card,to)
	local d = {damage=1}
	d.nature = card and sgs.card_damage_nature[donor_call(card,"getClassName")] or sgs.DamageStruct_Normal
	return donor_call(self,"canTianxiangHypothesis",d,sgs.Card_MethodDiscard)
end

sgs.ai_nullification.kongcheng = function(self,trick,from,to,positive,null_num)
	if positive and from and donor_call(self,"isEnemy",from) and donor_call(self,"isFriend",to)
	and donor_call(self,"getRoleEstimate",from)~="neutral"
	and donor_call(self.player,"getHandcardNum")<=null_num
	then return true end
end

sgs.ai_nullification.wumou = function(self,trick,from,to,positive,null_num)
	if donor_call(self.player,"getMark","&wrath")<1 and donor_call(self,"isWeak")
	or not donor_call(self,"isWeak") and donor_call(to,"objectName")==donor_call(self.player,"objectName") and donor_call(trick,"isDamageCard")
	then return false end
end
end

-- Core loads before common; freeze the actual audited ordinary providers.
-- Later arbitrary per-instance overrides cannot acquire known-nil permission.
for _, name in ipairs({"damageStruct", "damageIsEffective", "needToLoseHp", "hasTrickEffective", "aoeIsEffective", "canAvoidAOE", "hasHuangenEffect", "doDisCard", "canDamageHp", "canLoseHp", "isGoodHp", "loseEquipEffect", "needToThrowArmor", "hasWizard", "hasGuanxingEffect", "hasSkills"}) do
    if type(SmartAIView[name]) == "function" then source_nil_providers[name] = SmartAIView[name] end
end

-- R43 fixed Inovation source helper. Duplicate self is the actual donor ABI.
do
local function query(object, method, ...)
    local provider = object and object[method]
    if type(provider) ~= "function" then ai_unsupported("Inovation helper unavailable", method) end
    local value = provider(object, ...)
    if AIUnsupported.is(value) then error(value, 0) end
    if value == nil and not SmartAIView.isKnownNilStrategyResult(object, method, provider) then
        ai_unsupported("Inovation helper fact unknown", method)
    end
    return value
end
function SmartAIView:getMostWeakEnemyToDamage(self, targets, nature)
	local min = 100
	local target
	if not nature then nature = sgs.DamageStruct_Normal end
	for _,p in sgs.list(targets) do
		if query(self,"isEnemy",p) and query(self,"damageIsEffective",p,nature) and query(p,"getHp") * 2 + query(p,"getHandcardNum") < min then
			target = p
			min =  query(p,"getHp") * 2 + query(p,"getHandcardNum")
		end
	end
	return target
end

end


-- R47e: complete fixed touhouproject-ai.lua:100-126 common helper.
-- The who argument is source-unused. Preserve the enemy-lord precedence bug.
do
 local function query(object,key,...)
  local provider=object and object[key]
  if type(provider)~='function'then ai_unsupported('Touhou chain recovery helper unavailable',key)end
  local value=provider(object,...)
  if AIUnsupported.is(value)then error(value,0)end
  if value==nil then ai_unsupported('Touhou chain recovery input unknown',key)end
  if key=='hasSkill' and value==false then
   local complete=object.areSkillsComplete
   if type(complete)~='function'then ai_unsupported('Touhou chain recovery skill absence unknown',key)end
   local known=complete(object)
   if AIUnsupported.is(known)then error(known,0)end
   if known~=true then ai_unsupported('Touhou chain recovery skill absence unknown',key)end
  end
  return value
 end
 function SmartAIView:GoodChaintoRecover(who)
  who=who or self.player
  local ChainedFriends,ChainedEnemies={},{}
  local hasQED=0
  for _,p in sgs.qlist(query(self.room,'getAlivePlayers'))do
   if query(p,'hasSkill','TH_qed')then hasQED=hasQED+(query(self,'isFriend',p)and 1 or -1)end
   if query(p,'isChained')and query(p,'isWounded')then
    if query(self,'isFriend',p)then table.insert(ChainedFriends,p)
    else table.insert(ChainedEnemies,p)end
   end
  end
  local good=#ChainedFriends-#ChainedEnemies
  for _,friend in ipairs(ChainedFriends)do
   if query(friend,'getRole')=='lord'then good=good+1 end
   if query(friend,'getHp')<=2 then good=good+1 end
   if query(friend,'hasSkill','TH_tianjiedetaozi')and query(friend,'getLostHp')>1 then good=good+1 end
  end
  for _,enemy in ipairs(ChainedEnemies)do
   if query(enemy,'getRole')=='lord'and not query(self.player,'getRole')=='renegade'then good=good-1 end
   if query(enemy,'getHp')==1 then good=good-1 end
   if query(enemy,'hasSkill','TH_tianjiedetaozi')and query(enemy,'getLostHp')>1 then good=good-1 end
  end
  return good+hasQED>=0
 end
end
-- End R47e GoodChaintoRecover.


-- R49: fixed Touhou common helpers; complete bodies on lawfully known inputs.
do
 local nullable={}
 local function known(v,k)
  if AIUnsupported.is(v)then error(v,0)end
  if v==nil then ai_unsupported('Touhou fixed source input unknown',k)end
  return v
 end
 local function q(o,k,...)
  local f=o and o[k]
  if type(f)~='function'then ai_unsupported('Touhou fixed source helper unavailable',k)end
  local v=f(o,...)
  if AIUnsupported.is(v)then error(v,0)end
  if v==nil then
   if nullable[k]==f or SmartAIView.isKnownNilStrategyResult(o,k,f)then return nil end
   if k=='getWeapon' and AIValue.isPlayer(o)and AIValue.isList(o._view.equips)then return nil end
   if k=='getLord' then
    local w=rawget(o,'_world');local players=rawget(o,'_players')
    if type(w)~='table'or not AIValue.isList(w.player_order)or type(players)~='table'then ai_unsupported('Touhou lord absence unknown',k)end
    for _,name in ipairs(w.player_order)do
     local p=players[name];local v=type(p)=='table'and rawget(p,'_view')
     if type(v)~='table'or type(v.lord)~='boolean'then ai_unsupported('Touhou lord absence unknown',k)end
    end
    return nil
   end
   ai_unsupported('Touhou fixed source input unknown',k)
  end
  if (k=='hasSkill'or k=='hasSkills'or k=='hasLordSkill')and v==false and known(o:areSkillsComplete(),k)~=true then
   ai_unsupported('Touhou fixed source skill absence unknown',k)
  end
  return v
 end
 local function global(name,...)
  local f=_G[name];if type(f)~='function'then ai_unsupported('Touhou global helper unavailable',name)end
  return known(f(...),name)
 end
 local function role(self)return known(self.role,'owner role')end
 local function count(self,name)return known(q(self,'getRoleCounts')[name],'role count '..name)end
 local function kingdoms(self)
  local list=nil -- The ordered kingdom catalogue is not projected.
  if not AIValue.isList(list)then ai_unsupported('Touhou ordered native kingdom catalogue unknown','kingdoms')end
  local copy={};for i,v in ipairs(list)do if type(v)~='string'then ai_unsupported('Touhou kingdom catalogue malformed','kingdoms')end;copy[i]=v end
  return copy
 end
 local function hegemony(self)
  local enabled=self.world and self.world.enable_hegemony
  if type(enabled)~='boolean'then ai_unsupported('Touhou EnableHegemony unknown','EnableHegemony')end
  return enabled
 end
function SmartAIView:TheWuhun(player, onlylord, damage)
	player = player or self.player
	damage = damage or 1
	if q(player,"hasSkill","wuhun") and q(player,"getHp") <= damage and not global("isLord",player) then
		local lastone = true
		if (role(self) == "lord" or role(self) == "loyalist") and count(self,"rebel") + count(self,"renegade") > 0 then
			lastone = false
		elseif role(self) == "renegade" and q(self.player,"aliveCount") > 2 then
			lastone = false
		elseif role(self) == "rebel" and count(self,"loyalist")  + count(self,"renegade") > 0 then
			lastone = false
		end
		if not lastone then
			local maxnightmare = 0
			local nightmareplayer = {}
			for _, ap in sgs.qlist(q(self.room,"getAlivePlayers")) do
				maxnightmare = math.max(q(ap,"getMark","@nightmare"), maxnightmare)
			end
			if maxnightmare == 0 then return 0 end
			for _, np in sgs.qlist(q(self.room,"getAlivePlayers")) do
				if q(np,"getMark","@nightmare") == maxnightmare then
					table.insert(nightmareplayer, np)
				end
			end
			if #nightmareplayer == 0 then return 0 end
			local isfriendlord, isfriend, isenemy, isenemylord
			for _, p in ipairs(nightmareplayer) do
				if q(p,"isLord") then
					if q(self,"isFriend",p) then isfriendlord = true
					elseif role(self) == "renegade" then isfriendlord = true
					else isenemylord = true end
				else
					if q(self,"isFriend",p) then isfriend = true
					else isenemy = true end
				end
			end
			if q(self,"isFriend",player) then
				if isenemylord then return 2
				elseif isenemy then return 1
				elseif isfriend then return -1
				elseif isfriendlord then return -2
				else return 0 end
			else
				if isenemylord then return 2 end
				if isenemy then return 1 end
				if isfriend then return -1 end
				if isfriendlord then return -2 end
			end
		end
	end
	return 0
end

function SmartAIView:saveplayer(player)
	player = player or self.player
	if q(player,"hasSkills","jijiu|buyi|jiefan")  and q(player,"getHandcardNum") > 0  then return true end
	if q(player,"hasSkill","chunlao") and q(q(player,"getPile","wine"),"length") > 0 then return true end
	if q(player,"hasSkill","TH_chihuo") and q(player,"getCardCount",true) > 0 then return true end
	return
end

nullable.saveplayer=SmartAIView.saveplayer
source_nil_providers.saveplayer=SmartAIView.saveplayer

function SmartAIView:undeadplayer(player)
	player = player or self.player
	if (q(player,"hasSkill","longhun") and q(player,"getHp")==1) or
		(q(player,"hasSkill","niepan") and q(player,"getMark","@nirvana") > 0 and q(player,"getHp")==1) or
		(q(player,"hasSkill","fuli") and q(player,"getMark","@laoji") > 0 and q(player,"getHp")==1) or
		(q(player,"hasSkill","TH_Phoenixrevive") and q(player,"getMark","Phoenixrevive")<1 and q(player,"getHp")==1) then
		return true
	end
	return
end


nullable.undeadplayer=SmartAIView.undeadplayer
source_nil_providers.undeadplayer=SmartAIView.undeadplayer

function SmartAIView:UseAoeSkillValue(element, players, card)
	element = element or sgs.DamageStruct_Normal
	local friends = {}
	local enemies = {}
	local good = 0

	players = players or sgs.QList2Table(q(self.room,"getOtherPlayers",self.player))

	for _, ap in ipairs(players) do
		if q(self,"isFriend",ap) then table.insert(friends, ap)
		else table.insert(enemies, ap) end
	end

	good = (#enemies - #friends) * 2
	if #enemies == 0 then return -100 end
	if element == sgs.DamageStruct_Thunder then
		for _, ap in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if q(ap,"hasSkill","TH_yuyiruokong") then
				if q(self,"isFriend",ap) then good = good + q(ap,"getCardCount",true)
				else good = good - q(ap,"getCardCount",true)
				end
			end
		end
	end
	if element == sgs.DamageStruct_Fire then
		for _,ap in sgs.qlist(q(self.room,"getAlivePlayers")) do
			if q(ap,"hasSkill","TH_Meltdown") then
				for _, friend in ipairs(friends) do
					if q(friend,"getHandcardNum") > 0 then good = good - 0.5 end
				end
				for _, enemy in ipairs(enemies) do
					if q(enemy,"getHandcardNum") > 0 then good = good + 0.5 end
				end
			end
		end
	end




	if q(self.player,"hasSkill","TH_hongsehuanxiangxiang") then good = good + 1 end

	if q(self.player,"getRole") == "renegade" then good = good + 0.5 end
	if q(self.player,"getRole") == "rebel" then good = good + 0.8 end

	local who
	for _, player in ipairs(players) do
		if q(player,"isChained") and q(self,"damageIsEffective",player, element) and not who then who = player end
		local value = 0
		if q(player,"getRole") == "lord" then value = value - 0.5 end
		if not q(self,"damageIsEffective",player, element) then
			value = value + 1
			if q(self,"isEnemy",player) and #enemies == 1 or q(self,"isFriend",player) and #friends == 1 then value = value + 100 end
		end
		if q(player,"getHp") == 1 and q(self,"getAllPeachNum") == 0 then
			if q(player,"getRole") == "lord" then value = value - 100 else value = value - 2 end
		end
		if q(self,"needToLoseHp",player, self.player) then value = value + 0.5 end
		if q(self,"undeadplayer",player) then value = value + 0.5 end
		if q(self,"saveplayer",player) then value = value + 0.5 end

		if q(self,"isFriend",player) then good = good + value else good = good - value end
	end





	if who and not q(self.player,"hasSkill","jueqing") and (element == sgs.DamageStruct_Thunder or element == sgs.DamageStruct_Fire) then
		-- local damage = {}
		-- damage.from = self.player
		-- damage.to = who
		-- damage.nature = element
		-- damage.card = card
		-- damage.damage = 1
		-- good = good + q(self,"isGoodChain",damage)
		if q(self,"isGoodChainTarget",who, element, self.player, 1) then
		good = good + 1
		end
	end
	return good
end

function SmartAIView:CanUseAttackSkill(player)
	if not player then ai_unsupported("Touhou nil-player source console diagnostic unavailable", "CanUseAttackSkill.nil_player") end
	if q(player,"hasSkills","huashen|gongxin|mingce|ganlu|anxu|TH_SpearTheGungnir|TH_wugufengdeng|TH_Miracle_GodsWind|TH_Wonder_NwOBNS|TH_rengui|TH_nanti|"..
	"TH_LifeGame|TH_thethiefmarisa|TH_BadFortune|TH_Hypnosis|TH_TerribleSouvenir|TH_liandemaihuo|TH_GreatestCaution|TH_GalacticIllusion|"..
	"TH_CosmicMarionnette|TH_PhilosophersStone|TH_MoreUnscientific") then return true end
	if q(player,"hasSkill","shuangxiong") and q(q(player,"property","shuangxiong_colors_turn"),"toString") ~= "" and q(player,"getHandcardNum") > 3 then return true end
	if q(player,"hasSkills","rende|nosrende|jieyin|zhiheng|nosguose|guhuo|quhu|tianyi|dimeng|shenji|manjuan|dahe|TH_wenwenxinwen|TH_MasterSpark") and q(player,"getHandcardNum") > 1 then return true end
	if q(player,"hasSkills","fanjian|nosfanjian|qingnang|noslijian|lijian|qice|TH_huaidiao|TH_shengyusi|TH_Unscientific|TH_Science") and q(player,"getHandcardNum") > 0 then return true end
	if q(player,"hasSkills","luanji|paoxiao|jizhi|qixi|xianzhen|yinling") and q(player,"getHandcardNum") > 3 then return true end
	if q(player,"hasSkills","juejing|fuluan|TH_chihuo") and q(q(player,"getCards","he"),"length") > 2 then return true end
	if q(player,"hasSkill","TH_fengyitianxiang") and global("getCardsNum","FireSlash", player, self.player) > 1 then return true end

	if q(player,"hasSkill","TH_huanzang") and global("getCardsNum","Slash", player, self.player) > 0 then
		for _,friend in ipairs(self.friends) do
			if q(player,"canSlash",friend, nil, true) and q(player,"distanceTo",friend) == 1 then
				return true
			end
		end
	end
	if q(player,"hasSkill","TH_GreatestTreasure") and q(player,"getHandcardNum") > 1 then
		for _,friend in ipairs(self.friends) do
			if q(player,"distanceTo",friend) == 1 then return true end
		end
	end
	if q(player,"hasSkills","tieji|wushuang|liegong|mengjin|lieren|tiaoxin|pojun|nosqianxi|TH_Eternal|TH_aoyi_sanbubisha|TH_hengong") and q(player,"getHandcardNum") > 1 then
		for _,friend in ipairs(self.friends) do
			if q(player,"canSlash",friend, nil, true) then
				return true
			end
		end
	end
	if q(player,"hasSkill","lihun") then
		for _,friend in ipairs(self.friends) do
			if q(friend,"getHandcardNum") > 4 and q(friend,"isMale") then
				return true
			end
		end
	end
	if (q(player,"hasSkill","TH_moshenfusong") and q(player,"getMark","@TH_moshenfusong") > 0) or q(player,"hasSkill","TH_jiushizhiguang") then
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"getHp") == 1 then
				return true
			end
		end
		return
	end
	if q(player,"hasSkill","yanxiao") then
		local yanxiao_on
		for _,enemy in ipairs(self.enemies) do
			if q(enemy,"containsTrick","indulgence") or q(enemy,"containsTrick","supply_shortage") then
				yanxiao_on = true
			end
		end
		if yanxiao_on then
			for _, card in sgs.qlist(q(player,"getCards","he")) do
				if q(card,"getSuit") == 3 then return true end
			end
		end
		return
	end
	if q(player,"hasSkill","nosguose") and q(self,"hasSuit","diamond", true, player) then return true end
	if q(player,"hasSkill","duanliang") and q(self,"hasSuit","club", true, player) then return true end
	if (q(player,"hasSkill","wansha") and q(player,"getMark","@chaos") > 0) or (q(player,"hasSkill","shenfen") and q(player,"getMark","@wrath") > 5) then
		for _, p in ipairs(self.friends) do
			if q(p,"getHp") == 1 then return true end
		end
	end

	if q(player,"hasSkill","jilve") and q(player,"getMark","@bear") > 3 and q(player,"getMark","@waked") > 0 then return true end
	if q(player,"hasSkill","TH_fanhundie") and q(player,"getMark","@TH_fhdonce") > 0 then return true end
	if q(player,"hasSkill","jixi") and q(q(player,"getPile","field"),"length") > 1 and q(player,"getMark","@waked") > 0 then return true end
	if q(player,"hasSkill","paiyi") and q(q(player,"getPile","power"),"length") > 1 and q(player,"getMark","@waked") > 0 then return true end
	if q(player,"hasSkill","yinling") and q(q(player,"getPile","junwei_equip"),"length") < 5 then return true end
	if q(player,"hasSkill","qixing") and q(q(player,"getPile","stars"),"length") > 0 then return true end
	if q(player,"hasSkill","TH_yinhexi") and q(q(player,"getPile","TH_yinhexi_pile"),"length") > 6 then return true end
	if q(player,"hasSkills","kurou") and q(player,"getHp") > 2 then return true end
	if q(player,"hasSkills","nosshangshi|shangshi") and q(player,"getLostHp") > 2 then return true end
	if q(player,"hasSkill","qiangxi") and (q(player,"getHp") > 2 or q(player,"getWeapon")) then return true end
	if q(player,"hasSkill","TH_menghuanpaoying") and q(player,"getLostHp") > 0 then return true end
	if q(player,"hasSkill","TH_huaimiepaohou") and q(player,"hasFlag","TH_huaimiepaohou_on") then return true end
	if q(player,"hasSkill","TH_Nuclear") and q(player,"getMark","@TH_nuclear") > 9 then return true end
	if q(player,"hasSkill","TH_ZombieFairy") and q(q(self.room,"getAlivePlayers"),"length") ~= q(q(self.room,"getPlayers"),"length") then return true end
	if q(player,"hasSkill","TH_guanglongzhitanxi") and q(player,"getMark","@TH_yuyi") > 1 then return true end
	if q(player,"hasSkill","TH_suiyue") and q(player,"getMark","@TH_suiyue") > 0 then return true end

	return
end

nullable.CanUseAttackSkill=SmartAIView.CanUseAttackSkill
source_nil_providers.CanUseAttackSkill=SmartAIView.CanUseAttackSkill

local function TableRemoveOne(atable, str)
	local new = {}
	for _, t in ipairs(atable) do
		if t ~= str then table.insert(new, t) end
	end
	return new
end
local function TableContainsOne(atable, str)
	for _, t in ipairs(atable) do
		if t == str then return true end
	end
	return
end

function SmartAIView:askForKingdom()
	local kingdoms = kingdoms(self)
	kingdoms = TableRemoveOne(kingdoms, "god")
	if hegemony(self) then
		kingdoms = { "wei", "shu", "wu", "qun" }
		return kingdoms[math.random(1, #kingdoms)]
	end

	local lord = q(self.room,"getLord")
	if not lord then return kingdoms[math.random(1, #kingdoms)] end
	if q(self.player,"isLord") then
		local baka = true
		if TableContainsOne(kingdoms, "TH_kingdom_baka") then
			for _,ap in sgs.qlist(q(self.room,"getAlivePlayers")) do
				if q(ap,"hasSkill","TH_allbaka") then
					if q(ap,"getRole") == "rebel" then baka = false
					else return "TH_kingdom_baka" end
				end
			end
		end
		if not baka then
			kingdoms = TableRemoveOne(kingdoms, "TH_kingdom_baka")
		end
		return kingdoms[math.random(1, #kingdoms)]
	end
	if q(self.player,"getRole") == "rebel" then
		local baka = true
		if TableContainsOne(kingdoms, "TH_kingdom_baka") then
			for _,ap in sgs.qlist(q(self.room,"getAlivePlayers")) do
				if q(ap,"hasSkill","TH_allbaka") then
					if q(ap,"getRole") == "rebel" then return "TH_kingdom_baka"
					else baka = false end
				end
			end
		end
		if q(lord,"hasSkill","TH_allbaka") or not baka then
			kingdoms = TableRemoveOne(kingdoms, "TH_kingdom_baka")
		end
		if q(lord,"hasLordSkill","xueyi") then
			kingdoms = TableRemoveOne(kingdoms, "qun")
		end
		if q(lord,"hasLordSkill","shichou") then
			kingdoms = TableRemoveOne(kingdoms, "shu")
		end
		if q(lord,"hasLordSkill","TH_lordskill") then
			return kingdoms[math.random(1, #kingdoms)]
		end
		if TableContainsOne(kingdoms, q(lord,"getKingdom")) then return q(lord,"getKingdom")
		else return kingdoms[math.random(1, #kingdoms)]
		end
	end
	if q(self.player,"getRole") == "loyalist" or q(self.player,"getRole") == "renegade" then
		if (q(lord,"hasLordSkill","jijiang") or q(lord,"hasLordSkill","shichou")) and TableContainsOne(kingdoms, "shu") then
			return "shu"
		elseif (q(lord,"hasLordSkill","hujia") or q(lord,"hasLordSkill","songwei")) and TableContainsOne(kingdoms, "wei") then
			return "wei"
		elseif (q(lord,"hasLordSkill","jiuyuan") or q(lord,"hasLordSkill","zhiba")) and TableContainsOne(kingdoms, "wu") then
			return "wu"
		elseif (q(lord,"hasLordSkill","huangtian") or q(lord,"hasLordSkill","xueyi") or q(lord,"hasLordSkill","baonue")) and TableContainsOne(kingdoms, "qun") then
			return "qun"
		end
		local baka = true
		if TableContainsOne(kingdoms, "TH_kingdom_baka") then
			for _,ap in sgs.qlist(q(self.room,"getAlivePlayers")) do
				if q(ap,"hasSkill","TH_allbaka") then
					if (q(ap,"getRole") == "loyalist" or q(ap,"getRole") == "lord") and TableContainsOne(kingdoms, "TH_kingdom_baka") then
						return "TH_kingdom_baka"
					else baka = false end
				end
			end
		end
		if not baka then
			kingdoms = TableRemoveOne(kingdoms, "TH_kingdom_baka")
		end
		if q(lord,"hasLordSkill","TH_lordskill") then
			return kingdoms[math.random(1, #kingdoms)]
		end
		if TableContainsOne(kingdoms, q(lord,"getKingdom")) then return q(lord,"getKingdom")
		else return kingdoms[math.random(1, #kingdoms)] end
	end
	return kingdoms[math.random(1, #kingdoms)]
end
end
-- End R49 Touhou common helpers.

-- R54 ordinary SmartAI card-choice strategy method, distinct from a native
-- CardChosen request handler. Fixed smart-ai.lua:3403-3623 branch order;
-- shared counter/numeric consumption and foreign keep-cache paths fail closed.
do
local function r54_call(object,method,...)
 local provider=object and object[method]
 if type(provider)~='function'then ai_unsupported('ordinary card-choice dependency unavailable',method)end
 local value=provider(object,...)
 if AIUnsupported.is(value)then error(value,0)end
 if value==nil and not SmartAIView.isKnownNilStrategyResult(object,method,provider)then
  ai_unsupported('ordinary card-choice input unknown',method)
 end
 return value
end
local function r54_throw_prefix(reason)
 if type(reason)~='string'then
  if reason==nil then error('table index is nil',0)end
  ai_unsupported('ordinary card-choice reason is outside native string domain','askForCardChosen.throwData')
 end
 -- SmartAI bumps its global throw statistics here; this observer keeps its own
 -- throw history from the events it sees instead.
end
local function r54_callback(fn,...)
 local result=fn(...);if AIUnsupported.is(result)then error(result,0)end;return result
end
local function r54_owner_sort(self,who,cards,inverse)
 if who~=self.player then
  -- The exact source returns before cache/toUse access for fewer than two
  -- cards. Only current public equips plus authenticated foreign bindings
  -- qualify; all cache-dependent lists retain their existing unknown result.
  if #cards<2 then return cards end -- Sorting fewer than two cards keeps their order.
  ai_unsupported('foreign AI keep cache and toUse ordering not observed','askForCardChosen.ownerSort')
 end
 return r54_call(self,'sortByKeepValue',cards,inverse)
end
local function r54_owner_keep(self,who,card)
 if who~=self.player then ai_unsupported('foreign AI keep cache not observed','askForCardChosen.ownerKeep')end
 return r54_call(self,'getKeepValue',card)
end
function SmartAIView:getCardRandomly(who,flags,no_dis)
	if who==self.player then
		for _,c in sgs.list(r54_call(self,"sortByKeepValue",r54_call(who,"getCards",flags)))do
			local id = r54_call(c,"getEffectiveId")
			if not self.disabled_ids:contains(id)
			and (no_dis~=false or r54_call(self.player,"canDiscard",who,id))
			then return id end
		end
		return -1
	end
	local ids, r54_by_id = {}, {}
	for _,c in sgs.qlist(r54_call(who,"getCards",flags))do
		local id = r54_call(c,"getEffectiveId")
		r54_by_id[id] = c
		if not self.disabled_ids:contains(id)
		and (no_dis~=false or r54_call(self.player,"canDiscard",who,id))
		then table.insert(ids,id) end
	end
	if #ids<1 then return -1 end
	local mr = math.random(1,#ids)
	local id = ids[mr]
	if r54_call(r54_by_id[id],"isKindOf","SilverLion")
	and r54_call(who,"isWounded") and r54_call(self,"isEnemy",who) and r54_call(who,"hasArmorEffect","SilverLion") then
		if mr~=#ids then id = ids[mr+1] elseif mr>1 then id = ids[mr-1] end
	end
	return id
end

function SmartAIView:askForCardChosen(who,flags,reason,method)
	r54_call(self,"refreshDiscardPreferences",true)
	local no_dis,cid = false,-1
	if method~=sgs.Card_MethodDiscard then no_dis = true
	else r54_throw_prefix(reason) end
	for _,s in sgs.list(sgs.getPlayerSkillList(who))do
		cid = sgs.ai_skill_cardchosen["#"..r54_call(s,"objectName")]
		if type(cid)=="function" then
			cid = r54_callback(cid,self,who,flags,method)
			if cid then
				if type(cid)~="number" then cid = r54_call(cid,"getEffectiveId") end
				if not self.disabled_ids:contains(cid) then return cid end
				return cid
			end
		end
	end
	cid = sgs.ai_skill_cardchosen[string.gsub(reason,"%-","_")]
	if type(cid)=="function" then
		cid = r54_callback(cid,self,who,flags,method)
		if cid then
			if type(cid)~="number" then cid = r54_call(cid,"getEffectiveId") end
			if not self.disabled_ids:contains(cid) then return cid end
		end
	elseif type(cid)=="number" then
		ai_unsupported("ordinary numeric callback actual registry consumption is not synchronized", "askForCardChosen.numericConsume")
		if not self.disabled_ids:contains(cid) then return cid end
	end
	if reason=="dismantlement" and sgs.getMode=="02_1v1"
	and sgs.GetConfig("1v1/Rule","Classical")=="2013" then
		local cards,jink = r54_call(who,"getHandcards"),nil
		for _,c in sgs.qlist(cards)do
			if self.disabled_ids:contains(r54_call(c,"getId")) then continue end
			if isCard("Peach",c,who) then return r54_call(c,"getId") end
			if isCard("Jink",c,who) then jink = r54_call(c,"getId") end
		end
		if jink then return jink end
		for _,c in sgs.list(r54_call(self,"sortByKeepValue",cards,true))do
			jink = r54_call(c,"getEffectiveId")
			if self.disabled_ids:contains(jink)
			then continue end
			return jink
		end
	end
	if r54_call(self,"isFriend",who) then
		if flags:contains("j") and not(r54_call(who,"hasSkill","qiaobian") and r54_call(who,"getHandcardNum")>0) then
			local lightning,indulgence,supply_shortage
			for _,trick in sgs.list(r54_call(who,"getJudgingArea"))do
				local id = r54_call(trick,"getEffectiveId")
				if r54_call(self,"doDisCard",who,id,no_dis) then
					if r54_call(trick,"isDamageCard") then lightning = id
					elseif r54_call(trick,"isKindOf","Indulgence") then indulgence = id
					elseif not r54_call(trick,"isKindOf","Disaster") then supply_shortage = id end
				end
			end
			if lightning and r54_call(self,"hasWizard",self.enemies) then return lightning
			elseif supply_shortage and r54_call(who,"getHp")>=r54_call(who,"getHandcardNum") then return supply_shortage
			elseif indulgence then return indulgence
			elseif supply_shortage then return supply_shortage end
		end
		if flags:contains("e") then
			cid = r54_call(who,"getEquips")
			cid = r54_owner_sort(self,who,cid)
			for _,e in sgs.list(cid)do
				if r54_call(self,"doDisCard",who,r54_call(e,"getId"),no_dis)
				then return r54_call(e,"getId") end
			end
			if #cid>0 and r54_call(self,"loseEquipEffect",who) and r54_call(self,"isWeak",who)
			and r54_call(self,"doDisCard",who,cid[1]:getId(),no_dis)
			then return cid[1]:getId() end
		end
		if flags:contains("j") then
			for _,id in sgs.list(r54_call(who,"getJudgingAreaID"))do
				if r54_call(self,"doDisCard",who,id,no_dis)
				then return id end
			end
		end
		if flags:contains("h") and r54_call(who,"getHandcardNum")>0 then
			-- 如果是帮友方，检查明置牌，避免拿走valuable的牌（如果是获得的话）
			if no_dis and flags:contains("h") then
				local display_cards = getDisplayCards(who, self.player)
				local display_count = #display_cards
				local unknown_count = r54_call(who,"getHandcardNum") - display_count
				
				-- 如果有未知牌（暗牌），优先选择未知牌
				if unknown_count > 0 then
					return r54_call(self,"getCardRandomly",who, "h", no_dis)
				end
				
				-- 如果都是明置牌，选择价值最低的（使用getKeepValue评估）
				if display_count > 0 then
					local low_value_cards = {}
					for _, dc in ipairs(display_cards) do
						local card_id = r54_call(dc,"getEffectiveId")
						if not self.disabled_ids:contains(card_id) then
							local value = r54_owner_keep(self,who,dc)
							table.insert(low_value_cards, {card_id = card_id, value = value})
						end
					end
					
					if #low_value_cards > 0 then
						table.sort(low_value_cards, function(a, b) return a.value < b.value end)
						return low_value_cards[1].card_id
					end
				end
			end
			
			return r54_call(self,"getCardRandomly",who,"h",no_dis)
		end
	else
		if flags:contains("e") then
			cid = r54_call(self,"getDangerousCard",who)
			if cid and r54_call(self,"doDisCard",who,cid,no_dis)
			then return cid end
			cid = r54_call(self,"getValuableCard",who)
			if cid and r54_call(self,"doDisCard",who,cid,no_dis)
			then return cid end
			cid = r54_call(who,"getEquips")
			for _,e in sgs.list(r54_owner_sort(self,who,cid,true))do
				if r54_call(self,"doDisCard",who,r54_call(e,"getId"),no_dis) then return r54_call(e,"getId") end
			end
		end
		if flags:contains("h")
		and r54_call(who,"getHandcardNum")<=2
		and r54_call(self,"doDisCard",who,"h",no_dis) then
			if r54_call(who,"hasSkills","jijiu|qingnang|qiaobian|jieyin|beige|buyi|manjuan")
			then return r54_call(self,"getCardRandomly",who,"h",no_dis) end
			
			-- 敌方手牌少，优先选择明置牌中价值高的（顺拆/过河时优先拆重要牌）
			local display_cards = getDisplayCards(who, self.player)
			if #display_cards > 0 then
				local valuable_cards = {}
				for _, dc in ipairs(display_cards) do
					local card_id = r54_call(dc,"getEffectiveId")
					if not self.disabled_ids:contains(card_id) then
						local value = r54_owner_keep(self,who,dc)
						table.insert(valuable_cards, {card_id = card_id, value = value})
					end
				end
				
				if #valuable_cards > 0 then
					-- 选择价值最高的明置牌
					table.sort(valuable_cards, function(a, b) return a.value > b.value end)
					return valuable_cards[1].card_id
				end
			end
		end
		if flags:contains("j") then
			local lightning,yanxiao
			for _,trick in sgs.qlist(r54_call(who,"getJudgingArea"))do
				local id = r54_call(trick,"getEffectiveId")
				if r54_call(trick,"isDamageCard") and r54_call(self,"doDisCard",who,id,no_dis) then lightning = id
				elseif r54_call(trick,"isKindOf","YanxiaoCard") and r54_call(self,"doDisCard",who,id,no_dis) then yanxiao = id end
			end
			if lightning and r54_call(self,"getFinalRetrial",who)>1 then return lightning
			elseif yanxiao then return yanxiao end
		end
		if flags:contains("h") and r54_call(self,"doDisCard",who,"h",no_dis) then
			-- 检查明置牌：如果是获得牌的情况(no_dis=true)，优先选择valuable的明置牌
			-- 如果是弃牌的情况(no_dis=false)，优先弃掉valuable的明置牌
			local display_cards = getDisplayCards(who, self.player)
			if #display_cards > 0 then
				local valuable_cards = {}
				for _, dc in ipairs(display_cards) do
					local card_id = r54_call(dc,"getEffectiveId")
					if not self.disabled_ids:contains(card_id) then
						-- 使用getKeepValue评估卡牌价值
						local value = r54_owner_keep(self,who,dc)
						table.insert(valuable_cards, {card_id = card_id, value = value})
					end
				end
				
				if #valuable_cards > 0 then
					-- 如果是获得牌(顺手牵羊)，选择最valuable的
					if no_dis then
						table.sort(valuable_cards, function(a, b) return a.value > b.value end)
						return valuable_cards[1].card_id
					-- 如果是弃牌(过河拆桥)，也优先拆valuable的
					else
						table.sort(valuable_cards, function(a, b) return a.value > b.value end)
						return valuable_cards[1].card_id
					end
				end
			end
			
			-- 原有逻辑
			if r54_call(who,"getHandcardNum")<=2 or r54_call(who,"hasSkills",sgs.cardneed_skill)
			or (r54_call(who,"getHandcardNum")==1 and r54_call(who,"getHp")<=2 and r54_call(self,"getDefenseSlash",who)<3)
			then return r54_call(self,"getCardRandomly",who,"h",no_dis) end
		end
	end
	return r54_call(self,"getCardRandomly",who,flags,no_dis)
end

-- No-result callbacks are ordinary nil; these full source helpers return an
-- integer (including -1) on all normal paths, so no nil-provider exemption.
end
-- End R54 ordinary card-choice helper.

-- Source strategies sometimes sort a Lua array for its side effect.  Keep that
-- operation explicit; ordinary sort methods continue to return a fresh list.
local function sort_in_place(self, method, values, ...)
    local ordered = AIValue.callKnown(self, method, values, ...)
    for index, value in ipairs(ordered) do values[index] = value end
    return values
end
for _, method in ipairs({"sort", "sortByKeepValue", "sortByUseValue",
    "sortByUsePriority", "sortByDynamicUsePriority", "sortByCardNeed"}) do
    SmartAIView[method .. "InPlace"] = function(self, values, ...)
        return sort_in_place(self, method, values, ...)
    end
end

-- These public queries require a result.  Absence-returning lookups and planning
-- APIs keep their nil contract; audited source callbacks retain their provider
-- identity and may also return an ordinary no-result nil.
local required_strategy_queries = {
    isWeak=true, getOverflow=true, getCardsNum=true, getAllPeachNum=true,
    getUseValue=true, getKeepValue=true, getUsePriority=true,
    getDynamicUsePriority=true, getDefense=true, getDefenseSlash=true,
    getBestHp=true, getLeastHandcardNum=true, getMaxCards=true,
    getKnownNum=true, getKnownCard=true, getExpectedJinkNum=true,
    getFriends=true, getEnemies=true, getChainedEnemies=true,
    needKongcheng=true, needToLoseHp=true, needToThrowArmor=true,
    needToThrowLastHandcard=true, hasManjuanEffect=true,
    hasZhenguEffect=true, hasJieyingyEffect=true, hasCrossbowEffect=true,
    damageIsEffective=true, slashIsEffective=true, slashProhibit=true,
    canAttack=true, canSlash=true, canPindian=true, canDraw=true,
    canLiegong=true, isTiaoxinTarget=true, isLordHealthy=true,
    hasTuntianEffect=true, canCanmou=true, objectiveLevel=true,
    isRolePredictable=true, sort=true, sortByKeepValue=true,
    sortByUseValue=true, sortByUsePriority=true, sortByCardNeed=true,
    sortByDynamicUsePriority=true
}
for method in pairs(required_strategy_queries) do
    local provider = rawget(SmartAIView, method)
    if type(provider) == "function" then
        local checked = function(self, ...)
            local result = table.pack(provider(self, ...))
            if AIUnsupported.is(result[1]) then error(result[1], 0) end
            if result[1] == nil and not SmartAIView.isKnownNilStrategyResult(self, method, provider) then
                ai_unsupported("required strategy query is unknown", method)
            end
            return table.unpack(result, 1, result.n)
        end
        required_query_providers[checked] = provider
        SmartAIView[method] = checked
    end
end
