module("extensions.SoulA", package.seeall)
extension = sgs.Package("SoulA")

Soulcaoren = sgs.General(extension, "Soulcaoren", "wei", "4")
Soulcaohong = sgs.General(extension,"Soulcaohong","wei", "4")

--曹仁
Rcekuiwei = sgs.CreateTriggerSkill{
	name = "Rcekuiwei",  
	frequency = sgs.Skill_NotFrequent, 
	events = {sgs.EventPhaseStart}, 
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
			if p and player:getHp() >= p:getHp() then
				local phase = player:getPhase()
				if phase == sgs.Player_Finish then
					if room:askForSkillInvoke(p, self:objectName()) then
						room:broadcastSkillInvoke("Rcekuiwei",math.random(1,2))
						p:drawCards(1)
						p:turnOver()
					end
				end
			end
		end
	end,
	can_trigger = function(self, target)
		return target
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

Rceshishou = sgs.CreateTriggerSkill{
	name = "Rceshishou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self, event, player, data)
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Start then
			if change.from ~= sgs.Player_Discard then
			    local room = player:getRoom()
				change.to = sgs.Player_Discard
				data:setValue(change)
				player:insertPhase(sgs.Player_Discard)
				room:broadcastSkillInvoke("Rceshishou")
			end
		end
	end
}


--曹洪
Rcelinshou = sgs.CreateTriggerSkill{
	name = "Rcelinshou",  
	frequency = sgs.Skill_Compulsory, 
	events = {sgs.EventPhaseChanging, sgs.DrawNCards},  
	on_trigger = function(self, event, player, data) 
    	if event == sgs.EventPhaseChanging then
	    	local change = data:toPhaseChange()
		    local nextphase = change.to
            if nextphase == sgs.Player_Discard then
			    if not player:isSkipped(sgs.Player_Discard) then
				    local room = player:getRoom()
				    change.to = sgs.Player_Draw
				    data:setValue(change)
					room:broadcastSkillInvoke("Rcelinshou")
			    end
		    end
		else
			local draw = data:toDraw()
			if draw.reason ~= "draw_phase" then return false end
		    player:setFlags(self:objectName())
			draw.num = draw.num - 1
			data:setValue(draw)
		end
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
