local extension = sgs.Package("newgenerals",sgs.Package_GeneralPack)

--统一进行语音绑定
--谋周瑜，谋孙策
sgs.Sanguosha:setAudioType("mobilemou_zhouyu","mouyingzi","1,2")
sgs.Sanguosha:setAudioType("mobilemou_sunce","mouyingzi","3,4")
sgs.Sanguosha:setAudioType("mobilemou_sunces","mouyingzi","3,4")

sgs.Sanguosha:setAudioType("mobilemou_sunce","yinghun","10,11")
sgs.Sanguosha:setAudioType("mobilemou_sunces","yinghun","10,11")
--吕玲绮，吕布
sgs.Sanguosha:setAudioType("shenlvbu2","shenwei","1")
sgs.Sanguosha:setAudioType("lvlingqi","shenwei","2,3")

sgs.Sanguosha:setAudioType("lvbu","wushuang","1,2")
sgs.Sanguosha:setAudioType("shenlvbu","wushuang","1,2")
sgs.Sanguosha:setAudioType("shenlvbu2","wushuang","1,2")
sgs.Sanguosha:setAudioType("shenlvbu3","wushuang","1,2")
sgs.Sanguosha:setAudioType("sp_shenlvbuu","wushuang","1,2")
sgs.Sanguosha:setAudioType("nos_lvbu","wushuang","3,4")
sgs.Sanguosha:setAudioType("lvlingqi","wushuang","5,6")

--华雄
sgs.Sanguosha:setAudioType("tenyear_huaxiong","tenyearyaowu","1,2")
sgs.Sanguosha:setAudioType("mobilemobilemou_huaxiong","tenyearyaowu","3,4")
--刘表
sgs.Sanguosha:setAudioType("liubiao","zishou","1,2")
sgs.Sanguosha:setAudioType("new_liubiao","zishou","1,2")
sgs.Sanguosha:setAudioType("ol_liubiao","zishou","1,2")
sgs.Sanguosha:setAudioType("mobile_liubiao","zishou","4,5")
--简雍
sgs.Sanguosha:setAudioType("jianyong","zongshih","1,2")
sgs.Sanguosha:setAudioType("tenyear_jianyong","zongshih","3,4")
--黄盖
sgs.Sanguosha:setAudioType("huanggai","zhaxiang","1,2")
--李儒
sgs.Sanguosha:setAudioType("liru","juece","1,2")
sgs.Sanguosha:setAudioType("tenyear_liru","juece","3,4")
--荀攸
sgs.Sanguosha:setAudioType("xunyou","qice","1,2")
sgs.Sanguosha:setAudioType("tenyear_xunyou","qice","3,4")
--沮授
sgs.Sanguosha:setAudioType("jushou","shibei","1,2")
sgs.Sanguosha:setAudioType("mobile_jushou","shibei","3,4")
--蔡夫人
sgs.Sanguosha:setAudioType("caifuren","xianzhou","1,2")
sgs.Sanguosha:setAudioType("mobile_caifuren","xianzhou","3,4")
--陈群
sgs.Sanguosha:setAudioType("chenqun","faen","1,2")
sgs.Sanguosha:setAudioType("mobile_chenqun","faen","3,4")
--邓艾
sgs.Sanguosha:setAudioType("dengai","zaoxian","1,2")
sgs.Sanguosha:setAudioType("dengai","jixi","1,2")
sgs.Sanguosha:setAudioType("ol_dengai","jixi","3,4")
sgs.Sanguosha:setAudioType("mobile_dengai","zaoxian","3,4")
sgs.Sanguosha:setAudioType("mobile_dengai","jixi","5,6")
--钟会
sgs.Sanguosha:setAudioType("zhonghui","zili","1,2")
sgs.Sanguosha:setAudioType("mobile_zhonghui","zili","3,4")
sgs.Sanguosha:setAudioType("zhonghui","paiyi","1,2")
sgs.Sanguosha:setAudioType("mobile_zhonghui","paiyi","3,4")

sgs.Sanguosha:setAudioType("tenyear_sunquan","tenyearzhiheng","1,2")

sgs.Sanguosha:setAudioType("nos_diaochan","biyue","1,2")
sgs.Sanguosha:setAudioType("diaochan","biyue","3,4")

sgs.Sanguosha:setAudioType("ol_pengyang","cunmu","3,4")

sgs.Sanguosha:setAudioType("keolmou_jiangwei","zhaxiang","3")
sgs.Sanguosha:setAudioType("keolmou_jiangwei","kunfen","3")

--武将

local function sendZhenguLog(player,skill_name,broadcast)
	local log = sgs.LogMessage()
	log.type = "#ZhenguEffect"
	log.from = player
	log.arg = skill_name
	player:getRoom():sendLog(log)
	if broadcast~=false then
		player:peiyin(skill_name)
	end
end

local tenyear_xd = sgs.Sanguosha:getPackage("tenyear_xd")
--潘淑[十周年]
tenyear_panshu = sgs.General(tenyear_xd,"tenyear_panshu","wu",3,false)

zhiren = sgs.CreateTriggerSkill {
name = "zhiren",
events = {sgs.CardUsed,sgs.CardResponded},
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	if player:hasFlag("CurrentPlayer") or player:getMark("&yaner-Self"..sgs.Player_RoundStart.."Clear") > 0 then
		local card
		if event == sgs.CardUsed then
			card = data:toCardUse().card
		else
			local res = data:toCardResponse()
			if not res.m_isUse then return false end
			card = res.m_card
		end
		if not card or card:isVirtualCard() then return false end
		player:addMark("zhi0renRecord-Clear")
		if player:getMark("zhi0renRecord-Clear")==1 and player:getMark("zhirenUsed-Clear")<1
		and player:hasSkill(self) and player:askForSkillInvoke(self,data) then
			player:peiyin(self)
			player:addMark("zhirenUsed-Clear")
			local name_num = card:nameLength()
			if name_num >= 1 and player:isAlive() then
				room:askForGuanxing(player,room:getNCards(name_num),0)
			end
			if name_num >= 2 and player:isAlive() then
				local targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if player:canDiscard(p,"e") then
						targets:append(p)
					end
				end
				local to = room:askForPlayerChosen(player,targets,self:objectName(),"@zhiren-equip")
				if to then
					room:doAnimate(1,player:objectName(),to:objectName())
					if player:canDiscard(to,"e") then
						local id = room:askForCardChosen(player,to,"e",self:objectName(),false,sgs.Card_MethodDiscard)
						room:throwCard(id,to,player)
					end
				end
				if player:isDead() then return false end
				targets = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if player:canDiscard(p,"j") then
						targets:append(p)
					end
				end
				local to = room:askForPlayerChosen(player,targets,"zhiren_judge","@zhiren-judge")
				if to then
					room:doAnimate(1,player:objectName(),to:objectName())
					if player:canDiscard(to,"j") then
						local id = room:askForCardChosen(player,to,"j",self:objectName(),false,sgs.Card_MethodDiscard)
						room:throwCard(id,to,player)
					end
				end
			end
			if name_num >= 3 and player:isAlive() then
				room:recover(player,sgs.RecoverStruct(self:objectName()))
			end
			if name_num >= 4 and player:isAlive() then
				player:drawCards(3,self:objectName())
			end
		end
	end
	return false
end
}

yaner = sgs.CreateTriggerSkill {
name = "yaner",
events = sgs.CardsMoveOneTime,
on_trigger = function(self,event,player,data,room)
	if not room:hasCurrent() then return false end
	local move = data:toMoveOneTime()
	if not move.from or move.from:objectName() == player:objectName() or move.from:getPhase() ~= sgs.Player_Play or not move.is_last_handcard or
		not move.from_places:contains(sgs.Player_PlaceHand) or move.from:isDead() then return false end
	
	local from = room:findPlayerByObjectName(move.from:objectName())
	if not from or from:isDead() then return false end
	
	for _,p in sgs.qlist(room:getOtherPlayers(from))do
		if from:isDead() then return false end
		if p:isDead() or not p:hasSkill(self) or p:getMark("yanerUsed-Clear") > 0 then continue end
		if not p:askForSkillInvoke(self,from) then continue end
		p:peiyin(self)
		p:addMark("yanerUsed-Clear")
		local targets = sgs.SPlayerList(),p_list,f_list
		targets:append(p)
		targets:append(from)
		room:sortByActionOrder(targets)
		if targets:first() == from then
			f_list = from:drawCardsList(2,self:objectName())
			p_list = p:drawCardsList(2,self:objectName())
		else
			p_list = p:drawCardsList(2,self:objectName())
			f_list = from:drawCardsList(2,self:objectName())
		end
		if p:isAlive() and p_list:length() == 2 then
			if sgs.Sanguosha:getCard(p_list:first()):getTypeId() == sgs.Sanguosha:getCard(p_list:last()):getTypeId() then
				local phase = sgs.Player_RoundStart
				room:setPlayerMark(p,"&yaner-Self"..phase.."Clear",1)
			end
		end
		if from:isAlive() and f_list:length() == 2 then
			if sgs.Sanguosha:getCard(f_list:first()):getTypeId() == sgs.Sanguosha:getCard(f_list:last()):getTypeId() then
				room:recover(from,sgs.RecoverStruct(self:objectName(),p))
			end
		end
	end
	return false
end
}

tenyear_panshu:addSkill(zhiren)
tenyear_panshu:addSkill(yaner)

--神许褚(神·武)
th_shenxuchu = sgs.General(tenyear_xd,"th_shenxuchu","god",5,true)

thzhengqing = sgs.CreateTriggerSkill{
	name = "thzhengqing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage,sgs.EventPhaseChanging,sgs.RoundEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damage then
			local damage = data:toDamage()
			room:addPlayerMark(player,"thzhengqingDMG-Clear",damage.damage)
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _,p in sgs.qlist(room:getAllPlayers())do
				local n,m = p:getMark("thzhengqingDMG-Clear"),p:getMark("thzhengqingDMGrecord_lun")
				if n <= m then break end
				room:setPlayerMark(p,"thzhengqingDMGrecord_lun",n)
				local sxc = room:findPlayerBySkillName(self:objectName())
				if sxc then room:setPlayerMark(p,"&thzhengqingDMGrecord_lun",n) end --方便玩家查看用
			end
		elseif event == sgs.RoundEnd then
			if player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				local n = player:getMark("thzhengqingDMGrecord_lun")
				for _,p in sgs.qlist(room:getAllPlayers())do
					p:loseAllMarks("&thQing")
					local x = p:getMark("thzhengqingDMGrecord_lun")
					if x>n then n = x end
				end
				local m = room:getTag("thzhengqingDMGrecord"):toInt()
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:getMark("thzhengqingDMGrecord_lun")>=n then
						p:gainMark("&thQing",n)
						if p==player and n>=m then
							room:drawCards(p,math.min(n,5),self:objectName())
						else
							room:drawCards(p,1,self:objectName())
							room:drawCards(player,1,self:objectName())
						end
					end
				end
				room:setTag("thzhengqingDMGrecord",sgs.QVariant(n))
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
th_shenxuchu:addSkill(thzhengqing)
thzhuangpoVS = sgs.CreateOneCardViewAsSkill{
    name = "thzhuangpo",
	view_filter = function(self,to_select)
	    local des = to_select:getDescription()
		return string.find(des,"杀】")
	end,
	view_as = function(self,card)
	    local zp_card = sgs.Sanguosha:cloneCard("duel")
		zp_card:setSkillName(self:objectName())
		zp_card:addSubcard(card)
		return zp_card
	end,
}
thzhuangpo = sgs.CreateTriggerSkill{
	name = "thzhuangpo",
	events = {sgs.TargetSpecified,sgs.ConfirmDamage},
	view_as_skill = thzhuangpoVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Duel") and table.contains(use.card:getSkillNames(),self:objectName())
			and player:hasSkill(self:objectName()) then
				for _,p in sgs.qlist(use.to)do
					local _data = sgs.QVariant()
					_data:setValue(p)
					local count = player:getMark("&thQing")
					if count>0 and player:askForSkillInvoke(self,_data) then
						local choices = {}
						for i = 1,count do
							table.insert(choices,i)
						end
						room:broadcastSkillInvoke(self:objectName())
						local choice = room:askForChoice(player,"thzhuangpo",table.concat(choices,"+"),_data)
						count = tonumber(choice)
						player:loseMark("&thQing",count)
						room:askForDiscard(p,self:objectName(),count,count,false,true)
						if p:getMark("&thQing") > 0 then
							room:setCardFlag(use.card,"thzhuangpoDB")
						end
					end
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Duel")
			and table.contains(damage.card:getSkillNames(),self:objectName())
			and damage.card:hasFlag("thzhuangpoDB") then
				local log = sgs.LogMessage()
				log.type = "$thzhuangpoDMG"
				log.card_str = damage.card:toString()
				room:sendLog(log)
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
th_shenxuchu:addSkill(thzhuangpo)


sgs.Sanguosha:setPackage(tenyear_xd)

local yong = sgs.Sanguosha:getPackage("mobileyong")

--手杀文鸯
mobile_wenyang = sgs.General(yong,"mobile_wenyang","wei+wu",4)

local function quediCandiscard(player)
	for _,c in sgs.qlist(player:getHandcards())do
		if c:isKindOf("BasicCard") and player:canDiscard(player,c:getEffectiveId()) then
			return true
		end
	end
end

quedi = sgs.CreateTriggerSkill {
name = "quedi",
events = {sgs.TargetSpecified,sgs.ConfirmDamage},
can_trigger = function(self,player)
	return player ~= nil
end,
on_trigger = function(self,event,player,data,room)
	if event==sgs.TargetSpecified then
		if player:getMark("quediUsed-Clear") > player:getMark("&mobilechoujue-Clear") then return false end
		if not room:hasCurrent() or not player:hasSkill(self) then return false end
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") and not use.card:isKindOf("Duel") then return false end
		if use.to:length() ~= 1 then return false end
		local choices,to = {},use.to:first()
		if not to:isKongcheng() then
			table.insert(choices,"obtain="..to:objectName())
		end
		if quediCandiscard(player) then
			table.insert(choices,"damage")
		end
		table.insert(choices,"beishui")
		if not player:askForSkillInvoke(self,to) then return false end
		player:peiyin(self)
		player:addMark("quediUsed-Clear")
		local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"),data)
		if choice=="beishui" then
			room:loseMaxHp(player,1,"quedi")
		end
		if player:isDead() then return false end
		if choice~="damage" and not to:isKongcheng() then
			local id = room:askForCardChosen(player,to,"h",self:objectName())
			player:obtainCard(sgs.Sanguosha:getCard(id),false)
		end
		if player:isDead() then return false end
		if not choice:startsWith("obtain") and quediCandiscard(player) then
			room:askForDiscard(player,self:objectName(),1,1,false,false,"@quedi-basic","BasicCard")
			room:setCardFlag(use.card,"quediDamage")
		end
	else
		local damage = data:toDamage()
		if damage.card and damage.card:hasFlag("quediDamage") then
			player:damageRevises(data,1)
		end
	end
	return false
end
}

mobilechoujue = sgs.CreateTriggerSkill{
name = "mobilechoujue",
events = sgs.Death,
frequency = sgs.Skill_Compulsory,
on_trigger = function(self,event,player,data,room)
	local death = data:toDeath()
	if death.who == player then return false end
	if death.damage and death.damage.from and death.damage.from:objectName() == player:objectName() then
		room:sendCompulsoryTriggerLog(player,self)
		room:gainMaxHp(player,1,"mobilechoujue")
		player:drawCards(2,self:objectName())
		if room:hasCurrent() and player:isAlive() then
			room:addPlayerMark(player,"&mobilechoujue-Clear")
		end
	end
	return false
end
}

chuifengCard = sgs.CreateSkillCard {
name = "chuifengCard",
filter = function(self,targets,to_select,player)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	then return end
	local card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
	if card then
		card:deleteLater()
		if card:targetFixed() then return end
		card:addSubcard(self)
		card:setSkillName("chuifeng")
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets)do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets,to_select,player)
    end
end,
feasible = function(self,targets,player)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	then return true end
	local card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
	if card then
		card:deleteLater()
		if card:targetFixed() then return true end
		card:addSubcard(self)
		card:setSkillName("chuifeng")
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets)do
			qtargets:append(p)
		end
		return card:targetsFeasible(qtargets,player)
    end
end,
on_validate = function(self,cardUse)
	local source = cardUse.from
	local room = source:getRoom()
	local user_string = self:getUserString()	
	room:loseHp(sgs.HpLostStruct(source,1,"chuifeng",source))
	if source:isDead() then return nil end
	
    local use_card = sgs.Sanguosha:cloneCard(user_string)
	if not use_card then return nil end
    use_card:setSkillName("chuifeng")
    use_card:deleteLater()
    return use_card
end
}

chuifengvs = sgs.CreateZeroCardViewAsSkill{
name = "chuifeng",
view_as = function()
	local c = chuifengCard:clone()
	c:setUserString("duel")
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		c:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
	end
	return c
end,
enabled_at_play = function(self,player)
	return player:getKingdom() == "wei"
	and player:getMark("usetimeschuifeng-PlayClear")<2
	and player:getMark("banchuifeng-Clear")<1
end,
enabled_at_response = function(self,player,pattern)
	if player:getMark("usetimeschuifeng-PlayClear")>1 or player:getMark("banchuifeng-Clear")>0
	or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	or player:getPhase()~=sgs.Player_Play or player:getKingdom() ~= "wei"
	then return false end
	return string.find(pattern,"Duel")
end
}

chuifeng = sgs.CreateTriggerSkill{
	name = "chuifeng",
	view_as_skill = chuifengvs,
	events = {sgs.CardUsed,sgs.DamageInflicted,sgs.CardFinished},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"chuifeng") then
				room:removePlayerMark(use.from,"chuifengfrom-Clear")
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"chuifeng") then
				room:addPlayerMark(use.from,"usetimeschuifeng-PlayClear")
				room:addPlayerMark(use.from,"chuifengfrom-Clear")
			end
		end
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),"chuifeng")
			and damage.to:getMark("chuifengfrom-Clear")>0 then
				room:setPlayerMark(damage.to,"banchuifeng-Clear",1)
				room:sendCompulsoryTriggerLog(damage.to,"chuifeng")
				return player:damageRevises(data,-damage.damage)
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end
}

chongjianslash = sgs.CreateTargetModSkill{
	name = "#chongjianslash",
	distance_limit_func = function(self,from,card,to)
		if table.contains(card:getSkillNames(), "chongjian")
		or table.contains(card:getSkillNames(), "olluanwu")
		or table.contains(card:getSkillNames(), "qingshu_tianshu0")
		or to and to:getMark("&stscdlwei")<1 and from:hasSkill("dulie")
		or to and to:getMark("&mouwushengTarget+#"..from:objectName().."-PlayClear")>0
		or from:getWeapon() and from:hasSkill("moupaoxiao")
		then return 999 end
		return 0
	end,
	extra_target_func = function(self,from,card)
		local n = 0
		if from:hasSkill("keolguangao") then n = n+1 end
		if (table.contains(card:getSkillNames(), "keolkenshang") or card:hasFlag("keolkenshang"))
		and from:hasSkill("keolkenshang") then n = n+card:subcardsLength()-1 end
		return n
	end,
	residue_func = function(self,from,card,to)
		if from:hasSkill("shenzhuo")
		or from:hasSkill("moupaoxiao")
		or to and to:getMark("&mouwushengTarget+#"..from:objectName().."-PlayClear")>0
		then return 999 end
		local n = 0
		if from:getPhase() == sgs.Player_Play then
			n = n+from:getMark("&olxingbu3-SelfClear")-from:getMark("&olxingbu2-SelfClear")
			n = n+from:getMark("yilie_slash-PlayClear")
			n = n+from:getMark("shunshi_play-PlayClear")
			n = n+from:getMark("&xbwuxinglianzhu-SelfClear")-from:getMark("&xbyinghuoshouxin-SelfClear")
			n = n+from:getMark("&keoldouchan")
		end
		if from:hasSkill("keolgangshu") then
			n = n+from:getMark("keolgangshuSha")
		end
		return n
	end
}

chongjianCard = sgs.CreateSkillCard {
name = "chongjianCard",
handling_method = sgs.Card_MethodUse,
filter = function(self,targets,to_select,player)
	local card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
	if card then
		card:deleteLater()
		if card:targetFixed() then return end
		card:addSubcard(self)
		card:setSkillName("chongjian")
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets)do
			qtargets:append(p)
		end
		return card:targetFilter(qtargets,to_select,player)
    end
end,
feasible = function(self,targets,player)
	local card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
	if card then
		card:deleteLater()
		if card:targetFixed() then return true end
		card:addSubcard(self)
		card:setSkillName("chongjian")
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets)do
			qtargets:append(p)
		end
		return card:targetsFeasible(qtargets,player)
    end
end,
on_validate = function(self,cardUse)
	local source = cardUse.from
	local room = source:getRoom()
	local user_string = self:getUserString()
	if (string.find(user_string,"slash") or string.find(user_string,"Slash"))
	and sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
        local slashs = sgs.Sanguosha:getSlashNames()
        user_string = room:askForChoice(source,"chongjian",table.concat(slashs,"+"))
    end
    local use_card = sgs.Sanguosha:cloneCard(user_string)
	if not use_card then return nil end
    use_card:setSkillName("chongjian")
	use_card:addSubcard(self)
    use_card:deleteLater()
    return use_card
end,
on_validate_in_response = function(self,source)
	local room = source:getRoom()
	local user_string = self:getUserString()
	if user_string == "peach+analeptic" then
        user_string = "analeptic"
	end
	local use_card = sgs.Sanguosha:cloneCard(user_string)
	if not use_card then return nil end
    use_card:setSkillName("chongjian")
	use_card:addSubcard(self)
    use_card:deleteLater()
    return use_card
end
}

chongjianvs = sgs.CreateOneCardViewAsSkill{
name = "chongjian",
response_or_use = true,
filter_pattern = "EquipCard",
view_as = function(self,card)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
        local c = chongjianCard:clone()
		c:addSubcard(card)
		c:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
		return c
	end
	local cj = sgs.Self:getTag("chongjian"):toCard()
	if cj and cj:isAvailable(sgs.Self) then
		local c = chongjianCard:clone()
		c:setUserString(cj:objectName())
		c:addSubcard(card)
		return c
	end
end,
enabled_at_play = function(self,player)
	return player:getKingdom() == "wu"
	and (sgs.Slash_IsAvailable(player) or sgs.Analeptic_IsAvailable(player))
end,
enabled_at_response = function(self,player,pattern)
	if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	or player:getKingdom() ~= "wu" then return false end
	return string.find(pattern,"slash") or string.find(pattern,"Slash") or string.find(pattern,"analeptic")
end
}
chongjian = sgs.CreateTriggerSkill{
	name = "chongjian",
	view_as_skill = chongjianvs,
	waked_skills = "#chongjianslash",
	events = {sgs.CardUsed,sgs.Damage},
	on_trigger = function(self,event,player,data,room)
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),"chongjian") then
				local dc = dummyCard()
				for i = 1,damage.damage do
					if damage.to:getEquips():length()>dc:subcardsLength() then
						local id = room:askForCardChosen(player,damage.to,"e",self:objectName(),false,sgs.Card_MethodNone,dc:getSubcards())
						if id>-1 then dc:addSubcard(id) else break end
					end
				end
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,damage.from:objectName(),"chongjian","")
				room:obtainCard(player,dc,reason)
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"chongjian") then
				room:setCardFlag(use.card,"SlashIgnoreArmor")
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end
}
chongjian:setJuguanDialog("all_slashs,analeptic")

mobile_wenyang:addSkill(quedi)
mobile_wenyang:addSkill(mobilechoujue)
mobile_wenyang:addSkill(chuifeng)
mobile_wenyang:addSkill(chongjian)
mobile_wenyang:addSkill(chongjianslash)

--袁涣
yuanhuan = sgs.General(yong,"yuanhuan","wei",3)

qingjue = sgs.CreateTriggerSkill{
name = "qingjue",
events = sgs.TargetSpecifying,
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	local use = data:toCardUse()
	if use.card:isKindOf("SkillCard") or use.to:length() ~= 1 then return false end
	local to = use.to:first()
	if player:getHp() <= to:getHp() or to:hasFlag("Global_Dying") then return false end
	for _,p in sgs.qlist(room:getOtherPlayers(player))do
		if p:isDead() or not p:hasSkill(self) or p:objectName() == to:objectName() or p:getMark("qingjue_lun") > 0 then return false end
		if not p:askForSkillInvoke(self,data) then continue end
		p:peiyin(self)
		room:addPlayerMark(p,"qingjue_lun")
		p:drawCards(1,self:objectName())
		if p:canPindian(player) then
			if p:pindian(player,self:objectName()) then
				use.to = sgs.SPlayerList()
				data:setValue(use)
			else
				use.to:removeOne(to)
				use.to:append(p)
				data:setValue(use)
				--room:getThread():trigger(sgs.TargetSpecifying,room,player,data)
			end
		end
		break
	end
	return false
end
}

fengjie = sgs.CreatePhaseChangeSkill{
name = "fengjie",
frequency = sgs.Skill_Compulsory,
on_phasechange = function(self,player,room)
	if player:getPhase() ~= sgs.Player_Start then return false end
	local t = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@fengjie-invoke",false,true)
	player:peiyin(self)
	room:setPlayerMark(t,"&fengjie+#"..player:objectName(),1)
	local tag = sgs.QVariant()
	tag:setValue(t)
	player:setTag("FengjieTarget",tag)
	return false
end
}

fengjieEffect = sgs.CreateTriggerSkill{
name = "#fengjieEffect",
events = {sgs.EventPhaseStart,sgs.Death},
can_trigger = function(self,player)
	return player
end,
on_trigger = function(self,event,player,data,room)
	if event == sgs.EventPhaseStart then
		if player:getPhase() == sgs.Player_RoundStart then
			player:removeTag("FengjieTarget")
			for _,p in sgs.qlist(room:getAllPlayers())do
				room:setPlayerMark(p,"&fengjie+#"..player:objectName(),0)
			end
		elseif player:getPhase() == sgs.Player_Finish then
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:isDead() then continue end
				local t = p:getTag("FengjieTarget"):toPlayer()
				if not t or t:isDead() then continue end
				
				local hand = p:getHandcardNum()
				local hp = t:getHp()
				if hand > hp and p:canDiscard(p,"h") then
					sendZhenguLog(p,"fengjie")
					room:askForDiscard(p,"fengjie",hand - hp,hand - hp)
				elseif hand < hp then
					hp = math.min(4,hp)
					if hp > hand then
						sendZhenguLog(p,"fengjie")
						p:drawCards(hp - hand,"fengjie")
					end
				end
			end
		end
	else
		local death = data:toDeath()
		local who = death.who
		if who:objectName() ~= player:objectName() then return false end
		who:removeTag("FengjieTarget")
		for _,p in sgs.qlist(room:getAllPlayers())do
			room:setPlayerMark(p,"&fengjie+#"..who:objectName(),0)
		end
	end
	return false
end
}

yuanhuan:addSkill(qingjue)
yuanhuan:addSkill(fengjie)
yuanhuan:addSkill(fengjieEffect)
yong:insertRelatedSkills("fengjie","#fengjieEffect")

--宗预
zongyu = sgs.General(yong,"zongyu","shu",3)

local MoveEJDisabledList = function(player,target)
	local ids = sgs.IntList()
	for _,c in sgs.qlist(target:getEquips())do
		local n = c:getRealCard():toEquipCard():location()
		if player:getEquip(n) or not player:hasEquipArea(n) then
			ids:append(c:getEffectiveId())
		end
	end
	for _,c in sgs.qlist(target:getJudgingArea())do
		if player:containsTrick(c:objectName()) then --target:isProhibited(player,c)
			ids:append(c:getEffectiveId())
		end
	end
	return ids
end

zhibian = sgs.CreatePhaseChangeSkill{
name = "zhibian",
on_phasechange = function(self,player,room)
	if player:getPhase() ~= sgs.Player_Start then return false end
	local sp = sgs.SPlayerList()
	for _,p in sgs.qlist(room:getOtherPlayers(player))do
		if player:canPindian(p) then
			sp:append(p)
		end
	end
	if sp:isEmpty() then return false end
	local t = room:askForPlayerChosen(player,sp,self:objectName(),"@zhibian-invoke",true,true)
	if not t then return false end
	player:peiyin(self)
	
	if player:pindian(t,self:objectName()) then
		local choices,data,ids = {},sgs.QVariant(),MoveEJDisabledList(player,t)
		data:setValue(t)
		if t:getCards("ej"):length() - ids:length() > 0 then
			table.insert(choices,"move="..t:objectName())
		end
		if player:isWounded() then
			table.insert(choices,"recover")
		end
		table.insert(choices,"beishui")
		table.insert(choices,"cancel")
		
		local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"),data)
		if choice == "cancel" then return false end
		if choice == "recover" then
			room:recover(player,sgs.RecoverStruct(self:objectName(),player))
		elseif choice:startsWith("move") then
			local id = room:askForCardChosen(player,t,"ej",self:objectName(),false,sgs.Card_MethodNone,ids)
			local place = room:getCardPlace(id)
			room:moveCardTo(sgs.Sanguosha:getCard(id),player,place)
		else
			room:setPlayerMark(player,"&zhibian",1)
			if t:getCards("ej"):length() - ids:length() > 0 and player:isAlive() and t:isAlive() then
				local id = room:askForCardChosen(player,t,"ej",self:objectName(),false,sgs.Card_MethodNone,ids)
				local place = room:getCardPlace(id)
				room:moveCardTo(sgs.Sanguosha:getCard(id),player,place)
			end
			if player:isAlive() and player:isWounded() then
				room:recover(player,sgs.RecoverStruct(self:objectName(),player))
			end
		end
	else
		room:loseHp(sgs.HpLostStruct(player,1,"zhibian",player))
	end
	return false
end
}

zhibianSkip = sgs.CreateTriggerSkill{
name = "#zhibianSkip",
events = sgs.EventPhaseChanging,
can_trigger = function(self,player)
	return player and player:isAlive() and player:getMark("&zhibian") > 0
end,
on_trigger = function(self,event,player,data,room)
	if data:toPhaseChange().to ~= sgs.Player_Draw then return false end
	if player:isSkipped(sgs.Player_Draw) then return false end
	room:setPlayerMark(player,"&zhibian",0)
	sendZhenguLog(player,"zhibian")
	player:skip(sgs.Player_Draw)
	return false
end
}

yuyanzy = sgs.CreateTriggerSkill{
name = "yuyanzy",
events = sgs.TargetConfirming,
frequency=sgs.Skill_Compulsory,
on_trigger=function(self,event,player,data,room)
	local use = data:toCardUse()
	if not use.card:isKindOf("Slash") or use.card:isVirtualCard() then return false end
	if use.from:getHp() <= player:getHp() then return false end
	room:sendCompulsoryTriggerLog(player,self)
	local num = use.card:getNumber()+1
	
	if num >= 13 or use.from:isNude() then
		use.to:removeOne(player)
		data:setValue(use)
		return false
	end
	
	local card = room:askForCard(use.from,".|.|"..num.."~13","@yuyanzy-give:"..player:objectName().."::"..num,data,sgs.Card_MethodNone)
	if card then
		room:giveCard(use.from,player,card,self:objectName(),true)
	else
		use.to:removeOne(player)
		data:setValue(use)
	end
	return false
end
}

zongyu:addSkill(zhibian)
zongyu:addSkill(zhibianSkip)
zongyu:addSkill(yuyanzy)
yong:insertRelatedSkills("zhibian","#zhibianSkip")

--陈武＆董袭
mobile_chenwudongxi = sgs.General(yong,"mobile_chenwudongxi","wu",4)

yilie = sgs.CreatePhaseChangeSkill{
name = "yilie",
frequency = sgs.Skill_Frequent,
on_phasechange = function(self,player,room)
	if player:getPhase() ~= sgs.Player_Play then return false end
	if not player:askForSkillInvoke(self) then return false end
	player:peiyin(self)
	
	local choice = room:askForChoice(player,self:objectName(),"slash+draw+beishui")
	local log = sgs.LogMessage()
	log.from = player
	log.type = "#FumianFirstChoice"
	log.arg = "yilie:"..choice
	room:sendLog(log)
	
	if choice == "slash" then
		room:addPlayerMark(player,"yilie_slash-PlayClear")
	elseif choice == "draw" then
		room:addPlayerMark(player,"yilie_draw-PlayClear")
	else
		room:loseHp(sgs.HpLostStruct(player,1,"yilie",player))
		if player:isDead() then return false end
		room:addPlayerMark(player,"yilie_slash-PlayClear")
		room:addPlayerMark(player,"yilie_draw-PlayClear")
	end
	return false
end
}

yilieSlash = sgs.CreateTriggerSkill{
name = "#yilieSlash",
events = sgs.SlashMissed,
can_trigger = function(self,player)
	return player and player:isAlive() and player:getMark("yilie_draw-PlayClear") > 0 and player:getPhase() == sgs.Player_Play
end,
on_trigger = function(self,event,player,data,room)
	local mark = player:getMark("yilie_draw-PlayClear")
	for i = 1,mark do
		if player:isDead() then return false end
		sendZhenguLog(player,"yilie")
		player:drawCards(1,"yilie")
	end
	return false
end
}

mobilefenmingCard = sgs.CreateSkillCard{
name = "mobilefenming",
filter = function(self,targets,to_select,player)
	return to_select:getHp() <= player:getHp() and #targets == 0
end,
on_effect = function(self,effect)
	local from,to,room = effect.from,effect.to,effect.from:getRoom()
	if to:isDead() then return end
	if to:isChained() then
		if from:isDead() then return end
		local flags = "he"
		if from:objectName() == to:objectName() then flags = "e" end
		if to:getCards(flags):length() <= 0 then return end
		local id = room:askForCardChosen(from,to,flags,"mobilefenming")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,from:objectName())
		room:obtainCard(effect.from,sgs.Sanguosha:getCard(id),reason,false)
	else
		room:setPlayerChained(to)
	end
end
}

mobilefenming = sgs.CreateZeroCardViewAsSkill{
name = "mobilefenming",
view_as = function()
	return mobilefenmingCard:clone()
end,
enabled_at_play = function(self,player)
	return not player:hasUsed("#mobilefenming")
end
}

mobile_chenwudongxi:addSkill(yilie)
mobile_chenwudongxi:addSkill(yilieSlash)
mobile_chenwudongxi:addSkill(mobilefenming)
yong:insertRelatedSkills("yilie","#yilieSlash")

--王双
yong_wangshuang = sgs.General(yong,"yong_wangshuang","wei",4)
yongyiyong = sgs.CreateTriggerSkill{
    name = "yongyiyong",
	frequency = sgs.Skill_Frequent,
	events = {sgs.Damaged,sgs.ConfirmDamage},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event==sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash") and damage.from and damage.from ~= player
			and room:getCardPlace(damage.card:getEffectiveId())==sgs.Player_PlaceTable
			and player:askForSkillInvoke(self,ToData(damage.from)) then
				room:broadcastSkillInvoke(self:objectName())
				room:obtainCard(player,damage.card)
				local dc = dummyCard()
				dc:setSkillName("_"..self:objectName())
				dc:addSubcards(damage.card:getSubcards())
				if damage.from:isAlive() and player:canSlash(damage.from,dc,false) then
					room:useCard(sgs.CardUseStruct(dc,player,damage.from))
				end
			end
		else
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash")
			and table.contains(damage.card:getSkillNames(),self:objectName())
			and damage.to:getEquip(0)==nil then
				player:damageRevises(data,1)
			end
		end
	end,
}
yong_wangshuang:addSkill(yongyiyong)
yongshanxieCard = sgs.CreateSkillCard{
    name = "yongshanxieCard",
	target_fixed = true,
	on_use = function(self,room,source,targets)
		for _,wid in sgs.qlist(room:getDrawPile())do
			local wp = sgs.Sanguosha:getCard(wid)
			if wp:isKindOf("Weapon") then
				room:obtainCard(source,wp)
				return
			end
		end
		local ws = {}
		for _,p in sgs.qlist(room:getOtherPlayers(source))do
			if p:getWeapon() then
				table.insert(ws,p:getWeapon())
			end
		end
		if #ws > 0 then
			room:obtainCard(source,ws[math.random(1,#ws)])
		end
	end,
}
yongshanxievs = sgs.CreateZeroCardViewAsSkill{
	name = "yongshanxie",
	view_as = function()
		return yongshanxieCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#yongshanxieCard")
	end,
}
yongshanxie = sgs.CreateTriggerSkill{
    name = "yongshanxie",
	--frequency = sgs.Skill_Frequent,
	view_as_skill = yongshanxievs,
	events = {sgs.TargetSpecified,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:isAlive() and player:hasSkill(self) then
				local num = player:getAttackRange()*2
				player:setTag("yongshanxieJink"..use.card:toString(),ToData(num))
				for _,p in sgs.qlist(use.to)do
					if num<1 then break end
					p:setFlags("yongshanxieJink"..use.card:toString())
					room:setPlayerCardLimitation(p,"use","Jink|.|1~"..num,false)
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			local num = player:getTag("yongshanxieJink"..use.card:toString()):toInt()
			for _,p in sgs.qlist(room:getAlivePlayers())do
				if p:hasFlag("yongshanxieJink"..use.card:toString())
				then
					p:setFlags("-yongshanxieJink"..use.card:toString())
					room:removePlayerCardLimitation(p,"use","Jink|.|1~"..num)
				end
			end
		end
	end,
	can_trigger = function(self,player)
	    return player
	end,
}
yong_wangshuang:addSkill(yongshanxie)

sgs.Sanguosha:setPackage(yong)

local ol_ccxh = sgs.Sanguosha:getPackage("ol_ccxh")

--OL邓芝
ol_dengzhi = sgs.General(ol_ccxh,"ol_dengzhi","shu",3)

xiuhao = sgs.CreateTriggerSkill{
name = "xiuhao",
events = sgs.DamageCaused,
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	if not room:hasCurrent() then return false end
	local damage = data:toDamage()
	if damage.to:isDead() or damage.to:objectName() == player:objectName() then return false end
	local sp = sgs.SPlayerList()
	sp:append(player)
	sp:append(damage.to)
	room:sortByActionOrder(sp)
	for _,p in sgs.qlist(sp)do
		if p:isDead() or not p:hasSkill(self) or p:getMark("xiuhaoUsed-Clear") > 0 then continue end
		--local spp = sp
		local spp = sgs.SPlayerList()
		for _,q in sgs.qlist(sp)do
			if q:objectName() == p:objectName() then continue end
			spp:append(q)
		end
		--spp:removeOne(p)
		local pp = spp:first()
		if pp:isDead() then continue end
		if not p:askForSkillInvoke(self,pp) then continue end
		p:peiyin(self)
		p:addMark("xiuhaoUsed-Clear")
		damage.from:drawCards(2,self:objectName())
		return true
	end
	return false
end
}

sujian = sgs.CreatePhaseChangeSkill{
name = "sujian",
frequency = sgs.Skill_Compulsory,
on_phasechange = function(self,player,room)
	if player:getPhase() ~= sgs.Player_Discard then return false end
	local cards,this_turn,this_turn_ids,can_dis = sgs.IntList(),player:property("fulin_list"):toString():split("+"),sgs.IntList(),sgs.IntList()
	
	for _,str in ipairs(this_turn)do
		local num = tonumber(str)
		if num and num > -1 then
			this_turn_ids:append(num)
		end
	end
	
	for _,id in sgs.qlist(player:handCards())do
		if this_turn_ids:contains(id) then continue end
		cards:append(id)
		if player:canDiscard(player,id) then
			can_dis:append(id)
		end
	end
	if cards:isEmpty() then return true end
	room:sendCompulsoryTriggerLog(player,self)
	room:fillAG(cards,player)
	local data = sgs.QVariant()
	data:setValue(cards)
	local choices = "give"
	if not can_dis:isEmpty() then choices = choices.."+discard" end
	local choice = room:askForChoice(player,self:objectName(),choices,data)
	room:clearAG(player)
	
	if choice == "give" then
		local give = {}
		
		while not cards:isEmpty()do
			local move = room:askForYijiStruct(player,cards,self:objectName(),false,false,false,-1,room:getOtherPlayers(player),sgs.CardMoveReason(),"@sujian-give",false,false)
			if move and move.to then
				local ids = give[move.to:objectName()] or sgs.IntList()
				for _,id in sgs.qlist(move.card_ids)do
					cards:removeOne(id)
					ids:append(id)
				end
				give[move.to:objectName()] = ids
			end
		end
		
		local moves = sgs.CardsMoveList()
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			local ids = give[p:objectName()] or sgs.IntList()
			if ids:isEmpty() then continue end
			local move = sgs.CardsMoveStruct(ids,player,p,sgs.Player_PlaceHand,sgs.Player_PlaceHand,
				sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,player:objectName(),p:objectName(),self:objectName(),""))
			moves:append(move)
		end
		if not moves:isEmpty() then
			room:moveCardsAtomic(moves,false)
		end
	else
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		slash:addSubcards(can_dis)
		room:throwCard(slash,player)
		
		if player:isDead() then return true end
		local sp = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if player:canDiscard(p,"he") then
				sp:append(p)
			end
		end
		if sp:isEmpty() then return true end
		
		local to = room:askForPlayerChosen(player,sp,self:objectName(),"@sujian-discard")
		room:doAnimate(1,player:objectName(),to:objectName())
		
		local jink = sgs.Sanguosha:cloneCard("jink")
		jink:deleteLater()--生成虚拟卡进行弃置操作
		
		for i = 1,can_dis:length()do--进行多次执行
			local id = room:askForCardChosen(player,to,"he",self:objectName(),
				false,--选择卡牌时手牌不可见
				sgs.Card_MethodDiscard,--设置为弃置类型
				jink:getSubcards(),--将子卡表设置为不可选卡牌id表（保证每张卡只能被选择一次）
				i>1)--只有执行过一次选择才可取消
			if id < 0 then break end--如果卡牌id无效就结束多次执行
			jink:addSubcard(id)--将选择的id添加到虚拟卡的子卡表
		end
		room:throwCard(jink,to,player)--弃置虚拟卡（会连带着弃置子卡表里id的卡）
	end
	return true
end
}

ol_dengzhi:addSkill(xiuhao)
ol_dengzhi:addSkill(sujian)
ol_ccxh:insertRelatedSkills("sujian","#fulinbf")


--OL马忠
ol_mazhong = sgs.General(ol_ccxh,"ol_mazhong","shu",4)

olfumanCard = sgs.CreateSkillCard{
name = "olfuman",
handling_method = sgs.Card_MethodNone,
will_throw = false,
filter = function(self,targets,to_select,player)
	return #targets == 0 and to_select:objectName() ~= player:objectName() and to_select:getMark("olfuman_target-PlayClear") <= 0
end,
on_effect = function(self,effect)
	local from,to = effect.from,effect.to
	local room = from:getRoom()
	room:addPlayerMark(to,"olfuman_target-PlayClear")
	room:giveCard(from,to,self,"olfuman")
	
	local id = self:getSubcards():first()
	if room:getCardPlace(id) ~= sgs.Player_PlaceHand then return end
	local slash = sgs.Sanguosha:cloneCard("slash",self:getSuit(),self:getNumber())
	slash:setSkillName("olfuman")
	local ccc = sgs.Sanguosha:getWrappedCard(id)
	ccc:takeOver(slash)
	room:notifyUpdateCard(room:getCardOwner(id),id,ccc)
end
}

olfumanVS = sgs.CreateOneCardViewAsSkill{
name = "olfuman",
filter_pattern = ".|.|.|hand",
view_as = function(self,card)
	local c = olfumanCard:clone()
	c:addSubcard(card)
	return c
end
}

olfuman = sgs.CreateTriggerSkill{
name = "olfuman",
events = {sgs.DamageDone,sgs.CardFinished},
view_as_skill = olfumanVS,
can_trigger = function(self,player)
	return player
end,
on_trigger = function(self,event,player,data,room)
	if event == sgs.DamageDone then
		local damage = data:toDamage()
		if not damage.card or not damage.card:isKindOf("Slash") or not damage.card:hasFlag("olfuman_used_slash") then return false end
		room:setCardFlag(damage.card,"olfuman_damage_done")
	else
		local use = data:toCardUse()
		--if not use.card:isKindOf("Slash") then return false end  --如果原牌面不是【杀】，例如【闪】，ai操作时会判断不是【杀】
		if use.card:isKindOf("SkillCard") then return false end
		if use.card:hasFlag("olfuman_used_slash") or table.contains(use.card:getSkillNames(),"olfuman") then
			local x = (use.card:hasFlag("olfuman_damage_done") and 2) or 1
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:isDead() or not p:hasSkill(self) then continue end
				room:sendCompulsoryTriggerLog(p,self)
				p:drawCards(x,self:objectName())
			end
		end
	end
	return false
end
}

ol_mazhong:addSkill(olfuman)

--OL谯周
ol_qiaozhou = sgs.General(ol_ccxh,"ol_qiaozhou","shu",3)
--ol_qiaozhou:setImage("qiaozhou")

olxingbu = sgs.CreatePhaseChangeSkill{
name = "olxingbu",
frequency = sgs.Skill_Frequent,
on_phasechange = function(self,player,room)
	if player:getPhase() ~= sgs.Player_Finish or not player:askForSkillInvoke(self) then return false end
	player:peiyin(self)
	local shows = room:showDrawPile(player,3,"olxingbu")
	local red = 0
	for _,id in sgs.qlist(shows)do
		if sgs.Sanguosha:getCard(id):isRed()
		then red = red + 1 end
	end
	if red > 0 then
		local mark = "olxingbu3"
		if red == 2 then
			mark = "olxingbu2"
		elseif red <= 1 then
			mark = "olxingbu1"
		end
		local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),mark,"@olxingbu-invoke:"..red)
		room:doAnimate(1,player:objectName(),to:objectName())
		if to:isAlive() then
			room:addPlayerMark(to,"&"..mark.."-SelfClear")
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	for _,id in sgs.qlist(shows)do
		if room:getCardPlace(id) == sgs.Player_PlaceTable
		then slash:addSubcard(id) end
	end
	slash:deleteLater()
	if slash:subcardsLength() > 0 then
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,player:objectName(),"olxingbu","")
		room:throwCard(slash,reason,nil)
	end
	return false
end
}

olxingbuEffect = sgs.CreateTriggerSkill{
name = "#olxingbuEffect",
events = {sgs.EventPhaseChanging,sgs.DrawNCards,sgs.EventPhaseStart},
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	if event == sgs.EventPhaseChanging then
		if data:toPhaseChange().to ~= sgs.Player_Discard or player:getMark("&olxingbu2-SelfClear") <= 0 then return false end
		if player:isSkipped(sgs.Player_Discard) then return false end
		sendZhenguLog(player,"olxingbu")
		player:skip(sgs.Player_Discard)
	elseif event == sgs.DrawNCards then
		local mark = player:getMark("&olxingbu3-SelfClear")
		if mark <= 0 then return false end
		local draw = data:toDraw()
		if draw.reason~="draw_phase" then return end
		sendZhenguLog(player,"olxingbu")
		draw.num = draw.num+2*mark
		data:setValue(draw)
	else
		if player:getPhase() ~= sgs.Player_Start then return false end
		local mark = player:getMark("&olxingbu1-SelfClear")
		if mark <= 0 then return false end
		for i = 1,mark do
			if player:isDead() or player:isKongcheng() then break end
			sendZhenguLog(player,"olxingbu")
			room:askForDiscard(player,"olxingbu",1,1)
		end
	end
	return false
end
}


ol_qiaozhou:addSkill("zhiming")
ol_qiaozhou:addSkill(olxingbu)
ol_qiaozhou:addSkill(olxingbuEffect)
ol_ccxh:insertRelatedSkills("olxingbu","#olxingbuEffect")

--刘琦[二版]
second_liuqi = sgs.General(ol_ccxh,"second_liuqi","qun",3)

secondwenji = sgs.CreateTriggerSkill{
name = "secondwenji",
events = {sgs.CardUsed,sgs.EventPhaseStart},
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	if event==sgs.CardUsed then
		local use = data:toCardUse()
		if player:getMark("&secondwenji+:+"..use.card:getType().."-Clear")<1 then return false end
		local list = use.no_respond_list
		for _,p in sgs.qlist(use.to)do
			if p~=player then
				table.insert(list,p:objectName())
			end
		end
		use.no_respond_list = list
		data:setValue(use)
	elseif player:getPhase() == sgs.Player_Play
	and player:hasSkill(self) then
		local sp = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if p:isNude() then continue end
			sp:append(p)
		end
		
		local target = room:askForPlayerChosen(player,sp,self:objectName(),"@wenji-invoke",true,true)
		if not target then return false end
		player:peiyin(self)
		
		local card = room:askForCard(target,"..!","wenji-give:"..player:objectName(),ToData(player),sgs.Card_MethodNone)
		if not card then
			card = target:getCards("he"):at(math.random(0,target:getCards("he"):length() - 1))
		end
		if not card then return false end
		room:setPlayerMark(player,"&secondwenji+:+"..card:getType().."-Clear",1)
		room:giveCard(target,player,card,self:objectName())
	end
	return false
end
}

secondtunjiang = sgs.CreateTriggerSkill{
name = "secondtunjiang",
events = {sgs.CardUsed,sgs.EventPhaseStart},
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	if event==sgs.CardUsed then
		local use = data:toCardUse()
		if use.card:isKindOf("SkillCard") or player:getPhase() ~= sgs.Player_Play then return false end
		for _,p in sgs.qlist(use.to)do
			if p~=player then
				player:addMark("tunjiang-Clear")
				break
			end
		end
	elseif player:getPhase() == sgs.Player_Finish and player:getMark("tunjiang-Clear")<1
	and player:hasSkill(self) and player:askForSkillInvoke(self) then
		player:peiyin("tunjiang")
		local kingdoms = {}
		for _,p in sgs.qlist(room:getAlivePlayers())do
			local kingdom = p:getKingdom()
			if not table.contains(kingdoms,kingdom) then
				table.insert(kingdoms,kingdom)
			end
		end
		player:drawCards(#kingdoms,self:objectName())
	end
	return false
end
}

second_liuqi:addSkill(secondwenji)
second_liuqi:addSkill(secondtunjiang)

--杜夫人
dufuren = sgs.General(ol_ccxh,"dufuren","wei",3,false)

yise = sgs.CreateTriggerSkill{
name = "yise",
events = sgs.CardsMoveOneTime,
on_trigger = function(self,event,player,data,room)
	local move = data:toMoveOneTime()
	if not move.to or not move.from or move.to:objectName() == move.from:objectName() or move.from:objectName() ~= player:objectName() then return false end
	if not move.from_places:contains(sgs.Player_PlaceEquip) and not move.from_places:contains(sgs.Player_PlaceHand) then return false end
	
	local to = room:findPlayerByObjectName(move.to:objectName())
	if not to or to:isDead() then return false end
	
	local red,black = false,false
	for i = 0,move.card_ids:length() - 1 do
		if move.from_places:at(i) == sgs.Player_PlaceEquip or move.from_places:at(i) == sgs.Player_PlaceHand then
			local card = sgs.Sanguosha:getCard(move.card_ids:at(i))
			if card:isRed() then red = true
			elseif card:isBlack() then black = true end
			if red and black then break end
		end
	end
	
	if red then
		if to:isWounded() and player:askForSkillInvoke(self,to) then
			player:peiyin(self)
			room:recover(to,sgs.RecoverStruct(self:objectName(),player))
		end
	end
	
	if black and to:isAlive() then
		room:sendCompulsoryTriggerLog(player,self)
		room:addPlayerMark(to,"&yise")
	end
	return false
end
}

yiseDamage = sgs.CreateTriggerSkill{
name = "#yiseDamage",
events = sgs.DamageInflicted,
can_trigger = function(self,player)
	return player and player:isAlive() and player:getMark("&yise") > 0
end,
on_trigger = function(self,event,player,data,room)
	local damage = data:toDamage()
	if not damage.card or not damage.card:isKindOf("Slash") then return false end
	local mark = player:getMark("&yise")
	if mark <= 0 then return false end
	room:setPlayerMark(player,"&yise",0)
	sendZhenguLog(player,"yise")
	player:damageRevises(data,mark)
	return false
end
}

shunshi = sgs.CreateTriggerSkill{
name = "shunshi",
events = {sgs.EventPhaseStart,sgs.Damaged},
on_trigger = function(self,event,player,data,room)
	if player:isNude() then return false end
	
	if event == sgs.EventPhaseStart then
		if player:getPhase() ~= sgs.Player_Start then return false end
	end
	
	local players = room:getOtherPlayers(player)
	
	if event == sgs.Damaged then
		if player:hasFlag("CurrentPlayer") then return false end
		local damage = data:toDamage()
		if damage.from then players:removeOne(damage.from) end
	end
	
	if players:isEmpty() then return false end
	
	for _,p in sgs.qlist(players)do  --prepare for ai
		p:setFlags("shunshi")
	end
	
	local cards = sgs.IntList()
	for _,id in sgs.qlist(player:handCards())do
		cards:append(id)
	end
	for _,id in sgs.qlist(player:getEquipsId())do
		cards:append(id)
	end
	local move = room:askForYijiStruct(player,cards,self:objectName(),false,false,true,1,players,sgs.CardMoveReason(),"@shunshi-give",true,false)
	if move.to and not move.card_ids:isEmpty() then
		for _,p in sgs.qlist(players)do
			p:setFlags("-shunshi")
		end
		local to = room:findPlayerByObjectName(move.to:objectName())
		if not to or to:isDead() then return false end
		room:giveCard(player,to,move.card_ids,self:objectName())
		if player:isAlive() then
			room:addPlayerMark(player,"&shunshi-SelfClear")
			room:addPlayerMark(player,"shunshi_draw")
			room:addPlayerMark(player,"shunshi_play")
			room:addPlayerMark(player,"shunshi_discard")
		end
	end
	return false
end
}

shunshiEffect = sgs.CreateTriggerSkill{
name = "#shunshiEffect",
events = {sgs.DrawNCards,sgs.EventPhaseStart},
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	if event == sgs.DrawNCards then
		local n = player:getMark("shunshi_draw")
		if n <= 0 then return false end
		local draw = data:toDraw()
		if draw.reason~="draw_phase" then return end
		room:setPlayerMark(player,"shunshi_draw",0)
		sendZhenguLog(player,"shunshi")
		draw.num = draw.num+n
		data:setValue(draw)
	else
		if player:getPhase() == sgs.Player_Play then
			local mark = player:getMark("shunshi_play")
			if mark <= 0 then return false end
			room:setPlayerMark(player,"shunshi_play",0)
			room:addPlayerMark(player,"shunshi_play-PlayClear",mark)
		elseif player:getPhase() == sgs.Player_Discard then
			room:setPlayerMark(player,"&shunshi-SelfClear",0)
			local mark = player:getMark("shunshi_discard")
			if mark <= 0 then return false end
			room:setPlayerMark(player,"shunshi_discard",0)
			room:addPlayerMark(player,"shunshi_discard-Self"..sgs.Player_Discard.."Clear",mark)
		end
	end
	return false
end
}

shunshiMAX = sgs.CreateMaxCardsSkill{
	name = "#shunshiMAX",
	extra_func = function(self,player)
		local n = 0
		if player:hasArmorEffect("_taipingyaoshu") then
			local ks = {player:getKingdom()}
			for _,p in sgs.qlist(player:getAliveSiblings())do
				if table.contains(ks,p:getKingdom()) then continue end		
				table.insert(ks,p:getKingdom())
			end
			n = n+#ks-1
		end
		if player:hasLordSkill("mouxueyi") then
			for _,p in sgs.qlist(player:getAliveSiblings())do
				if p:getKingdom() == "qun" then n = n + 2 end
			end
		end
		if player:getPhase() == sgs.Player_Discard then
			n = n+player:getMark("shunshi_discard-Self"..sgs.Player_Discard.."Clear")
		end
		return n
	end,
	fixed_func = function(self,player)
		local n = -1
		if player:hasSkill("mobilexiaoni")
		then n = math.max(0,player:property("mobiledamingNum"):toInt()) end
		if player:hasSkill("pinghe") then
			n = math.max(n,player:getLostHp())
		end
		return n
	end
}

dufuren:addSkill(yise)
dufuren:addSkill(yiseDamage)
dufuren:addSkill(shunshi)
dufuren:addSkill(shunshiEffect)
dufuren:addSkill(shunshiMAX)
ol_ccxh:insertRelatedSkills("yise","#yiseDamage")
ol_ccxh:insertRelatedSkills("shunshi","#shunshiEffect")

--左棻
jin_zuofen = sgs.General(ol_ccxh,"jin_zuofen","jin",3,false)

jinzhaosongCard = sgs.CreateSkillCard{
name = "jinzhaosong",
filter = function(self,targets,to_select,player)
	return #targets < 2 and to_select:hasFlag("jinzhaosong_can_choose")
end,
about_to_use = function(self,room,use)
	for _,p in sgs.qlist(use.to)do
		room:setPlayerFlag(p,"jinzhaosong_add")
	end
end
}

jinzhaosongVS = sgs.CreateZeroCardViewAsSkill{
name = "jinzhaosong",
response_pattern = "@@jinzhaosong",
view_as = function()
	return jinzhaosongCard:clone()
end,
}

jinzhaosong = sgs.CreateTriggerSkill{
name = "jinzhaosong",
events = {sgs.EventPhaseEnd,sgs.Dying,sgs.EventPhaseStart,sgs.CardUsed,sgs.CardFinished,sgs.DamageDone},
view_as_skill = jinzhaosongVS,
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	if event == sgs.EventPhaseEnd then
		if player:getPhase() ~= sgs.Player_Draw then return false end
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if player:getMark("&jzslei") > 0 or player:getMark("&jzsfu") > 0 or player:getMark("&jzssong") > 0 then return false end
			if player:isKongcheng() or player:isDead() then return false end
			if p:isDead() or not p:hasSkill(self) then continue end
			if not p:askForSkillInvoke(self,player) then continue end
			p:peiyin(self)
			
			local card = room:askForExchange(player,self:objectName(),1,1,false,"jinzhaosong_give:"..p:objectName())
			local _card = sgs.Sanguosha:getCard(card:getSubcards():first())
			local mark
			if _card:isKindOf("TrickCard") then mark = "&jzslei"
			elseif _card:isKindOf("EquipCard") then mark = "&jzsfu"
			elseif _card:isKindOf("BasicCard") then mark = "&jzssong" end
			
			room:giveCard(player,p,card,self:objectName(),true)
			
			if not mark or player:isDead() then continue end
			player:gainMark(mark)
		end
	elseif event == sgs.Dying then
		local dying = data:toDying()
		if dying.who:objectName() ~= player:objectName() or player:getMark("&jzslei") <= 0 then return false end
		if not player:askForSkillInvoke("jinzhaosong_lei",sgs.QVariant("recover")) then return false end
		player:peiyin(self)
		player:loseAllMarks("&jzslei")
		local recover = math.min(1 - player:getHp(),player:getMaxHp() - player:getHp())
		room:recover(player,sgs.RecoverStruct(self:objectName(),player))
		player:drawCards(1,self:objectName())
		room:loseMaxHp(player,1,"jinzhaosong")
	elseif event == sgs.EventPhaseStart then
		if player:getPhase() ~= sgs.Player_Play or player:getMark("&jzsfu") <= 0 then return false end
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers())do
			if player:canDiscard(p,"hej") then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return false end
		local t = room:askForPlayerChosen(player,targets,self:objectName(),"@jinzhaosong-discard",true)
		if not t then return false end
		player:peiyin(self)
		room:doAnimate(1,player:objectName(),t:objectName())
		player:loseAllMarks("&jzsfu")
		local id = room:askForCardChosen(player,t,"hej",self:objectName(),false,sgs.Card_MethodDiscard)
		room:throwCard(id,t,player)
		if player:isAlive() and t:isAlive() then
			local new_data = sgs.QVariant()
			new_data:setValue(t)
			player:setTag("JinZhaosongDrawer",new_data)
			local invoke = player:askForSkillInvoke("jinzhaosong_fu",sgs.QVariant("draw"))
			player:removeTag("JinZhaosongDrawer")
			if invoke then
				t:drawCards(1,self:objectName())
			end
		end
	elseif event == sgs.CardUsed then
		if player:getMark("&jzssong") <= 0 then return false end
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") or use.to:length() ~= 1 then return false end
		
		local can_invoke = false
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if use.to:contains(p) or not player:canSlash(p,use.card) then continue end
			room:setPlayerFlag(p,"jinzhaosong_can_choose")
			can_invoke = true
		end
		
		if not can_invoke then
			for _,p in sgs.qlist(room:getOtherPlayers(player))do
				room:setPlayerFlag(p,"-jinzhaosong_can_choose")
			end
			return false
		end
		
		local invoke = room:askForUseCard(player,"@@jinzhaosong","@jinzhaosong",-1,sgs.Card_MethodNone)
		
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			room:setPlayerFlag(p,"-jinzhaosong_can_choose")
		end
		
		if not invoke then return false end
		
		local targets = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if p:hasFlag("jinzhaosong_add") then
				room:setPlayerFlag(p,"-jinzhaosong_add")
				targets:append(p)
				use.to:append(p)
			end
		end
		if targets:isEmpty() then return false end
		
		player:peiyin(self)
		room:setCardFlag(use.card,"jinzhaosong_song")
		local new_data = sgs.QVariant()
		new_data:setValue(player)
		room:setTag("JinZhaosongUser_"..use.card:toString(),new_data)
		
		player:loseAllMarks("&jzssong")
		room:sortByActionOrder(targets)
		room:sortByActionOrder(use.to)
		for _,p in sgs.qlist(targets)do
			room:doAnimate(1,player:objectName(),p:objectName())
		end
		local log = sgs.LogMessage()
		log.type = "#QiaoshuiAdd"
		log.from = player
		log.to = targets
		log.card_str = use.card:toString()
		log.arg = self:objectName()
		room:sendLog(log)
		data:setValue(use)
	elseif event == sgs.CardFinished then
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") or not use.card:hasFlag("jinzhaosong_song") then return false end
		local num = room:getTag("JinZhaosong_"..use.card:toString()):toInt()
		room:removeTag("JinZhaosong_"..use.card:toString())
		local from = room:getTag("JinZhaosongUser_"..use.card:toString()):toPlayer()
		room:removeTag("JinZhaosongUser_"..use.card:toString())
		if num >= 2 or not from or from:isDead() then return false end
		-- room:loseHp(from)
		for _,p in sgs.qlist(room:getAllPlayers())do
			if not p:hasSkill(self) then continue end
			room:loseHp(sgs.HpLostStruct(from,1,"jinzhaosong",p))
		end
	elseif event == sgs.DamageDone then
		local damage = data:toDamage()
		if not damage.card or not damage.card:isKindOf("Slash") or not damage.card:hasFlag("jinzhaosong_song") then return false end
		local num = room:getTag("JinZhaosong_"..damage.card:toString()):toInt()
		num = num + damage.damage
		room:setTag("JinZhaosong_"..damage.card:toString(),sgs.QVariant(num))
	end
	return false
end
}

jinlisi = sgs.CreateTriggerSkill{
name = "jinlisi",
events = sgs.CardsMoveOneTime,
on_trigger = function(self,event,player,data,room)
	local move = data:toMoveOneTime()
	if not move.from_places:contains(sgs.Player_PlaceTable) or move.to_place ~= sgs.Player_DiscardPile then return false end
	if not move.from or move.from:objectName() ~= player:objectName() then return false end
	if player:hasFlag("CurrentPlayer") then return false end
	if move.reason.m_reason == sgs.CardMoveReason_S_REASON_USE or move.reason.m_reason == sgs.CardMoveReason_S_REASON_LETUSE then
		local card = move.reason.m_extraData:toCard()
		if not card or not room:CardInPlace(card,sgs.Player_DiscardPile) then return false end
		local targets,hand = sgs.SPlayerList(),player:getHandcardNum()
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if p:getHandcardNum() <= hand then
				targets:append(p)
			end
		end
		if targets:isEmpty() then return false end
		local ids = sgs.IntList()
		if card:isVirtualCard() then
			ids = card:getSubcards()
		else
			ids:append(card:getEffectiveId())
		end
		if ids:isEmpty() then return false end
		room:fillAG(ids,player)
		local t = room:askForPlayerChosen(player,targets,self:objectName(),"@jinlisi-give",true,true)
		room:clearAG(player)
		if not t then return false end
		player:peiyin(self)
		room:giveCard(player,t,card,"jinlisi",true)
	end
	return false
end
}

jin_zuofen:addSkill(jinzhaosong)
jin_zuofen:addSkill(jinlisi)

--OL王荣
ol_wangrong = sgs.General(ol_ccxh,"ol_wangrong","qun",3,false)

fengzi = sgs.CreateTriggerSkill{
name = "fengzi",
events = sgs.CardUsed,
on_trigger = function(self,event,player,data,room)
	if player:getPhase() ~= sgs.Player_Play or player:getMark("fengzi_Used-PlayClear") > 0 then return false end
	local use = data:toCardUse()
	if not use.card:isKindOf("BasicCard") and not use.card:isNDTrick() then return false end
	if not player:canDiscard(player,"h") then return false end
	local typee = (use.card:isKindOf("BasicCard") and "BasicCard") or "TrickCard"
	if room:askForCard(player,typee.."|.|.|hand","@fengzi-discard:"..use.card:getType().."::"..use.card:objectName(),data,self:objectName()) then
		player:peiyin(self)
		player:addMark("fengzi_Used-PlayClear")
		player:addMark("fengziCard"..use.card:toString())
	end
	return false
end
}

fengziDouble = sgs.CreateTriggerSkill{
name = "#fengziDouble",
events = sgs.CardFinished,
on_trigger = function(self,event,player,data,room)
	local use = data:toCardUse()
	if player:getMark("fengziCard"..use.card:toString())<1 then return false end
	player:removeMark("fengziCard"..use.card:toString())
	use.card:use(room,use.from,use.to)
	return false
end
}

jizhanw = sgs.CreatePhaseChangeSkill{
name = "jizhanw",
on_phasechange = function(self,player,room)
	if player:getPhase() ~= sgs.Player_Draw or not player:askForSkillInvoke(self) then return false end
	player:peiyin(self)
	
	local gets = sgs.IntList()
	local ids = room:showDrawPile(player,1,self:objectName())
	gets:append(ids:first())
	local num = sgs.Sanguosha:getEngineCard(ids:first()):getNumber()
	
	while player:isAlive()do
		local choices = {}
		table.insert(choices,"more="..num)
		table.insert(choices,"less="..num)
		table.insert(choices,"cancel")
		local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"),sgs.QVariant(num))
		if choice == "cancel" then break end
		
		ids = room:showDrawPile(player,1,self:objectName())
		gets:append(ids:first())
		local next_num = sgs.Sanguosha:getEngineCard(ids:first()):getNumber()
		if (next_num == num) or (next_num > num and choice:startsWith("less")) or (next_num < num and choice:startsWith("more")) then break end
		num = next_num
	end
	
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	for _,id in sgs.qlist(gets)do
		if room:getCardPlace(id) ~= sgs.Player_PlaceTable then continue end
		slash:addSubcard(id)
	end
	
	if slash:subcardsLength() > 0 then
		if player:isDead() then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,player:objectName(),self:objectName(),"")
			room:throwCard(slash,reason,nil)
			return true
		end
		room:obtainCard(player,slash)
	end
	return true
end
}

fusong = sgs.CreateTriggerSkill{
name = "fusong",
events = sgs.Death,
can_trigger = function(self,player)
	return player and player:hasSkill(self)
end,
on_trigger = function(self,event,player,data,room)
	local death = data:toDeath()
	if death.who:objectName() ~= player:objectName() then return false end
	
	local players = sgs.SPlayerList()
	local max_hp = player:getMaxHp()
	for _,p in sgs.qlist(room:getOtherPlayers(player))do
		if p:getMaxHp() <= max_hp then continue end
		players:append(p)
	end
	
	if players:isEmpty() then return false end
	local target = room:askForPlayerChosen(player,players,self:objectName(),"@fusong-invoke",true,true)
	if not target then return false end
	player:peiyin(self)
	
	local skills = {}
	if not target:hasSkill("fengzi",true) then table.insert(skills,"fengzi") end
	if not target:hasSkill("jizhanw",true) then table.insert(skills,"jizhanw") end
	if #skills == 0 then return false end
	local skill = room:askForChoice(target,self:objectName(),table.concat(skills,"+"))
	room:acquireSkill(target,skill)
	return false
end
}

ol_wangrong:addSkill(fengzi)
ol_wangrong:addSkill(fengziDouble)
ol_wangrong:addSkill(jizhanw)
ol_wangrong:addSkill(fusong)
ol_ccxh:insertRelatedSkills("fengzi","#fengziDouble")

--夏侯玄
keol_xiahouxuan = sgs.General(ol_ccxh,"keol_xiahouxuan","wei",3)
keolhuanfu = sgs.CreateTriggerSkill{
	name = "keolhuanfu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified,sgs.TargetConfirmed,sgs.DamageDone,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				for _,p in sgs.qlist(room:getAllPlayers())do
					local n = p:getMark("keolhuanfudis"..use.card:toString())
					if n>0 and n==use.card:getMark("keolhuanfuda") then p:drawCards(2*n,self:objectName()) end
					room:setPlayerMark(p,"keolhuanfudis"..use.card:toString(),0)
				end
				room:setCardMark(use.card,"keolhuanfuda",0)
			end
		elseif (event == sgs.DamageDone) then
			local damage = data:toDamage()
			if damage.card then
				local use = room:getUseStruct(damage.card)
				if use.to:contains(player) then
					room:addCardMark(damage.card,"keolhuanfuda",damage.damage)
				end
			end
		elseif (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			if use.to:contains(player) and player:hasSkill(self) 
			and use.card:isKindOf("Slash") and not player:isNude() then
				player:setTag("keolhuanfuData",data)
				local askdis = room:askForDiscard(player,self:objectName(),player:getMaxHp(),1,true,true,"keolhuanfudis",".",self:objectName())
				if askdis then
					player:peiyin(self)
					player:setMark("keolhuanfudis"..use.card:toString(),askdis:subcardsLength())
				end
			end
		elseif (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if use.from==player and use.card:isKindOf("Slash")
			and player:hasSkill(self) and not player:isNude() then
				player:setTag("keolhuanfuData",data)
				local askdis = room:askForDiscard(player,self:objectName(),player:getMaxHp(),1,true,true,"keolhuanfudis",".",self:objectName())
				if askdis then
					player:peiyin(self)
					player:setMark("keolhuanfudis"..use.card:toString(),askdis:subcardsLength())
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target ~= nil
	end
}
keol_xiahouxuan:addSkill(keolhuanfu)
keolqingyiCard = sgs.CreateSkillCard{
	name = "keolqingyiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select,player)
		return (#targets < 2) and (not to_select:isNude()) and (to_select:objectName() ~= player:objectName())
	end,
	on_use = function(self,room,player,targets)
		local players = sgs.SPlayerList()
		players:append(player)
		for _,p in sgs.list(targets)do
			players:append(p)
		end
		local ids = sgs.IntList()
		player:removeTag("keolqingyiIds")
		while #targets>0 do
			local ds = {}
			for _,p in sgs.qlist(players)do
				if p:isNude() then continue end
				ds[p:objectName()] = room:askForCard(p,"..!","keolqingyidis:",ToData(player),sgs.Card_MethodDiscard,nil,true)
			end
			local can = false
			for _,p in sgs.qlist(players)do
				if ds[p:objectName()] then
					room:throwCard(ds[p:objectName()],p)
					ids:append(ds[p:objectName()]:getEffectiveId())
					can = true
				end
			end
			local dc = nil
			for p,c in pairs(ds)do
				if dc then
					if dc:getType()~=c:getType()
					then can = false break end
				else
					dc = c
				end
			end
			if not(can and player:askForSkillInvoke("keolqingyi",ToData("jixu"),false))
			then break end
		end
		player:setTag("keolqingyiIds",ToData(ids))
	end
}
keolqingyiVS = sgs.CreateViewAsSkill{
	name = "keolqingyi",
	n = 0,
	view_as = function(self,cards)
		return keolqingyiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return (not player:isNude()) and (not (player:hasUsed("#keolqingyiCard")))
	end,
}
keolqingyi = sgs.CreateTriggerSkill{
	name = "keolqingyi",
	view_as_skill = keolqingyiVS,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseStart) and (player:getPhase() == sgs.Player_Finish) then
			local card_ids = sgs.IntList()
			for _,id in sgs.qlist(player:getTag("keolqingyiIds"):toIntList())do
				if room:getCardPlace(id)==sgs.Player_DiscardPile then
					card_ids:append(id)
				end
			end
			--开始选择各一张
			if card_ids:length()>0 then
				room:broadcastSkillInvoke(self:objectName())
				room:fillAG(card_ids)
				local dummy = dummyCard()
				while card_ids:length()>0 do
					local card_id = room:askForAG(player,card_ids,false,self:objectName(),"keolqingyi-choice")
					dummy:addSubcard(card_id) 
					card_ids:removeOne(card_id)				
					room:takeAG(player,card_id,false)
					local card_ids2 = sgs.IntList()
					for _,id in sgs.qlist(card_ids)do
						card_ids2:append(id)
					end
					local card = sgs.Sanguosha:getCard(card_id)
					for _,id in sgs.qlist(card_ids2)do
						if (sgs.Sanguosha:getCard(id):getColor() == card:getColor()) then  	
							card_ids:removeOne(id)				
							room:takeAG(nil,id,false)
						end
					end
				end
				room:getThread():delay()
				room:clearAG()
				if dummy:subcardsLength()>0 then
					player:obtainCard(dummy)
				end
			end
		end
	end,
}
keol_xiahouxuan:addSkill(keolqingyi)
keolzeyue = sgs.CreateTriggerSkill{
	name = "keolzeyue",
	events = {sgs.DamageDone,sgs.EventPhaseStart,sgs.RoundStart},
	frequency = sgs.Skill_Limited,
	limit_mark = "@keolzeyue",
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.RoundStart) then
			for _,p in sgs.qlist(room:getOtherPlayers(player))do
				if player:getMark("&keolzeyue+#"..p:objectName()) > 0 then
					player:addMark("bezeyue"..p:objectName())
					for i = 1,player:getMark("bezeyue"..p:objectName())do
						local slash = dummyCard()
						slash:setFlags("keolzeyue")
						slash:setSkillName("_keolzeyue")
						if player:isAlive() and p:isAlive() and player:canSlash(p,slash,false) then
							room:useCard(sgs.CardUseStruct(slash,player,p))
							if p:getTag("keolzeyueDamageDone"):toBool() then
								p:removeTag("keolzeyueDamageDone")
								local sk = player:getTag("keolzeyuetag"..p:objectName()):toString()
								if sk~="" then
									room:setPlayerMark(player,"&keolzeyue+#"..p:objectName(),0)
									room:acquireSkill(player,sk)
								end
							end
						end
					end
				end
			end
		elseif (event == sgs.DamageDone) then
			local damage = data:toDamage()
			if damage.from then
				if not player:hasFlag("CurrentPlayer")
				then room:addPlayerMark(damage.to,damage.from:objectName().."keolzeyueda-SelfClear") end
				if damage.card and (table.contains(damage.card:getSkillNames(),"keolzeyue") or damage.card:hasFlag("keolzeyue"))
				then player:setTag("keolzeyueDamageDone",ToData(true)) end
			end
		elseif event == sgs.EventPhaseStart
		and player:getMark("@keolzeyue") > 0
		and player:getPhase() == sgs.Player_Start and player:hasSkill(self) then
			local chooseplayers = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAllPlayers())do
				if player:getMark(p:objectName().."keolzeyueda-SelfClear") > 0
				then chooseplayers:append(p) end
			end
			local person = room:askForPlayerChosen(player,chooseplayers,self:objectName(),"keolzeyue-ask",true,true)
            if person then
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox(player,"keolzeyue")
				room:removePlayerMark(player,"@keolzeyue")
				--给一个复仇标记
				room:setPlayerMark(person,"&keolzeyue+#"..player:objectName(),1)
				local skills_list = {}
				local gen = person:getGeneral()
				for _,skill in sgs.qlist(gen:getVisibleSkillList())do
					if (not table.contains(skills_list,skill:objectName())) 
					and (skill:getFrequency() ~= sgs.Skill_Compulsory)
					then table.insert(skills_list,skill:objectName()) end
				end
				gen = person:getGeneral2()
				if gen then
					for _,skill in sgs.qlist(gen:getVisibleSkillList())do
						if (not table.contains(skills_list,skill:objectName())) 
						and (skill:getFrequency() ~= sgs.Skill_Compulsory)
						then table.insert(skills_list,skill:objectName()) end
					end
				end
				if (#skills_list > 0) then
					local skill_zy = room:askForChoice(player,self:objectName(),table.concat(skills_list,"+"))
					room:detachSkillFromPlayer(person,skill_zy)
					person:setTag("keolzeyuetag"..player:objectName(),sgs.QVariant(skill_zy))
				end
			end
		end
	end,
}
keol_xiahouxuan:addSkill(keolzeyue)
sgs.LoadTranslationTable {
	["keol_xiahouxuan"] = "夏侯玄",
	["#keol_xiahouxuan"] = "明皎月影",
	["designer:keol_xiahouxuan"] = "官方",
	["cv:keol_xiahouxuan"] = "官方",
	["illustrator:keol_xiahouxuan"] = "官方",

	["keolhuanfu"] = "宦浮",
	[":keolhuanfu"] = "当你使用【杀】指定目标后或成为【杀】的目标后，你可以弃置至多X张牌（X为你的体力上限），若如此做，此【杀】结算完毕时，若此【杀】对目标角色造成的总伤害数等于你弃置的牌数，你摸等同于弃牌数两倍的牌。",

	["keolqingyi"] = "清议",
	[":keolqingyi"] = "出牌阶段限一次，你可以与至多两名其他角色同时弃置一张牌，若这些牌类型相同，你可以重复此流程；结束阶段，你获得上个出牌阶段以此法弃置的牌中每种颜色的牌各一张。",

	["keolqingyidis"] = "清议：请弃置一张牌",
	["keolhuanfudis"] = "你可以发动“宦浮”弃置牌",
	["keolqingyi-choice"] = "请选择每种颜色各一张",

	["keolqingyi:jixu"] = "你可以再次执行此流程",

	["keolzeyue"] = "迮阅",
	[":keolzeyue"] = "限定技，准备阶段，你可以令一名你上回合结束后对你造成过伤害的其他角色失去武将牌上的一个非锁定技；每轮开始时，该角色视为对你使用X张【杀】（X为其失去该技能的轮数），若此【杀】对你造成了伤害，其获得该技能。",
	["keolzeyue-ask"] = "你可以选择发动“迮阅”的角色",

	["$keolhuanfu1"] = "宦海浮沉，莫问前路。",
	["$keolhuanfu2"] = "仕途险恶，吉凶难料。",
	["$keolqingyi1"] = "布政得失，愿与诸君共议。",
	["$keolqingyi2"] = "领军伐谋，还请诸位献策。",
	["$keolzeyue1"] = "以令相迮，束阀阅之家。",
	["$keolzeyue2"] = "以正相争，清朝野之妒。",
	["~keol_xiahouxuan"] = "玉山倾颓心无尘……",
	
}

keol_liuba = sgs.General(ol_ccxh,"keol_liuba","shu",3)
keoltongdu = sgs.CreateTriggerSkill{
	name = "keoltongdu",
	events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart
		and player:getPhase() == sgs.Player_Start then
			local players = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAllPlayers())do
				if not p:isKongcheng() then
					players:append(p)
				end
			end
			local person = room:askForPlayerChosen(player,players,self:objectName(),"keoltongdu-ask",true,true)
			if person then
				room:broadcastSkillInvoke(self:objectName())
				local card = room:askForExchange(person,self:objectName(),1,1,false,"keoltongduchoose:"..player:objectName())
				if card then
					room:setPlayerMark(player,"keoltongdu",card:getEffectiveId())
					room:obtainCard(player,card,false)
					player:setFlags("keoltongdu")
				end
			end
		elseif event == sgs.EventPhaseEnd
		and player:getPhase() == sgs.Player_Play
		and player:hasFlag("keoltongdu") then
			local id = player:getMark("keoltongdu")
			local cp = room:getCardOwner(id)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_TRANSFER,player:objectName(),"keoltongdu","")
			if cp==player or cp==nil then room:moveCardTo(sgs.Sanguosha:getCard(id),nil,sgs.Player_DrawPile,reason,true) end
		end
	end,
}
keol_liuba:addSkill(keoltongdu)
keolzhubiVSCard = sgs.CreateSkillCard{
	name = "keolzhubiVSCard",
	will_throw = false,
	target_fixed = true,
	about_to_use = function(self,room,use)
	end
}
keolzhubiCard = sgs.CreateSkillCard{
	name = "keolzhubiCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select)
		return (#targets < 1) and (not to_select:isNude())
	end,
	on_use = function(self,room,player,targets)
		for _,target in sgs.list(targets)do
			--选一张牌
			local c = room:askForCard(target,"..!","keolzhubichoose",ToData(player),sgs.Card_MethodRecast)
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST,target:objectName(),"keolzhubi","")
			--重铸
			room:moveCardTo(c,target,sgs.Player_DiscardPile,reason)
			--标记摸的牌
			local ids = target:drawCardsList(1,"recast")
			room:setCardTip(ids:first(),"keolbi")
		end
	end
}
keolzhubiVS = sgs.CreateViewAsSkill{
	name = "keolzhubi",
	n = 999,
	expand_pile = "#keolzhubi",
	view_filter = function(self,selected,to_select)
	    local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@keolzhubi" then
			return to_select:hasTip("keolbi")
			or sgs.Self:getPileName(to_select:getId())=="#keolzhubi"
		end
	end,
	view_as = function(self,cards)
	    local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@keolzhubi" then
			local n = 0
			local card = keolzhubiVSCard:clone()
			for _,c in sgs.list(cards)do
				card:addSubcard(c)
				if c:hasTip("keolbi")
				then n = n+1 end
			end
			return #cards>1 and n==#cards/2 and card
		end
		return keolzhubiCard:clone()
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"@@keolzhubi")
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#keolzhubiCard") < player:getMaxHp()
	end,
}
keolzhubi = sgs.CreateTriggerSkill{
	name = "keolzhubi",
	events = {sgs.EventPhaseStart},
	view_as_skill = keolzhubiVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (player:getPhase() == sgs.Player_Finish) then
			for _,c in sgs.qlist(player:getHandcards())do
				if c:hasTip("keolbi") then
					--观看五张牌然后交换
					local ids = room:getNCards(5,true,false)
					room:notifyMoveToPile(player,ids,"keolzhubi",sgs.Player_DrawPile,true)
					local uc = room:askForUseCard(player,"@@keolzhubi","keolzhubi0:",-1,sgs.Card_MethodNone)
					room:notifyMoveToPile(player,ids,"keolzhubi",sgs.Player_DrawPile,false)
					if uc then
						local dc = dummyCard()
						for _,id in sgs.qlist(uc:getSubcards())do
							if ids:contains(id) then
								ids:removeOne(id)
								dc:addSubcard(id)
							else
								ids:append(id)
							end
						end
						room:moveCardsToEndOfDrawpile(player,ids,"keolzhubi",false)
						room:obtainCard(player,dc,false)
					else
						room:returnToEndDrawPile(ids)
					end
					break
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end
}
keol_liuba:addSkill(keolzhubi)
sgs.LoadTranslationTable {
	["keol_liuba"] = "刘巴[OL]",
	["&keol_liuba"] = "刘巴",
	["#keol_liuba"] = "清尚之节",
	["designer:keol_liuba"] = "官方",
	["cv:keol_liuba"] = "官方",
	["illustrator:keol_liuba"] = "官方",

	["keolzhubi0"] = "请选择交换的牌",
	["keolzhubichoose"] = "请选择重铸的牌",
	["keoltongduchoose"] = "请选择一张牌交给%src",

	["keoltongdu"] = "统度",
	[":keoltongdu"] = "准备阶段，你可以令一名角色交给你一张手牌，然后出牌阶段结束时，你将此牌置于牌堆顶。",
	["keoltongdu-ask"] = "统度：你可以令一名角色交给你一张手牌",

	["keolzhubi"] = "铸币",
	[":keolzhubi"] = "出牌阶段限X次（X为你的体力上限），你可以令一名角色重铸一张牌，以此法摸的牌称为“币”；有“币”的角色的结束阶段，其观看牌堆底的五张牌，然后可以用任意“币”交换其中等量张牌。",
	["keolbi"] = "币",
	["#keolzhubi"] = "牌堆底",

	["$keoltongdu1"] = "上下调度，臣工皆有所为。",
	["$keoltongdu2"] = "统筹部划，不糜国利分毫。",
	["$keolzhubi1"] = "钱货之通者，在乎币。",
	["$keolzhubi2"] = "融金为料，可铸五铢。",

	["~keol_liuba"] = "恨未见，铸兵为币之日……",
}

keol_zhangyi = sgs.General(ol_ccxh,"keol_zhangyi","shu",4)
keoldianjun = sgs.CreateTriggerSkill{
	name = "keoldianjun",
	frequency = sgs.Skill_Compulsory,
	events = sgs.EventPhaseChanging,
	on_trigger = function(self,event,player,data,room)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		room:sendCompulsoryTriggerLog(player,self)
		room:damage(sgs.DamageStruct(self:objectName(),nil,player))
		if player:isDead() then return end
		local phase = player:getPhase()
		player:setPhase(sgs.Player_Play)
		room:broadcastProperty(player,"phase")
		local thread = room:getThread()
		if not thread:trigger(sgs.EventPhaseStart,room,player) then
			thread:trigger(sgs.EventPhaseProceeding,room,player)
		end
		thread:trigger(sgs.EventPhaseEnd,room,player)
		player:setPhase(phase)
		room:broadcastProperty(player,"phase")
	end,
	--[[can_trigger = function(self,player)
		return player
	end]]
}
keol_zhangyi:addSkill(keoldianjun)
keolkangrui = sgs.CreateTriggerSkill{
	name = "keolkangrui",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged,sgs.Damage,sgs.ConfirmDamage},
	on_trigger = function(self,event,player,data,room)
		if (event == sgs.Damage) then
			local damage = data:toDamage()
			if (damage.from:getMark("readydismax-Clear") > 0) then
				room:addMaxCards(player,-player:getMaxCards(),true)
			end
		end
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if (damage.from and damage.from:getMark("&keolkangrui-Clear") > 0) then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				room:addPlayerMark(player,"readydismax-Clear",1)
				room:removePlayerMark(damage.from,"&keolkangrui-Clear")
				player:damageRevises(data,1)
			end
		end
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if damage.to:hasFlag("CurrentPlayer") and damage.to:getMark("keolkangruifirst-Clear")<1 then
				room:setPlayerMark(damage.to,"keolkangruifirst-Clear",1)
				for _,zy in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
					local to_data = sgs.QVariant()
					to_data:setValue(damage.to)
					if zy:askForSkillInvoke(self,to_data) then
						room:broadcastSkillInvoke(self:objectName())
						zy:drawCards(1,self:objectName())
						if room:askForChoice(zy,self:objectName(),"huifu+damage",to_data) == "huifu"
						then room:recover(damage.to,sgs.RecoverStruct(self:objectName(),zy))
						else room:addPlayerMark(damage.to,"&keolkangrui-Clear") end
					end
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end
}
keol_zhangyi:addSkill(keolkangrui)
sgs.LoadTranslationTable {
	["keol_zhangyi"] = "张翼[OL]",
	["&keol_zhangyi"] = "张翼",
	["#keol_zhangyi"] = "奉公弗怠",
	["designer:keol_zhangyi"] = "官方",
	["cv:keol_zhangyi"] = "官方",
	["illustrator:keol_zhangyi"] = "官方",

	["keoldianjun"] = "殿军",
	[":keoldianjun"] = "锁定技，回合结束时，你受到1点无来源的伤害并执行一个额外的出牌阶段。",

	["keolkangrui:huifu"] = "令其回复1点体力",
	["keolkangrui:damage"] = "其本回合下次造成的伤害+1且造成伤害后手牌上限改为0",
	["keolkangrui"] = "亢锐",
	[":keolkangrui"] = "当一名角色于其回合内首次受到伤害后，你可以摸一张牌并选择一项：1.其回复1点体力；2.其本回合下次造成的伤害+1，且造成伤害后其此回合手牌上限改为0。",

	["$keoldianjun1"] = "大将军勿忧，翼可领后军。",
	["$keoldianjun2"] = "诸将速行，某自领军殿后。",
	["$keolkangrui1"] = "尔等魍魉，愿试吾剑之利乎？",
	["$keolkangrui2"] = "诸君鼓励，克复中原指日可待！",

	["~keol_zhangyi"] = "伯约不见疲惫之国力乎？",
}

keol_zhujun = sgs.General(ol_ccxh,"keol_zhujun","qun",4)
keolcuipo = sgs.CreateTriggerSkill{
	name = "keolcuipo",
	events = {sgs.CardUsed,sgs.ConfirmDamage,sgs.CardResponded},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			room:addPlayerMark(player,"&keolcuipo-Clear")
			if player:getMark("&keolcuipo-Clear") == use.card:nameLength() then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				if use.card:isKindOf("Slash") or (use.card:isKindOf("TrickCard") and use.card:isDamageCard()) then
					room:setCardFlag(use.card,"keolcuipo") 
				else
					player:drawCards(1,self:objectName())
				end
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("keolcuipo") then
				player:damageRevises(data,1)
			end
		elseif (event == sgs.CardResponded) then
			local response = data:toCardResponse()
			if response.m_isUse
			then
				room:addPlayerMark(player,"&keolcuipo-Clear")
				if player:getMark("&keolcuipo-Clear") == response.m_card:nameLength()
				then player:drawCards(1,self:objectName()) end
			end
		end
	end,
}
keol_zhujun:addSkill(keolcuipo)
sgs.LoadTranslationTable {
	["keol_zhujun"] = "朱儁[OL]",
	["&keol_zhujun"] = "朱儁",
	["#keol_zhujun"] = "钦明神武",
	["designer:keol_zhujun"] = "官方",
	["cv:keol_zhujun"] = "官方",
	["illustrator:keol_zhujun"] = "官方",

	["keolcuipo"] = "摧破",
	[":keolcuipo"] = "锁定技，当你于当前回合使用第X张牌时（X为此牌牌名字数），若此牌为【杀】或伤害类锦囊牌，此牌造成的伤害+1，否则你摸一张牌。",

	["$keolcuipo1"] = "虎贲冯河，何惧千城。",
	["$keolcuipo2"] = "长锋在手，万寇辟易。",

	["~keol_zhujun"] = "李郭匹夫，安敢辱我！",
}

keol_quhuang = sgs.General(ol_ccxh,"keol_quhuang","wu",3)
keolqiejian = sgs.CreateTriggerSkill{
	name = "keolqiejian",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceHand) 
		and move.from:getMark("&keolqiejian_lun")<1
		and move.from:isAlive() and move.is_last_handcard then
			local from = BeMan(room,move.from)
			local to_data = sgs.QVariant()
			to_data:setValue(from)
			if player:askForSkillInvoke(self,to_data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1,self:objectName())
				from:drawCards(1,self:objectName())
				local players = sgs.SPlayerList()
				if player:canDiscard(player,"ej") then
				    players:append(player)
				end
				if player:canDiscard(from,"ej") then
					if not players:contains(from) then
				        players:append(from)
					end
				end
				local disone = room:askForPlayerChosen(player,players,self:objectName(),"keolqiejian-ask",true)
				if disone then
					local to_throw = room:askForCardChosen(player,disone,"ej",self:objectName())
					room:throwCard(to_throw,disone,player)
				else
					room:setPlayerMark(from,"&keolqiejian_lun",1)
				end
			end
		end
		return false
	end,
}
keol_quhuang:addSkill(keolqiejian)
keolnishou = sgs.CreateTriggerSkill{
	name = "keolnishou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseEnd) then
			for _,qh in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
				if (qh:getMark("&keolnishoujiaohuan-Clear") > 0) then
					room:setPlayerMark(qh,"&keolnishoujiaohuan-Clear",0)
					local players = sgs.SPlayerList()
					players:append(qh)
					for _,p in sgs.qlist(room:getAllPlayers())do
						for _,pp in sgs.qlist(players)do
							if (p:getHandcardNum() < pp:getHandcardNum()) then
								players:append(p)
								players:removeOne(pp)
							end
						end
					end
					local eny = room:askForPlayerChosen(qh,players,self:objectName(),"keolnishou-ask",false,true)
					if eny then
						room:broadcastSkillInvoke(self:objectName())
						local move1 = sgs.CardsMoveStruct(qh:handCards(),eny,sgs.Player_PlaceHand,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,qh:objectName(),eny:objectName(),self:objectName(),""))
						local move2 = sgs.CardsMoveStruct(eny:handCards(),qh,sgs.Player_PlaceHand,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,eny:objectName(),qh:objectName(),self:objectName(),""))
						local exchangeMove = sgs.CardsMoveList()
						exchangeMove:append(move1)
						exchangeMove:append(move2)
						room:moveCardsAtomic(exchangeMove,false)
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime
		then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip)
			and move.from:objectName() == player:objectName()
			and move.to_place == sgs.Player_DiscardPile
			and player:hasSkill(self:objectName()) then
				local result = {}
				room:sendCompulsoryTriggerLog(player,self)
				local shandian = dummyCard("lightning")
				shandian:setSkillName("_keolnishou")
				if player:canUse(shandian,player) then table.insert(result,"shandian") end
				if player:getMark("&keolnishoujiaohuan-Clear")<1 then table.insert(result,"jiaohuan") end
				if room:askForChoice(player,self:objectName(),table.concat(result,"+"))=="shandian" then
					for i,id in sgs.qlist(move.card_ids)do
						if move.from_places:at(i)==sgs.Player_PlaceEquip
						and room:getCardPlace(id)==move.to_place then
							shandian = dummyCard("lightning")
							shandian:setSkillName("_keolnishou")
							shandian:addSubcard(id)
							if player:canUse(shandian,player) then
								room:useCard(sgs.CardUseStruct(shandian,player,player))
							end
						end
					end
				else
					room:setPlayerMark(player,"&keolnishoujiaohuan-Clear",1)
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
keol_quhuang:addSkill(keolnishou)
sgs.LoadTranslationTable{
	["keol_quhuang"] = "屈晃",
	["#keol_quhuang"] = "泥头自缚",
	["designer:keol_quhuang"] = "官方",
	["cv:keol_quhuang"] = "官方",
	["illustrator:keol_quhuang"] = "官方",

	["keolqiejian"] = "切谏",
	[":keolqiejian"] = "当一名角色失去最后的手牌后，你可以与其各摸一张牌，然后选择一项：1.弃置你或其场上的一张牌；2.你本轮不能对其发动此技能。",

	["keolnishou"] = "泥首",
	["keolnishou:shandian"] = "将此牌当【闪电】使用",
	["keolnishou:jiaohuan"] = "本阶段结束时与手牌数最少的角色交换手牌",
	[":keolnishou"] = "锁定技，当你装备区里的牌进入弃牌堆后，你选择一项：1.将此牌当【闪电】使用；2.本阶段结束时，你与一名全场手牌数最少的角色交换手牌且本阶段内你无法选择此项。",

	["keolnishoujiaohuan"] = "泥首交换",
	["keolnishou-ask"] = "请选择一名角色，阶段结束后与其交换手牌",
	["keolqiejian-ask"] = "你可以弃置你或该角色场上的一张牌",

	["$keolqiejian1"] = "东宫不稳，必使众人生异。",
	["$keolqiejian2"] = "今三方鼎持，不宜擅动储君。",
	["$keolnishou1"] = "臣以泥涂首，足证本心。",
	["$keolnishou2"] = "人生百年，终埋一抔黄土。",

	["~keol_quhuang"] = "臣死谏于斯，死得其所……",
}

keol_wenqin = sgs.General(ol_ccxh,"keol_wenqin","wei",4)
keolguangao = sgs.CreateTriggerSkill{
	name = "keolguangao",
	frequency == sgs.Skill_Frequent,
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") then
				--别人额外目标
			    for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:hasSkill(self) and (not use.to:contains(p))
					and player:askForSkillInvoke(self,ToData("keolguangao-ask:"..p:objectName()),false) then
						room:doAnimate(1,player:objectName(),p:objectName())
						use.to:append(p)
						room:sortByActionOrder(use.to)
					end
				end
				--自己用杀摸牌情形
				if use.from:isAlive() and use.from:hasSkill(self) and use.from:getHandcardNum()%2==0 then
					room:sendCompulsoryTriggerLog(use.from,self)
					use.from:drawCards(1,self:objectName())
					local fris = room:askForPlayersChosen(use.from,use.to,self:objectName(),0,99,"keolguangaominus-ask",true,true)
					local nullified_list = use.nullified_list
					for _,p in sgs.qlist(fris)do
						table.insert(nullified_list,p:objectName())
					end
					use.nullified_list = nullified_list
				end
				--被杀摸牌情形
				for _,p in sgs.qlist(use.to)do
					if p:isAlive() and p:hasSkill(self) and p:getHandcardNum()%2==0 then
						room:sendCompulsoryTriggerLog(p,self)
						p:drawCards(1,self:objectName())
						local fris = room:askForPlayersChosen(p,use.to,self:objectName(),0,99,"keolguangaominus-ask",true,true)
						local nullified_list = use.nullified_list
						for i,p in sgs.qlist(fris)do
							table.insert(nullified_list,p:objectName())
						end
						use.nullified_list = nullified_list
					end
				end
				data:setValue(use)
			end
		end
	end,
	can_trigger = function(self,target)
		return target ~= nil
	end
}
keol_wenqin:addSkill(keolguangao)
keolhuiqi = sgs.CreateTriggerSkill{
	name = "keolhuiqi",
	events = {sgs.TargetConfirmed,sgs.EventPhaseChanging},
	frequency = sgs.Skill_Wake,
	waked_skills = "keolxieju",
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,wq in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
					if wq:getMark(self:objectName())>0
					then continue end
					local n = 0
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if p:getMark("&keolhuiqi-Clear")>0
						then n = n+1 end
					end
					if n==3 and wq:getMark("&keolhuiqi-Clear") > 0
					or wq:canWake(self:objectName()) then
						room:sendCompulsoryTriggerLog(wq,self)
						room:doSuperLightbox(wq,self:objectName())
						room:setPlayerMark(wq,self:objectName(),1)
						room:changeMaxHpForAwakenSkill(wq,0,self:objectName())
						room:recover(wq,sgs.RecoverStruct(self:objectName(),wq))
						room:acquireSkill(wq,"keolxieju")
					end
				end
			end
		elseif event == sgs.TargetConfirmed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				local wqs = sgs.SPlayerList()
			    for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:hasSkill(self,true)
					and p:getMark(self:objectName())<1
					then wqs:append(p) end
				end
				if wqs:isEmpty() then return end
				for _,p in sgs.qlist(use.to)do
					if p:getMark("&keolhuiqi-Clear")<1 then
						room:setPlayerMark(p,"&keolhuiqi-Clear",1,wqs)
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
keol_wenqin:addSkill(keolhuiqi)
keolxiejuslash = sgs.CreateViewAsSkill{
	name = "keolxiejuslash",
	n = 1,
	view_filter = function(self,selected,to_select)
		local slash = dummyCard()
		slash:setSkillName("_keolxieju")
		slash:addSubcard(to_select)
		return to_select:isBlack()
		and not sgs.Self:isLocked(slash)
	end,
	view_as = function(self,cards)
		if #cards ~= 1 then return end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("_keolxieju")
		slash:addSubcard(cards[1])
		return slash
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern:startsWith("@@keolxiejuslash")
	end
}
ol_ccxh:addSkills(keolxiejuslash)
keolxiejuCard = sgs.CreateSkillCard{
	name = "keolxiejuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select)
		return (to_select:getMark("keolxiejutar-Clear") > 0)
	end,
	on_use = function(self,room,player,targets)
		for _,p in sgs.list(targets)do 
			--依次询问黑牌当杀
			room:askForUseCard(p,"@@keolxiejuslash","keolxiejuslash-ask") 
		end
	end
}
keolxiejuVS = sgs.CreateViewAsSkill{
	name = "keolxieju",
	n = 1,
	view_filter = function(self,selected,to_select)
	    local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		return to_select:isBlack() and pattern=="@@keolxiejuslash"
		and not sgs.Self:isLocked(to_select)
	end,
	view_as = function(self,cards)
	    local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@keolxiejuslash" then
			if #cards<1 then return end
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName("_keolxieju")
			slash:addSubcard(cards[1])
			return slash
		end
		return keolxiejuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#keolxiejuCard") 
	end,
}
keolxieju = sgs.CreateTriggerSkill{
	name = "keolxieju",
	view_as_skill = keolxiejuVS,
	events = {sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.TargetConfirmed) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				for _,p in sgs.qlist(use.to)do 
					room:addPlayerMark(p,"keolxiejutar-Clear")
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
ol_ccxh:addSkills(keolxieju)

sgs.LoadTranslationTable {
	["keol_wenqin"] = "文钦[OL]",
	["&keol_wenqin"] = "文钦",
	["#keol_wenqin"] = "困兽鸱张",
	["designer:keol_wenqin"] = "官方",
	["cv:keol_wenqin"] = "官方",
	["illustrator:keol_wenqin"] = "官方",

	["keolguangao"] = "犷骜",
	[":keolguangao"] = "你使用【杀】的目标数+1；其他角色使用【杀】时，其可以令你成为此【杀】的额外目标；当一名角色使用【杀】时，若你是使用者或目标且你的手牌数为偶数，你摸一张牌，然后可以令此【杀】对任意名角色无效。",
    ["keolguangao:keolguangao-ask"] = "你可以发动“犷骜”令 %src 成为此【杀】的额外目标",

	["keolhuiqi"] = "慧企",
	[":keolhuiqi"] = "觉醒技，一个回合结束时，若此回合成为过牌目标的角色数为3且包括你，你回复1点体力并获得“偕举”。",

	["keolxieju"] = "偕举",
	[":keolxieju"] = "出牌阶段限一次，你可以令任意名本回合成为过牌的目标的角色依次选择是否将一张黑色牌当【杀】使用。",
	["keolxiejuslashCard"] = "偕举",
	["keolxiejuCard"] = "偕举",

	["keolguangaominus-ask"] = "你可以发动“犷骜”令此【杀】对任意名目标角色无效",
	["keolxiejuslash-ask"] = "偕举：你可以将一张黑色牌当【杀】使用",

	["$keolguangao1"] = "大丈夫行事，焉能畏首畏尾。",
	["$keolguangao2"] = "策马觅封侯，长驱万里之数。",
	["$keolhuiqi1"] = "今大星西垂，此天降清君侧之证。",
	["$keolhuiqi2"] = "彗星竟于西北，此罚天狼之兆。",
	["$keolxieju1"] = "今举大义，誓与仲恭共死。",
	["$keolxieju2"] = "天降大任，当与志士同忾。",

	["~keol_wenqin"] = "天不佑国魏，天不佑族文！",
}

keol_tianchou = sgs.General(ol_ccxh,"keol_tianchou","qun",4)
keolshandaoCard = sgs.CreateSkillCard{
	name = "keolshandaoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select)
		return not to_select:isNude()
	end,
	on_use = function(self,room,player,targets)
		local tos1,tos2 = sgs.SPlayerList(),room:getOtherPlayers(player)
		for _,target in pairs(targets)do
			if target:isNude() then continue end
			local id = room:askForCardChosen(player,target,"he","keolshandao")
			room:moveCardTo(sgs.Sanguosha:getCard(id),player,sgs.Player_DrawPile)
			tos1:append(target)
			tos2:removeOne(target)
		end
		local wgfd = sgs.Sanguosha:cloneCard("amazing_grace")
		wgfd:setSkillName("_keolshandao")
		room:setCardFlag(wgfd,"YUANBEN")
		room:useCard(sgs.CardUseStruct(wgfd,player,tos1),true)
		wgfd:deleteLater()
		if tos2:isEmpty() then return end
		local wjqf = sgs.Sanguosha:cloneCard("archery_attack")
		wjqf:setSkillName("_keolshandao")
		room:setCardFlag(wjqf,"YUANBEN")
		room:useCard(sgs.CardUseStruct(wjqf,player,tos2),true)
		wjqf:deleteLater()
	end
}
keolshandao = sgs.CreateViewAsSkill{
	name = "keolshandao",
	n = 0,
	view_as = function(self,cards)
		return keolshandaoCard:clone()
	end,
	enabled_at_play = function(self,player)
		return (not player:hasUsed("#keolshandaoCard")) 
	end,
}
keol_tianchou:addSkill(keolshandao)
sgs.LoadTranslationTable {
	["keol_tianchou"] = "田畴",
	["#keol_tianchou"] = "乱世族隐",
	["designer:keol_tianchou"] = "官方",
	["cv:keol_tianchou"] = "官方",
	["illustrator:keol_tianchou"] = "官方",

	["keolshandao"] = "善刀",
	[":keolshandao"] = "出牌阶段限一次，你可以将任意名角色的各一张牌置于牌堆顶，若如此做，你视为对这些角色使用一张【五谷丰登】，然后视为对其余其他角色使用一张【万箭齐发】。",

	["$keolshandao1"] = "君子藏器，待天时而动。",
	["$keolshandao2"] = "善刀而藏之，可解充栋之牛。",

	["~keol_tianchou"] = "吾罪大矣，何堪封侯之荣。",
}

--马休马铁
keol_maxiumatie = sgs.General(ol_ccxh,"keol_maxiumatie","qun",4)
keol_maxiumatie:addSkill("mashu")
keolkenshangVS = sgs.CreateViewAsSkill{
	name = "keolkenshang",
	n = 999,
	view_filter = function(self,selected,to_select)
        return true
	end,
	view_as = function(self,cards)
		if #cards < 2 then return end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("keolkenshang")
		slash:setFlags("keolkenshang")
		for _,c in ipairs(cards)do
			slash:addSubcard(c)
		end
		return slash
	end,
	enabled_at_play = function(self,player)
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern == "slash" and sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	end
}
keolkenshang = sgs.CreateTriggerSkill{
	name = "keolkenshang",
	view_as_skill = keolkenshangVS,
	events = {sgs.Damage,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"keolkenshang")
			or use.card:hasFlag("keolkenshang") then
				if room:getTag("keolkenshangda"):toInt() < use.card:subcardsLength()
				then use.from:drawCards(1,self:objectName()) end
				room:removeTag("keolkenshangda")
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and (table.contains(damage.card:getSkillNames(),"keolkenshang") or damage.card:hasFlag("keolkenshang")) then
				local num = room:getTag("keolkenshangda"):toInt() + damage.damage
				room:setTag("keolkenshangda",sgs.QVariant(num))
			end
		end
	end,
	--[[can_trigger = function(self,target)
		return target 
	end]]
}
keol_maxiumatie:addSkill(keolkenshang)
sgs.LoadTranslationTable {
	["keol_maxiumatie"] = "马休＆马铁",
	["&keol_maxiumatie"] = "马休马铁",
	["#keol_maxiumatie"] = "颉翥三秦",
	["designer:keol_maxiumatie"] = "官方",
	["cv:keol_maxiumatie"] = "官方",
	["illustrator:keol_maxiumatie"] = "官方",

	["keolkenshang"] = "垦伤",
	[":keolkenshang"] = "你可以将至少两张牌当【杀】使用，且此【杀】的目标数限制为这些牌的数量，此【杀】结算完毕后，若这些牌的数量大于此【杀】造成的伤害，你摸一张牌。",

	["$keolkenshang1"] = "择兵选将，一击而大白。",
	["$keolkenshang2"] = "纵横三辅，垦伤庸富！",

	["~keol_maxiumatie"] = "我兄弟，愿随父帅赴死。",
}

--孙弘
keol_sunhong = sgs.General(ol_ccxh,"keol_sunhong","wu",3)
keolxianbiCard = sgs.CreateSkillCard{
	name = "keolxianbiCard",
	will_throw = true,
	filter = function(self,targets,to_select,player)
		return #targets<1 and to_select:getMark("keolzenrun"..player:objectName())<1
	end,
	on_use = function(self,room,player,targets)
		for _,target in sgs.list(targets)do
			local n = target:getEquips():length()-player:getHandcardNum()
			if n>0 then
				player:drawCards(n,"keolxianbi")
			elseif n<0 then
				local dc = room:askForDiscard(player,self:objectName(),-n,-n,false,false,"keolxianbidis:"..-n)
				for _,id in sgs.qlist(dc:getSubcards())do
					if player:isDead() then break end
					local cids = sgs.IntList()
					for _,idd in sgs.qlist(room:getDiscardPile())do
						if id~=idd and sgs.Sanguosha:getCard(idd):getType()==sgs.Sanguosha:getCard(id):getType()
						then cids:append(idd) end
					end
					if cids:length()>0 then
						local suiji = math.random(0,cids:length()-1)
						room:obtainCard(player,cids:at(suiji))
					end
				end
			end
		end
	end
}
keolxianbi = sgs.CreateViewAsSkill{
	name = "keolxianbi",
	n = 0,
	view_as = function(self,cards)
		return keolxianbiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#keolxianbiCard")
	end
}
keol_sunhong:addSkill(keolxianbi)
keolzenrun = sgs.CreateTriggerSkill{
	name = "keolzenrun",
	frequency = sgs.Skill_Frequent,
	events = {sgs.BeforeCardsMove,sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			for _,p in sgs.qlist(room:getAllPlayers())do
				room:setPlayerMark(p,"bankeolzenrunuse-Clear",0)
			end
		elseif event == sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand and move.to:objectName() == player:objectName()
			and move.reason.m_skillName~="InitialHandCards" and player:getMark("bankeolzenrunuse-Clear")<1
			and move.from_places:contains(sgs.Player_DrawPile) and player:hasSkill(self) then
				local n = move.card_ids:length()
				local canchoose = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:getMark("keolzenrun"..player:objectName())<1
					and p:getCardCount()>=n then canchoose:append(p) end
				end
				local eny = room:askForPlayerChosen(player,canchoose,self:objectName(),"keolzenrunask:"..n,true,true)
				if eny then
				    room:broadcastSkillInvoke(self:objectName())
					room:addPlayerMark(player,"bankeolzenrunuse-Clear")
					move:removeCardIds(move.card_ids)
					data:setValue(move)
					room:returnToTopDrawPile(move.card_ids)
					local dc = dummyCard()
					for i = 1,n do
						if dc:subcardsLength()>=eny:getCardCount() then break end
						local id = room:askForCardChosen(player,eny,"he",self:objectName(),false,sgs.Card_MethodNone,dc:getSubcards())
						if id<0 then break end
						dc:addSubcard(id)
					end
					room:obtainCard(player,dc,false)
					if room:askForChoice(eny,self:objectName(),"mopai+ban",ToData(player)) == "ban"
					then room:addPlayerMark(eny,"keolzenrun"..player:objectName())
					else eny:drawCards(n,self:objectName()) end
				end
			end		
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
keol_sunhong:addSkill(keolzenrun)
sgs.LoadTranslationTable {
	["keol_sunhong"] = "孙弘",
	["#keol_sunhong"] = "谮诉构争",
	["designer:keol_sunhong"] = "官方",
	["cv:keol_sunhong"] = "官方",
	["illustrator:keol_sunhong"] = "官方",

	["keolxianbi"] = "险诐",
	["keolxianbiCard"] = "险诐",
	["keolxianbidis"] = "险诐：请选择弃置的牌",

	[":keolxianbi"] = "出牌阶段限一次，你可以将手牌数调整至与一名角色装备区里的牌数相同，你因此每弃置一张牌，你从弃牌堆随机获得另一张与之类型相同的牌。",

	["keolzenrun-ask"] = "谮润：你可以放弃此摸牌并获得一名其他角色 %src 张牌",
	["keolzenrun:mopai"] = "摸等量的牌",
	["keolzenrun:ban"] = "其不能再发动“险诐”和“谮润”选择你",
	["keolzenrun"] = "谮润",
	[":keolzenrun"] = "每个阶段限一次，当你即将从牌堆获得牌时，你可以取消之并获得一名其他角色等量张牌，然后其选择一项：1.摸等量的牌；2.你不能再发动“险诐”和“谮润”选择其。",
	["keolzenrunask"] = "你即将摸 %src 张牌，你可以发动“谮润”改为获得一名其他角色等量的牌",

	["$keolxianbi1"] = "宦海如薄冰，求生逐富贵。",
	["$keolxianbi2"] = "吾不欲为鱼肉，故为刀俎。",
	["$keolzenrun1"] = "休妄论芍陂之战，当诛之。",
	["$keolzenrun2"] = "据图谋不轨，今奉诏索命。",

	["~keol_sunhong"] = "诸葛公何至于此……",
}

--卢氏
keol_lushi = sgs.General(ol_ccxh,"keol_lushi","qun",3,false)
keolzhuyan = sgs.CreateTriggerSkill{
	name = "keolzhuyan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart,sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:setPlayerMark(player,"keolzhuyanhp",player:getHp())
			room:setPlayerMark(player,"keolzhuyansp",player:getHandcardNum())
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Finish and player:hasSkill(self) then
				local canchoose = sgs.SPlayerList()
				local from = sgs.SPlayerList()
				from:append(player)
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:getMark("beusedzhuyanhp"..player:objectName())+p:getMark("beusedzhuyansp"..player:objectName())<2 then
						canchoose:append(p)
						local n = p:getMark("keolzhuyanhp")
						if n<1 then
							n = p:getGeneralStartHp()
							room:setPlayerMark(p,"keolzhuyanhp",n)
						end
						if p:getMark("beusedzhuyanhp"..player:objectName())<1 then 
							if n<2 then room:setPlayerMark(p,"&keolzhuyanhpzero",1,from)
							else room:setPlayerMark(p,"&keolzhuyanhp",n,from) end
						end
						n = p:getMark("keolzhuyansp")
						if p:getMark("beusedzhuyansp"..player:objectName())<1 then 
							if n<2 then room:setPlayerMark(p,"&keolzhuyanspzero",1,from)
							else room:setPlayerMark(p,"&keolzhuyansp",n,from) end
						end
					end
				end
				local theone = room:askForPlayerChosen(player,canchoose,self:objectName(),"keolzhuyanask",true,true)
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:getMark("beusedzhuyanhp"..player:objectName())+p:getMark("beusedzhuyansp"..player:objectName())<2 then
						room:setPlayerMark(p,"&keolzhuyanhpzero",0,from)
						room:setPlayerMark(p,"&keolzhuyanhp",0,from)
						room:setPlayerMark(p,"&keolzhuyanspzero",0,from)
						room:setPlayerMark(p,"&keolzhuyansp",0,from)
					end
				end
				if theone then
					local choices = {}
					if theone:getMark("beusedzhuyanhp"..player:objectName())<1 then table.insert(choices,"hp") end
					if theone:getMark("beusedzhuyansp"..player:objectName())<1 then table.insert(choices,"sp") end
					local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"))
					room:broadcastSkillInvoke(self)
					if choice == "hp" then
						room:addPlayerMark(theone,"beusedzhuyanhp"..player:objectName())
						local sethp = math.min(theone:getMark("keolzhuyanhp"),theone:getMaxHp())
						room:setPlayerProperty(theone,"hp",sgs.QVariant(sethp))
					elseif choice == "sp" then
						room:addPlayerMark(theone,"beusedzhuyansp"..player:objectName())
						local n = theone:getHandcardNum()-theone:getMark("keolzhuyansp")
						if n>0 then room:askForDiscard(theone,self:objectName(),n,n)
						elseif n<0 then theone:drawCards(-n,self:objectName()) end
					end
				end
			elseif player:getPhase() == sgs.Player_Start then
				room:setPlayerMark(player,"keolzhuyanhp",player:getHp())
				room:setPlayerMark(player,"keolzhuyansp",player:getHandcardNum())
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
keol_lushi:addSkill(keolzhuyan)
keolleijie = sgs.CreateTriggerSkill{
	name = "keolleijie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseProceeding) then
			if (player:getPhase() == sgs.Player_Start) then
				local theone = room:askForPlayerChosen(player,room:getAllPlayers(),self:objectName(),"keolleijieask",true,true)
				if theone then
					room:broadcastSkillInvoke(self:objectName())
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|spade|2~9"
					judge.good = false
					judge.negative = true
					judge.reason = self:objectName()
					judge.who = theone
					room:judge(judge)
					if judge:isBad() then
						local damage = sgs.DamageStruct()
						damage.to = theone
						damage.from = player
						damage.damage = 2
						damage.reason = self:objectName()
						damage.nature = sgs.DamageStruct_Thunder
						room:damage(damage)
					else
						theone:drawCards(2,self:objectName())
					end
				end
			end
		end
	end,
}
keol_lushi:addSkill(keolleijie)
sgs.LoadTranslationTable {
	["keol_lushi"] = "卢氏",
	["#keol_lushi"] = "蝉蜕蛇解",
	["designer:keol_lushi"] = "官方",
	["cv:keol_lushi"] = "官方",
	["illustrator:keol_lushi"] = "官方",

	["keolzhuyan"] = "驻颜",
	["keolzhuyanhp"] = "驻颜体力值",
	["keolzhuyansp"] = "驻颜手牌数",
	["keolzhuyanhpzero"] = "驻颜体力值[0]",
	["keolzhuyanspzero"] = "驻颜手牌数[0]",
	["keolzhuyan:hp"] = "调整其体力值",
	["keolzhuyan:sp"] = "调整其手牌数",
	["keolzhuyanask"] = "你可以选择发动“驻颜”调整一名角色的体力值或手牌数",
	[":keolzhuyan"] = "<font color='green'><b>每名角色每项限一次，结束阶段，</b></font>你可以令一名角色将体力值或手牌数调整至其上个准备阶段开始时的数值（若其没有执行过准备阶段，改为其游戏开始时的数值；至多摸至五张）。",

	["keolleijie"] = "雷劫",
	[":keolleijie"] = "<font color='green'><b>准备阶段，</b></font>你可以令一名角色判定，若结果为♠2~9，你对其造成2点雷电伤害，否则其摸两张牌。",
	["keolleijieask"] = "你可以选择发动“雷劫”的角色",

	["$keolzhuyan1"] = "心有灵犀，面如不老之椿。",
	["$keolzhuyan2"] = "驻颜有术，此间永得芳容。",
	["$keolleijie1"] = "雷劫锻体，清瘴涤魂。",
	["$keolleijie2"] = "欲得长生，必受此劫。",

	["~keol_lushi"] = "人世寻大道，何其愚也。",
}

keol_zhangyan = sgs.General(ol_ccxh,"keol_zhangyan","qun",4)
keolsujislash = sgs.CreateViewAsSkill{
	name = "keolsuji",
	n = 1,
	view_filter = function(self,selected,to_select)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("keolsuji")
		slash:addSubcard(to_select)
		slash:deleteLater()
		return not sgs.Self:isLocked(slash) and to_select:isBlack()
	end,
	view_as = function(self,cards)
		if #cards ~= 1 then return end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("keolsuji")
		slash:setFlags("keolsuji")
		slash:addSubcard(cards[1])
		return slash
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern:startsWith("@@keolsujislash")
	end
}
keolsuji = sgs.CreateTriggerSkill{
	name = "keolsuji",
	view_as_skill = keolsujislash,
	events = {sgs.EventPhaseStart,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"keolsuji")
			or use.card:hasFlag("keolsuji") then
				for _,p in sgs.qlist(room:getAllPlayers())do
					local to = p:getTag("keolsujiTo"):toPlayer()
					p:removeTag("keolsujiTo")
					if to and use.card:hasFlag("DamageDone_"..to:objectName())
					and to:getCardCount()>0 then 
						local card_id = room:askForCardChosen(p,to,"he",self:objectName())
						room:obtainCard(p,sgs.Sanguosha:getCard(card_id),false)
					end
				end	
			end
		end
		if event == sgs.EventPhaseStart and player:isWounded() 
		and player:getPhase() == sgs.Player_Play then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do 
				p:setTag("keolsujiTo",ToData(player))
				room:askForUseCard(p,"@@keolsujislash","keolsujislash-ask") 
				p:removeTag("keolsujiTo")
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
keol_zhangyan:addSkill(keolsuji)
keollangdao = sgs.CreateTriggerSkill{
	name = "keollangdao",
	events = {sgs.TargetSpecifying,sgs.CardFinished,sgs.ConfirmDamage},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.ConfirmDamage) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("usingkeollangdao") then
				player:damageRevises(data,room:getTag("keollangdaoDamage"..damage.card:toString()):toInt())
			end
		end
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("usingkeollangdao") then
				local rem = true
				for _,p in sgs.qlist(use.to)do
					if p:isDead() then
						rem = false
						break
					end
				end
				if rem then
					for _,ch in sgs.list(player:getTag("keollangdaoChoice"..use.card:toString()):toString():split("+"))do
						room:addPlayerMark(player,"removekeollangdao"..ch)
					end
				end
				--清除工作
				room:removeTag("keollangdaoDamage"..use.card:toString())
				player:removeTag("keollangdaoChoice"..use.card:toString())
			end
		end
		if (event == sgs.TargetSpecifying) then
			local use = data:toCardUse()
			if use.to:length() == 1
			and use.card:isKindOf("Slash") then
				local choices = {}
				for _,ch in sgs.list({"da","tar","res"})do
					if player:getMark("removekeollangdao"..ch)<1
					then table.insert(choices,ch) end
				end
				if #choices<1
				or not player:askForSkillInvoke(self,data)
				then return end
				room:broadcastSkillInvoke(self:objectName())
				room:setCardFlag(use.card,"usingkeollangdao")
				--自己选
				local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"))
				local extar,num = 0,0
				if choice == "da" then num = num+1
				elseif choice == "tar" then extar = extar+1 end
				--对手选
				local eny = use.to:at(0)
				local choicetwo = room:askForChoice(eny,self:objectName(),table.concat(choices,"+"))
				if choicetwo == "da" then num = num+1
				elseif choicetwo == "tar" then extar = extar+1 end
				local log = sgs.LogMessage()
				log.type = "$choosekeollangdaolog"
				log.from = player
				log.arg = "keollangdao:"..choice
				room:sendLog(log)
				log.from = eny
				log.arg = "keollangdao:"..choicetwo
				room:sendLog(log)
				room:setTag("keollangdaoDamage"..use.card:toString(),ToData(num))
				player:setTag("keollangdaoChoice"..use.card:toString(),ToData(choice.."+"..choicetwo))
			    if (extar > 0) then
					local canchoose = sgs.SPlayerList()
					for _,p in sgs.qlist(room:getAllPlayers())do 
						if player:canSlash(p,use.card,false) and not use.to:contains(p) then
							canchoose:append(p)
						end
					end
					local log = sgs.LogMessage()
					log.to = room:askForPlayersChosen(player,canchoose,self:objectName(),0,extar,"keollangdaotarask",false,false)
					for _,p in sgs.qlist(log.to)do 
						room:doAnimate(1,player:objectName(),p:objectName())
						use.to:append(p)
					end
					if (log.to:length() > 0) then
						log.type = "$langdaoextarlog"
						log.from = eny
						room:sendLog(log)
						room:sortByActionOrder(use.to)
					end
				end
				if choicetwo == "res"
				or choice == "res"
				then
					local no_respond_list = use.no_respond_list
					for _,szm in sgs.qlist(use.to)do
						table.insert(no_respond_list,szm:objectName())
					end
					use.no_respond_list = no_respond_list
				end
				data:setValue(use)
			end
		end
	end,
	--[[can_trigger = function(self,target)
		return target
	end]]
}
keol_zhangyan:addSkill(keollangdao)
sgs.LoadTranslationTable {
	["keol_zhangyan"] = "张燕",
	["#keol_zhangyan"] = "飞燕",
	["designer:keol_zhangyan"] = "官方",
	["cv:keol_zhangyan"] = "官方",
	["illustrator:keol_zhangyan"] = "官方",

	["keolsuji"] = "肃疾",
	[":keolsuji"] = "一名已受伤的角色的出牌阶段开始时，你可以将一张黑色牌当【杀】使用，此【杀】结算完毕后，若其受到过此【杀】造成的伤害，你获得其一张牌。",
	["keolsujislash-ask"] = "肃疾：你可以将一张黑色牌当【杀】使用",

	["keollangdao"] = "狼蹈",
	[":keollangdao"] = "当你使用【杀】指定唯一目标时，你可以令你与其各选择一项：1.此【杀】造成的伤害+1；2.你可以选择一名额外目标；3.此【杀】不能被响应。然后若此【杀】结算完毕后，目标角色均存活，你移除“狼蹈”此次被选择过的选项。",
	["keollangdao:da"] = "令此【杀】伤害+1",
	["keollangdao:tar"] = "令此【杀】目标数限制+1",
	["keollangdao:res"] = "令此【杀】不能被响应",

	["$choosekeollangdaolog"] = "%from 选择了 %arg",
	["$langdaoextarlog"] = "%from 选择了 %to 为额外目标",

	["keollangdaotarask"] = "狼蹈：你可以选择此【杀】的额外目标",

	["$keolsuji1"] = "飞燕如风，非快不得破。",
	["$keolsuji2"] = "载疾风之势，摧万仞之城。",
	["$keollangdao1"] = "虎踞黑山，望天下百城。",
	["$keollangdao2"] = "狼顾四野，视幽冀为饵。",

	["~keol_zhangyan"] = "草莽之辈，难登大雅之堂……",
}

--孟达
keol_mengda = sgs.General(ol_ccxh,"keol_mengda","shu",4)
keolgoudevs = sgs.CreateViewAsSkill{
	name = "keolgoude",
	view_as = function(self,cards)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("_keolgoude")
		slash:setFlags("keolgoude")
		return slash
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern:startsWith("@@keolgoude")
	end
}
keolgoude = sgs.CreateTriggerSkill{
    name = "keolgoude",
    events = {sgs.EventPhaseChanging,sgs.CardsMoveOneTime,sgs.KingdomChanged,sgs.CardUsed},
    frequency = sgs.Skill_NotFrequent,
	view_as_skill = keolgoudevs,
    on_trigger = function(self,event,player,data)
        local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.from and move.from:objectName() == player:objectName() and move.card_ids:length() == 1
			and move.reason.m_reason == sgs.CardMoveReason_S_REASON_DISMANTLE then--弃置一张手牌
				local who = BeMan(room,move.reason.m_playerId)
				if who and move.from_places:contains(sgs.Player_PlaceHand)
				then room:addPlayerMark(who,"keolgoudedis-Clear") end
			end
			if move.to and move.to:objectName() == player:objectName() and move.card_ids:length() == 1
			and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW
			then room:addPlayerMark(player,"keolgoudedraw-Clear") end--摸一张牌
		elseif (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash")
			and use.card:isVirtualCard() and use.card:subcardsLength()<1
			then room:addPlayerMark(player,"keolgoudeslash-Clear") end
		elseif (event == sgs.KingdomChanged) then
			room:addPlayerMark(player,"keolgoudekingdom-Clear")
		elseif (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return end
			for _,p in sgs.qlist(room:getAlivePlayers())do
				if p:hasSkill(self) then
					local can,choices = false,{}
					for _,ch in sgs.list({"draw","dis","slash","kingdom"})do
						local has = false
						for _,pp in sgs.qlist(room:getAlivePlayers())do
							if pp:getKingdom()~=p:getKingdom() then continue end
							if pp:getMark("keolgoude"..ch.."-Clear")>0
							then has = true break end
						end
						if has then can = true
						else table.insert(choices,ch) end
					end
					if #choices<1 or not can then break end
					table.insert(choices,"cancel")
					local choice = room:askForChoice(p,self:objectName(),table.concat(choices,"+"))
					if choice=="cancel" then continue end
					p:skillInvoked(self,-1)
					if choice=="draw" then
						p:drawCards(1,self:objectName())
					elseif choice=="dis" then
						choice = sgs.SPlayerList()
						for _,q in sgs.qlist(room:getAlivePlayers())do
							if p:canDiscard(q,"h") then choice:append(q) end
						end
						choice = room:askForPlayerChosen(p,choice,"keolgoude","keolgoude0:",true,true)
						if choice then
							local id = room:askForCardChosen(p,choice,"h","keolgoude",false,sgs.Card_MethodDiscard)
							if id>=0 then room:throwCard(id,choice,p) end
						end
					elseif choice=="slash" then
						room:askForUseCard(p,"@@keolgoude","keolgoude1:")
					elseif choice=="kingdom" then
						choice = room:askForKingdom(p,"keolgoudekingdom")
						room:changeKingdom(p,choice)
					end
				end
			end
		end
    end,
    can_trigger = function(self,target)
        return target and target:isAlive()
    end,
}
keol_mengda:addSkill(keolgoude)
sgs.LoadTranslationTable {
	["keol_mengda"] = "孟达",
	["#keol_mengda"] = "腾挪反复",
	["designer:keol_mengda"] = "官方",
	["cv:keol_mengda"] = "官方",
	["illustrator:keol_mengda"] = "官方",

	["keolgoude"] = "苟得",
	[":keolgoude"] = "一名角色的回合结束时，若与你势力相同的角色于本回合执行过以下项中的任意个，你可以选择一个未被执行过的项并执行：1.摸一张牌；2.弃置一名角色的一张手牌；3.视为使用一张【杀】；4.变更势力。",
	["keolgoude:draw"] = "摸一张牌",
	["keolgoude:dis"] = "弃置一名角色的一张手牌",
	["keolgoude:slash"] = "视为使用一张【杀】",
	["keolgoude:kingdom"] = "变更势力",
	["keolgoude0"] = "苟得：请选择一名角色弃置其手牌",
	["keolgoude1"] = "苟得：请视为使用一张【杀】",

	["$keolgoude1"] = "蝼蚁尚且偷生，况我大将军乎",
	["$keolgoude2"] = "为保身家性命，做奔臣又如何？",

	["~keol_mengda"] = "丞相援军何其远乎？",
}

--郝普
keol_haopu = sgs.General(ol_ccxh,"keol_haopu","shu",4)
keolzhenyingCard = sgs.CreateSkillCard{
	name = "keolzhenyingCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,player)
		return #targets < 1 and to_select:objectName() ~= player:objectName()
		and to_select:getHandcardNum() <= player:getHandcardNum()
	end,
	on_use = function(self,room,player,targets)
		local aps,hns = {},{}
		table.insert(aps,player)
		for _,target in sgs.list(targets)do
			table.insert(aps,target)
		end
		for _,p in sgs.list(aps)do
			hns[p:objectName()] = room:askForChoice(p,"keolzhenying","0+1+2",ToData(player))
		end
		for _,target in sgs.list(aps)do
			local n = target:getHandcardNum()-tonumber(hns[target:objectName()])
			if n>0 then room:askForDiscard(target,"keolzhenying",n,n)
			elseif n<0 then target:drawCards(-n,"keolzhenying") end
		end
		local function compare_func(a,b)
			return a:getHandcardNum()<b:getHandcardNum()
		end
		table.sort(aps,compare_func)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:setSkillName("_keolzhenying")
		duel:deleteLater()
		if aps[1]:getHandcardNum()<aps[#aps]:getHandcardNum() and aps[1]:canUse(duel,aps[#aps]) then
			room:useCard(sgs.CardUseStruct(duel,aps[1],aps[#aps]))
		end
	end
}
--主技能
keolzhenying = sgs.CreateViewAsSkill{
	name = "keolzhenying",
	n = 0,
	view_as = function(self,cards)
		return keolzhenyingCard:clone()
	end,
	enabled_at_play = function(self,player)
		return (player:usedTimes("#keolzhenyingCard") < 2)
	end,
}
keol_haopu:addSkill(keolzhenying)
sgs.LoadTranslationTable {
	["keol_haopu"] = "郝普",
	["&keol_haopu"] = "郝普",
	["#keol_haopu"] = "惭恨入地",
	["designer:keol_haopu"] = "官方",
	["cv:keol_haopu"] = "官方",
	["illustrator:keol_haopu"] = "官方",

	["keolzhenying"] = "镇荧",
	[":keolzhenying"] = "<font color='green'><b>出牌阶段限两次，</b></font>你可以与一名手牌数不大于你的其他角色分别将手牌数调整至两张或更少，然后手牌数较少的角色视为对另一名角色使用一张【决斗】。",
	["keolzhenying-discard"] = "镇荧：请弃置至两张牌或更少",
	["keolzhenying:0"] = "将手牌数调整为 0 张",
	["keolzhenying:1"] = "将手牌数调整为 1 张",
	["keolzhenying:2"] = "将手牌数调整为 2 张",

	["$keolzhenying1"] = "吾闻世间有忠义，今欲为之。",
	["$keolzhenying2"] = "吴虽兵临三郡，普宁死不降。",
	["~keol_haopu"] = "徒做奔臣，死无其所。",
}

--丁尚涴
keol_dingshangwan = sgs.General(ol_ccxh,"keol_dingshangwan","wei",3,false)
keolfudao = sgs.CreateTriggerSkill{
	name = "keolfudao",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart,sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_NotActive) then
				for _,dsw in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
					for _,p in sgs.qlist(room:getOtherPlayers(dsw))do
						if p:getHandcardNum() == dsw:getMark("&keolfudao")
						and p:getMark("&keolfudao+#"..dsw:objectName())>0
						and dsw:askForSkillInvoke(self,ToData(p)) then
							room:broadcastSkillInvoke(self:objectName())
							dsw:drawCards(1,self:objectName())
							p:drawCards(1,self:objectName())
						end
					end
				end
			end
		end
		if event == sgs.GameStart
		and player:hasSkill(self) then
			room:broadcastSkillInvoke(self:objectName())
			player:drawCards(3,self:objectName())
			local to = room:askForYiji(player,player:handCards(),self:objectName(),true,false,true,3,room:getOtherPlayers(player))
			if to then
				room:setPlayerMark(to,"&keolfudao+#"..player:objectName(),1)
				room:askForDiscard(player,"keolfudaodis",999,1,true,false,"keolfudao-discard")
				room:setPlayerMark(player,"&keolfudao",player:getHandcardNum())
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
keol_dingshangwan:addSkill(keolfudao)
keolfengyan = sgs.CreateTriggerSkill{
	name = "keolfengyan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged,sgs.CardResponded,sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if damage.from and damage.from ~= player then
				room:sendCompulsoryTriggerLog(player,self)
				if room:askForChoice(player,self:objectName(),"memo+hemo",ToData(damage.from)) == "memo" then
					player:drawCards(1,self:objectName())
					if damage.from:isDead() then return end
					local card = room:askForExchange(player,self:objectName(),1,1,true,"kenewmijichoose:"..damage.from:objectName(),false)
					if card then room:giveCard(player,damage.from,card,self:objectName()) end
				elseif damage.from:isAlive()
				then
					damage.from:drawCards(1,self:objectName())
					room:askForDiscard(damage.from,self:objectName(),2,2,false,true)
				end
			end
		elseif (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.whocard
			and use.who and player~=use.who then
				room:sendCompulsoryTriggerLog(player,self)
				if room:askForChoice(player,self:objectName(),"memo+hemo",ToData(use.who)) == "memo" then
					player:drawCards(1,self:objectName())
					if use.who:isDead() then return end
					local card = room:askForExchange(player,self:objectName(),1,1,true,"kenewmijichoose:"..use.who:objectName(),false)
					if card then room:giveCard(player,use.who,card,self:objectName()) end
				elseif use.who:isAlive() then
					use.who:drawCards(1,self:objectName())
					room:askForDiscard(use.who,self:objectName(),2,2,false,true)
				end
			end
		elseif (event == sgs.CardResponded) then
			local res = data:toCardResponse()
			if res.m_card:getTypeId()>0 and res.m_toCard
			and res.m_who and res.m_who~=player then
				room:sendCompulsoryTriggerLog(player,self)
				if room:askForChoice(player,self:objectName(),"memo+hemo",ToData(res.m_who)) == "memo" then
					player:drawCards(1,self:objectName())
					if res.m_who:isDead() then return end
					local card = room:askForExchange(player,self:objectName(),1,1,true,"kenewmijichoose:"..res.m_who:objectName(),false)
					if card then room:giveCard(player,res.m_who,card,self:objectName()) end
				elseif res.m_who:isAlive()
				then
					res.m_who:drawCards(1,self:objectName())
					room:askForDiscard(res.m_who,self:objectName(),2,2,false,true)
				end
			end
		end
	end,
	--[[can_trigger = function(self,target)
		return target 
	end]]
}
keol_dingshangwan:addSkill(keolfengyan)
sgs.LoadTranslationTable{
	["keol_dingshangwan"] = "丁尚涴[OL]",
	["&keol_dingshangwan"] = "丁尚涴",
	["#keol_dingshangwan"] = "我心匪席",
	["designer:keol_dingshangwan"] = "官方",
	["cv:keol_dingshangwan"] = "官方",
	["illustrator:keol_dingshangwan"] = "官方",

	["keolfudao"] = "抚悼",
	["keolfudaodis"] = "抚悼",
	[":keolfudao"] = "<font color='green'><b>游戏开始时，</b></font>你摸三张牌，然后你可以交给一名其他角色至多三张手牌，且你可以弃置任意张手牌，然后记录你的手牌数；每名角色的回合结束时，若其手牌数等于此数值，你可以与其各摸一张牌。",
	["keolfudao-ask"] = "抚悼：你可以选择交给牌的其他角色或取消",
	["keolfudaochoose"] = "抚悼：请选择给出的牌（至多三张）",
	["keolfudao-discard"] = "抚悼：你可以弃置任意张牌",
	
	["keolfengyan"] = "讽言",
	[":keolfengyan"] = "锁定技，当你受到其他角色造成的伤害后，或响应其他角色使用的牌后，你选择一项：1.你摸一张牌并交给其一张牌；2.其摸一张牌并弃置两张牌。",
	["kenewmijichoose"] = "讽言：请选择一张牌交给%src",
	["keolfengyan:memo"] = "你摸一张牌，然后交给其一张牌",
	["keolfengyan:hemo"] = "其摸一张牌，然后弃置两张牌",

	["$keolfudao1"] = "冰刃入腹，使肝肠寸断！",
	["$keolfudao2"] = "失子之殇，世间再无春秋。",
	["$keolfengyan1"] = "何不以曹公之命，换我儿之命乎！",
	["$keolfengyan2"] = "亲儿丧于宛城，曹公何颜复还？",

	["~keol_dingshangwan"] = "今生与曹，不复相见。",
}

makiol_zhangzhi = sgs.General(ol_ccxh,"makiol_zhangzhi","qun",3,true)
keolbixinCard = sgs.CreateSkillCard{
	name = "keolbixinCard",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		local pattern = self:getUserString()
		local use_card = dummyCard(pattern:split("+")[1])
		use_card:setSkillName("keolbixin")
		if use_card:targetFixed()
		then return false end
		local plist = sgs.PlayerList()
		for _,p in sgs.list(targets)do
			plist:append(p)
		end
		return use_card:targetFilter(plist,to_select,from)
	end,
	feasible = function(self,targets)
		local pattern = self:getUserString()
		local use_card = dummyCard(pattern:split("+")[1])
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets)do
			qtargets:append(p)
		end
		return use_card:targetFixed()
		or use_card:targetsFeasible(qtargets,player)
	end,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		local results = {}
		for _,pn in sgs.list({"basic","trick","equip"})do
			if use.from:getMark("keolbixin_"..pn) < 3
			then table.insert(results,pn) end
		end
		if #results<1 then return nil end
		use.from:skillInvoked("keolbixin",-1)
		local result = room:askForChoice(use.from,"keolbixintype",table.concat(results,"+"))
		local log = sgs.LogMessage()
		log.type = "#keolbixintype"
		log.from = use.from
		log.arg = result
		room:sendLog(log)
		use.from:drawCards(1,"keolbixin")
		if use.from:isDead() then return nil end
		for _,m in sgs.list(use.from:getMarkNames())do
			if m:startsWith("&keolbixin+:+") then
				room:setPlayerMark(use.from,m,0)
			end
		end
		room:addPlayerMark(use.from,"keolbixin_"..result)
		room:setPlayerMark(use.from,"&keolbixin+:+"..use.from:getMark("keolbixin_basic")..use.from:getMark("keolbixin_trick")..use.from:getMark("keolbixin_equip"),1)
		local pattern = self:getUserString()
		pattern = room:askForChoice(use.from,"keolbixin",pattern)
		local use_card = dummyCard(pattern)
		use_card:setSkillName("_keolbixin")
		for _,h in sgs.qlist(use.from:getHandcards())do
			if h:getType()==result then use_card:addSubcard(h) end
		end
		return use_card
	end,
	on_validate_in_response = function(self,from)
		local room = from:getRoom()
		local results = {}
		for _,pn in sgs.list({"basic","trick","equip"})do
			if from:getMark("keolbixin_"..pn) < 3
			then table.insert(results,pn) end
		end
		if #results<1 then return nil end
		from:skillInvoked("keolbixin",-1)
		local result = room:askForChoice(from,"keolbixintype",table.concat(results,"+"))
		local log = sgs.LogMessage()
		log.type = "#keolbixintype"
		log.from = from
		log.arg = result
		room:sendLog(log)
		from:drawCards(1,"keolbixin")
		if from:isDead() then return nil end
		for _,m in sgs.list(from:getMarkNames())do
			if m:startsWith("&keolbixin+:+") then
				room:setPlayerMark(from,m,0)
			end
		end
		room:addPlayerMark(from,"keolbixin_"..result)
		room:setPlayerMark(from,"&keolbixin+:+"..from:getMark("keolbixin_basic")..from:getMark("keolbixin_trick")..from:getMark("keolbixin_equip"),1)
		local pattern = self:getUserString()
		pattern = room:askForChoice(from,"keolbixin",pattern)
		local use_card = dummyCard(pattern)
		use_card:setSkillName("_keolbixin")
		for _,h in sgs.qlist(from:getHandcards())do
			if h:getType()==result then use_card:addSubcard(h) end
		end
		return use_card
	end
}
keolbixinVS = sgs.CreateViewAsSkill{
	name = "keolbixin",
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@keolbixin!" then
			pattern = sgs.Self:property("keolbixincard"):toString()
			local vbasic = sgs.Sanguosha:cloneCard(pattern)
			vbasic:setSkillName("_keolbixin")
			pattern = sgs.Self:property("keolbixintype"):toString()
			for _,h in sgs.list(sgs.Self:getHandcards())do
				if h:getType()==pattern then vbasic:addSubcard(h) end
			end
			return vbasic
		elseif pattern == "" then
			local dc = sgs.Self:getTag("keolbixin"):toCard()
			if dc==nil then return end
			pattern = dc:objectName()
		end
		local new_card = keolbixinCard:clone()
		new_card:setUserString(pattern)
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		if pattern=="@@keolbixin!" then return true end
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		or player:getMark("keolximotimes")<3
		then return false end
		local can = false
		for _,pn in sgs.list({"basic","trick","equip"})do
			if player:getMark("keolbixin_"..pn) < 3
			then can = true break end
		end
		if can==false then return false end
		for _,p in sgs.list(pattern:split("+"))do
			local dc = dummyCard(p)
			if dc and dc:getTypeId()==1
			and player:getMark("keolbixin_guhuo_remove_"..p)<1 then
				dc:setSkillName("keolbixin")
				if not player:isLocked(dc)
				then return true end
			end
		end
		return false
	end,
	enabled_at_play = function(self,player)
		if player:getMark("keolximotimes")<3
		then return false end
		local can = false
		for _,pn in sgs.list({"basic","trick","equip"})do
			if player:getMark("keolbixin_"..pn) < 3
			then can = true break end
		end
		if can==false then return false end
		for _,p in sgs.list(patterns())do
			local dc = dummyCard(p)
			if dc and dc:getTypeId()==1
			and player:getMark("keolbixin_guhuo_remove_"..p)<1 then
				dc:setSkillName("keolbixin")
				if dc:isAvailable(player)
				then return true end
			end
		end
		return false
	end,
}
keolbixin = sgs.CreateTriggerSkill{
	name = "keolbixin",
	view_as_skill = keolbixinVS,
	guhuo_type = "l",
	events = {sgs.EventPhaseStart,sgs.CardUsed,sgs.RoundEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if use.card:isKindOf("BasicCard") then
				--记录每轮使用的基本牌
				room:addPlayerMark(player,"keolbixin_guhuo_remove_"..use.card:objectName())
			end
		elseif (event == sgs.RoundEnd) then--清除记录
			for _,m in sgs.list(player:getMarkNames())do
				if m:startsWith("keolbixin_guhuo_remove_")
				then room:setPlayerMark(player,m,0) end
			end
		elseif (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Start) or (player:getPhase() == sgs.Player_Finish) then
				for _,zz in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
					local t = zz:getMark("keolximotimes")
					if (t < 1 or player == zz)--第一次修改后不能在其他回合发动发动
					and (t < 2 and player:getPhase() == sgs.Player_Start--准备阶段不能被删除
					or t < 3 and player:getPhase() == sgs.Player_Finish)--结束阶段不能被删除
					then
						local results = {}
						for _,pn in sgs.list({"basic","trick","equip"})do
							if zz:getMark("keolbixin_"..pn) < 1
							then table.insert(results,pn) end
						end
						if #results<1 then continue end
						local choices = {}
						--筛选加入游戏中的所有基本牌
						for _,id in sgs.qlist(room:getAvailableCardList(zz,"basic","keolbixin"))do
							local tcard = sgs.Sanguosha:getEngineCard(id)
							--是基本牌，能使用，且没有被本轮记录过
							if zz:getMark("keolbixin_guhuo_remove_"..tcard:objectName())<1
							then table.insert(choices,tcard:objectName()) end
						end
						if #choices<1 or not zz:askForSkillInvoke(self,ToData(table.concat(choices,"+"))) then continue end
						local result = room:askForChoice(zz,"keolbixintype",table.concat(results,"+"))
						local log = sgs.LogMessage()
						log.type = "#keolbixintype"
						log.from = zz
						log.arg = result
						room:sendLog(log)
						zz:drawCards(3,"keolbixin")
						if zz:isDead() then continue end
						for _,m in sgs.list(zz:getMarkNames())do
							if m:startsWith("&keolbixin+:+") then
								room:setPlayerMark(zz,m,0)
							end
						end
						room:addPlayerMark(zz,"keolbixin_"..result)
						room:setPlayerMark(zz,"&keolbixin+:+"..zz:getMark("keolbixin_basic")..zz:getMark("keolbixin_trick")..zz:getMark("keolbixin_equip"),1)
						local choice = room:askForChoice(zz,"keolbixin",table.concat(choices,"+"))
						room:setPlayerProperty(zz,"keolbixintype",ToData(result))
						room:setPlayerProperty(zz,"keolbixincard",ToData(choice))
						if room:askForUseCard(zz,"@@keolbixin!","keolbixin0:"..result..":"..choice)
						then continue end
						local dc = dummyCard(choice)
						dc:setSkillName("_keolbixin")
						for _,h in sgs.qlist(zz:getHandcards())do
							if h:getType()==result then dc:addSubcard(h) end
						end
						local use = sgs.CardUseStruct(dc,zz,sgs.SPlayerList())
						if dc:targetFixed() then
							room:useCard(use,true)
						else
							use.to = zz:getRandomTargets(dc)
							room:useCard(use,true)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
}
makiol_zhangzhi:addSkill(keolbixin)
keolximo = sgs.CreateTriggerSkill{
	name = "keolximo",
	waked_skills = "keolfeibai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"keolbixin") then
				room:addPlayerMark(player,"keolximotimes")
				local n = player:getMark("keolximotimes")
				room:sendCompulsoryTriggerLog(player,self:objectName())
				room:broadcastSkillInvoke(self:objectName(),n)
				room:changeTranslation(player,"keolbixin",n)
				if n>2 then
					--标记此时洗墨完成
					room:setPlayerMark(player,"keolximodone",1)
					room:handleAcquireDetachSkills(player,"-keolximo|keolfeibai")
				end
			end
		end
	end,
}
makiol_zhangzhi:addSkill(keolximo)
keolfeibai = sgs.CreateTriggerSkill{
	name = "keolfeibai",
	change_skill = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreHpRecover,sgs.DamageCaused},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.PreHpRecover then
			local rec = data:toRecover()
			if rec.card and not rec.card:isRed() then
				local use = room:getUseStruct(rec.card)
				if use.from and use.from:hasSkill(self) then
					local n = use.from:getChangeSkillState(self:objectName())
					if n==2 then
						room:setChangeSkillState(player,self:objectName(),1)
						room:sendCompulsoryTriggerLog(player,self)
						rec.recover = rec.recover + 1
						data:setValue(rec)
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local dmg = data:toDamage()
			if dmg.card and not dmg.card:isBlack() then
				local use = room:getUseStruct(dmg.card)
				if use.from and use.from:hasSkill(self) then
					local n = use.from:getChangeSkillState(self:objectName())
					if n==1 then
						room:setChangeSkillState(player,self:objectName(),2)
						room:sendCompulsoryTriggerLog(player,self)
						player:damageRevises(data,1)
					end
				end
			end
		end
	end,
}
ol_ccxh:addSkills(keolfeibai)
sgs.LoadTranslationTable{
    ["makiol_zhangzhi"] = "张芝",
    ["#makiol_zhangzhi"] = "草圣",
	["designer:makiol_zhangzhi"] = "玄蝶既白",
	["cv:makiol_zhangzhi"] = "官方",
    ["illustrator:makiol_zhangzhi"] = "君桓文化",

    ["keolbixin"] = "笔心",
	["keolbixintype"] = "笔心",
	["keolbixin:cancel"] = "不发动“笔心”",
	["#keolbixintype"] = "%from 声明了 %arg",
	["keolbixin0"] = "笔心：将手牌中所有%src当做【%dest】使用",

	["keolbixin-ask"] = "笔心：请选择此牌的目标",
    [":keolbixin"] = "每名角色的准备阶段和结束阶段，你可以声明一种牌的类型并摸3张牌（每种类型限1次），将所有此类型手牌当你本轮未使用过的基本牌使用。",
    [":keolbixin1"] = "准备阶段和结束阶段，你可以声明一种牌的类型并摸3张牌（每种类型限1次），将所有此类型手牌当你本轮未使用过的基本牌使用。",
    [":keolbixin2"] = "结束阶段，你可以声明一种牌的类型并摸3张牌（每种类型限1次），将所有此类型手牌当你本轮未使用过的基本牌使用。",
    [":keolbixin3"] = "你可以声明一种牌的类型并摸1张牌（每种类型限3次），将所有此类型手牌当你本轮未使用过的基本牌使用。",
    ["$keolbixin1"] = "携笔落云藻，文书剖纤毫。",
    ["$keolbixin2"] = "执纸抒胸臆，挥笔涕汍澜。",

    ["keolximo"] = "洗墨",
    [":keolximo"] = "锁定技，当你发动“笔心”使用牌时，删除“笔心”技能描述的前五个字；当你第三次发动“笔心”使用牌时，你交换“笔心”描述中的两个阿拉伯数字，然后失去“洗墨”并获得“飞白”。",
    ["$keolximo1"] = "帛尽漂洗，以待后用。",
    ["$keolximo2"] = "故帛无尽，而笔不停也。",
	["$keolximo3"] = "以帛为纸，临池习书。",

	["keolfeibai"] = "飞白",
	[":keolfeibai"] = "转换技，锁定技，阳：当你的非黑色牌造成伤害时，此伤害+1；阴：当你的非红色牌回复体力时，此回复值+1。",
	[":keolfeibai1"] = "转换技，锁定技，阳：当你的非黑色牌造成伤害时，此伤害+1。<font color='#01A5AF'><s>阴：当你的非红色牌回复体力时，此回复值+1。</s></font>",
	[":keolfeibai2"] = "转换技，锁定技，<font color='#01A5AF'><s>阳：当你使用非黑色牌造成伤害时，此伤害+1；</s></font>阴：当你使用非红色牌回复体力时，回复值+1。",
    ["$keolfeibai1"] = "字之体势，一笔而成。",
    ["$keolfeibai2"] = "超前绝伦，独步无双。",

    ["~makiol_zhangzhi"] = "力透三分，何以言老……",
}

keol_caoxi = sgs.General(ol_ccxh,"keol_caoxi","wei",3)

keolgangshu = sgs.CreateTriggerSkill{
	name = "keolgangshu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.DrawNCards,sgs.CardUsed,sgs.CardFinished},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.whocard and use.whocard:getTypeId()>0
			and use.to:isEmpty() and not use.card:isAvailable(player) then
				room:setPlayerMark(player,"keolgangshuGjfw",0)
				room:setPlayerMark(player,"keolgangshuMp",0)
				room:setPlayerMark(player,"keolgangshuSha",0)
				for _,m in sgs.list(player:getMarkNames())do
					if m:startsWith("&keolgangshu+:+") then
						room:setPlayerMark(player,m,0)
					end
				end
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason~="draw_phase" or player:getMark("keolgangshuMp")<1 then return end
			draw.num = draw.num + player:getMark("keolgangshuMp")
			data:setValue(draw)
			room:setPlayerMark(player,"keolgangshuMp",0)
			for _,m in sgs.list(player:getMarkNames())do
				if m:startsWith("&keolgangshu+:+") then
					room:setPlayerMark(player,m,0)
				end
			end
			room:setPlayerMark(player,"&keolgangshu+:+"..player:getMark("keolgangshuGjfw")..player:getMark("keolgangshuMp")..player:getMark("keolgangshuSha"),1)
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId()<2 then return false end
			--每项至多增加至5，若都加满了，就不询问玩家
			--其中摸牌数包含额定摸牌数取2，不太严谨
			local choices = {}
			if player:getAttackRange()<5 then table.insert(choices,"Gjfw") end
			if 2+player:getMark("keolgangshuMp")<5 then table.insert(choices,"Mp") end
			if 1+sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,player,dummyCard())<5
			then table.insert(choices,"Sha") end
			if #choices > 0 and player:askForSkillInvoke(self,data) then
				room:broadcastSkillInvoke(self:objectName())
				local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"))
				room:addPlayerMark(player,"keolgangshu"..choice)
				for _,m in sgs.list(player:getMarkNames())do
					if m:startsWith("&keolgangshu+:+") then
						room:setPlayerMark(player,m,0)
					end
				end
				room:setPlayerMark(player,"&keolgangshu+:+"..player:getMark("keolgangshuGjfw")..player:getMark("keolgangshuMp")..player:getMark("keolgangshuSha"),1)
			end
		end
	end,
}
keol_caoxi:addSkill(keolgangshu)
keolgangshuex = sgs.CreateAttackRangeSkill{
	name = "keolgangshuex",
	extra_func = function(self,target)
		local n = target:getMark("&keoldouchan")
		if target:getMark("keolgangshuGjfw")>0 and target:hasSkill("keolgangshu") then
			n = n+target:getMark("keolgangshuGjfw")
		end
		return n+target:getMark("&olmoubaojing_add")-target:getMark("&olmoubaojing_remove")
	end,
    fixed_func = function(self,target)
		local n = -1
		if target:getMark("keolshanduancpgjfw-PlayClear")>0 and target:hasSkill("keolshanduan")
		then n = target:getMark("keolshanduancpgjfw-Clear") end
		if target:hasSkill("olmoujiaodi") then
			n = math.max(n,target:getHp()) 
		end
		return n
	end
}
ol_ccxh:addSkills(keolgangshuex)

keoljianxuan = sgs.CreateTriggerSkill{
	name = "keoljianxuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data,room)
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			local one = room:askForPlayerChosen(player,room:getAllPlayers(),self:objectName(),"keoljianxuan-ask",true,true)
			if one then
				room:broadcastSkillInvoke(self:objectName())
				while one:isAlive()do
					one:drawCards(1,self:objectName())
					--额定摸牌数默认2，不太严谨
					if one:getHandcardNum() == 2+player:getMark("&keolgangshu_mp")
					or one:getHandcardNum() == player:getAttackRange()
					or one:getHandcardNum() == 1+sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,player,dummyCard())
					then else break end
					room:getThread():delay(999)
				end
			end
		end
	end,
}
keol_caoxi:addSkill(keoljianxuan)

sgs.LoadTranslationTable{
	["keol_caoxi"] = "曹羲",
	["&keol_caoxi"] = "曹羲",
	["#keol_caoxi"] = "魁立倾厦",
	["designer:keol_caoxi"] = "玄蝶既白",
	["cv:keol_caoxi"] = "官方",
	["illustrator:keol_caoxi"] = "官方",

	["keolgangshu"] = "刚述",
	["Gjfw"] = "增加攻击范围",
	["Mp"] = "增加额定摸牌数",
	["Sha"] = "增加【杀】使用次数限制",
	[":keolgangshu"] = "当你使用非基本牌结算后，你可令你以下一项数值+1（至多增加至5）：<br/>1.攻击范围；<br/>2.下个摸牌阶段摸牌数；<br/>3.出牌阶段使用【杀】次数。<br/>当你抵消一张牌时，清空以此法增加的数值。",

	["keoljianxuan"] = "谏旋",
	["keoljianxuan-ask"] = "你可以选择发动“谏旋”的角色",
	[":keoljianxuan"] = "当你受到伤害后，你可以令一名角色摸一张牌，若其手牌数等于你“刚述”描述中的任意一项的数值，其重复此流程。",

	["$keolgangshu1"] = "羲而立之年，当为立身之事。",
	["$keolgangshu2"] = "总六军之要，秉选举之机。",
	["$keoljianxuan1"] = "司马氏卧虎藏龙，大兄安能小觑。",
	["$keoljianxuan2"] = "兄长以兽为猎，殊不知己亦为猎乎？",
	["~keol_caoxi"] = "曹氏亡矣，大魏亡矣！",

}

keol_duanjiong = sgs.General(ol_ccxh,"keol_duanjiong","qun",4)

keolsaoguslash = sgs.CreateViewAsSkill{
	name = "keolsaoguslash",
	expand_pile = "#keolsaoguslash",
	response_pattern = "@@keolsaoguslash",
	n = 1,
	enabled_at_play = function(self,player)
		return false
	end,
	view_filter = function(self,selected,to_select)
		return to_select:isKindOf("Slash") and not sgs.Self:isLocked(to_select)
		and sgs.Self:getPileName(to_select:getId())=="#keolsaoguslash"
	end,
	view_as = function(self,cards)
		if #cards>0 then
			return cards[1]
		end
	end
}
ol_ccxh:addSkills(keolsaoguslash)
keolsaogu2Card = sgs.CreateSkillCard{
	name = "keolsaogu2Card",
	--target_fixed = true,
	--will_throw = true,
	skill_name = "keolsaogu",
	filter = function(self,targets,to_select,source)
		return #targets<1 and to_select~=source
	end,
	on_use = function(self,room,source,targets)
		if (source:getChangeSkillState("keolsaogu") == 1) then
			for _,tp in ipairs(targets)do
				local pattern = {}
				for _,m in ipairs(tp:getMarkNames())do
					if m:contains("keolsaoguSuit") and tp:getMark(m)>0 then
						table.insert(pattern,"^"..m:split("ke")[1])
					end
				end
				if #pattern<1 then pattern = "."
				else pattern = table.concat(pattern,"+") end
				local dc = room:askForDiscard(tp,"keolsaogu",2,2,false,true,"",".|"..pattern)
				if dc then
					local alls = dc:getSubcards()
					while tp:isAlive() and alls:length()>0 do
						local can = false
						for _,id in sgs.qlist(alls)do
							if sgs.Sanguosha:getCard(id):isKindOf("Slash")
							then can = true end
						end
						if can then
							room:notifyMoveToPile(tp,alls,"keolsaoguslash",sgs.Player_DiscardPile,true)
							can = room:askForUseCard(tp,"@@keolsaoguslash","keolsaoguslash_ask")
							room:notifyMoveToPile(tp,alls,"keolsaoguslash",sgs.Player_DiscardPile,false)
							if can then
								alls:removeOne(can:getEffectiveId())
							else
								break
							end
						else
							break
						end
					end
				end
			end
		else
			for _,tp in ipairs(targets)do
				tp:drawCards(1,"keolsaogu")
			end
		end
	end
}
keolsaoguCard = sgs.CreateSkillCard{
	name = "keolsaoguCard",
	target_fixed = true,
	--will_throw = true,
	on_use = function(self,room,source,target)
		if (source:getChangeSkillState("keolsaogu") == 1) then
			room:setChangeSkillState(source,"keolsaogu",2)
			local alls = self:getSubcards()
			while source:isAlive() and alls:length()>0 do
				local can = false
				for _,id in sgs.qlist(alls)do
					if sgs.Sanguosha:getCard(id):isKindOf("Slash")
					then can = true end
				end
				if can then
					room:notifyMoveToPile(source,alls,"keolsaoguslash",sgs.Player_DiscardPile,true)
					can = room:askForUseCard(source,"@@keolsaoguslash","keolsaoguslash_ask")
					room:notifyMoveToPile(source,alls,"keolsaoguslash",sgs.Player_DiscardPile,false)
					if can then
						alls:removeOne(can:getEffectiveId())
					else
						break
					end
				else
					break
				end
			end
		else
			room:setChangeSkillState(source,"keolsaogu",1)
			source:drawCards(1,"keolsaogu")
		end
	end
}
keolsaoguVS = sgs.CreateViewAsSkill{
	name = "keolsaogu",
	n = 2,
	response_pattern = "@@keolsaogu",
	view_filter = function(self,selected,to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@keolsaogu" then
		    return #selected < 1 and not sgs.Self:isJilei(to_select)
		end
		if sgs.Self:getChangeSkillState("keolsaogu") == 1 then
		    return #selected < 2 and not sgs.Self:isJilei(to_select)
			and sgs.Self:getMark(to_select:getSuitString().."keolsaoguSuit-PlayClear")<1
		end
	end,
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@keolsaogu" then
			if #cards<1 then return end
			local card = keolsaogu2Card:clone()
			for _,c in ipairs(cards)do
				card:addSubcard(c)
			end
		    return card
		end
		if sgs.Self:getChangeSkillState("keolsaogu") == 1 then
			if #cards<2 then return end
			local card = keolsaoguCard:clone()
			for _,c in ipairs(cards)do
				card:addSubcard(c)
			end
			return card
		else
		    return keolsaoguCard:clone()
		end
	end,
	enabled_at_play = function(self,player)
		return true--not player:hasUsed("#keyugongCard")
	end
}
keolsaogu = sgs.CreateTriggerSkill{
	name = "keolsaogu",
	view_as_skill = keolsaoguVS,
	change_skill = true,
	events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		--结束阶段
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Finish
		and player:getCardCount()>0 and player:hasSkill(self) then
			room:askForUseCard(player,"@@keolsaogu","keolsaogus_ask:")
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD
			and move.from and move.from:objectName()==player:objectName() then
				for _,id in sgs.qlist(move.card_ids)do
					local c = sgs.Sanguosha:getCard(id)
					room:addPlayerMark(player,c:getSuitString().."keolsaoguSuit-PlayClear")
				end
			end
		end
	end,
}
keol_duanjiong:addSkill(keolsaogu)

ol_pengyang = sgs.General(ol_ccxh,"ol_pengyang","shu",3)
olxiaofan0Card = sgs.CreateSkillCard{
	name = "olxiaofan0Card",
	target_fixed = true,
	about_to_use = function(self,room,use)
		if self:getUserString()~="@@olxiaofan2" then
			local n = 1
			for _,m in sgs.list(use.from:getMarkNames())do
				if m:startsWith("&olxiaofan+") and use.from:getMark(m)>0 then
					n = n+#m:split("+")-1
					break
				end
			end
			local ids = room:getNCards(n,true,false)
			local cans = {}
			for _,id in sgs.list(ids)do
				if sgs.Sanguosha:getCard(id):isAvailable(use.from)
				then table.insert(cans,id) end
			end
			use.from:skillInvoked("olxiaofan",-1)
			room:setPlayerProperty(use.from,"olxiaofanPattern",ToData(table.concat(cans,"+")))
			room:notifyMoveToPile(use.from,ids,"olxiaofan",sgs.Player_DrawPile,true)
			room:returnToEndDrawPile(ids)
			room:askForUseCard(use.from,"@@olxiaofan1","olxiaofan0:",-1,sgs.Card_MethodUse,true,nil,nil,"olxiaofanUse")
			room:notifyMoveToPile(use.from,ids,"olxiaofan",sgs.Player_DrawPile,false)
		end
	end
}
olxiaofanCard = sgs.CreateSkillCard{
	name = "olxiaofanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,source)
		local pattern = self:getUserString()
		if pattern=="" then return false end
		local dc = dummyCard(pattern:split("+")[1])
		if dc:targetFixed() then return false end
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets)do
			qtargets:append(p)
		end
        return dc:targetFilter(qtargets,to_select,source)
	end,
	feasible = function(self,targets,player)
		local pattern = self:getUserString()
		if pattern=="" then return true end
		local dc = dummyCard(pattern:split("+")[1])
		local qtargets = sgs.PlayerList()
		for _,p in ipairs(targets)do
			qtargets:append(p)
		end
		return dc:targetFixed()
		or dc:targetsFeasible(qtargets,player)
	end,
	on_validate = function(self,use)
		local n = 1
		local room = use.from:getRoom()
		for _,m in sgs.list(use.from:getMarkNames())do
			if m:startsWith("&olxiaofan+") and use.from:getMark(m)>0 then
				n = n+#m:split("+")-1
				break
			end
		end
		local ids = room:getNCards(n,true,false)
		use.from:skillInvoked("olxiaofan",-1)
		room:setPlayerProperty(use.from,"olxiaofanPattern",ToData(self:getUserString()))
		room:notifyMoveToPile(use.from,ids,"olxiaofan",sgs.Player_DrawPile,true)
		local dc = room:askForUseCard(use.from,"@@olxiaofan2","olxiaofan0:")
		room:notifyMoveToPile(use.from,ids,"olxiaofan",sgs.Player_DrawPile,false)
		room:returnToEndDrawPile(ids)
		if dc then
			dc = sgs.Sanguosha:getCard(dc:getEffectiveId())
			room:setCardFlag(dc,"olxiaofanUse")
			return dc
		end
		return nil
	end,
	on_validate_in_response = function(self,from)
		local n = 1
		local room = from:getRoom()
		for _,m in sgs.list(from:getMarkNames())do
			if m:startsWith("&olxiaofan+:") and from:getMark(m)>0 then
				n = n+#m:split("+")-1
				break
			end
		end
		room:setPlayerProperty(from,"olxiaofanPattern",ToData(self:getUserString()))
		local ids = room:getNCards(n,true,false)
		from:skillInvoked("olxiaofan",-1)
		room:notifyMoveToPile(from,ids,"olxiaofan",sgs.Player_DrawPile,true)
		local dc = room:askForUseCard(from,"@@olxiaofan2","olxiaofan0:")
		room:notifyMoveToPile(from,ids,"olxiaofan",sgs.Player_DrawPile,false)
		room:returnToEndDrawPile(ids)
		if dc then
			dc = sgs.Sanguosha:getCard(dc:getEffectiveId())
			room:setCardFlag(dc,"olxiaofanUse")
			return dc
		end
		return nil
	end,
}
olxiaofanvs = sgs.CreateViewAsSkill{
	name = "olxiaofan",
	expand_pile = "#olxiaofan",
	n = 1,
	view_filter = function(self,selected,to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@olxiaofan1" then
			pattern = sgs.Self:property("olxiaofanPattern"):toString():split("+")
		    return table.contains(pattern,to_select:toString())
			and sgs.Self:getPileName(to_select:getId())=="#olxiaofan"
		end
		if pattern=="@@olxiaofan2" then
			pattern = sgs.Self:property("olxiaofanPattern"):toString()
			for _,pn in sgs.list(pattern:split("+"))do
				if to_select:sameNameWith(pn) then
					return sgs.Self:getPileName(to_select:getId())=="#olxiaofan"
					and not sgs.Self:isLocked(to_select)
				end
			end
		end
	end,
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@olxiaofan1" then
			if #cards<1 then return end
			return cards[1]
		elseif pattern=="@@olxiaofan2" then
			if #cards<1 then return end
			local sc = olxiaofan0Card:clone()
			sc:setUserString(pattern)
			sc:addSubcard(cards[1])
			return sc
		elseif pattern~="" then
			local sc = olxiaofanCard:clone()
			sc:setUserString(pattern)
			return sc
		end
		local sc = olxiaofan0Card:clone()
		sc:setUserString(pattern)
		return sc
	end,
	enabled_at_response = function(self,player,pattern)
		if pattern:startsWith("@@olxiaofan") then return true end
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return end
		for _,pn in sgs.list(pattern:split("+"))do
			local dc = dummyCard(pn)
			if dc and not player:isLocked(dc)
			then return true end
		end
	end,
	enabled_at_play = function(self,player)
		return true
	end,
}
olxiaofan = sgs.CreateTriggerSkill{
    name = "olxiaofan",
	view_as_skill = olxiaofanvs,
	events = {sgs.CardFinished},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				if player:getMark(use.card:getType().."olxiaofan-Clear")<1 then
					MarkRevises(player,"&olxiaofan-Clear",use.card:getType().."_char")
					player:addMark(use.card:getType().."olxiaofan-Clear")
				end
				if use.card:hasFlag("olxiaofanUse") then
					local n = 0
					for _,m in sgs.list(player:getMarkNames())do
						if m:startsWith("&olxiaofan+") and player:getMark(m)>0 then
							n = n+#m:split("+")-1
							break
						end
					end
					room:sendCompulsoryTriggerLog(player,self)
					for i=1,n do
						if i==1 then
							local dc = dummyCard()
							dc:addSubcards(player:getJudgingArea())
							if dc:subcardsLength()>0 then
								room:throwCard(dc,self:objectName(),nil)
							end
						elseif i==2 then
							local dc = dummyCard()
							dc:addSubcards(player:getEquips())
							if dc:subcardsLength()>0 then
								room:throwCard(dc,self:objectName(),nil)
							end
						elseif i==3 then
							local dc = dummyCard()
							dc:addSubcards(player:getHandcards())
							if dc:subcardsLength()>0 then
								room:throwCard(dc,self:objectName(),nil)
							end
						end
					end
				end
			end
		end
	end,
}
ol_pengyang:addSkill(olxiaofan)
olruishi = sgs.CreateTriggerSkill{
    name = "olruishi",
	events = {sgs.CardFinished,sgs.CardUsed,sgs.PreCardUsed,sgs.EventPhaseChanging},
	frequency = sgs.Skill_Compulsory,
	waked_skills = "#olruishibf,#olruishibf2",
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isDamageCard() then
				if use.card:hasFlag("DamageDone") then return end
				player:addMark("olruishiDamageCard-Clear")
				if player:getMark("olruishiDamageCard-Clear")==3 then
					room:sendCompulsoryTriggerLog(player,self)
					room:addPlayerMark(player,"Qingchengolxiaofan")
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				for _,p in sgs.list(use.to)do
					if p:getHandcardNum()<player:getHandcardNum() then
						room:setPlayerMark(player,"&olruishi",0)
						break
					end
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				if use.card:getNumber()==1
				or use.card:getNumber()==11
				or use.card:getNumber()==12
				or use.card:getNumber()==13 then
					room:sendCompulsoryTriggerLog(player,self)
					local nullified = use.nullified_list
					table.insert(nullified,"_ALL_TARGETS")
					use.nullified_list = nullified
					data:setValue(use)
					player:drawCards(1,self:objectName())
					room:setPlayerMark(player,"&olruishi",1)
					room:setCardFlag(use.card,"olruishiNullified")
				end
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive
			or player:getMark("olruishiDamageCard-Clear")<3 then return end
			room:removePlayerMark(player,"Qingchengolxiaofan")
		end
	end,
}
ol_pengyang:addSkill(olruishi)
olruishibf = sgs.CreateCardLimitSkill{
	name = "#olruishibf",
	limit_list = function(self,player)
		return "use"
	end,
	limit_pattern = function(self,player)
		if player:hasSkill("olruishi") then return "Nullification" end
		return ""
	end
}
ol_pengyang:addSkill(olruishibf)
olruishibf2 = sgs.CreateTargetModSkill{
	name = "#olruishibf2",
	pattern = ".",
	residue_func = function(self,from,card,to)-- 额外使用
		if to and from:getHandcardNum()>to:getHandcardNum() and from:getMark("&olruishi")>0 and from:hasSkill("olruishi")
		or card:isKindOf("BasicCard") and from:getMark("keolduoshou_basic-Clear")<1 and from:hasSkill("keolduoshou")
		or from:getMark("mouzhaxiangCardUsed-Clear") < from:getLostHp() and from:hasSkill("mouzhaxiang")
		or to and from:getMark(to:objectName().."SkillEffect24-SelfClear")>0
		or from:hasFlag("dlszCardBuff") and from:hasSkill("ol_shengzhi")
		or table.contains(card:getSkillNames(), "xdbaohe")
		or table.contains(card:getSkillNames(), "yuanjue")
		or from:getMark("&juqi-Clear")>0
		then return 999 end
		if not card:isVirtualCard() and from:hasSkill("xingtu") then
			local n,x = card:getNumber(),from:getMark("&xingtu")
			if n<1 or x<1 then return 0 end
			for i=1,n do
				if x*i==n then
					return 999
				end
			end
		end
		if from:hasSkill("nosxingtu") then
			local n,x = card:getNumber(),from:getMark("&nosxingtu")
			if n<1 or x<1 then return 0 end
			for i=1,n do
				if x*i==n then
					return 999
				end
			end
		end
		return 0
	end,
	distance_limit_func = function(self,from,card,to)-- 使用距离
		if to and from:getHandcardNum()>to:getHandcardNum() and from:getMark("&olruishi")>0 and from:hasSkill("olruishi")
		or from:getMark("mouzhaxiangCardUsed-Clear") < from:getLostHp() and from:hasSkill("mouzhaxiang")
		or card:isRed() and from:getMark("keolduoshou_red-Clear")<1 and from:hasSkill("keolduoshou")
		or to and to:getMark("&sscybpingding") > 0 and from:hasSkill("yingba")
		or from:hasFlag("dlszCardBuff") and from:hasSkill("ol_shengzhi")
		or to and from:getMark(to:objectName().."SkillEffect24-SelfClear")>0
		or card:isKindOf("TrickCard") and from:hasSkill("mouqicai")
		or card:isKindOf("Slash") and from:hasFlag("daojueBf0")
		or card:hasFlag("ofjunweiBf0")
		then return 999 end
		return 0
	end,
	extra_target_func = function(self,from,card)--目标数
		if card:isKindOf("IronChain") and from:getMark("mouniepaned")>0
		and from:hasSkill("moulianhuan") then return 999 end
		return 0
	end
}
ol_pengyang:addSkill(olruishibf2)
ol_pengyang:addSkill("cunmu")


sgs.Sanguosha:setPackage(ol_ccxh)

local mobile_sp = sgs.Sanguosha:getPackage("mobile_sp")

--谯周
qiaozhou = sgs.General(mobile_sp,"qiaozhou","shu",3)

zhiming = sgs.CreateTriggerSkill{
name = "zhiming",
events = {sgs.EventPhaseStart,sgs.EventPhaseEnd},
on_trigger = function(self,event,player,data,room)
	if event == sgs.EventPhaseStart then
		if player:getPhase() ~= sgs.Player_Start then return false end
	else
		if player:getPhase() ~= sgs.Player_Discard then return false end
	end
	room:sendCompulsoryTriggerLog(player,self)
	player:drawCards(1,self:objectName())
	if player:isDead() or player:isNude() then return false end
	local card = room:askForCard(player,"..","@zhiming-put",data,sgs.Card_MethodNone)
	if not card then return false end
	room:moveCardTo(card,nil,sgs.Player_DrawPile,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,player:objectName(),"zhiming",""))
	return false
end
}

xingbu = sgs.CreatePhaseChangeSkill{
name = "xingbu",
frequency = sgs.Skill_Frequent,
on_phasechange = function(self,player,room)
	if player:getPhase() ~= sgs.Player_Finish or not player:askForSkillInvoke(self) then return false end
	player:peiyin(self)
	local shows = room:showDrawPile(player,3,"xingbu")
	local red = 0
	for _,id in sgs.qlist(shows)do
		if sgs.Sanguosha:getCard(id):isRed() then
			red = red + 1
		end
	end
	if red > 0 then
		local mark = "xbwuxinglianzhu"
		if red == 2 then
			mark = "xbfukuangdongzhu"
		elseif red <= 1 then
			mark = "xbyinghuoshouxin"
		end
		local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),mark,"@xingbu-invoke:"..mark)
		room:doAnimate(1,player:objectName(),to:objectName())
		if to:isAlive() then
			room:addPlayerMark(to,"&"..mark.."-SelfClear")
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	for _,id in sgs.qlist(shows)do
		if room:getCardPlace(id) == sgs.Player_PlaceTable
		then slash:addSubcard(id) end
	end
	slash:deleteLater()
	if slash:subcardsLength() > 0 then
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_NATURAL_ENTER,player:objectName(),"xingbu","")
		room:throwCard(slash,reason,nil)
	end
	return false
end
}

xingbuEffect = sgs.CreateTriggerSkill{
name = "#xingbuEffect",
events = {sgs.EventPhaseChanging,sgs.DrawNCards,sgs.CardFinished},
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	if event == sgs.EventPhaseChanging then
		if data:toPhaseChange().to ~= sgs.Player_Discard or player:getMark("&xbwuxinglianzhu-SelfClear") <= 0 then return false end
		if player:isSkipped(sgs.Player_Discard) then return false end
		sendZhenguLog(player,"xingbu")
		player:skip(sgs.Player_Discard)
	elseif event == sgs.DrawNCards then
		local draw = data:toDraw()
		if draw.reason~="draw_phase" then return end
		local mark = player:getMark("&xbwuxinglianzhu-SelfClear")
		if mark <= 0 then return false end
		sendZhenguLog(player,"xingbu")
		draw.num = draw.num+2*mark
		data:setValue(draw)
	else
		if player:getPhase() ~= sgs.Player_Play then return false end
		local mark = player:getMark("&xbfukuangdongzhu-SelfClear")
		if mark <= 0 then return false end
		local use = data:toCardUse()
		if use.card:isKindOf("SkillCard") or player:getMark("xingbuEffect-PlayClear")>0 then return false end
		player:addMark("xingbuEffect-PlayClear")
		for i = 1,mark do
			if player:isDead() or not player:canDiscard(player,"he") then break end
			sendZhenguLog(player,"xingbu")
			room:askForDiscard(player,"xingbu",1,1,false,true)
			player:drawCards(2,"xingbu")
		end
	end
	return false
end
}

qiaozhou:addSkill(zhiming)
qiaozhou:addSkill(xingbu)
qiaozhou:addSkill(xingbuEffect)
mobile_sp:insertRelatedSkills("xingbu","#xingbuEffect")

kemobile_caosong = sgs.General(mobile_sp,"kemobile_caosong","wei",3)
local yijinMarks = {"keyijin_wushi","keyijin_jinmi","keyijin_guxiong","keyijin_tongshen","keyijin_yongbi","keyijin_houren"}
kemobileyijin = sgs.CreateTriggerSkill{
	name = "kemobileyijin",
	events = {sgs.GameStart,sgs.EventPhaseStart,sgs.EventPhaseChanging,sgs.DrawNCards,sgs.DamageInflicted},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()--通神
			if damage.nature ~= sgs.DamageStruct_Thunder
			and damage.to:getMark("diskeyijin_tongshen-SelfClear")>0
			and player:getMark("@diskeyijin_tongshen")>0 then
				room:sendCompulsoryTriggerLog(player,"diskeyijin_tongshen")
				return player:damageRevises(data,-damage.damage)
			end
		elseif event == sgs.EventPhaseStart--贾凶
		and player:getPhase() == sgs.Player_Play
		and player:getMark("keyijin_guxiong-SelfClear")>0
		and player:getMark("@keyijin_guxiong")>0 then
			room:sendCompulsoryTriggerLog(player,"keyijin_guxiong")
			room:loseHp(player, 1, true, player, "keyijin_guxiong")
			room:addMaxCards(player,-3)
		elseif event == sgs.DrawNCards--V我50
		and player:getMark("keyijin_wushi-SelfClear")>0
		and player:getMark("@keyijin_wushi")>0 then
			local draw = data:toDraw()
			if draw.reason~="draw_phase" then return end
			room:sendCompulsoryTriggerLog(player,"keyijin_wushi")
			room:addSlashCishu(player,1)
			draw.num = draw.num + 4
			data:setValue(draw)
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if (change.to == sgs.Player_Play or change.to == sgs.Player_Discard)--金迷
			and player:getMark("keyijin_jinmi-SelfClear")>0
			and player:getMark("@keyijin_jinmi")>0 then
				if not player:isSkipped(change.to) then
					room:sendCompulsoryTriggerLog(player,"keyijin_jinmi")
			    	player:skip(change.to)
				end
			elseif change.to == sgs.Player_Draw--拥蔽
			and player:getMark("keyijin_yongbi-SelfClear")>0
			and player:getMark("@keyijin_yongbi")>0 then
				if not player:isSkipped(sgs.Player_Draw) then
					room:sendCompulsoryTriggerLog(player,"keyijin_yongbi")
			    	player:skip(sgs.Player_Draw)
				end
			elseif change.to == sgs.Player_NotActive then
				if player:getMark("keyijin_houren-SelfClear")>0--厚任
				and player:getMark("@keyijin_houren")>0 then
					room:sendCompulsoryTriggerLog(player,"keyijin_houren")
					room:recover(player,sgs.RecoverStruct(self:objectName(),nil,3))	
				end
				for _,m in sgs.list(yijinMarks)do
					if player:getMark(m.."-SelfClear") > 0
					then player:loseMark("@"..m) end
				end
			end
		elseif event == sgs.EventPhaseStart
		and player:hasSkill(self) then
			if player:getPhase() == sgs.Player_RoundStart then
				local has = false
				for _,m in sgs.list(yijinMarks)do
					if player:getMark("@"..m) > 0
					then has = true break end
				end
				if has then return end
				room:sendCompulsoryTriggerLog(player,self,3)
				room:getThread():delay()
				room:killPlayer(player)
			elseif player:getPhase() == sgs.Player_Play then
				local chooseplayers = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					local has = false
					for _,m in sgs.list(yijinMarks)do
						if p:getMark("@"..m) > 0
						then has = true break end
					end
					if has==false then chooseplayers:append(p) end
				end
				if chooseplayers:isEmpty() then return end
				local choices = {}
				for _,m in sgs.list(yijinMarks)do
					if player:getMark("@"..m) > 0
					then table.insert(choices,m) end
				end
				if #choices<1 then return end
				room:sendCompulsoryTriggerLog(player,self,math.random(1,2))
				local giveone = room:askForPlayerChosen(player,chooseplayers,self:objectName(),"kemobileyijin-ask",false,true)
				local choice = room:askForChoice(player,"kemobileyijin",table.concat(choices,"+"))
				player:loseMark("@"..choice)
				--结束后要扔这个的
				room:addPlayerMark(giveone,choice.."-SelfClear")
				giveone:gainMark("@"..choice)
			end
		elseif event == sgs.GameStart
		and player:hasSkill(self) then
			room:sendCompulsoryTriggerLog(player,self,math.random(1,2))
			for _,m in sgs.list(yijinMarks)do
				player:gainMark("@"..m)
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end
}
kemobile_caosong:addSkill(kemobileyijin)
kemobileguanzongCard = sgs.CreateSkillCard{
	name = "kemobileguanzongCard",
	will_throw = true,
	filter = function(self,targets,to_select,player)
		return (#targets == 0) and (to_select:objectName() ~= player:objectName())
	end,
	on_use = function(self,room,player,targets)
		for _,target in sgs.list(targets)do
			local players = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getOtherPlayers(target))do
				if p ~= player then players:append(p) end
			end
			local to = room:askForPlayerChosen(player,players,self:objectName(),"kemobileguanzong-ask",false,false)
			if to then
				local log = sgs.LogMessage()
				log.type = "$kehuiyaolog"
				log.from = target
				log.to:append(to)
				room:sendLog(log)
				room:doAnimate(1,target:objectName(),to:objectName())
				local data = sgs.QVariant()
				data:setValue(sgs.DamageStruct("kemobileguanzong",target,to))
				room:getThread():delay()
				room:getThread():trigger(sgs.Damage,room,target,data)
				room:getThread():trigger(sgs.Damaged,room,to,data)
			end
		end
	end
}
kemobileguanzong = sgs.CreateViewAsSkill{
	name = "kemobileguanzong",
	view_as = function(self,cards)
		return kemobileguanzongCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#kemobileguanzongCard")
	end
}
kemobile_caosong:addSkill(kemobileguanzong)
sgs.LoadTranslationTable {
	["kemobile_caosong"] = "曹嵩[手杀]",
	["&kemobile_caosong"] = "曹嵩",
	["#kemobile_caosong"] = "舆金贾权",
	["designer:kemobile_caosong"] = "官方",
	["cv:kemobile_caosong"] = "官方",
	["illustrator:kemobile_caosong"] = "官方",

	["kemobileyijin"] = "亿金",
	[":kemobileyijin"] = "锁定技，游戏开始时，你获得六种“金”标记各1枚；回合开始时，若你没有“金”标记，你死亡；出牌阶段开始时，你将1枚“金”标记交给一名其他角色并令其执行对应效果，若如此做，其回合结束后弃置之。\
	<font color='#CFB53B'><b>膴仕：下回合的摸牌阶段多摸四张牌，且出牌阶段可以多使用一张【杀】；\
	金迷：跳过下回合的出牌阶段和弃牌阶段；\
	贾凶：下回合的出牌阶段开始时，失去1点体力且该回合手牌上限-3；\
	通神：防止受到的非雷电伤害；\
	拥蔽：跳过下回合的摸牌阶段；\
	厚任：下回合结束时，回复3点体力。</b></font>",

	["kemobileguanzong-ask"] = "请选择视为造成伤害的 受伤角色",
	["kemobileyijin-ask"] = "请选择“亿金”交给标记的角色",

	["@keyijin_wushi"] = "膴仕",
	["@keyijin_jinmi"] = "金迷",
	["@keyijin_guxiong"] = "贾凶",
	["@keyijin_tongshen"] = "通神",
	["@keyijin_yongbi"] = "拥蔽",
	["@keyijin_houren"] = "厚任",

	["keyijin_wushi"] = "膴仕：摸牌阶段多摸四张，出牌阶段可多使用一张【杀】",
	["keyijin_jinmi"] = "金迷：跳过出牌和弃牌阶段",
	["keyijin_guxiong"] = "贾凶：出牌阶段开始时失去1点体力且手牌上限-3",
	["keyijin_tongshen"] = "通神：防止非雷电伤害",
	["keyijin_yongbi"] = "拥蔽：跳过摸牌阶段",
	["keyijin_houren"] = "厚任：回合结束时回复3点体力",

	["kemobileguanzong"] = "惯纵",
	[":kemobileguanzong"] = "出牌阶段限一次，你可以令一名其他角色视为对另一名其他角色造成过1点伤害。",

	["$kemobileyijin1"] = "吾家资巨万，无惜此两贯三钱！",
	["$kemobileyijin2"] = "小儿持金过闹市，哼！杀人何需我多劳！",
	["$kemobileyijin3"] = "普天之下，竟有吾难市之职？",
	["$kemobileguanzong1"] = "汝为叔父，怎可与小辈计较！",
	["$kemobileguanzong2"] = "阿瞒生龙活虎，汝切勿胡言！",

	["~kemobile_caosong"] = "长恨人心不如水，等闲平地起波澜……",
}

mobile_peixiu = sgs.General(mobile_sp,"mobile_peixiu","qun",3)
--代码改自时光流逝FC、俺的西木野Maki写的手杀裴秀
xingtu = sgs.CreateTriggerSkill{
    name = "xingtu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:getTypeId()<1 then return end
		local x,n = player:getMark("&xingtu"),use.card:getNumber()
		if n<1 then return end
		room:setPlayerMark(player,"&xingtu",n)
		if x<1 then return end
		for i=1,n do
			if x*i==n
			then
				room:broadcastSkillInvoke(self:objectName())
				break
			end
		end
		for i=1,x do
			if x/n==i
			then
				room:sendCompulsoryTriggerLog(player,self)
				room:drawCards(player,1,self:objectName())
				break
			end
		end
	end,
}
mobilejvezhiCard = sgs.CreateSkillCard{
	name = "mobilejvezhi",
	will_throw = true,
	target_fixed = true,
	on_use = function(self,room,source,targets)
		local num = 0
		for _,id in sgs.qlist(self:getSubcards())do
			num = num + sgs.Sanguosha:getCard(id):getNumber()
		end
		num = num%13
		if num<1 then num = 13 end
		local jvezhi_gets = {}
		for _,id in sgs.qlist(room:getDrawPile())do
			local cd = sgs.Sanguosha:getCard(id)
			if cd:getNumber() == num then
				table.insert(jvezhi_gets,cd)
			end
		end
		if #jvezhi_gets > 0 then
			local jvezhi_card = jvezhi_gets[math.random(1,#jvezhi_gets)]
			room:obtainCard(source,jvezhi_card,true)
		end
	end,
}
mobilejvezhi = sgs.CreateViewAsSkill{
	name = "mobilejvezhi",
	n = 999,
	view_filter = function(self,selected,to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self,cards)
		if #cards <= 1 then return nil end
		local skillcard = mobilejvezhiCard:clone()
		for _,c in ipairs(cards)do
			skillcard:addSubcard(c)
		end
		return skillcard
	end,
	enabled_at_play = function(self,player)
		return player:getCardCount() >= 2
	end,
}
mobile_peixiu:addSkill(xingtu)
mobile_peixiu:addSkill(mobilejvezhi)
sgs.LoadTranslationTable{
	["mobile_peixiu"] = "裴秀",
	["#mobile_peixiu"] = "晋图开秘",
	["cv:mobile_peixiu"] = "官方",
	["designer:mobile_peixiu"] = "未知",
	["illustrator:mobile_peixiu"] = "官方",
	["xingtu"] = "行图",
	[":xingtu"] = "锁定技，你使用牌时，若此牌的点数是X的约数，你摸一张牌。你使用牌为X的倍数的非转化牌无次数限制（X为你使用的上一张牌的点数）。",
	["$xingtu1"] = "图设分率，则宇内地域皆可绘于一尺。",
	["$xingtu2"] = "制图之体有六，缺一不可言精。",
	["mobilejvezhi"] = "爵制",
	[":mobilejvezhi"] = "出牌阶段，你可以弃置至少两张牌，然后从牌堆随机获得一张点数为X的牌（X为你弃置牌点数之和对13取余，但若余数为0则X为13）。",
	["$mobilejvezhi1"] = "表为建爵五等，实则藩卫帝室。",
	["$mobilejvezhi2"] = "复设五等之制，以解天下土崩之势。",
	["~mobile_peixiu"] = "既食寒食散，便不可饮冷酒啊...",
}
---------------------------------
nos_mobile_peixiu = sgs.General(mobile_sp,"nos_mobile_peixiu","qun",3)
nosxingtu = sgs.CreateTriggerSkill{
    name = "nosxingtu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.CardUsed then
	    	local use = data:toCardUse()
		    if use.card:isKindOf("SkillCard") then return false end
		    local x,n = player:getMark("&nosxingtu"),use.card:getNumber()
			if x<1 or n<1 then return false end
			for i=1,n do
				if x*i==n
				then
					room:broadcastSkillInvoke(self:objectName())
					break
				end
			end
			for i=1,x do
				if x/n==i
				then
					room:sendCompulsoryTriggerLog(player,self)
					room:drawCards(player,1,self:objectName())
					break
				end
			end
		else
	    	local use = data:toCardUse()
		    local n = use.card:getNumber()
		    if n<1 or use.card:isKindOf("SkillCard") then return false end
		    room:setPlayerMark(player,"&nosxingtu",n)
		end
	end,
}
nosmobilejvezhiCard = sgs.CreateSkillCard{
	name = "nosmobilejvezhi",
	will_throw = true,
	target_fixed = true,
	on_use = function(self,room,source,targets)
		local num = 0
		for _,id in sgs.qlist(self:getSubcards())do
			num = sgs.Sanguosha:getCard(id):getNumber()
		end
		if num > 13 then num = 13 end
		local list = {}
		for _,id in sgs.qlist(room:getDrawPile())do
			local cards = sgs.Sanguosha:getCard(id):getNumber()
			if cards == num then
				table.insert(list,cards)
			end
		end
		if #list > 0 then
			local card = list[math.random(1,#list)]
			room:obtainCard(source,card,true)
		end
	end,
}
nosmobilejvezhi = sgs.CreateViewAsSkill{
	name = "nosmobilejvezhi",
	n = 999,
	view_filter = function(self,selected,to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self,cards)
		if #cards <= 1 then return nil end
		local skillcard = mobilejvezhiCard:clone()
		for _,c in ipairs(cards)do
			skillcard:addSubcard(c)
		end
		return skillcard
	end,
	enabled_at_play = function(self,player)
		return player:getCardCount() >= 2
	end,
}
nos_mobile_peixiu:addSkill(nosxingtu)
nos_mobile_peixiu:addSkill(nosmobilejvezhi)
sgs.LoadTranslationTable{
	["nos_mobile_peixiu"] = "裴秀[旧]",
	["&nos_mobile_peixiu"] = "裴秀",
	["#nos_mobile_peixiu"] = "晋图开秘",
	["cv:nos_mobile_peixiu"] = "官方",
	["designer:nos_mobile_peixiu"] = "官方",
	["illustrator:nos_mobile_peixiu"] = "官方",
	["nosxingtu"] = "行图",
	[":nosxingtu"] = "锁定技，你使用牌结算后记录此牌点数。你使用牌时，若此牌点数为记录点数的约数，你摸一张牌；若你有已记录的点数，你使用点数为记录点数的倍数的牌无次数限制。",
	["$nosxingtu1"] = "图设分率，则宇内地域皆可绘于一尺。",
	["$nosxingtu2"] = "制图之体有六，缺一不可言精。",
	["nosmobilejvezhi"] = "爵制",
	[":nosmobilejvezhi"] = "出牌阶段，你可以弃置至少2张牌，然后从牌堆随机获得一张点数为你弃置牌点数之和的牌（若点数和大于K，则视为K）。",
	["$nosmobilejvezhi1"] = "表为建爵五等，实则藩卫帝室。",
	["$nosmobilejvezhi2"] = "复设五等之制，以解天下土崩之势。",
	["~nos_mobile_peixiu"] = "既食寒食散，便不可饮冷酒啊...",
}

mobile_pengyang = sgs.General(mobile_sp,"mobile_pengyang","shu",3)
local function gainmobiledaming(player,n)
	n = n or 1
	if n==0 then return end
	local room = player:getRoom()
	local log = sgs.LogMessage()
	log.type = "#gainmobiledaming"
	log.from = player
	log.arg = "mobiledaming"
	log.arg2 = n
	if n>0 then log.arg3 = "gain"
	else
		log.arg2 = -n
		log.arg3 = "lose"
	end
	room:sendLog(log)
	n = player:property("mobiledamingNum"):toInt()+n
	room:setPlayerProperty(player,"mobiledamingNum",ToData(n))
	for _,m in sgs.list(player:getMarkNames())do
		if m:startsWith("&mobiledamingNum+")
		then room:setPlayerMark(player,m,0) end
	end
	room:setPlayerMark(player,"&mobiledamingNum+"..n,1)
end
mobiledamingCard = sgs.CreateSkillCard{
	name = "mobiledamingCard",
	will_throw = false,
	mute = true,
	filter = function(self,targets,to_select,from)
		return #targets<1 and to_select:hasSkill("mobiledaming")
		and from:getMark(to_select:objectName().."mobiledamingUse-PlayClear")<1
	end,
	on_use = function(self,room,source,targets)
		source:peiyin("mobiledaming",math.random(1,2))
		for _,p in sgs.list(targets)do
			room:addPlayerMark(source,p:objectName().."mobiledamingUse-PlayClear")
			room:giveCard(source,p,self,"mobiledaming")
			local tos = room:getOtherPlayers(p)
			tos:removeOne(source)
			if source:isDead() or p:isDead() then break end
			local to = room:askForPlayerChosen(p,tos,"mobiledaming","mobiledaming0")
			if to then
				local has = false
				local ac = sgs.Sanguosha:getCard(self:getEffectiveId())
				for _,c in sgs.list(to:getCards("he"))do
					if c:getType()==ac:getType()
					then has = true break end
				end
				room:doAnimate(1,p:objectName(),to:objectName())
				if has then
					has = "mobiledaming1:"..ac:getType()..":"..source:objectName()
					ac = room:askForExchange(to,"mobiledaming",1,1,true,has,false,ac:getType())
					if ac then
						room:giveCard(to,source,ac,"mobiledaming")
						if p:isDead() then break end
						gainmobiledaming(p)
						continue
					end
				end
			end
			source:peiyin("mobiledaming",3)
			room:giveCard(p,source,self,"mobiledaming")
		end
	end
}
mobiledamingVS = sgs.CreateViewAsSkill{
	name = "mobiledamingvs&",
	n = 1,
	view_filter = function(self,selected,to_select)
		return true
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local new_card = mobiledamingCard:clone()
		new_card:setUserString(pattern)
		new_card:addSubcard(cards[1])
		return new_card
	end,
	enabled_at_play = function(self,player)
		for _,p in sgs.list(player:getAliveSiblings())do
			if p:hasSkill("mobiledaming")
			and player:getMark(p:objectName().."mobiledamingUse-PlayClear")<1
			then return true end
		end
		return false
	end,
}
mobile_sp:addSkills(mobiledamingVS)
mobiledaming = sgs.CreateTriggerSkill{
	name = "mobiledaming",
	--view_as_skill = mobiledamingVS;
	events = {sgs.GameStart,sgs.EventPhaseProceeding,sgs.EventPhaseEnd,sgs.EventAcquireSkill},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.GameStart then
			if player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				gainmobiledaming(player)
			end
		elseif event == sgs.EventPhaseProceeding and player:getPhase()==sgs.Player_Play then
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:hasSkill(self,true) then
					room:attachSkillToPlayer(player,"mobiledamingvs")
					break
				end
			end
		elseif event == sgs.EventPhaseEnd and player:getPhase()==sgs.Player_Play then
			room:detachSkillFromPlayer(player,"mobiledamingvs",true)
		elseif event == sgs.EventAcquireSkill and data:toString()==self:objectName() then
			for _,p in sgs.list(room:getOtherPlayers(player))do
				if p:getPhase()==sgs.Player_Play then
					room:attachSkillToPlayer(p,"mobiledamingvs")
				end
			end
		end
	end
}
mobile_pengyang:addSkill(mobiledaming)
mobilexiaonivs = sgs.CreateViewAsSkill{
	name = "mobilexiaoni",
	n = 1,
	view_filter = function(self,selected,to_select)
		return true
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local dc = sgs.Self:getTag("mobilexiaoni"):toCard()
		if dc==nil then return end
		local new_card = sgs.Sanguosha:cloneCard(dc:objectName())
		new_card:setSkillName("mobilexiaoni")
		new_card:setFlags("mobilexiaoni")
		new_card:addSubcard(cards[1])
		return new_card
	end,
	enabled_at_play = function(self,player)
		if player:property("mobiledamingNum"):toInt()<1
		or player:getMark("mobilexiaoniUse-PlayClear")>0
		then return false end
		for _,pn in sgs.list(patterns())do
			local dc = dummyCard(pn)
			if dc and dc:isDamageCard()
			and dc:isAvailable(player)
			then return true end
		end
		return false
	end,
}
mobilexiaoni = sgs.CreateTriggerSkill{
	name = "mobilexiaoni",
	view_as_skill = mobilexiaonivs,
	guhuo_type = "lr";
	events = {sgs.CardFinished,sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),"mobilexiaoni")
			or use.card:hasFlag("mobilexiaoni") then
				gainmobiledaming(player,-use.to:length())
				room:addPlayerMark(player,"mobilexiaoniUse-PlayClear")
			end
		elseif player:getPhase()==sgs.Player_Play then
			for _,pn in sgs.list(patterns())do
				local dc = dummyCard(pn)
				if dc and dc:isDamageCard() then continue end
				room:setPlayerMark(player,"mobilexiaoni_guhuo_remove_"..pn,1)
			end
		end
	end,
}
mobile_pengyang:addSkill(mobilexiaoni)
sgs.LoadTranslationTable{
	["mobile_pengyang"] = "彭羕",
	["#mobile_pengyang"] = "难别菽麦",
	["cv:mobile_pengyang"] = "官方",
	["designer:mobile_pengyang"] = "官方",
	["illustrator:mobile_pengyang"] = "官方",
	["mobiledaming"] = "达命",
	[":mobiledaming"] = "游戏开始时，你获得1点“达命”值。其他角色的出牌阶段限一次，其可以交给你一张牌，然后你选择另一名其他角色。若后者有相同类型的牌，则后者交给前者一张相同类型的牌且你获得1点“达命”值，否则你将以此法获得的牌交给前者。",
	["mobiledamingvs"] = "达命",
	[":mobiledamingvs"] = "出牌阶段限一次，你可以交给“达命”角色一张牌，然后其选择另一名其他角色。若后者有相同类型的牌，则后者交给你一张相同类型的牌且“达命”角色获得1点“达命”值，否则“达命”角色将以此法获得的牌交给你。",
	["$mobiledaming1"] = "幸蒙士元斟酌，诣公于葭萌，达命于蜀川。",
	["$mobiledaming2"] = "论治图王，助吾主成就大业。",
	["$mobiledaming3"] = "心大志广，愧公知遇之恩。",
	["mobiledaming0"] = "达命：请选择一名其他角色",
	["mobiledaming1"] = "达命：请将一张%src交给%dest",
	["#gainmobiledaming"] = "%from %arg3 了 %arg2 点 %arg 值",
	["gain"] = "获得",
	["lose"] = "失去",
	["mobiledamingNum"] = "达命",
	["mobilexiaoni"] = "嚣逆",
	[":mobilexiaoni"] = "出牌阶段限一次，若你的“达命”值大于0，你可以将一张牌当任意一种【杀】或伤害类锦囊牌使用，然后你减少此牌目标数点“达命”值。你的手牌上限等于X（X为“达命”值，且至多为你的体力值）。",
	["$mobilexiaoni1"] = "织席贩履之辈，果无用人之能乎？",
	["$mobilexiaoni2"] = "古今天下，岂有重屠沽之流而轻贤达者乎？",
	["~mobile_pengyang"] = "招祸自咎，无不自己……",
}

mobile_yangfu = sgs.General(mobile_sp,"mobile_yangfu","wei",3)
jiebing = sgs.CreateTriggerSkill{
	name = "jiebing",
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data,room)
		local damage = data:toDamage()
		local tos = room:getOtherPlayers(player)
		if damage.from then tos:removeOne(damage.from) end
		if tos:isEmpty() then return false end
		room:sendCompulsoryTriggerLog(player,self)
		local to = room:askForPlayerChosen(player,tos,self:objectName(),"jiebing0:",false,true)
		if to and to:getCardCount()>0 then
			tos = to:getCards("he")
			local c = tos:at(math.random(0,tos:length()-1))
			room:obtainCard(player,c,false)
			room:showCard(player,c:getEffectiveId())
			if player:handCards():contains(c:getEffectiveId())
			and c:isKindOf("EquipCard") and player:canUse(c,player) then
				room:useCard(sgs.CardUseStruct(c,player))
			end
		end
		return false
	end
}
mobile_yangfu:addSkill(jiebing)
hannanCard = sgs.CreateSkillCard{
	name = "hannanCard",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		return #targets<1 and to_select~=from
		and from:canPindian(to_select)
	end,
	on_use = function(self,room,source,targets)
		for _,p in sgs.list(targets)do
			local n = source:pindianInt(p,self:getSkillName())
			if n==0 then continue end
			local to,from = p,source
			if n<0 then
				to = source
				from = p
			end
			room:damage(sgs.DamageStruct(self:getSkillName(),from,to))
		end
	end
}
hannan = sgs.CreateViewAsSkill{
	name = "hannan",
	view_as = function(self,cards)
		return hannanCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#hannanCard")<1
	end,
}
mobile_yangfu:addSkill(hannan)
sgs.LoadTranslationTable{
	["mobile_yangfu"] = "杨阜",
	["#mobile_yangfu"] = "勇撼雄狮",
	["cv:mobile_yangfu"] = "官方",
	["designer:mobile_yangfu"] = "官方",
	["illustrator:mobile_yangfu"] = "官方",
	["jiebing"] = "借兵",
	[":jiebing"] = "锁定技，当你受到伤害后，你选择一名其他角色（伤害来源除外），随机获得其一张牌并展示之。若其中有装备牌，你使用之。",
	["$jiebing1"] = "敌寇势大，情况危急，只能多谢阁下。",
	["$jiebing2"] = "将军借兵之恩，阜退敌后自当报还。",
	["jiebing0"] = "借兵：请选择一名其他角色",
	["hannan"] = "扞难",
	[":hannan"] = "出牌阶段限一次，你可以拼点；赢的角色对没赢的角色造成1点伤害。",
	["$hannan1"] = "贼寇虽勇，阜亦戮力以捍！",
	["$hannan2"] = "纵使信布之勇，亦非无策可当！",
	["~mobile_yangfu"] = "汝背父叛君，吾誓……杀……",
}

mobilesp_ganfuren = sgs.General(mobile_sp, "mobilesp_ganfuren", "shu", 3, false)
mobileshushen = sgs.CreateTriggerSkill{
	name = "mobileshushen",
	events = {sgs.CardsMoveOneTime, sgs.HpRecover},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() and move.card_ids:length() >= 2
			and move.to_place == sgs.Player_PlaceHand and move.to:objectName() == player:objectName()
			and player:getMark("mobileshushen_move-Clear") < 1 then
			    local players = sgs.SPlayerList()
				for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					if p:isWounded() then
						players:append(p)
					end
				end
			    local target = room:askForPlayerChosen(player, players, self:objectName(), "mobileshushen2", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					room:recover(target, sgs.RecoverStruct(self:objectName(),player))
					room:addPlayerMark(player, "mobileshushen_move-Clear")
			    end
		    end
		elseif event == sgs.HpRecover then
			local recover = data:toRecover()
			if recover.recover > 0 and player:getMark("mobileshushen_recover-Clear") < 1 then
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "mobileshushen1", true, true)
			    if target then
				    room:broadcastSkillInvoke(self:objectName())
				    target:drawCards(2, self:objectName())
				    room:addPlayerMark(player, "mobileshushen_recover-Clear")
			    end
			end
		end
	end
}
mobilezhijie = sgs.CreateTriggerSkill{
    name = "mobilezhijie",
	events = {sgs.EventPhaseEnd, sgs.EventPhaseStart, sgs.CardUsed},
	on_trigger = function(self, event, player, data)
	    local room = player:getRoom()
		for _, p in sgs.qlist(room:findPlayersBySkillName(self:objectName())) do
		    if event == sgs.EventPhaseStart then
				if player:getPhase() == sgs.Player_Play and not player:isKongcheng()
				and p:getMark("mobilezhijie_lun") < 1
				and p:askForSkillInvoke(self:objectName(), player) then
					room:broadcastSkillInvoke(self:objectName())
					local id = room:askForCardChosen(p, player, "h", self:objectName())
					local card = sgs.Sanguosha:getCard(id)
					room:showCard(player, id)
					room:setPlayerMark(player, "&mobilezhijie+"..card:getType().."-SelfPlayClear", 1)
					p:addMark("mobilezhijie_lun")
				end
		    elseif event == sgs.EventPhaseEnd then
				if player:getPhase() == sgs.Player_Play then
					if player:getMark("mobilezhijie+equip-SelfPlayClear")>player:getMark("mobilezhijie+equip_dis-SelfPlayClear")
					or player:getMark("mobilezhijie+basic-SelfPlayClear")>player:getMark("mobilezhijie+basic_dis-SelfPlayClear")
					or player:getMark("mobilezhijie+trick-SelfPlayClear")>player:getMark("mobilezhijie+trick_dis-SelfPlayClear") then
					    room:sendCompulsoryTriggerLog(p, self)
						room:drawCards(p, 1, self:objectName())
						room:drawCards(player, 1, self:objectName())
					end
				end
			else
			    local use = data:toCardUse()
				if use.from:getMark("&mobilezhijie+"..use.card:getType().."-SelfPlayClear") > 0 then
				    room:sendCompulsoryTriggerLog(p, self)
					room:drawCards(use.from, 1, self:objectName())
					local n = use.from:getMark("mobilezhijie+"..use.card:getType().."-SelfPlayClear")
					use.from:addMark("mobilezhijie+"..use.card:getType().."-SelfPlayClear")
					if n > 0 then
					    local dc = room:askForDiscard(use.from, self:objectName(), n, n, false, true)
						use.from:addMark("mobilezhijie+"..use.card:getType().."_dis-SelfPlayClear", dc:subcardsLength())
					end
				end
			end
		end
	end,
	can_trigger = function(self, player)
	    return player and player:isAlive()
	end,
}
mobilesp_ganfuren:addSkill(mobilezhijie)
mobilesp_ganfuren:addSkill(mobileshushen)
sgs.LoadTranslationTable{ 
	["mobilesp_ganfuren"] = "甘夫人[手杀SP]",
	["#mobilesp_ganfuren"] = "昭烈皇后",
	["illustrator:ganfuren"] = "官方",
	["mobilezhijie"] = "智诫",
	[":mobilezhijie"] = "每轮限一次，一名角色的出牌阶段开始时，你可以展示其一张手牌。本阶段其使用与此牌类别相同的牌后，其摸一张牌并弃置X张牌（X为本回合其使用此类型牌的次数-1）；此阶段结束时，若其此阶段因此法获得的牌数大于弃置的牌数则你与其各摸一张牌。",
	["mobileshushen"] = "淑慎",
	[":mobileshushen"] = "每回合各限一次，当你回复体力时，你可以令一名其他角色摸两张牌；当你获得两张或更多牌时，你可以令一名其他角色回复1点体力。",
	["mobileshushen1"] = "你可以发动“淑慎”选择令一名其他角色摸两张牌",
	["mobileshushen2"] = "你可以发动“淑慎”选择令一名其他角色回复1点体力",
	["$mobilezhijie1"] = "昔子罕不以玉为宝，《春秋》美之。",
	["$mobilezhijie2"] = "今吴、魏未灭，安以妖玩继怀？",
	["$mobileshushen1"] = "此者国亡之象，夫君岂不知乎？",
	["$mobileshushen2"] = "为人妻者，当为夫计。",
}



sgs.Sanguosha:setPackage(mobile_sp)

local OLStThicket = sgs.Sanguosha:getPackage("OLStThicket")

--OL界贾诩
ol_jiaxu = sgs.General(OLStThicket,"ol_jiaxu","qun",3)

olwansha = sgs.CreateTriggerSkill{
name = "olwansha",
events = {sgs.EnterDying,sgs.QuitDying},
frequency = sgs.Skill_Compulsory,
can_trigger = function(self,target)
	return target~=nil
end,
on_trigger = function(self,event,player,data,room)
	local dying = data:toDying()
	if event == sgs.EnterDying then
		local current = room:getCurrent()
		if current and current:hasFlag("CurrentPlayer") and current:hasSkill(self) then
			for _,p in sgs.qlist(room:getOtherPlayers(dying.who))do
				if p == current then continue end
				p:addMark("olwanshaBf")
				room:addPlayerMark(p,"@skill_invalidity")
				room:filterCards(p,p:getCards("he"),true)
				local jsonValue={9}
				room:doBroadcastNotify(sgs.CommandType.S_COMMAND_LOG_EVENT,json.encode(jsonValue))
			end
			if current:hasSkill("jilve",true) then
				current:peiyin("jilve",3)
			else
				current:peiyin(self)
			end
			local log = sgs.LogMessage()
			log.from = current
			log.arg = self:objectName()
			log.type = "#WanshaTwo"
			log.to:append(dying.who)
			if current == dying.who then
				log.type = "#WanshaOne"
			end
			room:sendLog(log)
			room:notifySkillInvoked(current,self:objectName())
		end
	else
		for _,p in sgs.qlist(room:getOtherPlayers(dying.who))do
			local n = p:getMark("olwanshaBf")
			if n<1 then continue end
			p:setMark("olwanshaBf",0)
			room:removePlayerMark(p,"@skill_invalidity",n)
			room:filterCards(p,p:getCards("he"),true)
		end
	end
	return false
end
}

olwanshabf = sgs.CreateCardLimitSkill{
	name = "#olwanshabf",
	limit_list = function(self,player)
		return "use"
	end,
	limit_pattern = function(self,player)
		if player:hasFlag("Global_Dying") then return "" end
		for _,p in sgs.qlist(player:getAliveSiblings())do
			if p:hasFlag("CurrentPlayer") and p:hasSkill("olwansha")
			then return "Peach" end
		end
		return ""
	end
}

olwanshaInvalidity = sgs.CreateInvaliditySkill{  --成功运行过两次，再后来就会崩了。。
name = "#olwanshaInvalidity",
skill_valid = function(self,player,skill)
	if player:hasFlag("Global_Dying") or skill:isAttachedLordSkill() then return true end
	for _,p in sgs.qlist(player:getAliveSiblings())do
		if p:hasFlag("CurrentPlayer") and p:hasSkill("olwansha") then
			local f = skill:getFrequency(player)
			return f == sgs.Skill_Compulsory or f == sgs.Skill_Wake
		end
	end
	return true--[[
	if player:hasSkill("olwansha",true) or player:hasFlag("Global_Dying") then return true end  --hasSkill设置为true，不然会栈溢出，当然这是不应该的
	local al = player:getAliveSiblings()
	al:append(player)
	local wansha = false
	for _,p in sgs.qlist(al)do
		if p:getPhase() ~= sgs.Player_NotActive and p:hasSkill("olwansha",true) then
			wansha = true
			break
		end
	end
	if not wansha then return true end
	for _,p in sgs.qlist(al)do
		if not p:hasFlag("Global_Dying") then continue end
		return skill:getFrequency(player) == sgs.Skill_Compulsory or skill:getFrequency(player) == sgs.Skill_Wake or skill:isAttachedLordSkill()
	end
	return true]]
end
}

olluanwuCard = sgs.CreateSkillCard{
name = "olluanwu",
target_fixed = true,
on_use = function(self,room,source)
	room:removePlayerMark(source,"@olluanwuMark")
	room:doSuperLightbox(source,"olluanwu")
	for _,p in sgs.qlist(room:getOtherPlayers(source))do
		if p:isDead() then continue end
		room:cardEffect(self,source,p)
        room:getThread():delay()
	end
	if source:isAlive() then
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("_olluanwu")
		slash:deleteLater()
		for _,p in sgs.qlist(room:getAlivePlayers())do
			if source:canSlash(p,slash,false) then
				room:askForUseCard(source,"@@olluanwu","@olluanwu")
				break
			end
		end
	end
end,
on_effect = function(self,effect)
	local from,to = effect.from,effect.to
	local room = from:getRoom()
	
	local distance_list,players = sgs.IntList(),room:getOtherPlayers(to)
	local nearest = to:distanceTo(players:first())
	for _,p in sgs.qlist(players)do
		local distance = to:distanceTo(p)
		distance_list:append(distance)
		nearest = math.min(nearest,distance)
	end
	
	local luanwu_targets = sgs.SPlayerList()
	for i = 0,distance_list:length() - 1 do
		if distance_list:at(i) == nearest and to:canSlash(players:at(i),nil,false) then
			luanwu_targets:append(players:at(i))
		end
	end
	
	if luanwu_targets:isEmpty() or not room:askForUseSlashTo(to,luanwu_targets,"@luanwu-slash") then
		room:loseHp(sgs.HpLostStruct(to,1,"olluanwu",from))
	end
end
}

olluanwu = sgs.CreateZeroCardViewAsSkill{
name = "olluanwu",
frequency = sgs.Skill_Limited,
limit_mark = "@olluanwuMark",
response_pattern = "@@olluanwu",
view_as = function(self,card)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		return olluanwuCard:clone()
	else
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("_olluanwu")
		return slash
	end
end,
enabled_at_play = function(self,player)
	return player:getMark("@olluanwuMark") > 0
end
}

olweimu = sgs.CreateProhibitSkill{
name = "olweimu",
is_prohibited = function(self,from,to,card)
	return card:isKindOf("TrickCard") and card:isBlack() and to:hasSkill(self)
end
}

olweimuDamage = sgs.CreateTriggerSkill{
name = "#olweimuDamage",
events = sgs.DamageInflicted,
frequency = sgs.Skill_Compulsory,
on_trigger = function(self,event,player,data,room)
	if not player:hasFlag("CurrentPlayer") or not player:hasSkill("olweimu") then return false end
	local damage = data:toDamage()
	local log = sgs.LogMessage()
	log.type = "#OLWeimuPreventDamage"
	log.from = player
	log.arg = "olweimu"
	log.arg2 = damage.damage
	room:sendLog(log)
	player:peiyin("olweimu")
	room:notifySkillInvoked(player,"olweimu")
	player:drawCards(2 * damage.damage,"olweimu")
	return true
end
}

ol_jiaxu:addSkill(olwansha)
ol_jiaxu:addSkill(olwanshabf)
--ol_jiaxu:addSkill(olwanshaInvalidity)
ol_jiaxu:addSkill(olluanwu)
ol_jiaxu:addSkill(olweimu)
ol_jiaxu:addSkill(olweimuDamage)
OLStThicket:insertRelatedSkills("olwansha","#olwanshabf")
--OLStThicket:insertRelatedSkills("olwansha","#olwanshaInvalidity")
OLStThicket:insertRelatedSkills("olweimu","#olweimuDamage")

--OL界鲁肃
ol_lusu = sgs.General(OLStThicket,"ol_lusu","wu",3)

olhaoshiCard = sgs.CreateSkillCard{
name = "olhaoshi",
will_throw = false,
handling_method = sgs.Card_MethodNone,
filter = function(self,targets,to_select,player)
	return #targets == 0 and to_select:objectName() ~= player:objectName() and to_select:getHandcardNum() == player:getMark("olhaoshi")
end,
on_effect = function(self,effect)
	local room = effect.from:getRoom()
	room:addPlayerMark(effect.to,"&olhaoshi+#"..effect.from:objectName())
	room:giveCard(effect.from,effect.to,self,"olhaoshi")
end
}

olhaoshiVS = sgs.CreateViewAsSkill{
name = "olhaoshi",
n = 9999,
response_pattern = "@@olhaoshi!",
view_filter = function(self,selected,to_select)
	return not to_select:isEquipped() and #selected < math.floor(sgs.Self:getHandcardNum() / 2)
end,
view_as = function(self,cards)
	if #cards ~= math.floor(sgs.Self:getHandcardNum() / 2) then return nil end
	local c = olhaoshiCard:clone()
	for i = 1,#cards,1 do
		c:addSubcard(cards[i])
	end
	return c
end
}

olhaoshi = sgs.CreateTriggerSkill{
name = "olhaoshi",
events = {sgs.DrawNCards,sgs.AfterDrawNCards,sgs.EventPhaseStart},
view_as_skill = olhaoshiVS,
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	if event == sgs.DrawNCards then
		local draw = data:toDraw()
		if draw.reason~="draw_phase" or not player:hasSkill(self)
		or not player:askForSkillInvoke(self) then return end
		player:peiyin(self)
		player:setFlags("olhaoshi")
		draw.num = draw.num+2
		data:setValue(draw)
	elseif event == sgs.AfterDrawNCards then
		local draw = data:toDraw()
		if draw.reason~="draw_phase" or not player:hasFlag("olhaoshi") then return end
		player:setFlags("-olhaoshi")
		if player:getHandcardNum() <= 5 then return false end
		local least = room:getOtherPlayers(player):first():getHandcardNum()
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			least = math.min(least,p:getHandcardNum())
		end
		room:setPlayerMark(player,"olhaoshi",least)
		
		local used = room:askForUseCard(player,"@@olhaoshi!","@haoshi",-1,sgs.Card_MethodNone)
		if used then return false end
		
		local beggar
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if p:getHandcardNum() == least then
				beggar = p
				break
			end
		end
		if not beggar then return false end
		room:addPlayerMark(beggar,"&olhaoshi+#"..player:objectName())
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local hands = player:handCards()
		for i = 0,math.floor(player:getHandcardNum() / 2) - 1 do
			slash:addSubcard(hands:at(i))
		end
		if slash:subcardsLength() > 0 then
			room:giveCard(player,beggar,slash,"olhaoshi")
		end
	elseif event == sgs.EventPhaseStart then
		if player:getPhase() ~= sgs.Player_RoundStart then return false end
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			room:setPlayerMark(p,"&olhaoshi+#"..player:objectName(),0)
		end
	end
	return false
end
}

olhaoshiEffect = sgs.CreateTriggerSkill{
name = "#olhaoshiEffect",
events = sgs.TargetConfirmed,
on_trigger = function(self,event,player,data,room)
	local use = data:toCardUse()
	if not use.to:contains(player) then return false end
	if not use.card:isKindOf("Slash") and not use.card:isNDTrick() then return false end
	for _,p in sgs.qlist(room:getOtherPlayers(player))do
		if player:isDead() then return false end
		if p:isDead() or p:getMark("&olhaoshi+#"..player:objectName()) <= 0 or p:isKongcheng() then continue end
		local card = room:askForCard(p,".|.|.|hand","@olhaoshi-give:"..player:objectName(),data,sgs.Card_MethodNone)
		if not card then continue end
		room:giveCard(p,player,card,"olhaoshi")
	end
	return false
end
}

oldimengCard = sgs.CreateSkillCard{
name = "oldimeng",
filter = function(self,targets,to_select,player)
	if to_select:objectName() == player:objectName() then return false end
	if #targets == 0 then return true end
	if #targets == 1 then
		return math.abs(to_select:getHandcardNum() - targets[1]:getHandcardNum()) <= player:getCardCount()
	end
	return false
end,
feasible = function(self,targets,player)
	return #targets == 2
end,
on_use = function(self,room,source,targets)
	local a = targets[1]
    local b = targets[2]
	if a:isDead() or b:isDead() then return end
	room:addPlayerMark(a,"oldimeng_target_"..b:objectName().."-PlayClear")
    a:setFlags("OLDimengTarget")
    b:setFlags("OLDimengTarget")
	
	--local oldimeng_func = function(a,b)
		local log = sgs.LogMessage()
		log.type = "#Dimeng"
		log.from = a
		log.to:append(b)
		log.arg = a:getHandcardNum()
		log.arg2 = b:getHandcardNum()
		local exchangeMove = sgs.CardsMoveList()
		local move1 = sgs.CardsMoveStruct(a:handCards(),b,sgs.Player_PlaceHand,
			sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,a:objectName(),b:objectName(),"oldimeng",""))
		local move2 = sgs.CardsMoveStruct(b:handCards(),a,sgs.Player_PlaceHand,
            sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,b:objectName(),a:objectName(),"oldimeng",""))
		exchangeMove:append(move1)
		exchangeMove:append(move2)
		room:moveCardsAtomic(exchangeMove,false)
		room:sendLog(log)
	--[[end
	
	if not pcall(oldimeng_func(a,b)) then
		a:setFlags("-OLDimengTarget")
		b:setFlags("-OLDimengTarget")
	end]]
	
	a:setFlags("-OLDimengTarget")
    b:setFlags("-OLDimengTarget")
end
}

oldimengVS = sgs.CreateZeroCardViewAsSkill{
name = "oldimeng",
view_as = function(self,card)
	return oldimengCard:clone()
end,
enabled_at_play = function(self,player)
	return not player:hasUsed("#oldimeng")
end
}

oldimeng = sgs.CreateTriggerSkill{
name = "oldimeng",
events = sgs.EventPhaseEnd,
view_as_skill = oldimengVS,
can_trigger = function(self,player)
	return player and player:isAlive() and player:canDiscard(player,"he")
end,
on_trigger = function(self,event,player,data,room)
	if player:getPhase() ~= sgs.Player_Play then return false end
	local send = true
	for _,p in sgs.qlist(room:getAllPlayers())do
		if player:isDead() or not player:canDiscard(player,"he") then return false end
		for _,q in sgs.qlist(room:getAllPlayers())do
			if player:isDead() or not player:canDiscard(player,"he") then return false end
			local mark = p:getMark("oldimeng_target_"..q:objectName().."-PlayClear")
			for i = 1,mark do
				if player:isDead() or not player:canDiscard(player,"he") then return false end
				local phand,qhand = p:getHandcardNum(),q:getHandcardNum()
				local num = math.abs(phand - qhand)
				if num == 0 then break end
				if send then
					send = false
					sendZhenguLog(player,self:objectName())
				end
				room:askForDiscard(player,self:objectName(),num,num,false,true)
			end
		end
	end
	return false
end
}

ol_lusu:addSkill(olhaoshi)
ol_lusu:addSkill(olhaoshiEffect)
ol_lusu:addSkill(oldimeng)
OLStThicket:insertRelatedSkills("olhaoshi","#olhaoshiEffect")

sgs.Sanguosha:setPackage(OLStThicket)

local OLStFire = sgs.Sanguosha:getPackage("OLStFire")

keol_yanliangwenchou = sgs.General(OLStFire,"keol_yanliangwenchou","qun",4)
keolshuangxiongVS = sgs.CreateOneCardViewAsSkill{
	name = "keolshuangxiong",
	view_filter = function(self,to_select)
		return sgs.Self:getMark("&keolshuangxiong+"..to_select:getColorString().."-Clear")<1
	end,
	view_as = function(self,card)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:setSkillName(self:objectName())
		duel:addSubcard(card)
		return duel
	end,
	enabled_at_play = function(self,player)
		return player:getMark("ViewAsSkill_keolshuangxiongEffect")>0
	end
}
keolshuangxiong = sgs.CreateTriggerSkill{
	name = "keolshuangxiong",
	view_as_skill = keolshuangxiongVS,
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd,sgs.EventPhaseStart,sgs.Damaged},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.to:hasFlag("CurrentPlayer") then
				local tag = player:getTag("keolshuangxiongToGet"):toIntList()
				if damage.card:isVirtualCard() then
					for _,id in sgs.qlist(damage.card:getSubcards())do
						tag:append(id)
					end
				else
					tag:append(damage.card:getId())
				end
				local data = sgs.QVariant()
				data:setValue(tag)
				player:setTag("keolshuangxiongToGet",data)
			end
		elseif event == sgs.EventPhaseEnd
		and player:getPhase() == sgs.Player_Draw
		and player:hasSkill(self) then
			local xxx = room:askForDiscard(player,self:objectName(),1,1,true,true,"keolshuangxiongdis")
			if xxx then
				room:setPlayerMark(player,"&keolshuangxiong+"..xxx:getColorString().."-Clear",1)
				room:addPlayerMark(player,"ViewAsSkill_keolshuangxiongEffect")
			end
		elseif event == sgs.EventPhaseStart
		and player:getPhase() == sgs.Player_Finish then
			local cards = sgs.IntList()
			for _,id in sgs.qlist(player:getTag("keolshuangxiongToGet"):toIntList())do
				if room:getCardPlace(id) == sgs.Player_DiscardPile
				then cards:append(id) end
			end
			player:removeTag("keolshuangxiongToGet")
			if cards:length() > 0 and player:hasSkill(self) then
				room:broadcastSkillInvoke(self:objectName())
				local move = sgs.CardsMoveStruct()
				move.card_ids = cards
				move.to = player
				move.to_place = sgs.Player_PlaceHand
				room:moveCardsAtomic(move,true)
			end
			room:setPlayerMark(player,"ViewAsSkill_keolshuangxiongEffect",0)
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end
}
keol_yanliangwenchou:addSkill(keolshuangxiong)
sgs.LoadTranslationTable {
	["keol_yanliangwenchou"] = "界颜良文丑[OL]",
	["&keol_yanliangwenchou"] = "界颜良文丑",
	["#keol_yanliangwenchou"] = "虎狼兄弟",
	["designer:keol_yanliangwenchou"] = "官方",
	["cv:keol_yanliangwenchou"] = "官方",
	["illustrator:keol_yanliangwenchou"] = "官方",

	["keolshuangxiong"] = "双雄",
	[":keolshuangxiong"] = "摸牌阶段结束时，你可以弃置一张牌，然后你本回合可以将一张与之颜色不同的牌当【决斗】使用；结束阶段，你获得你回合内对你造成过伤害的牌。",

	["keolshuangxiongdis"] = "你可以发动“双雄”弃置一张牌",
	["keolshuangxiongred"] = "双雄弃红",
	["keolshuangxiongblack"] = "双雄弃黑",

	["$keolshuangxiong2"] = "兄弟协力，定可于乱世纵横。",
	["$keolshuangxiong1"] = "吾执矛，君执槊，此天下可有挡我者。",

	["~keol_yanliangwenchou"] = "双雄皆陨，徒隆武圣之名……",
}

sgs.Sanguosha:setPackage(OLStFire)

local OLStStandard = sgs.Sanguosha:getPackage("OLStStandard")

keoljie_lvmeng = sgs.General(OLStStandard,"keoljie_lvmeng","wu",4)
keolkeji = sgs.CreateTriggerSkill{
	name = "keolkeji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.PreCardUsed,sgs.CardResponded,sgs.EventPhaseChanging},  
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.EventPhaseChanging) then
			local can_trigger = true
			if player:hasFlag("keolkejiSlashInPlayPhase") then
				can_trigger = false
				player:setFlags("-keolkejiSlashInPlayPhase")
			end
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Discard and player:isAlive() and player:hasSkill(self:objectName()) then
				if can_trigger and player:askForSkillInvoke(self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					player:skip(sgs.Player_Discard)
				end
			end
		else
			if player:getPhase() == sgs.Player_Play then
				local card = nil
				if event == sgs.PreCardUsed then
					card = data:toCardUse().card
				else
					card = data:toCardResponse().m_card			 
				end
				if card:isKindOf("Slash") then
					player:setFlags("keolkejiSlashInPlayPhase")
				end
			end
		end
	end,
	--[[can_trigger = function(self,target)
		return target ~= nil
	end]]
}
keoljie_lvmeng:addSkill("keji")
keolqinxue = sgs.CreateTriggerSkill {
	name = "keolqinxue",
	frequency = sgs.Skill_Wake,
	waked_skills = "gongxin",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		if player:getMark(self:objectName())>0 then return end
		if (player:getPhase() == sgs.Player_Start or player:getPhase() == sgs.Player_Finish)
		and (player:getHandcardNum()-player:getHp()>=2 or player:canWake(self:objectName())) then
			local room = player:getRoom()
			room:sendCompulsoryTriggerLog(player,self)
			room:doSuperLightbox(player,self:objectName())
			room:addPlayerMark(player,self:objectName())
			if room:changeMaxHpForAwakenSkill(player,-1,self:objectName()) then
				if player:isWounded() and room:askForChoice(player,self:objectName(),"keolqinxue1+keolqinxue2")=="keolqinxue1"
				then room:recover(player,sgs.RecoverStruct(self:objectName(),player))
				else player:drawCards(2,self:objectName()) end
				room:acquireSkill(player,"gongxin")
			end
		end
	end
}
keoljie_lvmeng:addSkill(keolqinxue)
keolgongxinCard = sgs.CreateSkillCard{
	name = "keolgongxinCard",
	filter = function(self,targets,to_select,player)
		return #targets == 0 and to_select~=player and not to_select:isKongcheng() 
	end,
	on_effect = function(self,effect)
		local room = effect.from:getRoom()
		local ids = sgs.IntList()
		for _,card in sgs.qlist(effect.to:getHandcards())do
			if card:getSuit() == sgs.Card_Heart then
				ids:append(card:getEffectiveId())
			end
		end
		local card_id = room:doGongxin(effect.from,effect.to,ids)
		if (card_id == -1) then return end
		local result = room:askForChoice(effect.from,"keolgongxin","discard+put")
		effect.from:removeTag("keolgongxin")
		if result == "discard" then
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_DISMANTLE,effect.from:objectName(),nil,"keolgongxin",nil)
			room:throwCard(sgs.Sanguosha:getCard(card_id),reason,effect.to,effect.from)
		else
			effect.from:setFlags("Global_GongxinOperator")
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,effect.from:objectName(),nil,"keolgongxin",nil)
			room:moveCardTo(sgs.Sanguosha:getCard(card_id),effect.to,nil,sgs.Player_DrawPile,reason,true)
			effect.from:setFlags("-Global_GongxinOperator")
		end
	end
}	
keolgongxin = sgs.CreateZeroCardViewAsSkill{
	name = "keolgongxin",
	view_as = function()
		return keolgongxinCard:clone()
	end,
	enabled_at_play = function(self,target)
		return not target:hasUsed("#keolgongxinCard")
	end
}

keolbotu = sgs.CreateTriggerSkill{
	name = "keolbotu",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardsMoveOneTime) then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_DiscardPile
			and player:hasSkill(self:objectName(),true)
			and player:hasFlag("CurrentPlayer") then
				for _,id in sgs.qlist(move.card_ids)do
					local str = sgs.Sanguosha:getCard(id):getSuitString().."_char"
					if player:getMark(str.."keolbotu-Clear")<1 then
						player:addMark(str.."keolbotu-Clear")
						MarkRevises(player,"&keolbotu",str)
					end
				end
			end
		elseif event == sgs.EventPhaseStart and player:getPhase()==sgs.Player_NotActive then
			local num = 0
			for _,m in sgs.list(player:getMarkNames())do
				if m:startsWith("&keolbotu+") and player:getMark(m)>0 then
					num = #m:split("+")-1
					room:setPlayerMark(player,m,0)
				end
			end
			if num >= 4 and player:hasSkill(self)
			and player:getMark("keolbotuuse_lun") < math.min(room:getAlivePlayers():length(),3)
			and room:askForSkillInvoke(player,self:objectName(),data) then
				room:broadcastSkillInvoke(self:objectName())
				player:addMark("keolbotuuse_lun")
			    player:gainAnExtraTurn()
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
keoljie_lvmeng:addSkill(keolbotu)

sgs.LoadTranslationTable {
	["keoljie_lvmeng"] = "界吕蒙[OL二版]",
	["&keoljie_lvmeng"] = "界吕蒙",
	["#keoljie_lvmeng"] = "士别三日",
	["designer:keoljie_lvmeng"] = "官方",
	["cv:keoljie_lvmeng"] = "官方",
	["illustrator:keoljie_lvmeng"] = "官方",

	["keolkeji"] = "克己",
	[":keolkeji"] = "若你没有于出牌阶段内使用或打出过【杀】，你可以跳过此回合的弃牌阶段。",

	["keolqinxue"] = "勤学",
	[":keolqinxue"] = "觉醒技，准备阶段或结束阶段，若你的手牌数比体力值多2或更多，你减1点体力上限，回复1点体力或摸两张牌，然后获得技能“攻心”。",
	["keolqinxue1"] = "回复1点体力",
	["keolqinxue2"] = "摸两张牌",

	["keolgongxin"] = "攻心",
	[":keolgongxin"] = "出牌阶段限一次，你可以观看一名其他角色的手牌，然后你可以展示其中的一张红桃牌并选择一项：1.弃置此牌；2.将此牌置于牌堆顶。",
	
	["keolbotu"] = "博图",
	[":keolbotu"] = "每轮限X次（X为场上角色数且至多为3），回合结束后，若本回合置入弃牌堆的牌包含四种花色，则你可以获得一个额外回合。",

	["$keolkeji1"] = "蓄力待时，不争首功。",
	["$keolkeji2"] = "最好的机会，还在等着我。",
	["$keolqinxue1"] = "兵书熟读，了然于胸。",
	["$keolqinxue2"] = "勤以修身，学以报国。",
	["$keolgongxin1"] = "洞若观火，运筹帷幄。",
	["$keolgongxin2"] = "哼，早知如此。",
	["$keolbotu1"] = "时机已到，全军出击！",
	["$keolbotu2"] = "今日起兵，渡江攻敌！",

	["~keoljie_lvmeng"] = "你，给我等着！",
}

keoljie_huaxiong = sgs.General(OLStStandard,"keoljie_huaxiong","qun",6)
keolyaowu = sgs.CreateTriggerSkill{
	name = "keolyaowu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card then
				room:sendCompulsoryTriggerLog(player,self)
				if damage.card:isRed() then
				    if damage.from and damage.from:isAlive() then
						damage.from:drawCards(1,self:objectName())
					end
			    else
				    player:drawCards(1,self:objectName())
				end
			end
		end
	end,
}
keoljie_huaxiong:addSkill(keolyaowu)
keolshizhanCard = sgs.CreateSkillCard{
	name = "keolshizhanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,player)
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:setSkillName("_keolshizhan")
		duel:deleteLater()
		return #targets < 1 and to_select ~= player
		and duel:targetFilter(sgs.PlayerList(),player,to_select)
	end,
	on_use = function(self,room,player,targets)
		for _,p in sgs.list(targets)do
			local duel = sgs.Sanguosha:cloneCard("duel")
			duel:setSkillName("_keolshizhan")
			room:useCard(sgs.CardUseStruct(duel,p,player))
			duel:deleteLater()
		end
	end
}
keolshizhan = sgs.CreateViewAsSkill{
	name = "keolshizhan",
	n = 0,
	view_as = function(self,cards)
		return keolshizhanCard:clone()
	end,
	enabled_at_play = function(self,player)
		return (player:usedTimes("#keolshizhanCard") < 2)
	end,
}
keoljie_huaxiong:addSkill(keolshizhan)
sgs.LoadTranslationTable {
	["keoljie_huaxiong"] = "界华雄[OL二版]",
	["&keoljie_huaxiong"] = "界华雄",
	["#keoljie_huaxiong"] = "飞扬跋扈",
	["designer:keoljie_huaxiong"] = "官方",
	["cv:keoljie_huaxiong"] = "官方",
	["illustrator:keoljie_huaxiong"] = "官方",

	["keolyaowu"] = "耀武",
	[":keolyaowu"] = "锁定技，当你受到伤害后，若对你造成伤害的牌：为红色，伤害来源摸一张牌；不为红色，你摸一张牌。",

	["keolshizhan"] = "势斩",
	[":keolshizhan"] = "出牌阶段限两次，你可以令一名其他角色视为对你使用一张【决斗】。",

	["$keolyaowu1"] = "这些杂兵，我有何惧！",
	["$keolyaowu2"] = "有吾在此，解太师烦忧。",
	["$keolshizhan1"] = "看你能坚持几个回合！",
	["$keolshizhan2"] = "兀那汉子，且报上名来！",

	["~keoljie_huaxiong"] = "我掉以轻心了……",
}

sgs.Sanguosha:setPackage(OLStStandard)


local yue = sgs.Sanguosha:getPackage("yue")

--杨芷
nos_jin_yangzhi = sgs.General(yue,"nos_jin_yangzhi","jin",3,false)
--nos_jin_yangzhi:setImage("jin_yangzhi")

nosjinwanyiCard = sgs.CreateSkillCard {
name = "nosjinwanyi",
will_throw = false,
handling_method = sgs.Card_MethodUse,
filter = function(self,targets,to_select,player)
    local card = player:getTag("nosjinwanyi"):toCard()
	if not card then return false end
	card:addSubcard(self)
	card:setSkillName("nosjinwanyi")
	local qtargets = sgs.PlayerList()
	for _,p in ipairs(targets)do
		qtargets:append(p)
	end
    return card:targetFilter(qtargets,to_select,player)
end,
feasible = function(self,targets,player)
	local card = player:getTag("nosjinwanyi"):toCard()
	if not card then return false end
	card:addSubcard(self)
	card:setSkillName("nosjinwanyi")
	if card:canRecast() and #targets == 0 then
		return false
	end
	local qtargets = sgs.PlayerList()
	for _,p in ipairs(targets)do
		qtargets:append(p)
	end
	return card:targetsFeasible(qtargets,player)
end,
on_validate = function(self,cardUse)
	local source = cardUse.from
	local room = source:getRoom()
	local user_string = self:getUserString()
    local use_card = sgs.Sanguosha:cloneCard(user_string,sgs.Card_SuitToBeDecided,-1)
	if not use_card then return nil end
    use_card:setSkillName("nosjinwanyi")
    use_card:deleteLater()
	use_card:addSubcard(self)
	room:addPlayerMark(source,"nosjinwanyi_juguan_remove_"..user_string.."-Clear")
    return use_card
end
}

nosjinwanyi = sgs.CreateOneCardViewAsSkill{
name = "nosjinwanyi",
juguan_type = "zhujinqiyuan,chuqibuyi,drowning,dongzhuxianji",
view_filter = function(self,to_select)
	if to_select:isEquipped() then return false end
	local ec = sgs.Sanguosha:getEngineCard(to_select:getEffectiveId())
	if ec:property("YingBianEffects"):toString() == "" then return false end
	local c = sgs.Self:getTag("nosjinwanyi"):toCard()
	if c==nil then return false end
	c:addSubcard(to_select)
	c:setSkillName("nosjinwanyi")
	return c:isAvailable(sgs.Self)
end,
view_as = function(self,card)
	local _card = sgs.Self:getTag("nosjinwanyi"):toCard()
	if _card and _card:isAvailable(sgs.Self) then
		local c = nosjinwanyiCard:clone()
		c:setUserString(_card:objectName())
		c:addSubcard(card)
		return c
	end
end
}

nos_jin_yangzhi:addSkill(nosjinwanyi)
nos_jin_yangzhi:addSkill("jinmaihuo")

--杨艳
nos_jin_yangyan = sgs.General(yue,"nos_jin_yangyan","jin",3,false)
--nos_jin_yangyan:setImage("jin_yangyan")

nosjinxuanbei = sgs.CreateTriggerSkill{
name = "nosjinxuanbei",
events = {sgs.GameStart,sgs.CardFinished},
on_trigger = function(self,event,player,data,room)
	if event == sgs.GameStart then
		local ids = sgs.IntList()
		for _,id in sgs.qlist(room:getDrawPile())do
			if sgs.Sanguosha:getEngineCard(id):property("YingBianEffects"):toString() == "" then continue end
			ids:append(id)
		end
		if ids:isEmpty() then return false end
		room:sendCompulsoryTriggerLog(player,self)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		for i = 1,2 do
			if ids:isEmpty() then break end
			local id = ids:at(math.random(0,ids:length() - 1))
			ids:removeOne(id)
			slash:addSubcard(id)
		end
		if slash:subcardsLength() == 0 then return false end
		room:obtainCard(player,slash)
	else
		if not room:hasCurrent() or player:getMark("nosjinxuanbei_Used-Clear") > 0 then return false end
		local use = data:toCardUse()
		if use.card:isVirtualCard() or use.card:getSkillName() ~= "" then return false end
		if sgs.Sanguosha:getEngineCard(use.card:getEffectiveId()):property("YingBianEffects"):toString() == "" then return false end
		if not room:CardInPlace(use.card,sgs.Player_DiscardPile) then return false end
		local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@nosjinxuanbei-invoke:"..use.card:objectName(),true,true)
		if not target then return false end
		player:peiyin(self)
		player:addMark("nosjinxuanbei_Used-Clear")
		room:giveCard(player,target,use.card,self:objectName(),true)
	end
	return false
end
}

nos_jin_yangyan:addSkill(nosjinxuanbei)
nos_jin_yangyan:addSkill("jinxianwan")

sgs.Sanguosha:setPackage(yue)

local zhi = sgs.Sanguosha:getPackage("mobilezhi")

zhi2_feiyi = sgs.General(zhi,"zhi2_feiyi","shu",3)
zhi2_feiyi:addSkill("mobilezhijianyu")
zhi2shengxi = sgs.CreateTriggerSkill{
	name = "zhi2shengxi",
	frequency = sgs.Skill_Frequent,
	waked_skills = "_ov_tiaojiyanmei",
	events = {sgs.EventPhaseProceeding,sgs.Damage,sgs.CardFinished},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseProceeding
	   	then
			if player:getPhase()==sgs.Player_Start
			and ToSkillInvoke(self,player)
			then
				room:broadcastSkillInvoke("zhishengxi")
				for i,c in sgs.list(PatternsCard("Tiaojiyanmei",true,true))do
					if room:getCardOwner(c:getEffectiveId())
					then continue end
					player:obtainCard(c)
					break
				end
			elseif player:getPhase()==sgs.Player_Finish
			and player:getMark("zhi2shengxiUse-Clear")>0
			and player:getMark("zhi2shengxiDamage-Clear")<1
			and ToSkillInvoke(self,player)
			then
				room:broadcastSkillInvoke("zhishengxi")
				for i,c in sgs.list(PatternsCard(sgs.ZhinangClassName,true,true))do
					if room:getCardPlace(c:getEffectiveId())==sgs.Player_PlaceTable
					or room:getCardOwner(c:getEffectiveId())
					then continue end
					player:obtainCard(c)
					break
				end
				player:drawCardsList(1,self:objectName())
			end
		elseif event==sgs.Damage
		and player:hasFlag("CurrentPlayer")
		then player:addMark("zhi2shengxiDamage-Clear")
		elseif event==sgs.CardFinished
		and player:hasFlag("CurrentPlayer")
		then
			local use = data:toCardUse()
			if use.card:getTypeId()>0
			then
				player:addMark("zhi2shengxiUse-Clear")
			end
		end
		return false
	end
}
zhi2_feiyi:addSkill(zhi2shengxi)

--神郭嘉
shenguojia = sgs.General(zhi,"shenguojia","god",3)
--sgs.Sanguosha:setAudioType("shenguojia","slash","1")
huishiCard = sgs.CreateSkillCard{
name = "huishiCard",
target_fixed = true,
on_use = function(self,room,source)	
	local suits = {}
	while (source:isAlive() and source:getMaxHp() < 10)do		
		local judge = sgs.JudgeStruct()
		judge.who = source
		judge.reason = self:getSkillName()
		judge.pattern = ".|"..table.concat(suits,",")
		judge.throw_card = false
		judge.good = false
		room:judge(judge)
		table.insert(suits,judge.card:getSuitString())
		local id = judge.card:getEffectiveId()
		if room:getCardPlace(id)==sgs.Player_PlaceJudge then
			self:addSubcard(id)
		end
		
		if judge:isGood() and source:getMaxHp() < 10
		and source:isAlive() and source:askForSkillInvoke(self:getSkillName()) then
			room:gainMaxHp(source,1,self:getSkillName())
		else
			break
		end
	end
	
	if source:isAlive() and self:subcardsLength() > 0 then
		room:fillAG(self:getSubcards(),source)
		local to = room:askForPlayerChosen(source,room:getAlivePlayers(),self:getSkillName(),"@huishi-give",true,false)
		room:clearAG(source)
		if to then
			room:doAnimate(1,source:objectName(),to:objectName())
			room:giveCard(source,to,self,self:getSkillName(),true)
			if to:isAlive() and source:isAlive() then
				local hand = to:getHandcardNum()
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:getHandcardNum() > hand then return end
				end
				room:loseMaxHp(source,1,self:getSkillName())
				return
			end
		end
	end
	room:throwCard(self,nil)
end
}

huishi = sgs.CreateZeroCardViewAsSkill{
name = "huishi",
view_as = function()
	return huishiCard:clone()
end,
enabled_at_play = function(self,player)
	return player:getMaxHp() < 10 and not player:hasUsed("#huishiCard")
end
}

godtianyi = sgs.CreatePhaseChangeSkill{
name = "godtianyi",
frequency = sgs.Skill_Wake,
waked_skills = "zuoxing",--[[
can_wake = function(self,event,player,data,room)
	if player:getPhase() ~= sgs.Player_Start or player:getMark(self:objectName()) > 0 then return false end
	if player:canWake(self:objectName()) then return true end
	for _,p in sgs.qlist(room:getAlivePlayers())do
		if p:getMark("godtianyi_record") <= 0 then return false end
	end
	return true
end,]]
can_trigger = function(self,player)
	return player and player:getPhase() == sgs.Player_Start
	and player:getMark(self:objectName())<1 and player:hasSkill(self)
end,
on_phasechange = function(self,player,room)
	if not player:canWake(self:objectName()) then
		for _,p in sgs.qlist(room:getAlivePlayers())do
			if p:getMark("godtianyi_record") <= 0 then return false end
		end
	end
	room:sendCompulsoryTriggerLog(player,self)
	room:doSuperLightbox(player,self:objectName())
	room:setPlayerMark(player,"godtianyi",1)
	if room:changeMaxHpForAwakenSkill(player,2,self:objectName()) then
		room:recover(player,sgs.RecoverStruct(self:objectName(),player))
		if player:isDead() then return false end
		local t = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"@godtianyi-invoke")
		if not t then return false end
		room:doAnimate(1,player:objectName(),t:objectName())
		room:acquireSkill(t,"zuoxing")
	end
	return false
end
}

godtianyiRecord = sgs.CreateTriggerSkill{
name = "#godtianyiRecord",
--frequency = sgs.Skill_Wake,
events = sgs.DamageDone,
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	player:addMark("godtianyi_record")
	return false
end
}

huishiiCard = sgs.CreateSkillCard{
name = "huishii",
filter = function(self,targets,to_select)
	return #targets == 0
end,
on_effect = function(self,effect)
	local source,target = effect.from,effect.to
	local room = source:getRoom()
	
	room:doSuperLightbox(source,"huishii")
	room:removePlayerMark(source,"@huishiiMark")
	
	local skills = {}
	for _,sk in sgs.qlist(target:getVisibleSkillList())do
		if sk:getFrequency(target) ~= sgs.Skill_Wake or target:getMark(sk:objectName()) > 0 then continue end
		table.insert(skills,sk:objectName())
	end
	if #skills > 0 and source:getMaxHp() >= room:alivePlayerCount() then
		local data = sgs.QVariant()
		data:setValue(target)
		local skill = room:askForChoice(source,self:objectName(),table.concat(skills,"+"),data)
		target:setCanWake("huishii",skill)
	else
		target:drawCards(4,"huishii")
	end
	
	if source:isDead() then return end
	room:loseMaxHp(source,2,self:objectName())
end
}

huishiiVS = sgs.CreateZeroCardViewAsSkill{
name = "huishii",
view_as = function()
	return huishiiCard:clone()
end,
enabled_at_play = function(self,player)
	return player:getMark("@huishiiMark") > 0
end
}

huishii = sgs.CreateGameStartSkill{
name = "huishii",
frequency = sgs.Skill_Limited,
view_as_skill = huishiiVS,
limit_mark = "@huishiiMark",
on_gamestart = function(self,player)
	return false
end
}

local function isSpecialOne(player,name)
	if string.find(player:getGeneralName(),name) then return true end
	if player:getGeneral2() then
		if string.find(player:getGeneral2Name(),name) then return true end
	end
	return false
end

zuoxingCard = sgs.CreateSkillCard{
name = "zuoxing",
target_fixed = false,
filter = function(self,targets,to_select,player)
	local _card = sgs.Sanguosha:cloneCard(self:getUserString())
	_card:setSkillName("zuoxing")
	_card:setCanRecast(false)
	_card:deleteLater()
	if _card:targetFixed() then  --因源码bug，不得已而为之
		return false
	end
	local new_targets = sgs.PlayerList()
	for _,p in ipairs(targets)do
		new_targets:append(p)
	end
	return _card:targetFilter(new_targets,to_select,player)
end,
feasible = function(self,targets,player)
	local _card = sgs.Sanguosha:cloneCard(self:getUserString())
	_card:setSkillName("zuoxing")
	_card:setCanRecast(false)
	_card:deleteLater()
	if _card:targetFixed() then  --因源码bug，不得已而为之
		return true
	end
	local new_targets = sgs.PlayerList()
	for _,p in ipairs(targets)do
		new_targets:append(p)
	end
	return _card:targetsFeasible(new_targets,player)
end,
on_validate = function(self,card_use)
	local use_card = sgs.Sanguosha:cloneCard(self:getUserString())
	use_card:setSkillName("zuoxing")
	use_card:deleteLater()
	return use_card
end
}

zuoxingVS = sgs.CreateZeroCardViewAsSkill{
name = "zuoxing",
view_as = function()
	local _card = sgs.Self:getTag("zuoxing"):toCard()
	if _card and _card:isAvailable(sgs.Self) then
		local c = zuoxingCard:clone()
		c:setUserString(_card:objectName())
		return c
	end
end,
enabled_at_play = function(self,player)
	return player:getMark("zuoxing-Clear") > 0 and not player:hasUsed("#zuoxing")
end
}

zuoxing = sgs.CreatePhaseChangeSkill{
name = "zuoxing",
guhuo_type = "r",
view_as_skill = zuoxingVS,
on_phasechange = function(self,player,room)
	if player:getPhase() ~= sgs.Player_Start then return false end
	local shenguojias = sgs.SPlayerList()
	for _,p in sgs.qlist(room:getAlivePlayers())do
		if p:getMaxHp() > 1 and isSpecialOne(p,"shenguojia") then
			shenguojias:append(p)
		end
	end
	local shenguojia = room:askForPlayerChosen(player,shenguojias,"zuoxing","@zuoxing-invoke",true,true)
	if not shenguojia then return false end
	shenguojia:peiyin(self)
	room:loseMaxHp(shenguojia,1,self:objectName())
	room:setPlayerMark(player,"zuoxing-Clear",1)
	return false
end
}
zhi:addSkills(zuoxing)
shenguojia:addSkill(huishi)
shenguojia:addSkill(godtianyi)
shenguojia:addSkill(godtianyiRecord)
shenguojia:addSkill(huishii)
zhi:insertRelatedSkills("godtianyi","#godtianyiRecord")

--神荀彧
shenxunyu = sgs.General(zhi,"shenxunyu","god",3)

tianzuo = sgs.CreateTriggerSkill{
name = "tianzuo",
events = {sgs.GameStart,sgs.CardEffected},
frequency = sgs.Skill_Compulsory,
waked_skills = "_qizhengxiangsheng",
on_trigger = function(self,event,player,data,room)
	if event == sgs.GameStart then
		local cards = sgs.IntList()
		for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
			if sgs.Sanguosha:getEngineCard(id):isKindOf("Qizhengxiangsheng") and room:getCardPlace(id) ~= sgs.Player_DrawPile then
				cards:append(id)
			end
		end
		if not cards:isEmpty() then
			room:sendCompulsoryTriggerLog(player,self)
			room:shuffleIntoDrawPile(player,cards,self:objectName(),true)
		end
	else
		local effect = data:toCardEffect()
		if not effect.card:isKindOf("Qizhengxiangsheng") then return false end
		local log = sgs.LogMessage()
		log.type = "#WuyanGooD"
		log.from = player
		log.to:append(effect.from)
		log.arg = effect.card:objectName()
		log.arg2 = self:objectName()
		room:sendLog(log)
		player:peiyin(self)
		room:notifySkillInvoked(player,self:objectName())
		return true
	end
	return false
end
}

lingce = sgs.CreateTriggerSkill{
name = "lingce",
events = sgs.CardUsed,
frequency = sgs.Skill_Compulsory,
waked_skills = "_qizhengxiangsheng",
can_trigger = function(self,player)
	return player
end,
on_trigger = function(self,event,player,data,room)
	local use = data:toCardUse()
	if not use.card:isKindOf("TrickCard") or use.card:isVirtualCard() then return false end
	for _,p in sgs.qlist(room:getAllPlayers())do
		if p:isDead() or not p:hasSkill(self) then continue end
		local names = p:property("SkillDescriptionRecord_dinghan"):toString():split("+")
		if use.card:isZhinangCard() or --use.card:isKindOf("Dismantlement") or use.card:isKindOf("Nullification") or use.card:isKindOf("Qizhengxiangsheng") or
			(p:hasSkill("dinghan",true) and table.contains(names,use.card:objectName())) then
			room:sendCompulsoryTriggerLog(p,self)
			p:drawCards(1,self:objectName())
		end
	end
	return false
end
}

dinghan = sgs.CreateTriggerSkill{
name = "dinghan",
events = {sgs.TargetConfirming,sgs.EventPhaseStart},
on_trigger = function(self,event,player,data,room)
	if event == sgs.TargetConfirming then
		local use = data:toCardUse()
		if not use.card:isKindOf("TrickCard") then return false end
		local names,name = player:property("SkillDescriptionRecord_dinghan"):toString():split("+"),use.card:objectName()
		if table.contains(names,name) then return false end
		table.insert(names,name)
		room:setPlayerProperty(player,"SkillDescriptionRecord_dinghan",sgs.QVariant(table.concat(names,"+")))
		local choice = {}
		for _,pt in sgs.list(names)do
			table.insert(choice,pt)
			table.insert(choice,"|")
		end
		player:setSkillDescriptionSwap("dinghan","%arg11",table.concat(choice,"+"));
		room:changeTranslation(player,"dinghan")
		
		local log = sgs.LogMessage()
		log.type = "#WuyanGooD"
		log.from = player
		log.to:append(use.from)
		log.arg = name
		log.arg2 = self:objectName()
		room:sendLog(log)
		player:peiyin(self)
		room:notifySkillInvoked(player,self:objectName())
		
		local nullified_list = use.nullified_list
		table.insert(nullified_list,player:objectName())
		use.nullified_list = nullified_list
		data:setValue(use)
	else
		if player:getPhase() ~= sgs.Player_RoundStart then return false end
		local record,other,all,dinghan,tricks = sgs.IntList(),sgs.IntList(),sgs.IntList(),player:property("SkillDescriptionRecord_dinghan"):toString():split("+"),{}
		for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards())do
			local c = sgs.Sanguosha:getEngineCard(id)
			if not c:isKindOf("TrickCard") or table.contains(tricks,c:objectName()) then continue end
			table.insert(tricks,c:objectName())
			--all:append(id)
			if table.contains(dinghan,c:objectName()) then
				record:append(id)
			else
				other:append(id)
			end
		end
		
		for _,id in sgs.qlist(record)do
			all:append(id)
		end
		for _,id in sgs.qlist(other)do
			all:append(id)
		end
		
		local choices = {}
		if not other:isEmpty() then
			table.insert(choices,"add")
		end
		if not record:isEmpty() then
			table.insert(choices,"remove")
		end
		if #choices<1 then return false end
		table.insert(choices,"cancel")
		
		room:fillAG(all,player,other)
		local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"),sgs.QVariant(),"","tip")
		room:clearAG(player)
		
		if choice == "cancel" then return false end
		
		local log = sgs.LogMessage()
		log.type = "#InvokeSkill"
		log.from = player
		log.arg = self:objectName()
		room:sendLog(log)
		player:peiyin(self)
		room:notifySkillInvoked(player,self:objectName())
		
		if choice == "remove" then
			room:fillAG(record,player)
			local id = room:askForAG(player,record,false,self:objectName())
			room:clearAG(player)
			local name = sgs.Sanguosha:getEngineCard(id):objectName()
			log.type = "#DingHanRemove"
			log.from = player
			log.arg = self:objectName()
			log.arg2 = name
			room:sendLog(log)
			table.removeOne(dinghan,name)
			room:setPlayerProperty(player,"SkillDescriptionRecord_dinghan",sgs.QVariant(table.concat(dinghan,"+")))
			choice = {}
			for _,pt in sgs.list(dinghan)do
				table.insert(choice,pt)
				table.insert(choice,"|")
			end
			player:setSkillDescriptionSwap("dinghan","%arg11",table.concat(choice,"+"));
			if #dinghan == 0 then
				room:changeTranslation(player,"dinghan",0)
			else
				room:changeTranslation(player,"dinghan")
			end
		else
			room:fillAG(other,player)
			local id = room:askForAG(player,other,false,self:objectName())
			room:clearAG(player)
			local name = sgs.Sanguosha:getEngineCard(id):objectName()
			log.type = "#DingHanAdd"
			log.from = player
			log.arg = self:objectName()
			log.arg2 = name
			room:sendLog(log)
			table.insert(dinghan,name)
			room:setPlayerProperty(player,"SkillDescriptionRecord_dinghan",sgs.QVariant(table.concat(dinghan,"+")))
			choice = {}
			for _,pt in sgs.list(dinghan)do
				table.insert(choice,pt)
				table.insert(choice,"|")
			end
			player:setSkillDescriptionSwap("dinghan","%arg11",table.concat(choice,"+"));
			room:changeTranslation(player,"dinghan")
		end
	end
	return false
end
}

shenxunyu:addSkill(tianzuo)
shenxunyu:addSkill(lingce)
shenxunyu:addSkill(dinghan)

sgs.Sanguosha:setPackage(zhi)

local exclusive_cards = sgs.Sanguosha:getPackage("exclusive_cards")

--奇正相生
Qizhengxiangsheng = sgs.CreateTrickCard {
name = "_qizhengxiangsheng",
class_name = "Qizhengxiangsheng",
subtype = "shenxunyu_card",
suit = sgs.Card_Spade,
number = 2,
damage_card = true,
single_target = true,
filter = function(self,targets,to_select,player)
	return to_select:objectName()~=player:objectName()
	and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,player,self,to_select)
	and not player:isProhibited(to_select,self)
end,
available = function(self,player)
   	for _,to in sgs.list(player:getAliveSiblings())do
		if self:targetFilter(sgs.PlayerList(),to,player)
		then return self:cardIsAvailable(player) end
	end	
end,
on_effect = function(self,effect)
	local from,to = effect.from,effect.to
	local room = from:getRoom()
	if from:isDead() or to:isDead() then return end
	
	local data = sgs.QVariant()
	data:setValue(to)
	local choice = room:askForChoice(from,"_qizhengxiangsheng","zhengbing="..to:objectName().."+qibing="..to:objectName(),data)
	
	local log = sgs.LogMessage()
	log.type = "#QizhengxiangshengLog"
	log.from = from
	log.to:append(to)
	log.arg = "_qizhengxiangsheng_"..choice:split("=")[1]
	room:sendLog(log,from)
	local card = room:askForCard(to,"Slash,Jink","@_qizhengxiangsheng-card:",data,sgs.Card_MethodResponse,from,false,"",false,self)
	room:sendLog(log,room:getOtherPlayers(from,true))
	if choice:startsWith("zhengbing") then
		if not(card and card:isKindOf("Jink")) then
			if from:isDead() or to:isNude() then return end
			local id = room:askForCardChosen(from,to,"he",self:objectName())
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,from:objectName())
			room:obtainCard(from,sgs.Sanguosha:getCard(id),reason,false)
		end
	elseif choice:startsWith("qibing") then
		if not(card and card:isKindOf("Slash")) then
			room:damage(sgs.DamageStruct(self,from,to))
		end
	end
end
}

Qizhengxiangsheng:setParent(exclusive_cards)

for i = 3,9 do
	local qzxs = Qizhengxiangsheng:clone(i % 2,i)
	qzxs:setParent(exclusive_cards)
end

sgs.LoadTranslationTable {
["_qizhengxiangsheng"] = "奇正相生",
[":_qizhengxiangsheng"] = "锦囊牌·单目标锦囊<br/><b>时机</b>：出牌阶段，对一名其他角色使用<br/><b>效果</b>：你秘密选择“正兵”或“奇兵”，然后目标角色可以打出一张【杀】或【闪】。"..
							"若你选择了“正兵”且其未打出【闪】，你获得其一张牌；若你选择了“奇兵”且其未打出【杀】，你对其造成1点伤害。",
["shenxunyu_card"] = "神荀彧专属",
["_qizhengxiangsheng:zhengbing"] = "为%src选择“正兵”",
["_qizhengxiangsheng:qibing"] = "为%src选择“奇兵”",
["@_qizhengxiangsheng-card"] = "奇正相生：你可以打出一张【杀】或【闪】",
["#QizhengxiangshengLog"] = "%from 为 %to 选择了“%arg”",
["_qizhengxiangsheng_zhengbing"] = "正兵",
["_qizhengxiangsheng_qibing"] = "奇兵",
["_qizhengxiangsheng_:slash"] = "打出一张【杀】",
["_qizhengxiangsheng_:jink"] = "打出一张【闪】",
}

--装备技能
taipingyaoshuskill = sgs.CreateTriggerSkill{
	name = "_taipingyaoshu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	can_trigger = function(self,target)
		return target and target:hasArmorEffect(self:objectName())
	end,
	on_trigger = function(self,event,player,data,room)
    	if (event == sgs.DamageInflicted) then
			local damage = data:toDamage()
			if damage.nature ~= sgs.DamageStruct_Normal then
				room:sendCompulsoryTriggerLog(player,self)
				return player:damageRevises(data,-damage.damage)
			end
		end
	end
}
exclusive_cards:addSkills(taipingyaoshuskill)
--装备
taipingyaoshu = sgs.CreateArmor{
	name = "_taipingyaoshu",
	class_name = "Taipingyaoshu",
	suit = 2,
	number = 3,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,taipingyaoshuskill,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,self:objectName(),true,true)
		if player:isAlive() and player:hasArmorEffect(self:objectName()) then
			player:drawCards(2,self:objectName())
			if (player:getHp() > 1) then
				room:loseHp(player,1,true,player,self:objectName())
			end
		end
		return false
	end,
}
taipingyaoshu:setParent(exclusive_cards)

local xin = sgs.Sanguosha:getPackage("mobilexin")

xin2_zhouchu = sgs.General(xin,"xin2_zhouchu","wu",4)
xin2_zhouchu:addSkill("mobilexinxianghai")
xin2chuhaiCard = sgs.CreateSkillCard{
	name = "xin2chuhaiCard",
	target_fixed = true,
	mute = true,
	on_use = function(self,room,source,targets)
		source:peiyin(self:getSkillName(),1)
		source:drawCards(1,"xin2chuhai")
		local tos = sgs.SPlayerList()
		for _,p in sgs.list(room:getOtherPlayers(source))do
			if source:canPindian(p)
			then tos:append(p) end
		end
		local to = room:askForPlayerChosen(source,tos,"xin2chuhai","xin2chuhai0:")
		if to then
			room:doAnimate(1,source:objectName(),to:objectName())
			if source:pindian(to,"xin2chuhai") then
				source:peiyin(self:getSkillName(),2)
				room:addPlayerMark(to,source:objectName().."xin2chuhai-PlayClear")
				room:doGongxin(source,to,to:handCards(),"xin2chuhai")
				local ctype = {}
				for _,h in sgs.list(to:getHandcards())do
					ctype[h:getType()] = true
				end
				for _,id in sgs.list(room:getDrawPile())do
					local c = sgs.Sanguosha:getCard(id)
					if ctype[c:getType()] then
						ctype[c:getType()] = false
						room:obtainCard(source,c)
					end
				end
				for _,id in sgs.list(room:getDiscardPile())do
					local c = sgs.Sanguosha:getCard(id)
					if ctype[c:getType()] then
						ctype[c:getType()] = false
						room:obtainCard(source,c)
					end
				end
			else
				source:peiyin(self:getSkillName(),3)
			end
		end
	end,
}
xin2chuhaiVS = sgs.CreateViewAsSkill{
	name = "xin2chuhai",
	view_as = function(self,cards)
		return xin2chuhaiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#xin2chuhaiCard")<1
		and player:getMark("successxin2chuhai")<1
		and player:getMark("failxin2chuhai")<1
	end,
}
xin2chuhai = sgs.CreateTriggerSkill{
	name = "xin2chuhai",
	shiming_skill = true,
	view_as_skill = xin2chuhaiVS,
	events = {sgs.PindianVerifying,sgs.CardsMoveOneTime,sgs.Pindian,sgs.Damage},
	waked_skills = "xinzhangming",
	on_trigger = function(self,event,player,data,room)
		if player:getMark("successxin2chuhai") > 0
		or player:getMark("failxin2chuhai") > 0
		then return false end
		if event == sgs.PindianVerifying then
			local pindian = data:toPindian()
			if pindian.reason ~= "xin2chuhai"
			or pindian.from:objectName() ~= player:objectName()
			then return false end
			local n = 4-player:getEquips():length()
			if n <= 0 then n = 0 end
			pindian.from_number = pindian.from_number + n
			data:setValue(pindian)
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.to:getMark(player:objectName().."xin2chuhai-PlayClear")>0 then
				for _,id in sgs.list(room:getDrawPile())do
					local c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("EquipCard") then
						local n = c:getRealCard():toEquipCard():location()
						if player:hasEquipArea(n) and player:getEquip(n)==nil then
							player:peiyin(self:objectName(),2)
							room:moveCardTo(c,player,sgs.Player_PlaceEquip,true)
							return false
						end
					end
				end
				for _,id in sgs.list(room:getDiscardPile())do
					local c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("EquipCard") then
						local n = c:getRealCard():toEquipCard():location()
						if player:hasEquipArea(n) and player:getEquip(n)==nil then
							room:moveCardTo(c,player,sgs.Player_PlaceEquip,true)
							return false
						end
					end
				end
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_PlaceEquip
			and move.to:objectName() == player:objectName()
			and player:getEquips():length() >= 3 then
				local log = sgs.LogMessage()
				log.type = "#chuhaisuccess"
				log.from = player
				log.arg = "xin2chuhai"
				room:sendLog(log)
				room:recover(player,sgs.RecoverStruct(self:objectName(),player,player:getMaxHp()))
				room:handleAcquireDetachSkills(player,"xinzhangming|-mobilexinxianghai")
				room:addPlayerMark(player,"successxin2chuhai")
			end
		elseif event == sgs.Pindian then
			local pindian = data:toPindian()
			if pindian.reason ~= "xin2chuhai" or pindian.success then return false end
			if pindian.from == player and pindian.from_number <= 6 then
				player:peiyin(self:objectName(),3)
				local log = sgs.LogMessage()
				log.type = "#chuhaifail"
				log.from = player
				log.arg = "xin2chuhai"
				room:sendLog(log)
				room:addPlayerMark(player,"failxin2chuhai")
			end
		end
		return false
	end,
}
xinzhangming = sgs.CreateTriggerSkill{
	name = "xinzhangming",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed,sgs.Damage},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.card:getSuit() == sgs.Card_Club then
				room:sendCompulsoryTriggerLog(player,self)
				local no_respond_list = use.no_respond_list
				table.insert(no_respond_list,"_ALL_TARGETS")
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if player:getMark("xinzhangming-Clear") > 0
			or damage.to == player then return false end
			room:addPlayerMark(player,"xinzhangming-Clear")
			room:sendCompulsoryTriggerLog(player,self)
			if damage.to:getHandcardNum()>0 then
				for i=0,9 do
					local c = damage.to:getRandomHandCardId()
					if damage.to:canDiscard(damage.to,c) then
						room:throwCard(c,damage.to)
						c = sgs.Sanguosha:getCard(c)
						local ctype = {}
						ctype[c:getType()] = true
						for _,id in sgs.list(room:getDrawPile())do
							if player:isDead() then break end
							local c = sgs.Sanguosha:getCard(id)
							if ctype[c:getType()] then continue end
							ctype[c:getType()] = true
							room:obtainCard(player,c)
							room:ignoreCards(player,c)
						end
						for _,id in sgs.list(room:getDiscardPile())do
							if player:isDead() then break end
							local c = sgs.Sanguosha:getCard(id)
							if ctype[c:getType()] then continue end
							ctype[c:getType()] = true
							room:obtainCard(player,c)
							room:ignoreCards(player,c)
						end
						break
					end
				end
			end
		end
	end,
}
xin2_zhouchu:addSkill(xin2chuhai)
xin:addSkills(xinzhangming)

xin2_wujing = sgs.General(xin,"xin2_wujing","wu",4)
xin2_wujing:addSkill("mobilexinheji")
xinliubing = sgs.CreateTriggerSkill{
    name = "xinliubing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.PreCardUsed,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and not use.card:isVirtualCard() and player:getPhase()==sgs.Player_Play then
				room:addPlayerMark(player,"xinliubingUse-PlayClear")
				if player:hasSkill(self)
				and player:getMark("xinliubingUse-PlayClear")<2 then
					room:sendCompulsoryTriggerLog(player,self)
					local wc = sgs.Sanguosha:getWrappedCard(use.card:getEffectiveId())
					wc:setSuit(3)
					--wc:setSkillName(self:objectName())
					wc:setModified(true)
					room:broadcastUpdateCard(room:getPlayers(),use.card:getEffectiveId(),wc)
					--use.card = wc
					--data:setValue(use)
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.card:isBlack() and not use.card:hasFlag("DamageDone")
			and not use.card:isVirtualCard() and player:getPhase()==sgs.Player_Play then
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
					if p==player or room:getCardOwner(use.card:getEffectiveId()) then continue end
					room:sendCompulsoryTriggerLog(p,self)
					room:obtainCard(p,use.card,false)
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
xin2_wujing:addSkill(xinliubing)

--神太史慈
shentaishici = sgs.General(xin,"shentaishici","god",4)

dulie = sgs.CreateTriggerSkill{
name = "dulie",
events = {sgs.GameStart,sgs.TargetConfirming},
frequency = sgs.Skill_Compulsory,
on_trigger = function(self,event,player,data,room)
	if event == sgs.GameStart then
		room:sendCompulsoryTriggerLog(player,self)
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if p:isDead() then continue end
			p:gainMark("&stscdlwei")
		end
	else
		local use = data:toCardUse()
		if not use.card:isKindOf("Slash") or not use.to:contains(player) then return false end
		if not use.from or use.from:isDead() or use.from:getMark("&stscdlwei") > 0 then return false end
		room:sendCompulsoryTriggerLog(player,self)
		
		local judge = sgs.JudgeStruct()
		judge.who = player
		judge.good = true
		judge.pattern = ".|heart"
		judge.reason = self:objectName()
		room:judge(judge)
		
		if not judge:isGood() then return false end
		
		local nullified_list = use.nullified_list
		table.insert(nullified_list,player:objectName())
		use.nullified_list = nullified_list
		data:setValue(use)
	end
	return false
end
}

powei = sgs.CreateTriggerSkill{
name = "powei",
events = {sgs.DamageCaused,sgs.CardFinished,sgs.Dying},
shiming_skill = true,
waked_skills = "shenzhuo",
frequency = sgs.Skill_NotCompulsory,
on_trigger = function(self,event,player,data,room)
	if player:getMark("powei") > 0 then return false end
	
	if event == sgs.DamageCaused then
		local damage = data:toDamage()
		if not damage.card or not damage.card:isKindOf("Slash") or not damage.by_user or damage.to:isDead() or damage.to:getMark("&stscdlwei") <= 0 then return false end
		room:sendCompulsoryTriggerLog(player,self,1)
		damage.to:loseMark("&stscdlwei")
		return player:damageRevises(data,-damage.damage)
	elseif event == sgs.CardFinished then
		for _,p in sgs.qlist(room:getAlivePlayers())do
			if p:getMark("&stscdlwei") > 0 then return false end
		end
		room:sendShimingLog(player,self)
		room:acquireSkill(player,"shenzhuo")
	else
		local who = room:getCurrentDyingPlayer()
		if not who or who:objectName() ~= player:objectName() then return false end
		room:sendShimingLog(player,self,false)
		local recover = math.min(1- player:getHp(),player:getMaxHp() - player:getHp())
		room:recover(player,sgs.RecoverStruct(self:objectName(),player,recover))
		if player:isAlive() then
			player:throwAllEquips()
		end
	end
	return false
end
}

dangmoCard = sgs.CreateSkillCard{
name = "dangmo",
mute = true,
filter = function(self,targets,to_select,player)
	return #targets < player:getHp() - 1 and to_select:hasFlag("dangmo")
end,
about_to_use = function(self,room,use)
	for _,p in sgs.qlist(use.to)do
		room:setPlayerFlag(p,"dangmo_slash")
	end
end
}

dangmoVS = sgs.CreateZeroCardViewAsSkill{
name = "dangmo",
response_pattern = "@@dangmo",
view_as = function()
	return dangmoCard:clone()
end
}

dangmo = sgs.CreateTriggerSkill{
name = "dangmo",
events = sgs.PreCardUsed,
view_as_skill = dangmoVS,
on_trigger = function(self,event,player,data,room)
	local use = data:toCardUse()
	if not use.card:isKindOf("Slash") or not use.card:hasFlag("dangmo_first_slash") then return false end
	room:setCardFlag(use.card,"-dangmo_first_slash")
	local extra = player:getHp() - 1
	if extra <= 0 then return false end
	
	local extra_targets = room:getCardTargets(player,use.card,use.to)
	if extra_targets:isEmpty() then return false end
	
	for _,p in sgs.qlist(extra_targets)do
		room:setPlayerFlag(p,"dangmo")
	end
	
	room:askForUseCard(player,"@@dangmo","@dangmo:"..use.card:objectName().."::"..extra,-1,sgs.Card_MethodNone)
	
	local adds = sgs.SPlayerList()
	for _,p in sgs.qlist(extra_targets)do
		room:setPlayerFlag(p,"-dangmo")
		if p:hasFlag("dangmo_slash") then
			room:setPlayerFlag(p,"-dangmo_slash")
			use.to:append(p)
			adds:append(p)
		end
	end
	
	if adds:isEmpty() then return false end
	room:sortByActionOrder(adds)
	
	room:sortByActionOrder(use.to)
	data:setValue(use)
	
	local log = sgs.LogMessage()
	log.type = "#QiaoshuiAdd"
	log.from = player
	log.to = adds
	log.card_str = use.card:toString()
	log.arg = "dangmo"
	room:sendLog(log)
	for _,p in sgs.qlist(adds)do
		room:doAnimate(1,player:objectName(),p:objectName())
	end
	player:peiyin(self)
	room:notifySkillInvoked(player,self:objectName())
	return false
end
}

dangmoSlash = sgs.CreateTriggerSkill{
name = "#dangmo-slash",
events = sgs.PreCardUsed,
priority = 5,
on_trigger = function(self,event,player,data,room)
	if player:getPhase() ~= sgs.Player_Play then return false end
	local use = data:toCardUse()
	if not use.card:isKindOf("Slash") or player:getMark("dangmo-PlayClear") > 0 then return false end
	room:addPlayerMark(player,"dangmo-PlayClear")
	room:setCardFlag(use.card,"dangmo_first_slash")
	return false
end
}

shenzhuo = sgs.CreateTriggerSkill{
name = "shenzhuo",
events = sgs.CardFinished,
on_trigger = function(self,event,player,data,room)
	local use = data:toCardUse()
	if not use.card:isKindOf("Slash") or use.card:isVirtualCard() then return false end
	room:sendCompulsoryTriggerLog(player,self)
	player:drawCards(1,"shenzhuo")
	return false
end
}
xin:addSkills(shenzhuo)

shentaishici:addSkill(dulie)
shentaishici:addSkill(powei)
shentaishici:addSkill(dangmo)
shentaishici:addSkill(dangmoSlash)
xin:insertRelatedSkills("dangmo","#dangmo-slash")

--神孙策
shensunce = sgs.General(xin,"shensunce","god",6)
shensunce:setStartHp(1)

yingbaCard = sgs.CreateSkillCard{
name = "yingba",
filter = function(self,targets,to_select,player)
	return #targets == 0 and player:objectName() ~= to_select:objectName() and to_select:getMaxHp() > 1
end,
on_effect = function(self,effect)
	local from,to = effect.from,effect.to
	--if to:getMaxHp() <= 1 or from:objectName() == to:objectName() then return end
	local room = from:getRoom()
	room:loseMaxHp(to,1,self:objectName())
	if to:isAlive() then
		to:gainMark("&sscybpingding")
	end
	room:loseMaxHp(from,1,self:objectName())
end
}

yingba = sgs.CreateZeroCardViewAsSkill{
name = "yingba",
view_as = function(self,card)
	return yingbaCard:clone()
end,
enabled_at_play = function(self,player)
	return not player:hasUsed("#yingba")
end
}

fuhaisc = sgs.CreateTriggerSkill{
name = "fuhaisc",
events = {sgs.CardUsed,sgs.TargetSpecifying,sgs.CardsMoveOneTime,sgs.Death,sgs.CardResponded},
frequency = sgs.Skill_Compulsory,
on_trigger = function(self,event,player,data,room)
	if event == sgs.CardUsed then
		local use = data:toCardUse()
		if use.card:isKindOf("SkillCard") then return false end
		local sp,no_respond_list = sgs.SPlayerList(),use.no_respond_list
		for _,p in sgs.qlist(room:getAllPlayers())do
			if p:getMark("&sscybpingding") > 0 then
				table.insert(no_respond_list,p:objectName())
				sp:append(p)
			end
		end
		if sp:isEmpty() then return false end
		use.no_respond_list = no_respond_list
		data:setValue(use)
		local log = sgs.LogMessage()
		log.type = "#FuqiNoResponse"
		log.from = player
		log.to = sp
		log.arg = self:objectName()
		log.card_str = use.card:toString()
		room:sendLog(log)
		player:peiyin(self)
		room:notifySkillInvoked(player,self:objectName())
	elseif event == sgs.CardResponded then
		local res = data:toCardResponse()
		if res.m_card:isKindOf("SkillCard") or not res.m_isUse then return false end
		local sp = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAllPlayers())do
			if p:getMark("&sscybpingding") > 0 then
				sp:append(p)
			end
		end
		if sp:isEmpty() then return false end
		local log = sgs.LogMessage()
		log.type = "#FuqiNoResponse"
		log.from = player
		log.to = sp
		log.arg = self:objectName()
		log.card_str = res.m_card:toString()
		room:sendLog(log)
		player:peiyin(self)
		room:notifySkillInvoked(player,self:objectName())
	elseif event == sgs.TargetSpecifying then
		if not room:hasCurrent() or player:getMark("fuhaisc_draw-Clear") > 1 then return false end
		local use = data:toCardUse()
		if use.card:isKindOf("SkillCard") then return false end
		local invoke = false
		for _,p in sgs.qlist(use.to)do
			if p:getMark("&sscybpingding") > 0 then
				invoke = true
				break
			end
		end
		if not invoke then return false end
		room:sendCompulsoryTriggerLog(player,self)
		player:drawCards(1,self:objectName())
	elseif event == sgs.CardsMoveOneTime then  --这个时机应该单独写成一个触发技，要有单独的can_trigger，以免被无效，我就偷懒了
		local move = data:toMoveOneTime()
		if move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand and move.reason.m_skillName == self:objectName() then
			player:addMark("fuhaisc_draw-Clear",move.card_ids:length())
		end
	elseif event == sgs.Death then
		local death = data:toDeath()
		if not death.who or death.who:objectName() == player:objectName() then return false end
		local mark = death.who:getMark("&sscybpingding")
		if mark <= 0 then return false end
		room:sendCompulsoryTriggerLog(player,self)
		room:gainMaxHp(player,mark,self:objectName())
		player:drawCards(mark,self:objectName())
	end
	return false
end
}

pinghe = sgs.CreateTriggerSkill{
name = "pinghe",
events = sgs.DamageInflicted,
frequency = sgs.Skill_Compulsory,
waked_skills = "#pinghe_mcs",
on_trigger = function(self,event,player,data,room)
	local damage = data:toDamage()
	if not damage.from or damage.from == player then return false end
	if player:isKongcheng() or player:getMaxHp() < 2 then return false end
	room:sendCompulsoryTriggerLog(player,self)
	room:loseMaxHp(player,1,"pinghe")
	if player:isAlive() and not player:isKongcheng() then
		local hands = player:handCards()
		if not room:askForYiji(player,hands,"pinghe",false,false,false,1) then
			local c = player:getRandomHandCard()
			local tos = room:getOtherPlayers(player)
			local to = tos:at(math.random(0,tos:length() - 1))
			room:giveCard(player,to,c,self:objectName())
		end
		if player:isAlive() and player:hasSkill("yingba",true) and damage.from:isAlive() then
			damage.from:gainMark("&sscybpingding")
		end
	end
	return true
end
}

shensunce:addSkill(yingba)
shensunce:addSkill(fuhaisc)
shensunce:addSkill(pinghe)

sgs.Sanguosha:setPackage(xin)

local tenyear_hc = sgs.Sanguosha:getPackage("tenyear_hc")

--新sp贾诩[十周年]
tenyear_new_sp_jiaxu = sgs.General(tenyear_hc,"tenyear_new_sp_jiaxu","wei",3)

tenyearjianshuCard = sgs.CreateSkillCard{
name = "tenyearjianshu",
will_throw = false,
on_effect = function(self,effect)
	local from,to = effect.from,effect.to
	local room = from:getRoom()
	room:giveCard(from,to,self,"tenyearjianshu")
	
	if from:isDead() then return end
	local targets = room:getOtherPlayers(from)
	if targets:contains(to) then
		targets:removeOne(to)
	end
	if targets:isEmpty() then return end
	
	local other = room:askForPlayerChosen(from,targets,self:objectName(),"@tenyearjianshu-pindian:"..to:objectName())
	room:doAnimate(1,to:objectName(),other:objectName())
	if not to:canPindian(other,false) then return end
	
	local n = to:pindianInt(other,self:objectName())
	if n < -1 then return end
	
	local losers,winner = sgs.SPlayerList(),nil
	if n == -1 then
		winner = other
		losers:append(to)
	elseif n == 1 then
		winner = to
		losers:append(other)
	elseif n == 0 then
		losers:append(to)
		losers:append(other)
	end
	
	if winner then
		local cards = sgs.IntList()
		for _,id in sgs.qlist(winner:handCards())do
			if winner:canDiscard(winner,id) then
				cards:append(id)
			end
		end
		for _,id in sgs.qlist(winner:getEquipsId())do
			if winner:canDiscard(winner,id) then
				cards:append(id)
			end
		end
		if cards:isEmpty() then
			if not winner:isKongcheng() then
				local log = sgs.LogMessage()
				log.type = "#TenyearJianshuShow"
				log.from = winner
				room:sendLog(log)
				room:showAllCards(winner)
			end
		else
			local id = cards:at(math.random(0,cards:length() - 1))
			room:throwCard(id,winner)
		end
	end

	room:sortByActionOrder(losers)
	for _,p in sgs.qlist(losers)do
		room:loseHp(sgs.HpLostStruct(p,1,"tenyearjianshu",from))
	end
end
}

tenyearjianshuVS = sgs.CreateOneCardViewAsSkill{
name = "tenyearjianshu",
filter_pattern = ".|black|.|hand",
view_as = function(self,card)
	local c = tenyearjianshuCard:clone()
	c:addSubcard(card)
	return c
end,
enabled_at_play = function(self,player)
	return not player:hasUsed("#tenyearjianshu")
end
}

tenyearjianshu = sgs.CreateTriggerSkill{
name = "tenyearjianshu",
events = sgs.Death,
view_as_skill = tenyearjianshuVS,
can_trigger = function(self,player)
	return player
end,
on_trigger = function(self,event,player,data,room)
	local death = data:toDeath()
	if not death.who or not death.hplost then return false end
	if death.hplost.reason ~= self:objectName() or not death.hplost.from then return false end
	room:addPlayerHistory(death.hplost.from,"#tenyearjianshu",0)
end
}

tenyearyongdiCard = sgs.CreateSkillCard{
name = "tenyearyongdi",
filter = function(self,targets,to_select,player)
	return #targets == 0 and to_select:isMale()
end,
on_effect = function(self,effect)
	local from,to = effect.from,effect.to
	local room = from:getRoom()
	
	room:doSuperLightbox(from,"tenyearyongdi")
	room:removePlayerMark(from,"@tenyearyongdiMark")
	
	local choices = ""
	if to:isLowestHpPlayer() then
		choices = "maxhp"
		if to:isWounded() then
			choices = "recover+maxhp"
		end
	else
		local maxhp,lowest = to:getMaxHp(),true
		for _,p in sgs.qlist(room:getOtherPlayers(to))do
			if p:getMaxHp() < maxhp then
				lowest = false
				break
			end
		end
		if lowest then
			choices = "maxhp"
			if to:isWounded() then
				choices = "recover+maxhp"
			end
		end
	end
	
	if choices ~= "" then
		local choice = room:askForChoice(to,self:objectName(),choices)
		if choice == "recover" then
			room:recover(to,sgs.RecoverStruct(self:objectName(),from))
		else
			room:gainMaxHp(to,1,self:objectName())
		end
	end
	
	if to:isDead() then return end
	
	local hand = to:getHandcardNum()
	for _,p in sgs.qlist(room:getOtherPlayers(to))do
		if p:getHandcardNum() < hand then
			return
		end
	end
	to:drawCards(math.min(to:getMaxHp(),5),self:objectName())
end
}

tenyearyongdi = sgs.CreateZeroCardViewAsSkill{
name = "tenyearyongdi",
frequency = sgs.Skill_Limited,
limit_mark = "@tenyearyongdiMark",
view_as = function(self,card)
	return tenyearyongdiCard:clone()
end,
enabled_at_play = function(self,player)
	return player:getMark("@tenyearyongdiMark") > 0
end
}

tenyear_new_sp_jiaxu:addSkill("zhenlve")
tenyear_new_sp_jiaxu:addSkill(tenyearjianshu)
tenyear_new_sp_jiaxu:addSkill(tenyearyongdi)

--曹安民
caoanmin = sgs.General(tenyear_hc,"caoanmin","wei",4)

xianwei = sgs.CreateTriggerSkill{
name = "xianwei",
events = {sgs.EventPhaseStart,sgs.ThrowEquipArea},
frequency = sgs.Skill_Compulsory,
on_trigger = function(self,event,player,data,room)
	if event == sgs.EventPhaseStart then
		if player:getPhase() ~= sgs.Player_Start or not player:hasEquipArea() then return false end
		local choices = {}
		for i = 0,4 do
			if player:hasEquipArea(i) then
				table.insert(choices,i)
			end
		end
		if choices == "" then return false end
		room:sendCompulsoryTriggerLog(player,self)
		local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"))
		local area,draw = tonumber(choice),0
		player:throwEquipArea(area)
		for i = 0,4 do
			if player:hasEquipArea(i) then
				draw = draw + 1
			end
		end
		if draw > 0 then
			player:drawCards(draw,self:objectName())
		end
		if player:isDead() then return false end
		
		local use_id = -1
		for _,id in sgs.qlist(room:getDrawPile())do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("EquipCard") and card:getRealCard():toEquipCard():location() == area then
				use_id = id
				break
			end
		end
		
		--[[local sp = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if p:hasEquipArea(area) then
				sp:append(p)
			end
		end
		if sp:isEmpty() then return false end]]
		
		local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@xianwei-use")
		room:doAnimate(1,player:objectName(),to:objectName())
		if use_id >= 0 then
			local use_card = sgs.Sanguosha:getCard(use_id)
			if to:isAlive() and to:canUse(use_card,to,true) then
				room:useCard(sgs.CardUseStruct(use_card,to,to))
			end
		else
			to:drawCards(1,self:objectName())
		end
	else
		if player:hasEquipArea() then return false end
		local log = sgs.LogMessage()
		log.type = "#XianweiEquipArea"
		log.arg = self:objectName()
		log.from = player
		room:sendLog(log)
		player:peiyin(self)
		room:notifySkillInvoked(player,self:objectName())
		
		room:gainMaxHp(player,2,self:objectName())
		for _,p in sgs.qlist(room:getOtherPlayers(player,true))do
			room:insertAttackRangePair(player,p)
			room:insertAttackRangePair(p,player)
		end
	end
	return false
end
}

caoanmin:addSkill(xianwei)

--唐姬[二版]
second_tangji = sgs.General(tenyear_hc,"second_tangji","qun",3,false)

secondkangge = sgs.CreateTriggerSkill{
name = "secondkangge",
events = {sgs.EventPhaseStart,sgs.CardsMoveOneTime,sgs.Dying,sgs.Death},
on_trigger = function(self,event,player,data,room)
	if event == sgs.EventPhaseStart then
		if player:getPhase() ~= sgs.Player_RoundStart then return false end
		player:addMark("secondkangge_Round-Keep")
		if player:getMark("secondkangge_Round-Keep") ~= 1 then return false end
		local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@kangge-target",false,true)
		player:peiyin(self)
		room:setPlayerMark(target,"&secondkangge+#"..player:objectName(),1)
	elseif event == sgs.Dying then
		if player:getMark("secondkangge_lun") > 0 then return false end
		local dying = data:toDying()
		if dying.who:getMark("&secondkangge+#"..player:objectName()) <= 0 then return false end
		if not player:askForSkillInvoke(self,dying.who) then return false end
		player:peiyin(self)
		room:addPlayerMark(player,"secondkangge_lun")
		local recover_num = math.min(1 - dying.who:getHp(),dying.who:getMaxHp() - dying.who:getHp())
		room:recover(dying.who,sgs.RecoverStruct(self:objectName(),player,recover_num))
	elseif event == sgs.Death then
		local death = data:toDeath()
		if death.who:getMark("&secondkangge+#"..player:objectName()) <= 0 then return false end
		room:sendCompulsoryTriggerLog(player,self)
		player:throwAllHandCardsAndEquips(self:objectName())
		room:loseHp(sgs.HpLostStruct(player,1,"secondkangge",player))
	else
		if not room:hasCurrent() or player:getMark("secondkangge-Clear") > 2 then return false end
		local move = data:toMoveOneTime()
		if not move.to or move.to:getMark("&secondkangge+#"..player:objectName()) <= 0 or move.to:hasFlag("CurrentPlayer") then return false end
		if move.to_place ~= sgs.Player_PlaceHand then return false end
		local num = math.min(3 - player:getMark("secondkangge-Clear"),move.card_ids:length())
		if num <= 0 then return false end
		room:sendCompulsoryTriggerLog(player,self);
		room:addPlayerMark(player,"secondkangge-Clear",num)
		player:drawCards(num,self:objectName())
	end
	return false
end
}

secondjielie = sgs.CreateTriggerSkill{
name = "secondjielie",
events = sgs.DamageInflicted,
on_trigger = function(self,event,player,data,room)
	local damage = data:toDamage()
	if not damage.from or damage.from:objectName() == player:objectName() or damage.from:getMark("&secondkangge+#"..player:objectName()) > 0 then return false end
	if damage.damage <= 0 then return false end
	player:setTag("secondjielie_damage_data",data)
	local invoke = player:askForSkillInvoke(self,sgs.QVariant("secondjielie:"..damage.damage))
	player:removeTag("secondjielie_damage_data")
	if not invoke then return false end
	player:peiyin(self)
	
	local suit = room:askForSuit(player,self:objectName())
	local log = sgs.LogMessage()
	log.type = "#ChooseSuit"
	log.from = player
	log.arg = sgs.Card_Suit2String(suit)
	room:sendLog(log)
	room:loseHp(sgs.HpLostStruct(player,damage.damage,"secondjielie",player))
	
	for _,p in sgs.qlist(room:getAllPlayers())do
		if p:isDead() or p:getMark("&secondkangge+#"..player:objectName()) <= 0 then continue end
		local list = sgs.IntList()
		for _,id in sgs.qlist(room:getDiscardPile())do
            local card = sgs.Sanguosha:getCard(id)
            if card:getSuit() ~= suit then continue end
            list:append(id)
        end
		if not list:isEmpty() then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:deleteLater()
			for i = 1,damage.damage do
				if list:isEmpty() then break end
				local id = list:at(math.random(0,list:length() - 1))
				list:removeOne(id)
				slash:addSubcard(id)
			end
			if slash:subcardsLength() > 0 then
				room:obtainCard(p,slash)
			end
		end
	end
	return true
end
}

second_tangji:addSkill(secondkangge)
second_tangji:addSkill(secondjielie)

--南华老仙
nanhualaoxian = sgs.General(tenyear_hc,"nanhualaoxian","qun",4)

gongxiu = sgs.CreateTriggerSkill{
name = "gongxiu",
events = sgs.EventPhaseChanging,
on_trigger = function(self,event,player,data,room)
	if data:toPhaseChange().to ~= sgs.Player_NotActive then return false end
	if player:getMark("jinghe_Used-Clear") <= 0 then return false end
	
	local choices = {}
	for _,p in sgs.qlist(room:getAllPlayers())do
		if p:getMark("jinghe_GetSkill-Clear") > 0 then
			table.insert(choices,"draw")
			break
		end
	end
	for _,p in sgs.qlist(room:getOtherPlayers(player))do
		if p:getMark("jinghe_GetSkill-Clear") <= 0 and not p:isKongcheng() then
			table.insert(choices,"discard")
			break
		end
	end
	
	if #choices == 0 or not player:askForSkillInvoke(self) then return false end
	player:peiyin(self)
	local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"))
	if choice == "draw" then
		local sp = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAllPlayers())do
			if p:getMark("jinghe_GetSkill-Clear") > 0 then
				sp:append(p)
			end
		end
		if not sp:isEmpty() then
			room:drawCards(sp,1,self:objectName())
		end
	else
		for _,p in sgs.qlist(room:getOtherPlayers(player))do
			if p:isAlive() and p:getMark("jinghe_GetSkill-Clear") <= 0 and p:canDiscard(p,"h") then
				room:askForDiscard(p,self:objectName(),1,1)
			end
		end
	end
	return false
end
}

jingheCard = sgs.CreateSkillCard{
name = "jinghe",
will_throw = false,
handling_method = sgs.Card_MethodNone,
filter = function(self,targets,to_select)
	return #targets < self:subcardsLength()
end,
feasible = function(self,targets,player)
	return #targets == self:subcardsLength()
end,
on_use = function(self,room,source,targets)
	room:showCard(source,self:getSubcards())
	
	local tianshu_skills = {"tenyearleiji","biyue","nostuxi","mingce","zhiyan","nhyinbing","nhhuoqi","nhguizhu","nhxianshou","nhlundao","nhguanyue","nhyanzheng"}
	
	for _,p in ipairs(targets)do
		if p:isDead() then continue end
		local new_tianshu_skills = {}
		for _,sk in ipairs(tianshu_skills)do
			if p:hasSkill(sk,true) or not sgs.Sanguosha:getSkill(sk) then continue end
			table.insert(new_tianshu_skills,sk)
		end
		if #new_tianshu_skills <= 0 then continue end
		
		local skill = room:askForChoice(p,self:objectName(),table.concat(new_tianshu_skills,"+"))
		room:addPlayerMark(p,"jinghe_GetSkill-Clear")
		local skills = p:getTag("jinghe_GetSkills_"..source:objectName()):toString():split(",")
		if not table.contains(skills,skill) then
			table.insert(skills,skill)
			p:setTag("jinghe_GetSkills_"..source:objectName(),sgs.QVariant(table.concat(skills,",")))
		end
		room:acquireSkill(p,skill)
	end
end
}

jingheVS = sgs.CreateViewAsSkill{
name = "jinghe",
n = 4,
view_filter = function(self,selected,to_select)
	if to_select:isEquipped() or #selected > 3 then return false end
	for _,c in ipairs(selected)do
		if to_select:sameNameWith(c) then return false end
	end
	return true
end,
view_as = function(self,cards)
	if #cards == 0 then return nil end
	local c = jingheCard:clone()
	for i = 1,#cards do
		c:addSubcard(cards[i])
	end
	return c
end,
enabled_at_play = function(self,player)
	return player:getMark("jinghe_Used-Clear") <= 0
end
}

jinghe = sgs.CreateTriggerSkill{
name = "jinghe",
events = {sgs.PreCardUsed,sgs.EventPhaseStart,sgs.Death},
view_as_skill = jingheVS,
waked_skills = "tenyearleiji,biyue,nostuxi,mingce,zhiyan,nhyinbing,nhhuoqi,nhguizhu,nhxianshou,nhlundao,nhguanyue,nhyanzheng",
can_trigger = function(self,player)
	return player
end,
on_trigger = function(self,event,player,data,room)
	if event == sgs.PreCardUsed then
		local use = data:toCardUse()
		--if not use.card:isKindOf("jingheCard") or not room:hasCurrent() then return false end
		if not use.card:isKindOf("SkillCard") or use.card:objectName() ~= "jinghe" or not room:hasCurrent() then return false end
		room:addPlayerMark(use.from,"jinghe_Used-Clear")
	else
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_RoundStart then return false end
		elseif event == sgs.Death then
			local death = data:toDeath()
			local who = death.who
			if who:objectName() ~= player:objectName() then return false end
		end
		
		for _,p in sgs.qlist(room:getAllPlayers())do
			if p:isDead() then continue end
			local skills = p:getTag("jinghe_GetSkills_"..player:objectName()):toString():split(",")
			p:removeTag("jinghe_GetSkills_"..player:objectName())
			if #skills == 0 or skills[1] == "" then continue end
			local lose = {}
			for _,sk in ipairs(skills)do
				if p:hasSkill(sk,true) then
					table.insert(lose,"-"..sk)
				end
			end
			if #lose > 0 then
				room:handleAcquireDetachSkills(p,table.concat(lose,"|"))
			end
		end
	end
	return false
end
}

nanhualaoxian:addSkill(gongxiu)
nanhualaoxian:addSkill(jinghe)

nhyinbing = sgs.CreateTriggerSkill{
name = "nhyinbing",
events = {sgs.Predamage,sgs.HpLost},
frequency = sgs.Skill_Compulsory,
can_trigger = function(self,player)
	return player and player:isAlive()
end,
on_trigger = function(self,event,player,data,room)
	if event == sgs.Predamage then
		if not player:hasSkill(self) then return false end
		local damage = data:toDamage()
		if not damage.card or not damage.card:isKindOf("Slash") or damage.to:isDead() then return false end
		room:sendCompulsoryTriggerLog(player,self)
		room:loseHp(sgs.HpLostStruct(damage.to,damage.damage,"nhyinbing",player,damage.ignore_hujia))
		return true
	else
		--local sp = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAllPlayers())do
			if p:isDead() or not p:hasSkill(self) then return false end
			room:sendCompulsoryTriggerLog(p,self)
			p:drawCards(1,self:objectName())
		end
	end
	return false
end
}
tenyear_hc:addSkills(nhyinbing)

nhhuoqiCard = sgs.CreateSkillCard{
name = "nhhuoqi",
filter = function(self,targets,to_select,player)
	local hp = player:getHp()
	for _,p in sgs.qlist(player:getAliveSiblings())do
		hp = math.min(hp,p:getHp())
	end
	return #targets  == 0 and to_select:getHp() == hp
end,
on_effect = function(self,effect)
	local room,from,to = effect.from:getRoom(),effect.from,effect.to
	room:recover(to,sgs.RecoverStruct(self:objectName(),(from:isAlive() and from) or nil))
	to:drawCards(1,"nhhuoqi")
end
}

nhhuoqi = sgs.CreateOneCardViewAsSkill{
name = "nhhuoqi",
filter_pattern = ".!",
view_as = function(self,card)
	local c = nhhuoqiCard:clone()
	c:addSubcard(card)
	return c
end,
enabled_at_play = function(self,player)
	return not player:hasUsed("#nhhuoqi")
end
}
tenyear_hc:addSkills(nhhuoqi)

nhguizhu = sgs.CreateTriggerSkill{
name = "nhguizhu",
events = sgs.Dying,
frequency = sgs.Skill_Frequent,
on_trigger = function(self,event,player,data,room)
	if player:getMark("nhguizhu_Used-Clear") > 0 then return false end
	if not player:askForSkillInvoke(self) then return false end
	player:peiyin(self)
	player:addMark("nhguizhu_Used-Clear")
	player:drawCards(2,self:objectName())
	return false
end
}
tenyear_hc:addSkills(nhguizhu)

nhxianshouCard = sgs.CreateSkillCard{
name = "nhxianshou",
filter = function(self,targets,to_select,player)
	return #targets == 0
end,
on_effect = function(self,effect)
	local to,room = effect.to,effect.to:getRoom()
	local x = (to:getLostHp() > 0 and 1) or 2
	to:drawCards(x,self:objectName())
end
}

nhxianshou = sgs.CreateZeroCardViewAsSkill{
name = "nhxianshou",
view_as = function(self,card)
	return nhxianshouCard:clone()
end,
enabled_at_play = function(self,player)
	return not player:hasUsed("#nhxianshou")
end
}
tenyear_hc:addSkills(nhxianshou)

nhlundao = sgs.CreateMasochismSkill{
name = "nhlundao",
on_damaged = function(self,player,damage)
	local room,from = player:getRoom(),damage.from
	if not from or from:isDead() then return end
	local hand,fhand = player:getHandcardNum(),from:getHandcardNum()
	if fhand < hand then
		room:sendCompulsoryTriggerLog(player,self)
		player:drawCards(1,self:objectName())
		return
	end
	if fhand > hand and player:canDiscard(from,"he") then
		if not player:askForSkillInvoke(self,from) then return end
		player:peiyin(self)
		local id = room:askForCardChosen(player,from,"he",self:objectName(),false,sgs.Card_MethodDiscard)
		room:throwCard(id,from,player)
	end
end
}
tenyear_hc:addSkills(nhlundao)

nhguanyue = sgs.CreatePhaseChangeSkill{
name = "nhguanyue",
frequency = sgs.Skill_Frequent,
on_phasechange = function(self,player,room)
	if player:getPhase() ~= sgs.Player_Finish then return false end
	if not player:askForSkillInvoke(self) then return false end
	player:peiyin(self)
	
	local ids = room:getNCards(2)
	room:fillAG(ids,player)  --偷懒用AG
	local id = room:askForAG(player,ids,false,self:objectName())
	room:clearAG(player)
	ids:removeOne(id)
	room:obtainCard(player,id,false)
	room:returnToTopDrawPile(ids)
	return false
end
}
tenyear_hc:addSkills(nhguanyue)

nhyanzhengCard = sgs.CreateSkillCard{
name = "nhyanzheng",
filter = function(self,targets,to_select,player)
	return #targets < player:getMark("nhyanzheng-PlayClear")
end,
on_use = function(self,room,source,targets)
	local thread = room:getThread()
	for _,p in ipairs(targets)do
		if p:isDead() then continue end
		room:cardEffect(self,source,p)
		thread:delay()
	end
end,
on_effect = function(self,effect)
	local room = effect.from:getRoom()
	room:damage(sgs.DamageStruct("nhyanzheng",(effect.from:isAlive() and effect.from) or nil,effect.to))
end
}

nhyanzhengVS = sgs.CreateZeroCardViewAsSkill{
name = "nhyanzheng",
response_pattern = "@@nhyanzheng",
view_as = function(self,card)
	return nhyanzhengCard:clone()
end
}

nhyanzheng = sgs.CreatePhaseChangeSkill{
name = "nhyanzheng",
view_as_skill = nhyanzhengVS,
on_phasechange = function(self,player,room)
	if player:getPhase() ~= sgs.Player_Start or player:getHandcardNum() <= 1 then return false end
	local card = room:askForCard(player,".|.|.|hand","@nhyanzheng-keep",sgs.QVariant(),sgs.Card_MethodNone,nil,false,self:objectName())
	if not card then return false end
	
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	for _,c in sgs.qlist(player:getCards("he"))do
		if c:getEffectiveId() == card:getEffectiveId() or not player:canDiscard(player,c:getEffectiveId()) then continue end
		slash:addSubcard(c)
	end
	local num = slash:subcardsLength()
	if num == 0 then return false end
	
	room:throwCard(slash,player)
	if player:isDead() then return false end
	room:setPlayerMark(player,"nhyanzheng-PlayClear",num)
	room:askForUseCard(player,"@@nhyanzheng","@nhyanzheng:"..num,-1,sgs.Card_MethodNone)
	return false
end
}
tenyear_hc:addSkills(nhyanzheng)


tenyear_yuanyin = sgs.General(tenyear_hc, "tenyear_yuanyin", "qun", 3)
tenyearmoshou = sgs.CreateTriggerSkill{
	name = "tenyearmoshou",
	events = {sgs.TargetConfirmed},
	on_trigger = function(self, event, player, data, room)
		if event == sgs.TargetConfirmed then
		    local use = data:toCardUse()
			if use.card:isBlack() and use.to:contains(player) and use.card:getTypeId()>0 then
				if room:askForSkillInvoke(player, self:objectName()) then
					room:broadcastSkillInvoke(self:objectName())
					local n = player:getMark("&tenyearmoshou")
					if n<1 then
						n = player:getMaxHp()
						room:setPlayerMark(player, "&tenyearmoshou",n)
					end
					player:drawCards(n,self:objectName())
					room:removePlayerMark(player, "&tenyearmoshou")
				end
			end
		end
	end,
}
tenyearyunjiu = sgs.CreateTriggerSkill{
	name = "tenyearyunjiu",
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip))
			and move.from:isDead() and move.reason.m_skillName=="bury" then
				local ids = sgs.IntList()
				for _, id in sgs.qlist(move.card_ids) do
					if room:getCardOwner(id) then continue end
					ids:append(id)
				end
				if ids:isEmpty() then return end
				room:fillAG(ids, player)
				local target = room:askForPlayerChosen(player, room:getOtherPlayers(player), self:objectName(), "tenyearyunjiu0", true, true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					local id = room:askForAG(player, ids, false, self:objectName())
					room:clearAG(player)
					room:obtainCard(target, id)
					room:gainMaxHp(player,1,self:objectName())
					room:recover(player,sgs.RecoverStruct(self:objectName(),player))
					return
				end
				room:clearAG(player)
			end
		end
	end,
}
tenyear_yuanyin:addSkill(tenyearmoshou)
tenyear_yuanyin:addSkill(tenyearyunjiu)
sgs.LoadTranslationTable{
	["tenyear_yuanyin"] = "袁胤",
	["#tenyear_yuanyin"] = "载路素车",
	["designer:tenyear_yuanyin"] = "官方",
	["cv:tenyear_yuanyin"] = "官方",
	["illustrator:tenyear_yuanyin"] = "错落宇宙，匠人绘",
	["tenyearmoshou"] = "墨守",
	[":tenyearmoshou"] = "当你成为黑色牌的目标后，你可以依次执行以下所有项：1.若没有记录值或记录值小于1，将记录值调整为你的体力上限；2.摸记录值数张牌并令记录值-1。",
	["$tenyearmoshou1"] = "",
	["$tenyearmoshou2"] = "",
	["tenyearyunjiu"] = "运柩",
	[":tenyearyunjiu"] = "当其他角色死亡时，你可以将该角色弃置的任意一张牌交给另一名其他角色，然后你加1点体力上限并回复1点体力。",
	["tenyearyunjiu0"] = "你可以发动“运柩”选择一名其他角色将其中一张牌交给其",
	["$tenyearyunjiu1"] = "",
	["$tenyearyunjiu2"] = "",
	["~tenyear_yuanyin"] = "",
}


sgs.Sanguosha:setPackage(tenyear_hc)



local mobile_star = sgs.Sanguosha:getPackage("mobile_star")

--手杀星周不疑
kexing_zhoubuyi = sgs.General(mobile_star,"kexing_zhoubuyi","wei",3)
kehuiyaoCard = sgs.CreateSkillCard{
	name = "kehuiyaoCard",
	filter = function(self,targets,to_select,player)
		if #targets==1 then return targets[1]~=to_select end
		return #targets<1 and to_select~=player
	end,
	feasible = function(self,targets)
		return #targets>1
	end,
	about_to_use = function(self,room,use)
		room:setTag("kehuiyaoUse",ToData(use))
		use.to = sgs.SPlayerList()
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,player,targets)
		room:damage(sgs.DamageStruct("kehuiyao",nil,player))
		local use = room:getTag("kehuiyaoUse"):toCardUse()
		if use.to then
			room:doAnimate(1,player:objectName(),use.to:first():objectName())
			local log = sgs.LogMessage()
			log.type = "$kehuiyaolog"
			log.from = use.to:first()
			log.to:append(use.to:last())
			room:sendLog(log)
			local data = sgs.QVariant()
			data:setValue(sgs.DamageStruct("kehuiyao",use.to:first(),use.to:last()))
			room:getThread():delay()
			room:doAnimate(1,use.to:first():objectName(),use.to:last():objectName())
			room:getThread():trigger(sgs.Damage,room,use.to:first(),data)
			room:getThread():trigger(sgs.Damaged,room,use.to:last(),data)
		end
	end
}
kehuiyao = sgs.CreateViewAsSkill{
	name = "kehuiyao",
	n = 0,
	view_as = function(self,cards)
		return kehuiyaoCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#kehuiyaoCard")
	end
}
kexing_zhoubuyi:addSkill(kehuiyao)
kequesong = sgs.CreateTriggerSkill{
	name = "kequesong",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseStart,sgs.Damaged},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if (event == sgs.Damaged) then
			local damage = data:toDamage()
			if damage.to and damage.to:hasSkill(self:objectName()) then
				room:addPlayerMark(damage.to,"&kequesong-Clear")
			end
		end
		if (event == sgs.EventPhaseStart) then
			if (player:getPhase() == sgs.Player_Finish) then
				for _,zby in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
					if (zby:getMark("&kequesong-Clear") > 0) then
						local fri = room:askForPlayerChosen(zby,room:getAllPlayers(),self:objectName(),"kequesong-ask",true,true)
						if fri then
							room:broadcastSkillInvoke(self:objectName())
							if room:askForChoice(fri,self:objectName(),"draw+recover") == "draw" then
								if (fri:getCards("e"):length() > 2) then
									fri:drawCards(2,self:objectName())
								else
									fri:drawCards(3,self:objectName())
								end
							else
								room:recover(fri,sgs.RecoverStruct(self:objectName(),zby))
							end
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player~=nil
	end,
}
kexing_zhoubuyi:addSkill(kequesong)
sgs.LoadTranslationTable {
	["kexing_zhoubuyi"] = "星周不疑",
	["&kexing_zhoubuyi"] = "星周不疑",
	["#kexing_zhoubuyi"] = "稚雀清声",
	["designer:kexing_zhoubuyi"] = "官方",
	["cv:kexing_zhoubuyi"] = "官方",
	["illustrator:kexing_zhoubuyi"] = "官方",

	["kehuiyao"] = "慧夭",
	["kehuiyaoCard"] = "慧夭",
	[":kehuiyao"] = "出牌阶段限一次，你可以受到1点无来源的伤害，然后你令一名其他角色视为对其以外的一名角色造成过1点伤害。",
	["$kehuiyaolog"] = "%from 视为对 %to 造成过1点伤害！",

	["kequesong"] = "雀颂",
	[":kequesong"] = "一名角色的结束阶段，若你于此回合内受到过伤害，你可以令一名角色选择一项：摸三张牌（若其装备区牌数大于2，改为两张），或回复1点体力。",

	["kehuiyao-ask"] = "请选择视为造成伤害的 伤害来源",
	["kehuiyaotwo-ask"] = "请选择视为造成伤害的 受伤的角色",
	["kequesong-ask"] = "请选择发动“雀颂”的角色",

	["kequesong:draw"] = "摸牌",
	["kequesong:recover"] = "回复1点体力",

	["$kehuiyao2"] = "通悟而无笃学之念，则必盈天下之叹也。",
	["$kehuiyao1"] = "幸有仓舒为伴，吾不至居高寡寒。",
	["$kequesong2"] = "挽汉室于危亡，继光武之中兴！",
	["$kequesong1"] = "承白雀之瑞，显周公之德！",
	["~kexing_zhoubuyi"] = "慧童亡，天下伤。",

}

sgs.Sanguosha:setPackage(mobile_star)

local ol_qifu = sgs.Sanguosha:getPackage("ol_qifu")

keol_zhouchu = sgs.General(ol_qifu,"keol_zhouchu","jin",4)
local shanduanNum = {}
keolshanduan = sgs.CreateTriggerSkill{
	name = "keolshanduan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.DrawNCards,sgs.Damaged},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged and not player:hasFlag("CurrentPlayer") then
			local ns = player:getTag("shanduanNum"):toIntList()
			if ns:isEmpty() then
				for i=1,4 do
					ns:append(i)
				end
				player:setTag("shanduanNum",ToData(ns))
			end
			local nums = sgs.QList2Table(ns)
			room:sendCompulsoryTriggerLog(player,self)
			local function func(a,b)
				return a<b
			end
			table.sort(nums,func)
			local log = sgs.LogMessage()
			log.type = "$shanduanNum"
			log.from = player
			log.arg = nums[1]
			log.arg2 = nums[1]+1
			room:sendLog(log)
			ns:removeOne(nums[1])
			ns:append(nums[1]+1)
			player:setTag("shanduanNum",ToData(ns))
		elseif (event == sgs.DrawNCards) then
			local draw = data:toDraw()
			if draw.reason~="draw_phase" then return end
			draw.num = player:getMark("shanduanmp-Clear")
			data:setValue(draw)
		elseif (event == sgs.EventPhaseStart) then
			local ns = player:getTag("shanduanNum"):toIntList()
			if ns:isEmpty() then
				for i=1,4 do
					ns:append(i)
				end
				player:setTag("shanduanNum",ToData(ns))
				local Num = sgs.QList2Table(ns)
				local function func(a,b)
					return a<b
				end
				table.sort(Num,func)
				shanduanNum[player:objectName()] = Num
			end
			if (player:getPhase() == sgs.Player_Draw) then
				if #shanduanNum[player:objectName()]<1 then return end
				room:sendCompulsoryTriggerLog(player,self)
				local choice = room:askForChoice(player,"keolshanduanmpjd",table.concat(shanduanNum[player:objectName()],"+"))
				room:setPlayerMark(player,"shanduanmp-Clear",tonumber(choice))
				table.removeOne(shanduanNum[player:objectName()],tonumber(choice))
				local log = sgs.LogMessage()
				log.type = "$keolshanduanmpjd"
				log.from = player
				log.arg = choice
				room:sendLog(log)
			elseif (player:getPhase() == sgs.Player_Play) then
				if #shanduanNum[player:objectName()]<1 then return end
				local choices0 = {"keolshanduancpgjfw","keolshanduancpslash"}
				room:sendCompulsoryTriggerLog(player,self)
				while #choices0>0 do
					local choice0 = room:askForChoice(player,"keolshanduan",table.concat(choices0,"+"))
					table.removeOne(choices0,choice0)
					if #shanduanNum[player:objectName()]<1 then continue end
					local choice = room:askForChoice(player,choice0,table.concat(shanduanNum[player:objectName()],"+"))
					room:setPlayerMark(player,choice0.."-Clear",tonumber(choice))
					table.removeOne(shanduanNum[player:objectName()],tonumber(choice))
					room:addPlayerMark(player,choice0.."-PlayClear")
					local log = sgs.LogMessage()
					log.type = "$"..choice0
					log.from = player
					log.arg = choice
					room:sendLog(log)
				end
				choices0 = player:getMark("keolshanduancpslash-Clear")
				if choices0>0 then room:addSlashCishu(player,choices0-1) end
			elseif (player:getPhase() == sgs.Player_Discard) then
				if #shanduanNum[player:objectName()]<1 then return end
				room:sendCompulsoryTriggerLog(player,self)
				local choice = room:askForChoice(player,"keolshanduanspsx",table.concat(shanduanNum[player:objectName()],"+"))
				room:setPlayerMark(player,"shanduanqp-Clear",tonumber(choice))
				table.removeOne(shanduanNum[player:objectName()],tonumber(choice))
				room:addMaxCards(player,tonumber(choice)-player:getHp())
				local log = sgs.LogMessage()
				log.type = "$keolshanduanspsx"
				log.from = player
				log.arg = choice
				room:sendLog(log)
			elseif (player:getPhase() == sgs.Player_NotActive) then
				ns = sgs.IntList()
				for i=1,4 do
					ns:append(i)
				end
				player:setTag("shanduanNum",ToData(ns))
			elseif (player:getPhase() == sgs.Player_RoundStart) then
				local Num = sgs.QList2Table(ns)
				local function func(a,b)
					return a<b
				end
				table.sort(Num,func)
				shanduanNum[player:objectName()] = Num
			end
		end
	end,
}
keol_zhouchu:addSkill(keolshanduan)
keolyilieCard = sgs.CreateSkillCard{
	name = "keolyilieCard",
	will_throw = false,
	mute = true,
	filter = function(self,targets,to_select,user)
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card,user_str = nil,self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetFilter(plist,to_select,user)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return false
		end
		local card = user:getTag("keolyilie"):toCard()
		return card and card:targetFilter(plist,to_select,user)
	end,
	feasible = function(self,targets,user)
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local card,user_str = nil,self:getUserString()
			if user_str ~= "" then
				local us = user_str:split("+")
				card = sgs.Sanguosha:cloneCard(us[1])
			end
			return card and card:targetsFeasible(plist,user)
		elseif sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			return true
		end
		local card = user:getTag("keolyilie"):toCard()
		return card and card:targetsFeasible(plist,user)
	end,
	on_validate = function(self,card_use)
		local player = card_use.from
		local room,to_keolyilie = player:getRoom(),self:getUserString()
		if self:getUserString() == "slash"
		and sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			local keolyilie_list = {}
			table.insert(keolyilie_list,"slash")
			table.insert(keolyilie_list,"fire_slash")
			table.insert(keolyilie_list,"thunder_slash")
			table.insert(keolyilie_list,"ice_slash")
			to_keolyilie = room:askForChoice(player,"keolyilie_slash",table.concat(keolyilie_list,"+"))
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_keolyilie == "slash" then
			--if card and card:isKindOf("Slash")and not (card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash") or card:isKindOf("IceSlash")) then
			if card and card:objectName() == "slash" then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		else
			user_str = to_keolyilie
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str)
		use_card:setSkillName("keolyilie")
		use_card:addSubcards(self:getSubcards())
		use_card:deleteLater()
		return use_card
	end,
	on_validate_in_response = function(self,user)
		local room,user_str = user:getRoom(),self:getUserString()
		local to_keolyilie
		if user_str == "peach+analeptic" then
			local keolyilie_list = {}
			table.insert(keolyilie_list,"peach")
			table.insert(keolyilie_list,"analeptic")
			to_keolyilie = room:askForChoice(user,"keolyilie_saveself",table.concat(keolyilie_list,"+"))
		elseif user_str == "slash" then
			local keolyilie_list = {}
			table.insert(keolyilie_list,"slash")
			table.insert(keolyilie_list,"fire_slash")
			table.insert(keolyilie_list,"thunder_slash")
			table.insert(keolyilie_list,"ice_slash")
			to_keolyilie = room:askForChoice(user,"keolyilie_slash",table.concat(keolyilie_list,"+"))
		else
			to_keolyilie = user_str
		end
		local card = nil
		if self:subcardsLength() == 1 then card = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self:getSubcards():first())) end
		local user_str
		if to_keolyilie == "slash" then
			if card and card:objectName() == "slash" then
			--if card and card:isKindOf("Slash") and not (card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash") or card:isKindOf("IceSlash"))then
				user_str = card:objectName()
			else
				user_str = "slash"
			end
		else
			user_str = to_keolyilie
		end
		local use_card = sgs.Sanguosha:cloneCard(user_str)
		use_card:addSubcards(self:getSubcards())
		use_card:setSkillName("keolyilie")
		use_card:deleteLater()
		return use_card
	end,
}
keolyilieVS = sgs.CreateViewAsSkill{
	name = "keolyilie",
	n = 2,
	response_or_use = true,
	view_filter = function(self,selected,to_select)
		if to_select:isEquipped() then return false  end
		if #selected>0 then
			return to_select:getColor() == selected[1]:getColor()
		end
		return #selected<1
	end,
	view_as = function(self,cards)
		if #cards ~= 2 then return nil end
		--local sc = keolyilieCard:clone()
		--sc:setSkillName(self:objectName())
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			local sc = sgs.Sanguosha:cloneCard(pattern:split("+")[1])
			sc:setSkillName(self:objectName())
			sc:setFlags(self:objectName())
			for _,card in ipairs(cards)do
				sc:addSubcard(card)
			end
			return sc
		end
		local c = sgs.Self:getTag("keolyilie"):toCard()
		if c then
			local sc = sgs.Sanguosha:cloneCard(c:objectName())
			sc:setSkillName(self:objectName())
			sc:setFlags(self:objectName())
			for _,card in ipairs(cards)do
				sc:addSubcard(card)
			end
			return sc
		end
	end,
	enabled_at_play = function(self,player)
		if player:getHandcardNum()<2 then return end
		for _,patt in ipairs(patterns())do
			local dc = dummyCard(patt)
			if dc and player:getMark("keolyilie_guhuo_remove_"..patt)<1 and dc:isKindOf("BasicCard") then
				dc:setSkillName(self:objectName())
				if dc:isAvailable(player)
				then return true end
			end
		end
	end,
	enabled_at_response = function(self,player,pattern)
		if player:getHandcardNum()<2 then return end
		for _,pt in sgs.list(pattern:split("+"))do
			local dc = dummyCard(pt)
			if dc and dc:isKindOf("BasicCard")
			and player:getMark("keolyilie_guhuo_remove_"..pt)<1 then
				return true
			end
		end
	end,
}
keolyilie = sgs.CreateTriggerSkill{
	name = "keolyilie",
	view_as_skill = keolyilieVS,
	events = {sgs.CardUsed,sgs.RoundEnd},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.CardUsed) then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) or use.card:hasFlag(self:objectName())
			then room:addPlayerMark(player,"keolyilie_guhuo_remove_"..use.card:objectName()) end
		else
			for _,m in sgs.list(player:getMarkNames())do
				if m:startsWith("keolyilie_guhuo_remove_")
				then room:setPlayerMark(player,m,0) end
			end
		end
	end,
}
keolyilie:setGuhuoDialog("l")
keol_zhouchu:addSkill(keolyilie)
sgs.LoadTranslationTable {
	["keol_zhouchu"] = "周处[OL]",
	["&keol_zhouchu"] = "周处",
	["#keol_zhouchu"] = "忠烈果毅",
	["designer:keol_zhouchu"] = "官方",
	["cv:keol_zhouchu"] = "官方",
	["illustrator:keol_zhouchu"] = "官方",

	["keolshanduan"] = "善断",
	["keolshanduandamage"] = "善断伤害",
	[":keolshanduan"] = "锁定技，摸牌/出牌/弃牌阶段开始时，你将本回合的摸牌数/攻击范围和【杀】的次数限制/手牌上限的默认值改为你从1、2、3和4中选择的本回合未以此法选择过的数值；当你于回合外受到伤害后，你令选择中的最小值+1（最多加至9），直到你下回合结束。",
	["$keolshanduanmpjd"] = "%from 的摸牌数默认值改为 %arg !",
	["$keolshanduancpslash"] = "%from 的【杀】的次数限制默认值改为 %arg !",
	["$keolshanduancpgjfw"] = "%from 的攻击范围默认值改为 %arg !",
	["$keolshanduanspsx"] = "%from 的手牌上限默认值改为 %arg !",
	["$shanduanNum"] = "%from 的最小点数 %arg +1变成 %arg2 !",
	["keolyilie"] = "义烈",
	[":keolyilie"] = "你可以将两张颜色相同的手牌当本轮未以此法使用过的基本牌使用或打出。",

	["keolshanduanmpjd"] = "摸牌数默认值",
	["keolshanduancpgjfw"] = "攻击范围默认值",
	["keolshanduancpslash"] = "【杀】次数限制默认值",
	["keolshanduanspsx"] = "手牌上限默认值",

	["keolyilie_slash"] = "义烈",
	["keolyilie_saveself"] = "义烈",

	["$keolshanduan1"] = "浪子回头，其期未晚矣。",
	["$keolshanduan2"] = "心既存蛟虎，秉慧剑斩之。",
	["$keolyilie1"] = "从来天下义，只在青山中。",
	["$keolyilie2"] = "沥血染征袍，英名万古存。",
	["~keol_zhouchu"] = "死战死谏，死亦可乎！",

}

nyol_feiyi = sgs.General(ol_qifu,"nyol_feiyi","shu",3,true,false,false)
ny_ol_yanru = sgs.CreateViewAsSkill{
	name = "ny_ol_yanru",
	n = 999,
	view_filter = function(self,selected,to_select)
		local num = sgs.Self:getHandcardNum()
		if num % 2 == 1 then return false end
		return not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		local num = sgs.Self:getHandcardNum()
		if num % 2 == 1 then
			return ny_ol_yanruCard:clone()
		else
			if #cards >= (num / 2) then
				local cc = ny_ol_yanruCard:clone()
				for _,card in ipairs(cards)do
					cc:addSubcard(card)
				end
				return cc
			end
		end
	end,
	enabled_at_play = function(self,player)
		local num = player:getHandcardNum()
		if num % 2 == 1 then
			return player:getMark("ny_ol_yanru_odd-PlayClear")<1
		else
			return player:getMark("ny_ol_yanru_even-PlayClear")<1
		end
	end,
}
ny_ol_yanruCard = sgs.CreateSkillCard{
	name = "ny_ol_yanruCard",
	target_fixed = true,
	--will_throw = false,
	about_to_use = function(self,room,use)
		local num = use.from:getHandcardNum()
		if num % 2 == 1 then
			room:addPlayerMark(use.from,"ny_ol_yanru_odd-PlayClear")
			use.from:setFlags("ny_ol_yanru_odd")
		else
			room:addPlayerMark(use.from,"ny_ol_yanru_even-PlayClear")			
		end
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,player,targets)
		player:drawCards(3,self:getSkillName())
		if player:hasFlag("ny_ol_yanru_odd") then
			player:setFlags("-ny_ol_yanru_odd")
			local num = math.floor(player:getHandcardNum()/2)
			if num>0 then
				room:askForDiscard(player,self:getSkillName(),999,num,false,false,"@ny_ol_yanru:"..num)
			end
		end
	end,
}
ny_ol_hezhong = sgs.CreateTriggerSkill{
	name = "ny_ol_hezhong",
	events = {sgs.CardsMoveOneTime,sgs.CardUsed,sgs.CardFinished},
	frequency = sgs.Skill_NotFrequent,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			if player:isDead() then return false end
			if player:getHandcardNum() ~= 1 then return false end
			if player:getMark("ny_ol_hezhong_up_used-Clear") > 0
			and player:getMark("ny_ol_hezhong_down_used-Clear") > 0 then return false end

			local move = data:toMoveOneTime()
			if (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand))
			or (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand) then else return false end

			local card = player:getHandcards():at(0)
			local choices = {}
			local prompt
			if player:getMark("ny_ol_hezhong_up_used-Clear") == 0 then
				table.insert(choices,"up="..card:getNumber())
				prompt = string.format("show:%s::%s:","ny_ol_hezhong_up",card:getNumber())
			end
			if player:getMark("ny_ol_hezhong_down_used-Clear") == 0 then
				table.insert(choices,"down="..card:getNumber())
				prompt = string.format("show:%s::%s:","ny_ol_hezhong_down",card:getNumber())
			end
			if #choices > 1 then prompt = string.format("show:%s::%s:","ny_ol_hezhong_all",card:getNumber()) end

			if player:askForSkillInvoke(self,sgs.QVariant(prompt)) then
				room:broadcastSkillInvoke(self:objectName())
				room:showCard(player,card:getEffectiveId())
				player:drawCards(1,self:objectName())

				if player:isAlive() then
					local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"),sgs.QVariant(card:getNumber()))
					if string.find(choice,"up") then
						room:setPlayerMark(player,"ny_ol_hezhong_up_used-Clear",1)
						room:setPlayerMark(player,"&ny_ol_hezhong_up_mark-Clear",card:getNumber())
					else
						room:setPlayerMark(player,"ny_ol_hezhong_down_used-Clear",1)
						room:setPlayerMark(player,"&ny_ol_hezhong_down_mark-Clear",card:getNumber())
					end
				end
			end
		end
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card and use.card:isNDTrick() then
				local n = 0
				if player:getMark("ny_ol_hezhong_up_used-Clear")>0
				and use.card:getNumber() > player:getMark("&ny_ol_hezhong_up_mark-Clear") 
				and player:getMark("&ny_ol_hezhong_up_mark-Clear") > 0 then
					room:addPlayerMark(player,"ny_ol_hezhong_up_used-Clear",1)
					room:setPlayerMark(player,"&ny_ol_hezhong_up_mark-Clear",0)
					n = n + 1
				end
				if player:getMark("ny_ol_hezhong_down_used-Clear")>0
				and use.card:getNumber() < player:getMark("&ny_ol_hezhong_down_mark-Clear") then
					room:addPlayerMark(player,"ny_ol_hezhong_down_used-Clear",1)
					room:setPlayerMark(player,"&ny_ol_hezhong_down_mark-Clear",0)
					n = n + 1
				end
				if n > 0 then
					room:sendCompulsoryTriggerLog(player,self)
					local log = sgs.LogMessage()
					log.type = "$ny_ol_hezhong_more"
					log.card_str = use.card:toString()
					log.arg = n
					room:sendLog(log)
					room:setCardFlag(use.card,"ny_ol_hezhong")
					use.card:setTag("ny_ol_hezhong",sgs.QVariant(n))
				end
			end
		end
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isNDTrick() and use.card:getTag("ny_ol_hezhong") then
				local n = use.card:getTag("ny_ol_hezhong"):toInt()
				if n > 0 then
					for i = 1,n do
						if player:isDead() then break end
						local use2 = sgs.CardUseStruct(use.card,player,use.to)
						room:setTag("UseHistory"..use.card:toString(),ToData(use2))
						use.card:use(room,player,use.to)
					end
				end
			end
		end
	end,
}
nyol_feiyi:addSkill(ny_ol_yanru)
nyol_feiyi:addSkill(ny_ol_hezhong)

sgs.LoadTranslationTable {
	["nyol_feiyi"] = "费祎[OL]",
	["&nyol_feiyi"] = "费祎",
	["#nyol_feiyi"] = "中才之相",
	["designer:nyol_feiyi"] = "官方",
	["cv:nyol_feiyi"] = "官方",
	["illustrator:nyol_feiyi"] = "君桓文化",

	["ny_ol_yanru"] = "晏如",
	[":ny_ol_yanru"] = "<font color='green'><b>出牌阶段各限一次，</b></font>若你的手牌数为：奇数，你可以摸三张牌并弃置至少一半手牌；偶数，你可以弃置至少一半手牌并摸三张牌。",
	["@ny_ol_yanru"] = "请弃置至少 %src 张手牌",
	["ny_ol_hezhong"] = "和衷",
	[":ny_ol_hezhong"] = "<font color='green'><b>每回合各限一次，</b></font>当你的手牌数变为1后，你可以展示手牌并摸一张牌，然后你令本回合使用的下一张点数大于或小于此牌点数的普通锦囊牌多结算一次。",
	["ny_ol_hezhong:show"] = "你可以发动“和衷”展示手牌并摸一张牌，然后令你本回合使用的下一张 %src 点数 %arg 的普通锦囊牌额外结算一次",
	["ny_ol_hezhong_up"] = "大于",
	["ny_ol_hezhong_down"] = "小于",
	["ny_ol_hezhong_all"] = "大于/小于",
	["ny_ol_hezhong:up"] = "下一张点数大于 %src 的普通锦囊牌牌额外结算一次",
	["ny_ol_hezhong:down"] = "下一张点数小于 %src 的普通锦囊牌牌额外结算一次",
	["ny_ol_hezhong_up_mark"] = "和衷大于",
	[":&ny_ol_hezhong_up_mark"] = "下一张点数大于 %src 的普通锦囊牌牌额外结算一次",
	["ny_ol_hezhong_down_mark"] = "和衷小于",
	[":&ny_ol_hezhong_down_mark"] = "下一张点数小于 %src 的普通锦囊牌牌额外结算一次",
	["$ny_ol_hezhong_more"] = "%card 将额外结算 %arg 次",

	["$ny_ol_yanru1"] = "国有宁日，民有丰年，大同也。",
	["$ny_ol_yanru2"] = "及臻厥成，天下晏如也。",
	["$ny_ol_hezhong1"] = "家和而万事兴，国亦如是。",
	["$ny_ol_hezhong2"] = "你我同殿为臣，理当协力同心。",
	["~nyol_feiyi"] = "今为小人所伤，皆酒醉之误……",
}

--与君化木 曹宪&曹华
--设计者：
caoxiancaohua = sgs.General(ol_qifu,"caoxiancaohua","qun",3,false)
--代码改自群友上传
--化木
huamu = sgs.CreateTriggerSkill{
	name = "huamu",
	events = {sgs.CardFinished},
	--frequency = sgs.Skill_Frequent,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId()<1 then return end
			local cs = player:getMark("&huamu+"..use.card:getColorString().."-Clear")
			local can = false
			for _,m in sgs.list(player:getMarkNames())do
				if m:startsWith("&huamu+")
				and player:getMark(m)>0 then
					room:setPlayerMark(player,m,0)
					can = true
				end
			end
			room:setPlayerMark(player,"&huamu+"..use.card:getColorString().."-Clear",1)
			if cs<1 and can and use.m_isHandcard
			and room:getCardOwner(use.card:getEffectiveId())==nil then
				if use.card:isRed() and player:askForSkillInvoke(self) then
					room:broadcastSkillInvoke(self:objectName(),math.random(3,4)) --播放配音
					player:addToPile("ercao_yushu",use.card,true)
				elseif use.card:isBlack() and player:askForSkillInvoke(self) then
					room:broadcastSkillInvoke(self:objectName(),math.random(1,2)) --播放配音
					player:addToPile("ercao_lingshan",use.card,true)
				end
			end
		end
	end
}
caoxiancaohua:addSkill(huamu)
--前盟
qianmeng = sgs.CreateTriggerSkill{
	name = "qianmeng",
	events = {sgs.CardsMoveOneTime},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if not room:getTag("FirstRound"):toBool() then
				local source
				if table.contains(move.from_pile_names,"ercao_yushu")
				or table.contains(move.from_pile_names,"ercao_lingshan")
				then source = move.from
				elseif move.to_pile_name == "ercao_yushu"
				or move.to_pile_name == "ercao_lingshan"
				then source = move.to end
				if source and (source:getPile("ercao_yushu"):isEmpty() or source:getPile("ercao_lingshan"):isEmpty() or source:getPile("ercao_yushu"):length() == source:getPile("ercao_lingshan"):length())
				then
					room:sendCompulsoryTriggerLog(player,self) --显示锁定技发动
					player:drawCards(1,self:objectName())
				end
			end
		end
	end
}
caoxiancaohua:addSkill(qianmeng)
--良缘
function canLyUse(from,cn)
	local ct ={analeptic="ercao_lingshan",peach="ercao_yushu"}
	local dc = dummyCard(cn)
	dc:setSkillName("liangyuan")
	for _,id in sgs.qlist(from:getPile(ct[cn]))do
		dc:addSubcard(id)
	end
	for _,p in sgs.qlist(from:getAliveSiblings())do
		for _,id in sgs.qlist(p:getPile(ct[cn]))do
			dc:addSubcard(id)
		end
	end
	if dc:subcardsLength()>0 and not from:isLocked(dc)
	and from:getMark(cn.."liangyuan_lun")<1
	then return dc end
end
liangyuanCard = sgs.CreateSkillCard{
	name = "liangyuanCard",
	will_throw = false,
	target_fixed = true,
	on_validate_in_response = function(self,from)
		local choice = {}
		local us = self:getUserString()
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY
		then
			for _,pc in ipairs({"peach","analeptic"})do
				local dc = canLyUse(from,pc)
				if dc and dc:isAvailable(from)
				then table.insert(choice,pc) end
			end
		else
			for _,pc in ipairs(us:split("+"))do
				local dc = canLyUse(from,pc)
				if dc then table.insert(choice,pc) end
			end
		end
		if #choice<1 then return nil end
		local room = from:getRoom()
		choice = room:askForChoice(from,"liangyuan",table.concat(choice,"+"))
		us = choice=="analeptic" and "ercao_lingshan" or "ercao_yushu"
		room:addPlayerMark(from,choice.."liangyuan_lun")
		local c = dummyCard(choice)
		c:setSkillName("liangyuan")
		for _,id in sgs.qlist(from:getPile(us))do
			c:addSubcard(id)
		end
		for _,p in sgs.qlist(from:getAliveSiblings())do
			for _,id in sgs.qlist(p:getPile(us))do
				c:addSubcard(id)
			end
		end
		return c
	end,
	on_validate = function(self,use)
		local choice = {}
		local us = self:getUserString()
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY
		then
			for _,pc in ipairs({"peach","analeptic"})do
				local dc = canLyUse(use.from,pc)
				if dc and dc:isAvailable(use.from)
				then table.insert(choice,pc) end
			end
		else
			for _,pc in ipairs(us:split("+"))do
				local dc = canLyUse(use.from,pc)
				if dc then table.insert(choice,pc) end
			end
		end
		if #choice<1 then return nil end
		local room = use.from:getRoom()
		choice = room:askForChoice(use.from,"liangyuan",table.concat(choice,"+"))
		us = choice=="analeptic" and "ercao_lingshan" or "ercao_yushu"
		room:addPlayerMark(use.from,choice.."liangyuan_lun")
		local c = dummyCard(choice)
		c:setSkillName("liangyuan")
		for _,id in sgs.qlist(use.from:getPile(us))do
			c:addSubcard(id)
		end
		for _,p in sgs.qlist(use.from:getAliveSiblings())do
			for _,id in sgs.qlist(p:getPile(us))do
				c:addSubcard(id)
			end
		end
		return c
	end,
}
liangyuanvs = sgs.CreateViewAsSkill{
	name = "liangyuan",
	view_as = function(self,cards)
		local new = liangyuanCard:clone()
		new:setUserString(sgs.Sanguosha:getCurrentCardUsePattern())
		return new
	end,
	enabled_at_play = function(self,player)	--自由时点
		local dc = canLyUse(player,"analeptic")
		if dc and dc:isAvailable(player)
		then return true end
		dc = canLyUse(player,"peach")
		if dc and dc:isAvailable(player)
		then return true end
	end,
	enabled_at_response = function(self,player,pattern)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return false end
		if string.find(pattern,"analeptic") then
			local dc = canLyUse(player,"analeptic")
			if dc then return true end
		end
		if string.find(pattern,"peach") then
			local dc = canLyUse(player,"peach")
			if dc then return true end
		end
	end
}
caoxiancaohua:addSkill(liangyuanvs)
--羁肆
jisi = sgs.CreateTriggerSkill{
	name = "jisi",
	frequency = sgs.Skill_Limited,
	events = {sgs.EventPhaseStart,sgs.PreCardUsed,sgs.ChoiceMade},
	limit_mark = "@jisi",
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart
		and player:getPhase() == sgs.Player_Start
		and player:getMark("@jisi")>0
		and player:hasSkill(self) then
			local choices = {}
			local general = player:getGeneral()
			for _,sk in sgs.qlist(general:getVisibleSkillList())do
				if player:getMark(sk:objectName().."jisiUse")>0
				then table.insert(choices,sk:objectName()) end
			end
			general = player:getGeneral2()
			if general then
				for _,sk in sgs.qlist(general:getVisibleSkillList())do
					if player:getMark(sk:objectName().."jisiUse")>0
					then table.insert(choices,sk:objectName()) end
				end
			end
			if #choices<1 then return false end
			local choices2 = {}
			for _,sk in sgs.list(choices)do
				table.insert(choices2,sgs.Sanguosha:translate(sk))
			end
			player:setTag("jisi_invoke",ToData(table.concat(choices,"+")))
			sgs.Sanguosha:addTranslationEntry("jisi_invoke","你可以令一名其他角色获得你武将牌上一个发动过的技能，然后你弃置所有手牌并视为对其使用【杀】"..
				"\n可选技能："..table.concat(choices2,","))
			local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"jisi_invoke:",true,true)
			if to then
				room:removePlayerMark(player,"@jisi")
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox(player,self:objectName())
				local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"),data)
				room:acquireSkill(to,choice)
				player:throwAllHandCards(self:objectName())
				local new_card = dummyCard()
				new_card:setSkillName("_jisi")
				if to:isAlive() and player:canSlash(to,new_card,false) then
					room:useCard(sgs.CardUseStruct(new_card,player,to))
				end
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:getSkillName()~="" then
				room:addPlayerMark(player,use.card:getSkillName().."jisiUse")
			end
		elseif event == sgs.ChoiceMade then
			local struct = data:toString()
			if struct=="" then return end
			local promptlist = struct:split(":")
			if #promptlist<2 or promptlist[1]~="notifyInvoked" then return end
			room:addPlayerMark(player,promptlist[2].."jisiUse")
		end
	end
}
caoxiancaohua:addSkill(jisi)
sgs.LoadTranslationTable{
	["caoxiancaohua"] = "曹宪&曹华",
	["&caoxiancaohua"] = "曹宪曹华",
	["#caoxiancaohua"] = "与君化木",
	["designer:caoxiancaohua"] = "玄蝶既白",
	["cv:caoxiancaohua"] = "官方",
	["illustrator:caoxiancaohua"] = "官方",
	["~caoxiancaohua"] = "爱恨有泪，聚散无常。",

	["huamu"] = "化木",
	[":huamu"] = "你使用手牌结算结束后，若此牌与本回合内被使用的上一张牌颜色不同，你可以将之置于你的武将牌上，黑色牌称为“灵杉”，红色牌称为“玉树”。",
	["$huamu1"] = "左杉右树，可共余生。",
	["$huamu2"] = "夫君，当与妾共越此人间之阶！",
	["$huamu3"] = "山重水复，心有灵犀。",
	["$huamu4"] = "灵之来兮如云。",
	["$huamu5"] = "一树樱桃带雨红。",
	["$huamu6"] = "四月寻春花更香。",
	["huamu:choice"] = "你可以发动“化木”，将你使用的 %src 作为 %dest 置于武将牌上",
	["ercao_yushu"] = "玉树",
	["ercao_lingshan"] = "灵杉",

	["qianmeng"] = "前盟",
	[":qianmeng"] = "锁定技，当一名角色的“灵杉”或“玉树”数量变化后，若两者相等或有一项为0，你摸一张牌。",
	["$qianmeng1"] = "前盟已断，杉树长别。",
	["$qianmeng2"] = "苍山有灵，杉树相依。",

	["liangyuan"] = "良缘",
	[":liangyuan"] = "每轮各限一次，你可以将场上所有“灵杉”当【酒】使用，或将场上所有“玉树”当【桃】使用。",
	["$liangyuan1"] = "千古奇遇，共剪西窗。",
	["$liangyuan2"] = "金玉良缘，来日方长。",

	["jisi"] = "羁肆",
	["@jisi"] = "羁肆",
	[":jisi"] = "限定技，准备阶段，你可以令一名其他角色获得你武将牌上发动过的一个技能，然后弃置所有手牌并视为对其使用一张【杀】。 ",
	["$jisi1"] = "被褐怀玉，天放不羁。",
	["$jisi2"] = "心若野马，不系璇台。",
}
sgs.Sanguosha:setPackage(ol_qifu)
















local ol_mou = sgs.Sanguosha:getPackage("ol_mou")

keolmou_jiangwei = sgs.General(ol_mou,"keolmou_jiangwei","shu",4)
keolzhuriVS = sgs.CreateOneCardViewAsSkill{
	name = "keolzhuri",
	expand_pile = "#keolzhuri",
	response_pattern = "@@keolzhuri",
	view_filter = function(self,to_select)
		return to_select:isAvailable(sgs.Self)
		and sgs.Self:getPile("#keolzhuri"):contains(to_select:getEffectiveId())
	end,
	view_as = function(self,card)
		return card
	end
}
keolzhuri = sgs.CreateTriggerSkill{
	name = "keolzhuri",
	view_as_skill = keolzhuriVS,
	waked_skills = "#keolzhuriEffect",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardsMoveOneTime and player:getPhase() ~= sgs.Player_NotActive then
			local move = data:toMoveOneTime()
			if (move.from and move.from:objectName() == player:objectName() and move.from_places:contains(sgs.Player_PlaceHand))
			or (move.to and move.to:objectName() == player:objectName() and move.to_place == sgs.Player_PlaceHand) then
				room:setPlayerMark(player,"keolzhuri_changed",1)
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() ~= sgs.Player_NotActive
			and player:getPhase() ~= sgs.Player_RoundStart
			and player:getMark("keolzhuri_changed") > 0
			and player:getMark("keolzhuri_lose")<1 then
				local targets = sgs.SPlayerList()
				for _,p in sgs.list(room:getOtherPlayers(player))do
					if player:canPindian(p) then targets:append(p) end
				end
				local target = room:askForPlayerChosen(player,targets,self:objectName(),"@keolzhuri_choose",true,true)
				if target then
					room:broadcastSkillInvoke(self:objectName())
					local pd = player:PinDian(target,self:objectName())
					if pd.success then
						local ids = sgs.IntList()
						ids:append(pd.from_card:getEffectiveId())
						ids:append(pd.to_card:getEffectiveId())
						room:notifyMoveToPile(player,ids,self:objectName(),sgs.Player_DiscardPile,true)
						local card = room:askForUseCard(player,"@@keolzhuri","@keolzhuri_use")
						room:notifyMoveToPile(player,ids,self:objectName(),sgs.Player_DiscardPile,false)
					else
						if room:askForChoice(player,self:objectName(),"hp+skill") == "hp" then
							room:loseHp(player,1,true,player,self:objectName())
						else
							room:addPlayerMark(player,"keolzhuri_lose-Clear")
							room:detachSkillFromPlayer(player,"keolzhuri")
						end
					end
				end
			end
			room:setPlayerMark(player,"keolzhuri_changed",0)
		end
	end
}
keolzhuriEffect = sgs.CreateTriggerSkill{
	name = "#keolzhuriEffect",
	frequency = sgs.Skill_Compulsory,
	events = sgs.EventPhaseChanging,
	on_trigger = function(self,event,player,data,room)
		local change = data:toPhaseChange()
		if change.to ~= sgs.Player_NotActive then return false end
		for _,p in sgs.list(room:getAlivePlayers())do
			if p:getMark("keolzhuri_lose-Clear") > 0 then
				room:sendCompulsoryTriggerLog(p,"keolzhuri")
				room:acquireSkill(p,"keolzhuri")
			end
		end
	end,
}
keolranji = sgs.CreateTriggerSkill{
	name = "keolranji",
	frequency = sgs.Skill_Limited,
	limit_mark = "@keolranji",
	waked_skills = "zhaxiang,kunfen",
	events = {sgs.EventPhaseStart,sgs.CardUsed,sgs.PreHpRecover,sgs.Death},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart then
			room:setPlayerFlag(player,"-keolranji_used")
			if player:getMark("@keolranji") == 0 or player:getPhase() ~= sgs.Player_Finish then return false end
			local skills,string = {},nil
			if player:getMark("keolranji_used-Clear") >= player:getHp() then table.insert(skills,"kunfen") end
			if player:getMark("keolranji_used-Clear") <= player:getHp() then table.insert(skills,"zhaxiang") end
			if #skills == 1 then string = "keolranji1:" end
			if #skills == 2 then string = "keolranji2:" end
			if player:askForSkillInvoke(self,sgs.QVariant(string..table.concat(skills,":"))) then
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox(player,"keolranji")
				room:removePlayerMark(player,"@keolranji")
				if table.contains(skills,"kunfen") then
					room:acquireSkill(player,"kunfen")
					room:addPlayerMark(player,"fengliang")
				end
				if table.contains(skills,"zhaxiang") then
					room:acquireSkill(player,"zhaxiang")
				end
				local choices = {}
				if player:isWounded() then table.insert(choices,"recover") end
				if player:getHandcardNum() < player:getMaxHp() then table.insert(choices,"draw") end
				if #choices ~= 0 then
					local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"))
					if choice == "recover" then
						room:recover(player,sgs.RecoverStruct(self:objectName(),player,player:getMaxHp() - player:getHp()))
					else
						room:drawCards(player,player:getMaxHp() - player:getHandcardNum(),self:objectName())
					end
				end
				room:setPlayerMark(player,"&keolranji_ban",1)
			end
		elseif event == sgs.CardUsed then
			if not player:hasFlag("keolranji_used") then
				room:setPlayerFlag(player,"keolranji_used")
				room:addPlayerMark(player,"keolranji_used-Clear")
			end
		elseif event == sgs.PreHpRecover then
			local recover = data:toRecover()
			if (player:getMark("&keolranji_ban")<1) then return end
			local log = sgs.LogMessage()
			log.type = "$keolranji_msg"
			log.from = player
			room:sendLog(log)
			room:setEmotion(player,"judgebad");
			return true
		else
			local death = data:toDeath()
			if death.who:objectName() == player:objectName() then return false end
			if death.damage and death.damage.from:objectName() == player:objectName()
			then room:setPlayerMark(player,"&keolranji_ban",0) end
		end
	end
}
keolmou_jiangwei:addSkill(keolzhuri)
keolmou_jiangwei:addSkill(keolzhuriEffect)
keolmou_jiangwei:addSkill(keolranji)
sgs.Sanguosha:setAudioType("keolmou_jiangwei","zhaxiang","3,4")
sgs.LoadTranslationTable {

	["keolmou_jiangwei"] = "谋姜维[OL]",
	["&keolmou_jiangwei"] = "谋姜维",
	["#keolmou_jiangwei"] = "炎志灼心",
	["designer:keolmou_jiangwei"] = "官方",
	["illustrator:keolmou_jiangwei"] = "官方",
	["cv:keolmou_jiangwei"] = "官方",
	["keolzhuri"] = "逐日",
	["#keolzhuri"] = "拼点牌",
	["keolzhuri:hp"] = "失去1点体力",
	["keolzhuri:skill"] = "失去本技能直到回合结束",
	["@keolzhuri_choose"] = "你可以与一名其他角色拼点",
	["@keolzhuri_use"] = "你可以使用一张拼点牌",
	[":keolzhuri"] = "你的阶段结束时，若你本阶段手牌数变化过，你可以拼点：若你赢，你可以使用一张拼点牌；若你没赢，你失去1点体力或失去“逐日”直到回合结束。",
	["keolranji"] = "燃己",
	["keolranji_ban"] = "禁止回复",
	["keolranji:keolranji1"] = "你可以发动“燃己”获得“%src”",
	["keolranji:keolranji2"] = "你可以发动“燃己”获得“%src”和“%dest”",
	["keolranji:recover"] = "将体力值调整至体力上限",
	["keolranji:draw"] = "将手牌数调整至体力上限",
	["$keolranji_msg"] = "%from 由于“<font color='yellow'><b>燃己</b></font>”的效果，不能回复体力值",
	[":keolranji"] = "限定技，结束阶段，若你本回合使用过牌的阶段数：不小于体力值，你可以获得“困奋”（升级）；不大于体力值，你可以获得“诈降”。若如此做，你将手牌数或体力值调整至上限，然后防止你回复体力直到你杀死角色。",

	["$keolzhuri1"] = "效逐日之夸父，怀忠志而长存。",
	["$keolzhuri2"] = "知天命而不顺，履穷途而强为。",
	["$keolranji1"] = "此身为薪，炬成灰亦照大汉长明。",
	["$keolranji2"] = "维之一腔骨血，可驱驰来北马否？",
	["$zhaxiang3"] = "亡国之将姜维，请明公驱驰。",
	["$kunfen3"] = "虽千万人！吾往矣。",

	["~keolmou_jiangwei"] = "姜维，又将何为……",
}

--谋袁绍
keolmou_yuanshao = sgs.General(ol_mou,"keolmou_yuanshao$","qun",4)
keolhetao = sgs.CreateTriggerSkill{
    name = "keolhetao",
    events = {sgs.TargetSpecified,sgs.CardFinished},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self,event,player,data)
        local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("keolhetaodoubleflag") then
				for _,p in sgs.qlist(use.to)do
					if (p:getMark("keolhetaodouble") > 0) then
						local tos = sgs.SPlayerList()
						tos:append(p)
						for i = 1,p:getMark("keolhetaodouble")do
							use.card:use(room,use.from,tos)
						end
						room:setPlayerMark(p,"keolhetaodouble",0)
					end
				end
			end
		elseif (event == sgs.TargetSpecified) then
			local use = data:toCardUse()
			if (use.to:length() <= 1) or use.card:isKindOf("SkillCard") then return false end
			for _,ys in sgs.qlist(room:getOtherPlayers(use.from))do
				ys:setTag("keolhetao",data)
				if ys:hasSkill(self)
				and room:askForDiscard(ys,"keolhetao",1,1,true,true,"keolhetaoreddis",".|"..use.card:getColorString(),"keolhetao") then
					room:broadcastSkillInvoke(self:objectName())
					local eny = room:askForPlayerChosen(ys,use.to,self:objectName(),"keolhetao-ask")
					if eny then
						room:doAnimate(1,ys:objectName(),eny:objectName())
						local nullified_list = use.nullified_list
						for _,p in sgs.qlist(use.to)do
							if (p:objectName() ~= eny:objectName()) then
								table.insert(nullified_list,p:objectName())
							end
						end
						use.nullified_list = nullified_list
						data:setValue(use)
						room:setCardFlag(use.card,"keolhetaodoubleflag")
						room:addPlayerMark(eny,"keolhetaodouble")
					end
				end
			end
		end
    end,
    can_trigger = function(self,target)
        return target~=nil
    end,
}
keolmou_yuanshao:addSkill(keolhetao)
keolshenli = sgs.CreateTriggerSkill{
    name = "keolshenli",
    events = {sgs.TargetSpecifying,sgs.CardFinished,sgs.Damage},
    frequency = sgs.Skill_NotFrequent,
    on_trigger = function(self,event,player,data)
        local room = player:getRoom()
		if (event == sgs.CardFinished) then
			local use = data:toCardUse()
			if use.card:hasFlag("keolshenlicard") then
				room:setCardFlag(use.card,"-keolshenlicard")
				local danum = room:getTag("keolshenlida"):toInt()
				room:removeTag("keolshenlida")
				if (danum > use.from:getHandcardNum()) then
					use.from:drawCards(math.min(5,danum),self:objectName())
				end
				if (danum > use.from:getHp()) then
					--room:doLightbox("image=image/animate/keolshenlipic.png",4500)
					room:useCard(sgs.CardUseStruct(use.card,player,use.to),false)
				end
			end
		elseif (event == sgs.Damage) then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("keolshenlicard") then
				local num = room:getTag("keolshenlida"):toInt() + damage.damage
				room:setTag("keolshenlida",sgs.QVariant(num))
			end
		elseif (event == sgs.TargetSpecifying) then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash")
			and player:getPhase() == sgs.Player_Play
			and player:getMark("bankeolshenli-PlayClear")<1
			and player:askForSkillInvoke(self,data) then
				room:broadcastSkillInvoke(self:objectName())
				room:addPlayerMark(player,"bankeolshenli-PlayClear")
				room:setCardFlag(use.card,"keolshenlicard")
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if (not use.to:contains(p)) and player:canSlash(p,use.card,false) then
						room:doAnimate(1,player:objectName(),p:objectName())
						use.to:append(p)
					end
				end
				room:sortByActionOrder(use.to)
				data:setValue(use)
			end
		end
    end,
}
keolmou_yuanshao:addSkill(keolshenli)
--思召剑
keolsizhaojianskill = sgs.CreateTriggerSkill{
	name = "_keolsizhaojian",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecified then
			if use.card:isKindOf("Slash") and use.from==player
			and player:hasWeapon("_keolsizhaojian") then
				local n = use.card:getNumber()
				if n<1 then return end
				room:sendCompulsoryTriggerLog(player,self:objectName())
				room:setCardFlag(use.card,"Sizhaojian")
				room:setEmotion(player,"weapon/_keolsizhaojian")
				for _,p in sgs.qlist(use.to)do
					room:setPlayerMark(p,"Sizhaojian-Clear",n)
				end
				data:setValue(use)
			end
		elseif event == sgs.CardFinished and use.card:hasFlag("Sizhaojian") then
			for _,p in sgs.qlist(room:getAllPlayers())do
				room:setPlayerMark(p,"Sizhaojian-Clear",0)
			end
		end
	end,
	can_trigger = function(self,player)
		return player~=nil
	end,
}
Keolsizhaojian = sgs.CreateWeapon{
	name = "_keolsizhaojian",
	class_name = "Sizhaojian",
	range = 2,
	suit = 2,
	number = 6,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,keolsizhaojianskill,true,true,false)
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"keolsizhaojianskill",true,true)
	end,
}
Keolsizhaojian:setParent(exclusive_cards)
ol_mou:addSkills(keolsizhaojianskill)
Keolsizhaojianex = sgs.CreateCardLimitSkill{
	name = "Keolsizhaojianex",
	limit_list = function(self,player)
		return "use,response"
	end,
	limit_pattern = function(self,player)
		if player:getMark("Sizhaojian-Clear") > 0
		then return "Jink|.|1~"..player:getMark("Sizhaojian-Clear") end
		return ""
	end
}
ol_mou:addSkills(Keolsizhaojianex)
keolyufeng = sgs.CreateTriggerSkill{
    name = "keolyufeng",
    events = {sgs.GameStart},
	waked_skills = "_keolsizhaojian",
    frequency = sgs.Skill_Frequent,
    on_trigger = function(self,event,player,data)
        local room = player:getRoom()
		if (event == sgs.GameStart) then
			if player:getWeapon() == nil then
				for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
					local thecard = sgs.Sanguosha:getCard(id)
					if thecard:isKindOf("Sizhaojian") then
						room:sendCompulsoryTriggerLog(player,self)
						room:moveCardTo(thecard,player,sgs.Player_PlaceEquip)
						break
					end
				end
			end
		end
    end,
}
keolmou_yuanshao:addSkill(keolyufeng)
keolshishou = sgs.CreateTriggerSkill{
	name = "keolshishou$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceEquip)
		and move.from:objectName() ~= player:objectName()
		and move.from:getKingdom() == "qun"
		and player:hasLordSkill(self)
		and player:getWeapon()==nil then
			local from = BeMan(room,move.from)
			if from:askForSkillInvoke(self,ToData(player),false) then
				room:doAnimate(1,move.from:objectName(),player:objectName())
				from:skillInvoked(self:objectName(),-1,player)
				for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
					local thecard = sgs.Sanguosha:getCard(id)
					if thecard:isKindOf("Sizhaojian") then
						room:moveCardTo(thecard,player,sgs.Player_PlaceEquip)
						break
					end
				end
			end
		end
	end,
}
keolmou_yuanshao:addSkill(keolshishou)
sgs.LoadTranslationTable {
	["keolmou_yuanshao"] = "谋袁绍[OL]",
	["&keolmou_yuanshao"] = "谋袁绍",
	["#keolmou_yuanshao"] = "义军盟主",
	["designer:keolmou_yuanshao"] = "官方",
	["cv:keolmou_yuanshao"] = "官方",
	["illustrator:keolmou_yuanshao"] = "官方",

	["keolhetao"] = "合讨",
	[":keolhetao"] = "当其他角色使用牌指定至少两名目标后，你可以弃置一张同颜色的牌并选择其中一名目标角色，令此牌对其余目标角色无效，然后此牌结算完毕后，该角色额外执行一次结算。",
	["keolhetaoreddis"] = "你可以发动“合讨”弃置一张与该牌同颜色的牌",
	["keolhetaoblackdis"] = "你可以发动“合讨”弃置一张与该牌同颜色的牌",
	["keolhetaoblack"] = "合讨",
	["keolhetaored"] = "合讨",

	["keolhetao-ask"] = "请选择发动“合讨”的角色",

	["keolshenli"] = "神离",
	[":keolshenli"] = "出牌阶段限一次，当你使用【杀】指定目标时，你可以将目标改为所有其他角色，此【杀】结算完毕后，若此【杀】造成的总伤害值：大于你的手牌数，你摸X张牌（X为此伤害值且至多为5）；大于你的体力值，你对目标角色再次使用此【杀】。",

	["_keolsizhaojian"] = "思召剑",
	[":_keolsizhaojian"] = "装备牌/武器<br/><b>攻击范围</b>：2\
	<b>武器技能</b>：锁定技，当你使用【杀】指定目标后，目标角色不能使用或打出点数小于此【杀】的【闪】直到此【杀】结算完毕。",

	["keolyufeng"] = "玉锋",
	[":keolyufeng"] = "<font color='green'><b>游戏开始时，</b></font>若你的装备区没有武器牌，你将【思召剑】置入你的装备区。",

	["keolshishou"] = "士首",
	[":keolshishou"] = "主公技，其他群势力角色失去装备区的牌后，若你的装备区没有武器牌，其可以将【思召剑】置入你的装备区。",

	["$keolhetao1"] = "合诸侯之群力，扶大汉之将倾。",
	["$keolhetao2"] = "猛虎啸于山野，群士执戈相待。",
	["$keolshenli1"] = "沧海之水难覆，将倾之厦难扶。",
	["$keolshenli2"] = "诸君心怀苟且，安能并力西向？",
	["$keolyufeng1"] = "梦神人授剑，怀神兵济世。",
	["$keolyufeng2"] = "",
	["$keolshishou1"] = "今执牛耳，当为天下之先。",
	["$keolshishou2"] = "士者不徒手而战，况其首乎。",

	["~keolmou_yuanshao"] = "众人合而无力，徒负大义也。",
}


--谋太史慈[OL]
keolmou_taishici = sgs.General(ol_mou,"keolmou_taishici","wu",4,true)

keoldulie = sgs.CreateTriggerSkill{
	name = "keoldulie",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetConfirming,sgs.CardFinished},
	can_trigger = function(self,target)
		return target
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event==sgs.CardFinished then
			if use.card:hasFlag("keoldulieBf") then
				room:removeTag("UseHistory"..use.card:toString())
				use.card:use(room,use.from,use.to)
			end
		else
			if use.from and use.from ~= player and use.to:contains(player) and use.to:length() == 1
			and player:hasSkill(self) and (use.card:isKindOf("BasicCard") or use.card:isNDTrick()) then
				if player:getMark("keoldulie-Clear")<1 and room:askForSkillInvoke(player,self:objectName(),data) then
					room:addPlayerMark(player,"keoldulie-Clear")
					room:broadcastSkillInvoke(self:objectName())
					room:setCardFlag(use.card,"keoldulieBf")
					local ar = math.min(player:getAttackRange(),5)
					room:drawCards(player,ar,self:objectName())
				end
			end
		end
	end,
}
keolmou_taishici:addSkill(keoldulie)

keoldouchan = sgs.CreateTriggerSkill{
	name = "keoldouchan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player,self:objectName())
			room:broadcastSkillInvoke(self:objectName())
			local duels = {}
			for _,id in sgs.qlist(room:getDrawPile())do
				local cd = sgs.Sanguosha:getCard(id)
				if cd:isKindOf("Duel") then
					table.insert(duels,cd)
				end
			end
			if #duels > 0 then
				local duel = duels[math.random(1,#duels)]
				room:obtainCard(player,duel)
			else
				local n = player:getMark("&"..self:objectName())
				if n < room:getPlayers():length() then
					room:addPlayerMark(player,"&"..self:objectName())
				end
			end
		end
	end,
}
keolmou_taishici:addSkill(keoldouchan)

--谋关羽[OL]
keolmou_guanyu = sgs.General(ol_mou,"keolmou_guanyu","shu")
keolweilin_red = sgs.CreateFilterSkill{
	name = "keolweilin_red&",
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return to_select:isRed() and to_select:hasFlag("keolweilin") and place == sgs.Player_PlaceHand
	end,
	view_as = function(self,originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash",originalCard:getSuit(),originalCard:getNumber())
		slash:setSkillName("keolweilin")
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end,
}
keolweilin_black = sgs.CreateFilterSkill{
	name = "keolweilin_black&",
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return not to_select:isRed() and to_select:hasFlag("keolweilin") and place == sgs.Player_PlaceHand
	end,
	view_as = function(self,originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash",originalCard:getSuit(),originalCard:getNumber())
		slash:setSkillName("keolweilin")
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end,
}
keolweilinCard = sgs.CreateSkillCard{
	name = "keolweilin",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,source)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("_"..self:objectName())
		slash:deleteLater()
		return source:canSlash(to_select,slash,false)
	end,
	feasible = function(self,targets)
		return #targets >= 0
	end,
	on_use = function(self,room,source,targets)
	    local target = nil
		if targets[1] then target = targets[1]
		else target = source end
		if target then
			if sgs.Sanguosha:getCard(self:getSubcards():first()):isRed() then
			    room:attachSkillToPlayer(target,"keolweilin_red")
			    for _,card in sgs.qlist(target:getHandcards())do
				    if card:isRed() then
						--[[room:setPlayerFlag(target,"keolweilin")
						room:moveCardTo(card,nil,sgs.Player_PlaceTable)
						room:setPlayerFlag(target,"-keolweilin")
						room:moveCardTo(card,target,sgs.Player_PlaceHand)]]
						room:setCardFlag(card,"keolweilin")
						room:filterCards(target,target:getCards("h"),true)
					end
				end
			else
			    room:attachSkillToPlayer(target,"keolweilin_black")
			    for _,card in sgs.qlist(target:getHandcards())do
				    if not card:isRed() then
						--[[room:setPlayerFlag(target,"keolweilin")
						room:moveCardTo(card,nil,sgs.Player_PlaceTable)
						room:setPlayerFlag(target,"-keolweilin")
						room:moveCardTo(card,target,sgs.Player_PlaceHand)]]
						room:setCardFlag(card,"keolweilin")
						room:filterCards(target,target:getCards("h"),true)
					end
				end
		    end
		end
		if targets[1] and targets[1]:objectName() ~= source:objectName() then
			local card = sgs.Sanguosha:getCard(self:getSubcards():first())
			local choices = {}
			for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards())do
				local cd = sgs.Sanguosha:getEngineCard(id)
				if not cd:isKindOf("Slash") or table.contains(choices,cd:objectName()) then continue end
				table.insert(choices,cd:objectName())
			end
			--local choice = room:askForChoice(source,self:objectName(),"normal_slash+fire_slash+thunder_slash+ice_slash")
			local choice = room:askForChoice(source,self:objectName(),table.concat(choices,"+"))
		    local slash = sgs.Sanguosha:cloneCard(choice,card:getSuit(),card:getNumber())
			slash:setSkillName("_"..self:objectName())
			slash:addSubcard(self:getSubcards():first())
			room:useCard(sgs.CardUseStruct(slash,source,targets[1]))
			slash:deleteLater()
		else
		    local slash = sgs.Sanguosha:cloneCard("analeptic",card:getSuit(),card:getNumber())
			slash:setSkillName("_"..self:objectName())
			slash:addSubcard(self:getSubcards():first())
			room:useCard(sgs.CardUseStruct(slash,source,source))
			slash:deleteLater()
		end
		room:addPlayerMark(source,"keolweilin-Clear")
	end,
}
keolweilinvs = sgs.CreateViewAsSkill{
    name = "keolweilin",
	n = 1,
	response_or_use = false,
	view_filter = function(self,selected,to_select)
		return true
	end,
    view_as = function(self,cards)
		if #cards > 0 then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern=="" then
				local dc = sgs.Self:getTag("keolweilin")
				if dc==nil then return end
				pattern = dc:toCard():objectName()
			end
			if string.find(pattern,"analeptic") then pattern = "analeptic" end
			local sc = sgs.Sanguosha:cloneCard(pattern)--keolweilinCard:clone()
			sc:setSkillName(self:objectName())
			for _,c in ipairs(cards)do
				sc:addSubcard(c)
			end
			return sc
		end
    end,
    enabled_at_play = function(self,player)
	    return player:getMark("keolweilin-Clear") == 0
		and (sgs.Slash_IsAvailable(player) or sgs.Analeptic_IsAvailable(player))
    end,
	enabled_at_response = function(self,player,pattern)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
		or player:getMark("keolweilin-Clear")>0 then return false end
		return pattern == "slash" or string.find(pattern,"analeptic")
	end,
}
keolweilin = sgs.CreateTriggerSkill{
	name = "keolweilin",
	events = {sgs.EventPhaseChanging,sgs.CardUsed},
	view_as_skill = keolweilinvs,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			for _,p in sgs.qlist(room:getAlivePlayers())do
				local hw = sgs.CardList()
				for _,c in sgs.qlist(p:getHandcards())do
					if c:getSkillName()==self:objectName() then
						hw:append(c)
					end
				end
				room:filterCards(p,hw,true)
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and table.contains(use.card:getSkillNames(),self:objectName()) then
				room:addPlayerMark(player,"keolweilin-Clear")
				for _,p in sgs.qlist(use.to)do
					for _,h in sgs.qlist(p:getHandcards())do
						if h:getColor()==use.card:getColor() then
							local toc = sgs.Sanguosha:cloneCard("slash",h:getSuit(),h:getNumber())
							toc:setSkillName("keolweilin")
							local wrap = sgs.Sanguosha:getWrappedCard(h:getEffectiveId())
							wrap:takeOver(toc)
							room:notifyUpdateCard(player,h:getEffectiveId(),wrap)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target
	end,
}
keolweilin:setJuguanDialog("all_slashs,analeptic")
keolduoshou = sgs.CreateTriggerSkill{
    name = "keolduoshou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damage,sgs.CardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damage then
			if player:getMark("keolduoshou_damage-Clear") == 0 then
		    	room:sendCompulsoryTriggerLog(player,self)
				room:addPlayerMark(player,"keolduoshou_damage-Clear")
				player:drawCards(1,self:objectName())
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			local has = false
			if use.card:isRed() and player:getMark("keolduoshou_red-Clear") == 0 then
		    	room:sendCompulsoryTriggerLog(player,self)
				room:addPlayerMark(player,"keolduoshou_red-Clear")
				has = true
			end
			if use.card:isKindOf("BasicCard") and player:getMark("keolduoshou_basic-Clear") == 0 then
		    	if has==false then room:sendCompulsoryTriggerLog(player,self) end
				room:addPlayerMark(player,"keolduoshou_basic-Clear")
				use.m_addHistory = false
				data:setValue(use)
			end
		end
	end,
}
keolmou_guanyu:addSkill(keolweilin)
keolmou_guanyu:addSkill(keolduoshou)

olmou_sunjian = sgs.General(ol_mou,"olmou_sunjian","wu",5,true,false,false,4)
olmouhulie = sgs.CreateTriggerSkill{
	name = "olmouhulie",
	events = {sgs.TargetSpecified,sgs.CardFinished,sgs.ConfirmDamage},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.TargetSpecified then
		    local use = data:toCardUse()
			if (use.card:isKindOf("Duel") or use.card:isKindOf("Slash")) and use.to:length() == 1
			and player:getMark("olmouhulie"..use.card:objectName().."-Clear") < 1
			and player:askForSkillInvoke(self,data) then
				player:addMark("olmouhulie"..use.card:objectName().."-Clear")
				room:broadcastSkillInvoke(self:objectName())
				room:setCardFlag(use.card,self:objectName())
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag(self:objectName()) then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				player:damageRevises(data,1)
			end
		elseif event == sgs.CardFinished then
		    local use = data:toCardUse()
			if use.card:hasFlag(self:objectName()) and not use.card:hasFlag("DamageDone") then
				local targets = sgs.SPlayerList()
				local slash = dummyCard()
				slash:setSkillName("_"..self:objectName())
                for _,p in sgs.qlist(room:getAlivePlayers())do
                    if use.to:contains(p) and p:canSlash(player,slash,false) then
                        targets:append(p)
                    end
                end
				local target = room:askForPlayerChosen(player,targets,self:objectName(),"olmouhulie0",true,false)
				if target then
					room:useCard(sgs.CardUseStruct(slash,target,player))
                end
			end
		end
	end
}
olmouyipo = sgs.CreateTriggerSkill{
	name = "olmouyipo",
	events = {sgs.HpChanged},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getHp() > 0 and player:getMark(self:objectName().."+"..player:getHp()) < 1 then
			local dest = room:askForPlayerChosen(player,room:getAllPlayers(),self:objectName(),"olmouyipo-invoke",true,true)
            if dest then
				room:broadcastSkillInvoke(self:objectName())
				local x = math.max(1,player:getLostHp())
				local choice = room:askForChoice(player,self:objectName(),"dxt1="..x.."+d1tx="..x,ToData(dest))
			    if choice:match("d1tx") then
				    dest:drawCards(1,self:objectName())
				    room:askForDiscard(dest,self:objectName(),x,x,false,true)
			    else
				    dest:drawCards(x,self:objectName())
				    room:askForDiscard(dest,self:objectName(),1,1,false,true)
			    end
				room:setPlayerMark(player,self:objectName().."+"..player:getHp(),1)
			end
		end
	end,
}
olmou_sunjian:addSkill(olmouhulie)
olmou_sunjian:addSkill(olmouyipo)
sgs.LoadTranslationTable{
	["olmou_sunjian"] = "谋孙坚[OL]",
	["&olmou_sunjian"] = "谋孙坚",
	["#olmou_sunjian"] = "刚毅冠中夏",
	["illustrator:olmou_sunjian"] = "官方",
	["olmouhulie"] = "虎烈",
	[":olmouhulie"] = "每回合各限一次，你使用【杀】或【决斗】仅指定一名角色为目标后，你可令此牌伤害+1。若此牌未造成伤害，你可令目标角色视为对你使用一张【杀】。",
	["olmouhulie0"] = "虎烈：你可以令其视为对你使用一张【杀】",
	["$olmouhulie1"] = "匹夫犯我，吾必斩之！",
	["$olmouhulie2"] = "鼠辈！这一刀下去，定让你看不到明天的太阳",
	["olmouyipo"] = "毅魄",
	[":olmouyipo"] = "你的体力值变化后，若当前体力值大于0且为你首次达到，你可以选择一名角色并选择一项：1.令其摸X张牌，然后弃置一张牌；2.令其摸一张牌，然后弃置X张牌。（X为你已损失体力值且至少为1）。",
    ["olmouyipo-invoke"] = "你可以发动“毅魄”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["d1tx"] = "令其摸一张牌，然后弃置%src张牌",
	["dxt1"] = "令其摸%src张牌，然后弃置一张牌",
	["$olmouyipo1"] = "乱臣贼子，天地不容！",
	["$olmouyipo2"] = "年少束发从羽林，纵死不改报国志！",
	["$olmouyipo3"] = "身既死兮神以灵，魂魄毅兮为鬼雄！",
	["~olmou_sunjian"] = "江东子弟们，我…先走一步了……",
}

olmou_gongsunzan = sgs.General(ol_mou, "olmou_gongsunzan", "qun", 4)
olmoujiaodi = sgs.CreateTriggerSkill{
	name = "olmoujiaodi", 
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecifying, sgs.ConfirmDamage}, 
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and use.to:length() == 1 then
				room:sendCompulsoryTriggerLog(player, self)
				for _, p in sgs.qlist(use.to) do
					if p:getAttackRange() <= player:getAttackRange() then
					    room:setCardFlag(use.card, "olmoujiaodi"..p:objectName())
					end
					if p:getAttackRange() >= player:getAttackRange() and player:canDiscard(p,"he") then
					    room:throwCard(room:askForCardChosen(player, p, "he", self:objectName()), p, player)
						local players = sgs.SPlayerList()
			            for _, p in sgs.qlist(room:getOtherPlayers(player)) do
					        if use.to:contains(p) or player:isProhibited(p,use.card)
							then continue end
							players:append(p)
			            end
						player:setTag("JincanmouData",data)
						local to = room:askForPlayerChosen(player, players, self:objectName(), "olmoujiaodi0")
                        if to then
							room:doAnimate(1,player:objectName(),to:objectName())
							use.to:append(to)
							room:sortByActionOrder(use.to)
							data:setValue(use)
						end
					end
				end
			end
		else
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("olmoujiaodi"..damage.to:objectName()) then
				room:setCardFlag(damage.card, "-olmoujiaodi"..damage.to:objectName())
				player:damageRevises(data,1)
			end
		end
		return false
	end,
}
olmoubaojingCard = sgs.CreateSkillCard{
	name = "olmoubaojingCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self, targets, to_select,source)
		return #targets == 0 and to_select~=source
	end,
	on_use = function(self, room, source, targets)
		source:addMark("olmoubaojingUse")
		local choices = "1"
		if targets[1]:getAttackRange() > 1 then
			choices = "1+2"
		end
		if room:askForChoice(source, self:getSkillName(), choices) == "1" then
		    if targets[1]:getMark("&olmoubaojing_remove") > 0 then
		        room:removePlayerMark(targets[1], "&olmoubaojing_remove")
			else
				room:addPlayerMark(targets[1], "&olmoubaojing_add")
			end
		else
		    if targets[1]:getMark("&olmoubaojing_add") > 0 then
		        room:removePlayerMark(targets[1], "&olmoubaojing_add")
			else
				room:addPlayerMark(targets[1], "&olmoubaojing_remove")
			end
		end
	end
}
olmoubaojingvs = sgs.CreateZeroCardViewAsSkill{
	name = "olmoubaojing",
	view_as = function(self, cards)
		return olmoubaojingCard:clone()
	end,
	enabled_at_play = function(self, player)
		return not player:hasUsed("#olmoubaojingCard")
	end,
}
olmoubaojing = sgs.CreateTriggerSkill{
	name = "olmoubaojing",
	events = {sgs.EventPhaseChanging,sgs.Death},
	view_as_skill = olmoubaojingvs,
	can_trigger = function(self,player)
		return player and player:getMark("olmoubaojingUse")>0
	end,
	on_trigger = function(self, event, player, data)
		local room = player:getRoom()
		if event==sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Play then
				player:setMark("olmoubaojingUse",0)
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "&olmoubaojing_remove", 0)
					room:setPlayerMark(p, "&olmoubaojing_add", 0)
				end
			end
		else
			local death = data:toDeath()
			if death.who==player then
				for _,p in sgs.qlist(room:getAlivePlayers()) do
					room:setPlayerMark(p, "&olmoubaojing_remove", 0)
					room:setPlayerMark(p, "&olmoubaojing_add", 0)
				end
			end
		end
	end,
}
olmou_gongsunzan:addSkill(olmoujiaodi)
olmou_gongsunzan:addSkill(olmoubaojing)
sgs.LoadTranslationTable{
	["#olmou_gongsunzan"] = "白马将军",
	["olmou_gongsunzan"] = "谋公孙瓒[OL]",
	["&olmou_gongsunzan"] = "谋公孙瓒",
	["illustrator:olmou_gongsunzan"] = "Vincent",
	["olmoujiaodi"] = "剿狄",
    [":olmoujiaodi"] = "锁定技，你的攻击范围使用等于你的当前体力值。当你使用【杀】指定唯一目标时，若目标的攻击范围不大于你，你令此【杀】伤害+1；若目标的攻击范围不小于你，你弃置目标区域内一张牌，选择一名角色成为此【杀】的额外目标。",
	["olmoujiaodi0"] = "剿狄：请选择此【杀】额外一名目标",
    ["olmoubaojing"] = "保京",
	["olmoubaojing:1"] = "攻击范围+1",
	["olmoubaojing:2"] = "攻击范围-1",
	["olmoubaojing_add"] = "攻击范围+1",
	["olmoubaojing_remove"] = "攻击范围-1",
    [":olmoubaojing"] = "出牌阶段限一次，你可令一名其他角色的攻击范围+1/-1（最多减为1），直到你的下个出牌阶段开始。",
}

sgs.Sanguosha:setPackage(ol_mou)











--以下谋将抄自时光流逝FC的谋攻篇（膜拜大佬）
--（但为什么有这么多全局技呢，还是手动改改吧（；´д｀）ゞ）

local mobilemoutong = sgs.Sanguosha:getPackage("mobilemoutong")

--谋刘赪
mobilemou_liucheng = sgs.General(mobilemoutong,"mobilemou_liucheng","qun",3,false)

moulveyingVS = sgs.CreateZeroCardViewAsSkill{
	name = "moulveying",
	view_as = function(self,card)
		local ghcc = sgs.Sanguosha:cloneCard("dismantlement")
		ghcc:setSkillName(self:objectName())
		return ghcc
	end,
	response_pattern = "@@moulveying",
}
moulveying = sgs.CreateTriggerSkill{
    name = "moulveying",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardFinished,sgs.TargetSpecifying},
	view_as_skill = moulveyingVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
        if event == sgs.CardFinished then
			if use.card:isKindOf("Slash") and player:getMark("&mouchui") >= 2 then
				room:sendCompulsoryTriggerLog(player,self)
				player:loseMark("&mouchui",2)
				room:drawCards(player,1,self:objectName())
				room:askForUseCard(player,"@@moulveying","@moulveying_ghcc")
			end
		elseif event == sgs.TargetSpecifying then
			if use.card:isKindOf("Slash") and use.from:getMark("moulveyingUsed-Clear") < 2 and use.from:getPhase() == sgs.Player_Play then
				room:sendCompulsoryTriggerLog(use.from,self)
				use.from:gainMark("&mouchui")
				room:addPlayerMark(use.from,"moulveyingUsed-Clear")
			end
		end
	end,
}
mobilemou_liucheng:addSkill(moulveying)

mouyingwuVS = sgs.CreateZeroCardViewAsSkill{
	name = "mouyingwu",
	response_pattern = "@@mouyingwu",
	view_as = function()
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:setSkillName("mouyingwu")
		return slash
	end,
	enabled_at_play = function()
		return false
	end,
}
mouyingwu = sgs.CreateTriggerSkill{
    name = "mouyingwu",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardFinished,sgs.TargetSpecifying},
	view_as_skill = mouyingwuVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
        if event == sgs.CardFinished then
			if use.card:isNDTrick() and not use.card:isDamageCard() and not use.card:isKindOf("Fqizhengxiangsheng") and player:getMark("&mouchui") >= 2 then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				room:broadcastSkillInvoke(self:objectName())
				player:loseMark("&mouchui",2)
				room:drawCards(player,1,self:objectName())
				room:askForUseCard(player,"@@mouyingwu","@mouyingwu_slash")
			end
		elseif event == sgs.TargetSpecifying then
			if use.card:isNDTrick() and not use.card:isDamageCard() and not use.card:isKindOf("Fqizhengxiangsheng")
			and player:getMark("mouyingwuUsed-Clear") < 2 and player:getPhase() == sgs.Player_Play then
				if use.from:hasSkill("moulveying",true) then
					room:sendCompulsoryTriggerLog(use.from,self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					use.from:gainMark("&mouchui")
					room:addPlayerMark(use.from,"mouyingwuUsed-Clear")
				end
			end
		end
	end,
}
mobilemou_liucheng:addSkill(mouyingwu)

--谋赵云
mobilemou_zhaoyun = sgs.General(mobilemoutong,"mobilemou_zhaoyun","shu")

moulongdanVS = sgs.CreateOneCardViewAsSkill{
	name = "moulongdan",
	response_or_use = true,
	view_filter = function(self,card)
		if sgs.Self:getMark("&moulongdanLast")>0 then return card:getTypeId()==1 end
		if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			return card:isKindOf("Jink")
		else
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern == "slash" then
				return card:isKindOf("Jink")
			else
				return card:isKindOf("Slash")
			end
		end
		return false
	end,
	view_as = function(self,card)
		if sgs.Self:getMark("&moulongdanLast")>0 then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_PLAY then
				local dc = sgs.Self:getTag("moulongdan"):toCard()
				if dc==nil then return end
				pattern = dc:objectName()
			end
			local jink = sgs.Sanguosha:cloneCard(pattern:split("+")[1])
			jink:setSkillName(self:objectName())
			jink:setFlags(self:objectName())
			jink:addSubcard(card)
			return jink
		end
		if card:isKindOf("Slash") then
			local jink = sgs.Sanguosha:cloneCard("jink")
			jink:setSkillName(self:objectName())
			jink:setFlags(self:objectName())
			jink:addSubcard(card)
			return jink
		elseif card:isKindOf("Jink") then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:setSkillName(self:objectName())
			slash:setFlags(self:objectName())
			slash:addSubcard(card)
			return slash
		end
	end,
	enabled_at_play = function(self,player)
		if player:getMark("&moulongdanLast")<1 then return end
		for _,pn in sgs.list(patterns())do
			if player:getMark("moujizhuoBf")<1 then break end
			local dc = dummyCard(pn)
			if dc and dc:getTypeId()==1
			and dc:isAvailable(player)
			then return true end
		end
		return sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self,player,pattern)
		if player:getMark("&moulongdanLast")<1 then return end
		for _,pn in sgs.list(pattern:split("+"))do
			if player:getMark("moujizhuoBf")<1 then break end
			local dc = dummyCard(pn)
			if dc and dc:getTypeId()==1
			then return true end
		end
		return (pattern == "slash" or pattern == "jink")
	end,
}
moulongdan = sgs.CreateTriggerSkill{
    name = "moulongdan",
	events = {sgs.CardFinished,sgs.CardResponded,sgs.EventPhaseChanging,sgs.GameStart,sgs.EventAcquireSkill},
	view_as_skill = moulongdanVS,
	limit_mark = "&moulongdanLast",
	guhuo_type = "l",
	can_trigger = function(self,player)
	    return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
        if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Play then
				local n = 1
				if player:getMark("moujizhuoBf")>0 then n = 0 end
				for _,pn in sgs.list(patterns())do
					if pn=="slash" then continue end
					room:setPlayerMark(player,"moulongdan_guhuo_remove_"..pn,n)
				end
			end
			if (change.to ~= sgs.Player_NotActive) then return end
			for _,p in sgs.list(room:findPlayersBySkillName("moulongdan"))do
				local n = p:getMark("&moulongdanLast")
				if n<3 or n<4 and p:getMark("moujizhuoBf")>0
				then room:addPlayerMark(p,"&moulongdanLast") end
			end
		elseif event == sgs.GameStart then
			if player:hasSkill(self,true) then
				room:setPlayerMark(player,"&moulongdanLast",1)
			end
		elseif event == sgs.EventAcquireSkill then
			if data:toString()=="moulongdan" then
				room:setPlayerMark(player,"&moulongdanLast",1)
			end
		else
			local card
			if event == sgs.CardFinished then
				card = data:toCardUse().card
			else
				card = data:toCardResponse().m_card
			end
			if table.contains(card:getSkillNames(),"moulongdan") or card:hasFlag("moulongdan") then
				room:removePlayerMark(player,"&moulongdanLast")
				player:drawCards(1,"moulongdan")
			end
		end
	end,
}
mobilemou_zhaoyun:addSkill(moulongdan)

local Xlchoices = {"XL_tongchou","XL_bingjin","XL_shucai","XL_luli"}
function setXLeffect(from,to,xl)
	local room = from:getRoom()
	removeXLeffect(from,to,xl)
	room:setPlayerMark(from,"&"..xl,1)
	room:setPlayerMark(from,xl.."from",1)
	room:setPlayerMark(from,xl.."XLto"..to:objectName(),1)
	room:setPlayerMark(to,"&"..xl,1)
end
function removeXLeffect(from,to,xl)
	local room = from:getRoom()
	room:setPlayerMark(from,"&"..xl,0)
	room:setPlayerMark(from,xl.."from",0)
	room:setPlayerMark(from,xl.."XLto"..to:objectName(),1)
	room:setPlayerMark(to,"&"..xl,0)
	room:setPlayerMark(from,"&XL_success+#"..xl,0)
	room:removeTag(xl)
end

moujizhuo = sgs.CreateTriggerSkill{
    name = "moujizhuo",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local phase = player:getPhase()
		if phase == sgs.Player_Start and player:hasSkill(self:objectName()) then
			local XLto = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@XL-jizhuo",true,true)
			if XLto then
				room:broadcastSkillInvoke(self:objectName(),1)
				local choice = room:askForChoice(player,self:objectName(),table.concat(Xlchoices,"+"))
				room:addPlayerMark(player,"moujizhuoTo"..XLto:objectName())
				player:setTag("moujizhuoXL",sgs.QVariant(choice))
				setXLeffect(player,XLto,choice)
			end
		elseif phase == sgs.Player_Finish then
			if player:getMark("moujizhuoBf")>0 then
				room:changeTranslation(player,"moulongdan")
				room:setPlayerMark(player,"moujizhuoBf",0)
			end
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:getMark("moujizhuoTo"..player:objectName())>0 then
					room:setPlayerMark(p,"moujizhuoTo"..player:objectName(),0)
					local xl = p:getTag("moujizhuoXL"):toString()
					p:removeTag("moujizhuoXL")
					if p:getMark("&XL_success+#"..xl)>0 then
						room:addPlayerMark(p,"moujizhuoBf")
						room:changeTranslation(p,"moulongdan",2)
					end
					removeXLeffect(p,player,xl)
				end
			end
		end
	end,
	can_trigger = function(self,player)
	    return player and player:isAlive()
	end,
}
mobilemou_zhaoyun:addSkill(moujizhuo)

--==[[协力]]==--（谋攻篇新机制）
XLeffect = sgs.CreateTriggerSkill{
    name = "XLeffect",
	global = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageComplete,sgs.CardsMoveOneTime,sgs.GameStart,sgs.DrawNCards,
	sgs.CardUsed,sgs.CardResponded,sgs.BuryVictim,sgs.Dying},
	can_trigger = function(self,player)
		return player~=nil
	end,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.DamageComplete then
			local damage = data:toDamage()--协力[同仇]：共计造成至少4点伤害。
			if damage.prevented then return end
			if damage.from and damage.from:getMark("&XL_tongchou")>0 then
				local n = room:getTag("XL_tongchou"):toInt()
				n = n+damage.damage
				room:setTag("XL_tongchou",sgs.QVariant(n))
				if n>=4 then
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if p:getMark("&XL_tongchou")<1 then continue end
						room:setPlayerMark(p,"&XL_success+#XL_tongchou",1) --“协力”成功
						room:setPlayerMark(p,"&XL_tongchou",0)
					end
				end
			end
			if damage.reason=="lightning" then
				player:setTag("LeigongzhuwoDamage",ToData(true))
			end
		elseif event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason~="InitialHandCards" or player:getKingdom()~="mo" then return end
			local k = room:askForKingdom(player,"mo","wei+shu+wu+qun+jin",true)
			room:setPlayerProperty(player,"kingdom",ToData(k))
		elseif event==sgs.GameStart then
			if player:isLord() and room:getMode():contains("p")
			and not table.contains(sgs.Sanguosha:getBanPackages(),"51OLTrick") then
				room:acquireSkill(player,"olmomingcha")
			end
		elseif event==sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			--协力[并进]：共计摸至少八张牌。
			if move.from_places:contains(sgs.Player_DrawPile) and move.to_place==sgs.Player_PlaceHand
			and move.to:objectName()==player:objectName() and player:getMark("&XL_bingjin")>0 then
				local n = room:getTag("XL_bingjin"):toInt()
				for i,id in sgs.qlist(move.card_ids)do
					if move.from_places:at(i)==sgs.Player_DrawPile
					then n = n+1 end
				end
				room:setTag("XL_bingjin",sgs.QVariant(n))
				if n>=8 then
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if p:getMark("&XL_bingjin")<1 then continue end
						room:setPlayerMark(p,"&XL_success+#XL_bingjin",1) --“协力”成功
						room:setPlayerMark(p,"&XL_bingjin",0)
					end
				end
			end
			--协力[疏财]：共计弃置四种花色的牌。
			if move.to_place == sgs.Player_DiscardPile and move.from and move.reason.m_playerId==player:objectName()
			and bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)==sgs.CardMoveReason_S_REASON_DISCARD
			and move.from:objectName()==player:objectName() and player:getMark("&XL_shucai")>0 then
				local suits = room:getTag("XL_shucai"):toString():split("+")
				for i,id in sgs.qlist(move.card_ids)do
					local su = sgs.Sanguosha:getCard(id):getSuitString()
					if table.contains(suits,su) then continue end
					table.insert(suits,su)
				end
				room:setTag("XL_shucai",sgs.QVariant(table.concat(suits,"+")))
				if #suits>=4 then
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if p:getMark("&XL_shucai")<1 then continue end
						room:setPlayerMark(p,"&XL_success+#XL_shucai",1) --“协力”成功
						room:setPlayerMark(p,"&XL_shucai",0)
					end
				end
			end
		elseif event==sgs.BuryVictim then
			for _,ch in sgs.list(Xlchoices)do
				if player:getMark(ch.."from")>0 then
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if player:getMark(ch.."XLto"..p:objectName())>0
						then room:setPlayerMark(p,"&"..ch,0) end
					end
				end
			end
			local death = data:toDeath()
			for _,p in sgs.list(room:getAllPlayers())do
				if p:getMark("ol_shengsiyugongTo"..death.who:objectName())>0 then
					Skill_msg("ol_shengsiyugong",p)
					room:killPlayer(p)
				end
			end
		elseif event==sgs.Dying then
			local dy = data:toDying()
			if dy.who~=player and dy.who:getHp()<1 and player:isAlive()
			and not table.contains(sgs.Sanguosha:getBanPackages(),"51OLTrick") then
				local can = {}
				local cs = hasCard(player,"Luojingxiashi","&h")
				if cs then
					for _,c in sgs.list(cs)do
						table.insert(can,c:getEffectiveId())
					end
				end
                for _,skill in sgs.list(player:getSkillList(true,false))do
		           	local vs = sgs.Sanguosha:getViewAsSkill(skill:objectName())
		           	if vs and vs:isEnabledAtResponse(player,"ol_luojingxiashi")
	               	then table.insert(can,"ol_luojingxiashi") break end
	        	end
       	        if #can>0 then
                    player:setTag("ol_luojingxiashiData",data)
				   	cs = "ol_luojingxiashi0:"..dy.who:objectName()
				  	if room:askForUseCard(player,table.concat(can,","),cs)
					then return end
		        end
				can = {}
				cs = hasCard(player,"Shengsiyugong","&h")
				if cs then
					for _,c in sgs.list(cs)do
						table.insert(can,c:getEffectiveId())
					end
				end
                for _,skill in sgs.list(player:getSkillList(true,false))do
		           	local vs = sgs.Sanguosha:getViewAsSkill(skill:objectName())
		           	if vs and vs:isEnabledAtResponse(player,"ol_shengsiyugong")
	               	then table.insert(can,"ol_shengsiyugong") break end
	        	end
       	        if #can>0 then
                    player:setTag("ol_shengsiyugongData",data)
				   	cs = "ol_shengsiyugong0:"..dy.who:objectName()
				  	room:askForUseCard(player,table.concat(can,","),cs)
		        end
			end
		else
			local card
			if event == sgs.CardUsed then card = data:toCardUse().card
			else card = data:toCardResponse().m_card end
			if card and card:getSuit()<4 and player:getMark("&XL_luli")>0 then
				local suits = room:getTag("XL_luli"):toString():split("+")
				if table.contains(suits,card:getSuitString()) then return end
				table.insert(suits,card:getSuitString())
				room:setTag("XL_luli",sgs.QVariant(table.concat(suits,"+")))
				if #suits>=4 then
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if p:getMark("&XL_luli")<1 then continue end
						room:setPlayerMark(p,"&XL_success+#XL_luli",1) --“协力”成功
						room:setPlayerMark(p,"&XL_luli",0)
					end
				end
			end
		end
	end,
}
mobilemoutong:addSkills(XLeffect)
--============--

--谋张飞
mobilemou_zhangfei = sgs.General(mobilemoutong,"mobilemou_zhangfei","shu")

moupaoxiao = sgs.CreateTriggerSkill{
    name = "moupaoxiao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed,sgs.TargetSpecified,sgs.ConfirmDamage,sgs.Damage,sgs.EventPhaseChanging},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash")
			and player:getPhase()==sgs.Player_Play and player:hasSkill(self) then
				room:addPlayerMark(player,"moupaoxiaoSlashUsed-PlayClear")
				if player:getMark("moupaoxiaoSlashUsed-PlayClear")>1 then
					room:sendCompulsoryTriggerLog(player,self)
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash") and player:getMark("moupaoxiaoSlashUsed-PlayClear")>1 then
				local no_respond_list = use.no_respond_list
				for _,wz in sgs.qlist(use.to)do
					table.insert(no_respond_list,wz:objectName())
					room:addPlayerMark(wz,"@skill_invalidity")
					wz:setFlags("moupaoxiaoTarget")
				end
				use.no_respond_list = no_respond_list
				data:setValue(use)
			end
		elseif event == sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash")
			and player:getMark("moupaoxiaoSlashUsed-PlayClear")>1 then
				damage.damage = damage.damage + 1
				data:setValue(damage)
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and damage.card:isKindOf("Slash")
			and player:getMark("moupaoxiaoSlashUsed-PlayClear")>1
			and damage.to:isAlive() then
				room:loseHp(player,1,true,player,self:objectName())
				for i=0,player:getHandcardNum()do
					local id = player:getRandomHandCardId()
					if player:canDiscard(player,id) then
						room:throwCard(id,player)
						break
					end
				end
			end
		else
			if event == sgs.EventPhaseChanging then
				local change = data:toPhaseChange()
				if change.to ~= sgs.Player_NotActive then
					return false
				end
			end
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:hasFlag("moupaoxiaoTarget") then
					room:setPlayerMark(p,"@skill_invalidity",0)
				end
			end
		end
	end,
}
mobilemou_zhangfei:addSkill(moupaoxiao)

mouxiejiCard = sgs.CreateSkillCard{
    name = "mouxiejiCard",
	target_fixed = false,
	filter = function(self,targets,to_select,player)
		if #targets < 3 then
			return player:canSlash(to_select,nil,false)
		end
		return false
	end,
	on_use = function(self,room,source,targets)
		room:broadcastSkillInvoke("mouxieji",3)
		for _,p in ipairs(targets)do
			local slash = dummyCard("slash")
			slash:setSkillName("_mouxieji")
			room:setCardFlag(slash,"YUANBEN")
			room:useCard(sgs.CardUseStruct(slash,source,p))
		end
	end,
}
mouxiejiVS = sgs.CreateZeroCardViewAsSkill{
    name = "mouxieji",
	view_as = function()
		return mouxiejiCard:clone()
	end,
	response_pattern = "@@mouxieji",
}
mouxieji = sgs.CreateTriggerSkill{
    name = "mouxieji",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseProceeding,sgs.Damage},
	view_as_skill = mouxiejiVS,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseProceeding then
			local phase = player:getPhase()
			if phase == sgs.Player_Start and player:hasSkill(self:objectName()) then
				local XLto = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@XL-xieji",true,true)
				if XLto then
					room:broadcastSkillInvoke(self:objectName(),1)
					local choice = room:askForChoice(player,self:objectName(),table.concat(Xlchoices,"+"))
					room:addPlayerMark(player,"mouxiejiTo"..XLto:objectName())
					player:setTag("mouxiejiXL",sgs.QVariant(choice))
					setXLeffect(player,XLto,choice)
				end
			elseif phase == sgs.Player_Finish then
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:hasSkill(self) and p:getMark("mouxiejiTo"..player:objectName()) > 0 then
						room:removePlayerMark(p,"mouxiejiTo"..player:objectName())
						local xj = p:getTag("mouxiejiXL"):toString()
						if p:getMark("&XL_success+#"..xj)>0 then
							room:broadcastSkillInvoke(self:objectName(),2)
							room:askForUseCard(p,"@@mouxieji","@mouxieji-slash")
						end
						removeXLeffect(p,player,xj)
					end
				end
			end
		elseif event == sgs.Damage then
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),"mouxieji") and player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				room:drawCards(player,damage.damage,self:objectName())
			end
		end
	end,
	can_trigger = function(self,player)
	    return player and player:isAlive()
	end,
}
mobilemou_zhangfei:addSkill(mouxieji)

--谋杨婉
mobilemou_yangwan = sgs.General(mobilemoutong,"mobilemou_yangwan","qun",3,false)

moumingxuanCard = sgs.CreateSkillCard{
	name = "moumingxuanCard",
	will_throw = false,
	filter = function(self,targets,to_select,source)
		if #targets == self:subcardsLength() then return false end
		return to_select:getMark("&moumingxuan+#"..source:objectName())<1
	end,
	on_use = function(self,room,source,targets)
		local suijigives = {}
		for _,c in sgs.qlist(self:getSubcards())do
			table.insert(suijigives,c)
		end
		for _,p in pairs(targets)do
			if p:isDead() then continue end
			local random_card = suijigives[math.random(1,#suijigives)]
			room:obtainCard(p,random_card,false)
			table.removeOne(suijigives,random_card)
		end
		for _,p in pairs(targets)do
			if p:isDead() then continue end
			if p:canSlash(source,nil,false)
			and room:askForUseSlashTo(p,source,"@moumingxuan-slash:"..source:objectName())
			then room:addPlayerMark(p,"&moumingxuan+#"..source:objectName()) continue end
			local card = room:askForExchange(p,"moumingxuan",1,1,true,"#moumingxuan:"..source:objectName())
			if card then
				room:giveCard(p,source,card,"moumingxuan",false)
				room:drawCards(source,1,"moumingxuan")
			end
		end
	end,
}
moumingxuanVS = sgs.CreateViewAsSkill{
	name = "moumingxuan",
	n = 999,--n = 4,
	view_filter = function(self,selected,to_select)
		local n = math.max(1,sgs.Self:getMark("moumingxuanCardGive"))
		if #selected >= n then return false end
		for _,c in sgs.list(selected)do
			if c:getSuit() == to_select:getSuit() then return false end
		end
		return not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		local n = math.max(1,sgs.Self:getMark("moumingxuanCardGive"))
		if #cards >= 1 and #cards <= n then
			local MXC = moumingxuanCard:clone()
			for _,c in ipairs(cards)do
				MXC:addSubcard(c)
			end
			return MXC
		end
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern:startsWith("@@moumingxuan")
	end,
}
moumingxuan = sgs.CreateTriggerSkill{
    name = "moumingxuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	view_as_skill = moumingxuanVS,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local n = 0
			for _,p in sgs.qlist(room:getOtherPlayers(player))do
				if p:getMark("&moumingxuan+#"..player:objectName())<1 then
					n = n+1
				end
			end
			if player:getHandcardNum()>0 and n>0 then
				room:setPlayerMark(player,"moumingxuanCardGive",n) --记录未被记录的角色数
				if room:askForUseCard(player,"@@moumingxuan!","@moumingxuan-card") then return end
				room:broadcastSkillInvoke(self:objectName())
				n = sgs.IntList()
				local dc = moumingxuanCard:clone()
				for i=0,player:getHandcardNum()do
					local c = player:getRandomHandCard()
					if n:contains(c:getSuit()) then break end
					n:append(c:getSuit())
					dc:addSubcard(c)
				end
				local mingxuaners = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:getMark("&moumingxuan+#"..player:objectName())<1 then
						mingxuaners:append(p)
						if mingxuaners:length()>=n:length()
						then break end
					end
				end
				if n:length()>0 and mingxuaners:length()>0
				then dc:use(room,player,mingxuaners) end
			end
		end
	end,
}
mobilemou_yangwan:addSkill(moumingxuan)

mouxianchou = sgs.CreateTriggerSkill{
    name = "mouxianchou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and player:hasSkill(self)
			then
				local plist = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p ~= damage.from and p:canSlash(damage.from,nil,false)
					then plist:append(p) end
				end
				local machao = room:askForPlayerChosen(player,plist,self:objectName(),"@mouxianchou-fujunAvanger",true,true)
				if machao and room:askForCard(machao,"..","@mouxianchou-slash",data)
				then
					local dc = dummyCard()
					dc:setSkillName("_mouxianchou")
					dc:setFlags("mouxianchou")
					room:setPlayerFlag(player,"mouyangwan")
					room:useCard(sgs.CardUseStruct(dc,machao,damage.from),true)
					room:setPlayerFlag(player,"-mouyangwan")
				end
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if (table.contains(use.card:getSkillNames(),"mouxianchou") or use.card:hasFlag("mouxianchou"))
			and use.card:hasFlag("DamageDone") then
				room:drawCards(player,2,self:objectName())
				for _,yw in sgs.qlist(room:getAllPlayers())do
					if yw:hasFlag("mouyangwan") then
						room:setPlayerFlag(yw,"-mouyangwan")
						room:recover(yw,sgs.RecoverStruct("mouxianchou",yw))
					end
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_yangwan:addSkill(mouxianchou)

--谋夏侯氏
mobilemou_xiahoushi = sgs.General(mobilemoutong,"mobilemou_xiahoushi","shu",3,false)

mouyanyuCard = sgs.CreateSkillCard{
    name = "mouyanyuCard",
	target_fixed = true,
	will_throw = true,
	on_use = function(self,room,source,targets)
		room:drawCards(source,1,"mouyanyu")
		room:addPlayerMark(source,"&mouyanyuDraw-PlayClear")
	end,
}
mouyanyuvs = sgs.CreateOneCardViewAsSkill{
    name = "mouyanyu",
	filter_pattern = "Slash",
	view_as = function(self,originalCard)
	    local myy_card = mouyanyuCard:clone()
		myy_card:addSubcard(originalCard)
		return myy_card
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#mouyanyuCard") < 2
	end,
}
mouyanyu = sgs.CreateTriggerSkill{
	name = "mouyanyu",
	events = {sgs.EventPhaseEnd},
	view_as_skill = mouyanyuvs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local n = player:getMark("&mouyanyuDraw-PlayClear")*3
			if n<1 then return end
			local zhangfei = room:askForPlayerChosen(player,room:getOtherPlayers(player),"mouyanyu","mouyanyu-GiveCardsNum:"..n,true,true)
			if zhangfei then
				room:broadcastSkillInvoke("mouyanyu")
				room:drawCards(zhangfei,n,"mouyanyu")
			end
		end
	end,
}
mobilemou_xiahoushi:addSkill(mouyanyu)

mouqiaoshi = sgs.CreateTriggerSkill{
	name = "mouqiaoshi",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.Damaged},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.from and damage.from~=player and player:getMark("mouqiaoshiUse-Clear")<1
			and damage.from:askForSkillInvoke(self,data,false) then
				local log = sgs.LogMessage()
				log.type = "#mouqiaoshiUse"
				log.from = damage.from
				log.to:append(damage.to)
				log.arg = self:objectName()
				room:sendLog(log)
				room:broadcastSkillInvoke(self:objectName())
				room:notifySkillInvoked(player,self:objectName())
				room:recover(player,sgs.RecoverStruct(self:objectName(),player,damage.damage))
				room:drawCards(damage.from,2,self:objectName())
				room:addPlayerMark(player,"mouqiaoshiUse-Clear")
			end
		end
	end,
}
mobilemou_xiahoushi:addSkill(mouqiaoshi)



--谋孙策
mobilemou_sunce = sgs.General(mobilemoutong,"mobilemou_sunce$","wu",4,true)

moujiangVS = sgs.CreateZeroCardViewAsSkill{
	name = "moujiang",
	view_as = function()
		local duel = sgs.Sanguosha:cloneCard("duel")
		duel:setSkillName("moujiang")
		for _,h in sgs.qlist(sgs.Self:getHandcards())do
			duel:addSubcard(h)
		end
		return duel
	end,
	enabled_at_play = function(self,player)
		if player:getMark("mzbBUFFmja")<1 then
			return player:getMark("moujiangUse-PlayClear")<1
			and player:getHandcardNum()>0
		else
			local wu = 0
			if player:getKingdom() == "wu" then wu = wu + 1 end
			for _,w in sgs.qlist(player:getAliveSiblings())do
				if w:getKingdom() == "wu" then wu = wu + 1 end
			end
			return player:getMark("moujiangUse-PlayClear") < wu
			and player:getHandcardNum()>0
		end
	end,
}
moujiang = sgs.CreateTriggerSkill{
    name = "moujiang",
	view_as_skill = moujiangVS,
	events = {sgs.PreCardUsed,sgs.TargetSpecified,sgs.TargetConfirmed},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.PreCardUsed then
			if use.card:isKindOf("Duel") then
				if table.contains(use.card:getSkillNames(),self:objectName())
				then room:addPlayerMark(player,"moujiangUse-PlayClear") end
				local extra_targets = room:getCardTargets(player,use.card,use.to)
				room:setTag("moujiang",data)
				local to = room:askForPlayerChosen(player,extra_targets,self:objectName(),"moujiang0:",true)
				room:removeTag("moujiang")
				if to
				then
					use.to:append(to)
					local log = sgs.LogMessage()
					log.type = "#QiaoshuiAdd"
					log.from = player
					log.to:append(to)
					log.card_str = use.card:toString()
					log.arg = self:objectName()
					room:sendLog(log)
					room:doAnimate(1,player:objectName(),to:objectName())
					room:sortByActionOrder(use.to)
					data:setValue(use)
					room:loseHp(player,1,true,player,self:objectName())
				end
			end
		elseif event == sgs.TargetSpecified or event == sgs.TargetConfirmed and use.to:contains(player) then
			if use.card:isKindOf("Duel") or (use.card:isKindOf("Slash") and use.card:isRed()) then
				if event == sgs.TargetSpecified then
					for _,p in sgs.qlist(use.to)do
						room:sendCompulsoryTriggerLog(player,self)
						room:drawCards(player,1,self:objectName())
					end
				elseif event == sgs.TargetConfirmed then
					room:sendCompulsoryTriggerLog(player,self)
					room:drawCards(player,1,self:objectName())
				end
			end
		end
	end,
}
mobilemou_sunce:addSkill(moujiang)

mouhunzi = sgs.CreateTriggerSkill{
	name = "mouhunzi",
	frequency = sgs.Skill_Wake,
	events = {sgs.QuitDying},
	waked_skills = "mouyingzi,yinghun",
	on_trigger = function(self,event,player,data)
	    if player:getMark(self:objectName())>0 then return end
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
		room:doSuperLightbox(player,self:objectName())
		room:addPlayerMark(player,self:objectName())
		room:changeMaxHpForAwakenSkill(player,-1,self:objectName())
		room:drawCards(player,2,self:objectName())
		room:handleAcquireDetachSkills(player,"mouyingzi|yinghun")
	end,
}
mobilemou_sunce:addSkill(mouhunzi)

mouzhiba = sgs.CreateTriggerSkill{
	name = "mouzhiba$",
	frequency = sgs.Skill_Limited,
	limit_mark = "@mouzhiba",
	events = {sgs.Dying,sgs.Death},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.Dying then
			local dying = data:toDying()
			if dying.who == player and player:getMark("@mouzhiba")>0
			and player:hasLordSkill(self:objectName())
			and player:askForSkillInvoke(self,data) then
				room:removePlayerMark(player,"@mouzhiba")
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox(player,self:objectName())
				local wu = 0
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:getKingdom() == "wu" then
						wu = wu + 1
					end
				end
				if wu > 0 then
					room:recover(player,sgs.RecoverStruct(self:objectName(),player,wu))
				end
				room:addPlayerMark(player,"mzbBUFFmja")
				for _,q in sgs.qlist(room:getOtherPlayers(player))do
					if q:getKingdom() == "wu" then
						player:setFlags("mouzhibaDamage"..q:objectName())
						room:damage(sgs.DamageStruct(self:objectName(),nil,q))
						player:setFlags("-mouzhibaDamage"..q:objectName())
					end
				end
			end
		else
			local death = data:toDeath()
			if death.who:getKingdom()=="wu"
			and death.damage and death.damage.reason==self:objectName()
			and player:hasFlag("mouzhibaDamage"..death.who:objectName())
			then room:drawCards(player,3,self:objectName()) end
		end
	end,
}
mobilemou_sunce:addSkill(mouzhiba)

--谋孙策[二版]
mobilemou_sunces = sgs.General(mobilemoutong,"mobilemou_sunces$","wu",4,true)

mobilemou_sunces:addSkill("moujiang")

mouhunzis = sgs.CreateTriggerSkill{
	name = "mouhunzis",
	frequency = sgs.Skill_Wake,
	events = {sgs.QuitDying},
	waked_skills = "mouyingzi,yinghun",
	on_trigger = function(self,event,player,data)
	    if player:getMark(self:objectName())>0 then return end
		local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName(),math.random(1,2))
		room:doSuperLightbox(player,self:objectName())
		room:addPlayerMark(player,self:objectName())
		room:changeMaxHpForAwakenSkill(player,-1,self:objectName())
		player:gainHujia(1)
		room:drawCards(player,2,self:objectName())
		room:handleAcquireDetachSkills(player,"mouyingzi|yinghun")
	end,
}
mobilemou_sunces:addSkill(mouhunzis)

mouzhibas = sgs.CreateTriggerSkill{
	name = "mouzhibas$",
	frequency = sgs.Skill_Limited,
	limit_mark = "@mouzhibas",
	events = {sgs.Dying,sgs.Death},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.Dying
		then
			local dying = data:toDying()
			if dying.who == player and player:getMark("@mouzhibas")>0
			and player:hasLordSkill(self:objectName())
			and player:askForSkillInvoke(self,data)
			then
				room:removePlayerMark(player,"@mouzhibas")
				room:broadcastSkillInvoke(self:objectName())
				room:doSuperLightbox(player,self:objectName())
				local wu = 0
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:getKingdom() == "wu" then
						wu = wu + 1
					end
				end
				if wu > 0 then
					room:recover(player,sgs.RecoverStruct(self:objectName(),player,wu))
				end
				room:addPlayerMark(player,"mzbBUFFmja")
				for _,q in sgs.qlist(room:getOtherPlayers(player))do
					if q:getKingdom() == "wu" then
						player:setFlags("mouzhibasDamage"..q:objectName())
						room:damage(sgs.DamageStruct(self:objectName(),nil,q))
						player:setFlags("-mouzhibasDamage"..q:objectName())
					end
				end
			end
		else
			local death = data:toDeath()
			if death.who:getKingdom()=="wu"
			and death.damage and death.damage.reason==self:objectName()
			and player:hasFlag("mouzhibasDamage"..death.who:objectName())
			then room:drawCards(player,3,self:objectName()) end
		end
	end,
}
mobilemou_sunces:addSkill(mouzhibas)



--谋祝融
mobilemou_zhurong = sgs.General(mobilemoutong,"mobilemou_zhurong","shu",4,false)

moulieren = sgs.CreateTriggerSkill{
	name = "moulieren",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.TargetSpecified,sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local use = data:toCardUse()
		if event == sgs.TargetSpecified then
			if use.card:isKindOf("Slash") and use.to:length()==1
			and player~=use.to:first() and player:canPindian(use.to:first())
			and player:askForSkillInvoke(self,ToData(use.to:first())) then
				room:broadcastSkillInvoke(self:objectName())
				if player:pindian(use.to:first(),self:objectName()) then
					room:setCardFlag(use.card,"moulierenPDsuccess")
				end
			end
		elseif event == sgs.CardFinished then
			if use.card:isKindOf("Slash") and use.card:hasFlag("moulierenPDsuccess") then
				local tos = room:getOtherPlayers(player)
				tos:removeOne(use.to:first())
				local dmgto = room:askForPlayerChosen(player,tos,self:objectName(),"moulieren-dmgto",true,true)
				if dmgto then
					room:broadcastSkillInvoke(self:objectName())
					room:damage(sgs.DamageStruct(self:objectName(),player,dmgto))
				end
			end
		end
	end,
}
mobilemou_zhurong:addSkill(moulieren)

for i = 0,1 do
    local card = sgs.Sanguosha:cloneCard("savage_assault")
	card:setObjectName("_savage_assault")
	card:setSuit(i)
	card:setNumber(7)
	card:setParent(exclusive_cards)
end

makijuxiang = sgs.CreateTriggerSkill{
    name = "makijuxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardFinished,sgs.CardEffected,sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				room:addPlayerMark(player,"makijuxiangUseSA-Clear")
				local id = use.card:getEffectiveId()
				if id>-1 then
					for _,p in sgs.qlist(room:getOtherPlayers(player))do
						if room:getCardOwner(id) then break end
						if p:hasSkill(self) then
							room:sendCompulsoryTriggerLog(p,self,2)
							room:obtainCard(p,use.card)
						end
					end
				end
			end
		elseif event == sgs.CardEffected then
		    local effect = data:toCardEffect()
		    if effect.card:isKindOf("SavageAssault") and effect.to:hasSkill(self) then
			    room:sendCompulsoryTriggerLog(effect.to,self,2)
			    effect.nullified = true
				data:setValue(effect)
		    end
		elseif event == sgs.EventPhaseProceeding then
			if player:getPhase()==sgs.Player_Finish
			and player:hasSkill(self) and player:getMark("makijuxiangUseSA-Clear")<1
			then
				for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
					local nmrq = sgs.Sanguosha:getEngineCard(id)
					if nmrq:objectName()~="_savage_assault"
					or room:getCardOwner(id) then continue end
					local ecto = room:askForPlayerChosen(player,room:getAllPlayers(),self:objectName(),"makijuxiang-givenm",true,true)
					if ecto then
						room:broadcastSkillInvoke(self:objectName(),1)
						room:obtainCard(ecto,nmrq)
					end
					break
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
}
mobilemou_zhurong:addSkill(makijuxiang)


--谋小乔
mobilemou_xiaoqiao = sgs.General(mobilemoutong,"mobilemou_xiaoqiao","wu",3,false)

moutianxiangCard = sgs.CreateSkillCard{
	name = "moutianxiangCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,player)
		return #targets<1 and to_select:objectName() ~= player:objectName()
		and to_select:getMark("&moutianxiang+heart")<1 and to_select:getMark("&moutianxiang+diamond")<1
	end,
	on_effect = function(self,effect)
		local room = effect.to:getRoom()
		room:giveCard(effect.from,effect.to,self,"moutianxiang")
		effect.to:gainMark("&moutianxiang+"..self:getSuitString())
	end,
}
moutianxiangVS = sgs.CreateOneCardViewAsSkill{
	name = "moutianxiang",
	view_filter = function(self,to_select)
		return to_select:isRed() and not to_select:isEquipped()
	end,
	view_as = function(self,card)
		local tx_card = moutianxiangCard:clone()
		tx_card:addSubcard(card)
		return tx_card
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#moutianxiangCard") < 3 and not player:isKongcheng()
	end,
}
moutianxiang = sgs.CreateTriggerSkill{
	name = "moutianxiang",
	events = {sgs.EventPhaseProceeding,sgs.DamageInflicted},
	view_as_skill = moutianxiangVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Start then
			local draw = 0
			for _,p in sgs.qlist(room:getAllPlayers())do
				draw = draw+p:getMark("&moutianxiang+heart")+p:getMark("&moutianxiang+diamond")
				p:loseAllMarks("&moutianxiang+diamond")
				p:loseAllMarks("&moutianxiang+heart")
			end
			if draw > 0 then
				if room:getMode() == "04_2v2" then --手杀设计师发癫的开端：若为XXX模式
					draw = draw + 3
				end
				room:sendCompulsoryTriggerLog(player,self)
				room:drawCards(player,draw,self:objectName())
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			local tianxiangers = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:getMark("&moutianxiang+heart") > 0 or p:getMark("&moutianxiang+diamond") > 0
				then tianxiangers:append(p) end
			end
			local txr = room:askForPlayerChosen(player,tianxiangers,self:objectName(),"moutianxiang-invoke",true,true)
			if txr then
				room:broadcastSkillInvoke(self:objectName())
				if txr:getMark("&moutianxiang+heart") > 0 then
					txr:loseMark("&moutianxiang+heart")
					tianxiangers = true --防伤判定标志，最后用
					if damage.from then
						room:damage(sgs.DamageStruct(self:objectName(),damage.from,txr))
					end
				end
				if txr:getMark("&moutianxiang+diamond") > 0 then
					txr:loseMark("&moutianxiang+diamond")
					local card = room:askForExchange(txr,self:objectName(),2,2,true,"#moutianxiang:"..player:objectName())
					if card then room:giveCard(txr,player,card,self:objectName()) end
				end
			end
			if tianxiangers==true then
				return true
			end
		end
	end,
}
mobilemou_xiaoqiao:addSkill(moutianxiang)

--花色视为卡
mouhongyan_vsc = sgs.CreateFilterSkill{
	name = "#mouhongyan_vsc",
	view_filter = function(self,to_select)
		local room = sgs.Sanguosha:currentRoom()
		local place = room:getCardPlace(to_select:getEffectiveId())
		return place==sgs.Player_PlaceHand and to_select:getSuit()==0
	end,
	view_as = function(self,card)
		local new_card = sgs.Sanguosha:getWrappedCard(card:getEffectiveId())
		new_card:setSkillName("mouhongyan")
		new_card:setSuit(sgs.Card_Heart)
		new_card:setModified(true)
		return new_card
	end,
}
mouhongyan = sgs.CreateTriggerSkill{
	name = "mouhongyan",
	waked_skills = "#mouhongyan_vsc",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AskForRetrial,sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.AskForRetrial then
			local judge = data:toJudge()
			if judge.card:getSuit() == sgs.Card_Heart then
				room:sendCompulsoryTriggerLog(player,self)
				room:setTag("mouhongyan",data)
				local suit = room:askForSuit(player,"mouhongyan")
				room:removeTag("mouhongyan")
				local cd = sgs.Sanguosha:getWrappedCard(judge.card:getEffectiveId())
				--judge.card:setSuit(suit)
				cd:setSuit(suit)
				cd:setSkillName("mouhongyan")
				cd:setModified(true)
                --cd:deleteLater()
				room:broadcastUpdateCard(room:getPlayers(),judge.card:getEffectiveId(),cd)
				data:setValue(judge)
				judge:updateResult()
			end
		elseif event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceHand) and move.from:objectName()==player:objectName()
			and move.to and move.to:objectName()~=player:objectName() then
				for i,id in sgs.qlist(move.card_ids)do
					if move.from_places:at(i)==sgs.Player_PlaceHand then
						local cd = sgs.Sanguosha:getWrappedCard(id)
						local to = room:getCardOwner(id)
						if cd:getSuit()==0 and to then
							cd:setSuit(2)
							cd:setSkillName("mouhongyan")
							cd:setModified(true)
							room:broadcastUpdateCard(room:getPlayers(),id,cd)
						end
					end
				end
			end
		end
	end,
}
mobilemou_xiaoqiao:addSkill(mouhongyan)
mobilemou_xiaoqiao:addSkill(mouhongyan_vsc)


sgs.Sanguosha:setPackage(mobilemoutong)

local mobilemouneng = sgs.Sanguosha:getPackage("mobilemouneng")

--谋孙尚香
mobilemou_sunshangxiang = sgs.General(mobilemouneng,"mobilemou_sunshangxiang","shu",4,false)

mouliangzhuCard = sgs.CreateSkillCard{
    name = "mouliangzhuCard",
	target_fixed = false,
	filter = function(self,targets,to_select,source)
		return #targets<1 and to_select ~= source and to_select:getEquips():length() > 0
	end,
	on_use = function(self,room,source,targets)
		local equip = room:askForCardChosen(source,targets[1],"e","mouliangzhu")
		source:addToPile("mouJiaZhuang",equip)
		for _,h in sgs.qlist(room:getAllPlayers())do
			if h:getMark("&mouHusband+#"..source:objectName()) > 0 then
				if room:askForChoice(h,"mouliangzhu","1+2") == "1" then
					room:recover(h,sgs.RecoverStruct("mouliangzhu",source))
				else
					room:drawCards(h,2,"mouliangzhu")
				end
			end
		end
	end,
}
mouliangzhu = sgs.CreateZeroCardViewAsSkill{
    name = "mouliangzhu",
	view_as = function()
		return mouliangzhuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#mouliangzhuCard") and player:getKingdom() == "shu"
	end,
}
mobilemou_sunshangxiang:addSkill(mouliangzhu)

moujieyin = sgs.CreateTriggerSkill{
    name = "moujieyin",
	frequency = sgs.Skill_Frequent,
	events = {sgs.GameStart,sgs.EventPhaseStart,sgs.MarkChanged,sgs.GameOver},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.GameStart then
			if player:hasSkill(self:objectName()) then
				local husband = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"@moujieyin-start",false,true)
				husband:gainMark("&mouHusband+#"..player:objectName())
				room:broadcastSkillInvoke(self:objectName(),1)
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play
			or not player:hasSkill(self:objectName())
			or player:getMark("moujieyin_fail")>0 then return false end
			for _,p in sgs.qlist(room:getAllPlayers())do
				if p:getMark("&mouHusband+#"..player:objectName()) > 0 and p:getMark("MJYnow")<1 then
					local choices = {}
					if not p:isKongcheng() then
						table.insert(choices,"1")
					end
					if p:getMark("&mouHusbandMarkLost")<1 then
						table.insert(choices,"2")
					else
						table.insert(choices,"3")
					end
					local choice = room:askForChoice(p,self:objectName(),table.concat(choices,"+"), ToData(player))
					if choice == "1" then
						room:broadcastSkillInvoke(self:objectName(),1)
						local caili = room:askForExchange(p,self:objectName(),2,2,false,"#moujieyin:"..player:getGeneralName())
						if caili then
							room:obtainCard(player,caili,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,player:objectName(),p:objectName(),self:objectName(),""),false)
						end
						p:gainHujia(1)
					elseif choice == "2" then
						local choicee = room:askForChoice(player,self:objectName(),"4+5")
						if choicee == "4" then
							room:broadcastSkillInvoke(self:objectName(),1)
							local Next = room:askForPlayerChosen(player,room:getOtherPlayers(p),self:objectName(),"@moujieyin-markmove")
							Next:gainMark("&mouHusband+#"..player:objectName()) --先让新目标获得标记，防止触发“sgs.MarkChanged”时机时检测到场上无“助”标记
							Next:addMark("MJYnow") --因为处于for循环语句中，防止未执行此循环的角色因获得了“助”标记轮到其时立即开始选择，导致出现错误
							p:loseMark("&mouHusband+#"..player:objectName())
							room:addPlayerMark(p,"&mouHusbandMarkLost")
						elseif choicee == "5" then
							p:loseMark("&mouHusband+#"..player:objectName())
						end
					elseif choice == "3" then
						p:loseMark("&mouHusband+#"..player:objectName())
					end
				end
			end
			for _,p in sgs.qlist(room:getAllPlayers())do
				p:removeMark("MJYnow")
			end
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name:startsWith("&mouHusband+#") and mark.gain<0 then
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
					local fail = false
					for _,pp in sgs.qlist(room:getAllPlayers())do
						if pp:getMark("&mouHusband+#"..p:objectName()) > 0 then
							fail = true
							break
						end
					end
					if fail then continue end
					if p:getMark("moujieyin_fail")<1 then
						--使命失败
						room:broadcastSkillInvoke(self:objectName(),2)
						room:recover(p,sgs.RecoverStruct(self:objectName(),p))
						local JiaZhuang = dummyCard()
						JiaZhuang:addSubcards(p:getPile("mouJiaZhuang"))
						room:obtainCard(p,JiaZhuang,false)
						room:changeKingdom(p,"wu")
						room:loseMaxHp(p)
						room:addPlayerMark(p,"moujieyin_fail")
						for _,p in sgs.qlist(room:getAllPlayers())do
							room:setPlayerMark(p,"&mouHusbandMarkLost",0)
						end
					end
				end
			end
		elseif event == sgs.GameOver then
			for _,ow in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:getMark("&mouHusband+#"..ow:objectName()) > 0 then
						room:broadcastSkillInvoke(self:objectName(),1)
						room:doLightbox("$moujieyin_success")
						return
					end
				end
			end
		end
	end,
	can_trigger = function(self,player)
	    return player and player:isAlive()
	end,
}
mobilemou_sunshangxiang:addSkill(moujieyin)

mouxiaoji = sgs.CreateTriggerSkill{
	name = "mouxiaoji",
	frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceEquip) and move.from:objectName() == player:objectName() then
			if player:getKingdom() ~= "wu" then return false end
			for i = 0,move.card_ids:length()-1 do
				if player:isDead() then break end
				if move.from_places:at(i) == sgs.Player_PlaceEquip then
					room:sendCompulsoryTriggerLog(player,self)
					room:drawCards(player,2,self:objectName())
					if player:isDead() then break end
					local FJ = sgs.SPlayerList()
					for _,lb in sgs.qlist(room:getAlivePlayers())do
						if player:canDiscard(lb,"ej") then FJ:append(lb) end
					end
					local liubei = room:askForPlayerChosen(player,FJ,self:objectName(),"@mouxiaoji-throw",true)
					if liubei then
						room:doAnimate(1,player:objectName(),liubei:objectName())
						local card = room:askForCardChosen(player,liubei,"ej",self:objectName(),false,sgs.Card_MethodDiscard)
						room:throwCard(card,self:objectName(),liubei,player)
					end
				end
			end
		end
	end,
}
mobilemou_sunshangxiang:addSkill(mouxiaoji)

--谋关羽
mobilemou_guanyu = sgs.General(mobilemouneng,"mobilemou_guanyu","shu",4,true)

mouwushengCard = sgs.CreateSkillCard{
	name = "mouwushengCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,source)
		local slash = dummyCard()
		slash:setSkillName("mouwusheng")
		return source:canSlash(to_select,slash)
	end,
	on_validate = function(self,use)
		local yuji = use.from
		local room = yuji:getRoom()
		local to_guhuo = self:getUserString()
		local choices = {}
		if string.find(to_guhuo,"slash") then
			for _,pm in sgs.list(sgs.Sanguosha:getSlashNames())do
				local c = dummyCard(pm)
				c:setSkillName("mouwusheng")
				c:addSubcard(self)
				if yuji:isLocked(c) then continue end
				table.insert(choices,pm)
			end
		end
		if #choices<1 then return nil end
		to_guhuo = room:askForChoice(yuji,"mouwusheng",table.concat(choices,"+"))
		local use_card = dummyCard(to_guhuo)
		use_card:setSkillName("mouwusheng")
		use_card:addSubcard(self)
		return use_card
	end,
	on_validate_in_response = function(self,yuji)
		local room = yuji:getRoom()
		local to_guhuo = self:getUserString()
		local choices = {}
		if string.find(to_guhuo,"slash") then
			for _,pm in sgs.list(sgs.Sanguosha:getSlashNames())do
				local c = dummyCard(pm)
				c:setSkillName("mouwusheng")
				c:addSubcard(self)
				if yuji:isLocked(c) then continue end
				table.insert(choices,pm)
			end
		end
		if #choices<1 then return nil end
		to_guhuo = room:askForChoice(yuji,"mouwusheng",table.concat(choices,"+"))
		local use_card = dummyCard(to_guhuo)
		use_card:setSkillName("mouwusheng")
		use_card:addSubcard(self)
		return use_card
	end,
}
mouwushengVS = sgs.CreateOneCardViewAsSkill{
	name = "mouwusheng",
	response_or_use = true,
	filter_pattern = ".|.|.|hand",
	view_as = function(self,card)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY then
			local dc = sgs.Self:getTag("mouwusheng"):toCard()
			if dc==nil then return end
			local c = sgs.Sanguosha:cloneCard(dc:objectName())
			c:setSkillName(self:objectName())
			c:addSubcard(card)
			return c
		end
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		local AS = mouwushengCard:clone()
		AS:setUserString(pattern)
		AS:addSubcard(card)
		return AS
	end,
	enabled_at_play = function(self,player)
		return player:getHandcardNum()>0
		and sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self,player,pattern)
		return player:getHandcardNum()>0
		and (string.find(pattern,"slash") or string.find(pattern,"Slash"))
	end,
}
mouwusheng = sgs.CreateTriggerSkill{
	name = "mouwusheng",
	events = {sgs.EventPhaseStart,sgs.CardUsed,sgs.EventPhaseEnd},
	view_as_skill = mouwushengVS,
	waked_skills = "#mouwusheng_afterThreeSlashs",
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_Play and player:hasSkill(self:objectName()) then
			local targets = sgs.SPlayerList()
			local mode = room:getMode()
			for _,p in sgs.qlist(room:getOtherPlayers(player))do
				if (string.sub(mode,-1) == "p" or string.sub(mode,-2) == "pd" or string.sub(mode,-2) == "pz")
				and p:isLord() then continue end
				targets:append(p)
			end
			local target = room:askForPlayerChosen(player,targets,self:objectName(),"mouwusheng-invoke",true,true)
			if target then
				room:broadcastSkillInvoke(self:objectName(),1)
				--room:doLightbox("image=image/animate/mouwusheng_invoke.png")--发动特效，怒目圆瞪的二爷
				room:setPlayerMark(target,"&mouwushengTarget+#"..player:objectName().."-PlayClear",1)
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Slash")
			and player:hasSkill(self:objectName()) then
				for _,p in sgs.qlist(use.to)do
					if p:getMark("&mouwushengTarget+#"..player:objectName().."-PlayClear")>0 then
						room:addPlayerMark(player,p:objectName().."mouwushengTarget-PlayClear")
						room:sendCompulsoryTriggerLog(player,self,math.random(2,3))
						local mode = room:getMode()
						local draw = 1
						if string.sub(mode,-1) == "p"
						or string.sub(mode,-2) == "pd"
						or string.sub(mode,-2) == "pz"
						then draw = 2 end
						room:drawCards(player,draw,self:objectName())
					end
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mouwusheng:setJuguanDialog("all_slashs")
mouwusheng_afterThreeSlashs = sgs.CreateProhibitSkill{
	name = "#mouwusheng_afterThreeSlashs",
	is_prohibited = function(self,from,to,card)
		return card:isKindOf("Slash") and to and from:getMark(to:objectName().."mouwushengTarget-PlayClear")>=3
	end,
}
mobilemou_guanyu:addSkill(mouwusheng)
mobilemou_guanyu:addSkill(mouwusheng_afterThreeSlashs)

mouyijue = sgs.CreateTriggerSkill{
	name = "mouyijue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted,sgs.TargetSpecifying},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if damage.from and damage.from ~= player and damage.from:hasFlag("CurrentPlayer")
			and damage.from:hasSkill(self:objectName()) then
				if damage.damage >= player:getHp() + player:getHujia() and player:getMark("&mouyijued")<1 then
					room:sendCompulsoryTriggerLog(damage.from,self)
					room:addPlayerMark(player,"&mouyijued")
					room:addPlayerMark(player,damage.from:objectName().."mouyijued-Clear")
					return true
				end
			end
		elseif event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and player:hasSkill(self) then
				local tos = sgs.SPlayerList()
				for _,p in sgs.qlist(use.to)do
					tos:append(p)
				end
				for _,p in sgs.qlist(tos)do
					if p:getMark(player:objectName().."mouyijued-Clear") > 0
					then use.to:removeOne(p) end
				end
				if use.to:length()<tos:length() then
					room:sendCompulsoryTriggerLog(player,self)
				end
				data:setValue(use)
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_guanyu:addSkill(mouyijue)

--谋孟获
mobilemou_menghuo = sgs.General(mobilemouneng,"mobilemou_menghuo","shu",4,true)

mouhuoshou = sgs.CreateTriggerSkill{
	name = "mouhuoshou",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected,sgs.TargetSpecified,sgs.ConfirmDamage,sgs.CardFinished,sgs.EventPhaseStart,sgs.CardUsed,sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardEffected then
			local effect = data:toCardEffect()
			if effect.card:isKindOf("SavageAssault") and player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				effect.nullified = true
				data:setValue(effect)
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:hasSkill(self) then
						room:sendCompulsoryTriggerLog(p,self)
						local tag = sgs.QVariant()
						tag:setValue(player)
						room:setTag("MHuoshouSource",tag)
					end
				end
				if player:hasSkill(self)
				and player:getPhase()==sgs.Player_Play
				and player:getMark("mouhuoshouUseSA-PlayClear")<1 then
					player:addMark("mouhuoshouUseSA-PlayClear")
					room:setPlayerCardLimitation(player,"use","SavageAssault",false)
				end
			end
		elseif event == sgs.ConfirmDamage then
			local source = room:getTag("MHuoshouSource"):toPlayer()
			local damage = data:toDamage()
			if source and damage.card and damage.card:isKindOf("SavageAssault") then
				damage.from = source
				data:setValue(damage)
			end
		elseif event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("SavageAssault") then
				room:removeTag("MHuoshouSource")
			end
		elseif event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and player:hasSkill(self) then
				local nms = {}
				for _,id in sgs.qlist(room:getDiscardPile())do
					local card = sgs.Sanguosha:getCard(id)
					if card:isKindOf("SavageAssault") then
						table.insert(nms,card)
					end
				end
				if #nms > 0 then
					local nm_card = nms[math.random(1,#nms)]
					room:sendCompulsoryTriggerLog(player,self)
					room:obtainCard(player,nm_card)
				end
			end
		elseif event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Play and player:getMark("mouhuoshouUseSA-PlayClear")>0 then
				room:removePlayerCardLimitation(player,"use","SavageAssault")
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_menghuo:addSkill(mouhuoshou)

function xuLiMax(player)
	local n = 0
	for _,sk in sgs.qlist(player:getVisibleSkillList())do
		local cn = sk:property("ChargeNum"):toString()
		if cn~="" then n = n+tonumber(cn:split("/")[2]) end
	end
	return n
end

mouzaiqiCard = sgs.CreateSkillCard{
	name = "mouzaiqiCard",
	filter = function(self,targets,to_select,source)
		return #targets < source:getMark("&charge_num")
	end,
	on_use = function(self,room,source,targets)
		source:loseMark("&charge_num",#targets)
		for _,p in pairs(targets)do
			local choices = {}
			table.insert(choices,"1")
			if source:isWounded() and p:canDiscard(p,"he") then
				table.insert(choices,"2")
			end
			local choice = room:askForChoice(p,"mouzaiqi",table.concat(choices,"+"),ToData(source))
			if choice == "1" then
				room:drawCards(source,1,"mouzaiqi")
			elseif choice == "2" then
				room:askForDiscard(p,"mouzaiqi",1,1,false,true)
				room:recover(source,sgs.RecoverStruct(self:getSkillName(),p))
			end
		end
	end,
}
mouzaiqiVS = sgs.CreateZeroCardViewAsSkill{
	name = "mouzaiqi",
	view_as = function()
		return mouzaiqiCard:clone()
	end,
	response_pattern = "@@mouzaiqi",
}
mouzaiqi = sgs.CreateTriggerSkill{
	name = "mouzaiqi",
	frequency = sgs.Skill_Frequent,
	events = {sgs.EventPhaseEnd,sgs.Damage},
	view_as_skill = mouzaiqiVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			if player:getPhase() == sgs.Player_Discard and player:getMark("&charge_num") > 0 then
				room:askForUseCard(player,"@@mouzaiqi","@mouzaiqi-card")
			end
		elseif event == sgs.Damage then
			if player:getMark("mouzaiqiXL-Clear")<1 and player:getMark("&charge_num") < xuLiMax(player) then
				player:addMark("mouzaiqiXL-Clear")
				room:sendCompulsoryTriggerLog(player,self:objectName())
				player:gainMark("&charge_num")
			end
		end
	end,
}
mouzaiqi:setProperty("ChargeNum",ToData("0/7"))
mobilemou_menghuo:addSkill(mouzaiqi)

--谋袁绍
mobilemou_yuanshao = sgs.General(mobilemouneng,"mobilemou_yuanshao$","qun",4,true)

mouluanjivs = sgs.CreateViewAsSkill{
	name = "mouluanji",
	n = 2,
	view_filter = function(self,selected,to_select)
		return #selected < 2 and not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		if #cards == 2 then
			local aa = sgs.Sanguosha:cloneCard("archery_attack")
			aa:setSkillName(self:objectName())
			for _,c in sgs.list(cards)do
				aa:addSubcard(c)
			end
			return aa
		end
	end,
	enabled_at_play = function(self,player)
		return player:getHandcardNum() >= 2 and player:getMark("mouluanjiUsed-PlayClear")<1
	end,
}
mouluanji = sgs.CreateTriggerSkill{
	name = "mouluanji",
	view_as_skill = mouluanjivs,
	--frequency = sgs.Skill_Frequent,
	events = {sgs.CardResponded,sgs.PreCardUsed},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardResponded then
			local resp = data:toCardResponse()
		    if resp.m_card:isKindOf("Jink") and resp.m_who and resp.m_who:hasSkill(self) and player~=resp.m_who
			and resp.m_toCard:isKindOf("ArcheryAttack") and resp.m_who:getMark("mouluanjiDraw-Clear")<3 then
				room:addPlayerMark(resp.m_who,"mouluanjiDraw-Clear")
				room:sendCompulsoryTriggerLog(resp.m_who,self)
				room:drawCards(resp.m_who,1,self:objectName())
		    end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				room:addPlayerMark(player,"mouluanjiUsed-PlayClear")
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_yuanshao:addSkill(mouluanji)

mouxueyi = sgs.CreateTriggerSkill{
	name = "mouxueyi$",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.TargetSpecified},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:getTypeId()>0
			and player:hasLordSkill(self:objectName()) then
				for _,p in sgs.list(use.to)do
					if p~=player and p:getKingdom()=="qun" and player:getMark("mouxueyiDC-Clear")<2 then
						room:sendCompulsoryTriggerLog(player,self)
						player:addMark("mouxueyiDC-Clear")
						player:drawCards(1,self:objectName())
					end
				end
			end
		end
	end,
}
mobilemou_yuanshao:addSkill(mouxueyi)

mobilemou_zhangliao = sgs.General(mobilemouneng,"mobilemou_zhangliao","wei",4)
mobilemoutuxiCard = sgs.CreateSkillCard{
	name = "mobilemoutuxiCard",
	will_throw = false,
	target_fixed = false,
	filter = function(self,targets,to_select,source)
		return #targets < self:subcardsLength() and to_select ~= source and not to_select:isKongcheng()
	end,
	on_use = function(self,room,source,targets)
		for _,c in sgs.list(source:getHandcards())do
			room:setCardFlag(c,"-moutuxi")
		end
		room:addPlayerMark(source,"&mobilemoutuxi-Clear")
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_PUT,source:objectName(),self:getSkillName(),"")
		room:moveCardTo(self,source,nil,sgs.Player_DiscardPile,reason,false)
		for _,p in ipairs(targets)do
			local id = room:askForCardChosen(source,p,"h",self:getSkillName())
			reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,source:objectName(),p:objectName(),self:getSkillName(),"")
			room:obtainCard(source,sgs.Sanguosha:getCard(id),reason,false)
		end
	end,
}
mobilemoutuxivs = sgs.CreateViewAsSkill{
	name = "mobilemoutuxi",
	n = 999,
	view_filter = function(self,selected,to_select)
		return to_select:hasFlag("moutuxi")
	end,
	view_as = function(self,cards)
		if #cards<1 then return false end
		local skillcard = mobilemoutuxiCard:clone()
		for _,c in sgs.list(cards)do
			skillcard:addSubcard(c)
		end
		return skillcard
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"@@mobilemoutuxi")
	end,
}
mobilemoutuxi = sgs.CreateTriggerSkill{
	name = "mobilemoutuxi",
	events = {sgs.CardsMoveOneTime},
	view_as_skill = mobilemoutuxivs,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardsMoveOneTime then
	     	local move = data:toMoveOneTime()
			if move.to_place == sgs.Player_PlaceHand and player:hasFlag("CurrentPlayer") and move.to:objectName() == player:objectName()
			and move.reason.m_skillName ~= "mobilemoutuxi" and player:getMark("&mobilemoutuxi-Clear") < 3 then
				for _,id in sgs.list(move.card_ids)do
				    room:setCardFlag(id,"moutuxi")
				end
				room:askForUseCard(player,"@@mobilemoutuxi","@mobilemoutuxi")
				for _,id in sgs.list(move.card_ids)do
				    room:setCardFlag(id,"-moutuxi")
				end
			end
		end
		return false
	end
}
mobilemoudengfeng = sgs.CreateTriggerSkill{
	name = "mobilemoudengfeng",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseChanging then
		    local change = data:toPhaseChange()
			if change.to == sgs.Player_Start then
			    local cards = {}
				local players = sgs.SPlayerList()
		        for _,id in sgs.qlist(room:getDrawPile())do
			        if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
					    table.insert(cards,id)
					end
		        end
	            for _,p in sgs.qlist(room:getOtherPlayers(player))do
		            if p:hasEquip() then
			            players:append(p)
			        end
		        end
		        if #cards > 0 or players:length()>0 then
				    local target = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"~shuangren",true,true)
			        if target then
				        room:broadcastSkillInvoke(self:objectName())
						local choices = {}
			            if target:hasEquip() then
						    table.insert(choices,"1")
						end
						if #cards > 0 then
						    table.insert(choices,"2")
						end
						if #choices>1 then
						    table.insert(choices,"3")
						end
						if #choices > 0 then
						    local choice = room:askForChoice(player,self:objectName(),table.concat(choices,"+"), ToData(target))
							if choice == "3" then
							    room:loseHp(player,1,true,player,self:objectName())
								if player:isDead() then return end
							end
							if choice ~= "2" then
							    local dc = dummyCard()
								for i=1,2 do
									if dc:subcardsLength()>=target:getEquips():length() then break end
									local id = room:askForCardChosen(player,target,"e",self:objectName(),false,sgs.Card_MethodNone,dc:getSubcards())
									if id>-1 then dc:addSubcard(id) else break end
								end
			                    room:obtainCard(target,dc)
							end
							if choice ~= "1" then
							    local card = cards[math.random(1,#cards)]
			                    room:obtainCard(player,card)
							end
						end
			        end
		        end
		    end
		end
		return false
	end,
}
mobilemou_zhangliao:addSkill(mobilemoutuxi)
mobilemou_zhangliao:addSkill(mobilemoudengfeng)
sgs.LoadTranslationTable{
	["mobilemou_zhangliao"] = "谋张辽",
	["#mobilemou_zhangliao"] = "古之召虎",
	["designer:mobilemou_zhangliao"] = "官方",
	["cv:mobilemou_zhangliao"] = "官方",
	["illustrator:mobilemou_zhangliao"] = "官方",
	["mobilemoutuxi"] = "突袭",
	["@mobilemoutuxi"] = "突袭：你可将任意数量的牌置入弃牌堆，然后获得至多等量其他角色各一张手牌",
	[":mobilemoutuxi"] = "你的回合内限三次，当你不因此技能获得牌后，你可将任意数量的牌置入弃牌堆，然后获得至多X名其他角色各一张手牌（X为你此次置入弃牌堆的牌数）。",
	["$mobilemoutuxi1"] = "成败之机，在此一战，诸君何疑！",
	["$mobilemoutuxi2"] = "及敌未合，折其盛势，以安众心！",
	["mobilemoudengfeng"] = "登锋",
	["mobilemoudengfeng:1"] = "令其获得其装备区里的至多两张牌",
	["mobilemoudengfeng:2"] = "从牌堆中获得一张【杀】",
	["mobilemoudengfeng:3"] = "背水-失去1点体力",
	[":mobilemoudengfeng"] = "准备阶段，你可选择一名其他角色并选择一项：1.选择其装备区里的至多两张牌，令其获得之；2.你从牌堆中获得一张【杀】；背水，失去1点体力。",
	["$mobilemoudengfeng1"] = "擒权覆吴，今便得成所愿，众将且奋力一战！",
	["$mobilemoudengfeng2"] = "甘、凌之流，何可阻我之攻势！",
	["~mobilemou_zhangliao"] = "陛下亲临问疾，臣诚惶诚恐……",
}



sgs.Sanguosha:setPackage(mobilemouneng)


local mobilemouzhi = sgs.Sanguosha:getPackage("mobilemouzhi")

--谋曹操
mobilemou_doublefuck = sgs.General(mobilemouzhi,"mobilemou_doublefuck$","wei")

moujianxiong = sgs.CreateTriggerSkill{
    name = "moujianxiong",
	frequency = sgs.Skill_Frequent,
	events = {sgs.GameStart,sgs.Damaged},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.GameStart and player:askForSkillInvoke(self) then
			room:broadcastSkillInvoke(self:objectName())
			local choice = room:askForChoice(player,self:objectName(),"1+2")
			player:gainMark("&mouGW",tonumber(choice))
		elseif event == sgs.Damaged then
			local damage = data:toDamage()
			if damage.card and damage.card:getEffectiveId()>=0
			and player:askForSkillInvoke(self,data) then
				room:broadcastSkillInvoke(self:objectName())
				if room:getCardOwner(damage.card:getEffectiveId())==nil
				then room:obtainCard(player,damage.card) end
				local n = player:getMark("&mouGW")
				if 1-n>0 then
					room:drawCards(player,1-n,self:objectName())
				end
				--调整标记
				if n>0 and player:askForSkillInvoke(self,sgs.QVariant("moujianxiong"),false) then
					player:loseMark("&mouGW")
				end
			end
		end
	end,
}
mobilemou_doublefuck:addSkill(moujianxiong)

mouqingzhengCard = sgs.CreateSkillCard{
    name = "mouqingzhengCard",
	filter = function(self,targets,to_select,source)
		if #targets>0 then return false end
		return to_select~=source and to_select:getHandcardNum()>0
	end,
	on_use = function(self,room,source,targets)
		for _,to in ipairs(targets)do
			local id = room:doGongxin(source,to,to:handCards(),self:getSkillName())
			if id>=0 then
				local dc = dummyCard()
				for _,h in sgs.qlist(to:getHandcards())do
					if sgs.Sanguosha:getCard(id):getSuit()==h:getSuit()
					and source:canDiscard(to,h:getId())
					then dc:addSubcard(h) end
				end
				if dc:subcardsLength()>0
				then room:throwCard(dc,to,source) end
				if self:subcardsLength()>dc:subcardsLength() then
					room:damage(sgs.DamageStruct(self:getSkillName(),source,to))
				end
			end
		end
	end,
}
mouqingzhengVS = sgs.CreateViewAsSkill{
    name = "mouqingzheng",
	n = 999,
	view_filter = function(self,selected,to_select)
		if #selected >= sgs.Self:getMark("mouqingzhengSuits") then return false end
		for _,c in sgs.list(selected)do
			if c:getSuit() == to_select:getSuit() then return false end
		end
		return not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		if #cards==sgs.Self:getMark("mouqingzhengSuits") then
			local dc = mouqingzhengCard:clone()
			for _,c in ipairs(cards)do
				for _,h in sgs.qlist(sgs.Self:getHandcards())do
					if c:getSuit()==h:getSuit()
					then dc:addSubcard(h) end
				end
			end
			return dc
		end
	end,
	response_pattern = "@@mouqingzheng",
}
mouqingzheng = sgs.CreateTriggerSkill{
    name = "mouqingzheng",
	--frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart},
	view_as_skill = mouqingzhengVS,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if player:getPhase() == sgs.Player_Play then
			local suits = sgs.IntList()
			for _,c in sgs.qlist(player:getHandcards())do
				if suits:contains(c:getSuit()) then continue end
				suits:append(c:getSuit())
			end
			local n = player:getMark("&mouGW")
			local m = 3-n
			if m<1 then m = 1 end
			room:setPlayerMark(player,"mouqingzhengSuits",m)
			if suits:length()>=m and room:askForUseCard(player,"@@mouqingzheng","@mouqingzheng:"..m) then
				if n<2 and player:hasSkill("moujianxiong",true)
				and player:askForSkillInvoke(self,sgs.QVariant("mouqingzheng"),false) then
					player:gainMark("&mouGW")
				end
			end
		end
	end,
}
mobilemou_doublefuck:addSkill(mouqingzheng)

mouhujia = sgs.CreateTriggerSkill{
	name = "mouhujia$",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageInflicted,sgs.RoundStart},
	view_as_skill = mouhujiaVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DamageInflicted then
			if player:hasLordSkill(self:objectName()) and player:getMark("mouhujia_lun")<1 then
				player:setTag("mouhujiaDamage",data)
				local tos = sgs.SPlayerList()
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:getKingdom()=="wei" then
						tos:append(p)
					end
				end
				local to = room:askForPlayerChosen(player,tos,self:objectName(),"@mouhujia:",true,true)
				if to then
					room:broadcastSkillInvoke(self:objectName())
					player:addMark("mouhujia_lun")
					local damage = data:toDamage()
					damage.to = to
					damage.transfer = true
					data:setValue(damage)
					player:setTag("TransferDamage",data)
					return true
				end
			end
		end
	end,
}
mobilemou_doublefuck:addSkill(mouhujia)

--谋周瑜
mobilemou_zhouyu = sgs.General(mobilemouzhi,"mobilemou_zhouyu","wu",3,true)

mouyingzi = sgs.CreateTriggerSkill{
	name = "mouyingzi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DrawNCards},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.DrawNCards then
			local draw = data:toDraw()
			if draw.reason~="draw_phase" then return end
			local n = 0
			if player:getHandcardNum() >= 2 then n = n + 1 end
			if player:getHp() >= 2 then n = n + 1 end
			if player:getEquips():length() >= 1 then n = n + 1 end
			if n<1 then return end
			room:sendCompulsoryTriggerLog(player,self)
			local log = sgs.LogMessage()
			log.type = "$mouyingzi_DrawMore"
			log.from = player
			log.arg2 = player:getHandcardNum()
			log.arg3 = player:getHp()
			log.arg4 = player:getEquips():length()
			log.arg5 = n
			room:sendLog(log)
			room:addMaxCards(player,n)
			draw.num = draw.num+n
			data:setValue(draw)
		end
	end,
}
mobilemou_zhouyu:addSkill(mouyingzi)

moufanjianCard = sgs.CreateSkillCard{
	name = "moufanjianCard",
	will_throw = false,
	mute = true;
	filter = function(self,targets,to_select,from)
		return #targets == 0 and to_select:objectName() ~= from:objectName()
	end,
	on_effect = function(self,effect)
	    local room = effect.to:getRoom()
		room:addPlayerMark(effect.from,self:getSuitString().."moufanjianUsed-PlayClear")
		local choice = room:askForChoice(effect.from,"moufanjianSuit","heart+diamond+club+spade") --声明
		local log = sgs.LogMessage()
		log.from = effect.from
		log.type = "#moufanjianSuit"
		log.arg = choice
		room:sendLog(log)
		local choicc = room:askForChoice(effect.to,"moufanjian","1+2+3",ToData(effect.from)) --令其选择
		log.type = "#moufanjian"
		log.to:append(effect.to)
		log.arg = "moufanjian:"..choicc
		room:sendLog(log)
		if choicc == "3" then --直接开摆，猜猜猜，我猜nm呢
			room:broadcastSkillInvoke("moufanjian",2)
			effect.to:turnOver()
			room:setPlayerFlag(effect.from,"moufanjian_cantUse")
			room:obtainCard(effect.to,self)
		else
			if choicc == "1" and self:getSuitString()==choice
			or choicc == "2" and self:getSuitString()~=choice then --猜对
				room:broadcastSkillInvoke("moufanjian",2)
				room:setPlayerFlag(effect.from,"moufanjian_cantUse")
				log.type = "$moufanjianGuess_success"
				room:sendLog(log)
				room:getThread():delay()
				room:obtainCard(effect.to,self)
			else--猜错
				room:broadcastSkillInvoke("moufanjian",1)
				log.type = "$moufanjianGuess_fail"
				room:sendLog(log)
				room:getThread():delay()
				room:obtainCard(effect.to,self)
				room:loseHp(effect.to,1,true,effect.from,"moufanjian")
			end
		end
	end,
}
moufanjian = sgs.CreateViewAsSkill{
    name = "moufanjian",
	n = 1,
	view_filter = function(self,selected,to_select)
		return not to_select:isEquipped()
		and sgs.Self:getMark(to_select:getSuitString().."moufanjianUsed-PlayClear")<1
	end,
	view_as = function(self,cards)
		if #cards == 1 then
			local card = moufanjianCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	enabled_at_play = function(self,player)
		return not player:isKongcheng() and not player:hasFlag("moufanjian_cantUse")
	end,
}
mobilemou_zhouyu:addSkill(moufanjian)

--谋刘备
mobilemou_liubei = sgs.General(mobilemouzhi,"mobilemou_liubei$","shu",4,true)

mourendeCard = sgs.CreateSkillCard{
	name = "mourendeCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,source)
		if self:subcardsLength()<1 then return false end
		return #targets<1 and to_select:getMark("mourendeCardGet-PlayClear")<1
		and to_select:objectName() ~= source:objectName()
	end,
	feasible = function(self,targets,source)
		return self:subcardsLength()<1 and source:getMark("mRenWang-Clear")<1
		or #targets>0
	end,
	on_validate = function(self,use)
		if string.find(self:getUserString(),"+") then
			local choices = {}
			local room = use.from:getRoom()
			for _,pc in sgs.list(self:getUserString():split("+"))do
				local dc = dummyCard(pc)
				if dc and dc:getTypeId()==1 then
					dc:setSkillName("_mourende")
					if use.from:isLocked(dc) then continue end
					table.insert(choices,pc)
				end
			end
			if #choices<1 then return nil end
			choices = room:askForChoice(use.from,"mourende",table.concat(choices,"+"))
			local dc = dummyCard(choices)
			dc:setSkillName("_mourende")
			return dc
		end
		return self
	end,
	on_validate_in_response = function(self,from)
		if string.find(self:getUserString(),"+") then
			local choices = {}
			local room = from:getRoom()
			for _,pc in sgs.list(self:getUserString():split("+"))do
				local dc = dummyCard(pc)
				if dc and dc:getTypeId()==1 then
					dc:setSkillName("_mourende")
					if from:isLocked(dc) then continue end
					table.insert(choices,pc)
				end
			end
			if #choices<1 then return nil end
			choices = room:askForChoice(from,"mourende",table.concat(choices,"+"))
			local dc = dummyCard(choices)
			dc:setSkillName("_mourende")
			return dc
		end
		return self
	end,
	about_to_use = function(self,room,use)
		if use.to:length()<1 then
			local ids = room:getAvailableCardList(use.from,"basic","mourende")
			room:fillAG(ids,use.from)
			local id = room:askForAG(use.from,ids,true,"mourende","mourende_choice")
			room:clearAG(use.from)
			if id>=0 then
				room:setPlayerMark(use.from,"mourendeId",id)
				if room:askForUseCard(use.from,"@@mourende","mourende0:"..sgs.Sanguosha:getEngineCard(id):objectName()) then
					room:addPlayerMark(use.from,"mRenWang-Clear")
				end
			end
			return
		end
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source,targets)
		local hxd = targets[1]
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,source:objectName(),targets[1]:objectName(),"mourende","")
		room:obtainCard(hxd,self,reason,false)
		room:addPlayerMark(hxd,"mourendeCardGet-PlayClear")
		room:setPlayerMark(hxd,"&mourdTOzw",1)
		local n = self:subcardsLength()
		local m = source:getMark("&mRenWang")
		if 8-m<n then n = 8-m end
		source:gainMark("&mRenWang",n)
	end,
}
mourendeVS = sgs.CreateViewAsSkill{
	name = "mourende",
	n = 999,
	view_filter = function(self,selected,to_select)
		return sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY
	end,
	view_as = function(self,cards)
		if #cards<1 then
			local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
			if pattern=="@@mourende" then
				pattern = sgs.Sanguosha:getEngineCard(sgs.Self:getMark("mourendeId")):objectName()
			end
			if sgs.Self:getMark("&mRenWang")>1
			and (string.find(pattern,"+") or pattern=="") then
				local mrd_card = mourendeCard:clone()
				mrd_card:setUserString(pattern)
				return mrd_card
			elseif pattern~="" then
				local c = sgs.Sanguosha:cloneCard(pattern)
				if c then
					c:setSkillName("_mourende")
					return c
				end
			end
		else
			local mrd_card = mourendeCard:clone()
			for _,c in ipairs(cards)do
				mrd_card:addSubcard(c)
			end
			return mrd_card
		end
	end,
	enabled_at_response = function(self,player,pattern)
		if pattern=="@@mourende" then return true end
		if player:getMark("mRenWang-Clear")>0 then return false end
		for _,p in sgs.list(pattern:split("+"))do
			local dc = dummyCard(p)
			if dc and dc:isKindOf("BasicCard")
			and player:getMark("&mRenWang")>1
			then return true end
		end
	end,
	enabled_at_play = function(self,player)
		return player:getCardCount()>0
		or player:getMark("&mRenWang")>1 and player:getMark("mRenWang-Clear")<1
	end,
}
mourende = sgs.CreateTriggerSkill{
	name = "mourende",
	view_as_skill = mourendeVS,
	--frequency = sgs.Skill_Frequent,
	events = {sgs.PreCardUsed,sgs.EventPhaseStart,sgs.PreCardResponded},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and table.contains(use.card:getSkillNames(),"mourende") then
				room:addPlayerMark(player,"mRenWang-Clear")
				player:loseMark("&mRenWang",2)
			end
		elseif event==sgs.PreCardResponded then
	       	local res = data:toCardResponse()
			if res.m_card:getTypeId()>0 and table.contains(res.m_card:getSkillNames(),"mourende") then
				room:addPlayerMark(player,"mRenWang-Clear")
				player:loseMark("&mRenWang",2)
			end
		elseif event == sgs.EventPhaseStart
		and player:getPhase() == sgs.Player_Play and player:hasSkill(self) then
			local n = player:getMark("&mRenWang")
			if n == 7 then
				room:sendCompulsoryTriggerLog(player,self)
				player:gainMark("&mRenWang",1)
			elseif n < 7 then
				room:sendCompulsoryTriggerLog(player,self)
				player:gainMark("&mRenWang",2)
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_liubei:addSkill(mourende)

mouzhangwuCard = sgs.CreateSkillCard{
	name = "mouzhangwuCard",
	target_fixed = true,
	on_use = function(self,room,source,targets)
	    room:removePlayerMark(source,"@mouzhangwu")
		local tos = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers())do
			if p:getMark("&mourdTOzw") > 0 then
				room:doAnimate(1,source:objectName(),p:objectName())
				tos:append(p)
			end
		end
		room:doSuperLightbox(source,"mouzhangwu")
		local n = room:getTag("TurnLengthCount"):toInt()-1
		for _,p in sgs.qlist(tos)do
			if n<1 or p:isDead() or source:isDead() then continue end
			local card = room:askForExchange(p,"mouzhangwu",n,n,true,"#mouzhangwu:"..n)
			if card then room:giveCard(p,source,card,"mouzhangwu") end
		end
		room:recover(source,sgs.RecoverStruct("mouzhangwu",source,3))
		room:detachSkillFromPlayer(source,"mourende")
	end,
}
mouzhangwu = sgs.CreateZeroCardViewAsSkill{
    name = "mouzhangwu",
	frequency = sgs.Skill_Limited,
	limit_mark = "@mouzhangwu",
	view_as = function()
		return mouzhangwuCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@mouzhangwu") > 0
	end,
}
mobilemou_liubei:addSkill(mouzhangwu)
moujijiangCard = sgs.CreateSkillCard{
	name = "moujijiangCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,source)
		if #targets==1 then
			if to_select:inMyAttackRange(targets[1])
			and to_select:getHp()>=source:getHp()
			and to_select:objectName()~=source:objectName()
			then return to_select:getKingdom()=="shu" end
		end
		return #targets<1
	end,
	feasible = function(self,targets)
		return #targets>1
	end,
	about_to_use = function(self,room,use)
		room:setTag("moujijiangData",ToData(use))
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source,targets)
		local use = room:getTag("moujijiangData"):toCardUse()
		local choice = "2"
		local dc = dummyCard()
		dc:setSkillName("_moujijiang")
		if use.to:at(1):canSlash(use.to:at(0),dc)
		then choice = "1="..use.to:at(0):objectName().."+2" end
		if room:askForChoice(use.to:at(1),"moujijiang",choice,room:getTag("moujijiangData"))~="2" then
			room:useCard(sgs.CardUseStruct(dc,use.to:at(1),use.to:at(0)))
		else
			room:addPlayerMark(use.to:at(1),"&moujijiangSL")
		end
	end,
}
moujijiangvs = sgs.CreateViewAsSkill{
	name = "moujijiang",
	n = 0,
	view_as = function(self,cards)
		return moujijiangCard:clone()
	end,
	enabled_at_response = function(self,player,pattern)
		if pattern=="@@moujijiang" then return true end
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
moujijiang = sgs.CreateTriggerSkill{
	name = "moujijiang$",
	view_as_skill = moujijiangvs,
	--frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseEnd,sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play and player:hasLordSkill(self:objectName()) then
			room:askForUseCard(player,"@@moujijiang","@moujijiang:")
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_Play and player:getMark("&moujijiangSL") > 0 then
				room:setPlayerMark(player,"&moujijiangSL",0)
				player:skip(change.to)
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_liubei:addSkill(moujijiang)

--谋甄姬
mobilemou_zhenji = sgs.General(mobilemouzhi,"mobilemou_zhenji","wei",3,false)

mouluoshen = sgs.CreateTriggerSkill{
	name = "mouluoshen",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase ~= sgs.Player_Start then return false end
		local lovers = room:askForPlayerChosen(player,room:getAllPlayers(),self:objectName(),"mouluoshen0:",true,true)
		if lovers then
			room:broadcastSkillInvoke(self:objectName())
			local n = room:alivePlayerCount()/2
			while n > 0 and player:isAlive()do
				if lovers==player then lovers = lovers:getNextAlive() end
				if lovers:getHandcardNum()>0 then
					local card = room:askForExchange(lovers,self:objectName(),1,1,false,"mouluoshen1:")
					room:showCard(lovers,card:getEffectiveId())
					if card:isBlack() then
						room:obtainCard(player,card,true)
						room:ignoreCards(player,card)
					elseif card:isRed() then
						room:throwCard(card,lovers)
					end
				end
				lovers = lovers:getNextAlive()
				n = n - 1
			end
		end
	end,
}
mobilemou_zhenji:addSkill(mouluoshen)

mouqingguo = sgs.CreateOneCardViewAsSkill{
	name = "mouqingguo",
	response_pattern = "jink",
	filter_pattern = ".|black|.|hand",
	response_or_use = true,
	view_as = function(self,card)
		local jink = sgs.Sanguosha:cloneCard("jink")
		jink:setSkillName(self:objectName())
		jink:addSubcard(card:getId())
		return jink
	end,
}
mobilemou_zhenji:addSkill(mouqingguo)

--谋诸葛亮
mobilemou_zhugeliang = sgs.General(mobilemouzhi,"mobilemou_zhugeliang","shu",3)
--谋诸葛亮(暮年)
mobilemou_zhugeliangs = sgs.General(mobilemouzhi,"mobilemou_zhugeliangs","shu",3,true,true)

mouhuojiCard = sgs.CreateSkillCard{
	name = "mouhuojiCard",
	will_throw = true,
	mute = true,
	filter = function(self,targets,to_select,source)
		return #targets<1 and to_select:objectName() ~= source:objectName()
	end,
	on_use = function(self,room,source,targets)
		room:broadcastSkillInvoke("mouhuoji",1)
		room:damage(sgs.DamageStruct(self:objectName(),source,targets[1],1,sgs.DamageStruct_Fire))
		for _,p in sgs.qlist(room:getOtherPlayers(targets[1]))do
			if p:getKingdom() == targets[1]:getKingdom() and p:objectName() ~= source:objectName() then
				room:doAnimate(1,source:objectName(),p:objectName())
				room:damage(sgs.DamageStruct(self:objectName(),source,p,1,sgs.DamageStruct_Fire))
			end
		end
	end,
}
mouhuojiVS = sgs.CreateViewAsSkill{
	name = "mouhuoji",
	n = 0,
	view_filter = function(self,selected,to_select)
		return false
	end,
	view_as = function(self,cards)
		return mouhuojiCard:clone()
	end,
	enabled_at_play = function(self,player,pattern)
		return not player:hasUsed("#mouhuojiCard") and player:getMark("mouhuoji") < 1
	end,
}
mouhuoji = sgs.CreateTriggerSkill{
    name = "mouhuoji",
    events = {sgs.EventPhaseProceeding,sgs.Damage,sgs.Dying},
    shiming_skill = true,
    waked_skills = "mouguanxing,moukongcheng",
    view_as_skill = mouhuojiVS,
    on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if player:getMark("mouhuoji") > 0 then return false end
		if event == sgs.EventPhaseProceeding then
			if player:getPhase() ~= sgs.Player_Start then return false end
			if player:getMark("&mouhuojiDMG") < room:getPlayers():length() then return false end
		    room:sendShimingLog(player,self,true,2) --使命成功
			room:doSuperLightbox(player,"ShimingSuccess")
			room:setPlayerMark(player,"&mouhuojiDMG",0)
			
			local hp = player:getHp()
			local mhp = player:getMaxHp()
			if player:getGeneralName() == "mobilemou_zhugeliang" then
				room:changeHero(player,"mobilemou_zhugeliangs",false,false,false,false)
			elseif player:getGeneral2Name() == "mobilemou_zhugeliang" then
				room:changeHero(player,"mobilemou_zhugeliangs",false,false,true,false)
			else
				room:handleAcquireDetachSkills(player,"-mouhuoji|-moukanpo|mouguanxing|moukongcheng")
			end
			if player:getMaxHp() ~= mhp then room:setPlayerProperty(player,"maxhp",sgs.QVariant(mhp)) end
			if player:getHp() ~= hp then room:setPlayerProperty(player,"hp",sgs.QVariant(hp)) end
		elseif event == sgs.Damage then
		    local damage = data:toDamage()
		    if damage.nature~=sgs.DamageStruct_Fire or damage.to==player then return false end
			room:addPlayerMark(player,"&mouhuojiDMG",damage.damage)
	    else
		    local dying = data:toDying()
		    if dying.who:objectName() ~= player:objectName() then return false end
		    room:sendShimingLog(player,self,false,3) --使命失败
			--room:doLightbox("image=image/animate/mouhuoji_fail.png") --谋诸葛亮暮年原画废案
			room:addPlayerMark(player,"mouhuoji")
	    end
	end,
}
mobilemou_zhugeliang:addSkill(mouhuoji)

moukanpo = sgs.CreateTriggerSkill{
    name = "moukanpo",
	frequency = sgs.Skill_NotFrequent,
    events = {sgs.RoundStart,sgs.CardUsed},
    on_trigger = function(self,event,player,data,room)
	    local use = data:toCardUse()
		if event == sgs.RoundStart then
			if not player:hasSkill(self:objectName()) then return false end
			local names = player:property("SkillDescriptionRecord_moukanpo"):toString():split("+")
			room:setPlayerProperty(player,"SkillDescriptionRecord_moukanpo",sgs.QVariant())
			room:setPlayerMark(player,"&moukanpo",#names)
			local record = sgs.IntList()
			local rcids = sgs.Sanguosha:getRandomCards()
			for id=0,sgs.Sanguosha:getCardCount()do
				if rcids:contains(id) then
					local cd = sgs.Sanguosha:getEngineCard(id)
					if cd:getTypeId()>2 or table.contains(names,cd:objectName())
					or cd:isKindOf("Slash") and table.contains(names,"slash")
					then continue end
					record:append(id)
					table.insert(names,cd:objectName())
					if cd:isKindOf("Slash") then table.insert(names,"slash") end
				end
			end
			local prediction = 4
			if room:getMode() == "04_2v2" or room:getMode() == "03_1v2"
			then prediction = 2 end
			room:sendCompulsoryTriggerLog(player,self)
			local namess = {}
			local log = sgs.LogMessage()
			log.type = "#moukanpo"
			log.from = player
			while prediction>0 and record:length()>0 do
				room:fillAG(record,player)
				local id = room:askForAG(player,record,true,self:objectName())
				room:clearAG(player)
				if id<0 then break end
				local eid = sgs.Sanguosha:getEngineCard(id)
				if eid:isKindOf("Slash") then table.insert(namess,"slash")
				else table.insert(namess,eid:objectName()) end
				prediction = prediction-1
				log.arg = namess[#namess]
				room:sendLog(log,player)
			end
			room:setPlayerProperty(player,"SkillDescriptionRecord_moukanpo",sgs.QVariant(table.concat(namess,"+")))
			room:setPlayerMark(player,"&moukanpo",#namess)
		elseif event == sgs.CardUsed then
			if use.card:getTypeId()<1 then return end
			for _,mzg in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
				if mzg == player then continue end
				local names = mzg:property("SkillDescriptionRecord_moukanpo"):toString():split("+")
				if use.card:isKindOf("Slash") and table.contains(names,"slash")
				or table.contains(names,use.card:objectName()) then
					mzg:setTag("moukanpo",data)
					local invoke = mzg:askForSkillInvoke(self,data)
					mzg:removeTag("moukanpo")
					if invoke then
						room:broadcastSkillInvoke(self:objectName())
						if use.card:isKindOf("Slash") then table.removeOne(names,"slash")
						else table.removeOne(names,use.card:objectName()) end
						room:setPlayerProperty(mzg,"SkillDescriptionRecord_moukanpo",sgs.QVariant(table.concat(names,"+")))
						room:setPlayerMark(mzg,"&moukanpo",#names)
						room:drawCards(mzg,1,self:objectName())
						local nullified_list = use.nullified_list
						table.insert(nullified_list,"_ALL_TARGETS")
						use.nullified_list = nullified_list
						data:setValue(use)
						break
					end
				end
			end
		end
    end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_zhugeliang:addSkill(moukanpo)
--卧龙-->武侯
mouguanxingCard = sgs.CreateSkillCard{
	name = "mouguanxingCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self,room,source,targets)
		room:moveCardTo(self,nil,sgs.Player_DrawPile)
	end,
}
mouguanxingVS = sgs.CreateViewAsSkill{
	name = "mouguanxing",
	n = 999,
	expand_pile = "&mouStarsXing",
	view_filter = function(self,selected,to_select)
		return sgs.Self:getPile("&mouStarsXing"):contains(to_select:getEffectiveId())
	end,
	view_as = function(self,cards)
		if #cards > 0 then
			local guanxing = mouguanxingCard:clone()
			for _,c in ipairs(cards)do
				guanxing:addSubcard(c)
			end
			return guanxing
		end
	end,
	enabled_at_play = function(self,player)
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return string.find(pattern,"@@mouguanxing")
	end,
}
mouguanxing = sgs.CreateTriggerSkill{
	name = "mouguanxing",
	events = {sgs.EventPhaseProceeding},
	view_as_skill = mouguanxingVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if player:getPhase() == sgs.Player_Start then
			room:sendCompulsoryTriggerLog(player,self)
			if not player:getPile("&mouStarsXing"):isEmpty() then
				local dummy = dummyCard()
				dummy:addSubcards(player:getPile("&mouStarsXing"))
				room:throwCard(dummy,nil)
			end
			local n = 7-player:getMark("mouguanxingSPI")*3
			if n > 0 then
				local ids = room:getNCards(n)
				player:addToPile("&mouStarsXing",ids)
				if not room:askForUseCard(player,"@@mouguanxing","@mouguanxing",-1,sgs.Card_MethodNone) then
					room:addPlayerMark(player,"mouguanxing-Clear")
				end
			end
			room:addPlayerMark(player,"mouguanxingSPI")
		elseif player:getPhase() == sgs.Player_Finish and player:getMark("mouguanxing-Clear")>0 then
			room:askForUseCard(player,"@@mouguanxing","@mouguanxing",-1,sgs.Card_MethodNone)
		end
	end,
}
mobilemou_zhugeliangs:addSkill(mouguanxing)

moukongcheng = sgs.CreateTriggerSkill{
	name = "moukongcheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if player:hasSkill("mouguanxing",true) then
			if player:getPile("mouStarsXing"):isEmpty() then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				damage.damage = damage.damage + 1
		        data:setValue(damage)
			else
				room:sendCompulsoryTriggerLog(player,self)
				local judge = sgs.JudgeStruct()
				judge.pattern = "."
				judge.play_animation = false
				judge.who = player
				judge.reason = self:objectName()
				room:judge(judge)
				if judge.card:getNumber() > player:getPile("mouStarsXing"):length() then return false end
				damage.damage = damage.damage - 1
		        data:setValue(damage)
				return damage.damage<1
			end
		end
	end,
}
mobilemou_zhugeliangs:addSkill(moukongcheng)

--谋大乔
mobilemou_daqiao = sgs.General(mobilemouzhi,"mobilemou_daqiao","wu",3,false)

mouguoseCard = sgs.CreateSkillCard{
	name = "mouguoseCard",
	target_fixed = false,
	filter = function(self,targets,to_select)
		return #targets<1 and to_select:containsTrick("indulgence")
	end,
	on_effect = function(self,effect)
		local room = effect.to:getRoom()
		for _,idg in sgs.qlist(effect.to:getJudgingArea())do
			if idg:isKindOf("Indulgence") then
				room:throwCard(idg,effect.to,effect.from)
				break
			end
		end
	end,
}
mouguoseVS = sgs.CreateViewAsSkill{
	name = "mouguose",
	n = 1,
	view_filter = function(self,selected,to_select)
		return to_select:getSuit() == sgs.Card_Diamond
	end,
	view_as = function(self,cards)
		if #cards<1 then --弃乐
			return mouguoseCard:clone()
		else --贴乐
			local indulgence = sgs.Sanguosha:cloneCard("indulgence")
			indulgence:setSkillName(self:objectName())
			indulgence:addSubcard(cards[1])
			return indulgence
		end
	end,
	enabled_at_play = function(self,player)
		return player:getMark("mouguoseUsed-PlayClear") < 4
	end,
}
mouguose = sgs.CreateTriggerSkill{
	name = "mouguose",
	view_as_skill = mouguoseVS,
	events = {sgs.CardFinished},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				room:addPlayerMark(player,"mouguoseUsed-PlayClear")
				room:drawCards(player,1,self:objectName())
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_daqiao:addSkill(mouguose)

mouliuliCard = sgs.CreateSkillCard{
	name = "mouliuliCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select,from)
		return #targets<1 and from~=to_select
		and from:inMyAttackRange(to_select)
		and not to_select:hasFlag("mouliuliUseFrom")
	end,
	on_effect = function(self,effect)
		local room = effect.from:getRoom()
		effect.to:setFlags("mllTarget")
	end,
}
mouliuliVS = sgs.CreateOneCardViewAsSkill{
	name = "mouliuli",
	response_pattern = "@@mouliuli",
	filter_pattern = ".!",
	view_as = function(self,card)
		local mll_card = mouliuliCard:clone()
		mll_card:addSubcard(card)
		return mll_card
	end,
}
mouliuli = sgs.CreateTriggerSkill{
	name = "mouliuli",
	frequency = sgs.Skill_Frequent,
	events = {sgs.TargetConfirming,sgs.EventPhaseStart},
	view_as_skill = mouliuliVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event==sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_RoundStart then return end
			for _,p in sgs.qlist(room:getOtherPlayers(player))do
				if player:getMark("&mouliuli+#"..p:objectName())>0 then
					room:sendCompulsoryTriggerLog(p,self:objectName())
					player:loseAllMarks("&mouliuli+#"..p:objectName())
					player:setPhase(sgs.Player_Play)
					room:broadcastProperty(player,"phase")
					local thread = room:getThread()
					if not thread:trigger(sgs.EventPhaseStart,room,player) then
						thread:trigger(sgs.EventPhaseProceeding,room,player)
					end
					thread:trigger(sgs.EventPhaseEnd,room,player)
					player:setPhase(sgs.Player_RoundStart)
					room:broadcastProperty(player,"phase")
				end
			end
			return
		end
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") and player:hasSkill(self)
		and player:canDiscard(player,"he") and room:alivePlayerCount()>2 then
			room:setPlayerFlag(use.from,"mouliuliUseFrom")
			local uc = room:askForUseCard(player,"@@mouliuli","@liuli:"..use.from:objectName(),-1,sgs.Card_MethodDiscard)
			room:setPlayerFlag(use.from,"-mouliuliUseFrom")
			if uc then
				local aps = room:getOtherPlayers(use.from)
				for _,p in sgs.qlist(aps)do
					if p:hasFlag("mllTarget") then
						p:setFlags("-mllTarget")
						use.to:removeOne(player)
						use.to:append(p)
						room:sortByActionOrder(use.to)
						data:setValue(use)
					end
				end
				if uc:getSuit()~=2 then return end
				local sunce = room:askForPlayerChosen(player,aps,self:objectName(),"mouliuli-extraEffect",true,true)
				if sunce then
					room:addPlayerMark(player,self:objectName())
					room:broadcastSkillInvoke(self:objectName())
					for _,p in sgs.qlist(room:getAllPlayers())do
						p:loseAllMarks("&mouliuli+#"..player:objectName())
					end
					sunce:gainMark("&mouliuli+#"..player:objectName())
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_daqiao:addSkill(mouliuli)

sgs.Sanguosha:setPackage(mobilemouzhi)

local mobilemoushi = sgs.Sanguosha:getPackage("mobilemoushi")

--谋甘宁(重做版)
mobilemou_ganning = sgs.General(mobilemoushi,"mobilemou_ganning","wu",4,true)

mouqixiCard = sgs.CreateSkillCard{
	name = "mouqixiCard",
	target_fixed = false,
	filter = function(self,targets,to_select,player)
		return #targets<1 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self,effect)
	    local room = effect.to:getRoom()
		local suits = {}
		local hs = effect.from:getHandcards()
		for _,h in sgs.qlist(hs)do
			table.insert(suits,h)
		end
		local function compare_func(a,b)
			local as,bs = 0,0
			for _,h in sgs.qlist(hs)do
				if a:getSuit()==h:getSuit()
				then as = as+1 end
				if b:getSuit()==h:getSuit()
				then bs = bs+1 end
			end
			return as>bs
		end
		table.sort(suits,compare_func)
		local choices = {}
		table.insert(choices,"mouqixiMAX=heart")
		table.insert(choices,"mouqixiMAX=diamond")
		table.insert(choices,"mouqixiMAX=club")
		table.insert(choices,"mouqixiMAX=spade")
		local n = 0
		while #choices>0 and effect.to:isAlive() and not effect.from:hasFlag("mouqixiEND") do
			room:getThread():delay(400)
			local choice = room:askForChoice(effect.to,"mouqixi",table.concat(choices,"+"))
			table.removeOne(choices,choice)
			local log = sgs.LogMessage()
			log.from = effect.from
			log.to:append(effect.to)
			if choice=="mouqixiMAX="..suits[1]:getSuitString() then
				log.type = "$mouqixiGuess_success"
				room:sendLog(log)
				room:broadcastSkillInvoke("mouCaiCaiKan",1)
				room:showAllCards(effect.from)
				room:setPlayerFlag(effect.from,"mouqixiEND")
			else
				n = n+1
				log.type = "$mouqixiGuess_fail"
				room:sendLog(log)
				room:broadcastSkillInvoke("mouCaiCaiKan",2)
				if #choices>0 and effect.from:askForSkillInvoke("mouqixi",sgs.QVariant("mouqixi"),false)
				then continue end
			end
			if n>0 and effect.from:isAlive()
			and effect.to:isAlive() then
				local dc = dummyCard()
				for i=1,n do
					if effect.to:getCardCount(true,true)<=dc:subcardsLength() then break end
					local id = room:askForCardChosen(effect.from,effect.to,"hej","mouqixi",false,sgs.Card_MethodDiscard,dc:getSubcards())
					if id<0 then break end
					dc:addSubcard(id)
				end
				room:throwCard(dc,"mouqixi",effect.to,effect.from)
				break
			end
		end
	end,
}
mouqixi = sgs.CreateZeroCardViewAsSkill{
    name = "mouqixi",
	view_as = function()
		return mouqixiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#mouqixiCard")
	end,
}
mobilemou_ganning:addSkill(mouqixi)

moufenweiCard = sgs.CreateSkillCard{ --选择牌和目标
	name = "moufenweiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select)
		return #targets<self:subcardsLength()
	end,
	feasible = function(self,targets)
		return #targets==self:subcardsLength()
		and #targets>0
	end,
	about_to_use = function(self,room,use)
		room:setTag("moufenweiData",ToData(use))
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source,targets)
	    room:removePlayerMark(source,"@moufenwei")
		room:doSuperLightbox(source,"moufenwei")
		local use = room:getTag("moufenweiData"):toCardUse()
		for i,p in sgs.qlist(use.to)do
			p:addToPile("MFwei",self:getSubcards():at(i))
		end
		room:drawCards(source,self:subcardsLength(),"moufenwei")
	end,
}
moufenweivs = sgs.CreateViewAsSkill{
    name = "moufenwei",
	n = 3,
	frequency = sgs.Skill_Limited,
	-- limit_mark = "@moufenwei",--20221231版新功能，可以直接在视为技设置limit_mark了。
	view_filter = function(self,selected,to_select)
		return true
	end,
	view_as = function(self,cards)
		if #cards > 0 then
			local moufenwei_card = moufenweiCard:clone()
			for _,card in pairs(cards)do
				moufenwei_card:addSubcard(card)
			end
			return moufenwei_card
		end
	end,
	enabled_at_play = function(self,player)
		return player:getMark("@moufenwei") > 0
	end,
}
moufenwei = sgs.CreateTriggerSkill{
	name = "moufenwei",
	events = {sgs.TargetConfirming},
	frequency = sgs.Skill_Limited,
	limit_mark = "@moufenwei",
	view_as_skill = moufenweivs,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.TargetConfirming then
			local use = data:toCardUse()
			if use.card:isKindOf("TrickCard") then
				local tos = sgs.SPlayerList()
				for _,p in sgs.qlist(use.to)do
					tos:append(p)
				end
				for _,p in sgs.qlist(tos)do
					local MFwei = p:getPile("MFwei")
					if MFwei:isEmpty() then continue end
					local dummy = dummyCard()
					dummy:addSubcards(MFwei)
					for _,mgn in sgs.qlist(room:findPlayersBySkillName("moufenwei"))do --搁这套娃呢
						local choice = room:askForChoice(mgn,"moufenwei","1+2",data)
						room:broadcastSkillInvoke("moufenwei")
						if choice == "1" then
							room:obtainCard(p,dummy)
						else
							room:throwCard(dummy,p,mgn)
							use.to:removeOne(p)
						end
						break
					end
				end
				data:setValue(use)
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_ganning:addSkill(moufenwei)

--谋庞统
mobilemou_pangtong = sgs.General(mobilemoushi,"mobilemou_pangtong","shu",3,true)

moulianhuanvs = sgs.CreateViewAsSkill{
	name = "moulianhuan",
	n = 1,
	view_filter = function(self,selected,to_select)
		return not to_select:isEquipped() and to_select:getSuit() == sgs.Card_Club
	end,
	view_as = function(self,cards)
		if #cards == 1 then
			local chain = sgs.Sanguosha:cloneCard("iron_chain")
			chain:setSkillName("moulianhuan")
			chain:addSubcard(cards[1])
			return chain
		end
	end,
	enabled_at_play = function(self,player)
		return not player:isKongcheng()
	end,
}
moulianhuan = sgs.CreateTriggerSkill{
	name = "moulianhuan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.CardUsed,sgs.TargetSpecified},
	view_as_skill = moulianhuanvs,
	waked_skills = "#moulianhuanbf",
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("IronChain") then
				if table.contains(use.card:getSkillNames(),self:objectName())
				then room:addPlayerMark(player,"moulianhuanICUsed-PlayClear") end
				if player:getMark("mouniepaned")>0 then
					room:setCardFlag(use.card,"moulianhuanBF")
				elseif player:askForSkillInvoke(self) then
					room:broadcastSkillInvoke(self)
					loseHp(player,1,true,player,self:objectName())
					room:setCardFlag(use.card,"moulianhuanBF")
				end
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if use.card:isKindOf("IronChain")
			and use.card:hasFlag("moulianhuanBF") then
				for _,p in sgs.qlist(use.to)do
					if p:isKongcheng() or p:isChained()
					then continue end
					for i=0,9 do
						local id = p:getRandomHandCardId()
						if player:canDiscard(p,id) then
							room:throwCard(id,p,player)
							break
						end
					end
				end
			end
		end
	end,
}
mobilemou_pangtong:addSkill(moulianhuan)
moulianhuanbf = sgs.CreateCardLimitSkill{
	name = "#moulianhuanbf",
	limit_list = function(self,player,card)
		return "use"
	end,
	limit_pattern = function(self,player,card)
		if player:getMark("moulianhuanICUsed-PlayClear")>0
		and table.contains(card:getSkillNames(), "moulianhuan")
		and player:hasSkill(self,true)
		then return "IronChain" end
		return ""
	end
}
mobilemou_pangtong:addSkill(moulianhuanbf)

mouniepan = sgs.CreateTriggerSkill{
	name = "mouniepan",
	frequency = sgs.Skill_Limited,
	limit_mark = "@mouniepan",
	events = {sgs.AskForPeaches},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local dying_data = data:toDying()
		if dying_data.who == player and room:askForSkillInvoke(player,self:objectName(),data) then
			room:removePlayerMark(player,"@mouniepan")
			room:broadcastSkillInvoke(self:objectName())
			room:doSuperLightbox(player,self:objectName())
			room:addPlayerMark(player,"mouniepaned")
			player:throwAllCards(self:objectName())
			room:drawCards(player,2,self:objectName())
			room:recover(player,sgs.RecoverStruct(self:objectName(),player,2-player:getHp()))
			if player:isChained() then room:setPlayerChained(player) end
			if not player:faceUp() then player:turnOver() end
			if player:hasSkill("moulianhuan",true) then
				room:changeTranslation(player,"moulianhuan")
			end
		end
	end,
	can_trigger = function(self,player)
		return player:hasSkill(self:objectName()) and player:getMark("@mouniepan") > 0
	end,
}
mobilemou_pangtong:addSkill(mouniepan)

--谋法正
mobilemou_fazheng = sgs.General(mobilemoushi,"mobilemou_fazheng","shu",3,true)

mouxuanhuoCard = sgs.CreateSkillCard{
	name = "mouxuanhuoCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,player)
		return #targets == 0 and to_select:getMark("&mXuan") == 0 and to_select:objectName() ~= player:objectName()
	end,
	on_effect = function(self,effect)
		local room = effect.from:getRoom()
		room:giveCard(effect.from,effect.to,self,"mouxuanhuo")
		effect.to:gainMark("&mXuan+#"..effect.from:objectName())
		effect.to:setMark("mXuan"..effect.from:objectName(),0)
	end,
}
mouxuanhuoVS = sgs.CreateOneCardViewAsSkill{
	name = "mouxuanhuo",
	view_filter = function(self,to_select)
		return true
	end,
	view_as = function(self,card)
		local mxh_card = mouxuanhuoCard:clone()
		mxh_card:addSubcard(card)
		return mxh_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#mouxuanhuoCard") and not player:isNude()
	end,
}
mouxuanhuo = sgs.CreateTriggerSkill{
	name = "mouxuanhuo",
	view_as_skill = mouxuanhuoVS,
	events = {sgs.CardsMoveOneTime},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_PlaceHand
			and move.to:getPhase() ~= sgs.Player_Draw and move.to:getHandcardNum()>0
			and move.to:getMark("&mXuan+#"..player:objectName())>0
			and move.to:getMark("mXuan"..player:objectName())<5
			then
				room:sendCompulsoryTriggerLog(player,self)
				move.to:addMark("mXuan"..player:objectName())
				room:obtainCard(player,move.to:getHandcards():at(math.random(0,move.to:getHandcardNum()-1)),false)
			end
		end
	end,
}
mobilemou_fazheng:addSkill(mouxuanhuo)

mouenyuan = sgs.CreateTriggerSkill{
	name = "mouenyuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local phase = player:getPhase()
		if phase ~= sgs.Player_Start then return false end
		for _,p in sgs.qlist(room:getAllPlayers())do
			if p:getMark("&mXuan+#"..player:objectName()) > 0 then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				if p:getMark("mXuan"..player:objectName()) >= 3 then
					room:broadcastSkillInvoke(self:objectName(),1)
					p:loseAllMarks("&mXuan+#"..player:objectName())
					if player:isNude() then return false end
					local card = room:askForExchange(player,self:objectName(),3,3,true,"#mouenyuan:"..p:objectName())
					if card then
						room:obtainCard(p,card,sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,p:objectName(),player:objectName(),self:objectName(),""),false)
					end
				else
					room:broadcastSkillInvoke(self:objectName(),2)
					room:loseHp(p,1,true,player,self:objectName())
					room:recover(player,sgs.RecoverStruct(self:objectName(),player))
					if p:isAlive() then
						p:loseAllMarks("&mXuan+#"..player:objectName())
					end
				end
			end
		end
	end,
}
mobilemou_fazheng:addSkill(mouenyuan)

--谋貂蝉
mobilemou_diaochan = sgs.General(mobilemoushi,"mobilemou_diaochan","qun",3,false)

moulijianCard = sgs.CreateSkillCard{
	name = "moulijianCard",
	target_fixed = false,
	will_throw = true,
	filter = function(self,targets,to_select,source)
		if #targets == self:subcardsLength()+1 then return false end
		return to_select:objectName() ~= source:objectName()
	end,
	feasible = function(self,targets)
		return #targets == self:subcardsLength()+1
	end,
	on_use = function(self,room,source,targets)
	    if #targets > 3 then --触发全屏特效
			--room:doSuperLightbox("mobilemou_diaochan_lj","moulijian")
		end
		for i,p in ipairs(targets)do
			local dc = dummyCard("duel")
			dc:setSkillName("_moulijian")
			local to
			if i==#targets then to = targets[1]
			else to = targets[i+1] end
			if p:isAlive() and to:isAlive() and p:canUse(dc,to) then
				room:useCard(sgs.CardUseStruct(dc,p,to))
			end
		end
	end,
}
moulijian = sgs.CreateViewAsSkill{
    name = "moulijian",
	n = 999,
	view_filter = function(self,selected,to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self,cards)
		if #cards > 0 then
			local MLJ_card = moulijianCard:clone()
			for _,card in pairs(cards)do
				MLJ_card:addSubcard(card)
			end
			return MLJ_card
		end
	end,
	enabled_at_play = function(self,player)
		return not player:isNude() and not player:hasUsed("#moulijianCard")
	end,
}
mobilemou_diaochan:addSkill(moulijian)

moubiyue = sgs.CreateTriggerSkill{
	name = "moubiyue",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged,sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			room:setPlayerFlag(player,"moubiyue_damagedTargets")
		elseif event == sgs.EventPhaseProceeding then --双保险
			if player:getPhase()==sgs.Player_Finish
			and player:hasSkill(self)
			then
				local n = 1
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:hasFlag("moubiyue_damagedTargets")
					then n = n+1 end
				end
				room:sendCompulsoryTriggerLog(player,self)
				if n >= 4 then --触发全屏特效
					--room:doSuperLightbox("mobilemou_diaochan_by","moubiyue")
					n = 4
				end
				room:drawCards(player,n,self:objectName())
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_diaochan:addSkill(moubiyue)

--谋陈宫
mobilemou_chengong = sgs.General(mobilemoushi,"mobilemou_chengong","qun",3,true)

moumingceCard = sgs.CreateSkillCard{
	name = "moumingceCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,from)
		return #targets == 0 and to_select:objectName() ~= from:objectName()
	end,
	on_effect = function(self,effect)
		local room = effect.to:getRoom()
		room:giveCard(effect.from,effect.to,self,"moumingce")
		local choice = room:askForChoice(effect.to,"moumingce","1+2")
		if choice == "1" then
			room:loseHp(effect.to,1,true,effect.from,"moumingce")
			room:drawCards(effect.from,2,"moumingce")
			effect.from:gainMark("&mouCeC")
		else
			room:drawCards(effect.to,1,"moumingce")
		end
	end,
}
moumingcevs = sgs.CreateOneCardViewAsSkill{
	name = "moumingce",
	filter_pattern = ".!",
	view_as = function(self,card)
		local mc_card = moumingceCard:clone()
		mc_card:addSubcard(card:getId())
		return mc_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#moumingceCard") and not player:isNude()
	end,
}
moumingce = sgs.CreateTriggerSkill{
	name = "moumingce",
	view_as_skill = moumingcevs,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local n = player:getMark("&mouCeC")
		local dbfk = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"moumingce-DMGto:"..n,true,true)
		if dbfk then
			room:broadcastSkillInvoke(self)
			room:damage(sgs.DamageStruct(self:objectName(),player,dbfk,n))
			player:loseAllMarks("&mouCeC")
		end
	end,
	can_trigger = function(self,player)
		return player:hasSkill(self) and player:getMark("&mouCeC") > 0 and player:getPhase() == sgs.Player_Play
	end,
}
mobilemou_chengong:addSkill(moumingce)

mouzhichi = sgs.CreateTriggerSkill{
	name = "mouzhichi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged,sgs.DamageInflicted},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local damage = data:toDamage()
		if event == sgs.Damaged then
			room:sendCompulsoryTriggerLog(player,self:objectName())
			room:broadcastSkillInvoke(self:objectName(),2)
			room:addPlayerMark(player,"&mouzhichi-Clear")
		elseif event == sgs.DamageInflicted then
			if player:getMark("&mouzhichi-Clear")>0 then
				room:sendCompulsoryTriggerLog(player,self:objectName())
				room:broadcastSkillInvoke(self:objectName(),1)
				damage.prevented = true
				data:setValue(damage)
				return true
			end
		end
	end,
}
mobilemou_chengong:addSkill(mouzhichi)

mobilemou_guojia = sgs.General(mobilemoushi,"mobilemou_guojia","wei",3)
mobilemoutianduvs = sgs.CreateZeroCardViewAsSkill{
	name = "mobilemoutiandu",
	view_as = function(self,cards)
		local c = sgs.Sanguosha:getEngineCard(sgs.Self:getMark("mobilemoutianduName"))
		local transcard = sgs.Sanguosha:cloneCard(c:objectName())
		transcard:setSkillName("_mobilemoutiandu")
		return transcard
	end,
	enabled_at_play = function()
		return false
	end,
	enabled_at_response = function(self,player,pattern)
		return string.startsWith(pattern,"@@mobilemoutiandu")
	end,
}
mobilemoutiandu = sgs.CreateTriggerSkill{
	name = "mobilemoutiandu",
	change_skill = true,
	events = {sgs.EventPhaseStart},
	view_as_skill = mobilemoutianduvs,
	on_trigger = function(self,event,player,data,room)
		if player:getPhase() == sgs.Player_Play then
			local n = player:getChangeSkillState(self:objectName())
		    if n == 1 and player:getHandcardNum() >= 2 then
				local dc = room:askForDiscard(player,self:objectName(),2,2,true,false,"mobilemoutiandu0",".",self:objectName())
		        if dc then
					room:broadcastSkillInvoke(self:objectName())
					room:setChangeSkillState(player,self:objectName(),2)
					for _,id in sgs.qlist(dc:getSubcards())do
						MarkRevises(player,"&mobilemoutiandu+:",sgs.Sanguosha:getCard(id):getSuitString().."_char")
					end
					local ids = room:getAvailableCardList(player,"trick",self:objectName())
					if ids:isEmpty() then return end
					room:fillAG(ids,player)
					local id = room:askForAG(player,ids,false,self:objectName())
					room:setPlayerMark(player,"mobilemoutianduName",id)
					room:clearAG(player)
					room:askForUseCard(player,"@@mobilemoutiandu!","mobilemoutiandu-ask:"..sgs.Sanguosha:getCard(id):objectName())
				end
			elseif n == 2 then
				room:sendCompulsoryTriggerLog(player,self)
			    room:setChangeSkillState(player,self:objectName(),1)
				local judge = sgs.JudgeStruct()
		        judge.pattern = "."
		        judge.good = true
		        judge.play_animation = false
		        judge.who = player
		        judge.reason = self:objectName()
		        room:judge(judge)
				if room:getCardOwner(judge.card:getEffectiveId())==nil then
					player:obtainCard(judge.card)
				end
				for _,m in sgs.list(player:getMarkNames())do
					if player:getMark(m)>0 and m:startsWith("&mobilemoutiandu+:") and m:contains(judge.card:getSuitString().."_char") then
						room:damage(sgs.DamageStruct(self:objectName(),nil,player))
					end
				end
			end
		end
	end,
}
mobilemouyiji = sgs.CreateTriggerSkill{
	name = "mobilemouyiji",
	events = {sgs.Damaged,sgs.EnterDying},
	frequency = sgs.Skill_Frequent,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged then
		    local damage = data:toDamage()
			if player:askForSkillInvoke(self:objectName(),data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(2,self:objectName())
				local ids = player:handCards()
				player:assignmentCards(ids,self:objectName(),room:getAlivePlayers(),2)
			end
		elseif event == sgs.EnterDying then
			local dying = data:toDying()
			player:addMark("mobilemouyiji_lun")
			if player:getMark("mobilemouyiji_lun")==1
			and player:askForSkillInvoke(self:objectName(),data) then
				room:broadcastSkillInvoke(self:objectName())
				player:drawCards(1,self:objectName())
				local ids = player:handCards()
				room:askForYiji(player,ids,self:objectName(),false,false,true,1,room:getOtherPlayers(player))
			end
		end
	end
}
mobilemou_guojia:addSkill(mobilemoutiandu)
mobilemou_guojia:addSkill(mobilemouyiji)
sgs.LoadTranslationTable{ 
	["mobilemou_guojia"] = "谋郭嘉",
	["#mobilemou_guojia"] = "以身证道",
	["designer:mobilemou_guojia"] = "官方",
	["cv:mobilemou_guojia"] = "官方",
	["illustrator:mobilemou_guojia"] = "官方",
	["mobilemoutiandu"] = "天妒",
	["mobilemoutiandu-ask"] = "天妒：请视为使用【%src】",
	[":mobilemoutiandu"] = "转换技，出牌阶段开始时，阳：你可弃置两张手牌，然后视为使用一张普通锦囊牌；阴：你进行判定并获得此判定牌，若结果与你本局游戏发动“天妒”弃置过的牌花色相同，你受到1点无来源伤害。",
	[":mobilemoutiandu2"] = "转换技，出牌阶段开始时，<font color=\"#01A5AF\"><s>阳：你可弃置两张手牌，然后视为使用一张普通锦囊牌</s></font>；阴：你进行判定并获得此判定牌，若结果与你本局游戏发动“天妒”弃置过的牌花色相同，你受到1点无来源伤害。",
	[":mobilemoutiandu1"] = "转换技，出牌阶段开始时，阳：你可弃置两张手牌，然后视为使用一张普通锦囊牌；<font color=\"#01A5AF\"><s>阴：你进行判定并获得此判定牌，若结果与你本局游戏发动“天妒”弃置过的牌花色相同，你受到1点无来源伤害</s></font>。",
	["mobilemoutiandu0"] = "你可以发动“天妒”弃置两张手牌，然后视为使用一张普通锦囊牌",
	["$mobilemoutiandu1"] = "顺应天命，即为大道所归",
	["$mobilemoutiandu2"] = "计高于人，为天所妒",
	["mobilemouyiji"] = "遗计",
	[":mobilemouyiji"] = "当你受到伤害后，你可以摸两张牌，然后你可以将至多等量张手牌交给任意名其他角色。当你每轮首次进入濒死状态时，你可以摸一张牌，然后你可以将至多等量张手牌交给任意名其他角色。",
	["$mobilemouyiji1"] = "身不能征伐，此计或可襄君太平！",
	["$mobilemouyiji2"] = "此身赴黄泉，望明公见计如晤",
	["~mobilemou_guojia"] = "蒙天所召，嘉先去矣，咳咳咳……",
}


sgs.Sanguosha:setPackage(mobilemoushi)



local mobilemouyu = sgs.Sanguosha:getPackage("mobilemouyu")

--谋黄盖
mobilemou_huanggai = sgs.General(mobilemouyu,"mobilemou_huanggai","wu",4,true)

moukurouCard = sgs.CreateSkillCard{
	name = "moukurouCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,from)
		return #targets == 0 and to_select:objectName() ~= from:objectName()
	end,
	on_effect = function(self,effect)
	    local room = effect.from:getRoom()
		room:giveCard(effect.from,effect.to,self,"moukurou")
		local n = 1
		local c = sgs.Sanguosha:getCard(self:getEffectiveId())
		if c:isKindOf("Peach") or c:isKindOf("Analeptic") then n = n+1 end
		room:loseHp(effect.from,n,true,effect.from,"moukurou")
	end,
}
moukurouvs = sgs.CreateViewAsSkill{
    name = "moukurou",
	n = 1,
	view_filter = function(self,selected,to_select)
		return true
	end,
	view_as = function(self,cards)
		if #cards == 1 then
			local card = moukurouCard:clone()
			card:addSubcard(cards[1])
			return card
		end
	end,
	response_pattern = "@@moukurou",
}
moukurou = sgs.CreateTriggerSkill{
	name = "moukurou",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.HpLost},
	view_as_skill = moukurouvs,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart then
			if player:getPhase() == sgs.Player_Play and not player:isNude() then
				room:askForUseCard(player,"@@moukurou","@moukurou")
			end
		elseif event == sgs.HpLost then
			local lose = data:toHpLost()
			for i=1,lose.lose do
				room:sendCompulsoryTriggerLog(player,self)
				player:gainHujia(2)
			end
		end
	end,
}
mobilemou_huanggai:addSkill(moukurou)

mouzhaxiang = sgs.CreateTriggerSkill{
	name = "mouzhaxiang",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed,sgs.DrawNCards},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				room:addPlayerMark(player,"mouzhaxiangCardUsed-Clear")
				if player:hasSkill(self)
				and player:getMark("mouzhaxiangCardUsed-Clear")<=player:getLostHp() then
					room:sendCompulsoryTriggerLog(player,self)
					local no_respond_list = use.no_respond_list
					table.insert(no_respond_list,"_ALL_TARGETS")
					use.no_respond_list = no_respond_list
					data:setValue(use)
				end
			end
		elseif event == sgs.DrawNCards then
			if player:hasSkill(self) then
				local draw = data:toDraw()
				if draw.reason~="draw_phase" then return end
				local n = player:getLostHp()
				if n<1 then return end
				room:sendCompulsoryTriggerLog(player,self)
				draw.num = draw.num+n
				data:setValue(draw)
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_huanggai:addSkill(mouzhaxiang)

--谋曹仁
mobilemou_caoren = sgs.General(mobilemouyu,"mobilemou_caoren","wei",4,true,false,false,4,1)

moujushouCard = sgs.CreateSkillCard{
	name = "moujushouCard",
	target_fixed = true,
	mute = true,
	on_use = function(self,room,source,targets)
		room:broadcastSkillInvoke("moujushou",1)
		source:turnOver()
		source:gainHujia(self:subcardsLength())
	end,
}
moujushouVS = sgs.CreateViewAsSkill{
	name = "moujushou",
	n = 2,
	view_filter = function(self,selected,to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self,cards)
		local mrd_card = moujushouCard:clone()
		for _,c in ipairs(cards)do
			mrd_card:addSubcard(c)
		end
		return mrd_card
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#moujushouCard") and player:faceUp()
	end,
}
moujushou = sgs.CreateTriggerSkill{
	name = "moujushou",
	view_as_skill = moujushouVS,
	events = {sgs.Damaged,sgs.TurnedOver},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.Damaged then
			local damage = data:toDamage()
			if not player:faceUp() then
				local choice = room:askForChoice(player,"moujushou","1+2")
				room:broadcastSkillInvoke("moujushou",3)
				if choice == "1" then
					player:turnOver()
				elseif choice == "2" then
					player:gainHujia(1)
				end
			end
		elseif event == sgs.TurnedOver then
			local n = player:getHujia()
			if player:faceUp() and n>0 then
				room:sendCompulsoryTriggerLog(player,"moujushou")
				room:broadcastSkillInvoke("moujushou",2)
				room:drawCards(player,n,"moujushou")
			end
		end
	end,
}
mobilemou_caoren:addSkill(moujushou)

moujieweiCard = sgs.CreateSkillCard{
	name = "moujieweiCard",
	target_fixed = false,
	filter = function(self,targets,to_select,from)
		return #targets == 0 and to_select:objectName() ~= from:objectName()
	end,
	on_effect = function(self,effect)
		local room = effect.from:getRoom()
		effect.from:loseHujia(1)
		local card_id = room:doGongxin(effect.from,effect.to,effect.to:handCards())
		if (card_id == -1) then return end
		local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_EXTRACTION,effect.from:objectName())
		room:obtainCard(effect.from,sgs.Sanguosha:getCard(card_id),reason,room:getCardPlace(card_id) ~= sgs.Player_PlaceHand)
	end,
}
moujiewei = sgs.CreateZeroCardViewAsSkill{
	name = "moujiewei",
	view_as = function()
		return moujieweiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#moujieweiCard") and player:getHujia() >= 1
	end,
}
mobilemou_caoren:addSkill(moujiewei)

--谋黄月英
mobilemou_huangyueying = sgs.General(mobilemouyu,"mobilemou_huangyueying","shu",3,false)

moujizhi = sgs.CreateTriggerSkill{
    name = "moujizhi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isNDTrick() then
			room:sendCompulsoryTriggerLog(player,self)
			room:ignoreCards(player,player:drawCardsList(1,self:objectName()))
		end
	end,
}
mobilemou_huangyueying:addSkill(moujizhi)

mouqicaiCard = sgs.CreateSkillCard{
	name = "mouqicaiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,source)
		return #targets<1 and to_select:objectName() ~= source:objectName()
		and (source:getMark("f_mode_doudizhu") > 0 and to_select:hasEquipArea(1)
		or source:getMark("f_mode_doudizhu") == 0 and to_select:hasEquipArea())
	end,
	on_use = function(self,room,source,targets)
	    if self:getSubcards():length() > 0 then
			local e = sgs.Sanguosha:getCard(self:getEffectiveId())
			local tos = sgs.SPlayerList()
			tos:append(targets[1])
			room:moveCardTo(e,source,sgs.Player_PlaceTable,true)
			e:use(room,source,tos)
			targets[1]:gainMark("&mouQI",3)
		else
		    local eqp_or_amr = sgs.IntList()
			for _,id in sgs.qlist(room:getDiscardPile())do
				local c = sgs.Sanguosha:getCard(id)
				if source:getMark("f_mode_doudizhu")>0 then
					if c:isKindOf("Armor")
					and source:getMark("mouqicaiArmor"..c:objectName())<1
					then eqp_or_amr:append(id) end
				elseif c:isKindOf("EquipCard")
				then eqp_or_amr:append(id) end
			end
			if not eqp_or_amr:isEmpty() then
		        room:fillAG(eqp_or_amr,source)
				local ea = room:askForAG(source,eqp_or_amr,false,self:objectName())
				local e = sgs.Sanguosha:getCard(ea)
				local tos = sgs.SPlayerList()
				tos:append(targets[1])
				room:moveCardTo(e,nil,sgs.Player_PlaceTable,true)
				e:use(room,source,tos)
				if source:getMark("f_mode_doudizhu") > 0 then
					room:addPlayerMark(source,"mouqicaiArmor"..e:objectName())
				end
				room:clearAG(source)
			    targets[1]:gainMark("&mouQI",3)
			end
		end
	end,
}
mouqicaivs = sgs.CreateViewAsSkill{
	name = "mouqicai",
	n = 1,
	view_filter = function(self,selected,to_select)
		if to_select:isEquipped() then return false end
		if sgs.Self:getMark("f_mode_doudizhu") > 0 then
			return to_select:isKindOf("Armor") and sgs.Self:getMark("mouqicaiArmor"..to_select:objectName())<1
		else
			return to_select:isKindOf("EquipCard")
		end
	end,
	view_as = function(self,cards)
		local skillcard = mouqicaiCard:clone()
		for _,c in ipairs(cards)do
			skillcard:addSubcard(c)
		end
		return skillcard
	end,
	enabled_at_play = function(self,player)
		if player:hasUsed("#mouqicaiCard") then return false end
		for _,id in sgs.qlist(player:property("mouqicaiDiscardPile"):toIntList())do
			if player:getMark("f_mode_doudizhu")>0 then
				if sgs.Sanguosha:getEngineCard(id):isKindOf("Armor")
				and player:getMark("mouqicaiArmor"..sgs.Sanguosha:getEngineCard(id):objectName()) < 1
				then return true end
			elseif sgs.Sanguosha:getEngineCard(id):isKindOf("EquipCard") then return true end
		end
		for _,h in sgs.qlist(player:getHandcards())do
			if player:getMark("f_mode_doudizhu")>0
			then if h:isKindOf("Armor") then return true end
			elseif h:isKindOf("EquipCard") then return true end
		end
		return false
	end,
}
mouqicai = sgs.CreateTriggerSkill{
	name = "mouqicai",
	--frequency = sgs.Skill_Frequent,
	events = {sgs.CardsMoveOneTime},
	view_as_skill = mouqicaivs,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local move = data:toMoveOneTime()
		if room:getMode()=="03_1v2" then room:setPlayerMark(player,"f_mode_doudizhu",1) end
		if move.to_place==sgs.Player_PlaceHand and move.to:objectName()~=player:objectName()
		and move.to:getMark("&mouQI")>0 then
		    local to = room:findPlayerByObjectName(move.to:objectName())
			for _,id in sgs.qlist(move.card_ids)do
				if sgs.Sanguosha:getCard(id):isNDTrick() then
				    if move.to:getMark("&mouQI") > 0 then
						room:sendCompulsoryTriggerLog(player,self)
						room:obtainCard(player,id,false)
						to:loseMark("&mouQI")
					end
				end
			end
		elseif move.to_place==sgs.Player_DiscardPile
		or move.from_places:contains(sgs.Player_DiscardPile)
		then
			local ids = room:getDiscardPile()
			room:setPlayerProperty(player,"mouqicaiDiscardPile",ToData(ids))
		end
	end,
}
mobilemou_huangyueying:addSkill(mouqicai)

--谋卢植
mobilemou_luzhi = sgs.General(mobilemouyu,"mobilemou_luzhi","qun",3,true)

moumingren = sgs.CreateTriggerSkill{
	name = "moumingren",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.GameStart,sgs.EventPhaseProceeding},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if event == sgs.GameStart then
			room:sendCompulsoryTriggerLog(player,self)
			room:drawCards(player,2,self:objectName())
			local dc = room:askForExchange(player,self:objectName(),1,1,false,"moumingren_put")
			if dc then player:addToPile("mouResponsibility",dc,false) end
		elseif event == sgs.EventPhaseProceeding and player:getPhase() == sgs.Player_Finish then
			if not player:getPile("mouResponsibility"):isEmpty() and not player:isKongcheng() then
				local card = room:askForExchange(player,self:objectName(),1,1,false,"moumingren_exchange",true)
				if card then
					room:broadcastSkillInvoke(self:objectName())
					room:notifySkillInvoked(player,self:objectName())
					local mrsb_card = sgs.Sanguosha:getCard(player:getPile("mouResponsibility"):first())
					room:obtainCard(player,mrsb_card)
					player:addToPile("mouResponsibility",card,false)
				end
			end
		end
	end,
}
mobilemou_luzhi:addSkill(moumingren)

mouzhenliangCard = sgs.CreateSkillCard{
	name = "mouzhenliang",
	filter = function(self,targets,to_select,from)
		return #targets<1 and math.max(1,math.abs(to_select:getHp() - from:getHp())) == self:subcardsLength()
		and from:inMyAttackRange(to_select) and from:objectName() ~= to_select:objectName()
	end,
	on_effect = function(self,effect)
		local room = effect.from:getRoom()
		room:damage(sgs.DamageStruct(self:objectName(),effect.from,effect.to))
		room:setChangeSkillState(effect.from,"mouzhenliang",2)
	end,
}
mouzhenliangVS = sgs.CreateViewAsSkill{
	name = "mouzhenliang",
	n = 999,
	view_filter = function(self,selected,to_select)
		return to_select:getColor() == sgs.Sanguosha:getCard(sgs.Self:getPile("mouResponsibility"):first()):getColor()
	end,
	view_as = function(self,cards)
		local skill = mouzhenliangCard:clone()
		if #cards ~= 0 then
			for _,c in ipairs(cards)do
				skill:addSubcard(c)
			end
		end
		return skill
	end,
	enabled_at_play = function(self,player)
		return player:canDiscard(player,"he") and not player:hasUsed("#mouzhenliang")
		and player:getChangeSkillState("mouzhenliang") == 1 and player:getPile("mouResponsibility"):length() > 0
	end,
}
mouzhenliang = sgs.CreateTriggerSkill{
	name = "mouzhenliang",
	change_skill = true,
	events = {sgs.CardResponded,sgs.CardFinished},
	view_as_skill = mouzhenliangVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local card = nil
		if event == sgs.CardFinished then
			card = data:toCardUse().card
		else
			card = data:toCardResponse().m_card
		end
		if card and not card:isKindOf("SkillCard") then
			for _,mlz in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
				if mlz:hasFlag("CurrentPlayer") or mlz:getChangeSkillState("mouzhenliang") ~= 2
				or mlz:getPile("mouResponsibility"):isEmpty() then continue end
				if card:getTypeId() == sgs.Sanguosha:getCard(mlz:getPile("mouResponsibility"):first()):getTypeId() then
					local to = room:askForPlayerChosen(mlz,room:getAlivePlayers(),self:objectName(),"mouzhenliang-invoke",true,true)
					if to then
						room:broadcastSkillInvoke(self:objectName())
						room:drawCards(to,2,self:objectName())
						room:setChangeSkillState(mlz,"mouzhenliang",1)
					end
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
mobilemou_luzhi:addSkill(mouzhenliang)

sgs.Sanguosha:setPackage(mobilemouyu)



local mobile = sgs.Sanguosha:getPackage("mobile")

mobile_majun = sgs.General(mobile,"mobile_majun","wei",3)
mobilejingxieCard = sgs.CreateSkillCard{
	name = "mobilejingxieCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self,room,source,targets)
		room:showCard(source,self:getEffectiveId())
		local c = sgs.Sanguosha:getCard(self:getEffectiveId())
		for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
			local rc = sgs.Sanguosha:getCard(id)
			if "_"..c:objectName()==rc:objectName()
			and c:getNumber()==rc:getNumber()
			and c:getSuit()==rc:getSuit() then
				room:getThread():delay()
				local moves = sgs.CardsMoveList()
				local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE,source:objectName(),"mobilejingxie","")
				moves:append(sgs.CardsMoveStruct(id,source,sgs.Player_PlaceHand,reason))
				moves:append(sgs.CardsMoveStruct(self:getEffectiveId(),nil,sgs.Player_PlaceTable,reason))
				room:moveCardsAtomic(moves,true)
				break
			end
		end
	end,
}
mobilejingxievs = sgs.CreateViewAsSkill{
	name = "mobilejingxie",
	n = 1,
	view_filter = function(self,selected,to_select)
		return to_select:objectName()=="crossbow"
		or to_select:objectName()=="eight_diagram"
		or to_select:objectName()=="renwang_shield"
		or to_select:objectName()=="silver_lion"
		or to_select:objectName()=="vine"
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local dc = mobilejingxieCard:clone()
		for _,c in ipairs(cards)do
			dc:addSubcard(c)
		end
		return dc
	end,
	enabled_at_play = function(self,player)
		return player:getCardCount()>0
	end,
	enabled_at_response = function(self,player,pattern)
		if pattern=="@@mobilejingxie" then return true end
	end
}
mobilejingxie = sgs.CreateTriggerSkill{
	name = "mobilejingxie",
	events = {sgs.Dying},
	view_as_skill = mobilejingxievs,
	waked_skills = "_crossbow,_eight_diagram,_renwang_shield,_silver_lion,_vine",
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
		if dying.who~=player or player:isNude() then return false end
		local dc = room:askForCard(player,"Armor","mobilejingxie0:",data,sgs.Card_MethodRecast)
		if dc then
			room:broadcastSkillInvoke(self:objectName())
			UseCardRecast(player,dc,"@mobilejingxie")
			if player:isAlive() and player:getHp()<1 then
				room:recover(player,sgs.RecoverStruct("mobilejingxie",player,1-player:getHp()))
			end
		end
	end,
}
mobile_majun:addSkill(mobilejingxie)

_crossbowSkill = sgs.CreateTargetModSkill{
	name = "_crossbow",
	pattern = "Slash",
	residue_func = function(self,from,card)-- 额外使用
		if from:hasWeapon("_crossbow")
		then return 999 end
		return 0
	end,
}
mobile:addSkills(_crossbowSkill)
_crossbow = sgs.CreateWeapon{
	name = "_crossbow",
	class_name = "Crossbow",
	range = 3,--[[
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,_crossbowSkill,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"_crossbow",true)
		return false
	end,--]]
	suit = 1,
	number = 1,
}
_crossbow:setParent(exclusive_cards)
_crossbow:clone(3,1):setParent(exclusive_cards)
_eight_diagramSkill = sgs.CreateTriggerSkill{
	name = "_eight_diagram",
	events = {sgs.CardAsked},
	can_trigger = function(self,target)
		return target and target:hasArmorEffect("_eight_diagram")
	end,
	on_trigger = function(self,event,player,data,room)
    	if event==sgs.CardAsked then
    		local pattern = data:toStringList()
    		if string.find(pattern[1],"jink") then
	           	local jink = dummyCard("jink")
	           	jink:setSkillName("__eight_diagram")
				if player:isCardLimited(jink,pattern[3]=="use" and sgs.Card_MethodUse or sgs.Card_MethodResponse)
				or not player:askForSkillInvoke(self,data) then return end
	           	room:setEmotion(player,"armor/eight_diagram")
		       	local judge = sgs.JudgeStruct()
               	judge.pattern = ".|spade"
	           	judge.good = false
	           	judge.reason = self:objectName()
               	judge.who = player
	           	room:judge(judge)
				if judge:isGood() then
			    	room:provide(jink)
					return true
				end
			end
		end
		return false
	end
}
_eight_diagram = sgs.CreateArmor{
	name = "_eight_diagram",
	class_name = "EightDiagram",
	equip_skill = _eight_diagramSkill,
	suit = 0,
	number = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,_eight_diagramSkill,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"_eight_diagram",true,true)
		return false
	end,
}
_eight_diagram:setParent(exclusive_cards)
_eight_diagram:clone(1,2):setParent(exclusive_cards)
_renwang_shieldSkill = sgs.CreateTriggerSkill{
	name = "_renwang_shield",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardEffected},
	can_trigger = function(self,target)
		return target and target:hasArmorEffect("_renwang_shield")
	end,
	on_trigger = function(self,event,player,data,room)
    	if event==sgs.CardEffected then
            local effect = data:toCardEffect()
			if effect.card:isKindOf("Slash")
			and (effect.card:isBlack() or effect.card:getSuit()==2) then
	        	room:sendCompulsoryTriggerLog(player,"_renwang_shield")
	         	room:setEmotion(player,"armor/renwang_shield")
	    		effect.nullified = true
				data:setValue(effect)
			end
		end
		return false
	end
}
_renwang_shield = sgs.CreateArmor{
	name = "_renwang_shield",
	class_name = "RenwangShield",
	equip_skill = _renwang_shieldSkill,
	suit = 1,
	number = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,_renwang_shieldSkill,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"_renwang_shield",true,true)
		return false
	end,
}
_renwang_shield:setParent(exclusive_cards)
_silver_lionSkill = sgs.CreateTriggerSkill{
	name = "_silver_lion",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted,sgs.CardEffected,sgs.CardAsked},
	can_trigger = function(self,target)
		return target and target:hasArmorEffect("_silver_lion")
	end,
	on_trigger = function(self,event,player,data,room)
    	if event==sgs.DamageInflicted then
		    local damage = data:toDamage()
        	if damage.damage>1 then
	        	room:sendCompulsoryTriggerLog(player,"_silver_lion")
	         	room:setEmotion(player,"armor/silver_lion")
		    	player:damageRevises(data,1-damage.damage)
			end
		end
		return false
	end
}
_silver_lion = sgs.CreateArmor{
	name = "_silver_lion",
	class_name = "SilverLion",
	equip_skill = _silver_lionSkill,
	suit = 1,
	number = 1,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,_silver_lionSkill,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"_silver_lion",true,true)
		if player:isAlive() and player:hasArmorEffect("_silver_lion") then
	     	room:sendCompulsoryTriggerLog(player,"_silver_lion")
	       	room:setEmotion(player,"armor/silver_lion")
	    	room:recover(player,sgs.RecoverStruct(player,self))
			player:drawCards(2,"_silver_lion")
		end
		return false
	end,
}
_silver_lion:setParent(exclusive_cards)
_vineSkill = sgs.CreateTriggerSkill{
	name = "_vine",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted,sgs.CardEffected,sgs.ChainStateChange},
	can_trigger = function(self,target)
		return target and target:hasArmorEffect("_vine")
	end,
	on_trigger = function(self,event,player,data,room)
    	if event==sgs.DamageInflicted then
		    local damage = data:toDamage()
            if damage.nature==sgs.DamageStruct_Fire then
                room:sendCompulsoryTriggerLog(player,"_vine")
	         	room:setEmotion(player,"armor/vineburn")
    	        player:damageRevises(data,1)
			end
    	elseif event==sgs.ChainStateChange then
			if player:isChained() then return end
	        room:sendCompulsoryTriggerLog(player,"_vine")
	       	room:setEmotion(player,"armor/vine")
			return true
    	elseif event==sgs.CardEffected then
            local effect = data:toCardEffect()
			if effect.card:objectName()=="slash"
			or effect.card:isKindOf("ArcheryAttack")
			or effect.card:isKindOf("SavageAssault") then
	        	room:sendCompulsoryTriggerLog(player,"_vine")
	         	room:setEmotion(player,"armor/vine")
	    		effect.nullified = true
			end
	    	data:setValue(effect)
		end
		return false
	end
}
_vine = sgs.CreateArmor{
	name = "_vine",
	class_name = "Vine",
	equip_skill = _vineSkill,
	suit = 0,
	number = 2,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,_vineSkill,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,"_vine",true,true)
		return false
	end,
}
_vine:setParent(exclusive_cards)
_vine:clone(1,2):setParent(exclusive_cards)

mobileqiaosiCard = sgs.CreateSkillCard{
	name = "mobileqiaosiCard",
	target_fixed = true,
	on_use = function(self,room,source,targets)
		local time0 = os.time()--开始计时
		local qs = {qs_wang=0,qs_shang=0,qs_gong=0,qs_nong=0,qs_shi=0,qs_jiang=0}
		while source:isAlive()do
			if os.time()-time0>=10 then break end--时间限制10秒
			local choices = {}
			for ch,n in pairs(qs)do
				table.insert(choices,ch.."="..n)
			end
			local choice = room:askForChoice(source,"qs_shuizhuan",table.concat(choices,"+"))
			if os.time()-time0>=10 then break end--时间限制10秒
			if choice:startsWith("qs_wang") then qs.qs_wang = math.min(100,qs.qs_wang+33)
			elseif choice:startsWith("qs_shang") then qs.qs_shang = math.min(100,qs.qs_shang+75)
			elseif choice:startsWith("qs_gong") then qs.qs_gong = 100
			elseif choice:startsWith("qs_nong") then qs.qs_nong = 100
			elseif choice:startsWith("qs_shi") then qs.qs_shi = math.min(100,qs.qs_shi+75)
			elseif choice:startsWith("qs_jiang") then qs.qs_jiang = math.min(100,qs.qs_jiang+33) end
			local has = 0
			for ch,n in pairs(qs)do
				if n>99 then has = has+1 end
			end
			if has>2 then break end
			room:getThread():delay(math.random(100,250))--随机延迟
		end
		local ds = {}
		for _,id in sgs.qlist(room:getDrawPile())do
			table.insert(ds,sgs.Sanguosha:getCard(id))
		end
		for _,id in sgs.qlist(room:getDiscardPile())do
			table.insert(ds,sgs.Sanguosha:getCard(id))
		end
		ds = RandomList(ds)
		local function QScard(name,n)
			local cs = {}
			for _,c in ipairs(ds)do
				if c:isKindOf(name) or c:objectName()==name
				then table.insert(cs,c) end
				if #cs>=n then break end
			end
			for _,c in ipairs(cs)do
				table.removeOne(ds,c)
			end
			return cs
		end
		local cards = {}
		if qs.qs_wang>99 then
			for _,c in ipairs(QScard("TrickCard",2))do
				table.insert(cards,c)
			end
		end
		if qs.qs_shang>99 then
			local can = QScard("Slash",1)
			for _,c in ipairs(QScard("Analeptic",1))do
				table.insert(can,c)
			end
			if qs.qs_jiang<100 then
				for _,c in ipairs(QScard("EquipCard",2))do
					table.insert(can,c)
				end
			end
			if #can>0 then table.insert(cards,can[math.random(1,#can)]) end
		end
		if qs.qs_gong>99 then
			local can = QScard("Slash",2)
			for _,c in ipairs(QScard("Analeptic",1))do
				table.insert(can,c)
			end
			if #can>0 then table.insert(cards,can[math.random(1,#can)]) end
		end
		if qs.qs_nong>99 then
			local can = QScard("Jink",2)
			for _,c in ipairs(QScard("Peach",1))do
				table.insert(can,c)
			end
			if #can>0 then table.insert(cards,can[math.random(1,#can)]) end
		end
		if qs.qs_shi>99 then
			local can = QScard("Jink",1)
			for _,c in ipairs(QScard("Peach",1))do
				table.insert(can,c)
			end
			if qs.qs_wang<100 then
				for _,c in ipairs(QScard("TrickCard",2))do
					table.insert(can,c)
				end
			end
			if #can>0 then table.insert(cards,can[math.random(1,#can)]) end
		end
		if qs.qs_jiang>99 then
			for _,c in ipairs(QScard("EquipCard",2))do
				table.insert(cards,c)
			end
		end
		if #cards<1 or source:isDead() then return end
		local dc = dummyCard()
		for _,c in ipairs(cards)do
			dc:addSubcard(c)
		end
		room:obtainCard(source,dc)
		if source:isDead() then return end
		room:setPlayerMark(source,"mobileqiaosiNum",#cards)
		if room:askForUseCard(source,"@@mobileqiaosi!","mobileqiaosi0:"..#cards,-1,sgs.Card_MethodNone)
		or source:isDead() then return end
		local dc = mobileqiaosi2Card:clone()
		for _,c in ipairs(cards)do
			if source:isJilei(c) or dc:subcardsLength()>=#cards then continue end
			dc:addSubcard(c)
		end
		room:useCard(sgs.CardUseStruct(dc,source))
	end,
}
mobileqiaosi2Card = sgs.CreateSkillCard{
	name = "mobileqiaosi2Card",
	will_throw = false,
	skill_name = "mobileqiaosi",
	filter = function(self,targets,to_select,from)
		if from:isJilei(self) then return false end
		return #targets<1 and from:objectName() ~= to_select:objectName()
	end,
	feasible = function(self,targets,from)
		local n = 0
		if from:isJilei(self) then n = n+1 end
		return #targets>=n
	end,
	about_to_use = function(self,room,use)
		for _,to in sgs.qlist(use.to)do
			room:giveCard(use.from,to,self,"mobileqiaosi")
			return
		end
		room:throwCard(self,"mobileqiaosi",use.from)
	end,
}
mobileqiaosi = sgs.CreateViewAsSkill{
	name = "mobileqiaosi",
	n = 999,
	view_filter = function(self,selected,to_select)
		return sgs.Sanguosha:getCurrentCardUsePattern()=="@@mobileqiaosi!"
		and #selected<sgs.Self:getMark("mobileqiaosiNum")
	end,
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@mobileqiaosi!" then
			if #cards<sgs.Self:getMark("mobileqiaosiNum") then return end
			local dc = mobileqiaosi2Card:clone()
			for _,c in ipairs(cards)do
				dc:addSubcard(c)
			end
			return dc
		end
		return mobileqiaosiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#mobileqiaosiCard")<1
	end,
	enabled_at_response = function(self,player,pattern)
		if pattern=="@@mobileqiaosi!" then return true end
	end
}
mobile_majun:addSkill(mobileqiaosi)

sgs.Sanguosha:setPackage(mobile)








local mobileren = sgs.Sanguosha:getPackage("mobileren")

ren2_huaxin = sgs.General(mobileren,"ren2_huaxin","wei",3)
renyuanqing = sgs.CreateTriggerSkill{
    name = "renyuanqing",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed,sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and player:getPhase()==sgs.Player_Play then
				local ucids = player:getTag("renyuanqingUseIds"):toIntList()
				if use.card:isVirtualCard() then
					for _,id in sgs.qlist(use.card:getSubcards())do
						ucids:append(id)
					end
				else
					ucids:append(use.card:getEffectiveId())
				end
				player:setTag("renyuanqingUseIds",ToData(ucids))
			end
		elseif player:getPhase() == sgs.Player_Play then
			local ucids = player:getTag("renyuanqingUseIds"):toIntList()
			player:removeTag("renyuanqingUseIds")
			if ucids:length()>0 and player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				local cs = {}
				for _,id in sgs.qlist(room:getDiscardPile())do
					if ucids:contains(id) then
						table.insert(cs,sgs.Sanguosha:getCard(id))
					end
				end
				local ctype = {}
				while #cs>0 do
					local c = cs[math.random(1,#cs)]
					table.removeOne(cs,c)
					if ctype[c:getType()] then continue end
					ctype[c:getType()] = true
					--addRenPile(c,player,self)
					player:addToRenPile(c,self:objectName())
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
ren2_huaxin:addSkill(renyuanqing)
renshuchen = sgs.CreateTriggerSkill{
	name = "renshuchen",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Dying},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
		local ids = room:getTag("ren_pile"):toIntList()
		if ids:length()<4 then return end
		room:sendCompulsoryTriggerLog(player,self)
		local slash = dummyCard()
		slash:addSubcards(ids)
		room:obtainCard(player,slash)
		room:recover(dying.who,sgs.RecoverStruct(self:objectName(),player))
	end,
}
ren2_huaxin:addSkill(renshuchen)

ren_zhangwen = sgs.General(mobileren,"ren_zhangwen","wu",3)
rengebo = sgs.CreateTriggerSkill{
    name = "rengebo",
	events = {sgs.HpRecover},
	frequency = sgs.Skill_Compulsory,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local recover = data:toRecover()
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
			if recover.recover > 0 then
				room:sendCompulsoryTriggerLog(p,self)
				--addRenPile(room:drawCard(),p,self)
				p:addToRenPile(room:drawCard(),self:objectName())
			end
		end
	end,
	can_trigger = function(self,player)
	    return player and player:isAlive()
	end,
}
ren_zhangwen:addSkill(rengebo)
rensongshu = sgs.CreateTriggerSkill{
	name = "rensongshu",
	events = {sgs.EventPhaseStart},
	waked_skills = "#rensongshuFlag",
	on_trigger = function(self,event,player,data,room)
		if player:getPhase() == sgs.Player_Draw then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
				local card_ids = room:getTag("ren_pile"):toIntList()
			    if player:getHp()<=p:getHp() or card_ids:isEmpty()
				or not p:askForSkillInvoke(self,ToData(player))
				then continue end
				room:broadcastSkillInvoke(self:objectName())
				local dc = dummyCard()
				for i = 1,math.min(5,p:getHp())do
				    if card_ids:isEmpty() then break end
					room:fillAG(card_ids,player)
				    local id = room:askForAG(player,card_ids,false,self:objectName())
				    card_ids:removeOne(id)
					dc:addSubcard(id)
				    room:clearAG(player)
			    end
				room:obtainCard(player,dc)
				room:setPlayerFlag(player,"rensongshuBf")
				return true
			end
		end
		return false
	end,
	can_trigger = function(self,player)
	    return player and player:isAlive()
	end
}
rensongshuFlag = sgs.CreateProhibitSkill{
	name = "#rensongshuFlag",
	is_prohibited = function(self,from,to,card)
		return from:hasFlag("rensongshuBf") and from~=to
		and card:getTypeId()>0
	end
}
ren_zhangwen:addSkill(rensongshu)
ren_zhangwen:addSkill(rensongshuFlag)

ren_qiaogong = sgs.General(mobileren,"ren_qiaogong","wu",3)
renyizhu = sgs.CreateTriggerSkill{
	name = "renyizhu",
	events = {sgs.EventPhaseProceeding,sgs.TargetSpecifying,sgs.CardFinished},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseProceeding then
			if player:getPhase() == sgs.Player_Finish and player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				player:drawCards(2,self:objectName())
				local ids = player:property("renyizhuIds"):toIntList()
				local names = player:property("renyizhuNames"):toString():split("+")
				local dc = room:askForExchange(player,self:objectName(),2,2,true,"@renyizhu")
				local n = room:getAlivePlayers():length()*2
				for _,id in sgs.qlist(dc:getSubcards())do
					local c = sgs.Sanguosha:getCard(id)
					ids:append(id)
					room:moveCardsInToDrawpile(player,id,self:objectName(),math.random(1,n))
					if table.contains(names,c:objectName()) then continue end
					table.insert(names,c:objectName())
				end
				names = sgs.QVariant(table.concat(names,"+"))
				room:setPlayerProperty(player,"renyizhuNames",names)
				room:setPlayerProperty(player,"renyizhuIds",ToData(ids))
			end
		elseif event == sgs.TargetSpecifying then
			local use = data:toCardUse()
			if use.to:length() ~= 1 then return false end
			for _,qg in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
				local ids = qg:property("renyizhuIds"):toIntList()
				if ids:contains(use.card:getId()) and player~=qg then
					local names = qg:property("renyizhuNames"):toString():split("+")
					if table.contains(names,use.card:objectName())
					and qg:askForSkillInvoke(self,data) then
						ids:removeOne(use.card:getId())
						qg:peiyin(self)
						table.removeOne(names,use.card:objectName())
						names = sgs.QVariant(table.concat(names,"+"))
						room:setPlayerProperty(qg,"renyizhuNames",names)
						room:setPlayerProperty(qg,"renyizhuIds",ToData(ids))
						use.to:removeOne(use.to:first())
						data:setValue(use)
						break
					end
				end
			end
		end
		return false
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
ren_qiaogong:addSkill(renyizhu)
renluanchouCard = sgs.CreateSkillCard{
    name = "renluanchouCard",
	target_fixed = true,
	on_use = function(self,room,source,targets)
		local players = room:getAlivePlayers()
		for _,p in sgs.qlist(players)do
	        p:loseAllMarks("&luanchouyin")
		end
		local targetz = room:askForPlayersChosen(source,players,self:getSkillName(),2,2,"renluanchou_doubles")
		for _,p in sgs.qlist(targetz)do
			room:doAnimate(1,source:objectName(),p:objectName())
			p:gainMark("&luanchouyin")
		end
	end,
}
renluanchouvs = sgs.CreateZeroCardViewAsSkill{
    name = "renluanchou",
	view_as = function()
		return renluanchouCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#renluanchouCard")
	end,
}
renluanchou = sgs.CreateTriggerSkill{
	name = "renluanchou",
	events = {sgs.MarkChanged},
	waked_skills = "rengonghuan",
	view_as_skill = renluanchouvs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.name == "&luanchouyin" then
			    if player:getMark(mark.name) > 0 then
				    room:acquireSkill(player,"rengonghuan")
				else
				    room:detachSkillFromPlayer(player,"rengonghuan")
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
ren_qiaogong:addSkill(renluanchou)
rengonghuan = sgs.CreateTriggerSkill{
	name = "rengonghuan",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.DamageInflicted,sgs.DamageComplete},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.DamageInflicted then
			local damage = data:toDamage()
			for _,p in sgs.qlist(room:getOtherPlayers(player))do
				if p:getMark("rengonghuan-Clear")<1 and player:getHp()<=p:getHp() and p:hasSkill(self) then
					room:sendCompulsoryTriggerLog(p,self)
					damage.transfer = true
					damage.to = p
					local tips = damage.tips
					table.insert(tips,"rengonghuanDamage:"..p:objectName()..":"..player:objectName())
					damage.tips = tips
					data:setValue(damage)
					player:setTag("TransferDamage",data)
					p:addMark("rengonghuan-Clear")
					return true
				end
			end
		else
			local damage = data:toDamage()
		    for _,tip in sgs.list(damage.tips)do
	            if tip:startsWith("rengonghuanDamage:") then
					local ts = tip:split(":")
					for _,p in sgs.qlist(room:getAlivePlayers())do
						if table.contains(ts,p:objectName())
						then p:loseMark("&luanchouyin") end
					end
				end
		    end
		end
		return false
	end,
	can_trigger = function(self,player)
		return player and player:getMark("&luanchouyin")>0
	end,
}
mobileren:addSkills(rengonghuan)

ren_zhangji = sgs.General(mobileren,"ren_zhangji","qun",3)
renjishi = sgs.CreateTriggerSkill{
    name = "renjishi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardsMoveOneTime,sgs.BeforeCardsMove},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceTable) then
				local renPile = player:getTag("ren_pile"):toIntList()
				if renPile:length()>0 then
					if move.reason.m_reason~=sgs.CardMoveReason_S_REASON_RULEDISCARD
					or move.reason.m_eventName~="removeRenPile" then
						for _,id in sgs.qlist(move.card_ids)do
							if renPile:contains(id) then
								room:sendCompulsoryTriggerLog(player,self)
								player:drawCards(1,self:objectName())
								break
							end
						end
					end
				end
			end
			if move.reason.m_reason==sgs.CardMoveReason_S_REASON_USE
			and move.to_place == sgs.Player_DiscardPile then
				local use = move.reason.m_useStruct
				if use.card and use.card:getTypeId()>0 and not use.card:hasFlag("DamageDone")
				and room:getCardPlace(use.card:getEffectiveId())==sgs.Player_DiscardPile
				and use.from==player then
					room:sendCompulsoryTriggerLog(player,self)
					player:addToRenPile(use.card,self:objectName())
					--addRenPile(use.card,player,self)
				end
			end
		else
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceTable) then
				player:setTag("ren_pile",room:getTag("ren_pile"))
			end
		end
	end,
}
ren_zhangji:addSkill(renjishi)
renliaoyi = sgs.CreateTriggerSkill{
	name = "renliaoyi",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart
		and player:getPhase()==sgs.Player_RoundStart then
			local n = player:getHp()-player:getHandcardNum()
			if n>0 then
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:hasSkill(self) then
						local ids = room:getTag("ren_pile"):toIntList()
						n = math.min(player:getHp()-player:getHandcardNum(),4)
						if n>0 and ids:length()>=n and p:askForSkillInvoke(self,ToData(player)) then
							room:broadcastSkillInvoke(self:objectName())
							local dc = dummyCard()
							for i = 1,n do
								if ids:isEmpty() then break end
								room:fillAG(ids,p)
								local id = room:askForAG(p,ids,false,self:objectName())
								ids:removeOne(id)
								dc:addSubcard(id)
								room:clearAG(p)
							end
							room:obtainCard(player,dc)
						end
					end
				end
			elseif n<0 then
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:hasSkill(self) then
						n = math.min(player:getHandcardNum()-player:getHp(),4)
						if n>0 and p:askForSkillInvoke(self,ToData(player)) then
							room:broadcastSkillInvoke(self:objectName())
							local dc = room:askForExchange(player,self:objectName(),n,n,false,"renliaoyi0:"..n)
							player:addToRenPile(dc,self:objectName())
							--addRenPile(dc,player,self)
						end
					end
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
ren_zhangji:addSkill(renliaoyi)
renbinglunCard = sgs.CreateSkillCard{
	name = "renbinglunCard",
	target_fixed = false,
	--will_throw = false,
	filter = function(self,targets,to_select,source)
		return #targets<1
	end,
	about_to_use = function(self,room,use)
		local ids = room:getTag("ren_pile"):toIntList()
		if ids:isEmpty() then return end
		room:fillAG(ids,use.from)
		local id = room:askForAG(use.from,ids,false,self:getSkillName())
		self:addSubcard(id)
		room:clearAG(use.from)
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source,targets)
		for _,p in sgs.list(targets)do
			if room:askForChoice(p,self:getSkillName(),"renbinglun1+renbinglun2")=="renbinglun1" then
				p:drawCards(1,self:getSkillName())
			else
				room:setPlayerMark(p,"&renbinglun",1)
				p:setFlags("renbinglun")
			end
		end
	end,
}
renbinglunvs = sgs.CreateViewAsSkill{
	name = "renbinglun",
	view_as = function(self,cards)
		return renbinglunCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#renbinglunCard")
	end,
}
renbinglun = sgs.CreateTriggerSkill{
	name = "renbinglun",
	events = {sgs.EventPhaseChanging},
	view_as_skill = renbinglunvs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to~=sgs.Player_NotActive or player:hasFlag("renbinglun") then return end
			room:setPlayerMark(player,"&renbinglun",0)
			room:recover(player,sgs.RecoverStruct(self:objectName()))
		end
	end,
	can_trigger = function(self,player)
		return player and player:getMark("&renbinglun")>0
	end,
}
ren_zhangji:addSkill(renbinglun)

mobile_shenhuatuo = sgs.General(mobileren,"mobile_shenhuatuo","god",3)
mobile_wulingCard = sgs.CreateSkillCard{
	name = "mobile_wulingCard",
	target_fixed = false,
	--will_throw = false,
	filter = function(self,targets,to_select,source)
		return #targets<1 and to_select:getMark("mobile_wuling")<1
	end,
	on_use = function(self,room,source,targets)
		for _,p in sgs.list(targets)do
			local choices = {"wl_hu_mark","wl_lu_mark","wl_xiong_mark","wl_yuan_mark","wl_he_mark"}
			local wlMark = {}
			while #choices>0 do
				local choice = room:askForChoice(source,self:getSkillName(),table.concat(choices,"+"),ToData(p))
				table.insert(wlMark,choice)
				table.removeOne(choices,choice)
			end
			room:setPlayerMark(p,"mobile_wuling",#wlMark)
			choices = table.concat(wlMark,"+").."+#wlMark"
			room:setPlayerMark(p,"&"..choices,1)
			p:gainMark(wlMark[1])
		end
	end,
}
mobile_wulingvs = sgs.CreateViewAsSkill{
	name = "mobile_wuling",
	view_as = function()
		return mobile_wulingCard:clone()
	end,
	enabled_at_play = function(self,player)
		if player:usedTimes("#mobile_wulingCard")>1
		then return false end
		local tos = player:getAliveSiblings()
		tos:append(player)
		for _,p in sgs.list(tos)do
			if p:getMark("mobile_wuling")<1
			then return true end
		end
		return false
	end,
}
mobile_wuling = sgs.CreateTriggerSkill{
    name = "mobile_wuling",
	frequency = sgs.Skill_NotFrequent,
	view_as_skill = mobile_wulingvs,
	events = {sgs.EventPhaseStart,sgs.MarkChanged,sgs.TargetSpecified,sgs.DamageCaused,sgs.DamageInflicted},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart then
		    if player:getPhase()~=sgs.Player_Start
			or player:getMark("mobile_wuling")<1 then return false end
			local wl = ""
			for _,m in sgs.list(player:getMarkNames())do
				if m:endsWith("+#wlMark")
				and player:getMark(m)>0
				then wl = m break end
			end
			if wl~="" then
				room:setPlayerMark(player,wl,0)
				room:setPlayerMark(player,"mobile_wuling",0)
				wl = string.sub(wl,2,-1)
				local ms = wl:split("+")
				if #ms>1 then
					room:sendCompulsoryTriggerLog(player,self)
					local ms1,ms2 = ms[1],ms[2]
					table.removeOne(ms,ms1)
					player:loseMark(ms1)
					if ms2~="#wlMark" then
						room:setPlayerMark(player,"&"..table.concat(ms,"+"),1)
						room:setPlayerMark(player,"mobile_wuling",#ms)
						player:gainMark(ms2)
					end
				end
			end
		elseif event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.card and damage.card:hasFlag("wl_hu_mark") then
				room:sendCompulsoryTriggerLog(player,"wl_hu_mark")
				damage.damage = damage.damage+1
				data:setValue(damage)
			end
		elseif event == sgs.DamageInflicted then
			local damage = data:toDamage()
			if player:getMark("wl_xiong_mark")>0
			and player:getMark("wl_xiong_mark-Clear")<1 then
				player:addMark("wl_xiong_mark-Clear")
				room:sendCompulsoryTriggerLog(player,"wl_xiong_mark")
				damage.damage = damage.damage-1
				data:setValue(damage)
				return damage.damage<1
			end
		elseif event == sgs.TargetSpecified then
			local use = data:toCardUse()
			if player:getMark("wl_hu_mark")<1
			or use.card:getTypeId()<1
			or use.to:length()~=1
			then return false end
			room:setCardFlag(use.card,"wl_hu_mark")
		elseif event == sgs.MarkChanged then
			local mark = data:toMark()
			if mark.gain>0 then
				if mark.name=="wl_lu_mark" then
					room:sendCompulsoryTriggerLog(player,mark.name)
					room:recover(player,sgs.RecoverStruct(mark.name))
					local ids = player:getJudgingAreaID()
					if ids:length()>0 then
						local dc = dummyCard()
						dc:addSubcards(ids)
						room:throwCard(dc,mark.name,nil)
					end
				elseif mark.name=="wl_yuan_mark" then
					room:sendCompulsoryTriggerLog(player,mark.name)
					local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),mark.name,"wl_yuan_mark0:",false,true)
					if to and to:hasEquip() then
						local c = to:getEquips():at(math.random(0,to:getEquips():length()-1))
						room:obtainCard(player,c)
					end
				elseif mark.name=="wl_he_mark" then
					room:sendCompulsoryTriggerLog(player,mark.name)
					player:drawCards(3,mark.name)
				end
			end
		end
	end,
	can_trigger = function(self,player)
	    return player and player:isAlive()
	end,
}
mobile_shenhuatuo:addSkill(mobile_wuling)
mobile_wulingbf = sgs.CreateProhibitSkill{
	name = "#mobile_wulingbf",
	is_prohibited = function(self,from,to,card)
		if card:isKindOf("DelayedTrick") and to:getMark("wl_lu_mark")>0
		then self:setObjectName("wl_lu_mark") return true end
		self:setObjectName("#mobile_wulingbf")
		return false
	end
}
mobile_shenhuatuo:addSkill(mobile_wulingbf)
mobile_youyiCard = sgs.CreateSkillCard{
	name = "mobile_youyiCard",
	target_fixed = true,
	--will_throw = false,
	about_to_use = function(self,room,use)
		local ids = room:getTag("ren_pile"):toIntList()
		if ids:isEmpty() then return end
		for _,p in sgs.list(room:getAllPlayers())do
			use.to:append(p)
		end
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source,targets)
		room:doSuperLightbox(source,self:getSkillName())
		local ids = room:getTag("ren_pile"):toIntList()
		local dc = dummyCard()
		dc:addSubcards(ids)
		room:throwCard(dc,self:getSkillName(),source)
		for _,p in sgs.list(targets)do
			room:recover(p,sgs.RecoverStruct(self:getSkillName(),source))
		end
	end,
}
mobile_youyivs = sgs.CreateViewAsSkill{
	name = "mobile_youyi",
	view_as = function(self,cards)
		return mobile_youyiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#mobile_youyiCard")<1
	end,
}
mobile_youyi = sgs.CreateTriggerSkill{
	name = "mobile_youyi",
	events = {sgs.EventPhaseEnd,sgs.CardsMoveOneTime},
	view_as_skill = mobile_youyivs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseEnd then
			local ids = sgs.IntList()
			for _,id in sgs.qlist(player:getTag("youyiDiscard"):toIntList())do
				if room:getCardPlace(id)==sgs.Player_DiscardPile
				and not ids:contains(id) then ids:append(id) end
			end
			if player:hasSkill(self) and ids:length()>0
			and player:askForSkillInvoke(self) then
				room:broadcastSkillInvoke(self:objectName())
				local dc = dummyCard()
				dc:addSubcards(ids)
				--addRenPile(dc,player,self)
				player:addToRenPile(dc,self:objectName())
			end
			player:removeTag("youyiDiscard")
		else
			local move = data:toMoveOneTime()
			if bit32.band(move.reason.m_reason,sgs.CardMoveReason_S_MASK_BASIC_REASON)~=sgs.CardMoveReason_S_REASON_DISCARD
			then return end
			local ids = player:getTag("youyiDiscard"):toIntList()
			for _,id in sgs.qlist(move.card_ids)do
				ids:append(id)
			end
			player:setTag("youyiDiscard",ToData(ids))
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
		and player:getPhase()==sgs.Player_Discard
	end,
}
mobile_shenhuatuo:addSkill(mobile_youyi)

mobile_shenlusu = sgs.General(mobileren,"mobile_shenlusu","god",3)
mobile_tamo = sgs.CreateTriggerSkill{
	name = "mobile_tamo",
	events = {sgs.GameStart},
	view_as_skill = mobile_youyivs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.GameStart then
			if player:askForSkillInvoke(self) then
				room:broadcastSkillInvoke(self:objectName())
				local aps = room:getAlivePlayers()
				if string.find(room:getMode(),"p") then
					aps = room:getOtherPlayers(room:getLord())
				end
				if aps:length()<2 then return end
				local ids = room:getNCards(aps:length(),false)
				local pt = {}
				for i,id in sgs.qlist(ids)do
					room:setCardTip(id,aps:at(i):getGeneralName())
					pt[id] = aps:at(i)
				end
				local ids2 = room:askForGuanxing(player,ids,1)
				room:getNCards(aps:length(),false)
				room:returnToTopDrawPile(ids)--防止改变牌堆
				for _,id in sgs.qlist(ids)do
					room:clearCardTip(id)
				end
				local ps = sgs.QList2Table(room:getAlivePlayers())
				local n = #ps
				for _,id in sgs.list(sgs.reverse(ids2))do
					if pt[id]:getSeat()~=n then
						for _,p in sgs.list(ps)do
							if p:getSeat()==n then
								room:swapSeat(pt[id],p)
								break
							end
						end
					end
					n = n-1
				end
				if #ps==aps:length() then
					room:setCurrent(pt[ids2:last()])
				end
			end
		end
	end,
}
mobile_shenlusu:addSkill(mobile_tamo)
mobile_dingzouCard = sgs.CreateSkillCard{
	name = "mobile_dingzouCard",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		return #targets<1 and from:objectName() ~= to_select:objectName()
		and self:subcardsLength()==to_select:getEquips():length()+to_select:getJudgingArea():length()
	end,
	on_effect = function(self,effect)
		if effect.from:isDead() or effect.to:isDead() then return end
		local room = effect.from:getRoom()
		room:giveCard(effect.from,effect.to,self,self:getSkillName())
		if effect.from:isDead() then return end
		local dc = dummyCard()
		dc:addSubcards(effect.to:getCards("ej"))
		room:obtainCard(effect.from,dc)
	end,
}
mobile_dingzou = sgs.CreateViewAsSkill{
	name = "mobile_dingzou",
	n = 999,
	view_filter = function(self,selected,to_select)
		return true
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local skill = mobile_dingzouCard:clone()
		for _,c in ipairs(cards)do
			skill:addSubcard(c)
		end
		return skill
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#mobile_dingzouCard")<1
	end,
}
mobile_shenlusu:addSkill(mobile_dingzou)
mobile_zhimeng = sgs.CreateTriggerSkill{
	name = "mobile_zhimeng",
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to~=sgs.Player_NotActive then return end
		local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"mobile_zhimeng0:",true,true)
		if to then
			room:broadcastSkillInvoke(self:objectName())
			local hs = to:handCards()
			for _,id in sgs.qlist(player:handCards())do
				hs:append(id)
			end
			local n = hs:length()
			local hs1 = sgs.IntList()
			while hs:length()>n/2 do
				local id = hs:at(math.random(0,hs:length()-1))
				hs1:append(id)
				hs:removeOne(id)
			end
			local move1 = sgs.CardsMoveStruct()
			for _,id in sgs.qlist(to:handCards())do
				if hs1:contains(id) then
					move1.card_ids:append(id)
				end
			end
			move1.to = player
			move1.to_place = sgs.Player_PlaceHand
			move1.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,to:objectName(),player:objectName(),self:objectName(),"")
			local move2 = sgs.CardsMoveStruct()
			for _,id in sgs.qlist(player:handCards())do
				if hs:contains(id) then
					move2.card_ids:append(id)
				end
			end
			move2.to = to
			move2.to_place = sgs.Player_PlaceHand
			move2.reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_SWAP,player:objectName(),to:objectName(),self:objectName(),"")
			local moves = sgs.CardsMoveList()
			moves:append(move1)
			moves:append(move2)
			room:moveCardsAtomic(moves,false)
		end
	end,
}
mobile_shenlusu:addSkill(mobile_zhimeng)


sgs.Sanguosha:setPackage(mobileren)



local mobileyan = sgs.Sanguosha:getPackage("mobileyan")

yan_liuba = sgs.General(mobileyan,"yan_liuba","shu",3)
yanduanbiCard = sgs.CreateSkillCard{
	name = "yanduanbiCard",
	target_fixed = true,
	on_use = function(self,room,source,targets)
		room:removePlayerMark(source,"@yanduanbi")
		for _,p in sgs.qlist(room:getOtherPlayers(source))do
			room:doAnimate(1,source:objectName(),p:objectName())
		end
		room:doSuperLightbox(source,self:getSkillName())
		local ids = {}
		for _,p in sgs.qlist(room:getOtherPlayers(source))do
			local n = math.min(3,p:getHandcardNum()/2)
			if n<1 then continue end
			local dc = room:askForDiscard(p,self:getSkillName(),n,n)
			for _,id in sgs.qlist(dc:getSubcards())do
				if room:getCardPlace(id)~=sgs.Player_DiscardPile then continue end
				table.insert(ids,id)
			end
		end
		if #ids<1 then return end
		local to = room:askForPlayerChosen(source,room:getAlivePlayers(),self:getSkillName(),"yanduanbi0:",true)
		if to then
			local dummy = dummyCard()
			room:doAnimate(1,source:objectName(),to:objectName())
			while dummy:subcardsLength()<3 and #ids > 0 do
				local id = ids[math.random(1,#ids)]
				dummy:addSubcard(id)
				table.removeOne(ids,id)
			end
			room:obtainCard(to,dummy)
		end
	end,
}
yanduanbi = sgs.CreateZeroCardViewAsSkill{
	name = "yanduanbi",
	frequency = sgs.Skill_Limited,
	limit_mark = "@yanduanbi",
	view_as = function()
		return yanduanbiCard:clone()
	end,
	enabled_at_play = function(self,player)
		local whcn,count = player:getHandcardNum(),1
		for _,p in sgs.qlist(player:getAliveSiblings())do
			whcn = whcn + p:getHandcardNum()
			count = count + 1
		end
		return player:getMark("@yanduanbi") > 0 and whcn > count*2
	end,
}
yan_liuba:addSkill(yanduanbi)
yantongdu = sgs.CreateTriggerSkill{
    name = "yantongdu",
	events = {sgs.TargetConfirming},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.to:length()~=1 or use.card:getTypeId()<1 or use.from==player
		or player:getMark("yantongdu-Clear")>0 then return false end
		local tos = sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers())do
			if p:getCardCount()>0 then tos:append(p) end
		end
		local to = room:askForPlayerChosen(player,tos,self:objectName(),"yantongdu0",true,true)
		if not to then return false end
		room:addPlayerMark(player,"yantongdu-Clear")
		room:broadcastSkillInvoke(self:objectName())
		local c = room:askForCard(to,"..!","yantongdu1:",data,sgs.Card_MethodRecast)
		if c==nil then
			for _,h in sgs.qlist(to:getCards("he"))do
				if to:isCardLimited(h,sgs.Card_MethodRecast)
				then continue end
				c = h
				break
			end
			if c==nil then return false end
		end
		room:broadcastSkillInvoke("@recast")
		local log = sgs.LogMessage()
		log.type = "#UseCard_Recast"
		log.from = to
		log.card_str = c:toString()
		room:sendLog(log)
		log = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_RECAST,to:objectName(),self:objectName(),"")
		room:moveCardTo(c,to,nil,sgs.Player_DiscardPile,log,true)
		to:drawCards(1,"recast")
	end,
}
yan_liuba:addSkill(yantongdu)

yan_lvfan = sgs.General(mobileyan,"yan_lvfan","wu",3)
yandiaodu = sgs.CreateTriggerSkill{
	name = "yandiaodu",
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if player:getPhase()~=sgs.Player_Start then return end
		local players,targets = sgs.SPlayerList(),sgs.SPlayerList()
		for _,p in sgs.qlist(room:getAlivePlayers())do
		    for _,e in sgs.qlist(p:getEquips())do
				local n = e:getRealCard():toEquipCard():location()
				for _,q in sgs.qlist(room:getOtherPlayers(p))do
					if q:hasEquipArea(n) and q:getEquip(n)==nil
					then
						n = -2
						break
					end
				end
				if n==-2 then
					players:append(p)
					break
				end
			end
		end
		if players:length()>0 then
		    local target = room:askForPlayerChosen(player,players,self:objectName(),"@yandiaodutarget",true,true)
			if target then
				room:broadcastSkillInvoke(self:objectName())
				local noids = sgs.IntList()
				for _,e in sgs.qlist(target:getEquips())do
					local n = e:getRealCard():toEquipCard():location()
					for _,q in sgs.qlist(room:getOtherPlayers(target))do
						if q:hasEquipArea(n) and q:getEquip(n)==nil then
							n = -2
							break
						end
					end
					if n~=-2 then
						noids:append(e:getEffectiveId())
					end
				end
				local id = room:askForCardChosen(player,target,"e",self:objectName(),false,sgs.Card_MethodNone,noids)
				if id<0 then return end
				local c = sgs.Sanguosha:getCard(id)
				local n = c:getRealCard():toEquipCard():location()
				for _,q in sgs.qlist(room:getOtherPlayers(target))do
					if q:hasEquipArea(n) and q:getEquip(n)==nil
					then targets:append(q) end
				end
				if targets:length()>0 then
				    local to = room:askForPlayerChosen(player,targets,"yandiaodu_to","@yandiaoduto",false,false)
					room:doAnimate(1,player:objectName(),to:objectName())
					room:moveCardTo(c,to,sgs.Player_PlaceEquip,true)
					room:drawCards(target,1,self:objectName())
				end
			end
		end
	end,
}
yan_lvfan:addSkill(yandiaodu)
yandiancai = sgs.CreateTriggerSkill{
	name = "yandiancai",
	events = {sgs.CardsMoveOneTime,sgs.EventPhaseEnd},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.CardsMoveOneTime then
			local move = data:toMoveOneTime()
			if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and move.from:objectName() == player:objectName()
			and not(move.to and (move.to:objectName()==player:objectName() and (move.to_place==sgs.Player_PlaceHand or move.to_place==sgs.Player_PlaceEquip)))
			and player:hasSkill(self,true) then room:addPlayerMark(player,"&yandiancai-PlayClear") end
		elseif event == sgs.EventPhaseEnd and player:getPhase() == sgs.Player_Play then
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
				if p~=player and p:getMaxHp()>p:getHandcardNum()
				and p:getMark("&yandiancai-PlayClear")>=p:getHp()
				and p:askForSkillInvoke(self) then
					room:broadcastSkillInvoke(self:objectName())
					p:drawCards(p:getMaxHp()-p:getHandcardNum(),self:objectName())
				end
			end
		end
	end,
	can_trigger = function(self,target)
		return target and target:isAlive()
	end
}
yan_lvfan:addSkill(yandiancai)
yanyanji = sgs.CreateTriggerSkill{
    name = "yanyanji",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventForDiy},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play
			or not player:askForSkillInvoke(self) then return false end
			room:broadcastSkillInvoke(self:objectName())
			ZhengsuChoice(player)
		elseif event == sgs.EventForDiy then
	     	local zs = data:toString()
			if zs:startsWith("zhengsu:") then
				
			end
		end
	end,
}
yan_lvfan:addSkill(yanyanji)

yan_huangfusong = sgs.General(mobileyan,"yan_huangfusong","qun",4)
yantaoluan = sgs.CreateTriggerSkill{
    name = "yantaoluan",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.FinishRetrial},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.FinishRetrial then
			local judge = data:toJudge()
			if judge.card:getSuit()~=sgs.Card_Spade then return false end
			for _,zys in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
				if zys:getMark("yantaoluanUse-Clear")<1
				and zys:askForSkillInvoke(self,data) then
					zys:addMark("yantaoluanUse-Clear")
					room:broadcastSkillInvoke(self:objectName())
					local choice = "yantaoluan1"
					if zys~=player then choice = "yantaoluan1+yantaoluan2" end
					if room:askForChoice(zys,self:objectName(),choice,data)=="yantaoluan1" then
						room:obtainCard(zys,judge.card)
					else
						local dc = dummyCard("fire_slash")
						dc:setSkillName("_"..self:objectName())
						if zys:canSlash(player,dc,false) then
							room:useCard(sgs.CardUseStruct(dc,zys,player),true)
						end
					end
					return true
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
yan_huangfusong:addSkill(yantaoluan)
yanshiji = sgs.CreateTriggerSkill{
    name = "yanshiji",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.DamageCaused},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.DamageCaused then
			local damage = data:toDamage()
			if damage.to~=player and damage.nature~=sgs.DamageStruct_Normal then
				for _,p in sgs.qlist(room:getOtherPlayers(player))do
					if p:getHandcardNum()>=player:getHandcardNum() then
						if player:askForSkillInvoke(self,ToData(damage.to)) then
							room:broadcastSkillInvoke(self:objectName())
							room:doGongxin(player,damage.to,damage.to:handCards(),self:objectName())
							local dc = dummyCard()
							for _,h in sgs.qlist(damage.to:getHandcards())do
								if h:isRed() and player:canDiscard(damage.to,h:getId())
								then dc:addSubcard(h) end
							end
							if dc:subcardsLength()<1 then break end
							room:throwCard(dc,damage.to,player)
							if player:isAlive() then
								player:drawCards(dc:subcardsLength(),self:objectName())
							end
						end
						break
					end
				end
			end
		end
	end,
}
yan_huangfusong:addSkill(yanshiji)
yanzhengjun = sgs.CreateTriggerSkill{
    name = "yanzhengjun",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventForDiy},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart then
			if player:getPhase() ~= sgs.Player_Play
			or not player:askForSkillInvoke(self) then return false end
			room:broadcastSkillInvoke(self:objectName())
			ZhengsuChoice(player)
		elseif event == sgs.EventForDiy then
	     	local zs = data:toString()
			if zs:startsWith("zhengsu:") then
				local zss = zs:split(":")
				if zss[3]=="zhengsu_successful" then
					local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"yanzhengjun0:"..zss[4],true,true)
					if to then
						if room:askForChoice(to,"zhengsu","drawCards_2+recover_1")~="drawCards_2"
						then room:recover(to,sgs.RecoverStruct("zhengsu"))
						else to:drawCards(2,"zhengsu") end
					end
				end
			end
		end
	end,
}
yan_huangfusong:addSkill(yanzhengjun)

yan_zhujun = sgs.General(mobileyan,"yan_zhujun","qun",4)
yanyangjieCard = sgs.CreateSkillCard{
	name = "yanyangjieCard",
	target_fixed = false,
	--will_throw = false,
	filter = function(self,targets,to_select,source)
		return #targets<1 and source:objectName()~=to_select:objectName()
		and source:canPindian(to_select)
	end,
	on_use = function(self,room,source,targets)
		for _,p in sgs.list(targets)do
			if source:pindian(p,self:getSkillName()) then continue end
			local dc = dummyCard("fire_slash")
			dc:setSkillName("_"..self:getSkillName())
		    local players = sgs.SPlayerList()
		    for _,q in sgs.qlist(room:getOtherPlayers(p))do
				if q~=source and q:canSlash(p,dc,false)
				then players:append(q) end
			end
			local from = room:askForPlayerChosen(source,players,self:objectName(),"yanyangjie0:"..p:objectName(),false,false)
			if from then room:useCard(sgs.CardUseStruct(dc,from,p),true) end
		end
	end,
}
yanyangjie = sgs.CreateViewAsSkill{
	name = "yanyangjie",
	view_as = function()
		return yanyangjieCard:clone()
	end,
	enabled_at_play = function(self,player)
		return not player:hasUsed("#yanyangjieCard") and player:canPindian()
	end,
}
yan_zhujun:addSkill(yanyangjie)
yanjuxiang = sgs.CreateTriggerSkill{
	name = "yanjuxiang",
	frequency = sgs.Skill_Limited,
	events = {sgs.QuitDying},
	limit_mark = "@yanjuxiang",
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local dying = data:toDying()
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
		    if p:getMark("@yanjuxiang")<1 or p == dying.who
			or not p:askForSkillInvoke(self,ToData(dying.who))
			then continue end
			room:broadcastSkillInvoke(self:objectName())
			room:removePlayerMark(p,"@yanjuxiang")
			room:doSuperLightbox(p,self:objectName())
			room:damage(sgs.DamageStruct(self:objectName(),p,dying.who))
		end
	end,
	can_trigger = function(self,player)
	    return player and player:isAlive()
	end,
}
yan_zhujun:addSkill(yanjuxiang)
yanhoufeng = sgs.CreateTriggerSkill{
    name = "yanhoufeng",
	frequency = sgs.Skill_NotFrequent,
	events = {sgs.EventPhaseStart,sgs.EventForDiy},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart then
		    if player:getPhase() ~= sgs.Player_Play then return false end
			for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
				if p:inMyAttackRange(player)
				and p:askForSkillInvoke(self,ToData(player)) then
					room:broadcastSkillInvoke(self:objectName(),1)
					local n = ZhengsuChoice(player)
					if n<0 then continue end
					p:setMark(player:objectName().."ZhengsuChoice-Clear",n)
				end
			end
		elseif event == sgs.EventForDiy then
	     	local zs = data:toString()
			if zs:startsWith("zhengsu:") then
				local zss = zs:split(":")
				for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
					if zss[3]=="zhengsu_successful" and p:getMark(player:objectName().."ZhengsuChoice-Clear")==tonumber(zss[2]) then
						if room:askForChoice(p,"zhengsu","drawCards_2+recover_1")~="drawCards_2"
						then room:recover(p,sgs.RecoverStruct("zhengsu"))
						else p:drawCards(2,"zhengsu") end
					end
				end
			end
		end
	end,
	can_trigger = function(self,player)
	    return player and player:isAlive()
	end,
}
yan_zhujun:addSkill(yanhoufeng)


sgs.Sanguosha:setPackage(mobileyan)



local god = sgs.Sanguosha:getPackage("ol_god")

--神孙权
ol_shensunquan = sgs.General(god,"ol_shensunquan","god",4,true)

olyuhengCard = sgs.CreateSkillCard{
	name = "olyuhengCard",
	target_fixed = true,
	will_throw = true,
	skill_name = "_olyuheng",
	on_use = function(self,room,source,targets)
		local skill_names = {}
		for _,name in ipairs(sgs.Sanguosha:getLimitedGeneralNames())do
			local general = sgs.Sanguosha:getGeneral(name)
			if general:getKingdom() == "wu" then
				for _,skill in sgs.qlist(general:getVisibleSkillList())do
					--没有加主公技、限定技、觉醒技限制，全都可以拿
					table.insert(skill_names,skill:objectName())
				end
			end
		end
		local skills = {}
		for i=1,self:subcardsLength()do
			local first = skill_names[math.random(1,#skill_names)]
			table.removeOne(skill_names,first)
			table.insert(skills,first)
		end
		skills = table.concat(skills,"|")
		room:handleAcquireDetachSkills(source,skills)
		source:setTag("olyuhengSkills",sgs.QVariant(skills))
	end,
}
olyuhengVS = sgs.CreateViewAsSkill{
	name = "olyuheng",
	n = 999,
	view_filter = function(self,selected,to_select)
		for _,c in sgs.list(selected)do
			if c:getSuit() == to_select:getSuit() then return false end
		end
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self,cards)
		if #cards>0 then
			local sc = olyuhengCard:clone()
			for _,c in ipairs(cards)do
				sc:addSubcard(c)
			end
			return sc
		end
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern:startsWith("@@olyuheng")
	end,
}
olyuheng = sgs.CreateTriggerSkill{
    name = "olyuheng",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.EventPhaseChanging},
	view_as_skill = olyuhengVS,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.EventPhaseStart and player:getPhase() == sgs.Player_RoundStart
		and player:getCardCount()>0 then
			room:sendCompulsoryTriggerLog(player,self:objectName())
			if room:askForUseCard(player,"@@olyuheng!","@olyuheng-card") then return end
			for _,c in sgs.qlist(player:getCards("he"))do
				if player:isJilei(c) then continue end
				local sc = olyuhengCard:clone()
				sc:addSubcard(c)
				room:useCard(sgs.CardUseStruct(sc,player))
				break
			end
		elseif event == sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return false end
			local sks = player:getTag("olyuhengSkills"):toString():split("|")
			if #sks<1 then return false end
			local skills = {}
			room:sendCompulsoryTriggerLog(player,self)
			for _,lsk in ipairs(sks)do
				if player:hasSkill(lsk,true) then
					table.insert(skills,"-"..lsk)
				end
			end
			room:handleAcquireDetachSkills(player,table.concat(skills,"|"),true)
			room:drawCards(player,#skills,self:objectName())
			player:removeTag("olyuhengSkills")
		end
	end,
}
ol_shensunquan:addSkill(olyuheng)

oldili = sgs.CreateTriggerSkill{
    name = "oldili",
	frequency = sgs.Skill_Wake,
	waked_skills = "ol_shengzhi,ol_quandao,ol_chigang",
	events = {sgs.EventAcquireSkill},--[[
	can_wake = function(self,event,player,data)
	    local room = player:getRoom()
		if player:getMark(self:objectName()) > 0 then return false end
		if player:canWake(self:objectName()) then return true end
		if player:hasFlag("oldiliLocked") then return false end
		local n = 0
		for _,skill in sgs.qlist(player:getVisibleSkillList())do
			if skill:isAttachedLordSkill() then continue end
			n = n + 1
		end
		return player:getMaxHp()<n
	end,]]
	on_trigger = function(self,event,player,data)
		if not player:canWake(self:objectName()) then
			local n = 0
			for _,skill in sgs.qlist(player:getVisibleSkillList())do
				if skill:isAttachedLordSkill() then continue end
				n = n + 1
			end
			if player:getMaxHp()>=n
			then return false end
		end
	    local room = player:getRoom()
		room:broadcastSkillInvoke(self:objectName())
		room:doSuperLightbox(player,self:objectName())
		room:addPlayerMark(player,self:objectName())
		if room:changeMaxHpForAwakenSkill(player,-1,self:objectName()) then
			local loseskill = {}
			for _,skill in sgs.qlist(player:getVisibleSkillList())do
				if skill:objectName()==self:objectName()
				or skill:isAttachedLordSkill() then continue end
				table.insert(loseskill,skill:objectName())
			end
			table.insert(loseskill,"end")
			local excg = {}
			while #loseskill>1 do
				local choice = room:askForChoice(player,self:objectName(),table.concat(loseskill,"+"),ToData(#excg))
				if choice=="end" then break end
				table.removeOne(loseskill,choice)
				table.insert(excg,"-"..choice)
			end
			loseskill = #excg
			if loseskill >= 1 then table.insert(excg,"ol_shengzhi") end
			if loseskill >= 2 then table.insert(excg,"ol_quandao") end
			if loseskill >= 3 then table.insert(excg,"ol_chigang") end
			room:handleAcquireDetachSkills(player,table.concat(excg,"|"))
		end
	end,
}
ol_shensunquan:addSkill(oldili)
--“圣质”
ol_shengzhi = sgs.CreateTriggerSkill{
    name = "ol_shengzhi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ChoiceMade,sgs.CardUsed},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local str = data:toString()
		if str:startsWith("notifyInvoked:") then
			local strs = str:split(":")
			if player:hasSkill(strs[2],true) and not player:hasEquipSkill(strs[2]) then
				local sk = sgs.Sanguosha:getSkill(strs[2])
				if sk and sk:getFrequency(player)~=sgs.Skill_Compulsory
				and not sk:isAttachedLordSkill() then
					room:sendCompulsoryTriggerLog(player,self)
					local log = sgs.LogMessage()
					log.type = "$ol_shengzhiNoLimit"
					log.from = player
					room:sendLog(log)
					room:setPlayerFlag(player,"dlszCardBuff")
				end
			end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 then
				room:setPlayerFlag(player,"-dlszCardBuff")
			end
		end
	end,
}
god:addSkills(ol_shengzhi)
--“权道”
ol_quandao = sgs.CreateTriggerSkill{
    name = "ol_quandao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.CardUsed},
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") or use.card:isNDTrick() then
			local s,ndt = 0,0
			for _,card in sgs.qlist(player:getHandcards())do
				if card:isKindOf("Slash") then s = s+1
				elseif card:isNDTrick() then ndt = ndt+1 end
			end
			room:sendCompulsoryTriggerLog(player,self)
			local n = s - ndt
			if n>0 then
				room:askForDiscard(player,self:objectName(),n,n,false,false,"qdslash:"..n,"Slash")
			elseif n<0 then
				n = -n
				room:askForDiscard(player,self:objectName(),n,n,false,false,"qdNDtrick:"..n,"TrickCard+^DelayedTrick")
			end
			room:drawCards(player,1,self:objectName())
		end
	end,
}
god:addSkills(ol_quandao)
--“持纲”
ol_chigang = sgs.CreateTriggerSkill{
	name = "ol_chigang",
	change_skill = true,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local change = data:toPhaseChange()
		if change.to == sgs.Player_Judge then
			local n = player:getChangeSkillState(self:objectName())
		    if n == 1 then
			    room:setChangeSkillState(player,self:objectName(),2)
				room:sendCompulsoryTriggerLog(player,self)
				change.to = sgs.Player_Draw
				data:setValue(change)
			elseif n == 2 then
			    room:setChangeSkillState(player,self:objectName(),1)
				room:sendCompulsoryTriggerLog(player,self)
				change.to = sgs.Player_Play
				data:setValue(change)
			end
		end
	end,
}
god:addSkills(ol_chigang)

sgs.Sanguosha:setPackage(god)

--王衍
keol_wangyan = sgs.General(extension,"keol_wangyan","jin",3)
keolyangkuang = sgs.CreateTriggerSkill{
	name = "keolyangkuang",
	--frequency = sgs.Skill_NotFrequent,
	events = {sgs.HpRecover},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.HpRecover) then
			local jiu = sgs.Sanguosha:cloneCard("analeptic")
			jiu:setSkillName("_"..self:objectName())
			jiu:deleteLater()
			if player:getLostHp()<1 and player:canUse(jiu,player)
			and player:askForSkillInvoke(self,data) then
				room:useCard(sgs.CardUseStruct(jiu,player,player),true)
				local cur = room:getCurrent()
				player:drawCards(1,self:objectName())
				if cur then cur:drawCards(1,self:objectName()) end
			end
		end
	end,
	--[[can_trigger = function(self,target)
		return target
	end]]
}
keol_wangyan:addSkill(keolyangkuang)
keolcihuang = sgs.CreateTriggerSkill{
    name = "keolcihuang",
	view_as_skill = keolcihuangvs,
    events = {sgs.CardOffset,sgs.CardUsed},
    on_trigger = function(self,event,player,data)
        local room = player:getRoom()
        if (event == sgs.CardOffset) then
            local effect = data:toCardEffect()
            if effect.from and effect.from:hasFlag("CurrentPlayer") and effect.card:getTypeId()>0 then
				local use = room:getTag("UseHistory"..effect.card:toString()):toCardUse()
				if use.to:length()~=1 then return end
				for _,wy in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do 
					if wy:isNude() then continue end
					local choices = {}
					for _,pt in sgs.list(patterns())do
						local dc = dummyCard(pt)
						if wy:getMark(pt.."keolcihuang_lun")<1 and dc
						and (dc:isSingleTargetCard() and dc:isNDTrick() or dc:isKindOf("NatureSlash"))
						and wy:canUse(dc,effect.from) then table.insert(choices,pt) end
					end
					if #choices<1 then continue end
					wy:setTag("keolcihuang",ToData(table.concat(choices,"+")))
					if wy:askForSkillInvoke(self,ToData(effect.from),false) then
						local choice = room:askForChoice(wy,self:objectName(),table.concat(choices,"+"))
						local dc = dummyCard(choice)
						dc:setSkillName(self:objectName())
						local ids = {}
						for _,c in sgs.qlist(wy:getCards("he"))do
							dc:addSubcard(c)
							if not wy:isLocked(dc) then
								table.insert(ids,c:toString())
							end
							dc:clearSubcards()
						end
						local hc = room:askForExchange(wy,self:objectName(),1,1,true,"keolcihuangchoose",false,table.concat(ids,","))
						if hc then
							dc:addSubcard(hc)
							local use = sgs.CardUseStruct()
							use.from = wy
							use.to:append(effect.from)
							use.card = dc
							local cardd = use.no_respond_list
							table.insert(cardd,"_ALL_TARGETS")
							use.no_respond_list = cardd
							room:useCard(use,true)
						end
					end
				end
            end
		elseif event == sgs.CardUsed then
			local use = data:toCardUse()
			if use.card:isNDTrick() or use.card:isKindOf("NatureSlash") then
				room:addPlayerMark(player,use.card:objectName().."keolcihuang_lun")
			end
        end
    end,
    can_trigger = function(self,target)
        return target and target:isAlive()
    end,
}
keol_wangyan:addSkill(keolcihuang)
keolsanku = sgs.CreateTriggerSkill{
	name = "keolsanku",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EnterDying,sgs.MaxHpChange},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		if (event == sgs.MaxHpChange) then
			local change = data:toMaxHp()
			if (change.change > 0) then
				room:sendCompulsoryTriggerLog(change.who,self)
				local log = sgs.LogMessage()
				log.type = "$keolsankulog"
				log.from = change.who
				room:sendLog(log)
				change.change = 0
				data:setValue(change)
			end
		elseif event == sgs.EnterDying then
			room:sendCompulsoryTriggerLog(player,self)
		    room:loseMaxHp(player)
			room:recover(player,sgs.RecoverStruct(self:objectName(),player,player:getMaxHp()-player:getHp()))
		end
	end,
}
keol_wangyan:addSkill(keolsanku)
sgs.LoadTranslationTable {
	["keol_wangyan"] = "王衍",
	["#keol_wangyan"] = "玄虚陆沉",
	["designer:keol_wangyan"] = "官方",
	["cv:keol_wangyan"] = "官方",
	["illustrator:keol_wangyan"] = "官方",

	["keolyangkuang"] = "阳狂",
	[":keolyangkuang"] = "当你回复体力后，若你体力满，你可以视为使用一张【酒】并与当前回合角色各摸一张牌。",

	["keolcihuang"] = "雌黄",
	["keolcihuangchoose"] = "雌黄：请选择一张牌当该牌使用",
	[":keolcihuang"] = "当前回合角色对唯一目标使用的牌被抵消后，你可以将一张牌当一张本轮你未使用过的属性【杀】或单目标普通锦囊牌对该使用者使用且此牌不能被响应。",

	["$keolcihuanglog"] = "因 %from 的 <font color='yellow'><b>“雌黄”</b></font> 效果，此牌不能被 %to 响应",
	["$keolsankulog"] = "因 %from 的 <font color='yellow'><b>“三窟”</b></font> 效果，此次增加体力上限被防止",

	["keolsanku"] = "三窟",
	[":keolsanku"] = "锁定技，当你进入濒死状态时，你失去1点体力上限然后回复所有体力；防止你增加体力上限。",

	["$keolyangkuang1"] = "比干忠谏剖心死，箕子披发阳狂生。",
	["$keolyangkuang2"] = "梅伯数谏遭炮烙，来革顺志而用国。",
	["$keolcihuang1"] = "腹存经典，口吐雌黄。",
	["$keolcihuang2"] = "手把玉麈（zhǔ），胸蕴成篇。",
	["$keolsanku1"] = "纲常难为，应存后路。",
	["$keolsanku2"] = "世将大乱，当思保全。",

	["~keol_wangyan"] = "影摇枭鸱（chī）动，三窟难得生。",
}

shenjiaxu = sgs.General(extension,"shenjiaxu","god")
--线下身份牌为：1主3忠5反2内
local LProles = {"lord","loyalist","loyalist","loyalist","rebel","rebel","rebel","rebel","rebel","renegade","renegade"}
lianpojx = sgs.CreateTriggerSkill{
    name = "lianpojx",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.RoundStart,sgs.Death},
	waked_skills = "#lianpojxbf1,#lianpojxbf2,#lianpojxbf3,#lianpojxbf4",
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.RoundStart then
			local roles = {}
			for _,r in ipairs(LProles)do
				table.insert(roles,r)
			end
			for _,p in sgs.qlist(room:getAlivePlayers())do
				table.removeOne(roles,p:getRole())
			end
			if #roles<1 then return end
			room:sendCompulsoryTriggerLog(player,self)
			local choice = room:askForChoice(player,self:objectName(),table.concat(roles,"+"))
			room:setEmotion(player,choice)
			local log = sgs.LogMessage()
			log.type = "$lianpojx_role"
			log.from = player
			log.arg = choice
			room:sendLog(log)
			room:setPlayerMark(player,"&lianpojx+:+"..choice.."_lun",1)
		else
			local death = data:toDeath()
			local from = death.damage and death.damage.from
			if from and from:isAlive() then
				local hasr = {}
				for _,p in sgs.list(room:getAlivePlayers())do
					hasr[p:getRole()] = (hasr[p:getRole()] or 0)+1
					if p:hasSkill(self,true) then
						for _,m in sgs.list(p:getMarkNames())do
							if m:startsWith("&lianpojx+:+")
							and p:getMark(m)>0 then
								local ms = m:split(":")
								ms = ms[#ms]:split("_")
								hasr[ms[1]] = (hasr[ms[1]] or 0)+1
							end
						end
					end
				end
				local m = 0
				for r,n in pairs(hasr)do
					if n>=m then m = n end
				end
				local x = 0
				for r,n in pairs(hasr)do
					if n>=m then x = x+1 end
				end
				if x<2 then return end
				room:sendCompulsoryTriggerLog(player,self)
				local choices = "lianpojx1"
				if from:isWounded() then choices = "lianpojx1+lianpojx2" end
				if room:askForChoice(from,"lianpojxDeath",choices)=="lianpojx2"
				then room:recover(from,sgs.RecoverStruct(self:objectName(),player))
				else from:drawCards(2,self:objectName()) end
			end
		end
	end,
}
lianpojxbf1 = sgs.CreateMaxCardsSkill{
    name = "#lianpojxbf1",
	extra_func = function(self,target)
		local hasr = {}
		hasr.has = -1
		for _,p in sgs.list(target:getAliveSiblings())do
			if p:hasSkill("lianpojx") then
				hasr.has = 0
				for _,m in sgs.list(p:getMarkNames())do
					if m:startsWith("&lianpojx+:+")
					and p:getMark(m)>0 then
						local ms = m:split(":")
						ms = ms[#ms]:split("_")
						hasr[ms[1]] = (hasr[ms[1]] or 0)+1
					end
				end
			end
		end
		if hasr.has>-1 then
			for _,r in ipairs(sgs.Sanguosha:getRoleList(target:getGameMode()))do
				hasr[r] = (hasr[r] or 0)+1
			end
			if hasr["rebel"] then
				for r,n in pairs(hasr)do
					if n>hasr["rebel"] then return 0 end
				end
				return -1
			end
		end
		return 0
	end 
}
lianpojxbf2 = sgs.CreateTargetModSkill{
	name = "#lianpojxbf2",
	residue_func = function(self,from,card)
		local hasr = {}
		hasr.has = -1
		local tos = from:getAliveSiblings()
		tos:append(from)
		for _,p in sgs.list(tos)do
			if p:hasSkill("lianpojx") then
				hasr.has = 0
				for _,m in sgs.list(p:getMarkNames())do
					if m:startsWith("&lianpojx+:+")
					and p:getMark(m)>0 then
						local ms = m:split(":")
						ms = ms[#ms]:split("_")
						hasr[ms[1]] = (hasr[ms[1]] or 0)+1
					end
				end
			end
		end
		if hasr.has>-1 then
			for _,r in ipairs(sgs.Sanguosha:getRoleList(from:getGameMode()))do
				hasr[r] = (hasr[r] or 0)+1
			end
			if hasr["rebel"] then
				for r,n in pairs(hasr)do
					if n>hasr["rebel"] then return 0 end
				end
				return 1
			end
		end
		return 0
	end,
}
lianpojxbf3 = sgs.CreateAttackRangeSkill{
	name = "#lianpojxbf3",
    extra_func = function(self,target)
		local hasr = {}
		hasr.has = -1
		local tos = target:getAliveSiblings()
		tos:append(target)
		for _,p in sgs.list(tos)do
			if p:hasSkill("lianpojx") then
				hasr.has = 0
				for _,m in sgs.list(p:getMarkNames())do
					if m:startsWith("&lianpojx+:+")
					and p:getMark(m)>0 then
						local ms = m:split(":")
						ms = ms[#ms]:split("_")
						hasr[ms[1]] = (hasr[ms[1]] or 0)+1
					end
				end
			end
		end
		if hasr.has>-1 and hasr["rebel"] then
			for _,r in ipairs(sgs.Sanguosha:getRoleList(target:getGameMode()))do
				hasr[r] = (hasr[r] or 0)+1
			end
			if hasr["rebel"] then
				for r,n in pairs(hasr)do
					if n>hasr["rebel"] then return 0 end
				end
				return 1
			end
		end
		return 0
	end,
}
lianpojxbf4 = sgs.CreateProhibitSkill{
	name = "#lianpojxbf4",
	is_prohibited = function(self,from,to,card)
		if card:isKindOf("Peach") and from~=to then
			local has,hasr = false,{}
			hasr.has = -1
			hasr[from:getRole()] = 1
			for _,p in sgs.list(from:getAliveSiblings())do
				if p:hasSkill("lianpojx") then
					hasr.has = 0
					for _,m in sgs.list(p:getMarkNames())do
						if m:startsWith("&lianpojx+:+")
						and p:getMark(m)>0 then
							local ms = m:split(":")
							ms = ms[#ms]:split("_")
							hasr[ms[1]] = (hasr[ms[1]] or 0)+1
						end
					end
				end
			end
			if hasr.has>-1 then
				for _,r in ipairs(sgs.Sanguosha:getRoleList(from:getGameMode()))do
					hasr[r] = (hasr[r] or 0)+1
				end
				if hasr["lord"] or hasr["loyalist"] then
					local m = (hasr["lord"] or 0)+(hasr["loyalist"] or 0)
					for r,n in pairs(hasr)do
						if n>m then return false end
					end
					return true
				end
			end
		end
	end
}
shenjiaxu:addSkill(lianpojx)
shenjiaxu:addSkill(lianpojxbf1)
shenjiaxu:addSkill(lianpojxbf2)
shenjiaxu:addSkill(lianpojxbf3)
shenjiaxu:addSkill(lianpojxbf4)
zhaoluanCard = sgs.CreateSkillCard{
	name = "zhaoluanCard",
	target_fixed = false,
	--will_throw = false,
	filter = function(self,targets,to_select,source)
		return #targets<1 and to_select:getMark("zhaoluanDamage"..source:objectName())<1
	end,
	on_use = function(self,room,source,targets)
		for _,p in sgs.list(targets)do
			for _,q in sgs.list(room:getAlivePlayers())do
				if q:getMark("&zhaoluan+#"..source:objectName())>0 then
					room:loseMaxHp(q,1,self:getSkillName())
					room:damage(sgs.DamageStruct(self:getSkillName(),source,p))
					room:addPlayerMark(p,"zhaoluanDamage"..source:objectName())
					break
				end
			end
		end
	end,
}
zhaoluanvs = sgs.CreateViewAsSkill{
	name = "zhaoluan",
	view_as = function()
		return zhaoluanCard:clone()
	end,
	enabled_at_play = function(self,player)
		local tos = player:getAliveSiblings()
		tos:append(player)
		local has = false
		for _,p in sgs.list(tos)do
			if p:getMark("&zhaoluan+#"..player:objectName())>0
			then has = true break end
		end
		for _,p in sgs.list(tos)do
			if has and p:getMark("zhaoluanDamage"..player:objectName())<1
			then return true end
		end
		return false
	end,
}
zhaoluan = sgs.CreateTriggerSkill{
    name = "zhaoluan",
	frequency = sgs.Skill_Limited,
	view_as_skill = zhaoluanvs,
	limit_mark = "@zhaoluan",
	events = {sgs.AskForPeachesDone},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if player:getHp()<1 and player:hasFlag("Global_Dying") then
			for _,p in sgs.list(room:findPlayersBySkillName(self:objectName()))do
				if p:getMark("@zhaoluan")<1 or player:getHp()>0 then continue end
				if p:askForSkillInvoke(self,ToData(player)) then
					room:broadcastSkillInvoke(self:objectName())
					room:removePlayerMark(p,"@zhaoluan")
					room:doAnimate(1,p:objectName(),player:objectName())
					room:doSuperLightbox(p,self:objectName())
					room:gainMaxHp(player,3,self:objectName())
					local sks = {}
					for _,sk in sgs.list(player:getVisibleSkillList())do
						if sk:getFrequency(player)==sgs.Skill_Compulsory
						or sk:isAttachedLordSkill() then continue end
						table.insert(sks,"-"..sk:objectName())
					end
					if #sks>0 then
						room:handleAcquireDetachSkills(player,table.concat(sks,"|"))
					end
					if player:isAlive() then
						room:recover(player,sgs.RecoverStruct(self:objectName(),p,3-player:getHp()))
					end
					if player:isAlive() then
						player:drawCards(4,self:objectName())
						room:setPlayerMark(player,"&zhaoluan+#"..p:objectName(),1)
					end
				end
			end
		end
	end,
}
shenjiaxu:addSkill(zhaoluan)

jin_simayan = sgs.General(extension,"jin_simayan$","jin",3)
juqi = sgs.CreateTriggerSkill{
    name = "juqi",
	events = {sgs.EventPhaseStart,sgs.ConfirmDamage},
	change_skill = true,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event==sgs.ConfirmDamage then
			local damage = data:toDamage()
			if damage.from and damage.from:getMark("&juqi-Clear")>0 and damage.card and damage.card:getTypeId()>0 then
				room:sendCompulsoryTriggerLog(damage.from,self:objectName())
				return damage.from:damageRevises(data,1)
			end
		elseif player:getPhase()==sgs.Player_Start then
			for _,p in sgs.list(room:findPlayersBySkillName(self:objectName()))do
				local n = p:getChangeSkillState(self:objectName())
				if n == 1 then
					if p==player then
						room:sendCompulsoryTriggerLog(p,self)
						room:setChangeSkillState(p,self:objectName(),2)
						p:drawCards(3,self:objectName())
					else
						local dc = room:askForCard(player,".|black|.|hand","juqi0:black:"..p:objectName(),ToData(p),sgs.Card_MethodNone)
						if dc then
							player:skillInvoked(self,-1,p)
							room:setChangeSkillState(p,self:objectName(),2)
							room:showCard(player,dc:getEffectiveId())
							if player:hasCard(dc) then
								room:giveCard(player,p,dc,self:objectName())
							end
						end
					end
				elseif n == 2 then
					if p==player then
						room:sendCompulsoryTriggerLog(p,self)
						room:setChangeSkillState(p,self:objectName(),1)
						room:setPlayerMark(p,"&juqi-Clear",1)
					else
						local dc = room:askForCard(player,".|red|.|hand","juqi0:red:"..p:objectName(),ToData(p),sgs.Card_MethodNone)
						if dc then
							player:skillInvoked(self,-1,p)
							room:setChangeSkillState(p,self:objectName(),1)
							room:showCard(player,dc:getEffectiveId())
							if player:hasCard(dc) then
								room:giveCard(player,p,dc,self:objectName())
							end
						end
					end
				end
			end
		end
	end,
}
jin_simayan:addSkill(juqi)
fengtu = sgs.CreateTriggerSkill{
    name = "fengtu",
	events = {sgs.Death,sgs.EventPhaseStart},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event==sgs.Death then
			if not player:hasSkill(self)
			then return end
			local death = data:toDeath()
			local aps = sgs.SPlayerList()
			for _,p in sgs.qlist(room:getAlivePlayers())do
				if p:getTag("fengtuseat"):toInt()<1 then aps:append(p) end
			end
			local to = room:askForPlayerChosen(player,aps,self:objectName(),"fengtu0:"..death.who:getPlayerSeat(),true,true)
			if to then
				room:loseMaxHp(to,1,self:objectName())
				if to:isAlive() then
					room:setPlayerMark(to,"&fengtuseat+"..death.who:getPlayerSeat(),1)
					to:setTag("fengtuseat",ToData(death.who:getPlayerSeat()))
				end
			end
		elseif player:getPhase()==sgs.Player_NotActive then
			if player:getMark("fengtuTurn")>0 then
				player:removeMark("fengtuTurn")
				return
			end
			local aps = {}
			for _,p in sgs.qlist(room:getAlivePlayers())do
				local n = p:getTag("fengtuseat"):toInt()
				if n>player:getPlayerSeat() then
					local x = player:getNextAlive():getPlayerSeat()
					if x<player:getPlayerSeat() or n<x then
						table.insert(aps,p)
					end
				end
			end
			local function compare_func(a,b)
				return a:getTag("fengtuseat"):toInt()<b:getTag("fengtuseat"):toInt()
			end
			table.sort(aps,compare_func)
			for _,p in sgs.list(aps)do
				if p:isAlive() then
					p:addMark("fengtuTurn")
					p:gainAnExtraTurn()
				end
			end
		end
	end,
}
jin_simayan:addSkill(fengtu)
taishi = sgs.CreateTriggerSkill{
    name = "taishi$",
	events = {sgs.TurnStart},
	frequency = sgs.Skill_Limited,
	limit_mark = "@taishi",
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event==sgs.TurnStart then
			local can = false
			for _,p in sgs.qlist(room:getAlivePlayers())do
				if p:inYinniState() then can = true end
			end
			if can then
				for _,p in sgs.qlist(room:getAllPlayers())do
					if p:hasLordSkill(self) and p:getMark("@taishi")>0 and p:askForSkillInvoke(self) then
						p:peiyin(self)
						room:doSuperLightbox(p,self:objectName())
						room:removePlayerMark(p,"@taishi")
						for _,p in sgs.qlist(room:getAllPlayers())do
							p:breakYinniState()
						end
						break
					end
				end
			end
		end
	end,
}
jin_simayan:addSkill(taishi)

jdmou_sunquan = sgs.General(extension,"jdmou_sunquan$","wu",4)
jiudingmouzhihengCard = sgs.CreateSkillCard{
	name = "jiudingmouzhihengCard",
	will_throw = true,
	target_fixed = true,
	about_to_use = function(self,room,use)
	    for _,id in sgs.qlist(use.from:getEquipsId())do
			if self:getSubcards():contains(id) then
				room:setCardFlag(self,self:getSkillName())
			end
		end
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,source)
		local n = self:subcardsLength()
		if self:hasFlag(self:getSkillName()) then
			n = n + 1
		end
		source:drawCards(n,self:getSkillName())
	end
}
jiudingmouzhiheng = sgs.CreateViewAsSkill{
	name = "jiudingmouzhiheng",
	n = 999,
	view_filter = function(self,selected,to_select)
		return not sgs.Self:isJilei(to_select)
	end,
	view_as = function(self,cards)
	    if #cards == 0 then return false end
		local skillcard = jiudingmouzhihengCard:clone()
		for _,card in ipairs(cards)do
			skillcard:addSubcard(card)
		end
		return skillcard
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#jiudingmouzhihengCard") < 1
	end,
}
jiudingmoutongye = sgs.CreateTriggerSkill{
	name = "jiudingmoutongye",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart,sgs.SwappedPile,sgs.EventAcquireSkill},
	waked_skills = "guzheng,mouyingzi",
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.SwappedPile then
			if data:toInt()==1 and player:hasSkills("guzheng|mouyingzi") then
				room:sendCompulsoryTriggerLog(player,self)
				room:handleAcquireDetachSkills(player,"-mouyingzi|-guzheng",true)
			end
		elseif room:getTag("SwapPile"):toInt()<1 then
			local sks = {}
			if not player:hasSkill("mouyingzi",true) then
				table.insert(sks,"mouyingzi")
			end
			if not player:hasSkill("guzheng",true) then
				table.insert(sks,"guzheng")
			end
			if #sks>0 then
				room:sendCompulsoryTriggerLog(player,self)
				room:handleAcquireDetachSkills(player,table.concat(sks,"|"))
			end
		end
	end,
}
jiudingmoujiuyuanCard = sgs.CreateSkillCard{
	name = "jiudingmoujiuyuanCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,player)
		return (#targets == 0) and (to_select:objectName() ~= player:objectName()) and to_select:getKingdom() == "wu" and not to_select:getEquips():isEmpty()
 	end,
	on_use = function(self,room,source,targets)
		local dc = dummyCard()
		for _,e in sgs.qlist(targets[1]:getEquips())do
			dc:addSubcard(e)
		end
		room:obtainCard(source,dc)
		room:recover(source,sgs.RecoverStruct("jiudingmoujiuyuan",source))
	end
}
jiudingmoujiuyuan = sgs.CreateZeroCardViewAsSkill{
	name = "jiudingmoujiuyuan$",
	view_as = function()
		return jiudingmoujiuyuanCard:clone()
	end,
	enabled_at_play = function(self,player)
		if not player:hasLordSkill(self) or player:usedTimes("#jiudingmoujiuyuanCard")>0 then return end
		for _,p in sgs.qlist(player:getAliveSiblings())do
			if p:getKingdom() == "wu" and p:hasEquip()
			then return true end
		end
	end,
}
jdmou_sunquan:addSkill(jiudingmouzhiheng)
jdmou_sunquan:addSkill(jiudingmoutongye)
jdmou_sunquan:addSkill(jiudingmoujiuyuan)


local ol_sp = sgs.Sanguosha:getPackage("ol_sp")

olsp_caocao = sgs.General(ol_sp,"olsp_caocao","qun",4)
olspxixiangCard = sgs.CreateSkillCard{
	name = "olspxixiangCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,selected,to_select,source)
		if to_select==source then return end
		local dc = dummyCard(self:getUserString())
		dc:setSkillName(self:getSkillName())
		dc:addSubcards(self:getSubcards())
		local plist = sgs.PlayerList()
		for i = 1,#selected do plist:append(selected[i]) end
		return dc:targetFilter(plist,to_select,source)
	end,
	about_to_use = function(self,room,use)
		local dc = dummyCard(self:getUserString())
		dc:setSkillName("olspxixiang")
		dc:addSubcards(self:getSubcards())
	    use.card = dc
		room:addPlayerMark(use.from,"olspxixiang_juguan_remove_"..self:getUserString().."-PlayClear")
		self:cardOnUse(room,use)
		if use.from:isAlive() then
			for _,p in sgs.qlist(use.to)do
				if p:getHp() > use.from:getHandcardNum() then
					use.from:drawCards(1,self:getSkillName())
				end
				if p:getHp() > use.from:getHp() then
					room:recover(use.from,sgs.RecoverStruct(self:getSkillName(),use.from))
					if p:getCardCount()>0 then
						room:obtainCard(use.from,room:askForCardChosen(use.from,p,"he",self:getSkillName()),false)
					end
				end
			end
		end
	end,
}
olspxixiangvs = sgs.CreateViewAsSkill{
	name = "olspxixiang",
	n = 999,
	juguan_type = "slash,duel",
	view_filter = function(self,selected,to_select)
		local sc = sgs.Self:getTag("olspxixiang"):toCard()
		if sc==nil then return false end
		return #selected<=sgs.Self:getMark("olspxixiangNum-Clear")
	end,
	view_as = function(self,cards)
		if #cards<=sgs.Self:getMark("olspxixiangNum-Clear") then return end
		local sc = sgs.Self:getTag("olspxixiang"):toCard()
		if sc==nil then return end
		local skillcard = olspxixiangCard:clone()
		skillcard:setUserString(sc:objectName())
		for _,c in sgs.list(cards)do
			skillcard:addSubcard(c)
		end
		return skillcard
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#olspxixiangCard") < 2 and not player:isNude()
	end
}
olspxixiang = sgs.CreateTriggerSkill{
    name = "olspxixiang",
	events = {sgs.CardFinished},
	view_as_skill = olspxixiangvs,
	juguan_type = "slash,duel",
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId()==1 then
				for _,p in sgs.qlist(room:getAlivePlayers())do
					room:addPlayerMark(p,"olspxixiangNum-Clear")
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
olspaige = sgs.CreateTriggerSkill{
	name = "olspaige",
	waked_skills = "olspzhubei",
	frequency = sgs.Skill_Wake,
	events = {sgs.EnterDying},
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:findPlayersBySkillName(self:objectName()))do
			if p:getMark(self:objectName()) > 0 then continue end
			local dying = data:toDying()
			room:addPlayerMark(p,"&olspaige-Clear")
			if p:getMark("&olspaige-Clear") >= 2 or p:canWake(self:objectName()) then
				room:sendCompulsoryTriggerLog(p,self)
				room:doSuperLightbox(p,self:objectName())
				room:handleAcquireDetachSkills(p,"-olspxixiang|olspzhubei")
				if dying.who:getMaxHp() > p:getHandcardNum() then
					p:drawCards(dying.who:getMaxHp() - p:getHandcardNum(),self:objectName())
				end
				if dying.who:getMaxHp() > p:getHp() and p:isWounded() then
					room:recover(p,sgs.RecoverStruct(self:objectName(),p,dying.who:getMaxHp() - p:getHp()))
				end
				room:setPlayerMark(p,self:objectName(),1)
				room:setPlayerMark(p,"&olspaige-Clear",0)
				if p:getGeneralName():contains("caocao") then
					p:setAvatarIcon("olsp_caocao2")
				end
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
olspzhubeiCard = sgs.CreateSkillCard{
	name = "olspzhubeiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,selected,to_select,source)
		return #selected<1 and source ~= to_select and to_select:getCardCount()>source:getMark("olspzhubeiNum-Clear")
	end,
	on_use = function(self,room,source,targets)
		local n = source:getMark("olspzhubeiNum-Clear")+1
		for _,p in sgs.list(targets)do
			local choices = {}
			if source:getMark("slasholspzhubeiUse-PlayClear")<1 and p:canUse(dummyCard(),source)
			then table.insert(choices,"slash") end
			if source:getMark("duelolspzhubeiUse-PlayClear")<1 and p:canUse(dummyCard("duel"),source)
			then table.insert(choices,"duel") end
			if #choices<1 then continue end
			local choice = room:askForChoice(p,"olspzhubei",table.concat(choices,"+"))
			local transcard = dummyCard(choice)
			transcard:setSkillName("_olspzhubei")
			source:addMark(choice.."olspzhubeiUse-PlayClear")
			local ids = {}
			for _,c in sgs.list(p:getCards("he"))do
				transcard:addSubcard(c)
				if not p:isLocked(transcard)
				then table.insert(ids,c:toString()) end
				transcard:clearSubcards()
			end
			local dc = room:askForExchange(p,"olspzhubei",n,n,true,"olspzhubei0:"..source:objectName()..":"..choice,false,table.concat(ids,","))
			if dc then transcard:addSubcards(dc:getSubcards()) end
			room:useCard(sgs.CardUseStruct(transcard,p,source))
		end
	end
}
olspzhubeivs = sgs.CreateZeroCardViewAsSkill{
	name = "olspzhubei",
	view_as = function(self,cards)
		return olspzhubeiCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#olspzhubeiCard") < 2
	end
}
olspzhubei = sgs.CreateTriggerSkill{
    name = "olspzhubei",
	events = {sgs.CardFinished,sgs.Damaged},
	view_as_skill = olspzhubeivs,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		if event == sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:getTypeId()==1 then
				for _,p in sgs.qlist(room:getAlivePlayers())do
					room:addPlayerMark(p,"olspzhubeiNum-Clear")
				end
			end
			if table.contains(use.card:getSkillNames(),self:objectName()) then
				for _,p in sgs.qlist(use.to)do
					if use.card:hasFlag("DamageDone_"..p:objectName())
					or p:isDead() or use.from:isDead() then continue end
					if p:hasSkill(self,true) then
					    room:recover(p,sgs.RecoverStruct(self:objectName(),p))
						if p:askForSkillInvoke(self,use.from,false) then
							room:swapCards(p,use.from,"h",self:objectName(),false)
						end
					end
				end
			end
		else
			local damage = data:toDamage()
			if damage.card and table.contains(damage.card:getSkillNames(),self:objectName())
			and room:getCardOwner(damage.card:getEffectiveId())==nil
			and player:hasSkill(self,true) and player:askForSkillInvoke(self,data,false) then
				player:obtainCard(damage.card)
			end
		end
	end,
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
}
olsp_caocao:addSkill(olspxixiang)
olsp_caocao:addSkill(olspaige)
ol_sp:addSkills(olspzhubei)
sgs.LoadTranslationTable{
    ["olsp_caocao"] = "SP曹操[OL]",
    ["#olsp_caocao"] = "踌躇的孤雁",
    ["olspxixiang"] = "西向",
	[":olspxixiang"] = "出牌阶段各限一次，你可以将至少X张牌当【决斗】/【杀】使用（X为本回合被使用过的基本牌的数量+1）。若目标角色的体力值大于你的：手牌数，你摸一张牌；体力值，你回复1点体力，然后获得其一张牌。",
	["$olspxixiang1"] = "挥剑断浮云，诸君共西向",
	["$olspxixiang2"] = "西望故都，何忍君父辱于匹夫之手",
    ["olspaige"] = "哀歌",
	[":olspaige"] = "觉醒技，一回合内第二次有角色进入濒死状态后，你失去“西向”，获得“逐北”，然后将手牌摸至X，体力值恢复至X。（X为该角色体力上限）",
	["$olspaige1"] = "奈何力不齐，踌躇而晏行",
	["$olspaige2"] = "生民百遗一，念之断人肠",
	["olspzhubei"] = "逐北",
	[":olspzhubei"] = "出牌阶段各限一次，你可以令一名其他角色将至少X张牌当【决斗】/【杀】对你使用（X为本回合被使用过的基本牌的数量+1）。若你因此受到了伤害，则你可以获得这些牌，否则你回复1点体力，然后可以与其交换手牌。",
	["olspzhubei0"] = "逐北：请将任意张牌当做【%dest】对%src使用",
	["$olspzhubei1"] = "虎踞青兖，欲补薄暮苍天",
	["$olspzhubei2"] = "欲止戈，必先执戈",
	["~olsp_caocao"] = "尔等....算什么大汉忠臣！",
    ["olsp_caocao2"] = "SP曹操",
}

local SkillEvent = {}
SkillEvent["SkillEvent1"] = function(self,event,player,data)
	if event==sgs.CardFinished and player:hasSkill(self:objectName()) then
		local use = data:toCardUse()
		if use.card:getTypeId()>0
		then return player end
	end
end
SkillEvent["SkillEvent2"] = function(self,event,player,data)
	if event==sgs.CardFinished then
		local use = data:toCardUse()
		if use.card:getTypeId()>0 then
			for _,p in sgs.qlist(use.to)do
				if p~=player and p:hasSkill(self:objectName())
				then return p end
			end
		end
	end
end
SkillEvent["SkillEvent3"] = function(self,event,player)
	return event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Play
	and player:hasSkill(self:objectName()) and player
end
SkillEvent["SkillEvent4"] = function(self,event,player,data)
	if event==sgs.Damaged and player:hasSkill(self:objectName())
	then return player end
end
SkillEvent["SkillEvent5"] = function(self,event,player)
	return event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Start
	and player:hasSkill(self:objectName()) and player
end
SkillEvent["SkillEvent6"] = function(self,event,player)
	return event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Finish
	and player:hasSkill(self:objectName()) and player
end
SkillEvent["SkillEvent7"] = function(self,event,player,data)
	if event==sgs.Damage and player:hasSkill(self:objectName())
	then return player end
end
SkillEvent["SkillEvent8"] = function(self,event,player,data)
	if event==sgs.TargetConfirming then
		local use = data:toCardUse()
		if use.card:isKindOf("Slash") then
			for _,p in sgs.qlist(use.to)do
				if p:hasSkill(self:objectName())
				then return p end
			end
		end
	end
end
SkillEvent["SkillEvent9"] = function(self,event,player,data)
	if event==sgs.Dying and player:hasSkill(self:objectName())
	then return player end
end
SkillEvent["SkillEvent10"] = function(self,event,player,data)
	if event==sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceEquip)
		and move.from:objectName()==player:objectName() and player:hasSkill(self:objectName())
		then return player end
	end
end
SkillEvent["SkillEvent11"] = function(self,event,player,data)
	if event==sgs.CardUsed then
		local use = data:toCardUse()
		if use.card:isKindOf("Jink") and player:hasSkill(self:objectName()) then
			return player
		end
	elseif event==sgs.CardResponded then
		local response = data:toCardResponse()
		if response.m_card:isKindOf("Jink") and player:hasSkill(self:objectName()) then
			return player
		end
	end
end
SkillEvent["SkillEvent12"] = function(self,event,player,data)
	if event==sgs.AskForRetrial and player:hasSkill(self:objectName()) then
		player:setTag("JudgeData",data)
		return player
	end
end
SkillEvent["SkillEvent13"] = function(self,event,player,data)
	if event==sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceHand)
		and move.from:objectName()==player:objectName() and player:hasSkill(self:objectName())
		then return player end
	end
end
SkillEvent["SkillEvent14"] = function(self,event,player,data)
	if event==sgs.CardOffset and player:hasSkill(self:objectName())
	then return player end
end
SkillEvent["SkillEvent15"] = function(self,event,player,data)
	if event==sgs.FinishJudge then
		player:setTag("JudgeData",data)
		return player:getRoom():findPlayerBySkillName(self:objectName())
	end
end
SkillEvent["SkillEvent16"] = function(self,event,player,data)
	if event==sgs.CardFinished then
		local use = data:toCardUse()
		if use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack") then
			return player:getRoom():findPlayerBySkillName(self:objectName())
		end
	end
end
SkillEvent["SkillEvent17"] = function(self,event,player,data)
	if event==sgs.Damage and player:hasSkill(self:objectName()) then
		local damage = data:toDamage()
		return damage.card and damage.card:isKindOf("Slash") and player
	end
end
SkillEvent["SkillEvent18"] = function(self,event,player,data)
	if event==sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if (move.from_places:contains(sgs.Player_PlaceHand) or move.from_places:contains(sgs.Player_PlaceEquip)) and (move.from~=move.to or not move.to)
		and move.from:objectName()==player:objectName() and not player:hasFlag("CurrentPlayer") and player:hasSkill(self:objectName()) then
			for _,id in sgs.qlist(move.card_ids)do
				if sgs.Sanguosha:getCard(id):isRed() then
					return player
				end
			end
		end
	end
end
SkillEvent["SkillEvent19"] = function(self,event,player)
	return event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Discard
	and player:hasSkill(self:objectName()) and player
end
SkillEvent["SkillEvent20"] = function(self,event,player,data)
	if event==sgs.Damaged then
		local damage = data:toDamage()
		if damage.card and damage.card:isKindOf("Slash") then
			return player:getRoom():findPlayerBySkillName(self:objectName())
		end
	end
end
SkillEvent["SkillEvent21"] = function(self,event,player)
	return event==sgs.EventPhaseStart and player:getPhase()==sgs.Player_Draw
	and player:hasSkill(self:objectName()) and player
end
SkillEvent["SkillEvent22"] = function(self,event,player,data)
	if event==sgs.TargetConfirmed then
		local use = data:toCardUse()
		if use.card:isNDTrick() and use.to:contains(player) and player:hasSkill(self:objectName())
		then return player end
	end
end
SkillEvent["SkillEvent23"] = function(self,event,player)
	if event==sgs.ChainStateChanged and player:isChained() then
		return player:getRoom():findPlayerBySkillName(self:objectName())
	end
end
SkillEvent["SkillEvent24"] = function(self,event,player,data)
	if event==sgs.Damaged then
		local damage = data:toDamage()
		if damage.nature~=sgs.DamageStruct_Normal then
			return player:getRoom():findPlayerBySkillName(self:objectName())
		end
	end
end
SkillEvent["SkillEvent25"] = function(self,event,player,data)
	if event==sgs.CardsMoveOneTime then
		local move = data:toMoveOneTime()
		if move.from_places:contains(sgs.Player_PlaceHand)
		and move.is_last_handcard and player:hasSkill(self:objectName())
		then return player end
	end
end
SkillEvent["SkillEvent26"] = function(self,event,player)
	if event==sgs.HpChanged and player:hasSkill(self:objectName())
	then return player end
end
SkillEvent["SkillEvent27"] = function(self,event,player)
	return event==sgs.RoundStart and player:hasSkill(self:objectName()) and player
end
SkillEvent["SkillEvent28"] = function(self,event,player)
	if event==sgs.DamageCaused then
		return player:getRoom():findPlayerBySkillName(self:objectName())
	end
end
SkillEvent["SkillEvent29"] = function(self,event,player)
	if event==sgs.DamageInflicted then
		return player:getRoom():findPlayerBySkillName(self:objectName())
	end
end
SkillEvent["SkillEvent30"] = function(self,event,player,data)
	if event==sgs.Death and player:hasSkill(self:objectName())
	then return player end
end

local SkillEffect = {}
SkillEffect["SkillEffect1"] = function(self,player)
	if player:askForSkillInvoke("SkillEffect",ToData("s1"),false) then
		local room = player:getRoom()
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		player:drawCards(1,self:objectName())
	end
end
SkillEffect["SkillEffect2"] = function(self,player)
	local room = player:getRoom()
	local tps = sgs.SPlayerList()
	for _,p in sgs.qlist(room:getAlivePlayers())do
		if player:canDiscard(p,"hej") then
			tps:append(p)
		end
	end
	local to = room:askForPlayerChosen(player,tps,self:objectName(),"SkillEffect2",true,true)
	if to then
		room:addPlayerMark(player,"useTime"..self:objectName())
		local id = room:askForCardChosen(player,to,"hej",self:objectName(),false,sgs.Card_MethodDiscard)
		room:throwCard(id,self:objectName(),to,player)
	end
end
SkillEffect["SkillEffect3"] = function(self,player)
	local room = player:getRoom()
	if player:askForSkillInvoke("SkillEffect",ToData("s3"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		local ids = room:getNCards(3)
		room:askForGuanxing(player,ids)
	end
end
SkillEffect["SkillEffect4"] = function(self,player)
	local room = player:getRoom()
	local dc = room:askForDiscard(player,self:objectName(),998,1,true,true,"SkillEffect4",".",self:objectName())
	if dc then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:drawCards(dc:subcardsLength(),self:objectName())
	end
end
SkillEffect["SkillEffect5"] = function(self,player,data)
	local room = player:getRoom()
	local damage = data:toDamage()
	if damage.card and damage.card and room:getCardOwner(damage.card:getEffectiveId())==nil
	and player:askForSkillInvoke("SkillEffect",ToData("s5"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		room:obtainCard(player,damage.card)
	end
end
SkillEffect["SkillEffect6"] = function(self,player)
	local room = player:getRoom()
	player:setTag("skilleffectp",ToData(self:objectName()))
	room:acquireSkill(player,"#SkillEffect11",true,false,false)
	room:askForUseCard(player,"@@skilleffectp","SkillEffect6")
end
skilleffectp = sgs.CreateZeroCardViewAsSkill{
	name = "skilleffectp",
	response_pattern = "@@skilleffectp",
	view_as = function(self)
		local dc = sgs.Sanguosha:cloneCard("slash")
		dc:setSkillName("qingshu_tianshu0")
		return dc
	end,
	enabled_at_play = function(self,player)
		return false
	end
}
extension:addSkills(skilleffectp)
SkillEffect["SkillEffect7"] = function(self,player)
	local room = player:getRoom()
	local to = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"SkillEffect7",true,true)
	if to and to:getCardCount(true,true)>0 then
		room:addPlayerMark(player,"useTime"..self:objectName())
		local id = room:askForCardChosen(player,to,"hej",self:objectName())
		room:obtainCard(player,id,false)
	end
end
SkillEffect["SkillEffect8"] = function(self,player)
	local room = player:getRoom()
	if player:isWounded() and player:askForSkillInvoke("SkillEffect",ToData("s8"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		room:recover(player,sgs.RecoverStruct(self:objectName(),player))
	end
end
SkillEffect["SkillEffect9"] = function(self,player)
	local room = player:getRoom()
	if player:askForSkillInvoke("SkillEffect",ToData("s9"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		player:drawCards(3,self:objectName())
		room:askForDiscard(player,self:objectName(),1,1,false,true)
	end
end
SkillEffect["SkillEffect10"] = function(self,player)
	local n = player:getMaxCards()-player:getHandcardNum()
	if n>0 and player:askForSkillInvoke("SkillEffect",ToData("s10"),false) then
		local room = player:getRoom()
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		player:drawCards(math.min(5,n),self:objectName())
	end
end
SkillEffect["SkillEffect11"] = function(self,player)
	local room = player:getRoom()
	local to = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"SkillEffect11",true,true)
	if to then
		room:addPlayerMark(player,"useTime"..self:objectName())
		to:addMark("skillInvalidity")
		room:addPlayerMark(to,"@skill_invalidity")
		room:acquireSkill(to,"#SkillEffect11",true,false,false)
	end
end
SkillEffect11 = sgs.CreateTriggerSkill{
    name = "#SkillEffect11",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart,sgs.PreCardUsed,sgs.CardEffect,sgs.AskForRetrial},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_RoundStart and player:getMark("skillInvalidity")>0 then
				room:removePlayerMark(player,"@skill_invalidity",player:getMark("skillInvalidity"))
				player:setMark("skillInvalidity",0)
			end
			if player:getPhase()==sgs.Player_NotActive and player:getMark("SkillEffect20")>0 then
				room:addMaxCards(player,-player:getMark("SkillEffect20")*2,false)
				player:setMark("SkillEffect20",0)
			end
		elseif event == sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and use.to:length()>0 then
				for _,p in sgs.qlist(room:getAlivePlayers())do
					p:setFlags("-SkillEffect13")
				end
				if table.contains(use.card:getSkillNames(),"qingshu_tianshu0") then
					room:addPlayerMark(player,"useTime"..player:getTag("skilleffectp"):toString())
				end
			end
		elseif event == sgs.CardEffect then
            local effect = data:toCardEffect()
			if effect.card:getTypeId()>0 and player:hasFlag("SkillEffect13") then
				player:setFlags("-SkillEffect13")
				effect.nullified = true
				data:setValue(effect)
			end
		elseif event == sgs.AskForRetrial then
			player:setTag("JudgeData",data)
		end
	end,
}
extension:addSkills(SkillEffect11)
SkillEffect["SkillEffect12"] = function(self,player)
	local room = player:getRoom()
	local to = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"SkillEffect12",true,true)
	if to then
		room:addPlayerMark(player,"useTime"..self:objectName())
		to:drawCards(2,self:objectName())
		to:turnOver()
	end
end
SkillEffect["SkillEffect13"] = function(self,player)
	local room = player:getRoom()
	room:acquireSkill(player,"#SkillEffect11",true,false,false)
	if player:askForSkillInvoke("SkillEffect",ToData("s13"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		player:setFlags("SkillEffect13")
	end
end
SkillEffect["SkillEffect14"] = function(self,player)
	local room = player:getRoom()
	local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"SkillEffect14",true,true)
	if to then
		room:addPlayerMark(player,"useTime"..self:objectName())
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|spade"
		judge.good = false
		judge.negative = true
		judge.reason = self:objectName()
		judge.who = to
		room:judge(judge)
		if judge:isBad() then
			room:damage(sgs.DamageStruct(self:objectName(),player,to,2,sgs.DamageStruct_Thunder))
		end
	end
end
SkillEffect["SkillEffect15"] = function(self,player,data)
	local room = player:getRoom()
	room:acquireSkill(player,"#SkillEffect11",true,false,false)
    local judge = data:toJudge()
	if judge and judge.card and room:getCardPlace(judge.card:getEffectiveId())==sgs.Player_PlaceJudge then
        local card = room:askForCard(player,".","SkillEffect15:",player:getTag("JudgeData"),sgs.Card_MethodResponse,judge.who,true)
		if card then
			room:addPlayerMark(player,"useTime"..self:objectName())
			room:retrial(card,player,judge,self:objectName(),true)
		end
	end
end
SkillEffect["SkillEffect16"] = function(self,player,data)
	local room = player:getRoom()
	room:acquireSkill(player,"#SkillEffect11",true,false,false)
    local judge = data:toJudge()
	if judge and judge.card and room:getCardPlace(judge.card:getEffectiveId())==sgs.Player_PlaceJudge
	and player:askForSkillInvoke(self,player:getTag("JudgeData"):toJudge()) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		room:obtainCard(player,judge.card)
	end
end
SkillEffect["SkillEffect17"] = function(self,player)
	local room = player:getRoom()
	for _,p in sgs.qlist(room:getAlivePlayers())do
		if p:getMaxHp()>player:getMaxHp() then
			if player:askForSkillInvoke("SkillEffect",ToData("s17"),false) then
				room:addPlayerMark(player,"useTime"..self:objectName())
				player:skillInvoked(self,-1)
				room:gainMaxHp(player,1,self:objectName())
			end
			break
		end
	end
end
SkillEffect["SkillEffect18"] = function(self,player)
	local room = player:getRoom()
	local tps = sgs.SPlayerList()
	for _,p in sgs.qlist(room:getOtherPlayers(player))do
		if p:isWounded() and player:canPindian(p)
		then tps:append(p) end
	end
	local to = room:askForPlayerChosen(player,tps,self:objectName(),"SkillEffect18",true,true)
	if to then
		room:addPlayerMark(player,"useTime"..self:objectName())
		if player:pindian(to,self:objectName()) and to:getCardCount()>0 and player:isAlive() then
			local dc = dummyCard()
			for i=1,2 do
				local id = room:askForCardChosen(player,to,"he",self:objectName(),false,sgs.Card_MethodNone,dc:getSubcards())
				if id>=0 then dc:addSubcard(id) end
			end
			player:obtainCard(dc)
		end
	end
end
SkillEffect["SkillEffect19"] = function(self,player)
	local room = player:getRoom()
	local tos = room:askForPlayersChosen(player,room:getAlivePlayers(),self:objectName(),0,2,"SkillEffect19",true)
	if tos:length()>0 then
		room:addPlayerMark(player,"useTime"..self:objectName())
		for _,p in sgs.qlist(tos)do
			p:drawCards(1,self:objectName())
		end
	end
end
SkillEffect["SkillEffect20"] = function(self,player)
	local room = player:getRoom()
	local to = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"SkillEffect20",true,true)
	if to then
		room:addPlayerMark(player,"useTime"..self:objectName())
		room:addMaxCards(to,2,false)
		to:addMark("SkillEffect20")
	end
end
SkillEffect["SkillEffect21"] = function(self,player)
	local room = player:getRoom()
	if player:askForSkillInvoke("SkillEffect",ToData("s21"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		local ids = room:getDiscardPile()
		for _,id in sgs.qlist(room:getDrawPile())do
			ids:append(id)
		end
		ids = RandomList(ids)
		local dc = dummyCard()
		for _,id in sgs.qlist(ids)do
			if sgs.Sanguosha:getCard(id):getTypeId()>1 then
				dc:addSubcard(id)
				if dc:subcardsLength()>1 then break end
			end
		end
		player:obtainCard(dc,true)
	end
end
SkillEffect["SkillEffect22"] = function(self,player)
	local room = player:getRoom()
	if player:askForSkillInvoke("SkillEffect",ToData("s22"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		local ids = room:getDiscardPile()
		for _,id in sgs.qlist(room:getDrawPile())do
			ids:append(id)
		end
		ids = RandomList(ids)
		local dc = dummyCard()
		for _,id in sgs.qlist(ids)do
			if sgs.Sanguosha:getCard(id):getTypeId()==2 then
				dc:addSubcard(id)
				if dc:subcardsLength()>1 then break end
			end
		end
		player:obtainCard(dc,true)
	end
end
SkillEffect["SkillEffect23"] = function(self,player)
	local room = player:getRoom()
	if player:askForSkillInvoke("SkillEffect",ToData("s23"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		player:drawCards(4,self:objectName())
		player:turnOver()
	end
end
SkillEffect["SkillEffect24"] = function(self,player)
	local room = player:getRoom()
	local to = room:askForPlayerChosen(player,room:getAlivePlayers(),self:objectName(),"SkillEffect24",true,true)
	if to then
		room:addPlayerMark(player,"useTime"..self:objectName())
		room:addPlayerMark(player,to:objectName().."SkillEffect24-SelfClear")
	end
end
SkillEffect["SkillEffect25"] = function(self,player)
	local room = player:getRoom()
	if room:askForDiscard(player,self:objectName(),2,2,true,true,"SkillEffect25",".",self:objectName()) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		local to = room:askForPlayerChosen(player,room:getOtherPlayers(player),self:objectName(),"SkillEffect25")
		room:doAnimate(1,player:objectName(),to:objectName())
		room:recover(player,sgs.RecoverStruct(self:objectName(),player),true)
		room:recover(to,sgs.RecoverStruct(self:objectName(),player),true)
	end
end
SkillEffect["SkillEffect26"] = function(self,player)
	local room = player:getRoom()
	if player:askForSkillInvoke("SkillEffect",ToData("s26"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		room:loseHp(player,1,true,player,self:objectName())
		player:drawCards(3,self:objectName())
	end
end
SkillEffect["SkillEffect27"] = function(self,player)
	local room = player:getRoom()
	local tos = room:askForPlayersChosen(player,room:getAlivePlayers(),self:objectName(),-1,2,"SkillEffect27",true)
	if tos:length()==2 then
		room:addPlayerMark(player,"useTime"..self:objectName())
		room:swapCards(tos:first(),tos:last(),"h",self:objectName(),false)
	end
end
SkillEffect["SkillEffect28"] = function(self,player)
	local room = player:getRoom()
	local tos = room:askForPlayersChosen(player,room:getAlivePlayers(),self:objectName(),-1,2,"SkillEffect28",true)
	if tos:length()==2 then
		room:addPlayerMark(player,"useTime"..self:objectName())
		room:swapCards(tos:first(),tos:last(),"e",self:objectName(),false)
	end
end
SkillEffect["SkillEffect29"] = function(self,player,data)
	local room = player:getRoom()
	if player:askForSkillInvoke("SkillEffect",ToData("s29"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		player:damageRevises(data,1)
	end
end
SkillEffect["SkillEffect30"] = function(self,player,data)
	local room = player:getRoom()
	if player:askForSkillInvoke("SkillEffect",ToData("s30"),false) then
		room:addPlayerMark(player,"useTime"..self:objectName())
		player:skillInvoked(self,-1)
		local damage = data:toDamage()
		player:damageRevises(data,-damage.damage)
		if damage.from then
			damage.from:drawCards(3,self:objectName())
		end
		return true
	end
end

local skill_events = {}
for i=sgs.EventPhaseStart,sgs.RoundStart do
	table.insert(skill_events,i)
end
local tianshuSkills = {}
for i=0,99 do
	local tianshu = sgs.CreateTriggerSkill{
		name = "qingshu_tianshu"..i,
		events = skill_events,
		can_trigger = function(self,player)
			return player and player:isAlive()
		end,
		on_trigger = function(self,event,player,data,room)
			local str = room:getTag(self:objectName().."SkillEvent"):toString();
			if str~="" then
				local owner = SkillEvent[str](self,event,player,data)
				if owner and owner:getMark("useTime"..self:objectName())<3 then
					str = room:getTag(self:objectName().."SkillEffect"):toString()
					local has = SkillEffect[str](self,owner,data)
					if owner:getMark("useTime"..self:objectName())>2 then
						room:setPlayerMark(owner,"useTime"..self:objectName(),0)
						room:changeTranslation(owner,self:objectName(),"")
						room:detachSkillFromPlayer(owner,self:objectName())
					end
					return has==true
				end
			end
		end
	}
	table.insert(tianshuSkills,tianshu)
	extension:addSkills(tianshu)
	sgs.LoadTranslationTable{
		["qingshu_tianshu"..i] = "天书",
	}
end

olsp_nanhua = sgs.General(ol_sp,"olsp_nanhua","qun",3)
qingshu = sgs.CreateTriggerSkill{
    name = "qingshu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart,sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventPhaseStart then
			if player:getPhase()~=sgs.Player_Start and player:getPhase()~=sgs.Player_Finish
			then return end
		end
		room:sendCompulsoryTriggerLog(player,self)
		local ses = {}
		for s,f in pairs(SkillEvent)do
			table.insert(ses,s)
		end
		RandomList(ses)
		local choices = {}
		for _,f in ipairs(ses)do
			table.insert(choices,f)
			if #choices>2 then break end
		end
		local str = room:askForChoice(player,self:objectName(),table.concat(choices,"+"))
		ses = {}
		for s,f in pairs(SkillEffect)do
			table.insert(ses,s)
		end
		RandomList(ses)
		choices = {}
		for _,f in ipairs(ses)do
			if f=="SkillEffect5" and str~="SkillEvent4" and str~="SkillEvent7" and str~="SkillEvent9"
			and str~="SkillEvent17"and str~="SkillEvent20"and str~="SkillEvent24"and str~="SkillEvent28"
			and str~="SkillEvent29" and str~="SkillEvent30" then continue end
			if f=="SkillEffect13" and str~="SkillEvent8" and str~="SkillEvent14" and str~="SkillEvent22" then continue end
			if f=="SkillEffect15" and str~="SkillEvent12" then continue end
			if f=="SkillEffect16" and str~="SkillEvent12" and str~="SkillEvent15" then continue end
			if f=="SkillEffect29" and str~="SkillEvent28" and str~="SkillEvent29" then continue end
			if f=="SkillEffect30" and str~="SkillEvent28" and str~="SkillEvent29" then continue end
			table.insert(choices,f)
			if #choices>2 then break end
		end
		ses = {}
		for _,s in ipairs(tianshuSkills)do
			local has = false
			for _,p in sgs.qlist(room:getPlayers())do
				if p:hasSkill(s,true) then
					has = true
					break
				end
			end
			if has then continue end
			table.insert(ses,s)
		end
		local trs = str
		local tianshu = ses[math.random(1,#ses)]
		room:setTag(tianshu:objectName().."SkillEvent",ToData(str))
		str = room:askForChoice(player,self:objectName(),table.concat(choices,"+"))
		room:setTag(tianshu:objectName().."SkillEffect",ToData(str))
		room:acquireSkill(player,tianshu)
		trs = sgs.Sanguosha:translate(trs).."，"..sgs.Sanguosha:translate(str).."。"
		room:changeTranslation(player,tianshu:objectName(),trs)
	end,
}
olsp_nanhua:addSkill(qingshu)
hedao = sgs.CreateTriggerSkill{
    name = "hedao",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart,sgs.QuitDying,sgs.EventAcquireSkill},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event == sgs.EventAcquireSkill then
			if data:toString():startsWith("qingshu_tianshu") then
				local n = player:getTag("TianshuSkillNum"):toInt()
				if n<1 then n = 1 end
				local ts = {}
				for _,s in sgs.qlist(player:getVisibleSkillList())do
					if s:objectName():startsWith("qingshu_tianshu")
					then table.insert(ts,s:objectName()) end
				end
				if #ts>n then
					n = #ts-n
					local ds = {}
					for i=1,n do
						local s = room:askForChoice(player,"hedao0",table.concat(ts,"+"))
						table.insert(ds,"-"..s)
						table.removeOne(ts,s)
					end
					room:handleAcquireDetachSkills(player,table.concat(ds,"|"),true)
				end
			end
		elseif event == sgs.QuitDying and player:getMark("hedaoQuitDying")<1 then
			player:addMark("hedaoQuitDying")
			if player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				player:setTag("TianshuSkillNum",ToData(3))
			end
		elseif event == sgs.GameStart and player:hasSkill(self) then
			room:sendCompulsoryTriggerLog(player,self)
			player:setTag("TianshuSkillNum",ToData(2))
		end
	end,
}
olsp_nanhua:addSkill(hedao)
olshoushuCard = sgs.CreateSkillCard{
	name = "olshoushuCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,selected,to_select,source)
		return #selected<1 and source ~= to_select
	end,
	on_use = function(self,room,source,targets)
		for _,p in sgs.list(targets)do
			local choices = {}
			for _,s in sgs.qlist(source:getVisibleSkillList())do
				if s:objectName():startsWith("qingshu_tianshu")
				and source:getMark("useTime"..s:objectName())<1
				then table.insert(choices,s:objectName()) end
			end
			if #choices<1 then continue end
			local choice = room:askForChoice(source,"olshoushu",table.concat(choices,"+"))
			room:detachSkillFromPlayer(source,choice)
			room:acquireSkill(p,choice)
		end
	end
}
olshoushu = sgs.CreateZeroCardViewAsSkill{
	name = "olshoushu",
	view_as = function(self,cards)
		return olshoushuCard:clone()
	end,
	enabled_at_play = function(self,player)
		for _,s in sgs.qlist(player:getVisibleSkillList())do
			if s:objectName():startsWith("qingshu_tianshu")
			and player:getMark("useTime"..s:objectName())<1
			then return player:usedTimes("#olshoushuCard") < 1 end
		end
	end
}
olsp_nanhua:addSkill(olshoushu)





sgs.Sanguosha:setPackage(ol_sp)



zhengjingCard = sgs.CreateSkillCard{
	name = "zhengjingCard",
	target_fixed = true,
	on_use = function(self,room,source)	
		local names = {}
		local froms = sgs.SPlayerList()
		froms:append(source)
		for i=1,99 do
			local canids = sgs.IntList()
			local can_names = {}
			for _,id in sgs.list(sgs.Sanguosha:getRandomCards())do
				local c = sgs.Sanguosha:getEngineCard(id)
				if c:isKindOf("Lightning") then
					canids:append(id)
				elseif c:getTypeId()==2 and not room:getCardOwner(id) and not table.contains(can_names,c:objectName()) then
					table.insert(can_names,c:objectName())
					canids:append(id)
				end
			end
			if #can_names<1 then break end
			local time0 = os.time()--开始计时
			room:fillAG(canids)
			local id = room:askForAG(source,canids,false,self:getSkillName())
			room:clearAG()
			if os.time()-time0>3 then id = -1 end
			if id>-1 then
				local c = sgs.Sanguosha:getEngineCard(id)
				if c:isKindOf("Lightning") then
					names = {}
					break
				elseif #names<5 then
					names[c:objectName()] = math.min(100,(names[c:objectName()] or 0)+20+os.time()-time0)
				else
					for n,m in pairs(names)do
						if n==c:objectName() then
							names[n] = math.min(100,names[n]+20+os.time()-time0)
							break
						end
					end
				end
				local x = 0
				for n,m in pairs(names)do
					room:setPlayerMark(source,"&"..n,m,froms)
					if m>99 then x = x+1 end
				end
				if x>=5 then
					break
				end
			end
		end
		local has_names = {}
		for n,m in pairs(names)do
			room:setPlayerMark(source,"&"..n,0,froms)
			if m>99 then
				table.insert(has_names,n)
			end
		end
		local has_ids = sgs.IntList()
		for _,id in sgs.list(sgs.Sanguosha:getRandomCards())do
			local c = sgs.Sanguosha:getEngineCard(id)
			if not room:getCardOwner(id) and table.contains(has_names,c:objectName()) then
				table.removeOne(has_names,c:objectName())
				has_ids:append(id)
			end
		end
		if has_ids:length()<1 or source:isDead() then return end
		room:notifyMoveToPile(source,has_ids,"zhengjing",sgs.Player_PlaceUnknown,true)
		local dc = room:askForUseCard(source,"@@zhengjing","zhengjing0:",-1,sgs.Card_MethodNone)
		room:notifyMoveToPile(source,has_ids,"zhengjing",sgs.Player_PlaceTable,false)
		for _,id in sgs.list(dc:getSubcards())do
			has_ids:removeOne(id)
		end
		if has_ids:length()<1 or source:isDead() then return end
		dc = dummyCard()
		dc:addSubcards(has_ids)
		source:obtainCard(dc)
	end
}
zhengjing2Card = sgs.CreateSkillCard{
	name = "zhengjing2Card",
	target_fixed = false,
	will_throw = false,
	filter = function(self,targets,to_select,source)
		return #targets<1 and to_select~=source
	end,
	about_to_use = function(self,room,use)
		for _,p in sgs.list(use.to)do
			p:addToPile("zheng_jing",self)
		end
	end,
}
zhengjingvs = sgs.CreateViewAsSkill{
	name = "zhengjing",
	n = 999,
	expand_pile = "#zhengjing",
	enabled_at_play = function(self,player)
		return not player:hasUsed("#zhengjingCard")
	end,
	view_filter = function(self,selected,to_select)
		return sgs.Self:getPileName(to_select:getId())=="#zhengjing"
	end,
	view_as = function(self,cards)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@zhengjing" then
			if #cards<1 then return end
			local sc = zhengjing2Card:clone()
			for _,c in ipairs(cards)do
				sc:addSubcard(c)
			end
			return sc
		end
		return zhengjingCard:clone()
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern:startsWith("@@zhengjing")
	end,
}
zhengjing = sgs.CreateTriggerSkill{
    name = "zhengjing",
	events = {sgs.EventPhaseStart},
	view_as_skill = zhengjingvs,
	can_trigger = function(self,player)
		return player and player:isAlive()
		and player:getPile("zhengjing"):length()>0
		and player:getPhase() == sgs.Player_Start
	end,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local dc = dummyCard()
		dc:addSubcards(player:getPile("zhengjing"))
		player:obtainCard(dc)
		player:skip(sgs.Player_Judge)
		player:skip(sgs.Player_Draw)
	end,
}
--olsp_nanhua:addSkill(zhengjing)



local miscellaneous = sgs.Sanguosha:getPackage("miscellaneous")

xd_shenzhangfei = sgs.General(miscellaneous,"xd_shenzhangfei","god",5)
xdbaohe = sgs.CreateFilterSkill{
	name = "xdbaohe",
	view_filter = function(self,to_select)
		return to_select:isKindOf("TrickCard")
	end,
	view_as = function(self,originalCard)
		local slash = sgs.Sanguosha:cloneCard("slash",originalCard:getSuit(),originalCard:getNumber())
		slash:addSubcard(originalCard)
		slash:setSkillName("xdbaohe")
		local card = sgs.Sanguosha:getWrappedCard(originalCard:getId())
		card:takeOver(slash)
		return card
	end,
}
xdbaohebf = sgs.CreateTriggerSkill{
    name = "#xdbaohebf",
	events = {sgs.ConfirmDamage},
	can_trigger = function(self,target)
		return target and target:hasSkill("xdbaohe")
	end,
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		if damage.card and damage.card:isVirtualCard(true) and damage.card:getEffectiveId()>0 then
			room:sendCompulsoryTriggerLog(player,"xdbaohe",true,true)
			damage.damage = 0
			for _,id in sgs.list(damage.card:getSubcards())do
				damage.damage = damage.damage+sgs.Sanguosha:getEngineCard(id):nameLength()
			end
			data:setValue(damage)
		end
	end,
}
xd_shenzhangfei:addSkill(xdbaohe)
xd_shenzhangfei:addSkill(xdbaohebf)
xdrenhai = sgs.CreateTriggerSkill{
    name = "xdrenhai",
	events = {sgs.DamageCaused},
	frequency = sgs.Skill_Compulsory,
	waked_skills = "chouhai,benghuai,wumou,tenyearzhixi",
	on_trigger = function(self,event,player,data)
	    local room = player:getRoom()
		local damage = data:toDamage()
		if damage.to:isAlive() then
			room:sendCompulsoryTriggerLog(player,self)
			local n = 0
			local choices = player:getTag("xdrenhai_choice"):toString()
			if choices=="" then choices = "1xdrenhai+2xdrenhai+3xdrenhai+4xdrenhai" end
			for d=1,damage.damage do
				local _choices = choices
				if d>1 then _choices = _choices.."+cancel" end
				local choice = room:askForChoice(damage.to,self:objectName(),_choices,data)
				if choice=="cancel" then break end
				local r = string.sub(choice,1,1)
				n = n-r
				if string.find(choice,"1xdrenhai") then
					local judge = sgs.JudgeStruct()
					judge.pattern = ".|spade|2~9"
					judge.good = false
					judge.negative = true
					judge.reason = "lightning"
					judge.who = damage.to
					room:judge(judge)
					if judge:isBad() then
						room:damage(sgs.DamageStruct("lightning",nil,damage.to,3,sgs.DamageStruct_Thunder))
					end
				end
				if string.find(choice,"2xdrenhai") then
					_choices = room:askForChoice(damage.to,"2xdrenhai","chouhai+benghuai",data)
					room:acquireSkill(damage.to,_choices)
					damage.to:addMark("xdrenhai_".._choices)
				end
				if string.find(choice,"3xdrenhai") then
					local choices2 = choices:split("+")
					for i,ch in ipairs(choices2)do
						if ch==choice then
							r = i
						end
					end
					if r>1 then
						if string.find(choices2[r-1],"3xdrenhai") then
							choices2[r-1] = string.gsub(choices2[r-1],"3xdrenhai","")
						end
						choices2[r-1] = choices2[r-1]..choice
					end
					if r<#choices2 then
						if string.find(choices2[r+1],"3xdrenhai") then
							choices2[r+1] = string.gsub(choices2[r+1],"3xdrenhai","")
						end
						choices2[r+1] = choices2[r+1]..choice
					end
					if #choices2>1 then
						table.remove(choices2,r)
						choices = table.concat(choices2,"+")
					end
				end
				if string.find(choice,"4xdrenhai") then
					_choices = room:askForChoice(damage.to,"4xdrenhai","wumou+tenyearzhixi",data)
					room:acquireSkill(damage.to,_choices)
					damage.to:addMark("xdrenhai_".._choices)
				end
				if damage.damage+n<1 then break end
			end
			player:setTag("xdrenhai_choice",ToData(choices))
			return damage.to:damageRevises(data,n)
		end
	end,
}
xd_shenzhangfei:addSkill(xdrenhai)
xdtiantong = sgs.CreateTriggerSkill{
    name = "xdtiantong",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()~=sgs.Player_Start then return end
			room:sendCompulsoryTriggerLog(player,self)
			local n = 0
			for _,p in sgs.list(room:getAllPlayers())do
				for _,s in sgs.list(p:getVisibleSkillList())do
					if p:getMark("xdrenhai_"..s:objectName())>0 then
						room:detachSkillFromPlayer(p,s:objectName(),false,true)
						p:removeMark("xdrenhai_"..s:objectName())
						n = n+1
					end
				end
			end
			local x = 0
			for _,id in sgs.list(room:getDrawPile())do
				local c = sgs.Sanguosha:getCard(id)
				if c:getNumber()>x then x = c:getNumber() end
			end
			local dc = dummyCard()
			for _,id in sgs.list(room:getDrawPile())do
				if dc:subcardsLength()>=n then break end
				local c = sgs.Sanguosha:getCard(id)
				if c:getNumber()>=x then dc:addSubcard(id) end
			end
			player:obtainCard(dc)
			if room:askForChoice(player,self:objectName(),"xdtiantong1+xdtiantong2")=="xdtiantong2"
			then player:setTag("xdrenhai_choice",ToData())
			else player:turnOver() end
		end
	end,
}
xd_shenzhangfei:addSkill(xdtiantong)

xd_shenzhangjiao = sgs.General(miscellaneous,"xd_shenzhangjiao","god",3)

xdyifucard = sgs.CreateSkillCard{
	name = "xdyifucard",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local plist = sgs.PlayerList()
			for i = 1,#targets do plist:append(targets[i]) end
			for _,cn in sgs.list(self:getUserString():split("+"))do
				local dc = dummyCard(cn,"_xdyifu")
				if dc then
					if dc:targetFixed() then return end
					dc:addSubcards(self:getSubcards())
					return dc:targetFilter(plist,to_select,from)
				end
			end
		end
		return #targets<1 and to_select:hasSkill("xdyifu")
	end,
	feasible = function(self,targets,from)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local plist = sgs.PlayerList()
			for i = 1,#targets do plist:append(targets[i]) end
			for _,cn in sgs.list(self:getUserString():split("+"))do
				local dc = dummyCard(cn,"_xdyifu")
				if dc then
					if dc:targetFixed() then return true end
					dc:addSubcards(self:getSubcards())
					return dc:targetsFeasible(plist,from)
				end
			end
		end
		return #targets>0
	end,
	on_validate_in_response = function(self,from)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local choice = {}
			local room = from:getRoom()
			for _,pc in ipairs(self:getUserString():split("+")) do
				local has = false
				for _,p in sgs.list(room:getAlivePlayers()) do
					if p:hasSkill("xdyifu") then
						local n = p:getChangeSkillState("xdyifu")
						if n==1 and pc=="lightning"
						or n==2 and pc==from:property("Suijiyingbian"):toString()
						or n==3 and pc=="iron_chain" then
							has = true
							break
						end
					end
				end
				if has then table.insert(choice,pc) end
			end
			if #choice<1 then return nil end
			choice = room:askForChoice(from,"xdyifu",table.concat(choice,"+"))
			local tos = sgs.SPlayerList()
			for _,p in sgs.list(room:getAlivePlayers()) do
				if p:hasSkill("xdyifu") then
					local n = p:getChangeSkillState("xdyifu")
					if n==1 and choice=="lightning"
					or n==2 and choice==from:property("Suijiyingbian"):toString()
					or n==3 and choice=="iron_chain" then
						tos:append(p)
					end
				end
			end
			tos = room:askForPlayerChosen(from,tos,"xdyifu","xdyifu0:")
			if tos then
				local n = tos:getChangeSkillState("xdyifu")
				if n<3 then n = n+1 else n = 1 end
	           	room:setChangeSkillState(tos,"xdyifu",n)
			else
				return nil
			end
			local c = dummyCard(choice)
			c:setSkillName("_xdyifu")
			c:addSubcard(self)
			return c
		end
		return self
	end,
	on_validate = function(self,use)
		if sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
			local choice = {}
			local room = use.from:getRoom()
			for _,pc in ipairs(self:getUserString():split("+")) do
				local has = false
				for _,p in sgs.list(room:getAlivePlayers()) do
					if p:hasSkill("xdyifu") then
						local n = p:getChangeSkillState()
						if n==1 and pc=="lightning"
						or n==2 and pc==use.from:property("Suijiyingbian"):toString()
						or n==3 and pc=="iron_chain" then
							has = true
							break
						end
					end
				end
				if has then table.insert(choice,pc) end
			end
			if #choice<1 then return nil end
			choice = room:askForChoice(use.from,"xdyifu",table.concat(choice,"+"))
			local tos = sgs.SPlayerList()
			for _,p in sgs.list(room:getAlivePlayers()) do
				if p:hasSkill("xdyifu") then
					local n = p:getChangeSkillState("xdyifu")
					if n==1 and choice=="lightning"
					or n==2 and choice==use.from:property("Suijiyingbian"):toString()
					or n==3 and choice=="iron_chain" then
						tos:append(p)
					end
				end
			end
			tos = room:askForPlayerChosen(use.from,tos,"xdyifu","xdyifu0:")
			if tos then
				local n = tos:getChangeSkillState("xdyifu")
				if n<3 then n = n+1 else n = 1 end
	           	room:setChangeSkillState(tos,"xdyifu",n)
			else
				return nil
			end
			local c = dummyCard(choice)
			c:setSkillName("_xdyifu")
			c:addSubcard(self)
			return c
		else
			local choice = ""
			for _,p in sgs.list(use.to) do
				local n = p:getChangeSkillState("xdyifu")
				if n==1 then choice = "lightning"
				elseif n==2 then choice = use.from:property("Suijiyingbian"):toString()
				elseif n==3 then choice = "iron_chain" end
			end
			if choice=="" then return nil end
			local room = use.from:getRoom()
			room:setPlayerProperty(use.from,"xdyifuvsCN",ToData(choice))
			room:setPlayerMark(use.from,"xdyifuvsId",self:getEffectiveId())
			if room:askForUseCard(use.from,"@@xdyifuvs","xdyifuvs0:"..choice) then
				for _,p in sgs.list(use.to) do
					local n = p:getChangeSkillState("xdyifu")
					if n<3 then n = n+1 else n = 1 end
					room:setChangeSkillState(p,"xdyifu",n)
				end
			end
		end
		return nil
	end,
}
xdyifuvs = sgs.CreateViewAsSkill{
	name = "xdyifuvs&",
	n = 1,
	view_filter = function(self,selected,to_select)
		return to_select:getTypeId()==1
		and sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	end,
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="@@xdyifuvs" then
			pattern = sgs.Self:property("xdyifuvsCN"):toString()
			local c = sgs.Sanguosha:cloneCard(pattern)
			c:addSubcard(sgs.Self:getMark("xdyifuvsId"))
			c:setSkillName("_xdyifu")
			return c
		end
		if #cards<1 then return end
		local new_card = xdyifucard:clone()
		new_card:setUserString(pattern)
		for _,c in ipairs(cards) do
			new_card:addSubcard(c)
		end
		return new_card
	end,
	enabled_at_response = function(self,player,pattern)
		if sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then
			for _,p in sgs.list(player:getAliveSiblings(true))do
				if p:hasSkill("xdyifu") then
					local n = p:getChangeSkillState("xdyifu")
					local choice = ""
					if n==1 then choice = "lightning"
					elseif n==2 then choice = player:property("Suijiyingbian"):toString()
					elseif n==3 then choice = "iron_chain" end
					for _,pc in ipairs(pattern:split("+"))do
						if pc==choice then return true end
					end
				end
			end
		end
		return pattern=="@@xdyifuvs"
	end,
	enabled_at_play = function(self,player)
		for _,p in sgs.list(player:getAliveSiblings(true))do
			if p:hasSkill("xdyifu") then
				return true
			end
		end
	end,
}
xdyifu = sgs.CreateTriggerSkill{
	name = "xdyifu",
	change_skill = true,
	events = {sgs.RoundStart,sgs.EventAcquireSkill,sgs.TargetConfirmed},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		for _,p in sgs.list(room:getAlivePlayers()) do
			if p:hasSkill(self,true) then
				if not player:hasSkill("xdyifuvs",true) then
					room:attachSkillToPlayer(player,"xdyifuvs")
				end
				break
			end
		end
		if event==sgs.TargetConfirmed then
	       	local use = data:toCardUse()
			if use.card:getTypeId()>0 and table.contains(use.card:getSkillNames(),self:objectName())
			and use.to:contains(player) and player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				player:drawCards(1,self:objectName())
			end
		end
		return false
	end
}
xd_shenzhangjiao:addSkill(xdyifu)
addToSkills(xdyifuvs)
xdtianjie = sgs.CreateTriggerSkill{
	name = "xdtianjie",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.ConfirmDamage,sgs.FinishJudge,sgs.BeforeCardsMove,sgs.PostCardEffected},
	can_trigger = function(self,target)
		return true
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.ConfirmDamage then
	        local damage = data:toDamage()
			if damage.reason=="lightning"
			or damage.card and damage.card:isKindOf("Lightning") then
				local tos = sgs.SPlayerList()
				for _,p in sgs.list(room:getAlivePlayers()) do
					if damage.to==p or damage.to:isAdjacentTo(p) then
						tos:append(p)
					end
				end
				if tos:isEmpty() then return false end
				for _,p in sgs.list(room:getAllPlayers()) do
					if p:hasSkill(self) then
						local to = room:askForPlayerChosen(p,tos,self:objectName(),"xdtianjie0:"..damage.to:objectName(),false,true)
						if to then
							damage.from = p
							damage.to = to
							damage.damage = 1
						end
					end
				end
				data:setValue(damage)
			end
		elseif event==sgs.FinishJudge then
			local judge = data:toJudge()
			if judge.reason=="lightning" and not judge.card:isKindOf("Jink") then
				for _,p in sgs.list(room:getAllPlayers()) do
					if p:hasSkill(self) then
						room:sendCompulsoryTriggerLog(p,self)
						local _judge = sgs.JudgeStruct()
						_judge.who = judge.who
						_judge.pattern = judge.pattern
						_judge.good = judge.good
						_judge.reason = judge.reason
						_judge.time_consuming = judge.time_consuming
						_judge.retrial_by_response = judge.retrial_by_response
						_judge.negative = judge.negative
						_judge.throw_card = judge.throw_card
						_judge.play_animation = judge.play_animation
						room:judge(_judge)
						if _judge.who:hasFlag("xdtianjieBf") then
							if _judge:isBad() then
								local id = _judge.who:getMark("xdtianjieId")
								local damage = sgs.DamageStruct("lightning",nil,_judge.who,3,sgs.DamageStruct_Thunder)
								if id>0 then damage.card = sgs.Sanguosha:getCard(id-1) end
								room:damage(damage)
							end
						else
							judge.who:setFlags("xdtianjieBf")
						end
						break
					end
				end
			end
		elseif event==sgs.BeforeCardsMove then
	     	local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceDelayedTrick) and move.to==sgs.Player_PlaceTable then
				for i,id in sgs.list(move.card_ids)do
					if move.from_places:at(i)==sgs.Player_PlaceDelayedTrick and sgs.Sanguosha:getCard(id):isKindOf("Lightning") then
						move.from:setMark("xdtianjieId",id+1)
					end
				end
			end
		elseif event==sgs.PostCardEffected then
            local effect = data:toCardEffect()
			if effect.card:isKindOf("Lightning") then
				effect.to:setFlags("-xdtianjieBf")
				effect.to:setMark("xdtianjieId",0)
			end
		end
		return false
	end
}
xd_shenzhangjiao:addSkill(xdtianjie)

xd_shenjiaxu = sgs.General(miscellaneous,"xd_shenjiaxu","god",3)
xdjiandai = sgs.CreateTriggerSkill{
    name = "xdjiandai",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.GameStart,sgs.EventAcquireSkill,sgs.TurnOver},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.TurnOver then
			return not player:faceUp()
		elseif player:faceUp() then
			room:sendCompulsoryTriggerLog(player,self)
			player:turnOver()
		end
	end,
}
xd_shenjiaxu:addSkill(xdjiandai)
xdfangchanvs = sgs.CreateViewAsSkill{
	name = "xdfangchan",
	enabled_at_play = function(self,player)
		return false
	end,
	view_as = function(self,cards)
		local n = sgs.Self:getMark("xdfangchanId")
		local dc = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(n):objectName())
		dc:setSkillName("_xdfangchan")
		return dc
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern:startsWith("@@xdfangchan")
	end,
}
xdfangchan = sgs.CreateTriggerSkill{
    name = "xdfangchan",
	view_as_skill = xdfangchanvs,
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseChanging,sgs.CardsMoveOneTime},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseChanging then
			local change = data:toPhaseChange()
			if change.to == sgs.Player_NotActive then
				for _,p in sgs.list(room:getAllPlayers())do
					if not p:hasSkill(self) then continue end
					local ids1 = sgs.IntList()
					local ids2 = sgs.IntList()
					for _,id in sgs.list(room:getDiscardPile())do
						if p:getMark(id.."xdfangchanId-Clear")>0 then
							local c = sgs.Sanguosha:getCard(id)
							if c:isNDTrick() then
								ids1:append(id)
							end
							if c:isDamageCard() then
								ids2:append(id)
							end
						end
					end
					local ids = sgs.IntList()
					if ids1:length()==1 then
						ids:append(ids1:first())
					end
					if ids2:length()==1 then
						ids:append(ids2:first())
					end
					if ids:length()>0 then
						room:sendCompulsoryTriggerLog(p,self)
						room:fillAG(ids,p)
						local id = room:askForAG(p,ids,true,self:objectName())
						if id<0 then id = ids:first() end
						room:clearAG(p)
						local c = sgs.Sanguosha:getCard(id)
						local dc = dummyCard(c:objectName())
						dc:setSkillName(self:objectName())
						room:setPlayerMark(p,"xdfangchanId",id)
						if dc:isAvailable(p) and room:askForUseCard(p,"@@xdfangchan","xdfangchan0:"..c:objectName())
						then continue end
						p:obtainCard(c)
					end
				end
			end
		else
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile then
				for _,id in sgs.list(move.card_ids)do
					player:addMark(id.."xdfangchanId-Clear")
				end
			end
		end
	end,
}
xd_shenjiaxu:addSkill(xdfangchan)
xdjuemei = sgs.CreateTriggerSkill{
    name = "xdjuemei",
	waked_skills = "_wuqibingfa",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.QuitDying,sgs.HpChanged},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.HpChanged then
			if player:getLostHp()>0
			then return end
		end
		for _,p in sgs.list(room:getAllPlayers())do
			if p:hasSkill(self) then
				room:sendCompulsoryTriggerLog(p,self)
				for _,id in sgs.list(sgs.Sanguosha:getRandomCards(true))do
					if room:getCardOwner(id) then continue end
					local c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("Wuqibingfa") and c:isAvailable(p) then
						room:addPlayerMark(p,"&xdjuemei")
						room:useCard(sgs.CardUseStruct(c,p))
						if p:getMark("&xdjuemei")%2==0 then
							for _,s in sgs.list(p:getVisibleSkillList())do
								if p:hasInnateSkill(s:objectName()) then
									room:detachSkillFromPlayer(p,s:objectName())
									break
								end
							end
						end
						break
					end
				end
			end
		end
	end,
}
xd_shenjiaxu:addSkill(xdjuemei)
xdluoshu = sgs.CreateTriggerSkill{
    name = "xdluoshu",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.EventPhaseStart},
	waked_skills = "luanwu,jianshu,yongdi,xingshuai,fencheng,olqimou,xiongyi,xiongsuan,zaowang,xdfenbo",
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()~=sgs.Player_Start
			then return end
			local sks = {}
			for _,s in sgs.list({"luanwu","jianshu","yongdi","xingshuai","fencheng","olqimou","xiongyi","xiongsuan","zaowang","xdfenbo"})do
				if player:hasSkill(s,true) then continue end
				table.insert(sks,s)
			end
			if #sks<1 then return end
			room:sendCompulsoryTriggerLog(player,self)
			local choice = {}
			for _,s in sgs.list(RandomList(sks))do
				table.insert(choice,s)
				if #choice>2 then break end
			end
			choice = room:askForChoice(player,self:objectName(),table.concat(choice,"+"))
			room:acquireSkill(player,choice)
		end
	end,
}
xd_shenjiaxu:addSkill(xdluoshu)
xdfenbo = sgs.CreateTriggerSkill{
    name = "xdfenbo",
	frequency = sgs.Skill_Limited,
	events = {sgs.RoundStart,sgs.RoundEnd},
	limit_mark = "@xdfenbo", 
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.RoundStart and player:getMark("@xdfenbo")>0 and player:askForSkillInvoke(self) then
			room:removePlayerMark(player,"@xdfenbo")
			room:doSuperLightbox(player,self:objectName())
			for _,p in sgs.list(room:getAllPlayers())do
				room:doAnimate(1,player:objectName(),p:objectName())
			end
			local choice = {}
			for _,p in sgs.list(room:getAllPlayers())do
				local str = room:askForChoice(p,self:objectName(),"xdfenbo1+xdfenbo2+xdfenbo3",data,"","xdfenbo0")
				choice[p:objectName()] = str
			end
			for _,p in sgs.list(room:getAllPlayers())do
				if choice[p:objectName()]~="xdfenbo1" then
					p:turnOver()
				end
				if choice[p:objectName()]~="xdfenbo2" then
					p:drawCards(2,self:objectName())
				end
				if choice[p:objectName()]~="xdfenbo3" then
					room:acquireSkill(p,"zhendu")
					p:addMark("xdfenbo_zhendu_lun")
				end
			end
		elseif event==sgs.RoundEnd and player:getMark("xdfenbo_zhendu_lun")>0 then
			room:detachSkillFromPlayer(player,"zhendu",false,true)
		end
	end,
}
miscellaneous:addSkills(xdfenbo)
--装备技能
wuqibingfaskillvs = sgs.CreateViewAsSkill{
	name = "_wuqibingfa",
	n = 1,
	view_filter = function(self,selected,to_select)
		return true
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local dc = sgs.Sanguosha:cloneCard("slash")
		dc:setSkillName("_wuqibingfa")
		dc:addSubcard(cards[1])
		return dc
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern:startsWith("@@_wuqibingfa")
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
wuqibingfaskill = sgs.CreateTriggerSkill{
	name = "_wuqibingfa",
	view_as_skill = wuqibingfaskillvs,
	events = {sgs.BeforeCardsMove,sgs.EventPhaseChanging},
	priority = {0},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
    	if (event == sgs.BeforeCardsMove) then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip) and move.reason.m_skillName~="BreakCard"
			and move.from:objectName()==player:objectName() then
				for i,id in sgs.list(move.card_ids)do
					if move.from_places:at(i)==sgs.Player_PlaceEquip
					and sgs.Sanguosha:getCard(id):isKindOf("Wuqibingfa") then
						room:sendCompulsoryTriggerLog(player,self:objectName())
						local ids = sgs.IntList()
						ids:append(id)
						move:removeCardIds(ids)
						data:setValue(move)
						room:breakCard(id,player)
						local n = 0
						for _,s in sgs.qlist(player:getVisibleSkillList()) do
							if not s:inherits("SPConvertSkill")
							and not s:isAttachedLordSkill()
							then n = n+1 end
						end
						if n<1 then continue end
						local tos = room:askForPlayersChosen(player,room:getAlivePlayers(),self:objectName(),1,n,"_wuqibingfa0:"..n,true)
						for _,p in sgs.qlist(tos) do
							room:setPlayerMark(p,"&_wuqibingfa-Clear",1)
						end
					end
				end
			end
		else
			local change = data:toPhaseChange()
			if change.to ~= sgs.Player_NotActive then return end
			for _,p in sgs.qlist(room:getAllPlayers()) do
				if p:getMark("&_wuqibingfa-Clear")>0 and p:getCardCount()>0 and dummyCard():isAvailable(p) then
					room:askForUseCard(p,"@@_wuqibingfa!","_wuqibingfa1:")
				end
			end
		end
	end
}
exclusive_cards:addSkills(wuqibingfaskill)
--装备
wuqibingfa = sgs.CreateTreasure{
	name = "_wuqibingfa",
	class_name = "Wuqibingfa",
	suit = 0,
	number = 1,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,wuqibingfaskill,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,self:objectName(),true,true)
		return false
	end,
}
wuqibingfa:setParent(exclusive_cards)
wuqibingfa:clone(0,1):setParent(exclusive_cards)

sgs.Sanguosha:setPackage(exclusive_cards)

lijueguosi = sgs.General(miscellaneous, "lijueguosi", "qun", 4)
xiongsuanCard = sgs.CreateSkillCard{
	name = "xiongsuanCard", 
	filter = function(self, targets, to_select) 
		return #targets<1
	end,
	on_use = function(self, room, source, targets)
		room:removePlayerMark(source, "@scary")
		room:doSuperLightbox(source,self:getSkillName())
		for _,p in sgs.list(targets)do
			room:damage(sgs.DamageStruct(self:getSkillName(), source, p))
			source:drawCards(3, self:getSkillName())
			local SkillList = {}
			for _,s in sgs.qlist(p:getVisibleSkillList()) do
				if not s:inherits("SPConvertSkill") and not s:isAttachedLordSkill()
				and s:getFrequency() == sgs.Skill_Limited then
					table.insert(SkillList, s:objectName())
				end
			end
			table.insert(SkillList, "cancel")
			if #SkillList>1 and p:isAlive() then
				local choice = room:askForChoice(source,self:getSkillName(),table.concat(SkillList, "+"),ToData(p))
				p:addMark(choice..":xiongsuan-Clear")
			end
		end
	end
}
xiongsuanVS = sgs.CreateOneCardViewAsSkill{
	name = "xiongsuan", 
	filter_pattern = ".", 
	view_as = function(self, card) 
		local cards = xiongsuanCard:clone()
		cards:addSubcard(card)
		return cards
	end, 
	enabled_at_play = function(self, player)
		return player:getMark("@scary") > 0
	end
}
xiongsuan = sgs.CreatePhaseChangeSkill{
	name = "xiongsuan", 
	view_as_skill = xiongsuanVS, 
	frequency = sgs.Skill_Limited, 
	limit_mark = "@scary", 
	can_trigger = function(self,player)
		return player and player:getPhase() == sgs.Player_Finish
	end,
	on_phasechange = function(self, player)
		local room = player:getRoom()
		for _,p in sgs.qlist(room:getAlivePlayers()) do
			for _,s in sgs.qlist(p:getVisibleSkillList()) do
				if p:getMark(s:objectName()..":xiongsuan-Clear")>0 then
					local m = s:getLimitMark()
					if m~="" and p:getMark(m)<1 then
						room:addPlayerMark(p, m)
					end
				end
			end
		end
	end
}
lijueguosi:addSkill(xiongsuan)

sgs.Sanguosha:setPackage(miscellaneous)

local ol_demon = sgs.Sanguosha:getPackage("ol_demon")

olmo_simayi = sgs.General(ol_demon, "olmo_simayi", "wei", 3)
olmoguofuCard = sgs.CreateSkillCard{
	name = "olmoguofuCard",
	target_fixed = true,
	about_to_use = function(self,room,use)
		local tpns = {}
		for _,pn in sgs.list(use.from:property("olmoguofuPns"):toString():split("+"))do
			if use.from:getMark(pn.."olmoguofuBan-Clear")>0 then continue end
			local dc = dummyCard(pn)
			if dc then
				dc:setSkillName("olmoguofu")
				if dc:isAvailable(use.from) then
					table.insert(tpns,pn)
				end
			end
		end
		if #tpns<1 then return end
		local pn = room:askForChoice(use.from,"olmoguofu",table.concat(tpns,"+"))
		room:setPlayerProperty(use.from,"olmoguofuPn",ToData(pn))
		room:askForUseCard(use.from,"@@olmoguofu","olmoguofu0:"..pn)
	end
}
olmoguofuvs = sgs.CreateViewAsSkill{
	name = "olmoguofu",
	n = 1,
	view_filter = function(self,selected,to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		return pattern~="" and to_select:hasTip("olmoguofu")
	end,
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if #cards<1 then
			if pattern=="" then return olmoguofuCard:clone() end
			return
		end
		if pattern=="@@olmoguofu" then
			pattern = sgs.Self:property("olmoguofuPn"):toString()
		end
		local dc = sgs.Sanguosha:cloneCard(pattern:split("+")[1])
		dc:setSkillName("olmoguofu")
		dc:addSubcard(cards[1])
		return dc
	end,
	enabled_at_response = function(self,player,pattern)
		local pns = player:property("olmoguofuPns"):toString():split("+")
		for _,pn in sgs.list(pattern:split("+"))do
			if player:getMark(pn.."olmoguofuBan-Clear")>0 then continue end
			if table.contains(pns,pn) then return true end
		end
		return pattern=="@@olmoguofu"
	end,
	enabled_at_play = function(self,player)
		for _,pn in sgs.list(player:property("olmoguofuPns"):toString():split("+"))do
			if player:getMark(pn.."olmoguofuBan-Clear")>0 then continue end
			local dc = dummyCard(pn)
			if dc then
				dc:setSkillName("olmoguofu")
				if dc:isAvailable(player)
				then return true end
			end
		end
	end,
}
olmoguofu = sgs.CreateTriggerSkill{
    name = "olmoguofu",
	view_as_skill = olmoguofuvs,
	events = {sgs.RoundStart,sgs.HpChanged,sgs.Damage,sgs.PreCardUsed},
	can_trigger = function(self,player)
		return true
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.RoundStart or event==sgs.HpChanged then
			if player:isAlive() and player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				for _,id in sgs.list(room:getDrawPile())do
					local c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("Jink") then
						player:obtainCard(c)
						if player:handCards():contains(id) then
							room:setCardTip(id,"olmoguofu")
						end
						return
					end
				end
				for _,id in sgs.list(room:getDiscardPile())do
					local c = sgs.Sanguosha:getCard(id)
					if c:isKindOf("Jink") then
						player:obtainCard(c)
						if player:handCards():contains(id) then
							room:setCardTip(id,"olmoguofu")
						end
						return
					end
				end
			end
		elseif event==sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:getTypeId()>0 and table.contains(use.card:getSkillNames(),self:objectName()) then
				room:addPlayerMark(player,use.card:objectName().."olmoguofuBan-Clear")
				use.m_addHistory = false
				data:setValue(use)
			end
		else
			local damage = data:toDamage()
			for _,p in sgs.qlist(room:getAlivePlayers())do
				local pns = p:property("olmoguofuPns"):toString():split("+")
				if damage.card then
					if table.contains(pns,damage.card:objectName()) then continue end
					table.insert(pns,damage.card:objectName())
				else
					if table.contains(pns,damage.reason) then continue end
					if sgs.Sanguosha:getSkill(damage.reason)
					then table.insert(pns,damage.reason) end
				end
				room:setPlayerProperty(p,"olmoguofuPns",ToData(table.concat(pns,"+")))
				if #pns>0 and p:hasSkill(self,true) then
					local sts = {}
					for _,pn in sgs.list(pns)do
						table.insert(sts,pn)
						table.insert(sts,"|")
					end
					p:setSkillDescriptionSwap(self:objectName(),"%arg11",table.concat(sts,"+"))
					room:changeTranslation(p,self:objectName())
				end
			end
		end
	end,
}
olmo_simayi:addSkill(olmoguofu)
olmoguofubf = sgs.CreateCardLimitSkill{
	name = "#olmoguofubf",
	limit_list = function(self,player,card)
		return "ignore"
	end,
	limit_pattern = function(self,player,card)
		if card:hasTip("olmoguofu")
		and player:hasSkill("olmoguofu",true)
		then return card:toString() end
		return ""
	end
}
olmo_simayi:addSkill(olmoguofubf)
olmomoubian = sgs.CreateTriggerSkill{
    name = "olmomoubian",
	waked_skills = "olmozhouxi",
	events = {sgs.EventPhaseStart},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()~=sgs.Player_Start or not player:hasSkill(self) then return end
			local pns = player:property("olmoguofuPns"):toString():split("+")
			if #pns>2 and player:getMark("&olmorumo")<1 and player:askForSkillInvoke(self,data) then
				room:setPlayerMark(player,"&olmorumo",1)
				player:peiyin(self)
				local skills = {}
				for _,st in sgs.list(pns)do
					if table.contains(getOLmoDamageSks(),st)
					then table.insert(skills,st) end
				end
				if #skills>0 then
					room:handleAcquireDetachSkills(player,table.concat(skills,"|"))
				end
				room:acquireSkill(player,"olmozhouxi")
			end
		end
	end,
}
olmo_simayi:addSkill(olmomoubian)
olmorumo = sgs.CreateTriggerSkill{
    name = "#olmorumo",
	events = {sgs.RoundEnd,sgs.DamageDone},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.DamageDone then
			local damage = data:toDamage()
			if damage.from then
				damage.from:addMark("olmorumoDamage_lun")
			end
		else
			if player:getMark("&olmorumo")>0 and player:getMark("olmorumoDamage_lun")<1
			then room:loseHp(player,1,true,player,"olmorumo") end
		end
	end,
}
olmo_simayi:addSkill(olmorumo)
local olmoDamageSks = {}
function getOLmoDamageSks()
	if #olmoDamageSks<1 then
		for _,gn in sgs.list(sgs.Sanguosha:getLimitedGeneralNames())do
			for _,sk in sgs.list(sgs.Sanguosha:getGeneral(gn):getVisibleSkillList())do
				if table.contains(olmoDamageSks,sk:objectName()) then continue end
				local skp = sk:getDescription()
				if string.find(skp,"对") and string.find(skp,"造成")
				and string.find(skp,"点") and string.find(skp,"伤害") then
					skp = skp:split("对")[2]
					if string.find(skp,"造成") then
						skp = skp:split("造成")[2]
						if string.find(skp,"点") then
							skp = skp:split("点")[2]
							if string.find(skp,"伤害") then
								table.insert(olmoDamageSks,sk:objectName())
							end
						end
					end
					--table.insert(olmoDamageSks,sk:objectName())
				end
			end
		end
	end
	return olmoDamageSks
end
olmozhouxi = sgs.CreateTriggerSkill{
    name = "olmozhouxi",
	events = {sgs.EventPhaseStart,sgs.RoundEnd,sgs.DamageDone},
	can_trigger = function(self,player)
		return player and player:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()==sgs.Player_Start and player:hasSkill(self) then
				local choice = {}
				for _,s in sgs.list(RandomList(getOLmoDamageSks()))do
					if player:hasSkill(s,true) then continue end
					table.insert(choice,s)
					if #choice>2 then break end
				end
				if #choice<1 then return end
				room:sendCompulsoryTriggerLog(player,self)
				choice = room:askForChoice(player,self:objectName(),table.concat(choice,"+"))
				room:acquireNextTurnSkills(player,self:objectName(),choice)
			end
		elseif event==sgs.DamageDone then
			local damage = data:toDamage()
			if damage.from then
				player:addMark(damage.from:objectName().."olmozhouxiDamage_lun")
			end
		else
			for _,p in sgs.list(room:getAllPlayers())do
				if player:getMark(p:objectName().."olmozhouxiDamage_lun")>0
				and p:hasSkill(self,true) and player:canSlash(p,false) then
					if player:askForSkillInvoke(self,ToData("slash:"..p:objectName()),false) then
						local dc = dummyCard()
						dc:setSkillName("_olmozhouxi")
						room:useCard(sgs.CardUseStruct(dc,player,p))
					end
				end
			end
		end
	end,
}
ol_demon:addSkills(olmozhouxi)

sgs.Sanguosha:setPackage(ol_demon)

local extensioncard = sgs.Package("51OLTrick",sgs.Package_CardPack)

ol_shengsiyugong = sgs.CreateTrickCard{
	name = "ol_shengsiyugong",
	class_name = "Shengsiyugong",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
	    return to_select~=source and to_select:hasFlag("Global_Dying")
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
		and not source:isProhibited(to_select,self)
	end,
	about_to_use = function(self,room,use)
       	if use.to:isEmpty() then
			local dyp = room:getCurrentDyingPlayer()
			if dyp then use.to:append(dyp) end
		end
		self:cardOnUse(room,use)
	end,
	on_effect = function(self,effect)
		if effect.to:isDead() then return end
		local room = effect.to:getRoom()
		room:recover(effect.to,sgs.RecoverStruct(effect.from,self,2))
		effect.from:addMark("ol_shengsiyugongTo"..effect.to:objectName())
	end,
}
ol_hongyundangtou = sgs.CreateTrickCard{
	name = "ol_hongyundangtou",
	class_name = "Hongyundangtou",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
	    return to_select~=source and to_select:getHandcardNum()>0
		and not source:isProhibited(source,self) and not source:isProhibited(to_select,self)
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	about_to_use = function(self,room,use)
       	use.to:append(use.from)
		self:cardOnUse(room,use)
	end,
	on_effect = function(self,effect)
		if effect.to:isDead() then return end
		local room = effect.to:getRoom()
		local sc = room:askForDiscard(effect.to,"ol_hongyundangtou",2,1,true,true,"ol_hongyundangtou0")
		if sc then
			local hearts = {}
			for _,id in sgs.list(room:getDrawPile())do
				local c = sgs.Sanguosha:getCard(id)
				if c:getSuit()==2 then table.insert(hearts,id) end
			end
			for _,id in sgs.list(room:getDiscardPile())do
				local c = sgs.Sanguosha:getCard(id)
				if c:getSuit()==2 then table.insert(hearts,id) end
			end
			local dc = dummyCard()
			for _,id in sgs.list(RandomList(hearts))do
				dc:addSubcard(id)
				if dc:subcardsLength()>=sc:subcardsLength() then break end
			end
			effect.to:obtainCard(dc)
		end
	end,
}
ol_younantongdang = sgs.CreateTrickCard{
	name = "ol_younantongdang",
	class_name = "Younantongdang",
--	subtype = "ba_card",
	subclass = sgs.LuaTrickCard_TypeGlobalEffect,
    target_fixed = true,
    can_recast = false,
	on_effect = function(self,effect)
		if effect.to:isDead() then return end
		local room = effect.to:getRoom()
		room:setPlayerChained(effect.to,true)
	end,
}
ol_leigongzhuwo = sgs.CreateTrickCard{
	name = "ol_leigongzhuwo",
	class_name = "Leigongzhuwo",
--	subtype = "ba_card",
	subclass = sgs.LuaTrickCard_TypeGlobalEffect,
    target_fixed = true,
    can_recast = false,
	on_effect = function(self,effect)
		if effect.to:isDead() then return end
		local room = effect.to:getRoom()
		local judge = sgs.JudgeStruct()
		judge.pattern = ".|spade|2~9"
		judge.good = false
		judge.negative = true
		judge.reason = "lightning"
		judge.who = effect.to
		room:judge(judge)
		if judge:isBad() then
			effect.to:removeTag("LeigongzhuwoDamage")
			room:damage(sgs.DamageStruct("lightning",nil,effect.to,3,sgs.DamageStruct_Thunder))
			if effect.to:getTag("LeigongzhuwoDamage"):toBool() then
				effect.from:drawCards(1,"ol_leigongzhuwo")
			end
		end
	end,
}
ol_liangleichadao = sgs.CreateTrickCard{
	name = "ol_liangleichadao",
	class_name = "Liangleichadao",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
	    return to_select~=source and not source:isProhibited(to_select,self)
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	on_effect = function(self,effect)
		if effect.to:isDead() then return end
		local room = effect.to:getRoom()
		local ids = {}
		for _,id in sgs.list(room:getDrawPile())do
			local c = sgs.Sanguosha:getCard(id)
			if c:isDamageCard() then table.insert(ids,id) end
		end
		for _,id in sgs.list(room:getDiscardPile())do
			local c = sgs.Sanguosha:getCard(id)
			if c:isDamageCard() then table.insert(ids,id) end
		end
		local dc = dummyCard()
		for _,id in sgs.list(RandomList(ids))do
			dc:addSubcard(id)
			if dc:subcardsLength()>=2 then break end
		end
		effect.to:obtainCard(dc)
	end,
}
ol_xiongdiqixinCard = sgs.CreateSkillCard{
	name = "ol_xiongdiqixinCard",
	target_fixed = true,
	about_to_use = function(self,room,use)
		
	end
}
ol_xiongdiqixinvs = sgs.CreateViewAsSkill{
	name = "ol_xiongdiqixin",
	n = 1,
	expand_pile = "#ol_xiongdiqixin",
	response_pattern = "@@ol_xiongdiqixin!",
	view_filter = function(self,selected,to_select)
		return not to_select:isEquipped()
	end,
	view_as = function(self,cards)
		if #cards<1 then return end
		local dc = ol_xiongdiqixinCard:clone()
		for _,c in sgs.list(cards)do
			dc:addSubcard(c)
		end
		return dc
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
extension:addSkills(ol_xiongdiqixinvs)
ol_xiongdiqixin = sgs.CreateTrickCard{
	name = "ol_xiongdiqixin",
	class_name = "Xiongdiqixin",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = false,
	can_recast = false,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
	    return to_select~=source and not source:isProhibited(to_select,self)
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	on_effect = function(self,effect)
		local ids = effect.from:handCards()
		if ids:isEmpty() or effect.to:isDead() then return end
		local room = effect.to:getRoom()
		room:notifyMoveToPile(effect.to,ids,"ol_xiongdiqixin")
		local dc = room:askForUseCard(effect.to,"@@ol_xiongdiqixin!","ol_xiongdiqixin0:"..effect.from:objectName())
		if dc then
			local moves = sgs.CardsMoveList()
			local reason = sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_OVERRIDE,effect.from:objectName(),effect.to:objectName(),"ol_liangleichadao","")
			for _,id in sgs.list(effect.to:handCards())do
				if dc:getSubcards():contains(id) then
					moves:append(sgs.CardsMoveStruct(id,effect.from,sgs.Player_PlaceHand,reason))
				end
			end
			for _,id in sgs.list(ids)do
				if dc:getSubcards():contains(id) then continue end
				moves:append(sgs.CardsMoveStruct(id,effect.to,sgs.Player_PlaceHand,reason))
			end
			room:moveCardsAtomic(moves,false)
			if effect.from:getHandcardNum()<effect.to:getHandcardNum() then
				effect.from:drawCards(1,"ol_xiongdiqixin")
			elseif effect.from:getHandcardNum()>effect.to:getHandcardNum() then
				effect.to:drawCards(1,"ol_xiongdiqixin")
			end
		end
	end,
}
ol_qianjiu = sgs.CreateTrickCard{
	name = "ol_qianjiu",
	class_name = "Qianjiu",
--	subtype = "ba_card",
	subclass = sgs.LuaTrickCard_TypeGlobalEffect,
    target_fixed = true,
    can_recast = false,
	on_effect = function(self,effect)
		if effect.to:isDead() then return end
		local room = effect.to:getRoom()
		if room:askForUseCard(effect.to,"$Analeptic#.|.|9","ol_qianjiu0") then return end
		room:loseHp(effect.to,1,true,effect.from,"ol_qianjiu")
	end,
}
ol_wutianwujie = sgs.CreateTrickCard{
	name = "ol_wutianwujie",
	class_name = "Wutianwujie",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
    available = function(self,player)
    	return self:cardIsAvailable(player)
		and not player:isProhibited(player,self)
    end,
	filter = function(self,targets,to_select,source)
	    return not source:isProhibited(to_select,self)
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
	end,
	about_to_use = function(self,room,use)
       	if use.to:isEmpty() then use.to:append(use.from) end
		self:cardOnUse(room,use)
	end,
	on_effect = function(self,effect)
		if effect.to:isDead() then return end
		local room = effect.to:getRoom()
		local choice = {}
		for _,s in sgs.list(RandomList(getOLmoDamageSks()))do
			if effect.to:hasSkill(s,true) then continue end
			table.insert(choice,s)
			if #choice>2 then break end
		end
		if #choice<1 then return end
		choice = room:askForChoice(effect.to,self:objectName(),table.concat(choice,"+"))
		room:acquireNextTurnSkills(effect.to,self:objectName(),choice)
	end,
}
ol_luojingxiashi = sgs.CreateTrickCard{
	name = "ol_luojingxiashi",
	class_name = "Luojingxiashi",
	subclass = sgs.LuaTrickCard_TypeSingleTargetTrick,
	target_fixed = true,
	can_recast = false,
    available = function(self,player)
    	for _,to in sgs.list(player:getAliveSiblings())do
			if CanToCard(self,player,to) then
				return self:cardIsAvailable(player)
			end
		end
    end,
	filter = function(self,targets,to_select,source)
	    return to_select~=source and to_select:hasFlag("Global_Dying")
		and #targets<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,source,self,to_select)
		and not source:isProhibited(to_select,self)
	end,
	about_to_use = function(self,room,use)
       	if use.to:isEmpty() then
			local dyp = room:getCurrentDyingPlayer()
			if dyp then use.to:append(dyp) end
		end
		self:cardOnUse(room,use)
	end,
	on_effect = function(self,effect)
		if effect.to:isDead() then return end
		local room = effect.to:getRoom()
		local dy = effect.from:getTag("ol_luojingxiashiData"):toDying()
		room:killPlayer(effect.to,dy.damage,dy.hplost)
		effect.from:drawCards(1,self:objectName())
	end,
}

for i=0,3 do
	ol_shengsiyugong:clone(i,4):setParent(extensioncard)
	ol_hongyundangtou:clone(i,5):setParent(extensioncard)
	ol_younantongdang:clone(i,6):setParent(extensioncard)
	ol_luojingxiashi:clone(i,7):setParent(extensioncard)
	ol_leigongzhuwo:clone(i,8):setParent(extensioncard)
	ol_liangleichadao:clone(i,10):setParent(extensioncard)
	ol_xiongdiqixin:clone(i,11):setParent(extensioncard)
	ol_qianjiu:clone(i,12):setParent(extensioncard)
	ol_wutianwujie:clone(i,13):setParent(extensioncard)
end

olmomingcha = sgs.CreateTriggerSkill{
    name = "olmomingcha",
	events = {sgs.GameStart},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.GameStart then
			local tp = room:askForPlayerChosen(player,room:getOtherPlayers(p),self:objectName(),"olmomingcha0",true,true)
			if tp then
				local log = sgs.LogMessage()
				log.type = "$olmomingchaLog1"
				if tp:getRole()=="rebel" then
					log.type = "$olmomingchaLog2"
					room:broadcastProperty(tp,"role")
				end
				log.from = player
				log.to:append(tp)
				log.arg = "rebel"
				room:sendLog(log)
			end
		end
	end,
}
extensioncard:addSkills(olmomingcha)


poker = sgs.CreateBasicCard{
	name = "__poker",
	class_name = "Poker",
	subtype = "poker_card",
	target_fixed = true,
    can_recast = false,
    available = function(self,player)
		return false
    end,
}
for s=0,3 do
	for n=1,13 do
		poker:clone(s,n):setParent(extension)
	end
end
poker:clone(4,14):setParent(extension)
poker:clone(5,15):setParent(extension)

chenshou = sgs.General(extension, "chenshou", "shu", 3)
chenzhi = sgs.CreateTriggerSkill{
    name = "chenzhi",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.AfterDrawNCards,sgs.BeforeCardsMove,sgs.DrawNCards},
	priority = {9},
	can_trigger = function(self,player)
		return true
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.to_place==sgs.Player_DiscardPile then
				local dc = dummyCard()
				local pokerDiscardPile = room:getTag("pokerDiscardPile"):toIntList()
				for _,id in sgs.qlist(move.card_ids)do
					if sgs.Sanguosha:getEngineCard(id):objectName():endsWith("poker") then
						pokerDiscardPile:prepend(id)
						dc:addSubcard(id)
					end
				end
				if dc:subcardsLength()<1 then return end
				move:removeCardIds(dc:getSubcards())
				data:setValue(move)
				room:setTag("pokerDiscardPile",ToData(pokerDiscardPile))
				room:moveCardTo(dc,nil,sgs.Player_PlaceTable,true)
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:getMark("&pokerDiscardPile")>0 or p:getMark("&pokerDrawPile")>0 then
						room:setPlayerMark(p,"&pokerDiscardPile",pokerDiscardPile:length())
						return
					end
				end
				room:setPlayerMark(player,"&pokerDiscardPile",pokerDiscardPile:length())
			elseif move.to_place==sgs.Player_DrawPile then
				local dc = dummyCard()
				local pokerDrawPile = room:getTag("pokerDrawPile"):toIntList()
				for _,id in sgs.qlist(move.card_ids)do
					if sgs.Sanguosha:getEngineCard(id):objectName():endsWith("poker") then
						pokerDrawPile:prepend(id)
						dc:addSubcard(id)
					end
				end
				if dc:subcardsLength()<1 then return end
				move:removeCardIds(dc:getSubcards())
				data:setValue(move)
				room:setTag("pokerDrawPile",ToData(pokerDrawPile))
				room:moveCardTo(dc,nil,sgs.Player_PlaceTable,false)
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:getMark("&pokerDiscardPile")>0 or p:getMark("&pokerDrawPile")>0 then
						room:setPlayerMark(p,"&pokerDrawPile",pokerDrawPile:length())
						return
					end
				end
				room:setPlayerMark(player,"&pokerDrawPile",pokerDrawPile:length())
			elseif move.to_place==sgs.Player_PlaceHand and move.reason.m_reason==sgs.CardMoveReason_S_REASON_DRAW
			and move.to:objectName()==player:objectName() and player:isAlive() and player:hasSkill(self) then
				local draw = player:getTag("chenzhiDrawData"):toDraw()
				if draw.reason~=move.reason.m_skillName then return end
				--move.from_places:clear()
				local ids = sgs.IntList()
				local pokerDrawPile = room:getTag("pokerDrawPile"):toIntList()
				local pokerDiscardPile = room:getTag("pokerDiscardPile"):toIntList()
				for i=1,move.card_ids:length() do
					if pokerDrawPile:isEmpty() then
						if pokerDiscardPile:isEmpty() then
							for i=0,sgs.Sanguosha:getCardCount()-1 do
								if ids:contains(i) or room:getCardOwner(i) then continue end
								if sgs.Sanguosha:getEngineCard(i):objectName():endsWith("poker")
								then pokerDiscardPile:append(i) end
							end
							if pokerDiscardPile:isEmpty() then return end
						end
						pokerDrawPile = RandomList(pokerDiscardPile)
						pokerDiscardPile = sgs.IntList()
					end
					local id = pokerDrawPile:last()
					if draw.top then id = pokerDrawPile:first() end
					--move.from_places:append(sgs.Player_PlaceTable)
					pokerDrawPile:removeOne(id)
					ids:append(id)
				end
				room:setTag("pokerDrawPile",ToData(pokerDrawPile))
				room:setTag("pokerDiscardPile",ToData(pokerDiscardPile))
				room:sendCompulsoryTriggerLog(player,self)
				if draw.top then room:returnToTopDrawPile(move.card_ids)
				else room:returnToEndDrawPile(move.card_ids) end
				move.card_ids = ids
				data:setValue(move)
				player:setTag(draw.reason.."chenzhiDraws",ToData(move.card_ids))
				for _,p in sgs.qlist(room:getAlivePlayers())do
					if p:getMark("&pokerDrawPile")>0 or p:getMark("&pokerDiscardPile")>0 then
						room:setPlayerMark(p,"&pokerDiscardPile",pokerDiscardPile:length())
						room:setPlayerMark(p,"&pokerDrawPile",pokerDrawPile:length())
						return
					end
				end
				room:setPlayerMark(player,"&pokerDiscardPile",pokerDiscardPile:length())
				room:setPlayerMark(player,"&pokerDrawPile",pokerDrawPile:length())
			end
		elseif event==sgs.DrawNCards then
			local draw = data:toDraw()
			if player:hasSkill(self,true) then
				player:setTag("chenzhiDrawData",data)
			end
		elseif event==sgs.AfterDrawNCards then
			local draw = data:toDraw()
			if player:hasSkill(self,true) then
				local ids = player:getTag(draw.reason.."chenzhiDraws"):toIntList()
				if ids:isEmpty() then return end
				draw.card_ids = ids
			end
		end
	end,
}
chenshou:addSkill(chenzhi)
local dianmoSks = {}
function getdianmoSks()
	if #dianmoSks<1 then
		for _,gn in sgs.list(sgs.Sanguosha:getLimitedGeneralNames())do
			for _,sk in sgs.list(sgs.Sanguosha:getGeneral(gn):getVisibleSkillList())do
				if table.contains(dianmoSks,sk:objectName()) then continue end
				if sgs.Sanguosha:getViewAsSkill(sk:objectName())==nil then continue end
				local skp = sk:getDescription()
				if string.find(skp,"你可以将") and (string.find(skp,"牌当") or string.find(skp,"】当")) then
					skp = skp:split("你可以将")[2]
					if (string.find(skp,"牌当") or string.find(skp,"】当"))
					and (string.find(skp,"使用") or string.find(skp,"打出"))
					then table.insert(dianmoSks,sk:objectName()) end
				elseif sk:objectName():endsWith("longhun") then
					table.insert(dianmoSks,sk:objectName())
				end
			end
		end
	end
	return dianmoSks
end
dianmo = sgs.CreateTriggerSkill{
    name = "dianmo",
	events = {sgs.EventPhaseStart,sgs.Damaged},
	on_trigger = function(self,event,player,data,room)
		if event==sgs.EventPhaseStart then
			if player:getPhase()~=sgs.Player_Start
			then return end
		else
			player:addMark("dianmoDamaged-Clear")
			if player:getMark("dianmoDamaged-Clear")>1
			then return end
		end
		local sks = {}
		for _,s in sgs.list(RandomList(getdianmoSks()))do
			if player:hasSkill(s,true) then continue end
			table.insert(sks,s)
			if #sks>1 then break end
		end
		if #sks>0 and player:askForSkillInvoke(self,data) then
			local sk = room:askForChoice(player,self:objectName(),table.concat(sks,"+"))
			sks = player:getTag("dianmoObtainSks"):toString():split("|")
			local sks2 = {sk}
			if #sks>3 or #sks>0 and room:askForChoice(player,self:objectName(),"dianmo1+dianmo2")=="dianmo2" then
				local sk2 = room:askForChoice(player,self:objectName(),table.concat(sks,"+"))
				table.removeOne(sks,sk2)
				table.insert(sks2,"-"..sk2)
			end
			table.insert(sks,sk)
			player:setTag("dianmoObtainSks",ToData(table.concat(sks,"|")))
			room:handleAcquireDetachSkills(player,table.concat(sks2,"|"))
			sk = 4-#sks
			if sk>0 then
				player:drawCards(sk,self:objectName())
			end
		end
	end,
}
chenshou:addSkill(dianmo)
zaibiCard = sgs.CreateSkillCard{
	name = "zaibiCard",
	target_fixed = true,
	will_throw = false,
	on_use = function(self, room, source, targets)
		UseCardRecast(source,self,"zaibi",self:subcardsLength())
		for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards(true))do
			local ec = sgs.Sanguosha:getEngineCard(id)
			if ec:isKindOf("Chunqiubi") and room:getCardOwner(id)==nil and ec:isAvailable(source) then
				room:setCardMapping(id,nil,sgs.Player_PlaceTable)
				local tps = sgs.SPlayerList()
				tps:append(source)
				ec:use(room,source,tps)
				break
			end
		end
	end
}
zaibi = sgs.CreateViewAsSkill{
	name = "zaibi",
	n = 998,
	waked_skills = "_chunqiubi",
	view_filter = function(self,selected,to_select)
		for _,c in sgs.list(selected)do
			if c:getNumber()==to_select:getNumber()
			then return end
		end
		for _,c in sgs.list(selected)do
			if math.abs(c:getNumber()-to_select:getNumber())==1
			then return true end
		end
		return #selected<1
	end,
	view_as = function(self,cards)
		if #cards<2 then return end
		local sc = zaibiCard:clone()
		for _,c in sgs.list(cards)do
			sc:addSubcard(c)
		end
		return sc
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#zaibiCard")<1
	end,
}
chenshou:addSkill(zaibi)

_chunqiubiCard = sgs.CreateSkillCard{
	name = "_chunqiubiCard",
	target_fixed = false,
	will_throw = false,
	filter = function(self,selected,to_select,source)
		return #selected<1
	end,
	on_use = function(self,room,source,targets)
		local choices = {"_chunqiubi1","_chunqiubi2","_chunqiubi3","_chunqiubi4"}
		local log = sgs.LogMessage()
		log.type = "$_chunqiubiLog"
		log.from = source
		log.arg = choices[math.random(1,4)]
		room:sendLog(log)
		local choices2 = {}
		for _,ct in sgs.list(choices)do
			if ct==log.arg or #choices2>0 then
				table.insert(choices2,ct)
			end
		end
		for _,ct in sgs.list(choices)do
			if table.contains(choices2,ct) then continue end
			table.insert(choices2,ct)
		end
		room:getThread():delay()
		for _,p in sgs.list(targets)do
			log.type = "$_chunqiubiLog2"
			log.from = p
			if room:askForChoice(source,"_chunqiubi","chunqiubi01+chunqiubi02",ToData(p))=="chunqiubi02" then
				local choices3 = {log.arg}
				for i=#choices2,2,-1 do
					table.insert(choices3,choices2[i])
				end
				choices2 = choices3
			end
			for _,ct in sgs.list(choices2)do
				log.arg = ct
				room:sendLog(log)
				if ct=="_chunqiubi1" then
					room:loseHp(p,1,true,source,"_chunqiubi")
				elseif ct=="_chunqiubi2" then
					p:drawCards(p:getLostHp(),"_chunqiubi")
				elseif ct=="_chunqiubi3" then
					room:recover(p,sgs.RecoverStruct("_chunqiubi",source))
				elseif ct=="_chunqiubi4" then
					room:askForDiscard(p,"_chunqiubi",p:getLostHp(),p:getLostHp())
				end
			end
		end
	end
}
chunqiubivs = sgs.CreateViewAsSkill{
	name = "_chunqiubi",
	enabled_at_play = function(self,player)
		return player:usedTimes("#_chunqiubiCard")<1
	end,
	view_as = function(self,cards)
		return _chunqiubiCard:clone()
	end,
}
chunqiubiskill = sgs.CreateTriggerSkill{
    name = "_chunqiubi",
	view_as_skill = chunqiubivs,
	events = {sgs.BeforeCardsMove},
	can_trigger = function(self,player)
		return true
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.BeforeCardsMove then
			local move = data:toMoveOneTime()
			if move.from_places:contains(sgs.Player_PlaceEquip) and move.reason.m_skillName~="BreakCard"
			and move.from:objectName()==player:objectName() then
				for i,id in sgs.qlist(move.card_ids)do
					if move.from_places:at(i)==sgs.Player_PlaceEquip
					and sgs.Sanguosha:getEngineCard(id):isKindOf("Chunqiubi") then
						local ids = sgs.IntList()
						ids:append(id)
						move:removeCardIds(ids)
						data:setValue(move)
						room:breakCard(id,player)
					end
				end
			end
		end
	end,
}
extension:addSkills(chunqiubiskill)
_chunqiubi = sgs.CreateTreasure{
	name = "_chunqiubi",
	class_name = "Chunqiubi",
	suit = 2,
	number = 5,
	on_install = function(self,player)
		local room = player:getRoom()
		room:acquireSkill(player,chunqiubiskill,true,true,false)
		return false
	end,
	on_uninstall = function(self,player)
		local room = player:getRoom()
		room:detachSkillFromPlayer(player,self:objectName(),true,true)
		return false
	end,
}
_chunqiubi:setParent(extension)

of_liuxuan = sgs.General(extension,"of_liuxuan$","shu",4)
ofsifenCard = sgs.CreateSkillCard{
	name = "ofsifenCard",
	target_fixed = false,
	filter = function(self,targets,to_select,source)
		if source:getMark("ofsifenRed-PlayClear")>0 then
			local dc = dummyCard("duel","ofsifen")
			dc:addSubcards(self:getSubcards())
			return source:getMark(to_select:objectName().."ofsifenDuel-PlayClear")>0
			and CanToCard(dc,source,to_select,targets)
		end
		return #targets<1 and to_select:getHandcardNum()>0 and to_select~=source
	end,
	about_to_use = function(self,room,use)
		if self:subcardsLength()>0 then
			local dc = dummyCard("duel","ofsifen")
			dc:addSubcards(self:getSubcards())
			use.card = dc
		end
		self:cardOnUse(room,use)
	end,
	on_use = function(self,room,player,targets)
		for i,p in sgs.list(targets)do
			local dc = room:askForUseCard(p,"@@ofsifen!","ofsifen0")
			if dc then
				room:setPlayerMark(player,"ofsifenRed-PlayClear",dc:subcardsLength())
				room:addPlayerMark(player,p:objectName().."ofsifenDuel-PlayClear")
			end
		end
	end
}
ofsifen = sgs.CreateViewAsSkill{
	name = "ofsifen",
	n = 999,
	response_pattern = "@@ofsifen!",
	view_filter = function(self,selected,to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUseReason()
		if pattern=="@@ofsifen!" then return not to_select:isEquipped() end
		local n = sgs.Self:getMark("ofsifenRed-PlayClear")
		return n>0 and to_select:isRed() and #selected<n
	end,
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUseReason()
		if pattern=="@@ofsifen!" then
			if #cards<1 then return end
			local dc = sgs.Sanguosha:cloneCard("duel")
			dc:setSkillName("_ofsifen")
			for i,c in sgs.list(cards)do
				dc:addSubcard(c)
			end
			return dc
		end
		local n = sgs.Self:getMark("ofsifenRed-PlayClear")
		if n>0 then
			if #cards<n then return end
			local dc = ofsifenCard:clone()
			for i,c in sgs.list(cards)do
				dc:addSubcard(c)
			end
			return dc
		end
		return ofsifenCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#ofsifenCard")<1 or player:getMark("ofsifenRed-PlayClear")>0
	end,
}
of_liuxuan:addSkill(ofsifen)
offunanCard = sgs.CreateSkillCard{
	name = "offunanCard",
	filter = function(self,targets,to_select,from)
		local slash = dummyCard()
		local plist = sgs.PlayerList()
		for i = 1,#targets do
			plist:append(targets[i])
		end
		return slash:targetFilter(plist,to_select,from)
	end,
	on_validate = function(self,use) --这是0610新加的哦~~~~
		use.from:skillInvoked("offunan",-1)
		use.m_isOwnerUse = false
		local room = use.from:getRoom()
		room:addPlayerMark(use.from,"offunanUse-Clear")
		use.from:skillInvoked("jijiang",-1)
		for _,p in sgs.qlist(room:getLieges("shu",use.from)) do
			local slash = room:askForCard(p,"slash","@jijiang-slash:"..use.from:objectName(),ToData(use.from),sgs.Card_MethodResponse,use.from,false,"",true)
			if slash then return slash end
		end
		room:loseHp(use.from,1,true,use.from,"offunan")
		use.from:drawCards(2,"offunan")
		return nil
	end
}
local function hasShu(player)
	for _,p in sgs.qlist(player:getAliveSiblings()) do
		if p:getKingdom() == "shu"
		then return true end
	end
	return false
end
offunanVS = sgs.CreateViewAsSkill{
	name = "offunan$",
	view_as = function()
		return offunanCard:clone()
	end,
	enabled_at_play = function(self,player)
		return hasShu(player) and player:getMark("offunanUse-Clear")<1
		and player:hasLordSkill("offunan")
		and sgs.Slash_IsAvailable(player)
	end,
	enabled_at_response = function(self,player,pattern)
		return hasShu(player) and (pattern == "slash" or pattern == "@jijiang")
		and player:hasLordSkill("offunan") and player:getMark("offunanUse-Clear")<1
		and sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE
	end
}
offunan = sgs.CreateTriggerSkill{
	name = "offunan$",
	events = {sgs.CardAsked},
	view_as_skill = offunanVS,
	on_trigger = function(self,event,player,data)
		local room = player:getRoom()
		local pattern = data:toStringList()[1]
		local prompt = data:toStringList()[2]
		if (pattern ~= "slash") or string.find(prompt,"jijiang-slash")
		or player:getMark("offunanUse-Clear")>0 then return false end
		local lieges = room:getLieges("shu",player)
		if lieges:isEmpty() or not player:askForSkillInvoke(self,data) then return false end
		room:addPlayerMark(player,"offunanUse-Clear")
		player:skillInvoked("jijiang",-1)
		for _,liege in sgs.qlist(lieges) do
			local slash = room:askForCard(liege,"slash","@jijiang-slash:" .. player:objectName(),ToData(player),sgs.Card_MethodResponse,player)
			if slash then
				room:provide(slash)
				return true
			end
		end
		room:loseHp(player,1,true,player,"offunan")
		player:drawCards(2,"offunan")
		return false
	end,
	can_trigger = function(self,target)
		return target and target:hasLordSkill("offunan")
	end
}
of_liuxuan:addSkill(offunan)

of_caohuan = sgs.General(extension,"of_caohuan","wei",3)
ofjunweiVS = sgs.CreateViewAsSkill{
	name = "ofjunwei",
	n = 2,
	view_filter = function(self,selected,to_select)
        return #selected<1 or selected[1]:getColor()==to_select:getColor()
	end,
	view_as = function(self,cards)
		if #cards > 1 then
			local sc = sgs.Sanguosha:cloneCard("nullification")
			sc:setSkillName(self:objectName())
			for _,c in sgs.list(cards)do
				sc:addSubcard(c)
			end
			return sc
		end
	end,
	enabled_at_response = function(self,player,pattern)
		return pattern == "nullification" and player:getHandcardNum()>1
		and player:getMark("ofjunweiUse-Clear")<1
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
ofjunwei = sgs.CreateTriggerSkill{
	name = "ofjunwei",
	view_as_skill = ofjunweiVS;
	events = {sgs.PreCardUsed,sgs.CardFinished,sgs.PostCardEffected},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.PreCardUsed then
			local use = data:toCardUse()
			if use.card:isKindOf("Nullification") and table.contains(use.card:getSkillNames(),"ofjunwei") then
				room:addPlayerMark(player,"ofjunweiUse-Clear")
			end
		elseif event==sgs.CardFinished then
			local use = data:toCardUse()
			if use.card:isKindOf("Nullification") and table.contains(use.card:getSkillNames(),"ofjunwei") then
				if table.contains(use.nullified_list,"_ALL_TARGETS") then return end
				use = room:getTag("UseHistory"..use.card:toString()):toCardUse()
				if table.contains(use.no_offset_list,"_HAS_EFFECT") then
					if use.whocard then
						use = room:getTag("UseHistory"..use.whocard:toString()):toCardUse()
						if use.to:isEmpty() then return end
						room:setCardFlag(use.card,"ofjunweiBf0")
						local tps = room:getCardTargets(use.from,use.card,use.to)
						tps = room:askForPlayersChosen(player,tps,self:objectName(),0,2,"ofjunwei0:"..use.card:objectName(),true)
						room:setCardFlag(use.card,"-ofjunweiBf0")
						for i,p in sgs.list(tps)do
							room:setCardFlag(use.card,"ofjunweiBf")
							use.to:append(p)
						end
						room:sortByActionOrder(use.to)
						room:setTag("UseHistory"..use.card:toString(),ToData(use))
						use.to = tps
						room:setTag("ofjunweiBf"..use.card:toString(),ToData(use))
					end
				end
			end
		elseif event==sgs.PostCardEffected then
			local effect = data:toCardEffect()
			if effect.card:hasFlag("ofjunweiBf") then
				local use = room:getTag("UseHistory"..effect.card:toString()):toCardUse()
				local use2 = room:getTag("ofjunweiBf"..effect.card:toString()):toCardUse()
				local tps = sgs.SPlayerList()
				for _,p in sgs.list(use.to)do
					if use2.to:contains(p)
					then continue end
					tps:append(p)
				end
				for _,p in sgs.list(use.to)do
					if p==effect.to and tps:contains(p) and tps:last()~=p then break end
					if use2.to:contains(p) then
						use2.to:removeOne(p)
						room:setTag("ofjunweiBf"..effect.card:toString(),ToData(use2))
						local effect2 = sgs.CardEffectStruct()
						effect2.multiple = use.to:length()>1
						effect2.card = effect.card
						effect2.from = effect.from
						effect2.to = p
						room:cardEffect(effect2)
					end
				end
			end
		end
	end,
}
of_caohuan:addSkill(ofjunwei)
ofmoran = sgs.CreateTriggerSkill{
    name = "ofmoran",
	frequency = sgs.Skill_Compulsory,
	events = {sgs.Damaged,sgs.TurnStart},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.Damaged then
			if player:hasSkill(self) then
				room:sendCompulsoryTriggerLog(player,self)
				local sf = SetShifa(self,player)
				sf.effect = function(owner,x)
					owner:drawCards(2*x,"ofmoran")
				end
				player:setMark("ofmoranNum",sf.x)
				for _,s in sgs.list(player:getVisibleSkillList())do
					if s:isAttachedLordSkill() then continue end
					room:addPlayerMark(player,"Qingcheng"..s:objectName())
					player:addMark("ofmoranSkill="..s:objectName())
				end
			end
		else
			for _,p in sgs.list(room:getAlivePlayers())do
				local n = p:getMark("ofmoranNum")
				if n>0 then
					p:removeMark("ofmoranNum")
					if n==1 then
						for i,m in sgs.list(p:getMarkNames())do
							if m:contains("ofmoranSkill=") then
								local ms = m:split("=")
								p:removeMark("ofmoranSkill="..ms[2])
								room:removePlayerMark(p,"Qingcheng"..ms[2])
							end
						end
					end
				end
			end
		end
	end,
}
of_caohuan:addSkill(ofmoran)

of_sunhao = sgs.General(extension,"of_sunhao","wu",5)
ofshezuoCard = sgs.CreateSkillCard{
	name = "ofshezuoCard",
	target_fixed = true,
	filter = function(self,targets,to_select,source)
		return #targets<1 and to_select~=source
		and source:canPindian(to_select)
	end,
	on_use = function(self,room,player,targets)
		player:drawCards(1,"ofshezuo")
		local tps = sgs.SPlayerList()
		for i,p in sgs.list(room:getOtherPlayers(player))do
			if player:canPindian(p) then tps:append(p) end
		end
		local tp = room:askForPlayerChosen(player,tps,"ofshezuo","ofshezuo0")
		if tp then player:pindian(tp,"ofshezuo") end
	end
}
ofshezuovs = sgs.CreateViewAsSkill{
	name = "ofshezuo",
	response_pattern = "@@ofshezuo!",
	view_as = function(self,cards)
		if sgs.Sanguosha:getCurrentCardUsePattern()=="@@ofshezuo!" then
			local dc = sgs.Self:getMark("ofshezuoId")
			dc = sgs.Sanguosha:getCard(dc)
			dc = sgs.Sanguosha:cloneCard(dc:objectName())
			dc:addSubcards(sgs.Self:handCards())
			dc:setSkillName("ofshezuo")
			return dc
		end
		return ofshezuoCard:clone()
	end,
	enabled_at_play = function(self,player)
		return player:usedTimes("#ofshezuoCard")<1
	end,
}
ofshezuo = sgs.CreateTriggerSkill{
    name = "ofshezuo",
	view_as_skill = ofshezuovs,
	events = {sgs.Pindian,sgs.EventPhaseStart},
	can_trigger = function(self,target)
		return target and target:isAlive()
	end,
	on_trigger = function(self,event,player,data,room)
		if event==sgs.Pindian then
			local pd = data:toPindian()
			local tps = sgs.SPlayerList()
			if pd.success then
				tps:append(pd.to)
			else
				if pd.from_number==pd.to_number then
					tps:append(pd.from)
					tps:append(pd.to)
				else
					tps:append(pd.from)
				end
			end
			for i,p in sgs.list(room:getAllPlayers())do
				if p:hasSkill(self) then
					for _,t in sgs.list(tps)do
						if t:isDead() then continue end
						if p:getMark("&ofshezuo+1-Clear")>0 then
							local dc = room:askForDiscard(t,self:objectName(),1,1,false,true)
							if dc then
								dc = room:askForDiscard(t,self:objectName(),1,1,false,true)
								if dc==nil then room:loseHp(t,1,true,p,self:objectName()) end
							else
								room:loseHp(t,1,true,p,self:objectName())
							end
						end
						if p:getMark("&ofshezuo+2-Clear")>0 then
							room:setPlayerChained(t,true)
							room:damage(sgs.DamageStruct(self:objectName(),nil,t,1,sgs.DamageStruct_Fire))
						end
						if p:getMark("&ofshezuo+3-Clear")>0 then
							local dc = dummyCard()
							dc:addSubcards(t:handCards())
							local ids = room:getAvailableCardList(t,"trick",self:objectName(),dc)
							if ids:isEmpty() then continue end
							room:fillAG(ids,t)
							local id = room:askForAG(t,ids,false,self:objectName(),"ofshezuo30")
							room:clearAG(t)
							room:setPlayerMark(t,"ofshezuoId",id)
							room:askForUseCard(t,"@@ofshezuo!","ofshezuo31:"..sgs.Sanguosha:getCard(id):objectName())
						end
					end
					room:removePlayerMark(p,"&ofshezuo+1-Clear")
					room:removePlayerMark(p,"&ofshezuo+2-Clear")
					room:removePlayerMark(p,"&ofshezuo+3-Clear")
				end
			end
		else
			if player:getPhase()==sgs.Player_Start
			and player:hasSkill(self) and player:askForSkillInvoke(self) then
				local choice = room:askForChoice(player,self:objectName(),"1+2+3",data)
				room:setPlayerMark(player,"&ofshezuo+"+choice+"-Clear",1)
			end
		end
	end,
}
of_sunhao:addSkill(ofshezuo)

of_liuxie = sgs.General(extension,"of_liuxie","qun",3)
ofjixuCard = sgs.CreateSkillCard{
	name = "ofjixuCard",
	will_throw = false,
	filter = function(self,targets,to_select,from)
		if self:subcardsLength()>0 then
			return #targets<2 and to_select:hasFlag("ofjixuTo")
		end
		return #targets<2 and to_select:getMark("ofjixuTo-PlayClear")<1
	end,
	feasible = function(self,targets,from)
		return #targets==2
	end,
	about_to_use = function(self,room,use)
		if self:subcardsLength()<1 then
			self:cardOnUse(room,use)
		end
	end,
	on_use = function(self,room,player,targets)
		local n = 0
		for i,p in sgs.list(targets)do
			n = p:getHandcardNum()
			room:addPlayerMark(p,"ofjixuTo-PlayClear")
			room:setPlayerFlag(p,"ofjixuTo")
		end
		for i,p in sgs.list(room:getAlivePlayers())do
			if table.contains(targets,p) then continue end
			local x = p:getHandcardNum()
			for ii,q in sgs.list(room:getAlivePlayers())do
				if table.contains(targets,q) or i<=ii then continue end
				if x+q:getHandcardNum()<n then
					local ids = room:getNCards(3)
					room:notifyMoveToPile(player,ids,"ofjixu",sgs.Player_DrawPile,true)
					local use = room:askForUseCardStruct(player,"@@ofjixu!","ofjixu0")
					room:notifyMoveToPile(player,ids,"ofjixu",sgs.Player_DrawPile,false)
					for _,t in sgs.list(targets)do
						room:setPlayerFlag(t,"-ofjixuTo")
					end
					local moves = sgs.CardsMoveList()
					if use.card then
						ids = use.card:getSubcards()
						while use.to:length()>0 do
							local tp = use.to:last()
							moves:append(sgs.CardsMoveStruct(ids:last(),tp,sgs.Player_PlaceHand,
							sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,player:objectName(),tp:objectName(),"ofjixu","")))
							ids:removeOne(ids:last())
							if ids:isEmpty() then break end
							use.to:removeOne(tp)
							if use.to:isEmpty() then
								moves:append(sgs.CardsMoveStruct(ids,tp,sgs.Player_PlaceHand,
								sgs.CardMoveReason(sgs.CardMoveReason_S_REASON_GIVE,player:objectName(),tp:objectName(),"ofjixu","")))
							end
						end
					end
					room:moveCardsAtomic(moves,false)
					return
				end
			end
		end
	end,
}
ofjixu = sgs.CreateViewAsSkill{
	name = "ofjixu",
	n = 3,
	expand_pile = "#ofjixu",
	view_filter = function(self,selected,to_select)
		local pattern = sgs.Sanguosha:getCurrentCardUseReason()
		if pattern=="@@ofjixu!" then
			return sgs.Self:getPileName(to_select:getEffectiveId())=="#ofjixu"
		end
	end,
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUseReason()
		if pattern=="@@ofjixu!" then
			if #cards<3 then return end
			local dc = ofjixuCard:clone()
			for i,c in sgs.list(cards)do
				dc:addSubcard(c)
			end
			return dc
		end
		return ofjixuCard:clone()
	end,
	enabled_at_play = function(self,player)
		local n = 0
		for i,p in sgs.list(player:getAliveSiblings(true))do
			if p:getMark("ofjixuTo-PlayClear")>0 then continue end
			n = n+1
		end
		return n>1
	end,
}
of_liuxie:addSkill(ofjixu)
ofyouchongCard = sgs.CreateSkillCard{
	name = "ofyouchongCard",
	will_throw = false,
	filter = function(self,targets,to_select,user)
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		local card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
		if card:targetFixed() then return false end
		return card:targetFilter(plist,to_select,user)
	end,
	feasible = function(self,targets,user)
		local plist = sgs.PlayerList()
		for i = 1,#targets do plist:append(targets[i]) end
		local card = sgs.Sanguosha:cloneCard(self:getUserString():split("+")[1])
		if card:targetFixed() then return true end
		return card:targetsFeasible(plist,user)
	end,
	on_validate = function(self,use)
		local room = use.from:getRoom()
		room:addPlayerMark(use.from,"ofyouchongUse-Clear")
		local tc = room:askForChoice(use.from,"ofyouchong",self:getUserString(),ToData(use.from))
		local tps = sgs.SPlayerList()
		for _,p in sgs.list(room:getAlivePlayers())do
			if p:getHandcardNum()>use.from:getHandcardNum()
			then tps:append(p) end
		end
		tps = room:askForPlayersChosen(use.from,tps,"ofyouchong",1,tps:length(),"ofyouchong0",true,true)
		for _,p in sgs.list(tps)do
			if not p:hasSkill("ofyouchongvs",true) then
				room:attachSkillToPlayer(p,"ofyouchongvs")
			end
			room:setPlayerProperty(p,"ofyouchongCN",ToData(tc))
			local dc = room:askForCard(p,"@@ofyouchong","ofyouchong1:"..use.from:objectName()..":"..tc,ToData(use.from),sgs.Card_MethodResponse,use.from,false,"",true)
			if dc then return dc end
		end
		return nil
	end,
	on_validate_in_response = function(self,user)
		local room = user:getRoom()
		room:addPlayerMark(user,"ofyouchongUse-Clear")
		local tc = room:askForChoice(user,"ofyouchong",self:getUserString(),ToData(user))
		local tps = sgs.SPlayerList()
		for _,p in sgs.list(room:getAlivePlayers())do
			if p:getHandcardNum()>user:getHandcardNum()
			then tps:append(p) end
		end
		tps = room:askForPlayersChosen(user,tps,"ofyouchong",1,tps:length(),"ofyouchong0",true,true)
		for _,p in sgs.list(tps)do
			if not p:hasSkill("ofyouchongvs",true) then
				room:attachSkillToPlayer(p,"ofyouchongvs")
			end
			room:setPlayerProperty(p,"ofyouchongCN",ToData(tc))
			local dc = room:askForCard(p,"@@ofyouchong","ofyouchong1:"..user:objectName()..":"..tc,ToData(user),sgs.Card_MethodResponse,user,false,"",true)
			if dc then return dc end
		end
		return nil
	end,
}
ofyouchong = sgs.CreateViewAsSkill{
	name = "ofyouchong",
	view_as = function(self,cards)
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern=="" then
			local c = sgs.Self:getTag("ofyouchong"):toCard()
			if c then pattern = c:objectName() else return end
		end
		local sc = ofyouchongCard:clone()
		sc:setUserString(pattern)
		return sc
	end,
	enabled_at_play = function(self,player)
		if player:getMark("ofyouchongUse-Clear")>0 then return end
		local has = false
		for _,p in sgs.list(player:getAliveSiblings())do
			if p:getHandcardNum()>player:getHandcardNum()
			then has = true end
		end
		if has==false then return end
		for _,patt in ipairs(patterns())do
			local dc = dummyCard(patt)
			if dc and dc:isKindOf("BasicCard") then
				dc:setSkillName(self:objectName())
				if dc:isAvailable(player)
				then return true end
			end
		end
	end,
	enabled_at_response = function(self,player,pattern)
		if player:getMark("ofyouchongUse-Clear")>0
		or sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE then return end
		local has = false
		for _,p in sgs.list(player:getAliveSiblings())do
			if p:getHandcardNum()>player:getHandcardNum()
			then has = true end
		end
		if has==false then return end
		for _,pt in sgs.list(pattern:split("+"))do
			local dc = dummyCard(pt)
			if dc and dc:isKindOf("BasicCard") then
				return true
			end
		end
	end,
}
ofyouchong:setGuhuoDialog("l")
of_liuxie:addSkill(ofyouchong)
ofyouchongvs = sgs.CreateViewAsSkill{
	name = "ofyouchongvs&",
	n = 3,
	response_pattern = "@@ofyouchong",
	view_filter = function(self,selected,to_select)
		return true
	end,
	view_as = function(self,cards)
		if #cards<3 then return end
		local dc = sgs.Sanguosha:cloneCard(sgs.Self:property("ofyouchongCN"):toString())
		dc:setSkillName("ofyouchong")
		for i,c in sgs.list(cards)do
			dc:addSubcard(c)
		end
		return dc
	end,
	enabled_at_play = function(self,player)
		return false
	end,
}
extension:addSkills(ofyouchongvs)



















sgs.LoadTranslationTable {
	["newgenerals"] = "新将",
	["sgs_entity"] = "三国杀·线下",

	["of_liuxuan"] = "刘璿",
	["#of_liuxuan"] = "暗渊龙吟",
    ["illustrator:of_liuxuan"] = "荆芥",
	["ofsifen"] = "俟奋",
	[":ofsifen"] = "出牌阶段限一次，你可以令一名其他角色将至少一张手牌当做【决斗】使用。若如此做，你摸两张牌，此阶段你可以将X张红色牌当做【决斗】对其使用（X为其转化所用的牌数）。",
	["offunan"] = "赴难",
	[":offunan"] = "主公技，每回合限一次，你可以发动一次“激将”，然后若没有角色响应，你失去1点体力并摸两张牌。",
	["ofsifen0"] = "俟奋：请将至少一张手牌当做【决斗】使用",

	["of_caohuan"] = "曹奂",
	["#of_caohuan"] = "陈留王",
    ["illustrator:of_caohuan"] = "小罗没想好",
	["ofjunwei"] = "君威",
	[":ofjunwei"] = "每回合限一次，你可以将两张同颜色牌当做【无懈可击】使用。当此【无懈可击】生效后，你可以为目标锦囊指定至多两个额外目标（无距离限制）。",
	["ofmoran"] = "默然",
	[":ofmoran"] = "锁定技，当你受到伤害后，你施法：摸2X张牌，且你的技能失效直到施法结束。",
	["ofjunwei0"] = "君威：请为【%src】选择至多两个额外目标",

	["of_sunhao"] = "孙皓[线下]",
	["#of_sunhao"] = "归命侯",
    ["illustrator:of_sunhao"] = "小罗没想好",
	["ofshezuo"] = "设座",
	[":ofshezuo"] = "准备阶段，你可以选择一项，令本回合下次拼点后，没赢的角色执行：1.依次弃置两张牌（不足则失去1点体力）；2.横置并受到1点无来源的火焰伤害；3.将所有手牌当做一张普通锦囊使用。出牌阶段限一次，你可以摸一张牌，然后进行拼点。",
	["ofshezuo:1"] = "依次弃置两张牌（不足则失去1点体力）",
	["ofshezuo:2"] = "横置并受到1点无来源的火焰伤害",
	["ofshezuo:3"] = "将所有手牌当做一张普通锦囊使用",

	["of_liuxie"] = "刘协",
	["#of_liuxie"] = "山阳公",
    ["illustrator:of_liuxie"] = "荆芥",
	["ofjixu"] = "济恤",
	[":ofjixu"] = "出牌阶段每组角色限一次，你可以选择两名角色，若这两名角色手牌数之和小于任意两名除这两名角色之外的角色手牌数之和，你观看牌堆顶3张牌并交给这些角色（每名角色至少一张）。",
	["ofyouchong"] = "优崇",
	[":ofyouchong"] = "每回合限一次，当你需要使用基本牌时，你可以令任意名手牌大于你的角色依次选择是否将3张牌当做你需要的牌打出，视为你使用之。",
	["#ofjixu"] = "济恤观看",
	["ofjixu0"] = "济恤：请选择牌分配（前两张分配给选择的第一名角色）",
	["ofyouchongvs"] = "优崇打出",
	["ofyouchong0"] = "优崇：请选择手牌数大于你的任意名角色",
	["ofyouchong1"] = "优崇：你可以将3张牌替%src打出【%dest】",

	["chenshou"] = "陈寿",
	["#chenshou"] = "婉而成章",
    ["illustrator:chenshou"] = "小罗没想好",
	["chenzhi"] = "沉滞",
	[":chenzhi"] = "锁定技，你摸牌改为从一副扑克牌中摸牌（包含初始手牌）；扑克牌拥有单独的弃牌堆。",
	["dianmo"] = "点墨",
	[":dianmo"] = "准备阶段或你每回合首次受到伤害后，你可以观看两张转化牌的技能，选择其中一获得（至多4个）或替换一个以此法获得的技能，然后摸空置的技能数张牌。",
	["zaibi"] = "载笔",
	[":zaibi"] = "出牌阶段限一次，你可以重铸至少两张连续点数的牌，然后将游戏外的【春秋笔】置入你的装备区。",
	["pokerDrawPile"] = "扑克牌堆",
	["pokerDiscardPile"] = "扑克弃牌堆",
	["dianmo1"] = "获得",
	["dianmo2"] = "替换",

	["__poker"] = "扑克",
	[":__poker"] = "基本牌·扑克<br/><b>时机</b>：出牌阶段，你可以打扑克<br/><b>效果</b>：你不能一人打扑克，所以你无法打扑克。",
	["poker_card"] = "扑克牌",
	["_chunqiubi"] = "春秋笔",
	["chunqiubi"] = "春秋笔",
	[":_chunqiubi"] = "装备牌·宝物<br/><b>宝物技能</b>：出牌阶段限一次，你可以选择一名角色并随机选择一项，其从此项开始正序或逆序依次执行所有项。<br/>起：失去1点体力；<br/>承：摸已失去体力张牌；<br/>转：回复1点体力；<br/>合：弃置已损失体力张手牌；<br/>此牌离开你的装备区后销毁。",
	["$_chunqiubiLog"] = "%from 随机到 %arg",
	["$_chunqiubiLog2"] = "%from 执行 %arg",
	["_chunqiubi1"] = "起：失去1点体力",
	["_chunqiubi2"] = "承：摸已失去体力张牌",
	["_chunqiubi3"] = "转：回复1点体力",
	["_chunqiubi4"] = "合：弃置已损失体力张手牌",
	["chunqiubi01"] = "正序",
	["chunqiubi02"] = "逆序",

	["olmo_simayi"] = "魔司马懿[OL]",
	["#olmo_simayi"] = "无天的魔狼",
	["olmoguofu"] = "诡伏",
	[":olmoguofu"] = "每轮开始时或你的体力值变化后，你获得一张不计入手牌上限的【闪】；技能或牌造成伤害后，你记录此技能名或牌名。你可以将“诡伏”获得的【闪】当做记录的牌名使用（不计入次数且每回合每个牌名限一次）。",
	[":olmoguofu1"] = "每轮开始时或你的体力值变化后，你获得一张不计入手牌上限的【闪】；技能或牌造成伤害后，你记录此技能名或牌名。你可以将“诡伏”获得的【闪】当做记录的牌名使用（不计入次数且每回合每个牌名限一次）。<br/><font color=\"red\"><b>已记录：%arg11</b></font>",
	["olmomoubian"] = "谋变",
	[":olmomoubian"] = "准备阶段，若你“诡伏”的记录数大于等于3，你可以【入魔】，获得“诡伏”记录的技能，并获得“骤袭”。【入魔】后，每轮结束时，若你本轮未造成伤害，你失去1点体力。",
	["olmozhouxi"] = "骤袭",
	[":olmozhouxi"] = "准备阶段，你从3个可造成伤害的技能中选择一个获得之，直到你下回合开始。受到你伤害的角色于本轮结束时可视为对你使用一张【杀】。",
	["olmozhouxi:slash"] = "骤袭：你可以对%src视为使用【杀】",
	["olmoguofu0"] = "诡伏：请将【闪】当【%src】使用",
	["olmorumo"] = "入魔",
	["$olmoguofu1"] = "天命在我，何须急于一时",
	["$olmoguofu2"] = "天数已定，如渊潜龙！",
	["$olmomoubian1"] = "别跟我谈什么对错！我的灵魂，即是我的正义！",
	["$olmomoubian2"] = "我这把剑，该见见血了！",
	["$olmomoubian3"] = "无天无界，我就是天命！",
	["$olmomoubian4"] = "自今日起，我剑由我不由人！",
	["$olmozhouxi1"] = "你降，不降，都得死！",
	["$olmozhouxi2"] = "我就像这夜，终将吞噬一切！",
	["~olmo_simayi"] = "哈哈哈哈哈哈，天数……我还是输给了天数？",

	["olmomingcha"] = "明察",
	[":olmomingcha"] = "游戏开始时，你可以公布一名其他角色的身份是否为反贼。",
	["olmomingcha0"] = "你可以发动“明察”选择公布一名其他角色是否为反贼",
	["$olmomingchaLog1"] = "%to 的身份不为 %arg",
	["$olmomingchaLog2"] = "%to 的身份为 %arg",

	["51OLTrick"] = "OL开黑锦囊",

	["ol_shengsiyugong"] = "生死与共",
	[":ol_shengsiyugong"] = "锦囊牌·单目标锦囊<br/><b>时机</b>：其他角色濒死时对其使用<br/><b>效果</b>：目标回复2点体力。<br/><b>额外效果</b>：本局目标死亡后，你死亡。",
	["ol_shengsiyugong0"] = "你可以对%src使用【生死与共】",
	["ol_hongyundangtou"] = "红运当头",
	[":ol_hongyundangtou"] = "锦囊牌·多目标锦囊<br/><b>时机</b>：出牌阶段，对你和一名有手牌的其他角色使用<br/><b>效果</b>：目标弃置至多两张牌，然后从牌堆或弃牌堆获得等量的♥牌。",
	["ol_hongyundangtou0"] = "红运当头：请弃置至多两张牌，然后获得等量♥牌",
	["ol_younantongdang"] = "有难同当",
	[":ol_younantongdang"] = "锦囊牌·全局锦囊<br/><b>时机</b>：出牌阶段，对所有角色使用<br/><b>效果</b>：目标横置武将牌。",
	["ol_leigongzhuwo"] = "雷公助我",
	[":ol_leigongzhuwo"] = "锦囊牌·全局锦囊<br/><b>时机</b>：出牌阶段，对所有角色使用<br/><b>效果</b>：目标进行【闪电】判定；若目标因此受到了伤害，你摸一张牌。",
	["ol_liangleichadao"] = "两肋插刀",
	[":ol_liangleichadao"] = "锦囊牌·单目标锦囊<br/><b>时机</b>：出牌阶段，对一名其他角色使用<br/><b>效果</b>：目标获得两张伤害牌。",
	["ol_xiongdiqixin"] = "兄弟齐心",
	[":ol_xiongdiqixin"] = "锦囊牌·单目标锦囊<br/><b>时机</b>：出牌阶段，对一名其他角色使用<br/><b>效果</b>：目标重新分配你与其的手牌，然后手牌较少的角色摸一张牌。",
	["ol_xiongdiqixin0"] = "兄弟齐心：请选择分配给%src的牌",
	["#ol_xiongdiqixin"] = "对方手牌",
	["ol_qianjiu"] = "劝酒",
	[":ol_qianjiu"] = "锦囊牌·全局锦囊<br/><b>时机</b>：出牌阶段，对所有角色使用<br/><b>效果</b>：目标需使用一张【酒】或点数为9的牌，否则失去1点体力。",
	["ol_qianjiu0"] = "劝酒：请使用一张【酒】或点数为9的牌，否则失去1点体力",
	["ol_wutianwujie"] = "无天无界",
	[":ol_wutianwujie"] = "锦囊牌·单目标锦囊<br/><b>时机</b>：出牌阶段，对你使用<br/><b>效果</b>：目标从3个可造成伤害的技能中选择一个获得之，直到目标下回合开始。",
	["ol_luojingxiashi"] = "落井下石",
	[":ol_luojingxiashi"] = "锦囊牌·单目标锦囊<br/><b>时机</b>：其他角色濒死时对其使用<br/><b>效果</b>：目标结束濒死结算，然后你摸一张牌。",
	["ol_luojingxiashi0"] = "你可以对%src使用【落井下石】",

	["SkillEffect:s1"] = "你可摸一张牌",
	["SkillEffect:s3"] = "你可卜算3",
	["SkillEffect:s5"] = "你可获得造成伤害的牌",
	["SkillEffect:s8"] = "你可回复1点体力",
	["SkillEffect:s9"] = "你可摸3张牌弃1张牌",
	["SkillEffect:s10"] = "你可摸牌至手牌上限（至多摸5张）",
	["SkillEffect:s13"] = "你可令此牌对你无效",
	["SkillEffect:s16"] = "你可获得此判定牌",
	["SkillEffect:s17"] = "你可增加1点体力上限",
	["SkillEffect:s21"] = "你可获得两张非基本牌",
	["SkillEffect:s22"] = "你可获得两张锦囊牌",
	["SkillEffect:s23"] = "你可摸四张牌并翻面",
	["SkillEffect:s26"] = "你可失去1点体力摸3张牌",
	["SkillEffect:s29"] = "你可令此伤害+1",
	["SkillEffect:s30"] = "你可防止此伤害，令来源摸3张牌",

	["SkillEffect1"] = "你可摸一张牌",
	["SkillEffect2"] = "你可弃置一名角色区域内一张牌",
	["SkillEffect3"] = "你可卜算3",
	["SkillEffect4"] = "你可弃置任意张牌，摸等量的牌",
	["SkillEffect5"] = "你可获得造成伤害的牌",
	["SkillEffect6"] = "你可视为使用无距离与次数限制的【杀】",
	["SkillEffect7"] = "你可获得一名角色区域内一张牌",
	["SkillEffect8"] = "你可回复1点体力",
	["SkillEffect9"] = "你可摸3张牌弃1张牌",
	["SkillEffect10"] = "你可摸牌至手牌上限（至多摸5张）",
	["SkillEffect11"] = "你可令一名角色非锁定技失效直到其回合开始",
	["SkillEffect12"] = "你可令一名角色摸2张牌并翻面",
	["SkillEffect13"] = "你可令此牌对你无效",
	["SkillEffect14"] = "你可令一名其他角色进行判定，若结果为♠，你对其造成2点雷电伤害",
	["SkillEffect15"] = "你可打出一张手牌替换此判定牌",
	["SkillEffect16"] = "你可获得此判定牌",
	["SkillEffect17"] = "若你不为体力上限最高，你可增加1点体力上限",
	["SkillEffect18"] = "你可与一名受伤角色拼点，若你赢，你获得其两张牌",
	["SkillEffect19"] = "你可令至多两名角色各摸一张牌",
	["SkillEffect20"] = "你可令一名角色手牌上限+2，直到其回合结束",
	["SkillEffect21"] = "你可获得两张非基本牌",
	["SkillEffect22"] = "你可获得两张锦囊牌",
	["SkillEffect23"] = "你可摸四张牌并翻面",
	["SkillEffect24"] = "你可令你对一名角色使用牌无次数与距离限制直到你回合结束",
	["SkillEffect25"] = "你可弃置两张牌令你与一名其他角色回复1点体力",
	["SkillEffect26"] = "你可失去1点体力摸3张牌",
	["SkillEffect27"] = "你可交换两名角色手牌",
	["SkillEffect28"] = "你可交换两名角色装备区牌",
	["SkillEffect29"] = "你可令此伤害+1",
	["SkillEffect30"] = "你可防止此伤害，令来源摸3张牌",


	["SkillEvent1"] = "你使用牌后",
	["SkillEvent2"] = "其他角色对你使用牌后",
	["SkillEvent3"] = "出牌阶段开始时",
	["SkillEvent4"] = "你受到伤害后",
	["SkillEvent5"] = "准备阶段",
	["SkillEvent6"] = "结束阶段",
	["SkillEvent7"] = "你造成伤害后",
	["SkillEvent8"] = "你成为【杀】的目标时",
	["SkillEvent9"] = "一名角色进入濒死时",
	["SkillEvent10"] = "你失去装备区牌后",
	["SkillEvent11"] = "你使用或打出【闪】时",
	["SkillEvent12"] = "当一张判定牌生效前",
	["SkillEvent13"] = "你失去手牌后",
	["SkillEvent14"] = "你使用牌被抵消后",
	["SkillEvent15"] = "当一张判定牌生效后",
	["SkillEvent16"] = "当【南蛮入侵】或【万箭齐发】结算后",
	["SkillEvent17"] = "你使用【杀】造成伤害后",
	["SkillEvent18"] = "你于回合外失去红色牌后",
	["SkillEvent19"] = "弃牌阶段开始时",
	["SkillEvent20"] = "一名角色受到【杀】伤害后",
	["SkillEvent21"] = "摸牌阶段开始时",
	["SkillEvent22"] = "你成为普通锦囊牌的目标后",
	["SkillEvent23"] = "一名角色横置后",
	["SkillEvent24"] = "一名角色受到属性伤害后",
	["SkillEvent25"] = "一名角色失去最后手牌后",
	["SkillEvent26"] = "你的体力变化后",
	["SkillEvent27"] = "每轮开始时",
	["SkillEvent28"] = "一名角色造成伤害时",
	["SkillEvent29"] = "一名角色受到伤害时",
	["SkillEvent30"] = "一名其他角色死亡后",

	["olsp_nanhua"] = "南华老仙[OL]",
	["#olsp_nanhua"] = "逍遥仙游",
	["qingshu"] = "青书",
	[":qingshu"] = "锁定技，游戏开始时、准备阶段和结束阶段，你书写一册“天书”。",
	["hedao"] = "合道",
	[":hedao"] = "锁定技，游戏开始时，你可至多拥有两册“天书”。你首次濒死结算后，你可至多拥有三册“天书”。",
	["olshoushu"] = "授术",
	[":olshoushu"] = "出牌阶段限一次，你可以将一册未翻开的“天书”交给一名其他角色。",
	["hedao0"] = "移去天书",
	["$qingshu1"] = "赤紫青黄，唯记万变其一",
	["$qingshu2"] = "天地万法，皆在此书之中",
	["$qingshu3"] = "以小篆记大道，则道可道",
	["$hedao1"] = "不参黄泉，难悟大道",
	["$hedao2"] = "道者，亦置之死地而后生",
	["$hedao3"] = "因果开茅塞，轮回似醍醐",
	["$olshoushu1"] = "此书载天地至理，望汝珍视如命",
	["$olshoushu2"] = "天书非凡物，字字皆玄机",
	["$olshoushu3"] = "我得道成仙，当出世，化生人中",
	["~olsp_nanhua"] = "尔生异心...必获恶报....",

	["xd_shenjiaxu"] = "神贾诩[玄蝶]",
	["&xd_shenjiaxu"] = "神贾诩",
	["#xd_shenjiaxu"] = "蚕室裸泄",
	["designer:xd_shenjiaxu"] = "玄蝶既白",
	["xdjiandai"] = "缄殆",
	[":xdjiandai"] = "锁定技，你始终处于翻面状态。",
	["xdfangchan"] = "纺残",
	[":xdfangchan"] = "锁定技，每个回合结束时，你获得或视为使用本回合弃牌堆中唯一的普通锦囊牌或唯一的伤害牌。",
	["xdjuemei"] = "绝殙",
	[":xdjuemei"] = "锁定技，当有角色脱离受伤或濒死状态时，你装备【吴起兵法】，若为第偶数次发动，你失去武将牌上首个技能。",
	["xdluoshu"] = "络殊",
	[":xdluoshu"] = "锁定技，准备阶段，你从随机三个限定技中选择一个获得之。",
	["xdfenbo"] = "纷殕",
	[":xdfenbo"] = "限定技，每轮开始时，你可以令所有角色同时选择两项：翻面；摸两张牌；本轮获得“鸩毒”。",
	["xdfangchan0"] = "纺残：你可以视为使用【%src】否则获得之",
	["xdfenbo0"] = "请排除不选择项",
	["xdfenbo1"] = "翻面",
	["xdfenbo2"] = "摸两张牌",
	["xdfenbo3"] = "本轮获得“鸩毒”",

	["_wuqibingfa"] = "吴起兵法",
	[":_wuqibingfa"] = "装备牌/宝物<br /><b>宝物技能</b>：当此牌你的离开装备区时，销毁之，然后你选择至多X名角色，本回合结束时，这些角色将一张牌当做【杀】使用（X为你的技能数）。",
	["_wuqibingfa0"] = "吴起兵法：请选择至多%src名角色",
	["_wuqibingfa1"] = "吴起兵法：请选择一张牌当【杀】使用之",

	["xd_shenzhangfei"] = "神张飞[玄蝶]",
	["&xd_shenzhangfei"] = "神张飞",
	["#xd_shenzhangfei"] = "战天魔屠",
	["designer:xd_shenzhangfei"] = "玄蝶既白",
	["xdbaohe"] = "暴喝",
	[":xdbaohe"] = "锁定技，你的锦囊牌均视为无次数限制的【杀】。你牌造成的的伤害值为转化牌所用牌的牌名总字数。",
	["xdrenhai"] = "人骇",
	[":xdrenhai"] = "锁定技，当你对一名角色造成伤害时，其选择任意项令此伤害-X（X为选项序号，可重复选择）：<br/>1.进行【闪电】判定；2.获得“仇海”或“崩坏”；<br/>3.将本项并入邻项；4.获得“无谋”或“止息”。",
	["xdtiantong"] = "天恸",
	[":xdtiantong"] = "锁定技，准备阶段，所有角色失去因“人骇”获得的技能，你获得牌堆中等量张点数最大的牌，然后你选择翻面或复原“人骇”的所有项。",
	["1xdrenhai"] = "1.进行【闪电】判定",
	["2xdrenhai"] = "2.获得“仇海”或“崩坏”",
	["3xdrenhai"] = "3.将本项并入邻项",
	["4xdrenhai"] = "4.获得“无谋”或“止息”",
	["2xdrenhai3xdrenhai"] = "2.获得“仇海”或“崩坏”将本项并入邻项",
	["4xdrenhai3xdrenhai"] = "4.获得“无谋”或“止息”将本项并入邻项",
	["1xdrenhai2xdrenhai3xdrenhai"] = "1.进行【闪电】判定获得“仇海”或“崩坏”将本项并入邻项",
	["4xdrenhai2xdrenhai3xdrenhai"] = "4.获得“无谋”或“止息”获得“仇海”或“崩坏”将本项并入邻项",
	["1xdrenhai2xdrenhai4xdrenhai3xdrenhai"] = "1.进行【闪电】判定获得“仇海”或“崩坏”获得“无谋”或“止息”将本项并入邻项",
	["1xdrenhai4xdrenhai2xdrenhai3xdrenhai"] = "1.进行【闪电】判定获得“无谋”或“止息”获得“仇海”或“崩坏”将本项并入邻项",
	["xdtiantong1"] = "翻面",
	["xdtiantong2"] = "复原“人骇”的所有项",


	["xd_shenzhangjiao"] = "神张角[玄蝶]",
	["#xd_shenzhangjiao"] = "蚁煦蟒噀",
	["designer:xd_shenzhangjiao"] = "玄蝶既白",
	["xdyifu"] = "蚁附",
	[":xdyifu"] = "转换技，每名角色可以将一张基本牌当以下牌使用，你成为此牌目标后摸一张牌。\n天：【闪电】；地：【随机应变】；人：【铁索连环】。",
	[":xdyifu1"] = "转换技，每名角色可以将一张基本牌当以下牌使用，你成为此牌目标后摸一张牌。\n天：【闪电】；<font color=\"#01A5AF\"><s>地：【随机应变】；人：【铁索连环】</s></font>。",
	[":xdyifu2"] = "转换技，每名角色可以将一张基本牌当以下牌使用，你成为此牌目标后摸一张牌。\n<font color=\"#01A5AF\"><s>天：【闪电】</s></font>；地：【随机应变】；<font color=\"#01A5AF\"><s>人：【铁索连环】</s></font>。",
	[":xdyifu3"] = "转换技，每名角色可以将一张基本牌当以下牌使用，你成为此牌目标后摸一张牌。\n<font color=\"#01A5AF\"><s>天：【闪电】；地：【随机应变】</s></font>；人：【铁索连环】。",
	["xdyifuvs"] = "蚁附",
	["xdtianjie"] = "天劫",
	[":xdtianjie"] = "锁定技，【闪电】生效结果改为你对目标或一名与其相邻的角色造成1点雷电伤害。当【闪电】判定牌生效后，若不为【闪】，继续判定。",
	["xdtianjie0"] = "天劫：请对%src或一名与其相邻的角色造成1点雷电伤害",




    ["lijueguosi"] = "李傕&郭汜",
    ["#lijueguosi"] = "犯祚倾祸",
    ["illustrator:lijueguosi"] = "旭",
    ["cv:lijueguosi"] = "《三国演义》",
    ["#lijueguosi"] = "飞狼狂豺",
    ["xiongsuan"] = "凶算",
    [":xiongsuan"] = "限定技，出牌阶段，你可以弃置一张牌并选择一名角色，对其造成1点伤害，然后你摸三张牌，若其拥有限定技，你可以令其中一个限定技于此回合结束后视为未发动。",
    ["$xiongsuan1"] = "让他看看我的箭法~",
    ["$xiongsuan2"] = "我们是太师的人，太师不平反，我们就不能名正言顺！ 郭将军所言极是！",
    ["~lijueguosi"] = "李傕郭汜二贼火拼，两败俱伤~",

	["_taipingyaoshu"] = "太平要术",
	[":_taipingyaoshu"] = "装备牌/防具<br /><b>防具技能</b>：锁定技，防止你受到的属性伤害；你的手牌上限+X（X为场上势力数-1）；当你失去装备区里的【太平要术】后，你摸两张牌，然后若你的体力值大于1，你失去1点体力。",

	["jdmou_sunquan"] = "谋孙权[九鼎]",
	["&jdmou_sunquan"] = "谋孙权",
	["#jdmou_sunquan"] = "江东大帝",
	["illustrator:jdmou_sunquan"] = "官方",
	["jiudingmouzhiheng"] = "制衡",
	[":jiudingmouzhiheng"] = "出牌阶段限一次，你可以弃置任意张牌，然后摸等量的牌。若你弃置了装备区的牌，则你额外摸一张牌。",
	["$jiudingmouzhiheng1"] = "",
	["$jiudingmouzhiheng2"] = "",
	["jiudingmoutongye"] = "统业",
	[":jiudingmoutongye"] = "锁定技，若牌堆没洗牌，你视为拥有“英姿”和“固政”。",
	["$jiudingmoutongye1"] = "",
	["$jiudingmoutongye2"] = "",
	["jiudingmoujiuyuan"] = "救援",
	[":jiudingmoujiuyuan"] = "主公技，出牌阶段限一次，你可以获得一名其他吴势力装备区内的所有牌，然后你回复1点体力。",
	["$jiudingmoujiuyuan1"] = "",
	["$jiudingmoujiuyuan2"] = "",
	["~jdmou_sunquan"] = "",

	["jin_simayan"] = "司马炎[九鼎]",
	["&jin_simayan"] = "司马炎",
    ["#jin_simayan"] = "晋武帝",
	["designer:jin_simayan"] = "官方",
	["cv:jin_simayan"] = "官方",
    ["illustrator:jin_simayan"] = "",
	["juqi"] = "举棋",
	[":juqi"] = "转换技，一名角色的准备阶段，①若为你，你摸3张牌；否则其可以展示一张黑色手牌并交给你②若为你，你本回合使用牌无次数限制且伤害+1；否则其可以展示一张红色手牌并交给你。",
	[":juqi1"] = "转换技，一名角色的准备阶段，①若为你，你摸3张牌；否则其可以展示一张黑色手牌并交给你<font color=\"#01A5AF\"><s>②若为你，你本回合使用牌无次数限制且伤害+1；否则其可以展示一张红色手牌并交给你</s></font>。",
	[":juqi2"] = "转换技，一名角色的准备阶段，<font color=\"#01A5AF\"><s>①若为你，你摸3张牌；否则其可以展示一张黑色手牌并交给你</s></font>②若为你，你本回合使用牌无次数限制且伤害+1；否则其可以展示一张红色手牌并交给你。",
	--[":juqi"] = "转换技，①准备阶段，你摸3张牌；其他角色准备阶段，其可以展示一张黑色手牌并交给你②准备阶段，你本回合使用牌无次数限制且伤害+1；其他角色准备阶段，其可以展示一张红色手牌并交给你。",
	--[":juqi1"] = "转换技，①准备阶段，你摸3张牌；其他角色准备阶段，其可以展示一张黑色手牌并交给你<font color=\"#01A5AF\"><s>②准备阶段，你本回合使用牌无次数限制且伤害+1；其他角色准备阶段，其可以展示一张红色手牌并交给你</s></font>。",
	--[":juqi2"] = "转换技，<font color=\"#01A5AF\"><s>①准备阶段，你摸3张牌；其他角色准备阶段，其可以展示一张黑色手牌并交给你</s></font>②准备阶段，你本回合使用牌无次数限制且伤害+1；其他角色准备阶段，其可以展示一张红色手牌并交给你。",
	["fengtu"] = "封土",
	[":fengtu"] = "其他角色死亡后，你可以令一名未以此法减少体力上限的角色扣减1点体力上限，然后其获得死亡角色位置每轮的额定回合。",
	["taishi"] = "泰始",
	[":taishi"] = "主公技，限定技，一个回合开始前，你可以令所有隐匿角色依次登场。",
	["juqi0"] = "举棋：你可以展示一张%src手牌交给 %dest",
	["fengtu0"] = "封土：你可以令一名角色扣减体力上限并获得 位置%src 的额定回合",
	["fengtuseat"] = "封土位置",

	["keol_duanjiong"] = "段颎",
	["&keol_duanjiong"] = "段颎",
    ["#keol_duanjiong"] = "束马县锋",
	["designer:keol_duanjiong"] = "官方",
	["cv:keol_duanjiong"] = "官方",
    ["illustrator:keol_duanjiong"] = "",
	["keolsaogu"] = "扫谷",
	[":keolsaogu"] = "转换技，结束阶段，你可以弃置一张牌，令一名其他角色执行当前状态；出牌阶段，你可以①弃置两张牌（本阶段弃置过的花色的牌除外），然后使用其中的【杀】；②摸一张牌。",
	[":keolsaogu1"] = "转换技，结束阶段，你可以弃置一张牌，令一名其他角色执行当前状态；出牌阶段，你可以①弃置两张牌（本阶段弃置过的花色的牌除外），然后使用其中的【杀】；<font color=\"#01A5AF\"><s>②摸一张牌</s></font>。",
	[":keolsaogu2"] = "转换技，结束阶段，你可以弃置一张牌，令一名其他角色执行当前状态；出牌阶段，你可以<font color=\"#01A5AF\"><s>①弃置两张牌（本阶段弃置过的花色的牌除外），然后使用其中的【杀】</s></font>；②摸一张牌。",
	["keolsaogus_ask"] = "扫谷：你可以弃置一张牌，令一名其他角色执行当前状态",
	["keolsaoguslash_ask"] = "扫谷：你可以使用弃置的【杀】",
	["#keolsaoguslash"] = "扫谷弃置",
	["$keolsaogu1"] = "大汉铁骑，必昭卫霍余风于当年。",
	["$keolsaogu2"] = "笑驱百蛮，试问谁敢牧马于中原！",
	["~keol_duanjiong"] = "秋霜落，天下寒。",

	["keolmou_guanyu"] = "谋关羽[OL]",
	["&keolmou_guanyu"] = "谋关羽",
	["#keolmou_guanyu"] = "威震华夏",
	["designer:keolmou_guanyu"] = "",
	["cv:keolmou_guanyu"] = "",
	["illustrator:keolmou_guanyu"] = "佚名",
	["keolweilin"] = "威临",
	["keolweilin_red"] = "威临",
	["keolweilin_black"] = "威临",
	[":keolweilin"] = "每个回合限一次，你可以将一张牌当任一种【杀】或【酒】使用，然后你令此牌的目标角色的所有与此牌颜色相同的手牌视为【杀】直到回合结束。",
	["$keolweilin1"] = "汝等鼠辈，岂敢与某相抗！",
	["$keolweilin2"] = "义襄千里，威震华夏！",
	["keolduoshou"] = "夺首",
	[":keolduoshou"] = "锁定技，当你于每回合第一次[使用红色牌/使用基本牌/造成伤害后]，[无距离限制/无次数限制且不计次/你摸一张牌]。",
	["$keolduoshou1"] = "今日之敌，必死于我刀下！",
	["$keolduoshou2"] = "青龙所向，战无不胜！",
	["~keolmou_guanyu"] = "玉碎不改白，竹焚不毁节......",

	["keolmou_taishici"] = "谋太史慈[OL]",
	["&keolmou_taishici"] = "谋太史慈",
	["#keolmou_taishici"] = "矢志全忠孝",
	["designer:keolmou_taishici"] = "[谋-奋勇扬威]",
	["illustrator:keolmou_taishici"] = "佚名",
	["keoldulie"] = "笃烈",
	[":keoldulie"] = "每个回合限一次，当你成为其他角色使用基本牌或普通锦囊牌的唯一目标时，你可以令此牌效果额外执行一次，然后你摸X张牌（X为你的攻击范围且至多为5）。",
	["$keoldulie1"] = "秉同难共患之义，莫敢辞也！",
	["$keoldulie2"] = "慈赴府君之急，死又何惧尔？",
	["keoldouchan"] = "斗缠",
	[":keoldouchan"] = "锁定技，准备阶段，你从牌堆获得一张【决斗】，若无则改为令你的攻击范围+1且出牌阶段使用【杀】的次数上限+1（至多以此法加至本局游戏人数）。",
	["$keoldouchan1"] = "此时不捉孙策，更待何时！",
	["$keoldouchan2"] = "有胆气者，都随我来！",
	["~keolmou_taishici"] = "人生得遇知己，死又何憾......",

	["ol_pengyang"] = "彭羕[OL]",
	["&ol_pengyang"] = "彭羕",
    ["#ol_pengyang"] = "翻然轻举",
	["designer:ol_pengyang"] = "官方",
	["cv:ol_pengyang"] = "官方",
    ["illustrator:ol_pengyang"] = "鬼画府",
	["~ol_pengyang"] = "羕酒后失言，主公勿怪。",
	["olxiaofan"] = "嚣翻",
	[":olxiaofan"] = "当你需要使用牌时，你可以观看牌堆底的X+1张牌（X为你本回合使用过牌的类别数），并可以使用之，然后此牌结算结束后，你依次执行前X项：1.弃置判定区里的所有牌；2.弃置装备区里的所有牌；3.弃置所有手牌。",
	["olxiaofan0"] = "嚣翻：请选择一张牌使用",
	["#olxiaofan"] = "牌堆底",
	["$olxiaofan1"] = "吾得三顾之伯乐，必登九丈之高台。",
	["$olxiaofan2"] = "诸君食肉而鄙，空有大腹作碍。",
	["olruishi"] = "侻失",
	[":olruishi"] = "锁定技，你不能使用【无懈可击】；当你使用牌时，若此牌的点数为字母，你令此牌无效并摸一张牌，然后你对手牌数小于你的角色使用的下一张牌无距离和次数限制；当你于一回合内第三次使用伤害牌未造成伤害后，本回合“嚣翻”失效。",
	["$olruishi1"] = "备者，久居行伍之丘八，何知礼仪？",
	["$olruishi2"] = "老革荒悖，可复道邪。",
	["$cunmu3"] = "腹有锦绣千里，奈何偏居一隅。",
	["$cunmu4"] = "心大志广之人，必难以保安。",

	["shenjiaxu"] = "神贾诩[线下]",
	["&shenjiaxu"] = "神贾诩",
    ["#shenjiaxu"] = "倒悬云衢",
    ["illustrator:shenjiaxu"] = "鬼画府",
	["information:shenjiaxu"] = "ᅟᅠ<i>“众生皆妄登极乐，唯我此身留人间。”</i>",
	["lianpojx"] = "炼魄",
	[":lianpojx"] = "锁定技，若场上最大阵营为反贼、其他角色的手牌上限-1，所有角色使用【杀】的次数和攻击范围+1，主忠、其他角色不能对其以外的角色使用【桃】。若有多个最大阵营，其他角色死亡后，杀死其的角色摸两张牌或回复1点体力；每轮开始时，你展示一张未加入游戏或死亡角色的身份牌，本轮该阵营角色数视为+1。",
	["lianpojxDeath"] = "炼魄奖励",
	["$lianpojx_role"] = "%from 选择展示一张 %arg 身份牌",
	["zhaoluan"] = "兆乱",
	[":zhaoluan"] = "限定技，一名角色的濒死结算完成后，若其未脱离濒死状态，你可以令其增加3点体力上限并失去所有非锁定技，然后其将体力回复至3点并摸四张牌，本局游戏你可以令其减少1点体力上限并对一名你选择的角色造成1点伤害（出牌阶段每名角色限一次）。",
--这，就是我为你们谱写的命运！来，陷入这场生死的乱局！复活吧，我的仆从！你，还有更大的用处！你的死生，在我一念之间！这，也是我的命运吗....

	--神孙权(OL)
	["ol_shensunquan"] = "神孙权[OL]",
	["&ol_shensunquan"] = "神孙权",
    ["#ol_shensunquan"] = "东吴大帝",
    ["illustrator:ol_shensunquan"] = "鬼画府",
	  --驭衡
	["olyuheng"] = "驭衡",
	[":olyuheng"] = "锁定技，回合开始时，你弃置任意张花色各不相同的牌，随机获得等量吴势力角色的技能。回合结束时，你失去以此法获得的技能，摸等量的牌。",
	["@olyuheng-card"] = "请选择任意张花色各不相同的牌弃置",
	["~olyuheng"] = "弃置几张牌，就可以随机获得几个吴势力角色技能",
	["olyuhengSCL"] = "",
	["$olyuheng1"] = "权术妙用，存乎一心。",
	["$olyuheng2"] = "唯权之道，皆在于衡。",
	  --帝力
	["oldili"] = "帝力",
	[":oldili"] = "觉醒技，当你的技能数超过体力上限后，你减1点体力上限，失去任意个其他技能并依次获得“圣质”、“权道”、“持纲”中的前等量个。",
	["oldili:end"] = "[中止]",
	["$oldili1"] = "身处巅峰，揽天下大事。",
	["$oldili2"] = "位居至尊，掌至高之权。",
	    --圣质
	  ["ol_shengzhi"] = "圣质",
	  ["ol_shengzhiNoLimit"] = "圣质",
	  [":ol_shengzhi"] = "锁定技，当你发动非锁定技后，你本回合使用下一张牌无距离和次数限制。",
	  ["$ol_shengzhiNoLimit"] = "%from 的“<font color='yellow'><b>圣质</b></font>”触发，其于本回合使用的下一张牌将无距离和次数限制",
	  ["$ol_shengzhi1"] = "为继父兄，程弘德以继往。",
	  ["$ol_shengzhi2"] = "英魂犹在，吕宫夜而开来。",
		--权道
	  ["ol_quandao"] = "权道",
	  ["ol_quandao_throwslash"] = "权道",
	  ["ol_quandao_throwNDtrick"] = "权道",
	  ["ol_quandao_throwndtrick"] = "权道",
	  [":ol_quandao"] = "锁定技，当你使用【杀】或普通锦囊牌时，你将手牌中两者的数量弃至相同并摸一张牌。",
	  ["ol_quandao-throw"] = "",
	  ["qdslash"] = "权道：请弃置%src张【杀】，保持手牌中【杀】的数量与普通锦囊牌相等",
	  ["qdNDtrick"] = "权道：请弃置%src张普通锦囊牌，保持手牌中普通锦囊牌的数量与【杀】相等",
	  ["$ol_quandao1"] = "计策掌权，福令无快。",
	  ["$ol_quandao2"] = "以权御衡，谋定天下。",
		--持纲
	  ["ol_chigang"] = "持纲",
	  [":ol_chigang"] = "转换技，锁定技，①你的判定阶段改为摸牌阶段；②你的判定阶段改为出牌阶段。",
	  [":ol_chigang1"] = "转换技，锁定技，①你的判定阶段改为摸牌阶段；<font color=\"#01A5AF\"><s>②你的判定阶段改为出牌阶段</s></font>。",
	  [":ol_chigang2"] = "转换技，锁定技，<font color=\"#01A5AF\"><s>①你的判定阶段改为摸牌阶段</s></font>；②你的判定阶段改为出牌阶段。",
	  ["$ol_chigang1"] = "秉承伦长，扶树刚济。",
	  ["$ol_chigang2"] = "至尊临位，则朝野自诉。",
	  --阵亡
    ["~ol_shensunquan"] = "困居江东，妄称至尊......",

	--神许褚(神·武)
	["th_shenxuchu"] = "神许褚[十周年]",
	["&th_shenxuchu"] = "神许褚",
	["#th_shenxuchu"] = "嗜战的熊罴",
	["information:th_shenxuchu"] = "ᅟᅠ<i>“我尚未死去，因而您还活着。”</i>",
	["illustrator:th_shenxuchu"] = "小新",
	  --争擎
	["thzhengqing"] = "争擎",
	[":thzhengqing"] = "锁定技，每轮结束时，你移去场上所有“擎”标记，然后本轮于单回合内造成伤害数最多的角色获得X枚“擎”标记，然后其与你各摸一张牌，" ..
	"若其为你且此次为获得标记数量最多的一次，改为摸X张牌(至多摸5张)。（X为其该回合造成的伤害数）",
	["thQing"] = "擎",
	["thzhengqingDMGrecord"] = "伤害数",
	["$thzhengqing1"] = "锐士夺志，斩将者虎侯是也！",
	["$thzhengqing2"] = "三军争勇，擎纛者舍我其谁！",
	["$thzhengqing3"] = "风云起苍黄，龙虎协力，奏凯歌于峥嵘！",
	["$thzhengqing4"] = "勇力拔山气盖世，壮士乘龙威四海！",
	  --壮魄
	["thzhuangpo"] = "壮魄",
	[":thzhuangpo"] = "你可以将一张[牌面信息]包含“杀”字的牌当【决斗】使用；" ..
	"若你有“擎”标记，则此【决斗】指定目标后，你可以移去任意枚“擎”标记，然后令其弃置等量张牌；若此【决斗】指定了有“擎”标记的角色为目标，则此牌伤害+1。",
	["thzhuangpoDiscard"] = "壮魄弃牌数",
	["$thzhuangpoDMG"] = "因为此 %card 的目标角色中含有“擎”标记角色，此 %card 造成的伤害+1",
	["$thzhuangpo1"] = "腹吞龙虎，气撼山河！",
	["$thzhuangpo2"] = "神魄凝威，魍魉辟易！",
	["$thzhuangpo3"] = "虎魄生威耀元日，志驱龙马抖精神！",
	["$thzhuangpo4"] = "龙腾虎跃壮山河，新岁百尺占鳌头！",
	  --阵亡
	["~th_shenxuchu"] = "猛虎归林晚，不见往来人......",--春风曳断虎须，将军可欲再战......

--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
--\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

	["zhi2_feiyi"] = "费祎[二版]",--lua
	["&zhi2_feiyi"] = "费祎",
	["#zhi2_feiyi"] = "洞世丞相",
	["illustrator:zhi2_feiyi"] = "官方",
	["zhi2shengxi"] = "生息",
	[":zhi2shengxi"] = "准备阶段，你可以从游戏外或牌堆中获得一张【调剂盐梅】。结束阶段，若你本回合使用过牌且未造成伤害，你可以获得一张智囊牌或摸一张牌。",
	["obtainzhinang"] = "获得一张智囊牌",
	["$zhi2shengxi1"] = "利治小之宜，秉居静之理。",
	["$zhi2shengxi2"] = "外却骆谷之师，内保宁缉之实。",
	["~zhi2_feiyi"] = "臣请告陛下，宦权日盛，必乱社稷也。",
	
	["xin2_zhouchu"] = "周处[二版]",--lua
	["&xin2_zhouchu"] = "周处",--我跟关圣帝君请示过,当天他给我九个圣筊...
	["#xin2_zhouchu"] = "英情天逸",
	["illustrator:xin2_zhouchu"] = "官方",
	["xin2chuhai"] = "除害",
	[":xin2chuhai"] = "使命技，出牌阶段限一次，你可以摸一张牌，然后进行拼点，此次你的拼点牌点数+X（X为4减去你装备区的装备数量）。若你赢：你观看对方手牌，然后从牌堆或弃牌堆中获得其手牌中拥有的牌类型各一张；"..
	"当你于此阶段对其造成伤害后，你将牌堆或弃牌堆中一张你空置的装备栏对应类型的装备牌置入你的装备区。\
	<b>成功</b>：当一张装备牌进入你的装备区后，若你的装备区有不少于3张装备，则你将体力值恢复至上限，获得“彰名”，失去“乡害”。\
	<b>失败</b>：若你于使命达成前，你使用“除害”拼点没赢，且你的拼点结果不大于6点，则使命失败。",
	["xin2chuhai0"] = "除害：请选择一名角色进行拼点",
	["#chuhaisuccess"] = "<font color='cyan'><b>英情天逸</b></font>！%from 使命成功，失去<font color='yellow'><b>“乡害”</b></font>、获得<font color='yellow'><b>“彰名”</b></font>",
	["#chuhaifail"] = "很遗憾，%from 使命已失败",
	["xinzhangming"] = "彰名",
	[":xinzhangming"] = "锁定技，你使用梅花牌不能被响应。<font color='green'><b>每回合限一次，</b></font>你对其他角色造成伤害后，其随机弃置一张手牌，然后你从牌堆或弃牌堆中获得与其弃置牌类型不同类型的牌各一张"..
	"（若其无法弃置手牌，则你改为牌堆或弃牌堆中获得所有类型的牌各一张），以此法获得的牌不计入本回合手牌上限。",
	["sm_xzm_drawpile"] = "彰名:选择牌堆",
	["sm_xzm_drawpile:1"] = "从摸牌堆获得",
	["sm_xzm_drawpile:2"] = "从弃牌堆获得",

	["$xin2chuhai1"] = "有我在此，安敢为害？！",
	["$xin2chuhai2"] = "小小孽畜，还不伏诛？！",
	["$xin2chuhai3"] = "此番不成，明日再战！",
	["$xinzhangming1"] = "心怀远志，何愁声名不彰！",
	["$xinzhangming2"] = "从今始学，成为有用之才！",
	["~xin2_zhouchu"] = "改励自砥，誓除三害……",
	
	["xin2_wujing"] = "吴景[二版]",--lua
	["&xin2_wujing"] = "吴景",
	["#xin2_wujing"] = "助吴征战",
	["illustrator:xin2_wujing"] = "官方",
	["secondmobile_xinliubing"] = "流兵",
	[":secondmobile_xinliubing"] = "锁定技，你于出牌阶段内使用的第一张非虚拟【杀】的花色视为方块。其他角色于其出牌阶段内使用的非转化黑色【杀】未造成过伤害，此牌结算结束后，你获得之。",
	["xinliubing"] = "流兵",
	[":xinliubing"] = "锁定技，你于出牌阶段内使用的第一张非虚拟【杀】的花色视为方块。其他角色于其出牌阶段内使用的非转化黑色【杀】未造成过伤害，此牌结算结束后，你获得之。",
	["$xinliubing1"] = "尔等流寇，亦可展吾军之勇！",
	["$xinliubing2"] = "流寇不堪大用，勤加操练可为精兵！",
	["~xin2_wujing"] = "贼寇未除，奈何……吾身先丧！",

	["ren2_huaxin"] = "华歆[二版]",--lua
	["&ren2_huaxin"] = "华歆",
	["#ren2_huaxin"] = "清素拂浊",
	["illustrator:ren2_huaxin"] = "官方",
	["renyuanqing"] = "渊清",
	[":renyuanqing"] = "锁定技，出牌阶段结束时，你随机将弃牌堆中你本回合使用过的牌类型的各一张牌置入“仁”区。",
	["renshuchen"] = "疏陈",
	[":renshuchen"] = "锁定技，当有角色进入濒死状态时，若“仁”区中至少有四张牌，则你获得所有“仁”区牌，令其回复1点体力。",
	["$renyuanqing1"] = "怀瑾瑜，握兰桂，而心若芷萱。",
	["$renyuanqing2"] = "嘉言懿行，如渊之清，如玉之洁。",
	["$renshuchen1"] = "陛下应先留心于治道，以征伐为后事也。",
	["$renshuchen2"] = "陛下若修文德，察民疾苦，则天下幸甚。",
	["~ren2_huaxin"] = "为虑国计，身损可矣……",

	["ren_zhangwen"] = "张温[手杀]",
	["&ren_zhangwen"] = "张温",
	["#ren_zhangwen"] = "抱德炀和",
	["illustrator:ren_zhangwen"] = "官方",
	["rengebo"] = "戈帛",
	[":rengebo"] = "锁定技，一名角色回复体力后，你将牌堆顶一张牌置入“仁”区。",
	["rensongshu"] = "颂蜀",
	[":rensongshu"] = "一名体力值大于你的其他角色的摸牌阶段开始时，若“仁”区有牌，你可以令其放弃摸牌，然后获得X张“仁”区牌（X为你的体力值，且最大为5）。若如此做，本回合其使用牌只能指定自己为目标。",
	["@rensongshu"] = "你可以发动“颂蜀”令当前回合角色放弃摸牌",
	["$rengebo1"] = "握手言和，永罢刀兵。",
	["$rengebo2"] = "重归于好，摒弃前仇。",
	["$rensongshu1"] = "称美蜀政，祛其疑贰之心。",
	["$rensongshu2"] = "蜀地君明民乐，实乃太平之治。",
	["~ren_zhangwen"] = "自招罪谴，诚可悲疚……",
	
	--桥公 --lua
	["ren_qiaogong"] = "桥公[手杀]",
	["&ren_qiaogong"] = "桥公",
	["#ren_qiaogong"] = "高风朔望",
	["illustrator:ren_qiaogong"] = "官方",
	["renyizhu"] = "遗珠",
	[":renyizhu"] = "结束阶段，你须摸2张牌，然后选择2张牌作为“遗珠”，随机洗入牌堆顶前2X张牌中（X为场上存活角色数），并记录“遗珠”牌的牌名。其他角色使用“遗珠”牌指定唯一目标时，你可以取消之，然后你将此牌从“遗珠”记录中移除。",
	["@renyizhu"] = "请选择你的2张牌作为“遗珠”",
	["renluanchou"] = "鸾俦",
	["luanchouyin"] = "姻",
	[":renluanchou"] = "出牌阶段限一次，你可以移除场上所有“姻”标记并选择两名角色，令其获得“姻”标记。拥有“姻”标记的角色，拥有技能“共患”。",
	["renluanchou_doubles"] = "[鸾俦]请选择两名角色",
	["rengonghuan"] = "共患",
	[":rengonghuan"] = "锁定技，每回合限一次，当另一名拥有“姻”标记的角色受到伤害时，若其体力值小于等于你，你将此伤害转移给自己。你因“共患”技能受到伤害后，移除你们的“姻”标记。",
	
	["$renyizhu1"] = "老夫有二女，视之如明珠。",
	["$renyizhu2"] = "将军若得遇小女，万望护送而归。",
	["$renluanchou1"] = "愿汝永结鸾俦，以期共盟鸳蝶。",
	["$renluanchou2"] = "夫妻相濡以沫，方可百年偕老。",
	["$rengonghuan1"] = "曹魏势大，吴蜀当共拒之。",
	["$rengonghuan2"] = "两国得此联姻，邦交更当稳固。",
	["~ren_qiaogong"] = "为父所念，为汝二人啊……",

	
	["ren_zhangji"] = "张仲景[手杀]",
	["&ren_zhangji"] = "张仲景",
	["#ren_zhangji"] = "医理圣哲",
	["illustrator:ren_zhangji"] = "官方",
	["renjishi"] = "济世",
	[":renjishi"] = "锁定技，当你使用牌结算结束后，若此牌未造成伤害且仍在弃牌堆，你将此牌置入“仁”区；当“仁”区不因溢出而失去牌时，你摸一张牌。",
	["renliaoyi"] = "疗疫",
	[":renliaoyi"] = "其他角色的回合开始时，若其手牌数：小于体力值且“仁”区牌数不小于X，你可以令其获得X张“仁”牌；大于体力值，你可以令其将X张手牌置入“仁”区（X为该角色的手牌数与体力值之差，且至多为4）。",
	["renliaoyi0"] = "疗疫：请选择%src张手牌置入“仁”区",
	["renbinglun"] = "病论",
	[":renbinglun"] = "出牌阶段限一次，你可以移去一张“仁”区牌，令一名角色选择一项：1.摸一张牌；2.于其下个回合结束时回复1点体力。",
	["renbinglun1"] = "摸一张牌",
	["renbinglun2"] = "下个回合结束时回复1点体力",
	["$renliaoyi1"] = "麻黄之汤，或可疗伤寒之疫。",
	["$renliaoyi2"] = "望闻问切，因病施治。",
	["$renbinglun1"] = "受病有深浅，使药有轻重。",
	["$renbinglun2"] = "三分需外治，七分靠内养。",
	["$renjishi1"] = "勤求古训，常怀济人之志。",
	["$renjishi2"] = "博采众方，不随趋势之徒。",
	["~ren_zhangji"] = "得人不传，恐成坠绪（赘婿）……",
	
	["yong_wangshuang"] = "王双[手杀]",
	["&yong_wangshuang"] = "王双",
	["#yong_wangshuang"] = "边城猛兵",
	["illustrator:yong_wangshuang"] = "官方",
	["yongyiyong"] = "异勇",
	[":yongyiyong"] = "当你受到其他角色的【杀】造成的伤害后，若你的装备区内有武器牌，你可以获得此【杀】，然后当无距离限制的【杀】对其使用（若其装备区里没有武器牌，此【杀】对其造成的伤害+1）。",
	["yongshanxie"] = "擅械",
	[":yongshanxie"] = "出牌阶段限一次，你可以从牌堆中获得一张武器牌（若牌堆中没有武器牌，改为获得场上随机的一张武器栏中的牌）。你使用的【杀】目标角色需要使用点数大于你攻击范围两倍的【闪】来抵消。",
	--["@yongshanxieSlash-jink"] = "请使用一张点数大于%src的【闪】，方可抵消此【杀】",
	["yongshanxie:yongshanxieJink"] = "请注意：你需使用点数大于%src的【闪】才能抵消此【杀】（点任意键继续）",
	["$yongyiyong1"] = "这么着急回营？哼！那我就送你一程！",
	["$yongyiyong2"] = "你的兵器，本大爷还给你！哈哈哈哈！",
	["$yongshanxie1"] = "快快取我兵器，予我上阵杀敌！",
	["$yongshanxie2"] = "哈哈！还是自己的兵器，用着趁手！",
	["~yong_wangshuang"] = "啊？速回主营！啊！",

	["yan_liuba"] = "刘巴[手杀]",
	["&yan_liuba"] = "刘巴",
	["#yan_liuba"] = "撰科行律",
	["illustrator:yan_liuba"] = "官方",
	["yanduanbi"] = "锻币",
	["@yanduanbi"] = "锻币",
	[":yanduanbi"] = "限定技，出牌阶段，若所有角色手牌数之和大于场上角色数的两倍，你可以令所有其他角色弃置X张手牌（X为其手牌数的一半，向下取整，且至多为3），然后你选择一名角色，将随机三张被弃置的牌交给其。",
	["yanduanbi0"] = "锻币：请选择一名角色随机获得3张牌",
	["yantongdu"] = "统度",
	[":yantongdu"] = "<font color='green'><b>每回合限一次，</b></font>你成为其他角色使用牌的唯一目标时，你可以令一名角色重铸一张牌。",
	["yantongdu0"] = "你可以发动“统度”选择令一名角色重铸一张牌",
	["yantongdu1"] = "统度：请重铸一张牌",
	["$yanduanbi1"] = "收缴故币，以旧铸新，使民有余财。",
	["$yanduanbi2"] = "今，若能统一蜀地币制，则利在千秋。",
	["$yantongdu1"] = "资中调拨，乃国之要务，岂可儿戏！",
	["$yantongdu2"] = "府库充盈，民有余财，主公师出有名矣。",
	["~yan_liuba"] = "孔明，大汉的重担，就全系于你一人之身了。",
	
	["yan_lvfan"] = "吕范[手杀]",
	["&yan_lvfan"] = "吕范",
	["#yan_lvfan"] = "持筹廉悍",
	["illustrator:yan_lvfan"] = "官方",
	["cv:yan_lvfan"] = "（不明）",
	["yandiaodu"] = "调度",
	["@yandiaodutarget"] = "你可以发动“调度”选择一名装备区有牌的角色<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["@yandiaoduto"] = "你可以发动“调度”选择一名角色<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	[":yandiaodu"] = "准备阶段，你可以将一名角色装备区内的一张牌移动到另一名角色的对应区域，然后第一名角色摸一张牌。",
	["yandiancai"] = "典财",
	[":yandiancai"] = "其他角色的出牌阶段结束时，若你于此阶段内失去过X张或更多的牌，则你可以将手牌补至体力上限。（X为你的体力值）",
	["yanyanji"] = "严纪",
	["#yanjifail"] = "%to 的 %arg 整肃失败",
	["#yanjisuccess"] = "%to 的 %arg 整肃成功",
	[":yanyanji"] = "出牌阶段开始时，你可以进行一次“整肃”，若如此做，弃牌阶段结束时，若你“整肃”未失败，你获得“整肃”奖励。",
	["$yandiaodu1"] = "兵甲统一分配，不可私自易之！",
	["$yandiaodu2"] = "兵器调度已定，忤者军法从事！",
	["$yandiancai1"] = "国无九年之蓄，为政安敢奢靡！",
	["$yandiancai2"] = "上下尚俭戒奢，以足天下之用！",
	["$yanyanji1"] = "料覆之日已到，帐簿速速呈来！",
	["$yanyanji2"] = "所记无有纰漏，余财尚可维持！",
	["$yanyanji3"] = "帐簿收支不符，何人敢做假帐！",
	["~yan_lvfan"] = "今日朝事，可有……",


	--群：皇甫嵩、朱儁
	  --皇甫嵩 --lua
	["yan_huangfusong"] = "皇甫嵩[手杀]",
	["&yan_huangfusong"] = "皇甫嵩",
	["#yan_huangfusong"] = "铁血柔肠",
	["designer:yan_huangfusong"] = "官方",
	["illustrator:yan_huangfusong"] = "官方",
	  --讨乱
	["yantaoluan"] = "讨乱",
	[":yantaoluan"] = "每个回合限一次，当判定牌生效时，若判定结果为黑桃，你可以[终止此次判定]并选择一项：1.你获得此牌；2.若进行判定的角色不为你，你视为对其使用一张无距离和次数限制的火【杀】。",
	["yantaoluan1"] = "获得此判定牌",
	["yantaoluan2"] = "视为对其使用一张无距离和次数限制的火【杀】",
	["yanshiji"] = "势击",
	[":yanshiji"] = "当你对其他角色造成属性伤害时，若你的手牌数不为全场唯一最大，你可以观看该角色的手牌并弃置其中的红色牌，然后你摸等量的牌。",
	["yanzhengjun"] = "整军",
	[":yanzhengjun"] = "出牌阶段开始时，你可以选择一项“整肃”，然后本回合的弃牌阶段结束后，若“整肃”未失败，你获得“整肃”奖励，并可以令一名其他角色也获得“整肃”奖励。",
	["yanzhengjun0"] = "整军：你可以令一名其他角色也获得“整肃”奖励",
	["$yantaoluan2"] = "欲定黄巾，必赖兵革之利！",
	["$yantaoluan1"] = "乱民桀逆，非威不服！",
	["$yanshiji1"] = "兵法所云火攻之计，正合此时之势！",
	["$yanshiji2"] = "敌军依草结营，正犯兵家大忌！",
	["$yanzhengjun1"] = "众将平日随心，战则务尽死力！",
	["$yanzhengjun2"] = "汝等不怀余力，皆有平贼之功！",
	["$yanzhengjun3"] = "仁恕之道，终非治军良策！",
	["~yan_huangfusong"] = "力有所能，臣必为也……",

	
	  --朱儁 --lua
	["yan_zhujun"] = "朱儁[手杀]",
	["&yan_zhujun"] = "朱儁",
    ["#yan_zhujun"] = "攻城师克",
	["illustrator:yan_zhujun"] = "官方",
	["yanyangjie"] = "佯解",
	[":yanyangjie"] = "出牌阶段限一次，你可以拼点，若你没赢，你可以令另一名其他角色视为对与你拼点的角色使用一张无距离限制的火【杀】。",
	["yanyangjie0"] = "佯解：你可以令另一名角色视为【杀】",
	["yanjuxiang"] = "拒降",
	["@yanjuxiang"] = "拒降",
	[":yanjuxiang"] = "限定技，其他角色脱离濒死时，你可以对其造成1点伤害。",
	["yanhoufeng"] = "厚俸",
	["#houfengfail"] = "%to 的 %arg 整肃失败",
	["#houfengsuccess"] = "%to 的 %arg 整肃成功",
	[":yanhoufeng"] = "<font color='green'><b>每轮限一次，</b></font>你攻击范围内的一名角色出牌阶段开始时，你可以令其进行一次“整肃”，" ..
	"若如此做，其弃牌阶段结束后，若其“整肃”未失败，你与其获得“整肃”奖励。",
	["$yanyangjie1"] = "佯解敌围，而后城外击之，此为易破之道！",
	["$yanyangjie2"] = "全军彻围，待其出城迎敌，再攻敌自散矣！",
	["$yanjuxiang1"] = "今非秦项之际，如若受之，徒增逆意！",
	["$yanjuxiang2"] = "兵有形同而势异者，此次乞降断不可受！",
	["$yanhoufeng1"] = "交汝统领，勿负我望！",
	["$yanhoufeng2"] = "有功自当行赏，来人呈上！",
	["$yanhoufeng3"] = "叉出去！罚其二十军杖！",
	["~yan_zhujun"] = "郭汜小竖！气煞我也！嗯……",
	

	["mobile_shenlusu"] = "神鲁肃",
	["#mobile_shenlusu"] = "兴吴之邓禹",
	["information:mobile_shenlusu"] = "ᅟᅠ<i>“昔高帝区区欲尊事义帝而不获者，以项羽为害也。今之曹操，犹昔项羽，将军何由得为桓文乎？”</i>",
	["mobile_tamo"] = "榻谟",
	[":mobile_tamo"] = "游戏开始时，你可以重新分配所有非主公角色的座次。",
	["mobile_dingzou"] = "定州",
	[":mobile_dingzou"] = "出牌阶段限一次，你可以交给一名场上有牌的其他角色X张牌（X为其场上的牌数），然后获得其场上的所有牌。",
	["mobile_zhimeng"] = "智盟",
	[":mobile_zhimeng"] = "回合结束时，你可以与一名其他角色随机平均分配手牌（余数分配于你）。",
	["mobile_zhimeng0"] = "智盟：你可以与一名其他角色随机平均分配手牌（余数分配于你）",

	["$mobile_tamo1"] = "天下分崩，乱之已极，肃竭浅智，窃为君计。",
	["$mobile_tamo2"] = "天下易主，已为大势，君当据此，以待其时。",
	["$mobile_dingzou1"] = "今肃亲往，主公何愁不定！",
	["$mobile_dingzou2"] = "肃之所至，万事皆平！",
	["$mobile_zhimeng1"] = "吾主英明神武，曹众虽百万亦无所惧！",
	["$mobile_zhimeng2"] = "豫州何图远窜，而不投吾雄略之主乎？",
	["~mobile_shenlusu"] = "常计小利，何成大局……",
	["$mobile_shenlusu"] = "至尊高坐天中，四海皆在目下！",

	["mobile_shenhuatuo"] = "神华佗",
	["#mobile_shenhuatuo"] = "悬壶济世",
	["mobile_wuling"] = "五灵",
	[":mobile_wuling"] = "出牌阶段限两次，你可以选择一名未拥有“五灵”标记的角色，按照你选择的顺序向其传授“五禽戏”。拥有“五灵”标记的角色在其准备阶段切换为下一种。\
	<font color='#01A5AF'><i>【虎】->若你使用牌仅指定唯一目标，则此牌对目标造成伤害时，此伤害+1。\
	【鹿】->获得此标记时，回复1点体力，移除判定区所有的牌。你不能成为延时锦囊牌的目标。\
	【熊】->每回合限一次，你受到伤害时，此伤害-1。\
	【猿】->获得此标记时，选择一名其他角色，随机获得其装备区的一张牌。\
	【鹤】->获得此标记时，你摸3张牌。</i></font>",
	["wl_hu_mark"] = "虎",
	[":wl_hu_mark"] = "若你使用牌仅指定唯一目标，则此牌对目标造成伤害时，此伤害+1。",
	["wl_lu_mark"] = "鹿",
	[":wl_lu_mark"] = "获得此标记时，回复1点体力，移除判定区所有的牌。你不能成为延时锦囊牌的目标。",
	["wl_xiong_mark"] = "熊",
	[":wl_xiong_mark"] = "每回合限一次，你受到伤害时，此伤害-1。",
	["wl_yuan_mark"] = "猿",
	[":wl_yuan_mark"] = "获得此标记时，选择一名其他角色，随机获得其装备区的一张牌。",
	["wl_he_mark"] = "鹤",
	[":wl_he_mark"] = "获得此标记时，你摸3张牌。",
	["wl_yuan_mark0"] = "猿：请选择一名其他角色，随机获得其装备区的一张牌。",
	["mobile_youyi"] = "游医",
	[":mobile_youyi"] = "弃牌阶段结束时，你可以将此阶段弃置的牌置入“仁”区。出牌阶段限一次，你可以弃置所有“仁”区牌，然后令所有角色回复1点体力。",

	["$mobile_wuling1"] = "吾创五禽之戏，君可作以除疾。",
	["$mobile_wuling2"] = "欲解万般苦，驱身仿五灵。",
	["$mobile_youyi1"] = "此身行医，志济万千百姓。",
	["$mobile_youyi2"] = "普济众生，永免疾患之苦。",
	["~mobile_shenhuatuo"] = "人间诸疾未解，老夫怎入轮回……",
	["$mobile_shenhuatuo"] = "但愿世间人无病，何惜架上药生尘。",

	["mobile_majun"] = "马钧",
	["#mobile_majun"] = "没渊瑰璞",
	["mobilejingxie"] = "精械",
	[":mobilejingxie"] = "出牌阶段，你可以展示一张防具牌或【诸葛连弩】，然后用相应的强化牌替换此牌。当你进入濒死状态后，你可以重铸一张防具牌，然后回复体力至1点。\
	<font color='#01A5AF'><i>【诸葛连弩】->【元戎精械弩】\
	【八卦阵】->【先天八卦阵】\
	【仁王盾】->【仁王金刚盾】\
	【白银狮子】->【照月狮子盔】\
	【藤甲】->【桐油百韧甲】</i></font>",
	["mobilejingxie0"] = "精械：你可以重铸一张防具牌令体力回复至1点",
	["_crossbow"] = "元戎精械弩",
	[":_crossbow"] = "装备牌/武器<br/><b>攻击范围</b>：3<br/><b>武器技能</b>：锁定技，你使用【杀】无次数限制。",
	["_eight_diagram"] = "先天八卦阵",
	[":_eight_diagram"] = "装备牌/防具<br/><b>防具技能</b>：当你需要使用或打出一张【闪】时，你可以进行判定：若结果不为♠，视为你使用或打出了一张【闪】。",
	["_renwang_shield"] = "仁王金刚盾",
	[":_renwang_shield"] = "装备牌/防具<br/><b>防具技能</b>：锁定技，黑色【杀】和♥【杀】对你无效。",
	["_silver_lion"] = "照月狮子盔",
	[":_silver_lion"] = "装备牌/防具<br/><b>防具技能</b>：锁定技，当你受到大于1点的伤害时，此伤害减至1点；当你失去装备区的此牌后，你回复1点体力并摸两张牌。",
	["_vine"] = "桐油百韧甲",
	[":_vine"] = "装备牌/防具<br/><b>防具技能</b>：锁定技，【南蛮入侵】、【万箭齐发】和普通【杀】对你无效。你不能被横置。当你受到火焰伤害时，此伤害+1。",
	["mobileqiaosi"] = "巧思",
	[":mobileqiaosi"] = "出牌阶段限一次，你可以表演“水转百戏图”并获得相应的牌，然后你选择一项：1.弃置等量的牌；2.将等量的牌交给一名其他角色。",
	["mobileqiaosi0"] = "巧思：请选择%src张牌弃置或交给一名其他角色",
	["qs_shuizhuan"] = "水转百戏图",
	["qs_wang"] = "王（%src%）",
	["qs_shang"] = "商（%src%）",
	["qs_gong"] = "工（%src%）",
	["qs_nong"] = "农（%src%）",
	["qs_shi"] = "士（%src%）",
	["qs_jiang"] = "将（%src%）",

	["$mobilejingxie1"] = "军具精巧，方保无虞。",
	["$mobilejingxie2"] = "巧则巧矣，未尽善也。",
	["$mobileqiaosi1"] = "待我稍作思量，更益其巧。",
	["$mobileqiaosi2"] = "虚争空言，不如思而试之。",
	["~mobile_majun"] = "衡石不用，美玉见诬啊……",
	["$mobile_majun"] = "吾巧益于世间，真乃幸事。",

	--[协力]--
	["XL_tongchou"] = "协力[同仇]",
	[":&XL_tongchou"] = "共计造成至少4点伤害",
	[":XL_tongchou"] = "共计造成至少4点伤害",
	["XL_bingjin"] = "协力[并进]",
	[":&XL_bingjin"] = "共计摸至少八张牌",
	[":XL_bingjin"] = "共计摸至少八张牌",
	["XL_shucai"] = "协力[疏财]",
	[":&XL_shucai"] = "共计弃置四种花色的牌",
	[":XL_shucai"] = "共计弃置四种花色的牌",
	["XL_luli"] = "协力[戮力]",
	[":&XL_luli"] = "共计使用或打出四种花色的牌",
	[":XL_luli"] = "共计使用或打出四种花色的牌",
	["XL_success"] = "协力成功",
	["$XL_success"] = "在 %from 与 %to 的共同努力下，%from <font color='yellow'><b>协力</b></font> <font color='red'><b>成功</b></font>！",
	["XL_death"] = "协力失效",
	----------

	--谋关羽
	["mobilemou_guanyu"] = "谋关羽",
	["#mobilemou_guanyu"] = "关圣帝君",
	["designer:mobilemou_guanyu"] = "官方",
	["cv:mobilemou_guanyu"] = "官方",
	["illustrator:mobilemou_guanyu"] = "官方",
	["mouwusheng"] = "武圣",
	[":mouwusheng"] = "你可以将一张手牌当任意类型的【杀】使用或打出。出牌阶段开始时，你可以指定一名非[身份场主公]的其他角色，若如此做，此阶段内：" ..
	"你对其使用【杀】无距离和次数限制；你使用【杀】指定其为目标后，摸[一张]牌（若为“身份场”模式则改为摸[两张]牌）；你对其使用累计三张【杀】后，不可再指定其为你使用【杀】的目标。",
	["mouwusheng-invoke"] = "[武圣]请指定一名非[身份场主公]的其他角色，作为你于本阶段的威震目标",
	["mouwushengTarget"] = "武圣目标",
	["$mouwusheng1"] = "千军斩将而回，于某又有何难？",--指定角色
	["$mouwusheng3"] = "对敌岂遵一招一式？！",--对指定目标使用杀
	["$mouwusheng2"] = "关某既出，敌将定皆披靡！",--摸牌
	["mouyijue"] = "义绝",--义绝？圣母！
	--[":mouyijue"] = "锁定技，你于回合内对一名其他角色造成伤害时，若此伤害会令其进入濒死状态，防止之（每局每名角色限一次），" ..
	[":mouyijue"] = "锁定技，一名其他角色于你的回合内受到你造成的伤害时，若此伤害会令其进入濒死状态，防止之（每局每名角色限一次），" ..
	"若如此做，直到回合结束，你使用牌指定其为目标时，取消之。",
	["mouyijued"] = "已义绝",
	["$mouyijue1"] = "承君之恩，今日尽报。",
	["$mouyijue2"] = "下次沙场相见，关某定不留情。",
	["~mobilemou_guanyu"] = "大哥，翼德，来生再于桃园，论豪情壮志......",

	--谋黄月英
	["mobilemou_huangyueying"] = "谋黄月英",
	["#mobilemou_huangyueying"] = "足智多谋",
	["designer:mobilemou_huangyueying"] = "官方,俺的西木野Maki",
	["cv:mobilemou_huangyueying"] = "官方",
	["illustrator:mobilemou_huangyueying"] = "佚名",
	  --集智
	["moujizhi"] = "集智",
	[":moujizhi"] = "锁定技，当你使用一张普通锦囊牌时，你摸一张牌，以此法获得的牌本回合不计入手牌上限。",
	["$moujizhi1"] = "解之有万法，吾独得千计。",
	["$moujizhi2"] = "慧思万千，以成我之所想。",
	  --奇才
	["mouqicai"] = "奇才",
    [":mouqicai"] = "你使用锦囊牌无距离限制。出牌阶段限一次，你可以选择一名其他角色，将手牌或弃牌堆中的一张[装备牌]置入其装备区（若为“斗地主(普通场)”模式，" ..
	"则改为“防具牌”，且每局游戏每种防具牌名限一次），然后其获得3枚“奇”标记。拥有“奇”标记的角色接下来每获得一张普通锦囊牌需交给你，然后移除1枚“奇”标记。",
	["mouQI"] = "奇",
	["$mouqicai1"] = "依我此计，便可破之。",
	["$mouqicai2"] = "以此无用之物，换得锦囊妙计。",
	  --阵亡
	["~mobilemou_huangyueying"] = "何日北平中原，夫君再返隆中......",

	--谋诸葛亮
	["mobilemou_zhugeliang"] = "谋诸葛亮",
	["#mobilemou_zhugeliang"] = "忠武侯",
	["designer:mobilemou_zhugeliang"] = "官方,Maki,FC",
	["cv:mobilemou_zhugeliang"] = "官方",
	["illustrator:mobilemou_zhugeliang"] = "佚名",
	  --火计
	["mouhuoji"] = "火计",
	["ShimingSuccess"] = "使命成功",
	[":mouhuoji"] = "使命技，出牌阶段限一次，你可以选择一名其他角色，对其与其同势力的其他角色各造成1点火焰伤害。\
	<b>成功：</b>准备阶段，若你本局游戏对其他角色造成过至少X点火焰伤害（X为本局游戏人数），则使命成功，失去“火计”和“看破”，获得“观星”和“空城”。\
	<b>失败：</b>当你于使命成功前进入濒死状态时，则使命失败。",
	["mouhuojiDMG"] = "火计伤害",
	["$mouhuoji1"] = "区区汉贼，怎挡天火之威！",--砸人
	["$mouhuoji2"] = "就让此火，再兴炎汉国祚！",--使命成功
	["$mouhuoji3"] = "吾虽有功，然终逆天命啊...",--使命失败
	  --看破
	["moukanpo"] = "看破",
	[":moukanpo"] = "每轮开始时，你清除“看破”记录的牌名，然后你可以选择并记录任意个与本轮清除牌名均不相同的牌名（每局至多记录4个，" ..
	"若为“<font color='red'><b>欢乐成双2v2</b></font>”或“斗地主(普通场)”模式则改为2个）。" ..
	"其他角色于本轮使用与你“看破”记录牌名相同的牌时，你可以移除一个对应牌名的记录，然后摸一张牌并令此牌无效。",
	["$moukanpo1"] = "静思敌谋，以出应对之策。",
	["$moukanpo2"] = "知汝欲行此计，故已待之久矣。",
	["#moukanpo"] = "%from“看破”记录了 %arg",
	  --阵亡
	["~mobilemou_zhugeliang"] = "纵具地利，不得天时亦难胜也......",
	  --谋诸葛亮(暮年)
	["mobilemou_zhugeliangs"] = "谋诸葛亮(暮年)",
	["&mobilemou_zhugeliangs"] = "谋诸葛亮",
	["#mobilemou_zhugeliangs"] = "忠武侯",
	["designer:mobilemou_zhugeliangs"] = "官方,Maki,FC",
	["cv:mobilemou_zhugeliangs"] = "官方",
	["illustrator:mobilemou_zhugeliangs"] = "佚名",
	  --观星
	["mouguanxing"] = "观星",
	[":mouguanxing"] = "准备阶段，你移去所有“星”并将牌堆顶的X张牌置于武将牌上（X为7-你此前于准备阶段发动此技能次数的三倍），称为“星”。然后你可以将任意张“星”置于牌堆顶。" ..
	"结束阶段，若你未于准备阶段将“星”牌置于牌堆顶，则你可以将任意张“星”置于牌堆顶。当你需要使用或打出手牌时，你可以将“星”视为你的牌使用或打出。",
	["&mouStarsXing"] = "星",
	["@mouguanxing"] = "[观星]你可以将任意张“星”置于牌堆顶",
	["$mouguanxing1"] = "冷夜孤星，正如时局啊。",
	["$mouguanxing2"] = "明月皓星，前路通达。",
	  --空城
	["moukongcheng"] = "空城",
	[":moukongcheng"] = "锁定技，当你受到伤害时，若你拥有技能“观星”且你的武将牌上有“星”，你进行一次判定：若判定牌点数小于等于你“星”牌的数量，则此伤害-1；" ..
	"若你拥有技能“观星”且你的武将牌上没有“星”，则此伤害+1。",
	["$moukongcheng1"] = "仲达可愿与我城中一叙？",
	["$moukongcheng2"] = "城下千军万马，我亦谈笑自若。",
	  --阵亡
	["~mobilemou_zhugeliangs"] = "轻分身陨，功败垂成啊......",

	--谋卢植
	["mobilemou_luzhi"] = "谋卢植",
	["#mobilemou_luzhi"] = "国之桢干",
	["designer:mobilemou_luzhi"] = "官方",
	["cv:mobilemou_luzhi"] = "官方",
	["illustrator:mobilemou_luzhi"] = "佚名",
	  --明任
	["moumingren"] = "明任",
	[":moumingren"] = "游戏开始时，你摸两张牌，然后将你的一张手牌扣置于你的武将牌上，称为“任”。结束阶段，你可以用一张手牌替换“任”。",
	["mouResponsibility"] = "任",
	["moumingren_put"] = "明任：请将一张手牌作为“任”",
	["moumingren_exchange"] = "明任：你可以用一张手牌替换“任”",
	["$moumingren1"] = "父不爱无益之子，君不蓄无用之臣！",
	["$moumingren2"] = "老夫蒙国重恩，敢不捐躯以报！",
	  --贞良
	["mouzhenliang"] = "贞良",
	[":mouzhenliang"] = "转换技，" ..
	"①出牌阶段限一次，你可以选择一名攻击范围内的其他角色并弃置X张与“任”颜色相同的牌（X为你与其体力值之差且至少为1），对其造成1点伤害；" ..
	"②你的回合外，当一名角色使用或打出的牌结算结束后，若此牌与你的“任”类型相同，你可以令一名角色摸两张牌。",
	[":mouzhenliang1"] = "转换技，" ..
	"①出牌阶段限一次，你可以选择一名攻击范围内的其他角色并弃置X张与“任”颜色相同的牌（X为你与其体力值之差且至少为1），对其造成1点伤害。" ..
	"<font color=\"#01A5AF\"><s>②你的回合外，当一名角色使用或打出的牌结算结束后，若此牌与你的“任”类型相同，你可以令一名角色摸两张牌。</s></font>",
	[":mouzhenliang2"] = "转换技，" ..
	"<font color=\"#01A5AF\"><s>①出牌阶段限一次，你可以选择一名攻击范围内的其他角色并弃置X张与“任”颜色相同的牌（X为你与其体力值之差且至少为1），对其造成1点伤害。</s></font>" ..
	"②你的回合外，当一名角色使用或打出的牌结算结束后，若此牌与你的“任”类型相同，你可以令一名角色摸两张牌。",
	["mouzhenliang-invoke"] = "你可以发动“贞良”<br/> <b>操作提示</b>: 选择一名角色→点击确定<br/>",
	["$mouzhenliang1"] = "汉室艰祸繁兴，老夫岂忍宸极失御！",
	["$mouzhenliang2"] = "犹思中兴之美，尚怀来苏之望！",
	  --阵亡
	["~mobilemou_luzhi"] = "历数有尽，天命有归......",

	--谋小乔（存在魔改）
	["mobilemou_xiaoqiao"] = "谋小乔",
	["#mobilemou_xiaoqiao"] = "矫情之花",
	["designer:mobilemou_xiaoqiao"] = "官方",
	["cv:mobilemou_xiaoqiao"] = "官方",
	["illustrator:mobilemou_xiaoqiao"] = "佚名",
	  --天香
	["moutianxiang"] = "天香",
	[":moutianxiang"] = "准备阶段，若场上有“天香”标记，则你清除场上所有“天香”标记并摸等量的牌（若本局为“<font color='red'><b>欢乐成双2v2</b></font>”则此次摸牌数+3）。" ..
	"<font color='green'><b>出牌阶段限三次，</b></font>你可以将一张红色手牌交给一名没有“天香”标记的其他角色，令其获得对应花色的“天香”标记。" ..
	"当你受到伤害时，你可以选择一名有“天香”标记的角色，移除其“天香”标记，然后根据该“天香”标记的花色发动对应效果：\
	红桃，你防止此伤害，然后令其受到此伤害来源造成的1点伤害；\
	方块，其交给你两张牌。",--神杀怎么可能会有排位赛，但为了还原手杀设计师的脑淤血之作就替代成了最近似的欢乐2v2模式。
	["moutianxiang-invoke"] = "你可以发动“天香”，选择一名有“天香”标记的角色并发动对应效果：\
	<br/>-><font color='red'><b>♥</b></font>“天香”标记：防伤+嫁祸；\
	<br/>-><font color='red'><b>♦</b></font>“天香”标记：要牌",
	["#moutianxiang"] = "[天香]请交给 %src 两张牌",
	["$moutianxiang2"] = "灿如春华，皎如秋月。",
	["$moutianxiang1"] = "凤眸流盼，美目含情。",
	  --红颜
	["mouhongyan"] = "红颜",
	[":mouhongyan"] = "锁定技，你使用、打出、弃置、交给其他角色的黑桃手牌均视为红桃手牌；你的黑桃判定牌视为红桃判定牌；" ..
	"当一张判定牌生效前，若判定牌为红桃，你将判定牌花色改为由你指定的任意一种花色。",
	["mouhongyanAFR"] = "红颜-改判",
	["$mouhongyan"] = "（拨弦声）",
	  --阵亡
	["~mobilemou_xiaoqiao"] = "朱颜易改，初心永在......",

	--谋孟获
	["mobilemou_menghuo"] = "谋孟获",
	["#mobilemou_menghuo"] = "南蛮王",
	["designer:mobilemou_menghuo"] = "官方",
	["cv:mobilemou_menghuo"] = "官方",
	["illustrator:mobilemou_menghuo"] = "佚名",
	  --祸首
	["mouhuoshou"] = "祸首",
	[":mouhuoshou"] = "锁定技，【南蛮入侵】对你无效；当其他角色使用【南蛮入侵】指定目标后，你代替其成为此牌造成的伤害的来源。" ..
	"出牌阶段开始时，你随机获得弃牌堆中的一张【南蛮入侵】。出牌阶段，若你使用过【南蛮入侵】，则你此阶段不能再使用【南蛮入侵】。",
	["$mouhuoshou2"] = "整个南中都要听我的！",
	["$mouhuoshou1"] = "我才是南中之主！",
	  --再起
	["mouzaiqi"] = "再起",
	[":mouzaiqi"] = "蓄力技（0/7），" ..
	"弃牌阶段结束时，你可以选择任意名角色并扣除等量蓄力点，然后令你选择的角色各选择一项: 1.令你摸一张牌; 2.弃置一张牌，然后你回复1点体力。" ..
	"当你造成伤害后，你获得1点蓄力点（每回合限以此法获得1点蓄力点）。",
	["mouzaiqi:1"] = "其摸一张牌",
	["mouzaiqi:2"] = "弃置一张牌，其回复1点体力",
	["@mouzaiqi-card"] = "诸葛亮真是闹麻了，你是否发动“再起”进化，卷土重来逮捕诸葛亮？",
	["~mouzaiqi"] = "选择不超过你现有蓄力点数的目标角色，对小弟们发出号令！",
	["$mouzaiqi2"] = "若有来日，必将汝等拿下！",
	["$mouzaiqi1"] = "且败且战，愈战愈勇！",
	  --阵亡
	["~mobilemou_menghuo"] = "吾等谨遵丞相教诲，永不复叛.......",

	--谋祝融
	["mobilemou_zhurong"] = "谋祝融",
	["#mobilemou_zhurong"] = "野性的女王",
	["designer:mobilemou_zhurong"] = "官方,俺的西木野Maki",
	["cv:mobilemou_zhurong"] = "官方",
	["illustrator:mobilemou_zhurong"] = "佚名",
		--烈刃
	["moulieren"] = "烈刃",
	[":moulieren"] = "当你使用【杀】指定一名其他角色为唯一目标后，你可以与其拼点：若你赢，此【杀】结算结束后，你可以对另一名其他角色造成1点伤害。",
	["moulieren-dmgto"] = "你拼点成功，可以选择一名不为拼点目标的其他角色，对其造成1点伤害",
	["$moulieren2"] = "我的飞刀，谁敢小瞧！",
	["$moulieren1"] = "哼！可知本夫人厉害！",
		--巨象
	["makijuxiang"] = "巨象",
	[":makijuxiang"] = "锁定技，【南蛮入侵】对你无效；当其他角色使用的【南蛮入侵】结算结束后，你获得之。结束阶段，若你本回合未使用过【南蛮入侵】，" ..
	"你可以随机从游戏外将一张【南蛮入侵】（总计两张）交给一名角色。",--实际上，该牌为通过技能视为【南蛮入侵】的白板卡。
	["makijuxiang-givenm"] = "[女王的恩赐]你可以选择一名角色，从游戏外将一张【南蛮入侵】赐予之",
	["$makijuxiang2"] = "都给我留下吧！",--防南蛮、收南蛮
	["$makijuxiang1"] = "哼！何需我亲自出马！",--赐南蛮
	    --“巨象”所涉及到的视为【南蛮入侵】的卡牌(mbmks!!)：
	["mougong_queen"] = "女王的恩赐",
	["_savage_assault"] = "南蛮入侵",
	[":_savage_assault"] = "锦囊牌·AOE锦囊<br/><b>时机</b>：出牌阶段，对所有其他角色使用<br/><b>效果</b>：目标须打出一张【杀】，否则你对其造成1点伤害。",
		--阵亡
	["~mobilemou_zhurong"] = "大王......这诸葛亮~...果然~厉害~",--( •̀ ω •́ )--

	--谋陈宫
	["mobilemou_chengong"] = "谋陈宫",
	["#mobilemou_chengong"] = "刚直壮烈",
	["designer:mobilemou_chengong"] = "官方",
	["cv:mobilemou_chengong"] = "官方",
	["illustrator:mobilemou_chengong"] = "佚名",
	  --明策
	["moumingce"] = "明策",
	[":moumingce"] = "出牌阶段限一次，你可以将一张牌交给一名其他角色，然后其选择一项：1、失去1点体力，你摸两张牌并获得1枚“策”标记；2、摸一张牌。" ..
	"出牌阶段开始时，若你拥有“策”标记，你可以选择一名其他角色，对其造成X点伤害并移除你的所有“策”标记。（X为你的“策”标记数量）",
	["moumingce:1"] = "失去1点体力，令其摸两张牌并获得1枚“策”标记",
	["moumingce:2"] = "摸一张牌",
	["mouCeC"] = "策",
	["moumingce-DMGto"] = "你可以选择一名其他角色，对其造成 %src 点伤害",
	["$moumingce2"] = "行吾此计，可使将军化险为夷。",
	["$moumingce1"] = "分兵驻扎，可互为掎角之势。",
	  --智迟
	["mouzhichi"] = "智迟",
	["mouzhichiClear"] = "智迟",
	[":mouzhichi"] = "锁定技，当你受到伤害后，你于本回合再受到伤害时，防止之。",
	["$mouzhichi2"] = "哎！怪我智迟，竟少算一步。",--激发
	["$mouzhichi1"] = "将军勿急，我等可如此行事：",--防伤
	  --阵亡
	["~mobilemou_chengong"] = "何必多言！宫唯求一死......",

	--谋大乔
	["mobilemou_daqiao"] = "谋大乔",
	["#mobilemou_daqiao"] = "国色芳华",
	["designer:mobilemou_daqiao"] = "官方",
	["cv:mobilemou_daqiao"] = "官方",
	["illustrator:mobilemou_daqiao"] = "佚名",
	  --国色
	["mouguose"] = "国色",
	[":mouguose"] = "<font color='green'><b>出牌阶段限四次，</b></font>你可以将一张方块牌当【乐不思蜀】使用，或弃置场上一张【乐不思蜀】。然后你摸一张牌。",
	["$mouguose2"] = "将军，请留步。",
	["$mouguose1"] = "还望将军，稍等片刻。",
	  --流离
	["mouliuli"] = "流离",
	[":mouliuli"] = "当你成为【杀】的目标时，你可以弃置一张牌并选择你攻击范围内的一名其他角色（不能是此【杀】的使用者），然后将此【杀】转移给该角色。" ..
	"每个回合限一次，若你以此法弃置的是红桃牌，你可令一名其他角色（不能是此【杀】的使用者）获得1枚“流离”标记（若场上已有“流离”标记则改为转移给该角色）。" ..
	"拥有“流离”标记的角色回合开始时，其执行一个额外的出牌阶段并移除其所有“流离”标记。",
	["mouliuli-extraEffect"] = "[流离-额外效果]你可以令一名(不为此【杀】使用者的)其他角色获得“流离”标记",
	["mouliuliextraPlay"] = "[流离-女神的祝福]执行一个额外的出牌阶段",
	["$mouliuli2"] = "辗转流离，只为此刻与君相遇。",
	["$mouliuli1"] = "无论何时何地，我都在你身边。",
	  --阵亡
	["~mobilemou_daqiao"] = "此心无可依，惟有泣别离......",

	--谋孙策
	["mobilemou_sunce"] = "谋孙策",
	["#mobilemou_sunce"] = "江东小王霸",
	["designer:mobilemou_sunce"] = "官方",
	["cv:mobilemou_sunce"] = "官方",
	["illustrator:mobilemou_sunce"] = "佚名",
	  --激昂
	["moujiang"] = "激昂",
	[":moujiang"] = "你使用【决斗】可以额外指定一名目标，若如此做，你失去1点体力。当你使用【决斗】或红色【杀】指定一名目标后，或成为【决斗】或红色【杀】的目标后，你摸一张牌。"..
	"<font color='green'><b>出牌阶段限X次（X初始为1；若你已发动“制霸”修改X值，则改为场上“吴”势力角色数），</b></font>你可以将所有手牌当【决斗】使用。",
	["@moujiangd-excard"] = "[激昂]你可以为【%src】指定一名额外目标",
	["$moujiang1"] = "义武奋扬，荡尽犯我之寇！",
	["$moujiang2"] = "锦绣江东，岂容小丑横行！",
	  --魂姿
	["mouhunzi"] = "魂姿",
	["mouhunziAudio"] = "魂姿",
	[":mouhunzi"] = "觉醒技，当你脱离濒死状态时，你减1点体力上限并摸两张牌，获得技能“谋英姿”、“英魂”。",
	["$mouhunzi1"] = "群雄逐鹿之时，正是吾等崭露头角之日！",--觉醒
	["$mouhunzi2"] = "胸中远志几时立，正逢建功立业时！",--觉醒
	--
	["$mouhunzi3"] = "今与公瑾相约，共图天下霸业！",--发动“谋英姿”的时机
	["$mouhunzi4"] = "空言岂尽意，跨马战沙场！",--发动“谋英姿”的时机
	["$mouhunzi5"] = "父亲英魂犹在，助我定乱平贼！",--发动“英魂”的时机
	["$mouhunzi6"] = "扫尽门庭之寇，贼自畏我之威！",--发动“英魂”的时机
	  --制霸
	["mouzhiba"] = "制霸",
	[":mouzhiba"] = "主公技，限定技，当你进入濒死状态时，你可以回复Y点体力（Y为场上“吴”势力角色数）并将“激昂”中的X值改为：<font color='green'><b>场上“吴”势力角色数</b></font>，" ..
	"然后其他“吴”势力角色依次受到1点无来源伤害。若有角色因此伤害死亡，则其死亡后，你摸三张牌。",
	["@mouzhiba"] = "制霸",
	["$mouzhiba1"] = "知君英豪，望来归效！",
	["$mouzhiba2"] = "孰胜孰负，犹未可知！",

	["$yinghun10"] = "父亲英魂犹在，助我定乱平贼！",
	["$yinghun11"] = "扫尽门庭之寇，贼自畏我之威！",

	  --阵亡
	["~mobilemou_sunce"] = "大志未展，权弟当继......",
	
	--谋孙策[二版]
	["mobilemou_sunces"] = "谋孙策[二版]",
	["&mobilemou_sunces"] = "谋孙策",
	["#mobilemou_sunces"] = "江东小霸王",
	["designer:mobilemou_sunces"] = "官方",
	["cv:mobilemou_sunces"] = "官方",
	["illustrator:mobilemou_sunces"] = "佚名",
	  --激昂（同正式初版）
	  --魂姿
	["mouhunzis"] = "魂姿",
	["mouhunzisAudio"] = "魂姿",
	[":mouhunzis"] = "觉醒技，当你脱离濒死状态时，你减1点体力上限、获得1点护甲并摸三张牌，获得技能“谋英姿”、“英魂”。",
	["$mouhunzis1"] = "群雄逐鹿之时，正是吾等崭露头角之日！",--觉醒
	["$mouhunzis2"] = "胸中远志几时立，正逢建功立业时！",--觉醒
	--
	["$mouhunzis3"] = "今与公瑾相约，共图天下霸业！",--发动“谋英姿”的时机
	["$mouhunzis4"] = "空言岂尽意，跨马战沙场！",--发动“谋英姿”的时机
	["$mouhunzis5"] = "父亲英魂犹在，助我定乱平贼！",--发动“英魂”的时机
	["$mouhunzis6"] = "扫尽门庭之寇，贼自畏我之威！",--发动“英魂”的时机
	  --制霸
	["mouzhibas"] = "制霸",
	[":mouzhibas"] = "主公技，限定技，当你进入濒死状态时，你可以回复Y点体力（Y为场上“吴”势力角色数-1）并将“激昂”中的X值改为：<font color='green'><b>场上“吴”势力角色数</b></font>，" ..
	"然后其他“吴”势力角色依次受到1点无来源伤害。若有角色因此伤害死亡，则其死亡后，你摸三张牌。",
	["@mouzhibas"] = "制霸",
	["$mouzhibas1"] = "知君英豪，望来归效！",
	["$mouzhibas2"] = "孰胜孰负，犹未可知！",
	  --阵亡
	["~mobilemou_sunces"] = "大志未展，权弟当继......",

	--谋袁绍
	["mobilemou_yuanshao"] = "谋袁绍",
	["#mobilemou_yuanshao"] = "虚伪的袁神",
	["designer:mobilemou_yuanshao"] = "官方",
	["cv:mobilemou_yuanshao"] = "官方",
	["illustrator:mobilemou_yuanshao"] = "佚名",
	  --乱击
	["mouluanji"] = "乱击",
	["mouluanjiDC"] = "乱击",
	[":mouluanji"] = "出牌阶段限一次，你可以将两张手牌当【万箭齐发】使用。其他角色因响应你使用的【万箭齐发】而打出【闪】时，你摸一张牌（每回合你至多以此法获得三张牌）。",
	["$mouluanji1"] = "与我袁本初为敌，下场只有一个！",
	["$mouluanji2"] = "弓弩手，乱箭齐下，射杀此贼！",
	  --血裔
	["mouxueyi"] = "血裔",
	[":mouxueyi"] = "主公技，锁定技，你的手牌上限+X（X为其他“群”势力角色数的两倍）；你使用牌指定其他“群”势力角色为目标后，你摸一张牌（每回合你至多以此法获得两张牌）。",
	["mouluanjiDC"] = "血裔",
	["$mouxueyi1"] = "四世三公之贵，岂是尔等寒门可及？",
	["$mouxueyi2"] = "吾袁门名冠天下，何须奉天子为傀？",
	  --阵亡
	["~mobilemou_yuanshao"] = "我不可能输给曹阿瞒，不可能！......",

	--谋貂蝉
	["mobilemou_diaochan"] = "谋貂蝉",
	["#mobilemou_diaochan"] = "离间计",
	["designer:mobilemou_diaochan"] = "官方",
	["cv:mobilemou_diaochan"] = "官方",
	["illustrator:mobilemou_diaochan"] = "佚名,云涯",
	  --离间
	["moulijian"] = "离间",
	[":moulijian"] = "出牌阶段限一次，你可以选择至少两名其他角色并弃置X张牌（X为你选择的角色数-1），然后这些角色依次视为对在你此次选择范围内的逆时针最近座次的另一名角色使用一张【决斗】。",
	["moulijianTargets"] = "",
	["$moulijian2"] = "贱妾污浊之身，岂可复侍将军...",
	["$moulijian1"] = "太师若献妾于吕布，妾宁死不受此辱！",
	  --闭月
	["moubiyue"] = "闭月",
	["moubiyueRaC"] = "闭月",
	[":moubiyue"] = "锁定技，结束阶段，你摸X张牌。（X为本回合受到伤害的角色数+1，至多为4）",
	["moubiyue_damagedTargets"] = "",
	["$moubiyue2"] = "芳草更芊芊，荷池映玉颜。",
	["$moubiyue1"] = "薄酒醉红颜，广袂羞掩面。",
	  --阵亡
	["~mobilemou_diaochan"] = "终不负阿父之托......",

	--谋庞统
	["mobilemou_pangtong"] = "谋庞统",
	["#mobilemou_pangtong"] = "铁索连舟",
	["designer:mobilemou_pangtong"] = "官方",
	["cv:mobilemou_pangtong"] = "官方",
	["illustrator:mobilemou_pangtong"] = "佚名",
	  --连环
	["moulianhuan"] = "连环",
	[":moulianhuan"] = "出牌阶段，你可以将一张梅花手牌当【铁索连环】使用（每个出牌阶段限一次），或重铸一张梅花手牌。你使用【铁索连环】时，你可以失去1点体力，若如此做，" ..
	"你使用【铁索连环】指定一名角色为目标后，若其不处于连环状态，随机弃置其一张手牌。",
	[":moulianhuan1"] = "出牌阶段，你可以将一张梅花手牌当【铁索连环】使用（每个出牌阶段限一次），或重铸一张梅花手牌。你使用【铁索连环】可以额外指定任意名目标。" ..
	"你使用【铁索连环】指定一名角色为目标后，若其不处于连环状态，随机弃置其一张手牌。",
	["$moulianhuan2"] = "并排横江，可利水战！",
	["$moulianhuan1"] = "任凭潮涌，连环无惧！",
	  --涅槃
	["mouniepan"] = "涅槃",
	[":mouniepan"] = "限定技，当你处于濒死状态时，你可以弃置区域里的所有牌，若如此做，你摸两张牌、将体力回复至2点并复原武将牌，然后升级“连环”" ..
	"（<font color='red'><b>【升级版】</b></font>出牌阶段，你可以将一张梅花手牌当【铁索连环】使用（每个出牌阶段限一次），或重铸一张梅花手牌。你使用【铁索连环】可以额外指定任意名目标。你使用【铁索连环】指定一名角色为目标后，若其不处于连环状态，随机弃置其一张手牌。）",
	["@mouniepan"] = "涅槃",
	["mouniepaned"] = "",
	["$mouniepan2"] = "烈火焚身，凤羽更丰！",
	["$mouniepan1"] = "凤雏涅槃，只为再生！",
	  --阵亡
	["~mobilemou_pangtong"] = "落凤坡，果真为我葬身之地......",

	--谋法正
	["mobilemou_fazheng"] = "谋法正",
	["#mobilemou_fazheng"] = "经学思谋",
	["designer:mobilemou_fazheng"] = "官方",
	["cv:mobilemou_fazheng"] = "官方",
	["illustrator:mobilemou_fazheng"] = "佚名",
	  --眩惑
	["mouxuanhuo"] = "眩惑",
	["mouxuanhuoGC"] = "眩惑",
	[":mouxuanhuo"] = "出牌阶段限一次，你可以交给一名没有“眩”标记的其他角色一张牌并令其获得“眩”标记。有“眩”标记的角色于摸牌阶段外获得牌时，你随机获得其一张手牌（每枚“眩”标记最多令你获得五张牌）。",
	["mXuan"] = "眩",
	["mLastXuan"] = "“眩”效果剩余",
	["$mouxuanhuo1"] = "虚名虽无实用，可沽万人之心。",
	["$mouxuanhuo2"] = "效金台碣馆之事，布礼贤仁德之名。",
	  --恩怨
	["mouenyuan"] = "恩怨",
	[":mouenyuan"] = "锁定技，准备阶段，你令有“眩”标记的角色执行以下效果：自其获得“眩”标记开始，若你获得其至少三张牌，则你移除其“眩”标记，然后交给其三张牌(不足则全给)；否则其失去1点体力，然后你回复1点体力并移除其“眩”标记。",
	["#mouenyuan"] = "请交给 %src 三张牌",
	["$mouenyuan1"] = "恩如泰山，当还以东海！",--恩
	["$mouenyuan2"] = "汝既负我，哼哼，休怪军法无情！",--怨
	  --阵亡
	["~mobilemou_fazheng"] = "蜀翼双折，吾主王业，就靠孔明了......",

	--谋甄姬
	["mobilemou_zhenji"] = "谋甄姬",
	["#mobilemou_zhenji"] = "薄幸幽兰",
	["designer:mobilemou_zhenji"] = "官方",
	["cv:mobilemou_zhenji"] = "官方",
	["illustrator:mobilemou_zhenji"] = "佚名",
	  --洛神
	["mouluoshen"] = "洛神",
	[":mouluoshen"] = "准备阶段，你可以选择一名角色，自其开始，X名其他角色依次展示一张手牌（X为场上存活人数的一半，向上取整），若为黑色，你获得之，且此牌本回合不计入手牌上限。若为红色，其弃置之。",
	["mouluoshen0"] = "洛神：你可以选择一名角色",
	["mouluoshen1"] = "洛神：请选择一张手牌展示",
	["$mouluoshen2"] = "晨张兮细帷，夕茸兮兰櫋。",
	["$mouluoshen1"] = "商灵缤兮恭迎，伞盖纷兮若云。",
	  --倾国
	["mouqingguo"] = "倾国",
	[":mouqingguo"] = "你可以将一张黑色手牌当【闪】使用或打出。",
	["$mouqingguo2"] = "辛夷展兮修裙，紫藤舒兮绣裳。",
	["$mouqingguo1"] = "凌波荡兮微步，香罗袜兮生尘。",
	  --阵亡
	["~mobilemou_zhenji"] = "秀目回兮难得，徒逍遥兮莫离......",

	--谋曹仁
	["mobilemou_caoren"] = "谋曹仁",
	["#mobilemou_caoren"] = "固若金汤",
	["designer:mobilemou_caoren"] = "官方",
	["cv:mobilemou_caoren"] = "官方",
	["illustrator:mobilemou_caoren"] = "佚名",
	  --据守
	["moujushou"] = "据守",
	[":moujushou"] = "出牌阶段限一次，若你正面向上，你可以翻面、弃置至多两张牌并获得等量的护甲。当你受到伤害后，若你背面向上，你可以选择一项：1.翻回；2.获得1点护甲。" ..
	"当你翻回正面时，你摸等同于你护甲值的牌。",
	["moujushou:1"] = "给我翻过来！",
	["moujushou:2"] = "叠甲，过",
	["$moujushou1"] = "白马沉河共歃誓，怒涛没城亦不悔！",--出牌阶段发动技能
	["$moujushou3"] = "山水速疾来去易，襄樊镇固永难开！",--选择
	["$moujushou2"] = "汉水溢流断归路，守城之志穷且坚！",--翻回摸牌
	  --解围
	["moujiewei"] = "解围",
	[":moujiewei"] = "出牌阶段限一次，你可以失去1点护甲并选择一名其他角色，你查看其手牌并获得其中一张。",
	["$moujiewei1"] = "同袍之谊，断不可弃之！",
	["$moujiewei2"] = "贼虽势盛，若吾出马，亦可解之！",
	  --阵亡
	["~mobilemou_caoren"] = "吾身可殉，然襄樊之地万不可落于吴蜀之手......",

	--谋刘备
	["mobilemou_liubei"] = "谋刘备",
	["#mobilemou_liubei"] = "雄才盖世",
	["designer:mobilemou_liubei"] = "官方",
	["cv:mobilemou_liubei"] = "官方",
	["illustrator:mobilemou_liubei"] = "佚名",
	  --仁德
	["mourende"] = "仁德",
	[":mourende"] = "出牌阶段开始时，你获得2枚“仁望”标记。出牌阶段，你可以将任意张牌交给一名本阶段未获得过“仁德”牌的其他角色，然后你获得等量的“仁望”标记（你至多拥有8枚“仁望”标记）。" ..
	"每个回合限一次，当你需要使用或打出一张基本牌时，你可以弃置2枚“仁望”标记视为使用或打出之。",
	["mourdTOzw"] = "本局已仁德",
	["mRenWang"] = "仁望",
	["mourende_choice"] = "请选择要使用的基本牌",
	["mourende0"] = "仁德：你可以使用【%src】",
	["$mourende1"] = "仁德为政，自得民心！",
	["$mourende2"] = "此非吾心所愿，乃形势所迫耳。",
	["$mourende3"] = "民心所望，乃吾政所向！",
	  --章武
	["mouzhangwu"] = "章武",
	["mouzhangwuTurn"] = "章武",
	[":mouzhangwu"] = "限定技，出牌阶段，你可以令本局游戏中所有获得过“仁德”牌的角色依次交给你X张牌（X为游戏轮数-1，且最大为3），若如此做，你回复3点体力，然后失去“仁德”。",
	["@mouzhangwu"] = "章武",
	["mouzhangwuGive"] = "",
	["#mouzhangwu"] = "请交给其%src张牌",
	["$mouzhangwu2"] = "众将皆言君恩，今当献身以报！",
	["$mouzhangwu1"] = "汉贼不两立，王业不偏安！",
	  --激将
	["moujijiang"] = "激将",
	[":moujijiang"] = "主公技，出牌阶段结束时，你可指定一名角色，并令另一名攻击范围内含有该角色且体力值不小于你的其他蜀势力角色选择一项：1.视为对你指定的角色使用一张普通【杀】；2.跳过下一个出牌阶段。",
	["@moujijiang"] = "激将：你可指定一名角色，并令另一名角色视为对其出【杀】",
	["moujijiang:1"] = "视为对%src使用一张【杀】",
	["moujijiang:2"] = "跳过下一个出牌阶段",
	["moujijiangSL"] = "不敢战",
	[":&moujijiangSL"] = "将跳过下一个出牌阶段",
	["$moujijiang2"] = "匡扶汉室，岂能无诸将之助！",
	["$moujijiang1"] = "大汉将士，何人敢战？",
	  --阵亡
	["~mobilemou_liubei"] = "汉室之兴，皆仰望丞相了......",

	--谋黄盖
	["mobilemou_huanggai"] = "谋黄盖",
	["#mobilemou_huanggai"] = "轻身为国",
	["designer:mobilemou_huanggai"] = "官方",
	["cv:mobilemou_huanggai"] = "官方",
	["illustrator:mobilemou_huanggai"] = "佚名",
	  --苦肉
	["moukurou"] = "苦肉",
	[":moukurou"] = "出牌阶段开始时，你可以交给其他角色一张牌，然后失去1点体力（若你交出的牌是【桃】或【酒】，则改为失去2点体力）。当你失去1点体力后，你获得2点护甲。",
	["@moukurou"] = "苦肉：你可以将一张牌交给一名其他角色",
	["$moukurou1"] = "既不能破，不如依张子布之言，投降便罢！",--给牌
	["$moukurou2"] = "周瑜小儿！破曹不得，便欺吾三世老臣乎？",--失去体力
	  --诈降
	["mouzhaxiang"] = "诈降",
	["mouzhaxiangWH"] = "诈降",
	[":mouzhaxiang"] = "锁定技，你于每个回合使用的前X张牌无距离和次数限制且不可被响应。摸牌阶段，你多摸X张牌。（X为你已损失体力值）",
	["mouzhaxiangCardUsed"] = "",
	["$mouzhaxiang1"] = "江东六郡之卒，怎敌丞相百万雄师！",
	["$mouzhaxiang2"] = "闻丞相虚心纳士，盖愿率众归降！",
	  --阵亡
	["~mobilemou_huanggai"] = "哈哈哈哈，公瑾计成，老夫死也无憾了......",

	--谋周瑜
	["mobilemou_zhouyu"] = "谋周瑜",
	["#mobilemou_zhouyu"] = "江淮之杰",
	["designer:mobilemou_zhouyu"] = "官方",
	["cv:mobilemou_zhouyu"] = "官方",
	["illustrator:mobilemou_zhouyu"] = "佚名",
	  --英姿
	["mouyingzi"] = "英姿",
	[":mouyingzi"] = "锁定技，摸牌阶段，你以下的数值每满足一项，你摸牌数与本回合手牌上限就+1：1.你的手牌数不少于2；2.你的体力值不低于2；3.你装备区的牌数不低于1。",
	["$mouyingzi_DrawMore"] = "%from 的手牌数为 %arg2，体力值为 %arg3，装备区的牌数为 %arg4，满足“<font color='yellow'><b>英姿</b></font>”的 %arg5 项增益，将多摸 %arg5 张牌，且本回合手牌上限 + %arg5",
	["$mouyingzi1"] = "交之总角，付之九州！",
	["$mouyingzi2"] = "定策分两治，纵马饮三江！",
	["$mouyingzi3"] = "今与公瑾相约，共图天下霸业！",
	["$mouyingzi4"] = "空言岂尽意，跨马战沙场！",
	  --反间
	["moufanjian"] = "反间",
	[":moufanjian"] = "出牌阶段，你可以选择一名其他角色，扣置一张本回合未以此法扣置过的花色的手牌，并声明一个花色，其须选择一项：1.猜测此牌花色与声明花色是否一致；2.其翻面，且此技能失效直到回合结束。" ..
						"然后你展示此牌令其获得之。若其选择猜测，则：若<font color='green'><b>猜对</b></font>，此技能失效直到回合结束；若<font color='red'><b>猜错</b></font>，其失去1点体力。",
	["moufanjianSuit"] = "声明花色",
	["moufanjian:1"] = "声明花色与扣置牌花色相同",
	["moufanjian:2"] = "声明花色与扣置牌花色不同",
	["moufanjian:3"] = "翻面，让其本回合不能再发动“反间”",
	["#moufanjianSuit"] = "%from 选择声明 %arg",
	["#moufanjian"] = "%to 选择猜测 %arg",
	["$moufanjianGuess_success"] = "面对由 %from 发起的“<font color='yellow'><b>反间</b></font>”猜猜看，%to 接受挑战、沉着应对，猜测 <font color=\"#4DB873\"><b>正确</b></font>！",
	["$moufanjianGuess_fail"] = "面对由 %from 发起的“<font color='yellow'><b>反间</b></font>”猜猜看，%to 接受挑战，但顾虑重重，猜测 <font color='red'><b>错误</b></font>",
	["$moufanjian2"] = "比之自内，不自失也。",--未“得逞”
	["$moufanjian1"] = "若不念汝三世之功，今日定斩不赦！",--“得逞”
	  --阵亡
	["~mobilemou_zhouyu"] = "余虽不惧曹军，但惧白驹过隙......",

	--谋夏侯氏
	["mobilemou_xiahoushi"] = "谋夏侯氏",
	["#mobilemou_xiahoushi"] = "燕语呢喃",
	["designer:mobilemou_xiahoushi"] = "官方",
	["cv:mobilemou_xiahoushi"] = "官方",
	["illustrator:mobilemou_xiahoushi"] = "佚名",
	  --燕语
	["mouyanyu"] = "燕语",
	["mouyanyuGiveCards"] = "燕语",
	[":mouyanyu"] = "<font color='green'><b>出牌阶段限两次，</b></font>你可以弃置一张【杀】并摸一张牌。出牌阶段结束时，你可以令一名其他角色摸3X张牌（X为你本回合以此法弃置的【杀】数）。",
	["mouyanyuDraw"] = "燕语补牌",
	["mouyanyu-GiveCardsNum"] = "请选择一名其他角色，其摸 %src 张牌",
	["$mouyanyu1"] = "燕语呢喃唤君归！",
	["$mouyanyu2"] = "燕燕于飞，差池其羽。",
	  --樵拾
	["mouqiaoshi"] = "樵拾",
	[":mouqiaoshi"] = "每个回合限一次，当你受到其他角色造成的伤害后，伤害来源可选择令你回复等同于此次伤害值的体力，若如此做，其摸两张牌。",
	["#mouqiaoshiUse"] = "%from 发动 %to 的 %arg",
	["$mouqiaoshi1"] = "拾樵城郭边，似有苔花开。",
	["$mouqiaoshi2"] = "拾樵采薇，怡然自足。",
	  --阵亡
	["~mobilemou_xiahoushi"] = "玄鸟不曾归，君亦不再来......",

	--谋甘宁
	["mobilemou_ganning"] = "谋甘宁",
	["#mobilemou_ganning"] = "兴王定霸",
	["designer:mobilemou_ganning"] = "官方",
	["cv:mobilemou_ganning"] = "官方",
	["illustrator:mobilemou_ganning"] = "佚名",
	  --奇袭
	["mouqixi"] = "奇袭",
	[":mouqixi"] = "出牌阶段限一次，你可以选择一名其他角色，令其猜测你手牌中某种花色的牌最多。若其猜错，你可令其再次猜测（其无法选择此阶段已猜测过的花色）；否则你展示所有手牌。然后你弃置其区域内X张牌。（X为其此阶段猜错的次数，若不足则全弃）",
	["mouqixiMAX"] = "猜测其手牌中%src最多",
	["$mouqixiGuess_success"] = "面对由 %from 发起的“<font color='yellow'><b>奇袭</b></font>”猜猜看，%to 沉着应对，猜测 <font color=\"#4DB873\"><b>正确</b></font>！",
	["$mouqixiGuess_fail"] = "面对由 %from 发起的“<font color='yellow'><b>奇袭</b></font>”猜猜看，%to 顾虑重重，猜测 <font color='red'><b>错误</b></font>",
	["mouqixi:mouqixi"] = "你是否令其再次猜测？这样有机会弃置其更多牌",
	["~mouqixi"] = "【注意】若对方连续猜错三次就可以收手了，不然直接就要展示手牌了",
	["$mouqixi1"] = "击敌不备，奇袭拔寨！",
	["$mouqixi2"] = "轻羽透重铠，奇袭溃坚城！",
	  --奋威
	["moufenwei"] = "奋威",
	[":moufenwei"] = "限定技，出牌阶段，你可以将至多三张牌置于等量角色的武将牌上各一张，称为“威”，然后你摸等同于“威”数量的牌。有“威”的角色成为锦囊牌的目标时，你须选择一项：1.令其获得“威”牌；2.弃置其“威”牌，取消其作为此锦囊牌的目标。",
	["@moufenwei"] = "奋威",
	["MFwei"] = "威",
	["moufenwei:1"] = "令其获得“威”牌",
	["moufenwei:2"] = "弃置其“威”牌，取消其作为此锦囊牌的目标",
	["$moufenwei1"] = "舍身护主，扬吴将之风！",
	["$moufenwei2"] = "袭军挫阵，奋江东之威！",
	  --阵亡
	["~mobilemou_ganning"] = "蛮将休得猖狂！呃...呃啊！......",

	--谋曹操
	["mobilemou_doublefuck"] = "谋曹操",
	["#mobilemou_doublefuck"] = "魏武大帝",
	["designer:mobilemou_doublefuck"] = "官方",
	["cv:mobilemou_doublefuck"] = "官方",
	["illustrator:mobilemou_doublefuck"] = "佚名",
	  --奸雄
	["moujianxiong"] = "奸雄",
	[":moujianxiong"] = "游戏开始时，你可以选择获得至多2枚“治世”标记。当你受到伤害后，你可以获得对你造成伤害的牌并摸1-X张牌（X为你的“治世”标记数且不大于2；1-x>=0），然后你可以弃置1枚“治世”标记。",
	["mouGW"] = "治世",
	["@moujx_getMarks"] = "请选择你开局拥有的“治世”标记数",
	["@moujx_getMarks:0"] = "0枚",
	["@moujx_getMarks:1"] = "1枚",
	["@moujx_getMarks:2"] = "2枚",
	["moujianxiong:moujianxiong"] = "你可以弃置1枚“治世”标记，增加后续触发“奸雄”的收益",
	["$moujianxiong1"] = "古今英雄盛世，尽赴沧海东流！",
	["$moujianxiong2"] = "骖六龙行御九州，行四海路下八邦！",
	  --清正
	["mouqingzheng"] = "清正",
	[":mouqingzheng"] = "出牌阶段开始时，你可以弃置手牌中3-X种花色的所有牌并选择一名有手牌的其他角色，你查看其手牌，弃置其中一种花色的所有牌，若弃置其的牌数少于你弃置的牌数，你对其造成1点伤害。然后若你的“治世”标记数少于2且你有技能“奸雄”，你可以获得1枚“治世”标记。",
	["mouqingzhengs"] = "请选择一名其他角色，之后你将查看其手牌并弃置其中一种花色的所有牌",
	["@mouqingzheng"] = "清正：你可以弃置%src种花色的所有手牌（选择时每种花色选一张）并选择一名其他角色",
	["mouqingzheng:mouqingzheng"] = "你可以获得1枚“治世”标记，减少后续发动“清正”的代价",
	["$mouqingzheng1"] = "立威行严法，肃佞正国纲！",
	["$mouqingzheng2"] = "悬杖分五色，治法扬清名。",
	  --护驾
	["mouhujia"] = "护驾",
	[":mouhujia"] = "主公技，每轮限一次，当你受到伤害时，你可以选择一名魏势力其他角色，你将此伤害转移给该角色。",
	["@mouhujia"] = "你可以选择一名魏势力其他角色，将伤害转移给其",
	["~mouhujia"] = "选择一名魏势力其他角色，点【确定】",
	["$mouhujia1"] = "虎贲三千，堪当敌万余！",
	["$mouhujia2"] = "壮士八百，足护卫吾身！",
	  --阵亡
	["~mobilemou_doublefuck"] = "狐死归首丘，故乡安可忘！",

	--谋杨婉
	["mobilemou_yangwan"] = "谋杨婉",
	["#mobilemou_yangwan"] = "迷计惑心",
	["designer:mobilemou_yangwan"] = "官方",
	["cv:mobilemou_yangwan"] = "官方",
	["illustrator:mobilemou_yangwan"] = "佚名",
	  --暝眩
	["moumingxuan"] = "暝眩",
	[":moumingxuan"] = "锁定技，出牌阶段开始时，若你有手牌且有未被“暝眩”记录的其他角色，你选择至多X张花色各不相同的手牌（X为未被“暝眩”记录的其他角色数），将这些牌随机交给等量未被“暝眩”记录的其他角色各一张，然后依次令这些角色选择一项：1.对你使用一张【杀】，然后你记录其；2.交给你一张牌，并令你摸一张牌。",
	--["moumingxuan:1"] = "对其使用一张【杀】，然后被记录为“暝眩”对象",
	--["moumingxuan:2"] = "交给其一张牌并令其摸一张牌",
	["moumingxuanCardGive"] = "",
	["@moumingxuan-card"] = "请选择至多为未被“暝眩”记录的其他角色数的花色各不相同的手牌，并选择你想将这些牌交予的可选择对象",
	["~moumingxuan"] = "选好手牌后，点场上未有“暝眩”标记的若干名其他角色，选好后点【确定】",
	["@moumingxuan-slash"] = "请对 %src 使用一张【杀】（会被记录为“暝眩”对象），否则你交给 %src 一张牌并令 %src 摸一张牌",
	["#moumingxuan"] = "请交给 %src 一张牌，然后令 %src 摸一张牌",
	["$moumingxuan1"] = "闻汝节行俱佳，今特设宴相请。",
	["$moumingxuan2"] = "百闻不如一见，夫人果真非凡。",
	  --陷仇
	["mouxianchou"] = "陷仇",
	[":mouxianchou"] = "当你受到伤害后，你可以选择一名不为伤害来源的其他角色，其可以弃置一张牌，视为对伤害来源使用一张无距离与次数限制的【杀】。此【杀】结算结束后，若此【杀】造成过伤害，其摸两张牌，你回复1点体力。",
	["@mouxianchou-fujunAvanger"] = "陷仇：你可以选择一名不为伤害来源的其他角色为你报仇",
	["@mouxianchou-slash"] = "你可以弃置一张牌，视为对伤害来源使用一张无距离与次数限制的【杀】",
	["$mouxianchou1"] = "夫君勿忘，杀妻害子之仇！",
	["$mouxianchou2"] = "吾母子之仇，便全靠夫君来报了！",
	  --阵亡
	["~mobilemou_yangwan"] = "引狗入寨，悔恨交加啊......",

	--谋马超
	["mobilemou_machao"] = "谋马超",
	["#mobilemou_machao"] = "阻戎负勇",
	["designer:mobilemou_machao"] = "官方",
	["cv:mobilemou_machao"] = "官方",
	["illustrator:mobilemou_machao"] = "佚名",
	  --马术（-1马）
	  --铁骑
	["moutieqii"] = "铁骑",
	["moutieqiiClear"] = "铁骑",
	[":moutieqii"] = "当你使用【杀】指定一名角色为目标时，你可以令其非锁定失效直到回合结束，且其不能使用【闪】响应此【杀】，然后你与其进行“谋弈”：\
	<b>直取敌营</b>：若成功，你获得其一张牌；\
	<b>扰阵疲敌</b>：若成功，你摸两张牌。",
	["@MouYi-tieqi"] = "谋弈：铁骑",
	["@MouYi-tieqi:F1"] = "直取敌营(获得目标的一张牌)",
	["@MouYi-tieqi:F2"] = "扰阵疲敌(摸两张牌)",
	["@MouYi-tieqi:T1"] = "拱卫中军(防止对手获得你的牌)",
	["@MouYi-tieqi:T2"] = "出阵迎战(防止对手摸牌)",
	["$moutieqii1"] = "你可闪得过此一击！！",--锁技能+强命
	["$moutieqii2"] = "厉马秣兵，只待今日！",--谋弈
	["$moutieqii3"] = "敌军防备空虚，出击直取敌营！",--抢牌成功
	["$moutieqii4"] = "敌军早有防备，先行扰阵疲敌！",--摸牌成功
	["$moutieqii5"] = "全军速撤回营，以期再觅良机！",--谋弈失败
	  --阵亡
	["~mobilemou_machao"] = "父兄妻儿俱丧，吾有何面目活于世间......",--父亲！不能为汝报仇雪恨矣......

	--谋孙尚香
	["mobilemou_sunshangxiang"] = "谋孙尚香",
	["#mobilemou_sunshangxiang"] = "骄豪明俏",
	["designer:mobilemou_sunshangxiang"] = "官方",
	["cv:mobilemou_sunshangxiang"] = "官方",
	["illustrator:mobilemou_sunshangxiang"] = "佚名",
	  --良助
	["mouliangzhu"] = "良助",
	[":mouliangzhu"] = "蜀势力技，出牌阶段限一次，你可以将其他角色装备区里的一张牌置于你的武将牌上，称为“妆”，然后令拥有“助”标记的角色选择一项：1.回复1点体力；2.摸两张牌。",
	["mouJiaZhuang"] = "妆",
	["mouliangzhu:1"] = "回复1点体力",
	["mouliangzhu:2"] = "摸两张牌",
	["$mouliangzhu1"] = "助君得胜战，跃马提缨枪！",
	["$mouliangzhu2"] = "平贼成君业，何惜上沙场！",
	  --结姻
	["moujieyin"] = "结姻",--使命成功是我自己编的，其实官方技能描述中并没有
	[":moujieyin"] = "使命技，游戏开始时，你令一名其他角色获得1枚“助”标记。出牌阶段开始时，你令有“助”标记的角色选择一项：" ..
	"1.若其有手牌，交给你两张手牌（不足则全给），然后其获得1点护甲；2.令你移交或移除其“助”标记（若其不为第一次失去“助”标记，则只能选择移除）。\
	<b>失败：</b>当场上的(所有)“助”标记被移除出游戏时，“婚姻”破裂，你将要“返乡”：回复1点体力并获得你武将牌上的所有“妆”，然后你将势力变更为“吴”并减1点体力上限。",
	["mouHusband"] = "助",
	["@moujieyin-start"] = "请选择一名其他角色，令其获得1枚“助”标记",
	["moujieyin:1"] = "交给其两张手牌(不足则全给)并获得1点护甲",
	["moujieyin:2"] = "令其移交或移除你的“助”标记",
	["moujieyin:3"] = "令其移除你的“助”标记",
	["moujieyin:4"] = "你移交其“助”标记给另一名角色",
	["moujieyin:5"] = "你移除其“助”标记(若如此做,你的使命将失败)",
	["mouHusbandMarkLost"] = "已失去过[助]标记",
	["#moujieyin"] = "请交给 %src 两张手牌，然后获得1点护甲",
	["@moujieyin-markmove"] = "请将该角色的“助”标记移交给除其之外的一名角色",
	["moujieyin_fail"] = "",
	["$moujieyin_success"] = "上邪！我欲与君相知，长命无绝衰。\
	山无陵，江水为竭，冬雷震震，\
	夏雨雪，天地合，乃敢与君绝。",
	["$moujieyin1"] = "君若不负吾心，妾自随君千里！",--一名角色得到“助”标记/护甲
	["$moujieyin2"] = "夫妻之情既断，何必再问归期！",--使命失败
	  --枭姬
	["mouxiaoji"] = "枭姬",
	[":mouxiaoji"] = "吴势力技，当你失去装备区里的一张牌时，你摸两张牌，然后你可以弃置场上的一张牌。",
	["@mouxiaoji-throw"] = "你可以弃置场上的一张牌",
	["$mouxiaoji1"] = "吾之所通，何止十八般兵刃！",
	["$mouxiaoji2"] = "既如此，就让尔等见识一番！",
	  --阵亡
	["~mobilemou_sunshangxiang"] = "此去一别，竟无再见之日......",

	--谋张飞
	  --正式版
	["mobilemou_zhangfei"] = "谋张飞",
	["#mobilemou_zhangfei"] = "义付桃园",
	["designer:mobilemou_zhangfei"] = "官方",
	["cv:mobilemou_zhangfei"] = "官方",
	["illustrator:mobilemou_zhangfei"] = "佚名",
	  --咆哮
	["moupaoxiao"] = "咆哮",
	["moupaoxiaoHWtMD"] = "咆哮",
	["moupaoxiao"] = "咆哮",
	[":moupaoxiao"] = "锁定技，你使用【杀】无次数限制；若你装备有武器牌，你使用【杀】无距离限制。若你于出牌阶段使用过【杀】，你于此阶段使用【杀】指定的目标本回合非锁定技失效，且此【杀】不可被响应、伤害+1。此【杀】造成伤害后，若目标角色未死亡，你失去1点体力并随机弃置一张手牌。",
	["$moupaoxiao1"] = "我乃燕人张飞，尔等休走！",
	["$moupaoxiao2"] = "战又不战，退又不退，却是何故！",
	  --协击
	["mouxieji"] = "协击",
	[":mouxieji"] = "准备阶段，你可以选择一名其他角色，与其进行“协力”。其结束阶段，若你与其“协力”成功，你可以选择至多三名角色，依次视为对这些角色使用一张【杀】（无视距离），且此【杀】造成伤害后，你摸等同于伤害值的牌。",
	["@XL-xieji"] = "协击：你可以令一名其他角色与你“协力”，成功可白嫖三张【杀】",
	["xiejiFrom"] = "",
	["xiejiTo"] = "",
	["@mouxieji-slash"] = "你可以选择至多三名角色，依次视为对他们使用【杀】",
	["~mouxieji"] = "按技能描述来说，其实你可以选自己？",
	["mouxiejiS"] = "协击",
	["$mouxieji2"] = "二哥，俺来助你！",--开始协力
	["$mouxieji1"] = "兄弟三人协力，破敌只在须臾！",--协力成功
	["$mouxieji3"] = "吴贼害我手足，此仇今日当报！",--开杀
	  --阵亡
	["~mobilemou_zhangfei"] = "不恤士卒，终为小人所害！...",

	--谋赵云
	  --标准版
	["mobilemou_zhaoyun"] = "谋赵云",
	["#mobilemou_zhaoyun"] = "七进七出",
	["designer:mobilemou_zhaoyun"] = "官方",
	["cv:mobilemou_zhaoyun"] = "官方",
	["illustrator:mobilemou_zhaoyun"] = "佚名",
	  --龙胆
	["moulongdan"] = "龙胆",
	[":moulongdan"] = "剩余可用X次，你可以以【杀】当【闪】，以【闪】当【杀】使用或打出，然后摸一张牌。（X初始为1且至多为3；每名角色的回合结束时，X加1）",
	[":moulongdan1"] = "剩余可用X次，你可以以【杀】当【闪】，以【闪】当【杀】使用或打出，然后摸一张牌。（X初始为1且至多为3；每名角色的回合结束时，X加1）",
	[":moulongdan2"] = "剩余可用X次，你可以将一张基本牌当任意一种基本牌使用或打出，然后摸一张牌。（X初始为1且至多为<font color='red'><b>4</b></font>；每名角色的回合结束时，X加1）",
	["moulongdanLast"] = "龙胆剩余",
	["$moulongdan1"] = "长坂沥赤胆，佑主成忠名！",
	["$moulongdan2"] = "龙驹染碧血，银枪照丹心！",
	  --积著
	["moujizhuo"] = "积著",
	[":moujizhuo"] = "准备阶段，你可以选择一名其他角色，与其进行“协力”。其结束阶段，若你与其“协力”成功，直到你的下一个结束阶段，你将“龙胆”改为：" ..
	"剩余可用X次，你可以将一张基本牌当任意一种基本牌使用或打出，然后摸一张牌。（X初始为1且至多为<font color='red'><b>4</b></font>；每名角色的回合结束时，X加1）",
	["@XL-jizhuo"] = "积著：你可以令一名其他角色与你“协力”，成功可升级“龙胆”",
	["jizhuoFrom"] = "",
	["jizhuoTo"] = "",
	["$moujizhuo1"] = "义贯金石，忠以卫上！",--开始协力
	["$moujizhuo3"] = "兴汉伟功，从今始成！",--协力成功
	["$moujizhuo2"] = "遵奉法度，功效可书！",--升级龙胆
	  --阵亡
	["~mobilemou_zhaoyun"] = "汉室未兴，功业未成......",

	--谋刘赪
	["mobilemou_liucheng"] = "谋刘赪",
	["#mobilemou_liucheng"] = "泣梧的湘女",
	["designer:mobilemou_liucheng"] = "官方",
	["cv:mobilemou_liucheng"] = "官方",
	["illustrator:mobilemou_liucheng"] = "佚名",
	  --掠影
	["moulveying"] = "掠影",
	[":moulveying"] = "当你使用【杀】结算结束后，若你的“椎”标记数不小于2，你移去2枚“椎”标记，摸一张牌，然后可以视为使用一张【过河拆桥】。<font color='green'><b>出牌阶段限两次，</b></font>当你使用【杀】指定其他角色为目标时，你获得1枚“椎”标记。",
	["mouchui"] = "椎",
	["@moulveying_ghcc"] = "你可以视为使用一张【过河拆桥】",
	["moulveyingUsed"] = "",
	["$moulveying1"] = "避实击虚，吾可不惮尔等蛮力！",
	["$moulveying2"] = "疾步如风，谁人可视吾影！",
	  --莺舞
	["mouyingwu"] = "莺舞",
	[":mouyingwu"] = "当你使用非伤害类普通锦囊牌结算结束后，若你的“椎”标记数不小于2，你移去2枚“椎”标记，摸一张牌，然后可以视为使用一张【杀】（不计次）。<font color='green'><b>出牌阶段限两次，</b></font>当你使用非伤害类普通锦囊牌指定一名角色为目标时，若你有技能“掠影”，你获得1枚“椎”标记。",
	["@mouyingwu_slash"] = "你可以视为使用一张不计入次数的【杀】",
	["mouyingwuUsed"] = "",
	["$mouyingwu1"] = "莺舞曼妙，杀机亦藏其中！",
	["$mouyingwu2"] = "莺翼之羽，便是诛汝之锋！",
	  --阵亡
	["~mobilemou_liucheng"] = "此番寻药未果，怎医叙儿之疾......",


["tenyear_panshu"] = "潘淑[十周年]",
["&tenyear_panshu"] = "潘淑",
["#tenyear_panshu"] = "神女",
["illustrator:tenyear_panshu"] = "夏季与杨杨",
["zhiren"] = "织纴",
[":zhiren"] = "当你于回合内使用第一张非转化的牌时，根据此牌名称字数，你可以依次执行以下选项中的前X项（X为此牌名称字数）：1.观看牌堆顶X张牌并以任意顺序置于牌堆顶或牌堆底；2.依次弃置场上一张装备牌和一张延时类锦囊牌；3.回复1点体力；4.摸三张牌。",
["@zhiren-equip"] = "请弃置场上一张装备牌",
["@zhiren-judge"] = "请弃置场上一张延时类锦囊牌",
["zhiren_judge"] = "织纴",
["yaner"] = "燕尔",
[":yaner"] = "每个回合限一次，当其他角色于其出牌阶段内失去最后的手牌后，你可以与其各摸两张牌。若你摸的两张牌类型相同，“织纴”改为回合外也可发动直到你的下个回合开始；若该角色摸的两张牌类型相同，其回复1点体力。",
[":&yaner"] = "回合外也可发动“织纴”",
["$zhiren1"] = "穿针引线，栩栩如生",
["$zhiren2"] = "纺绩织纴，布帛可成",
["$yaner1"] = "如胶似漆，白首相随",
["$yaner2"] = "新婚燕尔，亲睦和美",
["~tenyear_panshu"] = "有喜必忧，以为深戒",

["mobile_wenyang"] = "文鸯[手杀]",
["&mobile_wenyang"] = "文鸯",
["#mobile_wenyang"] = "独骑破军",
["illustrator:mobile_wenyang"] = "官方",
["quedi"] = "却敌",
[":quedi"] = "每个回合限一次，当你使用【杀】或【决斗】指定唯一目标后，你可以选择一项：1.获得其一张手牌；2.弃置一张基本牌令此牌伤害+1；3.减1点体力上限，然后依次执行前两项。",
["quedi:obtain"] = "获得%src一张手牌",
["quedi:damage"] = "此牌伤害+1",
["quedi:beishui"] = "减1点体力上限，执行前面所有项",
["@quedi-basic"] = "请弃置一张基本牌",
["mobilechoujue"] = "仇决",
[":mobilechoujue"] = "锁定技，当你杀死一名其他角色时，你加1点体力上限，摸两张牌，本回合可额外发动一次“却敌”。",
[":&mobilechoujue"] = "本回合你可以额外发动%src次“却敌”",
["chuifeng"] = "棰锋",
[":chuifeng"] = "魏势力技，出牌阶段限两次，你可以失去1点体力视为使用一张【决斗】，当你受到此牌造成的伤害时，你防止之且“棰锋”本回合失效。",
["chongjian"] = "冲坚",
[":chongjian"] = "吴势力技，你可以将一张装备牌当【酒】或任一种【杀】使用，此【杀】无距离限制且无视防具；以此法使用的【杀】造成伤害后，你获得目标装备区的X张牌（X为伤害值）。",

["$chuifeng1"] = "率军冲锋，不惧刀枪所阻！",
["$chuifeng2"] = "登锋履刃，何妨马革裹尸！",
["$chongjian1"] = "尔等良将，于我不堪一击！",
["$chongjian2"] = "此等残兵，破之何其易也！",
["$quedi1"] = "力摧敌阵，如视天光破云！",
["$quedi2"] = "让尔等有命追，无命回！",
["$mobilechoujue1"] = "血海深仇，便在今日来报！",
["$mobilechoujue2"] = "取汝之头，以祭先父！",
["~mobile_wenyang"] = "半生功业，而见疑于一家之言，岂能无怨！",
["ol_dengzhi"] = "邓芝[OL]",
["&ol_dengzhi"] = "邓芝",
["#ol_dengzhi"] = "坚贞简亮",
["illustrator:ol_dengzhi"] = "",
["xiuhao"] = "修好",
[":xiuhao"] = "每个回合限一次，当你对其他角色造成伤害时或其他角色对你造成伤害时，你可防止此伤害，然后伤害来源摸两张牌。",
["sujian"] = "素俭",
[":sujian"] = "锁定技，弃牌阶段开始时，你选择一项：将所有非本回合获得的手牌分配给其他角色；或弃置非本回合获得的手牌，然后弃置一名其他角色至多等量的牌。然后结束此阶段。",
["sujian:give"] = "分配非本回合获得的手牌",
["sujian:discard"] = "弃置非本回合获得的手牌，然后弃置一名其他角色至多等量的牌",
["@sujian-give"] = "请分配这些牌",
["@sujian-discard"] = "请弃置一名其他角色的牌",
["$xiuhao1"] = "吴蜀合同，可御魏敌",
["$xiuhao2"] = "与吾修好，共为唇齿",
["$sujian1"] = "不苟素俭，不治私产",--对的，就是这个治，不是置。原文：身之衣食资仰于官,不苟素俭,然终不治私产,妻子不免饥寒 
["$sujian2"] = "高风亮节，摆袖却金",
["~ol_dengzhi"] = "修好未成，蜀汉恐危……",

["ol_mazhong"] = "马忠[OL]",
["&ol_mazhong"] = "马忠",
["illustrator:ol_mazhong"] = "Thinking",
["olfuman"] = "抚蛮",
[":olfuman"] = "<font color=\"green\"><b>出牌阶段每名角色限一次，</b></font>你可以将一张手牌交给一名其他角色，此牌视为【杀】直到离开一名角色的手牌。当此【杀】结算完时，你摸一张牌；若此【杀】造成了伤害，改为摸两张牌。",
["$olfuman1"] = "恩威并施，蛮夷可为我所用。",
["$olfuman2"] = "发兵器啦！",

["caoanmin"] = "曹安民",
["#caoanmin"] = "履薄临深",
["illustrator:caoanmin"] = "君桓文化",
["xianwei"] = "险卫",
[":xianwei"] = "锁定技，准备阶段开始时，你废除一个装备栏并摸等同于你未废除装备栏数的牌，然后令一名其他角色使用牌堆中第一张对应副类别的装备牌（若牌堆中没有则改为摸一张牌）。当你废除所有装备栏后，你加两点体力上限，然后你视为在其他角色攻击范围内且其他角色视为在你攻击范围内。",
["xianwei:0"] = "废除武器栏",
["xianwei:1"] = "废除防具栏",
["xianwei:2"] = "废除+1坐骑栏",
["xianwei:3"] = "废除-1坐骑栏",
["xianwei:4"] = "废除宝物栏",
["@xianwei-use"] = "请选择使用装备牌的角色",
["#XianweiEquipArea"] = "%from 失去了所有装备栏，“%arg”触发",
["$xianwei1"] = "曹家儿郎，何惧一死",
["$xianwei2"] = "此役当战，有死无生",
["~caoanmin"] = "伯父快走……",

["qiaozhou"] = "谯周",
["#qiaozhou"] = "观星知命",
["illustrator:qiaozhou"] = "",
["zhiming"] = "知命",
[":zhiming"] = "准备阶段开始时与弃牌阶段结束时，你摸一张牌，然后你可以将一张牌置于牌堆顶。",
["@zhiming-put"] = "你可以将一张牌置于牌堆顶",
["xingbu"] = "星卜",
[":xingbu"] = "结束阶段开始时，你可以亮出牌堆顶的三张牌，根据其中红色牌的数量，令一名其他角色获得对应效果直到其回合结束：\
				三张：（五星连珠）摸牌阶段额外摸两张牌、出牌阶段可以额外使用一张【杀】、跳过弃牌阶段；\
				两张：（扶匡东柱）出牌阶段使用第一张牌结算完时，弃置一张牌然后摸两张牌；\
				不多于一张：（荧惑守心）出牌阶段可使用【杀】的次数-1。",
["@xingbu-invoke"] = "请选择一名其他角色获得 %src 效果",
["xbwuxinglianzhu"] = "五星连珠",
[":&xbwuxinglianzhu"] = "摸牌阶段额外摸2*%src张牌、出牌阶段可以额外使用%src张【杀】、跳过弃牌阶段",
["xbfukuangdongzhu"] = "扶匡东柱",
[":&xbfukuangdongzhu"] = "出牌阶段使用第一张牌结算完时，弃置一张牌然后摸两张牌",
["xbyinghuoshouxin"] = "荧惑守心",
[":&xbyinghuoshouxin"] = "出牌阶段可使用【杀】的次数-%src",
["xingbu_xbwuxinglianzhu"] = "星卜",
["xingbu_xbfukuangdongzhu"] = "星卜",
["xingbu_xbyinghuoshouxin"] = "星卜",

["$zhiming1"] = "天定人命，仅可一窥。",
["$zhiming2"] = "知命而行，尽诸人事。",
["$xingbu1"] = "天现祥瑞，此乃大吉之兆。",
["$xingbu2"] = "天象显异，北伐万不可期。",
["~qiaozhou"] = "老夫死不足惜，但求蜀地百姓无虞！",

["ol_qiaozhou"] = "谯周[OL]",
["&ol_qiaozhou"] = "谯周",
["#ol_qiaozhou"] = "观星知命",
["illustrator:ol_qiaozhou"] = "",
["olxingbu"] = "星卜",
[":olxingbu"] = "结束阶段开始时，你可以亮出牌堆顶的三张牌，根据其中红色牌的数量，令一名其他角色获得对应效果直到其回合结束：\
				三张：摸牌阶段额外摸两张牌，出牌阶段使用【杀】的次数+1；\
				两张：出牌阶段使用【杀】的次数-1，跳过弃牌阶段；\
				不多于一张：准备阶段开始时弃置一张手牌。",
["@olxingbu-invoke"] = "请选择一名其他角色获得星卜效果（%src张红色牌）",
["olxingbu3"] = "星卜",
[":&olxingbu3"] = "摸牌阶段额外摸2*%src张牌，出牌阶段使用【杀】的次数+%src",
["olxingbu2"] = "星卜",
[":&olxingbu2"] = "出牌阶段使用【杀】的次数-%src，跳过弃牌阶段",
["olxingbu1"] = "星卜",
[":&olxingbu1"] = "准备阶段开始时弃置%src张手牌",

["$olxingbu1"] = "天现祥瑞，此乃大吉之兆。",
["$olxingbu2"] = "天象显异，北伐万不可期。",
["~ol_qiaozhou"] = "老夫死不足惜，但求蜀地百姓无虞！",

["ol_jiaxu"] = "界贾诩[OL]",
["&ol_jiaxu"] = "界贾诩",
["illustrator:ol_jiaxu"] = "",
["cv:ol_jiaxu"] = "官方",
["olwansha"] = "完杀",
[":olwansha"] = "锁定技，你的回合内：未处于濒死状态的其他角色不能使用【桃】；一名角色的濒死结算中，未处于濒死状态的其他角色的非锁定技失效。",
["olluanwu"] = "乱武",
[":olluanwu"] = "限定技，出牌阶段，你可以令所有其他角色依次选择一项：1.对其距离最近的另一名角色使用一张【杀】；2.失去1点体力。然后，你可以视为使用一张无距离限制的【杀】。",
["@olluanwu"] = "你可以视为使用一张无距离限制的【杀】",
["olweimu"] = "帷幕",
[":olweimu"] = "锁定技，你不能成为黑色锦囊牌的目标。当你于回合内受到伤害时，防止此伤害并摸两倍数量的牌。",
["#OLWeimuPreventDamage"] = "%from 的“%arg”触发，防止了 %arg2 点伤害",
["olluanwu"] = "乱武",
[":olluanwu"] = "限定技，出牌阶段，你可以令所有其他角色依次选择一项：1.对距离最近的另一名角色使用一张【杀】；2.失去1点体力。然后，你可以视为使用一张无距离限制的【杀】。",
["@olluanwu"] = "你可以视为使用一张无距离限制的【杀】",
["$olwansha1"] = "有谁敢试试？",
["$olwansha2"] = "斩草务尽，以绝后患",
["$olweimu1"] = "此伤与我无关",
["$olweimu2"] = "还是另寻他法吧",
["$olluanwu1"] = "一切都在我的掌控中。",
["$olluanwu2"] = "这乱世还不够乱！",
["~ol_jiaxu"] = "此劫，我亦有所算",

["ol_lusu"] = "界鲁肃[OL]",
["&ol_lusu"] = "界鲁肃",
["illustrator:ol_lusu"] = "",
["cv:ol_lusu"] = "官方",
["olhaoshi"] = "好施",
[":olhaoshi"] = "摸牌阶段，你可以额外摸两张牌，然后若你的手牌数大于5，你将一半的手牌交给手牌最少的一名其他角色（向下取整），" ..
			"然后直到你的回合开始，当你成为【杀】或非延时类锦囊牌的目标后，其可交给你一张手牌。",
["@olhaoshi-give"] = "你可以交给 %src 一张手牌",
["oldimeng"] = "缔盟",
[":oldimeng"] = "出牌阶段限一次，你可交换两名手牌数的差不大于你的牌数的其他角色的手牌，若如此做，出牌阶段结束时，你弃置X张牌（X为这两名角色手牌数的差）。",
["$olhaoshi1"] = "仗义疏财，深得人心",
["$olhaoshi2"] = "召聚少年，给其衣食",
["$oldimeng1"] = "深知其奇，相与亲结",
["$oldimeng2"] = "同盟之人，言归于好",
["~ol_lusu"] = "一生为国，纵死无憾",

["second_liuqi"] = "刘琦[二版]",
["&second_liuqi"] = "刘琦",
["illustrator:second_liuqi"] = "NOVART",
["secondwenji"] = "问计",
[":secondwenji"] = "出牌阶段开始时，你可以令一名其他角色交给你一张牌。你于本回合内使用与该牌同类型的牌不能被其他角色响应。",
["secondtunjiang"] = "屯江",
[":secondtunjiang"] = "结束阶段开始时，若你未于本回合的出牌阶段内使用牌指定过其他角色为目标，你可以摸X张牌（X为全场势力数）。",
["$secondwenji1"] = "还望先生救我！",
["$secondwenji2"] = "言出子口，入于吾耳，可以言未？",
["$secondtunjiang1"] = "江夏冲要之地，孩儿愿往守之。",
["$secondtunjiang2"] = "皇叔勿惊，吾与关将军已到。",

["second_tangji"] = "唐姬[二版]",
["&second_tangji"] = "唐姬",
["illustrator:second_tangji"] = "",
["secondkangge"] = "抗歌",
[":secondkangge"] = "你的第一个回合开始时，选择一名其他角色。该角色于其回合外获得手牌后，你摸等量的牌（每回合最多摸三张）。" ..
				"每轮限一次，该角色进入濒死状态时，你可令其回复体力至1点。该角色死亡时，你弃置所有牌并失去1点体力。",
["secondjielie"] = "节烈",
[":secondjielie"] = "当你受到除自己和“抗歌”角色以外的角色造成的伤害时，你可以防止此伤害并选择一种花色，然后你失去X点体力，令“抗歌”角色从弃牌堆中随机获得X张此花色的牌（X为伤害值）。",
["secondjielie:secondjielie"] = "你是否发动“节烈”防止%src点伤害？",
["$secondkangge1"] = "慷慨悲歌，以抗凶逆",
["$secondkangge2"] = "忧惶昼夜，抗之以歌",
["$secondjielie1"] = "节烈之妇，从一而终也",
["$secondjielie2"] = "清闲贞静，守节整齐",

["dufuren"] = "杜夫人",
["#dufuren"] = "沛王太妃",
["illustrator:dufuren"] = "匠人绘",
["yise"] = "异色",
[":yise"] = "其他角色获得你的牌后，若其中包含：红色牌，你可令其回复1点体力；黑色牌，其下次受到【杀】的伤害时，此伤害+1。",
[":&yise"] = "下次受到【杀】的伤害时，此伤害+%src",
["shunshi"] = "顺世",
[":shunshi"] = "准备阶段开始时或当你于回合外受到伤害后，你可交给除伤害来源外的一名其他角色一张牌。若如此做，你获得以下效果：下个摸牌阶段摸牌数+1、下个出牌阶段使用【杀】次数+1、下个弃牌阶段手牌上限+1。",
["@shunshi-give"] = "你可交给一名其他角色一张牌",
[":&shunshi"] = "下个摸牌阶段摸牌数+1、下个出牌阶段使用【杀】次数+1、下个弃牌阶段手牌上限+1",
["$yise1"] = "明丽端庄，双瞳剪水",
["$yise2"] = "姿色天然，貌若桃李",
["$shunshi1"] = "顺应时运，得保安康",
["$shunshi2"] = "随遇而安，宠辱不惊",
["~dufuren"] = "往事云烟，去日苦多",

["ol_wangrong"] = "王荣[OL]",
["&ol_wangrong"] = "王荣",
["illustrator:ol_wangrong"] = "",
["fengzi"] = "丰姿",
[":fengzi"] = "出牌阶段限一次，你使用基本牌或非延时类锦囊牌时，可以弃置一张同类型的手牌，令此牌的效果结算两次。",
["@fengzi-discard"] = "你可以弃置一张 %src 令 %arg 结算两次",
["jizhanw"] = "吉占",
[":jizhanw"] = "摸牌阶段开始时，你可以放弃摸牌，展示牌堆顶的一张牌，猜测牌堆顶的下一张牌点数大于或小于此牌，然后展示之，若猜对你可重复此流程，最后你获得以此法展示的牌。",
["jizhanw:more"] = "点数大于%src",
["jizhanw:less"] = "点数小于%src",
["fusong"] = "赋颂",
[":fusong"] = "当你死亡时，你可令一名体力上限大于你的角色选择获得“丰姿”或“吉占”。",
["@fusong-invoke"] = "你可以发动“赋颂”",
["$fengzi1"] = "丰姿秀丽，礼法不失",
["$fengzi2"] = "倩影姿态，悄然入心",
["$jizhanw1"] = "得吉占之兆，言福运之气",
["$jizhanw2"] = "吉占逢时，化险为夷",
["$fusong1"] = "陛下垂爱，妾身方有此位",
["$fusong2"] = "长情颂，君王恩",
["~ol_wangrong"] = "只求吾儿一生平安",

["yuanhuan"] = "袁涣",
["#yuanhuan"] = "随车致雨",
["illustrator:yuanhuan"] = "",
["qingjue"] = "请决",
[":qingjue"] = "每轮限一次，当其他角色使用牌指定一名体力值小于其且不处于濒死状态的角色为目标时，若目标唯一且不为你，你可以摸一张牌，然后与其拼点。若你：赢，取消之；没赢，你将此牌转移给你。",
["fengjie"] = "奉节",
[":fengjie"] = "锁定技，准备阶段开始时，你选择一名其他角色。直到你下回合开始，每名角色的结束阶段开始时，若其存活，你将手牌数摸至或弃置至与其体力值相同（至多为4）。",
["@fengjie-invoke"] = "请选择一名其他角色",
["$qingjue3"] = "鼓之以道德，征之以仁义，才可得百姓之心。",
["$qingjue1"] = "兵者，凶器也，宜不得已而用之。",
["$qingjue2"] = "民安土重迁，易以顺行，难以逆动。",
["$fengjie1"] = "见贤思齐，内自省也。",
["$fengjie2"] = "立本于道，置身于正。",
["~yuanhuan"] = "乱世之中，有礼无用啊……",


["zongyu"] = "宗预",
["#zongyu"] = "御严无惧",
["illustrator:zongyu"] = "",
["zhibian"] = "直辩",
[":zhibian"] = "准备阶段开始时，你可以拼点。若你赢，你可以选择一项：将对方场上的一张牌移到你的对应区域；2.回复1点体力；3.跳过下个摸牌阶段，然后依次执行前两项。若你没赢，你失去1点体力。",
["@zhibian-invoke"] = "你可以与一名其他角色拼点",
["zhibian:move"] = "移动%src场上的牌",
["zhibian:recover"] = "回复1点体力",
["zhibian:beishui"] = "跳过下个摸牌阶段，然后依次执行前两项",
["yuyanzy"] = "御严",
[":yuyanzy"] = "锁定技，当你成为体力值大于你的角色使用的非转化的【杀】的目标时，其选择一项：交给你一张点数大于此【杀】的牌；或取消之。",
["@yuyanzy-give"] = "请交给 %src 一张点数大于 %arg 的牌",
["$zhibian1"] = "两国各增守将，皆事势宜然，何足相问。",
["$zhibian2"] = "固边大计，乃立国之本，岂有不设之理。",
["$yuyanzy1"] = "正直敢言，不惧圣怒。",
["$yuyanzy2"] = "威武不能屈，方为大丈夫。",
["~zongyu"] = "此次出使，终不负陛下期望。",

["mobile_chenwudongxi"] = "陈武＆董袭",
["&mobile_chenwudongxi"] = "陈武董袭",
["#mobile_chenwudongxi"] = "陨身不恤",
["illustrator:mobile_chenwudongxi"] = "",
["yilie"] = "毅烈",
[":yilie"] = "出牌阶段开始时，你可以选择一项：1.此阶段内，你可以额外使用一张【杀】；2.此阶段内，当你使用的【杀】被【闪】抵消时，你摸一张牌；3.失去1点体力，然后依次执行前两项。",
["yilie:slash"] = "此阶段内可以额外使用一张【杀】",
["yilie:draw"] = "此阶段内使用的【杀】被【闪】抵消时，摸一张牌",
["yilie:beishui"] = "失去1点体力，依次执行前两项",
["mobilefenming"] = "奋命",
[":mobilefenming"] = "出牌阶段限一次，你可以横置一名体力值不大于你的角色，若其已横置，改为获得其一张牌。",
["$yilie1"] = "哈哈哈哈！来吧！	",
["$yilie2"] = "哼！都来受死！",
["$mobilefenming1"] = "合肥一役，吾等必拼死效力！",
["$mobilefenming2"] = "主公勿忧，待吾等上前一战！",
["~mobile_chenwudongxi"] = "陛下速退！",

["nanhualaoxian"] = "南华老仙",
["#nanhualaoxian"] = "仙人指路",
["illustrator:nanhualaoxian"] = "君桓文化",
["gongxiu"] = "共修",
[":gongxiu"] = "回合结束时，若你本回合发动过“经合”，你可以选择一项：1.所有在本回合通过“经合”获得过技能的角色摸一张牌；2.所有在本回合未通过“经合”获得过技能的其他角色弃置一张手牌。",
["gongxiu:draw"] = "所有在本回合通过“经合”获得过技能的角色摸一张牌",
["gongxiu:discard"] = "所有在本回合未通过“经合”获得过技能的其他角色弃置一张手牌",
["jinghe"] = "经合",
[":jinghe"] = "每回合限一次，出牌阶段，你可以展示至多四张牌名各不相同的手牌，并选择等量的角色，然后每名角色可以从“写满技能的天书”中选择并获得一个技能直到你的下回合开始。",
["nhyinbing"] = "阴兵",
[":nhyinbing"] = "锁定技，你造成的【杀】的伤害改为失去体力。其他角色失去体力后，你摸一张牌。",
["nhhuoqi"] = "活气",
[":nhhuoqi"] = "出牌阶段限一次，你可以弃置一张牌，然后令体力值最少的一名角色回复1点体力并摸一张牌。",
["nhguizhu"] = "鬼助",
[":nhguizhu"] = "每个回合限一次，一名角色进入濒死状态时，你可以摸两张牌。",
["nhxianshou"] = "仙授",
[":nhxianshou"] = "出牌阶段限一次，你可以令一名角色摸一张牌，若其体力值满，改为摸两张牌。",
["nhlundao"] = "论道",
[":nhlundao"] = "当你受到伤害后，若伤害来源手牌比你多，你可以弃置其一张牌；若伤害来源手牌比你少，你摸一张牌。",
["nhguanyue"] = "观月",
[":nhguanyue"] = "结束阶段开始时，你可以观看牌堆顶两张牌，然后获得其中一张牌并将另一张牌置于牌堆顶。",
["nhyanzheng"] = "言政",
[":nhyanzheng"] = "准备阶段开始时，若你的手牌数大于1，你可以保留一张手牌并弃置其余牌，然后选择至多等于弃牌数量的角色，对这些角色各造成1点伤害。",
["@nhyanzheng-keep"] = "你可以发动“言政”保留一张手牌并弃置其余牌",
["@nhyanzheng"] = "请对至多 %src 名角色各造成1点伤害",
["$gongxiu1"] = "福祸与共，业山可移",
["$gongxiu2"] = "修行退智，遂之道也",
["$jinghe1"] = "大哉乾元，万物资始",
["$jinghe2"] = "无极之外，复无无极",
["~nanhualaoxian"] = "道亦有穷时",

["nos_jin_yangzhi"] = "杨芷[旧]",
["&nos_jin_yangzhi"] = "杨芷",
["#nos_jin_yangzhi"] = "武悼皇后",
["illustrator:nos_jin_yangzhi"] = "",
["nosjinwanyi"] = "婉嫕",
[":nosjinwanyi"] = "出牌阶段，你可将一张带有强化效果的手牌当【逐近弃远】或【出其不意】或【水淹七军】或【洞烛先机】使用（每种牌名每回合限一次）。",
["$nosjinwanyi1"] = "天性婉嫕，易以道御。",
["$nosjinwanyi2"] = "婉嫕利珍，为后攸行。",
["~nos_jin_yangzhi"] = "贾氏……构陷……",

["nos_jin_yangyan"] = "杨艳[旧]",
["&nos_jin_yangyan"] = "杨艳",
["#nos_jin_yangyan"] = "武元皇后",
["illustrator:nos_jin_yangyan"] = "",
["nosjinxuanbei"] = "选备",
[":nosjinxuanbei"] = "游戏开始时，你获得牌堆中两张带强化效果的牌。每个回合限一次，你使用带强化效果的牌后，你可将其交给一名其他角色。",
["@nosjinxuanbei-invoke"] = "你可以将 %src 交给一名其他角色",
["$nosjinxuanbei1"] = "博选良家，以充后宫。",
["$nosjinxuanbei2"] = "非良家，不可选也。",
["~nos_jin_yangyan"] = "一旦殂损，痛悼伤怀……",

["jin_zuofen"] = "左棻",
["#jin_zuofen"] = "无宠的才女",
["illustrator:jin_zuofen"] = "",
["jinzhaosong"] = "诏颂",
[":jinzhaosong"] = "其他角色的摸牌阶段结束时，若其没有标记，你可令其正面向上交给你一张手牌，然后根据此牌的类型，令该角色获得对应的标记：锦囊牌，“诔”标记；装备牌，“赋”标记；" ..
					"基本牌，“颂”标记。拥有标记的角色：进入濒死时，可弃置“诔”，回复至1体力，摸1张牌并减少1点体力上限；出牌阶段开始时，可弃置“赋”，弃置一名角色区域内的一张牌，" ..
					"然后可令其摸一张牌；使用仅指定一个目标的【杀】时，可弃置“颂”为此【杀】额外选择至多两个目标，然后若此【杀】造成的伤害小于2，其失去1点体力。",
["jzslei"] = "诔",
["jzsfu"] = "赋",
["jzssong"] = "颂",
["jinzhaosong_give"] = "请交给 %src 一张手牌",
["jinzhaosong_lei:recover"] = "你是否弃置“诔”，回复至1体力？",
["jinzhaosong_fu:draw"] = "你是否令其摸一张牌？",
["@jinzhaosong"] = "你可弃置“颂”为此【杀】额外选择至多两个目标",
["jinlisi"] = "离思",
[":jinlisi"] = "当你于回合外使用的牌置入弃牌堆后，你可将其交给一名手牌数不大于你的其他角色。",
["@jinlisi-give"] = "你可以将这些牌交给一名手牌数不大于你的其他角色",
["$jinzhaosong1"] = "领诏者，可上而颂之。",
["$jinzhaosong2"] = "今为诏，以上告下也。",
["$jinlisi1"] = "骨肉至亲，化为他人。",
["$jinlisi2"] = "梦想魂归，见所思兮。",
["~jin_zuofen"] = "惨怆愁悲……",

["shenguojia"] = "神郭嘉",
["#shenguojia"] = "星月奇佐",
["information:shenguojia"] = "ᅟᅠ<i>月明星稀，乌鹊南飞。绕树三匝，何枝可依？ᅟᅠ——曹操《短歌行》</i>",
["illustrator:shenguojia"] = "木美人",
["huishi"] = "慧识",
[":huishi"] = "出牌阶段限一次，若你的体力上限小于10，你可以进行一次判定，若判定结果与此阶段内以此法进行判定的判定结果花色均不同，且你的体力上限小于10，你可以重复此判定并加1点体力上限。" ..
				"然后你可将所有判定牌交给一名角色，然后若其手牌数为全场最多，你减1点体力上限。",
["@huishi-give"] = "你可将这些牌交给一名角色",
["godtianyi"] = "天翊",
[":godtianyi"] = "觉醒技，准备阶段开始时，若所有存活角色均受到过伤害，你加2点体力上限，回复1点体力，然后令一名角色获得“佐幸”。",
["@godtianyi-invoke"] = "请令一名角色获得“佐幸”",
["huishii"] = "辉逝",
[":huishii"] = "限定技，出牌阶段，你可以选择一名角色：若其有未触发的觉醒技且你的体力上限不小于存活角色数，你选择其中一个觉醒技，该技能视为满足觉醒条件；否则其摸四张牌。若如此做，你减2点体力上限。",
["zuoxing"] = "佐幸",
[":zuoxing"] = "准备阶段开始时，若神郭嘉存活且体力上限大于1，你可令神郭嘉减1点体力上限。若如此做，本回合的出牌阶段限一次，你可视为使用一张非延时类锦囊牌。",
["@zuoxing-invoke"] = "你可令神郭嘉减1点体力上限",
["$huishi1"] = "聪以知远，明以察微",
["$huishi2"] = "见微知著，识人心志",
["$godtianyi1"] = "天命靡常，惟德是辅",
["$godtianyi2"] = "可成吾志者，必此人也",
["$huishii1"] = "丧家之犬，主公实不足虑也",
["$huishii2"] = "时势兼备，主公复有何忧？",
["$zuoxing1"] = "以聪虑难,悉咨于上",
["$zuoxing2"] = "奉孝不才，愿献琴心",
--身计国谋，不可两遂
["~shenguojia"] = "可叹桢干命也迂",

["shentaishici"] = "神太史慈",
["#shentaishici"] = "义信天武",
["information:shentaishici"] = "ᅟᅠ<i>北海酬恩日，神亭酣战时。临终言壮志，千古共嗟咨！ᅟᅠ——《三国演义》</i>",
["illustrator:shentaishici"] = "",
["dulie"] = "笃烈",
[":dulie"] = "锁定技，游戏开始时，所有其他角色获得一枚“围”标记。你对没有“围”标记的角色使用【杀】无距离限制。当你成为没有“围”标记的角色使用的【杀】的目标时，你进行一次判定，若判定结果为红桃，此【杀】对你无效。",
["stscdlwei"] = "围",
["powei"] = "破围",
[":powei"] = "使命技，当你使用的【杀】对有“围”标记的角色造成伤害时，该角色弃置一枚“围”标记，然后防止此伤害。\
			<b>成功：</b>当你使用的【杀】结算完时，若没有角色有“围”标记，你获得技能“神著”。\
			<b>失败：</b>当你进入濒死时，你将体力回复至1点，然后弃置装备区内所有牌。",
["dangmo"] = "荡魔",
[":dangmo"] = "你于出牌阶段使用的第一张【杀】可以额外选择X名角色为目标（X为你的体力值-1）。",
["@dangmo"] = "你可以为【%src】选择至多%arg名额外目标",
["shenzhuo"] = "神著",
[":shenzhuo"] = "你使用的非转化的【杀】结算完时，摸一张牌。你使用【杀】无次数限制。",
["$dulie1"] = "素来言出必践，成吾信义昭彰",
["$dulie2"] = "小信如若不成，大信将以何立？",
["$powei1"] = "君且城中等候，待吾探敌虚实",--普通效果
["$powei2"] = "弓马骑射洒热血，突破重围显英豪",--成功
["$powei3"] = "敌军尚犹严防，有待明日再看",--失败
["$dangmo1"] = "魔高一尺，道高一丈",
["$dangmo2"] = "天魔祸世，吾自荡而除之",
["$shenzhuo1"] = "力引强弓百斤，矢出贯手著棼",
["$shenzhuo2"] = "箭既已在弦上，吾又岂能不发？",
["~shentaishici"] = "魂归……天地……",

["shensunce"] = "神孙策",
["#shensunce"] = "踞江鬼雄",
["information:shensunce"] = "ᅟᅠ<i>捋黄须，眺五湖。如此江山，应出孙伯符。ᅟᅠ——陈维崧《小梅花·其一·感事括古语效贺东山体》</i>",
["illustrator:shensunce"] = "",
["yingba"] = "英霸",
[":yingba"] = "出牌阶段限一次，你可以令一名体力上限大于1的其他角色减1点体力上限并获得一枚“平定”标记，然后你减1点体力上限。你对拥有“平定”标记的角色使用牌无距离限制。",
["sscybpingding"] = "平定",
["fuhaisc"] = "覆海",
[":fuhaisc"] = "锁定技，当你使用牌时，拥有“平定”标记的角色不能响应此牌。当你使用牌指定目标时，若目标中包含拥有“平定”标记的角色，且本回合你以此法获得的牌数小于2，你摸一张牌。一名其他角色死亡时，你加X点体力上限并摸X张牌（X为其“平定”标记数）。",
["pinghe"] = "冯河",
[":pinghe"] = "锁定技，你的手牌上限等于你已损失的体力值。当你受到其他角色的伤害时，若你有手牌且体力上限大于1，防止此伤害，然后你减1点体力上限并交给一名其他角色一张手牌，然后若你拥有“英霸”，伤害来源获得一枚“平定”标记。",
["$shensunce"] = "平定三郡，稳踞江东！",
["$yingba1"] = "从我者可免，拒我者难容！",
["$yingba2"] = "卧榻之侧，岂容他人鼾睡！",
["$fuhaisc1"] = "翻江复倒海，六合定乾坤！	",
["$fuhaisc2"] = "力攻平江东，威名扬天下！",
["$pinghe1"] = "不过胆小鼠辈，吾等有何惧哉！",
["$pinghe2"] = "只可得胜而返，岂能败战而归！",
["~shensunce"] = "无耻小人！胆敢暗算于我……",

["shenxunyu"] = "神荀彧",
["#shenxunyu"] = "洞心先识",
["illustrator:shenxunyu"] = "",
["information:shenxunyu"] = "ᅟᅠ<i>越陌度阡，枉用相存。契阔谈讌，心念旧恩。ᅟᅠ——曹操《短歌行》</i>",
["tianzuo"] = "天佐",
[":tianzuo"] = "锁定技，游戏开始时，你将八张【奇正相生】洗入牌堆。【奇正相生】对你无效。",
["lingce"] = "灵策",
[":lingce"] = "锁定技，当一名角色使用非转化的锦囊牌时，若此牌是【无中生有】、【过河拆桥】、【无懈可击】、【奇正相生】或已被你的“定汉”记录，你摸一张牌。",
["dinghan"] = "定汉",
[":dinghan"] = "每种牌名限一次，当你成为锦囊牌的目标时，你记录此牌名，然后此牌对你无效。回合开始时，你可以在你的“定汉”的记录中增加或移除一个锦囊牌的牌名。",
[":dinghan1"] = "每种牌名限一次，当你成为锦囊牌的目标时，你记录此牌名，然后此牌对你无效。回合开始时，你可以在你的“定汉”的记录中增加或移除一个锦囊牌的牌名。\
				<font color=\"red\"><b>已记录：%arg11</b></font>",
["#DingHanRemove"] = "%from 在“%arg”的记录中移除了【%arg2】",
["#DingHanAdd"] = "%from 在“%arg”的记录中增加了【%arg2】",
["dinghan:add"] = "增加一个记录",
["dinghan:remove"] = "移除一个记录",
["dinghan:tip"] = "变暗的卡牌是未记录的，其余的是已记录的",
["$tianzuo1"] = "此时进之多弊，守之多利，愿主公熟虑",
["$tianzuo2"] = "主公若不时定，待四方生心，则无及矣",
["$lingce1"] = "绍士卒虽众，其实难用，必无为也",
["$lingce2"] = "袁军不过一盘沙砾，主公用奇则散",
["$dinghan2"] = "益国之事，虽死弗避",
["$dinghan1"] = "杀身有地，报国有时",
["~shenxunyu"] = "宁鸣而死，不默而生",

["tenyear_new_sp_jiaxu"] = "sp贾诩[十周年]",
["#tenyear_new_sp_jiaxu"] = "料事如神",
["&tenyear_new_sp_jiaxu"] = "贾诩",
["illustrator:tenyear_new_sp_jiaxu"] = "凝聚永恒",
["cv:tenyear_new_sp_jiaxu"] = "官方",
["tenyearjianshu"] = "间书",
[":tenyearjianshu"] = "出牌阶段限一次，你可以将一张黑色手牌交给一名其他角色，然后选择另一名其他角色，令这两名角色拼点：赢的角色随机弃置一张牌，没赢的角色失去1点体力。若有角色因此死亡，此技能视为未发动过。",
["@tenyearjianshu-pindian"] = "请选择 %src 拼点的目标",
["#TenyearJianshuShow"] = "%from 展示了不能弃置的手牌",
["tenyearyongdi"] = "拥嫡",
[":tenyearyongdi"] = "限定技，出牌阶段，你可选择一名男性角色，若其体力值或体力上限全场最少，其回复1点体力或加1点体力上限；若其手牌数全场最少，其摸体力上限张牌（最多摸五张）。",
["tenyearyongdi:recover"] = "回复1点体力",
["tenyearyongdi:maxhp"] = "加1点体力上限",
["$tenyearjianshu1"] = "来，让我看一出好戏吧。",
["$tenyearjianshu2"] = "纵有千军万马，离心则难成大事。",
["$tenyearyongdi1"] = "臣愿为世子，肝脑涂地。",
["$tenyearyongdi2"] = "嫡庶有别，尊卑有序。",
["~tenyear_new_sp_jiaxu"] = "立嫡之事，真是取祸之道！",
}
return {extension,extensioncard}