--七哀
local mobilezhiqiai_skill = {}
mobilezhiqiai_skill.name = "mobilezhiqiai"
table.insert(sgs.ai_skills,mobilezhiqiai_skill)
mobilezhiqiai_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("@MobileZhiQiaiCard=.")
end

sgs.ai_skill_use_func.MobileZhiQiaiCard = function(card,use,self)
	local cards = {}
	
	if self.player:getArmor() and self:needToThrowArmor() then
		table.insert(cards,sgs.Sanguosha:getCard(self.player:getArmor():getEffectiveId()))
	else
		for _,c in sgs.qlist(self.player:getCards("h"))do
			if c:isKindOf("BasicCard") then continue end
			table.insert(cards,c)
		end
	end
	if #cards<=0 then return end
	
	self:sortByUseValue(cards,true)
	
	local card,friend = self:getCardNeedPlayer(cards,false)
	if card and friend then
		use.card = sgs.Card_Parse("@MobileZhiQiaiCard="..cards[1]:getEffectiveId())
	end
	
	self:sort(self.friends_noself,"handcard")
	for _,friend in ipairs(self.friends_noself)do
		if self:canDraw(friend) then
			use.card = sgs.Card_Parse("@MobileZhiQiaiCard="..cards[1]:getEffectiveId())
			use.to:append(friend)
			return
		end
	end
	
	self:sort(self.enemies)
	for _,enemy in ipairs(self.enemies)do
		if enemy:isKongcheng() and self:needKongcheng(enemy,true) and not hasManjuanEffect(enemy) then
			use.card = sgs.Card_Parse("@MobileZhiQiaiCard="..cards[1]:getEffectiveId())
			use.to:append(enemy)
			return
		end
	end
	
	if self.player:getLostHp()>0 or self:getOverflow()-1<=0 then
		for _,friend in ipairs(self.friends_noself)do
			if not (friend:isKongcheng() and self:needKongcheng(friend,true)) or hasManjuanEffect(friend) then
				use.card = sgs.Card_Parse("@MobileZhiQiaiCard="..cards[1]:getEffectiveId())
				use.to:append(friend)
				return
			end
		end
		
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if self:isFriend(p) or self:isEnemy(p) then continue end
			use.card = sgs.Card_Parse("@MobileZhiQiaiCard="..cards[1]:getEffectiveId())
			use.to:append(p)
			return
		end
		
		if #self.enemies>0 and not self:isValuableCard(cards[1]) and self:canDraw() and (self.player:getHp()~=getBestHp(self.player) or self.player:getLostHp()==0) then
			use.card = sgs.Card_Parse("@MobileZhiQiaiCard="..cards[1]:getEffectiveId())
			use.to:append(self.enemies[1])
			return
		end
	end
end

sgs.ai_use_priority.MobileZhiQiaiCard = 1.6

sgs.ai_card_intention.MobileZhiQiaiCard = function(self,card,from,tos)
	local intention = -20
	for _,to in sgs.list(tos)do
		if hasManjuanEffect(to) then continue end
		if self:needKongcheng(to,true) and to:isKongcheng() then
			intention = 20
		end
		sgs.updateIntention(from,to,intention)
	end
end

sgs.ai_skill_choice.mobilezhiqiai = function(self,choices,data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if not self:canDraw() then return "recover" end
		if target:getHp()>=getBestHp(target) then return "draw" end
		return "recover"
	else
		if not self:canDraw() then return "draw" end
		if target:getHp()==getBestHp(target) then return "recover" end
		return "draw"
	end
end

--善檄
sgs.ai_skill_playerchosen.mobilezhishanxi = function(self,targets)
	local enemies = {}
	for _,p in sgs.qlist(targets)do
		if self:isEnemy(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies<=0 then return nil end
	self:sort(enemies,"hp")
	return enemies[1]
end

sgs.ai_skill_discard.mobilezhishanxi = function(self,discard_num,min_num,optional,include_equip)
	local give = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	if self:needToThrowArmor() then
		table.insert(give,self.player:getArmor():getEffectiveId())
		for _,c in ipairs(cards)do
			if c:getEffectiveId()==self.player:getArmor():getEffectiveId() then continue end
			table.insert(give,c:getEffectiveId())
			break
		end
		if #give==2 then return give end
	end
	--if self:getCardsNum("Peach")>0 or self:getCardsNum("Analeptic")>0 or self:getSaveNum(true)>0 then return {} end  回复后还是会要求再选一次，不如给牌算了
	if not self:isWeak() and self.player:hasSkill("zhaxiang") and not self:willSkipPlayPhase() then return {} end
	for _,c in ipairs(cards)do
		table.insert(give,c:getEffectiveId())
		if #give==2 then return give end
	end
	return give
end

--挽危
local mobilezhiwanwei_skill = {}
mobilezhiwanwei_skill.name = "mobilezhiwanwei"
table.insert(sgs.ai_skills,mobilezhiwanwei_skill)
mobilezhiwanwei_skill.getTurnUseCard = function(self,inclusive)
	if self.player:isLord() then return end
	if #self.friends_noself==0 or self.player:getHp()<0 then return end
	if self:getCardsNum("Peach")+self:getCardsNum("Analeptic")+self:getSaveNum(true)<=0 and not hasBuquEffect(self.player) then return end
	return sgs.Card_Parse("@MobileZhiWanweiCard=.")
end

sgs.ai_skill_use_func.MobileZhiWanweiCard = function(card,use,self)
	self:sort(self.friends_noself,"hp")
	for _,p in ipairs(self.friends_noself)do
		if not self:isWeak(p) then continue end
		use.card = card
		use.to:append(p)
		return
	end
end

sgs.ai_use_priority.MobileZhiWanweiCard = 1.6
sgs.ai_card_intention.MobileZhiWanweiCard = -80

sgs.ai_skill_invoke.mobilezhiwanwei = function(self,data)
	if self.player:isLord() then return false end
	local friend = data:toPlayer()
	return self:isFriend(friend)
end

--约俭
sgs.ai_skill_cardask["@mobilezhiyuejian"] = function(self,data,pattern,target)
	local dis = self:askForDiscard("dummyreason",2,2,false,true)
	if #dis==2 then
		for _,id in ipairs(dis)do
			local card = sgs.Sanguosha:getCard(id)
			if (card:isKindOf("Peach") or card:isKindOf("Analeptic")) and self.player:canUse(card) then return "." end
		end
		return "$"..table.concat(dis,"+")
	end
	return "."
end

--歃盟
local mobilezhishameng_skill = {}
mobilezhishameng_skill.name = "mobilezhishameng"
table.insert(sgs.ai_skills,mobilezhishameng_skill)
mobilezhishameng_skill.getTurnUseCard = function(self,inclusive)
	if self.player:getHandcardNum()>=2 and #self.friends_noself>0 then
		return sgs.Card_Parse("@MobileZhiShamengCard=.")
	end
end

sgs.ai_skill_use_func.MobileZhiShamengCard = function(card,use,self)
	local target
	self:sort(self.friends_noself)
	for _,p in ipairs(self.friends_noself)do
		if self:canDraw(p) and not p:isDead() then
			target = p
			break
		end
	end
	if not target then return end
	
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	
	local dis = {}
	
	for _,c in ipairs(cards)do
		local _dis = {}
		for _,c2 in ipairs(cards)do
			if c2:getEffectiveId()==c:getEffectiveId() then continue end
			if not c2:sameColorWith(c) then continue end
			table.insert(_dis,c)
			table.insert(_dis,c2)
			break
		end
		if #_dis==2 then
			table.insert(dis,_dis)
		end
	end
	if #dis==0 then return end
	
	local function keepvaluesort(t1,t2)
		local a = self:getKeepValue(t1[1])+self:getKeepValue(t1[2])
		local b = self:getKeepValue(t2[1])+self:getKeepValue(t2[2])
		return a<b
	end
	table.sort(dis,keepvaluesort)
	
	use.card = sgs.Card_Parse("@MobileZhiShamengCard="..dis[1][1]:getEffectiveId().."+"..dis[1][2]:getEffectiveId())
	use.to:append(target)
end

sgs.ai_use_priority.MobileZhiShamengCard = sgs.ai_use_priority.NosJujianCard
sgs.ai_card_intention.MobileZhiShamengCard = -80

--谏喻
local mobilezhijianyu_skill = {}
mobilezhijianyu_skill.name = "mobilezhijianyu"
table.insert(sgs.ai_skills,mobilezhijianyu_skill)
mobilezhijianyu_skill.getTurnUseCard = function(self,inclusive)
	if #self.enemies>0 then
		return sgs.Card_Parse("@MobileZhiJianyuCard=.")
	end
end

sgs.ai_skill_use_func.MobileZhiJianyuCard = function(card,use,self)
	if self.room:getAlivePlayers():length()==2 then
		use.card = card
		use.to:append(self.room:getAlivePlayers():first())
		use.to:append(self.room:getAlivePlayers():last())
		return
	end
	
	self:sort(self.enemies,"threat")
	self:sort(self.friends)
	
	for _,enemy in ipairs(self.enemies)do
		for _,friend in ipairs(self.friends)do
			if enemy:canSlash(friend) then
				use.card = card
				use.to:append(enemy)
				use.to:append(friend)
				return
			end
		end
	end
end

sgs.ai_use_priority.MobileZhiJianyuCard = 0

--生息
sgs.ai_skill_invoke.mobilezhishengxi = function(self,data)
	return self:canDraw()
end

--辅弼
sgs.ai_skill_playerchosen.mobilezhifubi = function(self,targets)
	if self.player:getRole()=="loyalist" and self.room:getLord() and targets:contains(self.room:getLord()) then
		return self.room:getLord()
	end
	
	local friends = {}
	for _,p in sgs.qlist(targets)do
		if p:isYourFriend(self.player) and p:getMark("&mobilezhifu")<=0 then  --作弊
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		self:sort(friends,"maxcards")
		return friends[1]
	end
	for _,p in sgs.qlist(targets)do
		if p:isYourFriend(self.player) then  --作弊
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		self:sort(friends,"maxcards")
		return friends[1]
	end
	return nil
end

--罪辞
sgs.ai_skill_invoke.mobilezhizuici = function(self,data)
	if self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<=1-self.player:getHp() then return true end
	return false
end

sgs.ai_skill_choice.mobilezhizuici = function(self,choices,data)
	return self:throwEquipArea(choices)
end

--二版辅弼
sgs.ai_skill_playerchosen.secondmobilezhifubi = function(self,targets)
	return sgs.ai_skill_playerchosen.mobilezhifubi(self,targets)
end

sgs.ai_skill_invoke.secondmobilezhifubi = function(self,data)
	local player = data:toPlayer()
	return self:isFriend(player)
end

sgs.ai_skill_choice.secondmobilezhifubi = function(self,choices,data)
	choices = choices:split("+")
	local player = data:toPlayer()
	if player:isSkipped(sgs.Player_Discard) then  --将会跳过弃牌阶段待补充
		if self:isFriend(player) then
			return "slash"
		else
			return "max"
		end
	end
	if player:canSlashWithoutCrossbow() then
		if self:isFriend(player) then
			return "max"
		else
			return "slash"
		end
	end
	local slash = dummyCard()
	if self:canUse(slash,self:getEnemies(player),player) and getCardsNum("Slash",player,self.player)>1 then
		if self:isFriend(player) then
			return "slash"
		else
			return "max"
		end
	end
	if self:getOverflow(player)>player:getMaxCards() then
		if self:isFriend(player) then
			return "max"
		else
			return "slash"
		end
	end
	if self:isFriend(player) then
		return "max"
	else
		return "slash"
	end
end

--二版罪辞
local secondmobilezhizuici_skill = {}
secondmobilezhizuici_skill.name = "secondmobilezhizuici"
table.insert(sgs.ai_skills,secondmobilezhizuici_skill)
secondmobilezhizuici_skill.getTurnUseCard = function(self,inclusive)
	if self:isWeak() and self.player:hasEquipArea() and not self.player:getEquips():isEmpty() then
		return sgs.Card_Parse("@SecondMobileZhiZuiciCard=.")
	end
end

sgs.ai_skill_use_func.SecondMobileZhiZuiciCard = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.SecondMobileZhiZuiciCard = 0

sgs.ai_skill_choice.secondmobilezhizuici = function(self,choices,data)
	return self:throwEquipArea(choices)
end

sgs.ai_skill_invoke.secondmobilezhizuici = function(self,data)
	return sgs.ai_skill_invoke.mobilezhizuici(self,data)
end

sgs.ai_skill_use["@@secondmobilezhizuici"] = function(self,prompt)
	local enemies = {}
	for _,enemy in ipairs(self.enemies)do
		if enemy:getMark("&mobilezhifu")>0 then
			table.insert(enemies,enemy)
		end
	end
	if #enemies>0 then
		self:sort(enemies,"maxcards")
		local friends = {}
		for _,friend in ipairs(self.friends)do
			if friend:getMark("&mobilezhifu")==0 then
				table.insert(friends,friend)
			end
		end
		if #friends>0 then
			self:sort(friends,"maxcards")
			return "@SecondMobileZhiZuiciMarkCard=.->"..enemies[1]:objectName().."+"..friends[1]:objectName()
		end
		self:sort(self.friends,"maxcards")
		return "@SecondMobileZhiZuiciMarkCard=.->"..enemies[1]:objectName().."+"..self.friends[1]:objectName()
	end
	
	--[[local friends = {}  --移友方标记待补充
	for _,friend in ipairs(self.friends)do
		if friend:getMark("&mobilezhifu")>0 then
			table.insert(friends,friend)
		end
	end
	if #friends>0 then
		self:sort(friends)
		
	end]]
	return "."
end

--夺冀
local mobilezhiduoji_skill = {}
mobilezhiduoji_skill.name = "mobilezhiduoji"
table.insert(sgs.ai_skills,mobilezhiduoji_skill)
mobilezhiduoji_skill.getTurnUseCard = function(self,inclusive)
	if self.player:getHandcardNum()<=2 then return end
	return sgs.Card_Parse("@MobileZhiDuojiCard=.")
end

sgs.ai_skill_use_func.MobileZhiDuojiCard = function(card,use,self)
	local cards = self:askForDiscard("dummyreason",2,2,false,false)
	if #cards~=2 then return end
	local enemies = {}
	self:sort(self.enemies,"equip")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies)do
		if self:doDisCard(p,"e",true) and p:getEquips():length()>=2 then
			sgs.ai_use_priority.MobileZhiDuojiCard = sgs.ai_use_priority.Slash+0.1
			use.card = sgs.Card_Parse("@MobileZhiDuojiCard="..cards[1].."+"..cards[2])
			use.to:append(p)
			return
		end
	end
	if self:getOverflow()>=2 then
		self:sort(self.friends_noself)
		for _,p in ipairs(self.friends_noself)do
			if p:getEquips():length()==1 and not (p:hasTreasure("wooden_ox") and not p:getPile("wooden_ox"):isEmpty()) then
				if self:doDisCard(p,"e",true) then
					use.card = sgs.Card_Parse("@MobileZhiDuojiCard="..cards[1].."+"..cards[2])
					use.to:append(p)
					return
				end
			end
		end
	end
end

sgs.ai_use_priority.MobileZhiDuojiCard = 1.6

addAiSkills("secondmobilezhiduoji").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
  	if #cards>1
	then
		return sgs.Card_Parse("@SecondMobileZhiDuojiCard="..cards[1]:getEffectiveId())
	end
end

sgs.ai_skill_use_func["SecondMobileZhiDuojiCard"] = function(card,use,self)
	self:sort(self.enemies,"handcard",true)
	for _,ep in sgs.list(self.enemies)do
		use.card = card
		use.to:append(ep)
		return
	end
	local tos = self.room:getOtherPlayers(self.player)
	tos = self:sort(tos,"handcard",true)
	for _,ep in sgs.list(tos)do
		if ep:isKongcheng() then continue end
		use.card = card
		use.to:append(ep)
		return
	end
	for _,ep in sgs.list(tos)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.SecondMobileZhiDuojiCard = 3.4
sgs.ai_use_priority.SecondMobileZhiDuojiCard = -4.8
sgs.ai_card_intention.SecondMobileZhiDuojiCard = 66

--谏战
local mobilezhijianzhan_skill = {}
mobilezhijianzhan_skill.name = "mobilezhijianzhan"
table.insert(sgs.ai_skills,mobilezhijianzhan_skill)
mobilezhijianzhan_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("@MobileZhiJianzhanCard=.")
end

sgs.ai_skill_use_func.MobileZhiJianzhanCard = function(card,use,self)
	local target
	local slash = dummyCard()
	slash:setSkillName("_mobilezhijianzhan")
	
	self:sort(self.friends_noself,"threat")
	self:sort(self.enemies,"defense")
	for _,friend in ipairs(self.friends_noself)do
		for _,enemy in ipairs(self.enemies)do
			if friend:canSlash(enemy,slash) and not self:slashProhibit(slash,enemy) and self:getDefenseSlash(enemy)<=2
			and self:isGoodTarget(enemy,self.enemies,slash) and enemy:objectName()~=self.player:objectName()
			and enemy:getHandcardNum()<friend:getHandcardNum() 
			then
				target = friend
				self.MobileZhiJianzhanTarget = enemy
				break
			end
		end
		if target then break end
	end

	if not target and self:canDraw() then
		self:sort(self.friends_noself,"defense")
		target = self.friends_noself[1]
	end

	if target then
		use.card = card
		use.to:append(target)
	end
end

sgs.ai_use_priority.MobileZhiJianzhanCard = sgs.ai_use_priority.Slash+0.05

sgs.ai_skill_choice.mobilezhijianzhan = function(self,choices,data)
	local from = data:toPlayer()
	if not self:isFriend(from) then return "draw" end
	local slash = dummyCard()
	slash:setSkillName("_mobilezhijianzhan")
	for _,enemy in ipairs(self.enemies)do
		if self.player:canSlash(enemy,slash) and not self:slashProhibit(slash,enemy) and self:getDefenseSlash(enemy)<=2
		and self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies)
		and enemy:getHandcardNum()<self.player:getHandcardNum() then
			return "slash"
		end
	end
	return "draw"
end

sgs.ai_skill_playerchosen.mobilezhijianzhan = function(self,targets)
	if self.MobileZhiJianzhanTarget then return self.MobileZhiJianzhanTarget end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self,targets)
end

--灭吴
local mobilezhimiewu = {}
mobilezhimiewu.name = "mobilezhimiewu"
table.insert(sgs.ai_skills,mobilezhimiewu)
mobilezhimiewu.getTurnUseCard = function(self)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards,nil,"l") -- 按保留值排序
	if #cards<1 then return end
    for _,name in sgs.list(patterns())do
        local card = dummyCard(name)
        if card and card:isAvailable(self.player)
       	and card:isDamageCard() then
			if self:getCardsNum(card:getClassName())>1 and #cards>1 then continue end
            card:setSkillName("mobilezhimiewu")
            card:addSubcard(cards[1])
         	local dummy = self:aiUseCard(card)
			if dummy.card
			then
				self.Miewudummy = dummy
				return sgs.Card_Parse("@MobileZhiMiewuCard="..cards[1]:getEffectiveId()..":"..name)
			end
		end
	end
    for _,name in sgs.list(patterns())do
        local card = dummyCard(name)
        if card and card:isAvailable(self.player) then
			if self:getCardsNum(card:getClassName())>1 and #cards>1 then continue end
            card:setSkillName("mobilezhimiewu")
            card:addSubcard(cards[1])
         	local dummy = self:aiUseCard(card)
			if dummy.card then
				self.Miewudummy = dummy
	           	if card:canRecast() and dummy.to:length()<1 then continue end
				return sgs.Card_Parse("@MobileZhiMiewuCard="..cards[1]:getEffectiveId()..":"..name)
			end
		end
	end
end

sgs.ai_skill_use_func.MobileZhiMiewuCard = function(card,use,self)
	use.card = card
	use.to = self.Miewudummy.to
end

sgs.ai_guhuo_card.mobilezhimiewu = function(self,toname,class_name)
    local cards = self:addHandPile("he")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	if #cards<1 or self:getCardsNum(class_name)>0 and #cards>1 then return end
   	return "@MobileZhiMiewuCard="..cards[1]:getEffectiveId()..":"..toname
end

sgs.ai_use_revises.mobilezhimiewu = function(self,card,use)
	if card:isKindOf("EquipCard")
	and self.player:getMark("&mobilezhiwuku")>2
	and self.player:getMark("mobilezhimiewu-Clear")<1
	then return false end
end






local mobilexinyinju={}
mobilexinyinju.name="mobilexinyinju"
table.insert(sgs.ai_skills,mobilexinyinju)
mobilexinyinju.getTurnUseCard = function(self)
	if self:getCardsNum("Jink")<1 and self.player:getMark("mobilexinchijie-Clear")>0
	then return end
	return sgs.Card_Parse("@MobileXinYinjuCard=.")
end

sgs.ai_skill_use_func["MobileXinYinjuCard"] = function(card,use,self)
	for _,ep in sgs.list(self.enemies)do
		if ep:canSlash(self.player,true) then continue end
		use.card = card
		use.to:append(ep)
		return
	end
	for _,ep in sgs.list(self.enemies)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.MobileXinYinjuCard = 3.4
sgs.ai_use_priority.MobileXinYinjuCard = 2.2
sgs.ai_card_intention.MobileXinYinjuCard = 66

sgs.ai_skill_invoke.mobilexinchijie = function(self,data)
	local use = data:toCardUse()
	if use.card:isDamageCard()
	or self:isEnemy(use.from)
	then return true end
end

local mobilexincunsi={}
mobilexincunsi.name="mobilexincunsi"
table.insert(sgs.ai_skills,mobilexincunsi)
mobilexincunsi.getTurnUseCard = function(self)
	if not self.player:faceUp() then return end
	return sgs.Card_Parse("@MobileXinCunsiCard=.")
end

sgs.ai_skill_use_func["MobileXinCunsiCard"] = function(card,use,self)
	for _,ep in sgs.list(self.enemies)do
		if self:isWeak(ep)
		and ep:getHandcardNum()<2
		then
			for _,fp in sgs.list(self.friends)do
				if fp:canSlash(ep)
				then
					if fp==self.player
					then
						if self:getCardsNum("Slash")>0
						then return end
					end
					use.card = card
					use.to:append(fp)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.MobileXinCunsiCard = 3.4
sgs.ai_use_priority.MobileXinCunsiCard = 2.8
sgs.ai_card_intention.MobileXinCunsiCard = 66

sgs.ai_skill_cardask.mobilexinguixiu = function(self,data,pattern,prompt)
    local parsed = prompt:split(":")
    if not self:isWeak(self.player)
	and not self.player:faceUp()
	then
    	if parsed[1]=="slash-jink"
		then
	    	parsed = data:toCardEffect()
			if self:canLoseHp(parsed.from,parsed.slash)
			then return false end
		else
	    	parsed = data:toCardEffect()
			local card = parsed.card
			if card and card:isDamageCard()
			and self:canLoseHp(parsed.from,parsed.card)
			then return false end
		end
	end
end

sgs.ai_nullification.mobilexinguixiu = function(self,trick,from,to,positive)
    if to:hasSkill("mobilexinguixiu")
	and self:isFriend(to)
	and to:getHp()>1
	and trick:isDamageCard()
	and self:canLoseHp(from,trick,to)
	and not to:faceUp()
	then return false end
end

sgs.ai_skill_invoke.secondmobilexinxuancun = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
	end
end

local mobilexinmouli={}
mobilexinmouli.name="mobilexinmouli"
table.insert(sgs.ai_skills,mobilexinmouli)
mobilexinmouli.getTurnUseCard = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	if #cards<1 then return end
	return sgs.Card_Parse("@MobileXinMouliCard="..cards[1]:getEffectiveId())
end

sgs.ai_skill_use_func["MobileXinMouliCard"] = function(card,use,self)
	for _,ep in sgs.list(self.friends_noself)do
		if self:isWeak(ep) then continue end
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.MobileXinMouliCard = 6.4
sgs.ai_use_priority.MobileXinMouliCard = 2.5
sgs.ai_card_intention.MobileXinMouliCard = -44

function sgs.ai_cardsview.mobilexinmouli_effect(self,class_name,player)
   	local cards = sgs.QList2Table(player:getCards("he"))
    self:sortByKeepValue(cards)
	if class_name=="Jink"
	then
		for _,card in sgs.list(cards)do
        	if card:isRed()
	    	then
	    		return ("jink:mobilexinmouli_effect[no_suit:0]="..card:getEffectiveId())
			end
		end
	end
	if class_name=="Slash"
	then
        for _,card in sgs.list(cards)do
        	if card:isBlack()
	    	then
	        	return ("slash:mobilexinmouli_effect[no_suit:0]="..card:getEffectiveId())
			end
		end
	end
end

sgs.ai_skill_invoke.secondmobilexinxingqi = function(self,data)
	local bei = self.player:property("second_mobilexin_wangling_bei"):toString():split("+")
	local cards = {}
	for cs,name in sgs.list(bei)do
		cs = PatternsCard(name,true)
		if #cs>1 then table.insert(cards,cs[1]) end
	end
	self:sortByKeepValue(cards,true)
	sgs.ai_skill_choice.secondmobilexinxingqi = cards[1]:objectName()
	return #cards>1
end

addAiSkills("secondmobilexinmouli").getTurnUseCard = function(self)
	local bei = self.player:property("second_mobilexin_wangling_bei"):toString():split("+")
	if #bei<2 then return end
	return sgs.Card_Parse("@SecondMobileXinMouliCard=.")
end

sgs.ai_skill_use_func["SecondMobileXinMouliCard"] = function(card,use,self)
	self:sort(self.friends_noself,"hp")
	for _,ep in sgs.list(self.friends_noself)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.SecondMobileXinMouliCard = 3.4
sgs.ai_use_priority.SecondMobileXinMouliCard = 6.2
sgs.ai_card_intention.SecondMobileXinMouliCard = -44

sgs.ai_skill_choice.secondmobilexinmouli = function(self,choices,data)
	local cards = {}
	local bei = choices:split("+")
	for cs,name in sgs.list(bei)do
		cs = PatternsCard(name,true)
		if #cs>1 then table.insert(cards,cs[1]) end
	end
	self:sortByKeepValue(cards,true)
	return #cards>1 and cards[1]:objectName() or bei[1]
end



addAiSkills("mobilexinchuhai").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileXinChuhaiCard=.")
end

sgs.ai_skill_use_func["MobileXinChuhaiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.MobileXinChuhaiCard = 3.4
sgs.ai_use_priority.MobileXinChuhaiCard = 5.2

sgs.ai_skill_playerchosen.mobilexinchuhai = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	return destlist[1]
end

addAiSkills("mobilexinlirang").getTurnUseCard = function(self)
	if self.player:getHandcardNum()<self.player:getHp()
	or self.player:getHandcardNum()>2
	or #self.friends_noself<1
	then return end
	return sgs.Card_Parse("@MobileXinLirangCard=.")
end

sgs.ai_skill_use_func["MobileXinLirangCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.MobileXinLirangCard = 3.4
sgs.ai_use_priority.MobileXinLirangCard = 5.2

sgs.ai_skill_askforyiji.mobilexinlirang = function(self,card_ids,tos)
    local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to and id then return to,id end
	to = self.friends_noself[1]
	return to,card_ids[1]
end

sgs.ai_skill_cardask["@mobilexinmingfa-show"] = function(self,data,pattern)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
   	for _,c in sgs.list(cards)do
    	if c:getNumber()>8
		then return c:getEffectiveId() end
	end
    return "."
end

sgs.ai_skill_playerchosen.mobilexinmingfa = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	return destlist[1]
end

addAiSkills("mobilexinrongbei").getTurnUseCard = function(self)
	if math.random()>0.8 then return end
	return sgs.Card_Parse("@MobileXinRongbeiCard=.")
end

sgs.ai_skill_use_func["MobileXinRongbeiCard"] = function(card,use,self)
	self:sort(self.friends,"equip")
	for _,ep in sgs.list(self.friends)do
		if ep:getEquips():length()>3 then continue end
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.MobileXinRongbeiCard = 6.4
sgs.ai_use_priority.MobileXinRongbeiCard = 7.2
sgs.ai_card_intention.MobileXinRongbeiCard = -44


sgs.ai_skill_playerchosen.mobilexinxunyi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[#destlist]
end





addAiSkills("mobilerenrenshi").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	if #cards<2 then return end
	return sgs.Card_Parse("@MobileRenRenshiCard="..cards[1]:getEffectiveId())
end

sgs.ai_skill_use_func["MobileRenRenshiCard"] = function(card,use,self)
	self:sort(self.friends_noself,"hp",true)
	for _,ep in sgs.list(self.friends_noself)do
		if ep:getMark("mobilerenrenshi-PlayClear")<1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.MobileRenRenshiCard = 2.4
sgs.ai_use_priority.MobileRenRenshiCard = 2.3
sgs.ai_card_intention.MobileRenRenshiCard = -44

sgs.ai_skill_discard["@mobilerensheyi-give"] = function(self,x,n)
	local cards = {}
	local damage = self.player:getTag("mobilerensheyi_data"):toDamage()
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if #cards>=n then break end
		if #handcards>n and self:isWeak(damage.to) and self:isFriend(damage.to)
		then table.insert(cards,h:getEffectiveId()) end
	end
	return cards
end

addAiSkills("mobilerenboming").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	if #cards<2 then return end
	return sgs.Card_Parse("@MobileRenBomingCard="..cards[1]:getEffectiveId())
end

sgs.ai_skill_use_func["MobileRenBomingCard"] = function(card,use,self)
	self:sort(self.friends_noself,"hand")
	local ejian_names = self.player:getTag("mobilerenejian_names"):toStringList()
	for _,ep in sgs.list(self.friends_noself)do
		if ep:getHandcardNum()<3
		or table.contains(ejian_names,ep:objectName())
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	self:sort(self.enemies,"hand",true)
	for _,ep in sgs.list(self.enemies)do
		if table.contains(ejian_names,ep:objectName()) then continue end
		if ep:getHandcardNum()>2
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.MobileRenBomingCard = 2.4
sgs.ai_use_priority.MobileRenBomingCard = 1.8

addAiSkills("mobilerenmuzhen").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local toids = {}
  	for _,c in sgs.list(cards)do
		local can
		if #cards>2
		then
			for _,ep in sgs.list(self.friends_noself)do
				if ep:hasEquip() then can = true end
			end
			if not can then continue end
			table.insert(toids,c:getEffectiveId())
			if #toids>1 then return sgs.Card_Parse("@MobileRenMuzhenCard="..table.concat(toids,"+")) end
		end
		if self.player:getMark("mobilerenmuzhen_put-PlayClear")<1
		and c:isKindOf("EquipCard")
		and #cards>1
		then
			local index = c:getRealCard():toEquipCard():location()
			for _,ep in sgs.list(self.friends_noself)do
				if ep:getEquip(index)==nil then can = true end
			end
			if not can then continue end
			return sgs.Card_Parse("@MobileRenMuzhenCard="..c:getEffectiveId())
		end
	end
end

sgs.ai_skill_use_func["MobileRenMuzhenCard"] = function(card,use,self)
	self:sort(self.friends_noself,"hp")
	for _,ep in sgs.list(self.friends_noself)do
		if ep:getHp()>=self.player:getHp()
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.MobileRenMuzhenCard = 9.4
sgs.ai_use_priority.MobileRenMuzhenCard = 3.8

sgs.ai_skill_playerchosen.mobilerenyaohu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
	self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_choice.mobilerenyaohu = function(self,choices)
	local items = choices:split("+")
	return items[1]
end

sgs.ai_target_revises.mobilerenyaohu = function(to,card,self)
	if card:isDamageCard() and self:isEnemy(to)
	and self.player:getMark("mobilerenyaohu_"..to:objectName().."-PlayClear")>0
	then
		local ds = self:askForDiscard("yaohu",2,2,false,true)
		if #ds<2 or self:getUseValue(card)<self:getKeepValue(sgs.Sanguosha:getCard(ds[1]))+self:getKeepValue(sgs.Sanguosha:getCard(ds[2]))
		then return true end
	end
end

sgs.ai_skill_discard["mobilerenyaohu"] = function(self,x,n)
	local cards = {}
    local hcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(hcards) -- 按保留值排序
   	for _,h in sgs.list(hcards)do
		if #cards>=n then break end
		table.insert(cards,h:getEffectiveId())
	end
	return cards
end





sgs.ai_skill_discard.mobileyongxizhan = function(self)
   	local target = self.room:getCurrent()
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if self:isFriend(target)
		then
			if h:getSuit()==2
			or h:getSuit()==0
			then
				table.insert(cards,h:getEffectiveId())
				break
			end
		else
			table.insert(cards,h:getEffectiveId())
			break
		end
	end
	return cards
end

addAiSkills("mobileyongjungong").getTurnUseCard = function(self)
	local toids = {}
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
    local n = self.player:getMark("&mobileyongjungong-Clear")
  	for _,c in sgs.list(cards)do
		if #toids>n or n<1 and not self:isWeak() then break end
		table.insert(toids,c:getEffectiveId())
	end
	local slash = dummyCard()
	slash:setSkillName("mobileyongjungong")
	slash = self:aiUseCard(slash)
	if slash.card and slash.to
	and slash.card:isAvailable(self.player)
	then
		self.mobileyongjungong_to=slash.to
		local ids = #toids>0 and table.concat(toids,"+") or "."
		if #toids>n or n<1 then return sgs.Card_Parse("@MobileYongJungongCard="..ids) end
	end
end

sgs.ai_skill_use_func["MobileYongJungongCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.MobileYongJungongCard = 2.4
sgs.ai_use_priority.MobileYongJungongCard = 2.8

sgs.ai_skill_use["@@mobileyongjungong!"] = function(self,prompt)
	local valid = {}
	for _,to in sgs.list(self.mobileyongjungong_to)do
		table.insert(valid,to:objectName())
	end
	if #valid>0
	then
    	return "@MobileYongJungongCard=->"..table.concat(valid,"+")
	end
end

sgs.ai_skill_invoke.mobileyongdengli = function(self,data)
	return true
end






sgs.ai_skill_use["@@mobileyanyajun1"] = function(self,prompt)
	local valid = nil
	local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"hp")
	for _,friend in sgs.list(destlist)do
		if valid then break end
		if self:isEnemy(friend)
		and self.player:canPindian(friend)
		then valid = friend:objectName() end
	end
	for _,friend in sgs.list(destlist)do
		if valid then break end
		if not self:isFriend(friend)
		and self.player:canPindian(friend)
		then valid = friend:objectName() end
	end
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local strs = self.player:property("MobileYanYajunIds"):toString():split("+")
	for _,h in sgs.list(cards)do
		if table.contains(strs,h:toString()) and h:getNumber()>9 and valid
		then return ("@MobileYanYajunCard="..h:getEffectiveId().."->"..valid) end
	end
end

sgs.ai_skill_use["@@mobileyanyajun2"] = function(self,prompt)
	local pdlist = self.player:getTag("mobileyanyajunForAI"):toIntList()
	for _,id in sgs.list(pdlist)do
		local c = sgs.Sanguosha:getCard(id)
		if c:isBlack() then
			return ("@MobileYanYajunPutCard="..id)
		end
	end
	return ("@MobileYanYajunPutCard="..pdlist:first())
end

addAiSkills("mobileyanzundi").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	if #cards<1 then return end
	return sgs.Card_Parse("@MobileYanZundiCard="..cards[1]:getEffectiveId())
end

sgs.ai_skill_use_func["MobileYanZundiCard"] = function(card,use,self)
	if #self.friends<1 then return end
	use.card = card
	self:sort(self.friends,"hp")
	use.to:append(self.friends[1])
end

sgs.ai_use_value.MobileYanZundiCard = 5.4
sgs.ai_use_priority.MobileYanZundiCard = 4.8
sgs.ai_card_intention.MobileYanZundiCard = -44

sgs.ai_skill_discard.mobileyandifei = function(self)
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
--		table.insert(cards,h:getEffectiveId())
	end
	return cards
end

addAiSkills("mobileyanyanjiao").getTurnUseCard = function(self)
	if self.player:getHandcardNum()<self.player:getMaxCards()
	or self.player:isKongcheng() then return end
	return sgs.Card_Parse("@MobileYanYanjiaoCard=.")
end

sgs.ai_skill_use_func["MobileYanYanjiaoCard"] = function(card,use,self)
	self:sort(self.friends_noself,"hp",true)
	for _,ep in sgs.list(self.friends_noself)do
		if ep:getHp()<2 then continue end
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.MobileYanYanjiaoCard = 3.4
sgs.ai_use_priority.MobileYanYanjiaoCard = 1.8
sgs.ai_card_intention.MobileYanYanjiaoCard = -44

sgs.ai_skill_choice.mobileyanyanjiao = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"club")
	then return "club" end
	if table.contains(items,"spade")
	then return "spade" end
end

sgs.ai_skill_invoke.mobileyanzhenting = function(self,data)
	local items = data:toString():split(":")
    local target = self.room:findPlayerByObjectName(items[2])
	if self:isFriend(target)
	then
		if string.find(items[4],"slash")
		then
	    	return self:isWeak(target)
			or self:getCardsNum("Jink","h")>0
			or self.player:getArmor()
		elseif string.find(items[4],"indulgence")
		then return target:getHandcardNum()>3
		elseif string.find(items[4],"supply_shortage")
		then return target:getHandcardNum()<3
		end
	end
end

addAiSkills("mobileyanjincui").getTurnUseCard = function(self)
	if #self.friends_noself>0
	and self:isWeak()
	then
		return sgs.Card_Parse("@MobileYanJincuiCard=.")
	end
end

sgs.ai_skill_use_func["@MobileYanJincuiCard"] = function(card,use,self)
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		local n = 0
		for i=1,#self.friends_noself do
			i = p:getNextAlive(i)
			if self:isFriend(i)
			and i~=self.player
			then n = n+1
			else break end
		end
		if #self.friends_noself-n<2
		and not self:isFriend(p)
		then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.MobileYanJincuiCard = 2.4
sgs.ai_use_priority.MobileYanJincuiCard = -4.8

addAiSkills("mobileyanshangyi").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	if #cards<3 then return end
	return sgs.Card_Parse("@MobileYanShangyiCard="..cards[1]:getEffectiveId())
end

sgs.ai_skill_use_func["MobileYanShangyiCard"] = function(card,use,self)
	self:sort(self.enemies,"handcard",true)
	for _,ep in sgs.list(self.enemies)do
		if ep:getHandcardNum()>self.player:getHandcardNum()
		or ep:getHandcardNum()>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.MobileYanShangyiCard = 9.4
sgs.ai_use_priority.MobileYanShangyiCard = 4.8
sgs.ai_card_intention.MobileYanShangyiCard = 44






addAiSkills("mobilemouzhiheng").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileMouZhihengCard=.")
end

sgs.ai_skill_use_func["MobileMouZhihengCard"] = function(card,use,self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	if self.player:getHp()<3 then
		local zcards = self.player:getCards("he")
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _,zcard in sgs.qlist(zcards)do
			if not isCard("Peach",zcard,self.player) and not isCard("ExNihilo",zcard,self.player) then
				local shouldUse = true
				if isCard("Slash",zcard,self.player) and not use_slash then
					local dummy_use = dummy()
					self:useBasicCard(zcard,dummy_use)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.qlist(dummy_use.to)do
								if p:getHp()<=1 then
									shouldUse = false
									if self.player:distanceTo(p)>1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length()>1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId()==sgs.Card_TypeTrick then
					local dummy_use = dummy()
					self:useTrickCard(zcard,dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId()==sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = dummy()
					self:useEquipCard(zcard,dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId()==keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp()==1 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards,zcard:getId()) end
			end
		end
	end

	if #unpreferedCards==0 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,card) then
					local dummy_use = dummy()
					self:useBasicCard(card,dummy_use)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num+1
					end
				end
				if not will_use then table.insert(unpreferedCards,card:getId()) end
			end
		end

		local num = self:getCardsNum("Jink")-1
		if self.player:getArmor() then num = num+1 end
		if num>0 then
			for _,card in ipairs(cards)do
				if card:isKindOf("Jink") and num>0 then
					table.insert(unpreferedCards,card:getId())
					num = num-1
				end
			end
		end
		for _,card in ipairs(cards)do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum()<3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card,self.player) or card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards,card:getId())
			elseif card:getTypeId()==sgs.Card_TypeTrick then
				local dummy_use = dummy()
				self:useTrickCard(card,dummy_use)
				if not dummy_use.card then table.insert(unpreferedCards,card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum()<3 then
			table.insert(unpreferedCards,self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards,self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards,self.player:getOffensiveHorse():getId())
		end
	end

	for index = #unpreferedCards,1,-1 do
		if sgs.Sanguosha:getCard(unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then
			table.removeOne(unpreferedCards,unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards,1,-1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then table.insert(use_cards,unpreferedCards[index]) end
	end

	if #use_cards>0 then
		use.card = sgs.Card_Parse("@MobileMouZhihengCard="..table.concat(use_cards,"+"))
		return
	end
end

sgs.ai_use_value.MobileMouZhihengCard = 6.4
sgs.ai_use_priority.MobileMouZhihengCard = sgs.ai_use_priority.ZhihengCard

--start
addAiSkills("mobilemouleiji").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileMouLeijiCard=.")
end

sgs.ai_skill_use_func["MobileMouLeijiCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if self:damageIsEffective(ep, sgs.DamageStruct_Thunder, self.player) and self:canDamage(ep,self.player,nil) then 
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_skill_invoke.mobilemouguidao = function(self, data)
	local damage = data:toDamage()
    if self:damageIsEffective(damage.to,damage.card,damage.from) and not self:needToLoseHp(damage.to, damage.from, damage.card) and (self:isWeak() or self.player:getMark("&mou_daobing") > 5) then return true end
	return false
end

sgs.ai_can_damagehp.mobilemouzongshi = function(self, from, card, to)
    if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0 and
        self:canLoseHp(from, card, to) then
        return self:isEnemy(from) and from:getMark("mobilemouzongshiUse") < 1 and from:getHandcardNum() > 3
    end
end

sgs.ai_skill_invoke.mobilemouwansha = function(self, data)
	local target = data:toPlayer()
	local has = self.player:getMark("mobilemouwanshaUp")>0
    if self:isEnemy(target) and target:getCardCount(has, has) > 1 and self:doDisCard(target, "h" or has and "hej", true) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.mobilemouwansha = function(self,player,promptlist)
	local dying = self.room:getCurrentDyingPlayer()
	if dying and promptlist[#promptlist]=="yes" then
		sgs.updateIntention(player,dying,80)
	end
end

sgs.ai_skill_cardchosen.mobilemouwansha = function(self,who,flags,method)
	if self.disabled_ids:length() > 0 then
		local has = self.player:getMark("mobilemouwanshaUp")>0
		if who:getCardCount(has, has) < 3 then
    		return -1
		end
	end
end


addAiSkills("mobilemouluanwu").getTurnUseCard = function(self)
	local good,bad = 0,0
	local lord = self.room:getLord()
	if lord and self.role~="rebel" and self:isWeak(lord) then return end
	for _,player in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if self:isWeak(player) then
			if self:isFriend(player) then bad = bad+1
			else good = good+1
			end
		end
	end
	if good==0 then return end

	for _,player in sgs.qlist(self.room:getOtherPlayers(self.player))do
		local hp = math.max(player:getHp(),1)
		if getCardsNum("Analeptic",player)>0 then
			if self:isFriend(player) then good = good+1.0/hp
			else bad = bad+1.0/hp
			end
		end

		local has_slash = (getCardsNum("Slash",player)>0)
		local can_slash = false
		if not can_slash then
			for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
				if player:distanceTo(p)<=player:getAttackRange() then can_slash = true break end
			end
		end
		if not has_slash or not can_slash then
			if self:isFriend(player) then good = good+math.max(getCardsNum("Peach",player),1)
			else bad = bad+math.max(getCardsNum("Peach",player),1)
			end
		end

		if getCardsNum("Jink",player)==0 then
			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill,player) then lost_value = player:getHp()/2 end
			local hp = math.max(player:getHp(),1)
			if self:isFriend(player) then bad = bad+(lost_value+1)/hp
			else good = good+(lost_value+1)/hp
			end
		end
	end

	if good>bad then return sgs.Card_Parse("@MobileMouLuanwuCard=.") end
end

sgs.ai_skill_use_func["MobileMouLuanwuCard"] = function(card,use,self)
	use.card = card
end

sgs.dynamic_value.damage_card.MobileMouLuanwuCard = true

sgs.ai_target_revises.mobilemouweimu = function(to,card)
	if card:isKindOf("TrickCard") and card:isBlack()
	then return true end
end

addAiSkills("mobilemouquhu").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileMouQuhuCard=.")
end


sgs.ai_skill_use_func.MobileMouQuhuCard = function(card,use,self)

	if #self.enemies==0 then return end
	self:sort(self.enemies,"handcard")
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)

	for _,enemy in sgs.list(self.enemies)do
		if enemy:getCardCount() > 0 and self:doDisCard(enemy, "he", true) then
			for _,enemy2 in sgs.list(self.enemies)do
				if (enemy:objectName()~=enemy2:objectName())
					and enemy2:getCardCount() > 0 and self:doDisCard(enemy2, "he", true) and self:damageIsEffective(enemy2, "N", enemy) then
					use.card = sgs.Card_Parse("@MobileMouQuhuCard="..cards[1]:getEffectiveId())
					use.to:append(enemy)
					use.to:append(enemy2)
					return
				end
			end
		end
	end
	for _,enemy in sgs.list(self.enemies)do
		if enemy:getCardCount() > 0 then
			for _,enemy2 in sgs.list(self.enemies)do
				if (enemy:objectName()~=enemy2:objectName())
					and enemy2:getCardCount() > 0 and self:damageIsEffective(enemy2, "N", enemy) then
					use.card = sgs.Card_Parse("@MobileMouQuhuCard="..cards[1]:getEffectiveId())
					use.to:append(enemy)
					use.to:append(enemy2)
					return
				end
			end
		end
	end
end

sgs.ai_choicemade_filter.cardUsed.MobileMouQuhuCard = function(self,player,carduse)
	sgs.ai_quhu_effect = true
end

sgs.ai_card_intention.MobileMouQuhuCard = 0
sgs.dynamic_value.control_card.MobileMouQuhuCard = true

sgs.ai_card_intention.MobileMouQuhuCard = function(self,card,from,to)
	sgs.updateIntentions(from,to,40)
end

sgs.ai_skill_discard.mobilemouquhu = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local toids = {}
	for i,c in sgs.list(cards)do
		table.insert(to_cards,c:getEffectiveId())
		if #to_cards>=3 or math.random() < 0.5 then break end
	end
 	return to_cards
end

sgs.ai_can_damagehp.mobilemoujieming = function(self,from,card,to)
	if self:isFriend(to)
	and self:canLoseHp(from,card,to)
	and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	then
		return self:canDraw(self.player)
	end
end

sgs.ai_skill_playerchosen.mobilemoujieming = function(self,targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets,"handcard")
	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:canDraw(p) and ZishuEffect(p)>0 then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:canDraw(p)  then
			return p
		end
	end

	return nil
end

sgs.ai_playerchosen_intention.mobilemoujieming = function(self,from,to)
	if self:canDraw(to) then
		sgs.updateIntention(from,to,-80)
	end
end

sgs.ai_skill_discard.mobilemoujieming = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to = self.player:getTag("mobilemoujieming_target"):toPlayer()
	if to and self:isFriend(to) then
		local toids = {}
		for i,c in sgs.list(cards)do
			if #to_cards>=to:getLostHp() then break end
			table.insert(to_cards,c:getEffectiveId())
		end
	end
 	return to_cards
end

--end

addAiSkills("mobilemouduanliang").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileMouDuanliangCard=.")
end

sgs.ai_skill_use_func["MobileMouDuanliangCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if ep:getHp()>=self.player:getHp()
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.MobileMouDuanliangCard = 3.4
sgs.ai_use_priority.MobileMouDuanliangCard = 5.8
sgs.ai_card_intention.MobileMouDuanliangCard = 66

sgs.ai_skill_playerchosen.mobilemoushipo = function(self,players)
	players = self:sort(players,"handcard")
    for _,target in sgs.list(players)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(players)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_use["@@mobilemoushipo"] = function(self,prompt)
	local valid,to = {},nil
	local tos = self.player:getAliveSiblings()
	tos = self:sort(tos,"hp")
    for _,p in sgs.list(tos)do
      	if self:isFriend(p)
		and p:getHandcardNum()<self.player:getHandcardNum()
    	then to = p:objectName() break end
	end
    for _,p in sgs.list(tos)do
      	if self:isFriend(p) and self:isWeak(p)
    	then to = p:objectName() break end
	end
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	local List = self.player:property("mobilemoushipo_card_ids"):toString():split("+")
	for _,h in sgs.list(cards)do
		if #valid>1 then break end
		if table.contains(List,h:getEffectiveId())
		then table.insert(valid,h:getEffectiveId()) end
	end
	if #valid<1 then return end
	return to and string.format("@MobileMouShipoCard=%s->%s",table.concat(valid,"+"),to)
end

sgs.ai_skill_invoke.mobilemoutieqi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end


--start


addAiSkills("mobilemouxingshang").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileMouXingshangCard=.")
end


sgs.ai_skill_use_func.MobileMouXingshangCard = function(card,use,self)
	self:sort(self.friends,"handcard")
	local n = 0
	for _, p in sgs.qlist(self.room:getAllPlayers(true)) do
		if p:isDead() then
			n = n + 1
		end
	end
	local x = math.max(math.min(n, 5), 2)
	for _, friend in ipairs(self.friends) do
		if (self:canDraw(friend, self.player) and not self:willSkipPlayPhase(friend) and (x > 2 or self.player:getMark("&mobilemouxingshang_song") > 4)) or (not friend:faceUp() and self:toTurnOver(friend,x,"mobilemouxingshang")) then
			use.card = sgs.Card_Parse("@MobileMouXingshangCard=.")
			use.to:append(friend)
			return
		end
	end
	if self.player:getMark("&mobilemouxingshang_song") > 4 then
		for _, friend in ipairs(self.friends) do
			if self:hasSkills(sgs.need_maxhp_skill, friend) and friend:getMaxHp() < 9 then
				use.card = sgs.Card_Parse("@MobileMouXingshangCard=.")
				use.to:append(friend)
				return
			end
		end
		if (n > 0 and math.random() < 0.5) or (self.player:getMark("&mobilemouxingshang_song") > 8 and n == 0) then
			use.card = sgs.Card_Parse("@MobileMouXingshangCard=.")
			use.to:append(self.player)
		end
	end

end

sgs.ai_use_priority.MobileMouXingshangCard = 2
sgs.ai_use_value.MobileMouXingshangCard = 3
sgs.ai_card_intention.MobileMouXingshangCard = -40

sgs.ai_skill_choice.mobilemouxingshang = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	local choice1 = getChoice(choices, "2mobilemouxingshang")
	if choice1 then
		local n = 0
		for _, p in sgs.qlist(self.room:getAllPlayers(true)) do
			if p:isDead() then
				n = n + 1
			end
		end
		local x = math.max(math.min(n, 5), 2)
		if target and self:isFriend(target) and (not target:faceUp() and self:toTurnOver(target,x,"mobilemouxingshang")) then
			return choice1
		end
	end
	if table.contains(items, "5mobilemouxingshang") then
		if target == self.player and (self.player:getMark("&mobilemouxingshang_song") > 5 or sgs.turncount < 3) then
			table.removeOne(items, "5mobilemouxingshang")
		end
	end
	return items[math.random(1, #items)]
end

sgs.ai_skill_choice.mobilemouxingshangZhuisi = function(self,choices,data)
	local items = choices:split("+")
	local filtereditems = choices:split("+")
	for _, p in sgs.qlist(self.room:getAllPlayers(true)) do
		if p:isDead() then
			if table.contains(filtereditems, "ZhuisiPlayer="..p:objectName()) then
				if self:hasSkills(sgs.bad_skills, p) then
					table.removeOne(filtereditems, "ZhuisiPlayer="..p:objectName())
				end
			end
		end
	end
	if #filtereditems > 0 then
		return filtereditems[math.random(1, #filtereditems)]	
	end
	return items[math.random(1, #items)]
end

addAiSkills("mobilemoufangzhu").getTurnUseCard = function(self)
	if self.player:getMark("&mobilemouxingshang_song") < 2 then return end
	return sgs.Card_Parse("@MobileMouFangzhuCard=.")
end


sgs.ai_skill_use_func.MobileMouFangzhuCard = function(card,use,self)

	if #self.enemies==0 then return end
	self:sort(self.enemies,"handcard")

	for _, enemy in ipairs(self.enemies) do
		use.card = sgs.Card_Parse("@MobileMouFangzhuCard=.")
		use.to:append(enemy)
		return
	end
end

sgs.ai_skill_choice.mobilemoufangzhu = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items, "3") then
        if not target:faceUp() then table.removeOne(items, "3") end
    end
	return items[math.random(1, #items)]
end

sgs.ai_use_priority.MobileMouFangzhuCard = 10
sgs.ai_use_value.MobileMouFangzhuCard = 3
sgs.ai_card_intention.MobileMouFangzhuCard = 80


addAiSkills("mobilemousongwei").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileMouSongweiCard=.")
end


sgs.ai_skill_use_func.MobileMouSongweiCard = function(card,use,self)

	if #self.enemies==0 then return end
	self:sort(self.enemies,"defense")

	for _,liege in sgs.qlist(self.room:getLieges("wei",self.player))do
		if liege and self:isEnemy(liege) and self:objectiveLevel(liege) > 3 then
			use.card = sgs.Card_Parse("@MobileMouSongweiCard=.")
			use.to:append(liege)
			return
		end
	end
end

sgs.ai_use_priority.MobileMouSongweiCard = 10
sgs.ai_use_value.MobileMouSongweiCard = 3

sgs.ai_skill_invoke.mobilemouqiaobian = function(self,data)
	local change = data:toInt()
	if change == tonumber(sgs.Player_Judge) then
		if self.player:getJudgingArea():length() > 0 and self.player:getHp()+self:getAllPeachNum()-1>0 then
			return true
		end
	elseif change == tonumber(sgs.Player_Draw) then
		if self:isWeak() then return math.random() < 0.5  end
		if sgs.ai_skill_invoke.mobilemouqiaobian(self, ToData(tonumber(sgs.Player_Play))) then return false end
			return true
	elseif change == tonumber(sgs.Player_Play) then
		local x = 0
		if self.player:getHandcardNum() > 6 then
			x  = self.player:getHandcardNum() - 6
		end
		if x > 2 then return false end
		if self.room:canMoveField("ej") then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.mobilemouqiaobian = function(self, targets)
	local js = self.player:getCards("j")
	js = self:sortByKeepValue(js)
	for _,j in sgs.list(js)do
		local i = j:getEffectiveId()
		if self:doDisCard(self.player,i,true) then
			for _,ep in sgs.list(self.enemies)do
				if self.player:canUse(j,ep,true)
				then return ep end
			end
		end
	end
end
sgs.ai_playerchosen_intention.mobilemouqiaobian = 40

sgs.ai_skill_playerchosen.mobilemouqiaobian_from = function(self,players)
    if sgs.ai_skill_invoke.peiqi(self,ToData())
	then
		for _,target in sgs.list(players)do
			if target:objectName()==self.peiqiData.from:objectName()
			then return target end
		end
	end
end

sgs.ai_skill_playerchosen.mobilemouqiaobian_to = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==self.peiqiData.to:objectName()
		then return target end
	end
end

sgs.ai_skill_cardchosen.mobilemouqiaobian = function(self,who,flags,method)
	for i,c in sgs.list(who:getCards(flags))do
		i = c:getEffectiveId()
		if i==self.peiqiData.cid
		then return i end
	end
end



sgs.ai_skill_cardask["mobilemougongqi0"] = function(self,data,pattern,target)
	return true
end


addAiSkills("mobilemoujiefan").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileMouJiefanCard=.")
end


sgs.ai_skill_use_func.MobileMouJiefanCard = function(card,use,self)
local target
	local use_value = 0
	local max_value = -10000
	local p_count = 0
	for _,friend in ipairs(self.friends)do
		use_value = 0
		local count = 0
		for _,p in sgs.qlist(self.room:getOtherPlayers(friend))do
			if p:inMyAttackRange(friend) then
				count = count+1
				if self:isFriend(p) then
					if self:canDraw(p, self.player) then use_value = use_value+1 end
				else
					if p:getWeapon() then
						use_value = use_value+1.2
					else
						if not self:canDraw(p, self.player) then use_value = use_value+p:getHandcardNum()/5 end
					end
				end
			end
		end
		if friend:objectName()==self.player:objectName() then p_count = count end
		use_value = use_value-friend:getHandcardNum()/2
		if use_value>max_value then
			max_value = use_value
			target = friend
		end
	end

	if (target and max_value>=self.player:aliveCount()/2) then
		use.card = card
		use.to:append(target)
		return
	end
	use.card = card
	use.to:append(self.player)
	return
end

sgs.ai_use_priority.MobileMouJiefanCard = 4
sgs.ai_card_intention.MobileMouJiefanCard = sgs.ai_card_intention.JiefanCard

sgs.ai_skill_choice.mobilemoujiefan = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	local getChoice = getChoice(choices, "mobilemoujiefan2")
	if table.contains(items, "beishui") then
		for _,enemy in ipairs(self.enemies) do
			if self:isWeak(enemy) and (self:damageMinusHp(enemy,1)>0 or math.random() < 0.4) then
				return "beishui"
			end
		end
	end
	if getChoice then return getChoice end
	return "mobilemoujiefan1"
end


--end





sgs.ai_skill_invoke.mobilemouliegong = function(self,data)
	local target = data:toPlayer()
	local record = self.player:getTag("MobileMouLiegongRecords"):toStringList()
	if target and #record>2 then return not self:isFriend(target) end
end

addAiSkills("mobilemoukeji").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,"j")
	if #cards<2 and self:isWeak() then return end
	local m = self.player:getMark("mobilemoukeji-PlayClear")
	local toids = self:isWeak() or #cards>2 and cards[1]:getEffectiveId() or "."
	if m<1 or m==1 and toids~="." or m>1 and toids=="."
	then
		return sgs.Card_Parse("@MobileMouKejiCard="..toids)
	end
end

sgs.ai_skill_use_func["MobileMouKejiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.MobileMouKejiCard = 9.4
sgs.ai_use_priority.MobileMouKejiCard = 2.8

sgs.ai_skill_invoke.mobilemouduojing = function(self,data)
	local target = data:toPlayer()
	if target and self.player:getHujia()>1
	and self:isEnemy(target)
	then
		return target:getHandcardNum()>0 or target:getArmor()
	end
end

sgs.ai_use_revises.mobilemouduojing = function(self,card,use)
	if card:isKindOf("Slash") and self.player:getHujia()>1
	then card:setFlags("Qinggang") end
end


sgs.ai_skill_discard.mobilemouxiayuan = function(self)
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	local target = self.room:getCurrent()
   	for _,h in sgs.list(handcards)do
		if #cards>1 then break end
		table.insert(cards,h:getEffectiveId())
	end
	return self:isEnemy(target) and cards or {}
end

sgs.ai_skill_playerchosen.mobilemoujieyue = function(self,players)
	players = self:sort(players,"card")
    for _,target in sgs.list(players)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(players)do
		if not self:isEnemy(target)
		then return target end
	end
end

--start

addAiSkills("mobilemouxianzhen").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileMouXianzhenCard=.")
end


sgs.ai_skill_use_func.MobileMouXianzhenCard = function(card,use,self)

	if #self.enemies==0 then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	self:sort(self.enemies,"handcard")
	local slashcount = self:getCardsNum("Slash")
	if slashcount>0  then
		local slash = self:getCard("Slash")
		assert(slash)
		self.player:setFlags("InfinityAttackRange")
		local dummy_use = self:aiUseCard(slash,dummy(true))
		self.player:setFlags("-InfinityAttackRange")
		if dummy_use.card and dummy_use.to:length() > 0 then
			local target
			for _,enemy in sgs.qlist(dummy_use.to) do
				if not self.player:inMyAttackRange(enemy) then
					target = enemy
					break
				end
			end
			if target then
				use.card = sgs.Card_Parse("@MobileMouXianzhenCard=.")
				if use.to then use.to:append(target) end
				return
			end
			for _,enemy in sgs.qlist(dummy_use.to) do
				use.card = sgs.Card_Parse("@MobileMouXianzhenCard=.")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		use.card = sgs.Card_Parse("@MobileMouXianzhenCard=.")
		use.to:append(enemy)
		return
	end
end

sgs.ai_use_priority.MobileMouXianzhenCard = 10
sgs.ai_use_value.MobileMouXianzhenCard = 3
sgs.ai_card_intention.MobileMouXianzhenCard = 80

sgs.ai_cardneed.mobilemouxianzhen = sgs.ai_cardneed.bignumber

sgs.ai_skill_invoke.mobilemouxianzhen = function(self, data)
    local target = data:toPlayer()
    if target and self:isEnemy(target) then
		return true
	end
	return false
end

sgs.ai_view_as.mobilemoujinjiu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("Analeptic") then
		return ("slash:mobilemoujinjiu[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_fill_skill.mobilemoujinjiu = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c)
		or not c:isKindOf("Analeptic")
		then continue end
		local dc = dummyCard()
		dc:setSkillName("mobilemoujinjiu")
		dc:addSubcard(c)
		if dc:isAvailable(self.player)
		then return dc end
	end
end

sgs.ai_ajustdamage_to.mobilemoujinjiu = function(self,from,to,card,nature)
	if card and card:isKindOf("Slash") and card:hasFlag("drank")
	then return -card:getTag("drank"):toInt() end
end

sgs.ai_skill_invoke.mobilemouqianxun = function(self,data)
	local effect = data:toCardEffect()
	if effect.card:isKindOf("Collateral") and self.player:getWeapon() then
		local victim = self.player:getTag("collateralVictim"):toPlayer()
		if victim and sgs.ai_skill_cardask["collateral-slash"](self,nil,nil,victim,effect.from)~="." then return false end
	end
	if self.player:getPhase()==sgs.Player_Judge then
		if effect.card:isKindOf("Lightning") and self:isWeak() and self:getCardsNum("Peach")+self:getCardsNum("Analeptic")>0 then return false end
		return true
	end
	local current = self.room:getCurrent()
	if current and self:isFriend(current) and effect.from and self:isFriend(effect.from) then return true end
	if effect.card:isKindOf("Duel") and sgs.ai_skill_cardask["duel-slash"](self,data,nil,effect.from)~="." then return false end
	if effect.card:isKindOf("AOE") and sgs.ai_skill_cardask.aoe(self,data,nil,effect.from,effect.card:objectName())~="." then return false end
	if self.player:getHandcardNum()<self:getLeastHandcardNum(self.player) then return true end
	local l_lim,u_lim = math.max(2,self:getLeastHandcardNum(self.player)),math.max(5,#self.friends)
	if u_lim<=l_lim then u_lim = l_lim+1 end
	return math.random(0,100)>=(self.player:getHandcardNum()-l_lim)/(u_lim-l_lim+1)*100
end

sgs.ai_skill_discard.mobilemouqianxun = function(self, discard_num, min_num, optional, include_equip)
	local target = self.room:getCurrent()
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
        if self:getKeepValue(card)<5 or not target or self:isFriend(target) then
		    table.insert(to_discard, card:getEffectiveId())
        end
		if #to_discard >= discard_num then
			break
		end
	end
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end

sgs.ai_skill_choice.mobilemouqianxun = function(self, choices, data)
    local items = choices:split("+")
	for _,name in sgs.list(RandomList(items))do
		local c = dummyCard(name)
		c:setSkillName("_mobilemouqianxun")
		local d = self:aiUseCard(c)
		self.mobilemouqianxun_use = d
		if d.card and d.to
		then return name end
	end
end

sgs.ai_skill_use["@@mobilemouqianxun"] = function(self,prompt)
    local dummy = self.mobilemouqianxun_use
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dummy.card:toString().."->"..table.concat(tos,"+")
    end
	return "."
end

sgs.ai_skill_invoke.mobilemouqianxun = true
sgs.ai_skill_invoke.mobilemoulianying = true
sgs.ai_skill_askforyiji.mobilemoulianying = function(self,card_ids,tos)
	return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
end

sgs.ai_skill_use["@@mobilemoujingce"] = function(self,prompt)
	local ids = {}
	local targets = {}
	for _,id in sgs.list(self.player:getPile("mobilemoujingce"))do
		table.insert(ids,id)
	end
	local alive = sgs.QList2Table(self.room:getAlivePlayers())
    for i = 1, 3 do
        local rand = math.random(1, #alive)
        table.insert(targets, alive[rand]:objectName())
    end
	return "@MobileMouJingceCard="..table.concat(ids,"+").."->"..table.concat(targets,"+")
end


addAiSkills("mobilemouganglie").getTurnUseCard = function(self)
	if #self.enemies==0 then return end
	return sgs.Card_Parse("@MobileMouGangLieCard=.")
end

sgs.ai_skill_use_func["MobileMouGangLieCard"] = function(card,use,self)
	self:sort(self.enemies,"defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("MobileMouGangLieDamaged"..self.player:objectName()) == 0 and enemy:getMark("MobileMouGangLieDamage"..self.player:objectName()) > 0 and not self:cantDamageMore(self.player, enemy) and self:isGoodTarget(enemy, self.enemies, nil) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("MobileMouGangLieDamaged"..self.player:objectName()) == 0 and enemy:getMark("MobileMouGangLieDamage"..self.player:objectName()) > 0 and (not self:cantDamageMore(self.player, enemy) or self:isWeak(enemy)) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_value.MobileMouGangLieCard = 8.4
sgs.ai_use_priority.MobileMouGangLieCard = 3

sgs.ai_can_damagehp.mobilemouganglie = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and from:getMark("MobileMouGangLieDamaged"..to:objectName()) == 0 and from:getMark("MobileMouGangLieDamage"..to:objectName()) == 0
	end
end

sgs.ai_skill_askforyiji.mobilemouqingjian = function(self,card_ids,tos)
	return sgs.ai_skill_askforyiji.mobilemouqingjian(self,card_ids,tos)
end

--end







addAiSkills("mobilemouyangwei").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileMouYangweiCard=.")
end

sgs.ai_skill_use_func["MobileMouYangweiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.MobileMouYangweiCard = 8.4
sgs.ai_use_priority.MobileMouYangweiCard = 5.8

--start
addAiSkills("mobilemoutiaoxin").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileMouTiaoxinCard=.")
end

sgs.ai_skill_use_func.MobileMouTiaoxinCard = function(card,use,self)
	local distance = use.DefHorse and 1 or 0
	local targets = {}
	for _,enemy in ipairs(self.enemies)do
		if self:doDisCard(enemy,"he") and self:isTiaoxinTarget(enemy)
		then table.insert(targets,enemy)
			if #targets>=self.player:getMark("&charge_num") then
				break
			end
		end
	end

	if #targets==0 then return end

	sgs.ai_use_priority.MobileMouTiaoxinCard = 8
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _,card in sgs.qlist(self.player:getCards("h"))do
			if card:isKindOf("Armor") and self:evaluateArmor(card)>3 then
				sgs.ai_use_priority.MobileMouTiaoxinCard = 5.9
				break
			end
		end
	end
	if #targets>0 then
		self:sort(targets,"defenseSlash")
		for i = 1, #targets, 1 do
			use.to:append(targets[i])
		end
		use.card = sgs.Card_Parse("@MobileMouTiaoxinCard=.")
	end
end

sgs.ai_card_intention.MobileMouTiaoxinCard = sgs.ai_card_intention.TiaoxinCard
sgs.ai_use_priority.MobileMouTiaoxinCard = sgs.ai_use_priority.TiaoxinCard

sgs.ai_skill_playerschosen.mobilemouzhiji = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if self:isEnemy(target)then
            selected:append(target)
            if selected:length()>=max then break end
        end
    end
    return selected
end


sgs.ai_skill_invoke.mobilemouyicong = true
sgs.ai_skill_invoke.mobilemouqiaomeng = true
sgs.ai_skill_cardchosen.mobilemouqiaomeng = function(self, who, flags)
	if self.player:getMark("&charge_num") < 2 then
		return -1
	end
	local cards = sgs.QList2Table(who:getCards(flags))
	self:sortByUseValue(cards, true)
	if self:isFriend(who) then
		if self:doDisCard(who,"hej")
		then return end
		return -1
	end
	return
end

sgs.ai_skill_invoke.mobilemouhuanshi = function(self,data)
	local judge = data:toJudge()

	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		if self:isFriend(judge.who) then
			local card_id = self:getRetrialCardId(cards,judge)
			if card_id~=-1 then return true end
		elseif self:isEnemy(judge.who) then
			for _,card in sgs.list(cards)do
				if judge:isGood(card) or self:isValuableCard(card) then return false end
			end
			return true
		end
	end
	return false
end

sgs.ai_skill_askforag.mobilemouhuanshi = function(self,card_ids)
	local cards = {}
	for _,id in sgs.list(card_ids)do
		table.insert(cards,sgs.Sanguosha:getCard(id))
	end
	local judge = self.player:getTag("mobilemouhuanshiJudge"):toJudge()

	local cmp = function(a,b)
		local a_keep_value,b_keep_value = sgs.ai_keep_value[a:getClassName()] or 0,sgs.ai_keep_value[b:getClassName()] or 0
		a_keep_value = a_keep_value+a:getNumber()/100
		b_keep_value = b_keep_value+b:getNumber()/100
		return a_keep_value<b_keep_value
	end

	local card_id = self:getRetrialCardId(cards,judge,false)
	if card_id~=-1 then return card_id end
	local valueless = {}
	for _,card in sgs.list(cards)do
		if not self:isValuableCard(card) then table.insert(valueless,card) end
	end
	if #valueless==0 then valueless = cards end
	table.sort(valueless,cmp)
	return valueless[1]:getEffectiveId()
end

function sgs.ai_cardneed.mobilemouhuanshi(to,card,self)
	for _,player in sgs.list(self.friends)do
		if self:getFinalRetrial(to)==1 then
			if self:willSkipDrawPhase(player) then
				return card:getSuit()==sgs.Card_Club and not self:hasSuit("club",true,to)
			end
			if self:willSkipPlayPhase(player) then
				return card:getSuit()==sgs.Card_Heart and not self:hasSuit("heart",true,to)
			end
		end
	end
end

sgs.ai_skill_playerschosen.mobilemouhongyuan = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if self:isFriend(target) and self:canDraw(target, self.player) then
            selected:append(target)
        end
    end
    return selected
end

sgs.ai_skill_playerchosen.mobilemoumingzhe = function(self,targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
	if xuLiMax(self.player) > 0 and self.player:getMark("&charge_num") < xuLiMax(self.player) then
		return self.player
	end
	for _,friend in ipairs(targets)do
		if self:isFriend(friend) and xuLiMax(friend) > 0 and friend:getMark("&charge_num") < xuLiMax(friend) then
            return friend
		end
	end
	return self.player
end

sgs.ai_ajustdamage_from.mobilemouwushuang = function(self, from, to, card, nature)
	if card and ((card:isKindOf("Slash")) or (card:isKindOf("Duel") and table.contains(self.room:getTag("MobileMouWushuang_"..card:toString()):toStringList(), to:objectName()))) and not card:hasFlag("mobilemouwushuangUse"..to:objectName()) then
		return 1
	end
end

sgs.ai_skill_invoke.mobilemouliyu = function(self,data)
	local to = data:toPlayer()
    if self:isFriend(to)
	then return self:doDisCard(to,"hej", true) or #self.enemies>0
	else return self:doDisCard(to,"hej", true) end
end

sgs.ai_skill_playerchosen.mobilemouliyu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
    duel:deleteLater()
    local dummy_use = self:aiUseCard(duel, dummy())
	if dummy_use.card and dummy_use.to:length() > 0 then
		for _,p in sgs.list(dummy_use.to)do
			return p
		end
	end
	return nil
end



--end



sgs.ai_skill_playerchosen.chengxiong = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"e")
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"he")
		then return target end
	end
end

sgs.ai_skill_invoke.wangzhuan = function(self,data)
	local tp = self.room:getCurrent()
	return not self:isFriend(tp) or self:isWeak()
end

addAiSkills("guli").getTurnUseCard = function(self)
	local dc = dummyCard()
	dc:setSkillName("guli")
	dc:addSubcards(self.player:handCards())
	dc:setFlags("Qinggang")
	return #self.toUse<2 and dc
end

sgs.ai_skill_invoke.guli = function(self,data)
	return self.player:getHandcardNum()<self.player:getMaxHp()/2
	and self.player:getHp()+self:getAllPeachNum()>1
end

sgs.ai_skill_invoke.yishihz = function(self,data)
	local tp = data:toPlayer()
	return self:isFriend(tp) or not self:isWeak(tp) and self:doDisCard(tp,"e",true)
end

addAiSkills("qishe").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards) -- 按保留值排序
   	for _,c in sgs.list(cards)do
		if c:isKindOf("EquipCard") then
			local dc = dummyCard("analeptic")
			dc:setSkillName("qishe")
			dc:addSubcard(c)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
end

function sgs.ai_cardsview.qishe(self,class_name,player)
	local cards = sgs.QList2Table(player:getCards("he"))
    self:sortByKeepValue(cards) -- 按保留值排序
   	for _,c in sgs.list(cards)do
		if c:isKindOf("EquipCard") then
			local dc = dummyCard("analeptic")
			dc:setSkillName("qishe")
			dc:addSubcard(c)
			if not self.player:isLocked(dc) then
				return dc:toString()
			end
		end
	end
end

sgs.ai_skill_playerschosen.cuizhen = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tos = {}
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target) and #tos<2
		then table.insert(tos,target) end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target) and #self.enemies<1
		and not table.contains(tos,target) and #tos<2
		then table.insert(tos,target) end
	end
	return tos
end

sgs.ai_skill_invoke.cuizhen = function(self,data)
	local tp = data:toPlayer()
	return self:isEnemy(tp) or not self:isFriend(tp) and #self.enemies<1
end

addAiSkills("zuoyou").getTurnUseCard = function(self)
	return sgs.Card_Parse("@ZuoyouCard=.")
end

sgs.ai_skill_use_func["ZuoyouCard"] = function(card,use,self)
	self:sort(self.friends)
	if self.player:getChangeSkillState("zuoyou")==1 then
		for _,p in sgs.list(self.friends)do
			if self:canDraw(p) then
				use.card = card
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if self:canDraw(p) and not self:isEnemy(p) and #self.enemies>1 then
				use.card = card
				use.to:append(p)
				return
			end
		end
	else
		for _,p in sgs.list(self.friends)do
			if p:canDiscard(p,"h") and p:getHujia()<4 then
				use.card = card
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if p:canDiscard(p,"h") and p:getHujia()<3 and not self:isEnemy(p) and #self.enemies>1 then
				use.card = card
				use.to:append(p)
				return
			end
		end
	end
end

sgs.ai_use_value.ZuoyouCard = 5.4
sgs.ai_use_priority.ZuoyouCard = 5.8
sgs.ai_card_intention.ZuoyouCard = -66

sgs.ai_skill_use["@@qlqingzheng"] = function(self,prompt)
	local ids = {}
	local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards) -- 按保留值排序
	local function compare_func(a,b)
		local na,nb = 0,0
		for _,h in sgs.list(handcards)do
			if h:getSuit()==a:getSuit() then
				na = na+1
			elseif h:getSuit()==b:getSuit() then
				nb = nb+1
			end
		end
		return na<nb
	end
	table.sort(handcards,compare_func)
	local sus = {}
	for _,h in sgs.list(handcards)do
		if #sus<2 and not table.contains(sus,h:getSuit()) then
			table.insert(sus,h:getSuit())
		end
	end
	if #sus>1 then
		for _,h in sgs.list(handcards)do
			if table.contains(sus,h:getSuit()) then
				table.insert(ids,h:getId())
			end
		end
		self:sort(self.enemies)
		for _,p in sgs.list(self.enemies)do
			if self:isWeak(p) or p:getHandcardNum()>0 then
				return "@QlQingzhengCard="..table.concat(ids,"+").."->"..p:objectName()
			end
		end
	end
end

addAiSkills("qljiushi").getTurnUseCard = function(self)
   	for _,c in sgs.list(self.player:getCards("he"))do
		if isCard("Analeptic",c,self.player) then
			return
		end
	end
	local dc = dummyCard("analeptic")
	dc:setSkillName("qljiushi")
	return dc
end

function sgs.ai_cardsview.qljiushi(self,class_name,player)
   	for _,c in sgs.list(player:getCards("he"))do
		if isCard(class_name,c,player) then
			return
		end
	end
	local dc = dummyCard("analeptic")
	dc:setSkillName("qljiushi")
	return dc:toString()
end

sgs.ai_skill_invoke.qljiushi = function(self,data)
	return true
end

addAiSkills("qlfangzhu").getTurnUseCard = function(self)
	return sgs.Card_Parse("@QlFangzhuCard=.")
end

sgs.ai_skill_use_func["QlFangzhuCard"] = function(card,use,self)
	self:sort(self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		if p:getMark("&qlfangzhu-SelfClear")<1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>2 then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.QlFangzhuCard = 8.4
sgs.ai_use_priority.QlFangzhuCard = 5.8
sgs.ai_card_intention.QlFangzhuCard = 66

sgs.ai_skill_choice.qlfangzhu = function(self,choices,data)
	local items = choices:split("+")
	local to = data:toPlayer()
	if table.contains(items,"qlfangzhu1")
	and to:getMark("&qlfangzhu-SelfClear")<1
	then return "qlfangzhu1" end
	if table.contains(items,"qlfangzhu2")
	and to:getHandcardNum()>2
	then return "qlfangzhu2" end
end

addAiSkills("qljuejin").getTurnUseCard = function(self)
	return sgs.Card_Parse("@QlJuejinCard=.")
end

sgs.ai_skill_use_func["QlJuejinCard"] = function(card,use,self)
	local n = 0
	for _,p in sgs.list(self.enemies)do
		if self:isWeak(p) then
			n = n+1
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if self:isWeak(p) then
			n = n-1
		end
	end
	if n>0 then
		use.card = card
	end
end

sgs.ai_use_value.QlJuejinCard = 4.4
sgs.ai_use_priority.QlJuejinCard = 5.8

sgs.ai_use_revises.qljuejin = function(self,card,use)
	if (card:isKindOf("Peach") or card:isKindOf("Analeptic"))
	and self.player:getMark("@qljuejin")>0
	and self.player:hasCard(card) then
		local n = 0
		for _,p in sgs.list(self.enemies)do
			if self:isWeak(p) then
				n = n+1
			end
		end
		for _,p in sgs.list(self.friends_noself)do
			if self:isWeak(p) then
				n = n-1
			end
		end
		if n>0 then
			use.card = card
			return true
		end
	end
end

sgs.ai_card_priority.qljuejin = function(self,card,v)
	if (card:isKindOf("Peach") or card:isKindOf("Analeptic"))
	and self.player:getMark("@qljuejin")>0
	and self.player:hasCard(card) then
		local n = 0
		for _,p in sgs.list(self.enemies)do
			if self:isWeak(p) then
				n = n+1
			end
		end
		for _,p in sgs.list(self.friends_noself)do
			if self:isWeak(p) then
				n = n-1
			end
		end
		if n>0 then
			return 9
		end
	end
end

addAiSkills("xiongshi").getTurnUseCard = function(self)
	local ids = sgs.QList2Table(self.player:handCards())
	return sgs.Card_Parse("@XiongshiCard="..table.concat(ids,"+"))
end

sgs.ai_skill_use_func["XiongshiCard"] = function(card,use,self)
	local n = 0
	for _,p in sgs.list(self.enemies)do
		if self:isWeak(p) then
			n = n+1
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if self:isWeak(p) then
			n = n-1
		end
	end
	if n>0 then
		for _,p in sgs.list(self.friends_noself)do
			if p:isLord() and p:getHp()<2 and self:getAllPeachNum()<1 then
				return
			end
		end
		use.card = card
	end
end

sgs.ai_use_value.XiongshiCard = 2.4
sgs.ai_use_priority.XiongshiCard = 5.8

sgs.ai_skill_invoke.panxiang = function(self,data)
	local tp = data:toString()
	local damage = self.player:getTag("panxiangData"):toDamage()
	if tp:contains("1") then
		if not self:isEnemy(damage.to) then
			return self:isWeak(damage.to) or not damage.from or not self:isEnemy(damage.from)
		else
			return not self:isWeak(damage.to) and damage.from and self:isFriend(damage.from)
		end
	elseif tp:contains("2") then
		if self:isEnemy(damage.to) then
			return self:isWeak(damage.to)
		elseif damage.damage<2 then
			return not self:isWeak(damage.to)
		end
	else
		if self:isEnemy(damage.to) then
			return self:isWeak(damage.to)
		elseif self:isFriend(damage.to) then
			return self:isWeak(damage.to) or not damage.from or not self:isEnemy(damage.from)
		end
	end
end

function sgs.ai_cardsview.zhujin(self,class_name,player)
	local cards = sgs.QList2Table(player:getCards("he"))
   	for _,c in sgs.list(cards)do
		if isCard(class_name,c,player) then
			return
		end
	end
    self:sortByKeepValue(cards) -- 按保留值排序
   	for _,c in sgs.list(cards)do
		if c:isKindOf("BasicCard") then
			local dc = dummyCard(patterns(class_name))
			dc:setSkillName("zhujin")
			dc:addSubcard(c)
			if not self.player:isLocked(dc) then
				return dc:toString()
			end
		end
	end
end

addAiSkills("zhujin").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
   	for _,c in sgs.list(cards)do
		if isCard("Slash",c,self.player) then
			return
		end
	end
    self:sortByKeepValue(cards) -- 按保留值排序
   	for _,c in sgs.list(cards)do
		if c:isKindOf("BasicCard") then
			local dc = dummyCard()
			dc:setSkillName("zhujin")
			dc:addSubcard(c)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
end

sgs.ai_skill_askforyiji.jiejian = function(self,card_ids,targets)
	if #card_ids<self.player:getHandcardNum()/2 then return nil,-1 end
	return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,targets)
end

sgs.ai_skill_invoke.jiejian = function(self,data)
	local use = data:toCardUse()
	if use and use.card then
		if self:isFriend(use.to:first()) then
			if not self:isFriend(use.from) then
				if use.card:isDamageCard() and self:isWeak(use.to:first()) then
					return true
				end
				return not self:isWeak()
			end
		else
			return use.to:first()==use.from
			or self:isFriend(use.from,use.to:first())
		end
	else
		local ids = sgs.QList2Table(self.player:handCards())
		local target,cid = sgs.ai_skill_askforyiji.nosyiji(self,ids,self.room:getOtherPlayers(self.player))
		if target and cid then return true end
	end
end






addAiSkills("cstaoluan").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	if cards:length()<2 then return end
	cards = self:sortByKeepValue(cards)
	local dcs = {}
  	for _,pn in sgs.list(patterns())do
		local dc = dummyCard(pn)
		dc:setSkillName("cstaoluan")
		if (dc:isKindOf("BasicCard") or dc:isNDTrick()) and self:getCardsNum(dc:getClassName())<1 then
			table.insert(dcs,dc)
		end
	end
	self:sortByUseValue(dcs)
  	for _,dc in sgs.list(dcs)do
		if dc:isDamageCard() then
			for _,c in sgs.list(cards)do
				dc:addSubcard(c)
				if dc:isAvailable(self.player) and self:aiUseCard(dc).card then
					return dc
				end
				dc:clearSubcards()
			end
		end
	end
  	for _,dc in sgs.list(dcs)do
		for _,c in sgs.list(cards)do
			dc:addSubcard(c)
			if dc:isAvailable(self.player) and self:aiUseCard(dc).card then
				return dc
			end
			dc:clearSubcards()
		end
	end
end

sgs.ai_skill_invoke.cschiyan = function(self,data)
	local tp = data:toPlayer()
	return self:isEnemy(tp) or not self:isFriend(tp) and #self.enemies<1
end

addAiSkills("cspicai").getTurnUseCard = function(self)
	return sgs.Card_Parse("@CsPicaiCard=.")
end

sgs.ai_skill_use_func["CsPicaiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.CsPicaiCard = 9.4
sgs.ai_use_priority.CsPicaiCard = 5.8

sgs.ai_skill_invoke.cspicai = function(self,data)
	return true
end

sgs.ai_skill_playerchosen.cspicai = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

addAiSkills("csyaozhuo").getTurnUseCard = function(self)
	return sgs.Card_Parse("@CsYaozhuoCard=.")
end

sgs.ai_skill_use_func["CsYaozhuoCard"] = function(card,use,self)
	local mc = self:getMaxCard()
	if mc and mc:getNumber()>9 then else return end
	self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.CsYaozhuoCard = 1.4
sgs.ai_use_priority.CsYaozhuoCard = 5.8
sgs.ai_card_intention.CsYaozhuoCard = 50

addAiSkills("csxiaolu").getTurnUseCard = function(self)
	return sgs.Card_Parse("@CsXiaoluCard=.")
end

sgs.ai_skill_use_func["CsXiaoluCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.CsXiaoluCard = 9.4
sgs.ai_use_priority.CsXiaoluCard = 5.8

sgs.ai_skill_use["@@csxiaolu!"] = function(self,prompt)
	local valid,to = {},nil
	local tos = self.player:getAliveSiblings()
	tos = self:sort(tos,"hp")
    for _,p in sgs.list(tos)do
      	if self:isFriend(p)
		and p:getHandcardNum()<self.player:getHandcardNum()
    	then to = p:objectName() break end
	end
    for _,p in sgs.list(tos)do
      	if self:isFriend(p) and self:isWeak(p)
    	then to = p:objectName() break end
	end
    local cards = self.player:getCards("he")
    cards = self:sortByUseValue(cards,false) -- 按保留值排序
	for i,h in sgs.list(cards)do
		if #valid>1 then break end
		table.insert(valid,h:getEffectiveId())
	end
	if #valid<1 then return end
	return to and string.format("@CsXiaolu2Card=%s->%s",table.concat(valid,"+"),to)
end

local cskuiji_skill = {}
cskuiji_skill.name = "cskuiji"
table.insert(sgs.ai_skills,cskuiji_skill)
cskuiji_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("@CsKuijiCard=.")
end

sgs.ai_skill_use_func.CsKuijiCard = function(card,use,self)
	if #self.enemies<=0 then return end
	local target = nil
	self:sort(self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self:doDisCard(p,"h")
		then target = p	break end
	end
	if not target then return end
	self.cskuiji_target = nil
	if target:getHandcardNum()>0 then
		use.card = card
		self.cskuiji_target = target
		use.to:append(target)
	end
end

sgs.ai_skill_use["@@cskuiji"] = function(self,prompt)
	if self.cskuiji_target then
		local target_handcards = sgs.QList2Table(self.cskuiji_target:getCards("h"))
		self:sortByUseValue(target_handcards,inverse)
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		local discard_cards = {}
		local spade_check = true
		local heart_check = true
		local club_check = true
		local diamond_check = true
		local target_discard_count = 0
		
		for _,c in sgs.list(target_handcards)do
			if spade_check and c:getSuit()==sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards,c:getEffectiveId())
			elseif heart_check and c:getSuit()==sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards,c:getEffectiveId())
			elseif club_check and c:getSuit()==sgs.Card_Club then
				club_check = false
				table.insert(discard_cards,c:getEffectiveId())
			elseif diamond_check and c:getSuit()==sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards,c:getEffectiveId())
			end
			target_discard_count = #discard_cards
		end
		
		for _,c in sgs.list(handcards)do
			if not c:isKindOf("Peach")
			and not c:isKindOf("Duel")
			and not c:isKindOf("Indulgence")
			and not c:isKindOf("SupplyShortage")
			and not (self:getCardsNum("Jink")==1 and c:isKindOf("Jink"))
			and not (self:getCardsNum("Analeptic")==1 and c:isKindOf("Analeptic")) then
				if spade_check and c:getSuit()==sgs.Card_Spade then
					spade_check = false
					table.insert(discard_cards,c:getEffectiveId())
				elseif heart_check and c:getSuit()==sgs.Card_Heart then
					heart_check = false
					table.insert(discard_cards,c:getEffectiveId())
				elseif club_check and c:getSuit()==sgs.Card_Club then
					club_check = false
					table.insert(discard_cards,c:getEffectiveId())
				elseif diamond_check and c:getSuit()==sgs.Card_Diamond then
					diamond_check = false
					table.insert(discard_cards,c:getEffectiveId())
				end
			end
		end
		if #discard_cards==4 and target_discard_count>1 then
			return "@CsKuijiDisCard="..table.concat(discard_cards,"+")
		end
	end
	return "."
end

sgs.ai_use_priority.PoxiCard = 3
sgs.ai_use_value.PoxiCard = 3
sgs.ai_card_intention.PoxiCard = 50

sgs.ai_skill_invoke.cschihe = function(self,data)
	local tp = data:toPlayer()
	return self:isEnemy(tp) or not self:isFriend(tp) and #self.enemies<1
end


addAiSkills("csniqu").getTurnUseCard = function(self)
	return sgs.Card_Parse("@CsNiquCard=.")
end

sgs.ai_skill_use_func["CsNiquCard"] = function(card,use,self)
	self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
		if self:damageIsEffective(p,"F") then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.CsNiquCard = 3.4
sgs.ai_use_priority.CsNiquCard = 5.8
sgs.ai_card_intention.CsNiquCard = 66

local csmiaoyu_skill = {}
csmiaoyu_skill.name = "csmiaoyu"
table.insert(sgs.ai_skills,csmiaoyu_skill)
csmiaoyu_skill.getTurnUseCard = function(self,inclusive)
	local usable_cards = self:addHandPile()
	local equips = sgs.QList2Table(self.player:getCards("e"))
	for _,e in sgs.list(equips)do
		if e:isKindOf("DefensiveHorse") or e:isKindOf("OffensiveHorse") then
			table.insert(usable_cards,e)
		end
	end
	self:sortByUseValue(usable_cards,true)
	local two_diamond_cards = {}
	for _,c in sgs.list(usable_cards)do
		if c:getSuit()==sgs.Card_Diamond and #two_diamond_cards<2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>0) then
			table.insert(two_diamond_cards,c:getEffectiveId())
		end
	end
	if #two_diamond_cards==2 and self:slashIsAvailable() and self:getOverflow()>1 then
		return sgs.Card_Parse(("fire_slash:csmiaoyu[%s:%s]=%d+%d"):format("to_be_decided",0,two_diamond_cards[1],two_diamond_cards[2]))
	end
	for _,c in sgs.list(usable_cards)do
		if c:getSuit()==sgs.Card_Diamond and self:slashIsAvailable() and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink")<3) and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>0) then
			return sgs.Card_Parse(("fire_slash:csmiaoyu[%s:%s]=%d"):format(c:getSuitString(),c:getNumberString(),c:getEffectiveId()))
		end
	end
	for _,c in sgs.list(usable_cards)do
		if c:getSuit()==sgs.Card_Heart and self.player:getMark("Global_PreventPeach")==0 and not c:isKindOf("Peach") then
			return sgs.Card_Parse(("peach:csmiaoyu[%s:%s]=%d"):format(c:getSuitString(),c:getNumberString(),c:getEffectiveId()))
		end
	end
end

sgs.ai_view_as.csmiaoyu = function(card,player,card_place,class_name)
	if card_place==sgs.Player_PlaceSpecial then return end
	local usable_cards = sgs.QList2Table(player:getCards("he"))
	for _,id in sgs.list(player:getHandPile())do
		table.insert(usable_cards,sgs.Sanguosha:getCard(id))
	end
	local two_club_cards = {}
	local two_heart_cards = {}
	for _,c in sgs.list(usable_cards)do
		if c:getSuit()==sgs.Card_Club and #two_club_cards<2 then
			table.insert(two_club_cards,c:getEffectiveId())
		elseif c:getSuit()==sgs.Card_Heart and #two_heart_cards<2 then
			table.insert(two_heart_cards,c:getEffectiveId())
		end
	end
	
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	
	local current = player:getRoom():getCurrent()
	if #two_club_cards==2 and current and not current:isNude() and current:getWeapon() and current:getWeapon():isKindOf("Crossbow") then
		return ("jink:csmiaoyu[%s:%s]=%d+%d"):format("to_be_decided",0,two_club_cards[1],two_club_cards[2])
	elseif card:getSuit()==sgs.Card_Club then
		return ("jink:csmiaoyu[%s:%s]=%d"):format(suit,number,card_id)
	end
	
	if card:getSuit()==sgs.Card_Heart then
		return ("peach:csmiaoyu[%s:%s]=%d"):format(suit,number,card_id)
	end
	
	if card:getSuit()==sgs.Card_Diamond and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length()>0) then
		return ("fire_slash:csmiaoyu[%s:%s]=%d"):format(suit,number,card_id)
	elseif card:getSuit()==sgs.Card_Spade then
		return ("nullification:csmiaoyu[%s:%s]=%d"):format(suit,number,card_id)
	end
end

sgs.csmiaoyu_suit_value = sgs.longhun_suit_value

function sgs.ai_cardneed.csmiaoyu(to,card,self)
	if to:getCardCount()>3 then return false end
	if to:isNude() then return true end
	return card:getSuit()==sgs.Card_Heart or card:getSuit()==sgs.Card_Spade
end

sgs.ai_need_damaged.csmiaoyu = function(self,attacker,player)
	if player:getHp()>1 and player:hasSkill("newjuejing") then return true end
end

addAiSkills("poxiang").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	cards = self:sortByUseValue(cards,true)
	return #cards>0 and sgs.Card_Parse("@PoxiangCard="..cards[1]:getEffectiveId())
end

sgs.ai_skill_use_func["PoxiangCard"] = function(card,use,self)
	if self.player:getHp()>1 or self.player:getHp()+self:getAllPeachNum()>1 then
		local n = 0
		for _,id in sgs.list(self.player:getPile("jue_yong"))do
			local use = self.player:getTag("jueyong"..id):toCardUse()
			if use.from and use.from:isAlive() and not self:isFriend(use.from) then
				n = n+1
			else
				n = n-1
			end
		end
		if n<-1 then return end
		self:sort(self.friends_noself)
		for _,p in sgs.list(self.friends_noself)do
			if not hasManjuanEffect(p) then
				use.card = card
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.list(self.enemies)do
			if hasManjuanEffect(p) then
				use.card = card
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if p~=self.player and not self:isEnemy(p) then
				use.card = card
				use.to:append(p)
				return
			end
		end
	end
end

sgs.ai_use_value.PoxiangCard = 5.4
sgs.ai_use_priority.PoxiangCard = 11.8
sgs.ai_card_intention.PoxiangCard = -66

addAiSkills("zhujian").getTurnUseCard = function(self)
	return sgs.Card_Parse("@ZhujianCard=.")
end

sgs.ai_skill_use_func["ZhujianCard"] = function(card,use,self)
	self:sort(self.friends)
    for _,p in sgs.list(self.friends)do
		if p:hasEquip() and not hasManjuanEffect(p) then
			use.to:append(p)
			if use.to:length()>1 then
				use.card = card
			end
		end
	end
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if use.to:length()<#self.friends and not use.to:contains(p)
		and not self:isEnemy(p) and p:hasEquip() then
			use.to:append(p)
			if use.to:length()>1 then
				use.card = card
			end
		end
	end
end

sgs.ai_use_value.ZhujianCard = 5.4
sgs.ai_use_priority.ZhujianCard = 5.8
sgs.ai_card_intention.ZhujianCard = -66


addAiSkills("duansuo").getTurnUseCard = function(self)
	return sgs.Card_Parse("@DuansuoCard=.")
end

sgs.ai_skill_use_func["DuansuoCard"] = function(card,use,self)
	self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
		if p:isChained() and self:damageIsEffective(p,"F") then
			use.to:append(p)
			use.card = card
		end
	end
end

sgs.ai_use_value.DuansuoCard = 1.4
sgs.ai_use_priority.DuansuoCard = 1.8
sgs.ai_card_intention.DuansuoCard = 66

addAiSkills("buxu").getTurnUseCard = function(self)
	if self:getRestCardsNum("ExNihilo")<1 or self:getRestCardsNum("Indulgence")<1 then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards<2 then return end
	cards = self:sortByKeepValue(cards)
	local ids = {}
	local n = self.player:usedTimes("BuxuCard")
    for _,c in sgs.list(cards)do
		table.insert(ids,c:getId())
		if #ids>n or #ids>2
		then break end
	end
	return #ids>n and sgs.Card_Parse("@BuxuCard="..table.concat(ids,"+"))
end

sgs.ai_skill_use_func["BuxuCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.BuxuCard = 2.4
sgs.ai_use_priority.BuxuCard = 0.8
sgs.ai_card_intention.BuxuCard = -66

sgs.ai_skill_invoke.mingcha = function(self,data)
	local n = data:toInt()
	return n>1
end

sgs.ai_skill_playerchosen.mingcha = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		and self:doDisCard(p,"he",true)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		and p:getCardCount()>0
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		and p:getCardCount()>0
		then return p end
	end
end

sgs.ai_skill_playerchosen.jingzhong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p)
		and i<#destlist/2
		then return p end
	end
    for _,p in sgs.list(destlist)do
		return p
	end
end


sgs.ai_skill_playerschosen.beiming = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tos = {}
    for i,p in sgs.list(destlist)do
		if self:isFriend(p) and #tos<2
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if not self:isEnemy(p) and #tos<2
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_invoke.choumang = function(self,data)
	local use = data:toCardUse()
	if use.to:contains(self.player) then
		return not self:isFriend(use.from) and self:getCardsNum("Jink")>0
	else
		return not self:isFriend(use.to:first())
	end
end

sgs.ai_skill_choice.choumang = function(self,choices,data)
	local items = choices:split("+")
	local use = data:toCardUse()
	local to = use.to:first()
	if to==self.player then
		if table.contains(items,"choumang3") and self:getCardsNum("Jink")>0 then
			local w = self.player:getWeapon()
			if w then
				if #self:poisonCards({w})>0 then
					return "choumang3"
				end
			else
				w = to:getWeapon()
				if w and #self:poisonCards({w},to)<1 then
					return "choumang3"
				end
			end
		end
		if table.contains(items,"choumang2") then
			return "choumang2"
		end
	else
		if table.contains(items,"choumang3") then
			local w = self.player:getWeapon()
			if w then
				if #self:poisonCards({w})>0 then
					return "choumang3"
				end
			else
				w = to:getWeapon()
				if w and #self:poisonCards({w},to)<1 then
					return "choumang3"
				end
			end
		end
		if table.contains(items,"choumang1")
		and getCardsNum("Jink",to,self.player)<1
		then return "choumang1" end
		if table.contains(items,"choumang2")
		and getCardsNum("Jink",to,self.player)>0
		then return "choumang2" end
	end
end

sgs.ai_skill_playerchosen.choumang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p)
		and self:doDisCard(p,"hej",true)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"hej",true)
		then return p end
	end
end

sgs.ai_skill_invoke.bifeng = function(self,data)
	local use = data:toCardUse()
	if use.card:isKindOf("AOE") then
		return use.to:length()>1 or self:getCardsNum(sgs.aiResponse[use.card:getClassName()])<1
	elseif use.card:isDamageCard() then
		local rc = sgs.aiResponse[use.card:getClassName()]
		if rc then
			for _,p in sgs.list(use.to)do
				if p~=self.player and getCardsNum(rc,p,self.player)>0 then
					return true
				end
			end
			if self:getCardsNum(rc)<1 then
				return true
			end
		end
		return use.to:length()>2 and self:isWeak()
	end
end


sgs.ai_skill_invoke.suwang = function(self,data)
	local ids = self.player:getPile("suwang")
	return ids:length()>2
end

sgs.ai_skill_playerchosen.suwang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isFriend(p)
		and self:canDraw(p)
		then return p end
	end
end


sgs.ai_skill_cardask["@mobilexinheji-use"] = function(self,data,pattern)
    local use = data:toCardUse()
	if self:isEnemy(use.to:at(0)) then
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards) -- 按保留值排序
		for _,c in sgs.list(cards)do
			if c:isKindOf("Slash") and self:slashIsEffective(c,use.to:at(0)) then
				return c:getEffectiveId()
			end
		end
	end
    return "."
end




sgs.ai_skill_playerchosen.mobileshejian = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"he")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"he")
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and self:doDisCard(target,"he")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getCardCount()>0
		then return target end
	end
end

addAiSkills("jiaohua").getTurnUseCard = function(self)
	local ch = {}
	if self.player:getMark("jiaohua_tiansuan_remove_basic")<1 then table.insert(ch,"basic") end
	if self.player:getMark("jiaohua_tiansuan_remove_trick")<1 then table.insert(ch,"trick") end
	if self.player:getMark("jiaohua_tiansuan_remove_equip")<1 then table.insert(ch,"equip") end
	return sgs.Card_Parse("@JiaohuaCard=.:"..ch[math.random(1,#ch)])
end

sgs.ai_skill_use_func["JiaohuaCard"] = function(card,use,self)
	self:sort(self.friends)
	for _,p in sgs.list(self.friends)do
		if self:canDraw(p) then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.JiaohuaCard = 9.4
sgs.ai_use_priority.JiaohuaCard = 5.8

sgs.ai_skill_playerchosen.yichong = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for _,target in sgs.list(destlist)do
		self.yichong_to = target
		if self:isEnemy(target)
		and self:doDisCard(target,"e",true)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		self.yichong_to = target
		if not self:isFriend(target)
		and self:doDisCard(target,"e",true)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		self.yichong_to = target
		if self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_suit.yichong = function(self)
	if self.yichong_to:hasEquip() then
		local es = self.yichong_to:getEquips()
		es = self:sortByKeepValue(es,true)
		return es[1]:getSuit()
	end
end

sgs.ai_skill_invoke.wufei = function(self,data)
	local to = data:toPlayer()
	return self:isEnemy(to) or #self.enemies<1 and not self:isFriend(to)
end

addAiSkills("shihe").getTurnUseCard = function(self)
	return sgs.Card_Parse("@ShiheCard=.")
end

sgs.ai_skill_use_func["ShiheCard"] = function(card,use,self)
	local mc = self:getMaxCard()
	if mc and mc:getNumber()>10 then
		self:sort(self.enemies,nil,true)
		for _,p in sgs.list(self.enemies)do
			if self.player:canPindian(p) then
				use.card = card
				use.to:append(p)
				break
			end
		end
	end
end

sgs.ai_use_value.ShiheCard = 2.4
sgs.ai_use_priority.ShiheCard = 5.8

sgs.ai_skill_playerchosen.zhenfu = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:getHujia()<4
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and #self.enemies>0
		and target:getHujia()<2
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.guimou = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getHandcardNum()>0
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and #self.enemies>0
		and target:getHandcardNum()>0
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if target:getHandcardNum()>0
		then return target end
	end
end

sgs.ai_skill_playerchosen.guimou1 = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and #self.enemies>0
		then return target end
	end
end

sgs.ai_skill_discard.zhouxian = function(self,x,n,can,e,pattern)
    local use = sgs.filterData[sgs.TargetSpecifying]:toCardUse()
	for _,p in sgs.list(use.to)do
		if p:hasSkill("zhouxian") and self:isFriend(p) then
			return {}
		end
	end
	local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if pattern:contains(h:getType()) then return {h:getEffectiveId()} end
	end
	return {}
end

sgs.ai_skill_playerchosen.shoufa = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local ch = self.player:getTag("zhoulin_yeshou"):toString()
	if ch=="yeshou_tu" then
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			and self:canDraw(target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not self:isEnemy(target) and #self.enemies>0
			and self:canDraw(target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			then return target end
		end
		return
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getCardCount()>0
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and #self.enemies<1
		and target:getCardCount()>0
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if target:getCardCount()>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and #self.enemies<1
		then return target end
	end
end

addAiSkills("zhoulin").getTurnUseCard = function(self)
	return sgs.Card_Parse("@ZhoulinCard=.")
end

sgs.ai_skill_use_func["ZhoulinCard"] = function(card,use,self)
	if self:isWeak() and self.player:getHujia()<1 then
		use.card = card
	end
end

sgs.ai_use_value.ZhoulinCard = 3.4
sgs.ai_use_priority.ZhoulinCard = 5.8

sgs.ai_skill_playerchosen.spyilie = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and #self.enemies>0
		then return target end
	end
end

addAiSkills("luanqun").getTurnUseCard = function(self)
	return sgs.Card_Parse("@LuanqunCard=.")
end

sgs.ai_skill_use_func["LuanqunCard"] = function(card,use,self)
	local n = 0
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>0 then
			n = n+1
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if p:getHandcardNum()>0 then
			n = n-1
		end
	end
	if n>0 then
		use.card = card
	end
end

sgs.ai_use_value.LuanqunCard = 4.4
sgs.ai_use_priority.LuanqunCard = 5.8

sgs.ai_skill_invoke.naxue = function(self,data)
	local use = self:getTurnUse()
	return #use<self.player:getHandcardNum()/2
end

sgs.ai_skill_discard.naxue = function(self,x,n,can,e,pattern)
    local ids = {}
	local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if #ids<#handcards/2 and self:doDisCard(self.player,h:getId())
		then table.insert(ids,h:getId()) end
	end
   	for _,h in sgs.list(handcards)do
		if #ids<#handcards/2 and not table.contains(ids,h:getId())
		then table.insert(ids,h:getId()) end
	end
	return ids
end

sgs.ai_skill_use["@@naxue"] = function(self,prompt)
	local valid,ids = {},{}
	local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
	local tos = self.room:getOtherPlayers(self.player)
   	for _,h in sgs.list(handcards)do
		if #valid<2 then
			local c,p = self:getCardNeedPlayer({h},false,tos)
			if c and p then
				tos:removeOne(p)
				table.insert(ids,c:getId())
				table.insert(valid,p:objectName())
			end
		end
	end
	if #valid>0 then
    	return "@NaxueCard="..table.concat(ids,"+").."->"..table.concat(valid,"+")
	end
end

sgs.ai_skill_playerchosen.weiming = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and #self.enemies>0
		then return target end
	end
end

addAiSkills("xietu").getTurnUseCard = function(self)
	return sgs.Card_Parse("@XietuCard=.")
end

sgs.ai_skill_use_func["XietuCard"] = function(card,use,self)
	local n = self.player:getMark("weimingShiming")
	if n==1 then
		for _,p in sgs.list(self.friends)do
			if p:isWounded() and self.player:getMark("xietu1-PlayClear")<1 then
				sgs.ai_skill_choice.xietu = "xietu1"
				use.to:append(p)
				use.card = card
				return
			end
		end
		for _,p in sgs.list(self.friends)do
			if self:canDraw(p) and self.player:getMark("xietu2-PlayClear")<1 then
				sgs.ai_skill_choice.xietu = "xietu2"
				use.to:append(p)
				use.card = card
				return
			end
		end
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if not self:isEnemy(p) then
				if p:isWounded() and self.player:getMark("xietu1-PlayClear")<1 then
					sgs.ai_skill_choice.xietu = "xietu1"
					use.to:append(p)
					use.card = card
					return
				end
				if self:canDraw(p) and self.player:getMark("xietu2-PlayClear")<1 then
					sgs.ai_skill_choice.xietu = "xietu2"
					use.to:append(p)
					use.card = card
					return
				end
			end
		end
	elseif n==2 then
		n = self.player:getChangeSkillState("xietu")
		if n==1 then
			if self.player:isWounded() then
				self:sort(self.enemies)
				for _,p in sgs.list(self.enemies)do
					if p:canDiscard(p,"he") then
						use.to:append(p)
						use.card = card
						return
					end
				end
			end
		else
			self:sort(self.enemies)
			for _,p in sgs.list(self.enemies)do
				if self:damageIsEffective(p,"N",self.player) then
					use.to:append(p)
					use.card = card
					return
				end
			end
		end
	else
		n = self.player:getChangeSkillState("xietu")
		self:sort(self.friends)
		if n==1 then
			for _,p in sgs.list(self.friends)do
				if p:isWounded() then
					use.to:append(p)
					use.card = card
					return
				end
			end
			for _,p in sgs.list(self.room:getAlivePlayers())do
				if p:isWounded() and not self:isEnemy(p) then
					use.to:append(p)
					use.card = card
					return
				end
			end
		else
			for _,p in sgs.list(self.friends)do
				if self:canDraw(p) then
					use.to:append(p)
					use.card = card
					return
				end
			end
			for _,p in sgs.list(self.room:getAlivePlayers())do
				if self:canDraw(p) and not self:isEnemy(p) then
					use.to:append(p)
					use.card = card
					return
				end
			end
		end
	end
end

sgs.ai_use_value.XietuCard = 5.4
sgs.ai_use_priority.XietuCard = 5.8

sgs.ai_skill_playerchosen.bojian = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target) and self:canDraw(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target) and #self.enemies>0 and self:canDraw(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end


sgs.ai_skill_askforyiji.jiwei = function(self,card_ids,targets)
	local p,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,targets)
	if p and self.player~=p then return p,id end
    for _,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then return p,card_ids[1] end
	end
	local destlist = self.room:getOtherPlayers(self.player) -- 将列表转换为表
	destlist = self:sort(destlist)
	for _,p in sgs.list(destlist)do
		if not self:isEnemy(p) and #self.enemies>0 and self:canDraw(p)
		then return p,card_ids[1] end
	end
	for _,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p,card_ids[1] end
	end
	return destlist[1],card_ids[1]
end

addAiSkills("quchong").getTurnUseCard = function(self)
	local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if h:isKindOf("EquipCard") and not self.player:isCardLimited(h,sgs.Card_MethodRecast) then
			if h:objectName():contains("dagongche") and self:isWeak() then continue end
			return sgs.Card_Parse("@QuchongCard="..h:toString())
		end
	end
end

sgs.ai_skill_use_func["QuchongCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.QuchongCard = 5.4
sgs.ai_use_priority.QuchongCard = 8.8

sgs.ai_skill_playerchosen.quchong = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target) and self:isWeak(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_invoke.quchong = function(self,data)
	return not self:isWeak() or #self.friends_noself>#self.enemies/2
end

sgs.ai_skill_playerchosen.mobilespshushen = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_invoke.mobilespzhijie = function(self,data)
	local to = data:toPlayer()
	return to and self:isFriend(to)
end

sgs.ai_skill_invoke.xiongjin = function(self,data)
	local to = data:toPlayer()
	if to then
		if self:isFriend(to) then
			return self:canDraw(to) and self.player:getLostHp()>1
		else
			return self:isEnemy(to) and self.player:getLostHp()<2
		end
	end
	return self:canDraw() and self.player:getLostHp()>1
end

sgs.ai_skill_use["@@baoxi1"] = function(self,prompt)
	if self.player:getLostHp()<1 then return end
	local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		local dc = dummyCard("duel")
		dc:setSkillName("baoxi")
		dc:addSubcard(h)
		if dc:isAvailable(self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				local tos = {}
				for _,p in sgs.list(d.to)do
					table.insert(tos,p:objectName())
				end
				return dc:toString().."->"..table.concat(tos,"+")
			end
		end
	end
end

sgs.ai_skill_use["@@baoxi2"] = function(self,prompt)
	if self.player:getLostHp()<1 then return end
	local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		local dc = dummyCard()
		dc:setSkillName("baoxi")
		dc:addSubcard(h)
		if dc:isAvailable(self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				local tos = {}
				for _,p in sgs.list(d.to)do
					table.insert(tos,p:objectName())
				end
				return dc:toString().."->"..table.concat(tos,"+")
			end
		end
	end
end

addAiSkills("mobilejiyu").getTurnUseCard = function(self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards,nil,"j") -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if self:getKeepValue(h)<7 then
			return sgs.Card_Parse("@MobileJiyuCard="..h:toString())
		end
	end
end

sgs.ai_skill_use_func["MobileJiyuCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.MobileJiyuCard = 5.4
sgs.ai_use_priority.MobileJiyuCard = 8.8

sgs.ai_skill_invoke.guansha = function(self,data)
	return self:isWeak() and self:getOverflow()>0
end

addAiSkills("mzengou").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MZengouCard=.")
end

sgs.ai_skill_use_func["MZengouCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>0 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	local aps = self:sort(self.room:getAlivePlayers())
	for _,p in sgs.list(aps)do
		if p:getHandcardNum()>0 then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.MZengouCard = 4.4
sgs.ai_use_priority.MZengouCard = 1.8

sgs.ai_skill_invoke.feili = function(self,data)
	local to = data:toPlayer()
	if to then
		if self:isFriend(to) then
			return self:canDraw()
		else
			return self:isWeak()
		end
	end
	return self:canDraw() and self:isWeak()
end


sgs.ai_skill_discard.feili = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards,nil,"j")
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min then break end
     	table.insert(to_cards,h:getEffectiveId())
	end
   	if #to_cards<min then return {} end
	if self:isWeak() or self:getOverflow()>0
	then return to_cards end
	return {}
end


addAiSkills("mobiledaoshu").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileDaoshuCard=.")
end

sgs.ai_skill_use_func["MobileDaoshuCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.MobileDaoshuCard = 4.4
sgs.ai_use_priority.MobileDaoshuCard = 1.8

sgs.ai_skill_invoke.daizui = function(self,data)
	return self:getAllPeachNum()<2
end

sgs.ai_skill_invoke.yinda = function(self,data)
	local dy = data:toDying()
	return self:isFriend(dy.who)
end

sgs.ai_skill_use["@@yinda"] = function(self,prompt)
	if self.player:getLostHp()<1 then return end
	local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for i,h1 in sgs.list(handcards)do
		local ids = {h1:toString()}
		for x,h2 in sgs.list(handcards)do
			if x~=i and x<=#handcards/2 and h1:getColor()~=h2:getColor() then
				table.insert(ids,h2:toString())
				return "$"..table.concat(ids,"+")
			end
		end
	end
end

addAiSkills("zhuguo").getTurnUseCard = function(self)
	return sgs.Card_Parse("@ZhuguoCard=.")
end

sgs.ai_skill_use_func["ZhuguoCard"] = function(card,use,self)
	self:sort(self.friends)
	for _,p in sgs.list(self.friends)do
		if p:getHandcardNum()==p:getMaxHp() and p:isWounded() then
			use.to:append(p)
			use.card = card
			return
		end
	end
	self:sort(self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>p:getMaxHp() and not p:isWounded() then
			use.to:append(p)
			use.card = card
			return
		end
	end
	for _,p in sgs.list(self.friends)do
		if p:getHandcardNum()<p:getMaxHp() then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.ZhuguoCard = 4.4
sgs.ai_use_priority.ZhuguoCard = 6.8

sgs.ai_skill_playerchosen.zhuguo = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_invoke.xuyue = function(self,data)
	local to = data:toPlayer()
	if to and self:isFriend(to) then
		return self:canDraw(to)
	end
end

addAiSkills("mobilekuangxiang").getTurnUseCard = function(self)
	return sgs.Card_Parse("@MobileKuangxiangCard=.")
end

sgs.ai_skill_use_func["MobileKuangxiangCard"] = function(card,use,self)
	self:sort(self.friends)
	for _,p in sgs.list(self.friends)do
		if p:getHandcardNum()<self.player:getHandcardNum() then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.MobileKuangxiangCard = 4.4
sgs.ai_use_priority.MobileKuangxiangCard = -0.8

addAiSkills("ganjue").getTurnUseCard = function(self)
	local handcards = sgs.QList2Table(self.player:getCards("e"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if self:getKeepValue(h)<7 then
			local dc = dummyCard()
			dc:addSubcard(h)
			local d = self:aiUseCard(dc)
			if d.card then
				self.ganjueUse = d
				return sgs.Card_Parse("@GanjueCard="..h:toString())
			end
		end
	end
end

sgs.ai_skill_use_func["GanjueCard"] = function(card,use,self)
	use.card = card
	use.to = self.ganjueUse.to
end

sgs.ai_use_value.GanjueCard = 5.4
sgs.ai_use_priority.GanjueCard = 1.8

sgs.ai_skill_cardask["mobilezhuji0"] = function(self,data,pattern)
    local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if self:getKeepValue(c)<7 then
			return c:toString()
		end
	end
    return "."
end

sgs.ai_skill_choice.mobilezhuji = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"mobilezhuji2") and self:isWeak()
	then return "mobilezhuji2" end
	if table.contains(items,"mobilezhuji1") and self:getOverflow()<1
	then return "mobilezhuji1" end
	if table.contains(items,"mobilezhuji3") and self.player:getHujia()<4
	then return "mobilezhuji3" end
	if table.contains(items,"mobilezhuji1")
	then return "mobilezhuji1" end
end

sgs.ai_skill_invoke.yance = function(self,data)
	return sgs.turncount==1 or self.player:getPhase()==sgs.Player_Start
end

sgs.ai_skill_invoke.fangqiu = function(self,data)
	return self:isWeak()
end

sgs.ai_skill_discard.mobile_manjuan = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards,nil,"j")
	local ids = self.player:getTag("mobile_manjuanIds"):toStringList()
   	for _,h in sgs.list(cards)do
   		if #to_cards>max/2 then break end
     	if table.contains(ids,h:toString()) then
			table.insert(to_cards,h:getEffectiveId())
		end
	end
   	if #to_cards<min then return {} end
	return to_cards
end

sgs.ai_skill_invoke.yangming = function(self,data)
	return true
end

sgs.ai_skill_use["@@yangming"] = function(self,prompt)
	if self.player:getLostHp()<1 then return end
	local cs = {}
   	for _,id in sgs.list(self.player:getPile("yangming"))do
		table.insert(cs,sgs.Sanguosha:getCard(id))
	end
    self:sortByUseValue(cs)
   	for _,h in sgs.list(cs)do
		if h:isAvailable(self.player) then
			local d = self:aiUseCard(h)
			if d.card then
				local tos = {}
				for _,p in sgs.list(d.to)do
					table.insert(tos,p:objectName())
				end
				return h:toString().."->"..table.concat(tos,"+")
			end
		end
	end
end

sgs.ai_skill_invoke.xiaxing = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_choice.qihui = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"qihui1") and self:isWeak() and self.player:isWounded() then
		return "qihui1"
	end
	if table.contains(items,"qihui2") and self:canDraw() and self:isWeak() then
		return "qihui2"
	end
	if table.contains(items,"qihui3") and self.player:getPhase()<=sgs.Player_Play and self.player:getHandcardNum()>3 then
		return "qihui3"
	end
	if table.contains(items,"qihui2") then
		return "qihui2"
	end
end

function canXSGongli(player,gn)
	if player:hasShownRole() and player:hasSkill("xsgongli") then
		for _,p in sgs.list(player:getAliveSiblings())do
			if p:hasShownRole() and p:getGeneralName():contains(gn) and player:isYourFriend(p) then
				return true
			end
		end
	end
end

addAiSkills("_xuanjian").getTurnUseCard = function(self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if self:getKeepValue(h)<7 then
			local dc = dummyCard()
			dc:setSkillName("_xuanjian")
			if canXSGongli(self.player,"you_zhugeliang") then
				dc:addSubcard(h)
			else
				for _,c in sgs.list(handcards)do
					if h:getSuit()==c:getSuit()
					then dc:addSubcard(c) end
				end
			end
			if dc:isAvailable(self.player)
			and self:aiUseCard(dc).card
			then return dc end
		end
	end
end

function sgs.ai_cardsview._xuanjian(self,class_name,player)
	local handcards = sgs.QList2Table(player:getCards("h"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if self:getKeepValue(h)<7 then
			local dc = dummyCard()
			dc:setSkillName("_xuanjian")
			if canXSGongli(player,"you_zhugeliang") then
				dc:addSubcard(h)
			else
				for _,c in sgs.list(handcards)do
					if h:getSuit()==c:getSuit()
					then dc:addSubcard(c) end
				end
			end
			if dc:isAvailable(player)
			then return dc:toString() end
		end
	end
end

addAiSkills("qinying").getTurnUseCard = function(self)
	local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
	local ids = {}
   	for i,h in sgs.list(handcards)do
		if self:getKeepValue(h)>6 or table.contains(self.toUse,h) then continue end
		table.insert(ids,h:toString())
	end
	if #ids>0 then
		local dc = dummyCard("duel")
		local d = self:aiUseCard(dc)
		if d.card then
			self.qinyingUse = d
			return sgs.Card_Parse("@QinyingCard="..table.concat(ids,"+"))
		end
	end
end

sgs.ai_skill_use_func["QinyingCard"] = function(card,use,self)
	use.card = card
	use.to = self.qinyingUse.to
end

sgs.ai_use_value.QinyingCard = 5.4
sgs.ai_use_priority.QinyingCard = 3.8

sgs.ai_skill_invoke.qinying0 = function(self,data)
	return self:doDisCard(self.player,"hej") or self:getCardsNum("Slash")<1
end

sgs.ai_skill_cardask["lunxiong0"] = function(self,data,pattern)
    local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if self:getKeepValue(c)<7 and pattern==c:toString() and (c:getNumber()<9 or self:isWeak()) then
			return c:toString()
		end
	end
    return "."
end

sgs.ai_skill_invoke.shunyi = function(self,data)
	return self:canDraw()
end

addAiSkills("biwei").getTurnUseCard = function(self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local mc = handcards[1]
   	for i,h in sgs.list(handcards)do
		if h:getNumber()>mc:getNumber() then mc = h end
	end
   	for i,h in sgs.list(handcards)do
		if h:getNumber()>=mc:getNumber() and h~=mc then return end
	end
	return self:getOverflow()>0
	and sgs.Card_Parse("@BiweiCard="..mc:toString())
end

sgs.ai_skill_use_func["BiweiCard"] = function(card,use,self)
	self:sort(self.enemies,nil,true)
    for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>=self.player:getHandcardNum() then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.BiweiCard = 5.4
sgs.ai_use_priority.BiweiCard = 5.8

sgs.ai_skill_invoke.xinpowei = function(self,data)
	local to = data:toPlayer()
	if to and self:isEnemy(to) then
		return true
	end
end

sgs.ai_skill_choice.xinshenzhuo = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"xinshenzhuo1") and self:getCardsNum("Slash")>0
	and self.player:getPhase()==sgs.Player_Play
	then return "xinshenzhuo1" end
	if table.contains(items,"xinshenzhuo2") and self:canDraw()
	then return "xinshenzhuo2" end
end

sgs.ai_skill_invoke.mobilemouliyu = function(self,data)
	local to = data:toPlayer()
	if to and self:doDisCard(to) then
		return true
	end
end

sgs.ai_skill_playerchosen.mobilemouliyu = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

addAiSkills("bshanzhan").getTurnUseCard = function(self)
	return sgs.Card_Parse("@BsHanzhanCard=.")
end

sgs.ai_skill_use_func["BsHanzhanCard"] = function(card,use,self)
	for _,p in sgs.list(self:aiUseCard(dummyCard("duel")).to)do
		if self:getOverflow()<=self:getOverflow(p) then
			use.to:append(p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.BsHanzhanCard = 5.4
sgs.ai_use_priority.BsHanzhanCard = 5.8


sgs.ai_skill_playerschosen.zhanlie = function(self,players)
	local tos = {}
	local dc = dummyCard()
	dc:setSkillName("zhanlie")
	local d = self:aiUseCard(dc)
    for _,p in sgs.list(players)do
		if d.to:contains(p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_playerchosen.zhanlie = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_cardask["zhanlie30"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if self:getKeepValue(c)<7 or self:isWeak() then
			return c:toString()
		end
	end
    return "."
end

addAiSkills("zhenfeng").getTurnUseCard = function(self)
	return sgs.Card_Parse("@ZhenfengCard=.")
end

sgs.ai_skill_use_func["ZhenfengCard"] = function(card,use,self)
    if self:isWeak() then
		use.card = card
	end
end

sgs.ai_use_value.ZhenfengCard = 5.4
sgs.ai_use_priority.ZhenfengCard = 0.8

addAiSkills("fuji").getTurnUseCard = function(self)
	return sgs.Card_Parse("@FujiCard=.")
end

sgs.ai_skill_use_func["FujiCard"] = function(card,use,self)
	local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
	local ids = {}
   	for i,h in sgs.list(handcards)do
		if self:getKeepValue(h)>6 or table.contains(self.toUse,h) then continue end
		table.insert(ids,h:toString())
	end
	if #ids<1 then return end
	local ids2 = {}
	self:sort(self.friends_noself)
   	for i,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			use.to:append(p)
			table.insert(ids2,ids[use.to:length()])
			if use.to:length()>=#ids then
				use.card = sgs.Card_Parse("@FujiCard="..table.concat(ids2,"+"))
				break
			end
		end
	end
end

sgs.ai_use_value.FujiCard = 5.4
sgs.ai_use_priority.FujiCard = 3.8

addAiSkills("daozhuan").getTurnUseCard = function(self)
	local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
	local ids = {}
   	for i,pc in sgs.list(RandomList(patterns()))do
		if self.player:getMark("daozhuan_guhuo_remove_"..pc.."_lun")>0 then continue end
		local dc = dummyCard(pc)
		if dc:isKindOf("BasicCard")and dc:isAvailable(self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				self.daozhuanUse = d
				sgs.ai_use_priority.DaozhuanCard = sgs.ai_use_priority[dc:getClassName()]
				return sgs.Card_Parse("@DaozhuanCard=.:"..pc)
			end
		end
	end
end

sgs.ai_skill_use_func["DaozhuanCard"] = function(card,use,self)
	use.card = card
	use.to = self.daozhuanUse.to
end

sgs.ai_use_value.DaozhuanCard = 5.4
sgs.ai_use_priority.DaozhuanCard = 3.8

function sgs.ai_cardsview.daozhuan(self,class_name,player)
	return "@DaozhuanCard=.:"..patterns(class_name)
end

addAiSkills("qiantun").getTurnUseCard = function(self)
	return sgs.Card_Parse("@QiantunCard=.")
end

sgs.ai_skill_use_func["QiantunCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p) then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.QiantunCard = 4.4
sgs.ai_use_priority.QiantunCard = 6.8

addAiSkills("weisi").getTurnUseCard = function(self)
	return sgs.Card_Parse("@WeisiCard=.")
end

sgs.ai_skill_use_func["WeisiCard"] = function(card,use,self)
	local d = self:aiUseCard(dummyCard("duel"))
	for _,p in sgs.list(d.to)do
		if not self:isFriend(p) then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.WeisiCard = 4.4
sgs.ai_use_priority.WeisiCard = 2.8

sgs.ai_skill_invoke.zhaoxiong = function(self,data)
	return self:canDraw() or self:getOverflow()>0
end

sgs.ai_skill_invoke.dangyi = function(self,data)
	local to = data:toPlayer()
	if to and self:isEnemy(to) then
		return self:isWeak(to)
	end
end

sgs.ai_skill_playerschosen.xiezheng = function(self,players,x,n)
	local dc = dummyCard("_ov_binglinchengxia")
	dc:setSkillName("_xiezheng")
	if dc:isAvailable(self.player) then
		local ntps = {}
		if self.player:getMark("ZXChangeXiezheng")>0 then
			for _,p in sgs.list(self.player:getAliveSiblings())do
				if p:getKingdom()~=self.player:getKingdom()
				then table.insert(ntps,p:objectName()) end
			end
		end
		if self:aiUseCard(dc,dummy(nil,0,ntps)).card
		then else return {} end
	end
	local tps = {}
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if #tps<x then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_use["@@xiezheng"] = function(self,prompt)
	local dc = dummyCard("_ov_binglinchengxia")
	dc:setSkillName("_xiezheng")
	if dc:isAvailable(self.player) then
		local ntps = {}
		if self.player:getMark("ZXChangeXiezheng")>0 then
			for _,p in sgs.list(self.player:getAliveSiblings())do
				if p:getKingdom()~=self.player:getKingdom()
				then table.insert(ntps,p:objectName()) end
			end
		end
		local d = self:aiUseCard(dc,dummy(nil,0,ntps))
		if d.card then
			local tos = {}
			for _,p in sgs.list(d.to)do
				table.insert(tos,p:objectName())
			end
			return dc:toString().."->"..table.concat(tos,"+")
		end
	end
end

sgs.ai_skill_invoke._dagongche_jinji = function(self,data)
	local to = data:toPlayer()
	if to and self:isEnemy(to) then
		return true
	end
end

sgs.ai_skill_discard.bswanglie = function(self,max,min,optional)
	local to_cards = self:getTurnUse()
   	for _,h in sgs.list(self.player:getCards("h"))do
     	if table.contains(to_cards,h) then
			if h:isDamageCard() then
				return {h:getId()}
			end
		end
	end
	return {}
end

sgs.ai_skill_choice.bshongyi = function(self,choices)
	local items = choices:split("+")
	if self:getOverflow()<1
	then return items[1] end
	return items[2]
end

sgs.ai_skill_playerchosen.bshaoshi = function(self,players,reason)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p)
		then return p end
	end
end

addAiSkills("bsdimeng").getTurnUseCard = function(self)
	return sgs.Card_Parse("@BsDimengCard=.")
end

sgs.ai_skill_use_func["BsDimengCard"] = function(card,use,self)
	local n = self.player:getLostHp()
	self:sort(self.friends)
	self:sort(self.enemies,nil,true)
    for _,p in sgs.list(self.friends)do
		for _,q in sgs.list(self.enemies)do
			local x = q:getHandcardNum()-p:getHandcardNum()
			if x>0 and x<=n then
				use.card = card
				use.to:append(p)
				use.to:append(q)
				sgs.ai_skill_choice.bsdimeng = "1"
				return
			end
		end
		for _,q in sgs.list(self.enemies)do
			local x = p:getHandcardNum()-q:getHandcardNum()
			if x>0 and x<n then
				use.card = card
				use.to:append(p)
				use.to:append(q)
				sgs.ai_skill_choice.bsdimeng = "2"
				return
			end
		end
		for _,q in sgs.list(self.room:getAlivePlayers())do
			if self:isFriend(q) then continue end
			local x = p:getHandcardNum()-q:getHandcardNum()
			if x>0 and x<n then
				use.card = card
				use.to:append(p)
				use.to:append(q)
				sgs.ai_skill_choice.bsdimeng = "2"
				return
			end
		end
	end
end

sgs.ai_use_value.BsDimengCard = 4.4
sgs.ai_use_priority.BsDimengCard = 2.8

addAiSkills("xiongtu").getTurnUseCard = function(self)
	return sgs.Card_Parse("@XiongtuCard=.")
end

sgs.ai_skill_use_func["XiongtuCard"] = function(card,use,self)
	self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>0 and self:damageIsEffective(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.XiongtuCard = 4.4
sgs.ai_use_priority.XiongtuCard = 4.8

addAiSkills("feijing").getTurnUseCard = function(self)
	local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for i,h in sgs.list(handcards)do
		if h:isDamageCard() then
			local dc = dummyCard(nil,"feijing")
			dc:addSubcard(h)
			if dc:isAvailable(self.player)
			then return dc end
		end
	end
end

sgs.ai_view_as.feijing = function(card,player,card_place,class_name)
	if card:isDamageCard() and card_place~=sgs.Player_PlaceSpecial then
    	return ("slash:feijing[no_suit:0]="..card:getEffectiveId())
	end
end

sgs.ai_skill_invoke.feijing = function(self,data)
	local use = data:toCardUse()
	local ap = use.to:last():getNextAlive()
	local n = 0
	while ap~=self.player do
		if not self:isFriend(ap) then n = n+1 end
		ap = ap:getNextAlive()
	end
	ap = self.player:getNextAlive()
	while ap~=use.to:last() do
		if not self:isFriend(ap) then n = n-1 end
		ap = ap:getNextAlive()
	end
	sgs.ai_skill_choice.feijing = "2"
	if n>0 then
		sgs.ai_skill_choice.feijing = "1"
	end
	return n~=0
end

sgs.ai_skill_invoke.zhuangshi = function(self,data)
	return not self:isWeak() or self:getOverflow()>=0
end

sgs.ai_skill_discard.zhuangshi = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards,nil,"j")
	local touse = self:getTurnUse()
   	for _,h in sgs.list(cards)do
		if table.contains(touse,h) then continue end
		table.insert(to_cards,h:getEffectiveId())
   		if #to_cards>=#cards/2 then break end
	end
	return to_cards
end

sgs.ai_skill_choice.zhuangshi = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"cancel")
	and self:isWeak() then return "cancel" end
	return items[1]
end















