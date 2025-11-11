sgs.ai_skill_discard.kelqchaojue = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	if #cards<3 then return {} end
	self:sortByKeepValue(cards)
	local to_cards = {}
   	for i,c in sgs.list(cards)do
		if i>=#to_cards/2 then
			if self:aiUseCard(c).card then continue end
			table.insert(to_cards,c:getEffectiveId())
			break
		end
	end
	return to_cards
end

sgs.ai_skill_discard.kelqchaojue_show = function(self,x,n,o,e,p)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_cards = {}
	local cp = self.room:getCurrent()
   	for i,c in sgs.list(cards)do
		if p:contains(c:getSuitString()) and not self:isEnemy(cp) then
			table.insert(to_cards,c:getEffectiveId())
			break
		end
	end
	return to_cards
end

local kelqjunshen={}
kelqjunshen.name="kelqjunshen"
table.insert(sgs.ai_skills,kelqjunshen)
kelqjunshen.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if h:isRed() then
			local slash = dummyCard()
			slash:setSkillName("kelqjunshen")
			slash:addSubcard(h)
			if slash:isAvailable(self.player) then
				return slash
			end
		end
	end
end

sgs.ai_view_as.kelqjunshen = function(card,player,card_place,class_name)
	if card_place==sgs.Player_PlaceSpecial then return end
	if card:isRed() then
    	return "slash:kelqjunshen[no_suit:0]="..card:getEffectiveId()
	end
end

sgs.ai_skill_choice.kelqjunshen = function(self,choices)
	local items = choices:split("+")
	if table.contains(items,"qizhi") then
		if self.player:getEquips():length()<3 or self:isWeak() or self.player:getEquips():length()/2<=#self:poisonCards("e") then
			return "qizhi"
		end
	end
	return items[2]
end

sgs.ai_skill_use["@@kelqlizhong"] = function(self,prompt)
	local valid,tos = {},{}
	local players = self.player:getAliveSiblings()
    players = self:sort(players)
	if self.player:getMark("kelqlizhong1")~=1 then
		local cards = self.player:getCards("he")
		cards = self:sortByKeepValue(cards) -- 按保留值排序
		for _,h in sgs.list(cards)do
			if h:getTypeId()==3 then
				local n = h:getRealCard():toEquipCard():location()
				for _,p in sgs.list(players)do
					if table.contains(tos,p:objectName()) then continue end
					if p:hasEquipArea(n) and p:getEquip(n)==nil then
						if #self:poisonCards({h})>0 then
							if self:isEnemy(p) or not self:isFriend(p) and #self.enemies<1 then
								table.insert(valid,h:getEffectiveId())
								table.insert(tos,p:objectName())
								break
							end
						elseif self:isFriend(p) then
							table.insert(valid,h:getEffectiveId())
							table.insert(tos,p:objectName())
							break
						end
					end
				end
			end
		end
		if #tos<1 then
			if self.player:getMark("kelqlizhong1")==2 then return end
			for _,p in sgs.list(players)do
				if self:isFriend(p) and p:hasEquip()
				then table.insert(tos,p:objectName()) end
			end
		end
		if #tos<1 then table.insert(tos,self.player:objectName()) end
	else
		for _,p in sgs.list(players)do
			if self:isFriend(p) and p:hasEquip()
			then table.insert(tos,p:objectName()) end
		end
		if #tos<1 then table.insert(tos,self.player:objectName()) end
	end
	if #tos<1 then return end
	return string.format("#kelqlizhongcard:%s:->%s",table.concat(valid,"+"),table.concat(tos,"+"))
end

sgs.ai_view_as.kelqlizhongUse = function(card,player,card_place,class_name)
	if card_place~=sgs.Player_PlaceEquip then return end
   	return "nullification:_kelqlizhong[no_suit:0]="..card:getEffectiveId()
end

sgs.ai_skill_invoke.kelqjuesui = function(self,data)
	local target = data:toPlayer()
	if target then
		return self:isFriend(target)
		or not self:isEnemy(target) and #self.enemies>=#self.friends
	else
		return true
	end
end


local kelqjuesuiUse={}
kelqjuesuiUse.name="kelqjuesuiUse"
table.insert(sgs.ai_skills,kelqjuesuiUse)
kelqjuesuiUse.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if h:isBlack() and h:getTypeId()>1 then
			local slash = dummyCard()
			slash:setSkillName("_kelqjuesui")
			slash:addSubcard(h)
			if slash:isAvailable(self.player) then
				return slash
			end
		end
	end
end

sgs.ai_view_as.kelqjuesuiUse = function(card,player,card_place,class_name)
	if card_place==sgs.Player_PlaceSpecial then return end
	if card:isRed() and card:getTypeId()>1 then
    	return "slash:_kelqjuesui[no_suit:0]="..card:getEffectiveId()
	end
end

sgs.ai_target_revises.kelqjuwu = function(to,card,self)
    if card:objectName()=="slash" then
		local num = 0
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if self.player:inMyAttackRange(p) then
				num = num + 1
			end
		end
		if num>=3
		then return true end
	end
end

sgs.ai_skill_invoke.kelqshouxiang = function(self,data)
	local numt = 0
	for _, p in sgs.qlist(self.room:getAllPlayers()) do
		if p:inMyAttackRange(self.player) then
			numt = numt + 1
		end
	end
	if numt>1 then
		return #self:getTurnUse()<2
	end
end

sgs.ai_skill_use["@@kelqshouxiang"] = function(self,prompt)
	local valid,tos = {},{}
    self:sort(self.friends_noself,nil,true)
	local n = self.player:getMark("kelqshouxiangNum")
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards) -- 按保留值排序
	if #self.friends_noself<2 then
		local players = self.player:getAliveSiblings()
		players = self:sort(players,nil,true)
		for _,h in sgs.list(cards)do
			for _,p in sgs.list(players)do
				if table.contains(tos,p:objectName()) or #tos>=n then continue end
				if self:isFriend(p) or not self:isEnemy(p) and #self.enemies>0 then
					table.insert(valid,h:getEffectiveId())
					table.insert(tos,p:objectName())
					break
				end
			end
		end
	else
		for _,h in sgs.list(cards)do
			for _,p in sgs.list(self.friends_noself)do
				if table.contains(tos,p:objectName()) or #tos>=n then continue end
				table.insert(valid,h:getEffectiveId())
				table.insert(tos,p:objectName())
				break
			end
		end
	end
	if #tos<1 then return end
	return string.format("#kelqshouxiangcard:%s:->%s",table.concat(valid,"+"),table.concat(tos,"+"))
end









sgs.ai_fill_skill.tywusheng = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		if table.contains(self.toUse,c)
		or not c:isRed()
		then continue end
		local dc = dummyCard()
		dc:setSkillName("tywusheng")
		dc:addSubcard(c)
		if dc:isAvailable(self.player)
		then return dc end
	end
end

sgs.ai_view_as.tywusheng = function(card,player,card_place,class_name)
	if card:isRed() and card_place~=sgs.Player_PlaceSpecial then
    	return ("slash:tywusheng[no_suit:0]="..card:getEffectiveId())
	end
end

sgs.ai_skill_discard.tyfuwei = function(self,x,n)
	local damage = sgs.filterData[sgs.Damage]:toDamage()
	if not self:isFriend(damage.to) then return {} end
	local cards = {}
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if #cards>2 or #cards>#handcards/2 or #cards>=x then break end
		table.insert(cards,h:getEffectiveId())
	end
	return cards
end

sgs.ai_skill_invoke.tyfuhan1 = function(self,data)
	local target = data:toPlayer()
	if target then
		return not self:isFriend(target)
	end
end

sgs.ai_skill_invoke.tyfuhan2 = function(self,data)
	local target = data:toPlayer()
	if target then
		return self:isFriend(target)
	end
end

sgs.ai_fill_skill.tychende = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local ids = {}
	for _,c in sgs.list(cards)do
		if c:isKindOf("BasicCard") or c:isNDTrick() then
			local dc = dummyCard(c:objectName())
			if self:aiUseCard(dc).card then
				table.insert(ids,c:getId())
			end
		end
	end
	for _,c in sgs.list(cards)do
		if #ids==1 and not table.contains(ids,c:getId()) then
			table.insert(ids,c:getId())
		end
	end
	self.tychendeTo = nil
	if #ids>1 then return sgs.Card_Parse("#tychendeCard:"..table.concat(ids,"+")..":") end
	ids = {}
	local tp
	for _,h in sgs.list(cards)do
		if not table.contains(self.toUse,h) then
			local c,p = self:getCardNeedPlayer({h})
			if c and p then
				table.insert(ids,c:getId())
				if tp==p and #ids>1 then
					self.tychendeTo = p
					return sgs.Card_Parse("#tychendeCard:"..table.concat(ids,"+")..":")
				end
				tp = p
			end
		end
	end
end

sgs.ai_skill_use_func["#tychendeCard"] = function(card,use,self)
	if self.tychendeTo then
		use.card = card
		use.to:append(self.tychendeTo)
		return
	end
	self:sort(self.friends_noself,"card")
	for _,p in sgs.list(self.friends_noself)do
		if self:canDraw(p) then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.tychendeCard = 3.4
sgs.ai_use_priority.tychendeCard = 11.2

sgs.ai_skill_askforag.tychende = function(self,card_ids)
    local cards = {}
	for _,id in sgs.list(card_ids)do
		table.insert(cards,sgs.Sanguosha:getCard(id))
	end
	self:sortByUsePriority(cards)
	for _,c in sgs.list(cards)do
		local dc = dummyCard(c:objectName())
		dc:setSkillName("_tychende")
		local d = self:aiUseCard(dc)
		if d.card then
			if c:canRecast() and d.to:isEmpty() then continue end
			self.tychendeUse = d
			return c:getId()
		end
	end
	return -1
end

sgs.ai_skill_use["@@tychende"] = function(self,prompt)
    local d = self.tychendeUse
   	if d.card then
      	local tos = {}
       	for _,p in sgs.list(d.to)do
       		table.insert(tos,p:objectName())
       	end
       	return d.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_playerchosen.tysheju = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"e")
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if self:doDisCard(target,"he")
		and not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_invoke.tyxiyu = function(self,data)
	return self:canDraw()
end

sgs.ai_fill_skill.tyxingsha = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	local ids = {}
	local m = self:getOverflow()
	for _,c in sgs.list(cards)do
		table.insert(ids,c:getId())
		if #ids>1 then return sgs.Card_Parse("#tyxingshaCard:"..table.concat(ids,"+")..":") end
		if #ids>=m then break end
	end
	if #ids>0 then return sgs.Card_Parse("#tyxingshaCard:"..table.concat(ids,"+")..":") end
end

sgs.ai_skill_use_func["#tyxingshaCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.tyxingshaCard = 3.4
sgs.ai_use_priority.tyxingshaCard = -3.2

sgs.ai_fill_skill.ty2chengshi = function(self)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,c in sgs.list(cards)do
		local dc = dummyCard()
		dc:setSkillName("ty2chengshi")
		dc:addSubcard(card:getEffectiveId())
		if c:isRed() and dc:isAvailable(self.player) then
			return sgs.Card_Parse("#ty2chengshicard:"..c:getId()..":")
		end
	end
end

sgs.ai_skill_use_func["#tyxingshaCard"] = function(card,use,self)
	local dc = dummyCard()
	dc:setSkillName("ty2chengshi")
	dc:addSubcard(card:getEffectiveId())
	local d = self:aiUseCard(dc,dummy(nil,99))
	if d.card then
		for _,p in sgs.list(d.to)do
			if p:getMark("&ty2chengshi+#"..self.player:objectName().."_lun")>0 then
				use.card = card
				use.to:append(p)
				break
			end
		end
	end
end

sgs.ai_use_value.ty2chengshicard = 3.4
sgs.ai_use_priority.ty2chengshicard = 1.2

sgs.ai_skill_use["@@tyxingsha"] = function(self,prompt)
    local ids = self.player:getPile("tyyuan")
	for i,id1 in sgs.list(ids)do
		for n,id2 in sgs.list(ids)do
			if i<n then
				local dc = dummyCard()
				dc:setSkillName("tyxingsha")
				dc:addSubcard(id1)
				dc:addSubcard(id2)
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
end

sgs.ai_skill_invoke.tybianwo = function(self,data)
	return true
end

sgs.ai_skill_use["@@tybianwo"] = function(self,prompt)
    local id = self.player:getMark("tybianwoId")
	local dc = sgs.Sanguosha:getCard(id)
	local d = self:aiUseCard(dc)
	if d.card then
		local tos = {}
		for _,p in sgs.list(d.to)do
			table.insert(tos,p:objectName())
		end
		if dc:canRecast() and #tos<1 then return end
		return dc:toString().."->"..table.concat(tos,"+")
	end
end

sgs.ai_skill_playerchosen.tyxianshou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and p:isWounded()
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_skill_playerchosen.tybenxiang = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_skill_invoke.tyzhongen = function(self,data)
	local to = data:toPlayer()
	if self:isFriend(to) and self:canDraw(to) then
		return true
	end
	return #self.enemies>0
end

sgs.ai_skill_choice.tyzhongen = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"tyzhongen1") then
		local to = data:toPlayer()
		if self:isFriend(to) and self:canDraw(to) then
			return "tyzhongen1"
		end
	end
	if table.contains(items,"tyzhongen2")
	then return "tyzhongen2" end
end

sgs.ai_skill_invoke.tyliebao = function(self,data)
	local to = data:toPlayer()
	if self:isFriend(to) and self:isWeak(to) then
		return not self:isWeak() or self:getCard("Jink")~=nil
	end
end

sgs.ai_skill_invoke.tyfenwu = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_choice.tyfenwu = function(self,choices,data)
	local items = choices:split("+")
	local id = self.player:getMark("tyfenwuId")
    for _,pn in sgs.list(items)do
		if pn=="cancel" then return pn end
		local dc = dummyCard(pn)
		dc:setSkillName("_tyfenwu")
		dc:addSubcard(id)
		if dc:isAvailable(self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				self.tyfenwuUse = d
				return pn
			end
		end
	end
end

sgs.ai_skill_use["@@tyfenwu"] = function(self,prompt)
    local d = self.tyfenwuUse
   	if d.card then
      	local tos = {}
       	for _,p in sgs.list(d.to)do
       		table.insert(tos,p:objectName())
       	end
       	return d.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_invoke.tyqingkou = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_choice.tyqingkou = function(self,choices,data)
	local items = choices:split("+")
	local id = self.player:getMark("tyqingkouId")
    for _,pn in sgs.list(items)do
		if pn=="cancel" then return pn end
		local dc = dummyCard(pn)
		dc:setSkillName("_tyqingkou")
		dc:addSubcard(id)
		if dc:isAvailable(self.player) then
			local d = self:aiUseCard(dc)
			if d.card then
				if dc:canRecast() and d.to:isEmpty() then continue end
				self.tyqingkouUse = d
				return pn
			end
		end
	end
end

sgs.ai_skill_use["@@tyqingkou"] = function(self,prompt)
    local d = self.tyqingkouUse
   	if d.card then
      	local tos = {}
       	for _,p in sgs.list(d.to)do
       		table.insert(tos,p:objectName())
       	end
       	return d.card:toString().."->"..table.concat(tos,"+")
    end
end

sgs.ai_skill_invoke.tyyuantao = function(self,data)
	local use = data:toCardUse()
	return self:isFriend(use.from) and not self:isWeak()
	and (use.card:isDamageCard() or use.from:getLostHp()>1 and use.to:contains(use.from))
end

sgs.ai_skill_cardask.tychonglong1 = function(self,data,pattern,prompt)
	local damage = data:toDamage()
    if self:isEnemy(damage.to)
	and self:isWeak(damage.to)
	then return true end
	return "."
end

sgs.ai_skill_cardask.tychonglong0 = function(self,data,pattern,prompt)
	local use = data:toCardUse()
    if self:isEnemy(use.to:first())
	and not self:isEnemy(use.from)
	then return true end
	return "."
end

sgs.ai_skill_invoke.tychonglong = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_cardask.tyqianshou0 = function(self,data,pattern,prompt)
	local to = data:toPlayer()
    if self:isEnemy(to)
	and (self:isWeak(to) or to:inMyAttackRange(self.player) and self:isWeak())
	then return true end
	return "."
end

sgs.ai_skill_invoke.tyqianshou = function(self,data)
	local to = data:toPlayer()
	return self:canDraw() and not self:isWeak()
end

sgs.ai_fill_skill.tytanlong = function(self)
	return sgs.Card_Parse("#tytanlongCard:.:")
end

sgs.ai_skill_use_func["#tytanlongCard"] = function(card,use,self)
	self:sort(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if self.player:getHandcardNum()>ep:getHandcardNum() and self.player:canPindian(ep) then
			use.card = card
			use.to:append(ep)
			break
		end
	end
end

sgs.ai_use_value.tytanlongCard = 3.4
sgs.ai_use_priority.tytanlongCard = 3.2

sgs.ai_skill_invoke.tytanlong = function(self,data)
	local c = data:toCard()
	return self:canDraw() and #self:poisonCards({c})<1
end

sgs.ai_skill_invoke.tyxibei = function(self,data)
	return self:canDraw()
end

sgs.ai_skill_cardask.tyxibei0 = function(self,data,pattern,prompt)
    if #self.enemies>0
	then return true end
	return "."
end

function SmartAI:useCardHuoshaolianyingTy(card,use)
	self:sort(self.enemies)
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if CanToCard(card,self.player,ep,use.to) and self:hasTrickEffective(card,ep,self.player)
		and self:ajustDamage(self.player,ep,1,card,"F")~=0 then
	    	use.card = card
	    	use.to:append(ep)
		end
	end
	if self:getOverflow()>1 then
		local tos = self:sort(self.room:getAlivePlayers(),nil,true)
		for _,ep in sgs.list(tos)do
			if isCurrent(use,ep) or self:isFriend(ep) then continue end
			if CanToCard(card,self.player,ep,use.to) and self:hasTrickEffective(card,ep,self.player)
			and self:ajustDamage(self.player,ep,1,card,"F")~=0 then
				use.card = card
				use.to:append(ep)
			end
		end
	end
end
sgs.ai_use_priority.HuoshaolianyingTy = 3.5
sgs.ai_keep_value.HuoshaolianyingTy = 2
sgs.ai_use_value.HuoshaolianyingTy = 3.7

sgs.ai_skill_cardask._tyhuoshaolianying0 = function(self,data,pattern,prompt)
	local effect = data:toCardEffect()
	if self:ajustDamage(self.player,effect.to,1,effect.card,"F")==0
	then return "." end
    if self:isFriend(effect.to) then
		return effect.to:isChained() and self:isGoodChainTarget(effect.to,"F")
	elseif effect.to:isChained() then
		return self:isGoodChainTarget(effect.to,"F")
	else
		return true
	end
	return "."
end

sgs.ai_nullification.HuoshaolianyingTy = function(self,trick,from,to,positive)
    return self:isFriend(to) and positive
end

sgs.ai_card_intention.HuoshaolianyingTy = 77

sgs.ai_skill_playerschosen.tyqingshi = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isFriend(p) and p:getHandcardNum()>0
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and not self:isEnemy(p) and p:getHandcardNum()>0
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_use["@@tyqingshi"] = function(self,prompt)
	local ids,tos = {},{}
	local aps = {}
    for _,p in sgs.list(self.room:getOtherPlayers(self.player))do
      	if p:hasFlag("tyqingshiBlack") then table.insert(aps,p) end
	end
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		local c,p = self:getCardNeedPlayer({h},false,aps)
		if c and p then
			table.insert(ids,c:getId())
			table.insert(tos,p:objectName())
			table.removeOne(aps,p)
		end
	end
	if #ids<1 then return end
	return string.format("#tyqingshiCard:%s:->%s",table.concat(ids,"+"),table.concat(tos,"+"))
end

sgs.ai_skill_invoke.tyyilin = function(self,data)
	local move = data:toMoveOneTime()
	local to = BeMan(self.room,move.to)
	return self:isFriend(to)
end

sgs.ai_skill_playerchosen.tychengming = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:isFriend(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isEnemy(p)
		then return p end
	end
end

sgs.ai_skill_invoke.tymanyong = function(self,data)
	return #self.enemies>0 and self:canDraw()
end

sgs.ai_skill_invoke._tytiejiliguduo = function(self,data)
	return self.player:getHp()>2 and self.player:getHandcardNum()>=self.player:getHp()
end

sgs.ai_skill_invoke.tyyizhuang = function(self,data)
	return self:doDisCard(self.player,"j") and not self:isWeak()
end

sgs.ai_skill_discard.tysiji = function(self,x,n,o,e,p)
	local to = self.room:getCurrent()
	if not self:isEnemy(to) then return {} end
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
	local dc = dummyCard("yj_stabs_slash")
	dc:setSkillName("tysiji")
   	for _,h in sgs.list(handcards)do
		dc:addSubcard(h)
		if self.player:canSlash(to,dc,false) and self:hasTrickEffective(dc,to) then
			return {h:getId()}
		end
		dc:clearSubcards()
	end
	return {}
end

sgs.ai_skill_discard.tydaifa = function(self,x,n,o,e,p)
	local to = self.room:getCurrent()
	if not self:isEnemy(to) then return {} end
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
	local dc = dummyCard("yj_stabs_slash")
	dc:setSkillName("tydaifa")
   	for _,h in sgs.list(handcards)do
		dc:addSubcard(h)
		if self.player:canSlash(to,dc,false) and self:hasTrickEffective(dc,to) then
			return {h:getId()}
		end
		dc:clearSubcards()
	end
	return {}
end

sgs.ai_skill_discard.tyansha = function(self,x,n,o,e,p)
	local to = self.room:getCurrent()
	if not self:isEnemy(to) then return {} end
    local handcards = sgs.QList2Table(self.player:getCards("he"))
    self:sortByKeepValue(handcards) -- 按保留值排序
	local dc = dummyCard("yj_stabs_slash")
	dc:setSkillName("tyansha")
   	for _,h in sgs.list(handcards)do
		dc:addSubcard(h)
		if self.player:canSlash(to,dc) and self:hasTrickEffective(dc,to) then
			return {h:getId()}
		end
		dc:clearSubcards()
	end
	return {}
end

sgs.ai_skill_discard.tyxihun = function(self,x,n)
    local handcards = sgs.QList2Table(self.player:getCards("h"))
	if not self:isWeak() and #handcards<4 then return {} end
	local cards = {}
    self:sortByKeepValue(handcards) -- 按保留值排序
   	for _,h in sgs.list(handcards)do
		if #cards>1 then break end
		table.insert(cards,h:getEffectiveId())
	end
	return cards
end

sgs.ai_fill_skill.tyxianqivs = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards,nil,"j") -- 按保留值排序
	local ids = {}
	for _,h in sgs.list(cards)do
		if table.contains(self.toUse,h) then continue end
		table.insert(ids,h:getId())
		if #ids>1 and self:getOverflow()>0 then
			return sgs.Card_Parse("#tyxianqicard:"..table.concat(ids,"+")..":")
		end
	end
	return not self:isWeak()
	and sgs.Card_Parse("#tyxianqicard:.:")
end

sgs.ai_skill_use_func["#tyxianqicard"] = function(card,use,self)
	for _,p in sgs.list(self.enemies)do
		if p:hasSkill("tyxianqi") and self:ajustDamage(self.player,p,1)~=0 then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.tyxianqicard = 3.4
sgs.ai_use_priority.tyxianqicard = 0.2


