-- 武将统计分析模块
-- General Statistics Analysis Module
-- 提供数据分析、特色判定、排行榜等功能

require "extensions.general_statistics"

local general_data_file = "general_statistics.json"
local config_file = "general_stats_config.json"

-- 读取数据
local function loadData()
    local json = require "json"
    local file = io.open(general_data_file, "r")
    if not file then return nil end
    local content = file:read("*all")
    file:close()
    return json.decode(content)
end

-- 读取配置
local function loadConfig()
    local json = require "json"
    local file = io.open(config_file, "r")
    if not file then
        -- 返回默认配置（从general_statistics.lua复制）
        return {
            style_thresholds = {
                control = { control_card_ratio = 1.3 },
                damage_dealer = { slash_damage_ratio = 1.4 },
            }
        }
    end
    local content = file:read("*all")
    file:close()
    return json.decode(content)
end

-- 计算全局平均值
function CalculateGlobalAverages()
    local data = loadData()
    if not data or not data.Generals then return nil end
    
    local total_generals = 0
    local averages = {
        games_per_general = 0,
        win_rate = 0,
        avg_damage_dealt = 0,
        avg_damage_taken = 0,
        avg_kills = 0,
        avg_rounds = 0,
        avg_cards_drawn = 0,
        avg_cards_discarded = 0,
        control_cards_per_game = 0,
        slash_damage_ratio = 0,
        aoe_damage_ratio = 0,
    }
    
    for general_name, stats in pairs(data.Generals) do
        if stats.total_games > 0 then
            total_generals = total_generals + 1
            averages.games_per_general = averages.games_per_general + stats.total_games
            averages.win_rate = averages.win_rate + (stats.total_wins / stats.total_games)
            averages.avg_damage_dealt = averages.avg_damage_dealt + (stats.damage_stats.total_dealt / stats.total_games)
            averages.avg_damage_taken = averages.avg_damage_taken + (stats.damage_stats.total_taken / stats.total_games)
            averages.avg_kills = averages.avg_kills + (stats.kills / stats.total_games)
            averages.avg_rounds = averages.avg_rounds + (stats.total_game_rounds / stats.total_games)
            averages.avg_cards_drawn = averages.avg_cards_drawn + (stats.cards_drawn / stats.total_games)
            averages.avg_cards_discarded = averages.avg_cards_discarded + (stats.cards_discarded / stats.total_games)
            
            -- 控制牌占比
            local total_control = stats.control_cards.lebuduan + stats.control_cards.bingliang + 
                                stats.control_cards.snatch + stats.control_cards.dismantlement
            averages.control_cards_per_game = averages.control_cards_per_game + (total_control / stats.total_games)
            
            -- 伤害类型占比
            if stats.damage_stats.total_dealt > 0 then
                averages.slash_damage_ratio = averages.slash_damage_ratio + 
                    (stats.damage_stats.slash_damage / stats.damage_stats.total_dealt)
                averages.aoe_damage_ratio = averages.aoe_damage_ratio + 
                    (stats.damage_stats.aoe_damage / stats.damage_stats.total_dealt)
            end
        end
    end
    
    if total_generals > 0 then
        for key, value in pairs(averages) do
            averages[key] = value / total_generals
        end
    end
    
    return averages
end

-- 计算势力平均值
function CalculateFactionAverages()
    local data = loadData()
    if not data then return nil end
    
    local factions = { wei = {}, shu = {}, wu = {}, qun = {}, god = {} }
    
    for general_name, stats in pairs(data.Generals) do
        local general = sgs.Sanguosha:getGeneral(general_name)
        if general and stats.total_games > 0 then
            local faction = general:getKingdom()
            if not factions[faction] then factions[faction] = {} end
            table.insert(factions[faction], stats)
        end
    end
    
    local faction_averages = {}
    for faction, generals_list in pairs(factions) do
        if #generals_list > 0 then
            faction_averages[faction] = {
                count = #generals_list,
                avg_win_rate = 0,
                avg_damage = 0,
                avg_games = 0,
            }
            
            for _, stats in ipairs(generals_list) do
                faction_averages[faction].avg_win_rate = faction_averages[faction].avg_win_rate + 
                    (stats.total_wins / stats.total_games)
                faction_averages[faction].avg_damage = faction_averages[faction].avg_damage + 
                    (stats.damage_stats.total_dealt / stats.total_games)
                faction_averages[faction].avg_games = faction_averages[faction].avg_games + stats.total_games
            end
            
            faction_averages[faction].avg_win_rate = faction_averages[faction].avg_win_rate / #generals_list
            faction_averages[faction].avg_damage = faction_averages[faction].avg_damage / #generals_list
            faction_averages[faction].avg_games = faction_averages[faction].avg_games / #generals_list
        end
    end
    
    return faction_averages
end

-- 判定武将特色标签
function DetermineGeneralStyle(general_name)
    local data = loadData()
    if not data or not data.Generals[general_name] then return nil end
    
    local stats = data.Generals[general_name]
    if stats.total_games < 5 then
        return { "数据不足" }
    end
    
    local config = loadConfig()
    local averages = CalculateGlobalAverages()
    if not averages then return { "无法计算平均值" } end
    
    local styles = {}
    
    -- 控制系
    local total_control = stats.control_cards.lebuduan + stats.control_cards.bingliang + 
                        stats.control_cards.snatch + stats.control_cards.dismantlement
    local control_per_game = total_control / stats.total_games
    if control_per_game > averages.control_cards_per_game * config.style_thresholds.control.control_card_ratio then
        table.insert(styles, "控制系")
    end
    
    -- 菜刀系
    local slash_ratio = stats.damage_stats.total_dealt > 0 and 
        (stats.damage_stats.slash_damage / stats.damage_stats.total_dealt) or 0
    if slash_ratio > averages.slash_damage_ratio * config.style_thresholds.damage_dealer.slash_damage_ratio then
        table.insert(styles, "菜刀系")
    end
    
    -- 坦克系
    local damage_taken_per_game = stats.damage_stats.total_taken / stats.total_games
    if damage_taken_per_game > averages.avg_damage_taken * 1.3 and 
       stats.total_survival_rounds / stats.total_games > averages.avg_rounds * 1.2 then
        table.insert(styles, "坦克系")
    end
    
    -- 卖血系
    if stats.damage_taken_benefits.cards_drawn > stats.damage_stats.total_taken * 0.5 or
       stats.damage_taken_benefits.damage_dealt > stats.damage_stats.total_dealt * 0.3 then
        table.insert(styles, "卖血系")
    end
    
    -- 辅助系
    if stats.hp_recovered_others > stats.total_games * 2 then
        table.insert(styles, "辅助系")
    end
    
    -- 爆发系
    if stats.max_damage_per_round > averages.avg_damage_dealt * 2 then
        table.insert(styles, "爆发系")
    end
    
    -- 过牌系
    local draw_per_game = stats.cards_drawn / stats.total_games
    if draw_per_game > averages.avg_cards_drawn * 1.3 then
        table.insert(styles, "过牌系")
    end
    
    -- AOE系
    local aoe_ratio = stats.damage_stats.total_dealt > 0 and 
        (stats.damage_stats.aoe_damage / stats.damage_stats.total_dealt) or 0
    if aoe_ratio > averages.aoe_damage_ratio * 1.5 then
        table.insert(styles, "AOE系")
    end
    
    -- 速战速决
    local avg_rounds = stats.total_game_rounds / stats.total_games
    if avg_rounds < averages.avg_rounds * 0.8 then
        table.insert(styles, "速战速决")
    end
    
    -- 拉长战线
    if avg_rounds > averages.avg_rounds * 1.2 then
        table.insert(styles, "拉长战线")
    end
    
    -- 发育型
    if stats.late_damage > 0 and stats.early_damage > 0 then
        local growth_ratio = stats.late_damage / stats.early_damage
        if growth_ratio > 1.5 then
            table.insert(styles, "发育型")
        end
    end
    
    if #styles == 0 then
        table.insert(styles, "均衡型")
    end
    
    return styles
end

-- 生成身份推荐
function GenerateRoleRecommendation(general_name)
    local data = loadData()
    if not data or not data.Generals[general_name] then return nil end
    
    local stats = data.Generals[general_name]
    local config = loadConfig()
    local min_games = config.role_recommendation.min_games
    
    local recommendations = {
        recommended = {},
        not_recommended = {},
        neutral = {},
    }
    
    for role, role_data in pairs(stats.roles) do
        if role_data.games >= min_games then
            local win_rate = role_data.wins / role_data.games
            
            local role_name = ""
            if role == "lord" then role_name = "主公"
            elseif role == "loyalist" then role_name = "忠臣"
            elseif role == "rebel" then role_name = "反贼"
            elseif role == "renegade" then role_name = "内奸"
            end
            
            if win_rate >= config.role_recommendation.strong_threshold then
                table.insert(recommendations.recommended, {
                    role = role_name,
                    win_rate = win_rate,
                    games = role_data.games,
                })
            elseif win_rate <= config.role_recommendation.weak_threshold then
                table.insert(recommendations.not_recommended, {
                    role = role_name,
                    win_rate = win_rate,
                    games = role_data.games,
                })
            else
                table.insert(recommendations.neutral, {
                    role = role_name,
                    win_rate = win_rate,
                    games = role_data.games,
                })
            end
        end
    end
    
    return recommendations
end

-- 获取关键牌
function GetKeyCards(general_name, top_n)
    top_n = top_n or 10
    local data = loadData()
    if not data or not data.Generals[general_name] then return nil end
    
    local stats = data.Generals[general_name]
    local cards_list = {}
    
    for card_name, card_data in pairs(stats.cards_used) do
        local win_rate = card_data.count > 0 and (card_data.win_count / card_data.count) or 0
        local avg_damage = card_data.count > 0 and (card_data.damage / card_data.count) or 0
        
        table.insert(cards_list, {
            name = card_name,
            count = card_data.count,
            win_rate = win_rate,
            avg_damage = avg_damage,
            score = card_data.count * win_rate * (1 + avg_damage * 0.1), -- 综合评分
        })
    end
    
    table.sort(cards_list, function(a, b) return a.score > b.score end)
    
    local result = {}
    for i = 1, math.min(top_n, #cards_list) do
        table.insert(result, cards_list[i])
    end
    
    return result
end

-- 获取克制关系
function GetCounterRelations(general_name, top_n)
    top_n = top_n or 5
    local data = loadData()
    if not data or not data.Generals[general_name] then return nil end
    
    local stats = data.Generals[general_name]
    local relations = {
        counters = {},  -- 克制的武将
        countered_by = {},  -- 被克制的武将
    }
    
    for enemy_general, versus_data in pairs(stats.versus) do
        if versus_data.games >= 5 then
            local win_rate = versus_data.wins / versus_data.games
            
            if win_rate >= 0.6 then
                table.insert(relations.counters, {
                    general = enemy_general,
                    games = versus_data.games,
                    win_rate = win_rate,
                })
            elseif win_rate <= 0.4 then
                table.insert(relations.countered_by, {
                    general = enemy_general,
                    games = versus_data.games,
                    win_rate = win_rate,
                })
            end
        end
    end
    
    table.sort(relations.counters, function(a, b) return a.win_rate > b.win_rate end)
    table.sort(relations.countered_by, function(a, b) return a.win_rate < b.win_rate end)
    
    return {
        counters = table.sub(relations.counters, 1, top_n),
        countered_by = table.sub(relations.countered_by, 1, top_n),
    }
end

-- 武将胜率排行榜
function GeneralWinRateRanking(sort_by, min_games)
    sort_by = sort_by or "win_rate"  -- win_rate, games, avg_damage, mvp_count
    min_games = min_games or 10
    
    local data = loadData()
    if not data then return nil end
    
    local rankings = {}
    for general_name, stats in pairs(data.Generals) do
        if stats.total_games >= min_games then
            local win_rate = stats.total_wins / stats.total_games
            local avg_damage = stats.damage_stats.total_dealt / stats.total_games
            local avg_rounds = stats.total_game_rounds / stats.total_games
            
            table.insert(rankings, {
                general = general_name,
                games = stats.total_games,
                wins = stats.total_wins,
                win_rate = win_rate,
                avg_damage = avg_damage,
                avg_rounds = avg_rounds,
                mvp_count = stats.mvp_count,
                kills = stats.kills,
                deaths = stats.deaths,
            })
        end
    end
    
    -- 排序
    if sort_by == "win_rate" then
        table.sort(rankings, function(a, b) return a.win_rate > b.win_rate end)
    elseif sort_by == "games" then
        table.sort(rankings, function(a, b) return a.games > b.games end)
    elseif sort_by == "avg_damage" then
        table.sort(rankings, function(a, b) return a.avg_damage > b.avg_damage end)
    elseif sort_by == "mvp_count" then
        table.sort(rankings, function(a, b) return a.mvp_count > b.mvp_count end)
    end
    
    return rankings
end

-- 生成武将详细报告
function GenerateGeneralReport(general_name)
    local data = loadData()
    if not data or not data.Generals[general_name] then
        return nil, "找不到该武将的数据"
    end
    
    local stats = data.Generals[general_name]
    if stats.total_games < 5 then
        return nil, "该武将数据不足（少于5局）"
    end
    
    local report = {}
    
    -- 标题
    table.insert(report, "========================================")
    table.insert(report, "武将详细报告: " .. general_name)
    table.insert(report, "========================================")
    table.insert(report, "")
    
    -- 基础数据
    table.insert(report, "【基础数据】")
    table.insert(report, string.format("总场次: %d", stats.total_games))
    table.insert(report, string.format("总胜场: %d", stats.total_wins))
    local win_rate = stats.total_wins / stats.total_games * 100
    table.insert(report, string.format("胜率: %.2f%%", win_rate))
    table.insert(report, string.format("MVP次数: %d (%.2f%%)", stats.mvp_count, 
        stats.mvp_count / stats.total_games * 100))
    table.insert(report, "")
    
    -- 回合数据
    table.insert(report, "【回合数据】")
    table.insert(report, string.format("场均总回合数: %.2f", stats.total_game_rounds / stats.total_games))
    table.insert(report, string.format("场均存活回合: %.2f", stats.total_survival_rounds / stats.total_games))
    table.insert(report, string.format("场均行动回合: %.2f", stats.total_action_rounds / stats.total_games))
    table.insert(report, "")
    
    -- 身份分析
    table.insert(report, "【身份分析】")
    local role_names = { lord = "主公", loyalist = "忠臣", rebel = "反贼", renegade = "内奸" }
    for role, role_data in pairs(stats.roles) do
        if role_data.games > 0 then
            local role_win_rate = role_data.wins / role_data.games * 100
            table.insert(report, string.format("%s: %d局, 胜%d场, 胜率%.2f%%", 
                role_names[role], role_data.games, role_data.wins, role_win_rate))
        end
    end
    
    -- 身份推荐
    local recommendations = GenerateRoleRecommendation(general_name)
    if recommendations and #recommendations.recommended > 0 then
        local rec_roles = {}
        for _, rec in ipairs(recommendations.recommended) do
            table.insert(rec_roles, rec.role)
        end
        table.insert(report, string.format("推荐身份: %s", table.concat(rec_roles, "、")))
    end
    if recommendations and #recommendations.not_recommended > 0 then
        local not_rec_roles = {}
        for _, rec in ipairs(recommendations.not_recommended) do
            table.insert(not_rec_roles, rec.role)
        end
        table.insert(report, string.format("不推荐身份: %s", table.concat(not_rec_roles, "、")))
    end
    table.insert(report, "")
    
    -- 战斗风格标签
    table.insert(report, "【战斗风格】")
    local styles = DetermineGeneralStyle(general_name)
    table.insert(report, "特色标签: " .. table.concat(styles, "、"))
    table.insert(report, "")
    
    -- 战斗数据
    table.insert(report, "【战斗数据】")
    table.insert(report, string.format("场均伤害: %.2f", stats.damage_stats.total_dealt / stats.total_games))
    table.insert(report, string.format("  - 【杀】伤害: %.2f (%.1f%%)", 
        stats.damage_stats.slash_damage / stats.total_games,
        stats.damage_stats.total_dealt > 0 and stats.damage_stats.slash_damage / stats.damage_stats.total_dealt * 100 or 0))
    table.insert(report, string.format("  - 决斗伤害: %.2f", stats.damage_stats.duel_damage / stats.total_games))
    table.insert(report, string.format("  - AOE伤害: %.2f", stats.damage_stats.aoe_damage / stats.total_games))
    table.insert(report, string.format("  - 技能伤害: %.2f", stats.damage_stats.skill_damage / stats.total_games))
    table.insert(report, string.format("场均受伤: %.2f", stats.damage_stats.total_taken / stats.total_games))
    table.insert(report, string.format("场均击杀: %.2f", stats.kills / stats.total_games))
    table.insert(report, string.format("单局最高伤害: %d", stats.max_damage_per_game))
    table.insert(report, "")
    
    -- 关键牌推荐
    table.insert(report, "【关键牌推荐】")
    local key_cards = GetKeyCards(general_name, 10)
    if key_cards then
        for i, card in ipairs(key_cards) do
            table.insert(report, string.format("%d. %s - 使用%d次, 胜率%.2f%%, 场均伤害%.2f", 
                i, card.name, card.count, card.win_rate * 100, card.avg_damage))
        end
    end
    table.insert(report, "")
    
    -- 常用技能
    table.insert(report, "【技能使用统计】")
    local skills_list = {}
    for skill_name, count in pairs(stats.skills_used) do
        table.insert(skills_list, { name = skill_name, count = count })
    end
    table.sort(skills_list, function(a, b) return a.count > b.count end)
    for i = 1, math.min(10, #skills_list) do
        table.insert(report, string.format("%d. %s - 使用%d次 (场均%.2f次)", 
            i, skills_list[i].name, skills_list[i].count, skills_list[i].count / stats.total_games))
    end
    table.insert(report, "")
    
    -- 克制关系
    table.insert(report, "【克制关系】")
    local counters = GetCounterRelations(general_name, 5)
    if counters then
        if #counters.counters > 0 then
            table.insert(report, "克制的武将:")
            for i, counter in ipairs(counters.counters) do
                table.insert(report, string.format("  %d. %s - 对战%d局, 胜率%.2f%%", 
                    i, counter.general, counter.games, counter.win_rate * 100))
            end
        end
        if #counters.countered_by > 0 then
            table.insert(report, "被克制的武将:")
            for i, counter in ipairs(counters.countered_by) do
                table.insert(report, string.format("  %d. %s - 对战%d局, 胜率%.2f%%", 
                    i, counter.general, counter.games, counter.win_rate * 100))
            end
        end
    end
    table.insert(report, "")
    
    table.insert(report, "========================================")
    
    return table.concat(report, "\n"), nil
end

-- 生成生涯回顾
function GenerateCareerReview(general_name)
    -- 生涯回顾就是详细报告的另一个名字
    return GenerateGeneralReport(general_name)
end

-- 导出函数
return {
    CalculateGlobalAverages = CalculateGlobalAverages,
    CalculateFactionAverages = CalculateFactionAverages,
    DetermineGeneralStyle = DetermineGeneralStyle,
    GenerateRoleRecommendation = GenerateRoleRecommendation,
    GetKeyCards = GetKeyCards,
    GetCounterRelations = GetCounterRelations,
    GeneralWinRateRanking = GeneralWinRateRanking,
    GenerateGeneralReport = GenerateGeneralReport,
    GenerateCareerReview = GenerateCareerReview,
}
