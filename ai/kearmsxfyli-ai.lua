
sgs.ai_skill_askforyiji.kesxjimeng = function(self,card_ids,tos)
    local p,i = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if not p and self.player:getPhase()~=sgs.Player_Start then
		p = tos:at(0)
		i = card_ids[#card_ids]
	end
	return p,i
end

sgs.ai_skill_playerschosen.kesxhehe = function(self,players)
    local tos = {}
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	for _,p in sgs.list(destlist)do
		if self:isFriend(p) and #tos<2 then table.insert(tos,p) end
	end
	for _,p in sgs.list(destlist)do
		if not self:isEnemy(p) and #tos<2 and #self.enemies>0 and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_fill_skill.kesxquedi = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if c:isKindOf("Slash") then
			local can = dummyCard("duel")
			can:setSkillName("kesxquedi")
			can:addSubcard(c)
			if can:isAvailable(self.player) then
				return can
			end
		end
	end
end

sgs.ai_skill_playerchosen.kesxchunlao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"card")
	local tag = self.player:getTag("kesxchunlaoToGet"):toIntList()
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		and target:getHandcardNum()<tag:length()
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		and target:getHandcardNum()>=tag:length()
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_invoke.kesxchunlao = function(self,data)
	local srt = data:toString():split(":")
	local to = BeMan(self.room,srt[2])
	if to then
		return self:isFriend(to) or not self:isEnemy(to) and #self.enemies>0
	end
end

sgs.ai_skill_playerschosen.kesxxiongsuan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) then table.insert(tos,p) end
	end
	self:sort(destlist,nil,true)
    for _,p in sgs.list(destlist)do
		if #tos<2 and not table.contains(tos,p)
		and not self:isFriend(p)
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<1 then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_fill_skill.kesxtiaohe = function(self)
	return sgs.Card_Parse("#kesxtiaoheCard:.:")
end

sgs.ai_skill_use_func["#kesxtiaoheCard"] = function(card,use,self)
	self:sort(self.friends)
	for _,ep in sgs.list(self.friends)do
		if use.to:isEmpty() then
			local w = ep:getWeapon()
			if w and self:doDisCard(ep,w:getEffectiveId()) then
				use.to:append(ep)
			end
		else
			if use.to:contains(ep) then continue end
			local a = ep:getArmor()
			if a and self:doDisCard(ep,a:getEffectiveId()) then
				use.to:append(ep)
				use.card = card
				return
			end
		end
	end
	for _,ep in sgs.list(self.friends)do
		if use.to:isEmpty() then
			local w = ep:getWeapon()
			if w and self:doDisCard(ep,w:getEffectiveId()) then
				use.to:append(ep)
			end
		else
			if use.to:contains(ep) then continue end
			local a = ep:getArmor()
			if a and self:doDisCard(ep,a:getEffectiveId()) then
				use.to:append(ep)
				use.card = card
				return
			end
		end
	end
	self:sort(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if use.to:isEmpty() then
			local w = ep:getWeapon()
			if w and self:doDisCard(ep,w:getEffectiveId()) then
				use.to:append(ep)
			end
		else
			if use.to:contains(ep) then continue end
			local a = ep:getArmor()
			if a and self:doDisCard(ep,a:getEffectiveId()) then
				use.to:append(ep)
				use.card = card
				return
			end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if use.to:isEmpty() then
			local w = ep:getWeapon()
			if w and self:doDisCard(ep,w:getEffectiveId()) then
				use.to:append(ep)
			end
		else
			if use.to:contains(ep) then continue end
			local a = ep:getArmor()
			if a and self:doDisCard(ep,a:getEffectiveId()) then
				use.to:append(ep)
				use.card = card
				return
			end
		end
	end
	for _,ep in sgs.list(self.room:getAlivePlayers())do
		if self:isFriend(ep) or use.to:contains(ep) then continue end
		if use.to:isEmpty() then
			if ep:getWeapon() then
				use.to:append(ep)
			end
		else
			if ep:getArmor() then
				use.to:append(ep)
				use.card = card
				return
			end
		end
	end
end

sgs.ai_use_value.kesxtiaoheCard = 7.4
sgs.ai_use_priority.kesxtiaoheCard = 6.2

sgs.ai_skill_invoke.kesxqiansu = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill.kesxbazhan = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	self:sort(self.enemies)
	for _,c in sgs.list(cards)do
	   	if table.contains(self.toUse,c) then continue end
		for _,ep in sgs.list(self.enemies)do
			if ep:getMark("&kesxqiaoying-Clear") == ep:getHandcardNum() and self.player:inMyAttackRange(ep) then
				self.ht_to = ep
				return sgs.Card_Parse("#kesxbazhanCard:"..c:getEffectiveId()..":")
			end
		end
	end
	for _,c in sgs.list(cards)do
	   	if table.contains(self.toUse,c) then continue end
		for _,ep in sgs.list(self.enemies)do
			if ep:getMark("&kesxqiaoying-Clear") == ep:getHandcardNum() then
				self.ht_to = ep
				return sgs.Card_Parse("#kesxbazhanCard:"..c:getEffectiveId()..":")
			end
		end
	end
	for _,c in sgs.list(cards)do
	   	if table.contains(self.toUse,c) then continue end
		for _,ep in sgs.list(self.friends_noself)do
			if ep:getMark("&kesxqiaoying-Clear") > ep:getHandcardNum() then
				self.ht_to = ep
				return sgs.Card_Parse("#kesxbazhanCard:"..c:getEffectiveId()..":")
			end
		end
	end
	for _,c in sgs.list(cards)do
	   	if table.contains(self.toUse,c) then continue end
		for _,ep in sgs.list(self.friends_noself)do
			if ep:getMark("&kesxqiaoying-Clear") <= ep:getHandcardNum() then
				self.ht_to = ep
				return sgs.Card_Parse("#kesxbazhanCard:"..c:getEffectiveId()..":")
			end
		end
	end
end

sgs.ai_skill_use_func["#kesxbazhanCard"] = function(card,use,self)
	use.card = card
	use.to:append(self.ht_to)
end

sgs.ai_use_value.kesxbazhanCard = 7.4
sgs.ai_use_priority.kesxbazhanCard = 2.2

sgs.ai_skill_invoke.kesxyibing = function(self,data)
	local target = data:toPlayer()
	if target then
		if self:isFriend(target) then return self:doDisCard(target,"e",true)
		else return self:doDisCard(target,"he",true) end
	end
end

sgs.ai_skill_use["@@kesxzhiyi"] = function(self,prompt)
	local dc = dummyCard()
	dc:setSkillName("_kesxzhiyi")
    local dummy = self:aiUseCard(dc)
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dc:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_playerchosen.kesxdaoshu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local cp = self.room:getCurrent()
	if self:isEnemy(cp) then
		for _,p in sgs.list(destlist)do
			if self:isEnemy(p)
			then return p end
		end
		for _,p in sgs.list(destlist)do
			if not self:isFriend(p)
			then return p end
		end
	else
		for _,p in sgs.list(destlist)do
			if self:isEnemy(p)
			and cp:inMyAttackRange(p)
			and p:getHandcardNum()<3
			then return p end
		end
	end
end


sgs.ai_skill_playerchosen.kesxfenghun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	for _,p in sgs.list(destlist)do
		if not self:isFriend(p) then
			for _,e in sgs.list(p:getCards("e"))do
				if e:getSuit() == sgs.Card_Diamond and self:doDisCard(p,e:getEffectiveId()) then
					return p
				end
			end
			for _,e in sgs.list(p:getCards("e"))do
				if e:getSuit() == sgs.Card_Diamond then
					return p
				end
			end
		end
	end
	for _,p in sgs.list(destlist)do
		if self:isFriend(p) then
			for _,e in sgs.list(p:getCards("he"))do
				if e:getSuit() == sgs.Card_Diamond and self:doDisCard(p,e:getEffectiveId()) then
					return p
				end
			end
			for _,e in sgs.list(p:getCards("he"))do
				if e:getSuit() == sgs.Card_Diamond then
					return p
				end
			end
		end
	end
	for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and self:doDisCard(p,"he") then
			return p
		end
	end
end


sgs.ai_skill_cardchosen.kesxfenghun = function(self,who,flags,method)
	if who:objectName()==self.player:objectName() then
		local cards = self:sortByKeepValue(who:getCards("he"))
		for _,e in sgs.list(cards)do
			if e:getSuit() == sgs.Card_Diamond and self:doDisCard(who,e:getEffectiveId()) then
				return e:getEffectiveId()
			end
		end
		for _,e in sgs.list(cards)do
			if e:getSuit() == sgs.Card_Diamond then
				return e:getEffectiveId()
			end
		end
	else
		for _,e in sgs.list(who:getCards("e"))do
			if e:getSuit() == sgs.Card_Diamond and self:doDisCard(who,e:getEffectiveId()) then
				return e:getEffectiveId()
			end
		end
		for _,e in sgs.list(who:getCards("e"))do
			if e:getSuit() == sgs.Card_Diamond then
				return e:getEffectiveId()
			end
		end
	end
end



sgs.ai_fill_skill.kesxxiongyi = function(self)
	return sgs.Card_Parse("#kesxxiongyiCard:.:")
end

sgs.ai_skill_use_func["#kesxxiongyiCard"] = function(card,use,self)
	self:sort(self.friends,nil,true)
	for _,p in sgs.list(self.friends)do
		if getKnownCard(p,self.player,"Slash")>0 then
			for _,ep in sgs.list(self.enemies)do
				if p:canSlash(ep) then
					use.to:append(ep)
					if use.to:length()>#self.friends/2 and sgs.turncount>1 then
						use.card = card
					end
					break
				end
			end
		end
	end
end

sgs.ai_use_value.kesxxiongyiCard = 5.4
sgs.ai_use_priority.kesxxiongyiCard = 0.2
sgs.ai_card_intention.kesxxiongyiCard = -77




sgs.ai_skill_use["@@kesxyouqi"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAllPlayers()
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
    self:sort(destlist)
	for _,p in sgs.list(destlist)do
    	if self:isFriend(p) and p:getKingdom() == "qun" then
			for _,e in sgs.list(self:poisonCards("e",p))do
				if e:isKindOf("Horse") then
					local n = e:getRealCard():toEquipCard():location()
					for _,q in sgs.list(destlist)do
						if self:isEnemy(q)and q:hasEquipArea(n) and not q:getEquip(n) then
							self.kesxyouqiEid = e:getId()
							table.insert(valid,p:objectName())
							table.insert(valid,q:objectName())
							return string.format("#kesxyouqiCard:.:->%s",table.concat(valid,"+"))
						end
					end
					for _,q in sgs.list(destlist)do
						if not self:isFriend(q)and q:hasEquipArea(n) and not q:getEquip(n) then
							self.kesxyouqiEid = e:getId()
							table.insert(valid,p:objectName())
							table.insert(valid,q:objectName())
							return string.format("#kesxyouqiCard:.:->%s",table.concat(valid,"+"))
						end
					end
				end
			end
		end
	end
	for _,p in sgs.list(destlist)do
    	if self:isEnemy(p) and p:getKingdom() == "qun" then
			for _,e in sgs.list(p:getEquips())do
				if e:isKindOf("Horse") and #self:poisonCards({e},p)<1 then
					local n = e:getRealCard():toEquipCard():location()
					for _,q in sgs.list(destlist)do
						if self:isFriend(q)and q:hasEquipArea(n) and not q:getEquip(n) then
							self.kesxyouqiEid = e:getId()
							table.insert(valid,p:objectName())
							table.insert(valid,q:objectName())
							return string.format("#kesxyouqiCard:.:->%s",table.concat(valid,"+"))
						end
					end
					for _,q in sgs.list(destlist)do
						if not self:isEnemy(q)and q:hasEquipArea(n) and not q:getEquip(n) then
							self.kesxyouqiEid = e:getId()
							table.insert(valid,p:objectName())
							table.insert(valid,q:objectName())
							return string.format("#kesxyouqiCard:.:->%s",table.concat(valid,"+"))
						end
					end
				end
			end
		end
	end
	for _,p in sgs.list(destlist)do
    	if not self:isFriend(p) and p:getKingdom() == "qun" then
			for _,e in sgs.list(p:getEquips())do
				if e:isKindOf("Horse") and #self:poisonCards({e},p)<1 then
					local n = e:getRealCard():toEquipCard():location()
					for _,q in sgs.list(destlist)do
						if self:isFriend(q)and q:hasEquipArea(n) and not q:getEquip(n) then
							self.kesxyouqiEid = e:getId()
							table.insert(valid,p:objectName())
							table.insert(valid,q:objectName())
							return string.format("#kesxyouqiCard:.:->%s",table.concat(valid,"+"))
						end
					end
					for _,q in sgs.list(destlist)do
						if not self:isEnemy(q) and q:hasEquipArea(n) and not q:getEquip(n) then
							self.kesxyouqiEid = e:getId()
							table.insert(valid,p:objectName())
							table.insert(valid,q:objectName())
							return string.format("#kesxyouqiCard:.:->%s",table.concat(valid,"+"))
						end
					end
				end
			end
		end
	end
end

sgs.ai_skill_cardchosen.kesxfenghun = function(self,who,flags,method)
	if self.kesxyouqiEid then
		return self.kesxyouqiEid
	end
end


sgs.ai_fill_skill.kesxmingfa = function(self)
	return sgs.Card_Parse("#kesxmingfaCard:.:")
end

sgs.ai_skill_use_func["#kesxmingfaCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if p:getHp()>1 and self:damageIsEffective(p,"N") then
			use.to:append(p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.kesxmingfaCard = 5.4
sgs.ai_use_priority.kesxmingfaCard = 0.2
sgs.ai_card_intention.kesxmingfaCard = 77

sgs.ai_skill_playerschosen.kesxhuiji = function(self,players)
    local tos = {}
	local use = self.player:getTag("kesxhuijiUse"):toCardUse()
	local d = self:aiUseCard(use.card,dummy(true,1,use.to))
	if d.card then
		for _,p in sgs.list(players)do
			if d.to:contains(p) and #tos<2
			then table.insert(tos,p) end
		end
	end
	return tos
end


sgs.ai_fill_skill.kesxxiongxia = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c1 in sgs.list(cards)do
		for _,c2 in sgs.list(cards)do
			if c1==c2 then continue end
			local dc = dummyCard("duel")
			dc:addSubcard(c1)
			dc:addSubcard(c2)
			dc:setSkillName("kesxxiongxia")
			local d = self:aiUseCard(dc,dummy(nil,1))
			if d.card and d.to:length()==2 then
				local valid = {}
				table.insert(valid,c1:getEffectiveId())
				table.insert(valid,c2:getEffectiveId())
				self.kesxxiongxia_to = d.to
				return sgs.Card_Parse("#kesxxiongxiaCard:"..table.concat(valid,"+")..":")
			end
		end
	end
end

sgs.ai_skill_use_func["#kesxxiongxiaCard"] = function(card,use,self)
	if self.kesxxiongxia_to then
		use.card = card
		use.to = self.kesxxiongxia_to
	end
end

sgs.ai_use_value.kesxxiongxiaCard = 5.4
sgs.ai_use_priority.kesxxiongxiaCard = 2.2
sgs.ai_card_intention.kesxxiongxiaCard = 77


sgs.ai_skill_invoke.kesxjinjian = function(self,data)
	local str = data:toString():split(":")
	if str[1]=="kesxjinjian0" then
		local to = BeMan(self.room,str[2])
		return self:isFriend(to)
	else
		local to = BeMan(self.room,str[2])
		return self:isEnemy(to) or not self:isFriend(to) and #self.enemies<1
	end
end








sgs.ai_fill_skill.sxwuyou = function(self)
	return sgs.Card_Parse("#sxwuyouCard:.:")
end

sgs.ai_skill_use_func["#sxwuyouCard"] = function(card,use,self)
	local dc = dummyCard("duel")
	for _,p in sgs.list(self:aiUseCard(dc,dummy(nil,99)).to)do
		if self.player:canPindian(p) then
			use.to:append(p)
			use.card = card
			break
		end
	end
end

sgs.ai_use_value.sxwuyouCard = 3.4
sgs.ai_use_priority.sxwuyouCard = 3.2
sgs.ai_card_intention.sxwuyouCard = 44

sgs.ai_fill_skill.sxbeiwu = function(self)
    local cards = self.player:getCards("e")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local pts = {"ex_nihilo","duel"}
	for _,c in sgs.list(cards)do
		if self.player:getMark(c:toString().."sxbeiwu-Clear")<1 then
			local dc = dummyCard(pts[math.random(1,2)])
			dc:setSkillName("sxbeiwu")
			dc:addSubcard(c)
			if dc:isAvailable(self.player) and self:aiUseCard(dc).card then
				return dc
			end
		end
	end
end

sgs.ai_skill_invoke.sxchengshi = function(self,data)
	local target = data:toPlayer()
	if target then
		return target:getEquips():length()-#self:poisonCards("e",target)>self.player:getEquips():length()-#self:poisonCards("e")
	end
end

sgs.ai_fill_skill.sxxiemuvs = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if c:getTypeId()==1 then
			return sgs.Card_Parse("#sxxiemuCard:"..c:toString()..":")
		end
	end
end

sgs.ai_skill_use_func["#sxxiemuCard"] = function(card,use,self)
	self:sort(self.enemies)
	local has = false
	for i,p in sgs.list(self.enemies)do
		if i<=#self.enemies/2 and self.player:distanceTo(p)-self.player:getAttackRange()==1 then
			has = true
			break
		end
	end
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if has and p:hasSkill("sxxiemu") then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.sxxiemuCard = 5.4
sgs.ai_use_priority.sxxiemuCard = 3.2
sgs.ai_card_intention.sxxiemuCard = -33

sgs.ai_fill_skill.sxnaman = function(self)
	return sgs.Card_Parse("#sxnamanCard:.:")
end

sgs.ai_skill_use_func["#sxnamanCard"] = function(card,use,self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local bs = {}
	for _,c in sgs.list(cards)do
		if c:getTypeId()==1 then
			table.insert(bs,c:getId())
		end
	end
	local dc = dummyCard("duel")
	for _,p in sgs.list(self:aiUseCard(dc,dummy(nil,99)).to)do
		if use.to:length()<#bs and self:hasTrickEffective(dummyCard("savage_assault"),p) then
			use.to:append(p)
		end
	end
	if use.to:length()>0 then
		cards = {}
		for _,id in sgs.list(bs)do
			if #cards<use.to:length() then
				table.insert(cards,id)
			end
		end
		use.card = sgs.Card_Parse("#sxnamanCard:"..table.concat(cards,"+")..":")
	end
end

sgs.ai_use_value.sxnamanCard = 3.4
sgs.ai_use_priority.sxnamanCard = 2.2
sgs.ai_card_intention.sxnamanCard = 66

sgs.ai_skill_playerchosen.sxjujian = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isEnemy(p) and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_playerchosen.sxxingfa = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p,"N")
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies<1
		then return p end
	end
end

sgs.ai_skill_invoke.sxshangjian = function(self,data)
	local ids = data:toIntList()
	if self:canDraw() then
		return true
	end
end

sgs.ai_skill_invoke.sxfunan = function(self,data)
	local effect = data:toCardEffect()
	if self:canDraw() then
		return true
	end
end

sgs.ai_skill_playerchosen.sxjiexun = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		and self:hasSuit("diamond",false,p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_discard.sxjiexun = function(self,x,n)
	local discard = {}
	for _,c in ipairs(self:sortByKeepValue(self.player:getHandcards()))do
		if self.player:isCardLimited(c,sgs.Card_MethodDiscard,true)
		or c:getSuit()~=3 then continue end
		table.insert(discard,c:getEffectiveId())
		if #discard>=n then return discard end
	end
end

sgs.ai_skill_invoke.sxdingyi = function(self,data)
	if self:canDraw() then
		return true
	end
end

sgs.ai_skill_playerchosen.sxzuici = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local from = self.player:getTag("sxzuiciFrom"):toPlayer()
	if self:isFriend(from) then
		for _,p in sgs.list(destlist)do
			if not self:isFriend(p) then return p end
		end
	else
		for _,p in sgs.list(destlist)do
			if self:isFriend(p) and #self:poisonCards("ej",p)>0
			then return p end
		end
	end
end


sgs.ai_fill_skill.sxyinge = function(self)
	return sgs.Card_Parse("#sxyingeCard:.:")
end

sgs.ai_skill_use_func["#sxyingeCard"] = function(card,use,self)
	self:sort(self.friends_noself,nil,true)
	for _,p in sgs.list(self.enemies)do
		if self.player:inMyAttackRange(p) then
			for _,q in sgs.list(self.friends_noself)do
				if q:getCardCount()>0 then
					use.to:append(q)
					use.card = card
					return
				end
			end
		end
	end
	for _,p in sgs.list(self.friends_noself)do
		if self.player:inMyAttackRange(p) and self:isWeak(p) then
			return
		end
	end
	self:sort(self.enemies)
	for _,q in sgs.list(self.enemies)do
		if q:getCardCount()>0 then
			use.to:append(q)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxyingeCard = 3.4
sgs.ai_use_priority.sxyingeCard = 4.2
--sgs.ai_card_intention.sxwuyouCard = 44

sgs.ai_skill_playerchosen.sxyinge = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_invoke.sxshiren = function(self,data)
	if self:canDraw() then
		return true
	end
end

sgs.ai_skill_invoke.sxjuyi = function(self,data)
	local target = data:toPlayer()
	if target then
		return self:isFriend(target)
	end
end

sgs.ai_skill_invoke.sxzishou = function(self,data)
	if self:canDraw() then
		return #self.enemies<1 or self:getOverflow()<0
	end
end

sgs.ai_skill_discard.sxjujing = function(self,x,n)
	local discard = {}
	for _,c in ipairs(self:sortByKeepValue(self.player:getCards("he")))do
		if self.player:isCardLimited(c,sgs.Card_MethodDiscard,true) then continue end
		table.insert(discard,c:getEffectiveId())
		if #discard>=n and (self:isWeak() or #self:poisonCards("he")>0)
		then return discard end
	end
end

sgs.ai_skill_invoke.sxfengbai = function(self,data)
	local target = data:toPlayer()
	if target and self:canDraw(target) then
		return self:isFriend(target)
	end
end

sgs.ai_skill_discard.sxhuaiyi = function(self,x,n)
	local cs = {}
	for _,c in ipairs(self:sortByKeepValue(self.player:getCards("h")))do
		if self.player:isCardLimited(c,sgs.Card_MethodDiscard,true) then continue end
		cs[c:getColorString()] = (cs[c:getColorString()] or 0)+1
	end
	local x = 99
	for k,n in pairs(cs)do
		if n<x then x = n end
	end
	for k,n in pairs(cs)do
		if n<=x then
			for _,c in ipairs(self:sortByKeepValue(self.player:getCards("h")))do
				if self.player:isCardLimited(c,sgs.Card_MethodDiscard,true)
				or c:getColorString()~=k then continue end
				return {c:getEffectiveId()}
			end
		end
	end
end

sgs.ai_skill_playerschosen.sxhuaiyi = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"he",true) and #tos<x then
			table.insert(tos,p)
			if self:isWeak() then
				break
			end
		end
	end
	return tos
end

sgs.ai_skill_cardask["sxzhuikong0"] = function(self,data,pattern)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
	local target = data:toPlayer()
   	for _,c in sgs.list(cards)do
    	if c:isKindOf("Slash") and c:getNumber()>9
		and self:isEnemy(target)
		then return c:getEffectiveId() end
	end
    return "."
end

sgs.ai_skill_use["@@sxzhuikong"] = function(self,prompt)
    for _,id in sgs.list(self.player:getTag("sxzhuikongForAI"):toIntList())do
      	local c = sgs.Sanguosha:getCard(id)
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

sgs.ai_skill_playerchosen.sxqiuyuan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_discard.sxqiuyuan = function(self,x,n)
	local use = self.player:getTag("sxqiuyuanUse"):toCardUse()
	for _,c in ipairs(self:sortByKeepValue(self.player:getCards("he")))do
		if self:slashIsEffective(use.card,self.player,use.from)
		and (self:isWeak() or self:getCardsNum("Jink")<1)
		then return {c:getId()} end
	end
end

sgs.ai_skill_invoke.sxwudu = function(self,data)
	local target = data:toPlayer()
	if target and self:isWeak(target) then
		return self:isFriend(target)
	end
end

sgs.ai_fill_skill.sxgushe = function(self)
	local mc = self:getMaxCard()
	return mc and mc:getNumber()>9
	and sgs.Card_Parse("#sxgusheCard:.:")
end

sgs.ai_skill_use_func["#sxgusheCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p) then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxgusheCard = 3.4
sgs.ai_use_priority.sxgusheCard = 4.2
sgs.ai_card_intention.sxgusheCard = 44

sgs.ai_skill_invoke.sxgushe = function(self,data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) and self:canDraw() then
		local mc = self:getMaxCard()
		return mc and mc:getNumber()>6
	end
end

sgs.ai_skill_invoke.sxjici = function(self,data)
	local pindian = data:toPindian()
	if pindian.to==self.player then
		return self:isEnemy(pindian.from) and not self:isWeak()
		and pindian.from_number>pindian.to_number
		and pindian.to_number<13
	else
		return self:isEnemy(pindian.to) and not self:isWeak()
		and pindian.to_number>=pindian.from_number
		and pindian.from_number<13
		and pindian.to_number<13
	end
end

sgs.ai_skill_invoke.sxyuanqing = function(self,data)
	if self:canDraw() then
		return true
	end
end

function sgs.ai_cardsview.sxshuchen(self,class_name,player)
   	local cards = sgs.QList2Table(player:getCards("h"))
    self:sortByKeepValue(cards)
	for _,card in sgs.list(cards)do
		return ("peach:sxshuchen[no_suit:0]="..card:getEffectiveId())
	end
end

sgs.ai_skill_discard.sxjinglve = function(self,x,n)
	local discard = {}
	local cp = self.room:getCurrent()
	for _,c in ipairs(self:sortByKeepValue(self.player:getCards("he")))do
		table.insert(discard,c:getEffectiveId())
		if #discard>=n and self.player:getCardCount()>2
		and self:getOverflow(cp)>0 and self:isEnemy(cp)
		then return discard end
	end
end

sgs.ai_skill_invoke.sxjinglve = function(self,data)
	if self:canDraw() then
		return true
	end
end

sgs.ai_fill_skill.sxchengji = function(self)
   	local cards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(cards)
	for _,c1 in sgs.list(cards)do
		local dc = dummyCard()
		dc:setSkillName("sxchengji")
		dc:addSubcard(c1)
		for _,c2 in sgs.list(cards)do
			if c1:getColor()~=c2:getColor() then
				dc:addSubcard(c2)
				return dc
			end
		end
	end
end

function sgs.ai_cardsview.sxchengji(self,class_name,player)
   	local cards = sgs.QList2Table(player:getCards("he"))
    self:sortByKeepValue(cards)
	for _,c1 in sgs.list(cards)do
		local dc = dummyCard()
		dc:setSkillName("sxchengji")
		dc:addSubcard(c1)
		for _,c2 in sgs.list(cards)do
			if c1:getColor()~=c2:getColor() then
				dc:addSubcard(c2)
				return dc:toString()
			end
		end
	end
end

sgs.ai_skill_use["@@sxzhengnan"] = function(self,prompt)
	for _,c in ipairs(self:sortByKeepValue(self.player:getCards("h")))do
      	local dc = dummyCard()
		dc:setSkillName("sxzhengnan")
		dc:addSubcard(c)
		if c:isRed() and dc:isAvailable(self.player) then
			local dummy = self:aiUseCard(dc)
			if dummy.card then
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,p:objectName())
				end
				if dc:canRecast() and #tos<1 then continue end
				return dc:toString().."->"..table.concat(tos,"+")
			end
		end
	end
end

sgs.ai_fill_skill.sxzhanjue = function(self)
   	local ids = sgs.QList2Table(self.player:handCards())
	return sgs.Card_Parse("#sxzhanjueCard:"..table.concat(ids,"+")..":")
end

sgs.ai_skill_use_func["#sxzhanjueCard"] = function(card,use,self)
	local dc = dummyCard("duel")
	dc:setSkillName("sxzhanjue")
	dc:addSubcards(self.player:getCards("h"))
	if dc:isAvailable(self.player) then
		local d = self:aiUseCard(dc)
		for _,p in sgs.list(d.to)do
			if p:getHandcardNum()<self.player:getHandcardNum()
			or getCardsNum("Slash",p,self.player)<1 then
				use.to:append(p)
				use.card = card
			end
		end
	end
end

sgs.ai_use_value.sxzhanjueCard = 3.4
sgs.ai_use_priority.sxzhanjueCard = -1.2
sgs.ai_card_intention.sxzhanjueCard = 66

sgs.ai_skill_invoke.sxqinwang = function(self,data)
	if #self.friends_noself>0 then
		return true
	end
end

sgs.ai_skill_cardask["sxzhengnan0"] = function(self,data,pattern)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
	local target = data:toPlayer()
   	for _,c in sgs.list(cards)do
    	if c:getTypeId()==1 and getCardsNum("Slash",target,self.player)<1
		and self:isFriend(target) and self:isWeak(target)
		then return c:getEffectiveId() end
	end
    return "."
end

sgs.ai_skill_invoke.sxhuituo = function(self,data)
	if self:canDraw() then
		return true
	end
end

sgs.ai_skill_use["@@sxhuituo"] = function(self,prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
	local ids = {}
    for _,id in sgs.list(self.player:getTag("sxhuituoForAI"):toIntList())do
      	local c = sgs.Sanguosha:getCard(id)
		for _,h in sgs.list(cards)do
			if table.contains(ids,h:getId()) then continue end
			if self:getKeepValue(c)>self:getKeepValue(h) then
				table.insert(ids,h:getId())
				table.insert(ids,id)
				break
			end
		end
	end
	if #ids>1 then
		return "#sxhuituoCard:"..table.concat(ids,"+")..":"
	end
end

sgs.ai_fill_skill.sxmingjian = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if not c:isDamageCard() then continue end
		for _,p in sgs.list(self.friends_noself)do
			if c:isAvailable(p) then
				self.sxmingjianTo = p
				return sgs.Card_Parse("#sxmingjianCard:"..c:toString()..":")
			end
		end
	end
	for _,c in sgs.list(cards)do
		for _,p in sgs.list(self.friends_noself)do
			if c:isAvailable(p) then
				self.sxmingjianTo = p
				return sgs.Card_Parse("#sxmingjianCard:"..c:toString()..":")
			end
		end
	end
end

sgs.ai_skill_use_func["#sxmingjianCard"] = function(card,use,self)
	if self.sxmingjianTo then
		use.to:append(self.sxmingjianTo)
		use.card = card
	end
end

sgs.ai_use_value.sxmingjianCard = 3.4
sgs.ai_use_priority.sxmingjianCard = -1.2
sgs.ai_card_intention.sxmingjianCard = -66

sgs.ai_skill_playerchosen.sxbaobian = function(self,players)
	if self:isWeak() then return end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies>0
		then return p end
	end
end

sgs.ai_skill_choice.sxzaoli = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"sxzaoli1")
	and self.player:getHandcardNum()/2<=self.player:getEquips():length()
	then return "sxzaoli1" end
end

sgs.ai_skill_invoke.sxfenyin = function(self,data)
	if self:canDraw() then
		return not self.player:isSkipped(sgs.Player_Play)
	end
end

sgs.ai_used_revises.sxfenyin = function(self,use)
	if self.player:getMark("sxfenyinUse-Clear")>0 and #self.toUse>1
	and self.player:getMark("&sxfenyin+:+"..use.card:getColorString().."-Clear")>0 then
		use.card = nil
	end
end

sgs.ai_skill_playerchosen.sxshuangren = function(self,players)
	local mc = self:getMaxCard()
	if mc and mc:getNumber()>9 or self:getCardsNum("Slash")<1
	then else return end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) then
			for _,q in sgs.list(self.enemies)do
				if p:distanceTo(q)==1 and self.player:canSlash(q,false) then
					return p
				end
			end
		end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) then
			for _,q in sgs.list(self.enemies)do
				if p:distanceTo(q)==1 and self.player:canSlash(q,false) then
					return p
				end
			end
		end
	end
end

sgs.ai_skill_playerschosen.sxshuangren = function(self,players)
	local tos = {}
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if #tos<2 and self:isEnemy(p) and self:slashIsEffective(dummyCard(),p) then
			table.insert(tos,p)
		end
	end
    for _,p in sgs.list(destlist)do
		if #tos<2 and not table.contains(tos,p)
		and not self:isFriend(p) and self:slashIsEffective(dummyCard(),p) then
			table.insert(tos,p)
		end
	end
	return tos
end

sgs.ai_fill_skill.sxmieji = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if c:getTypeId()==2 and c:isBlack() then
			return sgs.Card_Parse("#sxmiejiCard:"..c:toString()..":")
		end
	end
end

sgs.ai_skill_use_func["#sxmiejiCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self:doDisCard(p,"he",false,2) then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxmiejiCard = 3.4
sgs.ai_use_priority.sxmiejiCard = 2.2
sgs.ai_card_intention.sxmiejiCard = 66

sgs.ai_skill_playerchosen.sxjuece = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies<1
		and self:damageIsEffective(p)
		then return p end
	end
end

sgs.ai_fill_skill.sxlianji = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if c:getTypeId()==3 then
			local dc = dummyCard("collateral")
			dc:setSkillName("sxlianji")
			dc:addSubcard(c)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
end

sgs.ai_skill_invoke.sxzongji = function(self,data)
	local damage = data:toDamage()
	return self:doDisCard(damage.to,"he") or self:doDisCard(damage.from,"he")
end

sgs.ai_skill_playerchosen.sxyirang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		and sgs.getDefense(p)<sgs.getDefense(self.player)
		then return p end
	end
end

sgs.ai_fill_skill.sxjiaozhao = function(self)
	return sgs.Card_Parse("#sxjiaozhaoCard:.:")
end

sgs.ai_skill_use_func["#sxjiaozhaoCard"] = function(card,use,self)
	self:sort(self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>1 then
			use.to:append(p)
			use.card = card
			return
		end
	end
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if p:getHandcardNum()>1 and not self:isFriend(p) then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxjiaozhaoCard = 3.4
sgs.ai_use_priority.sxjiaozhaoCard = 7.2
sgs.ai_card_intention.sxjiaozhaoCard = 66

sgs.ai_skill_discard.sxjiaozhao1 = function(self,x,n)
	for _,c in ipairs(self:sortByKeepValue(self.player:getCards("he")))do
		return {c:getEffectiveId()}
	end
end

sgs.ai_skill_use["@@sxjiaozhao"] = function(self,prompt)
	self:sort(self.enemies,nil,true)
	for _,p in sgs.list(self.enemies)do
		if p:getHandcardNum()>1 then
			return "#sxjiaozhaoCard:.:->"..p:objectName()
		end
	end
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if p:getHandcardNum()>1 and not self:isFriend(p) then
			return "#sxjiaozhaoCard:.:->"..p:objectName()
		end
	end
end

sgs.ai_skill_invoke.sxpolu = function(self,data)
	local to = data:toPlayer()
	return self:doDisCard(to,"e")
end

sgs.ai_fill_skill.sxchoulve = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		local c,p = self:getCardNeedPlayer({h},false)
		if c and p then
			self.sxchoulveTo = p
			return sgs.Card_Parse("#sxchoulveCard:"..c:toString()..":")
		end
	end
end

sgs.ai_skill_use_func["#sxchoulveCard"] = function(card,use,self)
	if self.sxchoulveTo then
		use.to:append(self.sxchoulveTo)
		use.card = card
	end
end

sgs.ai_use_value.sxchoulveCard = 3.4
sgs.ai_use_priority.sxchoulveCard = 2.2
sgs.ai_card_intention.sxchoulveCard = -66

sgs.ai_skill_discard.sxchoulve = function(self,x,n)
	local cp = self.room:getCurrent()
	for _,c in ipairs(self:sortByKeepValue(self.player:getCards("he")))do
		if c:getTypeId()==3 and self:isFriend(cp) then return {c:getId()} end
	end
end

sgs.ai_fill_skill.sxfenxun = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByUseValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if c:isKindOf("Armor") then
			return sgs.Card_Parse("#sxfenxunCard:"..c:toString()..":")
		end
	end
end

sgs.ai_skill_use_func["#sxfenxunCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self:isWeak(p) and not self.player:inMyAttackRange(p)
		and self:getCardsNum("Slash")>0 and dummyCard():isAvailable(self.player)
		and self:slashIsEffective(dummyCard(),p,self.player) then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.sxfenxunCard = 3.4
sgs.ai_use_priority.sxfenxunCard = 2.2
sgs.ai_card_intention.sxfenxunCard = 66

sgs.ai_skill_playerchosen.sxzenhui = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		and sgs.getDefense(p)>sgs.getDefense(self.player)
		then return p end
	end
end

sgs.ai_skill_invoke.sxchuyi = function(self,data)
	local to = data:toPlayer()
	return self:isEnemy(to)
end

sgs.ai_skill_playerchosen.sxzhaoxin = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies<1
		and self:damageIsEffective(p)
		then return p end
	end
end


sgs.ai_fill_skill.sxxianlu = function(self)
	return sgs.Card_Parse("#sxxianluCard:.:")
end

sgs.ai_skill_use_func["#sxxianluCard"] = function(card,use,self)
	if self.player:containsTrick("indulgence") then
		self:sort(self.enemies)
		for _,p in sgs.list(self.enemies)do
			if self:doDisCard(p,"e") then
				use.to:append(p)
				use.card = card
				return
			end
		end
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if self:doDisCard(p,"e") then
				use.to:append(p)
				use.card = card
				return
			end
		end
	else
		self:sort(self.enemies)
		for _,p in sgs.list(self.enemies)do
			if self:doDisCard(p,"e") then
				use.to:append(p)
				use.card = card
				return
			end
		end
		for _,p in sgs.list(self.room:getAlivePlayers())do
			for _,e in sgs.list(p:getEquips())do
				if e:isBlack() and self:doDisCard(p,e:getId()) then
					use.to:append(p)
					use.card = card
					return
				end
			end
		end
		for _,p in sgs.list(self.room:getAlivePlayers())do
			if self:doDisCard(p,"e") and not self:isFriend(p) then
				use.to:append(p)
				use.card = card
				return
			end
		end
	end
end

sgs.ai_use_value.sxxianluCard = 3.4
sgs.ai_use_priority.sxxianluCard = 7.2
sgs.ai_card_intention.sxxianluCard = 66

sgs.ai_skill_playerchosen.sxcansi = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and (self:slashIsEffective(dummyCard(),p,self.player) or self:hasTrickEffective(dummyCard("duel"),p))
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		then return p end
	end
end

sgs.ai_fill_skill.sxmingshi = function(self)
	return sgs.Card_Parse("#sxmingshiCard:.:")
end

sgs.ai_skill_use_func["#sxmingshiCard"] = function(card,use,self)
	if #self.enemies>0 then
		use.card = card
	end
end

sgs.ai_use_value.sxmingshiCard = 3.4
sgs.ai_use_priority.sxmingshiCard = 7.2

sgs.ai_skill_choice.sxmingshi = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"sxmingshi2") and self:isWeak()
	then return "sxmingshi2" end
	if table.contains(items,"sxmingshi3") then
		for _,p in sgs.list(self.enemies)do
			if self:isWeak(p) and self:damageIsEffective(p) then
				return "sxmingshi3"
			end
		end
	end
	if table.contains(items,"sxmingshi1") and self:canDraw() and self:getOverflow()<1
	then return "sxmingshi1" end
	if table.contains(items,"sxmingshi4") and sgs.ai_skill_invoke.peiqi(self,data)
	then return "sxmingshi4" end
	if table.contains(items,"sxmingshi1")
	then return "sxmingshi1" end
end

sgs.ai_skill_playerchosen.sxmingshi3 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies<1
		and self:damageIsEffective(p)
		then return p end
	end
end

sgs.ai_skill_playerchosen["sxmingshi_from"] = function(self,players)
	for _,target in sgs.list(players)do
		if target==self.peiqiData.from
		then return target end
	end
end

sgs.ai_skill_playerchosen["sxmingshi_to"] = function(self,players)
	for _,target in sgs.list(players)do
		if target==self.peiqiData.to
		then return target end
	end
end

sgs.ai_skill_cardchosen.sxmingshi = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		if id==self.peiqiData.cid
		then return id end
	end
end

sgs.ai_skill_playerchosen.sxyizheng = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self.player:canPindian(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies<1
		and self.player:canPindian(p)
		then return p end
	end
end

sgs.ai_skill_playerchosen["sxrangjie"] = function(self,players)
	if sgs.ai_skill_invoke.peiqi(self) then
		for _,target in sgs.list(players)do
			if target==self.peiqiData.from
			then return target end
		end
	end
end

sgs.ai_skill_playerchosen["sxrangjie1"] = function(self,players)
	for _,target in sgs.list(players)do
		if target==self.peiqiData.to
		then return target end
	end
end

sgs.ai_skill_cardchosen.sxrangjie = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		if id==self.peiqiData.cid
		then return id end
	end
end

sgs.ai_fill_skill.sxzhitu = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c) then continue end
		for _,a in sgs.list(cards)do
			if c==a or table.contains(self.toUse,a) then continue end
			if c:getNumber()+a:getNumber()==13 then
				for _,cn in sgs.list(patterns())do
					local dc = dummyCard(cn,"sxzhitu")
					if dc and dc:isNDTrick() then
						dc:addSubcard(c)
						dc:addSubcard(a)
						if dc:isAvailable(self.player) and self:aiUseCard(dc).card
						then return dc end
					end
				end
			end
		end
	end
end

function sgs.ai_cardsview.sxzhitu(self,class_name,player)
	local cards = player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		for _,a in sgs.list(cards)do
			if c==a then continue end
			if c:getNumber()+a:getNumber()==13 then
				local dc = dummyCard(class_name,"sxzhitu")
				if dc then
					dc:addSubcard(c)
					dc:addSubcard(a)
					return dc
				end
			end
		end
	end
end

sgs.ai_skill_askforyiji.sxyimou = function(self,card_ids,tos)
    return sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
end

sgs.ai_skill_playerchosen.sxmutao = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p)
		and getCardsNum("Slash",p,self.player)>0
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies<1
		and self:damageIsEffective(p)
		and getCardsNum("Slash",p,self.player)>0
		then return p end
	end
    for _,p in sgs.list(sgs.reverse(destlist))do
		if self:isEnemy(p) and self:damageIsEffective(p)
		then return p end
	end
    for _,p in sgs.list(sgs.reverse(destlist))do
		if self:isEnemy(p) then return p end
	end
end

sgs.ai_skill_askforyiji.sxtaoluan = function(self,card_ids,tos)
    if self:isEnemy(tos:last()) and getCardsNum("Jink",tos:last(),self.player)>0 then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards) -- 按保留值排序
		return tos:last(),cards[1]:getId()
	end
end

sgs.ai_skill_playerchosen._zc_xuanhuafu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies<1
		then return p end
	end
end

sgs.ai_skill_invoke.zcjieji = function(self,data)
	local to = data:toPlayer()
	return self:doDisCard(to,"he",false) and self:getCardsNum("Jink")>0
end

sgs.ai_skill_use["@@zcruixi"] = function(self,prompt)
	for _,c in ipairs(self:sortByKeepValue(self.player:getCards("he")))do
      	local dc = dummyCard()
		dc:setSkillName("zcruixi")
		dc:addSubcard(c)
		if dc:isAvailable(self.player) then
			local dummy = self:aiUseCard(dc)
			if dummy.card then
				local tos = {}
				for _,p in sgs.list(dummy.to)do
					table.insert(tos,p:objectName())
				end
				return dc:toString().."->"..table.concat(tos,"+")
			end
		end
	end
end

sgs.ai_skill_invoke.zclianrong = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill.zcbizun = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c) or c:getTypeId()~=3 then continue end
		local dc = dummyCard(nil,"zcbizun")
		dc:addSubcard(c)
		if dc:isAvailable(self.player) and self:aiUseCard(dc).card
		then return dc end
	end
end

sgs.ai_view_as.zcbizun = function(card,player,card_place,class_name)
	if card:getTypeId()==3 and card_place~=sgs.Player_PlaceSpecial then
    	if class_name=="Jink" then
			return ("jink:zcbizun[no_suit:0]="..card:getEffectiveId())
		else
			return ("slash:zcbizun[no_suit:0]="..card:getEffectiveId())
		end
	end
end

sgs.ai_skill_discard.zcdechong = function(self,x,n)
	local cards = self:sortByKeepValue(self.player:getCards("he"))
	local cp = self.room:getCurrent()
	local c,p = self:getCardNeedPlayer(cards,false,{cp})
	if c and p then
		return {c:getEffectiveId()}
	end
	if self:isFriend(cp) then
		if self:isWeak(cp) then
			return {cards[#cards]:getEffectiveId()}
		end
	elseif self:getOverflow()>0 then
		return {cards[1]:getEffectiveId()}
	end
end

sgs.ai_fill_skill.zcyuanzhuo = function(self)
	return sgs.Card_Parse("#zcyuanzhuoCard:.:")
end

sgs.ai_skill_use_func["#zcyuanzhuoCard"] = function(card,use,self)
	local destlist = sgs.QList2Table(self.room:getAlivePlayers()) -- 将列表转换为表
	self:sort(destlist)
	for _,p in sgs.list(destlist)do
		if p~=self.player and self:doDisCard(p,"he") then
			use.to:append(p)
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.zcyuanzhuoCard = 3.4
sgs.ai_use_priority.zcyuanzhuoCard = 7.2

sgs.ai_skill_invoke.zcyuanzhuo = function(self,data)
	local tp = data:toPlayer()
	return not self:isFriend(tp)
end

sgs.ai_skill_use["@@zcwuwei"] = function(self,prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
	self:sort(self.friends_noself)
	for _,h in sgs.list(cards)do
		if h:getTypeId()==3 then
			for _,p in sgs.list(self.friends_noself)do
				if self.player:isProhibited(p,h) or #self:poisonCards({h},p)>0 then continue end
				return "#zcwuweiCard:"..h:toString()..":->"..p:objectName()
			end
			for _,p in sgs.list(self.enemies)do
				if self.player:isProhibited(p,h) or #self:poisonCards({h},p)<1 then continue end
				return "#zcwuweiCard:"..h:toString()..":->"..p:objectName()
			end
		end
	end
end

sgs.ai_skill_playerchosen.zcleiruo = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"he",false)
		then return p end
	end
end

sgs.ai_skill_invoke.zcleiruo = function(self,data)
	local tp = data:toPlayer()
	return not self:isFriend(tp)
end

sgs.ai_skill_playerschosen.zclijun = function(self,players,x)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tps = {}
    for _,p in sgs.list(destlist)do
		if #tps<x then table.insert(tps,p) end
	end
	return tps
end

sgs.ai_skill_invoke.zczhuying = function(self,data)
	local tp = data:toPlayer()
	return not self:isFriend(tp)
end







