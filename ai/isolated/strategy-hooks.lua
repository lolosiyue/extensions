-- Shared value-only strategy hook contract for the isolated VM.
-- This module owns no gameplay objects and never calls sgs.Sanguosha.
local sgs = rawget(_G, "sgs")
if type(sgs) ~= "table" then sgs = {}; rawset(_G, "sgs", sgs) end

-- Donor category cache (smart-ai.lua:537). Preserve empty components, cache
-- identity and its deliberately lazy invalidation; this is not a player roster.
function sgs.getSkillList(skill_string_name)
    local cache_name = skill_string_name .. "_list"
    if not sgs[cache_name] then
        local skill_string = sgs[skill_string_name]
        if skill_string then
            local values, from = {}, 1
            if #skill_string > 0 then
                local delimiter = string.find(skill_string, "|", from, true)
                while delimiter do
                    values[#values + 1] = string.sub(skill_string, from, delimiter - 1)
                    from = delimiter + 1
                    delimiter = string.find(skill_string, "|", from, true)
                end
                values[#values + 1] = string.sub(skill_string, from)
            end
            sgs[cache_name] = values
        end
    end
    return sgs[cache_name] or {}
end

local registry_names = {
    "ai_card_intention", "ai_playerchosen_intention", "ai_playerschosen_intention",
    "ai_Yiji_intention", "ai_retrial_intention", "ai_keep_value", "ai_use_value",
    "ai_use_priority", "ai_suit_priority", "ai_chaofeng", "ai_skill_invoke", "ai_skill_suit",
    "ai_skill_cardask", "ai_skill_choice", "ai_general_choice", "ai_general_choice_for_lord",
    "ai_skill_askforag", "ai_skill_askforyiji", "ai_skill_pindian", "ai_filterskill_filter",
    "ai_skill_playerchosen", "ai_skill_discard", "ai_cardshow", "ai_nullification",
    "ai_skill_cardchosen", "ai_skill_use", "ai_cardneed", "ai_skill_use_func", "ai_skills",
    "ai_slash_weaponfilter", "ai_slash_prohibit", "ai_view_as", "ai_cardsview",
    "ai_cardsview_valuable", "ai_choicemade_filter", "ai_need_damaged", "ai_event_callback",
    "ai_NeedPeach", "ai_judgeGood", "ai_need_kongcheng", "ai_need_retrial", "ai_need_retrial_func", "ai_retrial", "ai_draw_count", "ai_use_revises", "ai_guhuo_card",
    "ai_target_revises", "ai_useto_revises", "ai_skill_defense", "ai_card_priority",
    "ai_poison_card", "ai_skill_playerschosen", "ai_used_revises", "ai_skill_carduse",
    "ai_target_recommend", "ai_target_recommend_global", "ai_damage_reason_suppress_intention",
    "ai_damage_from_flag_intention", "ai_voluntary_give_skills", "ai_card_combo_use", "ai_dont_hurt_from",
    "ai_dont_hurt_to", "ai_hasBuquEffect_skill", "ai_canNiepan_skill", "ai_hasTuntianEffect_skill",
    "ai_getLeastHandcardNum_skill", "ai_getBestHp_skill", "ai_canliegong_skill", "damageSkillsList",
    "ai_compare_funcs", "ai_nullification_threat_table", "ai_fill_skill", "ai_weapon_value",
    "ai_armor_value", "ai_card_usage_limit", "ai_card_usage_penalty", "ai_suppress_intention",
    "ai_ajustdamage_from", "ai_ajustdamage_to", "ai_can_damagehp", "ai_lijian_effect", "ai_liuli_effect",
    "ai_quhu_effect", "ai_slash_benefit", "ai_type_name", "dynamic_value", "card_damage_nature",
    "card_value"
}

local choice_legacy = rawget(_G, "ai_choice_legacy_registries")
    or rawget(sgs, "ai_choice_legacy_registries") or {}
if rawget(_G, "ai_choice_legacy_registries") == nil then
    rawset(_G, "ai_choice_legacy_registries", choice_legacy)
end
sgs.ai_choice_legacy_registries = choice_legacy

local choice_names = {
    ai_skill_invoke = true, ai_skill_suit = true, ai_skill_cardask = true,
    ai_skill_choice = true, ai_general_choice = true, ai_general_choice_for_lord = true,
    ai_skill_askforag = true, ai_skill_askforyiji = true, ai_skill_pindian = true,
    ai_skill_playerchosen = true, ai_skill_discard = true, ai_cardshow = true,
    ai_nullification = true, ai_skill_cardchosen = true, ai_skill_use = true,
    ai_skill_use_func = true, ai_skill_playerschosen = true, ai_skill_carduse = true
}

local function bind_registry(name)
    -- sgs.ai_skill_use retains SmartAI's positional callback ABI. The unqualified
    -- registry is the isolated API and must not receive legacy callbacks.
    if name == "ai_skill_use" and type(rawget(_G, "ai_skill_use_legacy")) == "table" then
        sgs[name] = ai_skill_use_legacy
        return
    end
    if choice_names[name] and choice_legacy[name] ~= nil then
        sgs[name] = choice_legacy[name]
        return
    end
    local global_value = rawget(_G, name)
    if type(global_value) == "table" then
        sgs[name] = global_value
    elseif type(sgs[name]) == "table" then
        rawset(_G, name, sgs[name])
    else
        local value = {}
        rawset(_G, name, value)
        sgs[name] = value
    end
end

for _, name in ipairs(registry_names) do
    bind_registry(name)
end
-- Choice modules own their complete set of legacy aliases, including extensions
-- such as single Peach, Guanxing and trigger order. Do not maintain a second list.
for name, registry in pairs(choice_legacy) do sgs[name] = registry end

-- These aliases are the original SmartAI tables, not copies.  A package can
-- register through either spelling and every consumer sees the same object.
local aliases = {
    ai_use_revises = "ai_use_revises", ai_target_revises = "ai_target_revises",
    ai_useto_revises = "ai_useto_revises", ai_used_revises = "ai_used_revises",
    cardneed = "ai_cardneed", retrial = "ai_retrial",
    damage = "ai_damage_from_flag_intention",
    besthp = "ai_getBestHp_skill", need_kongcheng = "need_kongcheng",
    lose_equip_skill = "lose_equip_skill", masochism_skill = "masochism_skill",
    Active_cardneed_skill = "Active_cardneed_skill", notActive_cardneed_skill = "notActive_cardneed_skill",
    cardneed_skill = "cardneed_skill", need_equip_skill = "need_equip_skill",
    double_slash_skill = "double_slash_skill",
    drawpeach_skill = "drawpeach_skill", recover_hp_skill = "recover_hp_skill",
    recover_skill = "recover_skill", use_lion_skill = "use_lion_skill",
    straight_damage_skill = "straight_damage_skill", need_maxhp_skill = "need_maxhp_skill", hit_skill = "hit_skill",
    dynamic_value = "dynamic_value", card_damage_nature = "card_damage_nature"
}

local function canonical(name)
    if type(name) ~= "string" or name == "" then return nil end
    if type(sgs[name]) == "table" or type(sgs[name]) == "string" then return name end
    if aliases[name] then return aliases[name] end
    return string.sub(name, 1, 3) == "ai_" and name or "ai_" .. name
end

sgs.lose_equip_skill = sgs.lose_equip_skill or "kofxiaoji|xiaoji|xuanfeng|nosxuanfeng|tenyearxuanfeng|mobilexuanfeng"
sgs.need_kongcheng = sgs.need_kongcheng or "lianying|noslianying|kongcheng|sijian|hengzheng"
sgs.masochism_skill = sgs.masochism_skill or "guixin|yiji|fankui|jieming|xuehen|neoganglie|ganglie|vsganglie|enyuan|fangzhu|nosenyuan|langgu|quanji|zhiyu|renjie|tanlan|tongxin|huashen|duodao|chengxiang|benyu"
sgs.wizard_skill = sgs.wizard_skill or "nosguicai|guicai|guidao|olguidao|jilve|tiandu|luoying|noszhenlie|huanshi|jinshenpin"
sgs.wizard_harm_skill = sgs.wizard_harm_skill or "nosguicai|guicai|guidao|olguidao|jilve|jinshenpin|midao|zhenyi"
sgs.priority_skill = sgs.priority_skill or "dimeng|haoshi|qingnang|nosjizhi|jizhi|guzheng|qixi|jieyin|guose|duanliang|jujian|fanjian|neofanjian|lijian|noslijian|manjuan|tuxi|qiaobian|yongsi|zhiheng|luoshen|nosrende|rende|mingce|wansha|gongxin|jilve|anxu|qice|yinling|heg_qingcheng|houyuan|zhaoxin|shuangren|zhaxiang|xiansi|junxing|bifa|yanyu|shenxian|jgtianyun"
sgs.save_skill = sgs.save_skill or "jijiu|buyi|nosjiefan|chunlao|tenyearchunlao|secondtenyearchunlao|longhun|newlonghun"
sgs.exclusive_skill = sgs.exclusive_skill or "huilei|duanchang|wuhun|buqu|dushi"
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill or "yuce|tanlan|toudu|qiaobian|jieyuan|anxian|liuli|chongzhen|tianxiang|tenyeartianxiang|oltianxiang|guhuo|nosguhuo|olguhuo|leiji|nosleiji|olleiji|qingguo|yajiao|chouhai|tenyearchouhai|nosrenxin|taoluan|tenyeartaoluan|huisheng|zhendu|newzhendu|kongsheng|zhuandui|longhun|newlonghun|fanghun|olfanghun|mobilefanghun|zhenshan|jijiu|daigong|yinshicai"
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill or "paoxiao|tenyearpaoxiao|olpaoxiao|tianyi|xianzhen|shuangxiong|nosjizhi|jizhi|guose|duanliang|qixi|qingnang|luoyi|guhuo|nosguhuo|jieyin|zhiheng|rende|nosrende|nosjujian|luanji|qiaobian|lirang|mingce|fuhun|spzhenwei|nosfuhun|nosluoyi|yinbing|jieyue|sanyao|xinzhan"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill or "kanpo|guicai|guidao|beige|xiaoguo|liuli|tianxiang|jijiu|leiji|nosleijiqingjian|zhuhai|qinxue|jspdanqi|" .. sgs.dont_kongcheng_skill
sgs.cardneed_skill = sgs.cardneed_skill or sgs.Active_cardneed_skill .. "|" .. sgs.notActive_cardneed_skill
sgs.need_equip_skill = sgs.need_equip_skill or "shensu|tenyearshensu|mingce|jujian|beige|yuanhu|huyuan|gongqi|nosgongqi|yanzheng|heg_qingcheng|neoluoyi|longhun|newlonghun|shuijian|yinbing"
sgs.double_slash_skill = sgs.double_slash_skill or "paoxiao|tenyearpaoxiao|olpaoxiao|fuhun|tianyi|xianzhen|zhaxiang|lihuo|jiangchi|shuangxiong|qiangwu|luanji"


-- Common initialized categories are available before any package loader.
for index, name in ipairs({"All", "Draw", "Male", "Female", "Wounded", "MaleWounded", "FemaleWounded", "Weak"}) do
    local key = "Friend_" .. name
    if sgs[key] == nil then sgs[key] = index - 1 end
end
sgs.drawpeach_skill = sgs.drawpeach_skill or "tuxi|qiaobian"
sgs.recover_hp_skill = sgs.recover_hp_skill or "nosrende|rende|tenyearrende|kofkuanggu|kuanggu|tenyearkuanggu|zaiqi|mobilezaiqi|jieyin|"..
						"qingnang|shenzhi|longhun|newlonghun|ytchengxiang|quji|dev_zhiyu|dev_pinghe|dev_qiliao|dev_saodong"
sgs.recover_skill = sgs.recover_skill or "yinghun|hunzi|nosmiji|noszishou|zishou|olzishou|tenyearzishou|ganlu|xueji|shangshi|nosshangshi|"..
						"buqu|miji|"..sgs.recover_hp_skill
sgs.use_lion_skill = sgs.use_lion_skill or "longhun|newlonghun|duanliang|qixi|guidao|noslijian|lijian|jujian|nosjujian|zhiheng|mingce|"..
						"yongsi|fenxun|gongqi|yinling|jilve|heg_qingcheng|neoluoyi|diyyicong"
sgs.straight_damage_skill = sgs.straight_damage_skill or "qiangxi|nosxuanfeng|duwu|danshou"
sgs.need_maxhp_skill = sgs.need_maxhp_skill or "yingzi|zaiqi|yinghun|hunzi|juejing|ganlu|noszishou|miji|chizhong|xueji|quji|xuehen|shude|"..
						"neojushou|tannang|fangzhu|nosshangshi|nosmiji|yisuan|xuhe"
sgs.hit_skill = sgs.hit_skill or "wushuang|fuqi|tenyearfuqi|zhuandui|tieji|nostieji|dahe|olqianxi|qianxi|tenyearjianchu|oljianchu|"..
					"wenji|tenyearbenxi|mobileliyong|olwushen|tenyearliegong|liegong|kofliegong|tenyearqingxi|wanglie|"..
					"conqueror|zhaxiang|tenyearyijue|yijue|xiongluan|xiying|"
sgs.turnOverSkillsList = sgs.turnOverSkillsList or {
		"jushou", "nosjushou", "neojushou", "super_jushou",
		"fangzhu", "mobilefangzhu", "mobilemoufangzhu", "jilve_mobilefangzhu",
		"jiushi", "mobilejiushi", "qljiushi", "oljiushi",
		"junxing", "mobilejunxing",
		"olxingwu", "lulve", "caiyi", "daili", "shisuan", "jiusi",
		"mobilexincunsi", "mobilexinguixiu",
		"mobilemoushensu", "mobileshensu",
		"guixin", "newguixin", "shenfen", "szfscliu",
		"olshebian", "olrenxin", "nosrenxin",
		"olfuli", "mobilefuli", "mobilebeige",
		"biejun", "pojun", "cangni",
		"jghuodi", "jgdidong", "jgdixian", "jglingyu", "bossdidong", "boss_xushi",
		"mobilemouqiaomeng", "fuji", "zhanlie"
	}

for _, key in ipairs({"damage_card", "control_usecard", "control_card", "lucky_chance", "benefit"}) do
    if type(sgs.dynamic_value[key]) ~= "table" then sgs.dynamic_value[key] = {} end
end

-- Printed standard card natures are definition values; damage hooks still
-- decide their strategic adjustments and never turn this table into a rule engine.
for _, entry in ipairs({{"Slash", "Normal"}, {"Duel", "Normal"},
    {"SavageAssault", "Normal"}, {"ArcheryAttack", "Normal"},
    {"FireSlash", "Fire"}, {"FireAttack", "Fire"}, {"ThunderSlash", "Thunder"},
    {"Lightning", "Thunder"}, {"IceSlash", "Ice"}}) do
    if sgs.card_damage_nature[entry[1]] == nil then
        sgs.card_damage_nature[entry[1]] = sgs["DamageStruct_" .. entry[2]]
    end
end

function SmartAIView:getHooks(name)
    local key = canonical(name)
    local registry=key and sgs[key]or nil
    if type(registry)~="table"or type(ai_audited_aliases)~="table"then return registry end
    if getmetatable(registry)==nil and next(registry)==nil then return registry end
    -- Resolve only the hook actually requested. Eagerly scanning every alias
    -- would demand unrelated package metadata and alter presence tests.
    self._audited_hook_views=self._audited_hook_views or{}
    local cached=self._audited_hook_views[key]
    if cached and cached.source==registry then return cached.view end
    local view=setmetatable({}, {
        __index=function(_,hook)return ai_audited_aliases.resolve(self,registry[hook])end,
        __newindex=function(_,hook,value)registry[hook]=value end,
        __len=function()return #registry end,
        __pairs=function()
            local iter,state,first=pairs(registry)
            return function(_,previous)
                local hook,value=iter(state,previous)
                while hook~=nil do
                    value=ai_audited_aliases.resolve(self,value)
                    if value~=nil then return hook,value end
                    hook,value=iter(state,hook)
                end
            end,nil,first
        end })
    self._audited_hook_views[key]={source=registry,view=view}
    return view
end

function SmartAIView:callHook(name, key, ...)
    local registry = self:getHooks(name)
    if type(registry) ~= "table" then return nil end
    local value = registry[key]
    if type(value) == "function" then return value(...) end
    return value
end

function SmartAIView:forSkillHooks(name, player)
    local registry = self:getHooks(name)
    if type(registry) ~= "table" or not AIValue.isPlayer(player) then return nil end
    -- Empty ordinary registries need no skill projection. This also avoids
    -- repeatedly wrapping every skill in requests without package overrides.
    if getmetatable(registry) == nil and next(registry) == nil then return AIList.new({}) end
    local skills = player:getSkills()
    if not skills then return nil end
    local result, seen = {}, {}
    for _, skill in ipairs(skills) do
        local skill_name = skill:objectName()
        if not seen[skill_name] and not skill:isInvalid() then
            seen[skill_name] = true
            local value = registry[skill_name]
            if value ~= nil then result[#result + 1] = {key = skill_name, value = value, skill = skill} end
        end
    end
    return AIList.new(result)
end

-- Target recommendation failures are distinct from an empty ranked result:
-- unknown classification/relation/projection, missing evaluators, malformed hooks,
-- and non-finite scores must raise unsupported, never choose the fallback.
local function target_known(value, key)
    if AIUnsupported.is(value) then error(value, 0) end
    if value == nil then ai_unsupported("target recommendation projection is unknown", key) end
    return value
end
local function target_number(value, key)
    if type(value) ~= "number" or value ~= value or value == math.huge or value == -math.huge then
        ai_unsupported("target recommendation score is not finite", key)
    end
    return value
end
local function target_call(object, method, ...)
    if AIValue.isPlayer(object) then
        if method == "getMark" and type(object.getStrategyMark) == "function" then method = "getStrategyMark" end
        if method == "hasFlag" and type(object.getStrategyFlag) == "function" then method = "getStrategyFlag" end
    end
    if type(object[method]) ~= "function" then ai_unsupported("target recommendation helper is unavailable", method) end
    return target_known(object[method](object, ...), method)
end
local scarlet_recommend_callbacks = setmetatable({}, {__mode = "k"})
local function scarlet_metadata(self)
    local facts = self.world and self.world.strategy_facts and self.world.strategy_facts.target_recommend
    local value = type(facts) == "table" and facts.scarlet
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
        for _, class in ipairs(entry[3]) do if target_call(card, "isKindOf", class) then return true end end
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
			if self:needDraw(to,notDraw) then
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
-- Cache entries retain the first function references, just as the donor VM.
-- Native history attests the epoch/first viewer; only primitive owner names
-- survive snapshots. A VM rebuild cannot reconstruct lost function references.
local target_recommend_cache = {}
local function target_cache_query(proposal)
    local query = rawget(_G, "ai_target_recommend_cache")
    if type(query) ~= "function" then ai_unsupported("target recommendation cache host is unavailable", "getBestTarget:cache") end
    local row = query(proposal)
    if AIUnsupported.is(row) then error(row, 0) end
    if type(row) ~= "table" or row.known ~= true then
        ai_unsupported(type(row) == "table" and row.reason or "target recommendation cache history is unknown", "getBestTarget:cache")
    end
    if type(row.scope) ~= "string" or row.scope == "" or type(row.epoch) ~= "string" or row.epoch == ""
        or (row.state ~= "empty" and row.state ~= "captured") then
        ai_unsupported("target recommendation cache stamp is malformed", "getBestTarget:cache")
    end
    return row
end
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
    local stamp = target_cache_query({op = "read"})
    local viewer = self.player:objectName()
    local saved = target_recommend_cache[stamp.scope]
    if stamp.state == "empty" then
        local before_estimates = target_estimate_counts(self)
        local entries = {}
        for _, owner in ipairs(target_call(self, "getCachedAlivePlayers")) do
            for _, name in ipairs(target_known(self:getConnections(owner), "recommend connections")) do
                local callback = recommendation_callback(self, sgs.ai_target_recommend[name])
                if callback then entries[#entries + 1] = {owner = owner:objectName(), eval = callback} end
            end
        end
        local captured = target_cache_query({op = "capture", scope = stamp.scope, epoch = stamp.epoch})
        if captured.scope ~= stamp.scope or captured.epoch ~= stamp.epoch or captured.state ~= "captured" then
            ai_unsupported("target recommendation cache changed while capturing", "getBestTarget:cache")
        end
        saved = {viewer = viewer, epoch = stamp.epoch, entries = entries,
            estimates = target_estimate_delta(self, before_estimates)}
        target_recommend_cache[stamp.scope] = saved
    elseif not saved or saved.viewer ~= viewer or saved.epoch ~= stamp.epoch then
        ai_unsupported("target recommendation function references were not retained in this VM", "getBestTarget:cache")
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
function SmartAIView:getBestTarget(targets, card, from, flags)
    if not targets then return nil end
    if not AIValue.isList(targets) then ai_unsupported("target candidates are unknown", "getBestTarget") end
    if #targets == 0 then return nil end
    from = from or self.player
    local ctx = self:buildTargetRecommendContext(card, flags)
    local ordered, ranks = targets, {}
    if ctx.isDamage then
        ordered = self:findPlayerToDamage(1, from, nil, targets, 0, card)
        if AIUnsupported.is(ordered) then error(ordered, 0) end
        if not ordered or #ordered == 0 then return nil end
        for index, target in ipairs(ordered) do
            ranks[target:objectName()] = #ordered > 1 and 1 + (#ordered - index) * (4 / (#ordered - 1)) or 5
        end
    end
    local recommends = active_target_recommends(self)
    local scored = {}
    for _, target in ipairs(ordered) do
        if not AIValue.isPlayer(target) then ai_unsupported("invalid target facade", "getBestTarget") end
        local score = ctx.isDamage and ranks[target:objectName()]
            or target_number(self:getTargetBaseScore(target, card, from, flags), "base score")
        if score > 0 then
            local veto = false
            local function apply(eval, owner)
                local adjust = eval(self, from, target, card, owner, ctx)
                if AIUnsupported.is(adjust) then error(adjust, 0) end
                if adjust == false then veto = true
                elseif type(adjust) == "number" then score = target_number(score + target_number(adjust, "adjustment"), "score")
                end -- Other ordinary return types are ignored by the source.
            end
            for _, rec in ipairs(recommends) do apply(rec.eval, rec.owner); if veto then break end end
            if not veto then
                for _, rec in ipairs(sgs.ai_target_recommend_global) do apply(rec.eval, nil); if veto then break end end
            end
            if not veto and score > 0 then
                scored[#scored + 1] = {target = target, score = score}
            end
        end
    end
    if #scored == 1 then return scored[1].target end
    if #scored == 0 then return nil end
    local total = 0
    for _, entry in ipairs(scored) do total = target_number(total + entry.score, "total score") end
    local random, cumulative = math.random() * total, 0
    for _, entry in ipairs(scored) do
        cumulative = cumulative + entry.score
        if random <= cumulative then return entry.target end
    end
    return scored[#scored].target
end
function SmartAIView:getBestTargetOr(targets, card, from, fallback)
    if targets and type(targets) ~= "table" then
        targets = sgs.QList2Table(targets)
    end
    local target = self:getBestTarget(targets, card, from)
    if target then return target end
    if type(fallback) == "function" then
        return fallback(self, targets, card, from)
    end
    return nil
end
-- Read only the exact reached slot. A public first description can decide
-- the predicate without requesting an undisclosed second general.
function SmartAIView:checkMasochismInvalid(from, to, card)
    if not from then return false end
    local nature = type(card) ~= "string" and card and sgs.card_damage_nature[card:getClassName()] or nil
    if target_call(self, "hasJueqingEffect", from, to, nature) then return true end
    if to and target_call(from, "hasSkill", "nosqianxi") and target_call(from, "distanceTo", to) == 1
        and type(card) ~= "string" and card and target_call(card, "isKindOf", "Slash") then return true end
    local facts = self.world and self.world.strategy_facts and self.world.strategy_facts.target_recommend
    local rows = type(facts) == "table" and facts.general_descriptions
    local row = type(rows) == "table" and rows[from:objectName()]
    for _, slot in ipairs({"first", "second"}) do
        local description = type(row) == "table" and row[slot]
        if type(description) ~= "table" or description.known ~= true or type(description.present) ~= "boolean" then
            ai_unsupported("original general description is not visible to this viewer", "checkMasochismInvalid:" .. slot)
        end
        if description.present then
            local text = description.text
            if type(text) ~= "string" then ai_unsupported("original general description is missing", "checkMasochismInvalid:" .. slot) end
            if string.find(text, "技能失效") or string.find(text, "技失效") then return true end
        end
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
