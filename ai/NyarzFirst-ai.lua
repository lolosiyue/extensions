--奇制
sgs.ai_skill_playerchosen.Dqizhi = function(self,targets)
	self:updatePlayers()

	if self.player:getJudgingArea():length() > 0 then return self.player end
	local targets = sgs.QList2Table(targets)
	for _,target in ipairs(targets)do
		if self:isFriend(target) and target:getJudgingArea():length() > 0 then return target end
	end
	return sgs.ai_skill_playerchosen.qizhi(self,targets)
end

--进趋

sgs.ai_skill_invoke.Djinqu = function(self, data)
	local player = self.player
    if (player:getMark("&Dqizhi-Clear") > 0) and (player:getMark("&Dqizhi-Clear") >= player:getHandcardNum()) then return true end
    return false 
end

--劫营

sgs.ai_skill_invoke.Godjieying = function(self, data)
	local player = self.player
    local target = player:getTag("jieyingtarget"):toPlayer()
    if self:isEnemy(target) then 
        return true
    else
        return false 
    end
end

sgs.ai_skill_playerchosen.Godjieying = function(self, targets)
	if self.player:getMark("&Godying") < 2 then return nil end
	for _,target in sgs.qlist(targets) do
		if self:isFriend(target) then
			return target
		end
	end
	if self.player:getMark("&Godying") < 3 then return nil end
	for _,target in sgs.qlist(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
	return nil
end

--魄袭

local Godpoxi_skill = {}
Godpoxi_skill.name = "Godpoxi"
table.insert(sgs.ai_skills, Godpoxi_skill)
Godpoxi_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#Godpoxi") then
		return sgs.Card_Parse("#Godpoxi:.:")
	end
end

sgs.ai_skill_use_func["#Godpoxi"] = function(card, use, self)
	self:updatePlayers()
	if #self.enemies <= 0 then return end
	local target = nil
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies) do
		--if self:doNotDiscard(p, "h") then continue end
		if p:getHandcardNum() == 0 then continue end
		target = p
		break
	end
	if not target then return end
	if target then
		local card_str = "#Godpoxi:.:->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_use["@@Godpoxi"] = function(self, prompt)
	local target = self.player:getTag("godpoxi"):toPlayer()
	if target then
		local target_handcards = sgs.QList2Table(target:getCards("h"))
		self:sortByUseValue(target_handcards, inverse)
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		local discard_cards = {}
		local spade_check = true
		local heart_check = true
		local club_check = true
		local diamond_check = true
		local target_discard_count = 0
		
		for _, c in ipairs(target_handcards) do
			if spade_check and c:getSuit() == sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards, c:getEffectiveId())
			elseif heart_check and c:getSuit() == sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards, c:getEffectiveId())
			elseif club_check and c:getSuit() == sgs.Card_Club then
				club_check = false
				table.insert(discard_cards, c:getEffectiveId())
			elseif diamond_check and c:getSuit() == sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards, c:getEffectiveId())
			end
			target_discard_count = #discard_cards
		end
		
		for _, c in ipairs(handcards) do
			if not c:isKindOf("Peach")
			and not c:isKindOf("Duel")
			and not c:isKindOf("Indulgence")
			and not c:isKindOf("SupplyShortage")
			and not (self:getCardsNum("Jink") == 1 and c:isKindOf("Jink"))
			and not (self:getCardsNum("Analeptic") == 1 and c:isKindOf("Analeptic"))
			then
				if spade_check and c:getSuit() == sgs.Card_Spade then
					spade_check = false
					table.insert(discard_cards, c:getEffectiveId())
				elseif heart_check and c:getSuit() == sgs.Card_Heart then
					heart_check = false
					table.insert(discard_cards, c:getEffectiveId())
				elseif club_check and c:getSuit() == sgs.Card_Club then
					club_check = false
					table.insert(discard_cards, c:getEffectiveId())
				elseif diamond_check and c:getSuit() == sgs.Card_Diamond then
					diamond_check = false
					table.insert(discard_cards, c:getEffectiveId())
				end
			end
		end
		
		--if target_discard_count == 4 and not self.player:isWounded() then return "." end
		if ((4 - target_discard_count) == 0) and self.player:getHandcardNum() > self.player:getMaxCards() then return "." end
		
		if #discard_cards == 4 then
			return "#GodpoxidisCard:"..table.concat(discard_cards, "+")..":"
			--string.format("#GodpoxidisCard:%s:.:", table.concat(discard_cards, "+"))
		end
	end
	return "."
end

sgs.ai_use_priority.Godpoxi = 3
sgs.ai_use_value.Godpoxi = 3
sgs.ai_card_intention.Godpoxi = 50

--称象

sgs.ai_skill_invoke.exchengxiang = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.exchengxiang = function(self, targets)
    for _,target in sgs.qlist(targets) do
		if self:isFriend(target) and target:isWounded() then
			return target
		end
	end
    for _,target in sgs.qlist(targets) do
		if self:isFriend(target) then
			return target
		end
	end
    return nil
end

sgs.ai_playerchosen_intention.exchengxiang = function(self, from, to)
	sgs.updateIntention(from, to, -80)
end

sgs.ai_skill_use["@@exchengxiang"] = function(self, prompt)
	local card_ids = self.player:getTag("chengxiangcards"):toIntList()
	local getcards = {}
	local sum = 0
	for _,id in sgs.qlist(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("EquipCard") or (card:objectName() == "peach") or (card:objectName() == "analeptic") then
			if (card:getNumber() + sum) <= 13 then
				table.insert(getcards,id)
				sum = sum + card:getNumber()
			end
		end
	end
	for _,id in sgs.qlist(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if ((card:getNumber() + sum) <= 13) and (not table.contains(getcards,id)) then
			table.insert(getcards,id)
			sum = sum + card:getNumber()
		end
	end
	local card_str = "#exchengxiang:"..table.concat(getcards, "+")..":"
	return card_str
end

sgs.ai_can_damagehp.exchengxiang = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end

--仁心

sgs.ai_skill_invoke.exrenxin = function(self, data)
	local target = self.player:getTag("renxintarget"):toPlayer()
    if self:isFriend(target) then return true end
    if target:objectName() == self.player:objectName() then return true end
    return false
end

--龙魂
 
local LuaLonghun_skill={}
LuaLonghun_skill.name="LuaLonghun"
table.insert(sgs.ai_skills, LuaLonghun_skill)
LuaLonghun_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Diamond and self:slashIsAvailable() then
			return sgs.Card_Parse(("fire_slash:longhun[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
		end
	end
end

sgs.ai_view_as.LuaLonghun = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceSpecial then return end
	if card:getSuit() == sgs.Card_Diamond then
		return ("fire_slash:longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Club then
		return ("jink:longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Heart and player:getMark("Global_PreventPeach") == 0 then
		return ("peach:longhun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Spade then
		return ("nullification:longhun[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.LuaLonghun_suit_value = {
	heart = 6.7,
	spade = 5,
	club = 4.2,
	diamond = 3.9,
}

function sgs.ai_cardneed.LuaLonghun(to, card, self)
	if to:getCardCount() > 3 then return false end
	if to:isNude() then return true end
	return card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Spade
end

--绝情

sgs.ai_skill_invoke.exjueqing = function(self, data)
	local player = self.player
    local target = player:getTag("exjueqingta"):toPlayer()
    if self:isEnemy(target) then 
        return true
    else
        return false 
    end
end

sgs.ai_getLeastHandcardNum_skill.exshangshi = function(self, player, least)
	local x = math.max(player:getLostHp(), 1)
	if least < x then
		return x
	end
end

--刃仇

local renchou_skill = {}
renchou_skill.name = "renchou"
table.insert(sgs.ai_skills, renchou_skill)
renchou_skill.getTurnUseCard = function(self, inclusive)
	local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	card:deleteLater()
	if not self.player:isCardLimited(card, sgs.Card_MethodUse) then
		return sgs.Card_Parse("#renchou:.:")
	end
end

sgs.ai_skill_use_func["#renchou"] = function(card, use, self)
	local target = nil
	self:sort(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
        card:setSkillName("renchou")
	for _, enemy in ipairs(self.enemies) do
		if  (((self.player:getHandcardNum() == enemy:getHandcardNum() and self.player:getHp() ~= enemy:getHp()) 
		or (self.player:getHandcardNum() ~= enemy:getHandcardNum() and self.player:getHp() == enemy:getHp()))) and self:slashIsEffective(card, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, card) then
			use.card = card
			target = enemy
		end
	end
	if target then
		local card_str = "#renchou:.:->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

--望归

sgs.ai_skill_playerchosen.dwanggui = function(self, targets)
	--伤害
	if self.player:getMark("dwangguida") > 0 then
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and not self:cantbeHurt(p) and self:damageIsEffective(p) and self:canDamage(p,self.player,nil) then 
				return p
			end
		end
		return nil
	else
		local p = nil
		local hand = 999
		for _,ta in sgs.qlist(targets) do
			if self:isFriend(ta) and (ta:getHandcardNum() < hand) and (ta:objectName() ~= self.player:objectName()) then
				p = ta
				hand = ta:getHandcardNum()
			end
		end
		if p then 
			return p
		else
			return self.player
		end
	end
end

--息兵

sgs.ai_skill_invoke.dxibin = function(self, data)
	local player = self.player
    local target = player:getTag("dxibinta"):toPlayer()
    if self:isEnemy(target) then 
		if target:getHandcardNum() >= target:getHp() then
        	return true
		elseif target:getHandcardNum() < target:getHp() then
			local draw = target:getHp() - target:getHandcardNum()
			if draw >= 3 then return false end
			return true
		end
    elseif self:isFriend(target) then
        if (target:getHandcardNum() + 2) < target:getHp() then
			for _,card in sgs.qlist(target:getHandcards()) do
				if card:isAvailable(target) then return false end
			end
			return true
		end
    end
	return false
end

--评鉴

local pingjianex_skill = {}
pingjianex_skill.name = "pingjianex"
table.insert(sgs.ai_skills, pingjianex_skill)
pingjianex_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#pingjianex") then
		return sgs.Card_Parse("#pingjianex:.:")
	end
end

sgs.ai_skill_use_func["#pingjianex"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_invoke.pingjianex = function(self, data)
	return true
end

--图射

sgs.ai_skill_invoke.Dtushe = function(self, data)
	if self.player:getPhase() == sgs.Player_NotActive then return true end
	if self.player:getMark("dtushe") >= 2 then return true end
	local can = true
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do
		if card:isKindOf("BasicCard") then 
			can = false 
			break
		end
	end
	local slash = 0
	local more = 0
	local mm = {"amazing_grace", "savage_assault", "archery_attack", "god_salvation"}
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then 
			slash = slash + 1
		end
		if table.contains(mm,card:objectName()) then
			more = more + 1
		end
	end
	if slash == 0 and more == 0 then return true end
	return can
end

--立牧

sgs.ai_skill_invoke.Dlimu = true

local Dlimu_skill = {}
Dlimu_skill.name = "Dlimu"
table.insert(sgs.ai_skills, Dlimu_skill)
Dlimu_skill.getTurnUseCard = function(self, inclusive)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	local slash = 0
	local red = 0
	local black = 0
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then 
			slash = slash + 1
		end
		if card:isRed() then
			red = red + 1
		end
		if card:isBlack() then
			black = black + 1
		end
	end
	if (slash >= 2 and (not self.player:containsTrick("supply_shortage")) and black > 0)  then
		return sgs.Card_Parse("#Dlimu:.:")
	elseif self.player:getHp() == 1 and red > 0 and (not self.player:containsTrick("indulgence")) 
	or ((not self.player:containsTrick("indulgence")) and slash >= 4 and red > 0 and (not self.player:containsTrick("supply_shortage"))) then
		return sgs.Card_Parse("#Dlimu:.:")
	end
end

sgs.ai_skill_use_func["#Dlimu"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	local slash = 0
	local red = 0
	local black = 0
	for _, cc in ipairs(cards) do
		if cc:isKindOf("Slash") then 
			slash = slash + 1
		end
		if cc:isRed() then
			red = red + 1
		end
		if cc:isBlack() then
			black = black + 1
		end
	end
	local usecard = nil
	if slash >= 2 and (not self.player:containsTrick("supply_shortage")) and black > 0 then
		for _, cc in ipairs(cards) do
			if cc:isBlack() then
				usecard = cc
				break
			end
		end
	elseif (self.player:getHp() == 1 and red > 0 and (not self.player:containsTrick("indulgence"))) 
	or ((not self.player:containsTrick("indulgence")) and slash >= 4 and red > 0 and (not self.player:containsTrick("supply_shortage")))then
		for _, cc in ipairs(cards) do
			if cc:isRed() then
				usecard = cc
				break
			end
		end
	end
	if usecard then
		local target = self.player
		local card_str = string.format("#Dlimu:%d:->%s", usecard:getId(), target:objectName())
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.Dlimu = 7
sgs.double_slash_skill = sgs.double_slash_skill .. "|Dlimu"

--夺锐

sgs.ai_skill_invoke.spduorui = function(self, data)
	local ta = self.player:getTag("duoruita"):toPlayer()
	if self:isEnemy(ta) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.spduorui = function(self,player,promptlist)
	local target = player:getTag("duoruita"):toPlayer()
	if target then
		if promptlist[#promptlist]=="yes" then
			sgs.updateIntention(player,target,80)
		else
			sgs.updateIntention(player,target,-10)
		end
	end
end

--锋影

sgs.ai_skill_use["@@gfengying"] = function(self, prompt)
	if self.player:getHandcardNum() < 2 then return "." end
	local handcards = self.player:getCards("he")
	handcards = sgs.QList2Table(handcards)
	self:sortByKeepValue(handcards)
	local card = handcards[1] 
	self:sort(self.enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
	slash:setSkillName("gfengying")
	slash:addSubcard(card)
	slash:deleteLater()
	local target = nil
	for _,enemy in ipairs(self.enemies) do
		if enemy:isAlive() and self.player:canSlash(enemy, slash, false) and not self:slashProhibit(slash, enemy)
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then 
			target = enemy
			break
		end
	end
	if target then
		local card_str = string.format("#gfengying:%d:->%s", card:getId(), target:objectName())
		return card_str
	else
		return "."
	end
end

sgs.ai_card_intention.gfengying = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		sgs.updateIntention(from, to, 40)
	end
end

--虚尊

sgs.ai_skill_invoke.xuzun = function(self, data)
	if self.player:getHandcardNum() <= self.player:getMaxHp() then return true end
	return false
end

--余怨

sgs.ai_skill_use["@@dyuyuan"] = function(self, prompt)
	if self.player:getHandcardNum() <= self.player:getMaxCards() then return "." end
	local handcards = self.player:getCards("h")
	handcards = sgs.QList2Table(handcards)
	if #handcards == 0 then return "." end
	if self.player:getPhase() == sgs.Player_Play then
		self:sortByUseValue(handcards, true)
		if #handcards == 1 then return "." end
	else
		self:sortByKeepValue(handcards, true)
	end
	local card = handcards[1] 

	self:sort(self.friends, "defense")
	local target = nil
	for _,friend in ipairs(self.friends) do
		if friend:isAlive() and friend:getMark("dyuyuan") == 0 and (self.player:objectName() ~= friend:objectName()) then 
			target = friend
			break
		end
	end

	if not target and self.player:getHandcardNum() > 3 and self.player:getPhase() == sgs.Player_Play then
		self:sort(self.enemies, "defense")
		for _,enemy in ipairs(self.enemies) do
			if enemy:isAlive() and enemy:getMark("dyuyuan") == 0 and (enemy:getMark("dyuyuan"..self.player:objectName()) < enemy:getHp()) then 
				target = enemy
				break
			end
		end
	end

	if target then
		if self:isEnemy(target) then
			local card_str = string.format("#dyuyuan:%d:->%s", card:getId(), target:objectName())
			return card_str
		elseif self:isFriend(target) then
			if (self.player:getHandcardNum() > (self.player:getMaxCards() + 1)) and (#handcards >= 2) then
				local cards = {}
				table.insert(cards, handcards[1]:getEffectiveId())
				table.insert(cards, handcards[2]:getEffectiveId())
				local card_str = string.format("#dyuyuan:%s:->%s", table.concat(cards,"+"), target:objectName())
				return card_str
			else
				local card_str = string.format("#dyuyuan:%d:->%s", card:getId(), target:objectName())
				return card_str
			end
		end
	else
		return "."
	end
end

sgs.ai_skill_playerchosen.dyuyuan = function(self, targets)
	local max = -1
	local target = nil
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) and p:getMark("dyuyuan"..self.player:objectName()) > max and self:damageIsEffective(p) and not self:cantDamageMore(self.player, p) and self:canDamage(p,self.player,nil) then 
			max = p:getMark("dyuyuan"..self.player:objectName())
			target = p
		end
	end
	return target
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|dyuyuan"
function sgs.ai_slash_prohibit.dyuyuan(self,from,to)
	if hasJueqingEffect(from,to) or (from:hasSkill("nosqianxi") and from:distanceTo(to)==1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:getHp()>1 or #(self:getEnemies(from))==1 then return false end
	if from:getMaxHp()==3 and from:getArmor() and from:getDefensiveHorse() then return false end
	if from:getMaxHp()<=3 or (from:isLord() and self:isWeak(from)) then return true end
	if from:getMaxHp()<=3 or (self.room:getLord() and from:getRole()=="renegade") then return true end
	return false
end

--烈弓（神黄忠）

sgs.ai_skill_playerchosen.Gliegong = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention.Gliegong = function(self, from, to)
	sgs.updateIntention(from, to, 200)
end

--破势

sgs.ai_skill_invoke.Gposhi = function(self, data)
	local ta = self.player:getTag("Gposhi"):toPlayer()
	if self:isEnemy(ta) then 
		return true
	else
		return false
	end
end
sgs.hit_skill = sgs.hit_skill .. "|Gposhi"
sgs.ai_cardneed.Gposhi = sgs.ai_cardneed.slash

--权计

sgs.ai_skill_invoke.exquanji = true
sgs.ai_can_damagehp.exquanji = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
	and self:canLoseHp(from,card,to)
end

--自立

sgs.ai_skill_choice["ziliex"] = function(self, choices, data)
	if self.player:getLostHp() > 1 then 
		return "recover"
	else
		return "draw"
	end
end

--排异

sgs.ai_skill_invoke.paiyiex = true

local paiyiex_skill = {}
paiyiex_skill.name = "paiyiex"
table.insert(sgs.ai_skills, paiyiex_skill)
paiyiex_skill.getTurnUseCard = function(self, inclusive)
	if (not self.player:hasUsed("#paiyiex")) and (self.player:getPile("exquan"):length() > 0 )  then
		return sgs.Card_Parse("#paiyiex:.:")
	end
end

sgs.ai_skill_use_func["#paiyiex"] = function(card, use, self)
	local card_ids = self.player:getPile("exquan")
	local usecard = nil
	for _,id in sgs.qlist(card_ids) do
		usecard = sgs.Sanguosha:getCard(id)
		break
	end

	local target = nil
	if self.player:getPile("exquan"):length() <= 2 then
		self:sort(self.enemies, "defense")
		self.enemies = sgs.reverse(self.enemies)
		for _,enemy in ipairs(self.enemies) do
			if (enemy:getHandcardNum() + self.player:getPile("exquan"):length() - 1) > self.player:getHandcardNum() then
				target = enemy
				break
			end
		end
	end
	if not target then
		self:sort(self.friends, "defense")
		self.friends = sgs.reverse(self.friends)
		for _,friend in ipairs(self.friends) do
			if (friend:getHandcardNum() + self.player:getPile("exquan"):length() - 1) <= self.player:getHandcardNum() then
				target = friend
				break
			end
		end
	end
	if not target then target = self.player end
	local card_str = string.format("#paiyiex:%d:->%s", usecard:getId(), target:objectName())
	local acard = sgs.Card_Parse(card_str)
	assert(acard)
	use.card = acard
	if use.to then
		use.to:append(target)
	end
end

sgs.ai_card_intention["#paiyiex"] = function(self, card, from ,tos)
	for _,to in sgs.qlist(tos) do
		if from:getPile("exquan"):length() <= 2 then
			sgs.updateIntention(from, to, 30)
		else
			sgs.updateIntention(from, to, -50)
		end
	end
end

sgs.ai_use_priority["#paiyiex"] = 3

--力激

local Diyliji_skill = {}
Diyliji_skill.name = "Diyliji"
table.insert(sgs.ai_skills, Diyliji_skill)
Diyliji_skill.getTurnUseCard = function(self, inclusive)
	if (self.player:getMark("&Diyliji-Clear") > 0) and (self.player:canDiscard(self.player, "he")) then
		return sgs.Card_Parse("#DiylijiCard:.:")
	end
end

sgs.ai_skill_use_func["#DiylijiCard"] = function(card, use, self)
	local handcards = self.player:getCards("he")
	handcards = sgs.QList2Table(handcards)
	self:sortByKeepValue(handcards)
	local usecard = nil
	usecard = handcards[1]
	self:sort(self.enemies, "defense")
	local target = self.enemies[1]
	if target then
		local card_str = string.format("#DiylijiCard:%d:->%s", usecard:getId(), target:objectName())
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.Diyliji = 5

--涉猎

sgs.ai_skill_invoke.godshelie = true

sgs.ai_skill_discard.godshelie = function(self,max,min)
	local player = self.player
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local dis = {}
	if #cards >= 2 then
		table.insert(dis, cards[1]:getEffectiveId())
		table.insert(dis, cards[2]:getEffectiveId())
	end
	return dis
end

sgs.ai_skill_choice["godshelie"] = function(self, choices, data)
	if self.player:getHandcardNum() > 3 then 
		return "play"
	else
		return "draw"
	end
end

--攻心

local godgongxin_skill = {}
godgongxin_skill.name = "godgongxin"
table.insert(sgs.ai_skills, godgongxin_skill)
godgongxin_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#godgongxin") then
		return sgs.Card_Parse("#godgongxin:.:")
	end
end

sgs.ai_skill_use_func["#godgongxin"] = function(card, use, self)
	self:updatePlayers()
	if #self.enemies <= 0 then return end
	local target = nil
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies) do
		--if self:doNotDiscard(p, "h") then continue end
		target = p
		break
	end
	if not target then return end
	if target then
		local card_str = "#godgongxin:.:->"..target:objectName()
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_use["@@godgongxin"] = function(self, prompt)
	local target = self.player:getTag("godgongxin"):toPlayer()
	if target then
		local target_handcards = sgs.QList2Table(target:getCards("h"))
		self:sortByUseValue(target_handcards, inverse)
		local discard_cards = {}
		local color = nil
		local n = 0
		for _,card in ipairs(target_handcards) do
			if n == 0 then
				table.insert(discard_cards,card:getEffectiveId())
				if card:isRed() then 
					color = "red"
				elseif card:isBlack() then
					color = "black"
				end
				n = n + 1
			elseif card:isRed() and color == "red" then
				table.insert(discard_cards,card:getEffectiveId())
				n = n + 1
			elseif card:isBlack() and color == "black" then
				table.insert(discard_cards,card:getEffectiveId())
				n = n + 1
			end
			if n == 2 then break end
		end
		if n > 0 then
			return "#godgongxindisCard:"..table.concat(discard_cards, "+")..":"
		end
	end
	return "."
end

sgs.ai_use_priority.godgongxin = 3
sgs.ai_use_value.godgongxin = 3
sgs.ai_card_intention.godgongxin = 50

--推锋

local extuifeng_skill = {}
extuifeng_skill.name = "extuifeng"
table.insert(sgs.ai_skills, extuifeng_skill)
extuifeng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:canDiscard(self.player, "he") and self.player:getMark("&extuifeng") > 0 then
		return sgs.Card_Parse("#extuifengCard:.:")
	end
end

sgs.ai_skill_use_func["#extuifengCard"] = function(card, use, self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if #cards > 0 then
		local card_str = string.format("#extuifengCard:%d:", cards[1]:getEffectiveId())
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
	end
end

--枪舞

local exqiangwu_skill = {}
exqiangwu_skill.name = "exqiangwu"
table.insert(sgs.ai_skills, exqiangwu_skill)
exqiangwu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#exqiangwu") then
		return sgs.Card_Parse("#exqiangwu:.:")
	end
end

sgs.ai_skill_use_func["#exqiangwu"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_discard.exqiangwu = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local to_discard = {}
	local min = 13
	local slash = 0
	for _,card in ipairs(cards) do
		if card:isKindOf("Slash") then
			slash = slash + 1
			if card:getNumber() <= 13 then min = card:getNumber() end
		end
	end
	if slash >= 2 then
		for _,card in ipairs(cards) do
			if card:getNumber() <= min then 
				table.insert(to_discard,card:getEffectiveId())
				break
			end
		end
	end
	return to_discard
end

sgs.ai_use_priority.exqiangwu = 8

--隅泣

sgs.ai_skill_invoke.spyuqi = true

sgs.ai_skill_use["@@spyuqi"] = function(self, prompt)
	local card_ids = self.player:getTag("spyuqicc"):toIntList()
	local getcards = {}
	local choices = {}
	for _,id in sgs.qlist(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(choices,card)
	end
	self:sortByKeepValue(choices)
	local target = self.player:getTag("spyuqita"):toPlayer()
	if (not self:isFriend(target)) then
		table.insert(getcards,choices[1]:getEffectiveId())
	elseif self:isFriend(target) and self.player:objectName() ~= target:objectName() then
		table.insert(getcards,choices[1]:getEffectiveId())
		table.insert(getcards,choices[2]:getEffectiveId())
	elseif self.player:objectName() == target:objectName() then
		for _,card in ipairs(choices) do
			table.insert(getcards,card:getEffectiveId())
		end
	end
	local card_str = "#spyuqi:"..table.concat(getcards, "+")..":"
	return card_str
end

sgs.ai_can_damagehp.spyuqi = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end


--娴静

sgs.ai_skill_invoke.spxianjin = true

sgs.ai_skill_playerchosen.spxianjin = function(self, targets)
	local min = 999
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHandcardNum() < min then
			min = p:getHandcardNum()
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHandcardNum() == min then
			return p
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.spxianjin = function(self, from, to)
	sgs.updateIntention(from, to, -40)
end

--善身
sgs.ai_skill_invoke.spshanshen = true

sgs.ai_skill_playerchosen.spshanshen = function(self, targets)
	local min = 999
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHandcardNum() < min then
			min = p:getHandcardNum()
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHandcardNum() == min then
			return p
		end
	end
	return self.player
end

sgs.ai_playerchosen_intention.spshanshen = function(self, from, to)
	sgs.updateIntention(from, to, -40)
end

--韶颜

sgs.ai_skill_invoke.shaoyan = true

--同心

local jitongxin_skill = {}
jitongxin_skill.name = "jitongxin"
table.insert(sgs.ai_skills, jitongxin_skill)
jitongxin_skill.getTurnUseCard = function(self, inclusive)
	local can = false
	if self.player:getChangeSkillState("jitongxin") <= 1 then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not p:isKongcheng() then 
				can = true 
				break
			end
		end
	elseif self.player:getChangeSkillState("jitongxin") == 2 then
		if self.player:getHandcardNum() >= 2 then
			can = true
		end
	end
	if self.player:getMark("jitongxin-PlayClear") == 0 and can then
		return sgs.Card_Parse("#jitongxin:.:")
	end
end

sgs.ai_skill_use_func["#jitongxin"] = function(card, use, self)
	if self.player:getChangeSkillState("jitongxin") <= 1 then
		local target = nil
		self:sort(self.enemies, "handcard")
		self.enemies = sgs.reverse(self.enemies)
		for _,p in ipairs(self.enemies) do
			if p:getHandcardNum() > 0 then
				target = p
				break
			end
		end
		if not target then
			self:sort(self.friends, "handcard")
			for _,p in ipairs(self.friends) do
				if p:getHandcardNum() > 0 and p:objectName() ~= self.player:objectName() then
					target = p
					break
				end
			end
		end
		local card_str = string.format("#jitongxin:.:->%s",target:objectName())
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end

	if self.player:getChangeSkillState("jitongxin") == 2 then
		local target = nil
		local usecard = nil
		local handcards = self.player:getCards("h")
		handcards = sgs.QList2Table(handcards)
		self:sortByKeepValue(handcards)
		local usecard = nil
		for _,card in ipairs(handcards) do
			usecard = card
			break
		end
		self:sort(self.enemies, "defense")
			for _,p in ipairs(self.enemies) do
				if not self:cantbeHurt(p) and self:damageIsEffective(p) and self:canDamage(p,self.player,nil) then
					target = p
					break
				end
			end
		if not target then
			self:sort(self.friends, "hp")
			for _,p in ipairs(self.friends) do
				if p:objectName() ~= self.player:objectName() then
					target = p
					break
				end
			end
		end
		if target and usecard then
			local card_str = string.format("#jitongxin:%d:->%s", usecard:getId(), target:objectName())
			local acard = sgs.Card_Parse(card_str)
			assert(acard)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_skill_use["@@jitongxin"] = function(self, prompt)
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("jitongxindraw") and self:isFriend(p) then
			local card_str = "#jitongxinelse:.:"
			return card_str
		end
		if p:hasFlag("jitongxinda") and not self:cantbeHurt(p) and self:damageIsEffective(p) and self:canDamage(p,self.player,nil)  then
			local card_str = "#jitongxinelse:.:"
			return card_str
		end
	end
	return "."
end

sgs.ai_use_priority.jitongxin = 10

--激昂

sgs.ai_skill_invoke.spjiang = true

local spjiang_skill = {}
spjiang_skill.name = "spjiang"
table.insert(sgs.ai_skills, spjiang_skill)
spjiang_skill.getTurnUseCard = function(self, inclusive)
	if (self.player:getHandcardNum() > 1) and (not self.player:hasUsed("#spjiang")) and ((self.player:getHp() > 1 and self.player:getMark("sphunzi") > 0) or (self.player:getMark("sphunzi") ==0)) then
		return sgs.Card_Parse("#spjiang:.:")
	end
end

sgs.ai_skill_use_func["#spjiang"] = function(card, use, self)
	local handcards = self.player:getCards("h")
	handcards = sgs.QList2Table(handcards)
	self:sortByKeepValue(handcards)
	local usecard = {}
	local n = self.player:getHandcardNum()
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
	duel:setSkillName("spjiang")
	duel:deleteLater()
	n = math.ceil(n/2)
	for _,card in ipairs(handcards) do
		table.insert(usecard,card:getEffectiveId())
		duel:addSubcard(card)
		n = n - 1
		if n <= 0 then break end
	end
	self:sort(self.enemies, "defense")
	
	
	local target
	local dummy_use = self:aiUseCard(duel, dummy())
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			target = p
		end
	end
	--local target = self.enemies[1]
	if target then
		local card_str = string.format("#spjiang:%s:->%s", table.concat(usecard,"+"), target:objectName())
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority.spjiang = 4

sgs.ai_canNiepan_skill.sphunzi = function(player)
	return player:hasLordSkill("sphunzi") and player:getMark("sphunzi") == 0
end

--英姿

sgs.ai_skill_invoke.spyingzi = true

--英魂

sgs.ai_skill_playerchosen.spyinghun = function(self, targets)
	if self.player:getLostHp() <= 1 then
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and p:getHandcardNum() >= 1 then
				return p
			end
		end
	end
	if self.player:getLostHp() > 1 then
		local n = -1
		local target = nil
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and ((p:getHandcardNum() < n) or n < 0) then
				n = p:getHandcardNum()
				target = p
			end
		end
		if target then return target end
		n = -1
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and ((p:getHandcardNum() < n) or n < 0) then
				n = p:getHandcardNum()
				target = p
			end
		end
		if target then return target end
		return self.player
	end
end

sgs.ai_skill_choice["spyinghun"] = function(self, choices, data)
	local target = self.player:getTag("spyinghun"):toPlayer()
	choices = choices:split("+")
	if self:isFriend(target) then 
		for _,choice in ipairs(choices) do
			if string.find(choice,"draw") then
				return choice
			end
		end
	elseif self:isEnemy(target) then
		for _,choice in ipairs(choices) do
			if string.find(choice,"dis") then
				return choice
			end
		end
	elseif self.player:objectName() == target:objectName() then
		for _,choice in ipairs(choices) do
			if string.find(choice,"draw") then
				return choice
			end
		end
	end
end

--方统

local function fangtongca(tasum, card_ids)
	local sum = 0
	local usecards = {}
	if card_ids:length() > 30 then
		for _,id in sgs.qlist(card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if (card:getNumber() + sum) <= tasum then
				table.insert(usecards,id)
				sum = sum + card:getNumber()
			end
		end
	else
		local n = card_ids:length()
		local allcards = {}
		for _,id in sgs.qlist(card_ids) do
			table.insert(allcards, id)
		end
		for i = 1, 2^n, 1 do
			sum = 0
			usecards = {}
			for j = 1, n, 1 do
				if bit32.band(i,(2^j)) ~= 0 then
					table.insert(usecards,allcards[j])
				end
			end
			for _,id in ipairs(usecards) do
				sum = sum + sgs.Sanguosha:getCard(id):getNumber()
			end
			if sum == tasum then break end
		end
	end

	if sum == tasum then 
		return usecards
	else
		return {}
	end
end

sgs.ai_skill_use["@@exfangtong"] = function(self, prompt)
	if self.player:isNude() then return "." end
	local card_ids = self.player:getPile("exfang")
	local allcards = {}
	local sum = 0
	local n = 0
	for _,id in sgs.qlist(card_ids) do
		sum = sum + sgs.Sanguosha:getCard(id):getNumber()
		table.insert(allcards,id)
		n = n + 1
	end
	if sum < 23 then return "." end

	self:sort(self.enemies, "defense")
	local target = nil
	for _,enemy in ipairs(self.enemies) do
		if enemy:isAlive() and not self:cantDamageMore(self.player, enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) then 
			target = enemy
			break
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if enemy:isAlive() and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) then 
				target = enemy
				break
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if enemy:isAlive() then 
				target = enemy
				break
			end
		end
	end

	if not target then return "." end

	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local usecards = {}
	for _,card in ipairs(cards) do
		sum = 0
		local tem = 36 - card:getNumber()
		usecards = fangtongca(tem,card_ids)
		if #usecards > 0 then
			table.insert(usecards,card:getEffectiveId())
		end
		for _,c in ipairs(usecards) do
			sum = sum + sgs.Sanguosha:getCard(c):getNumber()
		end
		if sum == 36 then break end
	end
	
	if sum ~= 36 then return "." end

	local card_str = "#exfangtongCard:"..table.concat(usecards, "+")..":->"..target:objectName()
	return card_str
end

--极略

local spjilve_skill = {}
spjilve_skill.name = "spjilve"
table.insert(sgs.ai_skills, spjilve_skill)
spjilve_skill.getTurnUseCard = function(self, inclusive)
	if (not self.player:hasUsed("#spjilve")) and (self.player:getMark("&spren") > 0) then
		return sgs.Card_Parse("#spjilve:.:")
	end
end

sgs.ai_skill_use_func["#spjilve"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority.spjilve = 6
sgs.ai_use_value.spjilve = 6

sgs.ai_skill_playerchosen.spjilve = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and (not p:faceUp()) then
			return p
		end
	end
	self:sort(self.enemies, "defense")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in ipairs(self.enemies) do
		if p:faceUp() then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention.spjilve = function(self, from, to)
	if to:faceUp() then
		sgs.updateIntention(from, to, 80)
	else
		sgs.updateIntention(from, to, -80)
	end
end

sgs.ai_skill_invoke.spjilve = function(self,data)
	if self.player:getMark("spjilvejudge") > 0 then
		if self.player:getMark("&spren") < 3 then return false end
		local judge = self.player:getTag("spjilvejudge"):toJudge()
		local can = false
		if judge.reason == "indulgence" then
			if self:isFriend(judge.who) and judge.card:getSuitString() ~= "heart" then
				can = true
			elseif self:isEnemy(judge.who) and judge.card:getSuitString() == "heart" then
				can = true
			end
		elseif judge.reason == "supply_shortage" then
			if self:isFriend(judge.who) and judge.card:getSuitString() ~= "club" then
				can = true
			elseif self:isEnemy(judge.who) and judge.card:getSuitString() == "club" then
				can = true
			end
		elseif judge.reason == "lightning" then
			if self:isFriend(judge.who) and judge.card:getSuitString() == "spade" and judge.card:getNumber() >= 2 and judge.card:getNumber() <= 9 then
				can = true
			elseif self:isEnemy(judge.who) and ((judge.card:getSuitString() ~= "spade") or (judge.card:getSuitString() == "spade" and (judge.card:getNumber() < 2 and judge.card:getNumber() > 9))) then
				can = true
			end
		elseif judge.reason == "eight_diagram" then
			if self:isFriend(judge.who) and judge.card:isBlack() then
				can = true
			elseif self:isEnemy(judge.who) and judge.card:isRed() then
				can = true
			end
		end
		return can 
	end

	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() <= 0 and self:isEnemy(p) then
			return true
		end
	end
	return false
end

sgs.ai_skill_choice["spjilve"] = function(self, choices, data)
	local judge = self.player:getTag("spjilvejudge"):toJudge()

	if judge.reason == "indulgence" then
		if self:isFriend(judge.who) and string.find(choices,"heart") then
			return "heart"
		elseif self:isEnemy(judge.who) and string.find(choices,"heart") then
			return "diamond"
		end
	elseif judge.reason == "supply_shortage" then
		if self:isFriend(judge.who) and string.find(choices,"club") then
			return "club"
		elseif self:isEnemy(judge.who) and string.find(choices,"club") then
			return "diamond"
		end
	elseif judge.reason == "lightning" then
		if self:isFriend(judge.who) and string.find(choices,"club") then
			return "diamond"
		elseif self:isEnemy(judge.who) and string.find(choices,"club") then
			return "spade"
		elseif self:isEnemy(judge.who) and string.find(choices,"5") then
			return "5"
		end
	elseif judge.reason == "eight_diagram" then
		if self:isFriend(judge.who) and string.find(choices,"diamond") then
			return "diamond"
		elseif self:isEnemy(judge.who) and string.find(choices,"club") then
			return "club"
		end
	end

	local canchoose = choices:split("+")
	return canchoose[1]
end

sgs.ai_need_damaged.spjilve = function (self, attacker, player)
	if not player:hasSkill("spjilve") then return end

	local will = false
	for _, p in ipairs(self.enemies) do
		if p:faceUp() then
			will = true
			break
		end
	end
	for _,p in ipairs(self.friends) do
		if not p:faceUp() then
			will = true
			break
		end
	end
	local n = self.player:getHp() + self:getCardsNum("Analeptic") + self:getCardsNum("Peach")

	return n > 2 and will
end

--忍戒

-- function SmartAI:needBear(player)
-- 	player = player or self.player
--     return player:hasSkills("sprenjie+spbaiyin") and player:getMark("spbaiyin") == 0 and player:getMark("&spren") < 4
-- end

--连破

sgs.ai_skill_choice["splianpo"] = function(self, choices, data)
	if self.player:getHp() == 1 then return "redr" end
	local canchoose = choices:split("+")
	return canchoose[1]
end

--平襄

local sppingxiang_skill = {}
sppingxiang_skill.name = "sppingxiang"
table.insert(sgs.ai_skills, sppingxiang_skill)
sppingxiang_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("sppingxiang") == 0 and self.player:getMaxHp() >= 10 then
		return sgs.Card_Parse("#sppingxiang:.:")
	elseif self.player:getMaxHp() > 4 and (not self.player:hasUsed("#sppingxiangSlash")) and self.player:getMark("sppingxiang") > 0 then
		return sgs.Card_Parse("#sppingxiangSlash:.:")
	end
end

sgs.ai_skill_use_func["#sppingxiang"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_use_func["#sppingxiangSlash"] = function(card, use, self)
	local qtargets = sgs.PlayerList()
    
    local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
    slash:setSkillName("sppingxiang")

	self:sort(self.enemies, "defense")
	local target = {}
	for _,enemy in ipairs(self.enemies) do
		if enemy:isAlive() and slash:targetFilter(qtargets, enemy, self.player) and (not self.player:isProhibited(enemy, slash, qtargets)) and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)  then 
			qtargets:append(enemy)
			table.insert(target,enemy:objectName())
		end
	end
	slash:deleteLater()
	if #target > 0 then
		local card_str = string.format("#sppingxiangSlash:.:->%s", table.concat(target,"+"))
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
		if use.to then
			use.to = qtargets
		end
	end
end

sgs.ai_skill_use["@@sppingxiang"] = function(self, prompt)
	local qtargets = sgs.PlayerList()
    
    local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
    slash:setSkillName("sppingxiang")

	self:sort(self.enemies, "defense")
	local target = {}
	for _,enemy in ipairs(self.enemies) do
		if enemy:isAlive() and slash:targetFilter(qtargets, enemy, self.player) and (not self.player:isProhibited(enemy, slash, qtargets)) then 
			qtargets:append(enemy)
			table.insert(target,enemy:objectName())
		end
	end
	slash:deleteLater()
	if #target > 0 then
		local card_str = string.format("#sppingxiangSlash:.:->%s", table.concat(target,"+"))
		return card_str
	else 
		return "."
	end
end

--九伐

sgs.ai_skill_invoke.spjiufa = true

--[[sgs.ai_skill_use["@@spjiufa"] = function(self, prompt)
	local qtargets = sgs.PlayerList()
	local card_ids = self.player:getTag("spjiufalist"):toIntList()
	local target = {}
    
	for _,id in sgs.qlist(card_ids) do
		local cc = sgs.Sanguosha:getCard(id)
		if cc:isAvailable(self.player) then
			if cc:isKindOf("EquipCard") then
				local card_str = string.format("#spjiufa:%s:", id)
				return card_str
			elseif cc:isKindOf("BasicCard") then
				if cc:objectName() == "peach" or cc:objectName() == "analeptic" then
					local card_str = string.format("#spjiufa:%s:", id)
					return card_str
				elseif cc:isKindOf("Slash") then
					self:sort(self.enemies, "defense")
					for _,enemy in ipairs(self.enemies) do
						if enemy:isAlive() and cc:targetFilter(qtargets, enemy, self.player) and (not self.player:isProhibited(enemy, cc, qtargets)) then 
							qtargets:append(enemy)
							table.insert(target,enemy:objectName())
						end
					end
					if #target > 0 then
						local card_str = string.format("#spjiufa:%s:->%s", id, table.concat(target,"+"))
						return card_str
					end
					qtargets = sgs.PlayerList()
					target = {}
				end
			elseif cc:isKindOf("TrickCard") then
				if not cc:isNDTrick() then
					self:sort(self.enemies, "defense")
					for _,enemy in ipairs(self.enemies) do
						if enemy:isAlive() and cc:targetFilter(qtargets, enemy, self.player) and (not self.player:isProhibited(enemy, cc, qtargets)) then 
							qtargets:append(enemy)
							table.insert(target,enemy:objectName())
						end
					end
					if #target > 0 then
						local card_str = string.format("#spjiufa:%s:->%s", id, table.concat(target,"+"))
						return card_str
					end
					qtargets = sgs.PlayerList()
					target = {}
				elseif cc:objectName() == "ex_nihilo" then
					local card_str = string.format("#spjiufa:%s:", id)
					return card_str
				elseif cc:targetFixed() then
					local card_str = string.format("#spjiufa:%s:", id)
					return card_str
				else
					self:sort(self.enemies, "defense")
					for _,enemy in ipairs(self.enemies) do
						if enemy:isAlive() and cc:targetFilter(qtargets, enemy, self.player) and (not self.player:isProhibited(enemy, cc, qtargets)) then 
							qtargets:append(enemy)
							table.insert(target,enemy:objectName())
						end
					end
					if #target > 0 then
						local card_str = string.format("#spjiufa:%s:->%s", id, table.concat(target,"+"))
						return card_str
					end
				end
			end
		end
	end

	return "."
end]]

sgs.ai_skill_use["@@spjiufa"] = function(self, prompt)
	local card_ids = self.player:getTag("spjiufalist"):toIntList()
	local canuse = {}
    for _,id in sgs.qlist(card_ids) do
        local card = sgs.Sanguosha:getCard(id)
        if card:isAvailable(self.player) then
            table.insert(canuse, card)
        end
    end
    if #canuse == 0 then return "." end
    --self:sortByCardNeed(canuse, true, true)
	self:sortByUseValue(canuse)
    for _,card in ipairs(canuse) do
        --local use = self:aiUseCard(card)
		local use = {isDummy=true,to=sgs.SPlayerList()}
		self:useCardByClassName(card, use)
        if use.card then
            if use.to and use.to:length() > 0 then
                local tos = {}
                for _,p in sgs.qlist(use.to) do
                    table.insert(tos, p:objectName())
                end
                --return card:toString().."->"..table.concat(tos,"+")
				return string.format("#spjiufa:%s:->%s", card:getId(), table.concat(tos,"+"))
            end
        end
    end
    return "."
end

--密运

sgs.ai_skill_playerchosen.miyund = function(self, targets)
	if self.player:hasFlag("miyunget") then
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) then
				return p
			end
		end
	elseif self.player:hasFlag("miyungive1") then
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) then
				return p
			end
		end
	elseif self.player:hasFlag("miyungive2") then
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) then
				return p
			end
		end
		return nil
	end
	for _,p in sgs.qlist(targets) do
		return p
	end
end

sgs.ai_use_revises.miyund = function(self,card,use)
	if card:hasFlag("miyunsafe") and self.player:getHp() > 1 then
		return false 
	end
end

sgs.ai_cardneed.miyund = function(to,card,self)
	return card:hasFlag("miyunsafe")
end
sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|miyund"

addAiSkills("danyind").getTurnUseCard = function(self)
	if self.player:getMark("danyind-Clear") > 0 then return end
	local handcards = self.player:getCards("he")
	handcards = self:sortByKeepValue(handcards) -- 按保留值排序
	if self:getCardsNum("Peach") == 0 then
		for _, h in ipairs(handcards) do
			if h:hasFlag("miyunsafe") then
				local slash = dummyCard("Peach")
				slash:setSkillName("danyind")
				if slash:isAvailable(self.player)
				then return slash end
			end
		end
	end
	if self:getCardsNum("Slash") == 0 then
		for _, h in ipairs(handcards) do
			if h:hasFlag("miyunsafe") then
				local slash = dummyCard("Slash")
				slash:setSkillName("danyind")
				if slash:isAvailable(self.player)
				then return slash end
			end
		end
	end
end

sgs.ai_guhuo_card.danyind = function(self,toname,class_name)
    if self.player:getMark("danyind-Clear") > 0 then return end
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
	else
		if class_name and self:getCardsNum(class_name) > 0 then return end
	end
	local card = sgs.Sanguosha:cloneCard(toname, sgs.Card_SuitToBeDecided, -1)
	card:deleteLater()
	if (not card) or (not card:isKindOf("BasicCard")) then return end
	local handcards = self.player:getCards("he")
	handcards = self:sortByKeepValue(handcards) -- 按保留值排序
	for _, h in ipairs(handcards) do
		if h:hasFlag("miyunsafe") then
			local slash = dummyCard(toname)
			slash:setSkillName("danyind")
			return slash:toString()
		end
	end
end

sgs.ai_card_priority.danyind = function(self,card)
	if card:hasFlag("miyunsafe")
	then return -0.05 end
end


--昊宠

sgs.ai_skill_invoke.sphaochong = function(self, data)
	if self.player:getHandcardNum() == 0 then return true end
	if self.player:getPhase() ~= sgs.Player_NotActive then return true end
	local n = 0
	local cards = {"peach", "jink", "analeptic", "nullification"}
	for _,p in sgs.qlist(self.player:getHandcards()) do
		if table.contains(cards, p:objectName()) then
			n = n + 1
		end
	end
	if n < 2 then return true end
    return false 
end

sgs.ai_skill_invoke.spjinjin = function(self, data)
	if self.player:getHandcardNum() < self.player:getMaxCards() then
		return true
	elseif self.player:getHandcardNum() > self.player:getMaxCards() then
		local n = self.player:getHandcardNum() - self.player:getMaxCards() 
		if n > 2 then return false end
		return true
	end
    return false 
end
sgs.ai_skill_choice["spjinjin"] = function(self, choices, data)
	local source = data:toPlayer()
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	else
		if table.contains(items, "recover") and self:isWeak(source) and source:isWounded() and source:getHp() < getBestHp(source) then
			return
			"recover"
		end
		local choice1 = getChoice(choices, "damage")
		if choice1 and ((self:isFriend(source) and self:needToLoseHp(source, self.player, nil)) or (self:isEnemy(source) and not self:cantbeHurt(source) and self:damageIsEffective(source, sgs.DamageStruct_Normal) and self:canDamage(source,self.player,nil))) then
			return choice1
		end
	end
	return "recover"
end

sgs.ai_can_damagehp.spjinjin = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and ((self.player:getMaxCards() - self.player:getHandcardNum() > 2) or ((self.player:getHandcardNum() -  self.player:getMaxCards()> 0) and from and self:isEnemy(from) and self:isWeak(from) and self:damageIsEffective(from, sgs.DamageStruct_Normal)))
end


--矜谨

sgs.ai_skill_invoke.spjinjin = function(self, data)
	if self.player:getHandcardNum() < self.player:getMaxCards() then return true end
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("spjinjintarget") then
			target = p
			break
		end
	end
	local save = self:getCardsNum("Analeptic") + self:getCardsNum("peach")
	local n = self.player:getHandcardNum() - self.player:getMaxCards()
	if self.player:isWounded() then
		if n <= 1 then return true end
		if self.player:getMaxCards() + 1 >= save then return true end
		if self.player:containsTrick("indulgence") and self.player:getHp() <= 1 and self:getCardsNum("Nullification") < 1 then return true end
	end
	if not target then
		return false 
	elseif target then
		if self:isEnemy(target) and n <= 2 then return true end
	end
	return false
end

sgs.ai_skill_choice["spjinjin"] = function(self, choices, data)
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("spjinjintarget") then
			target = p
			break
		end
	end
	if target and self:isEnemy(target) and target:getHp() <= 1 and self.player:getLostHp() < 2 then
		for _,choice in ipairs(choices:split("+")) do
			if string.find(choice, "damage") then
				return choice
			end
		end
	end
	if (self.player:getLostHp() >= 2) or (not target) then
		for _,choice in ipairs(choices:split("+")) do
			if string.find(choice, "recover") then
				return choice
			end
		end
	end
	if target and self:isEnemy(target) then
		for _,choice in ipairs(choices:split("+")) do
			if string.find(choice, "damage") then
				return choice
			end
		end
	end
	for _,choice in ipairs(choices:split("+")) do
		return choice
	end
end

--固势

local hfgushi_skill = {}
hfgushi_skill.name = "hfgushi"
table.insert(sgs.ai_skills, hfgushi_skill)
hfgushi_skill.getTurnUseCard = function(self, inclusive)
	local card = nil
	if self.player:getMark("&hfgushi-PlayClear") == 0 then
		card = sgs.Sanguosha:cloneCard("peach", sgs.Card_SuitToBeDecided, -1)
	elseif self.player:getMark("&hfgushi-PlayClear") == 1 then
		card = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_SuitToBeDecided, -1)
	elseif self.player:getMark("&hfgushi-PlayClear") == 2 then
		card = sgs.Sanguosha:cloneCard("duel", sgs.Card_SuitToBeDecided, -1)
	end
	if card then card:setSkillName("hfgushi")
	else return end
	card:deleteLater()
	if card and card:isAvailable(self.player) then
		local card_str = nil
		if self.player:getMark("&hfgushi-PlayClear") == 0 then
			card_str = string.format("peach:hfgushi[%s:%s]=.", "no_suit", 0)
		elseif self.player:getMark("&hfgushi-PlayClear") == 1 then
			card_str = string.format("ex_nihilo:hfgushi[%s:%s]=.", "no_suit", 0)
		elseif self.player:getMark("&hfgushi-PlayClear") == 2 then
			card_str = string.format("duel:hfgushi[%s:%s]=.", "no_suit", 0)
		end
		local usec = sgs.Card_Parse(card_str)
		return usec
	end
end

sgs.ai_card_priority.hfgushi = function(self,card)
	if table.contains(card:getSkillNames(), "hfgushi")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_use_priority.hfgushi = sgs.ai_use_priority.Peach + 0.1

--狼顾

sgs.ai_skill_askforag["hflanggu"] = function(self, card_ids)
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("hflanggutarget") then
			target = p
			break
		end
	end
	local can = false
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:getSuitString() == "spade" and card:getNumber() >= 2 and card:getNumber() <= 9 then
			can = true
		end
	end
	if not can  then
		local choosecards = {}
		for _,id in ipairs(card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			table.insert(choosecards,card)
		end

		--self:sortByCardNeed(choosecards)
		self:sortByKeepValue(choosecards, true)
    	return choosecards[#choosecards]:getEffectiveId()
	else 
		if self:isEnemy(target) then
			for _,id in ipairs(card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:getSuitString() == "spade" and card:getNumber() >= 2 and card:getNumber() <= 9 then
				else return id end
			end
		else
			for _,id in ipairs(card_ids) do
				local card = sgs.Sanguosha:getCard(id)
				if card:getSuitString() == "spade" and card:getNumber() >= 2 and card:getNumber() <= 9 then
					return id 
				end
			end
		end
	end
end

--义争

local dyizheng_skill = {}
dyizheng_skill.name = "dyizheng"
table.insert(sgs.ai_skills, dyizheng_skill)
dyizheng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#dyizheng") then return end
	return sgs.Card_Parse("#dyizheng:.:")
end

sgs.ai_skill_use_func["#dyizheng"] = function(card, use, self)
	local max_card = self:getMaxCard()
	if not max_card then return end
	local point = max_card:getNumber()
	if self.player:hasSkill("tianbian") and max_card:getSuit() == sgs.Card_Heart then point = 13 end
	if (((self.player:getHp() <= 2) or (self.room:getTag("SwapPile"):toInt() ~= 0)) and point >=10) or point >= 7 or (self.player:getHp() > 2 and self.room:getTag("SwapPile"):toInt() == 0) then
		self:sort(self.enemies, "handcard")
		for _, p in ipairs(self.enemies) do
			if not self.player:canPindian(p) --[[or self:doNotDiscard(p, "h")]] then continue end
			local card_str = string.format("#dyizheng:.:->%s",p:objectName())
			local acard = sgs.Card_Parse(card_str)
			assert(acard)
			use.card = acard
			if use.to then
				use.to:append(p)
			end
			return
		end
	end
end

function sgs.ai_skill_pindian.dyizheng(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end

sgs.ai_use_priority.dyizheng = 6
sgs.ai_use_value.dyizheng = 2
sgs.ai_card_intention["#dyizheng"] = 50

--让节

sgs.ai_skill_invoke.drangjie = function(self, data)
	if not self.room:canMoveField("ej") and not self:canDraw() then return false end
	if self:canDraw() then return true end
	local from, card, to = self:moveField()
	if from and card and to then return true end
	return false
end

sgs.ai_skill_choice.drangjie = function(self, choices)
	choices = choices:split("+")
	if table.contains(choices, "move") then
		local from, card, to = self:moveField()
		if from and card and to then return "move" end
		return "draw"
	else
		return "hand"
	end
end

sgs.ai_skill_use["@@drangjie"] = function(self, prompt)
	local card_ids = self.player:getTag("drangjiecards"):toIntList()
	local cards = {}
	for _,id in sgs.qlist(card_ids) do
		table.insert(cards,sgs.Sanguosha:getCard(id))
	end
	--self:sortByCardNeed(cards)
	self:sortByKeepValue(cards)
	local card_str = "#drangjie:"..cards[#cards]:getEffectiveId()..":"
	return card_str
end

sgs.ai_skill_playerchosen.drangjie = function(self, targets)
	self:sort(self.friends, "defense")
	return self.friends[1]
end

sgs.ai_playerchosen_intention.drangjie = function(self, from, to)
	if from:hasFlag("drangjiejud") then
		sgs.updateIntention(from, to, 60)
	else
		sgs.updateIntention(from, to, -60)
	end
end

sgs.ai_can_damagehp.drangjie = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end

--智哲

local dwzhizhe_skill = {}
dwzhizhe_skill.name = "dwzhizhe"
table.insert(sgs.ai_skills, dwzhizhe_skill)
dwzhizhe_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("dwzhizheused") == 0 then
		local names = {"peach", "nullification", "archery_attack", "savage_assault", "snatch", "fire_attack", "duel", "dismantlement"}
		if self.player:getHandcardNum() == 0 then return end
		for _,card in sgs.qlist(self.player:getHandcards()) do
			if table.contains(names, card:objectName()) then
				return sgs.Card_Parse("#dwzhizhe:.:")
			end
		end
		return
	end
	if self.player:getMark("dwzhizhe-Clear") > 0 then return end
	local pattern = self.player:property("dwzhizheshow"):toString()
	local card_str = string.format("%s:dwzhizhe[%s:%s]=.", pattern,"no_suit", 0)
	local usec = sgs.Card_Parse(card_str)
	assert(usec)
	return usec
end

sgs.ai_skill_use_func["#dwzhizhe"] = function(card, use, self)
	local handcards = self.player:getCards("h")
	handcards = sgs.QList2Table(handcards)
	local usecard
	self:sortByUseValue(handcards, inverse)
	local names = {"peach", "nullification", "archery_attack", "savage_assault", "snatch", "fire_attack", "duel", "dismantlement"}
	for _,card in ipairs(handcards) do
		if table.contains(names, card:objectName()) then
			usecard = card
			break
		end
	end

	if usecard then
		local card_str = string.format("#dwzhizhe:%d:", usecard:getId())
		local acard = sgs.Card_Parse(card_str)
		assert(acard)
		use.card = acard
	end
end

sgs.ai_cardsview_valuable.dwzhizhe = function(self, class_name, player)
	if self.player:getMark("dwzhizhe-Clear") > 0 then return end
	if self.player:getMark("dwzhizheused") == 0 then return end
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
		["Nullification"] = "nullification",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local pattern = self.player:property("dwzhizheshow"):toString()
	if string.find(pattern, name) or pattern == name or string.find(name, pattern) then
		return string.format("%s:dwzhizhe[%s:%s]=.", pattern,"no_suit", 0)
	end
	return
end

sgs.ai_use_priority.dwzhizhe = 8

sgs.ai_card_priority.dwzhizhe = function(self,card)
	if table.contains(card:getSkillNames(), "dwzhizhe")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

--情势

sgs.ai_skill_invoke.dwqingshi = true

sgs.ai_skill_choice["dwqingshi"] = function(self, choices, data)
	choices = choices:split("+")
	local names = {"slash", "thunder_slash", "fire_slash", "fire_attack", "duel", "archery_attack", "savage_assault"}

	if self.player:getMark("dwqingshiuseai") > 0 then
		local use = self.player:getTag("dwqingshiuseai"):toCardUse()
		if not table.contains(names,use.card:objectName()) then
			local canuse = false
			local num = 0
			for _,card in sgs.qlist(self.player:getHandcards()) do
				if not card:isAvailable(self.player) then break end
				canuse = true
				if card:objectName() == use.card:objectName() then num = num + 1 end
			end
			if (#self.friends == 2 and self.player:getHandcardNum() >3) 
			or (#self.friends > 2) 
			or (canuse and num > 1) then
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawall") then
						return choice
					end
				end
			else
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawself") then
						return choice
					end
				end
			end
		else
			local canuse = false
			local num = 0
			for _,card in sgs.qlist(self.player:getHandcards()) do
				if not card:isAvailable(self.player) then break end
				canuse = true
				if card:objectName() == use.card:objectName() 
				or (card:isKindOf("Slash") and use.card:isKindOf("Slash"))
				then num = num + 1 end
			end
			local enemynum = 0
			local weakenemy = false
			for _,p in sgs.qlist(use.to) do
				if self:isEnemy(p) then
					enemynum = enemynum + 1
					if p:getHp() <= 2 or p:getHandcardNum() <= 2 then
						weakenemy = true
					end
				end
			end
			if (enemynum > 1) or (canuse and num > 1) or weakenemy then
				for _,choice in ipairs(choices) do
					if string.find(choice, "damage") then
						return choice
					end
				end
			end

			if (#self.friends == 2 and self.player:getHandcardNum() >3) 
			or (#self.friends > 2) 
			or (canuse and num > 1) then
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawall") then
						return choice
					end
				end
			else
				for _,choice in ipairs(choices) do
					if string.find(choice, "drawself") then
						return choice
					end
				end
			end
		end
	else
		if (#self.friends == 2 and self.player:getHandcardNum() >3) 
			or (#self.friends > 2) then
			for _,choice in ipairs(choices) do
				if string.find(choice, "drawall") then
					return choice
				end
			end
		else
			for _,choice in ipairs(choices) do
				if string.find(choice, "drawself") then
					return choice
				end
			end
		end
	end
	return choices[math.random(1,#choices)]
end

sgs.ai_skill_use["@@dwqingshi"] = function(self, prompt)
	local targets = {}
	if self.player:hasFlag("dwqingshidrawall") then
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) then
				table.insert(targets,p:objectName())
			end
		end
	elseif self.player:hasFlag("dwqingshidamage") then
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isEnemy(p) and p:hasFlag("dwqingshiupcan") then
				table.insert(targets,p:objectName())
			end
		end
	end
	if #targets > 0 then
		local card_str = string.format("#dwqingshi:.:->%s", table.concat(targets,"+"))
		return card_str
	else 
		return "."
	end
end

sgs.ai_card_intention.dwqingshi = function(self, card, from, tos)
	if from:hasFlag("dwqingshidrawall") then
		for _,to in ipairs(tos) do
			sgs.updateIntention(from, to, -40)
		end
	else
		for _,to in ipairs(tos) do
			sgs.updateIntention(from, to, 60)
		end
	end
end
sgs.ai_ajustdamage_from.dwqingshi = function(self, from, to, card, nature)
	if card and card:hasFlag("dwqingshidamage") then
		local names = card:getTag("dwqingshitarget"):toString():split("+")
		if table.contains(names, to:objectName()) then
			return 1
		end
	end
end


--尽瘁

sgs.ai_skill_invoke.dwjingcui = function(self, data)
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() <= 0 then 
			target = p
			break
		end
	end
	if not self:isFriend(target) then return false end
	local n = nil
	if target:objectName() ~= self.player:objectName() then
		n = self:getCardsNum("Peach")
		for _,card in sgs.qlist(target:getHandcards()) do
			if card:objectName() == "peach" or card:objectName() == "analeptic" then n = n + 1 end
		end
		if self.player:getMark("dwzhizheused") > 0 then
			if self.player:getMark("dwzhizhe-Clear") == 0 then
				local pattern = self.player:property("dwzhizheshow"):toString()
				if pattern == "peach" then n = n + 1 end
			end
		end
	else
		n = self:getCardsNum("Peach") + self:getCardsNum("Analeptic")
		if self.player:getMark("dwzhizheused") > 0 then
			if self.player:getMark("dwzhizhe-Clear") == 0 then
				local pattern = self.player:property("dwzhizheshow"):toString()
				if pattern == "peach" or pattern == "analeptic" then n = n + 1 end
			end
		end
	end
	if n >= 1 - target:getHp() then return false end
	return true
end

--权御

sgs.ai_skill_playerchosen.spzhiheng =  function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self.player:getMark("spzhihenggood") > 0 then
			if self:isFriend(p) then return p end
		elseif self:isEnemy(p) then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention.spzhiheng = function(self, from, to)
	if from:getMark("spzhihenggood") > 0 then
		sgs.updateIntention(from, to, -80)
	else
		sgs.updateIntention(from, to, 80)
	end
end

--守常

sgs.ai_skill_invoke.shouchang = true

sgs.ai_skill_discard.shouchang = function(self,max,min)
	local dis = {}
	local red = {}
    local black = {}
    for _,card in sgs.qlist(self.player:getHandcards()) do
        if card:isRed() then
            table.insert(red, card)
        elseif card:isBlack() then
            table.insert(black, card)
        end
    end
	--self:sortByCardNeed(red)
	--self:sortByCardNeed(black)
	if self.player:getPhase() ~= sgs.Player_NotActive then
		self:sortByUseValue(red, true)
		self:sortByUseValue(black, true)
	else
		self:sortByKeepValue(red)
		self:sortByKeepValue(black)
	end
	if self.player:getPhase() == sgs.Player_Play and self.player:getHandcardNum() > 10 and #red > 0 then
		table.insert(dis, red[1]:getEffectiveId())
		return dis
	end
	if #red > #black then
		table.insert(dis, red[1]:getEffectiveId())
	elseif #black > #red then
		table.insert(dis, black[1]:getEffectiveId())
	end
	return dis
end

--奸雄

sgs.ai_skill_choice["Djianxiong"] = function(self, choices, data)
	choices = choices:split("+")
	if self.player:getLostHp() <= 2 and self.player:getHandcardNum() <= 2 then
		return "draw"
	end
	if table.contains(choices, "recover") then
		return "recover"
	end
	return choices[1]
end

sgs.ai_can_damagehp.Djianxiong = function(self, from, card, to)
	return  (card and not card:isKindOf("SkillCard"))
		and self:canLoseHp(from, card, to)
end


--寤寐

sgs.ai_skill_playerchosen.dmwumei = function(self,players)
	local destlist = players
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
	self:sort(destlist,"handcard",true)
	for _,target in sgs.list(destlist)do
		if self:isFriend(target) and target:getHandcardNum() > self.player:getHandcardNum() + 2
		then return target end
	end
	return self.player
end

sgs.ai_playerchosen_intention.dmwumei = function(self, from, to)
	sgs.updateIntention(from, to, -100)
end

--占梦

sgs.ai_skill_invoke.dmzhanmeng = function(self,data)
	local allchoices = {"recover", "draw", "discard"}
    local choices = {}
    for _,cc in ipairs(allchoices) do
        if self.player:getMark("dmzhanmeng"..cc.."-Clear") == 0 then
            table.insert(choices, cc)
        end
    end
	if table.contains(choices, "recover") then
		local wumeiextra = false
		local wounded = false
		local danger = false
		local nofaceup = false
		local chained = false
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getMark("&dmwumei-SelfClear") > 0 then wumeiextra = true end
			if self:isFriend(p) then
				if p:isWounded() then
					wounded = true
					if p:getHp() == 1 then danger = true end
				end
				if p:isChained() then chained = true end
				if not p:faceUp() then nofaceup = true end
			end
		end
		if nofaceup or ((not wumeiextra) and wounded) or chained or (wumeiextra and danger) then return true end
	end
	if table.contains(choices, "draw") then return true end
	if table.contains(choices, "discard") then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isEnemy(p) and p:canDiscard(p, "he")  and self:damageIsEffective(p, sgs.DamageStruct_Fire) and not self:cantbeHurt(p) and self:canDamage(p,self.player,nil) then return true end
		end
	end
	return false
end

sgs.ai_skill_choice.dmzhanmeng = function(self,choices,data)
	local items = choices:split("+")

	local wumeiextra = false
	local wounded = false
	local danger = false
	local nofaceup = false
	local chained = false
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("&dmwumei-SelfClear") > 0 then wumeiextra = true end
		if self:isFriend(p) then
			if p:isWounded() then
				wounded = true
				if p:getHp() == 1 then danger = true end
			end
			if p:isChained() then chained = true end
			if not p:faceUp() then nofaceup = true end
		end
	end
		
	if table.contains(items, "recover") then
		if nofaceup or danger then return "recover" end
	end

	if table.contains(items, "draw") and wumeiextra then return "draw" end

	if table.contains(items, "discard") then
		for _,p in ipairs(self.enemies) do
			if p:canDiscard(p, "he") then return "discard" end
		end
	end

	if table.contains(items, "recover") then
		if wounded and (not wumeiextra) then return "recover" end
	end

	if table.contains(items, "draw") then return "draw" end

	if table.contains(items, "recover") then
		if chained then return "recover" end
	end

	return items[math.random(1, #items)]
end

sgs.ai_playerchosen_intention.dmzhanmeng = function(self, from, to)
	if from:hasFlag("dmzhanmenggood") then
		sgs.updateIntention(from, to, -80)
	else
		sgs.updateIntention(from, to, 100)
	end
end

sgs.ai_skill_playerchosen.dmzhanmeng = function(self, targets)
	if self.player:hasFlag("dmzhanmenggood") then
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and (not p:faceUp()) then return p end
		end
		local min = -1
		local target = nil
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and ((min == - 1) or p:getHp() < min) and p:isWounded() then 
				target = p
				min = p:getHp()
			end
		end
		if target then return target end
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and p:isChained() then return p end
		end
	else
		self:sort(self.enemies, "defense")
		for _,p in ipairs(self.enemies) do
			if p:canDiscard(p, "he") then return p end
		end
		for _,p in sgs.qlist(targets) do
			if not self:isFriend(p) then return p end
		end
	end
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|dmshenyou"

--龙怒

local godlongnu_skill={}
godlongnu_skill.name="godlongnu"
table.insert(sgs.ai_skills, godlongnu_skill)
godlongnu_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do

		local slash = nil

		if card:isRed() and ((self.player:getMark("&godlongnu+:+fire_slash-PlayClear") > 0) or (self.player:getMark("&godlongnuall-PlayClear") > 0) ) then
			slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card)
			slash:setSkillName("godlongnu")
			if not slash:isAvailable(self.player) then slash = nil end
		end

		if card:isBlack() and ((self.player:getMark("&godlongnu+:+thunder_slash-PlayClear") > 0) or (self.player:getMark("&godlongnuall-PlayClear") > 0) ) then
			slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
			slash:addSubcard(card)
			slash:setSkillName("godlongnu")
			if not slash:isAvailable(self.player) then slash = nil end
		end

		if slash and card:isRed() then
			return sgs.Card_Parse(("fire_slash:godlongnu[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
		elseif slash and card:isBlack() then
			return sgs.Card_Parse(("thunder_slash:godlongnu[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
		end
	end
end

sgs.ai_skill_choice["godlongnu"] = function(self, choices, data)
	local n = self.player:getHp() + self:getCardsNum("Peach") + self:getCardsNum("Analeptic")
	if #self.enemies > 0 and n > 1 and self.player:getMaxHp() > 2 then
		self:sort(self.enemies, "defense")
		for _,p in ipairs(self.enemies) do
			if p:getHp() <= 2 then
				return "all"
			elseif p:getHandcardNum() < 2 and p:getHp() <= 3 then
				return "all"
			end
		end
		for _,cc in sgs.qlist(self.player:getHandcards()) do
			if cc:objectName() == "crossbow" then return "all" end
		end
		for _,cc in sgs.qlist(self.player:getEquips()) do
			if cc:objectName() == "crossbow" then return "all" end
		end
	end
	if self.player:getLostHp() < 3 and self.player:getHp() > 1 then return "red" end
	if self.player:getLostHp() >= 3 then return "black" end
	if self.player:getHp() == 1 and (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0) then return "red" end
	if self.player:getHp() == 1 and self.player:isWounded() then return "black" end
	if self.player:getMaxHp() == 1 then return "red" end
	choices = choices:split("+")
	table.removeOne(choices, "all")
	return  choices[math.random(1, #choices)]
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|godlongnu"

--结营

sgs.ai_skill_playerchosen.godjieyin = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then return p end
	end
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then return p end
	end
	for _,p in sgs.qlist(targets) do
		return p
	end
end
sgs.ai_target_revises.godjieyin = function(to,card,self,use)
    if card:isKindOf("IronChain") then return true end
end


sgs.ai_playerchosen_intention.godjieyin = function(self, from, to)
	sgs.updateIntention(from, to, 30)
end


--认父
sgs.ai_suppress_intention["xiaoyizi"] = true
sgs.ai_skill_playerchosen.xiaorenfu = function(self, targets)
	if self.player:hasFlag("xiaoyifu") then
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		slash:setSkillName("_xiaoyizi")
		slash:deleteLater()
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and self:slashIsEffective(slash, p, self.player) and self:isGoodTarget(p, self.enemies, slash) then return p end
		end
		return nil
	end
	local max = -1
	local yifu = nil
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) and (max == -1 or (p:getHandcardNum() + p:getEquips():length() > max)) then
			yifu = p
			max = p:getHandcardNum() + p:getEquips():length()
		end
	end
	if yifu then return yifu end
	for _,p in sgs.qlist(targets) do
		return p
	end
end

sgs.ai_playerchosen_intention.xiaorenfu = function(self, from, to)
	sgs.updateIntention(from, to, 80)
end

sgs.ai_skill_invoke.xiaorenfu = function(self, data)
	local target = nil
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("old_yifuta") then
			target = p
			break
		end
	end
	if target and (not self:isFriend(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and not self:cantbeHurt(target) and self:canDamage(target,self.player,nil)) then return true end
	return false
end

sgs.ai_ajustdamage_from.xiaorenfu = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and from and to:getMark("xiaoyifufrom"..from:objectName()) > 0
	then
		return 1
	end
end

--射戟

sgs.ai_skill_invoke.xiaosheji = function(self, data)
	local from = nil
	local to = nil
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("shejifrom") then
			from = p
		elseif p:hasFlag("shejito") then
			to = p
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	slash:setSkillName("xiaosheji")
	if (not self:isFriend(from)) and (not self:isEnemy(to) and self:slashIsEffective(slash, from, self.player) and self:isGoodTarget(from, self.enemies, slash)) then return true end
	return false
end

--内伐

sgs.ai_skill_playerchosen.doubleneifa = function(self, targets)
	if self.player:hasSkill("doubleneifa") then
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and p:getJudgingArea():length() > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and p:getEquips():length() > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and p:getMark("&doubleneifa") > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if not self:isFriend(p) then return p end
		end
		for _,p in sgs.qlist(targets) do
			return p
		end
	else
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) and p:getJudgingArea():length() > 0 then return p end
		end
		for _,p in sgs.qlist(targets) do
			if not self:isFriend(p) then return p end
		end
		if self.player:getHandcardNum() > 1 then return self.player end
		return nil
	end
end

sgs.ai_playerchosen_intention.doubleneifa = function(self, from, to)
	if to:getJudgingArea():length() > 0 then
		sgs.updateIntention(from, to, -40)
	else
		sgs.updateIntention(from, to, 40)
	end
end

--归心

sgs.ai_skill_askforag["wwguixin"] = function(self, card_ids)
	local cards = {}
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(cards, card)
	end
	--self:sortByCardNeed(cards)
	self:sortByKeepValue(cards)
    return cards[1]:getEffectiveId()
end

--祭风

local jfjifeng_skill = {}
jfjifeng_skill.name = "jfjifeng"
table.insert(sgs.ai_skills, jfjifeng_skill)
jfjifeng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("jfjifengfailed-PlayClear") > 0 then return end
	local fire_attack = sgs.Sanguosha:cloneCard("fire_attack", sgs.Card_SuitToBeDecided, -1)
    fire_attack:setSkillName("jfjifeng")
	if fire_attack and fire_attack:isAvailable(self.player) then
		local card_str = nil
		card_str = string.format("fire_attack:jfjifeng[%s:%s]=.", "no_suit", 0)
		local usec = sgs.Card_Parse(card_str)
		assert(usec)
		return usec
	end
end

sgs.ai_skill_use["@@jfjifeng"] = function(self, prompt)
	local dis = nil
	local card_ids = self.player:getTag("jfjifengai"):toIntList()
	local suit = self.player:property("jfjifengsuit"):toString()
	for _,id in sgs.qlist(card_ids) do
		local cc = sgs.Sanguosha:getCard(id)
		if cc:getSuitString() == suit then
			dis = cc
			break
		end
	end
	if not dis then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		--self:sortByCardNeed(cards)
		self:sortByKeepValue(cards)
		for _,cc in ipairs(cards) do
			if cc:getSuitString() == suit then
				dis = cc
				break
			end
		end
	end
	if dis then
		return "#jfjifengdis:"..dis:getEffectiveId()..":"
	else
		return "."
	end
end

sgs.ai_ajustdamage_to["&jfjifeng"] = function(self, from, to, card, nature)
	if nature == sgs.DamageStruct_Fire
	then
		return 1
	end
end

--月隐
local function getTypeString(card)
    local cardtype = nil
    local types = {"BasicCard","TrickCard","EquipCard"}
    for _,p in ipairs(types) do
        if card:isKindOf(p) then
            cardtype = p
            break
        end
    end
    return cardtype
end
sgs.ai_ajustdamage_to.jfyueyin = function(self, from, to, card, nature)
	local can_invoke = false
	if (not card) or (card and card:isKindOf("SkillCard")) then can_invoke = true end
	if card and (not card:isKindOf("SkillCard")) then
		local ctype = getTypeString(card)
		if to:getMark("jfyueyin"..ctype.."-Clear") > 0 then
			can_invoke = true
		end
	end
	if can_invoke then
		return -999
	end
end

--祈星
sgs.exclusive_skill = sgs.exclusive_skill .. "|jfqixing"

sgs.ai_skill_playerchosen.jfqixing = function(self, targets)
	if self.player:getRole() == "loyalist" then
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getRole() == "lord" then
				return p
			end
		end
	end
	self:sort(self.friends, "hp")
	for _,p in ipairs(self.friends) do
		if p:isAlive() then
			return p
		end
	end
	return nil
end

--骁锐

sgs.ai_skill_invoke.xrxiaorui = function(self, data)
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("xrxiaoruitarget") then
			target = p
			break
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	slash:setSkillName("xrxiaorui")
	slash:deleteLater()
	if self:isEnemy(target) and self:slashIsEffective(slash, target, self.player) and self:isGoodTarget(target, self.enemies, slash) then return true end
	return false
end

sgs.ai_skill_use["@@xrxiaorui"] = function(self, prompt)
	local target = nil
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("xrxiaoruitarget") then
			target = p
			break
		end
	end
	if not target then return "." end
	local cards = sgs.QList2Table(target:getCards("h"))
	self:sortByKeepValue(cards, inverse)
	if #cards > 0 then
		return "#xrxiaorui:"..cards[#cards]:getEffectiveId()..":"
	end
	return "."
end

--缮甲

sgs.ai_skill_invoke.xrshanjia = true

sgs.ai_skill_use["@@xrshanjia"] = function(self, prompt)
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
    slash:setSkillName("xrshanjia")
	local targets = {}
	--local use = self:aiUseCard(slash)
	local dummy_use = self:aiUseCard(slash, dummy())
	if dummy_use.card then
        if not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets, p:objectName())
			end
		end
	end
    slash:deleteLater()

	if #targets > 0 then
		local card_str = string.format("#xrshanjia:.:->%s",  table.concat(targets, "+"))
		return card_str
	end
	return "."
end
sgs.ai_use_revises.xrshanjia = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|xrshanjia"
sgs.ai_cardneed.xrshanjia = sgs.ai_cardneed.equip

--铁骑

sgs.ai_skill_invoke.cqtieji = function(self, data)
	local target = data:toPlayer()
	return self:isEnemy(target)
end
sgs.ai_choicemade_filter.skillInvoke.cqtieji = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end
sgs.ai_cardneed.cqtieji = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|cqtieji"

sgs.ai_canliegong_skill.cqtieji = function(self, from, to)
	return true
end
--长驱

sgs.ai_skill_playerchosen.cqchangqu = function(self, targets)
	self:sort(self.enemies, "defense")
	if #self.enemies == 0 then return nil end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	slash:setSkillName("cqchangqu")
	slash:deleteLater()
	for _,p in ipairs(self.enemies) do
		if self.player:inMyAttackRange(p) then
			if not p:inMyAttackRange(self.player) and self:slashIsEffective(slash, p, self.player) and self:isGoodTarget(p, self.enemies, slash) then
				return p
			end
		end
	end
	for _,p in ipairs(self.enemies) do
		if self.player:inMyAttackRange(p) and p:inMyAttackRange(self.player) and self:slashIsEffective(slash, p, self.player) and self:isGoodTarget(p, self.enemies, slash)  then
			return p
		end
	end
	for _,p in ipairs(self.enemies) do
		if self:slashIsEffective(slash, p, self.player) and self:isGoodTarget(p, self.enemies, slash)  then
			return p
		end
	end
	return self.enemies[1]
end

sgs.ai_playerchosen_intention.cqchangqu = function(self, from, to)
	sgs.updateIntention(from, to, 80)
end

--迂志

local function chsize(tmp)
	if not tmp then
		return 0
    elseif tmp > 240 then
        return 4
    elseif tmp > 225 then
        return 3
    elseif tmp > 192 then
        return 2
    else
        return 1
    end
end

local function utf8len(str)
	local length = 0
	local currentIndex = 1
	while currentIndex <= #str do
		local tmp = string.byte(str, currentIndex)
		currentIndex  = currentIndex + chsize(tmp)
		length = length + 1
	end
	return length
end

sgs.ai_skill_discard.yzyuzhi = function(self,max,min)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local n = self.player:getHp()
	self:sortByUseValue(cards)
	local max = -1
	local show = {}
	local special = nil
	for _,card in ipairs(cards) do
		local name_number = utf8len(sgs.Sanguosha:translate(card:objectName()))
		if card:isKindOf("Slash") then name_number = 1 end
		if name_number > max and name_number <= self.player:getHp() then 
			max = name_number
			special = card
		end
	end
	if special then
		table.insert(show, special:getEffectiveId())
		return show
	end
	for _,card in ipairs(cards) do
		table.insert(show, card:getEffectiveId())
		return show
	end
end

--挟术

sgs.ai_skill_use["@@yzxieshu"] = function(self, prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)

	local n = self.player:getMark("yzxieshu")
	if #cards < n then return "."end
	if (n > self.player:getLostHp() + 1) and self.player:getHp() ~= 1 and self.player:getHandcardNum() < 8 then return "." end
	
	local target = nil
	if self.player:getHp() == 1 and (self:getCardsNum("Analeptic") + self:getCardsNum("Peach") < 1) then
		target = self.player
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy,self.player,nil) then
				target = enemy
				break
			end
		end
	end

	if not target then
		if #self.enemies == 0 then return "." end
		self:sort(self.enemies, "hp")
		target = self.enemies[1]
	end

	local usecards = {}
	for _,card in ipairs(cards) do
		if #usecards < n then
			table.insert(usecards, card:getEffectiveId())
		else
			break
		end
	end

	if target then
		local card_str = string.format("#yzxieshu:%s:->%s", table.concat(usecards, "+"), target:objectName())
		return card_str
	else
		return "."
	end
end

sgs.ai_card_intention.yzxieshu = 50

sgs.ai_can_damagehp.yzxieshu = function(self,from,card,to)
	if card and not card:isKindOf("SkillCard") then
		local name_number = utf8len(sgs.Sanguosha:translate(card:objectName()))
		if card:isKindOf("Slash") then name_number = 1 end
		if to:getMark("yzxieshu"..name_number.."-Clear") > 0 then return false end

		return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
		and self:canLoseHp(from,card,to) and name_number <= to:getLostHp() + 1 and to:getCards("he"):length() >= name_number
	end
end


--谋烈弓

sgs.ai_skill_invoke.lgliegong = function(self, data)
	local target = data:toPlayer()
	return self:isEnemy(target)
end

sgs.ai_skill_discard.lgliegong = function(self,max,min)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local dis = {}
	if #cards == 0 then return dis end
	if self.player:containsTrick("indulgence") and (self.player:getHandcardNum() > (self.player:getMaxCards() - 2)) then
		local n = self.player:getHandcardNum() - self.player:getMaxCards() + 3
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValue(handcards)
		for _,card in ipairs(handcards) do
			table.insert(dis, card:getEffectiveId())
			n = n - 1
			if n <= 0 then break end
		end
	elseif self:getCardsNum("Slash") == 0 then
		table.insert(dis, cards[1]:getEffectiveId())
	end
	return dis
end

sgs.ai_ajustdamage_from.lgliegong = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") then else return 0 end
	local n = 0
	if from:getHp() <= to:getHp() then n = n + 1 end
	if from:getHandcardNum() <= to:getHandcardNum() then n = n + 1 end
	if from:getEquips():length() <= to:getEquips():length() then n = n + 1 end
	if n <= 0 then return false end
	return n
end

sgs.ai_choicemade_filter.skillInvoke.lgliegong = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end
sgs.ai_cardneed.lgliegong = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|lgliegong"

