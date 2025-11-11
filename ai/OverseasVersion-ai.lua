
sgs.ai_skill_cardask["ov_danfa0"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local ids = self.player:getPile("ov_dan")
	for _,h in sgs.list(cards)do
		if self.player:getPhase()==sgs.Player_Start
		and self.player:getJudgingArea():length()>0
		and #self:getCards("Nullification")>0
		and table.contains(self:getCards("Nullification"),h)
		or self.player:getPhase()==sgs.Player_Finish and #cards<3
		then continue end
		local can = true
		for _,c in sgs.list(ListI2C(ids))do
			if c:getSuit()==h:getSuit()
			then can = false end
		end
		if can
		then
			return h:getEffectiveId()
		end
	end
    return #cards>2 and cards[1]:getEffectiveId() or "."
end

addAiSkills("ov_lingbao").getTurnUseCard = function(self)
    local cards = self.player:getPile("ov_dan")
	if cards:length()<2 then return end
	local valid,suit = {},sgs.IntList()
	for _,h in sgs.list(ListI2C(cards))do
		if suit:contains(h:getSuit()) then continue end
		self.ov_lingbao_to = sgs.SPlayerList()
		for _,p in sgs.list(self.friends)do
			if self:isWeak(p)
			and h:isRed()
			then
				self.ov_lingbao_to:append(p)
				table.insert(valid,h:getEffectiveId())
				suit:append(h:getSuit())
				break
			end
		end
		if #valid>1 then return sgs.Card_Parse("#ov_lingbaoCard:"..table.concat(valid,"+")..":") end
	end
	valid,suit = {},sgs.IntList()
	for _,h in sgs.list(ListI2C(cards))do
		if suit:contains(h:getSuit()) then continue end
		self.ov_lingbao_to = sgs.SPlayerList()
		for _,p in sgs.list(self.enemies)do
			if p:getHandcardNum()>0
			and p:hasEquip()
			and h:isBlack()
			then
				self.ov_lingbao_to:append(p)
				table.insert(valid,h:getEffectiveId())
				suit:append(h:getSuit())
				break
			end
		end
		h = sgs.Card_Parse("#ov_lingbaoCard:"..table.concat(valid,"+")..":")
		if #valid>1 then sgs.ai_use_priority.ov_lingbaoCard = 3.4 return h end
	end
	valid,suit = {},sgs.IntList()
	self:sort(self.enemies,"card")
	self:sort(self.friends,"card")
	for _,h in sgs.list(ListI2C(cards))do
		if suit:contains(h:getSuit()) then continue end
		self.ov_lingbao_to = sgs.SPlayerList()
		for _,p in sgs.list(self.enemies)do
			if p:getCardCount()>0
			then
				if #valid>0
				and h:getColor()==sgs.Sanguosha:getCard(valid[1]):getColor()
				then break end
				self.ov_lingbao_to:append(self.friends[1])
				self.ov_lingbao_to:append(p)
				table.insert(valid,h:getEffectiveId())
				suit:append(h:getSuit())
				break
			end
		end
		h = sgs.Card_Parse("#ov_lingbaoCard:"..table.concat(valid,"+")..":")
		if #valid>1 then return h end
	end
end

sgs.ai_skill_use_func["#ov_lingbaoCard"] = function(card,use,self)
	use.card = card
	use.to = self.ov_lingbao_to
end

sgs.ai_use_value.ov_lingbaoCard = 6.4
sgs.ai_use_priority.ov_lingbaoCard = 0.4

sgs.ai_can_damagehp._ov_chongyingshenfu = function(self,from,card,to)
	if card and to:getMark("_ov_chongyingshenfu"..card:objectName())>0
	then return self:canLoseHp(from,card,to) end
	return card and self:canLoseHp(from,card,to)
	and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
end

sgs.ai_armor_value._ov_chongyingshenfu = 5
sgs.ai_armor_value._ov_taijifuchen = 3
sgs.ai_armor_value._ov_lingbaoxianhu = 4

sgs.ai_keep_value.OvChongyingshenfu = 11
sgs.ai_keep_value.OvTaijifuchen = 11
sgs.ai_keep_value.OvLingbaoxianhu = 11

sgs.ai_skill_invoke.ov_miaolve = function(self,data)
	return true
end

sgs.ai_skill_choice.ov_miaolve = function(self,choices)
	local items = choices:split("+")
	return items[1]
end

sgs.ai_skill_cardask["ov_yingjia0"] = function(self,data,pattern)
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	self:sort(self.friends,"handcard",true)
	for _,fp in sgs.list(self.friends)do
		if fp:getHandcardNum()>1
		and #cards>0
		then
			sgs.ai_skill_playerchosen.ov_yingjia = fp
			return cards[1]:getEffectiveId()
		end
	end
	sgs.ai_skill_playerchosen.ov_yingjia = self.friends[1]
    return #self.friends>0 and #cards>1 and cards[1]:getEffectiveId() or "."
end

function SmartAI:useCardMantianguohai(card,use)
	local extraTarget = 1+sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if not use.to:contains(ep) and CanToCard(card,self.player,ep)
		and self:doDisCard(ep,"ej") and self.player:getHandcardNum()>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if isCurrent(use,ep) then continue end
		if not use.to:contains(ep) and CanToCard(card,self.player,ep)
		and self:doDisCard(ep,"ej") and self.player:getHandcardNum()>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if isCurrent(use,ep) then continue end
		if not use.to:contains(ep) and CanToCard(card,self.player,ep)
		and ep:getHandcardNum()>0 and self.player:getHandcardNum()>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	self:sort(self.enemies,"card",true)
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if not use.to:contains(ep) and CanToCard(card,self.player,ep)
		and ep:getCardCount()>0 and self.player:getHandcardNum()>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if isCurrent(use,ep) then continue end
		if not use.to:contains(ep) and CanToCard(card,self.player,ep)
		and ep:getCardCount()>0 and self.player:getHandcardNum()>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end
sgs.ai_use_priority.Mantianguohai = 5.4
sgs.ai_keep_value.Mantianguohai = 4
sgs.ai_use_value.Mantianguohai = 3.7

sgs.ai_nullification.Mantianguohai = function(self,trick,from,to,positive)
    local null_num = self:getCardsNum("Nullification")
    if positive
	then
		if self:isEnemy(from)
		and self:isFriend(to)
		then
			if null_num>1
			then
				return to:hasEquip()
			else
				return to:getCardCount()>0
				and self:isWeak(to)
			end
		elseif self:isEnemy(from)
		and self:isEnemy(to)
		then
			return to:getJudgingArea():length()>0
		end
	else
		if self:isFriend(from)
		and self:isFriend(to)
		then
			return self:doDisCard(to,"ej")
		end
	end
end

sgs.ai_skill_cardask["ov_cuijin0"] = function(self,data,pattern)
	local use = data:toCardUse()
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	local can = #cards>1 and cards[1]:getEffectiveId()
	if self:isEnemy(use.from)
	then
		for _,to in sgs.list(use.to)do
			if to:getHandcardNum()<2
			then can = false break end
			if to:objectName()==self.player:objectName()
			then
				local jink = self:getCards("Jink")
				if #jink>0 and jink[1]:getEffectiveId()~=can
				then break end
			end
		end
	else
		for _,to in sgs.list(use.to)do
			if to:getHandcardNum()>1
			then can = false break end
			if to:objectName()==self.player:objectName()
			then
				local jink = self:getCards("Jink")
				if #jink>0 and jink[1]:getEffectiveId()~=can
				then can = false break end
			end
		end
	end
	return can or "."
end

addAiSkills("ov_beini").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_beiniCard:.:")
end

sgs.ai_skill_use_func["#ov_beiniCard"] = function(card,use,self)
	self:sort(self.enemies,"handcard")
	sgs.ai_skill_invoke.ov_beini = false
	for _,ep in sgs.list(self.enemies)do
		if ep:getHp()>self.player:getHp()
		and (ep:getHandcardNum()<1 or not self:isWeak() or self:getCardsNum("Jink")>0)
		then
			use.card = card
			use.to:append(ep) 
			sgs.ai_skill_invoke.ov_beini = ep:getHandcardNum()<1
			return
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		if ep:getHp()>self.player:getHp()
		and ep:getHandcardNum()>1
		and (not self:isWeak() or self:getCardsNum("Jink")>0)
		then
			use.card = card
			use.to:append(ep)
			sgs.ai_skill_invoke.ov_beini = self.player:getHandcardNum()>3
			return
		end
	end
	for _,ep in sgs.list(self.room:getAlivePlayers())do
		if ep:getHp()>self.player:getHp()
		and (not self:isWeak() or self:getCardsNum("Jink")>0)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.ov_beiniCard = 2.4
sgs.ai_use_priority.ov_beiniCard = 4.8

sgs.ai_skill_invoke.ov_dingfa = function(self,data)
	return true
end

sgs.ai_skill_playerchosen.ov_dingfa = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
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
sgs.ai_playerchosen_intention.ov_dingfa = 55

sgs.ai_skill_choice.ov_dingfa = function(self,choices)
	local items = choices:split("+")
	for _,ep in sgs.list(self.enemies)do
		if ep:getHp()<2 then return items[1] end
	end
	return #items>1 and self:isWeak() and items[2] or items[1]
end

sgs.ai_skill_use["@@ov_zhenjun"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
    for _,fp in sgs.list(self.friends_noself)do
		for _,p in sgs.list(self.player:getAliveSiblings())do
			if self:isEnemy(p) and fp:inMyAttackRange(p)
			then
				return string.format("#ov_zhenjunCard:%s:->%s",cards[1]:getEffectiveId(),fp:objectName())
			end
		end
	end
    for _,fp in sgs.list(self.player:getAliveSiblings())do
		for _,p in sgs.list(self.player:getAliveSiblings())do
			if not self:isEnemy(fp) and self:isEnemy(p) and fp:inMyAttackRange(p)
			then
				return string.format("#ov_zhenjunCard:%s:->%s",cards[1]:getEffectiveId(),fp:objectName())
			end
		end
	end
    for _,fp in sgs.list(self.player:getAliveSiblings())do
		for _,p in sgs.list(self.player:getAliveSiblings())do
			if not self:isEnemy(fp) and not self:isFriend(p) and fp:inMyAttackRange(p)
			then
				return string.format("#ov_zhenjunCard:%s:->%s",cards[1]:getEffectiveId(),fp:objectName())
			end
		end
	end
end

sgs.ai_skill_playerchosen.ov_zhenjun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
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
sgs.ai_playerchosen_intention.ov_zhenjun = 55

addAiSkills("ov_weipo").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_weipoCard:.:")
end

sgs.ai_skill_use_func["#ov_weipoCard"] = function(card,use,self)
	local slashs = self:getCards("Slash")
	if #slashs>0
	then
		for _,s in sgs.list(slashs)do
			if table.contains(self.toUse,s)
			then table.removeOne(slashs,s) end
		end
		if #slashs>0
		then
			use.card = card
			use.to:append(self.player)
			return
		end
	end
	self:sort(self.friends_noself,"handcard",true)
	for _,ep in sgs.list(self.friends_noself)do
		if ep:getHandcardNum()>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.ov_weipoCard = 5.4
sgs.ai_use_priority.ov_weipoCard = 3.8

addAiSkills("ov_weipobf").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if c:isKindOf("Slash")
		and not table.contains(self.toUse,c)
		then
			return sgs.Card_Parse("#ov_weipobfCard:"..c:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#ov_weipobfCard"] = function(card,use,self)
	for _,ep in sgs.list(self.room:findPlayersBySkillName("ov_weipo"))do
		if self.player:getMark("&ov_weipo+#"..ep:objectName())>0
		and self.player:getMark(ep:objectName().."ov_weipo-PlayClear")<1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.ov_weipobfCard = 2.4
sgs.ai_use_priority.ov_weipobfCard = 3.8

sgs.ai_skill_cardask["ov_chenshi0"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
	if cards:length()<2 then return "." end
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	local owner = data:toPlayer()
	if not self:isEnemy(owner) then
		return cards[1]:getEffectiveId()
	end
end

sgs.ai_skill_cardask["ov_chenshi1"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
	if cards:length()<1 then return "." end
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	local owner = data:toPlayer()
	if not self:isEnemy(owner) or self:isWeak() then
		return cards[1]:getEffectiveId()
	end
end

sgs.ai_can_damagehp.ov_moushi = function(self,from,card,to)
	return card and self:canLoseHp(from,card,to)
	and to:getMark("&ov_moushi+"..card:getSuitString().."_char")>0
end

function SmartAI:useCardBinglinchengxia(card,use)
	self:sort(self.enemies,"hp")
	local extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if CanToCard(card,self.player,ep)
		and self:isGoodTarget(ep,self.enemies,dummyCard())
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if isCurrent(use,ep) then continue end
		if CanToCard(card,self.player,ep) and not self:isFriend(ep)
		and self:isGoodTarget(ep,self.enemies,dummyCard())
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end
sgs.ai_use_priority.Binglinchengxia = 4.4
sgs.ai_keep_value.Binglinchengxia = 4
sgs.ai_use_value.Binglinchengxia = 3.3
sgs.ai_card_intention.Binglinchengxia = 44

sgs.ai_nullification.Binglinchengxia = function(self,trick,from,to,positive)
    local null_num = self:getCardsNum("Nullification")
    if positive
	then
		if self:isFriend(to)
		then
			if null_num>1 then return not to:getArmor()
			else return self:isWeak(to) end
		end
	else
		if self:isFriend(from) and self:isEnemy(to)
		then return self:isWeak(to) end
	end
end

sgs.ai_skill_choice.ov_weipo = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"_ov_binglinchengxia")
	then return "_ov_binglinchengxia" end
	for c,cn in sgs.list(items)do
		c = PatternsCard(cn,nil,true)
		if c and c:isAvailable(self.player)
		then return cn end
	end
end

sgs.ai_skill_invoke.ov_fengpo = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_choice.ov_fengpo = function(self,choices,data)
	local use = data:toCardUse()
	local items = choices:split("+")
	local x = 0
	for _,c in sgs.list(use.to:at(0):getHandcards())do
		if c:isRed() and self.player:getMark("ov_fengpo_deathdamage")>0
		or c:getSuit()==3
		then x = x+1 end
		if c:isKindOf("Jink")
		and use.card:isKindOf("Slash")
		then return items[1] end
	end
	return items[2]
end

sgs.ai_skill_invoke.ov_moukui = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_choice.ov_moukui = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target and not self:isFriend(target)
	and #items>2 then return items[3] end
	return self:isFriend(target) and items[1] or #items>1 and items[2]
end

sgs.ai_skill_choice.ov_mouzhu = function(self,choices)
	local items = choices:split("+")
	return self:getCardsNum("Jink")>0 and items[1] or #items>1 and items[2]
end

addAiSkills("ov_mouzhu").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_mouzhuCard:.:")
end

sgs.ai_skill_use_func["#ov_mouzhuCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if ep:getHp()>=self.player:getHp()
		and self.player:getAliveSiblings():length()>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if not self:isFriend(ep)
		and ep:getHp()>=self.player:getHp()
		and self.player:getAliveSiblings():length()>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.ov_mouzhuCard = 3.4
sgs.ai_use_priority.ov_mouzhuCard = 4.8

sgs.ai_skill_cardask["ov_mouzhu0"] = function(self,data,pattern)
	local owner = data:toPlayer()
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	if self:isFriend(owner) or self:isWeak()
	then
		return #cards>0 and cards[1]:getEffectiveId()
	end
end

sgs.ai_skill_use["@@ov_yanhuo"] = function(self,prompt)
	local valid = {}
	local destlist = self.player:getAliveSiblings()
	for _,friend in sgs.list(destlist)do
		if #valid>=self.player:getCardCount() then break end
		if not self:isFriend(friend) and friend:getCardCount()>0
		then table.insert(valid,friend:objectName()) end
	end
	if #valid>self.player:getCardCount()/2
	then
    	return string.format("#ov_yanhuoCard:.:->%s",table.concat(valid,"+"))
	end
	valid = {}
	for _,friend in sgs.list(destlist)do
		if self:isEnemy(friend) and friend:getCardCount()>self.player:getCardCount()/2
		then
			table.insert(valid,friend:objectName())
			return string.format("#ov_yanhuoCard:.:->%s",table.concat(valid,"+"))
		end
	end
	for _,friend in sgs.list(destlist)do
		if #valid>=self.player:getCardCount() then break end
		if not self:isFriend(friend) and friend:getCardCount()>0
		then table.insert(valid,friend:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_yanhuoCard:.:->%s",table.concat(valid,"+"))
	end
end

sgs.ai_use_revises.ov_shenxing = function(self,card,use)
	if card:isKindOf("DefensiveHorse")
	then return false
	elseif card:isKindOf("OffensiveHorse")
	and (self.player:getHandcardNum()>self.player:getHp() or not self:isWeak())
	then return false end
end

addAiSkills("ov_daoji").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if c:getTypeId()~=1
		then
			return sgs.Card_Parse("#ov_daojiCard:"..c:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#ov_daojiCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if self:doDisCard(ep,"e")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if self:doDisCard(ep,"he")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
		if self:doDisCard(ep,"he")
		and not self:isFriend(ep)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.ov_daojiCard = 6.4
sgs.ai_use_priority.ov_daojiCard = 4.8

sgs.ai_skill_invoke.ov_hengjiang = function(self,data)
	local use = data:toCardUse()
	local n = 0
    for _,target in sgs.list(self.room:getAllPlayers())do
		if self.player:inMyAttackRange(target)
		and not use.to:contains(target)
		then
			if use.card:isDamageCard()
			then
				if self:isFriend(target)
				then n = n-1 else n = n+1 end
			elseif self:isEnemy(use.to:at(0))
			and self:isEnemy(target)
			then n = n+1 end
		end
	end
	return n>0
end

sgs.ai_skill_playerchosen.ov_gezhi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_gezhi = -55

sgs.ai_skill_invoke.ov_yujue = function(self,data)
	local target = data:toPlayer()
	if target
	then
		self["ov_yujue_to_"..target:objectName()] = self:isFriend(target)
		return self:isFriend(target)
	end
end

addAiSkills("ov_yujuevs").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for n,lh in sgs.list(self.room:findPlayersBySkillName("ov_yujue"))do
		n = 2-self.player:getMark(lh:objectName().."ov_yujue-PlayClear")
		if lh:hasLordSkill("ov_fengqi") and self.player:getKingdom()=="qun" then n = n+2 end
		if n<1 or #cards<1 then continue end
		if self:isFriend(lh,self.player)
		then
			local can = #self.toUse>0 and self.player:getMark("ov_yujue2-Clear")<1
			for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
				if self.player:getMark("ov_yujue1-Clear")<1
				and self.player:inMyAttackRange(p)
				and self:doDisCard(p,"hej")
				and not self:isFriend(p)
				then can = true end
			end
			can = can and #cards>3 and (self["ov_yujue_to_"..self.player:objectName()]
							or self.player:getMark("ov_yujue_use-PlayClear")<1
							or self.player:getHandcardNum()>self.player:getMaxCards() and self.player:getHandcards():contains(cards[1]))
			local parse = sgs.Card_Parse("#ov_yujuevsCard:"..cards[1]:getEffectiveId()..":")
			self.ov_yujuevs_to = lh
			assert(parse)
			if can then return parse end
		else
			local PC = self:poisonCards("h")
			if #PC>0
			then
				self.ov_yujuevs_to = lh
				return sgs.Card_Parse("#ov_yujuevsCard:"..PC[1]:getEffectiveId()..":")
			end
		end
	end
end

sgs.ai_skill_use_func["#ov_yujuevsCard"] = function(card,use,self)
	if self.ov_yujuevs_to
	then
		use.card = card
		self.player:addMark("ov_yujue_use-PlayClear")
		use.to:append(self.ov_yujuevs_to)
	end
end

sgs.ai_use_value.ov_yujuevsCard = 5.4
sgs.ai_use_priority.ov_yujuevsCard = 4.8

sgs.ai_skill_invoke.ov_fengqi = function(self,data)
	return true
end

sgs.ai_skill_cardask["ov_gezhi0"] = function(self,data,pattern)
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	return #cards>1 and cards[1]:getEffectiveId()
	or #cards>0 and self:getKeepValue(cards[1])<3 and cards[1]:getEffectiveId()
end

sgs.ai_skill_invoke.ov_lingfa = function(self,data)
	return true
end

sgs.ai_skill_cardask["ov_lingfa1"] = function(self,data,pattern)
	local owner = data:toPlayer()
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	if self:canDamageHp(owner) and not self:isWeak() then return "." end
	return #cards>0 and cards[1]:getEffectiveId() or "."
end

sgs.ai_skill_cardask["ov_lingfa2"] = function(self,data,pattern)
	local owner = data:toPlayer()
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	if self:canDamageHp(owner) and not self:isWeak() then return "." end
	if self:isFriend(owner) or self:isWeak()
	then
		return #cards>0 and cards[1]:getEffectiveId() or "."
	end
end

sgs.ai_skill_invoke.ov_zhian = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_choice.ov_zhian = function(self,choices,data)
	local use = data:toCardUse()
	local items = choices:split("+")
	if self:isEnemy(use.from)
	then
		if self:isWeak(use.from)
		then return items[#items]
		elseif use.card:isKindOf("DelayedTrick")
		and self:isFriend(use.to:at(0))
		and self.player:getHandcardNum()>2
		then return items[2]
		elseif use.card:isKindOf("EquipCard")
		and self.player:getHandcardNum()>2
		then return items[2] end
	elseif not self:isFriend(use.from)
	and use.card:isKindOf("DelayedTrick")
	and self:isFriend(use.to:at(0))
	then return items[2] end
	return items[1]
end

sgs.ai_skill_cardask["ov_fengji0"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
  	for n,c in sgs.list(cards)do
		n = self:getRestCardsNum(c:getClassName())
		if n>1
		then
			n = n>3 and 3 or n
			sgs.ai_skill_choice.shifa = "shifa"..math.random(1,n)
			return c:getEffectiveId()
		end
	end
end

sgs.ai_skill_invoke.ov_budao = function(self,data)
	return self.player:getLostHp()>1
end

sgs.ai_skill_playerchosen.ov_budao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_budao = -55

addAiSkills("ov_sfzhouhu").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
   	for i,c in sgs.list(cards)do
		local n = self.player:getLostHp()
		if c:isRed() and i<=#cards/2 and n>0
		then
			n = n>3 and 3 or n
			sgs.ai_skill_choice.shifa = "shifa"..n
			return sgs.Card_Parse("#ov_sfzhouhuCard:"..c:getEffectiveId()..":")
		end
	end
   	for i,c in sgs.list(cards)do
		if c:isRed() and i<=#cards/2
		then
			local n = self.player:getLostHp()
			local to = self.player:getNextAlive()
			while to:objectName()~=self.player:objectName()do
				if self:isEnemy(to)
				and math.random()>0.5
				then n = n+1 end
				to = to:getNextAlive()
			end
			n = n>3 and 3 or n
			n = n>self.player:getHp() and self.player:getHp() or n
			n = n==1 and not self.player:isWounded() and n-1 or n
			sgs.ai_skill_choice.shifa = "shifa"..n
			return n>0 and sgs.Card_Parse("#ov_sfzhouhuCard:"..c:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#ov_sfzhouhuCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_sfzhouhuCard = 3.4
sgs.ai_use_priority.ov_sfzhouhuCard = -0.8

addAiSkills("ov_sffengqi").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
   	for i,c in sgs.list(cards)do
		if c:isBlack() and i<#cards/2
		then
			local n = self.player:getLostHp()
			local to = self.player:getNextAlive()
			while to:objectName()~=self.player:objectName()do
				if self:isEnemy(to)
				and math.random()>0.5
				then n = n+1 end
				to = to:getNextAlive()
			end
			n = n>3 and 3 or n<1 and math.random(1,3) or n
			n = n>self.player:getHp() and self.player:getHp() or n
			sgs.ai_skill_choice.shifa = "shifa"..n
			return sgs.Card_Parse("#ov_sffengqiCard:"..c:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#ov_sffengqiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_sffengqiCard = 3.4
sgs.ai_use_priority.ov_sffengqiCard = -0.8

addAiSkills("ov_sffengqi").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
   	for i,c in sgs.list(cards)do
		if c:getTypeId()~=1 and i<=#cards/2
		then
			local n = self.player:getLostHp()
			local to = self.player:getNextAlive()
			while to:objectName()~=self.player:objectName()do
				if self:isEnemy(to)
				and math.random()>0.5
				then n = n+1 end
				to = to:getNextAlive()
			end
			n = n>3 and 3 or n<1 and math.random(1,3) or n
			n = n>self.player:getHp() and self.player:getHp() or n
			sgs.ai_skill_choice.shifa = "shifa"..n
			return sgs.Card_Parse("#ov_sffengqiCard:"..c:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#ov_sffengqiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_sffengqiCard = 3.4
sgs.ai_use_priority.ov_sffengqiCard = -0.8

addAiSkills("ov_gongqi").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
  	for i,c in sgs.list(cards)do
		for it,ct in sgs.list(self.toUse)do
			if c:getEffectiveId()~=ct:getEffectiveId()
			and c:getSuit()==ct:getSuit()
			and ct:isKindOf("Slash")
			then
				return sgs.Card_Parse("#ov_gongqiCard:"..c:getEffectiveId()..":")
			end
		end
	end
  	for i,c in sgs.list(cards)do
		if c:isKindOf("EquipCard")
		and #self.enemies>0
		and i<#cards/2
		then
			return sgs.Card_Parse("#ov_gongqiCard:"..c:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#ov_gongqiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_gongqiCard = 3.4
sgs.ai_use_priority.ov_gongqiCard = 3.8

sgs.ai_skill_playerchosen.ov_gongqi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"e")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"e")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"he")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and self:doDisCard(target,"e")
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_gongqi = 55

addAiSkills("ov_jiefan").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_jiefanCard:.:")
end

sgs.ai_skill_use_func["#ov_jiefanCard"] = function(card,use,self)
	self:sort(self.friends,"hp")
	for n,ep in sgs.list(self.friends)do
		n = 0
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if p:inMyAttackRange(ep)
			then n = n+1 end
		end
		if n>#self.friends/2
		and n>ep:getHp()
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.ov_jiefanCard = 4.4
sgs.ai_use_priority.ov_jiefanCard = 4.8

addAiSkills("ov_fuzuan").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_fuzuanCard:.:")
end

sgs.ai_skill_use_func["#ov_fuzuanCard"] = function(card,use,self)
	self:sort(self.enemies,"handcard",true)
	self:sort(self.friends,"hp")
	if self.toUse
	then
		for d,c in sgs.list(self.toUse)do
			if c:isKindOf("Slash")
			then
				d = self:aiUseCard(c)
				if d.card and d.to
				then
					for i,to in sgs.list(d.to)do
						if not to:hasSkill("ov_feifu") then continue end
						i = to:getChangeSkillState("ov_feifu")
						if i<2 or to:getCardCount()<1 then continue end
						use.card = card
						use.to:append(to)
						return
					end
				end
			end
		end
		for _,ep in sgs.list(self.enemies)do
			if not ep:hasSkill("ov_feifu") then continue end
			i = ep:getChangeSkillState("ov_feifu")
			if i<2 or ep:getCardCount()<1 then continue end
			use.card = card
			use.to:append(ep)
			return
		end
		for _,ep in sgs.list(self.friends)do
			if not ep:hasSkill("ov_feifu") then continue end
			i = ep:getChangeSkillState("ov_feifu")
			if i>1 then continue end
			use.card = card
			use.to:append(ep)
			return
		end
		for d,c in sgs.list(self.toUse)do
			if c:isKindOf("Slash")
			then
				d = self:aiUseCard(c)
				if d.card and d.to
				then
					for i,to in sgs.list(d.to)do
						if not to:hasSkill("ov_feifu") then continue end
						i = to:getChangeSkillState("ov_feifu")
						if i<2 then continue end
						use.card = card
						use.to:append(to)
						return
					end
				end
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if not ep:hasSkill("ov_feifu") then continue end
		i = ep:getChangeSkillState("ov_feifu")
		if i<2 or ep:getCardCount()<1 then continue end
		use.card = card
		use.to:append(ep)
		return
	end
	for _,ep in sgs.list(self.friends)do
		if not ep:hasSkill("ov_feifu") then continue end
		i = ep:getChangeSkillState("ov_feifu")
		if i>1 then continue end
		use.card = card
		use.to:append(ep)
		return
	end
	for _,ep in sgs.list(self.enemies)do
		if not ep:hasSkill("ov_feifu") then continue end
		i = ep:getChangeSkillState("ov_feifu")
		if i<2 then continue end
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.ov_fuzuanCard = 2.4
sgs.ai_use_priority.ov_fuzuanCard = 3.8

sgs.ai_skill_use["@@ov_fuzuan"] = function(self,prompt)
	local destlist = self.room:getAlivePlayers()
    destlist = self:sort(destlist,"hp")
	for n,p in sgs.list(destlist)do
		if not p:hasSkill("ov_feifu") then continue end
		n = p:getChangeSkillState("ov_feifu")
		if self:isEnemy(p) and n>1
		then return string.format("#ov_fuzuanCard:.:->%s",p:objectName()) end
	end
	for n,p in sgs.list(destlist)do
		if not p:hasSkill("ov_feifu") then continue end
		n = p:getChangeSkillState("ov_feifu")
		if self:isFriend(p) and n<2
		then return string.format("#ov_fuzuanCard:.:->%s",p:objectName()) end
	end
	for n,p in sgs.list(destlist)do
		if not p:hasSkill("ov_feifu") then continue end
		n = p:getChangeSkillState("ov_feifu")
		if not self:isFriend(p) and n<2
		or self:isFriend(p) and n>1
		then continue end
		return string.format("#ov_fuzuanCard:.:->%s",p:objectName())
	end
end

sgs.ai_skill_invoke.ov_congqi = function(self,data)
	return #self.friends_noself>0
end

sgs.ai_skill_playerchosen.ov_congqi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end
sgs.ai_playerchosen_intention.ov_congqi = -55

sgs.ai_skill_choice.ov_fuzuan = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"ov_feifu")
	then return "ov_feifu" end
end

sgs.ai_skill_invoke.ov_zhenxi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
		and target:getCardCount()>0
	end
end

sgs.ai_skill_choice.ov_zhenxi = function(self,choices)
	local items = choices:split("+")
	if #items>2 then return items[3] end
end

sgs.ai_skill_use["@@ov_kaiji"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAllPlayers()
    destlist = self:sort(destlist,"hp")
	for _,p in sgs.list(destlist)do
		if #valid>=self.player:getMark("ov_kaiji") then break end
		if self:isFriend(p) then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>self.player:getMark("ov_kaiji")/2 then break end
		if not self:isEnemy(p) and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_kaijiCard:.:->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_invoke.ov_shepan = function(self,data)
	local target = data:toPlayer()
	if target then return true end
	local use = self.player:getTag("ov_shepan"):toCardUse()
	if use and use.card
	then
		if use.card:isDamageCard()
		then return true
		elseif use.to:contains(use.from)
		then return false
		elseif self:isEnemy(use.from)
		then return true end
	end
end

sgs.ai_skill_choice.ov_shepan = function(self,choices,data)
	local items = choices:split("+")
	local use = data:toCardUse()
	if self:isFriend(use.from)
	then
		if self:doDisCard(use.from,"ej")
		then return items[2]
		elseif use.card:isDamageCard()
		and self:isWeak()
		then
			local n = use.from:getHandcardNum()-self.player:getHandcardNum()
			if n==1 then return items[2] end
		end
	else
		if self:doDisCard(use.from,"ej")
		then return items[2]
		elseif use.card:isDamageCard()
		then
			local n = use.from:getHandcardNum()-self.player:getHandcardNum()
			if n==1 then return items[2] end
		end
	end
	return items[1]
end

sgs.ai_skill_use["@@ov_fenghan"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAllPlayers()
    destlist = self:sort(destlist,"hp")
	for _,p in sgs.list(destlist)do
		if #valid>=self.player:getMark("ov_fenghan") then break end
		if self:isFriend(p)
		then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>=self.player:getMark("ov_fenghan") then break end
		if not self:isEnemy(p)
		and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_fenghanCard:.:->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_playerchosen.ov_congji = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_congji = -55

sgs.ai_guhuo_card.ov_yingji = function(self,toname,class_name)
	if self.player:getPhase()==sgs.Player_NotActive
	and self.player:isKongcheng()
	then
        local c = dummyCard(toname)
		if c:getTypeId()==1 or c:isNDTrick()
	    then
           	return "#ov_yingjiCard:.:"..toname
        end
	end
end

sgs.ai_skill_invoke.ov_shanghe = function(self,data)
	return self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<1
end

sgs.ai_skill_invoke.ov_jieyu = function(self,data)
	return self.room:getDiscardPile():length()>self.player:getHandcardNum()
	and self:getCardsNum("Peach")<1
end

addAiSkills("ov_sidai").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	local fs = dummyCard("slash")
	fs:setSkillName("ov_sidai")
  	for i,c in sgs.list(cards)do
		if c:getTypeId()==1
		then fs:addSubcard(c) end
	end
  	local d = self:aiUseCard(fs)
	if d.card and d.to
	and fs:subcardsLength()>1
	then
		for i,to in sgs.list(d.to)do
			if to:getHandcardNum()<2
			then return fs end
		end
	end
end

sgs.ai_skill_cardask["ov_sidai0"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		i = self:getCards("Jink")
		if c:getTypeId()==1 and #i>0
		and i[1]:getEffectiveId()~=c:getEffectiveId()
		then return c:getEffectiveId() end
	end
end


sgs.ai_skill_invoke.ov_shigong = function(self,data)
	return #self.friends>0
	and self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<1
end

addAiSkills("ov_zhuidu").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_zhuiduCard:.:")
end

sgs.ai_skill_use_func["#ov_zhuiduCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if ep:getHp()<=self.enemies[1]:getHp()
		and self:doDisCard(ep,"e")
		and ep:isWounded()
		and ep:isFemale()
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if ep:isWounded()
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.room:getAlivePlayers())do
		if not self:isFriend(ep)
		and ep:isWounded()
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.ov_zhuiduCard = 4.4
sgs.ai_use_priority.ov_zhuiduCard = 1.8

sgs.ai_skill_choice.ov_zhuidu = function(self,choices)
	local items = choices:split("+")
	if #items>2 then return items[3] end
	return items[1]
end

sgs.ai_skill_playerchosen.ov_xiongzheng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	self:sort(destlist,"hp",true)
	return not self:isWeak(destlist[1])
	and #self.enemies>0
	and destlist[1]
end
sgs.ai_playerchosen_intention.ov_xiongzheng = 55

sgs.ai_skill_use["@@ov_xiongzheng"] = function(self,prompt)
	local valid1,valid2 = {},{}
	local destlist = self.room:getAllPlayers()
    destlist = self:sort(destlist,"hp")
	local to = self.player:getTag("ov_xiongzheng"):toPlayer()
	for _,p in sgs.list(destlist)do
		if self:isFriend(p)
		and p:getMark("&ov_xiongzheng+damage+#"..to:objectName())>0
		then table.insert(valid1,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if table.contains(valid1,p:objectName())
		then continue end
		if not self:isEnemy(p) and #valid1<#destlist/2
		and p:getMark("&ov_xiongzheng+damage+#"..to:objectName())>0
		then table.insert(valid1,p:objectName()) end
	end
	for d,p in sgs.list(destlist)do
		d = dummyCard()
		d:setSkillName("_ov_xiongzheng")
		if table.contains(valid2,p:objectName())
		then continue end
		if self.player:isProhibited(p,d) then continue end
		if self:isEnemy(p) and p:getMark("&ov_xiongzheng+damage+#"..to:objectName())<1
		then table.insert(valid2,p:objectName()) end
	end
	for d,p in sgs.list(destlist)do
		d = dummyCard()
		d:setSkillName("_ov_xiongzheng")
		if table.contains(valid2,p:objectName())
		then continue end
		if self.player:isProhibited(p,d)
		or #valid2>=#destlist/2 or self:isFriend(p)
		or p:getMark("&ov_xiongzheng+damage+#"..to:objectName())>0
		then continue end
		table.insert(valid2,p:objectName())
	end
	valid1 = #valid1>#valid2 and valid1 or valid2
	if #valid1>0
	then
    	return string.format("#ov_xiongzhengCard:.:->%s",table.concat(valid1,"+"))
	end
end

addAiSkills("ov_luannianvs").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for i,owner in sgs.list(self.room:findPlayersBySkillName("ov_luannian"))do
		local toids,to = {},owner:getTag("ov_xiongzheng"):toPlayer()
		if not owner:hasLordSkill("ov_luannian")
		or owner:getMark("ov_luannian-PlayClear")>0
		or not to or not self:isEnemy(to)
		then continue end
		for _,tc in sgs.list(cards)do
			if #toids>=owner:getMark("&ov_luannian_lun") then break end
			table.insert(toids,tc:getEffectiveId())
		end
		self.ov_luannian_to = owner
		if #toids<=to:getHp()
		then return sgs.Card_Parse("#ov_luannianCard:"..table.concat(toids,"+")..":") end
	end
end

sgs.ai_skill_use_func["#ov_luannianCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	if self.ov_luannian_to
	then
		use.card = card
		use.to:append(self.ov_luannian_to)
	end
end

sgs.ai_use_value.ov_luannianCard = 2.4
sgs.ai_use_priority.ov_luannianCard = 1.8

sgs.ai_skill_cardask["ov_qingtao0"] = function(self,data,pattern)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
  	for n,c in sgs.list(cards)do
		if c:getTypeId()~=1 or c:isKindOf("Analeptic")
		then return c:getEffectiveId() end
	end
	return #cards>1 and cards[1]:getEffectiveId() or "."
end

addAiSkills("ov_bingde").getTurnUseCard = function(self)
	local can = #self.toUse<2
	local suits = {"spade","club","heart","diamond","no_suit"}
	for _,s in sgs.list(suits)do
		if self.player:getMark(s.."no_bingde-PlayClear")<1
		and self.player:getMark(s.."ov_bingde-PlayClear")>0
		then can = can and true end
	end
	if not can then return end
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
  	for s,c in sgs.list(cards)do
		s = c:getSuitString()
		if self.player:getMark(s.."ov_bingde-PlayClear")>1
		and self.player:getMark(s.."no_bingde-PlayClear")<1
		then
			self.ov_bingde_choice = s
			return sgs.Card_Parse("#ov_bingdeCard:"..c:getEffectiveId()..":")
		end
	end
  	for s,c in sgs.list(cards)do
		s = c:getSuitString()
		if self.player:getMark(s.."ov_bingde-PlayClear")>0
		and self.player:getMark(s.."no_bingde-PlayClear")<1
		then
			self.ov_bingde_choice = s
			return sgs.Card_Parse("#ov_bingdeCard:"..c:getEffectiveId()..":")
		end
	end
	for _,s in sgs.list(suits)do
		if #cards>2 and self.player:getMark(s.."no_bingde-PlayClear")<1
		and self.player:getMark(s.."ov_bingde-PlayClear")>0
		then
			self.ov_bingde_choice = s
			return sgs.Card_Parse("#ov_bingdeCard:"..cards[1]:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#ov_bingdeCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_bingdeCard = 5.4
sgs.ai_use_priority.ov_bingdeCard = 2.8

sgs.ai_skill_choice.ov_bingde = function(self,choices)
	local items = choices:split("+")
  	for _,pm in sgs.list(items)do
		if self.ov_bingde_choice==pm
		then return pm end
	end
  	for _,pm in sgs.list(items)do
		if self.player:getMark(pm.."ov_bingde-PlayClear")>1
		then return pm end
	end
  	for _,pm in sgs.list(items)do
		if self.player:getMark(pm.."ov_bingde-PlayClear")>0
		then return pm end
	end
end

addAiSkills("ov_xiongsi").getTurnUseCard = function(self)
	local slash = dummyCard()
	slash:setSkillName("ov_xiongsi")
	self.ov_xiongsi_to = nil
	if slash:isAvailable(self.player)
	then
		local use = {to=sgs.SPlayerList(),current_targets={},isDummy=true}
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if p:getMark("ov_xiongsi")>0 then table.insert(use.current_targets,p) end
		end
		local d = self:aiUseCard(slash,use)
		if d.card and d.to
		then
			for _,to in sgs.list(d.to)do
				if to:getMark("ov_xiongsi")<1
				then
					self.ov_xiongsi_to = to
					break
				end
			end
		end
	end
	return self.ov_xiongsi_to and sgs.Card_Parse("#ov_xiongsiCard:.:")
end

sgs.ai_skill_use_func["#ov_xiongsiCard"] = function(card,use,self)
	if self.ov_xiongsi_to
	then
		use.card = card
		use.to:append(self.ov_xiongsi_to)
	end
end

sgs.ai_use_value.ov_xiongsiCard = 2.4
sgs.ai_use_priority.ov_xiongsiCard = 1.8

sgs.ai_skill_playerchosen.ov_linglu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getHandcardNum()<3
		then return target end
	end
	self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and target:getHandcardNum()>3
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_linglu = 55

sgs.ai_skill_invoke.ov_linglu = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_playerchosen.ov_juntun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard",true)
	local dying = self.room:getCurrentDyingPlayer()
    for _,target in sgs.list(destlist)do
		if not target:hasSkill("ov_xiongjun")
		and (not dying or dying:objectName()~=target:objectName())
		and self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not target:hasSkill("ov_xiongjun")
		and (not dying or dying:objectName()~=target:objectName())
		and not self:isEnemy(target)
		then return target end
	end
end

addAiSkills("ov_xiongxi").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	local toids = {}
	local n = 5-self.player:getMark("@ov_baonieNum")
  	for _,c in sgs.list(cards)do
		if #toids>=n then break end
		table.insert(toids,c:getEffectiveId())
	end
	return n<4 and #toids>=n and sgs.Card_Parse("#ov_xiongxiCard:"..table.concat(toids,"+")..":")
end

sgs.ai_skill_use_func["#ov_xiongxiCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if ep:getMark("ov_xiongxi-Clear")<1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.ov_xiongxiCard = 2.4
sgs.ai_use_priority.ov_xiongxiCard = 1.8

sgs.ai_skill_invoke.ov_xiafeng = function(self,data)
	local bn = self.player:getTag("ov_baonieNum"):toInt()
	if bn<1 then return end
	bn = bn>3 and 3 or bn
  	for _,c in sgs.list(self.player:getCards("h"))do
		if c:isDamageCard()
		then
			if c:getTypeId()==1
			or c:isKindOf("AOE")
			or c:isKindOf("SingleTargetTrick")
			then
				sgs.ai_use_priority[c:getClassName()] = sgs.ai_use_priority[c:getClassName()]+5
				c:setFlags("AIGlobal_KillOff")
			end
		end
	end
	self.player:setFlags("InfinityAttackRange")
	local touse = self:getTurnUse()
	local n = 0
	for i=1,bn do
		if #touse>=i and touse[i]:isDamageCard()
		then n = n+1 end
	end
	n = n<2 and self.player:getHandcardNum()>self.player:getMaxCards() and math.random(1,bn) or n
  	for _,c in sgs.list(self.player:getCards("h"))do
		c:setFlags("-AIGlobal_KillOff")
	end
	self.player:setFlags("-InfinityAttackRange")
	sgs.ai_skill_choice.ov_xiafeng = ""..n
	return n>1
end

sgs.ai_use_revises.ov_xiafeng = function(self,card,use)
	if self.player:getMark("ov_xiafeng-Clear")>0
	then
		if card:isDamageCard()
		then
			if card:getTypeId()==1 or card:isKindOf("AOE") or card:isKindOf("SingleTargetTrick")
			then sgs.ai_use_priority[card:getClassName()] = sgs.ai_use_priority[card:getClassName()]+5 end
		elseif card:isKindOf("EquipCard")
		then return false end
	end
end

sgs.ai_skill_choice.ov_zhengjian = function(self,choices)
	local items = choices:split("+")
	if #items>1 and math.random(1,5)>=#items
	then return items[2] end
	return items[1]
end

sgs.ai_skill_invoke.ov_zhengjian = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
	return math.random(1,5)<3
end

sgs.ai_guhuo_card.ov_zhuitingvs = function(self,toname,class_name)
    local handcards = self:addHandPile()
    handcards = self:sortByKeepValue(handcards,nil,true) -- 按保留值排序
	for _,p in sgs.list(self.player:getAliveSiblings())do
		if (self.player:getKingdom()=="qun" or self.player:getKingdom()=="wei")
		and p:hasLordSkill("ov_zhuiting")
		and class_name=="Nullification"
		and p:getMark("ov_zhuiting")>0
		then
			for c,h in sgs.list(handcards)do
				if h:getColor()==p:getMark("ov_zhuiting")-1
				then
					c = dummyCard(toname)
					c:setSkillName("ov_zhuiting")
					c:addSubcard(h)
					return c:toString()
				end
			end
		end
	end
end

sgs.ai_skill_invoke.ov_niju = function(self,data)
	self.ov_niju_choice = 1
	local pindian = data:toPindian()
	local qun = self.room:getLieges("qun",self.player):length()
	if pindian.from:objectName()==self.player:objectName()
	then
		if self:isFriend(pindian.to)
		then
			if pindian.from_number>pindian.to_number
			then
				sgs.ai_skill_askforag.ov_niju = pindian.to_card:getEffectiveId()
				if pindian.from_number<=pindian.to_number+qun
				then return true end
				self.ov_niju_choice = 2
				sgs.ai_skill_askforag.ov_niju = pindian.from_card:getEffectiveId()
				if pindian.from_number-qun<=pindian.to_number
				then return true end
			end
		else
			if pindian.from_number<=pindian.to_number
			then
				sgs.ai_skill_askforag.ov_niju = pindian.from_card:getEffectiveId()
				if pindian.from_number+qun>=pindian.to_number
				then return true end
				self.ov_niju_choice = 2
				sgs.ai_skill_askforag.ov_niju = pindian.to_card:getEffectiveId()
				if pindian.from_number>=pindian.to_number-qun
				then return true end
			end
		end
	else
		if self:isFriend(pindian.from)
		then
			if pindian.from_number<=pindian.to_number
			then
				sgs.ai_skill_askforag.ov_niju = pindian.from_card:getEffectiveId()
				if pindian.from_number+qun>pindian.to_number
				then return true end
				self.ov_niju_choice = 2
				sgs.ai_skill_askforag.ov_niju = pindian.to_card:getEffectiveId()
				if pindian.from_number>pindian.to_number-qun
				then return true end
			end
		else
			if pindian.from_number>pindian.to_number
			then
				sgs.ai_skill_askforag.ov_niju = pindian.to_card:getEffectiveId()
				if pindian.from_number<=pindian.to_number+qun
				then return true end
				self.ov_niju_choice = 2
				sgs.ai_skill_askforag.ov_niju = pindian.from_card:getEffectiveId()
				if pindian.from_number-qun<=pindian.to_number
				then return true end
			end
		end
	end
end

sgs.ai_skill_choice.ov_niju = function(self,choices)
	local items = choices:split("+")
	if self.ov_niju_choice then return items[self.ov_niju_choice] end
	return items[1]
end

sgs.ai_skill_discard.ov_chongwang = function(self)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to = self.player:getTag("ov_chongwang"):toPlayer()
	if self:getCardsNum("AOE")>1 and self:isFriend(to)
	then table.insert(to_cards,cards[1]:getEffectiveId())
	elseif self:isEnemy(to) and to:getHandcardNum()>3
	and to:inMyAttackRange(self.player) and self:isWeak()
	then table.insert(to_cards,cards[1]:getEffectiveId()) end
 	return to_cards
end

addAiSkills("ov_juxiangvs").getTurnUseCard = function(self)
	local cards = self.player:getCards("e")
	cards = self:sortByKeepValue(cards)
	for i,owner in sgs.list(self.room:findPlayersBySkillName("ov_juxiang"))do
		if owner:getMark("ov_juxiang-PlayClear")>0
		or not owner:hasLordSkill("ov_juxiang")
		or self.player:getKingdom()~="qun"
		or not self:isFriend(owner)
		then continue end
		i = nil
		local function can_juxiang(n)
			local x = 0
			for _,h in sgs.list(self.player:getCards("h"))do
				if h:getTypeId()~=3 then continue end
				local e = h:getRealCard():toEquipCard():location()
				if e==n then x = x+1 end
			end
			return x
		end
		self.ov_juxiang_to = owner
		for _,tc in sgs.list(cards)do
			if i then break end
			local e = tc:getRealCard():toEquipCard():location()
			if owner:hasEquipArea(e) then continue end
			i = tc:getEffectiveId()
		end
		for c,tc in sgs.list(cards)do
			if i then break end
			local e = tc:getRealCard():toEquipCard():location()
			c = owner:getEquip(e)
			if c and self:evaluateArmor(c,owner)>-5 then continue end
			if can_juxiang(e)>0 or self:isWeak(owner)
			then i = tc:getEffectiveId() end
		end
		if i
		then
			return sgs.Card_Parse("#ov_juxiangCard:"..i..":")
		end
	end
end

sgs.ai_skill_use_func["#ov_juxiangCard"] = function(card,use,self)
	if self.ov_juxiang_to
	then
		use.card = card
		use.to:append(self.ov_juxiang_to)
	end
end

sgs.ai_use_value.ov_juxiangCard = 2.4
sgs.ai_use_priority.ov_juxiangCard = 5.8

addAiSkills("ov_shijunvs").getTurnUseCard = function(self)
	for i,owner in sgs.list(self.room:findPlayersBySkillName("ov_shijun"))do
		if owner:getMark("ov_shijun-PlayClear")>0
		or not owner:hasLordSkill("ov_shijun")
		or owner:getPile("rice"):length()>0
		or self.player:getNextAlive()==owner
		or self.player:getKingdom()~="qun"
		or self:isEnemy(owner)
		then continue end
		self.ov_shijun_to = owner
		return sgs.Card_Parse("#ov_shijunCard:.:")
	end
end

sgs.ai_skill_use_func["#ov_shijunCard"] = function(card,use,self)
	if self.ov_shijun_to
	then
		use.card = card
		use.to:append(self.ov_shijun_to)
	end
end

sgs.ai_use_value.ov_shijunCard = 2.4
sgs.ai_use_priority.ov_shijunCard = 4.8

sgs.ai_skill_use["@@ov_polu"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAllPlayers()
    destlist = self:sort(destlist,"hp")
	for _,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_poluCard:.:->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_use["@@ov_dingzhen"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAllPlayers()
    destlist = self:sort(destlist,"hp")
	for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		and self.player:distanceTo(p)<=self.player:getHp()
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_dingzhenCard:.:->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_askforyiji.ov_youye = function(self,card_ids,tos)
	local to = self.room:getCurrent()
	local cards = ListI2C(card_ids)
	cards = self:sortByKeepValue(cards,self:isFriend(to))
	if self.player:hasFlag("Current")
	then return to,cards[1]:getEffectiveId() end
	local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to then return to,id end
	return self.player,cards[1]:getEffectiveId()
end

sgs.ai_can_damagehp.ov_youye = function(self,from,card,to)
	local target = self.room:getCurrent()
	return self:canLoseHp(from,trick,to)
	and to:getPile("ov_xu"):length()>3
	and self:isFriend(target) and self:isFriend(to)
	and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
end

sgs.ai_skill_cardask["ov_dingzhen1"] = function(self,data,pattern)
	local to = data:toPlayer()
	return self:isEnemy(to) and self.player:inMyAttackRange(to)
	and self:getCardsNum("Slash")>math.random(0,2)
end

sgs.ai_skill_use["@@ov_qingkou"] = function(self,prompt)
	local duel = dummyCard("duel")
	duel:setSkillName("ov_qingkou")
	local d = self:aiUseCard(duel)
	if d.card and d.to
	then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,p:objectName())
		end
		return duel:toString().."->"..table.concat(tos,"+")
	end
end

sgs.ai_skill_invoke.ov_juchen = function(self,data)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for i,c in sgs.list(cards)do
		if i<=#cards/2 and c:isRed()
		then return true end
	end
	return cards[1]:isRed()
end

sgs.ai_skill_discard.ov_juchen = function(self)
	local to = self.room:getCurrent()
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for i,c in sgs.list(cards)do
		if i<=#cards/2 and c:isRed() and self:isFriend(to)
		then return {c:getEffectiveId()} end
	end
	for i,c in sgs.list(cards)do
		if i<=#cards/2 and not c:isRed() and self:isEnemy(to)
		then return {c:getEffectiveId()} end
	end
 	return {cards[1]:getEffectiveId()}
end

addAiSkills("ov_xingzhui").getTurnUseCard = function(self)
	if not self:isWeak()
	and #self.enemies>0
	then
		local n = self.player:getLostHp()-self:getCardsNum("Peach")
		local to = self.player:getNextAlive()
		while to:objectName()~=self.player:objectName()do
			if self:isEnemy(to)
			and math.random()>0.5
			then n = n+1 end
			to = to:getNextAlive()
		end
		n = n>3 and 3 or n<1 and math.random(1,3) or n
		n = n>self.player:getHp() and self.player:getHp() or n
		sgs.ai_skill_choice.shifa = "shifa"..n
		return sgs.Card_Parse("#ov_xingzhuiCard:.:")
	end
end

sgs.ai_skill_use_func["#ov_xingzhuiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_xingzhuiCard = 3.4
sgs.ai_use_priority.ov_xingzhuiCard = 0.8

sgs.ai_skill_playerchosen.ov_xingzhui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
	if self.player:getMark("ov_xingzhui_num")>=self.player:getMark("ov_xingzhui_x") then
		for _,target in sgs.list(destlist)do
			if self:isEnemy(target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not self:isFriend(target)
			then return target end
		end
	else
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not self:isEnemy(target)
			then return target end
		end
	end
	return destlist[1]
end

sgs.ai_skill_invoke.ov_jiekuang = function(self,data)
	local target = data:toPlayer()
	local use = self.player:getTag("ov_jiekuang"):toCardUse()
	if target and self:isWeak(target)
	and self:isFriend(target)
	then
		return use.card:isDamageCard()
		or self:isEnemy(use.from)
	end
end

sgs.ai_skill_choice.ov_jiekuang = function(self,choices)
	local items = choices:split("+")
	if self.player:isWounded() then return items[2] end
	return items[1]
end

addAiSkills("ov_luanlve").getTurnUseCard = function(self)
	local snatch = dummyCard("snatch")
	snatch:setSkillName("ov_luanlve")
	local n = self.player:getMark("&ov_luanlve")
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for i,c in sgs.list(cards)do
		if snatch:subcardsLength()>=n then break end
		if c:isKindOf("Slash") then snatch:addSubcard(c) end
	end
	self.ov_luanlve_to = nil
	if snatch:isAvailable(self.player)
	and snatch:subcardsLength()>=n
	then
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if p:getMark("ov_luanlve-PlayClear")>0
			then p:setFlags("aiNoTo") end
		end
		n = self:aiUseCard(snatch)
		if n.card and n.to
		then
			for _,to in sgs.list(n.to)do
				if to:getMark("ov_luanlve-PlayClear")<1
				then self.ov_luanlve_to = to break end
			end
		end
	end
	n = table.concat(sgs.QList2Table(snatch:getSubcards()),"+")
	return self.ov_luanlve_to and sgs.Card_Parse("#ov_luanlveCard:"..n..":")
end

sgs.ai_skill_use_func["#ov_luanlveCard"] = function(card,use,self)
	if self.ov_luanlve_to
	then
		use.card = card
		use.to:append(self.ov_luanlve_to)
	end
end

sgs.ai_use_value.ov_luanlveCard = 2.4
sgs.ai_use_priority.ov_luanlveCard = 4.8

addAiSkills("ov_jichou").getTurnUseCard = function(self)
	for _,p in sgs.list(patterns())do
		if self.player:getMark("ov_jichou_"..p)>0 then continue end
		local c = dummyCard(p)
		if c and c:isNDTrick() and c:isAvailable(self.player)
		and self:getCardsNum(c:getClassName())<1 then
			c:setSkillName("ov_jichou")
			local d = self:aiUseCard(c)
			if d.card then
				self.ov_jichouUse = d
				self.ov_zhengjianChoice = "ov_jichou-Clear"
				if c:canRecast() and d.to:length()<1 then continue end
				sgs.ai_use_priority.ov_jichouCard = sgs.ai_use_priority[c:getClassName()]
				return sgs.Card_Parse("#ov_jichouCard:.:")
			end
		end
	end
	sgs.ai_use_priority.ov_jichouCard = -1.8
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if #self.friends_noself>0
		and self.player:getMark("ov_jichoucard-PlayClear")<1
		and self.player:getMark("ov_jichou_"..c:objectName())>0 then
			self.ov_zhengjianChoice = "ov_jichoucard-PlayClear"
			return sgs.Card_Parse("#ov_jichouCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#ov_jichouCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_jichouCard = 2.4
sgs.ai_use_priority.ov_jichouCard = -1.8

sgs.ai_skill_choice.ov_jichou = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,self.ov_zhengjianChoice)
	then return self.ov_zhengjianChoice end
	if table.contains(items,self.ov_jichouUse.card:objectName())
	then return self.ov_jichouUse.card:objectName() end
end

sgs.ai_skill_use["@@ov_jichou"] = function(self,prompt)
	local cd = self.ov_jichouUse
	if cd.card then
		local tos = {}
		for _,p in sgs.list(cd.to)do
			table.insert(tos,p:objectName())
		end
		return cd.card:toString().."->"..table.concat(tos,"+")
	end
end

sgs.ai_guhuo_card.ov_jichou = function(self,toname,class_name)
	if self.player:getMark("ov_jichou_"..toname)<1
	and self.player:getMark("ov_jichou-Clear")<1 then
        local c = dummyCard(toname)
		if c and c:isNDTrick() and self:getCardsNum(class_name)<1
	    then return "#ov_jichoucard:.:"..toname end
	end
end

sgs.ai_skill_playerchosen.ov_jichou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end
sgs.ai_playerchosen_intention.ov_jichou = -55

sgs.ai_skill_invoke.ov_jilun = function(self,data)
	return #self.friends>0
end

sgs.ai_skill_choice.ov_jilun = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"ov_jilun2") then
		local n = items[1]:split("=")[2]
		n = n-0
		n = n*1.7
		for _,p in sgs.list(patterns())do
			if self.player:getMark("ov_jichou_"..p)<1
			or self.player:getMark("ov_jilun_"..p)>0
			then continue end
			local c = dummyCard(p)
			if c and c:isNDTrick()
			and c:isAvailable(self.player) then
				c:setSkillName("_ov_jilun")
				self.ov_jichou_cn = p
				local d = self:aiUseCard(c)
				if d.card and self:getUseValue(c)>n then
					if c:canRecast() and d.to:length()<1 then continue end
					self.ov_jichouUse = d
					return "ov_jilun2"
				end
			end
		end
		return items[1]
	elseif table.contains(items,self.ov_jichou_cn)
	then return self.ov_jichou_cn end
end

sgs.ai_skill_use["@@ov_fenwu"] = function(self,prompt)
	local duel = dummyCard()
	duel:setSkillName("ov_fenwu")
	local d = self:aiUseCard(duel)
	local names = self.player:getTag("ov_fenwu"):toString():split("+")
	if d.card and d.to:length()>0 and math.random(0,#names)>0
	and self.player:getHp()+self:getCardsNum("Peach")+self:getCardsNum("Analeptic")>1
	then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,p:objectName())
		end
		return duel:toString().."->"..table.concat(tos,"+")
	end
end

sgs.ai_skill_invoke.ov_fupan = function(self,data)
	local to = data:toString()
	if to~=""
	then
		local n = 0
		to = BeMan(self.room,to:split(":")[2])
		for _,ep in sgs.list(self.room:getOtherPlayers(self.player))do
			if not self:isEnemy(ep) then n = n+1 end
		end
		if to
		then
			return self:isEnemy(to)
			and (self:isWeak(to) or n<1)
		end
	end
	return #self.friends>0
end

sgs.ai_skill_askforyiji.ov_fupan = function(self,card_ids,tos)
	local cards = ListI2C(card_ids)
	cards = self:sortByKeepValue(cards)
	self:sort(self.enemies,"hp")
    for _,ep in sgs.list(self.enemies)do
		if ep:getMark("ov_fupan_damage_"..self.player:objectName())<1
		and self:getKeepValue(cards[1])<4 and self:isWeak(ep)
		then return ep,cards[1]:getEffectiveId() end
	end
	local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to and to:getMark("ov_fupan_damage_"..self.player:objectName())<1
	and to:objectName()~=self.player:objectName()
	then return to,id end
	to = self.room:getOtherPlayers(self.player)
	to = self:sort(to,"handcard")
    for _,ep in sgs.list(to)do
		if not self:isEnemy(ep)
		and ep:getMark("ov_fupan_"..self.player:objectName())<1
		then return ep,cards[1]:getEffectiveId() end
	end
    for _,ep in sgs.list(to)do
		if #cards>4 and ep:getMark("ov_fupan_"..self.player:objectName())<1
		and ep:getMark("ov_fupan_damage_"..self.player:objectName())<1
		then return ep,cards[1]:getEffectiveId() end
	end
	self:sort(self.friends_noself,"handcard")
    for _,ep in sgs.list(self.friends_noself)do
		if ep:getMark("ov_fupan_damage_"..self.player:objectName())<1
		then return ep,cards[1]:getEffectiveId() end
	end
    for _,ep in sgs.list(to)do
		if not self:isEnemy(ep)
		and ep:getMark("ov_fupan_damage_"..self.player:objectName())<1
		then return ep,cards[1]:getEffectiveId() end
	end
    for _,ep in sgs.list(to)do
		if ep:getMark("ov_fupan_damage_"..self.player:objectName())<1
		then return ep,cards[1]:getEffectiveId() end
	end
end

sgs.ai_can_damagehp.ov_fupan = function(self,from,card,to)
    for _,ep in sgs.list(self.enemies)do
		if ep:getMark("ov_fupan_damage_"..to:objectName())<1
		and self:isWeak(ep) and self:canLoseHp(from,card,to) and self:isFriend(to)
		and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
		then return true end
	end
end

addAiSkills("ov_mutao").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_mutaoCard:.:")
end

sgs.ai_skill_use_func["#ov_mutaoCard"] = function(card,use,self)
	local n = self:getCardsNum("Slash")
	if n>0
	then
		local to = self.player:getNextAlive(n)
		if self:isEnemy(to)
		then
			use.card = card
			use.to:append(self.player)
			return
		end
	end
	self:sort(self.enemies,"handcard",true)
	for _,ep in sgs.list(self.enemies)do
		if ep:getHp()>=self.player:getHp()
		and ep:getHandcardNum()>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	n = self.room:getAlivePlayers()
	n = self:sort(n,"handcard",true)
	for _,ep in sgs.list(n)do
		if ep:getHp()>=self.player:getHp()
		and ep:getHandcardNum()>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(n)do
		if ep:getHandcardNum()>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.ov_mutaoCard = 3.4
sgs.ai_use_priority.ov_mutaoCard = 2.8

sgs.ai_skill_invoke.ov_yimou = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
	end
end

sgs.ai_skill_choice.ov_yimou = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if #items>2 and self:isWeak(target)
	and not self:isWeak()
	then return items[3] end
	if #items>1 and #self.friends>1
	then return items[2] end
end

sgs.ai_skill_playerchosen.ov_yimou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end
sgs.ai_playerchosen_intention.ov_yimou = -55

addAiSkills("ov_kujian").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if #toids>=3 or #toids>=#cards/2 then break end
		for _,ep in sgs.list(self.friends_noself)do
			if c:isAvailable(ep)
			then
				table.insert(toids,c:getEffectiveId())
				break
			end
		end
	end
	if #toids<1 and #cards>2 and #self.friends_noself>0
	then table.insert(toids,cards[1]:getEffectiveId()) end
	return #toids>0 and sgs.Card_Parse("#ov_kujianCard:"..table.concat(toids,"+")..":")
end

sgs.ai_skill_use_func["#ov_kujianCard"] = function(card,use,self)
	self:sort(self.friends_noself,"handcard",true)
	for _,ep in sgs.list(self.friends_noself)do
		if ep:getHandcardNum()<5
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.ov_kujianCard = 3.4
sgs.ai_use_priority.ov_kujianCard = -1.8

sgs.ai_skill_playerchosen.ov_ruilian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:getHandcardNum()>2
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and target:getHandcardNum()>0
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_ruilian = -55

sgs.ai_skill_invoke.ov_ruilian = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isEnemy(target)
	end
end

sgs.ai_skill_invoke.ov_jiaohua = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
	end
end

sgs.ai_skill_playerchosen.ov_tanfeng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if (self:getCardsNum("Jink")>0 or not self:isWeak())
		and self:doDisCard(target,"ej")
		and self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if (self:getCardsNum("Jink")>0 or not self:isWeak())
		and self:doDisCard(target,"ej")
		and self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target)
		and self:getCardsNum("Jink")>0
		then return target end
	end
end

sgs.ai_skill_choice.ov_tanfeng = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items,"Player_Judge")
	then
		if self:isFriend(target)
		then
			if self:doDisCard(target,"j")
			then return "Player_Judge"
			elseif table.contains(items,"Player_Discard")
			then return "Player_Discard"
			elseif table.contains(items,"Player_Finish")
			then return "Player_Finish" end
		elseif table.contains(items,"Player_Play")
		then return "Player_Play"
		elseif table.contains(items,"Player_Draw")
		then return "Player_Draw"
		elseif table.contains(items,"Player_Finish")
		then return "Player_Finish" end
	end
	if self:canDamageHp(target)
	and not self:isWeak()
	then return items[1] end
	return items[2]
end

sgs.ai_skill_invoke.ov_xiawei = function(self,data)
	local n = self.player:getCardCount()
	n = n<2 and 2 or n
	n = math.random(1,n)
	n = n>4 and 4 or n
	sgs.ai_skill_choice.wangxing = ""..n
	return n>0
end

sgs.ai_card_priority.ov_xiawei = function(self,card)
	return self.player:getPile("&ov_wei"):contains(card:getEffectiveId()) and 0.5
end

sgs.ai_skill_discard.wangxing = function(self,x,n,optional,include_equip)
	local todn = self.player:getTag("wangxing_ai"):toString()
	local toids = sgs.ai_skill_discard[todn.."_wangxing"]
	if type(toids)=="function"
	then
		toids = toids(self,x,n,optional,include_equip)
		if type(toids)=="table" then return #toids>=n and toids or {} end
	end
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	toids = {}
	for i,c in sgs.list(cards)do
		if #toids>=n then break end
		table.insert(toids,c:getEffectiveId())
	end
 	return #toids>=n and toids or {}
end

sgs.ai_skill_playerchosen.ov_jianwei = function(self,players)
	local mc = self:getMaxCard()
	if not mc or mc:getNumber()+self.player:getAttackRange()<9 then return end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"e")
		and self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"he")
		and self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"e")
		and self:doDisCard(target,"j")
		and self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.ov_jianweibf = function(self,players)
	local mc = self:getMaxCard()
	if not mc or mc:getNumber()<10 then return end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if target:getWeapon()
		and self:isEnemy(target)
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_jianweibf = 55

addAiSkills("ov_jiange").getTurnUseCard = function(self)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for c,h in sgs.list(cards)do
		if h:getTypeId()~=1
		then
			c = dummyCard()
			c:setSkillName("ov_jiange")
			c:addSubcard(h)
			if c:isAvailable(self.player)
			then return c end
		end
	end
end

sgs.ai_guhuo_card.ov_jiange = function(self,toname,class_name)
	if class_name=="Slash"
	and self.player:getMark("ov_jiange-Clear")<1
	then
		local cards = self:addHandPile("he")
		cards = self:sortByKeepValue(cards,nil,true)
		for c,h in sgs.list(cards)do
			if h:getTypeId()~=1
			then
				c = dummyCard()
				c:setSkillName("ov_jiange")
				c:addSubcard(h)
				return c:toString()
			end
		end
	end
end

sgs.ai_card_priority.ov_jiange = function(self,card)
	if card:getSkillName()=="ov_jiange" then
		if self.player:getPhase()==sgs.Player_NotActive
		then return 1 else return -1 end
	end
end

sgs.ai_skill_playerchosen.ov_chuanshu = function(self,players)
	local mc = self:getMaxCard()
	if mc and mc:getNumber()+3>10 and #self.enemies>0
	then return self.player end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if target:getHandcardNum()>2
		and self:isFriend(target)
		then return target end
	end
	return self.player
end
sgs.ai_playerchosen_intention.ov_chuanshu = -55

addAiSkills("ov_chaofeng").getTurnUseCard = function(self)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	for _,h in sgs.list(cards)do
		if h:isKindOf("Jink")
		then
			for c,pn in sgs.list(patterns())do
				c = dummyCard(pn)
				if c and c:isKindOf("Slash")
				then
					c:setSkillName("ov_chaofeng")
					c:addSubcard(h)
					if c:isAvailable(self.player)
					and self:aiUseCard(c).card
					then return c end
				end
			end
		end
	end
end

sgs.ai_guhuo_card.ov_chaofeng = function(self,toname,class_name)
	if class_name=="Slash"
	then
		local cards = self:addHandPile("he")
		cards = self:sortByKeepValue(cards,nil,true)
		for c,h in sgs.list(cards)do
			if h:isKindOf("Jink")
			then
				c = dummyCard(toname)
				c:setSkillName("ov_chaofeng")
				c:addSubcard(h)
				return c:toString()
			end
		end
	elseif class_name=="Jink"
	then
		local cards = self:addHandPile("he")
		cards = self:sortByKeepValue(cards,nil,true)
		for c,h in sgs.list(cards)do
			if h:isKindOf("Slash")
			then
				c = dummyCard(toname)
				c:setSkillName("ov_chaofeng")
				c:addSubcard(h)
				return c:toString()
			end
		end
	end
end

sgs.ai_skill_use["@@ov_chaofeng"] = function(self,prompt)
	local valid = {}
	self.ov_chaofeng_card = nil
	local mc = self:getMaxCard()
	local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"handcard")
	local n = self.player:getMark("&ov_chuanshu+#"..self.player:objectName())>0 and mc and mc:getNumber()+3 or mc and mc:getNumber() or 0
	for _,p in sgs.list(destlist)do
		if #valid>=3 then break end
		if self.player:canPindian(p) and self:isFriend(p)
		and p:getMark("&ov_chuanshu+#"..self.player:objectName())>0
		and #self.enemies>0 and (#valid>0 or self.player:canPindian(self.enemies[1]))
		then
			table.insert(valid,p:objectName())
			self.ov_chaofeng_card = self:getMinCard()
		end
		if self:isEnemy(p) and self.player:canPindian(p)
		then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>1 then break end
		if not self:isFriend(p)
		and self.player:canPindian(p)
		and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0 and (n>10 or self.ov_chaofeng_card)
	then
    	return string.format("#ov_chaofengCard:.:->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_pindian.ov_chaofeng = function(card,self,requestor,maxcard,mincard)
	if self:isFriend(requestor)
	then return maxcard end
end

sgs.ai_skill_playerchosen.ov_lvren = function(self,players)
	local use = self.player:getTag("ov_lvren"):toCardUse()
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:canCanmou(target,use)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and self:canCanmou(target,use)
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_lvren = 55

sgs.ai_skill_use["@@ov_zhenhu!"] = function(self,prompt)
	local valid = {}
	local destlist = self.player:getAliveSiblings()
    destlist = self:sort(destlist,"handcard")
	for _,p in sgs.list(destlist)do
		if #valid>=3 then break end
		if self:isEnemy(p) and self.player:canPindian(p)
		then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>1 then break end
		if not self:isFriend(p) and self.player:canPindian(p)
		and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>0 then break end
		if self.player:canPindian(p)
		and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	if #valid>0
	then
    	return string.format("#ov_zhenhuCard:.:->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_invoke.ov_zhenhu = function(self,data)
	local valid = {}
	local mc = self:getMaxCard()
	local destlist = self.player:getAliveSiblings()
    destlist = self:sort(destlist,"handcard")
	for _,p in sgs.list(destlist)do
		if #valid>=3 then break end
		if self:isEnemy(p) and self.player:canPindian(p)
		then table.insert(valid,p:objectName()) end
	end
	for _,p in sgs.list(destlist)do
		if #valid>=3 then break end
		if not self:isFriend(p)
		and self.player:canPindian(p)
		and not table.contains(valid,p:objectName())
		then table.insert(valid,p:objectName()) end
	end
	local n = mc and self.player:hasSkill("ov_lvren") and mc:getNumber()+(#valid*2) or mc and mc:getNumber() or 0
	n = n<1 and math.random(4,7)+(#valid*2) or n
	return #valid>0 and n>10
end

sgs.ai_skill_playerchosen.ov_yulong = function(self,players)
	local mc = self:getMaxCard()
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and mc and mc:getNumber()>9
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_yulong = 55

addAiSkills("ov_lihuo").getTurnUseCard = function(self)
  	for _,c in sgs.list(self:addHandPile())do
	   	if c:isKindOf("NatureSlash") then continue end
		local fs = dummyCard("fire_slash")
		fs:setSkillName("mobilelihuo")
		fs:addSubcard(c)
		if fs:isAvailable(self.player)
		and c:isKindOf("Slash")
	   	then return fs end
	end
end

sgs.ai_skill_invoke.ov_lihuo = function(self,data)
	local use = data:toCardUse()
	local fs = dummyCard("fire_slash")
	fs:setSkillName("mobilelihuo")
	if use.card:isVirtualCard() then fs:addSubcards(use.card:getSubcards())
	else fs:addSubcard(use.card:getEffectiveId()) end
	use.card = fs
	self.player:setTag("yb_zhuzhan2_data",ToData(use))
	if self:aiUseCard(fs).card
	then return true end
end

sgs.ai_skill_playerchosen.ov_lihuo = function(self,targets)
	return sgs.ai_skill_playerchosen.yb_zhuzhan2(self,targets)
end

sgs.ai_skill_playerchosen.ov_chunlao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"hej")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:isWeak(target)
		then return target end
	end
	self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:getHandcardNum()>3
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_chunlao = -55

sgs.ai_skill_invoke.ov_chunlao = function(self,data)
	local to = data:toPlayer()
	if to and self:isFriend(to)
	then return true end
end

sgs.ai_skill_playerchosen.ov_chunlaobf = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:isWeak(target)
		then return target end
	end
	self:sort(destlist,"card",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_chunlaobf = -55

sgs.ai_skill_discard.ov_chunlaobf = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
 	return #cards>1 and {cards[1]:getEffectiveId()}
end

addAiSkills("ov_boming").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	if #cards<1 then return end
	local c,to = self:getCardNeedPlayer(cards,false)
  	if c and to then
		self.bm_to = to
		sgs.ai_use_priority.ov_bomingCard = 8.8
		return sgs.Card_Parse("#ov_bomingCard:"..c:getEffectiveId()..":")
	end
	sgs.ai_use_priority.ov_bomingCard = 1.8
	local card_ids = sgs.QList2Table(ListC2I(cards))
	local to,c = sgs.ai_skill_askforyiji.nosyiji(self,card_ids)
  	if c and to and to:objectName()~=self.player:objectName() then
		self.bm_to = to
		return sgs.Card_Parse("#ov_bomingCard:"..c..":")
	end
	cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	if #cards>self.player:getMaxCards()
	and #self.friends_noself>0 then
		self.bm_to = self.friends_noself[1]
		return sgs.Card_Parse("#ov_bomingCard:"..cards[1]:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#ov_bomingCard"] = function(card,use,self)
	if self.bm_to
	then
		use.card = card
		use.to:append(self.bm_to)
	end
end

sgs.ai_use_value.ov_bomingCard = 4.4
sgs.ai_use_priority.ov_bomingCard = 1.8

sgs.ai_skill_invoke.ov_ejian = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isEnemy(target)
	end
end

addAiSkills("ov_jinglve").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_jinglveCard:.:")
end

sgs.ai_skill_use_func["#ov_jinglveCard"] = function(card,use,self)
	for c,as in sgs.list(sgs.ai_skills)do
		if as.name=="jinglve"
		then
			c = as.getTurnUseCard(self,false)
			local jlUse = sgs.ai_skill_use_func["JinglveCard"]
			if jlUse
			then
				jlUse(c,use,self)
				if use.to:length()>0
				then use.card = card end
				break
			end
		end
	end
end

sgs.ai_use_value.ov_jinglveCard = 4.4
sgs.ai_use_priority.ov_jinglveCard = 7.8

addAiSkills("ov_fuman").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	if #cards>=self.player:getMaxCards()
	and #self.friends_noself>0
	then
		return sgs.Card_Parse("#ov_fumanCard:"..cards[1]:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#ov_fumanCard"] = function(card,use,self)
	for c,fp in sgs.list(self.friends_noself)do
		if self.player:getMark(fp:objectName().."ov_fuman-PlayClear")<1
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
end

sgs.ai_use_value.ov_fumanCard = 4.4
sgs.ai_use_priority.ov_fumanCard = 1.8

sgs.ai_skill_invoke.ov_cuorui = function(self,data)
	local n = self.player:getHandcardNum()
	for i,p in sgs.list(self.room:getAlivePlayers())do
		i = p:getHandcardNum()
		if i>n then n = i end
	end
	n = n-self.player:getHandcardNum()
	n = n>5 and 5 or n
	return n>3 or self:isWeak() and n>2
end

sgs.ai_skill_playerchosen.ov_cuorui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and not self:isWeak(target)
		then return target end
	end
	self:sort(destlist,"card",true)
    return destlist[1]
end
sgs.ai_playerchosen_intention.ov_cuorui = 55

sgs.ai_skill_choice.ov_liewei = function(self,choices)
	local items = choices:split("+")
	if self:isWeak() then return items[1] end
	return items[2]
end

sgs.ai_skill_invoke.ov_xiewei = function(self,data)
	local target = data:toPlayer()
	if target and self:isEnemy(target)
	then
		for _,fp in sgs.list(self.friends_noself)do
			if target:canSlash(fp) and self:isWeak(fp)
			then return true end
		end
		return not self:isWeak()
		and (self:getCardsNum("Slash")>2 or target:getHandcardNum()<3)
	end
end

sgs.ai_skill_choice.ov_liewei = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target)
	then
		if target:getHandcardNum()<=self.player:getHandcardNum()
		then return items[1] else return items[2] end
	else
		if #items>2
		then
			return items[3]
		end
		if target:getHandcardNum()>self.player:getHandcardNum()+1
		then return items[1] else return items[2] end
	end
end

sgs.ai_skill_playerchosen.ov_shuangren = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
	local mc = self:getMaxCard()
	if not mc or mc:getNumber()<9
	then return end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target) then
			for _,p in sgs.list(self.room:getAlivePlayers())do
				if target:distanceTo(p)<=1 and self:isEnemy(p)
				and self:slashIsEffective(dummyCard(),p)
				and self.player:canSlash(p)
				then return target end
			end
		end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target) then
			for _,p in sgs.list(self.room:getAlivePlayers())do
				if target:distanceTo(p)<=1 and self:isEnemy(p)
				and self:slashIsEffective(dummyCard(),p)
				and self.player:canSlash(p)
				then return target end
			end
		end
	end
end
sgs.ai_playerchosen_intention.ov_shuangren = 55

sgs.ai_skill_cardask["ov_shuangren2"] = function(self,data,pattern,prompt)
	local tos = sgs.SPlayerList()
	for i,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if self.player:canPindian(p)
		then tos:append(p) end
	end
	tos = sgs.ai_skill_playerchosen.ov_shuangren(self,tos)
	if tos then
		local cards = self.player:getCards("he")
		cards = self:sortByKeepValue(cards)
		for i,c in sgs.list(cards)do
			if c:getEffectiveId()~=self:getMaxCard():getEffectiveId()
			then return c:getEffectiveId() end
		end
	end
	return "."
end

sgs.ai_skill_playerschosen.ov_shuangren = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
	local tos = {}
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isEnemy(target) and self.player:canSlash(target)
		and self:slashIsEffective(dummyCard(),target)
		then table.insert(tos,target) end
	end
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if not self:isFriend(target)
		and self.player:canSlash(target)
		and not table.contains(tos,target)
		and self:slashIsEffective(dummyCard(),target)
		then table.insert(tos,target) end
	end
	return tos
end

sgs.ai_skill_playerchosen.ov_fenming = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getCardCount()>0
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_fenming = 55

sgs.ai_skill_choice.ov_liewei = function(self,choices)
	local items = choices:split("+")
	if self.player:isChained() then return items[3] end
	return items[1]
end

addAiSkills("ov_mouli").getTurnUseCard = function(self)
    for _,pn in sgs.list(patterns())do
		local c = dummyCard(pn)
		if c and c:getTypeId()==1
		and c:isAvailable(self.player)
		and self:getCardsNum(c:getClassName())<2
		and self:getRestCardsNum(c:getClassName())>0
		then
			c = self:aiUseCard(c)
			if c.card and c.to
			then
				self.ml_to = c.to
				return sgs.Card_Parse("#ov_mouliCard:.:"..pn)
			end
		end
	end
end

sgs.ai_skill_use_func["#ov_mouliCard"] = function(card,use,self)
	if self.ml_to
	then
		use.card = card
		use.to = self.ml_to
	end
end

sgs.ai_use_value.ov_mouliCard = 4.4
sgs.ai_use_priority.ov_mouliCard = 2.8

sgs.ai_guhuo_card.ov_mouli = function(self,toname,class_name)
	if self.player:getMark("ov_mouliUse-Clear")<1
	and self:getRestCardsNum(class_name)>0
	and dummyCard(class_name):getTypeId()==1
	and self:getCardsNum(class_name)<2
	and sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	then return "#ov_mouliCard:.:"..toname end
end

sgs.ai_skill_invoke.ov_qianxi = function(self,data)
	return true
end

sgs.ai_skill_discard.ov_qianxi = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
    for i,c in sgs.list(cards)do
		if i<#cards/2
		and c:isRed()
		then
			return {c:getEffectiveId()}
		end
	end
	return #cards>0 and {cards[1]:getEffectiveId()}
end

sgs.ai_skill_playerchosen.ov_qianxi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getCardCount()>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_qianxi = 55

sgs.ai_skill_invoke.ov_enyuan = function(self,data)
	if self.player:hasFlag("Damaged")
	then
		local damage = data:toDamage()
		return not self:isFriend(damage.from)
	end
	if self.player:hasFlag("CardsMoveOneTime")
	then
		local target = data:toPlayer()
		return self:isFriend(target)
	end
	local target = data:toString():split(":")[2]
	target = BeMan(self.room,target)
	if self:isFriend(target)
	then
		return target:isWounded()
	end
end

sgs.ai_skill_use["@@ov_xuanhuo"] = function(self,prompt)
	local to,ids = nil,{}
	local destlist = self.room:getOtherPlayers(self.player)
    destlist = self:sort(destlist,"handcard")
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if #ids>1 then break end
		table.insert(ids,c:getEffectiveId())
	end
	for _,p in sgs.list(destlist)do
		if to then break end
		if self:isFriend(p)
		then to = p:objectName() end
		self.ov_xh_to = p
	end
	for _,p in sgs.list(destlist)do
		if to then break end
		if self:isEnemy(p)
		and #self.enemies>1
		then to = p:objectName() end
		self.ov_xh_to = p
	end
	for _,p in sgs.list(destlist)do
		if to then break end
		if #self.enemies>0
		then to = p:objectName() end
		self.ov_xh_to = p
	end
	if to
	and #ids>1
	then
    	return string.format("#ov_xuanhuoCard:%s:->%s",table.concat(ids,"+"),to)
	end
end

sgs.ai_skill_playerchosen.ov_xuanhuo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and (self.ov_xh_to:canUse(dummyCard(),target,true) or self.ov_xh_to:canUse(dummyCard("duel"),target,true))
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and (self.ov_xh_to:canUse(dummyCard(),target,true) or self.ov_xh_to:canUse(dummyCard("duel"),target,true))
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_xuanhuo = 55

sgs.ai_skill_choice.ov_xuanhuo = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items,"slash")
	then
		if self:isFriend(target)
		then
			if not self:hasTrickEffective(dummyCard("duel"),target,self.player)
			then return "duel" end
			if not(self:isWeak(target) and self:slashIsEffective(dummyCard(),target))
			then return "slash" end
		elseif self.player:getHandcardNum()>target:getHandcardNum()
		and self:hasTrickEffective(dummyCard("duel"),target,self.player)
		then
			return "duel"
		end
		return "slash"
	end
	if not self:isFriend(target)
	then return items[1] end
end

sgs.ai_skill_playerchosen.ov_zenhui = function(self,players)
	sgs.ai_skill_choice.ov_zenhui = "ov_zenhui2"
	self.player:setTag("yb_zhuzhan2_data",self.player:getTag("ov_zenhuiData"))
	local to = sgs.ai_skill_playerchosen.yb_zhuzhan2(self,players)
	if to then return to end
	sgs.ai_skill_choice.ov_zenhui = "ov_zenhui1"
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"ej")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"he")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"hej")
		then return target end
	end
end

sgs.ai_skill_playerchosen.ov_qirang1 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
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
sgs.ai_playerchosen_intention.ov_qirang1 = 55

sgs.ai_skill_cardask["ov_jiaojin"] = function(self,data,pattern,prompt)
	local damage = data:toDamage()
	if self:canDamageHp(damage.from,damage.card,damage.to)
	and self:canLoseHp(damage.from,damage.card)
	and not self:isWeak() then return end
	return true
end

addAiSkills("ov_yuanhu").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		if c:getTypeId()==3
		and self:evaluateArmor(c)>-5
		then
			i = c:getRealCard():toEquipCard():location()
			for n,fp in sgs.list(self.friends)do
				if fp:hasEquipArea(i)
				then 
					n = false
					for _,p in sgs.list(self.room:getAlivePlayers())do
						if i~=0 then break end
						if fp:distanceTo(p)==1
						and self:doDisCard(p,"hej")
						then n = true end
					end
					if i==1
					then
						n = fp:getHandcardNum()<3
					elseif i>1
					then
						n = self:isWeak(fp)
					end
					if n
					then
						self.ov_yh_to = fp
						return sgs.Card_Parse("#ov_yuanhuCard:"..c:getEffectiveId()..":")
					end
				end
			end
		end
	end
  	for i,c in sgs.list(cards)do
		if c:getTypeId()==3
		and self:evaluateArmor(c)>-5
		then
			i = c:getRealCard():toEquipCard():location()
			for _,fp in sgs.list(self.friends)do
				if fp:hasEquipArea(i)
				and not fp:getEquip(i)
				then 
					self.ov_yh_to = fp
					return sgs.Card_Parse("#ov_yuanhuCard:"..c:getEffectiveId()..":")
				end
			end
		end
	end
	cards = self:poisonCards("e")
  	for i,c in sgs.list(cards)do
		i = c:getRealCard():toEquipCard():location()
		for _,fp in sgs.list(self.enemies)do
			if fp:hasEquipArea(i)
			then 
				self.ov_yh_to = fp
				return sgs.Card_Parse("#ov_yuanhuCard:"..c:getEffectiveId()..":")
			end
		end
	end
	cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		if c:getTypeId()==3
		and self:evaluateArmor(c)<-5
		then
			i = c:getRealCard():toEquipCard():location()
			for _,fp in sgs.list(self.enemies)do
				if fp:hasEquipArea(i)
				then 
					self.ov_yh_to = fp
					return sgs.Card_Parse("#ov_yuanhuCard:"..c:getEffectiveId()..":")
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#ov_yuanhuCard"] = function(card,use,self)
	if self.ov_yh_to
	then
		use.card = card
		use.to:append(self.ov_yh_to)
	end
end

sgs.ai_use_value.ov_yuanhuCard = 9.4
sgs.ai_use_priority.ov_yuanhuCard = 7.8

sgs.ai_skill_use["@@ov_yuanhu"] = function(self,prompt)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		if c:getTypeId()==3
		and self:evaluateArmor(c)>-5
		then
			i = c:getRealCard():toEquipCard():location()
			for n,fp in sgs.list(self.friends)do
				if fp:hasEquipArea(i)
				then 
					n = false
					for _,p in sgs.list(self.room:getAlivePlayers())do
						if i~=0 then break end
						if fp:distanceTo(p)==1
						and self:doDisCard(p,"hej")
						then n = true end
					end
					if i==1
					then
						n = fp:getHandcardNum()<3
					elseif i>1
					then
						n = self:isWeak(fp)
					end
					if n
					then
						return string.format("#ov_yuanhuCard:%s:->%s",c:getEffectiveId(),fp:objectName())
					end
				end
			end
		end
	end
  	for i,c in sgs.list(cards)do
		if c:getTypeId()==3
		and self:evaluateArmor(c)>-5
		then
			i = c:getRealCard():toEquipCard():location()
			for _,fp in sgs.list(self.friends)do
				if fp:hasEquipArea(i)
				and not fp:getEquip(i)
				then 
					return string.format("#ov_yuanhuCard:%s:->%s",c:getEffectiveId(),fp:objectName())
				end
			end
		end
	end
	cards = self:poisonCards("e")
  	for i,c in sgs.list(cards)do
		i = c:getRealCard():toEquipCard():location()
		for _,fp in sgs.list(self.enemies)do
			if fp:hasEquipArea(i)
			then 
				return string.format("#ov_yuanhuCard:%s:->%s",c:getEffectiveId(),fp:objectName())
			end
		end
	end
	cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
  	for i,c in sgs.list(cards)do
		if c:getTypeId()==3
		and self:evaluateArmor(c)<-5
		then
			i = c:getRealCard():toEquipCard():location()
			for _,fp in sgs.list(self.enemies)do
				if fp:hasEquipArea(i)
				then 
					return string.format("#ov_yuanhuCard:%s:->%s",c:getEffectiveId(),fp:objectName())
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen.ov_juezhu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and (self:isWeak(target) or self:doDisCard(target,"j"))
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_juezhu = -55

sgs.ai_skill_invoke.ov_juezhu = function(self,data)
	return sgs.ai_skill_playerchosen.ov_juezhu(self,self.room:getAlivePlayers())
end

sgs.ai_skill_invoke.ov_zhilve = function(self,data)
	return true
end

sgs.ai_skill_choice.ov_zhilve = function(self,choices)
	local items = choices:split("+")
	if sgs.ai_skill_invoke.peiqi(self,ToData())
	then
		if self.room:getCardPlace(self.peiqiData.cid)~=sgs.Player_PlaceEquip
		or not self:isWeak() then return items[1] end
	end
	return items[2]
end

sgs.ai_skill_playerchosen["ov_zhilve_from"] = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==self.peiqiData.from:objectName()
		then return target end
	end
end

sgs.ai_skill_playerchosen["ov_zhilve_to"] = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==self.peiqiData.to:objectName()
		then return target end
	end
end

sgs.ai_skill_cardchosen.ov_zhilve = function(self,who,flags,method)
	for i,e in sgs.list(who:getCards(flags))do
		i = e:getEffectiveId()
		if i==self.peiqiData.cid
		then return i end
	end
end

sgs.ai_skill_playerchosen.ov_zhengrong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:doDisCard(target,"e")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:doDisCard(target,"he")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"he")
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_use["@@ov_hongju"] = function(self,prompt)
	local valid = {}
	local honor = ListI2C(self.player:getPile("honor"))
    local cards = self.player:getCards("h")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(honor)do
		if self:aiUseCard(c).card
		then
			for i,h in sgs.list(cards)do
				i = h:getEffectiveId()
				if table.contains(valid,i)
				then continue end
				if self:aiUseCard(h).card
				then
					if self:getUseValue(h)<self:getUseValue(c)
					then
						table.insert(valid,c:getEffectiveId())
						table.insert(valid,i)
						break
					end
				elseif self:getKeepValue(h)<self:getKeepValue(c)
				then
					table.insert(valid,c:getEffectiveId())
					table.insert(valid,i)
					break
				end
			end
		else
			for i,h in sgs.list(cards)do
				i = h:getEffectiveId()
				if table.contains(valid,i)
				then continue end
				if self:aiUseCard(h).card
				then
				elseif self:getKeepValue(h)<self:getKeepValue(c)
				then
					table.insert(valid,c:getEffectiveId())
					table.insert(valid,i)
					break
				end
			end
		end
 	end
	return string.format("#ov_hongjuCard:%s:",table.concat(valid,"+"))
end

sgs.ai_skill_invoke.ov_hongju = function(self,data)
	return self.player:isWounded()
	or #self.enemies>0
end

addAiSkills("ov_qingce").getTurnUseCard = function(self)
	local cards = self.player:getPile("honor")
	if cards:length()>0
	then
		return sgs.Card_Parse("#ov_qingceCard:"..cards:at(0)..":")
	end
end

sgs.ai_skill_use_func["#ov_qingceCard"] = function(card,use,self)
	for c,fp in sgs.list(self.friends_noself)do
		if self:doDisCard(fp,"ej")
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
	for c,fp in sgs.list(self.enemies)do
		if self:doDisCard(fp,"ej")
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
	for c,fp in sgs.list(self.enemies)do
		if self:doDisCard(fp,"hej")
		and fp:getCardCount()<3
		then
			use.card = card
			use.to:append(fp)
			return
		end
	end
end

sgs.ai_use_value.ov_qingceCard = 4.4
sgs.ai_use_priority.ov_qingceCard = 4.8

sgs.ai_skill_use["@@ov_xingluan!"] = function(self,prompt)
	local valid,to = {},nil
	local ids = self.player:getTag("ov_xingluanForAI"):toIntList()
    ids = self:sortByUseValue(ListI2C(ids))
	local n = self.player:getMark("ov_xingluanNum-Clear")
	self:sort(self.enemies,"hp")
	for i,c in sgs.list(ids)do
		if to then break end
		i = c:getEffectiveId()
		for _,se in sgs.list(self.enemies)do
			if to then break end
			if #valid+se:getMark("ov_xingluanNum-Clear")>2
			or isCard("Peach",c,se) then continue end
			if n>=se:getMark("ov_xingluanNum-Clear")
			then
				table.insert(valid,i)
				to = se:objectName()
			end
		end
 	end
	self:sort(self.friends,"hp",true)
	self:sortByKeepValue(ids,true)
	for i,c in sgs.list(ids)do
		if to then break end
		i = c:getEffectiveId()
		for _,se in sgs.list(self.friends)do
			if to then break end
			if #valid+se:getMark("ov_xingluanNum-Clear")>2
			or #self:poisonCards({c},se)>0 then continue end
			if n<=se:getMark("ov_xingluanNum-Clear")
			or hasZhaxiangEffect(se)
			then
				table.insert(valid,i)
				to = se:objectName()
			end
		end
 	end
	for i,c in sgs.list(ids)do
		if to then break end
		i = c:getEffectiveId()
		for _,se in sgs.list(self.enemies)do
			if to then break end
			if #valid+se:getMark("ov_xingluanNum-Clear")>2
			then continue end
			table.insert(valid,i)
			to = se:objectName()
		end
 	end
	for i,c in sgs.list(ids)do
		if to then break end
		i = c:getEffectiveId()
		for _,se in sgs.list(self.friends)do
			if to then break end
			if #valid+se:getMark("ov_xingluanNum-Clear")>2
			then continue end
			table.insert(valid,i)
			to = se:objectName()
		end
 	end
	for i,c in sgs.list(ids)do
		if to then break end
		i = c:getEffectiveId()
		for _,se in sgs.list(self.room:getAlivePlayers())do
			if to then break end
			if #valid+se:getMark("ov_xingluanNum-Clear")>2
			then continue end
			table.insert(valid,i)
			to = se:objectName()
		end
 	end
	return to and string.format("#ov_xingluanCard:%s:->%s",table.concat(valid,"+"),to)
end

sgs.ai_skill_invoke.ov_xingluan = function(self,data)
	return true
end

sgs.ai_skill_playerchosen.ov_qirang = function(self,players)
	self.player:setTag("yb_fujia2_data",self.player:getTag("ov_qirangData"))
	local to = sgs.ai_skill_playerchosen.yb_fujia2(self,players)
	if to then return to end
	self.player:setTag("yb_zhuzhan2_data",self.player:getTag("ov_qirangData"))
	to = sgs.ai_skill_playerchosen.yb_zhuzhan2(self,players)
	if to then return to end
end

sgs.ai_skill_invoke.ov_yuhua = function(self,data)
	sgs.guanXingFriend = true
	return true
end

sgs.ai_skill_invoke.ov_xuhe = function(self,data)
	local target = data:toPlayer()
	if target then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_choice.ov_xuhe = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isEnemy(target)
	then
		if target:getHandcardNum()>self.player:getHandcardNum()*(math.random()+1.3)
		and not self:isWeak() then return items[1] end
	end
	return items[2]
end

sgs.ai_skill_playerschosen.ov_wuhun = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
	local tos = {}
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isEnemy(target)
		then table.insert(tos,target) end
	end
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if not self:isFriend(target)
		and not table.contains(tos,target)
		then table.insert(tos,target) end
	end
	return tos
end

sgs.ai_skill_invoke.ov_wuhun = function(self,data)
	return #self.enemies>0
	or #self.friends>0
end

sgs.ai_skill_playerchosen.ov_kuanji = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_kuanji = -55

sgs.ai_skill_playerchosen["_ov_tiaojiyanmei"] = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end
sgs.ai_playerchosen_intention._ov_tiaojiyanmei = -55

function SmartAI:useCardTiaojiyanmei(card,use)
	self:sort(self.enemies,"hp")
	use.card = card
	sgs.ai_use_priority.Tiaojiyanmei = 5.5
	local extraTarget = 1+sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if use.to:length()<2 and CanToCard(card,ep,self.player,use.to)
		then
			use.to:append(ep)
			local remove1 = true
			for _,fp in sgs.list(self.friends)do
				if isCurrent(use,fp) then continue end
				if ep:getHandcardNum()>fp:getHandcardNum()
				and CanToCard(card,fp,self.player,use.to)
				then
					remove1 = false
					use.to:append(fp)
					if use.to:length()>extraTarget
					then return end
				end
			end
			if remove1 then use.to:removeOne(ep) end
		end
	end
	for _,ep in sgs.list(self.room:getAlivePlayers())do
		if isCurrent(use,ep) then continue end
		if use.to:length()<2 and CanToCard(card,ep,self.player,use.to)
		and not self:isFriend(ep)
		then
			use.to:append(ep)
			local remove1 = true
			for _,fp in sgs.list(self.friends)do
				if isCurrent(use,fp) then continue end
				if ep:getHandcardNum()>fp:getHandcardNum()
				and CanToCard(card,fp,self.player,use.to)
				then
					remove1 = false
					use.to:append(fp)
					if use.to:length()>extraTarget
					then return end
				end
			end
			if remove1 then use.to:removeOne(ep) end
		end
	end
	for _,fp in sgs.list(self.friends)do
		if isCurrent(use,fp) then continue end
		if use.to:length()>1 and use.to:at(0):getHandcardNum()>fp:getHandcardNum()
		and CanToCard(card,fp,self.player,use.to)
		then
			use.to:append(fp)
			if use.to:length()>extraTarget
			then return end
		end
	end
	if use.to:length()>0 then return end
	sgs.ai_use_priority.Tiaojiyanmei = 9-self.player:getHandcardNum()
end
sgs.ai_use_priority.Tiaojiyanmei = 5.5
sgs.ai_keep_value.Tiaojiyanmei = 1
sgs.ai_use_value.Tiaojiyanmei = 5.7
sgs.ai_card_intention.Tiaojiyanmei = function(self,card,from,tos)
	for _,to1 in ipairs(tos)do
		for _,to2 in ipairs(tos)do
			if to1==to2 then continue end
			if to1:getHandcardNum()<to2:getHandcardNum()
			then sgs.updateIntention(from,to1,-10)
			else sgs.updateIntention(from,to1,10) end
		end
	end
end

sgs.ai_skill_discard.ov_yizhu = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min then break end
		if h:isKindOf("AOE") or h:isKindOf("GlobalEffect") then continue end
		if h:isAvailable(self.player) then table.insert(to_cards,h:getEffectiveId()) end
	end
	cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min then break end
		if table.contains(to_cards,h:getEffectiveId())
		then continue end
		table.insert(to_cards,h:getEffectiveId())
	end
	return to_cards
end

sgs.ai_skill_playerchosen.ov_yizhu = function(self,players)
	local use = self.player:getTag("ov_yizhuData"):toCardUse()
	local destlist = self:sort(players,"hp")
	sgs.ai_skill_choice.ov_yizhu = "ov_yizhu2"
	if not self:isFriend(use.from) then
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			and use.card:targetFixed()
			and not use.card:isDamageCard()
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if self:isFriend(target)
			and use.card:getTypeId()==3
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if self:isEnemy(target)
			and use.card:isDamageCard()
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if self:isEnemy(target)
			and use.card:isKindOf("DelayedTrick")
			then return target end
		end
		for _,target in sgs.list(destlist)do
			if not self:isFriend(target)
			and use.card:isKindOf("DelayedTrick")
			then return target end
		end
	end
	sgs.ai_skill_choice.ov_yizhu = "ov_yizhu3"
	self.player:setTag("yb_zhuzhan2_data",self.player:getTag("ov_yizhuData"))
	local to = sgs.ai_skill_playerchosen.yb_zhuzhan2(self,players)
	if to then return to end
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and use.card:targetFixed()
		and not use.card:isDamageCard()
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and use.card:isDamageCard()
		then return target end
	end
end

addAiSkills("ov_luanchou").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_luanchouCard:.:")
end

sgs.ai_skill_use_func["#ov_luanchouCard"] = function(card,use,self)
	self:sort(self.friends,"hp")
	for c,fp1 in sgs.list(self.friends)do
		for _,fp2 in sgs.list(sgs.reverse(self.friends))do
			if fp2:getHp()>fp1:getHp()
			or fp2:objectName()~=fp1:objectName()
			then
				use.card = card
				use.to:append(fp1)
				use.to:append(fp2)
				return
			end
		end
	end
	for c,fp1 in sgs.list(self.room:getAlivePlayers())do
		if self:isEnemy(fp1) then continue end
		for _,fp2 in sgs.list(self.friends)do
			if fp2:getHp()<=fp1:getHp()
			and fp2:objectName()~=fp1:objectName()
			then
				use.card = card
				use.to:append(fp1)
				use.to:append(fp2)
				return
			end
		end
	end
end

sgs.ai_use_value.ov_luanchouCard = 4.4
sgs.ai_use_priority.ov_luanchouCard = 7.8

sgs.ai_skill_invoke.ov_gonghuan = function(self,data)
	local target = data:toPlayer()
	if target
	then
		if self:isFriend(target)
		then
			return self:isWeak(target)
			and (not self:isWeak() or target:getHp()<self.player:getHp() or target:getHandcardNum()>self.player:getHandcardNum())
		end
		return not self:isEnemy(target)
		and self:isWeak(target) and not self:isWeak()
	end
end

addAiSkills("ov_gongxin").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_gongxinCard:.:")
end

sgs.ai_skill_use_func["#ov_gongxinCard"] = function(card,use,self)
	local cas = canAiSkills("gongxin")
	if cas
	then
		cas = cas.ai_fill_skill(self,false)
		local gxUse = sgs.ai_skill_use_func["GongxinCard"]
		if gxUse
		then
			gxUse(cas,use,self)
			if use.to:length()>0
			then
				use.card = card
				self.player:setTag("gongxin",ToData(use.to:at(0)))
			end
		end
	end
end

sgs.ai_use_value.ov_gongxinCard = 4.4
sgs.ai_use_priority.ov_gongxinCard = 9.8

sgs.ai_skill_choice.ov_gongxin = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items,"ov_gongxin1")
	then
		if self.gongxinchoice=="put"
		then return "ov_gongxin1" end
		return "ov_gongxin2"
	end
	if table.contains(items,"red")
	then
		for i,h in sgs.list(target:getHandcards())do
			if self:isWeak(target)
			and (isCard("Peach",h,target) or isCard("Analeptic",h,target))
			then return h:getColorString() end
		end
		for i,h in sgs.list(target:getHandcards())do
			if isCard("Jink",h,target)
			then return h:getColorString() end
		end
		for i,h in sgs.list(target:getHandcards())do
			if isCard("Nullification",h,target)
			then return h:getColorString() end
		end
	end
end

sgs.ai_skill_askforag.ov_gongxin = function(self,card_ids)
	local id = sgs.ai_skill_askforag.gongxin(self,card_ids)
	if id>=0 then return id end
	local cs = ListI2C(card_ids)
    cs = self:sortByUseValue(cs)
	return cs[1]:getEffectiveId()
end

sgs.ai_skill_choice.ov_shelie = function(self,choices,data)
	local items = choices:split("+")
	local uses = self:getTurnUse()
	if #uses>2
	then
		return items[2]
	end
	return items[1]
end

sgs.ai_skill_playerchosen.ov_suizheng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
end
sgs.ai_playerchosen_intention.ov_suizheng = -55

sgs.ai_skill_discard.ov_suizheng = function(self,max,min,optional)
	local to_cards = {}
	local target = self.player:getTag("ov_suizheng"):toPlayer()
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min or self:isEnemy(target) or not self:isWeak() then break end
		if h:getTypeId()==1 then table.insert(to_cards,h:getEffectiveId()) end
	end
	return #to_cards>1 and to_cards
end

sgs.ai_skill_invoke.ov_tuidao = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isEnemy(target)
	end
	return #self.friends_noself>0
	or #self.enemies<1
end

sgs.ai_skill_choice.ov_tuidao = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target
	and table.contains(items,"BasicCard")
	then
		if target:hasEquip()
		then
			return items[3]
		end
		return items[1]
	end
	return items[2]
end

sgs.ai_skill_playerchosen.ov_tuidao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end
sgs.ai_playerchosen_intention.ov_tuidao = -55

sgs.ai_skill_playerchosen.ov_gongge = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"skill",true)
	local n = 0
	for _,c in sgs.list(self.toUse)do
		if c:isDamageCard()
		then n = n+1 end
	end
	if n>1 then return end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_playerchosen_intention.ov_gongge = 55

sgs.ai_skill_choice.ov_gongge = function(self,choices,data)
	local items = choices:split("+")
	local use = self.player:getTag("ov_gongge"):toCardUse()
	local target = data:toPlayer()
	if target
	then
		if target:getHandcardNum()<2
		then return items[3] end
		if target:getCardCount()>2
		or target:getHp()<self.player:getHp()
		then return items[2] end
		if target:getSkillList():length()>2
		and self.player:getHandcardNum()<3
		then return items[1] end
		if target:getLostHp()<2
		then return items[3] end
	end
	return items[1]
end

sgs.ai_skill_invoke.ov_qingxi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_choice.ov_qingxi = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target
	then
		if target:getEquips():length()<self.player:getEquips():length()
		and not self:isWeak() then return items[1] end
		if target:hasEquip() and self.player:hasEquip()
		and self:getCardsNum("Jink")>0
		then return items[2] end
	end
end

sgs.ai_skill_use["@@ov_zaoli!"] = function(self,prompt)
	local valid = {}
    local cards = self.player:getCards("hej")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if h:getTypeId()==3 then table.insert(valid,h:getEffectiveId()) end
		if h:isAvailable(self.player) and self:aiUseCard(h).card
		or table.contains(valid,h:getEffectiveId())
		or self:getKeepValue(h)>5 then continue end
    	table.insert(valid,h:getEffectiveId())
	end
	for _,h in sgs.list(self.player:getCards("j"))do
		if table.contains(valid,h:getEffectiveId()) then continue end
		if self:doDisCard(self.player,h:getEffectiveId())
		then table.insert(valid,h:getEffectiveId()) end
	end
	return string.format("#ov_zaoliCard:%s:",table.concat(valid,"+"))
end

sgs.ai_skill_invoke.ov_yuzhang = function(self,data)
	local ts = data:toString()
	if ts:startsWith("ov_yuzhang")
	then
		ts = ts:split(":")[2]
		if ts=="Player_Judge"
		and self:doDisCard(self.player,"j")
		then return true end
		if ts=="Player_Discard"
		and self.player:getHandcardNum()>self.player:getMaxCards()*(math.random()+1)
		then return true end
		return
	end
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_choice.ov_yuzhang = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target
	then
		if target:getHandcardNum()>self.player:getHandcardNum()*(math.random()+1)
		then return items[1] end
		if target:getCardCount()<4
		then return items[2] end
	end
end

sgs.ai_skill_invoke.ov_guoyi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_use["@@ov_liexi"] = function(self,prompt)
	local valid = {}
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true)
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if self:damageIsEffective(ep,nil,self.player)
		then
			for _,h in sgs.list(cards)do
				if ep:getHp()<#cards/2 or ep:getHp()<=#cards/2 and self:isWeak(ep)
				then
					table.insert(valid,h:getEffectiveId())
					if #valid>ep:getHp()
					then
						return "#ov_liexiCard:"..table.concat(valid,"+")..":->"..ep:objectName()
					end
				end
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if self:damageIsEffective(ep,nil,self.player)
		then
			for _,h in sgs.list(cards)do
				if h:isKindOf("Weapon") and (self.player:getHp()>1 and self:isWeak(ep) or not self:isWeak())
				then return "#ov_liexiCard:"..h:getEffectiveId()..":->"..ep:objectName() end
			end
		end
	end
end

sgs.ai_skill_playerschosen.ov_shezhong = function(self,players,x,n)
	local destlist = self:sort(players,"hp")
	local tos = {}
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isEnemy(target) then table.insert(tos,target) end
	end
    for _,target in sgs.list(destlist)do
		if #tos>=x then break end
		if not (self:isFriend(target) or self:isWeak(target))
		then table.insert(tos,target) end
	end
	return tos
end

sgs.ai_skill_playerchosen.ov_shezhong = function(self,players)
	local destlist = self:sort(players,"handcard",true)
	return destlist[1]
end

addAiSkills("ov_kaizengvs").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_kaizengCard:.:")
end

sgs.ai_skill_use_func["#ov_kaizengCard"] = function(card,use,self)
	for c,fp in sgs.list(self.room:getAlivePlayers())do
		if fp:hasSkill("ov_kaizeng")
		and fp:getHandcardNum()>0
		then
			self.ov_kz_to = fp
			if self:isEnemy(fp) and math.random()>0.3 then continue end
			use.to:append(fp)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.ov_kaizengCard = 5.4
sgs.ai_use_priority.ov_kaizengCard = 4.8

sgs.ai_skill_choice.ov_kaizeng = function(self,choices,data)
	local items = choices:split("+")
	for d,cn in sgs.list(items)do
		d = dummyCard(cn)
		if d
		then
			if getKnownCard(self.ov_kz_to,self.player,d:getClassName(),nil,"he")>0
			then return cn end
		elseif getKnownCard(self.ov_kz_to,self.player,cn,nil,"he")>0
		then return cn end
	end
end

sgs.ai_skill_discard.ov_kaizeng = function(self,max,min,optional)
	local to_cards = {}
	local target = self.room:getCurrent()
	local pc = self:poisonCards("he")
	if self:isFriend(target)
	then
		local kct = getKnownCards(self.player,target,"he")
		self:sortByUseValue(kct,true)
		for _,c in sgs.list(kct)do
			if #to_cards>2 or table.contains(to_cards,c:getEffectiveId()) then continue end
			if c:isAvailable(target) then table.insert(to_cards,c:getEffectiveId()) end
		end
		for _,c in sgs.list(pc)do
			if table.contains(to_cards,c:getEffectiveId()) then continue end
			if c:getTypeId()>2 then table.insert(to_cards,c:getEffectiveId()) end
		end
		for _,c in sgs.list(kct)do
			if #to_cards>1 or table.contains(to_cards,c:getEffectiveId()) then continue end
			table.insert(to_cards,c:getEffectiveId())
		end
		local cards = self.player:getCards("he")
		cards = self:sortByKeepValue(cards,true)
		for _,c in sgs.list(cards)do
			if #to_cards>1 or table.contains(to_cards,c:getEffectiveId()) then continue end
			if c:isAvailable(target) then table.insert(to_cards,c:getEffectiveId()) end
		end
		for _,c in sgs.list(cards)do
			if #to_cards<1 or #to_cards>1 or table.contains(to_cards,c:getEffectiveId()) then continue end
			table.insert(to_cards,c:getEffectiveId())
		end
	else
		for _,c in sgs.list(pc)do
			if table.contains(to_cards,c:getEffectiveId()) then continue end
			if c:getTypeId()<3 then table.insert(to_cards,c:getEffectiveId()) end
		end
	end
	return to_cards
end

addAiSkills("ov_xiechang").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_xiechangCard:.:")
end

sgs.ai_skill_use_func["#ov_xiechangCard"] = function(card,use,self)
	self:sort(self.enemies,"handcard")
	local xc = self:getMaxCard()
	self.ov_xiechang_card = xc
	for _,ep in sgs.list(self.enemies)do
		if ep:hasEquip()
		and xc and xc:getNumber()>9
		and self.player:canPindian(ep)
		then
			use.to:append(ep)
			use.card = card
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if self.player:canPindian(ep)
		and xc and xc:getNumber()>9
		then
			use.to:append(ep)
			use.card = card
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if self.player:canPindian(ep)
		and self.player:inMyAttackRange(ep)
		and ep:getHandcardNum()<3
		then
			use.to:append(ep)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.ov_xiechangCard = 4.4
sgs.ai_use_priority.ov_xiechangCard = 2.8

sgs.ai_skill_invoke.ov_duoren = function(self,data)
	local target = data:toPlayer()
	if target
	then
		local can
		for i,p in sgs.list(self.player:getSiblings())do
			if p:isDead() then can = true end
		end
		for i,sk in sgs.list(target:getSkillList())do
			if sk:isAttachedLordSkill()
			or sk:isLordSkill()
			then continue end
			return can and self.player:getLostHp()>0
		end
	end
end

sgs.ai_skill_playerchosen.ov_yanshi = function(self,players)
	local destlist = self:sort(players,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_playerchosen_intention.ov_yanshi = -55

sgs.ai_skill_invoke.ov_bingzhao = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
	end
end

sgs.ai_skill_invoke.ov_wanwei = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isFriend(target)
		and self:isWeak(target)
		and not self:isWeak()
	end
	return true
end

sgs.ai_skill_use["@@ov_wanwei!"] = function(self,prompt)
	local valid = {}
	local c = sgs.Sanguosha:getCard(self.player:getMark("ov_wanwei_id"))
    local d = self:aiUseCard(c)
	if d.card
	then
		if c:canRecast()
		and d.to:length()<1
		then return end
		for _,p in sgs.list(d.to)do
			table.insert(valid,p:objectName())
		end
		return c:toString().."->"..table.concat(valid,"+")
	end
end

addAiSkills("ov_yuejian").getTurnUseCard = function(self)
	local ids = {}
	local n = self.player:getHandcardNum()-self.player:getMaxCards()
	n = n<1 and 1 or n
	for _,c in sgs.list(self:poisonCards("he"))do
		if #ids>=n then break end
		table.insert(ids,c:getEffectiveId())
	end
	if self:getOverflow()>0
	then
		local cs = self.player:getHandcards()
		cs = self:sortByKeepValue(cs)
		for _,c in sgs.list(cs)do
			if #ids>=n then break end
			table.insert(ids,c:getEffectiveId())
		end
	end
	return #ids>0 and sgs.Card_Parse("#ov_yuejianCard:"..table.concat(ids,"+")..":")
end

sgs.ai_skill_use_func["#ov_yuejianCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_yuejianCard = 3.4
sgs.ai_use_priority.ov_yuejianCard = -0.8

addAiSkills("ov_muyue").getTurnUseCard = function(self)
	self.ACTN = nil
	self.ov_muyue_to = nil
	sgs.ai_use_priority.ov_muyueCard = 9.8
	if self.player:getMark("ov_muyuebf")>0
	then
		return sgs.Card_Parse("#ov_muyueCard:.:")
	end
	for _,c in sgs.list(self:poisonCards("e"))do
		return sgs.Card_Parse("#ov_muyueCard:"..c:getEffectiveId()..":")
	end
	sgs.ai_use_priority.ov_muyueCard = 1.8
	local c,p = self:getCardNeedPlayer()
	if p and self:isFriend(p) and c and (c:isNDTrick() or c:getTypeId()==1)
	and self:getRestCardsNum(c:getClassName())>0
	then
		self.ov_muyue_to = p
		self.ACTN = c:objectName()
		return sgs.Card_Parse("#ov_muyueCard:"..c:getEffectiveId()..":")
	end
	local cs = self.player:getHandcards()
	cs = self:sortByKeepValue(cs)
	for _,p in sgs.list(self.friends_noself)do
		if self:isWeak(p)
		and p:getHandcardNum()<#cs
		then
			for _,c in sgs.list(cs)do
				if (c:isKindOf("Peach") or c:isKindOf("Analeptic") or c:isKindOf("Jink"))
				and self:getRestCardsNum(c:getClassName())>0
				then
					self.ov_muyue_to = p
					self.ACTN = c:objectName()
					return sgs.Card_Parse("#ov_muyueCard:"..c:getEffectiveId()..":")
				end
			end
		end
	end
	for i,c in sgs.list(cs)do
		if #cs/2<i and table.contains(self.toUse,c)
		and self:getRestCardsNum(c:getClassName())>0
		then
			self.ACTN = c:objectName()
			self.ov_muyue_to = self.player
			return sgs.Card_Parse("#ov_muyueCard:"..c:getEffectiveId()..":")
		end
	end
	if self:getOverflow()>0
	then
		sgs.ai_use_priority.ov_muyueCard = -1.8
		for i,c in sgs.list(cs)do
			if self:getRestCardsNum(c:getClassName())>0
			and #cs/2<i
			then
				self.ACTN = c:objectName()
				return sgs.Card_Parse("#ov_muyueCard:"..c:getEffectiveId()..":")
			end
		end
	end
end

sgs.ai_skill_use_func["#ov_muyueCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_muyueCard = 3.4
sgs.ai_use_priority.ov_muyueCard = 0.8

sgs.ai_skill_playerchosen.ov_muyue = function(self,players)
	if self.ov_muyue_to and players:contains(self.ov_muyue_to)
	then return self.ov_muyue_to end
	local destlist = self:sort(players,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_playerchosen_intention.ov_muyue = -55

sgs.ai_skill_playerchosen.ov_chayi = function(self,players)
	local destlist = self:sort(players,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getHandcardNum()<=target:getHp()
		and target:getHandcardNum()>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getHandcardNum()>0
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and target:getHandcardNum()>0
		then return target end
	end
end

sgs.ai_playerchosen_intention.ov_chayi = 55

sgs.ai_skill_choice.ov_chayi = function(self,choices,data)
	local items = choices:split("+")
	if self.player:getHandcardNum()<1
	then return items[1]
	elseif self:isWeak()
	and self.player:getHandcardNum()<=self.player:getHp()
	then return items[2]
	elseif self.player:getHandcardNum()>4
	then return items[2] end
end

sgs.ai_skill_invoke.ov_zuici = function(self,data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return target:getPhase()>sgs.Player_Play
		or target:getMark("&ov_dingyi1")>0
		or target:getMark("&ov_dingyi2")>0 and self:getOverflow(target)>1
	end
end

sgs.ai_skill_choice.ov_zuici = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	local cs = {}
	for _,cn in sgs.list(items)do
		local d = PatternsCard(cn)
		if d then table.insert(cs,d) end
	end
	if #cs>0
	then
		self:sortByUseValue(cs,self:isEnemy(target))
		return cs[1]:getClassName()
	end
end

addAiSkills("ov_fubi").getTurnUseCard = function(self)
	self.ov_fubi_to = nil
	self.ov_fubi_choice = nil
	for _,p in sgs.list(self.friends)do
		if self:isWeak(p)
		and p:getHandcardNum()<3
		and p:getMark("&ov_dingyi4")<1
		and self:getAllPeachNum()>0
		then
			self.ov_fubi_to = p
			self.ov_fubi_choice = "ov_dingyi4"
			return sgs.Card_Parse("#ov_fubiCard:.:")
		end
	end
	for _,p in sgs.list(self.friends)do
		if p:getHandcardNum()<3
		and p:getMark("&ov_dingyi1")<1
		then
			self.ov_fubi_to = p
			self.ov_fubi_choice = "ov_dingyi1"
			return sgs.Card_Parse("#ov_fubiCard:.:")
		end
	end
	for _,p in sgs.list(self.friends)do
		if self:getOverflow(p)>1
		and p:getMark("&ov_dingyi2")<1
		then
			self.ov_fubi_to = p
			self.ov_fubi_choice = "ov_dingyi2"
			return sgs.Card_Parse("#ov_fubiCard:.:")
		end
	end
	for _,p in sgs.list(self.friends)do
		if self:getOverflow(p)>1
		and p:getMark("&ov_dingyi3")<1
		and p:getAttackRange()<2
		then
			self.ov_fubi_to = p
			self.ov_fubi_choice = "ov_dingyi3"
			return sgs.Card_Parse("#ov_fubiCard:.:")
		end
	end
	for _,p in sgs.list(self.enemies)do
		if self:getOverflow(p)>0 and p:getMark("&ov_dingyi2")+p:getMark("&ov_dingyi3")>0
		or self:getOverflow(p)<1 and p:getMark("&ov_dingyi1")>0
		then
			self.ov_fubi_to = p
			self.ov_fubi_choice = "ov_dingyi4"
			return sgs.Card_Parse("#ov_fubiCard:.:")
		end
	end
	local id = self:poisonCards("e")
	id = #id>0 and id[1]:getEffectiveId()
	if not id
	and self:getOverflow()>=0
	then
		local cs = self.player:getCards("he")
		cs = self:sortByKeepValue(cs)
		id = #cs>0 and cs[1]:getEffectiveId()
	end
	if not id then return end
	id = sgs.Card_Parse("#ov_fubiCard:"..id..":")
	for _,p in sgs.list(self.friends)do
		if self:isWeak(p)
		and p:getHandcardNum()<3
		and p:getMark("&ov_dingyi4")>0
		and self:getAllPeachNum()>0
		then
			self.ov_fubi_to = p
			return id
		end
	end
	for _,p in sgs.list(self.friends)do
		if p:getHandcardNum()<3
		and p:getMark("&ov_dingyi1")>0
		then
			self.ov_fubi_to = p
			return id
		end
	end
	for _,p in sgs.list(self.friends)do
		if self:getOverflow(p)>1
		and p:getMark("&ov_dingyi2")>0
		then
			self.ov_fubi_to = p
			return id
		end
	end
	for _,p in sgs.list(self.friends)do
		if self:getOverflow(p)>1
		and p:getMark("&ov_dingyi3")>0
		and p:getAttackRange()<3
		then
			self.ov_fubi_to = p
			return id
		end
	end
end

sgs.ai_skill_use_func["#ov_fubiCard"] = function(card,use,self)
	if self.ov_fubi_to
	then
		use.card = card
		use.to:append(self.ov_fubi_to)
	end
end

sgs.ai_use_value.ov_fubiCard = 3.4
sgs.ai_use_priority.ov_fubiCard = 4.8

sgs.ai_skill_playerchosen.ov_huiyuan = function(self,players)
	local destlist = self:sort(players,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self.player:inMyAttackRange(target)
		and not target:inMyAttackRange(self.player)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_playerchosen_intention.ov_huiyuan = 55

sgs.ai_skill_playerchosen.ov_zhiqu = function(self,players)
	local destlist = self:sort(players,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self.player:inMyAttackRange(target)
		and target:inMyAttackRange(self.player)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_playerchosen_intention.ov_zhiqu = 55

sgs.ai_skill_choice.ov_xianfeng = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target)
	then return items[1] end
	if not self:isWeak() and self:canDraw()
	then return items[2] end
end

sgs.ai_skill_cardask["ov_xingwu0"] = function(self,data,pattern,prompt)
	local damage = data:toDamage()
	if self:getOverflow()>0
	then
		local cs = self.player:getHandcards()
		cs = self:sortByKeepValue(cs)
		return cs[1]:getEffectiveId()
	end
	if self:isWeak(self.enemies)
	then
		local cs = self.player:getCards("he")
		cs = self:sortByKeepValue(cs)
		return cs[1]:getEffectiveId()
	end
end

sgs.ai_skill_use["@@ov_xingwu"] = function(self,prompt)
	local valid = {}
	for _,id in sgs.list(self.player:getPile("ov_xingwu"))do
    	table.insert(valid,id)
		if #valid>2 then break end
	end
	self:sort(self.enemies,"hp")
	for _,p in sgs.list(self.enemies)do
		return #valid>2 and "#ov_xingwuCard:"..table.concat(valid,"+")..":->"..p:objectName()
	end
end

sgs.ai_skill_invoke.ov_lijian = function(self,data)
	local target = data:toPlayer()
	self.ov_lijian_to = target
	return true
end

sgs.ai_skill_use["@@ov_lijian"] = function(self,prompt)
	local valid = {}
	local ids = self.player:getTag("ov_lijianForAI"):toIntList()
	for _,id in sgs.list(ids)do
    	table.insert(valid,id)
		if #valid>=ids:length()/2 then break end
	end
	if self:isEnemy(self.ov_lijian_to) then table.remove(valid,1) end
	return #valid>0 and "#ov_lijianCard:"..table.concat(valid,"+")..":"
end

sgs.ai_skill_invoke.ov_lijian_damage = function(self,data)
	return self:isEnemy(self.ov_lijian_to)
end

addAiSkills("ov_quanqian").getTurnUseCard = function(self)
	local ids = self:poisonCards("h")
	if self:getOverflow()>0
	then
		local cs = self.player:getHandcards()
		cs = self:sortByKeepValue(cs)
		for _,c in sgs.list(cs)do
			if table.contains(ids,c:getEffectiveId())
			or #ids>1 then continue end
			table.insert(ids,c:getEffectiveId())
		end
	end
	return #ids>1 and sgs.Card_Parse("#ov_quanqianCard:"..table.concat(ids,"+")..":")
end

sgs.ai_skill_use_func["#ov_quanqianCard"] = function(card,use,self)
	local n = 0
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if p:getHandcardNum()>n then n = p:getHandcardNum() end
	end
	for _,p in sgs.list(self.friends_noself)do
		if p:getHandcardNum()>=n
		then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>=n
		then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if p:getHandcardNum()>=n
		then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.ov_quanqianCard = 3.4
sgs.ai_use_priority.ov_quanqianCard = 5.8

sgs.ai_skill_choice.ov_quanqian = function(self,choices,data)
	local items = choices:split("+")
	local target = data:toPlayer()
	self.ov_quanqian_to = target
	if self:isFriend(target)
	then return items[1] end
	return items[2]
end

sgs.ai_skill_suit.ov_quanqian = function(self)
	local sus = {}
	for s,h in sgs.list(self.ov_quanqian_to:getHandcards())do
		s = h:getSuit()
		if sus[s] then sus[s] = sus[s]+1
		else sus[s] = 1 end
	end
	local function func(a,b)
		return a>b
	end
	table.sort(sus,func)
	for i,v in pairs(sus)do
		return i
	end
end

sgs.ai_skill_invoke.ov_shenyi = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return not self:isEnemy(target)
		or self.player:isKongcheng()
	end
end

sgs.ai_skill_choice.ov_shenyi = function(self,choices,data)
	local items = choices:split("+")
	local cs = {}
	for _,n in sgs.list(items)do
		table.insert(cs,dummyCard(n))
	end
	self:sortByKeepValue(cs,true)
	return cs[1]:objectName()
end

addAiSkills("ov_xinghan").getTurnUseCard = function(self)
	local cs = {}
	for _,id in sgs.list(self.player:getPile("ov_xiayi"))do
		table.insert(cs,sgs.Sanguosha:getCard(id))
	end
	return cs
end

function sgs.ai_cardsview.ov_xinghan(self,class_name,player)
	for _,id in sgs.list(player:getPile("ov_xiayi"))do
		if sgs.Sanguosha:getCard(id):isKindOf(class_name)
		then return id end
	end
end

sgs.ai_skill_use["@@ov_xinghan"] = function(self,prompt)
	for _,id in sgs.list(self.player:getPile("ov_xiayi"))do
		local c = sgs.Sanguosha:getCard(id)
		local dummy = self:aiUseCard(c)
		if dummy.card then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			if c:canRecast() and dummy.to:length()<1 then break end
			return id.."->"..table.concat(tos,"+")
		end
		break
	end
end

addAiSkills("ov_chengxi").getTurnUseCard = function(self)
	local mc = self:getMaxCard()
	if mc and mc:getNumber()>10
	then
		for _,c in sgs.list(self.toUse)do
			if (c:getTypeId()==1 or c:isNDTrick()) and mc~=c
			then
				return sgs.Card_Parse("#ov_chengxiCard:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#ov_chengxiCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p)
		then
			use.card = card
			self.ov_chengxi_to = p
			return
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if self.player:canPindian(p) and not self:isFriend(p)
		then
			use.card = card
			self.ov_chengxi_to = p
			return
		end
	end
end

sgs.ai_use_value.ov_chengxiCard = 3.4
sgs.ai_use_priority.ov_chengxiCard = 8.8

sgs.ai_skill_playerchosen.ov_chengxi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
    for _,target in sgs.list(destlist)do
    	if target==self.ov_chengxi_to
		then return target end
	end
	self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
    	if not self:isFriend(target)
		then return target end
	end
    return destlist[1]
end

sgs.ai_playerchosen_intention.ov_chengxi = 55

sgs.ai_skill_invoke.ov_huzhong = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isEnemy(target)
	end
end

sgs.ai_skill_cardask["ov_huzhong0"] = function(self,data,pattern,prompt)
	local use = data:toCardUse()
	for _,p in sgs.list(self.room:getCardTargets(self.player,use.card,use.to))do
		if self:canCanmou(p,use)
		then return true end
	end
	return false
end

sgs.ai_skill_cardask["ov_fenwang0"] = function(self,data,pattern,prompt)
	return true
end

addAiSkills("ov_danlie").getTurnUseCard = function(self)
	local mc = self:getMaxCard()
	if mc and mc:getNumber()+self.player:getLostHp()>10 then
		for _,c in sgs.list(self.toUse)do
			if mc~=c then
				return sgs.Card_Parse("#ov_danlieCard:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#ov_danlieCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p)
		and use.to:length()<3 then
			use.card = card
			use.to:append(p)
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if use.to:length()<3 and not use.to:contains(p) and #self.enemies>0
		and self.player:canPindian(p) and not self:isFriend(p) then
			use.card = card
			use.to:append(p)
		end
	end
end

sgs.ai_use_value.ov_danlieCard = 3.4
sgs.ai_use_priority.ov_danlieCard = 3.8

sgs.ai_skill_choice.ov_zhongyi = function(self,choices,data)
	local items = choices:split("+")
	local n = items[1]:split("=")[2]
	local m = items[3]:split("=")[2]
	if n-m>1 then return items[3] end
	if self:isWeak() then
		return items[2]
	end
	return items[1]
end

sgs.ai_skill_invoke.ov_chue = function(self,data)
	local use = data:toCardUse()
	if use and use.card then
		local du = self:aiUseCard(use.card,dummy(true,99,use.to))
		if du.card and du.to:length()>0 then
			self.ov_chue_to = du.to
			return not self:isWeak()
		end
	else
		local dc = dummyCard()
		dc:setSkillName("_ov_chue")
		local dummy = self:aiUseCard(dc)
		return dummy.card~=nil
	end
end

sgs.ai_skill_playerschosen.ov_chue = function(self,players,x,n)
	local destlist = {}
    for _,p in sgs.list(players)do
		if #destlist<x and self.ov_chue_to:contains(p)
		then table.insert(destlist,p) end
	end
    return destlist
end

sgs.ai_skill_use["@@ov_chue!"] = function(self,prompt)
	local dc = dummyCard()
	dc:setSkillName("_ov_chue")
	local dummy = self:aiUseCard(dc)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return dc:toString().."->"..table.concat(tos,"+")
	end
end

sgs.ai_skill_playerchosen.ov_tianshou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
    	if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
    	if not self:isEnemy(target)
		then return target end
	end
    return destlist[1]
end

sgs.ai_playerchosen_intention.ov_tianshou = -66

addAiSkills("ov_huajing").getTurnUseCard = function(self)
	local ids = {}
	local ss = {}
	local cs = self.player:getHandcards()
	cs = self:sortByKeepValue(cs)
	for _,c in sgs.list(cs)do
		if table.contains(ss,c:getSuit())
		or #ids>#cs/2 then continue end
		table.insert(ids,c:getEffectiveId())
		table.insert(ss,c:getSuit())
	end
	return #ids>0 and sgs.Card_Parse("#ov_huajingCard:"..table.concat(ids,"+")..":")
end

sgs.ai_skill_use_func["#ov_huajingCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_huajingCard = 3.4
sgs.ai_use_priority.ov_huajingCard = 4.8

sgs.ai_skill_cardask["ov_dengjian0"] = function(self,data,pattern,prompt)
	
	return self.player:getHandcardNum()>2
end

sgs.ai_skill_invoke.ov_xinshou = function(self,data)
	local st = data:toString()
	if st~="" then
		return #self.friends>1
	end
	return #self.friends>1
	or self.player:getMark("ov_xinshou1-Clear")<1
end

sgs.ai_skill_playerchosen.ov_xinshou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp",true)
    for _,target in sgs.list(destlist)do
    	if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
    	if not self:isEnemy(target)
		then return target end
	end
    return destlist[1]
end

sgs.ai_playerchosen_intention.ov_xinshou = -66

addAiSkills("ov_jieqiu").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_jieqiuCard:.:")
end

sgs.ai_skill_use_func["#ov_jieqiuCard"] = function(card,use,self)
	self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		local can = true
		for i=0,4 do
			if not p:hasEquipArea(i)
			then can = false break end
		end
		if can and #self:poisonCards("e",p)>p:getEquips():length()/2 then
			use.card = card
			use.to:append(p)
			return 
		end
	end
	self:sort(self.enemies,"equip",true)
	for _,p in sgs.list(self.enemies)do
		local can = true
		for i=0,4 do
			if not p:hasEquipArea(i)
			then can = false break end
		end
		if can then
			use.card = card
			use.to:append(p)
			return 
		end
	end
end

sgs.ai_use_value.ov_jieqiuCard = 3.4
sgs.ai_use_priority.ov_jieqiuCard = 4.8

addAiSkills("ov_enchou").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_enchouCard:.:")
end

sgs.ai_skill_use_func["#ov_enchouCard"] = function(card,use,self)
	self:sort(self.friends_noself,"hp",true)
	for _,p in sgs.list(self.friends_noself)do
		local can = false
		for i=0,4 do
			if not p:hasEquipArea(i)
			then can = true break end
		end
		if can then
			use.card = card
			use.to:append(p)
			return 
		end
	end
	self:sort(self.enemies,"hp")
	for _,p in sgs.list(self.enemies)do
		local can = false
		for i=0,4 do
			if not p:hasEquipArea(i)
			then can = p:getHandcardNum()>0 break end
		end
		if can then
			use.card = card
			use.to:append(p)
			return 
		end
	end
end

sgs.ai_use_value.ov_enchouCard = 3.4
sgs.ai_use_priority.ov_enchouCard = 5.8

sgs.ai_skill_playerschosen.ov_duwang = function(self,players,x,n)
	local destlist = {}
	players = self:sort(players,"handcard")
    for _,p in sgs.list(players)do
		if #destlist<x and p:getCardCount()>0
		then table.insert(destlist,p) end
	end
    return destlist
end

addAiSkills("ov_yanshiYL").getTurnUseCard = function(self)
	local cs = self.player:getHandcards()
	cs = self:sortByKeepValue(cs)
	local sc = nil
	for _,c in sgs.list(cs)do
		if c:isKindOf("Slash") then sc = c break end
	end
	if sc==nil then return end
	local znc = sgs.Sanguosha:getZhinangCards()
	table.insert(znc,"duel")
	for _,pm in sgs.list(znc)do
		local dc = dummyCard(pm)
		dc:setSkillName("ov_yanshiYL")
		dc:addSubcard(sc)
		if dc:isAvailable(self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				if dc:canRecast() and d.to:length()<1 then continue end
				sgs.ai_use_priority.ov_yanshiYLCard = sgs.ai_use_priority[dc:getClassName()]
				sgs.ai_skill_invoke.ov_yanshiYL = pm
				if self.player:getMark("@ov_yanshiYL")<1
				then return sgs.Card_Parse("#ov_yanshiYLCard:.:") end
				for _,p in sgs.list(d.to)do
					if self:isWeak(p) then
						return sgs.Card_Parse("#ov_yanshiYLCard:.:")
					end
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#ov_yanshiYLCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_yanshiYLCard = 3.4
sgs.ai_use_priority.ov_yanshiYLCard = 5.8

sgs.ai_skill_cardask["ov_yanshiYLuse"] = function(self,data,pattern,prompt)
	local dc = sgs.Card_Parse(self.player:property("ov_yanshiYLuse"):toString())
	local dummy = self:aiUseCard(dc)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		if dc:canRecast() and dummy.to:length()<1 then return end
		return dc:toString().."->"..table.concat(tos,"+")
	end
	return "."
end

addAiSkills("ov_juexing").getTurnUseCard = function(self)
	local dc = dummyCard("duel")
	dc:setSkillName("ov_juexing")
	return dc
end

sgs.ai_skill_invoke.ov_qiaosi = function(self,data)
	local st = data:toIntList()
	return st:length()>=self.player:getHp()
	or not self:isWeak() and st:length()>math.random(1,2)
end

sgs.ai_skill_playerschosen.ov_baizu = function(self,players,x,n)
	local destlist = {}
	players = self:sort(players,"handcard")
    for _,p in sgs.list(players)do
		if #destlist<x and p:getHandcardNum()>0 and self:isEnemy(p)
		then table.insert(destlist,p) end
	end
    for _,p in sgs.list(players)do
		if #destlist<x and p:getHandcardNum()>0
		and not table.contains(destlist,p) and not self:isFriend(p)
		then table.insert(destlist,p) end
	end
    return destlist
end


sgs.ai_skill_invoke.ov_beiding = function(self,data)
	local cp = self.room:getCurrent()
	return cp~=self.player or self.player:getHandcardNum()<3
end

sgs.ai_skill_choice.ov_beiding = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"cancel") and math.random()>0.5 then
		return "cancel"
	end
	local cs = {}
	local cp = self.room:getCurrent()
    for _,pn in sgs.list(items)do
		local dc = dummyCard(pn)
		dc:setSkillName("ov_beiding")
		if dc:isAvailable(self.player) then
			table.insert(cs,dc)
			if self.player:isProhibited(cp,dc) then continue end
			local d = self:aiUseCard(dc)
			if d.card then
				if d.to:contains(cp) or dc:isKindOf("AOE") or dc:isKindOf("GlobalEffect") then
					return pn
				end
			end
		end
	end
	self:sortByUseValue(cs)
    for _,dc in sgs.list(cs)do
		local d = self:aiUseCard(dc)
		if d.card then
			return pn
		end
	end
	return items[1]
end

sgs.ai_skill_use["@@ov_beiding"] = function(self,prompt)
    local dc = self.player:property("ov_beidingUse"):toString()
	dc = dummyCard(dc)
	dc:setSkillName("_ov_beiding")
    local d = self:aiUseCard(dc)
   	if d.card then
      	if dc:canRecast() and d.to:length()<1 then return end
		local tos = {}
       	for _,p in sgs.list(d.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dc:toString().."->"..table.concat(tos,"+")
    end
end


sgs.ai_skill_invoke.ov_hunyou = function(self,data)
	return self:getAllPeachNum()+self.player:getHp()<1
end

addAiSkills("ov_huanji").getTurnUseCard = function(self)
	return self.player:isWounded()
	and sgs.Card_Parse("#ov_huanjiCard:.:")
end

sgs.ai_skill_use_func["#ov_huanjiCard"] = function(card,use,self)
	local n = 0
	for _,h in sgs.list(self.player:getHandcards())do
		if h:isNDTrick() or h:isKindOf("BasicCard") then
			if table.contains(self.toUse,h) and self.player:getMark(h:objectName().."ov_beidingHistory")<1
			then n = n+1 end
		end
	end
	if n>self.player:getHp()/2 then
		use.card = card
	end
end

sgs.ai_use_value.ov_huanjiCard = 3.4
sgs.ai_use_priority.ov_huanjiCard = 11.8

sgs.ai_skill_choice.ov_huanji = function(self,choices,data)
	local items = choices:split("+")
	local cs = {}
    for _,pn in sgs.list(items)do
		for _,h in sgs.list(self.player:getHandcards())do
			if h:objectName()==pn then
				if table.contains(self.toUse,h)
				then return pn end
			end
		end
		local dc = dummyCard(pn)
		dc:setSkillName("ov_beiding")
		if dc:isAvailable(self.player) then
			table.insert(cs,dc)
		end
	end
	self:sortByUseValue(cs)
    for _,dc in sgs.list(cs)do
		if self:aiUseCard(dc).card then
			return pn
		end
	end
	return items[1]
end

sgs.ai_skill_invoke.ov_jiezhan = function(self,data)
	local cp = data:toPlayer()
	return self:canDraw() and self:isEnemy(cp)
	and (self:getCardsNum("Jink")>0 or not self:isWeak())
end

addAiSkills("ov_qinghan").getTurnUseCard = function(self)
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	for _,c in sgs.list(cs)do
		if c:isKindOf("EquipCard") and c:getNumber()>9 then
			return sgs.Card_Parse("#ov_qinghanCard:"..c:toString()..":")
		end
	end
end

sgs.ai_skill_use_func["#ov_qinghanCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p) then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.ov_qinghanCard = 3.4
sgs.ai_use_priority.ov_qinghanCard = 5.8

sgs.ai_skill_choice.ov_qinghan = function(self,choices,data)
	local items = choices:split("+")
	local cs = {}
	local cp = data:toPlayer()
    for _,pn in sgs.list(items)do
		local dc = dummyCard(pn)
		dc:setSkillName("ov_qinghan")
		if dc:isAvailable(self.player) then
			table.insert(cs,dc)
			if self.player:isProhibited(cp,dc) then continue end
			local d = self:aiUseCard(dc)
			if d.card then
				if d.to:contains(cp) or dc:isKindOf("AOE") or dc:isKindOf("GlobalEffect") then
					return pn
				end
			end
		end
	end
	self:sortByUseValue(cs)
    for _,dc in sgs.list(cs)do
		if self:aiUseCard(dc).card then
			return pn
		end
	end
	return items[#items]
end

sgs.ai_skill_invoke.ov_zhihuan = function(self,data)
	local damage = data:toDamage()
	self.ov_zhihuan_to = damage.to
	if self:isEnemy(damage.to) then
		return not self:isWeak(damage.to)
	end
	if self:isFriend(damage.to) then
		return #self:poisonCards("e",damage.to)>0
	end
	return true
end

sgs.ai_skill_choice.ov_zhihuan = function(self,choices,data)
	local items = choices:split("+")
	if self:doDisCard(self.ov_zhihuan_to,"e",true) then
		return items[1]
	end
	return items[2]
end

addAiSkills("ov_xianyuan").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_xianyuanCard:.:")
end

sgs.ai_skill_use_func["#ov_xianyuanCard"] = function(card,use,self)
	local n = self.player:getMark("&ov_xianyuan")
	self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if use.to:length()<n then
			use.card = card
			use.to:append(p)
		end
	end
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if use.to:length()<=n/2 then
			use.card = card
			use.to:append(p)
		end
	end
end

sgs.ai_use_value.ov_xianyuanCard = 3.4
sgs.ai_use_priority.ov_xianyuanCard = 0.8

sgs.ai_skill_choice.ov_xianyuan = function(self,choices,data)
	local items = choices:split("+")
	if items[1]:contains("ov_xianyuan0") then
		return items[1]
	end
	local to = data:toPlayer()
	if self:isFriend(to) then
		return items[2]
	end
	return items[1]
end

sgs.ai_skill_invoke.ov_lingyin = function(self,data)
	local use = data:toCardUse()
	return not self:isFriend(use.from) or use.card:isDamageCard()
end

sgs.ai_skill_playerchosen.ov_zongquan = function(self,players,x,n)
	for _,p in sgs.list(players)do
		if p==self.ov_zongquan_tp then
			self.ov_zongquan_tp = nil
			return p
		end
	end
	players = self:sort(players)
    return players[1]
end

sgs.ai_skill_invoke.ov_guimou = function(self,data)
	local judge = data:toJudge()
	self.ov_guimou_judge = judge
	return self:needRetrial(judge) or judge.reason=="ov_zongquan"
end

sgs.ai_skill_askforag.ov_guimou = function(self,card_ids)
	local cs = {}
	for _,id in sgs.list(card_ids)do
		table.insert(cs,sgs.Sanguosha:getCard(id))
	end
	local judge = self.ov_guimou_judge
	if judge.reason=="ov_zongquan" then
		if self:isFriend(judge.who) then
			if self.player:getTag("ov_zongquanTo"):toPlayer()==judge.who then
				for _,c in sgs.list(cs)do
					if judge.who:getTag("ov_zongquanJudge"):toString()~=c:getColorString() and c:isRed() then
						return c:getId()
					end
				end
			else
				for _,c in sgs.list(cs)do
					if c:isBlack() then
						self.ov_zongquan_tp = judge.who
						return c:getId()
					end
				end
			end
		else
			if self.player:getTag("ov_zongquanTo"):toPlayer()==judge.who then
				for _,c in sgs.list(cs)do
					if judge.who:getTag("ov_zongquanJudge"):toString()~=c:getColorString() and c:isBlack() then
						return c:getId()
					end
				end
			elseif math.random()<0.5 then
				for _,c in sgs.list(cs)do
					if c:isRed() then
						self.ov_zongquan_tp = judge.who
						return c:getId()
					end
				end
			end
		end
	end
	local id = self:getRetrialCardId(cs,judge)
	if id>-1 then return id end
	return card_ids[1]
end

sgs.ai_skill_playerchosen.ov_zongquan1 = function(self,players,x,n)
	players = self:sort(players)
	for _,p in sgs.list(players)do
		if self:isFriend(p) and self:canDraw(p) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isFriend(p) then
			return p
		end
	end
    return players[1]
end

sgs.ai_skill_playerchosen.ov_qiji = function(self,players,x,n)
	local dc = dummyCard()
	dc:setSkillName("ov_liyuan")
	local d = self:aiUseCard(dc)
	for _,p in sgs.list(players)do
		if d.to:contains(p) and not self:isFriend(p) then
			return p
		end
	end
end

sgs.ai_skill_playerchosen.ov_qiji1 = function(self,players,x,n)
	players = self:sort(players,nil,true)
	for _,p in sgs.list(players)do
		if self:isFriend(p) and self:canDraw(p) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isFriend(p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.ov_qiji2 = function(self,data)
	local sts = data:toString():split(":")
	local to = BeMan(self.room,sts[2])
	return self:isFriend(to)
	and (not self:isWeak() or self:getCardsNum("Jink")>0)
end

addAiSkills("ov_lifeng").getTurnUseCard = function(self)
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	self:sort(self.enemies)
	for i,c in sgs.list(cs)do
		for n,h in sgs.list(cs)do
			if i<n and self:getKeepValue(h)<6 then
				local x = math.abs(c:getNumber()-h:getNumber())
				for _,p in sgs.list(self.enemies)do
					if self.player:distanceTo(p)<=x and self:damageIsEffective(p) then
						local ids = {c:getId(),h:getId()}
						self.ov_lifeng_to = p
						return sgs.Card_Parse("#ov_lifengCard:"..table.concat(ids,"+")..":")
					end
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#ov_lifengCard"] = function(card,use,self)
	if self.ov_lifeng_to then
		use.card = card
		use.to:append(self.ov_lifeng_to)
	end
end

sgs.ai_use_value.ov_lifengCard = 3.4
sgs.ai_use_priority.ov_lifengCard = 1.8


sgs.ai_skill_cardask["ov_lifeng0"] = function(self,data,pattern,prompt)
	if self:isWeak() or self.player:getCardCount()>3 then
		return true
	end
end

sgs.ai_skill_invoke.ov_lifeng = function(self,data)
	return true
end

sgs.ai_skill_use["@@ov_niwo"] = function(self,prompt)
	local valid = {}
    local ucs = self:getTurnUse()
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if table.contains(ucs,h) then continue end
    	table.insert(valid,h:getEffectiveId())
	end
    self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>1 and p:getHandcardNum()<=#valid and self.player:inMyAttackRange(p) then
			local ids = {}
			for i=1,p:getHandcardNum() do
				table.insert(ids,valid[i])
			end
			return string.format("#ov_niwoCard:%s:->%s",table.concat(ids,"+"),p:objectName())
		end
	end
    for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>0 and p:getHandcardNum()<=#valid and self.player:inMyAttackRange(p) then
			local ids = {}
			for i=1,p:getHandcardNum() do
				table.insert(ids,valid[i])
			end
			return string.format("#ov_niwoCard:%s:->%s",table.concat(ids,"+"),p:objectName())
		end
	end
    for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>0 and self.player:inMyAttackRange(p) then
			local ids = {}
			for i=1,math.min(#valid,p:getHandcardNum()) do
				table.insert(ids,valid[i])
			end
			return string.format("#ov_niwoCard:%s:->%s",table.concat(ids,"+"),p:objectName())
		end
	end
    for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>0 then
			local ids = {}
			for i=1,math.min(#valid,p:getHandcardNum()) do
				table.insert(ids,valid[i])
			end
			return string.format("#ov_niwoCard:%s:->%s",table.concat(ids,"+"),p:objectName())
		end
	end
end

sgs.ai_skill_cardask["ov_guihan0"] = function(self,data,pattern,prompt)
	if self:isWeak() or self.player:getCardCount()>2 then
		return true
	end
end

addAiSkills("ov_guihan").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_guihanCard:.:")
end

sgs.ai_skill_use_func["#ov_guihanCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if use.to:length()<3 and p:getHandcardNum()>0 and p:isWounded() then
			use.card = card
			use.to:append(p)
		end
	end
	local tos = self:sort(self.room:getAlivePlayers())
	for _,p in sgs.list(tos)do
		if use.to:length()<3 and p:getHandcardNum()>0 and not use.to:contains(p)
		and p:isWounded() and not self:isFriend(p) then
			use.card = card
			use.to:append(p)
		end
	end
end

sgs.ai_use_value.ov_guihanCard = 3.4
sgs.ai_use_priority.ov_guihanCard = 2.8

sgs.ai_skill_choice.ov_guihan = function(self,choices,data)
	local items = choices:split("+")
	return items[2]
end

addAiSkills("ov_renxian").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_renxianCard:.:")
end

sgs.ai_skill_use_func["#ov_renxianCard"] = function(card,use,self)
	self:sort(self.friends_noself)
	for _,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			for _,h in sgs.list(self.player:getHandcards())do
				if h:isKindOf("BasicCard") and h:isAvailable(p) and sgs.ais[p:objectName()]:aiUseCard(h).card then
					use.card = card
					use.to:append(p)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.ov_renxianCard = 3.4
sgs.ai_use_priority.ov_renxianCard = -1.8

sgs.ai_skill_playerchosen.ov_chenxun = function(self,players,x,n)
	local dc = dummyCard("duel")
	dc:setSkillName("ov_chenxun")
	local d = self:aiUseCard(dc,dummy(nil,9))
	for _,p in sgs.list(players)do
		if d.to:contains(p) and p:getMark("ov_chenxunTo_lun")<1
		and not self:isFriend(p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.ov_chihui = function(self,data)
	local cp = self.room:getCurrent()
	return self:doDisCard(to,"ej") or self:isFriend(cp) and self:isWeak(cp)
end

sgs.ai_skill_choice.ov_xianyuan = function(self,choices,data)
	local items = choices:split("+")
	if items[1]:contains("ov_chihui") then
		local cp = self.room:getCurrent()
		if self:doDisCard(to,"ej") then
			return items[1]
		end
	end
	return items[#items]
end

sgs.ai_skill_invoke.ov_fuxi = function(self,data)
	return self:canDraw() or self.player:getHp()<1
end

sgs.ai_skill_choice.ov_fuxi = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"ov_fuxi4") then
		return "ov_fuxi4"
	end
	if table.contains(items,"ov_fuxi3") and self.player:getHandcardNum()<3 then
		return "ov_fuxi3"
	end
	if table.contains(items,"ov_fuxi1") and self:isWeak(self.enemies) then
		return "ov_fuxi1"
	end
	return items[#items]
end

sgs.ai_skill_invoke.ov_huangzhu = function(self,data)
	return self:canDraw()
end

addAiSkills("ov_liyuan").getTurnUseCard = function(self)
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	for _,c in sgs.list(cs)do
		if c:isKindOf("EquipCard") and not self.player:hasEquipArea(c:getRealCard():toEquipCard():location()) then
			local dc = dummyCard()
			dc:setSkillName("ov_liyuan")
			dc:addSubcard(c)
			return dc
		end
	end
end

sgs.ai_skill_discard.ov_shouzhu = function(self,max,min,optional)
	local to_cards = {}
	local target = self.room:getCurrent()
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>#cards/2 or #to_cards>2 or self:isEnemy(target) then break end
		table.insert(to_cards,h:getEffectiveId())
	end
	return to_cards
end

sgs.ai_skill_playerschosen.ov_daigui = function(self,players,x,n)
	local destlist = {}
	players = self:sort(players)
    for _,p in sgs.list(players)do
		if #destlist<x and self:isFriend(p) and self:canDraw(p)
		then table.insert(destlist,p) end
	end
    for _,p in sgs.list(players)do
		if #destlist<x and self:canDraw(p)
		and not table.contains(destlist,p) and not self:isEnemy(p)
		then table.insert(destlist,p) end
	end
    return destlist
end

addAiSkills("ov_cairu").getTurnUseCard = function(self)
	local ts = {}
	if self.player:getMark("fire_attackov_cairuUse-Clear")<2 then
		table.insert(ts,"fire_attack")
	end
	if self.player:getMark("iron_chainov_cairuUse-Clear")<2 then
		table.insert(ts,"iron_chain")
	end
	if self.player:getMark("ex_nihiloov_cairuUse-Clear")<2 then
		table.insert(ts,"ex_nihilo")
	end
	if #ts <1 then return end
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
		for n,h in sgs.list(cs)do
			if i<n and c:getColor()~=h:getColor() and self:getKeepValue(h)<6 then
				local dc = dummyCard(ts[math.random(1,#ts)])
				dc:setSkillName("ov_cairu")
				dc:setCanRecast(false)
				dc:addSubcard(h)
				dc:addSubcard(c)
				if dc:isAvailable(self.player) and self:aiUseCard(dc).card then
					return dc
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen.tongxin = function(self,players,x,n)
	players = self:sort(players,nil,true)
	for _,p in sgs.list(players)do
		if self:isFriend(p) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if not self:isEnemy(p) then
			return p
		end
	end
end

sgs.ai_playerchosen_intention.tongxin = -44

sgs.ai_skill_invoke.ov_ciyin = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_choice.ov_ciyin = function(self,choices,data)
	local items = choices:split("+")
	return items[1]
end

sgs.ai_skill_choice.ov_qiyiju = function(self,choices,data)
	local items = choices:split("+")
	if self:isWeak() then return items[1] end
	return items[2]
end

sgs.ai_skill_playerschosen.ov_jushou = function(self,players,x,n)
	local destlist = {}
	players = self:sort(players,nil,true)
    for _,p in sgs.list(players)do
		if #destlist<x and self:isFriend(p)
		then table.insert(destlist,p) end
	end
    for _,p in sgs.list(players)do
		if #destlist<x and self:isEnemy(p)
		and not table.contains(destlist,p)
		then table.insert(destlist,p) end
	end
    for _,p in sgs.list(players)do
		if #destlist<x and not table.contains(destlist,p)
		then table.insert(destlist,p) end
	end
    return destlist
end

sgs.ai_skill_choice.ov_jushou = function(self,choices,data)
	local items = choices:split("+")
	local from = data:toPlayer()
	if not self:isEnemy(from) then return items[1] end
	return items[2]
end

addAiSkills("ov_liaoluanvs").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_liaoluanCard:.:")
end

sgs.ai_skill_use_func["#ov_liaoluanCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self.player:inMyAttackRange(p) and self:damageIsEffective(p) and self:isWeak(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
	if self.player:faceUp() then return end
	for _,p in sgs.list(self.enemies)do
		if self.player:inMyAttackRange(p) and self:damageIsEffective(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.enemies)do
		if self.player:inMyAttackRange(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if self.player:inMyAttackRange(p) and not self:isFriend(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.ov_liaoluanCard = 3.4
sgs.ai_use_priority.ov_liaoluanCard = 1.8

sgs.ai_skill_playerchosen.ov_huaying = function(self,players,x,n)
	players = self:sort(players,nil,true)
	for _,p in sgs.list(players)do
		if self:isFriend(p) and not p:faceUp() then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isFriend(p) and p:isChained() then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isFriend(p) and p:getMark("ov_liaoluanUse")>0 then
			return p
		end
	end
end

sgs.ai_playerchosen_intention.ov_huaying = -66

sgs.ai_skill_playerschosen.ov_juqian = function(self,players,x,n)
    return sgs.ai_skill_playerschosen.ov_jushou(self,players,x,n)
end

sgs.ai_skill_choice.ov_juqian = function(self,choices,data)
	return sgs.ai_skill_choice.ov_jushou(self,choices,data)
end

sgs.ai_skill_playerschosen.ov_juluan = function(self,players,x,n)
    return sgs.ai_skill_playerschosen.ov_jushou(self,players,x,n)
end

sgs.ai_skill_choice.ov_juluan = function(self,choices,data)
	return sgs.ai_skill_choice.ov_jushou(self,choices,data)
end

sgs.ai_skill_invoke.ov_xianxing = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_choice.ov_xianxing = function(self,choices,data)
	local items = choices:split("+")
	if self.player:getMark("&ov_xianxing-Clear")<4 and not self:isWeak()
	then return items[1] end
	return items[2]
end

addAiSkills("ov_xijun").getTurnUseCard = function(self)
	local ts = {"slash","duel"}
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
		if c:isBlack() and self:getKeepValue(c)<6 then
			local dc = dummyCard(ts[math.random(1,2)])
			dc:setSkillName("ov_xijun")
			dc:addSubcard(c)
			if dc:isAvailable(self.player) and self:aiUseCard(dc).card then
				return dc
			end
		end
	end
end

sgs.ai_skill_use["@@ov_xijun"] = function(self,prompt)
	local ts = {"slash","duel"}
	local cs = self.player:getCards("he")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
		if c:isBlack() and self:getKeepValue(c)<6 then
			local dc = dummyCard(ts[math.random(1,2)])
			dc:setSkillName("ov_xijun")
			dc:addSubcard(c)
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
end

function sgs.ai_cardsview.ov_xijun(self,class_name,player)
	local dc = dummyCard(class_name)
	if dc then
		dc:setSkillName("ov_xijun")
		local cards = sgs.QList2Table(player:getCards("he"))
		self:sortByKeepValue(cards)
		for _,c in sgs.list(cards)do
			if c:isBlack() then
				dc:addSubcard(c)
				if not self.player:isLocked(dc) then
					return dc:toString()
				end
				dc:clearSubcards()
			end
		end
	end
end

sgs.ai_use_revises["&ov_xijun"] = function(self,card,use)
	if card:isKindOf("Peach") or card:isKindOf("Analeptic") and self.player:getHp()<1 then
		if self.player:getMark("&ov_xijun+no_recover-Clear")>0 then
			return false
		end
	end
end

sgs.ai_skill_cardask["ov_ronggui0"] = function(self,data,pattern,prompt)
	local use = data:toCardUse()
	self.player:setTag("JincanmouData",data)
	local tos = self.room:getCardTargets(self.player,use.card,use.to)
	local to = sgs.ai_skill_playerchosen.ov_ronggui(self,tos)
	if to then return true end
end

sgs.ai_skill_playerchosen.ov_ronggui = function(self,players)
	return sgs.ai_skill_playerchosen.jincanmou(self,players)
end

sgs.ai_skill_invoke.ov_tanlu = function(self,data)
	local to = data:toPlayer()
	return self:isEnemy(to) or not self:isFriend(to) and self:isWeak()
end

sgs.ai_skill_discard.ov_tanlu = function(self,max,min,optional)
	local to_cards = {}
	local target = self.room:getCurrent()
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min or self:isEnemy(target) and not self:isWeak() then break end
		table.insert(to_cards,h:getEffectiveId())
	end
	return #to_cards>=min and to_cards
end

addAiSkills("ov_bimeng").getTurnUseCard = function(self)
	local ts = {}
	local cs = self.player:getCards("h")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
		if self:getKeepValue(c)<6 then
			table.insert(ts,c)
		end
	end
	if #ts<self.player:getHp() then return end
	cs = {}
	for _,pn in sgs.list(patterns())do
		local dc = dummyCard(pn)
		if dc:isNDTrick() or dc:getTypeId()==1 then
			dc:setSkillName("ov_bimeng")
			for i=1,self.player:getHp() do
				dc:addSubcard(ts[i])
			end
			if dc:isAvailable(self.player) then
				table.insert(cs,dc)
			end
		end
	end
	self:sortByUseValue(cs)
	for i,c in sgs.list(cs)do
		if self:aiUseCard(c).card then
			return c
		end
	end
end

sgs.ai_skill_invoke.ov_zhue = function(self,data)
	local use = data:toCardUse()
	return self:isFriend(use.from) and self:canDraw(use.from)
end

sgs.ai_skill_cardask["ov_fuzhu0"] = function(self,data,pattern,prompt)
	local use = data:toCardUse()
	if self:isFriend(use.from) then
		local cards = self.player:getCards("h")
		cards = self:sortByKeepValue(cards)
		for _,h in sgs.list(cards)do
			if h:getTypeId()==2 and h:isAvailable(use.from) then return h:toString() end
		end
		return true
	end
end

sgs.ai_skill_use["@@ov_fuzhu"] = function(self,prompt)
    for _,id in sgs.list(self.player:getTag("ov_fuzhuForAI"):toIntList())do
		local dc = sgs.Sanguosha:getCard(id)
		if dc:getTypeId()==2 and dc:isAvailable(self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				if dc:canRecast() and d.to:length()<1
				then continue end
				local tos = {}
				for _,p in sgs.list(d.to)do
					table.insert(tos,p:objectName())
				end
				return id.."->"..table.concat(tos,"+")
			end
		end
	end
end

addAiSkills("ov_fenxian").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_fenxianCard:.:")
end

sgs.ai_skill_use_func["#ov_fenxianCard"] = function(card,use,self)
	for _,p in sgs.list(self.friends)do
		if #self:poisonCards("ej",p)>0 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if not self.player:hasEquip() and p:hasEquip() and #self:poisonCards("ej",p)<1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.enemies)do
		if #self.friends<2 and p:hasEquip() and not self.player:hasEquip() then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.enemies)do
		if #self.friends<2 and p:hasEquip() and #self:poisonCards("ej")==self.player:getEquips():length() then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.ov_fenxianCard = 3.4
sgs.ai_use_priority.ov_fenxianCard = 8.8

sgs.ai_skill_playerchosen.ov_fenxian = function(self,players,x,n)
	players = self:sort(players)
	for _,p in sgs.list(players)do
		if self:doDisCard(p,"ej",true) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isEnemy(p) then
			return p
		end
	end
end

sgs.ai_skill_playerschosen.ov_fenxian = function(self,players,x,n)
	players = self:sort(players)
	local tos = {}
	local dc = dummyCard("duel")
	local d = self:aiUseCard(dc)
	for _,p in sgs.list(players)do
		if d.to:contains(p) and #tos<x then
			table.insert(tos,p)
		end
	end
	for _,p in sgs.list(players)do
		if not table.contains(tos,p) and self:isEnemy(p) and #tos<x then
			table.insert(tos,p)
		end
	end
	return tos
end

addAiSkills("ov_shiyi").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_shiyiCard:.:")
end

sgs.ai_skill_use_func["#ov_shiyiCard"] = function(card,use,self)
	for _,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if not self:isEnemy(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.ov_shiyiCard = 3.4
sgs.ai_use_priority.ov_shiyiCard = 8.8

sgs.ai_skill_playerchosen.ov_chunhui = function(self,players,x,n)
	players = self:sort(players)
	for _,p in sgs.list(players)do
		if self:isFriend(p) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if not self:isEnemy(p) and #self.friends<2 then
			return p
		end
	end
end

sgs.ai_playerchosen_intention.ov_chunhui = -66

sgs.ai_skill_invoke.ov_miewei = function(self,data)
	return #self.enemies>0
end

addAiSkills("ov_miyong").getTurnUseCard = function(self)
	local cs = self.player:getCards("h")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
		if c:isKindOf("Slash") and table.contains(self.toUse,c)
		and #self.enemies>0 and self:hasCrossbowEffect() then
			return sgs.Card_Parse("#ov_miyongCard:"..c:toString()..":")
		end
	end
end

sgs.ai_skill_use_func["#ov_miyongCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_miyongCard = 3.4
sgs.ai_use_priority.ov_miyongCard = 1.8

addAiSkills("ov_hanhong").getTurnUseCard = function(self)
	if self:getOverflow()>0 then
		for _,s in sgs.list({"heart","diamond","club","spade"}) do
			if self.player:getMark("ov_hanhong_tiansuan_remove_"..s.."-PlayClear")<1
			then return sgs.Card_Parse("#ov_hanhongCard:.:"..s) end
		end
	end
end

sgs.ai_skill_use_func["#ov_hanhongCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_hanhongCard = 3.4
sgs.ai_use_priority.ov_hanhongCard = 1.8

sgs.ai_skill_invoke.ov_miewei = function(self,data)
	return self:getOverflow()<1
end

addAiSkills("ov_qianxiong").getTurnUseCard = function(self)
	return sgs.Card_Parse("#ov_qianxiongCard:.:")
end

sgs.ai_skill_use_func["#ov_qianxiongCard"] = function(card,use,self)
	self:sort(self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		use.card = card
		use.to:append(p)
		break
	end
end

sgs.ai_use_value.ov_qianxiongCard = 3.4
sgs.ai_use_priority.ov_qianxiongCard = 8.8

sgs.ai_skill_choice.ov_qianxiong = function(self,choices,data)
	local tp = data:toPlayer()
	local ids = tp:getPile("ov_qianxiong")
	local cs = {}
	for _,id in sgs.list(ids)do
		local c = sgs.Sanguosha:getCard(id)
		if self:aiUseCard(c).card then table.insert(cs,c) end
	end
	if #cs>ids:length()/2 then
		return items[2]
	end
	return items[1]
end

sgs.ai_skill_use["@@ov_qianxiong"] = function(self,prompt)
    for _,id in sgs.list(self.player:getTag("ov_qianxiongForAI"):toIntList())do
		local dc = sgs.Sanguosha:getCard(id)
		if dc:isAvailable(self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				if dc:canRecast() and d.to:length()<1
				then continue end
				local tos = {}
				for _,p in sgs.list(d.to)do
					table.insert(tos,p:objectName())
				end
				return id.."->"..table.concat(tos,"+")
			end
		end
	end
end

sgs.ai_skill_playerschosen.ov_zhengdi = function(self,players,x,n)
	players = self:sort(players)
	local tps = {}
	for _,p in sgs.list(players)do
		if #tps<x then
			table.insert(tps,p)
		end
	end
	return tps
end

sgs.ai_skill_playerchosen.ov_zhengdi = function(self,players)
	players = self:sort(players)
	return players[#players]
end

sgs.ai_skill_choice.ov_zhengdi = function(self,choices,data)
	local items = choices:split("+")
	local from = data:toPlayer()
	if self:isFriend(from) then return items[1] end
end

addAiSkills("ov_fushu").getTurnUseCard = function(self)
	local ms = self:getMaxCard()
	if ms and self:aiUseCard(dummyCard("peach")) then
		return sgs.Card_Parse("#ov_fushuCard:"..ms:toString()..":")
	end
end

sgs.ai_skill_use_func["#ov_fushuCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.ov_fushuCard = 3.4
sgs.ai_use_priority.ov_fushuCard = -1.8

function sgs.ai_cardsview.ov_fushu(self,class_name,player)
	local ms = self:getMaxCard()
	if ms and class_name=="Peach" then
		return "#ov_fushuCard:"..ms:toString()..":"
	end
end

sgs.ai_skill_playerchosen.ov_xiumu = function(self,players,x,n)
	players = self:sort(players)
	for _,p in sgs.list(players)do
		if self:isFriend(p) and p:getHandcardNum()<=self.player:getHandcardNum() and self:isWeak(p) then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if self:isEnemy(p) and p:getHandcardNum()>=self.player:getHandcardNum() then
			return p
		end
	end
	for _,p in sgs.list(players)do
		if not self:isFriend(p) and p:getHandcardNum()>self.player:getHandcardNum() then
			return p
		end
	end
end

sgs.ai_skill_use["@@ov_xiumu!"] = function(self,prompt)
	local n = 0
	local valid = {}
	local cs = self.player:getCards("h")
	cs = self:sortByKeepValue(cs)
	for i,c in sgs.list(cs)do
    	table.insert(valid,c:toString())
		n = n+c:getNumber()
		if n>12 then break end
	end
	return "#ov_xiumuCard:"..table.concat(valid,"+")..":"
end

sgs.ai_skill_playerschosen.ov_huiyu = function(self,players,x,n)
	players = self:sort(players,nil,true)
	local tps = {}
	for _,p in sgs.list(players)do
		if #tps<1 and self:isEnemy(p) then
			table.insert(tps,p)
		end
	end
	for _,p in sgs.list(players)do
		if #tps<1 and not self:isFriend(p) then
			table.insert(tps,p)
		end
	end
	for _,p in sgs.list(players)do
		if #tps==1 and not self:isEnemy(p) then
			table.insert(tps,p)
		end
	end
	for _,p in sgs.list(players)do
		if #tps==1 and not table.contains(tps,p) then
			table.insert(tps,p)
		end
	end
	return tps
end

sgs.ai_skill_invoke.ov_beixing = function(self,data)
	local to = data:toPlayer()
	return self:isEnemy(to)
end

sgs.ai_skill_playerchosen.ov_beixing = function(self,players,x,n)
	players = self:sort(players)
	for _,p in sgs.list(players)do
		if self:isFriend(p) then
			return p
		end
	end
end












