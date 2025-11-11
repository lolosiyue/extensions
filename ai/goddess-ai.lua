local GodQuxiang_skill = {}
GodQuxiang_skill.name = "GodQuxiang"
table.insert(sgs.ai_skills, GodQuxiang_skill)

GodQuxiang_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return end
	local can = false
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local subcards = {}
	self:sortByUseValue(cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
			if card:isBlack() then table.insert(cardsq, card) end
	end
	if #cardsq == 0  then return end
	if self:getKeepValue(cardsq[1])  > 18 then return end
	if self:getUseValue(cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getId())
	local card_str = "SavageAssault:GodQuxiang[to_be_decided:0]="..table.concat(subcards, "+")
	local AsCard = sgs.Card_Parse(card_str)
	assert(AsCard)
	return AsCard
end


sgs.ai_skill_choice["GodShenfu"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1,#items)]
end

local GodShijun_skill = {}
GodShijun_skill.name = "GodShijun"
table.insert(sgs.ai_skills, GodShijun_skill)
GodShijun_skill.getTurnUseCard = function(self)
	if not self.player:canDiscard(self.player,"he") then return end
	return sgs.Card_Parse("#GodShijunCard:.:")
end

sgs.ai_skill_use_func["#GodShijunCard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	self:sortByUseValue(cards,true)
	if slashcount > 0  then
		for _, card in ipairs(cards) do
				if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
				local slash = self:getCard("Slash")
					assert(slash)
					self.player:setFlags("InfinityAttackRange")
					local dummy_use = self:aiUseCard(slash,dummy(true))
					self.player:setFlags("-InfinityAttackRange")
					if dummy_use.card and dummy_use.to:length() > 0 then
						local target
						for _, enemy in ipairs(self.enemies) do
							if not self.player:inMyAttackRange(enemy) then
								target = enemy
							else
								return
							end
						end
						if target then
						use.card = sgs.Card_Parse("#GodShijunCard:"..card:getId()..":")
								if use.to then use.to:append(target) end
								return
						end
					end
				end
			end
	end
end

sgs.ai_card_intention["GodShijunCard"] = 70


sgs.ai_use_value["GodShijunCard"] = 9.2
sgs.ai_use_priority["GodShijunCard"] = sgs.ai_use_priority.Slash + 0.1

local GodYouhua_skill = {}
GodYouhua_skill.name = "GodYouhua"
table.insert(sgs.ai_skills, GodYouhua_skill)
GodYouhua_skill.getTurnUseCard = function(self)
	if self.player:isNude() then return nil end
	if self.player:getMark("LastId") == 0 or self.player:hasFlag("YouhuaUsed") then return nil end 
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local card = cards[1]
	local Id = self.player:getMark("LastId")
		
	if card and self.player:getMark("LastId") > 0 then
		local NewCard = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(Id):objectName(), sgs.Card_SuitToBeDecided, -1)
        if NewCard:isKindOf("IronChain") then return nil end
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		NewCard:setSkillName("GodYouhua")
		local card_str = nil
		if self.player:getMark("LastId") > 0 then 
			card_str = (NewCard:toString()..":GodYouhua[%s:%s]=%d"):format(suit, number, card_id)
		end
		local new_card = sgs.Card_Parse(card_str)
		
		assert(new_card) 
		return new_card
	end
end	




local GodGongshen_skill = {}
GodGongshen_skill.name = "GodGongshen"
table.insert(sgs.ai_skills, GodGongshen_skill)

GodGongshen_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return end
	local can = false
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local subcards = {}
	self:sortByUseValue(cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") then table.insert(cardsq, card) end
	end
	if #cardsq == 0  then return end
	if self:getKeepValue(cardsq[1])  > 18 then return end
	if self:getUseValue(cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getId())
	local card_str = "ArcheryAttack:GodGongshen[to_be_decided:0]="..table.concat(subcards, "+")
	local AsCard = sgs.Card_Parse(card_str)
	assert(AsCard)
	return AsCard
end



sgs.ai_skill_playerchosen["GodJiuse"] = function(self, targets)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	targets = sgs.QList2Table(targets)
			if self:isEnemy(damage.to) then	
					self:sort(targets, "defense")
					for _, anotherenemy in ipairs(targets) do
						if  self:ajustDamage(damage.from,damage.to,damage.damage,damage.card) > 0 then
							if self:isWeak(damage.to) then
								if self:isEnemy(anotherenemy) and self:ajustDamage(anotherenemy,damage.to,damage.damage,damage.card) > 0 then
									return anotherenemy
								end
							else
								if self:isFriend(anotherenemy) and self:ajustDamage(anotherenemy,damage.to,damage.damage,damage.card) > 0  then
									return anotherenemy
								end
						end
					end
				end
			end
	--end
	return nil
end

sgs.ai_ajustdamage_from.GodJiuse = function(self, from, to, card, nature)
	if (card and card:isKindOf("Slash")) and from:getPhase() == sgs.Player_Play	then
		for _,p in sgs.qlist(self.room:getOtherPlayers(from)) do
			if p:isMale() and p:inMyAttackRange(to) then
				return 1
			end
		end
	end
end
sgs.ai_cardneed.GodJiuse = sgs.ai_cardneed.slash


sgs.ai_skill_invoke.GodManwu = function(self, data)
	local card = sgs.Sanguosha:getCard(tonumber(self.room:getTag("GodManwu"):toString()))
	if self:isWeak() and (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then return true end
	if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow") and card:isKindOf("Slash") then return true end
	if not self:isWeak() and (card:isKindOf("Snatch") or card:isKindOf("ExNihilo") or card:isKindOf("Dismantlement")) then return true end
	return false
end


sgs.ai_skill_choice["LuaDanji"] = function(self, choices, data)
	local items = choices:split("+")
	if self.player:isWeak() then
		return "distwocards"
	end
	return items[math.random(1,#items)]
end

function sgs.ai_skill_invoke.LuaXJianshou(self, data)
	local sbdiaochan = self.room:findPlayerBySkillName("lihun")
	if sbdiaochan and sbdiaochan:faceUp() and not self:willSkipPlayPhase(sbdiaochan)
		and (self:isEnemy(sbdiaochan) or (sgs.turncount <= 1 and sgs.ai_role[sbdiaochan:objectName()] == "neutral")) then return false end
	if not self.player:faceUp() then return true end
	for _, friend in ipairs(self.friends) do
		if self:hasSkills("fangzhu|jilve", friend) then return true end
		if friend:hasSkill("junxing") and friend:faceUp() and not self:willSkipPlayPhase(friend)
			and not (friend:isKongcheng() and self:willSkipDrawPhase(friend)) then
			return true
		end
	end
	return self:isWeak()
end

sgs.ai_target_revises.LuaTiebi = function(to,card)
	if card:isKindOf("Dismantlement") and not to:faceUp()
	then return true end
end

sgs.bad_skills = sgs.bad_skills .. "|GodXiaoshi"


sgs.ai_cardneed.GodSaodang = sgs.ai_cardneed.slash

sgs.ai_target_revises.GodYuxiang = function(to,card)
	if card:isKindOf("SavageAssault")
	then return true end
end


function SmartAI:useCardshot(card,use)
	local extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	function slashNoTarget(target)
		if isCurrent(use,target)
		or use.to:contains(target) then return end
		if use.card and use.card~=card then
			extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,use.card)
			if use.extra_target then extraTarget = extraTarget+use.extra_target end
		end
		if use.to:length()>extraTarget then return true end
		if CanToCard(use.card or card,self.player,target)
		and self:ajustDamage(self.player,target,1,use.card or card)~=0 then
			if (card:isKindOf("thunder_shot") or card:isKindOf("fire_shot"))
			and hasChainEffect(target,self.player) then
				if self:isGoodChainTarget(target,card) then
					use.card = card
					use.to:append(target)
				end
			else
				use.card = card
				use.to:append(target)
			end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if sgs.ai_role[friend:objectName()]==sgs.ai_role[self.player:objectName()]
		and self:isPriorFriendOfSlash(friend,use.card or card)
		and slashNoTarget(friend) then return end
	end
	
	local forbidden = {}
	self:sort(self.enemies,"defenseSlash")
	for _,enemy in ipairs(self.enemies)do
		if self:isGoodTarget(enemy,self.enemies,use.card or card) then
			if self:objectiveLevel(enemy)<=3
			then table.insert(forbidden,enemy)
			elseif slashNoTarget(enemy)
			then return end
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if sgs.ai_role[friend:objectName()]==sgs.ai_role[self.player:objectName()]
		and (use.card or card):getSkillName()~="lihuo"
		and not(friend:isLord() and #self.enemies<1)
		and self:needToLoseHp(friend,self.player,use.card or card,true)
		and self:ajustDamage(self.player,friend,1,use.card or card)==1
		and slashNoTarget(friend) then return end
	end
	for _,target in ipairs(forbidden)do
		if slashNoTarget(target) then return end
	end
end
sgs.ai_use_priority.shot = 4.55
sgs.ai_use_value.shot = 9
sgs.ai_keep_value.shot = 1.0
sgs.ai_card_intention.shot = 40
function SmartAI:useCardthunder_shot(...)
	self:useCardshot(...)
end
sgs.card_damage_nature.thunder_shot = "T"

sgs.ai_card_intention.thunder_shot = sgs.ai_card_intention.shot
sgs.ai_use_value.thunder_shot = 4.6
sgs.ai_keep_value.thunder_shot = 3.63
sgs.ai_use_priority.thunder_shot = 2.5

function SmartAI:useCardfire_shot(...)
	self:useCardshot(...)
end
sgs.card_damage_nature.fire_shot = "F"

sgs.ai_card_intention.fire_shot = sgs.ai_card_intention.shot
sgs.ai_use_value.fire_shot = 4.6
sgs.ai_keep_value.fire_shot = 3.63
sgs.ai_use_priority.fire_shot = 2.5



sgs.ai_skill_cardask["shot-jink"] = function(self,data,pattern,target)
	local slash = dummyCard()
	local effect = data:toCardEffect()
	if type(data)=="userdata" then slash = data:toCardEffect().card end
	if not target or sgs.ai_skill_cardask.nullfilter(self,data,pattern,target)=="."
	or (slash:isKindOf("fire_shot") or slash:isKindOf("thunder_shot")) and self.player:isChained() and self:isGoodChainTarget(self.player,slash,target)then return "." end
	local n = self:ajustDamage(effect.from,effect.to,1,effect.card)
	if self:needToLoseHp(self.player,target,slash) and n==1
	then return "." end
	function getJink()
		if #self.friends_noself>0 and self:getCardsNum("Peach,Analeptic")<1
		and self.player:getHp()<=math.abs(n) then
			self:speak("noJink")
			-- self.room:getThread():delay(math.random(sgs.delay*0.5,sgs.delay*1.5))
		end
		return "."
	end
	if self:isFriend(target) then
		if self.player:getLostHp()==0 and self.player:isMale() and target:hasSkill("jieyin") then return "." end
		if not hasJueqingEffect(target,self.player) then
			if (target:hasSkill("nosrende") or target:hasSkill("rende") and not target:hasUsed("RendeCard")) and self.player:hasSkill("jieming")
			or target:hasSkill("pojun") and not self.player:faceUp()
			then return "." end
		end
	else
		if n>1 or n>=self.player:getHp() then return getJink() end
		local current = self.room:getCurrent()
		if current and current:hasSkill("juece") and self.player:getHp()>0 then
			for _,c in sgs.list(self:getCards("Jink"))do
				if self.player:isLastHandCard(c,true)
				then return "." end
			end
		end
		if self.player:getHandcardNum()==1 and self:needKongcheng()
		or not(self:hasLoseHandcardEffective() or self.player:isKongcheng()) then return getJink() end
		if self.player:getHp()>1 and getKnownCard(target,self.player,"Slash")>0
		and getKnownCard(target,self.player,"Analeptic")>0 and self:getCardsNum("Jink")<=1
		and (target:getPhase()<=sgs.Player_Play or self:slashIsAvailable(target) and target:canSlash(self.player))
		then return "." end
	end
	return getJink()
end


sgs.ai_skill_cardask["Kai-Jink"] = function(self,data,pattern,target)
	local isUse = data:toStringList()[3] == "use"
	local use 
	if isUse then
		if data:toStringList()[4] then 
			use = self.room:getTag("UseHistory"..data:toStringList()[4]):toCardUse()
		end
	end
	function getKai()
		if sgs.AIHumanized then
			-- self.room:getThread():delay(math.random(sgs.delay*0.3,sgs.delay*1.3))
		end
		for _,c in sgs.list(self:getCard("Kai",true))do
			if self.player:hasFlag("dahe") and c:getSuit()~=sgs.Card_Heart then continue end
			return c:toString()
		end
		if sgs.AIHumanized and math.random()<0.5 and #self.friends_noself>0 and self:getCardsNum("Peach,Analeptic")<1
		and self.player:getHp()<=math.abs(n) then
			self:speak("noJink")
			-- self.room:getThread():delay(math.random(sgs.delay*0.5,sgs.delay*1.5))
		end
		return "."
	end
	if isUse then
		if use.card and use.card:hasFlag("NosJiefanUsed") then return getKai()  end
		if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
		or use.card:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player,use.card,use.from)
		or self:needToLoseHp(self.player,use.from,use.card) and self:ajustDamage(use.from,self.player,1,use.card)==1 then return "." end
	end
	if self:needToLoseHp(self.player, use.from, use.card, true) then return "."  end
	if self:getCardsNum("Jink") == 0 then return getKai() end
	if self:ajustDamage(use.from,self.player,1,use.card)>1 then return getKai() end
end

sgs.ai_use_value.Kai = 9
sgs.ai_keep_value.Kai = 5.3

sgs.ai_skill_cardask["PoAskPo"] = function(self,data,pattern,target)
	local use = data:toCardUse()
	local Weikai = self.room:getTag("Weikai"):toCard()
	if use.from and self:isEnemy(use.from) then
		if Weikai then
			return "."
		else
			for _,c in sgs.list(self:getCard("Weikai",true))do
				return c:toString()
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["@PoAsk"] = function(self,data,pattern,target)
	local use = data:toCardUse()
	if use.from and self:isEnemy(use.from) then
		for _,c in sgs.list(self:getCard("Weikai",true))do
			return c:toString()
		end
	end
	return "."
end
sgs.ai_skill_cardask["@PoAskAgain"] = function(self,data,pattern,target)
	for _,c in sgs.list(self:getCard(pattern,true))do
		return c:toString()
	end
	return true
end
sgs.ai_keep_value.Weikai = 5.2

function SmartAI:useCardSu(card,use)
	self:sort(self.friends,"hp")
	local extraTarget = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.friends)do
		if isCurrent(use,ep) then continue end
		if self.player:canUse(card,ep) then
	    	use.card = card
	    	use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end
sgs.ai_use_priority.Su = 2.4
sgs.ai_keep_value.Su = 2.2
sgs.ai_use_value.Su = 4.7
sgs.ai_card_intention.Su = -33

function SmartAI:useCardgongcheng(card,use)
	local slash = self:getCard("Slash")
	if slash and #self:getCards("Slash") > 1 then
		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
			use.card = card
		end
	end
end
sgs.ai_use_priority.gongcheng = 2.7
sgs.ai_keep_value.gongcheng = 2.2
sgs.ai_use_value.gongcheng = 4.7

function SmartAI:useCardxianzhencard(card,use)
	local dismantlement = sgs.Sanguosha:cloneCard("dismantlement",sgs.Card_NoSuit,0)
	dismantlement:deleteLater()
	local dummy_use = self:aiUseCard(dismantlement, dummy(true,99))
	if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() and dummy_use.to:length() >= global_room:alivePlayerCount()/2 then
		use.card = card
	end
end
sgs.ai_use_value.xianzhencard = 5.6
sgs.ai_use_priority.xianzhencard = 9.4
sgs.ai_keep_value.xianzhencard = 3.44
sgs.ai_choicemade_filter.cardChosen.xianzhencard = sgs.ai_choicemade_filter.cardChosen.snatch










function SmartAI:useCardmanbing(manbing,use)
	self.aiUsing = manbing:getSubcards()
	local extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,manbing)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	if use.xiechan then extraTarget = 100 end
	self:sort(self.enemies)
	local enemySlash = 0
	for _,enemy in sgs.list(self.enemies)do
		if isCurrent(use,enemy) then continue end
		if self.player:hasFlag("manbingTo_"..enemy:objectName())
		and CanToCard(manbing,self.player,enemy)
		and self:ajustDamage(self.player,enemy,1,manbing)~=0
		then
			local n2 = getCardsNum("Slash",enemy,self.player)
			if n2>0 then continue end
			enemySlash = enemySlash+n2
			if self.player:getPhase()<=sgs.Player_Play and math.random()<0.5
			then self.player:setFlags("manbingTo_"..enemy:objectName()) end
			use.card = manbing
			use.to:append(enemy)
			if use.to:length()>extraTarget
			then return end
		end
	end
	local bcv = {}
	for _,p in ipairs(self.enemies)do
		local v1 = getCardsNum("Slash",p,self.player)+p:getHp()
		if not self:isWeak(p) and p:hasSkill("jianxiong") and not hasJueqingEffect(self.player,p) then v1 = v1+10 end
		if self:needToLoseHp(p,nil,manbing) then v1 = v1+15 end
		if self:hasSkills(sgs.masochism_skill,p) then v1 = v1+5 end
		if not self:isWeak(p) and p:hasSkill("jiang") then v1 = v1+5 end
		if p:hasLordSkill("jijiang") then v1 = v1+self:JijiangSlash(p)*2 end
		bcv[p:objectName()] = v1
	end
	local function compare_func(a,b)
		return bcv[a:objectName()]<bcv[b:objectName()]
	end
	table.sort(self.enemies,compare_func)
	for _,enemy in sgs.list(self.enemies)do
		if isCurrent(use,enemy) then continue end
		if not use.to:contains(enemy) and CanToCard(manbing,self.player,enemy)
		and self:objectiveLevel(enemy)>3 and self:isGoodTarget(enemy,self.enemies)
		and self:ajustDamage(self.player,enemy,1,manbing)~=0
		then
			local n2 = getCardsNum("Slash",enemy,self.player)
			if self:needToLoseHp(self.player,nil,manbing,true) or n2<1 
			or self:hasSkill("jianxiong") or self.player:getMark("shuangxiong")>0
			then else continue end
			enemySlash = enemySlash+n2
			if self.player:getPhase()<=sgs.Player_Play and math.random()<0.5
			then self.player:setFlags("manbingTo_"..enemy:objectName()) end
			use.card = manbing
			use.to:append(enemy)
			if use.to:length()>extraTarget
			then return end
		end
	end
end

sgs.ai_card_intention.manbing = function(self,card,from,tos)
	sgs.updateIntentions(from,tos,66)
end

sgs.ai_use_value.manbing = 3.7
sgs.ai_use_priority.manbing = 2.9
sgs.ai_keep_value.manbing = 3.42

sgs.dynamic_value.damage_card.manbing = true

sgs.ai_skill_cardask["manbing-slash1"] = function(self,data,pattern,target)
	local effect = data:toCardEffect()
	if self.player:hasSkill("wuhun") and self:isEnemy(effect.from) and effect.from:isLord() and #self.friends_noself>0
	or self:getCardsNum("Slash")<2
	or self:isEnemy(effect.from) and not self:isWeak() and self:needToLoseHp(self.player,effect.from, effect.card)
	or self:ajustDamage(effect.from,self.player,1,effect.card)==0
	or sgs.ai_skill_cardask.nullfilter(self,data,pattern,effect.from)=="."
	then return "." end

	if self:getCardsNum("Slash")>=2 then return true end
	return "."
end
sgs.ai_skill_cardask["manbing-slash2"] = function(self,data,pattern,target)
	local effect = data:toCardEffect()
	if self.player:hasSkill("wuhun") and self:isEnemy(effect.from) and effect.from:isLord() and #self.friends_noself>0
	or self:getCardsNum("Slash")<1
	or self:isEnemy(effect.from) and not self:isWeak() and self:needToLoseHp(self.player,effect.from)
	or self:ajustDamage(effect.from,self.player,1,effect.card)==0
	or sgs.ai_skill_cardask.nullfilter(self,data,pattern,effect.from)=="."
	then return "." end

	if self:getCardsNum("Slash")>=1 then return true end
	return "."
end


function SmartAI:useCardquanxiang(card,use)
	self:sort(self.enemies,"skill",false)
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if ep:getMark("@RemoveGeneral") == 0
		and ep:getVisibleSkillList():length()>0
		and ep:getHandcardNum() < self.player:getHandcardNum()
	   	and CanToCard(card,self.player,ep,use.to) then
	    	use.card = card
	    	use.to:append(ep)
		end
	end
end
sgs.ai_use_priority.quanxiang = 5.4
sgs.ai_keep_value.quanxiang = 4
sgs.ai_use_value.quanxiang = 3.7

sgs.ai_nullification.quanxiang = function(self,trick,from,to,positive)
    return self:isFriend(to) and (to:getHandcardNum()>3 or to==self.player)
	and positive
end

sgs.ai_card_intention.quanxiang = 80

sgs.ai_skill_cardask["@quanxiangmessage"] = function(self,data,pattern,target)
	if target and self:isEnemy(target) then
		local cards = self.player:getCards("he")
        cards = sgs.QList2Table(cards)
        self:sortByKeepValue(cards)
        for _,h in sgs.list(cards)do
            if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
            then return h:getEffectiveId() end
            if h:isKindOf(pattern)
            then return h:getEffectiveId() end
        end
        return self:getCardId(pattern)
	end
end


function SmartAI:useCardshuigong(shuigong,use)
	local lack = {basic=false,trick=false,equip=false}
	local canDis = {}
	for _,h in sgs.list(self.player:getHandcards())do
		if h:getEffectiveId()~=shuigong:getEffectiveId()
		and self.player:canDiscard(self.player,h:getEffectiveId())
		then
			table.insert(canDis,h)
			lack[h:getTypeId()] = true
		end
	end
	local suitnum = 0
	for suit,islack in pairs(lack)do
		if islack then suitnum = suitnum+1  end
	end
	self:sort(self.enemies,"defense")
	local function can_attack(enemy)
		if self:cantbeHurt(enemy,self.player) then return end
		return self:objectiveLevel(enemy)>2
		and self:isGoodTarget(enemy,self.enemies,shuigong)
		and (hasJueqingEffect(self.player,enemy) or not(enemy:hasSkill("jianxiong") and not self:isWeak(enemy)
		or self:needToLoseHp(enemy,self.player,shuigong)))
	end
	local enemies,targets = {},{}
	for _,enemy in sgs.list(self.enemies)do
		if can_attack(enemy) then table.insert(enemies,enemy) end
	end
	for kc,enemy in sgs.list(enemies)do
		kc = getKnownCards(enemy,self.player)
		if #kc>enemy:getHandcardNum()/2
		then
			local can = 0
			for _,h in sgs.list(kc)do
				if lack[h:getSuitString()]
				then can = can+1 end
			end
			if can>=#kc then table.insert(targets,enemy) end
		end
	end
	
	if (suitnum==2 and lack.diamond or suitnum<=1) and #targets<1
	and self:getOverflow()<=(self.player:hasSkills("jizhi|nosjizhi") and -2 or 0)
	then return end
	for _,enemy in sgs.list(enemies)do
		if table.contains(targets,enemy)
		then else table.insert(targets,enemy) end
	end
	local extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,shuigong)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,p in sgs.list(targets)do
		if isCurrent(use,p) then continue end
		if CanToCard(shuigong,self.player,p)
		and self:ajustDamage(self.player,p,1,shuigong)~=0
		then
			use.card = shuigong
			local gs = self:getCard("GodSalvation")
			if gs and gs:getEffectiveId()~=shuigong:getEffectiveId()
			and p:getLostHp()<1 and self:willUseGodSalvation(gs)
			and self:hasTrickEffective(gs,p,self.player)
			then use.card = gs return end
			use.to:append(p)
			if use.to:length()>extraTarget
			then return end
		end
	end
end


sgs.ai_use_value.shuigong = 4.8
sgs.ai_keep_value.shuigong = 3.3
sgs.ai_use_priority.shuigong = sgs.ai_use_priority.Dismantlement+0.1
sgs.dynamic_value.damage_card.shuigong = true
sgs.ai_card_intention.shuigong = 80

sgs.ai_skill_cardask["@shuigongmessage_BasicCard"] = function(self,data,pattern,target)
	local cards = self.player:getCards("h")
	cards = self:sortByUseValue(cards,true)
	for i,c in sgs.list(cards)do
		if c:isKindOf("BasicCard") then
			if self:isFriend(target) then
				if self:needToLoseHp(target,self.player,sgs.cardEffect.card)
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not self:isWeak(nil,false) or self:ajustDamage(self.player,target,1,sgs.cardEffect.card)>1
				then return c:getId() end
			else
				return c:getId()
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["@shuigongmessage_TrickCard"] = function(self,data,pattern,target)
	local cards = self.player:getCards("h")
	cards = self:sortByUseValue(cards,true)
	for i,c in sgs.list(cards)do
		if c:isKindOf("TrickCard") then
			if self:isFriend(target) then
				if self:needToLoseHp(target,self.player,sgs.cardEffect.card)
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not self:isWeak(nil,false) or self:ajustDamage(self.player,target,1,sgs.cardEffect.card)>1
				then return c:getId() end
			else
				return c:getId()
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["@shuigongmessage_EquipCard"] = function(self,data,pattern,target)
	local cards = self.player:getCards("h")
	cards = self:sortByUseValue(cards,true)
	for i,c in sgs.list(cards)do
		if c:isKindOf("EquipCard") then
			if self:isFriend(target) then
				if self:needToLoseHp(target,self.player,sgs.cardEffect.card)
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not self:isWeak(nil,false) or self:ajustDamage(self.player,target,1,sgs.cardEffect.card)>1
				then return c:getId() end
			else
				return c:getId()
			end
		end
	end
	return "."
end