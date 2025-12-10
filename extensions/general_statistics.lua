-- 武将统计系统
-- General Statistics System
-- 独立于玩家的武将数据统计和分析

general_stats_extension = sgs.Package("general_statistics")

-- 配置文件路径
local general_data_file = "general_statistics.json"
local config_file = "general_stats_config.json"

-- 默认配置
local default_config = {
    -- 特色判定阈值（相对于平均值的倍数）
    style_thresholds = {
        control = {
            control_card_ratio = 1.3,      -- 控制牌占比 > 平均值的1.3倍
            lebuduan_count = 1.5,          -- 乐不思蜀使用次数 > 平均值的1.5倍
            bingliang_count = 1.5,         -- 兵粮寸断
            snatch_count = 1.3,            -- 顺手牵羊
            dismantlement_count = 1.3,     -- 过河拆桥
        },
        damage_dealer = {
            slash_damage_ratio = 1.4,      -- 杀造成的伤害占比 > 平均值的1.4倍
            slash_count = 1.3,             -- 杀使用次数
            avg_damage_per_game = 1.3,     -- 场均伤害
        },
        tank = {
            damage_taken_ratio = 1.3,      -- 受伤占比高
            survival_rounds = 1.2,         -- 存活回合数长
            recover_count = 1.2,           -- 回血次数多
        },
        support = {
            heal_others_count = 1.5,       -- 给他人回血
            card_given_count = 1.3,        -- 给牌次数
        },
        burst = {
            max_damage_per_round = 1.5,    -- 单回合最高伤害
        },
        card_draw = {
            draw_count_ratio = 1.3,        -- 摸牌数远高于平均
        },
        aoe = {
            aoe_damage_ratio = 1.5,        -- AOE伤害占比
            aoe_card_count = 1.5,          -- AOE卡牌使用次数
        },
        fast_game = {
            avg_game_rounds = 0.8,         -- 平均回合数 < 80%平均值
        },
        slow_game = {
            avg_game_rounds = 1.2,         -- 平均回合数 > 120%平均值
        },
        growth = {
            late_damage_ratio = 1.3,       -- 后期伤害占比高（后半段回合伤害/前半段）
        },
    },
    -- 身份推荐阈值
    role_recommendation = {
        strong_threshold = 0.55,    -- 胜率 > 55% 推荐
        weak_threshold = 0.45,      -- 胜率 < 45% 不推荐
        min_games = 10,             -- 最少场次要求
    },
}

-- 读取配置
local function loadConfig()
    local json = require "json"
    local file = io.open(config_file, "r")
    if file then
        local content = file:read("*all")
        file:close()
        local config = json.decode(content)
        if config then return config end
    end
    -- 保存默认配置
    file = io.open(config_file, "w")
    if file then
        file:write(json.encode(default_config, { indent = true }))
        file:close()
    end
    return default_config
end

-- 读取武将统计数据
local function loadGeneralData()
    local json = require "json"
    local file = io.open(general_data_file, "r")
    local data = {
        Generals = {},           -- 武将数据
        GlobalAverages = {},     -- 全局平均值
        FactionAverages = {},    -- 势力平均值
        LastUpdate = os.date("%Y-%m-%d %H:%M:%S")
    }
    if file then
        local content = file:read("*all")
        file:close()
        data = json.decode(content) or data
    end
    return data
end

-- 保存武将统计数据
local function saveGeneralData(data)
    local json = require "json"
    data.LastUpdate = os.date("%Y-%m-%d %H:%M:%S")
    local file = assert(io.open(general_data_file, "w"))
    local content = json.encode(data, { indent = true })
    file:write(content)
    file:close()
end

-- 初始化武将数据结构
local function initGeneralStats(general_name)
    return {
        general_name = general_name,
        total_games = 0,
        total_wins = 0,
        
        -- 回合数统计
        total_game_rounds = 0,        -- 游戏总回合数累计
        total_survival_rounds = 0,    -- 武将存活回合数累计
        total_action_rounds = 0,      -- 实际行动回合数累计
        
        -- 身份统计
        roles = {
            lord = { games = 0, wins = 0 },
            loyalist = { games = 0, wins = 0 },
            rebel = { games = 0, wins = 0 },
            renegade = { games = 0, wins = 0 },
        },
        
        -- MVP统计
        mvp_count = 0,
        
        -- 卡牌使用统计
        cards_used = {},              -- { card_name = { count, damage, win_count } }
        
        -- 技能使用统计
        skills_used = {},             -- { skill_name = count }
        
        -- 伤害统计（细分）
        damage_stats = {
            total_dealt = 0,          -- 总造成伤害
            total_taken = 0,          -- 总承受伤害
            slash_damage = 0,         -- 杀造成的伤害
            duel_damage = 0,          -- 决斗伤害
            aoe_damage = 0,           -- AOE伤害（南蛮、万箭等）
            skill_damage = 0,         -- 技能伤害
            equipment_damage = 0,     -- 装备伤害
        },
        
        -- 击杀统计
        kills = 0,
        deaths = 0,
        
        -- 卡牌流转
        cards_drawn = 0,
        cards_discarded = 0,
        
        -- 回血统计
        hp_recovered = 0,
        hp_recovered_others = 0,      -- 给他人回血
        
        -- 受伤后收益
        damage_taken_benefits = {
            cards_drawn = 0,          -- 受伤后摸牌
            damage_dealt = 0,         -- 受伤后造成伤害
        },
        
        -- 单局最高记录
        max_damage_per_game = 0,
        max_damage_per_round = 0,
        
        -- 阶段性伤害（用于判断发育型）
        early_damage = 0,             -- 前1/3回合伤害
        mid_damage = 0,               -- 中1/3回合伤害
        late_damage = 0,              -- 后1/3回合伤害
        
        -- 控制类卡牌统计
        control_cards = {
            lebuduan = 0,             -- 乐不思蜀
            bingliang = 0,            -- 兵粮寸断
            snatch = 0,               -- 顺手牵羊
            dismantlement = 0,        -- 过河拆桥
            lightning = 0,            -- 闪电
        },
        
        -- AOE卡牌统计
        aoe_cards = {
            savage_assault = 0,       -- 南蛮入侵
            archery_attack = 0,       -- 万箭齐发
            god_salvation = 0,        -- 桃园结义
            amazing_grace = 0,        -- 五谷丰登
        },
        
        -- 对阵统计（克制关系）
        versus = {},                  -- { enemy_general = { games, wins } }
        
        -- 队友统计（配合效果）
        teammates = {},               -- { teammate_general = { games, wins } }
    }
end

-- 获取或创建武将统计
local function getGeneralStats(data, general_name)
    if not data.Generals[general_name] then
        data.Generals[general_name] = initGeneralStats(general_name)
    end
    return data.Generals[general_name]
end

-- 游戏开始时记录
local function recordGameStart(player, game_data)
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name)
    
    stats.total_games = stats.total_games + 1
    
    -- 记录身份
    local role = player:getRole()
    if stats.roles[role] then
        stats.roles[role].games = stats.roles[role].games + 1
    end
    
    -- 记录对手和队友
    local room = player:getRoom()
    for _, p in sgs.qlist(room:getAllPlayers()) do
        if p:objectName() ~= player:objectName() then
            local enemy_general = p:getGeneralName()
            local is_teammate = false
            
            -- 判断是否为队友
            if role == "lord" or role == "loyalist" then
                is_teammate = (p:getRole() == "lord" or p:getRole() == "loyalist")
            elseif role == "rebel" then
                is_teammate = (p:getRole() == "rebel")
            end
            
            if is_teammate then
                if not stats.teammates[enemy_general] then
                    stats.teammates[enemy_general] = { games = 0, wins = 0 }
                end
                stats.teammates[enemy_general].games = stats.teammates[enemy_general].games + 1
            else
                if not stats.versus[enemy_general] then
                    stats.versus[enemy_general] = { games = 0, wins = 0 }
                end
                stats.versus[enemy_general].games = stats.versus[enemy_general].games + 1
            end
        end
    end
    
    -- 初始化本局数据
    game_data.game_start_time = os.time()
    game_data.current_round = 0
    game_data.survival_rounds = 0
    game_data.action_rounds = 0
    game_data.current_game_damage = 0
    game_data.is_alive = true
    game_data.death_round = nil
    game_data.last_hp = player:getHp()
    
    saveGeneralData(data)
end

-- 游戏结束时记录
local function recordGameEnd(player, is_winner, is_mvp, total_rounds)
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name)
    
    if is_winner then
        stats.total_wins = stats.total_wins + 1
        
        -- 更新身份胜率
        local role = player:getRole()
        if stats.roles[role] then
            stats.roles[role].wins = stats.roles[role].wins + 1
        end
        
        -- 更新对手胜率
        local room = player:getRoom()
        for _, p in sgs.qlist(room:getAllPlayers()) do
            if p:objectName() ~= player:objectName() then
                local enemy_general = p:getGeneralName()
                local is_teammate = false
                
                if role == "lord" or role == "loyalist" then
                    is_teammate = (p:getRole() == "lord" or p:getRole() == "loyalist")
                elseif role == "rebel" then
                    is_teammate = (p:getRole() == "rebel")
                end
                
                if is_teammate then
                    if stats.teammates[enemy_general] then
                        stats.teammates[enemy_general].wins = stats.teammates[enemy_general].wins + 1
                    end
                else
                    if stats.versus[enemy_general] then
                        stats.versus[enemy_general].wins = stats.versus[enemy_general].wins + 1
                    end
                end
            end
        end
    end
    
    if is_mvp then
        stats.mvp_count = stats.mvp_count + 1
    end
    
    -- 记录回合数
    stats.total_game_rounds = stats.total_game_rounds + total_rounds
    
    local game_data = player:getTag("GeneralStatsGameData"):toTable()
    if game_data then
        stats.total_survival_rounds = stats.total_survival_rounds + game_data.survival_rounds
        stats.total_action_rounds = stats.total_action_rounds + game_data.action_rounds
    end
    
    saveGeneralData(data)
end

-- 记录卡牌使用
local function recordCardUsed(player, card, caused_damage)
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name)
    
    local card_name = card:objectName()
    if not stats.cards_used[card_name] then
        stats.cards_used[card_name] = { count = 0, damage = 0, win_count = 0 }
    end
    
    stats.cards_used[card_name].count = stats.cards_used[card_name].count + 1
    
    if caused_damage then
        stats.cards_used[card_name].damage = stats.cards_used[card_name].damage + caused_damage
    end
    
    -- 更新控制卡牌统计
    if card_name == "indulgence" then
        stats.control_cards.lebuduan = stats.control_cards.lebuduan + 1
    elseif card_name == "supply_shortage" then
        stats.control_cards.bingliang = stats.control_cards.bingliang + 1
    elseif card_name == "snatch" then
        stats.control_cards.snatch = stats.control_cards.snatch + 1
    elseif card_name == "dismantlement" then
        stats.control_cards.dismantlement = stats.control_cards.dismantlement + 1
    elseif card_name == "lightning" then
        stats.control_cards.lightning = stats.control_cards.lightning + 1
    end
    
    -- 更新AOE卡牌统计
    if card_name == "savage_assault" then
        stats.aoe_cards.savage_assault = stats.aoe_cards.savage_assault + 1
    elseif card_name == "archery_attack" then
        stats.aoe_cards.archery_attack = stats.aoe_cards.archery_attack + 1
    elseif card_name == "god_salvation" then
        stats.aoe_cards.god_salvation = stats.aoe_cards.god_salvation + 1
    elseif card_name == "amazing_grace" then
        stats.aoe_cards.amazing_grace = stats.aoe_cards.amazing_grace + 1
    end
    
    saveGeneralData(data)
end

-- 记录技能使用
local function recordSkillUsed(player, skill_name)
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name)
    
    if not stats.skills_used[skill_name] then
        stats.skills_used[skill_name] = 0
    end
    stats.skills_used[skill_name] = stats.skills_used[skill_name] + 1
    
    saveGeneralData(data)
end

-- 记录伤害
local function recordDamage(player, damage_data, is_source)
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name)
    
    local damage_value = damage_data.damage
    local card = damage_data.card
    local nature = damage_data.nature
    
    if is_source then
        stats.damage_stats.total_dealt = stats.damage_stats.total_dealt + damage_value
        
        -- 分类统计伤害
        if card then
            if card:isKindOf("Slash") then
                stats.damage_stats.slash_damage = stats.damage_stats.slash_damage + damage_value
            elseif card:objectName() == "duel" then
                stats.damage_stats.duel_damage = stats.damage_stats.duel_damage + damage_value
            elseif card:objectName() == "savage_assault" or card:objectName() == "archery_attack" then
                stats.damage_stats.aoe_damage = stats.damage_stats.aoe_damage + damage_value
            end
        else
            -- 技能或装备伤害
            if damage_data.reason and damage_data.reason:find("skill") then
                stats.damage_stats.skill_damage = stats.damage_stats.skill_damage + damage_value
            else
                stats.damage_stats.equipment_damage = stats.damage_stats.equipment_damage + damage_value
            end
        end
        
        -- 更新单局最高伤害
        local game_data = player:getTag("GeneralStatsGameData"):toTable() or {}
        game_data.current_game_damage = (game_data.current_game_damage or 0) + damage_value
        if game_data.current_game_damage > stats.max_damage_per_game then
            stats.max_damage_per_game = game_data.current_game_damage
        end
        player:setTag("GeneralStatsGameData", sgs.QVariant(game_data))
        
        -- 阶段性伤害统计
        local room = player:getRoom()
        local current_round = room:getTag("RoundCount"):toInt() or 0
        local game_data = player:getTag("GeneralStatsGameData"):toTable() or {}
        local total_rounds = game_data.estimated_total_rounds or 30  -- 估计总回合数
        
        if current_round <= total_rounds / 3 then
            stats.early_damage = stats.early_damage + damage_value
        elseif current_round <= total_rounds * 2 / 3 then
            stats.mid_damage = stats.mid_damage + damage_value
        else
            stats.late_damage = stats.late_damage + damage_value
        end
    else
        stats.damage_stats.total_taken = stats.damage_stats.total_taken + damage_value
        
        -- 记录受伤前的状态
        local game_data = player:getTag("GeneralStatsGameData"):toTable() or {}
        game_data.damage_taken_time = os.time()
        game_data.hp_before_damage = player:getHp()
        player:setTag("GeneralStatsGameData", sgs.QVariant(game_data))
    end
    
    saveGeneralData(data)
end

-- 记录受伤后收益
local function recordDamageBenefit(player, benefit_type, value)
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name)
    
    local game_data = player:getTag("GeneralStatsGameData"):toTable() or {}
    local damage_taken_time = game_data.damage_taken_time or 0
    
    -- 只记录受伤后3秒内的收益
    if os.time() - damage_taken_time <= 3 then
        if benefit_type == "draw" then
            stats.damage_taken_benefits.cards_drawn = stats.damage_taken_benefits.cards_drawn + value
        elseif benefit_type == "damage" then
            stats.damage_taken_benefits.damage_dealt = stats.damage_taken_benefits.damage_dealt + value
        end
    end
    
    saveGeneralData(data)
end

-- 游戏开始记录器
GeneralStatsGameStartRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_game_start",
    events = { sgs.GameStart },
    global = true,
    priority = -20,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        local game_data = {}
        recordGameStart(player, game_data)
        player:setTag("GeneralStatsGameData", sgs.QVariant(game_data))
        return false
    end
}

-- 回合记录器
GeneralStatsRoundRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_round",
    events = { sgs.EventPhaseStart, sgs.TurnStart },
    global = true,
    priority = -20,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        
        if event == sgs.TurnStart then
            -- 记录总回合数
            local round_count = room:getTag("RoundCount"):toInt() or 0
            room:setTag("RoundCount", sgs.QVariant(round_count + 1))
        end
        
        if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Start then
            local game_data = player:getTag("GeneralStatsGameData"):toTable() or {}
            
            -- 检查是否被跳过回合
            local is_skipped = player:isSkipped(sgs.Player_Play) or 
                             player:hasFlag("Global_ForbidPhase")
            
            if game_data.is_alive then
                game_data.survival_rounds = (game_data.survival_rounds or 0) + 1
                
                if not is_skipped then
                    game_data.action_rounds = (game_data.action_rounds or 0) + 1
                end
            end
            
            player:setTag("GeneralStatsGameData", sgs.QVariant(game_data))
        end
        
        return false
    end
}

-- 游戏结束记录器
GeneralStatsGameOverRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_game_over",
    events = { sgs.GameOverJudge },
    global = true,
    priority = -25,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local winner = data:toWinner()
        if not winner then return false end
        
        local total_rounds = room:getTag("RoundCount"):toInt() or 0
        
        -- 判断MVP
        local mvp_player = nil
        local max_mvp_exp = 0
        for _, p in sgs.qlist(room:getAllPlayers(true)) do
            local mvp_exp = p:getMark("mvpexp") or 0
            if mvp_exp > max_mvp_exp then
                max_mvp_exp = mvp_exp
                mvp_player = p
            end
        end
        
        -- 记录所有玩家数据
        for _, p in sgs.qlist(room:getAllPlayers(true)) do
            local is_winner = string.find(winner, p:getRole()) ~= nil
            local is_mvp = (mvp_player and mvp_player:objectName() == p:objectName())
            recordGameEnd(p, is_winner, is_mvp, total_rounds)
            
            -- 如果获胜，更新关键牌胜率
            if is_winner then
                local data = loadGeneralData()
                local general_name = p:getGeneralName()
                local stats = getGeneralStats(data, general_name)
                
                -- 更新本局使用过的卡牌的胜率
                for card_name, card_data in pairs(stats.cards_used) do
                    -- 这里需要判断本局是否使用过该卡牌
                    -- 简化处理：假设使用过
                    card_data.win_count = card_data.win_count + 1
                end
                
                saveGeneralData(data)
            end
        end
        
        return false
    end
}

-- 技能使用记录器
GeneralStatsSkillRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_skill",
    events = { sgs.InvokeSkill },
    global = true,
    priority = -20,
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
GeneralStatsCardRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_card",
    events = { sgs.PreCardUsed, sgs.PreCardResponded },
    global = true,
    priority = -20,
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
            recordCardUsed(player, card, nil)
        end
        
        return false
    end
}

-- 伤害记录器
GeneralStatsDamageRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_damage",
    events = { sgs.DamageCaused, sgs.DamageInflicted, sgs.Damage },
    global = true,
    priority = -20,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        local damage = data:toDamage()
        
        if event == sgs.DamageCaused then
            if damage.from then
                recordDamage(damage.from, damage, true)
            end
        elseif event == sgs.DamageInflicted then
            recordDamage(player, damage, false)
        elseif event == sgs.Damage then
            -- 记录卡牌造成的实际伤害
            if damage.from and damage.card then
                local data_obj = loadGeneralData()
                local general_name = damage.from:getGeneralName()
                local stats = getGeneralStats(data_obj, general_name)
                local card_name = damage.card:objectName()
                
                if stats.cards_used[card_name] then
                    stats.cards_used[card_name].damage = stats.cards_used[card_name].damage + damage.damage
                end
                
                saveGeneralData(data_obj)
            end
        end
        
        return false
    end
}

-- 死亡记录器
GeneralStatsDeathRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_death",
    events = { sgs.Death },
    global = true,
    priority = -20,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        local death = data:toDeath()
        if death.who then
            local data_obj = loadGeneralData()
            local general_name = death.who:getGeneralName()
            local stats = getGeneralStats(data_obj, general_name)
            
            stats.deaths = stats.deaths + 1
            
            -- 标记死亡
            local game_data = death.who:getTag("GeneralStatsGameData"):toTable() or {}
            game_data.is_alive = false
            local room = death.who:getRoom()
            game_data.death_round = room:getTag("RoundCount"):toInt() or 0
            death.who:setTag("GeneralStatsGameData", sgs.QVariant(game_data))
            
            -- 记录击杀者
            if death.damage and death.damage.from then
                local killer_general = death.damage.from:getGeneralName()
                local killer_data = loadGeneralData()
                local killer_stats = getGeneralStats(killer_data, killer_general)
                killer_stats.kills = killer_stats.kills + 1
                saveGeneralData(killer_data)
            end
            
            saveGeneralData(data_obj)
        end
        
        return false
    end
}

-- 摸牌/弃牌记录器
GeneralStatsCardMoveRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_card_move",
    events = { sgs.CardsMoveOneTime },
    global = true,
    priority = -20,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        local move = data:toMoveOneTime()
        
        -- 记录摸牌
        if move.to and move.to_place == sgs.Player_PlaceHand then
            local to_player = move.to
            if to_player then
                local data_obj = loadGeneralData()
                local general_name = to_player:getGeneralName()
                local stats = getGeneralStats(data_obj, general_name)
                stats.cards_drawn = stats.cards_drawn + move.card_ids:length()
                
                -- 检查是否为受伤后收益
                recordDamageBenefit(to_player, "draw", move.card_ids:length())
                
                saveGeneralData(data_obj)
            end
        end
        
        -- 记录弃牌
        if move.from and move.from_places:contains(sgs.Player_PlaceHand) 
            and (move.to_place == sgs.Player_DiscardPile or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISCARD) then
            local from_player = move.from
            if from_player then
                local data_obj = loadGeneralData()
                local general_name = from_player:getGeneralName()
                local stats = getGeneralStats(data_obj, general_name)
                stats.cards_discarded = stats.cards_discarded + move.card_ids:length()
                saveGeneralData(data_obj)
            end
        end
        
        return false
    end
}

-- 回血记录器
GeneralStatsRecoverRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_recover",
    events = { sgs.HpRecover },
    global = true,
    priority = -20,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        local recover = data:toRecover()
        local data_obj = loadGeneralData()
        local general_name = player:getGeneralName()
        local stats = getGeneralStats(data_obj, general_name)
        
        stats.hp_recovered = stats.hp_recovered + recover.recover
        
        -- 如果是给他人回血
        if recover.who and recover.who:objectName() ~= player:objectName() then
            local healer_general = recover.who:getGeneralName()
            local healer_data = loadGeneralData()
            local healer_stats = getGeneralStats(healer_data, healer_general)
            healer_stats.hp_recovered_others = healer_stats.hp_recovered_others + recover.recover
            saveGeneralData(healer_data)
        end
        
        saveGeneralData(data_obj)
        return false
    end
}

-- 注册所有技能
if not sgs.Sanguosha:getSkill("general_stats_game_start") then 
    local skills = sgs.SkillList()
    skills:append(GeneralStatsGameStartRecorder)
    skills:append(GeneralStatsRoundRecorder)
    skills:append(GeneralStatsGameOverRecorder)
    skills:append(GeneralStatsSkillRecorder)
    skills:append(GeneralStatsCardRecorder)
    skills:append(GeneralStatsDamageRecorder)
    skills:append(GeneralStatsDeathRecorder)
    skills:append(GeneralStatsCardMoveRecorder)
    skills:append(GeneralStatsRecoverRecorder)
    sgs.Sanguosha:addSkills(skills)
end

sgs.LoadTranslationTable {
    ["general_statistics"] = "武将统计",
}

return general_stats_extension
