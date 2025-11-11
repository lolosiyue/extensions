if not sgs.ai_damage_effect then
	sgs.ai_damage_effect = {}
end


--
sgs.ai_skill_invoke.fateyezhan = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.fateyezhan = sgs.ai_skill_playerchosen.damage



--����

local fatetouying_skill = {}
fatetouying_skill.name = "fatetouying"
table.insert(sgs.ai_skills, fatetouying_skill)
fatetouying_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasFlag("fatetouyingx")  then return end
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(usable_cards, true)
	local cards = {}
	for _,c in ipairs(usable_cards) do
		local cardex = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self.player:getMark("fatetouyingskill")):objectName(), c:getSuit(), c:getNumber())
		cardex:setSkillName("fatetouying")
		cardex:deleteLater()
		if not self.player:isCardLimited(cardex, sgs.Card_MethodUse, true) and cardex:isAvailable(self.player) and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink") < 3) then
		local name = sgs.Sanguosha:getCard(self.player:getMark("fatetouyingskill")):objectName()
		local new_card = sgs.Card_Parse((name..":fatetouying[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
			assert(new_card) 
			return new_card
		end
	end
end

sgs.ai_view_as.fatetouying = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		local name = sgs.Sanguosha:getCard(player:getMark("fatetouyingskill")):objectName()
		if name and player:hasFlag("fatetouyingx") then
			return (name..":fatetouying[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|fatetouying"


--saber ���� 

sgs.ai_skill_invoke.fatewangzhe = function(self, data)
	return true
end

sgs.ai_skill_askforag.fatewangzhe = function(self, card_ids)
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
	until nextAlive:faceUp()

	local peach, ex_nihilo, jink, nullification, slash
	local valuable
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Peach") then peach = id end
		if card:isKindOf("ExNihilo") then ex_nihilo = id end
		if card:isKindOf("Jink") then jink = id end
		if card:isKindOf("Nullification") then nullification = id end
		if card:isKindOf("Slash") then slash = id end
	end
	valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
	local card = sgs.Sanguosha:getCard(valuable)
	if not (self:needKongcheng(self.player) and self:getHandcardNum() <= 2) then
		if card:isKindOf("Peach") then
			return valuable
		end
		if card:isKindOf("TrickCard") or card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage") then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				return valuable
			end
		end
		if card:isKindOf("Jink") and self:getCardsNum("Jink") == 0 then
			return valuable
		end
		if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
			return valuable
		end
		if card:isKindOf("Slash") and self:slashIsAvailable() then
			local dummy_use = { isDummy = true }
			self:useBasicCard(card, dummy_use)
			if dummy_use.card then
				return valuable
			end
		end
		return valuable
		end
	local hasLightning, hasIndulgence, hasSupplyShortage
	local tricks = nextAlive:getJudgingArea()
	if not tricks:isEmpty() and not nextAlive:containsTrick("YanxiaoCard") then
		local trick = tricks:at(tricks:length() - 1)
		if self:hasTrickEffective(trick, nextAlive) then
			if trick:isKindOf("Lightning") then hasLightning = true
			elseif trick:isKindOf("Indulgence") then hasIndulgence = true
			elseif trick:isKindOf("SupplyShortage") then hasSupplyShortage = true
			end
		end
	end

	if self:isEnemy(nextAlive) and nextAlive:hasSkill("luoshen") and valuable then
		return valuable
	end
	if nextAlive:hasSkill("yinghun") and nextAlive:isWounded() then
		return valuable
	end
	if target:hasSkill("hongyan") and hasLightning and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		for _, id in ipairs(card_ids) do
			local card = sgs.Sanguosha:getEngineCard(id)
			if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
				return id
			end
		end
	end
	if hasIndulgence and self:isFriend(nextAlive) then
		return valuable
	end
	if hasSupplyShortage and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		local enemy_null = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(p) then enemy_null = enemy_null - getCardsNum("Nullification", p) end
			if self:isEnemy(p) then enemy_null = enemy_null + getCardsNum("Nullification", p) end
		end
		enemy_null = enemy_null - self:getCardsNum("Nullification")
		if enemy_null < 0.8 then
			return valuable
		end
	end

	if self:isFriend(nextAlive) and not self:willSkipDrawPhase(nextAlive) and not self:willSkipPlayPhase(nextAlive)
		and not nextAlive:hasSkill("luoshen")
		and not nextAlive:hasSkill("tuxi") and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		if (peach and valuable == peach) or (ex_nihilo and valuable == ex_nihilo) then
			return valuable
		end
		if jink and valuable == jink and getCardsNum("Jink", nextAlive) < 1 then
			return valuable
		end
		if nullification and valuable == nullification and getCardsNum("Nullification", nextAlive) < 1 then
			return valuable
		end
		if slash and valuable == slash and self:hasCrossbowEffect(nextAlive) then
			return valuable
		end
	end

	local card = sgs.Sanguosha:getCard(valuable)
	local keep = false
	if card:isKindOf("Slash") or card:isKindOf("Jink")
		or card:isKindOf("EquipCard")
		or card:isKindOf("Disaster") or card:isKindOf("GlobalEffect") or card:isKindOf("Nullification")
		or target:isLocked(card) then
		keep = true
	end
	return valuable
end


sgs.ai_skill_use["@fatewangzhe"] = function(self, prompt, method)
	local tag = self.room:getTag("fatewangzhe")
	local guanxu_cardsToGet
    if tag then
        guanxu_cardsToGet = tag:toString():split("+")
    else
        return "."
    end
    local discard_cards = {}
	local drawpile = {}
    for i=1,#guanxu_cardsToGet, 1 do
        local card_data = guanxu_cardsToGet[i]
        if card_data == nil then break end
        if card_data ~= "" then 
            local card_id = tonumber(card_data)
            table.insert(drawpile, sgs.Sanguosha:getCard(card_id))
        end
    end
    
    self:sortByUseValue(drawpile)
	for _, c in ipairs(drawpile) do
        table.insert(discard_cards, c:getEffectiveId())
    end
        
		
    if #discard_cards > 0 then
        return string.format("#fatewangzhe:%s:", discard_cards[1])
    end
end





--saber:��ս
local fateqiuzhan_skill={}
fateqiuzhan_skill.name="fateqiuzhan"
table.insert(sgs.ai_skills,fateqiuzhan_skill)
fateqiuzhan_skill.getTurnUseCard=function(self)	
    if not self.player:hasUsed("#fateqiuzhan_card") then
		return sgs.Card_Parse("#fateqiuzhan_card:.:")
	end
end

sgs.ai_skill_use_func["#fateqiuzhan_card"]=function(card,use,self)
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
	local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit, 0)
	duel:setSkillName("fateqiuzhan_card")
	duel:deleteLater()
	local dummy_use = self:aiUseCard(duel, dummy())
	if dummy_use.card then
		for _,p in sgs.qlist(dummy_use.to)do
			if self:objectiveLevel(p) > 3 and not self:cantbeHurt(p) and self:isTiaoxinTarget(p) and self:canDamage(p,self.player,nil) then
				use.card = sgs.Card_Parse("#fateqiuzhan_card:.:")
				if use.to then
					use.to:append(p)
				end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and  self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and self:canDamage(enemy,self.player,nil)		then
			use.card = sgs.Card_Parse("#fateqiuzhan_card:.:") -- �������κ��ӿ��ļ��ܿ�
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end



-- ����ɱ���ڵ���Saber���Ƶ�һ�룬�򲻴��ɱ
sgs.ai_skill_cardask["@fateqzslash"]=function(self, data, pattern, target)
	target = target or global_room:getCurrent()
	if (self:hasSkill("fatehuyou") and #self.enemies > 0) then
		return "."
	end
	if (self:getCardsNum("Slash")*2 >= target:getHandcardNum()) then
		return "."
	end
end

local fateshenjian_skill={}
fateshenjian_skill.name="fateshenjian"
table.insert(sgs.ai_skills,fateshenjian_skill)
fateshenjian_skill.getTurnUseCard=function(self)	
	if (self.player:getMark("@shenjian_mark")== 0) or not self.player:isWounded() then return end
	if self.player:getHp() + self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 2 then
		return sgs.Card_Parse("#fateshenjian_card:.:")
	end
	local x = math.min(self.player:getLostHp(), 2)
	local target_num = 0
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal)  then
			target_num = target_num + 1
		end
	end
	if target_num > 1 then
		return sgs.Card_Parse("#fateshenjian_card:.:")
	end
		
end

sgs.ai_skill_use_func["#fateshenjian_card"]=function(card,use,self)
	local x = math.min(self.player:getLostHp(), 2)
	if self.player:getMark("@shenjian_mark") == 0 then return end
	local targets = sgs.SPlayerList()
	self:sort(self.enemies, "hp")
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local need_cards = {}
	for _, card in ipairs(cards) do
		if not card:isKindOf("Peach")  then 
			table.insert(need_cards, card:getId())
			if #need_cards >= 2 then
				break
			end
		end
	end
	if #need_cards < 2 then return end
	for _, enemy in ipairs(self.enemies) do
		if  self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and  self.player:inMyAttackRange(enemy)  and not self:cantbeHurt(enemy) and enemy:getHp() <= x and self:canDamage(enemy,self.player,nil) then
			targets:append(enemy)
			if targets:length() >= 2 then break end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not targets:contains(enemy) then
			if self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and  self.player:inMyAttackRange(enemy) then
				targets:append(enemy)
				if targets:length() >= 2 then break end
			end
		end
	end
	if targets:length() > 0 then
		use.card = sgs.Card_Parse("#fateshenjian_card:" .. table.concat(need_cards, "+")..":")
		if use.to then use.to = targets end
		-- for _,p in sgs.list(targets)do
		-- 	use.to:append(p)
		-- end
	end
end



--sgs.ai_use_priority["fateqiuzhan_card"] = 8
--sgs.ai_use_priority.fateqiuzhan_card = 8
--sgs.ai_card_intention["fateqiuzhan_card"] = 80
sgs.ai_use_value["#fateqiuzhan_card"] = 8.5
sgs.ai_use_priority["#fateqiuzhan_card"] = 2
sgs.dynamic_value.damage_card["fateqiuzhan_card"] = true
sgs.ai_card_intention["fateqiuzhan_card"] = 60
sgs.double_slash_skill = sgs.double_slash_skill .. "|fateqiuzhan"

sgs.ai_use_value["#fateshenjian_card"] = 8.5
sgs.ai_use_priority["#fateshenjian_card"] = 9
sgs.dynamic_value.damage_card["fateshenjian_card"] = true
sgs.ai_card_intention["fateshenjian_card"] = 100

sgs.straight_damage_skill = sgs.straight_damage_skill .. "|fateshenjian"


--Archer:�칭 ���ƽ׶Σ��������һ������Ȼ��ѡ��һ����ɫ����������1���ڵĽ�ɫ����Ϊ��������һ�Ų�������ƽ׶����Ƶ���ɫ�ġ���ɱ����ÿ�غ���һ�Ρ�
local fatetiangong_skill={}
fatetiangong_skill.name="fatetiangong_vs"
table.insert(sgs.ai_skills,fatetiangong_skill)
fatetiangong_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasUsed("#fatetiangong_card") then return nil end
    local cards = self.player:getHandcards()
    cards=sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	local card_str = ("#fatetiangong_card:%d:"):format(cards[1]:getId())
    return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#fatetiangong_card"]=function(card,use,self)
	local first
	local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy) and self:canDamage(enemy,self.player,slash)
						and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
			use.card = sgs.Card_Parse("#fatetiangong_card:" .. card:getEffectiveId()..":")  -- �����ӿ��ļ��ܿ�
			if use.to then
				use.to:append(enemy)
				first=enemy
				break
			end
		end
	end
	if first and self.player:distanceTo(first) == 1 then 
		for _, enemy2 in ipairs(self.enemies) do
		--	if ((enemy2:getSeat() - first:getSeat())==1 or (enemy2:getSeat() - first:getSeat())==-1) and not self:cantbeHurt(enemy) and enemy:getMark("@fog") < 1 and not enemy:hasSkill("fatefapao") then
			if (self.player:distanceTo(enemy2) == 1) and enemy2:getSeat() ~= first:getSeat() and not self:cantbeHurt(enemy2) and self.player:canSlash(enemy2, slash) and not self:slashProhibit(slash, enemy2) and self:canDamage(enemy2,self.player,nil)
						and self:slashIsEffective(slash, enemy2) and self:isGoodTarget(enemy2, self.enemies, slash) then
				use.to:append(enemy2)
				return
			end
		end
	end
end

sgs.ai_use_value.fatetiangong_card = 7.5
sgs.ai_use_priority.fatetiangong_card = 4
sgs.ai_card_intention.fatetiangong_card = 70

sgs.double_slash_skill = sgs.double_slash_skill .. "|fatetiangong_vs"

sgs.ai_skill_invoke.fatejianzhong = function(self, data)
	return true
end
sgs.ai_target_revises.fatejianzhong = function(to, card)
	if  card:isKindOf("ArcheryAttack")
	then
		return true
	end
end

sgs.ai_skill_cardask["@fatejianzhong1"] = function(self, data, pattern, target)
	local targets = sgs.SPlayerList()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do 
		if self.player:canSlash(p,nil, false) then 
			targets:append(p)
		end
	end
	if targets:isEmpty() then return "." end
	if sgs.ai_skill_playerchosen["@fatejianzhong2"](self, targets) == nil then return "." end
	self:sortByKeepValue(cards)
	for _,card in sgs.list(cards)do
		return "$"..card:getEffectiveId()
	end
	return "."
end

sgs.ai_skill_playerchosen["@fatejianzhong2"] = sgs.ai_skill_playerchosen.zero_card_as_slash


--Berserker
--[[sgs.ai_skill_cardask["@fatejuli-jink-1"] = function(self)
    if (not (self:getCardsNum("Jink") > 0 and self:getCardsNum("Slash") > 0)) and (not (self.player:getHandcardNum() == 1 and self:hasSkills(sgs.need_kongcheng))) and (not self:hasSkill("lianying"))  then return "." end	
end]]

sgs.ai_skill_cardask["@fatejuli-jink-1"] = function(self, data, pattern, target)
	local isdummy = type(data) == "number"
	local function getJink()
		if (self:getCardsNum("Jink") > 0 and self:getCardsNum("Slash") > 0) then
		return self:getCardId("Slash") or not isdummy and "."
		else
		return "."
		end
	end
	local effect = data:toCardEffect()
	local slash = effect.card
	local cards = sgs.QList2Table(self.player:getHandcards())
	if (not target or self:isFriend(target)) and slash:hasFlag("nosjiefan-slash") then return "." end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	
	if not self:slashIsEffective(slash,self.player,effect.from)
		or (self:ajustDamage(effect.from,self.player,1,slash)<2
		and self:needToLoseHp(self.player,effect.from,slash)) then return "." end
		if self:ajustDamage(effect.from,self.player,1,slash) and self:getCardsNum("Peach")>0 then return "." end
	if not target then return getJink() end
	if not self:hasHeavyDamage(target, slash, self.player) and self:needToLoseHp(self.player, target, slash) then return "." end
	
	if self:ajustDamage(target, nil, 1, slash) <= 0 then return "." end

	if slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, target, nil, nil, slash) then return "." end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player, 50, target) then return getJink() end
		if target:hasSkill("jieyin") and not self.player:isWounded() and self.player:isMale() and not self.player:hasSkills("leiji|nosleiji|olleiji|jieleiji") then return "." end
		if not target:hasSkill("jueqing") then
			if (target:hasSkill("nosrende") or (target:hasSkill("rende") and not target:hasUsed("RendeCard"))) and self.player:hasSkill("jieming") then return "." end
			if target:hasSkill("pojun") and not self.player:faceUp() then return "." end
			--add dmpkancolle
			if target:hasSkill("BurningLove") and slash:isKindOf("FireSlash") then return "." end
		end
	else
		if self:hasHeavyDamage(target, slash, self.player) then return getJink() end

		local current = self.room:getCurrent()
		if current and current:hasSkill("juece") and self.player:getHp() > 0 then
			local use = false
			for _, card in ipairs(self:getCards("Jink")) do
				if not self.player:isLastHandCard(card, true) then
					use = true
					break
				end
			end
			if not use then return not isdummy and "." end
		end
		if self.player:getHandcardNum() == 1 and self:needKongcheng() then return getJink() end
		if not self:hasLoseHandcardEffective() and not self.player:isKongcheng() then return getJink() end
		if target:hasSkill("mengjin") and not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if self.player:getCards("he"):length() == 1 and not self.player:getArmor() then return getJink() end
			if self.player:hasSkills("jijiu|qingnang") and self.player:getCards("he"):length() > 1 then return "." end
			if self:canUseJieyuanDecrease(target) then return "." end
			if (self:getCardsNum("Peach") > 0 or (self:getCardsNum("Analeptic") > 0 and self:isWeak()))
				and not self.player:hasSkills("tuntian+zaoxian") and not self:willSkipPlayPhase() then
				return "."
			end
		end
		if self.player:getHp() > 1 and getKnownCard(target, self.player, "Slash") >= 1 and getKnownCard(target, self.player, "Analeptic") >= 1 and self:getCardsNum("Jink") == 1
			and (target:getPhase() < sgs.Player_Play or self:slashIsAvailable(target) and target:canSlash(self.player)) then
			return "."
		end
		if not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if target:hasWeapon("axe") then
				if target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 1 and target:getCards("he"):length() > 2 then return not isdummy and "." end
				if target:getHandcardNum() - target:getHp() > 2 and not self:isWeak() and not self:getOverflow() then return not isdummy and "." end
			elseif target:hasWeapon("blade") then
				
				local has_weak_chained_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if friend:isChained() and self:isWeak(friend) then
						has_weak_chained_friend = true
					end
				end
				if has_weak_chained_friend and slash:isKindOf("NatureSlash") and self.player:isChained() then
					return getJink()
				end
				
				if slash:isKindOf("NatureSlash") and self.player:hasArmorEffect("vine")
					or self.player:hasArmorEffect("renwang_shield")
					or self:hasEightDiagramEffect()
					or self:hasHeavyDamage(target, slash, self.player)
					or (self.player:getHp() == 1 and #self.friends_noself == 0) then
				elseif (self:getCardsNum("Jink") <= getCardsNum("Slash", target, self.player) or self.player:hasSkill("qingnang")) and self.player:getHp() > 1
					or (self.player:hasSkill("jijiu") and getKnownCard(self.player, self.player, "red") > 0)
					or self:canUseJieyuanDecrease(target)
					then
					return not isdummy and "."
				end
			end
		end
	end
	return getJink()
end

sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|fateshilian"
sgs.hit_skill = sgs.hit_skill .. "|fatejuli"
sgs.ai_cardneed.fatejuli = sgs.ai_cardneed.slash


sgs.ai_skill_cardask["@fatejuli-jink-2"] = function(self, data, pattern, target)
	local isdummy = type(data) == "number"
	local function getJink()
		if target and target:hasSkill("dahe") and self.player:hasFlag("dahe") then
			for _, card in ipairs(self:getCards("Jink")) do
				if card:getSuit() == sgs.Card_Heart then return card:getId() end
			end
			return "."
		end
		return self:getCardId("Jink") or not isdummy and "."
	end

	local slash
	if type(data) == "userdata" then
		local effect = data:toCardEffect()
		slash = effect.card
	else
		slash = sgs.Sanguosha:cloneCard("slash")
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	if (not target or self:isFriend(target)) and slash:hasFlag("nosjiefan-slash") then return "." end
	if sgs.ai_skill_cardask.nullfilter(self, data, pattern, target) then return "." end
	if not target then return getJink() end
	if not self:hasHeavyDamage(target, slash, self.player) and self:needToLoseHp(self.player, target, slash) then return "." end
	
	if self:ajustDamage(target, nil, 1, slash) <= 0 then return "." end

	if slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, target, nil, nil, slash) then return "." end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player, 50, target) then return getJink() end
		if target:hasSkill("jieyin") and not self.player:isWounded() and self.player:isMale() and not self.player:hasSkills("leiji|nosleiji|olleiji|jieleiji") then return "." end
		if not target:hasSkill("jueqing") then
			if (target:hasSkill("nosrende") or (target:hasSkill("rende") and not target:hasUsed("RendeCard"))) and self.player:hasSkill("jieming") then return "." end
			if target:hasSkill("pojun") and not self.player:faceUp() then return "." end
			--add dmpkancolle
			if target:hasSkill("BurningLove") and slash:isKindOf("FireSlash") then return "." end
		end
	else
		if self:hasHeavyDamage(target, slash, self.player) then return getJink() end

		local current = self.room:getCurrent()
		if current and current:hasSkill("juece") and self.player:getHp() > 0 then
			local use = false
			for _, card in ipairs(self:getCards("Jink")) do
				if not self.player:isLastHandCard(card, true) then
					use = true
					break
				end
			end
			if not use then return not isdummy and "." end
		end
		if self.player:getHandcardNum() == 1 and self:needKongcheng() then return getJink() end
		if not self:hasLoseHandcardEffective() and not self.player:isKongcheng() then return getJink() end
		if target:hasSkill("mengjin") and not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if not self:doDisCard(self.player, "he", true) then return getJink() end
			if self.player:getCards("he"):length() == 1 and not self.player:getArmor() then return getJink() end
			if self.player:hasSkills("jijiu|qingnang") and self.player:getCards("he"):length() > 1 then return "." end
			if self:canUseJieyuanDecrease(target) then return "." end
			if (self:getCardsNum("Peach") > 0 or (self:getCardsNum("Analeptic") > 0 and self:isWeak()))
				and not self.player:hasSkills("tuntian+zaoxian") and not self:willSkipPlayPhase() then
				return "."
			end
		end
		if self.player:getHp() > 1 and getKnownCard(target, self.player, "Slash") >= 1 and getKnownCard(target, self.player, "Analeptic") >= 1 and self:getCardsNum("Jink") == 1
			and (target:getPhase() < sgs.Player_Play or self:slashIsAvailable(target) and target:canSlash(self.player)) then
			return "."
		end
		if not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if target:hasWeapon("axe") then
				if target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 1 and target:getCards("he"):length() > 2 then return not isdummy and "." end
				if target:getHandcardNum() - target:getHp() > 2 and not self:isWeak() and not self:getOverflow() then return not isdummy and "." end
			elseif target:hasWeapon("blade") then
				
				local has_weak_chained_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if friend:isChained() and self:isWeak(friend) then
						has_weak_chained_friend = true
					end
				end
				if has_weak_chained_friend and slash:isKindOf("NatureSlash") and self.player:isChained() then
					return getJink()
				end
				
				if slash:isKindOf("NatureSlash") and self.player:hasArmorEffect("vine")
					or self.player:hasArmorEffect("renwang_shield")
					or self:hasEightDiagramEffect()
					or self:hasHeavyDamage(target, slash, self.player)
					or (self.player:getHp() == 1 and #self.friends_noself == 0) then
				elseif (self:getCardsNum("Jink") <= getCardsNum("Slash", target, self.player) or self.player:hasSkill("qingnang")) and self.player:getHp() > 1
					or (self.player:hasSkill("jijiu") and getKnownCard(self.player, self.player, "red") > 0)
					or self:canUseJieyuanDecrease(target)
					then
					return not isdummy and "."
				end
			end
		end
	end
	return getJink()
end

sgs.ai_skill_invoke.fateshilian = function(self, data)
 	return true
end


--Iriya��ħ��
sgs.ai_skill_invoke.fatemoli = function(self, data)
	local baba = self.room:findPlayerBySkillName("fatejiezhi")
    if baba and self:isEnemy(baba) then
        return false
    else
		return true
	end
end

--��ʱ��bug
--Iriya:Loli
local fateloli_skill={}
fateloli_skill.name="fateloli_vs"
table.insert(sgs.ai_skills,fateloli_skill)
fateloli_skill.getTurnUseCard=function(self)
    if not self.player:hasUsed("#fateloli_card") then
		return sgs.Card_Parse("#fateloli_card:.:")
	end
end


sgs.ai_skill_use_func["#fateloli_card"]=function(card,use,self)
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				use.card = sgs.Card_Parse("#fateloli_card:.:") -- �������κ��ӿ��ļ��ܿ�
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
end

sgs.ai_use_priority["fateloli_card"] = 9.2
sgs.ai_card_intention["fateloli_card"] = 50

sgs.ai_skill_askforag["fateloli_vs"] = function(self, card_ids)
	local target = self.room:getTag("fateloli"):toPlayer()
	if not target or self:isFriend(target) then return -1 end
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
	until nextAlive:faceUp()

	local peach, ex_nihilo, jink, nullification, slash
	local valuable
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Peach") then peach = id end
		if card:isKindOf("ExNihilo") then ex_nihilo = id end
		if card:isKindOf("Jink") then jink = id end
		if card:isKindOf("Nullification") then nullification = id end
		if card:isKindOf("Slash") then slash = id end
	end
	valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
	local card = sgs.Sanguosha:getCard(valuable)
	if self:isEnemy(target) and target:hasSkill("tuntian") and card:getSuit() == sgs.Card_Heart then
		return valuable
	end

	local willUseExNihilo, willRecast
	if self:getCardsNum("ExNihilo") > 0 then
		local ex_nihilo = self:getCard("ExNihilo")
		if ex_nihilo then
			local dummy_use = self:aiUseCard(ex_nihilo, dummy())
			if dummy_use.card then willUseExNihilo = true end
		end
	elseif self:getCardsNum("IronChain") > 0 then
		local iron_chain = self:getCard("IronChain")
		if iron_chain then
			local dummy_use = self:aiUseCard(iron_chain, dummy())
			if dummy_use.card and dummy_use.to:isEmpty() then willRecast = true end
		end
	end
	if willUseExNihilo or willRecast then
		local card = sgs.Sanguosha:getCard(valuable)
		if card:isKindOf("Peach") then
			return valuable
		end
		if card:isKindOf("TrickCard") or card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage") then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return valuable
			end
		end
		if card:isKindOf("Jink") and self:getCardsNum("Jink") == 0 then
			return valuable
		end
		if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
			return valuable
		end
		if card:isKindOf("Slash") and self:slashIsAvailable() then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return valuable
			end
		end
		return valuable
	end
--[[
	local hasLightning, hasIndulgence, hasSupplyShortage
	local tricks = nextAlive:getJudgingArea()
	if not tricks:isEmpty() and not nextAlive:containsTrick("YanxiaoCard") then
		local trick = tricks:at(tricks:length() - 1)
		if self:hasTrickEffective(trick, nextAlive) then
			if trick:isKindOf("Lightning") then hasLightning = true
			elseif trick:isKindOf("Indulgence") then hasIndulgence = true
			elseif trick:isKindOf("SupplyShortage") then hasSupplyShortage = true
			end
		end
	end

	if self:isEnemy(nextAlive) and nextAlive:hasSkill("luoshen") and valuable then
		self.gongxinchoice = "put"
		return valuable
	end
	if nextAlive:hasSkill("yinghun") and nextAlive:isWounded() then
		self.gongxinchoice = self:isFriend(nextAlive) and "put" or "discard"
		return valuable
	end
	if target:hasSkill("hongyan") and hasLightning and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		for _, id in ipairs(card_ids) do
			local card = sgs.Sanguosha:getEngineCard(id)
			if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
				self.gongxinchoice = "put"
				return id
			end
		end
	end
	if hasIndulgence and self:isFriend(nextAlive) then
		self.gongxinchoice = "put"
		return valuable
	end
	if hasSupplyShortage and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		local enemy_null = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(p) then enemy_null = enemy_null - getCardsNum("Nullification", p) end
			if self:isEnemy(p) then enemy_null = enemy_null + getCardsNum("Nullification", p) end
		end
		enemy_null = enemy_null - self:getCardsNum("Nullification")
		if enemy_null < 0.8 then
			self.gongxinchoice = "put"
			return valuable
		end
	end
]]
	if self:isFriend(nextAlive) and not self:willSkipDrawPhase(nextAlive) and not self:willSkipPlayPhase(nextAlive)
		and not nextAlive:hasSkill("luoshen")
		and not nextAlive:hasSkill("tuxi") and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		if (peach and valuable == peach) or (ex_nihilo and valuable == ex_nihilo) then
			return valuable
		end
		if jink and valuable == jink and getCardsNum("Jink", nextAlive) < 1 then
			return valuable
		end
		if nullification and valuable == nullification and getCardsNum("Nullification", nextAlive) < 1 then
			return valuable
		end
		if slash and valuable == slash and self:hasCrossbowEffect(nextAlive) then
			return valuable
		end
	end
	return valuable
end

sgs.ai_skill_discard["fateduoluo"] = function(self, discard_num, min_num, optional, include_equip)
	local current = self.room:getCurrent()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(handcards)
	local to_discard = {}
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach")
		--and not c:isKindOf("Jink")
		and not c:isKindOf("Analeptic")
		then
			if #to_discard < min_num then
				table.insert(to_discard, c:getEffectiveId())
			end
		end
	end
	if #to_discard == min_num then
		return to_discard
	end
	return {}
end

sgs.need_kongcheng = sgs.need_kongcheng .. "|fatenixi"

--�෵ ����Խ��ݻ��Ƶ�������ʹ�û���������Ƭ�Ƶ���ɱ��ʹ�û�����
sgs.ai_view_as.fateyanfan_vs = function(card, player, card_place)
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getEffectiveId()
    if card:getSuit()== sgs.Card_Diamond and not card:isKindOf("Peach") then
        return ("slash:fateyanfan_vs[%s:%s]=%d"):format(suit, number, card_id)
    end
	if card:getSuit()== sgs.Card_Club then
        return ("jink:fateyanfan_vs[%s:%s]=%d"):format(suit, number, card_id)
    end
end

local fateyanfan_vs_skill={}
fateyanfan_vs_skill.name="fateyanfan_vs"
table.insert(sgs.ai_skills,fateyanfan_vs_skill)
fateyanfan_vs_skill.getTurnUseCard=function(self,inclusive)
    local cards = self.player:getCards("he")
    cards=sgs.QList2Table(cards)
    
    local diamond_card
    
    self:sortByUseValue(cards,true)
    
    for _,card in ipairs(cards) do
        if card:getSuit()== sgs.Card_Diamond and not card:isKindOf("Slash") and not card:isKindOf("Peach") 				--not peach
            and ((self:getUseValue(card)<sgs.ai_use_value.Slash) or inclusive) then
            diamond_card = card
            break
        end
    end

    if diamond_card then		
        local suit = diamond_card:getSuitString()
        local number = diamond_card:getNumberString()
        local card_id = diamond_card:getEffectiveId()
        local card_str = ("slash:fateyanfan_vs[%s:%s]=%d"):format(suit, number, card_id)
        local slash = sgs.Card_Parse(card_str)
        
        assert(slash)
        
        return slash
    end
end

sgs.Kojirou_suit_value = 
{
    diamond = 3.9,
    club = 4.8
}

sgs.double_slash_skill = sgs.double_slash_skill .. "|fatexunjie"

--Carene ʥ��
sgs.ai_skill_invoke.fateshenghai = function(self, data)
	return true
end

sgs.ai_ajustdamage_to.fateshenghai = function(self, from, to, card, nature)
	if to:getMark("&fateshenghai") > 0 
	then
		return -99
	end
end

sgs.ai_can_damagehp.fateshenghai = function(self, from, card, to)
	if from and to:getHp() - self:ajustDamage(from, to, 1, card) == 0
		and self:canLoseHp(from, card, to) and self:getAllPeachNum() > 0
	then
		return to:getPhase() == sgs.Player_NotActive
	end
end

fateshenghai_damageeffect = function(self, to, nature, from)
	if to:hasSkill("fateshenghai") and to:getMark("@fateshenghai") > 0 then return false end
	return true
end
table.insert(sgs.ai_damage_effect, fateshenghai_damageeffect)

--Kirei �ڼ� ������ڳ��ƽ׶ν�һ�ź�ɫ���ƣ�ÿ�غ���һ�Σ���������ɫ����ʱ�����ĺ�ɫ����������佫���ϣ���Ϊ����������ÿӵ��һ�š��������������ޱ�+1��
--���ܵ��˺�ʱ����������һ�š�����ʹ�˺�-1������˺�ʱ����������һ�š�����ʹ�˺�+1�������ֻ��ͬʱӵ�����š�������

local fateheijian_skill={}
fateheijian_skill.name="fateheijian"
table.insert(sgs.ai_skills,fateheijian_skill)
fateheijian_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("#fateheijian_card") and not self.player:isKongcheng() and (self.player:getPile("fateheijiancards")):length() < 5 then
	    local cards = self.player:getCards("h")
	    cards = sgs.QList2Table(cards)
	    self:sortByKeepValue(cards)
	    for _, c in ipairs(cards) do
			if c:isBlack() and not (c:isKindOf("Nullification") and self:getCardsNum("Nullification") == 1 and self.player:getHp() > 1) then 
	    		return sgs.Card_Parse("#fateheijian_card:" .. c:getEffectiveId()..":") 
	    	end
	    end
	end
end

sgs.ai_skill_use_func["#fateheijian_card"]=function(card,use,self)
	use.card=card
	if use.to then
		use.to:append(self.player)
	end
end

sgs.ai_skill_invoke["fateheijianDamage"] = function(self, data)
	--���ܷ���ʱ������
	local damage = data:toDamage()
	if self:isFriend(damage.to) then return false end--�Զ��Ѳ�����
	if damage.to:getHp()<3 then return true end--��2Ѫ��2Ѫ���µĵ��˷���
	if self.player:getHp() == 1 then return false end--1Ѫʱ������
--[[	local i=0
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	for _, c in ipairs(cards) do
	    if c:isBlack() then
			i=i+1
		end
	end]]
	if ((self.player:getPile("fateheijiancards")):length() < 2)  and (self:getCardsNum("Jink") == 0) then --and (i==0) then--����ֻ��һ�ż�����������ʱ��������
		return false
	end
	return true	
end

sgs.ai_skill_invoke["fateheijianDefense"] = function(self, data)
	if self:getCardsNum("Peach") < 2 then --�����������ϵ���
		return true
	end		
end

function sgs.ai_cardneed.fateheijian(to,card)
	return to:getPile("fateheijiancards"):length() < 2 and card:isBlack()
end

sgs.ai_skill_invoke["fateheijianJianpai"] = function(self, data)
	return true		
end

sgs.Kirei_suit_value = 
{
	spade = 2.7,
	club = 2.7
}

--Lancelot
--sgs.ai_skill_invoke["fatefanji"] = function(self, data)
sgs.ai_skill_invoke["fatefanji"] = function(self, data, pattern, target)
--[[	local target = data:toResponsed().m_who
	if self:getCardsNum("Slash") >0 and not self:isFriend(target) then --��ɱ�Ҳ��Ƕ���
		return true
	end	
	
	local target = data:toPlayer()
	if self:isFriend(target) then
		return false
	end
	]]	
	if self:getCardsNum("Slash") == 0 then --ûɱ
		return false
	end
	local cur = self.room:getCurrent() --����Ѳ��ԣ�û������
	--local target = data:toPlayer()
--	local target = data:toResponsed().m_who
	--if target then return true end               self:isFriend(next_player)
	if self:isFriend(cur) then return false end
	return true
end

local fatefanshi_skill={}
fatefanshi_skill.name="fatefanshi"
table.insert(sgs.ai_skills,fatefanshi_skill)
fatefanshi_skill.getTurnUseCard=function(self)
    if not self.player:hasUsed("#fatefanshi_card") then
		return sgs.Card_Parse("#fatefanshi_card:.:")
	end
end

sgs.ai_skill_use_func["#fatefanshi_card"]=function(card,use,self)
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and self.player:distanceTo(enemy) <= self.player:getAttackRange() then
				use.card = sgs.Card_Parse("#fatefanshi_card:.:") -- �������κ��ӿ��ļ��ܿ�
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
end

sgs.ai_use_priority["#fatefanshi_card"] = 2.2
sgs.ai_card_intention["#fatefanshi_card"] = 100


local fatexinyin_skill={}
fatexinyin_skill.name="fatexinyin"
table.insert(sgs.ai_skills,fatexinyin_skill)
fatexinyin_skill.getTurnUseCard=function(self)
    if not self.player:hasUsed("#fatexinyin_card") then
		return sgs.Card_Parse("#fatexinyin_card:.:")
	end
end

sgs.ai_skill_use_func["#fatexinyin_card"]=function(card,use,self)
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and self.player:distanceTo(enemy) <= 1 then
				use.card = sgs.Card_Parse("#fatexinyin_card:.:") -- �������κ��ӿ��ļ��ܿ�
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
end

sgs.ai_use_priority["#fatexinyi_card"] = 7
sgs.ai_card_intention["#fatexinyi_card"] = 80

sgs.ai_skill_choice.fatexinyin_card=function(self,choices)
	return "xychoice1"
end

sgs.straight_damage_skill = sgs.straight_damage_skill .. "|fatexinyin"

--Rin Զ����
sgs.ai_skill_invoke["fateqingxing"] = function(self, data)
	--���Լ���������ж�����Ѫ�ͷ���
	--�Զ��ѣ����Ѫ��С��3����Ѫ����+����>2���Է���
	--���ܷ���ʱ������
	local cards = self.player:getCards("he")
	local i=0
	cards = sgs.QList2Table(cards)
	for _, c in ipairs(cards) do
		if c:getSuit()==sgs.Card_Heart or c:isKindOf("Jink")then 
	    		i=i+1
	    end
	end
	if i==0 then return false end
	local player = self.room:getCurrent()
	if not self:isFriend(player) then return false end
	local judges = player:getJudgingArea() --���� QList<const Card *>
	if player:hasSkill("fateqingxing") then 
		if player:isWounded() and player:getMark("@fatebimie")==0 then
			return true
		end
		if not judges:isEmpty() then
			if self:hasWizard(self.enemies) then return true end --��������������ֱ�ӷ���
			for _,cd in sgs.qlist(judges) do
				if not cd:isKindOf("Lightning") then return true end --"Lightning"��ʵӦ��Ϊ�����֡�
			end
		else 
			return false --����ֻ������
		end
	end
	if (player:getHp() < 2 and player:isWounded()) and player:getMark("@fatebimie")==0 then return true end
	local cards = self.player:getCards("he")
    cards=sgs.QList2Table(cards)
    local card
	local i=0
    self:sortByUseValue(cards,true)
    for _,acard in ipairs(cards)  do
        if (acard:getSuit() == sgs.Card_Heart) then 
			i=i+1
		end
    end
	if (player:getHp() < 3 and player:isWounded() and (self:getCardsNum("Jink")+ i> 1)) then return true end
	return false
end

sgs.ai_skill_cardask["@fateqingxing1"] = function(self, data, pattern, target)
	local cards = self.player:getCards("he")
	local i=0
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local heart = {}
	for _, c in ipairs(cards) do
		if c:getSuit()==sgs.Card_Heart or c:isKindOf("Jink")then 
	    		i=i+1
				table.insert(heart, c:getEffectiveId())
	    end
	end
	if i==0 then return "." end
	local player = self.room:getCurrent()
	if not self:isFriend(player) then return "." end
	local judges = player:getJudgingArea() --���� QList<const Card *>
	if player:hasSkill("fateqingxing") then 
		if player:isWounded() and player:getMark("@fatebimie")==0 then
			return "$" .. heart[1]
		end
		if not judges:isEmpty() then
			if self:hasWizard(self.enemies) then return "$" .. heart[1] end --��������������ֱ�ӷ���
			for _,cd in sgs.qlist(judges) do
				if not cd:isKindOf("Lightning") then return "$" .. heart[1] end --"Lightning"��ʵӦ��Ϊ�����֡�
			end
		else 
			return "." --����ֻ������
		end
	end
	if (self:isWeak(player) and player:isWounded()) and player:getMark("@fatebimie")==0 then return  "$" .. heart[1] end
	local cards = self.player:getCards("he")
    cards=sgs.QList2Table(cards)
    local card
	local i=0
    self:sortByUseValue(cards,true)
    for _,acard in ipairs(cards)  do
        if (acard:getSuit() == sgs.Card_Heart) then 
			i=i+1
		end
    end
	if self:needToThrowArmor() and self.player:getArmor():getSuit() == sgs.Card_Heart then
		return "$" .. self.player:getArmor() 
	end
	if ((not judges:isEmpty() or  player:getHp() < getBestHp(player)) and (self:getCardsNum("Jink")+ i> 1)) then return  "$" .. heart[1] end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@fateqingxing1"] = function(self,player,promptlist)
	if promptlist[#promptlist]~="" then
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player,current,-80)
	end
end

sgs.ai_armor_value.fatejizhi = function(player,self,card)
	if not card then return 4 end
end
sgs.ai_card_priority.fatejizhi = function(self,card,v)
    if self.useValue
	and card:isKindOf("Armor")
	then v = 2 end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|fateqingxing"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|fateqingxing"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|fatebumo"

sgs.Rin_suit_value = 
{
	heart = 6
}

sgs.Rin_keep_value = 
{
    Jink = 6.5
}

function sgs.ai_cardneed.fateqingxing(to, card, self)
	return (card:getSuit()==sgs.Card_Heart or card:isKindOf("Jink")) and to:getCards("he"):length() < 4
end

local fatebumo_skill={}
fatebumo_skill.name="fatebumo"
table.insert(sgs.ai_skills,fatebumo_skill)
fatebumo_skill.getTurnUseCard=function(self)
    if (self.player:getMark("@bumo_mark")>0) and (self.player:isWounded() or self.player:getHandcardNum() < self.player:getMaxHp()) then
    	return sgs.Card_Parse("#fatebumo_card:.:")
	end
end

sgs.ai_skill_use_func["#fatebumo_card"]=function(card,use,self)
    self:sort(self.friends_noself, "hp")
    local lord = self.room:getLord()
    if self:isFriend(lord) and not sgs.isLordHealthy()  and lord:isMale() and lord:isWounded() then
        use.card=card
        if use.to then use.to:append(lord) end
        return
    end
    for _, friend in ipairs(self.friends_noself) do
        if friend:getGender()~=self.player:getGender() and self:isWeak(friend) and (friend:getSeat() - self.player:getSeat()) % (global_room:alivePlayerCount()) < 3 then 
            use.card=card
            if use.to then use.to:append(friend) end
            return
        end
    end
end

--Sakura ��ͩӣ

local fatechuyi_vs_skill={}
fatechuyi_vs_skill.name="fatechuyi_vs"
table.insert(sgs.ai_skills,fatechuyi_vs_skill)
fatechuyi_vs_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<2 then return nil end
    if self.player:hasUsed("#fatechuyi_card") then return nil end
    
    local cards = self.player:getHandcards()
    cards=sgs.QList2Table(cards)
    
    local first, second
    self:sortByUseValue(cards,true)
    for _, card in ipairs(cards) do
        if card:getTypeId() ~= sgs.Card_Equip then
            if not first then first  = cards[1]:getEffectiveId()
            else second = cards[2]:getEffectiveId()
            end
        end
        if second then break end
    end
    
    if not second then return end
    local card_str = ("#fatechuyi_card:%d+%d:"):format(first, second)
    assert(card_str)
    return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#fatechuyi_card"]=function(card,use,self)
    self:sort(self.friends_noself, "defense")
    local lord = self.room:getLord()
    if self:isFriend(lord) and not sgs.isLordHealthy() and lord:isWounded() then
        use.card=card
        if use.to then use.to:append(lord) end
        return
    end	
    for _, friend in ipairs(self.friends_noself) do
        if friend:isWounded() and
            not (friend:hasSkill("longhun") and self:getAllPeachNum() > 0) and
            not (friend:hasSkill("hunzi") and friend:getMark("hunzi") == 0 and self:getAllPeachNum() > 1) then
            use.card=card
            if use.to then use.to:append(friend) end
            return
        end
    end
	if self:getOverflow()>0 then --����������������ʱʱѡ���������ٵ��Ǹ�
		self:sort(self.friends_noself, "handcard")
		for _, friend in ipairs(self.friends_noself) do 
      		if not (friend:hasSkill("kongcheng") and friend:isKongcheng()) then
        	    use.card=card
        	    if use.to then use.to:append(friend) end
        	    return
        	end
    	end
	end
end

sgs.ai_use_priority.fatechuyi_card = 4.2
sgs.ai_card_intention.fatechuyi_card = -200
sgs.dynamic_value.benefit.fatechuyi_card = true

sgs.ai_skill_invoke["fatexinengloseHP"] = function(self, data)
	local next_player = self.player:getNextAlive()
	if not self:isFriend(next_player) then return true end 
	return false
end


--Medea
--vs���֣������Һ�����֮�ⶼ����return���Ƿ�ʹ���ں����ж�

local fateyaoshu_skill={}
fateyaoshu_skill.name="fateyaoshu"
table.insert(sgs.ai_skills,fateyaoshu_skill)
fateyaoshu_skill.getTurnUseCard=function(self)
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit=false
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if not (fcard:isKindOf("Peach") or fcard:isKindOf("ExNihilo")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getSuitString() == first_card:getSuitString() and 
						not (scard:isKindOf("Peach") or scard:isKindOf("ExNihilo")) then -- and 
						second_card = scard
						second_found = true
						break
					end
				end
				if second_card then break end
			end
		end
	end
	if first_found and second_found then
		local card_str = "#fateyaoshu:.:"
		assert(card_str)
    	return sgs.Card_Parse(card_str)
	end
end

sgs.ai_skill_use_func["#fateyaoshu"]=function(card,use,self)
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit=false
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if not (fcard:isKindOf("Peach") or fcard:isKindOf("ExNihilo")) then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					if first_card ~= scard and scard:getSuitString() == first_card:getSuitString() and 
						not (scard:isKindOf("Peach") or scard:isKindOf("ExNihilo")) then -- and 
						second_card = scard
						second_found = true
						break
					end
				end
				if second_card then break end
			end
		end
	end
	if first_found and second_found then
		local first_suit, first_id = first_card:getSuit(), first_card:getEffectiveId()
		local second_suit, second_id = second_card:getSuit(), second_card:getEffectiveId()
		local card_str = ("#fateyaoshu:%d+%d:"):format(first_id, second_id)
		if first_suit == sgs.Card_Diamond then 
			use.card = sgs.Card_Parse(card_str)
			if use.to then use.to:append(self.player) end
			return
		elseif first_suit == sgs.Card_Spade then 
			local target
			for _,friend in ipairs(self.friends)do
				if not friend:faceUp() then
						target = friend
					break
				end
				if not target then
					if not self:toTurnOver(friend,0,"fateyaoshu") then
						target = friend
						break
					end
				end
			end
			self:sort(self.enemies)
			for _,enemy in ipairs(self.enemies)do
				if self:toTurnOver(enemy,0,"fateyaoshu") then
					target = enemy
					break
				end
			end
			if not target then
				for _,enemy in ipairs(self.enemies)do
					if self:toTurnOver(enemy,0,"fateyaoshu") and self:hasSkills(sgs.priority_skill,enemy) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _,enemy in ipairs(self.enemies)do
					if self:toTurnOver(enemy,0,"fateyaoshu") then
						target = enemy
						break
					end
				end
			end
			if target then
				use.card = sgs.Card_Parse(card_str)
				if use.to then use.to:append(target) end
				return
			end
		elseif first_suit == sgs.Card_Heart then 
			local arr1, arr2 = self:getWoundedFriend(false, true)
			local target = nil

			if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then
				target =
					arr1[1]
			end
			if target then
				use.card = sgs.Card_Parse(card_str)
				if use.to then use.to:append(target) end
				return 
			end
			if self:getOverflow() > 0 and #arr2 > 0 then
				for _, friend in ipairs(arr2) do
					if not friend:hasSkills("hunzi|longhun") then
						use.card = sgs.Card_Parse(card_str)
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		elseif first_suit == sgs.Card_Club  then 
			for _,enemy in sgs.list(self.enemies)do
				if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and self:canDamage(enemy,self.player,nil)
				then
					use.card = sgs.Card_Parse(card_str)
						if use.to then use.to:append(enemy) end
						return
				end
			end
		end
    	return
	end
end

sgs.ai_skill_use_func["#fateyaoshu1"]=function(card,use,self)
	--[[use.card=card
	if use.to then
		if self.player:isWounded() then 
			use.to:append(self.player)
			return 
		end
	end
	if not self.player:isWounded() then return end
	use.card=card
	if use.to then
		use.to:append(self.player)
	end
	return]]
	if self.player:isWounded() then 
        use.card=card
        if use.to then use.to:append(self.player) end
    end
end

sgs.ai_skill_use_func["#fateyaoshu2"]=function(card,use,self)
	self:sort(self.enemies, "chaofeng") -- ������ֵ�Ӵ�С����
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and enemy:faceUp() then
				use.card = card -- ���ܿ�
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
		for _, friend in ipairs(self.friends) do
        	if not friend:faceUp() then
				use.card = card -- ���ܿ�
				if use.to then
					use.to:append(friend)
				end
				return
			end
        end
end

--��ʱֻ�ܶ��Լ�ʹ��
sgs.ai_skill_use_func["#fateyaoshu3"]=function(card,use,self)
	self.room:writeToConsole("t4")
	use.card=card
	if use.to then
		use.to:append(self.player)
	end
end


sgs.ai_skill_use_func["#fateyaoshu4"]=function(card,use,self)
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
		for _, enemy in ipairs(self.enemies) do
			if self:getOverflow()<1 and enemy:getHp()>1 then return end --�������Ҫ���ƣ���ֻ�ڲ���ʱ����
			if self:objectiveLevel(enemy) > 3 then
				use.card = card -- ���ܿ�
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
end

sgs.ai_use_priority.fateyaoshucard1 = 3.2
sgs.ai_use_priority.fateyaoshucard2 = 10.2
sgs.ai_use_priority.fateyaoshucard3 = 3.1
sgs.ai_use_priority.fateyaoshucard4 = 3.0
sgs.ai_card_intention.fateyaoshucard1 = -150
sgs.ai_card_intention.fateyaoshucard3 = 70

fatefapao_damageeffect = function(self, to, nature, from)
	if to:hasSkill("fatefapao") and nature ~= sgs.DamageStruct_Normal then return false end
	return true
end
table.insert(sgs.ai_damage_effect, fatefapao_damageeffect)
sgs.ai_ajustdamage_to.fatefapao = function(self, from, to, card, nature)
	if nature ~= "N"
	then
		return -99
	end
end


--Gilgamesh ����٤��ʲ
local fateluanshe_vs_skill={}
fateluanshe_vs_skill.name="fateluanshe_vs"
table.insert(sgs.ai_skills,fateluanshe_vs_skill)
fateluanshe_vs_skill.getTurnUseCard=function(self,inclusive)
	if self.player:usedTimes("ArcheryAttack")>0 then return nil end
    local cards = self.player:getCards("h")
    cards=sgs.QList2Table(cards)
    local heart_card
    self:sortByUseValue(cards,true)
    for _,card in ipairs(cards) do
        if card:getSuit()== sgs.Card_Heart then
            heart_card = card
            break
        end
    end
	if heart_card then	
        local suit = heart_card:getSuitString()
        local number = heart_card:getNumberString()
        local card_id = heart_card:getEffectiveId()
        local card_str = ("archery_attack:fateluanshe_vs[%s:%s]=%d"):format(suit, number, card_id)
        local aa = sgs.Card_Parse(card_str)
        assert(aa)
        return aa
    end
end
--[[
sgs.ai_skill_playerchosen["@fatechuanxin2"] = function(self, targets)
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and enemy:getMark("@fog") < 1 and enemy:getMark("@fateshenghai") < 1
		and enemy:getMark("@fatesakura_mark") < 1 and not (enemy:hasSkill("yiji") or enemy:hasSkill("jieming") or enemy:hasSkill("fangzhu") or enemy:hasSkill("guixin") or enemy:hasSkill("fatewangzhe"))
	then
			return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and enemy:getMark("@fog") < 1 and enemy:getMark("@fateshenghai") < 1
		and enemy:getMark("@fatesakura_mark") < 1
		then
			return enemy
		end
	end
end
]]
sgs.ai_skill_cardask["@fatechuanxin1"] = function(self, data, pattern, target, target2)
	if #self.enemies == 0 then return "." end
	local card = sgs.QList2Table(self.player:getHandcards())
	if #card == 0 then return "." end
	if sgs.ai_skill_playerchosen.zero_card_as_slash(self, self.room:getOtherPlayers(self.player)) ~= nil then
		self:sortByKeepValue(card)
		return "$"..card[1]:getEffectiveId()
	end
	return "."
end
sgs.ai_skill_playerchosen["@fatechuanxin2"] = sgs.ai_skill_playerchosen.zero_card_as_slash
sgs.Gilgamesh_suit_value = 
{
	heart = 7
}

sgs.Gilgamesh_use_value = 
{
	ArcheryAttack = 10
}
sgs.double_slash_skill = sgs.double_slash_skill .. "|fateluanshe_vs"
sgs.double_slash_skill = sgs.double_slash_skill .. "|fatechuanxin_trs"



--Rider Medusa 
--����ɱ������1��ֱ������
--�������������Ҿ������е���/��������б����������Լ�2Ѫ���ϣ�ѡ��ǿϮ
--�����������к��������ڵ���2��ѡ����Ϯ
--��������һ��ɱ��ѡ������
--�������ɱ����������Χ���е��ˣ�ѡ����ʥ
--�������к���ѡ����Ϯ
--����ѡ������
sgs.ai_cardneed.fateguangbo = sgs.ai_cardneed.slash
sgs.ai_skill_invoke.fateguangbo = function(self, data)
	return true
end

sgs.ai_skill_choice.fateguangbo=function(self,choices)
	if self:getCardsNum("Slash") > 1 then return "fateguangbo3" end
	local hasweapon = false
	local weapon = self.player:getWeapon()
	
	if weapon then 
		hasweapon = true
	else 
		local cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if card:isKindOf("Weapon") then
				hasweapon = true
				break
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and enemy:getMark("@fog") < 1 and enemy:getMark("@fateshenghai") < 1
		and enemy:getMark("@fatesakura_mark") < 1 and self:canDamage(enemy,self.player,nil) then
			if (hasweapon or (enemy:getHp()==1 and self.player:getHp()>2)) and self.player:distanceTo(enemy) <=1 then
				return "fateguangbo2"
			end
		end
	end
	
	local cards = self.player:getCards("h")
	local blacknum = 0
	for _, card in sgs.qlist(cards) do
		if card:isBlack() then
			blacknum = blacknum + 1
		end
	end
	if blacknum > 1 then return "fateguangbo4" end
	
	if self:getCardsNum("Slash") > 0 then return "fateguangbo3" end
	
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and enemy:getMark("@fog") < 1 and enemy:getMark("@fateshenghai") < 1
		and enemy:getMark("@fatesakura_mark") < 1 and self:canDamage(enemy,self.player,nil) then
			if self.player:distanceTo(enemy) <= self.player:getAttackRange() then
					return "fateguangbo5"
			end
		end
	end
	
	local cards = self.player:getCards("he")
	for _, card in sgs.qlist(cards) do
		if card:isBlack() then
			return "fateguangbo4"
		end
	end
	return "fateguangbo3"
end

--ֱ�������ַ�������ʡ��~~~~~~~~~~~~~~~~~~~~~~~~~
sgs.ai_skill_invoke.fatetuji = function(self, data)
	return self:isWeak() or sgs.turncount > 1
end

--Irisviel fateshengqi
--[[sgs.ai_skill_cardask["fateshengqi"]=function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isRed() then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) then
			self:sortByUseValue(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "@GuidaoCard[" .. cards[1]:getSuitString() .. ":" .. cards[1]:getNumberString() .."]=" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(sgs.Sanguosha:getCard(card_id)) then
		local card = sgs.Sanguosha:getCard(card_id)
		return "@GuidaoCard[" .. card:getSuitString() .. ":" .. card:getNumberString() .. "]=" .. card_id
	end
	
	return "."
end]]
sgs.wizard_skill = sgs.wizard_skill .. "|fateshengqi"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|fateshengqi"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|fateshengqi"

function sgs.ai_cardneed.fateshengqi(to,card,self)
	for _,player in sgs.qlist(self.room:getAllPlayers())do
		if self:getFinalRetrial(to)==1 then
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit()==sgs.Card_Heart and self:hasSuit("heart",true,to)
			end
		end
	end
end


sgs.ai_skill_cardask["@fateshengqi-card"]=function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:prepend(sgs.Sanguosha:getCard(id))
		end
	end
	
	if all_cards:isEmpty() then return "." end

	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isRed() and not card:hasFlag("using") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() and self.player:getArmor():isRed() then return "$" .. self.player:getArmor():getEffectiveId() end
			self:sortByUseValue(cards, true)
			if self:getUseValue(judge.card) > self:getUseValue(cards[1]) then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) or self:getUseValue(judge.card) > self:getUseValue(sgs.Sanguosha:getCard(card_id)) then
		local card = sgs.Sanguosha:getCard(card_id)
		return "$" .. card_id
	end

	return "."
end


sgs.ai_skill_invoke["fatehuyoubad"] = function(self, data)
--���ж���ʱ�����ѷ��Ĳ�˳������;���ں���״̬ʱ��������������
--	local effect = data:toCardEffect()
	--local from=data:toCardEffect().from
--	local card = effect.card
--	local cur = self.room:getCurrent() --����Ѳ��ԣ�û������
--	local judges = self:getJudgingArea() --���� QList<const Card *>
	--if self:isFriend(cur) and ((effect.card:isKindOf("Snatch") or effect.card:isKindOf("Dismantlement")) and judges:isEmpty()==false) then return false end
--	if self:isFriend(cur) and (effect.card:isKindOf("Snatch") or effect.card:isKindOf("Dismantlement")) then return false end
--	if not judges:isEmpty() then return false end
--	if self:isChained() and effect.card:isKindOf("IronChain") then return false end
--	if self:isFriend(cur) then return true end
--	if (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) then return true end --����д���
	return true
end

sgs.ai_skill_playerchosen["#fatehuyoubad_target"] = function(self, targets) 
	local choices = {}
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) then-- and (self.player:distanceTo(target) <= self.player:getAttackRange()) then
			table.insert(choices, target)
		end
	end
	if #choices == 0 then
		for _, target in sgs.qlist(targets) do
			if not self:isFriend(target) then
				table.insert(choices, target)
			end
		end
		self:sort(choices, "hp", true) --������䣬��ֱ�Ӹ�����(targets:at(0))
		return choices[1] --targets:at(0)
	end
	self:sort(choices, "hp")
	return choices[1]
end

sgs.ai_skill_invoke["fatehuyougood"] = function(self, data)
	for _, friend in ipairs(self.friends_noself) do  --�Բۣ�������isWounded()��Ȼ���У�mlgb
        if friend:getLostHp() > 0 and self.player:getLostHp()==0 then -- and (self.player:distanceTo(friend) <= self.player:getAttackRange()) 
            return true
        end
    end
	return false
end

sgs.ai_skill_playerchosen["#fatehuyougood_target"] = function(self, targets)
	local choices = {}
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) then
			table.insert(choices, target)
		end
	end
	self:sort(choices, "hp")
	return choices[1]
end

sgs.ai_skill_playerchosen["fatehuyou"] = function(self, targets) 
	local targets = sgs.QList2Table(targets)
	local effect = self.room:getTag("fatehuyou"):toCardEffect()
	local card = effect.card
	local target
	if card:isKindOf("AmazingGrace") or card:isKindOf("ExNihilo") or card:isKindOf("EXCard_YJJG") then
		for _, friend in ipairs(self.friends) do
			if friend:hasSkills(sgs.cardneed_skill) and not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and self:hasTrickEffective(card, effect.from, friend) 
			and self.player:getHandcardNum() > 	friend:getHandcardNum()	and table.contains(targets, friend)	then
				return friend
			end
		end
		return nil
	elseif  card:isKindOf("EXCard_TJBZ") then
		return nil
	elseif card:isKindOf("EXCard_YYDL")  then
		for _, friend in ipairs(self.friends) do
			if (self:hasSkills(sgs.lose_equip_skill, friend) or self:needToThrowArmor(friend)) and not hasManjuanEffect(friend) and self:hasTrickEffective(card, effect.from, friend) and table.contains(targets, friend) 	then
				return friend
			end
		end
		return nil
	elseif card:isKindOf("GodSalvation") then
		local lord = self.room:getLord()
		if self:isWeak(lord) and self.player:getRole() == "loyalist" and self:hasTrickEffective(card, effect.from, lord)  and table.contains(targets, lord) then
			return lord
		end
		self:sort(self.friends, "hp")
		if self:isWeak() and self:hasTrickEffective(card, effect.from, self.player)  then
			return nil
		else
			for _, target in ipairs(self.friends) do
				if self:hasTrickEffective(card, effect.from, target) and target:getHp() < getBestHp(target)   and table.contains(targets, target) then
					return target
				end
			end
		end
		return nil
	elseif  card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("EXCard_WWJZ") then
		local nature = sgs.DamageStruct_Normal
		if card:isKindOf("FireAttack") then
			nature = sgs.DamageStruct_Fire
		end
		self:sort(self.enemies, "hp")
		self:sort(self.friends, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and self:canDamage(enemy,effect.from,nil) and self:damageIsEffective(enemy, nature) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and self:canDamage(enemy,effect.from,nil) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
		for _, friend in ipairs(self.friends) do
			if ((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, effect.from, card,false)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, effect.from, friend) or not self:damageIsEffective(friend, nature)  and  table.contains(targets, friend) then
				return friend
			end
		end
		return targets[1]
	elseif  card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
		local nature = sgs.DamageStruct_Normal
		if card:isKindOf("FireAttack") then
			nature = sgs.DamageStruct_Fire
		end
		self:sort(self.enemies, "hp")
		self:sort(self.friends, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nature) and self:canDamage(enemy,effect.from,nil) and not enemy:hasArmorEffect("vine") and  table.contains(targets, enemy) 	then
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy)  and not enemy:hasArmorEffect("vine") and self:canDamage(enemy,effect.from,nil)	and  table.contains(targets, enemy) then
				return enemy
			end
		end
		for _, friend in ipairs(self.friends) do
			if (((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, effect.from, card,false)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, effect.from, friend) or not self:damageIsEffective(friend, nature) or  friend:hasArmorEffect("vine")) and  table.contains(targets, friend) then
				return friend
			end
		end
		return targets[1]
	elseif card:isKindOf("Collateral") then
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getWeapon()) and self:hasTrickEffective(card, effect.from, enemy) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif card:isKindOf("Dismantlement")  or card:isKindOf("Snatch") then
		if self:isFriend(effect.from) and (self.player:getJudgingArea():length() > 0 or self:hasSkills(sgs.lose_equip_skill, self.player)) and self:hasTrickEffective(card, effect.from, self.player) then
			return nil
		end
			if card:isKindOf("Dismantlement") then
				self:sort(self.enemies, "handcard")
				for _, enemy in ipairs(self.enemies) do
					if self:doDisCard(enemy) and self:hasTrickEffective(card, effect.from, enemy) and  table.contains(targets, enemy)	then
						return enemy
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if  self:hasTrickEffective(card, effect.from, enemy) and  table.contains(targets, enemy)	then
						return enemy
					end
				end
			end
	elseif card:isKindOf("GodFlower") or card:isKindOf("Snatch") then
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if self:isEnemy(effect.from) and self:hasTrickEffective(card, effect.from, enemy) and (enemy:getJudgingArea():length() < 1 or not self:hasSkills(sgs.lose_equip_skill, enemy)) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif card:isKindOf("IronChain") then
		for _, friend in ipairs(self.friends) do
			if self:hasTrickEffective(card, effect.from, friend) and friend:isChained()  and  table.contains(targets, friend) then
				return friend
			end
		end
		
		for _, enemy in ipairs(self.enemies) do
			if  self:hasTrickEffective(card, effect.from, enemy)  and  table.contains(targets, enemy) and not enemy:isChained()	then
				return enemy
			end
		end
	end
	
	return nil
end

sgs.ai_target_revises.fatehuyou = function(to,card,self)
	if self:isFriend(to,self.player) then return false end
	if #self.friends_noself == 0 then return false end
	for _,friend in ipairs(self:getFriends(self.player, true))do
		if to:canSlash(friend,card) and self:slashIsEffective(card,friend,self.player) then return card:isNDTrick() and self.player~=to end
	end
	return card:isNDTrick() and self.player~=to
end

sgs.Irisviel_suit_value = 
{
	heart = 3.9,
	diamond = 3.8
}

--Tokiomi
--[[
sgs.ai_skill_invoke.fatejiejie = function(self, data)
	return true
end
]]
sgs.ai_skill_invoke.fatejiejie = function(self, data)
	local effect = data:toCardEffect()
	if effect.card and effect.card:hasFlag("NosJiefanUsed") then return false  end

	if not effect.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,effect.from)
		or effect.card:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player,effect.card,effect.from)
		or self:needToLoseHp(self.player,effect.from,effect.card) and self:ajustDamage(effect.from,self.player,1,effect.card)==1 then return false end
	if self:needToLoseHp(self.player, effect.from,effect.card, true, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end
	
	return true
end

local fatemoshu_skill={}
fatemoshu_skill.name="fatemoshu_vs"
table.insert(sgs.ai_skills,fatemoshu_skill)
fatemoshu_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasUsed("#fatemoshu_card") then return nil end
    local cards = self.player:getHandcards()
    cards=sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	local card_str = ("#fatemoshu_card:%d:"):format(cards[1]:getId())
    return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#fatemoshu_card"]=function(card,use,self)
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and not enemy:hasSkill("tiandu") and self:doDisCard(enemy, "he") then
			use.card = sgs.Card_Parse("#fatemoshu_card:" .. card:getEffectiveId()..":")  -- �����ӿ��ļ��ܿ�
			if use.to then
				use.to:append(enemy)
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:getOverflow()>0 then
			if self:doDisCard(enemy, "he") then
				use.card = sgs.Card_Parse("#fatemoshu_card:" .. card:getEffectiveId()..":")  -- �����ӿ��ļ��ܿ�
				if use.to then
					use.to:append(enemy)
					return
				end
			end
		end
	end
end

sgs.ai_use_value["fatemoshu_card"] = 7.5
sgs.ai_use_priority["fatemoshu_card"] = 4
sgs.ai_card_intention["fatemoshu_card"] = 70

--Alexander
local fatejuntuan_skill={}
fatejuntuan_skill.name="fatejuntuan_vs"
table.insert(sgs.ai_skills,fatejuntuan_skill)
fatejuntuan_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasUsed("#fatejuntuan_card") then return nil end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if c:isBlack() then 
	   		return sgs.Card_Parse("#fatejuntuan_card:" .. c:getEffectiveId()..":")
	   	end
	end
end

sgs.ai_skill_use_func["#fatejuntuan_card"]=function(card,use,self)
	local first
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal,self.player) and self.player:distanceTo(enemy) < 2
		then
			use.card = sgs.Card_Parse("#fatejuntuan_card:" .. card:getEffectiveId()..":")  -- �����ӿ��ļ��ܿ�
			if use.to then
				use.to:append(enemy)
				first=enemy
				break
			end
		end
	end
	if first then 
		for _, enemy2 in ipairs(self.enemies) do
			if self:objectiveLevel(enemy2) > 3 and not self:cantbeHurt(enemy2) and self:canDamage(enemy2,self.player,nil)  and self:damageIsEffective(enemy2, sgs.DamageStruct_Normal,self.player) and self.player:distanceTo(enemy2) < 2 and (enemy2:getSeat()~=first:getSeat())
			then
				use.to:append(enemy2)
				return
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal,self.player) and self.player:distanceTo(enemy) < 2 then
				use.card = sgs.Card_Parse("#fatejuntuan_card:" .. card:getEffectiveId()..":")
				if use.to then
					use.to:append(enemy)
					first=enemy
					break
				end
			end
		end
	end
end

sgs.ai_use_value["fatejuntuan_card"] = 8.5
sgs.ai_use_priority["fatejuntuan_card"] = 3
sgs.ai_card_intention["fatejuntuan_card"] = 70

function sgs.ai_cardneed.fatejuntuan_vs(to, card, self)
	return card:isBlack() and to:getCards("he"):length() < 4
end


sgs.ai_skill_invoke.fatehuwei = function(self, data)
	if #self.friends_noself > 0 then
		return true
	end
	return false
end


sgs.ai_skill_playerchosen["@fatehuwei"] = function(self, targets)
	local choices = {}
	local card = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, -1)
	card:deleteLater()
	for _, target in sgs.qlist(targets) do
		local armor = target:getArmor()
		if self:isFriend(target)  and self:hasTrickEffective(card, target, self.player)
		and not (armor and armor:isKindOf("Vine")) --�ټ�
		then
			table.insert(choices, target)
		end
	end
	self:sort(choices, "hp")
	return choices[1]
end

sgs.ai_target_revises.fatehuwei = function(to, card)
	if card:isKindOf("SavageAssault")then
		return true
	end
end


--Diarmuid
sgs.ai_skill_invoke.fatepomo = function(self, data)
	return true
end

sgs.ai_skill_playerchosen["@fatepomo"] = function(self, targets)
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("beige") and not enemy:isNude() then
			return enemy
		end
	end
	--�������1���ڵģ�����
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("fateduoluo") and enemy:distanceTo(self.player)< 2 then
			return enemy
		end
	end
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
	--fate�����ߣ�ħ�����ڼ����෵�����ӣ���磬+��ų
	--�����棺�żƣ����ۣ���������������������ң����أ��ճǣ����������󣬿��ƣ����ԣ����룬���㣬�׻����ƻ󣬷����Ļ��������֣����ģ���Ӱ�����������꣬�̽�
	--�����з��ߵ�
	--��ֻ��1Ѫ������ϣ�
	--fate��ʥ��������
	--��׼�棺���ᣬ��꣬׷�䣬���ȣ�����, �ϳ�
	for _, enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) <= self.player:getAttackRange() and
		(enemy:hasSkill("fatewangzhe") or enemy:hasSkill("fatemoli") or enemy:hasSkill("fateheijian") or enemy:hasSkill("fateyanfan_vs") or enemy:hasSkill("fatehuyou") or enemy:hasSkill("fatejiejie") or enemy:hasSkill("fateqienuo") 
		or enemy:hasSkill("yiji") or enemy:hasSkill("jianxiong") or enemy:hasSkill("fankui") or enemy:hasSkill("qingguo") or enemy:hasSkill("ganglie")
		or enemy:hasSkill("yizhong") or enemy:hasSkill("kongcheng") or enemy:hasSkill("longdan") or enemy:hasSkill("bazhen") or enemy:hasSkill("kanpo")
		or enemy:hasSkill("wuyan") or enemy:hasSkill("liuli") or enemy:hasSkill("tianxiang") or enemy:hasSkill("leiji") or enemy:hasSkill("guhuo")
		or enemy:hasSkill("fangzhu") or enemy:hasSkill("weimu") or enemy:hasSkill("tuntian") or enemy:hasSkill("xiangle") 
		or enemy:hasSkill("fengying") or enemy:hasSkill("guixin") or enemy:hasSkill("juejing") or enemy:hasSkill("longhun") or enemy:hasSkill("renjie")
		or ((enemy:hasSkill("fateshenghai") or enemy:hasSkill("fateshilian") or enemy:hasSkill("huilei") or enemy:hasSkill("zhuiyi") or enemy:hasSkill("jijiu")
		or enemy:hasSkill("buqu") or enemy:hasSkill("duanchang")) and enemy:getHp()<2))
		or enemy:getArmor()~= nil
		then
			return enemy
		end
	end
	
	-- ����ȫ��ģ�
	--fate�����ǣ�ʥ��
	--�����棺���ƣ����ţ�����������
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("fatejiezhi") or enemy:hasSkill("fateshengqi") or enemy:hasSkill("kanpo") or enemy:hasSkill("guicai") or enemy:hasSkill("guidao") 
		or enemy:hasSkill("jijiu") 
		then
			return enemy
		end
	end
	
	
	--����ȫ��ģ�
	--fate�����ߣ�����
	--�����棺�żƣ����������𣬸�¶������
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("fatewangzhe") or enemy:hasSkill("fatehuyou") or enemy:hasSkill("yiji") or enemy:hasSkill("jieming") or enemy:hasSkill("fangzhu") 
		or enemy:hasSkill("ganlu") or enemy:hasSkill("guixin")
		then
			return enemy
		end
	end

	--����ȫ��ģ�
	--fate����ڣ���������ڼ�
	--�����棺���󣬼��ۣ����ף��Ļ������
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("fatejianzhong") or enemy:hasSkill("fatehuwei") or enemy:hasSkill("fateheijian") or enemy:hasSkill("juxiang") or enemy:hasSkill("jianxiong") 
		or enemy:hasSkill("huoshou") or enemy:hasSkill("weimu") or enemy:hasSkill("tuntian") 
		then
			return enemy
		end
	end
	
	--���򹥻���Χ�ڵģ�
	--fate�����ǣ����ۣ�����
	--��׼�棺��ʥ���ɼ�����ӣ��ǳ٣�ǫѷ���񱩣�����
	for _, enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) <= self.player:getAttackRange() and
		(enemy:hasSkill("fatejizhi") or enemy:hasSkill("fatefapao") or enemy:hasSkill("fatexianshen") or enemy:hasSkill("wusheng") or enemy:hasSkill("xiaoji") 
		or enemy:hasSkill("yicong") or enemy:hasSkill("zhichi") or enemy:hasSkill("qianxun") or enemy:hasSkill("kuangbao") or enemy:hasSkill("huashen"))
		then
			return enemy
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("fatewangzhe") or enemy:hasSkill("fatemoli") or enemy:hasSkill("fateheijian") or enemy:hasSkill("fateyanfan") or enemy:hasSkill("fatehuyou") or enemy:hasSkill("fatejiejie")
		or enemy:hasSkill("yiji") or enemy:hasSkill("jianxiong") or enemy:hasSkill("fankui") or enemy:hasSkill("qingguo") or enemy:hasSkill("ganglie")
		or enemy:hasSkill("yizhong") or enemy:hasSkill("kongcheng") or enemy:hasSkill("longdan") or enemy:hasSkill("bazhen") or enemy:hasSkill("kanpo")
		or enemy:hasSkill("wuyan") or enemy:hasSkill("liuli") or enemy:hasSkill("tianxiang") or enemy:hasSkill("leiji") or enemy:hasSkill("guhuo")
		or enemy:hasSkill("fangzhu") or enemy:hasSkill("weimu") or enemy:hasSkill("tuntian") or enemy:hasSkill("xiangle") 
		or enemy:hasSkill("fengying") or enemy:hasSkill("guixin") or enemy:hasSkill("juejing") or enemy:hasSkill("longhun") or enemy:hasSkill("renjie")
		or ((enemy:hasSkill("fateshenghai") or enemy:hasSkill("fateshilian") or enemy:hasSkill("huilei") or enemy:hasSkill("zhuiyi") or enemy:hasSkill("jijiu")
		or enemy:hasSkill("buqu") or enemy:hasSkill("duanchang")) and enemy:getHp()==1)
		then
			return enemy
		end
	end
	
	for _, enemy in ipairs(self.enemies) do
		return enemy
	end
	
end

sgs.ai_cardneed.fatebimie = sgs.ai_cardneed.slash

--Lancer
sgs.ai_skill_invoke.fatetuci = function(self, data)
	local use = data:toCardUse()
	if self.player:getHandcardNum()<1 then return nil end
    for _, target in sgs.qlist(use.to) do
		if self:isFriend(target) then return false end
		if self:cantDamageMore(self.player,target) then return false end
    	return true
	end
	return false
end

sgs.ai_ajustdamage_from.fatetuci = function(self,from,to,card,nature)
	if card and card:isKindOf("Slash") and from:getHandcardNum()>0 and not beFriend(to,from)
	then return 1 end
end

--[[
local fatesiji_skill={}
fatesiji_skill.name="fatesiji_vs"
table.insert(sgs.ai_skills,fatesiji_skill)
fatesiji_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasUsed("#fatesiji_card") then return nil end
	if self.player:getLostHp()<2 then return nil end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") then
			return sgs.Card_Parse("#fatesiji_card:" .. card:getEffectiveId()..":")
		end
	end
--    local weapon = self.player:getWeapon()
--	if weapon then
		--local card_str = ("#fatesiji_card:%d:"):format(weapon:getId())
		--return sgs.Card_Parse(card_str)
	--end
end


local fatesiji_skill={}
fatesiji_skill.name="fatesiji_vs"
table.insert(sgs.ai_skills,fatesiji_skill)
fatesiji_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasUsed("#fatesiji_card") then return nil end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
--	for _, c in ipairs(cards) do
	--	if c:isBlack() then 
	--   		return sgs.Card_Parse("#fatesiji_card:" .. cards[1]:getEffectiveId()..":")
--	   	end
--	end
end

sgs.ai_skill_use_func["#fatesiji_card"]=function(card,use,self)
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
	for _, enemy in ipairs(self.enemies) do
		local armor = enemy:getArmor()
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and enemy:getMark("@fog") < 1 and self:distanceTo(enemy) < 3 
		and not (armor and armor:isKindOf("Vine")) --�ټ�
		then
			use.card = sgs.Card_Parse("#fatesiji_card:" .. card:getEffectiveId()..":")  -- �����ӿ��ļ��ܿ�
			if use.to then
				use.to:append(enemy)
				return
			end
		end
	end
end
]]
sgs.ai_skill_cardask["@fatetuci"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		return "$" .. card:getEffectiveId()
	end
	return "."
end

sgs.hit_skill = sgs.hit_skill .. "|fatetuci"

local fatesiji_skill={}
fatesiji_skill.name="fatesiji_vs"
table.insert(sgs.ai_skills,fatesiji_skill)
fatesiji_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasUsed("#fatesiji_card") then return nil end
	if self.player:getLostHp()<2 then return nil end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if c:isKindOf("Weapon") then
	   		return sgs.Card_Parse("#fatesiji_card:" .. c:getEffectiveId()..":")
	   	end
	end
end

sgs.ai_skill_use_func["#fatesiji_card"]=function(card,use,self)
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy)  and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and self.player:distanceTo(enemy) < 3 then
			use.card = sgs.Card_Parse("#fatesiji_card:" .. card:getEffectiveId()..":")  -- �����ӿ��ļ��ܿ�
			if use.to then
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_use_value["fatesiji_card"] = 3.5
sgs.ai_use_priority["fatesiji_card"] = 2.5
sgs.ai_card_intention["fatesiji_card"] = 100

sgs.double_slash_skill = sgs.double_slash_skill .. "|fatesiji_vs"
sgs.ai_cardneed.fatesiji_vs = sgs.ai_cardneed.weapon

--shinji
sgs.ai_view_as.fateqienuo = function(card, player, card_place)
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getEffectiveId()
	if card:isKindOf("BasicCard") then
        return ("jink:fateqienuo[%s:%s]=%d"):format(suit, number, card_id)
    end
end

sgs.ai_skill_invoke.fateqiangtui = function(self, data)
	local room = self.room
	local players = room:getOtherPlayers(self.player)
	for _, target in sgs.qlist(players) do
		if self:isEnemy(target) and not target:isKongcheng() and (target:getSeat()==(self.player:getNextAlive()):getSeat() or self.player:getSeat()==(target:getNextAlive()):getSeat()) then
			return true
		end
	end
	for _, target in sgs.qlist(players) do
		if self.player:isWounded() and not target:isKongcheng() and target:isFemale()
		and (target:getSeat()==(self.player:getNextAlive()):getSeat() or self.player:getSeat()==(target:getNextAlive()):getSeat())
		then
			return true
		end
	end
    return false
end

sgs.ai_skill_playerchosen.fateqiangtui = function(self, targets) 
	local choices = {}
	if self.player:getLostHp() > 0 then
		for _, target in sgs.qlist(targets) do
			if self:isEnemy(target) and not target:isKongcheng() and target:isFemale() then
				table.insert(choices, target)
			end
		end
		if #choices ~= 0 then
			self:sort(choices, "hp")
			return choices[1]
		else
			for _, target in sgs.qlist(targets) do
				if not target:isKongcheng() and target:isFemale() then
					table.insert(choices, target)
				end
			end
			self:sort(choices, "hp", true)
			return choices[1]
		end
	end
	
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) and not target:isKongcheng() then
			table.insert(choices, target)
		end
	end
	
	self:sort(choices, "hp")
	return choices[1]
end

sgs.drawpeach_skill = sgs.drawpeach_skill .. "|fateqiangtui"

--Kariya
local fatechongshu_skill={}
fatechongshu_skill.name="fatechongshu"
table.insert(sgs.ai_skills,fatechongshu_skill)
fatechongshu_skill.getTurnUseCard=function(self)
    if self.player:getHandcardNum()<1 then return nil end
    if self.player:hasUsed("#fatechongshu_card") then return nil end
    local cards = self.player:getHandcards()
    cards=sgs.QList2Table(cards)
    self:sortByKeepValue(cards)
	local card_str = ("#fatechongshu_card:%d:"):format(cards[1]:getId())
    return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#fatechongshu_card"]=function(card,use,self)
	self:sort(self.enemies, "hp") -- ������ֵ��С��������
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp()<2 and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and enemy:getHandcardNum()<2
		then
			use.card = sgs.Card_Parse("#fatechongshu_card:" .. card:getEffectiveId()..":")  -- �����ӿ��ļ��ܿ�
			if use.to then
				use.to:append(enemy)
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and enemy:getHandcardNum()<2) or (enemy:getHandcardNum()>1 and self:doDisCard(enemy, "h"))
		then
			use.card = sgs.Card_Parse("#fatechongshu_card:" .. card:getEffectiveId()..":")  -- �����ӿ��ļ��ܿ�
			if use.to then
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_use_value["fatechongshu_card"] = 7.5
sgs.ai_use_priority["fatechongshu_card"] = 4
sgs.ai_card_intention["fatechongshu_card"] = 100

sgs.ai_skill_invoke.fatechongshu = function(self, data)
    return true
end

sgs.ai_skill_invoke.fatejiushu = function(self, data)
	if self.player:getMark("@fatejiushu_mark")==0 then return false end
	if self.player:getRole()=="renegade"  then return false end
    return (#self.friends_noself > 0)
end

--һ������ѡ���ڼ�
--����ѡ��һѪ���ϵĹ��Ρ����򡢲�ا
--���Ȼ�٢�����㣬�ݣ�ӣ(δ����ʱ)
--�����ʦ
--�������ã�������С����
--�����ҳ�ѡ������
--����ѡ��һѪ����
--���򰴳�������ѡ�����
sgs.ai_skill_playerchosen["@fatejiushu"]= function(self, targets) 
	if self.player:getRole() == "loyalist" and self.room:getLord() then
		return self.room:getLord()
	end
	self:sort(self.friends_noself, "chaofeng")
	for _, friend in ipairs(self.friends_noself) do
        if (friend:hasSkill("qingnang") or friend:hasSkill("jieyin") or friend:hasSkill("fateqingxing") or friend:hasSkill("fatechuyi_vs")) and friend:getRole()~="renegade" then
            return friend
        end
    end
	for _, friend in ipairs(self.friends_noself) do
        if friend:hasSkill("dimeng") and friend:hasSkill("haoshi") and friend:getRole()~="renegade" then
            return friend
        end
    end
	for _, friend in ipairs(self.friends_noself) do
        if (friend:hasSkill("fatejiezhi") or friend:hasSkill("lijian") or friend:hasSkill("fatezonghe")) and friend:getRole()~="renegade" then
            return friend
        end
    end
	
    local lord = self.room:getLord()
    if self:isFriend(lord) and not self.player:isLord() then --��Ϊ�ڼ鲻�ᷢ���˼��ܡ���
        return lord
    end
	
    for _, friend in ipairs(self.friends_noself) do
        if friend:getHp()<2 and friend:getRole()~="renegade" then
			return friend
        end
    end
	for _, friend in ipairs(self.friends_noself) do
        if friend:getRole()~="renegade" and not ((friend:hasSkill("yiji") or friend:hasSkill("jieming") or friend:hasSkill("fangzhu") or friend:hasSkill("guixin")) and friend:getHp()>1) then
			return friend
        end
    end
end

sgs.ai_playerchosen_intention["@fatejiushu"] = -800

sgs.ai_ajustdamage_to["@fatesakura_mark"] = function(self, from, to, card, nature)
	if nature ~= "T" then
		return -99
	end
end