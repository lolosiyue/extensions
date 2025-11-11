--郭嘉
sgs.ai_skill_playerschosen.kezhuanqingzi = function(self, targets)
	targets = sgs.QList2Table(targets)
	local tos = {}
	for _, p in ipairs(targets) do
		if self:doDisCard(p,"e") then
			table.insert(tos,p)
		end
	end
	return tos
end

sgs.ai_skill_invoke.kezhuandingce = function(self, data)
	local from = data:toPlayer()
	if from==self.player then
		return from:getHandcardNum() >= 4
	elseif self:isFriend(from) then
		return from:getHandcardNum()>from:getHp()
	else
		return true
	end
end

sgs.ai_skill_cardchosen.kezhuandingce = function(self,who)
	local player = self.player
	if who:hasFlag("bestdingcered") then
		for _,c in sgs.qlist(who:getCards("h")) do
			if c:isRed() then
				return c:getId()
			end
		end
	else
		for _,c in sgs.qlist(who:getCards("h")) do
			if c:isBlack() then
				return c:getId()
			end
		end
	end
	return -1
end

local kezhuanzhenfeng={}
kezhuanzhenfeng.name="kezhuanzhenfeng"
table.insert(sgs.ai_skills,kezhuanzhenfeng)
kezhuanzhenfeng.getTurnUseCard = function(self)
	for _,p in sgs.list(zhuanJfNames(self.player))do
		local dc = zhuandummyCard(p)
		dc:setSkillName("kezhuanzhenfeng")
		if dc:isKindOf("Dongzhuxianji") and self.player:hasSkill("kezhuandingce",true)
		and self:isWeak() or not dc:isAvailable(self.player) then continue end
		local dummy = self:aiUseCard(dc)
		if dummy.card and dummy.to then
			self.kezhuanzhenfengData = dummy
			sgs.ai_skill_choice.kezhuanzhenfeng = choice
			if (dummy.to:isEmpty() and dc:canRecast())  then continue end
			sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
			return sgs.Card_Parse("#kezhuanzhenfengCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#kezhuanzhenfengCard"] = function(card,use,self)
   	use.card = card
end

sgs.ai_use_value.kezhuanzhenfengCard = 6.4
sgs.ai_use_priority.kezhuanzhenfengCard = 6.4

sgs.ai_skill_use["@@kezhuanzhenfeng"] = function(self,prompt)
	local dummy = self.kezhuanzhenfengData
	if dummy.card and dummy.to then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return dummy.card:toString().."->"..table.concat(tos,"+")
	end
end


--张任
sgs.ai_skill_askforyiji.kezhuanfuni = function(self,card_ids,tos)
	local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to and id then return to,id end
	for _,p in sgs.list(tos)do
		if not self:isFriend(p)
		and not p:hasFlag("kezhuanfuniAi") then
			p:setFlags("kezhuanfuniAi")
			return p,card_ids[1]
		end
	end
	return tos:first(),card_ids[1]
end
sgs.hit_skill = sgs.hit_skill .. "|kezhuanfuni"

sgs.ai_skill_use["@@kezhuanchuanxin"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
    	local c = zhuandummyCard()
		c:setSkillName("kezhuanchuanxin")
		c:addSubcard(h)
		if self.player:isLocked(c) then continue end
		local dummy = self:aiUseCard(c)
		if dummy.card then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			return c:toString().."->"..table.concat(tos,"+")
			--return "#kezhuanchuanxinCard:"..h:getId()..":->"..table.concat(tos,"+")
		end
	end
end

sgs.ai_ajustdamage_from.kezhuanchuanxin = function(self,from,to,card,nature)
	if card and card:getSkillName() == "kezhuanchuanxin"
	then return to:getMark("kezhuanchuanxin-Clear") end
end
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|kezhuanchuanxin"

--马超

sgs.ai_skill_invoke.kezhuanzhuiming = function(self, data)
	local to = data:toPlayer()
	return self:isEnemy(to)
	or not self:isFriend(to) and #self.enemies>0
end

sgs.ai_skill_choice.kezhuanzhuiming = function(self, choices, data)
	local items = choices:split("+")
	local to = data:toPlayer()
	kezhuanzhuimingColor = items[1]
	for _,h in sgs.list(getKnownCards(to,self.player,"he"))do
		if choices:contains(h:getColorString()) then
			kezhuanzhuimingColor = h:getColorString()
			return h:getColorString()
		end
	end
	return items[1]
end


sgs.ai_skill_cardchosen.kezhuanzhuiming = function(self,who)
	for _,h in sgs.list(getKnownCards(who,self.player,"he"))do
		if h:getColorString()==kezhuanzhuimingColor then
			return h:getId()
		end
	end
end

sgs.ai_skill_discard.kezhuanzhuiming = function(self) 
	local to_discard = {}	
	if self.player:getHp()+self:getCardsNum("Peach,Analeptic")<3 then
		local from = self.player:getTag("kezhuanzhuimingFrom"):toPlayer()
		for _,h in sgs.list(getKnownCards(self.player,from,"he"))do
			if h:getColorString()==kezhuanzhuimingColor then
				table.insert(to_discard, h:getEffectiveId())
			end
		end
	end
	return to_discard
end

sgs.ai_choicemade_filter.skillInvoke.kezhuanzhuiming = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end
sgs.hit_skill = sgs.hit_skill .. "|kezhuanzhuiming"
sgs.ai_cardneed.kezhuanzhuiming = sgs.ai_cardneed.slash


--张飞

sgs.ai_skill_discard.kezhuanbaohe = function(self) 
	local to_discard = {}
	local who = self.player:getTag("kezhuanbaoheWho"):toPlayer()
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("kezhuanbaohe")
	slash:deleteLater()
	local x = 0
	for _, pp in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if pp:inMyAttackRange(who) and self.player:canSlash(pp,slash,false) then
			if self:isFriend(pp) then
				x = x-1
				if self:isWeak(pp) then
					x = x-1
				end
			else
				x = x+1
				if self:isEnemy(pp) and self:isWeak(pp) then
					x = x+1
				end
			end
		end	
	end
	if x>1 then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards,nil,"j")
		if #cards<2 then return to_discard end
		table.insert(to_discard, cards[1]:getEffectiveId())
		table.insert(to_discard, cards[2]:getEffectiveId())
	end
	return to_discard
end

local kezhuanxushi_skill = {}
kezhuanxushi_skill.name = "kezhuanxushi"
table.insert(sgs.ai_skills, kezhuanxushi_skill)
kezhuanxushi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kezhuanxushiCard") then return end
	return sgs.Card_Parse("#kezhuanxushiCard:.:")
end

sgs.ai_skill_use_func["#kezhuanxushiCard"] = function(card, use, self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, c in ipairs(self.toUse) do
		table.removeOne(cards, c)
	end
	local ids = {}
	for _,c in ipairs(self:poisonCards(cards))do
		if c:getTypeId()>2 then
			for _,p in ipairs(self.friends_noself)do
				if use.to:contains(p) then continue end
				table.insert(ids, c:getId())
				use.to:append(p)
				break
			end
		else
			for _,p in ipairs(self.enemies)do
				if use.to:contains(p) then continue end
				table.insert(ids, c:getId())
				use.to:append(p)
				break
			end
		end
	end
	if #ids<#self.friends_noself then
		for _,c in ipairs(cards)do
			for _,p in ipairs(self.friends_noself)do
				if use.to:contains(p) or #ids>#cards/2 or table.contains(ids, c:getId()) then continue end
				table.insert(ids, c:getId())
				use.to:append(p)
				break
			end
		end
	end
	if #ids>0 then
		use.card = sgs.Card_Parse("#kezhuanxushiCard:"..table.concat(ids,"+")..":")
	end
end

sgs.ai_ajustdamage_from.kezhuanbaohe = function(self,from,to,card,nature)
	if card and card:getSkillName() == "kezhuanbaohe"
	then return card:getTag("kezhuanbaoheda"):toInt() end
end
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|kezhuanbaohe"

--夏侯荣

sgs.ai_skill_invoke.kezhuanfenjian = function(self, data)
	local to = data:toPlayer()
	return self:isFriend(to)
end

local kezhuanfenjian_skill = {}
kezhuanfenjian_skill.name = "kezhuanfenjian"
table.insert(sgs.ai_skills, kezhuanfenjian_skill)
kezhuanfenjian_skill.getTurnUseCard = function(self)
	--if self.player:hasUsed("kezhuanfenjianCard") then return end
	local duel = sgs.Sanguosha:cloneCard("duel")
	duel:setSkillName("kezhuanfenjian")
	duel:deleteLater()
	return duel--sgs.Card_Parse("#kezhuanfenjianCard:.:")
end

sgs.ai_skill_use_func["#kezhuanfenjianCard"] = function(card, use, self)
    if not self.player:hasUsed("#kezhuanfenjianCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if enys:isEmpty() then
				enys:append(enemy)
			else
				local yes = 1
				for _,p in sgs.qlist(enys) do
					if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) >= (p:getHp()+p:getHp()+p:getHandcardNum()) then
						yes = 0
					end
				end
				if (yes == 1) then
					enys:removeOne(enys:at(0))
					enys:append(enemy)
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			local yes = 1
			if (self.player:getHp() <= 2) and (self.player:getHandcardNum() < 2) 
			and (enemy:getHp() > 1) and (enemy:getHandcardNum() > 2) then
				yes = 0
			end
			if (self:objectiveLevel(enemy) > 0) and (yes == 1) then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.kezhuanfenjianCard = 8.5
sgs.ai_use_priority.kezhuanfenjianCard = 9.5
sgs.ai_card_intention.kezhuanfenjianCard = 80

sgs.ai_ajustdamage_to.kezhuanfenjian = function(self,from,to,card,nature)
	if to then return to:getMark("&kezhuanfenjian+:+peach-Clear")+to:getMark("&kezhuanfenjian+:+duel-Clear") end
end

local kezhuanguiji_skill = {}
kezhuanguiji_skill.name = "kezhuanguiji"
table.insert(sgs.ai_skills, kezhuanguiji_skill)
kezhuanguiji_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#kezhuanguijiCard") or self.player:getMark("usekezhuanguiji") > 0 then return end
	return sgs.Card_Parse("#kezhuanguijiCard:.:")
end

sgs.ai_skill_use_func["#kezhuanguijiCard"] = function(card, use, self)
    self:sort(self.friends_noself,nil,true)
	local x = self:getCardsNum("KezhuanYing")
	for _, p in ipairs(self.friends_noself) do
		if p:getHandcardNum()<self.player:getHandcardNum()
		and p:getHandcardNum()<=self.player:getHandcardNum()-x and p:getHandcardNum()>1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _, p in ipairs(self.friends_noself) do
		if p:getHandcardNum()<self.player:getHandcardNum() and p:getHandcardNum()>1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	self:sort(self.enemies,nil,true)
	for _, p in ipairs(self.enemies) do
		if p:getHandcardNum()<self.player:getHandcardNum() and p:getHandcardNum()>=x then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_skill_invoke.kezhuanguiji = function(self, data)
	local to = data:toPlayer()
	return to:getHandcardNum()>self.player:getHandcardNum()
	or self:isFriend(to) and self:isWeak(to)
end

local kezhuanjiaohaoex = {}
kezhuanjiaohaoex.name = "kezhuanjiaohaoex"
table.insert(sgs.ai_skills, kezhuanjiaohaoex)
kezhuanjiaohaoex.getTurnUseCard = function(self)
	return sgs.Card_Parse("#kezhuanjiaohaoCard:.:")
end

sgs.ai_skill_use_func["#kezhuanjiaohaoCard"] = function(card, use, self)
    self:sort(self.friends_noself)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, p in ipairs(self.friends_noself) do
		if (#cards>self.player:getHp() or self:isWeak(p)) and p:hasSkill("kezhuanjiaohao") then
			for _, h in ipairs(cards) do
				if h:getTypeId()<3 or #self:poisonCards({h},p)>0 then
					continue
				end
				local equip = h:getRealCard():toEquipCard()
				local equip_index = equip:location()
				if p:getEquip(equip_index) == nil then
					use.card = sgs.Card_Parse("#kezhuanjiaohaoCard:"..h:getId()..":")
					use.to:append(p)
					return
				end
			end
		end
	end
	for _, p in ipairs(self.enemies) do
		if (#cards>=self.player:getHp() or self:isWeak(p)) and p:hasSkill("kezhuanjiaohao") then
			for _, h in ipairs(cards) do
				if h:getTypeId()<3 or #self:poisonCards({h},p)<1 then
					continue
				end
				local equip = h:getRealCard():toEquipCard()
				local equip_index = equip:location()
				if p:getEquip(equip_index) == nil then
					use.card = sgs.Card_Parse("#kezhuanjiaohaoCard:"..h:getId()..":")
					use.to:append(p)
					return
				end
			end
		end
	end
end


--[[local kezhuanjiaohaoex_skill = {}
kezhuanjiaohaoex_skill.name = "kezhuanjiaohaoex"
table.insert(sgs.ai_skills, kezhuanjiaohaoex_skill)
kezhuanjiaohaoex_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kezhuanjiaohaoCard") then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = sgs.IntList()
	for _, acard in ipairs(cards) do
		if acard:isKindOf("EquipCard") then
			to_throw:append(acard:getEffectiveId())
		end
	end
	card_id = to_throw:at(0)
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("#kezhuanjiaohaoCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#kezhuanjiaohaoCard"] = function(card, use, self)
    if (not self.player:hasUsed("#kezhuanjiaohaoCard")) then
		self:sort(self.friends)
		local num = 0
		for _, friend in ipairs(self.friends) do
			if self:isFriend(friend) and (friend:objectName() ~= self.player:objectName()) and ((num <= 1) or (num < self.player:getOverflow())) then
				use.card = card
				if use.to then use.to:append(friend) end
				num = num + 1
			end
		end
		return
	end
end]]



--[[local kezhuanjiaohaoex_skill = {}
kezhuanjiaohaoex_skill.name = "kezhuanjiaohaoex"
table.insert(sgs.ai_skills, kezhuanjiaohaoex_skill)
kezhuanjiaohaoex_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#kezhuanjiaohaoCard") then return end
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getTypeId() == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end
	if #equips == 0 then return end
	--return sgs.Card_Parse("#kezhuanjiaohaoCard:.:")
	return sgs.Card_Parse("@kezhuanjiaohaoCard=.")
end

sgs.ai_skill_use_func.kezhuanjiaohaoCard = function(card, use, self)
	if not self.player:hasUsed("#kezhuanjiaohaoCard") then
		local equips = {}
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Armor") or card:isKindOf("Weapon") then
				if not self:getSameEquip(card) then
				elseif card:isKindOf("GudingBlade") and self:getCardsNum("Slash") > 0 then
					local HeavyDamage
					local slash = self:getCard("Slash")
					for _, enemy in ipairs(self.enemies) do
						if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(slash, enemy) and
							self:slashIsEffective(slash, enemy) and not hasJueqingEffect(self.player, enemy) and enemy:isKongcheng() then
								HeavyDamage = true
								break
						end
					end
					if not HeavyDamage then table.insert(equips, card) end
				else
					table.insert(equips, card)
				end
			elseif card:getTypeId() == sgs.Card_TypeEquip then
				table.insert(equips, card)
			end
		end
	
		if #equips == 0 then return end
	
		local select_equip, target
		for _, friend in ipairs(self.friends_noself) do
			for _, equip in ipairs(equips) do
				local index = equip:getRealCard():toEquipCard():location()
				if not friend:hasEquipArea(index) then continue end
				if not self:getSameEquip(equip, friend) and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
			for _, equip in ipairs(equips) do
				local index = equip:getRealCard():toEquipCard():location()
				if not friend:hasEquipArea(index) then continue end
				if not self:getSameEquip(equip, friend) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
		end
	
		if not target then return end
		if use.to then
			use.to:append(target)
		end
		local kezhuanjiaohaoex = sgs.Card_Parse("@kezhuanjiaohaoCard=" .. select_equip:getId())
		--local kezhuanjiaohaoex = sgs.Card_Parse("#kezhuanjiaohaoCard:".. select_equip:getId())
		use.card = kezhuanjiaohaoex
	end
end

sgs.ai_card_intention.kezhuanjiaohaoCard = -80
sgs.ai_use_priority.kezhuanjiaohaoCard = sgs.ai_use_priority.RendeCard + 0.1  
sgs.ai_cardneed.kezhuanjiaohaoCard = sgs.ai_cardneed.equip]]

--黄忠

local kezhuancuifeng={}
kezhuancuifeng.name="kezhuancuifeng"
table.insert(sgs.ai_skills,kezhuancuifeng)
kezhuancuifeng.getTurnUseCard = function(self)
	local ss = {}
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if table.contains(ss,c:getSuit()) then continue end
		table.insert(ss,c:getSuit())
	end
	if #ss>2 then
		local dc = zhuandummyCard("fire_attack")
		dc:setSkillName("kezhuancuifeng")
		local d = self:aiUseCard(dc)
		if d.card and dc:isAvailable(self.player) then
			for _,to in sgs.list(d.to)do
				if to:isChained() then
					self.kezhuancuifengData = d
					sgs.ai_skill_choice.kezhuancuifeng = "fire_attack"
					sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
					return sgs.Card_Parse("#kezhuancuifengCard:.:")
				end
			end
		end
	end
	for _,pn in sgs.list(patterns())do
		local dc = zhuandummyCard(pn)
		if dc:isDamageCard() and dc:isSingleTargetCard()
		and self:getCardsNum(dc:getClassName())<1 then
			dc:setSkillName("kezhuancuifeng")
			if dc:isAvailable(self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					for _,to in sgs.list(d.to)do
						if self:ajustDamage(self.player,to,1,dc)>1 then
							self.kezhuancuifengData = d
							sgs.ai_skill_choice.kezhuancuifeng = pn
							sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
							return sgs.Card_Parse("#kezhuancuifengCard:.:")
						end
					end
				end
			end
		end
	end
	for _,pn in sgs.list(patterns())do
		local dc = zhuandummyCard(pn)
		if dc:isDamageCard() and dc:isSingleTargetCard()
		and self:getCardsNum(dc:getClassName())<1 then
			dc:setSkillName("kezhuancuifeng")
			if dc:isAvailable(self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					for _,to in sgs.list(d.to)do
						if to:getHp()<2 and self:isWeak(to) then
							self.kezhuancuifengData = d
							sgs.ai_skill_choice.kezhuancuifeng = pn
							sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
							return sgs.Card_Parse("#kezhuancuifengCard:.:")
						end
					end
				end
			end
		end
	end	
end

sgs.ai_skill_use_func["#kezhuancuifengCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.kezhuancuifengCard = 6.4
sgs.ai_use_priority.kezhuancuifengCard = 6.4

sgs.ai_skill_use["@@kezhuancuifeng"] = function(self,prompt)
	local dummy = self.kezhuancuifengData
	if dummy.card and dummy.to then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return dummy.card:toString().."->"..table.concat(tos,"+")
	end
end

local kezhuandengnan={}
kezhuandengnan.name="kezhuandengnan"
table.insert(sgs.ai_skills,kezhuandengnan)
kezhuandengnan.getTurnUseCard = function(self)
	if self.player:getMark("@kezhuancuifeng")>0 and #self.enemies>1 then
		local dc = zhuandummyCard("iron_chain")
		dc:setSkillName("kezhuandengnan")
		local d = self:aiUseCard(dc)
		if d.card and dc:isAvailable(self.player) then
			local x = 0
			for _,to in sgs.list(d.to)do
				if not to:isChained()
				then x = x+1 end
			end
			if x>1 then
				self.kezhuandengnanData = d
				sgs.ai_skill_choice.kezhuandengnan = "iron_chain"
				sgs.ai_use_priority.kezhuandengnanCard = sgs.ai_use_priority[dc:getClassName()]
				return sgs.Card_Parse("#kezhuandengnanCard:.:")
			end
		end
	end
	local choices = {}
	for _,pn in sgs.list(patterns()) do
		local dc = zhuandummyCard(pn)
		if not dc:isDamageCard() and dc:isNDTrick()
		and self:getCardsNum(dc:getClassName())<1 then
			dc:setSkillName("kezhuandengnan")
			if dc:isAvailable(self.player) then
				table.insert(choices,dc)
			end
		end
	end
	if #choices<1 then return end
	self:getUseValue(choices)
	for _,dc in sgs.list(choices)do
		local dummy = self:aiUseCard(dc)
		if dummy.card then
			local can = dummy.to:length()>0
			for _,to in sgs.list(dummy.to)do
				if to:getMark("&kezhuandengnanda")<1 then
					can = false
					break
				end
			end
			if can then
				self.kezhuandengnanData = dummy
				sgs.ai_skill_choice.kezhuandengnan = dc:objectName()
				sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
				return sgs.Card_Parse("#kezhuandengnanCard:.:")
			end
		end
	end
	if self:isWeak() then
		for _,dc in sgs.list(choices)do
			local dummy = self:aiUseCard(dc)
			if dummy.card then
				self.kezhuandengnanData = dummy
				sgs.ai_skill_choice.kezhuandengnan = dc:objectName()
				if dummy.to:isEmpty() and dc:canRecast() then continue end
				sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
				return sgs.Card_Parse("#kezhuandengnanCard:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#kezhuandengnanCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.kezhuandengnanCard = 6.4
sgs.ai_use_priority.kezhuandengnanCard = 6.4

sgs.ai_skill_use["@@kezhuandengnan"] = function(self,prompt)
	local dummy = self.kezhuandengnanData
	if dummy.card then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return dummy.card:toString().."->"..table.concat(tos,"+")
	end
end




--娄圭
sgs.ai_playerchosen_intention["kezhuanshacheng"] = -80
sgs.ai_skill_playerchosen.kezhuanshacheng = function(self, targets)
	targets = sgs.QList2Table(targets)
    self:sort(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getMark("kezhuanshachenglose-Clear")>1 and self:canDraw(p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getMark("kezhuanshachenglose-Clear")>0 and self:isWeak(p) and self:canDraw(p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.kezhuanshacheng = function(self, data)
	if self.player:hasFlag("wantuseshacheng") then
		return true
	end
end

sgs.ai_skill_invoke.kezhuanninghan = function(self, data)
	return true
end


--张楚
local kezhuanhuozhong={}
kezhuanhuozhong.name="kezhuanhuozhong"
table.insert(sgs.ai_skills,kezhuanhuozhong)
kezhuanhuozhong.getTurnUseCard = function(self)
	return sgs.Card_Parse("#kezhuanhuozhongCard:.:")
end
local kezhuanhuozhongex={}
kezhuanhuozhongex.name="kezhuanhuozhongex"
table.insert(sgs.ai_skills,kezhuanhuozhongex)
kezhuanhuozhongex.getTurnUseCard = function(self)
	return sgs.Card_Parse("#kezhuanhuozhongCard:.:")
end

sgs.ai_skill_use_func["#kezhuanhuozhongCard"] = function(card,use,self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,c in ipairs(self.toUse)do
		table.removeOne(cards,c)
	end
	for _,c in ipairs(cards)do
		if not c:isBlack() or c:getTypeId()==2 then continue end
		local dc = zhuandummyCard("supply_shortage")
		dc:setSkillName("kezhuanhuozhong")
		dc:addSubcard(c)
		if not self.player:containsTrick("supply_shortage") and self.player:hasJudgeArea()
		and not self.player:isProhibited(self.player, dc) then
			for _,p in sgs.list(self.room:findPlayersBySkillName("kezhuanhuozhong"))do
				if self:isFriend(p) and (self:isWeak(p) or #cards>3) then
					use.card = sgs.Card_Parse("#kezhuanhuozhongCard:"..c:getId()..":")
					use.to:append(self.player)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.kezhuanhuozhongCard = 6.4
sgs.ai_use_priority.kezhuanhuozhongCard = 4.4

sgs.ai_skill_playerchosen.kezhuanhuozhong = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.kezhuanrihui = function(self, data)
	local n = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getJudgingArea():length()>0 then
			if self:isEnemy(p) then
				n = n-1
			else
				n = n+1
			end
		end
	end
	return n>0
end

--夏侯恩

sgs.ai_skill_invoke.kezhuanhujian = function(self, data)
	return true
end

local kezhuanshili_skill={}
kezhuanshili_skill.name="kezhuanshili"
table.insert(sgs.ai_skills,kezhuanshili_skill)
kezhuanshili_skill.getTurnUseCard=function(self)
	if (self.player:getMark("usekezhuanshili-PlayClear") > 0)
	or (self.player:hasFlag("usekezhuanshili")) then return nil end
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)

	local card
	for _,acard in ipairs(cards)  do
		if (acard:isKindOf("EquipCard")) then
			card = acard
			break
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("duel:kezhuanshili[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.weapon_range.Kezhuan_chixueqingfeng = 2
sgs.ai_use_priority.Kezhuan_chixueqingfeng = 3


--庞统

local kezhuanyangming_skill = {}
kezhuanyangming_skill.name = "kezhuanyangming"
table.insert(sgs.ai_skills, kezhuanyangming_skill)
kezhuanyangming_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kezhuanyangmingCard") or (not self.player:canPindian()) then return end
	return sgs.Card_Parse("#kezhuanyangmingCard:.:")
end

sgs.ai_skill_use_func["#kezhuanyangmingCard"] = function(card, use, self)
    if (not self.player:hasUsed("#kezhuanyangmingCard"))
	and (not self.player:isKongcheng()) then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if (self.player:canPindian(enemy, true)) then
				if enys:isEmpty() then
					enys:append(enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) >= (p:getHp()+p:getHp()+p:getHandcardNum()) then
							yes = 0
						end
					end
					if (yes == 1) then
						enys:removeOne(enys:at(0))
						enys:append(enemy)
					end
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			if (self:objectiveLevel(enemy) > 0) then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.kezhuanyangmingCard = 8.5
sgs.ai_use_priority.kezhuanyangmingCard = 9.5
sgs.ai_card_intention.kezhuanyangmingCard = 80

sgs.ai_skill_invoke.kezhuanyangming = function(self, data)
	return true
end

local kezhuanmanjuan={}
kezhuanmanjuan.name="kezhuanmanjuan"
table.insert(sgs.ai_skills,kezhuanmanjuan)
kezhuanmanjuan.getTurnUseCard = function(self)
	local choices = {}
	for i=0,sgs.Sanguosha:getCardCount()-1 do
		local c = sgs.Sanguosha:getEngineCard(i)
		if self.player:getMark(i.."manjuanPile-Clear")>0
		and self.player:getMark(c:getNumber().."manjuanNumber-Clear")<1
		and c:isAvailable(self.player)
		then table.insert(choices,c) end
	end
	if #choices<1 then return end
	self:getUseValue(choices)
	for _,dc in sgs.list(choices)do
		local dummy = self:aiUseCard(dc)
		if dummy.card then
			self.kezhuanmanjuanData = dummy
			if dummy.to:isEmpty() and dc:canRecast() then continue end
			sgs.ai_use_priority.kezhuanmanjuanCard = sgs.ai_use_priority[dc:getClassName()]
			return sgs.Card_Parse("#kezhuanmanjuanCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#kezhuanmanjuanCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.kezhuanmanjuanCard = 6.4
sgs.ai_use_priority.kezhuanmanjuanCard = 6.4

sgs.ai_skill_use["@@kezhuanmanjuan"] = function(self,prompt)
	local dummy = self.kezhuanmanjuanData
	if dummy.card then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return "#kezhuanmanjuanVsCard:.:@@kezhuanmanjuan->"..table.concat(tos,"+")
	end
end

function sgs.ai_cardsview.kezhuanmanjuan(self,class_name,player)
	if self.player:isKongcheng() then
		for i=0,sgs.Sanguosha:getCardCount()-1 do
			local c = sgs.Sanguosha:getCard(i)
			if player:getMark(i.."manjuanPile-Clear")>0
			and player:getMark(c:getNumber().."manjuanNumber-Clear")<1
			and not player:isLocked(c) and c:isKindOf(class_name)
			then return "#kezhuanmanjuanVsCard:.:"..c:objectName() end
		end
	end
end


--范疆张达

sgs.ai_skill_discard.kezhuanfushan = function(self, discard_num, min_num, optional, include_equip) 
	if not (self.player:hasFlag("wantusefushan")) then
		return self:askForDiscard("dummyreason", discard_num, discard_num, true, true)
	else
		local to_discard = {}
		local yes = 0
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if (c:isKindOf("Slash")) then
				table.insert(to_discard, c:getEffectiveId())
				yes = 1
				break
			end
		end
		if yes == 1 then
			return to_discard
		else
			return self:askForDiscard("dummyreason", discard_num, discard_num, true, true)
		end
	end
end

sgs.ai_skill_use["@@kezhuanniluan"] = function(self,prompt)
	self:sort(self.enemies)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards,nil,"j")
	for _,p in sgs.list(self.enemies)do
		if #cards>0 and p:getMark("kezhuanniluan"..self.player:objectName())<1 and self:isWeak(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal) and not self:cantbeHurt(p)
			then
			return "#kezhuanniluanCard:"..cards[1]:getId()..":->"..p:objectName()
		end
	end
	self:sort(self.friends)
	for _,p in sgs.list(self.friends)do
		if p:getMark("kezhuanniluan"..self.player:objectName())>0 and self:isWeak(p) then
			return "#kezhuanniluanCard:.:->"..p:objectName()
		end
	end
	for _,p in sgs.list(self.friends)do
		if p:getMark("kezhuanniluan"..self.player:objectName())>0 then
			return "#kezhuanniluanCard:.:->"..p:objectName()
		end
	end
	for _,p in sgs.list(self.friends)do
		if #cards>1 and p:getMark("kezhuanniluan"..self.player:objectName())<1 and not self:isWeak(p) then
			return "#kezhuanniluanCard:"..cards[1]:getId()..":->"..p:objectName()
		end
	end
end

sgs.ai_ajustdamage_from.kezhuanhuchou = function(self,from,to,card,nature)
	if to:getMark("&kezhuanhuchou+#"..from:objectName())>0
	then return 1 end
end

