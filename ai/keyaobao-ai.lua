--change

sgs.ai_skill_invoke.yaochangetupo = function(self, data)
	--[[local num = math.random(0,1)
	if (num == 0) then
	    return true
	else
		return false
	end]]
	return false
end

--张角

sgs.ai_skill_invoke.keyaotuzhong = function(self, data)
	if self:isWeak() then return true end
	if self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) > 2 then
		return false
	end
	return sgs.ai_skill_playerchosen.keyaotuzhong(self) ~= nil
end

sgs.ai_skill_playerchosen.keyaotuzhong = function(self, targets)
	--targets = sgs.QList2Table(targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil
	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then
		target =
			arr1[1]
	end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.keyaotuzhong = function(self, from, to)
	sgs.updateIntention(from, to, -50)
end


local keyaotaiping_skill = {}
keyaotaiping_skill.name = "keyaotaiping"
table.insert(sgs.ai_skills, keyaotaiping_skill)
keyaotaiping_skill.getTurnUseCard = function(self)
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length() >= 2 and not self.player:hasFlag("useyaotaiping") then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)

		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
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
			if not fvalueCard and fcard:getSuit() == sgs.Card_Heart then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then
						local card_str = ("archery_attack:keyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0,
							first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = self:aiUseCard(archeryattack, dummy())
						if dummy_use.card then
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

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("archery_attack:keyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length() >= 2 and not self.player:hasFlag("useyaotaiping") then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)

		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end

		self:sortByKeepValue(cards)


		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("SavageAssault", fcard, self.player))
			if not fvalueCard and fcard:getSuit() == sgs.Card_Spade then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("SavageAssault", scard, self.player))
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then
						local card_str = ("savage_assault:keyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0,
							first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = self:aiUseCard(archeryattack, dummy())
						if dummy_use.card then
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
	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("savage_assault:keyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length() >= 2 and not self.player:hasFlag("useyaotaiping") then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)

		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end

		self:sortByKeepValue(cards)


		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("GodSalvation", fcard, self.player))
			if not fvalueCard and fcard:getSuit() == sgs.Card_Diamond then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("GodSalvation", scard, self.player))
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then
						local card_str = ("god_salvation:keyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0,
							first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = self:aiUseCard(archeryattack, dummy())
						if dummy_use.card then
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
	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("god_salvation:keyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end

	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length() >= 2 and not self.player:hasFlag("useyaotaiping") then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)

		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end

		self:sortByKeepValue(cards)

		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("AmazingGrace", fcard, self.player))
			if not fvalueCard and fcard:getSuit() == sgs.Card_Club then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("AmazingGrace", scard, self.player))
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then
						local card_str = ("amazing_grace:keyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0,
							first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = self:aiUseCard(archeryattack, dummy())
						if dummy_use.card then
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
	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("amazing_grace:keyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
end


--界张角


sgs.ai_skill_invoke.kejieyaotuzhong = function(self, data)
	if self:isWeak() then return true end
	if self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) > 2 then
		return false
	end
	return sgs.ai_skill_playerchosen.kejieyaotuzhong(self) ~= nil
end

sgs.ai_skill_playerchosen.kejieyaotuzhong = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil
	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then
		target =
			arr1[1]
	end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.kejieyaotuzhong = function(self, from, to)
	sgs.updateIntention(from, to, -50)
end


local kejieyaotaiping_skill = {}
kejieyaotaiping_skill.name = "kejieyaotaiping"
table.insert(sgs.ai_skills, kejieyaotaiping_skill)
kejieyaotaiping_skill.getTurnUseCard = function(self)
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length() >= 2 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)

		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
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
			if not fvalueCard and fcard:getSuit() == sgs.Card_Heart then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then
						local card_str = ("archery_attack:kejieyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0,
							first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = self:aiUseCard(archeryattack, dummy())
						if dummy_use.card then
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

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("archery_attack:kejieyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length() >= 2 and not self.player:hasFlag("useyaotaiping") then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)

		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end

		self:sortByKeepValue(cards)


		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("SavageAssault", fcard, self.player))
			if not fvalueCard and fcard:getSuit() == sgs.Card_Spade then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("SavageAssault", scard, self.player))
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then
						local card_str = ("savage_assault:kejieyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0,
							first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = self:aiUseCard(archeryattack, dummy())
						if dummy_use.card then
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
	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("savage_assault:kejieyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length() >= 2 and not self.player:hasFlag("useyaotaiping") then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)

		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end

		self:sortByKeepValue(cards)


		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("GodSalvation", fcard, self.player))
			if not fvalueCard and fcard:getSuit() == sgs.Card_Diamond then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("GodSalvation", scard, self.player))
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then
						local card_str = ("god_salvation:kejieyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0,
							first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = self:aiUseCard(archeryattack, dummy())
						if dummy_use.card then
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
	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("god_salvation:kejieyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end

	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length() >= 2 and not self.player:hasFlag("useyaotaiping") then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)

		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end

		self:sortByKeepValue(cards)

		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("AmazingGrace", fcard, self.player))
			if not fvalueCard and fcard:getSuit() == sgs.Card_Club then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("AmazingGrace", scard, self.player))
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then
						local card_str = ("amazing_grace:kejieyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0,
							first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = self:aiUseCard(archeryattack, dummy())
						if dummy_use.card then
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
	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("amazing_grace:kejieyaotaiping[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
end



--司马懿

sgs.ai_skill_invoke.keyaozhabing = function(self, data)
	if self:isWeak() and self:getAllPeachNum() > 0 then
		return true
	end
	if self.player:getHp() > getBestHp(self.player) then
		return true
	end
	return false
end

sgs.ai_ajustdamage_to["&keyaozhabing"] = function(self, from, to, card, nature)
	return -99
end

sgs.ai_getBestHp_skill.keyaoguimou = function(owner)
	return owner:getMaxHp() - 1
end

--界司马懿

sgs.ai_skill_invoke.kejieyaozhabing = function(self, data)
	if self:isWeak() and self:getAllPeachNum() > 0 then
		return true
	end
	if self.player:getHp() > getBestHp(self.player) then
		return true
	end
	return false
end

sgs.ai_getBestHp_skill.kejieyaoguimou = function(owner)
	return owner:getMaxHp() - 1
end

--周泰
sgs.ai_skill_invoke.kejieyaofenwei = function(self, data)
	return sgs.ai_skill_playerchosen.kejieyaofenwei(self, self.room:getOtherPlayers(self.player)) ~= nil
end
sgs.ai_skill_playerchosen.kejieyaofenwei = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) and not friend:hasSkill("kejieyaobuhui") then
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.kejieyaofenwei = function(self, from, to)
	sgs.updateIntention(from, to, -50)
end

sgs.ai_skill_invoke.kejieyaofenwei_shouhui = function(self, data)
	return true
end
sgs.ai_skill_invoke.kejieyaofenwei_mopai = function(self, data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return false
	end
	return true
end

--小乔

local keyaoquwu_skill = {}
keyaoquwu_skill.name = "keyaoquwu"
table.insert(sgs.ai_skills, keyaoquwu_skill)
keyaoquwu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#keyaoquwuCard") then return end
	return sgs.Card_Parse("#keyaoquwuCard:.:")
end

sgs.ai_skill_use_func["#keyaoquwuCard"] = function(card, use, self)
	if not self.player:hasUsed("#keyaoquwuCard") then
		self:sort(self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) then
				if enemy:getMark("&keyaoquwu") == 0 then
					use.card = sgs.Card_Parse("#keyaoquwuCard:.:")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) then
				use.card = sgs.Card_Parse("#keyaoquwuCard:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end
sgs.ai_use_value.keyaoquwuCard = 8.5
sgs.ai_use_priority.keyaoquwuCard = 9.5
sgs.ai_card_intention.keyaoquwuCard = 80

sgs.ai_use_revises.keyaotongque = function(self, card, use)
	if card:isKindOf("Analeptic")
	then
		return false
	end
end

sgs.ai_target_revises.keyaotongque = function(to, card, self, use)
	if card:isKindOf("IronChain") then return true end
end

local kejieyaoquwu_skill = {}
kejieyaoquwu_skill.name = "kejieyaoquwu"
table.insert(sgs.ai_skills, kejieyaoquwu_skill)
kejieyaoquwu_skill.getTurnUseCard = function(self)
	if (self.player:getMark("canusequwucishu") <= 0) then return end
	--if self.player:usedTimes("#kejieyaoquwuCard") < self.player:getMark("canusequwucishu") then
	return sgs.Card_Parse("#kejieyaoquwuCard:.:")
end

sgs.ai_skill_use_func["#kejieyaoquwuCard"] = function(card, use, self)
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("&kejieyaoquwu") == 0 then
			use.card = sgs.Card_Parse("#kejieyaoquwuCard:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		use.card = sgs.Card_Parse("#kejieyaoquwuCard:.:")
		if use.to then use.to:append(enemy) end
		return
	end
end

sgs.ai_use_value.kejieyaoquwuCard = 8.5
sgs.ai_use_priority.kejieyaoquwuCard = 9.5
sgs.ai_card_intention.kejieyaoquwuCard = 80

sgs.ai_target_revises.kejieyaotongque = function(to, card, self, use)
	if card:isKindOf("IronChain") then return true end
end
sgs.ai_use_revises.kejieyaotongque = function(self, card, use)
	if card:isKindOf("Analeptic") then use.card = card end
end
sgs.ai_cardneed.kejieyaotongque = function(to, card, self)
	return card:isKindOf("Analeptic")
end


sgs.ai_skill_invoke.kejieyaoquwutwo = function(self, data)
	return true
end

sgs.ai_skill_invoke.kejieyaotongquetwo = function(self, data)
	return true
end

sgs.ai_skill_discard.kejieyaotongquetwo = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	table.insert(to_discard, cards[1]:getEffectiveId())
	return to_discard
end

sgs.ai_skill_choice.kejieyaozhongshangtwo = function(self, choices, data)
	if self.player:getHp() < getBestHp(self.player) then
		return "maxhp"
	end
	return "handmax"
end

--卞氏

local keyaojiahuo_skill = {}
keyaojiahuo_skill.name = "keyaojiahuo"
table.insert(sgs.ai_skills, keyaojiahuo_skill)

keyaojiahuo_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return end
	if self.player:hasFlag("usedyaojiahuo") then return end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local subcards = {}
	self:sortByUseValue(cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
		if card:isBlack() then table.insert(cardsq, card) end
	end
	if #cardsq == 0 then return end
	if self:getKeepValue(cardsq[1]) > 18 then return end
	if self:getUseValue(cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getId())
	local card_str = "Collateral:keyaojiahuo[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = sgs.Card_Parse(card_str)
	assert(AsCard)
	return AsCard
end



sgs.ai_cardneed.keyaojiahuo = function(to, card, self)
	return card:isBlack() and to:getHandcardNum() <= 3
end

sgs.ai_skill_choice.keyaoyaohou = function(self, choices, data)
	local items = choices:split("+")
	local damage = data:toDamage()
	if self:isEnemy(damage.to) then
		return "huode"
	else
		return "mopai"
	end
	return "mopai"
end


--吉平

local keyaoshidu_skill = {}
keyaoshidu_skill.name = "keyaoshidu"
table.insert(sgs.ai_skills, keyaoshidu_skill)
keyaoshidu_skill.getTurnUseCard = function(self)
	if not self.player:isNude() then
		return sgs.Card_Parse("#keyaoshiduCard:.:")
	end
end

sgs.ai_skill_use_func["#keyaoshiduCard"] = function(card, use, self)
	local hand_weapon, cards
	cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getSuit() == sgs.Card_Spade and (card:isKindOf("BasicCard") or card:isKindOf("EquipCard")) then
			hand_weapon = card
			break
		end
	end
	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and enemy:getMark("keyaoshidu" .. self.player:objectName()) == 0 then
			if hand_weapon then
				use.card = sgs.Card_Parse("#keyaoshiduCard:" .. hand_weapon:getId() .. ":")
				if use.to then
					use.to:append(enemy)
				end
				break
			end
		end
	end
end

sgs.ai_use_value.keyaoshiduCard = 8.5
sgs.ai_use_priority.keyaoshiduCard = 9.5
sgs.ai_card_intention.keyaoshiduCard = 80

function sgs.ai_cardneed.keyaoshidu(to, card)
	return (card:getSuit() == sgs.Card_Spade) and (card:isKindOf("BasicCard") or card:isKindOf("EquipCard"))
end

sgs.ai_view_as.keyaogongdu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and (card:isBlack() and not card:isEquipped()) and player:getPhase() == sgs.Player_NotActive
		and player:getMark("Global_PreventPeach") == 0 then
		return ("peach:keyaogongdu[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_card_priority.keyaogongdu = function(self, card)
	if card and card:getSkillName() == "keyaogongdu" then
		return 1
	end
end

sgs.keyaogongdu_suit_value = {
	spade = 6,
	club = 6
}

sgs.ai_cardneed.keyaogongdu = function(to, card)
	return (card:isBlack() and not card:isEquipped())
end

--界妖吉平

local kejieyaoshidu_skill = {}
kejieyaoshidu_skill.name = "kejieyaoshidu"
table.insert(sgs.ai_skills, kejieyaoshidu_skill)
kejieyaoshidu_skill.getTurnUseCard = function(self)
	if self.player:canDiscard(self.player, "he") then
		return sgs.Card_Parse("#kejieyaoshiduCard:.:")
	end
end

sgs.ai_skill_use_func["#kejieyaoshiduCard"] = function(card, use, self)
	local hand_weapon, cards
	cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if (card:isKindOf("BasicCard") or card:isKindOf("EquipCard")) then
			hand_weapon = card
			break
		end
	end
	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
			and enemy:getMark("kejieyaoshidu" .. self.player:objectName()) == 0 then
			if hand_weapon then
				use.card = sgs.Card_Parse("#kejieyaoshiduCard:" .. hand_weapon:getId() .. ":")
				if use.to then
					use.to:append(enemy)
				end
				break
			end
		end
	end
end

sgs.ai_use_value.kejieyaoshiduCard = 8.5
sgs.ai_use_priority.kejieyaoshiduCard = 9.5
sgs.ai_card_intention.kejieyaoshiduCard = 80

function sgs.ai_cardneed.kejieyaoshidu(to, card)
	return (card:isKindOf("BasicCard") or card:isKindOf("EquipCard"))
end

sgs.ai_view_as.kejieyaogongdu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and card:isBlack()
		and player:getMark("Global_PreventPeach") == 0 then
		return ("peach:kejieyaogongdu[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.kejieyaogongdu_suit_value = {
	spade = 6,
	club = 6
}

sgs.ai_cardneed.kejieyaogongdu = function(to, card)
	return card:isBlack()
end


--凌统

sgs.ai_skill_invoke.keyaozhongyi = function(self, data)
	return true
end

--程昱



sgs.ai_choicemade_filter.cardChosen.keyaoxieqin = sgs.ai_choicemade_filter.cardChosen.dismantlement

sgs.ai_skill_playerchosen.keyaoxieqin = function(self, targets)
	targets = sgs.QList2Table(targets)
	if self:findPlayerToDiscard("he", true, false, targets, "keyaoxieqin") ~= {} then
		local target = self:findPlayerToDiscard("he", true, false, targets, "keyaoxieqin")[1]
		return target
	end
	return nil
end

sgs.ai_skill_choice["keyaoshiwei"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1, #items)]
end



sgs.ai_skill_invoke.keyaoshiwei = function(self, data)
	return true
end


sgs.ai_choicemade_filter.cardChosen.kejieyaoxieqin = sgs.ai_choicemade_filter.cardChosen.dismantlement

sgs.ai_skill_invoke.kejieyaoxieqin = function(self, data)
	return sgs.ai_skill_playerchosen.kejieyaoxieqin(self, self.room:getOtherPlayers(data:toDamage().to)) ~= nil
end
sgs.ai_skill_playerchosen.kejieyaoxieqin = function(self, targets)
	targets = sgs.QList2Table(targets)

	if self:findPlayerToDiscard("he", true, false, targets, "kejieyaoxieqin") ~= {} then
		local target = self:findPlayerToDiscard("he", true, false, targets, "kejieyaoxieqin")[1]
		return target
	end
	return nil
end

sgs.ai_playerchosen_intention.kejieyaoxieqin = 80

sgs.ai_skill_invoke.kejieyaoshiwei = function(self, data)
	return true
end

sgs.ai_skill_choice["kejieyaoshiwei"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1, #items)]
end
