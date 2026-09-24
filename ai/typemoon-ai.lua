sgs.ai_skill_invoke["yinyang"] = function(self, data)
	local counter
	if self.player:isFemale() then
		counter = self.player:getPile("maleshiki"):length()
	else
		counter = self.player:getPile("femaleshiki"):length()
	end
	if self.player:hasSkills("lianying|noslianying|sijian") or (self.player:hasSkills("shangshi|nosshangshi") and self.player:isWounded()) then
		return true
	end
	if self.player:containsTrick("indulgence") then
		if counter <= self.player:getHandcardNum() then return true else return false end
	end
	if self.player:isFemale() then
		if self.player:getHandcardNum() > math.max(counter, 4) then
			return true
		end
	elseif counter > math.max(self.player:getHandcardNum(), 4) then
		return false
	end
	if counter >= self.player:getHandcardNum() then return true else return false end
end

Jiuzi_skill = {}
Jiuzi_skill.name = "Jiuzi"
table.insert(sgs.ai_skills, Jiuzi_skill)
Jiuzi_skill.getTurnUseCard = function(self)
	local player = self.player
	local used = self.player:usedTimes("#JiuziCard")
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	if player:getMark("@jianding") > 0 and used < player:getHp() then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if player:hasSkill("sinzhisi") and player:canSlash(enemy, slash, false) and enemy:getMark("@sharengui") == 1 then
				local parse = sgs.Card_Parse("#JiuziCard:.:")
				assert(parse ~= nil)
				return parse
			elseif player:getMark("@jianding") > 3 and used < 3 and not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				if (player:hasSkill("CixiongSkill") and enemy:isMale() ~= player:isMale()) or (player:hasSkill("HuoshanSkill") and enemy:hasArmorEffect("vine")) or (player:hasSkill("BaojiSkill") and enemy:isKongcheng()) or player:hasSkill("moukui") then
					local parse = sgs.Card_Parse("#JiuziCard:.:")
					assert(parse ~= nil)
					return parse
				end
				if used < 1 or self:isWeak(enemy) then
					local parse = sgs.Card_Parse("#JiuziCard:.:")
					assert(parse ~= nil)
					return parse
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_use_func["#JiuziCard"] = function(card, use, self)
	local enemyfound = false
	self:sort(self.enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if not self:slashProhibit(card, enemy) and self:slashIsEffective(card, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and enemy:getMark("@sharengui") == 1 then
			use.card = card
			if use.to then
				use.to:append(enemy)
				enemyfound = true
			end
			return
		end
	end
	if enemyfound == false then
		for _, enemy in ipairs(self.enemies) do
			if not self:slashProhibit(card, enemy) and self:slashIsEffective(card, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				use.card = card
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
end


sgs.ai_need_damaged["jialan"] = function(self, attacker, player)
	if player:hasSkill("jialan") and player:getMark("jialan") == 0 and not player:hasSkill("chanyuan")
		and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() > 0 or (player:getHp() == 1 and (player:faceUp() or player:hasSkill("guixin")))) then
		return true
	end
	return false
end

function sgs.ai_cardneed.sinzhisi(to, card, self)
	for _, enemy in ipairs(self.enemies) do
		if card:isKindOf("Slash") and to:canSlash(enemy, nil, true) and self:slashIsEffective(card, enemy)
			and not (enemy:hasSkill("kongcheng") and enemy:isKongcheng())
			and self:isGoodTarget(enemy, self.enemies, slash) and not self:slashProhibit(card, enemy) and enemy:getMark("@sharengui") == 1 then
			return getKnownCard(to, self.player, "Slash", true) == 0
		end
	end
end

sgs.ai_skill_invoke["Tohnozhisi"] = function(self, data)
	self:sort(self.enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	if self:getCardsNum("Slash") > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not self:slashProhibit(slash, enemy) and self.player:canSlash(enemy, slash, false) and self:isGoodTarget(enemy, self.enemies, nil)
				and self.player:distanceTo(enemy) <= self.player:getAttackRange() and not self:isWeak(self.player) then
				return true
			end
		end
	end
	return false
end

jisha_skill = {}
jisha_skill.name = "jisha"
table.insert(sgs.ai_skills, jisha_skill)
jisha_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#jishaCard") then
		local parse = sgs.Card_Parse("#jishaCard:.:")
		assert(parse ~= nil)
		return parse
	end
	return nil
end

sgs.ai_skill_use_func["#jishaCard"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	if self:getCardsNum("Slash") ~= 0 then
		for _, enemy in ipairs(self.enemies) do
			if not self:slashProhibit(card, enemy) and self:slashIsEffective(card, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				use.card = card
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not self:slashProhibit(card, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
				use.card = card
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	else
		for _, friend in ipairs(self.friends) do
			if friend:hasSkill("tiandu") then
				use.card = card
				if use.to then
					use.to:append(friend)
				end
				return
			end
		end
		self:sort(self.friends, "handcard")
		for _, friend in ipairs(self.friends) do
			use.card = card
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end
end

sgs.ai_card_intention.jishaCard = 100
sgs.ai_use_value.jishaCard = 10
sgs.ai_use_priority.jishaCard = 10

sgs.ai_skill_invoke["#jishamod"] = function(self, data)
	return true
end
