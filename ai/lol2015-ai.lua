local lol_jwyh_q_skill = {}
lol_jwyh_q_skill.name = "lol_jwyh_q"
table.insert(sgs.ai_skills, lol_jwyh_q_skill)
lol_jwyh_q_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if not self.player:hasUsed("#lol_jwyh_qCard") then
		return sgs.Card_Parse("#lol_jwyh_qCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_jwyh_qCard"] = function(card, use, self)
	self:updatePlayers()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sort(self.enemies, "handcard")
	self:sortByCardNeed(handcards, true)
	local targets = {}
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") and c:isRed() then
			use_card = c
		end
	end
	if use_card == nil then return end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() >= self.player:getHandcardNum() and enemy:hasFlag("lol_jwyh_e") and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:doDisCard(enemy, "h", true)   then
			table.insert(targets, enemy)
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() >= self.player:getHandcardNum() and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:doDisCard(enemy, "h", true)   then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	--local card_str =  ("#lol_jwyh_qCard:" .. use_card:getEffectiveId())
	local card_str =   string.format("#lol_jwyh_qCard:%s:", use_card:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_priority["lol_jwyh_qCard"] = 7
sgs.ai_use_value["lol_jwyh_qCard"] = 7
sgs.ai_card_intention["lol_jwyh_qCard"] = 30

sgs.ai_skill_invoke["lol_jwyh_q"] = function(self, data)
	local target = data:toPlayer()
	if self:isEnemy(target) and not self:cantbeHurt(target) and self:damageIsEffective(target) then 
		return true
	end
	return false
end

sgs.ai_skill_cardchosen["lol_jwyh_qCard"] = function(self, who, flags)
	self:updatePlayers()
	local handcards = sgs.QList2Table(who:getHandcards())
	self:sortByUseValue(handcards)
	if self:isEnemy(who) then
		if who:hasFlag("lol_jwyh_e") then
			for _,c in ipairs(handcards) do
				if c:isRed() then
					return c:getEffectiveId()
				end
			end
		end
	end
	return handcards[1]
end

local lol_jwyh_w_skill = {}
lol_jwyh_w_skill.name = "lol_jwyh_w"
table.insert(sgs.ai_skills, lol_jwyh_w_skill)
lol_jwyh_w_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#lol_jwyh_wCard") then
		return sgs.Card_Parse("#lol_jwyh_wCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_jwyh_wCard"] = function(card, use, self)
	self:updatePlayers()
	local tos = sgs.SPlayerList()
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			    if self.player:distanceTo(p) <= 1 and p:objectName() ~= self.player:objectName()  and self:damageIsEffective(p, sgs.DamageStruct_Fire) and not self:cantbeHurt(p) and self:isEnemy(p) then tos:append(p) end
            end
	if tos:isEmpty() then 
	self.player:setFlags("lol_jwyh_w_empty")
	end
	if self:isWeak() or not tos:isEmpty() then
		local card_str =   "#lol_jwyh_wCard:.:"
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
	end
end

sgs.ai_use_priority["lol_jwyh_wCard"] = 0
sgs.ai_use_value["lol_jwyh_wCard"] = 4

sgs.ai_skill_cardask["@lol_jwyh_w_discard"] =function(self, data, pattern, target, target2)
	local num = data:toInt()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local overflow = self:getOverflow()
		if self.player:hasSkill("lol_jwyh_t") and self.player:getMark("@lol_jwyh_t") < 8 - overflow  and self:isWeak() then
			local use_card = nil
			for _,c in ipairs(handcards) do
				if not c:isKindOf("Peach") then
					use_card = c
				end
			end
			if use_card == nil then return "." end
			return "$" .. use_card:getEffectiveId()
		end
		if not (self.player:hasFlag("lol_jwyh_wR") and self.player:hasFlag("lol_jwyh_wB")) and not self.player:hasFlag("lol_jwyh_w_empty")  then
			local use_card = nil
			if self.player:hasFlag("lol_jwyh_wR") then
				for _,c in ipairs(handcards) do
					if not c:isKindOf("Peach") and c:isRed() then
						use_card = c
					end
				end
				if use_card == nil then return "." end
				return "$" .. use_card:getEffectiveId()
			end
			if self.player:hasFlag("lol_jwyh_wR") then
				for _,c in ipairs(handcards) do
					if c:isBlack() then
						use_card = c
					end
				end
				if use_card == nil then return "." end
				return "$" .. use_card:getEffectiveId()
			end
		end
	return "."
end

sgs.ai_skill_playerchosen["lol_jwyh_wCard"] = function(self, targets)
	local target
	targets = sgs.QList2Table(targets)
	self:sort(self.enemies, "defense") 
	for _,enemy in ipairs(targets) do
		if enemy and self:isEnemy(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) and not self:cantbeHurt(enemy)  then
			target= enemy
			break
		end
	end
	if target then return target end
	return false
end


local lol_jwyh_e_skill = {}
lol_jwyh_e_skill.name = "lol_jwyh_e"
table.insert(sgs.ai_skills, lol_jwyh_e_skill)
lol_jwyh_e_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if self:getOverflow() < 2 then return end
	if not self.player:hasUsed("#lol_jwyh_eCard") then
		return sgs.Card_Parse("#lol_jwyh_eCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_jwyh_eCard"] = function(card, use, self)
	self:updatePlayers()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	self:sortByCardNeed(handcards, true)
	local targets = {}
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") and c:isRed() then
			use_card = c
		end
	end
	if use_card == nil then return end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() >= self.player:getHandcardNum() then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	local card_str =   string.format("#lol_jwyh_eCard:%s:", use_card:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_priority["lol_jwyh_eCard"] = 8
sgs.ai_use_value["lol_jwyh_eCard"] = 3
sgs.ai_card_intention["lol_jwyh_eCard"] = 10

sgs.ai_skill_use["@@lol_jwyh_r"] = function(self, prompt)
    local all_cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(all_cards)
	local use_card
	local spade = 0
	for _, c in ipairs(all_cards) do
		if c:getSuit() == sgs.Card_Spade then
			spade = spade + 1
			use_card = c
		end
	end
	local mark = self.player:getMark("lol_jwyh_r123")
	if (mark + spade >= 3 or self:isWeak()) and use_card then
    return string.format("#lol_jwyh_rCard:%s:", use_card:getEffectiveId())
	end
	return "."
end


--艾希
sgs.ai_ajustdamage_from.lol_hbss_t = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and from and from:getMark("@lol_hbss_t_Mark") == 100
	then
		return 1
	end
end

local lol_hbss_q_skill = {}
lol_hbss_q_skill.name = "lol_hbss_q"
table.insert(sgs.ai_skills, lol_hbss_q_skill)
lol_hbss_q_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if self.player:hasFlag("lol_hbss_q") then return end
	if self:getOverflow() < 1 then return end
	if self:getCardsNum("Slash") < 1 then return end
	if not self.player:hasUsed("#lol_hbss_qCard") then
		return sgs.Card_Parse("#lol_hbss_qCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_hbss_qCard"] = function(card, use, self)
	self:updatePlayers()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local can_invoke = false
	local targets = {}
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach")  then
			use_card = c
		end
	end
	if use_card == nil then return end
	for _, slash in ipairs(self:getCards("Slash")) do
		if  slash:isAvailable(self.player) and slash:getEffectiveId() ~= use_card then
			local dummy = self:aiUseCard(slash)
			if dummy.card and not dummy.to:isEmpty() then
				can_invoke = true
			end
		end
	end
	--local card_str =  ("#lol_jwyh_qCard:" .. use_card:getEffectiveId())
	if not can_invoke then return end 
	local card_str =   string.format("#lol_hbss_qCard:%s:", use_card:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
end

sgs.ai_use_priority["lol_hbss_qCard"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_use_value["lol_hbss_qCard"] = 1


local lol_hbss_w_skill = {}
lol_hbss_w_skill.name = "lol_hbss_w"
table.insert(sgs.ai_skills, lol_hbss_w_skill)
lol_hbss_w_skill.getTurnUseCard = function(self)
	local archery = sgs.Sanguosha:cloneCard("archery_attack")
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)
		
		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards ,sgs.Sanguosha:getCard(id))
			end
		end
		
		self:sortByKeepValue(cards)
		local useAll = false
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and not enemy:hasArmorEffect("vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
				and self:isWeak(enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
			if useAll then fvalueCard = isCard("ArcheryAttack", fcard, self.player) end
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard			and not svalueCard then

						local card_str = ("archery_attack:lol_hbss_w[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)
						
						local dummy = self:aiUseCard(archeryattack)
						if dummy.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end

	if first_found and second_found and not self.player:hasFlag("lol_hbss_w") then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("archery_attack:lol_hbss_w[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
end


local lol_hbss_e_skill = {}
lol_hbss_e_skill.name = "lol_hbss_e"
table.insert(sgs.ai_skills, lol_hbss_e_skill)
lol_hbss_e_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if self:getOverflow() < 3 then return end
	if not self.player:hasUsed("#lol_hbss_eCard") then
		return sgs.Card_Parse("#lol_hbss_eCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_hbss_eCard"] = function(card, use, self)
	self:updatePlayers()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	self:sort(self.enemies, "handcard")
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach")  then
			use_card = c
		end
	end
	if use_card == nil then return end
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	--local card_str =  ("#lol_jwyh_qCard:" .. use_card:getEffectiveId())
	local card_str =   string.format("#lol_hbss_eCard:%s:", use_card:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_priority["lol_hbss_eCard"] = 3
sgs.ai_use_value["lol_hbss_eCard"] = 1

lol_hbss_r_skill={}
lol_hbss_r_skill.name="lol_hbss_r"
table.insert(sgs.ai_skills,lol_hbss_r_skill)
lol_hbss_r_skill.getTurnUseCard=function(self,inclusive)
	if #self.enemies < 1 then return end
	self:sort(self.enemies, "hp")
	if self.player:getMark("@lol_hbss_r") < 1 then return end

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if #cards == 0 then return end
	local cardToUse = cards[1]
	if not cardToUse then
		return
	end
	if cardToUse:isKindOf("Peach") then return end
	if not(self.enemies[1]:getHandcardNum() == 0 or self:canLiegong(self.enemies[1], self.player) ) or not self:slashIsEffective(sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0), self.enemies[1]) then return end 
	local suit = cardToUse:getSuitString()
	local number = cardToUse:getNumberString()
	local card_id = cardToUse:getEffectiveId()
	local card_str = ("slash:lol_hbss_r[%s:%s]=%d"):format(suit, number, card_id)
	return sgs.Card_Parse(card_str)
end


local lol_mzzw_q_skill = {}
lol_mzzw_q_skill.name = "lol_mzzw_q"
table.insert(sgs.ai_skills, lol_mzzw_q_skill)
lol_mzzw_q_skill.getTurnUseCard = function(self, inclusive)
	if not self:isWeak() then return end
	if  self.player:getMark("@lol_mzzw_t") < 50 then return end
	if self.player:getMark("lol_mzzw_r_damage") == 1 then return end
	if not self.player:hasUsed("#lol_mzzw_qCard") then
		return sgs.Card_Parse("#lol_mzzw_qCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_mzzw_qCard"] = function(card, use, self)
	self:updatePlayers()


	local acard = sgs.Card_Parse("#lol_mzzw_qCard:.:")
	use.card = acard
end

sgs.ai_use_priority["lol_mzzw_qCard"] = sgs.ai_use_priority.Slash - 0.1
sgs.ai_use_value["lol_mzzw_qCard"] = 1


local lol_mzzw_w_skill = {}
lol_mzzw_w_skill.name = "lol_mzzw_w"
table.insert(sgs.ai_skills, lol_mzzw_w_skill)
lol_mzzw_w_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies < 1 then return end 
	local x = 0
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			x = x + 1
		end
	end
	if not self.player:hasUsed("#lol_mzzw_wCard") and x > 0 then
		return sgs.Card_Parse("#lol_mzzw_wCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_mzzw_wCard"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			if use.to then use.to:append(enemy) end
		end
	end
	use.card = sgs.Card_Parse("#lol_mzzw_wCard:.:")
	if use.to and use.to:length() > 0 then 
	
	return end
end

sgs.ai_use_priority["lol_mzzw_wCard"] = 7
sgs.ai_use_value["lol_mzzw_wCard"] = 4


sgs.ai_skill_cardchosen.lol_mzzw_w = function(self, who, flags)
	local cards = sgs.QList2Table(who:getHandcards())
		for _, card in ipairs(cards) do
			if not card:isKindOf("Jink") and not card:isKindOf("Slash") then
				 return card 
			end
		end
	for _, card in ipairs(cards) do
			if  not card:isKindOf("Slash") then
				 return card 
			end
		end
	return cards[1]
end

-- local lol_mzzw_e_skill = {}
-- lol_mzzw_e_skill.name = "lol_mzzw_e"
-- table.insert(sgs.ai_skills, lol_mzzw_e_skill)
-- lol_mzzw_e_skill.getTurnUseCard = function(self, inclusive)
-- 	if self.player:isKongcheng() then return end
-- 	local handcards = sgs.QList2Table(self.player:getCards("h"))
-- 	self:sort(self.enemies, "handcard")
-- 	self:sortByCardNeed(handcards, true)
-- 	local slash, jink = nil, nil
-- 	for _,c in ipairs(handcards) do
-- 		if c:isKindOf("Slash")  then
-- 			slash = c
-- 		end
-- 		if c:isKindOf("Jink")  then
-- 			jink = c
-- 		end
-- 	end
-- 	if slash == nil or jink == nil then return end
-- 	local toids = {}
-- 	table.insert(toids,slash:getEffectiveId())
-- 	table.insert(toids,jink:getEffectiveId())
-- 	local card_str = sgs.Card_Parse(("slash:lol_mzzw_e[%s:%s]=%d+%d"):format("to_be_decided", 0, toids[1],
-- 	toids[2]))
-- 	return card_str
	
-- end

-- sgs.ai_use_revises.lol_mzzw_e = function(self,card,use)
-- 	if table.contains(card:getSkillNames(), "lol_mzzw_e")
-- 	then
-- 		local max_value = 0
-- 		local target
-- 		for _,enemy in sgs.list(self.enemies)do
-- 			local value = 0
-- 			if not self:slashProhibit(card, enemy) and self:getDefenseSlash(enemy) <= 2
-- 				and self:slashIsEffective(card, enemy) and self:isGoodTarget(enemy, self.enemies, card) then
-- 				value = value + 1
-- 				local x = self.player:distanceTo(enemy)
-- 				for _,p in sgs.list(self.room:getAlivePlayers())do
-- 					if self.player:distanceTo(p) <= x then
-- 						if self:isFriend(p) then
-- 							if not self:slashProhibit(card, p) and sgs.getDefenseSlash(p, self) <= 2
-- 								and self:slashIsEffective(card, p) and not self:needToLoseHp(p, self.player, card) and not self:findLeijiTarget(p,50,self.player) then
-- 								value = value - 1
-- 							end
-- 						else
-- 							if not self:slashProhibit(card, p) and sgs.getDefenseSlash(p, self) <= 2
-- 								and self:slashIsEffective(card, p) and  p:objectName() ~= enemy:objectName() then
-- 								value = value+ 1
-- 							end
-- 						end
-- 					end
-- 				end
-- 				if value > max_value then
--                     max_value = value
-- 					target = enemy
--                 end
-- 			end
-- 		end
-- 		if target and max_value > 0 then
-- 			use.card = card
--             use.to:append(target)
--         end
-- 		return false
-- 	end
-- end

-- sgs.ai_card_priority.lol_mzzw_e = function(self,card)
-- 	if table.contains(card:getSkillNames(), "lol_mzzw_e")
-- 	then
-- 		if self.useValue
-- 		then return 1 end
-- 	end
-- end

local lol_mzzw_r_skill = {}
lol_mzzw_r_skill.name = "lol_mzzw_r"
table.insert(sgs.ai_skills, lol_mzzw_r_skill)
lol_mzzw_r_skill.getTurnUseCard = function(self, inclusive)
	if not self:isWeak() then return end
	if  self.player:getMark("@lol_mzzw_r") < 1 then return end
	if not self.player:hasUsed("#lol_mzzw_rCard") then
		return sgs.Card_Parse("#lol_mzzw_rCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_mzzw_rCard"] = function(card, use, self)
	self:updatePlayers()


	local acard = sgs.Card_Parse("#lol_mzzw_rCard:.:")
	use.card = acard
end

sgs.ai_use_priority["lol_mzzw_rCard"] = sgs.ai_use_priority["lol_mzzw_qCard"] - 0.1
sgs.ai_use_value["lol_mzzw_rCard"] = 1

sgs.ai_hasBuquEffect_skill.lol_mzzw_r = function(player)
	return player:getMark("lol_mzzw_r_damage") > 0
end



lol_tqz_q_skill={}
lol_tqz_q_skill.name="lol_tqz_q"
table.insert(sgs.ai_skills,lol_tqz_q_skill)
lol_tqz_q_skill.getTurnUseCard=function(self,inclusive)
	if #self.enemies < 1 then return end
	self:sort(self.enemies, "hp")
	
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if #cards == 0 then return end
	local cardToUse = cards[1]
	if not cardToUse then
		return
	end
	if cardToUse:isKindOf("Peach") or  not cardToUse:isRed() then return end
	if self.player:getMark("@lol_tqz_r") > 0 then
		sgs.ai_use_priority["lol_tqz_rCard"] = sgs.ai_use_priority["FireAttack"] + 0.1
	end
	local suit = cardToUse:getSuitString()
	local number = cardToUse:getNumberString()
	local card_id = cardToUse:getEffectiveId()
	local card_str = ("fire_attack:lol_tqz_q[%s:%s]=%d"):format(suit, number, card_id)
	return sgs.Card_Parse(card_str)
end


sgs.ai_skill_choice["lol_tqz_q"] = function(self, choices, data)
	local items = choices:split("+")
	 if table.contains(items, "lol_tqz_q_draw") then
		return "lol_tqz_q_draw"
   end
   if table.contains(items, "lol_tqz_q_damage") and self.player:getHandcardNum() > 2 then
	return "lol_tqz_q_damage"
   end
   
   return items[1]
end



local lol_tqz_w_skill = {}
lol_tqz_w_skill.name = "lol_tqz_w"
table.insert(sgs.ai_skills, lol_tqz_w_skill)
lol_tqz_w_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if self:getOverflow() < 1 then return end
		if not self.player:hasUsed("#lol_tqz_wCard") then
			if self.player:getMark("@lol_tqz_r") > 0 then
				sgs.ai_use_priority["lol_tqz_rCard"] = sgs.ai_use_priority["lol_tqz_eCard"] + 0.1
			end
			return sgs.Card_Parse("#lol_tqz_wCard:.:")
		end
end

sgs.ai_skill_use_func["#lol_tqz_wCard"] = function(card, use, self)
	self:updatePlayers()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	self:sort(self.enemies, "handcard")
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach")  then
			use_card = c
		end
	end
	if use_card == nil then return end

	local target
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			target = enemy
			break
		end
	end
	if target then
		local card_str =   string.format("#lol_tqz_wCard:%s:", use_card:getEffectiveId())
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_priority["lol_tqz_wCard"] = 3
sgs.ai_use_value["lol_tqz_wCard"] = 1

sgs.ai_skill_choice["lol_tqz_wCard"] = function(self, choices, data)
	local items = choices:split("+")
	 if table.contains(items, "lol_tqz_w_hp") and self.player:isWounded() then
		return "lol_tqz_w_hp"
   end
   if table.contains(items, "lol_tqz_w_throw")  then
	return "lol_tqz_w_throw"
   end
   
   return items[1]
end

local lol_tqz_e_skill = {}
lol_tqz_e_skill.name = "lol_tqz_e"
table.insert(sgs.ai_skills, lol_tqz_e_skill)
lol_tqz_e_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if self.player:getMark("@lol_tqz_r") > 0 then
		sgs.ai_use_priority["lol_tqz_rCard"] = sgs.ai_use_priority["lol_tqz_eCard"] + 0.1
	end
	if not self.player:hasUsed("#lol_tqz_eCard") then
		return sgs.Card_Parse("#lol_tqz_eCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_tqz_eCard"] = function(card, use, self)
	self:updatePlayers()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	self:sort(self.friends, "handcard")
	local use_card = nil
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") and c:getSuit() == sgs.Card_Diamond  then
			use_card = c
		end
	end
	if use_card == nil then return end

	local target
	for _, friend in ipairs(self.friends) do
		if  self:isWeak(friend) then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends) do
			if not self:needToLoseHp(friend) then
				target = friend
				break
			end
		end
	end
	if target then
		local card_str =   string.format("#lol_tqz_eCard:%s:", use_card:getEffectiveId())
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_priority["lol_tqz_eCard"] = 3
sgs.ai_use_value["lol_tqz_eCard"] = 1

sgs.ai_skill_choice["lol_tqz_eCard"] = function(self, choices, data)
	local items = choices:split("+")
	 if table.contains(items, "lol_tqz_e_hudun") then
		return "lol_tqz_e_hudun"
   end
   if table.contains(items, "lol_tqz_e_draw")  then
	return "lol_tqz_e_draw"
   end
   
   return items[1]
end






local lol_tqz_r_skill = {}
lol_tqz_r_skill.name = "lol_tqz_r"
table.insert(sgs.ai_skills, lol_tqz_r_skill)
lol_tqz_r_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies < 1 then return end
	
	if  self.player:getMark("@lol_tqz_r") < 1 then return end
	if not self.player:hasUsed("#lol_tqz_rCard") then
		return sgs.Card_Parse("#lol_tqz_rCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_tqz_rCard"] = function(card, use, self)
	self:updatePlayers()


	local acard = sgs.Card_Parse("#lol_tqz_rCard:.:")
	use.card = acard
end

sgs.ai_use_value["lol_tqz_rCard"] = 1




sgs.ai_card_priority["lol_xlnw_q"] = function(self, card)
	if card and card:isKindOf("Slash") and table.contains(card:getSkillNames(), "lol_xlnw_q")
	then
		return 0.1
	end
end

local lol_xlnw_q_skill={}
lol_xlnw_q_skill.name="lol_xlnw_q"
table.insert(sgs.ai_skills,lol_xlnw_q_skill)
lol_xlnw_q_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasFlag("lol_xlnw_q") then return nil end
    local cards = self.player:getHandcards()
    cards=sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if (acard:getSuit() == sgs.Card_Club)  then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Club		then
				card = sgs.Sanguosha:getCard(id)
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("slash:lol_xlnw_q[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end


lol_xlnw_w_skill = {}
lol_xlnw_w_skill.name = "lol_xlnw_w"
table.insert(sgs.ai_skills, lol_xlnw_w_skill)
lol_xlnw_w_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lol_xlnw_wCard") then return end

	local card
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:getSuit() == sgs.Card_Heart then
				card = hcard
				break
			end
		end
	end
	if card then
		card = sgs.Card_Parse("#lol_xlnw_wCard:" .. card:getEffectiveId()..":")
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#lol_xlnw_wCard"] = function(card, use, self)
	local target
	local friends = self.friends_noself
	
	self:sort(friends, "handcard", true)
	
	for _, friend in ipairs(friends) do
		if  not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and friend:getPile("lol_jiasu"):length() == 0 then
					target = friend
				end
		if target then break end
	end

	if not target then
		self:sort(friends, "defense")
		for _, friend in ipairs(friends) do
			if  not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end
sgs.ai_use_priority["lol_xlnw_wCard"] = 7
sgs.ai_use_value["lol_xlnw_wCard"] = 3


sgs.ai_skill_invoke.lol_xlnw_e = function(self, data)
	local target = data:toPlayer()
	if not self:isEnemy(target) then return false end
	local pks
	for _,pet in sgs.qlist(self.room:getAlivePlayers()) do
		if (pet:getGeneral2Name() == "lol_xlnw_pks") or  pet:getMark("@lol_xlnw_t") > 0 then pks = pet end
	end
	if pks then
		if self:doDisCard(pks, "h") then return true end
		if self:isWeak(pks) then
			return false
		end
	end
	if not self:isEnemy(target) then return false end
	return true
end

lol_xlnw_e_skill = {}
lol_xlnw_e_skill.name = "lol_xlnw_e"
table.insert(sgs.ai_skills, lol_xlnw_e_skill)
lol_xlnw_e_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lol_xlnw_eCard") then return end
	if #self.friends_noself < 1 then return end
	local card = sgs.Card_Parse("#lol_xlnw_eCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_xlnw_eCard"] = function(card, use, self)
	local target
	self:sort(self.friends_noself, "handcard", true)

	
	for _, friend in ipairs(self.friends_noself) do
		if self:hasHeavyDamage(friend, nil, nil) then
					target = friend
				end
		if target then break end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
						target = friend
			if target then break end
		end
	end
	
	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority["lol_xlnw_eCard"] = sgs.ai_use_priority.Slash  + 0.35
sgs.ai_use_value["lol_xlnw_eCard"] = 3
sgs.ai_card_intention["lol_xlnw_eCard"] = -40

lol_xlnw_r_skill = {}
lol_xlnw_r_skill.name = "lol_xlnw_r"
table.insert(sgs.ai_skills, lol_xlnw_r_skill)
lol_xlnw_r_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lol_xlnw_rCard") then return end
	if self.player:getMark("@lol_xlnw_r") < 1 then return end
	if #self.friends_noself < 1 then return end
	local card = sgs.Card_Parse("#lol_xlnw_rCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_xlnw_rCard"] = function(card, use, self)
	local target
	self:sort(self.friends, "hp")

	
	for _, friend in ipairs(self.friends) do
		if self:isWeak(friend) then
					target = friend
				end
		if target then break end
	end
	if not target then return end 
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	self:sort(self.friends, "handcard")
	local use_card = {}
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") and #use_card < target:getHp()  then
			table.insert(use_card, c:getEffectiveId())
		end
	end
	if #use_card ~= target:getHp() then return end
	
	if target then
		local card_str = string.format("#lol_xlnw_rCard:%s:", table.concat(use_card, "+"))
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(target)
		end
	end
end




sgs.ai_ajustdamage_from.lol_smss_q = function(self, from, to, card, nature)
	if (card and (card:isKindOf("Slash"))) and from:hasFlag("lol_smss_q")
	then
		return from:getMark("@lol_smss_q")
	end
end

sgs.ai_used_revises.lol_smss_q = function(self, use)
	if use.card:isKindOf("Slash")
		and not self.player:hasFlag("lol_smss_q")
		and not use.isDummy
		and not self.player:hasUsed("#lol_smss_qCard")
	then
		for _, to in sgs.list(use.to) do
			if self:isEnemy(to) and to:getHp() < 2 
				and getCardsNum("Jink", to, self.player) < 1 
			then
				local handcards = sgs.QList2Table(self.player:getCards("h"))
				local card_str = string.format("#lol_smss_qCard:%s:", handcards[1]:getEffectiveId())
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				use.to = sgs.SPlayerList()
				return false
			end
		end
	end
end

lol_smss_q_skill = {}
lol_smss_q_skill.name = "lol_smss_q"
table.insert(sgs.ai_skills, lol_smss_q_skill)
lol_smss_q_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lol_smss_qCard") then return end
	local card = sgs.Card_Parse("#lol_smss_qCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_smss_qCard"] = function(card, use, self)
	if self:isWeak() then	
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local invoke = false
	local use_card = {}
	for _,c in ipairs(handcards) do
		if c:isKindOf("Slash") then
			self:sort(self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if  self.player:getMark("@lol_smss_q") > 0 and self:slashIsEffective(c, enemy) then
					invoke = true
					break
				end
			end
		end
	end
	
	if invoke then
		local card_str = string.format("#lol_smss_qCard:%s:", handcards[1]:getEffectiveId())
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		end
	end
end
sgs.ai_use_priority["lol_smss_qCard"] = sgs.ai_use_priority.Slash + 8


lol_smss_w_skill = {}
lol_smss_w_skill.name = "lol_smss_w"
table.insert(sgs.ai_skills, lol_smss_w_skill)
lol_smss_w_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lol_smss_wCard") then return end

	local card
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:getSuit() == sgs.Card_Spade then
				card = hcard
				break
			end
		end
	end
	if card then
		card = sgs.Card_Parse("#lol_smss_wCard:" .. card:getEffectiveId()..":")
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#lol_smss_wCard"] = function(card, use, self)
	local target
	
	

	if not target then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if  self:isWeak(enemy) and enemy:getPile("lol_jiansu"):length() == 0 then
				target = enemy
				break
			end
		end
	end
	if not target then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if  self:getOverflow() > 0 and enemy:getPile("lol_jiansu"):length() == 0 then
				target = enemy
				break
			end
		end
	end

	if target then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority["lol_smss_wCard"] = 8
sgs.ai_use_value["lol_smss_wCard"] = 3
sgs.ai_card_intention["lol_smss_wCard"] = 50



local lol_smss_e_skill = {}
lol_smss_e_skill.name= "lol_smss_e"
table.insert(sgs.ai_skills,lol_smss_e_skill)
lol_smss_e_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("#lol_smss_eCard") then
		return sgs.Card_Parse("#lol_smss_eCard:.:")
	end
end

sgs.ai_skill_use_func["#lol_smss_eCard"] = function(card, use, self)
		local use_card
		local  cards
		local target
		cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") then
				use_card = card
				break
			end
		end
		self:sort(self.enemies)
		local max= 0
		for _, enemy in ipairs(self.enemies) do
			local x = 0
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				for _, p in sgs.qlist(self.room:getAlivePlayers()) do
					if enemy:distanceTo(p) <= 1 then
						x = x + 1
					end
				end
				if 3 - x > max then
					max = 3 - x
					target = enemy 
					break
				end
			end
		end
		
				if use_card and target  then
					use.card = sgs.Card_Parse("#lol_smss_eCard:" .. use_card:getId()..":")
					if use.to then
						use.to:append(target)
					end
	end
end

sgs.ai_use_priority["lol_smss_eCard"] = 7
sgs.ai_use_value["lol_smss_eCard"] = 3
sgs.ai_card_intention["lol_smss_eCard"] = 50


lol_smss_r_skill = {}
lol_smss_r_skill.name = "lol_smss_r"
table.insert(sgs.ai_skills, lol_smss_r_skill)
lol_smss_r_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lol_smss_rCard") then return end
	if self.player:getMark("@lol_smss_r") < 1 then return end
	local card = sgs.Card_Parse("#lol_smss_rCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_smss_rCard"] = function(card, use, self)
	if self:isWeak() then	
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local use_card = {}
	for _,c in ipairs(handcards) do
		if c:isBlack() and #use_card < self.player:getHp()  then
			table.insert(use_card, c:getEffectiveId())
		end
	end
	if #use_card ~= self.player:getHp() then return end
	
	
		local card_str = string.format("#lol_smss_rCard:%s:", table.concat(use_card, "+"))
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
	end
end






sgs.ai_canNiepan_skill.lol_ayjm_t = function(player)
	return player:getMark("@lol_ayjm_t") > 0
end

local lol_ayjm_q_skill={}
lol_ayjm_q_skill.name="lol_ayjm_q"
table.insert(sgs.ai_skills,lol_ayjm_q_skill)
lol_ayjm_q_skill.getTurnUseCard=function(self)
	if self:isWeak() then return nil end
	 if self.player:getHp() <= 1 then return nil end
    
    if self.player:hasFlag("lol_ayjm_q") then return nil end
   


	local card_str = ("slash:lol_ayjm_q[%s:%s]=."):format(sgs.Card_NoSuit, 0)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end



sgs.ai_skill_choice["lol_ayjm_w"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toDamage().to
	if #items == 1 then
		return items[1]
	end
	if target and self:isEnemy(target) and ((self:getCardsNum("Peach") + self.player:getHp() >= 2) or self:getOverflow() == 0) and  table.contains(items, "lol_ayjm_w_damage")  then
		return "lol_ayjm_w_damage"
	end
	if  target and (self:isFriend(target) or self:isWeak()) and  table.contains(items, "lol_ayjm_w_hp")  then
		return "lol_ayjm_w_hp"
	end
	return "cancel"
end





local lol_ayjm_e_skill={}
lol_ayjm_e_skill.name="lol_ayjm_e"
table.insert(sgs.ai_skills,lol_ayjm_e_skill)
lol_ayjm_e_skill.getTurnUseCard=function(self)
	if self:isWeak() then return nil end
    if self.player:hasFlag("lol_ayjm_e") then return nil end
    if self.player:getHp() <= 1 then return nil end
    
	local card_str = ("slash:lol_ayjm_e[%s:%s]=."):format(sgs.Card_NoSuit, 0)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end








lol_ayjm_r_skill = {}
lol_ayjm_r_skill.name = "lol_ayjm_r"
table.insert(sgs.ai_skills, lol_ayjm_r_skill)
lol_ayjm_r_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lol_ayjm_rCard") then return end
	if self.player:getMark("@lol_ayjm_r") < 1 then return end
	local card = sgs.Card_Parse("#lol_ayjm_rCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_ayjm_rCard"] = function(card, use, self)
	if self:isWeak() then	
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local invoke = false
	local use_card = {}
	for _,c in ipairs(handcards) do
		if c:isKindOf("Slash") then
			self:sort(self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if  self:isWeak(enemy) and self:slashIsEffective(c, enemy) then
					invoke = true
					break
				end
			end
		end
	end
	
	if invoke then
		use.card = card
		end
	end
end
sgs.ai_use_priority["lol_ayjm_rCard"] = sgs.ai_use_priority.Slash - 0.1


sgs.ai_canNiepan_skill.lol_bjfh_t = function(player)
	return true
end

local lol_bjfh_q_skill = {}
lol_bjfh_q_skill.name= "lol_bjfh_q"
table.insert(sgs.ai_skills,lol_bjfh_q_skill)
lol_bjfh_q_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#lol_bjfh_qCard:.:")
end

sgs.ai_skill_use_func["#lol_bjfh_qCard"] = function(card,use,self)
	
	local use_card,cards
	cards = self.player:getHandcards()
	for _,card in sgs.qlist(cards)do
		if card:isRed() then
			use_card = card
			break
		end
	end
	self:sort(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		then
			if use_card then
				use.card = sgs.Card_Parse("#lol_bjfh_qCard:"..use_card:getId()..":")
				if use.to then use.to:append(enemy) end
				break
			end
		end
	end
end

sgs.ai_use_value["#lol_bjfh_qCard"] = 2.5
sgs.ai_card_intention["#lol_bjfh_qCard"] = 80
sgs.dynamic_value.damage_card["#lol_bjfh_qCard"] = true



sgs.ai_skill_cardask["@lol_bjfh_q-card"]=function(self,data)
	local judge = data:toJudge()
	local all_cards = self:addHandPile("h")
	if #all_cards<1 then return "." end
	local cards = {}
	for _,card in sgs.list(all_cards)do
		if card:isRed() and not card:hasFlag("using") then
			table.insert(cards,card)
		end
	end
	if #cards<1 then return "." end
	local card_id = self:getRetrialCardId(cards,judge,nil,true)
	if card_id>=0 and self:needRetrial(judge)
	or self:getUseValue(judge.card)>self:getUseValue(sgs.Sanguosha:getCard(card_id))
	then return "$"..card_id end
	return "."
end

local lol_bjfh_e_skill = {}
lol_bjfh_e_skill.name= "lol_bjfh_e"
table.insert(sgs.ai_skills,lol_bjfh_e_skill)
lol_bjfh_e_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#lol_bjfh_eCard:.:")
end

sgs.ai_skill_use_func["#lol_bjfh_eCard"] = function(card,use,self)
	
	local use_card,cards
	cards = self.player:getHandcards()
	for _,card in sgs.qlist(cards)do
		use_card = card
		break
	end
	self:sort(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and enemy:getPile("lol_jiansu"):length()>0
		then
			if use_card then
				use.card = sgs.Card_Parse("#lol_bjfh_eCard:"..use_card:getId()..":")
				if use.to then use.to:append(enemy) end
				return
				
			end
		end
	end
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		then
			if use_card then
				use.card = sgs.Card_Parse("#lol_bjfh_eCard:"..use_card:getId()..":")
				if use.to then use.to:append(enemy) end
				return
				
			end
		end
	end
end

sgs.ai_use_value["#lol_bjfh_eCard"] = 2.5
sgs.ai_card_intention["#lol_bjfh_eCard"] = 80
sgs.dynamic_value.damage_card["#lol_bjfh_eCard"] = true

local lol_bjfh_r_skill = {}
lol_bjfh_r_skill.name= "lol_bjfh_r"
table.insert(sgs.ai_skills,lol_bjfh_r_skill)
lol_bjfh_r_skill.getTurnUseCard=function(self)
	if sgs.turncount<=1 then return end
	if self.player:getMark("@lol_bjfh_r") == 0 then return end
	return sgs.Card_Parse("#lol_bjfh_rCard:.:")
end

sgs.ai_skill_use_func["#lol_bjfh_rCard"] = function(card,use,self)
	
	local use_card,cards
	cards = self.player:getHandcards()
	for _,card in sgs.qlist(cards)do
		use_card = card
		break
	end
	local targets = {}
	self:sort(self.enemies)
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		then
			table.insert(targets, enemy)
		end
	end
	if #targets > 0 then
		if use_card then
			use.card = sgs.Card_Parse("#lol_bjfh_rCard:"..use_card:getId()..":")
			
			if use.to then 
				for _,enemy in sgs.list(targets)do 
					use.to:append(enemy) 
					end 
				end
			return
			
		end
	end
end

sgs.ai_use_value["#lol_bjfh_rCard"] = 2.5
sgs.ai_card_intention["#lol_bjfh_rCard"] = 80
sgs.dynamic_value.damage_card["#lol_bjfh_rCard"] = true



















local lol_sxls_q_skill={}
lol_sxls_q_skill.name="lol_sxls_q"
table.insert(sgs.ai_skills,lol_sxls_q_skill)
lol_sxls_q_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasFlag("lol_sxls_q") then return nil end
    local cards = self.player:getHandcards()
    cards=sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if (acard:getSuit() == sgs.Card_Heart)  then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if sgs.Sanguosha:getCard(id):getSuit() == sgs.Card_Heart		then
				card = sgs.Sanguosha:getCard(id)
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("slash:lol_sxls_q[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end







lol_sxls_w_skill = {}
lol_sxls_w_skill.name = "lol_sxls_w"
table.insert(sgs.ai_skills, lol_sxls_w_skill)
lol_sxls_w_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lol_sxls_wCard") then return end

	local card = sgs.Card_Parse("#lol_sxls_wCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_sxls_wCard"] = function(card, use, self)

	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local invoke = false
	local use_card = {}
	local slashes = self:getCards("Slash")
	for _,e in sgs.list(self.player:getEquips())do
		for _,slash in sgs.list(table.copyFrom(slashes))do
			if slash:getEffectiveId()==e:getId()
			or table.contains(slash:getSkillNames(), e:objectName())
			or not slash:isAvailable(self.player)
			then table.removeOne(slashes,slash) end
		end
	end
	if #slashes<1 then return end
	for _,enemy in sgs.list(self.enemies)do
		for _,slash in sgs.list(slashes)do
			local d = self:aiUseCard(slash)
			if d.card and d.to:contains(enemy)
			and not(self:hasEightDiagramEffect(enemy)) then
			invoke = true
			break
			end
		end
	end
	for _,c in ipairs(handcards) do
		if (#use_card < 1) and not (#self:getCards("Slash") <= 1 and c:isKindOf("Slash")) then
			table.insert(use_card, c:getEffectiveId())
		end
	end
	if #use_card ~= 1 then return end
	
	if invoke then
		local card_str = string.format("#lol_sxls_wCard:%s:", table.concat(use_card, "+"))
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		end
end
sgs.ai_use_priority["lol_sxls_wCard"] = sgs.ai_use_priority.Slash - 0.1



lol_sxls_e_skill = {}
lol_sxls_e_skill.name = "lol_sxls_e"
table.insert(sgs.ai_skills, lol_sxls_e_skill)
lol_sxls_e_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lol_sxls_eCard") then return end
	if self.player:getMark("@lol_sxls_e") == 1 then return end
	local card = sgs.Card_Parse("#lol_sxls_eCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_sxls_eCard"] = function(card, use, self)
		use.card = card
end
sgs.ai_use_priority["lol_sxls_eCard"] = sgs.ai_use_priority.Slash + 5.1


local lol_sxls_r_skill = {}
lol_sxls_r_skill.name = "lol_sxls_r"
table.insert(sgs.ai_skills,lol_sxls_r_skill)
lol_sxls_r_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#lol_sxls_rCard:.:")
end

sgs.ai_skill_use_func["#lol_sxls_rCard"] = function(card,use,self)
	local slashes = self:getCards("Slash")
	for _,e in sgs.list(self.player:getEquips())do
		for _,slash in sgs.list(table.copyFrom(slashes))do
			if slash:getEffectiveId()==e:getId()
			or table.contains(slash:getSkillNames(), e:objectName())
			or not slash:isAvailable(self.player)
			then table.removeOne(slashes,slash) end
		end
	end
	if #slashes<1 then return end
	self:sort(self.enemies,"hp")
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local use_card
	for _, card in ipairs(cards) do
		if not card:isKindOf("Slash") then
			use_card = card
		end
	end
	if not use_card	 then return end
	for _,enemy in sgs.list(self.enemies)do
		local n = 0
		for _,slash in sgs.list(slashes)do
			local d = self:aiUseCard(slash)
			if d.card and d.to:contains(enemy)
			and not(self:hasEightDiagramEffect(enemy)) then
				n = n+1
				if n>=enemy:getHp() then
					use.card = sgs.Card_Parse("#lol_sxls_rCard:.:")
					use.to:append(enemy)
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["lol_sxls_rCard"] = sgs.ai_use_priority.Slash+0.5
sgs.ai_use_value["lol_sxls_rCard"] = 3


sgs.ai_card_priority["lol_bzll_w_skill"] = function(self, card)
	if card and card:isKindOf("Slash") and table.contains(card:getSkillNames(), "lol_bzll_w")
	then
		return 0.1
	end
end




local lol_bzll_w_skill={}
lol_bzll_w_skill.name="lol_bzll_w"
table.insert(sgs.ai_skills,lol_bzll_w_skill)
lol_bzll_w_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasFlag("lol_bzll_w") then return nil end
    if self.player:getMark("lol_bzll_q") == 0 then return nil end
    local cards = self.player:getHandcards()
    cards=sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if (acard:getNumber() > self.player:getMark("lol_bzll_q") )  then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if sgs.Sanguosha:getCard(id):getNumber() > self.player:getMark("lol_bzll_q") 		then
				card = sgs.Sanguosha:getCard(id)
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("slash:lol_bzll_w[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end


lol_bzll_e_skill = {}
lol_bzll_e_skill.name = "lol_bzll_e"
table.insert(sgs.ai_skills, lol_bzll_e_skill)
lol_bzll_e_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#lol_bzll_eCard") then return end
	if self.player:getMark("@lol_bzll_e") ~= 0 then return end
	local card = sgs.Card_Parse("#lol_bzll_eCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#lol_bzll_eCard"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local use_card = {}
	
	for _,c in ipairs(handcards) do
		if #use_card < 1  then
			table.insert(use_card, c:getEffectiveId())
		end
	end
	if #use_card ~= 1 then return end
	
	if #use_card > 0 then
		local card_str = string.format("#lol_bzll_eCard:%s:", table.concat(use_card, "+"))
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		end
end


sgs.ai_skill_invoke.lol_bzll_e = function(self, data)
	local move = data:toMoveOneTime()
	local dest
	if move.from:objectName() == self.player:objectName() then dest = self.room:getCurrent() 
	else dest = self.room:findPlayer(move.from:getGeneralName())
	end
	if dest and self:isEnemy(dest) then
		return true
	end
	return false
end




local lol_bzll_r_skill={}
lol_bzll_r_skill.name="lol_bzll_r"
table.insert(sgs.ai_skills,lol_bzll_r_skill)
lol_bzll_r_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:getMark("lol_bzll_q") == 0 then return nil end
    if self.player:getMark("@lol_bzll_r") == 0 then return nil end
    local cards = self.player:getHandcards()
    cards=sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if (acard:getNumber() == self.player:getMark("lol_bzll_q") )  then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if sgs.Sanguosha:getCard(id):getNumber() == self.player:getMark("lol_bzll_q") 		then
				card = sgs.Sanguosha:getCard(id)
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("slash:lol_bzll_r[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end
sgs.ai_ajustdamage_from.lol_bzll_r = function(self, from, to, card, nature)
	if card and table.contains(card:getSkillNames(), "lol_bzll_r") and to and to:distanceTo(from) >= 2
	then
		return 1
	end
end






















