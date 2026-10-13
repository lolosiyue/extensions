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
ofgu_liaoliao_prohibit = sgs.CreateProhibitSkill {
    name = "#ofgu_liaoliao_prohibit",
    is_prohibited = function(self, from, to, card)
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
ofgu_tongji = sgs.CreateProhibitSkill {
    name = "ofgu_tongji",
    is_prohibited = function(self, from, to, card)
        if not from or not card:isKindOf("Slash") then return false end
        for _, q in sgs.qlist(from:getAliveSiblings(true)) do
            if q:hasSkill(self:objectName()) and q:getHandcardNum() > q:getHp() and q ~= to then return true end
        end
        return false
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
ofgu_jiuji_prohibit = sgs.CreateProhibitSkill {
    name = "#ofgu_jiuji_prohibit",
    is_prohibited = function(self, from, to, card)
        local partner = from and from:getTag("ofgu_jiuji_active"):toPlayer()
        return partner and partner ~= to
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
ofgu_jinjiu_prohibit = sgs.CreateProhibitSkill {
    name = "#ofgu_jinjiu_prohibit",
    is_prohibited = function(self, from, to, card)
        if not from or not card:isKindOf("Analeptic") then return false end
        for _, q in sgs.qlist(from:getAliveSiblings()) do if q:hasSkill("ofgu_jinjiu") and q:getPhase() ~= sgs.Player_NotActive then return true end end
        return false
    end,
}
ofmou_gaoshun:addSkill(ofgu_xianzhen); ofmou_gaoshun:addSkill(ofgu_xianzhen_mod); ofmou_gaoshun:addSkill(ofgu_xianzhen_trigger)
ofmou_gaoshun:addSkill(ofgu_jinjiu_filter); ofmou_gaoshun:addSkill(ofgu_jinjiu_trigger); ofmou_gaoshun:addSkill(ofgu_jinjiu_prohibit)

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

return { extension, extension_card }
