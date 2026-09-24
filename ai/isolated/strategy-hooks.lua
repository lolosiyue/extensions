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
sgs.priority_skill = sgs.priority_skill or "dimeng|haoshi|qingnang|nosjizhi|jizhi|guzheng|qixi|jieyin|guose|duanliang|jujian|fanjian|neofanjian|lijian|noslijian|manjuan|tuxi|qiaobian|yongsi|zhiheng|luoshen|nosrende|rende|mingce|wansha|gongxin|jilve|anxu|qice|yinling|heg_qingcheng|houyuan|zhaoxin|shuangren|zhaxiang|xiansi|junxing|bifa|yanyu|shenxian|jgtianyun"
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

-- Target recommendation failures are distinct from an empty ranked result:
-- unknown classification/relation/projection, missing evaluators, malformed hooks,
-- and non-finite scores must raise unsupported, never choose the fallback.
local function target_known(value, key)
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
    if type(object[method]) ~= "function" then ai_unsupported("target recommendation helper is unavailable", method) end
    return target_known(object[method](object, ...), method)
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
        if card == nil then return false end
        if type(card) == "string" then
            if card == kind then return true end
            for _, name in ipairs(sgs[entry[1]]) do if name == card then return true end end
            if kind == "recover" then
                for _, key in ipairs({"recover_skill", "recover_hp_skill", "save_skill"}) do
                    if sgs[key] and sgs[key]:match(card) then return true end
                end
            end
            return false
        end
        if not AIValue.isCard(card) then ai_unsupported("target context must be a card value", kind) end
        if kind == "damage" or kind == "debuff" then
            if target_call(card, "isDamageCard") then return true end
        end
        for _, class in ipairs(entry[3]) do if target_call(card, "isKindOf", class) then return true end end
        return false
    end
end
function sgs.registerSkillCardType(name, kind)
    local entry = target_types[kind]
    assert(entry and type(name) == "string", "unknown skill card type")
    for _, existing in ipairs(sgs[entry[1]]) do if existing == name then return end end
    table.insert(sgs[entry[1]], name)
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
    if type(card) == "string" then
        local registered = target_types[card] ~= nil
        for _, entry in pairs(target_types) do
            for _, name in ipairs(sgs[entry[1]]) do if name == card then registered = true end end
        end
        if not registered then ai_unsupported("skill target classification is not registered", card) end
    end
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
        local view = rawget(player, "_view")
        if type(view) ~= "table" or type(view.public_marks) ~= "table" then
            ai_unsupported("public marks are unknown", name)
        end
        return target_number(player:getMark(name), name)
    end
    if target_call(to, "hasSkill", "qhfiremanjuann") and mark(to, "qhfiremanjuann-Clear") < 2 then return true end
    if target_call(to, "getHandcardNum") < 5 and target_call(to, "hasSkill", "zhengu") then
        for _, player in ipairs(target_call(self.room, "getAlivePlayers")) do
            if mark(player, "&zhengu") > 0 and target_relation(self, player, to) == "friend" then return true end
        end
    end
    return false
end
function SmartAIView:getTargetBaseScore(target, card, from, flags)
    from = from or self.player
    local ctx = self:buildTargetRecommendContext(card, flags)
    local relation = target_relation(self, target, from)
    if relation ~= "friend" and relation ~= "enemy" then return 0 end
    -- Damage and discard base scoring need further original strategy ports.
    if ctx.isDamage or ctx.isDecrease or ctx.isRecovery then
        ai_unsupported("target base scoring is not ported for this effect", "getTargetBaseScore")
    end
    local score, sign = 0, relation == "friend" and 1 or -1
    if ctx.isDraw then
        if target_call(self, "canDraw", target, from) then
            if not target_call(self, "needKongcheng", target) then score = score + sign * 2 end
            -- Legacy uses undefined to/notDraw here: needDraw(nil) is false.
            -- Preserve the observed score; fixing the donor is a separate change.
        else score = score - 1 end
    end
    local view = rawget(target, "_view")
    if type(view) ~= "table" or type(view.lord) ~= "boolean" then ai_unsupported("lord flag is unknown", "recommend") end
    if view.lord then score = score + 1 end
    if relation == "enemy" then
        local objective = target_number(self:objectiveLevel(target), "objectiveLevel")
        if objective > 3 then score = score + math.min(objective - 3, 2) end
    end
    return score
end
function SmartAIView:getBestTarget(targets, card, from, flags)
    if not AIValue.isList(targets) then ai_unsupported("target candidates are unknown", "getBestTarget") end
    if #targets == 0 then return nil end
    from = from or self.player
    local ctx = self:buildTargetRecommendContext(card, flags)
    -- Built-in recommend ports below cover draw effects. Other effects must not
    -- silently omit native damage/chain/turnover policy and claim equivalence.
    if not ctx.isDraw or ctx.isDamage or ctx.isDecrease or ctx.isRecovery then
        ai_unsupported("target recommendation defaults only cover draw effects", "getBestTarget")
    end
    local recommends = {}
    for _, owner in ipairs(target_call(self.room, "getAlivePlayers")) do
        for _, hook in ipairs(target_known(self:forSkillHooks("ai_target_recommend", owner), "recommend skills")) do
            if type(hook.value) ~= "function" then ai_unsupported("invalid target recommendation hook", hook.key) end
            recommends[#recommends + 1] = {owner = owner, eval = hook.value}
        end
    end
    local scored, total = {}, 0
    for _, target in ipairs(targets) do
        if not AIValue.isPlayer(target) then ai_unsupported("invalid target facade", "getBestTarget") end
        local score = target_number(self:getTargetBaseScore(target, card, from, flags), "base score")
        if score > 0 then
            local veto = false
            local function apply(eval, owner)
                if type(eval) ~= "function" then ai_unsupported("invalid global recommend hook", "recommend") end
                local adjust = eval(self, from, target, card, owner, ctx)
                if adjust == false then veto = true
                elseif type(adjust) == "number" then score = target_number(score + target_number(adjust, "adjustment"), "score")
                elseif adjust ~= nil then ai_unsupported("invalid target recommendation result", "recommend") end
            end
            for _, rec in ipairs(recommends) do apply(rec.eval, rec.owner); if veto then break end end
            if not veto then
                for _, rec in ipairs(sgs.ai_target_recommend_global) do apply(rec.eval, nil); if veto then break end end
            end
            if not veto and score > 0 then
                scored[#scored + 1] = {target = target, score = score}
                total = target_number(total + score, "total score")
            end
        end
    end
    if #scored == 0 then return nil end
    if #scored == 1 then return scored[1].target end
    local random, cumulative = math.random() * total, 0
    for _, entry in ipairs(scored) do
        cumulative = cumulative + entry.score
        if random <= cumulative then return entry.target end
    end
    return scored[#scored].target
end
function SmartAIView:getBestTargetOr(targets, card, from, fallback)
    local target = self:getBestTarget(targets, card, from)
    if target then return target end
    if type(fallback) == "function" then return fallback(self, targets, card, from) end
    return nil
end
-- The donor's damage/Slash-only defaults return zero for draw contexts.
-- These are the two default registrations that can change Scarlet draw scores.
sgs.registerTargetRecommend("rende", function(self, from, to, card, owner, ctx)
    if ctx.isDraw and target_call(to, "isWounded") then return 2 end
    return 0
end)
sgs.registerTargetRecommend("s4_qiaobian", function(self, from, to, card, owner, ctx)
    if ctx.isDraw and target_relation(self, from, to) == "friend" then return 2 end
    if ctx.isDecrease then ai_unsupported("qiaobian discard recommendation is not ported", "s4_qiaobian") end
    return 0
end)

return sgs
