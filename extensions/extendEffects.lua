--===============================--
extension = sgs.Package("extendeffects",sgs.Package_GeneralPack)
--===============================--
sgs.LoadTranslationTable{
	["extendeffects"] = "特效",	
}
--================================--
ENABLE_LV5_EFFECT = true
--================================--
TexiaoAnjiang = sgs.General(extension, "TexiaoAnjiang", "god", 5, true, true, true)
LuaTexiao = sgs.CreateTriggerSkill{
	name = "#LuaTexiao",
	events = {sgs.FinishJudge},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local judge = data:toJudge()
		local shadiao = judge.who
		if judge:isGood() then return end
		if judge.reason == "indulgence" then
			room:setEmotion(shadiao,"indulgence")
		elseif judge.reason == "supply_shortage"  then
			room:setEmotion(shadiao,"supply_shortage")
		elseif judge.reason == "lightning"  then
			room:setEmotion(shadiao,"lightning")
		end
	end,
}
--=============================--
LuaTexiaoWujie = sgs.CreateTriggerSkill{
	name = "#LuaTexiaoWujie",
	events = {sgs.CardUsed,sgs.CardResponded},
	global = true,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local card_star
		if event == sgs.CardUsed then 
			card_star = data:toCardUse().card
		else 
			card_star = data:toCardResponse().m_card
		end
		if card_star:isKindOf("EquipCard") then return end
		room:setEmotion(player,"wujie/"..card_star:objectName())
	end,
}
function contains(splist,role) --using in getWinner func
     for _,p in sgs.qlist(splist) do
     	if p:getRoleEnum()==role then return true end				
     end
	 return false
end

function getWinner(room,victim)    
	local r = victim:getRoleEnum() 
    local sp = room:getOtherPlayers(victim)					
    if r == sgs.Player_Lord then
        if(sp:length() == 1 and sp:first():getRole() == "renegade") then                    
			return sp:first():objectName()
        else                   
			return "rebel"
        end
    else
        if(not contains(sp,sgs.Player_Rebel) and not contains(sp,sgs.Player_Renegade))then               
			return "lord+loyalist"
        elseif(victim:getRole() == "renegade" and not contains(sp,sgs.Player_Loyalist))
           then room:setTag("RenegadeInFinalPK", sgs.QVariant(true))
			return nil
		else return nil end							
    end 	
end

-- mvpexperience = sgs.CreateTriggerSkill {
-- 	name = "#mvpexperience",
-- 	events = { sgs.PreCardUsed, sgs.CardResponded, sgs.CardsMoveOneTime, sgs.PreDamageDone,
-- 				sgs.HpLost, sgs.GameOverJudge,sgs.GameFinished },
-- 	global = true,
-- 	priority = 3,
-- 	can_trigger = function(self, target)
-- 		return target
-- 	end,
-- 	on_trigger = function(self, triggerEvent, player, data)
-- 		local room = player:getRoom()
-- 		local x = 1
-- 		if triggerEvent == sgs.PreCardUsed or triggerEvent == sgs.CardResponded then
-- 			local card = nil
-- 			if triggerEvent == sgs.PreCardUsed then
-- 				card = data:toCardUse().card
-- 			else
-- 				card = data:toCardResponse().m_card
-- 			end
-- 			local typeid = card:getTypeId()
-- 			if typeid == sgs.Card_TypeBasic then
-- 				room:addPlayerMark(player, "mvpexp", x)
-- 			elseif typeid == sgs.Card_TypeTrick then
-- 				room:addPlayerMark(player, "mvpexp", 3 * x)
-- 			elseif typeid == sgs.Card_TypeEquip then
-- 				room:addPlayerMark(player, "mvpexp", 2 * x)
-- 			end
-- 		elseif triggerEvent == sgs.CardsMoveOneTime then
-- 			local move = data:toMoveOneTime()
-- 			if not move.to or player:objectName() ~= move.to:objectName()
-- 				or (move.from and move.from:objectName() == move.to:objectName())
-- 				or (move.to_place ~= sgs.Player_PlaceHand and move.to_place ~= sgs.Player_PlaceEquip)
-- 				or room:getTag("FirstRound"):toBool() then
-- 				return false
-- 			end
-- 			room:addPlayerMark(player, "mvpexp", move.card_ids:length() * x)
-- 		elseif triggerEvent == sgs.PreDamageDone then
-- 			local damage = data:toDamage()
-- 			if damage.from then
-- 				room:addPlayerMark(damage.from, "mvpexp", damage.damage * 5 * x)
-- 				room:addPlayerMark(damage.to, "mvpexp", damage.damage * 2 * x)
-- 			end
-- 		elseif triggerEvent == sgs.HpLost then
-- 			local lose = data:toInt()
-- 			room:addPlayerMark(player, "mvpexp", lose * x)
-- 		elseif triggerEvent == sgs.GameOverJudge then
-- 			local death = data:toDeath()
-- 			if not death.who:isLord() then
-- 				room:removePlayerMark(death.who, "mvpexp", 100)
-- 			else
-- 				for _, p in sgs.qlist(room:getOtherPlayers(death.who)) do
-- 					room:addPlayerMark(p, "mvpexp", 10 * x)
-- 				end
-- 				local damage = death.damage
-- 				if damage and damage.from and damage.from:isAlive() and not damage.from:isLord() then
-- 					room:addPlayerMark(damage.from, "mvpexp", 5 * x)
-- 				end
-- 			end
-- 			if not getWinner(room,death.who) then return end
-- 			local players = sgs.QList2Table(room:getAllPlayers())
-- 			local function comp(a,b)
-- 				return a:getMark("mvpexp") >= b:getMark("mvpexp")
-- 			end
-- 			table.sort(players,comp)
-- 			room:doLightbox("#mvpeffect")
-- 			room:doLightbox(players[1]:getGeneralName(),3000)
-- 		end
-- 		return false
-- 	end
-- }
-- lianpoeffect = sgs.CreateTriggerSkill{
-- 	name = "lianpoeffect",
-- 	global = true,
-- 	events = {sgs.EventPhaseStart,sgs.GameOverJudge},
-- 	on_trigger = function(self,event,player,data)
-- 		local room = player:getRoom()
-- 		if event == sgs.GameOverJudge then
-- 			local current = room:getCurrent()
-- 			room:addPlayerMark(current,"havekilled",1)
-- 			local x = current:getMark("havekilled")
-- 			--current:speak("sdgsdsg"..x)
-- 			if (x>1) and (x<8) then
-- 				room:setEmotion(current,"lianpo\\"..x)
-- 			end
-- 		else
-- 			if player:getPhase() == sgs.Player_NotActive then
-- 				room:setPlayerMark(player,"havekilled",0)
-- 			end
-- 		end
-- 	end,
-- 	priority = 4,
-- 	can_trigger = function(self, target)
-- 		return target
-- 	end,
-- }
--===========================--
TexiaoAnjiang:addSkill(LuaTexiao)
-- TexiaoAnjiang:addSkill(lianpoeffect)
if ENABLE_LV5_EFFECT then TexiaoAnjiang:addSkill(LuaTexiaoWujie) end
-- TexiaoAnjiang:addSkill(mvpexperience)
sgs.LoadTranslationTable{
	["#mvpeffect"] = "全场最佳：",
}
--=============================--
return extension
