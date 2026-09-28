-- Source: TODO/HUMAN/extensions/jiangshi.lua; V2 room/scenario lifecycle port.
-- 僵尸模式扩展包
-- 提供8人和16人僵尸模式

extension = sgs.Package("jiangshi", sgs.Package_GeneralPack)

-- 辅助函数：判断一个玩家是否为僵尸（包括僵尸和女僵尸）
local function isZombie(player)
    if not player then return false end
    local general = player:getGeneralName()
    local general2 = player:getGeneral2Name()
    return general == "zb_zombie" or general == "zb_female_zombie" 
        or general2 == "zb_zombie" or general2 == "zb_female_zombie"
end

-- 创建僵尸模式组（8人和16人）
-- 注意：初始配置为1主公+7忠臣（8人）或1主公+15忠臣（16人）
-- 游戏第二轮会有2名忠臣变成反贼僵尸
createMode{
    name = "僵尸模式-改",
    class = "jiangshi",
    roles = {
        "ZCCCCCCC",           -- 8人局：1主公 + 7忠臣（游戏开始后2名变僵尸）
        "ZCCCCCCCCCCCCCCC"    -- 16人局：1主公 + 15忠臣（游戏开始后2名变僵尸）
    },
    names = {"僵尸模式-8人", "僵尸模式-16人"},
    skipChooseGeneral = false,  -- 允许选将
    showRole = true,            -- 显示身份
}

-- Exact IDs match createMode's role-count IDs; donor's group label mismatched its registration.
local function jiangshiMode(room)
    return room:getMode() == "08_jiangshi" or room:getMode() == "16_jiangshi"
end

JiangshiSkipNormalDeath = sgs.CreateRuleSkillV2{
    name = "JiangshiSkipNormalDeath", priority = 10,
    events = {sgs.BuryVictim, sgs.GameStart},
    on_record = function(self, event, room, player, ctx)
        if not jiangshiMode(room) then return end
        if event == sgs.BuryVictim then
            room:setTag("SkipNormalDeathProcess", sgs.QVariant(true))
        elseif not room:getTag("JiangshiInitialized"):toBool() then
            room:setTag("JiangshiInitialized", sgs.QVariant(true))
            room:setTag("JiangshiZombiesSelected", sgs.QVariant(false))
        end
    end,
}
addToSkills(JiangshiSkipNormalDeath)

JiangshiModeRule = sgs.CreateRuleSkillV2{
    name = "#JiangshiModeRule", events = {sgs.EventPhaseStart}, priority = 5,
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not jiangshiMode(room) then return end
        if player and player:isAlive() and player:getPhase() == sgs.Player_RoundStart then
            return self:objectName(), player
        end
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
            -- 主公的逻辑
            if player:isLord() then
                player:gainMark("@round")
                
                -- 检查是否达到8枚退治标记（>7）
                if player:getMark("@round") > 7 then
                    local log = sgs.LogMessage()
                    log.type = "#survive_victory"
                    log.from = player
                    room:sendLog(log)
                    room:gameOver("lord+loyalist")
                    
                -- 第二轮开始时标记2名玩家（只执行一次）
                elseif room:getTag("TurnLengthCount"):toInt() == 2 then
                    -- 检查是否已经选过僵尸
                    local zombiesSelected = room:getTag("JiangshiZombiesSelected"):toBool()
                    if not zombiesSelected then
                        local players = room:getOtherPlayers(room:getLord())
                        -- 转换为Lua table进行打乱
                        local temp_list = {}
                        for _, p in sgs.qlist(players) do
                            table.insert(temp_list, p)
                        end
                        
                        -- 随机打乱（Fisher-Yates算法）
                        for i = #temp_list, 2, -1 do
                            local j = math.random(1, i)
                            temp_list[i], temp_list[j] = temp_list[j], temp_list[i]
                        end
                        
                        -- 标记前2名玩家
                        if #temp_list >= 2 then
                            temp_list[1]:setTag("zombie", sgs.QVariant(true))
                            temp_list[2]:setTag("zombie", sgs.QVariant(true))
                        end
                        
                        -- 设置标记，表示已经选过僵尸
                        room:setTag("JiangshiZombiesSelected", sgs.QVariant(true))
                    end
                end
                
            -- 非主公玩家的逻辑：检查是否有僵尸标记
            elseif player:getTag("zombie"):toBool() then
                -- 保存CurrentPlayer标记状态
                local hadCurrentFlag = player:hasFlag("CurrentPlayer")
                
                player:bury()
                room:killPlayer(player)
                
                -- 根据性别变成对应的僵尸
                local zombieGeneral = player:isMale() and "zb_zombie" or "zb_female_zombie"
                room:changeHero(player, zombieGeneral, false, false, true, false)
                room:setPlayerProperty(player, "maxhp", sgs.QVariant(5))
                room:setPlayerProperty(player, "hp", sgs.QVariant(5))
                room:setPlayerProperty(player, "role", sgs.QVariant("rebel"))
                
                -- 恢复CurrentPlayer标记（如果之前有的话）
                if hadCurrentFlag then
                    player:setFlags("CurrentPlayer")
                end
                
                local log = sgs.LogMessage()
                log.type = "#Zombify"
                log.from = player
                room:sendLog(log)
                
                room:updateStateItem()
                player:removeTag("zombie")
                
                room:revivePlayer(player)
                player:drawCards(5, "ZombieRule")
                room:getThread():delay()
                
                -- 重置所有玩家的AI（因为阵营关系改变）
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    room:resetAI(p)
                end
            end
            
            -- 检查游戏结束条件（gameOverJudge）
            local hasZombie = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if isZombie(p) then
                    hasZombie = true
                    break
                end
            end
            if not hasZombie then
                local turn_count = room:getTag("TurnLengthCount"):toInt()
                if turn_count > 2 then
                    room:gameOver("lord+loyalist")
                end
            end
            
        return false
    end,
}
addToSkills(JiangshiModeRule)

JiangshiDeathRule = sgs.CreateRuleSkillV2{
    name = "#JiangshiDeathRule", events = {sgs.Death, sgs.BuryVictim}, priority = 5,
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not jiangshiMode(room) then return end
        local death = data:toDeath()
        if not death or not death.who or death.who:isAlive() then return end
        if event == sgs.Death then
            -- BuryVictim is followed by unconditional skill detachment in the current core.
            -- Infection revives at Death's existing alive-return boundary instead.
            if not player or player:objectName() ~= death.who:objectName() then return end
            local killer = death.damage and death.damage.from
            local role = death.who:getRole()
            if not killer or (role ~= "lord" and role ~= "loyalist") then return end
            if killer:getRole() ~= "rebel" and killer:getRole() ~= "renegade" then return end
        end
        return self:objectName(), death.who
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
        player = ctx.owner -- The victim remains the decision maker on both death paths.
            -- 处理玩家死亡
            local death = data:toDeath()
            local damage = death.damage
            -- Burial clears marks/flags; preserve only the donor facts needed for succession/revival.
            local victimRoundMarks = player:getMark("@round")
            local victimHadCurrentFlag = player:hasFlag("CurrentPlayer")
            local victimZombieGeneral = player:isMale() and "zb_zombie" or "zb_female_zombie"
            -- Infection must bury before reviving at Death's native alive-return boundary.
            -- Ordinary BuryVictim keeps GameRule's original burial order and other skills.
            if event == sgs.Death then player:bury() end
            
            -- 调试输出
            room:writeToConsole("[jiangshi.lua::BuryVictim] 玩家死亡: " .. player:objectName())
            
            -- 检查是否有人类存活
            local hasHuman = false
            if player:isLord() then
                -- 主公死亡，寻找忠臣继承
                for _, p in sgs.qlist(room:getAlivePlayers()) do
                    if p:getRole() == "loyalist" then
                        room:setPlayerProperty(player, "role", sgs.QVariant("loyalist"))
                        room:setPlayerProperty(p, "role", sgs.QVariant("lord"))
                        room:setPlayerProperty(p, "maxhp", sgs.QVariant(p:getMaxHp() + 1))
                        
                        local recover = sgs.RecoverStruct()
                        recover.who = p
                        recover.recover = 1
                        recover.reason = "ZombieRule"
                        room:recover(p, recover)
                        
                        local round_marks = victimRoundMarks
                        if round_marks > 1 then
                            p:gainMark("@round", round_marks - 1)
                        else
                            p:gainMark("@round")
                        end
                        hasHuman = true
                        break
                    end
                end
            else
                hasHuman = true
            end
            
            -- 处理杀手奖励/感染
            if damage and damage.from then
                local killer = damage.from
                
                -- 通过身份判断是否为僵尸（因为死亡时副将可能已被移除）
                -- 僵尸的身份是 rebel（第二轮转化）或 renegade（被感染）
                local playerIsZombie = (player:getRole() == "rebel" or player:getRole() == "renegade")
                local killerIsZombie = (killer:getRole() == "rebel" or killer:getRole() == "renegade")
                
                -- 调试输出
                room:writeToConsole("[jiangshi.lua::BuryVictim] 死者: " .. player:objectName() .. "/" .. player:getGeneralName() .. "/" .. player:getGeneral2Name() .. ", role=" .. player:getRole() .. ", isZombie=" .. tostring(playerIsZombie))
                room:writeToConsole("[jiangshi.lua::BuryVictim] 杀手: " .. killer:objectName() .. "/" .. killer:getGeneralName() .. "/" .. killer:getGeneral2Name() .. ", role=" .. killer:getRole() .. ", isZombie=" .. tostring(killerIsZombie))
                
                if playerIsZombie and killerIsZombie then
                    -- 僵尸杀死僵尸 - 杀手摸3张牌（死者不复活）
                    room:writeToConsole("[jiangshi.lua::BuryVictim] 僵尸杀僵尸 - 杀手摸3张牌")
                    killer:drawCards(3, "ZombieRule")
                    
                elseif playerIsZombie and not killerIsZombie then
                    -- 人类杀死僵尸 - 杀手回复所有体力
                    room:writeToConsole("[jiangshi.lua::BuryVictim] 人类杀僵尸 - 杀手回复所有体力")
                    local lostHp = killer:getLostHp()
                    room:writeToConsole("[jiangshi.lua::BuryVictim] 杀手失去的体力: " .. tostring(lostHp))
                    if lostHp > 0 then
                        local recover = sgs.RecoverStruct()
                        recover.who = killer
                        recover.recover = lostHp
                        room:recover(killer, recover)
                    end
                    
                    -- 如果杀的是内奸僵尸额外摸3张牌
                    if player:getRole() == "renegade" then
                        room:writeToConsole("[jiangshi.lua::BuryVictim] 杀的是内奸僵尸，额外摸3张牌")
                        killer:drawCards(3, "ZombieRule")
                    end
                    
                elseif not playerIsZombie and killerIsZombie then
                    -- 僵尸杀死人类 - 人类被感染变成僵尸复活
                    room:writeToConsole("[jiangshi.lua::BuryVictim] 僵尸杀人类 - 人类被感染复活")
                    
                    -- 保存CurrentPlayer标记状态
                    local hadCurrentFlag = victimHadCurrentFlag
                    
                    -- 根据性别变成对应的僵尸
                    local zombieGeneral = victimZombieGeneral
                    room:changeHero(player, zombieGeneral, false, false, true, false)
                    
                    local maxhp = math.floor((killer:getMaxHp() + 1) / 2)
                    room:setPlayerProperty(player, "maxhp", sgs.QVariant(maxhp))
                    room:setPlayerProperty(player, "hp", sgs.QVariant(maxhp))
                    room:setPlayerProperty(player, "role", sgs.QVariant("renegade"))
                    
                    -- 恢复CurrentPlayer标记（如果之前有的话）
                    if hadCurrentFlag then
                        player:setFlags("CurrentPlayer")
                    end
                    
                    local log = sgs.LogMessage()
                    log.type = "#Zombify"
                    log.from = player
                    room:sendLog(log)
                    
                    room:updateStateItem()
                    room:revivePlayer(player)
                    room:setPlayerProperty(killer, "role", sgs.QVariant("rebel"))
                    
                    -- 重置所有玩家的AI（因为阵营关系改变）
                    for _, p in sgs.qlist(room:getAlivePlayers()) do
                        room:resetAI(p)
                    end
                else
                    -- 人类杀死人类 - 无效果
                    room:writeToConsole("[jiangshi.lua::BuryVictim] 人类杀人类 - 无效果")
                end
            end
            
            -- 检查游戏是否结束
            if not hasHuman then
                room:gameOver("rebel")
            end
            
        -- Death infection exits through the core's existing isAlive boundary.
        -- Ordinary burial continues; SkipNormalDeathProcess suppresses only native rewards.
        return false
    end,
}
addToSkills(JiangshiDeathRule)

JiangshiWinRule = sgs.CreateRuleSkillV2{
    name = "#JiangshiWinRule", events = {sgs.GameOverJudge}, priority = 5,
    frequency = sgs.Skill_Compulsory,
    can_trigger = function(self, event, room, player, data)
        if not jiangshiMode(room) then return end
        return self:objectName(), player or room:getAllPlayers(true):first()
    end,
    on_effect = function(self, event, room, player, ctx)
        local data = ctx.original_data
            -- 检查是否还有僵尸存活
            local hasZombie = false
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if isZombie(p) then
                    hasZombie = true
                    break
                end
            end
            
            -- 如果没有僵尸且回合数>2，人类胜利
            if not hasZombie then
                local turn_count = room:getTag("TurnLengthCount"):toInt()
                if turn_count > 2 then
                    room:gameOver("lord+loyalist")
                end
            end
            
        return true -- Suppress the ordinary identity-mode winner check.
    end,
}
addToSkills(JiangshiWinRule)

-- 加载翻译表
sgs.LoadTranslationTable{
    ["jiangshi"] = "僵尸模式",
    ["僵尸模式-8人"] = "僵尸模式-8人",
    ["僵尸模式-16人"] = "僵尸模式-16人",
    ["#JiangshiDeathRule"] = "僵尸模式：死亡结算",
    ["#JiangshiWinRule"] = "僵尸模式：胜负判定",
    ["#JiangshiModeRule"] = "僵尸模式规则",
    ["#survive_victory"] = "%from 获得了8枚退治标记，人类获得胜利！",
    ["#Zombify"] = "%from 变成了僵尸！",
}

return extension
