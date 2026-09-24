-- Source: existing Room-scoped facade plus TODO/QSanguosha-For-Hegemony-xxyheaven/lua/ai/smart-ai.lua (cf61c15).
-- Loaded only by the admitted Original Hegemony bundle in this Room VM.
if not sgs.original_hegemony_ai_loading then return end

-- The donor appends &skill to card material strings; native Card::Parse does not.
-- Normalize only this legacy wire suffix, retaining declaration and target payloads.
-- Baseline generals now use package-scoped HEG variants for these skills.
-- Keep aliases limited to IDs actually renamed by the native HEG packages.
sgs.originalHegemonySkillAliases = {
    nosganglie = {"heg_ganglie"}, nostuxi = {"tenyeartuxi"}, nosluoyi = {"heg_luoyi"},
    nosyiji = {"heg_yiji"}, shensu = {"heg_shensu"},
    duanliang = {"heg_duanliang"}, nosjushou = {"heg_jushou"}, qiangxi = {"heg_qiangxi"},
    jieming = {"heg_jieming"}, fangzhu = {"mobilefangzhu"}, luoshen = {"heg_luoshen"},
    guicai = {"heg_guicai"},
    paoxiao = {"heg_paoxiao"}, kongcheng = {"heg_kongcheng"}, longdan = {"heg_longdan"},
    tieqi = {"heg_tieqi"}, jizhi = {"heg_jizhi"}, liegong = {"heg_liegong"},
    wusheng = {"tenyearwusheng"}, kuanggu = {"tenyearkuanggu"}, huoshou = {"heg_huoshou"}, juxiang = {"heg_juxiang"},
    keji = {"heg_keji"},
    kurou = {"heg_kurou"}, yingzi = {"heg_yingzi_sunce", "heg_yingzi_zhouyu"},
    qicai = {"nosqicai"},
    fanjian = {"heg_fanjian"}, guose = {"heg_guose"}, qianxun = {"heg_qianxun"},
    xiaoji = {"heg_xiaoji"}, yinghun = {"heg_yinghun_sunjian", "heg_yinghun_sunce"},
    tianxiang = {"heg_tianxiang"}, buqu = {"heg_buqu"}, guzheng = {"heg_guzheng"},
    duanbing = {"heg_duanbing"}, fenxun = {"heg_fenxun"}, luanji = {"heg_luanji"},
     weimu = {"heg_weimu"},
	leiji = {"nosleiji"}, duanchang = {"heg_duanchang"},
    wushuang = {"heg_wushuang"}, jiang = {"heg_jiang"},
}
function sgs.originalHegemonySkillNames(skill)
    return sgs.originalHegemonySkillAliases[skill] or {skill}
end
function sgs.originalHegemonyCardWire(wire)
    if type(wire) ~= "string" or not wire:find("=", 1, true) then return wire end
    local prefix, skill, suffix = wire:match("^(.-)&([%w_]*)(.*)$")
    if not prefix then return wire end
    return prefix .. suffix, skill
end
local nativeCardParse = sgs.Card_Parse
sgs.Card_Parse = function(wire)
    local normalized, skill = sgs.originalHegemonyCardWire(wire)
    -- These native V2 skills expose a generic card, while donor strategies use
    -- their historical class IDs for priorities/history. Preserve material IDs.
    local class, materials = normalized:match("^@(%w+)=([^:]*)")
	local active_skills = { HKurouCard = "heg_kurou", HQiangxiCard = "heg_qiangxi" }
    local card
    if active_skills[class] then
        card = sgs.ActiveSkillCard()
        card:setSkillName(active_skills[class])
        for id in materials:gmatch("%d+") do card:addSubcard(tonumber(id)) end
    else
        card = nativeCardParse(normalized)
    end
    if card and skill and skill ~= "" then card:setSkillName(skill) end
    return card
end

-- Donor decision algorithms, retaining the current Room-owned lifecycle and mode policy.
sgs.ai_trick_prohibit = sgs.ai_trick_prohibit or {}
sgs.ai_damage_effect = sgs.ai_damage_effect or {}
sgs.ai_guangxing = sgs.ai_guangxing or {}
sgs.card_lack = sgs.card_lack or {}
-- Fixed donor constants; these do not track or infer any player's allegiance.
sgs.KingdomsTable = {"wei", "shu", "wu", "qun"}
sgs.Slash_Natures = {
    Slash = sgs.DamageStruct_Normal,
    FireSlash = sgs.DamageStruct_Fire,
    ThunderSlash = sgs.DamageStruct_Thunder,
}
-- Current ChoiceMade dispatch uses direct functions for generic events; only
-- reason-specific events (skillInvoke/cardChosen/etc.) use callback tables.

function sgs.cloneCard(name, suit, number)
    local card = sgs.Sanguosha:cloneCard(name, suit or sgs.Card_SuitToBeDecided, number or -1)
    if not card then error("Original Hegemony cannot clone card: " .. tostring(name)) end
    -- The existing SWIG return binding holds the wrapper lease; schedule cleanup
    -- through Card's managed lifetime instead of leaving a temporary clone alive.
    card:deleteLater()
    return card
end

-- Public kingdom is a derived query, never a second mutable allegiance table.
function sgs.originalHegemonyPublicKingdom(player)
    if not player then return "unknown" end
    local kingdom = player:getSeemingKingdom()
    return kingdom ~= "" and kingdom or "unknown"
end
function sgs.originalHegemonyShownCount(kingdom)
    local count = 0
    for _, player in sgs.qlist(global_room:getAlivePlayers()) do
        if sgs.originalHegemonyPublicKingdom(player) == kingdom then count = count + 1 end
    end
    return count
end
function sgs.isAnjiang(player)
    return not player:hasShownOneGeneral()
end
-- Player's raw pile getters expose server state; project private general names
-- through the same per-viewer open flag used by the client projection.
function SmartAI:getGeneralPile(player, pile_name)
    player = player or self.player
    if player:objectName() ~= self.player:objectName()
        and not player:generalPileOpen(pile_name, self.player:objectName()) then return {} end
    return sgs.QList2Table(player:getGeneralPile(pile_name))
end
function SmartAI:getGeneralPileNames(player)
    player = player or self.player
    local names = {}
    for _, pile_name in sgs.qlist(player:getGeneralPileNames()) do
        if player:objectName() == self.player:objectName()
            or player:generalPileOpen(pile_name, self.player:objectName()) then
            table.insert(names, pile_name)
        end
    end
    return names
end
function SmartAI:getGeneralPileName(player, general_name)
    player = player or self.player
    local pile_name = player:getGeneralPileName(general_name)
    if pile_name == "" or (player:objectName() ~= self.player:objectName()
        and not player:generalPileOpen(pile_name, self.player:objectName())) then return "" end
    return pile_name
end
function SmartAI:originalHegemonyOwnKingdom()
    -- The selected Hegemony faction is the sole private source for our own
    -- unrevealed player; all other seats use originalHegemonyPublicKingdom().
    local kingdom = self.player:getSeemingKingdom()
    if kingdom ~= "" then return kingdom end
    local role = self.player:getRole()
    if role == "careerist" or role:startsWith("careerist_") then return role end
    -- The existing Qt property invokes Player::getHegemonyKingdom(); it also
    -- works through the current Lua binding without exposing another getter.
    kingdom = self.player:property("hegemony_kingdom"):toString()
    return kingdom ~= "" and kingdom or "unknown"
end
function SmartAI:evaluateKingdom(player, observer)
    if not player then return "unknown" end
    -- Only this AI's own identity is available before reveal.
    if player:objectName() == self.player:objectName() and (not observer or observer == self.player) then
        return player:getRole() == "careerist" and "careerist" or self:originalHegemonyOwnKingdom()
    end
    return sgs.originalHegemonyPublicKingdom(player)
end
function SmartAI:originalHegemonyIsBigKingdomPlayer(player)
    player = player or self.player
    if not player or not player:hasShownOneGeneral() then return false end
    local big_kingdoms = sgs.QList2Table(player:getBigKingdoms("AI"))
    return table.contains(big_kingdoms, player:getSeemingKingdom())
        or table.contains(big_kingdoms, player:objectName())
end
function SmartAI:isFriendWith(player)
    return self:isFriend(player)
end
function SmartAI:getKingdomCount()
    local known = {}
    for _, player in sgs.qlist(self.room:getAlivePlayers()) do
        local kingdom = self:evaluateKingdom(player)
        known[(kingdom == "careerist" or kingdom == "unknown") and player:objectName() or kingdom] = true
    end
    local count = 0
    for _ in pairs(known) do count = count + 1 end
    return count
end
function sgs.hasNullSkill(skill, player)
    -- Suppression is queried from native public reveal state, never a donor history map.
    if not player:hasSkill(skill) then return true end
    return false
end
function sgs.originalHegemonyHasShownSkills(player, expression)
    for _, group in ipairs(expression:split("|")) do
        local shown = true
        for _, skill in ipairs(group:split("+")) do
            local found = false
            for _, actual in ipairs(sgs.originalHegemonySkillNames(skill)) do
                if player:hasShownSkill(actual) then found = true break end
            end
            if not found then shown = false break end
        end
        if shown then return true end
    end
    return false
end
function sgs.originalHegemonySkillCount(player, head)
    local count = 0
    for _, skill in sgs.qlist(player:getVisibleSkillList()) do
        if player:hasShownSkill(skill:objectName()) and
            ((head and player:inHeadSkills(skill:objectName())) or
             (not head and player:inDeputySkills(skill:objectName()))) then count = count + 1 end
    end
    return count
end
local initialize = SmartAI.initialize
function SmartAI:initialize(player)
    self.retain, self.kept, self.predictedRange, self.slashAvail = 2, {}, 1, 1
    for _, other in sgs.qlist(player:getRoom():getAllPlayers()) do
        local name = other:objectName()
        sgs.card_lack[name] = sgs.card_lack[name] or {Slash=0, Jink=0, Peach=0}
        sgs.ai_guangxing[name] = sgs.ai_guangxing[name] or {}
    end
    initialize(self, player)
end

-- These hooks run in the existing Room VM. Never keep the event QVariant or a
-- borrowed CardUseStruct: Card userdata alone has the existing SWIG wrapper lease.
local aoe_stack = {}
local function publish_aoe()
    local top = aoe_stack[#aoe_stack]
    sgs.ai_AOE_data = top and top.confirmed and top.relevant and top or nil
end
local function aoe_frame(use)
    return {card=use.card, targets={}, confirmed=false, relevant=false}
end
sgs.ai_event_callback[sgs.PreCardUsed].original_hegemony = function(self, player, data)
    local use = data:toCardUse()
    if not use.card or not use.card:isKindOf("AOE") or not use.from
        or player:objectName() ~= use.from:objectName() then return end
    local top = aoe_stack[#aoe_stack]
    -- Duplicate preparation notifications do not create an extra unfinished frame.
    if not top or top.card ~= use.card or top.confirmed then
        aoe_stack[#aoe_stack + 1] = aoe_frame(use)
    end
    publish_aoe()
end
sgs.ai_event_callback[sgs.TargetConfirmed].original_hegemony = function(self, player, data)
    local use = data:toCardUse()
    if not use.card or not use.card:isKindOf("AOE") then return end
    local top = aoe_stack[#aoe_stack]
    if not top or top.card ~= use.card then
        top = aoe_frame(use)
        aoe_stack[#aoe_stack + 1] = top
    end
    top.targets, top.relevant, top.confirmed = {}, false, true
    for _, target in sgs.qlist(use.to) do
        top.targets[target:objectName()] = true
        if target:hasShownSkill("mobilefangzhu") or
            (use.card:isKindOf("ArcheryAttack") and target:hasShownSkill("guidao")
                and target:hasShownSkill("nosleiji")) then top.relevant = true end
    end
    publish_aoe()
end
sgs.ai_event_callback[sgs.CardFinished].original_hegemony = function(self, player, data)
    local use = data:toCardUse()
    if not use.card or not use.card:isKindOf("AOE") then return end
    for i = #aoe_stack, 1, -1 do
        if aoe_stack[i].card == use.card then
            table.remove(aoe_stack, i)
            break
        end
    end
    publish_aoe()
end

local function public_card_lack(player)
    local name = player:objectName()
    sgs.card_lack[name] = sgs.card_lack[name] or {Slash=0, Jink=0, Peach=0}
    return sgs.card_lack[name]
end
sgs.ai_event_callback[sgs.ChoiceMade].original_hegemony = function(self, player, data)
    local parts = data:toString():split(":")
    if parts[1] ~= "cardResponded" then return end
    local pattern, answer = parts[2] or "", parts[#parts]
    local missing = answer == "" or answer == "_nil_" or answer == "."
    local lack = public_card_lack(player)
    -- Current Room uses an empty final field for refusal; donor used _nil_.
    if pattern:find("jink", 1, true) then
        if not missing or not self:hasEightDiagramEffect(player) then lack.Jink = missing and 1 or 0 end
    elseif pattern:find("slash", 1, true) then lack.Slash = missing and 1 or 0
    elseif pattern:find("peach", 1, true) then lack.Peach = missing and 1 or 0 end
end
sgs.ai_event_callback[sgs.CardsMoveOneTime].original_hegemony = function(self, player, data)
    local move = data:toMoveOneTime()
    if move.to and move.to_place == sgs.Player_PlaceHand
        and player:objectName() == move.to:objectName() then
        local lack = public_card_lack(player)
        for index, id in sgs.qlist(move.card_ids) do
            local card = sgs.Sanguosha:getCard(id)
            local open = move.open:length() > index and move.open:at(index)
            if not open and not card:hasFlag("visible") then
                -- A closed gain invalidates prior absence; do not inspect its face.
                lack.Slash, lack.Jink, lack.Peach = 0, 0, 0
                break
            end
            for _, kind in ipairs({"Slash", "Jink", "Peach"}) do
                if card:isKindOf(kind) then lack[kind] = 0 end
            end
        end
    end
    -- A publicly discarded Jink while Leiji is shown is the donor's positive
    -- retention hint (2), not proof of a hidden card. No AI_Playing global flag.
    if move.from and player:objectName() == move.from:objectName()
        and player:getPhase() == sgs.Player_Discard and player:hasShownSkill("nosleiji")
        and player:getHandcardNum() >= 2 and move.to_place == sgs.Player_DiscardPile
        and move.reason.m_reason == sgs.CardMoveReason_S_REASON_RULEDISCARD then
        for _, id in sgs.qlist(move.card_ids) do
            if sgs.Sanguosha:getCard(id):isKindOf("Jink") then public_card_lack(player).Jink = 2 end
        end
    end
end

-- Donor pressure heuristic derives only public strength; it does not decide allegiance.
function sgs.originalHegemonyGameProcess()
	local value = {}
	local kingdoms = {"wei", "shu", "wu", "qun"}
	for _, kingdom in ipairs(kingdoms) do
		value[kingdom] = 0
	end

	local anjiang = 0
	local players = global_room:getAlivePlayers()
	for _, ap in sgs.qlist(players) do
		if table.contains(kingdoms, sgs.originalHegemonyPublicKingdom(ap)) then
			local v = 3 + sgs.getDefense(ap) / 2
			value[sgs.originalHegemonyPublicKingdom(ap)] = value[sgs.originalHegemonyPublicKingdom(ap)] + v
		else
			anjiang = anjiang + 1
		end
	end

	local cmp = function(a, b)
		return value[a] > value[b]
	end
	table.sort(kingdoms, cmp)
	local sum_value1, sum_value2, sum_value3 = 0, 0, 0
	for i = 2, #kingdoms do
		sum_value1 = sum_value1 + value[kingdoms[i]]
		if i < #kingdoms then sum_value2 = sum_value2 + value[kingdoms[i]] end
		if i < #kingdoms - 1 then sum_value3 = sum_value3 + value[kingdoms[i]] end

	end

	local process = "==="
	if value[kingdoms[1]] >= sum_value1 and value[kingdoms[1]] > 0 then
		local playerNum_1 = sgs.originalHegemonyShownCount(kingdoms[1])
		local playerNum_2 = sgs.originalHegemonyShownCount(kingdoms[2])
		if players:length() > 4 and (players:length() / 2 <= playerNum_1 or playerNum_2 + anjiang <= playerNum_1 or anjiang <= 1) then process = kingdoms[1] .. ">>>"
		elseif anjiang <= players:length() / 2  - 1 then process = kingdoms[1] .. ">>"
		elseif anjiang <= players:length() / 2 + 1 then process = kingdoms[1] .. ">" end
	elseif value[kingdoms[1]] >= sum_value2 and value[kingdoms[1]] > 0 then
		if anjiang == 0 then process = kingdoms[1] .. ">>"
		elseif anjiang <= players:length() / 2 - 1 then process = kingdoms[1] .. ">" end
	elseif value[kingdoms[1]] >= sum_value3 and value[kingdoms[1]] > 0 then
		process = kingdoms[1] .. ">"
	end

	return process
end

	sgs.lose_equip_skill = "heg_xiaoji"
	sgs.lose_one_equip_skill = ""
	sgs.need_kongcheng = "heg_kongcheng"
	sgs.masochism_skill = 		"heg_yiji|nosfankui|heg_jieming|heg_ganglie|mobilefangzhu|heg_hengjiang|heg_qianhuan"
	sgs.wizard_skill = 		"guicai|heg_guicai|guidao|tiandu"
	sgs.wizard_harm_skill = 	"guicai|heg_guicai|guidao"
	sgs.priority_skill = 		"dimeng|haoshi|qingnang|heg_jizhi|guzheng|qixi|jieyin|heg_guose|heg_duanliang|heg_fanjian|lijian|tenyeartuxi|qiaobian|heg_zhiheng|heg_luoshen|rende|wansha|heg_qingcheng|shuangren"
	sgs.save_skill = 		"jijiu"
	sgs.exclusive_skill = 		"heg_duanchang|heg_buqu"
	sgs.Active_cardneed_skill =		"heg_paoxiao|tianyi|shuangxiong|heg_jizhi|heg_guose|heg_duanliang|qixi|qingnang|heg_luoyi|" ..
								"jieyin|heg_zhiheng|rende|heg_luanji|qiaobian|lirang"
	sgs.notActive_cardneed_skill =		"heg_kanpo|guicai|heg_guicai|guidao|beige|xiaoguo|liuli|heg_tianxiang|jijiu"
	sgs.cardneed_skill =  sgs.Active_cardneed_skill .. "|" .. sgs.notActive_cardneed_skill
	sgs.drawpeach_skill =		"tenyeartuxi|qiaobian"
	sgs.recover_skill =		"rende|tenyearkuanggu|heg_zaiqi|jieyin|qingnang|yinghun|hunzi|shenzhi|heg_buqu"
	sgs.use_lion_skill =		 "heg_duanliang|qixi|guidao|lijian|heg_zhiheng|heg_fenxun|heg_qingcheng"
	sgs.need_equip_skill = 		"heg_shensu|beige|heg_huyuan|heg_qingcheng"
	sgs.judge_reason =		"bazhen|EightDiagram|supply_shortage|heg_tuntian|heg_qianxi|indulgence|lightning|nosleiji|heg_tieqi|heg_luoshen|heg_ganglie"

	sgs.ai_skill_cardask["@command-select"] = function(self)
		local retained = {}
		for _, place in ipairs({"h", "e"}) do
			local cards = sgs.QList2Table(self.player:getCards(place))
			if #cards > 0 then
				self:sortByKeepValue(cards, true)
				table.insert(retained, cards[1]:getEffectiveId())
			end
		end
		return #retained > 0 and "$" .. table.concat(retained, "+") or "."
	end

	sgs.Friend_All = 0
	sgs.Friend_Draw = 1
	sgs.Friend_Male = 2
	sgs.Friend_Female = 3
	sgs.Friend_Wounded = 4
	sgs.Friend_MaleWounded = 5
	sgs.Friend_FemaleWounded = 6

function SmartAI:getTurnUse()
    -- Native V2 fill binds each candidate to the current activation request.
    self.active_skill_requests = {}
	local cards = {}
	for _ ,c in sgs.qlist(self.player:getHandcards()) do
		if c:isAvailable(self.player) then table.insert(cards, c) end
	end
	for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
		local c = sgs.Sanguosha:getCard(id)
		if c:isAvailable(self.player) then table.insert(cards, c) end
	end

	local turnUse = {}
	local slash = sgs.cloneCard("slash")
	local slashAvail = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, slash)
	self.slashAvail = slashAvail
	self.predictedRange = self.player:getAttackRange()
	self.slash_distance_limit = (1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, slash) > 50)

	self.weaponUsed = false
	self:fillSkillCards(cards)

	if self.player:hasWeapon("Crossbow") or #self.player:property("extra_slash_specific_assignee"):toString():split("+") > 1 then
		slashAvail = 100
		self.slashAvail = slashAvail
	end
	local slashes = {}

	for _, card in ipairs(cards) do

		local dummy_use = { isDummy = true }

		local type = card:getTypeId()
		self["use" .. sgs.ai_type_name[type + 1]](self, card, dummy_use)

		if dummy_use.card then
			if dummy_use.card:isKindOf("Slash") then
				if dummy_use.card:hasFlag("AIGlobal_KillOff") then table.insert(slashes, dummy_use.card) break end
				table.insert(slashes, dummy_use.card)
			else
				if self.player:hasFlag("InfinityAttackRange") or self.player:getMark("InfinityAttackRange") > 0 then
					self.predictedRange = 10000
				elseif dummy_use.card:isKindOf("Weapon") then
					if not sgs.weapon_range[card:getClassName()] then
						self.room:writeToConsole("weapon_range" .. card:getClassName())
					end
					self.predictedRange = sgs.weapon_range[card:getClassName()] or 1
					self.weaponUsed = true
				else
					self.predictedRange = 1
				end
				if dummy_use.card:objectName() == "Crossbow" then slashAvail = 100 self.slashAvail = slashAvail end
				table.insert(turnUse, dummy_use.card)
			end
			if self:getDynamicUsePriority(dummy_use.card) >= 9 then break end
		end
	end

	if slashAvail > 0 and #slashes > 0 then
		self:sortByUseValue(slashes)
		for i = 1, slashAvail do
			table.insert(turnUse, slashes[i])
		end
	end

	return turnUse
end

function SmartAI:activate(use)
	self:updatePlayers()
	self:assignKeep(true)
	self.toUse = self:getTurnUse()
	self:sortByDynamicUsePriority(self.toUse)
	for _, card in ipairs(self.toUse) do
		if not self.player:isCardLimited(card, card:getHandlingMethod())
			or (card:canRecast() and not self.player:isCardLimited(card, sgs.Card_MethodRecast)) then
			local type = card:getTypeId()

			self["use" .. sgs.ai_type_name[type + 1]](self, card, use)

			if use:isValid("") then
				self.toUse = nil
				return
			end
			if use.card and use.card:isKindOf("Slash") and (not use.to or use.to:isEmpty()) then
				self.toUse = nil
				return
			end

			if use.card then self:speak(use.card:getClassName(), self.player:isFemale()) end
		end
	end
	self.toUse = nil
end





sgs.ai_card_intention["general"] = function(to, level)
end





function sgs.getDefense(player)
	if not player then return 0 end
	local hp = player:getHp()
	if player:hasShownSkill("heg_benghuai") and player:getHp() > 4 then hp = 4 end
	local defense = math.min(hp * 2 + player:getHandcardNum(), hp * 3)
	local hasEightDiagram = false
	if player:hasArmorEffect("EightDiagram") or player:hasArmorEffect("bazhen") then
		hasEightDiagram = true
	end

	if player:getArmor() and player:hasArmorEffect(player:getArmor():objectName()) then defense = defense + 2 end
	if player:getDefensiveHorse() then defense = defense + 0.5 end

	if player:hasTreasure("JadeSeal") then defense = defense + 2 end
	if player:hasTreasure("WoodenOx") then defense = defense + player:getPile("wooden_ox"):length() end

	if hasEightDiagram then
		if player:hasShownSkill("tiandu") then defense = defense + 1 end
		if player:hasShownSkill("nosleiji") then defense = defense + 1 end
		if player:hasShownSkill("hongyan") then defense = defense + 1 end
	end

	local m = sgs.masochism_skill:split("|")
	for _, masochism in ipairs(m) do
		if player:hasShownSkill(masochism) then
			local goodHp = player:getHp() > 1 or getCardsNum("Peach", player) >= 1 or getCardsNum("Analeptic", player) >= 1
							or hasBuquEffect(player) or hasNiepanEffect(player)
			if goodHp then defense = defense + 1 end
		end
	end

	if player:hasShownSkill("heg_jieming") then defense = defense + 3 end
	if player:hasShownSkill("heg_yiji") then defense = defense + 2 end
	if player:hasShownSkill("tenyeartuxi") then defense = defense + 0.5 end
	if player:hasShownSkill("heg_luoshen") then defense = defense + 1 end

	if player:hasShownSkill("rende") and player:getHp() > 2 then defense = defense + 1 end
	if player:hasShownSkill("heg_zaiqi") and player:getHp() > 1 then defense = defense + player:getLostHp() * 0.5 end
	if sgs.originalHegemonyHasShownSkills(player, "heg_tieqi|heg_liegong|tenyearkuanggu") then defense = defense + 0.5 end
	if player:hasShownSkill("xiangle") then defense = defense + 1 end
	if player:hasShownSkill("shushen") then defense = defense + 1 end
	if player:hasShownSkill("heg_kongcheng") and player:isKongcheng() then defense = defense + 2 end
	if player:hasShownSkill("heg_shouyue") then
		for _, p in sgs.qlist(global_room:getAlivePlayers()) do
			if p:getKingdom() == "shu" then
				if p:hasShownSkill("tenyearwusheng") then defense = defense + 1 end
				if p:hasShownSkill("heg_paoxiao") then defense = defense + 1 end
				if p:hasShownSkill("heg_longdan") then defense = defense + 1 end
				if p:hasShownSkill("heg_liegong") then defense = defense + 1 end
				if p:hasShownSkill("heg_tieqi") then defense = defense + 1 end
			end
		end
	end

	if sgs.originalHegemonyHasShownSkills(player, "heg_yinghun_sunjian|heg_yinghun_sunce") and player:getLostHp() > 0 then defense = defense + player:getLostHp() - 0.5 end
	if player:hasShownSkill("heg_tianxiang") then defense = defense + player:getHandcardNum() * 0.5 end
	if player:hasShownSkill("heg_buqu") then defense = defense + math.max(4 - player:getPile("heg_buqu"):length(), 0) end
	if player:hasShownSkill("guzheng") then defense = defense + 1 end
	if player:hasShownSkill("dimeng") then defense = defense + 2 end
	if player:hasShownSkill("heg_keji") then defense = defense + player:getHandcardNum() * 0.5 end
	if player:hasShownSkill("jieyin") and player:getHandcardNum() > 1 then defense = defense + 2 end

	if player:hasShownSkill("heg_qianhuan") then defense = defense + (player:getPile("sorcery"):length() + 1) * 2 end
	if player:hasShownSkill("jijiu") then defense = defense + 2 end
	if player:hasShownSkill("lijian") then defense = defense + 0.5 end
	if player:hasLordSkill("heg_hongfa") then
		for _, p in sgs.qlist(global_room:getAlivePlayers()) do
			if sgs.originalHegemonyPublicKingdom(p) == "qun" then defense = defense + 1 end
		end
	end

	if not player:faceUp() then defense = defense - 0.5 end
	if player:containsTrick("indulgence") then defense = defense - 0.5 end
	if player:containsTrick("supply_shortage") then defense = defense - 0.5 end

	if global_room:getCurrent() then
		defense = defense + (player:aliveCount() - (player:getSeat() - global_room:getCurrent():getSeat()) % player:aliveCount()) / 4
	end

	return defense
end

function sgs.getValue(player)
	if not player then global_room:writeToConsole(debug.traceback()) end
	return player:getHp() * 2 + player:getHandcardNum()
end

function SmartAI:assignKeep(start)
	self.keepValue = {}
	self.kept = {}

	if start then
		--[[
			通常的保留顺序
			"peach-1" = 7,
			"peach-2" = 5.8, "jink-1" = 5.2,
			"peach-3" = 4.5, "analeptic-1" = 4.1,
			"jink-2" = 4.0, "ExNihilo-1" = 3.9, "BefriendAttacking-1" = 3.88, "nullification-1" = 3.8, "thunderslash-1" = 3.66 "fireslash-1" = 3.63
			"slash-1" = 3.6 indulgence-1 = 3.5 SupplyShortage-1 = 3.48 snatch-1 = 3.46 Dismantlement-1 = 3.44 Duel-1 = 3.42 Drownning -3.40
				BurningCamps = 3.38, Collateral-1 = 3.36 ArcheryAttack-1 = 3.35 SavageAssault-1 = 3.34 KnownBoth = 3.33 IronChain = 3.32 GodSalvation-1 = 3.30,
				Fireattack-1 = 3.28 AllianceFeast = 3.26 FightTogether =3.24 LureTiger = 3.22 threaten_emperor = 3.2 "peach-4" = 3.1
			"analeptic-2" = 2.9, "jink-3" = 2.7 ExNihilo-2 = 2.7 nullification-2 = 2.6 thunderslash-2 = 2.46 fireslash-2 = 2.43 slash-2 = 2.4
			...
			Weapon-1 = 2.08 Armor-1 = 2.06 Treasure = 2.05 DefensiveHorse-1 = 2.04 OffensiveHorse-1 = 2
			...
			AwaitExhausted = 1
			imperial_order = 0
			AmazingGrace-1 = -9 Lightning-1 = -10
		]]

		self.keepdata = {}
		for k, v in pairs(sgs.ai_keep_value) do
			self.keepdata[k] = v
		end

		for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
			local skilltable = sgs[askill:objectName() .. "_keep_value"]
			if skilltable then
				for k, v in pairs(skilltable) do
					self.keepdata[k] = v
				end
			end
		end
	end

	if sgs.turncount <= 1 and #self.enemies == 0 then
		self.keepdata.Jink = 4.2
	end

	if not self:isWeak() or self.player:getHandcardNum() >= 4 then
		for _, friend in ipairs(self.friends_noself) do
			if self:willSkipDrawPhase(friend) or self:willSkipPlayPhase(friend) then
				self.keepdata.Nullification = 5.5
				break
			end
		end
	end

	if self:getOverflow(self.player, true) == 1 then
		self.keepdata.Analeptic = (self.keepdata.Jink or 5.2) + 0.1
		-- 特殊情况下还是要留闪，待补充...
	end

	if not self:isWeak() then
		local needDamaged = false
		if not needDamaged and not sgs.isGoodTarget(self.player, self.friends, self) then needDamaged = true end
		if not needDamaged then
			for _, skill in sgs.qlist(self.player:getVisibleSkillList(true)) do
				local callback = sgs.ai_need_damaged[skill:objectName()]
				if type(callback) == "function" and callback(self, nil, self.player) then
					needDamaged = true
					break
				end
			end
		end
		if needDamaged then
			self.keepdata.ThunderSlash = 5.2
			self.keepdata.FireSlash = 5.1
			self.keepdata.Slash = 5
			self.keepdata.Jink = 4.5
		end
	end

	for _, card in sgs.qlist(self.player:getCards("he")) do
		self.keepValue[card:getEffectiveId()] = self:writeKeepValue(card)
	end

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards, true)

	local resetCards = function(allcards)
		local result = {}
		for _, a in ipairs(allcards) do
			local found
			for _, b in ipairs(self.kept) do
				if a:getEffectiveId() == b:getEffectiveId() then
					found = true
					break
				end
			end
			if not found then table.insert(result, a) end
		end
		return result
	end

	for i = 1, self.player:getHandcardNum() do
		for _, card in ipairs(cards) do
			local v = self:getKeepValue(card, self.kept)
			self.keepValue[card:getEffectiveId()] = v
			self.keepdata[card:getClassName()] = v
			table.insert(self.kept, card)
			break
		end
		cards = resetCards(cards)
	end

end

function SmartAI:writeKeepValue(card)
	local maxvalue = self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
	local mostvaluable_class = card:getClassName()
	for k, v in pairs(self.keepdata) do
		if isCard(k, card, self.player) and v > maxvalue then
			maxvalue = v
			mostvaluable_class = k
		end
	end
	local cardPlace = self.room:getCardPlace(card:getEffectiveId())
	if cardPlace == sgs.Player_PlaceEquip then
		if card:isKindOf("Armor") and self:needToThrowArmor() then return -10
		elseif self.player:hasSkills(sgs.lose_equip_skill) then
			if card:isKindOf("OffensiveHorse") then return -10
			elseif card:isKindOf("Weapon") then return -9.9
			elseif card:isKindOf("OffensiveHorse") then return -9.8
			else return -9.7
			end
		elseif self.player:hasSkills("bazhen|jgyizhong") and card:isKindOf("Armor") then return -8
		elseif self:needKongcheng() then return 5.0
		end
		local value = 0
		if card:isKindOf("Armor") then value = self:isWeak() and 5.2 or 3.2
		elseif card:isKindOf("DefensiveHorse") then value = self:isWeak() and 4.3 or 3.19
		elseif card:isKindOf("Weapon") then value = self.player:getPhase() == sgs.Player_Play and self:slashIsAvailable() and 3.39 or 3.2
		elseif card:isKindOf("JadeSeal") then value = 5
		elseif card:isKindOf("WoodenOx") then
			value = 3.19
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				local c = sgs.Sanguosha:getCard(id)
				value = value + (sgs.ai_keep_value[c:getClassName()] or 0)
			end
		else value = 3.19
		end
		if not card:isKindOf(mostvaluable_class) then
			value = value + maxvalue
		end
		return value
	elseif cardPlace == sgs.Player_PlaceHand then
		local value_suit, value_number, newvalue = 0, 0, 0
		local suit_string = card:getSuitString()
		local number = card:getNumber()
		local i = 0

		for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
			if sgs[askill:objectName() .. "_suit_value"] then
				local v = sgs[askill:objectName() .. "_suit_value"][suit_string]
				if v then
					i = i + 1
					value_suit = value_suit + v
				end
			end
		end
		if i > 0 then value_suit = value_suit / i end

		i = 0
		for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
			if sgs[askill:objectName() .. "_number_value"] then
				local v = sgs[askill:objectName() .. "_number_value"][tostring(number)]
				if v then
					i = i + 1
					value_number = value_number + v
				end
			end
		end

		if i > 0 then value_number = value_number / i end
			newvalue = maxvalue + value_suit + value_number
			if not card:isKindOf(mostvaluable_class) then 	newvalue = newvalue + 0.1 end
		newvalue = self:adjustKeepValue(card, newvalue)
			return newvalue
	else
		return self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
	end
end

function SmartAI:getKeepValue(card, kept)
	local cardPlace = self.room:getCardPlace(card:getEffectiveId())
	local v = self.keepValue[card:getEffectiveId()] or self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
	if not kept then
		if cardPlace ~= sgs.Player_PlaceHand and cardPlace ~= sgs.Player_PlaceEquip then
			v = self:adjustKeepValue(card, v)
		end
		return v
	end

	local maxvalue = self.keepdata[card:getClassName()] or sgs.ai_keep_value[card:getClassName()] or 0
	local mostvaluable_class = card:getClassName()
	for k, v in pairs(self.keepdata) do
		if isCard(k, card, self.player) and v > maxvalue then
			maxvalue = v
			mostvaluable_class = k
		end
	end

	if cardPlace == sgs.Player_PlaceHand then
		local dec = 0
		for _, acard in ipairs(kept) do
			if isCard(mostvaluable_class, acard, self.player) then
				v = v - 1.2 - dec
				dec = dec + 0.1
			elseif acard:isKindOf("Slash") and card:isKindOf("Slash") then
				v = v - 1.2 - dec
				dec = dec + 0.1
			end
		end
	end
	return v
end

function SmartAI:adjustKeepValue(card, v)
	local suits = {"club", "spade", "diamond", "heart"}
	for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
		local callback = sgs.ai_suit_priority[askill:objectName()]
		if type(callback) == "function" then
			suits = callback(self, card):split("|")
			break
		elseif type(callback) == "string" then
			suits = callback:split("|")
			break
		end
	end
	table.insert(suits, "no_suit")

	if card:isKindOf("Slash") then
		if card:isRed() then v = v + 0.02 end
		if card:isKindOf("NatureSlash") then v = v + 0.03 end
		if self.player:hasSkill("heg_jiang") and card:isRed() then v = v + 0.04 end
	elseif card:isKindOf("HegNullification") then v = v + 0.02
	end

	if self.player:getPile("wooden_ox"):contains(card:getEffectiveId()) then
		v = v - 0.1
	end

	local suits_value = {}
	for index,suit in ipairs(suits) do
		suits_value[suit] = index * 2
	end
	v = v + (suits_value[card:getSuitString()] or 0) / 100
	v = v + card:getNumber() / 500
	return v
end

function SmartAI:getUseValue(card)
	local class_name = card:isKindOf("LuaSkillCard") and card:objectName() or card:getClassName()
	local v = sgs.ai_use_value[class_name] or 0

	if card:getTypeId() == sgs.Card_TypeSkill then
		return v
	elseif card:getTypeId() == sgs.Card_TypeEquip then
		if self.player:hasEquip(card) then
			if card:isKindOf("OffensiveHorse") and self.player:getAttackRange() > 2 then return 5.5 end
			if card:isKindOf("DefensiveHorse") and self:hasEightDiagramEffect() then return 5.5 end
			return 9
		end
		if not self:getSameEquip(card) then v = 6.7 end
		if self.weaponUsed and card:isKindOf("Weapon") then v = 2 end
		if self.player:hasSkills("heg_qiangxi") and card:isKindOf("Weapon") then v = 2 end
		if self.player:hasSkill("heg_kurou") and card:isKindOf("Crossbow") then return 9 end
		if self.player:hasSkills("bazhen|jgyizhong") and card:isKindOf("Armor") then v = 2 end

		if self.player:hasSkills(sgs.lose_equip_skill) then return 10 end
	elseif card:getTypeId() == sgs.Card_TypeBasic then
		if card:isKindOf("Slash") then
			if self.player:hasFlag("TianyiSuccess") or self:hasHeavySlashDamage(self.player, card) then v = 8.7 end
			if self.player:getPhase() == sgs.Player_Play and self:slashIsAvailable() and #self.enemies > 0 and self:getCardsNum("Slash") == 1 then v = v + 5 end
			if self:hasCrossbowEffect() then v = v + 4 end
			if card:getSkillName() == "Spear" then v = v - 1 end
		elseif card:isKindOf("Jink") then
			if self:getCardsNum("Jink") > 1 then v = v - 6 end
		elseif card:isKindOf("Peach") then
			if self.player:isWounded() then v = v + 6 end
		end
	elseif card:getTypeId() == sgs.Card_TypeTrick then
		if self.player:getPhase() == sgs.Player_Play and not card:isAvailable(self.player) then v = 0 end
		if self.player:getWeapon() and not self.player:hasSkills(sgs.lose_equip_skill) and card:isKindOf("Collateral") then v = 2 end
		if card:getSkillName() == "shuangxiong" then v = 6 end
		if card:isKindOf("Duel") then v = v + self:getCardsNum("Slash") * 2 end
		if self.player:hasSkill("heg_jizhi") then v = v + 4 end
	end

	if self.player:hasSkills(sgs.need_kongcheng) then
		if self.player:getHandcardNum() == 1 then v = 10 end
	end

	if self.player:getPile("wooden_ox"):contains(card:getEffectiveId()) then
		v = v + 1
	end

	if card:isKindOf("HHalberdCard") then v = v + 20 end

	if self.player:getPhase() == sgs.Player_Play then v = self:adjustUsePriority(card, v) end
	return v
end

function SmartAI:getUsePriority(card)
	local class_name = card:getClassName()
	local v = 0
	if card:isKindOf("EquipCard") then
		if self.player:hasSkills(sgs.lose_equip_skill) then return 15 end
		if card:isKindOf("Armor") and not self.player:getArmor() then v = (sgs.ai_use_priority[class_name] or 0) + 5.2
		elseif card:isKindOf("Weapon") and not self.player:getWeapon() then v = (sgs.ai_use_priority[class_name] or 0) + 3
		elseif card:isKindOf("DefensiveHorse") and not self.player:getDefensiveHorse() then v = 5.8
		elseif card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then v = 5.5
		elseif card:isKindOf("Treasure") and not self.player:getTreasure() then
			v = 5.6
			if card:isKindOf("JadeSeal") then v = v + 0.1 end
		end
		return v
	end

	v = sgs.ai_use_priority[class_name] or 0
	if class_name == "LuaSkillCard" and card:isKindOf("LuaSkillCard") then
		v = sgs.ai_use_priority[card:objectName()] or 0
	end
	return self:adjustUsePriority(card, v)
end

function SmartAI:adjustUsePriority(card, v)
	local suits = {"club", "spade", "diamond", "heart"}

	if card:getTypeId() == sgs.Card_TypeSkill then return v end
	if card:getTypeId() == sgs.Card_TypeEquip then return v end

	for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
		local callback = sgs.ai_suit_priority[askill:objectName()]
		if type(callback) == "function" then
			suits = callback(self, card):split("|")
			break
		elseif type(callback) == "string" then
			suits = callback:split("|")
			break
		end
	end

	table.insert(suits, "no_suit")
	if card:isKindOf("Slash") then
		if card:getSkillName() == "Spear" then v = v - 0.1 end
		if card:isRed() then
			v = v - 0.05
		end
		if card:isKindOf("NatureSlash") then
			if self.slashAvail == 1 then
				v = v + 0.05
				if card:isKindOf("FireSlash") then
					for _, enemy in ipairs(self.enemies) do
						if enemy:hasArmorEffect("Vine") or enemy:getMark("@gale") > 0 then v = v + 0.07 break end
					end
				elseif card:isKindOf("ThunderSlash") then
					for _, enemy in ipairs(self.enemies) do
						if enemy:getMark("@fog") > 0 then v = v + 0.06 break end
					end
				end
			else v = v - 0.05
			end
		end
		if self.player:hasSkill("heg_jiang") and card:isRed() then v = v + 0.21 end
		if self.slashAvail == 1 then
			v = v + math.min(sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget, self.player, card) * 0.1, 0.5)
			v = v + math.min(sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, card) * 0.05, 0.5)
		end
	end

	if card:isKindOf("HHalberdCard") then v = v + 1 end

	if self.player:getPile("wooden_ox"):contains(card:getEffectiveId()) then
		v = v + 0.1
	end

	local suits_value = {}
	for index, suit in ipairs(suits) do
		suits_value[suit] = -index
	end
	v = v + (suits_value[card:getSuitString()] or 0) / 1000
	v = v + (13 - card:getNumber()) / 10000
	return v
end

function SmartAI:getDynamicUsePriority(card)
	if not card then return 0 end
	if card:hasFlag("AIGlobal_KillOff") then return 15 end

	if card:isKindOf("Slash") then
		for _, p in ipairs(self.friends) do
			if p:hasShownSkill("heg_yongjue") and self.player:isFriendWith(p) then return 12 end
		end
	elseif card:isKindOf("AmazingGrace") then
		local heg_zhugeliang = sgs.findPlayerByShownSkillName("heg_kongcheng")
		if heg_zhugeliang and self:isEnemy(heg_zhugeliang) and heg_zhugeliang:isKongcheng() then
			return math.max(sgs.ai_use_priority.Slash, sgs.ai_use_priority.Duel) + 0.1
		end
	elseif card:isKindOf("Peach") and self.player:hasSkill("tenyearkuanggu") then return 1.01
	elseif card:isKindOf("DelayedTrick") and #card:getSkillName() > 0 then
		return (sgs.ai_use_priority[card:getClassName()] or 0.01) - 0.01
	elseif card:isKindOf("Duel") then
		if self:hasCrossbowEffect()
			or self.player:canSlashWithoutCrossbow()
			or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.cloneCard("slash")) > 0
			or self.player:hasUsed("HFenxunCard") then
			return sgs.ai_use_priority.Slash - 0.1
		end
	elseif card:isKindOf("AwaitExhausted") and self.player:hasSkills("heg_guose|heg_duanliang") then
		return 0
	end

	local value = self:getUsePriority(card) or 0
	if card:getTypeId() == sgs.Card_TypeEquip then
		if self.player:hasSkills("heg_xiaoji+qixi") and self:getSameEquip(card) then return 3 end
		if self.player:hasSkills(sgs.lose_equip_skill) then value = value + 12 end
		if card:isKindOf("Weapon") and self.player:getPhase() == sgs.Player_Play and #self.enemies > 0 then
			self:sort(self.enemies)
			local enemy = self.enemies[1]
			local v, inAttackRange = self:evaluateWeapon(card, self.player, enemy) / 20
			value = value + string.format("%3.2f", v)
			if inAttackRange then value = value + 0.5 end
		end
	end

	if card:isKindOf("AmazingGrace") then
		local dynamic_value = 10
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			dynamic_value = dynamic_value - 1
			if self:isEnemy(player) then dynamic_value = dynamic_value - ((player:getHandcardNum() + player:getHp()) / player:getHp()) * dynamic_value
			else dynamic_value = dynamic_value + ((player:getHandcardNum() + player:getHp()) / player:getHp()) * dynamic_value
			end
		end
		value = value + dynamic_value
	elseif card:isKindOf("ArcheryAttack") and self.player:hasSkill("heg_luanji") then
		value = value + 5.5
	elseif card:isKindOf("Duel") and self.player:hasSkill("shuangxiong") then
		value = value + 6.3
	elseif card:isKindOf("HWendaoCard") and sgs.originalHegemonyHasShownSkills(self.player, "heg_wendao+heg_hongfa") and not self.player:getPile("heavenly_army"):isEmpty()
		and self.player:getArmor() and self.player:getArmor():objectName() == "PeaceSpell" then
		value = value + 8
	end

	return value
end

function SmartAI:cardNeed(card)
	if not self.friends then self.room:writeToConsole(debug.traceback()) self.room:writeToConsole(sgs.turncount) return end
	local class_name = card:getClassName()
	local suit_string = card:getSuitString()
	local value
	if card:isKindOf("Peach") then
		self:sort(self.friends,"hp")
		if self.friends[1]:getHp() < 2 then return 10 end
		if (self.player:getHp() < 3 or self.player:getLostHp() > 1 and not self.player:hasSkill("heg_buqu")) or self.player:hasSkills("heg_kurou|heg_benghuai") then return 14 end
		return self:getUseValue(card)
	end
	if self:isWeak() and card:isKindOf("Jink") and self:getCardsNum("Jink") < 1 then return 12 end

	local i = 0
	for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
		if sgs[askill:objectName() .. "_keep_value"] then
			local v = sgs[askill:objectName() .. "_keep_value"][class_name]
			if v then
				i = i + 1
				if value then value = value + v else value = v end
			end
		end
	end
	if value then return value / i + 4 end
	i = 0
	for _, askill in sgs.qlist(self.player:getVisibleSkillList(true)) do
		if sgs[askill:objectName() .. "_suit_value"] then
			local v = sgs[askill:objectName() .. "_suit_value"][suit_string]
			if v then
				i = i + 1
				if value then value = value + v else value = v end
			end
		end
	end
	if value then return value / i + 4 end

	if card:isKindOf("Slash") then
		if self:getCardsNum("Slash") == 0 then return 5.9
		else return 4 end
	end
	if card:isKindOf("Analeptic") then
		if self.player:getHp() < 2 then return 10 end
	end
	if card:isKindOf("Crossbow") and self.player:hasSkills("heg_luoshen|heg_kurou|heg_keji|tenyearwusheng") then return 20 end
	if card:isKindOf("Axe") and self.player:hasSkill("heg_luoyi") then return 15 end
	if card:isKindOf("Weapon") and (not self.player:getWeapon()) and (self:getCardsNum("Slash") > 1) then return 6 end
	if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
		if self:willSkipPlayPhase() or self:willSkipDrawPhase() then return 10 end
		for _, friend in ipairs(self.friends) do
			if self:willSkipPlayPhase(friend) or self:willSkipDrawPhase(friend) then return 9 end
		end
		return 6
	end
	if card:getTypeId() == sgs.Card_TypeTrick then
		return card:isAvailable(self.player) and self:getUseValue(card) or 0
	end
	return self:getUseValue(card)
end

function SmartAI:sortByKeepValue(cards, inverse, kept)
	local compare_func = function(a, b)
		local v1 = self:getKeepValue(a)
		local v2 = self:getKeepValue(b)

		if v1 ~= v2 then
			if inverse then return v1 > v2 end
			return v1 < v2
		else
			if not inverse then return a:getNumber() > b:getNumber() end
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByUseValue(cards, inverse)
	local compare_func = function(a, b)
		local value1 = self:getUseValue(a)
		local value2 = self:getUseValue(b)

		if value1 ~= value2 then
			if not inverse then return value1 > value2 end
			return value1 < value2
		else
			if not inverse then return a:getNumber() > b:getNumber() end
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByUsePriority(cards)
	local compare_func = function(a, b)
		local value1 = self:getUsePriority(a)
		local value2 = self:getUsePriority(b)

		if value1 ~= value2 then
			return value1 > value2
		else
			return a:getNumber() > b:getNumber()
		end
	end
	table.sort(cards, compare_func)
end

function SmartAI:sortByDynamicUsePriority(cards)
	local compare_func = function(a,b)
		local value1 = self:getDynamicUsePriority(a)
		local value2 = self:getDynamicUsePriority(b)

		if value1 ~= value2 then
			return value1 > value2
		else
			return a and a:getTypeId() ~= sgs.Card_TypeSkill and not (b and b:getTypeId() ~= sgs.Card_TypeSkill)
		end
	end

	table.sort(cards, compare_func)
end

function SmartAI:sortByCardNeed(cards, inverse)
	local compare_func = function(a,b)
		local value1 = self:cardNeed(a)
		local value2 = self:cardNeed(b)

		if value1 ~= value2 then
			if inverse then return value1 > value2 end
			return value1 < value2
		else
			if not inverse then return a:getNumber() > b:getNumber() end
			return a:getNumber() < b:getNumber()
		end
	end

	table.sort(cards, compare_func)
end

function sgs.findIntersectionSkills(first, second)
	if type(first) == "string" then first = first:split("|") end
	if type(second) == "string" then second = second:split("|") end

	local findings = {}
	for _, skill in ipairs(first) do
		for _, compare_skill in ipairs(second) do
			if skill == compare_skill and not table.contains(findings, skill) then table.insert(findings, skill) end
		end
	end
	return findings
end

function sgs.findUnionSkills(first, second)
	if type(first) == "string" then first = first:split("|") end
	if type(second) == "string" then second = second:split("|") end

	local findings = table.copyFrom(first)
	for _, skill in ipairs(second) do
		if not table.contains(findings, skill) then table.insert(findings, skill) end
	end

	return findings
end


function sgs.updateIntentions(from, tos, intention, card)
	for _, to in ipairs(tos) do
		sgs.updateIntention(from, to, intention, card)
	end
end



function SmartAI:getFriendsNoself(player)
	player = player or self.player
	local friends_noself = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(p, player) and p:objectName() ~= player:objectName() then table.insert(friends_noself, p) end
	end
	return friends_noself
end



-- compare functions
sgs.ai_compare_funcs = {
	value = function(a, b)
		return sgs.getValue(a) < sgs.getValue(b)
	end,

}

function SmartAI:sort(players, key)
	if type(players) ~= "table" then self.room:writeToConsole(debug.traceback()) end
	if #players == 0 then return end
	local func
	if not key or key == "defense" or key == "defenseSlash" then
		func = function(a, b)
			local c1 = sgs.getDefenseSlash(a, self)
			local c2 = sgs.getDefenseSlash(b, self)
			if c1 == c2 then
				return sgs.getDefense(a) < sgs.getDefense(b)
			else
				return c1 < c2
			end
		end
	elseif key == "hp" then
		func = function(a, b)
			local c1 = a:getHp()
			local c2 = b:getHp()
			if c1 == c2 then
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				return c1 < c2
			end
		end
	elseif key == "handcard" then
		func = function(a, b)
			local c1 = a:getHandcardNum()
			local c2 = b:getHandcardNum()
			if c1 == c2 then
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				return c1 < c2
			end
		end
	elseif key == "handcard_defense" then
		func = function(a, b)
			local c1 = a:getHandcardNum()
			local c2 = b:getHandcardNum()
			if c1 == c2 then
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				return c1 < c2
			end
		end
	elseif key == "equip_defense" then
		func = function(a, b)
			local c1 = a:getCards("e"):length()
			local c2 = b:getCards("e"):length()
			if c1 == c2 then
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				return c1 < c2
			end
		end
	elseif key == "chaofeng" then
		func = function(a, b)
			local c1 = sgs.getDefense(a)
			local c2 = sgs.getDefense(b)
			if c1 == c2 then
				return sgs.getDefenseSlash(a, self) < sgs.getDefenseSlash(b, self)
			else
				return c1 < c2
			end
		end
	else
		func = sgs.ai_compare_funcs[key]
	end

	if not func then self.room:writeToConsole(debug.traceback()) return end

	function _sort(players)
		table.sort(players, func)
	end
	if not pcall(_sort, players) then self.room:writeToConsole(debug.traceback()) end
end


function findPlayerByObjectName(name, include_death, except)
	local players = nil
	if include_death then
		players = global_room:getPlayers()
	else
		players = global_room:getAllPlayers()
	end
	if except then
		players:removeOne(except)
	end
	for _,p in sgs.qlist(players) do
		if p:objectName() == name then
			return p
		end
	end
end

function getTrickIntention(trick_class, target)
	local intention = sgs.ai_card_intention[trick_class]
	if type(intention) == "number" then
		return intention
	elseif type(intention == "function") then
		if trick_class == "IronChain" then
			if target and target:isChained() then return -60 else return 60 end
		end
	end
	if trick_class == "Collateral" then return 0 end
	if trick_class == "AwaitExhausted" then return -10 end
	if trick_class == "BefriendAttacking" then return -10 end
	if sgs.dynamic_value.damage_card[trick_class] then
		return 70
	end
	if sgs.dynamic_value.benefit[trick_class] then
		return -40
	end
	if target then
		if trick_class == "Snatch" or trick_class == "Dismantlement" then
			local judgelist = target:getCards("j")
			if not judgelist or judgelist:isEmpty() then
				if not target:hasArmorEffect("SilverLion") or not target:isWounded() then
					return 80
				end
			end
		end
	end
	return 0
end


sgs.ai_choicemade_filter.Nullification = function(self, player, promptlist)
	local trick_class = promptlist[2]
	local target_objectName = promptlist[3]
	if string.find(trick_class, "Nullification") then
		if not sgs.nullification_source or not sgs.nullification_intention or type(sgs.nullification_intention) ~= "number" then
			self.room:writeToConsole(debug.traceback())
			return
		end
		sgs.nullification_level = sgs.nullification_level + 1
		if sgs.nullification_level % 2 == 0 then
			sgs.updateIntention(player, sgs.nullification_source, sgs.nullification_intention)
		elseif sgs.nullification_level % 2 == 1 then
			sgs.updateIntention(player, sgs.nullification_source, -sgs.nullification_intention)
		end
	else
		sgs.nullification_source = findPlayerByObjectName(target_objectName)
		sgs.nullification_level = 1
		sgs.nullification_intention = getTrickIntention(trick_class, sgs.nullification_source)
		if player:objectName() ~= target_objectName then
			sgs.updateIntention(player, sgs.nullification_source, -sgs.nullification_intention)
		end
	end
end

local current_player_chosen = sgs.ai_choicemade_filter.playerChosen
sgs.ai_choicemade_filter.playerChosen = function(self, from, promptlist)
	-- The current protocol also carries multiple recipients in one ChoiceMade.
	if string.find(promptlist[3], "+", 1, true) then
		return current_player_chosen(self, from, promptlist)
	end
	if from:objectName() == promptlist[3] then return end
	local reason = string.gsub(promptlist[2], "%-", "_")
	local to = findPlayerByObjectName(promptlist[3])
	local callback = sgs.ai_playerchosen_intention[reason]
	if callback then
		if type(callback) == "number" then
			sgs.updateIntention(from, to, sgs.ai_playerchosen_intention[reason])
		elseif type(callback) == "function" then
			callback(self, from, to)
		end
	end
end

sgs.ai_choicemade_filter.viewCards = function(self, from, promptlist)
	local to = findPlayerByObjectName(promptlist[2])
	if to and not to:isKongcheng() then
		local flag = string.format("%s_%s_%s", "visible", from:objectName(), to:objectName())
		for _, card in sgs.qlist(to:getHandcards()) do
			if not card:hasFlag("visible") then self.room:setCardFlag(card, flag) end
		end
	end
end

sgs.ai_choicemade_filter.guanxingViewCards = function(self, from, promptlist)
	local player = promptlist[2]
	local ids = promptlist[#promptlist]:split("+")
	local count = self.room:getTag("SwapPile"):toInt()
	if not sgs.ai_guangxing[player][count] then
		sgs.ai_guangxing[player][count] = {}
	end
	for _, id in ipairs(ids) do
		if string.len(id) == 0 then continue end
		if not table.contains(sgs.ai_guangxing[player][count], id) then
			table.insert(sgs.ai_guangxing[player][count], id)
		end
	end
end

sgs.ai_choicemade_filter.Yiji = function(self, from, promptlist)
	-- Current Room sends Yiji:reason:recipient:ids; the giver is the event player.
	local to = findPlayerByObjectName(promptlist[3])
	if not from or not to then return end
	local reason = promptlist[2]
	local cards = {}
	local card_ids = promptlist[4]:split("+")
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(tonumber(id))
		self.room:setCardFlag(card, "visible_" .. from:objectName() .. "_" .. to:objectName())
		table.insert(cards, card)
	end
	if from and to then
		local callback = sgs.ai_Yiji_intention[reason]
		if callback then
			if type(callback) == "number" and not (self:needKongcheng(to, true) and #cards == 1) then
				sgs.updateIntention(from, to, sgs.ai_Yiji_intention[reason])
			elseif type(callback) == "function" then
				callback(self, from, to, cards)
			end
		elseif not (self:needKongcheng(to, true) and #cards == 1) then
			sgs.updateIntention(from, to, -10)
		end
	end
end


function SmartAI:askForSuit(reason)
	if not reason then return sgs.ai_skill_suit.heg_fanjian(self) end -- this line is kept for back-compatibility
	local callback = sgs.ai_skill_suit[reason]
	if type(callback) == "function" then
		if callback(self) then return callback(self) end
	end
	return math.random(0, 3)
end

function SmartAI:askForSkillInvoke(skill_name, data)
	skill_name = string.gsub(skill_name, "%-", "_")
	local invoke = sgs.ai_skill_invoke[skill_name]
	if type(invoke) == "boolean" then
		return invoke
	elseif type(invoke) == "function" then
		if invoke(self, data) == true then
			return true
		else
			return false
		end
	else
		local skill = sgs.Sanguosha:getSkill(skill_name)
		if skill and skill:getFrequency() == sgs.Skill_Frequent then
			return true
		end
	end
	return nil
end

function SmartAI:askForChoice(skill_name, choices, data)
	local choice = sgs.ai_skill_choice[skill_name]
	if type(choice) == "string" then
		return choice
	elseif type(choice) == "function" then
		return choice(self, choices, data)
	else
		local choice_table = choices:split("+")
		for index, achoice in ipairs(choice_table) do
			if achoice == "heg_benghuai" then table.remove(choice_table, index) break end
		end
		local r = math.random(1, #choice_table)
		return choice_table[r]
	end
end

function SmartAI:askForDiscard(reason, discard_num, min_num, optional, include_equip)
	min_num = min_num or discard_num
	local exchange = self.player:hasFlag("Global_AIDiscardExchanging")
	local callback = sgs.ai_skill_discard[reason]
	self:assignKeep(true)
	if type(callback) == "function" then
		local cb = callback(self, discard_num, min_num, optional, include_equip)
		if cb then
			if type(cb) == "number" and not self.player:isJilei(sgs.Sanguosha:getCard(cb)) then return { cb }
			elseif type(cb) == "table" then
				for _, card_id in ipairs(cb) do
					if not exchange and self.player:isJilei(sgs.Sanguosha:getCard(card_id)) then
						return {}
					end
				end
				return cb
			end
			return {}
		end
	elseif optional then
		return min_num == 1 and self:needToThrowArmor() and self.player:getArmor():getEffectiveId() or {}
	end

	local flag = "h"
	if include_equip and (self.player:getEquips():isEmpty() or not self.player:isJilei(self.player:getEquips():first())) then flag = flag .. "e" end
	local cards = self.player:getCards(flag)
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_discard = {}

	local least = min_num
	if discard_num - min_num > 1 then
		least = discard_num - 1
	end
	local temp, discardEquip = {}
	for _, card in ipairs(cards) do
		if exchange or not self.player:isJilei(card) then
			place = self.room:getCardPlace(card:getEffectiveId())
			if discardEquip and place == sgs.Player_PlaceEquip then
				table.insert(temp, card:getEffectiveId())
			elseif self:getKeepValue(card) >= 4.1 then
				table.insert(temp, card:getEffectiveId())
			else
				table.insert(to_discard, card:getEffectiveId())
			end
			if self.player:hasSkills(sgs.lose_equip_skill) and place == sgs.Player_PlaceEquip then discardEquip = true end
		end
		if #to_discard >= discard_num then break end
	end
	if #to_discard < discard_num then
		for _, id in ipairs(temp) do
			table.insert(to_discard, id)
			if #to_discard >= discard_num then break end
		end
	end

	return to_discard
end

sgs.ai_skill_discard.gamerule = function(self, discard_num)

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	local to_discard = {}
	for _, card in ipairs(cards) do
		if not self.player:isCardLimited(card, sgs.Card_MethodDiscard, true) then
			table.insert(to_discard, card:getId())
		end
		if #to_discard >= discard_num or self.player:isKongcheng() then break end
	end

	return to_discard
end


function SmartAI:askForNullification(trick, from, to, positive)
	if self.player:isDead() then return nil end
	local null_card = self:getCardId("Nullification")
	local null_num = self:getCardsNum("Nullification")
	if null_card then null_card = sgs.Card_Parse(null_card) else return nil end
	assert(null_card)
	if self.player:isLocked(null_card) then return nil end
	if (from and from:isDead()) or (to and to:isDead()) then return nil end

	local jgyueying = sgs.findPlayerByShownSkillName("jgjingmiao")
	if jgyueying and self:isEnemy(jgyueying) and self.player:getHp() == 1 then return nil end

	if trick:isKindOf("FireAttack") then
		if to:isKongcheng() or from:isKongcheng() then return nil end
		if self.player:objectName() == from:objectName() and self.player:getHandcardNum() == 1 and self.player:handCards():first() == null_card:getId() then return nil end
	end

	if ("snatch|dismantlement"):match(trick:objectName()) and to:isAllNude() then return nil end

	if from then
		if (trick:isKindOf("Duel") or trick:isKindOf("FireAttack") or trick:isKindOf("AOE")) and self:getDamagedEffects(to, from) and self:isFriend(to) then
			return nil
		end
		if (trick:isKindOf("Duel") or trick:isKindOf("AOE")) and not self:damageIsEffective(to, sgs.DamageStruct_Normal) then return nil end
		if trick:isKindOf("FireAttack") and not self:damageIsEffective(to, sgs.DamageStruct_Fire) then return nil end
	end
	if (trick:isKindOf("Duel") or trick:isKindOf("FireAttack") or trick:isKindOf("AOE")) and self:needToLoseHp(to, from) and self:isFriend(to) then
		return nil
	end

	local callback = sgs.ai_nullification[trick:getClassName()]
	if type(callback) == "function" then
		local shouldUse = callback(self, trick, from, to, positive)
		return shouldUse and null_card
	end

	if positive then

		if from and (trick:isKindOf("FireAttack") or trick:isKindOf("Duel") or trick:isKindOf("ArcheryAttack") or trick:isKindOf("SavageAssault")) and self:cantbeHurt(to, from) then
			if self:isFriend(from) then return null_card end
			return
		end

		local isEnemyFrom = from and self:isEnemy(from)

		if isEnemyFrom and self.player:hasSkill("heg_kongcheng") and self.player:getHandcardNum() == 1 and self.player:isLastHandCard(null_card) and trick:isKindOf("SingleTargetTrick") then
			return null_card
		elseif trick:isKindOf("ExNihilo") then
			if isEnemyFrom and self:evaluateKingdom(from) ~= "unknown" and (self:isWeak(from) or sgs.originalHegemonyHasShownSkills(from, sgs.cardneed_skill)) then
				return null_card
			end
		elseif trick:isKindOf("Snatch") then
			if (to:containsTrick("indulgence") or to:containsTrick("supply_shortage")) and self:isFriend(to) and to:isNude() then return nil end
			if isEnemyFrom and self:isFriend(to, from) and to:getCards("j"):length() > 0 then
				return null_card
			elseif from and self:isFriend(from) and self:isFriend(to) and self:askForCardChosen(to, "ej", "dummyreason") then return false
			elseif self:isFriend(to) then return null_card
			end
		elseif trick:isKindOf("Dismantlement") then
			if (to:containsTrick("indulgence") or to:containsTrick("supply_shortage")) and self:isFriend(to) and to:isNude() then return nil end
			if isEnemyFrom and self:isFriend(to, from) and to:getCards("j"):length() > 0 then
				return null_card
			end
			if from and self:isFriend(from) and self:isFriend(to) and self:askForCardChosen(to, "ej", "dummyreason") then return false end
			if self:isFriend(to) then
				if self:getDangerousCard(to) or self:getValuableCard(to) then return null_card end
				if to:getHandcardNum() == 1 and not self:needKongcheng(to) then
					if (getKnownCard(to, self.player, "TrickCard", false) == 1 or getKnownCard(to, self.player, "EquipCard", false) == 1 or getKnownCard(to, self.player, "Slash", false) == 1) then
						return nil
					end
					return null_card
				end
			end
		elseif trick:isKindOf("IronChain") then
			if isEnemyFrom and self:isFriend(to) then return to:hasArmorEffect("Vine") and null_card end
		elseif trick:isKindOf("Duel") then
			if trick:getSkillName() == "lijian" then
				if self:isFriend(to) and (self:isWeak(to) or null_num > 1 or self:getOverflow() or not self:isWeak()) then return null_card end
				return
			end
			if isEnemyFrom and self:isFriend(to) then
				if self:isWeak(to) then return null_card
				elseif self.player:objectName() == to:objectName() then
					if self:getCardsNum("Slash") > getCardsNum("Slash", from, self.player) then return
					elseif self.player:hasSkills(sgs.masochism_skill) and
						(self.player:getHp() > 1 or self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
						return nil
					elseif self:getCardsNum("Slash") == 0 then
						return null_card
					end
				end
			end
		elseif trick:isKindOf("FireAttack") then
			if to:isChained() then return not self:isGoodChainTarget(to, from, nil, nil, trick) and null_card end
			if isEnemyFrom and self:isFriend(to) then
				if from:getHandcardNum() > 2 or self:isWeak(to) or to:hasArmorEffect("Vine") or to:getMark("@gale") > 0 then
					return null_card
				end
			end
		elseif trick:isKindOf("Indulgence") then
			if self:isFriend(to) and not to:isSkipped(sgs.Player_Play) then
				if (to:hasShownSkill("guanxing") or to:hasShownSkill("heg_yizhi") and to:inDeputySkills("heg_yizhi"))
					and (global_room:alivePlayerCount() > 4 or to:hasShownSkill("heg_yizhi")) then return end
				if to:getHp() - to:getHandcardNum() >= 2 then return nil end
				if to:hasShownSkill("tenyeartuxi") and to:getHp() > 2 then return nil end
				if to:hasShownSkill("qiaobian") and not to:isKongcheng() then return nil end
				if to:containsTrick("supply_shortage") and null_num == 1 and to:getOverflow() > 1 then return nil end
				return null_card
			end
		elseif trick:isKindOf("SupplyShortage") then
			if self:isFriend(to) and not to:isSkipped(sgs.Player_Draw) then
				if (to:hasShownSkill("guanxing") or to:hasShownSkill("heg_yizhi") and to:inDeputySkills("heg_yizhi"))
					and (global_room:alivePlayerCount() > 4 or to:hasShownSkill("heg_yizhi")) then return end
				if sgs.originalHegemonyHasShownSkills(to, "guidao|tiandu") then return nil end
				if to:hasShownSkill("qiaobian") and not to:isKongcheng() then return nil end
				if to:containsTrick("indulgence") and null_num == 1 and to:getOverflow() < -1 then return nil end
				return null_card
			end

		elseif trick:isKindOf("ArcheryAttack") then
			if self:isFriend(to) then
				local heg_null_card = self:getCardId("HegNullification")
				if heg_null_card then
					for _, friend in ipairs(self.friends) do
						if self:playerGetRound(to) < self:playerGetRound(friend) and (self:aoeIsEffective(trick, to, from) or self:getDamagedEffects(to, from)) then
						else
							return heg_null_card
						end
					end
				end
				if not self:aoeIsEffective(trick, to, from) then return
				elseif self:getDamagedEffects(to, from) then return
				elseif to:objectName() == self.player:objectName() and self:canAvoidAOE(trick) then return
				elseif getKnownCard(to, self.player, "Jink", true, "he") >= 1 and to:getHp() > 1 then return
				elseif not self:isFriendWith(to) and self:playerGetRound(to) < self:playerGetRound(self.player) and self:isWeak() then return
				else
					return null_card
				end
			end
		elseif trick:isKindOf("SavageAssault") then
			if self:isFriend(to) then
				local heg_menghuo
				for _, p in sgs.qlist(self.room:getAlivePlayers()) do
					if p:hasShownSkill("heg_huoshou") then heg_menghuo = p break end
				end
				local heg_null_card = self:getCardId("HegNullification")
				if heg_null_card then
					for _, friend in ipairs(self.friends) do
						if self:playerGetRound(to) < self:playerGetRound(friend)
							and (self:aoeIsEffective(trick, to, heg_menghuo or from) or self:getDamagedEffects(to, heg_menghuo or from)) then
						else
							return heg_null_card
						end
					end
				end
				if not self:aoeIsEffective(trick, to, heg_menghuo or from) then return
				elseif self:getDamagedEffects(to, heg_menghuo or from) then return
				elseif to:objectName() == self.player:objectName() and self:canAvoidAOE(trick) then return
				elseif getKnownCard(to, self.player, "Slash", true, "he") >= 1 and to:getHp() > 1 then return
				elseif not self:isFriendWith(to) and self:playerGetRound(to) < self:playerGetRound(self.player) and self:isWeak() then return
				else
					return null_card
				end
			end
		elseif trick:isKindOf("AmazingGrace") then
			if self:isEnemy(to) then
				local NP = to:getNextAlive()
				if self:isFriend(NP) then
					local ag_ids = self.room:getTag("AmazingGrace"):toStringList()
					local peach_num, exnihilo_num, snatch_num, analeptic_num, crossbow_num = 0, 0, 0, 0, 0
					for _, ag_id in ipairs(ag_ids) do
						local ag_card = sgs.Sanguosha:getCard(ag_id)
						if ag_card:isKindOf("Peach") then peach_num = peach_num + 1 end
						if ag_card:isKindOf("ExNihilo") then exnihilo_num = exnihilo_num + 1 end
						if ag_card:isKindOf("Snatch") then snatch_num = snatch_num + 1 end
						if ag_card:isKindOf("Analeptic") then analeptic_num = analeptic_num + 1 end
						if ag_card:isKindOf("Crossbow") then crossbow_num = crossbow_num + 1 end
					end
					if (peach_num == 1) or (peach_num > 0 and (self:isWeak(to) or self:getOverflow(NP) < 1)) then
						return null_card
					end
					if peach_num == 0 and not self:willSkipPlayPhase(NP) then
						if exnihilo_num > 0 then
							if sgs.originalHegemonyHasShownSkills(NP, "heg_jizhi|rende|heg_zhiheng") then return null_card end
						else
							for _, enemy in ipairs(self.enemies) do
								if snatch_num > 0 and to:distanceTo(enemy) == 1 and
									(self:willSkipPlayPhase(enemy, true) or self:willSkipDrawPhase(enemy, true)) then
									return null_card
								elseif analeptic_num > 0 and (enemy:hasWeapon("Axe") or getCardsNum("Axe", enemy, self.player) > 0) then
									return null_card
								elseif crossbow_num > 0 and getCardsNum("Slash", enemy, self.player) >= 3 then
									local slash = sgs.cloneCard("slash")
									for _, friend in ipairs(self.friends) do
										if enemy:distanceTo(friend) == 1 and self:slashIsEffective(slash, friend, enemy) then
											return null_card
										end
									end
								end
							end
						end
					end
				end
			end
		elseif trick:isKindOf("GodSalvation") then
			if self:isEnemy(to) and self:evaluateKingdom(to) ~= "unknown" and self:isWeak(to) then return null_card end
		end

	else

		if from and from:objectName() == self.player:objectName() then return end

		if (trick:isKindOf("FireAttack") or trick:isKindOf("Duel") or trick:isKindOf("AOE")) and self:cantbeHurt(to, from) then
			if isEnemyFrom then return null_card end
		end
		if from and from:objectName() == to:objectName() then
			if self:isFriend(from) then return null_card else return end
		end

		if trick:isKindOf("Duel") then
			if trick:getSkillName() == "lijian" then
				if self:isEnemy(to) and (self:isWeak(to) or null_num > 1 or self:getOverflow() > 0 or not self:isWeak()) then return null_card end
				return
			end
			return from and self:isFriend(from) and not self:isFriend(to) and null_card
		elseif trick:isKindOf("GodSalvation") then
			if self:isFriend(to) and self:isWeak(to) then return null_card end
		elseif trick:isKindOf("AmazingGrace") then
			if self:isFriend(to) then return null_card end
		elseif not (trick:isKindOf("GlobalEffect") or trick:isKindOf("AOE")) then
			if from and self:isFriend(from) and not self:isFriend(to) then
				if ("snatch|dismantlement"):match(trick:objectName()) and to:isNude() then
				elseif trick:isKindOf("FireAttack") and to:isKongcheng() then
				else return null_card end
			end
		end
	end
	return
end

function SmartAI:getCardRandomly(who, flags)
	local cards = who:getCards(flags)
	if cards:isEmpty() then return end
	local r = math.random(0, cards:length() - 1)
	local card = cards:at(r)
	if who:hasArmorEffect("SilverLion") then
		if self:isEnemy(who) and who:isWounded() and card == who:getArmor() then
			if r ~= (cards:length() - 1) then
				card = cards:at(r + 1)
			elseif r > 0 then
				card = cards:at(r - 1)
			end
		end
	end
	return card:getEffectiveId()
end

function SmartAI:askForCardChosen(who, flags, reason, method)
	local isDiscard = (method == sgs.Card_MethodDiscard)
	local cardchosen = sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")]
	local card
	if type(cardchosen) == "function" then
		card = cardchosen(self, who, flags, method)
		if type(card) == "number" then return card
		elseif card then return card:getEffectiveId() end
	elseif type(cardchosen) == "number" then
		sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")] = nil
		for _, acard in sgs.qlist(who:getCards(flags)) do
			if acard:getEffectiveId() == cardchosen then return cardchosen end
		end
	end

	if ("snatch|dismantlement"):match(reason) then
		local flag = "AIGlobal_SDCardChosen_" .. reason
		local to_choose
		for _, card in sgs.qlist(who:getCards(flags)) do
			if card:hasFlag(flag) then
				card:setFlags("-" .. flag)
				to_choose = card:getId()
				break
			end
		end
		if to_choose then return to_choose end
	end

	if self:isFriend(who) then
		if flags:match("j") and not (who:hasShownSkill("qiaobian") and who:getHandcardNum() > 0) then
			local tricks = who:getCards("j")
			local lightning, indulgence, supply_shortage
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") and (not isDiscard or self.player:canDiscard(who, trick:getId())) then
					lightning = trick:getId()
				elseif trick:isKindOf("Indulgence") and (not isDiscard or self.player:canDiscard(who, trick:getId()))  then
					indulgence = trick:getId()
				elseif not trick:isKindOf("Disaster") and (not isDiscard or self.player:canDiscard(who, trick:getId())) then
					supply_shortage = trick:getId()
				end
			end

			if self:hasWizard(self.enemies) and lightning then
				return lightning
			end

			if indulgence and supply_shortage then
				if who:getHp() < who:getHandcardNum() then
					return indulgence
				else
					return supply_shortage
				end
			end

			if indulgence or supply_shortage then
				return indulgence or supply_shortage
			end
		end

		if flags:match("e") then
			if who:getArmor() and self:evaluateArmor(who:getArmor(), who) < -5 and (not isDiscard or self.player:canDiscard(who, who:getArmor():getEffectiveId())) then
				return who:getArmor():getEffectiveId()
			end
			if sgs.originalHegemonyHasShownSkills(who, sgs.lose_equip_skill) and self:isWeak(who) then
				if who:getWeapon() and (not isDiscard or self.player:canDiscard(who, who:getWeapon():getEffectiveId())) then return who:getWeapon():getEffectiveId() end
				if who:getOffensiveHorse() and (not isDiscard or self.player:canDiscard(who, who:getOffensiveHorse():getEffectiveId())) then return who:getOffensiveHorse():getEffectiveId() end
			end
		end
	else
		local dangerous = self:getDangerousCard(who)
		if flags:match("e") and dangerous and (not isDiscard or self.player:canDiscard(who, dangerous)) then return dangerous end
		if flags:match("e") and who:getTreasure() and (who:getPile("wooden_ox"):length() > 1 or who:hasTreasure("JadeSeal")) and (not isDiscard or self.player:canDiscard(who, who:getTreasure():getId())) then
			return who:getTreasure():getId()
		end
		if flags:match("e") and who:hasArmorEffect("EightDiagram") and not self:needToThrowArmor(who) and (not isDiscard or self.player:canDiscard(who, who:getArmor():getId())) then return who:getArmor():getId() end
		if flags:match("e") and sgs.originalHegemonyHasShownSkills(who, "jijiu|beige|heg_weimu|heg_qingcheng") and not self:doNotDiscard(who, "e", false, 1, reason) then
			if who:getDefensiveHorse() and (not isDiscard or self.player:canDiscard(who, who:getDefensiveHorse():getEffectiveId())) then return who:getDefensiveHorse():getEffectiveId() end
			if who:getArmor() and (not isDiscard or self.player:canDiscard(who, who:getArmor():getEffectiveId())) then return who:getArmor():getEffectiveId() end
			if who:getOffensiveHorse() and (not who:hasShownSkill("jijiu") or who:getOffensiveHorse():isRed()) and (not isDiscard or self.player:canDiscard(who, who:getOffensiveHorse():getEffectiveId())) then
				return who:getOffensiveHorse():getEffectiveId()
			end
			if who:getWeapon() and (not who:hasShownSkill("jijiu") or who:getWeapon():isRed()) and (not isDiscard or self.player:canDiscard(who, who:getWeapon():getEffectiveId())) then
				return who:getWeapon():getEffectiveId()
			end
		end
		if flags:match("e") then
			local valuable = self:getValuableCard(who)
			if valuable and (not isDiscard or self.player:canDiscard(who, valuable)) then
				return valuable
			end
		end
		if flags:match("h") and (not isDiscard or self.player:canDiscard(who, "h")) then
			if sgs.originalHegemonyHasShownSkills(who, "jijiu|qingnang|qiaobian|jieyin|beige")
				and not who:isKongcheng() and who:getHandcardNum() <= 2 and not self:doNotDiscard(who, "h", false, 1, reason) then
				return self:getCardRandomly(who, "h")
			end
			if who:getHp() == 1 and not self:needKongcheng(who)
				and not who:isKongcheng() and who:getHandcardNum() <= 2 and not self:doNotDiscard(who, "h", false, 1, reason) then
				return self:getCardRandomly(who, "h")
			end
			local cards = sgs.QList2Table(who:getHandcards())
			if #cards <= 2 and not self:doNotDiscard(who, "h", false, 1, reason) then
				for _, cc in ipairs(cards) do
					if sgs.cardIsVisible(cc, who, self.player) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
						return self:getCardRandomly(who, "h")
					end
				end
			end
		end

		if flags:match("j") then
			local tricks = who:getCards("j")
			local lightning
			for _, trick in sgs.qlist(tricks) do
				if trick:isKindOf("Lightning") and (not isDiscard or self.player:canDiscard(who, trick:getId())) then
					lightning = trick:getId()
				end
			end
			if self:hasWizard(self.enemies, true) and lightning then
				return lightning
			end
		end

		if flags:match("h") and not self:doNotDiscard(who, "h") then
			if (who:getHandcardNum() == 1 and sgs.getDefenseSlash(who, self) < 3 and who:getHp() <= 2) or sgs.originalHegemonyHasShownSkills(who, sgs.cardneed_skill) then
				return self:getCardRandomly(who, "h")
			end
		end

		if flags:match("e") and not self:doNotDiscard(who, "e") then
			if who:getDefensiveHorse() and (not isDiscard or self.player:canDiscard(who, who:getDefensiveHorse():getEffectiveId())) then return who:getDefensiveHorse():getEffectiveId() end
			if who:getArmor() and not self:needToThrowArmor(who) and (not isDiscard or self.player:canDiscard(who, who:getArmor():getEffectiveId())) then return who:getArmor():getEffectiveId() end
			if who:getOffensiveHorse() and (not isDiscard or self.player:canDiscard(who, who:getOffensiveHorse():getEffectiveId())) then return who:getOffensiveHorse():getEffectiveId() end
			if who:getWeapon() and (not isDiscard or self.player:canDiscard(who, who:getWeapon():getEffectiveId())) then return who:getWeapon():getEffectiveId() end
			if who:getTreasure() and (not isDiscard or self.player:canDiscard(who, who:getTreasure():getEffectiveId())) then return who:getTreasure():getEffectiveId() end
		end

		if flags:match("h") then
			if (not who:isKongcheng() and who:getHandcardNum() <= 2) and not self:doNotDiscard(who, "h", false, 1, reason) then
				return self:getCardRandomly(who, "h")
			end
		end
	end
	return -1
end

function sgs.ai_skill_cardask.nullfilter(self, data, pattern, target)
	if self.player:isDead() then return "." end
	local damage_nature = sgs.DamageStruct_Normal
	local effect
	if type(data) == "userdata" then
		effect = data:toSlashEffect()
		if effect and effect.slash then
			damage_nature = effect.nature
		end
	end
	if effect and self:hasHeavySlashDamage(target, effect.slash, self.player) then return end
	if not self:damageIsEffective(nil, damage_nature, target) then return "." end
	if effect and target and target:hasWeapon("IceSword") and self.player:getCards("he"):length() > 1 then return end
	if self:getDamagedEffects(self.player, target) or self:needToLoseHp() then return "." end

	if self.player:hasSkill("heg_tianxiang") then
		local dmgStr = {damage = 1, nature = damage_nature or sgs.DamageStruct_Normal}
		local willTianxiang = sgs.ai_skill_use["@@heg_tianxiang"](self, dmgStr, sgs.Card_MethodDiscard)
		if willTianxiang ~= "." then return "." end
	end
end

function SmartAI:askForCard(pattern, prompt, data)
	local target, target2
	local parsedPrompt = prompt:split(":")
	local players
	if parsedPrompt[2] then
		local players = self.room:getPlayers()
		players = sgs.QList2Table(players)
		for _, player in ipairs(players) do
			if player:getGeneralName() == parsedPrompt[2] or player:objectName() == parsedPrompt[2] then target = player break end
		end
		if parsedPrompt[3] then
			for _, player in ipairs(players) do
				if player:getGeneralName() == parsedPrompt[3] or player:objectName() == parsedPrompt[3] then target2 = player break end
			end
		end
	end
	local arg, arg2 = parsedPrompt[4], parsedPrompt[5]
	local callback = sgs.ai_skill_cardask[parsedPrompt[1]]
	if type(callback) == "function" then
		local ret = callback(self, data, pattern, target, target2, arg, arg2)
		if ret then return ret end
	end

	if data and type(data) == "number" then return end
	local card
	if pattern == "slash" then
		card = sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) or self:getCardId("Slash") or "."
	elseif pattern == "jink" then
		card = sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) or self:getCardId("Jink") or "."
	end
	return card
end

function SmartAI:askForUseCard(pattern, prompt, method)
	local use_func = sgs.ai_skill_use[pattern]
	if use_func then
		return use_func(self, prompt, method) or "."
	else
		return "."
	end
end

function SmartAI:askForAG(card_ids, refusable, reason)
	local cardchosen = sgs.ai_skill_askforag[string.gsub(reason, "%-", "_")]
	if type(cardchosen) == "function" then
		local card_id = cardchosen(self, card_ids)
		if card_id then return card_id end
	end

	local ids = card_ids
	local cards = {}
	for _, id in ipairs(ids) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Peach") then return card:getEffectiveId() end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("Indulgence") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then return card:getEffectiveId() end
		if card:isKindOf("AOE") and not (self:isWeak() and self:getCardsNum("Jink") == 0) then return card:getEffectiveId() end
	end
	self:sortByCardNeed(cards, true)

	return cards[1]:getEffectiveId()
end

function SmartAI:askForCardShow(requestor, reason)
	local func = sgs.ai_cardshow[reason]
	if func then
		return func(self, requestor)
	else
		return self.player:getRandomHandCard()
	end
end

function sgs.ai_cardneed.bignumber(to, card, self)
	if not self:willSkipPlayPhase(to) and self:getUseValue(card) < 6 then
		return card:getNumber() > 10
	end
end

function sgs.ai_cardneed.equip(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:getTypeId() == sgs.Card_TypeEquip
	end
end

function sgs.ai_cardneed.weapon(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:isKindOf("Weapon")
	end
end

function SmartAI:getEnemyNumBySeat(from, to, target, include_neutral)
	target = target or from
	local players = sgs.QList2Table(self.room:getAllPlayers())
	local to_seat = (to:getSeat() - from:getSeat()) % #players
	local enemynum = 0
	for _, p in ipairs(players) do
		if  (self:isEnemy(target, p) or (include_neutral and not self:isFriend(target, p))) and ((p:getSeat() - from:getSeat()) % #players) < to_seat then
			enemynum = enemynum + 1
		end
	end
	return enemynum
end

function SmartAI:getFriendNumBySeat(from, to)
	local players = sgs.QList2Table(self.room:getAllPlayers())
	local to_seat = (to:getSeat() - from:getSeat()) % #players
	local friendnum = 0
	for _, p in ipairs(players) do
		if self:isFriend(from, p) and ((p:getSeat() - from:getSeat()) % #players) < to_seat then
			friendnum = friendnum + 1
		end
	end
	return friendnum
end

function SmartAI:hasHeavySlashDamage(from, slash, to, getValue)
	from = from or self.room:getCurrent()
	if not slash or not slash:isKindOf("Slash") then
		slash = self.player:objectName() == from:objectName() and self:getCard("Slash") or sgs.cloneCard("slash")
	end
	to = to or self.player
	if not from or not to then self.room:writeToConsole(debug.traceback()) return false end
	if to:hasArmorEffect("SilverLion") and not IgnoreArmor(from, to) then
		if getValue then return 1
		else return false end
	end
	local dmg = 1
	local fireSlash = slash and (slash:isKindOf("FireSlash") or slash:objectName() == "slash" and from:hasWeapon("Fan"))
	local thunderSlash = slash and slash:isKindOf("ThunderSlash")

	if (slash and slash:hasFlag("drank")) then
		dmg = dmg + 1
	elseif from:getMark("drank") > 0 then
		dmg = dmg + from:getMark("drank")
	end
	if from:hasFlag("heg_luoyi") then dmg = dmg + 1 end
	if from:hasWeapon("GudingBlade") and slash and to:isKongcheng() then dmg = dmg + 1 end
	if to:getMark("@gale") > 0 and fireSlash then dmg = dmg + 1 end
	local jiaren_zidan = sgs.findPlayerByShownSkillName("jgchiying")
	if jiaren_zidan and jiaren_zidan:isFriendWith(to) then
		dmg = 1
	end
	if to:hasArmorEffect("Vine") and not IgnoreArmor(from, to) and fireSlash then
		dmg = dmg + 1
	end

	if getValue then return dmg end
	return (dmg > 1)
end

function SmartAI:needKongcheng(player, keep)
	player = player or self.player
	if keep then return player:isKongcheng() and player:hasShownSkill("heg_kongcheng") end
	if not self:hasLoseHandcardEffective(player) and not player:isKongcheng() then return true end
	if player:hasShownSkill("heg_hengzheng") and (player == self.player and sgs.ai_skill_invoke.heg_hengzheng(self)) and not player:getHp() == 1 then return true end
	return sgs.originalHegemonyHasShownSkills(player, sgs.need_kongcheng)
end

function SmartAI:getLeastHandcardNum(player)
	player = player or self.player
	local least = 0
	local jwfy = sgs.findPlayerByShownSkillName("heg_shoucheng")
	if least < 1 and jwfy and self:isFriend(jwfy, player) then least = 1 end
	return least
end

function SmartAI:hasLoseHandcardEffective(player)
	player = player or self.player
	return player:getHandcardNum() > self:getLeastHandcardNum(player)
end

function SmartAI:hasCrossbowEffect(player)
	player = player or self.player
	return player:hasWeapon("Crossbow") or player:hasShownSkill("heg_paoxiao")
end

function SmartAI:getCardNeedPlayer(cards, friends_table, skillname)
	cards = cards or sgs.QList2Table(self.player:getHandcards())

	local cardtogivespecial = {}
	local keptslash = 0
	local friends = {}
	local cmpByAction = function(a,b)
		return a:getRoom():getFront(a, b):objectName() == a:objectName()
	end

	local cmpByNumber = function(a,b)
		return a:getNumber() > b:getNumber()
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and (self:needKongcheng(AssistTarget, true) or self:willSkipPlayPhase(AssistTarget) or AssistTarget:getHandcardNum() > 10) then
		AssistTarget = nil
	end

	local found
	local heg_xunyu, heg_huatuo
	local friends_table = friends_table or self.friends_noself
	for i = 1, #friends_table do
		local player = friends_table[i]
		local exclude = self:needKongcheng(player) or self:willSkipPlayPhase(player)
		if sgs.originalHegemonyHasShownSkills(player, "heg_keji|qiaobian|heg_shensu") or player:getHp() - player:getHandcardNum() >= 3
			or (player:isLord() and self:isWeak(player) and self:getEnemyNumBySeat(self.player, player) >= 1) then
			exclude = false
		end
		if self:objectiveLevel(player) <= -2 and not exclude then
			if AssistTarget and AssistTarget:objectName() == player:objectName() then AssistTarget = player end
			if player:hasShownSkill("heg_jieming") then heg_xunyu = player end
			if player:hasShownSkill("jijiu") then heg_huatuo = player end
			table.insert(friends, player)
		end
	end
	if not found then AssistTarget = nil end

	if heg_xunyu and heg_huatuo and #cardtogivespecial == 0 and self.player:hasSkill("rende") and self.player:getPhase() == sgs.Player_Play then
		local no_distance = self.slash_distance_limit
		local redcardnum = 0
		for _, acard in ipairs(cards) do
			if isCard("Slash", acard, self.player) then
				if self.player:canSlash(heg_xunyu, nil, not no_distance) and self:slashIsEffective(acard, heg_xunyu) then
					keptslash = keptslash + 1
				end
				if keptslash > 0 then
					table.insert(cardtogivespecial, acard)
				end
			elseif isCard("Duel", acard, self.player) then
				table.insert(cardtogivespecial, acard)
			end
		end
		for _, hcard in ipairs(cardtogivespecial) do
			if hcard:isRed() then redcardnum = redcardnum + 1 end
		end
		if self.player:getHandcardNum() > #cardtogivespecial and redcardnum > 0 then
			for _, hcard in ipairs(cardtogivespecial) do
				if hcard:isRed() then return hcard, heg_huatuo end
				return hcard, heg_xunyu
			end
		end
	end

	local cardtogive = {}
	local keptjink = 0
	for _, acard in ipairs(cards) do
		if isCard("Jink", acard, self.player) and keptjink < 1 and not self.player:hasSkill("heg_kongcheng") then
			keptjink = keptjink + 1
		else
			table.insert(cardtogive, acard)
		end
	end

	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
		if self:isWeak(friend) and friend:getHandcardNum() < 3  then
			for _, hcard in ipairs(cards) do
				if isCard("Peach", hcard, friend) or (isCard("Jink", hcard, friend) and self:getEnemyNumBySeat(self.player,friend) > 0) or isCard("Analeptic", hcard, friend) then
					return hcard, friend
				end
			end
		end
	end

	if (skillname == "rende" and self.player:hasSkill("rende") and self.player:isWounded() and self.player:getMark("rende") < 3) and not self.player:hasSkill("heg_kongcheng") then
		if (self.player:getHandcardNum() < 3 and self.player:getMark("rende") == 0 and self:getOverflow() <= 0) then return end
	end

	for _, friend in ipairs(friends) do
		if friend:getHp() <= 2 and friend:faceUp() then
			for _, hcard in ipairs(cards) do
				if (hcard:isKindOf("Armor") and not friend:getArmor() and not sgs.originalHegemonyHasShownSkills(friend, "bazhen|jgyizhong"))
					or (hcard:isKindOf("DefensiveHorse") and not friend:getDefensiveHorse()) then
					return hcard, friend
				end
			end
		end
	end

	self:sortByUseValue(cards, true)
	for _, friend in ipairs(friends) do
		if sgs.originalHegemonyHasShownSkills(friend, "jijiu|jieyin") and friend:getHandcardNum() < 4 then
			for _, hcard in ipairs(cards) do
				if (hcard:isRed() and friend:hasShownSkill("jijiu")) or friend:hasShownSkill("jieyin") then
					return hcard, friend
				end
			end
		end
	end

	for _, friend in ipairs(friends) do
		if sgs.originalHegemonyHasShownSkills(friend, "heg_jizhi")  then
			for _, hcard in ipairs(cards) do
				if hcard:isKindOf("TrickCard") then
					return hcard, friend
				end
			end
		end
	end

	for _, friend in ipairs(friends) do
		if sgs.originalHegemonyHasShownSkills(friend, "heg_paoxiao")  then
			for _, hcard in ipairs(cards) do
				if hcard:isKindOf("Slash") then
					return hcard, friend
				end
			end
		end
	end

	--Crossbow
	for _, friend in ipairs(friends) do
		if sgs.originalHegemonyHasShownSkills(friend, "heg_longdan|tenyearwusheng|heg_keji") and not self:hasCrossbowEffect(friend) and friend:getHandcardNum() >= 2 then
			for _, hcard in ipairs(cards) do
				if hcard:isKindOf("Crossbow") then
					return hcard, friend
				end
			end
		end
	end

	for _, friend in ipairs(friends) do
		if getKnownCard(friend, self.player, "Crossbow") > 0 then
			for _, p in ipairs(self.enemies) do
				if sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) <= 1 then
					for _, hcard in ipairs(cards) do
						if isCard("Slash", hcard, friend) then
							return hcard, friend
						end
					end
				end
			end
		end
	end

	table.sort(friends, cmpByAction)

	for _, friend in ipairs(friends) do
		if friend:faceUp() then
			local can_slash = false
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) <= friend:getAttackRange() then
					can_slash = true
					break
				end
			end
			local flag = string.format("weapon_done_%s_%s",self.player:objectName(),friend:objectName())
			if not can_slash then
				for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
					if self:isEnemy(p) and sgs.isGoodTarget(p, self.enemies, self) and friend:distanceTo(p) > friend:getAttackRange() then
						for _, hcard in ipairs(cardtogive) do
							if hcard:isKindOf("Weapon") and friend:distanceTo(p) <= friend:getAttackRange() + (sgs.weapon_range[hcard:getClassName()] or 0)
									and not friend:getWeapon() and not friend:hasFlag(flag) then
								self.room:setPlayerFlag(friend, flag)
								return hcard, friend
							end
							if hcard:isKindOf("OffensiveHorse") and friend:distanceTo(p) <= friend:getAttackRange() + 1
									and not friend:getOffensiveHorse() and not friend:hasFlag(flag) then
								self.room:setPlayerFlag(friend, flag)
								return hcard, friend
							end
						end
					end
				end
			end

		end
	end

	table.sort(cardtogive, cmpByNumber)

	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend, true) and friend:faceUp() then
			for _, hcard in ipairs(cardtogive) do
				for _, askill in sgs.qlist(friend:getVisibleSkillList(true)) do
					local callback = sgs.ai_cardneed[askill:objectName()]
					if type(callback) == "function" and callback(friend, hcard, self) then
						return hcard, friend
					end
				end
			end
		end
	end

	if skillname ~= "transfer" then
		self:sort(self.enemies, "defense")
		if #self.enemies > 0 and self.enemies[1]:isKongcheng() and self.enemies[1]:hasShownSkill("heg_kongcheng") then
			for _, acard in ipairs(cardtogive) do
				if acard:isKindOf("Lightning") or acard:isKindOf("Collateral") or (acard:isKindOf("Slash") and self.player:getPhase() == sgs.Player_Play)
					or acard:isKindOf("OffensiveHorse") or acard:isKindOf("Weapon") or acard:isKindOf("AmazingGrace") then
					return acard, self.enemies[1]
				end
			end
		end
	end

	if AssistTarget then
		for _, hcard in ipairs(cardtogive) do
			return hcard, AssistTarget
		end
	end

	self:sort(friends, "defense")
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend, true) and not self:willSkipPlayPhase(friend) and sgs.originalHegemonyHasShownSkills(friend, sgs.priority_skill) then
				if (self:getOverflow() > 0 or self.player:getHandcardNum() > 3) and friend:getHandcardNum() <= 3 then
					return hcard, friend
				end
			end
		end
	end

	local shoulduse = skillname == "rende" and self.player:isWounded() and self.player:hasSkill("rende") and self.player:getMark("rende") < 3

	if #cardtogive == 0 and shoulduse then cardtogive = cards end

	self:sort(friends, "handcard")
	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend, true) then
				if friend:getHandcardNum() <= 3 and (self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shoulduse) then
					return hcard, friend
				end
			end
		end
	end


	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend, true) or #friends == 1 then
				if self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shoulduse then
					return hcard, friend
				end
			end
		end
	end

	for _, hcard in ipairs(cardtogive) do
		for _, friend in ipairs(friends_table) do
			if (not self:needKongcheng(friend, true) or #friends_table == 1) and (self:getOverflow() > 0 or self.player:getHandcardNum() > 3 or shoulduse) then
				return hcard, friend
			end
		end
	end

end

function SmartAI:askForYiji(card_ids, reason)
	if reason then
		local callback = sgs.ai_skill_askforyiji[string.gsub(reason,"%-","_")]
		if type(callback) == "function" then
			local target, cardid = callback(self, card_ids)
			if target and cardid then return target, cardid end
		end
	end
	return nil, -1
end

function SmartAI:askForPindian(requestor, reason)
	local passive = { "heg_lieren" }
	if self.player:objectName() == requestor:objectName() and not table.contains(passive, reason) then
		if self[reason .. "_card"] then
			return sgs.Sanguosha:getCard(self[reason .. "_card"])
		else
			self.room:writeToConsole("Pindian card for " .. reason .. " not found!!")
			return self:getMaxCard(self.player):getId()
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local compare_func = function(a, b)
		return a:getNumber() < b:getNumber()
	end
	table.sort(cards, compare_func)
	local maxcard, mincard, minusecard
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < 6 then mincard = card break end
	end
	for _, card in ipairs(sgs.reverse(cards)) do
		if self:getUseValue(card) < 6 then maxcard = card break end
	end
	self:sortByUseValue(cards, true)
	minusecard = cards[1]
	maxcard = maxcard or minusecard
	mincard = mincard or minusecard

	local sameclass, c1 = true
	for _, c2 in ipairs(cards) do
		if not c1 then c1 = c2
		elseif c1:getClassName() ~= c2:getClassName() then sameclass = false end
	end
	if sameclass then
		if self:isFriend(requestor) then return self:getMinCard()
		else return self:getMaxCard() end
	end

	local callback = sgs.ai_skill_pindian[reason]
	if type(callback) == "function" then
		local ret = callback(minusecard, self, requestor, maxcard, mincard)
		if ret then return ret end
	end
	if self:isFriend(requestor) then return mincard else return maxcard end
end

sgs.ai_skill_playerchosen.damage = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	self:sort(targetlist, "hp")
	for _, target in ipairs(targetlist) do
		if self:isEnemy(target) then return target end
	end
	return targetlist[#targetlist]
end

function SmartAI:askForPlayerChosen(targets, reason)
	local playerchosen = sgs.ai_skill_playerchosen[string.gsub(reason, "%-", "_")]
	local target = nil
	if type(playerchosen) == "function" then
		target = playerchosen(self, targets)
		-- Donor playerchosen callbacks can serve either one or several targets.
		if type(target) == "table" then
			for _, candidate in ipairs(target) do
				if targets:contains(candidate) then return candidate end
			end
			return nil
		end
		return target
	end
	local r = math.random(0, targets:length() - 1)
	return targets:at(r)
end

function SmartAI:ableToSave(saver, dying)
	local current = self.room:getCurrent()
	if current and current:getPhase() ~= sgs.Player_NotActive and current:hasShownSkill("wansha")
		and current:objectName() ~= saver:objectName() and current:objectName() ~= dying:objectName() then
		return false
	end
	local peach = sgs.cloneCard("peach", sgs.Card_NoSuitRed, 0)
	if saver:isCardLimited(peach, sgs.Card_MethodUse, true) then return false end
	return true
end

function SmartAI:willUsePeachTo(dying)
	local card_str
	local forbid = sgs.cloneCard("peach")
	if self.player:isLocked(forbid) or dying:isLocked(forbid) then return "." end
	if self.player:objectName() == dying:objectName() then
		local analeptic = sgs.cloneCard("analeptic")
		if not self.player:isLocked(analeptic) and self:getCardId("Analeptic") then return self:getCardId("Analeptic") end
		if self:getCardId("Peach") then return self:getCardId("Peach") end
	end

	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if type(damage) == "userdata" and damage.to and damage.to:objectName() == dying:objectName() and damage.from
		and (damage.from:objectName() == self.player:objectName()
			or self.player:isFriendWith(damage.from)
			or self:evaluateKingdom(damage.from) == self:originalHegemonyOwnKingdom())
		and (self:originalHegemonyOwnKingdom() ~= sgs.originalHegemonyPublicKingdom(damage.to) or self.role == "careerist") then
		return "."
	end

	if self:isFriend(dying) then
		if not self.player:isFriendWith(dying) and self:isWeak() then return "." end

		if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= sgs.ai_NeedPeach[self.player:objectName()] then return "." end

		if math.ceil(self:getAllPeachNum()) < 1 - dying:getHp() then return "." end

		if dying:objectName() ~= self.player:objectName() then
			local possible_friend = 0
			for _, friend in ipairs(self.friends_noself) do
				if (self:getKnownNum(friend) == friend:getHandcardNum() and getCardsNum("Peach", friend, self.player) == 0)
					or (self:playerGetRound(friend) < self:playerGetRound(self.player)) then
				elseif sgs.card_lack[friend:objectName()]["Peach"] == 1 then
				elseif not self:ableToSave(friend, dying) then
				elseif friend:getHandcardNum() > 0 or getCardsNum("Peach", friend, self.player) > 0 then
					possible_friend = possible_friend + 1
				end
			end
			if possible_friend == 0 and self:getCardsNum("Peach") < 1 - dying:getHp() then
				return "."
			end
		end


		local heg_buqu = dying:getPile("heg_buqu")
		if not heg_buqu:isEmpty() then
			local same = false
			for i, card_id in sgs.qlist(heg_buqu) do
				for j, card_id2 in sgs.qlist(heg_buqu) do
					if i ~= j and sgs.Sanguosha:getCard(card_id):getNumber() == sgs.Sanguosha:getCard(card_id2):getNumber() then
						same = true
						break
					end
				end
			end
			if not same then return "." end
		end
		if dying:hasFlag("Kurou_toDie") and (not dying:getWeapon() or dying:getWeapon():objectName() ~= "Crossbow") then return "." end

		if (self.player:objectName() == dying:objectName()) then
			card_str = self:getCardId("Analeptic")
			if not card_str then card_str = self:getCardId("Peach") end
		elseif self:doNotSave(dying) then return "."
		else card_str = self:getCardId("Peach") end
	end
	if not card_str then return nil end
	return card_str
end

function SmartAI:askForSinglePeach(dying)
	local card_str = self:willUsePeachTo(dying)
	return card_str or "."
end

function SmartAI:getOverflow(player, getMaxCards)
	player = player or self.player
	local MaxCards = player:getMaxCards()
	if player:hasShownSkill("qiaobian") and not player:hasFlag("AI_ConsideringQiaobianSkipDiscard") then
		MaxCards = math.max(self.player:getHandcardNum() - 1, MaxCards)
		player:setFlags("-AI_ConsideringQiaobianSkipDiscard")
	end
	if player:hasShownSkill("heg_keji") and not player:hasFlag("KejiSlashInPlayPhase") then MaxCards = self.player:getHandcardNum() end
	if getMaxCards then return MaxCards end
	return player:getHandcardNum() - MaxCards
end

function SmartAI:isWeak(player)
	player = player or self.player
	if hasBuquEffect(player) then return false end
	if hasNiepanEffect(player) then return false end
	if player:hasShownSkill("heg_kongcheng") and player:isKongcheng() and player:getHp() >= 2 then return false end
	if (player:getHp() <= 2 and player:getHandcardNum() <= 2) or player:getHp() <= 1 then return true end
	return false
end

function SmartAI:useCardByClassName(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	local class_name = card:getClassName()
	local use_func = self["useCard" .. class_name]

	if use_func then
		use_func(self, card, use)
	end
end

function SmartAI:hasWizard(players, onlyharm)
	local skill
	if onlyharm then skill = sgs.wizard_harm_skill else skill = sgs.wizard_skill end
	for _, player in ipairs(players) do
		if sgs.originalHegemonyHasShownSkills(player, skill) then
			return true
		end
	end
end

function SmartAI:canRetrial(player, to_retrial, reason)
	player = player or self.player
	to_retrial = to_retrial or self.player
	if player:hasShownSkill("guidao") then
		local blackequipnum = 0
		for _, equip in sgs.qlist(player:getEquips()) do
			if equip:isBlack() then blackequipnum = blackequipnum + 1 end
		end
		if blackequipnum + player:getHandcardNum() > 0 then return true end
	end
	if player:hasShownSkill("guicai") and player:getHandcardNum() > 0 then return true end
	return
end

function SmartAI:getFinalRetrial(player, reason)
	local maxfriendseat = -1
	local maxenemyseat = -1
	local tmpfriend
	local tmpenemy
	local wizardf, wizarde
	player = player or self.room:getCurrent()
	for _, aplayer in ipairs(self.friends) do
		if sgs.originalHegemonyHasShownSkills(aplayer, sgs.wizard_harm_skill) and self:canRetrial(aplayer, player, reason) then
			tmpfriend = (aplayer:getSeat() - player:getSeat()) % (global_room:alivePlayerCount())
			if tmpfriend > maxfriendseat then
				maxfriendseat = tmpfriend
				wizardf = aplayer
			end
		end
	end
	for _, aplayer in ipairs(self.enemies) do
		if sgs.originalHegemonyHasShownSkills(aplayer, sgs.wizard_harm_skill) and self:canRetrial(aplayer, player, reason) then
			tmpenemy = (aplayer:getSeat() - player:getSeat()) % (global_room:alivePlayerCount())
			if tmpenemy > maxenemyseat then
				maxenemyseat = tmpenemy
				wizarde = aplayer
			end
		end
	end
	if maxfriendseat == -1 and maxenemyseat == -1 then return 0, nil
	elseif maxfriendseat > maxenemyseat then return 1, wizardf
	else return 2, wizarde end
end

--- Determine that the current judge is worthy retrial
-- @param judge The JudgeStruct that contains the judge information
-- @return True if it is needed to retrial
function SmartAI:needRetrial(judge)
	local reason = judge.reason
	local who = judge.who
	if reason == "lightning" then
		if who:hasShownSkill("hongyan") then return false end

		if who:hasArmorEffect("SilverLion") and who:getHp() > 1 then return false end

		if who:hasArmorEffect("PeaceSpell") then return false end

		if self:isFriend(who) then
			if who:isChained() and self:isGoodChainTarget(who, self.player, sgs.DamageStruct_Thunder, 3) then return false end
		else
			if who:isChained() and not self:isGoodChainTarget(who, self.player, sgs.DamageStruct_Thunder, 3) then return judge:isGood() end
		end
	elseif reason == "indulgence" then
		if who:isSkipped(sgs.Player_Draw) and who:isKongcheng() then
			if who:hasShownSkill("heg_kurou") and who:getHp() >= 3 then
				if self:isFriend(who) then
					return not judge:isGood()
				else
					return judge:isGood()
				end
			end
		end
		if self:isFriend(who) then
			local drawcardnum = self:ImitateResult_DrawNCards(who, who:getVisibleSkillList(true))
			if who:getHp() - who:getHandcardNum() >= drawcardnum and self:getOverflow() < 0 then return false end
			if who:hasShownSkill("tenyeartuxi") and who:getHp() > 2 and self:getOverflow() < 0 then return false end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	elseif reason == "supply_shortage" then
		if self:isFriend(who) then
			if sgs.originalHegemonyHasShownSkills(who, "guidao|tiandu") then return false end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	elseif reason == "heg_luoshen" then
		if self:isFriend(who) then
			if who:getHandcardNum() > 30 then return false end
			if self:hasCrossbowEffect(who) or getKnownCard(who, self.player, "Crossbow", false) > 0 then return not judge:isGood() end
			if self:getOverflow(who) > 1 and self.player:getHandcardNum() < 3 then return false end
			return not judge:isGood()
		else
			return judge:isGood()
		end
	elseif reason == "heg_tuntian" then
		if self:isFriend(who) then
			if self.player:objectName() == who:objectName() then
				return not self:isWeak()
			else
				return not judge:isGood()
			end
		else
			return judge:isGood()
		end
	elseif reason == "beige" then
		return true
	end

	if self:isFriend(who) then
		return not judge:isGood()
	elseif self:isEnemy(who) then
		return judge:isGood()
	else
		return false
	end
end

--- Get the retrial cards with the lowest keep value
-- @param cards the table that contains all cards can use in retrial skill
-- @param judge the JudgeStruct that contains the judge information
-- @return the retrial card id or -1 if not found
function SmartAI:getRetrialCardId(cards, judge, self_card)
	if self_card == nil then self_card = true end
	local can_use = {}
	local reason = judge.reason
	local who = judge.who

	local other_suit, hasSpade = {}
	for _, card in ipairs(cards) do
		local card_x = sgs.Sanguosha:getEngineCard(card:getEffectiveId())
		if who:hasShownSkill("hongyan") and card_x:getSuit() == sgs.Card_Spade then
			card_x = sgs.cloneCard(card_x:objectName(), sgs.Card_Heart, card:getNumber())
		end
		if reason == "beige" and not isCard("Peach", card_x, self.player) then
			local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
			if damage.from then
				if self:isFriend(damage.from) then
					if not self:toTurnOver(damage.from, 0) and judge.card:getSuit() ~= sgs.Card_Spade and card_x:getSuit() == sgs.Card_Spade then
						table.insert(can_use, card)
						hasSpade = true
					elseif (not self_card or self:getOverflow() > 0) and judge.card:getSuit() ~= card_x:getSuit() then
						local retr = true
						if (judge.card:getSuit() == sgs.Card_Heart and who:isWounded() and self:isFriend(who))
							or (judge.card:getSuit() == sgs.Card_Club and self:needToThrowArmor(damage.from)) then
							retr = false
						end
						if retr
							and ((self:isFriend(who) and card_x:getSuit() == sgs.Card_Heart and who:isWounded())
								or (card_x:getSuit() == sgs.Card_Club and (self:needToThrowArmor(damage.from) or damage.from:isNude())))
								or (judge.card:getSuit() == sgs.Card_Spade and self:toTurnOver(damage.from, 0)) then
							table.insert(other_suit, card)
						end
					end
				else
					if not self:toTurnOver(damage.from, 0) and card_x:getSuit() ~= sgs.Card_Spade and judge.card:getSuit() == sgs.Card_Spade then
						table.insert(can_use, card)
					end
				end
			end
		elseif self:isFriend(who) and judge:isGood(card_x)
				and not (self_card and (self:getFinalRetrial() == 2 or self:dontRespondPeachInJudge(judge)) and isCard("Peach", card_x, self.player)) then
			table.insert(can_use, card)
		elseif self:isEnemy(who) and not judge:isGood(card_x)
				and not (self_card and (self:getFinalRetrial() == 2 or self:dontRespondPeachInJudge(judge)) and isCard("Peach", card_x, self.player)) then
			table.insert(can_use, card)
		end
	end
	if not hasSpade and #other_suit > 0 then table.insertTable(can_use, other_suit) end

	if reason ~= "lightning" then
		for _, aplayer in sgs.qlist(self.room:getAllPlayers()) do
			if aplayer:containsTrick("lightning") then
				for i, card in ipairs(can_use) do
					if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
						table.remove(can_use, i)
						break
					end
				end
			end
		end
	end

	if next(can_use) then
		if self:needToThrowArmor() then
			for _, c in ipairs(can_use) do
				if c:getEffectiveId() == self.player:getArmor():getEffectiveId() then return c:getEffectiveId() end
			end
		end
		self:sortByKeepValue(can_use)
		return can_use[1]:getEffectiveId()
	else
		return -1
	end
end

function SmartAI:damageIsEffective(to, nature, from)
	local damageStruct = {}
	damageStruct.to = to or self.player
	damageStruct.from = from or self.room:getCurrent()
	damageStruct.nature = nature or sgs.DamageStruct_Normal
	return self:damageIsEffective_(damageStruct)
end

function SmartAI:damageIsEffective_(damageStruct)
	if type(damageStruct) ~= "table" and type(damageStruct) ~= "userdata" then self.room:writeToConsole(debug.traceback()) return end
	if not damageStruct.to then self.room:writeToConsole(debug.traceback()) return end
	local to = damageStruct.to
	local nature = damageStruct.nature or sgs.DamageStruct_Normal
	local damage = damageStruct.damage or 1
	local from = damageStruct.from

	if type(to) == "table" then self.room:writeToConsole(debug.traceback()) return end

	if to:hasShownSkill("heg_mingshi") and from and not (from:hasShownGeneral() and from:hasShownGeneral2()) then
		damage = damage - 1
		if damage < 1 then return false end
	end

	if to:hasArmorEffect("PeaceSpell") and nature ~= sgs.DamageStruct_Normal then return false end
	if sgs.originalHegemonyHasShownSkills(to, "jgyuhuo_pangtong|jgyuhuo_zhuque") and nature == sgs.DamageStruct_Fire then return false end
	if to:getMark("@fog") > 0 and nature ~= sgs.DamageStruct_Thunder then return false end
	if to:hasArmorEffect("Breastplate") and damage >= to:getHp() then return false end

	for _, callback in pairs(sgs.ai_damage_effect) do
		if type(callback) == "function" then
			local is_effective = callback(self, damageStruct)
			if not is_effective then return false end
		end
	end

	return true
end

function SmartAI:getDamagedEffects(to, from, isSlash)
	from = from or self.room:getCurrent()
	to = to or self.player

	if isSlash then
		if from:hasWeapon("IceSword") and to:getCards("he"):length() > 1 and not self:isFriend(from, to) then
			return false
		end
	end

	if from:objectName() ~= to:objectName() and self:hasHeavySlashDamage(from, nil, to) then return false end

	if sgs.isGoodHp(to, self.player) then
		for _, askill in sgs.qlist(to:getVisibleSkillList(true)) do
			local callback = sgs.ai_need_damaged[askill:objectName()]
			if type(callback) == "function" and callback(self, from, to) then return true end
		end
	end
	return false
end

local function prohibitUseDirectly(card, player)
	if player:isCardLimited(card, card:getHandlingMethod()) then return true end
	if card:isKindOf("Peach") and player:hasFlag("Global_PreventPeach") then return true end
	return false
end

local function getPlayerSkillList(player)
	local skills = {}
	local observer = current_self and current_self.player
	local own = observer and observer:objectName() == player:objectName()
	for _, skill in sgs.qlist(player:getVisibleSkillList(true)) do
		if own or player:hasShownSkill(skill:objectName()) then table.insert(skills, skill) end
	end
	return skills
end

local function cardsView(self, class_name, player, cards)
	for _, skill in ipairs(getPlayerSkillList(player)) do
		local askill = skill:objectName()
		if player:hasSkill(askill) or player:hasLordSkill(askill) then
			local callback = sgs.ai_cardsview[askill]
			if type(callback) == "function" then
				local ret = callback(self, class_name, player, cards)
				if ret then return ret end
			end
		end
	end
	return {}
end

local function getSkillViewCard(card, class_name, player, card_place)
	for _, skill in ipairs(getPlayerSkillList(player)) do
		local askill = skill:objectName()
		if player:hasSkill(askill) or player:hasLordSkill(askill) then
			local callback = sgs.ai_view_as[askill]
			if type(callback) == "function" then
				local skill_card_str = callback(card, player, card_place, class_name)
				if skill_card_str then
					local skill_card = sgs.Card_Parse(skill_card_str)
					assert(skill_card)
					if skill_card:isKindOf("HHalberdCard") and not player:isCardLimited(skill_card, skill_card:getHandlingMethod()) and class_name == "Slash" then return skill_card_str end
					if skill_card:isKindOf(class_name) and not player:isCardLimited(skill_card, skill_card:getHandlingMethod()) then return skill_card_str end
				end
			end
		end
	end
end

function isCard(class_name, card, player)
	if not player or not card then global_room:writeToConsole(debug.traceback()) end
	if not card:isKindOf(class_name) then
		local place
		local id = card:getEffectiveId()
		if global_room:getCardOwner(id) == nil or global_room:getCardOwner(id):objectName() ~= player:objectName() then place = sgs.Player_PlaceHand
		else place = global_room:getCardPlace(id) end
		if getSkillViewCard(card, class_name, player, place) then return true end
	else
		if not prohibitUseDirectly(card, player) then return true end
	end
	return false
end

function SmartAI:getMaxCard(player, cards, observer)
	player = player or self.player

	if player:isKongcheng() then
		return nil
	end

	cards = cards or player:getHandcards()
	local max_card, max_point = nil, 0
	for _, card in sgs.qlist(cards) do
		if (player:objectName() == self.player:objectName() and not self:isValuableCard(card)) or sgs.cardIsVisible(card, player, observer) then
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		end
	end
	if player:objectName() == self.player:objectName() and not max_card then
		for _, card in sgs.qlist(cards) do
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		end
	end

	if player:objectName() ~= self.player:objectName() then return max_card end

	if player:hasShownSkill("tianyi") and max_point > 0 then
		for _, card in sgs.qlist(cards) do
			if card:getNumber() == max_point and not isCard("Slash", card, player) then
				return card
			end
		end
	end

	return max_card
end

function SmartAI:getMinCard(player)
	player = player or self.player

	if player:isKongcheng() then
		return nil
	end

	local cards = player:getHandcards()
	local min_card, min_point = nil, 14
	for _, card in sgs.qlist(cards) do
		if player:objectName() == self.player:objectName() or sgs.cardIsVisible(card, player, observer) then
			local point = card:getNumber()
			if point < min_point then
				min_point = point
				min_card = card
			end
		end
	end

	return min_card
end

function SmartAI:getKnownNum(player, observer)
	player = player or self.player
	if not player then
		return self.player:getHandcardNum()
	else
		local cards = player:getHandcards()
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			cards:append(sgs.Sanguosha:getCard(id))
		end
		local known = 0
		for _, card in sgs.qlist(cards) do
			if sgs.cardIsVisible(card, player, observer) then
				known = known + 1
			end
		end
		return known
	end
end

function getKnownNum(player, observer)
	if not player then global_room:writeToConsole(debug.traceback()) return end
	local cards = player:getHandcards()
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		cards:append(sgs.Sanguosha:getCard(id))
	end
	local known = 0
	for _, card in sgs.qlist(cards) do
		if sgs.cardIsVisible(card, player, observer) then
			known = known + 1
		end
	end
	return known
end

function getKnownCard(player, from, class_name, viewas, flags, return_table)
	if not player or (flags and type(flags) ~= "string") then global_room:writeToConsole(debug.traceback()) return 0 end
	flags = flags or "h"
	player = findPlayerByObjectName(player:objectName())
	if not player then global_room:writeToConsole(debug.traceback()) return 0 end
	local cards = player:getCards(flags)
	if flags:match("h") then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			cards:append(sgs.Sanguosha:getCard(id))
		end
	end
	local suits = {["club"] = 1, ["spade"] = 1, ["diamond"] = 1, ["heart"] = 1}
	local known = {}
	for _, card in sgs.qlist(cards) do
		if sgs.cardIsVisible(card, player, from) then
			if (viewas and isCard(class_name, card, player)) or card:isKindOf(class_name)
				or (suits[class_name] and card:getSuitString() == class_name)
				or (class_name == "red" and card:isRed()) or (class_name == "black" and card:isBlack()) then
				table.insert(known, card)
			end
		end
	end
	if return_table then return known end
	return #known
end

function SmartAI:getCardId(class_name, acard)
	local cards
	if acard then cards = { acard }
	else
		cards = self.player:getCards("he")
		for _, key in sgs.list(self.player:getPileNames()) do
			for _, id in sgs.qlist(self.player:getPile(key)) do
				cards:append(sgs.Sanguosha:getCard(id))
			end
		end
		cards = sgs.QList2Table(cards)
	end

	local cardask
	local reason = sgs.Sanguosha:getCurrentCardUseReason()
	cardask = class_name ~= "Slash" or (reason and reason == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
	if cardask then
		if self.player:getPhase() == sgs.Player_Play then
			self:sortByUseValue(cards, true)
		else
			self:sortByKeepValue(cards)
		end
	end

	local viewArr, cardArr = {}, {}

	for _, card in ipairs(cards) do
		local card_place = self.room:getCardPlace(card:getEffectiveId())
		local viewas = getSkillViewCard(card, class_name, self.player, card_place)
		local viewascard
		if viewas then
			viewascard = sgs.Card_Parse(viewas)
			assert(viewascard)
		end
		local isCard = card:isKindOf(class_name) and not prohibitUseDirectly(card, self.player)
						and (card_place ~= sgs.Player_PlaceSpecial or self.player:getPile("wooden_ox"):contains(card:getEffectiveId()))
		if viewas then
			if isCard and self:adjustUsePriority(card, 0) >= self:adjustUsePriority(viewascard, 0) then
				table.insert(cardArr, card)
			else
				table.insert(viewArr, viewascard)
			end
		elseif isCard then
			table.insert(cardArr, card)
		end
	end

	if not cardask then
		self:sortByUsePriority(viewArr)
		self:sortByUsePriority(cardArr)
	end

	if #viewArr > 0 or #cardArr > 0 then
		local viewas, cardid
		viewas = #viewArr > 0 and viewArr[1]:toString()
		cardid = #cardArr > 0 and cardArr[1]:toString()
		if cardid or viewas then return cardid or viewas end
	end
	local cardsView = cardsView(self, class_name, self.player)
	if #cardsView > 0 then return cardsView[1] end
	return
end

function SmartAI:getCard(class_name)
	local card_id = self:getCardId(class_name)
	if card_id then return sgs.Card_Parse(card_id) end
end

function SmartAI:getCards(class_name, flag)
	local room = self.room
	if flag and type(flag) ~= "string" then room:writeToConsole(debug.traceback()) return {} end

	local private_pile
	if not flag then private_pile = true end
	flag = flag or "he"
	local all_cards = self.player:getCards(flag)
	if private_pile then
		for _, key in sgs.list(self.player:getPileNames()) do
			for _, id in sgs.qlist(self.player:getPile(key)) do
				all_cards:append(sgs.Sanguosha:getCard(id))
			end
		end
	elseif flag:match("h") then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:append(sgs.Sanguosha:getCard(id))
		end
	end

	local cards, other = {}, {}
	local card_place, card_str

	for _, card in sgs.qlist(all_cards) do
		card_place = room:getCardPlace(card:getEffectiveId())

		if card:hasFlag("AI_Using") then
		elseif class_name == "." and card_place ~= sgs.Player_PlaceSpecial then table.insert(cards, card)
		else
			local isCard = card:isKindOf(class_name) and not prohibitUseDirectly(card, self.player)
							and (card_place ~= sgs.Player_PlaceSpecial or self.player:getPile("wooden_ox"):contains(card:getEffectiveId()))
			local viewas = getSkillViewCard(card, class_name, self.player, card_place)
			if viewas then
				viewas = sgs.Card_Parse(viewas)
				assert(viewas)
				if isCard and self:adjustUsePriority(card, 0) >= self:adjustUsePriority(viewas, 0) then
					table.insert(cards, card)
				else
					table.insert(cards, viewas)
				end
			elseif isCard then
				table.insert(cards, card)
			else
				table.insert(other, card)
			end
		end
	end

	card_str = cardsView(self, class_name, self.player, other)
	if #card_str > 0 then
		for _, str in ipairs(card_str) do
			local c = sgs.Card_Parse(str)
			assert(c)
			table.insert(cards, c)
		end
	end

	return cards
end

function getCardsNum(class_name, player, from)
	if not player then
		global_room:writeToConsole(debug.traceback())
		return 0
	end

	local cards = sgs.QList2Table(player:getHandcards())
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	local num = 0
	local shownum = 0
	local redpeach = 0
	local redslash = 0
	local blackcard = 0
	local blacknull = 0
	local equipnull = 0
	local equipcard = 0
	local trickcard = 0
	local heartslash = 0
	local heartpeach = 0
	local spadenull = 0
	local spadewine = 0
	local spadecard = 0
	local diamondcard = 0
	local clubcard = 0
	local slashjink = 0
	local other = {}

	for _, card in ipairs(cards) do
		if sgs.cardIsVisible(card, player, from) then
			shownum = shownum + 1
			if isCard(class_name, card, player) then
				num = num + 1
			else
				table.insert(other, card)
			end
			if card:isKindOf("EquipCard") then
				equipcard = equipcard + 1
			end
			if card:isKindOf("TrickCard") then
				trickcard = trickcard + 1
			end
			if card:isKindOf("Slash") or card:isKindOf("Jink") then
				slashjink = slashjink + 1
			end
			if card:isRed() then
				if not card:isKindOf("Slash") then
					redslash = redslash + 1
				end
				if not card:isKindOf("Peach") then
					redpeach = redpeach + 1
				end
			end
			if card:isBlack() then
				blackcard = blackcard + 1
				if not card:isKindOf("Nullification") then
					blacknull = blacknull + 1
				end
			end
			if card:getSuit() == sgs.Card_Heart then
				if not card:isKindOf("Slash") then
					heartslash = heartslash + 1
				end
				if not card:isKindOf("Peach") then
					heartpeach = heartpeach + 1
				end
			end
			if card:getSuit() == sgs.Card_Spade then
				if not card:isKindOf("Nullification") then
					spadenull = spadenull + 1
				end
				if not card:isKindOf("Analeptic") then
					spadewine = spadewine + 1
				end
			end
			if card:getSuit() == sgs.Card_Diamond and not card:isKindOf("Slash") then
				diamondcard = diamondcard + 1
			end
			if card:getSuit() == sgs.Card_Club then
				clubcard = clubcard + 1
			end
		end
	end

	local ecards = player:getCards("e")
	for _, card in sgs.qlist(ecards) do
		table.insert(other, card)
		equipcard = equipcard + 1
		if player:getHandcardNum() > player:getHp() then
			equipnull = equipnull + 1
		end
		if card:isRed() then
			redpeach = redpeach + 1
			redslash = redslash + 1
		end
		if card:getSuit() == sgs.Card_Heart then
			heartpeach = heartpeach + 1
		end
		if card:getSuit() == sgs.Card_Spade then
			spadecard = spadecard + 1
		end
		if card:getSuit() == sgs.Card_Diamond  then
			diamondcard = diamondcard + 1
		end
		if card:getSuit() == sgs.Card_Club then
			clubcard = clubcard + 1
		end
	end

	-- A conversion estimate must stay in the caller's viewer; using the
    -- target's own AI would expose its hidden cards and generals.
    local observer_ai = from and sgs.ais[from:objectName()] or current_self
    if observer_ai then num = num + #cardsView(observer_ai, class_name, player, other) end

	if not from or player:objectName() ~= from:objectName() then
		if class_name == "Slash" then
			local slashnum
			if player:hasShownSkill("tenyearwusheng") then
				slashnum = redslash + num + (player:getHandcardNum() - shownum) * 0.69
			elseif player:hasShownSkill("heg_longdan") then
				slashnum = slashjink + (player:getHandcardNum() - shownum) * 0.72
			else
				slashnum = num + (player:getHandcardNum() - shownum) * 0.35
			end
			if player:hasWeapon("Spear") then
				local slashnum2 = math.floor((player:getHandcardNum() - shownum) / 2) + num
				return math.max(slashnum, slashnum2)
			end
			return slashnum
		elseif class_name == "Jink" then
			if player:hasShownSkill("qingguo") then
				return blackcard + num + (player:getHandcardNum() - shownum) * 0.85
			elseif player:hasShownSkill("heg_longdan") then
				return slashjink + (player:getHandcardNum() - shownum) * 0.72
			else
				return num + (player:getHandcardNum() - shownum) * 0.6
			end
		elseif class_name == "Peach" then
			if player:hasShownSkill("jijiu") then
				return num + redpeach + (player:getHandcardNum() - shownum) * 0.6
			else
				return num
			end
		elseif class_name == "Nullification" then
			if player:hasShownSkill("heg_kanpo") then
				return num + blacknull + (player:getHandcardNum() - shownum) * 0.5
			else
				return num
			end
		end
	end
	return num
end

function SmartAI:getCardsNum(class_name, flag)
	local player = self.player
	local n = 0
	if type(class_name) == "table" then
		for _, each_class in ipairs(class_name) do
			n = n + self:getCardsNum(each_class, flag)
		end
		return n
	end
	n = #self:getCards(class_name, flag)

	return n
end

function SmartAI:getAllPeachNum(player)
	player = player or self.player
	local n = 0
	for _, friend in ipairs(self:getFriends(player)) do
		local num = self.player:objectName() == friend:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", friend, self.player)
		n = n + num
	end
	return n
end
function SmartAI:getRestCardsNum(class_name, heg_yuji)
	heg_yuji = heg_yuji or self.player
	local ban = sgs.Sanguosha:getBanPackages()
	ban = table.concat(ban, "|")
	sgs.discard_pile = self.room:getDiscardPile()
	local totalnum = 0
	local discardnum = 0
	local knownnum = 0
	local card
	for i = 1, sgs.Sanguosha:getCardCount() do
		card = sgs.Sanguosha:getEngineCard(i-1)
		-- if card:isKindOf(class_name) and not ban:match(card:getPackage()) then totalnum = totalnum+1 end
		if card:isKindOf(class_name) then totalnum = totalnum + 1 end
	end
	for _, card_id in sgs.qlist(sgs.discard_pile) do
		card = sgs.Sanguosha:getEngineCard(card_id)
		if card:isKindOf(class_name) then discardnum = discardnum + 1 end
	end
	for _, player in sgs.qlist(self.room:getOtherPlayers(heg_yuji)) do
		knownnum = knownnum + getKnownCard(player, self.player, class_name)
	end
	return totalnum - discardnum - knownnum
end

function SmartAI:hasSuit(suit_strings, include_equip, player)
	return self:getSuitNum(suit_strings, include_equip, player) > 0
end

function SmartAI:getSuitNum(suit_strings, include_equip, player)
	player = player or self.player
	local n = 0
	local flag = include_equip and "he" or "h"
	local allcards
	if player:objectName() == self.player:objectName() then
		allcards = sgs.QList2Table(player:getCards(flag))
	else
		allcards = include_equip and sgs.QList2Table(player:getEquips()) or {}
		local handcards = sgs.QList2Table(player:getHandcards())
		for i = 1, #handcards, 1 do
			if sgs.cardIsVisible(handcards[i], player, self.player) then
				table.insert(allcards, handcards[i])
			end
		end
	end
	for _, card in ipairs(allcards) do
		for _, suit_string in ipairs(suit_strings:split("|")) do
			if card:getSuitString() == suit_string
				or (suit_string == "black" and card:isBlack()) or (suit_string == "red" and card:isRed()) then
				n = n + 1
			end
		end
	end
	return n
end

function SmartAI:hasSkill(skill)
	local skill_name = skill
	if type(skill) == "table" then
		skill_name = skill.name
	end

	local real_skill = sgs.Sanguosha:getSkill(skill_name)
	if real_skill and real_skill:isLordSkill() then
		return self.player:hasLordSkill(skill_name)
	else
		return self.player:hasSkill(skill_name)
	end
end

function SmartAI:hasSkills(skill_names, player)
	player = player or self.player
	if type(player) == "table" then
		for _, p in ipairs(player) do
			if sgs.originalHegemonyHasShownSkills(p, skill_names) then return true end
		end
		return false
	end
	if type(skill_names) == "string" then
		return sgs.originalHegemonyHasShownSkills(player, skill_names)
	end
	return false
end

-- fillSkillCards stays on native SmartAI to retain V2 action context and dispatch.


-- useSkillCard stays on native SmartAI to retain V2 action context and dispatch.

function SmartAI:useBasicCard(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	if self:needRende() then return end
	self:useCardByClassName(card, use)
end

function SmartAI:aoeIsEffective(card, to, source)
	local players = self.room:getAlivePlayers()
	players = sgs.QList2Table(players)
	source = source or self.room:getCurrent()

	if to:hasArmorEffect("Vine") then
		return false
	end

	if to:isLocked(card) then
		return false
	end

	if card:isKindOf("SavageAssault") then
		if sgs.originalHegemonyHasShownSkills(to, "heg_huoshou|heg_juxiang") then
			return false
		end
	end

	if to:hasShownSkill("heg_weimu") and card:isBlack() then return false end

	if not self:hasTrickEffective(card, to, source) or not self:damageIsEffective(to, nil, source) then
		return false
	end
	return true
end

function SmartAI:canAvoidAOE(card)
	if not self:aoeIsEffective(card, self.player) then return true end
	if card:isKindOf("SavageAssault") then
		if self:getCardsNum("Slash") > 0 then
			return true
		end
	end
	if card:isKindOf("ArcheryAttack") then
		if self:getCardsNum("Jink") > 0 or (self:hasEightDiagramEffect() and self.player:getHp() > 1) then
			return true
		end
	end
	return false
end

function SmartAI:getDistanceLimit(card, from)
	from = from or self.player
	if card:isKindOf("Snatch") or card:isKindOf("SupplyShortage") or card:isKindOf("Slash") then
		return 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, from, card)
	elseif card:isKindOf("Indulgence") or card:isKindOf("FireAttack") then
		return 999
	end
end

function SmartAI:exclude(players, card, from)
	from = from or self.player
	local excluded = {}
	local limit = self:getDistanceLimit(card, from)
	local range_fix = 0
	if card:isKindOf("Snatch") and card:getSkillName() == "heg_jixi" then
		range_fix = range_fix + 1
	end

	if type(players) ~= "table" then players = sgs.QList2Table(players) end

	if card:isVirtualCard() then
		for _, id in sgs.qlist(card:getSubcards()) do
			if from:getOffensiveHorse() and from:getOffensiveHorse():getEffectiveId() == id then range_fix = range_fix + 1 end
		end
	end

	for _, player in ipairs(players) do
		if --[[not sgs.Sanguosha:isProhibited(from, player, card) and]] (not card:isKindOf("TrickCard") or self:hasTrickEffective(card, player, from))
			and (not limit or from:distanceTo(player, range_fix) <= limit) then
			table.insert(excluded, player)
		end
	end
	return excluded
end


function SmartAI:getJiemingChaofeng(player)
	local max_x, chaofeng = 0, 0
	for _, friend in ipairs(self:getFriends(player)) do
		local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
		if x > max_x then
			max_x = x
		end
	end
	if max_x < 2 then
		chaofeng = 5 - max_x * 2
	else
		chaofeng = (-max_x) * 2
	end
	return chaofeng
end

function SmartAI:getAoeValue(card)
	local attacker = self.player
	local good, bad, isEffective_F, isEffective_E = 0, 0, 0, 0

	local current = self.room:getCurrent()
local wansha = current:hasShownSkill("wansha")
	local peach_num = self:getCardsNum("Peach")
	local null_num = self:getCardsNum("Nullification")
	local punish
	local enemies, kills = 0, 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not self.player:isFriendWith(p) and self:evaluateKingdom(p) ~= self:originalHegemonyOwnKingdom() then enemies = enemies + 1 end
		if self:isFriend(p) then
			if not wansha then peach_num = peach_num + getCardsNum("Peach", p, self.player) end
			null_num = null_num + getCardsNum("Nullification", p, self.player)
		else
			null_num = null_num - getCardsNum("Nullification", p, self.player)
		end
	end
	if card:isVirtualCard() and card:subcardsLength() > 0 then
		for _, subcardid in sgs.qlist(card:getSubcards()) do
			local subcard = sgs.Sanguosha:getCard(subcardid)
			if isCard("Peach", subcard, self.player) then peach_num = peach_num - 1 end
			if isCard("Nullification", subcard, self.player) then null_num = null_num - 1 end
		end
	end

	local function getAoeValueTo(to)
		local value, sj_num = 0, 0
		if card:isKindOf("ArcheryAttack") then sj_num = getCardsNum("Jink", to, self.player) end
		if card:isKindOf("SavageAssault") then sj_num = getCardsNum("Slash", to, self.player) end

		if self:aoeIsEffective(card, to, self.player) then
			local sameKingdom
			if self:isFriend(to) then
				isEffective_F = isEffective_F + 1
				if self.player:isFriendWith(to) or self:evaluateKingdom(to) == self:originalHegemonyOwnKingdom() then sameKingdom = true end
			else
				isEffective_E = isEffective_E + 1
			end

			local jink = sgs.cloneCard("jink")
			local slash = sgs.cloneCard("slash")
			local isLimited
			if card:isKindOf("ArcheryAttack") and to:isCardLimited(jink, sgs.Card_MethodResponse) then isLimited = true
			elseif card:isKindOf("SavageAssault") and to:isCardLimited(slash, sgs.Card_MethodResponse) then isLimited = true end
			if card:isKindOf("SavageAssault") and sgs.card_lack[to:objectName()]["Slash"] == 1
				or card:isKindOf("ArcheryAttack") and sgs.card_lack[to:objectName()]["Jink"] == 1
				or sj_num < 1 or isLimited then
				value = -20
			else
				value = -10
			end
			-- value = value + math.min(50, to:getHp() * 10)

			if self:getDamagedEffects(to, self.player) then value = value + 30 end
			if self:needToLoseHp(to, self.player) then value = value + 20 end

			if card:isKindOf("ArcheryAttack") then
				if sgs.originalHegemonyHasShownSkills(to, "nosleiji") and (sj_num >= 1 or self:hasEightDiagramEffect(to)) and self:findLeijiTarget(to, 50, self.player) then
					value = value + 20
					if self:hasSuit("spade", true, to) then value = value + 50
					else value = value + to:getHandcardNum() * 10
					end
				elseif self:hasEightDiagramEffect(to) then
					value = value + 5
					if self:getFinalRetrial(to) == 2 then
						value = value - 10
					elseif self:getFinalRetrial(to) == 1 then
						value = value + 10
					end
				end
			end

			if card:isKindOf("ArcheryAttack") and sj_num >= 1 then
				if to:hasShownSkill("xiaoguo") then value = value - 4 end
			elseif card:isKindOf("SavageAssault") and sj_num >= 1 then
				if to:hasShownSkill("xiaoguo") then value = value - 4 end
			end

			if to:getHp() == 1 then
				if sameKingdom then
					if null_num > 0 then null_num = null_num - 1
					elseif getCardsNum("Analeptic", to, self.player) > 0 then
					elseif not wansha and peach_num > 0 then peach_num = peach_num - 1
					elseif wansha and (getCardsNum("Peach", to, self.player) > 0 or self:isFriend(current) and getCardsNum("Peach", to, self.player) > 0) then
					else
						if not punish then
							punish = true
							value = value - self.player:getCardCount(true) * 10
						end
						value = value - to:getCardCount(true) * 10
					end
				else
					kills = kills + 1
					if wansha and (sgs.card_lack[to:objectName()]["Peach"] == 1 or getCardsNum("Peach", to, self.player) == 0) then
						value = value - sgs.getReward(to) * 10
					end
				end
			end

			if not sgs.isAnjiang(to) and to:isLord() then value = value - self.room:getLieges(to:getKingdom(), to):length() * 5 end

			if to:getHp() > 1 and to:hasShownSkill("nosjianxiong") then
				value = value + ((card:isVirtualCard() and card:subcardsLength() * 10) or 10)
			end

		else
			value = 0
			if to:hasShownSkill("heg_juxiang") and not card:isVirtualCard() then value = value + 10 end
		end

		return value
	end

	if card:isKindOf("SavageAssault") then
		local heg_menghuo = sgs.findPlayerByShownSkillName("heg_huoshou")
		attacker = heg_menghuo or attacker
	end

	for _, p in sgs.qlist(self.room:getAllPlayers()) do
		if p:objectName() == self.player:objectName() then continue end
		if self:isFriend(p) then
			good = good + getAoeValueTo(p)
		else
			bad = bad + getAoeValueTo(p)
		end
		if self:aoeIsEffective(card, p, self.player) and self:cantbeHurt(p, attacker) then bad = bad + 250 end
		if kills == enemies then return 998 end
	end

	if isEffective_F == 0 and isEffective_E == 0 then
		return attacker:hasShownSkill("heg_jizhi") and 10 or -100
	elseif isEffective_E == 0 then
		return -100
	end

	if attacker:hasShownSkill("heg_jizhi") then good = good + 10 end
	if attacker:hasShownSkill("heg_luanji") then good = good + 5 * isEffective_E end

	return good - bad
end

function SmartAI:hasTrickEffective(card, to, from)
	from = from or self.room:getCurrent()
	to = to or self.player
	--if sgs.Sanguosha:isProhibited(from, to, card) then return false end
	if to:isRemoved() then return false end

	if not card:isKindOf("TrickCard") then self.room:writeToConsole(debug.traceback()) return end
	if to:hasShownSkill("hongyan") and card:isKindOf("Lightning") then return false end
	if to:hasShownSkill("heg_qianxun") and card:isKindOf("Snatch") then return false end
	if to:hasShownSkill("heg_qianxun") and card:isKindOf("Indulgence") then return false end
	if card:isKindOf("Indulgence") then
		if to:hasSkills("jgjiguan_qinglong|jgjiguan_baihu|jgjiguan_zhuque|jgjiguan_xuanwu") then return false end
		if to:hasSkills("jgjiguan_bian|jgjiguan_suanni|jgjiguan_chiwen|jgjiguan_yazi") then return false end
	end
	if to:hasShownSkill("heg_weimu") and card:isBlack() then
		if from:objectName() == to:objectName() and card:isKindOf("Disaster") then
		else
			return false
		end
	end
	if to:hasShownSkill("heg_kongcheng") and to:isKongcheng() and card:isKindOf("Duel") then return false end

	if card:isKindOf("IronChain") and not to:canBeChainedBy(from) then return false end

	local nature = sgs.DamageStruct_Normal
	if card:isKindOf("FireAttack") or card:isKindOf("BurningCamps") then nature = sgs.DamageStruct_Fire
	elseif card:isKindOf("Drowning") then nature = sgs.DamageStruct_Thunder end

	if (card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault"))
		and not self:damageIsEffective(to, nature, from) then return false end

	if to:hasArmorEffect("IronArmor") and (card:isKindOf("FireAttack") or card:isKindOf("BurningCamps")) then return false end

	for _, callback in pairs(sgs.ai_trick_prohibit) do
		if type(callback) == "function" then
			if callback(self, card, to, from) then return false end
		end
	end

	return true
end

function SmartAI:useTrickCard(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	if self:needRende() and not card:isKindOf("ExNihilo") then return end
	self:useCardByClassName(card, use)
end

sgs.weapon_range = {}

function SmartAI:hasEightDiagramEffect(player)
	player = player or self.player
	return player:hasArmorEffect("EightDiagram") or player:hasArmorEffect("bazhen")
end

function SmartAI:hasCrossbowEffect(player)
	player = player or self.player
	return player:hasWeapon("Crossbow") or player:hasShownSkill("heg_paoxiao")
end

sgs.ai_weapon_value = {}

function SmartAI:evaluateWeapon(card, player, target)
	player = player or self.player
	local deltaSelfThreat, inAttackRange = 0
	local currentRange
	local enemies = target and { target } or self:getEnemies(player)
	if not card then self.room:writeToConsole(debug.traceback()) return -1
	else
		currentRange = sgs.weapon_range[card:getClassName()] or 0
	end

	local callback = sgs.ai_weapon_value[card:objectName()]
	local callback2 = sgs.ai_slash_weaponfilter[card:objectName()]

	for _, enemy in ipairs(enemies) do
		if player:distanceTo(enemy) <= currentRange then
			inAttackRange = true
			local def = sgs.getDefenseSlash(enemy, self) / 2
			if def < 0 then def = 6 - def
			elseif def <= 1 then def = 6
			else def = 6 / def
			end
			deltaSelfThreat = deltaSelfThreat + def
			if type(callback) == "function" then deltaSelfThreat = deltaSelfThreat + (callback(self, enemy, player) or 0) end
			if type(callback2) == "function" and callback2(self, enemy, player) then deltaSelfThreat = deltaSelfThreat + 1 end
		end
	end


	if card:isKindOf("Crossbow") and not player:hasShownSkill("heg_paoxiao") and inAttackRange then
		local slash_num = player:objectName() == self.player:objectName() and self:getCardsNum("Slash") or getCardsNum("Slash", player, self.player)
		local analeptic_num = player:objectName() == self.player:objectName() and self:getCardsNum("Analeptic") or getCardsNum("Analeptic", player, self.player)
		local peach_num = player:objectName() == self.player:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", player, self.player)

		deltaSelfThreat = deltaSelfThreat + slash_num * 3 - 2
		if player:hasShownSkill("heg_kurou") then deltaSelfThreat = deltaSelfThreat + peach_num + analeptic_num + self.player:getHp() end
		if player:getWeapon() and not self:hasCrossbowEffect(player) and not player:canSlashWithoutCrossbow() and slash_num > 0 then
			for _, enemy in ipairs(enemies) do
				if player:distanceTo(enemy) <= currentRange
					and (sgs.card_lack[enemy:objectName()]["Jink"] == 1 or slash_num >= enemy:getHp()) then
					deltaSelfThreat = deltaSelfThreat + 10
				end
			end
		end
	end

	if player:hasShownSkill("jijiu") and card:isRed() then deltaSelfThreat = deltaSelfThreat + 0.5 end
	if sgs.originalHegemonyHasShownSkills(player, "qixi|guidao") and card:isBlack() then deltaSelfThreat = deltaSelfThreat + 0.5 end

	return deltaSelfThreat, inAttackRange
end

sgs.ai_armor_value = {}

function SmartAI:evaluateArmor(card, player)
	player = player or self.player
	local ecard = card or player:getArmor()
	if not ecard then return 0 end

	local value = 0
	if player:hasShownSkill("jijiu") and ecard:isRed() then value = value + 0.5 end
	if sgs.originalHegemonyHasShownSkills(player, "qixi|guidao") and ecard:isBlack() then value = value + 0.5 end
	for _, askill in sgs.qlist(player:getVisibleSkillList()) do
		local callback = sgs.ai_armor_value[askill:objectName()]
		if type(callback) == "function" then
			return value + (callback(ecard, player, self) or 0)
		end
	end
	local callback = sgs.ai_armor_value[ecard:objectName()]
	if type(callback) == "function" then
		return value + (callback(player, self) or 0)
	end
	return value + 0.5
end

function SmartAI:getSameEquip(card, player)
	player = player or self.player
	if not card then return end
	if card:isKindOf("Weapon") then return player:getWeapon()
	elseif card:isKindOf("Armor") then return player:getArmor()
	elseif card:isKindOf("DefensiveHorse") then return player:getDefensiveHorse()
	elseif card:isKindOf("OffensiveHorse") then return player:getOffensiveHorse() end
end

function SmartAI:useEquipCard(card, use)
	if not card then global_room:writeToConsole(debug.traceback()) return end
	if self.player:hasSkill("heg_xiaoji") and self:evaluateArmor(card) > -5 then
		local armor = self.player:getArmor()
		if armor and armor:objectName() == "PeaceSpell" and card:isKindOf("Armor") then
			if (self:getAllPeachNum() == 0 and self.player:getHp() < 3) and not (self.player:getHp() < 2 and self:getCardsNum("Analeptic") > 0) then
				return
			end
		end
		use.card = card
		return
	end
	if self.player:hasSkills(sgs.lose_equip_skill) and self:evaluateArmor(card) > -5 and #self.enemies > 1 then
		local armor = self.player:getArmor()
		if armor and armor:objectName() == "PeaceSpell" and card:isKindOf("Armor") then
			if (self:getAllPeachNum() == 0 and self.player:getHp() < 3) and not (self.player:getHp() < 2 and self:getCardsNum("Analeptic") > 0) then
				return
			end
		end
		use.card = card
		return
	end
	if self.player:getHandcardNum() == 1 and self:needKongcheng() and self:evaluateArmor(card) > -5 then
		local armor = self.player:getArmor()
		if armor and armor:objectName() == "PeaceSpell" and card:isKindOf("Armor") then
			if (self:getAllPeachNum() == 0 and self.player:getHp() < 3) and not (self.player:getHp() < 2 and self:getCardsNum("Analeptic") > 0) then
				return
			end
		end
		use.card = card
		return
	end
	if card:isKindOf("Armor") and card:objectName() == "PeaceSpell" then
		local heg_lord_zhangjiao = sgs.findPlayerByShownSkillName("heg_wendao") --有君张角在其他人（受伤/有防具）则不装备太平要术
		if heg_lord_zhangjiao and heg_lord_zhangjiao:isAlive() and not self:isWeak(heg_lord_zhangjiao) then
			if self.player:objectName() ~= heg_lord_zhangjiao:objectName() and (self.player:isWounded() or self.player:getArmor()) then
				return
			end
		end
	end
	if card:isKindOf("Weapon") and card:objectName() == "DragonPhoenix" then
		local heg_lord_liubei = sgs.findPlayerByShownSkillName("heg_zhangwu") --有君刘备在（其他势力/除他以外有武器）的人不装备龙凤剑
		if heg_lord_liubei and heg_lord_liubei:isAlive() then
			if not self.player:isFriendWith(heg_lord_liubei) or (self.player:objectName() ~= heg_lord_liubei:objectName() and self.player:getWeapon()) then
				return
			end
		end
	end
	local same = self:getSameEquip(card)
	local zzzh, isfriend_zzzh, isenemy_zzzh = sgs.findPlayerByShownSkillName("guzheng")
	if zzzh then
		if self:isFriend(zzzh) then isfriend_zzzh = true
		else isenemy_zzzh = true
		end
	end
	if same then
		if (self.player:hasSkill("rende") and self:findFriendsByType(sgs.Friend_Draw))
			or (self.player:hasSkills("qixi|heg_duanliang") and (card:isBlack() or same:isBlack()))
			or (self.player:hasSkills("heg_guose") and (card:getSuit() == sgs.Card_Diamond or same:getSuit() == sgs.Card_Diamond))
			or (self.player:hasSkill("jijiu") and (card:isRed() or same:isRed()))
			or (self.player:hasSkill("guidao") and same:isBlack() and card:isRed())
			or isfriend_zzzh
			then return end
	end
	local canUseSlash = self:getCardId("Slash") and self:slashIsAvailable(self.player)
	self:useCardByClassName(card, use)
	if use.card then return end
	if card:isKindOf("Weapon") then
		if same and self.player:hasSkill("heg_qiangxi") and not self.player:hasUsed("HQiangxiCard") then
			local dummy_use = { isDummy = true }
			self:useSkillCard(sgs.Card_Parse("@HQiangxiCard=" .. same:getEffectiveId().. "&heg_qiangxi"), dummy_use)
			if dummy_use.card and dummy_use.card:getSubcards():length() == 1 then return end
		end
		if self.player:hasSkill("rende") then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:getWeapon() then return end
			end
		end
		if self.player:hasSkills("heg_paoxiao") and card:isKindOf("Crossbow") then return end
		if not self:needKongcheng() and not self.player:hasSkills(sgs.lose_equip_skill) and self:getOverflow() <= 0 and not canUseSlash then return end
		--if (not use.to) and self.player:getWeapon() and not self.player:hasSkills(sgs.lose_equip_skill) then return end
		if self.player:hasSkill("heg_zhiheng") and not self.player:hasUsed("HZhihengCard") and self.player:getWeapon() and not card:isKindOf("Crossbow") then return end
		if not self:needKongcheng() and self.player:getHandcardNum() <= self.player:getHp() - 2 then return end
		if not self.player:getWeapon() or self:evaluateWeapon(card) > self:evaluateWeapon(self.player:getWeapon()) then
			use.card = card
		end
	elseif card:isKindOf("Armor") then
		local lion = self:getCard("SilverLion")
		if lion and self.player:isWounded() and not self.player:hasArmorEffect("SilverLion") and not card:isKindOf("SilverLion")
			and not (self.player:hasSkills("bazhen|jgyizhong") and not self.player:getArmor()) then
			use.card = lion
			return
		end
		if self.player:hasSkill("rende") and self:evaluateArmor(card) < 4 then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:getArmor() then return end
			end
		end
		if self:evaluateArmor(card) > self:evaluateArmor() or isenemy_zzzh and self:getOverflow() > 0 then use.card = card end
		return
	elseif card:isKindOf("OffensiveHorse") then
		if self.player:hasSkill("rende") then
			for _,friend in ipairs(self.friends_noself) do
				if not friend:getOffensiveHorse() then return end
			end
			use.card = card
			return
		else
			if not self.player:hasSkills(sgs.lose_equip_skill) and self:getOverflow() <= 0 and not (canUseSlash or self:getCardId("Snatch")) then
				return
			else
				if self.lua_ai:useCard(card) then
					use.card = card
					return
				end
			end
		end
	elseif card:isKindOf("DefensiveHorse") then
		local heg_tiaoxin = true
		if self.player:hasSkill("heg_tiaoxin") then
			local dummy_use = { isDummy = true, defHorse = true }
			self:useSkillCard(sgs.Card_Parse("@HTiaoxinCard=.&heg_tiaoxin"), dummy_use)
			if not dummy_use.card then heg_tiaoxin = false end
		end
		if heg_tiaoxin and self.lua_ai:useCard(card) then
			use.card = card
		end
	elseif card:isKindOf("Treasure") then
		if not card:isKindOf("wooden_ox") and not self.player:getTreasure()then
			for _, friend in ipairs(self.friends) do
				if (friend:getTreasure() and friend:getPile("wooden_ox"):length() > 1) then
					return
				end
			end
		end
		if not self.player:getTreasure() or card:isKindOf("JadeSeal") then
			use.card = card
		end
	elseif self.lua_ai:useCard(card) then
		use.card = card
	end
end

function SmartAI:needRende()
	return self.player:getLostHp() > 1 and self:findFriendsByType(sgs.Friend_Draw) and (self.player:hasSkill("rende") and self.player:getMark("rende") < 3)
end

function SmartAI:needToLoseHp(to, from, isSlash, passive, recover)
	to = to or self.player
	if isSlash and from and from:hasWeapon("IceSword") and to:getCards("he"):length() > 1 and not self:isFriend(from, to) then
		return false
	end
	if from and self:hasHeavySlashDamage(from, nil, to) then return false end
	local n = to:getMaxHp()

	if not passive then
		if to:hasShownSkill("rende") and to:getMaxHp() > 2 and not self:willSkipPlayPhase(to) and self:findFriendsByType(sgs.Friend_Draw, to) then
			n = math.min(n, to:getMaxHp() - 1)
		elseif to:hasShownSkill("heg_hengzheng") and (to == self.player and sgs.ai_skill_invoke.heg_hengzheng(self)) then
			n = math.min(n, to:getMaxHp() - 1)
		elseif sgs.originalHegemonyHasShownSkills(to, "heg_yinghun_sunjian|heg_yinghun_sunce|heg_zaiqi") then
			n = math.min(n, to:getMaxHp() - 1)
		end
	end

	local xiangxiang = sgs.findPlayerByShownSkillName("jieyin")
	if xiangxiang and xiangxiang:isWounded() and self:isFriend(xiangxiang, to) and not to:isWounded() and to:isMale()
		and (xiangxiang:getPhase() == sgs.Player_Play and xiangxiang:getHandcardNum() >= 2 and not xiangxiang:hasUsed("JieyinCard")
			or self:getEnemyNumBySeat(self.room:getCurrent(), xiangxiang, self.player) <= 1) then
		local friends = self:getFriendsNoself(to)
		local need_jieyin = true
		self:sort(friends, "hp")
		for _, friend in ipairs(friends) do
			if friend:isMale() and friend:isWounded() then need_jieyin = false end
		end
		if need_jieyin then n = math.min(n, to:getMaxHp() - 1) end
	end

	if recover then return to:getHp() >= n end

	return to:getHp() > n
end

function IgnoreArmor(from, to)
	if not from or not to then global_room:writeToConsole(debug.traceback()) return end
	if not to:getArmor() then return true end
	if not to:hasArmorEffect(to:getArmor():objectName()) or from:hasWeapon("QinggangSword") then
		return true
	end
	return
end

function SmartAI:needToThrowArmor(player)
	player = player or self.player
	if not player:getArmor() or not player:hasArmorEffect(player:getArmor():objectName()) then return false end
	if player:hasShownSkill("bazhen") and not player:getArmor():isKindOf("EightDiagram") then return true end
	if self:evaluateArmor(player:getArmor(), player) <= -2 then return true end
	if player:hasArmorEffect("SilverLion") and player:isWounded() then
		if self:isFriend(player) then
			if player:objectName() == self.player:objectName() then
				return true
			else
				return self:isWeak(player) and not sgs.originalHegemonyHasShownSkills(player, sgs.use_lion_skill)
			end
		else
			return true
		end
	end
	local damage = self.room:getTag("CurrentDamageStruct")
	if damage.damage and not damage.chain and not damage.prevented and damage.nature == sgs.DamageStruct_Fire
		and damage.to:isChained() and player:isChained() and player:hasArmorEffect("Vine") then
		return true
	end
	return false
end

function SmartAI:doNotDiscard(to, flags, conservative, n, cant_choose)
	if not to then global_room:writeToConsole(debug.traceback()) return end
	n = n or 1
	flags = flags or "he"
	if to:isNude() then return true end
	conservative = conservative or (sgs.turncount <= 2 and self.room:alivePlayerCount() > 2)
	local enemies = self:getEnemies(to)
	if #enemies == 1 and sgs.originalHegemonyHasShownSkills(enemies[1], "heg_qianxun|heg_weimu") and self.room:alivePlayerCount() == 2 then conservative = false end

	if cant_choose then
		if self:needKongcheng(to) and to:getHandcardNum() <= n then return true end
		if self:getLeastHandcardNum(to) <= n then return true end
		if sgs.originalHegemonyHasShownSkills(to, sgs.lose_equip_skill) and to:hasEquip() then return true end
		if self:needToThrowArmor(to) then return true end
	else
		if flags:match("e") then
			if sgs.originalHegemonyHasShownSkills(to, "jieyin+heg_xiaoji") and to:getDefensiveHorse() then return false end
			if sgs.originalHegemonyHasShownSkills(to, "jieyin+heg_xiaoji") and to:getArmor() and not to:getArmor():isKindOf("SilverLion") then return false end
		end
		if flags == "h" or (flags == "he" and not to:hasEquip()) then
			if to:isKongcheng() or not self.player:canDiscard(to, "h") then return true end
			if not self:hasLoseHandcardEffective(to) then return true end
			if to:getHandcardNum() == 1 and self:needKongcheng(to) then return true end
			if #self.friends > 1 and to:getHandcardNum() == 1 and to:hasShownSkill("sijian") then return false end
		elseif flags == "e" or (flags == "he" and to:isKongcheng()) then
			if not to:hasEquip() then return true end
			if sgs.originalHegemonyHasShownSkills(to, sgs.lose_equip_skill) then return true end
			if to:getCardCount(true) == 1 and self:needToThrowArmor(to) then return true end
		end
		if flags == "he" and n == 2 then
			if not self.player:canDiscard(to, "e") then return true end
			if to:getCardCount(true) < 2 then return true end
			if not to:hasEquip() then
				if not self:hasLoseHandcardEffective(to) then return true end
				if to:getHandcardNum() <= 2 and self:needKongcheng(to) then return true end
			end
			if sgs.originalHegemonyHasShownSkills(to, sgs.lose_equip_skill) and to:getHandcardNum() < 2 then return true end
			if to:getCardCount(true) <= 2 and self:needToThrowArmor(to) then return true end
		end
	end
	if flags == "he" and n > 2 then
		if not self.player:canDiscard(to, "e") then return true end
		if to:getCardCount(true) < n then return true end
	end
	return false
end

function SmartAI:findPlayerToDiscard(flags, include_self, isDiscard, players, return_table)
	local player_table = {}
	if isDiscard == nil then isDiscard = true end
	local friends, enemies = {}, {}
	if not players then
		friends = include_self and self.friends or self.friends_noself
		enemies = self.enemies
	else
		for _, player in sgs.qlist(players) do
			if self:isFriend(player) and (include_self or player:objectName() ~= self.player:objectName()) then table.insert(friends, player)
			elseif self:isEnemy(player) then table.insert(enemies, player) end
		end
	end
	flags = flags or "he"

	self:sort(enemies, "defense")
	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if self.player:canDiscard(enemy, "e") then
				local dangerous = self:getDangerousCard(enemy)
				if dangerous and (not isDiscard or self.player:canDiscard(enemy, dangerous)) then
					table.insert(player_table, enemy)
				end
			end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:hasArmorEffect("EightDiagram") and not self:needToThrowArmor(enemy) and self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId()) then
				table.insert(player_table, enemy)
			end
		end
	end

	if flags:match("j") then
		for _, friend in ipairs(friends) do
			if ((friend:containsTrick("indulgence") and not friend:hasShownSkill("heg_keji")) or friend:containsTrick("supply_shortage"))
				and not (friend:hasShownSkill("qiaobian") and not friend:isKongcheng())
				and (not isDiscard or self.player:canDiscard(friend, "j")) then
				table.insert(player_table, friend)
			end
		end
		for _, friend in ipairs(friends) do
			if friend:containsTrick("lightning") and self:hasWizard(enemies, true) and (not isDiscard or self.player:canDiscard(friend, "j")) then table.insert(player_table, friend) end
		end
		for _, enemy in ipairs(enemies) do
			if enemy:containsTrick("lightning") and self:hasWizard(enemies, true) and (not isDiscard or self.player:canDiscard(enemy, "j")) then table.insert(player_table, enemy) end
		end
	end

	if flags:match("e") then
		for _, friend in ipairs(friends) do
			if self:needToThrowArmor(friend) and (not isDiscard or self.player:canDiscard(friend, friend:getArmor():getEffectiveId())) then
				table.insert(player_table, friend)
			end
		end
		for _, enemy in ipairs(enemies) do
			if self.player:canDiscard(enemy, "e") then
				local valuable = self:getValuableCard(enemy)
				if valuable and (not isDiscard or self.player:canDiscard(enemy, valuable)) then
					table.insert(player_table, enemy)
				end
			end
		end
		for _, enemy in ipairs(enemies) do
			if sgs.originalHegemonyHasShownSkills(enemy, "jijiu|beige|heg_weimu|heg_qingcheng") and not self:doNotDiscard(enemy, "e") then
				if enemy:getDefensiveHorse() and (not isDiscard or self.player:canDiscard(enemy, enemy:getDefensiveHorse():getEffectiveId())) then table.insert(player_table, enemy) end
				if enemy:getArmor() and not self:needToThrowArmor(enemy) and (not isDiscard or self.player:canDiscard(enemy, enemy:getArmor():getEffectiveId())) then table.insert(player_table, enemy) end
				if enemy:getOffensiveHorse() and (not enemy:hasShownSkill("jijiu") or enemy:getOffensiveHorse():isRed()) and (not isDiscard or self.player:canDiscard(enemy, enemy:getOffensiveHorse():getEffectiveId())) then
					table.insert(player_table, enemy)
				end
				if enemy:getWeapon() and (not enemy:hasShownSkill("jijiu") or enemy:getWeapon():isRed()) and (not isDiscard or self.player:canDiscard(enemy, enemy:getWeapon():getEffectiveId())) then
					table.insert(player_table, enemy)
				end
			end
		end
	end

	if flags:match("h") then
		for _, enemy in ipairs(enemies) do
			local cards = sgs.QList2Table(enemy:getHandcards())
			if #cards <= 2 and not enemy:isKongcheng() and not (enemy:hasShownSkill("heg_tuntian") and enemy:getPhase() == sgs.Player_NotActive) then
				for _, cc in ipairs(cards) do
					if sgs.cardIsVisible(cc, enemy, self.player) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) and (not isDiscard or self.player:canDiscard(enemy, cc:getId())) then
						table.insert(player_table, enemy)
					end
				end
			end
		end
	end

	if flags:match("e") then
		for _, enemy in ipairs(enemies) do
			if enemy:hasEquip() and not self:doNotDiscard(enemy, "e") and (not isDiscard or self.player:canDiscard(enemy, "e")) then
				table.insert(player_table, enemy)
			end
		end
	end

	if flags:match("h") then
		self:sort(enemies, "handcard")
		for _, enemy in ipairs(enemies) do
			if (not isDiscard or self.player:canDiscard(enemy, "h")) and not self:doNotDiscard(enemy, "h") then
				table.insert(player_table, enemy)
			end
		end
	end

	if flags:match("h") then
		local heg_zhugeliang = sgs.findPlayerByShownSkillName("heg_kongcheng")
		if heg_zhugeliang and self:isFriend(heg_zhugeliang) and heg_zhugeliang:getHandcardNum() == 1 and self:getEnemyNumBySeat(self.player, heg_zhugeliang) > 0
			and heg_zhugeliang:getHp() <= 2 and (not isDiscard or self.player:canDiscard(heg_zhugeliang, "h")) then
			table.insert(player_table, heg_zhugeliang)
		end
	end
	if return_table then return player_table
	else
		if #player_table == 0 then return nil else return player_table[1] end
	end
end

function SmartAI:findPlayerToDraw(include_self, drawnum)
	drawnum = drawnum or 1
	local players = sgs.QList2Table(include_self and self.room:getAllPlayers() or self.room:getOtherPlayers(self.player))
	local friends = {}
	for _, player in ipairs(players) do
		if self:isFriend(player) and not (player:hasShownSkill("heg_kongcheng") and player:isKongcheng() and drawnum <= 2) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return end

	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and (AssistTarget:getHandcardNum() < 10 or self.player:getHandcardNum() > AssistTarget:getHandcardNum()) then
		for _, friend in ipairs(friends) do
			if friend:objectName() == AssistTarget:objectName() and not self:willSkipPlayPhase(friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if sgs.originalHegemonyHasShownSkills(friend, sgs.cardneed_skill) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end

	self:sort(friends, "handcard")
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
			return friend
		end
	end
	return nil
end

function SmartAI:dontRespondPeachInJudge(judge)
	if not judge or type(judge) ~= "userdata" then self.room:writeToConsole(debug.traceback()) return end
	local peach_num = self:getCardsNum("Peach")
	if peach_num == 0 then return false end
	if self:willSkipPlayPhase() and self:getCardsNum("Peach") > self:getOverflow(self.player, true) then return false end
	if judge.reason == "lightning" and self:isFriend(judge.who) then return false end

	local card = self:getCard("Peach")
	local dummy_use = { isDummy = true }
	self:useBasicCard(card, dummy_use)
	if dummy_use.card then return true end

	if peach_num <= self.player:getLostHp() then return true end

	if peach_num > self.player:getLostHp() then
		for _, friend in ipairs(self.friends) do
			if self:isWeak(friend) then return true end
		end
	end

	if (judge.reason == "EightDiagram" or judge.reason == "bazhen") and
		self:isFriend(judge.who) and not self:isWeak(judge.who) then return true
	elseif judge.reason == "heg_tieqi" then return true
	elseif judge.reason == "heg_qianxi" then return true
	elseif judge.reason == "beige" then return true
	end

	return false
end



function SmartAI:AssistTarget()
	if sgs.ai_AssistTarget_off then return end
	local human_count, player = 0
	if not sgs.ai_AssistTarget then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getState() ~= "robot" then
				human_count = human_count + 1
				player = p
			end
		end
		if human_count == 1 and player then
			sgs.ai_AssistTarget = player
		else
			sgs.ai_AssistTarget_off = true
		end
	end
	player = sgs.ai_AssistTarget
	if player and not player:getAI() and player:isAlive() and self:isFriend(player) and player:objectName() ~= self.player:objectName() then return player end
	return
end

function SmartAI:findFriendsByType(prompt, player)
	player = player or self.player
	local friends = self:getFriendsNoself(player)
	if #friends < 1 then return false end
	if prompt == sgs.Friend_Draw then
		for _, friend in ipairs(friends) do
			if not self:needKongcheng(friend, true) then return true end
		end
	elseif prompt == sgs.Friend_Male then
		for _, friend in ipairs(friends) do
			if friend:isMale() then return true end
		end
	elseif prompt == sgs.Friend_MaleWounded then
		for _, friend in ipairs(friends) do
			if friend:isMale() and friend:isWounded() then return true end
		end
	elseif prompt == sgs.Friend_All then
		return true
	else
		global_room:writeToConsole(debug.traceback())
		return
	end
	return false
end

function hasBuquEffect(player)
	return player:hasShownSkill("heg_buqu") and player:getPile("heg_buqu"):length() <= 4
end


function SmartAI:doNotSave(player)
	if hasNiepanEffect(player) then return true end
	if player:hasFlag("AI_doNotSave") then return true end
	return false
end

function SmartAI:ImitateResult_DrawNCards(player, skills)
	if not player then self.room:writeToConsole(debug.traceback()) return 0 end
	if player:isSkipped(sgs.Player_Draw) then return 0 end
	skills = skills or player:getVisibleSkillList(true)
	local drawSkills = {}
	for _,skill in sgs.qlist(skills) do
		if player:hasShownSkill(skill:objectName()) then
			table.insert(drawSkills, skill:objectName())
		end
	end
	local count = 2
	if player:hasTreasure("JadeSeal") and player:hasShownOneGeneral() then count = count + 1 end
	if #drawSkills > 0 then
		for _,skillname in pairs(drawSkills) do
			if skillname == "tenyeartuxi" then return math.min(2, self.room:getOtherPlayers(player):length())
			elseif skillname == "shuangxiong" then return 1
			elseif skillname == "heg_zaiqi" then return math.floor(player:getLostHp() * 3 / 4)
			elseif skillname == "heg_luoyi" then count = count - 1
			elseif skillname == "heg_yingzi_sunce" then count = count + 1
			elseif skillname == "heg_yingzi_zhouyu" then count = count + 1
			elseif skillname == "haoshi" then count = count + 2 end
		end
	end
	return count
end

function SmartAI:willSkipPlayPhase(player, NotContains_Null)
	local player = player or self.player

	if player:isSkipped(sgs.Player_Play) then return true end
	if player:hasFlag("willSkipPlayPhase") then return true end

	local friend_null = 0
	local friend_snatch_dismantlement = 0
	local cp = self.room:getCurrent()
	if cp and self.player:objectName() == cp:objectName() and self.player:objectName() ~= player:objectName() and self:isFriend(player) then
		for _, hcard in sgs.qlist(self.player:getCards("he")) do
			if (isCard("Snatch", hcard, self.player) and self.player:distanceTo(player) == 1) or isCard("Dismantlement", hcard, self.player) then
				local trick = sgs.cloneCard(hcard:objectName(), hcard:getSuit(), hcard:getNumber())
				if self:hasTrickEffective(trick, player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
			end
		end
	end
	if not NotContains_Null then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self:isFriend(p, player) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
			if self:isEnemy(p, player) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
		end
	end
	if player:containsTrick("indulgence") then
		if self.player:hasSkill("heg_keji") or (player:hasShownSkill("qiaobian") and not player:isKongcheng()) then return false end
		if friend_null + friend_snatch_dismantlement > 1 then return false end
		return true
	end
	return false
end

function SmartAI:willSkipDrawPhase(player, NotContains_Null)
	local player = player or self.player
	if player:isSkipped(sgs.Player_Draw) then return true end

	local friend_null = 0
	local friend_snatch_dismantlement = 0
	local cp = self.room:getCurrent()
	if not NotContains_Null then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self:isFriend(p, player) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
			if self:isEnemy(p, player) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
		end
	end
	if cp and self.player:objectName() == cp:objectName() and self.player:objectName() ~= player:objectName() and self:isFriend(player) then
		for _, hcard in sgs.qlist(self.player:getCards("he")) do
			if (isCard("Snatch", hcard, self.player) and self.player:distanceTo(player) == 1) or isCard("Dismantlement", hcard, self.player) then
				local trick = sgs.cloneCard(hcard:objectName(), hcard:getSuit(), hcard:getNumber())
				if self:hasTrickEffective(trick, player) then friend_snatch_dismantlement = friend_snatch_dismantlement + 1 end
			end
		end
	end
	if player:containsTrick("supply_shortage") then
		if self.player:hasSkill("heg_shensu") or (player:hasShownSkill("qiaobian") and not player:isKongcheng()) then return false end
		if friend_null + friend_snatch_dismantlement > 1 then return false end
		return true
	end
	return false
end

function SmartAI:resetCards(cards, except)
	local result = {}
	for _, c in ipairs(cards) do
		if c:getEffectiveId() == except:getEffectiveId() then continue
		else table.insert(result, c) end
	end
	return result
end

function SmartAI:isValuableCard(card, player)
	player = player or self.player
	if (isCard("Peach", card, player) and getCardsNum("Peach", player, self.player) <= 2)
		or (self:isWeak(player) and isCard("Analeptic", card, player))
		or (player:getPhase() ~= sgs.Player_Play
			and ((isCard("Nullification", card, player) and getCardsNum("Nullification", player, self.player) < 2 and player:hasShownSkill("heg_jizhi"))
				or (isCard("Jink", card, player) and getCardsNum("Jink", player, self.player) < 2)))
		or (player:getPhase() == sgs.Player_Play and isCard("ExNihilo", card, player) and not player:isLocked(card)) then
		return true
	end
	local dangerous = self:getDangerousCard(player)
	if dangerous and card:getEffectiveId() == dangerous then return true end
	local valuable = self:getValuableCard(player)
	if valuable and card:getEffectiveId() == valuable then return true end
end

function SmartAI:cantbeHurt(player, from, damageNum)
	from = from or self.player
	damageNum = damageNum or 1
	if not player then self.room:writeToConsole(debug.traceback()) return end

	if player:hasShownSkill("heg_duanchang") and not player:isLord() and #(self:getFriendsNoself(player)) > 0 and player:getHp() <= 1 then
		if not (from:getMaxHp() == 3 and from:getArmor() and from:getDefensiveHorse()) then
			if from:getMaxHp() <= 3 or (from:isLord() and self:isWeak(from)) then return true end
		end
	end
	if player:hasShownSkill("heg_tianxiang") and getKnownCard(player, self.player, "diamond|club", false) < player:getHandcardNum() then
		local peach_num = self.player:objectName() == from:objectName() and self:getCardsNum("Peach") or getCardsNum("Peach", from, self.player)
		local dyingfriend = 0
		for _, friend in ipairs(self:getFriends(from)) do
			if friend:getHp() < 2 and peach_num == 0 then
				dyingfriend = dyingfriend + 1
			end
		end
		if dyingfriend > 0 and player:getHandcardNum() > 0 then
			return true
		end
	end
	if player:hasShownSkill("heg_hengzheng") and player:getHandcardNum() ~= 0 and player:getHp() - damageNum == 1
		and from:getNextAlive():objectName() == player:objectName() then
		if (player == self.player and sgs.ai_skill_invoke.heg_hengzheng(self)) then return true end
	end
	return false
end

function SmartAI:getGuixinValue(player)
	if player:isAllNude() then return 0 end
	local card_id = self:askForCardChosen(player, "hej", "dummy")
	if self:isEnemy(player) then
		for _, card in sgs.qlist(player:getJudgingArea()) do
			if card:getEffectiveId() == card_id then
				if card:isKindOf("Lightning") then
					if self:hasWizard(self.enemies, true) then return 0.8
					elseif self:hasWizard(self.friends, true) then return 0.4
					else return 0.5 * (#self.friends) / (#self.friends + #self.enemies) end
				else
					return -0.2
				end
			end
		end
		for i = 0, 3 do
			local card = player:getEquip(i)
			if card and card:getEffectiveId() == card_id then
				if card:isKindOf("Armor") and self:needToThrowArmor(player) then return 0 end
				local value = 0
				if self:getDangerousCard(player) == card_id then value = 1.5
				elseif self:getValuableCard(player) == card_id then value = 1.1
				elseif i == 1 then value = 1
				elseif i == 2 then value = 0.8
				elseif i == 0 then value = 0.7
				elseif i == 3 then value = 0.5
				end
				if sgs.originalHegemonyHasShownSkills(player, sgs.lose_equip_skill) or self:doNotDiscard(player, "e", true) then value = value - 0.2 end
				return value
			end
		end
		if self:needKongcheng(player) and player:getHandcardNum() == 1 then return 0 end
		if not self:hasLoseHandcardEffective() then return 0.1
		else
			local index = sgs.originalHegemonyHasShownSkills(player, "jijiu|qingnang|nosleiji|jieyin|beige|heg_kanpo|liuli|qiaobian|heg_zhiheng|guidao|heg_tianxiang|lijian") and 0.7 or 0.6
			local value = 0.2 + index / (player:getHandcardNum() + 1)
			if self:doNotDiscard(player, "h", true) then value = value - 0.1 end
			return value
		end
	elseif self:isFriend(player) then
		for _, card in sgs.qlist(player:getJudgingArea()) do
			if card:getEffectiveId() == card_id then
				if card:isKindOf("Lightning") then
					if self:hasWizard(self.enemies, true) then return 1
					elseif self:hasWizard(self.friends, true) then return 0.8
					else return 0.4 * (#self.enemies) / (#self.friends + #self.enemies) end
				else
					return 1.5
				end
			end
		end
		for i = 0, 3 do
			local card = player:getEquip(i)
			if card and card:getEffectiveId() == card_id then
				if card:isKindOf("Armor") and self:needToThrowArmor(player) then return 0.9 end
				local value = 0
				if i == 1 then value = 0.1
				elseif i == 2 then value = 0.2
				elseif i == 0 then value = 0.25
				elseif i == 3 then value = 0.25
				end
				if sgs.originalHegemonyHasShownSkills(player, sgs.lose_equip_skill) then value = value + 0.1 end
				if player:hasShownSkill("heg_tuntian") then value = value + 0.1 end
				return value
			end
		end
		if self:needKongcheng(player, true) and player:getHandcardNum() == 1 then return 0.5
		elseif self:needKongcheng(player) and player:getHandcardNum() == 1 then return 0.3 end
		if not self:hasLoseHandcardEffective() then return 0.2
		else
			local index = sgs.originalHegemonyHasShownSkills(player, "jijiu|qingnang|nosleiji|jieyin|beige|heg_kanpo|liuli|qiaobian|heg_zhiheng|guidao|heg_tianxiang|lijian") and 0.5 or 0.4
			local value = 0.2 - index / (player:getHandcardNum() + 1)
			if player:hasShownSkill("heg_tuntian") then value = value + 0.1 end
			return value
		end
	end
	return 0.3
end


function SmartAI:willShowForAttack()
	if self.room:getMode() == "jiange_defense" then return true end
	if self.player:hasShownOneGeneral() then return true end
	if self.room:alivePlayerCount() < 3 then return true end

	local notshown, shown, f, e, eAtt = 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self:evaluateKingdom(p) == self:originalHegemonyOwnKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
	end

	local showRate = math.random() + f/20 + eAtt/10 + shown/20 + sgs.turncount/10

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end
	if firstShowReward and showRate > 0.9 then return true end

	if showRate < 0.8 then return false end
	if e < f or eAtt <= 0 then return false end

return true
end

function SmartAI:willShowForDefence()
	if self.room:getMode() == "jiange_defense" then return true end
	if self.player:hasShownOneGeneral() then return true end
	if self.room:alivePlayerCount() < 3 then return true end
	if self:isWeak() then return true end

	local notshown, shown, f, e, eAtt = 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self:evaluateKingdom(p) == self:originalHegemonyOwnKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
	end
	local showRate = math.random() - e/10 - self.player:getHp()/10 + shown/20 + sgs.turncount/10

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end
	if firstShowReward and showRate > 0.9 then return true end

	if showRate < 0.8 then return false end
	if f < 2 or not self:isWeak() then return false end

	return true
end

function SmartAI:willShowForMasochism()
	if self.room:getMode() == "jiange_defense" then return true end
	if self.player:hasShownOneGeneral() then return true end
	if self.room:alivePlayerCount() < 3 then return true end

	local notshown, shown, f, e, eAtt = 0, 0, 0, 0, 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if  not p:hasShownOneGeneral() then
			notshown = notshown + 1
		end
		if p:hasShownOneGeneral() then
			shown = shown + 1
			if self:evaluateKingdom(p) == self:originalHegemonyOwnKingdom() then
				f = f + 1
			else
				e = e + 1
				if self:isWeak(p) and p:getHp() == 1 and self.player:distanceTo(p) <= self.player:getAttackRange() then eAtt= eAtt + 1 end
			end
		end
	end
	local showRate = math.random() - self.player:getHp()/10 + e/10 + shown/20 + sgs.turncount/10

	local firstShowReward = false
	if sgs.GetConfig("RewardTheFirstShowingPlayer", true) then
		if shown == 0 then
			firstShowReward = true
		end
	end
	if firstShowReward and showRate > 0.9 then return true end

	if showRate < 0.2 then return false end
	if self.player:getLostHp() == 0 and self:getCardsNum("Peach") > 0 and showRate < 0.2 then return false end

	return true
end

function sgs.getReward(player)
	local x = 1
	if not sgs.isAnjiang(player) and player:getRole() == "careerist" then return 1 end
	for _, p in sgs.qlist(global_room:getOtherPlayers(player)) do
		if p:isFriendWith(player) then x = x + 1 end
	end
	return x
end



function sgs.PlayerList2SPlayerList(playerList)
	local splist = sgs.SPlayerList()
	for _, p in sgs.qlist(global_room:getAlivePlayers()) do
		if playerList:contains(p) then splist:append(p) end
	end
	return splist
end

function sgs.findPlayerByShownSkillName(skill_name)
	for _, p in sgs.qlist(global_room:getAllPlayers()) do
		if p:hasShownSkill(skill_name) then return p end
	end
end

function sgs.cardIsVisible(card, to, from)
	if not card or not to then return false end
	-- Simulating another player's choices must not grant that player's private hand.
	from = current_self and current_self.player or nil
	if from and to:objectName() == from:objectName() then return true end
	if card:hasFlag("visible") then return true end
	if from then
		local visibleFlag = string.format("visible_%s_%s", from:objectName(), to:objectName())
		if card:hasFlag(visibleFlag) then return true end
	end
	return false
end

function hasNiepanEffect(player)
	if player:hasShownSkill("heg_niepan") and player:getMark("@nirvana") > 0 then return true end
	if player:hasShownSkill("heg_jizhao") and player:getMark("@heg_jizhao") > 0 then return true end
end


-- xxyheaven strategy support; current Room lifecycle and visible knowledge remain authoritative.
for _, name in ipairs({"ai_skill_exchange", "ai_skill_cardschosen", "ai_skill_movecards",
    "ai_skill_transfercardchosen", "ai_need_damaged", "ai_nullification", "ai_fill_skill"}) do
    sgs[name] = sgs[name] or {}
end

-- Owner identities and publicly revealed identities are the only native reads.
-- Never copy an opponent's private general into another player's KnownBoth tag.
function sgs.originalHegemonyGeneral(player, head)
    local observer = current_self and current_self.player
    if observer and observer:objectName() == player:objectName() then
        local general = head and player:getActualGeneral1() or player:getActualGeneral2()
        return general or sgs.Sanguosha:getGeneral("anjiang")
    end
    if (head and player:hasShownGeneral1()) or (not head and player:hasShownGeneral2()) then
        local general = head and player:getGeneral() or player:getGeneral2()
        return general or sgs.Sanguosha:getGeneral("anjiang")
    end
    if observer then
        local names = observer:getTag("KnownBoth_" .. player:objectName()):toString():split("+")
        local name = names[head and 1 or 2]
        if name and name ~= "" then
            local general = sgs.Sanguosha:getGeneral(name)
            if general then return general end
        end
    end
    return sgs.Sanguosha:getGeneral("anjiang")
end

function SmartAI:hasKnownSkill(expression, player)
    player = player or self.player
    expression = type(expression) == "table" and expression.name or expression
    if type(expression) ~= "string" then return false end
    for _, group in ipairs(expression:split("|")) do
        local known = true
        for _, name in ipairs(group:split("+")) do
            local present = player:objectName() == self.player:objectName()
                and player:hasSkill(name) or player:hasShownSkill(name)
            if not present then known = false; break end
        end
        if known then return true end
    end
    return false
end

function SmartAI:trickIsEffective(card, to, from)
    -- Current native card legality owns the shared card rules.
    return self:hasTrickEffective(card, to, from)
end

function SmartAI:imitateDrawNCards(player)
    player = player or self.player
    if player:isSkipped(sgs.Player_Draw) then return 0 end
    local n = 2
    if player:hasTreasure("JadeSeal") and player:hasShownOneGeneral() then n = n + 1 end
    for _, name in ipairs({"yingzi", "heg_yingzi_sunce", "heg_yingzi_zhouyu", "heg_yingzi_flamemap"}) do
        if player:hasShownSkill(name) then n = n + 1 end
    end
    if player:hasShownSkill("heg_jieyue") then n = n + player:getMark("JieyueExtraDraw") * 3 end
    if player:hasShownSkill("heg_zisui") then n = n + player:getPile("&disloyalty"):length() end
    return n
end

function SmartAI:getMaxNumberCard(player, cards, observer)
	player = player or self.player

	if player:isKongcheng() then
		return nil
	end

	cards = cards or player:getHandcards()
	observer = observer or self.player

	local max_card, max_point = nil, 0
	for _, card in sgs.qlist(cards) do
		if (player:objectName() == self.player:objectName() and not self:isValuableCard(card)) or sgs.cardIsVisible(card, player, observer) then
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		end
	end
	if player:objectName() == self.player:objectName() and not max_card then
		for _, card in sgs.qlist(cards) do
			local point = card:getNumber()
			if point > max_point then
				max_point = point
				max_card = card
			end
		end
	end

	if player:objectName() ~= self.player:objectName() then return max_card end

	if player:hasShownSkill("tianyi") and max_point > 0 then
		for _, card in sgs.qlist(cards) do
			if card:getNumber() == max_point and not isCard("Slash", card, player) then
				return card
			end
		end
	end

	return max_card
end

function SmartAI:getMinNumberCard(player, cards, observer)
	player = player or self.player

	if player:isKongcheng() then
		return nil
	end

	cards = cards or player:getHandcards()
	observer = observer or self.player

	local min_card, min_point = nil, 14
	for _, card in sgs.qlist(cards) do
		if player:objectName() == self.player:objectName() or sgs.cardIsVisible(card, player, observer) then
			local point = card:getNumber()
			if point < min_point then
				min_point = point
				min_card = card
			end
		end
	end

	return min_card
end

function SmartAI:getReward(player)
	if self.player:getRole() == "careerist"
	or (sgs.originalHegemonyGeneral(self.player, true):getKingdom() == "careerist" and self.player:hasSkill("heg_shilu")) then
		return 3
	end
	if not sgs.isAnjiang(player) and player:getRole() == "careerist" then return 1 end
	local x = 1
	for _, p in sgs.qlist(global_room:getOtherPlayers(player)) do
		if p:isFriendWith(player) then x = x + 1 end
	end
	return x
end

function SmartAI:getJiemingDrawNum(player)
	local max_x = 0
	for _, friend in ipairs(self:getFriends(player)) do
		local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
		if x > max_x then
			max_x = x
		end
	end
	return max_x
end

function SmartAI:hasKnownSkills(skill_names, player)
	player = player or self.player
	if type(player) == "table" then
		for _, p in ipairs(player) do
			if self:hasKnownSkill(skill_names, p) then return true end
		end
		return false
	end
	return self:hasKnownSkill(skill_names, player)
end

function SmartAI:needDamagedEffects(to, from, isSlash)
	from = from or self.room:getCurrent() or self.player
	to = to or self.player

	if isSlash then
		if from:hasWeapon("IceSword") and to:getCardCount(true) > 1 and not self:isFriend(from, to) then
			return false
		end
	end

	if from:objectName() ~= to:objectName() and self:hasHeavySlashDamage(from, nil, to) then return false end

	if sgs.isGoodHp(to, self.player) then
		for _, askill in sgs.qlist(to:getVisibleSkillList(true)) do
			local callback = sgs.ai_need_damaged[askill:objectName()]
			if type(callback) == "function" and callback(self, from, to) then return true end
		end
	end
	return false
end

function SmartAI:askForExchange(reason,pattern,max_num,min_num,expand_pile)
	min_num = min_num or 0
	local callback = sgs.ai_skill_exchange[reason]
	if type(callback) == "function" then
		local result = callback(self,pattern,max_num,min_num,expand_pile)
		if type(result) == "number" then
			return {result}
		elseif type(result) == "table" then
			return result
		else
			assert(false,"the Exchange result should be a number or a table")
			return {}
		end
	end
	return {}
end

function SmartAI:askForCardsChosen(who, flags, reason, min_num, max_num, method, disable_list)
	disable_list = disable_list or {}

	local cardschosen = sgs.ai_skill_cardschosen[string.gsub(reason, "%-", "_")]
    local result
    if type(cardschosen) == "function" then
        result = cardschosen(self, who, flags, min_num, max_num, method)
        if type(result) == "table" then return result end
    elseif type(cardschosen) == "table" then
        sgs.ai_skill_cardchosen[string.gsub(reason, "%-", "_")] = nil
        return cardschosen
    end
	if (min_num == 1 and max_num == 1) then
		local card_id = self:askForCardChosen(who, flags, reason, method, disable_list)
		if (card_id ~= -1) then
			return {card_id}
		end
	end
    return {}
end

function SmartAI:askForMoveCards(upcards, downcards, reason, pattern, min_num, max_num)
	local callback = sgs.ai_skill_movecards[reason]
	if type(callback) == "function" then
		local top, down = callback(self, upcards, downcards, min_num, max_num)
		local res1, res2 = {}, {}
		if top then
			if type(top) == "number" then res1 = {top}
			elseif type(top) == "table" then
				res1 = top
			end
		end
		if down then
			if type(down) == "number" then res2 = {down}
			elseif type(down) == "table" then
				res2 = down
			end
		end
		if #upcards + #downcards == #res1 + #res2 then
			return res1, res2
		end
	end
	return {}, {}
end

function SmartAI:askForTransferFieldCards(targets, reason, equipArea, judgingArea)
	local callback = sgs.ai_skill_transfercardchosen[reason]
	if type(callback) == "function" then
		local card = callback(self, targets, equipArea, judgingArea)
		if type(card) == "number" then return card
		elseif card then return card:getEffectiveId() end
	end
	return -1
end

function HasBuquEffect(player)
	return player:hasShownSkill("heg_buqu") and player:getPile("scars"):length() <= 4
end

function HasNiepanEffect(player)
	if player:hasShownSkill("heg_niepan") and player:getMark("@nirvana") > 0 then return true end
	if player:hasShownSkill("heg_jizhao") and player:getMark("@heg_jizhao") > 0 then return true end
end

function HasRuleSkill(skill_name, player)
	local rule_skills = sgs.rule_skill:split("|")
	if table.contains(rule_skills, skill_name) then
		if skill_name == "heg_aozhan" then
			return player:getMark("GlobalBattleRoyalMode") > 0
		elseif skill_name == "heg_companion" then
			return player:getMark("@companion") > 0
		elseif skill_name == "heg_halfmaxhp" then
			return player:getMark("@halfmaxhp") > 0
		elseif skill_name == "heg_firstshow" then
			return player:getMark("@firstshow") > 0
		elseif skill_name == "heg_careerman" then
			return player:getMark("@careerist") > 0
		else
			return true
		end
	end
	return false
end

-- Donor immutable skill groupings.

	sgs.ai_type_name = {"SkillCard", "BasicCard", "TrickCard", "EquipCard"}
	sgs.priority_skill = 	"jianan|heg_yiji|mobilefangzhu|tenyeartuxi|heg_luoshen|heg_jixi|heg_qice|heg_jieyue|heg_zaoyun|" ..
							"heg_shouyue|heg_paoxiao|heg_jizhi|heg_tieqi|heg_liegong|heg_jili|heg_xuanhuo|heg_tongdu|" ..
							"heg_jiahe|heg_xiaoji|heg_guose|heg_tianxiang|heg_fanjian|heg_buqu|heg_xuanlue|heg_diaodu|" ..
							"heg_hongfa|jijiu|heg_luanji|wansha|tenyearjianchu|heg_qianhuan|heg_yigui|heg_fudi|heg_yongsi|"..
							"heg_paiyi|heg_suzhi|heg_shilu|heg_huaiyi|heg_chenglve|heg_congcha|heg_jinfa|heg_lixia|"..
							"heg_zhukou|heg_jinghe|heg_guowu|heg_shenwei|heg_wanggui|heg_boyan|heg_kuangcai|"..
							"heg_miewu|heg_guishu|heg_sidi|heg_danlao|heg_wanglie|heg_zhuidu"
	sgs.masochism_skill = "heg_yiji|nosfankui|heg_jieming|heg_ganglie|mobilefangzhu|heg_hengjiang|nosjianxiong|heg_qianhuan|heg_zhiyu|heg_jihun|heg_fudi|" ..
						  "heg_bushi|heg_shicai|heg_quanji|heg_zhaoxin|heg_fankui_simazhao|heg_wanggui|heg_sidi"
	sgs.defense_skill = "qingguo|heg_longdan|heg_kongcheng|heg_niepan|bazhen|heg_kanpo|xiangle|heg_tianxiang|liuli|heg_qianxun|nosleiji|heg_duanchang|beige|heg_weimu|" ..
						"heg_tuntian|heg_shoucheng|heg_yicheng|heg_qianhuan|heg_jizhao|heg_wanwei|heg_enyuan|heg_buyi|heg_keshou|heg_qiuan|heg_biluan|jiancai|heg_aocai|" ..
						"heg_xibing|heg_zhente|heg_qiao|heg_shejian|heg_yusui|heg_deshao|heg_yuanyu|heg_mingzhe|heg_jilei|heg_shigong"
	sgs.usefull_skill = "tiandu|qiaobian|xingshang|xiaoguo|tenyearwusheng|guanxing|nosqicai|heg_jizhi|tenyearkuanggu|heg_lianhuan|heg_huoshou|heg_juxiang|shushen|heg_zhiheng|heg_keji|" ..
						"heg_duoshi|heg_xiaoji|hongyan|haoshi|guzheng|zhijian|shuangxiong|guidao|guicai|xiongyi|mashu|lirang|heg_yizhi|heg_shengxi|" ..
						"heg_xunxun|heg_wangxi|heg_yingyang|heg_hunshang|biyue"
	sgs.attack_skill = "heg_paoxiao|heg_duanliang|quhu|rende|heg_tieqi|heg_liegong|heg_huoji|heg_lieren|qixi|heg_kurou|heg_fanjian|heg_guose|tianyi|dimeng|heg_duanbing|heg_fenxun|wushuang|" ..
						"lijian|heg_luanji|kuangfu|heg_huoshui|heg_qingcheng|heg_tiaoxin|heg_shangyi|heg_jiang|heg_chuanxin"
	sgs.drawcard_skill = "heg_yingzi_sunce|heg_yingzi_zhouyu|haoshi|heg_yingzi_flamemap|heg_haoshi_flamemap|heg_shelie|heg_jieyue|heg_congcha|heg_zisui"
	sgs.force_slash_skill = "heg_tieqi|heg_tieqi_xh|heg_liegong|heg_liegong_xh|wushuang|tenyearjianchu|heg_qianxi|heg_wushuang_lvlingqi|heg_wanglie"
	sgs.wizard_skill = 		"guicai|guidao|tiandu|heg_zhuwei|heg_huanshi"
	sgs.wizard_harm_skill = "guicai|guidao"
	sgs.lose_equip_skill = 	"heg_xiaoji|heg_xuanlue"
	sgs.need_kongcheng = 	"heg_kongcheng"
	sgs.save_skill = 		"jijiu|heg_yigui|heg_buyi|heg_aocai"
	sgs.exclusive_skill = 	"heg_duanchang|heg_buqu"
	sgs.throw_crossbow_skill = "nosfankui|heg_ganglie|heg_fankui_simazhao|heg_qiao"
	sgs.drawpeach_skill =	"tenyeartuxi|qiaobian|heg_elitegeneralflag|heg_huaiyi|heg_jinfa|heg_daoshu|heg_weimeng"
	sgs.recover_skill =		"rende|tenyearkuanggu|heg_zaiqi|jieyin|shenzhi|heg_buqu|heg_buyi"
	sgs.Active_cardneed_skill =		"qiaobian|heg_duanliang|rende|heg_paoxiao|heg_guose|qixi|jieyin|heg_zhiheng|tianyi|heg_duoshi|dimeng|heg_luanji|shuangxiong|lirang|" ..
									"heg_qice|heg_jili|heg_fengshix|heg_zaoyun|heg_huaiyi|heg_shilu|heg_baolie|heg_lianpian|heg_tongdu|heg_juejue|heg_duannian|heg_jinghe|heg_yanzheng|heg_kuangcai|heg_guishu"
	sgs.notActive_cardneed_skill =	"guicai|heg_guicai|xiaoguo|heg_kanpo|guidao|beige|jijiu|liuli|heg_tianxiang|heg_zhendu|heg_qianhuan|heg_keshou|heg_fudi|heg_shejian|heg_huanshi"
	sgs.cardneed_skill =  	sgs.Active_cardneed_skill .. "|" .. sgs.notActive_cardneed_skill
	sgs.use_lion_skill =	"heg_duanliang|guicai|guidao|lijian|heg_qingcheng|heg_zhiheng|qixi|heg_fenxun|heg_kurou|heg_diaogui|heg_quanji|heg_jinfa|heg_xishe"
	sgs.need_equip_skill = 	"heg_shensu|heg_huyuan|beige|heg_qingcheng|heg_xiaoji|heg_xuanlue|heg_diaodu|heg_biluan|heg_xishe"
	sgs.judge_reason =		"bazhen|EightDiagram|supply_shortage|indulgence|lightning|nosleiji|beige|heg_tieqi|heg_luoshen|heg_ganglie|heg_tuntian"

	sgs.rule_skill = "transfer|heg_aozhan|heg_companion|heg_halfmaxhp|heg_firstshow|heg_careerman|showhead|showdeputy"

-- Immutable donor ai-selector/general-value.txt; no per-player secrets.
sgs.general_value = {
    ["heg_lord_caocao"] = 11.0,
    ["heg_caocao"] = 7.0,
    ["heg_simayi"] = 8.0,
    ["heg_xiahoudun"] = 7.0,
    ["heg_zhangliao"] = 8.0,
    ["heg_xuchu"] = 6.0,
    ["heg_guojia"] = 9.0,
    ["heg_zhenji"] = 9.0,
    ["heg_xiahouyuan"] = 6.0,
    ["heg_zhanghe"] = 6.0,
    ["heg_xuhuang"] = 6.0,
    ["heg_caoren"] = 5.0,
    ["heg_dianwei"] = 7.0,
    ["heg_xunyu"] = 7.0,
    ["heg_caopi"] = 10.0,
    ["heg_yuejin"] = 5.0,
    ["heg_dengai"] = 7.0,
    ["heg_caohong"] = 4.0,
    ["heg_lidian"] = 8.0,
    ["heg_zangba"] = 4.0,
    ["heg_xunyou"] = 9.0,
    ["heg_bianhuanghou"] = 5.0,
    ["heg_cuiyanmaojie"] = 5.0,
    ["heg_yujin"] = 9.0,
    ["heg_dongzhao"] = 8.0,
    ["heg_zhuling"] = 6.0,
    ["heg_lord_liubei"] = 11.0,
    ["heg_liubei"] = 7.0,
    ["heg_guanyu"] = 8.0,
    ["heg_zhangfei"] = 9.0,
    ["heg_zhugeliang"] = 5.0,
    ["heg_zhaoyun"] = 5.0,
    ["heg_machao"] = 9.0,
    ["heg_huangyueying"] = 8.0,
    ["heg_huangzhong"] = 7.0,
    ["heg_weiyan"] = 7.0,
    ["heg_pangtong"] = 8.0,
    ["heg_wolong"] = 7.0,
    ["heg_liushan"] = 6.0,
    ["heg_menghuo"] = 7.0,
    ["heg_zhurong"] = 6.0,
    ["heg_ganfuren"] = 6.0,
    ["heg_jiangwei"] = 5.0,
    ["heg_jiangwanfeiyi"] = 8.0,
    ["heg_mifuren"] = 4.0,
    ["heg_madai"] = 7.0,
    ["heg_shamoke"] = 9.0,
    ["heg_masu"] = 5.0,
    ["heg_wangping"] = 10.0,
    ["heg_fazheng"] = 10.0,
    ["heg_xushu"] = 6.0,
    ["heg_liuba"] = 8.0,
    ["heg_lord_sunquan"] = 11.0,
    ["heg_sunquan"] = 7.0,
    ["heg_ganning"] = 7.0,
    ["heg_lvmeng"] = 7.0,
    ["heg_huanggai"] = 6.0,
    ["heg_zhouyu"] = 8.0,
    ["heg_daqiao"] = 8.0,
    ["heg_luxun"] = 7.0,
    ["heg_sunshangxiang"] = 9.0,
    ["heg_sunjian"] = 8.0,
    ["heg_xiaoqiao"] = 8.0,
    ["heg_taishici"] = 6.0,
    ["heg_zhoutai"] = 10.0,
    ["heg_lusu"] = 7.0,
    ["heg_erzhang"] = 7.0,
    ["heg_dingfeng"] = 6.0,
    ["heg_jiangqin"] = 5.0,
    ["heg_xusheng"] = 5.0,
    ["heg_sunce"] = 6.0,
    ["heg_chenwudongxi"] = 4.0,
    ["heg_lingtong"] = 9.0,
    ["heg_lvfan"] = 10.0,
    ["heg_wuguotai"] = 7.0,
    ["heg_lukang"] = 5.0,
    ["heg_wujing"] = 4.0,
    ["heg_zhugeke"] = 6.0,
    ["heg_lord_zhangjiao"] = 11.0,
    ["heg_huatuo"] = 9.0,
    ["heg_lvbu"] = 7.0,
    ["heg_diaochan"] = 7.0,
    ["heg_yuanshao"] = 9.0,
    ["heg_yanliangwenchou"] = 6.0,
    ["heg_jiaxu"] = 8.0,
    ["heg_pangde"] = 8.0,
    ["heg_zhangjiao"] = 6.0,
    ["heg_caiwenji"] = 7.0,
    ["heg_mateng"] = 8.0,
    ["heg_kongrong"] = 7.0,
    ["heg_jiling"] = 5.0,
    ["heg_tianfeng"] = 5.0,
    ["heg_panfeng"] = 6.0,
    ["heg_zoushi"] = 5.0,
    ["heg_yuji"] = 8.0,
    ["heg_hetaihou"] = 7.0,
    ["heg_dongzhuo"] = 6.0,
    ["heg_zhangren"] = 5.0,
    ["heg_lijueguosi"] = 7.0,
    ["heg_new_zuoci"] = 10.0,
    ["heg_yuanshu"] = 8.0,
    ["heg_zhangxiu"] = 8.0,
    ["heg_yanbaihu"] = 4.0,
    ["heg_huangzu"] = 7.0,
    ["heg_zhonghui"] = 9.0,
    ["heg_simazhao"] = 9.0,
    ["heg_sunchen"] = 7.0,
    ["heg_gongsunyuan"] = 8.0,
    ["heg_mengda"] = 6.0,
    ["heg_tangzi"] = 7.0,
    ["heg_zhanglu"] = 6.0,
    ["heg_mifangfushiren"] = 5.0,
    ["heg_liuqi"] = 7.0,
    ["heg_shixie"] = 4.0,
    ["heg_xuyou"] = 9.0,
    ["heg_xiahouba"] = 6.0,
    ["heg_panjun"] = 8.0,
    ["heg_wenqin"] = 8.0,
    ["heg_pengyang"] = 7.0,
    ["heg_sufei"] = 5.0,
    ["heg_jianggan"] = 7.0,
    ["heg_zhouyi"] = 8.0,
    ["heg_nanhualaoxian"] = 9.0,
    ["heg_lvlingqi"] = 9.0,
    ["heg_huaxin"] = 9.0,
    ["heg_luyusheng"] = 6.0,
    ["heg_zongyux"] = 5.0,
    ["heg_miheng"] = 8.0,
    ["heg_fengxi"] = 7.0,
    ["heg_dengzhi"] = 7.0,
    ["heg_xunchen"] = 7.0,
    ["heg_yanghu"] = 7.0,
    ["heg_beimihu"] = 8.0,
    ["heg_caozhen"] = 8.0,
    ["heg_liaohua"] = 7.0,
    ["heg_zhugejin"] = 7.0,
    ["heg_quancong"] = 7.0,
    ["heg_guohuai"] = 7.0,
    ["heg_yangxiu"] = 7.0,
    ["heg_zumao"] = 5.0,
    ["heg_fuwan"] = 7.0,
    ["heg_chendao"] = 8.0,
    ["heg_tianyu"] = 7.0,
    ["heg_maliang"] = 6.0,
    ["heg_duyu"] = 9.0,
}

-- Immutable donor ai-selector/pair-value.txt; no per-player secrets.
sgs.general_pair_value = {
    ["heg_lord_caocao+heg_yujin"] = 25.0,
    ["heg_yujin+heg_lord_caocao"] = 24.0,
    ["heg_guojia+heg_xiahoudun"] = 24.0,
    ["heg_xiahoudun+heg_guojia"] = 23.0,
    ["heg_guojia+heg_xuyou"] = 24.0,
    ["heg_xuyou+heg_guojia"] = 23.0,
    ["heg_zhenji+heg_guojia"] = 23.0,
    ["heg_guojia+heg_zhenji"] = 23.0,
    ["heg_zhenji+heg_simayi"] = 24.0,
    ["heg_simayi+heg_zhenji"] = 23.0,
    ["heg_zhenji+heg_zhangliao"] = 21.0,
    ["heg_zhangliao+heg_zhenji"] = 20.0,
    ["heg_zhenji+heg_zhenghe"] = 21.0,
    ["heg_zhenghe+heg_zhenji"] = 20.0,
    ["heg_caopi+heg_zhanghe"] = 19.0,
    ["heg_zhanghe+heg_caopi"] = 18.0,
    ["heg_caopi+heg_lidian"] = 25.0,
    ["heg_lidian+heg_caopi"] = 24.0,
    ["heg_lidian+heg_caocao"] = 21.0,
    ["heg_caocao+heg_lidian"] = 21.0,
    ["heg_lidian+heg_mengda"] = 20.0,
    ["heg_mengda+heg_lidian"] = 20.0,
    ["heg_lidian+heg_xiahouba"] = 20.0,
    ["heg_xiahouba+heg_lidian"] = 20.0,
    ["heg_lidian+heg_zhuling"] = 20.0,
    ["heg_zhuling+heg_lidian"] = 20.0,
    ["heg_xunyou+heg_xunyu"] = 23.0,
    ["heg_xunyu+heg_xunyou"] = 22.0,
    ["heg_xunyou+heg_xiahouyuan"] = 24.0,
    ["heg_xiahouyuan+heg_xunyou"] = 23.0,
    ["heg_xunyu+heg_xiahouyuan"] = 18.0,
    ["heg_xiahouyuan+heg_xunyu"] = 18.0,
    ["heg_dengai+heg_simayi"] = 22.0,
    ["heg_simayi+heg_dengai"] = 21.0,
    ["heg_dengai+heg_guojia"] = 23.0,
    ["heg_guojia+heg_dengai"] = 22.0,
    ["heg_yujin+heg_zhangliao"] = 23.0,
    ["heg_zhangliao+heg_yujin"] = 23.0,
    ["heg_yujin+heg_zhanghe"] = 22.0,
    ["heg_zhanghe+heg_yujin"] = 21.0,
    ["heg_yujin+heg_xuchu"] = 22.0,
    ["heg_xuchu+heg_yujin"] = 21.0,
    ["heg_yujin+heg_xiahouba"] = 22.0,
    ["heg_xiahouba+heg_yujin"] = 21.0,
    ["heg_jianggan+heg_dongzhao"] = 21.0,
    ["heg_dongzhao+heg_jianggan"] = 22.0,
    ["heg_jianggan+heg_yujin"] = 21.0,
    ["heg_yujin+heg_jianggan"] = 22.0,
    ["heg_jianggan+heg_cuiyanmaojie"] = 15.0,
    ["heg_cuiyanmaojie+heg_jianggan"] = 15.0,
    ["heg_huaxin+heg_xuyou"] = 24.0,
    ["heg_xuyou+heg_huaxin"] = 24.0,
    ["heg_caozhen+heg_dengai"] = 24.0,
    ["heg_dengai+heg_caozhen"] = 23.0,
    ["heg_lord_liubei+heg_fazheng"] = 26.0,
    ["heg_fazheng+heg_lord_liubei"] = 25.0,
    ["heg_huangyueying+heg_zhangfei"] = 23.0,
    ["heg_zhangfei+heg_huangyueying"] = 22.0,
    ["heg_huangyueying+heg_wolong"] = 22.0,
    ["heg_wolong+heg_huangyueying"] = 21.0,
    ["heg_huangyueying+heg_guanyu"] = 21.0,
    ["heg_guanyu+heg_huangyueying"] = 20.0,
    ["heg_huangyueying+heg_liuba"] = 23.0,
    ["heg_liuba+heg_huangyueying"] = 22.0,
    ["heg_zhangfei+heg_guanyu"] = 25.0,
    ["heg_guanyu+heg_zhangfei"] = 24.0,
    ["heg_zhangfei+heg_weiyan"] = 24.0,
    ["heg_weiyan+heg_zhangfei"] = 23.0,
    ["heg_zhangfei+heg_shamoke"] = 24.0,
    ["heg_shamoke+heg_zhangfei"] = 23.0,
    ["heg_wolong+heg_pangtong"] = 21.0,
    ["heg_pangtong+heg_wolong"] = 20.0,
    ["heg_weiyan+heg_madai"] = 23.0,
    ["heg_madai+heg_weiyan"] = 22.0,
    ["heg_weiyan+heg_huangzhong"] = 22.0,
    ["heg_huangzhong+heg_weiyan"] = 22.0,
    ["heg_machao+heg_weiyan"] = 24.0,
    ["heg_weiyan+heg_machao"] = 23.0,
    ["heg_zhugeliang+heg_jiangwei"] = 21.0,
    ["heg_jiangwei+heg_zhugeliang"] = 20.0,
    ["heg_zhugeliang+heg_zongyux"] = 18.0,
    ["heg_zongyux+heg_zhugeliang"] = 18.0,
    ["heg_liushan+heg_jiangwei"] = 21.0,
    ["heg_jiangwei+heg_liushan"] = 20.0,
    ["heg_liushan+heg_xiahouba"] = 21.0,
    ["heg_xiahouba+heg_liushan"] = 20.0,
    ["heg_jiangwei+heg_xiahouba"] = 20.0,
    ["heg_xiahouba+heg_jiangwei"] = 19.0,
    ["heg_jiangwanfeiyi+heg_liubei"] = 23.0,
    ["heg_liubei+heg_jiangwanfeiyi"] = 23.0,
    ["heg_jiangwanfeiyi+heg_liushan"] = 23.0,
    ["heg_liushan+heg_jiangwanfeiyi"] = 22.0,
    ["heg_jiangwanfeiyi+heg_liuqi"] = 22.0,
    ["heg_liuqi+heg_jiangwanfeiyi"] = 21.0,
    ["heg_jiangwanfeiyi+heg_liuba"] = 23.0,
    ["heg_liuba+heg_jiangwanfeiyi"] = 22.0,
    ["heg_jiangwanfeiyi+heg_zongyux"] = 20.0,
    ["heg_zongyux+heg_jiangwanfeiyi"] = 20.0,
    ["heg_masu+heg_menghuo"] = 18.0,
    ["heg_menghuo+heg_masu"] = 18.0,
    ["heg_masu+heg_zhurong"] = 18.0,
    ["heg_zhurong+heg_masu"] = 18.0,
    ["heg_masu+heg_xushu"] = 21.0,
    ["heg_xushu+heg_masu"] = 20.0,
    ["heg_shamoke+heg_wolong"] = 21.0,
    ["heg_wolong+heg_shamoke"] = 21.0,
    ["heg_shamoke+heg_liuba"] = 21.0,
    ["heg_liuba+heg_shamoke"] = 20.0,
    ["heg_ganfuren+heg_pangtong"] = 21.0,
    ["heg_pangtong+heg_ganfuren"] = 20.0,
    ["heg_fazheng+heg_wangping"] = 25.0,
    ["heg_wangping+heg_fazheng"] = 24.0,
    ["heg_fazheng+heg_pangtong"] = 23.0,
    ["heg_pangtong+heg_fazheng"] = 22.0,
    ["heg_fazheng+heg_liubei"] = 22.0,
    ["heg_liubei+heg_fazheng"] = 22.0,
    ["heg_fazheng+heg_wolong"] = 20.0,
    ["heg_wolong+heg_fazheng"] = 19.0,
    ["heg_fazheng+heg_ganfuren"] = 20.0,
    ["heg_ganfuren+heg_fazheng"] = 20.0,
    ["heg_fazheng+heg_liuba"] = 22.0,
    ["heg_liuba+heg_fazheng"] = 21.0,
    ["heg_dengzhi+heg_wolong"] = 20.0,
    ["heg_wolong+heg_dengzhi"] = 20.0,
    ["heg_dengzhi+heg_ganfuren"] = 17.0,
    ["heg_ganfuren+heg_dengzhi"] = 18.0,
    ["heg_liaohua+heg_liushan"] = 22.0,
    ["heg_liushan+heg_liaohua"] = 22.0,
    ["heg_liaohua+heg_pengyang"] = 22.0,
    ["heg_pengyang+heg_liaohua"] = 21.0,
    ["heg_liaohua+heg_dengzhi"] = 20.0,
    ["heg_dengzhi+heg_liaohua"] = 20.0,
    ["heg_lord_sunquan+heg_sunshangxiang"] = 26.0,
    ["heg_sunshangxiang+heg_lord_sunquan"] = 25.0,
    ["heg_ganning+heg_lingtong"] = 23.0,
    ["heg_lingtong+heg_ganning"] = 22.0,
    ["heg_ganning+heg_sufei"] = 22.0,
    ["heg_sufei+heg_ganning"] = 21.0,
    ["heg_sunshangxiang+heg_lingtong"] = 24.0,
    ["heg_lingtong+heg_sunshangxiang"] = 23.0,
    ["heg_sunshangxiang+heg_ganning"] = 23.0,
    ["heg_ganning+heg_sunshangxiang"] = 22.0,
    ["heg_sunshangxiang+heg_luxun"] = 25.0,
    ["heg_luxun+heg_sunshangxiang"] = 24.0,
    ["heg_sunshangxiang+heg_daqiao"] = 22.0,
    ["heg_daqiao+heg_sunshangxiang"] = 21.0,
    ["heg_sunshangxiang+heg_wenqin"] = 22.0,
    ["heg_wenqin+heg_sunshangxiang"] = 21.0,
    ["heg_zhoutai+heg_zhouyu"] = 23.0,
    ["heg_zhouyu+heg_zhoutai"] = 22.0,
    ["heg_zhoutai+heg_lusu"] = 23.0,
    ["heg_lusu+heg_zhoutai"] = 22.0,
    ["heg_zhoutai+heg_sunce"] = 23.0,
    ["heg_sunce+heg_zhoutai"] = 22.0,
    ["heg_zhoutai+heg_sunjian"] = 23.0,
    ["heg_sunjian+heg_zhoutai"] = 22.0,
    ["heg_zhoutai+heg_sufei"] = 21.0,
    ["heg_sufei+heg_zhoutai"] = 21.0,
    ["heg_xiaoqiao+heg_sunce"] = 22.0,
    ["heg_sunce+heg_xiaoqiao"] = 21.0,
    ["heg_xiaoqiao+heg_lukang"] = 22.0,
    ["heg_lukang+heg_xiaoqiao"] = 22.0,
    ["heg_daqiao+heg_sunce"] = 22.0,
    ["heg_sunce+heg_daqiao"] = 21.0,
    ["heg_huanggai+heg_taishici"] = 21.0,
    ["heg_taishici+heg_huanggai"] = 21.0,
    ["heg_huanggai+heg_dingfeng"] = 21.0,
    ["heg_dingfeng+heg_huanggai"] = 21.0,
    ["heg_sunce+heg_taishici"] = 21.0,
    ["heg_taishici+heg_sunce"] = 20.0,
    ["heg_zhouyu+heg_sunce"] = 22.0,
    ["heg_sunce+heg_zhouyu"] = 21.0,
    ["heg_zhouyu+heg_sunjian"] = 23.0,
    ["heg_sunjian+heg_zhouyu"] = 22.0,
    ["heg_sunjian+heg_sunce"] = 23.0,
    ["heg_sunce+heg_sunjian"] = 22.0,
    ["heg_lingtong+heg_wenqin"] = 23.0,
    ["heg_wenqin+heg_lingtong"] = 22.0,
    ["heg_lvfan+heg_lingtong"] = 24.0,
    ["heg_lingtong+heg_lvfan"] = 23.0,
    ["heg_lvfan+heg_sunshangxiang"] = 25.0,
    ["heg_sunshangxiang+heg_lvfan"] = 24.0,
    ["heg_lvfan+heg_sunjian"] = 24.0,
    ["heg_sunjian+heg_lvfan"] = 23.0,
    ["heg_lvfan+heg_lukang"] = 21.0,
    ["heg_lukang+heg_lvfan"] = 20.0,
    ["heg_zhouyi+heg_sunjian"] = 23.0,
    ["heg_sunjian+heg_zhouyi"] = 23.0,
    ["heg_zhouyi+heg_zhouyu"] = 23.0,
    ["heg_zhouyu+heg_zhouyi"] = 23.0,
    ["heg_zhouyi+heg_lvmeng"] = 22.0,
    ["heg_lvmeng+heg_zhouyi"] = 22.0,
    ["heg_zhouyi+heg_tangzi"] = 22.0,
    ["heg_tangzi+heg_zhouyi"] = 21.0,
    ["heg_zhouyi+heg_daqiao"] = 21.0,
    ["heg_daqiao+heg_zhouyi"] = 21.0,
    ["heg_zhouyi+heg_ganning"] = 21.0,
    ["heg_ganning+heg_zhouyi"] = 21.0,
    ["heg_luyusheng+heg_erzhang"] = 20.0,
    ["heg_erzhang+heg_luyusheng"] = 20.0,
    ["heg_fengxi+heg_sunjian"] = 22.0,
    ["heg_sunjian+heg_fengxi"] = 21.0,
    ["heg_zhugejin+heg_lukang"] = 22.0,
    ["heg_lukang+heg_zhugejin"] = 21.0,
    ["heg_lord_zhangjiao+heg_new_zuoci"] = 26.0,
    ["heg_new_zuoci+heg_lord_zhangjiao"] = 25.0,
    ["heg_yuanshao+heg_tianfeng"] = 23.0,
    ["heg_tianfeng+heg_yuanshao"] = 22.0,
    ["heg_yuanshao+heg_mateng"] = 24.0,
    ["heg_mateng+heg_yuanshao"] = 23.0,
    ["heg_yuanshao+heg_lijueguosi"] = 23.0,
    ["heg_lijueguosi+heg_yuanshao"] = 22.0,
    ["heg_yuanshao+heg_xuyou"] = 25.0,
    ["heg_xuyou+heg_yuanshao"] = 24.0,
    ["heg_yuanshao+heg_zoushi"] = 19.0,
    ["heg_zoushi+heg_yuanshao"] = 18.0,
    ["heg_lvbu+heg_yanliangwenchou"] = 20.0,
    ["heg_yanliangwenchou+heg_lvbu"] = 20.0,
    ["heg_jiaxu+heg_yanliangwenchou"] = 20.0,
    ["heg_yanliangwenchou+heg_jiaxu"] = 20.0,
    ["heg_jiaxu+heg_diaochan"] = 21.0,
    ["heg_diaochan+heg_jiaxu"] = 21.0,
    ["heg_kongrong+heg_diaochan"] = 22.0,
    ["heg_diaochan+heg_kongrong"] = 21.0,
    ["heg_kongrong+heg_huatuo"] = 23.0,
    ["heg_huatuo+heg_kongrong"] = 23.0,
    ["heg_kongrong+heg_pengyang"] = 23.0,
    ["heg_pengyang+heg_kongrong"] = 22.0,
    ["heg_kongrong+heg_caiwenji"] = 21.0,
    ["heg_caiwenji+heg_kongrong"] = 20.0,
    ["heg_yanliangwenchou+heg_mateng"] = 22.0,
    ["heg_mateng+heg_yanliangwenchou"] = 22.0,
    ["heg_yanliangwenchou+heg_lijueguosi"] = 21.0,
    ["heg_lijueguosi+heg_yanliangwenchou"] = 21.0,
    ["heg_lijueguosi+heg_xuyou"] = 23.0,
    ["heg_xuyou+heg_lijueguosi"] = 22.0,
    ["heg_lijueguosi+heg_mateng"] = 23.0,
    ["heg_mateng+heg_lijueguosi"] = 23.0,
    ["heg_lijueguosi+heg_beimihu"] = 23.0,
    ["heg_beimihu+heg_lijueguosi"] = 22.0,
    ["heg_tianfeng+heg_hetaihou"] = 18.0,
    ["heg_hetaihou+heg_tianfeng"] = 17.0,
    ["heg_huatuo+heg_zhanglu"] = 19.0,
    ["heg_zhanglu+heg_huatuo"] = 18.0,
    ["heg_yuji+heg_xuyou"] = 23.0,
    ["heg_xuyou+heg_yuji"] = 22.0,
    ["heg_new_zuoci+heg_xuyou"] = 24.0,
    ["heg_xuyou+heg_new_zuoci"] = 23.0,
    ["heg_zhangxiu+heg_hetaihou"] = 25.0,
    ["heg_hetaihou+heg_zhangxiu"] = 24.0,
    ["heg_zhangjiao+heg_zhangxiu"] = 20.0,
    ["heg_zhangxiu+heg_zhangjiao"] = 20.0,
    ["heg_huangzu+heg_mateng"] = 22.0,
    ["heg_mateng+heg_huangzu"] = 21.0,
    ["heg_huangzu+heg_zhangxiu"] = 23.0,
    ["heg_zhangxiu+heg_huangzu"] = 23.0,
    ["heg_xunchen+heg_zhangxiu"] = 22.0,
    ["heg_zhangxiu+heg_xunchen"] = 22.0,
    ["heg_xunchen+heg_zoushi"] = 20.0,
    ["heg_zoushi+heg_xunchen"] = 19.0,
    ["heg_miheng+heg_dongzhuo"] = 20.0,
    ["heg_dongzhuo+heg_miheng"] = 19.0,
    ["heg_miheng+heg_tianfeng"] = 19.0,
    ["heg_tianfeng+heg_miheng"] = 18.0,
    ["heg_miheng+heg_zhangxiu"] = 21.0,
    ["heg_zhangxiu+heg_miheng"] = 21.0,
    ["heg_zhonghui+heg_lukang"] = 25.0,
    ["heg_lukang+heg_zhonghui"] = 24.0,
    ["heg_zhonghui+heg_dengai"] = 25.0,
    ["heg_dengai+heg_zhonghui"] = 24.0,
    ["heg_simazhao+heg_simayi"] = 25.0,
    ["heg_simayi+heg_simazhao"] = 24.0,
    ["heg_gongsunyuan+heg_zhangliao"] = 23.0,
    ["heg_zhangliao+heg_gongsunyuan"] = 22.0,
    ["heg_sunchen+heg_caoren"] = 16.0,
    ["heg_caoren+heg_sunchen"] = 15.0,
    ["heg_zhangliao+heg_zhanghe"] = 5.0,
    ["heg_zhanghe+heg_zhangliao"] = 5.0,
    ["heg_zhangliao+heg_xiahouyuan"] = 5.0,
    ["heg_xiahouyuan+heg_zhangliao"] = 5.0,
    ["heg_zhanghe+heg_xiahouyuan"] = 5.0,
    ["heg_xiahouyuan+heg_zhanghe"] = 5.0,
    ["heg_guanyu+heg_zhaoyun"] = 5.0,
    ["heg_zhaoyun+heg_guanyu"] = 5.0,
    ["heg_lijueguosi+heg_zhangxiu"] = 5.0,
    ["heg_zhangxiu+heg_lijueguosi"] = 5.0,
    ["heg_yuanshao+heg_zhanglu"] = 5.0,
    ["heg_zhanglu+heg_yuanshao"] = 5.0,
}


function sgs.originalHegemonyDuanchang(player, head)
    local slots = player:property("Duanchang"):toStringList()
    if head == nil then return #slots > 0 end
    return table.contains(slots, head and "head" or "deputy")
end

function sgs.originalHegemonySlotSkills(player, head)
    local result = {}
    local general = sgs.originalHegemonyGeneral(player, head)
    if not general then return result end
    local own = current_self and current_self.player:objectName() == player:objectName()
    for _, skill in sgs.qlist(general:getVisibleSkillList()) do
        local name = skill:objectName()
        if (own and player:hasSkill(name)) or player:hasShownSkill(name) then
            if (head and player:inHeadSkills(name)) or (not head and player:inDeputySkills(name)) then
                result[#result + 1] = skill
            end
        end
    end
    return result
end
