extension = sgs.Package("offline", sgs.Package_GeneralPack)
extension_card = sgs.Package("ofl_card", sgs.Package_CardPack)

sgs.LoadTranslationTable {
	["offline"] = "线下官正",
	["ofl_card"] = "线下官正",
}
sgs.LoadTranslationTable {
	["sijyuoffline_zhaoyun"] = "赵云[联想]",
	["&sijyuoffline_zhaoyun"] = "赵云",
	["#sijyuoffline_zhaoyun"] = "白马先锋",
	["~sijyuoffline_zhaoyun"] = "",
	["designer:sijyuoffline_zhaoyun"] = "",
	["cv:sijyuoffline_zhaoyun"] = "",
	["illustrator:sijyuoffline_zhaoyun"] = "VINCENT",

	--三国杀旧藏版：往昔龙吟
	--yt_shencaocao skin
	["zhaoyeyushizi"] = "照夜玉狮子",
	[":zhaoyeyushizi"] = "装备牌·坐骑<br /><b>坐骑技能</b>：你与其他角色的距离-1。",

	--徐荣礼盒
	["sijyuoffline_huyi"] = "虎翼",
	[":sijyuoffline_huyi"] = "装备牌·武器\
	攻击范围：3\
	攻击效果：你使用【杀】对目标造成属性伤害时，你可以横置至多两名角色。",
	["@sijyuoffline_huyi"] = "虎翼：你可以横置至多两名角色",
}

sijyuoffline_zhaoyun = sgs.General(extension, "sijyuoffline_zhaoyun", "shu", 3)

sijyuoffline_zhaoyun:addSkill("longdan")
sijyuoffline_zhaoyun:addSkill("chongzhen")

zhaoyeyushizi = sgs.CreateOffensiveHorse {
	name = "zhaoyeyushizi",
	class_name = "Zhaoyeyushizi",
	suit = sgs.Card_Heart,
	number = 5,
}
zhaoyeyushizi:setParent(extension_card)

--[[
	技能名：虎翼
	技能描述：你使用【杀】对目标造成属性伤害时，你可以横置至多两名角色。
	引用：sfofl_yice
]]
--

sijyuoffline_huyi_skill = sgs.CreateTriggerSkillV2 {
	name = "sijyuoffline_huyi", --一般的话，技能的objectName()和武器的objectName(）用一样的名字
	frequency = sgs.Skill_Compulsory,
	events = { sgs.DamageCaused },
	can_trigger = function(skill, event, room, player, data)
		if not player or not player:hasWeapon(skill:objectName()) then return false end
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") and damage.card:isKindOf("NatureSlash") and not damage.transfer and not damage.chain then
			if damage.from and damage.from:objectName() == player:objectName() then
				return skill:objectName()
			end
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		local others = room:askForPlayersChosen(player, room:getAlivePlayers(), skill:objectName(), 0, 2, "@sijyuoffline_huyi", true, true)
		if not others or others:length() == 0 then return false end
		for _, enemy in sgs.qlist(others) do
			ctx.targets:append(enemy)
		end
		return true
	end,
	on_effect_target = function(skill, event, room, player, ctx, target)
		if not target:isChained() then
			room:setPlayerChained(target)
		end
		return false
	end,
}
sijyuoffline_huyi = sgs.CreateWeapon {
	name = "sijyuoffline_huyi",
	class_name = "Huyi",
	suit = sgs.Card_Spade,
	number = 11,
	range = 3,
	equip_skill = sijyuoffline_huyi_skill,
}
sijyuoffline_huyi:setParent(extension_card)

-- GU 官正 2026. SOURCE.md (Tom 2026-10-13) is authoritative.
-- These helpers remain in the existing offline package.
local function gu_ids(cards)
    local ids = sgs.IntList()
    for _, c in ipairs(cards) do ids:append(c:getEffectiveId()) end
    return ids
end
local function gu_dummy(ids)
    local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    c:addSubcards(ids)
    return c
end
local function gu_obtain(room, p, ids, skill)
    if ids:isEmpty() then return end
    local c = gu_dummy(ids)
    room:obtainCard(p, c, skill, false)
    c:deleteLater()
end
local function gu_trigger(name, events, effect, compulsory, frequency, limit_mark)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        frequency = frequency or (compulsory and sgs.Skill_Compulsory or sgs.Skill_NotFrequent), limit_mark = limit_mark,
        can_trigger = function(self, event, room, player, data)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then return self:objectName(), p end
            end
            return false
        end,
        on_effect = function(self, event, room, player, ctx)
            local cancelled = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then
                    cancelled = effect(self, event, room, player, ctx.original_data, p) or cancelled
                end
            end
            return cancelled
        end,
    }
end
local function gu_record(name, events, fn)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        can_trigger = function() return false end,
        on_record = function(self, event, room, player, ctx)
            fn(self, event, room, player, ctx.original_data)
        end,
    }
end
local function gu_active(name, quota, nmin, nmax, target_filter, target_feasible, effect, select_card, activate)
    local card = sgs.CreateSkillCard {
        name = name .. "Card", will_throw = false,
        filter = target_filter, feasible = target_feasible,
        on_use = effect,
    }
    local spec = {
        name = name,
        can_activate = function(self, request)
            return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
                and (not activate or activate(request:getInitiator()))
        end,
        can_select_card = function(self, request, c)
            return request:getSelectedCardIds():length() < nmax
                and (not select_card or select_card(request, c))
        end,
        card_selection_feasible = function(self, request)
            local n = request:getSelectedCardIds():length()
            return n >= nmin and n <= nmax
        end,
        create_card = function(self, request)
            local c = card:clone()
            c:addSubcards(request:getSelectedCardIds())
            c:setSkillName(name)
            return c
        end,
    }
    if quota then
        spec.limit_scope = sgs.Skill_Limit_Phase
        spec.phase_name = "Play"
        spec.max_usage_limit = quota
    end
    return sgs.CreateViewAsSkillV2(spec)
end
local function gu_one(self, targets, to, from)
    return #targets == 0 and to:objectName() ~= from:objectName()
end
local function gu_one_feasible(self, targets) return #targets == 1 end
local function gu_throw(room, p, ids, skill)
    if ids:isEmpty() then return end
    local c = gu_dummy(ids)
    room:throwCard(c, skill, p)
    c:deleteLater()
end
local function gu_invoke(p, name, data) return p:askForSkillInvoke(name, data or sgs.QVariant()) end
local function gu_names(p, tag)
    local s = p:getTag(tag):toString()
    return s == "" and {} or s:split("+")
end
local function gu_setnames(p, tag, names) p:setTag(tag, sgs.QVariant(table.concat(names, "+"))) end

-- 界典韋: record two failed opponents, resolve the seat interval on failure two.
ofjie_dianwei = sgs.General(extension, "ofjie_dianwei", "wei", 5)
ofgu_qiangxi = gu_active("ofgu_qiangxi", nil, 0, 0,
    function(self, targets, to, from)
        return gu_one(self, targets, to, from) and not to:isKongcheng() and not from:isKongcheng()
            and to:getMark("ofgu_qiangxi_" .. from:objectName() .. "-Clear") == 0
    end, gu_one_feasible,
    function(self, room, source, targets)
        local to = targets[1]
        room:setPlayerMark(to, "ofgu_qiangxi_" .. source:objectName() .. "-Clear", 1)
        if source:pindian(to, "ofgu_qiangxi") then
            local choices = to:isNude() and "draw" or "draw+discard"
            if room:askForChoice(source, "ofgu_qiangxi", choices, ToData(to)) == "draw" then
                source:drawCards(1, "ofgu_qiangxi")
            else room:throwCard(room:askForCardChosen(source, to, "he", "ofgu_qiangxi"), to, source) end
        else
            local first = source:getTag("ofgu_qiangxi_failed"):toPlayer()
            if not first then source:setTag("ofgu_qiangxi_failed", ToData(to)); return end
            room:setPlayerMark(source, "ofgu_qiangxi_disabled-Clear", 1)
            room:loseHp(source, 1, true, source, "ofgu_qiangxi")
            local lo, hi = math.min(first:getSeat(), to:getSeat()), math.max(first:getSeat(), to:getSeat())
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:objectName() ~= source:objectName() and p:getSeat() >= lo and p:getSeat() <= hi then
                    room:damage(sgs.DamageStruct("ofgu_qiangxi", source, p, 1))
                end
            end
        end
    end, nil, function(p) return not p:isKongcheng() and p:getMark("ofgu_qiangxi_disabled-Clear") == 0 end)
ofjie_dianwei:addSkill(ofgu_qiangxi)
extension:addSkills(gu_record("#ofgu_qiangxi_clear", {sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if data:toPhaseChange().to == sgs.Player_NotActive then
        for _, q in sgs.qlist(room:getAllPlayers()) do q:removeTag("ofgu_qiangxi_failed") end
    end
end))

extension:addSkills(gu_record("#ofgu_qishen_expire", {sgs.EventPhaseChanging, sgs.EventAcquireSkill}, function(self, event, room, p, data)
    if event == sgs.EventAcquireSkill then
        local name = data:toString()
        if name == "ofgu_qishen" then return end
        for _, owner in sgs.qlist(room:getAllPlayers()) do
            if p:getMark("ofgu_qishen_" .. owner:objectName()) > 0 then
                room:addSkillInvalidity(p, name, owner:objectName(), "ofgu_qishen")
            end
        end
    elseif data:toPhaseChange().to == sgs.Player_NotActive then
        for _, q in sgs.qlist(room:getAllPlayers()) do
            local key = "ofgu_qishen_" .. p:objectName()
            room:setPlayerMark(q, key, 0)
            local records = q:getTag("SkillInvalidityRecords"):toStringList()
            for _, record in ipairs(records) do
                local parts = record:split("|")
                if parts[2] == p:objectName() and parts[3] == "ofgu_qishen" then room:removeSkillInvalidity(q, parts[1], p:objectName(), "ofgu_qishen") end
            end
        end
    end
end))
-- SOURCE-C C4; Tom confirmed 誡訓 = jiexun. The selected native 雷擊
-- describes black (both spade and club), so it is not a single-suit skill.
-- Tom: redistribute suit->skill correspondence, never native suit checks.
-- Gameplay and collision rules for reassignment are undefined; keep hidden.
local gu_huamao_candidates = {
    {"wushen", "heart"}, {"liushi", "heart"}, {"gongxin", "heart"}, {"tianxiang", "heart"},
    {"guose", "diamond"}, {"limu", "diamond"}, {"fengpo", "diamond"}, {"jiexun", "diamond"},
    {"leiji", "spade"}, {"zuoding", "spade"}, {"yimiehai", "spade"}, {"jiyu", "spade"},
    {"luoying", "club"}, {"lianhuan", "club"}, {"zhujiu", "club"}, {"kezhuanninghan", "club"},
}
local function gu_huamao_description_suits(description)
    local aliases = {
        heart = {"♥", "红桃", "紅桃", "heart"},
        diamond = {"♦", "方块", "方塊", "diamond"},
        spade = {"♠", "黑桃", "spade"},
        club = {"♣", "梅花", "club"},
    }
    local found = {}
    for suit, words in pairs(aliases) do
        for _, word in ipairs(words) do
            if string.find(description, word, 1, true) then found[suit] = true; break end
        end
    end
    -- A colour condition also includes two suits, even without suit glyphs.
    if string.find(description, "黑色", 1, true) then found.spade = true; found.club = true end
    if string.find(description, "红色", 1, true) or string.find(description, "紅色", 1, true) then
        found.heart = true; found.diamond = true
    end
    local count, only = 0, nil
    for suit in pairs(found) do count = count + 1; only = suit end
    return count, only
end
local function gu_huamao_pool()
    local pool = {}
    for _, entry in ipairs(gu_huamao_candidates) do
        local name = entry[1]
        local count, suit = gu_huamao_description_suits(sgs.Sanguosha:translate(":" .. name))
        if name ~= "leiji" and sgs.Sanguosha:getSkill(name) and count == 1 then
            table.insert(pool, {name, suit})
        end
    end
    return pool
end
local function gu_huamao_draw(pool)
    local remaining, drawn = {}, {}
    for _, entry in ipairs(pool) do table.insert(remaining, entry) end
    for _ = 1, 3 do
        if #remaining == 0 then return {} end
        local selected = remaining[math.random(#remaining)]
        table.insert(drawn, selected)
        local next_pool = {}
        for _, entry in ipairs(remaining) do
            if entry[2] ~= selected[2] then table.insert(next_pool, entry) end
        end
        remaining = next_pool
    end
    return drawn
end
-- Track acquired instance IDs, so shuffle cannot remove another source's copy.
local function gu_huamao_clear(room, owner)
    local grants = gu_names(owner, "ofgu_huamao_grants")
    gu_setnames(owner, "ofgu_huamao_grants", {})
    for _, mapping in ipairs(gu_names(owner, "ofgu_huamao_mapping")) do
        local parts = mapping:split("|")
        room:setPlayerMark(owner, "&ofgu_huamao+" .. parts[1] .. "+" .. parts[2], 0)
    end
    gu_setnames(owner, "ofgu_huamao_mapping", {})
    for _, grant in ipairs(grants) do
        local parts = grant:split("|")
        room:setPlayerMark(owner, "&ofgu_huamao+" .. parts[2] .. "+" .. parts[1], 0)
        room:detachSkillFromPlayer(owner, parts[1] .. "#" .. parts[3], false, true)
    end
end
ofgu_huamao = gu_trigger("ofgu_huamao", {sgs.RoundStart}, function(self, event, room, p, data, owner)
    if p ~= owner or data:toInt() ~= 1 or owner:getMark("ofgu_huamao_started") > 0 then return end
    room:setPlayerMark(owner, "ofgu_huamao_started", 1)
    local drawn = gu_huamao_draw(gu_huamao_pool())
    local shuffle = room:getTag("SwapPile"):toInt()
    for _, entry in ipairs(drawn) do
        local name, suit = entry[1], entry[2]
        -- Acquired roots automatically bring their native related helpers.
        local id = room:acquireSkillUnbound(owner, name)
        if id > 0 then
            if room:getTag("SwapPile"):toInt() ~= shuffle then
                room:detachSkillFromPlayer(owner, name .. "#" .. id, false, true)
                return
            end
            local grants = gu_names(owner, "ofgu_huamao_grants")
            table.insert(grants, name .. "|" .. suit .. "|" .. id)
            gu_setnames(owner, "ofgu_huamao_grants", grants)
            local mapping = gu_names(owner, "ofgu_huamao_mapping")
            table.insert(mapping, suit .. "|" .. name)
            gu_setnames(owner, "ofgu_huamao_mapping", mapping)
            room:setPlayerMark(owner, "&ofgu_huamao+" .. suit .. "+" .. name, 1)
        end
    end
    -- Reassign the correspondence only; native skill suit checks stay intact.
    local mapping = gu_names(owner, "ofgu_huamao_mapping")
    if #mapping == 0 or not room:askForSkillInvoke(owner, "ofgu_huamao_reassign") then return end
    for index = 1, #mapping do
        if room:getTag("SwapPile"):toInt() ~= shuffle then return end
        local current = mapping[index]:split("|")
        local suit = room:askForChoice(owner, "ofgu_huamao_reassign",
            "heart+diamond+spade+club", sgs.QVariant(current[2]))
        if room:getTag("SwapPile"):toInt() ~= shuffle then return end
        for other, item in ipairs(mapping) do
            local parts = item:split("|")
            if other ~= index and parts[1] == suit then
                mapping[other] = current[1] .. "|" .. parts[2]
                room:setPlayerMark(owner, "&ofgu_huamao+" .. suit .. "+" .. parts[2], 0)
                room:setPlayerMark(owner, "&ofgu_huamao+" .. current[1] .. "+" .. parts[2], 1)
                break
            end
        end
        room:setPlayerMark(owner, "&ofgu_huamao+" .. current[1] .. "+" .. current[2], 0)
        mapping[index] = suit .. "|" .. current[2]
        room:setPlayerMark(owner, "&ofgu_huamao+" .. suit .. "+" .. current[2], 1)
        gu_setnames(owner, "ofgu_huamao_mapping", mapping)
    end
end)
extension:addSkills(gu_record("#ofgu_huamao_expire", {sgs.SwappedPile}, function(self, event, room, p, data)
    -- The engine dispatches once per player, including dead players. Cleanup
    -- does not depend on retaining Huamao or on its current validity.
    if p then gu_huamao_clear(room, p) end
end))
of_wencaozhi = sgs.General(extension, "of_wencaozhi", "wei", 4, true)
ofgu_qishen = gu_trigger("ofgu_qishen", {sgs.EventPhaseChanging, sgs.DamageCaused}, function(self, event, room, p, data, owner)
    local key = "ofgu_qishen_" .. owner:objectName()
    if event == sgs.DamageCaused then
        local d = data:toDamage()
        if d.from and d.from:getMark(key) > 0 then d.damage = d.damage + 1; data:setValue(d) end
    elseif p:objectName() == owner:objectName() and data:toPhaseChange().to == sgs.Player_NotActive then
        local old = gu_names(owner, "ofgu_qishen_previous")
        for _, q in sgs.qlist(room:getAllPlayers()) do
            room:setPlayerMark(q, key, 0)
            for _, skill in sgs.qlist(q:getSkillList(false, false)) do
                room:removeSkillInvalidity(q, skill:objectName(), owner:objectName(), "ofgu_qishen")
            end
        end
        local chosen = room:askForPlayersChosen(owner, room:getAlivePlayers(), self:objectName(), 0, 3, "@ofgu_qishen", true, true)
        local names = {}
        for _, q in sgs.qlist(chosen) do
            table.insert(names, q:objectName())
            room:setPlayerMark(q, key, 1)
            for _, skill in sgs.qlist(q:getSkillList(false, false)) do
                if skill:objectName() ~= "ofgu_qishen" then room:addSkillInvalidity(q, skill:objectName(), owner:objectName(), "ofgu_qishen") end
            end
        end
        gu_setnames(owner, "ofgu_qishen_previous", names)
        for _, q in sgs.qlist(chosen) do
            if table.contains(old, q:objectName()) then q:drawCards(3, self:objectName()) end
        end
    end
end)
of_wencaozhi:addSkill(ofgu_huamao)
of_wencaozhi:addSkill(ofgu_qishen)

of_xiaokongrong = sgs.General(extension, "of_xiaokongrong", "qun", 3)
ofgu_cirang = gu_trigger("ofgu_cirang", {sgs.CardsMoveOneTime}, function(self, event, room, p, data, owner)
    local m = data:toMoveOneTime()
    if not m.to or m.to:objectName() ~= owner:objectName() or m.to_place ~= sgs.Player_PlaceHand
        or m.card_ids:length() < 2 or owner:getMark("ofgu_cirang-Clear") > 0 then return end
    local ids, highest = sgs.IntList(), 0
    for _, id in sgs.qlist(m.card_ids) do
        if room:getCardOwner(id) == owner and room:getCardPlace(id) == sgs.Player_PlaceHand then
            ids:append(id); highest = math.max(highest, sgs.Sanguosha:getCard(id):getNumber())
        end
    end
    if ids:length() < 2 or not gu_invoke(owner, self:objectName(), data) then return end
    room:setPlayerMark(owner, "ofgu_cirang-Clear", 1)
    for _, id in sgs.qlist(ids) do room:showCard(owner, id) end
    while owner:isAlive() and not ids:isEmpty() do
        if not room:askForYiji(owner, ids, self:objectName(), false, false, true, -1, room:getAlivePlayers()) then break end
        local remaining = sgs.IntList()
        for _, id in sgs.qlist(ids) do
            if room:getCardOwner(id) == owner and room:getCardPlace(id) == sgs.Player_PlaceHand then remaining:append(id) end
        end
        if remaining:length() == ids:length() then break end
        ids = remaining
    end
    for _, id in sgs.qlist(m.card_ids) do
        if sgs.Sanguosha:getCard(id):getNumber() == highest and room:getCardOwner(id) == owner
            and room:getCardPlace(id) == sgs.Player_PlaceHand then return end
    end
    owner:drawCards(1, self:objectName())
end)
ofgu_liaoliao = gu_trigger("ofgu_liaoliao", {sgs.TurnStart}, function(self, event, room, p, data, owner)
    if p == owner or owner:isNude() then return end
    local c = room:askForCard(owner, "..", "@ofgu_liaoliao", data, sgs.Card_MethodDiscard, p, false, self:objectName())
    if c then room:setPlayerMark(owner, "ofgu_liaoliao-Clear", c:getNumber()) end
end)
ofgu_liaoliao_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#ofgu_liaoliao_prohibit",
    holder_selector = sgs.CorrectSkill_System,
    gate = { "secondary.mark:ofgu_liaoliao-Clear" },
    is_prohibited = function(self, ctx)
        local to, card = ctx:getTo(), ctx:getCard()
        return to:getMark("ofgu_liaoliao-Clear") > 0 and card:getNumber() > to:getMark("ofgu_liaoliao-Clear")
    end,
}
of_xiaokongrong:addSkill(ofgu_cirang); of_xiaokongrong:addSkill(ofgu_liaoliao); of_xiaokongrong:addSkill(ofgu_liaoliao_prohibit)

ofjie_xuhuang = sgs.General(extension, "ofjie_xuhuang", "wei", 4)
ofgu_duanliang = sgs.CreateViewAsSkillV2 {
    name = "ofgu_duanliang",
    can_activate = function(self, request) return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY end,
    can_select_card = function(self, request, c)
        return request:getSelectedCardIds():isEmpty() and c:isBlack() and not c:isKindOf("TrickCard")
            and not request:getInitiator():isJilei(c)
    end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():length() == 1 end,
    create_card = function(self, request)
        local c = sgs.Sanguosha:cloneCard("supply_shortage", sgs.Card_NoSuit, 0)
        c:addSubcards(request:getSelectedCardIds()); c:setSkillName("ofgu_duanliang"); return c
    end,
}
ofgu_duanliang_mod = sgs.CreateTargetModSkillV2 {
    name = "#ofgu_duanliang_mod", pattern = "SupplyShortage", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        if ctx:getModType() == sgs.TargetModSkill_DistanceLimit and ctx:getCard():getSkillName() == "ofgu_duanliang" then return 999 end
        return 0
    end,
}
ofgu_duanliang_draw = gu_trigger("#ofgu_duanliang_draw", {sgs.CardFinished}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from == owner and use.card:getSkillName() == "ofgu_duanliang" then
        for _, to in sgs.qlist(use.to) do
            if to:getHandcardNum() > owner:getHandcardNum() then owner:drawCards(1, "ofgu_duanliang") end
        end
    end
end)
ofgu_zier = gu_trigger("ofgu_zier", {sgs.RoundStart, sgs.EventPhaseSkipped, sgs.TurnStart, sgs.EventPhaseChanging}, function(self, event, room, p, data, owner)
    if event == sgs.RoundStart then
        room:setPlayerMark(owner, "ofgu_zier_used", 0); owner:removeTag("ofgu_zier_phases")
    elseif event == sgs.EventPhaseSkipped then
        if gu_invoke(owner, self:objectName(), data) then
            local phases = gu_names(owner, "ofgu_zier_phases"); local phase = tostring(p:getPhase())
            if not table.contains(phases, phase) then table.insert(phases, phase); gu_setnames(owner, "ofgu_zier_phases", phases) end
        end
    elseif event == sgs.TurnStart then
        local phases = gu_names(owner, "ofgu_zier_phases")
        if #phases == 0 or owner:getMark("ofgu_zier_used") > 0 or not gu_invoke(owner, self:objectName(), data) then return end
        local change = room:askForChoice(owner, self:objectName(), "judge+draw+play+discard+finish", ToData(p))
        local into = room:askForChoice(owner, self:objectName(), table.concat(phases, "+"), ToData(p))
        p:setTag("ofgu_zier_replace", sgs.QVariant(change .. ":" .. into)); room:setPlayerMark(owner, "ofgu_zier_used", 1)
    else
        local tag = p:getTag("ofgu_zier_replace"):toString()
        if tag == "" then return end
        local pair = tag:split(":"); local phases = {judge=sgs.Player_Judge, draw=sgs.Player_Draw, play=sgs.Player_Play, discard=sgs.Player_Discard, finish=sgs.Player_Finish}
        local change = data:toPhaseChange()
        if change.to == phases[pair[1]] then change.to = tonumber(pair[2]); data:setValue(change); p:removeTag("ofgu_zier_replace") end
        if change.to == sgs.Player_NotActive then p:removeTag("ofgu_zier_replace") end
    end
end)
ofjie_xuhuang:addSkill(ofgu_duanliang); ofjie_xuhuang:addSkill(ofgu_duanliang_mod); ofjie_xuhuang:addSkill(ofgu_duanliang_draw); ofjie_xuhuang:addSkill(ofgu_zier)

ofjie_zhurong = sgs.General(extension, "ofjie_zhurong", "shu", 4, false)
ofgu_lieren = gu_trigger("ofgu_lieren", {sgs.TargetSpecified, sgs.CardFinished}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from ~= owner or not use.card:isKindOf("Slash") then return end
    if event == sgs.TargetSpecified then
        room:addPlayerMark(owner, "ofgu_lieren-Clear")
        if owner:getMark("ofgu_lieren-Clear") ~= 1 or use.to:length() ~= 1 then return end
        local to = use.to:first()
        if owner:isKongcheng() or to:isKongcheng() or not gu_invoke(owner, self:objectName(), data) then return end
        local pd = owner:PinDian(to, self:objectName())
        local winner = pd.from_number > pd.to_number and owner or (pd.to_number > pd.from_number and to or nil)
        if winner then use.card:setTag("ofgu_lieren_winner", ToData(winner)) end
    else
        local winner = use.card:getTag("ofgu_lieren_winner"):toPlayer()
        use.card:removeTag("ofgu_lieren_winner")
        if winner and winner:isAlive() and not winner:isKongcheng() then
            local c = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
            c:addSubcards(winner:handCards()); c:setSkillName(self:objectName())
            room:useCard(sgs.CardUseStruct(c, winner, sgs.SPlayerList()), false); c:deleteLater()
        end
    end
end)
ofgu_juxiang = gu_trigger("ofgu_juxiang", {sgs.CardEffected, sgs.CardFinished, sgs.DamageCaused}, function(self, event, room, p, data, owner)
    if event == sgs.CardEffected then
        local e = data:toCardEffect()
        return e.to == owner and e.from ~= owner and e.card:isKindOf("SavageAssault")
    elseif event == sgs.CardFinished then
        local use = data:toCardUse()
        if use.from ~= owner and use.card:isKindOf("SavageAssault") and room:getCardPlace(use.card:getEffectiveId()) == sgs.Player_DiscardPile then
            room:obtainCard(owner, use.card, self:objectName(), true)
        end
    else
        local d = data:toDamage()
        if d.from == owner and d.card and d.card:isKindOf("SavageAssault") and d.to:getHp() > owner:getHp() and gu_invoke(owner, self:objectName(), data) then
            d.damage = d.damage + 1; data:setValue(d)
        end
    end
end)
ofjie_zhurong:addSkill(ofgu_lieren); ofjie_zhurong:addSkill(ofgu_juxiang)

of_zhangxingcai = sgs.General(extension, "of_zhangxingcai", "shu", 4, false)
ofgu_hengren = gu_trigger("ofgu_hengren", {sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.PreCardUsed, sgs.DamageCaused}, function(self, event, room, p, data, owner)
    if event == sgs.PreCardUsed then
        local use = data:toCardUse()
        if use.from == owner and owner:hasFlag("ofgu_hengren_using") and use.card:isKindOf("Slash") then
            room:setCardFlag(use.card, "ofgu_hengren")
            room:addPlayerHistory(room:getCurrent(), "Slash", 1)
        end
    elseif event == sgs.DamageCaused then
        local d = data:toDamage()
        if d.card and d.card:hasFlag("ofgu_hengren") then d.damage = d.damage + 1; data:setValue(d) end
    elseif p ~= owner and p:getPhase() == sgs.Player_Play and sgs.Slash_IsAvailable(p) then
        local yang = owner:getMark("ofgu_hengren_yin") == 0
        if (event == sgs.EventPhaseStart) ~= yang then return end
        room:setPlayerFlag(owner, "ofgu_hengren_using")
        local c = room:askForUseCard(owner, "slash", "@ofgu_hengren", -1, sgs.Card_MethodUse, false)
        room:setPlayerFlag(owner, "-ofgu_hengren_using")
        if c then room:setPlayerMark(owner, "ofgu_hengren_yin", yang and 1 or 0) end
    end
end)
ofgu_danjue = gu_trigger("ofgu_danjue", {sgs.TargetConfirmed}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if not use.card:isKindOf("Slash") or not use.to:contains(p) or owner:distanceTo(p) > 1 then return end
    if not gu_invoke(owner, self:objectName(), data) then return end
    if use.m_addHistory then
        room:addPlayerHistory(use.from, "Slash", -1); use.m_addHistory = false; data:setValue(use)
    end
    p:drawCards(1, self:objectName())
    if p ~= owner and not p:isNude() then
        local c = room:askForCard(p, "..", "@ofgu_danjue:" .. owner:objectName(), ToData(owner), sgs.Card_MethodNone, owner, false, self:objectName())
        if c then room:giveCard(p, owner, c, self:objectName()) end
    end
end)
of_zhangxingcai:addSkill(ofgu_hengren); of_zhangxingcai:addSkill(ofgu_danjue)

of_wencaopi = sgs.General(extension, "of_wencaopi", "wei", 3)
local function gu_fangzhu(room, source, to, skill)
    local n = source:getLostHp()
    to:turnOver()
    if to:isAlive() and n > 0 then to:drawCards(n, skill) end
end
ofgu_fangzhu = gu_trigger("ofgu_fangzhu", {sgs.Damaged}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    local choices = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getOtherPlayers(owner)) do
        if q:hasSkill("ofgu_yishi") then choices:append(q) end
    end
    if choices:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, choices, self:objectName(), "@ofgu_fangzhu", true, true)
    if to then gu_fangzhu(room, owner, to, self:objectName()) end
end)
extension:addSkills(ofgu_fangzhu)
ofgu_yishi = gu_active("ofgu_yishi", nil, 0, 0, function(self, targets) return false end,
    function(self, targets) return #targets == 0 end,
    function(self, room, source, targets)
        room:removePlayerMark(source, "@ofgu_yishi")
        for _, to in sgs.qlist(room:getOtherPlayers(source)) do
            gu_fangzhu(room, source, to, "ofgu_yishi")
            if to:isAlive() then room:acquireSkill(to, "ofgu_fangzhu") end
        end
    end, nil, function(p) return p:getMark("@ofgu_yishi") > 0 end)
ofgu_yishi_init = gu_record("#ofgu_yishi_init", {sgs.GameStart}, function(self, event, room, p, data)
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if q:hasSkill("ofgu_yishi") then room:setPlayerMark(q, "@ofgu_yishi", 1) end
    end
end)
-- Links keep physical card IDs: a moved link cannot be silently replaced.
ofgu_nianjun = gu_trigger("ofgu_nianjun", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Finish or p:isKongcheng() then return end
    local c = room:askForCard(owner, ".|.|.|hand", "@ofgu_nianjun-self", data, sgs.Card_MethodNone, nil, false, self:objectName())
    if not c then return end
    local candidates = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getOtherPlayers(owner)) do if not q:isKongcheng() then candidates:append(q) end end
    local tos = room:askForPlayersChosen(owner, candidates, self:objectName(), 0, candidates:length(), "@ofgu_nianjun", true, true)
    if tos:isEmpty() then return end
    local links = owner:getTag("ofgu_nianjun_ids"):toIntList()
    if not links:contains(c:getEffectiveId()) then links:append(c:getEffectiveId()) end
    room:setPlayerMark(owner, "ofgu_nianjun_link", 1)
    for _, q in sgs.qlist(tos) do
        local id = room:askForCardChosen(owner, q, "h", self:objectName())
        if not links:contains(id) then links:append(id) end
        room:setPlayerMark(q, "ofgu_nianjun_link", 1)
    end
    owner:setTag("ofgu_nianjun_ids", ToData(links))
end)
ofgu_nianjun_record = gu_record("#ofgu_nianjun_record", {sgs.CardsMoveOneTime, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to == sgs.Player_NotActive then room:removeTag("ofgu_nianjun_lost") end
        return
    end
    local move = data:toMoveOneTime()
    if not move.from then return end
    local lost = false
    for _, owner in sgs.qlist(room:getAllPlayers()) do
        local ids = owner:getTag("ofgu_nianjun_ids"):toIntList()
        for i, id in sgs.qlist(move.card_ids) do
            if move.from_places:at(i) == sgs.Player_PlaceHand and ids:contains(id) then
                ids:removeOne(id); lost = true
            end
        end
        owner:setTag("ofgu_nianjun_ids", ToData(ids))
    end
    for _, q in sgs.qlist(room:getAllPlayers()) do
        local linked = false
        for _, owner in sgs.qlist(room:getAllPlayers()) do
            for _, id in sgs.qlist(owner:getTag("ofgu_nianjun_ids"):toIntList()) do
                if room:getCardOwner(id) == q and room:getCardPlace(id) == sgs.Player_PlaceHand then linked = true end
            end
        end
        room:setPlayerMark(q, "ofgu_nianjun_link", linked and 1 or 0)
    end
    if lost and not room:getTag("ofgu_nianjun_lost"):toBool() then
        room:setTag("ofgu_nianjun_lost", sgs.QVariant(true))
        local from = room:findPlayerByObjectName(move.from:objectName())
        if from and from:isAlive() then room:loseHp(from, 1, true, nil, "ofgu_nianjun") end
    end
end)
ofgu_nianjun_mod = sgs.CreateTargetModSkillV2 {
    name = "#ofgu_nianjun_mod", pattern = ".", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local from, to = ctx:getPrimary(), ctx:getSecondary()
        if ctx:getModType() == sgs.TargetModSkill_Residue and from and to
            and from ~= to and from:getMark("ofgu_nianjun_link") > 0 and to:getMark("ofgu_nianjun_link") > 0 then return 999 end
        return 0
    end,
}
ofgu_qianqian = gu_record("ofgu_qianqian", {sgs.TurnStart, sgs.EventPhaseChanging, sgs.PreCardUsed, sgs.GameStart, sgs.EventAcquireSkill}, function(self, event, room, p, data)
    if event == sgs.PreCardUsed then
        if p and p:hasSkill(self:objectName()) then
            room:setPlayerMark(p, "ofgu_qianqian-Clear", 1)
            room:removePlayerCardLimitationByReason(p, "ofgu_qianqian")
        end
    elseif event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to ~= sgs.Player_NotActive then return end
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            if q:hasSkill(self:objectName()) then
                room:removePlayerCardLimitationByReason(q, "ofgu_qianqian")
                room:setPlayerCardLimitation(q, "use", ".|heart", false, "ofgu_qianqian")
            end
        end
    else
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            if q:hasSkill(self:objectName()) and q:getMark("ofgu_qianqian-Clear") == 0 then
                room:removePlayerCardLimitationByReason(q, "ofgu_qianqian")
                room:setPlayerCardLimitation(q, "use", ".|heart", false, "ofgu_qianqian")
            end
        end
    end
end)
of_wencaopi:addSkill(ofgu_yishi); of_wencaopi:addSkill(ofgu_yishi_init); of_wencaopi:addSkill(ofgu_nianjun)
of_wencaopi:addSkill(ofgu_nianjun_record); of_wencaopi:addSkill(ofgu_nianjun_mod); of_wencaopi:addSkill(ofgu_qianqian)

-- The old commented shendiaochan stub is not a live same-version registration.
of_shendiaochan = sgs.General(extension, "of_shendiaochan", "god", 3, false)
ofgu_meihun = gu_trigger("ofgu_meihun", {sgs.EventPhaseStart, sgs.TargetConfirmed}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.EventPhaseStart then
        if p:getPhase() ~= sgs.Player_Finish then return end
    else
        local use = data:toCardUse()
        if not use.card:isKindOf("Slash") or not use.to:contains(owner) then return end
    end
    local to = room:askForPlayerChosen(owner, room:getOtherPlayers(owner), self:objectName(), "@ofgu_meihun", true, true)
    if not to then return end
    local suit = room:askForChoice(owner, self:objectName(), "spade+heart+club+diamond", ToData(to))
    local has = false
    for _, c in sgs.qlist(to:getCards("he")) do if c:getSuitString() == suit then has = true end end
    if has then
        local c = room:askForCard(to, ".|" .. suit, "@ofgu_meihun-give:" .. owner:objectName(), ToData(owner), sgs.Card_MethodNone, owner, false, self:objectName())
        if not c then
            for _, card in sgs.qlist(to:getCards("he")) do if card:getSuitString() == suit then c = card; break end end
        end
        if c then room:giveCard(to, owner, c, self:objectName()) end
    elseif not to:isKongcheng() then
        room:showAllCards(to, owner)
        room:throwCard(room:askForCardChosen(owner, to, "h", self:objectName()), to, owner)
    end
end)
ofgu_huoxin = gu_active("ofgu_huoxin", 1, 2, 2,
    function(self, targets, to, from) return #targets < 2 and to ~= from end,
    function(self, targets) return #targets == 2 end,
    function(self, room, source, targets)
        local ids = self:getSubcards()
        room:showCard(source, ids:first()); room:showCard(source, ids:last())
        room:giveCard(source, targets[1], sgs.Sanguosha:getCard(ids:first()), "ofgu_huoxin")
        room:giveCard(source, targets[2], sgs.Sanguosha:getCard(ids:last()), "ofgu_huoxin")
        if targets[1]:isAlive() and targets[2]:isAlive() and not targets[1]:isKongcheng() and not targets[2]:isKongcheng() then
            local pd = targets[1]:PinDian(targets[2], "ofgu_huoxin")
            if pd.from_number <= pd.to_number then room:addPlayerMark(targets[1], "@ofgu_meihuo") end
            if pd.to_number <= pd.from_number then room:addPlayerMark(targets[2], "@ofgu_meihuo") end
        end
    end,
    function(request, c)
        local ids = request:getSelectedCardIds()
        return not c:isEquipped() and (ids:isEmpty() or sgs.Sanguosha:getCard(ids:first()):getSuit() == c:getSuit())
    end)
ofgu_huoxin_control = gu_trigger("#ofgu_huoxin_control", {sgs.TurnStart}, function(self, event, room, p, data, owner)
    if p:getMark("@ofgu_meihuo") < 2 then return end
    room:setPlayerMark(p, "@ofgu_meihuo", 0); room:setPlayerController(p, owner)
    p:setTag("ofgu_huoxin_controller", ToData(owner))
end, true)
extension:addSkills(gu_record("#ofgu_huoxin_clear", {sgs.EventPhaseChanging, sgs.Death}, function(self, event, room, p, data)
    if event == sgs.EventPhaseChanging and data:toPhaseChange().to ~= sgs.Player_NotActive then return end
    if p:getTag("ofgu_huoxin_controller"):toPlayer() then
        room:setPlayerController(p, nil); p:removeTag("ofgu_huoxin_controller")
    end
end))
of_shendiaochan:addSkill(ofgu_meihun); of_shendiaochan:addSkill(ofgu_huoxin); of_shendiaochan:addSkill(ofgu_huoxin_control)

ofjie_sunce = sgs.General(extension, "ofjie_sunce$", "wu", 4)
ofgu_jiang = gu_trigger("ofgu_jiang", {sgs.TargetSpecified}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if not (use.card:isKindOf("Duel") or use.card:isKindOf("Slash") and use.card:isRed()) then return end
    if gu_invoke(owner, self:objectName(), data) then
        owner:drawCards(1, self:objectName()); if use.from:isAlive() then use.from:drawCards(1, self:objectName()) end
    end
end)
ofgu_jiang_filter = sgs.CreateFilterSkill {
    name = "#ofgu_jiang_filter",
    view_filter = function(self, c) return c:getNumber() == 13 end,
    view_as = function(self, c)
        local slash = sgs.Sanguosha:cloneCard("slash", c:getSuit(), c:getNumber()); slash:setSkillName("ofgu_jiang")
        local wrapped = sgs.Sanguosha:getWrappedCard(c:getId()); wrapped:takeOver(slash); slash:deleteLater(); return wrapped
    end,
}
ofgu_hunzi = sgs.CreateTriggerSkillV2 {
    name = "ofgu_hunzi", frequency = sgs.Skill_Wake, events = {sgs.HpChanged},
    can_trigger = function(self, event, room, p, data)
        return p and p:isAlive() and p:hasSkill(self:objectName()) and p:getHp() == 1 and p:getMark(self:objectName()) == 0 and self:objectName() or false
    end,
    on_effect = function(self, event, room, p, ctx)
        room:setPlayerMark(p, self:objectName(), 1); room:gainMaxHp(p, 1, self:objectName())
        room:handleAcquireDetachSkills(p, "yingzi|yinghun")
    end,
}
ofgu_zhiba = gu_trigger("ofgu_zhiba$", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if not owner:hasLordSkill("ofgu_zhiba") or p == owner or p:getKingdom() ~= "wu" or p:getPhase() ~= sgs.Player_Start or p:isKongcheng() then return end
    local candidates = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getOtherPlayers(p)) do if not q:isKongcheng() then candidates:append(q) end end
    if candidates:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, candidates, "ofgu_zhiba", "@ofgu_zhiba:" .. p:objectName(), true, true)
    if to and p:pindian(to, "ofgu_zhiba") and p:isAlive() and to:isAlive() then
        local c = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0); c:setSkillName("ofgu_zhiba")
        if not p:isProhibited(to, c) then room:useCard(sgs.CardUseStruct(c, p, to), false) end
        c:deleteLater()
    end
end)
ofjie_sunce:addSkill(ofgu_jiang); ofjie_sunce:addSkill(ofgu_jiang_filter); ofjie_sunce:addSkill(ofgu_hunzi); ofjie_sunce:addSkill(ofgu_zhiba)

ofjie_caiwenji = sgs.General(extension, "ofjie_caiwenji", "qun", 3, false)
ofgu_duanchang = sgs.CreateTriggerSkillV2 {
    name = "ofgu_duanchang", frequency = sgs.Skill_Compulsory, events = {sgs.Death},
    can_trigger = function(self, event, room, p, data)
        return p and p:hasSkill(self:objectName()) and data:toDeath().who == p and self:objectName() or false
    end,
    on_effect = function(self, event, room, p, ctx)
        local death = ctx.original_data:toDeath()
        if not death.damage or not death.damage.from or not death.damage.from:isAlive() then return end
        local killer = death.damage.from
        if room:askForChoice(p, self:objectName(), "skills+cards", ToData(killer)) == "cards" then killer:throwAllCards(self:objectName())
        else
            local names = {}
            for _, skill in sgs.qlist(killer:getVisibleSkillList()) do table.insert(names, "-" .. skill:objectName()) end
            room:handleAcquireDetachSkills(killer, table.concat(names, "|"))
        end
    end,
}
ofgu_beige = gu_trigger("ofgu_beige", {sgs.Damaged}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if not d.card or not d.card:isKindOf("Slash") or owner:isNude() then return end
    local c = room:askForCard(owner, "..", "@ofgu_beige", data, sgs.Card_MethodDiscard, p, false, self:objectName())
    if not c then return end
    local judge = sgs.JudgeStruct(); judge.who = d.to; judge.reason = self:objectName(); judge.pattern = "."; judge.good = true
    room:judge(judge)
    local suit = judge.card:getSuitString()
    room:setPlayerMark(owner, "ofgu_beige_" .. suit, 1)
    local complete = true
    for _, s in ipairs({"spade", "heart", "club", "diamond"}) do if owner:getMark("ofgu_beige_" .. s) == 0 then complete = false end end
    if complete and not owner:hasSkill("ofgu_quzhong") then room:acquireSkill(owner, "ofgu_quzhong") end
    local to, from = d.to, d.from
    if d.card:getSkillName() == "ofgu_quzhong" and d.from == owner then to, from = from, to end
    if suit == "heart" and to and to:isAlive() then room:recover(to, sgs.RecoverStruct(self:objectName(), owner, d.damage))
    elseif suit == "diamond" and to and to:isAlive() then to:drawCards(3, self:objectName())
    elseif suit == "club" and from and from:isAlive() then room:askForDiscard(from, self:objectName(), 2, 2, false, true)
    elseif suit == "spade" and from and from:isAlive() then from:turnOver() end
end)
ofgu_quzhong_record = gu_record("#ofgu_quzhong_record", {sgs.CardsMoveOneTime}, function(self, event, room, p, data)
    local move = data:toMoveOneTime()
    if move.to_place ~= sgs.Player_DiscardPile or bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_DISCARD or not move.from then return end
    local from = room:findPlayerByObjectName(move.from:objectName())
    if not from then return end
    local ids = from:getTag("ofgu_quzhong_discard"):toIntList()
    for _, id in sgs.qlist(move.card_ids) do if not ids:contains(id) then ids:append(id) end end
    from:setTag("ofgu_quzhong_discard", ToData(ids))
end)
ofgu_quzhongvs = sgs.CreateViewAsSkillV2 {
    name = "ofgu_quzhong", expand_pile = "#ofgu_quzhong_available",
    can_activate = function(self, request) return request:getPattern() == "@@ofgu_quzhong" end,
    can_select_card = function(self, request, card)
        return request:getSelectedCardIds():isEmpty() and request:getInitiator():getTag("ofgu_quzhong_discard"):toIntList():contains(card:getEffectiveId())
            and request:getInitiator():getRoom():getCardPlace(card:getEffectiveId()) == sgs.Player_DiscardPile
    end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():length() == 1 end,
    create_card = function(self, request)
        local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        c:addSubcards(request:getSelectedCardIds()); c:setSkillName("ofgu_quzhong"); return c
    end,
}
ofgu_quzhong = gu_trigger("ofgu_quzhong", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p:getPhase() ~= sgs.Player_Finish then return end
    local ids = sgs.IntList()
    for _, id in sgs.qlist(owner:getTag("ofgu_quzhong_discard"):toIntList()) do if room:getCardPlace(id) == sgs.Player_DiscardPile then ids:append(id) end end
    if ids:isEmpty() then return end
    room:notifyMoveToPile(owner, ids, "ofgu_quzhong_available", sgs.Player_DiscardPile, true)
    room:askForUseCard(owner, "@@ofgu_quzhong", "@ofgu_quzhong", -1, sgs.Card_MethodUse, false)
    room:notifyMoveToPile(owner, ids, "ofgu_quzhong_available", sgs.Player_DiscardPile, false)
end)
ofgu_quzhong:setViewAsSkill(ofgu_quzhongvs)
extension:addSkills(ofgu_quzhong); extension:addSkills(ofgu_quzhong_record)
extension:addSkills(gu_record("#ofgu_quzhong_clear", {sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if data:toPhaseChange().to == sgs.Player_NotActive then
        for _, q in sgs.qlist(room:getAllPlayers()) do q:removeTag("ofgu_quzhong_discard") end
    end
end))
ofjie_caiwenji:addSkill(ofgu_duanchang); ofjie_caiwenji:addSkill(ofgu_beige)

of_shenzhangjiao = sgs.General(extension, "of_shenzhangjiao", "god", 4, true)
local function gu_lightning(room, target, source, skill)
    local judge = sgs.JudgeStruct(); judge.who = target; judge.reason = skill
    judge.pattern = ".|spade|2~9"; judge.good = false; judge.negative = true
    room:judge(judge)
    if judge:isBad() and target:isAlive() then room:damage(sgs.DamageStruct(skill, source, target, 3, sgs.DamageStruct_Thunder)) end
end
ofgu_yuanlin = gu_trigger("ofgu_yuanlin", {sgs.RoundStart, sgs.EventPhaseStart, sgs.Damaged}, function(self, event, room, p, data, owner)
    if event == sgs.RoundStart then
        if p ~= owner then return end
        for _, to in sgs.qlist(room:getOtherPlayers(owner)) do if to:isAlive() then gu_lightning(room, to, owner, self:objectName()) end end
    elseif event == sgs.EventPhaseStart then
        if p ~= owner and p:getPhase() == sgs.Player_Judge then gu_lightning(room, p, owner, self:objectName()) end
    elseif data:toDamage().nature == sgs.DamageStruct_Thunder then
        local choices = owner:isWounded() and "draw+recover" or "draw"
        if room:askForChoice(owner, self:objectName(), choices, data) == "recover" then room:recover(owner, sgs.RecoverStruct(self:objectName(), owner))
        else owner:drawCards(1, self:objectName()) end
    end
end, true)
-- SOURCE-C append: 2015 雷擊, matching wind.cpp TenyearLeiji's suit branches.
ofgu_kuanglei = gu_trigger("ofgu_kuanglei", {sgs.TargetConfirming}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if p ~= owner or not use.from or use.from == owner or not use.from:isAlive()
        or not use.to:contains(owner) or not use.card or not use.card:isDamageCard() then return end
    local gift = room:askForCard(use.from, "..", "@ofgu_kuanglei:" .. owner:objectName(), data, sgs.Card_MethodNone)
    if gift then room:giveCard(use.from, owner, gift, self:objectName()); return end
    local judge = sgs.JudgeStruct()
    judge.who = use.from; judge.reason = self:objectName(); judge.pattern = ".|black"; judge.good = false
    room:judge(judge)
    local suit = judge.card:getSuit()
    if suit ~= sgs.Card_Spade and suit ~= sgs.Card_Club then return end
    if suit == sgs.Card_Club and owner:isAlive() then room:recover(owner, sgs.RecoverStruct(self:objectName(), owner)) end
    if use.from:isAlive() then room:damage(sgs.DamageStruct(self:objectName(), owner, use.from,
        suit == sgs.Card_Spade and 2 or 1, sgs.DamageStruct_Thunder)) end
end, true)
ofgu_qiongshan = gu_trigger("ofgu_qiongshan", {sgs.FinishRetrial}, function(self, event, room, p, data, owner)
    if p == owner or owner:getMark("ofgu_qiongshan_used") > 0 or not gu_invoke(owner, self:objectName(), data) then return end
    room:setPlayerMark(owner, "ofgu_qiongshan_used", 1)
    local judge = data:toJudge()
    local name = judge.card:objectName()
    room:obtainCard(owner, judge.card, self:objectName(), true)
    room:setTag("ofgu_qiongshan_judge", data)
    local suit = room:askForSuit(owner, self:objectName())
    room:removeTag("ofgu_qiongshan_judge")
    local numbers = {}; for n = 1, 13 do table.insert(numbers, tostring(n)) end
    local number = tonumber(room:askForChoice(owner, self:objectName(), table.concat(numbers, "+"), data))
    local snapshot = sgs.Sanguosha:cloneCard(name, suit, number)
    room:retainJudgeSnapshot(snapshot); judge.card = snapshot; judge:updateResult(); data:setValue(judge)
end)
extension:addSkills(gu_record("#ofgu_qiongshan_round", {sgs.RoundStart}, function(self, event, room, p, data)
    local round = data:toInt()
    if room:getTag("ofgu_qiongshan_round_reset"):toInt() == round then return end
    room:setTag("ofgu_qiongshan_round_reset", sgs.QVariant(round))
    for _, q in sgs.qlist(room:getAlivePlayers()) do room:setPlayerMark(q, "ofgu_qiongshan_used", 0) end
end))
of_shenzhangjiao:addSkill(ofgu_kuanglei); of_shenzhangjiao:addSkill(ofgu_yuanlin); of_shenzhangjiao:addSkill(ofgu_qiongshan)

of_guanyinping = sgs.General(extension, "of_guanyinping", "shu", 4, false)
ofgu_saxue = gu_trigger("ofgu_saxue", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Start or not gu_invoke(owner, self:objectName(), data) then return end
    local chained = room:askForPlayersChosen(owner, room:getAlivePlayers(), self:objectName(), 2, 2, "@ofgu_saxue-chain", true, true)
    if chained:length() ~= 2 then return end
    for _, q in sgs.qlist(chained) do room:setPlayerChained(q, true, owner) end
    local from = room:askForPlayerChosen(owner, room:getOtherPlayers(owner), self:objectName(), "@ofgu_saxue-source", false, true)
    if not from then return end
    -- The chosen other character allocates both points before either resolves.
    local n = tonumber(room:askForChoice(from, self:objectName(), "0+1+2", ToData(owner)))
    if n > 0 and owner:isAlive() then room:damage(sgs.DamageStruct(self:objectName(), from, owner, n, sgs.DamageStruct_Fire)) end
    if n < 2 and from:isAlive() then room:damage(sgs.DamageStruct(self:objectName(), from, from, 2-n, sgs.DamageStruct_Fire)) end
end)
-- Record suits before discards resolve, including discards by other characters.
ofgu_xianfeng_record = gu_record("#ofgu_xianfeng_record", {sgs.CardsMoveOneTime, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to == sgs.Player_NotActive then
            for _, q in sgs.qlist(room:getAllPlayers()) do q:removeTag("ofgu_xianfeng_first") end
        end
        return
    end
    local move = data:toMoveOneTime()
    if move.to_place ~= sgs.Player_DiscardPile then return end
    for _, id in sgs.qlist(move.card_ids) do
        local suit = sgs.Sanguosha:getCard(id):getSuitString()
        if not room:getTag("ofgu_discard_suit_" .. suit):toBool() then
            room:setTag("ofgu_discard_suit_" .. suit, sgs.QVariant(true))
            for _, q in sgs.qlist(room:getAlivePlayers()) do
                if q:getTag("ofgu_xianfeng_chosen"):toInt() == id + 1 then q:setTag("ofgu_xianfeng_first", sgs.QVariant(id + 1)) end
            end
        end
    end
end)
ofgu_xianfeng = gu_trigger("ofgu_xianfeng", {sgs.Damaged}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if p ~= owner or not d.from or d.from:isNude() then return end
    for n = 1, d.damage do
        if owner:isDead() or d.from:isNude() or not gu_invoke(owner, self:objectName(), data) then break end
        local id = room:askForCardChosen(owner, d.from, "he", self:objectName())
        owner:setTag("ofgu_xianfeng_chosen", sgs.QVariant(id + 1)); owner:removeTag("ofgu_xianfeng_first")
        room:throwCard(id, d.from, owner)
        if owner:getTag("ofgu_xianfeng_first"):toInt() == id + 1 and room:getCardPlace(id) == sgs.Player_DiscardPile then room:obtainCard(owner, id, self:objectName(), true) end
        owner:removeTag("ofgu_xianfeng_chosen"); owner:removeTag("ofgu_xianfeng_first")
    end
end)
extension:addSkills(ofgu_xianfeng_record)
extension:addSkills(gu_record("#ofgu_discard_suits_clear", {sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if data:toPhaseChange().to == sgs.Player_NotActive then
        for _, suit in ipairs({"spade", "heart", "club", "diamond", "no_suit"}) do room:removeTag("ofgu_discard_suit_" .. suit) end
    end
end))
of_guanyinping:addSkill(ofgu_saxue); of_guanyinping:addSkill(ofgu_xianfeng)

-- 夢貂蟬 and the four derived skills have their own names to avoid changing
-- existing versions with the same displayed names.
of_mengdiaochan = sgs.General(extension, "of_mengdiaochan", "shu", 3, false)
ofgu_benghuai = gu_trigger("ofgu_benghuai", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Finish then return end
    local lowest = true
    for _, q in sgs.qlist(room:getOtherPlayers(owner)) do if q:getHp() < owner:getHp() then lowest = false end end
    if lowest then return end
    if room:askForChoice(owner, self:objectName(), "hp+maxhp") == "hp" then room:loseHp(owner, 1, true, nil, self:objectName())
    else room:loseMaxHp(owner, 1, self:objectName()) end
end, true)
ofgu_tongji = sgs.CreateProhibitSkillV2 {
    name = "ofgu_tongji",
    holder_selector = sgs.CorrectSkill_AllHolders,
    is_prohibited = function(self, ctx)
        local holder, to, card = ctx:getHolder(), ctx:getTo(), ctx:getCard()
        return card:isKindOf("Slash") and holder:getHandcardNum() > holder:getHp() and holder ~= to
    end,
}
ofgu_bihun = gu_trigger("ofgu_bihun", {sgs.TargetSpecified}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from ~= owner or owner:getHandcardNum() <= owner:getMaxHp() then return end
    local tos = sgs.SPlayerList()
    for _, q in sgs.qlist(use.to) do if q ~= owner then tos:append(q) end end
    if tos:isEmpty() then return end
    local single = use.to:length() == 1
    local nullified = use.nullified_list
    for _, q in sgs.qlist(tos) do table.insert(nullified, q:objectName()) end
    use.nullified_list = nullified
    data:setValue(use)
    if single then room:obtainCard(tos:first(), use.card, self:objectName(), true) end
end, true)
ofgu_yiju = gu_trigger("ofgu_yiju", {sgs.TargetConfirmed}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if p == owner and use.from ~= owner and use.to:length() == 1 and use.to:contains(owner) then
        room:askForDiscard(owner, self:objectName(), 1, 1, false, true)
    end
end, true)
extension:addSkills(ofgu_benghuai); extension:addSkills(ofgu_tongji); extension:addSkills(ofgu_bihun); extension:addSkills(ofgu_yiju)
ofgu_diyu = gu_trigger("ofgu_diyu", {sgs.RoundStart, sgs.DamageCaused}, function(self, event, room, p, data, owner)
    local key = "ofgu_diyu_" .. owner:objectName()
    if event == sgs.DamageCaused then
        local d = data:toDamage()
        if d.from and d.from:getMark(key) > 0 then d.damage = d.damage + 1; data:setValue(d) end
        return
    end
    for _, q in sgs.qlist(room:getAllPlayers()) do room:setPlayerMark(q, key, 0) end
    local used = gu_names(owner, "ofgu_diyu_used")
    local choices = {}
    for _, name in ipairs({"ofgu_benghuai", "ofgu_tongji", "ofgu_bihun", "ofgu_yiju"}) do
        if not table.contains(used, name) then table.insert(choices, name) end
    end
    if #choices == 0 then return end
    local to = room:askForPlayerChosen(owner, room:getAlivePlayers(), self:objectName(), "@ofgu_diyu", true, true)
    if not to then return end
    room:setPlayerMark(to, key, 1)
    local name = room:askForChoice(owner, self:objectName(), table.concat(choices, "+"), ToData(to))
    table.insert(used, name); gu_setnames(owner, "ofgu_diyu_used", used); room:acquireSkill(to, name)
end)
ofgu_fuyi = gu_trigger("ofgu_fuyi", {sgs.TargetConfirming, sgs.SlashMissed}, function(self, event, room, p, data, owner)
    if event == sgs.SlashMissed then
        local effect = data:toSlashEffect()
        if effect.slash:hasFlag("ofgu_fuyi") then room:setCardFlag(effect.slash, "ofgu_fuyi_cancel") end
        return
    end
    local use = data:toCardUse()
    if p ~= owner or not use.card:isKindOf("Slash") or not use.to:contains(owner) then return end
    local candidates = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if not use.to:contains(q) and not use.from:isProhibited(q, use.card) then candidates:append(q) end
    end
    if candidates:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, candidates, self:objectName(), "@ofgu_fuyi", true, true)
    if not to then return end
    use.to:append(to); room:sortByActionOrder(use.to); room:setCardFlag(use.card, "ofgu_fuyi"); data:setValue(use)
    for _, q in sgs.qlist(use.to) do q:drawCards(1, self:objectName()) end
end)
-- Cancellation needs an effect callback, not an observational recorder.
ofgu_fuyi_cancel = sgs.CreateRuleSkillV2 {
    name = "#ofgu_fuyi_effect", global = true, events = {sgs.CardEffected},
    can_trigger = function(self, event, room, p, data) return data:toCardEffect().card:hasFlag("ofgu_fuyi_cancel") and self:objectName() or false, p end,
    on_effect = function() return true end,
}
extension:addSkills(ofgu_fuyi_cancel)
local function gu_swap_skills(room, a, b)
    local as, bs = {}, {}
    for _, skill in sgs.qlist(a:getVisibleSkillList()) do if not skill:isEquipSkill() then table.insert(as, skill:objectName()) end end
    for _, skill in sgs.qlist(b:getVisibleSkillList()) do if not skill:isEquipSkill() then table.insert(bs, skill:objectName()) end end
    local da, db = {}, {}
    for _, n in ipairs(as) do table.insert(da, "-" .. n) end
    for _, n in ipairs(bs) do table.insert(db, "-" .. n) end
    for _, n in ipairs(bs) do table.insert(da, n) end
    for _, n in ipairs(as) do table.insert(db, n) end
    room:handleAcquireDetachSkills(a, table.concat(da, "|")); room:handleAcquireDetachSkills(b, table.concat(db, "|"))
    return as, bs
end
ofgu_jiuji = gu_trigger("ofgu_jiuji", {sgs.RoundEnd}, function(self, event, room, p, data, owner)
    if not gu_invoke(owner, self:objectName(), data) then return end
    local tos = room:askForPlayersChosen(owner, room:getAlivePlayers(), self:objectName(), 2, 2, "@ofgu_jiuji", true, true)
    if tos:length() ~= 2 then return end
    local a, b = tos:first(), tos:last()
    -- Each immediate extra turn swaps then restores, in the chosen order.
    a:setTag("ofgu_jiuji_partner", ToData(b)); b:setTag("ofgu_jiuji_partner", ToData(a))
    a:gainAnExtraTurn(); if b:isAlive() then b:gainAnExtraTurn() end
end)
ofgu_jiuji_record = gu_record("#ofgu_jiuji_record", {sgs.TurnStart, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.TurnStart then
        local partner = p:getTag("ofgu_jiuji_partner"):toPlayer()
        if not partner then return end
        p:removeTag("ofgu_jiuji_partner")
        local as, bs = gu_swap_skills(room, p, partner)
        gu_setnames(p, "ofgu_jiuji_original", as); gu_setnames(partner, "ofgu_jiuji_original", bs)
        p:setTag("ofgu_jiuji_active", ToData(partner))
    elseif data:toPhaseChange().to == sgs.Player_NotActive then
        local partner = p:getTag("ofgu_jiuji_active"):toPlayer()
        if not partner then return end
        for _, q in ipairs({p, partner}) do
            local changes = {}
            for _, skill in sgs.qlist(q:getVisibleSkillList()) do if not skill:isEquipSkill() then table.insert(changes, "-" .. skill:objectName()) end end
            for _, name in ipairs(gu_names(q, "ofgu_jiuji_original")) do table.insert(changes, name) end
            room:handleAcquireDetachSkills(q, table.concat(changes, "|")); q:removeTag("ofgu_jiuji_original")
        end
        p:removeTag("ofgu_jiuji_active")
    end
end)
ofgu_jiuji_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#ofgu_jiuji_prohibit",
    holder_selector = sgs.CorrectSkill_System,
    is_prohibited = function(self, ctx)
        local from, to = ctx:getFrom(), ctx:getTo()
        local partner = from:getTag("ofgu_jiuji_active"):toPlayer()
        return partner ~= nil and partner ~= to
    end,
}
extension:addSkills(ofgu_jiuji_record); extension:addSkills(ofgu_jiuji_prohibit)
of_mengdiaochan:addSkill(ofgu_diyu); of_mengdiaochan:addSkill(ofgu_fuyi); of_mengdiaochan:addSkill(ofgu_jiuji)

of_luoguanzhong = sgs.General(extension, "of_luoguanzhong", "qun", 4, true)
local function gu_zhuhun(room, owner)
    local used, pool = {}, {}
    for _, p in sgs.qlist(room:getAllPlayers()) do used[p:getGeneralName()] = true; used[p:getGeneral2Name()] = true end
    for _, name in ipairs(sgs.Sanguosha:getLimitedGeneralNames()) do if not used[name] then table.insert(pool, name) end end
    local names = {}
    while #names < 4 and #pool > 0 do table.insert(names, table.remove(pool, math.random(#pool))) end
    if #names == 0 then return end
    local log = sgs.LogMessage(); log.type = "#ofgu_zhuhun_reveal"; log.from = owner; log.arg = table.concat(names, "+"); room:sendLog(log)
    -- Acknowledgement happens before hidden shuffle, preserving the public reveal.
    room:askForChoice(owner, "ofgu_zhuhun", "confirm")
    for i = #names, 2, -1 do local j = math.random(i); names[i], names[j] = names[j], names[i] end
    owner:drawCards(#names, "ofgu_zhuhun")
    local ids = owner:handCards()
    local souls = {}
    for _, name in ipairs(names) do
        if ids:isEmpty() then break end
        room:fillAG(ids, owner)
        local id = room:askForAG(owner, ids, false, "ofgu_zhuhun"); room:clearAG(owner)
        ids:removeOne(id); owner:addToPile("ofgu_hun", id, true)
        table.insert(souls, tostring(id) .. ":" .. name)
    end
    gu_setnames(owner, "ofgu_zhuhun_hidden", souls)
    -- Only the owner receives the shuffled general identities.
    local json = require("json")
    room:doNotify(owner, sgs.CommandType.S_COMMAND_VIEW_GENERALS, json.encode({"ofgu_zhuhun", names}))
end
ofgu_zhuhun = gu_trigger("ofgu_zhuhun", {sgs.GameStart}, function(self, event, room, p, data, owner) gu_zhuhun(room, owner) end, true)
ofgu_jingshi = gu_trigger("ofgu_jingshi", {sgs.TurnStart}, function(self, event, room, p, data, owner)
    if p == owner or owner:getPile("ofgu_hun"):isEmpty() or not gu_invoke(p, self:objectName(), ToData(owner)) then return end
    local hidden = gu_names(owner, "ofgu_zhuhun_hidden")
    local ids = sgs.IntList()
    for _, entry in ipairs(hidden) do ids:append(tonumber(entry:split(":")[1])) end
    room:fillAG(ids, p); local id = room:askForAG(p, ids, false, self:objectName()); room:clearAG(p)
    local guess = room:askForGeneral(p, table.concat(sgs.Sanguosha:getLimitedGeneralNames(), "+"), "", self:objectName())
    local actual = ""
    for i, entry in ipairs(hidden) do
        local pair = entry:split(":")
        if tonumber(pair[1]) == id then actual = pair[2]; table.remove(hidden, i); break end
    end
    gu_setnames(owner, "ofgu_zhuhun_hidden", hidden)
    local log = sgs.LogMessage(); log.type = "#ofgu_jingshi_reveal"; log.from = p; log.arg = actual; log.arg2 = guess; room:sendLog(log)
    if guess == actual then
        owner:drawCards(2, self:objectName())
        if owner:getHandcardNum() >= 2 then
            local c = room:askForExchange(owner, self:objectName(), 2, 2, false, "@ofgu_jingshi-give:" .. p:objectName(), true)
            if c then room:giveCard(owner, p, c, self:objectName()) end
        end
    end
    if #hidden == 0 then
        gu_throw(room, owner, owner:getPile("ofgu_hun"), self:objectName()); gu_zhuhun(room, owner)
    end
end)
of_luoguanzhong:addSkill(ofgu_zhuhun); of_luoguanzhong:addSkill(ofgu_jingshi)

sgs.LoadTranslationTable {
    ["ofjie_dianwei"] = "界典韋[線下]",
    ["#ofjie_dianwei"] = "戟貫數人",
    ["ofgu_qiangxi"] = "強襲",
    [":ofgu_qiangxi"] = "出牌階段，你可以與一名本回合未選擇過的角色拼點：若你贏，你摸一張牌或棄置對方一張牌；本回合第二次沒贏時，你失去1點體力對這兩次拼點目標及其之間的所有其他角色各造成1點傷害，然後此技能本回合失效。",
    ["of_wencaozhi"] = "文曹植[線下]",
    ["#of_wencaozhi"] = "白馬飾金羈",
    ["ofgu_huamao"] = "華茂",
    [":ofgu_huamao"] = "首轮开始时，你随机获得三个描述中仅含一种花色且花色各不相同的技能直到洗牌，然后你可以重新分配这些技能描述中的花色。<br/>對應以公開花色／技能標記顯示；四種花色皆可，已占用者交換。各技能原生花色判定不變。",
    ["ofgu_huamao_reassign"] = "華茂：重新分配花色對應",
    [":ofgu_huamao_reassign"] = "依次為每個已獲得技能選擇對應花色（四種花色皆可）；若已被其他技能占用，交換兩技的對應。公開標記顯示各技對應，洗牌時清除；各技能原生花色判定不變。",
    ["ofgu_qishen"] = "棄身",
    [":ofgu_qishen"] = "回合结束时，你可以选择至多三名角色，直到你下回合结束：这些角色其他技能失效且造成的伤害+1，然后其中上回合也选择过的角色各摸三张牌。",
    ["of_xiaokongrong"] = "小孔融[線下]",
    ["#of_xiaokongrong"] = "年少懷德",
    ["ofgu_cirang"] = "辭讓",
    [":ofgu_cirang"] = "每回合限一次，當你獲得至少兩張牌後，你可以展示這些牌並交給任意名角色，若你未保留點數最大的牌，則你摸一張牌。",
    ["ofgu_liaoliao"] = "了了",
    [":ofgu_liaoliao"] = "其他角色的回合開始時，你可以棄置一張牌，本回合你不能成為點數大於此牌的牌的目標。",
    ["ofjie_xuhuang"] = "界徐晃[線下]",
    ["#ofjie_xuhuang"] = "公明大義",
    ["ofgu_duanliang"] = "斷糧",
    [":ofgu_duanliang"] = "你可以將一張黑色非錦囊牌當無距離限制的【兵糧寸斷】使用，然後若目標角色手牌數大於你，你摸一張牌。",
    ["ofgu_zier"] = "輜餌",
    [":ofgu_zier"] = "一名角色跳過一個階段後，你可以記錄此階段。每輪限一次，一名角色回合開始時，你可以將其本回合的一個階段改為你本輪記錄的階段。",
    ["ofjie_zhurong"] = "界祝融[線下]",
    ["#ofjie_zhurong"] = "刺美人",
    ["ofgu_lieren"] = "烈刃",
    [":ofgu_lieren"] = "當你每回合首次使用【殺】指定唯一目標後，你可以與其拼點，贏的角色於此【殺】結算後將所有手牌當【南蠻入侵】使用。",
    ["ofgu_juxiang"] = "巨象",
    [":ofgu_juxiang"] = "當一名角色使用【南蠻入侵】時，若使用者不為你，此牌對你無效且你於結算後獲得之；否則你可以令此牌對體力值大於你的角色造成的傷害+1。",
    ["of_zhangxingcai"] = "張星彩[線下]",
    ["#of_zhangxingcai"] = "蘭芷鋒鏑",
    ["ofgu_hengren"] = "橫刃",
    [":ofgu_hengren"] = "轉換技，其他角色的出牌階段①開始時②結束時，若其本階段有【殺】的剩餘使用次數，你可以使用一張【殺】（將計入其使用次數且傷害+1）。",
    ["ofgu_danjue"] = "膽決",
    [":ofgu_danjue"] = "當與你距離1以內的角色成為【殺】的目標後，你可以令此【殺】不計入次數，然後其摸一張牌並可以交給你一張牌。",
    ["of_wencaopi"] = "文曹丕[線下]",
    ["#of_wencaopi"] = "秋風蕭瑟",
    ["ofgu_yishi"] = "遺世",
    [":ofgu_yishi"] = "限定技，出牌階段，你可以對所有其他角色發動「放逐」，然後這些角色獲得僅能對你發動的「放逐」。",
    ["ofgu_nianjun"] = "念君",
    [":ofgu_nianjun"] = "結束階段，你可以連接你與任意名其他角色各一張手牌。有連接牌的角色互相使用牌無次數限制。每回合首名失去連接牌的角色失去1點體力。",
    ["ofgu_qianqian"] = "慊慊",
    [":ofgu_qianqian"] = "鎖定技，你每回合使用的首張牌不能為♥。",
    ["ofgu_fangzhu"] = "放逐",
    [":ofgu_fangzhu"] = "當你受到傷害後，你可以令一名其他角色翻面並摸X張牌（X為你已損失的體力值）。",
    ["of_shendiaochan"] = "神貂蟬[線下]",
    ["#of_shendiaochan"] = "欲界非天",
    ["ofgu_meihun"] = "魅魂",
    [":ofgu_meihun"] = "結束階段或當你成為【殺】的目標後，你可以令一名其他角色交給你一張你聲明的花色的牌，若其沒有，你觀看其手牌，然後棄置其中一張。",
    ["ofgu_huoxin"] = "惑心",
    [":ofgu_huoxin"] = "出牌階段限一次，你可以展示兩張花色相同的手牌並分別交給兩名其他角色，然後令這兩名角色拼點，沒贏的角色獲得1枚「魅惑」。擁有至少2枚「魅惑」的角色回合即將開始時，其棄其所有「魅惑」，此回合改為由你操控。",
    ["ofjie_sunce"] = "界孫策[線下]",
    ["#ofjie_sunce"] = "翻江倒海",
    ["ofgu_jiang"] = "激昂",
    [":ofgu_jiang"] = "一名角色使用【決鬥】或紅色【殺】指定目標後，你可以與其各摸一張牌。你的K點牌均視為【殺】。",
    ["ofgu_hunzi"] = "魂姿",
    [":ofgu_hunzi"] = "覺醒技，當你的體力值變為1時，你加1點體力上限並獲得「英姿」和「英魂」（英魂 X為你已損失的體力值）。",
    ["ofgu_zhiba"] = "制霸",
    [":ofgu_zhiba"] = "主公技，吳勢力角色的準備階段，你可以令其與另一名角色拼點：若其贏，其視為使用一張【決鬥】。",
    ["ofjie_caiwenji"] = "界蔡文姬[線下]",
    ["#ofjie_caiwenji"] = "別子歸漢",
    ["ofgu_duanchang"] = "斷腸",
    [":ofgu_duanchang"] = "鎖定技，當你死亡時，你選擇一項令殺死你的角色執行：1.失去所有技能；2.棄置所有牌。",
    ["ofgu_beige"] = "悲歌",
    [":ofgu_beige"] = "當一名角色受到【殺】造成的傷害後，你可以棄置一張牌，然後令其判定並記錄花色（記錄了所有花色後，你獲得「曲終」），若結果為：♥，其回復X點體力（X為此傷害值）；♦，其摸三張牌；♣，傷害來源棄置兩張牌；♠，傷害來源翻面。",
    ["ofgu_quzhong"] = "曲終",
    [":ofgu_quzhong"] = "當一名角色的結束階段，你可以將你本回合棄置的一張牌當【殺】使用；當你在此【殺】結算中發動「悲歌」時，交換選項中的「其」與「傷害來源」。",
    ["of_shenzhangjiao"] = "神張角[線下]",
    ["#of_shenzhangjiao"] = "神臨天劫",
    ["ofgu_yuanlin"] = "淵臨",
    [":ofgu_yuanlin"] = "鎖定技，每輪開始時，你令所有其他角色進行一次【閃電】判定；其他角色的判定階段，你令其進行一次【閃電】判定；當一名角色受到雷電傷害後，你摸一張牌或回復1點體力。",
    ["ofgu_kuanglei"] = "狂雷",
    [":ofgu_kuanglei"] = "鎖定技，當你成為其他角色使用傷害牌的目標時，除非其交給你一張牌，否則其進行一次「雷擊」判定（黑桃：你對其造成2點雷電傷害；梅花：你回復1點體力，然後對其造成1點雷電傷害）。",
    ["@ofgu_kuanglei"] = "狂雷：交给 %src 一张牌，否则进行雷击判定",
    ["ofgu_qiongshan"] = "穹閃",
    [":ofgu_qiongshan"] = "每輪限一次，當其他角色的判定牌生效前，你可以獲得之並聲明此判定的花色和點數。",
    ["of_guanyinping"] = "關銀屏[線下]",
    ["#of_guanyinping"] = "鐵衣薔薇",
    ["ofgu_saxue"] = "灑血",
    [":ofgu_saxue"] = "準備階段，你可以橫置兩名角色，然後令一名其他角色對你與其造成共計2點火焰傷害（其先為每名目標分配造成傷害的點數，然後由你先進行結算）。",
    ["ofgu_xianfeng"] = "銜鋒",
    [":ofgu_xianfeng"] = "當你受到1點傷害後，你可以棄置傷害來源一張牌，若此牌花色為本回合首次進入棄牌堆，你獲得之。",
    ["of_mengdiaochan"] = "夢貂蟬[線下]",
    ["#of_mengdiaochan"] = "群芳之魁",
    ["ofgu_diyu"] = "低語",
    [":ofgu_diyu"] = "每輪開始時，你可以令一名角色本輪造成的傷害+1，然後你從「崩壞」「同疾」「弼昏」「義拒」中選擇一個未選擇過的技能令其獲得。",
    ["ofgu_fuyi"] = "拂衣",
    [":ofgu_fuyi"] = "當你成為【殺】的目標時，你可以令一名角色也成為此【殺】的目標並令所有目標角色各摸一張牌；當此【殺】被一名目標角色抵消後，此【殺】對其他目標角色無效。",
    ["ofgu_jiuji"] = "就計",
    [":ofgu_jiuji"] = "每輪結束後，你可以令兩名角色依次執行一個僅能對對方使用牌且雙方技能互換的額外回合。",
    ["of_luoguanzhong"] = "羅貫中[線下]",
    ["#of_luoguanzhong"] = "湖海散人",
    ["ofgu_zhuhun"] = "著魂",
    [":ofgu_zhuhun"] = "遊戲開始時，你隨機展示四張未加入遊戲的武將牌，確認後洗混扣置（僅對你可見），然後你摸等量的牌並在每張扣置的武將牌上正面放置一張手牌，稱為「魂」。",
    ["ofgu_jingshi"] = "經世",
    [":ofgu_jingshi"] = "其他角色回合開始時，其可以根據「魂」的提示猜測並翻開一張扣置的武將牌，若猜對，你摸兩張牌並可以交給其兩張牌。當所有武將牌被翻開後，移去這些牌並再次發動「著魂」。",
    ["@ofgu_yishi"] = "遺世",
    ["@ofgu_meihuo"] = "魅惑",
    ["ofgu_hun"] = "魂",
    ["#ofgu_zhuhun_reveal"] = "%from 展示武將牌：%arg",
    ["#ofgu_jingshi_reveal"] = "%from 翻開 %arg（猜測：%arg2）",
    ["ofgu_benghuai"] = "崩壞",
    [":ofgu_benghuai"] = "結束階段非體力最低則減上限或失血。",
    ["ofgu_tongji"] = "同疾",
    [":ofgu_tongji"] = "手牌>體力時只能以你為【殺】目標。",
    ["ofgu_bihun"] = "弼昏",
    [":ofgu_bihun"] = "手牌>上限時取消你對他角色使用的牌，單一目標則其獲得之。",
    ["ofgu_yiju"] = "義拒",
    [":ofgu_yiju"] = "其他角色以你為唯一目標後你棄一張牌。",
    ["@ofgu_qishen"] = "棄身：選擇至多三名角色",
    ["@ofgu_liaoliao"] = "了了：你可以棄置一張牌",
    ["@ofgu_hengren"] = "橫刃：你可以使用一張【殺】",
    ["@ofgu_danjue"] = "膽決：你可以交給 %src 一張牌",
    ["@ofgu_fangzhu"] = "放逐：選擇文曹丕",
    ["@ofgu_nianjun-self"] = "念君：選擇你的連接牌",
    ["@ofgu_nianjun"] = "念君：選擇要連接的其他角色",
    ["@ofgu_meihun"] = "魅魂：選擇一名其他角色",
    ["@ofgu_meihun-give"] = "魅魂：交給 %src 一張聲明花色的牌",
    ["@ofgu_zhiba"] = "制霸：為 %src 選擇拼點對手",
    ["@ofgu_beige"] = "悲歌：你可以棄置一張牌",
    ["@ofgu_quzhong"] = "曲終：將本回合棄置的牌當【殺】使用",
    ["@ofgu_saxue-chain"] = "灑血：橫置兩名角色",
    ["@ofgu_saxue-source"] = "灑血：選擇分配傷害的其他角色",
    ["@ofgu_diyu"] = "低語：選擇本輪傷害+1的角色",
    ["@ofgu_fuyi"] = "拂衣：選擇此【殺】的額外目標",
    ["@ofgu_jiuji"] = "就計：依次選擇兩名角色",
    ["@ofgu_jingshi-give"] = "經世：你可以交給 %src 兩張手牌",
    ["ofgu_zhuhun:confirm"] = "確認展示的武將牌",
    ["ofgu_saxue:0"] = "對關銀屏分配0點，對你分配2點",
    ["ofgu_saxue:1"] = "各分配1點",
    ["ofgu_saxue:2"] = "對目標分配2點，對你分配0點",
}


-- 謀攻篇線下八將 (SOURCE §3). Existing mobile/native variants are distinct.
local function gu_reveal_hu(room, owner, skill, union)
    local ids = room:getNCards(4, false)
    room:fillAG(ids)
    local kind = union and "both" or room:askForChoice(owner, skill, "slash+jink")
    local hu, rest = sgs.IntList(), sgs.IntList()
    for _, id in sgs.qlist(ids) do
        local c = sgs.Sanguosha:getCard(id)
        if owner:getPile("&ofgu_hu"):length() + hu:length() < 4 and ((kind == "both" or kind == "slash") and c:isKindOf("Slash") or (kind == "both" or kind == "jink") and c:isKindOf("Jink")) then hu:append(id)
        else rest:append(id) end
    end
    if not hu:isEmpty() then owner:addToPile("&ofgu_hu", hu, true) end
    gu_throw(room, nil, rest, skill); room:clearAG()
end
ofmou_gongsunzan = sgs.General(extension, "ofmou_gongsunzan", "qun", 4)
ofgu_yicong = gu_trigger("ofgu_yicong", {sgs.RoundStart}, function(self, event, room, p, data, owner)
    room:setPlayerMark(owner, "ofgu_yicong_mode", 0)
    if not gu_invoke(owner, self:objectName(), data) then return end
    local choice = room:askForChoice(owner, self:objectName(), "from+to")
    room:setPlayerMark(owner, "ofgu_yicong_mode", choice == "from" and 1 or 2)
    gu_reveal_hu(room, owner, self:objectName(), true)
end)
ofgu_yicong_distance = sgs.CreateDistanceSkillV2 {
    name = "#ofgu_yicong_distance",
    correct_func = function(self, from, to)
        local n = 0
        if from:getMark("ofgu_yicong_mode") == 1 then n = n - 1 end
        if to:getMark("ofgu_yicong_mode") == 2 then n = n + 1 end
        return n
    end,
}
ofgu_qiaomeng = gu_trigger("ofgu_qiaomeng", {sgs.Damage}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if d.from ~= owner or not d.card or not d.card:isKindOf("Slash") or not gu_invoke(owner, self:objectName(), data) then return end
    if room:askForChoice(owner, self:objectName(), "draw+hu", data) == "hu" then
        gu_reveal_hu(room, owner, self:objectName(), false)
    else
        owner:drawCards(1, self:objectName())
        if d.to:isAlive() and not d.to:isAllNude() then room:throwCard(room:askForCardChosen(owner, d.to, "hej", self:objectName()), d.to, owner) end
    end
end)
ofmou_gongsunzan:addSkill(ofgu_yicong); ofmou_gongsunzan:addSkill(ofgu_yicong_distance); ofmou_gongsunzan:addSkill(ofgu_qiaomeng)

ofmou_xunyu = sgs.General(extension, "ofmou_xunyu", "wei", 3)
ofgu_quhu = gu_active("ofgu_quhu", 1, 1, 999,
    function(self, targets, to, from) return #targets < 2 and to ~= from and not to:isNude() end,
    function(self, targets) return #targets == 2 end,
    function(self, room, source, targets)
        local own_ids = self:getSubcards()
        local actors = {source, targets[1], targets[2]}; local counts = {own_ids:length()}
        gu_throw(room, source, own_ids, "ofgu_quhu")
        for i = 2, 3 do
            local p = actors[i]
            if p:isAlive() and not p:isNude() then
                local c = room:askForExchange(p, "ofgu_quhu", p:getCardCount(true), 1, true, "@ofgu_quhu", false)
                local ids = c and c:getSubcards() or sgs.IntList()
                counts[i] = ids:length(); gu_throw(room, p, ids, "ofgu_quhu")
            else counts[i] = 0 end
        end
        local hi, lo = math.max(counts[1], counts[2], counts[3]), math.min(counts[1], counts[2], counts[3])
        if counts[1] > counts[2] and counts[1] > counts[3] then
            for i = 2, 3 do if actors[i]:isAlive() then actors[i]:drawCards(counts[i], "ofgu_quhu") end end
        else
            for i = 2, 3 do
                if counts[i] == hi and actors[i]:isAlive() then
                    for j = 1, 3 do if counts[j] == lo and actors[j]:isAlive() then room:damage(sgs.DamageStruct("ofgu_quhu", actors[i], actors[j], 1)) end end
                    local ids = sgs.IntList()
                    for _, id in sgs.qlist(own_ids) do if room:getCardPlace(id) == sgs.Player_DiscardPile then ids:append(id) end end
                    if actors[i]:isAlive() then gu_obtain(room, actors[i], ids, "ofgu_quhu") end
                end
            end
        end
    end, function(request, c) return not request:getInitiator():isJilei(c) end,
    function(p) return not p:isNude() end)
ofgu_jieming = gu_trigger("ofgu_jieming", {sgs.Damaged}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    local to = room:askForPlayerChosen(owner, room:getAlivePlayers(), self:objectName(), "@ofgu_jieming", true, true)
    if not to then return end
    to:drawCards(4, self:objectName())
    local n = math.max(1, owner:getLostHp())
    if not room:askForDiscard(to, self:objectName(), to:getCardCount(true), n, true, true, "@ofgu_jieming-discard") then room:loseHp(owner, 1, true, nil, self:objectName()) end
end)
ofmou_xunyu:addSkill(ofgu_quhu); ofmou_xunyu:addSkill(ofgu_jieming)

-- 謀曹丕: 追思 is named but its rules are not supplied; pending Tom.
-- Do not attach a mobile Cao Pi remembrance effect to this offline general.

ofmou_zhangjiao = sgs.General(extension, "ofmou_zhangjiao$", "qun", 3)
ofgu_leiji = gu_active("ofgu_leiji", nil, 0, 0, gu_one, gu_one_feasible,
    function(self, room, source, targets)
        room:removePlayerMark(source, "@ofgu_daobing", 2)
        room:damage(sgs.DamageStruct("ofgu_leiji", source, targets[1], 1, sgs.DamageStruct_Thunder))
    end, nil, function(p) return p:getMark("@ofgu_daobing") >= 2 end)
local function gu_daobing(room, owner, n) room:setPlayerMark(owner, "@ofgu_daobing", math.min(4, owner:getMark("@ofgu_daobing") + n)) end
ofgu_guidao = gu_trigger("ofgu_guidao", {sgs.GameStart, sgs.Damaged, sgs.DamageInflicted, sgs.TurnStart}, function(self, event, room, p, data, owner)
    if event == sgs.TurnStart then
        if p == owner then room:setPlayerMark(owner, "ofgu_guidao_disabled", 0) end
    elseif event == sgs.GameStart then gu_daobing(room, owner, 1)
    elseif event == sgs.Damaged then
        if owner:getMark("ofgu_guidao_disabled") == 0 and data:toDamage().nature ~= sgs.DamageStruct_Normal then gu_daobing(room, owner, 1) end
    elseif p == owner and owner:getMark("ofgu_guidao_disabled") == 0 and owner:getMark("@ofgu_daobing") > 0 and gu_invoke(owner, self:objectName(), data) then
        room:removePlayerMark(owner, "@ofgu_daobing")
        if owner:getPhase() == sgs.Player_NotActive then room:setPlayerMark(owner, "ofgu_guidao_disabled", 1) end
        return true
    end
end)
ofgu_huangtian = gu_trigger("ofgu_huangtian$", {sgs.TurnStart, sgs.RoundStart, sgs.Damage}, function(self, event, room, p, data, owner)
    if not owner:hasLordSkill("ofgu_huangtian") then return end
    if event == sgs.RoundStart then room:setPlayerMark(owner, "ofgu_huangtian_used", 0)
    elseif event == sgs.TurnStart then
        if p == owner and owner:getMark("ofgu_huangtian_started") == 0 then
            room:setPlayerMark(owner, "ofgu_huangtian_started", 1); owner:getDerivativeCard("_taipingyaoshu")
        end
    else
        local d = data:toDamage()
        if d.from and d.from ~= owner and d.from:getKingdom() == "qun" and owner:getMark("ofgu_huangtian_used") < 2 then
            room:addPlayerMark(owner, "ofgu_huangtian_used"); gu_daobing(room, owner, 1)
        end
    end
end, true)
ofmou_zhangjiao:addSkill(ofgu_leiji); ofmou_zhangjiao:addSkill(ofgu_guidao); ofmou_zhangjiao:addSkill(ofgu_huangtian)

ofmou_xiahoudun = sgs.General(extension, "ofmou_xiahoudun", "wei", 4)
ofgu_ganglie = gu_active("ofgu_ganglie", 1, 0, 0,
    function(self, targets, to, from) return to:getMark("ofgu_ganglie_hurt_" .. from:objectName()) > 0 and to:getMark("ofgu_ganglie_used_" .. from:objectName()) == 0 end,
    function(self, targets) return #targets > 0 end,
    function(self, room, source, targets)
        for _, to in ipairs(targets) do room:setPlayerMark(to, "ofgu_ganglie_used_" .. source:objectName(), 1) end
        for _, to in ipairs(targets) do if to:isAlive() then room:damage(sgs.DamageStruct("ofgu_ganglie", source, to, 2)) end end
    end)
ofgu_ganglie_record = gu_record("#ofgu_ganglie_record", {sgs.Damaged}, function(self, event, room, p, data)
    local d = data:toDamage()
    if d.from then room:setPlayerMark(d.from, "ofgu_ganglie_hurt_" .. p:objectName(), 1) end
end)
ofgu_qingjian = gu_trigger("ofgu_qingjian", {sgs.CardsMoveOneTime, sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if event == sgs.CardsMoveOneTime then
        local move = data:toMoveOneTime()
        if move.to_place ~= sgs.Player_DiscardPile or owner:getPile("ofgu_qingjian"):length() >= 3
            or bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_USE then return end
        local ids = sgs.IntList()
        for _, id in sgs.qlist(move.card_ids) do if room:getCardPlace(id) == sgs.Player_DiscardPile then ids:append(id) end end
        if ids:isEmpty() then return end
        room:fillAG(ids, owner); local id = room:askForAG(owner, ids, false, self:objectName()); room:clearAG(owner)
        owner:addToPile("ofgu_qingjian", id, true)
    elseif p == owner and p:getPhase() == sgs.Player_Finish then
        local ids = owner:getPile("ofgu_qingjian")
        while not ids:isEmpty() and owner:isAlive() do
            local to = room:askForPlayerChosen(owner, room:getAlivePlayers(), self:objectName(), "@ofgu_qingjian", false, true)
            room:fillAG(ids, owner); local id = room:askForAG(owner, ids, false, self:objectName()); room:clearAG(owner)
            room:obtainCard(to, id, self:objectName(), true); ids = owner:getPile("ofgu_qingjian")
        end
    end
end, true)
ofmou_xiahoudun:addSkill(ofgu_ganglie); ofmou_xiahoudun:addSkill(ofgu_ganglie_record); ofmou_xiahoudun:addSkill(ofgu_qingjian)

ofmou_luxun = sgs.General(extension, "ofmou_luxun", "wu", 3)
ofgu_qianxunvs = sgs.CreateViewAsSkillV2 {
    name = "ofgu_qianxun",
    can_activate = function(self, request) return request:getPattern() == "@@ofgu_qianxun" end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
    create_card = function(self, request)
        local name = request:getInitiator():getTag("ofgu_qianxun_use"):toString()
        if name == "" then return nil end
        local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0); c:setSkillName("ofgu_qianxun"); return c
    end,
}
ofgu_qianxun = gu_trigger("ofgu_qianxun", {sgs.CardEffected, sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    local names = gu_names(owner, "ofgu_qianxun_names")
    if event == sgs.CardEffected then
        local e = data:toCardEffect()
        if e.to ~= owner or e.from == owner or not e.card:isKindOf("TrickCard") or table.contains(names, e.card:objectName()) then return end
        table.insert(names, e.card:objectName()); gu_setnames(owner, "ofgu_qianxun_names", names)
        local n = math.min(5, #names)
        if owner:isNude() then return end
        local c = room:askForExchange(owner, self:objectName(), n, 0, true, "@ofgu_qianxun-store", true)
        if c and c:subcardsLength() > 0 then owner:addToPile("ofgu_qianxun", c, false) end
    elseif p == owner and p:getPhase() == sgs.Player_Play and #names > 0 then
        local name = room:askForChoice(owner, self:objectName(), table.concat(names, "+") .. "+cancel")
        if name == "cancel" then return end
        table.removeOne(names, name); gu_setnames(owner, "ofgu_qianxun_names", names)
        local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
        if c and c:isNDTrick() then
            owner:setTag("ofgu_qianxun_use", sgs.QVariant(name)); room:askForUseCard(owner, "@@ofgu_qianxun", "@ofgu_qianxun-use", -1, sgs.Card_MethodUse, false); owner:removeTag("ofgu_qianxun_use")
        end
        if c then c:deleteLater() end
    end
end)
ofgu_qianxun:setViewAsSkill(ofgu_qianxunvs)
ofgu_lianying_record = gu_record("#ofgu_lianying_record", {sgs.CardsMoveOneTime, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.CardsMoveOneTime then
        local move = data:toMoveOneTime()
        if move.from and (not move.to or move.to:objectName() ~= move.from:objectName() or move.to_place ~= sgs.Player_PlaceHand) then
            local from = room:findPlayerByObjectName(move.from:objectName())
            if from then room:addPlayerMark(from, "ofgu_lianying_lost", move.card_ids:length()) end
        end
    elseif data:toPhaseChange().to == sgs.Player_NotActive then
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            local ids = q:getPile("ofgu_qianxun"); if not ids:isEmpty() then gu_obtain(room, q, ids, "ofgu_qianxun") end
        end
    end
end)
ofgu_lianying = gu_trigger("ofgu_lianying", {sgs.EventPhaseChanging}, function(self, event, room, p, data, owner)
    if p == owner or data:toPhaseChange().to ~= sgs.Player_NotActive or not gu_invoke(owner, self:objectName(), data) then return end
    local ids = room:getNCards(math.min(4, owner:getMark("ofgu_lianying_lost") + 1), false)
    room:fillAG(ids, owner)
    while not ids:isEmpty() and owner:isAlive() do
        local to = room:askForPlayerChosen(owner, room:getAlivePlayers(), self:objectName(), "@ofgu_lianying", false, true)
        local id = room:askForAG(owner, ids, false, self:objectName())
        room:obtainCard(to, id, self:objectName(), false); ids:removeOne(id)
    end
    room:clearAG(owner)
    gu_throw(room, nil, ids, self:objectName())
end)
extension:addSkills(gu_record("#ofgu_lianying_clear", {sgs.EventPhaseStart}, function(self, event, room, p, data)
    if p:getPhase() == sgs.Player_NotActive then for _, q in sgs.qlist(room:getAllPlayers()) do room:setPlayerMark(q, "ofgu_lianying_lost", 0) end end
end))
ofmou_luxun:addSkill(ofgu_qianxun); ofmou_luxun:addSkill(ofgu_lianying_record); ofmou_luxun:addSkill(ofgu_lianying)

ofmou_handang = sgs.General(extension, "ofmou_handang", "wu", 4)
ofgu_gongqi_range = sgs.CreateAttackRangeSkillV2 {
    name = "#ofgu_gongqi_range", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx) return ctx:getPrimary():hasSkill("ofgu_gongqi") and 4 or 0 end,
}
ofgu_gongqi = gu_trigger("ofgu_gongqi", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Play then return end
    local c = room:askForCard(owner, "..", "@ofgu_gongqi", data, sgs.Card_MethodDiscard, nil, false, self:objectName())
    if c then owner:setTag("ofgu_gongqi_suit", sgs.QVariant(c:getSuitString())) else owner:removeTag("ofgu_gongqi_suit") end
end)
ofgu_gongqi_record = gu_record("#ofgu_gongqi_record", {sgs.CardUsed, sgs.CardFinished, sgs.EventPhaseEnd}, function(self, event, room, p, data)
    if event == sgs.EventPhaseEnd then
        if p:getPhase() == sgs.Player_Play then p:removeTag("ofgu_gongqi_suit") end
        return
    end
    local use = data:toCardUse(); local suit = use.from:getTag("ofgu_gongqi_suit"):toString()
    if suit == "" or use.from:getPhase() ~= sgs.Player_Play or use.card:getTypeId() == 0 then return end
    local pattern = ".|^" .. suit
    for _, q in sgs.qlist(room:getOtherPlayers(use.from)) do
        if event == sgs.CardUsed then room:setPlayerCardLimitation(q, "use,response", pattern, false)
        else room:removePlayerCardLimitation(q, "use,response", pattern .. "$0") end
    end
end)
ofgu_jiefan = gu_active("ofgu_jiefan", 1, 0, 0,
    function(self, targets) return #targets < 1 end, gu_one_feasible,
    function(self, room, source, targets)
        local to = targets[1]; local inrange = sgs.SPlayerList()
        for _, q in sgs.qlist(room:getOtherPlayers(to)) do if q:inMyAttackRange(to) then inrange:append(q) end end
        local choice = room:askForChoice(to, "ofgu_jiefan", "discard+draw", ToData(source))
        if choice == "draw" then to:drawCards(inrange:length(), "ofgu_jiefan")
        else for _, q in sgs.qlist(inrange) do room:askForDiscard(q, "ofgu_jiefan", 1, 1, false, true) end end
        if gu_invoke(source, "ofgu_jiefan_backwater", ToData(to)) then
            room:setPlayerMark(source, "ofgu_jiefan_disabled", 1)
            if choice == "draw" then for _, q in sgs.qlist(inrange) do room:askForDiscard(q, "ofgu_jiefan", 1, 1, false, true) end
            else to:drawCards(inrange:length(), "ofgu_jiefan") end
        end
    end, nil, function(p) return p:getMark("ofgu_jiefan_disabled") == 0 end)
extension:addSkills(gu_record("#ofgu_jiefan_reset", {sgs.Death}, function(self, event, room, p, data)
    local death = data:toDeath()
    if death.damage and death.damage.from then room:setPlayerMark(death.damage.from, "ofgu_jiefan_disabled", 0) end
end))
ofmou_handang:addSkill(ofgu_gongqi); ofmou_handang:addSkill(ofgu_gongqi_range); ofmou_handang:addSkill(ofgu_gongqi_record); ofmou_handang:addSkill(ofgu_jiefan)

ofmou_gaoshun = sgs.General(extension, "ofmou_gaoshun", "qun", 4)
ofgu_xianzhen = gu_active("ofgu_xianzhen", 1, 0, 0,
    function(self, targets, to, from) return gu_one(self, targets, to, from) and to:getHp() < from:getHp() end, gu_one_feasible,
    function(self, room, source, targets) room:setPlayerMark(targets[1], "ofgu_xianzhen_" .. source:objectName() .. "-PlayClear", 1) end)
ofgu_xianzhen_mod = sgs.CreateTargetModSkillV2 {
    name = "#ofgu_xianzhen_mod", pattern = ".", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local from, to = ctx:getPrimary(), ctx:getSecondary()
        if ctx:getModType() == sgs.TargetModSkill_DistanceLimit and to and to:getMark("ofgu_xianzhen_" .. from:objectName() .. "-PlayClear") > 0 then return 999 end
        return 0
    end,
}
ofgu_xianzhen_trigger = gu_trigger("#ofgu_xianzhen_trigger", {sgs.TargetSpecified}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from ~= owner or not use.card:isKindOf("Slash") or owner:isKongcheng() then return end
    for _, to in sgs.qlist(use.to) do
        if to:getMark("ofgu_xianzhen_" .. owner:objectName() .. "-PlayClear") > 0 and not to:isKongcheng() and gu_invoke(owner, "ofgu_xianzhen", ToData(to)) then
            local pd = owner:PinDian(to, "ofgu_xianzhen")
            if pd.to_card:isKindOf("Slash") and room:getCardPlace(pd.to_card:getEffectiveId()) == sgs.Player_DiscardPile then room:obtainCard(owner, pd.to_card, "ofgu_xianzhen", true) end
            if pd.from_number > pd.to_number then
                to:addQinggangTag(use.card)
                if use.m_addHistory then room:addPlayerHistory(owner, "Slash", -1); use.m_addHistory = false; data:setValue(use) end
                if owner:getMark("ofgu_xianzhen_damage-Clear") == 0 then
                    room:setPlayerMark(owner, "ofgu_xianzhen_damage-Clear", 1)
                    room:damage(sgs.DamageStruct("ofgu_xianzhen", owner, to, 1))
                end
            end
        end
    end
end)
ofgu_jinjiu_filter = sgs.CreateFilterSkill {
    name = "ofgu_jinjiu",
    view_filter = function(self, c) return c:isKindOf("Analeptic") end,
    view_as = function(self, c)
        local slash = sgs.Sanguosha:cloneCard("slash", c:getSuit(), c:getNumber()); slash:setSkillName(self:objectName())
        local wrapped = sgs.Sanguosha:getWrappedCard(c:getId()); wrapped:takeOver(slash); slash:deleteLater(); return wrapped
    end,
}
ofgu_jinjiu_trigger = gu_trigger("#ofgu_jinjiu_trigger", {sgs.DamageInflicted, sgs.PindianVerifying}, function(self, event, room, p, data, owner)
    if event == sgs.DamageInflicted then
        local d = data:toDamage()
        if d.to == owner and d.card and d.card:isKindOf("Slash") and d.card:hasFlag("drank") then d.damage = 1; data:setValue(d) end
    else
        local pd = data:toPindian()
        if pd.from == owner and pd.to_card:isKindOf("Analeptic") then pd.to_number = 1; data:setValue(pd)
        elseif pd.to == owner and pd.from_card:isKindOf("Analeptic") then pd.from_number = 1; data:setValue(pd) end
    end
end, true)
ofgu_jinjiu_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#ofgu_jinjiu_prohibit",
    holder_selector = sgs.CorrectSkill_AllHolders,
    is_prohibited = function(self, ctx)
        local holder, from, card = ctx:getHolder(), ctx:getFrom(), ctx:getCard()
        return card:isKindOf("Analeptic") and holder ~= from and holder:hasSkill("ofgu_jinjiu")
            and holder:getPhase() ~= sgs.Player_NotActive
    end,
}
ofmou_gaoshun:addSkill(ofgu_xianzhen); ofmou_gaoshun:addSkill(ofgu_xianzhen_mod); ofmou_gaoshun:addSkill(ofgu_xianzhen_trigger)
ofmou_gaoshun:addSkill(ofgu_jinjiu_filter); ofmou_gaoshun:addSkill(ofgu_jinjiu_trigger); ofmou_gaoshun:addSkill(ofgu_jinjiu_prohibit)
extension:insertRelatedSkills("ofgu_jinjiu", "#ofgu_jinjiu_prohibit")

sgs.LoadTranslationTable {
    ["ofmou_gongsunzan"] = "公孫瓚[謀攻線下]",
    ["ofgu_yicong"] = "義從",
    [":ofgu_yicong"] = "每輪開始時，你可以令本輪你計算與其他角色距離-1／其他角色計算與你距離+1，然後亮出牌堆頂四張牌並將其中所有的【殺】/【閃】置於武將牌上，稱為「扈」（至多有四張）。你可以將「扈」如手牌般使用或打出。",
    ["ofgu_qiaomeng"] = "趫猛",
    [":ofgu_qiaomeng"] = "當你使用【殺】造成傷害後，你可選擇一項：1.摸一張牌，然後棄置受傷角色區域內一張牌；2.亮出牌堆頂四張牌，然後將其中所有的【殺】或【閃】置為「扈」。",
    ["ofmou_xunyu"] = "荀彧[謀攻線下]",
    ["ofgu_quhu"] = "驅虎",
    [":ofgu_quhu"] = "出牌階段限一次，你可以與兩名有牌的其他角色依次棄置至少一張牌：棄置牌最多的其他角色對棄置牌最少的角色各造成1點傷害，然後獲得你棄置的牌。若棄置牌唯一最多的角色是你，則這兩名角色各摸等同其棄置牌數的牌。",
    ["ofgu_jieming"] = "節命",
    [":ofgu_jieming"] = "當你受到傷害後，你可令一名角色摸四張牌，然後其需棄置至少X張牌（X為你已損失的體力值，至少為1），否則你失去1點體力。",
    ["ofmou_zhangjiao"] = "張角[謀攻線下]",
    ["ofgu_leiji"] = "雷擊",
    [":ofgu_leiji"] = "出牌階段，你可以移去2枚「道兵」，然後對一名其他角色造成1點雷電傷害。",
    ["ofgu_guidao"] = "鬼道",
    [":ofgu_guidao"] = "遊戲開始時，或一名角色受到屬性傷害後，你獲得1枚「道兵」（至多4枚）。當你受到傷害時，你可以移去1枚「道兵」並防止此傷害，若此時是你回合外，此技能失效直到你下回合開始。",
    ["ofgu_huangtian"] = "黃天",
    [":ofgu_huangtian"] = "主公技，鎖定技，你的首回合開始時，你從遊戲外將【太平要術】置入裝備區；每輪限兩次，其他群勢力角色造成傷害後，你獲得1枚「道兵」。",
    ["ofmou_xiahoudun"] = "夏侯惇[謀攻線下]",
    ["ofgu_ganglie"] = "剛烈",
    [":ofgu_ganglie"] = "出牌階段限一次，你可以選擇任意名本局對你造成過傷害且未以此法選擇過的角色，你對這些角色各造成2點傷害。",
    ["ofgu_qingjian"] = "清儉",
    [":ofgu_qingjian"] = "鎖定技，當有牌不因使用而置入棄牌堆時，你將其中一張置於武將牌上（至多三張）；結束階段，你將這些牌交給任意角色。",
    ["ofmou_luxun"] = "陸遜[謀攻線下]",
    ["ofgu_qianxun"] = "謙遜",
    [":ofgu_qianxun"] = "不為你使用的錦囊牌對你生效時，若你未記錄此牌名，你記錄之，然後你可以將至多X張牌置於武將牌上（X為你記錄牌名數，至多為5），此回合結束時獲得這些牌。出牌階段開始時，你可以移去一個記錄牌名，若為普通錦囊牌，則你可以視為使用之。",
    ["ofgu_lianying"] = "連營",
    [":ofgu_lianying"] = "其他角色回合結束時，你可以觀看牌堆頂X張牌（X為你本回合失去的牌數+1，至多為4），然後將這些牌交給任意角色。",
    ["ofmou_handang"] = "韓當[謀攻線下]",
    ["ofgu_gongqi"] = "弓騎",
    [":ofgu_gongqi"] = "你的攻擊範圍+4。出牌階段開始時，你可以棄置一張牌，此階段其他角色只能使用或打出此花色的手牌或虛擬牌響應你使用的牌。",
    ["ofgu_jiefan"] = "解煩",
    [":ofgu_jiefan"] = "出牌階段限一次，你可令一名角色選擇一項：1.令攻擊範圍內含有其的角色依次棄置一張牌；2.摸等同攻擊範圍內含有其的角色數的牌。背水：此技能失效直到你殺死角色。",
    ["ofmou_gaoshun"] = "高順[謀攻線下]",
    ["ofgu_xianzhen"] = "陷陣",
    [":ofgu_xianzhen"] = "出牌階段限一次，你可以選擇一名體力值小於你的角色，此階段你對其使用牌無距離限制，且使用【殺】指定其為目標後可以與其拼點：若你贏，你對其造成1點傷害（每回合限一次），此【殺】無視防具和次數；若其拼點牌為【殺】，你獲得之。",
    ["ofgu_jinjiu"] = "禁酒",
    [":ofgu_jinjiu"] = "鎖定技，你的【酒】只能當【殺】使用或打出；當你受到【酒】【殺】的傷害時，此傷害減至1點；回合內，其他角色不能使用【酒】；與你拼點的角色亮出拼點牌後，若此牌為【酒】，點數視為A。",
    ["&ofgu_hu"] = "扈",
    ["@ofgu_daobing"] = "道兵",
    ["@ofgu_quhu"] = "驅虎：棄置至少一張牌",
    ["@ofgu_jieming"] = "節命：選擇摸四張牌的角色",
    ["@ofgu_jieming-discard"] = "節命：棄置所需數量的牌，或取消令荀彧失去1點體力",
    ["@ofgu_qingjian"] = "清儉：選擇獲得牌的角色",
    ["@ofgu_qianxun-store"] = "謙遜：你可以將牌置於武將牌上",
    ["@ofgu_qianxun-use"] = "謙遜：你可以視為使用所移去記錄的錦囊牌",
    ["@ofgu_lianying"] = "連營：選擇獲得牌的角色",
    ["@ofgu_gongqi"] = "弓騎：你可以棄置一張牌",
    ["ofgu_yicong:from"] = "你計算與其他角色距離-1",
    ["ofgu_yicong:to"] = "其他角色計算與你距離+1",
    ["ofgu_qiaomeng:draw"] = "摸一張牌並棄置受傷角色區域內一張牌",
    ["ofgu_qiaomeng:hu"] = "亮出四張牌並獲得扈",
    ["ofgu_jiefan_backwater"] = "解煩·背水",
    ["ofgu_jiefan:discard"] = "令攻擊範圍內含有你的角色依次棄置一張牌",
    ["ofgu_jiefan:draw"] = "摸等同攻擊範圍內含有你的角色數的牌",
}


-- SOURCE-C C2: reuse the existing Ying class and #kezhuanYing destruction rule.
-- No new Ying card definition or duplicate general ID.
of_gu_zhaoxiang = sgs.General(extension, "of_gu_zhaoxiang", "shu", 4, false)
ofgu_qianling = gu_active("ofgu_qianling", 2, 0, 0,
    function(self, targets, to, source) return #targets < 3 and to ~= source end,
    function(self, targets) return #targets <= 3 end,
    function(self, room, source, targets)
        room:showAllCards(source)
        for _, to in ipairs(targets) do room:showAllCards(to) end
        local function black(p)
            local n = 0
            for _, c in sgs.qlist(p:getHandcards()) do if c:isBlack() then n = n + 1 end end
            return n
        end
        local eligible = sgs.SPlayerList()
        for _, to in ipairs(targets) do if to:isAlive() and black(to) == black(source) then eligible:append(to) end end
        if eligible:isEmpty() then return end
        local to = room:askForPlayerChosen(source, eligible, "ofgu_qianling", "@ofgu_qianling", true, true)
        if not to then return end
        local moves = sgs.CardsMoveList()
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName(), to:objectName(), "ofgu_qianling", "")
        moves:append(sgs.CardsMoveStruct(source:handCards(), source, to, sgs.Player_PlaceHand, sgs.Player_PlaceHand, reason))
        moves:append(sgs.CardsMoveStruct(to:handCards(), to, source, sgs.Player_PlaceHand, sgs.Player_PlaceHand, reason))
        room:moveCardsAtomic(moves, false)
    end)
local function gu_ying_id(room)
    for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
        if sgs.Sanguosha:getEngineCard(id):isKindOf("Ying") and not room:getCardOwner(id)
            and room:getCardPlace(id) ~= sgs.Player_DrawPile and room:getCardPlace(id) ~= sgs.Player_DiscardPile then return id end
    end
end
local function gu_queying_card(source, name)
    local room = source:getRoom()
    if source:getHandcardNum() >= source:getMaxHp() then return nil end
    local id = gu_ying_id(room)
    if not id then return nil end
    room:obtainCard(source, id, "ofgu_queying", false)
    local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    c:setSkillName("ofgu_queying"); c:deleteLater()
    return c
end
ofgu_queyingCard = sgs.CreateSkillCard {
    name = "ofgu_queyingCard", will_throw = false,
    filter = function(self, targets, to, source)
        local c = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, 0)
        c:setSkillName("ofgu_queying"); c:deleteLater()
        local ps = sgs.PlayerList(); for _, p in ipairs(targets) do ps:append(p) end
        return c:targetFilter(ps, to, source) and not source:isProhibited(to, c)
    end,
    feasible = function(self, targets, source)
        local c = sgs.Sanguosha:cloneCard(self:getUserString(), sgs.Card_NoSuit, 0)
        c:deleteLater()
        local ps = sgs.PlayerList(); for _, p in ipairs(targets) do ps:append(p) end
        return c:targetsFeasible(ps, source)
    end,
    on_validate = function(self, use) return gu_queying_card(use.from, self:getUserString()) end,
    on_validate_in_response = function(self, source) return gu_queying_card(source, self:getUserString()) end,
}
ofgu_queying = sgs.CreateViewAsSkillV2 {
    name = "ofgu_queying", response_or_use = true, n = 0,
    can_activate = function(self, request)
        local p = request:getInitiator()
        if p:getHandcardNum() >= p:getMaxHp() or not gu_ying_id(p:getRoom()) then return false end
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return sgs.Slash_IsAvailable(p) end
        return request:getPattern() == "slash" or request:getPattern() == "jink"
    end,
    can_select_card = function() return false end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
    create_card = function(self, request)
        local c = ofgu_queyingCard:clone()
        c:setSkillName("ofgu_queying")
        c:setUserString(request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and "slash" or request:getPattern())
        return c
    end,
}
of_gu_zhaoxiang:addSkill(ofgu_qianling); of_gu_zhaoxiang:addSkill(ofgu_queying)
sgs.LoadTranslationTable {
    ["of_gu_zhaoxiang"] = "趙襄[線下]", ["#of_gu_zhaoxiang"] = "暗香吟雪",
    ["ofgu_qianling"] = "潜聆",
    [":ofgu_qianling"] = "出牌阶段限两次，你可以令至多三名角色与你展示手牌，然后你可以与其中一名黑色手牌数与你相同的角色交换手牌。",
    ["@ofgu_qianling"] = "潜聆：你可以选择一名角色交换手牌",
    ["ofgu_queying"] = "雀影",
    [":ofgu_queying"] = "若你的手牌数小于体力上限，你可以获得一张【影】，视为使用一张【杀】或【闪】。",
}


-- SOURCE-C append: the four kingdoms form a circular order.
local function gu_huhaibi_order(room, p)
    if not gu_invoke(p, "ofgu_huhaibi") then return end
    local remaining, order = {"wei", "shu", "wu", "qun"}, {}
    while #remaining > 1 do
        local choice = room:askForChoice(p, "ofgu_huhaibi", table.concat(remaining, "+"))
        for i, name in ipairs(remaining) do
            if name == choice then table.insert(order, table.remove(remaining, i)); break end
        end
    end
    table.insert(order, remaining[1])
    gu_setnames(p, "ofgu_huhaibi_order", order)
end
ofgu_huhaibi = sgs.CreateTreasure {
    name = "_ofgu_huhaibi", class_name = "OfguHuhaibi", suit = sgs.Card_Diamond, number = 5,
    on_install = function(self, p)
        gu_setnames(p, "ofgu_huhaibi_order", {"wei", "shu", "wu", "qun"})
        gu_huhaibi_order(p:getRoom(), p)
    end,
}
ofgu_huhaibi:setParent(extension_card)
extension:addSkills(gu_record("#ofgu_huhaibi_record", {sgs.EventPhaseStart, sgs.CardsMoveOneTime}, function(self, event, room, p, data)
    if event == sgs.EventPhaseStart then
        if p:getPhase() == sgs.Player_Finish and p:getTreasure() and p:getTreasure():isKindOf("OfguHuhaibi") then gu_huhaibi_order(room, p) end
        return
    end
    local m = data:toMoveOneTime()
    for i, id in sgs.qlist(m.card_ids) do
        if m.from_places:at(i) == sgs.Player_PlaceEquip and sgs.Sanguosha:getEngineCard(id):isKindOf("OfguHuhaibi") then
            -- Destroy even when the departure was a transfer into another equipment area.
            local move = sgs.CardsMoveStruct(id, nil, sgs.Player_PlaceTable,
                sgs.CardMoveReason(sgs.CardMoveReason_S_MASK_BASIC_REASON, "", "BreakCard", ""))
            room:moveCardsAtomic(move, true)
        end
    end
end))
extension:addSkills(gu_record("#ofgu_huhaibi_damage", {sgs.DamageCaused}, function(self, event, room, p, data)
    local d = data:toDamage()
    if not d.from or not d.to then return end
    for _, holder in sgs.qlist(room:getAlivePlayers()) do
        if holder:getTreasure() and holder:getTreasure():isKindOf("OfguHuhaibi") then
            local order = gu_names(holder, "ofgu_huhaibi_order")
            for i, kingdom in ipairs(order) do
                local nextkingdom = order[i % #order + 1]
                if (d.from:getKingdom() == kingdom and d.to:getKingdom() == nextkingdom)
                    or (d.to:getKingdom() == kingdom and d.from:getKingdom() == nextkingdom) then
                    d.damage = d.damage + 1; break
                end
            end
        end
    end
    data:setValue(d)
end))
ofgu_ranhan = gu_active("ofgu_ranhan", 1, 0, 0, function() return false end, function(self, targets) return #targets == 0 end,
    function(self, room, source, targets)
        if not source:hasEquipArea(4) then return end
        local pen
        for _, id in sgs.qlist(sgs.Sanguosha:getRandomCards(true)) do
            if sgs.Sanguosha:getEngineCard(id):isKindOf("OfguHuhaibi") and not room:getCardOwner(id)
                and room:getCardPlace(id) ~= sgs.Player_DrawPile and room:getCardPlace(id) ~= sgs.Player_DiscardPile then pen = id; break end
        end
        if not pen then return end
        local suits, ids = {}, sgs.IntList()
        while true do
            local available = sgs.IntList()
            for _, q in sgs.qlist(room:getAlivePlayers()) do
                for _, c in sgs.qlist(q:getCards("ej")) do
                    if not suits[c:getSuit()] and c:hasSuit() and source:canDiscard(q, c:getEffectiveId()) then available:append(c:getEffectiveId()) end
                end
            end
            if available:isEmpty() then break end
            room:fillAG(available, source)
            local id = room:askForAG(source, available, true, "ofgu_ranhan"); room:clearAG(source)
            if id < 0 then break end
            ids:append(id); suits[sgs.Sanguosha:getCard(id):getSuit()] = true
        end
        for _, id in sgs.qlist(ids) do
            local owner = room:getCardOwner(id)
            local place = room:getCardPlace(id)
            if owner and (place == sgs.Player_PlaceEquip or place == sgs.Player_PlaceDelayedTrick) and source:canDiscard(owner, id) then
                room:throwCard(id, "ofgu_ranhan", owner, source)
            end
        end
        if source:isAlive() and source:hasEquipArea(4) then
            local treasures = sgs.IntList()
            for _, c in sgs.qlist(source:getEquips()) do
                if c:isKindOf("Treasure") then treasures:append(c:getEffectiveId()) end
            end
            if treasures:length() >= source:getEquipArea(4) then
                room:fillAG(treasures, source)
                local replaced = room:askForAG(source, treasures, false, "ofgu_ranhan"); room:clearAG(source)
                room:throwCard(replaced, "ofgu_ranhan", source)
            end
            room:moveCardTo(sgs.Sanguosha:getCard(pen), nil, source, sgs.Player_PlaceEquip,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, source:objectName(), "ofgu_ranhan", ""), true)
        end
    end)
of_luoguanzhong:addSkill(ofgu_ranhan)
sgs.LoadTranslationTable {
    ["ofgu_ranhan"] = "染瀚",
    [":ofgu_ranhan"] = "出牌阶段限一次，你可以弃置场上任意张花色各不同的牌，将游戏外的【湖海笔】置入装备区。",
    ["OfguHuhaibi"] = "湖海笔", ["_ofgu_huhaibi"] = "湖海笔", ["ofgu_huhaibi"] = "湖海笔",
    [":_ofgu_huhaibi"] = "结束阶段或当此牌置入你的装备区后，你可以调整笔上势力的顺序；笔上相邻势力的角色互相造成的伤害+1；此牌离开你的装备区时销毁。",
}

-- SOURCE-C C1 and Tom's appended damage target clarification.
of_gu_jiepangtong = sgs.General(extension, "of_gu_jiepangtong", "shu", 3)
ofgu_xiangxing = gu_trigger("ofgu_xiangxing", {sgs.GameStart}, function() end, true)
-- Borrow native skills with exact parent refs; never detach an innate copy.
extension:addSkills(gu_record("#ofgu_xiangxing_record", {sgs.GameStart, sgs.TurnStart, sgs.Death, sgs.EventAcquireSkill, sgs.EventLoseSkill}, function(self, event, room, p, data)
    if room:getTag("ofgu_xiangxing_sync"):toBool() then return end
    room:setTag("ofgu_xiangxing_sync", sgs.QVariant(true))
    for _, owner in sgs.qlist(room:getAllPlayers()) do
        local active = owner:isAlive() and owner:hasSkill("ofgu_xiangxing")
        for _, to in sgs.qlist(room:getAllPlayers()) do
            if to ~= owner then
                for _, name in ipairs({"yingzi", "biyue", "#yingzi"}) do
                    local key = "ofgu_xiangxing_" .. owner:objectName() .. "_" .. name
                    local id = to:getTag(key):toInt()
                    if not active or not to:isAlive() then
                        if id > 0 then
                            to:removeTag(key)
                            room:detachAttachedSkill(sgs.SkillInstanceRef(to:objectName(), sgs.SkillInstanceKey(name, id)))
                        end
                    elseif not to:hasSkill(name, true) then
                        local parent = sgs.SkillInstanceRef(owner:objectName(), sgs.SkillInstanceKey("ofgu_xiangxing", owner:getSkillInstanceId("ofgu_xiangxing")))
                        local ref = room:attachSkillToPlayer(to, name, parent)
                        to:setTag(key, sgs.QVariant(ref.key.instanceID))
                    end
                end
            end
        end
    end
    room:removeTag("ofgu_xiangxing_sync")
end))
ofgu_lianhuan = sgs.CreateViewAsSkillV2 {
    name = "ofgu_lianhuan",
    can_activate = function(self, request)
        local p = request:getInitiator()
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and p:getMark("ofgu_lianhuan_used-PlayClear") < p:getRoom():getTag("SwapPile"):toInt() + 1
    end,
    can_select_card = function(self, request, c)
        return request:getSelectedCardIds():isEmpty() and not c:hasFlag("using")
    end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():length() == 1 end,
    create_card = function(self, request)
        local c = sgs.Sanguosha:cloneCard("iron_chain", sgs.Card_NoSuit, 0)
        c:addSubcards(request:getSelectedCardIds()); c:setSkillName("ofgu_lianhuan"); return c
    end,
}
extension:addSkills(gu_record("#ofgu_lianhuan_record", {sgs.CardUsed, sgs.CardFinished, sgs.CardsMoveOneTime}, function(self, event, room, p, data)
    if event == sgs.CardsMoveOneTime then
        local move = data:toMoveOneTime()
        if move.from and move.reason.m_skillName == "ofgu_lianhuan"
            and bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_RECAST then
            room:addPlayerMark(room:findPlayerByObjectName(move.from:objectName()), "ofgu_lianhuan_used-PlayClear")
        end
        return
    end
    local use = data:toCardUse()
    if not use.card or use.card:getSkillName() ~= "ofgu_lianhuan" then return end
    if event == sgs.CardUsed then room:addPlayerMark(use.from, "ofgu_lianhuan_used-PlayClear"); return end
    if use.to:length() ~= 2 then return end
    local a, b = use.to:first(), use.to:last()
    if not a:isAlive() or not b:isAlive() then return end
    local pool = {}
    for _, id in sgs.qlist(a:handCards()) do table.insert(pool, id) end
    for _, id in sgs.qlist(b:handCards()) do table.insert(pool, id) end
    for i = #pool, 2, -1 do local j = math.random(i); pool[i], pool[j] = pool[j], pool[i] end
    local left, right = sgs.IntList(), sgs.IntList()
    local half = math.floor(#pool / 2)
    for i = 1, half do left:append(pool[i]); right:append(pool[i + half]) end
    local moves = sgs.CardsMoveList()
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, use.from:objectName(), "ofgu_lianhuan", "")
    if not left:isEmpty() then moves:append(sgs.CardsMoveStruct(left, a, sgs.Player_PlaceHand, reason)) end
    if not right:isEmpty() then moves:append(sgs.CardsMoveStruct(right, b, sgs.Player_PlaceHand, reason)) end
    if #pool % 2 == 1 and use.from:isAlive() then
        moves:append(sgs.CardsMoveStruct(pool[#pool], use.from, sgs.Player_PlaceHand, reason))
    end
    if not moves:isEmpty() then room:moveCardsAtomic(moves, false) end
end))
ofgu_niepan = gu_trigger("ofgu_niepan", {sgs.EnterDying}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getMark("@ofgu_niepan") == 0 or not gu_invoke(owner, self:objectName(), data) then return end
    room:setPlayerMark(owner, "@ofgu_niepan", 0)
    owner:drawCards(3, self:objectName())
    room:recover(owner, sgs.RecoverStruct(self:objectName(), owner, 3 - owner:getHp()))
    if owner:isAlive() then
        local to = room:askForPlayerChosen(owner, room:getAlivePlayers(), self:objectName(), "@ofgu_niepan-target", false, true)
        if to then room:damage(sgs.DamageStruct(self:objectName(), owner, to, 2, sgs.DamageStruct_Fire)) end
    end
end, false, sgs.Skill_Limited, "@ofgu_niepan")
extension:addSkills(gu_record("#ofgu_niepan_reset", {sgs.SwappedPile}, function(self, event, room, p, data)
    -- SwappedPile is dispatched once per player: reset only the event player.
    if p:hasSkill("ofgu_niepan", true) then room:setPlayerMark(p, "@ofgu_niepan", 1) end
end))
of_gu_jiepangtong:addSkill(ofgu_xiangxing); of_gu_jiepangtong:addSkill(ofgu_lianhuan); of_gu_jiepangtong:addSkill(ofgu_niepan)
sgs.LoadTranslationTable {
    ["of_gu_jiepangtong"] = "界龐統[線下]", ["#of_gu_jiepangtong"] = "南洲冠冕",
    ["ofgu_xiangxing"] = "相形", [":ofgu_xiangxing"] = "锁定技，其他角色视为拥有“英姿”“闭月”。",
    ["ofgu_lianhuan"] = "連環", [":ofgu_lianhuan"] = "出牌阶段限X次，你可以将一张牌当【铁锁连环】使用，结算后两名目标随机均分手牌（无法均分的手牌交给你，X为洗牌的次数+1）。",
    ["ofgu_niepan"] = "涅槃", ["@ofgu_niepan"] = "涅槃",
    [":ofgu_niepan"] = "限定技，当你处于濒死状态时，你可以摸三张牌、回复至3点体力，然后对一名角色造成2点火焰伤害；洗牌时，此技能重置。",
    ["@ofgu_niepan-target"] = "涅槃：选择一名角色，对其造成2点火焰伤害",
}

-- SOURCE-C C3 (now authorized) and appended 追思; equipment restoration is
-- explicitly defined in SOURCE.md, despite the SOURCE-C OCR uncertainty.
of_gu_moucaopi = sgs.General(extension, "of_gu_moucaopi", "wei", 3)
local function gu_dead_candidates(room)
    local dead = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getAllPlayers()) do
        if q:isDead() and q:getMark("ofgu_zhuisi_taken") == 0 then dead:append(q) end
    end
    return dead
end
local function gu_general_skills(p, nonlord)
    local names = {}
    for _, general in ipairs({p:getGeneral(), p:getGeneral2()}) do
        for _, skill in sgs.qlist(general:getSkillList()) do
            if (not nonlord or not skill:isLordSkill()) and not table.contains(names, skill:objectName()) then
                table.insert(names, skill:objectName())
            end
        end
    end
    return names
end
local function gu_song(room, p, n)
    room:setPlayerMark(p, "&ofgu_song", math.min(9, p:getMark("&ofgu_song") + n))
end
ofgu_xingshangvs = gu_active("ofgu_xingshang", 2, 0, 0,
    function(self, targets, to, from) return #targets == 0 end, gu_one_feasible,
    function(self, room, source, targets)
        local to = targets[1]
        local choices = {"2"}
        if source:getMark("&ofgu_song") >= 3 then table.insert(choices, "3") end
        if to == source and source:getMark("&ofgu_song") >= 4 and not gu_dead_candidates(room):isEmpty() then table.insert(choices, "4") end
        local n = tonumber(room:askForChoice(source, "ofgu_xingshang", table.concat(choices, "+"), ToData(to)))
        room:removePlayerMark(source, "&ofgu_song", n)
        if n == 2 then
            if not to:faceUp() then to:turnOver() end
            if to:isChained() then room:setPlayerChained(to, false, source) end
            if to:isAlive() then to:drawCards(3, "ofgu_xingshang") end
        elseif n == 3 then
            room:recover(to, sgs.RecoverStruct("ofgu_xingshang", source))
            if to:isAlive() then
                if to:getMaxHp() < 9 then room:setPlayerProperty(to, "maxhp", sgs.QVariant(to:getMaxHp() + 1)) end
                local areas = {}
                for i = 0, 4 do if not to:hasEquipArea(i) then table.insert(areas, tostring(i)) end end
                if #areas > 0 then to:obtainEquipArea(tonumber(room:askForChoice(source, "ofgu_xingshang_equip", table.concat(areas, "+"), ToData(to)))) end
            end
        else
            local dead = room:askForPlayerChosen(source, gu_dead_candidates(room), "ofgu_zhuisi", "@ofgu_zhuisi", false, true)
            if not dead then return end
            room:setPlayerMark(dead, "ofgu_zhuisi_taken", 1)
            local changes = {}
            for _, name in ipairs(gu_general_skills(source, false)) do table.insert(changes, "-" .. name) end
            for _, name in ipairs(gu_general_skills(dead, true)) do table.insert(changes, name) end
            room:handleAcquireDetachSkills(source, table.concat(changes, "|"))
        end
    end, nil, function(p) return p:getMark("&ofgu_song") >= 2 end)
ofgu_xingshang = gu_trigger("ofgu_xingshang", {}, function() end)
ofgu_xingshang:setViewAsSkill(ofgu_xingshangvs)
extension:addSkills(gu_record("#ofgu_xingshang_record", {sgs.Damaged, sgs.Death, sgs.TurnStart, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.TurnStart or (event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive) then
        room:removeTag("ofgu_xingshang_first_damage"); return
    end
    if event == sgs.Damaged then
        if room:getTag("ofgu_xingshang_first_damage"):toBool() then return end
        room:setTag("ofgu_xingshang_first_damage", sgs.QVariant(true))
    elseif data:toDeath().who ~= p then return end
    for _, q in sgs.qlist(room:getAlivePlayers()) do if q:hasSkill("ofgu_xingshang") then gu_song(room, q, 2) end end
end))
ofgu_moufangzhu = gu_active("ofgu_moufangzhu", 1, 0, 0, gu_one, gu_one_feasible,
    function(self, room, source, targets)
        local to = targets[1]
        local choices = {"basic"}
        if source:getMark("&ofgu_song") >= 4 then table.insert(choices, "response") end
        if source:getMark("&ofgu_song") >= 6 then table.insert(choices, "trick"); table.insert(choices, "invalid") end
        if source:getMark("&ofgu_song") >= 8 then table.insert(choices, "equip"); table.insert(choices, "turnover") end
        local choice = room:askForChoice(source, "ofgu_moufangzhu", table.concat(choices, "+"), ToData(to))
        local costs = {basic = 2, response = 4, trick = 6, invalid = 6, equip = 8, turnover = 8}
        room:removePlayerMark(source, "&ofgu_song", costs[choice])
        local key = "ofgu_moufangzhu_" .. source:objectName()
        room:setPlayerMark(to, key, 1)
        room:setPlayerMark(to, key .. "_ready", 0)
        if choice == "turnover" then to:turnOver()
        elseif choice == "response" then room:setPlayerMark(to, key .. "_response", 1)
        elseif choice == "invalid" then
            room:setPlayerMark(to, key .. "_invalid", 1)
            -- Keep this accepted duration when the source dies: the engine clears
            -- records whose source is exactly the dead player's object name.
            room:addSkillInvalidity(to, "all", "ofgu_moufangzhu:" .. source:objectName(), "ofgu_moufangzhu")
        else
            local kinds = {basic = "BasicCard", trick = "TrickCard", equip = "EquipCard"}
            room:setPlayerCardLimitation(to, "use", "^" .. kinds[choice] .. "|.|.|hand", false, key)
        end
    end, nil, function(p) return p:getMark("&ofgu_song") >= 2 end)
extension:addSkills(gu_record("#ofgu_moufangzhu_record", {sgs.CardUsed, sgs.EventPhaseChanging, sgs.TurnStart, sgs.TurnedOver}, function(self, event, room, p, data)
    if event == sgs.CardUsed then
        local use = data:toCardUse()
        local names = use.no_respond_list
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            if q ~= use.from then
                for _, source in sgs.qlist(room:getAllPlayers()) do
                    if q:getMark("ofgu_moufangzhu_" .. source:objectName() .. "_response") > 0 then
                        if not table.contains(names, q:objectName()) then table.insert(names, q:objectName()) end
                        break
                    end
                end
            end
        end
        use.no_respond_list = names; data:setValue(use)
    elseif event == sgs.TurnStart then
        for _, source in sgs.qlist(room:getAllPlayers()) do
            local key = "ofgu_moufangzhu_" .. source:objectName()
            if p:getMark(key) > 0 then room:setPlayerMark(p, key .. "_ready", 1) end
        end
    elseif (event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive)
        or (event == sgs.TurnedOver and p:getPhase() == sgs.Player_NotActive) then
        -- A face-down skipped turn has no phases; TurnedOver ends that turn.
        for _, source in sgs.qlist(room:getAllPlayers()) do
            local key = "ofgu_moufangzhu_" .. source:objectName()
            if p:getMark(key) > 0 and p:getMark(key .. "_ready") > 0 then
                room:setPlayerMark(p, key, 0); room:setPlayerMark(p, key .. "_invalid", 0)
                room:setPlayerMark(p, key .. "_response", 0); room:setPlayerMark(p, key .. "_ready", 0)
                room:removePlayerCardLimitationByReason(p, key)
                room:removeSkillInvalidity(p, "all", "ofgu_moufangzhu:" .. source:objectName(), "ofgu_moufangzhu")
            end
        end
    end
end))
ofgu_songwei = gu_trigger("ofgu_songwei$", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Play or not owner:hasLordSkill("ofgu_songwei") then return end
    local n = 0
    for _, q in sgs.qlist(room:getAllPlayers()) do if q ~= owner and q:getKingdom() == "wei" then n = n + 1 end end
    gu_song(room, owner, 2 * n)
end, true)
of_gu_moucaopi:addSkill(ofgu_xingshang); of_gu_moucaopi:addSkill(ofgu_moufangzhu); of_gu_moucaopi:addSkill(ofgu_songwei)
sgs.LoadTranslationTable {
    ["of_gu_moucaopi"] = "謀曹丕[線下]", ["ofgu_song"] = "颂",
    ["ofgu_xingshang"] = "行殇",
    [":ofgu_xingshang"] = "有角色死亡后或每回合首次有角色受到伤害后，你获得2枚“颂”（至多9枚）。出牌阶段限两次，你可以弃以下数量的“颂”并令一名角色“祭奠”：2，复原武将牌，然后摸三张牌；3，回复1点体力、加1点体力上限（至多为9），恢复一个装备栏；4，若其为你，追思一名已死亡的角色。追思：获得该角色武将牌上所有非主公技，并失去自己原武将牌上所有技能；已被追思过的角色不可再追思。",
    ["ofgu_zhuisi"] = "追思", ["@ofgu_zhuisi"] = "追思：选择一名尚未被追思的已死亡角色",
    ["ofgu_xingshang_equip"] = "行殇：恢复一个装备栏",
    ["ofgu_moufangzhu"] = "放逐",
    [":ofgu_moufangzhu"] = "出牌阶段限一次，你可以弃以下数量的“颂”并对一名其他角色“流放”，直到其下回合结束：2，其不能使用非基本手牌；4，其不能响应除其外的角色的牌；6，其不能使用非锦囊手牌，或其技能失效；8，其不能使用非装备手牌，或翻面。",
    ["ofgu_moufangzhu:basic"] = "2颂：仅可使用基本手牌", ["ofgu_moufangzhu:response"] = "4颂：不能响应其他角色的牌",
    ["ofgu_moufangzhu:trick"] = "6颂：仅可使用锦囊手牌", ["ofgu_moufangzhu:invalid"] = "6颂：技能失效",
    ["ofgu_moufangzhu:equip"] = "8颂：仅可使用装备手牌", ["ofgu_moufangzhu:turnover"] = "8颂：翻面",
    ["ofgu_songwei"] = "颂威", [":ofgu_songwei"] = "主公技，锁定技，出牌阶段开始时，你获得2X枚“颂”（X为其他魏势力角色数和已死亡魏势力角色数之和）。",
}

-- GU 王者之战 (finaldebug wangzhan.md): 2020 2V2/3V3 exclusives, 2021 3V3 changes, 2024 修改将全文.
extension_wz = sgs.Package("ofl_wangzhan", sgs.Package_GeneralPack)
-- 己方/对方 follow the engine's 3v3 skills: in team modes a camp is the role initial
-- (lord/loyalist, rebel/renegade); in other modes 己方 is only oneself.
local function wz_team_mode(p)
    local mode = p:getGameMode()
    return mode:startsWith("06_") or mode:startsWith("04_") or mode == "08_defense"
end
local function wz_ally(a, b)
    if a:objectName() == b:objectName() then return true end
    return wz_team_mode(a) and a:getRole():sub(1, 1) == b:getRole():sub(1, 1)
end
local function wz_card_ids(card)
    if card:isVirtualCard() then return card:getSubcards() end
    local ids = sgs.IntList(); ids:append(card:getEffectiveId()); return ids
end

-- 2020 2V2 诸葛亮: 专属观星 (3 cards when only two are alive) + 空城.
ofwz20_zhugeliang = sgs.General(extension_wz, "ofwz20_zhugeliang", "shu", 3)
ofwz_guanxing = gu_trigger("ofwz_guanxing", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Start or not gu_invoke(owner, self:objectName()) then return end
    local n = room:alivePlayerCount()
    n = n == 2 and 3 or math.min(n, 5)
    room:askForGuanxing(owner, room:getNCards(n))
end, false, sgs.Skill_Frequent)
ofwz20_zhugeliang:addSkill(ofwz_guanxing); ofwz20_zhugeliang:addSkill("kongcheng")

-- 2020 2V2 审配 (移动版 base, 2/3): 守邺 judges instead of 对策.
ofwz20_shenpei = sgs.General(extension_wz, "ofwz20_shenpei", "qun", 3, true, false, false, 2)
ofwz_shouye = gu_trigger("ofwz_shouye", {sgs.TargetConfirmed, sgs.CardFinished}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    local flag = "ofwz_shouye_" .. owner:objectName()
    if event == sgs.CardFinished then
        if not use.card or not use.card:hasFlag(flag) then return end
        room:setCardFlag(use.card, "-" .. flag)
        local ids = sgs.IntList()
        for _, id in sgs.qlist(wz_card_ids(use.card)) do
            if room:getCardPlace(id) == sgs.Player_DiscardPile then ids:append(id) end
        end
        if owner:isAlive() then gu_obtain(room, owner, ids, self:objectName()) end
        return
    end
    if p ~= owner or not use.card or use.card:getTypeId() == sgs.Card_TypeSkill or use.to:length() ~= 1 or not use.to:contains(owner)
        or owner:getMark("ofwz_shouye-Clear") > 0 or not gu_invoke(owner, self:objectName(), data) then return end
    room:setPlayerMark(owner, "ofwz_shouye-Clear", 1)
    local judge = sgs.JudgeStruct()
    judge.who = owner; judge.reason = self:objectName(); judge.pattern = ".|red"; judge.good = true
    room:judge(judge)
    if judge:isGood() then
        local list = use.nullified_list
        table.insert(list, owner:objectName())
        use.nullified_list = list
        data:setValue(use)
        room:setCardFlag(use.card, flag)
    end
end)
ofwz_liezhi = gu_trigger("ofwz_liezhi", {sgs.EventPhaseStart, sgs.Damaged}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.Damaged then
        if owner:getMark("&ofwz_liezhi_invalid") == 0 then
            room:setPlayerMark(owner, "&ofwz_liezhi_invalid", 1)
            room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        end
        return
    end
    if owner:getPhase() ~= sgs.Player_Start or owner:getMark("&ofwz_liezhi_invalid") > 0 then return end
    local candidates = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if owner:canDiscard(q, "hej") then candidates:append(q) end
    end
    if candidates:isEmpty() then return end
    local tos = room:askForPlayersChosen(owner, candidates, self:objectName(), 0, 2, "@ofwz_liezhi", true)
    for _, q in sgs.qlist(tos) do
        if owner:isDead() then return end
        if q:isAlive() and owner:canDiscard(q, "hej") then
            local id = room:askForCardChosen(owner, q, "hej", self:objectName(), false, sgs.Card_MethodDiscard)
            room:throwCard(id, self:objectName(), q, owner)
        end
    end
end)
-- The invalidity ends at the owner's next 结束阶段 even when the skill itself is gone.
extension_wz:addSkills(gu_record("#ofwz_liezhi_restore", {sgs.EventPhaseStart}, function(self, event, room, p, data)
    if p:getPhase() == sgs.Player_Finish and p:getMark("&ofwz_liezhi_invalid") > 0 then
        room:setPlayerMark(p, "&ofwz_liezhi_invalid", 0)
    end
end))
ofwz20_shenpei:addSkill(ofwz_shouye); ofwz20_shenpei:addSkill(ofwz_liezhi)

-- 2020 3V3 典韦: 强袭 each payment once per phase, never the same target twice.
ofwz20_dianwei = sgs.General(extension_wz, "ofwz20_dianwei", "wei", 4)
ofwz_qiangxiCard = sgs.CreateSkillCard {
    name = "ofwz_qiangxiCard",
    filter = function(self, targets, to, from)
        return #targets == 0 and to:objectName() ~= from:objectName()
            and to:getMark("ofwz_qiangxi_" .. from:objectName() .. "-PlayClear") == 0
            and from:inMyAttackRange(to, self:getSubcards())
    end,
    feasible = gu_one_feasible,
    on_use = function(self, room, source, targets)
        local to = targets[1]
        room:setPlayerMark(to, "ofwz_qiangxi_" .. source:objectName() .. "-PlayClear", 1)
        if self:subcardsLength() == 0 then
            room:setPlayerMark(source, "ofwz_qiangxi_hp-PlayClear", 1)
            room:loseHp(source, 1, true, source, "ofwz_qiangxi")
        else
            room:setPlayerMark(source, "ofwz_qiangxi_weapon-PlayClear", 1)
        end
        if to:isAlive() then room:damage(sgs.DamageStruct("ofwz_qiangxi", source, to)) end
    end,
}
ofwz_qiangxi = sgs.CreateViewAsSkillV2 {
    name = "ofwz_qiangxi",
    can_activate = function(self, request)
        local p = request:getInitiator()
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and (p:getMark("ofwz_qiangxi_hp-PlayClear") == 0 or p:getMark("ofwz_qiangxi_weapon-PlayClear") == 0)
    end,
    can_select_card = function(self, request, c)
        local p = request:getInitiator()
        return request:getSelectedCardIds():isEmpty() and p:getMark("ofwz_qiangxi_weapon-PlayClear") == 0
            and c:isKindOf("Weapon") and not p:isJilei(c)
    end,
    card_selection_feasible = function(self, request)
        local n = request:getSelectedCardIds():length()
        return n == 1 or (n == 0 and request:getInitiator():getMark("ofwz_qiangxi_hp-PlayClear") == 0)
    end,
    create_card = function(self, request)
        local c = ofwz_qiangxiCard:clone()
        c:addSubcards(request:getSelectedCardIds())
        c:setSkillName("ofwz_qiangxi")
        return c
    end,
}
ofwz20_dianwei:addSkill(ofwz_qiangxi)

-- 2020 3V3 徐晃: 断粮 range 2, unlimited against hands not smaller than yours; 截辎 = tenyearjiezi.
ofwz20_xuhuang = sgs.General(extension_wz, "ofwz20_xuhuang", "wei", 4)
ofwz_duanliang = sgs.CreateViewAsSkillV2 {
    name = "ofwz_duanliang",
    can_activate = function(self, request) return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY end,
    can_select_card = function(self, request, c)
        return request:getSelectedCardIds():isEmpty() and c:isBlack()
            and (c:isKindOf("BasicCard") or c:isKindOf("EquipCard")) and not request:getInitiator():isJilei(c)
    end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():length() == 1 end,
    create_card = function(self, request)
        local c = sgs.Sanguosha:cloneCard("supply_shortage", sgs.Card_NoSuit, 0)
        c:addSubcards(request:getSelectedCardIds()); c:setSkillName("ofwz_duanliang"); return c
    end,
}
ofwz_duanliang_mod = sgs.CreateTargetModSkillV2 {
    name = "#ofwz_duanliang_mod", pattern = "SupplyShortage", holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(self, ctx)
        local from, to = ctx:getPrimary(), ctx:getSecondary()
        if ctx:getModType() ~= sgs.TargetModSkill_DistanceLimit or not from or not from:hasSkill("ofwz_duanliang") then return false end
        if to and to:getHandcardNum() >= from:getHandcardNum() then return 999 end
        return 1
    end,
}
ofwz20_xuhuang:addSkill(ofwz_duanliang); ofwz20_xuhuang:addSkill(ofwz_duanliang_mod); ofwz20_xuhuang:addSkill("tenyearjiezi")
extension_wz:insertRelatedSkills("ofwz_duanliang", "#ofwz_duanliang_mod")

-- 2020 3V3 关羽: 武圣 + 忠义 (any number of red cards as 义).
ofwz20_guanyu = sgs.General(extension_wz, "ofwz20_guanyu", "shu", 4)
ofwz_zhongyivs = gu_active("ofwz_zhongyi", nil, 1, 999, function() return false end,
    function(self, targets) return #targets == 0 end,
    function(self, room, source, targets) source:addToPile("ofwz_yi", self) end,
    function(request, c) return c:isRed() end)
ofwz_zhongyi = gu_trigger("ofwz_zhongyi", {sgs.DamageCaused}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    local pile = owner:getPile("ofwz_yi")
    if pile:isEmpty() or not d.card or not d.card:isKindOf("Slash") or not d.from or not wz_ally(owner, d.from)
        or not gu_invoke(owner, self:objectName(), data) then return end
    local id = pile:first()
    if pile:length() > 1 then
        room:fillAG(pile, owner)
        id = room:askForAG(owner, pile, false, self:objectName())
        room:clearAG(owner)
    end
    room:throwCard(sgs.Sanguosha:getCard(id),
        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", self:objectName(), ""), nil)
    d.damage = d.damage + 1
    data:setValue(d)
end)
ofwz_zhongyi:setViewAsSkill(ofwz_zhongyivs)
ofwz20_guanyu:addSkill("wusheng"); ofwz20_guanyu:addSkill(ofwz_zhongyi)

-- 2020 3V3 黄权: 筹进 (any other player) + 忠谏. The damaging 己方 role draws.
local function wz_choujin(name, enemy_only, quota)
    return gu_trigger(name, {sgs.GameStart, sgs.Damage}, function(self, event, room, p, data, owner)
        local key = name .. "_" .. owner:objectName()
        if event == sgs.GameStart then
            if p ~= owner then return end
            local targets = sgs.SPlayerList()
            for _, q in sgs.qlist(room:getOtherPlayers(owner)) do
                if not enemy_only or not wz_ally(owner, q) then targets:append(q) end
            end
            if targets:isEmpty() then return end
            room:sendCompulsoryTriggerLog(owner, name, true)
            local to = room:askForPlayerChosen(owner, targets, name, "@" .. name .. "-choose", false, true)
            if to then room:setPlayerMark(to, key, 1); room:addPlayerMark(to, "@ofwz_choujin") end
            return
        end
        local d = data:toDamage()
        if p ~= d.from or not d.to or d.to:getMark(key) == 0 or not wz_ally(owner, d.from) or d.from:isDead() then return end
        if quota and owner:getMark(name .. "-Clear") >= quota then return end
        if quota then room:addPlayerMark(owner, name .. "-Clear") end
        room:sendCompulsoryTriggerLog(owner, name, true)
        d.from:drawCards(1, name)
    end, true)
end
ofwz20_huangquan = sgs.General(extension_wz, "ofwz20_huangquan", "shu", 3)
ofwz_choujin = wz_choujin("ofwz_choujin", false, nil)
ofwz_zhongjian = gu_active("ofwz_zhongjian", nil, 1, 1,
    function(self, targets, to, from) return gu_one(self, targets, to, from) and wz_ally(from, to) end, gu_one_feasible,
    function(self, room, source, targets)
        room:giveCard(source, targets[1], self, "ofwz_zhongjian")
        if source:isAlive() then source:drawCards(1, "ofwz_zhongjian") end
    end)
ofwz20_huangquan:addSkill(ofwz_choujin); ofwz20_huangquan:addSkill(ofwz_zhongjian)

-- 2020 3V3 吕布: 无双 + 战神 (回合开始时; 神武 instead of 神戟, no weapon discard).
ofwz20_lvbu = sgs.General(extension_wz, "ofwz20_lvbu", "qun", 4)
ofwz_zhanshen = sgs.CreateTriggerSkillV2 {
    name = "ofwz_zhanshen", frequency = sgs.Skill_Wake, events = {sgs.TurnStart}, waked_skills = "mashu,ofwz_shenwu",
    can_trigger = function(skill, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(skill:objectName()) and player:getMark(skill:objectName()) == 0 then
            return skill:objectName()
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local dead_ally = false
        for _, q in sgs.qlist(room:getAllPlayers(true)) do
            if q:isDead() and wz_ally(player, q) then dead_ally = true; break end
        end
        if not (player:isWounded() and dead_ally) and not player:canWake(skill:objectName()) then return false end
        room:notifySkillInvoked(player, skill:objectName())
        room:doSuperLightbox(player, skill:objectName())
        room:setPlayerMark(player, skill:objectName(), 1)
        if room:changeMaxHpForAwakenSkill(player, -1, skill:objectName()) then
            room:handleAcquireDetachSkills(player, "mashu|ofwz_shenwu")
        end
        return false
    end,
}
ofwz_shenwu = sgs.CreateTargetModSkillV2 {
    name = "ofwz_shenwu", pattern = "Slash", holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(self, ctx)
        local from = ctx:getPrimary()
        if not from or not from:hasSkill("ofwz_shenwu") then return false end
        if ctx:getModType() == sgs.TargetModSkill_Residue then return 1 end
        if ctx:getModType() == sgs.TargetModSkill_ExtraTarget then return 2 end
        return false
    end,
}
extension_wz:addSkills(ofwz_shenwu)
ofwz20_lvbu:addSkill("wushuang"); ofwz20_lvbu:addSkill(ofwz_zhanshen)

-- 2021 3V3 文聘: 镇卫 now also covers 文聘 himself.
ofwz21_wenpin = sgs.General(extension_wz, "ofwz21_wenpin", "wei", 4)
ofwz_zhenwei = sgs.CreateDistanceSkillV2 {
    name = "ofwz_zhenwei", frequency = sgs.Skill_Compulsory, holder_selector = sgs.CorrectSkill_AllHolders,
    correct_func = function(self, ctx)
        local from, to, holder = ctx:getPrimary(), ctx:getSecondary(), ctx:getHolder()
        if from and to and holder and not wz_ally(holder, from) and wz_ally(holder, to) then return 1 end
        return false
    end,
}
ofwz21_wenpin:addSkill(ofwz_zhenwei)

-- 2021 3V3 黄权: 筹进 picks an 对方 role, twice per turn; 忠谏 unchanged.
ofwz21_huangquan = sgs.General(extension_wz, "ofwz21_huangquan", "shu", 3)
ofwz_choujin21 = wz_choujin("ofwz_choujin21", true, 2)
ofwz21_huangquan:addSkill(ofwz_choujin21); ofwz21_huangquan:addSkill("ofwz_zhongjian")

-- 2021 3V3 吕布: 战神 becomes a locked skill, no 无双.
ofwz21_lvbu = sgs.General(extension_wz, "ofwz21_lvbu", "qun", 4)
ofwz_zhanshen21 = gu_trigger("ofwz_zhanshen21", {sgs.EventPhaseStart, sgs.DrawNCards, sgs.DamageCaused}, function(self, event, room, p, data, owner)
    if event == sgs.EventPhaseStart then
        if p ~= owner or p:getPhase() ~= sgs.Player_Start then return end
        local choices = {}
        for _, c in ipairs({"draw", "damage", "target"}) do
            if owner:getMark("&ofwz_zhanshen21+" .. c) == 0 then table.insert(choices, c) end
        end
        if #choices == 0 then return end
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        local choice = room:askForChoice(owner, self:objectName(), table.concat(choices, "+"))
        room:setPlayerMark(owner, "&ofwz_zhanshen21+" .. choice, 1)
    elseif event == sgs.DrawNCards then
        local draw = data:toDraw()
        if p ~= owner or draw.reason ~= "draw_phase" or owner:getMark("&ofwz_zhanshen21+draw") == 0 then return end
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        draw.num = draw.num + 1
        data:setValue(draw)
    else
        local d = data:toDamage()
        if d.from ~= owner or not d.card or not d.card:isKindOf("Slash") or owner:getMark("&ofwz_zhanshen21+damage") == 0 then return end
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        d.damage = d.damage + 1
        data:setValue(d)
    end
end, true)
ofwz_zhanshen21_mod = sgs.CreateTargetModSkillV2 {
    name = "#ofwz_zhanshen21_mod", pattern = "Slash", holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(self, ctx)
        local from = ctx:getPrimary()
        if ctx:getModType() == sgs.TargetModSkill_ExtraTarget and from and from:hasSkill("ofwz_zhanshen21")
            and from:getMark("&ofwz_zhanshen21+target") > 0 then return 1 end
        return false
    end,
}
ofwz21_lvbu:addSkill(ofwz_zhanshen21); ofwz21_lvbu:addSkill(ofwz_zhanshen21_mod)
extension_wz:insertRelatedSkills("ofwz_zhanshen21", "#ofwz_zhanshen21_mod")

-- 2024 界甄姬: 洛神 keeps each black judge card and adds 1 to this turn's hand limit; 倾国.
ofwz24_zhenji = sgs.General(extension_wz, "ofwz24_zhenji", "wei", 3, false)
ofwz_luoshen = gu_trigger("ofwz_luoshen", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Start then return end
    while owner:isAlive() and gu_invoke(owner, self:objectName()) do
        local judge = sgs.JudgeStruct()
        judge.who = owner; judge.reason = self:objectName(); judge.pattern = ".|black"; judge.good = true
        room:judge(judge)
        if not judge:isGood() then break end
        if room:getCardPlace(judge.card:getEffectiveId()) == sgs.Player_DiscardPile then
            room:obtainCard(owner, judge.card, self:objectName(), true)
        end
        room:addPlayerMark(owner, "&ofwz_luoshen-Clear")
    end
end, false, sgs.Skill_Frequent)
ofwz_luoshen_max = sgs.CreateMaxCardsSkillV2 {
    name = "#ofwz_luoshen_max", holder_selector = sgs.CorrectSkill_System, gate = { "mark:&ofwz_luoshen-Clear" },
    correct_func = function(self, ctx)
        local p = ctx:getPrimary()
        if p and p:getMark("&ofwz_luoshen-Clear") > 0 then return p:getMark("&ofwz_luoshen-Clear") end
        return false
    end,
}
ofwz24_zhenji:addSkill(ofwz_luoshen); ofwz24_zhenji:addSkill(ofwz_luoshen_max); ofwz24_zhenji:addSkill("qingguo")
extension_wz:insertRelatedSkills("ofwz_luoshen", "#ofwz_luoshen_max")

sgs.LoadTranslationTable {
    ["ofl_wangzhan"] = "王者之战",
    ["ofwz20_zhugeliang"] = "诸葛亮[王战2V2]", ["&ofwz20_zhugeliang"] = "诸葛亮",
    ["ofwz_guanxing"] = "观星",
    [":ofwz_guanxing"] = "准备阶段，你可以观看牌堆顶的X张牌，然后以任意顺序置于牌堆顶或牌堆底（X为存活角色数且至多为5；若存活角色数为2，X为3）。",
    ["ofwz20_shenpei"] = "审配[王战2V2]", ["&ofwz20_shenpei"] = "审配",
    ["ofwz_shouye"] = "守邺",
    [":ofwz_shouye"] = "每回合限一次，当你成为牌的唯一目标后，你可以进行判定：若结果为红色，此牌对你无效，且此牌结算完成后你获得之。",
    ["ofwz_liezhi"] = "烈直",
    [":ofwz_liezhi"] = "准备阶段，你可以依次弃置至多两名角色区域内的各一张牌；当你受到伤害后，此技能失效直到你的下个结束阶段。",
    ["@ofwz_liezhi"] = "烈直：你可以选择至多两名角色，依次弃置其区域内的一张牌",
    ["ofwz_liezhi_invalid"] = "烈直失效",
    ["ofwz20_dianwei"] = "典韦[王战3V3]", ["&ofwz20_dianwei"] = "典韦",
    ["ofwz_qiangxi"] = "强袭",
    [":ofwz_qiangxi"] = "出牌阶段各限一次，你可以失去1点体力或弃置一张武器牌，然后对你攻击范围内的一名角色造成1点伤害（同一阶段不能指定相同的角色）。",
    ["ofwz20_xuhuang"] = "徐晃[王战3V3]", ["&ofwz20_xuhuang"] = "徐晃",
    ["ofwz_duanliang"] = "断粮",
    [":ofwz_duanliang"] = "你可以将一张黑色基本牌或黑色装备牌当【兵粮寸断】使用；你使用【兵粮寸断】的距离限制为2；你对手牌数不小于你的角色使用【兵粮寸断】无距离限制。",
    ["ofwz20_guanyu"] = "关羽[王战3V3]", ["&ofwz20_guanyu"] = "关羽",
    ["ofwz_zhongyi"] = "忠义", ["ofwz_yi"] = "义",
    [":ofwz_zhongyi"] = "出牌阶段，你可以将任意张红色牌置于武将牌上，称为“义”；己方角色使用的【杀】造成伤害时，你可以移去一张“义”，令此伤害+1。",
    ["ofwz20_huangquan"] = "黄权[王战3V3]", ["&ofwz20_huangquan"] = "黄权",
    ["ofwz_choujin"] = "筹进", ["@ofwz_choujin"] = "筹进",
    [":ofwz_choujin"] = "游戏开始时，你选择一名其他角色；己方角色对其造成伤害后，该己方角色摸一张牌。",
    ["@ofwz_choujin-choose"] = "筹进：选择一名其他角色",
    ["ofwz_zhongjian"] = "忠谏",
    [":ofwz_zhongjian"] = "出牌阶段，你可以交给一名其他己方角色一张牌，然后你摸一张牌。",
    ["ofwz20_lvbu"] = "吕布[王战3V3]", ["&ofwz20_lvbu"] = "吕布",
    ["ofwz_zhanshen"] = "战神",
    [":ofwz_zhanshen"] = "觉醒技，回合开始时，若你已受伤且有己方角色已死亡，你减1点体力上限，然后获得“马术”和“神武”。",
    ["ofwz_shenwu"] = "神武",
    [":ofwz_shenwu"] = "你使用【杀】的次数上限+1；你使用【杀】可以额外选择两个目标。",
    ["ofwz21_wenpin"] = "文聘[王战2021]", ["&ofwz21_wenpin"] = "文聘",
    ["ofwz_zhenwei"] = "镇卫",
    [":ofwz_zhenwei"] = "锁定技，对方角色计算与己方角色（含你）的距离+1。",
    ["ofwz21_huangquan"] = "黄权[王战2021]", ["&ofwz21_huangquan"] = "黄权",
    ["ofwz_choujin21"] = "筹进",
    [":ofwz_choujin21"] = "游戏开始时，你选择一名对方角色；每回合限两次，己方角色对其造成伤害后，该己方角色摸一张牌。",
    ["@ofwz_choujin21-choose"] = "筹进：选择一名对方角色",
    ["ofwz21_lvbu"] = "吕布[王战2021]", ["&ofwz21_lvbu"] = "吕布",
    ["ofwz_zhanshen21"] = "战神",
    [":ofwz_zhanshen21"] = "锁定技，准备阶段，你获得一项未选择过的效果：1.摸牌阶段多摸一张牌；2.你使用【杀】造成的伤害+1；3.你使用【杀】可以额外选择一个目标。",
    ["ofwz_zhanshen21:draw"] = "摸牌阶段多摸一张牌", ["ofwz_zhanshen21:damage"] = "【杀】伤害+1",
    ["ofwz_zhanshen21:target"] = "【杀】可多选一个目标",
    ["ofwz24_zhenji"] = "界甄姬[王战2024]", ["&ofwz24_zhenji"] = "甄姬",
    ["ofwz_luoshen"] = "洛神",
    [":ofwz_luoshen"] = "准备阶段，你可以进行判定：若结果为黑色，你获得此牌且本回合手牌上限+1，然后你可以重复此流程。",
}

-- GU 欢乐三国杀 (finaldebug huanle.md): 欢乐杀专属, SP, 斗地主活动原创, 欢乐杀修改 and 欢乐杀界限突破.
-- Kept in offline.lua because the engine only loads the extension files its config lists;
-- the package AI is ai/huanle-ai.lua (loaded by package name).
extension_hl = sgs.Package("huanle", sgs.Package_GeneralPack)
sgs.LoadTranslationTable { ["huanle"] = "欢乐三国杀" }

-- ==================== c201
do
-- c201: huanle.md L302-470, 欢乐杀修改 / 欢乐杀界限突破 variants (丁原 .. 关索).
-- Derived skills that another skill grants (叛弑 from 慈孝; 武圣/咆哮 from 父魂; 武圣/当先/制蛮 from 征南)
-- are registered through extension_hl:addSkills and are not printed on the general.

local function c201_list(room, pred)
    local list = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if pred(q) then list:append(q) end
    end
    return list
end
-- A random card from the draw pile (and, when discard_too, the discard pile) matching pred.
local function c201_fetch(room, owner, pred, discard_too, skill)
    local pool = {}
    for _, id in sgs.qlist(room:getDrawPile()) do
        if pred(sgs.Sanguosha:getCard(id)) then table.insert(pool, id) end
    end
    if discard_too then
        for _, id in sgs.qlist(room:getDiscardPile()) do
            if pred(sgs.Sanguosha:getCard(id)) then table.insert(pool, id) end
        end
    end
    if #pool == 0 then return end
    room:obtainCard(owner, pool[math.random(1, #pool)], skill, true)
end
local function c201_card_ids(card)
    if card:isVirtualCard() then return card:getSubcards() end
    local ids = sgs.IntList(); ids:append(card:getEffectiveId()); return ids
end
local function c201_pd(p)
    local d = sgs.QVariant()
    d:setValue(p)
    return d
end

-- ======================================================================= 丁原
hlxg_dingyuan = sgs.General(extension_hl, "hlxg_dingyuan", "qun", 4)
local function c201_has_panshi(room, p)
    if p:hasSkill("hlxg_panshi") then return true end
    if p:getMark("@hlxg_yizi") == 0 then return false end
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if q:hasSkill("hlxg_cixiao") then return true end
    end
    return false
end
hlxg_cixiao = gu_trigger("hlxg_cixiao", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Start then return end
    local cands = c201_list(room, function(q) return q ~= owner and q:getMark("@hlxg_yizi") == 0 end)
    if cands:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, cands, self:objectName(), "@hlxg_cixiao", true, true)
    if not to then return end
    room:addPlayerMark(to, "@hlxg_yizi")
    if owner:isKongcheng() or to:isDead() then return end
    local give = room:askForExchange(owner, self:objectName(), 1, 1, false, "@hlxg_cixiao-give:" .. to:objectName(), true)
    if not give then return end
    room:giveCard(owner, to, give, self:objectName())
    if to:isDead() then return end
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    slash:setSkillName("_hlxg_cixiao")
    local victims = c201_list(room, function(q)
        return q ~= to and to:inMyAttackRange(q) and to:canSlash(q, slash, false)
    end)
    if victims:isEmpty() then slash:deleteLater(); return end
    local victim = room:askForPlayerChosen(owner, victims, "hlxg_cixiao_slash", "@hlxg_cixiao-slash:" .. to:objectName(), false)
    if victim then room:useCard(sgs.CardUseStruct(slash, to, victim), false) end
    slash:deleteLater()
end)
-- 叛弑: held natively or through a 义子 mark while someone holds 慈孝.
hlxg_panshi = sgs.CreateRuleSkillV2 {
    name = "hlxg_panshi", events = {sgs.EventPhaseStart, sgs.DamageCaused, sgs.Damage}, global = true,
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not (player and player:isAlive() and c201_has_panshi(room, player)) then return false end
        if event == sgs.EventPhaseStart then
            if player:getPhase() ~= sgs.Player_Start or player:isKongcheng() then return false end
            for _, q in sgs.qlist(room:getOtherPlayers(player)) do
                if q:hasSkill("hlxg_cixiao") then return self:objectName(), player end
            end
            return false
        end
        local d = data:toDamage()
        if d.from == player and d.to and d.to ~= player and d.to:hasSkill("hlxg_cixiao") and d.card
            and d.card:isKindOf("Slash") and player:getPhase() == sgs.Player_Play then
            return self:objectName(), player
        end
        return false
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        room:sendCompulsoryTriggerLog(player, self:objectName(), true)
        if event == sgs.EventPhaseStart then
            local cands = c201_list(room, function(q) return q ~= player and q:hasSkill("hlxg_cixiao") end)
            if cands:isEmpty() or player:isKongcheng() then return false end
            local to = room:askForPlayerChosen(player, cands, self:objectName(), "@hlxg_panshi", false)
            local give = room:askForExchange(player, self:objectName(), 1, 1, false, "@hlxg_panshi-give:" .. to:objectName())
            if give then room:giveCard(player, to, give, self:objectName()) end
        elseif event == sgs.DamageCaused then
            local d = data:toDamage()
            d.damage = d.damage + 1
            data:setValue(d)
        else
            room:setPlayerMark(player, "@hlxg_yizi", 0)
            room:setPlayerFlag(player, "Global_PlayPhaseTerminated")
        end
        return false
    end,
}
extension_hl:addSkills(hlxg_panshi)
hlxg_dingyuan:addSkill("xianshuai"); hlxg_dingyuan:addSkill(hlxg_cixiao)
hlxg_dingyuan:addRelateSkill("hlxg_panshi")

-- ======================================================================= 丁奉
hlxg_fenxun_dist = sgs.CreateDistanceSkillV2 {
    name = "#hlxg_fenxun_dist", holder_selector = sgs.CorrectSkill_System,
    fixed_func = function(skill, ctx)
        local from, to = ctx:getPrimary(), ctx:getSecondary()
        if from and to and from:getMark("hlxg_fenxun_" .. to:objectName() .. "-Clear") > 0 then return 1 end
        return nil
    end,
}
extension_hl:addSkills(hlxg_fenxun_dist)
local function c201_fenxun(name)
    return gu_active(name, 1, 0, 0, gu_one, gu_one_feasible, function(self, room, source, targets)
        room:setPlayerMark(source, "hlxg_fenxun_" .. targets[1]:objectName() .. "-Clear", 1)
    end)
end
hlxg_dingfeng = sgs.General(extension_hl, "hlxg_dingfeng", "wu", 4)
hlxg_fenxun = c201_fenxun("hlxg_fenxun")
hlxg_dingfeng:addSkill(hlxg_fenxun); hlxg_dingfeng:addSkill("duanbing")

hljx_dingfeng = sgs.General(extension_hl, "hljx_dingfeng", "wu", 4)
hljx_fenxun = gu_trigger("hljx_fenxun", {sgs.DamageCaused, sgs.Damage, sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if event == sgs.EventPhaseStart then
        local x = owner:getMark("hljx_fenxun_dmg-Clear")
        if p ~= owner or p:getPhase() ~= sgs.Player_Finish or x <= 0 then return end
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        owner:drawCards(x, self:objectName())
        return
    end
    local d = data:toDamage()
    if d.from ~= owner or p ~= owner or not d.to then return end
    if event == sgs.DamageCaused then
        room:setPlayerFlag(d.to, owner:distanceTo(d.to) <= 1 and "hljx_fenxun_near" or "-hljx_fenxun_near")
    elseif d.to:hasFlag("hljx_fenxun_near") then
        room:setPlayerFlag(d.to, "-hljx_fenxun_near")
        room:addPlayerMark(owner, "hljx_fenxun_dmg-Clear", d.damage)
    end
end)
hljx_fenxun:setViewAsSkill(c201_fenxun("hljx_fenxun"))
-- First sentence: one extra Slash target at distance 1 (same rule as the engine's 短兵 TargetMod).
hljx_duanbing_tm = sgs.CreateTargetModSkillV2 {
    name = "#hljx_duanbing_tm", pattern = "Slash", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        local from, to = ctx:getPrimary(), ctx:getSecondary()
        if ctx:getModType() == sgs.TargetModSkill_ExtraTarget and from and to and from:hasSkill("hljx_duanbing")
            and from:distanceTo(to) == 1 then return 1 end
        return false
    end,
}
hljx_duanbing = gu_trigger("hljx_duanbing", {sgs.TargetSpecified}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if p ~= owner or use.from ~= owner or not use.card or not use.card:isKindOf("Slash") then return end
    if owner:getMark("hljx_duanbing_first-Clear") > 0 then return end
    local near = false
    for _, t in sgs.qlist(use.to) do
        if owner:distanceTo(t) == 1 then near = true end
    end
    if not near then return end
    room:setPlayerMark(owner, "hljx_duanbing_first-Clear", 1)
    room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
    local key = "Jink_" .. use.card:toString()
    local old, new = owner:getTag(key):toIntList(), sgs.IntList()
    for i = 0, use.to:length() - 1 do
        local v = i < old:length() and old:at(i) or 1
        if v == 1 and owner:distanceTo(use.to:at(i)) == 1 then v = 2 end
        new:append(v)
    end
    local qv = sgs.QVariant(); qv:setValue(new)
    owner:setTag(key, qv)
end)
hljx_dingfeng:addSkill(hljx_fenxun); hljx_dingfeng:addSkill(hljx_duanbing); hljx_dingfeng:addSkill(hljx_duanbing_tm)
extension_hl:insertRelatedSkills("hljx_duanbing", "#hljx_duanbing_tm")
hlxg_dingfeng:addSkill("#hlxg_fenxun_dist"); hljx_dingfeng:addSkill("#hlxg_fenxun_dist")
extension_hl:insertRelatedSkills("hlxg_fenxun", "#hlxg_fenxun_dist")
extension_hl:insertRelatedSkills("hljx_fenxun", "#hlxg_fenxun_dist")

-- ======================================================================= 严夫人
hlxg_yanfuren = sgs.General(extension_hl, "hlxg_yanfuren", "qun", 3, false)
hlxg_nifu = gu_trigger("hlxg_nifu", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p:getPhase() ~= sgs.Player_Finish or owner:getHandcardNum() >= 3 then return end
    room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
    owner:drawCards(3 - owner:getHandcardNum(), self:objectName())
end, true)
hlxg_channivs = gu_active("hlxg_channi", 1, 1, 999, gu_one, gu_one_feasible, function(self, room, source, targets)
    local to = targets[1]
    local n = self:subcardsLength()
    room:giveCard(source, to, self, "hlxg_channi")
    if to:isDead() or to:isKongcheng() then return end
    local cards = room:askForExchange(to, "hlxg_channi", n, 1, false, "@hlxg_channi-duel:::" .. n, true)
    if not cards then return end
    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
    duel:addSubcards(cards:getSubcards())
    duel:setSkillName("hlxg_channi")
    local victims = c201_list(room, function(q) return q ~= to and not to:isProhibited(q, duel) end)
    if victims:isEmpty() or to:isCardLimited(duel, sgs.Card_MethodUse) then duel:deleteLater(); return end
    local victim = room:askForPlayerChosen(to, victims, "hlxg_channi_duel", "@hlxg_channi-target", true)
    if not victim then duel:deleteLater(); return end
    room:setCardFlag(duel, "hlxg_channi_by_" .. to:objectName())
    room:setCardFlag(duel, "hlxg_channi_src_" .. source:objectName())
    room:useCard(sgs.CardUseStruct(duel, to, victim), true)
end, function(request, c) return not c:isEquipped() end)
hlxg_channi = gu_trigger("hlxg_channi", {sgs.Damage, sgs.DamageInflicted}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if not d.card or not d.card:isKindOf("Duel") then return end
    if event == sgs.Damage then
        if not d.from or p ~= d.from or d.from:isDead() or not d.card:hasFlag("hlxg_channi_by_" .. d.from:objectName())
            or not d.card:hasFlag("hlxg_channi_src_" .. owner:objectName()) then return end
        d.from:drawCards(d.card:subcardsLength(), self:objectName())
        return
    end
    if not d.to or p ~= d.to or not d.card:hasFlag("hlxg_channi_by_" .. d.to:objectName()) or not d.card:hasFlag("hlxg_channi_src_" .. owner:objectName())
        or not gu_invoke(owner, "hlxg_channi_prevent", c201_pd(d.to)) then return end
    owner:throwAllHandCards(self:objectName())
    return true
end)
hlxg_channi:setViewAsSkill(hlxg_channivs)
hlxg_yanfuren:addSkill(hlxg_nifu); hlxg_yanfuren:addSkill(hlxg_channi)

-- ======================================================================= 严畯
hlxg_yanjun = sgs.General(extension_hl, "hlxg_yanjun", "wu", 3)
local function c201_monotone(nums, up)
    for i = 2, #nums do
        if up and nums[i] <= nums[i - 1] then return false end
        if not up and nums[i] >= nums[i - 1] then return false end
    end
    return true
end
hlxg_guanchao = gu_trigger("hlxg_guanchao", {sgs.EventPhaseStart, sgs.CardUsed}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.EventPhaseStart then
        if owner:getPhase() ~= sgs.Player_Play then return end
        gu_setnames(owner, "hlxg_guanchao_nums", {})
        local choice = room:askForChoice(owner, self:objectName(), "up+down+cancel")
        if choice == "cancel" then return end
        room:notifySkillInvoked(owner, self:objectName())
        room:setPlayerMark(owner, "&hlxg_guanchao_" .. choice .. "-PlayClear", 1)
        return
    end
    local use = data:toCardUse()
    if use.from ~= owner or not use.card or use.card:getTypeId() == sgs.Card_TypeSkill or owner:getPhase() ~= sgs.Player_Play then return end
    local names = gu_names(owner, "hlxg_guanchao_nums")
    table.insert(names, tostring(use.card:getNumber()))
    gu_setnames(owner, "hlxg_guanchao_nums", names)
    local nums = {}
    for _, s in ipairs(names) do table.insert(nums, tonumber(s) or 0) end
    if (owner:getMark("&hlxg_guanchao_up-PlayClear") > 0 and c201_monotone(nums, true))
        or (owner:getMark("&hlxg_guanchao_down-PlayClear") > 0 and c201_monotone(nums, false)) then
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        owner:drawCards(1, self:objectName())
    end
end)
hlxg_guanchao_mod = sgs.CreateTargetModSkillV2 {
    name = "#hlxg_guanchao_mod", pattern = "Slash", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        local from = ctx:getPrimary()
        if ctx:getModType() == sgs.TargetModSkill_Residue and from and from:getMark("&hlxg_guanchao_up-PlayClear") > 0 then return 1 end
        return false
    end,
}
hlxg_guanchao_dist = sgs.CreateDistanceSkillV2 {
    name = "#hlxg_guanchao_dist", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        local from = ctx:getPrimary()
        if from and from:getMark("&hlxg_guanchao_down-PlayClear") > 0 then return -1 end
        return false
    end,
}
hlxg_xunxian = gu_trigger("hlxg_xunxian", {sgs.CardsMoveOneTime}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getMark("hlxg_xunxian-Clear") > 0 then return end
    local move = data:toMoveOneTime()
    if move.to_place ~= sgs.Player_DiscardPile or move.reason.m_playerId ~= owner:objectName() then return end
    local basic = move.reason.m_reason & sgs.CardMoveReason_S_MASK_BASIC_REASON
    if basic ~= sgs.CardMoveReason_S_REASON_USE and basic ~= sgs.CardMoveReason_S_REASON_RESPONSE then return end
    local card = move.reason.m_extraData:toCard()
    if card and card:getTypeId() == sgs.Card_TypeSkill then return end
    local ids = sgs.IntList()
    for _, id in sgs.qlist(move.card_ids) do
        if room:getCardPlace(id) == sgs.Player_DiscardPile then ids:append(id) end
    end
    if ids:isEmpty() then return end
    local cname = card and card:objectName() or sgs.Sanguosha:getCard(ids:first()):objectName()
    local to = room:askForPlayerChosen(owner, room:getOtherPlayers(owner), self:objectName(), "@hlxg_xunxian:::" .. cname, true, true)
    if not to then return end
    room:setPlayerMark(owner, "hlxg_xunxian-Clear", 1)
    gu_obtain(room, to, ids, self:objectName())
end)
hlxg_yanjun:addSkill(hlxg_guanchao); hlxg_yanjun:addSkill(hlxg_guanchao_mod); hlxg_yanjun:addSkill(hlxg_guanchao_dist)
hlxg_yanjun:addSkill(hlxg_xunxian)
extension_hl:insertRelatedSkills("hlxg_guanchao", "#hlxg_guanchao_mod")
extension_hl:insertRelatedSkills("hlxg_guanchao", "#hlxg_guanchao_dist")

-- ======================================================================= 严白虎
hlxg_yanbaihu = sgs.General(extension_hl, "hlxg_yanbaihu", "qun", 4)
hlxg_jili_yanbaihu = gu_trigger("hlxg_jili_yanbaihu", {sgs.TargetConfirming, sgs.Damaged, sgs.CardFinished}, function(self, event, room, p, data, owner)
    local flag = "hlxg_jili_" .. owner:objectName()
    if event == sgs.CardFinished then
        local use = data:toCardUse()
        if use.card and use.card:hasFlag(flag) then room:setCardFlag(use.card, "-" .. flag) end
        return
    end
    if event == sgs.Damaged then
        local d = data:toDamage()
        if p ~= owner or not d.card or not d.card:hasFlag(flag) then return end
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        owner:drawCards(1, self:objectName())
        return
    end
    local use = data:toCardUse()
    if p == owner or not use.card or not use.card:isRed() or not use.to:contains(p) then return end
    if not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return end
    if not use.from or use.from == owner or use.to:contains(owner) or p:distanceTo(owner) ~= 1 then return end
    if use.from:isProhibited(owner, use.card) then return end
    room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
    room:setCardFlag(use.card, flag)
    use.to:append(owner)
    room:sortByActionOrder(use.to)
    data:setValue(use)
end, true)
hlxg_zhidao = gu_trigger("hlxg_zhidao", {sgs.Damage}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if p ~= owner or d.from ~= owner or not d.to or d.to == owner or owner:getPhase() ~= sgs.Player_Play
        or owner:getMark("hlxg_zhidao-PlayClear") > 0 then return end
    room:setPlayerMark(owner, "hlxg_zhidao-PlayClear", 1)
    room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
    local to = d.to
    for _, flag in ipairs({"h", "e", "j"}) do
        if owner:isDead() or to:isDead() then break end
        local has = (flag == "h" and not to:isKongcheng()) or (flag == "e" and to:hasEquip())
            or (flag == "j" and not to:getJudgingArea():isEmpty())
        if has then
            local id = room:askForCardChosen(owner, to, flag, self:objectName())
            room:obtainCard(owner, id, false)
        end
    end
    room:setPlayerMark(owner, "hlxg_zhidao_" .. to:objectName() .. "-Clear", 1)
end, true)
hlxg_zhidao_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#hlxg_zhidao_prohibit", holder_selector = sgs.CorrectSkill_System,
    is_prohibited = function(skill, ctx)
        local from, to, card = ctx:getFrom(), ctx:getTo(), ctx:getCard()
        return from ~= nil and to ~= nil and card ~= nil and card:getTypeId() ~= sgs.Card_TypeSkill
            and from:getMark("hlxg_zhidao_" .. to:objectName() .. "-Clear") > 0
    end,
}
hlxg_yanbaihu:addSkill(hlxg_jili_yanbaihu); hlxg_yanbaihu:addSkill(hlxg_zhidao); hlxg_yanbaihu:addSkill(hlxg_zhidao_prohibit)
extension_hl:insertRelatedSkills("hlxg_zhidao", "#hlxg_zhidao_prohibit")

-- ======================================================================= 严颜
hlxg_yanyan = sgs.General(extension_hl, "hlxg_yanyan", "shu", 4)
hlxg_juzhan = gu_trigger("hlxg_juzhan", {sgs.TargetConfirmed, sgs.TargetSpecified}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if p ~= owner or not use.card or not use.card:isKindOf("Slash") then return end
    if event == sgs.TargetConfirmed then
        local from = use.from
        if not from or from == owner or not use.to:contains(owner) or from:isDead()
            or not gu_invoke(owner, "hlxg_juzhan_draw", c201_pd(from)) then return end
        owner:drawCards(1, self:objectName())
        if from:isAlive() then from:drawCards(1, self:objectName()) end
        room:setPlayerMark(from, "hlxg_juzhan_to_" .. owner:objectName() .. "-Clear", 1)
        return
    end
    if use.from ~= owner then return end
    for _, t in sgs.qlist(use.to) do
        if owner:isDead() then return end
        if t ~= owner and t:isAlive() and not t:isNude() and gu_invoke(owner, "hlxg_juzhan_get", c201_pd(t)) then
            local id = room:askForCardChosen(owner, t, "he", self:objectName())
            room:obtainCard(owner, id, false)
            room:setPlayerMark(owner, "hlxg_juzhan_red_" .. t:objectName() .. "-Clear", 1)
        end
    end
end)
hlxg_juzhan_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#hlxg_juzhan_prohibit", holder_selector = sgs.CorrectSkill_System,
    is_prohibited = function(skill, ctx)
        local from, to, card = ctx:getFrom(), ctx:getTo(), ctx:getCard()
        if not from or not to or not card or card:getTypeId() == sgs.Card_TypeSkill then return false end
        if from:getMark("hlxg_juzhan_to_" .. to:objectName() .. "-Clear") > 0 then return true end
        return card:isKindOf("Slash") and card:isRed() and from:getMark("hlxg_juzhan_red_" .. to:objectName() .. "-Clear") > 0
    end,
}
hlxg_yanyan:addSkill(hlxg_juzhan); hlxg_yanyan:addSkill(hlxg_juzhan_prohibit)
extension_hl:insertRelatedSkills("hlxg_juzhan", "#hlxg_juzhan_prohibit")

-- ======================================================================= 乐进
hlxg_lejin = sgs.General(extension_hl, "hlxg_lejin", "wei", 4)
hlxg_xiaoguo = gu_trigger("hlxg_xiaoguo", {sgs.EventPhaseStart, sgs.DamageCaused}, function(self, event, room, p, data, owner)
    local draw_key, dmg_key = "&hlxg_xiaoguo_draw+#" .. owner:objectName(), "&hlxg_xiaoguo_dmg+#" .. owner:objectName()
    if event == sgs.DamageCaused then
        local d = data:toDamage()
        if not d.from or not d.to or p ~= d.from then return end
        if d.to == owner and d.from:getMark(draw_key) > 0 then
            room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
            owner:drawCards(1, self:objectName())
        elseif d.from == owner and d.to:getMark(dmg_key) > 0 and d.card and d.card:isKindOf("Slash") and not d.chain then
            room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
            d.damage = d.damage + 1
            data:setValue(d)
        end
        return
    end
    if p == owner or p:getPhase() ~= sgs.Player_Finish then return end
    -- The previous choice lasts until this player's next 结束阶段.
    room:setPlayerMark(p, draw_key, 0); room:setPlayerMark(p, dmg_key, 0)
    if owner:isNude() then return end
    local c = room:askForDiscard(owner, self:objectName(), 1, 1, true, true, "@hlxg_xiaoguo:" .. p:objectName())
    if not c or p:isDead() then return end
    local choices = {}
    for _, e in sgs.qlist(p:getCards("he")) do
        if e:isKindOf("EquipCard") and not p:isJilei(e) then table.insert(choices, "equip"); break end
    end
    table.insert(choices, "damage")
    local choice = room:askForChoice(p, self:objectName(), table.concat(choices, "+"), c201_pd(owner))
    if choice == "equip" then
        room:askForDiscard(p, self:objectName(), 1, 1, false, true, "@hlxg_xiaoguo-equip:" .. owner:objectName(), "EquipCard")
        if owner:isAlive() then owner:drawCards(1, self:objectName()) end
        room:setPlayerMark(p, draw_key, 1)
    else
        room:damage(sgs.DamageStruct(self:objectName(), owner, p))
        if p:isAlive() then room:setPlayerMark(p, dmg_key, 1) end
    end
end)
hlxg_lejin:addSkill(hlxg_xiaoguo)

-- ======================================================================= 于吉
hlxg_yuji = sgs.General(extension_hl, "hlxg_yuji", "qun", 3)
hlxg_guhuo = gu_trigger("hlxg_guhuo", {sgs.Damage, sgs.CardFinished, sgs.EventPhaseStart, sgs.EventPhaseChanging}, function(self, event, room, p, data, owner)
    if event == sgs.EventPhaseStart or event == sgs.EventPhaseChanging then
        if event == sgs.EventPhaseStart and p:getPhase() ~= sgs.Player_Finish then return end
        if event == sgs.EventPhaseChanging and data:toPhaseChange().to ~= sgs.Player_NotActive then return end
        local pile = owner:getPile("hlxg_guhuo")
        if pile:isEmpty() then return end
        gu_obtain(room, owner, pile, self:objectName())
        return
    end
    if event == sgs.Damage then
        local d = data:toDamage()
        if d.from == owner and p == owner and d.card then room:setCardFlag(d.card, "hlxg_guhuo_hit") end
        return
    end
    local use = data:toCardUse()
    if p ~= owner or use.from ~= owner or not use.card then return end
    if not (use.card:isKindOf("Slash") or (use.card:isKindOf("TrickCard") and use.card:isDamageCard())) then return end
    local hit = use.card:hasFlag("hlxg_guhuo_hit")
    if hit then room:setCardFlag(use.card, "-hlxg_guhuo_hit") end
    if not hit then
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        local ids = sgs.IntList()
        for _, id in sgs.qlist(c201_card_ids(use.card)) do
            local place = room:getCardPlace(id)
            if place == sgs.Player_DiscardPile or place == sgs.Player_PlaceTable then ids:append(id) end
        end
        if not ids:isEmpty() then owner:addToPile("hlxg_guhuo", ids, true) end
        owner:drawCards(1, self:objectName())
    elseif owner:getMark("hlxg_guhuo_draw-Clear") == 0 then
        room:setPlayerMark(owner, "hlxg_guhuo_draw-Clear", 1)
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        owner:drawCards(1, self:objectName())
    end
end, true)
hlxg_yuji:addSkill(hlxg_guhuo)

-- ======================================================================= 于禁
hlxg_yujin = sgs.General(extension_hl, "hlxg_yujin", "wei", 4)
hlxg_yizhong = gu_trigger("hlxg_yizhong", {sgs.CardEffected}, function(self, event, room, p, data, owner)
    local effect = data:toCardEffect()
    if p ~= owner or effect.to ~= owner or not effect.card or not effect.card:isKindOf("Slash")
        or effect.card:getSuit() ~= sgs.Card_Club or owner:hasEquip() then return end
    room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
    return true
end, true)
hlxg_zhenjun = gu_trigger("hlxg_zhenjun", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or (p:getPhase() ~= sgs.Player_Start and p:getPhase() ~= sgs.Player_Finish) then return end
    local cands = c201_list(room, function(q) return owner:canDiscard(q, "he") end)
    if cands:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, cands, self:objectName(), "@hlxg_zhenjun", true, true)
    if not to then return end
    local x = math.max(1, to:getHandcardNum() - to:getHp())
    x = math.min(x, to:getCardCount(true))
    local ids = room:askForCardsChosen(owner, to, "he", self:objectName(), x, x, false, sgs.Card_MethodDiscard, sgs.IntList(), false)
    if ids:isEmpty() then return end
    local equip = false
    for _, id in sgs.qlist(ids) do
        if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then equip = true end
    end
    room:throwCard(ids, self:objectName(), to, owner)
    if equip or owner:isDead() then return end
    local choices = {}
    if owner:canDiscard(owner, "he") then table.insert(choices, "discard") end
    if to:isAlive() then table.insert(choices, "draw") end
    if #choices == 0 then return end
    local choice = room:askForChoice(owner, self:objectName(), table.concat(choices, "+"), c201_pd(to))
    if choice == "discard" then
        room:askForDiscard(owner, self:objectName(), 1, 1, false, true)
    else
        to:drawCards(ids:length(), self:objectName())
    end
end)
hlxg_yujin:addSkill(hlxg_yizhong); hlxg_yujin:addSkill(hlxg_zhenjun)

hlxg_yujin2 = sgs.General(extension_hl, "hlxg_yujin2", "wei", 4)
hlxg_xiayuan = gu_trigger("hlxg_xiayuan", {sgs.EnterDying}, function(self, event, room, p, data, owner)
    if p == owner or owner:getMark("hlxg_xiayuan_lun") > 0 or not owner:canDiscard(owner, "he") then return end
    local c = room:askForDiscard(owner, self:objectName(), 2, 1, true, true, "@hlxg_xiayuan:" .. p:objectName())
    if not c then return end
    room:setPlayerMark(owner, "hlxg_xiayuan_lun", 1)
    local n = math.max(1, c:subcardsLength())
    if p:isAlive() then room:recover(p, sgs.RecoverStruct(self:objectName(), owner, n)) end
end)
hlxg_jieyue = gu_trigger("hlxg_jieyue", {sgs.EventPhaseStart, sgs.DamageInflicted}, function(self, event, room, p, data, owner)
    local key = "hlxg_jieyue_" .. owner:objectName() .. "-Clear"
    if event == sgs.DamageInflicted then
        local d = data:toDamage()
        if p ~= d.to or p:getMark(key) == 0 then return end
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        d.damage = d.damage + 1
        data:setValue(d)
        return
    end
    if p ~= owner or p:getPhase() ~= sgs.Player_Start then return end
    local to = room:askForPlayerChosen(owner, room:getOtherPlayers(owner), self:objectName(), "@hlxg_jieyue", true, true)
    if not to then return end
    to:drawCards(1, self:objectName())
    if to:isDead() or owner:isDead() then return end
    if owner:askCommandto(self:objectName(), to) then
        if owner:isAlive() then owner:drawCards(1, self:objectName()) end
    else
        if owner:isAlive() then owner:drawCards(3, self:objectName()) end
        if to:isAlive() then
            room:setPlayerMark(to, key, 1)
            room:setPlayerMark(to, "&hlxg_jieyue-Clear", 1)
        end
    end
end)
hlxg_yujin2:addSkill(hlxg_xiayuan); hlxg_yujin2:addSkill(hlxg_jieyue)

-- ======================================================================= 伏完
hlxg_fuwan = sgs.General(extension_hl, "hlxg_fuwan", "qun", 4)
local function c201_moukui_do(room, owner, t, what)
    if what == "draw" then
        owner:drawCards(1, "hlxg_moukui")
    elseif t:isAlive() and owner:canDiscard(t, "he") then
        local id = room:askForCardChosen(owner, t, "he", "hlxg_moukui", false, sgs.Card_MethodDiscard)
        room:throwCard(id, "hlxg_moukui", t, owner)
    end
end
-- 两项: when the Slash is nullified/offset for this pair, t discards one of owner's cards (once).
local function c201_moukui_both(room, owner, t, card)
    local flag = "hlxg_moukui_" .. owner:objectName() .. "_both_" .. t:objectName()
    if not card:hasFlag(flag) then return end
    room:setCardFlag(card, "-" .. flag)
    if owner:isAlive() and t:isAlive() and t:canDiscard(owner, "he") then
        room:sendCompulsoryTriggerLog(owner, "hlxg_moukui", true)
        local id = room:askForCardChosen(t, owner, "he", "hlxg_moukui", false, sgs.Card_MethodDiscard)
        room:throwCard(id, "hlxg_moukui", owner, t)
    end
end
hlxg_moukui = gu_trigger("hlxg_moukui", {sgs.TargetConfirmed, sgs.TargetSpecified, sgs.CardOffset, sgs.CardEffected, sgs.Damage, sgs.CardFinished},
function(self, event, room, p, data, owner)
    local base = "hlxg_moukui_" .. owner:objectName() .. "_"
    if event == sgs.TargetConfirmed or event == sgs.TargetSpecified then
        local use = data:toCardUse()
        if p ~= owner or not use.card or not use.card:isKindOf("Slash") then return end
        local others = {}
        if event == sgs.TargetConfirmed then
            if not use.from or use.from == owner or not use.to:contains(owner) then return end
            others = {use.from}
        else
            if use.from ~= owner then return end
            for _, t in sgs.qlist(use.to) do if t ~= owner then table.insert(others, t) end end
        end
        for _, t in ipairs(others) do
            if owner:isDead() then return end
            local choices = {"draw"}
            if t:isAlive() and owner:canDiscard(t, "he") then table.insert(choices, "discard"); table.insert(choices, "both") end
            table.insert(choices, "cancel")
            local choice = room:askForChoice(owner, self:objectName(), table.concat(choices, "+"), c201_pd(t))
            if choice ~= "cancel" then
                room:notifySkillInvoked(owner, self:objectName())
                if choice == "both" then
                    c201_moukui_do(room, owner, t, "draw")
                    c201_moukui_do(room, owner, t, "discard")
                else
                    c201_moukui_do(room, owner, t, choice)
                end
                room:setCardFlag(use.card, base .. choice .. "_" .. t:objectName())
            end
        end
    elseif event == sgs.CardOffset or event == sgs.CardEffected then
        local effect = data:toCardEffect()
        if not effect.card or not effect.card:isKindOf("Slash") or not effect.from or not effect.to then return end
        if event == sgs.CardEffected and (p ~= effect.to or not effect.nullified) then return end
        if event == sgs.CardOffset and p ~= effect.from then return end
        local t
        if effect.from == owner then t = effect.to elseif effect.to == owner then t = effect.from else return end
        c201_moukui_both(room, owner, t, effect.card)
    elseif event == sgs.Damage then
        local d = data:toDamage()
        if not d.card or not d.card:isKindOf("Slash") then return end
        for _, t in sgs.qlist(room:getAllPlayers(true)) do
            for _, what in ipairs({"draw", "discard"}) do
                local flag = base .. what .. "_" .. t:objectName()
                if d.card:hasFlag(flag) and owner:isAlive() then
                    room:setCardFlag(d.card, "-" .. flag)
                    room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
                    c201_moukui_do(room, owner, t, what)
                end
            end
        end
    else
        local use = data:toCardUse()
        if not use.card or not use.card:isKindOf("Slash") then return end
        -- Targets whose effect was skipped through the use's nullified list (无效) never reach CardEffected.
        local nl = use.nullified_list or {}
        for _, t in sgs.qlist(use.to) do
            if table.contains(nl, "_ALL_TARGETS") or table.contains(nl, t:objectName()) then
                if use.from == owner then c201_moukui_both(room, owner, t, use.card)
                elseif t == owner and use.from then c201_moukui_both(room, owner, use.from, use.card) end
            end
        end
        for _, t in sgs.qlist(room:getAllPlayers(true)) do
            for _, what in ipairs({"draw", "discard", "both"}) do
                local flag = base .. what .. "_" .. t:objectName()
                if use.card:hasFlag(flag) then room:setCardFlag(use.card, "-" .. flag) end
            end
        end
    end
end)
hlxg_fuwan:addSkill(hlxg_moukui)

-- ======================================================================= 伏皇后
hlxg_fuhuanghou = sgs.General(extension_hl, "hlxg_fuhuanghou", "qun", 3, false)
hlxg_zhuikong = gu_trigger("hlxg_zhuikong", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p == owner or p:getPhase() ~= sgs.Player_Start or not owner:canPindian(p)
        or not gu_invoke(owner, self:objectName(), c201_pd(p)) then return end
    if owner:pindian(p, self:objectName()) then
        if p:isAlive() then room:setPlayerMark(p, "&hlxg_zhuikong_self-Clear", 1) end
    elseif p:isAlive() then
        room:setPlayerMark(p, "hlxg_zhuikong_" .. owner:objectName() .. "-Clear", 1)
    end
end)
hlxg_zhuikong_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#hlxg_zhuikong_prohibit", holder_selector = sgs.CorrectSkill_System,
    is_prohibited = function(skill, ctx)
        local from, to, card = ctx:getFrom(), ctx:getTo(), ctx:getCard()
        return from ~= nil and to ~= nil and card ~= nil and card:getTypeId() ~= sgs.Card_TypeSkill
            and from:getMark("&hlxg_zhuikong_self-Clear") > 0 and from:objectName() ~= to:objectName()
    end,
}
hlxg_zhuikong_dist = sgs.CreateDistanceSkillV2 {
    name = "#hlxg_zhuikong_dist", holder_selector = sgs.CorrectSkill_System,
    fixed_func = function(skill, ctx)
        local from, to = ctx:getPrimary(), ctx:getSecondary()
        if from and to and from:getMark("hlxg_zhuikong_" .. to:objectName() .. "-Clear") > 0 then return 1 end
        return nil
    end,
}
hlxg_qiuyuan = gu_trigger("hlxg_qiuyuan", {sgs.TargetConfirming}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if p ~= owner or not use.card or not use.card:isKindOf("Slash") or not use.to:contains(owner) then return end
    local cands = c201_list(room, function(q) return q ~= owner and q ~= use.from end)
    if cands:isEmpty() then return end
    local tos = room:askForPlayersChosen(owner, cands, self:objectName(), 0, 3, "@hlxg_qiuyuan", true)
    for _, t in sgs.qlist(tos) do
        if t:isAlive() then
            local jink = room:askForCard(t, "jink", "@hlxg_qiuyuan-give:" .. owner:objectName(), data, sgs.Card_MethodNone)
            if jink and owner:isAlive() then
                room:giveCard(t, owner, jink, self:objectName(), true)
            elseif not jink then
                if use.from and not room:isProhibited(use.from, t, use.card) and not use.to:contains(t) then
                    use.to:append(t)
                    room:sortByActionOrder(use.to)
                    data:setValue(use)
                end
                if t:canDiscard(t, "he") then room:askForDiscard(t, self:objectName(), 1, 1, false, true) end
            end
        end
    end
end)
hlxg_fuhuanghou:addSkill(hlxg_zhuikong); hlxg_fuhuanghou:addSkill(hlxg_zhuikong_prohibit); hlxg_fuhuanghou:addSkill(hlxg_zhuikong_dist)
hlxg_fuhuanghou:addSkill(hlxg_qiuyuan)
extension_hl:insertRelatedSkills("hlxg_zhuikong", "#hlxg_zhuikong_prohibit")
extension_hl:insertRelatedSkills("hlxg_zhuikong", "#hlxg_zhuikong_dist")

-- ======================================================================= 何太后
hlxg_hetaihou = sgs.General(extension_hl, "hlxg_hetaihou", "qun", 3, false)
hlxg_qiluan = gu_trigger("hlxg_qiluan", {sgs.EnterDying, sgs.Death}, function(self, event, room, p, data, owner)
    if event == sgs.EnterDying then
        if gu_invoke(owner, self:objectName(), c201_pd(p)) then owner:drawCards(1, self:objectName()) end
        return
    end
    local death = data:toDeath()
    if not death.damage or death.damage.from ~= owner or p == owner then return end
    room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
    owner:drawCards(2, self:objectName())
end)
hlxg_zhendu = gu_trigger("hlxg_zhendu", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p:getPhase() ~= sgs.Player_Play or not owner:canDiscard(owner, "he") then return end
    local c = room:askForDiscard(owner, self:objectName(), 1, 1, true, true, "@hlxg_zhendu:" .. p:objectName())
    if not c or p:isDead() then return end
    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
    ana:setSkillName("_hlxg_zhendu")
    if not p:isCardLimited(ana, sgs.Card_MethodUse) and not p:isProhibited(p, ana) then
        room:useCard(sgs.CardUseStruct(ana, p, p), true)
    end
    ana:deleteLater()
    if p ~= owner and p:isAlive() then
        room:damage(sgs.DamageStruct(self:objectName(), owner, p))
        if p:isAlive() then room:setPlayerMark(p, "&hlxg_zhendu-Clear", 1) end
    end
end)
hlxg_zhendu_dist = sgs.CreateDistanceSkillV2 {
    name = "#hlxg_zhendu_dist", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        local from = ctx:getPrimary()
        if from and from:getMark("&hlxg_zhendu-Clear") > 0 then return 1 end
        return false
    end,
}
hlxg_hetaihou:addSkill(hlxg_qiluan); hlxg_hetaihou:addSkill(hlxg_zhendu); hlxg_hetaihou:addSkill(hlxg_zhendu_dist)
extension_hl:insertRelatedSkills("hlxg_zhendu", "#hlxg_zhendu_dist")

-- ======================================================================= 兀突骨
hlxg_wutugu = sgs.General(extension_hl, "hlxg_wutugu", "qun", 15)
-- 悍勇 = tenyearhanyong (same text); 燃殇 shares its "&rsran" mark.
hlxg_ranshang = gu_trigger("hlxg_ranshang", {sgs.Damaged, sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.Damaged then
        local d = data:toDamage()
        if d.nature ~= sgs.DamageStruct_Fire or d.damage <= 0 then return end
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        owner:gainMark("&rsran", d.damage)
        return
    end
    if owner:getPhase() ~= sgs.Player_Finish then return end
    local x = owner:getMark("&rsran")
    if x <= 0 then return end
    room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
    room:loseHp(owner, x, true, owner, self:objectName())
    if owner:isAlive() and x > 1 then
        room:loseMaxHp(owner, 2, self:objectName())
        if owner:isAlive() then owner:drawCards(x, self:objectName()) end
    end
end, true)
hlxg_wutugu:addSkill("tenyearhanyong"); hlxg_wutugu:addSkill(hlxg_ranshang)

-- ======================================================================= 全琮
hlxg_quancong = sgs.General(extension_hl, "hlxg_quancong", "wu", 4)
local function c201_yaoming(room, owner)
    local choices = {}
    for i = 1, 3 do
        if owner:getMark("hlxg_yaoming_" .. i .. "-Clear") < 2 then
            if i ~= 1 or not c201_list(room, function(q) return q ~= owner and owner:canDiscard(q, "h") end):isEmpty() then
                table.insert(choices, "opt" .. i)
            end
        end
    end
    if #choices == 0 then return end
    table.insert(choices, "cancel")
    local choice = room:askForChoice(owner, "hlxg_yaoming", table.concat(choices, "+"))
    if choice == "cancel" then return end
    local i = tonumber(choice:sub(4))
    local cands = i == 1 and c201_list(room, function(q) return q ~= owner and owner:canDiscard(q, "h") end) or room:getAlivePlayers()
    local to = room:askForPlayerChosen(owner, cands, "hlxg_yaoming_" .. i, "@hlxg_yaoming-" .. i, true, true)
    if not to then return end
    room:addPlayerMark(owner, "hlxg_yaoming_" .. i .. "-Clear")
    room:setPlayerMark(owner, "hlxg_yaoming_used-Clear", 1)
    if i == 1 then
        local id = room:askForCardChosen(owner, to, "h", "hlxg_yaoming", false, sgs.Card_MethodDiscard)
        room:throwCard(id, "hlxg_yaoming", to, owner)
    elseif i == 2 then
        to:drawCards(1, "hlxg_yaoming")
    else
        to:drawCards(2, "hlxg_yaoming")
        if to:isAlive() then room:askForDiscard(to, "hlxg_yaoming", 2, 2, false, true) end
    end
end
hlxg_yaoming = gu_trigger("hlxg_yaoming", {sgs.Damage, sgs.Damaged, sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.EventPhaseStart and (owner:getPhase() ~= sgs.Player_Finish or owner:getMark("hlxg_yaoming_used-Clear") > 0) then return end
    c201_yaoming(room, owner)
end)
hlxg_quancong:addSkill(hlxg_yaoming)

-- ======================================================================= 公孙渊
local function c201_huaiyi_take(room, source, x)
    if x <= 0 or source:isDead() then return end
    local cands = c201_list(room, function(q) return q ~= source and not q:isNude() end)
    if cands:isEmpty() then return end
    local tos = room:askForPlayersChosen(source, cands, "hlxg_huaiyi", 0, x, "@hlxg_huaiyi:::" .. x, true)
    for _, q in sgs.qlist(tos) do
        if source:isDead() then return end
        if q:isAlive() and not q:isNude() then
            local id = room:askForCardChosen(source, q, "he", "hlxg_huaiyi")
            room:obtainCard(source, id, false)
        end
    end
end
local function c201_color_ids(p, color)
    local ids = sgs.IntList()
    for _, c in sgs.qlist(p:getHandcards()) do
        if (color == "red" and c:isRed()) or (color == "black" and c:isBlack()) then ids:append(c:getEffectiveId()) end
    end
    return ids
end
hlxg_gongsunyuan = sgs.General(extension_hl, "hlxg_gongsunyuan", "qun", 4)
hlxg_huaiyi = gu_active("hlxg_huaiyi", 1, 0, 0, function() return false end, function(self, targets) return #targets == 0 end,
function(self, room, source, targets)
    room:showAllCards(source)
    local red, black = c201_color_ids(source, "red"), c201_color_ids(source, "black")
    if red:isEmpty() or black:isEmpty() then return end
    local color = room:askForChoice(source, "hlxg_huaiyi", "red+black")
    local ids = sgs.IntList()
    for _, id in sgs.qlist(color == "red" and red or black) do
        if not source:isJilei(sgs.Sanguosha:getCard(id)) then ids:append(id) end
    end
    if ids:isEmpty() then return end
    gu_throw(room, source, ids, "hlxg_huaiyi")
    c201_huaiyi_take(room, source, ids:length())
end, nil, function(p) return not p:isKongcheng() end)
hlxg_gongsunyuan:addSkill(hlxg_huaiyi)

hljx_gongsunyuan = sgs.General(extension_hl, "hljx_gongsunyuan", "qun", 4)
hljx_huaiyi = gu_active("hljx_huaiyi", 1, 0, 0, function() return false end, function(self, targets) return #targets == 0 end,
function(self, room, source, targets)
    room:showAllCards(source)
    local colors = {}
    for _, color in ipairs({"red", "black"}) do
        if not c201_color_ids(source, color):isEmpty() then table.insert(colors, color) end
    end
    if #colors == 0 then return end
    local color = room:askForChoice(source, "hljx_huaiyi", table.concat(colors, "+"))
    local all = c201_color_ids(source, color)
    local c = room:askForDiscard(source, "hljx_huaiyi", all:length(), 0, true, false,
        "@hljx_huaiyi-discard:::" .. color, ".|" .. color .. "|.|hand")
    local x = 0
    if c then x = math.max(1, c:subcardsLength()) end
    if source:isDead() then return end
    local rest = c201_color_ids(source, color)
    if not rest:isEmpty() then room:recastCards(source, rest, "hljx_huaiyi") end
    c201_huaiyi_take(room, source, x)
end, nil, function(p) return not p:isKongcheng() end)
hljx_gongsunyuan:addSkill(hljx_huaiyi)

-- ======================================================================= 公孙瓒
hljx_gongsunzan = sgs.General(extension_hl, "hljx_gongsunzan", "qun", 4)
hljx_yicong = sgs.CreateDistanceSkillV2 {
    name = "hljx_yicong", frequency = sgs.Skill_Compulsory, holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        local from, to = ctx:getPrimary(), ctx:getSecondary()
        local n = 0
        if from and from:hasSkill("hljx_yicong") then n = n - from:getHp() end
        if to and to:hasSkill("hljx_yicong") then n = n + to:getLostHp() end
        if n ~= 0 then return n end
        return false
    end,
}
hljx_qiaomeng = gu_trigger("hljx_qiaomeng", {sgs.DamageCaused}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if p ~= owner or d.from ~= owner or not d.to or not d.card or not d.card:isKindOf("Slash") or d.to:isAllNude()
        or not gu_invoke(owner, self:objectName(), data) then return end
    local id = room:askForCardChosen(owner, d.to, "hej", self:objectName())
    room:obtainCard(owner, id, false)
    local c = sgs.Sanguosha:getCard(id)
    if c:isKindOf("OffensiveHorse") or c:isKindOf("DefensiveHorse") then
        d.damage = d.damage + 1
        data:setValue(d)
    end
end)
hljx_gongsunzan:addSkill(hljx_yicong); hljx_gongsunzan:addSkill(hljx_qiaomeng)

-- ======================================================================= 关兴张苞
hlxg_guanxingzhangbao = sgs.General(extension_hl, "hlxg_guanxingzhangbao", "shu", 4)
hlxg_tongxin = sgs.CreateAttackRangeSkillV2 {
    name = "hlxg_tongxin", frequency = sgs.Skill_Compulsory, holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(skill, ctx)
        local p = ctx:getPrimary()
        if p and p:hasSkill("hlxg_tongxin") then return 2 end
        return false
    end,
}
local function c201_wusheng(name, discard_too)
    return gu_trigger(name, {sgs.EventPhaseStart, sgs.DamageCaused}, function(self, event, room, p, data, owner)
        if p ~= owner then return end
        if event == sgs.EventPhaseStart then
            if owner:getPhase() ~= sgs.Player_RoundStart then return end
            room:sendCompulsoryTriggerLog(owner, name, true)
            c201_fetch(room, owner, function(c) return c:isKindOf("Slash") and c:isRed() end, discard_too, name)
            return
        end
        local d = data:toDamage()
        if d.from ~= owner or not d.card or not d.card:isKindOf("Slash") or not d.card:isRed() then return end
        room:sendCompulsoryTriggerLog(owner, name, true)
        d.damage = d.damage + 1
        data:setValue(d)
    end, true)
end
hlxg_wusheng_guanxingzhangbao = c201_wusheng("hlxg_wusheng_guanxingzhangbao", true)
hlxg_paoxiao_guanxingzhangbao = sgs.CreateTargetModSkillV2 {
    name = "hlxg_paoxiao_guanxingzhangbao", pattern = "Slash", frequency = sgs.Skill_Compulsory,
    holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(skill, ctx)
        local from = ctx:getPrimary()
        if not from or not from:hasSkill("hlxg_paoxiao_guanxingzhangbao") then return false end
        if ctx:getModType() == sgs.TargetModSkill_Residue then return 1000 end
        if ctx:getModType() == sgs.TargetModSkill_DistanceLimit and from:getPhase() == sgs.Player_Play
            and from:getMark("hlxg_paoxiao_used-PlayClear") > 0 then return 1000 end
        return false
    end,
}
hlxg_paoxiao_rec = gu_record("#hlxg_paoxiao_guanxingzhangbao_rec", {sgs.CardUsed}, function(self, event, room, p, data)
    local use = data:toCardUse()
    if use.from == p and use.card and use.card:isKindOf("Slash") and p:getPhase() == sgs.Player_Play then
        room:setPlayerMark(p, "hlxg_paoxiao_used-PlayClear", 1)
    end
end)
hlxg_fuhunvs = sgs.CreateViewAsSkillV2 {
    name = "hlxg_fuhun", response_or_use = true,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player or player:getHandcardNum() < 2 then return false end
        local reason = request:getReason()
        if reason == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return sgs.Slash_IsAvailable(player) end
        if reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE or reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
            local ok = sgs.Sanguosha:matchExpPattern(request:getPattern(), player, slash)
            slash:deleteLater()
            return ok
        end
        return false
    end,
    can_select_card = function(skill, request, c)
        return request:getSelectedCardIds():length() < 2 and not c:isEquipped()
    end,
    card_selection_feasible = function(skill, request) return request:getSelectedCardIds():length() == 2 end,
    create_card = function(skill, request)
        local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
        c:addSubcards(request:getSelectedCardIds())
        c:setSkillName("hlxg_fuhun")
        return c
    end,
}
hlxg_fuhun = gu_trigger("hlxg_fuhun", {sgs.Damage}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if p ~= owner or d.from ~= owner or not d.card or not d.card:isKindOf("Slash") then return end
    local skills = "hlxg_wusheng_guanxingzhangbao|hlxg_paoxiao_guanxingzhangbao"
    local stage = owner:getMark("hlxg_fuhun_stage-Clear")
    if stage == 1 then
        room:setPlayerMark(owner, "hlxg_fuhun_stage-Clear", 2)
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        owner:removeTag("OneTurnSkill_hlxg_fuhun")
        local gain = {}
        for _, s in ipairs(skills:split("|")) do
            if not owner:hasSkill(s, true) then table.insert(gain, s) end
        end
        if #gain > 0 then room:handleAcquireDetachSkills(owner, table.concat(gain, "|")) end
    elseif stage == 0 and owner:getPhase() == sgs.Player_Play and d.card:getSkillName() == "hlxg_fuhun" then
        room:setPlayerMark(owner, "hlxg_fuhun_stage-Clear", 1)
        room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
        room:acquireOneTurnSkills(owner, "hlxg_fuhun", skills)
    end
end)
hlxg_fuhun:setViewAsSkill(hlxg_fuhunvs)
extension_hl:addSkills(hlxg_wusheng_guanxingzhangbao); extension_hl:addSkills(hlxg_paoxiao_guanxingzhangbao)
extension_hl:addSkills(hlxg_paoxiao_rec)
extension_hl:insertRelatedSkills("hlxg_paoxiao_guanxingzhangbao", "#hlxg_paoxiao_guanxingzhangbao_rec")
hlxg_guanxingzhangbao:addSkill(hlxg_tongxin); hlxg_guanxingzhangbao:addSkill(hlxg_fuhun)
hlxg_guanxingzhangbao:addRelateSkill("hlxg_wusheng_guanxingzhangbao"); hlxg_guanxingzhangbao:addRelateSkill("hlxg_paoxiao_guanxingzhangbao")

-- ======================================================================= 关平
hlxg_guanping = sgs.General(extension_hl, "hlxg_guanping", "shu", 4)
hlxg_jiezhong = gu_trigger("hlxg_jiezhong", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Play or owner:getMark("@hlxg_jiezhong") == 0
        or not gu_invoke(owner, self:objectName()) then return end
    room:setPlayerMark(owner, "@hlxg_jiezhong", 0)
    room:doSuperLightbox(owner, self:objectName())
    local n = owner:getMaxHp() - owner:getHandcardNum()
    if n > 0 then owner:drawCards(n, self:objectName()) end
end, false, sgs.Skill_Limited, "@hlxg_jiezhong")
hlxg_longyin = gu_trigger("hlxg_longyin", {sgs.CardUsed}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from ~= p or not use.card or not use.card:isKindOf("Slash") or p:getPhase() ~= sgs.Player_Play
        or not owner:canDiscard(owner, "he") then return end
    local c = room:askForCard(owner, "..", "@hlxg_longyin:" .. p:objectName(), data, self:objectName())
    if not c then return end
    use.m_addHistory = false
    data:setValue(use)
    if owner:isDead() then return end
    if use.card:isRed() then owner:drawCards(1, self:objectName()) end
    if use.card:getSuit() == c:getSuit() and owner:hasSkill("hlxg_jiezhong", true) then
        room:setPlayerMark(owner, "@hlxg_jiezhong", 1)
    end
end)
hlxg_guanping:addSkill(hlxg_jiezhong); hlxg_guanping:addSkill(hlxg_longyin)

-- ======================================================================= 关索
hlxg_guansuo = sgs.General(extension_hl, "hlxg_guansuo", "shu", 4)
hlxg_wusheng_guansuo = c201_wusheng("hlxg_wusheng_guansuo", false)
hlxg_dangxian_guansuo = gu_trigger("hlxg_dangxian_guansuo", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_RoundStart then return end
    room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
    owner:insertPhase(sgs.Player_Play)
    c201_fetch(room, owner, function(c) return c:isKindOf("Slash") end, true, self:objectName())
end, true)
hlxg_zhengnan = gu_trigger("hlxg_zhengnan", {sgs.EnterDying}, function(self, event, room, p, data, owner)
    local key = "hlxg_zhengnan_" .. owner:objectName()
    if p:getMark(key) > 0 or not gu_invoke(owner, self:objectName(), c201_pd(p)) then return end
    room:setPlayerMark(p, key, 1)
    local bonus = p == owner and 1 or 0
    room:recover(owner, sgs.RecoverStruct(self:objectName(), owner, 1 + bonus))
    if owner:isDead() then return end
    local left = {}
    for _, s in ipairs({"hlxg_wusheng_guansuo", "hlxg_dangxian_guansuo", "olzhiman"}) do
        if not owner:hasSkill(s, true) then table.insert(left, s) end
    end
    if #left == 0 then
        owner:drawCards(3 + bonus, self:objectName())
        return
    end
    owner:drawCards(1 + bonus, self:objectName())
    if owner:isDead() then return end
    local choice = room:askForChoice(owner, self:objectName(), table.concat(left, "+"))
    room:handleAcquireDetachSkills(owner, choice)
end)
hlxg_xiefang_x = function(p)
    local n = p:isFemale() and 1 or 0
    for _, q in sgs.qlist(p:getAliveSiblings()) do if q:isFemale() then n = n + 1 end end
    return math.max(1, n)
end
hlxg_xiefang = sgs.CreateDistanceSkillV2 {
    name = "hlxg_xiefang", frequency = sgs.Skill_Compulsory, holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(skill, ctx)
        local from = ctx:getPrimary()
        if from and from:hasSkill("hlxg_xiefang") then return -hlxg_xiefang_x(from) end
        return false
    end,
}
hlxg_xiefang_max = sgs.CreateMaxCardsSkillV2 {
    name = "#hlxg_xiefang_max", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(skill, ctx)
        local p = ctx:getPrimary()
        if p and p:hasSkill("hlxg_xiefang") then return hlxg_xiefang_x(p) end
        return false
    end,
}
extension_hl:addSkills(hlxg_wusheng_guansuo); extension_hl:addSkills(hlxg_dangxian_guansuo)
hlxg_guansuo:addSkill(hlxg_zhengnan); hlxg_guansuo:addSkill(hlxg_xiefang); hlxg_guansuo:addSkill(hlxg_xiefang_max)
extension_hl:insertRelatedSkills("hlxg_xiefang", "#hlxg_xiefang_max")
hlxg_guansuo:addRelateSkill("hlxg_wusheng_guansuo"); hlxg_guansuo:addRelateSkill("hlxg_dangxian_guansuo")
hlxg_guansuo:addRelateSkill("olzhiman")

sgs.LoadTranslationTable {
    ["hlxg_dingyuan"] = "丁原[欢乐修改]", ["&hlxg_dingyuan"] = "丁原",
    ["hlxg_cixiao"] = "慈孝",
    [":hlxg_cixiao"] = "准备阶段，你可以令一名没有“义子”的其他角色获得“义子”，然后你可以将一张手牌交给其，令其视为对其攻击范围内你选择的一名其他角色使用一张【杀】。有“义子”的角色视为拥有〖叛弑〗。",
    ["@hlxg_yizi"] = "义子",
    ["@hlxg_cixiao"] = "慈孝：你可以令一名没有“义子”的其他角色获得“义子”",
    ["@hlxg_cixiao-give"] = "慈孝：你可以交给 %src 一张手牌，令其视为使用【杀】",
    ["hlxg_cixiao_slash"] = "慈孝",
    ["@hlxg_cixiao-slash"] = "慈孝：选择 %src 视为使用【杀】的目标",
    ["hlxg_panshi"] = "叛弑",
    [":hlxg_panshi"] = "锁定技，准备阶段，你将一张手牌交给拥有〖慈孝〗的角色；当你于出牌阶段内使用【杀】对其造成伤害时，此伤害+1且你于造成伤害后弃“义子”并结束出牌阶段。",
    ["@hlxg_panshi"] = "叛弑：选择一名拥有〖慈孝〗的角色",
    ["@hlxg_panshi-give"] = "叛弑：请交给 %src 一张手牌",

    ["hlxg_dingfeng"] = "丁奉[欢乐修改]", ["&hlxg_dingfeng"] = "丁奉",
    ["hlxg_fenxun"] = "奋迅",
    [":hlxg_fenxun"] = "出牌阶段限一次，你可以选择一名其他角色，然后本回合你计算与其的距离视为1。",
    ["hljx_dingfeng"] = "丁奉[欢乐界]", ["&hljx_dingfeng"] = "丁奉",
    ["hljx_fenxun"] = "奋迅",
    [":hljx_fenxun"] = "出牌阶段限一次，你可以选择一名其他角色，然后本回合你计算与其的距离视为1。结束阶段，你摸X张牌（X为本回合你对距离1以内的角色造成的伤害值）。",
    ["hljx_duanbing"] = "短兵",
    [":hljx_duanbing"] = "你使用【杀】可以多选择一名距离为1的角色为目标。你对距离为1的角色每回合使用首张【杀】需两张【闪】才能抵消。",

    ["hlxg_yanfuren"] = "严夫人[欢乐修改]", ["&hlxg_yanfuren"] = "严夫人",
    ["hlxg_nifu"] = "匿伏",
    [":hlxg_nifu"] = "锁定技，一名角色的结束阶段，你将手牌摸至三张。",
    ["hlxg_channi"] = "谗逆",
    [":hlxg_channi"] = "出牌阶段限一次，你可以交给一名其他角色任意张手牌，然后其可以将至多等量张手牌当一张【决斗】使用。其因此【决斗】：造成伤害后，其摸X张牌（X为其转化此【决斗】的牌数）；受到伤害时，你可以弃置所有手牌并防止此伤害。",
    ["@hlxg_channi-duel"] = "谗逆：你可以将至多 %arg 张手牌当【决斗】使用",
    ["hlxg_channi_duel"] = "谗逆",
    ["@hlxg_channi-target"] = "谗逆：选择此【决斗】的目标",
    ["hlxg_channi_prevent"] = "谗逆（弃置所有手牌并防止伤害）",

    ["hlxg_yanjun"] = "严畯[欢乐修改]", ["&hlxg_yanjun"] = "严畯",
    ["hlxg_guanchao"] = "观潮",
    [":hlxg_guanchao"] = "出牌阶段开始时，你可以选择一项直到此阶段结束：1.使用【杀】的次数上限+1，且当你使用牌时，若你此阶段使用过的所有牌的点数严格递增，你摸一张牌；2.计算与其他角色的距离-1，且当你使用牌时，若你此阶段使用过的所有牌的点数严格递减，你摸一张牌。",
    ["hlxg_guanchao:up"] = "【杀】次数+1，点数严格递增时摸牌",
    ["hlxg_guanchao:down"] = "距离-1，点数严格递减时摸牌",
    ["hlxg_guanchao:cancel"] = "不发动",
    ["hlxg_guanchao_up"] = "观潮递增", ["hlxg_guanchao_down"] = "观潮递减",
    ["hlxg_xunxian"] = "逊贤",
    [":hlxg_xunxian"] = "每回合限一次，当你使用或打出的牌置入弃牌堆时，你可以将之交给一名其他角色。",
    ["@hlxg_xunxian"] = "逊贤：你可以将【%arg】交给一名其他角色",

    ["hlxg_yanbaihu"] = "严白虎[欢乐修改]", ["&hlxg_yanbaihu"] = "严白虎",
    ["hlxg_jili_yanbaihu"] = "寄篱",
    [":hlxg_jili_yanbaihu"] = "锁定技，当其他角色成为红色基本牌或红色普通锦囊牌的目标时，若其与你的距离为1且你不是此牌的使用者或目标角色，你也成为此牌的目标；当你受到此牌造成的伤害后，你摸一张牌。",
    ["hlxg_zhidao"] = "雉盗",
    [":hlxg_zhidao"] = "锁定技，出牌阶段内限一次，当你对其他角色造成伤害后，你获得其每个区域里的各一张牌，然后你本回合使用牌不能指定其为目标。",

    ["hlxg_yanyan"] = "严颜[欢乐修改]", ["&hlxg_yanyan"] = "严颜",
    ["hlxg_juzhan"] = "拒战",
    [":hlxg_juzhan"] = "当你成为其他角色使用【杀】的目标后，你可以与其各摸一张牌，然后其本回合不能再对你使用牌。当你使用【杀】指定一名角色为目标后，你可以获得其一张牌，然后你本回合不能再对其使用红色【杀】。",
    ["hlxg_juzhan_draw"] = "拒战（与使用者各摸一张牌）",
    ["hlxg_juzhan_get"] = "拒战（获得目标一张牌）",

    ["hlxg_lejin"] = "乐进[欢乐修改]", ["&hlxg_lejin"] = "乐进",
    ["hlxg_xiaoguo"] = "骁果",
    [":hlxg_xiaoguo"] = "其他角色的结束阶段，你可以弃置一张牌，然后其选择一项：1.弃置一张装备牌，你摸一张牌，然后直到其下个结束阶段，当其对你造成伤害时，你摸一张牌；2.受到你造成的1点伤害，然后直到其下个结束阶段，你使用指定其为目标的【杀】造成的伤害+1。",
    ["@hlxg_xiaoguo"] = "骁果：你可以弃置一张牌，令 %src 选择一项",
    ["@hlxg_xiaoguo-equip"] = "骁果：请弃置一张装备牌，然后 %src 摸一张牌",
    ["hlxg_xiaoguo:equip"] = "弃置一张装备牌，其摸一张牌",
    ["hlxg_xiaoguo:damage"] = "受到其造成的1点伤害",
    ["hlxg_xiaoguo_draw"] = "骁果摸牌", ["hlxg_xiaoguo_dmg"] = "骁果增伤",

    ["hlxg_yuji"] = "于吉[欢乐修改]", ["&hlxg_yuji"] = "于吉",
    ["hlxg_guhuo"] = "蛊惑",
    [":hlxg_guhuo"] = "锁定技，当你使用【杀】或伤害类锦囊牌结算结束后，若此牌：未造成伤害，你将此牌移出游戏直到本回合的结束阶段，然后摸一张牌；造成伤害，你摸一张牌（每回合限一次）。",

    ["hlxg_yujin"] = "于禁[欢乐修改]", ["&hlxg_yujin"] = "于禁",
    ["hlxg_yizhong"] = "毅重",
    [":hlxg_yizhong"] = "锁定技，若你的装备区里没有牌，梅花【杀】对你无效。",
    ["hlxg_zhenjun"] = "镇军",
    [":hlxg_zhenjun"] = "准备阶段或结束阶段，你可以弃置一名角色X张牌（X为其手牌数减体力值且至少为1），然后若其中没有装备牌，你选择一项：1.弃置一张牌；2.令其摸等量的牌。",
    ["@hlxg_zhenjun"] = "镇军：你可以弃置一名角色X张牌（X为其手牌数减体力值且至少为1）",
    ["hlxg_zhenjun:discard"] = "你弃置一张牌", ["hlxg_zhenjun:draw"] = "令其摸等量的牌",

    ["hlxg_yujin2"] = "于禁[欢乐修改2]", ["&hlxg_yujin2"] = "于禁",
    ["hlxg_xiayuan"] = "狭援",
    [":hlxg_xiayuan"] = "每轮限一次，当其他角色进入濒死状态时，你可以弃置至多两张牌，令其回复等量的体力。",
    ["@hlxg_xiayuan"] = "狭援：你可以弃置至多两张牌，令 %src 回复等量的体力",
    ["hlxg_jieyue"] = "节钺",
    [":hlxg_jieyue"] = "准备阶段，你可以令一名其他角色摸一张牌，然后令其执行一次由你选择的“军令”。若其执行，你摸一张牌；若其不执行，你摸三张牌，本回合其受到的伤害+1。",
    ["@hlxg_jieyue"] = "节钺：你可以令一名其他角色摸一张牌，然后令其执行“军令”",

    ["hlxg_fuwan"] = "伏完[欢乐修改]", ["&hlxg_fuwan"] = "伏完",
    ["hlxg_moukui"] = "谋溃",
    [":hlxg_moukui"] = "当你成为一名角色使用【杀】的目标或使用【杀】指定一名角色为目标后，你可以选择任意项：1.摸一张牌；2.弃置其一张牌。若你选择：两项，当此【杀】被无效或抵消后，其弃置你一张牌；一项，若此【杀】造成伤害，你再执行一次此项。",
    ["hlxg_moukui:draw"] = "摸一张牌", ["hlxg_moukui:discard"] = "弃置其一张牌",
    ["hlxg_moukui:both"] = "两项", ["hlxg_moukui:cancel"] = "不发动",

    ["hlxg_fuhuanghou"] = "伏皇后[欢乐修改]", ["&hlxg_fuhuanghou"] = "伏皇后",
    ["hlxg_zhuikong"] = "惴恐",
    [":hlxg_zhuikong"] = "其他角色的准备阶段，你可以与其拼点，若你：赢，本回合其只能对自己使用牌；没赢，本回合其与你的距离视为1。",
    ["hlxg_zhuikong_self"] = "惴恐",
    ["hlxg_qiuyuan"] = "求援",
    [":hlxg_qiuyuan"] = "当你成为【杀】的目标时，你可以令除使用者外的至多三名其他角色需交给你一张【闪】，否则也成为此【杀】的目标并弃置一张牌。",
    ["@hlxg_qiuyuan"] = "求援：你可以选择至多三名其他角色",
    ["@hlxg_qiuyuan-give"] = "求援：请交给 %src 一张【闪】，否则你也成为此【杀】的目标并弃置一张牌",

    ["hlxg_hetaihou"] = "何太后[欢乐修改]", ["&hlxg_hetaihou"] = "何太后",
    ["hlxg_qiluan"] = "戚乱",
    [":hlxg_qiluan"] = "当一名角色进入濒死状态时，你可以摸一张牌；当你杀死一名角色后，你摸两张牌。",
    ["hlxg_zhendu"] = "鸩毒",
    [":hlxg_zhendu"] = "一名角色的出牌阶段开始时，你可以弃置一张牌。若如此做，其视为使用一张【酒】，然后若其不为你，你对其造成1点伤害且本回合其计算与除其外的角色的距离+1。",
    ["@hlxg_zhendu"] = "鸩毒：你可以弃置一张牌，令 %src 视为使用一张【酒】",

    ["hlxg_wutugu"] = "兀突骨[欢乐修改]", ["&hlxg_wutugu"] = "兀突骨",
    ["hlxg_ranshang"] = "燃殇",
    [":hlxg_ranshang"] = "锁定技，当你受到1点火焰伤害后，你获得1枚“燃”；结束阶段，你失去X点体力（X为“燃”的数量），然后若X大于1，你减2点体力上限并摸X张牌。",

    ["hlxg_quancong"] = "全琮[欢乐修改]", ["&hlxg_quancong"] = "全琮",
    ["hlxg_yaoming"] = "邀名",
    [":hlxg_yaoming"] = "每回合每项限两次，当你造成或受到伤害后，你可以选择一项：1.弃置一名其他角色一张手牌；2.令一名角色摸一张牌；3.令一名角色摸两张牌并弃置两张牌。结束阶段，若你本回合未发动过此技能，你可以发动此技能。",
    ["hlxg_yaoming:opt1"] = "弃置一名其他角色一张手牌", ["hlxg_yaoming:opt2"] = "令一名角色摸一张牌",
    ["hlxg_yaoming:opt3"] = "令一名角色摸两张牌并弃置两张牌", ["hlxg_yaoming:cancel"] = "不发动",
    ["hlxg_yaoming_1"] = "邀名", ["hlxg_yaoming_2"] = "邀名", ["hlxg_yaoming_3"] = "邀名",
    ["@hlxg_yaoming-1"] = "邀名：弃置一名其他角色一张手牌",
    ["@hlxg_yaoming-2"] = "邀名：令一名角色摸一张牌",
    ["@hlxg_yaoming-3"] = "邀名：令一名角色摸两张牌并弃置两张牌",

    ["hlxg_gongsunyuan"] = "公孙渊[欢乐修改]", ["&hlxg_gongsunyuan"] = "公孙渊",
    ["hlxg_huaiyi"] = "怀异",
    [":hlxg_huaiyi"] = "出牌阶段限一次，你可以展示所有手牌，若其中包含两种颜色，你弃置其中一种颜色的牌，然后获得至多X名其他角色的各一张牌（X为你以此法弃置的手牌数）。",
    ["hlxg_huaiyi:red"] = "红色", ["hlxg_huaiyi:black"] = "黑色",
    ["@hlxg_huaiyi"] = "怀异：你可以获得至多 %arg 名其他角色的各一张牌",
    ["hljx_gongsunyuan"] = "公孙渊[欢乐界]", ["&hljx_gongsunyuan"] = "公孙渊",
    ["hljx_huaiyi"] = "怀异",
    [":hljx_huaiyi"] = "出牌阶段限一次，你可以展示所有手牌，弃置任意张同颜色的手牌并重铸其余此颜色的手牌，然后获得至多X名其他角色的各一张牌（X为你以此法弃置的手牌数）。",
    ["hljx_huaiyi:red"] = "红色", ["hljx_huaiyi:black"] = "黑色",
    ["@hljx_huaiyi-discard"] = "怀异：弃置任意张 %arg 手牌，其余此颜色的手牌将被重铸",

    ["hljx_gongsunzan"] = "公孙瓒[欢乐界]", ["&hljx_gongsunzan"] = "公孙瓒",
    ["hljx_yicong"] = "义从",
    [":hljx_yicong"] = "锁定技，你计算与其他角色的距离-X（X为你的体力值）；其他角色计算与你的距离+Y（Y为你已损失的体力值）。",
    ["hljx_qiaomeng"] = "趫猛",
    [":hljx_qiaomeng"] = "当你使用【杀】对一名角色造成伤害时，你可以获得其区域里的一张牌。若此牌为坐骑牌，此伤害+1。",

    ["hlxg_guanxingzhangbao"] = "关兴张苞[欢乐修改]", ["&hlxg_guanxingzhangbao"] = "关兴张苞",
    ["hlxg_tongxin"] = "同心",
    [":hlxg_tongxin"] = "锁定技，你的攻击范围+2。",
    ["hlxg_paoxiao_guanxingzhangbao"] = "咆哮",
    [":hlxg_paoxiao_guanxingzhangbao"] = "锁定技，你使用【杀】无次数限制；若你于出牌阶段内使用过【杀】，你本阶段使用【杀】无距离限制。",
    ["hlxg_wusheng_guanxingzhangbao"] = "武圣",
    [":hlxg_wusheng_guanxingzhangbao"] = "锁定技，回合开始时，你从牌堆或弃牌堆中获得一张红色【杀】；你使用红色【杀】造成的伤害+1。",
    ["hlxg_fuhun"] = "父魂",
    [":hlxg_fuhun"] = "你可以将两张手牌当【杀】使用或打出；当你于出牌阶段内以此法造成伤害后，你本回合视为拥有〖武圣〗和〖咆哮〗，然后当你本回合再次使用【杀】造成伤害后，你永久获得这两个技能。",

    ["hlxg_guanping"] = "关平[欢乐修改]", ["&hlxg_guanping"] = "关平",
    ["hlxg_jiezhong"] = "竭忠", ["@hlxg_jiezhong"] = "竭忠",
    [":hlxg_jiezhong"] = "限定技，出牌阶段开始时，你可以将手牌摸至体力上限。",
    ["hlxg_longyin"] = "龙吟",
    [":hlxg_longyin"] = "当一名角色于其出牌阶段内使用【杀】时，你可以弃置一张牌，令此【杀】不计入次数，然后若此【杀】：为红色，你摸一张牌；与你弃置的牌花色相同，复原〖竭忠〗。",
    ["@hlxg_longyin"] = "龙吟：你可以弃置一张牌，令 %src 使用的【杀】不计入次数",

    ["hlxg_guansuo"] = "关索[欢乐修改]", ["&hlxg_guansuo"] = "关索",
    ["hlxg_dangxian_guansuo"] = "当先",
    [":hlxg_dangxian_guansuo"] = "锁定技，回合开始时，你执行一个额外的出牌阶段并从牌堆或弃牌堆中获得一张【杀】。",
    ["hlxg_zhengnan"] = "征南",
    [":hlxg_zhengnan"] = "每名角色限一次，当一名角色进入濒死状态时，你可以回复1点体力、摸一张牌并获得下列技能中的一个：〖武圣〗、〖当先〗和〖制蛮〗（若技能均已获得改为摸三张牌）。若进入濒死状态的角色为你，则回复值和摸牌数+1。",
    ["hlxg_zhengnan:hlxg_wusheng_guansuo"] = "武圣", ["hlxg_zhengnan:hlxg_dangxian_guansuo"] = "当先",
    ["hlxg_zhengnan:olzhiman"] = "制蛮",
    ["hlxg_xiefang"] = "撷芳",
    [":hlxg_xiefang"] = "锁定技，你计算与其他角色的距离-X；你的手牌上限+X（X为全场女性角色数且至少为1）。",
    ["hlxg_wusheng_guansuo"] = "武圣",
    [":hlxg_wusheng_guansuo"] = "锁定技，回合开始时，你获得一张红色【杀】；你使用红色【杀】造成的伤害+1。",
}
end

-- ==================== c204
do
-- c204: chapter-2 欢乐杀修改 / 欢乐杀界限突破, huanle.md L789-957 (吕蒙 .. 夏侯渊).
local SUITS = {"spade", "club", "heart", "diamond"}
local function c204_card_ids(card)
    if card:isVirtualCard() then return card:getSubcards() end
    local ids = sgs.IntList(); ids:append(card:getEffectiveId()); return ids
end
local function c204_same(a, b) return a ~= nil and b ~= nil and a:objectName() == b:objectName() end
local function c204_pile_ids(room, ids)
    local out = sgs.IntList()
    for _, id in sgs.qlist(ids) do
        if room:getCardPlace(id) == sgs.Player_DiscardPile then out:append(id) end
    end
    return out
end
local function c204_sp(room, name)
    if name == nil or name == "" then return nil end
    local p = room:findPlayerByObjectName(name)
    if p and p:isAlive() then return p end
    return nil
end
local function c204_pick(list)
    if list:isEmpty() then return nil end
    return list:at(math.random(0, list:length() - 1))
end

-- Equipment swap shared by 甘露 (both versions): two equips of the same sub-type on two players.
local function c204_swap_partners(room, p, card)
    local list = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getOtherPlayers(p)) do
        for _, e in sgs.qlist(q:getEquips()) do
            if e:getSubtype() == card:getSubtype() then list:append(q); break end
        end
    end
    return list
end
local function c204_swap_froms(room)
    local froms = sgs.SPlayerList()
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        for _, c in sgs.qlist(p:getEquips()) do
            if not c204_swap_partners(room, p, c):isEmpty() then froms:append(p); break end
        end
    end
    return froms
end
local function c204_swap(room, owner, name)
    local froms = c204_swap_froms(room)
    if froms:isEmpty() then return false end
    local a = room:askForPlayerChosen(owner, froms, name .. "_swapfrom", "@hl_c204_swap-from", false)
    if not a then return false end
    local disabled = sgs.IntList()
    for _, c in sgs.qlist(a:getEquips()) do
        if c204_swap_partners(room, a, c):isEmpty() then disabled:append(c:getEffectiveId()) end
    end
    local id1 = room:askForCardChosen(owner, a, "e", name, false, sgs.Card_MethodNone, disabled)
    if id1 < 0 then return false end
    local c1 = sgs.Sanguosha:getCard(id1)
    local partners = c204_swap_partners(room, a, c1)
    if partners:isEmpty() then return false end
    local b = room:askForPlayerChosen(owner, partners, name .. "_swapto", "@hl_c204_swap-to:" .. c1:objectName(), false)
    if not b then return false end
    local disabled2 = sgs.IntList()
    for _, c in sgs.qlist(b:getEquips()) do
        if c:getSubtype() ~= c1:getSubtype() then disabled2:append(c:getEffectiveId()) end
    end
    local id2 = room:askForCardChosen(owner, b, "e", name, false, sgs.Card_MethodNone, disabled2)
    if id2 < 0 then return false end
    local moves = sgs.CardsMoveList()
    moves:append(sgs.CardsMoveStruct(id1, b, sgs.Player_PlaceEquip,
        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, a:objectName(), b:objectName(), name, "")))
    moves:append(sgs.CardsMoveStruct(id2, a, sgs.Player_PlaceEquip,
        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, b:objectName(), a:objectName(), name, "")))
    room:moveCardsAtomic(moves, true)
    return true
end

-- 克己: the play-phase 杀 record is shared by both 克己 skills (any player, cleared at turn end).
extension_hl:addSkills(gu_record("#hlxg_keji_lvmeng_record", {sgs.CardUsed, sgs.CardResponded}, function(self, event, room, p, data)
    local card
    if event == sgs.CardUsed then card = data:toCardUse().card else card = data:toCardResponse().m_card end
    if card and card:isKindOf("Slash") and p:getPhase() == sgs.Player_Play then
        room:setPlayerMark(p, "hl_c204_keji_slash-Clear", 1)
    end
end))
-- mod_mark: while the owner has this mark, 克己 is the modified version without the 杀 condition (夺荆).
local function c204_keji(name, mod_mark)
    return gu_trigger(name, {sgs.EventPhaseChanging}, function(self, event, room, p, data, owner)
        if p ~= owner or data:toPhaseChange().to ~= sgs.Player_Discard or owner:isSkipped(sgs.Player_Discard) then return end
        local modified = mod_mark and owner:getMark(mod_mark) > 0
        if (not modified and owner:getMark("hl_c204_keji_slash-Clear") > 0) or not gu_invoke(owner, name) then return end
        owner:skip(sgs.Player_Discard)
        owner:drawCards(1, name)
    end, false, sgs.Skill_Frequent)
end

-- 攻心 (界吕蒙 / 神吕蒙): sole target of 杀 or 普通锦囊, either direction, once per turn.
local function c204_gongxin(name)
    return gu_trigger(name, {sgs.TargetSpecified, sgs.TargetConfirmed}, function(self, event, room, p, data, owner)
        local use = data:toCardUse()
        if p ~= owner or not use.card or not (use.card:isKindOf("Slash") or use.card:isNDTrick())
            or use.to:length() ~= 1 or owner:getMark(name .. "-Clear") > 0 then return end
        local target
        if event == sgs.TargetSpecified then
            if not c204_same(use.from, owner) or c204_same(use.to:first(), owner) then return end
            target = use.to:first()
        else
            if not use.to:contains(owner) or not use.from or c204_same(use.from, owner) then return end
            target = use.from
        end
        if not target or target:isDead() then return end
        owner:setTag(name .. "_target", sgs.QVariant(target:objectName()))
        local ok = gu_invoke(owner, name, data)
        owner:removeTag(name .. "_target")
        if not ok then return end
        room:setPlayerMark(owner, name .. "-Clear", 1)
        if target:isKongcheng() then return end
        local reds = sgs.IntList()
        for _, c in sgs.qlist(target:getHandcards()) do
            if c:isRed() then reds:append(c:getEffectiveId()) end
        end
        local id = room:doGongxin(owner, target, reds, name)
        if id < 0 or not reds:contains(id) or not target:handCards():contains(id) then return end
        room:showCard(target, id)
        local choice = room:askForChoice(owner, name, "obtain+top")
        if not target:handCards():contains(id) then return end
        if choice == "obtain" then
            room:obtainCard(owner, id, name, true)
        else
            room:moveCardTo(sgs.Sanguosha:getCard(id), target, nil, sgs.Player_DrawPile,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, owner:objectName(), "", name, ""), true)
        end
    end)
end

-- L793 吕蒙 (欢乐杀修改): 克己.
hlxg_lvmeng = sgs.General(extension_hl, "hlxg_lvmeng", "wu", 4)
hlxg_keji_lvmeng = c204_keji("hlxg_keji_lvmeng")
hlxg_lvmeng:addSkill(hlxg_keji_lvmeng)

-- L798 吕蒙 (欢乐杀界限突破): 克己, 勤学 (gains 攻心), 博图.
hljx_lvmeng = sgs.General(extension_hl, "hljx_lvmeng", "wu", 4)
hljx_keji = c204_keji("hljx_keji")
hljx_gongxin = c204_gongxin("hljx_gongxin")
extension_hl:addSkills(hljx_gongxin)
hljx_qinxue = sgs.CreateTriggerSkillV2 {
    name = "hljx_qinxue", frequency = sgs.Skill_Wake, events = {sgs.EventPhaseStart}, waked_skills = "hljx_gongxin",
    can_trigger = function(skill, event, room, player, data)
        if player and player:isAlive() and player:hasSkill(skill:objectName()) and player:getPhase() == sgs.Player_Finish
            and player:getMark(skill:objectName()) == 0 then
            return skill:objectName()
        end
        return false
    end,
    on_effect = function(skill, event, room, player, ctx)
        local name = skill:objectName()
        if player:getHandcardNum() < player:getHp() * 3 and not player:canWake(name) then return false end
        room:notifySkillInvoked(player, name)
        room:doSuperLightbox(player, name)
        room:setPlayerMark(player, name, 1)
        local diff = player:getMaxHp() - player:getHp()
        if diff > 0 then room:loseMaxHp(player, diff, name) end
        if player:isAlive() then room:handleAcquireDetachSkills(player, "-hljx_keji|hljx_gongxin") end
        return false
    end,
}
-- 博图: suits entering the discard pile this turn are kept per owner, reset at every turn start.
hljx_botu = gu_trigger("hljx_botu", {sgs.TurnStart, sgs.CardsMoveOneTime, sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if event == sgs.TurnStart then
        for _, s in ipairs(SUITS) do room:setPlayerMark(owner, "hljx_botu_" .. s, 0) end
        return
    end
    if event == sgs.CardsMoveOneTime then
        if p ~= owner then return end
        local move = data:toMoveOneTime()
        if move.to_place ~= sgs.Player_DiscardPile then return end
        for _, id in sgs.qlist(move.card_ids) do
            local s = sgs.Sanguosha:getCard(id):getSuitString()
            if table.contains(SUITS, s) then room:setPlayerMark(owner, "hljx_botu_" .. s, 1) end
        end
        return
    end
    if p:getPhase() ~= sgs.Player_NotActive or not c204_same(room:getCurrent(), p) then return end
    for _, s in ipairs(SUITS) do
        if owner:getMark("hljx_botu_" .. s) == 0 then return end
    end
    if owner:getMark("hljx_botu_lun") >= math.min(room:alivePlayerCount(), 3) or not gu_invoke(owner, "hljx_botu") then return end
    room:addPlayerMark(owner, "hljx_botu_lun")
    owner:gainAnExtraTurn()
end)
hljx_lvmeng:addSkill(hljx_keji); hljx_lvmeng:addSkill(hljx_qinxue); hljx_lvmeng:addSkill(hljx_botu)
hljx_lvmeng:addRelateSkill("hljx_gongxin")

-- L806 神吕蒙 (欢乐杀修改, Q.LE): 攻心 + locked 涉猎.
hlxg_lvmeng2 = sgs.General(extension_hl, "hlxg_lvmeng2", "god", 3)
hlxg_gongxin_lvmeng2 = c204_gongxin("hlxg_gongxin_lvmeng2")
hlxg_shelie = gu_trigger("hlxg_shelie", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Draw then return end
    room:sendCompulsoryTriggerLog(owner, "hlxg_shelie", true, true)
    local ids = room:getNCards(5, false)
    if ids:isEmpty() then return true end
    room:moveCardsAtomic(sgs.CardsMoveStruct(ids, nil, sgs.Player_PlaceTable,
        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, owner:objectName(), "hlxg_shelie", "")), true)
    local cands = sgs.IntList()
    for _, id in sgs.qlist(ids) do
        if room:getCardPlace(id) == sgs.Player_PlaceTable then cands:append(id) end
    end
    local got = sgs.IntList()
    if not cands:isEmpty() then
        room:fillAG(cands)
        while not cands:isEmpty() and owner:isAlive() do
            local id = room:askForAG(owner, cands, false, "hlxg_shelie")
            if id < 0 or not cands:contains(id) then break end
            cands:removeOne(id)
            got:append(id)
            room:takeAG(owner, id, false)
            local suit = sgs.Sanguosha:getCard(id):getSuit()
            for _, other in sgs.qlist(ids) do
                if cands:contains(other) and sgs.Sanguosha:getCard(other):getSuit() == suit then
                    cands:removeOne(other)
                    room:takeAG(nil, other, false)
                end
            end
        end
        room:clearAG()
    end
    local keep, rest = sgs.IntList(), sgs.IntList()
    for _, id in sgs.qlist(ids) do
        if room:getCardPlace(id) == sgs.Player_PlaceTable then
            if got:contains(id) and owner:isAlive() then keep:append(id) else rest:append(id) end
        end
    end
    gu_obtain(room, owner, keep, "hlxg_shelie")
    if not rest:isEmpty() then
        local d = gu_dummy(rest)
        room:throwCard(d, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, owner:objectName(), "hlxg_shelie", ""), nil)
        d:deleteLater()
    end
    return true
end, true)
hlxg_lvmeng2:addSkill(hlxg_gongxin_lvmeng2); hlxg_lvmeng2:addSkill(hlxg_shelie)

-- L812 吕蒙 (欢乐杀修改): 克己, 夺荆 (谋弈, resolved like the engine's 谋断粮: the target blocks one strategy).
hlxg_lvmeng3 = sgs.General(extension_hl, "hlxg_lvmeng3", "wu", 4)
hlxg_keji_lvmeng3 = c204_keji("hlxg_keji_lvmeng3", "hlxg_duojing_keji-Clear")
hlxg_duojing = gu_active("hlxg_duojing", 2, 0, 0, gu_one, gu_one_feasible,
    function(self, room, source, targets)
        local to = targets[1]
        local name = "hlxg_duojing"
        local d1 = sgs.QVariant(); d1:setValue(to)
        local c1 = room:askForChoice(source, name, "xiuyang+baiyi", d1)
        if to:isDead() then return end
        local d2 = sgs.QVariant(); d2:setValue(source)
        local c2 = room:askForChoice(to, name, "xiuyang2+baiyi2", d2)
        local log = sgs.LogMessage()
        log.from = source; log.to:append(to); log.arg = name .. ":" .. c1
        log.type = (c2 == c1 .. "2") and "#hlxg_duojingFail" or "#hlxg_duojingSuccess"
        room:sendLog(log)
        if c2 == c1 .. "2" or source:isDead() then return end
        if c1 == "xiuyang" then
            if to:isAlive() and not to:isNude() then
                local id = room:askForCardChosen(source, to, "he", name)
                if id >= 0 then room:obtainCard(source, id, name, false) end
            end
            if source:isAlive() then room:recover(source, sgs.RecoverStruct(source, nil, 1, name)) end
            local x = source:getLostHp()
            if x > 0 and source:isAlive() and source:askForSkillInvoke("hlxg_duojing_draw", sgs.QVariant(x)) then
                source:drawCards(x, name)
                if source:isAlive() then room:askForDiscard(source, name, x, x, false, true) end
            end
        else
            local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
            slash:setSkillName("_hlxg_duojing")
            slash:setFlags("hlxg_duojing_armor")
            if to:isAlive() and source:canSlash(to, slash, false) then
                room:useCard(sgs.CardUseStruct(slash, source, to), false)
            else
                slash:deleteLater()
            end
            if source:isAlive() then
                room:addPlayerMark(source, "hlxg_duojing_slash-Clear")
                room:setPlayerMark(source, "hlxg_duojing_keji-Clear", 1)
            end
        end
    end)
-- 白衣渡江's 【杀】 ignores armor.
hlxg_duojing_armor = gu_trigger("#hlxg_duojing_armor", {sgs.TargetSpecified}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if p ~= owner or not use.card or not use.card:hasFlag("hlxg_duojing_armor") then return end
    for _, t in sgs.qlist(use.to) do t:addQinggangTag(use.card) end
end, true)
hlxg_duojing_mod = sgs.CreateTargetModSkillV2 {
    name = "#hlxg_duojing_mod", pattern = "Slash", holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(self, ctx)
        local from = ctx:getPrimary()
        if ctx:getModType() == sgs.TargetModSkill_Residue and from and from:getMark("hlxg_duojing_slash-Clear") > 0 then
            return from:getMark("hlxg_duojing_slash-Clear")
        end
        return false
    end,
}
hlxg_lvmeng3:addSkill(hlxg_keji_lvmeng3); hlxg_lvmeng3:addSkill(hlxg_duojing)
hlxg_lvmeng3:addSkill(hlxg_duojing_armor); hlxg_lvmeng3:addSkill(hlxg_duojing_mod)
extension_hl:insertRelatedSkills("hlxg_duojing", "#hlxg_duojing_armor")
extension_hl:insertRelatedSkills("hlxg_duojing", "#hlxg_duojing_mod")

-- L820 吴兰 (欢乐杀修改): 挫锐.
hlxg_wulan = sgs.General(extension_hl, "hlxg_wulan", "shu", 4)
hlxg_cuorui = gu_trigger("hlxg_cuorui", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Play then return end
    local firsts = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if owner:distanceTo(q) <= 1 and owner:canDiscard(q, "hej") then firsts:append(q) end
    end
    if firsts:isEmpty() then return end
    local first = room:askForPlayerChosen(owner, firsts, "hlxg_cuorui", "@hlxg_cuorui", true, true)
    if not first then return end
    local id = room:askForCardChosen(owner, first, "hej", "hlxg_cuorui", false, sgs.Card_MethodDiscard)
    if id < 0 then return end
    local card = sgs.Sanguosha:getCard(id)
    room:throwCard(id, "hlxg_cuorui", first, owner)
    if owner:isDead() then return end
    local function same_color(c) return (card:isRed() and c:isRed()) or (card:isBlack() and c:isBlack()) end
    local equip_targets, hand_targets = sgs.SPlayerList(), sgs.SPlayerList()
    for _, q in sgs.qlist(room:getOtherPlayers(owner)) do
        if q:objectName() ~= first:objectName() then
            equip_targets:append(q)
            if owner:canDiscard(q, "h") then hand_targets:append(q) end
        end
    end
    local choices = {}
    if not equip_targets:isEmpty() then table.insert(choices, "equip") end
    if not hand_targets:isEmpty() then table.insert(choices, "hand") end
    if #choices == 0 then return end
    local choice = room:askForChoice(owner, "hlxg_cuorui", table.concat(choices, "+"))
    if choice == "equip" then
        local to = room:askForPlayerChosen(owner, equip_targets, "hlxg_cuorui_equip", "@hlxg_cuorui-equip", false)
        if not to then return end
        local ids = sgs.IntList()
        for _, e in sgs.qlist(to:getEquips()) do
            if same_color(e) and owner:canDiscard(to, e:getEffectiveId()) then ids:append(e:getEffectiveId()) end
        end
        if not ids:isEmpty() then
            local d = gu_dummy(ids); room:throwCard(d, "hlxg_cuorui", to, owner); d:deleteLater()
        end
    else
        local to = room:askForPlayerChosen(owner, hand_targets, "hlxg_cuorui_hand", "@hlxg_cuorui-hand", false)
        if not to then return end
        local n = math.min(2, to:getHandcardNum())
        local ids = room:askForCardsChosen(owner, to, "h", "hlxg_cuorui", 1, n, false, sgs.Card_MethodDiscard, sgs.IntList(), false)
        if ids:isEmpty() then return end
        local d = gu_dummy(ids); room:throwCard(d, "hlxg_cuorui", to, owner); d:deleteLater()
        local gain = sgs.IntList()
        for _, cid in sgs.qlist(ids) do
            if same_color(sgs.Sanguosha:getCard(cid)) and room:getCardPlace(cid) == sgs.Player_DiscardPile then gain:append(cid) end
        end
        if owner:isAlive() then gu_obtain(room, owner, gain, "hlxg_cuorui") end
    end
end)
hlxg_wulan:addSkill(hlxg_cuorui)

-- L827 吴国太 (欢乐杀修改): 甘露 (locked), 补益.
hlxg_wuguotai = sgs.General(extension_hl, "hlxg_wuguotai", "wu", 3, false)
hlxg_ganlu = gu_trigger("hlxg_ganlu", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Play then return end
    room:sendCompulsoryTriggerLog(owner, "hlxg_ganlu", true, true)
    local choices = {}
    if room:canMoveField("e") then table.insert(choices, "move") end
    if not c204_swap_froms(room):isEmpty() then table.insert(choices, "swap") end
    table.insert(choices, "draw")
    local choice = room:askForChoice(owner, "hlxg_ganlu", table.concat(choices, "+"))
    if choice == "move" then room:moveField(owner, "hlxg_ganlu", false, "e")
    elseif choice == "swap" then c204_swap(room, owner, "hlxg_ganlu")
    else owner:drawCards(1, "hlxg_ganlu") end
end, true)
hlxg_buyi = gu_trigger("hlxg_buyi", {sgs.Dying}, function(self, event, room, p, data, owner)
    local who = data:toDying().who
    if not who or p ~= who or who:isKongcheng() or owner:getMark("hlxg_buyi-Clear") >= 3
        or not gu_invoke(owner, "hlxg_buyi", sgs.QVariant(who:objectName())) then return end
    room:addPlayerMark(owner, "hlxg_buyi-Clear")
    local id = room:askForCardChosen(owner, who, "h", "hlxg_buyi")
    if id < 0 then return end
    room:showCard(who, id)
    if not sgs.Sanguosha:getCard(id):isKindOf("BasicCard") or not who:handCards():contains(id) then return end
    room:throwCard(id, "hlxg_buyi", who)
    if who:isAlive() then room:recover(who, sgs.RecoverStruct(owner, nil, 1, "hlxg_buyi")) end
end)
hlxg_wuguotai:addSkill(hlxg_ganlu); hlxg_wuguotai:addSkill(hlxg_buyi)

-- L833 吴国太 (欢乐杀界限突破): 甘露 (locked), 补益.
hljx_wuguotai = sgs.General(extension_hl, "hljx_wuguotai", "wu", 3, false)
hljx_ganlu = gu_trigger("hljx_ganlu", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Play then return end
    room:sendCompulsoryTriggerLog(owner, "hljx_ganlu", true, true)
    local choices = {"draw"}
    if room:alivePlayerCount() >= 2 then table.insert(choices, "exchange") end
    local choice = room:askForChoice(owner, "hljx_ganlu", table.concat(choices, "+"))
    if choice == "draw" then
        owner:drawCards(2, "hljx_ganlu")
        if owner:isDead() then return end
        local more = {}
        if room:canMoveField("e") then table.insert(more, "move") end
        if not c204_swap_froms(room):isEmpty() then table.insert(more, "swap") end
        if #more == 0 then return end
        table.insert(more, "cancel")
        local sub = room:askForChoice(owner, "hljx_ganlu_more", table.concat(more, "+"))
        if sub == "move" then room:moveField(owner, "hljx_ganlu", false, "e")
        elseif sub == "swap" then c204_swap(room, owner, "hljx_ganlu") end
        return
    end
    local tos = room:askForPlayersChosen(owner, room:getAlivePlayers(), "hljx_ganlu", 2, 2, "@hljx_ganlu-exchange", true)
    if tos:length() ~= 2 then return end
    local a, b = tos:at(0), tos:at(1)
    room:swapEquips(a, b, "hljx_ganlu")
    if owner:isAlive() and math.abs(a:getEquips():length() - b:getEquips():length()) > owner:getMaxHp() then
        room:askForDiscard(owner, "hljx_ganlu", 1, 1, false, true)
    end
end, true)
hljx_buyi = gu_trigger("hljx_buyi", {sgs.Dying}, function(self, event, room, p, data, owner)
    local who = data:toDying().who
    if not who or p ~= who or owner:getMark("hljx_buyi-Clear") >= 3
        or not gu_invoke(owner, "hljx_buyi", sgs.QVariant(who:objectName())) then return end
    room:addPlayerMark(owner, "hljx_buyi-Clear")
    if who:isKongcheng() then who:drawCards(1, "hljx_buyi") end
    if who:isDead() or who:isKongcheng() or owner:isDead() then return end
    local ids = room:askForCardsChosen(owner, who, "h", "hljx_buyi", 0, who:getHandcardNum(), true, sgs.Card_MethodDiscard)
    if ids:isEmpty() then return end
    room:showCard(who, ids)
    local x = 0
    for _, id in sgs.qlist(ids) do
        if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then x = x + 1 end
    end
    local d = gu_dummy(ids); room:throwCard(d, "hljx_buyi", who, owner); d:deleteLater()
    if x > 0 and who:isAlive() then room:recover(who, sgs.RecoverStruct(owner, nil, x, "hljx_buyi")) end
end)
hljx_wuguotai:addSkill(hljx_ganlu); hljx_wuguotai:addSkill(hljx_buyi)

-- L841 吴苋 (欢乐杀修改): 怠宴, 福绵. "上回合" = the owner's previous turn (tags shift at her turn start).
hlxg_wuxian = sgs.General(extension_hl, "hlxg_wuxian", "shu", 3, false)
hlxg_daiyan = gu_trigger("hlxg_daiyan", {sgs.TurnStart, sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.TurnStart then
        owner:setTag("hlxg_daiyan_last", sgs.QVariant(owner:getTag("hlxg_daiyan_this"):toString()))
        owner:setTag("hlxg_daiyan_this", sgs.QVariant(""))
        return
    end
    if owner:getPhase() ~= sgs.Player_Finish then return end
    local to = room:askForPlayerChosen(owner, room:getOtherPlayers(owner), "hlxg_daiyan", "@hlxg_daiyan", true, true)
    if not to then return end
    owner:setTag("hlxg_daiyan_this", sgs.QVariant(to:objectName()))
    local pool = sgs.IntList()
    for _, id in sgs.qlist(room:getDrawPile()) do
        local c = sgs.Sanguosha:getCard(id)
        if c:getSuit() == sgs.Card_Heart and c:isKindOf("BasicCard") then pool:append(id) end
    end
    for _, id in sgs.qlist(room:getDiscardPile()) do
        local c = sgs.Sanguosha:getCard(id)
        if c:getSuit() == sgs.Card_Heart and c:isKindOf("BasicCard") then pool:append(id) end
    end
    local id = c204_pick(pool)
    if id then room:obtainCard(to, id, "hlxg_daiyan", true) end
    if owner:isAlive() and owner:getTag("hlxg_daiyan_last"):toString() ~= to:objectName() then
        owner:drawCards(1, "hlxg_daiyan")
    end
end)
hlxg_fumian = gu_trigger("hlxg_fumian", {sgs.TurnStart, sgs.EventPhaseStart, sgs.DrawNCards, sgs.PreCardUsed}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.TurnStart then
        owner:setTag("hlxg_fumian_last", sgs.QVariant(owner:getTag("hlxg_fumian_this"):toString()))
        owner:setTag("hlxg_fumian_this", sgs.QVariant(""))
        return
    end
    if event == sgs.EventPhaseStart then
        if owner:getPhase() ~= sgs.Player_Start then return end
        local choice = room:askForChoice(owner, "hlxg_fumian", "draw+target+cancel")
        if choice ~= "draw" and choice ~= "target" then return end
        room:notifySkillInvoked(owner, "hlxg_fumian")
        owner:setTag("hlxg_fumian_this", sgs.QVariant(choice))
        local last = owner:getTag("hlxg_fumian_last"):toString()
        local n = (last ~= "" and last ~= choice) and 2 or 1
        room:setPlayerMark(owner, "&hlxg_fumian_" .. choice .. "-Clear", n)
        return
    end
    if event == sgs.DrawNCards then
        local draw = data:toDraw()
        local n = owner:getMark("&hlxg_fumian_draw-Clear")
        if draw.reason ~= "draw_phase" or n == 0 then return end
        room:sendCompulsoryTriggerLog(owner, "hlxg_fumian", true)
        draw.num = draw.num + n
        data:setValue(draw)
        return
    end
    local use = data:toCardUse()
    local n = owner:getMark("&hlxg_fumian_target-Clear")
    local card = use.card
    if n == 0 or not card or not c204_same(use.from, owner) or not card:isRed() or use.to:isEmpty()
        or not (card:isKindOf("BasicCard") or card:isNDTrick()) or card:isKindOf("Nullification") or card:isKindOf("Collateral") then return end
    room:setCardFlag(card, "hlxg_fumian_distance")
    local cands = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if not use.to:contains(q) and not owner:isProhibited(q, card) and card:targetFilter(sgs.PlayerList(), q, owner) then
            cands:append(q)
        end
    end
    room:setCardFlag(card, "-hlxg_fumian_distance")
    if cands:isEmpty() then return end
    local chosen = room:askForPlayersChosen(owner, cands, "hlxg_fumian", 0, n, "@hlxg_fumian:" .. card:objectName(), true)
    if chosen:isEmpty() then return end
    for _, q in sgs.qlist(chosen) do use.to:append(q) end
    room:sortByActionOrder(use.to)
    data:setValue(use)
end)
hlxg_fumian_mod = sgs.CreateTargetModSkillV2 {
    name = "#hlxg_fumian_mod", pattern = ".", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local card = ctx:getCard()
        if ctx:getModType() == sgs.TargetModSkill_DistanceLimit and card and card:hasFlag("hlxg_fumian_distance") then return 1000 end
        return false
    end,
}
hlxg_wuxian:addSkill(hlxg_daiyan); hlxg_wuxian:addSkill(hlxg_fumian); hlxg_wuxian:addSkill(hlxg_fumian_mod)
extension_hl:insertRelatedSkills("hlxg_fumian", "#hlxg_fumian_mod")

-- L849 周仓 (欢乐杀修改): 刀仆 (view-as 青龙偃月刀 + red-杀 damage), 忠勇.
hlxg_zhoucang = sgs.General(extension_hl, "hlxg_zhoucang", "shu", 4)
-- No V2 factory exists for view-as equipment; CreateViewAsEquipSkill is the only engine route.
hlxg_daopu = sgs.CreateViewAsEquipSkill {
    name = "hlxg_daopu",
    view_as_equip = function(self, player)
        if player:getWeaponsCount() == 0 then return "blade" end
        return ""
    end,
}
hlxg_daopu_damage = gu_trigger("#hlxg_daopu_damage", {sgs.DamageCaused}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if p ~= owner or not c204_same(d.from, owner) or not d.card or not d.card:isKindOf("Slash") or not d.card:isRed() then return end
    local has_blade = false
    for _, e in sgs.qlist(owner:getEquips()) do
        if e:isKindOf("Blade") then has_blade = true; break end
    end
    if not has_blade then return end
    room:sendCompulsoryTriggerLog(owner, "hlxg_daopu", true)
    d.damage = d.damage + 1
    data:setValue(d)
end, true)
hlxg_zhongyong = gu_trigger("hlxg_zhongyong", {sgs.CardOffset, sgs.CardFinished}, function(self, event, room, p, data, owner)
    if event == sgs.CardOffset then
        local effect = data:toCardEffect()
        if p ~= owner or not c204_same(effect.from, owner) or not effect.card or not effect.card:isKindOf("Slash")
            or not effect.offset_card or not effect.offset_card:isKindOf("Jink") then return end
        local key = "hlxg_zhongyong_" .. effect.card:toString()
        local list = gu_names(owner, key)
        for _, id in sgs.qlist(c204_card_ids(effect.offset_card)) do table.insert(list, tostring(id)) end
        gu_setnames(owner, key, list)
        return
    end
    local use = data:toCardUse()
    if p ~= owner or not c204_same(use.from, owner) or not use.card or not use.card:isKindOf("Slash") then return end
    local key = "hlxg_zhongyong_" .. use.card:toString()
    local jinks = gu_names(owner, key)
    owner:removeTag(key)
    local others = false
    for _, t in sgs.qlist(use.to) do
        if not c204_same(t, owner) then others = true end
    end
    if not others then return end
    local give = c204_pile_ids(room, c204_card_ids(use.card))
    for _, s in ipairs(jinks) do
        local id = tonumber(s)
        if id and room:getCardPlace(id) == sgs.Player_DiscardPile and not give:contains(id) then give:append(id) end
    end
    if give:isEmpty() then return end
    local cands = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getOtherPlayers(owner)) do
        if not use.to:contains(q) then cands:append(q) end
    end
    if cands:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, cands, "hlxg_zhongyong", "@hlxg_zhongyong", true, true)
    if not to then return end
    local red, black = false, false
    for _, id in sgs.qlist(give) do
        local c = sgs.Sanguosha:getCard(id)
        if c:isRed() then red = true elseif c:isBlack() then black = true end
    end
    -- The cards lie in the discard pile, so they are handed over as a GIVE move from there.
    local dummy = gu_dummy(give)
    room:obtainCard(to, dummy, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, owner:objectName(), to:objectName(),
        "hlxg_zhongyong", ""), true)
    dummy:deleteLater()
    if red and to:isAlive() and owner:isAlive() then
        -- The only range restriction is 你攻击范围内 (the 周仓 player's range), not the user's own distance.
        local tos = sgs.SPlayerList()
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            if owner:inMyAttackRange(q) and to:canSlash(q, nil, false) then tos:append(q) end
        end
        if not tos:isEmpty() then room:askForUseSlashTo(to, tos, "@hlxg_zhongyong-slash:" .. owner:objectName(), false, true, false) end
    end
    if black then
        if owner:isAlive() then owner:drawCards(1, "hlxg_zhongyong") end
        if to:isAlive() then to:drawCards(1, "hlxg_zhongyong") end
    end
end)
hlxg_zhoucang:addSkill(hlxg_daopu); hlxg_zhoucang:addSkill(hlxg_daopu_damage); hlxg_zhoucang:addSkill(hlxg_zhongyong)
extension_hl:insertRelatedSkills("hlxg_daopu", "#hlxg_daopu_damage")

-- L857 周妃 (欢乐杀修改): 箜声 = engine kongsheng (same text), 良姻.
hlxg_zhoufei = sgs.General(extension_hl, "hlxg_zhoufei", "wu", 3, false)
hlxg_liangyin = gu_trigger("hlxg_liangyin", {sgs.CardsMoveOneTime}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    local move = data:toMoveOneTime()
    if move.to_place == sgs.Player_PlaceSpecial then
        if move.to_pile_name:sub(1, 1) == "#" then return end
        local out = false
        for i = 0, move.card_ids:length() - 1 do
            if move.from_places:at(i) ~= sgs.Player_PlaceSpecial then out = true; break end
        end
        if not out then return end
        local to = room:askForPlayerChosen(owner, room:getAlivePlayers(), "hlxg_liangyin_draw", "@hlxg_liangyin-draw", true, true)
        if to then to:drawCards(1, "hlxg_liangyin") end
    elseif move.to and move.to_place == sgs.Player_PlaceHand and move.from_places:contains(sgs.Player_PlaceSpecial) then
        local cands = sgs.SPlayerList()
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            if q:canDiscard(q, "he") then cands:append(q) end
        end
        if cands:isEmpty() then return end
        local to = room:askForPlayerChosen(owner, cands, "hlxg_liangyin_discard", "@hlxg_liangyin-discard", true, true)
        if to then room:askForDiscard(to, "hlxg_liangyin", 1, 1, false, true) end
    end
end)
hlxg_zhoufei:addSkill("kongsheng"); hlxg_zhoufei:addSkill(hlxg_liangyin)

-- L863 周妃 (欢乐杀修改, no 編號): 灵箜 ("箜篌" is a card tip), 贤淑.
hlxg_zhoufei2 = sgs.General(extension_hl, "hlxg_zhoufei2", "wu", 3, false)
hlxg_lingkong = gu_trigger("hlxg_lingkong", {sgs.GameStart, sgs.CardsMoveOneTime}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.GameStart then
        if owner:isKongcheng() then return end
        room:sendCompulsoryTriggerLog(owner, "hlxg_lingkong", true, true)
        for _, id in sgs.qlist(owner:handCards()) do room:setCardTip(id, "hlxg_konghou") end
        -- The opening deal is not a "首次获得" of the first turn.
        room:setPlayerMark(owner, "hlxg_lingkong-Clear", 0)
        return
    end
    local move = data:toMoveOneTime()
    if not move.to or move.to:objectName() ~= owner:objectName() or move.to_place ~= sgs.Player_PlaceHand
        or owner:getPhase() == sgs.Player_Draw or owner:getMark("hlxg_lingkong-Clear") > 0 then return end
    room:setPlayerMark(owner, "hlxg_lingkong-Clear", 1)
    local marked = false
    for _, id in sgs.qlist(move.card_ids) do
        if owner:handCards():contains(id) then room:setCardTip(id, "hlxg_konghou"); marked = true end
    end
    if marked then room:sendCompulsoryTriggerLog(owner, "hlxg_lingkong", true) end
end, true)
hlxg_lingkong_limit = sgs.CreateCardLimitSkill {
    name = "#hlxg_lingkong_limit",
    limit_list = function(self, player) return "ignore" end,
    limit_pattern = function(self, player, card)
        if card and player:hasSkill("hlxg_lingkong") and card:hasTip("hlxg_konghou") and player:handCards():contains(card:getEffectiveId()) then
            return card:toString()
        end
        return ""
    end,
}
hlxg_xianshu = gu_active("hlxg_xianshu", nil, 1, 1, gu_one, gu_one_feasible,
    function(self, room, source, targets)
        local to = targets[1]
        local card = sgs.Sanguosha:getCard(self:getSubcards():first())
        room:giveCard(source, to, self, "hlxg_xianshu")
        if source:isDead() then return end
        source:drawCards(math.max(1, math.min(5, math.abs(source:getHp() - to:getHp()))), "hlxg_xianshu")
        if to:isDead() or source:isDead() then return end
        if card:isRed() and to:getHp() <= source:getHp() then
            room:recover(to, sgs.RecoverStruct(source, nil, 1, "hlxg_xianshu"))
        elseif card:isBlack() and to:getHp() >= source:getHp() then
            room:loseHp(to, 1, true, source, "hlxg_xianshu")
        end
    end,
    function(request, c)
        return c:hasTip("hlxg_konghou") and request:getInitiator():handCards():contains(c:getEffectiveId())
    end)
hlxg_zhoufei2:addSkill(hlxg_lingkong); hlxg_zhoufei2:addSkill(hlxg_lingkong_limit); hlxg_zhoufei2:addSkill(hlxg_xianshu)
extension_hl:insertRelatedSkills("hlxg_lingkong", "#hlxg_lingkong_limit")

-- 奋激 (both 周泰 variants, same text).
local function c204_fenji(name)
    return gu_trigger(name, {sgs.CardsMoveOneTime}, function(self, event, room, p, data, owner)
        if p ~= owner then return end
        local move = data:toMoveOneTime()
        if not move.from or not move.from_places:contains(sgs.Player_PlaceHand) then return end
        local from = room:findPlayerByObjectName(move.from:objectName())
        if not from or from:isDead() then return end
        local r = move.reason.m_reason
        -- 弃置: a discard whose acting player is someone else; 获得: another player takes the cards into
        -- their hand on their own initiative (交给 / 交换 are the loser's or a mutual action, not 获得).
        local by_other = (r % 16 == sgs.CardMoveReason_S_REASON_DISCARD and move.reason.m_playerId ~= ""
                and move.reason.m_playerId ~= from:objectName())
            or (move.to and move.to:objectName() ~= from:objectName() and move.to_place == sgs.Player_PlaceHand
                and r ~= sgs.CardMoveReason_S_REASON_GIVE and r ~= sgs.CardMoveReason_S_REASON_PREVIEWGIVE
                and r ~= sgs.CardMoveReason_S_REASON_SWAP)
        if not by_other or not gu_invoke(owner, name, sgs.QVariant(from:objectName())) then return end
        room:loseHp(owner, 1, true, owner, name)
        if from:isAlive() then from:drawCards(2, name) end
    end)
end
local function c204_buqu_max(name, helper)
    return sgs.CreateMaxCardsSkillV2 {
        name = helper, holder_selector = sgs.CorrectSkill_System,
        correct_func = function(self, ctx)
            local p = ctx:getPrimary()
            if p and p:hasSkill(name) and p:getMark("@" .. name) > 0 then return p:getMark("@" .. name) end
            return false
        end,
    }
end

-- L871 周泰 (欢乐杀修改): 不屈 (创 marks), 奋激.
hlxg_zhoutai = sgs.General(extension_hl, "hlxg_zhoutai", "wu", 4)
hlxg_buqu = gu_trigger("hlxg_buqu", {sgs.Dying}, function(self, event, room, p, data, owner)
    local who = data:toDying().who
    if p ~= owner or not c204_same(who, owner) or owner:getMark("@hlxg_buqu") >= 4 or owner:getHp() >= 1 then return end
    room:sendCompulsoryTriggerLog(owner, "hlxg_buqu", true, true)
    room:addPlayerMark(owner, "@hlxg_buqu")
    room:recover(owner, sgs.RecoverStruct(owner, nil, 1 - owner:getHp(), "hlxg_buqu"))
end, true)
hlxg_buqu_max = c204_buqu_max("hlxg_buqu", "#hlxg_buqu_max")
hlxg_fenji = c204_fenji("hlxg_fenji")
hlxg_zhoutai:addSkill(hlxg_buqu); hlxg_zhoutai:addSkill(hlxg_buqu_max); hlxg_zhoutai:addSkill(hlxg_fenji)
extension_hl:insertRelatedSkills("hlxg_buqu", "#hlxg_buqu_max")

-- L877 周泰 (欢乐杀界限突破): 不屈 (prevents damage / HP loss), 奋激, 清创.
hljx_zhoutai = sgs.General(extension_hl, "hljx_zhoutai", "wu", 4)
hljx_buqu = gu_trigger("hljx_buqu", {sgs.DamageInflicted, sgs.PreHpLost}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getMark("@hljx_buqu") >= 4 then return end
    if event == sgs.DamageInflicted then
        if not c204_same(data:toDamage().to, owner) then return end
    elseif not c204_same(data:toHpLost().to, owner) then return end
    room:sendCompulsoryTriggerLog(owner, "hljx_buqu", true, true)
    room:addPlayerMark(owner, "@hljx_buqu")
    return true
end, true)
hljx_buqu_max = c204_buqu_max("hljx_buqu", "#hljx_buqu_max")
hljx_fenji = c204_fenji("hljx_fenji")
hljx_qingchuang = gu_active("hljx_qingchuang", 1, 1, 1, function() return false end,
    function(self, targets) return #targets == 0 end,
    function(self, room, source, targets)
        room:throwCard(self, "hljx_qingchuang", source)
        if source:getMark("@hljx_buqu") > 0 then room:removePlayerMark(source, "@hljx_buqu") end
        if source:isAlive() then source:drawCards(1, "hljx_qingchuang") end
    end,
    function(request, c)
        return (c:isKindOf("Peach") or c:isKindOf("Analeptic")) and not request:getInitiator():isJilei(c)
    end,
    function(p) return p:getMark("@hljx_buqu") > 0 end)
hljx_zhoutai:addSkill(hljx_buqu); hljx_zhoutai:addSkill(hljx_buqu_max); hljx_zhoutai:addSkill(hljx_fenji); hljx_zhoutai:addSkill(hljx_qingchuang)
extension_hl:insertRelatedSkills("hljx_buqu", "#hljx_buqu_max")

-- L886 周瑜 (欢乐杀修改): 反间 (play-phase start), 英姿 = engine yingzi (same text).
hlxg_zhouyu = sgs.General(extension_hl, "hlxg_zhouyu", "wu", 3)
hlxg_fanjian = gu_trigger("hlxg_fanjian", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Play then return end
    local to = room:askForPlayerChosen(owner, room:getAlivePlayers(), "hlxg_fanjian", "@hlxg_fanjian", true, true)
    if not to then return end
    to:drawCards(1, "hlxg_fanjian")
    if to:isAlive() then room:damage(sgs.DamageStruct("hlxg_fanjian", owner, to)) end
end)
hlxg_zhouyu:addSkill(hlxg_fanjian); hlxg_zhouyu:addSkill("yingzi")

-- L892 周瑜 (欢乐杀界限突破): 反间 (secret suit), 英姿 (X conditions).
hljx_zhouyu = sgs.General(extension_hl, "hljx_zhouyu", "wu", 3)
hljx_fanjian = gu_active("hljx_fanjian", 1, 0, 0, gu_one, gu_one_feasible,
    function(self, room, source, targets)
        local to = targets[1]
        local suits = {}
        for _, c in sgs.qlist(source:getHandcards()) do
            local s = c:getSuitString()
            if table.contains(SUITS, s) and not table.contains(suits, s) then table.insert(suits, s) end
        end
        if #suits == 0 then return end
        local mine = room:askForChoice(source, "hljx_fanjian", table.concat(suits, "+"))
        if to:isDead() then return end
        local theirs = sgs.Card_Suit2String(room:askForSuit(to, "hljx_fanjian"))
        local log = sgs.LogMessage()
        log.type = "#hljx_fanjianLog"; log.from = source; log.to:append(to); log.arg = mine; log.arg2 = theirs
        room:sendLog(log)
        if mine == theirs and to:isAlive() then to:drawCards(1, "hljx_fanjian") end
        if to:isAlive() and source:isAlive() then room:damage(sgs.DamageStruct("hljx_fanjian", source, to)) end
    end, nil,
    function(p) return not p:isKongcheng() end)
local function c204_yingzi_x(p)
    local x = 0
    if p:getHandcardNum() >= 2 then x = x + 1 end
    if p:getHp() >= 2 then x = x + 1 end
    if p:getEquips():length() >= 1 then x = x + 1 end
    return math.max(1, x)
end
hljx_yingzi_zhouyu = gu_trigger("hljx_yingzi_zhouyu", {sgs.DrawNCards}, function(self, event, room, p, data, owner)
    local draw = data:toDraw()
    if p ~= owner or draw.reason ~= "draw_phase" then return end
    room:sendCompulsoryTriggerLog(owner, "hljx_yingzi_zhouyu", true, true)
    draw.num = draw.num + c204_yingzi_x(owner)
    data:setValue(draw)
end, true)
hljx_yingzi_zhouyu_max = sgs.CreateMaxCardsSkillV2 {
    name = "#hljx_yingzi_zhouyu_max", holder_selector = sgs.CorrectSkill_System,
    fixed_func = function(self, ctx)
        local p = ctx:getPrimary()
        if p and p:hasSkill("hljx_yingzi_zhouyu") then return p:getMaxHp() + c204_yingzi_x(p) end
        return nil
    end,
}
hljx_zhouyu:addSkill(hljx_fanjian); hljx_zhouyu:addSkill(hljx_yingzi_zhouyu); hljx_zhouyu:addSkill(hljx_yingzi_zhouyu_max)
extension_hl:insertRelatedSkills("hljx_yingzi_zhouyu", "#hljx_yingzi_zhouyu_max")

-- L898 神周瑜 (欢乐杀修改, Q.LE): 业炎, 琴音.
hlxg_zhouyu2 = sgs.General(extension_hl, "hlxg_zhouyu2", "god", 4)
hlxg_yeyan_zhouyu2 = gu_trigger("hlxg_yeyan_zhouyu2", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Play then return end
    local to = room:askForPlayerChosen(owner, room:getOtherPlayers(owner), "hlxg_yeyan_zhouyu2", "@hlxg_yeyan_zhouyu2", true, true)
    if to then room:damage(sgs.DamageStruct("hlxg_yeyan_zhouyu2", owner, to, 1, sgs.DamageStruct_Fire)) end
end)
hlxg_qinyin = gu_trigger("hlxg_qinyin", {sgs.CardsMoveOneTime, sgs.EventPhaseEnd}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.CardsMoveOneTime then
        local move = data:toMoveOneTime()
        if move.from and move.from:objectName() == owner:objectName()
            and (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
            and move.reason.m_reason % 16 == sgs.CardMoveReason_S_REASON_DISCARD then
            room:setPlayerMark(owner, "hlxg_qinyin-Clear", 1)
        end
        return
    end
    if owner:getPhase() ~= sgs.Player_Discard or owner:getMark("hlxg_qinyin-Clear") == 0 then return end
    local choice = room:askForChoice(owner, "hlxg_qinyin", "recover+lose+draw+cancel")
    if choice == "cancel" then return end
    room:notifySkillInvoked(owner, "hlxg_qinyin")
    for _, q in sgs.qlist(room:getAllPlayers()) do
        if q:isAlive() then
            if choice == "recover" then
                if q:isWounded() then room:recover(q, sgs.RecoverStruct(owner, nil, 1, "hlxg_qinyin")) end
            elseif choice == "lose" then room:loseHp(q, 1, true, owner, "hlxg_qinyin")
            elseif choice == "draw" then q:drawCards(1, "hlxg_qinyin") end
        end
    end
end)
hlxg_zhouyu2:addSkill(hlxg_yeyan_zhouyu2); hlxg_zhouyu2:addSkill(hlxg_qinyin)

-- L906 周鲂 (欢乐杀修改): 断发 = engine duanfa (same text), 诱敌.
hlxg_zhoufang = sgs.General(extension_hl, "hlxg_zhoufang", "wu", 3)
hlxg_youdi = gu_trigger("hlxg_youdi", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Finish or owner:isKongcheng() then return end
    local cands = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getOtherPlayers(owner)) do
        if q:canDiscard(owner, "h") then cands:append(q) end
    end
    if cands:isEmpty() then return end
    local q = room:askForPlayerChosen(owner, cands, "hlxg_youdi", "@hlxg_youdi", true, true)
    if not q then return end
    local id = room:askForCardChosen(q, owner, "h", "hlxg_youdi", false, sgs.Card_MethodDiscard)
    if id < 0 then return end
    local card = sgs.Sanguosha:getCard(id)
    room:throwCard(id, "hlxg_youdi", owner, q)
    if owner:isDead() then return end
    if not card:isKindOf("Slash") then
        if q:isAlive() and not q:isNude() then
            local cid = room:askForCardChosen(owner, q, "he", "hlxg_youdi")
            if cid >= 0 then room:obtainCard(owner, cid, "hlxg_youdi", false) end
        end
        if owner:isAlive() then owner:drawCards(1, "hlxg_youdi") end
    end
    if not card:isBlack() and owner:isAlive() and owner:getMaxHp() < 5 then room:gainMaxHp(owner, 1, "hlxg_youdi") end
end)
hlxg_zhoufang:addSkill("duanfa"); hlxg_zhoufang:addSkill(hlxg_youdi)

-- L914 唐姬 (欢乐杀修改): 抗歌, 节烈.
hlxg_tangji = sgs.General(extension_hl, "hlxg_tangji", "qun", 3, false)
local function c204_kangge_target(room, owner) return c204_sp(room, owner:getTag("hlxg_kangge"):toString()) end
hlxg_kangge = gu_trigger("hlxg_kangge", {sgs.TurnStart, sgs.CardsMoveOneTime, sgs.Dying}, function(self, event, room, p, data, owner)
    if event == sgs.TurnStart then
        if p ~= owner then return end
        local old = c204_kangge_target(room, owner)
        if old then room:removePlayerMark(old, "@hlxg_kangge") end
        owner:setTag("hlxg_kangge", sgs.QVariant(""))
        local others = room:getOtherPlayers(owner)
        if others:isEmpty() then return end
        room:sendCompulsoryTriggerLog(owner, "hlxg_kangge", true, true)
        local to = room:askForPlayerChosen(owner, others, "hlxg_kangge", "@hlxg_kangge", false)
        if not to then return end
        owner:setTag("hlxg_kangge", sgs.QVariant(to:objectName()))
        room:addPlayerMark(to, "@hlxg_kangge")
        return
    end
    local k = c204_kangge_target(room, owner)
    if not k then return end
    if event == sgs.CardsMoveOneTime then
        if p ~= owner then return end
        local move = data:toMoveOneTime()
        if not move.to or move.to:objectName() ~= k:objectName() or move.to_place ~= sgs.Player_PlaceHand
            or k:getPhase() ~= sgs.Player_NotActive then return end
        local n = math.min(move.card_ids:length(), 3 - owner:getMark("hlxg_kangge_draw-Clear"))
        if n <= 0 then return end
        room:addPlayerMark(owner, "hlxg_kangge_draw-Clear", n)
        room:sendCompulsoryTriggerLog(owner, "hlxg_kangge", true)
        owner:drawCards(n, "hlxg_kangge")
        return
    end
    local who = data:toDying().who
    if p ~= k or not c204_same(who, k) or k:getHp() >= 1 or owner:getMark("hlxg_kangge_lun") > 0
        or not gu_invoke(owner, "hlxg_kangge", sgs.QVariant(k:objectName())) then return end
    room:setPlayerMark(owner, "hlxg_kangge_lun", 1)
    room:recover(k, sgs.RecoverStruct(owner, nil, 1 - k:getHp(), "hlxg_kangge"))
end, true)
hlxg_jielie = gu_trigger("hlxg_jielie", {sgs.DamageInflicted}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if p ~= owner or not c204_same(d.to, owner) or not gu_invoke(owner, "hlxg_jielie", data) then return end
    local x = d.damage
    room:loseHp(owner, 1, true, owner, "hlxg_jielie")
    if owner:isDead() then return true end
    local suit = room:askForSuit(owner, "hlxg_jielie")
    local k = c204_kangge_target(room, owner)
    if k then
        local pool = sgs.IntList()
        for _, id in sgs.qlist(room:getDiscardPile()) do
            if sgs.Sanguosha:getCard(id):getSuit() == suit then pool:append(id) end
        end
        local got = sgs.IntList()
        while got:length() < x and not pool:isEmpty() do
            local id = c204_pick(pool)
            pool:removeOne(id); got:append(id)
        end
        gu_obtain(room, k, got, "hlxg_jielie")
    end
    return true
end)
hlxg_tangji:addSkill(hlxg_kangge); hlxg_tangji:addSkill(hlxg_jielie)

-- L922 夏侯惇 (欢乐杀修改): 刚烈 = engine ganglie (same effect, synonymous wording).
hlxg_xiahoudun = sgs.General(extension_hl, "hlxg_xiahoudun", "wei", 4)
hlxg_xiahoudun:addSkill("ganglie")

-- L927 夏侯惇 (欢乐杀界限突破): 刚烈 (engine ganglie), 清俭.
hljx_xiahoudun = sgs.General(extension_hl, "hljx_xiahoudun", "wei", 4)
hljx_qingjian = gu_trigger("hljx_qingjian", {sgs.CardsMoveOneTime}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    local move = data:toMoveOneTime()
    if not move.to or move.to:objectName() ~= owner:objectName() or move.to_place ~= sgs.Player_PlaceHand
        or owner:getPhase() == sgs.Player_Draw or owner:getMark("hljx_qingjian-Clear") > 0 or owner:isNude() then return end
    local others = room:getOtherPlayers(owner)
    if others:isEmpty() then return end
    local card = room:askForExchange(owner, "hljx_qingjian", owner:getCards("he"):length(), 1, true, "@hljx_qingjian", true)
    if not card or card:subcardsLength() == 0 then return end
    room:setPlayerMark(owner, "hljx_qingjian-Clear", 1)
    room:notifySkillInvoked(owner, "hljx_qingjian")
    local ids = card:getSubcards()
    room:showCard(owner, ids)
    local to = room:askForPlayerChosen(owner, others, "hljx_qingjian", "@hljx_qingjian-give", false)
    if to then room:giveCard(owner, to, ids, "hljx_qingjian", true) end
    if owner:isAlive() then owner:drawCards(1, "hljx_qingjian") end
end)
hljx_xiahoudun:addSkill("ganglie"); hljx_xiahoudun:addSkill(hljx_qingjian)

-- L935 夏侯氏 (欢乐杀修改): 樵拾, 燕语 (recast 杀; 结束阶段 reward).
hlxg_xiahoushi = sgs.General(extension_hl, "hlxg_xiahoushi", "shu", 3, false)
hlxg_qiaoshi_xiahoushi = gu_trigger("hlxg_qiaoshi_xiahoushi", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p == owner or p:getPhase() ~= sgs.Player_Finish or p:isDead() or p:getHandcardNum() < owner:getHandcardNum()
        or not gu_invoke(owner, "hlxg_qiaoshi_xiahoushi", sgs.QVariant(p:objectName())) then return end
    owner:drawCards(1, "hlxg_qiaoshi_xiahoushi")
    if p:isAlive() then p:drawCards(1, "hlxg_qiaoshi_xiahoushi") end
end)
hlxg_yanyu_xiahoushi_vs = gu_active("hlxg_yanyu_xiahoushi", nil, 1, 1, function() return false end,
    function(self, targets) return #targets == 0 end,
    function(self, room, source, targets)
        room:setPlayerMark(source, "hlxg_yanyu_xiahoushi-Clear", 1)
        room:recastCard(source, self:getSubcards():first(), "hlxg_yanyu_xiahoushi")
    end,
    function(request, c) return c:isKindOf("Slash") end)
hlxg_yanyu_xiahoushi = gu_trigger("hlxg_yanyu_xiahoushi", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Finish or owner:getMark("hlxg_yanyu_xiahoushi-Clear") == 0 then return end
    local others = room:getOtherPlayers(owner)
    local choice = room:askForChoice(owner, "hlxg_yanyu_xiahoushi", others:isEmpty() and "draw+cancel" or "draw+give+cancel")
    if choice == "draw" then
        room:notifySkillInvoked(owner, "hlxg_yanyu_xiahoushi")
        owner:drawCards(1, "hlxg_yanyu_xiahoushi")
    elseif choice == "give" then
        local to = room:askForPlayerChosen(owner, others, "hlxg_yanyu_xiahoushi", "@hlxg_yanyu_xiahoushi", false, true)
        if to then to:drawCards(2, "hlxg_yanyu_xiahoushi") end
    end
end)
hlxg_yanyu_xiahoushi:setViewAsSkill(hlxg_yanyu_xiahoushi_vs)
hlxg_xiahoushi:addSkill(hlxg_qiaoshi_xiahoushi); hlxg_xiahoushi:addSkill(hlxg_yanyu_xiahoushi)

-- L941 夏侯氏 (欢乐杀修改): 樵拾 (the source decides), 燕语 (discard a type, hand out matching cards).
hlxg_xiahoushi2 = sgs.General(extension_hl, "hlxg_xiahoushi2", "shu", 3, false)
hlxg_qiaoshi_xiahoushi2 = gu_trigger("hlxg_qiaoshi_xiahoushi2", {sgs.Damaged}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if p ~= owner or not c204_same(d.to, owner) or not d.from or d.from:isDead() or c204_same(d.from, owner)
        or owner:getMark("hlxg_qiaoshi_xiahoushi2-Clear") > 0 or owner:isDead() then return end
    if not room:askForSkillInvoke(d.from, "hlxg_qiaoshi_xiahoushi2", data) then return end
    room:setPlayerMark(owner, "hlxg_qiaoshi_xiahoushi2-Clear", 1)
    room:recover(owner, sgs.RecoverStruct(d.from, nil, d.damage, "hlxg_qiaoshi_xiahoushi2"))
    if d.from:isAlive() then d.from:drawCards(2, "hlxg_qiaoshi_xiahoushi2") end
end)
hlxg_yanyu_xiahoushi2 = gu_trigger("hlxg_yanyu_xiahoushi2", {sgs.EventPhaseStart, sgs.CardsMoveOneTime}, function(self, event, room, p, data, owner)
    if event == sgs.EventPhaseStart then
        if p:getPhase() ~= sgs.Player_Play or not owner:canDiscard(owner, "he") then return end
        local card = room:askForDiscard(owner, "hlxg_yanyu_xiahoushi2", 1, 1, true, true, "@hlxg_yanyu_xiahoushi2")
        if not card then return end
        local id = card:isVirtualCard() and card:getSubcards():first() or card:getEffectiveId()
        room:setPlayerMark(owner, "hlxg_yanyu_xiahoushi2_type-Clear", sgs.Sanguosha:getCard(id):getTypeId())
        room:setPlayerMark(owner, "hlxg_yanyu_xiahoushi2_id-Clear", id + 1)
        return
    end
    if p ~= owner then return end
    local t = owner:getMark("hlxg_yanyu_xiahoushi2_type-Clear")
    local cur = room:getCurrent()
    if t == 0 or not cur or cur:getPhase() ~= sgs.Player_Play then return end
    local move = data:toMoveOneTime()
    if move.to_place ~= sgs.Player_DiscardPile then return end
    for _, id in sgs.qlist(move.card_ids) do
        if owner:isDead() or owner:getMark("hlxg_yanyu_xiahoushi2_used-Clear") >= 2 then return end
        local c = sgs.Sanguosha:getCard(id)
        if c:getTypeId() == t and id + 1 ~= owner:getMark("hlxg_yanyu_xiahoushi2_id-Clear")
            and room:getCardPlace(id) == sgs.Player_DiscardPile then
            local to = room:askForPlayerChosen(owner, room:getAlivePlayers(), "hlxg_yanyu_xiahoushi2",
                "@hlxg_yanyu_xiahoushi2-give:" .. c:objectName(), true, true)
            if to and room:getCardPlace(id) == sgs.Player_DiscardPile then
                room:addPlayerMark(owner, "hlxg_yanyu_xiahoushi2_used-Clear")
                room:obtainCard(to, id, "hlxg_yanyu_xiahoushi2", true)
            end
        end
    end
end)
hlxg_xiahoushi2:addSkill(hlxg_qiaoshi_xiahoushi2); hlxg_xiahoushi2:addSkill(hlxg_yanyu_xiahoushi2)

-- 神速 (both 夏侯渊 variants): each option is offered when its phase is about to begin.
local function c204_shensu(name, slash_name)
    return gu_trigger(name, {sgs.EventPhaseChanging}, function(self, event, room, p, data, owner)
        if p ~= owner then return end
        local to_phase = data:toPhaseChange().to
        local opt
        if to_phase == sgs.Player_Judge then opt = 1
        elseif to_phase == sgs.Player_Play then opt = 2
        elseif to_phase == sgs.Player_Discard then opt = 3 end
        if not opt or owner:isSkipped(to_phase) then return end
        local slash = sgs.Sanguosha:cloneCard(slash_name, sgs.Card_NoSuit, 0)
        slash:setSkillName(name)
        local targets = sgs.SPlayerList()
        for _, q in sgs.qlist(room:getOtherPlayers(owner)) do
            if owner:canSlash(q, slash, false) then targets:append(q) end
        end
        if targets:isEmpty() then slash:deleteLater(); return end
        local to = room:askForPlayerChosen(owner, targets, name .. opt, "@" .. name .. opt, true)
        if not to then slash:deleteLater(); return end
        room:notifySkillInvoked(owner, name)
        if opt == 1 then owner:skip(sgs.Player_Judge); owner:skip(sgs.Player_Draw)
        elseif opt == 2 then owner:skip(sgs.Player_Play)
        else owner:skip(sgs.Player_Discard); owner:turnOver() end
        if owner:isAlive() and to:isAlive() then
            room:useCard(sgs.CardUseStruct(slash, owner, to), false)
        else
            slash:deleteLater()
        end
    end)
end

-- L949 夏侯渊 (欢乐杀修改): 神速.
hlxg_xiahouyuan = sgs.General(extension_hl, "hlxg_xiahouyuan", "wei", 4)
hlxg_shensu = c204_shensu("hlxg_shensu", "slash")
hlxg_xiahouyuan:addSkill(hlxg_shensu)

-- L954 夏侯渊 (欢乐杀界限突破): 神速 (雷【杀】), 设变.
hljx_xiahouyuan = sgs.General(extension_hl, "hljx_xiahouyuan", "wei", 4)
hljx_shensu = c204_shensu("hljx_shensu", "thunder_slash")
hljx_shebian = gu_trigger("hljx_shebian", {sgs.TurnedOver}, function(self, event, room, p, data, owner)
    if p ~= owner or not room:canMoveField("e") or not gu_invoke(owner, "hljx_shebian") then return end
    if room:moveField(owner, "hljx_shebian", false, "e") and owner:isAlive() and owner:isWounded() then
        room:recover(owner, sgs.RecoverStruct(owner, nil, 1, "hljx_shebian"))
    end
end)
hljx_xiahouyuan:addSkill(hljx_shensu); hljx_xiahouyuan:addSkill(hljx_shebian)

sgs.LoadTranslationTable {
    ["hl_c204_swap-from"] = "请选择被交换装备牌的第一名角色",
    ["@hl_c204_swap-from"] = "请选择被交换装备牌的第一名角色",
    ["@hl_c204_swap-to"] = "请选择与【%src】交换的另一名角色",

    ["hlxg_lvmeng"] = "吕蒙[欢乐修改]", ["&hlxg_lvmeng"] = "吕蒙",
    ["hlxg_keji_lvmeng"] = "克己",
    [":hlxg_keji_lvmeng"] = "若你未于出牌阶段内使用或打出过【杀】，你可以跳过弃牌阶段并摸一张牌。",

    ["hlxg_lvmeng3"] = "吕蒙[欢乐修改2]", ["&hlxg_lvmeng3"] = "吕蒙",
    ["hlxg_keji_lvmeng3"] = "克己",
    [":hlxg_keji_lvmeng3"] = "若你未于出牌阶段内使用或打出过【杀】，你可以跳过弃牌阶段并摸一张牌。",
    ["hlxg_duojing"] = "夺荆",
    [":hlxg_duojing"] = "出牌阶段限两次，你可以与一名其他角色进行“谋弈”：休养生息：你获得其一张牌并回复1点体力，然后你可以摸X张牌并弃置等量的牌（X为你已损失的体力值）；白衣渡江：你视为对其使用一张【杀】（无距离和次数限制且无视防具），然后你本回合可以多使用一张【杀】且修改〖克己〗。<br>〖克己〗（修改）：你可以跳过弃牌阶段并摸一张牌。",
    ["hlxg_duojing:xiuyang"] = "休养生息：获得其一张牌并回复1点体力，然后可以摸X张牌并弃置等量的牌",
    ["hlxg_duojing:baiyi"] = "白衣渡江：视为对其使用一张【杀】，然后本回合可以多使用一张【杀】且修改〖克己〗",
    ["hlxg_duojing:xiuyang2"] = "阻止 休养生息", ["hlxg_duojing:baiyi2"] = "阻止 白衣渡江",
    ["#hlxg_duojingSuccess"] = "%from 对 %to 的“谋弈”成功，执行 %arg",
    ["#hlxg_duojingFail"] = "%from 对 %to 的“谋弈”失败（%arg 被阻止）",
    ["hlxg_duojing_draw"] = "夺荆：你可以摸X张牌并弃置等量的牌",

    ["hljx_lvmeng"] = "吕蒙[欢乐界]", ["&hljx_lvmeng"] = "吕蒙",
    ["hljx_keji"] = "克己",
    [":hljx_keji"] = "若你未于出牌阶段内使用或打出过【杀】，你可以跳过弃牌阶段并摸一张牌。",
    ["hljx_qinxue"] = "勤学",
    [":hljx_qinxue"] = "觉醒技，结束阶段，若你的手牌数不小于体力值的三倍，你将体力上限减少至体力值，然后失去〖克己〗并获得〖攻心〗。",
    ["hljx_botu"] = "博图",
    [":hljx_botu"] = "每轮限X次（X为存活角色数且至多为3），回合结束后，若本回合置入弃牌堆的牌包含四种花色，你可以获得一个额外回合。",
    ["hljx_gongxin"] = "攻心",
    [":hljx_gongxin"] = "每回合限一次，当你使用【杀】或普通锦囊牌指定其他角色为唯一目标后，或成为其他角色使用【杀】或普通锦囊牌的唯一目标后，你可以观看其手牌，然后你可以展示其中的一张红色牌并选择一项：1.获得此牌；2.将此牌置于牌堆顶。",
    ["hljx_gongxin:obtain"] = "获得此牌", ["hljx_gongxin:top"] = "将此牌置于牌堆顶",

    ["hlxg_lvmeng2"] = "神吕蒙[欢乐修改]", ["&hlxg_lvmeng2"] = "神吕蒙",
    ["hlxg_gongxin_lvmeng2"] = "攻心",
    [":hlxg_gongxin_lvmeng2"] = "每回合限一次，当你使用【杀】或普通锦囊牌指定其他角色为唯一目标后，或成为其他角色使用【杀】或普通锦囊牌的唯一目标后，你可以观看其手牌，然后你可以展示其中的一张红色牌并选择一项：1.获得此牌；2.将此牌置于牌堆顶。",
    ["hlxg_gongxin_lvmeng2:obtain"] = "获得此牌", ["hlxg_gongxin_lvmeng2:top"] = "将此牌置于牌堆顶",
    ["hlxg_shelie"] = "涉猎",
    [":hlxg_shelie"] = "锁定技，摸牌阶段，你改为亮出牌堆顶的五张牌，然后获得其中每种花色的牌各一张。",

    ["hlxg_wulan"] = "吴兰[欢乐修改]", ["&hlxg_wulan"] = "吴兰",
    ["hlxg_cuorui"] = "挫锐",
    [":hlxg_cuorui"] = "出牌阶段开始时，你可以弃置一名距离不大于1的角色区域里的一张牌，然后选择一项：1.弃置另一名其他角色装备区里所有与此牌颜色相同的牌；2.弃置另一名其他角色的至多两张手牌，然后获得其中与此牌颜色相同的牌。",
    ["@hlxg_cuorui"] = "挫锐：你可以弃置一名距离不大于1的角色区域里的一张牌",
    ["hlxg_cuorui:equip"] = "弃置另一名其他角色装备区里所有同色牌",
    ["hlxg_cuorui:hand"] = "弃置另一名其他角色至多两张手牌并获得其中同色牌",
    ["@hlxg_cuorui-equip"] = "挫锐：选择另一名其他角色，弃置其装备区里所有同色牌",
    ["@hlxg_cuorui-hand"] = "挫锐：选择另一名其他角色，弃置其至多两张手牌",

    ["hlxg_wuguotai"] = "吴国太[欢乐修改]", ["&hlxg_wuguotai"] = "吴国太",
    ["hlxg_ganlu"] = "甘露",
    [":hlxg_ganlu"] = "锁定技，出牌阶段开始时，你选择一项：1.移动场上的一张装备牌；2.交换场上两张副类别相同的装备牌；3.摸一张牌。",
    ["hlxg_ganlu:move"] = "移动场上的一张装备牌", ["hlxg_ganlu:swap"] = "交换场上两张副类别相同的装备牌", ["hlxg_ganlu:draw"] = "摸一张牌",
    ["hlxg_buyi"] = "补益",
    [":hlxg_buyi"] = "每回合限三次，当一名角色进入濒死状态时，你可以展示其一张手牌，若此牌为基本牌，其弃置此牌，然后回复1点体力。",

    ["hljx_wuguotai"] = "吴国太[欢乐界]", ["&hljx_wuguotai"] = "吴国太",
    ["hljx_ganlu"] = "甘露",
    [":hljx_ganlu"] = "锁定技，出牌阶段开始时，你选择一项：1.摸两张牌，然后可以移动场上的一张装备牌或交换场上两张副类别相同的装备牌；2.令两名角色交换装备区里的牌，然后若他们装备区里的牌数之差大于你的体力上限，你弃置一张牌。",
    ["hljx_ganlu:draw"] = "摸两张牌，然后可以移动或交换场上的装备牌", ["hljx_ganlu:exchange"] = "令两名角色交换装备区里的牌",
    ["hljx_ganlu_more"] = "甘露",
    ["hljx_ganlu_more:move"] = "移动场上的一张装备牌", ["hljx_ganlu_more:swap"] = "交换场上两张副类别相同的装备牌",
    ["@hljx_ganlu-exchange"] = "甘露：选择两名角色交换装备区里的牌",
    ["hljx_buyi"] = "补益",
    [":hljx_buyi"] = "每回合限三次，当一名角色进入濒死状态时，你可以令其摸一张牌（若其有手牌则跳过），然后观看其手牌，展示并弃置其中任意张，令其回复X点体力（X为展示牌中的基本牌数）。",

    ["hlxg_wuxian"] = "吴苋[欢乐修改]", ["&hlxg_wuxian"] = "吴苋",
    ["hlxg_daiyan"] = "怠宴",
    [":hlxg_daiyan"] = "结束阶段，你可以令一名其他角色从牌堆或弃牌堆中获得一张红桃基本牌，然后若其不是上回合此技能选择的角色，你摸一张牌。",
    ["@hlxg_daiyan"] = "怠宴：你可以令一名其他角色获得一张红桃基本牌",
    ["hlxg_fumian"] = "福绵",
    [":hlxg_fumian"] = "准备阶段，你可以选择一项：1.本回合摸牌阶段多摸一张牌；2.本回合使用红色牌可以多选择一个目标（无距离限制）。若你选择的选项与你上回合选择的选项不同，则该选项数值+1并复原此技能。",
    ["hlxg_fumian:draw"] = "本回合摸牌阶段多摸牌", ["hlxg_fumian:target"] = "本回合使用红色牌可以多选择目标",
    ["&hlxg_fumian_draw-Clear"] = "福绵摸牌", ["&hlxg_fumian_target-Clear"] = "福绵目标",
    ["@hlxg_fumian"] = "福绵：你可以为【%src】增加额外目标（无距离限制）",

    ["hlxg_zhoucang"] = "周仓[欢乐修改]", ["&hlxg_zhoucang"] = "周仓",
    ["hlxg_daopu"] = "刀仆",
    [":hlxg_daopu"] = "锁定技，若你的装备区里：没有武器牌，你视为装备着【青龙偃月刀】；有【青龙偃月刀】，你使用红色【杀】造成的伤害+1。",
    ["hlxg_zhongyong"] = "忠勇",
    [":hlxg_zhongyong"] = "当你对其他角色使用【杀】结算结束后，你可以将此【杀】和目标角色使用的【闪】交给另一名其他角色，然后若你交给其的牌中包含：红色牌，其可以对你攻击范围内的一名角色使用一张【杀】；黑色牌，你与其各摸一张牌。",
    ["@hlxg_zhongyong"] = "忠勇：你可以将此【杀】和目标角色使用的【闪】交给另一名其他角色",
    ["@hlxg_zhongyong-slash"] = "忠勇：你可以对%src攻击范围内的一名角色使用一张【杀】",

    ["hlxg_zhoufei"] = "周妃[欢乐修改]", ["&hlxg_zhoufei"] = "周妃",
    ["hlxg_liangyin"] = "良姻",
    [":hlxg_liangyin"] = "当有牌移出游戏后，你可以令一名角色摸一张牌；当有牌从游戏外移至一名角色的手牌区后，你可以令一名角色弃置一张牌。",
    ["@hlxg_liangyin-draw"] = "良姻：你可以令一名角色摸一张牌",
    ["@hlxg_liangyin-discard"] = "良姻：你可以令一名角色弃置一张牌",

    ["hlxg_zhoufei2"] = "周妃[欢乐修改2]", ["&hlxg_zhoufei2"] = "周妃",
    ["hlxg_lingkong"] = "灵箜",
    [":hlxg_lingkong"] = "锁定技，游戏开始时，你的起始手牌增加“箜篌”标记。“箜篌”不计入你的手牌上限。当你每回合首次于摸牌阶段外获得牌后，将这些牌标记为“箜篌”。",
    ["hlxg_konghou"] = "箜篌",
    ["hlxg_xianshu"] = "贤淑",
    [":hlxg_xianshu"] = "出牌阶段，你可以将一张“箜篌”交给一名其他角色，然后摸X张牌（X为你与其体力值之差，至少为1且至多为5），若此牌为：红色，且其体力值不大于你，其回复1点体力；黑色，且其体力值不小于你，其失去1点体力。",

    ["hlxg_zhoutai"] = "周泰[欢乐修改]", ["&hlxg_zhoutai"] = "周泰",
    ["hlxg_buqu"] = "不屈",
    [":hlxg_buqu"] = "锁定技，当你处于濒死状态时，若“创”的数量小于4，你获得1枚“创”并将体力回复至1点。你的手牌上限+X（X为“创”的数量）。",
    ["@hlxg_buqu"] = "创",
    ["hlxg_fenji"] = "奋激",
    [":hlxg_fenji"] = "当一名角色因另一名角色的弃置或获得而失去手牌后，你可以失去1点体力，然后失去手牌的角色摸两张牌。",

    ["hljx_zhoutai"] = "周泰[欢乐界]", ["&hljx_zhoutai"] = "周泰",
    ["hljx_buqu"] = "不屈",
    [":hljx_buqu"] = "锁定技，当你受到伤害或失去体力时，若“创”的数量小于4，你获得1枚“创”并防止之。你的手牌上限+X（X为“创”的数量）。",
    ["@hljx_buqu"] = "创",
    ["hljx_fenji"] = "奋激",
    [":hljx_fenji"] = "当一名角色因另一名角色的弃置或获得而失去手牌后，你可以失去1点体力，然后失去手牌的角色摸两张牌。",
    ["hljx_qingchuang"] = "清创",
    [":hljx_qingchuang"] = "出牌阶段限一次，你可以弃置一张【桃】或【酒】并弃1枚“创”，然后摸一张牌。",

    ["hlxg_zhouyu"] = "周瑜[欢乐修改]", ["&hlxg_zhouyu"] = "周瑜",
    ["hlxg_fanjian"] = "反间",
    [":hlxg_fanjian"] = "出牌阶段开始时，你可以令一名角色摸一张牌，然后对其造成1点伤害。",
    ["@hlxg_fanjian"] = "反间：你可以令一名角色摸一张牌，然后对其造成1点伤害",

    ["hljx_zhouyu"] = "周瑜[欢乐界]", ["&hljx_zhouyu"] = "周瑜",
    ["hljx_fanjian"] = "反间",
    [":hljx_fanjian"] = "出牌阶段限一次，你可以秘密选择一种手牌中有的花色，令一名其他角色选择一种花色，若花色相同，其摸一张牌。若如此做，你对其造成1点伤害。",
    ["#hljx_fanjianLog"] = "%from 秘密选择的花色为 %arg，%to 选择的花色为 %arg2",
    ["hljx_yingzi_zhouyu"] = "英姿",
    [":hljx_yingzi_zhouyu"] = "锁定技，摸牌阶段，你多摸X张牌；你的手牌上限等于你的体力上限+X（X为你满足的条件数且至少为1：手牌数不小于2、体力值不小于2、装备区里的牌数不小于1）。",

    ["hlxg_zhouyu2"] = "神周瑜[欢乐修改]", ["&hlxg_zhouyu2"] = "神周瑜",
    ["hlxg_yeyan_zhouyu2"] = "业炎",
    [":hlxg_yeyan_zhouyu2"] = "出牌阶段开始时，你可以对一名其他角色造成1点火焰伤害。",
    ["@hlxg_yeyan_zhouyu2"] = "业炎：你可以对一名其他角色造成1点火焰伤害",
    ["hlxg_qinyin"] = "琴音",
    [":hlxg_qinyin"] = "弃牌阶段结束时，若有角色于此回合内弃置过你的牌，你可以选择一项：1.令所有角色各回复1点体力；2.令所有角色各失去1点体力；3.令所有角色各摸一张牌。",
    ["hlxg_qinyin:recover"] = "令所有角色各回复1点体力", ["hlxg_qinyin:lose"] = "令所有角色各失去1点体力", ["hlxg_qinyin:draw"] = "令所有角色各摸一张牌",

    ["hlxg_zhoufang"] = "周鲂[欢乐修改]", ["&hlxg_zhoufang"] = "周鲂",
    ["hlxg_youdi"] = "诱敌",
    [":hlxg_youdi"] = "结束阶段，你可以令一名其他角色弃置你一张手牌，若此牌不为：【杀】，你获得其一张牌并摸一张牌；黑色，你加1点体力上限（至多加至5）。",
    ["@hlxg_youdi"] = "诱敌：你可以令一名其他角色弃置你一张手牌",

    ["hlxg_tangji"] = "唐姬[欢乐修改]", ["&hlxg_tangji"] = "唐姬",
    ["hlxg_kangge"] = "抗歌",
    [":hlxg_kangge"] = "回合开始时，你选择一名其他角色直到你的下回合开始：1.当其于其回合外获得手牌后，你摸等量的牌（每回合至多摸三张）；2.每轮限一次，当其进入濒死状态时，你可以令其将体力回复至1点。",
    ["@hlxg_kangge"] = "抗歌：选择一名其他角色",
    ["hlxg_jielie"] = "节烈",
    [":hlxg_jielie"] = "当你受到伤害时，你可以改为失去1点体力并选择一种花色，然后令〖抗歌〗选择的角色从弃牌堆中随机获得X张此花色的牌（X为伤害值）。",

    ["hlxg_xiahoudun"] = "夏侯惇[欢乐修改]", ["&hlxg_xiahoudun"] = "夏侯惇",

    ["hljx_xiahoudun"] = "夏侯惇[欢乐界]", ["&hljx_xiahoudun"] = "夏侯惇",
    ["hljx_qingjian"] = "清俭",
    [":hljx_qingjian"] = "每回合限一次，当你于摸牌阶段外获得牌后，你可以展示任意张牌并将这些牌交给一名其他角色，然后你摸一张牌。",
    ["@hljx_qingjian"] = "清俭：你可以展示任意张牌并交给一名其他角色",
    ["@hljx_qingjian-give"] = "清俭：将这些牌交给一名其他角色",

    ["hlxg_xiahoushi"] = "夏侯氏[欢乐修改]", ["&hlxg_xiahoushi"] = "夏侯氏",
    ["hlxg_qiaoshi_xiahoushi"] = "樵拾",
    [":hlxg_qiaoshi_xiahoushi"] = "其他角色的结束阶段，若其手牌数不小于你，你可以与其各摸一张牌。",
    ["hlxg_yanyu_xiahoushi"] = "燕语",
    [":hlxg_yanyu_xiahoushi"] = "出牌阶段，你可以重铸【杀】。结束阶段，若你于出牌阶段内重铸过【杀】，你可以选择一项：1.摸一张牌；2.令一名其他角色摸两张牌。",
    ["hlxg_yanyu_xiahoushi:draw"] = "摸一张牌", ["hlxg_yanyu_xiahoushi:give"] = "令一名其他角色摸两张牌",
    ["@hlxg_yanyu_xiahoushi"] = "燕语：令一名其他角色摸两张牌",

    ["hlxg_xiahoushi2"] = "夏侯氏[欢乐修改2]", ["&hlxg_xiahoushi2"] = "夏侯氏",
    ["hlxg_qiaoshi_xiahoushi2"] = "樵拾",
    [":hlxg_qiaoshi_xiahoushi2"] = "每回合限一次，当你受到其他角色造成的伤害后，伤害来源可以令你回复等同此次伤害值的体力，然后其摸两张牌。",
    ["hlxg_yanyu_xiahoushi2"] = "燕语",
    [":hlxg_yanyu_xiahoushi2"] = "一名角色的出牌阶段开始时，你可以弃置一张牌。若如此做，此回合限两次，当一张与你弃置牌类别相同的其他牌于出牌阶段内进入弃牌堆后，你可以令一名角色获得之。",
    ["@hlxg_yanyu_xiahoushi2"] = "燕语：你可以弃置一张牌",
    ["@hlxg_yanyu_xiahoushi2-give"] = "燕语：你可以令一名角色获得【%src】",

    ["hlxg_xiahouyuan"] = "夏侯渊[欢乐修改]", ["&hlxg_xiahouyuan"] = "夏侯渊",
    ["hlxg_shensu"] = "神速",
    [":hlxg_shensu"] = "你可以做出如下选择：1.跳过判定阶段和摸牌阶段；2.跳过出牌阶段；3.跳过弃牌阶段并翻面。你每选择一项，便视为使用一张无距离限制的【杀】。",
    ["hlxg_shensu1"] = "神速", ["hlxg_shensu2"] = "神速", ["hlxg_shensu3"] = "神速",
    ["@hlxg_shensu1"] = "神速：你可以跳过判定阶段和摸牌阶段，视为使用一张无距离限制的【杀】",
    ["@hlxg_shensu2"] = "神速：你可以跳过出牌阶段，视为使用一张无距离限制的【杀】",
    ["@hlxg_shensu3"] = "神速：你可以跳过弃牌阶段并翻面，视为使用一张无距离限制的【杀】",

    ["hljx_xiahouyuan"] = "夏侯渊[欢乐界]", ["&hljx_xiahouyuan"] = "夏侯渊",
    ["hljx_shensu"] = "神速",
    [":hljx_shensu"] = "你可以做出如下选择：1.跳过判定阶段和摸牌阶段；2.跳过出牌阶段；3.跳过弃牌阶段并翻面。你每选择一项，便视为使用一张无距离限制的雷【杀】。",
    ["hljx_shensu1"] = "神速", ["hljx_shensu2"] = "神速", ["hljx_shensu3"] = "神速",
    ["@hljx_shensu1"] = "神速：你可以跳过判定阶段和摸牌阶段，视为使用一张无距离限制的雷【杀】",
    ["@hljx_shensu2"] = "神速：你可以跳过出牌阶段，视为使用一张无距离限制的雷【杀】",
    ["@hljx_shensu3"] = "神速：你可以跳过弃牌阶段并翻面，视为使用一张无距离限制的雷【杀】",
    ["hljx_shebian"] = "设变",
    [":hljx_shebian"] = "当你翻面时，你可以移动场上的一张装备牌，然后回复1点体力。",
}
end

-- ==================== c202_01
do
-- c202_01: literal Guan Yu variants.
local function c202_slash(name, predicate, response, red)
    return sgs.CreateViewAsSkillV2 {
        name = name, n = 1, response_or_use = response,
        can_activate = function(self, request)
            if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return true end
            return response and request:getPattern() == "slash"
        end,
        can_select_card = function(self, request, card)
            return request:getSelectedCardIds():isEmpty() and predicate(request:getInitiator(), card)
        end,
        card_selection_feasible = function(self, request) return request:getSelectedCardIds():length() == 1 end,
        create_card = function(self, request)
            local original = sgs.Sanguosha:getCard(request:getSelectedCardIds():first())
            local suit = original:getSuit()
            if red and not original:isRed() then suit = sgs.Card_Heart end
            local card = sgs.Sanguosha:cloneCard("slash", suit, original:getNumber())
            card:addSubcards(request:getSelectedCardIds()); card:setSkillName(name)
            return card
        end,
    }
end
local function c202_red_damage(room, data, owner, heart)
    local damage = data:toDamage()
    if damage.from == owner and damage.card and damage.card:isKindOf("Slash")
        and (heart and damage.card:getSuit() == sgs.Card_Heart or not heart and damage.card:isRed()) then
        damage.damage = damage.damage + 1; data:setValue(damage)
    end
end
hlxg_guanyu = sgs.General(extension_hl, "hlxg_guanyu", "shu", 4)
hlxg_wusheng_guanyu = c202_slash("hlxg_wusheng_guanyu", function(p, c)
    return p:getMark("hlxg_wusheng_guanyu_id-Clear") == c:getEffectiveId() + 1
end, false, true)
hlxg_wusheng_guanyu_trigger = gu_trigger("#hlxg_wusheng_guanyu_trigger", {sgs.TurnStart, sgs.CardsMoveOneTime, sgs.DamageCaused}, function(self, event, room, p, data, owner)
    if event == sgs.CardsMoveOneTime then
        local move = data:toMoveOneTime()
        if owner:getMark("hlxg_wusheng_guanyu_drawing") > 0 and move.to == owner
            and move.to_place == sgs.Player_PlaceHand and not move.card_ids:isEmpty() then
            room:setPlayerMark(owner, "hlxg_wusheng_guanyu_id-Clear", move.card_ids:first() + 1)
        end
    elseif event == sgs.DamageCaused then c202_red_damage(room, data, owner, false)
    elseif p == owner and gu_invoke(owner, "hlxg_wusheng_guanyu", data) then
        room:setPlayerMark(owner, "hlxg_wusheng_guanyu_id-Clear", 0)
        room:setPlayerMark(owner, "hlxg_wusheng_guanyu_drawing", 1)
        owner:drawCards(1, "hlxg_wusheng_guanyu")
        room:setPlayerMark(owner, "hlxg_wusheng_guanyu_drawing", 0)
        local id = owner:getMark("hlxg_wusheng_guanyu_id-Clear") - 1
        if id >= 0 then room:showCard(owner, id) end
    end
end)
hlxg_guanyu:addSkill(hlxg_wusheng_guanyu)
hlxg_guanyu:addSkill(hlxg_wusheng_guanyu_trigger)
extension_hl:insertRelatedSkills("hlxg_wusheng_guanyu", "#hlxg_wusheng_guanyu_trigger")

hljx_guanyu = sgs.General(extension_hl, "hljx_guanyu", "shu", 4)
hljx_guanjue = gu_trigger("hljx_guanjue", {sgs.CardUsed, sgs.CardResponded}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    local card = event == sgs.CardUsed and data:toCardUse().card or data:toCardResponse().m_card
    if not card then return end
    for _, other in sgs.qlist(room:getOtherPlayers(owner)) do
        room:setPlayerMark(other, "hljx_guanjue_" .. card:getSuitString() .. "-Clear", 1)
    end
end, true)
hljx_guanjue_limit = sgs.CreateCardLimitSkill {
    name = "#hljx_guanjue_limit",
    limit_list = function(self, p) return "use,response" end,
    limit_pattern = function(self, p)
        local suits = {}
        for _, suit in ipairs({"spade", "club", "heart", "diamond", "no_suit"}) do
            if p:getMark("hljx_guanjue_" .. suit .. "-Clear") > 0 then table.insert(suits, suit) end
        end
        return #suits > 0 and ".|" .. table.concat(suits, "+") or ""
    end,
}
hljx_tuodao = gu_trigger("hljx_tuodao", {sgs.CardUsed, sgs.CardResponded, sgs.DamageCaused}, function(self, event, room, p, data, owner)
    if event == sgs.DamageCaused then
        local damage = data:toDamage()
        if damage.from == owner and damage.card and damage.card:hasFlag("hljx_tuodao_bonus") then
            damage.damage = damage.damage + damage.card:getTag("hljx_tuodao_bonus"):toInt(); data:setValue(damage)
        end
        return
    end
    if p ~= owner then return end
    local card = event == sgs.CardUsed and data:toCardUse().card or data:toCardResponse().m_card
    if not card then return end
    if card:isKindOf("Jink") then room:addPlayerMark(owner, "hljx_tuodao_pending")
    elseif event == sgs.CardUsed and card:isKindOf("Slash") then
        local n = owner:getMark("hljx_tuodao_pending")
        -- Reset a reused physical Slash's previous bonus on every use.
        card:setTag("hljx_tuodao_bonus", sgs.QVariant(n))
        room:setCardFlag(card, n > 0 and "hljx_tuodao_bonus" or "-hljx_tuodao_bonus")
        room:setPlayerMark(owner, "hljx_tuodao_pending", 0)
    end
end, true)
hljx_wusheng = c202_slash("hljx_wusheng", function(p, c) return c:isRed() end, true, false)
hljx_wusheng_trigger = gu_trigger("#hljx_wusheng_trigger", {sgs.TurnStart, sgs.DamageCaused}, function(self, event, room, p, data, owner)
    if event == sgs.DamageCaused then c202_red_damage(room, data, owner, false)
    elseif p == owner then
        for _, pile in ipairs({room:getDrawPile(), room:getDiscardPile()}) do
            for _, id in sgs.qlist(pile) do
                if sgs.Sanguosha:getCard(id):isRed() then
                    local ids = sgs.IntList(); ids:append(id); gu_obtain(room, owner, ids, "hljx_wusheng"); return
                end
            end
        end
    end
end, true)
hljx_guanyu:addSkill(hljx_guanjue); hljx_guanyu:addSkill(hljx_guanjue_limit)
hljx_guanyu:addSkill(hljx_tuodao); hljx_guanyu:addSkill(hljx_wusheng); hljx_guanyu:addSkill(hljx_wusheng_trigger)
extension_hl:insertRelatedSkills("hljx_guanjue", "#hljx_guanjue_limit")
extension_hl:insertRelatedSkills("hljx_wusheng", "#hljx_wusheng_trigger")

hlxg_guanyu2 = sgs.General(extension_hl, "hlxg_guanyu2", "god", 5)
hlxg_wushen = c202_slash("hlxg_wushen", function(p, c)
    return c:getSuit() == sgs.Card_Heart and p:handCards():contains(c:getEffectiveId())
end, true, false)
hlxg_wushen_damage = gu_trigger("#hlxg_wushen_damage", {sgs.DamageCaused}, function(self, event, room, p, data, owner)
    c202_red_damage(room, data, owner, true)
end)
hlxg_wushen_mod = sgs.CreateTargetModSkillV2 {
    name = "#hlxg_wushen_mod", pattern = "Slash", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local from, card = ctx:getFrom(), ctx:getCard()
        if ctx:getModType() == sgs.TargetModSkill_DistanceLimit and from and from:hasSkill("hlxg_wushen")
            and card and card:getSuit() == sgs.Card_Heart then return 999 end
        return 0
    end,
}
-- Death must also trigger for the dead owner; gu_trigger only enumerates living owners.
hlxg_wuhun = sgs.CreateTriggerSkillV2 {
    name = "hlxg_wuhun", frequency = sgs.Skill_Compulsory,
    events = {sgs.Damaged, sgs.QuitDying, sgs.Death},
    can_trigger = function(self, event, room, player, data)
        if not player or not player:hasSkill(self:objectName()) then return false end
        if event == sgs.Death and data:toDeath().who ~= player then return false end
        return self:objectName(), player
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        if event == sgs.Damaged then
            local damage = data:toDamage()
            if damage.from then room:addPlayerMark(damage.from, "@hlxg_wuhun", damage.damage) end
            return false
        end
        local candidates, maximum = sgs.SPlayerList(), -1
        for _, other in sgs.qlist(room:getAlivePlayers()) do
            if other ~= player then
                local n = other:getMark("@hlxg_wuhun")
                if n > maximum then candidates = sgs.SPlayerList(); maximum = n end
                if n == maximum then candidates:append(other) end
            end
        end
        if not candidates:isEmpty() then
            local target = room:askForPlayerChosen(player, candidates, "hlxg_wuhun", "@hlxg_wuhun-target", false, true)
            local judge = sgs.JudgeStruct(); judge.who = target; judge.reason = "hlxg_wuhun"
            judge.pattern = "Peach,GodSalvation"; judge.good = true; room:judge(judge)
            if judge.card and not judge.card:isKindOf("Peach") and not judge.card:isKindOf("GodSalvation") then
                room:loseHp(target, 5, true, player, "hlxg_wuhun")
            end
        end
        for _, other in sgs.qlist(room:getAllPlayers()) do room:setPlayerMark(other, "@hlxg_wuhun", 0) end
        return false
    end,
}
hlxg_guanyu2:addSkill(hlxg_wushen); hlxg_guanyu2:addSkill(hlxg_wushen_damage)
hlxg_guanyu2:addSkill(hlxg_wushen_mod); hlxg_guanyu2:addSkill(hlxg_wuhun)
extension_hl:insertRelatedSkills("hlxg_wushen", "#hlxg_wushen_damage")
extension_hl:insertRelatedSkills("hlxg_wushen", "#hlxg_wushen_mod")
sgs.LoadTranslationTable {
    ["hlxg_guanyu"] = "关羽[欢乐修改]", ["&hlxg_guanyu"] = "关羽",
    ["hljx_guanyu"] = "关羽[欢乐界]", ["&hljx_guanyu"] = "关羽",
    ["hlxg_guanyu2"] = "神关羽[欢乐修改]", ["&hlxg_guanyu2"] = "关羽",
    ["hlxg_wusheng_guanyu"] = "武圣",
    [":hlxg_wusheng_guanyu"] = "回合开始时，你可以摸一张牌并展示之，本回合你可以将此牌当红色【杀】使用；你使用红色【杀】造成的伤害+1。",
    ["hljx_guanjue"] = "冠绝",
    [":hljx_guanjue"] = "锁定技，当你使用或打出一张牌时，你令所有其他角色于此回合内不能使用或打出花色与之相同的牌。",
    ["hljx_tuodao"] = "拖刀",
    [":hljx_tuodao"] = "锁定技，当你使用或打出一张【闪】时，你使用的下一张【杀】造成的伤害+1。",
    ["hljx_wusheng"] = "武圣",
    [":hljx_wusheng"] = "回合开始时，你从牌堆或弃牌堆中获得一张红色牌；你可以将一张红色牌当【杀】使用或打出；你使用红色【杀】造成的伤害+1。",
    ["hlxg_wushen"] = "武神",
    [":hlxg_wushen"] = "你可以将一张红桃手牌当【杀】使用或打出。你使用红桃【杀】无距离限制且伤害+1。",
    ["hlxg_wuhun"] = "武魂", ["@hlxg_wuhun"] = "梦魇",
    ["@hlxg_wuhun-target"] = "武魂：选择梦魇最多的一名其他角色进行判定",
    [":hlxg_wuhun"] = "锁定技，当你受到1点伤害后，你令伤害来源获得1枚“梦魇”；当你脱离濒死状态或死亡时，你令拥有最多“梦魇”的一名其他角色进行判定：若结果不为【桃】或【桃园结义】，其失去5点体力，然后弃所有“梦魇”。",
}
end

-- ==================== c202_02
do
-- c202_02: Q.SHU-002 is skipped: its required card text is unspecified.
hlxg_guanyu3 = sgs.General(extension_hl, "hlxg_guanyu3", "wei", 4)
hlxg_guanyinping = sgs.General(extension_hl, "hlxg_guanyinping", "shu", 3, false)

hlxg_danqi = gu_trigger("hlxg_danqi", {sgs.CardUsed, sgs.CardResponded, sgs.Damage},
    function(self, event, room, p, data, owner)
        if p ~= owner or owner:getMark("hlxg_danqi") > 0 then return end
        if event == sgs.Damage then
            local d = data:toDamage()
            if d.from ~= owner then return end
            room:addPlayerMark(owner, "hlxg_danqi_damage", d.damage)
        else
            local c
            if event == sgs.CardUsed then c = data:toCardUse().card
            else c = data:toCardResponse().m_card end
            if not c or c:getTypeId() == sgs.Card_TypeSkill then return end
            room:addPlayerMark(owner, "hlxg_danqi_cards")
        end
        if owner:getMark("hlxg_danqi_cards") < 5 and owner:getMark("hlxg_danqi_damage") < 6 then return end
        room:setPlayerMark(owner, "hlxg_danqi", 1)
        room:doSuperLightbox(owner, "hlxg_danqi")
        local r = sgs.RecoverStruct(); r.who = owner; r.recover = owner:getMaxHp() - owner:getHp()
        if r.recover > 0 then room:recover(owner, r) end
        room:handleAcquireDetachSkills(owner, "hlxg_yuma_guanyu3|hlxg_nuzhan")
    end, true, sgs.Skill_Wake)

local function hlxg_trick_slash(c)
    if not c or not c:isKindOf("Slash") or not c:isVirtualCard() or c:getSubcards():isEmpty() then return false end
    for _, id in sgs.qlist(c:getSubcards()) do
        if not sgs.Sanguosha:getEngineCard(id):isKindOf("TrickCard") then return false end
    end
    return true
end
hlxg_nuzhan = gu_trigger("hlxg_nuzhan", {sgs.DamageCaused, sgs.CardFinished, sgs.PostCardResponded, sgs.EventPhaseChanging},
    function(self, event, room, p, data, owner)
        if p ~= owner then return end
        if event == sgs.EventPhaseChanging then
            room:setPlayerMark(owner, "hlxg_nuzhan_phase", 0)
        elseif event == sgs.DamageCaused then
            local d = data:toDamage()
            if d.from == owner and hlxg_trick_slash(d.card) then d.damage = d.damage + 1; data:setValue(d) end
        else
            local c
            if event == sgs.PostCardResponded then
                local response = data:toCardResponse()
                if not response.m_isUse then return end
                c = response.m_card
            else c = data:toCardUse().card end
            if c and c:isKindOf("Slash") and not hlxg_trick_slash(c) then room:addPlayerMark(owner, "hlxg_nuzhan_phase") end
        end
    end, true)
hlxg_nuzhan_mod = sgs.CreateTargetModSkillV2 {
    name = "#hlxg_nuzhan_mod", pattern = "Slash", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local p = ctx:getPrimary()
        if p and p:hasSkill("hlxg_nuzhan") and ctx:getModType() == sgs.TargetModSkill_Residue then
            return p:getMark("hlxg_nuzhan_phase")
        end
        return 0
    end,
}

hlxg_wusheng_guanyu3 = sgs.CreateViewAsSkillV2 {
    name = "hlxg_wusheng_guanyu3", n = 1,
    can_activate = function(self, request)
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return sgs.Slash_IsAvailable(request:getInitiator())
        end
        return request:getPattern() == "slash"
    end,
    can_select_card = function(self, request, c)
        return request:getSelectedCardIds():isEmpty() and c:isRed() and not c:hasFlag("using")
    end,
    create_card = function(self, request)
        local ids = request:getSelectedCardIds(); if ids:length() ~= 1 then return nil end
        local original = sgs.Sanguosha:getCard(ids:first())
        local c = sgs.Sanguosha:cloneCard("slash", original:getSuit(), original:getNumber())
        c:addSubcards(ids); c:setSkillName("hlxg_wusheng_guanyu3"); return c
    end,
}
hlxg_wusheng_guanyu3_effect = gu_trigger("#hlxg_wusheng_guanyu3_effect", {sgs.EventPhaseStart, sgs.DamageCaused},
    function(self, event, room, p, data, owner)
        if p ~= owner or not owner:hasSkill("hlxg_wusheng_guanyu3") then return end
        if event == sgs.EventPhaseStart then
            if owner:getPhase() ~= sgs.Player_RoundStart then return end
            local ids = sgs.IntList()
            for _, pile in ipairs({room:getDrawPile(), room:getDiscardPile()}) do
                for _, id in sgs.qlist(pile) do
                    if sgs.Sanguosha:getCard(id):isRed() then ids:append(id) end
                end
            end
            if not ids:isEmpty() then room:obtainCard(owner, ids:at(math.random(0, ids:length() - 1)), false) end
        else
            local d = data:toDamage(); local c = d.card
            if d.from == owner and c and c:isKindOf("Slash") and c:isRed() and not c:isVirtualCard()
                and c:getSkillName() == "" then d.damage = d.damage + 1; data:setValue(d) end
        end
    end, true)
hlxg_wusheng_guanyu3_mod = sgs.CreateTargetModSkillV2 {
    name = "#hlxg_wusheng_guanyu3_mod", pattern = "Slash", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local p, c = ctx:getPrimary(), ctx:getCard()
        if p and p:hasSkill("hlxg_wusheng_guanyu3") and c and c:getSuit() == sgs.Card_Diamond
            and ctx:getModType() == sgs.TargetModSkill_DistanceLimit then return 1000 end
        return 0
    end,
}
hlxg_yuma_guanyu3 = gu_trigger("hlxg_yuma_guanyu3", {sgs.CardsMoveOneTime},
    function(self, event, room, p, data, owner)
        local m = data:toMoveOneTime()
        if not m.from or m.from:objectName() ~= owner:objectName() then return end
        local n = 0
        for i = 0, m.card_ids:length() - 1 do
            local c = sgs.Sanguosha:getEngineCard(m.card_ids:at(i))
            if m.from_places:at(i) == sgs.Player_PlaceEquip and (c:isKindOf("OffensiveHorse") or c:isKindOf("DefensiveHorse")) then n = n + 1 end
        end
        for i = 1, n do if owner:isAlive() then owner:drawCards(2, "hlxg_yuma_guanyu3") end end
    end, true)
hlxg_yuma_guanyu3_distance = sgs.CreateDistanceSkillV2 {
    name = "#hlxg_yuma_guanyu3_distance", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local p = ctx:getPrimary()
        if p and p:hasSkill("hlxg_yuma_guanyu3") then return -1 end
        return 0
    end,
}

hlxg_wuji = gu_trigger("hlxg_wuji", {sgs.Damage, sgs.EventPhaseStart},
    function(self, event, room, p, data, owner)
        if p ~= owner then return end
        if event == sgs.Damage then
            local d = data:toDamage()
            if d.from == owner then room:addPlayerMark(owner, "hlxg_wuji_damage-Clear", d.damage) end
            return
        end
        if owner:getPhase() ~= sgs.Player_Finish or owner:getMark("hlxg_wuji") > 0
            or owner:getMark("hlxg_wuji_damage-Clear") < 3 then return end
        room:setPlayerMark(owner, "hlxg_wuji", 1); room:doSuperLightbox(owner, "hlxg_wuji")
        room:setPlayerProperty(owner, "maxhp", sgs.QVariant(owner:getMaxHp() + 1))
        local r = sgs.RecoverStruct(); r.who = owner; r.recover = 1; room:recover(owner, r)
        owner:drawCards(2, "hlxg_wuji")
    end, true, sgs.Skill_Wake)
hlxg_huxiao = gu_trigger("hlxg_huxiao", {sgs.Damage},
    function(self, event, room, p, data, owner)
        local d = data:toDamage()
        if d.from == owner and d.to and d.nature == sgs.DamageStruct_Fire then
            room:setPlayerMark(owner, "hlxg_huxiao_" .. d.to:objectName() .. "-Clear", 1)
        end
    end, true)
hlxg_huxiao_mod = sgs.CreateTargetModSkillV2 {
    name = "#hlxg_huxiao_mod", pattern = ".", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local p, to = ctx:getPrimary(), ctx:getSecondary()
        if ctx:getModType() == sgs.TargetModSkill_Residue and p and to
            and p:getMark("hlxg_huxiao_" .. to:objectName() .. "-Clear") > 0 then
            return sgs.CorrectSkillResult.unlimitedResidue()
        end
        return 0
    end,
}
hlxg_xuehen = gu_active("hlxg_xuehen", 1, 1, 1,
    function(self, targets, to, from) return #targets < math.max(1, from:getLostHp()) end,
    function(self, targets) return #targets > 0 end,
    function(self, room, source, targets)
        gu_throw(room, source, self:getSubcards(), "hlxg_xuehen")
        local eligible = sgs.SPlayerList()
        for _, to in ipairs(targets) do
            if to:isAlive() then room:setPlayerChained(to, true, source) end
        end
        for _, to in ipairs(targets) do if to:isAlive() then eligible:append(to) end end
        if eligible:isEmpty() or not source:isAlive() then return end
        local to = room:askForPlayerChosen(source, eligible, "hlxg_xuehen", "@hlxg_xuehen-damage", false, true)
        if to then room:damage(sgs.DamageStruct("hlxg_xuehen", source, to, 1, sgs.DamageStruct_Fire)) end
    end,
    function(request, c) return c:isRed() and not request:getInitiator():isJilei(c) and not c:hasFlag("using") end)

hlxg_guanyu3:addSkill(hlxg_danqi)
hlxg_guanyu3:addSkill(hlxg_wusheng_guanyu3)
hlxg_guanyu3:addSkill(hlxg_wusheng_guanyu3_effect)
hlxg_guanyu3:addSkill(hlxg_wusheng_guanyu3_mod)
extension_hl:addSkills(hlxg_nuzhan)
extension_hl:addSkills(hlxg_nuzhan_mod)
extension_hl:addSkills(hlxg_yuma_guanyu3)
extension_hl:addSkills(hlxg_yuma_guanyu3_distance)
hlxg_guanyinping:addSkill(hlxg_wuji)
hlxg_guanyinping:addSkill(hlxg_huxiao)
hlxg_guanyinping:addSkill(hlxg_huxiao_mod)
hlxg_guanyinping:addSkill(hlxg_xuehen)
extension_hl:insertRelatedSkills("hlxg_wusheng_guanyu3", "#hlxg_wusheng_guanyu3_effect")
extension_hl:insertRelatedSkills("hlxg_wusheng_guanyu3", "#hlxg_wusheng_guanyu3_mod")
extension_hl:insertRelatedSkills("hlxg_nuzhan", "#hlxg_nuzhan_mod")
extension_hl:insertRelatedSkills("hlxg_yuma_guanyu3", "#hlxg_yuma_guanyu3_distance")
extension_hl:insertRelatedSkills("hlxg_huxiao", "#hlxg_huxiao_mod")
sgs.LoadTranslationTable {
    ["hlxg_guanyu3"] = "关羽[欢乐修改]", ["&hlxg_guanyu3"] = "关羽",
    ["hlxg_guanyinping"] = "关银屏[欢乐修改]", ["&hlxg_guanyinping"] = "关银屏",
    ["hlxg_danqi"] = "单骑",
    [":hlxg_danqi"] = "觉醒技，当你累计使用或打出五张牌时或造成6点伤害后，你将体力回复至体力上限，然后获得〖驭马〗和〖怒斩〗。",
    ["hlxg_nuzhan"] = "怒斩",
    [":hlxg_nuzhan"] = "锁定技，你使用锦囊牌转化的【杀】造成的伤害+1；当你使用非锦囊牌转化的【杀】后，本阶段你使用【杀】的次数上限+1。",
    ["hlxg_wusheng_guanyu3"] = "武圣",
    [":hlxg_wusheng_guanyu3"] = "回合开始时，你从牌堆或弃牌堆中获得一张红色牌；你可以将一张红色牌当【杀】使用或打出；你使用非转化的红色【杀】造成的伤害+1；你使用方块【杀】无距离限制。",
    ["hlxg_yuma_guanyu3"] = "驭马",
    [":hlxg_yuma_guanyu3"] = "锁定技，你计算与其他角色的距离-1。当你失去装备区里的一张坐骑牌后，你摸两张牌。",
    ["hlxg_wuji"] = "武继",
    [":hlxg_wuji"] = "觉醒技，结束阶段，若你本回合造成过至少3点伤害，你加1点体力上限并回复1点体力，然后摸两张牌。",
    ["hlxg_huxiao"] = "虎啸",
    [":hlxg_huxiao"] = "锁定技，当你对一名角色造成火焰伤害后，你本回合对其使用牌无次数限制。",
    ["hlxg_xuehen"] = "雪恨",
    [":hlxg_xuehen"] = "出牌阶段限一次，你可以弃置一张红色牌，然后选择至多X名角色，横置这些角色并对其中一名角色造成1点火焰伤害（X为你已损失的体力值且至少为1）。",
    ["@hlxg_xuehen-damage"] = "雪恨：选择其中一名角色，对其造成1点火焰伤害",
}
end

-- ==================== c202_03
do
-- c202_03: literal 欢乐 changes; damage records include self damage.
hljx_guanyinping = sgs.General(extension_hl, "hljx_guanyinping", "shu", 3, false)
hlxg_dianwei = sgs.General(extension_hl, "hlxg_dianwei", "wei", 4)
hljx_dianwei = sgs.General(extension_hl, "hljx_dianwei", "wei", 4)

hljx_wuji_record = gu_record("#hljx_wuji_record", {sgs.DamageDone}, function(self, event, room, p, data)
    local d = data:toDamage()
    if d.from and d.damage > 0 then
        room:addPlayerMark(d.from, "hljx_wuji_damage-Clear", d.damage)
        room:addPlayerMark(d.from, "hlxg_qiangxi_damage-Clear")
    end
end)
extension_hl:addSkills(hljx_wuji_record)
extension_hl:insertRelatedSkills("hljx_wuji", "#hljx_wuji_record")
extension_hl:insertRelatedSkills("hlxg_qiangxi", "#hljx_wuji_record")

local function hl_c202_find(room, owner, predicate, field)
    if field then
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            for _, c in sgs.qlist(q:getCards("ej")) do
                if predicate(c) then room:obtainCard(owner, c, "hljx_wuji", true); return end
            end
        end
    end
    for _, pile in ipairs({room:getDrawPile(), room:getDiscardPile()}) do
        for _, id in sgs.qlist(pile) do
            local c = sgs.Sanguosha:getCard(id)
            if predicate(c) then
                room:obtainCard(owner, c, field and "hljx_wuji" or "hljx_huxiao", false)
                return
            end
        end
    end
end
hljx_wuji = gu_trigger("hljx_wuji", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Finish or owner:getMark("hljx_wuji") > 0
        or owner:getMark("hljx_wuji_damage-Clear") < 3 then return end
    room:notifySkillInvoked(owner, self:objectName())
    room:setPlayerMark(owner, "hljx_wuji", 1)
    room:changeMaxHpForAwakenSkill(owner, 1, self:objectName())
    local recover = sgs.RecoverStruct(); recover.who = owner; recover.recover = 1
    room:recover(owner, recover)
    if owner:isAlive() then
        hl_c202_find(room, owner, function(c) return c:objectName() == "blade" end, true)
        room:setPlayerMark(owner, "&hljx_huxiao_modified", 1)
        room:changeTranslation(owner, "hljx_huxiao", 2)
    end
end, true, sgs.Skill_Wake)
hljx_huxiao = gu_trigger("hljx_huxiao", {sgs.Damage, sgs.TurnStart}, function(self, event, room, p, data, owner)
    if event == sgs.TurnStart then
        if p == owner and owner:getMark("hljx_wuji") > 0 then
            hl_c202_find(room, owner, function(c) return c:isKindOf("Slash") and c:isRed() end, false)
        end
        return
    end
    local d = data:toDamage()
    if d.from ~= owner or not d.to or d.nature ~= sgs.DamageStruct_Fire then return end
    room:sendCompulsoryTriggerLog(owner, self:objectName(), true)
    room:setPlayerMark(owner, "hljx_huxiao_" .. d.to:objectName() .. "-Clear", 1)
    owner:drawCards(1, self:objectName())
end, true)
hljx_huxiao_mod = sgs.CreateTargetModSkillV2 {
    name = "#hljx_huxiao_mod", pattern = ".", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local from, to = ctx:getPrimary(), ctx:getSecondary()
        if ctx:getModType() == sgs.TargetModSkill_Residue and from and to
            and from:getMark("hljx_huxiao_" .. to:objectName() .. "-Clear") > 0 then return 999 end
        return 0
    end,
}
hljx_xuehen = gu_active("hljx_xuehen", 1, 1, 1,
    function(self, targets, to, from) return #targets < from:getLostHp() + 1 end,
    function(self, targets) return #targets > 0 end,
    function(self, room, source, targets)
        gu_throw(room, source, self:getSubcards(), "hljx_xuehen")
        local candidates = sgs.SPlayerList()
        for _, q in ipairs(targets) do
            if q:isAlive() then
                room:setPlayerChained(q, true)
                candidates:append(q)
            end
        end
        if source:isDead() or candidates:isEmpty() then return end
        local to = room:askForPlayerChosen(source, candidates, "hljx_xuehen", "@hljx_xuehen-damage")
        if to then room:damage(sgs.DamageStruct("hljx_xuehen", source, to, 1, sgs.DamageStruct_Fire)) end
    end,
    function(request, c) return c:isRed() and not request:getInitiator():isJilei(c) end)
hljx_guanyinping:addSkill(hljx_wuji)
hljx_guanyinping:addSkill(hljx_huxiao)
hljx_guanyinping:addSkill(hljx_huxiao_mod)
hljx_guanyinping:addSkill(hljx_xuehen)
extension_hl:insertRelatedSkills("hljx_huxiao", "#hljx_huxiao_mod")

hlxg_qiangxi = gu_trigger("hlxg_qiangxi", {sgs.DamageCaused}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if d.from ~= owner or room:getCurrent() ~= owner
        or owner:getMark("hlxg_qiangxi_damage-Clear") > 0 then return end
    if room:askForCard(owner, "Weapon", "@hlxg_qiangxi-weapon", data, sgs.Card_MethodDiscard,
        nil, false, self:objectName()) then
        d.damage = d.damage + 1; data:setValue(d)
    end
end)
hlxg_dianwei:addSkill(hlxg_qiangxi)

hljx_qiangxi = gu_active("hljx_qiangxi", nil, 0, 0,
    function(self, targets, to, from)
        return #targets == 0 and to ~= from and from:inMyAttackRange(to)
            and from:getMark("hljx_qiangxi_" .. to:objectName() .. "-PlayClear") == 0
    end, gu_one_feasible,
    function(self, room, source, targets)
        local to = targets[1]
        room:setPlayerMark(source, "hljx_qiangxi_" .. to:objectName() .. "-PlayClear", 1)
        room:loseHp(source, 1)
        if source:isAlive() then source:drawCards(1, "hljx_qiangxi") end
        if to:isAlive() then room:damage(sgs.DamageStruct("hljx_qiangxi", source, to, 1)) end
    end)
hljx_qiangxi_damage = gu_trigger("#hljx_qiangxi_damage", {sgs.DamageInflicted}, function(self, event, room, p, data, owner)
    local d = data:toDamage()
    if not d.to or d.to == owner then return end
    if room:askForCard(owner, "EquipCard", "@hljx_qiangxi-equip", data, sgs.Card_MethodDiscard,
        nil, false, "hljx_qiangxi") then
        d.damage = d.damage + 1; data:setValue(d)
    end
end)
hljx_dianwei:addSkill(hljx_qiangxi)
hljx_dianwei:addSkill(hljx_qiangxi_damage)
extension_hl:insertRelatedSkills("hljx_qiangxi", "#hljx_qiangxi_damage")

sgs.LoadTranslationTable {
    ["hljx_guanyinping"] = "关银屏[欢乐界]", ["&hljx_guanyinping"] = "关银屏",
    ["hljx_wuji"] = "武继",
    [":hljx_wuji"] = "觉醒技，结束阶段，若你本回合造成过至少3点伤害，你加1点体力上限并回复1点体力，然后从场上、牌堆或弃牌堆中获得【青龙偃月刀】并修改〖虎啸〗。",
    ["hljx_huxiao"] = "虎啸",
    [":hljx_huxiao"] = "锁定技，当你对一名角色造成火焰伤害后，你摸一张牌且本回合对其使用牌无次数限制。",
    [":hljx_huxiao2"] = "锁定技，回合开始时，你从牌堆或弃牌堆中获得一张红色【杀】。当你对一名角色造成火焰伤害后，你摸一张牌且本回合对其使用牌无次数限制。",
    ["&hljx_huxiao_modified"] = "虎啸·修改",
    ["hljx_xuehen"] = "雪恨",
    [":hljx_xuehen"] = "出牌阶段限一次，你可以弃置一张红色牌，然后选择至多X名角色，横置这些角色并对其中一名角色造成1点火焰伤害（X为你已损失的体力值+1）。",
    ["@hljx_xuehen-damage"] = "雪恨：选择其中一名角色，对其造成1点火焰伤害",
    ["hlxg_dianwei"] = "典韦[欢乐修改]", ["&hlxg_dianwei"] = "典韦",
    ["hlxg_qiangxi"] = "强袭",
    [":hlxg_qiangxi"] = "当你于回合内第一次造成伤害时，你可以弃置一张武器牌，令此伤害+1。",
    ["@hlxg_qiangxi-weapon"] = "强袭：你可以弃置一张武器牌，令此伤害+1",
    ["hljx_dianwei"] = "典韦[欢乐界]", ["&hljx_dianwei"] = "典韦",
    ["hljx_qiangxi"] = "强袭",
    [":hljx_qiangxi"] = "出牌阶段对每名角色限一次，你可以失去1点体力并摸一张牌，然后对你攻击范围内的一名其他角色造成1点伤害。当其他角色受到伤害时，你可以弃置一张装备牌，令此伤害+1。",
    ["@hljx_qiangxi-equip"] = "强袭：你可以弃置一张装备牌，令此伤害+1",
}
end

-- ==================== c202_04
do
-- c202_04: literal Huanle variants; shared helpers are provided by offline.lua.
hlxg_liuxie = sgs.General(extension_hl, "hlxg_liuxie", "qun", 3)
hlxg_liubei = sgs.General(extension_hl, "hlxg_liubei", "shu", 4)
hljx_liubei = sgs.General(extension_hl, "hljx_liubei", "shu", 4)
local function c204_tianming(room, p, name)
    local n = math.min(2, p:getCardCount(true))
    if n > 0 then room:askForDiscard(p, name, n, n, false, true) end
    if p:isAlive() then p:drawCards(2, name) end
end
hlxg_tianming = gu_trigger("hlxg_tianming", {sgs.TargetConfirmed}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if p ~= owner or not use.card or not use.card:isKindOf("Slash") or not use.to:contains(owner)
        or not gu_invoke(owner, self:objectName(), data) then return end
    c204_tianming(room, owner, self:objectName())
    if not owner:isAlive() then return end
    local q = room:askForPlayerChosen(owner, room:getAlivePlayers(), self:objectName(), "@hlxg_tianming", true, true)
    if q and gu_invoke(q, self:objectName(), sgs.QVariant(owner)) then c204_tianming(room, q, self:objectName()) end
end)
hlxg_mizhao = gu_active("hlxg_mizhao", 1, 0, 999, gu_one, gu_one_feasible,
    function(self, room, source, targets)
        local first = targets[1]
        gu_obtain(room, first, self:getSubcards(), "hlxg_mizhao")
        if not source:isAlive() or not first:isAlive() then return end
        local candidates = sgs.SPlayerList()
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            if q ~= first and first:canPindian(q) then candidates:append(q) end
        end
        if candidates:isEmpty() then return end
        local second = room:askForPlayerChosen(source, candidates, "hlxg_mizhao", "@hlxg_mizhao", false, true)
        local result = first:pindianInt(second, "hlxg_mizhao")
        if result ~= 1 and result ~= -1 then return end
        local winner = result == 1 and first or second
        local loser = result == 1 and second or first
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName("_hlxg_mizhao"); slash:deleteLater()
        if winner:isAlive() and loser:isAlive() and winner:canSlash(loser, slash, false) then
            local use = sgs.CardUseStruct(); use.card = slash; use.from = winner; use.to:append(loser)
            room:useCard(use)
        end
    end, function(request, c) return not c:isEquipped() end)
hlxg_mizhaoCard = sgs.Sanguosha:cloneSkillCard("hlxg_mizhaoCard")
hlxg_liuxie:addSkill(hlxg_tianming); hlxg_liuxie:addSkill(hlxg_mizhao)

local function c204_rende(name, extended)
    local gift = sgs.CreateSkillCard {
        name = name .. "Card", will_throw = false,
        filter =
        function(self, targets, to, from)
            return gu_one(self, targets, to, from) and to:getMark(name .. "_" .. from:objectName() .. "-PlayClear") == 0
        end, feasible = gu_one_feasible,
        on_use = function(self, room, source, targets)
            local to = targets[1]
            room:setPlayerMark(to, name .. "_" .. source:objectName() .. "-PlayClear", 1)
            local old = source:getMark(name .. "-PlayClear")
            room:addPlayerMark(source, name .. "-PlayClear", self:subcardsLength())
            gu_obtain(room, to, self:getSubcards(), name)
            if not source:isAlive() then return end
            if extended and to:isAlive() and gu_invoke(source, name .. "_red", sgs.QVariant(to)) then
                room:setPlayerMark(to, name .. "_red_" .. source:objectName(), 1)
            end
            if old < 2 and source:getMark(name .. "-PlayClear") >= 2 then
                local choices = {}
                for _, cn in sgs.list(sgs.Sanguosha:getCardNames()) do
                    local c = sgs.Sanguosha:cloneCard(cn, sgs.Card_NoSuit, 0)
                    if c then
                        c:setSkillName(name)
                        if (c:isKindOf("BasicCard") or (extended and c:isNDTrick())) and c:isAvailable(source) then table.insert(choices, cn) end
                        c:deleteLater()
                    end
                end
                if #choices == 0 then return end
                table.insert(choices, "cancel")
                local choice = room:askForChoice(source, name, table.concat(choices, "+"))
                if choice == "cancel" then return end
                source:setTag(name .. "_card", sgs.QVariant(choice))
                room:askForUseCard(source, "@@" .. name, "@" .. name, -1, sgs.Card_MethodUse, true)
                source:removeTag(name .. "_card")
            end
        end,
    }
    _G[name .. "Card"] = gift
    -- The same view-as skill handles the nested free-card request with normal targeting/history.
    local free = sgs.CreateViewAsSkillV2 {
        name = name,
        can_activate = function(self, request)
            return request:getPattern() == "@@" .. name or
                request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
        end,
        can_select_card = function(self, request, c)
            return request:getPattern() ~= "@@" .. name and not c:isEquipped()
        end,
        card_selection_feasible = function(self, request)
            return request:getPattern() ~= "@@" .. name or request:getSelectedCardIds():isEmpty()
        end,
        create_card = function(self, request)
            if request:getPattern() == "@@" .. name then
                local cn = request:getInitiator():getTag(name .. "_card"):toString()
                if cn == "" then return nil end
                local c = sgs.Sanguosha:cloneCard(cn, sgs.Card_NoSuit, 0); c:setSkillName(name); return c
            end
            local c = gift:clone()
            c:addSubcards(request:getSelectedCardIds()); c:setSkillName(name); return c
        end,
    }
    return free
end
hlxg_rende_liubei = c204_rende("hlxg_rende_liubei", false)
hljx_rende = c204_rende("hljx_rende", true)
hljx_rende_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#hljx_rende_prohibit",
    holder_selector = sgs.CorrectSkill_System,
    is_prohibited = function(self, ctx)
        local from, to, card = ctx:getFrom(), ctx:getTo(), ctx:getCard()
        return from and to and card:isKindOf("Slash") and card:isRed()
            and from:getMark("hljx_rende_red_" .. to:objectName()) > 0
    end,
}
hljx_rende_clear = gu_record("#hljx_rende_clear", {sgs.TurnStart}, function(self, event, room, p, data)
    if not p then return end
    for _, q in sgs.qlist(room:getAllPlayers()) do room:setPlayerMark(q, "hljx_rende_red_" .. p:objectName(), 0) end
end)
hlxg_liubei:addSkill(hlxg_rende_liubei); hljx_liubei:addSkill(hljx_rende)
hljx_liubei:addSkill(hljx_rende_prohibit); hljx_liubei:addSkill(hljx_rende_clear)
extension_hl:insertRelatedSkills("hljx_rende", "#hljx_rende_prohibit")
extension_hl:insertRelatedSkills("hljx_rende", "#hljx_rende_clear")

local function c204_jijiang_supply(source, name)
    local room = source:getRoom()
    for _, q in sgs.qlist(room:getOtherPlayers(source)) do
        if q:getKingdom() == "shu" then
            local c = room:askForCard(q, "slash", "@" .. name .. ":" .. source:objectName(), sgs.QVariant(source), sgs.Card_MethodResponse, source, false, name, true)
            if c then
                room:setCardFlag(c, name .. "_" .. source:objectName() .. "_" .. q:objectName())
                room:setCardFlag(c, "YUANBEN")
                return c
            end
        end
    end
end
local function c204_jijiang(name, extended)
    local card = sgs.CreateSkillCard {
        name = name .. "Card", will_throw = false,
        filter = function(self, targets, to, from)
            local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); c:deleteLater()
            local ps = sgs.PlayerList(); for _, p in ipairs(targets) do ps:append(p) end
            return c:targetFilter(ps, to, from) and not from:isProhibited(to, c)
        end,
        feasible = function(self, targets, from)
            local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); c:deleteLater()
            local ps = sgs.PlayerList(); for _, p in ipairs(targets) do ps:append(p) end
            return c:targetsFeasible(ps, from)
        end,
        on_validate = function(self, use) use.m_isOwnerUse = false; return c204_jijiang_supply(use.from, name) end,
        on_validate_in_response = function(self, source) return c204_jijiang_supply(source, name) end,
    }
    _G[name .. "Card"] = card
    local vs = sgs.CreateViewAsSkillV2 {
        name = name, response_or_use = true,
        can_activate = function(self, request)
            local p = request:getInitiator()
            if not p:hasLordSkill(name) then return false end
            local found = false
            for _, q in sgs.qlist(p:getAliveSiblings()) do if q:getKingdom() == "shu" then found = true end end
            if not found then return false end
            if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return sgs.Slash_IsAvailable(p) end
            return request:getPattern() == "slash"
        end,
        can_select_card = function() return false end,
        card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
        create_card = function() local c = card:clone(); c:setSkillName(name); return c end,
    }
    local main = gu_trigger(name .. "$", {sgs.CardAsked, sgs.CardFinished, sgs.PostCardResponded}, function(self, event, room, p, data, owner)
        if not owner:hasLordSkill(name) then return end
        if event == sgs.CardAsked then
            local ask = data:toStringList()
            if p ~= owner or ask[1] ~= "slash" or not ask[2] or string.find(ask[2], "jijiang", 1, true)
                or not gu_invoke(owner, name, data) then return end
            local c = c204_jijiang_supply(owner, name)
            if c then room:provide(c); return true end
            return
        end
        local c, done
        if event == sgs.CardFinished then c = data:toCardUse().card; done = true
        else local response = data:toCardResponse(); c = response.m_card; done = not response.m_isUse end
        if not c or not c:isKindOf("Slash") then return end
        if done then
            for _, q in sgs.qlist(room:getAllPlayers()) do
                local flag = name .. "_" .. owner:objectName() .. "_" .. q:objectName()
                if c:hasFlag(flag) then
                    room:setCardFlag(c, "-" .. flag)
                    if owner:isAlive() then owner:drawCards(1, name) end
                    if q:isAlive() then q:drawCards(1, name) end
                end
            end
        end
    end)
    main:setViewAsSkill(vs)
    return main
end
hlxg_jijiang_liubei = c204_jijiang("hlxg_jijiang_liubei", false)
hljx_jijiang_liubei = c204_jijiang("hljx_jijiang_liubei", true)
hljx_jijiang_liubei_bonus = gu_record("#hljx_jijiang_liubei_bonus", {sgs.CardUsed, sgs.CardResponded}, function(self, event, room, p, data)
    if not p or p:getKingdom() ~= "shu" then return end
    local c = event == sgs.CardUsed and data:toCardUse().card or data:toCardResponse().m_card
    if not c or not c:isKindOf("Slash") then return end
    for _, owner in sgs.qlist(room:getAlivePlayers()) do
        if owner ~= p and owner:hasLordSkill("hljx_jijiang_liubei") and owner:getPhase() == sgs.Player_NotActive
            and owner:getMark("hljx_jijiang_liubei_bonus-Clear") == 0
            and gu_invoke(p, "hljx_jijiang_liubei_bonus", sgs.QVariant(owner)) then
            room:setPlayerMark(owner, "hljx_jijiang_liubei_bonus-Clear", 1)
            owner:drawCards(1, "hljx_jijiang_liubei")
        end
    end
end)
hlxg_liubei:addSkill(hlxg_jijiang_liubei); hljx_liubei:addSkill(hljx_jijiang_liubei)
hljx_liubei:addSkill(hljx_jijiang_liubei_bonus)
extension_hl:insertRelatedSkills("hljx_jijiang_liubei", "#hljx_jijiang_liubei_bonus")
sgs.LoadTranslationTable {
    ["hlxg_liuxie"] = "刘协[欢乐修改]", ["&hlxg_liuxie"] = "刘协",
    ["hlxg_liubei"] = "刘备[欢乐修改]", ["&hlxg_liubei"] = "刘备",
    ["hljx_liubei"] = "刘备[欢乐界]", ["&hljx_liubei"] = "刘备",
    ["hlxg_tianming"] = "天命",
    [":hlxg_tianming"] = "当你成为【杀】的目标后，你可以弃置两张牌（不足则全弃，无牌则不弃）并摸两张牌，然后你可以选择一名角色，其也可以如此做。",
    ["hlxg_mizhao"] = "密诏",
    [":hlxg_mizhao"] = "出牌阶段限一次，你可以将任意张手牌交给一名其他角色，然后令其与你选择的另一名角色拼点，拼点赢的角色视为对拼点没赢的角色使用一张【杀】。",
    ["hlxg_rende_liubei"] = "仁德",
    [":hlxg_rende_liubei"] = "出牌阶段每名角色限一次，你可以将任意张手牌交给一名其他角色，每阶段你以此法给出第二张牌时，你可以视为使用一张基本牌（以此法使用的【杀】有距离限制且计入次数限制）。",
    ["hljx_rende"] = "仁德",
    [":hljx_rende"] = "出牌阶段每名角色限一次，你可以将任意张手牌交给一名其他角色，然后你可以令其不能对你使用红色【杀】直到你的下回合开始。每阶段你以此法给出第二张牌时，你可以视为使用一张基本牌或普通锦囊牌（以此法使用的【杀】有距离限制且计入次数限制）。",
    ["hlxg_jijiang_liubei"] = "激将",
    [":hlxg_jijiang_liubei"] = "主公技，当你需要使用或打出【杀】时，你可以令其他蜀势力角色选择是否替你使用或打出【杀】（视为由你使用或打出）；此【杀】结算结束后，你与响应〖激将〗的角色各摸一张牌。",
    ["hljx_jijiang_liubei"] = "激将",
    [":hljx_jijiang_liubei"] = "主公技，当你需要使用或打出【杀】时，你可以令其他蜀势力角色选择是否替你使用或打出【杀】（视为由你使用或打出）；此【杀】结算结束后，你与响应〖激将〗的角色各摸一张牌。当其他蜀势力角色于你的回合外使用、打出或替你使用或打出【杀】时，其可以令你摸一张牌（每回合限一次）。",
    ["@hlxg_tianming"] = "天命：你可以选择一名角色，其可以弃牌并摸两张牌",
    ["@hlxg_mizhao"] = "密诏：请选择另一名拼点角色",
    ["@hlxg_rende_liubei"] = "仁德：你可以使用所选基本牌",
    ["@hljx_rende"] = "仁德：你可以使用所选基本牌或普通锦囊牌",
    ["hljx_rende_red"] = "仁德：令其不能对你使用红色杀",
    ["@hlxg_jijiang_liubei"] = "激将：你可以替 %src 打出杀",
    ["@hljx_jijiang_liubei"] = "激将：你可以替 %src 打出杀",
    ["hljx_jijiang_liubei_bonus"] = "激将：令此主公摸一张牌",
}
end

-- ==================== c202_05
do
-- c202_05: literal 欢乐杀修改 variants.
hlxg_liubei2 = sgs.General(extension_hl, "hlxg_liubei2", "god", 6)
hlxg_liubei3 = sgs.General(extension_hl, "hlxg_liubei3", "shu", 4)
hlxg_liufeng = sgs.General(extension_hl, "hlxg_liufeng", "shu", 4)

hlxg_jieying_liubei2 = sgs.CreateTriggerSkillV2 {
    name = "hlxg_jieying_liubei2", frequency = sgs.Skill_Compulsory,
    events = {sgs.GameStart, sgs.Debut, sgs.Revived, sgs.EventAcquireSkill, sgs.ChainStateChange, sgs.Damaged, sgs.EventPhaseStart},
    can_trigger = function(self, event, room, p, data)
        if not p or not p:isAlive() or not p:hasSkill(self:objectName()) then return false end
        if event == sgs.ChainStateChange then return p:isChained() and self:objectName() or false end
        if event == sgs.EventPhaseStart then return p:getPhase() == sgs.Player_Finish and self:objectName() or false end
        return self:objectName()
    end,
    on_cost = function(self, event, room, p, ctx)
        if event == sgs.EventPhaseStart then
            return not room:getOtherPlayers(p):isEmpty() and gu_invoke(p, self:objectName(), ctx.original_data)
        end
        return true
    end,
    on_effect = function(self, event, room, p, ctx)
        if event == sgs.ChainStateChange then return true end
        if event == sgs.Damaged then p:drawCards(1, self:objectName())
        elseif event == sgs.EventPhaseStart then
            local to = room:askForPlayerChosen(p, room:getOtherPlayers(p), self:objectName(), "@hlxg_jieying_liubei2", false, true)
            if to then room:setPlayerChained(to, true, p) end
        elseif not p:isChained() then room:setPlayerChained(p, true, p) end
        return false
    end,
}
hlxg_jieying_liubei2_max = sgs.CreateMaxCardsSkillV2 {
    name = "#hlxg_jieying_liubei2_max", holder_selector = sgs.CorrectSkill_AllHolders,
    correct_func = function(self, ctx)
        local p, holder = ctx:getPrimary(), ctx:getHolder()
        if p and p:isChained() and holder and holder:isAlive() and holder:hasSkill("hlxg_jieying_liubei2") then return 2 end
        return false
    end,
}
hlxg_longnu_filter = sgs.CreateFilterSkill {
    name = "#hlxg_longnu_filter",
    view_filter = function(self, card)
        local room = sgs.Sanguosha:currentRoom()
        local p = room and room:getCardOwner(card:getId())
        return p and room:getCardPlace(card:getId()) == sgs.Player_PlaceHand
            and ((p:getMark("hlxg_longnu_mode") == 1 and card:isRed()) or (p:getMark("hlxg_longnu_mode") == 2 and card:isBlack()))
    end,
    view_as = function(self, card)
        local p = sgs.Sanguosha:currentRoom():getCardOwner(card:getId())
        local name = p:getMark("hlxg_longnu_mode") == 1 and "fire_slash" or "thunder_slash"
        local slash = sgs.Sanguosha:cloneCard(name, card:getSuit(), card:getNumber())
        slash:setSkillName("hlxg_longnu")
        local wrapped = sgs.Sanguosha:getWrappedCard(card:getId())
        wrapped:takeOver(slash); slash:deleteLater(); return wrapped
    end,
}
hlxg_longnu = sgs.CreateTriggerSkillV2 {
    name = "hlxg_longnu", frequency = sgs.Skill_Compulsory, events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, p, data)
        return p and p:isAlive() and p:hasSkill(self:objectName()) and p:getPhase() == sgs.Player_Play and self:objectName() or false
    end,
    on_effect = function(self, event, room, p, ctx)
        local mode = room:askForChoice(p, self:objectName(), "fire+thunder")
        room:setPlayerMark(p, "hlxg_longnu_mode", mode == "fire" and 1 or 2)
        if mode == "fire" then
            room:loseHp(p, 1, true, p, self:objectName())
            if p:isAlive() then p:drawCards(2, self:objectName()) end
        else room:loseMaxHp(p, 1, self:objectName()) end
        if p:isAlive() then room:filterCards(p, p:getCards("he"), true) end
        return false
    end,
}
hlxg_longnu_clear = gu_record("#hlxg_longnu_clear", {sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if p and data:toPhaseChange().from == sgs.Player_Play and p:getMark("hlxg_longnu_mode") > 0 then
        room:setPlayerMark(p, "hlxg_longnu_mode", 0); room:filterCards(p, p:getCards("he"), true)
    end
end)
hlxg_longnu_mod = sgs.CreateTargetModSkillV2 {
    name = "#hlxg_longnu_mod", holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(self, ctx)
        local p, c = ctx:getPrimary(), ctx:getCard()
        if not p or not c then return false end
        if p:getMark("hlxg_longnu_mode") == 1 and c:isKindOf("FireSlash") and ctx:getModType() == sgs.TargetModSkill_DistanceLimit then return 1000 end
        if p:getMark("hlxg_longnu_mode") == 2 and c:isKindOf("ThunderSlash") and ctx:getModType() == sgs.TargetModSkill_Residue then return sgs.CorrectSkillResult.unlimitedResidue() end
        return false
    end,
}
hlxg_liubei2:addSkill(hlxg_jieying_liubei2); hlxg_liubei2:addSkill(hlxg_jieying_liubei2_max)
hlxg_liubei2:addSkill(hlxg_longnu); hlxg_liubei2:addSkill(hlxg_longnu_filter); hlxg_liubei2:addSkill(hlxg_longnu_clear); hlxg_liubei2:addSkill(hlxg_longnu_mod)
extension_hl:insertRelatedSkills("hlxg_jieying_liubei2", "#hlxg_jieying_liubei2_max")
for _, suffix in ipairs({"filter", "clear", "mod"}) do extension_hl:insertRelatedSkills("hlxg_longnu", "#hlxg_longnu_" .. suffix) end

local function hlxg_rende_enabled(p)
    return p and p:isAlive() and p:hasSkill("hlxg_rende_liubei3") and p:getMark("hlxg_rende_disabled-Clear") == 0
end
local function hlxg_rende_card(p, name)
    local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    if not c then return nil end
    c:deleteLater()
    local cost = c:isKindOf("BasicCard") and 2 or 3
    if not (c:isKindOf("BasicCard") or c:isNDTrick()) or p:getMark("&hlxg_ren") < cost
        or p:getMark("hlxg_rende_used-Clear") > 0 or not hlxg_rende_enabled(p) then return nil end
    c:setSkillName("hlxg_rende_liubei3")
    return c
end
local function hlxg_rende_response_names(pattern)
    local names = {}
    for _, name in ipairs(pattern:split("+")) do
        if name == "slash" then
            for _, slash in ipairs(sgs.Sanguosha:getSlashNames()) do table.insert(names, slash) end
        else table.insert(names, name) end
    end
    return names
end
local function hlxg_rende_pay(room, p, c)
    room:removePlayerMark(p, "&hlxg_ren", c:isKindOf("BasicCard") and 2 or 3)
    room:setPlayerMark(p, "hlxg_rende_used-Clear", 1)
end
hlxg_rende_liubei3_imitate = sgs.CreateViewAsSkillV2 {
    name = "#hlxg_rende_liubei3_imitate", n = 0,
    can_activate = function(self, request) return request:getPattern() == "@@hlxg_rende_liubei3_imitate" and hlxg_rende_enabled(request:getInitiator()) end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
    create_card = function(self, request)
        local p = request:getInitiator()
        return hlxg_rende_card(p, p:getTag("hlxg_rende_declare"):toString())
    end,
    pay = function(self, room, ctx, request)
        local p = request:getInitiator()
        local c = hlxg_rende_card(p, p:getTag("hlxg_rende_declare"):toString())
        if not c then return false end
        hlxg_rende_pay(room, p, c); return true
    end,
}
hlxg_rende_liubei3Card = sgs.CreateSkillCard {
    name = "hlxg_rende_liubei3Card", will_throw = false,
    filter = function(self, targets, to, from)
        if self:getUserString() ~= "" then
            local c = hlxg_rende_card(from, self:getUserString():split("+")[1])
            local list = sgs.PlayerList(); for _, p in ipairs(targets) do list:append(p) end
            return c and c:targetFilter(list, to, from) and not from:isProhibited(to, c, list)
        end
        return self:subcardsLength() > 0 and #targets == 0 and to ~= from
            and to:getMark("hlxg_rende_given_" .. from:objectName() .. "-PlayClear") == 0
    end,
    feasible = function(self, targets, from)
        if self:getUserString() ~= "" then
            if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return #targets == 0 end
            local c = hlxg_rende_card(from, self:getUserString():split("+")[1])
            local list = sgs.PlayerList(); for _, p in ipairs(targets) do list:append(p) end
            return c and c:targetsFeasible(list, from)
        end
        return #targets == (self:subcardsLength() == 0 and 0 or 1)
    end,
    on_use = function(self, room, p, targets)
        if not hlxg_rende_enabled(p) then return end
        if self:subcardsLength() > 0 then
            local to = targets[1]
            room:setPlayerMark(to, "hlxg_rende_given_" .. p:objectName() .. "-PlayClear", 1)
            room:setPlayerMark(to, "hlxg_rende_received_" .. p:objectName(), 1)
            room:obtainCard(to, self, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, p:objectName(), to:objectName(), "hlxg_rende_liubei3", ""), false)
            room:setPlayerMark(p, "&hlxg_ren", math.min(10, p:getMark("&hlxg_ren") + self:subcardsLength()))
        else
            local names = {}
            for _, name in ipairs(sgs.Sanguosha:getCardNames()) do
                local c = hlxg_rende_card(p, name)
                if c and c:isAvailable(p) then table.insert(names, name) end
            end
            if #names == 0 then return end
            local name = room:askForChoice(p, "hlxg_rende_liubei3", table.concat(names, "+") .. "+cancel")
            if name == "cancel" then return end
            p:setTag("hlxg_rende_declare", sgs.QVariant(name))
            room:askForUseCard(p, "@@hlxg_rende_liubei3_imitate", "@hlxg_rende_liubei3-imitate:" .. name)
            p:removeTag("hlxg_rende_declare")
        end
    end,
    on_validate_in_response = function(self, p)
        local names = {}
        for _, name in ipairs(hlxg_rende_response_names(self:getUserString())) do
            local c = hlxg_rende_card(p, name)
            if c and not (c:isKindOf("Peach") and p:getMark("Global_PreventPeach") > 0) then table.insert(names, name) end
        end
        if #names == 0 then return nil end
        local name = #names == 1 and names[1] or p:getRoom():askForChoice(p, "hlxg_rende_liubei3", table.concat(names, "+"))
        local c = hlxg_rende_card(p, name)
        if c then hlxg_rende_pay(p:getRoom(), p, c) end
        return c
    end,
    on_validate = function(self, use)
        if self:getUserString() == "" then return self end
        -- Response-use (e.g. a requested Slash) already has its targets.
        local p = use.from
        local names = {}
        for _, name in ipairs(hlxg_rende_response_names(self:getUserString())) do
            local c = hlxg_rende_card(p, name)
            if c and not (c:isKindOf("Peach") and p:getMark("Global_PreventPeach") > 0) then table.insert(names, name) end
        end
        if #names == 0 then return nil end
        local name = #names == 1 and names[1] or p:getRoom():askForChoice(p, "hlxg_rende_liubei3", table.concat(names, "+"))
        local c = hlxg_rende_card(p, name)
        if c then hlxg_rende_pay(p:getRoom(), p, c) end
        return c
    end,
}
hlxg_rende_liubei3VS = sgs.CreateViewAsSkillV2 {
    name = "hlxg_rende_liubei3", n = 999, response_or_use = true,
    can_activate = function(self, request)
        local p = request:getInitiator()
        if not hlxg_rende_enabled(p) then return false end
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return true end
        for _, name in ipairs(request:getPattern():split("+")) do
            local c = hlxg_rende_card(p, name)
            if c and not (c:isKindOf("Peach") and p:getMark("Global_PreventPeach") > 0) then return true end
        end
        return false
    end,
    can_select_card = function(self, request, c)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and request:getInitiator():getCards("he"):contains(c)
    end,
    card_selection_feasible = function(self, request)
        return request:getSelectedCardIds():length() > 0 or request:getInitiator():getMark("&hlxg_ren") >= 2
            and request:getInitiator():getMark("hlxg_rende_used-Clear") == 0
    end,
    create_card = function(self, request)
        local c = hlxg_rende_liubei3Card:clone()
        c:addSubcards(request:getSelectedCardIds()); c:setSkillName(self:objectName())
        if request:getReason() ~= sgs.CardUseStruct_CARD_USE_REASON_PLAY then c:setUserString(request:getPattern()) end
        return c
    end,
}
hlxg_rende_liubei3VS.response_pattern = "nullification"
local hlxg_rende_name = "hlxg_rende_liubei3"
hlxg_rende_liubei3 = sgs.CreateTriggerSkillV2 {
    name = hlxg_rende_name, view_as_skill = hlxg_rende_liubei3VS, events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, p, data)
        return hlxg_rende_enabled(p) and p:getPhase() == sgs.Player_Play and self:objectName() or false
    end,
    on_effect = function(self, event, room, p, ctx)
        room:setPlayerMark(p, "&hlxg_ren", math.min(10, p:getMark("&hlxg_ren") + 3)); return false
    end,
}
hlxg_jijiang_liubei3 = sgs.CreateTriggerSkillV2 {
    name = "hlxg_jijiang_liubei3$", events = {sgs.EventPhaseEnd},
    can_trigger = function(self, event, room, p, data)
        return p and p:isAlive() and p:hasLordSkill(self:objectName()) and p:getPhase() == sgs.Player_Play and self:objectName() or false
    end,
    on_cost = function(self, event, room, p, ctx)
        return gu_invoke(p, self:objectName(), ctx.original_data)
    end,
    on_effect = function(self, event, room, p, ctx)
        local candidates = sgs.SPlayerList()
        for _, to in sgs.qlist(room:getOtherPlayers(p)) do
            for _, q in sgs.qlist(room:getOtherPlayers(p)) do
                if q ~= to and q:getKingdom() == "shu" and q:inMyAttackRange(to) then candidates:append(to); break end
            end
        end
        if candidates:isEmpty() then return false end
        local to = room:askForPlayerChosen(p, candidates, self:objectName(), "@hlxg_jijiang_liubei3-target", false, true)
        local attackers = sgs.SPlayerList()
        for _, q in sgs.qlist(room:getOtherPlayers(p)) do
            if q ~= to and q:getKingdom() == "shu" and q:inMyAttackRange(to) then attackers:append(q) end
        end
        local q = room:askForPlayerChosen(p, attackers, self:objectName(), "@hlxg_jijiang_liubei3-attacker:" .. to:objectName(), false, true)
        if room:askForChoice(q, self:objectName(), "slash+skip", sgs.QVariant(to)) == "slash" then
            local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); c:setSkillName(self:objectName())
            local use = sgs.CardUseStruct(); use.card = c; use.from = q; use.to:append(to)
            room:useCard(use, false); c:deleteLater()
        else room:addPlayerMark(q, "&hlxg_jijiang_liubei3_skip") end
        return false
    end,
}
hlxg_jijiang_liubei3_skip = gu_record("#hlxg_jijiang_liubei3_skip", {sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if p and data:toPhaseChange().to == sgs.Player_Play and p:getMark("&hlxg_jijiang_liubei3_skip") > 0 then
        room:setPlayerMark(p, "&hlxg_jijiang_liubei3_skip", 0); p:skip(sgs.Player_Play)
    end
end)
hlxg_zhangwuCard = sgs.CreateSkillCard {
    name = "hlxg_zhangwuCard", target_fixed = true,
    on_use = function(self, room, p, targets)
        if p:getMark("@hlxg_zhangwu") == 0 then return end
        room:removePlayerMark(p, "@hlxg_zhangwu")
        local n = math.max(0, math.min(3, room:getTag("TurnLengthCount"):toInt() - 1))
        local recipients = sgs.SPlayerList()
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            if q:getMark("hlxg_rende_received_" .. p:objectName()) > 0 then recipients:append(q) end
        end
        room:sortByActionOrder(recipients)
        for _, q in sgs.qlist(recipients) do
            if not p:isAlive() then break end
            local count = math.min(n, q:getCardCount(true))
            if q:isAlive() and count > 0 then
                local c = room:askForExchange(q, "hlxg_zhangwu", count, count, true, "@hlxg_zhangwu-give:" .. p:objectName() .. "::" .. count)
                if c then room:obtainCard(p, c, sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE, q:objectName(), p:objectName(), "hlxg_zhangwu", ""), false); c:deleteLater() end
            end
        end
        if p:isAlive() then
            room:recover(p, sgs.RecoverStruct(p, nil, 3))
            room:setPlayerMark(p, "hlxg_rende_disabled-Clear", 1)
        end
    end,
}
hlxg_zhangwu = sgs.CreateViewAsSkillV2 {
    name = "hlxg_zhangwu", n = 0, frequency = sgs.Skill_Limited, limit_mark = "@hlxg_zhangwu",
    can_activate = function(self, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and request:getInitiator():getMark("@hlxg_zhangwu") > 0
    end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
    create_card = function(self, request) local c = hlxg_zhangwuCard:clone(); c:setSkillName(self:objectName()); return c end,
}
hlxg_rende_liubei3_invalid = sgs.CreateInvaliditySkill {
    name = "#hlxg_rende_liubei3_invalid",
    skill_valid = function(self, p, skill)
        return skill:objectName() ~= "hlxg_rende_liubei3" or p:getMark("hlxg_rende_disabled-Clear") == 0
    end,
}
hlxg_liubei3:addSkill(hlxg_rende_liubei3); hlxg_liubei3:addSkill(hlxg_rende_liubei3_imitate)
hlxg_liubei3:addSkill(hlxg_rende_liubei3_invalid); hlxg_liubei3:addSkill(hlxg_jijiang_liubei3)
hlxg_liubei3:addSkill(hlxg_jijiang_liubei3_skip); hlxg_liubei3:addSkill(hlxg_zhangwu)
extension_hl:insertRelatedSkills("hlxg_rende_liubei3", "#hlxg_rende_liubei3_imitate")
extension_hl:insertRelatedSkills("hlxg_rende_liubei3", "#hlxg_rende_liubei3_invalid")
extension_hl:insertRelatedSkills("hlxg_jijiang_liubei3", "#hlxg_jijiang_liubei3_skip")

hlxg_xiansiCard = sgs.CreateSkillCard {
    name = "hlxg_xiansiCard", target_fixed = false,
    filter = function(self, targets, to, from) return #targets < 2 and to ~= from and from:canDiscard(to, "hej") end,
    feasible = function(self, targets) return #targets <= 2 end,
    on_use = function(self, room, p, targets)
        local count = 0
        for _, to in ipairs(targets) do
            if p:isAlive() and to:isAlive() and p:canDiscard(to, "hej") then
                local id = room:askForCardChosen(p, to, "hej", "hlxg_xiansi", false, sgs.Card_MethodDiscard)
                local equip = room:getCardPlace(id) == sgs.Player_PlaceEquip
                room:throwCard(sgs.Sanguosha:getCard(id), to, p); count = count + 1
                if equip and p:isAlive() and to:isAlive() and to:inMyAttackRange(p) then
                    local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); c:setSkillName("hlxg_xiansi")
                    local use = sgs.CardUseStruct(); use.card = c; use.from = to; use.to:append(p)
                    room:useCard(use, false); c:deleteLater()
                end
            end
        end
        if count == 1 and p:isAlive() then p:drawCards(1, "hlxg_xiansi") end
    end,
}
hlxg_xiansiVS = sgs.CreateViewAsSkillV2 {
    name = "hlxg_xiansi", n = 0,
    can_activate = function(self, request) return request:getPattern() == "@@hlxg_xiansi" end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
    create_card = function(self, request) local c = hlxg_xiansiCard:clone(); c:setSkillName(self:objectName()); return c end,
}
local hlxg_xiansi_name = "hlxg_xiansi"
hlxg_xiansi = sgs.CreateTriggerSkillV2 {
    name = hlxg_xiansi_name, view_as_skill = hlxg_xiansiVS, events = {sgs.EventPhaseStart},
    can_trigger = function(self, event, room, p, data)
        return p and p:isAlive() and p:hasSkill(self:objectName()) and p:getPhase() == sgs.Player_Start and self:objectName() or false
    end,
    on_cost = function(self, event, room, p, ctx) return room:askForUseCard(p, "@@hlxg_xiansi", "@hlxg_xiansi") ~= nil end,
    on_effect = function() return false end,
}
hlxg_liufeng:addSkill(hlxg_xiansi)

sgs.LoadTranslationTable {
    ["hlxg_liubei2"] = "刘备[欢乐修改Q.LE]", ["&hlxg_liubei2"] = "刘备",
    ["hlxg_liubei3"] = "刘备[欢乐修改]", ["&hlxg_liubei3"] = "刘备",
    ["hlxg_liufeng"] = "刘封[欢乐修改]", ["&hlxg_liufeng"] = "刘封",
    ["hlxg_jieying_liubei2"] = "结营",
    [":hlxg_jieying_liubei2"] = "锁定技，你始终横置；当你受到伤害后，你摸一张牌；已横置的角色手牌上限+2；结束阶段，你可以横置一名其他角色。",
    ["@hlxg_jieying_liubei2"] = "结营：你可以横置一名其他角色",
    ["hlxg_longnu"] = "龙怒",
    [":hlxg_longnu"] = "锁定技，出牌阶段开始时，你选择一项：1.失去1点体力，摸两张牌，你的红色手牌于此阶段内均视为火【杀】，你于此阶段内使用火【杀】无距离限制；2.减1点体力上限，你的黑色手牌于此阶段内均视为雷【杀】，你于此阶段内使用雷【杀】无次数限制。",
    ["hlxg_longnu:fire"] = "失去1点体力、摸两张牌，红色手牌视为火杀且火杀无距离限制",
    ["hlxg_longnu:thunder"] = "减1点体力上限，黑色手牌视为雷杀且雷杀无次数限制",
    ["hlxg_rende_liubei3"] = "仁德",
    [":hlxg_rende_liubei3"] = "出牌阶段开始时，你获得3枚“仁”；出牌阶段，你可以将任意张牌交给一名本阶段未因此获得过牌的其他角色，然后你获得等量的“仁”（你至多拥有10枚“仁”）。每回合限一次，当你需要使用或打出基本牌/普通锦囊牌时，你可以弃2/3枚“仁”，视为使用或打出之。",
    ["&hlxg_ren"] = "仁", ["hlxg_ren"] = "仁",
    ["@hlxg_rende_liubei3-imitate"] = "仁德：请选择使用【%src】的目标",
    ["hlxg_jijiang_liubei3"] = "激将", ["hlxg_jijiang_liubei3$"] = "激将",
    [":hlxg_jijiang_liubei3"] = "主公技，出牌阶段结束时，你可以指定一名其他角色，并令另一名攻击范围内含有其的其他蜀势力角色选择一项：1.视为对你指定的角色使用一张【杀】；2.跳过下个出牌阶段。",
    ["@hlxg_jijiang_liubei3-target"] = "激将：指定杀的目标",
    ["@hlxg_jijiang_liubei3-attacker"] = "激将：选择攻击范围内含有%src的另一名蜀势力角色",
    ["hlxg_jijiang_liubei3:slash"] = "视为对指定角色使用杀",
    ["hlxg_jijiang_liubei3:skip"] = "跳过下个出牌阶段",
    ["&hlxg_jijiang_liubei3_skip"] = "激将待跳过", ["hlxg_jijiang_liubei3_skip"] = "激将待跳过",
    ["hlxg_zhangwu"] = "章武",
    [":hlxg_zhangwu"] = "限定技，出牌阶段，你可以令本局游戏中所有获得过“仁德”牌的角色依次交给你X张牌（X为游戏轮数-1，且至多为3），若如此做，你回复3点体力，然后〖仁德〗本回合失效。",
    ["@hlxg_zhangwu"] = "章武", ["@hlxg_zhangwu-give"] = "章武：请交给%src %arg张牌",
    ["hlxg_xiansi"] = "陷嗣",
    [":hlxg_xiansi"] = "准备阶段，你可以弃置至多两名其他角色区域里的各一张牌。若弃置了装备区里的牌且你在其攻击范围内，其视为对你使用一张【杀】；若只弃置了一张牌，你摸一张牌。",
    ["@hlxg_xiansi"] = "陷嗣：选择至多两名其他角色，弃置其区域里的各一张牌",
}
end

-- ==================== c202_06
do
-- c202_06: literal 欢乐杀修改 text; persistent counters are not card tips.
hlxg_liuyong = sgs.General(extension_hl, "hlxg_liuyong", "shu", 3)
hlxg_liuzhang = sgs.General(extension_hl, "hlxg_liuzhang", "qun", 3)
hlxg_liuchan = sgs.General(extension_hl, "hlxg_liuchan", "shu", 3)

hlxg_fengxiang = gu_trigger("hlxg_fengxiang", {sgs.Damaged}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    owner:drawCards(1, self:objectName())
    local maximum, recipients = 0, sgs.SPlayerList()
    for _, q in sgs.qlist(room:getAlivePlayers()) do maximum = math.max(maximum, q:getMark("&hlxg_zhuning_xi")) end
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if q:getMark("&hlxg_zhuning_xi") == maximum then recipients:append(q) end
    end
    for _, q in sgs.qlist(recipients) do
        if q:isAlive() then local r = sgs.RecoverStruct(); r.who = owner; r.recover = 1; room:recover(q, r) end
    end
end, true)

hlxg_zhuningCard = sgs.CreateSkillCard {
    name = "hlxg_zhuningCard", will_throw = false,
    filter = gu_one, feasible = gu_one_feasible,
    on_use = function(self, room, source, targets)
        local to = targets[1]
        room:addPlayerMark(source, "hlxg_zhuning_used-PlayClear")
        local n = self:subcardsLength()
        room:giveCard(source, to, self, "hlxg_zhuning")
        if to:isAlive() then room:addPlayerMark(to, "&hlxg_zhuning_xi", n) end
        if source:isDead() then return end
        local ids = sgs.IntList()
        for _, id in sgs.qlist(room:getAvailableCardList(source, "basic,trick", "hlxg_zhuning", nil, false)) do
            if sgs.Sanguosha:getEngineCard(id):isDamageCard() then ids:append(id) end
        end
        if ids:isEmpty() then return end
        room:fillAG(ids, source)
        local id = room:askForAG(source, ids, true, "hlxg_zhuning")
        room:clearAG(source)
        if id < 0 then return end
        room:setPlayerMark(source, "hlxg_zhuning_card", id + 1)
        room:askForUseCard(source, "@@hlxg_zhuning", "@hlxg_zhuning-use:" .. sgs.Sanguosha:getEngineCard(id):objectName(), -1, sgs.Card_MethodUse, false)
        room:setPlayerMark(source, "hlxg_zhuning_card", 0)
    end,
}
hlxg_zhuning = sgs.CreateViewAsSkillV2 {
    name = "hlxg_zhuning",
    can_activate = function(self, request)
        local p = request:getInitiator()
        if request:getPattern() == "@@hlxg_zhuning" then return p:getMark("hlxg_zhuning_card") > 0 end
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
            and p:getMark("hlxg_zhuning_used-PlayClear") < (p:getMark("hlxg_zhuning_extra-PlayClear") > 0 and 2 or 1)
    end,
    can_select_card = function(self, request, c)
        return request:getPattern() ~= "@@hlxg_zhuning" and request:getInitiator():getCards("he"):contains(c)
    end,
    card_selection_feasible = function(self, request)
        if request:getPattern() == "@@hlxg_zhuning" then return request:getSelectedCardIds():isEmpty() end
        return not request:getSelectedCardIds():isEmpty()
    end,
    create_card = function(self, request)
        if request:getPattern() == "@@hlxg_zhuning" then
            local id = request:getInitiator():getMark("hlxg_zhuning_card") - 1
            if id < 0 then return nil end
            local c = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getEngineCard(id):objectName(), sgs.Card_NoSuit, 0)
            c:setSkillName("hlxg_zhuning"); return c
        end
        local c = hlxg_zhuningCard:clone(); c:addSubcards(request:getSelectedCardIds()); c:setSkillName("hlxg_zhuning"); return c
    end,
}
hlxg_zhuning_mod = sgs.CreateTargetModSkillV2 {
    name = "#hlxg_zhuning_mod", pattern = ".", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local c = ctx:getCard()
        if ctx:getModType() == sgs.TargetModSkill_Residue and c and c:getSkillName() == "hlxg_zhuning"
            and c:getTypeId() ~= sgs.Card_TypeSkill then return sgs.CorrectSkillResult.unlimitedResidue() end
        return 0
    end,
}
hlxg_zhuning_record = gu_record("#hlxg_zhuning_record", {sgs.DamageDone, sgs.CardFinished}, function(self, event, room, p, data)
    if event == sgs.DamageDone then
        local d = data:toDamage()
        if d.card and d.card:getSkillName() == "hlxg_zhuning" then room:setCardFlag(d.card, "hlxg_zhuning_damaged") end
    else
        local use = data:toCardUse()
        if use.card and use.from and use.card:getSkillName() == "hlxg_zhuning"
            and use.card:getTypeId() ~= sgs.Card_TypeSkill then
            if not use.card:hasFlag("hlxg_zhuning_damaged") then room:setPlayerMark(use.from, "hlxg_zhuning_extra-PlayClear", 1) end
            room:setCardFlag(use.card, "-hlxg_zhuning_damaged")
        end
    end
end)
hlxg_liuyong:addSkill(hlxg_fengxiang); hlxg_liuyong:addSkill(hlxg_zhuning)
hlxg_liuyong:addSkill(hlxg_zhuning_mod); hlxg_liuyong:addSkill(hlxg_zhuning_record)
extension_hl:insertRelatedSkills("hlxg_zhuning", "#hlxg_zhuning_mod")
extension_hl:insertRelatedSkills("hlxg_zhuning", "#hlxg_zhuning_record")

hlxg_xiusheng = gu_trigger("hlxg_xiusheng", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Start then return end
    local n = owner:getMark("&hlxg_yinlang_sheng")
    room:setPlayerMark(owner, "&hlxg_yinlang_sheng", 0)
    if n > 0 then owner:drawCards(n, self:objectName()) end
end, true)
hlxg_yinlang = gu_trigger("hlxg_yinlang", {sgs.EventPhaseEnd}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Play or not gu_invoke(owner, self:objectName()) then return end
    local kingdoms = {}
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if not table.contains(kingdoms, q:getKingdom()) then table.insert(kingdoms, q:getKingdom()) end
    end
    local kingdom = room:askForChoice(owner, self:objectName(), table.concat(kingdoms, "+"))
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if q == owner or q:getKingdom() == kingdom then room:addPlayerMark(q, "&hlxg_yinlang_sheng") end
    end
end)
hlxg_yinlang_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#hlxg_yinlang_prohibit", holder_selector = sgs.CorrectSkill_System,
    is_prohibited = function(self, ctx)
        local from, to = ctx:getFrom(), ctx:getTo()
        return from and to and from:getMark("&hlxg_yinlang_sheng") > 0 and to:getMark("&hlxg_yinlang_sheng") == 0
    end,
}
hlxg_huaibi = gu_trigger("hlxg_huaibi$", {sgs.Damaged}, function(self, event, room, p, data, owner)
    if p ~= owner or not owner:hasLordSkill("hlxg_huaibi") then return end
    local from = data:toDamage().from
    if from and from:getMark("&hlxg_yinlang_sheng") > 0 then owner:drawCards(1, "hlxg_huaibi") end
end, true)
hlxg_huaibi_max = sgs.CreateMaxCardsSkillV2 {
    name = "#hlxg_huaibi_max", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local p = ctx:getPrimary()
        return p and p:hasLordSkill("hlxg_huaibi") and p:getMark("&hlxg_yinlang_sheng") or 0
    end,
}
hlxg_liuzhang:addSkill(hlxg_xiusheng); hlxg_liuzhang:addSkill(hlxg_yinlang); hlxg_liuzhang:addSkill(hlxg_huaibi)
hlxg_liuzhang:addSkill(hlxg_yinlang_prohibit); hlxg_liuzhang:addSkill(hlxg_huaibi_max)
extension_hl:insertRelatedSkills("hlxg_yinlang", "#hlxg_yinlang_prohibit")
extension_hl:insertRelatedSkills("hlxg_huaibi", "#hlxg_huaibi_max")

hlxg_xiangle = gu_trigger("hlxg_xiangle", {sgs.TargetConfirmed}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if p ~= owner or not use.card or not use.card:isKindOf("Slash") or not use.from or not use.to:contains(owner) then return end
    local payment = room:askForCard(use.from, ".Basic", "@hlxg_xiangle-discard:" .. owner:objectName(), data, sgs.Card_MethodDiscard, owner, false, "hlxg_xiangle")
    if not payment then
        use = data:toCardUse()
        local nullified = use.nullified_list
        if not table.contains(nullified, owner:objectName()) then table.insert(nullified, owner:objectName()) end
        use.nullified_list = nullified; data:setValue(use)
    end
end, true)
hlxg_fangquan = gu_trigger("hlxg_fangquan", {sgs.EventPhaseChanging}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    local change = data:toPhaseChange()
    if change.to == sgs.Player_Play then
        if not owner:isSkipped(sgs.Player_Play) and gu_invoke(owner, self:objectName()) then
            owner:skip(sgs.Player_Play); room:setPlayerMark(owner, "hlxg_fangquan_pending", 1)
        end
    elseif change.to == sgs.Player_NotActive and owner:getMark("hlxg_fangquan_pending") > 0 then
        room:setPlayerMark(owner, "hlxg_fangquan_pending", 0)
        local to = room:askForPlayerChosen(owner, room:getOtherPlayers(owner), self:objectName(), "@hlxg_fangquan", true, true)
        if to then to:gainAnExtraTurn() end
    end
end)

local function c206_jijiang_supply(source)
    local room = source:getRoom()
    for _, q in sgs.qlist(room:getOtherPlayers(source)) do
        if q:getKingdom() == "shu" then
            local supplied = room:askForCard(q, "slash", "@hlxg_jijiang_liuchan-slash:" .. source:objectName(), sgs.QVariant(source), sgs.Card_MethodResponse, source, false, "hlxg_jijiang_liuchan", true)
            if supplied then
                local c = sgs.Sanguosha:cloneCard(supplied:objectName(), supplied:getSuit(), supplied:getNumber())
                c:addSubcard(supplied); c:setSkillName("hlxg_jijiang_liuchan")
                c:setFlags("YUANBEN")
                c:setFlags("hlxg_jijiang_liuchan_" .. source:objectName() .. "_" .. q:objectName())
                c:deleteLater(); return c
            end
        end
    end
end
hlxg_jijiang_liuchanCard = sgs.CreateSkillCard {
    name = "hlxg_jijiang_liuchanCard", will_throw = false,
    filter = function(self, targets, to, from)
        local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); c:deleteLater()
        local ps = sgs.PlayerList(); for _, q in ipairs(targets) do ps:append(q) end
        return c:targetFilter(ps, to, from) and not from:isProhibited(to, c)
    end,
    feasible = function(self, targets, from)
        local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); c:deleteLater()
        local ps = sgs.PlayerList(); for _, q in ipairs(targets) do ps:append(q) end
        return c:targetsFeasible(ps, from)
    end,
    on_validate = function(self, use)
        use.m_isOwnerUse = false
        local c = c206_jijiang_supply(use.from)
        if c then
            for _, to in sgs.qlist(use.to) do
                if not use.from:canSlash(to, c, false) then return nil end
            end
        end
        return c
    end,
    on_validate_in_response = function(self, source) return c206_jijiang_supply(source) end,
}
hlxg_jijiang_liuchan_vs = sgs.CreateViewAsSkillV2 {
    name = "hlxg_jijiang_liuchan", response_or_use = true,
    can_activate = function(self, request)
        local p = request:getInitiator()
        if not p:hasLordSkill("hlxg_jijiang_liuchan") then return false end
        local found = false
        for _, q in sgs.qlist(p:getAliveSiblings()) do if q:getKingdom() == "shu" then found = true end end
        if not found then return false end
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return sgs.Slash_IsAvailable(p) end
        return request:getPattern() == "slash"
    end,
    can_select_card = function() return false end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
    create_card = function() local c = hlxg_jijiang_liuchanCard:clone(); c:setSkillName("hlxg_jijiang_liuchan"); return c end,
}
hlxg_jijiang_liuchan = gu_trigger("hlxg_jijiang_liuchan$", {sgs.CardAsked}, function(self, event, room, p, data, owner)
    local ask = data:toStringList()
    if p ~= owner or not owner:hasLordSkill("hlxg_jijiang_liuchan") or ask[1] ~= "slash" or ask[3] ~= "response"
        or (ask[2] and string.find(ask[2], "jijiang", 1, true)) or not gu_invoke(owner, "hlxg_jijiang_liuchan", data) then return end
    local c = c206_jijiang_supply(owner)
    if c then room:provide(c); return true end
end)
hlxg_jijiang_liuchan:setViewAsSkill(hlxg_jijiang_liuchan_vs)
hlxg_jijiang_liuchan_draw = gu_record("#hlxg_jijiang_liuchan_draw", {sgs.CardFinished, sgs.PostCardResponded}, function(self, event, room, p, data)
    local c, source
    if event == sgs.CardFinished then local use = data:toCardUse(); c = use.card; source = use.from
    else
        local response = data:toCardResponse()
        if response.m_isUse then return end
        c = response.m_card; source = p
    end
    if not c or not source or not c:isKindOf("Slash") then return end
    for _, q in sgs.qlist(room:getAllPlayers()) do
        local flag = "hlxg_jijiang_liuchan_" .. source:objectName() .. "_" .. q:objectName()
        if c:hasFlag(flag) then
            room:setCardFlag(c, "-" .. flag)
            if source:isAlive() then source:drawCards(1, "hlxg_jijiang_liuchan") end
            if q:isAlive() then q:drawCards(1, "hlxg_jijiang_liuchan") end
        end
    end
end)
extension_hl:addSkills(hlxg_jijiang_liuchan)
hlxg_ruoyu = gu_trigger("hlxg_ruoyu$", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Start or not p:hasLordSkill("hlxg_ruoyu") or p:getMark("hlxg_ruoyu") > 0 then return end
    for _, q in sgs.qlist(room:getAlivePlayers()) do if q:getHp() < p:getHp() then return end end
    room:setPlayerMark(p, "hlxg_ruoyu", 1)
    if room:changeMaxHpForAwakenSkill(p, 1, "hlxg_ruoyu") then
        local r = sgs.RecoverStruct(); r.who = p; r.recover = 1; room:recover(p, r)
        room:acquireSkill(p, "hlxg_jijiang_liuchan")
    end
end, true, sgs.Skill_Wake)
hlxg_liuchan:addSkill(hlxg_xiangle); hlxg_liuchan:addSkill(hlxg_fangquan); hlxg_liuchan:addSkill(hlxg_ruoyu)
hlxg_liuchan:addSkill(hlxg_jijiang_liuchan_draw)
hlxg_liuchan:addRelateSkill("hlxg_jijiang_liuchan")
extension_hl:insertRelatedSkills("hlxg_jijiang_liuchan", "#hlxg_jijiang_liuchan_draw")

sgs.LoadTranslationTable {
    ["hlxg_liuyong"] = "刘永[欢乐修改]", ["&hlxg_liuyong"] = "刘永",
    ["hlxg_liuzhang"] = "刘璋[欢乐修改]", ["&hlxg_liuzhang"] = "刘璋",
    ["hlxg_liuchan"] = "刘禅[欢乐修改]", ["&hlxg_liuchan"] = "刘禅",
    ["hlxg_fengxiang"] = "封乡", [":hlxg_fengxiang"] = "锁定技，当你受到伤害后，你摸一张牌，然后“隙”最多的角色各回复1点体力。",
    ["hlxg_zhuning"] = "诛佞", [":hlxg_zhuning"] = "出牌阶段限一次，你可以交给一名其他角色任意张牌，其获得等量的“隙”，然后你可以视为使用一张无次数限制的伤害牌，若此牌未造成伤害，此技能本阶段改为“出牌阶段限两次”。",
    ["hlxg_zhuningCard"] = "诛佞", ["&hlxg_zhuning_xi"] = "隙",
    ["@hlxg_zhuning-use"] = "诛佞：你可以视为使用【%src】",
    ["hlxg_xiusheng"] = "休生", [":hlxg_xiusheng"] = "锁定技，准备阶段，你弃所有“生”，然后摸等量的牌。",
    ["hlxg_yinlang"] = "引狼", [":hlxg_yinlang"] = "出牌阶段结束时，你可以选择场上的一个势力，你与该势力的所有角色各获得“生”。有“生”的角色不能对没有“生”的角色使用牌。",
    ["&hlxg_yinlang_sheng"] = "生",
    ["hlxg_huaibi"] = "怀璧", ["hlxg_huaibi$"] = "怀璧", [":hlxg_huaibi"] = "主公技，锁定技，你的手牌上限+X（X为“生”数）。当有“生”的角色对你造成伤害后，你摸一张牌。",
    ["hlxg_xiangle"] = "享乐", [":hlxg_xiangle"] = "锁定技，当你成为一名角色使用【杀】的目标后，其选择一项：1.弃置一张基本牌；2.令此【杀】对你无效。",
    ["@hlxg_xiangle-discard"] = "享乐：弃置一张基本牌，否则此【杀】对 %src 无效",
    ["hlxg_fangquan"] = "放权", [":hlxg_fangquan"] = "你可以跳过出牌阶段，然后本回合结束时，你可以令一名其他角色执行一个额外的回合。",
    ["@hlxg_fangquan"] = "放权：你可以令一名其他角色执行一个额外的回合",
    ["hlxg_jijiang_liuchan"] = "激将", ["hlxg_jijiang_liuchan$"] = "激将", ["hlxg_jijiang_liuchanCard"] = "激将",
    [":hlxg_jijiang_liuchan"] = "主公技，当你需要使用或打出【杀】时，你可以令其他蜀势力角色选择是否替你使用或打出【杀】（视为由你使用或打出）；此【杀】结算结束后，你与响应〖激将〗的角色各摸一张牌。",
    ["@hlxg_jijiang_liuchan-slash"] = "激将：你可以为 %src 打出一张【杀】",
    ["hlxg_ruoyu"] = "若愚", ["hlxg_ruoyu$"] = "若愚", [":hlxg_ruoyu"] = "主公技，觉醒技，准备阶段，若你是体力值最小的角色，你加1点体力上限并回复1点体力，然后获得〖激将〗。",
}
end

-- ==================== c202_07
do
-- c202_07: literal 欢乐 variants. Permanent judge and pending-turn state
-- lives in a global recorder so it survives loss/death of the source skill.
local function hl07_kingdoms(room)
    local seen, n = {}, 0
    for _, p in sgs.qlist(room:getAlivePlayers()) do
        local k = p:getKingdom()
        if not seen[k] then seen[k] = true; n = n + 1 end
    end
    return n
end
local function hl07_fangquan(room, owner, immediate)
    local to = room:askForPlayerChosen(owner, room:getOtherPlayers(owner), "hljx_fangquan", "@hljx_fangquan", true, true)
    if not to then return end
    if not owner:isNude() then
        local cards = room:askForExchange(owner, "hljx_fangquan", owner:getCardCount(true), 0, true, "@hljx_fangquan-give", true)
        if cards then
            if cards:subcardsLength() > 0 then room:obtainCard(to, cards, false) end
            cards:deleteLater()
        end
    end
    if immediate then to:gainAnExtraTurn() else
        local names = gu_names(owner, "hljx_fangquan_pending")
        table.insert(names, to:objectName()); gu_setnames(owner, "hljx_fangquan_pending", names)
    end
end
hljx_xiangle = gu_trigger("hljx_xiangle", {sgs.TargetConfirmed, sgs.RoundEnd}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.RoundEnd then
        if owner:getMark("hljx_xiangle_used_lun") > 0 then return end
        local n = math.floor(owner:getSeat() / 2)
        local available = 0
        for _, c in sgs.qlist(owner:getCards("he")) do if not owner:isJilei(c) then available = available + 1 end end
        if available < n then return end
        if not gu_invoke(owner, "hljx_xiangle", data) then return end
        if n > 0 and not room:askForDiscard(owner, "hljx_xiangle", n, n, false, true, "@hljx_xiangle-round") then return end
        owner:turnOver()
        if owner:isAlive() then hl07_fangquan(room, owner, true) end
        return
    end
    local use = data:toCardUse()
    if not use.card or not use.card:isKindOf("Slash") or not use.from or not use.to:contains(owner) then return end
    if not room:askForCard(use.from, "BasicCard", "@hljx_xiangle-basic:" .. owner:objectName(), data, sgs.Card_MethodDiscard, owner, false, "hljx_xiangle") then
        local nullified = use.nullified_list
        table.insert(nullified, owner:objectName()); use.nullified_list = nullified; data:setValue(use)
    end
end, true)
hljx_sishu = gu_trigger("hljx_sishu", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Play then return end
    local to = room:askForPlayerChosen(owner, room:getAlivePlayers(), "hljx_sishu", "@hljx_sishu", true, true)
    if to then room:setPlayerMark(to, "&hljx_sishu", 1) end
end)
hljx_fangquan = gu_trigger("hljx_fangquan", {sgs.EventPhaseChanging, sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to == sgs.Player_Play and not owner:isSkipped(sgs.Player_Play) and gu_invoke(owner, "hljx_fangquan", data) then
            owner:skip(sgs.Player_Play); room:setPlayerMark(owner, "hljx_fangquan_skipped-Clear", 1)
        end
    elseif p:getPhase() == sgs.Player_Discard and owner:getMark("hljx_fangquan_skipped-Clear") > 0 then
        hl07_fangquan(room, owner, false)
    end
end)
local function hl07_borrow(source)
    local room = source:getRoom()
    -- Provision asks cannot recursively borrow another player's Slash.
    room:setPlayerFlag(source, "hljx_jijiang_liuchan_asking")
    for _, liege in sgs.qlist(room:getOtherPlayers(source)) do
        if liege:getKingdom() == "shu" then
            local card = room:askForCard(liege, "slash", "@hljx_jijiang_liuchan-slash:" .. source:objectName(), sgs.QVariant(source:objectName()), sgs.Card_MethodResponse, source, false, "hljx_jijiang_liuchan", true)
            if card then
                local slash = sgs.Sanguosha:cloneCard(card:objectName(), card:getSuit(), card:getNumber())
                slash:addSubcard(card); slash:setSkillName("hljx_jijiang_liuchan")
                slash:setFlags("hljx_jijiang_liuchan_from_" .. liege:objectName())
                slash:deleteLater(); room:setPlayerFlag(source, "-hljx_jijiang_liuchan_asking")
                return slash
            end
        end
    end
    room:setPlayerFlag(source, "-hljx_jijiang_liuchan_asking")
    return nil
end
hljx_jijiang_liuchanCard = sgs.CreateSkillCard {
    name = "hljx_jijiang_liuchanCard", will_throw = false,
    filter = function(self, targets, to, from)
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); slash:deleteLater()
        local list = sgs.PlayerList(); for _, p in ipairs(targets) do list:append(p) end
        return slash:targetFilter(list, to, from) and not from:isProhibited(to, slash)
    end,
    feasible = function(self, targets, from)
        if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return #targets == 0 end
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0); slash:deleteLater()
        local list = sgs.PlayerList(); for _, p in ipairs(targets) do list:append(p) end
        return slash:targetsFeasible(list, from)
    end,
    on_validate = function(self, use) return hl07_borrow(use.from) end,
    on_validate_in_response = function(self, source) return hl07_borrow(source) end,
}
hljx_jijiang_liuchan = sgs.CreateViewAsSkillV2 {
    name = "hljx_jijiang_liuchan" .. "$", n = 0, response_or_use = true,
    can_activate = function(self, request)
        local p = request:getInitiator()
        if not p:hasLordSkill("hljx_jijiang_liuchan") then return false end
        for _, other in sgs.qlist(p:getAliveSiblings()) do
            if other:hasFlag("hljx_jijiang_liuchan_asking") then return false end
        end
        local available = false
        for _, other in sgs.qlist(p:getAliveSiblings()) do if other:getKingdom() == "shu" then available = true end end
        if not available then return false end
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return sgs.Slash_IsAvailable(p) end
        return request:getPattern() == "slash"
    end,
    can_select_card = function() return false end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
    create_card = function(self, request)
        local card = hljx_jijiang_liuchanCard:clone(); card:setSkillName("hljx_jijiang_liuchan"); return card
    end,
}
hljx_ruoyu = gu_trigger("hljx_ruoyu" .. "$", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Start or not p:hasLordSkill("hljx_ruoyu") or p:getMark("hljx_ruoyu") > 0 then return end
    for _, other in sgs.qlist(room:getAlivePlayers()) do if other:getHp() < owner:getHp() then return end end
    room:setPlayerMark(owner, "hljx_ruoyu", 1)
    if room:changeMaxHpForAwakenSkill(owner, 1, "hljx_ruoyu") then
        local recover = sgs.RecoverStruct(); recover.who = owner; recover.recover = 1; room:recover(owner, recover)
        room:handleAcquireDetachSkills(owner, "hljx_jijiang_liuchan|hljx_sishu")
    end
end, true, sgs.Skill_Wake)
hljx_liuchan = sgs.General(extension_hl, "hljx_liuchan", "shu", 3)
hljx_liuchan:addSkill(hljx_xiangle); hljx_liuchan:addSkill(hljx_fangquan); hljx_liuchan:addSkill(hljx_ruoyu)
extension_hl:addSkills(hljx_sishu); extension_hl:addSkills(hljx_jijiang_liuchan)
hljx_liuchan:addRelateSkill("hljx_sishu"); hljx_liuchan:addRelateSkill("hljx_jijiang_liuchan")

hlxg_zongshi_liubiao = sgs.CreateMaxCardsSkillV2 {
    name = "hlxg_zongshi_liubiao", holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(self, ctx) return 2 end,
}
hlxg_zishou = gu_trigger("hlxg_zishou", {sgs.DrawNCards}, function(self, event, room, p, data, owner)
    if p ~= owner or not gu_invoke(owner, "hlxg_zishou", data) then return end
    data:setValue(data:toInt() + 2); room:setPlayerMark(owner, "hlxg_zishou-Clear", 1)
end)
hlxg_zishou_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#hlxg_zishou_prohibit", holder_selector = sgs.CorrectSkill_System,
    gate = {"primary.mark:hlxg_zishou-Clear"},
    is_prohibited = function(self, ctx)
        local from, to = ctx:getFrom(), ctx:getTo()
        return from and to and from ~= to and from:getMark("hlxg_zishou-Clear") > 0
    end,
}
hlxg_liubiao = sgs.General(extension_hl, "hlxg_liubiao", "qun", 3)
hlxg_liubiao:addSkill(hlxg_zongshi_liubiao); hlxg_liubiao:addSkill(hlxg_zishou); hlxg_liubiao:addSkill(hlxg_zishou_prohibit)
extension_hl:insertRelatedSkills("hlxg_zishou", "#hlxg_zishou_prohibit")
hljx_zongshi = gu_trigger("hljx_zongshi", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p == owner and p:getPhase() == sgs.Player_Start and p:getHandcardNum() > p:getHp() then room:setPlayerMark(p, "hljx_zongshi-Clear", 1) end
end, true)
hljx_zongshi_max = sgs.CreateMaxCardsSkillV2 {
    name = "#hljx_zongshi_max", holder_selector = sgs.CorrectSkill_Primary,
    correct_func = function(self, ctx) return hl07_kingdoms(ctx:getPrimary():getRoom()) end,
}
hljx_zongshi_slash = sgs.CreateTargetModSkillV2 {
    name = "#hljx_zongshi_slash", pattern = "Slash", holder_selector = sgs.CorrectSkill_System,
    gate = {"primary.mark:hljx_zongshi-Clear"},
    correct_func = function(self, ctx)
        if ctx:getModType() == sgs.TargetModSkill_Residue and ctx:getPrimary():getMark("hljx_zongshi-Clear") > 0 then return sgs.CorrectSkillResult.unlimitedResidue() end
        return false
    end,
}
hljx_zishou = gu_trigger("hljx_zishou", {sgs.DrawNCards}, function(self, event, room, p, data, owner)
    if p ~= owner or not gu_invoke(owner, "hljx_zishou", data) then return end
    data:setValue(data:toInt() + hl07_kingdoms(room)); room:setPlayerMark(owner, "hljx_zishou-Clear", 1)
end)
hljx_liubiao = sgs.General(extension_hl, "hljx_liubiao", "qun", 3)
hljx_liubiao:addSkill(hljx_zongshi); hljx_liubiao:addSkill(hljx_zongshi_max); hljx_liubiao:addSkill(hljx_zongshi_slash); hljx_liubiao:addSkill(hljx_zishou)
extension_hl:insertRelatedSkills("hljx_zongshi", "#hljx_zongshi_max")
extension_hl:insertRelatedSkills("hljx_zongshi", "#hljx_zongshi_slash")

hljx_xiangle_record = gu_record("#hljx_xiangle_record", {sgs.CardUsed, sgs.CardResponded, sgs.PostCardResponded, sgs.CardFinished, sgs.StartJudge, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.StartJudge then
        local judge = data:toJudge()
        if judge.reason == "indulgence" and judge.who:getMark("&hljx_sishu") > 0 then judge.good = not judge.good; data:setValue(judge) end
    elseif event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to ~= sgs.Player_NotActive then return end
        local pending = gu_names(p, "hljx_fangquan_pending"); p:removeTag("hljx_fangquan_pending")
        for _, name in ipairs(pending) do
            for _, to in sgs.qlist(room:getAlivePlayers()) do if to:objectName() == name then to:gainAnExtraTurn() end end
        end
    else
        local card, actor, response_use
        if event == sgs.CardResponded or event == sgs.PostCardResponded then
            local response = data:toCardResponse(); card = response.m_card; actor = p; response_use = response.m_isUse
        else local use = data:toCardUse(); card = use.card; actor = use.from end
        if not card or not actor then return end
        if event == sgs.CardUsed or (event == sgs.CardResponded and response_use) then
            room:setPlayerMark(actor, "hljx_xiangle_used_lun", 1)
        end
        if not card:isKindOf("Slash") then return end
        if event == sgs.CardFinished or (event == sgs.PostCardResponded and not response_use) then
            for _, donor in sgs.qlist(room:getAllPlayers()) do
                local flag = "hljx_jijiang_liuchan_from_" .. donor:objectName()
                if card:hasFlag(flag) then
                    room:setCardFlag(card, "-" .. flag)
                    if actor:isAlive() then actor:drawCards(1, "hljx_jijiang_liuchan") end
                    if donor:isAlive() then donor:drawCards(1, "hljx_jijiang_liuchan") end
                end
            end
        end
        if event == sgs.CardFinished or event == sgs.PostCardResponded or actor:getKingdom() ~= "shu" then return end
        for _, lord in sgs.qlist(room:getAlivePlayers()) do
            if lord ~= actor and lord:hasLordSkill("hljx_jijiang_liuchan") and lord:getPhase() == sgs.Player_NotActive and lord:getMark("hljx_jijiang_liuchan-Clear") == 0 then
                if gu_invoke(actor, "hljx_jijiang_liuchan", sgs.QVariant(lord:objectName())) then
                    room:setPlayerMark(lord, "hljx_jijiang_liuchan-Clear", 1); lord:drawCards(1, "hljx_jijiang_liuchan")
                end
            end
        end
    end
end)
extension_hl:addSkills(hljx_xiangle_record)
hljx_zishou_prevent = sgs.CreateRuleSkillV2 {
    name = "#hljx_zishou_prevent", global = true, frequency = sgs.Skill_Compulsory,
    events = {sgs.DamageCaused},
    can_trigger = function(self, event, room, p, data)
        local damage = data:toDamage()
        if damage.from and damage.to and damage.from ~= damage.to and damage.from:getMark("hljx_zishou-Clear") > 0 then return self:objectName(), damage.from end
        return false
    end,
    on_effect = function() return true end,
}
extension_hl:addSkills(hljx_zishou_prevent)
extension_hl:insertRelatedSkills("hljx_zishou", "#hljx_zishou_prevent")
sgs.LoadTranslationTable {
    ["hljx_liuchan"] = "刘禅[欢乐界]", ["&hljx_liuchan"] = "刘禅",
    ["hljx_xiangle"] = "享乐",
    [":hljx_xiangle"] = "锁定技，当你成为一名角色使用【杀】的目标后，其选择一项：1.弃置一张基本牌；2.令此【杀】对你无效。每轮结束时，若你本轮未使用过牌，你可以弃置X张牌并翻面（X为你座次的一半，向下取整），然后发动一次〖放权〗。",
    ["hljx_sishu"] = "思蜀", [":hljx_sishu"] = "出牌阶段开始时，你可以选择一名角色，其本局游戏【乐不思蜀】的判定结果反转。",
    ["hljx_fangquan"] = "放权", [":hljx_fangquan"] = "你可以跳过出牌阶段，然后弃牌阶段开始时，你可以选择一名其他角色，交给其任意张牌并令其于回合结束时执行一个额外的回合。",
    ["hljx_jijiang_liuchan"] = "激将", [":hljx_jijiang_liuchan"] = "主公技，当你需要使用或打出【杀】时，你可以令其他蜀势力角色选择是否替你使用或打出【杀】（视为由你使用或打出）；此【杀】结算结束后，你与响应〖激将〗的角色各摸一张牌。当其他蜀势力角色于你的回合外使用、打出或替你使用或打出【杀】时，其可以令你摸一张牌（每回合限一次）。",
    ["hljx_ruoyu"] = "若愚", [":hljx_ruoyu"] = "主公技，觉醒技，准备阶段，若你是体力值最小的角色，你加1点体力上限并回复1点体力，然后获得〖激将〗和〖思蜀〗。",
    ["@hljx_xiangle-basic"] = "享乐：弃置一张基本牌，否则此【杀】对 %src 无效",
    ["@hljx_xiangle-round"] = "享乐：弃置指定数量的牌，然后翻面并发动放权",
    ["@hljx_sishu"] = "思蜀：选择一名角色，永久反转其乐不思蜀判定",
    ["&hljx_sishu"] = "思蜀",
    ["@hljx_fangquan"] = "放权：选择获得额外回合的其他角色",
    ["@hljx_fangquan-give"] = "放权：交给该角色任意张牌（可以为零）",
    ["@hljx_jijiang_liuchan-slash"] = "激将：你可以替 %src 打出一张【杀】",
    ["hlxg_liubiao"] = "刘表[欢乐修改]", ["&hlxg_liubiao"] = "刘表",
    ["hlxg_zongshi_liubiao"] = "宗室", [":hlxg_zongshi_liubiao"] = "锁定技，你的手牌上限+2。",
    ["hlxg_zishou"] = "自守", [":hlxg_zishou"] = "摸牌阶段，你可以多摸两张牌。若如此做，本回合你使用牌不能指定其他角色为目标。",
    ["hljx_liubiao"] = "刘表[欢乐界]", ["&hljx_liubiao"] = "刘表",
    ["hljx_zongshi"] = "宗室", [":hljx_zongshi"] = "锁定技，你的手牌上限+X（X为势力数）。准备阶段，若你的手牌数大于体力值，本回合你使用【杀】无次数限制。",
    ["hljx_zishou"] = "自守", [":hljx_zishou"] = "摸牌阶段，你可以多摸X张牌（X为势力数）。若如此做，防止本回合你对其他角色造成的伤害。",
}
end

-- ==================== c203_01
do
-- c203_01: literal 欢乐杀修改 variants.
hlxg_liuchen = sgs.General(extension_hl, "hlxg_liuchen", "shu", 4)
hlxg_liubian = sgs.General(extension_hl, "hlxg_liubian", "qun", 3)
hlxg_huatuo = sgs.General(extension_hl, "hlxg_huatuo", "qun", 3)

hlxg_qinwangCard = sgs.CreateSkillCard {
    name = "hlxg_qinwangCard", target_fixed = true, will_throw = false,
    on_use = function(self, room, source)
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if not source:isAlive() then break end
            if p:isAlive() and p:getKingdom() == "shu" then
                local c = room:askForCard(p, "BasicCard", "@hlxg_qinwang-give:" .. source:objectName(), sgs.QVariant(source), sgs.Card_MethodNone, source, false, "hlxg_qinwang")
                if c then
                    -- Per recipient/per physical card marks survive the card leaving the hand.
                    local ids = c:isVirtualCard() and c:getSubcards() or gu_ids({c})
                    for _, id in sgs.qlist(ids) do room:setPlayerMark(source, "hlxg_qinwang_" .. id .. "-Clear", 1) end
                    room:obtainCard(source, c, false)
                    if p:isAlive() and gu_invoke(source, "hlxg_qinwang", sgs.QVariant(p)) then p:drawCards(1, "hlxg_qinwang") end
                end
            end
        end
    end,
}
hlxg_qinwang = sgs.CreateViewAsSkillV2 {
    name = "hlxg_qinwang$", limit_scope = sgs.Skill_Limit_Phase, phase_name = "Play", max_usage_limit = 1,
    can_activate = function(self, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY and request:getInitiator():hasLordSkill("hlxg_qinwang")
    end,
    can_select_card = function() return false end,
    create_card = function() return hlxg_qinwangCard:clone() end,
}
local function hl_zhanjue_ids(p)
    local ids = sgs.IntList()
    for _, id in sgs.qlist(p:handCards()) do
        if p:getMark("hlxg_qinwang_" .. id .. "-Clear") == 0 then ids:append(id) end
    end
    return ids
end
hlxg_zhanjue = sgs.CreateViewAsSkillV2 {
    name = "hlxg_zhanjue",
    can_activate = function(self, request)
        return (request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
                or (request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and request:getPattern() == "duel"))
            and request:getInitiator():getMark("hlxg_zhanjue_draw-PlayClear") < 3
            and not hl_zhanjue_ids(request:getInitiator()):isEmpty()
    end,
    can_select_card = function() return false end,
    create_card = function(self, request)
        local ids = hl_zhanjue_ids(request:getInitiator())
        if ids:isEmpty() then return nil end
        local c = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
        c:addSubcards(ids); c:setSkillName(self:objectName()); return c
    end,
}
hlxg_zhanjue_record = gu_record("#hlxg_zhanjue_record", {sgs.DamageDone, sgs.CardFinished, sgs.CardsMoveOneTime, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.EventPhaseChanging then
        for _, q in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(q, "hlxg_zhanjue_draw-PlayClear", 0) end
        return
    elseif event == sgs.CardsMoveOneTime then
        local move = data:toMoveOneTime()
        if move.to and move.to_place == sgs.Player_PlaceHand and move.reason.m_skillName == "hlxg_zhanjue" then
            for _, q in sgs.qlist(room:getAlivePlayers()) do
                if move.to:objectName() == q:objectName() and q:getMark("hlxg_zhanjue_counting") > 0 then
                    room:addPlayerMark(q, "hlxg_zhanjue_draw-PlayClear", move.card_ids:length())
                end
            end
        end
        return
    elseif event == sgs.DamageDone then
        local d = data:toDamage()
        if d.card and d.card:getSkillName() == "hlxg_zhanjue" and d.to then room:setCardFlag(d.card, "hlxg_zhanjue_hit_" .. d.to:objectName()) end
    else
        local use = data:toCardUse()
        if not use.card or use.card:getSkillName() ~= "hlxg_zhanjue" or not use.from then return end
        -- The user and each damaged role each draw once, even if the user was damaged.
        for _, q in sgs.qlist(room:getAllPlayers(true)) do
            local hit = use.card:hasFlag("hlxg_zhanjue_hit_" .. q:objectName())
            if hit then room:setCardFlag(use.card, "-hlxg_zhanjue_hit_" .. q:objectName()) end
            if q:isAlive() and (q == use.from or hit) then
                if q == use.from then room:addPlayerMark(q, "hlxg_zhanjue_counting") end
                q:drawCards(1, "hlxg_zhanjue")
                if q == use.from then room:removePlayerMark(q, "hlxg_zhanjue_counting") end
            end
        end
    end
end)
hlxg_zhanjue_damage = gu_trigger("#hlxg_zhanjue_damage", {sgs.Damaged}, function(self, event, room, p, data, owner)
    -- The helper is attached to the same holder as 战绝.
    local d = data:toDamage()
    if p == owner and owner:hasSkill("hlxg_zhanjue") and d.card and d.card:isKindOf("Duel")
        and d.from and owner:canDiscard(d.from, "hej") and gu_invoke(owner, "hlxg_zhanjue", data) then
        local id = room:askForCardChosen(owner, d.from, "hej", "hlxg_zhanjue", false, sgs.Card_MethodDiscard)
        room:throwCard(id, d.from, owner)
    end
end)

hlxg_yuwei = sgs.CreateTriggerSkillV2 {
    name = "hlxg_yuwei$", frequency = sgs.Skill_Compulsory,
    events = {sgs.TargetConfirmed}, can_trigger = function() return false end,
}
hlxg_shiyuan = gu_trigger("hlxg_shiyuan", {sgs.TargetConfirmed}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if p ~= owner or not use.from or use.from == owner or not use.to:contains(owner) then return end
    local n = use.from:getHp() > owner:getHp() and 3 or (use.from:getHp() == owner:getHp() and 2 or 1)
    local current = room:getCurrent()
    local limit = owner:hasLordSkill("hlxg_yuwei") and current and current ~= owner and current:getKingdom() == "qun" and 2 or 1
    local mark = "hlxg_shiyuan_" .. n .. "-Clear"
    if owner:getMark(mark) < limit and gu_invoke(owner, self:objectName(), data) then
        room:addPlayerMark(owner, mark); owner:drawCards(n, self:objectName())
    end
end)
hlxg_dushi = sgs.CreateTriggerSkillV2 {
    name = "hlxg_dushi", frequency = sgs.Skill_Compulsory, events = {sgs.QuitDying, sgs.Death},
    can_trigger = function(self, event, room, p, data)
        if not p or not p:hasSkill(self:objectName()) then return false end
        if event == sgs.Death and data:toDeath().who ~= p then return false end
        if event == sgs.QuitDying and not p:isAlive() then return false end
        return self:objectName(), p
    end,
    on_effect = function(self, event, room, p, ctx)
        local owner = ctx.owner or p
        room:detachSkillFromPlayer(owner, self:objectName())
        local targets = room:getOtherPlayers(owner)
        if not targets:isEmpty() then
            local to = room:askForPlayerChosen(owner, targets, self:objectName(), "@hlxg_dushi-transfer", false, true)
            if to then room:acquireSkill(to, self:objectName()) end
        end
        return false
    end,
}
hlxg_dushi_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#hlxg_dushi_prohibit", holder_selector = sgs.CorrectSkill_System,
    is_prohibited = function(self, ctx)
        local from, to, card = ctx:getFrom(), ctx:getTo(), ctx:getCard()
        return from and to and from ~= to and card and card:isKindOf("Peach")
            and to:hasSkill("hlxg_dushi") and to:hasFlag("Global_Dying")
    end,
}
-- System selector keeps the prohibition working when 毒逝 is transferred.
extension_hl:addSkills(hlxg_dushi_prohibit)

-- Standard Jijiu has exactly the same 回合外/red-card Peach conversion.
hlxg_qingnang = gu_active("hlxg_qingnang", 1, 0, 0,
    function(self, targets, to, from) return #targets == 0 end, gu_one_feasible,
    function(self, room, source, targets)
        local recover = sgs.RecoverStruct(); recover.who = source; recover.recover = 1
        room:recover(targets[1], recover)
    end)

hlxg_liuchen:addSkill(hlxg_qinwang); hlxg_liuchen:addSkill(hlxg_zhanjue)
hlxg_liuchen:addSkill(hlxg_zhanjue_record); hlxg_liuchen:addSkill(hlxg_zhanjue_damage)
extension_hl:insertRelatedSkills("hlxg_zhanjue", "#hlxg_zhanjue_record")
extension_hl:insertRelatedSkills("hlxg_zhanjue", "#hlxg_zhanjue_damage")
hlxg_liubian:addSkill(hlxg_yuwei); hlxg_liubian:addSkill(hlxg_dushi); hlxg_liubian:addSkill(hlxg_shiyuan)
extension_hl:insertRelatedSkills("hlxg_dushi", "#hlxg_dushi_prohibit")
hlxg_huatuo:addSkill("jijiu"); hlxg_huatuo:addSkill(hlxg_qingnang)
sgs.LoadTranslationTable {
    ["hlxg_liuchen"] = "刘谌[欢乐修改]", ["&hlxg_liuchen"] = "刘谌",
    ["hlxg_liubian"] = "刘辩[欢乐修改]", ["&hlxg_liubian"] = "刘辩",
    ["hlxg_huatuo"] = "华佗[欢乐修改]", ["&hlxg_huatuo"] = "华佗",
    ["hlxg_qinwang$"] = "勤王", ["hlxg_qinwang"] = "勤王", ["hlxg_qinwangCard"] = "勤王",
    [":hlxg_qinwang"] = "主公技，出牌阶段限一次，你可以令其他蜀势力角色依次选择是否交给你一张基本牌（以此法获得的牌本回合不会被〖战绝〗使用），若其如此做，你可以令其摸一张牌。",
    ["@hlxg_qinwang-give"] = "你可以交给 %src 一张基本牌",
    ["hlxg_zhanjue"] = "战绝",
    [":hlxg_zhanjue"] = "你可以将所有手牌当【决斗】使用，然后你与因此受伤的角色各摸一张牌；若你本阶段因此技能而摸过至少三张牌，你本阶段不能发动此技能转化【决斗】。当你受到【决斗】的伤害后，你可以弃置伤害来源区域里的一张牌。",
    ["hlxg_yuwei$"] = "余威", ["hlxg_yuwei"] = "余威",
    [":hlxg_yuwei"] = "主公技，锁定技，其他群势力角色的回合内，〖诗怨〗改为“每回合各限两次”。",
    ["hlxg_dushi"] = "毒逝", ["@hlxg_dushi-transfer"] = "令一名其他角色获得“毒逝”",
    [":hlxg_dushi"] = "锁定技，你的濒死结算中，其他角色不能对你使用【桃】。当你脱离濒死状态后或死亡时，你失去此技能并令一名其他角色获得之。",
    ["hlxg_shiyuan"] = "诗怨",
    [":hlxg_shiyuan"] = "每回合各限一次，当你成为其他角色使用牌的目标后，若其体力值大于/等于/小于你，你可以摸三/两/一张牌。",
    ["hlxg_jijiu"] = "急救", [":hlxg_jijiu"] = "你于回合外可以将一张红色牌当【桃】使用。",
    ["hlxg_qingnang"] = "青囊", ["hlxg_qingnangCard"] = "青囊",
    [":hlxg_qingnang"] = "出牌阶段限一次，你可以令一名角色回复1点体力。",
}
end

-- ==================== c203_02
do
-- c203_02: literal Huanle variants.
hljx_huatuo = sgs.General(extension_hl, "hljx_huatuo", "qun", 3)
hlxg_huaxiong = sgs.General(extension_hl, "hlxg_huaxiong", "qun", 6)
hljx_huaxiong = sgs.General(extension_hl, "hljx_huaxiong", "qun", 6)

hljx_jijiu = sgs.CreateViewAsSkillV2 {
    name = "hljx_jijiu", response_or_use = true,
    can_activate = function(self, request)
        local p = request:getInitiator()
        return p and p:getPhase() == sgs.Player_NotActive
            and request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
            and string.find(request:getPattern(), "peach", 1, true) ~= nil
            and p:getMark("Global_PreventPeach") == 0
    end,
    can_select_card = function(self, request, card)
        return request:getSelectedCardIds():isEmpty() and card:isRed()
    end,
    create_card = function(self, request)
        local ids = request:getSelectedCardIds()
        if ids:length() ~= 1 then return nil end
        local c = sgs.Sanguosha:getCard(ids:first())
        local peach = sgs.Sanguosha:cloneCard("peach", c:getSuit(), c:getNumber())
        peach:addSubcard(c); peach:setSkillName(self:objectName())
        return peach
    end,
}
hljx_jijiu.response_pattern = "peach"
hljx_jijiu_discard = gu_trigger("#hljx_jijiu_discard", {sgs.CardFinished}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from ~= owner or not use.card or use.card:getSkillName() ~= "hljx_jijiu" then return end
    local targets = sgs.SPlayerList()
    for _, other in sgs.qlist(room:getOtherPlayers(owner)) do
        if owner:canDiscard(other, "h") then targets:append(other) end
    end
    if targets:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, targets, "hljx_jijiu", "@hljx_jijiu-discard", true, true)
    if to then
        local id = room:askForCardChosen(owner, to, "h", "hljx_jijiu", false, sgs.Card_MethodDiscard)
        room:throwCard(id, to, owner)
    end
end)

hljx_qingnang = gu_active("hljx_qingnang", 1, 0, math.huge,
    function(self, targets, to, from) return #targets < self:subcardsLength() + 1 end,
    function(self, targets) return #targets == self:subcardsLength() + 1 end,
    function(self, room, source, targets)
        gu_throw(room, source, self:getSubcards(), "hljx_qingnang")
        for _, to in ipairs(targets) do
            if to:isAlive() then
                room:addPlayerMark(to, "hljx_qingnang_" .. source:objectName())
                room:gainMaxHp(to, 1, "hljx_qingnang")
                local rec = sgs.RecoverStruct(); rec.who = source; rec.recover = 1
                room:recover(to, rec)
            end
        end
    end,
    function(request, c) return not request:getInitiator():isJilei(c) end)
hljx_qingnang_restore = gu_record("#hljx_qingnang_restore", {sgs.EventPhaseStart}, function(self, event, room, p, data)
    if not p or p:getPhase() ~= sgs.Player_RoundStart then return end
    local key = "hljx_qingnang_" .. p:objectName()
    for _, to in sgs.qlist(room:getAllPlayers()) do
        local n = to:getMark(key)
        room:setPlayerMark(to, key, 0)
        if to:isAlive() and n > 0 then room:loseMaxHp(to, n, "hljx_qingnang") end
    end
end)
extension_hl:addSkills(hljx_qingnang_restore)

local function hl_yaowu_effect(self, event, room, p, data, owner)
    if event == sgs.Damaged then
        local damage = data:toDamage()
        if p ~= owner or not damage.card or not damage.card:isKindOf("Slash") then return end
        if damage.card:isRed() and damage.from and damage.from:isAlive() then
            damage.from:drawCards(1, self:objectName())
        elseif damage.card:isBlack() then owner:drawCards(1, self:objectName()) end
        if self:objectName() == "hljx_yaowu" then
            damage.card:setFlags("hljx_yaowu_" .. owner:objectName())
        end
    else
        local use = data:toCardUse()
        if use.card and use.card:hasFlag("hljx_yaowu_" .. owner:objectName()) then
            use.card:setFlags("-hljx_yaowu_" .. owner:objectName())
            room:obtainCard(owner, use.card, true)
        end
    end
end
hlxg_yaowu = gu_trigger("hlxg_yaowu", {sgs.Damaged}, hl_yaowu_effect, true)
hljx_yaowu = gu_trigger("hljx_yaowu", {sgs.Damaged, sgs.CardFinished}, hl_yaowu_effect, true)

hljx_yangwei = gu_trigger("hljx_yangwei", {sgs.CardFinished, sgs.EventPhaseEnd}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    if event == sgs.CardFinished then
        local use = data:toCardUse()
        if owner:getPhase() == sgs.Player_Play and use.card and use.card:isKindOf("Slash") then
            if use.card:isRed() then room:setPlayerMark(owner, "hljx_yangwei_color-Clear", 1)
            elseif use.card:isBlack() then room:setPlayerMark(owner, "hljx_yangwei_color-Clear", 2) end
        end
    elseif owner:getPhase() == sgs.Player_Play and owner:getMark("hljx_yangwei_slashes-Clear") >= 3 then
        local rec = sgs.RecoverStruct(); rec.who = owner; rec.recover = 1
        room:recover(owner, rec)
    end
end)
hljx_yangwei_record = gu_record("#hljx_yangwei_record", {sgs.CardUsed}, function(self, event, room, p, data)
    local use = data:toCardUse()
    if not p or not use.card or not use.card:isKindOf("Slash") then return end
    room:addPlayerMark(p, "hljx_yangwei_slashes-Clear")
    local color = p:getMark("hljx_yangwei_color-Clear")
    if (color == 1 and not use.card:isRed()) or (color == 2 and not use.card:isBlack()) then
        room:setPlayerMark(p, "hljx_yangwei_color-Clear", 0)
    end
end)
extension_hl:addSkills(hljx_yangwei_record)
hljx_yangwei_residue = sgs.CreateTargetModSkillV2 {
    name = "#hljx_yangwei_residue", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        if ctx:getModType() ~= sgs.TargetModSkill_Residue then return false end
        local p, c = ctx:getPrimary(), ctx:getCard()
        if not p or not p:hasSkill("hljx_yangwei") or not c or not c:isKindOf("Slash") then return false end
        local color = p:getMark("hljx_yangwei_color-Clear")
        if (color == 1 and not c:isRed()) or (color == 2 and not c:isBlack()) then
            return sgs.CorrectSkillResult.unlimitedResidue()
        end
        return false
    end,
}
hljx_huatuo:addSkill(hljx_jijiu); hljx_huatuo:addSkill(hljx_jijiu_discard); hljx_huatuo:addSkill(hljx_qingnang)
hlxg_huaxiong:addSkill(hlxg_yaowu)
hljx_huaxiong:addSkill(hljx_yangwei); hljx_huaxiong:addSkill(hljx_yangwei_residue); hljx_huaxiong:addSkill(hljx_yaowu)
extension_hl:insertRelatedSkills("hljx_jijiu", "#hljx_jijiu_discard")
extension_hl:insertRelatedSkills("hljx_qingnang", "#hljx_qingnang_restore")
extension_hl:insertRelatedSkills("hljx_yangwei", "#hljx_yangwei_record")
extension_hl:insertRelatedSkills("hljx_yangwei", "#hljx_yangwei_residue")
sgs.LoadTranslationTable {
    ["hljx_huatuo"] = "华佗[欢乐界]", ["&hljx_huatuo"] = "华佗",
    ["hlxg_huaxiong"] = "华雄[欢乐修改]", ["&hlxg_huaxiong"] = "华雄",
    ["hljx_huaxiong"] = "华雄[欢乐界]", ["&hljx_huaxiong"] = "华雄",
    ["hljx_jijiu"] = "急救", [":hljx_jijiu"] = "你于回合外可以将一张红色牌当【桃】使用，然后可以弃置一名其他角色的一张手牌。",
    ["@hljx_jijiu-discard"] = "急救：你可以弃置一名其他角色的一张手牌",
    ["hljx_qingnang"] = "青囊", [":hljx_qingnang"] = "出牌阶段限一次，你可以选择任意名角色，弃置X张牌（X为选择的角色数-1），然后令这些角色各加1点体力上限并回复1点体力；回合开始时，这些角色各减1点体力上限。",
    ["hlxg_yaowu"] = "耀武", [":hlxg_yaowu"] = "锁定技，当你受到【杀】造成的伤害时，若此【杀】：为红色，伤害来源摸一张牌；为黑色，你摸一张牌。",
    ["hljx_yangwei"] = "扬威", [":hljx_yangwei"] = "当你于出牌阶段内使用一张非无色【杀】后，你本回合使用下一张颜色不同的【杀】无次数限制。出牌阶段结束时，若你本回合使用过至少三张【杀】，你回复1点体力。",
    ["hljx_yaowu"] = "耀武", [":hljx_yaowu"] = "锁定技，当你受到【杀】造成的伤害时，若此【杀】：为红色，伤害来源摸一张牌；为黑色，你摸一张牌。此【杀】结算结束后，你获得之。",
}
end

-- ==================== c203_03
do
-- c203_03: literal 欢乐杀修改 variants.
hlxg_huaxiong2 = sgs.General(extension_hl, "hlxg_huaxiong2", "qun", 6)
hlxg_yangwei = gu_trigger("hlxg_yangwei", {sgs.CardsMoveOneTime, sgs.ConfirmDamage, sgs.DamageForseen, sgs.CardUsed, sgs.EventPhaseEnd},
    function(self, event, room, player, data, p)
        if event == sgs.CardsMoveOneTime then
            local m = data:toMoveOneTime()
            local reason = bit32.band(m.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
            if m.to == p and m.to_place == sgs.Player_PlaceHand and p:getPhase() ~= sgs.Player_Draw
                and reason == sgs.CardMoveReason_S_REASON_DRAW then
                local old = p:getMark("hlxg_yangwei_draw-Clear")
                room:addPlayerMark(p, "hlxg_yangwei_draw-Clear", m.card_ids:length())
                if old < 2 and old + m.card_ids:length() >= 2 then room:addPlayerMark(p, "&hlxg_yangwei_deal") end
            end
            if m.from == p and p:getPhase() ~= sgs.Player_Discard and reason == sgs.CardMoveReason_S_REASON_DISCARD then
                local old = p:getMark("hlxg_yangwei_discard-Clear")
                room:addPlayerMark(p, "hlxg_yangwei_discard-Clear", m.card_ids:length())
                if old < 2 and old + m.card_ids:length() >= 2 then room:addPlayerMark(p, "&hlxg_yangwei_receive") end
            end
        elseif event == sgs.ConfirmDamage or event == sgs.DamageForseen then
            local d = data:toDamage()
            local mark = event == sgs.ConfirmDamage and "&hlxg_yangwei_deal" or "&hlxg_yangwei_receive"
            if (event == sgs.ConfirmDamage and d.from == p or event == sgs.DamageForseen and d.to == p) and p:getMark(mark) > 0 then
                d.damage = d.damage + p:getMark(mark)
                room:setPlayerMark(p, mark, 0)
                data:setValue(d)
            end
        elseif event == sgs.CardUsed and player == p and p:getPhase() == sgs.Player_Play then
            local use = data:toCardUse()
            if use.card and use.card:isKindOf("Slash") then room:addPlayerMark(p, "hlxg_yangwei_slash-PlayClear") end
        elseif event == sgs.EventPhaseEnd and player == p and p:getPhase() == sgs.Player_Play
            and p:getMark("hlxg_yangwei_slash-PlayClear") >= 3 then
            local r = sgs.RecoverStruct(); r.who = p; r.recover = 1; room:recover(p, r)
        end
        return false
    end, true)
hlxg_bojue = gu_active("hlxg_bojue", 2, 0, 0, gu_one, gu_one_feasible,
    function(self, room, source, targets)
        local other = targets[1]
        -- Commit both choices before either card movement or public choice log.
        local a = room:askForChoice(source, "hlxg_bojue", "draw+discard")
        local b = room:askForChoice(other, "hlxg_bojue", "draw+discard")
        for i, p in ipairs({source, other}) do
            local choice = i == 1 and a or b
            if p:isAlive() then
                if choice == "draw" then p:drawCards(1, "hlxg_bojue")
                else room:askForDiscard(p, "hlxg_bojue", 1, 1, false, true) end
            end
        end
        for _, actor in ipairs({source, other}) do
            local victim = actor == source and other or source
            if actor:isAlive() and victim:isAlive() then
                if a ~= b then
                    if actor:canDiscard(victim, "he") then
                        local id = room:askForCardChosen(actor, victim, "he", "hlxg_bojue", false, sgs.Card_MethodDiscard)
                        room:throwCard(id, victim, actor)
                    end
                else
                    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
                    slash:setSkillName("_hlxg_bojue")
                    if actor:canSlash(victim, slash, false) then
                        local use = sgs.CardUseStruct(); use.card = slash; use.from = actor; use.to:append(victim)
                        room:useCard(use, false)
                    end
                    slash:deleteLater()
                end
            end
        end
    end)
hlxg_huaxiong2:addSkill(hlxg_yangwei)
hlxg_huaxiong2:addSkill(hlxg_bojue)

hlxg_beimihu = sgs.General(extension_hl, "hlxg_beimihu", "qun", 3, false)
hlxg_zonggui = gu_trigger("hlxg_zonggui", {sgs.GameStart, sgs.EventPhaseStart},
    function(self, event, room, player, data, p)
        if player ~= p or (event == sgs.EventPhaseStart and p:getPhase() ~= sgs.Player_RoundStart) then return false end
        local candidates = sgs.SPlayerList()
        local minimum = 10000
        for _, q in sgs.qlist(room:getOtherPlayers(p)) do
            if event == sgs.GameStart then minimum = math.min(minimum, q:getHp()) end
        end
        for _, q in sgs.qlist(room:getOtherPlayers(p)) do
            if event == sgs.GameStart and q:getHp() == minimum or event ~= sgs.GameStart and q:getMark("&hlxg_zonggui_kui") == 0 then candidates:append(q) end
        end
        if not candidates:isEmpty() then
            local q = room:askForPlayerChosen(p, candidates, "hlxg_zonggui", "@hlxg_zonggui", event ~= sgs.GameStart, true)
            if q then room:addPlayerMark(q, "&hlxg_zonggui_kui") end
        end
        return false
    end)
hlxg_canshi_beimihu = gu_trigger("hlxg_canshi_beimihu", {sgs.TargetSpecifying},
    function(self, event, room, player, data, p)
        local use = data:toCardUse()
        if not use.card or not use.from or use.to:length() ~= 1 or not (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then return false end
        if use.to:first() == p and use.from:getMark("&hlxg_zonggui_kui") > 0 and gu_invoke(p, self:objectName(), data) then
            use.to:removeOne(p)
            room:setPlayerMark(use.from, "&hlxg_zonggui_kui", 0)
            data:setValue(use)
            return false
        end
        if use.from ~= p then return false end
        local candidates = sgs.SPlayerList()
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            if q:getMark("&hlxg_zonggui_kui") > 0 and not use.to:contains(q) and not room:isProhibited(p, q, use.card) then candidates:append(q) end
        end
        if candidates:isEmpty() then return false end
        p:setTag("hlxg_canshi_beimihu_use", data)
        local chosen = room:askForPlayersChosen(p, candidates, self:objectName(), 0, candidates:length(), "@hlxg_canshi_beimihu", true, true)
        p:removeTag("hlxg_canshi_beimihu_use")
        for _, q in sgs.qlist(chosen) do
            use.to:append(q); room:setPlayerMark(q, "&hlxg_zonggui_kui", 0)
        end
        room:sortByActionOrder(use.to); data:setValue(use)
        return false
    end)
hlxg_guju = gu_trigger("hlxg_guju", {sgs.Damaged}, function(self, event, room, player, data, p)
    if player and player:getMark("&hlxg_zonggui_kui") > 0 then p:drawCards(1, self:objectName()) end
    return false
end, true)
hlxg_beimihu:addSkill(hlxg_zonggui)
hlxg_beimihu:addSkill(hlxg_canshi_beimihu)
hlxg_beimihu:addSkill(hlxg_guju)

hlxg_luzhi = sgs.General(extension_hl, "hlxg_luzhi", "qun", 3)
hlxg_mingren = gu_trigger("hlxg_mingren", {sgs.GameStart, sgs.EventPhaseStart},
    function(self, event, room, player, data, p)
        if player ~= p or (event == sgs.EventPhaseStart and p:getPhase() ~= sgs.Player_Finish) then return false end
        if event == sgs.GameStart then p:drawCards(2, self:objectName()) end
        if p:isKongcheng() then return false end
        local card = room:askForExchange(p, self:objectName(), 1, 1, false, "@hlxg_mingren", event ~= sgs.GameStart)
        if card then
            local old = p:getPile("hlxg_mingren_ren")
            p:addToPile("hlxg_mingren_ren", card, true)
            gu_obtain(room, p, old, self:objectName())
            card:deleteLater()
        end
        return false
    end)
hlxg_zhenliang = gu_active("hlxg_zhenliang", 1, 1, 1,
    function(self, targets, to, from) return gu_one(self, targets, to, from) and from:inMyAttackRange(to) end,
    gu_one_feasible, function(self, room, source, targets)
        room:setPlayerMark(source, "&hlxg_zhenliang_yin", 1)
        gu_throw(room, source, self:getSubcards(), "hlxg_zhenliang")
        if source:isAlive() and targets[1]:isAlive() then
            local d = sgs.DamageStruct(); d.from = source; d.to = targets[1]; d.damage = 1; d.reason = "hlxg_zhenliang"; room:damage(d)
        end
    end, function(request, c)
        local p = request:getInitiator(); local pile = p:getPile("hlxg_mingren_ren")
        return not pile:isEmpty() and not p:isJilei(c) and c:getColor() == sgs.Sanguosha:getCard(pile:first()):getColor()
    end, function(p) return p:getMark("&hlxg_zhenliang_yin") == 0 and not p:getPile("hlxg_mingren_ren"):isEmpty() end)
hlxg_zhenliang_response = gu_trigger("#hlxg_zhenliang_response", {sgs.CardFinished, sgs.PostCardResponded},
    function(self, event, room, player, data, p)
        if p:getPhase() ~= sgs.Player_NotActive or p:getMark("&hlxg_zhenliang_yin") == 0 then return false end
        local card
        if event == sgs.CardFinished then card = data:toCardUse().card
        else
            local response = data:toCardResponse()
            if response.m_isUse then return false end -- Response uses finish via CardFinished.
            card = response.m_card
        end
        local pile = p:getPile("hlxg_mingren_ren")
        if not card or card:isKindOf("SkillCard") or pile:isEmpty() or card:getTypeId() ~= sgs.Sanguosha:getCard(pile:first()):getTypeId() then return false end
        local target = room:askForPlayerChosen(p, room:getAlivePlayers(), "hlxg_zhenliang", "@hlxg_zhenliang", true, true)
        if target then room:setPlayerMark(p, "&hlxg_zhenliang_yin", 0); target:drawCards(2, "hlxg_zhenliang") end
        return false
    end)
hlxg_luzhi:addSkill(hlxg_mingren)
hlxg_luzhi:addSkill(hlxg_zhenliang)
hlxg_luzhi:addSkill(hlxg_zhenliang_response)
extension_hl:insertRelatedSkills("hlxg_zhenliang", "#hlxg_zhenliang_response")
sgs.LoadTranslationTable{
    ["hlxg_huaxiong2"] = "华雄[欢乐修改]", ["&hlxg_huaxiong2"] = "华雄",
    ["hlxg_yangwei"] = "扬威",
    [":hlxg_yangwei"] = "锁定技，当你每回合于摸牌阶段外摸第二张牌后，你下一次造成的伤害+1；当你每回合于弃牌阶段外弃置第二张牌后，你下一次受到的伤害+1。出牌阶段结束时，若你本阶段使用过至少三张【杀】，你回复1点体力。",
    ["&hlxg_yangwei_deal"] = "扬威造伤", ["&hlxg_yangwei_receive"] = "扬威受伤",
    ["hlxg_bojue"] = "搏决", ["hlxg_bojueCard"] = "搏决",
    [":hlxg_bojue"] = "出牌阶段限两次，你可以与一名其他角色同时选择摸或弃置一张牌，然后若你与其的选择：不同，你与其各弃置对方一张牌；相同，你与其各视为对对方使用一张【杀】。",
    ["hlxg_bojue:draw"] = "摸一张牌", ["hlxg_bojue:discard"] = "弃置一张牌",
    ["hlxg_beimihu"] = "卑弥呼[欢乐修改]", ["&hlxg_beimihu"] = "卑弥呼",
    ["hlxg_zonggui"] = "纵傀", ["&hlxg_zonggui_kui"] = "傀",
    [":hlxg_zonggui"] = "游戏开始时，你令体力值最小的一名其他角色获得“傀”。回合开始时，你可以令一名没有“傀”的其他角色获得“傀”。",
    ["@hlxg_zonggui"] = "纵傀：选择获得“傀”的其他角色",
    ["hlxg_canshi_beimihu"] = "蚕食",
    [":hlxg_canshi_beimihu"] = "当一名角色使用基本牌或普通锦囊牌指定你为唯一目标时，若其有“傀”，你可以取消之，然后其弃其“傀”；当你使用基本牌或普通锦囊牌指定唯一目标时，你可以多指定任意名有“傀”的角色为目标，然后其各弃其“傀”。",
    ["@hlxg_canshi_beimihu"] = "蚕食：选择任意名有“傀”的额外目标",
    ["hlxg_guju"] = "骨疽", [":hlxg_guju"] = "锁定技，当有“傀”的角色受到伤害后，你摸一张牌。",
    ["hlxg_luzhi"] = "卢植[欢乐修改]", ["&hlxg_luzhi"] = "卢植",
    ["hlxg_mingren"] = "明任", ["hlxg_mingren_ren"] = "任",
    [":hlxg_mingren"] = "游戏开始时，你摸两张牌，然后将一张手牌置于你的武将牌上，称为“任”。结束阶段，你可以用一张手牌替换“任”。",
    ["@hlxg_mingren"] = "明任：将一张手牌置为“任”（结束阶段可取消替换）",
    ["hlxg_zhenliang"] = "贞良", ["hlxg_zhenliangCard"] = "贞良", ["&hlxg_zhenliang_yin"] = "贞良阴",
    [":hlxg_zhenliang"] = "转换技，阳：出牌阶段限一次，你可以选择你攻击范围内的一名其他角色并弃置一张与“任”颜色相同的牌，对其造成1点伤害；阴：你的回合外，当一名角色使用或打出的牌结算结束后，若此牌与“任”类别相同，你可以令一名角色摸两张牌。",
    ["@hlxg_zhenliang"] = "贞良：你可以令一名角色摸两张牌",
}
end


-- ===== diyba b01 =====
do
-- diyba batch b01 (3D10J 002/003/005/006)
local function diyba_trigger(name, events, effect, compulsory)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        frequency = compulsory and sgs.Skill_Compulsory or sgs.Skill_NotFrequent,
        can_trigger = function(self, event, room, player, data)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then return self:objectName(), p end
            end
            return false
        end,
        on_effect = function(self, event, room, player, ctx)
            local cancelled = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then
                    cancelled = effect(self, event, room, player, ctx.original_data, p) or cancelled
                end
            end
            return cancelled
        end,
    }
end
local function diyba_record(name, events, fn)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        can_trigger = function() return false end,
        on_record = function(self, event, room, player, ctx)
            fn(self, event, room, player, ctx.original_data)
        end,
    }
end

diyba_10j_zhangti = sgs.General(extension, "diyba_10j_zhangti", "wu", 3)

-- 张悌 逆势 / 覆江
diyba_nishi = diyba_trigger("diyba_nishi", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Start then return end
    local minother
    for _, o in sgs.qlist(room:getOtherPlayers(owner)) do
        if not minother or o:getHandcardNum() < minother then minother = o:getHandcardNum() end
    end
    if not minother then return end
    room:sendCompulsoryTriggerLog(owner, self:objectName())
    if owner:getHandcardNum() < minother then
        local n = minother + 1 - owner:getHandcardNum()
        if n > 0 then owner:drawCards(n, self:objectName()) end
    end
    local cands = sgs.SPlayerList()
    for _, o in sgs.qlist(room:getOtherPlayers(owner)) do
        if o:getHandcardNum() < owner:getHandcardNum() then cands:append(o) end
    end
    if cands:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, cands, self:objectName(), "@diyba_nishi", false, true)
    if not to then return end
    local moves = sgs.CardsMoveList()
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, owner:objectName(), to:objectName(), self:objectName(), "")
    moves:append(sgs.CardsMoveStruct(owner:handCards(), owner, to, sgs.Player_PlaceHand, sgs.Player_PlaceHand, reason))
    moves:append(sgs.CardsMoveStruct(to:handCards(), to, owner, sgs.Player_PlaceHand, sgs.Player_PlaceHand, reason))
    room:moveCardsAtomic(moves, false)
end, true)
diyba_fujiang = diyba_trigger("diyba_fujiang", {sgs.CardsMoveOneTime}, function(self, event, room, p, data, owner)
    local move = data:toMoveOneTime()
    if not move.from or move.from:objectName() ~= owner:objectName() or not move.to
        or move.to:objectName() == owner:objectName() or move.to_place ~= sgs.Player_PlaceHand then return end
    local to
    for _, o in sgs.qlist(room:getOtherPlayers(owner)) do
        if o:objectName() == move.to:objectName() then to = o end
    end
    if not to or to:isDead() or not owner:askForSkillInvoke(self:objectName(), data) then return end
    if to:hasEquip() then
        local id = room:askForCardChosen(owner, to, "e", self:objectName())
        if id and id >= 0 then room:throwCard(id, to, owner) end
    else
        room:damage(sgs.DamageStruct(self:objectName(), owner, to, 1))
    end
end)
diyba_10j_zhangti:addSkill(diyba_nishi)
diyba_10j_zhangti:addSkill(diyba_fujiang)

sgs.LoadTranslationTable {
    ["diyba_10j_zhangti"] = "张悌", ["#diyba_10j_zhangti"] = "枯浪哀潮", ["designer:diyba_10j_zhangti"] = "晨曦千载",
    ["diyba_nishi"] = "逆势",
    [":diyba_nishi"] = "锁定技，准备阶段，你须与手牌少于你的一名其他角色交换手牌。若你为手牌最少的角色，你须先将手牌摸至比手牌数最少的其他角色多一张牌。",
    ["@diyba_nishi"] = "逆势：选择一名手牌少于你的其他角色，与其交换手牌",
    ["diyba_fujiang"] = "覆江",
    [":diyba_fujiang"] = "其他角色获得你的牌时，若其装备区里：有牌，你可以弃置其中一张牌；没有牌，你可以对该角色造成1点伤害。",
}
end
-- ===== diyba b02 =====
do
-- diyba b02: skipped (diyba_10j_liuhong removed)
end
-- ===== diyba b03 =====
do
-- diyba b03: skipped (diyba_12j_sunhe, diyba_12j_zhouchu removed)
end
-- ===== diyba b04 =====
do
-- diyba batch b04: all generals skipped (diyba_xj_kebineng, diyba_xj_zhangkai)
end
-- ===== diyba b05 =====
do
-- diyba b05: all generals (lie / zhangcheng / baoxin) skipped; see fix report
end
-- ===== diyba b06 =====
do
-- diyba batch b06 (3D15J001)
local function diyba_b06_trigger(name, events, effect, compulsory)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        frequency = compulsory and sgs.Skill_Compulsory or sgs.Skill_NotFrequent,
        can_trigger = function(self, event, room, player, data)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then return self:objectName(), p end
            end
            return false
        end,
        on_effect = function(self, event, room, player, ctx)
            local cancelled = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then
                    cancelled = effect(self, event, room, player, ctx.original_data, p) or cancelled
                end
            end
            return cancelled
        end,
    }
end
local function diyba_b06_dummy(ids)
    local c = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    c:addSubcards(ids)
    return c
end
diyba_15j_dingfei = sgs.General(extension, "diyba_15j_dingfei", "wei", 3)

-- 丁斐 畜突 / 坦婪
diyba_chutu = diyba_b06_trigger("diyba_chutu", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p == owner or p:getPhase() ~= sgs.Player_Play or owner:isNude() or p:isDead() then return end
    if not owner:askForSkillInvoke(self:objectName(), data) then return end
    local put = room:askForExchange(owner, self:objectName(), owner:getCardCount(true), 1, "@diyba_chutu", "", ".", true)
    if not put or put:subcardsLength() == 0 then return end
    room:moveCardsAtomic(sgs.CardsMoveStruct(put:getSubcards(), owner, nil, sgs.Player_PlaceHand, sgs.Player_DrawPile,
        sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, owner:objectName(), self:objectName(), "")), false)
    p:drawCards(4, self:objectName())
    local ids = sgs.IntList()
    local n = math.min(4, p:getHandcardNum())
    if n > 0 then
        local dis = room:askForExchange(p, self:objectName(), n, n, "@diyba_chutu-discard", "", ".|.|.|hand", false)
        if dis then ids = dis:getSubcards() end
    end
    local pile = sgs.IntList()
    if not ids:isEmpty() then
        local d = diyba_b06_dummy(ids)
        room:throwCard(d, self:objectName(), p)
        d:deleteLater()
        for _, id in sgs.qlist(ids) do
            if room:getCardPlace(id) == sgs.Player_DiscardPile then pile:append(id) end
        end
    end
    if pile:isEmpty() then return end
    local choice = room:askForChoice(p, self:objectName(), "diyba_chutu_use+diyba_chutu_put", data)
    if choice == "diyba_chutu_use" then
        for _, id in sgs.qlist(pile) do
            local c = sgs.Sanguosha:getCard(id)
            if owner:isAlive() and p:isAlive() and room:getCardPlace(id) == sgs.Player_DiscardPile
                and (c:isKindOf("Slash") or c:isKindOf("TrickCard") and c:isNDTrick()) then
                room:useCard(sgs.CardUseStruct(c, owner, p), false)
            end
        end
    else
        local avail = sgs.IntList()
        for _, id in sgs.qlist(pile) do
            if room:getCardPlace(id) == sgs.Player_DiscardPile then avail:append(id) end
        end
        if not avail:isEmpty() then
            room:fillAG(avail, owner)
            local picked = {}
            while not avail:isEmpty() do
                local id = room:askForAG(owner, avail, true, self:objectName())
                if id < 0 then break end
                avail:removeOne(id)
                room:takeAG(nil, id, false)
                table.insert(picked, id)
            end
            room:clearAG(owner)
            for _, id in ipairs(picked) do
                room:moveCardTo(sgs.Sanguosha:getCard(id), nil, sgs.Player_DrawPile, false)
            end
        end
        room:setPlayerMark(p, "diyba_chutu_limit-Clear", 1)
    end
end)
diyba_chutu_prohibit = sgs.CreateProhibitSkillV2 {
    name = "#diyba_chutu_prohibit",
    holder_selector = sgs.CorrectSkill_System,
    gate = { "secondary.mark:diyba_chutu_limit-Clear" },
    is_prohibited = function(self, ctx)
        local from, to = ctx:getFrom(), ctx:getTo()
        return from:getMark("diyba_chutu_limit-Clear") > 0 and from ~= to
    end,
}
diyba_tanlan = diyba_b06_trigger("diyba_tanlan", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or p:getPhase() ~= sgs.Player_Finish then return end
    local list = sgs.SPlayerList()
    for _, o in sgs.qlist(room:getOtherPlayers(owner)) do
        if not o:isKongcheng() then list:append(o) end
    end
    if list:isEmpty() or not owner:askForSkillInvoke(self:objectName(), data) then return end
    local to = room:askForPlayerChosen(owner, list, self:objectName(), "@diyba_tanlan")
    local id = room:askForCardChosen(owner, to, "h", self:objectName())
    room:obtainCard(owner, id, false)
    local x = owner:getHandcardNum()
    if to:isDead() or owner:isDead() or to:getHandcardNum() < x or x == 0 then return end
    local give = room:askForExchange(to, self:objectName(), to:getHandcardNum(), x, "@diyba_tanlan-exchange", "", ".|.|.|hand", true)
    if not give or give:subcardsLength() < x then return end
    local mine = sgs.IntList()
    for _, c in sgs.qlist(owner:getHandcards()) do mine:append(c:getEffectiveId()) end
    local theirs = give:getSubcards()
    local d1, d2 = diyba_b06_dummy(theirs), diyba_b06_dummy(mine)
    room:obtainCard(owner, d1, false)
    room:obtainCard(to, d2, false)
    d1:deleteLater() d2:deleteLater()
end)
diyba_15j_dingfei:addSkill(diyba_chutu)
diyba_15j_dingfei:addSkill(diyba_chutu_prohibit)
diyba_15j_dingfei:addSkill(diyba_tanlan)

sgs.LoadTranslationTable {
    ["diyba_15j_dingfei"] = "丁斐", ["#diyba_15j_dingfei"] = "贪不殉利", ["designer:diyba_15j_dingfei"] = "左小白",
    ["diyba_chutu"] = "畜突",
    [":diyba_chutu"] = "其他角色的出牌阶段开始时，你可以将至少一张牌置于牌堆顶，令其摸四张牌，弃置其四张手牌，然后其选择一项：你依次对其使用以此法弃置的【杀】或普通锦囊牌；你将以此法弃置的任意张牌置于牌堆顶且其本回合不能对其他角色使用牌。",
    ["@diyba_chutu-discard"] = "畜突：请弃置四张手牌",
    ["@diyba_chutu"] = "畜突：请选择至少一张牌置于牌堆顶",
    ["diyba_chutu_use"] = "你依次对其使用以此法弃置的【杀】或普通锦囊牌",
    ["diyba_chutu_put"] = "你将以此法弃置的任意张牌置于牌堆顶且其本回合不能对其他角色使用牌",
    ["diyba_tanlan"] = "坦婪",
    [":diyba_tanlan"] = "结束阶段，你可以获得一名其他角色的一张手牌，然后其可以用至少X张手牌交换你的所有手牌（X为你的手牌数）。",
    ["@diyba_tanlan"] = "坦婪：选择一名其他角色，获得其一张手牌",
    ["@diyba_tanlan-exchange"] = "坦婪：你可以用至少X张手牌交换其所有手牌",
}
end
-- ===== diyba b07 =====
do
-- diyba b07: xumiao / yangxi skipped (no literal implementation possible)
end
-- ===== diyba b08 =====
do
-- b08: diyba 3D15J 步度根
diyba_15j_budugen = sgs.General(extension, "diyba_15j_budugen", "qun", 4)

local function diyba_raolue_run(room, source, to)
    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
    duel:setSkillName("diyba_raolue")
    if source:isProhibited(to, duel) then duel:deleteLater() return end
    room:useCard(sgs.CardUseStruct(duel, source, to), false)
    duel:deleteLater()
    if not source:isAlive() or not to:isAlive() then return end
    if room:askForChoice(to, "diyba_raolue", "swap+noswap", ToData(source)) == "swap" then
        if not source:isKongcheng() or not to:isKongcheng() then
            local move = sgs.CardsMoveList()
            move:append(sgs.CardsMoveStruct(source:handCards(), to, sgs.Player_PlaceHand,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, source:objectName(), to:objectName(), "diyba_raolue", "")))
            move:append(sgs.CardsMoveStruct(to:handCards(), source, sgs.Player_PlaceHand,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, to:objectName(), source:objectName(), "diyba_raolue", "")))
            room:moveCardsAtomic(move, false)
        end
    else
        if source:askForSkillInvoke("diyba_raolue_draw", ToData(to)) then
            source:drawCards(2, "diyba_raolue")
        end
        if source:isAlive() and to:isAlive() and to:getHandcardNum() >= source:getHandcardNum()
            and source:askForSkillInvoke("diyba_raolue", ToData(to)) then
            diyba_raolue_run(room, source, to)
        end
    end
end

local diyba_raolue_card = sgs.CreateSkillCard {
    name = "diyba_raolueCard", will_throw = false,
    filter = function(self, targets, to, from)
        return #targets == 0 and to:objectName() ~= from:objectName()
            and to:getHandcardNum() >= from:getHandcardNum()
    end,
    feasible = function(self, targets) return #targets == 1 end,
    on_use = function(self, room, source, targets)
        diyba_raolue_run(room, source, targets[1])
    end,
}
diyba_raolue = sgs.CreateViewAsSkillV2 {
    name = "diyba_raolue",
    limit_scope = sgs.Skill_Limit_Phase, phase_name = "Play", max_usage_limit = 1,
    can_activate = function(self, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    can_select_card = function(self, request, c) return false end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
    create_card = function(self, request)
        local c = diyba_raolue_card:clone()
        c:setSkillName("diyba_raolue")
        return c
    end,
}
diyba_15j_budugen:addSkill(diyba_raolue)

sgs.LoadTranslationTable {
    ["diyba_15j_budugen"] = "步度根",
    ["#diyba_15j_budugen"] = "霜刃露寒",
    ["designer:diyba_15j_budugen"] = "七哀",
    ["diyba_raolue"] = "扰掠",
    [":diyba_raolue"] = "出牌阶段限一次，你可视为对一名手牌数不小于你的角色使用【决斗】，然后于结算后令该角色选择是否与你交换手牌；若其选择否，你可以摸两张牌，然后若该角色手牌数仍不小于你，你可对其再次发动“扰掠”。",
    ["diyba_raolue:swap"] = "与其交换手牌",
    ["diyba_raolue:noswap"] = "不交换",
    ["diyba_raolue_draw"] = "扰掠",
}
end

-- ===== diyba b09 =====
do
-- diyba batch b09 (邓方). 司马芝, 张举&张纯, 庞淯 skipped.
local function diyba_trigger(name, events, effect, compulsory)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        frequency = compulsory and sgs.Skill_Compulsory or sgs.Skill_NotFrequent,
        can_trigger = function(self, event, room, player, data)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then return self:objectName(), p end
            end
            return false
        end,
        on_effect = function(self, event, room, player, ctx)
            local cancelled = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then
                    cancelled = effect(self, event, room, player, ctx.original_data, p) or cancelled
                end
            end
            return cancelled
        end,
    }
end
local function diyba_record(name, events, fn)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        can_trigger = function() return false end,
        on_record = function(self, event, room, player, ctx)
            fn(self, event, room, player, ctx.original_data)
        end,
    }
end

diyba_xj_dengfang = sgs.General(extension, "diyba_xj_dengfang", "qun", 2)

------------------------------------------------------------------ 邓方
diyba_guoyi_card = sgs.CreateSkillCard {
    name = "diyba_guoyiCard", will_throw = false,
    filter = function(self, targets, to, from) return #targets == 0 end,
    feasible = function(self, targets) return #targets == 1 end,
    on_use = function(self, room, source, targets)
        local to = targets[1]
        to:drawCards(1, "diyba_guoyi")
        if to:isDead() then return end
        local choice = "diyba_guoyi_discard"
        if to:getCardCount(true) >= 2 then
            choice = room:askForChoice(to, "diyba_guoyi", "diyba_guoyi_give+diyba_guoyi_discard")
        end
        if choice == "diyba_guoyi_give" then
            local ex = room:askForExchange(to, "diyba_guoyi", 2, 2, true, "@diyba_guoyi_give")
            if not ex then return end
            local red, black, none = false, false, false
            for _, id in sgs.qlist(ex:getSubcards()) do
                local c = sgs.Sanguosha:getCard(id)
                if c:isRed() then red = true elseif c:isBlack() then black = true else none = true end
                room:showCard(to, id)
            end
            room:obtainCard(source, ex, true)
            if not red then room:setPlayerCardLimitation(source, "use", ".|red", true) end
            if not black then room:setPlayerCardLimitation(source, "use", ".|black", true) end
            if not none then room:setPlayerCardLimitation(source, "use", ".|.|.|.|colorless", true) end
        else
            source:setTag("diyba_guoyi_target", sgs.QVariant(to:objectName()))
        end
    end,
}
diyba_guoyi = sgs.CreateViewAsSkillV2 {
    name = "diyba_guoyi",
    limit_scope = sgs.Skill_Limit_Phase, phase_name = "Play", max_usage_limit = 1,
    can_activate = function(self, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    can_select_card = function(self, request, c) return false end,
    card_selection_feasible = function(self, request) return true end,
    create_card = function(self, request)
        local c = diyba_guoyi_card:clone()
        c:setSkillName("diyba_guoyi")
        return c
    end,
}
diyba_guoyi_use = diyba_record("#diyba_guoyi_use", {sgs.CardFinished, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to == sgs.Player_NotActive then p:removeTag("diyba_guoyi_target") end
        return
    end
    local use = data:toCardUse()
    if use.from ~= p or not p:hasSkill("diyba_guoyi") or use.card:isKindOf("SkillCard") then return end
    local name = p:getTag("diyba_guoyi_target"):toString()
    if name == "" then return end
    local to = room:findPlayer(name)
    if not to or to:isDead() or to:isNude() then return end
    if p:askForSkillInvoke("diyba_guoyi", data) then
        local id = room:askForCardChosen(p, to, "he", "diyba_guoyi", false, sgs.Card_MethodDiscard)
        room:throwCard(id, to, p)
    end
end)
diyba_xj_dengfang:addSkill(diyba_guoyi)
diyba_xj_dengfang:addSkill(diyba_guoyi_use)

sgs.LoadTranslationTable {
    ["diyba_xj_dengfang"] = "邓方", ["#diyba_xj_dengfang"] = "御土如磐", ["designer:diyba_xj_dengfang"] = "yyuaN",
    ["diyba_guoyi"] = "果毅",
    [":diyba_guoyi"] = "出牌阶段限一次，你可以令一名角色摸一张牌并选择一项：1.展示并交给你两张牌，你本回合只能使用这些颜色的牌；2.你本回合使用牌后，可以弃置其一张牌。",
    ["diyba_guoyi_give"] = "展示并交给其两张牌，其本回合只能使用这些颜色的牌",
    ["diyba_guoyi_discard"] = "其本回合使用牌后，可以弃置你一张牌",
    ["@diyba_guoyi_give"] = "果毅：展示并交给其两张牌",
}
end
-- ===== diyba b10 =====
do
-- b10: diyba 朱异 (更狩). 阎行 skipped. 廖立/刘基 skipped (体力1.5).
local function diyba10_trigger(name, events, effect)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        frequency = sgs.Skill_NotFrequent,
        can_trigger = function(self, event, room, player, data)
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then return self:objectName(), p end
            end
            return false
        end,
        on_effect = function(self, event, room, player, ctx)
            local cancelled = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:hasSkill(self:objectName()) then
                    cancelled = effect(self, event, room, player, ctx.original_data, p) or cancelled
                end
            end
            return cancelled
        end,
    }
end
local function diyba10_record(name, events, fn)
    return sgs.CreateRuleSkillV2 {
        name = name, events = events, global = true,
        can_trigger = function() return false end,
        on_record = function(self, event, room, player, ctx)
            fn(self, event, room, player, ctx.original_data)
        end,
    }
end

-- 朱异
diyba_xj_zhuyi = sgs.General(extension, "diyba_xj_zhuyi", "wu", 2)

diyba_gengshou = diyba10_trigger("diyba_gengshou", {sgs.Damage, sgs.EventPhaseEnd}, function(self, event, room, p, data, owner)
    if event == sgs.Damage then
        local damage = data:toDamage()
        if damage.from ~= owner or not damage.card or not damage.card:isKindOf("Slash")
            or damage.transfer or damage.chain then return end
        local list = { owner }
        for _, t in sgs.qlist(room:getOtherPlayers(owner)) do
            if owner:inMyAttackRange(t) then table.insert(list, t) end
        end
        for _, t in ipairs(list) do
            if owner:isDead() then return end
            if t:isAlive() then
                local choice = room:askForChoice(t, "diyba_gengshou", "draw+discard+cancel", ToData(owner))
                if choice == "draw" then
                    owner:drawCards(1, "diyba_gengshou")
                elseif choice == "discard" and not owner:isNude() then
                    room:askForDiscard(owner, "diyba_gengshou", 1, 1, false, true)
                end
            end
        end
    else
        if p ~= owner or owner:getPhase() ~= sgs.Player_Play then return end
        -- 若你没有此阶段获得的手牌: none of the cards obtained this phase is still in hand
        local got = owner:getTag("diyba_gengshou_ids"):toString()
        if got ~= "" then
            for _, n in ipairs(got:split("+")) do
                local id = tonumber(n)
                if id and owner:handCards():contains(id) then return end
            end
        end
        if not owner:askForSkillInvoke("diyba_gengshou_slash", data) then return end
        local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        slash:setSkillName("diyba_gengshou")
        local targets = sgs.SPlayerList()
        for _, t in sgs.qlist(room:getOtherPlayers(owner)) do
            if owner:canSlash(t, slash, true) then targets:append(t) end
        end
        if not targets:isEmpty() then
            local to = room:askForPlayerChosen(owner, targets, "diyba_gengshou", "@diyba_gengshou-slash", true)
            if to then room:useCard(sgs.CardUseStruct(slash, owner, to), false) end
        end
        slash:deleteLater()
    end
end)
diyba_gengshou_record = diyba10_record("#diyba_gengshou_record", {sgs.CardsMoveOneTime, sgs.EventPhaseStart},
    function(self, event, room, player, data)
        if event == sgs.EventPhaseStart then
            if player:getPhase() == sgs.Player_Play then player:removeTag("diyba_gengshou_ids") end
            return
        end
        local move = data:toMoveOneTime()
        if not move.to or move.to_place ~= sgs.Player_PlaceHand then return end
        local to = room:findPlayerByObjectName(move.to:objectName())
        if to and to:hasSkill("diyba_gengshou") and to:getPhase() == sgs.Player_Play then
            local ids = {}
            local old = to:getTag("diyba_gengshou_ids"):toString()
            if old ~= "" then table.insert(ids, old) end
            for _, id in sgs.qlist(move.card_ids) do table.insert(ids, tostring(id)) end
            to:setTag("diyba_gengshou_ids", sgs.QVariant(table.concat(ids, "+")))
        end
    end)
diyba_xj_zhuyi:addSkill(diyba_gengshou)
diyba_xj_zhuyi:addSkill(diyba_gengshou_record)

sgs.LoadTranslationTable {
    ["diyba_xj_zhuyi"] = "朱异",
    ["#diyba_xj_zhuyi"] = "大节巉天",
    ["designer:diyba_xj_zhuyi"] = "猪",
    ["diyba_gengshou"] = "更狩",
    [":diyba_gengshou"] = "你使用【杀】造成伤害后，你与你攻击范围内的角色依次可以令你摸或弃置一张牌。出牌阶段结束时，若你没有此阶段获得的手牌，你可以视为使用一张【杀】。",
    ["diyba_gengshou:draw"] = "令其摸一张牌",
    ["diyba_gengshou:discard"] = "令其弃置一张牌",
    ["diyba_gengshou:cancel"] = "取消",
    ["diyba_gengshou_slash"] = "更狩",
    ["@diyba_gengshou-slash"] = "更狩：选择视为使用【杀】的目标",
}
end
-- ===== diyba b11 =====
do
-- diyba batch b11: 姜叙 / 马忠 skipped (not literally implementable)
end
-- ===== diyba b12 =====
do
-- diyba batch b12 (3D17J): all four generals skipped (not literally implementable)
end
-- ===== diyba b17 =====
do
-- b17: diyba_19j_yanzhenqing skipped
end
-- ===== diyba b18 =====
do
-- b18: diyba_re0_lihuowang skipped (no literal implementation possible)
end
-- ===== diyba b20 =====
do
-- b20: diyba 东雪莲 skipped (重整 state not expressible literally)
end
-- ===== diyba b21 =====
do
local diyba_12j_qianzhao = sgs.General(extension, "diyba_12j_qianzhao", "wei", 4)

local diyba_yuanzhen = sgs.CreateRuleSkillV2 {
    name = "diyba_yuanzhen", events = { sgs.TargetSpecified }, global = true,
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then return false end
        local use = data:toCardUse()
        if use.from and use.from:objectName() == player:objectName() and use.card
            and use.to:length() == 1 and use.to:first():objectName() ~= player:objectName()
            and player:distanceTo(use.to:first()) ~= 1 then
            return self:objectName(), player
        end
        return false
    end,
    on_effect = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local target = use.to:first()
        if not target or not target:isAlive() then return false end
        room:sendCompulsoryTriggerLog(player, self:objectName())
        local choice = "draw"
        if not target:isNude() then
            choice = room:askForChoice(target, self:objectName(), "discard+draw", ToData(player))
        end
        if choice == "discard" then
            room:askForDiscard(target, self:objectName(), 1, 1, false, true)
        elseif player:isAlive() then
            player:drawCards(1, self:objectName())
        end
        return false
    end,
}

local diyba_zhirong = sgs.CreateRuleSkillV2 {
    name = "diyba_zhirong", events = { sgs.EventPhaseStart }, global = true,
    can_trigger = function(self, event, room, player, data)
        if not player or not player:isAlive() or not player:hasSkill(self:objectName()) then return false end
        if player:getPhase() ~= sgs.Player_Play then return false end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasEquip() then return self:objectName(), player end
        end
        return false
    end,
    on_cost = function(self, event, room, player, ctx)
        return player:askForSkillInvoke(self:objectName(), sgs.QVariant())
    end,
    on_effect = function(self, event, room, player, ctx)
        local froms = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:hasEquip() then froms:append(p) end
        end
        local from = room:askForPlayerChosen(player, froms, self:objectName(), "@diyba_zhirong-from", true)
        if not from then return false end
        local tos = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:objectName() ~= from:objectName() then tos:append(p) end
        end
        if tos:isEmpty() then return false end
        local to = room:askForPlayerChosen(player, tos, self:objectName(), "@diyba_zhirong-to", false)
        if not to then return false end
        local id = room:askForCardChosen(player, from, "e", self:objectName())
        if not id or id < 0 then return false end
        local card = sgs.Sanguosha:getCard(id)
        local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER, player:objectName(), self:objectName(), "")
        room:moveCardTo(card, from, to, sgs.Player_PlaceEquip, reason)
        if from:isAlive() and to:isAlive() and to:isAllNude() == false then
            local dis = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
            dis:setSkillName(self:objectName())
            if not from:isProhibited(to, dis) then
                room:useCard(sgs.CardUseStruct(dis, from, to))
            end
            dis:deleteLater()
        end
        return false
    end,
}

diyba_12j_qianzhao:addSkill(diyba_yuanzhen)
diyba_12j_qianzhao:addSkill(diyba_zhirong)

sgs.LoadTranslationTable {
    ["diyba_12j_qianzhao"] = "牵招",
    ["#diyba_12j_qianzhao"] = "凛正戍远塞",
    ["diyba_yuanzhen"] = "远振",
    [":diyba_yuanzhen"] = "锁定技，你使用牌指定与你距离不为1的其他角色为唯一的目标后，你令其选择一项：1. 弃置一张牌；2. 令你摸一张牌。",
    ["diyba_yuanzhen:discard"] = "弃置一张牌",
    ["diyba_yuanzhen:draw"] = "令其摸一张牌",
    ["diyba_zhirong"] = "制戎",
    [":diyba_zhirong"] = "出牌阶段限开始时，你可将一名角色场上的一张装备牌置入另一名角色的装备区，然后前者视为对后者使用【过河拆桥】。",
    ["@diyba_zhirong-from"] = "制戎：选择一名装备区有牌的角色",
    ["@diyba_zhirong-to"] = "制戎：选择另一名角色",
}
end

extension_sj = sgs.Package("sheji", sgs.Package_GeneralPack)


-- ===== sheji b01 =====
do
local extension = extension_sj
-- sj2 b01: 亚历山大 / 克利奥帕特拉七世 (亚瑟、达·芬奇 skipped, see report.md)
sj2_yalishanda = sgs.General(extension, "sj2_yalishanda", "qun", 4)
sj2_jizhengzhe = gu_trigger("sj2_jizhengzhe", {sgs.TargetSpecified, sgs.DamageCaused}, function(self, event, room, p, data, owner)
    if event == sgs.DamageCaused then
        local damage = data:toDamage()
        if damage.from ~= owner or not damage.card or not damage.card:isKindOf("Slash") then return end
        local x = damage.card:getTag("sj2_jizhengzhe_x"):toInt()
        if x > 0 and damage.card:getTag("sj2_jizhengzhe_to"):toString() == damage.to:objectName() then
            damage.damage = x
            data:setValue(damage)
            damage.card:removeTag("sj2_jizhengzhe_x")
        end
        return
    end
    local use = data:toCardUse()
    if use.from ~= owner or not use.card:isKindOf("Slash") or room:getCurrent() ~= owner then return end
    if owner:getMark("sj2_jizhengzhe_first-Clear") > 0 then return end
    room:setPlayerMark(owner, "sj2_jizhengzhe_first-Clear", 1)
    if owner:isKongcheng() then return end
    local candidates = sgs.SPlayerList()
    for _, to in sgs.qlist(use.to) do
        if to:isAlive() and not to:isNude() then candidates:append(to) end
    end
    if candidates:isEmpty() or not gu_invoke(owner, self:objectName(), data) then return end
    local to = room:askForPlayerChosen(owner, candidates, self:objectName(), "@sj2_jizhengzhe-target", true, true)
    if not to then return end
    local give = room:askForExchange(owner, self:objectName(), owner:getHandcardNum(), 1, false, "@sj2_jizhengzhe-give:" .. to:objectName(), true)
    if not give or give:subcardsLength() == 0 then return end
    local got = room:askForCardChosen(owner, to, "he", self:objectName())
    local x = give:subcardsLength()
    local moves = sgs.CardsMoveList()
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP, owner:objectName(), to:objectName(), self:objectName(), "")
    moves:append(sgs.CardsMoveStruct(give:getSubcards(), owner, to, sgs.Player_PlaceHand, sgs.Player_PlaceHand, reason))
    moves:append(sgs.CardsMoveStruct(got, to, owner, room:getCardPlace(got), sgs.Player_PlaceHand, reason))
    room:moveCardsAtomic(moves, false)
    room:addPlayerMark(owner, "sj2_jizhengzhe_lost-Clear", x)
    use.card:setTag("sj2_jizhengzhe_x", sgs.QVariant(x))
    use.card:setTag("sj2_jizhengzhe_to", sgs.QVariant(to:objectName()))
end)
sj2_tuotujun_record = gu_record("#sj2_tuotujun_record", {sgs.Damage}, function(self, event, room, p, data)
    local damage = data:toDamage()
    if not damage.from or not damage.to or not damage.card or not damage.card:isKindOf("Slash") then return end
    local names = gu_names(damage.from, "sj2_tuotujun_hit")
    for _, n in ipairs(names) do if n == damage.to:objectName() then return end end
    table.insert(names, damage.to:objectName())
    gu_setnames(damage.from, "sj2_tuotujun_hit", names)
end)
extension:addSkills(sj2_tuotujun_record)
sj2_tuotujun = gu_trigger("sj2_tuotujun", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getPhase() ~= sgs.Player_Finish then return end
    local x = owner:getMark("sj2_jizhengzhe_lost-Clear")
    if x <= 0 then return end
    local pool = sgs.SPlayerList()
    for _, n in ipairs(gu_names(owner, "sj2_tuotujun_hit")) do
        local q = room:findPlayer(n)
        if q and q:isAlive() then pool:append(q) end
    end
    if pool:isEmpty() then return end
    local n = math.min(x, pool:length())
    local chosen = pool
    if n < pool:length() then
        chosen = room:askForPlayersChosen(owner, pool, self:objectName(), n, n, "@sj2_tuotujun:" .. n, false, true)
    end
    local list = sgs.QList2Table(chosen)
    local ordered = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        for _, c in ipairs(list) do if c == q then ordered:append(q) end end
    end
    for _, q in sgs.qlist(ordered) do
        if q:isAlive() and not q:isKongcheng() then
            local next = q:getNextAlive()
            if next and next ~= q then
                local c = room:askForExchange(q, self:objectName(), 1, 1, false, "@sj2_tuotujun-give:" .. next:objectName())
                if c then room:giveCard(q, next, c, self:objectName()) end
            end
        end
    end
end, true)
sj2_yalishanda:addSkill(sj2_jizhengzhe)
sj2_yalishanda:addSkill(sj2_tuotujun)

sj2_keliaobateluo = sgs.General(extension, "sj2_keliaobateluo", "qun", 3, false)
sj2_faolaozhishe = gu_trigger("sj2_faolaozhishe", {sgs.CardsMoveOneTime}, function(self, event, room, p, data, owner)
    local move = data:toMoveOneTime()
    if move.from ~= owner or move.to_place ~= sgs.Player_DiscardPile
        or bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_DISCARD then return end
    local trigger_lo, trigger_hi
    for _, id in sgs.qlist(move.card_ids) do
        local number = sgs.Sanguosha:getCard(id):getNumber()
        local count = owner:getMark("sj2_faolaozhishe_count-Clear") + 1
        room:setPlayerMark(owner, "sj2_faolaozhishe_count-Clear", count)
        if count == 1 then
            room:setPlayerMark(owner, "sj2_faolaozhishe_first-Clear", number)
        elseif count == 2 then
            local a = owner:getMark("sj2_faolaozhishe_first-Clear")
            trigger_lo, trigger_hi = math.min(a, number), math.max(a, number)
        end
    end
    if not trigger_lo or not gu_invoke(owner, self:objectName()) then return end
    local ids = room:getNCards(6, false)
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TURNOVER, owner:objectName(), self:objectName(), "")
    room:moveCardsAtomic(sgs.CardsMoveStruct(ids, nil, sgs.Player_PlaceTable, reason), true)
    local get, rest = sgs.IntList(), sgs.IntList()
    for _, id in sgs.qlist(ids) do
        local n = sgs.Sanguosha:getCard(id):getNumber()
        if n >= trigger_lo and n <= trigger_hi then get:append(id) else rest:append(id) end
    end
    if not get:isEmpty() then
        room:obtainCard(owner, gu_dummy(get), false)
    end
    if not rest:isEmpty() then
        local r2 = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER, "", self:objectName(), "")
        room:moveCardsAtomic(sgs.CardsMoveStruct(rest, nil, sgs.Player_DiscardPile, r2), true)
    end
    if owner:isAlive() then room:loseHp(owner, 1) end
end)
sj2_seyou = gu_trigger("sj2_seyou", {sgs.CardAsked}, function(self, event, room, p, data, owner)
    local ask = data:toStringList()
    if p ~= owner or ask[1] ~= "jink" or owner:getCardCount(true) < 2 then return end
    local c = room:askForExchange(owner, self:objectName(), 2, 2, true, "@sj2_seyou", true)
    if not c then return end
    local x = 0
    for _, id in sgs.qlist(c:getSubcards()) do
        if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then x = x + 1 end
    end
    room:throwCard(c, self:objectName(), owner)
    if x > 0 then
        if owner:isAlive() then room:recover(owner, sgs.RecoverStruct(owner, nil, x)) end
        local cur = room:getCurrent()
        if cur and cur:isAlive() then room:loseHp(cur, x) end
        return
    end
    local jink = sgs.Sanguosha:cloneCard("jink", sgs.Card_NoSuit, 0)
    jink:setSkillName(self:objectName())
    room:provide(jink)
    return true
end)
sj2_keliaobateluo:addSkill(sj2_faolaozhishe)
sj2_keliaobateluo:addSkill(sj2_seyou)

sgs.LoadTranslationTable{
    ["sj2_yalishanda"] = "亚历山大[三设2]",
    ["&sj2_yalishanda"] = "亚历山大",
    ["designer:sj2_yalishanda"] = "Revival_1947",
    ["sj2_jizhengzhe"] = "激征者",
    [":sj2_jizhengzhe"] = "你在回合内使用第一张【杀】指定目标时，你可以用至少一张手牌交换一名目标角色的一张牌，然后将伤害改为X（X为你此次以此法失去的牌数）。",
    ["@sj2_jizhengzhe-target"] = "激征者：选择一名目标角色，用手牌交换其一张牌",
    ["@sj2_jizhengzhe-give"] = "激征者：选择至少一张手牌，与 %src 交换其一张牌",
    ["sj2_tuotujun"] = "拓土君",
    [":sj2_tuotujun"] = "锁定技，结束阶段，你须选择X名本局游戏受到过你【杀】造成伤害的角色，令其依次将一张手牌交给其下家（不足则全选，无则不给）。",
    ["@sj2_tuotujun"] = "拓土君：选择 %arg 名受到过你【杀】伤害的角色",
    ["@sj2_tuotujun-give"] = "拓土君：将一张手牌交给 %src",
    ["sj2_keliaobateluo"] = "克利奥帕特拉七世[三设2]",
    ["&sj2_keliaobateluo"] = "克利奥帕特拉七世",
    ["designer:sj2_keliaobateluo"] = "本因坊神策",
    ["sj2_faolaozhishe"] = "法老之蛇",
    [":sj2_faolaozhishe"] = "当你于一回合内弃置第二张牌后，你可以翻开牌堆顶的六张牌，获得其中点数在弃置牌点数之间的所有牌，然后失去1点体力。",
    ["sj2_seyou"] = "色诱",
    [":sj2_seyou"] = "当你需要使用或打出一张【闪】时，你可以弃置两张牌，然后回复X点体力并令当前回合的角色失去X点体力（X为你以此法弃置的装备牌数）。若你未以此法弃置装备牌，则你视为使用或打出了一张【闪】。",
    ["@sj2_seyou"] = "色诱：你可以弃置两张牌",
}
end

-- ===== sheji b02 =====
do
local extension = extension_sj
-- b02: all four generals skipped (see report.md); nothing registered.
end

-- ===== sheji b03 =====
do
local extension = extension_sj
-- b03: all four generals skipped (see report.md); nothing registered.
end

-- ===== sheji b04 =====
do
local extension = extension_sj
-- sj5 贝多芬
sj5_beiduofen = sgs.General(extension, "sj5_beiduofen", "qun", 3)
local function sj5_jbzs_target(room, owner)
    local name = owner:getTag("sj5_junbuzhisong_target"):toString()
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if name == "" and q:getRole() == "lord" or name ~= "" and q:objectName() == name then return q end
    end
    return nil
end
sj5_junbuzhisong = gu_trigger("sj5_junbuzhisong", {sgs.TurnStart, sgs.DamageCaused, sgs.DrawNCards, sgs.EventPhaseChanging}, function(self, event, room, p, data, owner)
    local name = self:objectName()
    if event == sgs.TurnStart then
        room:setPlayerMark(owner, "sj5_jbzs_could", 0)
        room:setPlayerMark(owner, "sj5_jbzs_used", 0)
        return
    end
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to ~= sgs.Player_NotActive then return end
        if owner:getMark("sj5_jbzs_could") == 0 or owner:getMark("sj5_jbzs_used") > 0 or not owner:isAlive() then return end
        local card = room:askForCard(owner, "Jink", "@sj5_junbuzhisong-recast", sgs.QVariant(), sgs.Card_MethodNone, nil, false, name)
        if not card then return end
        local cur = sj5_jbzs_target(room, owner)
        local targets = sgs.SPlayerList()
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            if q:objectName() ~= owner:objectName() and (not cur or q:objectName() ~= cur:objectName()) then targets:append(q) end
        end
        room:notifySkillInvoked(owner, name)
        room:recastCard(owner, card:getEffectiveId(), name)
        if targets:isEmpty() then return end
        local to = room:askForPlayerChosen(owner, targets, name, "@sj5_junbuzhisong-name", false)
        if to then owner:setTag("sj5_junbuzhisong_target", sgs.QVariant(to:objectName())) end
        return
    end
    local target = sj5_jbzs_target(room, owner)
    if not target then return end
    local state = owner:getMark("sj5_jbzs_state")
    if event == sgs.DamageCaused then
        local d = data:toDamage()
        if d.from ~= target or state ~= 0 or d.damage <= 0 then return end
        room:setPlayerMark(owner, "sj5_jbzs_could", 1)
        if gu_invoke(owner, name, data) then
            d.damage = d.damage * 2; data:setValue(d)
            room:setPlayerMark(owner, "sj5_jbzs_used", 1)
            room:setPlayerMark(owner, "sj5_jbzs_state", 1)
        end
    else
        local draw = data:toDraw()
        if p ~= target or state ~= 1 or draw.reason ~= "draw_phase" or draw.num <= 0 then return end
        room:setPlayerMark(owner, "sj5_jbzs_could", 1)
        if gu_invoke(owner, name, data) then
            draw.num = draw.num * 2; data:setValue(draw)
            room:setPlayerMark(owner, "sj5_jbzs_used", 1)
            room:setPlayerMark(owner, "sj5_jbzs_state", 0)
        end
    end
end)
sj5_yikuyile = gu_trigger("sj5_yikuyile", {sgs.DrawNCards, sgs.EventPhaseChanging}, function(self, event, room, p, data, owner)
    local name = self:objectName()
    if p ~= owner then return end
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to ~= sgs.Player_NotActive then return end
        room:setPlayerMark(owner, "sj5_yikuyile_extra", 0)
        if owner:getMark("sj5_yikuyile_pending") > 0 then
            room:setPlayerMark(owner, "sj5_yikuyile_pending", 0)
            if owner:isAlive() then
                room:sendCompulsoryTriggerLog(owner, name, true)
                room:setPlayerMark(owner, "sj5_yikuyile_extra", 1)
                owner:gainAnExtraTurn()
            end
        end
        return
    end
    local draw = data:toDraw()
    if room:getCurrent() ~= owner or owner:getMark("sj5_yikuyile_extra") > 0 or draw.num <= 1 then return end
    room:sendCompulsoryTriggerLog(owner, name, true)
    local less = draw.num - 1
    draw.num = 1; data:setValue(draw)
    local acted = false
    for _ = 1, less do
        if not owner:isAlive() then break end
        local choices = {}
        local nonnude = sgs.SPlayerList()
        local field = false
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            if not q:isNude() then nonnude:append(q) end
            if q:hasEquip() or q:getJudgingArea():length() > 0 then field = true end
        end
        if not nonnude:isEmpty() then table.insert(choices, "discard") end
        if field then table.insert(choices, "move") end
        if #choices == 0 then break end
        table.insert(choices, "cancel")
        local choice = room:askForChoice(owner, name, table.concat(choices, "+"))
        if choice == "cancel" then break end
        if choice == "discard" then
            local q = room:askForPlayerChosen(owner, nonnude, name, "@sj5_yikuyile-discard", false)
            if q and not q:isNude() then
                room:throwCard(room:askForCardChosen(owner, q, "he", name, false, sgs.Card_MethodDiscard), q, owner)
                acted = true
            end
        else
            if room:moveField(owner, name, false, "ej") then acted = true end
        end
    end
    if acted then
        local red, black = 0, 0
        for _, q in sgs.qlist(room:getAlivePlayers()) do
            for _, c in sgs.qlist(q:getEquips()) do
                if c:isRed() then red = red + 1 elseif c:isBlack() then black = black + 1 end
            end
            for _, c in sgs.qlist(q:getJudgingArea()) do
                if c:isRed() then red = red + 1 elseif c:isBlack() then black = black + 1 end
            end
        end
        if red == black then room:setPlayerMark(owner, "sj5_yikuyile_pending", 1) end
    end
end, true)
sj5_beiduofen:addSkill(sj5_junbuzhisong)
sj5_beiduofen:addSkill(sj5_yikuyile)

-- sj9 曹休
sj9_caoxiu = sgs.General(extension, "sj9_caoxiu", "wei", 4)
sj9_qingshi = gu_trigger("sj9_qingshi", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    local name = self:objectName()
    if p == owner or p:getPhase() ~= sgs.Player_Start or not p:isAlive() or not owner:isAlive() then return end
    local x = math.max(owner:getHp(), 0)
    local n = owner:getHandcardNum() - x
    if n <= 0 or not gu_invoke(owner, name, ToData(p)) then return end
    local c = room:askForExchange(owner, name, n, n, false, "@sj9_qingshi-discard:" .. n, false)
    if not c then return end
    local ids = {}
    for _, id in sgs.qlist(c:getSubcards()) do table.insert(ids, id) end
    gu_throw(room, owner, c:getSubcards(), name)
    room:setPlayerMark(p, "sj9_qingshi_" .. owner:objectName() .. "-Clear", 1)
    local used = 0
    while used < x and owner:isAlive() and p:isAlive() do
        local usable = sgs.IntList()
        for _, id in ipairs(ids) do
            if room:getCardPlace(id) == sgs.Player_DiscardPile then
                local card = sgs.Sanguosha:getCard(id)
                local tl = sgs.PlayerList()
                tl:append(p)
                if not card:targetFixed() and not owner:isProhibited(p, card) and not owner:isCardLimited(card, sgs.Card_MethodUse)
                    and card:isAvailable(owner) and card:targetFilter(sgs.PlayerList(), p, owner)
                    and card:targetsFeasible(tl, owner) then
                    usable:append(id)
                end
            end
        end
        if usable:isEmpty() then break end
        room:fillAG(usable, owner)
        local id = room:askForAG(owner, usable, true, name)
        room:clearAG(owner)
        if id < 0 then break end
        used = used + 1
        room:useCard(sgs.CardUseStruct(sgs.Sanguosha:getCard(id), owner, p), false)
    end
end)
sj9_qingshi_mod = sgs.CreateTargetModSkillV2 {
    name = "#sj9_qingshi_mod", pattern = "Card", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        if ctx:getModType() ~= sgs.TargetModSkill_DistanceLimit then return 0 end
        local from, to = ctx:getPrimary(), ctx:getSecondary()
        if from and to and from:getMark("sj9_qingshi_" .. to:objectName() .. "-Clear") > 0 then return 1000 end
        return 0
    end,
}
sj9_caoxiu:addSkill(sj9_qingshi)
sj9_caoxiu:addSkill(sj9_qingshi_mod)

-- sj9 罗宪
sj9_luoxian = sgs.General(extension, "sj9_luoxian", "shu", 4)
sj9_lixian = gu_trigger("sj9_lixian", {sgs.EventPhaseChanging, sgs.EventPhaseSkipped, sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    local name = self:objectName()
    if p ~= owner then return end
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to ~= sgs.Player_Judge or owner:isSkipped(sgs.Player_Judge) then return end
        local least = true
        for _, q in sgs.qlist(room:getOtherPlayers(owner)) do
            if q:getHandcardNum() < owner:getHandcardNum() then least = false end
        end
        if not (least or owner:getHp() == 1) then return end
        if gu_invoke(owner, name) then owner:skip(sgs.Player_Judge) end
    elseif event == sgs.EventPhaseSkipped then
        room:addPlayerMark(owner, "sj9_lixian-Clear")
        local nxt = owner:getPhase() + 1
        if nxt < sgs.Player_Start or nxt > sgs.Player_Finish or owner:isSkipped(nxt) then return end
        if gu_invoke(owner, name) then owner:skip(nxt) end
    else
        if owner:getPhase() ~= sgs.Player_Finish then return end
        local n = owner:getMark("sj9_lixian-Clear")
        if n > 0 then
            room:notifySkillInvoked(owner, name)
            owner:drawCards(n, name)
        end
    end
end)
sj9_luoxian:addSkill(sj9_lixian)

sgs.LoadTranslationTable{
    ["sj5_beiduofen"] = "贝多芬[三设5]",
    ["&sj5_beiduofen"] = "贝多芬",
    ["#sj5_beiduofen"] = "悲著雄音",
    ["designer:sj5_beiduofen"] = "轻帆过海",
    ["sj5_junbuzhisong"] = "君不值颂",
    [":sj5_junbuzhisong"] = "转换技，（主公）①造成伤害时②于摸牌阶段摸牌时，你可令伤害值或摸牌数数值翻倍；你能发动但未发动此技能的回合结束时，你可重铸一张【闪】并将另一名角色名替换进括号。",
    ["@sj5_junbuzhisong-recast"] = "君不值颂：你可重铸一张【闪】，并将另一名角色名替换进括号",
    ["@sj5_junbuzhisong-name"] = "君不值颂：选择另一名角色替换进括号",
    ["sj5_yikuyile"] = "以苦易乐",
    [":sj5_yikuyile"] = "锁定技，你于额定回合摸牌时改为仅摸一张；你因此每少摸一张牌，便能弃置一名角色的一张牌或移动场上一张牌；然后若场上红黑牌的数量因此相等，当前回合结束时你执行一个额外回合。",
    ["sj5_yikuyile:discard"] = "弃置一名角色的一张牌",
    ["sj5_yikuyile:move"] = "移动场上一张牌",
    ["sj5_yikuyile:cancel"] = "取消",
    ["@sj5_yikuyile-discard"] = "以苦易乐：弃置一名角色的一张牌",

    ["sj9_caoxiu"] = "曹休[三设9]",
    ["&sj9_caoxiu"] = "曹休",
    ["#sj9_caoxiu"] = "千烽贯烬",
    ["designer:sj9_caoxiu"] = "王日天",
    ["sj9_qingshi"] = "倾势",
    [":sj9_qingshi"] = "其他角色的准备阶段，你可以将手牌弃置至X张，然后仅对其使用至多X张以此法弃置的牌（X为你的体力值）。若如此做，其本回合对你使用牌无距离限制。",
    ["@sj9_qingshi-discard"] = "倾势：将手牌弃置至体力值张，需弃置 %arg 张",

    ["sj9_luoxian"] = "罗宪[三设9]",
    ["&sj9_luoxian"] = "罗宪",
    ["#sj9_luoxian"] = "西壁绝东",
    ["designer:sj9_luoxian"] = "老冰",
    ["sj9_lixian"] = "历险",
    [":sj9_lixian"] = "若你的手牌数为全场最少或体力值为1，你可以跳过判定阶段；当你跳过阶段后，你可以跳过你的下个阶段；结束阶段，本回合你每跳过一个阶段，便摸一张牌。",
}
end

-- ===== sheji b05 =====
do
local extension = extension_sj
-- b05 三设9 (3S9J): 程普 同征, 韩遂 邀叛/马术. 秦宓/刘焉 skipped (see report.md).
extension:addSkills(gu_record("#sj9_record", {sgs.CardsMoveOneTime, sgs.Damaged, sgs.EventPhaseChanging}, function(self, event, room, p, data)
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().from == sgs.Player_NotActive then
            room:removeTag("sj9_tongzheng_ids"); room:removeTag("sj9_damaged")
        end
    elseif event == sgs.Damaged then
        local d = data:toDamage()
        room:setTag("sj9_damaged", sgs.QVariant(true))
        if d.to then room:setPlayerMark(d.to, "sj9_hurt-Clear", 1) end
    else
        local move = data:toMoveOneTime()
        if move.to_place ~= sgs.Player_DiscardPile
            or bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) ~= sgs.CardMoveReason_S_REASON_DISCARD then return end
        local ids = room:getTag("sj9_tongzheng_ids"):toIntList()
        for _, id in sgs.qlist(move.card_ids) do if not ids:contains(id) then ids:append(id) end end
        room:setTag("sj9_tongzheng_ids", ToData(ids))
    end
end))

sj9_chengpu = sgs.General(extension, "sj9_chengpu", "wu", 4)
sj9_tongzheng = gu_trigger("sj9_tongzheng", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p:getPhase() ~= sgs.Player_Finish or p:getKingdom() ~= owner:getKingdom() then return end
    local ids = sgs.IntList()
    for _, id in sgs.qlist(room:getTag("sj9_tongzheng_ids"):toIntList()) do
        if room:getCardPlace(id) == sgs.Player_DiscardPile then ids:append(id) end
    end
    if ids:isEmpty() or not gu_invoke(owner, self:objectName(), ToData(p)) then return end
    room:fillAG(ids, owner)
    local id = room:askForAG(owner, ids, false, self:objectName())
    room:clearAG(owner)
    if id >= 0 then
        local choice = room:askForChoice(owner, self:objectName(), "use+give", ToData(p))
        if choice == "use" then
            room:askForUseCard(owner, tostring(id), "@sj9_tongzheng-use", -1, sgs.Card_MethodUse, false)
        elseif room:getCardPlace(id) == sgs.Player_DiscardPile and p:isAlive() then
            room:obtainCard(p, sgs.Sanguosha:getCard(id), true)
        end
    end
    if not room:getTag("sj9_damaged"):toBool() and owner:isAlive() then
        room:loseHp(owner, 1, true, owner, self:objectName())
    end
end)
sj9_chengpu:addSkill(sj9_tongzheng)

sj9_hansui = sgs.General(extension, "sj9_hansui", "qun", 4)
sj9_yaopan = gu_trigger("sj9_yaopan", {sgs.EventPhaseStart}, function(self, event, room, p, data, owner)
    if p == owner or p:getPhase() ~= sgs.Player_Finish then return end
    local cands = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getAlivePlayers()) do
        if q:getMark("sj9_hurt-Clear") > 0 and (q == owner or owner:distanceTo(q) <= 1) then cands:append(q) end
    end
    if cands:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, cands, self:objectName(), "@sj9_yaopan", true, true)
    if not to or not to:isAlive() then return end
    room:setPlayerChained(to, true, owner)
    if to:isDead() then return end
    local choices = {"slash", "snatch", "cancel"}
    local choice = room:askForChoice(to, self:objectName(), table.concat(choices, "+"))
    if choice == "cancel" then return end
    local name = choice == "slash" and "slash" or "snatch"
    local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    card:setSkillName(self:objectName())
    local tos = sgs.SPlayerList()
    for _, q in sgs.qlist(room:getOtherPlayers(to)) do
        if name == "slash" then
            if to:canSlash(q, card, false) then tos:append(q) end
        elseif not to:isProhibited(q, card) and card:targetFilter(sgs.PlayerList(), q, to) then
            tos:append(q)
        end
    end
    if not tos:isEmpty() then
        local victim = room:askForPlayerChosen(to, tos, "sj9_yaopan_use", "@sj9_yaopan-use:::" .. name, false, false)
        if victim then room:useCard(sgs.CardUseStruct(card, to, victim), false) end
    end
    card:deleteLater()
end)
sj9_mashu = sgs.CreateDistanceSkillV2 {
    name = "sj9_mashu", frequency = sgs.Skill_Compulsory, holder_selector = sgs.CorrectSkill_AllHolders,
    correct_func = function(self, ctx)
        local from, to, holder = ctx:getPrimary(), ctx:getSecondary(), ctx:getHolder()
        if from and to and holder and holder == from and from ~= to then return -1 end
        return false
    end,
}
sj9_hansui:addSkill(sj9_yaopan)
sj9_hansui:addSkill(sj9_mashu)

sgs.LoadTranslationTable {
    ["sj9_chengpu"] = "程普[三设9]", ["&sj9_chengpu"] = "程普", ["#sj9_chengpu"] = "铁脊灼江",
    ["designer:sj9_chengpu"] = "静谦",
    ["sj9_tongzheng"] = "同征",
    [":sj9_tongzheng"] = "与你势力相同的角色的结束阶段，你可以选择一张本回合因弃置而进入弃牌堆的牌，然后使用之或将之交给该角色。然后若本回合没有角色受到过伤害，你失去1点体力。",
    ["sj9_tongzheng:use"] = "使用之", ["sj9_tongzheng:give"] = "交给该角色",
    ["@sj9_tongzheng-use"] = "同征：请使用此牌",
    ["sj9_hansui"] = "韩遂[三设9]", ["&sj9_hansui"] = "韩遂", ["#sj9_hansui"] = "推关覆北",
    ["designer:sj9_hansui"] = "静谦",
    ["sj9_yaopan"] = "邀叛",
    [":sj9_yaopan"] = "其他角色的结束阶段，你可以令一名距离为1以内且本回合受到过伤害的角色横置，然后其可以视为使用一张【杀】或【顺手牵羊】。",
    ["@sj9_yaopan"] = "邀叛：你可以令一名距离为1以内且本回合受到过伤害的角色横置",
    ["@sj9_yaopan-use"] = "邀叛：请选择视为使用【%arg】的目标",
    ["sj9_yaopan:slash"] = "视为使用【杀】", ["sj9_yaopan:snatch"] = "视为使用【顺手牵羊】", ["sj9_yaopan:cancel"] = "取消",
    ["sj9_mashu"] = "马术", [":sj9_mashu"] = "锁定技，你计算与其他角色距离-1。",
}
end

-- ===== sheji b06 =====
do
local extension = extension_sj
-- sj9 (3S9J) batch b06: 任恺, 石崇. 傅燮/桥瑁 skipped (see report.md).

-- 任恺
sj9_renkai = sgs.General(extension, "sj9_renkai", "qun", 3)
sj9_qinke = gu_trigger("sj9_qinke", {sgs.CardFinished}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from ~= owner or not owner:isAlive() or not use.card then return end
    local suit = use.card:getSuit()
    if suit < 0 or suit > 3 then return end
    local key = "sj9_qinke_suit" .. suit .. "-Clear"
    if owner:getMark(key) > 0 then return end
    room:setPlayerMark(owner, key, 1)
    if owner:isNude() or not gu_invoke(owner, self:objectName(), data) then return end
    local c = room:askForCard(owner, "..", "@sj9_qinke", data, sgs.Card_MethodNone, nil, false, self:objectName())
    if not c then return end
    local same = c:getTypeId() == use.card:getTypeId()
    local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, owner:objectName(), self:objectName(), "")
    room:moveCardTo(c, owner, nil, sgs.Player_DiscardPile, reason)
    if owner:isAlive() then owner:drawCards(1, "recast") end
    local cur = room:getCurrent()
    if same and cur and cur:isAlive() then room:addPlayerMark(cur, "sj9_qinke_max-Clear") end
end)
sj9_qinke_max = sgs.CreateMaxCardsSkillV2 {
    name = "#sj9_qinke_max", holder_selector = sgs.CorrectSkill_System, gate = { "mark:sj9_qinke_max-Clear" },
    correct_func = function(self, ctx)
        local p = ctx:getPrimary()
        if p and p:getMark("sj9_qinke_max-Clear") > 0 then return p:getMark("sj9_qinke_max-Clear") end
        return false
    end,
}
sj9_pengzheng = sgs.CreateViewAsSkillV2 {
    name = "sj9_pengzheng",
    limit_scope = sgs.Skill_Limit_Phase, phase_name = "Play", max_usage_limit = 1,
    can_activate = function(self, request)
        return request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY
    end,
    can_select_card = function(self, request, c)
        return request:getSelectedCardIds():isEmpty() and c:isKindOf("TrickCard") and not c:hasFlag("using")
    end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():length() == 1 end,
    create_card = function(self, request)
        local c = sgs.Sanguosha:cloneCard("fight_together", sgs.Card_SuitToBeDecided, -1)
        c:addSubcards(request:getSelectedCardIds()); c:setSkillName("sj9_pengzheng"); return c
    end,
}
sj9_pengzheng_record = gu_trigger("#sj9_pengzheng_record", {sgs.CardUsed, sgs.CardFinished}, function(self, event, room, p, data, owner)
    local use = data:toCardUse()
    if use.from ~= owner or not use.card or use.card:getSkillName() ~= "sj9_pengzheng" then return end
    if event == sgs.CardUsed then
        owner:setTag("sj9_pengzheng_chained", sgs.QVariant(owner:isChained()))
        return
    end
    local was = owner:getTag("sj9_pengzheng_chained"):toBool()
    owner:removeTag("sj9_pengzheng_chained")
    if was or not owner:isChained() or not owner:isAlive() then return end
    local targets = sgs.SPlayerList()
    for _, t in sgs.qlist(room:getAlivePlayers()) do
        if not t:isChained() then targets:append(t) end
    end
    if targets:isEmpty() then return end
    local to = room:askForPlayerChosen(owner, targets, "sj9_pengzheng", "@sj9_pengzheng", true)
    if to then room:damage(sgs.DamageStruct("sj9_pengzheng", owner, to, 1)) end
end, true)
sj9_renkai:addSkill(sj9_qinke)
sj9_renkai:addSkill(sj9_qinke_max)
sj9_renkai:addSkill(sj9_pengzheng)
sj9_renkai:addSkill(sj9_pengzheng_record)
extension:insertRelatedSkills("sj9_qinke", "#sj9_qinke_max")
extension:insertRelatedSkills("sj9_pengzheng", "#sj9_pengzheng_record")

-- 石崇
sj9_shichong = sgs.General(extension, "sj9_shichong", "qun", 4)
sj9_yiyi = gu_active("sj9_yiyi", 1, 0, 0,
    function() return false end,
    function(self, targets) return #targets == 0 end,
    function(self, room, source, targets)
        local maxn, minn = 0, 1000
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            maxn = math.max(maxn, p:getHandcardNum())
        end
        local draw = math.min(5, maxn - source:getHandcardNum())
        if draw > 0 then source:drawCards(draw, "sj9_yiyi") end
        if not source:isAlive() then return end
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            minn = math.min(minn, p:getHandcardNum())
        end
        local n = source:getHandcardNum() - minn
        if n <= 0 then return end
        local before = {}
        for _, c in sgs.qlist(source:getHandcards()) do before[c:getEffectiveId()] = true end
        room:askForDiscard(source, "sj9_yiyi", n, n, false, false)
        local ids = sgs.IntList()
        for id, _ in pairs(before) do
            if room:getCardPlace(id) == sgs.Player_DiscardPile then ids:append(id) end
        end
        if ids:isEmpty() or not source:isAlive() then return end
        local cnt = ids:length()
        local choices = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getHandcardNum() <= cnt then choices:append(p) end
        end
        if choices:isEmpty() then return end
        local to = room:askForPlayerChosen(source, choices, "sj9_yiyi", "@sj9_yiyi:::" .. cnt, false)
        if not to then return end
        local hand = sgs.IntList()
        for _, c in sgs.qlist(to:getHandcards()) do hand:append(c:getEffectiveId()) end
        if not hand:isEmpty() then
            local d = gu_dummy(hand)
            room:moveCardTo(d, nil, nil, sgs.Player_DiscardPile,
                sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT, to:objectName(), "sj9_yiyi", ""), true)
            d:deleteLater()
        end
        local give = sgs.IntList()
        for _, id in sgs.qlist(ids) do
            if room:getCardPlace(id) == sgs.Player_DiscardPile then give:append(id) end
        end
        if to:isAlive() then gu_obtain(room, to, give, "sj9_yiyi") end
    end)
sj9_shichong:addSkill(sj9_yiyi)

sgs.LoadTranslationTable {
    ["sj9_renkai"] = "任恺[三设9]", ["&sj9_renkai"] = "任恺", ["#sj9_renkai"] = "郁郁投箸",
    ["designer:sj9_renkai"] = "静谦",
    ["sj9_qinke"] = "勤恪",
    [":sj9_qinke"] = "当你每回合首次使用一种花色的牌结算后，你可以重铸一张牌，若两牌类别相同，当前回合角色于本回合内手牌上限+1。",
    ["@sj9_qinke"] = "勤恪：你可以重铸一张牌",
    ["sj9_pengzheng"] = "朋争",
    [":sj9_pengzheng"] = "出牌阶段限一次，你可以将一张锦囊牌当【调力同心】使用，若你因此横置，你可以对一名未横置的角色造成1点伤害。",
    ["@sj9_pengzheng"] = "朋争：你可以对一名未横置的角色造成1点伤害",
    ["sj9_shichong"] = "石崇[三设9]", ["&sj9_shichong"] = "石崇", ["#sj9_shichong"] = "百道营生",
    ["designer:sj9_shichong"] = "妖",
    ["sj9_yiyi"] = "亿亿",
    [":sj9_yiyi"] = "出牌阶段限一次，你可以摸牌至手牌数为最多（至多摸五张），然后弃置至手牌数为最少。若如此做，你选择一名手牌数不大于以此法弃置牌数的角色，将弃置牌与其所有手牌交换。",
    ["@sj9_yiyi"] = "亿亿：选择一名手牌数不大于 %arg 的角色，将弃置牌与其所有手牌交换",
}
end

-- ===== sheji b07 =====
do
local extension = extension_sj
-- 三国杀设计吧 3S7J (b07): 邓飏丁谧, 阮咸. (赵直/刘岱 skipped, see report.md)

-- 邓飏丁谧
sj7_dengyangdingmi = sgs.General(extension, "sj7_dengyangdingmi", "wei", 3)

local function sj7_gain_skill(room, owner, skill)
    if owner:isAlive() and not owner:hasSkill(skill) then room:handleAcquireDetachSkills(owner, skill) end
end

sj7_fuguang = gu_trigger("sj7_fuguang", {sgs.GameStart, sgs.HpRecover, sgs.RoundEnd}, function(self, event, room, p, data, owner)
    if event == sgs.RoundEnd then
        if owner:getMark("sj7_fuguang_got") == 0 then return end
        room:setPlayerMark(owner, "sj7_fuguang_got", 0)
        if not owner:isAlive() or not owner:hasSkill("yiji") then return end
        local judge = sgs.JudgeStruct()
        judge.who = owner; judge.reason = "sj7_fuguang_fulei"; judge.pattern = ".|spade"; judge.good = true
        room:judge(judge)
        if not judge:isGood() then
            room:handleAcquireDetachSkills(owner, "-yiji")
            local c = judge.card
            if c and owner:isAlive() and room:getCardPlace(c:getEffectiveId()) == sgs.Player_DiscardPile then
                local ids = sgs.IntList(); ids:append(c:getEffectiveId())
                gu_obtain(room, owner, ids, self:objectName())
            end
        end
        return
    end
    if p ~= owner then return end
    sj7_gain_skill(room, owner, "yiji")
end, true)

sj7_yongyi = gu_trigger("sj7_yongyi", {sgs.GameStart, sgs.PostHpReduced, sgs.EventPhaseChanging}, function(self, event, room, p, data, owner)
    if event == sgs.EventPhaseChanging then
        if data:toPhaseChange().to ~= sgs.Player_NotActive then return end
        if not owner:isAlive() or not owner:hasSkill("luoying") or owner:getMark("sj7_yongyi_got") > 0 then return end
        local ids = sgs.IntList()
        for _, s in ipairs(room:getTag("sj7_yongyi_spades"):toString():split("+")) do
            local id = tonumber(s)
            if id and room:getCardPlace(id) == sgs.Player_DiscardPile then ids:append(id) end
        end
        if ids:isEmpty() then return end
        room:fillAG(ids, owner)
        local id = room:askForAG(owner, ids, false, self:objectName())
        room:clearAG(owner)
        local one = sgs.IntList(); one:append(id)
        gu_obtain(room, owner, one, self:objectName())
        room:handleAcquireDetachSkills(owner, "-luoying")
        if owner:isAlive() then room:recover(owner, sgs.RecoverStruct(self:objectName(), owner)) end
        return
    end
    if p ~= owner then return end
    sj7_gain_skill(room, owner, "luoying")
end, true)

sj7_yongyi_record = gu_record("#sj7_yongyi_record", {sgs.CardsMoveOneTime, sgs.TurnStart}, function(self, event, room, p, data)
    if event == sgs.TurnStart then
        room:removeTag("sj7_yongyi_spades")
        for _, q in sgs.qlist(room:getAllPlayers()) do room:setPlayerMark(q, "sj7_yongyi_got", 0) end
        return
    end
    local move = data:toMoveOneTime()
    if move.to and move.to_place == sgs.Player_PlaceHand then
        local to = room:findPlayer(move.to:objectName())
        if to then
            if move.reason.m_skillName == "yiji" and to:hasSkill("sj7_fuguang") then room:setPlayerMark(to, "sj7_fuguang_got", 1) end
            if move.reason.m_skillName == "luoying" and to:hasSkill("sj7_yongyi") then room:setPlayerMark(to, "sj7_yongyi_got", 1) end
        end
    end
    if move.to_place == sgs.Player_DiscardPile then
        local list = room:getTag("sj7_yongyi_spades"):toString()
        local names = list == "" and {} or list:split("+")
        for _, id in sgs.qlist(move.card_ids) do
            if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Spade then table.insert(names, tostring(id)) end
        end
        room:setTag("sj7_yongyi_spades", sgs.QVariant(table.concat(names, "+")))
    end
end)
sj7_dengyangdingmi:addSkill(sj7_fuguang)
sj7_dengyangdingmi:addSkill(sj7_yongyi)
sj7_dengyangdingmi:addSkill(sj7_yongyi_record)
extension:insertRelatedSkills("sj7_yongyi", "#sj7_yongyi_record")

-- 阮咸
sj7_ruanxian = sgs.General(extension, "sj7_ruanxian", "qun", 3)

local sj7_xian_names = {"slash", "jink", "peach", "analeptic"}
local function sj7_xian_up(p, name) return p:getMark("&sj7_sixian_" .. name) > 0 end

sj7_sixian = gu_trigger("sj7_sixian", {sgs.GameStart}, function(self, event, room, p, data, owner)
    if p ~= owner or owner:getMark("sj7_sixian_set") > 0 then return end
    room:setPlayerMark(owner, "sj7_sixian_set", 1)
    for _, n in ipairs(sj7_xian_names) do room:setPlayerMark(owner, "&sj7_sixian_" .. n, 0) end
end, true)

local function sj7_qingtan_card(name, p)
    local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    c:setSkillName("sj7_qingtan")
    return c
end
local function sj7_qingtan_names(p, pattern)
    local res = {}
    if p:getMark("sj7_sixian_set") == 0 then return res end
    for _, n in ipairs(sj7_xian_names) do
        if p:getMark("sj7_qingtan_" .. n .. "-Clear") == 0 then
            local c = sj7_qingtan_card(n, p)
            local ok
            if pattern then ok = sgs.Sanguosha:matchExpPattern(pattern, p, c) else ok = c:isAvailable(p) end
            c:deleteLater()
            if ok then table.insert(res, n) end
        end
    end
    return res
end
-- Flip n 弦 (n = position of the card name); true if only the matching 弦 is face up.
local function sj7_qingtan_flip(room, p, name)
    room:setPlayerMark(p, "sj7_qingtan_" .. name .. "-Clear", 1)
    p:setTag("sj7_qingtan_target", sgs.QVariant(name))
    local n = 0
    for i, v in ipairs(sj7_xian_names) do if v == name then n = i end end
    local left = {}
    for _, v in ipairs(sj7_xian_names) do table.insert(left, v) end
    for _ = 1, n do
        local choice = room:askForChoice(p, "sj7_qingtan_flip", table.concat(left, "+"), sgs.QVariant(name))
        table.removeOne(left, choice)
        room:setPlayerMark(p, "&sj7_sixian_" .. choice, sj7_xian_up(p, choice) and 0 or 1)
    end
    p:removeTag("sj7_qingtan_target")
    for _, v in ipairs(sj7_xian_names) do
        if sj7_xian_up(p, v) ~= (v == name) then return false end
    end
    return true
end
local sj7_qingtan_gift = sgs.CreateSkillCard {
    name = "sj7_qingtanCard", will_throw = false,
    filter = function() return false end,
    feasible = function(self, targets) return #targets == 0 end,
    on_use = function(self, room, source, targets)
        local names = sj7_qingtan_names(source, nil)
        if #names == 0 then return end
        table.insert(names, "cancel")
        local name = room:askForChoice(source, "sj7_qingtan", table.concat(names, "+"))
        if name == "cancel" then return end
        if sj7_qingtan_flip(room, source, name) then
            source:drawCards(1, "sj7_qingtan")
            source:setTag("sj7_qingtan_card", sgs.QVariant(name))
            room:askForUseCard(source, "@@sj7_qingtan", "@sj7_qingtan", -1, sgs.Card_MethodUse, true)
            source:removeTag("sj7_qingtan_card")
        end
    end,
    on_validate_in_response = function(self, source)
        local room = source:getRoom()
        local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
        local names = sj7_qingtan_names(source, pattern)
        if #names == 0 then return nil end
        local name = names[1]
        if #names > 1 then
            table.insert(names, "cancel")
            name = room:askForChoice(source, "sj7_qingtan", table.concat(names, "+"))
            if name == "cancel" then return nil end
        end
        if sj7_qingtan_flip(room, source, name) then
            source:drawCards(1, "sj7_qingtan")
            local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
            c:setSkillName("sj7_qingtan")
            return c
        end
        return nil
    end,
}
_G["sj7_qingtanCard"] = sj7_qingtan_gift
sj7_qingtan = sgs.CreateViewAsSkillV2 {
    name = "sj7_qingtan", response_or_use = true,
    can_activate = function(self, request)
        local p = request:getInitiator()
        if request:getPattern() == "@@sj7_qingtan" then return true end
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
            return #sj7_qingtan_names(p, nil) > 0
        end
        return #sj7_qingtan_names(p, request:getPattern()) > 0
    end,
    can_select_card = function() return false end,
    card_selection_feasible = function(self, request) return request:getSelectedCardIds():isEmpty() end,
    create_card = function(self, request)
        if request:getPattern() == "@@sj7_qingtan" then
            local cn = request:getInitiator():getTag("sj7_qingtan_card"):toString()
            if cn == "" then return nil end
            return sj7_qingtan_card(cn, request:getInitiator())
        end
        local c = sj7_qingtan_gift:clone(); c:setSkillName("sj7_qingtan"); return c
    end,
}
sj7_qingtan_mod = sgs.CreateTargetModSkillV2 {
    name = "#sj7_qingtan_mod", pattern = "Slash", holder_selector = sgs.CorrectSkill_System,
    correct_func = function(self, ctx)
        local c = ctx:getCard()
        if c and c:getSkillName() == "sj7_qingtan" then
            local t = ctx:getModType()
            if t == sgs.TargetModSkill_DistanceLimit or t == sgs.TargetModSkill_Residue then return 999 end
        end
        return 0
    end,
}
sj7_ruanxian:addSkill(sj7_sixian)
sj7_ruanxian:addSkill(sj7_qingtan)
sj7_ruanxian:addSkill(sj7_qingtan_mod)
extension:insertRelatedSkills("sj7_qingtan", "#sj7_qingtan_mod")

sgs.LoadTranslationTable {
    ["sj7_dengyangdingmi"] = "邓飏丁谧[三设7]",
    ["&sj7_dengyangdingmi"] = "邓飏丁谧",
    ["#sj7_dengyangdingmi"] = "枝淒巢籍",
    ["designer:sj7_dengyangdingmi"] = "狂风159",
    ["sj7_fuguang"] = "浮光",
    [":sj7_fuguang"] = "游戏开始时或你回复体力后，你获得“遗计”；你因“遗计”获得过牌的轮次结束时，若你有“遗计”，你进行一次【浮雷】判定，若判定结果花色不为黑桃，你失去“遗计”，获得判定牌。",
    ["sj7_fuguang_fulei"] = "浮雷",
    ["sj7_yongyi"] = "咏仪",
    [":sj7_yongyi"] = "游戏开始时或你扣减体力后，你获得“落英”；你未因“落英”获得牌的回合结束时，若你有“落英”，你获得一张本回合置入弃牌堆的黑桃牌，若如此做，你失去“落英”，回复1点体力。",

    ["sj7_ruanxian"] = "阮咸[三设7]",
    ["&sj7_ruanxian"] = "阮咸",
    ["#sj7_ruanxian"] = "妙音八达",
    ["designer:sj7_ruanxian"] = "不能更改",
    ["sj7_sixian"] = "四弦",
    [":sj7_sixian"] = "游戏开始时，你将四种牌名的基本牌各一张背面朝上置于武将牌上，称为“弦”。",
    ["&sj7_sixian_slash"] = "弦·杀",
    ["&sj7_sixian_jink"] = "弦·闪",
    ["&sj7_sixian_peach"] = "弦·桃",
    ["&sj7_sixian_analeptic"] = "弦·酒",
    ["sj7_qingtan"] = "清弹",
    [":sj7_qingtan"] = "每回合每种牌名各限一次，当你需要使用一张【杀】/【闪】/【桃】/【酒】时，你可以翻面一/二/三/四张“弦”，然后若仅剩对应牌名的“弦”正面朝上，你摸一张牌并视为使用之（无距离和次数限制）。",
    ["sj7_qingtan_flip"] = "清弹",
    ["@sj7_qingtan"] = "清弹：请使用视为的牌",
    ["sj7_qingtanCard"] = "清弹",
}
end

-- ===== sheji b08 =====
do
local extension = extension_sj
-- 三国杀设计吧 3S7J 马隆 / 3S11J 毛皇后 (batch b08)
-- 马隆：视为使用基本牌或普通锦囊牌的辅助函数
local sj7_virtual_names = {
    "slash", "fire_slash", "thunder_slash", "ice_slash", "peach", "analeptic",
    "ex_nihilo", "dismantlement", "snatch", "duel", "savage_assault", "archery_attack",
    "collateral", "god_salvation", "amazing_grace", "iron_chain", "fire_attack",
    "indulgence", "supply_shortage", "known_both", "befriend_attacking",
}
local function sj7_virtual_use(room, owner, reason)
    local avail = {}
    for _, name in ipairs(sj7_virtual_names) do
        local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
        if c then
            if c:isAvailable(owner) then table.insert(avail, name) end
            c:deleteLater()
        end
    end
    if #avail == 0 then return end
    local name = room:askForChoice(owner, reason .. "_use", table.concat(avail, "+"))
    local card = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
    if not card then return end
    card:setSkillName(reason)
    local targets = sgs.SPlayerList()
    if not card:targetFixed() then
        local selected = sgs.PlayerList()
        while not card:targetsFeasible(selected, owner) or selected:length() < 1 do
            local cands = sgs.SPlayerList()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if not selected:contains(p) and card:targetFilter(selected, p, owner) then cands:append(p) end
            end
            if cands:isEmpty() then break end
            local to = room:askForPlayerChosen(owner, cands, reason .. "_use", "@" .. reason .. "-target:" .. name, false, false)
            if not to then break end
            selected:append(to)
            targets:append(to)
        end
        if not card:targetsFeasible(selected, owner) then card:deleteLater() return end
    end
    room:useCard(sgs.CardUseStruct(card, owner, targets), false)
end

sj7_malong = sgs.General(extension, "sj7_malong", "qun", 4)
sj7_jizhen = gu_trigger("sj7_jizhen", {sgs.CardUsed}, function(self, event, room, p, data, owner)
    if p ~= owner then return end
    local use = data:toCardUse()
    local card = use.card
    if not card or card:isKindOf("SkillCard") then return end
    local basic = card:isKindOf("BasicCard")
    local first = owner:getMark("sj7_jizhen_first")
    if first == 0 then
        room:setPlayerMark(owner, "sj7_jizhen_first", basic and 1 or 2)
        return
    end
    room:setPlayerMark(owner, "sj7_jizhen_first", 0)
    local names = {}
    if first == 1 then table.insert(names, "paoxiao") end
    if basic then table.insert(names, "longdan") end
    if first == 2 and not basic then table.insert(names, "bazhen") end
    for _, n in ipairs(names) do
        if not owner:hasSkill(n) then room:acquireSkill(owner, n) end
    end
end, true)
sj7_pianxiang = gu_trigger("sj7_pianxiang", {sgs.EventPhaseEnd}, function(self, event, room, p, data, owner)
    if p:getPhase() ~= sgs.Player_Finish or not owner:isAlive() then return end
    local skills = {}
    local seen = {}
    for _, s in sgs.qlist(owner:getVisibleSkillList()) do
        local n = s:objectName()
        if not seen[n] and string.sub(n, 1, 1) ~= "#" then seen[n] = true; table.insert(skills, n) end
    end
    if #skills == 0 or not gu_invoke(owner, "sj7_pianxiang", ToData(p)) then return end
    local lost = {}
    while #skills > 0 do
        table.insert(skills, "cancel")
        local choice = room:askForChoice(owner, "sj7_pianxiang", table.concat(skills, "+"))
        table.remove(skills)
        if choice == "cancel" then break end
        table.insert(lost, choice)
        for i, n in ipairs(skills) do
            if n == choice then table.remove(skills, i); break end
        end
    end
    if #lost == 0 then return end
    local virtual = false
    for _, n in ipairs(lost) do
        if n == "sj7_jizhen" or n == "sj7_pianxiang" then virtual = true end
        room:detachSkillFromPlayer(owner, n)
    end
    owner:drawCards(#lost, "sj7_pianxiang")
    if virtual and owner:isAlive() then sj7_virtual_use(room, owner, "sj7_pianxiang") end
end)
sj7_malong:addSkill(sj7_jizhen)
sj7_malong:addSkill(sj7_pianxiang)

-- 毛皇后
local sj11_chaomian_names = {
    slash = true, fire_slash = true, thunder_slash = true, ice_slash = true, jink = true,
    peach = true, analeptic = true, ex_nihilo = true, dismantlement = true, snatch = true,
    duel = true, nullification = true, savage_assault = true, archery_attack = true,
    collateral = true, god_salvation = true, amazing_grace = true, iron_chain = true,
    fire_attack = true, known_both = true, befriend_attacking = true,
}
local function sj11_chaomian_pick(pattern)
    local found = {}
    for word in string.gmatch(string.lower(pattern or ""), "[%a_]+") do
        if sj11_chaomian_names[word] then table.insert(found, word) end
    end
    return found
end
sj11_chaomianvs = sgs.CreateViewAsSkillV2 {
    name = "sj11_chaomian",
    n = 0,
    can_activate = function(skill, request)
        local player = request:getInitiator()
        if not player or player:getTag("sj11_chaomian_ban"):toString() ~= "" then return false end
        if request:getReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then return false end
        return #sj11_chaomian_pick(request:getPattern()) > 0
    end,
    create_card = function(skill, request)
        local found = sj11_chaomian_pick(request:getPattern())
        if #found == 0 then return nil end
        local name = found[1]
        local player = request:getInitiator()
        if #found > 1 and player then
            name = player:getRoom():askForChoice(player, "sj11_chaomian", table.concat(found, "+"))
        end
        local c = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, 0)
        if c then c:setSkillName("sj11_chaomian") end
        return c
    end,
}
sj11_chaomian = sgs.CreateTriggerSkillV2 {
    name = "sj11_chaomian",
    view_as_skill = sj11_chaomianvs,
    global = true,
    events = {sgs.CardFinished, sgs.CardResponded, sgs.CardsMoveOneTime},
    on_record = function(self, event, room, player, data)
        if event ~= sgs.CardsMoveOneTime then return end
        local move = data:toMoveOneTime()
        local from = move.from
        if not from then return end
        local ban = from:getTag("sj11_chaomian_ban"):toString()
        if ban == "" then return end
        for i = 0, move.card_ids:length() - 1 do
            local place = move.from_places:at(i)
            if (place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip)
                and sgs.Sanguosha:getCard(move.card_ids:at(i)):objectName() == ban then
                from:removeTag("sj11_chaomian_ban")
                return
            end
        end
    end,
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardsMoveOneTime or not player or not player:isAlive() then return false end
        if not player:hasSkill(self:objectName()) then return false end
        local card
        if event == sgs.CardFinished then card = data:toCardUse().card
        else card = data:toCardResponse().m_card end
        if card and card:getSkillName() == self:objectName() then return self:objectName(), player end
        return false
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        local card
        if event == sgs.CardFinished then card = data:toCardUse().card
        else card = data:toCardResponse().m_card end
        if not card then return false end
        local current = room:getCurrent()
        local done = false
        if current and current:isAlive()
            and room:askForSkillInvoke(current, "sj11_chaomian_slash", ToData(player)) then
            local slash = sgs.Sanguosha:cloneCard("ice_slash", sgs.Card_NoSuit, 0)
            slash:setSkillName("sj11_chaomian")
            if not current:isProhibited(player, slash) then
                done = true
                room:useCard(sgs.CardUseStruct(slash, current, player), false)
            else slash:deleteLater() end
        end
        if not done then
            player:setTag("sj11_chaomian_ban", sgs.QVariant(card:objectName()))
        end
        return false
    end,
}

sj11_xiti = gu_trigger("sj11_xiti", {sgs.Damaged}, function(self, event, room, p, data, owner)
    if p ~= owner or not owner:isAlive() or owner:getMark("sj11_xiti_round") > 0 then return end
    if not gu_invoke(owner, "sj11_xiti") then return end
    room:setPlayerMark(owner, "sj11_xiti_round", 1)
    local others = room:getOtherPlayers(owner)
    local more = {}
    for _, q in sgs.qlist(others) do
        if q:getHandcardNum() > owner:getHandcardNum() then table.insert(more, q) end
    end
    for _, q in ipairs(more) do
        if q:isAlive() and owner:isAlive() and room:askForSkillInvoke(q, "sj11_xiti_draw", ToData(owner)) then
            owner:drawCards(2, "sj11_xiti")
        end
    end
    local less = {}
    for _, q in sgs.qlist(room:getOtherPlayers(owner)) do
        if q:getHandcardNum() < owner:getHandcardNum() then table.insert(less, q) end
    end
    for _, q in ipairs(less) do
        if q:isAlive() and owner:isAlive() and not owner:isNude()
            and room:askForSkillInvoke(q, "sj11_xiti_discard", ToData(owner)) then
            room:throwCard(room:askForCardChosen(q, owner, "he", "sj11_xiti"), owner, q)
        end
    end
end)
extension:addSkills(gu_record("#sj11_xiti_round", {sgs.RoundStart}, function(self, event, room, p, data)
    for _, q in sgs.qlist(room:getAllPlayers()) do room:setPlayerMark(q, "sj11_xiti_round", 0) end
end))
sj11_maohuanghou = sgs.General(extension, "sj11_maohuanghou", "wei", 3, false)
sj11_maohuanghou:addSkill(sj11_chaomian)
sj11_maohuanghou:addSkill(sj11_xiti)

sgs.LoadTranslationTable {
    ["sj7_malong"] = "马隆[三设7]",
    ["&sj7_malong"] = "马隆",
    ["#sj7_malong"] = "孤师妙器",
    ["designer:sj7_malong"] = "亚里士缺德",
    ["sj7_jizhen"] = "机阵",
    [":sj7_jizhen"] = "锁定技，你每累计使用两张牌后，根据所满足的条件获得对应技能：第一张牌为基本牌：“咆哮”；第二张牌为基本牌：“龙胆”；两张均不为基本牌：“八阵”。",
    ["sj7_pianxiang"] = "偏箱",
    [":sj7_pianxiang"] = "一名角色的回合结束时，你可以失去任意个技能并摸等量的牌，若你选择失去“机阵”或“偏箱”，则你视为使用一张基本牌或普通锦囊牌。",
    ["sj7_pianxiang_use"] = "偏箱",
    ["@sj7_pianxiang-target"] = "偏箱：选择【%arg】的目标",

    ["sj11_maohuanghou"] = "毛皇后[三设11]",
    ["&sj11_maohuanghou"] = "毛皇后",
    ["#sj11_maohuanghou"] = "鸾凤挫翮",
    ["designer:sj11_maohuanghou"] = "白鲨",
    ["sj11_chaomian"] = "朝冕",
    [":sj11_chaomian"] = "你需要使用即时牌时，可以视为使用之。结算后当前回合角色可以视为对你使用一张冰【杀】，否则此技能失效至你失去同名牌。",
    ["sj11_chaomian_slash"] = "朝冕（视为对其使用冰【杀】）",
    ["sj11_xiti"] = "夕惕",
    [":sj11_xiti"] = "每轮限一次，当你受到伤害后，你可以先令所有手牌数大于你的角色选择是否令你摸两张牌，然后所有手牌数小于你的角色选择是否弃置你一张牌。",
    ["sj11_xiti_draw"] = "夕惕（令其摸两张牌）",
    ["sj11_xiti_discard"] = "夕惕（弃置其一张牌）",
}
end

-- ===== sheji b09 =====
do
local extension = extension_sj
-- b09: both generals skipped; nothing to register.
end

return { extension, extension_card, extension_wz, extension_hl, extension_sj }
