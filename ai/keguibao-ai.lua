--换英雄

sgs.ai_skill_invoke.guichangetupo = function(self, data)
	--[[local num = math.random(0,1)
	if (num == 0) then
	    return true
	else
		return false
	end]]
	return false
end

--鬼曹操
sgs.ai_skill_invoke.keguiduoyi = function(self, data)
	return (#(sgs.ai_skill_playerschosen.keguiduoyi(self, data:toCardUse().to, 99, 0)) > 0)
end


sgs.ai_skill_playerschosen.keguiduoyi = function(self,targets,max_num,min_num)
	local tos = {}
  	for i,p in sgs.list(targets)do
		if #tos>=max_num then break end
		if self:isEnemy(p)
		then table.insert(tos,p) end
	end
	return tos
end


local keguixianjiVS_skill = {}
keguixianjiVS_skill.name = "keguixianjiVS"
table.insert(sgs.ai_skills, keguixianjiVS_skill)
keguixianjiVS_skill.getTurnUseCard = function(self)
	if self.player:hasFlag("Forbidkeguixianji") then return false end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("TrickCard") then
			return sgs.Card_Parse("#keguixianjiCard:" .. acard:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#keguixianjiCard"] = function(card, use, self)
	if self:needBear() then
		return "."
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("keguixianji") then
			if not friend:hasFlag("keguixianjiInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	end
end

sgs.ai_card_intention["keguixianjiCard"] = function(self, card, from, tos)
	sgs.updateIntention(from, tos[1], -80)
end

--sgs.ai_use_priority["keguixianjiCard"] = 10
sgs.ai_use_value["keguixianjiCard"] = 8.5

function sgs.ai_cardneed.keguihuxiao(to, card, self)
	local cards = to:getHandcards()
	local slash_num = 0
	for _, c in sgs.list(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end
	return card:isRed() and ( card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic")))
end

function sgs.ai_cardneed.keguilongyin(to, card, self)
	local cards = to:getHandcards()
	local slash_num = 0
	for _, c in sgs.list(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end
	return card:isBlack() and ( card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic")))
end

--鬼关羽
sgs.ai_skill_invoke.keguiwumo = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.keguituodao = function(self, targets)
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
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end

function sgs.ai_cardneed.keguisheji(to, card, self)
	local cards = to:getHandcards()
	local slash_num = 0
	for _, c in sgs.list(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end
	return  ( card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic")))
end

sgs.ai_canliegong_skill.keguisheji = function(self, from, to)
	return from:getPhase() == sgs.Player_Play and from:inMyAttackRange(to, 0, true) and to:inMyAttackRange(from, 0, true)
end

sgs.ai_cardneed.keguijueluone = function(to,card,self)
	return isCard("Slash",card,to) and getKnownCard(to,self.player,"Slash",true)==0
end


--鬼华雄
sgs.ai_can_damagehp.keguixiaoshou = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return from:getEquips():length() > 0 and self:doDisCard(from, "he", true)
	end
end
sgs.ai_skill_invoke.keguixiaoshou = function(self, data)
	local damage = data:toDamage()
	if damage.from then
		return self:doDisCard(damage.from, "he", true)
	end
	return true
end

sgs.ai_skill_choice.keguixiaoshou = function(self,choices, data)
	return "move"
end


sgs.ai_skill_choice.keguixiaoshou_equip = function(self,choices, data)
	local target = data:toPlayer()
	choices = choices:split("+")
	if target then
		if self:isFriend(target) and self:needToThrowArmor(target) and table.contains(choices, "1") then
			return "1"
		end
	end
	local x = math.floor(math.random(0, #choices))
	return choices[x]
end

sgs.ai_skill_playerchosen.keguixiaoshou = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, friend in ipairs(self.friends_noself) do
		if self:loseEquipEffect(friend) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.need_equip_skill, friend) then
			return friend
		end
	end
	return self.player
end

--鬼诸葛亮
sgs.ai_skill_invoke.keguizhuangshen = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.keguizhuangshen = function(self, targets)
	targets = sgs.QList2Table(targets)
	return targets[math.random(1, #targets)]
end

sgs.ai_skill_choice.keguizhuangshen = function(self,choices,data)
	local player = data:toPlayer()
	local skills = choices:split("+")
	--[[if self:isFriend(player) then
		for _,sk in sgs.list(skills)do
			if string.find(sgs.bad_skills,sk) and player:hasSkill(sk) then return sk end
		end
		return skills[1]
	end]]
	
	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player,true) then
			return sk
		end
	end
	
	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player) then
			return sk
		end
	end
	
	local not_bad_skills = {}
	for _,sk in sgs.list(skills)do
		if string.find(sgs.bad_skills,sk) then continue end
		table.insert(not_bad_skills,sk)
	end
	if #not_bad_skills>0 then
		return not_bad_skills[math.random(1,#not_bad_skills)]
	end
	
	return skills[math.random(1,#skills)]
end


--鬼曹节
local keguitiqi_skill = {}
keguitiqi_skill.name= "keguitiqi"
table.insert(sgs.ai_skills,keguitiqi_skill)
keguitiqi_skill.getTurnUseCard=function(self)
	if not self.player:canDiscard(self.player, "he") then return end
	if #self.enemies > 0 then return sgs.Card_Parse("#keguitiqiCard:.:") end
	return 
end
sgs.ai_skill_use_func["#keguitiqiCard"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	local cards = self.player:getCards("he")
	
	local use_card = {}
	cards = sgs.QList2Table(cards)
	if #cards == 0 then return end
	self:sortByKeepValue(cards)
	if self:needToThrowArmor() then
		table.insert(use_cards, self.player:getArmor():getEffectiveId())
	end

	for _, card in ipairs(cards) do
		if not table.contains(use_card, card:getEffectiveId()) then
			table.insert(use_card, card:getId())
		end
	end
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		and self.player:getHp()>enemy:getHp() and self.player:getHp()>1
		then
			targets:append(enemy) 
			if targets:length() >= #use_card then
				break
			end
		end
	end
	
	if targets:length() < #use_card  then
		for i = 1, #use_card - targets:length(), 1 do
			table.removeOne(use_card, use_card[#use_card])
		end
		
	end
	if targets:length()> 0 then
		if #use_card == 1 then
		use.card = sgs.Card_Parse("#keguitiqiCard:"..use_card[1] ..":")
		else
		use.card = sgs.Card_Parse("#keguitiqiCard:".. table.concat(use_card, "+")..":")
		end
		if use.to then use.to = targets end
		return
	end
end


sgs.ai_use_value.keguitiqiCard = 2.5
sgs.ai_card_intention.keguitiqiCard = 80
sgs.dynamic_value.damage_card.keguitiqiCard = true


--司马徽

local keguishouye_skill = {}
keguishouye_skill.name = "keguishouye"
table.insert(sgs.ai_skills, keguishouye_skill)
keguishouye_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("keguishouyeCard") then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = sgs.IntList()
	for _, acard in ipairs(cards) do
		to_throw:append(acard:getEffectiveId())
	end
	card_id = to_throw:at(0)
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("#keguishouyeCard:"..card_id..":")
	end
end


sgs.ai_skill_use_func["#keguishouyeCard"] = function(card, use, self)
	if not self.player:hasUsed("#keguishouyeCard") then
		if self.player:getMark("@guijiehuo") > 0  then
			local deathplayer = {}
			for _,p in sgs.qlist(self.room:getPlayers()) do
				if p:isDead() and ((p:getRole() == self.player:getRole())
				or (p:getRole() == "loyalist" and self.player:isLord())) then
					table.insert(deathplayer,p:getGeneralName())
				end
			end
			if #deathplayer>0 then 
			use.card = card
			if use.to then use.to:append(self.player) end
			return
			end
		end
		for _, friend in ipairs(self.friends) do
			if self:hasSkills(sgs.cardneed_skill, friend) and self:canDraw(friend, self.player) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
        self:sort(self.friends)
		for _, friend in ipairs(self.friends) do
			if self:isWeak(friend)  and self:canDraw(friend, self.player) then
			use.card = card
			if use.to then use.to:append(friend) end
			return
			end
	end
		for _, friend in ipairs(self.friends) do
				use.card = card
				if use.to then use.to:append(friend) end
				return
		end
	end
end

sgs.ai_use_value.keguishouyeCard = 8.5
sgs.ai_use_priority.keguishouyeCard = 9.5
sgs.ai_card_intention.keguishouyeCard = -80

local keguijiehuo_skill = {}
keguijiehuo_skill.name = "keguijiehuo"
table.insert(sgs.ai_skills,keguijiehuo_skill)
keguijiehuo_skill.getTurnUseCard = function(self)
	if self.player:getMark("@guijiehuo") == 0 then return end
	local deathplayer = {}
	for _,p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and ((p:getRole() == self.player:getRole())
		 or (p:getRole() == "loyalist" and self.player:isLord())) then
			table.insert(deathplayer,p:getGeneralName())
		end
	end
	if #deathplayer==0 then return end
	if self.player:getHandcardNum()>=4 then
		local spade,club,heart,diamond
		for _,card in sgs.list(self.player:getHandcards())do
			if card:getSuit()==sgs.Card_Spade then spade = true
			elseif card:getSuit()==sgs.Card_Club then club = true
			elseif card:getSuit()==sgs.Card_Heart then heart = true
			elseif card:getSuit()==sgs.Card_Diamond then diamond = true
			end
		end
		if spade and club and diamond and heart then
			return sgs.Card_Parse("#keguijiehuoCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#keguijiehuoCard"] = function(card,use,self)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	local need_cards = {}
	local spade,club,heart,diamond
	for _,card in sgs.list(cards)do
		if card:getSuit()==sgs.Card_Spade and not spade then spade = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Club and not club then club = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Heart and not heart then heart = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Diamond and not diamond then diamond = true table.insert(need_cards,card:getId())
		end
	end
	if #need_cards<4 then return end
	local greatyeyan = sgs.Card_Parse("#keguijiehuoCard:"..table.concat(need_cards,"+")..":")
	assert(greatyeyan)
	use.card = greatyeyan
end

sgs.ai_use_value["#keguijiehuoCard"] = 8
sgs.ai_use_priority["#keguijiehuoCard"] = 9.5
sgs.ai_use_priority.keguijiehuoCard = 9.5

sgs.ai_skill_choice["shenji-ask"] = function(self, choices, data)
	local items = choices:split("+")
	for _, p_name in ipairs(items) do
		for _,p in sgs.qlist(self.room:getPlayers()) do
			if p:getGeneralName() == p_name and ((p:getRole() == self.player:getRole())
			 or (p:getRole() == "loyalist" and self.player:isLord())) then
				return p_name
			end
		end
	end
	return items[math.random(1, #items)]
end


--沙摩柯

sgs.ai_skill_invoke.keguiqinwang = function(self, data)
	local target = data:toPlayer()
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if not self:isFriend(target) or (damage.from and self:isFriend(damage.from)) then return false end
	if self:needToLoseHp(target, damage.from, damage.card) then return false end
	if self.player:getHandcardNum() + self.player:getEquips():length() < 2 and not self:isWeak(target) then return false end


	if self:isWeak(target) and not self:isWeak() then return true end

	return false
end


sgs.ai_ajustdamage_from.keguiqinwang = function(self, from, to, card, nature)
    if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and from:getPhase() == sgs.Player_Play then
        return from:getMark("@guiqinwang")
    end
end



--界鬼曹操
sgs.ai_skill_invoke.kejieguiduoyi = function(self, data)
	return (#(sgs.ai_skill_playerschosen.kejieguiduoyi(self, data:toCardUse().to, 99, 0)) > 0)
end


sgs.ai_skill_playerschosen.kejieguiduoyi = function(self,targets,max_num,min_num)
	local tos = {}
  	for i,p in sgs.list(targets)do
		if #tos>=max_num then break end
		if self:isEnemy(p)
		then table.insert(tos,p) end
	end
	return tos
end


local kejieguixianjiVS_skill = {}
kejieguixianjiVS_skill.name = "kejieguixianjiVS"
table.insert(sgs.ai_skills, kejieguixianjiVS_skill)
kejieguixianjiVS_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("TrickCard") then
			return sgs.Card_Parse("#kejieguixianjiCard:" .. acard:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#kejieguixianjiCard"] = function(card, use, self)
	if self:needBear() then
		return "."
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("kejieguixianji") then
			if not friend:hasFlag("kejieguixianjiInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	end
end

sgs.ai_card_intention["#kejieguixianjiCard"] = function(self, card, from, tos)
	sgs.updateIntention(from, tos[1], -80)
end

sgs.ai_use_priority["kejieguixianjiCard"] = 10
sgs.ai_use_value["kejieguixianjiCard"] = 8.5


--界鬼诸葛亮
sgs.ai_skill_invoke.kejieguizhuangshen = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kejieguizhuangshen = function(self, targets)
	targets = sgs.QList2Table(targets)
	return targets[math.random(1, #targets)]
end

sgs.ai_skill_choice.kejieguizhuangshen = function(self,choices,data)
	local player = data:toPlayer()
	local skills = choices:split("+")
	--[[if self:isFriend(player) then
		for _,sk in sgs.list(skills)do
			if string.find(sgs.bad_skills,sk) and player:hasSkill(sk) then return sk end
		end
		return skills[1]
	end]]
	
	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player,true) then
			return sk
		end
	end
	
	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player) then
			return sk
		end
	end
	
	local not_bad_skills = {}
	for _,sk in sgs.list(skills)do
		if string.find(sgs.bad_skills,sk) then continue end
		table.insert(not_bad_skills,sk)
	end
	if #not_bad_skills>0 then
		return not_bad_skills[math.random(1,#not_bad_skills)]
	end
	
	return skills[math.random(1,#skills)]
end

sgs.ai_skill_playerchosen.kejieguizhuangshenbuff = function(self, targets)
	local cardstr = sgs.ai_skill_use["@@dawu"](self, "@dawu")
	if cardstr:match("->") then
		local targetstr = cardstr:split("->")[2]:split("+")
		if #targetstr > 0 then
			local target = self.room:findPlayerByObjectName(targetstr[1])
			return target
		end
	end
	local cardstr = sgs.ai_skill_use["@@kuangfeng"](self, "@kuangfeng")
	if cardstr:match("->") then
		local targetstr = cardstr:split("->")[2]:split("+")
		if #targetstr > 0 then
			local target = self.room:findPlayerByObjectName(targetstr[1])
			return target
		end
	end
	return self.player
end

sgs.ai_skill_choice.kejieguizhuangshenbuff = function(self,choices,data)
	local player = data:toPlayer()
	if self:isFriend(player) then
		return "guidawu"
	else
		return "guikuangfeng"
	end
	
	return "guikuangfeng"
end

--second

sgs.ai_skill_invoke.kejieguiqideng = function(self, data)
	local damage = data:toDying().damage
	return self:getAllPeachNum() < self.player:getHp() or (damage and damage.card and damage.card:hasFlag("zhashicardflag"))
end

local kejieguizhashi_skill = {}
kejieguizhashi_skill.name = "kejieguizhashi"
table.insert(sgs.ai_skills, kejieguizhashi_skill)
kejieguizhashi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kejieguizhashiCard") then return end
	return sgs.Card_Parse("#kejieguizhashiCard:.:")
end

sgs.ai_skill_use_func["#kejieguizhashiCard"] = function(card, use, self)
    if not self.player:hasUsed("#kejieguizhashiCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local targets = {}
		local distance = use.DefHorse and 1 or 0
	for _,enemy in ipairs(self.enemies)do
		if enemy:distanceTo(self.player,distance)<=enemy:getAttackRange() and self:isTiaoxinTarget(enemy) 
		and self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player)
		then
			table.insert(targets,enemy)
		end
	end

	if #targets==0 then return end

	sgs.ai_use_priority["#kejieguizhashiCard"] = 8
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _,card in sgs.qlist(self.player:getCards("h"))do
			if card:isKindOf("Armor") and self:evaluateArmor(card)>3 then
				sgs.ai_use_priority["#kejieguizhashiCard"] = 5.9
				break
			end
		end
	end

	if use.to then
		self:sort(targets,"defenseSlash")
		use.to:append(targets[1])
	end
	use.card = sgs.Card_Parse("#kejieguizhashiCard:.:")
	end
end

sgs.ai_use_value["kejieguizhashiCard"] = 8.5
sgs.ai_use_priority["kejieguizhashiCard"] = 9.5
sgs.ai_card_intention["kejieguizhashiCard"] = 80


--鬼张飞

sgs.ai_skill_invoke.kejieguilongyin = function(self, data)
	return sgs.ai_skill_playerchosen.kejieguilongyin(self, self.room:getAlivePlayers()) ~= nil
end

sgs.ai_skill_playerchosen.kejieguilongyin = function(self, targets)
	targets = sgs.QList2Table(targets)
	if self.player:getRole() == "loyalist" and self:isWeak(self.room:getLord()) then return  self.room:getLord() end
	local theweak = sgs.SPlayerList()
	local theweaktwo = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
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
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end

sgs.ai_skill_invoke.jueqiaogainslash = function(self, data)
	return true
end


sgs.ai_ajustdamage_from.kejieguixiaoyin = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:isRed()
	then
		return 1
	end
end
function sgs.ai_cardneed.kejieguixiaoyin(to, card, self)
	local cards = to:getHandcards()
	local slash_num = 0
	for _, c in sgs.list(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end
	return ( card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic")))
end





--界鬼关羽

sgs.ai_skill_invoke.kejieguiwumo = function(self, data)
	return true
end
sgs.ai_cardneed.kejieguiwumo = function(to,card,self)
	return (isCard("Slash",card,to) and card:isRed())
end
sgs.ai_card_priority.kejieguiwumo = function(self,card)
	if card:isKindOf("Slash") and card:isRed()
	then return 0.05 end
end

sgs.ai_skill_choice.kejieguituodao = function(self, choices, data)
	if self:getEnemyNumBySeat(self.room:getCurrent(),self.player,self.player,true)>self.room:getAlivePlayers():length()/2 and self.player:getMark("&jieguiwumozhuangbei-SelfClear") == 0 then
		return "dao"
	end
	local players = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:canSlash(p, nil, false) then
			players:append(p)
		end
	end
	if players:length() > 0 and sgs.ai_skill_playerchosen.zero_card_as_slash(self, players) then
		return "sha"
	else
		return "dao"
	end	 
end

sgs.ai_skill_playerchosen.kejieguituodao = sgs.ai_skill_playerchosen.zero_card_as_slash


--界鬼吕布

sgs.ai_skill_invoke.kejieguisheji = function(self, data)
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	local target = data:toPlayer()
	local slash = use.card
	local from = use.from
	if from and self:isFriend(from) then return false end
	local willSave = false
	local friend
	if self:isFriend(target) and self:slashIsEffective(slash, target, from) then
		return true
	end
	if self:isEnemy(from) and self:damageIsEffective(from, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(from) then
		return true
	end
	
	return false
end
sgs.ai_cardneed.kejieguisheji = sgs.ai_cardneed.bignumber

function sgs.ai_skill_pindian.kejieguisheji(minusecard,self,requestor,maxcard)
	local req
	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if p:hasFlag("kejieguishejiPindianTarget") then
			target = p
			break
		end
	end
	if self.player:objectName()==requestor:objectName() then
		req = self.room:getTag("CurrentUseStruct"):toCardUse().from
	else
		req = requestor
	end
	local cards,maxcard = sgs.QList2Table(self.player:getHandcards()),nil
	local max_value = 0
	self:sortByKeepValue(cards)
	max_value = self:getKeepValue(cards[#cards])
	local function compare_func1(a,b)
		return a:getNumber()>b:getNumber()
	end
	local function compare_func2(a,b)
		return a:getNumber()<b:getNumber()
	end
	if target and self:isFriend(target) and self:isWeak(target) and self.player:objectName() ~= req:objectName() then
	--if self:isFriend(req) and self.player:getHp()>req:getHp() then
		table.sort(cards,compare_func2)
	else
		table.sort(cards,compare_func1)
	end
	for _,card in sgs.list(cards)do
		if max_value>7 or self:getKeepValue(card)<7 or card:isKindOf("EquipCard") then maxcard = card break end
	end
	return maxcard or cards[1]
end

sgs.ai_cardneed.kejieguijuelu = sgs.ai_cardneed.slash


--界鬼华雄

sgs.ai_can_damagehp.kejieguixiaoshou = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return from:getEquips():length() > 0 and self:doDisCard(from, "e", true)
	end
end
sgs.ai_skill_invoke.kejieguixiaoshou = function(self, data)
	local damage = data:toDamage()
	if damage.from and damage.to:objectName() == self.player:objectName() then
		return self:doDisCard(damage.from, "e", true)
	elseif damage.from and damage.from:objectName() == self.player:objectName() then
		return self:doDisCard(damage.to, "e", true)
	end
	return true
end

sgs.ai_skill_choice.kejieguixiaoshou = function(self,choices, data)
	return "move"
end


sgs.ai_skill_choice.kejieguixiaoshou_equip = function(self,choices, data)
	local target = data:toPlayer()
	choices = choices:split("+")
	if target then
		if self:isFriend(target) and self:needToThrowArmor(target) and table.contains(choices, "1") then
			return "1"
		end
	end
	return choices[1]
end

sgs.ai_skill_playerchosen.kejieguixiaoshou = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, friend in ipairs(self.friends_noself) do
		if self:loseEquipEffect(friend) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.need_equip_skill, friend) then
			return friend
		end
	end
	return self.player
end

sgs.ai_can_damagehp.kejieguifuwang = function(self, from, card, to)
	return to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to) and self.room:getLord():isMale() and from and from:isFemale()
end






local kejieguishouye_skill = {}
kejieguishouye_skill.name = "kejieguishouye"
table.insert(sgs.ai_skills, kejieguishouye_skill)
kejieguishouye_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kejieguishouyeCard") then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = sgs.IntList()
	for _, acard in ipairs(cards) do
		to_throw:append(acard:getEffectiveId())
	end
	card_id = to_throw:at(0)
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("#kejieguishouyeCard:"..card_id..":")
	end
end


sgs.ai_skill_use_func["#kejieguishouyeCard"] = function(card, use, self)
	if not self.player:hasUsed("#kejieguishouyeCard") then
		if self.player:getMark("&kejieguijiehuo") < 4 and self.player:hasSkill("kejieguijiehuo")  then
			local deathplayer = {}
			for _,p in sgs.qlist(self.room:getPlayers()) do
				if p:isDead() and ((p:getRole() == self.player:getRole())
				or (p:getRole() == "loyalist" and self.player:isLord())) then
					table.insert(deathplayer,p:getGeneralName())
				end
			end
			if #deathplayer>0 then 
			use.card = card
			if use.to then use.to:append(self.player) end
			return
			end
		end
		for _, friend in ipairs(self.friends) do
			if self:hasSkills(sgs.cardneed_skill, friend) and self:canDraw(friend, self.player) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
        self:sort(self.friends)
		for _, friend in ipairs(self.friends) do
			if self:isWeak(friend)  and self:canDraw(friend, self.player) then
			use.card = card
			if use.to then use.to:append(friend) end
			return
			end
		end
		for _, friend in ipairs(self.friends) do
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
end

sgs.ai_use_value.kejieguishouyeCard = 8.5
sgs.ai_use_priority.kejieguishouyeCard = 9.5
sgs.ai_card_intention.kejieguishouyeCard = -80

local kejieguijiehuo_skill = {}
kejieguijiehuo_skill.name = "kejieguijiehuo"
table.insert(sgs.ai_skills,kejieguijiehuo_skill)
kejieguijiehuo_skill.getTurnUseCard = function(self)
	if self.player:getMark("&kejieguijiehuo") >= 4 then return end
	local deathplayer = {}
	for _,p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and ((p:getRole() == self.player:getRole())
		 or (p:getRole() == "loyalist" and self.player:isLord())) then
			table.insert(deathplayer,p:getGeneralName())
		end
	end
	if #deathplayer==0 then return end
	if self.player:getHandcardNum()>=3 then
		local spade,club,heart,diamond
		for _,card in sgs.list(self.player:getHandcards())do
			if card:getSuit()==sgs.Card_Spade then spade = true
			elseif card:getSuit()==sgs.Card_Club then club = true
			elseif card:getSuit()==sgs.Card_Heart then heart = true
			elseif card:getSuit()==sgs.Card_Diamond then diamond = true
			end
		end
		local suit = 0
		if spade then
			suit = suit + 1
		end
		if club then
			suit = suit + 1
		end
		if heart then
			suit = suit + 1
		end
		if diamond then
			suit = suit + 1
		end
		if suit >= 3 then
			return sgs.Card_Parse("#kejieguijiehuoCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#kejieguijiehuoCard"] = function(card,use,self)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	local need_cards = {}
	local spade,club,heart,diamond
	for _,card in sgs.list(cards)do
		if card:getSuit()==sgs.Card_Spade and not spade and #need_cards < 3 then spade = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Club and not club and #need_cards < 3 then club = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Heart and not heart and #need_cards < 3 then heart = true table.insert(need_cards,card:getId())
		elseif card:getSuit()==sgs.Card_Diamond and not diamond and #need_cards < 3 then diamond = true table.insert(need_cards,card:getId())
		end
	end
	if #need_cards<3 then return end
	local greatyeyan = sgs.Card_Parse("#kejieguijiehuoCard:"..table.concat(need_cards,"+")..":")
	assert(greatyeyan)
	use.card = greatyeyan
end

sgs.ai_use_value["#kejieguijiehuoCard"] = 8
sgs.ai_use_priority["#kejieguijiehuoCard"] = 9.5
sgs.ai_use_priority.kejieguijiehuoCard = 9.5







