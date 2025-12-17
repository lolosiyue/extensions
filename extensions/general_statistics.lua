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
        GameModes = {},          -- 按游戏模式分类的数据 { mode_name = { Generals = {}, GlobalAverages = {}, FactionAverages = {} } }
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
            ndtrick_damage = 0,       -- NDTrick伤害
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
        
        -- 收益统计系统（通用）
        benefits = {
            -- 受伤收益
            on_damaged = {
                cards_drawn = 0,           -- 受伤后摸牌
                damage_dealt = 0,          -- 受伤后造成伤害
                hp_recovered = 0,          -- 受伤后回血
                trigger_count = 0,         -- 受伤触发次数
            },
            -- 击杀收益
            on_kill = {
                cards_drawn = 0,           -- 击杀后摸牌
                hp_recovered = 0,          -- 击杀后回血
                extra_turns = 0,           -- 击杀后额外回合
                trigger_count = 0,         -- 击杀触发次数
            },
            -- 死亡收益（遗计类）
            on_death = {
                cards_given = 0,           -- 死亡时给牌
                damage_dealt = 0,          -- 死亡时造成伤害
                effects_applied = 0,       -- 死亡时触发效果次数
                trigger_count = 0,         -- 死亡触发次数
            },
            -- 出牌收益
            on_card_used = {
                cards_drawn = 0,           -- 用牌后摸牌
                damage_bonus = 0,          -- 用牌伤害加成
                trigger_count = 0,         -- 用牌触发次数
            },
            -- 弃牌收益
            on_discard = {
                cards_drawn = 0,           -- 弃牌后摸牌
                damage_dealt = 0,          -- 弃牌后造成伤害
                trigger_count = 0,         -- 弃牌触发次数
            },
            -- 回合外收益
            off_turn = {
                cards_drawn = 0,           -- 回合外摸牌
                damage_dealt = 0,          -- 回合外造成伤害
                trigger_count = 0,         -- 回合外触发次数
            },
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
        
        -- 副将统计（双将模式）
        secondary_generals = {},      -- { secondary_general_name = { games, wins, is_secondary = true } }
        best_secondary_combos = {},   -- 最高胜率副将组合列表（自动排序）
    }
end

-- 获取或创建武将统计
local function getGeneralStats(data, general_name, game_mode)
    game_mode = game_mode or "standard"
    
    if not data.GameModes[game_mode] then
        data.GameModes[game_mode] = {
            Generals = {},
            GlobalAverages = {},
            FactionAverages = {}
        }
    end
    
    if not data.GameModes[game_mode].Generals[general_name] then
        data.GameModes[game_mode].Generals[general_name] = initGeneralStats(general_name)
    end
    
    return data.GameModes[game_mode].Generals[general_name]
end

-- 获取游戏模式名称（标准化）
local function getGameModeName(mode_string)
    -- 标准身份局
    if string.find(mode_string, "02p") then return "2p_standard"
    elseif string.find(mode_string, "03p") then return "3p_standard"
    elseif string.find(mode_string, "04p") then return "4p_standard"
    elseif string.find(mode_string, "05p") then return "5p_standard"
    elseif string.find(mode_string, "06p") then return "6p_standard"
    elseif string.find(mode_string, "08p") then return "8p_standard"
    -- 特殊模式
    elseif mode_string == "06_3v3" then return "3v3"
    elseif mode_string == "06_XMode" then return "1v3"
    elseif mode_string == "04_boss" then return "boss"
    elseif mode_string == "08_defense" then return "defense"
    elseif mode_string == "02_mini_scene" then return "mini_scene"
    else
        -- 其他模式使用原始名称
        return mode_string
    end
end

-- 游戏开始时记录
local function recordGameStart(player, game_data)
    local room = player:getRoom()
    local game_mode = getGameModeName(room:getMode())
    
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name, game_mode)
    
    stats.total_games = stats.total_games + 1
    
    -- 记录副将（如果存在）
    local general2_name = player:getGeneral2Name()
    if general2_name and general2_name ~= "" then
        if not stats.secondary_generals[general2_name] then
            stats.secondary_generals[general2_name] = { games = 0, wins = 0, is_secondary = true }
        end
        stats.secondary_generals[general2_name].games = stats.secondary_generals[general2_name].games + 1
        
        -- 同时记录副将作为主将的数据
        local stats2 = getGeneralStats(data, general2_name, game_mode)
        stats2.total_games = stats2.total_games + 1
        if not stats2.secondary_generals[general_name] then
            stats2.secondary_generals[general_name] = { games = 0, wins = 0, is_secondary = false }
        end
        stats2.secondary_generals[general_name].games = stats2.secondary_generals[general_name].games + 1
    end
    
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
    local room = player:getRoom()
    local game_mode = getGameModeName(room:getMode())
    
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name, game_mode)
    
    if is_winner then
        stats.total_wins = stats.total_wins + 1
        
        -- 更新副将胜率（如果存在）
        local general2_name = player:getGeneral2Name()
        if general2_name and general2_name ~= "" then
            if stats.secondary_generals[general2_name] then
                stats.secondary_generals[general2_name].wins = stats.secondary_generals[general2_name].wins + 1
            end
            
            -- 同时更新副将作为主将的数据
            local stats2 = getGeneralStats(data, general2_name, game_mode)
            stats2.total_wins = stats2.total_wins + 1
            if stats2.secondary_generals[general_name] then
                stats2.secondary_generals[general_name].wins = stats2.secondary_generals[general_name].wins + 1
            end
            
            -- 更新副将的身份胜率
            local role = player:getRole()
            if stats2.roles[role] then
                stats2.roles[role].wins = stats2.roles[role].wins + 1
            end
        end
        
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
    
    -- 更新最佳副将组合
    updateBestSecondaryCombos(data, general_name, game_mode)
    local general2_name = player:getGeneral2Name()
    if general2_name and general2_name ~= "" then
        updateBestSecondaryCombos(data, general2_name, game_mode)
    end
    
    saveGeneralData(data)
end

-- 更新最佳副将组合列表
local function updateBestSecondaryCombos(data, general_name, game_mode)
    local stats = getGeneralStats(data, general_name, game_mode)
    
    -- 清空旧列表
    stats.best_secondary_combos = {}
    
    -- 计算所有副将组合的胜率
    local combos = {}
    for secondary_name, secondary_data in pairs(stats.secondary_generals) do
        if secondary_data.games >= 3 then  -- 至少3局才有参考价值
            local win_rate = secondary_data.wins / secondary_data.games
            table.insert(combos, {
                name = secondary_name,
                games = secondary_data.games,
                wins = secondary_data.wins,
                win_rate = win_rate,
                is_secondary = secondary_data.is_secondary
            })
        end
    end
    
    -- 按胜率降序排序
    table.sort(combos, function(a, b)
        if a.win_rate == b.win_rate then
            return a.games > b.games  -- 胜率相同时，场次多的优先
        end
        return a.win_rate > b.win_rate
    end)
    
    -- 保存前10个最佳组合
    for i = 1, math.min(10, #combos) do
        stats.best_secondary_combos[i] = combos[i]
    end
end

-- 记录卡牌使用
local function recordCardUsed(player, card, caused_damage)
    local room = player:getRoom()
    local game_mode = getGameModeName(room:getMode())
    
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name, game_mode)
    
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
    if not skill_name or skill_name == "" then
        return
    end
    
    local room = player:getRoom()
    local game_mode = getGameModeName(room:getMode())
    local data = loadGeneralData()
    
    -- 检查技能是否属于主将
    local main_general = sgs.Sanguosha:getGeneral(player:getGeneralName())
    local is_main_general_skill = false
    
    if main_general then
        local visible_skills = main_general:getVisibleSkillList()
        for i = 0, visible_skills:length() - 1 do
            local skill = visible_skills:at(i)
            if skill:objectName() == skill_name then
                is_main_general_skill = true
                break
            end
            
            -- 检查相关技能
            local related_skills = skill:getRelatedSkills()
            for j = 0, related_skills:length() - 1 do
                if related_skills:at(j) == skill_name then
                    is_main_general_skill = true
                    break
                end
            end
            
            if is_main_general_skill then
                break
            end
        end
    end
    
    -- 如果是主将技能，记录到主将
    if is_main_general_skill then
        local general_name = player:getGeneralName()
        local stats = getGeneralStats(data, general_name, game_mode)
        
        if not stats.skills_used[skill_name] then
            stats.skills_used[skill_name] = 0
        end
        stats.skills_used[skill_name] = stats.skills_used[skill_name] + 1
    end
    
    -- 检查技能是否属于副将
    local general2_name = player:getGeneral2Name()
    if general2_name and general2_name ~= "" then
        local secondary_general = sgs.Sanguosha:getGeneral(general2_name)
        local is_secondary_general_skill = false
        
        if secondary_general then
            local visible_skills = secondary_general:getVisibleSkillList()
            for i = 0, visible_skills:length() - 1 do
                local skill = visible_skills:at(i)
                if skill:objectName() == skill_name then
                    is_secondary_general_skill = true
                    break
                end
                
                -- 检查相关技能
                local related_skills = skill:getRelatedSkills()
                for j = 0, related_skills:length() - 1 do
                    if related_skills:at(j) == skill_name then
                        is_secondary_general_skill = true
                        break
                    end
                end
                
                if is_secondary_general_skill then
                    break
                end
            end
        end
        
        -- 如果是副将技能，记录到副将的统计数据
        if is_secondary_general_skill then
            local stats2 = getGeneralStats(data, general2_name, game_mode)
            
            if not stats2.skills_used[skill_name] then
                stats2.skills_used[skill_name] = 0
            end
            stats2.skills_used[skill_name] = stats2.skills_used[skill_name] + 1
        end
    end
    
    saveGeneralData(data)
end

-- 记录伤害
local function recordDamage(player, damage_data, is_source)
    local room = player:getRoom()
    local game_mode = getGameModeName(room:getMode())
    
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name, game_mode)
    
    local damage_value = damage_data.damage
    local card = damage_data.card
    local nature = damage_data.nature
    
    if is_source then
        stats.damage_stats.total_dealt = stats.damage_stats.total_dealt + damage_value
        
        -- 分类统计伤害
        if card then
            if card:isKindOf("Slash") then
                stats.damage_stats.slash_damage = stats.damage_stats.slash_damage + damage_value
            elseif card:isKindOf("Duel") then
                stats.damage_stats.duel_damage = stats.damage_stats.duel_damage + damage_value
            elseif card:isKindOf("AOE") then
                stats.damage_stats.aoe_damage = stats.damage_stats.aoe_damage + damage_value
            elseif card:isNDTrick() then
                stats.damage_stats.ndtrick_damage = stats.damage_stats.ndtrick_damage + damage_value
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
        
        -- 标记受伤触发（用于收益计算）
        markBenefitTrigger(player, "on_damaged")
        
        -- 记录受伤前的状态（保持兼容性）
        local game_data = player:getTag("GeneralStatsGameData"):toTable() or {}
        game_data.hp_before_damage = player:getHp()
        player:setTag("GeneralStatsGameData", sgs.QVariant(game_data))
    end
    
    saveGeneralData(data)
end

-- 通用收益记录系统（基于事件结算链）
-- benefit_category: "on_damaged", "on_kill", "on_death", "on_card_used", "on_discard", "off_turn"
-- benefit_type: "cards_drawn", "damage_dealt", "hp_recovered", "cards_given", "damage_bonus", "extra_turns", "effects_applied"
-- value: 数值
local function recordBenefit(player, benefit_category, benefit_type, value)
    local room = player:getRoom()
    local game_mode = getGameModeName(room:getMode())
    
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name, game_mode)
    
    -- 确保收益分类存在
    if not stats.benefits[benefit_category] then
        return
    end
    
    -- 确保收益类型存在
    if not stats.benefits[benefit_category][benefit_type] then
        return
    end
    
    stats.benefits[benefit_category][benefit_type] = stats.benefits[benefit_category][benefit_type] + value
    saveGeneralData(data)
end

-- 标记收益触发事件（记录到tag供后续事件检查）
local function markBenefitTrigger(player, benefit_category, extra_data)
    local game_data = player:getTag("GeneralStatsGameData"):toTable() or {}
    
    -- 标记当前触发的收益类型
    game_data.current_benefit_trigger = benefit_category
    game_data.benefit_trigger_data = extra_data or {}
    
    -- 增加触发计数
    local room = player:getRoom()
    local game_mode = getGameModeName(room:getMode())
    local data = loadGeneralData()
    local general_name = player:getGeneralName()
    local stats = getGeneralStats(data, general_name, game_mode)
    
    if stats.benefits[benefit_category] then
        stats.benefits[benefit_category].trigger_count = stats.benefits[benefit_category].trigger_count + 1
        saveGeneralData(data)
    end
    
    player:setTag("GeneralStatsGameData", sgs.QVariant(game_data))
end

-- 清除收益触发标记（事件结算完成后）
local function clearBenefitTrigger(player)
    local game_data = player:getTag("GeneralStatsGameData"):toTable() or {}
    game_data.current_benefit_trigger = nil
    game_data.benefit_trigger_data = nil
    player:setTag("GeneralStatsGameData", sgs.QVariant(game_data))
end

-- 检查当前是否在某个收益触发链中
local function isInBenefitChain(player, benefit_category)
    local game_data = player:getTag("GeneralStatsGameData"):toTable() or {}
    return game_data.current_benefit_trigger == benefit_category
end

-- 根据CardMoveReason判断收益类型
local function checkBenefitFromMoveReason(player, move_reason)
    if not move_reason then return nil end
    
    local reason_str = move_reason.m_reason
    local skill_name = move_reason.m_skillName or ""
    
    -- 根据原因判断收益类型
    -- S_REASON_DRAW: 摸牌阶段摸牌
    -- S_REASON_GOTCARD: 获得牌（可能是技能收益）
    -- S_REASON_PREVIEWGIVE: 获得牌
    
    local game_data = player:getTag("GeneralStatsGameData"):toTable() or {}
    
    -- 检查当前是否有活跃的收益触发
    if game_data.current_benefit_trigger then
        return game_data.current_benefit_trigger
    end
    
    -- 根据技能名称推断（如果有技能名）
    if skill_name ~= "" then
        -- 这里可以根据已知技能名称判断类型
        -- 例如：反馈、英魂、遗计等
        return "skill_triggered"  -- 技能触发的收益
    end
    
    return nil
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
    events = { sgs.EventPhaseStart, sgs.EventPhaseEnd, sgs.TurnStart },
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
        
        -- 在出牌阶段结束时清除出牌触发标记
        if event == sgs.EventPhaseEnd then
            if player:getPhase() == sgs.Player_Play then
                clearBenefitTrigger(player)
            elseif player:getPhase() == sgs.Player_Discard then
                -- 弃牌阶段结束，清除弃牌触发标记
                clearBenefitTrigger(player)
            end
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
        local death = data:toDeath()
        local winner = getWinner(room,death.who)
        if not winner then return end
        
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
    events = { sgs.InvokeSkill, sgs.CardFinished },
    global = true,
    priority = -20,
    can_trigger = function(self, player)
        return player and player:isAlive()
    end,
    on_trigger = function(self, event, player, data)
        if event == sgs.InvokeSkill then
            local skill_name = data:toString()
            if skill_name and skill_name ~= "" then
                recordSkillUsed(player, skill_name)
            end
        elseif event == sgs.CardFinished then
            local use = data:toCardUse()
            local card = use.card
            if card and card:isKindOf("SkillCard") then
                local skill_name = card:getSkillName()
                if skill_name and skill_name ~= "" then
                    recordSkillUsed(player, skill_name)
                end
            end
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
            
            -- 标记出牌触发（用于出牌收益，如英姿、集智等）
            markBenefitTrigger(player, "on_card_used")
        end
        if card and #card:getSkillNames() > 0 then
            for _, skill_name in ipairs(card:getSkillNames()) do
                if skill_name and skill_name ~= "" then
                    recordSkillUsed(player, skill_name)
                end
            end
        end
        
        return false
    end
}

-- 伤害记录器
GeneralStatsDamageRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_damage",
    events = { sgs.DamageCaused, sgs.DamageInflicted, sgs.Damage, sgs.DamageComplete },
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
            -- DamageInflicted：伤害即将造成，标记受伤触发
            recordDamage(player, damage, false)
        elseif event == sgs.Damage then
            -- Damage：伤害已经造成，此时可能触发受伤收益技能
            -- 记录卡牌造成的实际伤害
            if damage.from and damage.card then
                local room = damage.from:getRoom()
                local game_mode = getGameModeName(room:getMode())
                local data_obj = loadGeneralData()
                local general_name = damage.from:getGeneralName()
                local stats = getGeneralStats(data_obj, general_name, game_mode)
                local card_name = damage.card:objectName()
                
                if stats.cards_used[card_name] then
                    stats.cards_used[card_name].damage = stats.cards_used[card_name].damage + damage.damage
                end
                
                saveGeneralData(data_obj)
            end
        elseif event == sgs.DamageComplete then
            -- DamageComplete：伤害结算完成，清除受伤触发标记
            clearBenefitTrigger(damage.to)
        end
        
        return false
    end
}

-- 死亡记录器
GeneralStatsDeathRecorder = sgs.CreateTriggerSkill{
    name = "general_stats_death",
    events = { sgs.Death, sgs.BuryVictim },
    global = true,
    priority = -20,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        if event == sgs.Death then
            local death = data:toDeath()
            if death.who then
                local room = death.who:getRoom()
                local game_mode = getGameModeName(room:getMode())
                local data_obj = loadGeneralData()
                local general_name = death.who:getGeneralName()
                local stats = getGeneralStats(data_obj, general_name, game_mode)
                
                stats.deaths = stats.deaths + 1
                
                -- 标记死亡触发（用于死亡收益，如遗计类技能）
                markBenefitTrigger(death.who, "on_death")
                
                -- 标记死亡
                local game_data = death.who:getTag("GeneralStatsGameData"):toTable() or {}
                game_data.is_alive = false
                game_data.death_round = room:getTag("RoundCount"):toInt() or 0
                death.who:setTag("GeneralStatsGameData", sgs.QVariant(game_data))
                
                -- 记录击杀者
                if death.damage and death.damage.from then
                    local killer_general = death.damage.from:getGeneralName()
                    local killer_data = loadGeneralData()
                    local killer_stats = getGeneralStats(killer_data, killer_general, game_mode)
                    killer_stats.kills = killer_stats.kills + 1
                    
                    -- 标记击杀触发（用于击杀收益）
                    markBenefitTrigger(death.damage.from, "on_kill")
                    
                    saveGeneralData(killer_data)
                end
                
                saveGeneralData(data_obj)
            end
        elseif event == sgs.BuryVictim then
            -- BuryVictim：死亡结算完成，清除死亡和击杀触发标记
            local death = data:toDeath()
            if death.who then
                clearBenefitTrigger(death.who)
                
                -- 清除击杀者的标记
                if death.damage and death.damage.from then
                    clearBenefitTrigger(death.damage.from)
                end
            end
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
                local room = to_player:getRoom()
                local game_mode = getGameModeName(room:getMode())
                local data_obj = loadGeneralData()
                local general_name = to_player:getGeneralName()
                local stats = getGeneralStats(data_obj, general_name, game_mode)
                local card_count = move.card_ids:length()
                stats.cards_drawn = stats.cards_drawn + card_count
                
                -- 根据当前事件链判断收益来源
                local game_data = to_player:getTag("GeneralStatsGameData"):toTable() or {}
                local benefit_trigger = game_data.current_benefit_trigger
                
                if benefit_trigger then
                    -- 在收益触发链中，记录对应的收益
                    recordBenefit(to_player, benefit_trigger, "cards_drawn", card_count)
                else
                    -- 不在收益触发链中，检查移动原因
                    local reason = move.reason.m_reason
                    
                    -- 检查是否为回合外摸牌
                    if to_player:getPhase() == sgs.Player_NotActive then
                        -- 回合外摸牌
                        if reason == sgs.CardMoveReason_S_REASON_DRAW then
                            -- 正常摸牌阶段（不太可能在回合外）
                        else
                            recordBenefit(to_player, "off_turn", "cards_drawn", card_count)
                        end
                    end
                end
                
                saveGeneralData(data_obj)
            end
        end
        
        -- 记录弃牌
        if move.from and move.from_places:contains(sgs.Player_PlaceHand) 
            and (move.to_place == sgs.Player_DiscardPile or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISCARD) then
            local from_player = move.from
            if from_player then
                local room = from_player:getRoom()
                local game_mode = getGameModeName(room:getMode())
                local data_obj = loadGeneralData()
                local general_name = from_player:getGeneralName()
                local stats = getGeneralStats(data_obj, general_name, game_mode)
                stats.cards_discarded = stats.cards_discarded + move.card_ids:length()
                
                -- 标记弃牌触发（用于弃牌收益）
                markBenefitTrigger(from_player, "on_discard")
                
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
        local room = player:getRoom()
        local game_mode = getGameModeName(room:getMode())
        local recover = data:toRecover()
        local data_obj = loadGeneralData()
        local general_name = player:getGeneralName()
        local stats = getGeneralStats(data_obj, general_name, game_mode)
        
        stats.hp_recovered = stats.hp_recovered + recover.recover
        
        -- 检查回血收益来源
        recordBenefit(player, "on_damaged", "hp_recovered", recover.recover)    -- 受伤后回血（如反馈）
        recordBenefit(player, "on_kill", "hp_recovered", recover.recover)       -- 击杀后回血（如神速）
        
        -- 如果是给他人回血
        if recover.who and recover.who:objectName() ~= player:objectName() then
            local healer_general = recover.who:getGeneralName()
            local healer_data = loadGeneralData()
            local healer_stats = getGeneralStats(healer_data, healer_general, game_mode)
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
