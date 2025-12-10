-- 年度回顾功能集成配置示例
-- Integration Configuration Example for Year Review Feature

--[[
    集成方式说明：
    
    方式1: 直接在主加载文件中引入（推荐）
    如果你的项目有一个主加载文件（如 init.lua, main.lua 等），在其中添加：
]]

-- 在主加载文件中添加：
-- require "extensions.year_review"

--[[
    方式2: 确保游戏自动加载 extensions 目录
    如果你的游戏引擎会自动加载 extensions 目录下的所有 .lua 文件，
    则无需额外配置，直接将 year_review.lua 放入 extensions 目录即可。
]]

--[[
    方式3: 在现有的 Package 文件中引入
    如果你想在某个特定的扩展包中使用年度回顾功能，
    在该扩展包文件的开头添加：
]]

-- 在扩展包文件中添加：
-- dofile "extensions/year_review.lua"

--[[
    验证安装：
    安装后，在 Lua 控制台或脚本中运行以下代码来验证是否成功加载：
]]

function VerifyYearReviewInstallation()
    local skills_to_check = {
        "year_review_game_start",
        "year_review_game_over",
        "year_review_skill",
        "year_review_card"
    }
    
    local all_loaded = true
    for _, skill_name in ipairs(skills_to_check) do
        local skill = sgs.Sanguosha:getSkill(skill_name)
        if skill then
            print("[✓] " .. skill_name .. " 已加载")
        else
            print("[✗] " .. skill_name .. " 未找到")
            all_loaded = false
        end
    end
    
    if all_loaded then
        print("\n年度回顾功能安装成功！")
        return true
    else
        print("\n年度回顾功能安装失败，请检查文件路径和加载配置。")
        return false
    end
end

--[[
    使用示例：
]]

-- 示例1: 在游戏结束时自动显示房主的年度回顾
YearReviewAutoDisplay = sgs.CreateTriggerSkill{
    name = "year_review_auto_display",
    events = { sgs.GameOverJudge },
    global = true,
    priority = -20,  -- 确保在数据记录之后执行
    can_trigger = function(self, player)
        -- 只对房主显示
        return player and player:getRoom():getOwner():objectName() == player:objectName()
    end,
    on_trigger = function(self, event, player, data)
        -- 延迟显示，确保数据已保存
        local room = player:getRoom()
        local player_name = player:objectName()
        
        -- 使用线程来延迟执行，避免阻塞
        -- 注意：这需要游戏引擎支持，如果不支持可以移除此部分
        -- room:delay(2000)  -- 延迟2秒
        
        -- 生成并显示年度回顾
        local report = ShowYearReview(player_name)
        if report then
            -- 将报告分行发送（如果报告太长）
            local lines = {}
            for line in report:gmatch("[^\r\n]+") do
                table.insert(lines, line)
            end
            
            -- 每10行发送一次，避免消息过长
            for i = 1, #lines, 10 do
                local segment = {}
                for j = i, math.min(i + 9, #lines) do
                    table.insert(segment, lines[j])
                end
                local msg = table.concat(segment, "\n")
                -- 发送消息到房间（具体API根据游戏引擎而定）
                -- room:broadcastInvoke("chat", player_name .. ": " .. msg)
                print(msg)
            end
        end
        
        return false
    end
}

-- 示例2: 添加自定义命令来查询年度回顾
function RegisterYearReviewCommands()
    --[[
        如果游戏支持自定义聊天命令，可以注册以下命令：
        
        /year_review - 查看当前年度回顾
        /year_review 2023 - 查看2023年的回顾
        /year_review export - 导出HTML格式报告
    ]]
    
    -- 这里是伪代码，具体实现取决于游戏引擎的命令系统
    -- RegisterCommand("/year_review", function(player, args)
    --     if #args == 0 then
    --         ShowYearReview(player:objectName())
    --     elseif #args == 1 and tonumber(args[1]) then
    --         ShowYearReview(player:objectName(), args[1])
    --     elseif args[1] == "export" then
    --         ExportYearReviewHTML(player:objectName())
    --     end
    -- end)
end

-- 示例3: 创建一个游戏结束后的统计面板
function CreateYearReviewPanel(room, player)
    --[[
        在游戏结束界面添加一个"年度回顾"按钮
        点击后显示详细的统计信息
    ]]
    
    -- 这需要游戏引擎支持自定义UI
    -- local panel = room:createPanel("年度回顾")
    -- panel:addButton("查看回顾", function()
    --     ShowYearReview(player:objectName())
    -- end)
    -- panel:addButton("导出HTML", function()
    --     ExportYearReviewHTML(player:objectName())
    -- end)
    -- panel:show()
end

-- 示例4: 定期提醒功能
YearReviewReminder = sgs.CreateTriggerSkill{
    name = "year_review_reminder",
    events = { sgs.GameOverJudge },
    global = true,
    priority = -30,
    can_trigger = function(self, player)
        return true
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local player_name = player:objectName()
        
        -- 检查玩家的总场次
        local json = require "json"
        local file = io.open("year_review_data.json", "r")
        if file then
            local content = file:read("*all")
            file:close()
            local review_data = json.decode(content)
            
            if review_data and review_data.PlayerStats and review_data.PlayerStats[player_name] then
                local year = os.date("%Y")
                local stats = review_data.PlayerStats[player_name][year]
                
                if stats then
                    -- 每10场、50场、100场时提醒
                    if stats.total_games % 100 == 0 then
                        print(string.format("🎉 恭喜 %s！你已经完成了 %d 场游戏！", player_name, stats.total_games))
                        print("输入 ShowYearReview('" .. player_name .. "') 查看你的年度回顾！")
                    elseif stats.total_games % 50 == 0 then
                        print(string.format("💪 %s，你已经玩了 %d 场游戏！继续加油！", player_name, stats.total_games))
                    elseif stats.total_games % 10 == 0 then
                        print(string.format("👍 %s 完成了第 %d 场游戏！", player_name, stats.total_games))
                    end
                    
                    -- 特殊成就提示
                    if stats.total_wins == stats.total_games / 2 then
                        print(string.format("⚖️ %s 达成平衡！胜率正好50%%！", player_name))
                    end
                end
            end
        end
        
        return false
    end
}

-- 示例5: 数据迁移和备份
function MigrateYearReviewData()
    --[[
        如果需要从旧的统计系统迁移数据到年度回顾系统，
        可以使用此函数进行数据转换
    ]]
    
    local json = require "json"
    
    -- 读取旧数据（假设是 save10p.json）
    local old_file = io.open("save10p.json", "r")
    if not old_file then
        print("未找到旧数据文件")
        return false
    end
    
    local old_content = old_file:read("*all")
    old_file:close()
    local old_data = json.decode(old_content)
    
    -- 读取新数据
    local new_file = io.open("year_review_data.json", "r")
    local new_data = { PlayerStats = {}, CurrentYear = os.date("%Y") }
    if new_file then
        local new_content = new_file:read("*all")
        new_file:close()
        new_data = json.decode(new_content) or new_data
    end
    
    -- 转换数据结构（根据实际情况调整）
    -- if old_data and old_data.Record then
    --     for package, generals in pairs(old_data.Record) do
    --         for general_name, general_data in pairs(generals) do
    --             -- 将旧数据转换为新格式
    --             -- 这里需要根据实际的数据结构进行调整
    --         end
    --     end
    -- end
    
    -- 保存合并后的数据
    local output = io.open("year_review_data.json", "w")
    if output then
        output:write(json.encode(new_data, { indent = true }))
        output:close()
        print("数据迁移完成！")
        return true
    end
    
    return false
end

-- 注册自定义技能（如果需要）
-- if not sgs.Sanguosha:getSkill("year_review_auto_display") then 
--     local skills = sgs.SkillList()
--     skills:append(YearReviewAutoDisplay)
--     skills:append(YearReviewReminder)
--     sgs.Sanguosha:addSkills(skills)
-- end

print("年度回顾功能集成配置已加载")
print("运行 VerifyYearReviewInstallation() 来验证安装")
