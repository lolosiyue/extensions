module("extensions.blood", package.seeall)
extension = sgs.Package("blood")
blood_zhaozilong=sgs.General(extension, "blood_zhaozilong", "shu", 4)

blood_gudan = sgs.CreateTriggerSkill{
	name = "blood_gudan",
	frequency = sgs.Skill_Limited, 
	events = {sgs.AskForPeaches},
	limit_mark = "@gudan",
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
			if player:askForSkillInvoke(self:objectName(), data) then
				room:addPlayerMark(player, "&"..self:objectName())
			room:broadcastSkillInvoke("blood_gudan")
		    room:notifySkillInvoked(player,self:objectName())
	        local log=sgs.LogMessage()
	        log.from=player
	        log.arg=self:objectName()
	        log.type="#TriggerSkill"
	        room:sendLog(log)
	        room:broadcastSkillInvoke(self:objectName())
            room:doLightbox("$blood_gudan",5000)
				player:loseMark("@gudan")
				player:throwAllCards()
				local maxhp = player:getMaxHp()
				local hp = math.min(1, maxhp)
				room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
				player:drawCards(4)
				room:loseMaxHp(player, 2, "blood_gudan")
		        room:handleAcquireDetachSkills(player,"-longdan")
		        room:handleAcquireDetachSkills(player, "longhun")
		        room:handleAcquireDetachSkills(player, "juejing")
		        room:setPlayerMark(player, "gudan", 1)
				if player:isChained() then
					local damage = dying_data.damage
					if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
				end
				if not player:faceUp() then
					player:turnOver()
				end
				local jsonValue = {
					10,
					player:objectName(),
					"shenzhaoyun",
					"longhun",
				}
				room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT, json.encode(jsonValue))
        room:setPlayerFlag(player, "-Global_Dying")
        local currentdying = room:getTag("CurrentDying"):toStringList()
        table.removeOne(currentdying,player:objectName())
        room:setTag("CurrentDying", sgs.QVariant(table.concat(currentdying, "|")))
			end
		end
		return false
	end, 
	can_trigger = function(self, target)
		if target then
			if target:hasSkill(self:objectName()) then
				if target:isAlive() then
					return target:getMark("@gudan") > 0
				end
			end
		end
		return false
	end
}
blood_zhaozilong:addSkill("longdan")
blood_zhaozilong:addSkill(blood_gudan)
blood_zhaozilong:addRelateSkill("longhun")
blood_zhaozilong:addRelateSkill("juejing")


blood_sunbofu=sgs.General(extension, "blood_sunbofu$", "wu", 4)

blood_sunbofu:addSkill("jiang")

blood_hjcard=sgs.CreateSkillCard{
name="blood_hj",
target_fixed=false,
will_throw=false,
filter=function(self,targets,to_select)
	return #targets==0 and  sgs.Self:canPindian(to_select) and to_select:objectName()~=sgs.Self:objectName()
end,
on_use = function(self, room, source, targets) 
		local tiger = targets[1]
		room:broadcastSkillInvoke("blood_hj")
		local success = source:pindian(tiger, "blood_hj", nil)
		if success then			
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			duel:setSkillName("blood_hj")
			if not(source:isCardLimited(duel, sgs.Card_MethodUse) or source:isProhibited(tiger, duel) ) then
				local use = sgs.CardUseStruct()
				use.card = duel
				use.from = source
				use.to:append(tiger)
				room:useCard(use)
			end
            duel:deleteLater()
		else
			room:loseHp(source, 1, true, source, "blood_hj")
		end
	end
}

blood_hj=sgs.CreateZeroCardViewAsSkill{
name="blood_hj",
view_as=function()
	return blood_hjcard:clone()
end,
enabled_at_play=function(self,player)
	return not player:hasUsed("#blood_hj") and not player:isKongcheng()
end
}


blood_sunbofu:addSkill(blood_hj)

blood_hunzi=sgs.CreateTriggerSkill{
	name = "blood_hunzi$",
  waked_skills = "yingzi,yinghun",
	frequency = sgs.Skill_Wake,
  events = {sgs.AskForPeaches},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		local source = dying_data.who
		if source:objectName() == player:objectName() then
			room:broadcastSkillInvoke("blood_hunzi")
		    room:notifySkillInvoked(player,self:objectName())
	        local log=sgs.LogMessage()
	        log.from=player
	        log.arg=self:objectName()
	        log.type="#TriggerSkill"
	        room:sendLog(log)
	        room:broadcastSkillInvoke(self:objectName())
            room:doLightbox("hunziAnimate$",5000)
				room:addPlayerMark(player, "blood_hunzi")
				player:throwAllCards()
				local maxhp = player:getMaxHp()
				local hp = math.min(1, maxhp)
				room:setPlayerProperty(player, "hp", sgs.QVariant(hp))
         room:setPlayerFlag(player, "-Global_Dying")
        local currentdying = room:getTag("CurrentDying"):toStringList()
        table.removeOne(currentdying,player:objectName())
        room:setTag("CurrentDying", sgs.QVariant(table.concat(currentdying, "|")))
				player:drawCards(3)
				if room:changeMaxHpForAwakenSkill(player, -1, self:objectName()) then
		        room:handleAcquireDetachSkills(player,"-blood_hj")
		        room:handleAcquireDetachSkills(player, "yingzi")
		        room:handleAcquireDetachSkills(player, "yinghun")
		        room:setPlayerMark(player, "hunzi", 1)
				if player:isChained() then
					local damage = dying_data.damage
					if (damage == nil) or (damage.nature == sgs.DamageStruct_Normal) then
						room:setPlayerProperty(player, "chained", sgs.QVariant(false))
					end
				end
				if not player:faceUp() then
					player:turnOver()
				end
				end
		end
		return false
	end, 
    can_wake = function(self, event, player, data, room)
        if not player:hasLordSkill(self:objectName()) then return false end
        if player:getMark("blood_hunzi") > 0 then return false end
        if player:canWake(self:objectName()) then return true end
        return true
    end,
    
}


blood_sunbofu:addSkill(blood_hunzi)

sgs.LoadTranslationTable{
["blood"]="血战包",
["blood_zhaozilong"]="赵子龙",
["#blood_zhaozilong"]="长坂坡圣骑",
["blood_gudan"]="孤胆",
["@gudan"]="孤胆",
[":blood_gudan"]="<font color=\"red\"><b>限定技，</b></font>当你进入濒死状态时，你可以弃置你区域内的牌，然后复原你的武将牌，摸四张牌体力回复至1点，并失去2点体力上限，失去“龙胆”，获得“龙魂”，“绝境”。",
["$blood_gudan"]="赤胆平乱世，龙枪定江山",
["blood_sunbofu"]="孙伯符",
["#blood_sunbofu"]="东吴奠基人",
["blood_yingyang"]="鹰扬",
[":blood_yingyang"]="<font color=\"blue\"><b>锁定技，</b></font>每当你使用（指定目标后）或被使用（成为目标后）一张【决斗】或红色【杀】时，你摸一张牌。",
["blood_hj"]="虎踞",
[":blood_hj"]="<font color=\"green\"><b>出牌阶段限一次，</b></font>你可以与一名其他角色拼点，若你赢，视为对其使用一张决斗，若你没有赢，则失去一点体力。",
["$blood_hj"]="小霸王在此，匹夫受死！",
["blood_hunzi"]="魂姿",
[":blood_hunzi"]="<font color=\"orange\"><b>主公技，</b></font><font color=\"purple\"><b>觉醒技，</b></font>当你进入濒死状态时，你须弃置你区域内的牌，复原你的武将牌，摸三张牌体力回复至1点，并失去1点体力上限，失去“虎踞”，获得“英姿”和“英魂”。",
["$blood_hunzi"]="父亲在上，魂佑江东；公瑾在旁，智定天下！",
["hunziAnimate$"]="image=image/animate/hunzi.png",



}






neo_sunce = sgs.General(extension,"neo_sunce$","qun","4")

luaxiongfengCard = sgs.CreateSkillCard{
  name = "luaxiongfeng",
  filter = function(self,targets,to_select)
     return #targets < math.max(sgs.Self:getMark(self:objectName()),1)
  end,
  feasible = function(self,targets)
     return (#targets == 1 or #targets == sgs.Self:getMark(self:objectName())) and #targets ~= 0 
  end,
  on_use = function(self,room,source,targets)
    local x = source:getMark(self:objectName())
    local choice = room:askForChoice(source,self:objectName(),"d1tx+dxt1")
    source:setTag("xiongfeng_choice",sgs.QVariant(choice))
    for _, p in ipairs(targets) do 
       room:cardEffect(self, source, p)
     end
     source:removeTag("xiongfeng_choice")
      if x > 2 then room:loseHp(source, 1, true, source, self:objectName()) end
    end,
  on_effect = function(self,effect)
    local source = effect.from
    local dest = effect.to
    local x = source:getMark(self:objectName())
    local choice = source:getTag("xiongfeng_choice"):toString()
    local room = source:getRoom()
      if choice == "d1tx" then
        dest:drawCards(1)
        x = math.min(x, dest:getCardCount(true))
        if x~=0 then  room:askForDiscard(dest, self:objectName(), x, x, false, true) end
      else
        if x ~= 0 then  dest:drawCards(x) end
        room:askForDiscard(dest, self:objectName(), 1, 1, false, true)
    end
  end 
}

luaxiongfengVS = sgs.CreateZeroCardViewAsSkill{
  name = "luaxiongfeng",
  view_as = function()
     return luaxiongfengCard:clone()
  end,
  enabled_at_play = function(self,player)
     return false
  end,
  enabled_at_response = function(self,player,pattern)
     return pattern == "@@luaxiongfeng"
  end
}

luaxiongfeng = sgs.CreateTriggerSkill{
  name = "luaxiongfeng",
  events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart},
  view_as_skill = luaxiongfengVS,
  on_trigger = function(self,event,player,data)
    if event == sgs.CardsMoveOneTime then 
      local move = data:toMoveOneTime()
      if move.from and move.from:objectName() == player:objectName() 
        and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD) 
        and player:getPhase() ~= sgs.Player_NotActive then 
        local room = player:getRoom()
        room:addPlayerMark(player,self:objectName(),move.card_ids:length())
        room:addPlayerMark(player,"&"..self:objectName().."-Clear",move.card_ids:length())

      end
    elseif event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish then 
      local room = player:getRoom()
	   local log=sgs.LogMessage()
	        log.from=player
	        log.arg= player:getMark(self:objectName())
	        log.type="#luaxiongfeng_num"
	        room:sendLog(log)
      room:askForUseCard(player, "@@luaxiongfeng", string.format("@luaxiongfeng:%s", player:getMark(self:objectName())))
      player:setMark(self:objectName(),0)
    end
  end
}
neo_sunce:addSkill(luaxiongfeng)

luaangyang = sgs.CreateTriggerSkill{
  name = "luaangyang",
  events = {sgs.TargetSpecifying,sgs.TargetConfirming},
  on_trigger = function(self,event,player,data)
    local use = data:toCardUse()
    local room = player:getRoom()
    local card = use.card 
    if (card:isKindOf("Slash") and card:isRed()) or card:isKindOf("Duel") then 
       local target = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"@luaangyang-to",true)
       if not target then return false end
       if player:isMale() then room:broadcastSkillInvoke("luaangyang",math.random(1,2)) end
       target:drawCards(1,self:objectName())
     end 
  end
}


local Skills = sgs.SkillList()
if not sgs.Sanguosha:getSkill("luaangyang") then
Skills:append(luaangyang)
end
sgs.Sanguosha:addSkills(Skills)

luajuying = sgs.CreateTriggerSkill{
  name = "luajuying$",
  frequency = sgs.Skill_Limited,
  limit_mark = "@juying",
  events = {sgs.EventPhaseStart},
  on_trigger = function(self,event,player,data)
    if player:getPhase()== sgs.Player_Start then 
     local room = player:getRoom()
     if player:askForSkillInvoke(self:objectName()) then 
      room:broadcastSkillInvoke("luajuying",1)
      room:removePlayerMark(player, "@juying")
      room:doSuperLightbox("neo_sunce", "luajuying")
      room:setPlayerProperty(player,"kingdom",sgs.QVariant("wu"))
      local qun_players = sgs.SPlayerList()
      for _, target in sgs.qlist(room:getOtherPlayers(player)) do
        if target:getKingdom() == "qun" then qun_players:append(target) end
      end
      local count = 1
      if not qun_players:isEmpty() then 
        for _, target in sgs.qlist(qun_players) do
        if room:askForChoice(target,"changeToWu","yes+no") == "yes" then 
           room:setPlayerProperty(target,"kingdom",sgs.QVariant("wu"))
           room:handleAcquireDetachSkills(target,"luaangyang")
          count = count + 1
        end
        end
      end
      room:handleAcquireDetachSkills(player,"luaangyang")
      room:loseMaxHp(player)
      player:drawCards(count,self:objectName())
    end
    end
  end,
  can_trigger = function(self,target)
    return target and target:hasSkill(self:objectName())
    and target:getMark("@juying") > 0
    and (not string.find(target:getGeneralName(),"yuanshu"))
    and (not string.find(target:getGeneral2Name(),"yuanshu"))
  end
}
  neo_sunce:addSkill(luajuying)
  neo_sunce:addRelateSkill("luaangyang")

sgs.LoadTranslationTable{ 
  ["neo_sunce"] = "孙策-新",
  ["&neo_sunce"] = "孙策-新",
  ["#neo_sunce"] = "江东奠基人",
  ["#luaxiongfeng_num"] = "本回合 %from 的弃牌数為 %arg ",
  ["luaxiongfeng"] = "雄风",
  [":luaxiongfeng"] = "回合结束阶段开始时，你可以令一名角色或X名角色进行以下操作：摸一张牌弃X张牌或摸X张牌弃一张牌（X为本回合你的弃牌数），若X大于2，你失去1点体力。",
  ["d1tx"] = "摸一张牌弃X张牌",
  ["dxt1"] = "摸X张牌弃一张牌",
  ["luaangyang"] = "昂扬",
  [":luaangyang"] = "每当你使用或成为一张决斗或红色杀的目标后，你可以令一名角色摸一张牌。",
  ["@luaangyang-to"] = "请选择【昂扬】的对象，可以不选",
  ["luajuying"] = "聚英",
  [":luajuying"] = "<font color=\"orange\"><b>主公技，</b></font><font color=\"red\"><b>限定技，</b></font>准备阶段开始时，若你不为袁术，你可以将势力变为吴，场上所有存活的群势力角色可以选择与的你势力相同，若如此做，你与以此法改变势力的角色获得“昂扬”，然后你减1点体力上限，摸X张牌。（X为这些角色的数量）",
  ["$luajuying1"] = "属于我们的时代开始了！",
  ["$luaxiongfeng1"] = "吾乃江东小霸王孙伯符！",
  ["$luaxiongfeng2"] = "义兵再起，暴乱必除！",
  ["$luaangyang1"] = "江东子弟，何惧于天下！",
  ["$luaangyang2"] = "所向披靡，进退自如！",
  ["@luaxiongfeng"] = "请选择【雄风】的对象（一名角色或 %src 名角色），可以不选",
  ["~luaxiongfeng"] = "选择一名玩家->点击确定",
  ["changeToWu"] = "将势力改为“吴”",
}