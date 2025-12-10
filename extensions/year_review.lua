-- 年度回顾功能模块
-- Year Review Feature Module
-- 统计玩家的年度游戏数据，包括武将使用、胜率、技能/锦囊使用等

year_review_extension = sgs.Package("year_review")

-- 数据存储文件
local year_review_data_file = "year_review_data.json"

-- 读取年度回顾数据
local function readYearReviewData()
    local json = require "json"
    local file = io.open(year_review_data_file, "r")
    local data = {
        GameModes = {},    -- 按游戏模式分类的玩家统计数据 { mode_name = { PlayerStats = {} } }
        CurrentYear = os.date("%Y")  -- 当前年份
    }
    if file ~= nil then
        local content = file:read("*all")
        data = json.decode(content) or data
        file:close()
    end
    return data
end

-- 写入年度回顾数据
local function writeYearReviewData(data)
    local json = require "json"
    local file = assert(io.open(year_review_data_file, "w"))
    local content = json.encode(data, { indent = true, level = 1 })
    file:write(content)
    file:close()
end

-- 初始化玩家数据结构
local function initPlayerStats(player_name, year)
    return {
        year = year,
        player_name = player_name,
        generals = {},  -- 武将使用数据 { general_name = { play_count, win_count } }
        total_games = 0,  -- 总场次
        total_wins = 0,  -- 总胜场
        skills_used = {},  -- 技能使用次数 { skill_name = count }
        cards_used = {},  -- 锦囊/装备使用次数 { card_name = count }
        damage_dealt = 0,  -- 总伤害
        damage_taken = 0,  -- 总受伤
        kills = 0,  -- 击杀数
        deaths = 0,  -- 死亡数
        card_drawn = 0,  -- 摸牌数
        card_discarded = 0,  -- 弃牌数
        roles_stats = {  -- 身份统计
            lord = { play = 0, win = 0 },
            loyalist = { play = 0, win = 0 },
            rebel = { play = 0, win = 0 },
            renegade = { play = 0, win = 0 }
        }
    }
end

-- 获取或创建玩家年度统计数据
local function getPlayerYearStats(data, player_name, year, game_mode)
    game_mode = game_mode or "standard"  -- 默认模式
    
    if not data.GameModes[game_mode] then
        data.GameModes[game_mode] = { PlayerStats = {} }
    end
    
    if not data.GameModes[game_mode].PlayerStats[player_name] then
        data.GameModes[game_mode].PlayerStats[player_name] = {}
    end
    
    if not data.GameModes[game_mode].PlayerStats[player_name][year] then
        data.GameModes[game_mode].PlayerStats[player_name][year] = initPlayerStats(player_name, year)
    end
    
    return data.GameModes[game_mode].PlayerStats[player_name][year]
end

-- 记录游戏开始时的数据
local function recordGameStart(player)
    local room = player:getRoom()
    local game_mode = room:getMode()  -- 获取游戏模式
    
    local data = readYearReviewData()
    local year = os.date("%Y")
    local player_name = player:objectName()
    local stats = getPlayerYearStats(data, player_name, year, game_mode)
    
    -- 记录总场次
    stats.total_games = stats.total_games + 1
    
    -- 记录武将使用
    local general_name = player:getGeneralName()
    if not stats.generals[general_name] then
        stats.generals[general_name] = { play_count = 0, win_count = 0 }
    end
    stats.generals[general_name].play_count = stats.generals[general_name].play_count + 1
    
    -- 如果是双将，记录第二个武将
    if player:getGeneral2() then
        local general2_name = player:getGeneral2Name()
        if not stats.generals[general2_name] then
            stats.generals[general2_name] = { play_count = 0, win_count = 0 }
        end
        stats.generals[general2_name].play_count = stats.generals[general2_name].play_count + 1
    end
    
    -- 记录身份
    local role = player:getRole()
    if stats.roles_stats[role] then
        stats.roles_stats[role].play = stats.roles_stats[role].play + 1
    end
    
    writeYearReviewData(data)
end

-- 记录游戏结束时的数据
local function recordGameEnd(player, is_winner)
    local room = player:getRoom()
    local game_mode = room:getMode()
    
    local data = readYearReviewData()
    local year = os.date("%Y")
    local player_name = player:objectName()
    local stats = getPlayerYearStats(data, player_name, year, game_mode)
    
    if is_winner then
        -- 记录胜利
        stats.total_wins = stats.total_wins + 1
        
        -- 记录武将胜利
        local general_name = player:getGeneralName()
        if stats.generals[general_name] then
            stats.generals[general_name].win_count = stats.generals[general_name].win_count + 1
        end
        
        if player:getGeneral2() then
            local general2_name = player:getGeneral2Name()
            if stats.generals[general2_name] then
                stats.generals[general2_name].win_count = stats.generals[general2_name].win_count + 1
            end
        end
        
        -- 记录身份胜利
        local role = player:getRole()
        if stats.roles_stats[role] then
            stats.roles_stats[role].win = stats.roles_stats[role].win + 1
        end
    end
    
    writeYearReviewData(data)
end

-- 记录技能使用
local function recordSkillUsed(player, skill_name)
    local room = player:getRoom()
    local game_mode = room:getMode()
    
    local data = readYearReviewData()
    local year = os.date("%Y")
    local player_name = player:objectName()
    local stats = getPlayerYearStats(data, player_name, year, game_mode)
    
    if not stats.skills_used[skill_name] then
        stats.skills_used[skill_name] = 0
    end
    stats.skills_used[skill_name] = stats.skills_used[skill_name] + 1
    
    writeYearReviewData(data)
end

-- 记录卡牌使用
local function recordCardUsed(player, card)
    local room = player:getRoom()
    local game_mode = room:getMode()
    
    local data = readYearReviewData()
    local year = os.date("%Y")
    local player_name = player:objectName()
    local stats = getPlayerYearStats(data, player_name, year, game_mode)
    
    local card_name = card:objectName()
    if not stats.cards_used[card_name] then
        stats.cards_used[card_name] = 0
    end
    stats.cards_used[card_name] = stats.cards_used[card_name] + 1
    
    writeYearReviewData(data)
end

-- 记录伤害数据
local function recordDamage(player, damage_value, is_source)
    local room = player:getRoom()
    local game_mode = room:getMode()
    
    local data = readYearReviewData()
    local year = os.date("%Y")
    local player_name = player:objectName()
    local stats = getPlayerYearStats(data, player_name, year, game_mode)
    
    if is_source then
        stats.damage_dealt = stats.damage_dealt + damage_value
    else
        stats.damage_taken = stats.damage_taken + damage_value
    end
    
    writeYearReviewData(data)
end

-- 记录击杀/死亡
local function recordKillOrDeath(player, is_kill)
    local room = player:getRoom()
    local game_mode = room:getMode()
    
    local data = readYearReviewData()
    local year = os.date("%Y")
    local player_name = player:objectName()
    local stats = getPlayerYearStats(data, player_name, year, game_mode)
    
    if is_kill then
        stats.kills = stats.kills + 1
    else
        stats.deaths = stats.deaths + 1
    end
    
    writeYearReviewData(data)
end

-- 记录摸牌/弃牌
local function recordCardMove(player, count, is_draw)
    local room = player:getRoom()
    local game_mode = room:getMode()
    
    local data = readYearReviewData()
    local year = os.date("%Y")
    local player_name = player:objectName()
    local stats = getPlayerYearStats(data, player_name, year, game_mode)
    
    if is_draw then
        stats.card_drawn = stats.card_drawn + count
    else
        stats.card_discarded = stats.card_discarded + count
    end
    
    writeYearReviewData(data)
end

-- 生成年度回顾报告
local function generateYearReview(player_name, year)
    local data = readYearReviewData()
    if not data.PlayerStats[player_name] or not data.PlayerStats[player_name][year] then
        return nil, "没有找到该玩家的年度数据"
    end
    
    local stats = data.PlayerStats[player_name][year]
    local report = {}
    
    -- 基本数据
    table.insert(report, "======== " .. year .. " 年度回顾 ========")
    table.insert(report, "玩家: " .. player_name)
    table.insert(report, "")
    
    -- 总体统计
    table.insert(report, "【总体数据】")
    table.insert(report, "总场次: " .. stats.total_games)
    table.insert(report, "总胜场: " .. stats.total_wins)
    if stats.total_games > 0 then
        local win_rate = string.format("%.2f", (stats.total_wins / stats.total_games) * 100)
        table.insert(report, "胜率: " .. win_rate .. "%")
    end
    table.insert(report, "")
    
    -- 最常使用的武将（Top 5）
    table.insert(report, "【最常使用的武将】")
    local general_list = {}
    for general_name, general_data in pairs(stats.generals) do
        table.insert(general_list, {
            name = general_name,
            play_count = general_data.play_count,
            win_count = general_data.win_count
        })
    end
    table.sort(general_list, function(a, b) return a.play_count > b.play_count end)
    for i = 1, math.min(5, #general_list) do
        local g = general_list[i]
        local win_rate = g.play_count > 0 and string.format("%.2f", (g.win_count / g.play_count) * 100) or "0"
        table.insert(report, string.format("%d. %s - 使用%d次, 胜%d场, 胜率%s%%", 
            i, g.name, g.play_count, g.win_count, win_rate))
    end
    table.insert(report, "")
    
    -- 身份统计
    table.insert(report, "【身份统计】")
    for role, role_data in pairs(stats.roles_stats) do
        if role_data.play > 0 then
            local win_rate = string.format("%.2f", (role_data.win / role_data.play) * 100)
            local role_name = ""
            if role == "lord" then role_name = "主公"
            elseif role == "loyalist" then role_name = "忠臣"
            elseif role == "rebel" then role_name = "反贼"
            elseif role == "renegade" then role_name = "内奸"
            end
            table.insert(report, string.format("%s: %d场, 胜%d场, 胜率%s%%", 
                role_name, role_data.play, role_data.win, win_rate))
        end
    end
    table.insert(report, "")
    
    -- 最常使用的技能（Top 10）
    table.insert(report, "【最常使用的技能】")
    local skill_list = {}
    for skill_name, count in pairs(stats.skills_used) do
        table.insert(skill_list, { name = skill_name, count = count })
    end
    table.sort(skill_list, function(a, b) return a.count > b.count end)
    for i = 1, math.min(10, #skill_list) do
        local s = skill_list[i]
        table.insert(report, string.format("%d. %s - 使用%d次", i, s.name, s.count))
    end
    table.insert(report, "")
    
    -- 最常使用的锦囊/装备（Top 10）
    table.insert(report, "【最常使用的卡牌】")
    local card_list = {}
    for card_name, count in pairs(stats.cards_used) do
        table.insert(card_list, { name = card_name, count = count })
    end
    table.sort(card_list, function(a, b) return a.count > b.count end)
    for i = 1, math.min(10, #card_list) do
        local c = card_list[i]
        table.insert(report, string.format("%d. %s - 使用%d次", i, c.name, c.count))
    end
    table.insert(report, "")
    
    -- 战斗数据
    table.insert(report, "【战斗数据】")
    table.insert(report, "造成伤害: " .. stats.damage_dealt)
    table.insert(report, "承受伤害: " .. stats.damage_taken)
    table.insert(report, "击杀数: " .. stats.kills)
    table.insert(report, "死亡数: " .. stats.deaths)
    table.insert(report, "")
    
    -- 卡牌数据
    table.insert(report, "【卡牌数据】")
    table.insert(report, "摸牌数: " .. stats.card_drawn)
    table.insert(report, "弃牌数: " .. stats.card_discarded)
    table.insert(report, "")
    
    table.insert(report, "==============================")
    
    return table.concat(report, "\n"), nil
end

-- 游戏开始记录器
YearReviewGameStartRecorder = sgs.CreateTriggerSkill{
    name = "year_review_game_start",
    events = { sgs.GameStart },
    global = true,
    priority = -10,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        recordGameStart(player)
        return false
    end
}

-- 游戏结束记录器
YearReviewGameOverRecorder = sgs.CreateTriggerSkill{
    name = "year_review_game_over",
    events = { sgs.GameOverJudge },
    global = true,
    priority = -10,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local winner = data:toWinner()
        if not winner then return false end
        
        for _, p in sgs.qlist(room:getAllPlayers(true)) do
            local is_winner = false
            if string.find(winner, p:getRole()) then
                is_winner = true
            end
            recordGameEnd(p, is_winner)
        end
        return false
    end
}

-- 技能使用记录器
YearReviewSkillRecorder = sgs.CreateTriggerSkill{
    name = "year_review_skill",
    events = { sgs.InvokeSkill },
    global = true,
    priority = -10,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        local skill_name = data:toString()
        if skill_name and skill_name ~= "" then
            recordSkillUsed(player, skill_name)
        end
        return false
    end
}

-- 卡牌使用记录器
YearReviewCardRecorder = sgs.CreateTriggerSkill{
    name = "year_review_card",
    events = { sgs.PreCardUsed, sgs.PreCardResponded },
    global = true,
    priority = -10,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        local card
        if event == sgs.PreCardUsed then
            card = data:toCardUse().card
        else
            if data:toCardResponse().m_isUse then
                card = data:toCardResponse().m_card
            end
        end
        
        if card and not card:isKindOf("SkillCard") then
            recordCardUsed(player, card)
        end
        return false
    end
}

-- 伤害记录器
YearReviewDamageRecorder = sgs.CreateTriggerSkill{
    name = "year_review_damage",
    events = { sgs.DamageCaused, sgs.DamageInflicted },
    global = true,
    priority = -10,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        local damage = data:toDamage()
        if event == sgs.DamageCaused then
            if damage.from then
                recordDamage(damage.from, damage.damage, true)
            end
        else
            recordDamage(player, damage.damage, false)
        end
        return false
    end
}

-- 击杀/死亡记录器
YearReviewKillRecorder = sgs.CreateTriggerSkill{
    name = "year_review_kill",
    events = { sgs.Death },
    global = true,
    priority = -10,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        local death = data:toDeath()
        if death.who then
            recordKillOrDeath(death.who, false)  -- 记录死亡
            if death.damage and death.damage.from then
                recordKillOrDeath(death.damage.from, true)  -- 记录击杀
            end
        end
        return false
    end
}

-- 摸牌/弃牌记录器
YearReviewCardMoveRecorder = sgs.CreateTriggerSkill{
    name = "year_review_card_move",
    events = { sgs.CardsMoveOneTime },
    global = true,
    priority = -10,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        local move = data:toMoveOneTime()
        
        -- 记录摸牌
        if move.to and move.to_place == sgs.Player_PlaceHand then
            local to_player = move.to
            if to_player then
                recordCardMove(to_player, move.card_ids:length(), true)
            end
        end
        
        -- 记录弃牌
        if move.from and move.from_places:contains(sgs.Player_PlaceHand) 
            and (move.to_place == sgs.Player_DiscardPile or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISCARD) then
            local from_player = move.from
            if from_player then
                recordCardMove(from_player, move.card_ids:length(), false)
            end
        end
        
        return false
    end
}

-- 年度回顾查询命令（可以在游戏中调用）
function ShowYearReview(player_name, year)
    year = year or os.date("%Y")
    local report, err = generateYearReview(player_name, year)
    if report then
        print(report)
        return report
    else
        print("错误: " .. (err or "未知错误"))
        return nil
    end
end

-- 导出年度回顾数据为HTML格式
function ExportYearReviewHTML(player_name, year, output_file)
    year = year or os.date("%Y")
    local data = readYearReviewData()
    
    if not data.PlayerStats[player_name] or not data.PlayerStats[player_name][year] then
        return false, "没有找到该玩家的年度数据"
    end
    
    local stats = data.PlayerStats[player_name][year]
    
    local html = [[
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>]] .. player_name .. " - " .. year .. [[ 年度回顾</title>
    <style>
        body { font-family: Arial, sans-serif; max-width: 800px; margin: 50px auto; padding: 20px; background-color: #f5f5f5; }
        .container { background-color: white; padding: 30px; border-radius: 10px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
        h1 { color: #333; text-align: center; border-bottom: 3px solid #4CAF50; padding-bottom: 10px; }
        h2 { color: #4CAF50; margin-top: 30px; }
        .stat-box { background-color: #f9f9f9; padding: 15px; margin: 10px 0; border-left: 4px solid #4CAF50; }
        .stat-item { margin: 5px 0; }
        .highlight { color: #4CAF50; font-weight: bold; }
        table { width: 100%; border-collapse: collapse; margin: 10px 0; }
        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
        th { background-color: #4CAF50; color: white; }
        tr:hover { background-color: #f5f5f5; }
    </style>
</head>
<body>
    <div class="container">
        <h1>]] .. player_name .. " - " .. year .. [[ 年度回顾</h1>
        
        <h2>总体数据</h2>
        <div class="stat-box">
            <div class="stat-item">总场次: <span class="highlight">]] .. stats.total_games .. [[</span></div>
            <div class="stat-item">总胜场: <span class="highlight">]] .. stats.total_wins .. [[</span></div>
]]
    
    if stats.total_games > 0 then
        local win_rate = string.format("%.2f", (stats.total_wins / stats.total_games) * 100)
        html = html .. [[            <div class="stat-item">胜率: <span class="highlight">]] .. win_rate .. [[%</span></div>
]]
    end
    
    html = html .. [[        </div>
        
        <h2>最常使用的武将</h2>
        <table>
            <tr><th>排名</th><th>武将</th><th>使用次数</th><th>胜场</th><th>胜率</th></tr>
]]
    
    -- 武将列表
    local general_list = {}
    for general_name, general_data in pairs(stats.generals) do
        table.insert(general_list, {
            name = general_name,
            play_count = general_data.play_count,
            win_count = general_data.win_count
        })
    end
    table.sort(general_list, function(a, b) return a.play_count > b.play_count end)
    for i = 1, math.min(10, #general_list) do
        local g = general_list[i]
        local win_rate = g.play_count > 0 and string.format("%.2f", (g.win_count / g.play_count) * 100) or "0"
        html = html .. string.format([[            <tr><td>%d</td><td>%s</td><td>%d</td><td>%d</td><td>%s%%</td></tr>
]], i, g.name, g.play_count, g.win_count, win_rate)
    end
    
    html = html .. [[        </table>
        
        <h2>战斗数据</h2>
        <div class="stat-box">
            <div class="stat-item">造成伤害: <span class="highlight">]] .. stats.damage_dealt .. [[</span></div>
            <div class="stat-item">承受伤害: <span class="highlight">]] .. stats.damage_taken .. [[</span></div>
            <div class="stat-item">击杀数: <span class="highlight">]] .. stats.kills .. [[</span></div>
            <div class="stat-item">死亡数: <span class="highlight">]] .. stats.deaths .. [[</span></div>
        </div>
        
        <h2>卡牌数据</h2>
        <div class="stat-box">
            <div class="stat-item">摸牌数: <span class="highlight">]] .. stats.card_drawn .. [[</span></div>
            <div class="stat-item">弃牌数: <span class="highlight">]] .. stats.card_discarded .. [[</span></div>
        </div>
    </div>
</body>
</html>
]]
    
    output_file = output_file or ("year_review_" .. player_name .. "_" .. year .. ".html")
    local file = io.open(output_file, "w")
    if file then
        file:write(html)
        file:close()
        return true, output_file
    else
        return false, "无法创建文件"
    end
end

-- 生成生涯回顾(聚合所有年份数据)
function GenerateCareerReview(player_name)
    local data = readYearReviewData()
    if not data.PlayerStats[player_name] then
        return "玩家 " .. player_name .. " 没有任何数据"
    end
    
    local player_all_years = data.PlayerStats[player_name]
    
    -- 初始化聚合数据
    local career_stats = {
        total_games = 0,
        total_wins = 0,
        generals = {},
        skills_used = {},
        cards_used = {},
        damage_dealt = 0,
        damage_taken = 0,
        kills = 0,
        deaths = 0,
        card_drawn = 0,
        card_discarded = 0,
        roles_stats = {
            ["lord"] = {games = 0, wins = 0},
            ["loyalist"] = {games = 0, wins = 0},
            ["rebel"] = {games = 0, wins = 0},
            ["renegade"] = {games = 0, wins = 0}
        }
    }
    
    local year_list = {}
    
    -- 聚合所有年份数据
    for year, year_stats in pairs(player_all_years) do
        table.insert(year_list, year)
        
        career_stats.total_games = career_stats.total_games + year_stats.total_games
        career_stats.total_wins = career_stats.total_wins + year_stats.total_wins
        career_stats.damage_dealt = career_stats.damage_dealt + year_stats.damage_dealt
        career_stats.damage_taken = career_stats.damage_taken + year_stats.damage_taken
        career_stats.kills = career_stats.kills + year_stats.kills
        career_stats.deaths = career_stats.deaths + year_stats.deaths
        career_stats.card_drawn = career_stats.card_drawn + year_stats.card_drawn
        career_stats.card_discarded = career_stats.card_discarded + year_stats.card_discarded
        
        -- 武将数据聚合
        for general_name, general_data in pairs(year_stats.generals) do
            if not career_stats.generals[general_name] then
                career_stats.generals[general_name] = {play_count = 0, win_count = 0}
            end
            career_stats.generals[general_name].play_count = career_stats.generals[general_name].play_count + general_data.play_count
            career_stats.generals[general_name].win_count = career_stats.generals[general_name].win_count + general_data.win_count
        end
        
        -- 技能使用聚合
        for skill_name, count in pairs(year_stats.skills_used) do
            career_stats.skills_used[skill_name] = (career_stats.skills_used[skill_name] or 0) + count
        end
        
        -- 卡牌使用聚合
        for card_name, count in pairs(year_stats.cards_used) do
            career_stats.cards_used[card_name] = (career_stats.cards_used[card_name] or 0) + count
        end
        
        -- 身份数据聚合
        for role, role_data in pairs(year_stats.roles_stats) do
            if career_stats.roles_stats[role] then
                career_stats.roles_stats[role].games = career_stats.roles_stats[role].games + role_data.games
                career_stats.roles_stats[role].wins = career_stats.roles_stats[role].wins + role_data.wins
            end
        end
    end
    
    table.sort(year_list)
    
    -- 生成报告
    local win_rate = career_stats.total_games > 0 
        and string.format("%.2f", (career_stats.total_wins / career_stats.total_games) * 100)
        or "0"
    
    local report = "\n================================================\n"
    report = report .. string.format("玩家 %s 的生涯回顾 (总共 %d 年)\n", player_name, #year_list)
    report = report .. "================================================\n\n"
    
    -- 跨越年份
    if #year_list > 0 then
        report = report .. string.format("数据跨越年份: %s - %s\n\n", year_list[1], year_list[#year_list])
    end
    
    -- 基本数据
    report = report .. string.format("总场次: %d\n", career_stats.total_games)
    report = report .. string.format("总胜场: %d\n", career_stats.total_wins)
    report = report .. string.format("总体胜率: %s%%\n\n", win_rate)
    
    -- 身份胜率
    report = report .. "【身份数据】\n"
    local role_names = {
        ["lord"] = "主公",
        ["loyalist"] = "忠臣",
        ["rebel"] = "反贼",
        ["renegade"] = "内奸"
    }
    for role, role_name in pairs(role_names) do
        local role_data = career_stats.roles_stats[role]
        if role_data.games > 0 then
            local role_wr = string.format("%.2f", (role_data.wins / role_data.games) * 100)
            report = report .. string.format("  %s: %d场 %d胜 (胜率 %s%%)\n", 
                role_name, role_data.games, role_data.wins, role_wr)
        end
    end
    report = report .. "\n"
    
    -- 最常用武将 Top 10
    report = report .. "【最常用武将 Top 10】\n"
    local general_list = {}
    for general_name, general_data in pairs(career_stats.generals) do
        table.insert(general_list, {
            name = general_name,
            play_count = general_data.play_count,
            win_count = general_data.win_count
        })
    end
    table.sort(general_list, function(a, b) return a.play_count > b.play_count end)
    for i = 1, math.min(10, #general_list) do
        local g = general_list[i]
        local g_win_rate = g.play_count > 0 
            and string.format("%.2f", (g.win_count / g.play_count) * 100)
            or "0"
        report = report .. string.format("  %d. %s - %d场 %d胜 (胜率 %s%%)\n", 
            i, g.name, g.play_count, g.win_count, g_win_rate)
    end
    report = report .. "\n"
    
    -- 最常用技能 Top 10
    report = report .. "【最常用技能 Top 10】\n"
    local skill_list = {}
    for skill_name, count in pairs(career_stats.skills_used) do
        table.insert(skill_list, {name = skill_name, count = count})
    end
    table.sort(skill_list, function(a, b) return a.count > b.count end)
    for i = 1, math.min(10, #skill_list) do
        report = report .. string.format("  %d. %s - %d次\n", i, skill_list[i].name, skill_list[i].count)
    end
    report = report .. "\n"
    
    -- 最常用卡牌 Top 10
    report = report .. "【最常用卡牌 Top 10】\n"
    local card_list = {}
    for card_name, count in pairs(career_stats.cards_used) do
        table.insert(card_list, {name = card_name, count = count})
    end
    table.sort(card_list, function(a, b) return a.count > b.count end)
    for i = 1, math.min(10, #card_list) do
        report = report .. string.format("  %d. %s - %d次\n", i, card_list[i].name, card_list[i].count)
    end
    report = report .. "\n"
    
    -- 战斗数据
    report = report .. "【战斗数据】\n"
    report = report .. string.format("  总造成伤害: %d\n", career_stats.damage_dealt)
    report = report .. string.format("  总承受伤害: %d\n", career_stats.damage_taken)
    report = report .. string.format("  总击杀数: %d\n", career_stats.kills)
    report = report .. string.format("  总死亡数: %d\n", career_stats.deaths)
    local kd_ratio = career_stats.deaths > 0 
        and string.format("%.2f", career_stats.kills / career_stats.deaths)
        or (career_stats.kills > 0 and "∞" or "0")
    report = report .. string.format("  K/D比: %s\n\n", kd_ratio)
    
    -- 卡牌数据
    report = report .. "【卡牌数据】\n"
    report = report .. string.format("  总摸牌数: %d\n", career_stats.card_drawn)
    report = report .. string.format("  总弃牌数: %d\n", career_stats.card_discarded)
    report = report .. "\n================================================\n"
    
    return report, career_stats
end

-- 导出生涯回顾HTML
function ExportCareerReviewHTML(player_name, output_file)
    local report, stats = GenerateCareerReview(player_name)
    if not stats then
        return false, report  -- report contains error message
    end
    
    local data = readYearReviewData()
    local player_all_years = data.PlayerStats[player_name]
    local year_list = {}
    for year, _ in pairs(player_all_years) do
        table.insert(year_list, year)
    end
    table.sort(year_list)
    
    local year_span = #year_list > 0 
        and string.format("%s - %s", year_list[1], year_list[#year_list])
        or "未知"
    
    local win_rate = stats.total_games > 0 
        and string.format("%.2f", (stats.total_wins / stats.total_games) * 100)
        or "0"
    
    local html = [[<!DOCTYPE html>
<html lang="zh-CN">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>]] .. player_name .. [[ - 生涯回顾</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: 'Microsoft YaHei', Arial, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            padding: 20px;
            min-height: 100vh;
        }
        .container {
            max-width: 1200px;
            margin: 0 auto;
            background: white;
            border-radius: 15px;
            box-shadow: 0 10px 40px rgba(0,0,0,0.2);
            padding: 40px;
        }
        h1 {
            text-align: center;
            color: #667eea;
            font-size: 2.5em;
            margin-bottom: 10px;
            text-shadow: 2px 2px 4px rgba(0,0,0,0.1);
        }
        .subtitle {
            text-align: center;
            color: #666;
            font-size: 1.2em;
            margin-bottom: 30px;
        }
        .stat-box {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 25px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 5px 15px rgba(102, 126, 234, 0.3);
        }
        .stat-item {
            font-size: 1.2em;
            margin: 10px 0;
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .highlight {
            font-weight: bold;
            font-size: 1.3em;
            color: #ffd700;
        }
        h2 {
            color: #667eea;
            border-bottom: 3px solid #667eea;
            padding-bottom: 10px;
            margin-top: 30px;
            margin-bottom: 20px;
        }
        table {
            width: 100%;
            border-collapse: collapse;
            margin: 20px 0;
            background: white;
            border-radius: 10px;
            overflow: hidden;
            box-shadow: 0 3px 10px rgba(0,0,0,0.1);
        }
        th {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 15px;
            text-align: left;
            font-weight: bold;
        }
        td {
            padding: 12px 15px;
            border-bottom: 1px solid #eee;
        }
        tr:hover {
            background: #f5f5f5;
        }
        .kd-ratio {
            font-size: 1.5em;
            color: #667eea;
            font-weight: bold;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🏆 ]] .. player_name .. [[ 的生涯回顾 🏆</h1>
        <div class="subtitle">数据跨越: ]] .. year_span .. [[ (总共 ]] .. #year_list .. [[ 年)</div>
        
        <div class="stat-box">
            <div class="stat-item">总场次: <span class="highlight">]] .. stats.total_games .. [[</span></div>
            <div class="stat-item">总胜场: <span class="highlight">]] .. stats.total_wins .. [[</span></div>
            <div class="stat-item">总体胜率: <span class="highlight">]] .. win_rate .. [[%</span></div>
        </div>
        
        <h2>身份数据</h2>
        <table>
            <tr><th>身份</th><th>场次</th><th>胜场</th><th>胜率</th></tr>
]]
    
    local role_names = {
        ["lord"] = "主公",
        ["loyalist"] = "忠臣",
        ["rebel"] = "反贼",
        ["renegade"] = "内奸"
    }
    for _, role in ipairs({"lord", "loyalist", "rebel", "renegade"}) do
        local role_data = stats.roles_stats[role]
        if role_data.games > 0 then
            local role_wr = string.format("%.2f", (role_data.wins / role_data.games) * 100)
            html = html .. string.format([[            <tr><td>%s</td><td>%d</td><td>%d</td><td>%s%%</td></tr>
]], role_names[role], role_data.games, role_data.wins, role_wr)
        end
    end
    
    html = html .. [[        </table>
        
        <h2>最常用武将 Top 10</h2>
        <table>
            <tr><th>排名</th><th>武将</th><th>使用次数</th><th>胜场</th><th>胜率</th></tr>
]]
    
    local general_list = {}
    for general_name, general_data in pairs(stats.generals) do
        table.insert(general_list, {
            name = general_name,
            play_count = general_data.play_count,
            win_count = general_data.win_count
        })
    end
    table.sort(general_list, function(a, b) return a.play_count > b.play_count end)
    for i = 1, math.min(10, #general_list) do
        local g = general_list[i]
        local g_win_rate = g.play_count > 0 and string.format("%.2f", (g.win_count / g.play_count) * 100) or "0"
        html = html .. string.format([[            <tr><td>%d</td><td>%s</td><td>%d</td><td>%d</td><td>%s%%</td></tr>
]], i, g.name, g.play_count, g.win_count, g_win_rate)
    end
    
    html = html .. [[        </table>
        
        <h2>战斗数据</h2>
        <div class="stat-box">
            <div class="stat-item">总造成伤害: <span class="highlight">]] .. stats.damage_dealt .. [[</span></div>
            <div class="stat-item">总承受伤害: <span class="highlight">]] .. stats.damage_taken .. [[</span></div>
            <div class="stat-item">总击杀数: <span class="highlight">]] .. stats.kills .. [[</span></div>
            <div class="stat-item">总死亡数: <span class="highlight">]] .. stats.deaths .. [[</span></div>
]]
    
    local kd_ratio = stats.deaths > 0 
        and string.format("%.2f", stats.kills / stats.deaths)
        or (stats.kills > 0 and "∞" or "0")
    
    html = html .. [[            <div class="stat-item">K/D比: <span class="kd-ratio">]] .. kd_ratio .. [[</span></div>
        </div>
        
        <h2>卡牌数据</h2>
        <div class="stat-box">
            <div class="stat-item">总摸牌数: <span class="highlight">]] .. stats.card_drawn .. [[</span></div>
            <div class="stat-item">总弃牌数: <span class="highlight">]] .. stats.card_discarded .. [[</span></div>
        </div>
    </div>
</body>
</html>
]]
    
    output_file = output_file or ("career_review_" .. player_name .. ".html")
    local file = io.open(output_file, "w")
    if file then
        file:write(html)
        file:close()
        return true, output_file
    else
        return false, "无法创建文件"
    end
end

-- 注册技能
if not sgs.Sanguosha:getSkill("year_review_game_start") then 
    local skills = sgs.SkillList()
    skills:append(YearReviewGameStartRecorder)
    skills:append(YearReviewGameOverRecorder)
    skills:append(YearReviewSkillRecorder)
    skills:append(YearReviewCardRecorder)
    skills:append(YearReviewDamageRecorder)
    skills:append(YearReviewKillRecorder)
    skills:append(YearReviewCardMoveRecorder)
    sgs.Sanguosha:addSkills(skills)
end

sgs.LoadTranslationTable {
    ["year_review"] = "年度回顾",
    ["year_review_game_start"] = "年度回顾-游戏开始",
    ["year_review_game_over"] = "年度回顾-游戏结束",
    ["year_review_skill"] = "年度回顾-技能使用",
    ["year_review_card"] = "年度回顾-卡牌使用",
    ["year_review_damage"] = "年度回顾-伤害统计",
    ["year_review_kill"] = "年度回顾-击杀统计",
    ["year_review_card_move"] = "年度回顾-卡牌移动",
}

return year_review_extension
