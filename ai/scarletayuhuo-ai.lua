local s_anren_skill = {}
s_anren_skill.name = "s_anren"
table.insert(sgs.ai_skills, s_anren_skill)

s_anren_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getCards("he"):length() < 1 then return nil end
	if self.player:hasUsed("#s_anren") then return nil end
	local card
	if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isBlack() then
				card = hcard
				break
			end
		end
	end
	if card then
		return sgs.Card_Parse("#s_anren:.:")
	end
end

sgs.ai_skill_use_func["#s_anren"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	local target = nil
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			and enemy:objectName() ~= self.player:objectName() then
			target = enemy
			break
		end
	end
	local card
	if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isBlack() then
				card = hcard
				break
			end
		end
	end
	if card then
		if target then
			use.card = sgs.Card_Parse("#s_anren:" .. card:getId() .. ":")
			if use.to then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_use_value["s_anren"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["s_anren"] = sgs.ai_use_priority.Slash - 0.2


sgs.ai_skill_invoke.s_nixing = function(self, data)
	local dmg = data:toDamage()
	if self:damageStruct(dmg) and self:needToLoseHp(dmg.to, dmg.from, dmg.card) then
		return false
	end
	return true
end

function sgs.ai_cardneed.s_wuqiang(to, card, self)
	local slash = card:isKindOf("Slash")
	if self.player:getWeapon() then
		return (slash and getKnownCard(to, self.player, "Slash", false) == 0)
	else
		return (card:isKindOf("Weapon") and card:getRealCard():toWeapon():getRange() > 2)
	end
end

local biaoqiSlashCard = function(pile)
	if #pile > 0 then return pile[1] end
	return nil
end


local s_biaoqiSlash_skill = {}
s_biaoqiSlash_skill.name = "s_biaoqiSlash"
table.insert(sgs.ai_skills, s_biaoqiSlash_skill)
s_biaoqiSlash_skill.getTurnUseCard = function(self)
	--if not self:slashIsAvailable() then return end
	if #self.enemies == 0 then return end
	return sgs.Card_Parse("#s_biaoqiSlash:.:")
	--[[self:sort(self.enemies, "defense")
	local players =  self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		--if p:hasSkill("slyanhuo") and not p:getPile("confuse"):isEmpty() and self:isEnemy(p) then
		if  (p:getPile("s_yong"):length() > 0) and self:isEnemy(p) then
			return  sgs.Card_Parse("#s_biaoqislash:.:")
		end
	end]]
	--[[for _, enemy in ipairs(self.enemies) do
		if (enemy:getPile("s_yong"):length() > 0) and self.player:canSlash(enemy) then
			local ints = sgs.QList2Table(enemy:getPile("s_yong"))
				local a = biaoqiSlashCard(ints)
			if a  then
				return sgs.Card_Parse("#s_biaoqislash:" .. tostring(a)..":")
			end
		end
	end
	for _, friend in ipairs(self.friends) do
		if (friend:getPile("s_yong"):length() > 0) and self.player:canSlash(friend) then
			local ints = sgs.QList2Table(friend:getPile("s_yong"))
				local a = biaoqiSlashCard(ints)
			if a  then
				return sgs.Card_Parse("#s_biaoqislash:" .. tostring(a)..":")
			end
		end
	end]]
end

sgs.ai_skill_use_func["#s_biaoqiSlash"] = function(card, use, self)
	local slash = sgs.Sanguosha:cloneCard("slash")
	local target
	local players = self.room:getOtherPlayers(self.player)
	for _, p in sgs.qlist(players) do
		if p and self:isEnemy(p) and (p:getPile("s_yong"):length() > 0) and self.player:canSlash(p) and self:canHit(p, self.player) then
			use.card = card
			use.card:addSubcard(p:getPile("s_yong"):first())
			if use.to then use.to:append(p) end
		end
	end

	--[[
	for _,p in sgs.qlist(players) do
		if p and self:isEnemy(p) and (p:getPile("s_yong"):length() > 0) and self.player:canSlash(p) then
			sgs.ai_use_priority["#s_biaoqislash"] = 2.6
			local dummy_use = { to = sgs.SPlayerList() }
			self:useCardSlash(slash, dummy_use)
			if dummy_use.card then
				if (dummy_use.card:isKindOf("GodSalvation") or dummy_use.card:isKindOf("Analeptic") or dummy_use.card:isKindOf("Weapon"))
					and self:getCardsNum("Slash") > 0 then
					use.card = dummy_use.card
					if use.to then use.to:append(p) end
				else
					if dummy_use.card:isKindOf("Slash") and dummy_use.to:length() > 0 then
						local lf
						for _, q in sgs.qlist(dummy_use.to) do
							if q:objectName() == p:objectName() then
								lf = true
								break
							end
						end
						if lf then
							use.card = card
							use.card:addSubcard(p:getPile("s_yong"):first())
							if use.to then use.to:append(p) end
						end
					end
				end
			end
			if not use.card then
					if self:slashIsAvailable() and self:isEnemy(p)
						and not self:slashProhibit(slash, p) and self:slashIsEffective(slash, p) and sgs.isGoodTarget(p, self.enemies, self) then
						use.card = card
						use.card:addSubcard(p:getPile("s_yong"):first())
						if use.to then use.to:append(p) end
					end
				end
		end
	end
		for _,p in sgs.qlist(players) do
		if p and self:isFriend(p) and (p:getPile("s_yong"):length() > 0) and self.player:canSlash(p) then
		if (p:getPile("s_yong"):length() > 0) and self.player:canSlash(p) then
			if self:slashIsAvailable() and not self:slashIsEffective(slash, p, self.player) and self:isFriend(p) then
			sgs.ai_use_priority["#s_biaoqislash"] = 0.1
			use.card = card
			use.card:addSubcard(p:getPile("s_yong"):first())
			if use.to then use.to:append(p) end
			end
		end
		end
	end]]
	--[[
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if (enemy:getPile("s_yong"):length() > 0) and self.player:canSlash(enemy) then
			sgs.ai_use_priority["s_biaoqislash"] = 2.6
			local dummy_use = { to = sgs.SPlayerList() }
			self:useCardSlash(slash, dummy_use)
			if dummy_use.card then
				if (dummy_use.card:isKindOf("GodSalvation") or dummy_use.card:isKindOf("Analeptic") or dummy_use.card:isKindOf("Weapon"))
					and self:getCardsNum("Slash") > 0 then
					use.card = dummy_use.card
					if use.to then use.to:append(enemy) end
				else
					if dummy_use.card:isKindOf("Slash") and dummy_use.to:length() > 0 then
						local lf
						for _, p in sgs.qlist(dummy_use.to) do
							if p:objectName() == enemy:objectName() then
								lf = true
								break
							end
						end
						if lf then
							use.card = card
							if use.to then use.to:append(enemy) end
						end
					end
				end
			end
			if not use.card then
					if self:slashIsAvailable() and self:isEnemy(enemy)
						and not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self) then
						use.card = card
						if use.to then use.to:append(enemy) end
					end
				end
		end
	end
	for _, friend in ipairs(self.friends) do
		if (friend:getPile("s_yong"):length() > 0) and self.player:canSlash(friend) then
			if self:slashIsAvailable() and not self:slashIsEffective(slash, friend, self.player) and self:isFriend(friend) then
			sgs.ai_use_priority["s_biaoqislash"] = 0.1
			use.card = card
			if use.to then use.to:append(friend) end
			end
		end
	end]]
end

sgs.ai_card_intention["#s_biaoqislash"] = function(self, card, from, tos)
	local slash = sgs.Sanguosha:cloneCard("slash")
	if not self:slashIsEffective(slash, tos[1], from) then
		sgs.updateIntention(from, tos[1], -30)
	else
		return sgs.ai_card_intention.Slash(self, slash, from, tos)
	end
end


s_w_yongjin_skill = {}
s_w_yongjin_skill.name = "s_w_yongjin"
table.insert(sgs.ai_skills, s_w_yongjin_skill)
s_w_yongjin_skill.getTurnUseCard = function(self, inclusive)
	if not sgs.Slash_IsAvailable(self.player) or self.player:getMark("&s_w_yongjin") < 1 then return end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, carda in ipairs(cards) do
		if carda:isKindOf("Slash") then
			return
		end
	end

	local card_str = ("slash:s_w_yongjin[no_suit:0]=.")
	local card = sgs.Card_Parse(card_str)
	return card
end


sgs.ai_view_as.s_w_yongjin = function(card, player, card_place)
	--if player:hasFlag("slash_to") then
	if player:getMark("&s_w_yongjin") < 1 then return end
	local cards = player:getCards("h")
	cards = sgs.QList2Table(cards)
	for _, carda in ipairs(cards) do
		if carda:isKindOf("Slash") then
			return
		end
	end
	return ("slash:s_w_yongjin[no_suit:0]=.")
	--end
end

sgs.ai_use_value["s_w_yongjin"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["s_w_yongjin"] = sgs.ai_use_priority.Slash - 0.5


s_w_zhitui_skill = {}
s_w_zhitui_skill.name = "s_w_zhitui"
table.insert(sgs.ai_skills, s_w_zhitui_skill)
s_w_zhitui_skill.getTurnUseCard = function(self, inclusive)
	local card = sgs.Sanguosha:cloneCard("peach", sgs.Card_NoSuit, 0)
	card:deleteLater()
	if not card:isAvailable(self.player) or self.player:getMark("&s_w_zhitui") < 1 then return end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, carda in ipairs(cards) do
		if carda:isKindOf("peach") then
			return
		end
	end
	return sgs.Card_Parse(("peach:s_w_zhitui[no_suit:0]=."))
end

sgs.ai_view_as.s_w_zhitui = function(card, player, card_place, class_name)
	if class_name == "Jink" then
		if player:getMark("&s_w_zhitui") < 1 then return end
		local cards = player:getCards("h")
		cards = sgs.QList2Table(cards)
		for _, carda in ipairs(cards) do
			if carda:isKindOf("Jink") then
				return
			end
		end

		return ("jink:s_w_zhitui[no_suit:0]=.")
	elseif class_name == "Peach" and player:getMark("Global_PreventPeach") == 0 then
		if player:getMark("&s_w_zhitui") < 1 then return end
		local cards = player:getCards("h")
		cards = sgs.QList2Table(cards)
		for _, carda in ipairs(cards) do
			if carda:isKindOf("Peach") then --null部分有问题
				return
			end
		end
		return ("peach:s_w_zhitui[no_suit:0]=.")
	end
end
sgs.ai_use_value["s_w_zhitui"] = sgs.ai_use_value.Peach
sgs.ai_use_priority["s_w_zhitui"] = sgs.ai_use_priority.Peach - 0.5

sgs.ai_skill_choice["s_w_jianxiong"] = function(self, choices, data)
	local damage = data:toDamage()
	local items = choices:split("+")
	if not damage.card then return "draw" end
	if table.contains(items, "obtain") and self:isWeak() and self.player:hasSkill("s_w_qipao") and sgs.ai_skill_cardask["#s_w_qipao"](self, data) ~= "." then return "obtain" end
	if damage.card:isKindOf("Slash") and not self:hasCrossbowEffect() and self:getCardsNum("Slash") > 0 then return
		"draw" end
	if self:isWeak() and (self:getCardsNum("Slash") > 0 or not damage.card:isKindOf("Slash") or self.player:getHandcardNum() <= self.player:getHp()) then return
		"draw" end
	if table.contains(items, "obtain") then return "obtain" end
	return items[1]
end

sgs.ai_target_revises.s_w_jianxiong = function(to,card,self)
	if card:isDamageCard()
	and not self:isFriend(to)
	and card:subcardsLength()>0
	then
		for _,id in sgs.list(card:getSubcards())do
			if isCard("Peach,Analeptic",sgs.Sanguosha:getCard(id),to)
			then return true end
		end
	end
end

sgs.ai_can_damagehp.s_w_jianxiong = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return card:isKindOf("Duel") or card:isKindOf("AOE")
	end
end

sgs.ai_skill_invoke.s_w_geran = function(self, data)
	local damage = data:toDamage()
	local target = damage.from
	if target then
		return self:doDisCard(target, "he")
	end
	return false
end

sgs.ai_skill_invoke.s_w_qipao = function(self, data)
	local damage = data:toDamage()
	local zhangjiao = self.room:findPlayerBySkillName("guidao")
	if zhangjiao and self:isEnemy(zhangjiao) then
		if getKnownCard(zhangjiao, self.player, "black", false, "he") > 1 then return false end
		if self:getCardsNum("Jink") > 1 and getKnownCard(zhangjiao, self.player, "black", false, "he") > 0 then return false end
	end
	return true
end

sgs.ai_skill_cardask["#s_w_qipao"] = function(self, data)
	local red = 0
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if c:isRed() then
			red = red + 1
		end
	end
	if (red == 0) and not self:isWeak(self.player) then return "." end

	local cards = {}
	local use_cards = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if self.player:canDiscard(self.player, c:getId()) and c:isRed() and (#cards < 2) then
			table.insert(cards, c)
		end
	end
	if #cards < 2 then return "." end
	if self.player:getHp() > getBestHp(self.player) then return "." end
	self:sortByKeepValue(cards)
	table.insert(use_cards, cards[1]:getEffectiveId())
	table.insert(use_cards, cards[2]:getEffectiveId())
	return "$"..table.concat(use_cards, "+")
end




local s_w_wushuang_skill = {}
s_w_wushuang_skill.name = "s_w_wushuang"
table.insert(sgs.ai_skills, s_w_wushuang_skill)
s_w_wushuang_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local red_card
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if not card:isKindOf("Slash") and not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not isCard("Analeptic", card, self.player) then
			red_card = card
			break
		end
	end

	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getEffectiveId()
		local card_str = ("slash:s_w_wushuang[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end
sgs.ai_card_priority.s_w_wushuang = function(self,card,v)
	if card:getSkillName() == "s_w_wushuang"
	then return 1 end
end


sgs.ai_skill_discard["s_w_tongling"] = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(usable_cards)
	local to_discard = {}
	for _, c in ipairs(usable_cards) do
		if #to_discard < discard_num and c:isKindOf("BasicCard") and not c:isKindOf("Peach") then
			table.insert(to_discard, c:getEffectiveId())
		end
	end
	if #to_discard > 0 then
		return to_discard
	end
end

sgs.ai_skill_use["@@s_ling"] = function(self, prompt)
	self:updatePlayers()
	local cards = self.player:getPile("s_ling")
	cards = sgs.QList2Table(cards)
	local card = cards[1]
	self:sort(self.enemies, "defense")
	local current = self.room:getCurrent()

	if current and self:isFriend(current) and not current:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill, current) then
		return ("#s_w_jiejiang:%d:"):format(card)
	end

	if current and self:isEnemy(current) then
		if not current:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill, current) then
			return "."
		end
		return ("#s_w_jiejiang:%d:"):format(card)
	end
	return "."
end


sgs.ai_skill_discard["s_w_jiejiang_q"] = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = sgs.QList2Table(self.player:getCards("e"))
	self:sortByKeepValue(usable_cards)
	local to_discard = {}
	for _, c in ipairs(usable_cards) do
		if #to_discard < 1 then
			table.insert(to_discard, c:getEffectiveId())
		end
	end
	if #to_discard > 0 then
		for _, player in sgs.qlist(self.room:getAllPlayers()) do
			if player:hasFlag("s_w_jiejiang") then
				player:obtainCard(to_discard[1])
			end
		end
		return to_discard
	end
end


function sgs.ai_cardneed.s_w_shenyong(to, card, self)
	return card:isKindOf("Slash")
end

sgs.ai_ajustdamage_from.s_w_nilin = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and from:getPhase() ~= sgs.Player_NotActive
	then
		return to:getMark("&s_w_nilin+to+#"..from:objectName())
	end
end
sgs.ai_ajustdamage_to.s_w_juling = function(self, from, to, card, nature)
	if nature ~= "N" then
		return -99
	end
end





sgs.ai_skill_invoke.s_w_qimou_give = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.s_w_qimou = function(self, data)
	local damage = data:toDamage()

	if not damage.to:faceUp() then
		return self:isFriend(damage.to)
	end

	local good = damage.to:getHp() > 2
	if self:isFriend(damage.to) then
		return good
	elseif self:isEnemy(damage.to) then
		if not damage.to:hasSkill("xiongshou") then
			return not good
		end
	end
end

sgs.ai_choicemade_filter.skillInvoke.s_w_qimou = function(self, player, promptlist)
	local intention = 60
	local index = promptlist[#promptlist] == "yes" and 1 or -1
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if not damage.to:faceUp() then
			intention = index * intention
		elseif damage.to:getHp() > 2 then
			intention = -index / 2 * intention
		elseif index == -1 then
			intention = -20
		end
		sgs.updateIntention(damage.from, damage.to, intention)
	end
end

local s_w_qimou_skill = {}
s_w_qimou_skill.name = "s_w_qimou"
table.insert(sgs.ai_skills, s_w_qimou_skill)
s_w_qimou_skill.getTurnUseCard = function(self)
	if (self.player:getMark("@s_mou") == 0) then return end
	if self:needBear() then return end
	if #self.enemies == 0 then return end
	if sgs.ai_role[self.player:objectName()]=="neutral" then return end
	return sgs.Card_Parse("#s_w_qimouCard:.:")
end
sgs.ai_skill_use_func["#s_w_qimouCard"] = function(card, use, self)
	local target
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
	local enemies = self.enemies
	local selfDef = sgs.getDefense(self.player)
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
	if target and can_slash then
		local card_str = ("#s_w_qimouCard:.:")
		use.card = sgs.Card_Parse(card_str)
		if use.to then use.to:append(target) end
	end
end
sgs.ai_use_priority["s_w_qimouCard"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_playerchosen.s_w_qimou = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end


local s_w_shenghun_skill = {}
s_w_shenghun_skill.name = "s_w_shenghun"
table.insert(sgs.ai_skills, s_w_shenghun_skill)
s_w_shenghun_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#s_w_shenghun") or self.player:isKongcheng() then return end
	return sgs.Card_Parse("#s_w_shenghun:.:")
end

sgs.ai_skill_use_func["#s_w_shenghun"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount - 1 end

	if slashcount > 0 then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card and dummy_use.to:length() > 0 then
			for _, enemy in sgs.qlist(dummy_use.to) do
				if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self:canAttack(enemy, self.player) and self.player:canPindian(enemy)
					and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
					local enemy_max_card = self:getMaxCard(enemy)
					local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
					if max_point > enemy_max_point then
						--self.s_w_shenghun_card = max_card:getId()
						use.card = sgs.Card_Parse("#s_w_shenghun:.:")
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self:canAttack(enemy, self.player) and self.player:canPindian(enemy)
					and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
					if max_point >= 10 then
						--self.s_w_shenghun_card = max_card:getId()
						use.card = sgs.Card_Parse("#s_w_shenghun:.:")
						if use.to then use.to:append(enemy) end
						return
					end
				end
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	if (self:getUseValue(cards[1]) < 6 and self:getKeepValue(cards[1]) < 6) or self:getOverflow() > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and not enemy:hasSkills("tuntian+zaoxian") and self.player:canPindian(enemy) then
				--self.s_w_shenghun_card = cards[1]:getId()
				use.card = sgs.Card_Parse("#s_w_shenghun:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_cardneed.s_w_shenghun = function(to, card, self)
	local cards = to:getHandcards()
	local has_big = false
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:getNumber() > 10 then
				has_big = true
				break
			end
		end
	end
	if not has_big then
		return card:getNumber() > 10
	else
		return card:isKindOf("Slash") and card:isRed()
	end
end

function sgs.ai_skill_pindian.s_w_shenghun(minusecard, self, requestor)
	if requestor:getHandcardNum() == 1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return cards[1]
	end
	if requestor:getHandcardNum() <= 2 then return minusecard end
end

sgs.ai_card_intention["s_w_shenghun"] = 70


sgs.ai_use_value["s_w_shenghun"] = 9.2
sgs.ai_use_priority["s_w_shenghun"] = 9.2


sgs.ai_ajustdamage_from["s_w_wenjiu"]   = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:isRed() and from:getMark("s_w_wenjiu-PlayClear") == 0 then
		return 1
	end
end



sgs.ai_skill_invoke.s_w_juezhan_buqu = function(self, data)
	return true
end

sgs.ai_skill_invoke.s_w_juezhan_tuxi = function(self,prompt)
	local tuxi_string = sgs.ai_skill_use["@@tenyeartuxi"](self, prompt)
	if tuxi_string == "." then
		return false
	end
	return true
end


sgs.ai_skill_invoke.s_w_juezhan_wushuang1 = function(self, data)
	if (self.player:getMark("&s_w_yong") < 3) then return false end
	local use = data:toCardUse()
	for _, t in sgs.qlist(use.to) do
		if t and self:isEnemy(t) then
			return true
		end
	end
	return false
end

sgs.ai_skill_invoke.s_w_juezhan_wushuang2 = function(self, data)
	if (self.player:getMark("&s_w_yong") < 3) then return false end
	local effect = data:toCardEffect()
	if effect.from and effect.from:hasSkill("s_w_juezhan") then
		if effect.to and self:isFriend(effect.to) then
			return false
		end
	end
	if effect.to and effect.to:hasSkill("s_w_juezhan") then
		if effect.from and self:isFriend(effect.from) then
			return false
		end
	end
	return true
end

sgs.ai_skill_use["@@s_w_changshu"] = function(self, prompt, method)
	if self:getOverflow() > 0 then
		local target
		self:sort(self.friends_noself, "hp")
		if #self.friends_noself > 0 then
			for _, friend in ipairs(self.friends_noself) do
				if getBestHp(friend) < friend:getHp() and not hasManjuanEffect(friend) then
					target = friend
					break
				end
			end
			if not target then
				for _, friend in ipairs(self.friends_noself) do
					if (friend:hasSkills(sgs.notActive_cardneed_skill) or friend:hasSkills(sgs.Active_cardneed_skill)) and not hasManjuanEffect(friend) then
						target = friend
						break
					end
				end
			end
			if not target then
				for _, friend in ipairs(self.friends_noself) do
					if not hasManjuanEffect(friend) then
						target = friend
						break
					end
				end
			end
		end
		if target then
			local hcards = self.player:getCards("he")
			hcards = sgs.QList2Table(hcards)
			self:sortByUseValue(hcards, true)
			local use_card = {}
			local heartcard = {}
			local x = math.min(self.player:getLostHp(), target:getLostHp())
			for _, c in ipairs(hcards) do
				if c:getSuit() == sgs.Card_Heart and #heartcard < x then
					table.insert(heartcard, c:getEffectiveId())
				end
				table.insert(use_card, c:getEffectiveId())
				if #use_card >= 5 then
					break
				end
			end
			if #use_card > 0 then
				return "#s_w_changshu:" .. table.concat(use_card, "+") .. ":->" .. target:objectName()
			end
		end
	end
	return "."
end

sgs.ai_cardneed.s_w_yuma = function(to, card, self)
	local cards = to:getCards("e")
	if not to:getOffensiveHorse() then
		return card:isKindOf("OffensiveHorse")
	elseif not to:getDefensiveHorse() then
		return card:isKindOf("DefensiveHorse")
	end
end


function sgs.ai_cardsview.s_w_2_wenjiu(self, class_name, player)
	if class_name == "Analeptic" then
		local cards = player:getCards("h")
		cards = sgs.QList2Table(cards)
		local newcards = {}
		for _, card in ipairs(cards) do
			if not isCard("Analeptic", card, player) and not isCard("Peach", card, player) and not (isCard("ExNihilo", card, player)) then
				table.insert(newcards, card) end
		end
		if #newcards < 2 then return end
		sgs.ais[player:objectName()]:sortByKeepValue(newcards)

		local first_found, second_found = false, false
		local first_card, second_card
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Analeptic", fcard, player) or isCard("Peach", fcard, player) or (isCard("ExNihilo", fcard, player)))
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Analeptic", scard, player) or isCard("Peach", scard, player) or (isCard("ExNihilo", scard, player)))
					if first_card ~= scard and scard:getSuit() == first_card:getSuit()
						and not svalueCard then
						local card_str = ("analeptic:%s[%s:%s]=%d+%d"):format("s_w_2_wenjiu", "to_be_decided", 0,
							first_card:getId(), scard:getId())
						second_card = scard
						second_found = true
						break
					end
				end
			end
			if second_card then break end
		end
		if first_found and second_found then
			local first_id = first_card:getId()
			local second_id = second_card:getId()
			local card_str = ("analeptic:%s[%s:%s]=%d+%d"):format("s_w_2_wenjiu", "to_be_decided", 0, first_id, second_id)
			return card_str
		end
	end
end

local s_w_2_wenjiu_skill = {}
s_w_2_wenjiu_skill.name = "s_w_2_wenjiu"
table.insert(sgs.ai_skills, s_w_2_wenjiu_skill)
s_w_2_wenjiu_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	local newcards = {}
	for _, card in ipairs(cards) do
		if not isCard("Analeptic", card, self.player) and not isCard("Peach", card, self.player) and not (isCard("ExNihilo", card, self.player) and self.player:getPhase() == sgs.Player_Play) then
			table.insert(newcards, card) end
	end
	if #cards <= self.player:getHp() - 1 and self.player:getHp() <= 4 and not self:hasSkills("kongcheng|lianying|noslianying|shangshi|noshangshi") then return end
	if #newcards < 2 then return end

	local first_found, second_found = false, false
	local first_card, second_card
	for _, fcard in ipairs(cards) do
		local fvalueCard = (isCard("Analeptic", fcard, self.player)) or isCard("Peach", fcard, self.player) or (isCard("ExNihilo", fcard, self.player) )
		if not fvalueCard then
			first_card = fcard
			first_found = true
			for _, scard in ipairs(cards) do
				local svalueCard = (isCard("Analeptic", scard, self.player)) or isCard("Peach", scard, self.player) or (isCard("ExNihilo", scard, self.player))
				if first_card ~= scard and scard:getSuit() == first_card:getSuit()
					and not svalueCard then
					local card_str = ("analeptic:%s[%s:%s]=%d+%d"):format("s_w_2_wenjiu", "to_be_decided", 0,
						first_card:getId(), scard:getId())
					second_card = scard
					second_found = true
					break
				end
			end
		end
		if second_card then break end
	end
	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("analeptic:%s[%s:%s]=%d+%d"):format("s_w_2_wenjiu", "to_be_decided", 0, first_id, second_id)
		local analeptic = sgs.Card_Parse(card_str)
		return analeptic
	end
end


sgs.ai_skill_invoke.s_w_shouyou = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isFriend(damage.to) then
		return true
	end
	return false
end



sgs.ai_skill_playerchosen.s_w_shenzi = function(self, targets)
	local x = self.player:getLostHp() + 2
	if x == 2 and self.player:getJudgingArea():length() == 0 then
		return nil
	end
	self:sort(self.friends_noself, "handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _, friend in ipairs(self.friends_noself) do
		if (friend:hasSkills(sgs.notActive_cardneed_skill) or friend:hasSkills(sgs.Active_cardneed_skill)) and not hasManjuanEffect(friend) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend, self.player) then
			return friend
		end
	end
	return targets[1]
end



sgs.ai_used_revises.s_w_wuqian = function(self,use)
	if use.card:isKindOf("Slash")
	and not use.isDummy
	then
		for _,to in sgs.list(use.to)do
			if self:isEnemy(to) and self:isWeak(to)
			and to:getMark("Armor_Nullified")<1
			and self.player:getMark("&wrath")>=to:getHp()
			then
				use.card = sgs.Card_Parse("#s_w_wuqian:.:")
				use.to = sgs.SPlayerList()
				use.to:append(to)
				return false
			end
		end
	end
end
local s_w_wuqian_skill = {}
s_w_wuqian_skill.name = "s_w_wuqian"
table.insert(sgs.ai_skills, s_w_wuqian_skill)
s_w_wuqian_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#s_w_wuqian") or self.player:getMark("&wrath") < 2 then return end
	return sgs.Card_Parse("#s_w_wuqian:.:")
end

sgs.ai_skill_use_func["#s_w_wuqian"] = function(wuqiancard, use, self)
	if self:getCardsNum("Slash") > 0 and not self.player:hasSkill("wushuang") then
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if isCard("Duel", card, self.player) then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card and dummy_use.to:length() > 0 and (self:isWeak(dummy_use.to:first()) or dummy_use.to:length() > 1) then
					use.card = wuqiancard
					if use.to then use.to:append(dummy_use.to:first()) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value["s_w_wuqian"] = 5
sgs.ai_use_priority["s_w_wuqian"] = 10
sgs.ai_card_intention["s_w_wuqian"] = 80

sgs.ai_use_revises.s_w_wumou = function(self,card,use)
	if card:isNDTrick() and self.player:getMaxHp() < 4
	then
        if not (card:isKindOf("AOE") or card:isKindOf("IronChain") or card:isKindOf("Drowning"))
        and not (card:isKindOf("Duel") and getCardsNum("Peach")>0)
		then return false end
	end
end
sgs.ai_skill_choice.s_w_wumou = function(self, choices)
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
			if (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self.player:getHp() > least_hp) then return
				"hp" end
		end
		return "maxhp"
	else
		return "hp"
	end
end

sgs.ai_skill_discard["s_w_guishen"] = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(usable_cards)
	local to_discard = {}
	if self.player:getHp() < 4 then
		for _, c in ipairs(usable_cards) do
			if #to_discard < discard_num and not c:isKindOf("Peach") then
				table.insert(to_discard, c:getEffectiveId())
			end
		end
	end
	return {}
end


sgs.ai_skill_invoke.s_w_youhuo = true
sgs.ai_skill_choice.s_w_youhuo = function(self, choices, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		if damage.damage == 1 then
			return "s_w_youhuo_draw"
		else
			return "s_w_youhuo_recover"
		end
	end
	return "s_w_youhuo_draw"
end
sgs.ai_skill_playerchosen.s_w_juese = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if player:isLord() then lord = player end
		if self:isEnemy(player) and (not target or target:getHp() < player:getHp()) then
			target = player
		end
	end
	if target then return target end
	self:sort(targetlist, "hp")
	if lord then
		return lord
	end
	return targetlist[1]
end

sgs.ai_skill_invoke.s_w_yanzi = function(self, data)
	if self:isFriend(data:toPlayer()) and self:willSkipPlayPhase(data:toPlayer()) then
		return math.random() < 0.5
	end
    return true
end
sgs.ai_skill_choice.s_w_yanzi_disMark = function(self, choices, data)
	local target = data:toPlayer()
	if target then
		local x = target:getMark("&s_w_juese")
		x = math.max(1, x)
		x = math.min(x, 3)
		return tostring(x)
	end
	return "1"
end
sgs.ai_skill_choice.s_w_yanzi_in_de = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) and not self:willSkipPlayPhase(target) then
		return "s_w_yanzi_in"
	end
	return "s_w_yanzi_de"
end

sgs.ai_choicemade_filter.skillChoice["s_w_yanzi_in_de"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = self.room:getCurrent()
	if choice == "s_w_yanzi_in" then
		sgs.updateIntention(player, current, -80)
	elseif not self:willSkipPlayPhase(current) then
		sgs.updateIntention(player, current, 80)
	end
end




local s2_longhun_skill = {}
s2_longhun_skill.name = "s2_longhun"
table.insert(sgs.ai_skills, s2_longhun_skill)
s2_longhun_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:isWounded() then return end
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(handcards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(handcards, true)
	local equipments = sgs.QList2Table(self.player:getCards("e"))
	self:sortByUseValue(equipments, true)
	local basic_cards = {}
	local basic_cards_count = 0
	local non_basic_cards = {}
	local use_cards = {}

	if self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:isWounded() and self.player:getLostHp() >= 2 then
		table.insert(non_basic_cards, self.player:getArmor():getEffectiveId())
	end

	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach") then
			if c:isKindOf("BasicCard") then
				basic_cards_count = basic_cards_count + 1
				table.insert(basic_cards, c:getEffectiveId())
			else
				table.insert(non_basic_cards, c:getEffectiveId())
			end
		end
	end
	for _, e in ipairs(equipments) do
		if e:isKindOf("OffensiveHorse") then
			table.insert(non_basic_cards, e:getEffectiveId())
		end
	end
	if self:getOverflow() <= 0 then return end

	if #basic_cards > 0 then
		table.insert(use_cards, basic_cards[1])
	end
	if #use_cards == 0 then return end

	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and self:isGoodTarget(enemy, self.enemies, nil) and self.player:inMyAttackRange(enemy) then
			local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash")
			local fire_slash = sgs.Sanguosha:cloneCard("fire_slash")
			local slash = sgs.Sanguosha:cloneCard("slash")
			if not self:slashProhibit(fire_slash, enemy, self.player) and self:slashIsEffective(fire_slash, enemy, self.player) then
				return sgs.Card_Parse("#s2_longhun:" .. table.concat(use_cards, "+") .. ":" .. "fire_slash")
			end
			if not self:slashProhibit(thunder_slash, enemy, self.player) and self:slashIsEffective(thunder_slash, enemy, self.player) then
				return sgs.Card_Parse("#s2_longhun:" .. table.concat(use_cards, "+") .. ":" .. "thunder_slash")
			end
			if not self:slashProhibit(slash, enemy, self.player) and self:slashIsEffective(slash, enemy, self.player) then
				return sgs.Card_Parse("#s2_longhun:" .. table.concat(use_cards, "+") .. ":" .. "slash")
			end
		end
	end
	if self.player:isWounded() then
		if self.player:getLostHp() == 1 and #self.toUse > 0 then
			return 
		end
		return sgs.Card_Parse("#s2_longhun:" .. table.concat(use_cards, "+") .. ":" .. "peach")
	end
end

sgs.ai_skill_use_func["#s2_longhun"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local xin_zhayi_jibencard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	xin_zhayi_jibencard:setSkillName("s2_longhun")
	self:useBasicCard(xin_zhayi_jibencard, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["s2_longhun"] = 3
sgs.ai_use_value["s2_longhun"] = 3

sgs.ai_view_as["s2_longhun"] = function(card, player, card_place, class_name)
	if not player:isWounded() then return end
	local classname2objectname = {
		["Slash"] = "slash",
		["Jink"] = "jink",
		["Peach"] = "peach",
		["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash",
		["ThunderSlash"] = "thunder_slash"
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local no_have = true
	local cards = player:getCards("h")
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			cards:prepend(sgs.Sanguosha:getCard(id))
		end
	end
	for _, c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			no_have = false
			break
		end
	end
	if not no_have then return end
	--if class_name == "Peach"  then return end


	local handcards = sgs.QList2Table(player:getCards("h"))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(handcards, sgs.Sanguosha:getCard(id))
		end
	end
	local equipments = sgs.QList2Table(player:getCards("e"))
	local basic_cards = {}
	local non_basic_cards = {}
	local use_cards = {}

	if player:getArmor() and player:hasArmorEffect("silver_lion") and player:isWounded() and player:getLostHp() >= 2 then
		table.insert(non_basic_cards, player:getArmor():getEffectiveId())
	end

	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach") then
			if c:isKindOf("BasicCard") then
				table.insert(basic_cards, c:getEffectiveId())
			else
				table.insert(non_basic_cards, c:getEffectiveId())
			end
		end
	end
	for _, e in ipairs(equipments) do
		if not (e:isKindOf("Armor") or e:isKindOf("DefensiveHorse")) and not (e:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
			table.insert(non_basic_cards, e:getEffectiveId())
		end
	end

	if player:getMark("@s2_longhunUsed") == 0 then
		if #basic_cards > 0 then
			table.insert(use_cards, basic_cards[1])
		end
		if #use_cards == 0 then return end
	else
		if #basic_cards > 0 and #non_basic_cards > 0 then
			table.insert(use_cards, basic_cards[1])
			table.insert(use_cards, non_basic_cards[1])
		elseif #basic_cards > 1 and #non_basic_cards == 0 then
			table.insert(use_cards, basic_cards[1])
			table.insert(use_cards, basic_cards[2])
		end
		if #use_cards ~= 2 then return end
	end

	if player:getMark("@s2_longhunUsed") == 0 then
		if class_name == "Peach" then
			--local dying = player:getRoom():getCurrentDyingPlayer()
			--if dying and dying:getHp() < 0 then return end
			return (name .. ":s2_longhun[%s:%s]=%d"):format(sgs.Card_NoSuit, 0, use_cards[1])
		else
			return (name .. ":s2_longhun[%s:%s]=%d"):format(sgs.Card_NoSuit, 0, use_cards[1])
		end
	else
		if class_name == "Peach" then
			--local dying = player:getRoom():getCurrentDyingPlayer()
			--if dying and dying:getHp() < 0 then return end
			return (name .. ":s2_longhun[%s:%s]=%d+%d"):format(sgs.Card_NoSuit, 0, use_cards[1], use_cards[2])
		else
			return (name .. ":s2_longhun[%s:%s]=%d+%d"):format(sgs.Card_NoSuit, 0, use_cards[1], use_cards[2])
		end
	end
end

function sgs.ai_cardneed.s2_longhun(to, card, self)
	return card:isKindOf("BasicCard")
end

sgs.need_kongcheng = sgs.need_kongcheng .. "|s2_juejing"

sgs.ai_skill_playerchosen.s2_juejing = function(self, targets)
	if self:needKongcheng(self.player, true) then
		return nil
	end
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and (not target:hasSkills(sgs.lose_equip_skill) or self:doDisCard(target)) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and ((target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 0) or target:needToThrowArmor()) then return
			target end
	end

	return targets[1]
end


sgs.ai_skill_cardchosen["s2_juejing"] = function(self, who, flags)
	self:updatePlayers()
	if self.player:getPhase() == sgs.Player_Play then
		if flags:match("e") then
			if self:isEnemy(who) then
				if not who:hasSkills(sgs.lose_equip_skill) then
					for _, e in ipairs(sgs.QList2Table(who:getCards("e"))) do
						local equip_index = e:getRealCard():toEquipCard():location()
						return e:getEffectiveId()
					end
				end
			else
				if who:hasSkills(sgs.lose_equip_skill) then
					for _, e in ipairs(sgs.QList2Table(who:getCards("e"))) do
						local equip_index = e:getRealCard():toEquipCard():location()
						return e:getEffectiveId()
					end
				end
			end
		end
		if flags:match("j") then
			if self:isEnemy(who) then
				local judges = who:getJudgingArea()
				if who:containsTrick("YanxiaoCard") then
					for _, judge in sgs.qlist(judges) do
						if judge:isKindOf("YanxiaoCard") then
							return judge:getEffectiveId()
						end
					end
				end
			elseif self:isFriend(who) then
				local judges = who:getJudgingArea()
				for _, judge in sgs.qlist(judges) do
					if not judge:isKindOf("YanxiaoCard") then
						return judge:getEffectiveId()
					end
				end
			end
		end
		if flags:match("h") then
			if self:isEnemy(who) then
				for _, h in ipairs(sgs.QList2Table(who:getCards("h"))) do
					return h:getEffectiveId()
				end
			end
		end
	else
		if flags:match("h") then
			--if self:isEnemy(who) then
			for _, h in ipairs(sgs.QList2Table(who:getCards("h"))) do
				return h:getEffectiveId()
			end
			--end
		end
	end
end


s2_duanzui_skill = {}
s2_duanzui_skill.name = "s2_duanzui"
table.insert(sgs.ai_skills, s2_duanzui_skill)
s2_duanzui_skill.getTurnUseCard = function(self)
	if self.player:getMark("@s2_duanzui") <= 0 then return end
	if self.room:getMode() == "_mini_13" then return sgs.Card_Parse("#s2_duanzui:.:") end
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) and self:damageIsEffective(player, sgs.DamageStruct_Fire) then
			if self:isFriend(player) then
				bad = bad + 1
			else
				good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(player:getHp(), 1)
		if self:damageIsEffective(player, sgs.DamageStruct_Fire) then
			if getCardsNum("Analeptic", player) > 0 then
				if self:isFriend(player) then
					good = good + 1.0 / hp
				else
					bad = bad + 1.0 / hp
				end
			end


			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill, player) then lost_value = player:getHp() / 2 end
			local hp = math.max(player:getHp(), 1)
			if self:isFriend(player) then
				bad = bad + (lost_value + 1) / hp
			else
				good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad then return sgs.Card_Parse("#s2_duanzui:.:") end
end

sgs.ai_skill_use_func["#s2_duanzui"] = function(card, use, self)
	use.card = card
end

sgs.dynamic_value.damage_card["#s2_duanzui"] = true


local s2_shenpan_skill = {}
s2_shenpan_skill.name = "s2_shenpan"
table.insert(sgs.ai_skills, s2_shenpan_skill)
s2_shenpan_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#s2_shenpan") then
		return sgs.Card_Parse("#s2_shenpan:.:")
	end
end

sgs.ai_skill_use_func["#s2_shenpan"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
			if enemy:getHandcardNum() >= 2 then
				use.card = sgs.Card_Parse("#s2_shenpan:.:")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
end

sgs.ai_use_value.s2_shenpan = 2.5
sgs.ai_card_intention.s2_shenpan = 80
sgs.ai_use_priority.s2_shenpan = 4.2


sgs.ai_cardneed.s2_chengwu = function(to, card)
	return card:isRed() and isCard("Slash", card, to)
end

sgs.ai_ajustdamage_from.s2_chengwu = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and card:isRed()
    then
        return 1
    end
end



sgs.ai_need_damaged.s2_huzi = function(self, attacker, player)
	if not player:hasSkill("chanyuan") and player:hasSkill("s2_huzi") and player:getMark("s2_huzi") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() > 3 or player:getHp() == 3 and (player:faceUp() or player:hasSkill("guixin") or player:hasSkill("toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end


sgs.ai_skill_invoke.s2_touben_wei = function(self, data)
	if not self:isWeak() and (self.player:getHp() > 2 or (self:getCardsNum("Peach") > 0 and self.player:getHp() > 1)) then
		return true
	end
	return false
end


sgs.ai_skill_invoke.s2_touben_wu = function(self, data)
	if not self:isWeak() and (self.player:getHp() > 2 or (self:getCardsNum("Peach") > 0 and self.player:getHp() > 1)) then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.s2_nixi = function(self, targets)
	local target = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, targets, false, 0, false)[1]

	return target
end

local s2_jiange_skill = {}
s2_jiange_skill.name = "s2_jiange"
table.insert(sgs.ai_skills, s2_jiange_skill)
s2_jiange_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#s2_jiange") then
		if self.player:getHandcardNum() > 0 then
			return sgs.Card_Parse("#s2_jiange:.:")
		end
	end
end

sgs.ai_skill_use_func["#s2_jiange"] = function(card, use, self)
	use.card = card
	return
end

sgs.ai_use_value["s2_jiange"] = 2                                     --卡牌使用价值
sgs.ai_use_priority["s2_jiange"] = sgs.ai_use_priority.ExNihilo - 0.1 --卡牌使用优先级

sgs.ai_skill_invoke.s2_jiange_obtain = function(self)
	return true
end

sgs.ai_skill_askforag.s2_jiange = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByCardNeed(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end



sgs.ai_skill_cardask["@s2_jiange_add"] = function(self, data, pattern, target)
	return "."
end



sgs.ai_skill_invoke.s2_wuhun = function(self)
	if self.player:getHp() >= getBestHp(self.player) then
		return false
	end
	return true
end


sgs.ai_view_as.s2_wuhun = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
		and card_place == sgs.Player_PlaceHand
		and card:getSuit() == sgs.Card_Heart and not card:isKindOf("Peach") and not card:hasFlag("using") and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("slash:s2_wuhun[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local s2_wuhun_skill = {}
s2_wuhun_skill.name = "s2_wuhun"
table.insert(sgs.ai_skills, s2_wuhun_skill)
s2_wuhun_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	local red_card
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

	local disCrossbow = false
	if self:getCardsNum("Slash") <= 0 or self.player:hasSkill("paoxiao") then
		disCrossbow = true
	end
	
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Heart and not card:isKindOf("Slash") 
			and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0)
			and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			red_card = card
			break
		end
	end

	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getEffectiveId()
		local card_str = ("slash:s2_wuhun[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end

function sgs.ai_cardneed.s2_wuhun(to, card)
	return to:getHandcardNum() < 3 and card:getSuit() == sgs.Card_Heart
end

sgs.ai_skill_use["@@s2_wushen"] = function(self, prompt)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local slashcount = self:getCardsNum("Slash")
	local use_card = {}
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") and #use_card < slashcount then
			table.insert(use_card, card:getEffectiveId())
		end
	end
	if slashcount > 1 then
		return string.format("#s2_wushen:%s:", table.concat(use_card, "+"))
	end
	return "."
end

sgs.ai_skill_invoke.s2_gn_nixi = function(self, data)
	local tuxi_string = sgs.ai_skill_use["@@tenyeartuxi"](self, prompt)
	if tuxi_string == "." then
		return false
	end
	return true
end


local s2_gn_nixi_skill = {}
s2_gn_nixi_skill.name = "s2_gn_nixi"
table.insert(sgs.ai_skills, s2_gn_nixi_skill)
s2_gn_nixi_skill.getTurnUseCard = function(self, inclusive)
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
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end

			if self:getUseValue(card) > sgs.ai_use_value.Dismantlement and card:isKindOf("TrickCard") then
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end

			if shouldUse then
				black_card = card
				break
			end
		end
	end

	if black_card and self.player:getMark("&s2_jie") > 2 then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("dismantlement:s2_gn_nixi[%s:%s]=%d"):format(suit, number, card_id)
		local dismantlement = sgs.Card_Parse(card_str)

		assert(dismantlement)

		return dismantlement
	end
end

sgs.s2_gn_nixi_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.s2_gn_nixi(to, card)
	return card:isBlack()
end

sgs.ai_skill_cardask["@s2_guanhui-card"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not card:hasFlag("using") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	local card_id = self:getRetrialCardId(cards, judge)
	if card_id == -1 then
		if self:needRetrial(judge) and judge.reason ~= "beige" then
			if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
			self:sortByUseValue(cards, true)
			if not self:needBear() and self.player:getAttackRange() >= 3 then
				return "$" .. cards[1]:getId()
			end
		end
	elseif self:needRetrial(judge) then
		local card = sgs.Sanguosha:getCard(card_id)
		return "$" .. card_id
	end

	return "."
end

sgs.ai_skill_askforag.s2_guanhui = function(self, card_ids)
	local judge = self.room:getTag("s2_guanhui"):toJudge()
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	local card_id = self:getRetrialCardId(to_obtain, judge)
	if card_id == -1 then
		return to_obtain[1]:getEffectiveId()
	else
		return card_id
	end
end
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|s2_guanhui"
sgs.wizard_skill = sgs.wizard_skill .. "|s2_guanhui"

sgs.double_slash_skill = sgs.double_slash_skill .. "|s2_jiangmen"
sgs.bad_skills = sgs.bad_skills .. "|s2_duanya"
sgs.ai_skill_discard.s2_duanya = function(self,discard_num,min_num,optional,include_equip)
	return nosganglie_discard(self,discard_num,min_num,optional,include_equip,"")
end

sgs.ai_skill_use["@@s2_houqi"] = function(self, prompt)
	if self.player and (self.player:getPile("s2_fa"):length() > 0) then
		local use_card = {}
		for _, c in ipairs(sgs.QList2Table(self.player:getPile("s2_fa"))) do
			if #use_card == 0 and sgs.Sanguosha:getCard(c):isRed() then
				table.insert(use_card, sgs.Sanguosha:getCard(c):getEffectiveId())
				break
			end
		end
		if #use_card == 0 then
			for _, c in ipairs(sgs.QList2Table(self.player:getPile("s2_fa"))) do
				if (#use_card < 2) and sgs.Sanguosha:getCard(c):isBlack() then
					table.insert(use_card, sgs.Sanguosha:getCard(c):getEffectiveId())
				end
			end
		end
		if #use_card > 0 then
			return "#s2_houqi:" .. table.concat(use_card, "+") .. ":"
		end
	end
	return "."
end


sgs.ai_skill_invoke.s2_yongbing = function(self, data)
	if self:willSkipPlayPhase() then return false end
	if self:willSkipDrawPhase() then return true end
	local card = sgs.Sanguosha:cloneCard("amazing_grace", sgs.Card_NoSuit, 0)
	card:setSkillName("s2_yongbing")
	card:deleteLater()
	if self.player:getHp() + self:getAllPeachNum() - 1 <= 0 then return false end
	local dummy = self:aiUseCard(card, dummy())
    if dummy.card then
		return true
	end
	if self.player:hasSkill("s2_lixian") then
		return true
	end
	return false
end


sgs.ai_skill_choice.s2_lixian = function(self, choices, data)
    local items = choices:split("+")
    local aglist = self.room:getTag("AmazingGrace"):toIntList()
	local basic = 0 
	local equip = 0 
	local trick = 0
	local max = 0
	for _, card_id in sgs.qlist(aglist) do
		local card = sgs.Sanguosha:getCard(card_id)
		if card:isKindOf("BasicCard") then 
			basic = basic + 1 
		elseif card:isKindOf("EquipCard") then 
			equip = equip + 1 
		elseif card:isKindOf("TrickCard") then 
			trick = trick + 1 
		end
	end
	max = math.max(basic, equip, trick)
	if table.contains(items, "s2_lixian_basic") then
		if basic == max then
			return "s2_lixian_basic"
		end
	end
	if table.contains(items, "s2_lixian_equip") then
		if equip == max then
			return "s2_lixian_equip"
		end
	end
	if table.contains(items, "s2_lixian_trick") then
		if trick == max then
			return "s2_lixian_trick"
		end
	end
    return items[1]
end
sgs.ai_skill_playerchosen.s2_lixian = function(self, targets)
	local targetlist=sgs.QList2Table(targets)
	for _, player in ipairs(targetlist) do
		if self:isFriend(player) then return player end
	end
	for _, player in ipairs(targetlist) do
		return player
	end
end
function sgs.ai_armor_value.s2_jianzu(player, self, card)
	if card and (card:isKindOf("KylinBow") or card:isKindOf("Crossbow")) then return 4 end
end

sgs.ai_use_revises.s2_jianzu = function(self, card, use)
	if card and card:isKindOf("Weapon")
	then
		local same = self:getSameEquip(card)
		if same and (same:isKindOf("KylinBow") or same:isKindOf("Crossbow"))
		then
			return false
		end
	end
end
function sgs.ai_cardneed.s2_jianzu(to, card, self)
	if not self:willSkipPlayPhase(to) then
		return card:isKindOf("KylinBow") or card:isKindOf("Crossbow") 
	end
end

sgs.ai_ajustdamage_from.s2_shengjian = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and from:getWeapon() ~= nil
    then
        return 1
    end
end

sgs.ai_skill_invoke.s2_zhengyi = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isFriend(damage.to, self.player) and (not damage.from or not self:isFriend(damage.from, self.player)) then
		return true
	end
end
sgs.ai_choicemade_filter.skillInvoke.s2_zhengyi = function(self, player, promptlist)
    if promptlist[#promptlist] == "yes" then
		local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
        sgs.updateIntention(player, damage.to, -70)
    end
end


local s2_guimou_skill = {}
s2_guimou_skill.name = "s2_guimou"
table.insert(sgs.ai_skills, s2_guimou_skill)
s2_guimou_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasFlag("s2_guimoux") then return end
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(usable_cards, true)
	local cards = {}
	for _, c in ipairs(usable_cards) do
		local cardex = sgs.Sanguosha:cloneCard(sgs.Sanguosha:getCard(self.player:getMark("s2_guimouskill")):objectName(),
			c:getSuit(), c:getNumber())
		if not self.player:isCardLimited(cardex, sgs.Card_MethodUse, true) and cardex:isAvailable(self.player) and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink") < 3) and not cardex:isKindOf("IronChain") then
			local name = sgs.Sanguosha:getCard(self.player:getMark("s2_guimouskill")):objectName()
			local new_card = sgs.Card_Parse((name .. ":s2_guimou[%s:%s]=%d"):format(c:getSuitString(),
				c:getNumberString(), c:getEffectiveId()))
			assert(new_card)
			return new_card
		end
	end
end



sgs.ai_skill_playerchosen.s2_huandou = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and not hasZhaxiangEffect(target)
			and (self:isWeak(target) or not self.player:faceUp()) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and hasZhaxiangEffect(target) and not self:isWeak(target) and not (target:getHp() == 2 and target:hasSkill("chanyuan")) then return
			target end
	end
	return nil
end

sgs.ai_skill_playerchosen.s2_xingyi = function(self, targets)
	targets = sgs.QList2Table(targets)
	if #self.enemies > 0 then
		return self.enemies[math.random(1, #self.enemies)]
	end
	return targets[math.random(1, #targets)]
end
sgs.ai_playerchosen_intention.s2_xingyi = 40

sgs.ai_skill_choice["s2_xingyi"] = function(self, choices, data)
	local items = choices:split("+")
	local bad_skills = sgs.bad_skills:split("|")
	local can_duorui_items = {}
	for _, item in ipairs(items) do
		if not table.contains(bad_skills, item) then
			table.insert(can_duorui_items, item)
		end
	end
	return can_duorui_items[math.random(1, #can_duorui_items)]
end


local s2_yizei_skill = {}
s2_yizei_skill.name = "s2_yizei"
table.insert(sgs.ai_skills, s2_yizei_skill)
s2_yizei_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#s2_yizei") then
		return sgs.Card_Parse("#s2_yizei:.:")
	end
end

sgs.ai_skill_use_func["#s2_yizei"] = function(card, use, self)

	if #self.enemies == 0 then return end
	self:sort(self.enemies, "handcard")
	local target
	local friendt
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() > self.player:getHp() and not enemy:isKongcheng() and self:doDisCard(enemy, "h", true) then
			target = enemy
			break
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHp() > self.player:getHp() and not friend:isKongcheng() and self:doDisCard(friend, "h", true) then
				target = friend
				break
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() <= self.player:getHp() then
			friendt = friend
			break
		end
	end
	if target and friendt then
		use.card = sgs.Card_Parse("#s2_yizei:.:")
		if use.to then use.to:append(target) end
		if use.to then use.to:append(friendt) end
	end
end
sgs.ai_use_priority["s2_yizei"] = sgs.ai_use_priority.Peach + 0.1


local s2_zhanjiang_skill = {}
s2_zhanjiang_skill.name = "s2_zhanjiang"
table.insert(sgs.ai_skills, s2_zhanjiang_skill)
s2_zhanjiang_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#s2_zhanjiang") and not self.player:isKongcheng() then return sgs.Card_Parse(
		"#s2_zhanjiang:.:") end
end

sgs.ai_skill_use_func["#s2_zhanjiang"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard(self.player)
	local max_point = max_card:getNumber()
	if self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and self.player:canPindian(enemy) and enemy:getHp() < self.player:getHp() then
				use.card = sgs.Card_Parse("#s2_zhanjiang:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if (max_point > 10) then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and self.player:canPindian(enemy) and enemy:getHp() < self.player:getHp() then
				use.card = sgs.Card_Parse("#s2_zhanjiang:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end


sgs.ai_cardneed.s2_zhanjiang = sgs.ai_cardneed.bignumber
function sgs.ai_slash_prohibit.s2_hungui(self, from, to)
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:getHp() > 1 or #(self:getEnemies(from)) == 1 then return false end
	if from:getMaxHp() == 3 and from:getArmor() and from:getDefensiveHorse() then return false end
	if from:getMaxHp() <= 3 or (from:isLord() and self:isWeak(from)) then return true end
	if from:getMaxHp() <= 3 or (self.room:getLord() and from:getRole() == "renegade") then return true end
	return false
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|s2_hungui"
sgs.bad_skills = sgs.bad_skills .. "|s2_baizou"

sgs.ai_target_revises.s2_changsheng = function(to,card)
	if card:isKindOf("Duel")
	then return true end
end
function sgs.ai_cardneed.s2_changsheng(to, card)
    return card:isKindOf("Duel")
end
sgs.ai_cardneed.s2_danqi = sgs.ai_cardneed.slash

sgs.s2_danqi_keep_value = {
	Peach           = 6,
	Analeptic       = 5.8,
	Jink            = 5.2,
	Duel            = 5.5,
	FireSlash       = 5.6,
	Slash           = 5.4,
	ThunderSlash    = 5.5,
}

sgs.ai_skill_invoke.s2_danqi = function(self, data)
	local slashNum = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Slash") then
			slashNum = slashNum + 1
		end
	end
	return (self.player:getHp() > 3 and slashNum > 0) or (self.player:getHp() > 4)
end

sgs.ai_ajustdamage_from["s2_danqi"]   = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") then
		return from:getMark("s2_danqi")
	end
end

sgs.ai_skill_invoke.s2_tianjiang = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end

sgs.ai_cardneed.s2_tianjiang = sgs.ai_cardneed.slash
sgs.ai_cardneed.s2_tieji = sgs.ai_cardneed.slash

sgs.ai_ajustdamage_from["s2_tianjiang"]   = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:hasFlag("s2_tianjiang") then
		return 1
	end
end
sgs.ai_ajustdamage_from["s2_tieji"]   = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and (from:getOffensiveHorse() ~= nil or from:getDefensiveHorse() ~= nil) then
		return 1
	end
end
sgs.ai_skill_playerchosen.s2_haojiu = function(self, targets)
	local target = self:findPlayerToDraw(true, 1)
	if target then
		return target
	else
		self:sort(self.enemies, "hp")
		return self.enemies[1]
	end
end

sgs.bad_skills = sgs.bad_skills .. "|s2_cansi"
sgs.ai_skill_choice["s2_haojiu"] = function(self, choices, data)
	local items = choices:split("+")
	if self:isWeak() then
		return "s2_haojiu_draw"
	end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("s2_haojiu") then
			if self:isFriend(p) then
				return "s2_haojiu_draw"
			elseif self:isEnemy(p) then
				if self.player:getHp() > p:getHp() and not hasZhaxiangEffect(p) then
					return "s2_haojiu_losthp"
				end
			end
		end
	end
	return items[math.random(1, #items)]
end



sgs.ai_skill_cardask["@s2_nuhou-give"] = function(self,data)
	local target = data:toPlayer()
	local has_peach,has_analeptic,has_slash,has_jink
	for _,card in sgs.qlist(self.player:getHandcards())do
		if card:isKindOf("Peach") then has_peach = card
		elseif card:isKindOf("Analeptic") then has_analeptic = card
		elseif card:isKindOf("Slash") then has_slash = card
		elseif card:isKindOf("Jink") then has_jink = card
		end
	end

	if has_slash then return "$"..has_slash:getEffectiveId()
	elseif has_jink then return "$"..has_jink:getEffectiveId()
	elseif has_analeptic or has_peach then
		if has_analeptic then return "$"..has_analeptic:getEffectiveId()
		else return "$"..has_peach:getEffectiveId()
		end
	else return "."
	end
end

sgs.ai_target_revises.s2_nuhou = function(to,card,self,use)
	if card:isKindOf("TrickCard")
	and self:getCardsNum("BasicCard")-self:getCardsNum("Peach")<2
	then return true end
end



local s2_shanqi_skill = {}
s2_shanqi_skill.name = "s2_shanqi"
table.insert(sgs.ai_skills, s2_shanqi_skill)
s2_shanqi_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#s2_shanqi") then
		return sgs.Card_Parse("#s2_shanqi:.:")
	end
end

sgs.ai_skill_use_func["#s2_shanqi"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())


	if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self:getCardsNum("Nullification") + self:getCardsNum("SavageAssault") + self:getCardsNum("ArcheryAttack") + self:getCardsNum("Duel") == 0 then
		local use_zhiheng_cards = {}
		for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
			if c:isKindOf("OffensiveHorse") or c:isKindOf("DefensiveHorse") then
				table.insert(use_zhiheng_cards, c:getEffectiveId())
			end
		end
		for _, e in ipairs(sgs.QList2Table(self.player:getCards("e"))) do
			if e:isKindOf("OffensiveHorse") or e:isKindOf("DefensiveHorse") then
				table.insert(use_zhiheng_cards, e:getEffectiveId())
			end
		end
		if #use_zhiheng_cards > 0 then
			use.card = sgs.Card_Parse("#s2_shanqi:" .. table.concat(use_zhiheng_cards, "+") .. ":")
			if use.to then use.to:append(self.player) end
			return
		end
	end
end

sgs.ai_use_value["#s2_shanqi"] = 9
sgs.ai_use_priority["#s2_shanqi"] = 2.61
sgs.dynamic_value.benefit["#s2_shanqi"] = true

sgs.ai_skill_choice["s2_shanqi"] = function(self, choices, data)
	return "s2_shanqi_draw"
end


local s2_longwei_skill = {}
s2_longwei_skill.name = "s2_longwei"
table.insert(sgs.ai_skills, s2_longwei_skill)
s2_longwei_skill.getTurnUseCard = function(self, inclusive)
	self:updatePlayers()
	local patterns = {"slash", "jink", "analeptic", "nullification", "snatch", "dismantlement", "collateral", "duel", "fire_attack", "amazing_grace", "savage_assault", "archery_attack", "god_salvation", "iron_chain"}
	if not (Setlw(sgs.Sanguosha:getBanPackages()))["maneuvering"] then
		table.insert(patterns, 2, "thunder_slash")
		table.insert(patterns, 2, "fire_slash")
		table.insert(patterns, 2, "normal_slash")
	end
	local slash_patternslw = {"slash", "normal_slash", "thunder_slash", "fire_slash"}
	local choices = {}
	for _, name in ipairs(patterns) do
		local poi = sgs.Sanguosha:cloneCard(name, sgs.Card_NoSuit, -1)
		poi:deleteLater()
		if poi:isAvailable(self.player) then
			table.insert(choices, name)
		end
	end
	if self.player:isNude() then return end
	if sgs.playerRoles["rebel"] == 0 then return end
	if self.player:getMark("AI_do_not_invoke_s2_longwei-Clear") > 0 then return end

	if next(choices) and self.player:getMark("s2_longwei-Clear") == 0 then
		return sgs.Card_Parse("#s2_longwei_select:.:")
	end
end

sgs.ai_skill_use_func["#s2_longwei_select"] = function(card, use, self)
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
		if not c:isKindOf("EquipCard")
		then
			table.insert(useable_cards, c)
		end
	end
	--if #useable_cards == 0 then return end
	local card_str = "#s2_longwei_select:.:"
	local acard = sgs.Card_Parse(card_str)
	if #useable_cards >= 1 then
		if useable_cards[1]:hasFlag("xiahui") then return end
		self.room:setTag("ai_s2_longwei_card_id", sgs.QVariant(useable_cards[1]:getEffectiveId()))
		acard:addSubcard(useable_cards[1]:getEffectiveId())
		use.card = acard
	end
end

sgs.ai_use_priority["s2_longwei_select"] = 3
sgs.ai_use_value["s2_longwei_select"] = 3

sgs.ai_skill_choice["s2_longwei-new-choicetype"] = function(self, choices, data)
	local ai_s2_longwei_card_id = self.room:getTag("ai_s2_longwei_card_id"):toInt()
	if sgs.Sanguosha:getCard(ai_s2_longwei_card_id):isKindOf("BasicCard") then
		return "basic"
	elseif math.random() < 0.5 then
		return "single_target_trick"
	else
		return "multiple_target_trick"
	end
end
sgs.ai_skill_choice["s2_longwei"] = function(self, choices, data)
	self:updatePlayers()
	local ai_s2_longwei_card_id = self.room:getTag("ai_s2_longwei_card_id"):toInt()
	self.room:removeTag("ai_s2_longwei_card_id")
	local s2_longwei_vs_card = {}
	local items = choices:split("+")
	for _, card_name in ipairs(items) do
		if card_name ~= "cancel" then
			local use_card = sgs.Sanguosha:cloneCard(card_name, sgs.Card_SuitToBeDecided, -1)
			use_card:deleteLater()
			if not table.contains(s2_longwei_vs_card, use_card) then
				table.insert(s2_longwei_vs_card, use_card)
			end
		end
	end
	self:sortByUsePriority(s2_longwei_vs_card)
	for _, c in ipairs(s2_longwei_vs_card) do
		if table.contains(items, c:objectName()) then
			if c:targetFixed() then
				if c:isKindOf("SavageAssault") then
					if self:getAoeValue(c) > 0 then
						return c:objectName()
					end
				end
				if c:isKindOf("ArcheryAttack") then
					if self:getAoeValue(c) > 0 then
						return c:objectName()
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
						return c:objectName()
					end
				end
				if c:isKindOf("GodSalvation") then
					if self:willUseGodSalvation(c) then
						return c:objectName()
					end
				end
				if c:isKindOf("Analeptic") then
					for _, slash in ipairs(self:getCards("Slash")) do
						if slash:isKindOf("NatureSlash") and slash:isAvailable(self.player) and
						(slash:getEffectiveId() ~= ai_s2_longwei_card_id) then
							local dummy_use = self:aiUseCard(c, dummy())
							if not dummy_use.to:isEmpty() then
								for _, p in sgs.qlist(dummy_use.to) do
									if self:shouldUseAnaleptic(p, slash) then
										return c:objectName()
									end
								end
							end
						end
					end
				end
			else
				if c:isKindOf("NatureSlash") and self:getCardsNum("NatureSlash") == 0 then
					if c:isKindOf("FireSlash") or c:isKindOf("ThunderSlash") then
						local dummy_use = self:aiUseCard(c, dummy())
						if not dummy_use.to:isEmpty() then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:isChained() then
									self.room:setTag("ai_s2_longwei_card_id", sgs.QVariant(ai_s2_longwei_card_id))
									return c:objectName()
								end
							end
						end
					end
				end
				--if use_card:isNDTrick() then
				if c:isKindOf("TrickCard") and not c:isKindOf("Collateral") then
					local dummy_use = self:aiUseCard(c, dummy())
					if not dummy_use.to:isEmpty() then
						for _, p in sgs.qlist(dummy_use.to) do
							self.room:setTag("ai_s2_longwei_card_id", sgs.QVariant(ai_s2_longwei_card_id))
							return c:objectName()
						end
					end
				end
			end
		end
	end

	self.room:addPlayerMark(self.player, "AI_do_not_invoke_s2_longwei-Clear")
	return "cancel"
end

sgs.ai_skill_use["@@s2_longwei"] = function(self, prompt, method)
	local usecard = prompt:split(":")[2]
	local use_card = sgs.Sanguosha:cloneCard(usecard, sgs.Card_NoSuit, -1)
	use_card:setSkillName("s2_longwei")
	local ai_s2_longwei_card_id = self.room:getTag("ai_s2_longwei_card_id"):toInt()
	self.room:removeTag("ai_s2_longwei_card_id")
	use_card:addSubcard(ai_s2_longwei_card_id)
	local dummy_use = self:aiUseCard(use_card, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return use_card:toString() .. "->" .. table.concat(targets, "+")
		end
	end

	self.room:addPlayerMark(self.player, "AI_do_not_invoke_s2_longwei-Clear")
	return "."
end

sgs.ai_cardsview_valuable["s2_longwei"] = function(self, class_name, player)
	local classname2objectname = {
		["Slash"] = "slash",
		["Jink"] = "jink",
		["Analeptic"] = "analeptic",
		["Nullification"] = "nullification",
		["FireSlash"] = "fire_slash",
		["ThunderSlash"] = "thunder_slash"
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local no_have = true
	local cards = player:getCards("he")
	for _, id in sgs.qlist(player:getPile("wooden_ox")) do
		cards:prepend(sgs.Sanguosha:getCard(id))
	end
	for _, c in sgs.qlist(cards) do
		if c:isKindOf(class_name) then
			no_have = false
			break
		end
	end
	if not no_have or player:getMark("s2_longwei-Clear") ~= 0 then return end
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local card
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			if sgs.Sanguosha:getCard(id):isKindOf("BasicCard") then
				card = sgs.Sanguosha:getCard(id)
				break
			end
		end
	end
	if card then
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		return (name..":s2_longwei[%s:%s]=%d"):format(suit, number, card_id)
	end
	return
end

sgs.ai_skill_invoke.s2_tuxi = function(self, data)
	local target = data:toPlayer()
	return self:doDisCard(target, "h")
end
sgs.ai_cardneed.s2_tuxi = sgs.ai_cardneed.slash

sgs.ai_need_damaged.s2_wuwei = function(self, attacker, player)
	if not player:hasSkill("chanyuan") and player:hasSkill("s2_wuwei") and player:getMark("s2_wuwei") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() > 3 or player:getHp() == 3 and (player:faceUp() or player:hasSkill("guixin") or player:hasSkill("toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end


sgs.ai_skill_playerchosen.s2_muyi = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				return friend
			end
		end
	end


	return target
end

sgs.ai_playerchosen_intention.s2_muyi = -80

sgs.ai_skill_choice["s2_muyi"] = function(self, choices, data)
	local items = choices:split("+")
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("s2_muyi_target") then
			local x = math.abs(p:getHandcardNum() - self.player:getHandcardNum())
			if x > 1 then
				return "s2_muyi1"
			else
				return "s2_muyixd1"
			end
		end
	end
	return items[math.random(1, #items)]
end


sgs.ai_skill_invoke.s2_yaowu = function(self, data)
	local heart = 0
	local diamond = 0
	local spade = 0
	local club = 0
	local suit = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getSuitString() == "club" then
			club = 1
		elseif card:getSuitString() == "spade" then
			spade = 1
		elseif card:getSuitString() == "diamond" then
			diamond = 1
		elseif card:getSuitString() == "heart" then
			heart = 1
		end
	end
	if club >= 1 then
		suit = suit + 1
	end
	if spade >= 1 then
		suit = suit + 1
	end
	if diamond >= 1 then
		suit = suit + 1
	end
	if heart >= 1 then
		suit = suit + 1
	end
	if suit == 2 then
		return true
	end
	if suit >= 3 or self:isWeak() then
		return true
	end
end


local s2_bayeVS_skill = {}
s2_bayeVS_skill.name = "s2_bayeVS"
table.insert(sgs.ai_skills,s2_bayeVS_skill)
s2_bayeVS_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if (acard:getSuit() == sgs.Card_Spade and self.player:getKingdom() == "shu") or
		(acard:getSuit() == sgs.Card_Heart and self.player:getKingdom() == "wei") or
		(acard:getSuit() == sgs.Card_Diamond and self.player:getKingdom() == "wu") or
		(acard:getSuit() == sgs.Card_Club and self.player:getKingdom() == "qun")
			then
			return sgs.Card_Parse("#s2_bayeCard:"..acard:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#s2_bayeCard"] = function(card,use,self)
	local targets = {}
	for _,friend in ipairs(self.friends_noself)do
		if friend:hasLordSkill("s2_baye") then
			if not friend:hasFlag("s2_bayeInvoked") then
				if not hasManjuanEffect(friend) then
					table.insert(targets,friend)
				end
			end
		end
	end
	if #targets>0 then --黄天己方
		use.card = card
		self:sort(targets,"defense")
		use.to:append(targets[1])
	end
end

sgs.ai_card_intention["s2_bayeCard"] = function(self,card,from,tos)
	sgs.updateIntention(from,tos[1],-80)
end

sgs.ai_skill_invoke.s2_fanji = function(self, data)
	local target = data:toPlayer()
	local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	card:deleteLater()
	card:setSkillName("s2_fanji")
	if target then
		local dummy_use = self:aiUseCard(card, dummy(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
			return true
		end
	end
	return false
end

sgs.ai_view_as.s2_fenzhan = function(card, player, card_place)
	local usable_cards = sgs.QList2Table(player:getCards("h"))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(usable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()

	local two_cards = {}
	for _, c in ipairs(usable_cards) do
		if c:getSuit() == card:getSuit() and #two_cards < 2 then
			--[[if not isCard("Jink", card, player) and not isCard("Peach", card, player)
			and not (isCard("ExNihilo", card, player) and player:getPhase() == sgs.Player_Play)
			and not isCard("Jink", c, player) and not isCard("Peach", c, player)
			and not (isCard("ExNihilo", c, player) and player:getPhase() == sgs.Player_Play) then ]]
			table.insert(two_cards, c:getEffectiveId())
			--end
		end
	end


	if #two_cards == 2 and not card:isKindOf("Jink") then
		return ("jink:s2_fenzhan[%s:%s]=%d+%d"):format("to_be_decided", 0, two_cards[1], two_cards[2])
	end
end


sgs.ai_skill_invoke.s2_maifu = function(self, data)
	if self:getHandcardNum() <= 4 and #self.enemies > 0 then return true end
	return false
end

sgs.ai_skill_playerchosen.s2_maifu = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(self.enemies, "hp")
	for _, p in ipairs(targets) do
		if p and self:isEnemy(p) then
			return p
		end
	end
	return targets[math.random(1, #targets)]
end

sgs.ai_skill_choice["s2_maifu"] = function(self, choices, data)
	local items = choices:split("+")
	local bad_skills = sgs.bad_skills:split("|")
	local can_duorui_items = {}
	for _, item in ipairs(items) do
		if not table.contains(bad_skills, item) then
			table.insert(can_duorui_items, item)
		end
	end
	return can_duorui_items[math.random(1, #can_duorui_items)]
end



sgs.ai_skill_invoke.s2_shuangdao = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end


sgs.ai_skill_playerchosen.s2_huzhu = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) and friend:getEquips():length() then
			return friend
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.s2_huzhu = -80

sgs.ai_skill_playerchosen.s2_xiaoguo = function(self, targets)
	local target = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, targets, false, 0)[1]

	return target
end
sgs.ai_skill_cardask["s2_xiaoguo"] = function(self, data, pattern, target, target2)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local use_card = {}
	self:sortByKeepValue(handcards)
	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach")
			and not c:isKindOf("Analeptic")
			and not c:isKindOf("Jink")
			and not c:isKindOf("Nullification")
		then
			table.insert(use_card, c)
		end
	end
	if #use_card > 0 then
		return use_card[1]:toString()
	end
	return handcards[1]:toString()
end




local s2_xiaoguo_skill = {}
s2_xiaoguo_skill.name = "s2_xiaoguo"
table.insert(sgs.ai_skills, s2_xiaoguo_skill)
s2_xiaoguo_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#s2_xiaoguo") then return sgs.Card_Parse("#s2_xiaoguo:.:") end
end

sgs.ai_skill_use_func["#s2_xiaoguo"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if #targets < 2 and not enemy:isKongcheng() then
			table.insert(targets, enemy)
		else
			break
		end
	end
	if #targets ~= 2 then return end
	local card_str = ("#s2_xiaoguo:.:")
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	if use.to then
		for i = 1, #targets, 1 do
			use.to:append(targets[i])
		end
	end
	--if use.to then use.to:append(target) end
end
sgs.ai_use_priority["s2_xiaoguo"] = 7
sgs.ai_use_value["s2_xiaoguo"] = 7


local s2_xiande_skill = {}
s2_xiande_skill.name = "s2_xiande"
table.insert(sgs.ai_skills, s2_xiande_skill)
s2_xiande_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#s2_xiande") and self.player:getHp() >= 2 and sgs.ai_skill_playerchosen["s2_xiande_recover"](self,self.room:getAlivePlayers()) ~= nil  then return sgs.Card_Parse("#s2_xiande:.:") end
end

sgs.ai_skill_use_func["#s2_xiande"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if #targets < 2 and not enemy:isKongcheng() then
			table.insert(targets, enemy)
		else
			break
		end
	end
	if #targets ~= 2 then return end
	local card_str = ("#s2_xiande:.:")
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	if use.to then
		for i = 1, #targets, 1 do
			use.to:append(targets[i])
		end
	end
	--if use.to then use.to:append(target) end
end
sgs.ai_use_priority["s2_xiande"] = 7
sgs.ai_use_value["s2_xiande"] = 7


sgs.ai_skill_cardask["s2_xiande"] = function(self, data, pattern, target, target2)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local use_card = {}
	self:sortByKeepValue(handcards)
	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach")
			and not c:isKindOf("Analeptic")
			and not c:isKindOf("Jink")
			and not c:isKindOf("Nullification")
		then
			table.insert(use_card, c)
		end
	end
	if #use_card > 0 then
		return use_card[1]:toString()
	end
	return handcards[1]:toString()
end


sgs.ai_skill_playerchosen["s2_xiande_draw"] = function(self, targets)
	local target = self:findPlayerToDraw(true, 2)
	if target then
		return target
	else
		self:sort(self.friends, "hp")
		return self.friends[1]
	end
end
sgs.ai_skill_playerchosen["s2_xiande_recover"] = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				return friend
			end
		end
	end


	return nil
end
sgs.ai_playerchosen_intention.s2_xiande_draw = -80
sgs.ai_playerchosen_intention.s2_xiande_recover = -80
sgs.exclusive_skill = sgs.exclusive_skill .. "|s2_toujing"

sgs.ai_skill_playerchosen.s2_toujing = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if player:isLord() then lord = player end
		if self:isFriend(player) and (not target or target:getHp() < player:getHp()) then
			target = player
		end
	end
	if self.role == "loyalist" and lord then return lord end
	if target then return target end
	self:sort(targetlist, "hp")
	return targetlist[1]
end

sgs.ai_skill_invoke["s2_tujin"] = function(self, data)
	local use = data:toCardUse()
	if use.to:length() > 1 then return true end
	local target = use.to:at(0)
	if self:isFriend(target) then return false end
	if not self:slashIsEffective(data:toCardUse().card, target) then return false end
	if getCardsNum("Jink", target, self.player) == 0 then return true end
	local player = use.from
	if target:isKongcheng() or self:canLiegong(target, player) then return true end
	if self:isWeak(target) and math.random(1, 2) == 1 then return true end
	if target:getHandcardNum() == 1 and math.random(1, 3) > 1 then return true end
	if target:getHandcardNum() > 3 then return false end
	return math.random(1, 5) == 1
end

sgs.ai_skill_playerchosen.s2_tujin = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if self:isEnemy(player) and (not target or target:getHp() > player:getHp()) then
			target = player
		end
	end
	if target then return target end
	self:sort(targetlist, "hp")
	return targetlist[1]
end
sgs.ai_playerchosen_intention.s2_tujin = 50

sgs.ai_skill_choice["s2_zhenyan_draw"] = function(self, choices, data)
	return "5"
end

sgs.ai_skill_playerchosen.s2_zhenyan = function(self, targets)
	local target = self:findPlayerToDraw(true, 1)
	if target then
		return target
	else
		self:sort(self.friends, "hp")
		return self.friends[1]
	end
end
sgs.ai_playerchosen_intention.s2_zhenyan = function(self, from, to)
	sgs.updateIntention(from, to, -50)
end


sgs.ai_skill_askforag["s2_zhenyan"] = function(self, card_ids)
	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByCardNeed(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_skill_invoke.s2_boxing = function(self, data)
	local damage = data:toDamage()
	if self:isWeak() or damage.damage >= 2 then
		return damage.nature == sgs.DamageStruct_Normal or
		(damage.nature ~= sgs.DamageStruct_Normal and not self:isGoodChainTarget(self.player, damage.card, damage.from, damage.damage))
	end
end

sgs.ai_skill_playerchosen.s2_boxing = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getEquips():length() > 0 and (self:isWeak(p) or p:hasSkills(sgs.lose_equip_skill)) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getEquips():length() > 0 then
			return p
		end
	end
end
sgs.ai_playerchosen_intention.s2_boxing = function(self, from, to)
	sgs.updateIntention(from, to, -50)
end


local s2_jinchi_skill = {}
s2_jinchi_skill.name = "s2_jinchi"
table.insert(sgs.ai_skills, s2_jinchi_skill)
s2_jinchi_skill.getTurnUseCard = function(self)
	if not self.player:getArmor() then return end

	return sgs.Card_Parse("#s2_jinchi:.:")
end

sgs.ai_skill_use_func["#s2_jinchi"] = function(card, use, self)
	if not self.player:getArmor() then return end

	local target
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) and friend:getEquip(2) == nil and friend:hasEquipArea(2) and friend:getHandcardNum() > 5 and friend:isMale() then
			target = friend
			break
		end
		if target then break end
		if friend:getEquip(2) == nil and friend:hasEquipArea(2) and friend:getHandcardNum() > 5 and friend:isMale() then
			target = friend
			break
		end
		if target then break end
	end

	if not target then return end
	local acard = sgs.Card_Parse("#s2_jinchi:.:")
	use.card = acard
end


sgs.ai_skill_playerchosen.s2_jinchi = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) and friend:getEquip(2) == nil and friend:hasEquipArea(2) and friend:getHandcardNum() > 5 and friend:isMale() then
			return friend
		end
		if target then break end
		if friend:getEquip(2) == nil and friend:hasEquipArea(2) and friend:getHandcardNum() > 5 and friend:isMale() then
			return friend
		end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention.s2_jinchi = function(self, from, to)
	sgs.updateIntention(from, to, -50)
end

sgs.ai_view_as.s2_douba = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id))
		and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("slash:s2_douba[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local s2_douba_skill = {}
s2_douba_skill.name = "s2_douba"
table.insert(sgs.ai_skills, s2_douba_skill)
s2_douba_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	local red_card
	local black_card
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

	local disCrossbow = false
	if self:getCardsNum("Slash") <= 0 or self.player:hasSkill("paoxiao") then
		disCrossbow = true
	end


	for _, card in ipairs(cards) do
		if card:isRed() and not card:isKindOf("Slash") and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0)
			and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			red_card = card
			break
		end
	end
	for _, card in ipairs(cards) do
		if card:isBlack() and (not isCard("Crossbow", card, self.player))
			and (self:getUseValue(card) < sgs.ai_use_value.Duel or inclusive) then
			black_card = card
			break
		end
	end

	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("duel:s2_douba[%s:%s]=%d"):format(suit, number, card_id)
		local duel = sgs.Card_Parse(card_str)

		assert(duel)
		return duel
	end
	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getEffectiveId()
		local card_str = ("slash:s2_douba[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end


local s2_zhanpo_skill = {}
s2_zhanpo_skill.name = "s2_zhanpo"
table.insert(sgs.ai_skills, s2_zhanpo_skill)
s2_zhanpo_skill.getTurnUseCard = function(self)
	local z = self.player:getLostHp() + 1
	if not self.player:hasUsed("#s2_zhanpo") and self.player:getMark("s2_zhanpoduel") >= z then
		return sgs.Card_Parse("#s2_zhanpo:.:")
	end
end

sgs.ai_skill_use_func["#s2_zhanpo"] = function(card, use, self)
	local target
	for _, enemy in ipairs(self.enemies) do
		if not self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, enemy) and enemy:getWeapon() then
			target = enemy
			break
		end
		if target then break end
		if enemy:getWeapon() then
			target = friend
			break
		end
		if target then break end
	end

	if not target then return end
	local acard = sgs.Card_Parse("#s2_zhanpo:.:")
	use.card = acard
	if use.to then use.to:append(target) end
end




sgs.ai_skill_playerchosen.s2_zhanpo = function(self, targets)
	self:sort(self.friends_noself, "handcard")
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() < self.player:getHandcardNum() then
			return friend
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.s2_zhanpo = function(self, from, to)
	sgs.updateIntention(from, to, -50)
end

sgs.ai_skill_invoke.s2_taoni = function(self, data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(use.to) do
		if p and self:isFriend(p) then
			return false
		end
	end
	return true
end
sgs.ai_cardneed.s2_taoni = sgs.ai_cardneed.slash

sgs.ai_skill_discard.s2_jubing = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if cards[1] == nil then return {} end
	table.insert(to_discard, cards[1]:getEffectiveId())
	if (sgs.ai_skill_invoke.fangquan(self)) then
		return to_discard
	end

	return {}
end
sgs.ai_skill_playerchosen.s2_jubing = function(self, targets)
	local lord = self.room:getLord()
	if lord and self:isFriend(lord) and lord:objectName() ~= self.player:objectName() then
		return lord
	end
	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
		return AssistTarget
	end

	self:sort(self.friends_noself, "chaofeng")
	for _, target in ipairs(self.friends_noself) do
		if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
			and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) then
			return target
		end
	end

	for _, target in ipairs(self.friends_noself) do
		if target:hasSkill("dawu") then
			local use = true
			for _, p in ipairs(self.friends_noself) do
				if p:getMark("@fog") > 0 then
					use = false
					break
				end
			end
			if use then
				return target
			end
		else
			return target
		end
	end
end
sgs.ai_playerchosen_intention.s2_jubing = function(self, from, to)
	sgs.updateIntention(from, to, -80)
end



sgs.ai_skill_playerchosen.s2_budai = function(self, targets)
	self:sort(self.friends, "hp")
	for _, friend in ipairs(self.friends) do
		if self.player:inMyAttackRange(friend) then
			return friend
		end
	end
	return self.player
end
sgs.ai_playerchosen_intention.s2_budai = function(self, from, to)
	sgs.updateIntention(from, to, -50)
end




sgs.ai_skill_invoke.s2_bashi = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end


local s2_danjing_skill = {}
s2_danjing_skill.name = "s2_danjing"
table.insert(sgs.ai_skills, s2_danjing_skill)
s2_danjing_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#s2_danjing") and self.player:getPile("s2_shi"):length() > self.player:getLostHp() then
		return sgs.Card_Parse("#s2_danjing:.:")
	end
end

sgs.ai_skill_use_func["#s2_danjing"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local target
	for _, p in ipairs(self.enemies) do
		if self.player:canPindian(p) then
			target = p
		end
	end
	if target then
		use.card = card
	end
	return
end

sgs.ai_use_priority["s2_danjing"] = 2.61

sgs.ai_skill_playerchosen.s2_danjing = function(self, targets)
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy, true) then
			return enemy
		end
	end
	return targets[1]
end
sgs.ai_cardneed.s2_xuezhan = sgs.ai_cardneed.slash




local s2_leiyin_skill = {}
s2_leiyin_skill.name = "s2_leiyin"
table.insert(sgs.ai_skills, s2_leiyin_skill)
s2_leiyin_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	if not self.player:hasUsed("#s2_leiyin") and not self.player:isKongcheng() then return sgs.Card_Parse(
		"#s2_leiyin:.:") end
end

sgs.ai_skill_use_func["#s2_leiyin"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard(self.player)
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if max_card:isKindOf("Slash") then slashcount = slashcount - 1 end
	if self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and self.player:canPindian(enemy) then
				--self.dahe_card = max_card:getId()
				use.card = sgs.Card_Parse("#s2_leiyin:" .. max_card:getId() .. ":")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if slashcount > 0 then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = self:aiUseCard(slash, dummy())
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1 and enemy:getHp() > self.player:getHp())
				and not enemy:isKongcheng() and self.player:canSlash(enemy, nil, true) and self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local allknown = 0
				if self:getKnownNum(enemy) == enemy:getHandcardNum() then
					allknown = allknown + 1
				end
				if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
					or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10)
					or (not enemy_max_card and max_point > 10) then
					--self.dahe_card = max_card:getId()
					use.card = sgs.Card_Parse("#s2_leiyin:" .. max_card:getId() .. ":")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

function sgs.ai_skill_pindian.s2_leiyin(minusecard, self, requestor)
	if self:isFriend(requestor) then return minusecard end
	return self:getMaxCard()
end

sgs.ai_use_priority["s2_leiyin"] = sgs.ai_use_priority.DaheCard
sgs.ai_use_value["s2_leiyin"] = sgs.ai_use_value.DaheCard
sgs.ai_cardneed.s2_leiyin = sgs.ai_cardneed.bignumber




sgs.ai_view_as.s2_yezhan = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
		and card:isBlack() and not card:hasFlag("using") then
		return ("slash:s2_yezhan[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local s2_yezhan_skill = {}
s2_yezhan_skill.name = "s2_yezhan"
table.insert(sgs.ai_skills, s2_yezhan_skill)
s2_yezhan_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	local black_card
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

	local disCrossbow = false
	if self:getCardsNum("Slash") <= 0 or self.player:hasSkill("paoxiao") then
		disCrossbow = true
	end

	self:sort(self.enemies, "defense")

	for _, card in ipairs(cards) do
		if card:isBlack() and not card:isKindOf("Slash")
			and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) and not disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0) then
			black_card = card
			break
		end
	end


	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("slash:s2_yezhan[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)
		return slash
	end
end


sgs.ai_ajustdamage_from.s2_shenwei = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and (card:hasFlag("s2_shenwei") or (not beFriend(to, from) and getCardsNum("Slash", from, to) > 0))
    then
        return 1
    end
end

function sgs.ai_cardneed.s2_yezhan(to, card)
	return to:getHandcardNum() < 3 and card:isBlack()
end

sgs.ai_skill_invoke.s2_yizhan = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isFriend(target) then
		if damage.damage == 1 and self:needToLoseHp(target, damage.from, damage.card) then
			return false
		end
		return true
	else
		if self:hasHeavyDamage(self.player, damage.card, target) then return false end
		if self:isWeak(target) then return false end
		if self:needToLoseHp(target, damage.from, damage.card) then return true end
		return false
	end
end

sgs.ai_use_revises.s2_chuanyang = function(self,card,use)
	if card:isKindOf("Slash") then
		card:setFlags("Qinggang")
	end
end
sgs.ai_can_damagehp.s2_guimou_2 = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
	and self:canLoseHp(from,card,to)
end


sgs.ai_skill_use["@@s2_andu"] = function(self, prompt)
	if self.player and (self.player:getPile("s2_gong"):length() > 0) then
		local use_card = {}

		for _, c in ipairs(sgs.QList2Table(self.player:getPile("s2_gong"))) do
			if (#use_card < 2) then
				table.insert(use_card, sgs.Sanguosha:getCard(c):getEffectiveId())
			end
		end
		if #use_card == 2 then
			return "#s2_andu:" .. table.concat(use_card, "+") .. ":"
		end
	end
	return "."
end


sgs.ai_skill_invoke.s2_shemi = function(self, data)
	if self:needBear() then return true end
	if self:isWeak() or not self.player:faceUp() then return true end
	if self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) + self.player:getLostHp() + 2 <= 5 then
		return true
	end
	return false
end

sgs.ai_skill_invoke.s2_jiujia = function(self)
	local lord = self.room:getCurrentDyingPlayer()
	local save = false
	if lord and lord:getLostHp() > 0 then
		if self:isFriend(lord) then
			save = true
		elseif self.role == "renegade" and lord:isLord() and self.room:alivePlayerCount() > 2 then
			if lord:getHp() <= 0 then
				save = true
			end
		end
	end
	if save then
		local hp_max = lord:getHp() + self:getAllPeachNum(lord)
		local must_save = (hp_max <= 1)

		if not self.player:faceUp() then
			return true
		elseif must_save then
			if hp_max <= 0 then
				return true
			elseif self.role == "renegade" or self.role == "lord" then
				return false
			end
		end
	end
	return false
end
sgs.ai_choicemade_filter["skillInvoke"]["s2_jiujia"] = function(self, player, promptlist)
	if #promptlist == "yes" then
		local lord = self.room:getCurrentDyingPlayer()
		if lord and not self:hasSkills(sgs.masochism_skill, player) then
			sgs.updateIntention(player, lord, -60)
		end
	end
end


sgs.ai_cardneed.s2_feijun = sgs.ai_cardneed.bignumber
sgs.ai_skill_invoke.s2_feijun = function(self, data)
	local damage = data:toDamage()
	local dummy_use = self:aiUseCard(damage.card,dummy(true,0,self.room:getOtherPlayers(damage.to)))
	if dummy_use.card and dummy_use.to:contains(damage.to) then
		local max_card = self:getMaxCard()
		if max_card and max_card:getNumber() > 10 then
			return self:isEnemy(damage.to)
		end
		if self:isEnemy(damage.to) then
			if self:getOverflow() > 0 then return true end
		end
	end
	return false
end

function sgs.ai_skill_pindian.s2_feijun(minusecard, self, requestor, maxcard)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local function compare_func(a, b)
		return a:getNumber() > b:getNumber()
	end
	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if card:getNumber() > 10 then return card end
	end
	self:sortByKeepValue(cards)
	return cards[1]
end

s2_chizha_skill = {}
s2_chizha_skill.name = "s2_chizha"
table.insert(sgs.ai_skills, s2_chizha_skill)
s2_chizha_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#s2_chizha") then
		return sgs.Card_Parse("#s2_chizha:.:")
	end
end

sgs.ai_skill_use_func["#s2_chizha"] = function(card, use, self)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)

	local target
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if self:getDangerousCard(enemy) then
				target = enemy
				break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				target = friend
				break
			end
		end
	end
	if not target then
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if self:getValuableCard(enemy) then
				target = enemy
				break
			end
			if target then break end

			local cards = sgs.QList2Table(enemy:getHandcards())
			local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), enemy:objectName())
			if not enemy:isKongcheng() and not enemy:hasSkills("tuntian+zaoxian") then
				for _, cc in ipairs(cards) do
					if (cc:hasFlag("visible") or cc:hasFlag(flag)) and (cc:isKindOf("Peach") or cc:isKindOf("Analeptic")) then
						target = enemy
						break
					end
				end
			end
			if target then break end

			if self:getValuableCard(enemy) then
				target = enemy
				break
			end
			if target then break end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends_noself) do
			if friend:hasSkills("tuntian+zaoxian") and not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				target = friend
				break
			end
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isNude() then
				target = enemy
				break
			end
		end
	end

	if target then
		local willUse
		if self:isFriend(target) then
			for _, card in ipairs(cards) do
				if card:getSuit() == sgs.Card_Heart then
					willUse = card
					break
				end
			end
		else
			for _, card in ipairs(cards) do
				if card:getSuit() == sgs.Card_Heart and not isCard("Peach", card, target) and not isCard("Nullification", card, target) then
					willUse = card
					break
				end
			end
		end

		if willUse then
			use.card = sgs.Card_Parse("#s2_chizha:" .. willUse:getEffectiveId() .. ":")
			if use.to then use.to:append(target) end
		end
	end
end


sgs.ai_skill_invoke.s2_chizha = function(self, data)
	local target = data:toPlayer()
	if target then
		if self:isFriend(target) then
			return (self:needKongcheng(target, true) or (self:isWeak(target) and target:getHandcardNum() < 2 and self:getMaxCard(target) < 8))
		elseif self:isEnemy(target) then
			return true
		end
	end
end

sgs.ai_cardneed.s2_qigong = sgs.ai_cardneed.slash
sgs.s2_qigong_keep_value = sgs.paoxiao_keep_value

sgs.ai_need_damaged.s2_hengjiang = function(self, attacker, player)
	if not player:hasSkill("chanyuan") and player:hasSkill("s2_hengjiang") and player:getMark("s2_hengjiang") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() > 2 or player:getHp() == 2 and (player:faceUp() or player:hasSkill("guixin") or player:hasSkill("toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end



sgs.ai_skill_playerchosen.s2_jizhan = sgs.ai_skill_playerchosen.zero_card_as_slash


sgs.ai_skill_cardask["@s2_jizhan-exchange"] = function(self, data)
	local suit = data:toString()
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not card:hasFlag("using") and card:getSuitString() == suit and not card:isKindOf("Peach") then
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	local victims = sgs.SPlayerList()
	slash:setSkillName("s2_jizhan")
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:canSlash(p, slash, false) then
			victims:append(p)
		end
	end
	if not victims:isEmpty() then
	if sgs.ai_skill_playerchosen.zero_card_as_slash(self,victims) ~= nil then
		return "$" .. cards[1]:getId()
	end
end
	return "."
end

s2_xubian_skill = {}
s2_xubian_skill.name = "s2_xubian"
table.insert(sgs.ai_skills, s2_xubian_skill)
s2_xubian_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return end
	if self.player:hasUsed("#s2_xubian") then return end
	if self:getCardsNum("BasicCard") + self:getCardsNum("Nullification") == self.player:getHandcardNum() and self.player:getHandcardNum() <= self.player:getHp() then return end
	local handcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(handcards)
	if handcards[1]:isKindOf("Peach") then return end
	return sgs.Card_Parse("#s2_xubian:.:")
end

sgs.ai_skill_use_func["#s2_xubian"] = function(card, use, self)
	local card

	local to_use = {}
	if self.player:isKongcheng() then return end

	local handcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(handcards)

	for _, c in ipairs(handcards) do
		if #to_use < 3 then
			if self:getOverflow() > 0 then
				if not c:isKindOf("Peach") then
					table.insert(to_use, c:getEffectiveId())
				end
			else
				if c:isKindOf("Jink") then
					table.insert(to_use, c:getEffectiveId())
				end
			end
		end
	end
	if #to_use > 0 then
		use.card = sgs.Card_Parse("#s2_xubian:" .. table.concat(to_use, "+") .. ":")
		return
	end
end


local s2_qingfa_skill = {}
s2_qingfa_skill.name = "s2_qingfa"
table.insert(sgs.ai_skills, s2_qingfa_skill)
s2_qingfa_skill.getTurnUseCard = function(self)
	if self.player:getPile("s2_zu"):isEmpty()
		or (self.player:getHandcardNum() >= self.player:getHp() + 2
			and self.player:getPile("s2_zu"):length() <= self.room:getAlivePlayers():length() / 2 - 1) then
		return
	end
	local first_found, second_found = false, false
	local first_card, second_card
	if self.player:getPile("s2_zu"):length() >= 2 then
		local cards = {}
		local same_suit = false

		if self.player:getPile("s2_zu"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("s2_zu")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end

		self:sortByKeepValue(cards)
		for _, fcard in ipairs(cards) do
			first_card = fcard
			first_found = true
			for _, scard in ipairs(cards) do
				if first_card ~= scard then
					local card_str = ("snatch:s2_qingfa[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(),
						scard:getId())
					local snatch = sgs.Card_Parse(card_str)

					assert(snatch)

					local dummy_use = self:aiUseCard(snatch, dummy())
					if dummy_use.card then
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
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local snatch_str = ("snatch:s2_qingfa[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local jixisnatch = sgs.Card_Parse(snatch_str)

		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if (self.player:distanceTo(player, 1) <= 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_DistanceLimit, self.player, jixisnatch))
				and not self.room:isProhibited(self.player, player, jixisnatch) and self:hasTrickEffective(jixisnatch, player) then
				local first_id = first_card:getId()
				local second_id = second_card:getId()
				local card_str = ("snatch:s2_qingfa[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
				local snatch = sgs.Card_Parse(card_str)
				assert(snatch)
				return snatch
			end
		end
	end
end


sgs.ai_view_as.s2_xubian = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceSpecial and player:getPileName(card_id) == "s2_zu" then
		return ("jink:s2_qingfa[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_skill_playerchosen.s2_guijin = function(self, targets)
    targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		return target
	end
	return nil
end

sgs.ai_use_revises.s2_guijin = function(self,card,use)
	if card:isKindOf("Slash") and self.player:hasSkill("s2_z_baye") and self.player:getPhase() == sgs.Player_Play
	and (#self.enemies>1 or #self.friends>1)
	then 
		local x = 0 
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if p:getKingdom() == "jin" then
				x = x + 1 
			end
		end
		if x < (self.room:getAlivePlayers():length()/2) then
		return false end
		end
end

sgs.ai_skill_use["@@s2_qiangrang"] = function(self, prompt)
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local effect = self.room:getTag("CurrentUseStruct"):toCardEffect()
	local card = effect.card
	local needed = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if (self.player:getHandcardNum() > 0) then
		for _, acard in ipairs(cards) do
			if #needed < 1 and not acard:isKindOf("Peach") then
				table.insert(needed, acard:getEffectiveId())
			end
		end
	end
	if #needed > 0 and card then
		local target
		if card:isKindOf("GodSalvation") then
			local lord = self.room:getLord()
			if self:isWeak(lord) and self.player:getRole() == "loyalist" and self:hasTrickEffective(card, effect.from, lord) and table.contains(targets, lord) then
				return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. lord:objectName()
			end
			self:sort(self.friends, "hp")
			if self:isWeak() and self:hasTrickEffective(card, effect.from, self.player) then
				return "."
			else
				for _, p in sgs.qlist(self.friends) do
					if self:hasTrickEffective(card, effect.from, p) and p:getHp() < getBestHp(p) and table.contains(targets, p) then
						return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. p:objectName()
					end
				end
			end
		elseif card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("EXCard_WWJZ") then
			local nature = sgs.DamageStruct_Normal
			if card:isKindOf("FireAttack") then
				nature = sgs.DamageStruct_Fire
			end
			self:sort(self.enemies, "hp")
			self:sort(self.friends, "hp")
			for _, enemy in ipairs(self.enemies) do
				if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nature) and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
			for _, friend in ipairs(self.friends) do
				if ((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, effect.from, false)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, effect.from, friend) or not self:damageIsEffective(friend, nature) and table.contains(targets, friend) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. friend:objectName()
				end
			end
		elseif card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
			local nature = sgs.DamageStruct_Normal
			if card:isKindOf("FireAttack") then
				nature = sgs.DamageStruct_Fire
			end
			self:sort(self.enemies, "hp")
			self:sort(self.friends, "hp")
			for _, enemy in ipairs(self.enemies) do
				if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nature) and not enemy:hasArmorEffect("vine") and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, effect.from, enemy) and not self:cantbeHurt(enemy) and not enemy:hasArmorEffect("vine") and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
			for _, friend in ipairs(self.friends) do
				if (((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, effect.from, false)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, effect.from, friend) or not self:damageIsEffective(friend, nature) or friend:hasArmorEffect("vine")) and table.contains(targets, friend) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. friend:objectName()
				end
			end
			return targets[1]
		elseif card:isKindOf("Collateral") then
			self:sort(self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getWeapon()) and self:hasTrickEffective(card, effect.from, enemy) and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
		elseif card:isKindOf("Dismantlement") or card:isKindOf("Snatch") then
			if self:isFriend(effect.from) and (self.player:getJudgingArea():length() > 0 or self:hasSkills(sgs.lose_equip_skill, self.player)) and self:hasTrickEffective(card, effect.from, self.player) then
				return nil
			end
			if card:isKindOf("Dismantlement") then
				self:sort(self.enemies, "handcard")
				for _, enemy in ipairs(self.enemies) do
					if self:doDisCard(enemy) and self:hasTrickEffective(card, effect.from, enemy) and table.contains(targets, enemy) then
						return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if self:hasTrickEffective(card, effect.from, enemy) and table.contains(targets, enemy) then
						return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
					end
				end
			end
		elseif card:isKindOf("GodFlower") or card:isKindOf("Snatch") then
			self:sort(self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if self:isEnemy(effect.from) and self:hasTrickEffective(card, effect.from, enemy) and (enemy:getJudgingArea():length() < 1 or not self:hasSkills(sgs.lose_equip_skill, enemy)) and table.contains(targets, enemy) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
		elseif card:isKindOf("IronChain") then
			for _, friend in ipairs(self.friends) do
				if self:hasTrickEffective(card, effect.from, friend) and friend:isChained() and table.contains(targets, friend) then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. friend:objectName()
				end
			end

			for _, enemy in ipairs(self.enemies) do
				if self:hasTrickEffective(card, effect.from, enemy) and table.contains(targets, enemy) and not enemy:isChained() then
					return "#s2_qiangrang:" .. table.concat(needed, "+") .. ":->" .. enemy:objectName()
				end
			end
		end
	end
	return "."
end


sgs.ai_ajustdamage_from.s2_mieshi = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and card:hasFlag("s2_mieshi")
    then
        return from:getMark("s2_mieshi")
    end
end

sgs.ai_skill_use["@@s2_mieshi"] = function(self, prompt)
	local suit = self.player:property("s2_mieshi"):toString()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	for _, p in sgs.qlist(use.to) do
		if p and self:isFriend(p) then
			return "."
		end
	end
	local needed = {}
	if (self.player:getHandcardNum() > 0) then
		for _, acard in ipairs(cards) do
			if #needed < 1 and not acard:isKindOf("Peach") and acard:getSuitString() ~= suit then
				table.insert(needed, acard:getEffectiveId())
			end
		end
	end
	if #needed > 0 then
		return "#s2_mieshi:" .. table.concat(needed, "+") .. ":"
	end
	return "."
end


sgs.ai_skill_use["@@s2_zhonghun"] = function(self, prompt)
	self:sort(self.friends, "hp")
	local targets = {}
	local lord = self.room:getLord()
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sort(self.friends, "defense")
	if lord and self:isFriend(lord) and not sgs.isLordHealthy() and not self.player:isLord()  then
		table.insert(targets, lord)
	else
		for _, friend in ipairs(self.friends_noself) do
			if self:isWeak(friend) then
				table.insert(targets, friend)
				break
			end
		end
		for _, friend in ipairs(self.friends_noself) do
			if not table.contains(targets, friend) then
				table.insert(targets, friend)
				break
			end
		end
	end
	local needed = {}
	if (self.player:getHandcardNum() > 0) then
		for _, acard in ipairs(cards) do
			if #needed < 1 and not acard:isKindOf("Peach") then
				table.insert(needed, acard:getEffectiveId())
			end
		end
	end
	if #targets > 0 and #needed > 0 then
		return "#s2_zhonghun:" .. table.concat(needed, "+") .. ":->" .. targets[1]:objectName()
	end
	return "."
end


sgs.ai_skill_invoke.s2_zhonghun = function(self, data)
	local use = data:toCardUse()
	if use.card and use.card:hasFlag("NosJiefanUsed") then return false  end
	if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
	or use.card:isKindOf("NatureSlash") and  self.player:isChained() and self:isGoodChainTarget( self.player,use.card,use.from)
	or self:needToLoseHp( self.player,use.from,use.card) and self:ajustDamage(use.from, self.player,1,use.card)==1 then return false end
	if self:needToLoseHp(self.player, use.from, use.card, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end

	return true
end


sgs.ai_skill_invoke.s2_guantian = true


sgs.ai_skill_discard.s2_duanjia = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local stealer
	for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if ap:hasSkills("tuxi|nostuxi") and self:isEnemy(ap) then stealer = ap end
	end
	local card
	for i = 1, #cards, 1 do
		local isPeach = cards[i]:isKindOf("Peach")
		if isPeach then
			if stealer and self:isEnemy(stealer) and self.player:getHandcardNum() <= 2 and self.player:getHp() > 2
				and (not stealer:containsTrick("supply_shortage") or stealer:containsTrick("YanxiaoCard")) then
				card = cards[i]
				break
			end
			local to_discard_peach = true
			for _, fd in ipairs(self.friends) do
				if fd:getHp() <= 2 and not fd:hasSkill("niepan") then
					to_discard_peach = false
				end
			end
			if to_discard_peach then
				card = cards[i]
				break
			end
		else
			card = cards[i]
			break
		end
	end
	if card == nil then return {} end
	table.insert(to_discard, card:getEffectiveId())
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		if not current:containsTrick("YanxiaoCard") then
			if (current:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
				or (current:containsTrick("lightning") and #self.friends > #self.enemies) then
				return to_discard
			elseif current:containsTrick("supply_shortage") then
				if self.player:getHp() > self.player:getHandcardNum() then return to_discard end
			elseif current:containsTrick("indulgence") then
				if self.player:getHandcardNum() > 3 or self.player:getHandcardNum() > self.player:getHp() - 1 then return
					to_discard end
				for _, friend in ipairs(self.friends_noself) do
					if not friend:containsTrick("YanxiaoCard") and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
						return to_discard
					end
				end
			end
		end
	end
	return {}
end


local s2_tiantan_skill = {}
s2_tiantan_skill.name = "s2_tiantan"
table.insert(sgs.ai_skills, s2_tiantan_skill)
s2_tiantan_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#s2_tiantan") then return end
	if #self.enemies < 1 then return end
	return sgs.Card_Parse("#s2_tiantan:.:")
end

sgs.ai_skill_use_func["#s2_tiantan"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	self:sortByKeepValue(cards)
	local first_found, second_found = false, false
	local first_card, second_card
	local acard
	for _, fcard in ipairs(cards) do
		local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
		if not fvalueCard then
			first_card = fcard
			first_found = true
			for _, scard in ipairs(cards) do
				local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
				if first_card ~= scard and scard:getNumber() == first_card:getNumber()
					and not svalueCard then
					second_card = scard
					second_found = true
					table.insert(to_discard, fcard:getEffectiveId())
					table.insert(to_discard, scard:getEffectiveId())
					break
				end
			end
			if second_card then break end
		end
	end

	if #to_discard == 2 and first_found and second_found then
		self:sort(self.enemies)
		local target
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
				if self.player:distanceTo(enemy) == 1 then
					target = enemy
					break
				end
			end
		end
		if target then
			local card_str = string.format("#s2_tiantan:%s:", table.concat(to_discard, "+"))
			use.card = sgs.Card_Parse(card_str)
			if use.to then use.to:append(target) end
			return
		end
	end
end

sgs.ai_use_value["#s2_tiantan"] = 2.5
sgs.ai_card_intention["#s2_tiantan"] = 80
sgs.dynamic_value.damage_card["#s2_tiantan"] = true




s2_yinyang_skill = {}
s2_yinyang_skill.name = "s2_yinyang"
table.insert(sgs.ai_skills, s2_yinyang_skill)
s2_yinyang_skill.getTurnUseCard = function(self)
	if self.player:getMark("@s2_yinyang") <= 0 then return end
	if self.player:getPile("s2_fu"):length() == 0 or (self.player:getPile("s2_fu"):length() > 5 and not self:isWeak()) then return end
	if self.room:getMode() == "_mini_13" then return sgs.Card_Parse("#s2_yinyang:.:") end
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) and self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			if self:isFriend(player) then
				bad = bad + 1
			else
				good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(player:getHp(), 1)
		if self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			if getCardsNum("Analeptic", player) > 0 then
				if self:isFriend(player) then
					good = good + 1.0 / hp
				else
					bad = bad + 1.0 / hp
				end
			end


			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill, player) then lost_value = player:getHp() / 2 end
			local hp = math.max(player:getHp(), 1)
			if self:isFriend(player) then
				bad = bad + (lost_value + 1) / hp
			else
				good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad then return sgs.Card_Parse("#s2_yinyang:.:") end
end

sgs.ai_skill_use_func["#s2_yinyang"] = function(card, use, self)
	use.card = card
end



sgs.ai_skill_use["@@s2_danmu"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local targets = {}
	local card = sgs.Sanguosha:getCard(self.player:getMark("card_id"))
	local use_card = {}
	if card then
		for _, enemy in ipairs(self.enemies) do
			if #targets < self.player:getPile("s2_fu"):length() and not enemy:hasFlag("s2_danmu") and card:targetFilter(sgs.PlayerList(), enemy, self.player) and not self.player:isProhibited(enemy, card) and self:slashIsEffective(card, enemy) then
				table.insert(targets, enemy:objectName())
			end
		end
	end
	if #targets > 0 then
		for _, id in sgs.qlist(self.player:getPile("s2_fu")) do
			if #use_card < #targets then
				table.insert(use_card, id)
			end
		end
		if #targets == #use_card then
			return "#s2_danmu:" .. table.concat(use_card, "+") .. ":->" .. table.concat(targets, "+")
		end
	end
	return "."
end

sgs.ai_skill_playerchosen["s2_saiqian"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _, p in ipairs(targets) do
		if not p:isNude() then
			if self:isEnemy(p) and not (p:hasArmorEffect("silver_lion") and p:isWounded()) then
				if p:getEquips():length() > 0 then
					if not p:hasSkills(sgs.lose_equip_skill) then
						return p
					end
				else
					return p
				end
			end
		end
	end
	targets = sgs.reverse(targets)
	for _, p in ipairs(targets) do
		if not p:isNude() then
			if self:isFriend(p) and p:getHp() > 2 and p:getHandcardNum() > 2 then
				return p
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["s2_saiqian"] = function(self, from, to)
	if sgs.turncount <= 1 then
		sgs.updateIntention(from, to, 80)
	end
end

sgs.ai_skill_cardask["@s2_saiqian"] = function(self, data, pattern, target, target2)
	local current = self.room:getCurrent()
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(usable_cards)
	local give_card = {}
	if self.player:hasArmorEffect("silver_lion") and self.player:isWounded() then
		for _, c in ipairs(usable_cards) do
			if c:isKindOf("SilverLion") then
				return c:toString()
			end
		end
	end
	if self:isFriend(current) then
		for _, c in ipairs(usable_cards) do
			if c:isKindOf("Slash")
				or c:isKindOf("Duel")
				or c:isKindOf("SavageAssault")
				or c:isKindOf("ArcheryAttack")
				or c:isKindOf("Snatch")
				or c:isKindOf("Dismantlement")
			then
				table.insert(give_card, c)
			end
		end
		if #give_card > 0 then
			return give_card[1]:toString()
		end
	end
	if self.player:hasSkills(sgs.lose_equip_skill) and self.player:getEquips():length() > 0 then
		local equipments = sgs.QList2Table(self.player:getCards("e"))
		self:sortByKeepValue(equipments)
		for _, e in ipairs(equipments) do
			return e:toString()
		end
	end
	for _, c in ipairs(usable_cards) do
		return c:toString()
	end
end

sgs.ai_ajustdamage_to.s2_hufu = function(self,from,to,slash,nature)
	if nature ~= "N"
	then return -99 end
end



local s2_2_zhanjiang_skill = {}
s2_2_zhanjiang_skill.name = "s2_2_zhanjiang"
table.insert(sgs.ai_skills, s2_2_zhanjiang_skill)
s2_2_zhanjiang_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#s2_2_zhanjiang") or self.player:isKongcheng() then return end
	return sgs.Card_Parse("#s2_2_zhanjiang:.:")
end

sgs.ai_skill_use_func["#s2_2_zhanjiang"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")

	if slashcount > 0 then
		local slash = self:getCard("Slash")
		--assert(slash)
		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card then 
			for _, enemy in ipairs(self.enemies) do
				if self:canAttack(enemy, self.player)
					and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player) then
					use.card = sgs.Card_Parse("#s2_2_zhanjiang:.:")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_cardneed.s2_2_zhanjiang = function(to, card, self)
	return card:isKindOf("Slash")
end



sgs.ai_use_value["s2_2_zhanjiang"] = 9.2
sgs.ai_use_priority["s2_2_zhanjiang"] = 9.2


sgs.ai_skill_invoke.s2_2_huzi = function(self, data)
	local use = data:toCardUse()
	if self:hasWizard(self.enemies,true) and not self:hasWizard(self.friends,true) then
		return false
	end
	for _, to in sgs.qlist(use.to) do
		if self:isEnemy(to) and (not self:damageIsEffective(to, use.card, self.player) or self:cantDamageMore(self.player, to)) then
			return false
		end
	end
	if math.random() < 0.4 then
		return false
	end
	return true
end
sgs.ai_ajustdamage_from.s2_2_huzi = function(self, from, to, card, nature)
    if card and (card:isKindOf("Slash") or card:isKindOf("Duel"))
    then
        return from:getMark("s2_2_huzi")
    end
end
sgs.ai_use_revises.s3_weihezhe = function(self,card,use)
	if card:isKindOf("EquipCard")
	then
		local same = self:getSameEquip(card)
		if same and #self:poisonCards({card})<1
		then return false end
	end
end

sgs.ai_ajustdamage_from.s3_weihezhe = function(self, from, to, card, nature)
    if from:getMark("@s3_weihezhe") + 1 == from:getHp() or (card and card:hasFlag("s3_weihezhe"))
    then
        return 1
    end
end
sgs.ai_skill_invoke.s3_shenqiangshou = function(self,data)
	local use = data:toCardUse()
	local good = 0
	for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
		if self:isEnemy(p) and not self:slashProhibit(use.card, p) and self:getDefenseSlash(p) <= 2
		and self:slashIsEffective(use.card, p) and self:isGoodTarget(p, self.enemies, use.card)then
			good = good + 1
			if self:isWeak(p) then
				good = good + 2
			end
			
		end
		if self:isFriend(p) and not self:slashProhibit(use.card, p) and self:getDefenseSlash(p) <= 2
		and self:slashIsEffective(use.card, p) and self:isGoodTarget(p, self.enemies, use.card) then
			good = good - 1
			if self:isWeak(p) then
				good = good - 2
			end
		end
	end
	return good>0
end

sgs.ai_skill_choice.s3_shenqiangshou = function(self, choices, data)
    local items = choices:split("+")
	return items[math.random(1, #items)]
end

sgs.ai_skill_discard.s3_zhuhai = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", 1, 1, false, true)
end

sgs.ai_skill_choice.s3_zhuhai = function(self, choices)
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	local items = choices:split("+")
	if table.contains(items, "s3_zhuhai_discard") then
		if not use.from or use.from:isDead() then return "cancel" end
		if self.role == "rebel" and sgs.ai_role[use.from:objectName()] == "rebel" and not use.from:hasSkill("jueqing")
			and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
			return "cancel"
		end

		if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord() and self.player:getHp() == 1) then
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
						if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then return
							"s3_zhuhai_discard" end
						if sj_num == 0 and friend_null <= 0 then
							if self:isEnemy(from) and from:hasSkill("jueqing") then return "s3_zhuhai_discard" end
							if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not from:hasSkill("jueqing") then return
								"s3_zhuhai_discard" end
							if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or use.from:hasSkill("jueqing")) then
								return "s3_zhuhai_discard"
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
								return "s3_zhuhai_discard"
							elseif self.player:isChained() and not self:isGoodChainTarget(self.player, use.from) then
								return "s3_zhuhai_discard"
							end
						end
					end
				elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))
					and not self.player:isKongcheng() then
					if self:hasTrickEffective(use.card, self.player) then
						return "s3_zhuhai_discard"
					end
				elseif use.card:isKindOf("Duel") then
					if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player) then
						if self:hasTrickEffective(use.card, self.player) then
							if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then
								return "s3_zhuhai_discard"
							end
						end
					end
				end
			end
		end
	end

	if use.from and self:isEnemy(use.from) then
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		if self:slashIsEffective(slash, use.from) and not self:slashProhibit(slash, use.from) and self:isGoodTarget(use.from, self.enemies, slash) then
			return "s3_zhuhai_slash"
		end
	end



	return "cancel"
end


s3_jianyan_skill = {}
s3_jianyan_skill.name = "s3_jianyan"
table.insert(sgs.ai_skills, s3_jianyan_skill)
s3_jianyan_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	if not self.player:hasUsed("#s3_jianyan") then return sgs.Card_Parse("#s3_jianyan:.:") end
end

sgs.ai_skill_use_func["#s3_jianyan"] = function(card, use, self)
	local abandon_card = {}
	local index = 0
	local hasPeach = (self:getCardsNum("Peach") > 0)
	local to
	local AssistTarget = self:AssistTarget()
	if AssistTarget and self:willSkipPlayPhase(AssistTarget) and AssistTarget:getHandcardNum() >= self.player:getHandcardNum() - 1 then AssistTarget = nil end


	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)

	index = 0
	for _, card in ipairs(cards) do
		if index >= 1 then break end
		if card:isKindOf("TrickCard") and not card:isKindOf("Nullification") then
			table.insert(abandon_card, card:getId())
			index = index + 1
		elseif card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			table.insert(abandon_card, card:getId())
			index = index + 1
		end
	end
	self:sort(self.friends_noself, "handcard")
	local x = 0
	local y = self.player:getHandcardNum() - 1
	if AssistTarget and not hasManjuanEffect(AssistTarget) and AssistTarget:getHandcardNum() < self.player:getHandcardNum() - 1 then
		to = AssistTarget
	else
		for _, p in ipairs(self.friends_noself) do
			if y - p:getHandcardNum() > x and p:getHandcardNum() < y then
				to = p
				x = p:getHandcardNum() - y
			end
		end
	end

	if index == 1 then
		if not to then return end
		if use.to then use.to:append(to) end
		use.card = sgs.Card_Parse("#s3_jianyan:" .. table.concat(abandon_card, "+") .. ":")
		return
	end
end

sgs.ai_use_priority["#s3_jianyan"] = 0
sgs.ai_use_value["#s3_jianyan"] = 6.7

sgs.ai_card_intention["#s3_jianyan"] = -100



sgs.ai_skill_choice.s3_binglu = function(self, choices)
	local items = choices:split("+")
	local x
	if self.player:getHandcardNum() > self.player:getHp() then
		x = self.player:getHandcardNum() - self.player:getHp()
	else
		x = self.player:getHp() - self.player:getHp()
	end
	if x >= 2 and not self:isWeak() then
		return "s3_binglu_draw"
	end
	if self:isWeak() and not (x >= 2) and table.contains(items, "s3_binglu_discard") then
		return "s3_binglu_discard"
	end
	return "cancel"
end

sgs.ai_skill_discard.s3_binglu = function(self, discard_num, min_num, optional, include_equip)
	local x
	if self.player:getHandcardNum() > self.player:getHp() then
		x = self.player:getHandcardNum() - self.player:getHp()
	else
		x = self.player:getHp() - self.player:getHp()
	end
	return self:askForDiscard("dummyreason", x, x, false, false)
end

sgs.ai_skill_invoke.s3_zhijue = function(self, data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end

sgs.ai_can_damagehp.s3_zhijue = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from)
	end
end



sgs.ai_skill_invoke.s3_lianzhan = function(self, data)
	local target = data:toPlayer()
	if target then
		local card = self.room:getTag("CurrentDamageStruct"):toDamage().card
		local dummy_use = self:aiUseCard(card, dummy(true, 0, self.room:getOtherPlayers(target)))
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
			return true
		end
	else
		return true
	end
	return false
end
sgs.ai_cardneed.s3_lianzhan = sgs.ai_cardneed.slash



sgs.ai_skill_invoke.s3_qiangyuan = function(self, data)
	return true
end

sgs.ai_skill_use["@@s3_qiangyuan"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.friends, "defense")
	local targets = {}
	for _, player in ipairs(sgs.QList2Table(self.room:getAllPlayers())) do
		if self:isFriend(player) and not hasManjuanEffect(player) and not self:needKongcheng(player, true)
			and not (player:hasSkill("kongcheng") and player:isKongcheng()) and #targets < 2 then
			table.insert(targets, player:objectName())
		end
	end
	if #targets > 0 then
		return "#s3_qiangyuan:.:->" .. table.concat(targets, "+")
	end
	return "."
end
sgs.ai_cardneed.s3_tianwei = sgs.ai_cardneed.slash



local s3_youlong_skill = {}
s3_youlong_skill.name = "s3_youlong"
table.insert(sgs.ai_skills, s3_youlong_skill)
s3_youlong_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end

	local jink_card

	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("fire_slash:s3_youlong[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash
end

sgs.ai_view_as.s3_youlong = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if card:isKindOf("Jink") then
			return ("slash:s3_youlong[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:s3_youlong[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end


sgs.ai_skill_invoke.s3_youlong = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if hasManjuanEffect(self.player) then return false end
		if self:needKongcheng(target) and target:getHandcardNum() == 1 then return true end
		if self:getOverflow(target) > 2 then return true end
		return false
	else
		return not (self:needKongcheng(target) and target:getHandcardNum() == 1)
	end
end

sgs.ai_choicemade_filter.skillInvoke.s3_youlong = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasFlag("s3_youlongTarget") then
			target = p
			break
		end
	end
	if target then
		local intention = 60
		if promptlist[#promptlist] == "yes" then
			if not self:hasLoseHandcardEffective(target) or (self:needKongcheng(target) and target:getHandcardNum() == 1) then
				intention = 0
			end
			if self:getOverflow(target) > 2 then intention = 0 end
			sgs.updateIntention(player, target, intention)
		else
			if self:needKongcheng(target) and target:getHandcardNum() == 1 then intention = 0 end
			sgs.updateIntention(player, target, -intention)
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.s3_youlong = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_slash_prohibit.s3_youlong = function(self, from, to, card)
	if self:isFriend(to, from) then return false end
	if from:hasSkill("tieji") or self:canLiegong(to, from) then
		return false
	end
	if self:SlashCanIgnoreJink(from, to) then return false end
	if to:hasSkill("s3_youlong") and to:getHandcardNum() >= 3 and from:getHandcardNum() > 1 then return true end
	return false
end



sgs.ai_skill_discard.s3_youlong = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", 1, 1, false, true)
end

sgs.ai_card_priority.s3_youlong = function(self,card)
	if card:getSkillName()=="s3_youlong"
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end


sgs.ai_skill_playerchosen["s3_kangdao"] = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		for _, enemy in ipairs(self.enemies) do
			if friend:canSlash(enemy) and not self:slashProhibit(nil, enemy) and self:getDefenseSlash(enemy) <= 2 and self:isGoodTarget(enemy, self.enemies, nil) 
				and enemy:objectName() ~= self.player:objectName() and getCardsNum("Slash", friend, self.player) >= 1 then
				return friend
			end
		end
	end
	return nil
end

sgs.ai_skill_playerchosen["s3_kangdao_target"] = function(self, targets)
	local target = self.room:getTag("s3_kangdao"):toPlayer()
	for _, enemy in ipairs(self.enemies) do
		if target:canSlash(enemy) and not self:slashProhibit(nil, enemy) and self:getDefenseSlash(enemy) <= 2 and 
			self:isGoodTarget(enemy, self.enemies, nil)  and enemy:objectName() ~= self.player:objectName() then
			return enemy
		end
	end
	return nil
end



sgs.ai_skill_use["@@s3_qiane"] = function(self, prompt, method)
	self:updatePlayers()
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(usable_cards)
	local give_card = {}
	if self:willSkipPlayPhase() then
		for _, c in ipairs(usable_cards) do
			if not c:isKindOf("Peach") and (#give_card < self:getOverflow()) then
				table.insert(give_card, c:getEffectiveId())
			end
		end
		if #give_card > 0 then
			return "#s3_qiane:" .. table.concat(give_card, "+") .. ":"
		end
	end
	if self:getTurnUse() then
		for _, c in ipairs(usable_cards) do
			if not table.contains(self.toUse,c) then
				table.insert(give_card, c:getEffectiveId())
			end
		end
	end
	if #give_card > 0 then
		return "#s3_qiane:" .. table.concat(give_card, "+") .. ":"
	end
	return "."
end



local s3_fenzhi_skill = {}
s3_fenzhi_skill.name = "s3_fenzhi"
table.insert(sgs.ai_skills, s3_fenzhi_skill)
s3_fenzhi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#s3_fenzhi") then return end
	if #self.enemies < 1 then return end
	if self.player:getHandcardNum() < 1 then return end
	return sgs.Card_Parse("#s3_fenzhi:.:")
end

sgs.ai_skill_use_func["#s3_fenzhi"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local to_discard = {}
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if #to_discard < 2 and not card:isKindOf("Peach") then
			table.insert(to_discard, card:getEffectiveId())
		end
	end
	if #to_discard == 2 then
		self:sort(self.enemies)
		local target
		for _, friend in ipairs(self.friends_noself) do
			if friend:hasSkills(sgs.cardneed_skill) and not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
				target = friend
				break
			end
		end
		if target == nil then
			for _, friend in ipairs(self.friends_noself) do
				if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) then
					target = friend
					break
				end
			end
		end
		if target then
			local card_str = string.format("#s3_fenzhi:%s:", table.concat(to_discard, "+"))
			use.card = sgs.Card_Parse(card_str)
			if use.to then use.to:append(target) end
			return
		end
	end
end


sgs.ai_skill_choice.s3_fenzhi = function(self, choices)
	local items = choices:split("+")
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("s3_fenzhi") then
			if self:isFriend(p) then
				return "s3_fenzhidraw"
			else
				if table.contains(items, "s3_fenzhiget") then
					return "s3_fenzhiget"
				end
			end
		end
	end
	return "s3_fenzhidraw"
end


sgs.ai_choicemade_filter.skillChoice["s3_fenzhi"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("s3_fenzhi") then
			if choice == "s3_fenzhidraw" then
				sgs.updateIntention(player, p, -80)
			else
				sgs.updateIntention(player, p, 80)
			end
		end
	end
end


local s3_fudao_skill = {}
s3_fudao_skill.name = "s3_fudao"
table.insert(sgs.ai_skills, s3_fudao_skill)
s3_fudao_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return nil end
	if self.player:hasUsed("#s3_fudao") then return nil end
	return sgs.Card_Parse("#s3_fudao:.:")
end

sgs.ai_skill_use_func["#s3_fudao"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	if #cards == 1 and cards[1]:getSuit() == sgs.Card_Diamond then return end
	if #cards <= 4 and (self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then return end
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local suits = {}
	local suits_num = 0
	for _, c in ipairs(cards) do
		if not suits[c:getSuitString()] then
			suits[c:getSuitString()] = true
			suits_num = suits_num + 1
		end
	end


	for _, enemy in ipairs(self.enemies) do
		local visible = 0
		for _, card in ipairs(cards) do
			local flag = string.format("%s_%s_%s", "visible", enemy:objectName(), self.player:objectName())
			if card:hasFlag("visible") or card:hasFlag(flag) then visible = visible + 1 end
		end
		if visible > 0 and (#cards <= 2 or suits_num <= 2) then continue end
		if self:canAttack(enemy) then
			use.card = sgs.Card_Parse("#s3_fudao:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_card_intention["s3_fudao"] = 70
sgs.ai_use_priority["s3_fudao"] = sgs.ai_use_priority.Peach

function sgs.ai_skill_suit.s3_fudao(self)
	local map = { 0, 0, 1, 2, 2, 3, 3, 3 }
	local suit = map[math.random(1, 8)]
	local tg = self.room:getCurrent()
	local suits = {}
	local maxnum, maxsuit = 0
	for _, c in sgs.qlist(tg:getHandcards()) do
		local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), tg:objectName())
		if c:hasFlag(flag) or c:hasFlag("visible") then
			if not suits[c:getSuitString()] then suits[c:getSuitString()] = 1 else suits[c:getSuitString()] = suits
				[c:getSuitString()] + 1 end
			if suits[c:getSuitString()] > maxnum then
				maxnum = suits[c:getSuitString()]
				maxsuit = c:getSuit()
			end
		end
	end
	if self.player:hasSkill("hongyan") and (maxsuit == sgs.Card_Spade or suit == sgs.Card_Spade) then
		return sgs.Card_Heart
	end
	if maxsuit then
		if self.player:hasSkill("hongyan") and maxsuit == sgs.Card_Spade then return sgs.Card_Heart end
		return maxsuit
	else
		if self.player:hasSkill("hongyan") and suit == sgs.Card_Spade then return sgs.Card_Heart end
		return suit
	end
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|s3_guizhou"


sgs.ai_skill_playerchosen.s3_guizhou = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if player:isLord() then lord = player end
		if self:isEnemy(player) and (not target or target:getHp() < player:getHp()) then
			target = player
		end
	end
	if self.role == "rebel" and lord then return lord end
	if target then return target end
	self:sort(targetlist, "hp")
	if self.player:getRole() == "loyalist" and targetlist[1]:isLord() then return targetlist[2] end
	return targetlist[1]
end

sgs.ai_cardneed.s3_luofeng = sgs.ai_cardneed.slash
sgs.ai_can_damagehp.s3_sizhan = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) then
		return self:isEnemy(from) and self:isWeak(from) and sgs.ai_skill_cardask["@s3_sizhan"](self, ToData(from), "" , from) ~= "."
	end
end


sgs.ai_skill_cardask["@s3_sizhan"] = function(self, data, pattern, target)
	local target = data:toPlayer()
	if self:isFriend(target, self.player) then return "." end

	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	if target and self:isEnemy(target) and self:slashIsEffective(slash, target) and not self:slashProhibit(slash, target) and self:isGoodTarget(target, self.enemies, slash)  then
		if self:needToThrowArmor() then
			return "$" .. self.player:getArmor():getEffectiveId()
		end
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not card:isKindOf("Peach") then
				return "$" .. card:getEffectiveId()
			end
		end
		if self.player:canDiscard(self.player, "he") then
			return "$" .. cards[1]:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_need_damaged.s3_zhonglie = function(self, attacker, player)
	if player:hasSkill("s3_zhonglie") and player:getMark("s3_zhonglie") == 0 and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() > 3 or player:getHp() == 3 and (player:faceUp() or player:hasSkill("guixin") or player:hasSkill("toudu") and not player:isKongcheng())) then
		return true
	end
	return false
end

sgs.ai_skill_discard["s3_wumou"] = function(self, discard_num, min_num, optional, include_equip)
	return self:askForDiscard("dummyreason", 1, 1, false, false)
end
sgs.ai_use_revises.s3_wumou = function(self,card,use)
	if card:isNDTrick() and self.player:getHandcardNum() <= 3
	then
        if not (card:isKindOf("AOE") or card:isKindOf("IronChain") or card:isKindOf("Drowning"))
        and not (card:isKindOf("Duel") and self.player:getMark("&wrath")>0)
		then return false end
	end
end

sgs.ai_skill_invoke.s3_xiaoyong = function(self, data)
	local target = data:toPlayer()
	return self:doDisCard(target)
end

sgs.ai_choicemade_filter.cardChosen.s3_xiaoyong = sgs.ai_choicemade_filter.cardChosen.snatch



sgs.ai_cardneed.s3_xiongyi = sgs.ai_cardneed.slash


sgs.ai_skill_cardask["s3_xiongyi-invoke"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("s3_xiongyi_ing") then
			target = p
			break
		end
	end
	for _, q in sgs.qlist(self.room:getOtherPlayers(target)) do
		if target:inMyAttackRange(q) and not use.to:contains(q) then
			if q and self:isEnemy(q) and self:slashIsEffective(use.card, q) and not self:slashProhibit(use.card, q) and self:isGoodTarget(q, self.enemies, use.card) then
				if self:needToThrowArmor() then
					return "$" .. self.player:getArmor():getEffectiveId()
				end
				local cards = sgs.QList2Table(self.player:getCards("he"))
				self:sortByKeepValue(cards)
				for _, card in ipairs(cards) do
					if not card:isKindOf("Peach") then
						return "$" .. card:getEffectiveId()
					end
				end
				return "$" .. cards[1]:getEffectiveId()
			end
		end
	end
	return "."
end


sgs.ai_skill_playerchosen.s3_xiongyi = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end




local s3_xiandao_skill = {}
s3_xiandao_skill.name = "s3_xiandao"
table.insert(sgs.ai_skills, s3_xiandao_skill)
s3_xiandao_skill.getTurnUseCard = function(self)
	if self.player:canDiscard(self.player, "he") then
		return sgs.Card_Parse("#s3_xiandao:.:")
	end
end

sgs.ai_skill_use_func["#s3_xiandao"] = function(card, use, self)
	local weapon = self.player:getWeapon()
	if weapon then
		local hand_weapon, cards
		cards = self.player:getHandcards()
		for _, card in sgs.qlist(cards) do
			if card:isKindOf("Weapon") then
				hand_weapon = card
				break
			end
		end
		self:sort(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and hand_weapon and not self:hasSkills(sgs.lose_equip_skill, enemy) then
				use.card = sgs.Card_Parse("#s3_xiandao:" .. hand_weapon:getId() .. ":")
				if use.to then
					use.to:append(enemy)
				end
				break
			end
		end
	end
end

sgs.ai_use_value["#s3_xiandao"] = 2.5
sgs.ai_card_intention["#s3_xiandao"] = 80
sgs.dynamic_value.damage_card["#s3_xiandao"] = true
sgs.ai_cardneed.s3_xiandao = sgs.ai_cardneed.weapon

sgs.s3_xiandao_keep_value = {
	Weapon = 5
}

sgs.ai_skill_invoke.s3_yt_fulin = function(self, data)
	local use = data:toCardUse()
	local card = use.card
	local target = use.to:first()
	if self:isEnemy(target) then
		if ((card:isKindOf("TrickCard") and self:hasTrickEffective(card, target, self.player)) or (card:isKindOf("Slash") and self:slashIsEffective(card, target, self.player))) then
			return true
		end
	end
	if self:isFriend(target) then
		return true
	end
	return not self:isEnemy(target)
end


sgs.ai_skill_choice.s3_yt_fulin = function(self, choices)
	local items = choices:split("+")
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("s3_yt_fulin") then
			if self:isFriend(p) then
				return "s3_yt_fulin_draw"
			else
				if table.contains(items, "s3_yt_fulin_use") then
					return "s3_yt_fulin_use"
				end
			end
		end
	end
	return "s3_yt_fulin_draw"
end


sgs.ai_choicemade_filter.skillChoice["s3_yt_fulin"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("s3_yt_fulin") then
			if choice == "s3_yt_fulin_draw" then
				sgs.updateIntention(player, p, -80)
			else
				sgs.updateIntention(player, p, 80)
			end
		end
	end
end



local s3_yt_baier_skill = {}
s3_yt_baier_skill.name = "s3_yt_baier"
table.insert(sgs.ai_skills, s3_yt_baier_skill)
s3_yt_baier_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end

	local jink_card

	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if not card:isKindOf("Peach") then
			jink_card = card
			break
		end
	end
	if math.ceil(self.player:getHp() / 2) * 2 == self.player:getHp() then return nil end
	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:s3_yt_baier[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash
end

sgs.ai_view_as.s3_yt_baier = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if math.ceil(player:getHp() / 2) * 2 == player:getHp() then
			return ("slash:s3_yt_baier[%s:%s]=%d"):format(suit, number, card_id)
		elseif math.ceil(player:getHp() / 2) * 2 ~= player:getHp() then
			return ("jink:s3_yt_baier[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.s3_yt_baier_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.7,
	Slash = 5.6,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}


sgs.ai_skill_invoke.s3_yt_kuangjun = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) and target:getHandcardNum() < 4 then
		return false
	end
	if self:isEnemy(target) and target:getHandcardNum() >= 4 then
		return false
	end
	return true
end
sgs.ai_skill_cardask["@s3_yt_kuangjun"] = function(self, data, pattern, target)
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

sgs.ai_skill_invoke.s3_yt_huzheng = function(self, data)
	local target = data:toPlayer()
	for _, enemy in ipairs(self.enemies) do
		if target:canSlash(enemy) and not self:slashProhibit(nil, enemy) and self:getDefenseSlash(enemy) <= 2 and self:isGoodTarget(enemy, self.enemies, nil) 
			and enemy:objectName() ~= self.player:objectName() then
			return self:isFriend(target)
		end
	end
	return false
end



sgs.ai_skill_playerchosen.s3_yt_huzheng = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end


sgs.ai_skill_invoke.s3_yt_huangyi = function(self, data)
	local target = self.room:getCurrent()
	if self:isFriend(target) then
		return not self.player:faceUp()
	end
	if self:isEnemy(target) then
		return not (self.player:faceUp()) or (self:isWeak(target))
	end
	return false
end
sgs.ai_skill_choice["s3_yt_huangyi_type"] = function(self, choices, data)
	self:updatePlayers()
	self:sort(self.friends_noself, "handcard")
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		return "TrickCard"
	end
	if current and self:isEnemy(current) then
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		if self:slashIsEffective(slash, current) and self:isGoodTarget(current, self.enemies, slash)  then
			self.room:setTag("ai_s3_yt_huangyi_card_name", sgs.QVariant(slash:objectName()))
			return "Slash"
		else
			return "TrickCard"
		end
	end

	return "cancel"
end


sgs.ai_skill_choice["s3_yt_huangyi"] = function(self, choices, data)
	self:updatePlayers()
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		return "TrickCard"
	end
	if current and self:isEnemy(current) then
		local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		if self:hasTrickEffective(duel, current, self.player) then
			self.room:setTag("ai_s3_yt_huangyi_card_name", sgs.QVariant(duel:objectName()))
			return "duel"
		end
	end
	if current and self:isFriend(current) then
		local duel = sgs.Sanguosha:cloneCard("god_salvation", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		self.room:setTag("ai_s3_yt_huangyi_card_name", sgs.QVariant(duel:objectName()))
		return "god_salvation"
	end

	return "cancel"
end


sgs.ai_skill_use["@@s3_yt_huangyi"] = function(self, prompt, method)
	local ai_taoluan_card_name = self.room:getTag("ai_s3_yt_huangyi_card_name"):toString()
	self.room:removeTag("ai_s3_yt_huangyi_card_name")

	local use_card = sgs.Sanguosha:cloneCard(ai_taoluan_card_name, sgs.Card_NoSuit, -1)
	use_card:setSkillName("s3_yt_huangyi")

	local current = self.room:getCurrent()
	local dummy_use = self:aiUseCard(use_card, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			if p:objectName() == current:objectName() then
				return use_card:toString() .. "->" .. current:objectName()
			end
		end
	end
	return "."
end




sgs.ai_skill_playerchosen.s3_yt_zhinan = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_skill_discard["s3_yt_fuding"] = function(self, discard_num, min_num, optional, include_equip)
	local x = 0
	local y = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:inMyAttackRange(p) then
			if self:isEnemy(p) then
				y = y + 1
			end
			x = x + 1
		end
	end
	if (x >= self.player:getHandcardNum() - 2) or (y > 2) then
		return self:askForDiscard("dummyreason", 1, 1, false, false)
	end
end
sgs.ai_skill_cardask["s3_yt_fuding_push"] = function(self, data, pattern, target)
	if target and not self:isFriend(target) then return "." end
	if target and self:isFriend(target) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				return "$" .. card:getEffectiveId()
			end
		end
		self:sortByKeepValue(cards)
	end
	return "."
end



sgs.ai_skill_invoke.s3_yt_feijun = function(self, data)
	if self.player:getHp() <= 2 then
		return true
	else
		local handcards = self.player:getHandcards()
		local basic = {}
		local trick = {}
		local equip = {}
		for _, c in sgs.qlist(handcards) do
			if c:isKindOf("BasicCard") and not c:isKindOf("Peach") then
				if self.player:canDiscard(self.player, c:getEffectiveId()) then
					table.insert(basic, c)
				end
			end
			if c:isKindOf("TrickCard") then
				if self.player:canDiscard(self.player, c:getEffectiveId()) then
					table.insert(trick, c)
				end
			end
			if c:isKindOf("EquipCard") then
				if self.player:canDiscard(self.player, c:getEffectiveId()) then
					table.insert(equip, c)
				end
			end
		end
		if #basic == 1 or #trick == 1 or equip == 1 then
			for _, enemy in ipairs(self.enemies) do
				local def = self:getDefenseSlash(enemy)
				local slash = sgs.Sanguosha:cloneCard("slash")
				slash:deleteLater()
				local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) 

				if not self.player:canSlash(enemy, slash) then
				elseif self:slashProhibit(nil, enemy) then
				elseif def < 6 and eff then
					return true
				end
			end
		end
	end
	return false
end

sgs.ai_skill_choice["s3_yt_feijun"] = function(self, choices, data)
	local handcards = self.player:getHandcards()
	local basic = {}
	local trick = {}
	local equip = {}
	for _, c in sgs.qlist(handcards) do
		if c:isKindOf("BasicCard") and not c:isKindOf("Peach") then
			if self.player:canDiscard(self.player, c:getEffectiveId()) then
				table.insert(basic, c)
			end
		end
		if c:isKindOf("TrickCard") then
			if self.player:canDiscard(self.player, c:getEffectiveId()) then
				table.insert(trick, c)
			end
		end
		if c:isKindOf("EquipCard") then
			if self.player:canDiscard(self.player, c:getEffectiveId()) then
				table.insert(equip, c)
			end
		end
	end
	if #basic == 1 then
		return "BasicCard"
	elseif #trick <= 2 then
		return "TrickCard"
	elseif #equip <= 2 then
		return "EquipCard"
	end
end

sgs.ai_skill_playerchosen.s3_yt_feijun = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end
sgs.ai_cardneed.s3_yt_zhengtao = sgs.ai_cardneed.slash
sgs.ai_card_priority.s3_yt_zhengtao = function(self,card,v)
	local x = math.max(1, self.player:getLostHp())
	if self.player:getMark("s3_yt_kangrui") > 0 then
		x = 1 
	end
	if self.player:getMark("s3_yt_zhengtao")+1==x and card:isKindOf("Slash")
	then return 10 end
end

sgs.ai_skill_playerchosen.s3_yt_zhengtao = function(self, targets)
	return self.player
end


sgs.ai_skill_invoke.s3_yt_mangyong = function(self, data)
	local card = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
	card:deleteLater()
	if self:getAoeValue(card) > 0 then
		return true
	end
	return false
end

local s3_yt_tongnan_skill = {}
s3_yt_tongnan_skill.name = "s3_yt_tongnan"
table.insert(sgs.ai_skills, s3_yt_tongnan_skill)
s3_yt_tongnan_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#s3_yt_tongnan") then return nil end
	return sgs.Card_Parse("#s3_yt_tongnan:.:")
end

sgs.ai_skill_use_func["#s3_yt_tongnan"] = function(card, use, self)
	use.card = card

	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() > 0 then
			if not self:hasSkills(sgs.lose_equip_skill, enemy) then
				for _, ecard in sgs.qlist(enemy:getCards("e")) do
					if ecard:isKindOf("Armor") or ecard:isKindOf("DefensiveHorse") or ecard:isKindOf("Weapon") then
						if use.to then
							use.to:append(enemy)
						end
						return
					end
				end
			end
		end
	end
	if use.to then
		use.to:append(self.player)
	end
	return
end
sgs.ai_use_priority["s3_yt_tongnan"] = sgs.ai_use_priority.Peach

sgs.ai_skill_playerchosen["s3_yt_junlie"] = function(self, targets)
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	if use.card then
		if use.card:isKindOf("Slash") then
			if self:slashIsEffective(use.card, self.player, use.from) then
				local handcards = self.player:getHandcards()
				for _, c in sgs.qlist(handcards) do
					if c:isKindOf("Jink") then
						return nil
					end
				end
				if self.player:getHandcardNum() < self.player:getHp() then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:isKongcheng() then
							return enemy
						end
					end
				end
			end
		elseif use.card:isKindOf("FireAttack") or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Collateral") or use.card:isKindOf("Snatch") or use.card:isKindOf("AmazingGrace") then
			if self.player:getHandcardNum() < self.player:getHp() then
				for _, enemy in ipairs(self.enemies) do
					if not enemy:isKongcheng() then
						return enemy
					end
				end
			end
		elseif use.card:isKindOf("Duel") or use.card:isKindOf("SavageAssault") then
			if self:slashIsEffective(use.card, self.player, use.from) then
				local handcards = self.player:getHandcards()
				for _, c in sgs.qlist(handcards) do
					if c:isKindOf("Slash") then
						return nil
					end
				end
				if self.player:getHandcardNum() < self.player:getHp() then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:isKongcheng() then
							return enemy
						end
					end
				end
			end
		elseif use.card:isKindOf("ArcheryAttack") then
			if self:slashIsEffective(use.card, self.player, use.from) then
				local handcards = self.player:getHandcards()
				for _, c in sgs.qlist(handcards) do
					if c:isKindOf("Jink") then
						return nil
					end
				end
				if self.player:getHandcardNum() < self.player:getHp() then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:isKongcheng() then
							return enemy
						end
					end
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_invoke.s3_yt_gangyong = function(self, data)
	local damage = data:toDamage()
	if damage.from and self:isEnemy(damage.from) then
		return true
	end
	return false
end



local s3_yt_qibing_skill = {}
s3_yt_qibing_skill.name = "s3_yt_qibing"
table.insert(sgs.ai_skills, s3_yt_qibing_skill)
s3_yt_qibing_skill.getTurnUseCard = function(self)
	if self.player:getMark("@s3_yt_qibing") > 0 then
		return sgs.Card_Parse("#s3_yt_qibing:.:")
	end
end

sgs.ai_skill_use_func["#s3_yt_qibing"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
			if self.player:getHp() > enemy:getHp() then
				use.card = sgs.Card_Parse("#s3_yt_qibing:.:")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
end

sgs.ai_use_value["#s3_yt_qibing"] = 2.5
sgs.ai_card_intention["#s3_yt_qibing"] = 80
sgs.dynamic_value.damage_card["#s3_yt_qibing"] = true



sgs.ai_skill_discard["s3_yt_panjiang"] = function(self, discard_num, min_num, optional, include_equip)
	local target = self.room:getCurrent()
	if target:objectName() == self.player:objectName() then
		return self:askForDiscard("dummyreason", 1, 1, false, false)
	end
	if self:isFriend(target) and not self:isWeak() then
		return self:askForDiscard("dummyreason", 1, 1, false, false)
	end

	return {}
end

sgs.ai_skill_use["@@s3_yt_ruiqiDiscard"] = function(self, prompt, method)
	local data = self.room:getTag("s3_yt_ruiqi")
	if not data then return "." end
	local effect = data:toCardEffect()
	if not effect then return "." end
	local can_invoke = false
	if effect.card:isKindOf("TrickCard") then
		if effect.card:isDamageCard() then
			if self:needToLoseHp(self.player,effect.from,effect.card)
			or self:canDamageHp(effect.from,effect.card,self.player) then
			else
				local adn = self:ajustDamage(effect.from,self.player,1,effect.card)
				if adn<-1 or adn>1 or adn>=self.player:getHp() then 
					can_invoke = true
				end
			end
		end
	elseif effect.card:isKindOf("Slash") then
		if sgs.ai_skill_cardask["slash-jink"](self,data,"jink",data:toCardEffect().from) or self.player:getMark("ai_NoJinkCard"..effect.card:getEffectiveId().."_targeted-Clear") > 0 then
			can_invoke = true
		end
	end
	if not can_invoke then return "." end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local trick = {}
	local nontrick = {}
	local discard = {}
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") then
			table.insert(trick, card)
		elseif card:isKindOf("BasicCard") then
			table.insert(nontrick, card)
		end
	end
	if #cards <= 2 then return "." end
	if #trick == 0 then
		for _, card in ipairs(nontrick) do
			table.insert(discard, card:getEffectiveId())
			if #discard == 2 or #discard == #nontrick then
				break
			end
		end
	end
	if #nontrick == 0 and #trick >= 1 then
		table.insert(discard, trick[1]:getEffectiveId())
	end
	if #discard > 0 then
		return "#s3_yt_ruiqiDummyCard:".. table.concat(discard, "+") ..":"
	end
	return "."
end


sgs.ai_skill_invoke.s3_yt_ruiqi = function(self, data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(use.to) do
		if p and self:isEnemy(p) then
			return true
		end
	end
	return false
end





sgs.ai_skill_cardask["@s3_yt_congzheng"] = function(self, data, pattern, target)
	local target = self.room:getCurrent()
	if self:needBear() then return "." end
	if target and self:isEnemy(target) and self:objectiveLevel(target) > 3 and not self:cantbeHurt(target) and self:damageIsEffective(target) and not self:willSkipPlayPhase(target) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		if self:needToThrowArmor() and not self.player:isCardLimited(self.player:getArmor(), sgs.Card_MethodDiscard) then
			return "$" .. self.player:getArmor():getEffectiveId()
		end


		for _, card in ipairs(cards) do
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@s3_yt_congzheng"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		--local current = self.player:getTag("sidi_target"):toPlayer()
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, 80)
	end
end


sgs.ai_card_priority.s3_yt_yinpan = function(self,card)
	if self.player:getPile("&s3_yinpan"):contains(card:getEffectiveId())
	then
		if self.useValue
		then return 2 end
		return 0.08
	end
end




sgs.ai_choicemade_filter.cardChosen.s3_yt_qujin_caoxiu = sgs.ai_choicemade_filter.cardChosen.dismantlement
sgs.ai_skill_cardchosen["s3_yt_qujin"] = function(self, who, flags)
	local cards = sgs.QList2Table(who:getHandcards())
	self:sortByUseValue(cards, false)
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then
			return card
		end
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") and card:isBlack() then
			return card
		end
	end

	return cards[1]
end

sgs.ai_skill_choice.s3_yt_qujin = function(self, choices, data)
	local target = data:toPlayer()
	local x = target:getPile("qujin"):length()
	if self:isFriend(target) then
		if target:getCardCount(true) < x and x <= 2 then
			return "s3_yt_qujin_discard"
		end
	else
		if not self:isWeak(target) and target:getCardCount(true) > x and x > 2 then
			return "s3_yt_qujin_discard"
		end
	end
	return "s3_yt_qujin_damage"
end



local s3_yt_qujin_skill = {}
s3_yt_qujin_skill.name = "s3_yt_qujin"
table.insert(sgs.ai_skills, s3_yt_qujin_skill)

s3_yt_qujin_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("s3_yt_qujin_dis") then return nil end
	return sgs.Card_Parse("#s3_yt_qujin:.:")
end

sgs.ai_skill_use_func["#s3_yt_qujin"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	local target
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he") then
			target = enemy
			break
		end
	end
	if target and not target:isNude() then
		use.card = sgs.Card_Parse("#s3_yt_qujin:.:")
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_use_value["s3_yt_qujin"] = sgs.ai_use_value.Slash + 0.1
sgs.ai_use_priority["s3_yt_qujin"] = sgs.ai_use_priority.Slash + 0.1









sgs.ai_skill_invoke.s3_yt_gangjian = function(self, data)
	if self:willSkipPlayPhase() then return false end
	if self.player:isKongcheng() then return true end
	if self:isWeak() and self:getCardsNum("Jink") + self:getCardsNum("Analeptic") + self:getCardsNum("Peach") + self:getCardsNum("Nullification") == 0 then
		return true
	end
	if self.player:getHp() == 2 then return true end
	if self:getTurnUse() then
		for i,c in sgs.list(self.toUse)do
			if c:isKindOf("Duel") then return true end
			if c:isKindOf("FireAttack") then return true end
			if c:isKindOf("AOE") then return true end
		end
	end
	
	return false
end
sgs.ai_card_priority.s3_yt_youxue = function(self,card,v)
	if card:isBlack() and card:getNumber() <= self.player:getMark("s3_yt_youxueNumber-".. self.player:getPhase() .."Clear")
	then return 10 end
end

sgs.ai_skill_invoke.s3_yt_gaojiong = function(self, data)
	local good = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:distanceTo(p) == 1 and self:damageIsEffective(p, nil, self.player) then
			if self:isFriend(p) then
				good = good - 1
			else
				good = good + 1
			end
		end
	end
	if good > 0 then
		if self.player:getHp() <= 0 or not self.player:faceUp() then
			return true
		end
		return not self:isWeak()
	end
	return false
end

sgs.ai_skill_discard.s3_touying = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if (self.player:getPile("s3_jian"):length() >= self.room:getAlivePlayers():length() - 1) or self:needBear() then
		return {}
	end
	table.insert(to_discard, cards[1]:getEffectiveId())

	return to_discard
end

sgs.ai_skill_use["@@s3_huanxiangbenghuai"] = function(self, prompt)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return "." end
	if target:hasArmorEffect("silver_lion") then return "." end

	local discard_cards = {}
	if self.player:getPile("s3_jian"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("s3_jian")) do
			table.insert(discard_cards, sgs.Sanguosha:getCard(id))
		end
		return "#s3_huanxiangbenghuai:" .. discard_cards[1]:getEffectiveId() .. ":"
	end
	return "."
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|s3_wuxianjianzhi"


sgs.ai_ajustdamage_from.s3_huanxiangbenghuai = function(self, from, to, card, nature)
    if not from:getPile("s3_jian"):isEmpty() and not beFriend(to, from)
    then
        return 1
    end
end
sgs.ai_ajustdamage_from.s3_fans_caomin = function(self, from, to, card, nature)
    return -99
end

sgs.ai_skill_invoke.s3_fans_jiegan = function(self, data)
	return (#self.enemies > 0)
end
sgs.ai_need_damaged.s3_fans_jiegan = function (self,attacker,player)
	if not player:hasSkill("s3_fans_jiegan") then return end
	if player:getMark("@s3_fans_jiegan") == 0 then return end

	return player:getHp()>=2
end
sgs.ai_skill_cardask["@s3_fans_pianji"] = function(self, data, pattern, target)
	local isdummy = type(data) == "number"
	local function getJink(effect)
		if (self:getCardsNum("TrickCard") > 0 or (self:getCardsNum("Slash") > 1-self.player:getMark("s3_fans_pianjiCard"..effect.card:getEffectiveId().."-Clear"))) then
		return self:getCardId("TrickCard") or self:getCardId("Slash") or not isdummy and "."
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
	if not target then return getJink(effect) end
	if not self:hasHeavyDamage(target, slash, self.player) and self:needToLoseHp(self.player, target, slash) then return "." end
	
	if self:ajustDamage(target, nil, 1, slash) <= 0 then return "." end

	if slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, target, nil, nil, slash) then return "." end
	if self:isFriend(target) then
		if self:findLeijiTarget(self.player, 50, target) then return getJink(effect) end
		if target:hasSkill("jieyin") and not self.player:isWounded() and self.player:isMale() and not self.player:hasSkills("leiji|nosleiji|olleiji|jieleiji") then return "." end
		if not target:hasSkill("jueqing") then
			if (target:hasSkill("nosrende") or (target:hasSkill("rende") and not target:hasUsed("RendeCard"))) and self.player:hasSkill("jieming") then return "." end
			if target:hasSkill("pojun") and not self.player:faceUp() then return "." end
			--add dmpkancolle
			if target:hasSkill("BurningLove") and slash:isKindOf("FireSlash") then return "." end
		end
	else
		if self:hasHeavyDamage(target, slash, self.player) then return getJink(effect) end

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
		if self.player:getHandcardNum() == 1 and self:needKongcheng() then return getJink(effect) end
		if not self:hasLoseHandcardEffective() and not self.player:isKongcheng() then return getJink(effect) end
		if target:hasSkill("mengjin") and not (target:hasSkill("nosqianxi") and target:distanceTo(self.player) == 1) then
			if self.player:getCards("he"):length() == 1 and not self.player:getArmor() then return getJink(effect) end
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
					return getJink(effect)
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
	return getJink(effect)
end
sgs.hit_skill = sgs.hit_skill .. "|s3_fans_pianji"
sgs.ai_cardneed.s3_fans_pianji = sgs.ai_cardneed.slash


sgs.ai_skill_invoke.s3_fans_jiongyan = function(self, data)
	local effect = data:toCardEffect()
	return self:doDisCard(effect.to)
end

sgs.ai_skill_choice.s3_fans_guzhi = function(self, choice)
	if self.player:getHp() < self.player:getMaxHp() - 1 then return "s3_fans_guzhirecover" end
	return "s3_fans_guzhidraw"
end

sgs.ai_skill_use["@@s3_fans_handou"] = function(self, prompt)
	if self.player:isKongcheng() then return "." end
	self:sort(self.enemies, "handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()

	local duel = sgs.Sanguosha:cloneCard("duel")
	duel:deleteLater()
	local dummy_use = self:aiUseCard(duel, dummy())

	if dummy_use.card then
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point > enemy_max_point then
					self.s3_fans_handou_card = max_card:getEffectiveId()
					return "#s3_fans_handou:.:->" .. enemy:objectName()
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1) and not enemy:isKongcheng() and self.player:canPindian(enemy) then
				if max_point >= 10 then
					self.s3_fans_handou_card = max_card:getEffectiveId()
					return "#s3_fans_handou:.:->" .. enemy:objectName()
				end
			end
		end
		if #self.enemies < 1 then return end
	end
	return "."
end




sgs.ai_skill_playerchosen.s3_fans_shanlan = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, target in ipairs(targets) do
		if self:isFriend(target) and (target:getMark("@s3_fans_shanlan") == 0) then
			return target
		end
	end
	return nil
end


sgs.ai_skill_invoke.s3_fans_shanlan = function(self, data)
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
	if current and self:isFriend(current) and self.player:isChained() and self:isGoodChainTarget(self.player, current) then return false end --內奸跳反會有問題，非屬性殺也有問題。但狀況特殊，八卦陣原碼資訊不足，暫時這樣寫。
	--	slash = sgs.Sanguosha:cloneCard("fire_slash")
	--	if slash and slash:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(self.player, self.room:getCurrent(), nil, nil, slash) then return false end

	if self:hasSkills("tiandu|leiji|nosleiji|olleiji|gushou") then
		if self.player:hasFlag("dahe") and not heart_jink then return true end
		if sgs.hujiasource and not self:isFriend(sgs.hujiasource) and (sgs.hujiasource:hasFlag("dahe") or self.player:hasFlag("dahe")) then return true end
		if sgs.lianlisource and not self:isFriend(sgs.lianlisource) and (sgs.lianlisource:hasFlag("dahe") or self.player:hasFlag("dahe")) then return true end
		if self.player:hasFlag("dahe") and handang and self:isFriend(handang) and dying > 0 then return true end
	end
	if self.player:getHandcardNum() == 1 and self:getCardsNum("Jink") == 1 and self.player:hasSkills("zhiji|beifa") and self:needKongcheng() then
		local enemy_num = self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player)
		if self.player:getHp() > enemy_num and enemy_num <= 1 then return false end
	end
	if handang and self:isFriend(handang) and dying > 0 then return false end
	if self.player:hasFlag("dahe") then return false end
	if sgs.hujiasource and (not self:isFriend(sgs.hujiasource) or sgs.hujiasource:hasFlag("dahe")) then return false end
	if sgs.lianlisource and (not self:isFriend(sgs.lianlisource) or sgs.lianlisource:hasFlag("dahe")) then return false end
	if self:needToLoseHp(self.player, nil, true, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end

	return true
end



sgs.ai_playerchosen_intention.s3_fans_shanlan = -50


sgs.ai_skill_playerchosen.s3_fans_yanfeng = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and (target:getMark("@s3_fans_yanfeng") == 0) then
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.s3_fans_yanfeng = 50

sgs.ai_skill_discard.s3_fans_yanfeng = function(self, discard_num, min_num, optional, include_equip)
	local cards = self.player:getCards("he")
	local to_discard = {}
	cards = sgs.QList2Table(cards)
	if self:needBear() then
		return {}
	end
	if self:needToThrowArmor() and self.player:getArmor():isBlack() then
		table.insert(to_discard, self.player:getArmor():getId())
		return to_discard
	end
	for _, card in ipairs(cards) do
		if not self.player:isJilei(card) and card:isBlack() then
			table.insert(to_discard, card:getId())
			return to_discard
		end
	end
	return to_discard
end

sgs.ai_skill_choice["s3_fans_luoshi"] = function(self, choices, data)
	local items = choices:split("+")

	if (self.player:containsTrick("indulgence") or self.player:containsTrick("supply_shortage")) then
		if self.player:getHandcardNum() < self.player:getHp() - 2 then
			if table.contains(items, "s3_fans_luoshi_jp") then return "s3_fans_luoshi_jp" end
		else
			if table.contains(items, "s3_fans_luoshi_jd") then return "s3_fans_luoshi_jd" end
		end
	end
	if not self:isWeak() then
		if table.contains(items, "s3_fans_luoshi_lose") then return "s3_fans_luoshi_lose" end
	end
	return "cancel"
end

local function getjibianValue(self, who, card, from)
	if not self:hasTrickEffective(card, who, from) then return 0 end
	if card:isKindOf("AOE") then
		if not self:isFriend(who) then return 0 end
		local value = self:getAoeValueTo(card, who, from)
		if value < 0 then return -value / 30 end
	elseif card:isKindOf("GodSalvation") then
		if not self:isEnemy(who) or not who:isWounded() or who:getHp() >= getBestHp(who) then return 0 end
		if self:isWeak(who) then return 1.2 end
		if who:hasSkills(sgs.masochism_skill) then return 1.0 end
		return 0.9
	elseif card:isKindOf("AmazingGrace") then
		if not self:isEnemy(who) or hasManjuanEffect(who) then return 0 end
		local v = 1.2
		local p = self.room:getCurrent()
		while p:objectName() ~= who:objectName() do
			v = v * 0.9
			p = p:getNextAlive()
		end
		return v
	end
	return 0
end

sgs.ai_skill_use["@@s3_fans_jibian1"] = function(self, prompt)
	local liuxie = self.room:findPlayerBySkillName("huangen")
	if liuxie and self:isFriend(liuxie) and not self:isWeak(liuxie) then return "." end

	local card = self.room:getTag("s3_fans_jibian"):toCardUse().card
	local from = self.room:getTag("s3_fans_jibian"):toCardUse().from

	local players = sgs.QList2Table(self.room:getAllPlayers())
	self:sort(players, "defense")
	local target_table = {}
	local targetslist = self.player:property("s3_fans_jibian_target"):toString():split("+")
	local value = 0
	for _, player in ipairs(players) do
		if not (player:hasSkill("danlao") or (player:hasSkills("jianxiong|nosjianxiong") and not self:isWeak(player)))
			and table.contains(targetslist, player:objectName()) and #target_table < self.player:getHp() then
			local val = getjibianValue(self, player, card, from)
			if val > 0 then
				value = value + val
				table.insert(target_table, player:objectName())
			end
		end
	end
	if #target_table == 0 or value / (self.room:alivePlayerCount() - 1) < 0.55 then return "." end
	local cards = {}
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("he"))) do
		table.insert(cards, c:getEffectiveId())
		if #cards == #target_table then
			break
		end
	end
	if #cards == #target_table then
		return "#s3_fans_jibian:" .. table.concat(cards, "+") .. ":->" .. table.concat(target_table, "+")
	end
	return "."
end


sgs.ai_skill_playerchosen.s3_fans_jibian = function(self, targets)
	if self:needKongcheng(self.player, true) then
		return nil
	end
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and (not target:hasSkills(sgs.lose_equip_skill) or self:doDisCard(target)) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and ((target:hasSkills(sgs.lose_equip_skill) and target:getEquips():length() > 0) or self:needToThrowArmor(target)) then return
			target end
	end

	return targets[1]
end

local function card_for_jibian(self, who, return_prompt)
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (enemy:hasSkill("hongyan") or judge:isKindOf("Lightning")) then
							target = enemy
							break
						end
					end
					if target then break end
				end
			end
		end

		local equips = who:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then
					card = equip
					break
				elseif equip:isKindOf("Weapon") then
					card = equip
					break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	else
		local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					card = sgs.Sanguosha:getCard(judge:getEffectiveId())
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge)
							and not friend:getJudgingArea():isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge) then
							target = friend
							break
						end
					end
					if target then break end
				end
			end
		end
		if card == nil or target == nil then
			if not who:hasEquip() or self:hasSkills(sgs.lose_equip_skill, who) then return nil end
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and self:hasSkills(sgs.lose_equip_skill .. "|shensu", friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	end

	if return_prompt == "card" then
		return card
	elseif return_prompt == "target" then
		return target
	else
		return (card and target)
	end
end

sgs.ai_skill_use["@@s3_fans_jibian2"] = function(self, prompt)
	local who = self.room:getTag("s3_fans_jibian"):toPlayer()
	if not who or not self:isFriend(who) then return "." end
	local target = card_for_jibian(self, who, "target")

	local cards = {}
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("he"))) do
		table.insert(cards, c:getEffectiveId())
		if #cards == self.player:getHp() - 1 then
			break
		end
	end
	if #cards == self.player:getHp() - 1 and self.player:getHp() - 1 < 4 and target then
		return "#s3_fans_jibian:" .. table.concat(cards, "+") .. ":->" .. target:objectName()
	end
	return "."
end


local s3_fans_feiyan_skill = {}
s3_fans_feiyan_skill.name = "s3_fans_feiyan"
table.insert(sgs.ai_skills, s3_fans_feiyan_skill)

s3_fans_feiyan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getCards("he"):length() < 1 then return nil end
	if self.player:hasUsed("#s3_fans_feiyan") then return nil end
	local card
	if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isKindOf("EquipCard") then
				card = hcard
				break
			end
		end
	end
	if card then
		return sgs.Card_Parse("#s3_fans_feiyan:.:")
	end
end

sgs.ai_skill_use_func["#s3_fans_feiyan"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	local target = nil
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) 
			and enemy:objectName() ~= self.player:objectName() then
			target = enemy
			break
		end
	end
	local card
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isKindOf("EquipCard") then
				card = hcard
				break
			end
		end
	end
	if card then
		if target then
			use.card = sgs.Card_Parse("#s3_fans_feiyan:" .. card:getId() .. ":")
			if use.to then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_use_value["#s3_fans_feiyan"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["#s3_fans_feiyan"] = sgs.ai_use_priority.Slash - 0.2




function sgs.ai_cardneed.s3_fans_feiyan(to, card, self)
	return card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", true) == 0
end

sgs.ai_skill_invoke.s3_fans_qingyu = function(self, data)
	local dmg = data:toDamage()
	if self:damageStruct(dmg) and self:needToLoseHp(dmg.to, dmg.from, dmg.card) then
		return false
	end
	return true
end
sgs.ai_ajustdamage_from.s3_fans_caihua = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and card:getSuitString() == "no_suit"
    then
        return 1
    end
end



sgs.ai_skill_invoke.s3_fans_shangji = function(self, data)
	return true
end



sgs.ai_skill_invoke.s3_fans_yunce = function(self, data)
	return true
end


sgs.ai_skill_choice["s3_fans_yunce"] = function(self, choices, data)
	self:updatePlayers()
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		local duel = sgs.Sanguosha:cloneCard("savage_assault", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		if self:hasTrickEffective(duel, target, self.player) then
			return "duel"
		end
	end
	if target and self:isFriend(target) then
		local duel = sgs.Sanguosha:cloneCard("ex_nihilo", sgs.Card_NoSuit, 0)
		duel:deleteLater()
		return "ex_nihilo"
	end

	return "cancel"
end
sgs.ai_ajustdamage_from.s3_fans_wenjiu = function(self, from, to, card, nature)
    if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and from:hasFlag("s3_fans_wenjiu") and from:objectName() ~= to:objectName()
    then
        return 1
    end
end

sgs.ai_cardneed.s3_fans_wenjiu = sgs.ai_cardneed.slash
sgs.ai_cardneed.s3_fans_longxiao = sgs.ai_cardneed.slash

s3_fans_xianjia_skill = {}
s3_fans_xianjia_skill.name = "s3_fans_xianjia"
table.insert(sgs.ai_skills, s3_fans_xianjia_skill)
s3_fans_xianjia_skill.getTurnUseCard = function(self)
	local card
	if self:needToThrowArmor() then
		card = self.player:getArmor()
	end
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isKindOf("EquipCard") then
				card = hcard
				break
			end
		end
	end
	if not card then
		local ecards = self.player:getCards("e")
		ecards = sgs.QList2Table(ecards)

		for _, ecard in ipairs(ecards) do
			if ecard:isKindOf("Weapon") or ecard:isKindOf("OffensiveHorse") then
				card = ecard
				break
			end
		end
	end
	if card then
		card = sgs.Card_Parse("#s3_fans_xianjia:" .. card:getEffectiveId() .. ":")
		return card
	end

	return nil
end

sgs.ai_skill_use_func["#s3_fans_xianjia"] = function(card, use, self)
	local target
	local friends = self.friends_noself

	local canMingceTo = function(player)
		local canGive = not self:needKongcheng(player, true)
		return canGive or (not canGive and self:getEnemyNumBySeat(self.player, player) == 0)
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

sgs.ai_use_value["#s3_fans_xianjia"] = sgs.ai_use_value.RendeCard
sgs.ai_use_priority["#s3_fans_xianjia"] = sgs.ai_use_priority.RendeCard

sgs.ai_card_intention["#s3_fans_xianjia"] = sgs.ai_card_intention.RendeCard

sgs.dynamic_value.benefit["#s3_fans_xianjia"] = true

sgs.ai_skill_invoke.s3_fans_yinbing = function(self, data)
	local target = data:toPlayer()
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	if not self:isFriend(target) or self:isFriend(use.from) then return false end
	if target:hasSkills("liuli|tianxiang|ol_tianxiang") and target:getHandcardNum() > 1 then return false end
	if not self:slashIsEffective(use.card, target, use.from) then return false end
	if target:hasSkills(sgs.masochism_skill) and not self:isWeak(target) then return false end

	if not self:slashIsEffective(use.card, self.player, use.from) then return true end

	if self.player:getHandcardNum() + self.player:getEquips():length() < 2 and not self:isWeak(target) then return false end


	if self:isWeak(target) and not self:isWeak() then return true end
	if self:getCardsNum("Jink") > 0 then return true end

	return false
end

sgs.ai_skill_discard.s3_fans_yinbing = function(self)
	local to_discard = {}
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	if not self:slashIsEffective(use.card, self.player, use.from) then return to_discard end
	if self.player:hasSkills(sgs.masochism_skill) and not self:isWeak(self.player) then
		return to_discard
	end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:isKindOf("EquipCard") then
			table.insert(to_discard, card:getEffectiveId())
			break
		end
	end
	return to_discard
end


sgs.ai_skill_use["@@s3_xianju"] = function(self, prompt)
	local target


	local cards = {}
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if not c:isKindOf("Peach") then
			table.insert(cards, c:getEffectiveId())
			if #cards == 2 then
				break
			end
		end
	end

	local max = 0
	for _, friend in ipairs(self.friends_noself) do
		local temp = 0
		for _, enemy in ipairs(self.enemies) do
			if enemy:inMyAttackRange(friend) then
				temp = temp + 1
			end
		end
		if temp + 6 - friend:getHp() > max then
			max = temp + 6 - friend:getHp()
			target = friend
		end
	end
	if self:needBear() then return "." end
	if #cards == 2 and target and self:isWeak(target) then
		return "#s3_xianju:" .. table.concat(cards, "+") .. ":->" .. target:objectName()
	end
	if target and self:isWeak(target) and not self:isWeak() then
		return "#s3_xianju:.:->" .. target:objectName()
	end
	return "."
end



sgs.ai_skill_playerchosen.s3_jxwj_fange = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

sgs.ai_cardneed.s3_jxwj_fange = sgs.ai_cardneed.slash
sgs.ai_cardneed.s3_jxwj_zhoudao = sgs.ai_cardneed.slash
sgs.ai_skill_playerchosen["s3_jxwj_zhoudao"] = function(self, targets)
	local x = math.max(1, self.player:getLostHp())
	local target = self:findPlayerToDraw(true, x)
	if target then
		return target
	else
		return self.player
	end
end

sgs.ai_playerchosen_intention["s3_jxwj_zhoudao"] = -20

sgs.ai_skill_cardask["@s3_jxwj_duce"] = function(self, data, pattern, target)
	local damage = data:toDamage()
	if (damage.from and self:isEnemy(damage.from) and self:isWeak(damage.from)) or (not damage.to:hasSkills(sgs.masochism_skill) and self.player:getLostHp() > 1) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Spade then
				return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end

sgs.ai_skill_choice.s3_jxwj_duce = function(self, choices)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and self:isEnemy(damage.from) and self:isWeak(damage.from) then
		return "s3_jxwj_duce_lost"
	end
	return "s3_jxwj_duce_from"
end


sgs.ai_choicemade_filter.skillChoice["s3_jxwj_duce"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	if choice == "s3_jxwj_duce_lost" then
		local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
		sgs.updateIntention(player, damage.from, 80)
	end
end



function sgs.ai_cardsview_valuable.s3_jxwj_weiwan(self, class_name, player)
	if class_name == "Peach" and player:faceUp() then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then return nil end
		if dying:isKongcheng() then return nil end
		if dying:isLord() and self:isFriend(dying, player) then return "#s3_jxwj_weiwan:.:" end

		if self:playerGetRound(dying) < self:playerGetRound(self.player) and dying:getHp() < 0 then return nil end
		if player:faceUp() then
			if dying:getMark("Global_PreventPeach") == 0 then
				for _, c in sgs.qlist(player:getHandcards()) do
					if not isCard("Peach", c, player) then return nil end
				end
			end
			return "#s3_jxwj_weiwan:.:"
		end
		return nil
	end
end

function sgs.ai_cardsview.s3_jxwj_weiwan(self, class_name, player)
	if class_name == "Peach" and player:faceUp() then
		local dying = player:getRoom():getCurrentDyingPlayer()
		if not dying or self:isEnemy(dying, player) or dying:objectName() == player:objectName() then return nil end
		if dying:isKongcheng() then return nil end
		if dying:isLord() and self:isFriend(dying, player) then return "#s3_jxwj_weiwan:.:" end

		if not self:isWeak(player) then return "#s3_jxwj_weiwan:.:" end
		return nil
	end
end

sgs.ai_card_intention["#s3_jxwj_weiwan"] = sgs.ai_card_intention.Peach


sgs.ai_skill_invoke.s3_jxwj_miaoyan = function(self, data)
	local use = data:toCardUse()
	if not use.from or use.from:isDead() then return false end
	if self.role == "rebel" and sgs.ai_role[use.from:objectName()] == "rebel" and not use.from:hasSkill("jueqing")
		and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
		return false
	end

	if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord() and self.player:getHp() == 1) then
		if use.card:isKindOf("AOE") then
			local from = use.from
			if use.card:isKindOf("SavageAssault") then
				local menghuo = self.room:findPlayerBySkillName("huoshou")
				if menghuo then from = menghuo end
			end


			if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then return true end

			if self:isEnemy(from) and from:hasSkill("jueqing") then return self:doDisCard(from) end
			if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not from:hasSkill("jueqing") then return true end
			if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or use.from:hasSkill("jueqing"))
				and self:doDisCard(use.from) then
				return true
			end
		elseif self:isEnemy(use.from) then
			if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
				return self:doDisCard(use.from)
			elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))
				and self:getCardsNum("Peach") == self.player:getHandcardNum() and not self.player:isKongcheng() then
				return self:doDisCard(use.from)
			elseif use.card:isKindOf("Duel") then
				return self:doDisCard(use.from)
			elseif use.card:isKindOf("TrickCard") then
				if self:doDisCard(use.from) then
					return true
				end
			end
		end
	end
	return false
end



sgs.ai_skill_choice.s3_jxwj_dunwei = function(self, choices)
	local items = choices:split("+")
	if self:getOverflow() > 0 and table.contains(items, "s3_jxwj_dunwei_keji") then
		if self.player:getHandcardNum() > self.player:getMaxHp() then
			return "s3_jxwj_dunwei_keji"
		end
	end
	return "s3_jxwj_dunwei_draw"
end


sgs.ai_skill_cardask["@s3_jxwj_boji"] = function(self, data, pattern, target)
	local damage = data:toDamage()
	if self.player:objectName() == damage.from:objectName() then
		if not self:isEnemy(damage.to) then return "." end
		if damage.to:hasArmorEffect("silver_lion") then return "." end
	end
	if self.player:objectName() == damage.to:objectName() then
		if self:needToLoseHp(self.player, damage.from, damage.card) and damage.damage <= 1 then return "." end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	if self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	for _, card in ipairs(cards) do
		if card:isKindOf("EquipCard") then
			return "$" .. card:getEffectiveId()
		end
	end
	return "."
end


sgs.ai_skill_invoke.s3_jxwj_zhuwei = function(self, data)
	if (self.player:getJudgingArea():length() > 0) or (self.player:isSkipped(sgs.Player_Draw)) then
		return true
	end
	return false
end



sgs.ai_skill_invoke.s3_jxwj_zhuwei_draw = function(self, data)
	return true
end


sgs.ai_skill_use["@@s3_jxwj_zhuwei"] = function(self, prompt)
	local target
	if self.player:getJudgingArea():length() > 0 then
		local cards = {}
		if self.player:containsTrick("indulgence") then
			for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
				if not c:isKindOf("TrickCard") and c:isBlack() then
					table.insert(cards, c:getEffectiveId())
					if #cards == 1 then
						break
					end
				end
			end
		elseif self.player:containsTrick("supply_shortage") then
			for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
				if not c:isKindOf("TrickCard") and c:getSuit() == sgs.Card_Diamond then
					table.insert(cards, c:getEffectiveId())
					if #cards == 1 then
						break
					end
				end
			end
		else
			for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
				if not c:isKindOf("TrickCard") and c:getSuit() ~= sgs.Card_Heart then
					table.insert(cards, c:getEffectiveId())
					if #cards == 1 then
						break
					end
				end
			end
		end




		if #cards == 1 then
			return "#s3_jxwj_zhuwei:" .. table.concat(cards, "+") .. ":"
		end
	end


	return "."
end



sgs.ai_skill_use["@@s3_jxwj_zijun"] = function(self, prompt)
	self:sort(self.friends_noself, "handcard")

	if not self.player:isWounded() then return "." end
	local equips = {}

	local ecards = self.player:getCards("e")
	ecards = sgs.QList2Table(ecards)

	for _, ecard in ipairs(ecards) do
		if ecard:isKindOf("Weapon") or ecard:isKindOf("OffensiveHorse") then
			table.insert(equips, ecard)
		end
	end

	if #equips == 0 then return "." end

	local select_equip, target
	for _, friend in ipairs(self.friends_noself) do
		for _, equip in ipairs(equips) do
			local equip_index = equip:getRealCard():toEquipCard():location()
			if not self:getSameEquip(equip, friend) and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) and friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
		for _, equip in ipairs(equips) do
			local equip_index = equip:getRealCard():toEquipCard():location()
			if not self:getSameEquip(equip, friend) and friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
				target = friend
				select_equip = equip
				break
			end
		end
		if target then break end
	end



	if target and select_equip then
		return "#s3_jxwj_zijun:" .. select_equip:getId() .. ":->" .. target:objectName()
	end
	return "."
end




s3_jxwj_shangdao_skill = {}
s3_jxwj_shangdao_skill.name = "s3_jxwj_shangdao"
table.insert(sgs.ai_skills, s3_jxwj_shangdao_skill)
s3_jxwj_shangdao_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	if self.player:hasUsed("#s3_jxwj_shangdao") then return end
	card = sgs.Card_Parse("#s3_jxwj_shangdao:.:")
	return card
end
local s3_jxwj_shangdao_discard = function(self, discard_num, mycards)
	local cards = mycards
	local to_discard = {}

	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getEffectiveId())
		if self:getUseValue(card) >= 6 then
			return 3                           --使用价值高的牌，如顺手牵羊(9),下调至桃
		elseif self:hasSkills(sgs.lose_equip_skill) then
			return 5
		else
			return 0
		end
		return 0
	end

	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then
			return aux_func(a) < aux_func(b)
		end
		return self:getKeepValue(a) < self:getKeepValue(b)
	end

	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if not self.player:isJilei(card) then table.insert(to_discard, card:getId()) end
		if #to_discard >= discard_num then break end
	end
	if #to_discard ~= discard_num then return {} end
	return to_discard
end

sgs.ai_skill_use_func["#s3_jxwj_shangdao"] = function(card, use, self)
	local mycards = {}

	local keepaslash
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if not self.player:isJilei(c) then
			local shouldUse
			if not keepaslash and isCard("Slash", c, self.player) then
				local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
				self:useBasicCard(c, dummy_use)
				if dummy_use.card and not dummy_use.to:isEmpty() and (dummy_use.to:length() > 1 or dummy_use.to:first():getHp() <= 1) then
					shouldUse = true
				end
			end
			if not shouldUse then table.insert(mycards, c) end
		end
	end

	if #mycards == 0 then return end
	self:sortByKeepValue(mycards) --桃的keepValue是5，useValue是6；顺手牵羊的keepValue是1.9，useValue是9

	self:sort(self.enemies, "handcard")


	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if hasManjuanEffect(enemy) then
			local e_hand = enemy:getHandcardNum()

			local f_peach, f_hand = getCardsNum("Peach", self.player), self.player:getHandcardNum()
			if (e_hand > f_hand - 1) and (e_hand - f_hand) <= #mycards and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
				if e_hand == f_hand then
					local discards = s3_jxwj_shangdao_discard(self, f_hand, mycards)
					if #discards > 0 then use.card = sgs.Card_Parse("#s3_jxwj_shangdao:" ..
						table.concat(discards, "+") .. ":") end
				else
					local discard_num = 3
					local discards = s3_jxwj_shangdao_discard(self, discard_num, mycards)
					if #discards > 0 then use.card = sgs.Card_Parse("#s3_jxwj_shangdao:" ..
						table.concat(discards, "+") .. ":") end
				end
				if use.card and use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		local e_hand = enemy:getHandcardNum()

		local f_peach, f_hand = getCardsNum("Peach", self.player), self.player:getHandcardNum()
		if (e_hand > f_hand - 1) and (e_hand - f_hand) <= #mycards and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
			if e_hand == f_hand then
				local discards = s3_jxwj_shangdao_discard(self, f_hand, mycards)
				if #discards > 0 then use.card = sgs.Card_Parse("#s3_jxwj_shangdao:" .. table.concat(discards, "+") ..
					":") end
			else
				local discard_num = 3
				local discards = s3_jxwj_shangdao_discard(self, discard_num, mycards)
				if #discards > 0 then use.card = sgs.Card_Parse("#s3_jxwj_shangdao:" .. table.concat(discards, "+") ..
					":") end
			end
			if use.card and use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end



sgs.ai_skill_choice.s3_jxwj_xiantu = function(self, choices)
	return "s3_jxwj_xiantu_show"
end



sgs.ai_skill_cardask["@s3_jxwj_qiangji"] = function(self, data, pattern, target)
	local move = data:toMoveOneTime()
	local card = sgs.Sanguosha:getCard(move.card_ids:first())
	if card:isKindOf("ExNihilo") or card:isKindOf("excard_yjjg") or card:isKindOf("Snatch") then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		for _, c in ipairs(cards) do
			if c:getSuit() == card:getSuit() then
				return "$" .. c:getEffectiveId()
			end
		end
	end
	return "."
end

sgs.ai_can_damagehp.s3_jxwj_gangli = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and self:doDisCard(from, "he")
	end
end

sgs.ai_skill_invoke.s3_jxwj_gangli = function(self, data)
	local damage = data:toDamage()
	if damage.from and self:isEnemy(damage.from) then
		local x = damage.from:getHandcardNum() - self.player:getHp()
		if x > self.player:getHp() then
			self.s3_jxwj_ganglichoice = "s3_jxwj_gangli_throwtohp"
		else
			self.s3_jxwj_ganglichoice = "s3_jxwj_gangli_throwhp"
		end
		return self:doDisCard(damage.from)
	end
	return false
end



sgs.ai_skill_choice.s3_jxwj_gangli = function(self, choices)
	return self.s3_jxwj_ganglichoice
end




local s3_jxwj_fuji_skill = {}
s3_jxwj_fuji_skill.name = "s3_jxwj_fuji"
table.insert(sgs.ai_skills, s3_jxwj_fuji_skill)
s3_jxwj_fuji_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getPile("s3_jxwj_fu"):length() == 0 and self.player:getHandcardNum() > 0 then
		return sgs.Card_Parse("#s3_jxwj_fuji:.:")
	end
end

sgs.ai_skill_use_func["#s3_jxwj_fuji"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if cards[1]:isKindOf("Peach") or cards[1]:isKindOf("Nullification") or cards[1]:isKindOf("Analeptic") then return end
	use.card = sgs.Card_Parse("#s3_jxwj_fuji:" .. cards[1]:getEffectiveId() .. ":")
	return
end


sgs.ai_skill_invoke.s3_jxwj_fuji = function(self, data)
	local use = data:toCardUse()
	local card = sgs.Sanguosha:getCard(self.player:getPile("s3_jxwj_fu"):first())
	if card:getSuit() == use.card:getSuit() and card:getNumber() == use.card:getNumber() then
		return true
	end
	if card:getNumber() == use.card:getNumber() then
		return true
	end
	if card:getSuit() == use.card:getSuit() and (use.card:isKindOf("ExNihilo") or use.card:isKindOf("excard_yjjg") or use.card:isKindOf("Snatch")) then
		return true
	end


	return self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player, true) < self.player:getHp()
end



sgs.ai_cardsview_valuable.s3_jxwj_jiujia = function(self, class_name, player)
	if player:getPhase() ~= sgs.Player_NotActive then return end



	if (sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
			or sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
	then
		if class_name == "Jink" then
			return ("#s3_jxwj_jiujia:.:jink")
		end
	end
end


sgs.ai_skill_choice.s3_jxwj_jiujia = function(self, choices)
	local items = choices:split("+")
	if table.contains(items, "s3_jxwj_jiujia_equip") then
		local card
		local target


		local equips = self.player:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, self.player) then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then
					card = equip
					break
				elseif equip:isKindOf("Weapon") then
					card = equip
					break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak() then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak() or self:needToThrowArmor()) then
					card = equip
					break
				end
			end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName() then
						target = friend
						break
					end
				end
				if target then
					return "s3_jxwj_jiujia_equip"
				end
			end
		end
	end
	return "s3_jxwj_jiujia_lostHp"
end


sgs.ai_skill_cardchosen.s3_jxwj_jiujia = function(self, who, flags)
	local card
	local target
	if self:isFriend(who) then
		local equips = who:getCards("e")
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then
					card = equip
					break
				elseif equip:isKindOf("Weapon") then
					card = equip
					break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
				if target then
					return card
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen.s3_jxwj_jiujia = function(self, targets)
	local card
	local equips = self.player:getCards("e")
	local weak
	local target
	if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, self.player) then
		for _, equip in sgs.qlist(equips) do
			if equip:isKindOf("OffensiveHorse") then
				card = equip
				break
			elseif equip:isKindOf("Weapon") then
				card = equip
				break
			elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(self.player) then
				card = equip
				break
			elseif equip:isKindOf("Armor") and (not self:isWeak(self.player) or self:needToThrowArmor(self.player)) then
				card = equip
				break
			end
		end

		if card then
			if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
				self:sort(self.friends, "defense")
			else
				self:sort(self.friends, "handcard")
				self.friends = sgs.reverse(self.friends)
			end

			for _, friend in ipairs(self.friends) do
				if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName()
					and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
					target = friend
					break
				end
			end
			for _, friend in ipairs(self.friends) do
				if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName() then
					target = friend
					break
				end
			end
			if target then
				return target
			end
		end
	end
end



sgs.ai_skill_invoke.s3_jxwj_xianci = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end































function sgs.ai_cardneed.s_lotus_stick(to, card)
	return card:isKindOf("Duel")
end

function sgs.ai_cardneed.s_fire_sword(to, card)
	return card:isKindOf("FireSlash") or card:isKindOf("ThunderSlash")
end

--[[
local s_fire_sword_skill = {}
s_fire_sword_skill.name = "s_fire_sword"
table.insert(sgs.ai_skills, s_fire_sword_skill)

s_fire_sword_skill.getTurnUseCard = function(self, inclusive)
	if not sgs.Slash_IsAvailable(self.player) then return nil end
	if self:isWeak(self.player) then return nil end
if (self:getCardsNum("FireSlash") > 0 or self:getCardsNum("ThunderSlash") > 0)
		and #self.enemies > 0 then
		local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
		self.MingceTarget = nil
		for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
						and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
						and enemy:objectName() ~= self.player:objectName()  and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
					self.MingceTarget = enemy
					break
		end
	end
	if  self.MingceTarget then
		return sgs.Card_Parse("#s_fire_sword:.:")
		end
	end
end

sgs.ai_skill_use_func["#s_fire_sword"] =function(card,use,self)
	self:sort(self.enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_SuitToBeDecided, -1)
	local card
		if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
			if hcard:isKindOf("FireSlash") or hcard:isKindOf("ThunderSlash")  then
				card = hcard
				break
			end
		end
	end
	if card then
	use.card = sgs.Card_Parse("#s_fire_sword:"..card:getId()..":")
		if use.to then
		for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy)
						and self:slashIsEffective(slash, enemy) and sgs.isGoodTarget(enemy, self.enemies, self)
						and enemy:objectName() ~= self.player:objectName() then
			if enemy:isChained()and  self:isGoodChainTarget(enemy) then use.to:append(enemy) end
			if use.to:length() == 3 then break end
			if enemy:hasArmorEffect("vine") then use.to:append(enemy) end
			if use.to:length() == 3 then break end
		end
	end
	end
	end
end

sgs.ai_use_value["s_fire_sword"] = sgs.ai_use_value.Slash
sgs.ai_use_priority["s_fire_sword"] = sgs.ai_use_priority.Slash
]]
function sgs.ai_cardneed.s_biaoqi(to, card)
	return card:isKindOf("Slash")
end

sgs.ai_skill_invoke.s_biaoqi = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isEnemy(damage.to) then
		return true
	end
	return false
end

--[[

sgs.ai_skill_invoke.s2_falisunhui = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end
]]



















--[[


local s2_lierijiushao_skill = {}
s2_lierijiushao_skill.name= "s2_lierijiushao"
table.insert(sgs.ai_skills,s2_lierijiushao_skill)
s2_lierijiushao_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("#s2_lierijiushao") then
		return sgs.Card_Parse("#s2_lierijiushao=.")
	end
end

sgs.ai_skill_use_func["#s2_lierijiushao"] = function(card, use, self)
		self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) then
				if self.player:distanceTo(enemy) <= self.player:getAttackRange() and self.player:getHp() > enemy:getHp() and self.player:getHp() > 1 then
					use.card = sgs.Card_Parse("#s2_lierijiushao=.")
					if use.to then
						use.to:append(enemy)
					end
					return
				end
		end
	end
end


sgs.ai_use_value["s2_lierijiushao"] = 2.5
sgs.ai_card_intention["s2_lierijiushao"] = 80
sgs.dynamic_value.damage_card["s2_lierijiushao"] = true

sgs.s2_lierijiushao_keep_value = {
	Peach = 6,
	Jink = 5.1,
}



]]

















sgs.ai_skill_playerchosen.gzj_leishen = function(self, targets)
	local getCmpValue = function(enemy)
		local value = 0
		if not self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, player) then return 99 end
		if enemy:hasSkill("hongyan") then
			return 99
		end
		if self:cantbeHurt(enemy, player, 3) or self:objectiveLevel(enemy) < 3
			or (enemy:isChained() and not self:isGoodChainTarget(enemy, player, sgs.DamageStruct_Thunder, 3)) then
			return 100
		end
		if not self:isGoodTarget(enemy, self.enemies, nil)  then value = value + 50 end
		if enemy:hasArmorEffect("silver_lion") then value = value + 20 end
		if enemy:hasSkills(sgs.exclusive_skill) then value = value + 10 end
		if enemy:hasSkills(sgs.masochism_skill) then value = value + 5 end
		if enemy:isChained() and self:isGoodChainTarget(enemy, player, sgs.DamageStruct_Thunder, 3) and #(self:getChainedEnemies(player)) > 1 then value =
			value - 25 end
		if enemy:isLord() then value = value - 5 end
		value = value + enemy:getHp() + self:getDefenseSlash(enemy) * 0.01
		return value
	end

	local cmp = function(a, b)
		return getCmpValue(a) < getCmpValue(b)
	end

	local enemies = self:getEnemies(player)
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		if getCmpValue(enemy) < 100 then return enemy end
	end
	return nil
end


sgs.ai_playerchosen_intention.gzj_leishen = sgs.ai_playerchosen_intention.leiji


sgs.ai_slash_prohibit.gzj_leishen = function(self, from, to, card)
	local has_black_card = false
	for _, c in ipairs(sgs.QList2Table(to:getCards("he"))) do
		if c:getSuit() == sgs.Card_Spade then
			has_black_card = true
		end
	end
	local hcard = to:getHandcardNum()
	if self:isFriend(to, from) and has_black_card then return false end
	if to:hasFlag("QianxiTarget") and (not self:hasEightDiagramEffect(to) or self.player:hasWeapon("qinggang_sword")) then return false end


	if from:getRole() == "rebel" and to:isLord() then
		local other_rebel
		for _, player in sgs.qlist(self.room:getOtherPlayers(from)) do
			if sgs.ai_role[player:objectName()] == "rebel" or sgs.compareRoleEvaluation(player, "rebel", "loyalist") == "rebel" then
				other_rebel = player
				break
			end
		end
		if not other_rebel and ((from:getHp() >= 4 and (getCardsNum("Peach", from, self.player) > 0 or from:hasSkills("nosganglie|vsnosganglie"))) or from:hasSkill("hongyan")) then
			return false
		end
	end

	if (self:hasSuit("spade", true, to) and hcard >= 2) or hcard >= 4 then return true end
	if to:getTreasure() and to:getPile("wooden_ox"):length() > 1 then return true end
end

sgs.ai_skill_invoke.gzj_jiazi = function(self)
	if self.player:hasFlag("DimengTarget") then
		local another
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasFlag("DimengTarget") then
				another = player
				break
			end
		end
		if not another or not self:isFriend(another) then return false end
	end
	return not self:needKongcheng(self.player, true)
end

sgs.ai_skill_askforag.gzj_jiazi = function(self, card_ids)
	if self:needKongcheng(self.player, true) then return card_ids[1] else return -1 end
end




sgs.ai_skill_playerchosen.gzj_guifen = function(self, targets)
	local targetlist = sgs.QList2Table(targets)
	local target
	local lord
	for _, player in ipairs(targetlist) do
		if player:isLord() then lord = player end
		if self:isEnemy(player) and (not target or target:getHp() < player:getHp()) then
			target = player
		end
	end
	if self.role == "rebel" and lord then return lord end
	if target then return target end
	self:sort(targetlist, "hp")
	if self.player:getRole() == "loyalist" and targetlist[1]:isLord() then return targetlist[2] end
	return nil
end


sgs.ai_slash_prohibit.gzj_guifen = function(self, from, to)
	if from:hasSkill("jueqing") then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	local damageNum = self:hasHeavySlashDamage(from, nil, to, true)

	if self:isEnemy(to, from) and (to:getHp() == 1 or self:isWeak(to)) then
		if not (#(self:getEnemies(from)) == 1 and #(self:getFriends(from)) + #(self:getEnemies(from)) == self.room:alivePlayerCount()) then
			return true
		end
	end
end


sgs.ai_skill_cardask["@gzj_tiandao-card"] = function(self, data)
	local judge = data:toJudge()
	local all_cards = self.player:getCards("h")

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			all_cards:prepend(sgs.Sanguosha:getCard(id))
		end
	end

	if all_cards:isEmpty() then return "." end

	local needTokeep = judge.card:getSuit() ~= sgs.Card_Spade and sgs.ai_AOE_data and
	self:playerGetRound(judge.who) < self:playerGetRound(self.player)

	if not needTokeep then
		local who = judge.who
		if who:getPhase() == sgs.Player_Judge and not who:getJudgingArea():isEmpty() and who:containsTrick("lightning") and judge.reason ~= "lightning" then
			needTokeep = true
		end
	end
	local keptspade, keptblack = 0, 0
	if needTokeep then
		if self.player:hasSkill("gzj_guifen") then keptspade = 2 end
	end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not card:hasFlag("using") then
			if card:getSuit() == sgs.Card_Spade then keptspade = keptspade - 1 end
			keptblack = keptblack - 1
			table.insert(cards, card)
		end
	end

	if #cards == 0 then return "." end
	if keptspade == 1 and not self.player:hasSkill("gzj_guifen") then return "." end

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


function sgs.ai_cardneed.gzj_tiandao(to, card, self)
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

sgs.gzj_tiandao_suit_value = {
	heart = 3.9,
	club = 3.9,
	spade = 3.5
}
