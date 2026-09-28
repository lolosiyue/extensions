-- Source: TODO/HUMAN/extensions/happyrebel.lua; V2 room/scenario lifecycle port.
local function happyRoundReady(room, data, tag)
    if room:getMode() ~= "7_happyrebel" or room:getAlivePlayers():isEmpty() then return false end
    local previous = room:getTag(tag)
    return previous:isNull() or previous:toInt() ~= data:toInt()
end
local function happyRoundPay(room, ctx, tag)
    room:setTag(tag, sgs.QVariant(ctx.original_data:toInt()))
    return true
end
local function happyClearVotes(room, mark)
    for _, p in sgs.qlist(room:getAllPlayers(true)) do room:setPlayerMark(p, mark, 0) end
end

--[[
    欢乐反贼模式 (Happy Rebel Mode)
    
    模式配置：
    - 7人局：1主公 + 3忠臣 + 3反贼（无内奸）
    
    特色规则：
    1. 所有身份完全随机分配（包括主公）
    2. 每个玩家只知道自己的身份，不知道其他人
    3. 游戏开始时，反贼之间互相知道身份（其他人仍然不知道）
    4. 每轮开始时，所有人查看身份（只有主公能获得结果）
    5. 每轮开始时，反贼投票选择一名角色，得票最多的失去2点体力
    6. 每轮结束时，全员公投选择一名角色，得票最多的失去2点体力
    7. 所有角色死亡后，身份不亮置（显示unknown）
]]--

-- ==========================================
-- 创建欢乐反贼模式
-- ==========================================
createMode{
    name = "欢乐反贼杀(狼人杀玩法)",
    class = "happyrebel",
    roles = "ZCCCFFF",  -- 7人局：1主公3忠臣3反贼
    skipChooseGeneral = true,  -- 跳过传统选将，在GameReady时重新选将
    showRole = false,    -- 不显示身份（除了主公）
    lordWelfare = false  -- 主公不获得额外体力上限
    -- 注意：不使用shuffleRoles，而是在HappyRebelInit中手动打乱身份
}


-- ==========================================
-- 模式初始化：身份分配后重新选将
-- ==========================================
HappyRebelRoles = sgs.CreateRuleSkillV2{
    name = "#HappyRebelRoles", events = {sgs.GameReady},
    frequency = sgs.Skill_Compulsory,
    priority = 10,
    can_trigger = function(self, event, room, player, data)
        if room:getMode() == "7_happyrebel" and not room:getTag("HappyRebelMode"):toBool() then
            return self:objectName(), player or room:getAllPlayers(true):first()
        end
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        room:setTag("HappyRebelMode", sgs.QVariant(true))
        
        -- room:writeToConsole("=== 欢乐反贼模式：初始化 ===")
        
        -- 随机打乱所有玩家的身份（包括主公）
        local allPlayers = room:getAllPlayers()
        local playerList = {}
        local roles = {}
        
        -- 收集所有玩家和身份
        for _, p in sgs.qlist(allPlayers) do
            table.insert(playerList, p)
            table.insert(roles, p:getRole())
        end
        
        -- 先将所有人的身份广播为unknown（清除主公的公开状态）
        for i, p in ipairs(playerList) do
            room:broadcastProperty(p, "role", "unknown")
            -- 清除"身份已公开"标记（解决客户端无法修改身份判别的问题）
            room:setPlayerProperty(p, "role_shown", sgs.QVariant(false))
        end
        -- room:writeToConsole("已将所有玩家身份隐藏（显示为unknown）")
        
        -- 打乱身份顺序（Fisher-Yates洗牌算法）
        for i = #roles, 2, -1 do
            local j = math.random(1, i)
            roles[i], roles[j] = roles[j], roles[i]
        end
        
        -- 重新分配真实身份（只在服务器端，不广播）
        for i, p in ipairs(playerList) do
            -- 在服务器端设置真实身份
            p:setRole(roles[i])
            
            -- 使用notifyProperty让玩家知道自己的身份（不广播给其他人）
            room:notifyProperty(p, p, "role")
            
            -- room:writeToConsole(p:objectName() .. " 的真实身份是：" .. roles[i])
        end
        
        -- 现在每个玩家都知道自己的身份，但不知道其他人的身份（显示unknown）
        -- 在GameStart时，反贼之间会通过notifyProperty互相知道身份
        
        return false
    end,

}
addToSkills(HappyRebelRoles)

HappyRebelInit = sgs.CreateRuleSkillV2{
    name = "#HappyRebelInit", events = {sgs.GameReady}, priority = 9,
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if room:getMode() == "7_happyrebel" and not room:getTag("HappyRebelGenerals"):toBool() then
            return self:objectName(), player or room:getAllPlayers(true):first()
        end
    end,
    on_cost = function(self, event, room, player, ctx)
        local available = sgs.Sanguosha:getLimitedGeneralNames()
        local chosen = {}
        for _, p in sgs.qlist(room:getAllPlayers()) do
            local pool, options = {}, {}
            for _, name in ipairs(available) do table.insert(pool, name) end
            for i = 1, math.min(5, #pool) do
                table.insert(options, table.remove(pool, math.random(1, #pool)))
            end
            if #options == 0 then break end
            local name = room:askForGeneral(p, table.concat(options, "+"))
            if not table.contains(options, name) then name = options[1] end
            table.removeOne(available, name)
            table.insert(chosen, p:objectName() .. ":" .. name)
        end
        ctx.extra_data:setValue(table.concat(chosen, "+"))
        return #chosen > 0
    end,
    on_pay = function(self, event, room, player, ctx)
        room:setTag("HappyRebelGenerals", sgs.QVariant(true))
        return true
    end,
    on_effect = function(self, event, room, player, ctx)
        for entry in ctx.extra_data:toString():gmatch("[^+]+") do
            local seat, name = entry:match("^([^:]+):(.+)$")
            local p = room:findPlayerByObjectName(seat)
            room:changeHero(p, name, true, false, false, false, 0)
            local general = p:getGeneral()
            if general then
                for j = 1, general:getStartHujia() do p:gainHujia() end
            end
            p:setTag("MaxHp", sgs.QVariant(p:getMaxHp()))
            p:setTag("Hp", sgs.QVariant(p:getHp()))
        end
        return false
    end,
}
addToSkills(HappyRebelInit)


-- ==========================================
-- 模式专属技能1：反贼互知
-- ==========================================
HappyRebelKnow = sgs.CreateRuleSkillV2{
    name = "#HappyRebelKnow", events = {sgs.GameStart},
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if room:getMode() == "7_happyrebel" and not room:getTag("HappyRebelKnown"):toBool() then
            return self:objectName(), player or room:getAllPlayers(true):first()
        end
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        room:setTag("HappyRebelKnown", sgs.QVariant(true))
        -- 获取所有玩家
        local allPlayers = room:getAllPlayers()
        
        -- 收集所有反贼
        local rebels = {}
        for _, p in sgs.qlist(allPlayers) do
            if p:getRole() == "rebel" then
                table.insert(rebels, p)
            end
        end
        
        -- room:writeToConsole("找到 " .. #rebels .. " 名反贼")
        
        -- 让每个反贼知道其他反贼的身份
        for i = 1, #rebels do
            for j = 1, #rebels do
                if i ~= j then
                    -- 让反贼i知道反贼j的身份
                    room:notifyProperty(rebels[i], rebels[j], "role")
                    -- room:writeToConsole(rebels[i]:getGeneralName() .. " 知道了 " .. 
                    --                    rebels[j]:getGeneralName() .. " 是反贼")
                end
            end
        end
        
        -- 重置所有玩家的AI（因为反贼已经知道队友身份）
        for _, p in sgs.qlist(allPlayers) do
            room:resetAI(p)
        end
        -- room:writeToConsole("已重置所有玩家的AI")
         
        
        return false
    end,

}
addToSkills(HappyRebelKnow)


-- ==========================================
-- 模式专属技能2：死亡隐藏身份
-- ==========================================
HappyRebelHideDeath = sgs.CreateRuleSkillV2{
    name = "#HappyRebelHideDeath", events = {sgs.BeforeGameOverJudge},
    frequency = sgs.Skill_Compulsory,
    priority = 10,
    on_record = function(self, event, room, player, ctx)
        if room:getMode() == "7_happyrebel" then
            local death = ctx.original_data:toDeath()
            if death and death.who then room:setPlayerProperty(death.who, "HideDeathIcon", sgs.QVariant(true)) end
        end
    end,
}
addToSkills(HappyRebelHideDeath)


-- ==========================================
-- 模式专属技能3：主公查看身份
-- ==========================================
HappyRebelLordCheck = sgs.CreateRuleSkillV2{
    name = "#HappyRebelLordCheck", events = {sgs.RoundStart},
    frequency = sgs.Skill_Compulsory,
    priority = 2,
    can_trigger = function(self, event, room, player, data)
        if happyRoundReady(room, data, "HappyRebelLordCheck_Round") then
            return self:objectName(), player or room:getAllPlayers(true):first()
        end
    end,
    on_cost = function(self, event, room, player, ctx)
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            local targets = room:getOtherPlayers(p)
            if not targets:isEmpty() then
                local target = room:askForPlayerChosen(p, targets, self:objectName(), "@HappyRebelLordCheck", true)
                if target and p:isLord() then ctx.targets:append(target) end
            end
        end
        return true
    end,
    on_pay = function(self, event, room, player, ctx)
        return happyRoundPay(room, ctx, "HappyRebelLordCheck_Round")
    end,
    on_effect = function(self, event, room, player, ctx)
        local lord = room:getLord()
        if lord then
            for _, target in sgs.qlist(ctx.targets) do
                room:notifyProperty(lord, target, "role")
                room:setPlayerMark(target, "lord_check", 1)
            end
        end
        for _, p in sgs.qlist(room:getAlivePlayers()) do room:resetAI(p) end
        return false
    end,

}
addToSkills(HappyRebelLordCheck)


-- ==========================================
-- 模式专属技能4：反贼投票
-- ==========================================
HappyRebelVote = sgs.CreateRuleSkillV2{
    name = "#HappyRebelVote", events = {sgs.RoundStart},
    frequency = sgs.Skill_Compulsory,
    priority = 1,
    can_trigger = function(self, event, room, player, data)
        if happyRoundReady(room, data, "HappyRebelVote_Round") then
            return self:objectName(), player or room:getAllPlayers(true):first()
        end
    end,
    on_cost = function(self, event, room, player, ctx)
        local allPlayers = room:getAlivePlayers()
        -- 发送反贼投票开始的日志
        local log = sgs.LogMessage()
        log.type = "#HappyRebelVoteStart"
        room:sendLog(log)
        
        -- 复用前面获取的allPlayers
        
        -- 收集所有反贼（只有反贼能看到投票标记）
        local rebels = sgs.SPlayerList()
        for _, p in sgs.qlist(allPlayers) do
            if p:getRole() == "rebel" then
                rebels:append(p)
            end
        end
        
        -- 投票统计表（只统计反贼的投票）
        local ballots = {} -- Room invocation payload; target-confirming must not retarget ballots.
        
        -- 让所有玩家都投票（隐藏反贼身份）
        for _, p in sgs.qlist(allPlayers) do
            -- 创建可投票目标列表
            local targets = sgs.SPlayerList()
            for _, target in sgs.qlist(allPlayers) do
                targets:append(target)
            end
            
            -- 让玩家选择投票目标
            local target = room:askForPlayerChosen(p, targets, self:objectName(), "@HappyRebelVote", false)
            
            if target then
                -- 只有反贼的投票才计数
                if p:getRole() == "rebel" then
                table.insert(ballots, target:objectName())
                    
                    -- Ballot presentation updates during selection; HP/game effects resolve after payment.
                    -- 给目标添加投票标记（只有反贼能看到）
                    room:addPlayerMark(target, "&rebel_vote", 1, rebels)
                    
                    -- room:writeToConsole(p:getGeneralName() .. "（反贼）投票给了 " .. target:getGeneralName())
                else
                    -- 非反贼的投票不计数
                    -- room:writeToConsole(p:getGeneralName() .. "（" .. p:getRole() .. "）投票无效")
                end
            end
        end
        
        ctx.extra_data:setValue(table.concat(ballots, "+"))
        return true
    end,
    on_pay = function(self, event, room, player, ctx)
        return happyRoundPay(room, ctx, "HappyRebelVote_Round")
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        local allPlayers = room:getAlivePlayers()
        local votes = {}
        for name in ctx.extra_data:toString():gmatch("[^+]+") do
            votes[name] = (votes[name] or 0) + 1
        end
        -- 找出得票最多的玩家
        local maxVotes = 0
        local maxVotePlayers = {}
        
        for playerName, voteCount in pairs(votes) do
            if voteCount > maxVotes then
                maxVotes = voteCount
                maxVotePlayers = {playerName}
            elseif voteCount == maxVotes then
                table.insert(maxVotePlayers, playerName)
            end
        end
        
        -- 如果有得票最多的玩家
        if maxVotes > 0 and #maxVotePlayers == 1 then
            -- 只有唯一最高票时才执行惩罚（避免平票）
            local targetName = maxVotePlayers[1]
            local targetPlayer = nil
            
            for _, p in sgs.qlist(allPlayers) do
                if p:objectName() == targetName then
                    targetPlayer = p
                    break
                end
            end
            
            if targetPlayer and targetPlayer:isAlive() then
                -- 提前保存所有需要的信息，避免loseHp后对象状态改变
                local generalName = targetPlayer:getGeneralName()
                local playerObj = targetPlayer
                
                -- 发送反贼投票结果日志
                local log = sgs.LogMessage()
                log.type = "#HappyRebelVoteResult"
                log.from = playerObj
                -- 不显示票数，避免暴露反贼数量
                -- log.arg = tostring(maxVotes)
                room:sendLog(log)
                
                -- 显示特效
                local args = sgs.StringList()
                args:append(generalName)
                room:doLightbox("$HappyRebelVoteResult", args, 2000)
                
                -- 【AI身份推测】成为反贼投票结果的人，很可能不是反贼
                -- 初始化身份评分表（如果还没有的话）
                sgs.roleValue = sgs.roleValue or {}
                if not sgs.roleValue[targetName] then
                    sgs.roleValue[targetName] = {
                        loyalist = 0,
                        rebel = 0,
                        renegade = 0
                    }
                end
                
                -- 成为反贼投票的目标，降低反贼分数，增加忠臣分数
                -- 这是一个强烈的信号：反贼不会投自己人
                sgs.roleValue[targetName].rebel = sgs.roleValue[targetName].rebel - 80
                sgs.roleValue[targetName].loyalist = sgs.roleValue[targetName].loyalist + 60
                
                -- room:writeToConsole("【AI推测】" .. generalName .. " 成为反贼投票结果，反贼分数-80，忠臣分数+60")
                
                -- 先清除所有标记（避免loseHp导致死亡时标记残留引起崩溃）
                pcall(function()
                    for _, p in sgs.qlist(room:getAllPlayers()) do
                        if p then
                            pcall(function() room:setPlayerMark(p, "&rebel_vote", 0) end)
                        end
                    end
                end)
                
                -- 执行失去体力（可能导致死亡，之后不要再使用targetPlayer）
                -- room:writeToConsole(generalName .. " 获得最多反贼票数（" .. maxVotes .. "票），失去2点体力")
                room:loseHp(playerObj, 2)
                
                return false
            end
        elseif maxVotes > 0 and #maxVotePlayers > 1 then
            -- 平票，发送平票日志（不显示票数，避免暴露反贼数量）
            local log = sgs.LogMessage()
            log.type = "#HappyRebelVoteTie"
            -- 不显示人数和票数
            -- log.arg = tostring(#maxVotePlayers)
            -- log.arg2 = tostring(maxVotes)
            room:sendLog(log)
            
            -- 显示平票特效（不包含具体数字）
            local args = sgs.StringList()
            -- 不显示具体数字
            -- args:append(tostring(#maxVotePlayers))
            -- args:append(tostring(maxVotes))
            room:doLightbox("$HappyRebelVoteTie", args, 2000)
        else
            -- 发送没有人获得投票的日志
            local log = sgs.LogMessage()
            log.type = "#HappyRebelVoteNoResult"
            room:sendLog(log)
            
            -- room:writeToConsole("没有人获得投票")
        end
        
        -- 清除所有投票标记（在没有loseHp的情况下执行）
        -- 使用pcall保护，避免访问无效对象时崩溃
        pcall(function()
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p then
                    pcall(function() room:setPlayerMark(p, "&rebel_vote", 0) end)
                end
            end
        end)
        
        return false
    end,
    on_turn_broken = function(self, callback_name, event, room, player, ctx)
        happyClearVotes(room, "&rebel_vote")
    end,

}
addToSkills(HappyRebelVote)


-- ==========================================
-- 模式专属技能5：全员公投
-- ==========================================
HappyRebelPublicVote = sgs.CreateRuleSkillV2{
    name = "#HappyRebelPublicVote", events = {sgs.RoundEnd},
    frequency = sgs.Skill_Compulsory,
    priority = 1,
    can_trigger = function(self, event, room, player, data)
        if happyRoundReady(room, data, "HappyRebelPublicVote_Round") then
            return self:objectName(), player or room:getAllPlayers(true):first()
        end
    end,
    on_cost = function(self, event, room, player, ctx)
        local allPlayers = room:getAlivePlayers()
        -- 发送全员公投开始的日志
        local log = sgs.LogMessage()
        log.type = "#HappyRebelPublicVoteStart"
        room:sendLog(log)
        
        -- 复用前面获取的allPlayers
        
        -- 投票统计表（所有人的投票都计数）
        local ballots = {} -- Room invocation payload; target-confirming must not retarget ballots.
        
        -- 让所有玩家都投票
        for _, p in sgs.qlist(allPlayers) do
            -- 创建可投票目标列表
            local targets = sgs.SPlayerList()
            for _, target in sgs.qlist(allPlayers) do
                targets:append(target)
            end
            
            -- 让玩家选择投票目标
            local target = room:askForPlayerChosen(p, targets, self:objectName(), "@HappyRebelPublicVote", false)
            
            if target then
                -- 所有人的投票都计数
                table.insert(ballots, target:objectName())
                
                -- 给目标添加公开投票标记（所有人可见）
                room:addPlayerMark(target, "&public_vote", 1)
                
                -- 发送日志信息
                local log = sgs.LogMessage()
                log.type = "#HappyRebelPublicVoteLog"
                log.from = p
                log.to:append(target)
                room:sendLog(log)
                
                -- room:writeToConsole(p:getGeneralName() .. " 投票给了 " .. target:getGeneralName())
            end
        end
        
        ctx.extra_data:setValue(table.concat(ballots, "+"))
        return true
    end,
    on_pay = function(self, event, room, player, ctx)
        return happyRoundPay(room, ctx, "HappyRebelPublicVote_Round")
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        local allPlayers = room:getAlivePlayers()
        local votes = {}
        for name in ctx.extra_data:toString():gmatch("[^+]+") do
            votes[name] = (votes[name] or 0) + 1
        end
        -- 找出得票最多的玩家
        local maxVotes = 0
        local maxVotePlayers = {}
        
        for playerName, voteCount in pairs(votes) do
            if voteCount > maxVotes then
                maxVotes = voteCount
                maxVotePlayers = {playerName}
            elseif voteCount == maxVotes then
                table.insert(maxVotePlayers, playerName)
            end
        end
        
        -- 如果有得票最多的玩家
        if maxVotes > 0 and #maxVotePlayers == 1 then
            -- 只有唯一最高票时才执行惩罚（避免平票）
            local targetName = maxVotePlayers[1]
            local targetPlayer = nil
            
            for _, p in sgs.qlist(allPlayers) do
                if p:objectName() == targetName then
                    targetPlayer = p
                    break
                end
            end
            
            if targetPlayer and targetPlayer:isAlive() then
                -- 提前保存所有需要的信息，避免loseHp后对象状态改变
                local generalName = targetPlayer:getGeneralName()
                local playerObj = targetPlayer
                
                -- 发送得票最多的日志
                local log = sgs.LogMessage()
                log.type = "#HappyRebelPublicVoteResult"
                log.from = playerObj
                log.arg = tostring(maxVotes)
                room:sendLog(log)
                
                -- 显示特效
                local args = sgs.StringList()
                args:append(generalName)
                room:doLightbox("$HappyRebelPublicVoteResult", args, 2000)
                
                -- 先清除所有标记（避免loseHp导致死亡时标记残留引起崩溃）
                pcall(function()
                    for _, p in sgs.qlist(room:getAllPlayers()) do
                        if p then
                            pcall(function() room:setPlayerMark(p, "&public_vote", 0) end)
                        end
                    end
                end)
                
                -- 执行失去体力（可能导致死亡，之后不要再使用targetPlayer）
                -- room:writeToConsole(generalName .. " 获得最多票数（" .. maxVotes .. "票），失去2点体力")
                room:loseHp(playerObj, 2)
                
                return false
            end
        elseif maxVotes > 0 and #maxVotePlayers > 1 then
            -- 平票，发送平票日志
            local log = sgs.LogMessage()
            log.type = "#HappyRebelPublicVoteTie"
            log.arg = tostring(#maxVotePlayers)
            log.arg2 = tostring(maxVotes)
            room:sendLog(log)
            
            -- 显示平票特效（不包含具体数字，参照反贼公投）
            local args = sgs.StringList()
            room:doLightbox("$HappyRebelPublicVoteTie", args, 2000)
        else
            -- 发送没有人获得投票的日志
            local log = sgs.LogMessage()
            log.type = "#HappyRebelPublicVoteNoResult"
            room:sendLog(log)
            
            -- room:writeToConsole("没有人获得投票")
        end
        
        -- 清除所有投票标记（在没有loseHp的情况下执行）
        -- 使用pcall保护，避免访问无效对象时崩溃
        pcall(function()
            for _, p in sgs.qlist(room:getAllPlayers()) do
                if p then
                    pcall(function() room:setPlayerMark(p, "&public_vote", 0) end)
                end
            end
        end)
        
        return false
    end,
    on_turn_broken = function(self, callback_name, event, room, player, ctx)
        happyClearVotes(room, "&public_vote")
    end,

}
addToSkills(HappyRebelPublicVote)


-- ==========================================
-- 模式专属技能6：移除正常击杀奖惩
-- ==========================================
HappyRebelSkipReward = sgs.CreateRuleSkillV2{
    name = "#HappyRebelSkipReward", events = {sgs.BuryVictim},
    frequency = sgs.Skill_Compulsory,
    priority = 10,
    on_record = function(self, event, room, player, ctx)
        if room:getMode() == "7_happyrebel" then
            room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
        end
    end,
}
addToSkills(HappyRebelSkipReward)


-- ==========================================
-- 模式专属技能7：移除正常游戏结束结算
-- ==========================================
HappyRebelSkipNormalWin = sgs.CreateRuleSkillV2{
    name = "#HappyRebelSkipNormalWin", events = {sgs.GameOverJudge},
    frequency = sgs.Skill_Compulsory,
    priority = 3,
    on_record = function(self, event, room, player, ctx)
        if room:getMode() == "7_happyrebel" then
            room:setTag("SkipGameRule", sgs.QVariant(event))
        end
    end,
}
addToSkills(HappyRebelSkipNormalWin)


-- ==========================================
-- 模式专属技能8：自定义胜利判定
-- ==========================================
HappyRebelCustomWin = sgs.CreateRuleSkillV2{
    name = "#HappyRebelCustomWin", events = {sgs.GameOverJudge},
    frequency = sgs.Skill_Compulsory,
    priority = 2,
    can_trigger = function(self, event, room, player, data)
        if room:getMode() == "7_happyrebel" then
            return self:objectName(), player or room:getAllPlayers(true):first()
        end
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        local allPlayers = room:getAlivePlayers()
        
        -- 统计存活角色的身份
        local hasRebel = false
        local hasLordOrLoyalist = false
        
        for _, p in sgs.qlist(allPlayers) do
            if p:getRole() == "rebel" then
                hasRebel = true
            end
            if p:getRole() == "lord" or p:getRole() == "loyalist" then
                hasLordOrLoyalist = true
            end
        end
        
        -- 判断胜利条件
        if not hasRebel then
            -- 存活角色中没有反贼，主公忠臣获胜
            -- room:writeToConsole("=== 没有反贼存活，主公忠臣阵营获胜 ===")
            room:gameOver("lord+loyalist")
        elseif not hasLordOrLoyalist then
            -- 存活角色中没有主公和忠臣，反贼获胜
            -- room:writeToConsole("=== 没有主公忠臣存活，反贼阵营获胜 ===")
            room:gameOver("rebel")
        end
        
        return false
    end,

}
addToSkills(HappyRebelCustomWin)


-- ==========================================
-- 翻译表
-- ==========================================
sgs.LoadTranslationTable{
    ["#HappyRebelRoles"] = "欢乐反贼：身份分配",
    ["7_happyrebel"] = "欢乐反贼模式（7人局）",
    ["#HappyRebelInit"] = "欢乐反贼：模式初始化",
    ["#HappyRebelKnow"] = "欢乐反贼：反贼互知",
    ["#HappyRebelHideDeath"] = "欢乐反贼：死亡隐藏",
    ["#HappyRebelLordCheck"] = "欢乐反贼：查看身份",
    ["@HappyRebelLordCheck"] = "【轮开始·查看身份】<br/><font color='#FF0000' size='5'><b>只有主公有效</b></font><br/>请选择一名其他角色查看身份",
    ["#HappyRebelVote"] = "欢乐反贼：反贼投票",
    ["@HappyRebelVote"] = "【轮开始·反贼投票】<br/><font color='#FF0000' size='5'><b>只有反贼有效</b></font><br/>请选择一名角色投票，得票最多的失去2点体力",
    ["#HappyRebelPublicVote"] = "欢乐反贼：全员公投",
    ["@HappyRebelPublicVote"] = "【轮结束·全员公投】<br/><font color='#FF0000' size='5'><b>所有人都有效</b></font><br/>请选择一名角色投票，得票最多的失去2点体力",
    ["#HappyRebelPublicVoteLog"] = "%from 投票给了 %to",
    ["#HappyRebelPublicVoteResult"] = "%from 获得最多票数（%arg票），失去2点体力",
    ["#HappyRebelPublicVoteTie"] = "全员公投平票（%arg人各获得%arg2票），无事发生",
    ["#HappyRebelPublicVoteNoResult"] = "全员公投结束，没有人获得投票",
    ["#HappyRebelVoteStart"] = "反贼投票开始（所有人选择，只有反贼的票有效）",
    ["#HappyRebelVoteResult"] = "%from 获得最多反贼票数，失去2点体力",
    ["#HappyRebelVoteTie"] = "反贼投票平票，无事发生",
    ["#HappyRebelVoteNoResult"] = "反贼投票结束，没有人获得投票",
    ["#HappyRebelPublicVoteStart"] = "全员公投开始（所有人的票都有效）",
    ["#HappyRebelSkipReward"] = "欢乐反贼：移除击杀奖惩",
    ["#HappyRebelSkipNormalWin"] = "欢乐反贼：移除正常胜利结算",
    ["#HappyRebelCustomWin"] = "欢乐反贼：自定义胜利判定",
    ["rebel_vote"] = "反贼票",
    ["public_vote"] = "公投票",
    ["$HappyRebelVoteResult"] = "%1 获得反贼投票最多票数，失去2点体力",
    ["$HappyRebelVoteTie"] = "反贼投票平票，无事发生",
    ["$HappyRebelPublicVoteResult"] = "%1 获得公投最多票数，失去2点体力",
    ["$HappyRebelPublicVoteTie"] = "全员公投平票，无事发生",
}


-- ==========================================
-- 使用说明
-- ==========================================
--[[
    欢乐反贼模式说明：
    
    【模式配置】
    - 人数：7人
    - 身份分配：1主公 + 3忠臣 + 3反贼
    - 特点：无内奸，势力均衡
    
    【特殊规则】
    1. 完全随机身份分配：
       - 跳过传统的选将阶段
       - GameReady时，随机打乱所有玩家的身份（包括主公）
       - 每个玩家只知道自己的身份，不知道其他人
       - 主公不再固定在第一个位置，可能是任何一个玩家
       - 然后每位玩家从5个随机武将中选择一个
       - 确保身份分配的公平性和随机性
    
    2. 反贼互知（游戏开始后）：
       - 在GameStart事件时，所有反贼互相知道彼此的身份
       - 主公和忠臣仍然不知道其他人的身份（显示unknown）
       - 反贼可以更好地配合作战
       - 主公和忠臣需要通过行为推理判断
    
    3. 主公查看身份（新增）：
       - 每轮开始时（RoundStart事件）触发
       - 所有人都要选择一名其他角色
       - 但只有主公身份的玩家能获得真实结果
       - 非主公选择后没有任何效果
       - 从外观上看不出谁是主公（所有人操作都一样）
       - 查看后只有主公知道目标身份，不会广播给其他人
       - 查看后会重置所有AI（主公AI会根据新信息调整策略）
    
    4. 反贼投票（新增）：
       - 每轮开始时（RoundStart事件）触发
       - 所有玩家都要选择一名角色进行投票
       - 但只有反贼的投票才计数
       - 非反贼投票无效（隐藏反贼身份）
       - 得票最多的角色失去2点体力
       - 如果多人并列最高票，无事发生
       - 从外观上看不出谁是反贼（所有人都投票）
       - 【特殊机制】反贼之间可以看到投票标记（&rebel_vote）
         * 使用addPlayerMark的only_viewers参数
         * 只有反贼能看到被投票角色的票数标记
         * 投票结束后标记自动清除
    
    5. 全员公投（新增）：
       - 每轮结束时（RoundEnd事件）触发
       - 所有玩家都要选择一名角色进行投票
       - 所有人的投票都有效
       - 得票最多的角色失去2点体力
       - 如果多人并列最高票，无事发生
       - 可用于削弱强势角色或通过投票行为推理身份
       - 【特殊机制】完全公开透明
         * 所有人都能看到投票标记（&public_vote）
         * 每次投票都发送日志（%from 投票给了 %to）
         * 得票最多时发送结果日志
         * 投票结束后标记自动清除
    
    6. 死亡隐藏：
       - 任何角色死亡后，身份不亮置
       - Log消息显示为"xxx（unknown）阵亡"
       - Rolebox身份图标保持彩色不变灰
       - 增加推理难度和游戏乐趣
    
    7. 移除击杀奖惩：
       - 触发时机：BuryVictim事件
       - 设置SkipNormalDeathProcess标记
       - 跳过正常的击杀奖惩流程
       - 击杀反贼不摸3张牌
       - 主公误杀忠臣不弃牌
       - 完全移除传统奖惩机制
    
    8. 移除正常胜利结算：
       - 触发时机：GameOverJudge事件（优先级3）
       - 设置SkipGameRule标记
       - 跳过正常的游戏结束判断
    
    9. 自定义胜利判定（新增）：
       - 触发时机：GameOverJudge事件（优先级2）
       - 统计存活角色的身份
       - 当没有反贼存活时，主公忠臣阵营获胜
       - 当没有主公和忠臣存活时，反贼阵营获胜
       - 使用room:gameOver()结束游戏
    
    【游戏流程】
    1. 游戏开始 → 初始身份分配（ZCCCFFF）
    2. GameReady事件 → HappyRebelInit触发
       - 随机打乱所有玩家的身份（包括主公）
       - 每个玩家只知道自己的身份
       - 每位玩家从5个随机武将中选择1个
       - 设置武将并初始化血量
    3. GameStart事件 → HappyRebelKnow触发
       - 反贼之间互相通知身份
       - 主公和忠臣仍然看不到其他人的身份
    4. 每轮流程：
       - 轮开始：主公查看身份（只有主公获得信息）
       - 轮开始：反贼投票（只有反贼的票计数，得票最多的-2体力）
       - 玩家1回合 → 玩家2回合 → ... → 玩家7回合
       - 轮结束：全员公投（所有人的票计数，得票最多的-2体力）
    5. 角色死亡 → 身份不亮置
    
    【游戏特色】
    - 完全随机身份：主公可能是任何一个玩家
    - 势力均衡：3反贼 vs 1主公3忠臣
    - 反贼之间知道队友，可以默契配合
    - 每轮双重投票机制：
      * 轮开始：反贼秘密投票（隐藏身份，反贼之间可见标记）
      * 轮结束：全员公开投票（所有人参与，完全透明）
    - 主公每轮可查看一人身份，逐步获取信息
    - 主公和忠臣不知道彼此，需要通过行为判断敌友
    - 死亡不亮身份增加了推理难度和不确定性
    - 身份分配后选将，避免针对性选将
    - 高度信息不对称与投票博弈相结合
    - 每轮最多可造成4点伤害（反贼投票2点+公投2点）
    - 移除击杀奖惩：击杀不再获得摸牌奖励，主公误杀不弃牌
    - 自定义胜利条件：基于阵营存活情况判定胜负
    
    【胜利条件】（自定义）
    - 主公忠臣阵营：存活角色中没有反贼时获胜
    - 反贼阵营：存活角色中没有主公和忠臣时获胜
    
    【注意事项】
    - 反贼互知是游戏开始时自动生效的
    - 主公查看身份后AI会重置，策略会调整
    - 投票时如果多人并列最高票，无事发生
    - 查看身份可以取消，但投票不能取消
    - 角色死亡后身份不会公开，需要通过推理判断
    - 移除击杀奖惩：击杀任何人都不获得奖励，也无惩罚
    - 自定义胜利判断：
      * 没有反贼存活 → 主公忠臣阵营获胜
      * 没有主公忠臣存活 → 反贼阵营获胜
    
    【安装方法】
    1. 将此文件放入 newsgs/extensions/ 目录
    2. 确保C++代码已编译（死亡隐藏功能需要）
    3. 重启游戏
    4. 在服务器设置中选择"欢乐反贼模式"
    
    【调试】
    - 控制台会输出模式初始化信息
    - 控制台会输出每位玩家的真实身份（仅服务器可见）
    - 控制台会输出每位玩家的选将信息
    - 控制台会输出反贼互知信息
    - 控制台会输出死亡隐藏信息
    - 如有问题请查看控制台日志
    
    【技术实现】
    技能触发顺序：
    1. GameReady → HappyRebelInit
       - 广播所有人为unknown（清除主公公开）
       - 随机打乱所有身份（Fisher-Yates算法）
       - 让每位玩家选将（5选1）
       - 设置武将和血量
    2. GameStart → HappyRebelKnow
       - 使用notifyProperty让反贼互相知道身份
       - 主公和忠臣仍看到unknown
       - 重置所有AI
    3. RoundStart（每轮开始）→ HappyRebelLordCheck
       - 使用轮数标记防止重复执行
       - 所有玩家依次选人（但只有主公获得信息）
       - 使用notifyProperty让主公知道目标身份
       - 重置所有AI
    4. RoundStart（每轮开始）→ HappyRebelVote
       - 使用轮数标记防止重复执行
       - 所有玩家依次投票（但只有反贼的票计数）
       - 使用addPlayerMark给目标添加&rebel_vote标记（只有反贼可见）
       - 统计反贼的票数，得票最多的失去2点体力
       - 投票结束后清除所有标记
    5. RoundEnd（每轮结束）→ HappyRebelPublicVote
       - 使用轮数标记防止重复执行
       - 所有玩家依次投票（所有人的票都计数）
       - 使用addPlayerMark给目标添加&public_vote标记（所有人可见）
       - 使用sendLog发送投票日志和结果日志
       - 统计票数，得票最多的失去2点体力
       - 投票结束后清除所有标记
    6. BeforeGameOverJudge → HappyRebelHideDeath
       - 设置HideDeathIcon属性
       - 身份不亮置
    7. BuryVictim → HappyRebelSkipReward
       - 设置SkipNormalDeathProcess标记
       - 跳过正常击杀奖惩
    8. GameOverJudge（优先级3）→ HappyRebelSkipNormalWin
       - 设置SkipGameRule标记
       - 跳过正常游戏结束判断
    9. GameOverJudge（优先级2）→ HappyRebelCustomWin
       - 统计存活身份
       - 判断自定义胜利条件
       - 调用room:gameOver()结束游戏
    
    【关键机制】
    - showRole = false：确保身份默认隐藏
    - 身份随机：所有玩家（包括主公）都参与随机
    - notifyProperty：选择性通知身份（反贼互知、主公查看）
    - HideDeathIcon：死亡后身份不暴露
    - 主公查看技能：每个人都选人，但只有主公获得结果（隐藏主公身份）
    - 反贼投票技能：每个人都投票，但只有反贼的票计数（隐藏反贼身份）
      * 使用&rebel_vote标记（只有反贼可见）
      * 反贼之间可以看到彼此的投票
    - 全员公投技能：每个人都投票，所有人的票都计数（公开投票机制）
      * 使用&public_vote标记（所有人可见）
      * 发送日志信息，完全透明
    - 防重复机制：使用轮数标记防止RoundStart/RoundEnd事件重复触发
    - 标记机制：参考shenzhouyu的yeyan技能，使用addPlayerMark的only_viewers参数
    - 移除击杀奖惩：设置SkipNormalDeathProcess（参考Shijia模式）
    - 移除正常胜利：设置SkipGameRule（参考Shijia模式）
    - 自定义胜利判定：统计存活身份阵营判定胜负
    
    【每轮流程】
    轮开始 → 主公查看身份 → 反贼投票 → 7个玩家依次回合 → 轮结束 → 全员公投
]]--

