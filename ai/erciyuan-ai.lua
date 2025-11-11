sgs.ai_chaofeng.itomakoto = -2
sgs.ai_chaofeng.ayanami = 3
sgs.ai_chaofeng.keima = 0
sgs.ai_chaofeng.SPkirito = 3
sgs.ai_chaofeng.odanobuna = 3
sgs.ai_chaofeng.yuuta = -2
sgs.ai_chaofeng.tsukushi = -2
sgs.ai_chaofeng.mao_maoyu = 1
sgs.ai_chaofeng.sheryl = 5
sgs.ai_chaofeng.aoitori = 3
sgs.ai_chaofeng.batora = -4
sgs.ai_chaofeng.kyouko = 4
sgs.ai_chaofeng.diarmuid = 6
sgs.ai_chaofeng.ikarishinji = -5
sgs.ai_chaofeng.redarcher = 2
sgs.ai_chaofeng.redo = 2
sgs.ai_chaofeng.runaria = -3
sgs.ai_chaofeng.fuwaaika = 5
sgs.ai_chaofeng.slsty = -2
sgs.ai_chaofeng.rokushikimei = 4
sgs.ai_chaofeng.bernkastel = 5
sgs.ai_chaofeng.hibiki = 4
sgs.ai_chaofeng.kntsubasa = 2
sgs.ai_chaofeng.khntmiku = 5
sgs.ai_chaofeng.yukinechris = 5


--装备
local function isEquip(name, player)
	for _, e in sgs.qlist(player:getEquips()) do
		if e:isKindOf(name) then
			return true
		end
	end
	return false
end
--渣
sgs.ai_skill_cardchosen.renzha = function(self, who, flags)
	local cards = who:getHandcards()
	self:sortByUseValue(cards, true)
	return cards:first()
end

sgs.ai_skill_invoke.ak_renzha = function(self, data)
	local damage = data:toDamage()
	local x = self.player:getMark("ak_renzha")
	if damage.damage >= 2 and x >= 2 then
		return true
	end
	if not self.player:faceUp() then
		return true
	end
	return false
end

sgs.ai_skill_discard.ak_renzha = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	table.insert(to_discard, cards[1]:getEffectiveId())
	return to_discard
end

sgs.ai_need_damaged.ak_renzha = function(self, attacker, player)
	if not (player:hasSkill("chanyuan") and player:getHp() == 2) and player:hasSkill("ak_renzha") and self:getEnemyNumBySeat(self.room:getCurrent(), player, player, true) < player:getHp()
		and (player:getHp() >= 2 and not player:faceUp()) then
		return true
	end
	return false
end

sgs.ai_can_damagehp.ak_renzha = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)  and self:getEnemyNumBySeat(self.room:getCurrent(), to, to, true) < to:getHp()
end


luarenzha_skill = {}
luarenzha_skill.name = "luarenzha"
table.insert(sgs.ai_skills, luarenzha_skill)
luarenzha_skill.getTurnUseCard          = function(self, inclusive)
	if self.player:hasUsed("#luarenzhacard") then return end
	if self.player:getPile("zha"):length() == 0 then return end

	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) then
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
		if getCardsNum("Analeptic", player) > 0 then
			if self:isFriend(player) then
				good = good + 1.0 / hp
			else
				bad = bad + 1.0 / hp
			end
		end

		local has_slash = (getCardsNum("Slash", player) > 0)
		local can_slash = false
		if not can_slash then
			for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
				if player:distanceTo(p) <= player:getAttackRange() then
					can_slash = true
					break
				end
			end
		end
		if not has_slash or not can_slash then
			if self:isFriend(player) then
				good = good + math.max(getCardsNum("Peach", player), 1)
			else
				bad = bad + math.max(getCardsNum("Peach", player), 1)
			end
		end

		if getCardsNum("Jink", player) == 0 then
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

	if self.player:isWounded() then
		good = good + math.min(self.player:getPile("zha"):length(), self.player:getLostHp())
	end
	if self.player:faceUp() then
		bad = bad +
			0.5 * self.room:getOtherPlayers(self.player):length() /
			math.min(self.player:getPile("zha"):length(), self.player:getLostHp())
	end
	if good > bad then
		local renzha = sgs.Sanguosha:getCard(self.player:getPile("zha"):first())
		return sgs.Card_Parse("#luarenzhacard:" .. renzha:getId() .. ":")
	end
end

sgs.ai_skill_use_func["#luarenzhacard"] = function(card, use, self)
	use.card = card
	return
end

sgs.ai_use_priority["luarenzhacard"]    = 4.2
sgs.ai_card_intention["luarenzhacard"]  = 0

--凌波丽
sgs.ai_cardneed.weixiao = sgs.ai_cardneed.bignumber
sgs.ai_skill_discard.weixiao            = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	if self.player:getHandcardNum() < 2 then return {} end
	local max_number = 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		max_number = math.max(max_number, card:getNumber())
	end
	if max_number >= 4 then
		local card_num_max = 0
		local card_n
		local card_num_max2 = 0
		local card_n2
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:getNumber() > card_num_max then
				card_num_max2 = card_num_max
				card_num_max = card:getNumber()
				card_n2 = card_n
				card_n = card
			else
				if card:getNumber() <= card_num_max and card:getNumber() > card_num_max2 then
					card_num_max2 = card:getNumber()
					card_n2 = card
				end
			end
		end
		local x = card_num_max2 / 2
		local n = card_num_max / 2
		self.weixiao = nil
		self:updatePlayers()
		if #self.friends == 1 then
			self.weixiao = self.player
			self.weixiaochoice = "a"
			if card_n and card_n2 then
				table.insert(to_discard, card_n:getEffectiveId())
				table.insert(to_discard, card_n2:getEffectiveId())
				return to_discard
			end
		end
		local player = self:AssistTarget()

		if x == 1 then
			self.weixiao = self.player
		elseif #self.friends > 1 then
			self:sort(self.friends, "chaofeng")
			if not self.weixiao and (self:isWeak(self.player) or self.player:getHandcardNum() <= 4) and not self:needKongcheng(self.player, true) then
				self.weixiao = self.player
			end
			if not self.weixiao and #self.enemies > 0 then
				local wf
				if self.player:isLord() then
					if self:isWeak() and (self.player:getHp() < 2 and self:getCardsNum("Peach") < 1) then
						wf = true
					end
				end
				if not wf then
					for _, friend in ipairs(self.friends) do
						if self:isWeak(friend) then
							wf = true
							break
						end
					end
				end

				if not wf then
					self:sort(self.enemies, "chaofeng")
					for _, enemy in ipairs(self.enemies) do
						if enemy:getCards("he"):length() == n
							and self:doDisCard(enemy, "he", false, n) then
							self.weixiaochoice = "b"
							self.weixiao = enemy
							if card_n and card_n2 then
								table.insert(to_discard, card_n:getEffectiveId())
								table.insert(to_discard, card_n2:getEffectiveId())
								return to_discard
							end
						end
					end
					for _, enemy in ipairs(self.enemies) do
						if enemy:getCards("he"):length() >= n
							and self:doDisCard(enemy, "he", false, n)
							and self:hasSkills(sgs.cardneed_skill, enemy) then
							self.weixiaochoice = "b"
							self.weixiao = enemy
							if card_n and card_n2 then
								table.insert(to_discard, card_n:getEffectiveId())
								table.insert(to_discard, card_n2:getEffectiveId())
								return to_discard
							end
						end
					end
				end
			end
			if not self.weixiao and player and not hasManjuanEffect(player) and not self:needKongcheng(player, true) then
				self.weixiao = player
			end

			if not self.weixiao then
				self.weixiao = self:findPlayerToDraw(true, n)
			end
			if not self.weixiao then
				for _, friend in ipairs(self.friends) do
					if not hasManjuanEffect(friend) then
						self.weixiao = friend
						break
					end
				end
			end
			if self.weixiao then self.weixiaochoice = "a" end
		end
		if not self.weixiao and x > 1 and #self.enemies > 0 then
			self:sort(self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if enemy:getCards("he"):length() >= n
					and self:doDisCard(enemy, "he", false, n) then
					self.weixiaochoice = "b"
					self.weixiao = enemy
					if card_n and card_n2 then
						table.insert(to_discard, card_n:getEffectiveId())
						table.insert(to_discard, card_n2:getEffectiveId())
						return to_discard
					end
				end
			end
			self.enemies = sgs.reverse(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isNude()
					and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
					and not self:needToThrowArmor(enemy)
					and not hasTuntianEffect(enemy) then
					self.weixiaochoice = "b"
					self.weixiao = enemy
					if card_n and card_n2 then
						table.insert(to_discard, card_n:getEffectiveId())
						table.insert(to_discard, card_n2:getEffectiveId())
						return to_discard
					end
				end
			end
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isNude()
					and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
					and not self:needToThrowArmor(enemy)
					and not (hasTuntianEffect(enemy) and x < 3 and enemy:getCards("he"):length() < 2) then
					self.weixiaochoice = "b"
					self.weixiao = enemy
					if card_n and card_n2 then
						table.insert(to_discard, card_n:getEffectiveId())
						table.insert(to_discard, card_n2:getEffectiveId())
						return to_discard
					end
				end
			end
		end
		if card_n and card_n2 then
			table.insert(to_discard, card_n:getEffectiveId())
			table.insert(to_discard, card_n2:getEffectiveId())
			return to_discard
		end
	end
	return {}
end
sgs.ai_skill_choice.weixiao             = function(self, choices, data)
	return self.weixiaochoice
end


sgs.ai_skill_playerchosen.weixiao = function(self, targets)
	return self.weixiao
end


sgs.ai_playerchosen_intention.weixiao = function(self, from, to)
	local intention = -80
	if hasManjuanEffect(to) then intention = -intention end
	if self.weixiaochoice == "a" then
	elseif self.weixiaochoice == "b" then
		intention = -intention
	end
	sgs.updateIntention(from, to, intention)
end
sgs.ai_cardneed.weixiao = sgs.ai_cardneed.bignumber
sgs.ai_use_revises.weixiao = function(self, card, use)
	if card:isKindOf("EquipCard")

	then
		same = self:getSameEquip(card)
		if same
		then
			return false
		end
	end
end


--SP桐人
sgs.ai_cardneed.LuaChanshi = function(to, card)
	return isCard("Slash", card, to)
end
sgs.ai_cardneed.LuaZhuan = function(to, card)
	return (card:isBlack() and isCard("Slash", card, to)) or isCard("Duel", card, to)
end

--神大人
luagonglue_skill = {}
luagonglue_skill.name = "luagonglue"
table.insert(sgs.ai_skills, luagonglue_skill)
luagonglue_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies < 1 or self.player:hasUsed("#luagongluecard") then return end
	return sgs.Card_Parse("#luagongluecard:.:")
end


sgs.ai_skill_use_func["#luagongluecard"] = function(card, use, self)
	local target
	self:sort(self.enemies, "defense")
	local lord = self.room:getLord()
	if self.player:getRole() == "rebel" then
		if not lord:isKongcheng() then
			target = lord
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				target = enemy
			end
		end
	end
	if target then
		use.card = sgs.Card_Parse("#luagongluecard:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["luagongluecard"]       = 8
sgs.ai_use_priority["luagongluecard"]    = 8
sgs.ai_card_intention["luagongluecard"]  = 60


--信奈
sgs.ai_skill_playerchosen.LuaChigui = function(self, targets)
	if self:isWeak(self.player) then return nil end
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local dest
	local temp = 0
	for _, target in ipairs(targets) do
		local count = 0
		if self:isFriend(target) then
			if target:getWeapon() and self:hasSkills(sgs.lose_equip_skill, target) then
				for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
					if target:inMyAttackRange(p) and self:isEnemy(p) then
						count = count + 1
					end
				end
			end
		else
			if not target:getWeapon() or self:hasSkills(sgs.lose_equip_skill, target) then return nil end
			for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
				if target:inMyAttackRange(p) and self:isFriend(p) then
					count = count + 1
				end
			end
		end
		if count > temp then
			temp = count
			dest = target
		end
	end
	if dest and temp > 2 then return dest end
	return nil
end

sgs.ai_skill_invoke.LuaBuwu = function(self, data)
	local target = data:toPlayer()
	if not target:faceUp() and self:isFriend(target) then
		return not self:toTurnOver(target, target:getHp() - 1, "LuaBuwu")
	end

	if self:isEnemy(target) then
		if self:toTurnOver(target, target:getHp() - 1, "LuaBuwu") then
			return true
		end
	end
end

sgs.ai_choicemade_filter.skillInvoke.LuaBuwu = function(self, player, promptlist)
	local intention = 60
	local index = promptlist[#promptlist] == "yes" and 1 or -1
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if hasManjuanEffect(damage.to) and index then sgs.updateIntention(damage.from, damage.to, 80) end
		if not self:toTurnOver(damage.to, damage.to:getHp() - 1) then intention = -intention * index end
		if damage.to:getHp() - 1 < 3 then
			sgs.updateIntention(damage.from, damage.to, intention * index)
		else
			sgs.updateIntention(damage.from, damage.to, math.min(intention, -30) * index)
		end
	end
end


sgs.ai_skill_invoke.LuaTianmoDefense = function(self, data)
	if self.player:getMark("@tianmo") == 0 then return false end
	local damage = data:toDamage()
	if not self:needToLoseHp(damage.to, damage.from, damage.card) then
		return true
	end
	return false
end


--勇太
LuaWangxiang_skill = {}
LuaWangxiang_skill.name = "LuaWangxiang"
table.insert(sgs.ai_skills, LuaWangxiang_skill)
LuaWangxiang_skill.getTurnUseCard   = function(self, inclusive)
	local wxhcn = self.player:getHandcardNum()
	local losehp = self.player:getMaxHp() - self.player:getHp()
	if wxhcn > losehp then return end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local card_nd = cards[1]
	return sgs.Card_Parse(("ex_nihilo:LuaWangxiang[%s:%s]=%d"):format(card_nd:getSuitString(), card_nd:getNumberString(),
		card_nd:getEffectiveId()))
end

sgs.ai_use_value["LuaWangxiang"]    = 10
sgs.ai_use_priority["LuaWangxiang"] = 9

luablackflame_skill                 = {}
luablackflame_skill.name            = "luablackflame"
table.insert(sgs.ai_skills, luablackflame_skill)
luablackflame_skill.getTurnUseCard          = function(self, inclusive)
	if #self.enemies < 1 then return end
	local source = self.player
	if source:hasUsed("#luablackflamecard") then return end
	if self.player:getHp() <= 2 then return end
	return sgs.Card_Parse("#luablackflamecard:.:")
end

sgs.ai_skill_use_func["#luablackflamecard"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Fire, self.player) then
			if self.player:getHp() > enemy:getHp() and self.player:getHp() > 1 and self:canDamage(enemy,self.player,nil) then
				use.card = sgs.Card_Parse("#luablackflamecard:.:")
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
end

sgs.ai_use_value["luablackflamecard"]       = 8
sgs.ai_use_priority["luablackflamecard"]    = 10
sgs.ai_card_intention.luablackflamecard     = 90

--钢铁
sgs.ai_skill_invoke.LuaGqset                = function(self, data)
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("BasicCard") or card:isKindOf("TrickCard") then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardchosen.LuaGqset            = function(self, who, flags)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("BasicCard") then
			return card
		end
		if card:isKindOf("TrickCard") then
			return card
		end
	end
	return cards[1]
end
sgs.ai_skill_discard.LuaGqset               = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:isKindOf("BasicCard") then
			table.insert(to_discard, card:getEffectiveId())
			return to_discard
		end
		if card:isKindOf("TrickCard") then
			table.insert(to_discard, card:getEffectiveId())
			return to_discard
		end
	end
	return {}
end

function sgs.ai_slash_prohibit.LuaGqset(self, from, to, card)
	if to:hasSkill("LuaGqset") and to:getPile("gang"):length() > 0 and sgs.Sanguosha:getCard(to:getPile("gang"):first()):getTypeId() == sgs.Card_TypeBasic then return true end
end

sgs.ai_target_revises.LuaGqset = function(to, card, self)
	if to:getPile("gang"):length() > 0 then
		local newcard = sgs.Sanguosha:getCard(to:getPile("gang"):first())
		return newcard:getTypeId() == card:getTypeId()
	end
end


luatiaojiao_skill = {}
luatiaojiao_skill.name = "luatiaojiao"
table.insert(sgs.ai_skills, luatiaojiao_skill)
luatiaojiao_skill.getTurnUseCard          = function(self, inclusive)
	if self.player:hasUsed("#luatiaojiaocard") then return end
	for _, friend in ipairs(self.friends) do
		if friend:getJudgingArea():length() > 0 then
			return sgs.Card_Parse("#luatiaojiaocard:.:")
		end
	end
	if #self.enemies < 1 then return end
	if #self.enemies == 1 and self.enemies[1]:isNude() then return end
	return sgs.Card_Parse("#luatiaojiaocard:.:")
end

sgs.ai_skill_use_func["#luatiaojiaocard"] = function(card, use, self)
	for _, friend in ipairs(self.friends_noself) do
		if friend:getJudgingArea():length() > 0
			and not friend:hasSkills("shensu|qingyi|qiaobian")
			and (self:isWeak(friend) or self:getOverflow(friend) > 1)
		then
			for _, c in sgs.list(friend:getJudgingArea()) do
				if not c:isKindOf("YanxiaoCard") then
					use.card = sgs.Card_Parse("#luatiaojiaocard:.:")
					if use.to then use.to:append(friend) end
					return
				end
			end
		end
	end
	local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
	local collateral = dummyCard("collateral")
	self:useCardCollateral(collateral, dummy_use)
	if dummy_use.card and dummy_use.to:length() == 2 then
		use.card = sgs.Card_Parse("#luatiaojiaocard:.:")
		self.room:setPlayerFlag(dummy_use.to:last(), "luatiaojiao_target")
		if use.to then use.to:append(dummy_use.to:first()) end
		return
	end
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isNude() then
			for _, enemy2 in ipairs(self.enemies) do
				if enemy:objectName() ~= enemy2:objectName()
					and enemy:canSlash(enemy2)
					and (self:cantbeHurt(enemy2) or not self:needToLoseHp(enemy2, enemy, nil, true)) and self:canDamage(enemy,self.player,nil) then
					use.card = sgs.Card_Parse("#luatiaojiaocard:.:")
					self.room:setPlayerFlag(enemy2, "luatiaojiao_target")
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end
end

sgs.ai_use_value["luatiaojiaocard"]       = 8
sgs.ai_use_priority["luatiaojiaocard"]    = 10
sgs.ai_card_intention.luatiaojiaocard     = 30


sgs.ai_skill_playerchosen.luatiaojiaocard = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if p:hasFlag("luatiaojiao_target") then
			self.room:setPlayerFlag(p, "-luatiaojiao_target")
			return p
		end
	end
	local target
	for _, p in ipairs(sgs.QList2Table(self.room:getAlivePlayers())) do
		if p:hasFlag("luatiaojiaocard") then
			target = p
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()

	for _, enemy in ipairs(targets) do
		if target:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:getDefenseSlash(enemy) <= 2
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			and enemy:objectName() ~= target:objectName() then
			return enemy
		end
	end
	return targets[0]
end

sgs.ai_skill_cardask["@TiaojiaoSlash"] = function(self, data, pattern, target)
	if self.player:getJudgingArea():length() > 0
		and not self.player:hasSkills("shensu|qingyi|qiaobian")
		and (self:isWeak(self.player) or self:getOverflow(self.player) > 1)
	then
		for _, c in sgs.list(self.player:getJudgingArea()) do
			if not c:isKindOf("YanxiaoCard") then
				for _, p in ipairs(sgs.QList2Table(self.room:getAlivePlayers())) do
					if p:hasFlag("luatiaojiaocard") then
						if self:isFriend(p) then
							return "."
						end
					end
				end
			end
		end
	end
	if target then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:isFriend(target) and self:slashIsEffective(slash, target) then
				if self:needLeiji(target, self.player) then return slash:toString() end
				if self:needToLoseHp(target, self.player, nil, true) then return slash:toString() end
			end

			if not self:isFriend(target) and self:slashIsEffective(slash, target)
				and not self:needLeiji(target, self.player)
			then
				return slash:toString()
			end
		end
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:isFriend(target) then
				if not self:needLeiji(target, self.player) and not self:needToLoseHp(target, self.player, slash) then
					return
						slash:toString()
				end
				if not self:slashIsEffective(slash, target) then return slash:toString() end
			end
		end
	end
	return "."
end

--经济学魔王
luaboxue_skill = {}
luaboxue_skill.name = "luaboxue"
table.insert(sgs.ai_skills, luaboxue_skill)
luaboxue_skill.getTurnUseCard          = function(self, inclusive)
	if self.player:hasUsed("#luaboxuecard") then return end
	--if #self.friends < 2 then return end
	return sgs.Card_Parse("#luaboxuecard:.:")
end

sgs.ai_skill_use_func["#luaboxuecard"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	for _, friend in ipairs(self.friends) do
		if not friend:isNude() then
			targets:append(friend)
		end
	end
	if targets then
		use.card = sgs.Card_Parse("#luaboxuecard:.:")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_value["luatiaojiaocard"]    = 8
sgs.ai_use_priority["luatiaojiaocard"] = 10
sgs.ai_card_intention.luatiaojiaocard  = -60

sgs.ai_skill_choice.luaboxuecard       = function(self, choices, data)
	return "gx"
end

local LuaYaojing_skill                 = {}
LuaYaojing_skill.name                  = "LuaYaojing"
table.insert(sgs.ai_skills, LuaYaojing_skill)

LuaYaojing_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return end
	local can = false
	local cards = sgs.QList2Table(self.player:getHandcards())
	local subcards = {}
	self:sortByUseValue(cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
		if not (isCard("Peach", card, self.player) or isCard("ExNihilo", card, self.player)) then
			table.insert(cardsq,
				card)
		end
	end
	if #cardsq == 0 then return end
	if self:getKeepValue(cardsq[1]) > 18 then return end
	if self:getUseValue(cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getId())
	local card_str = "god_salvation:LuaYaojing[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = sgs.Card_Parse(card_str)
	assert(AsCard)
	return AsCard
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|LuaYaojing"

sgs.ai_skill_playerchosen.LuaGongming = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	for _, friend in ipairs(targets) do
		if not self:isFriend(friend) then
			table.removeOne(targets, friend)
		end
	end
	local max_x = 0
	local target
	local Shenfen_user
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	if Shenfen_user then
		local y, weak_friend = 3
		for _, friend in ipairs(targets) do
			local x = self.player:getLostHp() + 1
			if hasManjuanEffect(friend) and x > 0 then x = x + 1 end
			if x > max_x and friend:isAlive() then
				max_x = x
				target = friend
			end

			if self:playerGetRound(friend, Shenfen_user) > self:playerGetRound(self.player, Shenfen_user) and x >= y
				and friend:getHp() == 1 and getCardsNum("Peach", friend, self.player) < 1 then
				y = x
				weak_friend = friend
			end
		end

		if weak_friend and ((getCardsNum("Peach", Shenfen_user, self.player) < 1) or (math.min(Shenfen_user:getMaxHp(), 5) - Shenfen_user:getHandcardNum() <= 1)) then
			return weak_friend
		end
		if self:isFriend(Shenfen_user) and math.min(Shenfen_user:getMaxHp(), 5) > Shenfen_user:getHandcardNum() then
			return Shenfen_user
		end
		if target then return target end
	end

	local CP = self.room:getCurrent()
	local max_x = 0
	local AssistTarget = self:AssistTarget()
	for _, friend in ipairs(targets) do
		local x = self.player:getLostHp() + 1
		if hasManjuanEffect(friend) then x = x + 1 end
		if self:hasCrossbowEffect(CP) then x = x + 1 end
		if AssistTarget and friend:objectName() == AssistTarget:objectName() then x = x + 0.5 end

		if x > max_x and friend:isAlive() then
			max_x = x
			target = friend
		end
	end
	if not target then
		target = self.player
	end
	return target
end
--裸王
--[[
sgs.ai_skill_playerchosen.LuaLuowang = function(self, targets)
	local list = self.room:getAlivePlayers()
	local card_min = 100
	local target
	for _,friend in ipairs(self.friends) do
		local card_num = friend:getHandcardNum()
		if friend:getHp() == 1 then
			card_num = card_num - 1
		end
		if friend:getArmor() then
			card_num = card_num + 1
		end
		if friend:getHandcardNum() > friend:getHp() then
			card_num = card_num - 1
		end
		if card_num < card_min then
			card_min = card_num
			target = friend
		end
	end
	if target then return target end
	return self.friends[1]
end]]

--枪兵
sgs.ai_cardneed.LuaPomo = sgs.ai_cardneed.slash
sgs.ai_cardneed.LuaBimie = sgs.ai_cardneed.slash
sgs.ai_use_revises.LuaPomo = function(self, card, use)
	if card:isKindOf("Slash")
	then
		card:setFlags("Qinggang")
	end
end

sgs.ai_skill_invoke.LuaBimie = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isEnemy(target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.LuaBimie = function(self, player, promptlist)
	local intention = 100
	local index = promptlist[#promptlist] == "yes" and 1 or -1
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if index == -1 then
			intention = -20
		end
		sgs.updateIntention(damage.from, damage.to, intention)
	end
end



function sgs.ai_cardneed.LuaBimie(to, card, self)
	local cards = to:getHandcards()
	local has_weapon = to:getWeapon()
	local slash_num = 0
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isKindOf("Weapon") then
				has_weapon = true
			end
			if c:isKindOf("Slash") then slash_num = slash_num + 1 end
		end
	end

	if not has_weapon then
		return card:isKindOf("Weapon")
	else
		return to:hasWeapon("spear") or card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic"))
	end
end

sgs.ai_skill_defense.LuaBimie = function(self, player)
	return self:isFriend(player) and player:getMaxHp() or -player:getMaxHp()
end

--真嗣乖乖
sgs.ai_skill_invoke.LuaBaozou = true
sgs.ai_skill_defense.LuaBaozou = 4

sgs.ai_skill_playerchosen["LuaXinbi"] = function(self, targets)
	return self:findPlayerToDiscard("e", true, true, targets, false)[1]
end

function sgs.ai_slash_prohibit.LuaBaozou(self, from, to, card)
	if to:getHp() <= 1 and not self:isFriend(from, to) then
		return (to:getHandcardNum() >= 2 and not self:willSkipDrawPhase(to)) or not self:willSkipPlayPhase(to)
	end
end

sgs.ai_ajustdamage_to.LuaBaozou = function(self, from, to, card, nature)
	if to:hasFlag("BaozouTurn") then
		return -99
	end
end
sgs.ai_can_damagehp.LuaBaozou = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) >= 0 and
		self:canLoseHp(from, card, to) then
		return (to:getHandcardNum() >= 2 and not self:willSkipDrawPhase(to)) or not self:willSkipPlayPhase(to)
	end
end


function sgs.ai_cardneed.LuaBaozou(to, card, self)
	return to:getHandcardNum() < 3
end


--红A
luatouying_skill = {}
luatouying_skill.name = "luatouying"
table.insert(sgs.ai_skills, luatouying_skill)
luatouying_skill.getTurnUseCard          = function(self, inclusive)
	if self.player:hasUsed("#luatouyingcard") then return end
	if self.player:getWeapon() then return end
	return sgs.Card_Parse("#luatouyingcard:.:")
end

sgs.ai_skill_use_func["#luatouyingcard"] = function(card, use, self)
	use.card = card
	return
end

sgs.ai_use_priority["luatouyingcard"]    = 10
sgs.ai_card_intention["luatouyingcard"]  = 0

sgs.ai_skill_choice.luatouying           = function(self, choices)
	-- if self.player:getWeapon() then return "crossbow" end
	-- local slashNum = self:getCardsNum("Slash")
	-- local cardNum = self.player:getHandcardNum()
	-- if slashNum == 0 then
	-- 	return "spear"
	-- end
	-- if slashNum > 2 then
	-- 	return "crossbow"
	-- end
	-- if cardNum >= 5 and slashNum > 0 then
	-- 	return "axe"
	-- end
	-- if #self.enemies > 0 then
	-- 	self:sort(self.enemies, "chaofeng")
	-- 	for _, p in ipairs(self.enemies) do
	-- 		if p:getArmor() and p:getArmor():isKindOf("Vine") then
	-- 			return "fan"
	-- 		end
	-- 		if not p:getArmor() and p:getHandcardNum() == 0 then
	-- 			return "guding_blade"
	-- 		end
	-- 		if not p:isMale() and not p:getArmor() then
	-- 			return "double_sword"
	-- 		end
	-- 		if p:getArmor() and p:getArmor() then
	-- 			return "qinggang_sword"
	-- 		end
	-- 	end
	-- else
	-- 	return "qinggang_sword"
	-- end
	local items = choices:split("+")
	return items[math.random(1, #items)]
end


function sgs.ai_cardsview.ZhangbaSkill(self, class_name, player)
	if class_name == "Slash" then
		return cardsView_spear(self, player, "ZhangbaSkill")
	end
end

local ZhangbaSkill_skill = {}
ZhangbaSkill_skill.name = "ZhangbaSkill"
table.insert(sgs.ai_skills, ZhangbaSkill_skill)
ZhangbaSkill_skill.getTurnUseCard = function(self, inclusive)
	return turnUse_spear(self, inclusive, "ZhangbaSkill")
end

sgs.ai_skill_invoke.ShemaSkill = sgs.ai_skill_invoke.kylin_bow



local LuaGongqi_skill = {}
LuaGongqi_skill.name = "LuaGongqi"
table.insert(sgs.ai_skills, LuaGongqi_skill)
LuaGongqi_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end

	local equip_card
	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive)
			and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			equip_card = card
			break
		end
	end

	if equip_card then
		local suit = equip_card:getSuitString()
		local number = equip_card:getNumberString()
		local card_id = equip_card:getEffectiveId()
		local card_str = ("slash:LuaGongqi[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)

		return slash
	end
end


function sgs.ai_cardneed.LuaGongqi(to, card, self)
	return card:getTypeId() == sgs.Card_TypeEquip and getKnownCard(to, self.player, "EquipCard", true) == 0
end

sgs.ai_choicemade_filter.cardChosen.LuaJianzhi = sgs.ai_choicemade_filter.cardChosen.snatch





local luajianyu_skill = {}
luajianyu_skill.name = "luajianyu"
table.insert(sgs.ai_skills, luajianyu_skill)

luajianyu_skill.getTurnUseCard = function(self)
	local yong = self.player:getPile("yong")
	local alivenum = self.room:getAlivePlayers():length()
	if yong:length() < alivenum then return end

	local cards = {}
	local subcards = {}

	if self.player:getPile("yong"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("yong")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(cards, true)
	if #cards == 0 or ((alivenum > 4) and (alivenum / yong:length()) < 1.5) then return end
	for i = 1, alivenum, 1 do
		table.insert(subcards, cards[i]:getId())
	end
	local card_str = "archery_attack:luajianyu[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = sgs.Card_Parse(card_str)
	assert(AsCard)
	return AsCard
end


--[[
luajianyu_skill={}
luajianyu_skill.name="luajianyu"
table.insert(sgs.ai_skills,luajianyu_skill)
luajianyu_skill.getTurnUseCard=function(self,inclusive)
	local yong = self.player:getPile("yong")
	local alivenum = self.room:getAlivePlayers()
	if yong:length() < alivenum then return end
	if #self.friends - 1 > #self.enemies then return end
	return sgs.Card_Parse("#luajianyucard:.:")
end

sgs.ai_skill_use_func["#luajianyucard"] = function(card,use,self)
	use.card = card
	return
end
]]

local LuaChitian_skill = {}
LuaChitian_skill.name = "LuaChitian"
table.insert(sgs.ai_skills, LuaChitian_skill)
LuaChitian_skill.getTurnUseCard = function(self, inclusive)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local no_have = true
	local cardsq = self.player:getCards("he")
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			cardsq:prepend(sgs.Sanguosha:getCard(id))
		end
	end
	for _, c in sgs.qlist(cardsq) do
		if c:isKindOf("Slash") then
			no_have = false
			break
		end
	end
	if not no_have then return end

	local cards = {}
	if self.player:getPile("yong"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("yong")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(cards, true)
	local use_cards = {}

	if #cards > 0 then
		table.insert(use_cards, cards[1])
	end
	if #use_cards == 0 then return end

	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and self:isGoodTarget(enemy, self.enemies, slash) and self.player:inMyAttackRange(enemy) then
			local slash = sgs.Sanguosha:cloneCard("slash")
			slash:deleteLater()
			if not self:slashProhibit(slash, enemy, self.player) and self:slashIsEffective(slash, enemy, self.player) then
				local card_str = ("slash:LuaChitian[%s:%s]=%d"):format(sgs.Card_NoSuit, 0, use_cards[1]:getEffectiveId())
				local AsCard = sgs.Card_Parse(card_str)
				assert(AsCard)
				return AsCard
			end
		end
	end
end

sgs.ai_skill_use_func["#LuaChitian"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local yizancard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	yizancard:deleteLater()
	yizancard:setSkillName("LuaChitian")
	self:useBasicCard(yizancard, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["LuaChitian"] = 3
sgs.ai_use_value["LuaChitian"] = 3

sgs.ai_view_as["LuaChitian"] = function(card, player, card_place, class_name)
	local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
	}
	local name = classname2objectname[class_name]
	if not name then return end
	local cards = player:getCards("he")
	local no_have = true
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

	local handcards = {}
	if player:getPile("yong"):length() == 0 then return end
	if not player:getPile("yong"):contains(card:getId()) then return end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	return (name .. ":LuaChitian[%s:%s]=%d"):format(suit, number, card_id)
end



--雷德
sgs.ai_skill_invoke.LuaChamberMove = function(self, data)
	if self.player:getMark("@Chamber") == 1 then
		if self.player:getHp() < 2 then
			return true
		end
	end
	if self.player:getMark("@Chamber") == 0 then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.LuaRedoWake = function(self, targets)
	if #self.enemies > 0 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:isAlive() and self:isGoodTarget(enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player) and not self:cantDamageMore(self.player, enemy) and self:canDamage(enemy,self.player,nil) then
				return enemy
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:isAlive() then
			return enemy
		end
	end
end


sgs.ai_skill_cardask["@jiguang"] = function(self, data, pattern)
	local effect = data:toCardEffect()
	if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
	if not self:slashIsEffective(effect.card, self.player, effect.from)
		or (not self:hasHeavyDamage(effect.from, effect.card, self.player)
			and self:needToLoseHp(self.player, effect.from, nil)) then
		return "."
	end
	if not self:hasHeavyDamage(effect.from, effect.card, self.player) and self:getCardsNum("Peach") > 0 then return "." end
	local equip_index = { 3, 0, 2, 4, 1 }
	if self.player:hasSkills(sgs.lose_equip_skill) then
		for _, i in ipairs(equip_index) do
			if i == 4 then break end
			if self.player:getEquip(i) then return "$" .. self.player:getEquip(i):getEffectiveId() end
		end
	end

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if (not self:isWeak() and (self:getKeepValue(card) > 8 or self:isValuableCard(card))) then continue end
		if card:isKindOf("BasicCard") then continue end
		return "$" .. card:getEffectiveId()
	end

	for _, i in ipairs(equip_index) do
		if self.player:getEquip(i) then
			if not (i == 1 and self:evaluateArmor() > 3)
				and not (i == 4 and self.player:getTreasure():isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() >= 3) then
				return "$" .. self.player:getEquip(i):getEffectiveId()
			end
		end
	end
end

sgs.ai_cardneed.LuaJiguangAsk = sgs.ai_cardneed.slash

sgs.ai_skill_discard.LuaWenle = function(self)
	local x = math.floor(self.room:alivePlayerCount() / 2)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for i = 1, x do
		table.insert(to_discard, cards[i]:getEffectiveId())
	end
	return to_discard
end

--月长石
luayukong_skill = {}
luayukong_skill.name = "luayukong"
table.insert(sgs.ai_skills, luayukong_skill)
luayukong_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#luayukongcard") then return end
	if self.player:getPile("si"):length() == 0 then return end
	if self.player:getAttackRange() > 2 then return end
	if #self.enemies <= 1 then return end
	local min_number = 13
	local cardx
	for _, id in sgs.qlist(self.player:getPile("si")) do
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuitString()
		local number = card:getNumber()
		local card_id = card:getEffectiveId()
		if number < min_number then
			min_number = number
			cardx = card
		end
	end
	if cardx then
		return sgs.Card_Parse("#luayukongcard:" .. cardx:getId() .. ":")
	end
end


sgs.ai_skill_use_func["#luayukongcard"] = function(card, use, self)
	use.card = card
	local min_number = 13
	local cardx
	for _, id in sgs.qlist(self.player:getPile("si")) do
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuitString()
		local number = card:getNumber()
		local card_id = card:getEffectiveId()
		if number < min_number then
			min_number = number
			cardx = card
		end
	end
	if cardx then
		return sgs.Card_Parse("#luayukongcard:" .. cardx:getId() .. ":")
	end
end

sgs.ai_use_priority["luayukongcard"]    = 10
sgs.ai_card_intention["luayukongcard"]  = 0


sgs.ai_skill_use["@@LuaQisi"] = function(self, prompt, method)
	local data = self.room:getTag("LuaQisiData")
	local effect = data:toCardEffect()
	local source = effect.from
	local itsar = source:getAttackRange()
	local max_number = 0
	local cardx
	for _, id in sgs.qlist(self.player:getPile("si")) do
		local card = sgs.Sanguosha:getCard(id)
		local suit = card:getSuitString()
		local number = card:getNumber()
		local card_id = card:getEffectiveId()
		if number > max_number then
			max_number = number
			cardx = card
		end
	end
	if max_number / 2 < itsar then return "." end
	if cardx then
		if self.role == "rebel" and sgs.ai_role[effect.from:objectName()] == "rebel" and not effect.from:hasSkill("jueqing")
			and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
			return "."
		end
		local card_str = "#LuaQisi:" .. cardx:getId() .. ":"
		if self:isEnemy(effect.from) or (self:isFriend(effect.from) and self.role == "loyalist" and not effect.from:hasSkill("jueqing") and effect.from:isLord() and self.player:getHp() == 1) then
			if effect.card:isKindOf("Slash") then
				if self:slashIsEffective(effect.card, self.player, effect.from) and self.player:getPile("si"):length() > 1 then
					return
						card_str
				end
				if self:hasHeavyDamage(effect.from, effect.card, self.player) then return card_str end

				local jink_num = self:getExpectedJinkNum(effect)
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
					or (effect.from:hasSkill("dahe") and self.player:hasFlag("dahe") and not hasHeart) then
					if effect.card:isKindOf("NatureSlash") and self.player:isChained() and not self:isGoodChainTarget(self.player, effect.from, nil, nil, effect.card) then
						return
							card_str
					end
					if effect.from:hasSkill("nosqianxi") and effect.from:distanceTo(self.player) == 1 then
						return
							card_str
					end
					if self:isFriend(effect.from) and self.role == "loyalist" and not effect.from:hasSkill("jueqing") and effect.from:isLord() and self.player:getHp() == 1 then
						return
							card_str
					end
					if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or effect.from:hasSkill("jueqing")) then
						return card_str
					end
				end
			elseif effect.card:isKindOf("AOE") then
				local from = effect.from
				if effect.card:isKindOf("SavageAssault") then
					local menghuo = self.room:findPlayerBySkillName("huoshou")
					if menghuo then from = menghuo end
				end

				local friend_null = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
					if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
				end
				friend_null = friend_null + self:getCardsNum("Nullification")
				local sj_num = self:getCardsNum(effect.card:isKindOf("SavageAssault") and "Slash" or "Jink")

				if not self:hasTrickEffective(effect.card, self.player, from) then return "." end
				if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then return "." end
				if effect.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then
					return
						card_str
				end
				if sj_num == 0 and friend_null <= 0 then
					if self:isEnemy(from) and from:hasSkill("jueqing") then return self:doDisCard(from) end
					if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not from:hasSkill("jueqing") then
						return
							card_str
					end
					if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or effect.from:hasSkill("jueqing")) then
						return card_str
					end
				end
			end
		elseif self:isEnemy(effect.from) then
			if effect.card:isKindOf("FireAttack") and effect.from:getHandcardNum() > 0 then
				if not self:hasTrickEffective(effect.card, self.player) then return "." end
				if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, effect.from) then return "." end
				if (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0) and effect.from:getHandcardNum() > 3
					and not (effect.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
					return card_str
				elseif self.player:isChained() and not self:isGoodChainTarget(self.player, effect.from) then
					return card_str
				end
			elseif (effect.card:isKindOf("Snatch") or effect.card:isKindOf("Dismantlement"))
				and self:getCardsNum("Peach") == self.player:getHandcardNum() and not self.player:isKongcheng() then
				if not self:hasTrickEffective(effect.card, self.player) then return "." end
				return card_str
			elseif effect.card:isKindOf("Duel") then
				if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", effect.from, self.player) then
					if not self:hasTrickEffective(effect.card, self.player) then return "." end
					if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, effect.from) then return "." end
					return card_str
				end
			elseif effect.card:isKindOf("TrickCard") and not effect.card:isKindOf("AmazingGrace") and not effect.card:isKindOf("GodSalvation") and not effect.card:isKindOf("ExNihilo") then
				return card_str
			end
		elseif effect.card:isKindOf("TrickCard") and not effect.card:isKindOf("AmazingGrace") and not effect.card:isKindOf("GodSalvation") and not effect.card:isKindOf("ExNihilo") then
			return card_str
		end
	end
	return "."
end




--[[
sgs.ai_skill_invoke.LuaQisi = function(self, data)
	local effect = data:toCardEffect()
	local source = effect.from
	local card = effect.card
	if card:isKindOf("Slash") then
		local itsar = source:getAttackRange()
		if itsar <= 3 then
			return true
		end
	end
	return false
end]]

--爱花（通过）
local function getSlashNum(player)
	local num = 0
	for _, card in sgs.qlist(player:getHandcards()) do
		if card:isKindOf("Slash") then
			num = num + 1
		end
	end
	return num
end

local luaposhi_skill = {}
luaposhi_skill.name = "luaposhi"
table.insert(sgs.ai_skills, luaposhi_skill)
luaposhi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#luaposhicard") then return end
	if self.player:getMark("&luaposhi") > 0 then return end
	if #self.enemies < 1 then return end
	if getSlashNum(self.player) < 2 then return end
	if self.player:getHp() < 2 and self:getCardsNum("Peach") == 0 then return end
	if getSlashNum(self.player) < 3 and (self.player:getHp() < 3 and self:getCardsNum("Peach") == 0) then return end
	return sgs.Card_Parse("#luaposhicard:.:")
end

sgs.ai_skill_use_func["#luaposhicard"] = function(card, use, self)
	use.card = sgs.Card_Parse("#luaposhicard:.:")
	return
end

sgs.ai_use_value["luaposhicard"] = 7
sgs.ai_use_priority["luaposhicard"] = 9

sgs.double_slash_skill = sgs.double_slash_skill .. "|luaposhi"
sgs.ai_cardneed.luaposhi = sgs.ai_cardneed.slash

sgs.ai_skill_invoke.LuaLiansuo = true
sgs.ai_skill_invoke.LuaYinguo = function(self, data)
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:isMale() and self:isFriend(p) then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.LuaYinguo = function(self, targets)
	local min_card_num = 100
	local target
	for _, p in sgs.qlist(targets) do
		if p:isMale() and self:isFriend(p) then
			if p:getHandcardNum() < min_card_num then
				target = p
				min_card_num = p:getHandcardNum()
			end
		end
	end
	if target then return target end
	return targets:first()
end

--赌徒
local yanhuoacquire_skill = {}
yanhuoacquire_skill.name = "yanhuoacquire"
table.insert(sgs.ai_skills, yanhuoacquire_skill)
yanhuoacquire_skill.getTurnUseCard = function(self, inclusive)
	if not self:isWeak() and not self.player:hasUsed("#yanhuoacquirecard") then
		local target
		local players = self.room:getOtherPlayers(self.player)
		for _, p in sgs.qlist(players) do
			--if p:hasSkill("slyanhuo") and not p:getPile("confuse"):isEmpty() and self:isEnemy(p) then
			if p:getPile("confuse"):length() > 0 and self:isEnemy(p) then
				target = p
				break
			end
		end
		if target then
			return sgs.Card_Parse("#yanhuoacquirecard:.:")
		end
	end
end


sgs.ai_skill_use_func["#yanhuoacquirecard"] = function(card, use, self)
	if not self:isWeak() then
		local target
		local players = self.room:getOtherPlayers(self.player)
		for _, p in sgs.qlist(players) do
			if p:getPile("confuse"):length() > 0 and self:isEnemy(p) then
				target = p
				break
			end
		end
		if target then
			use.card = card
			if use.to then use.to:append(target) end
			return
		end
	end
end

--这个判断甚为复杂。。。
sgs.ai_skill_invoke.slyanhuo = function(self, data)
	local damage = data:toDamage()
	if self.player:getPile("confuse"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("confuse")) do
			local card = sgs.Sanguosha:getCard(id)
			if card:getSuit() == sgs.Card_Spade and self:isFriend(damage.from) and self:isWeak(damage.from) then
				return true
			elseif card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Diamond then
				if self:isEnemy(damage.from) then
					return true
				end
			end
		end
	end
	--[[	if self:isFriend(damage.from) then
		if self:isWeak(damage.from) and #spade > 0 then
			return true
			end
		else
			if #heart > 0 or #diamond > 0 then
			return true
			end
	end]]
	return false
end


sgs.ai_skill_askforag["slyanhuo"] = function(self, card_ids)
	local data = self.room:getTag("slyanhuoData")
	local damage = data:toDamage()
	local cards = {}
	local spade = {}
	local heart = {}
	local club = {}
	local diamond = {}
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:getSuit() == sgs.Card_Spade then
			table.insert(spade, card)
		elseif card:getSuit() == sgs.Card_Heart then
			table.insert(heart, card)
		elseif card:getSuit() == sgs.Card_Club then
			table.insert(club, card)
		elseif card:getSuit() == sgs.Card_Diamond then
			table.insert(diamond, card)
		end
		table.insert(cards, card)
	end
	if self:isFriend(damage.from) then
		if self:isWeak(damage.from) and #spade > 0 then
			self:sortByUseValue(spade)
			return spade[1]:getId()
		elseif #club > 0 then
			self:sortByUseValue(club)
			return club[1]:getId()
		end
	else
		if #heart > 0 then
			self:sortByUseValue(heart)
			return heart[1]:getId()
		end
		if #diamond > 0 then
			self:sortByUseValue(diamond)
			return diamond[1]:getId()
		end
	end
	self:sortByUseValue(cards)
	return cards[1]:getId()
end

local yanhuovs_skill = {}
yanhuovs_skill.name = "slyanhuo"
table.insert(sgs.ai_skills, yanhuovs_skill)
yanhuovs_skill.getTurnUseCard          = function(self, inclusive)
	if self.player:getPile("confuse"):length() < 5 and self.player:getHandcardNum() > 0 and self.player:getPile("confuse"):length() < self.room:getAlivePlayers():length() then
		return sgs.Card_Parse("#slyanhuocard:.:")
	end
end

sgs.ai_skill_use_func["#slyanhuocard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if cards[1]:isKindOf("Peach") or cards[1]:isKindOf("Nullification") or cards[1]:isKindOf("Analeptic") then return end
	use.card = sgs.Card_Parse("#slyanhuocard:" .. cards[1]:getEffectiveId() .. ":")
	return
end
sgs.ai_use_priority["slyanhuo"]        = sgs.ai_use_priority.ExNihilo - 0.1
--64m
sgs.ai_skill_invoke.LuaHeartlead       = function(self, data)
	local use = data:toCardUse()
	local source = use.from
	local target = use.to:first()
	local card = use.card
	if card:isKindOf("Peach") and self:isEnemy(target) then return true end
	if self:isEnemy(source) and self:isFriend(target) and self.player:getHp() > 1 then return true end
	if self:isEnemy(source) and self:isFriend(target) and target:getHp() == 1 then return true end
	return false
end

sgs.ai_skill_choice["LuaHeartlead"]    = "chained"

sgs.ai_skill_playerchosen.LuaHeartlead = function(self, targets)
	local positive = true
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() <= 0 and self:isEnemy(p) then
			positive = false
		end
	end
	if positive then
		for _, p in sgs.qlist(targets) do
			if p:isEnemy() then return p end
		end
	else
		for _, p in sgs.qlist(targets) do
			if p:isFriend() and p:getHp() < p:getMaxHp() then return p end
		end
	end
	return targets:first()
end
--不确定...这个或许有别的考量
sgs.ai_skill_invoke.LuaHeartlead       = function(self, data)
	if self.player:getHp() == 1 and self.player:getHandcardNum() < 3 then return true end
	return false
end

--奇迹+碎片
sgs.ai_skill_invoke["erciyuan_qiji"]            = function(self, data)
	local dying = data:toDying()
	if self:isFriend(dying.who) then return true end
	return false
end
sgs.ai_skill_invoke["suipian"]         = function(self, data)
	local judge = data:toJudge()
	if self:needRetrial(judge) and (judge.pattern ~= ".") then return true end
	return false
end

sgs.ai_ajustdamage_from.LuaGungnir     = function(self, from, to, card, nature)
	if to:getHp() > from:getHp() then
		return 1
	end
end
sgs.ai_used_revises.LuaGungnir         = function(self, use)
	if use.card:isKindOf("Slash")
		and not self.player:getWeapon()
		and not use.isDummy
	then
		local use_card
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Weapon") then
				use_card = card
			end
		end
		if use_card then
			use.card = use_card

			use.to = sgs.SPlayerList()
			return false
		end
	end
end
sgs.hit_skill = sgs.hit_skill .. "|LuaGungnir"
sgs.ai_cardneed.LuaGungnir = sgs.ai_cardneed.weapon

sgs.ai_cardneed.luasynchrogazer = sgs.ai_cardneed.weapon
sgs.double_slash_skill = sgs.double_slash_skill .. "|luasynchrogazer"

sgs.ai_cardneed.LuaCangshan = sgs.ai_cardneed.equip

--萌战
sgs.ai_skill_invoke["moesenskill"] = function(self, data)
	local p = data:toPlayer()
	if self:isFriend(p) then return true end
	return false
end

--响（通过）
local luasynchrogazer_skill = {}
luasynchrogazer_skill.name = "luasynchrogazer"
table.insert(sgs.ai_skills, luasynchrogazer_skill)
luasynchrogazer_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#luasynchrogazercard") then return end
	if #self.enemies < 1 then return end
	return sgs.Card_Parse("#luasynchrogazercard:.:")
end

sgs.ai_skill_use_func["#luasynchrogazercard"] = function(card, use, self)
	use.card = sgs.Card_Parse("#luasynchrogazercard:.:")
	return
end


sgs.ai_skill_playerchosen["luasynchrogazer_Target"] = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end




sgs.ai_skill_playerchosen["luasynchrogazer_Friend"] = function(self, targets)
	local drawnum = 1
	local friends = {}
	local player_list = sgs.SPlayerList()
	for _, player in ipairs(targets) do
		if self:isFriend(player) and not hasManjuanEffect(player) and not self:needKongcheng(player, true)
			and not (player:hasSkill("kongcheng") and player:isKongcheng() and drawnum <= 2) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return targets:first() end

	self:sort(friends, "defense")
	for _, friend in ipairs(friends) do
		if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and (AssistTarget:getHandcardNum() < AssistTarget:getMaxCards() * 2 or AssistTarget:getHandcardNum() < self.player:getHandcardNum()) then
		for _, friend in ipairs(friends) do
			if friend:objectName() == AssistTarget:objectName() and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
				return friend
			end
		end
	end

	for _, friend in ipairs(friends) do
		if self:hasSkills(sgs.cardneed_skill, friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end

	self:sort(friends, "handcard")
	for _, friend in ipairs(friends) do
		if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) and not hasManjuanEffect(friend) then
			return friend
		end
	end
	return targets:first()
end



sgs.ai_use_value["luasynchrogazercard"] = 7
sgs.ai_use_priority["luasynchrogazercard"] = sgs.ai_use_priority.Slash + 0.1

--某翅膀（通过?...）
--[[LuaCangshan_skill={}
LuaCangshan_skill.name="LuaCangshan"
table.insert(sgs.ai_skills,LuaCangshan_skill)
LuaCangshan_skill.getTurnUseCard=function(self,inclusive)
	local has_equip = false
	local equip
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("EquipCard") then
			has_equip = true
			equip = card
		end
	end
	if not has_equip then
		for  _,card in sgs.qlist(self.player:getEquips()) do
			if not ((self.player:getWeapon() and card:getEffectiveId() == self.player:getWeapon():getId()) and card:isKindOf("Crossbow")) then
				equip =  card
			end
		end
	end
	if not sgs.Slash_IsAvailable(self.player) or not has_equip then return end
	return sgs.Card_Parse(("slash:LuaCangshan[%s:%s]=%d"):format(equip:getSuitString(),equip:getNumberString(),equip:getEffectiveId()))
end]]
--[[
sgs.ai_view_as.LuaCangshan = function(card, player, card_place)
	local cards = sgs.QList2Table(player:getCards("he"))
	local hand_equip = false
	local equip
	for _,card in sgs.qlist(player:getHandcards()) do
		if card:isKindOf("EquipCard") then
			hand_equip = true
			equip = card
		end
	end
	if not hand_equip then return end
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	if pattern == "Jink" then
		local cards = player:getCards("h")	
		cards=sgs.QList2Table(cards)
		for _,card in ipairs(cards)  do
			if card:isKindOf("Jink") then
				return
			end
		end
		return ("jink:LuaCangshan[%s:%s]=%d"):format(equip:getSuitString(),equip:getNumberString(),equip:getEffectiveId())
	elseif pattern == "Slash" then
		local cards = player:getCards("h")	
		cards=sgs.QList2Table(cards)
		for _,card in ipairs(cards)  do
			if card:isKindOf("Slash") then
				return
			end
		end
		return ("slash:LuaCangshan[%s:%s]=%d"):format(equip:getSuitString(),equip:getNumberString(),equip:getEffectiveId())
	end
end
]]

sgs.ai_view_as.LuaCangshan = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
		and card:getTypeId() == sgs.Card_TypeEquip and not card:hasFlag("using")
		and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
		if pattern == "Jink" then
			return ("Jink:LuaCangshan[%s:%s]=%d"):format(suit, number, card_id)
		elseif pattern == "Slash" then
			return ("slash:LuaCangshan[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

local LuaCangshan_skill = {}
LuaCangshan_skill.name = "LuaCangshan"
table.insert(sgs.ai_skills, LuaCangshan_skill)
LuaCangshan_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end

	local equip_card
	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive)
			and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			equip_card = card
			break
		end
	end

	if equip_card then
		local suit = equip_card:getSuitString()
		local number = equip_card:getNumberString()
		local card_id = equip_card:getEffectiveId()
		local card_str = ("slash:LuaCangshan[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)

		assert(slash)

		return slash
	end
end


local luayuehuang_skill = {}
luayuehuang_skill.name = "luayuehuang"
table.insert(sgs.ai_skills, luayuehuang_skill)
luayuehuang_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#luayuehuangcard") then return end
	--if #self.friends < 2 then return end
	return sgs.Card_Parse("#luayuehuangcard:.:")
end

sgs.ai_skill_use_func["#luayuehuangcard"] = function(card, use, self)
	use.card = sgs.Card_Parse("#luayuehuangcard:.:")
	return
end

sgs.ai_use_value["luayuehuangcard"] = 7
sgs.ai_use_priority["luayuehuangcard"] = 9
sgs.double_slash_skill = sgs.double_slash_skill .. "|luayuehuang"
sgs.ai_cardneed.luayuehuang = sgs.ai_cardneed.equip


--未来（通过）
--[[
sgs.ai_skill_invoke["LuaJingming"] = function(self, data)
	local p = data:toPlayer()
	if self.player:getHandcardNum() > 1 then
		if self:isFriend(p) then
			if isEquip("Crossbow", p) then return false end
			if p:getHp() == 1 and p:getHandcardNum() < 2 then return true end
			if p:getHp() == 2 and p:getHandcardNum() < 1 then return true end
			if p:getHandcardNum() + 5 < p:getHp() then return true end
		end
	end
	if self:isEnemy(p) then
		if p:getHandcardNum() > 3 and isEquip("Crossbow", p) then return true end
		if self:hasSkills("SE_Juji|SE_Juji_Reki|se_chouyuan|LuaTianmo|LuaBimie|luaposhi|LuaGungnir|luasaoshe",p) and p:getHandcardNum() > 1 then return true end
		if self:isWeak(self.player) and p:inMyAttackRange(self.player) then return true end
	end
	return false
end
]]

sgs.ai_skill_choice["LuaJingming"] = function(self, choices, data)
	local target
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("noslash_jm") == 1 then
			target = p
		end
	end
	if not target then return "cancel" end
	if self:isEnemy(target) then
		return "cancel"
	else
		if target:getMaxHp() - target:getHp() > 0 and target:getHandcardNum() >= 1 then return "recover" end
		return "eachdraw"
	end
	return "cancel"
end

sgs.ai_choicemade_filter.skillChoice["LuaJingming"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getMark("noslash_jm") == 1 then
			target = p
		end
	end
	if target then
		if choice ~= "cancel" then
			sgs.updateIntention(player, target, -40)
		end
	end
end

sgs.ai_skill_cardask["@jmdiscard"] = function(self, data, pattern, target, target2)
	local p = data:toPlayer()
	if self.player:getHandcardNum() > 1 then
		local card_id
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByKeepValue(hcards)
		if self:isFriend(p) then
			if isEquip("Crossbow", p) then return "." end
			if p:getHp() + p:getHandcardNum() >= 4 then return "." end
			if p:getHandcardNum() + 3 >= p:getHp() then return "." end
			card_id = hcards[1]:getEffectiveId()
			return hcards[1]:toString()
		elseif self:isEnemy(p) then
			if p:getHandcardNum() <= 3 then return "." end
			if not isEquip("Crossbow", p) then return "." end
			card_id = hcards[1]:getEffectiveId()
			if self:isWeak(self.player) and p:inMyAttackRange(self.player) then
				if card_id then
					return hcards[1]:toString()
				end
			end
		end
		if card_id then
			return hcards[1]:toString()
		end
	end
	return "."
end



local luayingxian_skill = {}
luayingxian_skill.name = "luayingxian"
table.insert(sgs.ai_skills, luayingxian_skill)
luayingxian_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#luayingxiancard") then return end
	--if #self.friends < 2 then return end
	return sgs.Card_Parse("#luayingxiancard:.:")
end

sgs.ai_skill_use_func["#luayingxiancard"] = function(card, use, self)
	use.card = sgs.Card_Parse("#luayingxiancard:.:")
	return
end

sgs.ai_use_value["luayingxiancard"] = 7
sgs.ai_use_priority["luayingxiancard"] = 9

sgs.ai_cardshow.luayingxiancard = function(self, requestor)
	local max = 0
	local result
	local cards = self.player:getHandcards()
	for _, card in sgs.qlist(cards) do
		if card:getNumber() > max then
			max = card:getNumber()
			result = card
		end
	end


	return result -- 返回结果
end

--kurisu（通过）
luasaoshe_skill = {}
luasaoshe_skill.name = "luasaoshe"
table.insert(sgs.ai_skills, luasaoshe_skill)
luasaoshe_skill.getTurnUseCard          = function(self, inclusive)
	if #self.enemies < 1 then return end
	if self.player:isKongcheng() then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local card_OK = false
	for _, acard in ipairs(cards) do
		if not acard:isKindOf("Jink") and not acard:isKindOf("Peach") and not acard:isKindOf("Analeptic") then
			card_OK = true
		end
	end
	if not card_OK then return end
	local selfSub = self.player:getHp() - self.player:getHandcardNum()
	local selfDef = sgs.getDefense(self.player)

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(nil, enemy) and def < 6 and eff and enemy:getMark("SaosheX") < 2 then
			return sgs.Card_Parse("#luasaoshecard:.:")
		end
	end
end

sgs.ai_skill_use_func["#luasaoshecard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local target
	local card
	for _, acard in ipairs(cards) do
		if not acard:isKindOf("Jink") and not acard:isKindOf("Peach") and not acard:isKindOf("Analeptic") then
			card = acard
		end
	end
	local selfSub = self.player:getHp() - self.player:getHandcardNum()
	local selfDef = sgs.getDefense(self.player)

	for _, enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, nil)

		if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(nil, enemy) and def < 6 and eff and enemy:getMark("SaosheX") < 2 then
			target = enemy
			break
		end
	end
	if target and card then
		use.card = sgs.Card_Parse("#luasaoshecard:" .. card:getEffectiveId() .. ":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["luasaoshecard"]       = 9
sgs.ai_use_priority["luasaoshecard"]    = 3.2
sgs.ai_card_intention["luasaoshecard"]  = 80

sgs.ai_skill_invoke.LuaDikai            = function(self, data)
	local damage = data:toDamage()
	if damage.from and self:isEnemy(damage.from) then
		if self:doDisCard(damage.from) then
			return true
		end
	end
	if self:isFriend(damage.from) then
		return self:needToThrowArmor(damage.from) or self:doDisCard(damage.from)
	end
	return not damage.from or not self:isFriend(damage.from)
end

sgs.ai_can_damagehp.LuaDikai = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and self:isWeak(from) and from:getCardCount()>0
	end
end

sgs.ai_skill_cardask["@dikai"]          = function(self, data, pattern, target)
	if self:isFriend(target) then
		local weapon, armor, def_horse, off_horse = {}, {}, {}, {}
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Weapon") then
				table.insert(weapon, card)
			elseif card:isKindOf("Armor") then
				table.insert(armor, card)
			elseif card:isKindOf("DefensiveHorse") then
				table.insert(def_horse, card)
			elseif card:isKindOf("OffensiveHorse") then
				table.insert(off_horse, card)
			end
		end
		if #armor > 0 then
			for _, card in ipairs(armor) do
				if ((not target:getArmor() and not target:hasSkills("bazhen|yizhong"))
						or (target:getArmor() and self:evaluateArmor(card, target) >= self:evaluateArmor(target:getArmor(), target)))
					and not (card:isKindOf("Vine") and use.card:isKindOf("FireSlash") and self:slashIsEffective(use.card, target, use.from)) then
					return "$" .. card:getEffectiveId()
				end
			end
		end
		if self:needToThrowArmor()
			and ((not target:getArmor() and not target:hasSkills("bazhen|yizhong"))
				or (target:getArmor() and self:evaluateArmor(self.player:getArmor(), target) >= self:evaluateArmor(target:getArmor(), target)))
			and not (self.player:getArmor():isKindOf("Vine") and use.card:isKindOf("FireSlash") and self:slashIsEffective(use.card, target, use.from)) then
			return "$" .. self.player:getArmor():getEffectiveId()
		end
		if #def_horse > 0 then return "$" .. def_horse[1]:getEffectiveId() end
		if #weapon > 0 then
			for _, card in ipairs(weapon) do
				if not target:getWeapon()
					or (self:evaluateArmor(card, target) >= self:evaluateArmor(target:getWeapon(), target)) then
					return "$" .. card:getEffectiveId()
				end
			end
		end
		if self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon()) < 5
			and (not target:getArmor()
				or (self:evaluateArmor(self.player:getWeapon(), target) >= self:evaluateArmor(target:getWeapon(), target))) then
			return "$" .. self.player:getWeapon():getEffectiveId()
		end
		if #off_horse > 0 then return "$" .. off_horse[1]:getEffectiveId() end
		if self.player:getOffensiveHorse()
			and ((self.player:getWeapon() and not self.player:getWeapon():isKindOf("Crossbow")) or self.player:hasSkills("mashu|tuntian")) then
			return "$" .. self.player:getOffensiveHorse():getEffectiveId()
		end
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if not self:isValuableCard(card) then return "$" .. card:getEffectiveId() end
		end
	end
end

--补充 裸王
sgs.ai_skill_playerchosen["LuaLuowang"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	if self.player:hasFlag("luoDraw") then
		return self:findPlayerToDraw(true)
	else
		local target = self:findPlayerToDiscard("he", true)[1]
		if target then
			return target
		end
		for _, enemy in ipairs(self.enemies) do
            if self:doDisCard(enemy, "he") then
				return enemy
            end
        end
	end
	return targets[1]
end
