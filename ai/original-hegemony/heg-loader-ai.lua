-- Declared after the bundle files: those declarations are inert until this gate.
if not sgs.GetConfig("EnableHegemony", false) or sgs.original_hegemony_ai_loaded then return end
assert(SmartAI and sgs.LoadPackageScript, "Original Hegemony requires the current Room SmartAI")
local first_strategy = #sgs.ai_skills + 1
sgs.original_hegemony_ai_loading = true
local ok, error_message = pcall(function()
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-common-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-standard_cards-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-maneuvering-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-guanxing-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-standard-wei-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-standard-shu-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-standard-wu-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-standard-qun-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-basara-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-formation-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-momentum-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-strategic_advantage-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-transformation-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-power-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-manoeuvre-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-newsgs-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-mol-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-overseas-ai.lua")
    sgs.LoadPackageScript("lua/ai/original-hegemony/heg-lord_ex-ai.lua")

    -- Donor callbacks keep their strategy source names; native HEG prompts use
    -- package-scoped IDs. Mirror registered callbacks without changing V2 gates.
    local callback_tables = {
        "ai_skill_invoke", "ai_skill_choice", "ai_skill_playerchosen", "ai_skill_playerschosen",
        "ai_skill_cardchosen", "ai_skill_cardshow", "ai_skill_cardask", "ai_skill_use",
        "ai_cardneed", "ai_skill_askforag",
        "ai_view_as", "ai_cardsview", "ai_skill_use_func",
        "ai_fill_skill", "ai_use_priority", "ai_use_value", "ai_card_intention",
        "ai_slash_prohibit", "ai_need_damaged", "ai_need_expensive", "ai_need_retrial", "ai_need_retrial_ask",
    }
    for old_name, actual_names in pairs(sgs.originalHegemonySkillAliases) do
        for _, table_name in ipairs(callback_tables) do
            local callbacks = sgs[table_name]
            if type(callbacks) == "table" and callbacks[old_name] ~= nil then
                for _, actual_name in ipairs(actual_names) do
                    if callbacks[actual_name] == nil then callbacks[actual_name] = callbacks[old_name] end
                end
            end
        end
    end

    -- Native HEG prompts keep their translated legacy text; map only the
    -- bundle's known card-ask spellings to the corresponding HEG decision.
    local cardask_prompt_aliases = {
        ["@midao-card"] = "@heg_midao-card",
        ["@xishe-slash"] = "@heg_xishe-slash",
        ["@juejue-discard"] = "@heg_juejue-discard",
        ["@daoshu-give"] = "@heg_daoshu-give",
        ["@huanshi-card"] = "@heg_huanshi-card",
        ["@threaten_emperor"] = "@heg_threaten_emperor",
    }
    for native_prompt, donor_prompt in pairs(cardask_prompt_aliases) do
        local callback = sgs.ai_skill_cardask[donor_prompt]
        if callback and not sgs.ai_skill_cardask[native_prompt] then
            sgs.ai_skill_cardask[native_prompt] = callback
        end
    end

    -- Native multi-target selection uses a separate registry from donor Lua.
    for name, callback in pairs(sgs.ai_skill_playerchosen) do
        if name:match("^heg_") and type(callback) == "function" and not sgs.ai_skill_playerschosen[name] then
            local original = callback
            sgs.ai_skill_playerschosen[name] = function(...)
                local targets = original(...)
                if type(targets) == "table" then return targets end
                return targets and { targets } or {}
            end
        end
    end

    -- Native command prompts append the actual skill ID to their fixed prefix.
    -- Resolve generic aliases after power has installed startcommand_to.
    for _, reason in ipairs({"jieyue", "jianglve", "buyi", "weidi", "quanjin", "jingce", "duwu"}) do
        sgs.ai_skill_choice["startcommand_heg_" .. reason] =
            sgs.ai_skill_choice["startcommand_" .. reason] or sgs.ai_skill_choice.startcommand_to
        sgs.ai_skill_choice["docommand_heg_" .. reason] =
            sgs.ai_skill_choice["docommand_" .. reason] or sgs.ai_skill_choice.docommand_from
    end

    -- External replies bypass Card_Parse, so normalize the same legacy suffix
    -- at the existing reply registries after every donor callback is installed.
    for _, name in ipairs({"ai_skill_use", "ai_view_as", "ai_cardsview"}) do
        for key, callback in pairs(sgs[name]) do
            if type(callback) == "function" then
                local original = callback
                sgs[name][key] = function(...)
                    local value = original(...)
                    if type(value) == "string" then return (sgs.originalHegemonyCardWire(value)) end
                    if type(value) == "table" then
                        local normalized = {}
                        for index, wire in ipairs(value) do
                            normalized[index] = (sgs.originalHegemonyCardWire(wire))
                        end
                        return normalized
                    end
                    return value
                end
            end
        end
    end

    for skill, class in pairs({heg_kurou = "HKurouCard", heg_qiangxi = "HQiangxiCard"}) do
        sgs.ai_skill_use_func[skill] = sgs.ai_skill_use_func[class]
        sgs.ai_use_priority[skill] = sgs.ai_use_priority[class]
        sgs.ai_use_value[skill] = sgs.ai_use_value[class]
    end

    -- Register donor producers through the existing V2 availability/source gate.
    for index = first_strategy, #sgs.ai_skills do
        local strategy = sgs.ai_skills[index]
        if strategy and type(strategy.getTurnUseCard) == "function"
            and not sgs.ai_fill_skill[strategy.name] then
            sgs.ai_fill_skill[strategy.name] = strategy.getTurnUseCard
        end
    end
    -- Class-specific strategies share algorithms without reintroducing card aliases.
    local strategy_classes = {
        HAllianceFeast = "AllianceFeast",
        HAwaitExhausted = "AwaitExhausted",
        HBefriendAttacking = "BefriendAttacking",
        HBurningCamps = "BurningCamps",
        HChaos = "Chaos",
        HConquering = "Conquering",
        HConsolidateCountry = "ConsolidateCountry",
        HDrowning = "Drowning",
        HFightTogether = "FightTogether",
        HImperialOrder = "ImperialOrder",
        HKnownBoth = "KnownBoth",
        HLureTiger = "LureTiger",
        HRuleTheWorld = "RuleTheWorld",
        HThreatenEmperor = "ThreatenEmperor",
    }
    for class_name, strategy_name in pairs(strategy_classes) do
        SmartAI["useCard" .. class_name] = SmartAI["useCard" .. strategy_name]
    end
end)
sgs.original_hegemony_ai_loading = nil
if not ok then error(error_message) end
sgs.original_hegemony_ai_loaded = true
