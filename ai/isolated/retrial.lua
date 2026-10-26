-- Shared retrial selection over primitive projections, never native CardFilter/Room.
sgs = sgs or {}
sgs.ai_need_retrial = sgs.ai_need_retrial or {}
sgs.ai_need_retrial_func = sgs.ai_need_retrial_func or {}
sgs.ai_judgeGood = sgs.ai_judgeGood or {}
sgs.ai_retrial = sgs.ai_retrial or {}

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

local function note_estimate(self,basis)
    if type(self.useKnowledgeEstimate)=="function" then
        self:useKnowledgeEstimate({value=true,status="estimate",basis=basis,observer=self.player:objectName()},"retrial")
    end
end

-- A public-only FilterSkill model can prove selected foreign filters without
-- invoking another player's callback or reading its private state.
local function public_filter(self, player, card, place)
    if player:objectName()==self.player:objectName() or type(self.publicCardFilterKnowledge)~="function" then return nil end
    local knowledge=self:publicCardFilterKnowledge(card,player,place)
    if type(knowledge)~="table" or (knowledge.status~="exact" and knowledge.status~="unknown") then
        ai_unsupported("public CardFilter knowledge is malformed","CardFilter")
    end
    if knowledge.status=="exact" then
        local filtered=card_view(knowledge.card)
        if not filtered then ai_unsupported("exact public CardFilter has no card","CardFilter") end
        return filtered
    end
end

local function filtered_judge_values(self, player, card, estimate_basis)
    local id, name = card:getEffectiveId(), player:objectName()
    local row = nil -- A filtered judge face is not projected separately.
    if type(row)=="table" and row.complete==true and type(row.card)=="table" then
        if type(row.donor_error_repair)=="string" then note_estimate(self,"donor_error_repair:"..row.donor_error_repair) end
        local value=card_view(row.card)
        return value:getSuit(),value:getNumber(),value:isBlack(),value:isRed()
    end
    local context=self.request and self.request.context or self.world and self.world.decision_context
    local judge=context and context.judge
    local who=judge and (type(judge.who)=="string" and judge.who or type(judge.who)=="table" and judge.who.object_name)
    if who==name and judge.filtered_complete==true then
        local suit,number=lookup(judge.filtered_suit_by_id,id),lookup(judge.filtered_number_by_id,id)
        if finite(suit) and finite(number) then
            local repair=lookup(judge.repair_by_id,id)
            if type(repair)=="string" then note_estimate(self,"donor_error_repair:"..repair) end
            return suit,number,suit==sgs.Card_Spade or suit==sgs.Card_Club or suit==sgs.Card_NoSuitBlack,
                suit==sgs.Card_Heart or suit==sgs.Card_Diamond or suit==sgs.Card_NoSuitRed
        end
    end
    local public=public_filter(self,player,card,sgs.Player_PlaceJudge)
    if public then return public:getSuit(),public:getNumber(),public:isBlack(),public:isRed() end
    local view=rawget(player,"_view")
    local complete=type(view)=="table" and view.skills_complete==true
    local filters=false
    for _, skill in ipairs(player:getSkills() or {}) do
        local is_filter
        if type(skill.inherits)=="function" then is_filter=skill:inherits("FilterSkill") end
        if is_filter==nil then complete=false
        elseif is_filter then filters=true end
    end
    if not filters and complete then return card:getSuit(),card:getNumber(),card:isBlack(),card:isRed() end
    if player:objectName()==self.player:objectName() then
        ai_unsupported("owner CardFilter result is not projected","goodJudge.CardFilter")
    end
    note_estimate(self,estimate_basis or "goodJudge.foreign_filter_public_identity")
    return card:getSuit(),card:getNumber(),card:isBlack(),card:isRed()
end

-- Visible positive skills are conclusive; absence from a partial foreign
-- roster is not. These two policy gates precede/guard distinct donor branches.
local function good_judge_has_skills(self, player, names)
    local value=player:hasSkills(names)
    if AIUnsupported.is(value) then error(value,0) end
    if value==true then return true end
    local complete=type(player.areSkillsComplete)=="function" and player:areSkillsComplete()==true
    if value==false and complete then return false end
    if player:objectName()==self.player:objectName() then
        ai_unsupported("own judgment skill roster is incomplete", "goodJudge.skills")
    end
    note_estimate(self,"goodJudge.unobserved_skill_inactive_prior."..names)
    return false
end

-- Resolve the same lawful filter evidence without reading unused face fields.
-- Filter context values are captured before relationship callbacks, as the
-- source CardFilter result is produced before selecting a predicate branch.
local function r33_good_judge_card(self, player, card, estimate_basis)
    if type(card) == "number" then
        local result = self:CardFilter(card, player)
        if AIUnsupported.is(result) then error(result, 0) end
        return result
    end
    card = card_view(card)
    if not card then ai_unsupported("goodJudge requires an authorized card view", "goodJudge") end
    local id, name = card:getEffectiveId(), player:objectName()
    local row = nil -- A filtered judge face is not projected separately.
    if type(row) == "table" and row.complete == true and type(row.card) == "table" then
        if type(row.donor_error_repair) == "string" then note_estimate(self, "donor_error_repair:" .. row.donor_error_repair) end
        return card_view(row.card)
    end
    local context = self.request and self.request.context or self.world and self.world.decision_context
    local judge = context and context.judge
    local who = judge and (type(judge.who) == "string" and judge.who or type(judge.who) == "table" and judge.who.object_name)
    if who == name and judge.filtered_complete == true then
        local suit, number = lookup(judge.filtered_suit_by_id, id), lookup(judge.filtered_number_by_id, id)
        local repair = lookup(judge.repair_by_id, id)
        if type(repair) == "string" then note_estimate(self, "donor_error_repair:" .. repair) end
        local function required(value, field)
            if not finite(value) then ai_unsupported("filtered judgment " .. field .. " is unknown", "goodJudge." .. field) end
            return value
        end
        return {
            getSuit = function() return required(suit, "suit") end,
            getNumber = function() return required(number, "number") end,
            isBlack = function() local s=required(suit,"suit"); return s==sgs.Card_Spade or s==sgs.Card_Club or s==sgs.Card_NoSuitBlack end,
            isRed = function() local s=required(suit,"suit"); return s==sgs.Card_Heart or s==sgs.Card_Diamond or s==sgs.Card_NoSuitRed end
        }
    end
    local public = public_filter(self, player, card, sgs.Player_PlaceJudge)
    if public then return public end
    local view = rawget(player, "_view")
    local complete = type(view) == "table" and view.skills_complete == true
    local filters = false
    for _, skill in ipairs(player:getSkills() or {}) do
        local is_filter
        if type(skill.inherits) == "function" then is_filter = skill:inherits("FilterSkill") end
        if is_filter == nil then complete=false elseif is_filter then filters=true end
    end
    if not filters and complete then return card end
    if player:objectName() == self.player:objectName() then
        ai_unsupported("owner CardFilter result is not projected", "goodJudge.CardFilter")
    end
    note_estimate(self, estimate_basis or "goodJudge.foreign_filter_public_identity")
    return card
end

function SmartAIView:goodJudge(player, reason, card)
    if not reason then return false end
    local function relation(method)
        local value = self[method](self, player)
        if AIUnsupported.is(value) then error(value, 0) end
        if type(value) ~= "boolean" then ai_unsupported("Judgment relationship is unknown", "goodJudge." .. method) end
        return value
    end
    if good_judge_has_skills(self, player, "qianxi|olqianxi") and not relation("isFriend") then return false end
    card = r33_good_judge_card(self, player, card)
    local function read(method)
        local getter = card and card[method]
        if type(getter) ~= "function" then ai_unsupported("filtered judgment getter is absent", "goodJudge." .. method) end
        local value = getter(card)
        if AIUnsupported.is(value) then error(value, 0) end
        if value == nil then ai_unsupported("filtered judgment value is unknown", "goodJudge." .. method) end
        return value
    end
    if reason == "lightning" and not good_judge_has_skills(self, player, "wuyan") then
        if relation("isFriend") then return not (read("getSuit")==sgs.Card_Spade and read("getNumber")>=2 and read("getNumber")<=9)
        elseif relation("isEnemy") then return read("getSuit")==sgs.Card_Spade and read("getNumber")>=2 and read("getNumber")<=9 end
    elseif reason == "indulgence" then
        if relation("isFriend") then return read("getSuit")==sgs.Card_Heart
        elseif relation("isEnemy") then return read("getSuit")~=sgs.Card_Heart end
    elseif reason == "supply_shortage" then
        if relation("isFriend") then return read("getSuit")==sgs.Card_Club
        elseif relation("isEnemy") then return read("getSuit")~=sgs.Card_Club end
    elseif reason == "black" then
        if relation("isFriend") then return read("isBlack")
        elseif relation("isEnemy") then return read("isRed") end
    end
    return false
end

function SmartAIView:CardFilter(card, owner, place)
    owner=player_view(self,owner)
    if not owner then ai_unsupported("CardFilter owner is unknown","CardFilter") end
    local rows = nil -- Filtered faces are projected on the cards themselves.
    if type(card)=="number" then
        local id=card
        local projected=lookup(rows,id)
        if type(projected)=="table" and projected.complete==true and type(projected.card)=="table" then
            if type(projected.donor_error_repair)=="string" then note_estimate(self,"donor_error_repair:"..projected.donor_error_repair) end
            return card_view(projected.card),true
        end
        -- Search only already disclosed primitive DTOs. Numeric IDs are not
        -- permission to query the Engine, including another player's piles.
        local seen, budget = {}, 4096
        local function find(value, depth)
            if type(value) ~= "table" or seen[value] or depth > 12 or budget <= 0 then return nil end
            seen[value], budget = true, budget - 1
            if (value.effective_id == id or value.id == id)
                and type(value.name) == "string" and type(value.class_name) == "string" then
                return card_view(value)
            end
            for _, child in pairs(value) do
                local found = find(child, depth + 1)
                if found then return found end
            end
        end
        local world = self.world or {}
        -- Filter outputs are deliberately excluded from the identity search:
        -- Judge and Hand can produce different cards for the same physical ID.
        card = find(world.hand_cards, 0) or find(world.self, 0)
            or find(world.players, 0) or find(world.discard_pile, 0)
            or find(facts and facts.notified_piles, 0)
            or find(self.request and self.request.options, 0)
            or find(self.request and self.request.context, 0)
            or find(self._event_input and self._event_input.details, 0)
    else card=card_view(card) end
    if not card then ai_unsupported("CardFilter card identity is not authorized","CardFilter") end
    local row=lookup(rows,card:getEffectiveId())
    if type(row)=="table" and row.complete==true and type(row.card)=="table" then
        if type(row.donor_error_repair)=="string" then note_estimate(self,"donor_error_repair:"..row.donor_error_repair) end
        return card_view(row.card),true
    end
    local public=public_filter(self,owner,card,place or sgs.Player_PlaceJudge)
    if public then return public,true end
    local view=rawget(owner,"_view")
    local complete=view and view.skills_complete==true
    local filters=false
    for _, skill in ipairs(owner:getSkills() or {}) do
        local active
        if type(skill.inherits)=="function" then active=skill:inherits("FilterSkill") end
        if active==nil then complete=false elseif active then filters=true end
    end
    if complete and not filters then return card,true end
    if owner:objectName()==self.player:objectName() then
        ai_unsupported("owner CardFilter place/result is not projected","CardFilter")
    end
    note_estimate(self,"CardFilter.foreign_filter_public_identity")
    return card,false
end

local function scalar(player, method)
    if player and type(player[method]) == "function" then return player[method](player) end
end

local function indulgence_exception(self, judge, hand)
    if hand ~= 0 then return false end
    local skipped = judge.who:isSkipped(sgs.Player_Draw)
    if skipped == nil then return nil end
    if not skipped then return false end
    local who = judge.who
    if who:hasSkill("shenfen") and who:getMark("&wrath") >= 6 then return true end
    if who:hasSkill("jixi") then
        local count = who:getPileCount("field")
        if not finite(count) then return nil end
        if count > 2 then return true end
    end
    if who:hasSkill("lihun") then
        -- The shared helper owns its public/estimated inputs. Preserve the
        -- source's list call and zero draw allowance before later exceptions.
        if self:isLihunTarget(self:getEnemies(who), 0) then return true end
    end
    if who:hasSkill("xiongyi") and who:getMark("@arise") > 0 then return true end
    if who:hasSkill("kurou") then
        local hp = who:getHp()
        if not finite(hp) then return nil end
        if hp >= 3 then return true end
    end
    return false
end

function SmartAIView:needRetrial(judge)
    self.isWeak_judge = false
    judge = normalize(self, judge)
    if not judge or not judge.who or type(judge.good) ~= "boolean" then
        ai_unsupported("Current retrial judgment is unknown", "needRetrial")
    end
    local reason = judge.reason
    local function known_boolean(value, key)
        if type(value) ~= "boolean" then ai_unsupported("Retrial boolean is unknown", "needRetrial." .. key) end
        return value
    end
    local function known_number(value, key)
        if not finite(value) then ai_unsupported("Retrial number is unknown", "needRetrial." .. key) end
        return value
    end
    local lord = self.room and self.room:getLord()
    -- Preserve the legacy early-return order: specific reasons precede hooks.
    if reason == "lightning" then
        -- The publicly identified lord substitutes only for the role==lord
        -- test; do not read a foreign hidden role. Keep each source short circuit.
        if lord and (judge.who:objectName() == lord:objectName()
            or known_boolean(judge.who:isChained(), "lightning.chained")
                and known_boolean(lord:isChained(), "lightning.lord_chained"))
            and known_number(self:objectiveLevel(lord), "lightning.objective") <= 3 then
            if known_boolean(lord:hasArmorEffect("SilverLion"), "lightning.lord_armor")
                and known_number(lord:getHp(), "lightning.lord_hp") >= 2
                and self:isGoodChainTarget(lord, "T") then return false end
            if judge.good then return false end
            return known_boolean(self:damageIsEffective(lord, "T"), "lightning.damage")
        end
        if known_number(judge.who:getHp(), "lightning.hp") > 1
            and known_boolean(judge.who:hasArmorEffect("SilverLion"), "lightning.armor") then return false end
        if known_boolean(self:isFriend(judge.who), "friend") then
            if known_boolean(judge.who:isChained(), "lightning.chained")
                and self:isGoodChainTarget(judge.who, "T", nil, 3) then return false end
        else
            if known_boolean(judge.who:isChained(), "lightning.chained")
                and not self:isGoodChainTarget(judge.who, "T", nil, 3) then return judge.good end
        end
    elseif reason == "indulgence" then
        local hand = scalar(judge.who, "getHandcardNum")
        if not finite(hand) then ai_unsupported("Indulgence hand count is unknown", "needRetrial.indulgence") end
        local exception = indulgence_exception(self, judge, hand)
        if exception == nil then ai_unsupported("Indulgence exception state is unknown", "needRetrial.indulgence") end
        local friendly = self:isFriend(judge.who)
        if type(friendly) ~= "boolean" then ai_unsupported("Indulgence relationship is unknown", "needRetrial.indulgence") end
        if exception then return friendly and not judge.good or not friendly and judge.good end
        if not friendly then return judge.good end
        local hp = scalar(judge.who, "getHp")
        if not finite(hp) then ai_unsupported("Indulgence health is unknown", "needRetrial.indulgence") end
        local draw = self:ImitateResult_DrawNCards(judge.who, judge.who:getVisibleSkillList(true))
        if not finite(draw) then ai_unsupported("Indulgence draw result is unknown", "needRetrial.indulgence") end
        -- Keep both source calls and their short circuits: evaluating overflow
        -- can consume relation/cache inputs even when the answer is unchanged.
        if hp - hand >= draw and self:getOverflow() < 0 then return false end
        if judge.who:hasSkill("tuxi") and hp > 2 and self:getOverflow() < 0 then return false end
        return not judge.good
    elseif reason == "supply_shortage" then
        if known_boolean(self:isFriend(judge.who), "friend") then
            if known_boolean(self:hasSkills("guidao|tiandu", judge.who), "supply_shortage.skills") then return false end
            return not judge.good
        end
        return judge.good
    elseif reason:find("luoshen", 1, true) then
        if known_boolean(self:isFriend(judge.who), "friend") then
            if known_number(judge.who:getHandcardNum(), "luoshen.hand") > 30 then return false end
            if known_boolean(self:hasCrossbowEffect(judge.who), "luoshen.crossbow")
                or known_number(getKnownCard(judge.who, self.player, "Crossbow", false), "luoshen.known_crossbow") > 0 then
                return not judge.good
            end
            if known_number(self:getOverflow(judge.who), "luoshen.overflow") > 1
                and known_number(self.player:getHandcardNum(), "luoshen.own_hand") < 3 then return false end
            return not judge.good
        end
        return judge.good
    elseif reason:find("tuntian", 1, true) then
        if not known_boolean(judge.who:hasSkill("zaoxian"), "tuntian.skill")
            and known_number(judge.who:getMark("zaoxian"), "tuntian.mark") < 1 then return false end
    elseif reason:find("beige", 1, true) then return true end
    local hook = sgs.ai_need_retrial_func[reason]
    if type(hook) == "function" then
        hook = hook(self, judge, judge.good, judge.who, known_boolean(self:isFriend(judge.who), "friend"), lord)
    end
    if type(hook) == "boolean" then return hook end
    if known_boolean(self:isFriend(judge.who), "friend") then return not judge.good end
    if known_boolean(self:isEnemy(judge.who), "enemy") then return judge.good end
    self.isWeak_judge = true
    if known_boolean(self:isWeak(judge.who), "weak") then return not judge.good end
    return judge.good
end

-- Capability uses public counts and visible trigger metadata, never a guessed
-- count of black hidden hand cards (legacy Guidao counts the whole hand pile).
local function can_retrial_status(self, player, reason)
    player = player or self.player
    if not player then return nil end
    local hand_pile
    local function available_hand()
        if hand_pile ~= nil then return hand_pile end
        local hand = scalar(player, "getHandcardNum")
        local extra = scalar(player, "getHandPileCount")
        if not finite(hand) or not finite(extra) then return nil end
        hand_pile = hand + extra
        return hand_pile
    end
    if player:hasSkill("guidao") and reason ~= "wuhun" then
        local count = available_hand()
        if count == nil then return nil end
        local equips = player:getEquips()
        if not equips then return nil end
        for _, card in ipairs(equips) do
            local black = card:isBlack()
            if type(black) ~= "boolean" then return nil end
            if black then count = count + 1 end
        end
        if count > 0 then return true end
    end
    if player:hasSkill("nosguicai") then
        local count = available_hand()
        if count == nil then return nil end
        if count > 0 then return true end
    end
    if player:hasSkill("jilve") then
        local count = player:getCardCount()
        if not finite(count) then return nil end
        if count > 0 then
            local bear = player:getMark("&bear")
            if not finite(bear) then return nil end
            if bear > 0 then return true end
        end
    end
    if player:hasSkill("midao") then
        local count = player:getPileCount("rice")
        if not finite(count) then return nil end
        if count > 0 then return true end
    end
    if player:hasSkill("zhenyi") then
        local mark = player:getMark("@flziwei")
        if not finite(mark) then return nil end
        if mark > 0 then return true end
    end
    local skills = player:getSkills()
    if not skills then return nil end
    local unknown = scalar(player, "areSkillsComplete") ~= true
    local considered = {}
    for _, skill in ipairs(skills) do
        local lord_skill = scalar(skill, "isLordSkill")
        if lord_skill == nil then unknown = true
        else
            local enabled
            if lord_skill then enabled = player:hasLordSkill(skill:objectName())
            else enabled = player:hasSkill(skill:objectName()) end
            if enabled == nil then unknown = true
            elseif enabled then considered[#considered + 1] = skill end
        end
    end
    if player:hasSkill("weidi") then
        local lord = self.room:getLord()
        if lord and lord:objectName() ~= player:objectName() then
            local inherited = lord:getSkills()
            if not inherited then return nil end
            if scalar(lord, "areSkillsComplete") ~= true then unknown = true end
            for _, skill in ipairs(inherited) do
                local lord_skill = scalar(skill, "isLordSkill")
                if lord_skill == nil then unknown = true
                elseif lord_skill then considered[#considered + 1] = skill end
            end
        end
    end
    for _, skill in ipairs(considered) do
        local trigger = type(skill.hasEvent) == "function" and skill:hasEvent(sgs.AskForRetrial)
        if trigger == nil then unknown = true
        elseif trigger then
            local count = player:getCardCount()
            if not finite(count) then return nil end
            if count > 0 then return true end
        end
    end
    if unknown then return nil end
    return false
end

-- Public API keeps the donor's known-negative nil. Unknown capability must not
-- be mistaken for that nil by skill callbacks. Final-retrial can inspect the
-- internal three-state result because a later certain wizard dominates it.
function SmartAIView:canRetrial(player, reason)
    local value = can_retrial_status(self, player, reason)
    if value == nil then ai_unsupported("Retrial capability is not known", "canRetrial") end
    if value then return true end
end
local ordinary_can_retrial = SmartAIView.canRetrial

function SmartAIView:getFinalRetrial(owner, reason)
    local judge = type(reason) == "table" and reason
        or type(owner) == "table" and owner.judge
    if not judge and type(self.getJudge) == "function" then judge = self:getJudge() end
    -- Explicit DTO capability rows remain useful to callers with an authoritative
    -- reason/owner-specific projection. Otherwise scan public capabilities live.
    local requested_owner = player_view(self, owner) or (owner == nil and self.room:getCurrent() or nil)
    if type(judge) == "table" and judge.retrial_candidates_complete == true
        and type(reason) == "string" and reason == judge.reason
        and requested_owner and judge.retrial_owner == requested_owner:objectName() then
        if type(judge.retrial_candidates) ~= "table" then ai_unsupported("Final retrial capability/order is unknown", "getFinalRetrial") end
        if type(reason) == "string" and reason ~= judge.reason then ai_unsupported("Final retrial capability/order is unknown", "getFinalRetrial") end
        if owner ~= nil and not (type(owner) == "table" and owner.judge) then
            local player = player_view(self, owner)
            if not player or judge.retrial_owner ~= player:objectName() then ai_unsupported("Final retrial capability/order is unknown", "getFinalRetrial") end
        end
        local final, wizard, unknown = 0, nil, false
        for _, candidate in ipairs(judge.retrial_candidates) do
            if type(candidate.can_retrial) ~= "boolean" then unknown = true
            elseif candidate.can_retrial then
                local player = player_view(self, candidate.player)
                local friendly = player and self:isFriend(player)
                if type(friendly) ~= "boolean" then unknown = true
                else final, wizard, unknown = friendly and 1 or 2, player, false end
            end
        end
        if unknown then ai_unsupported("Final retrial capability/order is unknown", "getFinalRetrial") end
        return final, wizard
    end
    owner = requested_owner
    if not owner then ai_unsupported("Final retrial capability/order is unknown", "getFinalRetrial") end
    if type(reason) == "table" then reason = reason.reason end
    local roster = self.room:getAlivePlayers()
    if not roster then ai_unsupported("Final retrial capability/order is unknown", "getFinalRetrial") end
    -- Native source walks the actual next-alive ring, constructing the full list
    -- before it asks any capability. A dead/nonclosing cycle is not guessed.
    local players, seen = {owner}, {[owner:objectName()]=true}
    local next_player = owner:getNextAlive()
    while next_player and next_player:objectName() ~= owner:objectName() do
        local name = next_player:objectName()
        if seen[name] or #players >= #roster then
            ai_unsupported("Final retrial seat cycle does not close", "getFinalRetrial")
        end
        seen[name], players[#players+1] = true, next_player
        next_player = next_player:getNextAlive()
    end
    if not next_player then ai_unsupported("Final retrial seat cycle is unknown", "getFinalRetrial") end
    local final, wizard, unknown = 0, nil, false
    for _, player in ipairs(players) do
        local capable
        if self.canRetrial == ordinary_can_retrial then
            capable = can_retrial_status(self, player, reason)
        else
            -- Source/custom overrides retain their own nil = known-negative ABI.
            capable = not not self:canRetrial(player, reason)
        end
        if capable == nil then unknown = true
        elseif capable then
            local friendly = self:isFriend(player)
            if type(friendly) ~= "boolean" then unknown = true
            else final, wizard, unknown = friendly and 1 or 2, player, false end
        end
    end
    if unknown then ai_unsupported("Final retrial capability/order is unknown", "getFinalRetrial") end
    return final, wizard
end

-- Only the literal suit/number judgment subset is evaluated here. The native
-- public-pattern flag excludes availability/place predicates; it is not by
-- itself proof that an arbitrary expression is supported by this Lua matcher.
local function public_judge_pattern(pattern)
    if type(pattern)~="string" or pattern=="" or pattern:find("$",1,true) then return false end
    local suits={spade=true,club=true,heart=true,diamond=true,red=true,black=true,
        no_suit=true,no_suit_red=true,no_suit_black=true,no_color=true}
    for branch in (pattern.."#"):gmatch("(.-)#") do
        local factors={}
        for factor in (branch.."|"):gmatch("(.-)|") do factors[#factors+1]=factor end
        if factors[1]~="." or #factors>4 or #factors==4 and factors[4]~="." then return false end
        if factors[2] and factors[2]~="." then
            for token in (factors[2]..","):gmatch("(.-),") do
                if token:sub(1,1)=="^" then token=token:sub(2) end
                if not suits[token] then return false end
            end
        end
        if factors[3] and factors[3]~="." then
            for token in (factors[3]..","):gmatch("(.-),") do
                if token:sub(1,1)=="^" then token=token:sub(2) end
                local low,high=token:match("^(%d*)~(%d*)$")
                local function small(value) return value=="" or value:match("^%d+$") and tonumber(value)<=15 end
                if low then if not small(low) or not small(high) then return false end
                elseif not ({A=true,J=true,Q=true,K=true,JOKER=true})[token]
                    and not (token:match("^%d+$") and tonumber(token)<=15) then return false end
            end
        end
    end
    return true
end

local function outcome(self, judge, card, filtered, filter_exact)
    -- ai_judgeGood is the event's previous-result cache, not a candidate hook.
    if judge.outcomes_complete ~= true then
        if judge.who:objectName()~=self.player:objectName() and judge.unfiltered_outcomes_complete==true then
            if filter_exact==true then
                if filtered==card then return lookup(judge.unfiltered_outcome_by_id,card:getEffectiveId()) end
                if type(judge.predicate_good)~="boolean" or not public_judge_pattern(judge.pattern)
                    or type(self.matchGuanxingPattern)~="function" then return nil end
                local matches=self:matchGuanxingPattern(judge.pattern,judge.who,filtered)
                if type(matches)~="boolean" then return nil end
                return judge.predicate_good==matches
            end
            local value=lookup(judge.unfiltered_outcome_by_id,card:getEffectiveId())
            if type(value)=="boolean" then
                note_estimate(self,"retrial.foreign_filter_public_identity")
                return value
            end
        end
        return nil
    end
    local repair=lookup(judge.repair_by_id,card:getEffectiveId())
    if type(repair)=="string" then note_estimate(self,"donor_error_repair:"..repair) end
    return lookup(judge.outcome_by_id, card:getEffectiveId())
end

local function lightning_reserve(self, judge)
    if judge.reason == "lightning" then return {}, 0 end
    if judge.lightning_reserve_complete == true then
        if type(judge.lightning_reserve_rows) == "table" then return {}, 0 end
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

function SmartAIView:dontRespondPeachInJudge(judge)
    judge = normalize(self, judge)
    if not judge or not judge.who then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
    local count = self:getCardsNum("Peach")
    if not finite(count) then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
    if count < 1 then return false end
    local skip = self:willSkipPlayPhase()
    if type(skip) ~= "boolean" then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
    if skip then
        local limit = self:getOverflow(self.player, true)
        if not finite(limit) then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
        if count > limit then return false end
    end
    local card = self:getCard("Peach")
    if card then
        local use = {isDummy = true, to = AIList.new({}), current_targets = {}, extra_target = 0}
        self:useCardPeach(card, use)
        if use.card and use.card:isKindOf("Peach") then return true end
    end
    local lost = self.player:getLostHp()
    if not finite(lost) then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
    if count <= lost then return true end
    local weak = self:isWeak(self.friends)
    if type(weak) ~= "boolean" then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
    if weak then return true end
    local reason = judge.reason
    if reason == "tuntian" then
        local zaoxian = judge.who:getMark("zaoxian")
        if zaoxian == nil then ai_unsupported("Peach retrial protection mark is unknown", "dontRespondPeachInJudge.zaoxian") end
        if zaoxian < 1 then
            local field = judge.who:getPileCount("field")
            if not finite(field) then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
            if field < 2 then return true end
        end
    elseif reason == "EightDiagram" or reason == "bazhen" then
        weak = self:isWeak(judge.who)
        if type(weak) ~= "boolean" then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
        if not weak or judge.who:hasSkills(sgs.masochism_skill) then
            local friendly = self:isFriend(judge.who)
            if type(friendly) ~= "boolean" then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
            if friendly then return true end
        end
    elseif reason == "nosmiji" then
        lost = judge.who:getLostHp()
        if not finite(lost) then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
        if lost == 1 then return true end
    elseif reason == "shaoying" then
        -- Prefer a reason-scoped fact; otherwise use this viewer's explicitly
        -- known event memory. A reset/missing history cannot mean "no target".
        local target_name = judge.shaoying_target
        -- The effective Yitian intention writer records this public selected
        -- target in the viewer's strategy envelope, not the initial legacy key.
        if target_name == nil and type(self.getStrategyMemory) == "function" then
            local value, known = self:getStrategyMemory("yitian.shaoying_target")
            if known then target_name = value or "" end
        end
        if target_name == nil and type(self.getEventMemory) == "function" then
            local value, known = self:getEventMemory("shaoying_target")
            if known then target_name = value or "" end
        end
        if type(target_name) ~= "string" then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
        if target_name ~= "" then
            local target = player_view(self, target_name)
            if not target then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
            local vine, hp = target:hasArmorEffect("Vine"), target:getHp()
            if type(vine) ~= "boolean" or not finite(hp) then ai_unsupported("Peach retrial protection input is unknown", "dontRespondPeachInJudge") end
            if vine and hp > 3 or hp > 2 then return true end
        end
    elseif reason:find("tieji", 1, true) or reason:find("qianxi", 1, true)
        or reason:find("beige", 1, true) then return true end
    return false
end

local function peach_protected(self, judge)
    local final = self:getFinalRetrial(nil, judge.reason)
    if not finite(final) then return nil end
    local protect = final > 1
    if not protect then
        protect = self:dontRespondPeachInJudge(judge)
        if type(protect) ~= "boolean" then return nil end
    end
    if not protect then return false end
    local weak = self:isWeak(self.friends)
    if type(weak) ~= "boolean" then return nil end
    return not weak
end

local function r33_retrial_query(object,method,...)
    local provider=object and object[method]
    if type(provider)~="function" then ai_unsupported("retrial dependency is unavailable",method) end
    local value=provider(object,...)
    if AIUnsupported.is(value) then error(value,0) end
    if value==nil and not (type(SmartAIView.isKnownNilStrategyResult)=="function"
        and SmartAIView.isKnownNilStrategyResult(object,method,provider)) then
        ai_unsupported("retrial dependency is unknown",method)
    end
    return value
end
local function beige_candidate(self, judge, card, self_card, filtered)
    local source
    if judge.damage_context_complete == true then
        if judge.damage_from == "" then return false end
        source = player_view(self, judge.damage_from)
    elseif type(self.getDecisionContext) == "function" then
        local damage = self:getDecisionContext().damage
        if type(damage) == "table" then
            if damage.from == nil and damage.from_name == "" then return false end
            source = player_view(self, damage.from)
        end
    end
    if not source then return nil end
    -- The source repeatedly reads the filtered/original suits only in reached
    -- clauses; do not prefetch them before toTurnOver or the overflow gate.
    local q = r33_retrial_query
    if q(self,"isFriend",source) then
        if not q(self,"toTurnOver",source,0)
            and q(judge.card,"getSuit")~=0 and q(filtered,"getSuit")==0 then
            return "spade"
        elseif (self_card==false or q(self,"getOverflow")>0)
            and q(judge.card,"getSuit")~=q(filtered,"getSuit") then
            if q(judge.card,"getSuit")==2 and q(judge.who,"isWounded") and q(self,"isFriend",judge.who)
                or q(judge.card,"getSuit")==3 and q(self,"isEnemy",judge.who) and q(self,"hasManjuanEffect",judge.who)
                or q(judge.card,"getSuit")==1 and q(self,"needToThrowArmor",source) then
            elseif (q(self,"isFriend",judge.who) and q(filtered,"getSuit")==2 and q(judge.who,"isWounded")
                or q(filtered,"getSuit")==3 and q(self,"isEnemy",judge.who) and q(self,"hasManjuanEffect",judge.who)
                or q(filtered,"getSuit")==3 and q(self,"isFriend",judge.who) and not q(self,"hasManjuanEffect",judge.who)
                or q(filtered,"getSuit")==1 and (q(self,"needToThrowArmor",source) or q(source,"isNude")))
                or q(judge.card,"getSuit")==1 and q(self,"toTurnOver",source,0) then
                return "other"
            end
        end
    elseif not q(self,"toTurnOver",source,0)
        and q(filtered,"getSuit")~=0 and q(judge.card,"getSuit")==0 then
        return true
    end
    return false
end

function SmartAIView:getRetrialCardId(cards, judge, self_card, exchange)
    judge = normalize(self, judge)
    if type(cards) ~= "table" or not judge then ai_unsupported("Retrial candidate/selection input is unknown", "getRetrialCardId") end
    local views, allowed = {}, {}
    for _, card in ipairs(cards) do
        local view = card_view(card)
        if not view then ai_unsupported("Retrial candidate/selection input is unknown", "getRetrialCardId") end
        local id = view:getEffectiveId()
        if not finite(id) or id < 0 or id % 1 ~= 0 then ai_unsupported("Retrial candidate/selection input is unknown", "getRetrialCardId") end
        views[#views + 1], allowed[id] = view, true
    end
    if #views == 0 then return -1 end
    local beige = judge.reason:find("beige", 1, true) ~= nil
    local function boolean(value, key)
        if type(value) ~= "boolean" then ai_unsupported("Retrial selection input is unknown", key) end
        return value
    end
    local function is_peach(card)
        -- isCard deliberately returns a card on a match and nil on a known
        -- nonmatch; missing classification data raises typed unsupported.
        local request=self.request or{}
        local options=request.options or{}
        if request.kind=="amazing_grace" and options.reason=="fcj_huanshi"
            and type(card.isVirtualCard)=="function" and card:isVirtualCard()==false then
            for _,id in ipairs(options.card_ids or{}) do
                if id==card:getEffectiveId() then return self:isCardForAcquisition("Peach",card) end
            end
        end
        return not not isCard("Peach", card, self.player)
    end
    local function good(card,filtered,filter_exact)
        return boolean(outcome(self, judge, card,filtered,filter_exact), "getRetrialCardId.outcome")
    end
    local normal, other, has_spade = {}, {}, false
    for _, card in ipairs(views) do
        -- Source applies CardFilter before relation and Peach tests, even when
        -- neither relationship will select a card. This query only uses the
        -- existing owner/disclosed projections (foreign filters stay marked estimates).
        local filtered,filter_exact = self:CardFilter(card, judge.who)
        if beige and not is_peach(card) then
            local selected = beige_candidate(self, judge, card, self_card, filtered)
            if selected == nil then ai_unsupported("Beige candidate input is unknown", "getRetrialCardId.beige") end
            if selected == "spade" then has_spade = true end
            if selected == "other" then other[#other + 1] = card
            elseif selected then normal[#normal + 1] = card end
        elseif (boolean(self:isFriend(judge.who), "getRetrialCardId.friend") and good(card,filtered,filter_exact)
            or boolean(self:isEnemy(judge.who), "getRetrialCardId.enemy") and not good(card,filtered,filter_exact)) then
            local protected = false
            if self_card ~= false and is_peach(card) then
                protected = peach_protected(self, judge)
                if type(protected) ~= "boolean" then
                    ai_unsupported("Peach protection is unknown", "getRetrialCardId.peach_protection")
                end
            end
            if not protected then normal[#normal + 1] = card end
        end
    end
    if not has_spade then
        for _, card in ipairs(other) do normal[#normal + 1] = card end
    end
    local reserved = {}
    if #normal > 0 then
        local reserve, reserve_count = lightning_reserve(self, judge)
        if not reserve then
            if judge.lightning_reserve_complete~=false then ai_unsupported("Retrial candidate/selection input is unknown", "getRetrialCardId") end
            local players=self.room:getAllPlayers()
            if not players then ai_unsupported("Retrial candidate/selection input is unknown", "getRetrialCardId") end
            -- The donor applies CardFilter only to remaining candidates, scanning
            -- backwards once per holder. Preserve that lazy query/selection order.
            for _, holder in ipairs(players) do
                local has_lightning=holder:containsTrick("lightning")
                if has_lightning==nil then ai_unsupported("Retrial candidate/selection input is unknown", "getRetrialCardId") end
                if has_lightning then
                    for index=#normal,1,-1 do
                        if not reserved[index] then
                            local filtered=r33_good_judge_card(self,holder,normal[index],"retrial.lightning_reserve_foreign_filter")
                            if r33_retrial_query(filtered,"getSuit")==sgs.Card_Spade
                                and r33_retrial_query(filtered,"getNumber")>=2
                                and r33_retrial_query(filtered,"getNumber")<=9 then
                                reserved[index]=true;break
                            end
                        end
                    end
                end
            end
            reserve,reserve_count={},0
        end
        if type(judge.lightning_reserve_rows) == "table" and judge.lightning_reserve_complete == true
            and judge.reason ~= "lightning" then
            for _, row in ipairs(judge.lightning_reserve_rows) do
                if type(row.candidate_ids) ~= "table" then ai_unsupported("Retrial candidate/selection input is unknown", "getRetrialCardId") end
                for index = #normal, 1, -1 do
                    if not reserved[index] and lookup(row.candidate_ids, normal[index]:getEffectiveId()) == true then
                        reserved[index] = true
                        break
                    end
                end
            end
        else
            for index = #normal, 1, -1 do
                if reserve_count <= 0 then break end
                if lookup(reserve, normal[index]:getEffectiveId()) == true then
                    reserved[index], reserve_count = true, reserve_count - 1
                end
            end
        end
    end
    local function select(pool, excluded)
        -- Legacy doDisCard scans the entire candidate order before any keep lookup.
        for index, card in ipairs(pool) do
            if not excluded[index] then
                if type(self.doDisCard) ~= "function" then ai_unsupported("Retrial candidate/selection input is unknown", "getRetrialCardId") end
                local discard = r33_retrial_query(self,"doDisCard",self.player,card:getEffectiveId())
                if discard then return card:getEffectiveId() end
            end
        end
        local candidates = {}
        for index, card in ipairs(pool) do
            if not excluded[index] then candidates[#candidates + 1] = card end
        end
        if #candidates == 0 then return -1 end
        local ordered = self:sortByKeepValue(candidates)
        -- Source sort is in-place; the common pure helper returns its sorted copy.
        if ordered ~= nil then candidates = ordered end
        return candidates[1]:getEffectiveId()
    end
    local selected = select(normal, reserved)
    if selected == nil or selected ~= -1 then return selected end
    if exchange == true then
        local swaps = {}
        for _, card in ipairs(views) do
            local filtered, filter_exact = self:CardFilter(card, judge.who)
            local candidate_good = good(card, filtered, filter_exact)
            if type(judge.good) ~= "boolean" then
                ai_unsupported("Current judgment result is unknown", "getRetrialCardId.exchange")
            end
            if candidate_good == judge.good then swaps[#swaps + 1] = card end
            -- Legacy deliberately adds a duplicate for wildcard patterns; sorting
            -- side effects and RNG count see that duplicate as well.
            if judge.pattern == "." then swaps[#swaps + 1] = card end
        end
        return select(swaps, {})
    end
    return -1
end
