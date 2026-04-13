--===============================--
extension = sgs.Package("extendeffects", sgs.Package_GeneralPack)
--===============================--
sgs.LoadTranslationTable {
	["extendeffects"] = "特效",
}
--================================--
ENABLE_LV5_EFFECT = true
--================================--
TexiaoAnjiang = sgs.General(extension, "TexiaoAnjiang", "god", 5, true, true, true)
LuaTexiao = sgs.CreateTriggerSkill {
	name = "#LuaTexiao",
	events = { sgs.FinishJudge },
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local shadiao = judge.who
		if judge:isGood() then
			return
		end
		if judge.reason == "indulgence" then
			room:setEmotion(shadiao, "indulgence")
		elseif judge.reason == "supply_shortage" then
			room:setEmotion(shadiao, "supply_shortage")
		elseif judge.reason == "lightning" then
			room:setEmotion(shadiao, "lightning")
		end
	end,
	can_trigger = function(self,target)
		if table.contains(sgs.Sanguosha:getBanPackages(),"extendeffects")
		then else return target end
	end,
}
--=============================--
LuaTexiaoWujie = sgs.CreateTriggerSkill {
	name = "#LuaTexiaoWujie",
	events = { sgs.CardUsed, sgs.CardResponded },
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card_star
		if event == sgs.CardUsed then
			card_star = data:toCardUse().card
		else
			card_star = data:toCardResponse().m_card
		end
		if not card_star then
			return
		end
		if card_star:isKindOf("EquipCard") then
			return
		end
		room:setEmotion(player, "wujie/" .. card_star:objectName())
	end,
	can_trigger = function(self,target)
		if table.contains(sgs.Sanguosha:getBanPackages(),"extendeffects")
		then else return target end
	end,
}

lianpoeffect = sgs.CreateTriggerSkill{
	name = "lianpoeffect",
	global = true,
	events = {sgs.EventPhaseStart,sgs.GameOverJudge},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.GameOverJudge then
			local current = room:getCurrent()
			-- room:addPlayerMark(current,"havekilled",1)
			local x = current:getMark("havekilled-Clear")
			--current:speak("sdgsdsg"..x)
			if (x>1) and (x<8) then
				room:setEmotion(current,"lianpo\\"..x)
			end
		end
	end,
	priority = 4,
	can_trigger = function(self,target)
		if table.contains(sgs.Sanguosha:getBanPackages(),"extendeffects")
		then else return target end
	end,
}
--===========================--
TexiaoAnjiang:addSkill(LuaTexiao)
TexiaoAnjiang:addSkill(lianpoeffect)
if ENABLE_LV5_EFFECT then
	TexiaoAnjiang:addSkill(LuaTexiaoWujie)
end
sgs.LoadTranslationTable {
	["#mvpeffect"] = "全场最佳：",
}
--=============================--
return extension
