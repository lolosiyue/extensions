sgs.ai_skill_invoke.keshuaizhimeng = function(self,data)
	return true
end

sgs.ai_skill_invoke.keshuaitianyu = function(self,data)
	return true
end

sgs.ai_fill_skill.keshuaizhuni = function(self)
    return sgs.Card_Parse("#keshuaizhuniCard:.:")
end

sgs.ai_skill_use_func["#keshuaizhuniCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.keshuaizhuniCard = 3.4
sgs.ai_use_priority.keshuaizhuniCard = 8.2

sgs.ai_skill_playerchosen.keshuaizhuni = function(self,players)
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

sgs.ai_skill_discard.keshuaixiangru = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
   	for _,hcard in sgs.list(cards)do
   		if #to_cards>=min then break end
     	table.insert(to_cards,hcard:getEffectiveId())
	end
	local to = self.player:getTag("keshuaixiangruTo"):toPlayer()
	if self:isFriend(to) then return to_cards end
	return {}
end

sgs.ai_skill_playerchosen.keshuaijinglei = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and #self.enemies<1
		then return target end
	end
end

sgs.ai_skill_use["@@keshuaijinglei"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAlivePlayers()
    destlist = self:sort(destlist,"handcard")
	local n = 0
	for _,to in sgs.list(destlist)do
		if n+to:getHandcardNum()<self.player:getMark("keshuaijinglei") then
			table.insert(valid,to:objectName())
			n = n+to:getHandcardNum()
		end
	end
	if #valid>1 then
    	return string.format("#keshuaijingleiCard:.:->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_playerschosen.keshuaiyansha = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:isWeak(p)
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and not self:isWeak(p) and #destlist/2>#tos
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and #self.friends>1
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_use["@@keshuaiyansha"] = function(self,prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
   	for _,c in sgs.list(cards)do
		if c:getTypeId()<3 then continue end
		local dc = dummyCard()
		dc:setSkillName("_keshuaiyansha")
		dc:addSubcard(c)
		if not dc:isAvailable(self.player) then continue end
		local dummy = self:aiUseCard(dc)
		if dummy.card and dummy.to then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			return dc:toString().."->"..table.concat(tos,"+")
		end
	end
end

sgs.ai_skill_playerchosen.keshuaizhushou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		and #self.enemies<1
		then return p end
	end
end

local keshuaiyanggeex={}
keshuaiyanggeex.name="keshuaiyanggeex"
table.insert(sgs.ai_skills,keshuaiyanggeex)
keshuaiyanggeex.getTurnUseCard = function(self)
    return sgs.Card_Parse("#keshuaiyanggeCard:.:")
end

sgs.ai_skill_use_func["#keshuaiyanggeCard"] = function(card,use,self)
	local dc = sgs.Card_Parse("@MizhaoCard=.")
	local d = self:aiUseCard(dc)
	if d.card then
		for _,p in sgs.list(d.to)do
			if p:hasSkill("keshuaiyangge") then
				use.card = card
				use.to:append(p)
				return
			end
		end
	end
	if #self.toUse<2 then
		for _,p in sgs.list(self.friends_noself)do
			if not p:hasSkill("keshuaiyangge") then continue end
			for _,e in sgs.list(self.enemies)do
				if self:slashIsEffective(dummyCard(),e,p) then
					use.card = card
					use.to:append(p)
					return
				end
			end
		end
		if self.player:getHandcardNum()/2<=#self:poisonCards("h") then
			for _,p in sgs.list(self.enemies)do
				if not p:hasSkill("keshuaiyangge") then continue end
				for _,e in sgs.list(self.enemies)do
					if p~=e and self:slashIsEffective(dummyCard(),e,p) then
						use.card = card
						use.to:append(p)
						return
					end
				end
			end
		end
		if self.player:getHandcardNum()<2 then
			for _,p in sgs.list(self.enemies)do
				if not p:hasSkill("keshuaiyangge") then continue end
				for _,e in sgs.list(self.enemies)do
					if p~=e and self:slashIsEffective(dummyCard(),e,p) then
						use.card = card
						use.to:append(p)
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_value.keshuaiyanggeCard = 6.4
sgs.ai_use_priority.keshuaiyanggeCard = 1.4

local keshuaisaojian={}
keshuaisaojian.name="keshuaisaojian"
table.insert(sgs.ai_skills,keshuaisaojian)
keshuaisaojian.getTurnUseCard = function(self)
	return sgs.Card_Parse("#keshuaisaojianCard:.:")
end

sgs.ai_skill_use_func["#keshuaisaojianCard"] = function(card,use,self)
	self:sort(self.enemies,"handcard",true)
	for _,to in sgs.list(self.enemies)do
     	if to:getHandcardNum()>0 then
			use.card = card
			use.to:append(to)
			break
		end
   	end
end

sgs.ai_use_value.keshuaisaojianCard = 6.4
sgs.ai_use_priority.keshuaisaojianCard = 8.4

local keshuaiguanshi={}
keshuaiguanshi.name="keshuaiguanshi"
table.insert(sgs.ai_skills,keshuaiguanshi)
keshuaiguanshi.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if h:isKindOf("Slash") then
			local dc = dummyCard("FireAttack")
			dc:setSkillName("keshuaiguanshi")
			dc:addSubcard(h)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
end

sgs.ai_skill_invoke.keshuaicangxiong = function(self,data)
	local id = self.player:getTag("keshuaicangxiongId"):toInt()
	local to = self.room:getCardOwner(id)
	return not(to and self:isFriend(to))
	and (not self.player:hasSkill("keshuaibaowei",true) or sgs.Sanguosha:getCard(id):isAvailable(self.player))
end

sgs.ai_use_revises.keshuaibaowei = function(self,card,use)
	local n = 0
	local to = nil
	for _, dmd in sgs.qlist(self.room:getOtherPlayers(self.player)) do   
		if dmd:getMark("&keshuaibaowei-Clear")>0 then
			n = n+1
			to = dmd
		end
	end
	if n==1 and self:isEnemy(to) then
		if card:getTypeId()==3 or card:getTypeId()==0
		then return end
		if card:getTypeId()==1 and card:targetFixed()
		then return end
		return false
	end
end

sgs.ai_skill_playerschosen.keshuairuzong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) or not self:isEnemy(p) and #self.enemies>0
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_invoke.keshuairuzong = function(self,data)
	return true
end

local keshuaidaoren={}
keshuaidaoren.name="keshuaidaoren"
table.insert(sgs.ai_skills,keshuaidaoren)
keshuaidaoren.getTurnUseCard = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	if #cards<2 then return end
	for _,h in sgs.list(cards)do
		return sgs.Card_Parse("#keshuaidaorenCard:"..h:getId()..":")
	end
end

sgs.ai_skill_use_func["#keshuaidaorenCard"] = function(card,use,self)
	local destlist = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(destlist)
	for _,p in sgs.list(self.friends_noself)do
		for _,to in sgs.list(destlist)do
			if self.player:inMyAttackRange(to) and p:inMyAttackRange(to) and self:isEnemy(to) then
				use.to:append(p)
				use.card = card
				return
			end
		end
	end
	for _,p in sgs.list(destlist)do
     	if self:isEnemy(to) then continue end
		for _,to in sgs.list(destlist)do
			if self.player:inMyAttackRange(to) and p:inMyAttackRange(to) and self:isEnemy(to) then
				use.to:append(p)
				use.card = card
				return
			end
		end
   	end
	for _,p in sgs.list(destlist)do
		for _,to in sgs.list(destlist)do
			if self.player:inMyAttackRange(to) and p:inMyAttackRange(to) and self:isEnemy(to) and self:isWeak(to) then
				use.to:append(p)
				use.card = card
				return
			end
		end
   	end
end

sgs.ai_use_value.keshuaidaorenCard = 3.4
sgs.ai_use_priority.keshuaidaorenCard = 2.4

sgs.ai_skill_invoke.keshuaixuchong = function(self,data)
	return true
end

sgs.ai_skill_choice.keshuaixuchong = function(self,choices)
	local items = choices:split("+")
	local to = self.room:getCurrent()
	if to==self.player then
		if self:getOverflow()>1 then
			return items[2]
		end
	elseif self:isFriend(to) and self:isWeak(to) then
		if self:getOverflow()>0 then
			return items[2]
		end
	end
	return items[1]
end

sgs.ai_skill_invoke.keshuaigangfen = function(self,data)
	local str = data:toString()
	local use = self.room:getTag("keshuaigangfenData"):toCardUse()
	if str:contains("ask2") then
		if self:isFriend(use.to:at(0)) then
			return true
		end
	else
		if self:isEnemy(use.from) and self:isFriend(use.to:at(0)) then
			return #self.friends>use.from:getHandcardNum()/2
		end
	end
end

sgs.ai_skill_invoke.keshuaidangren = function(self,data)
	return true
end


local keshuaidangren={}
keshuaidangren.name="keshuaidangren"
table.insert(sgs.ai_skills,keshuaidangren)
keshuaidangren.getTurnUseCard = function(self)
	local dc = dummyCard("Peach")
	dc:setSkillName("keshuaidangren")
	return dc
end

local keshuaiqiluan={}
keshuaiqiluan.name="keshuaiqiluan"
table.insert(sgs.ai_skills,keshuaiqiluan)
keshuaiqiluan.getTurnUseCard = function(self)
    local dc = dummyCard()
	dc:setSkillName("keshuaiqiluan")
	local d = self:aiUseCard(dc)
	if d.card then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards) -- 将列表转换为表
		local tos = sgs.ai_skill_playerschosen.keshuaiqiluan(self,self.room:getOtherPlayers(self.player),#cards,1)
		self:sortByKeepValue(cards) -- 按保留值排序
		local ids = {}
		for _,c1 in sgs.list(cards)do
			if #ids>=#tos then break end
			table.insert(ids,c1:getId())
		end
		if #ids<1 then return end
		self.keshuaiqiluanTo = d.to
		return sgs.Card_Parse("#keshuaiqiluanCard:"..table.concat(ids,"+")..":slash")
	end
end

sgs.ai_skill_use_func["#keshuaiqiluanCard"] = function(card,use,self)
	use.card = card
	use.to = self.keshuaiqiluanTo
end

sgs.ai_use_value.keshuaiqiluanCard = 6.4
sgs.ai_use_priority.keshuaiqiluanCard = 2.4

sgs.ai_skill_playerschosen.keshuaiqiluan = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard",true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isFriend(p) then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if table.contains(tos,p) then continue end
		if #tos<=x/2 and not self:isEnemy(p) then table.insert(tos,p) end
	end
    return tos
end

sgs.ai_guhuo_card.keshuaiqiluan = function(self,toname,class_name)
	if self:getCardsNum(class_name)>0 then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards) -- 将列表转换为表
	local tos = sgs.ai_skill_playerschosen.keshuaiqiluan(self,self.room:getOtherPlayers(self.player),#cards,1)
	self:sortByKeepValue(cards) -- 按保留值排序
	local ids = {}
	for _,c1 in sgs.list(cards)do
		if #ids>=#tos then break end
		table.insert(ids,c1:getId())
	end
	if #ids<1 then return end
	return "#keshuaiqiluanCard:"..table.concat(ids,"+")..":"..toname
end

sgs.ai_skill_cardask.keshuaiqiluan = function(self,data,pattern,prompt)
    local parsed = data:toPlayer()
    if self:isFriend(parsed)
	then return true end
	return "."
end

local keshuaixiangjia={}
keshuaixiangjia.name="keshuaixiangjia"
table.insert(sgs.ai_skills,keshuaixiangjia)
keshuaixiangjia.getTurnUseCard = function(self)
	local dc = dummyCard("Collateral")
	dc:setSkillName("keshuaixiangjia")
	return dc
end

sgs.ai_skill_invoke.keshuaixiangjia = function(self,data)
	return true
end

sgs.ai_skill_invoke.keshuaijueyin = function(self,data)
	return true
end

sgs.ai_skill_invoke.keshuaizonghai = function(self,data)
	local to = data:toPlayer()
	return self:isEnemy(to) or not self:isFriend(to) and #self.enemies<1
end

sgs.ai_skill_playerschosen.keshuaizonghai = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isFriend(p) and getCardsNum("Peach",p,self.player)>0
		and p:getHp()>1 then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isEnemy(p) and p:getHp()<2
		then table.insert(tos,p) end
	end
	return tos
end


sgs.ai_skill_discard.keshuaisaojian = function(self,max,min,optional)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	return {cards[math.random(1,#cards)]}
end
















