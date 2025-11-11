
sgs.ai_skill_discard.zuyuzhi = function(self)
	local to_cards = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local n = 0
   	for _,c in sgs.list(cards)do
		local x = c:nameLength()
		if x>n then n = x end
	end
   	for _,c in sgs.list(cards)do
		local x = c:nameLength()
		if x>=n then table.insert(to_cards,c:getEffectiveId()) break end
	end
	return to_cards
end

sgs.ai_skill_choice.losehoorremoveskill = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"removes_zu_zhong_baozu")
	and self:isWeak() and self.player:getMark("@zu_zhong_baozu")<1
	then return "removes_zu_zhong_baozu" end
	return items[1]
end

sgs.ai_skill_discard.zuxieshu = function(self,max,min)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if self.player:getLostHp()>max/2 then
		self:sortByKeepValue(cards)
		for _,h in sgs.list(cards)do
			if #to_cards>min then break end
			table.insert(to_cards,h:getEffectiveId())
		end
	end
	if #to_cards<min then to_cards = {} end
	return to_cards
end

sgs.ai_skill_invoke.zu_zhong_baozu = function(self,data)
	local dying = data:toDying()
	return self:isFriend(dying.who)
	and self:getAllPeachNum()+dying.who:getHp()<1
end

sgs.ai_skill_playerchosen.zujiejian = function(self,players)
    for _,target in sgs.list(players)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(players)do
		if not self:isEnemy(target)
		and #self.enemies>0
		then return target end
	end
end

sgs.ai_use_revises.zujiejian = function(self,card,use)
	if #self.toUse>1 then
		local has = ""
		for i,c in sgs.list(self.toUse)do
			if i>1 and c:nameLength()==self.player:getMark("&zujiejian-Clear")+1 then
				has = c:toString()
				break
			end
		end
		if has~="" and has~=card:toString() then
			return false
		end
	end
end

sgs.ai_skill_invoke.zuhuanghan = function(self,data)
	local damage = data:toDamage()
	local n = damage.card:nameLength()
	return n>=self.player:getLostHp() or self.player:getMark("@zu_zhong_baozu")<1
	and self.player:hasSkill("zu_zhong_baozu",true)
end

sgs.ai_fill_skill.zuguangu = function(self)
    return sgs.Card_Parse("#zuguanguCard::")
end

sgs.ai_skill_use_func["#zuguanguCard"] = function(card,use,self)
	local n = self.player:getChangeSkillState("zuguangu")
	if n==1 then
		use.card = card
	else
		self:sort(self.enemies,"handcard",true)
		for _,p in sgs.list(self.enemies)do
			if p:getHandcardNum()>0 then
				use.card = card
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.list(self:sort(self.room:getOtherPlayers(self.player),"handcard",true))do
			if p:getHandcardNum()>0 and not self:isFriend(p) then
				use.card = card
				use.to:append(p)
				return
			end
		end
		self:sort(self.friends_noself,"handcard",true)
		for _,p in sgs.list(self.friends_noself)do
			if p:getHandcardNum()>0 then
				use.card = card
				use.to:append(p)
				return
			end
		end
	end
end

sgs.ai_use_value.zuguanguCard = 3.4
sgs.ai_use_priority.zuguanguCard = 6.2

sgs.ai_skill_askforag.zuguangu = function(self,card_ids)
	local to_cards = {}
	for _,id in sgs.list(card_ids)do
		table.insert(to_cards,sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(to_cards)
	for _,c in sgs.list(to_cards)do
		local dummy = self:aiUseCard(c)
		if dummy.card then
			if c:canRecast() and dummy.to:isEmpty() then continue end
			self.zuguanguUse = dummy
			return c:getEffectiveId()
		end
	end
	return -1
end

sgs.ai_skill_use["@@zuguangu"] = function(self,prompt)
	local to_cards = {}
	for _,id in sgs.list(self.player:getTag("zuguanguForAI"):toIntList())do
		table.insert(to_cards,sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(to_cards)
	for _,c in sgs.list(to_cards)do
		if c:isAvailable(self.player) then
			local dummy = self:aiUseCard(c)
			if dummy.card then
				if c:canRecast() and dummy.to:isEmpty() then continue end
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
				return c:toString().."->"..table.concat(tos,"+")
    end
end
	end
end

sgs.ai_skill_choice.zuguangunum = function(self,choices)
	local items = choices:split("+")
	return items[#items]
end



--穆荫

sgs.ai_skill_playerchosen.zu_wu_muyin = function(self, targets)
    local min = -1
    local selected = nil
    for _,target in sgs.qlist(targets) do
        if self:isFriend(target) then
            if target:hasSkill("zuguixiang",true) and target:getMaxCards() == 2 then continue end--防止穆荫导致贵相跳了摸牌阶段
            if min < 0 or min > target:getMaxCards() then 
                min = target:getMaxCards() 
                selected = target
            end
        end
    end
    return selected
end

--斩钉

local zuzhanding = {}
zuzhanding.name = "zuzhanding"
table.insert(sgs.ai_skills, zuzhanding)
zuzhanding.getTurnUseCard = function(self, inclusive)
    if self:getCardsNum("Slash") > 0 and self.player:getHandcardNum() > self.player:getMaxCards() then return end
    local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
        local slash = sgs.Sanguosha:cloneCard("slash")
        slash:addSubcard(card)
        slash:setSkillName("zuzhanding")
        slash:deleteLater()
        if slash:isAvailable(self.player) then return slash end
    end
end

--移荣

local zuyirong = {}
zuyirong.name = "zuyirong"
table.insert(sgs.ai_skills, zuyirong)
zuyirong.getTurnUseCard = function(self, inclusive)
	return sgs.Card_Parse("#zuyirongCard:.:")
end

sgs.ai_skill_use_func["#zuyirongCard"] = function(card, use, self)
	local n = self.player:getHandcardNum()-self.player:getMaxCards()
	if n>0 then
		sgs.ai_use_priority.zuyirongCard = 0.2
		if self.player:getHandcardNum()>3
		then use.card = card end
	else
		sgs.ai_use_priority.zuyirongCard = 7.2
		use.card = card
	end
end



sgs.ai_fill_skill.zulianzhuvs = function(self)
    return sgs.Card_Parse("#zulianzhuCard:.:")
end

sgs.ai_skill_use_func["#zulianzhuCard"] = function(card,use,self)
	self:sort(self.enemies,"handcard")
	for _,p in sgs.list(self:sort(self.room:getAlivePlayers(),"handcard",true))do
		if p:hasSkill("zulianzhu") and self:isFriend(p) then
			local n = p:getChangeSkillState("zulianzhu")
			if n==1 then
				local cards = sgs.QList2Table(self.player:getCards("he"))
				if #cards>2 and p:getCardCount()>2 then
					self:sortByKeepValue(cards)
					for _,c in sgs.list(cards)do
						if self.player:isCardLimited(c,sgs.Card_MethodRecast)
						then continue end
						card:addSubcard(c)
						use.card = card
						use.to:append(p)
						return
					end
				end
			else
				self.zulianzhuFrom = p
				for _,ep in sgs.list(self.enemies)do
					if self.player:canSlash(ep,nil,false)
					and p:canSlash(ep,nil,false) then
						use.card = card
						use.to:append(p)
						return
					end
				end
			end
		end
	end
	for _,p in sgs.list(self:sort(self.room:getAlivePlayers(),"handcard"))do
		if p:hasSkill("zulianzhu") and not self:isFriend(p) then
			local n = p:getChangeSkillState("zulianzhu")
			if n==1 then
				local cards = sgs.QList2Table(self.player:getCards("he"))
				if #cards>2 and p:getCardCount()>0 then
					self:sortByKeepValue(cards)
					for _,c in sgs.list(cards)do
						if self.player:isCardLimited(c,sgs.Card_MethodRecast)
						then continue end
						card:addSubcard(c)
						use.card = card
						use.to:append(p)
						return
					end
				end
			else
				self.zulianzhuFrom = p
				for _,ep in sgs.list(self.enemies)do
					if self.player:canSlash(ep,nil,false)
					and p~=ep then
						use.card = card
						use.to:append(p)
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_value.zulianzhuCard = 3.4
sgs.ai_use_priority.zulianzhuCard = 5.2

sgs.ai_skill_playerchosen.zulianzhu = function(self,players)
    local from = self.zulianzhuFrom
	if self:isFriend(from) then
		for _,target in sgs.qlist(players) do
			if self:isEnemy(target)
			and self.player:canSlash(target,nil,false)
			and from:canSlash(target,nil,false)
			then return target end
		end
	end
    for _,target in sgs.qlist(players) do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_cardask["@zuqiajue-invoke"] = function(self,data,pattern)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
	local n = 0
   	for _,c in sgs.list(cards)do
		n = n+c:getNumber()
	end
   	for _,c in sgs.list(cards)do
    	if n>30 or self.player:isJilei(c) or not c:isBlack() then continue end
		return c:getEffectiveId()
	end
    return "."
end


--蹈节

sgs.ai_skill_choice["kezudaojie"] = function(self, choices, data)
	local items = choices:split("+")
    if table.contains(items,"hp")
	and self.player:getHp()+self:getCardsNum("Peach,Analeptic")>1 then return "hp" end
	if table.contains(items,"kezudaojie") then return "kezudaojie" end
	if table.contains(items,"skill") then return "skill" end
end

sgs.ai_skill_playerchosen.kezudaojie = function(self, targets)
    local fri = {}
    for _,target in sgs.qlist(targets) do
        if self:isFriend(target) then
            table.insert(fri, target)
        end
    end
    if #fri > 0 then
        self:sort(fri, "handcard")
        return fri[1]
    end
    for _,target in sgs.qlist(targets) do
        return target
    end
end

--神君

sgs.ai_skill_choice["ny_shenjun"] = function(self, choices, data)
	local items = choices:split("+")
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByUseValue(cards)
	for _,ch in sgs.list(items) do
        local dc = dummyCard(ch)
		if not dc then continue end
		dc:setSkillName("ny_shenjun")
		local n = self.player:getMark("ny_shenjun")
		for _,h in sgs.list(cards) do
			dc:addSubcard(h)
			if dc:subcardsLength()>=n then break end
		end
		local d = self:aiUseCard(dc)
		if d.card then return ch end
    end
    return "cancel"
end

sgs.ai_skill_use["@@ny_shenjun"] = function(self,prompt)
	local n = self.player:getMark("ny_shenjun")
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
	if n>#cards/2 then return end
    local dc = self.player:property("ny_shenjun"):toString()
	dc = dummyCard(dc)
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
    	dc:addSubcard(h)
		if dc:subcardsLength()>=n then break end
	end
	dc:setSkillName("ny_shenjun")
    local dummy = self:aiUseCard(dc)
   	if dummy.card then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
		if dc:canRecast() and #tos<1 then return end
       	return dc:toString().."->"..table.concat(tos,"+")
    end
end

--八龙

--[[local ny_balong_skill = {}
ny_balong_skill.name = "ny_balong"
table.insert(sgs.ai_skills, ny_balong_skill)
ny_balong_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("ny_balong_old") > 0 then return end
    return sgs.Card_Parse("#ny_balong:.:")
end

sgs.ai_skill_use_func["#ny_balong"] = function(card,use,self)
    use.card = card
end

sgs.ai_use_priority.ny_balong = 10]]

--三恇

sgs.ai_skill_playerchosen.ny_sankuang = function(self, targets)
    local use = self.player:getTag("ny_sankuang_use"):toCardUse()
    local give = use.card:subcardsLength()
    if self.player:hasSkill("kezudaojie")and not use.card:isDamageCard()
    and use.card:isKindOf("TrickCard") and self.player:getMark("kezudaojie-Clear") == 0 then
        give = 0
    end
    local max = -99
    local rtarget
    for _,target in sgs.qlist(targets) do
        local min = 0
        if (not target:getCards("ej"):isEmpty()) then min = min + 1 end
        if target:isWounded() then min = min + 1 end
        if target:getHandcardNum() > target:getHp() then min = min + 1 end
        min = math.min(min, target:getCards("he"):length())
        local value = min*1.2 - give
        if self:isFriend(target) then value = (-1)*value end
        if value > max then
            max = value
            rtarget = target
        end
    end
    return rtarget
end

--百出

sgs.ai_skill_choice["ny_baichu"] = function(self, choices, data)
	if string.find(choices, "recover") then return "recover" end
    local items = choices:split("+")
    return items[math.random(1,#items)]
end



sgs.ai_fill_skill.kezuyunshen = function(self)
	return sgs.Card_Parse("#kezuyunshenCard:.:")
end

sgs.ai_skill_use_func["#kezuyunshenCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if not ep:isWounded() then
			use.card = card
			use.to:append(ep)
			sgs.ai_skill_choice.kezuyunshen = "he"
			return
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if self:isWeak(p) and not self:isWeak() then
			use.card = card
			use.to:append(p)
			sgs.ai_skill_choice.kezuyunshen = "self"
			return
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if p:isWounded() and self:getCardsNum("Jink")>0 then
			use.card = card
			use.to:append(p)
			sgs.ai_skill_choice.kezuyunshen = "self"
			return
		end
	end
end

sgs.ai_use_value.kezuyunshenCard = 3.4
sgs.ai_use_priority.kezuyunshenCard = 6.2

sgs.ai_skill_invoke.kezushangshen = function(self,data)
	local damage = data:toDamage()
	if self:isFriend(damage.to)
	and damage.to:getHandcardNum()<4 then
		local to = self.player:getTag("fenchaiPlayer"):toPlayer()
		if to and to:isAlive() and self.player:hasSkill("kezufenchai") then return true end
		local finalRetrial,wizard = self:getFinalRetrial(nil,"lightning")
		if finalRetrial<2 then
			return not to or to:isAlive()
			or not self.player:hasSkill("kezufenchai")
		end
	end
end

sgs.ai_fill_skill.kezulieshi = function(self)
	return #self.enemies>0
	and sgs.Card_Parse("#kezulieshiCard:.:")
end

sgs.ai_skill_use_func["#kezulieshiCard"] = function(card,use,self)
	if self.player:hasJudgeArea() and not self:isWeak() and self.player:isChained() then
		use.card = card
	else
		local n = 0
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if c:isKindOf("Slash") then n = n+1 end
		end
		if n<self:getCardsNum("Slash") then
			use.card = card
		end
	end
end

sgs.ai_use_value.kezulieshiCard = 3.4
sgs.ai_use_priority.kezulieshiCard = 3.2

sgs.ai_skill_choice["kezulieshi"] = function(self, choices, data)
	local items = choices:split("+")
    --if table.contains(items,"slash") then return "slash" end
	--if table.contains(items,"jink") then return "jink" end
    for _,tr in sgs.list(items) do
		if tr:startsWith("lieshidamage") and not self:isWeak()
		then return tr end
	end
end

sgs.ai_skill_playerchosen.kezulieshi = function(self, players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_playerchosen.kezufangzhen = function(self, players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:getSeat()<=self.room:getTag("TurnLengthCount"):toInt()
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and self:isWeak(target)
		then return target end
	end
end

sgs.ai_skill_choice["kezufangzhen"] = function(self, choices, data)
	local items = choices:split("+")
	local to = data:toPlayer()
    if self:isWeak(to) and to:isWounded()
	then return items[2] end
    return items[1]
end

sgs.ai_skill_playerchosen.kezuliuju = function(self, players)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
	if #cards<2 then return end
    self:sortByKeepValue(cards) -- 按保留值排序
	self.kezuliuju_card = cards[1]
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_use["@@kezuliuju"] = function(self,prompt)
    local dcs = {}
	for _,id in sgs.list(self.player:getTag("kezuliujuIds"):toIntList())do
    	table.insert(dcs,sgs.Sanguosha:getCard(id))
	end
    self:sortByKeepValue(dcs,true) -- 按保留值排序
	for _,c in sgs.list(dcs)do
		if c:isAvailable(self.player) then
			local dummy = self:aiUseCard(c)
			if dummy.card then
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,p:objectName())
				end
				if c:canRecast() and #tos<1 then continue end
				return c:toString().."->"..table.concat(tos,"+")
			end
		end
	end
end

sgs.ai_fill_skill.kezuxumin = function(self)
	return sgs.Card_Parse("#kezuxuminCard:.:")
end

sgs.ai_skill_use_func["#kezuxuminCard"] = function(card,use,self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		local wgfd = sgs.Sanguosha:cloneCard("amazing_grace")
		wgfd:setSkillName("kezuxumin")
		wgfd:addSubcard(h)
		wgfd:deleteLater()
		if wgfd:isAvailable(self.player) then
			local can = false
			for _, p in sgs.list(self.friends_noself) do
				if self.player:isProhibited(p,wgfd)
				or use.to:contains(p) then continue end
				use.to:append(p)
				if self:isWeak(p) then
					can = true
				end
			end
			if can then use.card = card
			else break end
		end
	end
end

sgs.ai_use_value.kezuxuminCard = 3.4
sgs.ai_use_priority.kezuxuminCard = 4.2

sgs.ai_skill_playerschosen.kezulianhe = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
	local tos = {}
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and #tos<x
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #tos<x
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_invoke.kezulianhe = function(self,data)
	return #self.friends+#self.enemies>1
end

sgs.ai_skill_discard.kezulianhe = function(self,n,x)
	local from = self.player:getTag("kezulianheFrom"):toPlayer()
	local cards = {}
   	for _,h in sgs.list(self:poisonCards("he"))do
		table.insert(cards,h:getEffectiveId())
		if #cards>=n then break end
	end
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if self:isFriend(from) and #cards<1 or #cards>=n
		or table.contains(cards,h:getEffectiveId()) then continue end
		table.insert(cards,h:getEffectiveId())
	end
	return cards
end

sgs.ai_skill_choice["kezuhuanjia"] = function(self, choices, data)
	local items = choices:split("+")
    if table.contains(items,"kezuxumin")
	and self.player:getMark("@kezuxumin")<1
	then return "kezuxumin" end
end

sgs.ai_skill_playerchosen.kezuhuanjia = function(self, players)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
	if #cards<2 then return end
    self:sortByKeepValue(cards) -- 按保留值排序
	self.kezuliuju_card = cards[1]
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_use["@@kezuhuanjia"] = function(self,prompt)
    local dcs = {}
	for _,id in sgs.list(self.player:getTag("kezuhuanjiaIds"):toIntList())do
    	table.insert(dcs,sgs.Sanguosha:getCard(id))
	end
    self:sortByKeepValue(dcs,true) -- 按保留值排序
	for _,c in sgs.list(dcs)do
		if c:isAvailable(self.player) then
			local dummy = self:aiUseCard(c)
			if dummy.card then
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,p:objectName())
				end
				if c:canRecast() and #tos<1 then continue end
				return c:toString().."->"..table.concat(tos,"+")
			end
		end
	end
end

sgs.ai_fill_skill.kezujiexuan = function(self)
	local n = self.player:getChangeSkillState("kezujiexuan")
	if n==1 then
		local can
		for i,c in sgs.list(self.toUse)do
			if i>1 and self.room:getCardPlace(c:getEffectiveId())~=sgs.Player_PlaceHand then
				can = c
				break
			end
		end
		if can then
			local cards = sgs.QList2Table(self.player:getCards("he"))
			self:sortByKeepValue(cards) -- 按保留值排序
			for _,c in sgs.list(cards)do
				if c:getEffectiveId()==can:getEffectiveId() then continue end
				local dc = dummyCard("snatch")
				dc:addSubcard(c)
				dc:setSkillName("kezujiexuan")
				if dc:isRed() and dc:isAvailable(self.player)
				then return dc end
			end
		end
		local ids = self.player:getHandPile()
		for _,id in sgs.list(ids)do
			if self.player:handCards():contains(id)
			then continue end
			local dc = dummyCard("snatch")
			dc:addSubcard(id)
			dc:setSkillName("kezujiexuan")
			if dc:isRed() and dc:isAvailable(self.player)
			then return dc end
		end
		local cards = sgs.QList2Table(self.player:getCards("e"))
		self:sortByKeepValue(cards) -- 按保留值排序
		for _,e in sgs.list(cards)do
			local dc = dummyCard("snatch")
			dc:addSubcard(e)
			dc:setSkillName("kezujiexuan")
			if dc:isRed() and dc:isAvailable(self.player)
			then return dc end
		end
	else
		local can
		for i,c in sgs.list(self.toUse)do
			if i>1 and self.room:getCardPlace(c:getEffectiveId())~=sgs.Player_PlaceHand then
				can = c
				break
			end
		end
		if can then
			local cards = sgs.QList2Table(self.player:getCards("he"))
			self:sortByKeepValue(cards) -- 按保留值排序
			for _,c in sgs.list(cards)do
				if c:getEffectiveId()==can:getEffectiveId() then continue end
				local dc = dummyCard("dismantlement")
				dc:addSubcard(c)
				dc:setSkillName("kezujiexuan")
				if dc:isRed() and dc:isAvailable(self.player)
				then return dc end
			end
		end
		local ids = self.player:getHandPile()
		for _,id in sgs.list(ids)do
			if self.player:handCards():contains(id)
			then continue end
			local dc = dummyCard("dismantlement")
			dc:addSubcard(id)
			dc:setSkillName("kezujiexuan")
			if dc:isBlack() and dc:isAvailable(self.player)
			then return dc end
		end
		local cards = sgs.QList2Table(self.player:getCards("e"))
		self:sortByKeepValue(cards) -- 按保留值排序
		for _,e in sgs.list(cards)do
			local dc = dummyCard("dismantlement")
			dc:addSubcard(e)
			dc:setSkillName("kezujiexuan")
			if dc:isBlack() and dc:isAvailable(self.player)
			then return dc end
		end
	end
end

sgs.ai_fill_skill.kezumingjie = function(self)
	return sgs.Card_Parse("#kezumingjieCard:.:")
end

sgs.ai_skill_use_func["#kezumingjieCard"] = function(card,use,self)
	local dc,fc = 0,0
	for _,c in sgs.list(self.toUse)do
		if c:isKindOf("BasicCard") or c:isNDTrick() then
			if c:isDamageCard() then dc = dc+1
			elseif c:targetFixed() then fc = fc+1 end
		end
	end
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if p:getMark("&kezumingjie+#"..self.player:objectName())>0 then continue end
		if dc>0 and self:isEnemy(p) and not self.player:inMyAttackRange(p) then
			use.card = card
			use.to:append(p)
			return
		end
		if fc>1 and p~=self.player and self:isFriend(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.kezumingjieCard = 3.4
sgs.ai_use_priority.kezumingjieCard = 11.2

sgs.ai_skill_askforag.kezumingjie = function(self,card_ids)
	local to_cards = {}
	for _,id in sgs.list(card_ids)do
		table.insert(to_cards,sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(to_cards)
	for _,c in sgs.list(to_cards)do
		local dummy = self:aiUseCard(c)
		if dummy.card then
			if c:canRecast() and dummy.to:isEmpty() then continue end
			self.kezumingjieUse = dummy
			return c:getEffectiveId()
		end
	end
	return -1
end

sgs.ai_skill_use["@@kezumingjiemark"] = function(self,prompt)
    local dummy = self.kezumingjieUse
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_invoke.kezumingjie = function(self,data)
	local st = data:toString()
	local sts = st:split(":")
	local to = BeMan(self.room,sts[2])
	local use = self.room:getTag("kezumingjieData"):toCardUse()
	if self:isFriend(to) and use.card:targetFixed() then
		return true
	elseif self:isEnemy(to) and use.card:isDamageCard() then
		return true
	end
end

sgs.ai_fill_skill.kezubolong = function(self)
	return sgs.Card_Parse("#kezubolongCard:.:")
end

sgs.ai_skill_use_func["#kezubolongCard"] = function(card,use,self)
	for _,p in sgs.list(self.enemies)do
		if self:isWeak(p) then
			use.to:append(p)
			use.card = card
			return
		end
	end
	local dc = dummyCard("thunder_slash")
	dc:setSkillName("kezubolong")
	local d = self:aiUseCard(dc)
	if d.card then
		for _,p in sgs.list(d.to)do
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.kezubolongCard = 3.4
sgs.ai_use_priority.kezubolongCard = 3.2

sgs.ai_skill_choice["kezubolong"] = function(self, choices, data)
	local items = choices:split("+")
	if self:isWeak() then return items[2] end
    return items[1]
end

sgs.ai_fill_skill.kezufuxun = function(self)
	return sgs.Card_Parse("#kezufuxunCard:.:")
end

sgs.ai_skill_use_func["#kezufuxunCard"] = function(card,use,self)
	for _,p in sgs.list(self.enemies)do
		if p:getMark("&kezufuxunmove-PlayClear")<1
		and p:getHandcardNum()-self.player:getHandcardNum()==2 then
			use.to:append(p)
			use.card = card
			return
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if p:getMark("&kezufuxunmove-PlayClear")<1
		and p:getHandcardNum()-self.player:getHandcardNum()==-2 then
			local cards = self.player:getCards("h")
			cards = sgs.QList2Table(cards) -- 将列表转换为表
			if #cards<2 then continue end
			self:sortByKeepValue(cards) -- 按保留值排序
			card:addSubcard(cards[1])
			use.to:append(p)
			use.card = card
			return
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if p:getMark("&kezufuxunmove-PlayClear")<1
		and p:getHandcardNum()-self.player:getHandcardNum()==-2 then
			local cards = self.player:getCards("h")
			cards = sgs.QList2Table(cards) -- 将列表转换为表
			if #cards<3 then continue end
			self:sortByKeepValue(cards) -- 按保留值排序
			card:addSubcard(cards[1])
			use.to:append(p)
			use.card = card
			return
		end
	end
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>0 then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.kezufuxunCard = 3.4
sgs.ai_use_priority.kezufuxunCard = 6.2

sgs.ai_skill_askforag.kezufuxun = function(self,card_ids)
	local to_cards = {}
	for _,id in sgs.list(card_ids)do
		table.insert(to_cards,sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(to_cards)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards) -- 将列表转换为表
	self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(to_cards)do
		for i,h in sgs.list(cards)do
			local dc = dummyCard(c:objectName())
			dc:setSkillName("_kezufuxun")
			dc:addSubcard(h)
			if self.player:isLocked(dc) or i>#cards/2 then continue end
			local dummy = self:aiUseCard(dc)
			if dummy.card then
				if c:canRecast() and dummy.to:isEmpty() then continue end
				self.kezufuxunUse = dummy
				return c:getEffectiveId()
			end
		end
	end
	return -1
end

sgs.ai_skill_use["@@kezufuxunbasic"] = function(self,prompt)
    local dummy = self.kezufuxunUse
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_invoke.kezuchenya = function(self,data)
	local to = data:toPlayer()
	return self:isFriend(to)
	or not self:isEnemy(to) and #self.enemies>0
end

sgs.ai_skill_use["@@kezuchenyacz"] = function(self,prompt)
	local valid = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for i,h in sgs.list(cards)do
		if i>#cards/2 or self.player:isCardLimited(h,sgs.Card_MethodRecast)
		or h:nameLength()~=self.player:getHandcardNum() then continue end
    	table.insert(valid,h:getEffectiveId())
	end
	if #valid<1 then return end
	return string.format("#kezuchenyaCard:%s:",table.concat(valid,"+"))
end


sgs.ai_fill_skill.kezulilun = function(self)
	local dc = sgs.Card_Parse("#kezulilunCard:.:")
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByDynamicUsePriority(cards)
	local cs = {}
	for _,h in sgs.list(cards)do
		if self.player:isCardLimited(h,sgs.Card_MethodRecast) then continue end
		if h:isAvailable(self.player) then
			local d = self:aiUseCard(h)
			if d.card then
				for _,r in sgs.list(cards)do
					if self.player:isCardLimited(r,sgs.Card_MethodRecast) then continue end
					if h~=r and h:sameNameWith(r) then
						dc:addSubcard(h)
						dc:addSubcard(r)
						return dc
					end
				end
			end
		end
	end
    self:sortByKeepValue(cards) -- 按保留值排序
	for i,h in sgs.list(cards)do
		if i>#cards/2 or table.contains(self.toUse,h)
		or self.player:isCardLimited(h,sgs.Card_MethodRecast) then continue end
		for _,r in sgs.list(cards)do
			if self.player:isCardLimited(r,sgs.Card_MethodRecast) then continue end
			if h~=r and h:sameNameWith(r) then
				dc:addSubcard(h)
				dc:addSubcard(r)
				return dc
			end
		end
	end
end

sgs.ai_skill_use_func["#kezulilunCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.kezulilunCard = 3.4
sgs.ai_use_priority.kezulilunCard = 11.2

sgs.ai_skill_askforag.kezulilun = function(self,card_ids)
	local to_cards = {}
	for _,id in sgs.list(card_ids)do
		table.insert(to_cards,sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(to_cards)
	for _,c in sgs.list(to_cards)do
		local dummy = self:aiUseCard(c)
		if dummy.card then
			if c:canRecast() and dummy.to:isEmpty() then continue end
			self.kezulilunUse = dummy
			return c:getEffectiveId()
		end
	end
	return -1
end

sgs.ai_skill_use["@@kezulilunuse"] = function(self,prompt)
    local dummy = self.kezulilunUse
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_use["@@kezujianji"] = function(self,prompt)
    local dc = dummyCard()
	dc:setSkillName("kezujianji")
	local dummy = self:aiUseCard(dc)
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_invoke.kezujianji = function(self,data)
	local cur = self.room:getCurrent()
	return self:isFriend(cur)
	or not self:isEnemy(cur) and #self.enemies>0
end


sgs.ai_fill_skill.kezuqiuxin = function(self)
	return sgs.Card_Parse("#kezuqiuxinCard:.:")
end

sgs.ai_skill_use_func["#kezuqiuxinCard"] = function(card,use,self)
	for i,c in sgs.list(self.toUse)do
		if i>1 and c:isKindOf("Slash") or c:isNDTrick() then
			local d = self:aiUseCard(c)
			if d.card then
				for _,p in sgs.list(d.to)do
					if p:getMark("&kezuqiuxinsha+#"..self.player:objectName())>0
					or p:getMark("&kezuqiuxinjinnang+#"..self.player:objectName())>0
					or p==self.player then continue end
					use.card = card
					use.to:append(p)
					return
				end
			end
		end
	end
	for _,p in sgs.list(self.enemies)do
		if p:getMark("&kezuqiuxinsha+#"..self.player:objectName())>0
		or p:getMark("&kezuqiuxinjinnang+#"..self.player:objectName())>0
		then continue end
		use.card = card
		use.to:append(p)
		return
	end
	for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
		if self:isFriend(p) or p:getMark("&kezuqiuxinsha+#"..self.player:objectName())>0
		or p:getMark("&kezuqiuxinjinnang+#"..self.player:objectName())>0
		then continue end
		use.card = card
		use.to:append(p)
		return
	end
end

sgs.ai_use_value.kezuqiuxinCard = 3.4
sgs.ai_use_priority.kezuqiuxinCard = 9.2

sgs.ai_skill_askforag.kezuqiuxin = function(self,card_ids)
	local to_cards = {}
	for _,id in sgs.list(card_ids)do
		table.insert(to_cards,sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(to_cards)
	local to = self.player:getTag("kezuqiuxinTo"):toPlayer()
	for _,c in sgs.list(to_cards)do
		local dc = dummyCard(c:objectName())
		dc:setSkillName("_kezuqiuxin")
		if dc:targetFixed() or self:isEnemy(to) then
			local dummy = self:aiUseCard(dc,dummy(true,99))
			if dummy.card and dummy.to:contains(to) then
				return c:getEffectiveId()
			end
		end
	end
	return -1
end

sgs.ai_skill_use["@@kezujianyuancz"] = function(self,prompt)
	local valid = {}
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for i,h in sgs.list(cards)do
		if i>#cards/2 or self.player:isCardLimited(h,sgs.Card_MethodRecast)
		or h:nameLength()~=self.player:getMark("sgsjianyuantimes-PlayClear") then continue end
    	table.insert(valid,h:getEffectiveId())
	end
	if #valid<1 then return end
	return string.format("#kezujianyuanCard:%s:",table.concat(valid,"+"))
end

sgs.ai_skill_invoke.kezujianyuan = function(self,data)
	local cur = data:toPlayer()
	return self:isFriend(cur)
	or not self:isEnemy(cur) and #self.enemies>0
end

sgs.ai_fill_skill.zuchengqi = function(self)
	for _,pn in sgs.list(patterns())do
		if self.player:getMark(pn.."zuchengqiUse-Clear")<1 then
			local dc = dummyCard(pn)
			if dc and (dc:isNDTrick() or dc:getTypeId()==1)
			and dc:isDamageCard() and self:getCardsNum(dc:getClassName())<1 then
				local m = dc:nameLength()
				dc:setSkillName("zuchengqi")
				local cards = self.player:getCards("h")
				cards = sgs.QList2Table(cards) -- 将列表转换为表
				self:sortByKeepValue(cards) -- 按保留值排序
				for _,h in sgs.list(cards)do
					local x = h:nameLength()
					for _,c in sgs.list(cards)do
						if h==c then continue end
						if x+c:nameLength()>=m then
							dc:addSubcard(h)
							dc:addSubcard(c)
							if dc:isAvailable(self.player) then
								local d = self:aiUseCard(dc)
								if d.card then
									if dc:canRecast() and d.to:isEmpty() then break end
									self.zuchengqiUse = d
									sgs.ai_use_priority.zuchengqiCard = sgs.ai_use_priority[dc:getClassName()]
									return sgs.Card_Parse("#zuchengqiCard:"..h:getId().."+"..c:getId()..":")
								end
							end
							dc:clearSubcards()
						end
					end
				end
			end
		end
	end
	for _,pn in sgs.list(patterns())do
		if self.player:getMark(pn.."zuchengqiUse-Clear")<1 then
			local dc = dummyCard(pn)
			if dc and (dc:isNDTrick() or dc:getTypeId()==1)
			and self:getCardsNum(dc:getClassName())<1 then
				local m = dc:nameLength()
				dc:setSkillName("zuchengqi")
				local cards = self.player:getCards("h")
				cards = sgs.QList2Table(cards) -- 将列表转换为表
				self:sortByKeepValue(cards) -- 按保留值排序
				for _,h in sgs.list(cards)do
					local x = h:nameLength()
					for _,c in sgs.list(cards)do
						if h==c then continue end
						if x+c:nameLength()>=m then
							dc:addSubcard(h)
							dc:addSubcard(c)
							if dc:isAvailable(self.player) then
								local d = self:aiUseCard(dc)
								if d.card then
									if dc:canRecast() and d.to:isEmpty() then break end
									self.zuchengqiUse = d
									sgs.ai_use_priority.zuchengqiCard = sgs.ai_use_priority[dc:getClassName()]
									return sgs.Card_Parse("#zuchengqiCard:"..h:getId().."+"..c:getId()..":")
								end
							end
							dc:clearSubcards()
						end
					end
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#zuchengqiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.zuchengqiCard = 3.4
sgs.ai_use_priority.zuchengqiCard = 9.2

sgs.ai_skill_use["@@zuchengqi"] = function(self,prompt)
    local dummy = self.zuchengqiUse
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_guhuo_card.zuchengqi = function(self,toname,class_name)
    if self.player:getMark(toname.."zuchengqiUse-Clear")>0
	or self:getCardsNum(class_name)>0 then return end
	local dc = dummyCard(toname)
	if dc and (dc:isNDTrick() or dc:getTypeId()==1) then
		local m = dc:nameLength()
		dc:setSkillName("zuchengqi")
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards) -- 将列表转换为表
		self:sortByKeepValue(cards) -- 按保留值排序
		for _,h in sgs.list(cards)do
			local x = h:nameLength()
			for _,c in sgs.list(cards)do
				if h==c then continue end
				if x+c:nameLength()>=m then
					dc:addSubcard(h)
					dc:addSubcard(c)
					if not self.player:isLocked(dc) then
						return dc:toString()
					end
					dc:clearSubcards()
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen.zuchengqi = function(self, players)
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

sgs.ai_skill_playerchosen.zujieli = function(self, players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		self.zujieliTo = target
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(sgs.reverse(destlist))do
		self.zujieliTo = target
		if self:isEnemy(target)
		then return target end
	end
end

sgs.ai_skill_use["@@zujieli"] = function(self,prompt)
	local valid = {}
    local cns = {}
	local cards = {}
	for i,id in sgs.list(self.player:getTag("zujieliForAI"):toIntList())do
		table.insert(cards,sgs.Sanguosha:getCard(id))
	end
	for i,id in sgs.list(self.player:getTag("zujieliNForAI"):toIntList())do
		table.insert(cns,sgs.Sanguosha:getCard(id))
	end
	local to = self.zujieliTo
    self:sortByKeepValue(cards,self:isEnemy(to)) -- 按保留值排序
    self:sortByKeepValue(cns,self:isFriend(to)) -- 按保留值排序
	for _,h in sgs.list(cards)do
		for _,c in sgs.list(cns)do
			if table.contains(valid,c:getEffectiveId())
			then continue end
			if self:isFriend(to) then
				if self:getKeepValue(c)>self:getKeepValue(h) then
					table.insert(valid,h:getEffectiveId())
					table.insert(valid,c:getEffectiveId())
					break
				end
			elseif self:getKeepValue(c)<self:getKeepValue(h) then
				table.insert(valid,h:getEffectiveId())
				table.insert(valid,c:getEffectiveId())
				break
			end
		end
	end
	if #valid<1 then return end
	return string.format("#zujieliCard:%s:",table.concat(valid,"+"))
end

sgs.ai_skill_playerchosen.kezutanque = function(self, players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
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

sgs.ai_fill_skill.kezushengmo = function(self)
	for _,pn in sgs.list(patterns())do
		if self.player:getMark("kezushengmo_guhuo_remove_"..pn)>0 then continue end
		local dc = dummyCard(pn)
		if dc and dc:getTypeId()==1 and self:getCardsNum(dc:getClassName())<1 then
			dc:setSkillName("kezushengmo")
			if dc:isAvailable(self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					if dc:canRecast() and d.to:isEmpty() then break end
					self.kezushengmoUse = d
					sgs.ai_use_priority.zuchengqiCard = sgs.ai_use_priority[dc:getClassName()]
					return sgs.Card_Parse("#kezushengmoCard:.:"..pn)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#kezushengmoCard"] = function(card,use,self)
	local ut = self.kezushengmoUse
	if ut and ut.card then
		use.card = card
		use.to = ut.to
	end
end

sgs.ai_use_value.kezushengmoCard = 3.4
sgs.ai_use_priority.kezushengmoCard = 9.2

sgs.ai_guhuo_card.kezushengmo = function(self,toname,class_name)
    if self.player:getMark("kezushengmo_guhuo_remove_"..toname)>0
	or self:getCardsNum(class_name)>0 then return end
	return "#kezushengmoCard:.:"..toname
	end

sgs.ai_fill_skill.zukaiji = function(self)
	if self.player:getMark("sgszukaijiTo_lun")<1 then
		for _,h in sgs.list(self.player:getHandcards())do
			if h:isAvailable(self.player) and self:aiUseCard(h).card then
				return sgs.Card_Parse("#zukaijiCard:.:")
end
		end
	end
	return self:getOverflow()>0
	and sgs.Card_Parse("#zukaijiCard:.:")
end

sgs.ai_skill_use_func["#zukaijiCard"] = function(card,use,self)
	if self.player:getMark("sgszukaijiTo_lun")<1 then
		use.card = card
		use.to:append(self.player)
		return
	end
	self:sort(self.friends,nil,true)
	for _,p in sgs.list(self.friends)do
		if p:getMark("sgszukaijiTo_lun")>0
		then continue end
		use.card = card
		use.to:append(p)
		break
	end
end

sgs.ai_use_value.zukaijiCard = 3.4
sgs.ai_use_priority.zukaijiCard = 11.2

sgs.ai_skill_use["@@zukaiji"] = function(self,prompt)
	local cs = {}
    for _,id in sgs.list(self.player:getTag("zukaijiForAI"):toIntList())do
      	table.insert(cs,sgs.Sanguosha:getCard(id))
	end
    local dummy = self:aiUseCard(cs[1])
   	if dummy.card then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
		if cs[1]:canRecast() and #tos<1 then return end
       	return cs[1]:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_cardchosen.zukaiji = function(self,who)
	if self.player==who then
		for _,h in sgs.list(who:getHandcards())do
			if h:isAvailable(who) and self:aiUseCard(h).card then
				return h:getId()
			end
		end
	end
end

sgs.ai_skill_invoke.zuanran = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_playerschosen.zuanran = function(self, players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isFriend(p) and self:canDraw(p)
		then table.insert(tos,p) end
	end
	if #tos<=x/2 and self:canDraw()
	then tos = {} end
	return tos
end

sgs.ai_skill_use["@@zugaobian"] = function(self,prompt)
    if self.player:getMark("&zuanran+#num")>2 and self.player:hasSkill("kezuzhongliu")
	and not self:isWeak() then return end
	for _,id in sgs.list(self.player:getTag("zugaobianForAI"):toIntList())do
      	local c = sgs.Sanguosha:getCard(id)
		if c:isAvailable(self.player) then
			local dummy = self:aiUseCard(c)
			if dummy.card then
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,p:objectName())
				end
				return c:toString().."->"..table.concat(tos,"+")
			end
		end
	end
    for _,id in sgs.list(self.player:getTag("zugaobianForAI"):toIntList())do
      	local c = sgs.Sanguosha:getCard(id)
		if c:isAvailable(self.player) then
			for _,p in sgs.list(self.enemies)do
				if self.player:canSlash(p,c) then
					return c:toString().."->"..p:objectName()
				end
			end
			for _,p in sgs.list(self.room:getAlivePlayers())do
				if not self:isFriend(p) and self.player:canSlash(p,c) then
					return c:toString().."->"..p:objectName()
				end
			end
		end
	end
end

sgs.ai_skill_invoke.zuqieyi = function(self,data)
	return self:canDraw() and not self:isWeak()
end

sgs.ai_skill_playerchosen.zuquhuo = function(self, players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		and #self.enemies>0
		then return target end
	end
end

sgs.ai_skill_playerchosen.zujiewu = function(self, players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_invoke.zujiewu = function(self,data)
	local use = data:toCardUse()
	self.zujiewusuit = use.card:getSuitString()
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if p:getMark("&zujiewu+#"..self.player:objectName().."-PlayClear")>0
		and getKnownCard(p,self.player,self.zujiewusuit)>0
		then return true end
	end
end

sgs.ai_skill_cardchosen.zujiewu = function(self,who)
	for _,h in sgs.list(getKnownCards(who,self.player,"h"))do
		if self.zujiewusuit==h:getSuitString() then
			return h:getId()
		end
	end
end

sgs.ai_skill_invoke.zugaoshi = function(self,data)
	return self:canDraw() or self:isWeak()
end

sgs.ai_skill_use["@@zugaoshi"] = function(self,prompt)
	local cs = {}
    for _,id in sgs.list(self.player:getTag("zugaoshiForAI"):toIntList())do
      	table.insert(cs,sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(cs)
    for _,c in sgs.list(cs)do
		if c:isAvailable(self.player) then
			local dummy = self:aiUseCard(c)
			if dummy.card then
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,p:objectName())
				end
				if c:canRecast() and #tos<1 then continue end
				return c:toString().."->"..table.concat(tos,"+")
			end
		end
	end
end

sgs.ai_skill_invoke.zuyangji = function(self,data)
    local n = 0
	for _,h in sgs.list(self.player:getHandcards())do
		if h:isBlack() and h:isAvailable(self.player) then
			if self:aiUseCard(h).card then n = n+1 end
		end
	end
	return n>=self.player:getHandcardNum()/3
end

sgs.ai_skill_use["zuyangji0"] = function(self,prompt)
	local cs = {}
    for _,h in sgs.list(self.player:getHandcards())do
      	if h:isBlack() then table.insert(cs,h) end
	end
	self:sortByUseValue(cs)
    for _,c in sgs.list(cs)do
		if c:isAvailable(self.player) then
			local dummy = self:aiUseCard(c)
			if dummy.card then
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,p:objectName())
				end
				if c:canRecast() and #tos<1 then continue end
				return c:toString().."->"..table.concat(tos,"+")
			end
		end
	end
end


sgs.ai_skill_use["@@zujuetu!"] = function(self,prompt)
	local valid = {}
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local suits = {}
	for i,h in sgs.list(cards)do
		if table.contains(suits,h:getSuit()) then continue end
    	table.insert(valid,h:getEffectiveId())
    	table.insert(suits,h:getSuit())
	end
	if #valid<1 then return end
	return string.format("#zujuetuCard:%s:",table.concat(valid,"+"))
end

sgs.ai_skill_playerchosen.zujuetu = function(self, players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_use["@@zujuetu1!"] = function(self,prompt)
	local dc = dummyCard("dismantlement","_zujuetu")
	dc:addSubcard(self.player:getMark("zujuetuId"))
	local dummy = self:aiUseCard(dc)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return dc:toString().."->"..table.concat(tos,"+")
	end
    for _,p in sgs.list(self.enemies)do
		if self.player:canUse(dc,p)
		then return dc:toString().."->"..p:objectName() end
	end
    for _,p in sgs.list(self.room:getAlivePlayers())do
		if not self:isFriend(p) and #self.enemies>0
		then return dc:toString().."->"..p:objectName() end
	end
    for _,p in sgs.list(self.room:getAlivePlayers())do
		if not self:isFriend(p) then return dc:toString().."->"..p:objectName() end
	end
end


sgs.ai_fill_skill.zukudu = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards,nil,"j") -- 按保留值排序
	local ids = {}
	for _,c1 in sgs.list(cards)do
		if table.contains(self.toUse,c1)
		or self:getKeepValue(c1)>6 then continue end
		table.insert(ids,c1:getId())
		if #ids>1 then return sgs.Card_Parse("#zukuduCard:"..table.concat(ids,"+")..":") end
	end
end

sgs.ai_skill_use_func["#zukuduCard"] = function(card,use,self)
	local tps = self:sort(self.room:getAlivePlayers())
	for i,p in sgs.list(tps)do
		if i>#tps/2 and p~=self.player and self:isFriend(p) then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.zukuduCard = 3.4
sgs.ai_use_priority.zukuduCard = 6.2

sgs.ai_skill_invoke.zujiannan = function(self,data)
	return self:canDraw() or self:isWeak()
end

sgs.ai_skill_playerchosen.zujiannan = function(self, players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self.player:getMark("zujiannan2-Clear")<1
		and self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_choice["zujiannan"] = function(self, choices, data)
	local items = choices:split("+")
	local to = data:toPlayer()
    if self:isFriend(to) and table.contains(items,"zujiannan2")
	then return "zujiannan2" end
end

sgs.ai_skill_cardask.zujiannan4 = function(self,data,pattern)
    local parsed = data:toPlayer()
    if self:isFriend(parsed)
	or self:isWeak() then return true end
	return "."
end

sgs.ai_skill_playerchosen.zuyichi = function(self, players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_playerschosen.zufennu = function(self, players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isEnemy(p) then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and not self:isFriend(p) and #self.enemies>0
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_playerchosen.zuzelie = function(self, players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		sgs.ai_skill_choice.zuzelie = "zuzelie1"
		if self:isFriend(p) and self:canDraw(p)
		and p:getMark("&zuzelie1Bf-Clear")<1
		then return p end
	end
    for _,p in sgs.list(destlist)do
		sgs.ai_skill_choice.zuzelie = "zuzelie2"
		if self:isEnemy(p) and p:getMark("&zuzelie2Bf-Clear")<1
		then return p end
	end
    for _,p in sgs.list(destlist)do
		sgs.ai_skill_choice.zuzelie = "zuzelie1"
		if self:isFriend(p) and p:getMark("&zuzelie1Bf-Clear")<1
		then return p end
	end
    for _,p in sgs.list(destlist)do
		sgs.ai_skill_choice.zuzelie = "zuzelie2"
		if not self:isFriend(p) and p:getMark("&zuzelie2Bf-Clear")<1
		then return p end
	end
end



sgs.ai_fill_skill.zutanfeng = function(self)
	return sgs.Card_Parse("#zutanfengCard:.:")
end

sgs.ai_skill_use_func["#zutanfengCard"] = function(card,use,self)
	local dc = dummyCard()
	dc:setFlags("Qinggang")
	local d = self:aiUseCard(dc)
	if d.card then
		use.card = card
		use.to:append(d.to:first())
		return
	end
end

sgs.ai_use_value.zutanfengCard = 3.4
sgs.ai_use_priority.zutanfengCard = 2.8

sgs.ai_skill_invoke.zutanfeng = function(self,data)
	local to = data:toPlayer()
	return self:isEnemy(to)
end

sgs.ai_skill_cardask.zujuewei0 = function(self,data,pattern)
	local use = data:toCardUse()
	if use.from==self.player then
		sgs.ai_skill_choice.zujuewei = "zujuewei1"
		if self:isEnemy(use.to:first()) then return true end
	else
		sgs.ai_skill_choice.zujuewei = "zujuewei2"
		if self:isWeak() then return true end
	end
	return "."
end








