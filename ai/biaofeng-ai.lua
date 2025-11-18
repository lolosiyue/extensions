sgs.ai_skill_use["@PlusJianxiong"] = function(self, prompt)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	local dest = damage.to
	if not dest or not self:isEnemy(dest) then return "." end
	local target
	if dest:getHp() <= 1 then
		if dest:getRole() == "rebel" and self:getOverflow() then
			for _, friend in ipairs(self.friends_noself) do
				if friend then
					if not hasJueqingEffect(friend, dest, damage.nature) then
						target = friend
					end
				end
			end
		elseif dest:getRole() == "loyalist" then
			local lord = self.room:getLord()
			if self:isEnemy(lord) then
				target = friend
			end
		end
	end


	if not target then
		if self:hasSkills(sgs.masochism_skill, dest) then
			self:sort(self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if enemy then
					target = enemy
				end
			end
		end
	end

	local discard_cards = {}

	for _, id in sgs.qlist(self.player:getCards("h")) do
		if id:isBlack() then
			table.insert(discard_cards, id)
		end
	end
	if target and #discard_cards > 0 then
		return "#PlusJianxiong_Card:" ..
			discard_cards[1]:getEffectiveId() .. ":->" .. target:objectName()
	end
	return "."
end


sgs.ai_skill_choice.PlusWulve = function(self, choices, data)
	local damage = data:toDamage()
	local choice1 = getChoice(choices, "PlusWulve_choice1")
	local choice2 = getChoice(choices, "PlusWulve_choice2")
	if not damage.card then return choice2 end
	if damage.card:isKindOf("Slash") and not self:hasCrossbowEffect() and self.player:getLostHp() > 1 and self:getCardsNum("Slash") > 0 then
		return choice2
	end
	if self:isWeak() and (self:getCardsNum("Slash") > 0 or not damage.card:isKindOf("Slash") or self.player:getHandcardNum() <= self.player:getHp()) then
		return choice2
	end
	local items = choices:split("+")
	if choice1 then return choice1 end
	return items[1]
end
sgs.ai_target_revises.PlusWulve = sgs.ai_target_revises.jianxiong

sgs.ai_can_damagehp.PlusWulve = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return card:isKindOf("Duel") or card:isKindOf("AOE") or to:getLostHp() > 2
	end
end

sgs.ai_skill_invoke.PlusLangmou = sgs.ai_skill_invoke.fankui

sgs.ai_choicemade_filter.cardChosen.PlusLangmou = sgs.ai_choicemade_filter.cardChosen.fankui

sgs.ai_skill_cardchosen.PlusLangmou = sgs.ai_skill_cardchosen.fankui

sgs.ai_need_damaged.PlusLangmou = sgs.ai_need_damaged.fankui

sgs.wizard_skill = sgs.wizard_skill .. "|PlusGuicai"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|PlusGuicai"


sgs.ai_skill_cardask["@PlusGuicai-card"] = function(self, data)
	local judge = data:toJudge()

	--if self.room:getMode():find("_mini_46") and not judge:isGood() then return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			--return "$" .. card_id
			return "#PlusGuicai_DummyCard:" .. card_id .. ":"
		end
	end

	return "."
end

function sgs.ai_cardneed.PlusGuicai(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and
					not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
			end
		end
	end
end

sgs.PlusGuicai_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}


sgs.ai_skill_use["@PlusGuicai2"] = function(self, prompt)
	local targets = sgs.QList2Table(self.room:getAllPlayers())
	local pindian = self.room:getTag("CurrentPindianStruct"):toPindian()
	local from, to
	for _, p in ipairs(targets) do
		if p:hasFlag("PlusGuicai_Source") then
			from = p
		end
		if p:hasFlag("PlusGuicai_Target") then
			to = p
		end
	end
	if from and to and self:isFriend(to) and self:isEnemy(from) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() < pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if acard:getNumber() < pindian.to_card:getNumber() then
						table.insert(min_card, acard:getEffectiveId())
					elseif acard:getNumber() >= pindian.from_card:getNumber() then
						table.insert(max_card, acard:getEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuicai_Card:" .. max_card[1] .. ":->" .. to:objectName()
			end
			if #min_card > 0 then
				return "#PlusGuicai_Card:" .. min_card[1] .. ":->" .. from:objectName()
			end
		end
	end
	if from and to and self:isFriend(from) and self:isEnemy(to) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() >= pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if acard:getNumber() > pindian.to_card:getNumber() then
						table.insert(max_card, acard:getEffectiveId())
					elseif acard:getNumber() < pindian.from_card:getNumber() then
						table.insert(min_card, acard:getEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuicai_Card:" .. max_card[1] .. ":->" .. from:objectName()
			end
			if #min_card > 0 then
				return "#PlusGuicai_Card:" .. min_card[1] .. ":->" .. to:objectName()
			end
		end
	end

	return "."
end

sgs.ai_target_revises.PlusTaohui = function(to, card, self, use)
	if card:isNDTrick() and to:getHandcardNum() <= to:getMaxHp()
		and self:getCardsNum("BasicCard") - self:getCardsNum("Peach") < 2
	then
		return true
	end
end

sgs.ai_skill_cardask["@PlusTaohui"] = function(self, data)
	local use = data:toCardUse()
	local current = self.room:getCurrent()
	for _, p in sgs.qlist(use.to) do
		if p:getMark("PlusTaohui-Clear") > 0 then
			if self:isFriend(p) then
				if use.card:isKindOf("AmazingGrace") and
					(p:getSeat() - current:getSeat()) % (global_room:alivePlayerCount()) < global_room:alivePlayerCount() / 2 then
					local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
					if #to_discard > 0 then return "$" .. to_discard[1] end
				end
				if use.card:isKindOf("GodSalvation") and p:isWounded() or use.card:isKindOf("ExNihilo") then
					local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")

					if #to_discard > 0 then return "$" .. to_discard[1] end
				end
				if use.card:isKindOf("IronChain") then
					if p:isChained() and not self:isGoodChainTarget(p) then
						local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
						if #to_discard > 0 then return "$" .. to_discard[1] end
					end
				end
			end
			if self:isEnemy(p) or (self:isFriend(p) and p:getRole() == "loyalist" and not hasJueqingEffect(self.player, p, sgs.card_damage_nature[use.card:getClassName()]) and self.player:isLord() and p:getHp() == 1) then
				if use.card:isKindOf("AOE") then
					local from = use.from
					if use.card:isKindOf("SavageAssault") then
						local menghuo = self.room:findPlayerBySkillName("huoshou")
						if menghuo then from = menghuo end
					end

					local friend_null = 0
					for _, q in sgs.qlist(self.room:getOtherPlayers(self.player)) do
						if self:isFriend(q) then friend_null = friend_null + getCardsNum("Nullification", q, self.player) end
						if self:isEnemy(q) then friend_null = friend_null - getCardsNum("Nullification", q, self.player) end
					end
					friend_null = friend_null + self:getCardsNum("Nullification")
					local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

					if self:hasTrickEffective(use.card, p, from) then
						if self:damageIsEffective(p, sgs.DamageStruct_Normal, from) then
							if sj_num == 0 and friend_null <= 0 then
								if self:isEnemy(from) and hasJueqingEffect(from, p, sgs.card_damage_nature[use.card:getClassName()]) then
				
									local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
									if #to_discard > 0 then return "$" .. to_discard[1] end
								end
								if self:isFriend(from) and p:getRole() == "loyalist" and from:isLord() and p:getHp() == 1 and not hasJueqingEffect(from, p, sgs.card_damage_nature[use.card:getClassName()]) then
									return "."
								end
								if (not (self:hasSkills(sgs.masochism_skill, p) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(use.from, p, sgs.card_damage_nature[use.card:getClassName()])) then
									return "."
								end
							end
						end
					end
				elseif self:isEnemy(p) then
					if use.card:isKindOf("FireAttack") then
						if self:hasTrickEffective(use.card, p) then
							if self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) then
								if (p:hasArmorEffect("vine") or p:getMark("@gale") > 0) and self.player:getHandcardNum() > 3
									and not (self.player:hasSkill("hongyan") and getKnownCard(p, p, "spade") > 0) then
				
									local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
									if #to_discard > 0 then return "$" .. to_discard[1] end
								elseif p:isChained() and not self:isGoodChainTarget(p, use.from) then
				
									local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
									if #to_discard > 0 then return "$" .. to_discard[1] end
								end
							end
						end
					elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Zhujinqiyuan") or use.card:isKindOf("ZdShengdongjixi")) and not p:isKongcheng() then
						if self:hasTrickEffective(use.card, p) then
							local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
		
							if #to_discard > 0 then return "$" .. to_discard[1] end
						end
					elseif use.card:isKindOf("Duel") or use.card:isKindOf("chuqibuyi") then
						if self:hasTrickEffective(use.card, p) then
							if self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then
								local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
								if #to_discard > 0 then return "$" .. to_discard[1] end
							end
						end
					elseif use.card:isKindOf("IronChain") then
						if self:isGoodChainTarget(p) then
							local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
							if #to_discard > 0 then return "$" .. to_discard[1] end
						end
					end
				end
			end
		end
	end

	return "."
end


sgs.ai_skill_invoke.PlusTiandu = sgs.ai_skill_invoke.jianxiong
function sgs.ai_slash_prohibit.PlusTiandu(self, from, to)
	if self:canLiegong(to, from) then return false end
	if self:isEnemy(to) and self:hasEightDiagramEffect(to) and not IgnoreArmor(from, to) and #self.enemies > 1 then return true end
end

sgs.ai_skill_use["@PlusYiji"] = function(self, prompt)
	--local cards = sgs.QList2Table(self.player:getCards("h"))

	local tag = self.room:getTag("PlusYiji")
	local guanxu_cardsToGet
	if tag then
		guanxu_cardsToGet = tag:toString():split("+")
	else
		return "."
	end
	self.room:removeTag("PlusYiji")

	local cards = {}
	for i = 1, #guanxu_cardsToGet, 1 do
		local card_data = guanxu_cardsToGet[i]
		if card_data == nil then break end
		if card_data ~= "" then
			local card_id = tonumber(card_data)
			table.insert(cards, sgs.Sanguosha:getCard(card_id))
		end
	end



	local give_card = {}
	local equip_card = {}
	local judge_card = {}
	self:sortByKeepValue(cards)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("EquipCard") then
			table.insert(equip_card, acard:getEffectiveId())
		elseif acard:isKindOf("DelayedTrick") then
			table.insert(judge_card, acard:getEffectiveId())
		else
			table.insert(give_card, acard:getEffectiveId())
		end
	end
	if #judge_card > 0 then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if (not self.player:isProhibited(enemy, sgs.Sanguosha:getCard(judge_card[1])) and enemy:hasJudgeArea() and not enemy:containsTrick(sgs.Sanguosha:getCard(judge_card[1]):objectName())) then
				return "#PlusYiji_Card:" .. judge_card[1] .. ":->" .. enemy:objectName()
			end
		end
	end
	if #equip_card > 0 then
		self:sort(self.friends, "defense")
		local equip_index = sgs.Sanguosha:getCard(equip_card[1]):getRealCard():toEquipCard():location()
		for _, friend in ipairs(self.friends) do
			if friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
				return "#PlusYiji_Card:" .. equip_card[1] .. ":->" .. friend:objectName()
			end
		end
	end



	if #give_card > 0 then
		local target1
		local extra = self:getCardsNum("Jink") - self.player:getHp() - self:getCardsNum("Peach") > 0
		for _, acard in ipairs(give_card) do
			local card = sgs.Sanguosha:getCard(acard)
			if card:isKindOf("Peach") or card:isKindOf("Analeptic") then continue end
			if not extra and card:isKindOf("Jink") then continue end
			local ids = {}
			table.insert(ids, card:getEffectiveId())
			local target, cardid = sgs.ai_skill_askforyiji.nosyiji(self, ids)
			if not target then continue end
			if not target1 or target1:objectName() == target:objectName() then
				target1 = target
			end
		end
		if not target1 then return "." end
		return "#PlusYiji_Card:" .. give_card[1] .. ":->" .. target1:objectName()
	end
	return "."
end


sgs.ai_skill_invoke.PlusYiji = sgs.ai_skill_invoke.yiji

sgs.ai_skill_choice.PlusYiji = function(self, choices, data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items, "PlusYiji_delayedTrick") and target and self:isEnemy(target) then
		return
		"PlusYiji_delayedTrick"
	end
	if table.contains(items, "PlusYiji_equip") and target and self:isFriend(target) then return "PlusYiji_equip" end
	return items[1]
end

sgs.ai_need_damaged.PlusYiji = function(self, attacker, player)
	if not player:hasSkill("PlusYiji") then return end

	local friends = {}
	for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(ap, player) then
			table.insert(friends, ap)
		end
	end
	self:sort(friends, "hp")

	if #friends > 0 and friends[1]:objectName() == player:objectName() and self:isWeak(player) and getCardsNum("Peach", player, (attacker or self.player)) == 0 then return false end

	return player:getHp() > 2 and sgs.turncount > 2 and #friends > 1 and not self:isWeak(player) and
		player:getHandcardNum() >= 2
end

sgs.ai_skill_choice.PlusGanglie = function(self, choices, data)
	local use = data:toCardUse()
	local items = choices:split("+")
	if table.contains(items, "PlusGanglie_choice1") then
		if not use.from or use.from:isDead() then return "PlusGanglie_cancel" end
		if self.role == "rebel" and sgs.ai_role[use.from:objectName()] == "rebel" and not hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()])
			and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
			return "PlusGanglie_cancel"
		end

		if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()]) and use.from:isLord() and self.player:getHp() == 1) then
			if use.card:isKindOf("Slash") then
				if not self:slashIsEffective(use.card, self.player, use.from) then return "PlusGanglie_cancel" end
				if self:hasHeavyDamage(use.from, use.card, self.player) then return "PlusGanglie_choice1" end

				local jink_num = self:getExpectedJinkNum(use)
				local hasHeart = false
				for _, card in ipairs(self:getCards("Jink")) do
					if card:getSuit() == sgs.Card_Heart then
						hasHeart = true
						break
					end
				end
				if self:getCardsNum("Jink") == 0
					or jink_num == 0
					or self:getCardsNum("Jink") < jink_num
					or (use.from:hasSkill("dahe") and self.player:hasFlag("dahe") and not hasHeart) then
					if use.card:isKindOf("NatureSlash") and self.player:isChained() and not self:isGoodChainTarget(self.player, use.from, nil, nil, use.card) then
						return
						"PlusGanglie_choice1"
					end
					if use.from:hasSkill("nosqianxi") and use.from:distanceTo(self.player) == 1 then
						return
						"PlusGanglie_choice1"
					end
					if self:isFriend(use.from) and self.role == "loyalist" and not hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()]) and use.from:isLord() and self.player:getHp() == 1 then
						return
						"PlusGanglie_choice1"
					end
					if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(use.from, self.player, sgs.card_damage_nature[use.card:getClassName()])) then
						return "PlusGanglie_choice1"
					end
				end
			elseif use.card:isKindOf("AOE") then
				local from = use.from
				if use.card:isKindOf("SavageAssault") then
					local menghuo = self.room:findPlayerBySkillName("huoshou")
					if menghuo then from = menghuo end
				end

				local friend_null = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
					if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
				end
				friend_null = friend_null + self:getCardsNum("Nullification")
				local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

				if not self:hasTrickEffective(use.card, self.player, from) then return "PlusGanglie_cancel" end
				if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then
					return
					"PlusGanglie_cancel"
				end
				if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then
					return
					"PlusGanglie_choice1"
				end
				if sj_num == 0 and friend_null <= 0 then
					if self:isEnemy(from) and hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()]) then
						return
						"PlusGanglie_choice1"
					end
					if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()]) then
						return
						"PlusGanglie_choice1"
					end
					if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(from, self.player, sgs.card_damage_nature[use.card:getClassName()])) then
						return "PlusGanglie_choice1"
					end
				end
			elseif self:isEnemy(use.from) then
				if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
					if not self:hasTrickEffective(use.card, self.player) then return "PlusGanglie_cancel" end
					if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, use.from) then
						return
						"PlusGanglie_cancel"
					end
					if (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0) and use.from:getHandcardNum() > 3
						and not (use.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
						return "PlusGanglie_choice1"
					elseif self.player:isChained() and not self:isGoodChainTarget(self.player, use.from) then
						return "PlusGanglie_choice1"
					end
				elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Zhujinqiyuan"))
					and not self.player:isKongcheng() and not self:isWeak() then
					if not self:hasTrickEffective(use.card, self.player) then return "PlusGanglie_cancel" end
					return "PlusGanglie_choice1"
				elseif use.card:isKindOf("chuqibuyi") then
					if self:hasTrickEffective(use.card, self.player) and self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then
						return
						"PlusGanglie_choice1"
					end
				elseif use.card:isKindOf("Duel") then
					if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player) then
						if self:hasTrickEffective(use.card, self.player) and self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then
							return
							"PlusGanglie_choice1"
						end
					end
				elseif use.card:isKindOf("TrickCard") and not use.card:isKindOf("AmazingGrace") then
					if self:needToLoseHp(self.player, use.from, use.card) then
						return "PlusGanglie_choice1"
					end
				end
			end
		end
	end
	if table.contains(items, "PlusGanglie_choice2") then
		if use.from and self:isEnemy(use.from) then
			if use.card:isKindOf("FireAttack") or use.card:isKindOf("Snatch") or use.card:isKindOf("Zhujinqiyuan") or use.card:isKindOf("Collateral") then
				return
				"PlusGanglie_cancel"
			end
			if use.card:isKindOf("Slash") then
				if not self:slashIsEffective(use.card, use.from, use.from) then return "PlusGanglie_cancel" end
				if self:hasHeavyDamage(use.from, use.card, use.from) then return "PlusGanglie_choice2" end

				--local jink_num = self:getExpectedJinkNum(use)

				if getCardsNum("Jink", use.from) == 0
					or jink_num == 0
					or getCardsNum("Jink", use.from) < 1 then
					if use.card:isKindOf("NatureSlash") and use.from:isChained() and not self:isGoodChainTarget(use.from, use.from, nil, nil, use.card) then
						return
						"PlusGanglie_choice2"
					end
					return "PlusGanglie_choice2"
				end
			elseif use.card:isKindOf("AOE") then
				if self:isWeak(use.from)  and self:hasTrickEffective(use.card, use.from, use.from) then
					return "PlusGanglie_choice2"
				end
			elseif use.card:isKindOf("Duel") or use.card:isKindOf("chuqibuyi") then
				if self:isWeak(use.from)  and self:hasTrickEffective(use.card, use.from, use.from) then
					return "PlusGanglie_choice2"
				end
			end
		end
	end
	return "PlusGanglie_cancel"
end


sgs.ai_skill_invoke.PlusLuoyi = function(self, data)
	if self.player:isSkipped(sgs.Player_Play) then return false end
	if self:needBear() then return false end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local slashtarget = 0
	local dueltarget = 0
	self:sort(self.enemies, "hp")
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") or card:isKindOf("EquipCard") then
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, card, true) and self:slashIsEffective(card, enemy) and self:objectiveLevel(enemy) > 3 and self:isGoodTarget(enemy, self.enemies) then
					if getCardsNum("Jink", enemy) < 1 or (self.player:hasWeapon("axe") and self.player:getCards("he"):length() > 4) then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
		if card:isKindOf("Duel") or card:isKindOf("EquipCard") then
			for _, enemy in ipairs(self.enemies) do
				if self:getCardsNum("Slash") >= getCardsNum("Slash", enemy) and self:isGoodTarget(enemy, self.enemies)
					and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy, self.player, 2) and self:canDamage(enemy,self.player,nil)
					and self:damageIsEffective(enemy) and enemy:getMark("@late") < 1 then
					dueltarget = dueltarget + 1
				end
			end
		end
	end
	if (slashtarget + dueltarget) > 0 then
		return true
	end
	return false
end


local PlusLuoyi_skill = {}
PlusLuoyi_skill.name = "PlusLuoyi"
table.insert(sgs.ai_skills, PlusLuoyi_skill)
PlusLuoyi_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasFlag("PlusLuoyi") or not self.player:hasEquip() then return end
	local patterns = { "slash", "duel" }
	local choices = {}
	for _, name in ipairs(patterns) do
		local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		poi:deleteLater()
		if poi:isAvailable(self.player) then
			table.insert(choices, name)
		end
	end

	if next(choices) and self.player:getMark("AI_do_not_invoke_PlusLuoyi-Clear") == 0 then
		return sgs.Card_Parse("#PlusLuoyi_select:.:")
	end
end

sgs.ai_skill_use_func["#PlusLuoyi_select"] = function(card, use, self)
	local useable_cards = sgs.QList2Table(self.player:getCards("e"))
	self:sortByUseValue(useable_cards, true)

	if #useable_cards == 0 then return end
	if useable_cards[1]:hasFlag("xiahui") then return end
	self.room:setTag("ai_PlusLuoyi_card_id", sgs.QVariant(useable_cards[1]:getEffectiveId()))
	local card_str = string.format("#PlusLuoyi_select:%s:", useable_cards[1]:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
end

sgs.ai_use_priority["PlusLuoyi_select"] = 3
sgs.ai_use_value["PlusLuoyi_select"] = 3

sgs.ai_skill_choice["PlusLuoyi"] = function(self, choices, data)
	local ai_taoluan_card_id = self.room:getTag("ai_PlusLuoyi_card_id"):toInt()
	self.room:removeTag("ai_PlusLuoyi_card_id")
	local taoluan_vs_card = {}
	local suit = sgs.Sanguosha:getCard(ai_taoluan_card_id):getSuit()
	local number = sgs.Sanguosha:getCard(ai_taoluan_card_id):getNumber()
	local items = choices:split("+")
	for _, card_name in ipairs(items) do
		if card_name ~= "cancel" then
			local use_card = sgs.Sanguosha:cloneCard(card_name, suit, number)
			use_card:deleteLater()
			table.insert(taoluan_vs_card, use_card)
		end
	end
	self:sortByUsePriority(taoluan_vs_card)
	for _, c in ipairs(taoluan_vs_card) do
		if table.contains(items, c:objectName()) then
			if c:isKindOf("Duel") then
				local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
				self:useTrickCard(c, dummyuse)
				if not dummyuse.to:isEmpty() then
					for _, p in sgs.qlist(dummyuse.to) do
						self.room:setTag("ai_PlusLuoyi_card_name", sgs.QVariant(c:objectName()))
						self.room:setTag("ai_PlusLuoyi_card_id", sgs.QVariant(ai_taoluan_card_id))
						return c:objectName()
					end
				end
			end
			if c:isKindOf("Slash") then
				local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
				self:useBasicCard(c, dummyuse)
				if not dummyuse.to:isEmpty() then
					for _, p in sgs.qlist(dummyuse.to) do
						self.room:setTag("ai_PlusLuoyi_card_name", sgs.QVariant(c:objectName()))
						self.room:setTag("ai_PlusLuoyi_card_id", sgs.QVariant(ai_taoluan_card_id))
						return c:objectName()
					end
				end
			end
		end
	end
	self.room:addPlayerMark(self.player, "AI_do_not_invoke_PlusLuoyi-Clear")
	return "cancel"
end

sgs.ai_skill_use["@PlusLuoyi"] = function(self, prompt, method)
	local ai_taoluan_card_name = self.room:getTag("ai_PlusLuoyi_card_name"):toString()
	self.room:removeTag("ai_PlusLuoyi_card_name")
	local ai_taoluan_card_id = self.room:getTag("ai_PlusLuoyi_card_id"):toInt()
	self.room:removeTag("ai_PlusLuoyi_card_id")
	local taoluan_use_card = sgs.Sanguosha:getCard(ai_taoluan_card_id)
	local suit = taoluan_use_card:getSuitString()
	local number = taoluan_use_card:getNumberString()
	local use_card = sgs.Sanguosha:cloneCard(ai_taoluan_card_name, sgs.Card_NoSuit, -1)

	use_card:setSkillName("PlusLuoyi")
	use_card:addSubcard(ai_taoluan_card_id)

	local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
	self:useTrickCard(use_card, dummyuse)
	local targets = {}
	if not dummyuse.to:isEmpty() then
		for _, p in sgs.qlist(dummyuse.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return use_card:toString() .. "->" .. table.concat(targets, "+")
		end
	end

	self.room:addPlayerMark(self.player, "AI_do_not_invoke_PlusLuoyi-Clear")
	return "."
end
--[[
sgs.ai_cardsview["PlusLuoyi"] = function(self, class_name, player)
	local no_have = true
	local cards = player:getCards("he")
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	for _,c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			no_have = false
			break
		end
	end
	if not no_have  then return end
	local use_cards = player:getCards("e")
	use_cards = sgs.QList2Table(use_cards)
	self:sortByKeepValue(use_cards)
	
	if #use_cards == 0 then return end
	
	
	local suit = use_cards[1]:getSuitString()
	local number = use_cards[1]:getNumberString()
	local card_id = use_cards[1]:getEffectiveId()
	if player:hasSkill("PlusLuoyi") and class_name == "Slash" then
		return ("slash:PlusLuoyi[%s:%s]=%d"):format(suit, number, card_id)
	end
end
]]
function sgs.ai_cardneed.PlusLuoyi(to, card, self)
	local slash_num = 0
	local target
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()

	local cards = to:getHandcards()
	local need_slash = true
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if isCard("Slash", c, to) then
				need_slash = false
				break
			end
		end
	end

	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if to:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and self:getDefenseSlash(enemy) <= 2 then
			target = enemy
			break
		end
	end

	if need_slash and target and isCard("Slash", card, to) then return true end
	return isCard("Duel", card, to) or isCard("EquipCard", card, to)
end

sgs.PlusLuoyi_keep_value = {
	Peach          = 6,
	Analeptic      = 5.8,
	Jink           = 5.2,
	Duel           = 5.5,
	FireSlash      = 5.6,
	Slash          = 5.4,
	ThunderSlash   = 5.5,
	Axe            = 5,
	Blade          = 4.9,
	spear          = 4.9,
	fan            = 4.8,
	KylinBow       = 4.7,
	Halberd        = 4.6,
	MoonSpear      = 4.5,
	SPMoonSpear    = 4.5,
	DefensiveHorse = 4
}

sgs.ai_ajustdamage_from.PlusLuoyi = function(self, from, to, card, nature)
	if (card and (card:isKindOf("Slash") or card:isKindOf("Duel"))) and from:hasFlag("PlusLuoyi") and not from:hasEquip()
	then
		return 1
	end
end

sgs.use_lion_skill = sgs.use_lion_skill .. "|PlusLuoyi"
sgs.need_equip_skill = sgs.need_equip_skill .. "|PlusLuoyi"

sgs.ai_skill_invoke.PlusHuwei = function(self, data)
	if self.player:getHp() == 1 then return false end
	local dying = 0
	local handang = self.room:findPlayerBySkillName("nosjiefan")
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:getHp() < 1 and not aplayer:hasSkill("nosbuqu") then
			dying = 1
			break
		end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end

	local heart_jink = false
	for _, card in sgs.qlist(self.player:getCards("he")) do
		if card:getSuit() == sgs.Card_Heart and isCard("Jink", card, self.player) then
			heart_jink = true
			break
		end
	end

	--隊友要鐵鎖連環殺自己時不用八卦陣
	local current = self.room:getCurrent()
	if current and self:isFriend(current) and self.player:isChained() and self:isGoodChainTarget(self.player, current) then return false end

	if self.player:getHandcardNum() == 1 and self:getCardsNum("Jink") == 1 and self.player:hasSkills("zhiji|beifa") and self:needKongcheng() then
		local enemy_num = self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player)
		if self.player:getHp() > enemy_num and enemy_num <= 1 then return false end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end
	if self.player:hasFlag("dahe") then return false end
	if sgs.hujiasource and (not self:isFriend(sgs.hujiasource) or sgs.hujiasource:hasFlag("dahe")) then return false end
	if sgs.lianlisource and (not self:isFriend(sgs.lianlisource) or sgs.lianlisource:hasFlag("dahe")) then return false end
	if self:needToLoseHp(self.player, nil, nil, true, true) then return false end
	if self:getCardsNum("Jink") == 0 then
		return true
	else
		return false
	end

	return true
end


ai_get_cardType = function(card)
	if card:isKindOf("Weapon") then return 1 end
	if card:isKindOf("Armor") then return 2 end
	if card:isKindOf("DefensiveHorse") then return 3 end
	if card:isKindOf("OffensiveHorse") then return 4 end
	if card:isKindOf("Treasure") then return 5 end
end

sgs.ai_skill_use["@PlusShensu1"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	if self.player:containsTrick("lightning") and self.player:getCards("j"):length() == 1
		and self:hasWizard(self.friends) and not self:hasWizard(self.enemies, true) then
		return "."
	end

	if self:needBear() then return "." end
	local selfDef = sgs.getDefense(self.player)

	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	local eCard
	local hasCard = { 0, 0, 0, 0, 0 }

	if self:needToThrowArmor() and not self.player:isCardLimited(self.player:getArmor(), method) then
		eCard = self.player:getArmor()
	end

	if not eCard then
		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
				hasCard[ai_get_cardType(card)] = hasCard[ai_get_cardType(card)] + 1
			end
		end

		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and hasCard[ai_get_cardType(card)] > 1 then
				eCard = card
				break
			end
		end

		if not eCard then
			for _, card in ipairs(cards) do
				if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and ai_get_cardType(card) > 3 and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
		if not eCard then
			for _, card in ipairs(cards) do
				if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and not card:isKindOf("Armor") and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
	end
	if not eCard then return "." end

	local effectslash, best_target, target, throw_weapon
	local defense = 6
	local weapon = self.player:getWeapon()
	if weapon and eCard:getId() == weapon:getId() and (eCard:isKindOf("fan") or eCard:isKindOf("QinggangSword")) then throw_weapon = true end

	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif throw_weapon and enemy:hasArmorEffect("vine") and not self.player:hasSkill("zonghuo") then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff then
			if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then
				best_target = enemy
				break
			end
			if def < defense then
				best_target = enemy
				defense = def
			end
			target = enemy
		end
	end

	if best_target then return "#PlusShensu_Card:" .. eCard:getEffectiveId() .. ":->" .. best_target:objectName() end
	if target then return "#PlusShensu_Card:" .. eCard:getEffectiveId() .. ":->" .. target:objectName() end


	for _, friend in ipairs(self.friends_noself) do
		local def = sgs.getDefense(friend)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, friend)

		if not self.player:canSlash(friend, slash, false) then
		elseif self:slashProhibit(nil, friend) then
		elseif eff then
			if self:needToLoseHp(friend, self.player, slash) then
				target = friend
			end
		end
	end
	if target then return "#PlusShensu_Card:" .. eCard:getEffectiveId() .. ":->" .. target:objectName() end

	return "."
end

sgs.ai_skill_use["@PlusShensu2"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")

	local selfSub = self.player:getHp() - self.player:getHandcardNum()
	local selfDef = sgs.getDefense(self.player)

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local eCard

	if not eCard then
		for _, card in ipairs(cards) do
			if card:isRed() and not card:isKindOf("Peach") and not card:isKindOf("Jink") and self:getCardsNum("Jink") == 1 then
				eCard = card
				break
			end
		end
	end

	if not eCard then return "." end

	local effectslash, best_target, target
	local defense = 6

	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff then
			if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then
				best_target = enemy
				break
			end
			if def < defense then
				best_target = enemy
				defense = def
			end
			target = enemy
		end
		if selfSub < 0 then return "." end
	end

	if best_target then return "#PlusShensu_Card:" .. eCard:getEffectiveId() .. ":->" .. best_target:objectName() end
	if target then return "#PlusShensu_Card:" .. eCard:getEffectiveId() .. ":->" .. target:objectName() end

	return "."
end

sgs.ai_cardneed.PlusShensu = function(to, card, self)
	return (card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", false) < 2)
		or (card:isRed() and to:getHandcardNum() <= 2)
end

sgs.ai_card_intention.PlusShensu_Card = sgs.ai_card_intention.Slash

sgs.need_equip_skill = sgs.need_equip_skill .. "|PlusShensu"

function sgs.ai_skill_invoke.PlusJushou(self, data)
	local sbdiaochan = self.room:findPlayerBySkillName("lihun")
	if sbdiaochan and sbdiaochan:faceUp() and not self:willSkipPlayPhase(sbdiaochan)
		and (self:isEnemy(sbdiaochan) or (sgs.turncount <= 1 and sgs.ai_role[sbdiaochan:objectName()] == "neutral")) then
		return false
	end
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

sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|PlusJushou"

sgs.ai_skill_askforag["PlusKuiwei"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByUseValue(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_skill_use["@PlusYizhong"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local eCard
	local hasCard = { 0, 0, 0, 0, 0 }

	if not eCard then
		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
				hasCard[ai_get_cardType(card)] = hasCard[ai_get_cardType(card)] + 1
			end
		end

		for _, card in ipairs(cards) do
			if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and hasCard[ai_get_cardType(card)] > 1 then
				eCard = card
				break
			end
		end

		if not eCard then
			for _, card in ipairs(cards) do
				if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and ai_get_cardType(card) > 3 and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
		if not eCard then
			for _, card in ipairs(cards) do
				if card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and not card:isKindOf("Armor") and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
	end
	if not eCard then
		for _, card in ipairs(cards) do
			if card:isKindOf("TrickCard") and not self.player:isCardLimited(card, method) then
				eCard = card
				break
			end
		end
	end


	local effectslash, best_target, target
	local defense = 6
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	for _, friend in ipairs(self.friends) do
		if friend:getMark("PlusYizhong") > 0 then
			local def = sgs.getDefense(friend)
			local slash = use.card
			local eff = self:slashIsEffective(slash, friend)
			if use.card and self:hasHeavyDamage(use.from, use.card, friend) then
				best_target = friend
				break
			end
			if not self.player:canSlash(friend, slash, false) then
			elseif self:slashProhibit(nil, friend) then
			elseif eff then
				if friend:getHp() == 1 and getCardsNum("Jink", friend) == 0 then
					best_target = friend
					break
				end
				if def < defense then
					best_target = friend
					defense = def
				end
				target = friend
			end
		end
	end

	if best_target then
		if not eCard then
			for _, card in ipairs(cards) do
				if not card:isKindOf("Peach") and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
		if eCard then
			sgs.updateIntention(self.player, best_target, -70)
			return "#PlusYizhong_Card:" .. eCard:getEffectiveId() .. ":"
		end
	end

	if target then
		if not eCard and self.player:getHandcardNum() >= 2 then
			for _, card in ipairs(cards) do
				if not card:isKindOf("Peach") and not self.player:isCardLimited(card, method) then
					eCard = card
					break
				end
			end
		end
		if eCard then
			sgs.updateIntention(self.player, target, -70)
			return "#PlusYizhong_Card:" .. eCard:getEffectiveId() .. ":"
		end
	end
	if not eCard then return "." end
	return "."
end

sgs.ai_skill_invoke.PlusYizhong = function(self, data)
	return true
end

function sgs.ai_cardneed.PlusYizhong(to, card)
	return (not card:isKindOf("BasicCard") and to:getHandcardNum() < 2) or
		(isCard("OffensiveHorse", card, to) and not (to:getOffensiveHorse() or getKnownCard(to, "OffensiveHorse", false) > 0))
end

sgs.ai_card_intention["#PlusYizhong_Card"] = function(self, card, from, tos)
	local intention = -70
	local to
	for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(from))) do
		if p:getMark("PlusYizhong") > 0 then
			to = p
			break
		end
	end
	if to then
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_skill_invoke.PlusJilei = function(self, data)
	local damage = data:toDamage()
	if damage.from and self:isEnemy(damage.from) then
		if not damage.from:isKongcheng() and self:doDisCard(damage.from, "h") then
			return true
		end
	end
	return false
end

sgs.ai_skill_suit["PlusJilei"] = function(self)
	local target
	for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
		if p:getMark("PlusJilei") > 0 then
			target = p
			break
		end
	end
	if target then
		local cards = sgs.QList2Table(target:getHandcards())
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
		for _, cc in ipairs(cards) do
			if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
				return cc:getSuit()
			end
		end
	end
	return math.random(0, 3)
end


sgs.ai_skill_use["@PlusJiangcai"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	self:sort(self.friends_noself, "handcard")


	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local eCard

	if not eCard then
		for _, card in ipairs(cards) do
			if card:isKindOf("BasicCard") and not card:isKindOf("Peach") and not (card:isKindOf("Jink") and self:getCardsNum("Jink") == 1) then
				eCard = card
				break
			end
		end
	end

	if not eCard then return "." end


	local friends = {}
	for _, friend in ipairs(self.friends_noself) do
		if not friend:isKongcheng() and #friends < 3 then
			table.insert(friends, friend:objectName())
		end
	end
	if #friends == 3 then
		return "#PlusJiangcai_Card:" .. eCard:getEffectiveId() .. ":->" .. table.concat(friends, "+")
	elseif (#friends == 1 or #friends == 2) then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and #friends < 3 then
				table.insert(friends, enemy:objectName())
			end
		end
		if #friends > 1 then
			return "#PlusJiangcai_Card:" .. eCard:getEffectiveId() .. ":->" .. table.concat(friends, "+")
		end
	end
	return "."
end


sgs.ai_skill_discard.PlusJiangcai = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	local target
	for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
		if p:getMark("PlusJiangcai") > 0 then
			target = p
			break
		end
	end
	if cards[1] == nil then return {} end
	if target then
		if self:isFriend(target) then
			self:sortByKeepValue(cards, true)
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		elseif self:isEnemy(target) then
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		end
	end

	return cards[1]:getEffectiveId()
end

sgs.ai_skill_use["@PlusYuanmou"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	self:sort(self.friends_noself, "handcard")

	local damagecard = self.room:getTag("PlusYuanmou_Damage"):toCard()
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local eCard

	if not eCard then
		for _, card in ipairs(cards) do
			if not card:isKindOf("Peach") and not (card:isKindOf("Jink") and self:getCardsNum("Jink") == 1) and
				self:getKeepValue(card) < self:getKeepValue(damagecard) then
				eCard = card
				break
			end
		end
	end

	if not eCard then return "." end

	if self:isWeak() then return "." end
	local friends = {}
	for _, p in ipairs(self.friends) do
		if not self:willSkipPlayPhase(p) then
			table.insert(friends, p)
		end
	end
	if #friends == 0 then return "." end
	self:sort(friends, "defense")
	if #friends > 0 then
		return "#PlusYuanmou_Card:" .. eCard:getEffectiveId() .. ":->" .. friends[1]:objectName()
	end
	return "."
end


sgs.ai_card_intention["#PlusYuanmou_Card"] = -60

sgs.ai_target_revises.PlusYuanmou = function(to, card, self)
	if card:isDamageCard()
		and not self:isFriend(to)
		and card:subcardsLength() > 0
	then
		for _, id in sgs.list(card:getSubcards()) do
			if isCard("Peach,Analeptic", sgs.Sanguosha:getCard(id), to)
			then
				return to:getHandcardNum() > 0
			end
		end
	end
end


sgs.ai_skill_invoke.PlusDanji = function(self, data)
	local damage = data:toDamage()
	if damage.card and damage.card:isKindOf("Slash") then
		if self:hasHeavyDamage(damage.from, damage.card, self.player) then
			return true
		end
	end
	if self:needToLoseHp(self.player, damage.from) and damage.damage <= 1 then return false end
	return true
end

sgs.ai_ajustdamage_to.PlusDanji = function(self, from, to, card, nature)
	if card and (card:isKindOf("Slash") or card:isNDTrick()) then
		if from and to and from:getHandcardNum() > to:getHandcardNum() then
			return -1
		end
	end
end



sgs.ai_skill_use["@PlusFuzheng"] = function(self, prompt, method)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		local eCard

		if not eCard then
			for _, card in ipairs(cards) do
				if card:isRed() and not card:isKindOf("Peach") and (not (card:isKindOf("Jink") and self:getCardsNum("Jink") == 1) or self:getOverflow(current) >= 2) then
					eCard = card
					break
				end
			end
		end

		if not eCard then return "." end

		return "#PlusFuzheng_Card:" .. eCard:getEffectiveId() .. ":"
	end
	return "."
end

sgs.ai_skill_invoke.PlusFuzheng = function(self, data)
	return true
end

sgs.ai_card_intention["#PlusFuzheng_Card"] = function(self, card, from, tos)
	local intention = -70
	local current = self.room:getCurrent()
	if current then
		sgs.updateIntention(from, current, intention)
	end
end
sgs.ai_target_revises.PlusPingluan = function(to, card)
	if card:isKindOf("SavageAssault")
		or card:isKindOf("ArcheryAttack")
	then
		return true
	end
end

local PlusZhiguo_skill = {}
PlusZhiguo_skill.name = "PlusZhiguo"
table.insert(sgs.ai_skills, PlusZhiguo_skill)
PlusZhiguo_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#PlusZhiguo_Card") then return end
	return sgs.Card_Parse("#PlusZhiguo_Card:.:")
end

sgs.ai_skill_use_func["#PlusZhiguo_Card"] = function(card, use, self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if not card:isKindOf("Peach") and (not (card:isKindOf("Jink") and self:getCardsNum("Jink") == 1)) then
			local targets = {}

			for _, friend in ipairs(self.friends) do
				if #targets < card:getNumber() and self:canDraw(friend, self.player) then
					table.insert(targets, friend)
				end
			end
			for _, friend in ipairs(self.friends) do
				if #targets < card:getNumber() then
					table.insert(targets, friend)
				else
					break
				end
			end
			local x = 0
			if #targets < card:getNumber() then
				for _, enemy in ipairs(self.enemies) do
					if #targets < card:getNumber() and x < 2 then
						table.insert(targets, enemy)
						x = x + 1
					end
				end
			end
			if #targets > 0 and #targets == card:getNumber() then
				use.card = sgs.Card_Parse("#PlusZhiguo_Card:.:")
				use.card:addSubcard(card)
				for _, p in ipairs(targets) do
					if use.to then
						use.to:append(p)
					end
				end
			end
			return
		end
	end
	
end

sgs.ai_skill_choice["PlusZhiguo"] = function(self, choices, data)
	return "PlusZhiguo_Draw"
end

local PlusRende_skill = {}
PlusRende_skill.name = "PlusRende"
table.insert(sgs.ai_skills, PlusRende_skill)
PlusRende_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	if self.player:getHandcardNum() <= 1 and self.player:getMaxCards() > 0 and self.player:getMark("PlusRende") == 0 then return end
	local mode = string.lower(global_room:getMode())
	if self.player:getMark("PlusRende") > 1 and mode:find("04_1v3") then return end

	if self.player:isWounded() then
		if self.player:getMark("PlusRende") > 1 and self:getOverflow() <= 0 then return end
	else
		if self:getOverflow() <= 0 then return end
	end

	if self:shouldUseRende() then
		return sgs.Card_Parse("#PlusRende_Card:.:")
	end
end

sgs.ai_skill_use_func["#PlusRende_Card"] = function(card, use, self)
	--防血少時有兩張手牌只給一張的情況
	if self.player:getHp() < 3 and self.player:isWounded() and self.player:getHandcardNum() == 2 then
		self:sort(self.friends_noself, "handcard")
		local give_all_cards = {}
		for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
			table.insert(give_all_cards, c:getEffectiveId())
		end
		local targets = {}
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				table.insert(targets, friend)
			end
		end
		if #targets > 0 and #give_all_cards > 1 then
			local card_str = string.format("#PlusRende_Card:" .. table.concat(give_all_cards, "+") .. ":")
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				use.to:append(targets[1])
			end
			return
		end
	end

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	local notFound

	for i = 1, self.player:getHandcardNum() do
		local card, friend = self:getCardNeedPlayer(cards)
		if card and friend then
			cards = self:resetCards(cards, card)
		else
			notFound = true
			break
		end

		if friend:objectName() == self.player:objectName() or not self.player:getHandcards():contains(card) then continue end
		local canJijiang = self.player:hasLordSkill("jijiang") and friend:getKingdom() == "shu"
		if card:isAvailable(self.player) and ((card:isKindOf("Slash") and not canJijiang) or card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) then
			local dummy_use = self:aiUseCard(card)
			if dummy_use.card and dummy_use.to:length() > 0 then
				if card:isKindOf("Slash") or card:isKindOf("Duel") then
					local t1 = dummy_use.to:first()
					if dummy_use.to:length() > 1 then
						continue
					elseif t1:getHp() == 1 or getCardsNum("Jink",t1,self.player)<1
						or t1:isCardLimited(sgs.Sanguosha:cloneCard("jink"), sgs.Card_MethodResponse) then
						continue
					end
				elseif (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and self:getEnemyNumBySeat(self.player, friend) > 0 then
					local hasDelayedTrick
					for _, p in sgs.qlist(dummy_use.to) do
						if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p)) then
							hasDelayedTrick = true
							break
						end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif card:isAvailable(self.player) and self:getEnemyNumBySeat(self.player, friend) > 0 and (card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")) then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then continue end
		end

		if friend:hasSkill("enyuan") and #cards >= 1 and not (self.room:getMode() == "04_1v3" and self.player:getMark("PlusRende") == 1) then
			use.card = sgs.Card_Parse("#PlusRende_Card:" .. card:getId() .. "+" .. cards[1]:getId() .. ":")
		else
			use.card = sgs.Card_Parse("#PlusRende_Card:" .. card:getId() .. ":")
		end
		if use.to then use.to:append(friend) end
		return
	end

	if notFound then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByUseValue(cards, true)
		if self.player:isWounded() and self.player:getHandcardNum() > 3 and self.player:getMark("PlusRende") < 2 then
			self:sortByUseValue(cards, true)
			local to_give = {}
			for _, card in ipairs(cards) do
				if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
					table
						.insert(to_give, card:getId())
				end
				if #to_give == 2 - self.player:getMark("PlusRende") then break end
			end
			if #to_give > 0 then
				for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
					if self:isFriend(p)  then
						use.card = sgs.Card_Parse("#PlusRende_Card:" .. table.concat(to_give, "+") .. ":")
						if use.to then use.to:append(p) end
					end
				end
			end
		end
	end
end

sgs.ai_use_value["#PlusRende_Card"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["#PlusRende_Card"] = sgs.ai_use_priority.RendeCard

sgs.ai_card_intention["#PlusRende_Card"] = sgs.ai_card_intention.RendeCard

sgs.dynamic_value.benefit["#PlusRende_Card"] = true


sgs.ai_skill_choice.PlusRende = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "PlusRende_choice1") then
		if self.player:getHp() < getBestHp(self.player) then
			return "PlusRende_choice1"
		end
	end

	if table.contains(items, "PlusRende_choice3") then
		local god_salvation = sgs.Sanguosha:cloneCard("god_salvation", sgs.Card_NoSuit, 0)
		god_salvation:deleteLater()
		local good = 0
		for _, who in ipairs(sgs.QList2Table(self.room:getAllPlayers())) do
			if self:hasTrickEffective(god_salvation, who, self.player) then
				if self:isFriend(who) then
					if not who:isWounded() or who:getHp() >= getBestHp(who) then
					elseif self:isWeak(who) then
						good = good + 1.2
					elseif who:hasSkills(sgs.masochism_skill) then
						good = good + 1
					else
						good = good + 0.9
					end
				elseif self:isEnemy(who) then
					if not who:isWounded() or who:getHp() >= getBestHp(who) then
					elseif self:isWeak(who) then
						good = good - 1.2
					elseif who:hasSkills(sgs.masochism_skill) then
						good = good - 1
					else
						good = good - 0.9
					end
				end
			end
		end

		if self:willUseGodSalvation(god_salvation) and good > 0 then
			local handcards = sgs.QList2Table(self.player:getCards("h"))
			self:sortByUseValue(handcards, true)
			local useable_cards = {}
			if self.player:getPile("wooden_ox"):length() > 0 then
				for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
					if sgs.Sanguosha:getCard(id):isKindOf("Slash") then
						table.insert(handcards, sgs.Sanguosha:getCard(id))
					end
				end
			end
			for _, c in ipairs(handcards) do
				if not c:isKindOf("Peach")
					and not c:isKindOf("Analeptic")
					and not (c:isKindOf("Analeptic") and self:getCardsNum("Analeptic") == 1 and self.player:getHp() <= 1)
					and not (c:isKindOf("Jink") and self:getCardsNum("Jink") == 1)
					and not c:isKindOf("Nullification")
					and not c:isKindOf("SavageAssault")
					and not c:isKindOf("ArcheryAttack")
					and not c:isKindOf("Duel")
					and not c:isKindOf("Armor")
					and not c:isKindOf("DefensiveHorse")
					and c:getSuit() == sgs.Card_Heart
				then
					table.insert(useable_cards, c)
				end
			end
			if #useable_cards == 0 then return "PlusRende_cancel" end
			return "PlusRende_choice3"
		end
	end
	if table.contains(items, "PlusRende_choice2") then
		local can_invoke = true
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if p:hasFlag("PlusRende_target") then
				if p:isNude() or self:isWeak(p) then
					can_invoke = false
					break
				end
			end
		end
		if can_invoke then
			return "PlusRende_choice2"
		end
	end

	return "PlusRende_cancel"
end

sgs.ai_skill_cardask["#PlusRende_Salvation"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards, true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Heart then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusRende"

sgs.ai_skill_invoke.PlusGuanxing = function(self, data)
	return true
end

sgs.ai_skill_invoke.PlusKongcheng = function(self, data)
	return true
end


sgs.ai_skill_playerchosen.PlusKongcheng = function(self, targets)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if sgs.playerRoles["rebel"] == 0 then
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) and lord:objectName() ~= self.player:objectName() and not hasManjuanEffect(lord) then
			return lord
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and not hasManjuanEffect(AssistTarget) then
		return AssistTarget
	end

	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) and friend:hasSkills(sgs.cardneed_skill) then
			return friend
		end
	end

	self:sort(self.friends_noself, "chaofeng")
	for _, friend in ipairs(self.friends_noself) do
		if not hasManjuanEffect(friend) then
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.PlusKongcheng = -80

function sgs.ai_slash_prohibit.PlusKongcheng(self, from, to)
	if self:isEnemy(to) then return true end
end

sgs.ai_view_as.PlusWusheng = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
		and not card:isKindOf("Peach") and not card:hasFlag("using") and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("slash:PlusWusheng[%s:%s]=%d"):format(suit, number, card_id)
	end
end


sgs.ai_ajustdamage_from.PlusWusheng = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:getSuit() == sgs.Card_Diamond
	then
		return 1
	end
end

local PlusWusheng_skill = {}
PlusWusheng_skill.name = "PlusWusheng"
table.insert(sgs.ai_skills, PlusWusheng_skill)
PlusWusheng_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	local red_card = {}
	self:sortByUseValue(cards, true)

	local useAll = false
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("eight_diagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end
	for _,card in ipairs(cards)do
		if not card:isKindOf("Slash") 
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (not isCard("Crossbow",card,self.player) or disCrossbow)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard("slash"))>0)
		then table.insert(red_card,card) end
	end
	for _,card in ipairs(red_card)do
		local slash = dummyCard("slash")
		slash:addSubcard(card)
		slash:setSkillName("PlusWusheng")
		if slash:isAvailable(self.player)
		then return slash end
	end
end

function sgs.ai_cardneed.PlusWusheng(to, card)
	return to:getHandcardNum() < 3
end
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|PlusWusheng"
sgs.double_slash_skill = sgs.double_slash_skill .. "|PlusWusheng"

local PlusPaoxiao_skill = {}
PlusPaoxiao_skill.name = "PlusPaoxiao"
table.insert(sgs.ai_skills, PlusPaoxiao_skill)
PlusPaoxiao_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getLostHp() == 0 or self.player:hasUsed("#PlusPaoxiao_Card") then return nil end

	return sgs.Card_Parse("#PlusPaoxiao_Card:.:")
end

sgs.ai_skill_use_func["#PlusPaoxiao_Card"] = function(card, use, self)
	use.card = sgs.Card_Parse("#PlusPaoxiao_Card:.:")
end

sgs.ai_use_value["PlusPaoxiao_Card"] = sgs.ai_use_value.Slash + 0.2
sgs.ai_use_priority["PlusPaoxiao_Card"] = sgs.ai_use_priority.Slash + 0.2


sgs.ai_skill_choice.PlusPaoxiao_Card = function(self, choices, data)
	local extra = getChoice(choices, "PlusPaoxiao1")
	local num = getChoice(choices, "PlusPaoxiao2")

	local slashcount = self:getCardsNum("Slash")
	if slashcount > 1 then
		return num
	end
	if #self.enemies == 1 then
		return num
	end
	return extra
end

sgs.ai_getBestHp_skill.PlusPaoxiao = function(owner)
	return owner:getMaxHp() - 1
end



sgs.ai_cardneed.PlusJie = function(to, card)
	return card:isRed() and isCard("Slash", card, to)
end

sgs.ai_ajustdamage_from.PlusJie = function(self, from, to, card, nature)
	if from and card and card:isKindOf("Slash") and card:isRed()
	then
		return 1
	end
end

sgs.ai_skill_invoke.PlusChangsheng = function(self, data)
	return true
end

sgs.PlusLongdan_suit_value = {
	heart = 4.0,
	spade = 5,
	club = 4.2,
	diamond = 3.9,
}

function sgs.ai_cardneed.PlusLongdan(to, card, self)
	if to:getCardCount() > 3 then return false end
	if to:isNude() then return true end
	return card:getSuit() == sgs.Card_Spade
end

----------------------------------
local PlusLongdan_skill = {}
PlusLongdan_skill.name = "PlusLongdan"
table.insert(sgs.ai_skills, PlusLongdan_skill)
PlusLongdan_skill.getTurnUseCard = function(self, inclusive)
	local usable_cards = self:addHandPile()
	local equips = sgs.QList2Table(self.player:getCards("e"))
	for _, e in ipairs(equips) do
		if e:isKindOf("DefensiveHorse") or e:isKindOf("OffensiveHorse") then
			table.insert(usable_cards, e)
		end
	end
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(usable_cards, sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(usable_cards, true)
	local two_diamond_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Diamond and #two_diamond_cards < 2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and not c:isKindOf("Slash") then
			table.insert(two_diamond_cards, c:getEffectiveId())
		end
	end
	if #two_diamond_cards == 2 and self:slashIsAvailable() and (self.player:getHp() > 2) and self:getOverflow() > 0 then
		return sgs.Card_Parse(("slash:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_diamond_cards[1],
			two_diamond_cards[2]))
	end
	if self:slashIsAvailable() and self.player:getHp() <= 2 then
		for _, c in ipairs(usable_cards) do
			if c:getSuit() == sgs.Card_Diamond and self:slashIsAvailable() and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink") < 3) and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
				return sgs.Card_Parse(("slash:PlusLongdan[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(),
					c:getEffectiveId()))
			end
		end
	end
	local two_heart_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Heart and #two_heart_cards < 2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			table.insert(two_heart_cards, c:getEffectiveId())
		end
	end
	if #two_heart_cards == 2 and (self.player:getHp() > 2) and self:getOverflow() > 0 then
		return sgs.Card_Parse(("analeptic:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_heart_cards[1],
			two_heart_cards[2]))
	end
	if self:slashIsAvailable() and self.player:getHp() <= 2 then
		for _, c in ipairs(usable_cards) do
			if c:getSuit() == sgs.Card_Heart and not c:isKindOf("Peach") then
				return sgs.Card_Parse(("analeptic:PlusLongdan[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(),
					c:getEffectiveId()))
			end
		end
	end
end

sgs.ai_view_as.PlusLongdan = function(card, player, card_place, class_name)
	if card_place == sgs.Player_PlaceSpecial then return end
	local usable_cards = sgs.QList2Table(player:getCards("he"))
	for _, id in sgs.qlist(player:getHandPile()) do
		table.insert(usable_cards, sgs.Sanguosha:getCard(id))
	end
	local two_club_cards = {}
	local two_heart_cards = {}
	local two_spade_cards = {}
	local two_diamond_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Club and #two_club_cards < 2 then
			table.insert(two_club_cards, c:getEffectiveId())
		elseif c:getSuit() == sgs.Card_Heart and #two_heart_cards < 2 then
			table.insert(two_heart_cards, c:getEffectiveId())
		elseif c:getSuit() == sgs.Card_Diamond and #two_diamond_cards < 2 then
			table.insert(two_diamond_cards, c:getEffectiveId())
		elseif c:getSuit() == sgs.Card_Spade and #two_spade_cards < 2 then
			table.insert(two_spade_cards, c:getEffectiveId())
		end
	end

	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()

	if #two_club_cards == 2 and (player:getHp() > 2) then
		return ("jink:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_club_cards[1], two_club_cards[2])
	elseif card:getSuit() == sgs.Card_Club and player:getHp() <= 2 then
		return ("jink:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end

	if #two_heart_cards == 2 and (player:getHp() > 2) then
		return ("analeptic:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_heart_cards[1], two_heart_cards[2])
	elseif card:getSuit() == sgs.Card_Heart and player:getHp() <= 2 then
		return ("analeptic:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end

	--[[if #two_spade_cards == 2 and (player:getHp() > 2) then
		return ("nullification:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_spade_cards[1],
			two_spade_cards[2])
	elseif card:getSuit() == sgs.Card_Spade and player:getHp() <= 2 then
		return ("nullification:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end]]
	if card:getSuit() == sgs.Card_Spade and player:getHp() <= 2 then
		return ("nullification:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end

	if #two_diamond_cards == 2 and (player:getHp() > 2) then
		return ("slash:PlusLongdan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_diamond_cards[1], two_diamond_cards[2])
	elseif card:getSuit() == sgs.Card_Diamond and player:getHp() <= 2 then
		return ("slash:PlusLongdan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_getBestHp_skill.PlusLongdan = function(owner)
	return 2
end

sgs.ai_cardneed.PlusTieji = function(to, card, self)
	return (isCard("Slash", card, to) and getKnownCard(to, self.player, "Slash", true) == 0) or
		(not self:willSkipPlayPhase(to) and self:getUseValue(card) < 6 and card:getNumber() > 10)
end

function sgs.ai_skill_pindian.PlusTieji(minusecard, self, requestor)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if requestor:objectName() == self.player:objectName() then
		return cards[1]:getId()
	end
	return self:getMaxCard(self.player):getId()
end

sgs.ai_skill_invoke.PlusTieji = function(self, data)
	local target = data:toPlayer()
	if not self:isEnemy(target) then return false end
	if not self.player:canPindian(target, true) then return false end

	if self.player:getHandcardNum() == 1 then
		if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then return true end
		local card = self.player:getHandcards():first()
		if card:isKindOf("Jink") or card:isKindOf("Peach") then return end
	end

	if (self.player:getHandcardNum() >= self.player:getHp() or self:getMaxCard():getNumber() > 10
			or (self:needKongcheng() and self.player:getHandcardNum() == 1) or not self:hasLoseHandcardEffective())
		and self:doDisCard(target, "he") then
		return true
	end
	if self:doDisCard(target, "e") then return true end
	return false
end

sgs.ai_choicemade_filter.cardChosen.PlusTieji = sgs.ai_choicemade_filter.cardChosen.snatch

function sgs.ai_skill_pindian.PlusTieji(minusecard, self, requestor)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if requestor:objectName() == self.player:objectName() then
		return minusecard
	end
	return self:getMaxCard()
end

sgs.ai_skill_invoke.PlusJizhi = function(self, data)
	local target = data:toPlayer()
	if target then
		return self:doDisCard(target,"h")
	end
	return true
end

function sgs.ai_cardneed.PlusJizhi(to, card)
	return card:getTypeId() == sgs.Card_TypeTrick
end

function sgs.ai_cardneed.PlusYongyi(to, card)
	return (isCard("Slash", card, to) and getKnownCard(to, "Slash", true) == 0) or
		(card:isKindOf("Weapon") and not (to:getWeapon() or getKnownCard(to, "Weapon", false) > 0))
end

sgs.ai_skill_invoke.PlusYongyi = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end

sgs.ai_skill_invoke.PlusLiegong = function(self, data)
	local use = data:toCardUse()
	if use.from then
		return self:doDisCard(use.from,"h")
	end
	return true
end

sgs.ai_canliegong_skill.PlusLiegong = function(self, from, to)
	return from:getPhase() == sgs.Player_Play and (to:getHandcardNum() >= from:getHp() or to:getHandcardNum() <= from:getAttackRange())
end

local PlusQimou_skill = {}
PlusQimou_skill.name = "PlusQimou"
table.insert(sgs.ai_skills, PlusQimou_skill)
PlusQimou_skill.getTurnUseCard = function(self)
	if (self.player:getMark("@stratagem") == 0) then return end
	if self:needBear() then return end
	if #self.enemies == 0 then return end
	if sgs.ai_role[self.player:objectName()] == "neutral" then return end
	return sgs.Card_Parse("#PlusQimou_Card:.:")
end
sgs.ai_skill_use_func["#PlusQimou_Card"] = function(card, use, self)
	local target

	local slashcount = self:getCardsNum("Slash")

	self:sort(self.friends_noself, "handcard", true)
	for _, friend in ipairs(self.friends_noself) do
		if friend and not friend:isKongcheng() then
			if self:needKongcheng(friend) then
				target = friend
				break
			end
			if not self:isWeak(friend) then
				target = friend
				break
			end
		end
	end
	local can_slash = false
	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif def < 6 and eff then
			can_slash = true
		end
	end

	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff and def < 8 then
			can_slash = true
		end
	end
	local can_invoke = false
	for _, c in sgs.qlist(self.player:getHandcards()) do
		local x = nil
		if isCard("ArcheryAttack", c, self.player) then
			x = sgs.Sanguosha:cloneCard("ArcheryAttack")
		elseif isCard("SavageAssault", c, self.player) then
			x = sgs.Sanguosha:cloneCard("SavageAssault")
		else
			continue
		end
		x:deleteLater()

		local du = { isDummy = true }
		self:useTrickCard(x, du)
		if (du.card) then can_invoke = true end
		--if target and (du.card) and self.player:getHp() > 1 then use.card=acard end
	end
	if target and ((slashcount > 0 and can_slash and self:slashIsAvailable()) or can_invoke) then
		local card_str = ("#PlusQimou_Card:.:")
		use.card = sgs.Card_Parse(card_str)
		if use.to then use.to:append(target) end
	end
end
sgs.ai_use_priority["PlusQimou_Card"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_choice.PlusQimou = function(self, choices, data)
	local target = data:toPlayer()
	local give = getChoice(choices, "PlusQimou_Give")

	if target and self:isFriend(target) then
		return give
	end
	return "PlusQimou_Refuse"
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusZaiqi"
sgs.ai_skill_invoke.PlusZaiqi = sgs.ai_skill_invoke.zaiqi

sgs.ai_skill_invoke.PlusZaiqi_ss = function(self, data)
	local card = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
	card:deleteLater()
	if self:getAoeValue(card) > 0 and ((self.player:getHandcardNum() <= 4)) then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@PlusZhongyong_Slash"] = function(self, data, pattern, target)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isRed() then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end


sgs.ai_skill_playerchosen.PlusZhongyong = function(self, targets)
	local friends = {}
	for _, player in ipairs(self.friends) do
		if player:isAlive() and self:canDraw(player, self.player) and self.player:distanceTo(player) <= 2 then
			table.insert(friends, player)
		end
	end
	self:sort(friends)

	local max_x = 0
	local target

	local CP = self.room:getCurrent()
	local max_x = 0
	local AssistTarget = self:AssistTarget()
	for _, friend in ipairs(friends) do
		local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
		if self:hasCrossbowEffect(CP) then x = x + 1 end
		if AssistTarget and friend:objectName() == AssistTarget:objectName() then x = x + 0.5 end

		if x > max_x and friend:isAlive() then
			max_x = x
			target = friend
		end
	end

	return target
end

sgs.ai_playerchosen_intention.PlusZhongyong = function(self, from, to)
	if to:getHandcardNum() < math.min(5, to:getMaxHp()) then
		sgs.updateIntention(from, to, -80)
	end
end

sgs.ai_skill_use["@PlusZhongyong"] = function(self, prompt)
	if self.player:isKongcheng() then return "." end
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	self.player:setFlags("slashNoDistanceLimit")
	local dummy_use = self:aiUseCard(slash)
	self.player:setFlags("-slashNoDistanceLimit")
	if not dummy_use.to:isEmpty() then
		for _, enemy in sgs.qlist(dummy_use.to) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point > enemy_max_point then
					self.shuangren_card = max_card:getEffectiveId()
					return "#PlusZhongyong_Card:" .. max_card:getEffectiveId() .. ":->" .. enemy:objectName()
				end
			end
		end
		for _, enemy in sgs.qlist(dummy_use.to) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self.player:canPindian(enemy) then
				if max_point >= 10 then
					self.shuangren_card = max_card:getEffectiveId()
					return "#PlusZhongyong_Card" .. max_card:getEffectiveId() .. ":->" .. enemy:objectName()
				end
			end
		end
		if #self.enemies < 1 then return end
	end

	return "."
end

function sgs.ai_skill_pindian.PlusZhongyong(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return (maxcard:getNumber() < 6 and minusecard or maxcard)
end

sgs.ai_cardneed.PlusZhongyong = sgs.ai_cardneed.bignumber

function sgs.ai_skill_invoke.PlusChouyuan(self, data)
	local use = data:toCardUse()
	local target
	for _, p in sgs.qlist(use.to) do
		if p:getMark("PlusChouyuan_target") > 0 then
			target = p
		end
	end
	if target and self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.PlusChouyuan = function(self,player,promptlist)
	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
		if p:getMark("PlusChouyuan_target") > 0 then target = p break end
	end
	if target then
		if promptlist[#promptlist]=="yes" then
			sgs.updateIntention(player,target,-80)
		else
			sgs.updateIntention(player,target,80)
		end
	end
end


sgs.ai_skill_invoke.PlusChenggui = function(self, data)
	local card = self.room:getTag("PlusChenggui_card"):toCard()
	if ((card:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse())
			or (card:isKindOf("OffensiveHorse") and (self.player:getOffensiveHorse() or (self.player:hasSkill("drmashu") and self.player:getDefensiveHorse()))))
		and not self.player:hasSkills(sgs.lose_equip_skill) then
		return false
	end
	if card:isKindOf("Armor")
		and ((self.player:hasSkills("bazhen|yizhong") and not self.player:getArmor())
			or (self.player:getArmor() and self:evaluateArmor(card) < self:evaluateArmor(self.player:getArmor()))) then
		return false
	end
	if card:isKindOf("Weanpon") and (self.player:getWeapon() and self:evaluateArmor(card) < self:evaluateArmor(self.player:getWeapon())) then return false end
	return true
end


local PlusChenggui_skill = {}
PlusChenggui_skill.name = "PlusChenggui"
table.insert(sgs.ai_skills, PlusChenggui_skill)
PlusChenggui_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if self:needBear() then return end
	if not self.player:hasUsed("#PlusChenggui") then
		return sgs.Card_Parse("#PlusChenggui:.:")
	end
end

sgs.ai_skill_use_func["#PlusChenggui"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends, "handcard")
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local use_card
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
	until nextAlive:faceUp()



	local hasLightning, hasIndulgence, hasSupplyShortage
	local tricks = nextAlive:getJudgingArea()
	if not tricks:isEmpty() and not nextAlive:containsTrick("YanxiaoCard") then
		local trick = tricks:at(tricks:length() - 1)
		if self:hasTrickEffective(trick, nextAlive) then
			if trick:isKindOf("Lightning") then
				hasLightning = true
			elseif trick:isKindOf("Indulgence") then
				hasIndulgence = true
			elseif trick:isKindOf("SupplyShortage") then
				hasSupplyShortage = true
			end
		end
	end

	if hasLightning and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		for _, id in ipairs(cards) do
			local card = sgs.Sanguosha:getEngineCard(id)
			if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
				use_card = card
			end
		end
	end
	if not use_card then
		if hasIndulgence then
			if self:isFriend(nextAlive) then
				for _, card in ipairs(cards) do
					--local card = sgs.Sanguosha:getEngineCard(id)
					if card:getSuit() == sgs.Card_Heart then
						use_card = card
					end
				end
			elseif self:isEnemy(nextAlive) then
				for _, card in ipairs(cards) do
					--local card = sgs.Sanguosha:getEngineCard(id)
					if card:getSuit() ~= sgs.Card_Heart then
						use_card = card
					end
				end
			end
		end
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
			table.insert(targets, friend)
		end
	end
	if not use_card then
		use_card = cards[1]
	end


	if #targets == 0 then return end
	if not use_card then return end
	use.card = sgs.Card_Parse("#PlusChenggui:" .. use_card:getId() .. ":")
	if use.to then
		use.to:append(targets[1])
	end
end

sgs.ai_use_priority["PlusChenggui"] = 7
sgs.ai_use_value["PlusChenggui"] = 7


local PlusZhiheng_skill = {}
PlusZhiheng_skill.name = "PlusZhiheng"
table.insert(sgs.ai_skills, PlusZhiheng_skill)
PlusZhiheng_skill.getTurnUseCard = function(self)
	local has_Crossbow = false
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if c:isKindOf("Crossbow") then
			has_Crossbow = true
		end
	end
	if has_Crossbow or self:hasCrossbowEffect() then
		for _, slash in ipairs(self:getCards("Slash")) do
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useBasicCard(slash, dummyuse)
			if not dummyuse.to:isEmpty() then return end
		end
	end

	if not self.player:hasUsed("#PlusZhiheng_Card") then
		return sgs.Card_Parse("#PlusZhiheng_Card:.:")
	end
end

sgs.ai_skill_use_func["#PlusZhiheng_Card"] = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	if self.player:getHp() < 3 then
		local zcards = self.player:getCards("he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0 then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
			end
		end
	end
	if #unpreferedCards == 0 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) then
					local dummy_use = self:aiUseCard(card)
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getId()) end
			end
		end

		local num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unpreferedCards, card:getId())
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards, card:getId())
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = self:aiUseCard(card)
				if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
			table.insert(unpreferedCards, self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards, self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
		end
	end
	for index = #unpreferedCards, 1, -1 do
		if sgs.Sanguosha:getCard(unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then
			table.insert(use_cards,
				unpreferedCards[index])
		end
	end

	if #use_cards > 0 then
		use.card = sgs.Card_Parse("#PlusZhiheng_Card:" .. table.concat(use_cards, "+") .. ":")
		return
	end
end

sgs.ai_use_value["#PlusZhiheng_Card"] = 9
sgs.ai_use_priority["#PlusZhiheng_Card"] = 2.61
sgs.dynamic_value.benefit["#PlusZhiheng_Card"] = true


function sgs.ai_cardneed.PlusZhiheng(to, card)
	return not card:isKindOf("Jink")
end

sgs.ai_skill_choice.PlusZhiheng = function(self, choices, data)
	local max = 0
	local min = 999
	for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
		if p:getHandcardNum() > max then
			max = p:getHandcardNum()
		end
		if p:getHandcardNum() < min then
			min = p:getHandcardNum()
		end
	end
	local friend_can_invoke = false
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() == min and (not self:needKongcheng(friend, true) or hasManjuanEffect(friend)) then
			friend_can_invoke = true
		end
	end
	local enemy_can_invoke = false
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() == max and not hasTuntianEffect(enemy, true) then
			enemy_can_invoke = true
		end
	end
	if friend_can_invoke and enemy_can_invoke then
		return "PlusZhiheng_ok"
	end
	return "PlusZhiheng_cancel"
end


sgs.ai_skill_playerchosen["#PlusZhiheng_from"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not hasTuntianEffect(p, true) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention["#PlusZhiheng_from"] = function(self, from, to)
	sgs.updateIntention(from, to, 30)
end

sgs.ai_skill_playerchosen["#PlusZhiheng_to"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and (not self:needKongcheng(p, true) or hasManjuanEffect(p)) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention["#PlusZhiheng_to"] = function(self, from, to)
	sgs.updateIntention(from, to, -30)
end

sgs.ai_use_revises.PlusZhiheng = function(self, card, use)
	if card:isKindOf("Weapon")
		and not card:isKindOf("Crossbow")
		and self:getSameEquip(card)
		and not self.player:hasUsed("#PlusZhiheng_Card")
	then
		return false
	end
end

local PlusFanjian_skill = {
	name = "PlusFanjian",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#PlusFanjian_Card") then return end
		if self.player:isNude() then return end
		local can_use = false
		self:sort(self.enemies, "chaofeng")
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		for _, enemy in ipairs(self.enemies) do
			if not self:slashIsEffective(slash, enemy) then continue end
			can_use = true
			break
		end
		if can_use then
			return sgs.Card_Parse("#PlusFanjian_Card:.:")
		end
	end,
}
table.insert(sgs.ai_skills, PlusFanjian_skill) --加入AI可用技能表
sgs.ai_skill_use_func["#PlusFanjian_Card"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("he"))
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	if #handcards == 0 then return end
	self:sortByUseValue(handcards, true) --对可用手牌按使用价值从小到大排序
	local togive = nil
	local slasher, target
	self:sort(self.enemies, "defense")
	for _, enemy_a in ipairs(self.enemies) do
		for _, enemy_b in ipairs(self.enemies) do
			if enemy_b:canSlash(enemy_a) and not self:slashProhibit(slash, enemy_a) and self:getDefenseSlash(enemy_a) <= 2
				and self:slashIsEffective(slash, enemy_a) and self:isGoodTarget(enemy_a, self.enemies, slash) and enemy_b:getHandcardNum() > enemy_a:getHandcardNum() and enemy_a:objectName() ~= self.player:objectName() then
				slasher = enemy_b
				target = enemy_a
				break
			end
		end
	end
	if not slasher then
		for _, enemy in ipairs(self.enemies) do
			for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(enemy))) do
				if p:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:getDefenseSlash(enemy) <= 2
					and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and p:getHandcardNum() > enemy:getHandcardNum() and enemy:objectName() ~= self.player:objectName() then
					slasher = p
					target = enemy
					break
				end
			end
		end
	end

	if slasher and target then
		togive = handcards[1]
		local card_str = string.format("#PlusFanjian_Card:%s:", togive:getEffectiveId())
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(slasher)
			use.to:append(target)
		end
	end
end

sgs.ai_use_priority["PlusFanjian_Card"] = 0
sgs.ai_use_value["PlusFanjian_Card"] = 0
sgs.ai_card_intention["PlusFanjian_Card"] = 80

sgs.ai_use_revises.PlusKeji = function(self, card, use)
	if card:isKindOf("Slash") and not self.player:hasFlag("PlusKejiSlashInPlayPhase")
		and ((self.player:getMark("PlusDujiang") == 0 and self.player:hasSkill("PlusDujiang")) or self.player:getPile("slack"):length() == 0)
	then
		return false
	end
end

sgs.ai_getBestHp_skill.PlusDujiang = function(owner)
	if owner:getMark("PlusDujiang") == 0 and owner:getPile("slack"):length() >= 4 then
		return owner:getMaxHp() - 1
	end
end

local PlusDuocheng_skill = {}
PlusDuocheng_skill.name = "PlusDuocheng"
table.insert(sgs.ai_skills, PlusDuocheng_skill)
PlusDuocheng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if not self.player:hasUsed("#PlusDuocheng_Card") then
		return sgs.Card_Parse("#PlusDuocheng_Card:.:")
	end
end

sgs.ai_skill_use_func["#PlusDuocheng_Card"] = function(card, use, self)
	local useable_cards = {}
	if self.player:getPile("slack"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("slack")) do
			table.insert(useable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	if #useable_cards == 0 then return end
	local target
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getEquips():length() <= self.player:getHandcardNum() then
			target = enemy
		end
	end
	if target then
		if useable_cards[1]:hasFlag("xiahui") then return end
		local card_str = string.format("#PlusDuocheng_Card:%s:", useable_cards[1]:getEffectiveId())
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_priority["#PlusDuocheng_Card"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_use_value["#PlusDuocheng_Card"] = 1

sgs.ai_skill_discard.PlusDuocheng = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", discard_num, min_num, false, false)
end


sgs.ai_skill_invoke["#PlusKeji_Jink"] = function(self, data)
	local dying = 0
	local handang = self.room:findPlayerBySkillName("nosjiefan")
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:getHp() < 1 and not aplayer:hasSkill("nosbuqu") then
			dying = 1
			break
		end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end

	--隊友要鐵鎖連環殺自己時不用八卦陣
	local current = self.room:getCurrent()
	if current and self:isFriend(current) and self.player:isChained() and self:isGoodChainTarget(self.player, current) then return false end --內奸跳反會有問題，非屬性殺也有問題。但狀況特殊，八卦陣原碼資訊不足，暫時這樣寫。
	--	slash = sgs.Sanguosha:cloneCard("fire_slash")
	--	if slash and slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, self.room:getCurrent(), nil, nil, slash) then return false end

	if self.player:getHandcardNum() == 1 and self:getCardsNum("Jink") == 1 and self.player:hasSkills("zhiji|beifa") and self:needKongcheng() then
		local enemy_num = self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player)
		if self.player:getHp() > enemy_num and enemy_num <= 1 then return false end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end
	if self:needToLoseHp(self.player, nil, nil, true, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end

	return true
end


sgs.ai_skill_use["@PlusCuorui"] = function(self, prompt)
	local target = self.room:getTag("PlusCuorui"):toPlayer()

	local cards = {}
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("he"))) do
		table.insert(cards, c:getEffectiveId())
	end
	if #cards > 0 and target and self:isFriend(target) then
		return "#PlusCuorui_DummyCard:" .. cards[1] .. ":"
	end
	return "."
end


sgs.ai_getLeastHandcardNum_skill.PlusDuoshi = function(self, player, least)
	if least < 1 then
		return 1
	end
end


local PlusQixi_skill = {}
PlusQixi_skill.name = "PlusQixi"
table.insert(sgs.ai_skills, PlusQixi_skill)
PlusQixi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("PlusQixi_used") then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end

	local black_card

	self:sortByUseValue(cards, true)

	local has_weapon = false

	for _, card in ipairs(cards) do
		if card:isKindOf("Weapon") and card:isBlack() then has_weapon = true end
	end

	for _, card in ipairs(cards) do
		if card:isBlack() and ((self:getUseValue(card) < sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow() > 0) then
			local shouldUse = true

			if card:isKindOf("Armor") then
				if not self.player:getArmor() then
					shouldUse = false
				elseif self.player:hasEquip(card) and not self:needToThrowArmor() then
					shouldUse = false
				end
			end

			if card:isKindOf("Weapon") then
				if not self.player:getWeapon() then
					shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then
					shouldUse = false
				end
			end

			if card:isKindOf("Slash") then
				local dummy_use = { isDummy = true }
				if self:getCardsNum("Slash") == 1 then
					local dummy_use = self:aiUseCard(card)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.Dismantlement and card:isKindOf("TrickCard") then
				local dummy_use = self:aiUseCard(card)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				black_card = card
				break
			end
		end
	end

	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("dismantlement:PlusQixi[%s:%s]=%d"):format(suit, number, card_id)
		local dismantlement = sgs.Card_Parse(card_str)

		assert(dismantlement)

		return dismantlement
	end
end

sgs.PlusQixi_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.PlusQixi(to, card)
	return card:isBlack()
end

sgs.ai_skill_invoke.PlusQixi = function(self, data)
	local target = data:toPlayer()
	if self:isEnemy(target) then
		return self:doDisCard(target, "hej")
	end
	if self:isFriend(target) then
		return self:needToThrowArmor(target) or self:doDisCard(target, "hej") or target:getJudgingArea():length() > 0
	end
	return not self:isFriend(target)
end

sgs.ai_skill_cardask["@PlusQixi_prompt"] = function(self, data, pattern, target)
	local move = data:toMoveOneTime()
	local card_id = move.card_ids:first()
	local cd = sgs.Sanguosha:getCard(card_id)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if self:getKeepValue(card) < self:getKeepValue(cd) then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_use_revises.PlusQixi = function(self, card, use)
	if card:isKindOf("EquipCard")
		and card:isBlack()
	then
		same = self:getSameEquip(card)
		if same and same:isBlack()
		then
			return false
		end
	end
end

local PlusKurou_skill = {}
PlusKurou_skill.name = "PlusKurou"
table.insert(sgs.ai_skills, PlusKurou_skill)
PlusKurou_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#PlusKurou_Card") then return end
	local func = Tactic("PlusKurou", self, nil)
	if func then return func(self, nil) end
	sgs.ai_use_priority["#PlusKurou_Card"] = 6.8
	local losthp = isLord(self.player) and 0 or 1
	if ((self.player:getHp() > 3 and self.player:getLostHp() <= losthp and self.player:getHandcardNum() > self.player:getHp())
			or (self.player:getHp() - self.player:getHandcardNum() >= 2)) and not (isLord(self.player) and sgs.turncount <= 1) then
		return sgs.Card_Parse("#PlusKurou_Card:.:")
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	if (self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")) or self.player:hasSkill("paoxiao") then
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, nil, true) and self:slashIsEffective(slash, enemy)
				and not (enemy:hasSkill("kongcheng") and enemy:isKongcheng())
				and not (enemy:hasSkills("fankui|guixin") and not self.player:hasSkill("paoxiao"))
				and not enemy:hasSkills("fenyong|jilei|zhichi")
				and self:isGoodTarget(enemy, self.enemies, slash) and not self:slashProhibit(slash, enemy) and self.player:getHp() > 1 then
				return sgs.Card_Parse("#PlusKurou_Card:.:")
			end
		end
	end
	if self.player:getHp() == 1 and self:getCardsNum("Analeptic") >= 1 then
		return sgs.Card_Parse("#PlusKurou_Card:.:")
	end

	--Suicide by NosKurou
	local nextplayer = self.player:getNextAlive()
	if self.player:getHp() == 1 and self.player:getRole() ~= "lord" and self.player:getRole() ~= "renegade" then
		local to_death = false
		if self:isFriend(nextplayer) then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasSkill("xiaoguo") and not self:isFriend(p) and not p:isKongcheng()
					and self.role == "rebel" and self.player:getEquips():isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkill("jieyin") and self.player:isMale() then return end
				if nextplayer:hasSkill("qingnang") then return end
			end
		end
		if self.player:getRole() == "rebel" and not self:isFriend(nextplayer) then
			if not self:willSkipPlayPhase(nextplayer) or nextplayer:hasSkill("shensu") then
				to_death = true
			end
		end
		local lord = getLord(self.player)
		if self.player:getRole() == "loyalist" then
			if lord and lord:getCards("he"):isEmpty() then return end
			if self:isEnemy(nextplayer) and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkills("noslijian|lijian") and self.player:isMale() and lord and lord:isMale() then
					to_death = true
				elseif nextplayer:hasSkill("quhu") and lord and lord:getHp() > nextplayer:getHp() and not lord:isKongcheng()
					and lord:inMyAttackRange(self.player) then
					to_death = true
				end
			end
		end
		if to_death then
			local caopi = self.room:findPlayerBySkillName("xingshang")
			if caopi and self:isEnemy(caopi) then
				if self.player:getRole() == "rebel" and self.player:getHandcardNum() > 3 then to_death = false end
				if self.player:getRole() == "loyalist" and lord and lord:getCardCount(true) + 2 <= self.player:getHandcardNum() then
					to_death = false
				end
			end
			if #self.friends == 1 and #self.enemies == 1 and self.player:aliveCount() == 2 then to_death = false end
		end
		if to_death then
			self.player:setFlags("NosKurou_toDie")
			sgs.ai_use_priority.NosKurouCard = 0
			return sgs.Card_Parse("#PlusKurou_Card:.:")
		end
		self.player:setFlags("-NosKurou_toDie")
	end
end

sgs.ai_skill_use_func["#PlusKurou_Card"] = function(card, use, self)
	if not use.isDummy then self:speak("noskurou") end
	use.card = card
end

sgs.ai_use_priority["#PlusKurou_Card"] = 6.8


sgs.ai_skill_playerchosen["PlusKurou"] = function(self, targets)
	return self.player
end


sgs.ai_skill_choice.PlusKurou = function(self, choices, data)
	return "PlusKurou_Draw"
end

local PlusZhaxiang_skill = { name = "PlusZhaxiang" }
table.insert(sgs.ai_skills, PlusZhaxiang_skill)
function PlusZhaxiang_skill.getTurnUseCard(self)
	if self.player:getMark("@surrender") < 1 then return end
	if self.player:getHp() > 1 then return end
	if self:needBear() then return end
	if (#self.friends > 1) or (#self.enemies == 1 and sgs.turncount > 1) then
		if self:getAllPeachNum() == 0 and self.player:getHp() == 1 then
			for _, enemy in ipairs(self.enemies) do
				if self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) and self:damageIsEffective(self.player, sgs.DamageStruct_Fire, self.player) and enemy:isChained() then
					return sgs.Card_Parse("#PlusZhaxiang_Card:.:")
				end
			end
			if self.role == "rebel" then
				local can_invoke = true
				for _, friend in ipairs(self.friends_noself) do
					if self:damageIsEffective(friend, sgs.DamageStruct_Fire, self.player) and self:damageIsEffective(self.player, sgs.DamageStruct_Fire, self.player) and friend:isChained() then
						can_invoke = false
						break
					end
				end
				if can_invoke then
					return sgs.Card_Parse("#PlusZhaxiang_Card:.:")
				end
			end
		end
		if self:isWeak() and self.role == "rebel" and self.room:getLord():isChained() then
			return sgs.Card_Parse("#PlusZhaxiang_Card:.:")
		end
	end
end

sgs.ai_skill_use_func["#PlusZhaxiang_Card"] = function(card, use, self)
	use.card = card
end


sgs.ai_skill_use["@PlusLiuli"] = function(self, prompt, method)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) and self:isGoodChainTarget(self.player, current) then return "." end
	local others = self.room:getOtherPlayers(self.player)
	local slash = self.room:getTag("liuli-card"):toCard()
	others = sgs.QList2Table(others)
	local source
	for _, player in ipairs(others) do
		if player:hasFlag("LiuliSlashSource") then
			source = player
			break
		end
	end
	self:sort(self.enemies, "defense")

	local doLiuli = function(who)
		if not self:isFriend(who) and who:hasSkills("leiji|nosleiji|olleiji")
			and (self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3)
			and (getKnownCard(who, self.player, "Jink", true) >= 1 or self:hasEightDiagramEffect(who)) then
			return "."
		end
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not self.player:isCardLimited(card, method) and who:isMale() and ((self.player:distanceTo(who) <= 2 and not card:isKindOf("OffensiveHorse")) or
					(self.player:distanceTo(who, 1) <= 2) and card:isKindOf("OffensiveHorse")) then
				if self:isFriend(who) and not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) then
					return "#PlusLiuli_Card:" .. card:getEffectiveId() .. ":->" .. who:objectName()
				else
					return "#PlusLiuli_Card:" .. card:getEffectiveId() .. ":->" .. who:objectName()
				end
			end
		end
		local cards = self.player:getCards("e")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not self.player:isCardLimited(card, method) and who:isMale() and ((self.player:distanceTo(who) <= 2 and not card:isKindOf("OffensiveHorse")) or
					(self.player:distanceTo(who, 1) <= 2) and card:isKindOf("OffensiveHorse")) then
				return "#PlusLiuli_Card:" .. card:getEffectiveId() .. ":->" .. who:objectName()
			end
		end
		return "."
	end
	for _, enemy in ipairs(self.enemies) do
		if not (source and source:objectName() == enemy:objectName()) then
			local ret = doLiuli(enemy)
			if ret ~= "." then return ret end
		end
	end

	for _, player in ipairs(others) do
		if self:objectiveLevel(player) == 0 and not (source and source:objectName() == player:objectName()) then
			local ret = doLiuli(player)
			if ret ~= "." then return ret end
		end
	end

	self:sort(self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)


	for _, friend in ipairs(self.friends_noself) do
		if (not (self:slashIsEffective(slash, friend, source)) or self:findLeijiTarget(friend, 50, source)) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if self:needToLoseHp(friend, source, slash) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end
	if (self:isWeak() or self:hasHeavyDamage(source, slash)) and source:hasWeapon("axe") and source:getCards("he"):length() > 2
		and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	if (self:isWeak() or self:hasHeavyDamage(source, slash)) and not self:getCardId("Jink") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) or (self:hasEightDiagramEffect(friend) and getCardsNum("Jink", friend) >= 1) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	return "."
end

sgs.ai_card_intention["#PlusLiuli_Card"] = function(self, card, from, to)
	sgs.ai_liuli_effect = true
	if not hasExplicitRebel(self.room) then
		sgs.ai_liuli_user = from
	else
		sgs.ai_liuli_user = nil
	end
end

function sgs.ai_slash_prohibit.PlusLiuli(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:isNude() then return false end
	for _, friend in ipairs(self:getFriends(from, true)) do
		if to:distanceTo(friend) <= 2 and friend:isMale() and self:slashIsEffective(card, friend, from) then return true end
	end
end

function sgs.ai_cardneed.PlusLiuli(to, card)
	return to:getCards("he"):length() <= 2
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusJieyin"

local PlusJieyin_skill = {}
PlusJieyin_skill.name = "PlusJieyin"
table.insert(sgs.ai_skills, PlusJieyin_skill)
PlusJieyin_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 2 then return nil end
	if self.player:hasUsed("#PlusJieyin_Card") then return nil end
	if self:needBear() and not self.player:isWounded() and not self:isWeak() then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local first, second
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") then
			local dummy_use = self:aiUseCard(card)
			if not dummy_use.card then
				if not first then
					first = card:getEffectiveId()
				elseif first and not second then
					second = card:getEffectiveId()
				end
			end
			if first and second then break end
		end
	end

	for _, card in ipairs(cards) do
		if card:getTypeId() ~= sgs.Card_TypeEquip and (not self:isValuableCard(card) or self.player:isWounded()) then
			if not first then
				first = card:getEffectiveId()
			elseif first and first ~= card:getEffectiveId() and not second then
				second = card:getEffectiveId()
			end
		end
		if first and second then break end
	end

	if not second or not first then return end
	local card_str = ("#PlusJieyin_Card:%d+%d:"):format(first, second)
	assert(card_str)
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#PlusJieyin_Card"] = function(card, use, self)
	local target = nil
	local others = self.room:getOtherPlayers(self.player)
	for _, other in sgs.qlist(others) do
		if other:getMark("@match") > 0 and other:isMale() then
			target = other
			break
		end
	end
	local can_invoke = false
	if target and target:isLord() then
		if target:getMark("hunzi") == 0 and target:hasSkill("hunzi") and self:getEnemyNumBySeat(self.player, target) <= (target:getHp() >= 2 and 1 or 0) then
			return
		elseif self:needToLoseHp(target, nil, nil, true, true) then
			return
		elseif not sgs.isLordHealthy() then
			can_invoke = true
		end
	else
		if self:needToLoseHp(target, nil, nil, nil, true) or (self:hasSkills("rende|kuanggu|zaiqi", target) and target:getHp() >= 2) then
			return
		else
			can_invoke = true
		end
	end

	if target and can_invoke then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end




sgs.ai_skill_use["@PlusLiangyuan"] = function(self, prompt, method)
	local min = 999
	for _, friend in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
		if friend:getHandcardNum() < min then
			min = friend:getHandcardNum()
		end
	end
	if self.role == "loyalist" and self.room:getLord():isMale() and (self.room:getLord():getHandcardNum() == min or self.room:getLord():isWounded()) then
		return "#PlusLiangyuan_Card:.:->" .. self.room:getLord():objectName()
	end
	for _, friend in ipairs(self.friends_noself) do
		if (friend:getHandcardNum() == min or friend:isWounded()) and friend:isMale() then
			return "#PlusLiangyuan_Card:.:->" .. friend:objectName()
		end
	end

	return "."
end


sgs.ai_card_intention["#PlusLiangyuan_Card"] = -80

sgs.ai_skill_invoke.PlusYinli = function(self, data)
	return true
end
sgs.ai_skill_askforag.PlusYinli = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end

sgs.ai_skill_invoke.PlusHongyan = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end

	return false
end

sgs.ai_skill_askforag.PlusHongyan = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end


sgs.ai_skill_use["@PlusTianxiang"] = function(self, prompt, method)
	self:sort(self.enemies, "defense")
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local use_card
	for _, card in ipairs(cards) do
		if not (isCard("Peach", card, self.player) or isCard("Analeptic", card, self.player)) and card:getSuit() == sgs.Card_Heart then
			use_card = card
		end
	end
	local target
	for _, friend in ipairs(self.friends_noself) do
		if self:ImitateResult_DrawNCards(friend, friend:getVisibleSkillList(true)) > 2 then
			target = friend
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:hasSkill(sgs.cardneed_skill) then
				target = friend
				break
			end
		end
	end
	

	if not target then
		for _, enemy in ipairs(self.enemies) do
			if self:getOverflow(enemy) > 3 or enemy:hasSkill("yongsi") then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			target = friend
			break
		end
	end



	if use_card and target then
		return "#PlusTianxiang_Card:" .. use_card:getEffectiveId() .. ":->" .. target:objectName()
	end

	return "."
end

sgs.ai_skill_choice["PlusTianxiang"] = function(self, choices, data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	else
		if self:isEnemy(target) then
			return "PlusTianxiang_Discard"
		end
	end
	return "PlusTianxiang_Draw"
end





sgs.ai_skill_askforag.PlusBuqu = function(self, card_ids)
	for i, card_id in ipairs(card_ids) do
		for j, card_id2 in ipairs(card_ids) do
			if i ~= j and sgs.Sanguosha:getCard(card_id):getNumber() == sgs.Sanguosha:getCard(card_id2):getNumber() then
				return card_id
			end
		end
	end

	return card_ids[1]
end



function sgs.ai_skill_invoke.PlusBuqu(self, data)
	if #self.enemies == 1 and self.enemies[1]:hasSkill("guhuo") then
		return false
	else
		return true
	end
end

sgs.ai_hasBuquEffect_skill.PlusBuqu = function(player)
	return player:getPile("Plushurt"):length() <= 4
end

sgs.save_skill = sgs.save_skill .. "|PlusHuzhu"
function sgs.ai_skill_invoke.PlusHuzhu(self, data)
	local dying = data:toDying()
	local target = dying.who
	if target and self:isFriend(target) then
		return true
	end
	return false
end

function sgs.ai_skill_invoke.PlusBiyou(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return not self:isWeak()
	end
	return false
end

function sgs.ai_skill_invoke.PlusLiangjie(self, data)
	return true
end

function sgs.ai_skill_invoke.PlusQiaojian(self, data)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		if not current:containsTrick("YanxiaoCard") then
			if (current:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
				or (current:containsTrick("lightning") and #self.friends > #self.enemies) then
				return true
			elseif current:containsTrick("supply_shortage") then
				--if self.player:getHp() > self.player:getHandcardNum() then return true end
				return true
			elseif current:containsTrick("indulgence") then
				if self.player:getHandcardNum() > 3 or self.player:getHandcardNum() > self.player:getHp() - 1 then return true end
				for _, friend in ipairs(self.friends_noself) do
					if not friend:containsTrick("YanxiaoCard") and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
						return true
					end
				end
			end
		end
	end
	return false
end

sgs.ai_skill_cardask["@PlusQiaojian_Prompt"] = function(self, data, pattern, target, target2)
	local suit = pattern:split("|")[2]
	local current = self.room:getCurrent()
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(usable_cards)
	local give_card = {}
	if self:isFriend(current) then
		for _, c in ipairs(usable_cards) do
			if c:getSuitString() == suit then
				table.insert(give_card, c)
			end
		end
		if #give_card > 0 then
			return give_card[1]:toString()
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@PlusQiaojian_Prompt"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		--local current = self.player:getTag("sidi_target"):toPlayer()
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, -60)
	end
end



sgs.ai_skill_use["@PlusJiahuo"] = function(self, prompt, method)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) and self:isGoodChainTarget(self.player, current) then return "." end

	local others = self.room:getOtherPlayers(self.player)
	local slash = self.room:getTag("liuli-card"):toCard()
	others = sgs.QList2Table(others)
	local source
	for _, player in ipairs(others) do
		if player:hasFlag("LiuliSlashSource") then
			source = player
			break
		end
	end
	self:sort(self.enemies, "defense")

	local doLiuli = function(who)
		if not self:isFriend(who) and who:hasSkills("leiji|nosleiji|olleiji")
			and (self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3)
			and (getKnownCard(who, self.player, "Jink", true) >= 1 or self:hasEightDiagramEffect(who)) then
			return "."
		end

		if (self.player:canSlash(who)) then
			if self:isFriend(who) then
				return "#PlusJiahuo_Card:.:->" .. who:objectName()
			else
				return "#PlusJiahuo_Card:.:->" .. who:objectName()
			end
		end

		if self.player:canSlash(who) then
			return "#PlusJiahuo_Card:.:->" .. who:objectName()
		end
		return "."
	end

	for _, enemy in ipairs(self.enemies) do
		if not (source and source:objectName() == enemy:objectName()) then
			local ret = doLiuli(enemy)
			if ret ~= "." then return ret end
		end
	end

	for _, player in ipairs(others) do
		if self:objectiveLevel(player) == 0 and not (source and source:objectName() == player:objectName()) then
			local ret = doLiuli(player)
			if ret ~= "." then return ret end
		end
	end


	self:sort(self.friends_noself, "defense")
	self.friends_noself = sgs.reverse(self.friends_noself)


	for _, friend in ipairs(self.friends_noself) do
		if not self:slashIsEffective(slash, friend) or self:findLeijiTarget(friend, 50, source) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	for _, friend in ipairs(self.friends_noself) do
		if self:needToLoseHp(friend, source, nil) then
			if not (source and source:objectName() == friend:objectName()) then
				local ret = doLiuli(friend)
				if ret ~= "." then return ret end
			end
		end
	end

	if (self:isWeak() or self:hasHeavyDamage(source, slash)) and source:hasWeapon("axe") and source:getCards("he"):length() > 2
		and not self:getCardId("Peach") and not self:getCardId("Analeptic") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end

	if (self:isWeak() or self:hasHeavyDamage(source, slash)) and not self:getCardId("Jink") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:isWeak(friend) or (self:hasEightDiagramEffect(friend) and getCardsNum("Jink", friend) >= 1) then
				if not (source and source:objectName() == friend:objectName()) then
					local ret = doLiuli(friend)
					if ret ~= "." then return ret end
				end
			end
		end
	end
	return "."
end


function sgs.ai_slash_prohibit.PlusJiahuo(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	for _, friend in ipairs(self:getFriends(from, true)) do
		if to:canSlash(friend) and self:slashIsEffective(card, friend, from) then return not to:faceUp() end
	end
end

local PlusZenhui_skill = {
	name = "PlusZenhui",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#PlusZenhui_Card") then return end
		local can_use = false
		self:sort(self.enemies, "chaofeng")
		for _, enemy_a in ipairs(self.enemies) do
			for _, enemy_b in ipairs(self.enemies) do
				if enemy_b:getHp() == enemy_a:getHp() then continue end
				if enemy_a:objectName() == enemy_b:objectName() then continue end
				can_use = true
				break
			end
			if can_use == true then break end
		end
		if can_use then
			return sgs.Card_Parse("#PlusZenhui_Card:.:")
		end
	end,
}
table.insert(sgs.ai_skills, PlusZenhui_skill) --加入AI可用技能表
sgs.ai_skill_use_func["#PlusZenhui_Card"] = function(card, use, self)
	local handcards = self.player:getHandcards()
	local blacks = {}
	for _, c in sgs.qlist(handcards) do
		if c:getSuit() == sgs.Card_Spade then
			table.insert(blacks, c) --加入可用集合
		end
	end
	if #blacks == 0 then return end
	self:sortByUseValue(blacks, true) --对可用手牌按使用价值从小到大排序
	local togive = nil
	self:sort(self.enemies, "chaofeng")
	local weak_enemy = {}
	local kong_enemy = {}
	local kong_weak = {}
	for _, enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) and not enemy:isKongcheng() then
			table.insert(weak_enemy, enemy)
		elseif not self:isWeak(enemy) and enemy:isKongcheng() then
			if hasManjuanEffect(enemy) or enemy:hasSkill("qingjian") then continue end
			table.insert(kong_enemy, enemy)
		elseif self:isWeak(enemy) and enemy:isKongcheng() then
			table.insert(weak_enemy, enemy)
			if hasManjuanEffect(enemy) or enemy:hasSkill("qingjian") then continue end
			table.insert(kong_enemy, enemy)
			table.insert(kong_weak, enemy)
		end
	end
	if #weak_enemy == 0 then return end
	local lost_enemy = nil
	local dis_enemy = nil
	if #kong_weak > 0 then
		for _, enemy_a in ipairs(kong_weak) do
			for _, enemy_b in ipairs(self.enemies) do
				if enemy_b:getHp() == enemy_a:getHp() then continue end
				if enemy_a:objectName() == enemy_b:objectName() then continue end
				dis_enemy = enemy_b
				break
			end
			if dis_enemy then
				lost_enemy = enemy_a
				break
			end
		end
	end
	if not lost_enemy then
		if #weak_enemy > 1 then
			for _, enemy_a in ipairs(weak_enemy) do
				for _, enemy_b in ipairs(self.enemies) do
					if enemy_b:getHp() == enemy_a:getHp() then continue end
					if enemy_a:objectName() == enemy_b:objectName() then continue end
					if not self:isWeak(enemy_b) then continue end
					togive = blacks[1]
					if enemy_a:getCardCount(true) > enemy_b:getCardCount(true) then
						if enemy_b:getCardCount(true) > 1 then
							lost_enemy = enemy_a
							dis_enemy = enemy_b
						else
							lost_enemy = enemy_b
							dis_enemy = enemy_a
						end
					else
						if enemy_a:getCardCount(true) > 1 then
							lost_enemy = enemy_b
							dis_enemy = enemy_a
						else
							lost_enemy = enemy_a
							dis_enemy = enemy_b
						end
					end
					break
				end
				if togive then break end
			end
		end
		if not lost_enemy then
			for _, enemy_a in ipairs(weak_enemy) do
				for _, enemy_b in ipairs(self.enemies) do
					if enemy_b:getHp() == enemy_a:getHp() then continue end
					if enemy_a:objectName() == enemy_b:objectName() then continue end

					dis_enemy = enemy_b
					break
				end
				if not dis_enemy and #kong_enemy > 0 then
					for _, enemy_b in ipairs(kong_enemy) do
						if enemy_a:objectName() == enemy_b:objectName() then continue end
						if enemy_b:getHp() == enemy_a:getHp() then continue end
						dis_enemy = enemy_b
						break
					end
				end
				if dis_enemy then
					lost_enemy = enemy_a
					break
				end
			end
		end
	end
	if lost_enemy and dis_enemy then
		togive = blacks[1]
		local card_str = string.format("#PlusZenhui_Card:%s:", togive:getEffectiveId())
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			if dis_enemy:isKongcheng() then
				use.to:append(dis_enemy)
				use.to:append(lost_enemy)
			else
				use.to:append(lost_enemy)
				use.to:append(dis_enemy)
			end
		end
	end
end

sgs.ai_use_priority["PlusZenhui_Card"] = 0
sgs.ai_use_value["PlusZenhui_Card"] = 0
sgs.ai_card_intention["PlusZenhui_Card"] = 80

sgs.ai_skill_choice["PlusZenhui"] = function(self, choices, data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	else
		if self:isEnemy(target) then
			return "PlusZenhui_Damage"
		elseif self:isFriend(target) then
			if self:isWeak(target) then
				return "PlusZenhui_Discard"
			elseif self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) and self:needToLoseHp(target, self.player, nil) then
				return "PlusZenhui_Damage"
			end
		end
	end
	return "PlusZenhui_Discard"
end



PlusSheji_skill = { name = "PlusSheji" }
table.insert(sgs.ai_skills, PlusSheji_skill)
PlusSheji_skill.getTurnUseCard = function(self)
	self:updatePlayers()
	local has_weak_enemy = false
	for _, enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) then
			has_weak_enemy = true
		end
	end
	if (self.player:isKongcheng()) then return end
	if not has_weak_enemy then
		if self:getCardsNum("Peach") > 0 or self:getCardsNum("Duel") > 0
			or (self:getCardsNum("Analeptic") > 0 and self:isWeak())
			or (self:getCardsNum("Jink") > 0 and self:isWeak())
			or self:getCardsNum("SupplyShortage") > 0 or self:getCardsNum("Indulgence") > 0
			or self:getCardsNum("ArcheryAttack") > 0 or self:getCardsNum("SavageAssault") > 0
		then
			return
		end
	end

	if self.player:getHandcardNum() > 1 then
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if not c:isKindOf("Analeptic") then
				if self:willUse(self.player, c) or c:isAvailable(self.player) then return end
			end
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	slash:addSubcards(self.player:getHandcards())
	slash:setSkillName("PlusSheji")
	return slash
end
sgs.ai_use_priority.PlusSheji_skill = sgs.ai_use_priority.Slash - 0.1

function sgs.ai_cardsview.PlusSheji(self, class_name, player)
	if player:getPhase() ~= sgs.Player_NotActive then return end
	if class_name == "Slash"then
		local slashs = {}
		for _, c in sgs.qlist(player:getCards("h")) do
			if c:isKindOf("Slash") then
				table.insert(slashs, c)
			end
		end
		if #slashs == 0 then
			local c = PatternsCard(class_name)
			c:setSkillName("PlusSheji")
			c:addSubcards(player:getHandcards())
			return c:toString()
		end
	end
end

sgs.ai_card_priority.PlusSheji = function(self, card)
	if card:isKindOf("Slash") and self.player:getHandcardNum() < 4 and table.contains(card:getSkillNames(), "PlusSheji")
	then
		return 1
	end
end

sgs.save_skill = sgs.save_skill .. "|PlusMafei"

sgs.ai_use_revises.PlusMafei = function(self, card, use)
	if card:isKindOf("EquipCard")
		and card:isRed()
	then
		same = self:getSameEquip(card)
		if same and same:isRed()
		then
			return false
		end
	end
end

sgs.ai_target_revises.PlusMafei = function(to, card)
	if (card:isKindOf("Slash")
			or card:isNDTrick()) and to:hasFlag("PlusMafei")
	then
		return true
	end
end

sgs.PlusMafei_suit_value = {
	heart = 6,
	diamond = 6
}

sgs.ai_cardneed.PlusMafei = function(to, card)
	return card:isRed()
end

sgs.ai_skill_cardask["@PlusMafei_Prompt"] = function(self, data, pattern, target, target2)
	local dying = data:toDying()
	local target = dying.who
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(usable_cards)
	local give_card = {}
	if self:isFriend(target) then
		for _, c in ipairs(usable_cards) do
			if c:isRed() then
				table.insert(give_card, c)
			end
		end
		if #give_card > 0 then
			return give_card[1]:toString()
		end
	end
	return "."
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|PlusXuanhu"

sgs.ai_use_revises.PlusXuanhu = function(self, card, use)
	if card:isKindOf("Slash") and self:isWeak()
		and self:getOverflow() <= 0
	then
		return false
	end
end

local PlusXuanhu_skill = {}
PlusXuanhu_skill.name = "PlusXuanhu"
table.insert(sgs.ai_skills, PlusXuanhu_skill)
PlusXuanhu_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return nil end
	if self.player:hasUsed("#PlusXuanhu_Card") then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local compare_func = function(a, b)
		local v1 = self:getKeepValue(a) + (a:isRed() and 50 or 0) + (a:isKindOf("Peach") and 50 or 0)
		local v2 = self:getKeepValue(b) + (b:isRed() and 50 or 0) + (b:isKindOf("Peach") and 50 or 0)
		return v1 < v2
	end
	table.sort(cards, compare_func)

	local card_str = ("#PlusXuanhu_Card:%d:"):format(cards[1]:getId())
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#PlusXuanhu_Card"] = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then
		target =
			arr1[1]
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
	if self:getOverflow() > 0 and #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
end

sgs.ai_use_priority["#PlusXuanhu_Card"] = 4.2
sgs.ai_card_intention["#PlusXuanhu_Card"] = -100

sgs.dynamic_value.benefit["#PlusXuanhu_Card"] = true



sgs.ai_skill_playerchosen.PlusQingnang = function(self, targets)
	local first, second
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) and friend:isAlive() then
			if isLord(friend) and self:isWeak(friend) then return friend end
			if not (friend:hasSkill("zhiji") and friend:getMark("zhiji") == 0 and not self:isWeak(friend) and friend:getPhase() == sgs.Player_NotActive) then
				if sgs.ai_role[friend:objectName()] == "renegade" then
					second = friend
				elseif sgs.ai_role[friend:objectName()] ~= "renegade" and not first then
					first = friend
				end
			end
		end
	end
	if first then return first end
	if second then return second end
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) then
			return friend
		end
	end
	return nil
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|PlusQingnang"

sgs.ai_skill_choice["PlusQingnang"] = function(self, choices, data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	else
		if self:isFriend(target) then
			if self:isWeak(target) or self:hasSkills(sgs.need_maxhp_skill, target) then
				return "PlusQingnang_choice1"
			else
				return "PlusQingnang_choice2"
			end
		end
	end
	return "PlusQingnang_choice1"
end



sgs.ai_skill_cardask["@PlusGuidao-card"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:prepend(sgs.Sanguosha:getCard(id))
		end
	end

	if all_cards:isEmpty() then return "." end

	local needTokeep = judge.card:getSuit() ~= sgs.Card_Spade and
		((not self.player:hasSkill("leiji") and not self.player:hasSkill("olleiji")) or judge.card:getSuit() ~= sgs.Card_Club)
		and sgs.ai_AOE_data and self:playerGetRound(judge.who) < self:playerGetRound(self.player) and
		self:findLeijiTarget(self.player, 50)
		and (self:getCardsNum("Jink") > 0 or self:hasEightDiagramEffect()) and self:getFinalRetrial() == 1

	if not needTokeep then
		local who = judge.who
		if who:getPhase() == sgs.Player_Judge and not who:getJudgingArea():isEmpty() and who:containsTrick("lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if self.player:hasSkill("nosleiji") then keptspade = 2 end
		if self.player:hasSkill("PlusLeiji") then keptspade = 2 end
		if self.player:hasSkill("leiji") then keptblack = 2 end
		if self.player:hasSkill("olleiji") then keptblack = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if card:isBlack() and not card:hasFlag("using") then
			if card:getSuit() == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptblack == 1 and not self.player:hasSkill("olleiji") then return "." end
	if keptspade == 1 and not self.player:hasSkill("leiji") then return "." end

	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
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


sgs.PlusGuidao_suit_value = {
	spade = 3.9,
	club = 2.7
}

sgs.PlusGuidao_keep_value = {
	Peach = 10,
	Jink = 9
}

sgs.ai_skill_use["@PlusGuidao2"] = function(self, prompt)
	local targets = sgs.QList2Table(self.room:getAllPlayers())
	local pindian = self.room:getTag("CurrentPindianStruct"):toPindian()
	local from, to
	for _, p in ipairs(targets) do
		if p:hasFlag("PlusGuidao_Source") then
			from = p
		end
		if p:hasFlag("PlusGuidao_Target") then
			to = p
		end
	end
	if from and to and self:isFriend(to) and self:isEnemy(from) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() < pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") and acard:isBlack() then
					if acard:getNumber() < pindian.to_card:getNumber() then
						table.insert(min_card, acard:getEffectiveId())
					elseif acard:getNumber() >= pindian.from_card:getNumber() then
						table.insert(max_card, acard:getEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuidao_Card:" .. max_card[1] .. ":->" .. to:objectName()
			end
			if #min_card > 0 then
				return "#PlusGuidao_Card:" .. min_card[1] .. ":->" .. from:objectName()
			end
		end
	end
	if from and to and self:isFriend(from) and self:isEnemy(to) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() >= pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") and acard:isBlack() then
					if acard:getNumber() > pindian.to_card:getNumber() then
						table.insert(max_card, acard:getEffectiveId())
					elseif acard:getNumber() < pindian.from_card:getNumber() then
						table.insert(min_card, acard:getEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#PlusGuidao_Card:" .. max_card[1] .. ":->" .. from:objectName()
			end
			if #min_card > 0 then
				return "#PlusGuidao_Card:" .. min_card[1] .. ":->" .. to:objectName()
			end
		end
	end

	return "."
end

function sgs.ai_cardneed.PlusGuidao(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and
					not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club and self:hasSuit("club", true, to)
			end
		end
	end
end

function sgs.ai_cardneed.PlusLeiji(to, card, self)
	return ((isCard("Jink", card, to) and getKnownCard(to, "Jink", true) == 0)
		or (card:getSuit() == sgs.Card_Spade and self:hasSuit("spade", true, to))
		or (card:isKindOf("EightDiagram") and not (self:isEquip("EightDiagram") or getKnownCard(to, "EightDiagram", false) > 0)))
end

sgs.ai_skill_use["@PlusLeiji"] = function(self, prompt)
	local mode = self.room:getMode()
	if mode:find("_mini_17") or mode:find("_mini_19") or mode:find("_mini_20") or mode:find("_mini_26") then
		local players = self.room:getAllPlayers();
		for _, aplayer in sgs.qlist(players) do
			if aplayer:getState() ~= "robot" then
				return "#PlusLeiji_Card:.:->" .. aplayer:objectName()
			end
		end
	end

	self:updatePlayers()
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasArmorEffect("SilverLion") and not enemy:hasSkill("hongyan") and
			self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and not (enemy:isChained() and not self:isGoodChainTarget(enemy)) and self:canDamage(enemy,self.player,nil) then
			return "#PlusLeiji_Card:.:->" .. enemy:objectName()
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if not enemy:hasSkill("hongyan")
			and not (enemy:isChained() and not self:isGoodChainTarget(enemy)) then
			return "#PlusLeiji_Card:.:->" .. enemy:objectName()
		end
	end

	return "."
end

sgs.ai_card_intention["#PlusLeiji_Card"] = 80

function sgs.ai_slash_prohibit.PlusLeiji(self, to, card)
	if self:isFriend(to) then return false end
	local hcard = to:getHandcardNum()
	if self.player:hasSkill("liegong") and (hcard >= self.player:getHp() or hcard <= self.player:getAttackRange()) then return false end
	if self.role == "rebel" and to:isLord() then
		local other_rebel
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if sgs.ai_role[player:objectName()] == "rebel" or sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and (self:hasSkills("hongyan") or self.player:getHp() >= 4) and (self:getCardsNum("Peach") > 0 or self:hasSkills("hongyan|ganglie|neoganglie")) then
			return false
		end
	end

	if getKnownCard(to, "Jink", true) >= 1 or (self:hasSuit("spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if self:isEquip("EightDiagram", to) and not IgnoreArmor(self.player, to) then return true end
end

local PlusHuangtianQun_skill = {}
PlusHuangtianQun_skill.name = "PlusHuangtianQun"
table.insert(sgs.ai_skills, PlusHuangtianQun_skill)
PlusHuangtianQun_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("ForbidPlusHuangtian") then return nil end
	if self.player:getKingdom() ~= "qun" then return nil end

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Jink") or acard:isKindOf("ThunderSlash") then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = card:getEffectiveId()
	local card_str = "#PlusHuangtian_Card:" .. card_id .. ":"
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)
	return skillcard
end

sgs.ai_skill_use_func["#PlusHuangtian_Card"] = function(card, use, self)
	if self:needBear() or self:getCardsNum("Jink", "h") <= 1 then
		return
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("PlusHuangtian") then
			if not friend:hasFlag("PlusHuangtianInvoked") then
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
	elseif self:getCardsNum("Slash", "he") >= 2 then --黄天对方
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasLordSkill("PlusHuangtian") then
				if not enemy:hasFlag("PlusHuangtianInvoked") then
					if not hasManjuanEffect(enemy) then
						if enemy:isKongcheng() and not enemy:hasSkill("kongcheng") and not hasTuntianEffect(enemy, true) then --必须保证对方空城，以保证天义/陷阵的拼点成功
							table.insert(targets, enemy)
						end
					end
				end
			end
		end
		if #targets > 0 then
			local flag = false
			if self.player:hasSkill("tianyi") and not self.player:hasUsed("TianyiCard") then
				flag = true
			elseif self.player:hasSkill("xianzhen") and not self.player:hasUsed("XianzhenCard") then
				flag = true
			end
			if flag then
				local maxCard = self:getMaxCard(self.player) --最大点数的手牌
				if maxCard:getNumber() > card:getNumber() then --可以保证拼点成功
					self:sort(targets, "defense", true)
					for _, enemy in ipairs(targets) do
						if self.player:canSlash(enemy, nil, false, 0) then --可以发动天义或陷阵
							use.card = card
							enemy:setFlags("AI_HuangtianPindian")
							if use.to then
								use.to:append(enemy)
							end
							break
						end
					end
				end
			end
		end
	end
end

sgs.ai_card_intention.PlusHuangtian_Card = function(self, card, from, tos)
	if tos[1]:isKongcheng() and ((from:hasSkill("tianyi") and not from:hasUsed("TianyiCard"))
			or (from:hasSkill("xianzhen") and not from:hasUsed("XianzhenCard"))) then
	else
		sgs.updateIntention(from, tos[1], -80)
	end
end

sgs.ai_use_priority.PlusHuangtian_Card = 10
sgs.ai_use_value.PlusHuangtian_Card = 8.5

sgs.exclusive_skill = sgs.exclusive_skill .. "|PlusHunzhou"

sgs.bad_skills = sgs.bad_skills .. "|PlusShiyong"


sgs.ai_skill_choice["PlusMizhao_Card"] = function(self, choices, data)
	local items = choices:split("+")
	if #items == 1 then
		return items[1]
	else
		local target = data:toPlayer()
		if self.player:canSlash(target) and self:isEnemy(target) then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:deleteLater()
			if not self:slashProhibit(slash, target) and self.player:canSlash(target, slash, false) and self:isGoodTarget(target, self.enemies, slash) then
				return "PlusMizhao_Use"
			end
		end
	end
	return "PlusMizhao_Draw"
end



PlusMizhao_skill = {}
PlusMizhao_skill.name = "PlusMizhao"
table.insert(sgs.ai_skills, PlusMizhao_skill)
PlusMizhao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#PlusMizhao_Card") then return end
	local use_cards = {}
	local card
	if self:needToThrowArmor() then
		table.insert(use_cards, self.player:getArmor():getEffectiveId())
	end
	if #use_cards < 3 then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if #use_cards < 3 then
				if hcard:isKindOf("Slash") then
					if self:getCardsNum("Slash") > 1 then
						card = hcard
						break
					else
						local dummy_use = self:aiUseCard(hcard)
						if dummy_use and dummy_use.to and (dummy_use.to:length() == 0
								or dummy_use.to:length() == 1 and not self:hasHeavyDamage(self.player, hcard, dummy_use.to:first())) then
							table.insert(use_cards, hcard:getEffectiveId())
						end
					end
				else
					table.insert(use_cards, hcard:getEffectiveId())
				end
			else
				break
			end
		end
	end
	if #use_cards < 3 then
		local ecards = self.player:getCards("e")
		ecards = sgs.QList2Table(ecards)

		for _, ecard in ipairs(ecards) do
			if (ecard:isKindOf("Weapon") or ecard:isKindOf("OffensiveHorse")) and #use_cards < 3 then
				table.insert(use_cards, ecard:getEffectiveId())
			end
		end
	end
	if #use_cards == 3 then
		card = sgs.Card_Parse("#PlusMizhao_Card:" .. table.concat(use_cards, "+") .. ":")
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#PlusMizhao_Card"] = function(card, use, self)
	local target
	local friends = self.friends_noself
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	self.PlusMizhaoTarget = nil

	local canMingceTo = function(player)
		local canGive = not self:needKongcheng(player, true)
		return canGive or (not canGive and self:getEnemyNumBySeat(self.player, player) == 0)
	end

	self:sort(self.enemies, "defense")
	for _, friend in ipairs(friends) do
		if canMingceTo(friend) then
			for _, enemy in ipairs(self.enemies) do
				if friend:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:getDefenseSlash(enemy) <= 2
					and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
					and enemy:objectName() ~= self.player:objectName() then
					target = friend
					self.PlusMizhaoTarget = enemy
					break
				end
			end
		end
		if target then break end
	end

	if not target then
		self:sort(friends, "defense")
		for _, friend in ipairs(friends) do
			if canMingceTo(friend) then
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


sgs.ai_skill_playerchosen.PlusMizhao_Card = function(self, targets)
	if self.PlusMizhaoTarget then return self.PlusMizhaoTarget end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_use_value["#PlusMizhao_Card"] = 5.9
sgs.ai_use_priority["#PlusMizhao_Card"] = 4

sgs.ai_card_intention["#PlusMizhao_Card"] = -70


sgs.ai_skill_invoke.PlusAnxi = function(self, data)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local target = self.room:getCurrent()
	if self:isFriend(target) then return false end
	if target:getHandcardNum() > self.player:getHandcardNum() and not target:isKongcheng() and self.player:canPindian(target) then
		local enemy_max_card = self:getMaxCard(target)
		local allknown = 0
		if self:getKnownNum(target) == target:getHandcardNum() then
			allknown = allknown + 1
		end
		if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
			or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10)
			or (not enemy_max_card and max_point > 10) then
			self.PlusAnxi_card = max_card:getEffectiveId()
			return true
		end
	end
	return false
end


sgs.ai_skill_invoke.PlusAnxidamage = function(self, data)
	return true
end

--[[
sgs.ai_skill_playerchosen.PlusAnxi = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
    for _, enemy in ipairs(targets) do
        if self:isEnemy(enemy) then
        end
    end
end]]

sgs.ai_cardneed.PlusAnxi = sgs.ai_cardneed.bignumber
sgs.ai_skill_playerchosen.PlusAnxi = sgs.ai_skill_playerchosen.damage

local PlusZhuni_skill = {}
PlusZhuni_skill.name = "PlusZhuni"
table.insert(sgs.ai_skills, PlusZhuni_skill)

PlusZhuni_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return end
	local can = false
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
	local card_str = "Collateral:PlusZhuni[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = sgs.Card_Parse(card_str)
	assert(AsCard)
	return AsCard
end

sgs.ai_skill_cardask["@PlusZhuni"] = function(self, data, pattern, target)
	local victim = data:toPlayer()
	if not victim then return "." end
	if self:isFriend(victim) then return "." end
	if self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	local cards = sgs.QList2Table(self.player:getCards("e"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		return "$" .. card:getEffectiveId()
	end
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_skill_use["@PlusKuangjun"] = function(self, prompt, method)
	local arr1, arr2 = self:getWoundedFriend(false, false)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then
		target =
			arr1[1]
	end
	if target then
		return "#PlusKuangjun_Card:.:->" .. target:objectName()
	end


	return "."
end
sgs.ai_card_intention["PlusKuangjun_Card"] = -80



local PlusZhiren_skill = {}
PlusZhiren_skill.name = "PlusZhiren"
table.insert(sgs.ai_skills, PlusZhiren_skill)
PlusZhiren_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#PlusZhiren_Card") then return nil end
	if #self.friends == 0 then return nil end
	local card_str = "#PlusZhiren_Card:.:"
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#PlusZhiren_Card"] = function(card, use, self)
	self:sort(self.friends, "handcard")
	self.friends = sgs.reverse(self.friends)
	local target = self:findPlayerToDraw(true,2)
	if target and not target:isKongcheng() and getKnownCard(target, self.player, "EquipCard", true) + getKnownCard(target, self.player, "TrickCard", true) > 0 then 
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
	for _, friend in ipairs(self.friends) do
		if not friend:isKongcheng() and self:canDraw(friend, self.player) and getKnownCard(friend, self.player, "EquipCard", true) + getKnownCard(friend, self.player, "TrickCard", true) > 0 then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
	for _, friend in ipairs(self.friends) do
		if not friend:isKongcheng() and friend:getHp() < getBestHp(friend) and getKnownCard(friend, self.player, "BasicCard", true) > 0 then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
	if target and not target:isKongcheng() then 
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority["#PlusZhiren_Card"] = 4.2
sgs.ai_card_intention["#PlusZhiren_Card"] = -80

sgs.ai_skill_askforag.PlusZhiren = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	local target
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("PlusZhiren") then
			target = p
			break
		end
	end
	if not target then return -1 end
	for _, card in ipairs(cards) do
		if card:isKindOf("BasicCard") and target:getHp() < getBestHp(target) then
			return card:getEffectiveId()
		end
	end
	for _, card in ipairs(cards) do
		if not card:isKindOf("BasicCard") then
			return card:getEffectiveId()
		end
	end
	return -1
end


sgs.ai_skill_invoke.PlusChenghao = function(self, data)
	local target = self.room:getCurrent()
	if self:isFriend(target) then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.PlusChenghao = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, current, -20)
		end
	end
end


--------------------------------------6.0

sgs.ai_skill_choice.SixWulve = function(self, choices, data)
	local damage = data:toDamage()
	if not damage.card then return "SixWulveDraw" end
	--if damage.card:isKindOf("Slash") and not self:hasCrossbowEffect() and self:getCardsNum("Slash") > 0 then return "SixWulveDraw" end
	if self:isWeak() and (self:getCardsNum("Slash") > 0 or not damage.card:isKindOf("Slash") or self.player:getHandcardNum() <= self.player:getHp()) then
		return
		"SixWulveDraw"
	end
	if damage.card then 
		if damage.card:isVirtualCard() then
			return "SixWulveDraw"
		end
	end
	
	local items = choices:split("+")
	if table.contains(items, "SixWulveGet") then return "SixWulveGet" end
	return items[1]
end

sgs.ai_skill_invoke.SixWulve = function(self, data)
	local target = self.room:getCurrent()
	if target and self:isFriend(target) then
		for _, id in sgs.qlist(self.player:getPile("strategy")) do
			local c = sgs.Sanguosha:getCard(id)
			if c:targetFixed() then
				if c:isKindOf("Peach") and target:isWounded() and target:getHp() <= 2 then
					return true
				end
				if c:isKindOf("ExNihilo") and target:getHandcardNum() <= 2 then
					return true
				end
				if c:isKindOf("SavageAssault") then
					if self:getAoeValue(c) > 0 then
						return true
					end
				end
				if c:isKindOf("ArcheryAttack") then
					if self:getAoeValue(c) > 0 then
						return true
					end
				end
				if c:isKindOf("AmazingGrace") then
					local low_handcard_friend = false
					for _, friend in ipairs(self.friends_noself) do
						if friend:getHandcardNum() <= 4 then
							low_handcard_friend = true
						end
					end
					if low_handcard_friend then
						return true
					end
				end
				if c:isKindOf("GodSalvation") then
					if self:willUseGodSalvation(c) then
						return true
					end
				end
				if c:isKindOf("EquipCard") then
					local equip_index = c:getRealCard():toEquipCard():location()
					if target:getEquip(equip_index) == nil and target:hasEquipArea(equip_index) then
						return true
					end
				end
			else
				if c:isKindOf("Slash") then
					local dummyuse = self:aiUseCard(c)
					local targets = {}
					if not dummyuse.to:isEmpty() then
						for _, p in sgs.qlist(dummyuse.to) do
							return true
						end
					end
				end
				--if use_card:isNDTrick() then
				if c:isKindOf("TrickCard") and not c:isKindOf("Collateral") then
					local dummyuse = self:aiUseCard(c)
					local targets = {}
					if not dummyuse.to:isEmpty() then
						for _, p in sgs.qlist(dummyuse.to) do
							if p:getHp() <= 2 and p:getCards("he"):length() <= 2 and p:getHandcardNum() <= 1 then
								return true
							end
						end
					end
				end
			end

			
		end
	end
	return false
end

sgs.ai_skill_askforag.SixWulve = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByUseValue(cards)
	local target = self.room:getCurrent()
	for _, c in ipairs(cards) do
		if c:targetFixed() then
			if c:isKindOf("Peach") and target:isWounded() and target:getHp() <= 2 then
				return c:getEffectiveId()
			end
			if c:isKindOf("ExNihilo") and target:getHandcardNum() <= 2 then
				return c:getEffectiveId()
			end
			if c:isKindOf("SavageAssault") then
				if self:getAoeValue(c) > 0 then
					return c:getEffectiveId()
				end
			end
			if c:isKindOf("ArcheryAttack") then
				if self:getAoeValue(c) > 0 then
					return c:getEffectiveId()
				end
			end
			if c:isKindOf("AmazingGrace") then
				local low_handcard_friend = false
				for _, friend in ipairs(self.friends_noself) do
					if friend:getHandcardNum() <= 4 then
						low_handcard_friend = true
					end
				end
				if low_handcard_friend then
					return c:getEffectiveId()
				end
			end
			if c:isKindOf("GodSalvation") then
				if self:willUseGodSalvation(c) then
					return c:getEffectiveId()
				end
			end
			if c:isKindOf("EquipCard") then
				local equip_index = c:getRealCard():toEquipCard():location()
				if target:getEquip(equip_index) == nil and target:hasEquipArea(equip_index) then
					return c:getEffectiveId()
				end
			end
			--[[if c:isKindOf("Analeptic") then
                for _, slash in ipairs(self:getCards("Slash")) do
                    if slash:isKindOf("NatureSlash") and slash:isAvailable(self.player) and slash:getEffectiveId() ~= ai_taoluan_card_id then
                        local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
                        self:useBasicCard(slash, dummyuse)
                        if not dummyuse.to:isEmpty() then
                            for _, p in sgs.qlist(dummyuse.to) do
                                if self:shouldUseAnaleptic(p, slash) then
                                    return c:objectName()
                                end
                            end
                        end
                    end
                end
            end]]
		else
			if c:isKindOf("Slash") and self:getCardsNum("Slash") == 0 then
				local dummyuse = self:aiUseCard(c)
				local targets = {}
				if not dummyuse.to:isEmpty() then
					for _, p in sgs.qlist(dummyuse.to) do
						return c:getEffectiveId()
					end
				end
			end
			--if use_card:isNDTrick() then
			if c:isKindOf("TrickCard") and not c:isKindOf("Collateral") then
				local dummyuse = self:aiUseCard(c)
				local targets = {}
				if not dummyuse.to:isEmpty() then
					for _, p in sgs.qlist(dummyuse.to) do
						if p:getHp() <= 2 and p:getCards("he"):length() <= 2 and p:getHandcardNum() <= 1 then
							return c:getEffectiveId()
						end
					end
				end
			end
		end
	end

	return -1
end

sgs.ai_can_damagehp.SixWulve = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return (card:isNDTrick() and card:isDamageCard()) or card:isKindOf("AOE")
	end
end
sgs.ai_target_revises.SixWulve = function(to, card, self)
	if card:isDamageCard()
		and not self:isFriend(to)
		and card:subcardsLength() > 0
	then
		for _, id in sgs.list(card:getSubcards()) do
			if isCard("Peach,Analeptic", sgs.Sanguosha:getCard(id), to)
			then
				return true
			end
		end
	end
end


sgs.ai_skill_use["@@SixWulveOthers!"] = function(self, prompt, method)
	local taoluan_use_card = sgs.Card_Parse(self.player:property("SixWulveCard"):toString())
	taoluan_use_card:setSkillName("SixWulve")

	local dummyuse = self:aiUseCard(taoluan_use_card)
	local targets = {}
	if not dummyuse.to:isEmpty() then
		for _, p in sgs.qlist(dummyuse.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return taoluan_use_card:toString() .. "->" .. table.concat(targets, "+")
		end
	end
	return "."
end


sgs.ai_skill_invoke.SixLangmou = sgs.ai_skill_invoke.fankui

sgs.ai_choicemade_filter.cardChosen.SixLangmou = sgs.ai_choicemade_filter.cardChosen.fankui

sgs.ai_skill_cardchosen.SixLangmou = sgs.ai_skill_cardchosen.fankui

sgs.ai_need_damaged.SixLangmou = sgs.ai_need_damaged.fankui


sgs.use_lion_skill = sgs.use_lion_skill .. "|SixTaohui"


sgs.ai_skill_use["@SixTaohui"] = function(self, prompt, method)
	local cards = {}
	if self:needToThrowArmor(self.player) then
		table.insert(cards, self.player:getArmor():getEffectiveId())
	end
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("e"))) do
		if not table.contains(cards, c:getEffectiveId()) and self:doDisCard(self.player, c:getEffectiveId(), true) then
			table.insert(cards, c:getEffectiveId())
		end
	end
	if #cards > 0 then
		return "#SixTaohuiCard:" .. table.concat(cards, "+") .. ":"
	end
	return "."
end

sgs.wizard_skill = sgs.wizard_skill .. "|SixGuicai"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|SixGuicai"

sgs.ai_skill_use["@@SixGuicai2"] = function(self, prompt)
	local targets = sgs.QList2Table(self.room:getAllPlayers())
	local pindian = self.room:getTag("CurrentPindianStruct"):toPindian()
	local from, to
	for _, p in ipairs(targets) do
		if p:hasFlag("SixGuicaiSource") then
			from = p
		end
		if p:hasFlag("SixGuicaiTarget") then
			to = p
		end
	end
	if from and to and self:isFriend(to) and self:isEnemy(from) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() < pindian.from_card:getNumber() then
			if #cards > 0 then
				return "#SixGuicaiCard:" .. cards[1]:getEffectiveId() .. ":->" .. from:objectName()
			end
		end
	end
	if from and to and self:isFriend(from) and self:isEnemy(to) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() >= pindian.from_card:getNumber() then
			if #cards > 0 then
				return "#SixGuicaiCard:" .. cards[1]:getEffectiveId() .. ":->" .. to:objectName()
			end
		end
	end

	return "."
end


sgs.ai_skill_choice["SixGuicaipindian"] = function(self, choices, data)
	local target

	local targets = sgs.QList2Table(self.room:getAllPlayers())
	for _, p in ipairs(targets) do
		if p:hasFlag("SixGuicaiModify") then
			target = p
		end
	end
	if target then
		if self:isFriend(target) then
			return "13"
		else
			return "1"
		end
	end
	return "1"
end
function sgs.ai_skill_suit.SixGuicai(self)
	local judge = self.room:getTag("CurrentJudgeStruct"):toJudge()
	local who = judge.who
	if judge and self:needRetrial(judge) then
		if judge.reason == "beige" then
			local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
			if damage.from then
				if self:isFriend(damage.from) then
					if not self:toTurnOver(damage.from, 0) and judge.card:getSuit() ~= sgs.Card_Spade then
						return sgs.Card_Spade
					else
						local retr = true
						if (judge.card:getSuit() == sgs.Card_Heart and who:isWounded() and self:isFriend(who))
							or (judge.card:getSuit() == sgs.Card_Diamond and self:isEnemy(who) and hasManjuanEffect(who))
							or (judge.card:getSuit() == sgs.Card_Club and self:needToThrowArmor(damage.from)) then
							retr = false
						end
						if retr then
							if (self:isFriend(who) and who:isWounded()) then
								return sgs.Card_Heart
							elseif self:isEnemy(who) and hasManjuanEffect(who) then
								return sgs.Card_Diamond
							elseif self:isFriend(who) and not hasManjuanEffect(who) then
								return sgs.Card_Diamond
							elseif (self:needToThrowArmor(damage.from) or damage.from:isNude()) then
								return sgs.Card_Club
							elseif self:toTurnOver(damage.from, 0) then
								return sgs.Card_Spade
							end
						end
					end
				else
					if not self:toTurnOver(damage.from, 0) and judge.card:getSuit() == sgs.Card_Spade then
						return sgs.Card_Club
					end
				end
			end
		elseif self:isFriend(who) and not (self:getFinalRetrial() == 2) then
			local newcard = sgs.Sanguosha:cloneCard(judge.card:objectName(), sgs.Card_Diamond, 0)
			newcard:deleteLater()
			if judge:isGood(newcard) then
				return sgs.Card_Diamond
			end
			local newcard = sgs.Sanguosha:cloneCard(judge.card:objectName(), sgs.Card_Heart, 0)
			newcard:deleteLater()
			if judge:isGood(newcard) then
				return sgs.Card_Heart
			end
			local newcard = sgs.Sanguosha:cloneCard(judge.card:objectName(), sgs.Card_Spade, 0)
			newcard:deleteLater()
			if judge:isGood(newcard) then
				return sgs.Card_Spade
			end
			local newcard = sgs.Sanguosha:cloneCard(judge.card:objectName(), sgs.Card_Club, 0)
			newcard:deleteLater()
			if judge:isGood(newcard) then
				return sgs.Card_Club
			end
		elseif self:isEnemy(who) and not (self:getFinalRetrial() == 2) then
			local newcard = sgs.Sanguosha:cloneCard(judge.card:objectName(), sgs.Card_Diamond, 0)
			newcard:deleteLater()
			if not judge:isGood(newcard) then
				return sgs.Card_Diamond
			end
			local newcard = sgs.Sanguosha:cloneCard(judge.card:objectName(), sgs.Card_Heart, 0)
			newcard:deleteLater()
			if not judge:isGood(newcard) then
				return sgs.Card_Heart
			end
			local newcard = sgs.Sanguosha:cloneCard(judge.card:objectName(), sgs.Card_Spade, 0)
			newcard:deleteLater()
			if not judge:isGood(newcard) then
				return sgs.Card_Spade
			end
			local newcard = sgs.Sanguosha:cloneCard(judge.card:objectName(), sgs.Card_Club, 0)
			newcard:deleteLater()
			if not judge:isGood(newcard) then
				return sgs.Card_Club
			end
		end
	end
	local map = { 0, 0, 1, 2, 2, 3, 3, 3 }
	local suit = map[math.random(1, 8)]
	return suit
end

sgs.ai_skill_choice["SixGuicai"] = function(self, choices, data)
	local judge = data:toJudge()
	local items = choices:split("+")
	local target = judge.who
	if target and self:needRetrial(judge) then
		if self:isFriend(target) then
			return "13"
		else
			return items[math.random(3, #items - 3)]
		end
	end
	return items[math.random(1, #items)]
end


sgs.ai_skill_cardask["@SixGuicai"] = function(self, data)
	local judge = data:toJudge()

	--if self.room:getMode():find("_mini_46") and not judge:isGood() then return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		--local card_id = self:getRetrialCardId(cards, judge)
		if #cards > 0 then
			--return "$" .. card_id
			return "#SixGuicaiDummyCard:" .. cards[1]:getEffectiveId() .. ":"
		end
	end

	return "."
end

function sgs.ai_cardneed.SixGuicai(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return to:getCards("h"):length() <= 2 and not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return to:getCards("h"):length() <= 2
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return to:getCards("h"):length() <= 2
			end
		end
	end
end

sgs.ai_skill_cardask["@SixHuwei"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then return "." end
	if self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end

	local has_equip

	for _, card in sgs.qlist(self.player:getCards("e")) do
		if card:isKindOf("EquipCard") and self.player:hasSkills(sgs.lose_equip_skill) then
			has_equip = card
		end
	end

	if has_equip then
		return "$" .. has_equip:getEffectiveId()
	else
		return "."
	end
end

function sgs.ai_armor_value.SixHuwei(player, self, card)
	if not card then return 4 end
end

sgs.ai_skill_invoke.SixJushou = function(self, data)
	if sgs.ai_skill_playerchosen.SixJushou(self, sgs.QList2Table(self.room:getOtherPlayers(self.player))) ~= nil then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.SixJushou = function(self, targets)
	self:updatePlayers()
	self:sort(self.friends_noself, "handcard")
	local target = nil
	local n = math.min(self.player:getMark("SixJushou"), 4)
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not self:toTurnOver(friend, n, "SixJushou") and friend:faceUp() and friend:inMyAttackRange(self.player) then
				target = friend
				break
			end
		end
	end
	if not target then
		if n >= 3 then
			target = self:findPlayerToDraw(false, n)
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "SixJushou") and hasManjuanEffect(enemy) and enemy:faceUp() and enemy:inMyAttackRange(self.player) then
						target = enemy
						break
					end
				end
			end
		else
			self:sort(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if self:toTurnOver(enemy, n, "SixJushou") and hasManjuanEffect(enemy) and enemy:faceUp() and enemy:inMyAttackRange(self.player) then
					target = enemy
					break
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "SixJushou") and self:hasSkills(sgs.priority_skill, enemy) and enemy:faceUp() and enemy:inMyAttackRange(self.player) then
						target = enemy
						break
					end
				end
			end
			if not target then
				for _, enemy in ipairs(self.enemies) do
					if self:toTurnOver(enemy, n, "SixJushou") and enemy:faceUp() and enemy:inMyAttackRange(self.player) then
						target = enemy
						break
					end
				end
			end
		end
	end
	return target
end



sgs.ai_playerchosen_intention.SixJushou = function(self, from, to)
	if hasManjuanEffect(to) then sgs.updateIntention(from, to, 80) end
	local intention = 80 / math.max(from:getMark("SixJushou"), 1)
	if not self:toTurnOver(to, from:getMark("SixJushou"), "SixJushou") then intention = -intention end
	if from:getMark("SixJushou") < 3 then
		sgs.updateIntention(from, to, intention)
	else
		sgs.updateIntention(from, to, math.min(intention, -30))
	end
end

sgs.ai_skill_use["@@SixMingduan"] = function(self, prompt)
	local can_invoke = false
	local target = self.room:getCurrent()
	local slash2 = sgs.Sanguosha:cloneCard("slash")
	slash2:deleteLater()
	if self.room:alivePlayerCount() <= 2 or #self.friends_noself < 1 then return "." end

	if self:isEnemy(target) then
		if target:isJilei(slash2) then can_invoke = true end

		if target:hasSkills("guose|qixi|duanliang|ol_duanliang|luanji") and target:getHandcardNum() > 1 then can_invoke = true end
		if target:hasSkills("shuangxiong") and not self:isWeak(target) then can_invoke = true end
		if not self:slashIsEffective(slash2, self.player, target) and not self:isWeak() then can_invoke = true end
		if self.player:getArmor() and self.player:getArmor():isKindOf("Vine") and not self:isWeak() then can_invoke = true end
		if self.player:getArmor() and not self:isWeak() and self:getCardsNum("Jink") > 0 then can_invoke = true end
	end

	local use_card
	local slashtarget
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if c:isBlack() then
			use_card = c
			break
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not target:isProhibited(enemy, slash2) and self:slashIsEffective(slash2, enemy) then
			slashtarget = enemy
			break
		end
	end
	if use_card and can_invoke and slashtarget then
		return "#SixMingduanCard:" .. use_card:getEffectiveId() .. ":"
	end
	return "."
end


sgs.ai_skill_playerchosen.SixMingduan = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end


sgs.ai_skill_invoke.SixQiaoxie = function(self, data)
	local target = data:toPlayer()
	if target and not self:isEnemy(target) and #self.enemies > 0 and self:getCardsNum("Slash") >= 1 and not self:needBear() then
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		self.player:setFlags("slashNoDistanceLimit")
		local dummy_use = self:aiUseCard(slash)
		self.player:setFlags("-slashNoDistanceLimit")
		if not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				if not self.player:inMyAttackRange(p) then
					return true
				end
			end
		end
	end
	return false
end

sgs.ai_skill_cardask["@SixQiaoxie"] = function(self, data, pattern, target)
	local target = self.room:getCurrent()
	if target and self:isFriend(target) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isBlack() then
				return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@SixQiaoxie"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		--local current = self.player:getTag("sidi_target"):toPlayer()
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, -60)
	end
end




sgs.ai_skill_use["@@SixZhidi"] = function(self, prompt)
	local use_card
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)

	if #cards > 0 then
		return "#SixZhidiCard:" .. cards[1]:getEffectiveId() .. ":"
	end
	return "."
end



sgs.ai_skill_invoke.SixZhidi = function(self, data)
	local use = data:toCardUse()

	if use.card then
		if use.card:isKindOf("Peach") then return false end
		return not (use.card:isKindOf("Slash") and self:isPriorFriendOfSlash(self.player, use.card, use.from))
	end
end


local SixChouzuan_skill = {}
SixChouzuan_skill.name = "SixChouzuan"
table.insert(sgs.ai_skills, SixChouzuan_skill)
SixChouzuan_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return end
	if self.player:hasUsed("#SixChouzuanCard") then return nil end
	return sgs.Card_Parse("#SixChouzuanCard:.:")
end

sgs.ai_skill_use_func["#SixChouzuanCard"] = function(card, use, self)
	local maxvalue = 0
	local target
	for _, friend in ipairs(self.friends_noself) do
		local value = 0
		local enemies = {}
		for _, enemy in ipairs(self.enemies) do
			if friend:inMyAttackRange(enemy) then table.insert(enemies, enemy) end
		end
		if #enemies == 0 then return end
		self:sort(enemies, "hp")

		-- find cards
		local card_ids = {}

		local zcards = self.player:getHandcards()
		local use_slash, keep_jink, keep_analeptic = false, false, false
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if zcard:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then shouldUse = false end
				end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(card_ids, zcard:getId()) end
			end
		end

		if #card_ids >= friend:getAttackRange() then
			for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if friend:inMyAttackRange(p) then
					value = value + 1
				end
			end
		end
		if value > maxvalue then
			maxvalue = value
			target = friend
		end
	end
	if maxvalue > 0 and target then
		use.card = sgs.Card_Parse("#SixChouzuanCard:.:")
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_priority["#SixChouzuanCard"] = 0.6
sgs.ai_use_value["#SixChouzuanCard"] = 2.45
sgs.ai_card_intention["#SixChouzuanCard"] = -80



sgs.ai_skill_choice["SixChouzuan"] = function(self, choices, data)
	local current = self.room:getCurrent()
	if (self:needToLoseHp(self.player, nil, nil)) and not self:isWeak() then
		return "SixChouzuanDamage"
	end
	return "SixChouzuanDraw"
end



sgs.ai_skill_playerchosen.SixWeiyuan = function(self, targets)
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
	if self.player:getEquips():length() > 2 then
		for _, friend in ipairs(self.friends_noself) do
			if (self:hasSkills(sgs.lose_equip_skill, friend)
				or (hasTuntianEffect(friend, true)) or self:hasSkills(sgs.need_equip_skill, friend)) and friend:getEquips():length() < self.player:getEquips():length() then
				return friend
			end
		end
	end

	target = nil
	if self:needToThrowArmor(self.player) or ((self:hasSkills(sgs.lose_equip_skill, self.player)
				or (hasTuntianEffect(self.player, true)))
			and not self.player:getEquips():isEmpty()) then
		target = self.player
	end
	if not target then return end
	for _, friend in ipairs(self.friends_noself) do
		if (self:hasSkills(sgs.lose_equip_skill, friend)
			or (hasTuntianEffect(friend, true)) or self:hasSkills(sgs.need_equip_skill, friend)) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		return friend
	end

	return nil
end


sgs.ai_cardneed.SixTaichen = sgs.ai_cardneed.slash

local SixTaichen_skill = {
	name = "SixTaichen",
	getTurnUseCard = function(self, inclusive)
		if self:getCardsNum("Slash") == 0 then return end
		if self.player:hasUsed("#SixTaichenCard") then return end
		local can_use = false
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:isNude() then continue end
			if self.player:inMyAttackRange(p) then
				can_use = true
				break
			end
		end
		if can_use then
			return sgs.Card_Parse("#SixTaichenCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, SixTaichen_skill) --加入AI可用技能表
sgs.ai_skill_use_func["#SixTaichenCard"] = function(card, use, self)
	local handcards = self.player:getHandcards()
	local slashs = {}
	for _, c in sgs.qlist(handcards) do
		if c:isKindOf("Slash") then
			if self.player:canDiscard(self.player, c:getEffectiveId()) then
				table.insert(slashs, c)
			end
		end
	end
	if #slashs == 0 then return end
	self:sort(self.enemies, "chaofeng")
	local enemys = {}
	for _, enemy in ipairs(self.enemies) do
		if not self.player:inMyAttackRange(enemy) then continue end
		if self:cantbeHurt(enemy) then continue end
		if not self:canDamage(enemy,self.player,nil) then continue end
		if not self:damageIsEffective(enemy, sgs.DamageStruct_Normal) then continue end
		if self:getCardsNum("Slash") - 1 < getCardsNum("Slash", enemy) and self.player:getHp() <= enemy:getHp() then continue end
		table.insert(enemys, enemy)
	end
	if #enemys > 0 then
		local card_str = string.format("#SixTaichenCard:%s:", slashs[1]:getEffectiveId())
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then use.to:append(enemys[1]) end
	end
end

local SixRende_skill = {}
SixRende_skill.name = "SixRende"
table.insert(sgs.ai_skills, SixRende_skill)
SixRende_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	if self.player:getHandcardNum() <= 1 and self.player:getMaxCards() > 0 and self.player:getMark("SixRende") == 0 then return end
	local mode = string.lower(global_room:getMode())
	if self.player:getMark("SixRende") > 1 and mode:find("04_1v3") then return end

	if self.player:isWounded() then
		if self.player:getMark("SixRende") > 1 and self:getOverflow() <= 0 then return end
	end

	if self:shouldUseRende() then
		return sgs.Card_Parse("#SixRendeCard:.:")
	end
end

sgs.ai_skill_use_func["#SixRendeCard"] = function(card, use, self)
	--防血少時有兩張手牌只給一張的情況
	if self.player:getHp() < 3 and self.player:isWounded() and self.player:getHandcardNum() == 2 then
		self:sort(self.friends_noself, "handcard")
		local give_all_cards = {}
		for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
			table.insert(give_all_cards, c:getEffectiveId())
		end
		local targets = {}
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				table.insert(targets, friend)
			end
		end
		if #targets > 0 and #give_all_cards > 1 then
			local card_str = string.format("#SixRendeCard:" .. table.concat(give_all_cards, "+") .. ":")
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then
				use.to:append(targets[1])
			end
			return
		end
	end

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	local notFound

	for i = 1, self.player:getHandcardNum() do
		local card, friend = self:getCardNeedPlayer(cards)
		if card and friend then
			cards = self:resetCards(cards, card)
		else
			notFound = true
			break
		end

		if friend:objectName() == self.player:objectName() or not self.player:getHandcards():contains(card) then continue end
		local canJijiang = self.player:hasLordSkill("jijiang") and friend:getKingdom() == "shu"
		if card:isAvailable(self.player) and ((card:isKindOf("Slash") and not canJijiang) or card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card
			then
				if card:isKindOf("Slash") or card:isKindOf("Duel") then
					local t1 = dummy_use.to:first()
					if dummy_use.to:length() > 1 then
						continue
					elseif t1:getHp() == 1 or getCardsNum("Jink",t1,self.player)<1
						or t1:isCardLimited(sgs.Sanguosha:cloneCard("jink"), sgs.Card_MethodResponse) then
						continue
					end
				elseif (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and self:getEnemyNumBySeat(self.player, friend) > 0 then
					local hasDelayedTrick
					for _, p in sgs.qlist(dummy_use.to) do
						if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p)) then
							hasDelayedTrick = true
							break
						end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif card:isAvailable(self.player) and self:getEnemyNumBySeat(self.player, friend) > 0 and (card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then continue end
		end

		if friend:hasSkill("enyuan") and #cards >= 1 and not (self.room:getMode() == "04_1v3" and ((self.player:getHandcardNum() + 2 > self.player:getMaxCards()) or (self.player:isWounded() and self.player:getMark("SixRende") < 2))) then
			use.card = sgs.Card_Parse("#SixRendeCard:" .. card:getId() .. "+" .. cards[1]:getId() .. ":")
		else
			use.card = sgs.Card_Parse("#SixRendeCard:" .. card:getId() .. ":")
		end
		if use.to then use.to:append(friend) end
		return
	end

	if notFound then

		if self.player:getMark("SixRende") <= 1 or (self.player:getHandcardNum() + 2 < self.player:getMaxCards() and not self.player:isWounded()) or self:getOverflow() > 0 then
			local cards = sgs.QList2Table(self.player:getHandcards())
			self:sortByUseValue(cards, true)
			self:sort(self.friends_noself, "handcard")
			local give_all_cards = {}
			for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
				table.insert(give_all_cards, c:getEffectiveId())
			end
			local targets = {}
			for _, friend in ipairs(self.friends_noself) do
				if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
					table.insert(targets, friend)
				end
			end
			if #targets > 0 and #give_all_cards > 1 then
				local card_str = string.format("#SixRendeCard:" .. give_all_cards[1] .. ":")
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				if use.to then
					use.to:append(targets[1])
				end
				return
			end
		end



		local pangtong = self.room:findPlayerBySkillName("manjuan")
		if not pangtong then pangtong = self.room:findPlayerBySkillName("zishu") end
		if not pangtong then return end
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByUseValue(cards, true)
		if ((self.player:getHandcardNum() + 2 > self.player:getMaxCards()) or (self.player:isWounded() and self.player:getMark("SixRende") < 2)) then
			self:sortByUseValue(cards, true)
			local to_give = {}
			for _, card in ipairs(cards) do
				if not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) then
					table.insert(to_give, card:getId())
				end
				if #to_give == 2 - self.player:getMark("SixRende") then break end
			end
			if #to_give > 0 then
				use.card = sgs.Card_Parse("#SixRendeCard:" .. table.concat(to_give, "+") .. ":")
				if use.to then use.to:append(pangtong) end
			end
		end
	end
end

sgs.ai_use_value["SixRendeCard"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["SixRendeCard"] = sgs.ai_use_priority.RendeCard

sgs.ai_card_intention["SixRendeCard"] = sgs.ai_card_intention.RendeCard

sgs.dynamic_value.benefit["SixRendeCard"] = true



sgs.ai_skill_choice.SixRende = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "SixRendeRecover") then
		if self.player:getHp() < getBestHp(self.player) then
			return "SixRendeRecover"
		end
	end

	if table.contains(items, "SixRendeDraw") then
		return "SixRendeDraw"
	end

	return "SixRendeCancel"
end

sgs.ai_use_revises.SixRende = function(self,card,use)
	if self.player:getLostHp()>1 and self:findFriendsByType(sgs.Friend_Draw) and self.player:getMark("SixRende") < 2 then
		if card:getTypeId()==1 
		or card:getTypeId()==3 and self:getSameEquip(card)
		or card:getTypeId()==2 and not (card:targetFixed() and card:isDamageCard())
		then return false end
	end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|SixRende"

local SixPaoxiao_skill = {}
SixPaoxiao_skill.name = "SixPaoxiao"
table.insert(sgs.ai_skills, SixPaoxiao_skill)

SixPaoxiao_skill.getTurnUseCard = function(self, inclusive)
	if not sgs.Slash_IsAvailable(self.player) then return nil end
	if self.player:hasFlag("SixPaoxiaoForbidden") then return nil end
	if not self.player:canSlashWithoutCrossbow() then return nil end

	return sgs.Card_Parse("#SixPaoxiaoCard:.:")
end

sgs.ai_skill_use_func["#SixPaoxiaoCard"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	self.MingceTarget = nil
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			and enemy:objectName() ~= self.player:objectName() then
			self.MingceTarget = enemy
			break
		end
	end

	if self.MingceTarget then
		use.card = sgs.Card_Parse("#SixPaoxiaoCard:.:")
		if use.to then
			use.to:append(self.MingceTarget)
		end
	end
end

function sgs.ai_cardneed.SixPaoxiao(to,card,self)
	return card:isKindOf("Crossbow")
end

sgs.ai_use_value["SixPaoxiaoCard"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["SixPaoxiaoCard"] = sgs.ai_use_priority.Slash + 1


sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|SixLongdan"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|SixLongdan"

sgs.ai_skill_use["@@SixLongdan2"] = function(self, data, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")

	local card_str = ("slash:SixLongdan[%s:%s]=."):format("to_be_decided", 0)
	local use_card = sgs.Card_Parse(card_str)
	use_card:setSkillName("SixLongdan")
	local dummy_use = self:aiUseCard(use_card,dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			if self:getDefenseSlash(p) < 6 then
				table.insert(targets, p:objectName())
			end
		end
		if #targets > 0 then
			return use_card:toString() .. "->" .. table.concat(targets, "+")
		end
	end


	return "."
end

sgs.ai_skill_use["@@SixLongdan1"] = function(self, data, method)
	local target
	local use_card
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("SixLongdan_Target") then
			target = p
			break
		end
	end
	if target and self:isFriend(target) and self.player:getMark("SixLongdan_using") == 0 then
		local shouldUse = false

		local defense = 6
		local use = self.room:getTag("CurrentUseStruct"):toCardUse()

		local def = sgs.getDefense(target)
		local slash = use.card
		local eff = self:slashIsEffective(slash, target)
		if use.card and self:hasHeavyDamage(use.from, use.card, target) then
			shouldUse = true
		end
		if not use.from:canSlash(target, slash, false) then
		elseif self:slashProhibit(nil, target) then
		elseif eff then
			if target:getHp() == 1 and getCardsNum("Jink", target) == 0 then shouldUse = true end
			shouldUse = true
		end
		for _, card in ipairs(cards) do
			if not card:isKindOf("Peach") and not self.player:isCardLimited(card, method) and card:isKindOf("BasicCard") then
				use_card = card
				break
			end
		end
		if use_card and self:isFriend(target) then
			sgs.updateIntention(self.player, target, -70)
			return "#SixLongdanCard:" .. use_card:getEffectiveId() .. ":"
		end
	end
	return "."
end



local SixSance_skill = {}
SixSance_skill.name = "SixSance"
table.insert(sgs.ai_skills, SixSance_skill)
SixSance_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#SixSanceCard") then
		return sgs.Card_Parse("#SixSanceCard:.:")
	end
end

sgs.ai_skill_use_func["#SixSanceCard"] = function(card, use, self)
	local target = nil
	self:updatePlayers()
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		target = friend
	end
	if target then
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		local discard_cards = {}
		local spade_check = true
		local heart_check = true
		local club_check = true
		local diamond_check = true
		self:sortByUseValue(handcards)
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
				if #discard_cards == 3 then
					break
				end
			end
		end

		if #discard_cards == 3 and target then
			local card_str = string.format("#SixSanceCard:%s:", table.concat(discard_cards, "+"))
			use.card = sgs.Card_Parse(card_str)
			if use.to then use.to:append(target) end
		end
	end
end


sgs.ai_skill_askforag.SixSance = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByCardNeed(to_obtain, true)
	if self:isWeak() then
		for card_id in ipairs(card_ids) do
			if sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Heart then
				return card_id
			end
		end
	end
	local target
	for _,friend in ipairs(self.friends_noself)do
		if friend:hasFlag("SixSance_from") then
			target = friend
			break
		end
	end
	if target and self:isWeak(target) then
		for card_id in ipairs(card_ids) do
			if sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Diamond then
				return card_id
			end
		end
	end
	if target then
		for card_id in ipairs(card_ids) do
			if sgs.Sanguosha:getCard(card_id):isBlack() then
				return card_id
			end
		end
	end
	for card_id in ipairs(card_ids) do
		if sgs.Sanguosha:getCard(card_id):getSuit() == sgs.Card_Spade then
			return card_id
		end
	end

	return to_obtain[1]:getEffectiveId()
end
sgs.ai_use_priority["SixSanceCard"] = 3
sgs.ai_use_value["SixSanceCard"] = 3
sgs.ai_card_intention["SixSanceCard"] = -80

function sgs.ai_cardneed.SixQucai(to, card)
	return card:getTypeId() == sgs.Card_TypeTrick
end

sgs.ai_skill_invoke.SixZhongyong = function(self, data)
	local target = data:toPlayer()
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	if not self:isFriend(target) or self:isFriend(use.from) then return false end
	if use.card and use.card:isKindOf("Slash") then
		if target:hasSkills("liuli|tianxiang|ol_tianxiang") and target:getHandcardNum() > 1 then return false end
		if not self:slashIsEffective(use.card, target, use.from) then return false end
		if self:getCardsNum("Jink") > 0 then return true end
	end
	if self:needToLoseHp(target, use.from, use.card) then return false end
	if self.player:getHandcardNum() + self.player:getEquips():length() < 2 and not self:isWeak(target) then return false end


	if self:isWeak(target) and not self:isWeak() then return true end

	return false
end


sgs.ai_skill_use["@@SixChouyuan"] = function(self, data, method)
	self:updatePlayers()
	self:sort(self.friends, "hp")
	for _, friend in ipairs(self.friends) do
		if friend:getHp() <= 3 and friend:isWounded() and self:canDraw(friend, self.player) then
			return "#SixChouyuanCard:.:->" .. friend:objectName()
		end
	end
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if enemy:isWounded() and (enemy:getHp() > 3 and not enemy:isKongcheng()) and self:doDisCard(enemy, "h") then
			return "#SixChouyuanCard:.:->" .. enemy:objectName()
		end
	end


	return "."
end

sgs.ai_skill_invoke.SixWujun = function(self, data)
	local target = self.room:getCurrent()
	if target and self:isEnemy(target) then
		return true
	end

	return false
end

sgs.ai_choicemade_filter.skillInvoke.SixWujun = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local current = self.room:getCurrent()
		sgs.updateIntention(player, current, 50)
	end
end

sgs.ai_skill_cardask["@SixWujun"] = function(self, data, pattern, target, target2)
	if target and self:isFriend(target) and not self:findLeijiTarget(target, 50, self.player) then
		return "."
	end
	if not self.player:canSlash(target, false) then return "." end

	local use_card
	if not target:hasSkill("yizhong") and not target:hasArmorEffect("renwang_shield") and not target:hasArmorEffect("vine") then
		local cards = sgs.QList2Table(self.player:getHandcards())


		self:sortByKeepValue(cards)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		for _, card in ipairs(cards) do
			if self:getKeepValue(card, cards) <= self:getKeepValue(slash, cards) then
				local black_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
				black_slash:deleteLater()
				black_slash:addSubcard(card)
				if self:slashIsEffective(black_slash, target) then
					use_card = card
					break
				end
			end
		end
	end
	if self:needKongcheng(self.player, true) and self.player:getHandcardNum() == 1 then
		use_card = self.player:getHandcards():first()
	end
	if use_card then
		local black_slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		black_slash:setSkillName("SixWujun")
		black_slash:addSubcard(use_card)
		return black_slash:toString()
	end
	return "."
end

sgs.ai_target_revises.SixWujun = function(to, card, self)
	if card:isKindOf("DefensiveHorse") or card:isKindOf("OffensiveHorse")
	then
		return true
	end
end


local SixWuzhi_skill = {}
SixWuzhi_skill.name = "SixWuzhi"
table.insert(sgs.ai_skills, SixWuzhi_skill)
SixWuzhi_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#SixWuzhiCard") then
		return sgs.Card_Parse("#SixWuzhiCard:.:")
	end
end

sgs.ai_skill_use_func["#SixWuzhiCard"] = function(card, use, self)
	local target = nil
	self:updatePlayers()
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if friend:getJudgingArea():length() > 0 then
			for _, judge in sgs.qlist(friend:getJudgingArea()) do
				if not judge:isKindOf("YanxiaoCard") then
					target = friend
					break
				end
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getEquips():length() > 0 and friend:hasSkills(sgs.lose_equip_skill) then
				target = friend
				break
			end
		end
	end
	if not target then
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(handcards)
		local cards = {}
		for _, c in ipairs(handcards) do
			if c:isKindOf("Slash") then
				table.insert(cards,c)
			end
		end
		if #cards > 0 then
			local c,to = self:getCardNeedPlayer(cards,false)
			if c and to then
				target = to
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getEquips():length() > 0 and not enemy:hasSkills(sgs.lose_equip_skill) then
				target = enemy
				break
			end
		end
	end
	if target then
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByUseValue(handcards)
		local use_card
		for _, c in ipairs(handcards) do
			if c:isKindOf("Slash") then
				use_card = c
			end
		end

		if use_card and target then
			use.card = sgs.Card_Parse("#SixWuzhiCard:" .. use_card:getEffectiveId() .. ":")
			if use.to then use.to:append(target) end
		end
	end
end

sgs.ai_skill_choice.SixWuzhi = function(self, choices, data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items, "SixWuzhiGet") then
		if self:isFriend(target) then
			if self:doDisCard(target, "ej", true) then
				return "SixWuzhiGet"
			end
		else
			return "SixWuzhiGet"
		end
	end
	if table.contains(items, "SixWuzhiDiscard") then
		if self:isEnemy(target) and self:doDisCard(target, "h", false, 2) then
			return "SixWuzhiDiscard"
		end
	end
	return "SixWuzhiCancel"
end

sgs.ai_choicemade_filter.cardChosen.SixWuzhiCard = sgs.ai_choicemade_filter.cardChosen.snatch


function sgs.ai_cardneed.SixWuzhi(to, card, self)
	return isCard("Slash", card, to) and getKnownCard(to, self.player, "Slash", true) == 0
end

sgs.ai_skill_invoke.SixHusi = function(self, data)
	local move = data:toMoveOneTime()
	if self.player:isLord() and self:isWeak() then return false end
	if move.from and self:isFriend(move.from) and move.to and not self:isFriend(move.to) then
		return move.card_ids:length() >= 2 or self:isWeak(move.from)
	end
	if move.from and move.from:objectName() == self.player:objectName() then return not self:isWeak() end

	return false
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|SixToujing"

sgs.ai_skill_playerchosen.SixToujing = function(self, targets)
	local first, second
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) and friend:isAlive() and not (hasManjuanEffect(friend) and friend:getLostHp() == 0) then
			if isLord(friend) and self:isWeak(friend) then return friend end
			if not (friend:hasSkill("zhiji") and friend:getMark("zhiji") == 0 and not self:isWeak(friend) and friend:getPhase() == sgs.Player_NotActive) then
				if sgs.ai_role[friend:objectName()] == "renegade" then
					second = friend
				elseif sgs.ai_role[friend:objectName()] ~= "renegade" and not first then
					first = friend
				end
			end
		end
	end
	if first then return first end
	if second then return second end
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) then
			return friend
		end
	end
	return targets[1]
end

sgs.ai_use_revises.SixToujing = function(self,card,use)
	if card:isKindOf("FireAttack") then
		if self:getAllPeachNum() + self.player:getHp() == 1 and self.player:getHandcardNum() > 1 and self:hasTrickEffective(card, self.player) and self:damageIsEffective(self.player, sgs.DamageStruct_Fire) and not self.player:isChained() then
			use.card = card
			use.to:append(self.player)
			return true
		end
	end
end

sgs.ai_skill_invoke.PlusYingwu = function(self, data)
	return not (self.player:hasSkill("yingzi") and self.player:hasSkill("yinghun"))
end


sgs.ai_skill_cardask["@PlusYingwu"] = function(self, data, pattern, target, target2)
	local use_card
	local cards = sgs.QList2Table(self.player:getHandcards())
	if self:needToLoseHp() then return "." end

	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		use_card = card
		break
	end
	if self:needToThrowArmor() then use_card = self.player:getArmor() end
	if self:needKongcheng(self.player, true) and self.player:getHandcardNum() == 1 then
		use_card = self.player:getHandcards():first()
	end
	if use_card then
		return use_card:toString()
	end
	return "."
end


sgs.ai_skill_choice.PlusYingwu = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "yinghun") then
		if self.player:getLostHp() > 2 then
			return "yinghun"
		end
	end
	return "yingzi"
end


sgs.ai_skill_invoke.SixLiangjie = function(self, data)
	return self.player:wholeHandCards():isBlack() or self.player:wholeHandCards():isRed()
end

sgs.ai_skill_invoke.SixLiangjieDraw = function(self, data)
	return true
end


sgs.ai_skill_cardask["@SixZenhui"] = function(self, data, pattern, target, target2)
	local current = self.room:getCurrent()
	if current and self:isEnemy(current) then
		local use_card
		local cards = sgs.QList2Table(self.player:getHandcards())

		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Spade then
				use_card = card
				break
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if current:inMyAttackRange(friend) then
				if use_card then
					return use_card:toString()
				end
			end
		end
	end
	return "."
end



sgs.ai_skill_playerchosen["SixZenhui"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and (not self:needKongcheng(p, true) or hasManjuanEffect(p)) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention["SixZenhui"] = function(self, from, to)
	sgs.updateIntention(from, to, -30)
end

sgs.ai_skill_playerchosen.SixJiahuo = function(self, targets)
	for _,p in ipairs(self:findPlayerToDiscard("h", false, false, targets))do
		return p
	end
	return nil
end

sgs.ai_skill_invoke.SixJiahuoSecond = function(self, data)
	return true
end


local SixChunlao_skill = {}
SixChunlao_skill.name = "SixChunlao"
table.insert(sgs.ai_skills, SixChunlao_skill)
SixChunlao_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() or self.player:hasUsed("#SixChunlaoCard") then return nil end
	return sgs.Card_Parse("#SixChunlaoCard:.:")
end

sgs.ai_skill_use_func["#SixChunlaoCard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	self:sort(self.enemies, "defense")

	sgs.ai_use_priority["#SixChunlaoCard"] = 0.2
	local suit_table = { "spade", "club", "heart", "diamond" }
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > 0 then
			local max_suit_num, max_suit = 0, {}
			for i = 0, 3, 1 do
				local suit_num = getKnownCard(enemy, self.player, suit_table[i + 1])
				if suit_num > max_suit_num then
					max_suit_num = suit_num
					max_suit = { i }
				elseif suit_num == max_suit_num then
					table.insert(max_suit, i)
				end
			end
			if max_suit_num == 0 then
				max_suit = {}
				local suit_value = { 1, 1, 1.3, 1.5 }
				for _, skill in ipairs(sgs.getPlayerSkillList(enemy)) do
					if sgs[skill:objectName() .. "_suit_value"] then
						for i = 1, 4, 1 do
							local v = sgs[skill:objectName() .. "_suit_value"][suit_table[i]]
							if v then suit_value[i] = suit_value[i] + v end
						end
					end
				end
				local max_suit_val = 0
				for i = 0, 3, 1 do
					local suit_val = suit_value[i + 1]
					if suit_val > max_suit_val then
						max_suit_val = suit_val
						max_suit = { i }
					elseif suit_val == max_suit_val then
						table.insert(max_suit, i)
					end
				end
			end
			for _, card in ipairs(cards) do
				if self:getUseValue(card) < 6 and not (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
					use.card = sgs.Card_Parse("#SixChunlaoCard:" .. card:getEffectiveId() .. ":")
					if use.to then use.to:append(enemy) end
					return
				end
			end
			if getCardsNum("Peach", enemy, self.player) < 2 then
				for _, card in ipairs(cards) do
					if self:getUseValue(card) < 6 and not self:isValuableCard(card) and not (card:isKindOf("Peach") or card:isKindOf("Analeptic")) then
						use.card = sgs.Card_Parse("#SixChunlaoCard:" .. card:getEffectiveId() .. ":")
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
			if self:getOverflow() > 0 then
				for _, card in ipairs(cards) do
					use.card = sgs.Card_Parse("#SixChunlaoCard:" .. card:getEffectiveId() .. ":")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_card_intention["#SixChunlaoCard"] = function(self, card, from, tos)
	local to = tos[1]
	sgs.updateIntention(from, to, 60)
end

sgs.ai_use_priority["#SixChunlaoCard"] = 0.2


function sgs.ai_cardsview_valuable.SixChunlao(self, class_name, player)
	if class_name == "Peach" and player:getPile("beer"):length() > 0 then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if dying then
			local analeptic = sgs.Sanguosha:cloneCard("analeptic")
			analeptic:deleteLater()
			if dying:isLocked(analeptic) then return nil end

			local give_card = {}
			for _, card_id in sgs.qlist(self.player:getPile("beer")) do
				table.insert(give_card, sgs.Sanguosha:getCard(card_id))
			end
			self:sortByKeepValue(give_card)



			local diamond_cards = {}
			local heart_cards = {}
			local spade_cards = {}
			local club_cards = {}
			local use_cards = {}

			for _, c in ipairs(give_card) do
				if c:getSuit() == sgs.Card_Diamond then
					table.insert(diamond_cards, c:getEffectiveId())
				elseif c:getSuit() == sgs.Card_Heart then
					table.insert(heart_cards, c:getEffectiveId())
				elseif c:getSuit() == sgs.Card_Spade then
					table.insert(spade_cards, c:getEffectiveId())
				elseif c:getSuit() == sgs.Card_Club then
					table.insert(club_cards, c:getEffectiveId())
				end
			end

			if #diamond_cards >= 2 then
				table.insert(use_cards, diamond_cards[1])
				table.insert(use_cards, diamond_cards[2])
			elseif #heart_cards >= 2 then
				table.insert(use_cards, heart_cards[1])
				table.insert(use_cards, heart_cards[2])
			elseif #spade_cards >= 2 then
				table.insert(use_cards, spade_cards[1])
				table.insert(use_cards, spade_cards[2])
			elseif #club_cards >= 2 then
				table.insert(use_cards, club_cards[1])
				table.insert(use_cards, club_cards[2])
			end
			if #use_cards > 0 then
				return "#SixChunlaoWineCard:" .. use_cards[1] .. "+" .. use_cards[2] .. ":"
			end
		end
	end
end

sgs.ai_card_intention.SixChunlaoWineCard = sgs.ai_card_intention.Peach

sgs.save_skill = sgs.save_skill .. "|SixChunlao"

sgs.ai_skill_invoke.SevenMizhao = function(self, data)
	return sgs.ai_skill_playerchosen.SevenMizhao(self, self.room:getOtherPlayers(self.player)) ~= nil
end

sgs.ai_skill_playerchosen.SevenMizhao = function(self, targets)
	if (sgs.ai_skill_invoke.fangquan(self) or self:needKongcheng(self.player)) then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		if sgs.playerRoles["rebel"] == 0 then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) and lord:objectName() ~= self.player:objectName() and not hasManjuanEffect(lord) then
				return lord
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and not hasManjuanEffect(AssistTarget) then
			return AssistTarget
		end

		for _, friend in ipairs(self.friends_noself) do
			if not hasManjuanEffect(friend) and friend:hasSkills(sgs.cardneed_skill) then
				return friend
			end
		end

		self:sort(self.friends_noself, "chaofeng")
		for _, friend in ipairs(self.friends_noself) do
			if not hasManjuanEffect(friend) then
				return friend
			end
		end
		--return self.friends_noself[1]
	end
	return nil
end

sgs.ai_playerchosen_intention.SevenMizhao = -80

sgs.ai_choicemade_filter.cardResponded["SevenJiujiajink"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if sgs.SevenJiujia then
            sgs.updateIntention(player, sgs.SevenJiujia, -80)
		    sgs.SevenJiujia = nil
        end
    elseif sgs.SevenJiujia then
        local lieges = player:getRoom():getOtherPlayers(sgs.SevenJiujia)
        if lieges and not lieges:isEmpty() then
            if player:objectName() == lieges:last():objectName() then
                sgs.SevenJiujia = nil
            end
        end
    end
end

sgs.ai_skill_cardask["SevenJiujiajink"] = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return "." end
	return self:getCardId("Jink") or "."
end

sgs.ai_choicemade_filter.cardResponded["SevenJiujiaslash"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if sgs.SevenJiujia then
            sgs.updateIntention(player, sgs.SevenJiujia, -80)
		    sgs.SevenJiujia = nil
        end
    elseif sgs.SevenJiujia then
        local lieges = player:getRoom():getOtherPlayers(sgs.SevenJiujia)
        if lieges and not lieges:isEmpty() then
            if player:objectName() == lieges:last():objectName() then
                sgs.SevenJiujia = nil
            end
        end
    end
end
sgs.ai_skill_cardask["SevenJiujiaslash"] = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return "." end
	return self:getCardId("Slash") or "."
end

sgs.ai_choicemade_filter.cardResponded["SevenJiujiapeach"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if sgs.SevenJiujia then
            sgs.updateIntention(player, sgs.SevenJiujia, -80)
		    sgs.SevenJiujia = nil
        end
    elseif sgs.SevenJiujia then
        local lieges = player:getRoom():getOtherPlayers(sgs.SevenJiujia)
        if lieges and not lieges:isEmpty() then
            if player:objectName() == lieges:last():objectName() then
                sgs.SevenJiujia = nil
            end
        end
    end
end

sgs.ai_skill_cardask["SevenJiujiapeach"] = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return "." end
	return self:getCardId("Peach") or "."
end

sgs.ai_choicemade_filter.skillInvoke.SevenJiujia = function(self, player, promptlist)
    if promptlist[#promptlist] == "yes" then
        sgs.SevenJiujia = player
    end
end

sgs.ai_skill_invoke["SevenJiujia"] = function(self, data)
	return true
end

function sgs.ai_slash_prohibit.SevenJiujia(self, from, to, card)
    if self:isFriend(to) then
        return false
    end
    if self:canLiegong(to, from) then
        return false
    end
    local players = sgs.QList2Table(self.room:getOtherPlayers(to))
    for _, player in ipairs(players) do
        if self:isFriend(player, to) then
            if player:hasSkill("tiandu") and sgs.ai_slash_prohibit.tiandu(self, from, player, card) then
                return true
            end
            if player:hasLordSkill("hujia") and sgs.ai_slash_prohibit.hujia(self, from, player, card) then
                return true
            end
            if player:hasSkill("leiji") and sgs.ai_slash_prohibit.leiji(self, from, player, card) then
                return true
            end
            if player:hasSkill("weidi") and sgs.ai_slash_prohibit.weidi(self, from, player, card) then
                return true
            end
        end
    end
    return false
end

sgs.ai_skill_cardask["@@SevenJiujia"] = function(self, data, pattern)
    local target = data:toPlayer()
    if target and self:isFriend(target) then
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
    return "."
end

sgs.ai_choicemade_filter.cardResponded["@@SevenJiujia"] = function(self, player, promptlist)
    if promptlist[#promptlist] ~= "" then
        if sgs.SevenJiujia then
            sgs.updateIntention(player, sgs.SevenJiujia, -80)
		    sgs.SevenJiujia = nil
        end
    elseif sgs.SevenJiujia then
        local lieges = player:getRoom():getOtherPlayers(sgs.SevenJiujia)
        if lieges and not lieges:isEmpty() then
            if player:objectName() == lieges:last():objectName() then
                sgs.SevenJiujia = nil
            end
        end
    end
end

sgs.ai_cardsview_valuable.SevenJiujia = function(self, class_name, player)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
    local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
		["Peach"] = "peach",
	}
	local name = classname2objectname[class_name]
    if not name then return end
	local had_card = nil
	for _, c in ipairs(handcards) do
		if c:isKindOf(name) then
			had_card = c
            break
		end
	end
	if class_name == "Peach" and sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end

	if name and not player:hasFlag("Global_SevenJiujiaFailed") and had_card == nil and player:getPhase() == sgs.Player_NotActive  then
		return string.format("#SevenJiujiaCard:.:%s", name)
	end
end

local SevenJiujia_filter = function(self,player,carduse)
	if carduse.card:isKindOf("SevenJiujiaCard") then
		sgs.SevenJiujia = player
	end
end
table.insert(sgs.ai_choicemade_filter.cardUsed,SevenJiujia_filter)

local SixMiBian_skill = {}
SixMiBian_skill.name = "SixMiBian"
table.insert(sgs.ai_skills, SixMiBian_skill)
SixMiBian_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#SixMiBian") then
		return sgs.Card_Parse("#SixMiBian:.:")
	end
end

sgs.ai_skill_use_func["#SixMiBian"] = function(card, use, self)
	local target = nil
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	local max = 0
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		local x = 0
		if self.player:inMyAttackRange(enemy) then
			for _, friend in ipairs(self.friends) do
				if friend:inMyAttackRange(enemy) then
					if not friend:isKongcheng() and not self:slashProhibit(slash, enemy, friend)
						and self:slashIsEffective(slash, enemy, friend) and self:isGoodTarget(enemy, self.enemies, slash) then
						x = x + 1
					end
				end
			end
			if x > max then
				max = x
				target = enemy
			end
		end
	end

	if target == nil then return end

	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local discard_cards = {}
	local spade_check = true
	local heart_check = true
	local club_check = true
	local diamond_check = true

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
	if #discard_cards > 0 then
		use.card = sgs.Card_Parse(string.format("#SixMiBian:%s:", table.concat(discard_cards, "+")))
		if use.to then use.to:append(target) end
	end
end

sgs.ai_skill_cardask["@SixMiBian"] = function(self, data, pattern, target)
	local dest = data:toPlayer()
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	if dest and not self:slashProhibit(slash, dest, self.player) and self:isEnemy(dest) and self:slashIsEffective(slash, dest, self.player) and self:isGoodTarget(dest, self.enemies, slash) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if string.find(pattern, card:getSuitString()) then
				return card:toString()
			end
		end
	end
	return "."
end


sgs.ai_skill_invoke["SixJianCe"] = function(self, data)
	local target = data:toPlayer()
	local max_card = self:getMaxCard()

	if target and self:isEnemy(target) and max_card then
		local max_point = max_card:getNumber()
		local enemy_max_card = self:getMaxCard(target)
		if (enemy_max_card and max_point > enemy_max_card:getNumber())
			or (enemy_max_card and max_point > enemy_max_card:getNumber() and max_point > 10)
			or (not enemy_max_card and max_point > 10) then
			if self.player:getHandcardNum() > target:getHandcardNum() then
				self.SixJianCe_card = max_card:getEffectiveId()
				return true
			end
		end
	end
	return false
end



sgs.ai_skill_discard.SixJianCe = function(self, discard_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	local compare_func = function(a, b)
		return self:getKeepValue(a) < self:getKeepValue(b)
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if #to_discard >= discard_num then break end
		table.insert(to_discard, card:getId())
	end

	return to_discard
end

sgs.ai_cardneed.SixJianCe = sgs.ai_cardneed.bignumber

function sgs.ai_skill_pindian.SixJianCe(minusecard, self, requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and minusecard or (maxcard:getNumber() < 6 and minusecard or maxcard)
end

sgs.ai_cardneed.SixShouLue = sgs.ai_cardneed.equip



sgs.ai_skill_invoke["SixYangShi"] = function(self, data)
	return true
end

sgs.ai_skill_invoke["SevenRenDe"] = function(self, data)
	if self.player:isWounded() or self:isWeak() or self.player:getHandcardNum() < 3 then
		return true
	end

	if #self.friends_noself >= #self.enemies then
		return true
	end

	return false
end

sgs.ai_skill_cardask["@SevenRenDe"] = function(self, data, pattern, target, target2)
	local target = data:toPlayer()
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(usable_cards)

	if target then
		if self:isFriend(target) then
			usable_cards = sgs.reverse(usable_cards)
			return usable_cards[1]:toString()
		else
			return usable_cards[1]:toString()
		end
	end
	return "."
end




function sgs.ai_skill_invoke.SevenJuDi(self, data)
	return true
end

sgs.ai_skill_use["@@SevenJuDi"] = function(self, prompt)
	local enemynum = 0
	for _, enemy in ipairs(self.enemies) do
		if (not self:needKongcheng(enemy) and self:hasLoseHandcardEffective(enemy)) or self:getDangerousCard(enemy) or self:getValuableCard(enemy) then
			enemynum = enemynum + 1
		end
	end

	if enemynum == 0 then
		return "."
	end
	self:sort(self.enemies, "defense")

	local first_index, second_index, third_index
	for i = 1, #self.enemies do
		if ((not self:needKongcheng(self.enemies[i]) and self:hasLoseHandcardEffective(self.enemies[i]))
				or self:getDangerousCard(self.enemies[i]) or self:getValuableCard(self.enemies[i])) and not self.enemies[i]:isNude() and
			not (self.enemies[i]:hasSkill("guzheng") and self.room:getCurrent():getPhase() == sgs.Player_Discard) then
			if not first_index then
				first_index = i
			elseif not second_index then
				second_index = i
			else
				third_index = i
			end
		end
		if third_index then break end
	end
	if first_index then
		local first = self.enemies[first_index]:objectName()
		if first_index and not second_index then
			return ("#SevenJuDi:.:->%s"):format(first)
		elseif second_index and not third_index then
			local second = self.enemies[second_index]:objectName()
			return ("#SevenJuDi:.:->%s+%s"):format(first, second)
		else
			local second = self.enemies[second_index]:objectName()
			local third = self.enemies[third_index]:objectName()
			return ("#SevenJuDi:.:->%s+%s"):format(first, second, third_index)
		end
	end
end

sgs.ai_card_intention["#SevenJuDi"] = 80

sgs.double_slash_skill = sgs.double_slash_skill .. "|SevenKanLuan"

function sgs.ai_skill_invoke.SevenKanLuan(self, data)
	local discard_num = self.player:getHandcardNum() - self.player:getHp()
	if discard_num >= 3 then
		return false
	end
	local cardstr = sgs.ai_skill_use["@@SevenKanLuan"](self, "@SevenKanLuan")
	if cardstr:match("->") then
		return true
	end
	return false
end

sgs.ai_skill_use["@@SevenKanLuan"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local discard_num = self.player:getHandcardNum() - self.player:getHp()
	local discard_table = self:askForDiscard("dummyreason", discard_num, discard_num, false, true)


	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()

	local dummy_use = self:aiUseCard(slash, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
	end
	if #targets > 0 then
		return "#SevenKanLuan:" .. table.concat(discard_table, "+") .. ":->" .. targets[1]
	end
	return "."
end

sgs.ai_cardneed.SevenKanLuan = function(to,card)
	return to:getHandcardNum() < to:getHp()
end

sgs.ai_skill_discard.SevenZhenShi = function(self, discard_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local target
	for _,p in sgs.list(sgs.QList2Table(self.room:getOtherPlayers(self.player)))do
		if p:hasFlag("SevenZhenShi") then
			target = p
            break
		end
	end
	local to_discard = {}
	local compare_func = function(a, b)
		return self:getKeepValue(a) < self:getKeepValue(b)
	end
	table.sort(cards, compare_func)
	local n = 2
	if target and self:isFriend(target) then n = self:getOverflow() end
	for _, card in ipairs(cards) do
		if #to_discard >= n then break end
		table.insert(to_discard, card:getId())
	end

	return to_discard
end



sgs.ai_skill_playerchosen["SevenZhenShi"] = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getHandcardNum() <= 1 and not self:needKongcheng(p, true) and not hasManjuanEffect(p) and self:canDraw(p, self.player) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and not hasManjuanEffect(p) and self:canDraw(p, self.player) then
			return p
		end
	end
	if self:isWeak() then
		return targets[1]
	end
	return nil
end

sgs.ai_playerchosen_intention["SevenZhenShi"] = -40

local SevenZhaoXiang_skill = {}
SevenZhaoXiang_skill.name = "SevenZhaoXiang"
table.insert(sgs.ai_skills, SevenZhaoXiang_skill)
SevenZhaoXiang_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#SevenZhaoXiang") then
		return sgs.Card_Parse("#SevenZhaoXiang:.:")
	end
end

sgs.ai_skill_use_func["#SevenZhaoXiang"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends_noself, "defense")
	local target = nil
	for _, friend in ipairs(self.friends_noself) do
		if friend:getEquips():length() > 0 and self:hasSkills(sgs.lose_equip_skill, friend) then
			target = friend
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if self:doDisCard(friend, "e", true) then
				target = friend
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getEquips():length() > 0 then
				target = friend
			end
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_priority["SevenZhaoXiang"] = 7
sgs.ai_use_value["SevenZhaoXiang"] = 7
sgs.ai_card_intention["SevenZhaoXiang"] = -40


sgs.ai_can_damagehp.SevenTaoHui = function(self, from, card, to)
	return to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
end


function sgs.ai_skill_invoke.SevenTaoHui(self, data)
	local sbdiaochan = self.room:findPlayerBySkillName("lihun")
	if sbdiaochan and sbdiaochan:faceUp() and not self:willSkipPlayPhase(sbdiaochan)
		and (self:isEnemy(sbdiaochan) or (sgs.turncount <= 1 and sgs.ai_role[sbdiaochan:objectName()] == "neutral")) then
		return false
	end
	if not self.player:faceUp() then return true end
	for _, friend in ipairs(self.friends) do
		if self:hasSkills("fangzhu|jilve", friend) then return true end
		if friend:hasSkill("junxing") and friend:faceUp() and not self:willSkipPlayPhase(friend)
			and not (friend:isKongcheng() and self:willSkipDrawPhase(friend)) then
			return true
		end
	end
	local current = self.room:getCurrent()
	return self:isWeak() or
		not (current:getNextAlive():objectName() == self.player:objectName() and self.player:faceUp())
end

function sgs.ai_skill_invoke.SevenLangMou(self, data)
	return true
end

sgs.ai_skill_cardask["@SevenQuanBian-card"] = function(self, data)
	local judge = data:toJudge()

	if self.room:getMode():find("_mini_46") and not judge:isGood() then return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getHandcards())
		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end

	return "."
end

function sgs.ai_cardneed.SevenQuanBian(to, card, self)
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if self:getFinalRetrial(to) == 1 then
			if player:containsTrick("lightning") and not player:containsTrick("YanxiaoCard") then
				return card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 and
					not self:hasSkills("hongyan|wuyan")
			end
			if self:isFriend(player) and self:willSkipDrawPhase(player) then
				return card:getSuit() == sgs.Card_Club
			end
			if self:isFriend(player) and self:willSkipPlayPhase(player) then
				return card:getSuit() == sgs.Card_Heart
			end
		end
	end
end

sgs.SevenQuanBian_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}

sgs.wizard_skill = sgs.wizard_skill .. "|SevenQuanBian"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|SevenQuanBian"

function sgs.ai_skill_invoke.SevenQuanBian(self, data)
	local card = data:toCard()
	self:sort(self.friends, "hp")
	self:sort(self.enemies, "hp")
	local up = 0
	local down = 0

	for _, friend in ipairs(self.friends) do
		down = down - 10
		up = up + (friend:isWounded() and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, friend) then
			down = down - 5
			if friend:isWounded() then up = up + 5 end
		end
		if self:needToLoseHp(friend, nil, nil, true) then down = down + 5 end
		if self:needToLoseHp(friend, nil, nil, true, true) and friend:isWounded() then up = up - 5 end

		if self:isWeak(friend) then
			if friend:isWounded() then up = up + 10 + (friend:isLord() and 20 or 0) end
			down = down - 10 - (friend:isLord() and 40 or 0)
			if friend:getHp() <= 1 and not friend:hasSkill("buqu") or friend:getPile("trauma"):length() > 4 then
				down = down - 20 - (friend:isLord() and 40 or 0)
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		down = down + 10
		up = up - (enemy:isWounded() and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, enemy) then
			down = down + 10
			if enemy:isWounded() then up = up - 10 end
		end
		if self:needToLoseHp(enemy, nil, nil, true) then down = down - 5 end
		if self:needToLoseHp(enemy, nil, nil, true, true) and enemy:isWounded() then up = up - 5 end

		if self:isWeak(enemy) then
			if enemy:isWounded() then up = up - 10 end
			down = down + 10
			if enemy:getHp() <= 1 and not enemy:hasSkill("buqu") then
				down = down + 10 + ((enemy:isLord() and #self.enemies > 1) and 20 or 0)
			end
		end
	end

	if down > 0 and card:isBlack() then
		return true
	elseif up > 0 and card:isRed() then
		return true
	end
	return false
end

sgs.ai_skill_invoke.SevenChuaiYi = function(self, data)
	local damage = data:toDamage()
	if damage and damage.from and self:isEnemy(damage.from) then
		return true
	end
	return not self:needToLoseHp(damage.to, damage.from, damage.card)
end

sgs.ai_skill_cardask["@SevenChuaiYi-show"] = function(self, data)
	local damage = data:toDamage()
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if damage.from and self.player:objectName() == damage.from:objectName() then
		if self:isEnemy(damage.to) then
			for _, card in ipairs(cards) do
				if getKnownCard(damage.to, self.player, card:getSuitString(), false, "h") > 0 then
					return "$" .. card:getEffectiveId()
				end
			end
		elseif self:isFriend(damage.to) and not self:needToLoseHp(damage.to, self.player, damage.card) then
			for _, card in ipairs(cards) do
				if getKnownCard(damage.to, self.player, card:getSuitString(), false, "h") == 0 then
					return "$" .. card:getEffectiveId()
				end
			end
		end
	end
	return "$" .. cards[1]:getEffectiveId()
end

sgs.ai_ajustdamage_to.SevenChuaiYi = function(self, from, to, card, nature)
	if not to:isKongcheng()
	then
		if self:isFriend(to, from)
		then
			return -1
		else
			if from:objectName() ~= self.player:objectName()
			then
				if ((getKnownCard(to, self.player, "heart", false, "h") == 0 and getKnownCard(self.player, self.player, "heart", false, "h") > 0) or
						(getKnownCard(to, self.player, "spade", false, "h") == 0 and getKnownCard(self.player, self.player, "spade", false, "h") > 0) or
						(getKnownCard(to, self.player, "club", false, "h") == 0 and getKnownCard(self.player, self.player, "club", false, "h") > 0) or
						(getKnownCard(to, self.player, "diamond", false, "h") == 0 and getKnownCard(self.player, self.player, "diamond", false, "h") > 0)
					)

				then
					return -1
				end
			end
		end
	end
end



sgs.ai_skill_invoke.SevenZhiDi = function(self, data)
	local target = data:toPlayer()
	if target then
		if self:isEnemy(target) then
			return true
		end
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.SevenZhiDi = function(self, player, promptlist)
	if #promptlist == "yes" then
		local lord = self.room:getCurrent()
		if lord then
			sgs.updateIntention(player, lord, 60)
		end
	end
end



sgs.ai_skill_choice["SevenZhiDi"] = function(self, choices, data)
	self:updatePlayers()
	local who = data:toPlayer()
	local handcards = sgs.QList2Table(who:getHandcards())
	local items = choices:split("+")
	for _, c in ipairs(handcards) do
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), who:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if table.contains(items, c:objectName()) then
				return c
			end
		end
	end
	return items[math.random(1, #items)]
end

function sgs.ai_cardsview_valuable.SevenWeiYuan(self, class_name, player)
	local dying = self.room:getCurrentDyingPlayer()
	if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then return end
	if dying:isLord() and self:isFriend(dying, player) then return "#SevenWeiYuan:.:" end

	--if self:playerGetRound(dying) < self:playerGetRound(self.player) then return end
		local cards = player:getCards("he")
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if fcard:isKindOf("EquipCard") then
				return "#SevenWeiYuan:" .. fcard:getEffectiveId() .. ":"
			end
		end
	if player:getHp() >= 2 or getCardsNum("Analeptic", player, self.player) > 0
	then
		return "#SevenWeiYuan:.:"
	end
end

sgs.ai_card_intention.SevenWeiYuan = sgs.ai_card_intention.Peach

sgs.ai_cardneed["SevenWeiYuan"] = sgs.ai_cardneed.equip

sgs.save_skill = sgs.save_skill .. "|SevenWeiYuan"

sgs.ai_skill_choice["SevenJuGong"] = function(self, choices, data)
	local items = choices:split("+")
	if self:getCardsNum("Peach") > 0 then
		return "loseHp"
	end
	if self:getAllPeachNum() < 1 then
		return "discard"
	end
	return items[math.random(1, #items)]
end


local SevenFenLiang_skill = {}
SevenFenLiang_skill.name = "SevenFenLiang"
table.insert(sgs.ai_skills, SevenFenLiang_skill)
SevenFenLiang_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#SevenFenLiang") or self.player:getMark("@SevenFenLiang") < 1 then return end
	if #self.enemies == 0 then return end


	return sgs.Card_Parse("#SevenFenLiang:.:")
end

sgs.ai_skill_use_func["#SevenFenLiang"] = function(wuqiancard, use, self)
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local target
	for _, enemy in ipairs(self.enemies) do
		if self.player:getCardCount() >= self.player:distanceTo(enemy) and self.player:distanceTo(enemy) < enemy:getHandcardNum() and self:doDisCard(enemy, "h") and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil)  then
			target = enemy
			break
		end
	end
	if target then
		use.card = sgs.Card_Parse("#SevenFenLiang:.:")
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["#SevenFenLiang"] = 5
sgs.ai_use_priority["#SevenFenLiang"] = 10
sgs.ai_card_intention["#SevenFenLiang"] = 80


sgs.ai_skill_invoke.SevenPingPan = function(self, data)
	return true
end

sgs.ai_choicemade_filter.skillInvoke.SevenPingPan = function(self, player, promptlist)
	if #promptlist == "yes" then
		local target = self.room:getCurrentDyingPlayer()
		if target then
			sgs.roleValue[target:objectName()]["renegade"] = 0
			sgs.roleValue[target:objectName()]["loyalist"] = 0
			local role, value = target:getRole(), 1000
			if role == "rebel" then
				role = "loyalist"
				value = -1000
			end
			sgs.roleValue[target:objectName()][role] = value
			sgs.ai_role[target:objectName()] = target:getRole()

			sgs.roleValue[player:objectName()]["renegade"] = 0
			sgs.roleValue[player:objectName()]["loyalist"] = 0
			local role, value = player:getRole(), 1000
			if role == "rebel" then
				role = "loyalist"
				value = -1000
			end
			sgs.roleValue[player:objectName()][role] = value
			sgs.ai_role[player:objectName()] = player:getRole()
		end
	end
end

sgs.ai_skill_invoke.SevenHuBei = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@SevenHuBei"] = function(self, data)
	local to_discard = self:askForDiscard("dummyreason", 1, 1, false, true, ".")
	if #to_discard > 0 then return "$" .. to_discard[1] else return "." end
end

sgs.ai_cardneed.SevenXiaoRui = sgs.ai_cardneed.slash


sgs.ai_skill_use["@@SevenYingYong"] = function(self, prompt)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local duel = sgs.Sanguosha:cloneCard("duel")
	duel:deleteLater()
	local d = self:aiUseCard(duel)
	if d.card then
		dc = {}
		for _,p in sgs.list(d.to)do
			table.insert(dc,p:objectName())
		end
		return "#SevenYingYong:.:->" .. table.concat(dc,"+")
	end

	for _, enemy in ipairs(self.enemies) do
		local eff = self:hasTrickEffective(duel, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, duel)
		if self.player:isProhibited(enemy, duel) then
		elseif eff then
			return "#SevenYingYong:.:->" .. enemy:objectName()
		else
			return "."
		end
	end

	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)
		local eff = self:hasTrickEffective(duel, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, duel)

		if self.player:isProhibited(enemy, duel) then
		elseif eff and def < 8 then
			return "#SevenYingYong:.:->" .. enemy:objectName()
		else
			return "."
		end
	end
	return "."
end

sgs.ai_skill_cardask["@SevenFuTui"] = function(self, data)
	local current = self.room:getCurrent()
	local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
	if #to_discard > 0 and current and self:isEnemy(current) and not current:hasFlag("Global_PlayPhaseTerminated") then
		return
			"$" .. to_discard[1]
	else
		return "."
	end
end

sgs.ai_choicemade_filter.cardResponded["@SevenFuTui"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		--local current = self.player:getTag("sidi_target"):toPlayer()
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, 80)
	end
end

sgs.ai_skill_invoke.SevenYiZe = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.SevenYiZe = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if friend:getEquips():length() > 0 and (self:hasSkills(sgs.lose_equip_skill, friend) or self:doDisCard(friend, "e")) then
			return friend
		end
	end
	-- the target of the Duel
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() > 0 then
			if (self:doDisCard(enemy, "e")) then
				return enemy
			end
		end
	end
end


sgs.ai_skill_choice.SevenZhengBian = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) then return "SevenZhengBian_equip" end
	if self:isEnemy(target) and self:doDisCard(target, "e", true) then return "SevenZhengBian_equip" end
	return "SevenZhengBian_limit"
end

local SevenZhengBian_skill = {}
SevenZhengBian_skill.name = "SevenZhengBian"
table.insert(sgs.ai_skills, SevenZhengBian_skill)
SevenZhengBian_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#SevenZhengBian") then return end
	return sgs.Card_Parse("#SevenZhengBian:.:")
end
sgs.ai_skill_use_func["#SevenZhengBian"] = function(card, use, self)
	local player = self.player
	local room = player:getRoom()
	local cards = sgs.QList2Table(player:getCards("he"))
	for _, card in ipairs(cards) do
		if not card:isKindOf("EquipCard") then table.removeOne(cards, card) end
	end
	self:sortByKeepValue(cards, false)
	local players = sgs.QList2Table(room:getAlivePlayers())
	local targets, friends, enemies = {}, {}, {}
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not p:isKongcheng() then
			table.insert(targets, p)
			if self:isFriend(p) then
				table.insert(friends, p)
			elseif self:isEnemy(p) and self:doDisCard(p, "e", true) then
				table.insert(enemies, p)
			end
		end
	end

	if #targets == 0 then return end
	local target


	if not target then
		for _, enemy in ipairs(enemies) do
			if self:getDangerousCard(enemy) then
				target = enemy
				break
			end
		end
	end

	if not target then
		for _, enemy in ipairs(enemies) do
			if self:getValuableCard(enemy) then
				target = enemy
				break
			end
		end
	end

	if not target then
		for _, friend in ipairs(friends) do
			if self:needToThrowArmor(friend) or friend:hasArmorEffect("silver_lion") or friend:hasSkill("yqijiang") then
				target = friend
				break
			end
		end
	end
	if not target then
		for _, enemy in ipairs(enemies) do
			if self:hasSkills(sgs.concentrated_skill, enemy) and self:doDisCard(enemy, "e") then
				if enemy:getDefensiveHorse() then
					target = enemy
					break
				end
				if not target then
					if enemy:getArmor() and not self:needToThrowArmor(enemy) then
						target = enemy
						break
					end
				end
			end
		end
	end
	if not target and self:getCardsNum("Slash") > 0 then
		local slash = self:getCard("Slash")
		assert(slash)

		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
			for _, p in sgs.qlist(dummy_use.to) do
				if not self:canHit(p, self.player) or (p:getHp() <= 1 and self:getAllPeachNum(p) > 0) then
					target = p
					break
				end
			end
		end
	end

	local cards = sgs.QList2Table(player:getCards("he"))
	self:sortByUseValue(cards, true)
	local subcard
	for _, acard in ipairs(cards) do
		if acard:isKindOf("EquipCard") then
			subcard = acard
			break
		end
	end
	if not subcard then
		use.card = nil
		return
	end
	if not target then
		use.card = nil
		return
	end
	use.card = sgs.Card_Parse("#SevenZhengBian:.:")
	use.card:addSubcard(subcard)
	self:sort(targets, "handcard")
	if use.to then use.to:append(target) end
end





sgs.ai_use_value["SevenZhengBian"] = 9
sgs.ai_use_priority["SevenZhengBian"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_card_intention["SevenZhengBian"] = sgs.ai_card_intention.Dismantlement

sgs.ai_cardneed["SevenZhengBian"] = sgs.ai_cardneed.equip

sgs.ai_skill_cardask["@SevenQuGao-discard"] = function(self, data)
	local use = data:toCardUse()
	if self:isFriend(use.from) then
		if use.card and use.card:isKindOf("IronChain") then
			return "."
		end
		local shouldUse = false
		local dummy_use = self:aiUseCard(use.card, dummy())
		if dummy_use.card then shouldUse = true end


		local card_id
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)
		for _, hcard in ipairs(hcards) do
			if self.player:canDiscard(self.player, hcard:getId()) and hcard:getSuitString() == use.card:getSuitString() and self:getUseValue(hcard) < self:getUseValue(use.card) then
				card_id = hcard:getEffectiveId()
				break
			end
		end

		if shouldUse and card_id then
			return "$" .. card_id
		end
	elseif self:isFriend(use.to:first()) then
		if not use.from or use.from:isDead() then return "cancel" end
		if self.role == "rebel" and sgs.ai_role[use.from:objectName()] == "rebel" and not hasJueqingEffect(use.from, use.to:first(), sgs.card_damage_nature[use.card:getClassName()])
			and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
			return "."
		end
		local card_id
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)
		for _, hcard in ipairs(hcards) do
			if self.player:canDiscard(self.player, hcard:getId()) and hcard:getSuitString() == use.card:getSuitString() and self:getUseValue(hcard) < self:getUseValue(use.card) then
				card_id = hcard:getEffectiveId()
				break
			end
		end
		if card_id then
			if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not hasJueqingEffect(use.from, use.to:first(), sgs.card_damage_nature[use.card:getClassName()]) and use.from:isLord() and self.player:getHp() == 1) then
				if use.card:isKindOf("AOE") then
					local from = use.from
					if use.card:isKindOf("SavageAssault") then
						local menghuo = self.room:findPlayerBySkillName("huoshou")
						if menghuo then from = menghuo end
					end

					local friend_null = 0
					for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
						if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
						if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
					end
					friend_null = friend_null + self:getCardsNum("Nullification")
					local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

					if self:hasTrickEffective(use.card, self.player, from) then
						if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then
							if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then
								return
									"$" .. card_id
							end
							if sj_num == 0 and friend_null <= 0 then
								if self:isEnemy(from) and hasJueqingEffect(from, use.to:first(), sgs.card_damage_nature[use.card:getClassName()]) then
									return
										"$" .. card_id
								end
								if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not hasJueqingEffect(from, use.to:first(), sgs.card_damage_nature[use.card:getClassName()]) then
									return
										"$" .. card_id
								end
								if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(from, use.to:first(), sgs.card_damage_nature[use.card:getClassName()])) then
									return "$" .. card_id
								end
							end
						end
					end
				elseif self:isEnemy(use.from) then
					if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
						if self:hasTrickEffective(use.card, self.player) then
							if self:damageIsEffective(self.player, sgs.DamageStruct_Fire, use.from) then
								if (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0) and use.from:getHandcardNum() > 3
									and not (use.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
									return "$" .. card_id
								elseif self.player:isChained() and not self:isGoodChainTarget(self.player, use.from) then
									return "$" .. card_id
								end
							end
						end
					elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))
						and not self.player:isKongcheng() then
						if self:hasTrickEffective(use.card, self.player) then
							return "$" .. card_id
						end
					elseif use.card:isKindOf("Duel") then
						if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player) then
							if self:hasTrickEffective(use.card, self.player) then
								if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then
									return "$" .. card_id
								end
							end
						end
					end
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_choice.SevenQuGao = function(self, choices, data)
	local use = data:toCardUse()
	local items = choices:split("+")
	if self:isFriend(use.from) then
		return "SevenQuGao_double"
	elseif self:isFriend(use.to:first()) then
		return "SevenQuGao_invalid"
	end
	return items[math.random(1, #items)]
end

sgs.ai_skill_choice.SevenBaChao = function(self, choices)
	if self.player:getMaxHp() >= self.player:getHp() + 2 then
		if self.player:getMaxHp() > 5 and (self.player:hasSkills("nosmiji|yinghun|juejing|zaiqi|nosshangshi") or self.player:hasSkill("miji") and self:findPlayerToDraw(false)) then
			local enemy_num = 0
			for _, p in ipairs(self.enemies) do
				if p:inMyAttackRange(self.player) and not self:willSkipPlayPhase(p) then enemy_num = enemy_num + 1 end
			end
			local ls = sgs.fangquan_effect and self.room:findPlayerBySkillName("fangquan")
			if ls then
				sgs.fangquan_effect = false
				enemy_num = self:getEnemyNumBySeat(ls, self.player, self.player)
			end
			local least_hp = isLord(self.player) and math.max(2, enemy_num - 1) or 1
			if (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self.player:getHp() > least_hp) then
				return
				"hp"
			end
		end
		return "maxhp"
	else
		return "hp"
	end
end

sgs.bad_skills = sgs.bad_skills .. "|SevenBaChao"

SevenLuanZheng_skill = {}
SevenLuanZheng_skill.name = "SevenLuanZheng"
table.insert(sgs.ai_skills, SevenLuanZheng_skill)
SevenLuanZheng_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#SevenLuanZheng") then return end
	return sgs.Card_Parse("#SevenLuanZheng:.:")
end

sgs.ai_skill_use_func["#SevenLuanZheng"] = function(card, use, self)
	use.card = card
end


sgs.ai_skill_cardask["@SevenJieMing"] = function(self, data)
	local target = data:toDamage().to
	if self:isFriend(target) then return "." end
	local to_discard = self:askForDiscard("dummyreason", 1, 1, false, false, ".")
	if #to_discard > 0 then
		return "$" .. to_discard[1]
	else
		return "."
	end
end

sgs.ai_ajustdamage_to.SevenJieMing = function(self, from, to, card, nature)
	if from and (from:isKongcheng() or beFriend(to, from))
	then
		return -1
	end
end

sgs.ai_skill_invoke.SevenTaDao = function(self, data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return true
	end
	return false
end


sgs.ai_skill_playerchosen.SevenTaDao = function(self, targets)
	local target = self:findPlayerToDamage(1, self.player, "N", targets)[1]
	return target
end
sgs.ai_skill_invoke.SevenMiDao = function(self, data)
	return true
end


SevenChuanJiao_skill = {}
SevenChuanJiao_skill.name = "SevenChuanJiao"
table.insert(sgs.ai_skills, SevenChuanJiao_skill)
SevenChuanJiao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#SevenChuanJiao") then return end
	return sgs.Card_Parse("#SevenChuanJiao:.:")
end

sgs.ai_skill_use_func["#SevenChuanJiao"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_choice.SevenChuanJiao = function(self, choices, data)
	local items = choices:split("+")
	local red_friend = 0
	local black_friend = 0
	local red_enemy = 0
	local black_enemy = 0

	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("SevenChuanJiaored") then
			if self:isFriend(p) then
				red_friend = red_friend + 1
			elseif self:isEnemy(p) then
				red_enemy = red_enemy + 1
			end
		elseif p:hasFlag("SevenChuanJiaoblack") then
			if self:isFriend(p) then
				black_friend = black_friend + 1
			elseif self:isEnemy(p) then
				black_enemy = black_enemy + 1
			end
		end
	end
	local x = red_friend - red_enemy
	local y = black_friend - black_enemy
	if x > y then
		return "red"
	else
		return "black"
	end

	return items[math.random(1, #items)]
end




local SevenFengPing_skill = {}
SevenFengPing_skill.name = "SevenFengPing"
table.insert(sgs.ai_skills, SevenFengPing_skill)
SevenFengPing_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#SevenFengPing") then
		return sgs.Card_Parse("#SevenFengPing:.:")
	end
end

sgs.ai_skill_use_func["#SevenFengPing"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he") then
			use.card = sgs.Card_Parse("#SevenFengPing:.:")
			if use.to then
				use.to:append(enemy)
			end
		end
		return
	end
end

sgs.ai_use_value.SevenFengPing = 2.5
sgs.ai_card_intention.SevenFengPing = 0



sgs.ai_skill_choice.SevenFengPing = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target) then return "red" end
	if self:isEnemy(target) then return "black" end

	return items[math.random(1, #items)]
end

sgs.ai_choicemade_filter.skillChoice["SevenFengPing"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target = self.room:getTag("SevenFengPing"):toPlayer()
	if choice == "red" then
		sgs.updateIntention(player, target, -80)
	else
		sgs.updateIntention(player, target, 80)
	end
end


sgs.ai_skill_cardask["@SevenFengPing"] = function(self, data, pattern, target)
	local target = data:toPlayer()
	if self:isFriend(target) then return "." end
	local card_id
	local hcards = self.player:getCards("h")
	hcards = sgs.QList2Table(hcards)
	self:sortByUseValue(hcards, true)
	local types = pattern:split("|")[2]
	for _, hcard in ipairs(hcards) do
		if self.player:canDiscard(self.player, hcard:getId()) and hcard:getColorString() == types then
			card_id = hcard:getEffectiveId()
			break
		end
	end
	if card_id then
		return "$" .. card_id
	end

	return "."
end
sgs.ai_skill_invoke.SevenYueDan = function(self, data)
	local ids = self.room:getTag("SevenFengPing"):toString():split("+") or {}
	if #ids == 0 then return false end
	local x = 0
	for _, id in pairs(ids) do
		if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") and self.room:getCardPlace(id) == sgs.Player_DiscardPile then
			x = x + 1
		end
	end
	if x >= 3 then
		return true
	end
	return false
end

