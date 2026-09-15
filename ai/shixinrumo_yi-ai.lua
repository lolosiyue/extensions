

sgs.ai_skill_invoke.yikuxin = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_playerchosen.yikuxin = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local has = false
	local ids = self.player:getTag("yikuxinIds"):toIntList()
	for _,id in sgs.list(ids)do
		if sgs.Sanguosha:getCard(id):getSuit()==2 then has = true end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		and p:getHandcardNum()>ids:length()
		and getKnownCard(p,self.player,"heart","h")>0
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and not has
		and getKnownCard(p,self.player,"heart","h")>0
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and not has
		then return p end
	end
end

sgs.ai_fill_skill.yisigu = function(self)
	return sgs.Card_Parse("#yisiguCard:.:")
end

sgs.ai_skill_use_func["#yisiguCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if self:damageIsEffective(ep,"N",self.player) then
			use.card = card
			use.to:append(ep)
			return
		end
	end
	self:sort(self.friends_noself,nil,true)
	for i,p in sgs.list(self.friends_noself)do
		if i<#self.friends/2 and not self:isWeak(p)
		and self:damageIsEffective(p,"N",self.player) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.yisiguCard = 3.4
sgs.ai_use_priority.yisiguCard = 0.2

sgs.ai_fill_skill.yimiehai = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local dc = dummyCard("yj_stabs_slash","yimiehai")
	for i,c1 in sgs.list(cards)do
		if table.contains(self.toUse,c1)
		or self:getKeepValue(c1)>6 then continue end
		for n,c2 in sgs.list(cards)do
			if table.contains(self.toUse,c1)
			or self:getKeepValue(c1)>6 then continue end
			if i>n then
				dc:addSubcard(c1)
				dc:addSubcard(c2)
				if dc:isAvailable(self.player)
				then return dc end
				dc:clearSubcards()
			end
		end
	end
end

function sgs.ai_cardsview.yimiehai(self,class_name,player)
    local cards = player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local dc = dummyCard("yj_stabs_slash","yimiehai")
	for i,c1 in sgs.list(cards)do
		for n,c2 in sgs.list(cards)do
			if i>n then
				dc:addSubcard(c1)
				dc:addSubcard(c2)
				if dc:isAvailable(player)
				then return dc:toString() end
				dc:clearSubcards()
			end
		end
	end
end

sgs.ai_skill_choice.shefu = function(self,choices)
	local items = choices:split("+")
	return items[1]
end

sgs.ai_skill_playerchosen.yiqingjun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
end

sgs.ai_skill_invoke.yijugu = function(self,data)
	return #self.enemies>0
end

sgs.ai_skill_playerchosen.yijugu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"he",true)
		then return p end
	end
end

sgs.ai_skill_invoke.yichengming = function(self,data)
	return #self.enemies>0
end

sgs.ai_fill_skill.yizhengsi = function(self)
	return sgs.Card_Parse("#yizhengsiCard:.:")
end

sgs.ai_skill_use_func["#yizhengsiCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if ep:getHandcardNum()>0 and use.to:isEmpty()
		then use.to:append(ep) end
	end
	if use.to:length()==1 then
		use.to:append(self.player)
	end
	for i,p in sgs.list(self.room:getAlivePlayers())do
		if not self:isFriend(p) and not use.to:contains(p)
		and use.to:length()==2 and p:getHandcardNum()>0 then
			use.to:append(p)
			use.card = card
		end
	end
end

sgs.ai_use_value.yizhengsiCard = 3.4
sgs.ai_use_priority.yizhengsiCard = 4.2

sgs.ai_fill_skill.yihuice = function(self)
	return sgs.Card_Parse("#yihuiceCard:.:")
end

sgs.ai_skill_use_func["#yihuiceCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p) and use.to:length()<2
		then use.to:append(p) end
	end
	for i,p in sgs.list(self.room:getAlivePlayers())do
		if not self:isFriend(p) and not use.to:contains(p)
		and use.to:length()<2 and self.player:canPindian(p) then
			use.to:append(p)
		end
	end
	if use.to:length()==2 then
		use.card = card
	end
end

sgs.ai_use_value.yihuiceCard = 3.4
sgs.ai_use_priority.yihuiceCard = 4.2

sgs.ai_skill_invoke.yiqianliu = function(self,data)
	return #self.enemies>0
end

sgs.ai_skill_playerchosen.yimitu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_playerschosen.yimitu = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		and #tps<x and #tps<self.player:getLostHp()
		and #self.enemies>0 then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_invoke.yimitu = function(self,data)
	local ts = data:toString():split(":")
	return self:isEnemy(BeMan(self.room,ts[2]))
end

sgs.ai_skill_playerchosen.yichengbian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local dc = dummyCard("duel","_yichengbian")
	local d = self:aiUseCard(dc)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and d.to:contains(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:hasTrickEffective(dc,p,self.player)
		then return p end
	end
end

sgs.ai_skill_discard.yichengbian = function(self)
	if self:getCardsNum("Slash")>0 then return {} end
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		table.insert(cards,h:getEffectiveId())
		if #cards>=#handcards/2 then break end
	end
	return cards
end

sgs.ai_skill_invoke.yiduibian = function(self,data)
	local damage = data:toDamage()
	return #self.enemies>0 and (self:isWeak() or self:isEnemy(damage.from))
end

sgs.ai_skill_invoke.yiduibian0 = function(self,data)
	local ts = data:toString():split(":")
	return self:isEnemy(BeMan(self.room,ts[2]))
end

sgs.ai_skill_playerschosen.yizongheng = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #tps<x
		then table.insert(tps,p) end
	end
	return #tps>1 and tps
end

sgs.ai_skill_playerchosen.manhanguo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and p:getCardCount()>0
		and self.player:inMyAttackRange(p)
		then return p end
	end
end

sgs.ai_skill_playerschosen.manweiwo = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and #tps<x
		then table.insert(tps,p) end
	end
	if #tps<2 then return {} end
	return tps
end

sgs.ai_skill_use["@@manhaibian"] = function(self,prompt)
    local dc = dummyCard("duel")
	dc:setSkillName("manhaibian")
    local d = self:aiUseCard(dc)
   	if d.card then
      	if dc:canRecast() and d.to:length()<1 then return end
      	local tos = {}
       	for _,p in sgs.qlist(d.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dc:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_fill_skill.manchanyu = function(self)
	return sgs.Card_Parse("#manchanyuCard:.:")
end

sgs.ai_skill_use_func["#manchanyuCard"] = function(card,use,self)
	self:sort(self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		if use.to:length()<1 then
			use.to:append(p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.manchanyuCard = 3.4
sgs.ai_use_priority.manchanyuCard = 5.2

sgs.ai_skill_choice.manchanyu = function(self,choices)
	local items = choices:split("+")
	local s2n = {}
	for _,c in sgs.qlist(self.player:getHandcards())do
		s2n[c:getColorString()] = (s2n[c:getColorString()] or 0)+1
		s2n[c:getType()] = (s2n[c:getType()] or 0)+1
	end
	local x = 999
    for s,n in pairs(s2n)do
		x = math.min(x,n)
	end
    for s,n in pairs(s2n)do
		if x>=n then
			return s
		end
	end
	return items[1]
end

sgs.ai_skill_invoke.mancongfeng = function(self,data)
	local tp = data:toPlayer()
	if self.player:getChangeSkillState("mancongfeng")==1 then
		return self:isFriend(tp) and self:canDraw(tp)
	else
		return self:doDisCard(tp,"he")
	end
end

sgs.ai_target_revises.mankongzhi = function(to,card,self)
    if card:isNDTrick() and to:isWounded() then
		return true
	end
end

sgs.ai_skill_invoke.manbizha = function(self,data)
	return self:canDraw() and self:getOverflow()>=0
end

sgs.ai_skill_playerchosen.manbizha = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		then return p end
	end
end

sgs.ai_skill_use["@@manbizha"] = function(self,prompt)
	local cs = {}
    for _,id in sgs.qlist(self.player:getTag("manbizhaForAI"):toIntList())do
      	local c = sgs.Sanguosha:getCard(id)
		if self.player:getMark("manbizhaNum")>c:getNumber()
		and c:isAvailable(self.player)
		then table.insert(cs,c) end
	end
    self:sortByUsePriority(cs) -- 按保留值排序
	for _,c in sgs.list(cs)do
      	local d = self:aiUseCard(c)
		if d.card then
			if c:canRecast() and d.to:length()<1 then return end
			local tos = {}
			for _,p in sgs.list(d.to)do
				table.insert(tos,p:objectName())
			end
			return c:toString().."->"..table.concat(tos,"+")
		end
	end
end

sgs.ai_skill_playerchosen.mannuozhan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		then return p end
	end
end

sgs.ai_skill_invoke.mannuozhan = function(self,data)
	return not self:isWeak() and self:isEnemy(data:toPlayer())
end

sgs.ai_skill_playerschosen.manhuaibing = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_playerschosen.manhuoe = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x and self:isEnemy(p)
		then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_playerchosen.manhuoe = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
end

sgs.ai_skill_playerschosen.mansuwu = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_fill_skill.manrenwang = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c) or not c:hasFlag("link_card")
		or self:getKeepValue(c)>6 then continue end
		local dc = dummyCard("peach","manrenwang")
		dc:addSubcard(c)
		if dc:isAvailable(self.player)
		then return dc end
	end
end

sgs.ai_guhuo_card.manrenwang = function(self,card_name,class_name)
    if self:getCardsNum(class_name)<1 then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards) -- 将列表转换为表
		self:sortByKeepValue(cards) -- 按保留值排序
		for _,c in sgs.list(cards)do
			if not c:hasFlag("link_card")
			or self:getKeepValue(c)>6 then continue end
			local dc = dummyCard("peach","manrenwang")
			dc:addSubcard(c)
			return dc:toString()
		end
	end
end

sgs.ai_fill_skill.manquchi = function(self)
	return sgs.Card_Parse("#manquchiCard:.:")
end

sgs.ai_skill_use_func["#manquchiCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self:damageIsEffective(p,"F",self.player) then
			for _,c in sgs.list(getKnownCards(p,self.player,"h"))do
				if c:hasFlag("link_card") then
					use.to:append(p)
					use.card = card
					return
				end
			end
		end
	end
	for _,p in sgs.list(self.enemies)do
		if self:damageIsEffective(p,"F",self.player) then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.manquchiCard = 3.4
sgs.ai_use_priority.manquchiCard = 5.2


sgs.ai_skill_invoke.chenjiehuo = function(self,data)
	for _,c in sgs.list(self:getCards("Duel,FireAttack","he"))do
		local d = self:aiUseCard(c)
		if d.card and self:isEnemy(d.to:at(0)) then
			return true
		end
	end
	for _,c in sgs.list(self:getCards("Slash","he"))do
		local d = self:aiUseCard(c)
		if d.card and self:isEnemy(d.to:at(0)) and getCardsNum("Jink",d.to:at(0),self.player)<1 then
			return true
		end
	end
	return self:isWeak() and #self.enemies>0
end

sgs.ai_fill_skill.chenxianger = function(self)
	return sgs.Card_Parse("#chenxiangerCard:.:")
end

sgs.ai_skill_use_func["#chenxiangerCard"] = function(card,use,self)
	local p2n = {}
	for _,c in sgs.list(self:addHandPile())do
		if c:isDamageCard() then
			for _,p in sgs.list(self:aiUseCard(c).to)do
				p2n[p:objectName()] = (p2n[p:objectName()] or 0)+1
			end
		end
	end
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if p2n[p:objectName()] and p2n[p:objectName()]>1 then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.chenxiangerCard = 6.4
sgs.ai_use_priority.chenxiangerCard = 7.2

sgs.ai_skill_playerchosen.chenmieguo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"he")
		then return p end
	end
end

sgs.ai_skill_playerschosen.chenmieguo = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x and self:isFriend(p) then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_playerchosen.chenbingqu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for i,p in sgs.list(destlist)do
		if i<#destlist/2 and self:isEnemy(p)
		then return p end
	end
    for i,p in sgs.list(destlist)do
		if i>#destlist/2 and self:isFriend(p)
		then return p end
	end
	return destlist[1]
end

sgs.ai_skill_choice.chenbingqu = function(self,choices,data)
	local items = choices:split("+")
	local cs = {}
	for s,cn in ipairs(items)do
		table.insert(cs,dummyCard(cn))
	end
    self:sortByKeepValue(cs)
	if(self:isFriend(data:toPlayer()))then
		return cs[math.random(#cs/2,#cs)]:objectName()
	end
	return cs[math.random(1,#cs/2)]:objectName()
end

sgs.ai_skill_playerchosen.chenfanxin = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
end


sgs.ai_skill_playerchosen.chenxiezhong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
	return destlist[#destlist]
end

sgs.ai_skill_invoke.chenqishi = function(self,data)
	return data:toIntList():length()>1 and self:canDraw()
end

sgs.ai_skill_use["@@chenwanli"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local cs = {}
    for i,c in sgs.list(cards)do
		if i<#cards/2 then
			table.insert(cs,c:toString())
		end
	end
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		return string.format("#chenwanliCard:%s:->%s",table.concat(cs,"+"),p:objectName())
	end
end

sgs.ai_skill_playerchosen.chenlishuo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for i,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
end

sgs.ai_skill_invoke.chenlishuo = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill.chenfubei = function(self)
	return sgs.Card_Parse("#chenfubeiCard:.:")
end

sgs.ai_skill_use_func["#chenfubeiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.chenfubeiCard = 6.4
sgs.ai_use_priority.chenfubeiCard = 7.2

sgs.ai_skill_invoke.chendancui = function(self,data)
	local damage = self.player:getTag("chendancuiData"):toDamage()
	return self:isEnemy(damage.to)
end

sgs.ai_skill_discard.chendancui = function(self)
	local damage = self.player:getTag("chendancuiData"):toDamage()
	if not self:isEnemy(damage.to) then return {} end
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		table.insert(cards,h:getEffectiveId())
		if #cards>1 then return cards end
	end
	return {}
end

sgs.ai_fill_skill.chenlanjiao = function(self)
	return sgs.Card_Parse("#chenlanjiaoCard:.:")
end

sgs.ai_skill_use_func["#chenlanjiaoCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self.player:getMark(p:objectName().."chenlanjiaoBan-Clear")<1 then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.chenlanjiaoCard = 3.4
sgs.ai_use_priority.chenlanjiaoCard = 5.2

sgs.ai_skill_invoke.chenlanjiao = function(self,data)
	local ids = self.player:getTag("chenlanjiaoIds"):toIntList()
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
	for i,c in sgs.list(handcards)do
		if i>#handcards/2 and ids:contains(c:getId()) and not self:isWeak() then
			return true
		end
	end
	return self.player:hasSkill("kurou")
end

sgs.ai_skill_invoke.chenyangbei = function(self,data)
	local srt = data:toString()
	if srt~="" then
		for i,p in sgs.list(self.enemies)do
			if srt:endsWith(p:objectName()) and not self:isWeak() then
				return true
			end
		end
	else
		return self:canDraw()
	end
end

sgs.ai_skill_playerchosen.chenjiaozong = function(self,players)
	if sgs.ai_skill_invoke.peiqi(self) then
		for i,p in sgs.list(players)do
			if self.peiqiData.from==p
			then return p end
		end
	end
end

sgs.ai_skill_playerchosen.chenjiaozong1 = function(self,players)
	if sgs.ai_skill_invoke.peiqi(self) then
		for i,p in sgs.list(players)do
			if self.peiqiData.to==p
			then return p end
		end
	end
end

sgs.ai_skill_cardchosen.chenjiaozong = function(self,who,flags,method)
   	for _,c in sgs.list(who:getCards(flags))do
		if c:getId()==self.peiqiData.cid
		then return c:getId() end
	end
end

sgs.ai_fill_skill.chenfusui = function(self)
	return sgs.Card_Parse("#chenfusuiCard:.:")
end

sgs.ai_skill_use_func["#chenfusuiCard"] = function(card,use,self)
	local aps = self.room:getAlivePlayers()
	aps = self:sort(aps)
	for i,p in sgs.list(aps)do
		if i>#aps/2 and p:isMale() and self:isEnemy(p) then
			for _,s in sgs.qlist(p:getVisibleSkillList())do
				if s:isAttachedLordSkill() then continue end
				local pt = s:getDescription(p)
				if pt:contains("技，") then continue end
				use.to:append(p)
				use.card = card
				return
			end
		end
	end
	for i,p in sgs.list(aps)do
		if i<#aps/2 and p:isMale() and self:isFriend(p) then
			for _,s in sgs.qlist(p:getVisibleSkillList())do
				if s:isAttachedLordSkill() then continue end
				local pt = s:getDescription(p)
				if pt:contains("技，") then continue end
				use.to:append(p)
				use.card = card
				return
			end
		end
	end
end

sgs.ai_use_value.chenfusuiCard = 3.4
sgs.ai_use_priority.chenfusuiCard = 5.2

sgs.ai_fill_skill.chenbiyi = function(self)
	local f = sgs.ai_fill_skill[self.player:property("chenbiyi_skill"):toString()]
	return f and f(self)
end

sgs.ai_guhuo_card.chenbiyi = function(self,card_name,class_name)
	local f = sgs.ai_guhuo_card[self.player:property("chenbiyi_skill"):toString()]
	return f and f(self,card_name,class_name)
end

function sgs.ai_cardsview.chenbiyi(self,class_name,player)
	local f = sgs.ai_cardsview[self.player:property("chenbiyi_skill"):toString()]
	return f and f(self,class_name,player)
end
