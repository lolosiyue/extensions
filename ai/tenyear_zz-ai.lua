
sgs.ai_skill_invoke.yiyong = function(self,data)
	local target = data:toPlayer()
	if target
	then
		return self:isEnemy(target) or not self:isFriend(target) and not self:isWeak(target)
	end
end

sgs.ai_skill_cardask["@cuijin-discard"] = function(self,data,pattern)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
	local use = data:toCardUse()
   	for _,c in sgs.list(cards)do
    	if self.player:canDiscard(self.player,c:getEffectiveId())
		then
			for _,p in sgs.list(use.to)do
				if getCardsNum("Jink",p,self.player)<1 and self:isEnemy(p)
				then return c:getEffectiveId() end
			end
			for _,p in sgs.list(use.to)do
				if getCardsNum("Jink",p,self.player)>0 and self:isEnemy(use.from)
				then return c:getEffectiveId() end
			end
		end
	end
    return "."
end

sgs.ai_skill_use["@@jueman!"] = function(self,prompt)
	local cn = prompt:split(":")[2]
	cn = dummyCard(cn)
	local tos = {}
	if cn
	then
		cn:setSkillName("jueman")
		local d = self:aiUseCard(cn)
		if d.card
		then
			for _,p in sgs.list(d.to)do
				table.insert(tos,p:objectName())
			end
			return cn:toString().."->"..table.concat(tos,"+")
		end
		if cn:targetFixed() then return cn:toString() end
		local players = self.room:getAlivePlayers()
		self:sort(players,"handcard")
		for _,p in sgs.list(players)do
			if self:isEnemy(p) and cn:isDamageCard()
			and self.player:canUse(cn,p,true)
			then table.insert(tos,p:objectName()) end
		end
		if #tos>0
		then
			return cn:toString().."->"..table.concat(tos,"+")
		end
	end
end

addAiSkills("xiaosi").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByUseValue(cards)
  	for _,c in sgs.list(cards)do
		if c:isKindOf("BasicCard")
		and c:isAvailable(self.player)
		then
			local d = self:aiUseCard(c)
			if d.card then
				return sgs.Card_Parse("@XiaosiCard="..c:getEffectiveId())
			end
		end
	end
  	for d,c in sgs.list(cards)do
		if c:isKindOf("BasicCard")
		and c:isAvailable(self.player)
		then
			return sgs.Card_Parse("@XiaosiCard="..c:getEffectiveId())
		end
	end
  	for d,c in sgs.list(cards)do
		if c:isKindOf("BasicCard")
		and self.player:getHandcardNum()>2
		then
			return sgs.Card_Parse("@XiaosiCard="..c:getEffectiveId())
		end
	end
end

sgs.ai_skill_use_func["XiaosiCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if ep:getHandcardNum()>0
		and getKnownCard(self.player,ep,"BasicCard")>0
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends_noself)do
		local kc = getKnownCards(self.player,ep)
		for _,c in sgs.list(kc)do
			if c:isKindOf("BasicCard")
			and c:isAvailable(self.player)
			then
				d = self:aiUseCard(c)
				if d.card
				then
					use.card = card
					use.to:append(ep)
					return
				end
			end
		end
	end
	for _,ep in sgs.qlist(self.room:getOtherPlayers(self.player))do
		local kc = getKnownCards(self.player,ep)
		for _,c in sgs.list(kc)do
			if c:isKindOf("BasicCard")
			and c:isAvailable(self.player)
			then
				d = self:aiUseCard(c)
				if d.card
				then
					use.card = card
					use.to:append(ep)
					return
				end
			end
		end
	end
	for _,ep in sgs.qlist(self.room:getOtherPlayers(self.player))do
		local kc = getKnownCards(self.player,ep)
		for _,c in sgs.list(kc)do
			if c:isKindOf("BasicCard")
			and c:isAvailable(self.player)
			then
				use.card = card
				use.to:append(ep)
				return
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if ep:getHandcardNum()>0
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.XiaosiCard = 9.4
sgs.ai_use_priority.XiaosiCard = 7.8

sgs.ai_skill_discard.xiaosi = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to = self.player:getTag("XiaosiFrom"):toPlayer()
   	for _,c in sgs.list(cards)do
   		if #to_cards>=min then break end
		if c:getTypeId()~=1 then continue end
		if self:isFriend(to)
		then
			if c:isAvailable(to)
			then
				table.insert(to_cards,c:getEffectiveId())
			end
		else
			if not c:isAvailable(to)
			then
				table.insert(to_cards,c:getEffectiveId())
			end
		end
	end
   	for _,c in sgs.list(cards)do
   		if #to_cards>=min then break end
		if c:getTypeId()~=1 then continue end
		table.insert(to_cards,c:getEffectiveId())
	end
	return to_cards
end

sgs.ai_skill_use["@@xiaosi"] = function(self,prompt)
	local cn = self.player:property("XiaosiCards"):toString():split("+")
	local tos = {}
	if #cn>0 then
		local cs = {}
		for _,t in sgs.list(cn)do
			table.insert(cs,sgs.Card_Parse(t))
		end
		self:sortByUseValue(cs)
		for _,c in sgs.list(cs)do
			if c:isAvailable(self.player) then
				local d = self:aiUseCard(c)
				if d.card then
					for _,p in sgs.list(d.to)do
						table.insert(tos,p:objectName())
					end
					return c:toString().."->"..table.concat(tos,"+")
				end
			end
		end
	end
end

sgs.ai_skill_invoke.tenyearqingren = function(self,data)
	return true
end

sgs.ai_skill_use["@@xinggu"] = function(self,prompt)
	for _,id in sgs.list(self.player:getPile("xinggu"))do
		local c = sgs.Sanguosha:getCard(id)
		if c:getTypeId()~=3 then continue end
		if #self:poisonCards({c})>0
		then
			for _,p in sgs.list(self.enemies)do
				local i = c:getRealCard():toEquipCard():location()
				if p:hasEquipArea(i) then
					return "@XingguCard="..id.."->"..p:objectName()
				end
			end
		else
			for _,p in sgs.list(self.friends_noself)do
				local i = c:getRealCard():toEquipCard():location()
				if p:hasEquipArea(i) then
					i = p:getEquip(i)
					if i and #self:poisonCards({i})<1 then continue end
					return "@XingguCard="..id.."->"..p:objectName()
				end
			end
		end
	end
end

sgs.ai_skill_invoke.hongji = function(self,data)
	local to = BeMan(self.room,data:toString():split(":")[2])
    return to and self:isFriend(to)
end

sgs.ai_skill_invoke.daili = function(self,data)
    if self.player:faceUp()
	then
		return self:canDraw() and (self:isWeak() or self.player:getHandcardNum()<3)
	else
		return self:canDraw()
	end
end

sgs.ai_skill_invoke.pitian = function(self,data)
    return self:canDraw()
end

sgs.ai_fill_skill.qiangzhizh = function(self)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards,nil,true) -- 按保留值排序
	for _,ep in sgs.list(self.enemies)do
		if ep:getHp()<2 and #cards>3
		and self:damageIsEffective(ep,"N",self.player)
		then
			local pc = {}
			for _,c in sgs.list(cards)do
				if #pc>=3 then break end
				table.insert(pc,c:getEffectiveId())
			end
			return sgs.Card_Parse("@QiangzhiZHCard="..table.concat(pc,"+"))
		end
	end
	return #cards>0 and sgs.Card_Parse("@QiangzhiZHCard="..cards[1]:getEffectiveId())
end

sgs.ai_skill_use_func["QiangzhiZHCard"] = function(card,use,self)
	self:sort(self.friends_noself,"card",true)
	for _,ep in sgs.list(self.friends_noself)do
		local pc = self:poisonCards("e",ep)
		if #pc>1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if ep:getHp()<2 and card:subcardsLength()>=3
		and self:damageIsEffective(ep,"N",self.player)
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self:sort(self.room:getOtherPlayers(self.player),"card"))do
		if ep:getCardCount()+card:subcardsLength()>3 and not self:isFriend(ep)
		and self:doDisCard(ep,"he")
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.QiangzhiZHCard = 5.4
sgs.ai_use_priority.QiangzhiZHCard = 5.8

sgs.ai_skill_askforyiji.libang = function(self,card_ids,targets)
	for _,p in sgs.list(targets)do
		if self:isFriend(p)
		then
			local cards = {}
			for c,id in sgs.list(card_ids)do
				table.insert(cards,sgs.Sanguosha:getCard(id))
			end
			self:sortByUseValue(cards) -- 按保留值排序
			return p,cards[1]:getEffectiveId()
		end
	end
	for _,p in sgs.list(targets)do
		if not self:isEnemy(p)
		then
			local cards = {}
			for c,id in sgs.list(card_ids)do
				table.insert(cards,sgs.Sanguosha:getCard(id))
			end
			self:sortByUseValue(cards) -- 按保留值排序
			return p,cards[1]:getEffectiveId()
		end
	end
end

sgs.ai_skill_use["@@libang"] = function(self,prompt)
	local d = dummyCard()
	d:setSkillName("_libang")
	local use = self:aiUseCard(d)
	if use.card and use.to
	then
		local tos = {}
		for _,p in sgs.list(use.to)do
			table.insert(tos,p:objectName())
		end
		return d:toString()"->"..table.concat(tos,"+")
	end
end

sgs.ai_fill_skill.libang = function(self)
    local cards = self.player:getCards("he")
    cards = self:sortByUseValue(cards,true,true) -- 按保留值排序
	return #cards>0 and sgs.Card_Parse("@LibangCard="..cards[1]:getEffectiveId())
end

sgs.ai_skill_use_func["LibangCard"] = function(card,use,self)
	self:sort(self.friends_noself,"card",true)
	for _,ep in sgs.list(self.friends_noself)do
		if use.to:length()<1
		and self:doDisCard(ep,"e")
		then use.to:append(ep) end
	end
	for _,ep in sgs.list(self:sort(self.room:getOtherPlayers(self.player),"card"))do
		if use.to:length()<2 and not self:isFriend(ep)
		and self:doDisCard(ep,"he")
		then use.to:append(ep) end
	end
	if use.to:length()>1
	then use.card = card end
end

sgs.ai_use_value.LibangCard = 5.4
sgs.ai_use_priority.LibangCard = 5.8

sgs.ai_skill_invoke.huayi = function(self,data)
    return true
end

sgs.ai_fill_skill.caizhuang = function(self)
	local valid = {}
    local cards = self.player:getCards("he")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	for i,h in sgs.list(cards)do
		if #valid>#cards/2 then break end
		local can = true
		for _,id in sgs.list(valid)do
			if h:getSuit()==sgs.Sanguosha:getCard(id):getSuit()
			then can = false break end
		end
		if can then
			table.insert(valid,h:getEffectiveId())
		end
	end
	local suits = {}
	for _,h in sgs.list(self.player:getCards("h"))do
		if table.contains(valid,h:getEffectiveId()) or table.contains(suits,h:getSuit()) then continue end
		table.insert(suits,h:getSuit())
	end
	return #valid>#suits and sgs.Card_Parse("@CaizhuangCard="..table.concat(valid,"+"))
end

sgs.ai_skill_use_func["CaizhuangCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.CaizhuangCard = 7.4
sgs.ai_use_priority.CaizhuangCard = 5.8

sgs.ai_fill_skill.jijiao = function(self)
	local ids = self.player:getTag("JijiaoRecord"):toIntList()
	if ids:length()<2 then return end
	return #self.toUse<1 and sgs.Card_Parse("@JijiaoCard=.")
end

sgs.ai_skill_use_func["JijiaoCard"] = function(card,use,self)
	local ids = self.player:getTag("JijiaoRecord"):toIntList()
	local n,xt = 0,0
	for _,id in sgs.list(ids)do
		if self.room:getCardPlace(id)==sgs.Player_Discard
		then
			n = n+1
			if self:aiUseCard(sgs.Sanguosha:getCard(id)).card
			then xt = xt+1 end
			if xt>ids:length()/2
			and use.to
			then
				use.card = card
				use.to:append(self.player)
				return
			end
		end
	end
	if n<3 then return end
	self:sort(self.friends,"card",true)
	for _,ep in sgs.list(self.friends)do
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.JijiaoCard = 6.4
sgs.ai_use_priority.JijiaoCard = 6.8

sgs.ai_skill_discard.huizhi = function(self,max,min)
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if p:getHandcardNum()<self.player:getHandcardNum() then continue end
		local cards = self.player:getCards("h")
		local to_cards = {}
		for _,h in sgs.list(self:sortByKeepValue(cards))do
			if #to_cards>min or #to_cards>cards:length()/2 then break end
			table.insert(to_cards,h:getEffectiveId())
		end
		return to_cards
	end
	return {}
end

sgs.ai_skill_choice.yuanmo = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"add")
	then
		local n = 0
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if self.player:distanceTo(p)-1==self.player:getAttackRange()
			and self:doDisCard(p,nil,true)
			then
				n = n+1
			end
		end
		if n>1
		or n>0 and self.player:getAttackRange()<2
		then return "add" end
	end
	if table.contains(items,"reduce")
	and self.player:getAttackRange()>1
	then return "reduce" end
	return "cancel"
end

sgs.ai_skill_use["@@jianjiyh"] = function(self,prompt)
	local d = dummyCard()
	d:setSkillName("_jianjiyh")
	local use = self:aiUseCard(d)
	if use.card and use.to
	then
		local tos = {}
		for _,p in sgs.list(use.to)do
			table.insert(tos,p:objectName())
		end
		return d:toString().."->"..table.concat(tos,"+")
	end
end

sgs.ai_fill_skill.jianjiyh = function(self)
	return sgs.Card_Parse("@JianjiYHCard=.")
end

sgs.ai_skill_use_func["JianjiYHCard"] = function(card,use,self)
	self:sort(self.enemies,"card")
	for _,ep in sgs.list(self.enemies)do
		if ep:getCardCount()>0
		and use.to:length()<self.player:getAttackRange()
		then
			if use.to:length()<1
			then
				use.card = card
				use.to:append(ep)
				continue
			end
			for _,p in sgs.list(use.to)do
				if p:isAdjacentTo(ep)
				then
					use.to:append(ep)
					break
				end
			end
		end
	end
	self:sort(self.friends,"card",true)
	for _,ep in sgs.list(self.friends)do
		if ep:getCardCount()>4 and use.to:length()>0
		and use.to:length()<self.player:getAttackRange()
		then
			for _,p in sgs.list(use.to)do
				if p:isAdjacentTo(ep)
				then
					use.to:append(ep)
					break
				end
			end
		end
	end
	for _,ep in sgs.list(self:sort(self.room:getAlivePlayers(),"card"))do
		if ep:getCardCount()>0 and not self:isFriend(ep)
		and use.to:length()<self.player:getAttackRange()
		and not use.to:contains(ep)
		then
			if use.to:length()<1
			then
				use.card = card
				use.to:append(ep)
				continue
			end
			for _,p in sgs.list(use.to)do
				if p:isAdjacentTo(ep)
				then
					use.to:append(ep)
					break
				end
			end
		end
	end
end

sgs.ai_use_value.JianjiYHCard = 3.4
sgs.ai_use_priority.JianjiYHCard = 9.8

sgs.ai_skill_choice.xiangshuzk = function(self,choices,data)
	local items = choices:split("+")
	local to = data:toPlayer()
	if (not self:isFriend(to) or self:doDisCard(to,"ej"))
	and to:getHandcardNum()<=7
	then
		if to:getHandcardNum()>3
		then
			return tostring(to:getHandcardNum()-2)
		else
			return tostring(to:getHandcardNum()-1)
		end
	end
	return "cancel"
end

sgs.ai_skill_askforag.fozong = function(self,card_ids)
	if not self:isEnemy(self.room:getCurrent())
	then
		local cards = {}
		for c,id in sgs.list(card_ids)do
			table.insert(cards,sgs.Sanguosha:getCard(id))
		end
		self:sortByUseValue(cards) -- 按保留值排序
		return cards[1]:getEffectiveId()
	end
	return -1
end

sgs.ai_skill_playerchosen.cansi = function(self,players)
	local destlist = self:sort(players,"card")
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:hasTrickEffective(dummyCard(),target,self.player)
		and self:hasTrickEffective(dummyCard("duel"),target,self.player)
		and self:hasTrickEffective(dummyCard("fire_attack"),target,self.player)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:hasTrickEffective(dummyCard("duel"),target,self.player)
		and self:hasTrickEffective(dummyCard("fire_attack"),target,self.player)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and self:hasTrickEffective(dummyCard("duel"),target,self.player)
		and self:hasTrickEffective(dummyCard("fire_attack"),target,self.player)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
    return destlist[1]
end

sgs.ai_skill_use["@@saowei"] = function(self,prompt)
	local d = dummyCard()
	d:setSkillName("saowei")
	for _,h in sgs.list(self:sortByUseValue(self.player:getHandcards(),true,true))do
		if h:hasTip("qrasai")
		then
			d:addSubcard(h)
			break
		end
	end
	local use = self:aiUseCard(d)
	if use.card and use.to
	then
		local tos = {}
		for _,p in sgs.list(use.to)do
			table.insert(tos,p:objectName())
		end
		return d:toString().."->"..table.concat(tos,"+")
	end
end

sgs.ai_skill_invoke.aishou = function(self,data)
    return self:canDraw()
end

sgs.ai_skill_discard.jinjin = function(self,max,min)
	local to_cards = {}
	local damage = self.player:getTag("JinjinData"):toDamage()
	if self:isEnemy(damage.from)
	and min<self.player:getCardCount()/2
	then
		local cards = self.player:getCards("he")
		for _,hcard in sgs.list(self:sortByKeepValue(cards))do
			if #to_cards>=min then break end
			table.insert(to_cards,hcard:getEffectiveId())
		end
	end
	return to_cards
end

sgs.ai_skill_invoke.jinjin = function(self,data)
    return self.player:getHp()>self.player:getHandcardNum()
end

sgs.ai_skill_discard.haochong = function(self,max,min)
	local to_cards = {}
	if min<2 then
		local cards = self.player:getCards("h")	
		for _,hcard in sgs.list(self:sortByKeepValue(cards))do
			if #to_cards>=min then break end
			table.insert(to_cards,hcard:getEffectiveId())
		end
	end
	return to_cards
end

sgs.ai_skill_invoke.haochong = function(self,data)
    return self:canDraw()
end

sgs.ai_fill_skill.tenyearlingyin = function(self)
	local valid = {}
    local cards = self.player:getCards("he")
    cards = self:sortByUseValue(cards,true,true) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if h:isKindOf("Weapon")
		or h:isKindOf("Armor")
		then
			local d = dummyCard("duel")
			d:setSkillName("tenyearlingyin")
			d:addSubcard(h)
			table.insert(valid,d)
		end
	end
	return #valid>0 and valid
end

sgs.ai_skill_use["@@tenyearlingyin"] = function(self,prompt)
	local valid = {}
    local cards1,cards2 = {},{}
	for _,id in sgs.list(self.player:getPile("tyrjwywang"))do
		local c = sgs.Sanguosha:getCard(id)
		if #cards1<1 or cards1[1]:getColor()==c:getColor()
		then table.insert(cards1,c)
		else table.insert(cards2,c) end
	end
	local n = self.player:getMark("tenyearlingyin_lun-PalyClear")
	if #cards1<=n
	then
		for _,c in sgs.list(cards1)do
			table.insert(valid,c:getEffectiveId())
		end
		self.player:addMark("lingyin_valid",#valid)
		return "@TenyearLingyinCard="..table.concat(valid,"+")
	end
	if #cards2<=n
	and #cards2>0
	then
		for _,c in sgs.list(cards2)do
			table.insert(valid,c:getEffectiveId())
		end
		self.player:addMark("lingyin_valid",#valid)
		return "@TenyearLingyinCard="..table.concat(valid,"+")
	end
	for _,c in sgs.list(cards1)do
		if #valid>=n then break end
		table.insert(valid,c:getEffectiveId())
	end
	self.player:addMark("lingyin_valid",#valid)
	return "@TenyearLingyinCard="..table.concat(valid,"+")
end

sgs.ai_skill_playerchosen.tenyearliying = function(self,players)
	local destlist = self:sort(players,"hp")
	local n = self.player:getMark("lingyin_valid")
	self.player:setMark("lingyin_valid",0)
	if n>1 then return end
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:canDraw(target)
		then return target end
	end
end

sgs.ai_skill_invoke.tenyearwangyuan = function(self,data)
    return true
end

sgs.ai_fill_skill.jinjianhe = function(self)
	local valid = {}
    local cards = self.player:getCards("he")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	for i,h1 in sgs.list(cards)do
		for n,h2 in sgs.list(cards)do
			if i==n then continue end
			if h1:sameNameWith(h2)
			or h1:getTypeId()==3 and h2:getTypeId()==3 then
				table.insert(valid,h1:getEffectiveId())
				table.insert(valid,h2:getEffectiveId())
				return sgs.Card_Parse("@JinJianheCard="..table.concat(valid,"+"))
			end
		end
	end
end

sgs.ai_skill_use_func["JinJianheCard"] = function(card,use,self)
	self:sort(self.enemies,"card")
	for _,ep in sgs.list(self.enemies)do
		if ep:getMark("jinjianheTarget-PlayClear")<1 then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self:sort(self.room:getAlivePlayers(),"handcard"))do
		if ep:getMark("jinjianheTarget-PlayClear")<1
		and not self:isFriend(ep) then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.JinJianheCard = 3.4
sgs.ai_use_priority.JinJianheCard = 4.8

sgs.ai_use_revises.jinbihun = function(self,card,use)
	if not card:targetFixed()
	and self.player:getHandcardNum()-1>self.player:getMaxCards() then
		if card:isKindOf("BasicCard")
		or card:isKindOf("SingleTargetTrick") then
			for _,p in sgs.list(self.friends_noself)do
				if CanToCard(card,self.player,p) then
					use.card = card
					use.to:append(p)
					return
				end
			end
			return false
		end
	end
end

sgs.ai_skill_cardchosen.tenyearluochong = function(self,who,flags,method)
	if who:getMark("luochongChosen-Clear")<2
	then
		for _,c in sgs.list(who:getCards("ej"))do
			if self:doDisCard(who,c:getEffectiveId())
			then
				who:addMark("luochongChosen-Clear")
				return c:getEffectiveId()
			end
		end
		for _,p in sgs.list(self.room:getOtherPlayers(who))do
			if p:getMark("luochongChosen-Clear")<1
			and self:doDisCard(p,"ej")
			then return -1 end
		end
		if who:objectName()==self.player:objectName()
		then
			if who:getMark("luochongChosen-Clear")>0
			then return -1
			else
				who:addMark("luochongChosen-Clear")
				return self:getCardRandomly(who,"h")
			end
		end
		if self:doDisCard(who,"h")
		and who:getMark("luochongChosen-Clear")<2
		then
			who:addMark("luochongChosen-Clear")
			return self:getCardRandomly(who,"h")
		end
	end
	return -1
end

sgs.ai_skill_playerchosen.tenyearluochong = function(self,players)
	local destlist = self:sort(players,"hp")	
	for _,target in sgs.list(destlist)do
		if self:isFriend(target) and target:getMark("luochongChosen-Clear")<1
		and self:doDisCard(target,"ej")
		then return target end
	end
	if self.room:getDrawPile():length()>80
	and self.player:hasSkill("tenyearaichen")
	and self.player:getMark("luochongChosen-Clear")<1
	and players:contains(self.player)
	then return self.player end
	for _,target in sgs.list(destlist)do
		if self:isEnemy(target) and target:getMark("luochongChosen-Clear")<1
		and self:doDisCard(target,"ej")
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isFriend(target) and target:getMark("luochongChosen-Clear")<1
		and self:doDisCard(target,"hej")
		then return target end
	end
end

sgs.ai_skill_discard.tenyearjinjie = function(self,max,min)
	local to_cards = {}
    local to = self.room:getCurrent()
	if self:isEnemy(to)
	and self:hasTrickEffective(dummyCard(),to,self.player)
	then
		local cards = self.player:getCards("h")	
		for _,hcard in sgs.list(self:sortByKeepValue(cards))do
			if #to_cards>=min then break end
			table.insert(to_cards,hcard:getEffectiveId())
		end
	end
	return to_cards
end

sgs.ai_skill_invoke.tenyearsigong = function(self,data)
    local to = self.room:getCurrent()
	if self:isEnemy(to)
	and self:hasTrickEffective(dummyCard(),to,self.player)
	then return true end
end

sgs.ai_guhuo_card.tenyeargue = function(self,cname,class_name)
	local sj = 0
	for _,h in sgs.list(self.player:getCards("h"))do
		if h:isKindOf("Slash")
		or h:isKindOf("Jink")
		then sj = sj+1 end
	end
	return sj<2 and "@TenyearGueCard=.:"..cname
end

sgs.ai_skill_playerschosen.tenyearyuguan = function(self,players,x,n)
	local destlist = players
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
	self:sort(destlist,"hp")
	local tos = {}
	for _,to in sgs.list(destlist)do
		if #tos>=x then break end
		if self:isFriend(to) and to:getMaxHp()>to:getHandcardNum()
		then table.insert(tos,to) end
	end
	for _,to in sgs.list(destlist)do
		if #tos>=x then break end
		if not table.contains(tos,to)
		then table.insert(tos,to) end
	end
	return tos
end

sgs.ai_skill_invoke.tenyearyuguan = function(self,data)
	local lh = self.player:getLostHp()-1
	if lh>0
	then
		local n = math.max(0,(self.player:getMaxHp()-1)-self.player:getHandcardNum())
		if n>0 then lh = lh-1 end
		self:sort(self.friends_noself,"handcard")
		for _,p in sgs.list(self.friends_noself)do
			if lh<1 then break end
			local x = math.max(0,p:getMaxHp()-p:getHandcardNum())
			if x>0 then lh = lh-1 n = n+x end
		end
		return lh<1 and n>2
	end
end

sgs.ai_skill_playerchosen.tenyearxuewei = function(self,players)
	local destlist = self:sort(players,"hp")	
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:isWeak(target)
		then return target end
	end
	return self.player
end

sgs.ai_fill_skill.xiangmian = function(self)
	return sgs.Card_Parse("@XiangmianCard=.")
end

sgs.ai_skill_use_func["XiangmianCard"] = function(card,use,self)
	self:sort(self.enemies,"handcard",true)
	for _,ep in sgs.list(self.enemies)do
		if ep:getMark("xiangmianTarget-Keep")<1
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.XiangmianCard = 3.4
sgs.ai_use_priority.XiangmianCard = 9.8

sgs.ai_skill_use["@@tenyearjue"] = function(self,prompt)
	local use = dummy(true,99)
	use = self:aiUseCard(dummyCard(),use)
	if use.card and use.to
	then
		for _,p in sgs.list(use.to)do
			if p:getHp()==p:getMaxHp()
			then return "@TenyearJueCard=.->"..p:objectName() end
		end
	end
end

sgs.ai_skill_discard.tenyearjinjie = function(self,max,min)
	local to_cards = {}
	local dy = self.room:getCurrentDyingPlayer()
	if not (dy and self:isFriend(dy)) then return {} end
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min then break end
		table.insert(to_cards,h:getEffectiveId())
	end
	return to_cards
end

sgs.ai_skill_invoke.tenyearjinjie = function(self,data)
	local to = BeMan(self.room,data:toString():split(":")[2])
    return to and self:isFriend(to)
end

sgs.ai_skill_use["@@tenyearzhaohan!"] = function(self,prompt)
	local valid,to = {},nil
	for _,p in sgs.list(self.friends_noself)do
		if p:isKongcheng() and not self:needKongcheng(p,true)
		then to = p break end
	end
    local cards = self.player:getCards("h")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	for _,h in sgs.list(cards)do
		if #valid>=2 then break end
    	table.insert(valid,h:getEffectiveId())
	end
	if #valid<2 then return end
	return "@TenyearZhaohanCard="..table.concat(valid,"+").."->"..to:objectName()
end

sgs.ai_skill_choice.tenyearzhaohan = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"give")
	then
		for _,p in sgs.list(self.friends_noself)do
			if p:isKongcheng()
			and not self:needKongcheng(p,true)
			then return "give" end
		end
	end
	return "discard"
end

sgs.ai_skill_invoke.tenyearzhaohan = function(self,data)
    return self:canDraw()
end

sgs.ai_skill_choice.juying = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"cishu")
	then return "cishu"
	elseif table.contains(items,"draw")
	and (self.player:getHp()>1 or self:isWeak())
	then return "draw" end
	if table.contains(items,"maxcards")
	and 4-#items<self.player:getHp()
	and self:getOverflow()>0
	then
		return "maxcards"
	end
	return "cancel"
end

sgs.ai_skill_playerchosen.anzhi = function(self,players)
	local destlist = self:sort(players,"card")
	for _,target in sgs.list(destlist)do
		if self:isFriend(target) and self:canDraw(target)
		then return target end
	end
	for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	self.player:addMark("ai_anzhi-PlayClear")
end

sgs.ai_fill_skill.anzhi = function(self)
	return (self.player:getMark("&xialei_watch-Clear")>1 or #self.toUse<1)
	and self.player:getMark("ai_anzhi-PlayClear")<1
	and sgs.Card_Parse("@AnzhiCard=.")
end

sgs.ai_skill_use_func["AnzhiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.AnzhiCard = 3.4
sgs.ai_use_priority.AnzhiCard = 9.8

sgs.ai_skill_invoke.anzhi = function(self,data)
    return self.player:getMark("&xialei_watch-Clear")>1 or #self.toUse<1
end

sgs.ai_skill_invoke.xialei = function(self,data)
    return self:canDraw()
end

sgs.ai_skill_playerchosen.zhanmeng = function(self,players)
	local destlist = self:sort(players,"card")
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

sgs.ai_skill_choice.zhanmeng = function(self,choices,data)
	local items = choices:split("+")
	local use = data:toCardUse()
	if table.contains(items,"last")
	then return "last"
	elseif table.contains(items,"next")
	then
		if self.player:getMark("@extra_turn")>0
		then
			if self:getCardsNum(use.card:getClassName())>0
			then return "next" end
		else
			if getCardsNum(use.card:getClassName(),self.room:getCurrent():getNextAlive(),self.player)>0
			then return "next" end
		end
	end
	if table.contains(items,"discard")
	and #self.enemies>0
	then
		return "discard"
	end
	
	return "cancel"
end

sgs.ai_skill_playerchosen.wumei = function(self,players)
	local destlist = self:sort(players,"handcard",true)	
	for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_playerschosen.tingxian = function(self,players,x,n)
	local destlist = self:sort(players,"hp")	
	local tos = {}
	for _,to in sgs.list(destlist)do
		if #tos<x and self:isFriend(to)
		and not self:isPriorFriendOfSlash(to,dummyCard())
		then table.insert(tos,to) end
	end
	return tos
end

sgs.ai_skill_invoke.tingxian = function(self,data)
	for _,ep in sgs.list(self.friends_noself)do
		if self.player:inMyAttackRange(ep)
		then return true end
	end
    return self:canDraw()
end

sgs.ai_target_revises.enyu = function(to,card,self,use)
	return to:getMark("enyu_target_"..card:objectName().."-Clear")>0
end

sgs.ai_fill_skill.jingzao = function(self)
	return sgs.Card_Parse("@JingzaoCard=.")
end

sgs.ai_skill_use_func["JingzaoCard"] = function(card,use,self)
	self:sort(self.friends_noself,"handcard",true)
	for _,ep in sgs.list(self.friends_noself)do
		if ep:getMark("jingzao_target-PlayClear")>0 then continue end
		if ep:getHandcardNum()>4
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self:sort(self.room:getOtherPlayers(self.player),"handcard",true))do
		if ep:getMark("jingzao_target-PlayClear")>0 then continue end
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.JingzaoCard = 3.4
sgs.ai_use_priority.JingzaoCard = 9.8

sgs.ai_guhuo_card.fengying = function(self,cname,class_name)
	local d = dummyCard(cname)
	if d
	then
		d:setSkillName("fengying")
		local cards = self.player:getCards("h")
		cards = self:sortByKeepValue(cards,nil,true)
		for _,h in sgs.list(cards)do
			if h:getNumber()<=self.player:getMark("&dgrlzjiao")
			then
				d:addSubcard(h)
				return d:toString()
			end
		end
	end
end

sgs.ai_fill_skill.fengying = function(self)
	local record = self.player:property("SkillDescriptionRecord_fengying"):toString():split("+")
	if #record<1 then return end
	local cancs = {}
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
  	for c,h in sgs.list(cards)do
		if h:getNumber()>self.player:getMark("&dgrlzjiao")
		then else table.insert(cancs,h:getEffectiveId()) break end
	end
	if #cancs<1 then return end
	local records = {}
  	for _,cn in sgs.list(record)do
		local c = dummyCard(cn)
		c:setSkillName("fengying")
		c:addSubcard(cancs[1])
		if c:isAvailable(self.player)
		then
			local uc = self:aiUseCard(c)
			if uc.card
			then
				self.fengying_to = uc.to
				if c:canRecast() and uc.to:length()<1 then continue end
				sgs.ai_use_priority.FengyingCard = sgs.ai_use_priority[c:getClassName()]
				return sgs.Card_Parse("@FengyingCard="..cancs[1]..":"..cn)
			end
		end
	end
end

sgs.ai_skill_use_func["FengyingCard"] = function(card,use,self)
	use.card = card
	use.to = self.fengying_to
end

sgs.ai_use_value.FengyingCard = 3.4
sgs.ai_use_priority.FengyingCard = 9.8

sgs.ai_skill_playerchosen.lianzhi_shouze = function(self,players)
	local destlist = self:sort(players,"hp",true)	
	for _,to in sgs.list(destlist)do
		if self:isFriend(to)
		then return to end
	end
	for _,to in sgs.list(destlist)do
		if not self:isEnemy(to)
		then return to end
	end
    return destlist[1]
end

sgs.ai_skill_playerchosen.lianzhi = function(self,players)
	local destlist = self:sort(players,"hp",true)	
	for _,to in sgs.list(destlist)do
		if self:isFriend(to)
		then return to end
	end
	for _,to in sgs.list(destlist)do
		if not self:isEnemy(to)
		then return to end
	end
    return destlist[1]
end

sgs.ai_skill_choice.zuojian = function(self,choices,data)
	local items = choices:split("+")
	local maxE,minE = 0,0
	for i,p in sgs.list(self.room:getAlivePlayers())do
		if p:getEquips():length()>self.player:getEquips():length()
		then
			if self:isEnemy(p) then maxE = maxE-1
			else maxE = maxE+1 end
		elseif p:getEquips():length()<self.player:getEquips():length()
		then
			if self:isFriend(p) then maxE = maxE-1
			else maxE = maxE+1 end
		end
	end
	if maxE>0 then return "draw"
	elseif minE>0
	then return "discard" end
	if maxE>=0 then return "draw"
	elseif minE>=0
	then return "discard" end
	return "draw"
end

sgs.ai_skill_invoke.zhengxu = function(self,data)
	local str = data:toString()
	if str:match("draw") then
		return self:canDraw()
	else
		return not self:needToLoseHp()
	end
end

sgs.ai_fill_skill.cuichuan = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if #cards>2 or self:getOverflow()>0
		then return sgs.Card_Parse("@CuichuanCard="..c:getEffectiveId()) end
	end
end

sgs.ai_skill_use_func["CuichuanCard"] = function(card,use,self)
	self:sort(self.friends,"hp")
	for _,ep in sgs.list(self.friends)do
		if ep:hasEquip()
		and ep:getEquips():length()<4
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self.friends)do
		if ep:hasEquipArea()
		and ep:getEquips():length()<4
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	for _,ep in sgs.list(self:sort(self.room:getAlivePlayers(),"equip"))do
		if ep:hasEquipArea() and not self:isEnemy(ep)
		and ep:getEquips():length()<4
		then
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

sgs.ai_use_value.CuichuanCard = 3.4
sgs.ai_use_priority.CuichuanCard = 4.8

sgs.ai_fill_skill.kanji = function(self)
	local suits = {}
  	for _,c in sgs.list(self.player:getCards("h"))do
		if table.contains(suits,c:getSuit()) then return end
		table.insert(suits,c:getSuit())
	end
	return sgs.Card_Parse("@KanjiCard=.")
end

sgs.ai_skill_use_func["KanjiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.KanjiCard = 3.4
sgs.ai_use_priority.KanjiCard = 9.8


sgs.ai_skill_playerchosen.silve = function(self,players)
	local destlist = self:sort(players,nil,true)	
	for _,to in sgs.list(destlist)do
		if self:isFriend(to)
		then return to end
	end
	for _,to in sgs.list(destlist)do
		if not self:isEnemy(to)
		then return to end
	end
    return destlist[1]
end

sgs.ai_skill_invoke.silve = function(self,data)
	local damage = data:toDamage()
	return self:doDisCard(damage.to,"he",true)
end

sgs.ai_fill_skill.shuaijie = function(self)
	return sgs.Card_Parse("@ShuaijieCard=.")
end

sgs.ai_skill_use_func["ShuaijieCard"] = function(card,use,self)
  	for _,p in sgs.list(self.room:getAlivePlayers())do
		if p:getMark("&silve+#"..self.player:objectName())>0
		and self:isFriend(p) and self:isWeak(p) then return end
	end
	use.card = card
end

sgs.ai_use_value.ShuaijieCard = 3.4
sgs.ai_use_priority.ShuaijieCard = 9.8


sgs.ai_skill_invoke.tenyearfuning = function(self,data)
	local str = data:toString()
	local strs = str:split(":")
	local n = tonumber(strs[2])
	if n<3 or n<(self.player:getCardCount()+2)/2 then
		return self:canDraw()
	end
end

sgs.ai_fill_skill.tenyearbingji = function(self)
	return sgs.Card_Parse("@TenyearBingjiCard=.")
end

sgs.ai_skill_use_func["TenyearBingjiCard"] = function(card,use,self)
  	local dcp = dummyCard("peach")
	dcp:setSkillName("tenyearbingji")
	self:sort(self.friends_noself)
  	for _,p in sgs.list(self.friends_noself)do
		if self:isWeak(p) and self.player:conUse(dcp,p) then
			sgs.ai_skill_choice.tenyearbingji = "peach"
			use.card = card
			return
		end
	end
  	local dc = dummyCard()
	dc:setSkillName("tenyearbingji")
	if not self.player:isLocked(dc) then
		local d = self:aiUseCard(dc)
		if d.card then
			self.tenyearbingjiUse = d
			sgs.ai_skill_choice.tenyearbingji = "slash"
			use.card = card
			return
		end
	end
  	for _,p in sgs.list(self.friends_noself)do
		if self.player:conUse(dcp,p) then
			sgs.ai_skill_choice.tenyearbingji = "peach"
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.TenyearBingjiCard = 3.4
sgs.ai_use_priority.TenyearBingjiCard = 2.8

sgs.ai_skill_use["@@tenyearbingji!"] = function(self,prompt)
	local use = self.tenyearbingjiUse
	if use.card then
		for _,p in sgs.list(use.to)do
			return use.card:toString().."->"..p:objectName()
		end
	end
end

sgs.ai_skill_playerchosen.tenyearbingji = function(self,players)
	local destlist = self:sort(players)	
	for _,to in sgs.list(destlist)do
		if self:isFriend(to)
		then return to end
	end
	for _,to in sgs.list(destlist)do
		if not self:isEnemy(to)
		then return to end
	end
    return destlist[1]
end










