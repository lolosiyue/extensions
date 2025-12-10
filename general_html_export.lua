-- 武将统计 HTML 导出和显示模块
-- General Statistics HTML Export and Display Module

local analysis = require "general_analysis"

-- 导出武将详细报告为HTML
function ExportGeneralReportHTML(general_name, output_file)
    local data = require("general_statistics").loadGeneralData()
    if not data or not data.Generals[general_name] then
        return false, "找不到该武将的数据"
    end
    
    local stats = data.Generals[general_name]
    if stats.total_games < 5 then
        return false, "该武将数据不足（少于5局）"
    end
    
    local win_rate = stats.total_wins / stats.total_games * 100
    local styles = analysis.DetermineGeneralStyle(general_name)
    local recommendations = analysis.GenerateRoleRecommendation(general_name)
    local key_cards = analysis.GetKeyCards(general_name, 10)
    local counters = analysis.GetCounterRelations(general_name, 5)
    
    local html = string.format([[
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>%s - 武将详细报告</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: "Microsoft YaHei", Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            padding: 20px;
            min-height: 100vh;
        }
        .container { 
            max-width: 1200px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 20px; 
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 { 
            font-size: 2.5em; 
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.2);
        }
        .header .subtitle {
            font-size: 1.2em;
            opacity: 0.9;
        }
        .content { padding: 40px; }
        .section {
            margin-bottom: 40px;
            animation: fadeIn 0.5s ease-in;
        }
        @keyframes fadeIn {
            from { opacity: 0; transform: translateY(20px); }
            to { opacity: 1; transform: translateY(0); }
        }
        .section h2 {
            color: #667eea;
            font-size: 1.8em;
            margin-bottom: 20px;
            padding-bottom: 10px;
            border-bottom: 3px solid #667eea;
        }
        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
            gap: 20px;
            margin: 20px 0;
        }
        .stat-card {
            background: linear-gradient(135deg, #f5f7fa 0%%, #c3cfe2 100%%);
            padding: 20px;
            border-radius: 15px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
            transition: transform 0.3s ease;
        }
        .stat-card:hover {
            transform: translateY(-5px);
            box-shadow: 0 6px 12px rgba(0,0,0,0.15);
        }
        .stat-card .label {
            font-size: 0.9em;
            color: #666;
            margin-bottom: 5px;
        }
        .stat-card .value {
            font-size: 2em;
            font-weight: bold;
            color: #667eea;
        }
        .tags {
            display: flex;
            flex-wrap: wrap;
            gap: 10px;
            margin: 15px 0;
        }
        .tag {
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            color: white;
            padding: 8px 16px;
            border-radius: 20px;
            font-size: 0.9em;
            font-weight: bold;
            box-shadow: 0 2px 4px rgba(0,0,0,0.2);
        }
        .tag.recommended { background: linear-gradient(135deg, #11998e 0%%, #38ef7d 100%%); }
        .tag.not-recommended { background: linear-gradient(135deg, #eb3349 0%%, #f45c43 100%%); }
        table {
            width: 100%%;
            border-collapse: collapse;
            margin: 15px 0;
            box-shadow: 0 2px 8px rgba(0,0,0,0.1);
        }
        th {
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: bold;
        }
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #e0e0e0;
        }
        tr:hover {
            background-color: #f5f7fa;
        }
        tr:nth-child(even) {
            background-color: #fafafa;
        }
        .progress-bar {
            width: 100%%;
            height: 25px;
            background: #e0e0e0;
            border-radius: 12px;
            overflow: hidden;
            margin: 10px 0;
        }
        .progress-fill {
            height: 100%%;
            background: linear-gradient(90deg, #667eea 0%%, #764ba2 100%%);
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
            font-weight: bold;
            font-size: 0.9em;
            transition: width 1s ease;
        }
        .damage-chart {
            display: flex;
            gap: 10px;
            margin: 20px 0;
        }
        .damage-bar {
            flex: 1;
            min-height: 200px;
            background: linear-gradient(to top, #667eea 0%%, #764ba2 100%%);
            border-radius: 10px 10px 0 0;
            display: flex;
            flex-direction: column;
            justify-content: flex-end;
            align-items: center;
            padding: 10px;
            color: white;
            font-weight: bold;
            transition: all 0.3s ease;
        }
        .damage-bar:hover {
            transform: scale(1.05);
        }
        .role-grid {
            display: grid;
            grid-template-columns: repeat(2, 1fr);
            gap: 15px;
        }
        .role-card {
            padding: 15px;
            border-radius: 10px;
            border: 2px solid #e0e0e0;
        }
        .role-card.high { border-color: #38ef7d; background: #f0fdf4; }
        .role-card.low { border-color: #f45c43; background: #fef2f2; }
        .role-card h3 { margin-bottom: 10px; }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>%s</h1>
            <div class="subtitle">武将详细数据分析报告</div>
        </div>
        
        <div class="content">
]], general_name, general_name)
    
    -- 基础数据
    html = html .. [[
            <div class="section">
                <h2>📊 基础数据</h2>
                <div class="stats-grid">
    ]]
    
    html = html .. string.format([[
                    <div class="stat-card">
                        <div class="label">总场次</div>
                        <div class="value">%d</div>
                    </div>
                    <div class="stat-card">
                        <div class="label">总胜场</div>
                        <div class="value">%d</div>
                    </div>
                    <div class="stat-card">
                        <div class="label">胜率</div>
                        <div class="value">%.1f%%</div>
                    </div>
                    <div class="stat-card">
                        <div class="label">MVP次数</div>
                        <div class="value">%d</div>
                    </div>
    ]], stats.total_games, stats.total_wins, win_rate, stats.mvp_count)
    
    html = html .. [[
                </div>
                <div class="progress-bar">
    ]]
    html = html .. string.format([[
                    <div class="progress-fill" style="width: %.1f%%">胜率 %.1f%%</div>
    ]], win_rate, win_rate)
    html = html .. [[
                </div>
            </div>
    ]]
    
    -- 战斗风格标签
    html = html .. [[
            <div class="section">
                <h2>🎯 战斗风格</h2>
                <div class="tags">
    ]]
    
    for _, style in ipairs(styles) do
        html = html .. string.format([[
                    <div class="tag">%s</div>
        ]], style)
    end
    
    html = html .. [[
                </div>
            </div>
    ]]
    
    -- 身份分析
    html = html .. [[
            <div class="section">
                <h2>👑 身份分析</h2>
    ]]
    
    if recommendations then
        html = html .. [[
                <div style="margin-bottom: 20px;">
        ]]
        
        if #recommendations.recommended > 0 then
            html = html .. [[
                    <div class="tags">
            ]]
            for _, rec in ipairs(recommendations.recommended) do
                html = html .. string.format([[
                        <div class="tag recommended">✓ 推荐 %s (%.1f%%)</div>
                ]], rec.role, rec.win_rate * 100)
            end
            html = html .. [[
                    </div>
            ]]
        end
        
        if #recommendations.not_recommended > 0 then
            html = html .. [[
                    <div class="tags">
            ]]
            for _, rec in ipairs(recommendations.not_recommended) do
                html = html .. string.format([[
                        <div class="tag not-recommended">✗ 不推荐 %s (%.1f%%)</div>
                ]], rec.role, rec.win_rate * 100)
            end
            html = html .. [[
                    </div>
            ]]
        end
        
        html = html .. [[
                </div>
        ]]
    end
    
    -- 身份详细数据表格
    html = html .. [[
                <table>
                    <tr>
                        <th>身份</th>
                        <th>场次</th>
                        <th>胜场</th>
                        <th>胜率</th>
                    </tr>
    ]]
    
    local role_names = { lord = "主公", loyalist = "忠臣", rebel = "反贼", renegade = "内奸" }
    for role, role_data in pairs(stats.roles) do
        if role_data.games > 0 then
            local role_win_rate = role_data.wins / role_data.games * 100
            html = html .. string.format([[
                    <tr>
                        <td><strong>%s</strong></td>
                        <td>%d</td>
                        <td>%d</td>
                        <td><strong>%.1f%%</strong></td>
                    </tr>
            ]], role_names[role], role_data.games, role_data.wins, role_win_rate)
        end
    end
    
    html = html .. [[
                </table>
            </div>
    ]]
    
    -- 战斗数据
    html = html .. [[
            <div class="section">
                <h2>⚔️ 战斗数据</h2>
                <div class="stats-grid">
    ]]
    
    local avg_damage = stats.damage_stats.total_dealt / stats.total_games
    local avg_taken = stats.damage_stats.total_taken / stats.total_games
    local avg_kills = stats.kills / stats.total_games
    
    html = html .. string.format([[
                    <div class="stat-card">
                        <div class="label">场均伤害</div>
                        <div class="value">%.1f</div>
                    </div>
                    <div class="stat-card">
                        <div class="label">场均受伤</div>
                        <div class="value">%.1f</div>
                    </div>
                    <div class="stat-card">
                        <div class="label">场均击杀</div>
                        <div class="value">%.2f</div>
                    </div>
                    <div class="stat-card">
                        <div class="label">单局最高伤害</div>
                        <div class="value">%d</div>
                    </div>
    ]], avg_damage, avg_taken, avg_kills, stats.max_damage_per_game)
    
    html = html .. [[
                </div>
            </div>
    ]]
    
    -- 关键牌推荐
    if key_cards and #key_cards > 0 then
        html = html .. [[
            <div class="section">
                <h2>🃏 关键牌推荐</h2>
                <table>
                    <tr>
                        <th>排名</th>
                        <th>卡牌</th>
                        <th>使用次数</th>
                        <th>胜率</th>
                        <th>场均伤害</th>
                    </tr>
        ]]
        
        for i, card in ipairs(key_cards) do
            html = html .. string.format([[
                    <tr>
                        <td><strong>%d</strong></td>
                        <td>%s</td>
                        <td>%d</td>
                        <td><strong>%.1f%%</strong></td>
                        <td>%.2f</td>
                    </tr>
            ]], i, card.name, card.count, card.win_rate * 100, card.avg_damage)
        end
        
        html = html .. [[
                </table>
            </div>
        ]]
    end
    
    -- 克制关系
    if counters and (#counters.counters > 0 or #counters.countered_by > 0) then
        html = html .. [[
            <div class="section">
                <h2>🎭 克制关系</h2>
        ]]
        
        if #counters.counters > 0 then
            html = html .. [[
                <h3 style="color: #38ef7d; margin: 15px 0;">✓ 克制的武将</h3>
                <table>
                    <tr>
                        <th>武将</th>
                        <th>对战场次</th>
                        <th>胜率</th>
                    </tr>
            ]]
            
            for _, counter in ipairs(counters.counters) do
                html = html .. string.format([[
                    <tr>
                        <td><strong>%s</strong></td>
                        <td>%d</td>
                        <td><strong style="color: #38ef7d;">%.1f%%</strong></td>
                    </tr>
                ]], counter.general, counter.games, counter.win_rate * 100)
            end
            
            html = html .. [[
                </table>
            ]]
        end
        
        if #counters.countered_by > 0 then
            html = html .. [[
                <h3 style="color: #f45c43; margin: 15px 0;">✗ 被克制的武将</h3>
                <table>
                    <tr>
                        <th>武将</th>
                        <th>对战场次</th>
                        <th>胜率</th>
                    </tr>
            ]]
            
            for _, counter in ipairs(counters.countered_by) do
                html = html .. string.format([[
                    <tr>
                        <td><strong>%s</strong></td>
                        <td>%d</td>
                        <td><strong style="color: #f45c43;">%.1f%%</strong></td>
                    </tr>
                ]], counter.general, counter.games, counter.win_rate * 100)
            end
            
            html = html .. [[
                </table>
            ]]
        end
        
        html = html .. [[
            </div>
        ]]
    end
    
    -- 页脚
    html = html .. string.format([[
        </div>
        <div style="text-align: center; padding: 20px; background: #f5f7fa; color: #666;">
            <p>数据生成时间: %s</p>
            <p>三国杀武将统计系统 v1.0</p>
        </div>
    </div>
</body>
</html>
    ]], os.date("%Y-%m-%d %H:%M:%S"))
    
    -- 保存文件
    output_file = output_file or ("general_report_" .. general_name .. ".html")
    local file = io.open(output_file, "w")
    if file then
        file:write(html)
        file:close()
        return true, output_file
    else
        return false, "无法创建文件"
    end
end

-- 导出武将排行榜为HTML
function ExportGeneralRankingHTML(sort_by, min_games, output_file)
    sort_by = sort_by or "win_rate"
    min_games = min_games or 10
    
    local rankings = analysis.GeneralWinRateRanking(sort_by, min_games)
    if not rankings or #rankings == 0 then
        return false, "没有符合条件的数据"
    end
    
    local sort_names = {
        win_rate = "胜率",
        games = "场次",
        avg_damage = "场均伤害",
        mvp_count = "MVP次数",
    }
    
    local html = string.format([[
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>武将排行榜 - 按%s排序</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: "Microsoft YaHei", Arial, sans-serif; 
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            padding: 20px;
        }
        .container { 
            max-width: 1400px; 
            margin: 0 auto; 
            background: white; 
            border-radius: 20px; 
            box-shadow: 0 20px 60px rgba(0,0,0,0.3);
            overflow: hidden;
        }
        .header {
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            color: white;
            padding: 40px;
            text-align: center;
        }
        .header h1 { 
            font-size: 2.5em; 
            margin-bottom: 10px;
        }
        table {
            width: 100%%;
            border-collapse: collapse;
        }
        th {
            background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: bold;
            position: sticky;
            top: 0;
        }
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #e0e0e0;
        }
        tr:hover {
            background-color: #f5f7fa;
        }
        tr:nth-child(even) {
            background-color: #fafafa;
        }
        .rank {
            font-size: 1.2em;
            font-weight: bold;
        }
        .rank.top1 { color: #FFD700; }
        .rank.top2 { color: #C0C0C0; }
        .rank.top3 { color: #CD7F32; }
        .highlight { 
            color: #667eea; 
            font-weight: bold; 
        }
    </style>
</head>
<body>
    <div class="container">
        <div class="header">
            <h1>🏆 武将排行榜</h1>
            <div style="font-size: 1.2em; opacity: 0.9;">排序依据: %s (最少%d场)</div>
        </div>
        
        <table>
            <tr>
                <th>排名</th>
                <th>武将</th>
                <th>场次</th>
                <th>胜场</th>
                <th>胜率</th>
                <th>场均伤害</th>
                <th>场均回合</th>
                <th>MVP次数</th>
                <th>击杀/死亡</th>
            </tr>
    ]], sort_names[sort_by] or sort_by, sort_names[sort_by] or sort_by, min_games)
    
    for i, rank in ipairs(rankings) do
        local rank_class = ""
        if i == 1 then rank_class = "top1"
        elseif i == 2 then rank_class = "top2"
        elseif i == 3 then rank_class = "top3"
        end
        
        html = html .. string.format([[
            <tr>
                <td class="rank %s">%d</td>
                <td><strong>%s</strong></td>
                <td>%d</td>
                <td>%d</td>
                <td class="highlight">%.1f%%</td>
                <td>%.1f</td>
                <td>%.1f</td>
                <td>%d</td>
                <td>%d / %d</td>
            </tr>
        ]], rank_class, i, rank.general, rank.games, rank.wins,
            rank.win_rate * 100, rank.avg_damage, rank.avg_rounds,
            rank.mvp_count, rank.kills, rank.deaths)
    end
    
    html = html .. string.format([[
        </table>
        <div style="text-align: center; padding: 20px; background: #f5f7fa; color: #666;">
            <p>数据生成时间: %s</p>
            <p>共%d个武将 | 三国杀武将统计系统 v1.0</p>
        </div>
    </div>
</body>
</html>
    ]], os.date("%Y-%m-%d %H:%M:%S"), #rankings)
    
    output_file = output_file or ("general_ranking_" .. sort_by .. ".html")
    local file = io.open(output_file, "w")
    if file then
        file:write(html)
        file:close()
        return true, output_file
    else
        return false, "无法创建文件"
    end
end

-- 命令行接口函数
function ShowGeneralReport(general_name)
    local report, err = analysis.GenerateGeneralReport(general_name)
    if report then
        print(report)
        return report
    else
        print("错误: " .. (err or "未知错误"))
        return nil
    end
end

function ShowGeneralRanking(sort_by, min_games)
    sort_by = sort_by or "win_rate"
    min_games = min_games or 10
    
    local rankings = analysis.GeneralWinRateRanking(sort_by, min_games)
    if not rankings or #rankings == 0 then
        print("没有符合条件的数据")
        return nil
    end
    
    print("========================================")
    print(string.format("武将排行榜 (排序: %s, 最少场次: %d)", sort_by, min_games))
    print("========================================")
    print(string.format("%-4s %-20s %8s %8s %10s %10s %10s", 
        "排名", "武将", "场次", "胜场", "胜率", "场均伤害", "MVP"))
    print(string.rep("-", 80))
    
    for i, rank in ipairs(rankings) do
        print(string.format("%-4d %-20s %8d %8d %9.1f%% %10.1f %10d",
            i, rank.general, rank.games, rank.wins,
            rank.win_rate * 100, rank.avg_damage, rank.mvp_count))
    end
    
    print("========================================")
    return rankings
end

return {
    ExportGeneralReportHTML = ExportGeneralReportHTML,
    ExportGeneralRankingHTML = ExportGeneralRankingHTML,
    ShowGeneralReport = ShowGeneralReport,
    ShowGeneralRanking = ShowGeneralRanking,
}
