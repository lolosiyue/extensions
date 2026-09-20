-- Shared value-only strategy hook contract for the isolated VM.
-- This module owns no gameplay objects and never calls sgs.Sanguosha.
local sgs = rawget(_G, "sgs")
if type(sgs) ~= "table" then sgs = {}; rawset(_G, "sgs", sgs) end

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
    "ai_ajustdamage_from", "ai_ajustdamage_to", "ai_lijian_effect", "ai_liuli_effect",
    "ai_quhu_effect", "ai_slash_benefit", "ai_type_name", "dynamic_value", "card_damage_nature"
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
    cardneed_skill = "cardneed_skill", dynamic_value = "dynamic_value", card_damage_nature = "card_damage_nature"
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
sgs.priority_skill = sgs.priority_skill or "dimeng|haoshi|qingnang|nosjizhi|jizhi|guzheng|qixi|jieyin|guose|duanliang|jujian|fanjian|neofanjian|lijian|noslijian|manjuan|tuxi|qiaobian|yongsi|zhiheng|luoshen|nosrende|rende|mingce|wansha|gongxin|jilve|anxu|qice|yinling|qingcheng|houyuan|zhaoxin|shuangren|zhaxiang|xiansi|junxing|bifa|yanyu|shenxian|jgtianyun"
sgs.save_skill = sgs.save_skill or "jijiu|buyi|nosjiefan|chunlao|tenyearchunlao|secondtenyearchunlao|longhun|newlonghun"
sgs.exclusive_skill = sgs.exclusive_skill or "huilei|duanchang|wuhun|buqu|dushi"
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill or "yuce|tanlan|toudu|qiaobian|jieyuan|anxian|liuli|chongzhen|tianxiang|tenyeartianxiang|oltianxiang|guhuo|nosguhuo|olguhuo|leiji|nosleiji|olleiji|qingguo|yajiao|chouhai|tenyearchouhai|nosrenxin|taoluan|tenyeartaoluan|huisheng|zhendu|newzhendu|kongsheng|zhuandui|longhun|newlonghun|fanghun|olfanghun|mobilefanghun|zhenshan|jijiu|daigong|yinshicai"
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill or "paoxiao|tenyearpaoxiao|olpaoxiao|tianyi|xianzhen|shuangxiong|nosjizhi|jizhi|guose|duanliang|qixi|qingnang|luoyi|guhuo|nosguhuo|jieyin|zhiheng|rende|nosrende|nosjujian|luanji|qiaobian|lirang|mingce|fuhun|spzhenwei|nosfuhun|nosluoyi|yinbing|jieyue|sanyao|xinzhan"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill or "kanpo|guicai|guidao|beige|xiaoguo|liuli|tianxiang|jijiu|leiji|nosleijiqingjian|zhuhai|qinxue|jspdanqi|" .. sgs.dont_kongcheng_skill
sgs.cardneed_skill = sgs.cardneed_skill or sgs.Active_cardneed_skill .. "|" .. sgs.notActive_cardneed_skill

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
    return key and sgs[key] or nil
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

return sgs
