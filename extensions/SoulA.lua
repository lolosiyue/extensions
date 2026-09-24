module("extensions.SoulA", package.seeall)
extension = sgs.Package("SoulA")

Soulcaoren = sgs.General(extension, "Soulcaoren", "wei", "4")
Soulcaohong = sgs.General(extension,"Soulcaohong","wei", "4")

--曹仁
Rcekuiwei = sgs.CreateTriggerSkillV2{
	name = "Rcekuiwei",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	can_trigger = function(skill, event, room, player, data)
		if player:getPhase() ~= sgs.Player_Finish then return false end
		local skill_list, owner_list = {}, {}
		for _, p in sgs.qlist(room:findPlayersBySkillName(skill:objectName())) do
			if p and player:getHp() >= p:getHp() then
				table.insert(skill_list, skill:objectName())
				table.insert(owner_list, p:objectName())
			end
		end
		if #skill_list > 0 then
			return table.concat(skill_list, "|"), table.concat(owner_list, "|")
		end
		return false
	end,
	on_cost = function(skill, event, room, player, ctx)
		return room:askForSkillInvoke(player, skill:objectName())
	end,
	on_effect = function(skill, event, room, player, ctx)
		room:broadcastSkillInvoke("Rcekuiwei",math.random(1,2))
		player:drawCards(1)
		player:turnOver()
		return false
	end
}

Rceyanzheng = sgs.CreateViewAsSkill{
	name = "Rceyanzheng", 
	n = 1, 
	view_filter = function(self, selected, to_select)
		return true
	end, 
	view_as = function(self, cards) 
		if #cards == 1 then 
			local ncard = cards[1]
			local nsuit = ncard:getSuit()
			local npoint = ncard:getNumber()
			local Newcard = sgs.Sanguosha:cloneCard("nullification", nsuit, npoint)
			Newcard:addSubcard(ncard)
			Newcard:setSkillName(self:objectName())
			return Newcard
		end
	end, 
	enabled_at_play = function(self, player)
		return false
	end, 
	enabled_at_response = function(self, player, pattern)
		if player:getHandcardNum() > player:getHp() then
			return pattern == "nullification"
		end
		return false
	end,
	enabled_at_nullification = function(self, player)
        if player:getHandcardNum() > player:getHp() then
	    	return true
		end
	end
}

Rceshishou = sgs.CreateTriggerSkillV2{
	name = "Rceshishou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Start and change.from ~= sgs.Player_Discard then
			return skill:objectName()
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		local change = ctx.original_data:toPhaseChange()
		change.to = sgs.Player_Discard
		ctx.original_data:setValue(change)
		player:insertPhase(sgs.Player_Discard)
		room:broadcastSkillInvoke("Rceshishou")
		return false
	end
}


--曹洪
Rcelinshou = sgs.CreateTriggerSkillV2{
	name = "Rcelinshou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging, sgs.DrawNCards},
	can_trigger = function(skill, event, room, player, data)
		if not player:hasSkill(skill:objectName()) then return false end
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard and not player:isSkipped(sgs.Player_Discard) then
				return skill:objectName()
			end
		else
			local draw = data:toDraw()
			if draw.reason == "draw_phase" then
				return skill:objectName()
			end
		end
		return false
	end,
	on_effect = function(skill, event, room, player, ctx)
		if event == sgs.EventPhaseChanging then
			local change = ctx.original_data:toPhaseChange()
			change.to = sgs.Player_Draw
			ctx.original_data:setValue(change)
			room:broadcastSkillInvoke("Rcelinshou")
		else
			local draw = ctx.original_data:toDraw()
			player:setFlags(skill:objectName())
			draw.num = draw.num - 1
			ctx.original_data:setValue(draw)
		end
		return false
	end
}

Soulcaoren:addSkill(Rcekuiwei)
Soulcaoren:addSkill(Rceyanzheng)
Soulcaoren:addSkill(Rceshishou)

Soulcaohong:addSkill(Rcelinshou)
Soulcaohong:addSkill("yuanhu")

sgs.LoadTranslationTable{

    ["SoulA"] = "魂行天下",
	
--武将

    ["Soulcaoren"] = "魂-曹仁",
	["&Soulcaoren"] = "曹仁",
	["#Soulcaoren"] = "顶天立地",
	["designer:Soulcaoren"] = "牙签",
	["cv:Soulcaoren"] = "官方",
	["illustrator:Soulcaoren"] = "张帅",
	["~Soulcaoren"] = "已经……尽力了……",
	
	["Soulcaohong"] = "魂-曹洪",
	["&Soulcaohong"] = "曹洪",
	["#Soulcaohong"] = "以身作则",
	["designer:Soulcaohong"] = "牙签，官方",
	["cv:Soulcaohong"] = " ",
	["illustrator:Soulcaohong"] = "LiuHeng",
	["~Soulcaohong"] = "福兮……祸之所伏……",
	
--技能

	["Rcekuiwei"] = "溃围",
	[":Rcekuiwei"] = "任意角色的结束阶段开始时，若你的当前体力值不大于该角色，你可以摸一张牌并将你的武将牌翻面。",
	["Rceyanzheng"] = "严整",
	[":Rceyanzheng"] = "当你的手牌数大于你的当前体力值时，你可以将一张牌视为【无懈可击】使用。",
	["Rceshishou"] = "失守",
	[":Rceshishou"] = "<font color=\"blue\"><b>锁定技，</b></font>回合开始前，你执行一个额外的弃牌阶段。",
	
	["Rcelinshou"] = "吝守",
	[":Rcelinshou"] = "<font color=\"blue\"><b>锁定技，</b></font>你的弃牌阶段均视为摸牌阶段；摸牌阶段摸牌时，你少摸一张牌。",
	
--配音
	
	["$Rcekuiwei1"] = "休整片刻，且待我杀出一条血路！",
	["$Rcekuiwei2"] = "骑兵列队，准备突围！",
	["$Rceyanzheng1"] = "任你横行霸道，我自岿然不动！",
	["$Rceyanzheng2"] = "行伍严整，百战不殆！",
	["$Rceshishou"] = "实在是守不住了……",
	
	["$Rcelinshou"] = "黄头小儿，可听过将军名号？！",
	
}
