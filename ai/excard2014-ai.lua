if not sgs.ai_nullification then
	sgs.ai_nullification = {}
end

if not sgs.ai_damage_effect then
	sgs.ai_damage_effect = {}
end

------------
function SmartAI:useCardEXCard_WWJZ(card, use)
	if self.player:aliveCount() <= 2 or #self.friends == 0 and sgs.turncount > 1 then
		use.card = card
		if use.to then use.to = sgs.SPlayerList() end
		return
	end
	local n = self:getOverflow()
	if n > 0 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		for i = 1, n do
			if cards[i]:getEffectiveId() == card:getEffectiveId() then
				use.card = card
				if use.to then use.to = sgs.SPlayerList() end
				return
			end
		end
	end
end
sgs.ai_skill_use.EXCard_WWJZ = function(self, prompt, method)
	local use = self.room:getTag("EXCard_WWJZ_data"):toCardUse()
	if not use or not use.from then return "." end
	local id = self:getCardId("EXCard_WWJZ")
	if not id then return "." end
	local slash = sgs.Sanguosha:cloneCard("slash")
	if not self:slashIsEffective(slash, use.from, self.player) then return "." end
	local cardparse = (id .. "->" .. use.from:objectName())
	local isFriend, needDamaged, needLeiji
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			needDamaged = self:getDamagedEffects(p, use.from, true) or self:needToLoseHp(p, use.from, true)
			needLeiji = self:needLeiji(p, use.from)
			isFriend = true
		end
	end
	if needLeiji then
		return isFriend and cardparse or "."
	end
	if isFriend then
		if not self:isFriend(use.from) then return cardparse end
		if self:isFriend(use.from) then
			if self:getDamagedEffects(use.from, self.player, true) or self:needToLoseHp(use.from, self.player, true, true) then
				return cardparse end
			if use.to:length() > 1 then return cardparse end
			if needDamaged then return "." end
			if not self:isWeak(use.from) then return cardparse end
		end
	end
	return "."
end
sgs.ai_nullification.EXCard_WWJZ = function(self, card, from, to, positive)
	if positive then
		if self:isFriend(to) then
			if self:needToLoseHp(to, from, true) or self:getDamagedEffects(to, from, true) then return end
			if self:isFriend(from) then
				if self:needToLoseHp(from, self.player, true) or self:getDamagedEffects(from, self.player, true) then return true end
				if not self:isWeak(from) and self:isWeak(to) then return true end
			else return true end
		end
	else
		if self:isEnemy(to) and self:isFriend(from) then return true end
	end
	return
end
sgs.ai_keep_value.EXCard_WWJZ = 4
sgs.ai_use_priority.EXCard_WWJZ = 0
sgs.ai_card_intention.EXCard_WWJZ = function(self, card, from, tos)
	local use = self.room:getTag("EXCard_WWJZ_data"):toCardUse()
	if type(use) == "userdata" then
		for _, to in sgs.qlist(use.to) do
			if to:hasSkill("leiji|nosleiji") then return end
		end
	end
	sgs.updateIntentions(from, tos, 20)
end

-----------------

sgs.weapon_range.EXCard_SJLRD = 3
sgs.ai_use_priority.EXCard_SJLRD = 5.673
function sgs.ai_weapon_value.EXCard_SJLRD(self, enemy, player)
	if not enemy then return 1 end
	if enemy and player:getHandcardNum() > 2 then return math.min(3.8, player:getHandcardNum() - 1) end
end
function sgs.ai_slash_weaponfilter.EXCard_SJLRD(self, to, player)
	if player:distanceTo(to) > math.max(sgs.weapon_range.EXCard_SJLRD, player:getAttackRange()) then return end
	return not player:hasWeapon("TH_Weapon_SpearTheGungnir") and getCardsNum("Jink", to, self.player) == 0
end
sgs.ai_skill_discard.EXCard_SJLRD_Skill = function(self, discard_num, min_num, optional, include_equip)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if type(damage) ~= "table" then return {} end
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getOtherPlayers(damage.to)) do
		if damage.to:distanceTo(p) == 1 then targets:append(p) end
	end
	if targets:isEmpty() then return {} end
	local id
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _, c in ipairs(cards) do
		if not self.player:isCardLimited(c, sgs.Card_MethodDiscard) then id = c:getEffectiveId() break end
	end
	if not id then return {} end
	for _, enemy in sgs.qlist(targets) do
		if self:damageIsEffective(enemy, nil, self.player) and not self:getDamagedEffects(enemy, self.player) and not self:needToLoseHp(enemy, self.player) then
			self.EXCard_SJLRD_target = enemy
			return id
		end
	end
	for _, friend in sgs.qlist(targets) do
		if self:damageIsEffective(friend, nil, self.player) and (self:getDamagedEffects(friend, self.player) or self:needToLoseHp(friend, self.player, nil, true)) then
			self.EXCard_SJLRD_target = friend
			return id
		end
	end
	return {}
end
sgs.ai_skill_playerchosen.EXCard_SJLRD_Skill = function(self, targets)
	if self.EXCard_SJLRD_target then return self.EXCard_SJLRD_target end
	for _, target in sgs.qlist(targets) do
		if self:isEnemy(target) and self:damageIsEffective(target, nil, self.player) and not self:getDamagedEffects(target, self.player)
			and not self:needToLoseHp(target, self.player) then
			return target
		end
	end
	for _, target in sgs.qlist(targets) do
		if self:isFriend(target) and self:damageIsEffective(target, nil, self.player)
			and (self:getDamagedEffects(target, self.player) or self:needToLoseHp(target, self.player, nil, true)) then
			return target
		end
	end
	return
end

-----------------------

sgs.weapon_range.EXCard_WLJ = 2
sgs.ai_use_priority.EXCard_WLJ = 5.673
function sgs.ai_weapon_value.EXCard_WLJ(self, enemy, player)
	if not self:slashIsAvailable(player) then return 5 end
	if #self:getFriends(player) > 0 then return 2.8 end
end

local EXCard_WLJ_Skill = {
	name = "EXCard_WLJ",
	getTurnUseCard = function(self, inclusive)
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(player) then
				if player:getMark("@EXCard_WLJ") == 0 then return sgs.Card_Parse("#EXCard_WLJ_SkillCARD:.:") end
			else
				if player:getMark("@EXCard_WLJ") > 0 then return sgs.Card_Parse("#EXCard_WLJ_SkillCARD:.:") end
			end
		end
	end
}
table.insert(sgs.ai_skills, EXCard_WLJ_Skill)
sgs.ai_skill_use_func["#EXCard_WLJ_SkillCARD"] = function(card, use, self)
	for _, friend in ipairs(self.friends) do
		use.card = card
		if use.to then use.to:append(friend) end
	end
end
sgs.ai_use_priority.EXCard_WLJ_SkillCARD = 10
sgs.ai_card_intention.EXCard_WLJ_SkillCARD = -10
------------------

sgs.weapon_range.EXCard_FLDF = 2
sgs.ai_use_priority.EXCard_FLDF = 5.400
function sgs.ai_weapon_value.EXCard_FLDF(self, enemy, player)
	if enemy and enemy:getHp() <= 1 and getCardsNum("Jink", enemy, self.player) == 0 then
		return 4.1
	end
end
function sgs.ai_slash_weaponfilter.EXCard_FLDF(self, to, player)
	if player:distanceTo(to) > math.max(sgs.weapon_range.EXCard_FLDF, player:getAttackRange()) then return end
	return getCardsNum("Peach", to, self.player) + getCardsNum("Jink", to, self.player) < 1
		and getCardsNum("Jink", to, self.player) == 0
end
sgs.ai_skill_invoke.EXCard_FLDF_revive = function(self, data)
	if not self.player:isLord() and self.player:getRole() == "renegade" then return false end
	return true
end
sgs.ai_skill_invoke.EXCard_FLDF = function(self, data)
	local use = data:toCardUse()
	for _, to in sgs.qlist(use.to) do
		local eff = self:doDisCard(to)
		return eff and self:isEnemy(to)
	end
	return
end

sgs.ai_choicemade_filter.skillInvoke.EXCard_FLDF = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
			if sb:hasFlag("EXCard_FLDF_Skill") then
			
					sgs.role_evaluation[sb:objectName()]["renegade"] = 0
					sgs.role_evaluation[sb:objectName()]["loyalist"] = 0
					local role, value = player:getRole(), 1000
					if role == "rebel" then role = "loyalist" value = -1000 end
					sgs.role_evaluation[sb:objectName()][role] = value
					sgs.ai_role[sb:objectName()] = player:getRole()
					self.room:setPlayerFlag(sb, "-EXCard_FLDF_Skill")
					self:updatePlayers()
				end
			end
	end
end


-------------------------------

sgs.ai_slash_prohibit.EXCard_TPYS = function(self, from, enemy, card)
	if enemy:hasArmorEffect("EXCard_TPYS") and card:isKindOf("NatureSlash") then return true end
	return
end
function sgs.ai_armor_value.EXCard_TPYS(player, self)
	if getCardsNum("Peach", player, player) + getCardsNum("Analeptic", player, player) == 0 then return 9 end
	return 3.5
end

EXCard_TPYS_damageeffect = function(self, to, nature, from)
	if to:hasArmorEffect("EXCard_TPYS") and nature ~= sgs.DamageStruct_Normal then return false end
	return true
end
table.insert(sgs.ai_damage_effect, EXCard_TPYS_damageeffect)

-------------------------------

function SmartAI:useCardEXCard_YYDL(card, use)
	use.card = card
	if use.to then use.to:append(self.player) end
	for _, player in ipairs(self.friends_noself) do
		if use.to and not player:hasSkill("manjuan") and not player:isKongcheng() then
			use.to:append(player)
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if use.to and enemy:hasSkill("manjuan") and not enemy:isKongcheng() then
			use.to:append(enemy)
		end
	end
	return
end
sgs.ai_use_priority.EXCard_YYDL = 2.8
sgs.ai_use_value.EXCard_YYDL = 4
sgs.ai_keep_value.EXCard_YYDL = 1
sgs.ai_card_intention.EXCard_YYDL = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		local intention = to:hasSkill("manjuan") and 10 or -10
		sgs.updateIntention(from, to, intention)
	end
end
sgs.ai_nullification.EXCard_YYDL = function(self, card, from, to, positive)
	if positive then
		if self:isEnemy(to) then
			if hasManjuanEffect(to) then return true end
			if to:isWounded() and to:hasArmorEffect("SilverLion") then return true end
			if self:getOverflow() > 0 and self:getCardsNum("Nullification") > 1 then return true end
		end
	else
		if self:isFriend(to) then
			if self:getOverflow() > 0 and self:getCardsNum("Nullification") > 1 then return true end
			if to:isWounded() and to:hasArmorEffect("SilverLion") then return true end
		end
	end
	return
end
-------------------------------

function SmartAI:useCardEXCard_YJJG(card, use)
	local friend = self:findPlayerToDraw()
	if friend then
		use.card = card
		if use.to then use.to:append(friend) end
		return
	elseif #self.friends_noself > 0 then
		self:sort(self.friends_noself)
		use.card = card
		if use.to then use.to:append(self.friends_noself[1]) end
		return
	else
		local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(players)
		use.card = card
		if use.to then use.to:append(players[1]) end
		return
	end
end
sgs.ai_use_priority.EXCard_YJJG = 9.28
sgs.ai_use_value.EXCard_YJJG = 9
sgs.ai_keep_value.EXCard_YJJG = 3.88
sgs.ai_card_intention.EXCard_YJJG = function(self, card, from, tos)
	if #self:getFriends(from) > 1 or tos[1]:isLord() then
		sgs.updateIntentions(from, tos, -10)
	end
end
sgs.ai_nullification.EXCard_YJJG = function(self, card, from, to, positive)
	if positive then
		if self:isEnemy(to) and self:isEnemy(from) then return true end
	else
		if self:isFriend(to) and self:isFriend(from) then return true end
	end
	return
end

-------------------------------

function SmartAI:useCardEXCard_ZJZB(card, use)
	self.EXCard_ZJZB_choice = nil
	if not isRolePredictable() and not isRolePredictable(true) then
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not self:isFriend(p) and not self:isEnemy(p) and not p:isLord() then
				use.card = card
				if use.to then use.to:append(p) end
				self.EXCard_ZJZB_choice = "ZJZB_showrole"
				return
			end
		end
		if sgs.playerRoles["rebel"] == 0 then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if not p:isLord() then
					use.card = card
					if use.to then use.to:append(p) end
					self.EXCard_ZJZB_choice = "ZJZB_showrole"
					return
				end
			end
		end
	end
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() - self:getKnownNum(enemy) > 1 then
			use.card = card
			if use.to then use.to:append(enemy) end
			self.EXCard_ZJZB_choice = "ZJZB_showhandcards"
			return
		end
	end
	use.card = card
	return
end
sgs.ai_skill_choice.EXCard_ZJZB = function(self, choices)
	if self.EXCard_ZJZB_choice then return self.EXCard_ZJZB_choice end
	return "ZJZB_showhandcards"
end
sgs.ai_use_priority.EXCard_ZJZB = 9.1
sgs.ai_use_value.EXCard_ZJZB = 5.4
sgs.ai_keep_value.EXCard_ZJZB = 3.33
sgs.ai_nullification.EXCard_ZJZB = function(self, card, from, to, positive)
	if positive then
		if self:isFriend(to) and not self:isFriend(from) and self.player:objectName() ~= from:objectName() and (self:getOverflow() > 0 and self:getCardsNum("Nullification") > 1) then return true end
	else
		if self:isEnemy(to) and (self:getOverflow() > 0 and self:getCardsNum("Nullification") > 1) then return true end
	end
	return
end

----------------------------

function SmartAI:useCardEXCard_DHLS(card, use)
	if #self.friends_noself > 0 then
		local nextp
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isEnemy(p) then nextp = p break end
		end
		if nextp then
			self:sort(self.friends_noself, "chaofeng")
			for _, friend in ipairs(self.friends_noself) do
				if self:playerGetRound(friend) > self:playerGetRound(nextp) then
					local range_fix = 1 + friend:getAttackRange() - nextp:getAttackRange()
					for _, enemy in ipairs(self.enemies) do
						if nextp:distanceTo(enemy) <= range_fix then
							use.card = card
							if use.to then use.to:append(friend) use.to:append(nextp) end
							sgs.ai_use_priority.EXCard_DHLS = 9
							return
						end
					end
				end
			end
			for _, friend in ipairs(self.friends_noself) do
				if self:playerGetRound(friend) > self:playerGetRound(nextp) and (getCardsNum("Weapon", friend, self.player) or friend:getHandcardNum() - friend:getKnownCard() >= 4) then
					use.card = card
					if use.to then use.to:append(friend) use.to:append(nextp) end
					sgs.ai_use_priority.EXCard_DHLS = 0
					return
				end
			end
		end
	end

	if self.player:aliveCount() <= 2 or #self.friends == 0 and sgs.turncount > 1 then
		use.card = card
		if use.to then use.to = sgs.SPlayerList() end
		return
	end
	local n = self:getOverflow()
	if n > 0 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		for i = 1, n do
			if cards[i]:getEffectiveId() == card:getEffectiveId() then
				use.card = card
				if use.to then use.to = sgs.SPlayerList() end
				return
			end
		end
	end
end

sgs.ai_use_priority.EXCard_DHLS = 0
sgs.ai_use_value.EXCard_DHLS = 8
sgs.ai_keep_value.EXCard_DHLS = 2
sgs.ai_nullification.EXCard_DHLS = function(self, card, from, to, positive)
	local targets = {}
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("EXCard_DHLS_target") then table.insert(targets, p) end
	end
	if #targets ~= 2 then return false end
	local t1, t2 = targets[1], targets[2]
	if positive then
		if self:isFriend(t1) and self:isFriend(t2) then
			return false
		elseif self:isFriend(t1) and self:playerGetRound(t1) < self:playerGetRound(t2) then
			return true
		elseif self:isFriend(t2) and self:playerGetRound(t2) < self:playerGetRound(t1) then
			return true
		end
	else
		if self:isFriend(t1) and self:isFriend(t2) then
			return false
		elseif self:isFriend(t1) and self:playerGetRound(t1) > self:playerGetRound(t2) then
			return true
		elseif self:isFriend(t2) and self:playerGetRound(t2) > self:playerGetRound(t1) then
			return true
		end
	end
	return
end

------------------------------------

function SmartAI:useCardEXCard_TJBZ(card, use)
	local good, bad = 0, 0
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if not hasManjuanEffect(player) and player:getHandcardNum() < 6 then
			local value = 6 - player:getHandcardNum()
			value = value + (self.player:aliveCount() - self:playerGetRound(player)) / 4
			if self:isFriend(player) then good = good + value
			else bad = bad + value
			end
		end
	end
	if good > bad then
		use.card = card
		return
	end
end

sgs.ai_use_priority.EXCard_TJBZ = 0
sgs.ai_keep_value.EXCard_TJBZ = 3.7
sgs.ai_nullification.EXCard_TJBZ = function(self, card, from, to, positive)
	if positive then
		if self:isEnemy(to) and 6 - to:getHandcardNum() >= 3 then return true end
	else
		if self:isFriend(to) and 6 - to:getHandcardNum() >= 3 then return true end
	end
	return
end