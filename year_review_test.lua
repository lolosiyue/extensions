-- 年度回顾功能测试和使用示例
-- Year Review Feature Test and Usage Examples

-- 引入年度回顾模块
require "extensions.year_review"

print("========================================")
print("年度回顾功能测试程序")
print("========================================")
print()

-- 示例1: 查看当前年度回顾
print("【示例1】查看玩家的当前年度回顾")
print("用法: ShowYearReview('玩家名')")
print()

-- 示例调用（需要实际的玩家名）
-- local report = ShowYearReview("Player1")
-- if report then
--     print("成功生成年度回顾！")
-- else
--     print("该玩家暂无年度数据")
-- end

-- 示例2: 查看指定年份的回顾
print("【示例2】查看玩家的指定年份回顾")
print("用法: ShowYearReview('玩家名', '2024')")
print()

-- 示例3: 导出HTML格式报告
print("【示例3】导出HTML格式的年度回顾")
print("用法: ExportYearReviewHTML('玩家名', '2024', 'output.html')")
print()

-- 实际使用示例
-- local success, result = ExportYearReviewHTML("Player1", "2024", "player1_2024_review.html")
-- if success then
--     print("成功导出到文件: " .. result)
-- else
--     print("导出失败: " .. result)
-- end

-- 示例4: 在游戏结束时自动生成回顾
print("【示例4】游戏结束后自动生成回顾")
print("可以在游戏结束触发器中添加以下代码：")
print([[
YearReviewAutoShow = sgs.CreateTriggerSkill{
    name = "year_review_auto_show",
    events = { sgs.GameOverJudge },
    global = true,
    can_trigger = function(self, player)
        return player and player:objectName() == player:getRoom():getOwner():objectName()
    end,
    on_trigger = function(self, event, player, data)
        -- 在游戏结束时显示房主的年度回顾
        ShowYearReview(player:objectName())
        return false
    end
}
]])
print()

-- 示例5: 创建一个简单的查询界面
print("【示例5】创建查询界面")
print([[
function QueryYearReview(room, player)
    -- 询问玩家要查看哪一年的数据
    local current_year = os.date("%Y")
    local years = {}
    for i = 0, 5 do
        table.insert(years, tostring(tonumber(current_year) - i))
    end
    
    -- 这里可以用游戏的选择界面让玩家选择年份
    -- 然后调用 ShowYearReview 显示结果
    local year = current_year  -- 默认当前年份
    local report = ShowYearReview(player:objectName(), year)
    
    if report then
        -- 将报告发送给玩家
        room:broadcastInvoke("speak", player:objectName() .. ":" .. report)
    end
end
]])
print()

-- 示例6: 数据备份功能
print("【示例6】备份年度数据")
print([[
function BackupYearReviewData()
    local json = require "json"
    local source_file = "year_review_data.json"
    local backup_file = "year_review_data_backup_" .. os.date("%Y%m%d_%H%M%S") .. ".json"
    
    local file = io.open(source_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        
        local backup = io.open(backup_file, "w")
        if backup then
            backup:write(content)
            backup:close()
            print("备份成功: " .. backup_file)
            return true
        end
    end
    print("备份失败")
    return false
end
]])
print()

-- 示例7: 比较两个年份的数据
print("【示例7】比较不同年份的数据")
print([[
function CompareYears(player_name, year1, year2)
    local json = require "json"
    local file = io.open("year_review_data.json", "r")
    if not file then
        return "没有找到数据文件"
    end
    
    local content = file:read("*all")
    file:close()
    local data = json.decode(content)
    
    if not data.PlayerStats[player_name] then
        return "没有找到该玩家的数据"
    end
    
    local stats1 = data.PlayerStats[player_name][year1]
    local stats2 = data.PlayerStats[player_name][year2]
    
    if not stats1 or not stats2 then
        return "缺少某个年份的数据"
    end
    
    local report = {}
    table.insert(report, "======== 年度对比：" .. year1 .. " vs " .. year2 .. " ========")
    table.insert(report, "")
    table.insert(report, string.format("总场次: %d → %d (%+d)", 
        stats1.total_games, stats2.total_games, stats2.total_games - stats1.total_games))
    table.insert(report, string.format("总胜场: %d → %d (%+d)", 
        stats1.total_wins, stats2.total_wins, stats2.total_wins - stats1.total_wins))
    
    local win_rate1 = stats1.total_games > 0 and (stats1.total_wins / stats1.total_games * 100) or 0
    local win_rate2 = stats2.total_games > 0 and (stats2.total_wins / stats2.total_games * 100) or 0
    table.insert(report, string.format("胜率: %.2f%% → %.2f%% (%+.2f%%)", 
        win_rate1, win_rate2, win_rate2 - win_rate1))
    
    table.insert(report, "")
    table.insert(report, "==============================")
    
    return table.concat(report, "\n")
end
]])
print()

-- 示例8: 排行榜功能
print("【示例8】生成武将使用排行榜")
print([[
function GenerateGeneralRanking(player_name, year)
    local json = require "json"
    local file = io.open("year_review_data.json", "r")
    if not file then
        return "没有找到数据文件"
    end
    
    local content = file:read("*all")
    file:close()
    local data = json.decode(content)
    
    if not data.PlayerStats[player_name] or not data.PlayerStats[player_name][year] then
        return "没有找到数据"
    end
    
    local stats = data.PlayerStats[player_name][year]
    local ranking = {}
    
    -- 按使用次数排序
    for general, gdata in pairs(stats.generals) do
        table.insert(ranking, {
            name = general,
            count = gdata.play_count,
            wins = gdata.win_count
        })
    end
    
    table.sort(ranking, function(a, b) return a.count > b.count end)
    
    local report = {}
    table.insert(report, "======== 武将使用排行榜 ========")
    for i = 1, math.min(20, #ranking) do
        local g = ranking[i]
        local win_rate = g.count > 0 and (g.wins / g.count * 100) or 0
        table.insert(report, string.format("%2d. %-15s 使用:%3d次  胜:%3d场  胜率:%.2f%%",
            i, g.name, g.count, g.wins, win_rate))
    end
    table.insert(report, "==============================")
    
    return table.concat(report, "\n")
end
]])
print()

print("========================================")
print("测试程序加载完成")
print("请在游戏中使用上述函数来查看年度回顾")
print("========================================")
print()

-- 提示如何在游戏中使用
print("快速使用指南：")
print("1. 游戏会自动记录所有数据")
print("2. 游戏结束后，在Lua控制台输入：")
print("   ShowYearReview('你的玩家名')")
print("3. 导出HTML报告：")
print("   ExportYearReviewHTML('你的玩家名')")
print()
