-- Target recommendation classification, scoring and built-in recommendation policies.
-- Keep captured source guards local to this domain; package overrides load afterward.
local sgs = assert(rawget(_G, "sgs"), "strategy-hooks.lua must load first")

-- Target recommendation failures are distinct from an empty ranked result:
-- unknown classification/relation/projection, missing evaluators, malformed hooks,
-- and non-finite scores must raise unsupported, never choose the fallback.
local target_known = AIValue.requireKnown
local function target_number(value, key)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        ai_unsupported("target recommendation score is not finite", key)
    end
    return value
end
local target_call = AIValue.bindQuery {
    resolve = AIValue.playerStrategyMethod, known = target_known,
    missing = function(method, object)
        -- Keep malformed nil receivers distinct from an unavailable facade method.
        if object == nil then error("attempt to index a nil value", 0) end
        ai_unsupported("target recommendation helper is unavailable", method)
    end,
}
local scarlet_recommend_callbacks = setmetatable({}, {__mode = "k"})
local function scarlet_metadata(self)
    local value = nil -- The Scarlet recommendation capture is not projected.
    if type(value) ~= "table" or value.captured ~= true then
        ai_unsupported("Scarlet recommendation source was not captured at initialization", "target_recommend:scarlet")
    end
    return value
end
local function recommendation_callback(self, callback)
    local key = scarlet_recommend_callbacks[callback]
    if not key then return callback end
    local entries = scarlet_metadata(self).entries
    local row = type(entries) == "table" and entries[key]
    if type(row) ~= "table" or row.known ~= true or type(row.present) ~= "boolean" then
        ai_unsupported("Scarlet recommendation presence is unknown", key)
    end
    if not row.present then return nil end
    if row.source_matches ~= true or row.enabled ~= true then
        ai_unsupported("Scarlet recommendation effective source changed", key)
    end
    return callback
end
local function scarlet_registered_type(self, card, kind)
    if not ((card == "s4_ganglie" and kind == "draw") or (card == "s4_qiaobian" and kind == "decrease")) then return false end
    local types = scarlet_metadata(self).types
    local row = type(types) == "table" and types[card]
    if type(row) ~= "table" or row.known ~= true or row.type ~= kind or type(row.present) ~= "boolean" then
        ai_unsupported("Scarlet registered card category is unknown", card)
    end
    return row.present
end
local target_types = {
    damage = {"damageSkillsList", "checkIsDamageCard", {}},
    draw = {"drawSkillsList", "checkIsDrawCard", {"ExNihilo", "AmazingGrace", "IronChain", "Dongzhuxianji"}},
    buff = {"buffSkillsList", "checkIsBuff", {"Peach"}},
    debuff = {"debuffSkillsList", "checkIsDebuff", {"Dismantlement", "Snatch", "Indulgence", "SupplyShortage", "IronChain"}},
    recover = {"recoverSkillsList", "checkIsRecover", {"Peach", "Analeptic", "GodSalvation"}},
    decrease = {"decreaseSkillsList", "checkIsDecreaseCard", {"Dismantlement", "Snatch", "Collateral"}},
    turnOver = {"turnOverSkillsList", "checkIsTurnOver", {}}
}
local target_subtypes = {recover = "recover_card", buff = "buff_card", debuff = "debuff_card"}
for kind, entry in pairs(target_types) do
    sgs[entry[1]] = sgs[entry[1]] or {}
    SmartAIView[entry[2]] = function(self, card)
        if not card then return false end
        if type(card) == "string" then
            if card == kind then return true end
            if scarlet_registered_type(self, card, kind) then return true end
            for _, name in ipairs(sgs[entry[1]]) do if name == card then return true end end
            if kind == "recover" then
                for _, key in ipairs({"recover_skill", "recover_hp_skill", "save_skill"}) do
                    if sgs[key] and sgs[key]:match(card) then return true end
                end
            end
            return false
        end
        if not AIValue.isCard(card) then ai_unsupported("target context must be a card value", kind) end
        if kind == "damage" and target_call(card, "isDamageCard") then return true end
        if target_subtypes[kind] and target_call(card, "getSubtype") == target_subtypes[kind] then return true end
        for _, class in ipairs(entry[3]) do if target_call(card, "isKindOf", class) then return true end end
        -- 套件也可按牌類別登記效果；實體牌與轉化牌都讀相同的分類。
        for _, class in ipairs(sgs[entry[1]]) do if target_call(card, "isKindOf", class) then return true end end
        if kind == "debuff" and target_call(card, "isDamageCard") then return true end
        return false
    end
end
-- The donor captures these list objects once; later replacement of a public
-- registry must not redirect registration into a different table.
local skill_card_type_lists = {}
for kind, entry in pairs(target_types) do skill_card_type_lists[kind] = sgs[entry[1]] end
function sgs.registerSkillCardType(name, kind)
    local list = skill_card_type_lists[kind]
    assert(list, "sgs.registerSkillCardType: unknown type " .. tostring(kind))
    for _, existing in ipairs(list) do if existing == name then return end end
    table.insert(list, name)
end
function sgs.registerTargetRecommend(name, fn)
    sgs.ai_target_recommend[name] = function(self, from, to, card, owner, ctx)
        if not to or not target_call(to, "hasSkill", name) then return 0 end
        -- 此 API 是目標自身技能的推薦；其他持有者的同名掛鉤不得再次加到它身上。
        if owner and target_call(owner, "objectName") ~= target_call(to, "objectName") then return 0 end
        return fn(self, from, to, card, owner, ctx or self:buildTargetRecommendContext(card))
    end
end
function sgs.registerGlobalTargetRecommend(name, fn)
    for _, entry in ipairs(sgs.ai_target_recommend_global) do
        if entry.name == name then entry.eval = fn; return end
    end
    table.insert(sgs.ai_target_recommend_global, {name = name, eval = fn})
end
function SmartAIView:buildTargetRecommendContext(card, flags)
    return {isDamage = self:checkIsDamageCard(card), isDebuff = self:checkIsDebuff(card),
        isTurnOver = self:checkIsTurnOver(card), isRecovery = self:checkIsRecover(card),
        isDraw = self:checkIsDrawCard(card), isBuff = self:checkIsBuff(card),
        isDecrease = self:checkIsDecreaseCard(card), isVirtual = type(card) == "string", flags = flags}
end
local function target_relation(self, to, from)
    local relation = self:relationTo(to, from)
    if relation == nil or relation == "unknown" then ai_unsupported("target relation is unknown", "recommend") end
    return relation
end
function SmartAIView:needDraw(to, notDraw)
    if not to then return false end
    if target_call(to, "hasSkills", "manjuan|zishu") and target_call(to, "getPhase") ~= sgs.Player_NotActive then return true end
    if not notDraw and target_call(to, "hasSkill", "zhanji") and target_call(to, "getPhase") == sgs.Player_Play then return true end
    if not notDraw and target_call(to, "hasSkill", "Luajianzai") then return true end
    local function mark(player, name)
        return target_number(target_call(player, "getMark", name), name)
    end
    if target_call(to, "hasSkill", "qhfiremanjuann") and mark(to, "qhfiremanjuann-Clear") < 2 then return true end
    if target_call(to, "getHandcardNum") < 5 and target_call(to, "hasSkill", "zhengu") then
        for _, player in ipairs(target_call(self.room, "getAlivePlayers")) do
            if mark(player, "&zhengu") > 0 and target_call(self, "isFriend", player, to) then return true end
        end
    end
    return false
end
-- Source aiConnect returns names. Preserve its objectName call, including the
-- ordinary error on a reached string element; do not repair donor policy here.
function SmartAIView:hasTurnOverSkill(player)
	if not player then return false end

	for _,ac in ipairs(target_known(self:getConnections(player), "hasTurnOverSkill connections"))do
		if self:checkIsTurnOver(ac:objectName()) then
			return true
		end
	end
	return false
end
function SmartAIView:hasRecoverSkill(player)
	if not player then return false end
	for _, skill in ipairs(target_known(self:getConnections(player), "hasRecoverSkill connections")) do
		if self:checkIsRecover(skill:objectName()) then
			return true
		end
	end
	return false
end
function SmartAIView:hasSaveSkill(player)
	if not player then return false end
	for _, skill in ipairs(target_known(self:getConnections(player), "hasSaveSkill connections")) do
		local skill_name = skill:objectName()
		if sgs.save_skill and sgs.save_skill:match(skill_name) then
			return true
		end
	end
	return false
end

function SmartAIView:getTargetBaseScore(target, card, from, flags)
    from = from or self.player
    -- Unknown relations must stay unsupported, not become a zero-score fallback.
    target_relation(self, target, from)
    local score = 0
    local isFriend = self:isFriend(target, from)
    local isEnemy = self:isEnemy(target, from)

    if not (isFriend or isEnemy) then return 0 end

    -- [1] 傷害牌評分
    if self:checkIsDamageCard(card) then
        if self:damageIsEffective(target, card, from) then
            local damage = self:ajustDamage(from, target, 1, card)
            if damage > 0 then
                if isEnemy then
                    if not self:needToLoseHp(target, from, card) then
                        score = score + 2
                        if target:getHp() <= damage then
                            score = score + 3  -- 斬殺
                        elseif self:isWeak(target) then
                            score = score + 1
                        end
                    end
                else
                    if not self:needToLoseHp(target, from, card) then
                        score = score - 3
                    end
                end
            end
        end
    end

    -- [2] 回復牌評分
    if self:checkIsRecover(card) then
        if target:isWounded() then
            score = score + (isFriend and 2 or -2)
        end
		if self:hasRecoverSkill(target) or self:hasSaveSkill(target) then
			score = score + (isFriend and 2 or -2)
		end
    end

    -- [3] 摸牌類評分
    if self:checkIsDrawCard(card) then
        if self:canDraw(target, from) then
            if not self:needKongcheng(target) then
                score = score + (isFriend and 2 or -2)
            end
			local notDraw = type(flags)=="table" and flags.notDraw==true
			if self:needDraw(target,notDraw) then
				score = score + (isFriend and 2 or -2)
			end
        else
            score = score - 1  -- 無效目標扣分
        end
    end

    -- [4] 棄牌/破壞類評分
    if self:checkIsDecreaseCard(card) then
		if not from:canDiscard(target, flags) then
			return -5  -- 無效目標
		end

		-- 判定是拆牌(不獲得)還是順牌(獲得)
		local isObtain = card and card:isKindOf("Snatch")

		if isEnemy then
			if self:doDisCard(target, flags, isObtain) then
				local dangerous = self:getDangerousCard(target)
				local valuable = self:getValuableCard(target)
				score = score + 2  -- 基礎分
				if dangerous then score = score + 2 end
				if valuable then score = score + 1 end
			else
				score = score - 1  -- 不適合棄牌
			end
		elseif isFriend then
			if self:doDisCard(target, flags, isObtain) then
				score = score + 1  -- 友軍需要棄牌
			else
				score = score - 2  -- 友軍不想被棄牌
			end
		end
	end

    -- [5] 身份與威脅修正
    if target:isLord() then score = score + 1 end
    if isEnemy then
        local objLevel = self:objectiveLevel(target)
        if objLevel > 3 then
            score = score + math.min(objLevel - 3, 2)
        end
    end

    return score
end
-- Recommendation hooks are collected once per viewer and board revision.
local target_recommend_cache = {}
local function target_estimate_counts(self)
    local log = self.request and self.request.scratch and self.request.scratch.knowledge_estimates or {}
    local counts = {}
    for i, row in ipairs(log) do counts[i] = row.count or 1 end
    return counts
end
local function target_estimate_delta(self, counts)
    local log = self.request and self.request.scratch and self.request.scratch.knowledge_estimates or {}
    local result = {}
    for i, row in ipairs(log) do
        if counts[i] == nil or counts[i] ~= (row.count or 1) then
            local entry = {}
            for key, value in pairs(row) do if key ~= "count" then entry[key] = value end end
            result[#result + 1] = entry
        end
    end
    return result
end
local function active_target_recommends(self)
    local viewer = self.player:objectName()
    local stamp = {scope = viewer, epoch = tostring(self.world.revision)}
    local saved = target_recommend_cache[stamp.scope]
    if not saved or saved.epoch ~= stamp.epoch then
        local before_estimates = target_estimate_counts(self)
        local entries = {}
        for _, owner in ipairs(target_call(self, "getCachedAlivePlayers")) do
            for _, name in ipairs(target_known(self:getConnections(owner), "recommend connections")) do
                local callback = recommendation_callback(self, sgs.ai_target_recommend[name])
                if callback then entries[#entries + 1] = {owner = owner:objectName(), eval = callback} end
            end
        end
        saved = {viewer = viewer, epoch = stamp.epoch, entries = entries,
            estimates = target_estimate_delta(self, before_estimates)}
        target_recommend_cache[stamp.scope] = saved
    else
        -- A cached observer estimate remains an estimate in every later result.
        -- Replay only its provenance, never the connections or policy value.
        for _, row in ipairs(saved.estimates or {}) do
            local entry = {}
            for key, value in pairs(row) do entry[key] = value end
            entry.status = "estimate"
            if entry.value == nil then entry.value = true end
            self:useKnowledgeEstimate(entry, entry.context or "target_recommend.cache")
        end
    end
    local entries = {}
    for _, entry in ipairs(saved.entries) do
        local owner = self.room:findPlayerByObjectName(entry.owner, true)
        if not owner then ai_unsupported("cached recommendation owner is not in the current roster", "getBestTarget:cache") end
        entries[#entries + 1] = {owner = owner, eval = entry.eval}
    end
    return entries
end
-- opts.deterministic：決定性取用者（Slash 目標）改走 argmax，不消耗 room RNG。
function SmartAIView:getBestTarget(targets, card, from, flags, opts)
    if not targets then return nil end
    if not AIValue.isList(targets) then ai_unsupported("target candidates are unknown", "getBestTarget") end
    if #targets == 0 then return nil end
    from = from or self.player
    local ctx = self:buildTargetRecommendContext(card, flags)
    local ordered, ranks = targets, {}
    if ctx.isDamage then
        -- Damage ranking uses viewer relations and bypasses getTargetBaseScore.
        for _, target in ipairs(targets) do
            if not AIValue.isPlayer(target) then ai_unsupported("invalid target facade", "getBestTarget") end
            target_relation(self, target)
        end
        ordered = self:findPlayerToDamage(1, from, nil, targets, 0, card)
        if AIUnsupported.is(ordered) then error(ordered, 0) end
        if not ordered or #ordered == 0 then return nil end
        for index, target in ipairs(ordered) do
            ranks[target:objectName()] = #ordered > 1 and 1 + (#ordered - index) * (4 / (#ordered - 1)) or 5
        end
    end
    local recommend_score = opts and opts.recommend_score or self:targetRecommendScorer(card, from, flags, nil, ctx)
    local scored = {}
    for _, target in ipairs(ordered) do
        if not AIValue.isPlayer(target) then ai_unsupported("invalid target facade", "getBestTarget") end
        local score = ctx.isDamage and ranks[target:objectName()]
            or target_number(self:getTargetBaseScore(target, card, from, flags), "base score")
        if score > 0 then
            score = recommend_score(target, score)
            if score ~= nil and score > 0 then
                scored[#scored + 1] = {target = target, score = score}
            end
        end
    end
    if #scored == 1 then return scored[1].target end
    if #scored == 0 then return nil end
    if opts and opts.deterministic then
        -- 與 rankTargets 同一決勝規則：分數降冪、objectName 升冪，同一局面必得同一人。
        local best
        for _, entry in ipairs(scored) do
            if not best or entry.score > best.score
                or (entry.score == best.score and entry.target:objectName() < best.target:objectName()) then
                best = entry
            end
        end
        return best.target
    end
    local total = 0
    for _, entry in ipairs(scored) do total = target_number(total + entry.score, "total score") end
    local random, cumulative = math.random() * total, 0
    for _, entry in ipairs(scored) do
        cumulative = cumulative + entry.score
        if random <= cumulative then return entry.target end
    end
    return scored[#scored].target
end
function SmartAIView:getBestTargetOr(targets, card, from, fallback, opts)
    if targets and type(targets) ~= "table" then
        targets = sgs.QList2Table(targets)
    end
    local target = self:getBestTarget(targets, card, from, nil, opts)
    if target then return target end
    if type(fallback) == "function" then
        return fallback(self, targets, card, from)
    end
    return nil
end
-- 多目標版：重複用決定性 getBestTarget 抽出前 count 名，供配對／多人技能使用。
-- 每次呼叫都不抽 RNG，且已選中的人會從下一輪候選移除。
function SmartAIView:getBestTargets(targets, count, card, from, flags)
    if not targets then return nil end
    if not AIValue.isList(targets) then ai_unsupported("target candidates are unknown", "getBestTargets") end
    from = from or self.player
    local remaining, chosen = AIList.new({}), AIList.new({})
    for _, target in ipairs(targets) do remaining[#remaining + 1] = target end
    for _ = 1, math.max(1, tonumber(count) or 1) do
        if #remaining == 0 then break end
        local best = self:getBestTarget(remaining, card, from, flags, {deterministic = true})
        if not best then break end
        chosen[#chosen + 1] = best
        local next_remaining = AIList.new({})
        for _, target in ipairs(remaining) do
            if target:objectName() ~= best:objectName() then next_remaining[#next_remaining + 1] = target end
        end
        remaining = next_remaining
    end
    return chosen
end
-- 目標推薦的「加減分」形式：給已經有自己評分函式的取用者（例如國色的 getvalue）用。
-- 排序仍由呼叫端決定；推薦掛鉤只提供 delta，回 false 代表否決。
function SmartAIView:targetRecommendAdjust(target, card, from, ctx)
    from = from or self.player
    ctx = ctx or self:buildTargetRecommendContext(card)
    local total = 0
    local function apply(eval, owner)
        local adjust = eval(self, from, target, card, owner, ctx)
        if AIUnsupported.is(adjust) then error(adjust, 0) end
        if adjust == false then return false end
        if type(adjust) == "number" then
            total = target_number(total + target_number(adjust, "recommend adjustment"), "recommend total")
        end
        return true
    end
    for _, rec in ipairs(active_target_recommends(self)) do
        if apply(rec.eval, rec.owner) == false then return false end
    end
    for _, rec in ipairs(sgs.ai_target_recommend_global) do
        if apply(rec.eval, nil) == false then return false end
    end
    return total
end
-- 每次牌型規劃建立一個評分器；重排、否決檢查與備援共用快取，不累加舊分數。
-- role_kind 僅供配對牌的不同角色指定效果，牌本身仍保留原始身份。
function SmartAIView:targetRecommendScorer(card, from, flags, role_kind, context)
    from = from or self.player
    local ctx = context or self:buildTargetRecommendContext(card, flags)
    if role_kind then
        assert(target_types[role_kind], "targetRecommendScorer: unknown role kind")
        for kind in pairs(target_types) do
            local key = kind == "recover" and "isRecovery" or "is" .. kind:sub(1, 1):upper() .. kind:sub(2)
            ctx[key] = kind == role_kind
        end
    end
    local deltas = {}
    return function(target, value)
        local name = target_call(target, "objectName")
        local delta = deltas[name]
        if delta == nil then
            delta = self:targetRecommendAdjust(target, card, from, ctx)
            deltas[name] = delta
        end
        if delta == false then return nil end
        return target_number(value + delta, "recommended score")
    end
end
-- 只在呼叫端提供的同一規則分組內排序；同分保留順序，不消耗 RNG 或改寫來源清單。
function SmartAIView:orderTargetsByRecommend(targets, score)
    local ranked, ordered = {}, AIList.new({})
    for index, player in ipairs(sgs.QList2Table(targets)) do
        local value = score(player, 0)
        if value ~= nil then ranked[#ranked + 1] = {player = player, value = value, index = index} end
    end
    table.sort(ranked, function(a, b)
        if a.value ~= b.value then return a.value > b.value end
        return a.index < b.index
    end)
    for _, entry in ipairs(ranked) do ordered:append(entry.player) end
    return ordered
end
-- Read only the exact reached slot. A public first description can decide
-- the predicate without requesting an undisclosed second general.
function SmartAIView:checkMasochismInvalid(from, to, card)
    if not from then return false end
    local nature = type(card) ~= "string" and card and sgs.card_damage_nature[card:getClassName()] or nil
    if target_call(self, "hasJueqingEffect", from, to, nature) then return true end
    if to and target_call(from, "hasSkill", "nosqianxi") and target_call(from, "distanceTo", to) == 1
        and type(card) ~= "string" and card and target_call(card, "isKindOf", "Slash") then return true end
    -- The donor reads the general's description; the visible skills' descriptions
    -- are the same text. Hidden hegemony skills leave the answer unknown.
    local skills = target_known(from:getSkills(), "masochism source skills")
    for _, skill in ipairs(skills) do
        local text = skill._view.description
        if type(text) ~= "string" then ai_unsupported("skill description is not projected", "checkMasochismInvalid") end
        if string.find(text, "技能失效") or string.find(text, "技失效") then return true end
    end
    if from:areSkillsComplete() ~= true then
        ai_unsupported("hidden skills may invalidate skills", "checkMasochismInvalid")
    end
    return false
end
function sgs.registerMasochismRecommend(name, spec)
    sgs.registerTargetRecommend(name, function(self, from, to, card, owner, ctx)
        if not ctx.isDamage then return 0 end
        if spec.invalid ~= nil and self:checkMasochismInvalid(from, to, card) then return spec.invalid end
        for _, rule in ipairs(spec.rules or {}) do if rule.when(self, from, to, card) then return rule.score end end
        return 0
    end)
end

-- 剛烈（新版）
sgs.registerMasochismRecommend("ganglie", {
	invalid = 3,
	rules = {
		{ when = function(self, from, to, card) return from:getHp() < 2 end, score = -3 },
	},
})

-- nosganglie（舊版剛烈）
sgs.registerMasochismRecommend("nosganglie", {
	invalid = 2,
	rules = {
		{ when = function(self, from, to, card) return from:getHp() < 2 end, score = -2 },
	},
})

-- 節命
sgs.registerMasochismRecommend("jieming", {
	invalid = 2,
	rules = {
		{
			when = function(self, from, to, card)
	local apn = self:getAllPeachNum(to)
	local damageNum = self:ajustDamage(from, to, 1, card)
				return apn + to:getHp() > damageNum
					and self.getJiemingChaofeng and self:getJiemingChaofeng(to) > -4
			end,
			score = -2
		},
	},
})

-- 遺計
sgs.registerMasochismRecommend("yiji", {
	invalid = 2,
	rules = {
		{
			when = function(self, from, to, card)
	local apn = self:getAllPeachNum(to)
	local damageNum = self:ajustDamage(from, to, 1, card)
				return apn + to:getHp() > damageNum
					and self.findFriendsByType and not self:findFriendsByType(sgs.Friend_Draw, to)
			end,
			score = -2
		},
	},
})

-- 秘計
sgs.registerMasochismRecommend("miji", {
	invalid = 2,
	rules = {
		{ when = function() return true end, score = -2 },
	},
})

sgs.registerMasochismRecommend("nosmiji", {
	invalid = 2,
	rules = {
		{ when = function() return true end, score = -2 },
	},
})

-- 歸心
sgs.registerMasochismRecommend("guixin", {
	invalid = 2,
	rules = {
		{ when = function(self, from, to, card) return to:aliveCount() > 2 end, score = -2 },
	},
})

-- 放逐
sgs.registerMasochismRecommend("fangzhu", {
	invalid = 4,
	rules = {
		{
			when = function(self, from, to, card)
	local apn = self:getAllPeachNum(to)
	local damageNum = self:ajustDamage(from, to, 1, card)
				return to:getLostHp() < 2 or (apn + to:getHp() > damageNum and #self:getFriends(to) > 1)
			end,
			score = -4
		},
	},
})

-- 揮淚
sgs.registerMasochismRecommend("huilei", {
	invalid = 3,
	rules = {
		{
			when = function(self, from, to, card)
	local damageNum = self:ajustDamage(from, to, 1, card)
				return not to:isLord() and to:getHp() <= damageNum and from:getHandcardNum() >= 4
			end,
			score = -3
		},
		{
			when = function(self, from, to, card)
				local damageNum = self:ajustDamage(from, to, 1, card)
				return not to:isLord() and to:getHp() <= damageNum
					and self.compareRoleEvaluation and self:compareRoleEvaluation(to, "rebel", "loyalist") == "rebel"
			end,
			score = 0
		},
		{
			when = function(self, from, to, card)
				local damageNum = self:ajustDamage(from, to, 1, card)
				return not to:isLord() and to:getHp() <= damageNum
			end,
			score = -2
		},
	},
})

-- 天香
sgs.registerMasochismRecommend("tianxiang", {
	invalid = 2,
	rules = {
		{
			when = function(self, from, to, card)
				if not getKnownCard or target_known(getKnownCard(to, from, "diamond,club"), "recommend:tianxiang known suits") >= to:getHandcardNum() then
					return false
				end
		local damageNum = self:ajustDamage(from, to, 1, card)
		for _, friend in ipairs(self.friends or {}) do
			if friend:getHp() + self:getCardsNum("Peach") - damageNum < 2 then
						return true
			end
		end
				return false
			end,
			score = -2
		},
	},
})

-- 武魂
sgs.registerMasochismRecommend("wuhun", {
	invalid = 5,
	rules = {
		{
			when = function(self, from, to, card)
				if to:isLord() or #self:getFriends(to, true) == 0 then return false end
		local maxfriendmark, maxenemymark = 0, 0
		for _, friend in ipairs(self.friends or {}) do
			local friendmark = friend:getMark("&nightmare+#" .. to:objectName())
					if friendmark > maxfriendmark then maxfriendmark = friendmark end
		end
		for _, enemy in ipairs(self.enemies or {}) do
			local enemymark = enemy:getMark("&nightmare+#" .. to:objectName())
					if enemymark > maxenemymark and enemy:objectName() ~= to:objectName() then maxenemymark = enemymark end
		end
		local damageNum = self:ajustDamage(from, to, 1, card)
		if self:isEnemy(to) then
					return maxfriendmark + damageNum - to:getHp() / 2 >= maxenemymark
						and not (#self.enemies == 1 and #self.friends + #self.enemies == self.room:alivePlayerCount())
				else
					return maxfriendmark + damageNum - to:getHp() / 2 > maxenemymark
			end
			end,
			score = -5
		},
	},
})

-- 斷腸
sgs.registerTargetRecommend("duanchang", function(self, from, to, card, skill_owner, ctx)
	if not ctx.isDamage then
		return 0
	end
	local damageNum = self:ajustDamage(from, to, 1, card)
	if to:getHp() <= damageNum and from:getMaxHp() < 6 and not to:isLord() and #self:getFriends(to, true) > 0 then
		if not (from:getMaxHp() >= 3 and from:getArmor() and from:getDefensiveHorse()) then
			if from:isLord() and self:isWeak() or (self.room:getLord() and target_known(from:getRole(), "recommend:duanchang source role") == "renegade") then
				return -5
			end
		end
	end
	return 0
end)

-- 雪恨/血集/新剛烈
sgs.registerTargetRecommend("xuehen", function(self, from, to, card, skill_owner, ctx)
	if not ctx.isDamage then
		return 0
	end
	if self.isWeak and self:isWeak(self.friends) then
		return -2
	end
	return 0
end)

sgs.ai_target_recommend["xueji"] = function(self, from, to, card, skill_owner, ctx)
	if not to:hasSkill("xueji") then
		return 0
	end
	return sgs.ai_target_recommend["xuehen"](self, from, to, card, skill_owner, ctx)
end

sgs.ai_target_recommend["neoganglie"] = function(self, from, to, card, skill_owner, ctx)
	if not to:hasSkill("neoganglie") then
		return 0
	end
	return sgs.ai_target_recommend["xuehen"](self, from, to, card, skill_owner, ctx)
end

-- 魂姿
sgs.registerTargetRecommend("hunzi", function(self, from, to, card, skill_owner, ctx)
	if not ctx.isDamage then
		return 0
	end
	if self:isFriend(from, to) and to:getHp() == 2 and to:getMark("hunzi") < 1 then
		local damageNum = self:ajustDamage(from, to, 1, card)
		if math.abs(damageNum) == 1 and not ctx.isVirtual and card:isKindOf("Slash") and card:getSkillName() ~= "lihuo" then
			return 10
		end
	end
	if to:getMark("hunzi") < 1 and to:isLord() and to:getHp() >= 2 then
		local damageNum = self:ajustDamage(from, to, 1, card)
		if math.abs(damageNum) == 1 and target_known(target_known(self:getRoleCounts(), "public role counts")["loyalist"], "public loyalist count") > 0 then
			return -2
		end
	end
	return 0
end)

-- 固穀（特殊：判斷 from 持有技能，直接賦值）
sgs.ai_target_recommend["guagu"] = function(self, from, to, card, skill_owner, ctx)
	if not card or ctx.isVirtual or not card:isKindOf("Slash") then
		return 0
	end
	if to:isLord() and from:hasSkill("guagu") then
		if to:getLostHp() >= 1 and target_known(getCardsNum("Jink", to, from), "recommend:guagu Jink count") < 1 then
			if self:isFriend(from, to) then
				local damageNum = self:ajustDamage(from, to, 1, card)
				if math.abs(damageNum) == 1 and card:getSkillName() ~= "lihuo" then
					return 10
				end
			end
		end
	end
	return 0
end

-- 連鎖配合（全局型）
sgs.registerGlobalTargetRecommend("chain_slash_friend", function(self, from, to, card, skill_owner, ctx)
	if not card or ctx.isVirtual or not card:isKindOf("NatureSlash") then
		return 0
	end
	if self:isFriend(from, to) and hasChainEffect(to, from) then
		if self:isGoodChainTarget(to, card, from) then
			return 10
		end
	end
	return 0
end)

-- 求援效果（全局型）
sgs.registerGlobalTargetRecommend("qiuyuan_effect", function(self, from, to, card, skill_owner, ctx)
	if not card or ctx.isVirtual or not card:isKindOf("Slash") then
		return 0
	end
	if self:hasQiuyuanEffect(from, to) then
		return 10
	end
	return 0
end)

-- 雷擊配合（全局型）
sgs.registerGlobalTargetRecommend("leiji_slash_friend", function(self, from, to, card, skill_owner, ctx)
	if not card or ctx.isVirtual or not card:isKindOf("Slash") then
		return 0
	end
	if self:isFriend(from, to) then
		if (to:isWounded() and self:findLeijiTarget(to, 50, from, 1))
		   or self:findLeijiTarget(to, 50, from, -1) then
			local damageNum = self:ajustDamage(from, to, 1, card)
			if math.abs(damageNum) == 1 and card:getSkillName() ~= "lihuo" then
				return 10
			end
		end
	end
	return 0
end)

-- 激昂
sgs.registerTargetRecommend("jiang", function(self, from, to, card, skill_owner, ctx)
	if not card or ctx.isVirtual then
		return 0
	end
	local is_duel = card:isKindOf("Duel")
	local is_red_slash = card:isKindOf("Slash") and card:isRed()
	if is_duel or is_red_slash then
		return -1
	end
	return 0
end)


-- Four effective Scarlet dependencies. These functions are enabled only by
-- immutable native wrapper/upvalue origin evidence, not by an assumed package.
-- Ordinary Standard registers its own Rende/Fankui later; no substitute here.
local function scarlet_hunzi_instance(player)
    local view = rawget(player, "_view")
    if type(view) ~= "table" or view.skills_complete ~= true then
        ai_unsupported("first skill instance requires a complete lawful instance set", "s4_hunzi")
    end
    local ids = target_known(player:getSkillInstanceIds("s4_hunzi"), "s4_hunzi instance IDs")
    local first = 0
    for _, id in ipairs(ids) do
        if type(id) ~= "number" or id <= 0 or id % 1 ~= 0 then ai_unsupported("invalid skill instance identity", "s4_hunzi") end
        if first == 0 or id < first then first = id end
    end
    return first
end
sgs.registerTargetRecommend("s4_banjiang", function(self, from, to, card, skill_owner, ctx)
    if not ctx.isDamage then
        return 0
    end

    -- 檢查技能是否失效
    if self:checkMasochismInvalid(from, to, card) then
        return 0
    end

    if self:canLoseHp(from,card,to) then
        if self:isEnemy(to, from) then
            return -1
        end
        if self:isFriend(to, from) then
            return 1
        end
    end

    return 0
end)
scarlet_recommend_callbacks[sgs.ai_target_recommend["s4_banjiang"]] = "s4_banjiang"

sgs.registerMasochismRecommend("s4_ganglie", {
	invalid = 3,
	rules = {
		{ when = function(self, from, to, card) return from:getHp() < 2 end, score = -3 },
	},
})
scarlet_recommend_callbacks[sgs.ai_target_recommend.s4_ganglie] = "s4_ganglie"

sgs.registerTargetRecommend("s4_hunzi", function(self, from, to, card, skill_owner, ctx)
    local mark = to:getMark("s4_hunzi"..scarlet_hunzi_instance(to))
    if mark > 0 then return 0 end  -- already awakened
    if not ctx.isDamage then return 0 end
    -- ally decision: help trigger wake
    if self:isFriend(from, to) and to:getHp() == 1 and to:getLostHp() >= 2 then
        return 5
    end
    -- enemy decision: avoid triggering wake when enemy is low
    if self:isEnemy(from, to) and to:getHp() <= 1 and to:getLostHp() <= 1 then
        return -3
    end
    return 0
end)
scarlet_recommend_callbacks[sgs.ai_target_recommend["s4_hunzi"]] = "s4_hunzi"

sgs.registerTargetRecommend("s4_qiaobian", function(self, from, to, card, skill_owner, ctx)
	if ctx.isDraw and self:isFriend(from, to) and to:hasSkill("s4_qiaobian") then
		return 2
	end
	if ctx.isDecrease and self:isEnemy(from, to) and to:hasSkill("s4_qiaobian") then
		if self:doDisCard(to, "h") then
			return 1
		end
	end
	return 0
end)
scarlet_recommend_callbacks[sgs.ai_target_recommend["s4_qiaobian"]] = "s4_qiaobian"

-- smart-ai.lua:4652. The native PlayerChosen input is a QList: sort returns
-- its table copy, and the donor deliberately passes the original target list.
-- Keep the sort's cache effects without changing equal-score target order.
sgs.ai_skill_playerchosen.damage=function(self,targets)
    local sorted=self:sort(targets,"hp")
    if AIUnsupported.is(sorted) then error(sorted,0) end
    local ranked=self:findPlayerToDamage(1,self.player,"N",targets,0,nil)
    if AIUnsupported.is(ranked) then error(ranked,0) end
    return ranked[1]
end

return sgs
