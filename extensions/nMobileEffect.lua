extension = sgs.Package("n_mobile_effect",sgs.Package_GeneralPack)

n_anjiang = sgs.General(extension,"n_anjiang","god",5,true,true)

n_trig = sgs.CreateTriggerSkill{
	name = "#n_trig",
	global = true,
	events = {sgs.TurnStart,sgs.FinishJudge,sgs.EventPhaseStart,sgs.Death},
	can_trigger = function(self,target)
		if table.contains(sgs.Sanguosha:getBanPackages(),"n_mobile_effect")
		then else return target end
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.TurnStart then
			local n = 15
			for _,p in sgs.qlist(room:getAlivePlayers())do
				n = math.min(p:getSeat(),n)
			end
			if player:getSeat() == n and not room:getTag("ExtraTurn"):toBool() then
				if player:getMark("Global_TurnCount") == 0 then 
					room:broadcastSkillInvoke("gamestart","system")
					room:doAnimate(2,"skill=StartAnim:rule","rule")
					for _,p in sgs.qlist(room:getAlivePlayers())do
						room:addPlayerMark(p,"mvpexp",1)
					end
				end
			end
		elseif event == sgs.FinishJudge then
			local judge = data:toJudge()
			if judge:isGood() then return end
			if judge.reason == "indulgence" then
				room:setEmotion(judge.who,"indulgence-effect")
			elseif judge.reason == "supply_shortage" then
				room:setEmotion(judge.who,"supply_shortage-effect")
			elseif judge.reason == "lightning" then
				room:setEmotion(judge.who,"lightning-effect")
			end
		elseif event == sgs.GameOverJudge then
			local current = room:getCurrent()
			room:addPlayerMark(current,"havekilled",1)
			local x = current:getMark("havekilled")
			if room:getAllPlayers(true):length()-room:alivePlayerCount()==1
			then sgs.Sanguosha:playSystemAudioEffect("yipo") end
			if x>1 and x<8 then
				sgs.Sanguosha:playSystemAudioEffect("lianpo"..x)
				room:setEmotion(current,"lianpo\\"..x)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_NotActive then
				room:setPlayerMark(player,"havekilled",0)
				for _,p in sgs.qlist(room:getAlivePlayers())do
					room:setPlayerMark(p,"healed",0)
					room:setPlayerMark(p,"Nohealed",0)
					room:setPlayerMark(p,"rescued",0)
					room:setPlayerMark(p,"Norescued",0)
				end
			elseif player:getPhase() == sgs.Player_RoundStart then
				local jsonValue = {
					player:objectName(),
					"turnstart",
				}
				for _,p in sgs.qlist(room:getOtherPlayers(player,true))do
					room:doNotify(p,sgs.CommandType.S_COMMAND_SET_EMOTION,json.encode(jsonValue))
				end	
			end
		elseif event == sgs.Death
		then
			local damage = data:toDeath().damage
			local who = data:toDeath().who
			if who==player and damage and damage.from
			then
				room:doAnimate(2,"skill=KillAnim:"..damage.from:getGeneralName().."+"..who:getGeneralName(),"~"..who:getGeneralName())
				room:getThread():delay(2500)
			end
		end
		return false
	end
}
n_anjiang:addSkill(n_trig)

n_mobile_effect = sgs.CreateTriggerSkill{
    name = "n_mobile_effect",
    priority = 9,
    global = true,
    events = {sgs.Damage,sgs.DamageComplete,sgs.EnterDying,sgs.GameOverJudge,sgs.HpRecover},
	can_trigger = function(self,target)
		if table.contains(sgs.Sanguosha:getBanPackages(),"n_mobile_effect")
		then else return target end
	end,
    on_trigger = function(self,event,player,data)
        local room = player:getRoom()
		local function damage_effect(n)
			if n == 3 then
				room:doAnimate(2,"skill=Rampage:mbjs","")
				room:broadcastSkillInvoke(self:objectName(),1)
				room:getThread():delay(3325)
            elseif n >= 4 then
                room:doAnimate(2,"skill=Violence:mbjs","")
				room:broadcastSkillInvoke(self:objectName(),2)
				room:getThread():delay(4000)
			end
		end
        if event == sgs.Damage then
            local damage = data:toDamage()
            if damage.from and damage.from:getMark("mobile_damage") == 0 then
				damage_effect(damage.damage)
			end
		elseif event == sgs.EnterDying then
			local damage = data:toDying().damage
            if damage and damage.from and damage.to:isAlive() then
				if damage.damage >= 3 then
					damage_effect(damage.damage)
					room:addPlayerMark(damage.from,"mobile_damage")
				end
			end
		elseif event == sgs.DamageComplete then
			local damage = data:toDamage()
			if damage.from then room:setPlayerMark(damage.from,"mobile_damage",0) end
        elseif event == sgs.GameOverJudge then
            local current = room:getCurrent()
			room:addPlayerMark(current,"havekilled",1)
			local x = current:getMark("havekilled")
			if not room:getTag("FirstBlood"):toBool() then
                room:setTag("FirstBlood",sgs.QVariant(true))
				room:doAnimate(2,"skill=FirstBlood:mbjs","")
				room:broadcastSkillInvoke(self:objectName(),3)
				room:getThread():delay(2500)
			end
			if x == 2 then
                room:doAnimate(2,"skill=DoubleKill:mbjs","")
				room:broadcastSkillInvoke(self:objectName(),x + 2)
				room:getThread():delay(2800)
            elseif x == 3 then
                room:doAnimate(2,"skill=TripleKill:mbjs","")
				room:broadcastSkillInvoke(self:objectName(),x + 2)
				room:getThread():delay(2800)
            elseif x == 4 then
                room:doAnimate(2,"skill=QuadraKill:mbjs","")
				room:broadcastSkillInvoke(self:objectName(),x + 2)
				room:getThread():delay(3500)
            elseif x > 4 and x<=7 then
                room:doAnimate(2,"skill=MoreKill:" .. x,"")
				room:broadcastSkillInvoke(self:objectName(),x + 2)
				room:getThread():delay(4000)
            end
		elseif event == sgs.HpRecover then
			local recover = data:toRecover()
			-- 如果没有体力回复来源，或者是自己让自己回血，那么触发医术高超
			if recover.who == player or room:getCurrent() == player and not recover.who then
				room:addPlayerMark(player,"healed",recover.recover)
				if player:getMark("Nohealed")<1 and player:getMark("healed") >= 3 then
					room:setPlayerMark(player,"healed",0)
					room:addPlayerMark(player,"Nohealed")
					room:doAnimate(2,"skill=Heal:mbjs","")
					room:broadcastSkillInvoke(self:objectName(),10)
					room:getThread():delay(2000)
				end
			end

			if recover.who and player~=room:getCurrent() and recover.who~=player then
				room:addPlayerMark(recover.who,"rescued",recover.recover)
				if recover.who:getMark("Norescued") < 1 and recover.who:getMark("rescued") >= 3 and player:isAlive() then
					room:setPlayerMark(recover.who,"rescued",0)
					room:addPlayerMark(recover.who,"Norescued")
					room:doAnimate(2,"skill=Rescue:mbjs","")
					room:broadcastSkillInvoke(self:objectName(),11)
					room:getThread():delay(2000)
				end
			end
		end
    end,
}
n_anjiang:addSkill(n_mobile_effect)

function getWinner(room,victim)    
	--if not string.find(room:getMode(),"p") then return nil end
	local function contains(plist,role)
		for _,p in sgs.qlist(plist)do
			if p:getRoleEnum() == role then return true end
		end
		return false
	end
	local r = victim:getRoleEnum() 
    local sp = room:getOtherPlayers(victim)					
    if r == sgs.Player_Lord then
        if(sp:length() == 1 and sp:first():getRole() == "renegade") then                    
			return "renegade"
        else                   
			return "rebel"
        end
    else
        if(not contains(sp,sgs.Player_Rebel) and not contains(sp,sgs.Player_Renegade))then               
			return "lord+loyalist"
		else return nil end							
    end 	
end

n_mvpexperience = sgs.CreateTriggerSkill {
	name = "#n_mvpexperience",
	events = { sgs.PreCardUsed,sgs.CardResponded,sgs.CardsMoveOneTime,sgs.PreDamageDone,
	sgs.HpLost,sgs.GameOverJudge,sgs.GameFinished },
	global = true,
	priority = 3,
	can_trigger = function(self,target)
		if table.contains(sgs.Sanguosha:getBanPackages(),"n_mobile_effect")
		then else return target end
	end,
	on_trigger = function(self,triggerEvent,player,data)
		local room = player:getRoom()
		if not string.find(room:getMode(),"p") then return end
		local x = 1
		local conv = false --(math.random() < 0.2)
		if triggerEvent == sgs.PreCardUsed or triggerEvent == sgs.CardResponded then
			local card = nil
			if triggerEvent == sgs.PreCardUsed then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			local typeid = card:getTypeId()
			if typeid == sgs.Card_TypeBasic then
				room:addPlayerMark(player,"mvpexp",x)
			elseif typeid == sgs.Card_TypeTrick then
				room:addPlayerMark(player,"mvpexp",3 * x)
			elseif typeid == sgs.Card_TypeEquip then
				room:addPlayerMark(player,"mvpexp",2 * x)
			end
			if conv and math.random() < 0.1 then
				playConversation(room,player:getGeneralName(),"#mvpuse"..math.floor(math.random(6)))
			end
		elseif triggerEvent == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not move.to or player:objectName()~=move.to:objectName()
				or (move.from and move.from:objectName() == move.to:objectName())
				or (move.to_place~=sgs.Player_PlaceHand and move.to_place~=sgs.Player_PlaceEquip)
				or room:getTag("FirstRound"):toBool() then
				return false
			end
			room:addPlayerMark(player,"mvpexp",move.card_ids:length() * x)
		elseif triggerEvent == sgs.PreDamage then
			local damage = data:toDamage()
			if damage.from then
				room:addPlayerMark(damage.from,"mvpexp",damage.damage * 5 * x)
				room:addPlayerMark(damage.to,"mvpexp",damage.damage * 2 * x)
				if conv then
					playConversation(room,damage.from:getGeneralName(),"#mvpdamage"..math.floor(math.random(6)))
				end
			end
		elseif triggerEvent == sgs.HpLost then
			local lose = data:toInt()
			room:addPlayerMark(player,"mvpexp",lose * x)
			if conv and math.random() < 0.3 then
				playConversation(room,player:getGeneralName(),"#mvplose"..math.floor(math.random(6)))
			end
		elseif triggerEvent == sgs.GameOverJudge then
			local death = data:toDeath()
			--death.who:speak("skillinvoke")
			if not death.who:isLord() then
				room:removePlayerMark(death.who,"mvpexp",100)
			else
				for _,p in sgs.qlist(room:getOtherPlayers(death.who))do
					room:addPlayerMark(p,"mvpexp",10 * x)
				end
				local damage = death.damage
				if damage and damage.from and damage.from:isAlive() and not damage.from:isLord() then
					room:addPlayerMark(damage.from,"mvpexp",5 * x)
				end
			end
			local t = getWinner(room,death.who)
			if not t then return end
			--room:getLord():speak(t)
			local players = sgs.QList2Table(room:getAlivePlayers())
			local function loser(p)
				local tt = t:split("+")
				if not table.contains(tt,p:getRole()) then return true end
				return false
			end
			for _,p in ipairs(players)do
				if loser(p) then 
					table.removeOne(players,p)
				end
			end
			local comp = function(a,b)
				return a:getMark("mvpexp") > b:getMark("mvpexp")
			end
			if #players > 1 then
				-- for _,p in ipairs(players)do
				-- 	if (swig_type(p)~="ServerPlayer *") then
				-- 		table.removeOne(players,p)
				-- 	end
				-- end
                table.sort(players,comp)
			end
			local str = players[1]:getGeneralName()
			local str2 = players[1]:screenName()
			--room:doAnimate(2,"skill=MvpAnim:"..str,str)
			local skills = players[1]:getGeneral():getVisibleSkillList()
			local skill = nil
			local word = ""
			local index = -1
			if not skills:isEmpty() then
				skill = skills:at(math.random(1,skills:length())-1)
				local sources = skill:getSources()
				if #sources > 1 then index = math.random(1,#sources) end
				word = "$" .. skill:objectName() .. (index == -1 and "" or tostring(index))
			end
			room:doAnimate(2,"skill=MobileMvp:"..str..":"..str2..":"..math.random(0,11),word)
			room:broadcastSkillInvoke("n_mobile_effect",12)
			local thread = room:getThread()
			--thread:delay(1080)
			thread:delay(1100)
			--local skills = players[1]:getGeneral():getVisibleSkillList()
			if skill then room:broadcastSkillInvoke(skill:objectName(),index) end
			thread:delay(2900)
		end
		return false
	end
}
n_anjiang:addSkill(n_mvpexperience)

sgs.LoadTranslationTable{
	["n_anjiang"] = "技能暗将",
	["n_mobile_effect"] = "手杀特效（勾选启用）",
	[":n_mobile_effect"] = "鬼晓得这些特效是怎么触发的",
	["$n_mobile_effect1"] = "癫狂屠戮！",
	["$n_mobile_effect2"] = "无双！万军取首！",
	["$n_mobile_effect3"] = "一破！卧龙出山！",
	["$n_mobile_effect4"] = "双连！一战成名！",
	["$n_mobile_effect5"] = "三连！下次一定！",
	["$n_mobile_effect6"] = "四连！天下无敌！",
	["$n_mobile_effect7"] = "五连！诛天灭地！",
	["$n_mobile_effect8"] = "六连！诛天灭地！",
	["$n_mobile_effect9"] = "七连！诛天灭地！",
	["$n_mobile_effect10"] = "医术高超~",
	["$n_mobile_effect11"] = "妙手回春~",
}
return {extension}