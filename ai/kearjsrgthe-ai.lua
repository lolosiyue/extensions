
sgs.ai_skill_use["@@kehexumouuse"] = function(self, prompt)
	local id = self.player:getTag("kehexumouForAI"):toIntList():first()
	local card = sgs.Sanguosha:getEngineCard(id)
	local d = self:aiUseCard(card)
	if d.card then
		local targets = {}
		for _, p in sgs.qlist(d.to)do
			table.insert(targets, p:objectName())
		end
		if card:canRecast() and #targets<1 then return "." end
		return id.."->"..table.concat(targets, "+")
	end
	return "."
end

--郭循

sgs.ai_skill_choice.keheeqian = function(self, choices, data)
	return "add"
end

sgs.ai_skill_invoke.keheeqian = function(self, data)
	local to = data:toPlayer()
	return self:isEnemy(to) or not self:isFriend(to) and #self.enemies<1
end

sgs.ai_skill_discard.keheeqian = function(self) 
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local cns = {}
	for _,c in sgs.qlist(self.player:getCards("j"))do
		if string.find(c:objectName(),"kehexumou")
		then table.insert(cns, sgs.Sanguosha:getEngineCard(c:getEffectiveId()):objectName()) end
	end
	for _, c in ipairs(cards)do 
		if not table.contains(cns, c:objectName()) and c:isAvailable(self.player) then
			return {c:getEffectiveId()}
		end
	end
	if #cns>0 then return {} end
	return self:askForDiscard("dummyreason", 1, 1, true, true)
end
sgs.ai_choicemade_filter.skillInvoke.keheeqian = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end

local kehefusha_skill = {}
kehefusha_skill.name = "kehefusha"
table.insert(sgs.ai_skills, kehefusha_skill)
kehefusha_skill.getTurnUseCard = function(self)
	if (self.player:getMark("@kehefusha") <= 0) then return end
	return sgs.Card_Parse("#kehefushaCard:.:")
end

sgs.ai_skill_use_func["#kehefushaCard"] = function(card, use, self)
	self:sort(self.enemies)
	local n = math.min(self.player:getAttackRange(),self.room:getPlayers():length())
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) and enemy:getHp()<=n and (#self.enemies<2 or enemy:getHp()>1)
		and self:damageIsEffective(enemy,"N",self.player) then
			use.card = card
			use.to:append(enemy)
			break
		end
	end
end

sgs.ai_use_value.kehefushaCard = 8.5
sgs.ai_use_priority.kehefushaCard = 3.5
sgs.ai_card_intention.kehefushaCard = 80



--诸葛亮

sgs.ai_skill_invoke.kehewentian = function(self, data)
	if self.player:getMark("@usekehewentian")<2 and #self.friends_noself<1
	then return end
	if self.player:getPhase()==sgs.Player_Judge then
		return self.player:getJudgingArea():length()>0
	end
	return self.player:getPhase()>=sgs.Player_Play
	and #self.friends_noself>0
end

sgs.ai_skill_playerchosen.kehewentian = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = sgs.SPlayerList()
	local theweaktwo = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if (qq:getRole() == "lord") then
			for _,oo in sgs.qlist(theweak) do
				theweaktwo:removeOne(oo)
			end
			theweaktwo:append(qq)
			break
		end
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	--[[for _,zg in sgs.qlist(self.player:getAliveSiblings()) do
		if self:isFriend(zg) and (zg:getRole() == "lord") then
			return zg
		end
	end]]
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end
sgs.ai_playerchosen_intention.kehewentian = -40


local kehewentian_skill={}
kehewentian_skill.name="kehewentian"
table.insert(sgs.ai_skills,kehewentian_skill)
kehewentian_skill.getTurnUseCard=function(self)
	local id = self.player:getMark("kehewentianId")
	local dc = dummyCard("fire_attack")
	dc:addSubcard(id)
	dc:setSkillName("kehewentian")
	if not dc:isAvailable(self.player) then return end
	if self.player:getMark("usedkehewentian-Clear")>0 and sgs.Sanguosha:getCard(id):isRed() then
		return dc
	end
	local d = self:aiUseCard(dc)
	if d.card then
		for _,p in sgs.qlist(d.to) do
			if (self:isEnemy(p) or p:isChained()) and self:isWeak(p)  then
				return dc
			end
		end
	end
end

--[[sgs.ai_view_as.kehewentian = function(card, player, card_place)
	local pdcard = sgs.Sanguosha:getCard(player:getMark("kehewentianId"))
	local suit = pdcard:getSuitString()
	local number = pdcard:getNumberString()
	local card_id = player:getMark("kehewentianId")
	if (pdcard:isBlack() or (math.random(1,10) >=7)) and (player:getMark("&bankehewentian_lun") == 0) then
		return ("nullification:kehewentian[%s:%s]=%d"):format(suit, number, card_id)
	end	
end]]

function sgs.ai_cardsview.kehewentian(self, class_name, player)
	if class_name == "Nullification" then
		local id = player:getMark("kehewentianId")
		local dc = dummyCard("nullification")
		dc:addSubcard(id)
		dc:setSkillName("kehewentian")
		if self.player:getMark("usedkehewentian-Clear")>0 then
			return sgs.Sanguosha:getCard(id):isBlack() and dc
		end
		return dc:toString()
	end
end

sgs.ai_skill_discard.keheyinlue = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local cards = self.player:getCards("he")
	local to = self.player:getTag("keheyinlueTo"):toPlayer()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:isFriend(to) and not self:needToLoseHp(to) then
	    table.insert(to_discard, cards[1]:getEffectiveId())
		return to_discard
	elseif not self:isEnemy(to) then
	    return self:askForDiscard("dummyreason", 1, 1, true, true)
	end
	return {}
end

local kehechushi_skill = {}
kehechushi_skill.name = "kehechushi"
table.insert(sgs.ai_skills, kehechushi_skill)
kehechushi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehechushiCard") then return end
	return sgs.Card_Parse("#kehechushiCard:.:")
end

sgs.ai_skill_use_func["#kehechushiCard"] = function(card, use, self)
    if not self.player:hasUsed("#kehechushiCard") then
        use.card = card
	    return
	end
end

sgs.ai_skill_invoke.keheyinlue = function(self, data)
	if self.player:hasFlag("wantuseyinlue") then
	    return true
	end
end

sgs.ai_skill_discard.kehechushi = function(self)
	local zhugeliang = self.room:getTag("kehechushi_from"):toPlayer()
	local to_discard = {}
	if zhugeliang and self:isFriend(zhugeliang) or (self.player:objectName()==zhugeliang:objectName() and getLord(zhugeliang) and self:isFriend(getLord(zhugeliang), zhugeliang)) then
		if zhugeliang:getMark("&kehechushi_lun") > 0 then
			local cards = self.player:getCards("h")
			cards = sgs.QList2Table(cards)
			self:sortByKeepValue(cards)
			for _,h in sgs.list(cards)do
				if h:isRed() then
					table.insert(to_discard,h:getId())
					break
				end
			end	
		else
			for _,m in ipairs(self.player:getMarkNames())do
				if self.player:getMark(m)>0 and (m:startsWith("kehewentianObtain")) then 
					if self.player:objectName()==zhugeliang:objectName() then
						local color = sgs.Sanguosha:getCard(tonumber(m:split(":")[2])):getColor()
						local cards = self.player:getCards("h")
						cards = sgs.QList2Table(cards)
						self:sortByKeepValue(cards)
						for _,h in sgs.list(cards)do
							if h:getColor() == color then
								table.insert(to_discard,h:getId())
								break
							end
						end	
					else
						table.insert(to_discard,tonumber(m:split(":")[2])) 
					end
				end
			end
		end
	end
	if #to_discard == 0 then
		table.insert(to_discard, self.player:getCards("h"):last():getId())
	end
	return to_discard
end

sgs.ai_use_value.kehechushiCard = 8.5
sgs.ai_use_priority.kehechushiCard = 7.5

sgs.ai_ajustdamage_from.kehechushi = function(self,from,to,card,nature)
	if from and from:getMark("&kehechushi_lun") > 0 and nature ~= sgs.DamageStruct_Normal then
		return 1 
	end
end


--二虎

sgs.ai_skill_invoke.kehedaimou = function(self, data)
	return true
end

sgs.ai_skill_invoke.kehefangjie = function(self, data)
	local hasxm,nouse,cns = 0,0,{}
	for _,c in sgs.qlist(self.player:getJudgingArea()) do
		if string.find(c:objectName(),"kehexumou") then
			local ec = sgs.Sanguosha:getEngineCard(c:getEffectiveId())
			if table.contains(cns, ec:objectName()) then nouse = nouse+1 break end
			table.insert(cns, ec:objectName())
			if ec:isAvailable(self.player) then
				local d = self:aiUseCard(ec)
				if d.card then
					hasxm = hasxm+1
				else
					nouse = nouse+1
				end
			else
				nouse = nouse+1
			end
		end
	end
	return hasxm>nouse and nouse>1
end

sgs.ai_skill_cardchosen.kehefangjie = function(self,who,flags,method)
	local cns = {}
	for _,c in sgs.qlist(self.player:getJudgingArea()) do
		if string.find(c:objectName(),"kehexumou") then
			local id = c:getEffectiveId()
			if self.disabled_ids:contains(id) then continue end
			local ec = sgs.Sanguosha:getEngineCard(id)
			if table.contains(cns, ec:objectName()) then return id end
			table.insert(cns, ec:objectName())
			if ec:isAvailable(self.player) then
				local d = self:aiUseCard(ec)
				if d.card then
					
				else
					return id
				end
			else
				return id
			end
		end
	end
end

--卫温诸葛直

local kehefuhai_skill = {}
kehefuhai_skill.name = "kehefuhai"
table.insert(sgs.ai_skills, kehefuhai_skill)
kehefuhai_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehefuhaiCard") then return end
	return sgs.Card_Parse("#kehefuhaiCard:.:")
end

sgs.ai_skill_use_func["#kehefuhaiCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_value.kehefuhaiCard = 8.5
sgs.ai_use_priority.kehefuhaiCard = 9.5
sgs.ai_card_intention.kehefuhaiCard = 33

--郭照

sgs.ai_skill_invoke.kehepianchong = function(self, data)
	return true
end

--姜维

local kehejinfa_skill = {}
kehejinfa_skill.name = "kehejinfa"
table.insert(sgs.ai_skills, kehejinfa_skill)
kehejinfa_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehejinfaCard") then return end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if #cards>0 then
		return sgs.Card_Parse("#kehejinfaCard:"..cards[1]:getId()..":")
	end
end

sgs.ai_skill_use_func["#kehejinfaCard"] = function(card, use, self)
    use.card = card
	kehejinfaColor = card:getColor()
end

function sgs.ai_cardneed.kehejinfaCard(to, card, self)
	if self.player:hasUsed("#kehejinfaCard") then return false end
	return true
end

sgs.ai_use_value.kehejinfaCard = 8.5
sgs.ai_use_priority.kehejinfaCard = 9.5
sgs.ai_card_intention.kehejinfaCard = 80

sgs.ai_skill_playerschosen.kehejinfa = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if self:isFriend(target) then
            selected:append(target)
			sgs.updateIntention(self.player,target,-80)
			if selected:length()>=max then break end
        end
    end
    return selected
end

sgs.ai_skill_choice.kehejinfa = function(self, choices)
	local items = choices:split("+")
	if (self.player:getKingdom() == "shu") then
	    return "wei"
	else
		return "shu"
	end
end

sgs.ai_skill_discard.kehejinfa = function(self)
	local from = self.room:getTag("kehejinfaFrom"):toPlayer()
	if self:isFriend(from) then
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if (c:getColor()==kehejinfaColor) then
				return {c:getId()}
			end
		end
	end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	return {cards[1]:getId()}
end

sgs.ai_skill_use["@@kehefumou"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
    	local c = dummyCard("chuqibuyi")
		c:setSkillName("kehefumou")
		c:addSubcard(h)
		if self.player:isLocked(c) or not c:isKindOf("KezhuanYing") then continue end
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
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill.."|kehefumou"

sgs.ai_view_as.kehexuanfeng = function(card, player, card_place)
	if (player:getKingdom() == "shu") and card_place ~= sgs.Player_PlaceSpecial and card:isKindOf("KezhuanYing") then
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		return ("_kecheng_stabs_slash:kehexuanfeng[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local kehexuanfeng_skill = {}
kehexuanfeng_skill.name = "kehexuanfeng"
table.insert(sgs.ai_skills, kehexuanfeng_skill)
kehexuanfeng_skill.getTurnUseCard = function(self, inclusive)
	if (self.player:getKingdom() ~= "shu") then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("KezhuanYing") then
			local dc = dummyCard("_kecheng_stabs_slash")
			dc:setSkillName("kehexuanfeng")
			dc:addSubcard(card)
			return dc
		end
	end
end

function sgs.ai_cardneed.kehexuanfeng(to, card)
	return card:isKindOf("KezhuanYing") 
end

sgs.Active_cardneed_skill = sgs.Active_cardneed_skill.."|kehexuanfeng"


--赵云
sgs.ai_skill_invoke.kehelonglinjuedou = function(self, data)
	local from = data:toPlayer()
	local duel = dummyCard("duel")
	local dummy_use = self:aiUseCard(duel,dummy(true,99))
	if dummy_use.card then
		for _,p in sgs.list(dummy_use.to)do
			if p:objectName() == from:objectName() then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_discard.kehelonglin = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards,nil,"j")
	local use = self.player:getTag("kehelonglinData"):toCardUse()
	if self:isFriend(use.to:first()) and not self:needToLoseHp(use.to:first(),use.from,use.card,true) then
	    if not self:isFriend(use.from) then
			table.insert(to_discard, cards[1]:getEffectiveId())
		end
	elseif not self:isEnemy(use.to:first()) then
	    to_discard = self:askForDiscard("dummyreason", 1, 1, true, true)
	end
	return to_discard
end

local kehezhendan_skill = {}
kehezhendan_skill.name = "kehezhendan"
table.insert(sgs.ai_skills, kehezhendan_skill)
kehezhendan_skill.getTurnUseCard = function(self, inclusive)
	local handcards = self:addHandPile("h")
	self:sortByUseValue(handcards, true)
	for _, pn in ipairs(patterns())do
		local dc = dummyCard(pn)
		dc:setSkillName("kehezhendan")
		if dc:getTypeId()==1 then
			for _, h in ipairs(handcards)do
				if h:getTypeId()>1 and self:getUseValue(h)<self:getUseValue(dc) then
					dc:addSubcard(h)
					if dc:isAvailable(self.player) then
						local d = self:aiUseCard(dc)
						if d.card then
							return dc
						end
					end
					dc:clearSubcards()
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#kehezhendan"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local kehezhendancard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	kehezhendancard:setSkillName("kehezhendan")
	self:useBasicCard(kehezhendancard, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["kehezhendan"] = 3
sgs.ai_use_value["kehezhendan"] = 3

function sgs.ai_cardsview.kehezhendan(self,class_name,player)
	local handcards = self:addHandPile("h")
	self:sortByKeepValue(handcards)
	for _, h in ipairs(handcards)do
		if h:getTypeId()>1 then
			local dc = dummyCard(class_name)
			dc:setSkillName("kehezhendan")
			dc:addSubcard(h)
			return dc:toString()
		end
	end
end

function sgs.ai_cardneed.kehezhendan(to, card, self)
	return (not card:isKindOf("BasicCard")) and (not card:isEquipped())
end


--司马懿

sgs.ai_skill_invoke.keheyingshi = function(self, data)
	return true
end

sgs.ai_skill_invoke.kehetuigu = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kehetuigu = function(self, targets)
	if self:isWeak() and (self.player:getEquipsId():length() > 0) then
		return self.player
	end
	targets = sgs.QList2Table(targets)
	local theweak = sgs.SPlayerList()
	local theweaktwo = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getEquips():length() > qq:getEquips():length()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:removeOne(theweaktwo:at(0))
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end

sgs.ai_skill_use["@@kehetuigu"] = function(self,prompt)
	local xjgt = sgs.Sanguosha:cloneCard("_kehe_jiejiaguitian")
	xjgt:setSkillName("kehetuigu")
	xjgt:deleteLater() 
	local dummy_use = dummy()
	self:useCardZlJiejiaguitian(xjgt,dummy_use)
	if dummy_use.card then
		if dummy_use.to:length() > 0 then
			local targets ={}
			for _, enemy in sgs.qlist(dummy_use.to) do
				table.insert(targets, enemy:objectName())
			end
			return xjgt:toString()..":.:->" .. table.concat(targets,"+")
		end
	end
end

sgs.lose_equip_skill = sgs.lose_equip_skill.."|kehetuigu"

sgs.ai_cardneed.kehetuigu = sgs.ai_cardneed.equip

--曹芳
local kehezhaotu_skill={}
kehezhaotu_skill.name="kehezhaotu"
table.insert(sgs.ai_skills,kehezhaotu_skill)
kehezhaotu_skill.getTurnUseCard=function(self,inclusive)
	if (self.player:getMark("kehezhaotuuse_lun") ~= 0) then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	self:sortByUseValue(cards,true)

	local has_weapon, has_armor = false, false

	for _,acard in ipairs(cards)  do
		if acard:isKindOf("Armor") then has_armor=true end
		if acard:isKindOf("Weapon") then has_weapon=true end
	end

	for _,acard in ipairs(cards)  do
		if acard:isRed() and acard:getTypeId()~=2 and (inclusive or self:getUseValue(acard)<sgs.ai_use_value.Indulgence) then
			if acard:isKindOf("Armor") then
				if not self.player:getArmor() then continue
				elseif self.player:hasEquip(acard) and not has_armor and self:evaluateArmor()>0
				then continue end
			end
			if acard:isKindOf("Weapon") then
				if not self.player:getWeapon() then continue
				elseif self.player:hasEquip(acard) and not has_weapon
				then continue end
			end
			local dc = dummyCard("indulgence")
			dc:setSkillName("kehezhaotu")
			dc:addSubcard(acard)
			return dc
		end
	end
end

function sgs.ai_cardneed.kehezhaotu(to, card)
	return card:isRed() and (not card:isKindOf("TrickCard"))
end

local kehejingju_skill={}
kehejingju_skill.name="kehejingju"
table.insert(sgs.ai_skills,kehejingju_skill)
kehejingju_skill.getTurnUseCard = function(self)
	for _,p in sgs.list(self.player:getAliveSiblings())do
		for _,j in sgs.list(p:getJudgingArea())do
			if self.player:containsTrick(j:objectName())
			or self:isEnemy(p) then continue end
			return sgs.Card_Parse("#kehejingjuCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#kehejingjuCard"] = function(card,use,self)
	for _,p in sgs.list(patterns())do
		local dc = dummyCard(p)
		if dc and dc:getTypeId()==1 then
			dc:setSkillName("kehejingju")
			if dc:isAvailable(self.player) then
				local dummy = self:aiUseCard(dc)
				if dummy.card then
					use.card = sgs.Card_Parse("#kehejingjuCard:.:"..dc:objectName())
					if use.to then use.to = dummy.to end
					break
				end
			end
		end
	end
end

sgs.ai_use_value.kehejingjuCard = 4.4
sgs.ai_use_priority.kehejingjuCard = 3

function sgs.ai_cardsview.jingju(self,class_name,player)
	if sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	then return end
	local dc = dummyCard(class_name)
	if dc and dc:getTypeId()==1 then
		for _,p in sgs.list(player:getAliveSiblings())do
			for _,j in sgs.list(p:getJudgingArea())do
				if player:containsTrick(j:objectName()) then continue end
				return ("#kehejingjuCard:.:"..dc:objectName())
			end
		end
	end
end

sgs.ai_skill_playerchosen.kehejingju = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"card")
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

sgs.ai_skill_discard.keheweizhui = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local from = self.player:getTag("keheweizhuiFrom"):toPlayer()
	if self:doDisCard(from,"hej") then
		if cards[1]:isBlack() then
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		end
	end
	return self:askForDiscard("dummyreason", 1, 1, true, true)
end

--陆逊

sgs.ai_skill_playerchosen.keheyoujin = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	local slash = dummyCard()
	for _,to in sgs.list(self.enemies)do
		if table.contains(targets, to) and self:slashIsEffective(slash,to,self.player) and not self:needToLoseHp(to,self.player,slash) and not self:findLeijiTarget(to,50,self.player) then
			return to
		end
	end
	return nil
end


local kehedailao_skill = {}
kehedailao_skill.name = "kehedailao"
table.insert(sgs.ai_skills, kehedailao_skill)
kehedailao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehedailaoCard") then return end
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:isAvailable(self.player) then
			return
		end
	end
	return sgs.Card_Parse("#kehedailaoCard:.:")
end

sgs.ai_skill_use_func["#kehedailaoCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value.kehedailaoCard = 8.5
sgs.ai_use_priority.kehedailaoCard = 9.5

sgs.ai_ajustdamage_from.kehezhubei = function(self,from,to,slash,nature)
	if to:getMark("&kehezhubeida-Clear") > 0
	then return 1 end
end


--孙峻

sgs.ai_skill_invoke.keheyaoyan = function(self, data)
	return true
end

sgs.ai_skill_choice.keheyaoyan = function(self, choices, data)
	local sj = self.room:getCurrent()
	if (self.player == sj) then
		return "join"
	else
		if self:isFriend(sj) then
			if math.random(0,5) > 1 then
				return "join"
			end
		else
			if math.random(0,2)>1 then
				return "join"
			end
		end
	end
	return "notjoin"
end

sgs.ai_skill_playerschosen.keheyaoyan = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if self:isEnemy(target)
		or self:getOverflow(target) > 1 then
            selected:append(target)
            if selected:length()>=max then break end
        end
    end
    return selected
end

sgs.ai_skill_playerchosen.keheyaoyan = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, enemy in ipairs(targets) do
		if enemy and self:isEnemy(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(enemy) then
			return enemy
		end
	end
	
	return nil
end

sgs.ai_skill_discard.keheyaoyan = function(self)
	local from = self.room:getTag("keheyaoyanFrom"):toPlayer()
	
	if self:isFriend(from) then
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if (c:isRed() and from:getMark("keheyaoyan") < (self.room:getAlivePlayers():length() / 2)) then
				return {c:getId()}
			end
		end
	end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	return {cards[1]:getId()}
end


local kehechiying_skill = {}
kehechiying_skill.name = "kehechiying"
table.insert(sgs.ai_skills, kehechiying_skill)
kehechiying_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehechiyingCard") then return end
	return sgs.Card_Parse("#kehechiyingCard:.:")
end

sgs.ai_skill_use_func["#kehechiyingCard"] = function(card, use, self)
	self:sort(self.friends)
	local target
	local max = 0
	for _, friend in ipairs(self.friends) do
		local x = 0
		for _, enemy in ipairs(self.enemies) do
			if friend:inMyAttackRange(enemy) and self:doDisCard(enemy,"he") then
				x = x + 1
			end
		end
		for _, friend2 in ipairs(self.friends) do
			if friend:inMyAttackRange(friend2) and friend:objectName() ~= friend2:objectName() and not self:doDisCard(friend2,"he") then
				x = x - 1
			end
		end
		if x > max then
            max = x
            target = friend
        end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_value.kehechiyingCard = 8.5
sgs.ai_use_priority.kehechiyingCard = 9.5
sgs.ai_card_intention.kehechiyingCard = -80

--[[sgs.ai_skill_use_func["#kehechiyingCard"] = function(card, use, self)
	if not self.player:hasUsed("#kehechiyingCard") then
		self:updatePlayers()
		local room = self.room
		local can_dis = 0
		local target = nil
	
		for _,friend in ipairs(self.friends) do
			if friend:getHp() <= self.player:getHp() then
				local dis = 0
				for _,other in sgs.qlist(room:getOtherPlayers(friend)) do
					if friend:inMyAttackRange(other) and other:objectName() ~= self.player:objectName() then
						if not self:isFriend(other) then
							if friend:objectName() == self.player:objectName() then
								dis = dis + 1
							else
								dis = dis + 1.5
							end
						end
					end
				end
				if dis > can_dis then
					target = friend
					can_dis = dis
				end
			end
		end
	
		if not target then return end
		if target then
			local card_str = "#kehechiying:.:->"..target:objectName()
			local acard = sgs.Card_Parse(card_str)
			assert(acard)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_use_priority.kehechiying = 6]]

sgs.ai_use_revises.kehedanxin = function(self,card,use)
	if card:getSkillName() == "kehedanxin" then
		for _,friend in sgs.list(self.friends_noself)do
			if friend:getHp() < getBestHp(friend) and self.player:distanceTo(friend) == 1 then
				use.card = card
				use.to:append(friend)
				break
			end
		end
	end
end
local kehedanxin = {}
kehedanxin.name = "kehedanxin"
table.insert(sgs.ai_skills, kehedanxin)
kehedanxin.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	self:sortByUseValue(cards,true)
	if #cards<1 then return end
	local acard = sgs.Sanguosha:cloneCard("_kecheng_tuixinzhifu")
	acard:setSkillName("kehedanxin")
	acard:addSubcard(cards[1])
	acard:deleteLater()
	return acard
end

sgs.ai_skill_playerchosen.kehefengxiang = function(self, targets)
	local target, min_friend, max_enemy
	for _, enemy in ipairs(self.enemies) do
		if not self:hasSkills(sgs.lose_equip_skill, enemy) and not hasTuntianEffect(enemy, true) and self.player:getPile("wooden_ox"):length() == 0 then
			local ee = enemy:getEquips():length()
			local fe = self.player:getEquips():length()
			local value = self:evaluateArmor(enemy:getArmor(), self.player) -
				self:evaluateArmor(self.player:getArmor(), enemy)
				- self:evaluateArmor(self.player:getArmor(), self.player) + self:evaluateArmor(enemy:getArmor(), enemy)
			if ee > 0 and (ee > fe or ee == fe and value > 0) then
				return enemy
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if hasTuntianEffect(friend, true) or self:hasSkills(sgs.lose_equip_skill, friend) or self:hasSkills(sgs.need_equip_skill, friend) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends) do
		if friend:getEquips():length() > 0 then
			return friend
		end
	end
	for _, friend in ipairs(self.friends) do
		if self:needToThrowArmor(self.player) then
			return friend
		end
	end

	return nil
end


local kehejiuxian_skill = {}
kehejiuxian_skill.name = "kehejiuxian"
table.insert(sgs.ai_skills, kehejiuxian_skill)
kehejiuxian_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	local target
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	for _, enemy in ipairs(self.enemies) do
		if  self:hasTrickEffective(duel, enemy, self.player) and
			self:damageIsEffective(self.player, sgs.DamageStruct_Normal, enemy) and self:canAttack(enemy, self.player) then
			target = enemy
		end
	end
	duel:deleteLater()
	if ( target) then
		return sgs.Card_Parse("#kehejiuxian:.:")
	end
end

sgs.ai_skill_use_func["#kehejiuxian"] = function(card, use, self)
	local target
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	for _, enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) and self:hasTrickEffective(duel, enemy, self.player) and
			self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) and self:canAttack(enemy, self.player) then
			target = enemy
		end
	end

	if not target then
		for _, enemy in ipairs(self.enemies) do
			if (self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") >= getCardsNum("Slash", enemy, self.player)) and
				self:hasTrickEffective(duel, enemy, self.player) and
				self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) and self:canAttack(enemy, self.player) then
				target = enemy
			end
		end
	end

	if target then
		local x = math.ceil(self.player:getHandcardNum() / 2)
		local unpreferedCards = {}
		local cards = sgs.QList2Table(self.player:getHandcards())
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,card)
				then
					if self:aiUseCard(card).card then
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
			if card:isKindOf("Weapon") and self.player:getHandcardNum()<3
			or self:getSameEquip(card,self.player)
			or card:isKindOf("OffensiveHorse")
			or card:isKindOf("AmazingGrace")
			then table.insert(unpreferedCards,card:getId())
			elseif card:getTypeId()==sgs.Card_TypeTrick then
				if not self:aiUseCard(card).card then table.insert(unpreferedCards,card:getId()) end
			end
		end

		local use_cards = {}
		for i = #unpreferedCards,1,-1 do
			if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
			if #use_cards==x then break end
		end
		if #use_cards==x then
			use.card = sgs.Card_Parse("#kehejiuxian:"..table.concat(use_cards,"+")..":")
			if use.to then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_skill_playerchosen.kehejiuxian = function(self,targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets,"hp")
	for _,p in ipairs(targets)do
		if self:isFriend(p) and p:getHp() < getBestHp(p) then
			return p
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.kehejiuxian = -50


sgs.ai_skill_invoke.keheguangao = function(self,data)
	local target = self.room:findPlayerByObjectName(data:toString():split(":")[2])
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	if self:isFriend(target) and (target:getHandcardNum()% 2 == 0 or  self:needToLoseHp(target,self.player, use.card) ) and sgs.ai_role[self.player:objectName()] ~= "neutral"  then
		self.room:setPlayerFlag(target, "keheguangao")
		return true 
	end
	if self:isEnemy(target) and target:getHandcardNum()% 2 == 0 and self:slashIsEffective(use.card, target) and self:isGoodTarget(target, self.enemies, use.card) then
		self.room:setPlayerFlag(target, "keheguangao")
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.keheguangao = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local use = self.room:getTag("CurrentUseStruct"):toCardUse()
		local target
		for _,p in sgs.qlist(use.to) do
			if p:hasFlag("keheguangao") then
				self.room:setPlayerFlag(p, "-keheguangao")
				target = p
                break
			end
		end
		if not target then return end
		if not self:needToLoseHp(target,player) and target:getHandcardNum()% 2 ~= 0  then
			sgs.updateIntention(player,target,80)
		else
			sgs.updateIntention(player,target,-80)
		end
	end
end

sgs.ai_target_revises.keheguangao = function(to,card, self)
	if card:isKindOf("Slash") and to:getHandcardNum()% 2 == 0 and not self:isFriend(to)
	then return true end
end

sgs.ai_skill_playerschosen.keheguangao = function(self,targets,max,min)
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
	local tos = {}
	for _, p in ipairs(targets) do
		if self:isFriend(p) and #tos<max then
			if not self:needToLoseHp(p,use.from) then 
				sgs.updateIntention(self.player,p,-80)
				table.insert(tos, p)
				break
			end
		elseif self:isEnemy(p) and self:findLeijiTarget(p, 50, use.from) and #tos<max then
			table.insert(tos, p)
		end
	end
	return tos
end


local kehexieju_skill = {}
kehexieju_skill.name = "kehexieju"
table.insert(sgs.ai_skills, kehexieju_skill)
kehexieju_skill.getTurnUseCard = function(self, inclusive)
	return sgs.Card_Parse("#kehexiejuCard:.:")
end

sgs.ai_skill_use_func["#kehexiejuCard"] = function(card, use, self)
	local targets = {}
	for _, friend in ipairs(self.friends) do
		if friend:getMark("kehexiejutar-Clear") > 0 then
			table.insert(targets, friend)
		end
	end
	if #targets > 0 then
		use.card = card
		if use.to then
			for _,to in sgs.list(targets)do
				use.to:append(to)
			end
		end
		return
	end
end
sgs.ai_card_intention.kehexiejuCard = -80

sgs.ai_skill_use["@@kehexiejuslash"] = function(self,prompt,method)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards,nil,true)
	local eCard
	if self:needToThrowArmor() and self.player:getArmor():isBlack() then
		eCard = self.player:getArmor()
	end
	for _,card in ipairs(cards)do
		if eCard then break end
		if card:isBlack()
		then eCard = card end
	end
	if not eCard then return "." end
	local slash = dummyCard()
	slash:setSkillName("_kehexieju")
	slash:addSubcard(eCard:getEffectiveId())
	local dummy = self:aiUseCard(slash)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return ("slash:kehexieju[%s:%s]=%d->%s"):format(eCard:getSuitString(),eCard:getNumberString(),eCard:getEffectiveId(),table.concat(tos,"+"))
	end
	return "."
end






