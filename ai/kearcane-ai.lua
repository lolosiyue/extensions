
--金克丝
sgs.ai_skill_playerchosen.kejinxmark = function(self, targets)
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

sgs.ai_playerchosen_intention.kejinxmark = 50

local jinxchange_skill = {}
jinxchange_skill.name = "jinxchange"
table.insert(sgs.ai_skills, jinxchange_skill)
jinxchange_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#jinxchangeCard:.:")
end

sgs.ai_skill_use_func["#jinxchangeCard"] = function(card, use, self)
	local slash_num = self:getCardsNum("Slash")
	if slash_num > 1 and self.player:getMark("@jinxcannon")>0 then
		use.card = card
	elseif slash_num == 1 and self.player:getMark("@jinxgun")>0 then
		use.card = card
	end
end
sgs.ai_use_priority.jinxchangeCard = 9.5

sgs.ai_skill_playerchosen.kejintuo = function(self, targets)
	targets = sgs.QList2Table(targets)
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
sgs.ai_playerchosen_intention.kejintuo = -50



local kefanmao_skill = {}
kefanmao_skill.name = "kefanmao"
table.insert(sgs.ai_skills, kefanmao_skill)
kefanmao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kefanmaoCard") then return end
	return sgs.Card_Parse("#kefanmaoCard:.:")
end

sgs.ai_skill_use_func["#kefanmaoCard"] = function(card, use, self)
    if (self.player:getMark("@hexstone")>=2) and not self.player:hasUsed("#kefanmaoCard") then
        self:sort(self.friends)
		for _, friend in ipairs(self.friends) do
			if self:isFriend(friend) and (self.player:objectName() ~= friend:objectName() ) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
end

sgs.ai_use_value.kefanmaoCard = 8.5
sgs.ai_use_priority.kefanmaoCard = 9.5
sgs.ai_card_intention.kefanmaoCard = 80

sgs.ai_skill_invoke["flydoorswapback-ask"] = function(self, data)
	return true
end

sgs.ai_skill_invoke.kebengneng = function(self, data)
	local target = data:toPlayer()
	return self:doDisCard(target, "h")
end

sgs.ai_ajustdamage_from.kebengneng = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and card:isRed()
    then
        return 1
    end
end


sgs.ai_skill_invoke.kechetan = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) and self:doDisCard(target, "h") then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.kechetan = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end


sgs.ai_ajustdamage_from.kejingwen = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and (from:getMark("@kebaotou") > 0)
    then
        return 1
    end
end

--vi

local keyuji_skill = {}
keyuji_skill.name = "keyuji"
table.insert(sgs.ai_skills, keyuji_skill)
keyuji_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("keyujiCard") then return end
	return sgs.Card_Parse("#keyujiCard:.:")
end

sgs.ai_skill_use_func["#keyujiCard"] = function(card, use, self)
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in sgs.list(self.enemies) do
		if self:objectiveLevel(enemy) > 0 and (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) < (self.player:getHp()+self.player:getHp()+self.player:getHandcardNum()) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) and not enemy:hasFlag("yujichosen") and self.player:inMyAttackRange(enemy) then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_value.keyujiCard = 8.5
sgs.ai_use_priority.keyujiCard = 9.5
sgs.ai_card_intention.keyujiCard = 80

sgs.ai_skill_invoke.kegonghuan = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.kegonghuan = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-80) end
	end
end

sgs.ai_skill_choice["hitvi"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:setSkillName("kevioletspace")
	local dummy_use = self:aiUseCard(duel, dummy(true, 0, self.room:getOtherPlayers(target)))
	if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
		return "juedou"
	end
	
	return "slash"
end

sgs.ai_skill_choice.kechupan = function(self, choices, data)
	local use = data:toCardUse()
	if use.from then
		if self:isFriend(use.from) and self:damageIsEffective(use.from, sgs.DamageStruct_Normal, self.player)
			and self:needToLoseHp(use.from,self.player,nil) then
			return "damage"
		end
		if self:isEnemy(use.from) and self:damageIsEffective(use.from, sgs.DamageStruct_Normal, self.player)
			and not self:needToLoseHp(use.from,self.player,nil) and not self:cantbeHurt(use.from) then
			return "damage"
		end
	end
	return "cancel"
end

sgs.ai_skill_invoke.kechupan = function(self, data)
	local use = data:toCardUse()
	if use.from and self:isFriend(use.from) then
		return false
	end
	return true
end

sgs.ai_skill_playerchosen.kechupan = function(self, targets)
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

sgs.ai_skill_discard.kesilang = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	--if self.player:hasFlag("wantusepaomu") then
	    table.insert(to_discard, cards[1]:getEffectiveId())
		return to_discard
	--else
	   -- return self:askForDiscard("dummyreason", 999, 999, true, true)
	--end
end

sgs.ai_skill_playerchosen.kesilang = function(self, targets)
	targets = sgs.QList2Table(targets)
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
sgs.ai_playerchosen_intention.kesilang = -50


sgs.ai_ajustdamage_to["@besilanged"] = function(self, from, to, card, nature)
	if not to:hasSkill("kesilang") then
		return to:getMark("@besilanged")
	end
end


sgs.ai_skill_use["@@ketinghu"] = function(self, prompt)
	local x = self.player:getMaxHp() - 1
	local targets = {}
	for _,p in ipairs(self.friends) do
		if #targets >= x then
			break
		end
		if p:getMark("&beketinghu+to+#"..self.player:objectName()) == 0 then table.insert(targets, p:objectName()) end
	end
	if #targets > 0 then
		return "#ketinghuCard:.:->"..table.concat(targets, "+")
	end
end

sgs.ai_card_intention.ketinghuCard = -80

sgs.ai_skill_choice.vander_choice = function(self, choices, data)
	local items = choices:split("+")
	if self.player:getMark("&usetinghu") > self.player:getHp()+self:getAllPeachNum() then
		return "losemaxhp"
	end
	return items[math.random(1,#items)]
end
 

sgs.ai_skill_invoke.keblood = function(self, data)
	local use = data:toCardUse()
	if use.from and use.from:objectName() == self.player:objectName() then
		if self:isFriend(use.to:first()) then
			return false
		end
	end
	if use.from and use.from:objectName() ~= self.player:objectName() then
		if self:isFriend(use.from) then
			return false
		end
	end
	return true
end
sgs.ai_skill_invoke.kebloodangry = function(self, data)
	local use = data:toCardUse()
	if use.from and use.from:objectName() == self.player:objectName() then
		if self:isFriend(use.to:first()) then
			return false
		end
	end
	if use.from and use.from:objectName() ~= self.player:objectName() then
		if self:isFriend(use.from) then
			return false
		end
	end
	return true
end

sgs.ai_skill_invoke.killaround = function(self, data)
	return (self.player:getHandcardNum() < 4 or self.player:getLostHp() > 1) and sgs.ai_skill_use["@@killaround"](self, "") ~= "."
end
sgs.ai_skill_use["@@killaround"] = function(self, prompt)
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:setSkillName("killaround")
	slash:deleteLater()
	local dummy_use = self:aiUseCard(slash, dummy(true, self.player:getLostHp() - 1))
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return "#killaroundCard:.:->"..table.concat(tos, "+")
    end
	return "."
end

sgs.ai_use_revises.killaround = function(self,card,use)
	if card:isKindOf("Slash") and table.contains(card:getSkillNames(), "killaround") then
		card:setFlags("Qinggang")
	end
end

local keduantou_extra_skill = {}
keduantou_extra_skill.name = "keduantou_extra"
table.insert(sgs.ai_skills, keduantou_extra_skill)
keduantou_extra_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#keduantouCard:.:")
end

local keduantou_skill = {}
keduantou_skill.name = "keduantou"
table.insert(sgs.ai_skills, keduantou_skill)
keduantou_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	self:sortByUseValue(cards)
	local first_found, second_found = false, false
	local first_card, second_card
	for _, fcard in ipairs(cards) do
		first_card = fcard
		first_found = true
		for _, scard in ipairs(cards) do
			if first_card ~= scard then
				second_card = scard
				second_found = true
				table.insert(to_discard, fcard:getEffectiveId())
				table.insert(to_discard, scard:getEffectiveId())
				break
			end
		end
		if second_card then break end
	end
	local card_str = string.format("#keduantouCard:%s:", table.concat(to_discard, "+"))
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#keduantouCard"] = function(card, use, self)
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in sgs.list(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) and enemy:getMark("@shixue") >= 5 and enemy:getHp() + self:getAllPeachNum(enemy) <= 2 and self.player:distanceTo(enemy) <= 1 then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _,enemy in sgs.list(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nil, self.player) and enemy:getHp() + self:getAllPeachNum(enemy) <= 1 and self.player:distanceTo(enemy) <= 1 then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
	if self.player:hasSkill("keduantou_extra") then
		for _,enemy in sgs.list(self.enemies) do
			if self:damageIsEffective(enemy, nil, self.player) and self.player:distanceTo(enemy) <= 1 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.keduantouCard = 8.5
sgs.ai_use_priority.keduantouCard = 9.5
sgs.ai_card_intention.keduantouCard = 80

local kebeilian_skill = {}
kebeilian_skill.name = "kebeilian"
table.insert(sgs.ai_skills, kebeilian_skill)
kebeilian_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kebeilianCard") then return end
	return sgs.Card_Parse("#kebeilianCard:.:")
end

sgs.ai_skill_use_func["#kebeilianCard"] = function(card, use, self)
	self:sort(self.friends)
	for _, friend in ipairs(self.friends_noself) do
		if self:isFriend(friend) and friend:getMark("@shixue") > 0 then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
end
sgs.ai_card_intention.kebeilianCard = -80

--garen
sgs.ai_skill_invoke.kezhengyi = function(self, data)
	local target = data:toPlayer()
	if target then
		if self:isEnemy(target) and self:isWeak(target) and target:getHp() + self:getAllPeachNum(target) - target:getLostHp() < 1 and not self:cantDamageMore(self.player, target) and self:damageIsEffective(target, sgs.DamageStruct_Thunder, self.player) then
			return true
		end
	end
	return false
end

local kehaojin_skill = {}
kehaojin_skill.name = "kehaojin"
table.insert(sgs.ai_skills, kehaojin_skill)
kehaojin_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehaojinCard") then return end
	--if (self.player:getMark("kechengzhengbing-Clear") >= 3) or (self.player:getKingdom() ~= "qun") or (self.player:isKongcheng()) then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = sgs.IntList()
	for _, acard in ipairs(cards) do
		to_throw:append(acard:getEffectiveId())
	end
	card_id = to_throw:at(0)--(to_throw:length()-1)
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("#kehaojinCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#kehaojinCard"] = function(card, use, self)
	local slashcount = self:getCardsNum("Slash")
	if slashcount > 0 then
		local slash = self:getCard("Slash")
		if slash then
			assert(slash)
			local dummy_use = self:aiUseCard(slash, dummy())
			if dummy_use.card and dummy_use.to then
				if not dummy_use.to:isEmpty() then
					use.card = card
					return
				end
			end
		end
	end
end

sgs.ai_use_value.kehaojinCard = 8.5
sgs.ai_use_priority.kehaojinCard = 3
sgs.ai_card_intention.kehaojinCard = -80

--lux

local keguangfu_skill = {}
keguangfu_skill.name = "keguangfu"
table.insert(sgs.ai_skills, keguangfu_skill)
keguangfu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("keguangfuCard") then return end
	return sgs.Card_Parse("#keguangfuCard:.:")
end

sgs.ai_skill_use_func["#keguangfuCard"] = function(card, use, self)
    if not self.player:hasUsed("#keguangfuCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		if self.player:hasSkill("kelux_r") then
			for _, enemy in ipairs(self.enemies) do
				if self.player:canPindian(enemy,true) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) and not self:cantbeHurt(enemy) then
					use.card = card
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
		local max_card = self:getMaxCard()
		local max_point = max_card:getNumber()
		for _,enemy in ipairs(self.enemies) do
			if self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if enemy_max_card then enemy_max_point = math.min(enemy_max_point+3,13) end
				if max_point>enemy_max_point or max_point>10 then
					use.card = card
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value.keguangfuCard = 8.5
sgs.ai_use_priority.keguangfuCard = 9.5
sgs.ai_card_intention.keguangfuCard = 80

sgs.ai_skill_playerchosen.kequguang = function(self, targets)
	targets = sgs.QList2Table(targets)
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

sgs.ai_card_intention.kequguang = -80

local playmovesoldier_skill = {}
playmovesoldier_skill.name = "playmovesoldier"
table.insert(sgs.ai_skills, playmovesoldier_skill)
playmovesoldier_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("playmovesoldierCard") then return end
	return sgs.Card_Parse("#playmovesoldierCard:.:")
end

sgs.ai_skill_use_func["#playmovesoldierCard"] = function(card, use, self)
    if not self.player:hasUsed("#playmovesoldierCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if (enemy:getMark("@sandsoldier") == 0) then
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
			if self:objectiveLevel(enemy) > 0 then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.playmovesoldierCard = 8.5
sgs.ai_use_priority.playmovesoldierCard = 9.5
sgs.ai_card_intention.playmovesoldierCard = 80


sgs.ai_skill_invoke.azirslash = function(self, data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(self.room:getAllPlayers()) do        
		if (p:getMark("@sandsoldier") > 0) then
			local dummy_use = self:aiUseCard(use.card, dummy(true, 99, self.room:getOtherPlayers(p)))
			if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(p) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_invoke.playmovesoldier = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.playmovesoldier = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	if self:isWeak() then
		local min = 999
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getHp() < min and not (p:getGeneralName() == "kesolardisk" or p:getGeneral2Name() == "kesolardisk") then
				min = p:getHp()
			end
		end
		if self.player:getHp() <= min then
			return self.player
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "he") then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	return self.player
end


sgs.ai_event_callback[sgs.CardFinished].azirshenjiCard = function(self, player, data)
	local use = data:toCardUse()
	if use.card and use.card:objectName() == "azirshenjiCard" then
		local room = player:getRoom()
		for _, sb in sgs.qlist(room:getOtherPlayers(player)) do
			if sb:getGeneralName() == "kesolardisk" then
				--sgs.role_evaluation[sb:objectName()][sb:getRole()] = 10000
				sgs.roleValue[sb:objectName()]["renegade"] = 0
				sgs.roleValue[sb:objectName()]["loyalist"] = 0
				sgs.roleValue[sb:objectName()][sb:getRole()] = 1000
				sgs.ai_role[sb:objectName()] = sb:getRole()
			end
		end
	end
end

local azirshenji_skill = {}
azirshenji_skill.name = "azirshenji"
table.insert(sgs.ai_skills,azirshenji_skill)
azirshenji_skill.getTurnUseCard = function(self)
	if self.player:getMark("@azirshenji") == 0 then return end
	local deathplayer = {}
	for _,p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and ((p:getRole() == self.player:getRole())
		 or (p:getRole() == "loyalist" and self.player:isLord())) then
			table.insert(deathplayer,p:getGeneralName())
		end
	end
	if #deathplayer==0 then return end
	return sgs.Card_Parse("#azirshenjiCard:.:")
end

sgs.ai_skill_use_func["#azirshenjiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value["#azirshenjiCard"] = 8
sgs.ai_use_priority["#azirshenjiCard"] = 9.5



sgs.ai_skill_choice["shenji-ask"] = function(self, choices, data)
	local items = choices:split("+")
	table.removeOne(items, "cancel")
	return items[math.random(1,#items)]
end
