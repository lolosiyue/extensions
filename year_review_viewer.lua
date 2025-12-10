-- 年度回顾数据查看器
-- Year Review Data Viewer
-- 用于查看和分析 year_review_data.json 中的数据

local json = require "json"

-- 读取年度回顾数据
local function loadData()
    local file = io.open("year_review_data.json", "r")
    if not file then
        print("错误: 找不到 year_review_data.json 文件")
        return nil
    end
    
    local content = file:read("*all")
    file:close()
    
    local data = json.decode(content)
    if not data then
        print("错误: JSON 文件格式错误")
        return nil
    end
    
    return data
end

-- 列出所有玩家
function ListAllPlayers()
    local data = loadData()
    if not data or not data.PlayerStats then
        return
    end
    
    print("========================================")
    print("所有玩家列表")
    print("========================================")
    
    local player_count = 0
    for player_name, years in pairs(data.PlayerStats) do
        player_count = player_count + 1
        print(string.format("%d. %s", player_count, player_name))
        
        -- 显示该玩家有数据的年份
        local year_list = {}
        for year, _ in pairs(years) do
            table.insert(year_list, year)
        end
        table.sort(year_list)
        print("   年份: " .. table.concat(year_list, ", "))
    end
    
    print("========================================")
    print("总计: " .. player_count .. " 个玩家")
    print("========================================")
end

-- 列出某个年份的所有玩家排行
function RankPlayersByYear(year)
    year = year or os.date("%Y")
    local data = loadData()
    if not data or not data.PlayerStats then
        return
    end
    
    print("========================================")
    print(year .. " 年度玩家排行榜")
    print("========================================")
    
    local rankings = {}
    for player_name, years in pairs(data.PlayerStats) do
        if years[year] then
            local stats = years[year]
            table.insert(rankings, {
                name = player_name,
                games = stats.total_games,
                wins = stats.total_wins,
                win_rate = stats.total_games > 0 and (stats.total_wins / stats.total_games * 100) or 0
            })
        end
    end
    
    if #rankings == 0 then
        print("该年份没有玩家数据")
        return
    end
    
    -- 按场次排序
    table.sort(rankings, function(a, b) return a.games > b.games end)
    
    print("\n【按场次排名】")
    print(string.format("%-4s %-20s %8s %8s %10s", "排名", "玩家名", "场次", "胜场", "胜率"))
    print(string.rep("-", 60))
    for i = 1, math.min(20, #rankings) do
        local p = rankings[i]
        print(string.format("%-4d %-20s %8d %8d %9.2f%%", 
            i, p.name, p.games, p.wins, p.win_rate))
    end
    
    -- 按胜率排序（至少10场）
    local min_games = 10
    local win_rate_rankings = {}
    for _, p in ipairs(rankings) do
        if p.games >= min_games then
            table.insert(win_rate_rankings, p)
        end
    end
    table.sort(win_rate_rankings, function(a, b) return a.win_rate > b.win_rate end)
    
    print("\n【按胜率排名】（至少" .. min_games .. "场）")
    print(string.format("%-4s %-20s %8s %8s %10s", "排名", "玩家名", "场次", "胜场", "胜率"))
    print(string.rep("-", 60))
    for i = 1, math.min(20, #win_rate_rankings) do
        local p = win_rate_rankings[i]
        print(string.format("%-4d %-20s %8d %8d %9.2f%%", 
            i, p.name, p.games, p.wins, p.win_rate))
    end
    
    print("========================================")
end

-- 显示年份总览
function YearOverview(year)
    year = year or os.date("%Y")
    local data = loadData()
    if not data or not data.PlayerStats then
        return
    end
    
    print("========================================")
    print(year .. " 年度数据总览")
    print("========================================")
    
    local total_games = 0
    local total_players = 0
    local all_generals = {}
    local all_skills = {}
    local all_cards = {}
    
    for player_name, years in pairs(data.PlayerStats) do
        if years[year] then
            total_players = total_players + 1
            local stats = years[year]
            total_games = total_games + stats.total_games
            
            -- 统计武将
            for general, gdata in pairs(stats.generals) do
                if not all_generals[general] then
                    all_generals[general] = { play_count = 0, win_count = 0 }
                end
                all_generals[general].play_count = all_generals[general].play_count + gdata.play_count
                all_generals[general].win_count = all_generals[general].win_count + gdata.win_count
            end
            
            -- 统计技能
            for skill, count in pairs(stats.skills_used) do
                if not all_skills[skill] then
                    all_skills[skill] = 0
                end
                all_skills[skill] = all_skills[skill] + count
            end
            
            -- 统计卡牌
            for card, count in pairs(stats.cards_used) do
                if not all_cards[card] then
                    all_cards[card] = 0
                end
                all_cards[card] = all_cards[card] + count
            end
        end
    end
    
    print("\n【基本统计】")
    print("活跃玩家数: " .. total_players)
    print("总场次: " .. total_games)
    if total_players > 0 then
        print("人均场次: " .. string.format("%.2f", total_games / total_players))
    end
    
    -- 最热门武将
    print("\n【最热门武将 Top 10】")
    local general_list = {}
    for general, gdata in pairs(all_generals) do
        table.insert(general_list, {
            name = general,
            count = gdata.play_count,
            wins = gdata.win_count
        })
    end
    table.sort(general_list, function(a, b) return a.count > b.count end)
    
    print(string.format("%-4s %-20s %8s %8s %10s", "排名", "武将", "使用次数", "胜场", "胜率"))
    print(string.rep("-", 60))
    for i = 1, math.min(10, #general_list) do
        local g = general_list[i]
        local win_rate = g.count > 0 and (g.wins / g.count * 100) or 0
        print(string.format("%-4d %-20s %8d %8d %9.2f%%", 
            i, g.name, g.count, g.wins, win_rate))
    end
    
    -- 最常用技能
    print("\n【最常用技能 Top 10】")
    local skill_list = {}
    for skill, count in pairs(all_skills) do
        table.insert(skill_list, { name = skill, count = count })
    end
    table.sort(skill_list, function(a, b) return a.count > b.count end)
    
    for i = 1, math.min(10, #skill_list) do
        local s = skill_list[i]
        print(string.format("%2d. %-30s %8d次", i, s.name, s.count))
    end
    
    -- 最常用卡牌
    print("\n【最常用卡牌 Top 10】")
    local card_list = {}
    for card, count in pairs(all_cards) do
        table.insert(card_list, { name = card, count = count })
    end
    table.sort(card_list, function(a, b) return a.count > b.count end)
    
    for i = 1, math.min(10, #card_list) do
        local c = card_list[i]
        print(string.format("%2d. %-30s %8d次", i, c.name, c.count))
    end
    
    print("========================================")
end

-- 比较两个玩家
function ComparePlayers(player1, player2, year)
    year = year or os.date("%Y")
    local data = loadData()
    if not data or not data.PlayerStats then
        return
    end
    
    local stats1 = data.PlayerStats[player1] and data.PlayerStats[player1][year]
    local stats2 = data.PlayerStats[player2] and data.PlayerStats[player2][year]
    
    if not stats1 or not stats2 then
        print("错误: 找不到玩家数据")
        return
    end
    
    print("========================================")
    print("玩家对比: " .. player1 .. " vs " .. player2)
    print(year .. " 年度数据")
    print("========================================")
    
    local function compare_stat(name, val1, val2, format_str)
        format_str = format_str or "%d"
        local diff = val2 - val1
        local diff_str = diff >= 0 and ("+" .. string.format(format_str, diff)) or string.format(format_str, diff)
        print(string.format("%-20s %15s %15s %15s", 
            name, 
            string.format(format_str, val1), 
            string.format(format_str, val2),
            diff_str))
    end
    
    print(string.format("%-20s %15s %15s %15s", "项目", player1, player2, "差距"))
    print(string.rep("-", 70))
    
    compare_stat("总场次", stats1.total_games, stats2.total_games)
    compare_stat("总胜场", stats1.total_wins, stats2.total_wins)
    
    local win_rate1 = stats1.total_games > 0 and (stats1.total_wins / stats1.total_games * 100) or 0
    local win_rate2 = stats2.total_games > 0 and (stats2.total_wins / stats2.total_games * 100) or 0
    compare_stat("胜率", win_rate1, win_rate2, "%.2f%%")
    
    compare_stat("造成伤害", stats1.damage_dealt, stats2.damage_dealt)
    compare_stat("承受伤害", stats1.damage_taken, stats2.damage_taken)
    compare_stat("击杀数", stats1.kills, stats2.kills)
    compare_stat("死亡数", stats1.deaths, stats2.deaths)
    compare_stat("摸牌数", stats1.card_drawn, stats2.card_drawn)
    compare_stat("弃牌数", stats1.card_discarded, stats2.card_discarded)
    
    print("========================================")
end

-- 查找使用特定武将最多的玩家
function FindTopPlayerForGeneral(general_name, year)
    year = year or os.date("%Y")
    local data = loadData()
    if not data or not data.PlayerStats then
        return
    end
    
    print("========================================")
    print("武将「" .. general_name .. "」使用排行")
    print(year .. " 年度")
    print("========================================")
    
    local rankings = {}
    for player_name, years in pairs(data.PlayerStats) do
        if years[year] and years[year].generals[general_name] then
            local gdata = years[year].generals[general_name]
            table.insert(rankings, {
                player = player_name,
                count = gdata.play_count,
                wins = gdata.win_count,
                win_rate = gdata.play_count > 0 and (gdata.win_count / gdata.play_count * 100) or 0
            })
        end
    end
    
    if #rankings == 0 then
        print("没有玩家使用过该武将")
        return
    end
    
    table.sort(rankings, function(a, b) return a.count > b.count end)
    
    print(string.format("%-4s %-20s %8s %8s %10s", "排名", "玩家", "使用次数", "胜场", "胜率"))
    print(string.rep("-", 60))
    for i = 1, math.min(20, #rankings) do
        local p = rankings[i]
        print(string.format("%-4d %-20s %8d %8d %9.2f%%", 
            i, p.player, p.count, p.wins, p.win_rate))
    end
    
    print("========================================")
end

-- 主菜单
function YearReviewDataViewer()
    print("\n")
    print("╔════════════════════════════════════════╗")
    print("║      年度回顾数据查看器 v1.0          ║")
    print("╚════════════════════════════════════════╝")
    print()
    print("可用命令:")
    print("  ListAllPlayers()                    - 列出所有玩家")
    print("  RankPlayersByYear('2024')           - 显示年度排行榜")
    print("  YearOverview('2024')                - 显示年度总览")
    print("  ComparePlayers('玩家1', '玩家2')    - 对比两个玩家")
    print("  FindTopPlayerForGeneral('武将名')   - 查找武将使用排行")
    print("  ShowYearReview('玩家名')            - 显示玩家年度回顾")
    print()
    print("提示: 年份参数可以省略，默认为当前年份")
    print()
end

-- 启动查看器
YearReviewDataViewer()

-- 导出函数供外部使用
return {
    ListAllPlayers = ListAllPlayers,
    RankPlayersByYear = RankPlayersByYear,
    YearOverview = YearOverview,
    ComparePlayers = ComparePlayers,
    FindTopPlayerForGeneral = FindTopPlayerForGeneral
}
