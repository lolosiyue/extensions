
extension = sgs.Package("Xiangqi",sgs.Package_CardPack)


sgs.LoadTranslationTable{
	["Xiangqi"]="象棋",
	["chess"]="象棋",
	
	["RedJu"]="車",
	[":RedJu"]="基本牌\
   <b>时机</b>：出牌阶段限一次\
   <b>目标</b>：由你制定的一名角色\
   <b>效果</b>：你分别对该角色距离1以内的角色造成一点伤害",
	["BlackJu"]="車",
	[":BlackJu"]="基本牌\
   <b>时机</b>：出牌阶段限一次\
   <b>目标</b>：由你指定的一名角色\
   <b>效果</b>：你分别对该角色距离1以内的角色造成一点伤害",
   
   ["RedBing"]="兵",
   [":RedBing"]="基本牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你指定的一名角色\
   <b>效果</b>：该角色须打出一张手牌，否则你对其造成一点伤害",
   ["BlackZu"]="卒",
   [":BlackZu"]="基本牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你指定的一名角色\
   <b>效果</b>：该角色须打出一张手牌，否则你对其造成一点伤害",
   ["@Bing"]="请打出一张手牌，否则受到一点伤害",
   ["#Bing"]="受【兵】或【卒】的影响，你需要选择弃牌或受伤",
   
   ["RedPao"]="炮",
     [":RedPao"]="装备牌\
   <b>攻击范围</b>：999\
   <b>效果</b>：锁定技，你使用的牌无法被响应且你使用牌不得指定距离1以内的其他角色。",
      ["BlackPao"]="砲",
     [":BlackPao"]="装备牌\
   <b>攻击范围</b>：999\
   <b>效果</b>：锁定技，你使用的牌无法被响应且你使用牌不得指定距离1以内的其他角色。",
   ["#PaoSkill1"]="炮",
   
   ["RedXiang"]="相",
   ["BlackXiang"]="象",
   ["#XiangUse"]="<font color=\"#FFFF00\"><b>大音希声，大象无形</b>",
   [":BlackXiang"]="宝物牌\
   <b>效果</b>：锁定技，当你的体力值发生变化时，你摸一张牌。",
   [":RedXiang"]="宝物牌\
   <b>效果</b>：锁定技，当你的体力值发生变化时，你摸一张牌。",
 
    ["BlackJiang"]="将",
   [":BlackJiang"]="基本牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：本回合内，所有角色无法响应你使用的牌",
    ["RedShuai"]="帅",
   [":RedShuai"]="基本牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：本回合内，所有角色无法响应你使用的牌",
   
   ["BlackMa"]="马",
   [":BlackMa"]="基本牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你指定的一名角色\
   <b>效果</b>：本回合内，该角色非锁定技无效",  
   ["RedMa"]="马",
   [":RedMa"]="基本牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你指定的一名角色\
   <b>效果</b>：本回合内，该角色非锁定技无效",
   
   ["RedShi"]="仕",
   [":RedShi"]="基本牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：你获得1点护甲",  
   ["BlackShi"]="士",
   [":BlackShi"]="基本牌\
   <b>时机</b>：出牌阶段\
   <b>目标</b>：你\
   <b>效果</b>：你获得1点护甲",
}


XiangqiAnjiang = sgs.General(extension, "XiangqiAnjiang", "god", 99, false,true,true)

--車
RedJu = sgs.CreateBasicCard{
	name = "RedJu",
	class_name = "Ju",
	subtype = "chess",
	target_fixed = false,
    can_recast = false,
    available = function(self,player)
		local count = player:getMark("Ju-Clear")
		if count == 0 then
			return true
		else
			return false
		end
    end,
	filter = function(self, targets, to_select)--过滤器，用来表示可选范围
	local player = sgs.Self
	if player  then
		if #targets < 1 then
			return to_select ~= player
		end
	end
	end,
	feasible = function(self,targets)--表示可以点确定的情况
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source,"Ju-Clear",1)
		for _, target in ipairs(targets) do
			room:cardEffect(self, source, target)
		end
		return
	end,
	on_effect = function(self, effect)
	
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		--source:addMark("Ju-Clear")
		local players= room:getAlivePlayers()
		local targets =sgs.SPlayerList()
												
		for _,p in sgs.qlist(players) do
			if target:distanceTo(p) <= 1 then 
				targets:append(p)
			end
		end
		for _,p in sgs.qlist(targets) do
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = p
			damage.damage = 1
			damage.card = self
			room:damage(damage)				
		end
		

	end
}
BlackJu = sgs.CreateBasicCard{
	name = "BlackJu",
	class_name = "ju",
	subtype = "chess",
	target_fixed = false,
    can_recast = false,
   available = function(self,player)
		local count =player:getMark("Ju-Clear")
		if count == 0 then
		return true
		else
        return false
		end
    end,
	filter = function(self, targets, to_select)--过滤器，用来表示可选范围
	local player = sgs.Self
	if player then
		if #targets < 1 then
			return to_select ~= player
		end
	end
	end,
	feasible = function(self,targets)--表示可以点确定的情况
		return #targets == 1
	end,
	on_use = function(self, room, source, targets)
		room:addPlayerMark(source,"Ju-Clear",1)
		for _, target in ipairs(targets) do
			room:cardEffect(self, source, target)
		end
		return
	end,
	on_effect = function(self, effect)
		
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		--source:addMark("Ju-Clear")
		local players= room:getAlivePlayers()
		local targets =sgs.SPlayerList()
												
		for _,p in sgs.qlist(players) do
			if target:distanceTo(p) <= 1 then 
				targets:append(p)
			end
		end
		for _,p in sgs.qlist(targets) do
			local damage = sgs.DamageStruct()
			damage.from = source
			damage.to = p
			damage.damage = 1
			damage.card = self
			room:damage(damage)				
		end
		

	end
}

--红車
for i=0,1,1 do
	local card = RedJu:clone()
	card:setDamageCard(true)
	card:setSuit(5)
	card:setNumber(0)
	card:setParent(extension)
end
--黑車
for i=0,1,1 do
	local card = BlackJu:clone()
	card:setDamageCard(true)
	card:setSuit(4)
	card:setNumber(0)
	card:setParent(extension)
end

--兵

RedBing = sgs.CreateBasicCard{
	name = "RedBing",
	class_name = "Bing",
	subtype = "chess",
	subclass = sgs.LuaTrickCard_TypeDelayedTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	filter = function(self,targets,to_select,source)
		if source:isProhibited(to_select,self) then return end
	    return to_select:objectName()~=source:objectName()
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	on_effect = function(self, effect)
		local room = effect.to:getRoom()
		--if not room:askForDiscard(effect.to, self:objectName(), 1, 1, true,false,"@Bing") then
		if (effect.no_respond or not room:askForCard(effect.to, ".", "@Bing", sgs.QVariant(), self:objectName())) then
			local damage = sgs.DamageStruct()
			damage.from = effect.from
			damage.to = effect.to
			damage.damage = 1
			damage.card = self
			room:damage(damage)
		end
	end,
}

BlackZu = sgs.CreateBasicCard{
	name = "BlackZu",
	class_name = "Zu",
	subtype = "chess",
	subclass = sgs.LuaTrickCard_TypeDelayedTrick,
	target_fixed = false,
	can_recast = false,
	is_cancelable = false,
	filter = function(self, targets, to_select,source)
		if source:isProhibited(to_select,self) then return end
	    return to_select:objectName()~=source:objectName()
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	on_effect = function(self, effect)
	local room = effect.to:getRoom()
		--if not room:askForDiscard(effect.to, self:objectName(), 1, 1, true,false,"@Bing") then
		if  (effect.no_respond or not room:askForCard(effect.to, ".", "@Bing", sgs.QVariant(), self:objectName())) then
			local damage = sgs.DamageStruct()
			damage.from = effect.from
			damage.to = effect.to
			damage.damage = 1
			damage.card = self
			room:damage(damage)
		end
	end,
}


for i=1,5,1 do
	local card = RedBing:clone()
	card:setDamageCard(true)
	card:setSuit(5)
	card:setNumber(0)
	card:setParent(extension)
end
for i=1,5,1 do
	local card = BlackZu:clone()
	card:setDamageCard(true)
	card:setSuit(4)
	card:setNumber(0)
	card:setParent(extension)
end

--炮
PaoSkill1 = sgs.CreateProhibitSkill{
    name = "#PaoSkill1",
    -- ProhibitSkill has no V2 counterpart; actual equipment admission stays explicit.
    is_prohibited = function(self, from, to, card)
        return from and to and from ~= to and not card:isKindOf("SkillCard")
            and (from:hasWeapon("RedPao") or from:hasWeapon("BlackPao"))
            and from:distanceTo(to) <= 1
    end,
}


PaoSkill2 = sgs.CreateEquipSkillV2{
    name = "#PaoSkill2", equipment = "RedPao", equipment_type = "weapon",
    frequency = sgs.Skill_Compulsory, events = {sgs.CardUsed},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and data:toCardUse().from == player then
            return self:objectName(), player
        end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local list = use.no_respond_list
        if not table.contains(list, "_ALL_TARGETS") then table.insert(list, "_ALL_TARGETS") end
        use.no_respond_list = list
        ctx.original_data:setValue(use)
        return false
    end,
}
BlackPaoSkill = sgs.CreateEquipSkillV2{
    name = "#BlackPaoSkill", equipment = "BlackPao", equipment_type = "weapon",
    frequency = sgs.Skill_Compulsory, events = {sgs.CardUsed},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() and data:toCardUse().from == player then
            return self:objectName(), player
        end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local list = use.no_respond_list
        if not table.contains(list, "_ALL_TARGETS") then table.insert(list, "_ALL_TARGETS") end
        use.no_respond_list = list
        ctx.original_data:setValue(use)
        return false
    end,
}
XiangqiAnjiang:addSkill(BlackPaoSkill)
XiangqiAnjiang:addSkill(PaoSkill1)
XiangqiAnjiang:addSkill(PaoSkill2)
RedPao = sgs.CreateWeapon{
	name="RedPao",
	class_name = "Pao",
	range = 999,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,"#PaoSkill1")
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "#PaoSkill1")
	end,
}
BlackPao = sgs.CreateWeapon{
	name="BlackPao",
	class_name = "pao",
	range = 999,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,"#PaoSkill1")
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player, "#PaoSkill1")
	end,
}
--红炮
for i=1,2,1 do
	local card = RedPao:clone()
	card:setSuit(5)
	card:setNumber(0)
	card:setParent(extension)
end
--黑炮
for i=0,1,1 do
	local card = BlackPao:clone()
	card:setSuit(4)
	card:setNumber(0)
	card:setParent(extension)
end



--相


XiangSkill = sgs.CreateEquipSkillV2{
    name = "#XiangSkill", equipment = "RedXiang", equipment_type = "treasure",
    frequency = sgs.Skill_Compulsory, events = {sgs.HpChanged},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() then return self:objectName(), player end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        local msg = sgs.LogMessage(); msg.type = "#XiangUse"; room:sendLog(msg)
        player:drawCards(self:getEffectiveAmount(ctx))
        return false
    end,
}
BlackXiangSkill = sgs.CreateEquipSkillV2{
    name = "#BlackXiangSkill", equipment = "BlackXiang", equipment_type = "treasure",
    frequency = sgs.Skill_Compulsory, events = {sgs.HpChanged},
    can_trigger = function(self, event, room, player, data)
        if player and player:isAlive() then return self:objectName(), player end
        return ""
    end,
    on_effect = function(self, event, room, player, ctx)
        local msg = sgs.LogMessage(); msg.type = "#XiangUse"; room:sendLog(msg)
        player:drawCards(self:getEffectiveAmount(ctx))
        return false
    end,
}
XiangqiAnjiang:addSkill(BlackXiangSkill)
XiangqiAnjiang:addSkill(XiangSkill)


RedXiang = sgs.CreateTreasure{
    name = "RedXiang", class_name = "Xiang",
}
BlackXiang = sgs.CreateTreasure{
    name = "BlackXiang", class_name = "xiang",
}



for i=1,2,1 do
	local card = RedXiang:clone()
	card:setSuit(5)
	card:setNumber(0)
	card:setParent(extension)
end
for i=0,1,1 do
	local card = BlackXiang:clone()
	card:setSuit(4)
	card:setNumber(0)
	card:setParent(extension)
end



--帅

-- A turn-scoped card result must also expire when Finish is skipped or interrupted.
-- Death is dispatched once for each seat; clean only when its actor is the dead source.
local function chessCleanupSource(event, player, data)
    if not player then return nil end
    if event == sgs.Death then
        local dead = data:toDeath().who
        if dead and dead:objectName() == player:objectName() then return dead end
    elseif event == sgs.TurnBroken then return player
    elseif event == sgs.EventPhaseChanging and data:toPhaseChange().to == sgs.Player_NotActive then return player
    elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Finish then return player end
    return nil
end

ShuaiSkill = sgs.CreateRuleSkillV2{
    name = "#ShuaiSkill", frequency = sgs.Skill_Compulsory,
    events = {sgs.CardUsed, sgs.EventPhaseEnd, sgs.EventPhaseChanging, sgs.TurnBroken, sgs.Death},
    can_trigger = function(self, event, room, player, data)
        if event == sgs.CardUsed and player and player:isAlive()
            and player:hasFlag("XiangqiShuai") and data:toCardUse().from == player then
            return self:objectName(), player
        end
        return ""
    end,
    on_record = function(self, event, room, player, ctx)
        -- A card-created turn effect has no acquired skill instance.
        local source = chessCleanupSource(event, player, ctx.original_data)
        if source then room:setPlayerFlag(source, "-XiangqiShuai") end
    end,
    on_effect = function(self, event, room, player, ctx)
        local use = ctx.original_data:toCardUse()
        local list = use.no_respond_list
        if not table.contains(list, "_ALL_TARGETS") then table.insert(list, "_ALL_TARGETS") end
        use.no_respond_list = list
        ctx.original_data:setValue(use)
        return false
    end,
}


XiangqiAnjiang:addSkill(ShuaiSkill)

RedShuai = sgs.CreateBasicCard{
	name = "RedShuai",
	class_name = "Shuai",
	subtype = "chess",
	target_fixed = true,
    can_recast = false,
	on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		for _, target in ipairs(targets) do
			room:cardEffect(self, source, target)
		end
		return
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local room =target:getRoom()
		room:setPlayerFlag(target,"XiangqiShuai")
	end
}
BlackJiang = sgs.CreateBasicCard{
	name = "BlackJiang",
	class_name = "Jiang",
	subtype = "chess",
	target_fixed = true,
    can_recast = false,
	on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		for _, target in ipairs(targets) do
			room:cardEffect(self, source, target)
		end
		return
	end,
	on_effect = function(self, effect)
		local target = effect.to
		local room =target:getRoom()
		room:setPlayerFlag(target,"XiangqiShuai")
	end
}

for i=1,1,1 do
	local card = RedShuai:clone()
	card:setSuit(5)
	card:setNumber(0)
	card:setParent(extension)
end
for i=1,1,1 do
	local card = BlackJiang:clone()
	card:setSuit(4)
	card:setNumber(0)
	card:setParent(extension)
end


--马

MaSkill = sgs.CreateRuleSkillV2{
    name = "#MaSkill", frequency = sgs.Skill_Compulsory,
    events = {sgs.EventPhaseEnd, sgs.EventPhaseChanging, sgs.TurnBroken, sgs.Death},
    can_trigger = function() return "" end,
    on_record = function(self, event, room, player, ctx)
        local source = chessCleanupSource(event, player, ctx.original_data)
        if not source then return end
        -- Consume this source's list before callbacks: later cleanup events are idempotent.
        -- Each duplicate name is one contributed stack; other sources' stacks remain.
        local names = source:getTag("XiangqiMaTargets"):toString():split("+")
        source:removeTag("XiangqiMaTargets")
        for _, name in ipairs(names) do
            local target = room:findPlayerByObjectName(name, true)
            if target and target:getMark("@skill_invalidity") > 0 then
                room:removePlayerMark(target, "@skill_invalidity")
            end
        end
    end,
}
XiangqiAnjiang:addSkill(MaSkill)

RedMa = sgs.CreateBasicCard{
	name = "RedMa",
	class_name = "ma",
	subtype = "chess",
	target_fixed = false,
    can_recast = false,
	filter = function(self,targets,to_select,source)
		if source:isProhibited(to_select,self) then return end
	    return #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:addPlayerMark(target,"@skill_invalidity",1)
		-- Keep the card effect's source and each stack for exact turn cleanup.
        local names = source:getTag("XiangqiMaTargets"):toString()
        source:setTag("XiangqiMaTargets", sgs.QVariant(names == "" and target:objectName() or names .. "+" .. target:objectName()))
	end
}

BlackMa = sgs.CreateBasicCard{
	name = "BlackMa",
	class_name = "Ma",
	subtype = "chess",
	target_fixed = false,
    can_recast = false,
	filter = function(self,targets,to_select,source)
		if source:isProhibited(to_select,self) then return end
	    return #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	on_effect = function(self, effect)
		local source = effect.from
		local target = effect.to
		local room = source:getRoom()
		room:addPlayerMark(target,"@skill_invalidity",1)
		-- Keep the card effect's source and each stack for exact turn cleanup.
        local names = source:getTag("XiangqiMaTargets"):toString()
        source:setTag("XiangqiMaTargets", sgs.QVariant(names == "" and target:objectName() or names .. "+" .. target:objectName()))
	end
}



for i=1,2,1 do
	local card = RedMa:clone()
	card:setSuit(5)
	card:setNumber(0)
	card:setParent(extension)
end

for i=1,2,1 do
	local card = BlackMa:clone()
	card:setSuit(4)
	card:setNumber(0)
	card:setParent(extension)
end




--士


BlackShi = sgs.CreateBasicCard{
	name = "BlackShi",
	class_name = "shi",
	subtype = "chess",
	target_fixed = true,
    can_recast = false,
	on_use = function(self, room, source, targets)
	local room = source:getRoom()
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		for _, target in ipairs(targets) do
			room:cardEffect(self, source, target)
		end
		return
	end,
	on_effect = function(self, effect)
		local target = effect.to
		target:gainHujia(1)
	end
}
RedShi = sgs.CreateBasicCard{
	name = "RedShi",
	class_name = "Shi",
	subtype = "chess",
	target_fixed = true,
    can_recast = false,
	on_use = function(self, room, source, targets)
		if not table.contains(targets,source) then
			table.insert(targets,source)
		end
		for i=1,#targets,1 do
			room:cardEffect(self, source, targets[i])
		end
	
		
	end,
	on_effect = function(self, effect)
	
		local target = effect.to
		local room =target:getRoom()
		target:gainHujia(1)
	end
}
for i=1,2,1 do
	local card = BlackShi:clone()
	card:setSuit(4)
	card:setNumber(0)
	card:setParent(extension)
end
for i=1,2,1 do
	local card = RedShi:clone()
	card:setSuit(5)
	card:setNumber(0)
	card:setParent(extension)
end



-- Only the non-trigger prohibition needs the legacy equipment metadata flag.
PaoSkill1:setEquipSkill(true)
sgs.LoadTranslationTable{
    ["#BlackPaoSkill"] = "砲", ["#BlackXiangSkill"] = "象",
}
return extension