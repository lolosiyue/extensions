extension = sgs.Package("zhenghuoCMT")

sgs.LoadTranslationTable{
	["zhenghuoCMT"] = "整活包"
}

guanyuZHCMT = sgs.General(extension, "guanyuZHCMT", "shu", 4, true)

shenjiZHCMTCard = sgs.CreateSkillCard{
	name = "shenjiZHCMTCard",
	target_fixed = false,
    filter = function(self, targets, to_select)
        return #targets == 0 and (sgs.Slash_IsAvailable(sgs.Self) or sgs.Self:hasSkill("binuZHCMT"))
    end,
	on_use = function(self, room, source, targets)
    		local skill_list = {}
    		for _,skill in sgs.qlist(targets[1]:getVisibleSkillList()) do
        		if (not table.contains(skill_list,skill:objectName())) and not skill:isAttachedLordSkill() then
    				table.insert(skill_list,skill:objectName())
    			end
    		end
    		local skill_qc = ""
	    	if (#skill_list > 0) then
	    		skill_qc = room:askForChoice(source, "shenjiZHCMT", table.concat(skill_list,"+"))
	    	end
	    	if (skill_qc ~= "") then
	    		room:detachSkillFromPlayer(targets[1], skill_qc)
                local slash = sgs.Sanguosha:cloneCard("slash")
                slash:setSkillName("shenjiZHCMT")
                local person2 = room:askForPlayerChosen(source, room:getOtherPlayers(source), "shenjiZHCMT", "shenjiZHCMT-ask2", false, true)
                room:useCard(sgs.CardUseStruct(slash, source, person2))
	    	end
    end
}

shenjiZHCMT = sgs.CreateViewAsSkill{
	name = "shenjiZHCMT",
	n = 1,
    frequency = sgs.Skill_Compulsory,
	view_filter = function(self, selected, to_select)
		return #selected == 0 or #selected == 1
	end,
	view_as = function(self, cards)
        if #cards == 0 then
            return shenjiZHCMTCard:clone()
        elseif #cards == 1 and sgs.Slash_IsAvailable(sgs.Self) then
			local slash = sgs.Sanguosha:cloneCard("slash", cards[1]:getSuit(), cards[1]:getNumber())
			slash:addSubcard(cards[1])
			slash:setSkillName(self:objectName())
		    return slash
		else
			return nil
		end

	end,
    enabled_at_play = function(self, player)
        return player:hasSkill("shenjiZHCMT")

    end,
    enabled_at_response = function(self, player, pattern)
        return pattern == "slash"
    end,
}

shenjiZHCMTCH = sgs.CreateTriggerSkill{
    name = "#shenjiZHCMTCH",
    events = {sgs.EventPhaseStart, sgs.EventLoseSkill},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if not player:hasSkill("shenjiZHCMT") and player:getPhase() ~= sgs.Player_Play then
            room:acquireSkill(player, "shenjiZHCMT")
        end
    end,
	can_trigger = function(self, target)
		return target:hasSkill(self:objectName())
	end
}

guanyuZHCMT:addSkill(shenjiZHCMT)
guanyuZHCMT:addSkill(shenjiZHCMTCH)

binuZHCMT = sgs.CreateTargetModSkill{
	name = "binuZHCMT",
	pattern = "^SkillCard",
	residue_func = function(self,from,card)--额外使用
		if from:hasSkill("binuZHCMT") and card:isVirtualCard() and card:getSuit() == ""
		then return 1000 end
	end,
	distance_limit_func = function(self,from,card,to)--使用距离
		if from:hasSkill("binuZHCMT") and card:isVirtualCard() and card:getSuit() == ""
		then return 1000 end
	end,
	extra_target_func = function(self,from,card)--目标数
	end
}
binuZHCMTBJ = sgs.CreateTriggerSkill{
    name = "#binuZHCMTBJ",
    events = {sgs.TargetConfirmed},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.card:isVirtualCard() and use.card:getSuit() == "" then
            use.m_addHistory = false
            data:setValue(use)
        end
        return false
    end,
	can_trigger = function(self, target)
		return target:hasSkill("binuZHCMT")
	end
}
guanyuZHCMT:addSkill(binuZHCMT)
guanyuZHCMT:addSkill(binuZHCMTBJ)

sgs.LoadTranslationTable{
    ["guanyuZHCMT"] = "关羽",
    ["~guanyuZHCMT"] = "恭喜发财，好运常来……",
    ["#guanyuZHCMT"] = "威震华夏",
    ["shenjiZHCMT"] = "神技",
    [":shenjiZHCMT"] = "<b>持恒技，</b>你可以将一张牌或一名角色的一个技能当【杀】使用或打出。",
    ["shenjizhcmt"] = "神技",
    ["$shenjiZHCMT1"] = "福禄双全，春风得意，今许鸿运第一流。",
    ["$shenjiZHCMT2"] = "纳财赠祥瑞，沐桃园春风，享人间太平。",
    ["shenjiZHCMT-ask"] = "请选择一名角色",
    ["shenjiZHCMT-ask2"] = "请选择【杀】的目标",
    ["binuZHCMT"] = "必弩",
    [":binuZHCMT"] = "锁定技，你使用虚拟牌不计次数且无次数和距离限制。",
    ["designer:guanyuZHCMT"] = "癫瘋天花板",
}

machaoZHCMT = sgs.General(extension, "machaoZHCMT", "qun", 4, true)

zhuiluZHCMTCard = sgs.CreateSkillCard{
    name = "zhuiluZHCMTCard",
    filter = function(self, targets, to_select)
		return #targets == 0 and (to_select:hasSkill("mashu") or to_select:getMark("&mashu") > 0)
	end,
    on_use = function(self, room, source, targets)
        if targets[1]:getMark("&mashu") == 0 then
            room:detachSkillFromPlayer(targets[1], "mashu")
        else
            room:addPlayerMark(targets[1], "&mashu", -1)
        end
        room:setPlayerMark(source, "zhuiluZHCMT", 1)
    end,
}

zhuiluZHCMTVS = sgs.CreateViewAsSkill{
    name = "zhuiluZHCMT",
    n = 0,
    view_filter = function(self, selected, to_select)
        return #selected == 0
    end,
    view_as = function(self, cards)
        if #cards == 0 and sgs.Self:getMark("zhuiluZHCMT")==0 then
            return zhuiluZHCMTCard:clone()
        elseif #cards == 0 and sgs.Self:getMark("zhuiluZHCMT")==1 then
            local slash = sgs.Sanguosha:cloneCard("slash")
            slash:setSkillName(self:objectName())
            return slash
        else
            return nil
        end
    end,
    enabled_at_play = function(self, player)
        return sgs.Slash_IsAvailable(player)
    end,
}
zhuiluZHCMT = sgs.CreateTriggerSkill{
    name = "zhuiluZHCMT",
    events = {sgs.TargetConfirmed},
    view_as_skill = zhuiluZHCMTVS,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        if use.from:hasSkill("zhuiluZHCMT") and use.card:isKindOf("Slash") then
            room:setPlayerMark(player, "zhuiluZHCMT", 0)
            for _, p in sgs.qlist(use.to) do
                local skill_list = {}
    		    for _,skill in sgs.qlist(p:getVisibleSkillList()) do
        	    	if (not table.contains(skill_list,skill:objectName())) and not skill:isAttachedLordSkill() then
    		    		table.insert(skill_list,skill:objectName())
    		    	end
    		    end
    		    local skill_qc = ""
	    	    if (#skill_list > 0) then
	    	    	skill_qc = room:askForChoice(player, "zhuiluZHCMT", table.concat(skill_list,"+"))
	    	    end
	    	    if (skill_qc ~= "") then
	    	    	room:detachSkillFromPlayer(p, skill_qc)
                    room:broadcastSkillInvoke("zhuiluZHCMT")
                    room:sendCompulsoryTriggerLog(player, "zhuiluZHCMT")
                    if p:hasSkill("mashu") then
                        room:addPlayerMark(p, "&mashu", 1)
                    else
                        room:acquireSkill(p, "mashu")
                    end
	    	    end
            end
        end
    end,
    can_trigger = function(self, target)
		return target:hasSkill("zhuiluZHCMT")
	end,
}
ZHCMTMashu = sgs.CreateDistanceSkill{
	name = "#ZHCMTMashu",
	correct_func = function(self, from)
		if from:getMark("&mashu") > 0 then
			return from:getMark("&mashu")
		else
			return 0
		end
	end,
}
machaoZHCMT:addSkill(ZHCMTMashu)
machaoZHCMT:addSkill(zhuiluZHCMT)

xuechouZHCMT = sgs.CreateTriggerSkill{
    name = "xuechouZHCMT",
    events = {sgs.DamageCaused, sgs.Damage},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if event == sgs.DamageCaused and damage.card:isKindOf("Slash") and (damage.to:hasSkill("mashu") or damage.to:getMark("&mashu") > 0) and player:askForSkillInvoke(self:objectName()) then
            room:broadcastSkillInvoke("xuechouZHCMT")
            room:sendCompulsoryTriggerLog(player, "xuechouZHCMT")
            room:detachSkillFromPlayer(damage.to, "mashu")
            room:setPlayerMark(damage.to, "&mashu", 0)
            damage.damage = damage.damage + 1
            data:setValue(damage)
            room:setPlayerFlag(damage.to, "xuechouZHCMT")
        end
        if event == sgs.Damage and damage.to:hasFlag("xuechouZHCMT") then
            room:setPlayerMark(damage.to, "xuechouZHCMT", damage.to:getHp())
            damage.to:setProperty("yinniGeneral", ToData(damage.to:getGeneralName()))
            room:changeHero(damage.to, "yinni_hide", false, true, false, false)
            room:setPlayerFlag(damage.to, "-xuechouZHCMT")
        end
    end,
    can_trigger = function(self, target)
		return target:hasSkill("xuechouZHCMT")
	end,
}
xuechouZHCMT_list = sgs.CreateTriggerSkill{
	name = "#xuechouZHCMT_list",
	events = {sgs.EventPhaseStart, sgs.HpChanged},
    priority = -1,
	frequency = sgs.Skill_Compulsory,
	can_trigger = function(self, target)
		return target and target:isAlive()
	end,
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		if player:getMark("xuechouZHCMT") > 0 and event == sgs.EventPhaseStart then
            room:setPlayerProperty(player, "hp", sgs.QVariant(player:getMark("xuechouZHCMT")))
            room:setPlayerMark(player, "xuechouZHCMT", 0)
        elseif player:getMark("xuechouZHCMT") > 0 and event == sgs.HpChanged and player:getPhase() == sgs.Player_NotActive then
            local x = player:getMark("xuechouZHCMT")
            room:setPlayerMark(player, "xuechouZHCMT", 0)
            room:setPlayerProperty(player, "hp", sgs.QVariant(x - 1))
        end
		return false
	end,
}
machaoZHCMT:addSkill(xuechouZHCMT_list)
machaoZHCMT:addSkill(xuechouZHCMT)
machaoZHCMT:addSkill("mashu")
sgs.LoadTranslationTable{
    ["machaoZHCMT"] = "马超",
    ["~machaoZHCMT"] = "血仇犹在，奈何青锋已残……",
    ["#machaoZHCMT"] = "巡狩八荒",
    ["zhuiluZHCMT"] = "追戮",
    ["zhuiluzhcmt"] = "追戮",
    [":zhuiluZHCMT"] = "你可将一名角色的<b>【马术】</b>当【杀】使用；你使用【杀】指定唯一目标后，可用<b>【马术】</b>覆盖其一个技能。",
    ["xuechouZHCMT"] = "血仇",
    [":xuechouZHCMT"] = "你使用【杀】对有<b>【马术】</b>的角色造成伤害时，可移除其武将牌上所有<b>【马术】</b>令此伤害+1然后其隐匿。",
    ["$zhuiluZHCMT1"] = "你们一个都别想跑！",
    ["$zhuiluZHCMT2"] = "誓要让手中银枪饱饮鲜血！",
    ["$xuechouZHCMT1"] = "父仇在胸，国恨在目，西凉马超，誓杀曹贼！",
    ["$xuechouZHCMT2"] = "不枭曹贼之首祀于父前，吾枉为人子。",
    ["designer:machaoZHCMT"] = "全险大运车",
    ["information:machaoZHCMT"] = "“敢这么和我说话，你马是批发的？”",
    ["illustrator:machaoZHCMT"] = "鬼画符"
}

caopiZHCMT = sgs.General(extension, "caopiZHCMT$", "wei", 5, true, false, false, 3)

zhanliangZHCMT = sgs.CreateTriggerSkill{
    name = "zhanliangZHCMT",
    frequency = sgs.Skill_Compulsory, -- 锁定技
    events = {sgs.RoundStart, sgs.HpRecover}, -- 监听阶段开始和回复体力事件

    on_trigger = function(self, event, player, data)
        local room = player:getRoom()

        -- 每轮开始时增加体力上限
        if event == sgs.RoundStart then
            room:broadcastSkillInvoke(self:objectName())
            room:sendCompulsoryTriggerLog(player, self:objectName())

            -- 如果还没有获得过"威重"技能
            if not player:hasSkill("weizhong") and not player:hasSkill("benghuai") then
                -- 获得"威重"技能
                room:handleAcquireDetachSkills(player, "weizhong")
            end
            -- 增加1点体力上限
            room:gainMaxHp(player, 1)
        end
        
        -- 当体力回满时
        if event == sgs.HpRecover then
            if player:getHp() == player:getMaxHp() then
                if not player:hasSkill("benghuai") then
                    room:sendCompulsoryTriggerLog(player, self:objectName())
                    
                    -- 失去"威重"技能
                    room:handleAcquireDetachSkills(player, "-weizhong")
                    
                    -- 获得"崩坏"技能
                    room:handleAcquireDetachSkills(player, "benghuai")
                end
            end
        end
    end,
    
    can_trigger = function(self, target)
        return target and target:hasSkill(self:objectName())
    end
}
caopiZHCMT:addSkill(zhanliangZHCMT)
function fuckYoka2(skill)
	local i, j
	i, j = string.find(skill:getDescription(), sgs.Sanguosha:translate("fuckyoka1"))
	if not i then return false end
	if i == 1 then return true end
	i, j = string.find(skill:getDescription(), sgs.Sanguosha:translate("fuckyoka2"))
	if not i then return false end
	if i == 1 then return true end
	i, j = string.find(skill:getDescription(), sgs.Sanguosha:translate("fuckyoka3"))
	if not i then return false end
	if i == 1 then return true end
end
sgs.LoadTranslationTable {
	["fuckyoka1"] = "锁定技",
	["fuckyoka2"] = "<(.-)><b>锁定技",
	["fuckyoka3"] = "<(.-)><b>(.-)</b></font><(.-)><b>锁定技",
}
zhenzuZHCMT = sgs.CreateTriggerSkill{
    name = "zhenzuZHCMT",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseStart},
    
    on_trigger = function(self, event, player, data)
        if player:getPhase() ~= sgs.Player_Play then return false end
        local room = player:getRoom()
        
        -- 询问是否发动议事
        if not player:askForSkillInvoke(self:objectName()) then return false end
        room:broadcastSkillInvoke(self:objectName())
        room:sendCompulsoryTriggerLog(player, self:objectName())
        -- 第一阶段：所有玩家选择意见牌
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not p:isKongcheng() then
                -- 让玩家选择一张手牌作为意见牌
                local id = room:askForExchange(p, "zhenzuZHCMT", 1, 1, false, "zhenzuZHCMT_yishi"):getSubcards():first()
                local card = sgs.Sanguosha:getCard(id)
                room:obtainCard(player, card, true)
                local use = room:askForUseCard(player, "#" .. id, "@zhenzuZHCMT-use")
                -- 标记牌的颜色
                if not use and card:isRed() then
                    room:setPlayerMark(p, "zhenzuZHCMT_red", 1)
                    room:obtainCard(p, card, true)
                elseif not use and card:isBlack() then
                    room:setPlayerMark(p, "zhenzuZHCMT_black", 1)
                    room:obtainCard(p, card, true)
                end
                
                -- 标记已选择的牌
                room:setCardFlag(card, "zhenzuZHCMT_opinion")
                room:setPlayerMark(p, "zhenzuZHCMT_chose", 1)
            end
        end
        
        -- 第二阶段：展示所有意见牌
        local red_count = 0
        local black_count = 0
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark("zhenzuZHCMT_chose") > 0 then
                -- 找到被标记的意见牌并展示
                for _, card in sgs.qlist(p:getHandcards()) do
                    if card:hasFlag("zhenzuZHCMT_opinion") then
                        room:showCard(p, card:getEffectiveId())
                        room:setCardFlag(card, "-zhenzuZHCMT_opinion")
                        
                        -- 统计颜色
                        if card:isRed() then
                            red_count = red_count + 1
                        elseif card:isBlack() then
                            black_count = black_count + 1
                        end
                        break
                    end
                end
            end
        end
        
        -- 延迟让玩家看清结果
        room:getThread():delay(1500)
        
        -- 宣布议事结果
        local result = 0  -- 0:平局, 1:红色多, 2:黑色多
        if red_count > black_count then
            result = 1
            local log = sgs.LogMessage()
            log.type = "#zhenzuZHCMTRedWin"
            log.from = player
            room:sendLog(log)
            room:doLightbox("$zhenzuZHCMT_red", 1000)
        elseif black_count > red_count then
            result = 2
            local log = sgs.LogMessage()
            log.type = "#zhenzuZHCMTBlackWin"
            log.from = player
            room:sendLog(log)
            room:doLightbox("$zhenzuZHCMT_black", 1000)
        else
            local log = sgs.LogMessage()
            log.type = "#zhenzuZHCMTTie"
            log.from = player
            room:sendLog(log)
            room:doLightbox("$zhenzuZHCMT_tie", 1000)
        end
        -- 清理标记
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if result == 1 and p:getMark("zhenzuZHCMT_red") > 0 then
                room:setPlayerMark(p, "&zhenzuZHCMT_no_recover", 1)
            end
            if result == 2 and p:getMark("zhenzuZHCMT_black") > 0 then
                room:setPlayerMark(p, "&zhenzuZHCMT_no_derivative", 1)
				room:setPlayerMark(p, "@skill_invalidity", 1)
                local lose_skills = p:getTag("zhenzuZHCMTSkills"):toString():split("+")
				local skills = p:getVisibleSkillList()
				for _, skill in sgs.qlist(skills) do
                    if not p:hasInnateSkill(skill) then
                    room:addPlayerMark(p, "Qingcheng"..skill:objectName())
                    -- 将技能名加入失效列表
                    table.insert(lose_skills, skill:objectName())
                    end
                end
                p:setTag("zhenzuZHCMTSkills", sgs.QVariant(table.concat(lose_skills, "+")))
            end
            room:setPlayerMark(p, "zhenzuZHCMT_participating", 0)
            room:setPlayerMark(p, "zhenzuZHCMT_red", 0)
            room:setPlayerMark(p, "zhenzuZHCMT_black", 0)
            room:setPlayerMark(p, "zhenzuZHCMT_chose", 0)
        end
        
        return false
    end
}

-- 添加对体力回复的限制
zhenzuZHCMT_global = sgs.CreateTriggerSkill{
    name = "#zhenzuZHCMT_global",
    events = {sgs.PreHpRecover},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        
        -- 阻止体力回复
        if event == sgs.PreHpRecover and player:getMark("&zhenzuZHCMT_no_recover") > 0 then
            local recover = data:toRecover()
            local log = sgs.LogMessage()
            log.type = "#zhenzuZHCMTBlockRecover"
            log.from = player
            log.arg = recover.recover
            room:sendLog(log)
            return true
        end
        return false
    end,
    
    can_trigger = function(self, target)
        return target and (target:getMark("&zhenzuZHCMT_no_recover") > 0 or target:getMark("&zhenzuZHCMT_no_derivative") > 0)
    end
}

-- 每轮结束时清除效果
zhenzuZHCMT_clear = sgs.CreateTriggerSkill{
    name = "#zhenzuZHCMT_clear",
    events = {sgs.RoundStart},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
            local room = player:getRoom()
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("&zhenzuZHCMT_no_recover") > 0 then
                    room:setPlayerMark(p, "&zhenzuZHCMT_no_recover", 0)
                end
                if p:getMark("&zhenzuZHCMT_no_derivative") > 0 then
                    room:setPlayerMark(p, "&zhenzuZHCMT_no_derivative", 0)
                    room:setPlayerMark(p, "@skill_invalidity", 0)
				    -- for skills
				    local lose_skills = p:getTag("zhenzuZHCMTSkills"):toString():split("+")
				    for _, skill_name in ipairs(lose_skills) do
				    	room:removePlayerMark(p, "Qingcheng"..skill_name)
				    end
				    p:setTag("zhenzuZHCMTSkills", sgs.QVariant())
                end
            end
        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}
caopiZHCMT:addSkill(zhenzuZHCMT)
caopiZHCMT:addSkill(zhenzuZHCMT_global)
caopiZHCMT:addSkill(zhenzuZHCMT_clear)

weidaiZHCMT = sgs.CreateTriggerSkill{
    name = "weidaiZHCMT$",
    events = {sgs.CardUsed},
    change_skill = true,
    priority = {3, 2},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local use = data:toCardUse()
        local k = room:findPlayersBySkillName(self:objectName())
        if k:isEmpty() then return false end
        if use.card:isKindOf("Peach") then
            for _, p in sgs.qlist(k) do
                if p:isLord() then
                    local n = p:getChangeSkillState(self:objectName())
                    if n == 1 and not use.to:contains(p) and p:askForSkillInvoke(self:objectName(), data) then
                        room:setChangeSkillState(p, self:objectName(), 2)
                        use.to:append(p)
                        room:sortByActionOrder(use.to)
                        room:broadcastSkillInvoke(self:objectName(), 1)
                        room:sendCompulsoryTriggerLog(p, self:objectName())
                        data:setValue(use)
                    end
                end
            end
        elseif use.card:isKindOf("Slash") then
            for _, p in sgs.qlist(k) do
                if p:isLord() then
                    local n = p:getChangeSkillState(self:objectName())
                    if n == 2 and p:askForSkillInvoke(self:objectName(), data) then
                        -- 选择额外目标
                        local others = room:getOtherPlayers(use.from)
                        local non_wei_targets = sgs.SPlayerList()
                        for _, q in sgs.qlist(others) do
                            if q:getKingdom() ~= "wei" and not use.to:contains(q) and use.from:canSlash(q, use.card) then
                                non_wei_targets:append(q)
                            end
                        end
                        if not non_wei_targets:isEmpty() then
                            local extra = room:askForPlayerChosen(p, non_wei_targets, self:objectName(), "weidai-extra", true)
                            if extra then
                                room:setChangeSkillState(p, self:objectName(), 1)
                                use.to:append(extra)
                                room:sortByActionOrder(use.to)
                                room:broadcastSkillInvoke(self:objectName(), 2)
                                room:sendCompulsoryTriggerLog(p, self:objectName())
                                data:setValue(use)
                            end
                        end
                    end
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target:getKingdom() == "wei"
    end,
}
caopiZHCMT:addSkill(weidaiZHCMT)
caopiZHCMT:addRelateSkill("weizhong")
caopiZHCMT:addRelateSkill("benghuai")

sgs.LoadTranslationTable{
    ["#caopiZHCMT"] = "味闻帝",
    ["~caopiZHCMT"] = "子建，子建……",
    ["$weidaiZHCMT1"] = "仙福永享，寿与天齐！",
    ["$weidaiZHCMT2"] = "来，管杀还管埋。",
    ["$zhanliangZHCMT"] = "千秋万载，一统江山！",
    ["$zhenzuZHCMT"] = "我的是我的，你的还是我的。",
    ["caopiZHCMT"] = "曹丕",
    ["zhanliangZHCMT"] = "占梁",
    [":zhanliangZHCMT"] = "锁定技，每轮开始时，你增加1点体力上限。你拥有‘威重’直到你首次将体力值回满，然后你获得‘崩坏’。",
    ["weidaiZHCMT"] = "魏代",
    [":weidaiZHCMT"] = "主公技，转换技，①你可令魏势力角色非对自己使用的【桃】额外指定你为目标②你可为魏势力角色使用的【杀】额外指定一个非魏势力目标。",
    [":weidaiZHCMT1"] = "主公技，转换技，①你可令魏势力角色非对自己使用的【桃】额外指定你为目标<font color=\"#01A5AF\"><s>②你可为魏势力角色使用的【杀】额外指定一个非魏势力目标。</font></s>",
    [":weidaiZHCMT2"] = "主公技，转换技，<font color=\"#01A5AF\"><s>①你可令魏势力角色非对自己使用的【桃】额外指定你为目标</font></s>②你可为魏势力角色使用的【杀】额外指定一个非魏势力目标。",
    ["weidai-extra"] = "你可为魏势力角色使用的【杀】额外指定一个非魏势力目标。",
    ["zhenzuZHCMT"] = "甄族",
    [":zhenzuZHCMT"] = "出牌阶段开始时，你可全场议事，然后你可先使用任意张意见牌，这些牌不记入意见统计。①红色：此意见角色本轮的体力回复失效。②黑色：此意见角色本轮的衍生技失效。被你使用牌的角色不执行。",
    ["zhenzuZHCMT_yishi"] = "请选择一张牌来参与议事",
    ["@zhenzuZHCMT-use"] = "你可以使用此牌",
    ["#zhenzuZHCMTRedWin"] = "红色意见角色本轮的体力回复失效。",
    ["#zhenzuZHCMTBlackWin"] = "黑色意见角色本轮的衍生技失效。",
    ["#zhenzuZHCMTTie"] = "意见持平，没有任何效果。",
    ["$zhenzuZHCMT_red"] = "议事结果为红色",
    ["$zhenzuZHCMT_black"] = "议事结果为黑色",
    ["$zhenzuZHCMT_tie"] = "议事结果为平局",
    ["zhenzuZHCMT_no_recover"] = "体力回复失效",
    ["zhenzuZHCMT_no_derivative"] = "衍生技失效",
    ["#zhenzuZHCMTBlockRecover"] = "体力回复失效",
    ["designer:caopiZHCMT"] = "霸王是我孙伯符",
    ["illustrator:caopiZHCMT"] = "铁杵文化&豆包"

}

sunquanZHCMT = sgs.General(extension, "sunquanZHCMT$", "wu", 4, true)

XiansiZHCMTCard = sgs.CreateSkillCard{
	name = "XiansiZHCMTCard", 
	target_fixed = false,
	filter = function(self, targets, to_select) 
        if to_select:objectName() == sgs.Self:objectName() then return false end
		return #targets < 2 and not to_select:isNude()
	end,
	on_effect = function(self, effect) 
        effect.from:getRoom():broadcastSkillInvoke("XiansiZHCMT")
        effect.from:getRoom():sendCompulsoryTriggerLog(effect.from, "XiansiZHCMT")
		if effect.to:isNude() then return end
		local id = effect.from:getRoom():askForCardChosen(effect.from, effect.to, "he", "XiansiZHCMT")
		effect.from:addToPile("counter", id)
        effect.from:getRoom():acquireSkill(effect.to, "zhengsiZHCMT")
	end,
}

XiansiZHCMTVS = sgs.CreateZeroCardViewAsSkill{
	name = "XiansiZHCMT",
	view_as = function(self) 
		return XiansiZHCMTCard:clone()
	end,
    enabled_at_play = function(self, player)
        return not player:hasUsed("#XiansiZHCMTCard")
    end,
}

XiansiZHCMT = sgs.CreateTriggerSkill{
	name = "XiansiZHCMT",
	events = {sgs.TargetConfirming},
    view_as_skill = XiansiZHCMTVS,
	on_trigger = function(self, event, player, data)
        local room = player:getRoom()
		if player:getPile("counter"):length() == 0 and player:getMark("XiansiZHCMT") == 1 then
        room:setPlayerMark(player, "XiansiZHCMT",0)
                    -- 获取所有男性角色
        local males = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:hasSkill("zhengsiZHCMT") then
                room:detachSkillFromPlayer(p, "zhengsiZHCMT")
            end
            if p:isMale() then
                males:append(p)
            end
        end
        if males:isEmpty() then return false end

        -- 让玩家选择一名男性角色
        local male = room:askForPlayerChosen(player, males, self:objectName(), "@newyongdi-invoke", true, true)
        if not male then return false end

        -- 播放技能特效
        room:broadcastSkillInvoke("newyongdi")
        room:doSuperLightbox("second_new_sp_jiaxu", "newyongdi")

        -- 目标男性角色增加1点体力上限
        room:gainMaxHp(male, 1)
        local players = room:getAlivePlayers()
    
        -- 所有角色失去3点体力
        for _, p in sgs.qlist(players) do
            if p:isAlive() then
                room:loseHp(p, 3)  -- 直接失去体力
            end
        end

        -- 如果目标是主公，则直接返回
        if male:isLord() then return false end

        -- 获取目标未拥有的主公技
        local skills = {}
        for _, skill in sgs.qlist(male:getVisibleSkillList()) do
            if skill:isLordSkill() and not male:hasLordSkill(skill:objectName(), true) and not table.contains(skills, skill:objectName()) then
                table.insert(skills, skill:objectName())
            end
        end

        -- 检查副将（如果有）
        if male:getGeneral2() then
            for _, skill in sgs.qlist(male:getGeneral2():getVisibleSkillList()) do
                if skill:isLordSkill() and not male:hasLordSkill(skill:objectName(), true) and not table.contains(skills, skill:objectName()) then
                    table.insert(skills, skill:objectName())
                end
            end
        end

        -- 如果存在可获取的主公技，则赋予
        if #skills > 0 then
            room:handleAcquireDetachSkills(male, table.concat(skills, "|"))
        end

        return false
        end
    end
}

XiansiZHCMTAttach = sgs.CreateTriggerSkill{
	name = "#XiansiZHCMTAttach", 
	events = {sgs.GameStart,sgs.EventAcquireSkill,sgs.EventLoseSkill}, 
    priority = -1,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local source = room:findPlayerBySkillName("XiansiZHCMT")
		if event == sgs.GameStart then
			if (event == sgs.GameStart and source and source:isAlive()) or (event == sgs.EventAcquireSkill and data:toString() == "XiansiZHCMT") then
				for _,p in sgs.qlist(room:getOtherPlayers(source))do
					if not p:hasSkill("XiansiZHCMTSlash") then
						room:attachSkillToPlayer(p,"XiansiZHCMTSlash")
					end
				end
			end
		elseif event == sgs.EventLoseSkill and data:toString() == "XiansiZHCMT"then
			for _,p in sgs.qlist(room:getOtherPlayers(player))do
				if p:hasSkill("XiansiZHCMTSlash") then
					room:detachSkillFromPlayer(p, "XiansiZHCMTSlash")
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
	end,
}

XiansiZHCMTSlashCard = sgs.CreateSkillCard{
	name = "XiansiZHCMTSlashCard", 
	target_fixed = false,
	filter = function(self, targets, to_select) 
		return to_select:hasSkill("XiansiZHCMT") and to_select:getPile("counter"):length() >1 and sgs.Self:canSlash(to_select,nil)
	end,
	on_validate = function(self,carduse)
		local source = carduse.from
		local target = carduse.to:first()
		local room = source:getRoom()
		local dummy = sgs.Sanguosha:cloneCard("jink")
		if target:getPile("counter"):length() == 2 then
			dummy:addSubcard(target:getPile("counter"):first())
			dummy:addSubcard(target:getPile("counter"):last())
		else
			local ids = target:getPile("counter")
			for i = 0,1,1 do
				room:fillAG(ids, source);
				local id = room:askForAG(source, ids, false, "XiansiZHCMT");
				dummy:addSubcard(id);
				ids:removeOne(id);
				room:clearAG(source)
			end
		end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_REMOVE_FROM_PILE, "", "XiansiZHCMT", "");
		room:throwCard(dummy, reason, nil);
		if source:canSlash(target, nil, false) then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName("_xiansi")
            room:setPlayerMark(target, "XiansiZHCMT",1)
			return slash
		end
	end,
}
function canSlashLiufeng (player)
	local liufeng = nil;
	for _,p in sgs.qlist(player:getAliveSiblings()) do
		if (p:hasSkill("XiansiZHCMT") and p:getPile("counter"):length() > 1) then
			liufeng = p;
			break;
		end
	end
	if liufeng == nil then return false end
	local slash = sgs.Sanguosha:cloneCard("slash")
	return slash:targetFilter(sgs.PlayerList(), liufeng, player);
end

XiansiZHCMTSlash = sgs.CreateZeroCardViewAsSkill{
	name = "XiansiZHCMTSlash",
	view_as = function(self) 
		return XiansiZHCMTSlashCard:clone()
	end, 
	enabled_at_play = function(self, player)
		return sgs.Slash_IsAvailable(player) and canSlashLiufeng(player)
	end, 
	enabled_at_response = function(self, player, pattern)
		return  pattern == "slash"and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			   and canSlashLiufeng(player)
	end,
}
sunquanZHCMT:addSkill(XiansiZHCMT)
sunquanZHCMT:addSkill(XiansiZHCMTAttach)
sunquanZHCMT:addRelateSkill("newyongdi")
sunquanZHCMT:addRelateSkill("xiansi")

dangzhengZHCMTCard = sgs.CreateSkillCard{
	name = "dangzhengZHCMTCard",
	target_fixed = false,
	will_throw = false,
	handling_method = sgs.Card_MethodNone,
	filter = function(self, targets, to_select)
		return #targets == 0 and to_select:hasSkill("dangzhengZHCMT")
		   and to_select:objectName() ~= sgs.Self:objectName() and not to_select:hasFlag("dangzhengZHCMTInvoked")
	end,
	on_use = function(self, room, source, targets)
		local sq = targets[1]
		if sq:hasLordSkill("dangzhengZHCMT") then
			room:setPlayerFlag(sq, "dangzhengZHCMTInvoked")
			room:notifySkillInvoked(sq, "dangzhengZHCMT")
            local choice = room:askForChoice(source, "dangzhengZHCMT", "xiansi+newyongdi")
            if choice == "xiansi" then
                source:turnOver()
                room:broadcastSkillInvoke("xiansi")
        local t = room:askForPlayerChosen(sq, room:getOtherPlayers(sq), "xiansi")
        if t:isNude() then return end
		local id = room:askForCardChosen(sq, t, "he", "XiansiZHCMT")
        sq:addToPile("counter", id)
        local t2 = room:askForPlayerChosen(sq, room:getOtherPlayers(sq, t), "xiansi")
        if t2:isNude() then return end
		local id2 = room:askForCardChosen(sq, t2, "he", "XiansiZHCMT")
        sq:addToPile("counter", id2)
            elseif choice == "newyongdi" then
                source:turnOver()
        local males = sgs.SPlayerList()
        for _, p in sgs.qlist(room:getOtherPlayers(source)) do
            if p:isMale() then
                males:append(p)
            end
        end
        if males:isEmpty() then return false end

        -- 让玩家选择一名男性角色
        local male = room:askForPlayerChosen(source, males, self:objectName(), "@newyongdi-invoke", true, true)
        if not male then return false end

        -- 播放技能特效
        room:broadcastSkillInvoke("newyongdi")
        room:doSuperLightbox("second_new_sp_jiaxu", "newyongdi")

        -- 目标男性角色增加1点体力上限
        room:gainMaxHp(male, 1)
        -- 如果目标是主公，则直接返回
        if male:isLord() then return false end

        -- 获取目标未拥有的主公技
        local skills = {}
        for _, skill in sgs.qlist(male:getVisibleSkillList()) do
            if skill:isLordSkill() and not male:hasLordSkill(skill:objectName(), true) and not table.contains(skills, skill:objectName()) then
                table.insert(skills, skill:objectName())
            end
        end

        -- 检查副将（如果有）
        if male:getGeneral2() then
            for _, skill in sgs.qlist(male:getGeneral2():getVisibleSkillList()) do
                if skill:isLordSkill() and not male:hasLordSkill(skill:objectName(), true) and not table.contains(skills, skill:objectName()) then
                    table.insert(skills, skill:objectName())
                end
            end
        end

        -- 如果存在可获取的主公技，则赋予
        if #skills > 0 then
            room:handleAcquireDetachSkills(male, table.concat(skills, "|"))
        end

            end
			local sqs = room:getLieges("wu",sq)
			if sqs:isEmpty() then
				room:setPlayerFlag(source, "ForbiddangzhengZHCMT")
			end
		end
	end
}
dangzhengZHCMTVS = sgs.CreateZeroCardViewAsSkill{
	name = "dangzhengZHCMTVS",
	view_as = function(self, card)
		local acard = dangzhengZHCMTCard:clone()
		return acard
	end,
	enabled_at_play = function(self, player)
		if player:getKingdom() == "wu" then
			return not player:hasFlag("ForbiddangzhengZHCMT")
		end
		return false
	end
}
dangzhengZHCMT = sgs.CreateTriggerSkill{
	name = "dangzhengZHCMT$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart, sgs.EventPhaseChanging,sgs.EventAcquireSkill,sgs.EventLoseSkill},
	on_trigger = function(self, triggerEvent, player, data)
		local room = player:getRoom()
		local lords = room:findPlayersBySkillName(self:objectName())
		if player:isLord() and (triggerEvent == sgs.GameStart)or(triggerEvent == sgs.EventAcquireSkill and data:toString() == "dangzhengZHCMT") then 
			if lords:isEmpty() then return false end
			local players
			if lords:length() > 1 then
				players = room:getAlivePlayers()
			else
				players = room:getOtherPlayers(lords:first())
			end
			for _,p in sgs.qlist(players) do
				if not p:hasSkill("dangzhengZHCMTVS") then
					room:attachSkillToPlayer(p, "dangzhengZHCMTVS")
				end
			end
		elseif triggerEvent == sgs.EventLoseSkill and data:toString() == "dangzhengZHCMT" then
			if lords:length() > 2 then return false end
			local players
			if lords:isEmpty() then
				players = room:getAlivePlayers()
			else
				players:append(lords:first())
			end
			for _,p in sgs.qlist(players) do
				if p:hasSkill("dangzhengZHCMTVS") then
					room:detachSkillFromPlayer(p, "dangzhengZHCMTVS")
				end
			end
		elseif (triggerEvent == sgs.EventPhaseChanging) then
			local phase_change = data:toPhaseChange()
			if phase_change.from ~= sgs.Player_Play then return false end
			if player:hasFlag("ForbiddangzhengZHCMT") then
				room:setPlayerFlag(player, "-ForbiddangzhengZHCMT")
			end
			local players = room:getOtherPlayers(player);
			for _,p in sgs.qlist(players) do
				if p:hasFlag("dangzhengZHCMTInvoked") then
					room:setPlayerFlag(p, "-dangzhengZHCMTInvoked")
				end
			end
		end
		return false
	end,
}
zhengsiZHCMTCard = sgs.CreateSkillCard{
    name = "zhengsiZHCMTCard",
    target_fixed = false,
    will_throw = false,
    
    filter = function(self, targets, to_select, player)
        if #targets >= 2 then return false end
        return to_select:objectName() ~= player:objectName() and not to_select:isKongcheng()
    end,
    
    feasible = function(self, targets)
        return #targets == 2
    end,
    
    on_use = function(self, room, source, targets)
        room:broadcastSkillInvoke("zhengsiZHCMT")
        room:sendCompulsoryTriggerLog(source, "zhengsiZHCMT")
        local target_list = sgs.SPlayerList()
        for _, p in ipairs(targets) do
            target_list:append(p)
        end
    
        -- 2. 添加自己到目标列表
        target_list:append(source)
    
        -- 3. 让 source 选择一名玩家
        local first = room:askForPlayerChosen(source, target_list, "@zhengsiZHCMT")
        local card_id = room:askForCardChosen(first, first, "h", "zhengsiZHCMT")
        local card = sgs.Sanguosha:getCard(card_id)
        room:showCard(first, card_id)
        -- 记录点数
        local point = card:getNumber()
        local max_point = point
        local max_players = first
        
        -- 其他目标同时展示牌
        for _, p in sgs.qlist(target_list) do
            if p:objectName() ~= first:objectName() and not p:hasFlag("second") then
                local card_id2 = room:askForCardChosen(p, p, "h", "zhengsiZHCMT")
                local card2 = sgs.Sanguosha:getCard(card_id2)
                room:showCard(p, card_id2)
                local point2 = card2:getNumber()
                if point2 > max_point then
                    max_point = point2
                    max_players = {p}
                elseif point2 == max_point then
                    table.insert(max_players, p)
                end
                room:setPlayerFlag(p, "second")
            elseif p:objectName() ~= first:objectName() and not p:hasFlag("second") then
                local card_id3 = room:askForCardChosen(p, p, "h", "zhengsiZHCMT")
                local card3 = sgs.Sanguosha:getCard(card_id3)
                room:showCard(p, card_id3)
                local point3 = card3:getNumber()
                if point3 > max_point then
                    max_point = point3
                    max_players = {p}
                elseif point3 == max_point then
                    table.insert(max_players, p)
                end
            end
        end
            -- 处理结果
            for _, p in sgs.qlist(target_list) do
                if table.contains(max_players, p) then
                    room:askForDiscard(p, self:objectName(), 2, 2, false, true)
                else
                    room:loseHp(p, 1)
                end
            end
    end
}
zhengsiZHCMT = sgs.CreateViewAsSkill{
    name = "zhengsiZHCMT",
    n = 0,
    
    view_as = function(self, cards)
        return zhengsiZHCMTCard:clone()
    end,
    
    enabled_at_play = function(self, player)
        return player
    end
}
sunquanZHCMT:addSkill(dangzhengZHCMT)
sunquanZHCMT:addRelateSkill("zhengsiZHCMT")

sgs.LoadTranslationTable{
	["sunquanZHCMT"] = "孙权",
    ["~sunquanZHCMT"] = "时不待我，命不由人呐。",
    ["#sunquanZHCMT"] = "年迈昏君",
    ["XiansiZHCMT"] = "滞横",
    ["$XiansiZHCMT"] = "淡定，淡定。",
    ["XiansiZHCMTSlash"] = "陷嗣",
    [":XiansiZHCMTSlash"] = "你可以将其两张“逆”置入弃牌堆，视为对其使用一张【杀】（计入次数限制）。",
    ["xiansizhcmt"] = "滞横",
    [":XiansiZHCMT"] = "出牌阶段限一次，你可以对2名其他角色发动“陷嗣”，然后这些角色获得“争嗣”直至你没有“逆”。当你失去所有“逆”时，你发动“拥嫡”并令所有角色失去3点体力。",
    ["dangzhengZHCMT"] = "党争",
    ["dangzhengzhcmt"] = "党争",
    ["dangzhengZHCMTVS"] = "党争",
    ["dangzhengZHCMTCard"] = "党争",
    [":dangzhengZHCMT"] = "主公技，其他吴势力角色出牌阶段限一次，其可令你/其发动“陷嗣”/“拥嫡”并翻面。",
    [":dangzhengZHCMTVS"] = "主公技，吴势力角色出牌阶段限一次，你可令主公/你发动“陷嗣”/“拥嫡”并翻面。",
    ["zhengsiZHCMT"] = "争嗣",
    ["zhengsizhcmt"] = "争嗣",
    ["@zhengsiZHCMT"] = "选择争嗣先手",
    ["$zhengsiZHCMT"] = "比丧命更痛苦，比死亡更恐怖。",
    [":zhengsiZHCMT"] = "出牌阶段，你可以选择包含你在内三名有手牌的角色，令其中一名角色先展示一张手牌，其余角色再同时展示一张手牌：点数最大的角色弃置两张手牌；点数最小的角色失去1点体力。",
    ["illustrator:sunquanZHCMT"] = "瞌瞌一休",
    ["designer:sunquanZHCMT"] = "行游记",
}

liubeiZHCMT = sgs.General(extension, "liubeiZHCMT", "god", "6", true)

jieyingZHCMT = sgs.CreateTriggerSkill {
    name = "#jieyingZHCMT",
    events = {sgs.GameStart, sgs.Debut, sgs.Revived, sgs.EventAcquireSkill,sgs.ChainStateChange},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.GameStart or event == sgs.Debut or event == sgs.Revived or 
           (event == sgs.EventAcquireSkill and data:toString() == self:objectName()) then
            if player:isChained() then return false end
            room:setPlayerChained(player)
            room:broadcastSkillInvoke("jieying")
        elseif event == sgs.ChainStateChange then
            if not player:isChained() then return false end
            room:broadcastSkillInvoke("jieying")
            return true
        end
        return false
    end
}
liubeiZHCMT:addSkill(jieyingZHCMT)

longnuZHCMT = sgs.CreateTriggerSkill{
    name = "longnuZHCMT",
    events = {sgs.EventPhaseStart},
    change_skill = true,
    priority = {3, 2},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local n =player:getChangeSkillState(self:objectName())
        if player:getPhase() == sgs.Player_Start then
            player:drawCards(1)
            room:broadcastSkillInvoke("longnu")
            room:sendCompulsoryTriggerLog(player, "longnu")
            if n == 1 and player:getMark("longnuZHCMT") == 0 then
				room:changeHero(player, "guanyu", false, true, true, false)
                room:setChangeSkillState(player, self:objectName(), 2)
                room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() - 1))
            elseif n == 2 and player:getMark("longnuZHCMT") == 0 then
				room:changeHero(player, "zhangfei", false, true, true, false)
                room:setChangeSkillState(player, self:objectName(), 1)
                room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() - 1))
            end
        end
    end
}
liubeiZHCMT:addSkill(longnuZHCMT)

GZ_ZHCMT = sgs.General(extension, "GZ_ZHCMT", "shu", "6", true, true, true)
GZ_ZHCMT:addSkill("wusheng")
GZ_ZHCMT:addSkill("yijue")
GZ_ZHCMT:addSkill("paoxiao")
GZ_ZHCMT:addSkill("tishen")

hunjuZHCMT = sgs.CreateTriggerSkill{
    name = "hunjuZHCMT",
    events = {sgs.RoundStart},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getGeneral2Name() == "GZ_ZHCMT" then
            room:sendCompulsoryTriggerLog(player, "hunjuZHCMT")
            room:broadcastSkillInvoke("shencai", 1)
            room:getThread():delay(1000)
            room:broadcastSkillInvoke("hunjuZHCMT", 1)
		local judge = sgs.JudgeStruct()
		judge.pattern = "Peach,GodSalvation"
		judge.good = true
		judge.negative = true
		judge.reason = "hunjuZHCMT"
		judge.who = player
		room:judge(judge)
		if judge:isBad() then
            room:broadcastSkillInvoke("hunjuZHCMT", 2)
            room:getThread():delay(1000)
			room:killPlayer(player)
        end
            room:setPlayerMark(player, "longnuZHCMT", 0)
        end
        if room:askForSkillInvoke(player, self:objectName()) then
            room:sendCompulsoryTriggerLog(player, "hunjuZHCMT")
            room:broadcastSkillInvoke("jieying", 1)
            room:doSuperLightbox("hunjuZHCMT", "hunjuZHCMT")
            room:changeHero(player, "GZ_ZHCMT", false, true, true, false)
            room:setPlayerProperty(player, "maxhp", sgs.QVariant(player:getMaxHp() - 3))
            room:setPlayerMark(player, "longnuZHCMT", 1)
        end
    end
}
liubeiZHCMT:addSkill(hunjuZHCMT)

sgs.LoadTranslationTable{
    ["GZ_ZHCMT"] = "关羽&张飞",
	["liubeiZHCMT"] = "刘备",
    ["~liubeiZHCMT"] = "桃园依旧，来世再结。",
    ["#liubeiZHCMT"] = "誓守桃园义",
    ["longnuZHCMT"] = "龙怒",
    [":longnuZHCMT"] = "转换技，锁定技，准备阶段，你摸一张牌，将①“关羽”②“张飞”作为你的副将。",
    [":longnuZHCMT1"] = "转换技，锁定技，准备阶段，你摸一张牌，将①“<b>关羽</b>”<font color=\"#01A5AF\"><s>②“张飞”</s></font>作为你的副将。",
    [":longnuZHCMT2"] = "转换技，锁定技，准备阶段，你摸一张牌，将<font color=\"#01A5AF\"><s>①“关羽”</s></font>②“<b>张飞</b>”作为你的副将。",
    ["hunjuZHCMT"] = "魂聚",
    ["$hunjuZHCMT1"] = "关某记下了。",
    ["$hunjuZHCMT2"] = "桃园之梦，再也不会回来了……",
    [":hunjuZHCMT"] = "每轮开始时，你可以合并〖龙怒〗的两项效果，若如此做，每轮结束时，你判定，若结果不为【桃】或【桃园结义】，你死亡。",
    ["illustrator:liubeiZHCMT"] = "zoo",
    ["designer:liubeiZHCMT"] = "随心绘梨",
}

youkazhuoyouZHCMT = sgs.General(extension, "youkazhuoyouZHCMT", "qun", "4", true)

shimaZHCMT = sgs.CreateFilterSkill{
	name = "shimaZHCMT", 
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return (to_select:isKindOf("DefensiveHorse") or to_select:isKindOf("OffensiveHorse")) and (place == sgs.Player_PlaceHand or place == sgs.Player_PlaceEquip)
	end,
	view_as = function(self, originalCard)
		local ex_nihilo = sgs.Sanguosha:cloneCard("ex_nihilo", originalCard:getSuit(), originalCard:getNumber())
		ex_nihilo:setSkillName(self:objectName())
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(ex_nihilo)
		return card
	end
}
shimaZHCMT_GS = sgs.CreateTriggerSkill{
	name = "#shimaZHCMT_GS",
	events = {sgs.GameStart},
    frequency = sgs.Skill_Compulsory,
	on_trigger = function(self, event, player, data)
		player:throwEquipArea(2)
        player:throwEquipArea(3)
	end
}
youkazhuoyouZHCMT:addSkill(shimaZHCMT_GS)
youkazhuoyouZHCMT:addSkill(shimaZHCMT)

dangzaiZHCMT = sgs.CreateTriggerSkill{
    name = "dangzaiZHCMT",
    events = {sgs.DamageForseen},  -- 确保在伤害生效前触发
    can_trigger = function(self, target)
        return target
    end,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _, p in sgs.qlist(room:getAlivePlayers()) do
            if not p:isNude() and p:hasSkill("dangzaiZHCMT") then
                local handcards = p:getHandcards()
                local has_card = false
                for _, card1 in sgs.qlist(handcards) do
                    if card1:isKindOf("ExNihilo") then
                    has_card = true
                        break
                    end
                end  -- 检查是否有【无中生有】
                if has_card == true then
                    local card = room:askForCard(p, "#ExNihilo", "@dangzai-choose", sgs.QVariant(), sgs.Card_MethodRecast)
                    if card then
                        room:broadcastSkillInvoke("lianhuo")
                        room:sendCompulsoryTriggerLog(player, self:objectName())
                    -- 防止伤害
                        local move = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST, p:objectName(), self:objectName(), "")
                        room:moveCardTo(card, p, nil, sgs.Player_DiscardPile, move)
                        p:drawCards(1, self:objectName())
                        room:setPlayerFlag(player, "dangzaiZHCMT")
                    end
                end
            end
        end
        if player:hasFlag("dangzaiZHCMT") then
            room:setPlayerFlag(player, "-dangzaiZHCMT")
            return true
        else
            return false
        end
    end
}
youkazhuoyouZHCMT:addSkill(dangzaiZHCMT)

liancaiZHCMT = sgs.CreateTriggerSkill{
    name = "liancaiZHCMT",
    frequency = sgs.Skill_NotFrequent,
    events = {sgs.EventPhaseStart},  -- 出牌阶段触发

    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        
        -- 检查是否出牌阶段且手牌数与体力值均为全场唯一最小
        if player:getPhase() ~= sgs.Player_Play then return false end
        
        local min = true
        local min2 = true
        -- 遍历所有玩家，找到最小手牌和最小体力值
        for _, p in sgs.qlist(room:getOtherPlayers(player)) do
            if p:getHp() <= player:getHp()then
                min = false
            end
            if p:getHandcardNum() <= player:getHandcardNum() then
                min2 = false
            end
        end
        
        -- 检查是否唯一最小
        if  min == false and min2 == false then return false end
        -- 询问是否发动技能
        if not player:askForSkillInvoke(self:objectName(), data) then return false end
        room:broadcastSkillInvoke("jishe")
        room:sendCompulsoryTriggerLog(player, self:objectName())
        -- 选择一名其他角色
        local others = room:getOtherPlayers(player)
        local target = room:askForPlayerChosen(player, others, self:objectName(), "@liancai-choose", true, false)
        if not target then return false end
        
        -- 计算X（运营年数）
        local current_year = os.date("%Y")  -- 获取当前年份
        local x = math.min(current_year - 2008, 20)  -- 2008年三国杀上线，上限20
        
        -- 观看目标手牌并选择点数之和<=X的牌
        local card_ids = sgs.IntList()
        local handcards = target:getHandcards()
        for _, card in sgs.qlist(handcards) do
            card_ids:append(card:getId())
        end
        
        -- 显示目标手牌
        room:fillAG(card_ids)
        
        -- 让玩家选择牌
        local selected = sgs.IntList()
        local to_throw = sgs.IntList()
        while not card_ids:isEmpty() do
            local sum = 0
			for _, id in sgs.qlist(selected) do
				sum = sum + sgs.Sanguosha:getCard(id):getNumber()
			end
			if sum >= x - 1 then break end
			for _, id in sgs.qlist(card_ids) do
				if sum + sgs.Sanguosha:getCard(id):getNumber() > x then
					room:takeAG(nil, id, false)
                    to_throw:append(id)
				end
			end
			for _, id in sgs.qlist(card_ids) do
				if to_throw:contains(id) then
					card_ids:removeOne(id)
				end
            end
            if to_throw:length() + selected:length() == 4 then break end
			local card_id = room:askForAG(player, card_ids, true, self:objectName())
			if card_id == -1 then break end
			card_ids:removeOne(card_id)
			selected:append(card_id)
			room:takeAG(player, card_id, false)
			if card_ids:isEmpty() then break end
        end
        -- 获取选择的牌
        local dummy = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        if not selected:isEmpty() then
            for _, id in sgs.qlist(selected) do
                dummy:addSubcard(id)
            end
            room:obtainCard(player, dummy, false)
        end
        dummy:clearSubcards()
        room:clearAG()
        return false
    end
}
youkazhuoyouZHCMT:addSkill(liancaiZHCMT)

sgs.LoadTranslationTable{
	["youkazhuoyouZHCMT"] = "游卡桌游",
    ["~youkazhuoyouZHCMT"] = "我们的游戏正在蒸蒸日上哦。",
    ["#youkazhuoyouZHCMT"] = "吃相如狗",
    ["shimaZHCMT"] = "失马",
    [":shimaZHCMT"] = "锁定技，游戏开始时，你废除你的坐骑栏；你的坐骑牌均视为【无中生有】。",
    ["dangzaiZHCMT"] = "挡灾",
    [":dangzaiZHCMT"] = "当一名角色受到伤害时，你可以重铸一张【无中生有】然后防止此伤害。",
    ["@dangzai-choose"] = "是否发动挡灾？",
    ["@liancai-choose"] = "请选择敛财对象",
    ["liancaiZHCMT"] = "敛财",
    [":liancaiZHCMT"] = "出牌阶段开始时，若你的手牌数或体力值为全场唯一最小，你可以观看一名其他角色的手牌并获得其区域内任意张点数之和不超过X的牌（X等于《三国杀》运营年数且至多为20）。",
    ["illustrator:youkazhuoyouZHCMT"] = "杭州游卡",
    ["designer:youkazhuoyouZHCMT"] = "台灯和电风扇",
}

maodieZHCMT = sgs.General(extension, "maodieZHCMT", "god", "4", false)

dengshenZHCMT = sgs.CreateTriggerSkill {
    name = "dengshenZHCMT",
    events = {sgs.CardsMoveOneTime,sgs.Damage,sgs.Damaged},
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if event == sgs.CardsMoveOneTime and data:toMoveOneTime().from:objectName() ~= player:objectName() and data:toMoveOneTime().reason.m_playerId == player:objectName() then
            room:broadcastSkillInvoke("dengshenZHCMT")
            room:sendCompulsoryTriggerLog(player, "dengshenZHCMT")
            local move = data:toMoveOneTime()
            for _,id in sgs.qlist(move.card_ids) do
                local slash = sgs.Sanguosha:cloneCard("slash")
                slash:addSubcard(id)
			    slash:setSkillName(self:objectName())
                slash:deleteLater()
                for _,p in sgs.qlist(room:getOtherPlayers(player)) do
                    if p:objectName() == move.from:objectName() then
                        room:useCard(sgs.CardUseStruct(slash, player, p))
                    end
                end
            end
        elseif event == sgs.Damage or event == sgs.Damaged then
            room:broadcastSkillInvoke("dengshenZHCMT")
            room:sendCompulsoryTriggerLog(player, "dengshenZHCMT")
            room:drawCards(player, 2)
                local e = room:askForCard(player, "#EquipCard", "@changjie", sgs.QVariant(), sgs.Card_MethodNone)
                if (not e or player:hasEquip(e)) then
                    room:askForDiscard(player, self:objectName(), 1, 1, false, true)
                else
                    room:useCard(sgs.CardUseStruct(e, player, player))
                end
        end
    end
}
maodieZHCMT:addSkill(dengshenZHCMT)
maodieZHCMT:addRelateSkill("tenyeartuxi")
maodieZHCMT:addRelateSkill("haqiZHCMT")
guiweiZHCMT = sgs.CreateTriggerSkill{
    name = "guiweiZHCMT",
    events = {sgs.EventPhaseStart,},
    frequency = sgs.Skill_Wake,--触发频率：觉醒技
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start and player:getEquips():length() >= player:getHp() then
            room:doSuperLightbox("guiweiZHCMT", "guiweiZHCMT")
            room:sendCompulsoryTriggerLog(player, "guiweiZHCMT")
            room:changeHero(player, "maodie2ZHCMT", false, true)
            player:gainMark("@waked")
        end
    end
}
maodieZHCMT:addSkill(guiweiZHCMT)

maodie2ZHCMT = sgs.General(extension, "maodie2ZHCMT", "god", "3", false, true, false)

haqiZHCMT = sgs.CreateTriggerSkill{
    name = "haqiZHCMT",
    events = {sgs.DamageCaused},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.to:getMark("&haqiZHCMT") > 0 then
            room:broadcastSkillInvoke("haqiZHCMT")
            room:sendCompulsoryTriggerLog(player, "haqiZHCMT")
            damage.damage = damage.damage + 1
            data:setValue(damage)
        end
    end
}
haqiZHCMTcl = sgs.CreateTriggerSkill{
    name = "#haqiZHCMTcl",
    events = {sgs.TurnStart,},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        for _,p in sgs.qlist(room:getAlivePlayers()) do
            if p:getMark("&haqiZHCMT") > 0 then
                room:setPlayerMark(p, "&haqiZHCMT", 0)
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}
haqiZHCMT_record = sgs.CreateTriggerSkill{
    name = "#haqiZHCMT_record",
    events = {sgs.CardsMoveOneTime},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local move = data:toMoveOneTime()
        -- 判断是否从手牌或装备区移动
        if not move.from then
            return false
        end

        local has_hand = false
        for i = 0, move.card_ids:length() - 1 do
            local from_place = move.from_places:at(i)
            if from_place == sgs.Player_PlaceHand then
                has_hand = true
                break
            end
        end

        if not has_hand then
            return false
        end

        -- 获取来源玩家（move.from 是 GeneralPlayer，需通过 room 找到 ServerPlayer）
        local room = player:getRoom()
        local current = room:getCurrent()
        local from = room:findPlayerByObjectName(move.from:objectName())
        if from and current:hasSkill("haqiZHCMT") then
            room:setPlayerMark(from, "&haqiZHCMT", 1)
        end

        return false
    end,
    can_trigger = function(self, target)
        return target
    end
}

maodie2ZHCMT:addSkill(dengshenZHCMT)
maodie2ZHCMT:addSkill("tenyeartuxi")
maodie2ZHCMT:addSkill(haqiZHCMT)
maodie2ZHCMT:addSkill(haqiZHCMTcl)
maodie2ZHCMT:addSkill(haqiZHCMT_record)

sgs.LoadTranslationTable{
	["maodieZHCMT"] = "耄耋",
    ["maodie2ZHCMT"] = "耄耋",
    ["#maodieZHCMT"] = "哈基之绝唱",
    ["#maodie2ZHCMT"] = "哈基之绝唱",
    ["dengshenZHCMT"] = "登神",
    ["@changjie"] = "长阶",
    [":dengshenZHCMT"] = "①锁定技，当你得到或弃置其他角色区域里的牌时，你将此牌当作无距离限制的杀对其使用；②当你受到或造成伤害时，你摸两张牌并选择一项：1、弃置一张牌；2、使用一张装备牌。",
    ["discardCard"] = "弃牌",
    ["useCard"] = "装备",
    ["guiweiZHCMT"] = "归位",
    [":guiweiZHCMT"] = "觉醒技，准备阶段，若你装备区里的牌数不小于你的体力值，你失去一点体力上限，获得【突袭】和【哈气】。",
    ["haqiZHCMT"] = "哈气",
    [":haqiZHCMT"] = "锁定技，你对本回合失去过手牌的角色造成伤害+1。",
    ["illustrator:maodieZHCMT"] = "白手套和马犬旺财",
    ["designer:maodieZHCMT"] = "haydn",
}

simayiZHCMT = sgs.General(extension, "simayiZHCMT", "god", "4", true)

tuomingZHCMT = sgs.CreateTriggerSkill{
    name = "tuomingZHCMT",
    events = {sgs.Dying},
    frequency = sgs.Skill_Compulsory,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local dying = data:toDying()
		local _player = dying.who
        if player:getKingdom() ~= "jin" and player == _player then
            local p = room:askForPlayerChosen(player, room:getAlivePlayers(), "tuomingZHCMT", "tuomingZHCMT_choose", false, true)
            if p then
                local pk = p:getKingdom()
                room:broadcastSkillInvoke("jilve", 5)
                room:sendCompulsoryTriggerLog(player, "tuomingZHCMT")
                local new_kingdom = room:askForKingdom(p)
                if pk ~= new_kingdom then
                    room:setPlayerProperty(p, "kingdom", sgs.QVariant(new_kingdom))
                else
                    local kingdoms = {"wei", "shu", "wu", "qun", "jin"}  -- 所有可选势力
                    table.removeOne(kingdoms, pk)
                    local random_kingdom = kingdoms[math.random(1, #kingdoms)]  -- 随机选一个
                    room:setPlayerProperty(p, "kingdom", sgs.QVariant(random_kingdom))
                end
            end
        end
    end,
    can_trigger = function(self, target)
        return target:hasSkill("tuomingZHCMT")
    end
}
simayiZHCMT:addSkill(tuomingZHCMT)

zhaniZHCMT = sgs.CreateTriggerSkill{
    name = "zhaniZHCMT",
    events = {sgs.EventPhaseStart},
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        if player:getPhase() == sgs.Player_Start and (player:getMark("zhaniZHCMT") == 0 or player:getKingdom() == "wu") then
            room:broadcastSkillInvoke("jilve", 3)
            room:sendCompulsoryTriggerLog(player, "zhaniZHCMT")
            room:setPlayerMark(player, "zhaniZHCMT", 1)
            room:setPlayerMark(player, "zhaniZHCMT0", 1)
            if player:getKingdom() ~= "shu" then
                room:loseHp(player, player:getHp())
            end
            for _ = 0, player:getMaxHp() - player:getHp() do
                local p = room:askForPlayerChosen(player, room:getAlivePlayers(), "zhaniZHCMT", "zhaniZHCMT_choose", false, true)
                if p then
                    room:addPlayerMark(p, "&zhaniZHCMT1", 1)
                end
            end
            for _, p in sgs.qlist(room:getAlivePlayers()) do
                if p:getMark("&zhaniZHCMT1") > 0 then
                    local damage = sgs.DamageStruct()
                    damage.from = player
                    damage.to = p
                    damage.damage = p:getMark("&zhaniZHCMT1")
                    room:damage(damage)
                    room:setPlayerMark(p, "&zhaniZHCMT1", 0)
                end
            end
        end
        return false
    end
}
zhaniZHCMT_EX = sgs.CreateTriggerSkill{
    name = "#zhaniZHCMT_EX",
    events = {sgs.Damage},
    priority = -1,
    frequency = sgs.Skill_Wake,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local damage = data:toDamage()
        if damage.from == player and not damage.to:isAlive() then
            local Phase = player:getPhase()
            if player:getKingdom() ~= "qun" and player:getMark("zhaniZHCMT0") == 1 and player:getPhase() == sgs.Player_Start then
                room:setPlayerMark(player, "zhaniZHCMT0", 0)
                room:broadcastSkillInvoke("lianpo")
                player:drawCards(3)
                player:gainAnExtraTurn()
            else
                if player:getMark("zhaniZHCMT0") == 1 and Phase == sgs.Player_Start then
                    room:setPlayerMark(player, "zhaniZHCMT0", 0)
                    player:drawCards(3)
                player:skip(sgs.Player_Start)
                player:skip(sgs.Player_Judge)
                player:skip(sgs.Player_Draw)
                player:skip(sgs.Player_Play)
                player:skip(sgs.Player_Discard)
                player:skip(sgs.Player_Finish)
                end
            end
            if player:getKingdom() ~= "qun" and (player:getMark("zhaniZHCMT0") == 1 or player:getKingdom() == "wei") and player:getMark("zhaniZHCMT_EX") == 0 and Phase ~= sgs.Player_Start then
                room:setPlayerMark(player, "zhaniZHCMT0", 0)
                room:broadcastSkillInvoke("lianpo")
                player:drawCards(3)
                player:skip(sgs.Player_Start)
                player:skip(sgs.Player_Judge)
                player:skip(sgs.Player_Draw)
                player:skip(sgs.Player_Play)
                player:skip(sgs.Player_Discard)
                player:skip(sgs.Player_Finish)
                player:gainAnExtraTurn()
                room:setPlayerMark(player, "zhaniZHCMT_EX", 1)
            else
                if player:getMark("zhaniZHCMT0") == 1 and Phase ~= sgs.Player_Start then
                    room:setPlayerMark(player, "zhaniZHCMT0", 0)
                    player:drawCards(3)
                    room:setPlayerCardLimitation(player, "use", ".", true)
                    player:skip(sgs.Player_Play)
                    player:skip(sgs.Player_Discard)
                    player:skip(sgs.Player_Finish)
                end
            end
        end
        return false
    end,
    can_trigger = function(self, target)
        return target:hasSkill("zhaniZHCMT")
    end
}
simayiZHCMT:addSkill(zhaniZHCMT)
simayiZHCMT:addSkill(zhaniZHCMT_EX)

shiwangZHCMT = sgs.CreateTriggerSkill{
    name = "shiwangZHCMT",
    events = {sgs.GameStart, sgs.TurnStart},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self, event, player, data)
        local room = player:getRoom()
        local smy = room:findPlayersBySkillName("shiwangZHCMT")
        for _, p in sgs.qlist(smy) do
            if p:getKingdom() ~= "shu" and not (p:hasSkill("mashu") and p:hasSkill("kuanggu")) then
                room:handleAcquireDetachSkills(p, "mashu")
                room:handleAcquireDetachSkills(p, "kuanggu")
            elseif p:getKingdom() == "shu" and (p:hasSkill("mashu") or p:hasSkill("kuanggu")) then
                room:handleAcquireDetachSkills(p, "-mashu")
                room:handleAcquireDetachSkills(p, "-kuanggu")
            end
            if p:getKingdom() ~= "wei" and not (p:hasSkill("tuxi") and p:hasSkill("qiangxi")) then
                room:handleAcquireDetachSkills(p, "tuxi")
                room:handleAcquireDetachSkills(p, "qiangxi")
            elseif p:getKingdom() == "wei" and (p:hasSkill("tuxi") or p:hasSkill("qiangxi")) then
                room:handleAcquireDetachSkills(p, "-tuxi")
                room:handleAcquireDetachSkills(p, "-qiangxi")
            end
            if p:getKingdom() ~= "wu" and not (p:hasSkill("zhiheng") and p:hasSkill("botu")) then
                room:handleAcquireDetachSkills(p, "zhiheng")
                room:handleAcquireDetachSkills(p, "botu")
            elseif p:getKingdom() == "wu" and (p:hasSkill("zhiheng") or p:hasSkill("botu")) then
                room:handleAcquireDetachSkills(p, "-zhiheng")
                room:handleAcquireDetachSkills(p, "-botu")
            end
            if p:getKingdom() ~= "qun" and not (p:hasSkill("lijian") and p:hasSkill("weimu")) then
                room:handleAcquireDetachSkills(p, "lijian")
                room:handleAcquireDetachSkills(p, "weimu")
            elseif p:getKingdom() == "qun" and (p:hasSkill("lijian") or p:hasSkill("weimu")) then
                room:handleAcquireDetachSkills(p, "-lijian")
                room:handleAcquireDetachSkills(p, "-weimu")
            end
        end
    end,
    can_trigger = function(self, target)
        return target
    end
}
simayiZHCMT:addSkill(shiwangZHCMT)

simayiZHCMT:addRelateSkill("mashu")
simayiZHCMT:addRelateSkill("kuanggu")
simayiZHCMT:addRelateSkill("tuxi")
simayiZHCMT:addRelateSkill("qiangxi")
simayiZHCMT:addRelateSkill("zhiheng")
simayiZHCMT:addRelateSkill("botu")
simayiZHCMT:addRelateSkill("lijian")
simayiZHCMT:addRelateSkill("weimu")

sgs.LoadTranslationTable{
	["simayiZHCMT"] = "司马懿",
    ["#simayiZHCMT"] = "晋国之祖",
    ["~simayiZHCMT"] = "我已谋划至此，奈何……",
    ["tuomingZHCMT"] = "托命",
    ["tuomingZHCMT_choose"] = "请选择要托命的目标",
    [":tuomingZHCMT"] = "<font color=\"#CC00CC\"><b>锁定技,</b> 根据你的势力删除技能中对应字段；进入濒死状态时，你令一名角色重新选择势力。</font>",
    ["zhaniZHCMT"] = "诈逆",
    ["zhaniZHCMT1"] = "分配伤害",
    ["zhaniZHCMT_choose"] = "请选择要分配1点伤害的目标",
    [":zhaniZHCMT"] = "<font color=\"#339900\"><b>觉醒技,</b></font> 准备阶段，<font color=\"#CC0000\">你失去所有体力并</font>分配X+1点伤害，然后当你<font color=\"#3333CC\"><b>本</b></font>回合内击杀其他角色时，结束当前回合并摸三张牌，<font color=\"#999999\">然后执行一个额外回合</font>。（X为你已损失体力值）",
    ["shiwangZHCMT"] = "世望",
    [":shiwangZHCMT"] = "你视为拥有<font color=\"#CC0000\">“马术”、“狂骨”、</font><font color=\"#3333CC\">“突袭”、“强袭”、</font><font color=\"#339900\">“制衡”、“博图”、</font><font color=\"#999999\">“离间”、“帷幕”</font>。",
    ["illustrator:simayiZHCMT"] = "fallen＿",
    ["designer:simayiZHCMT"] = "fallen＿",
}

SkillAnjiangZHCMT = sgs.General(extension, "SkillAnjiangZHCMT", "god", "5", true, true, true)
SkillAnjiangZHCMT:addSkill(XiansiZHCMTSlash)
SkillAnjiangZHCMT:addSkill(dangzhengZHCMTVS)
SkillAnjiangZHCMT:addSkill(zhengsiZHCMT)

return {extension}