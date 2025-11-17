--武器攻击范围
sgs.weapon_range.Elucidator = 2

sgs.ai_skill_invoke.Elucidator = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) and self:canDraw(damage.to, self.player) then
		return true
	end
	local slash = self:getCard("Slash")
	if slash then
		local dummy_use = self:aiUseCard(slash, dummy())

		if dummy_use.card and not dummy_use.to:isEmpty() then
			return true
		end
	end
	
	return false
end

sgs.ai_skill_invoke.htms_rishi = function(self, data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return true
	end
	return false
end

sgs.ai_canliegong_skill.htms_rishi = function(self, from, to)
	return from:getHandcardNum() < to:getHandcardNum()
end

sgs.weapon_range.chopper = 3


chopper_skill = {name = "chopper"}
table.insert(sgs.ai_skills,chopper_skill)
chopper_skill.getTurnUseCard = function(self)
    if self.player:getHandcardNum()>self.player:getHp()
	or self.player:isKongcheng() then return end
	local slash = dummyCard("slash")
    slash:addSubcards(self.player:getHandcards())
    slash:setSkillName("chopper")
	return slash
end

function sgs.ai_cardsview.chopper(self, class_name, player)
	if player:getPhase() ~= sgs.Player_NotActive then return end
	if class_name == "Slash"then
		local slashs = {}
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:isKindOf("Slash") then
				table.insert(slashs, c)
			end
		end
		if #slashs == 0 then
			local c = dummyCard("slash")
			c:setSkillName("chopper")
			c:addSubcards(player:getHandcards())
			return c:toString()
		end
	end
end

--使用优先级
sgs.ai_use_priority.Rho_Aias = 2.6

sgs.ai_skill_discard.Rho_Aias_trigger = function(self,discard_num,optional,include_equip)
	if self.player:getPile("ring"):length() >= 2 then return {} end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	local compare_func = function(a,b)
		return self:getKeepValue(a)<self:getKeepValue(b)
	end
	table.sort(cards,compare_func)
	for _,card in sgs.list(cards)do
		if #to_discard>=1 then break end
		table.insert(to_discard,card:getId())
	end

	return to_discard
end
sgs.ai_view_as.Rho_Aias = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getPile("ring"):contains(card_id) then
		return ("jink:Rho_Aias[%s:%s]=%d"):format(suit,number,card_id)
	end
end
--使用结构

function SmartAI:useCardmouthgun(card, use)
	if self.player:hasSkill("noswuyan") then return end
	--暂且忽略对队友使用嘴炮的可能性

	--注意的技能：【屯田】，【纵适】，【鹰扬】

	--拼点事宜
	local cards = sgs.CardList()
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player, cards)
	if not max_card then return end
	local max_point = max_card:getNumber()

	--目标选择
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() < 5 and not enemy:isKongcheng() and self.player:distanceTo(enemy) <= math.max(1, self.player:getHp()) then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end

--	use.card = card
	return
end

function sgs.ai_skill_pindian.mouthgun(minusecard, self, requestor)
	if requestor:getHandcardNum() == 1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return cards[1]
	end
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber() < 6 and  minusecard or maxcard )
end
sgs.ai_skill_choice["mouthgun"] = function(self, choices, data)
	local card = dummyCard("mouthgun")
	
	local pindian = data:toPindian()
	local fromNumber = pindian.from_card:getNumber()
	local toNumber = pindian.to_card:getNumber()
	local winner, loser
	if fromNumber ~= toNumber then
		if fromNumber > toNumber then
			winner = pindian.from
			loser = pindian.to
		else
			winner = pindian.to
			loser = pindian.from
		end
	end
	if self:ajustDamage(winner, self.player, 1, card) == 0 then
		return "mouthgun_fail"
	end
	if self:isWeak() then
		return "mouthgun_qp"
	end
	if self:needToLoseHp(self.player, winner)  then return "mouthgun_fail" end
    return "mouthgun_qp"
end


sgs.ai_skill_cardask["@murasameself"] = function(self,data,pattern,target)
	local card_list = self.player:getHandcards()
	local cards = sgs.QList2Table(card_list)
	self:sortByKeepValue(cards,false)
	return "$"..cards[1]:getEffectiveId()
end
sgs.ai_skill_cardask["@murasamekilla"] = function(self,data,pattern)
	local colour = pattern:split("|")[2]
	local use = data:toCardUse()
	if self:needToThrowArmor() and self.player:getArmor():getColorString()==colour then return "$"..self.player:getArmor():getEffectiveId() end
	if not self:slashIsEffective(use.card,self.player,use.from)
	or (self:ajustDamage(use.from,self.player,1,use.card)<2
	and self:needToLoseHp(self.player,use.from,use.card)) then return "." end
	if self:ajustDamage(use.from,self.player,1,use.card) and self:getCardsNum("Peach")>0 then return "." end
	if self:getCardsNum("Jink")==0 or not sgs.isJinkAvailable(use.from,self.player,use.card,true) then return "." end
	local jiangqin = self.room:findPlayerBySkillName("niaoxiang")
	local need_double_jink = use.from:hasSkill("wushuang")
		or (use.from:hasSkill("roulin") and self.player:isFemale())
		or (self.player:hasSkill("roulin") and use.from:isFemale())
		or (jiangqin and jiangqin:isAdjacentTo(self.player) and use.from:isAdjacentTo(self.player) and self:isEnemy(jiangqin))
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards)do
		if card:getColorString()~=colour or (not self:isWeak() and (self:getKeepValue(card)>8 or self:isValuableCard(card)))
			or (isCard("Jink",card,self.player) and self:getCardsNum("Jink")-1<(need_double_jink and 2 or 1)) then continue end
		return "$"..card:getEffectiveId()
	end
end

sgs.ai_skill_cardask["@murasamekillb"] = sgs.ai_skill_cardask["@murasamekilla"] 
sgs.ai_skill_cardask["@murasamekillc"] = sgs.ai_skill_cardask["@murasamekilla"] 
sgs.ai_skill_invoke.Murasame = function(self, data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return true
	end
	return false
end
sgs.weapon_range.Murasame = 2

sgs.weapon_range.tywz = 2

sgs.ai_skill_invoke.tywz = function(self, data)
	local target = data:toDamage().to
	if target and self:isEnemy(target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.tywz = function(self,player,promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and promptlist[3]=="yes" then
		sgs.updateIntention(player,damage.to,40)
	end
end

sgs.weapon_range.hqiangwei = 2
sgs.ai_skill_discard.hqiangwei = function(self,discard_num,optional,include_equip)
	local target = self.player:getTag("hqiangwei"):toPlayer()
	if not target or self:isFriend(target) then return {} end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	local compare_func = function(a,b)
		return self:getKeepValue(a)<self:getKeepValue(b)
	end
	table.sort(cards,compare_func)
	for _,card in sgs.list(cards)do
		if #to_discard>=1 then break end
		table.insert(to_discard,card:getId())
	end

	return to_discard
end

--收藏价值
sgs.ai_keep_value.mouthgun = 3.16
sgs.ai_keep_value.shuugakulyukou = 3.21
sgs.ai_keep_value.rotenburo = 3.25
sgs.ai_keep_value.bunkasai = 3.35
sgs.ai_keep_value.strike_the_death = 3.24

--使用价值
sgs.ai_use_value.mouthgun = 4.9

sgs.ai_ajustdamage_from["@std"] = function(self, from, to, card, nature)
	return from:getMark("@std")
end

sgs.ai_skill_use["@strike_the_death"] = function(self, prompt)
	local dying = self.room:getCurrentDyingPlayer()
	if dying then
		local peaches = 1-dying:getHp()
		if self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<peaches then
			local cards = sgs.QList2Table(self.player:getCards("he"))
			self:sortByKeepValue(cards)
			local cards = self.player:getHandcards()
			local card
			cards = sgs.QList2Table(cards)

			for _,acard in sgs.list(cards)  do
				if acard:isKindOf("strike_the_death") then
					card = acard
					break
				end
			end
			if not card then
				return "."
			end
			return card:toString()
		end
	end
	
	return "."
end

function SmartAI:useCardstrike_the_death(card,use)
	if self:isWeak() then return end
	use.card = card
	return
end


function SmartAI:useCardrotenburo(card,use)
	local n = 0
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if self.player:canUse(card,p) then
			if self:isFriend(p) then
				n = n+1
				if self:isWeak(p) then
					n = n+1
				end
			elseif self:isEnemy(p) then
				n = n-1
				if self:isWeak(p) then
					n = n-1
				end
			end
		end
	end
	if n>=0 then
		use.card = card
	end
end
sgs.ai_use_priority.rotenburo = 1.4
sgs.ai_keep_value.rotenburo = 4
sgs.ai_use_value.rotenburo = 2.7


function SmartAI:useCardbunkasai(card,use)
	local min = 999
	local target
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if self.player:canUse(card,p) then
			if p:getHandcardNum() < min then
				min = p:getHandcardNum()
				target = p
			end
		end
	end
	if target and self:isEnemy(target) and self:hasTrickEffective(card,target,self.player) and self:isGoodTarget(target) then
		use.card = card
	end
end
sgs.ai_skill_discard.bunkasai = function(self,discard_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	local suit = {}
	-- local use = sgs.filterData[sgs.CardUsed]:toCardUse()
	local usecard = self.room:getTag("bunkasai"):toCard()
	local use = self.room:getTag("UseHistory"..usecard:toString()):toCardUse()
	if use then
		if self:needToLoseHp(self.player,use.from,use.card,true)then return to_discard end
		local min = 999
		local target
		for _,p in sgs.list(use.to)do
			if p:getHandcardNum() < min then
				min = p:getHandcardNum()
				target = p
			end
		end
		if target and self:isFriend(target) and self:hasTrickEffective(use.card,target,use.from) and self:isWeak(target) then
			return to_discard
		end
	end
	for _,card in sgs.list(cards)do
		if #to_discard>=discard_num then break end
		if table.contains(suit,card:getSuitString()) then continue end
		table.insert(to_discard,card:getId())
		table.insert(suit,card:getSuitString())
	end

	return to_discard
end

function SmartAI:useCardtogether_go_die(card,use)
	local slashcount = self:getCardsNum("Slash")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	if slashcount > 0  then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use and dummy_use.card and not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				if p:getHandcardNum() >= self.player:getHandcardNum() then
					use.card = card
					if use.to then use.to:append(p) end
						return
				end
			end
		end
	end
end
sgs.ai_use_priority.together_go_die = sgs.ai_use_priority.Slash + 2

function SmartAI:useCardshuugakulyukou(card,use)
	self:sort(self.friends_noself,"defense")
	for _,friend in sgs.list(self.friends_noself)do
		if  not friend:containsTrick("shuugakulyukou")
		then
			use.card = card
			use.to:append(friend)
			return
		end
	end
end

sgs.ai_card_intention.shuugakulyukou = -40

--[[Elucidator
shuugakulyukou
rotenburo
chopper
bunkasai
mouthgun
Rho_Aias
strike_the_death
kotatsu]]