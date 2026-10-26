-- Fixed excard2014 source; incompatibilities are not repaired by substitution.
local known = AIValue.requireKnown

local function ex_context(self)
 local c=self:getDecisionContext().excard2014
 if type(c)~="table"then ai_unsupported("EXCard scoped context missing","excard2014")end;return c
end
local function wwjz_use(self)
 local row=known(ex_context(self).wwjz_use,"EXCard_WWJZ_data")
 if row==false then return{to=AIList.new({})}end
 if type(row)~="table"or not AIValue.isList(row.to)then ai_unsupported("invalid WWJZ CardUse","EXCard_WWJZ")end
 local use={to=AIList.new({})};if row.from and row.from~=""then use.from=known(self.room:findPlayerByObjectName(row.from),"WWJZ source")end
 for _,name in ipairs(row.to)do use.to:append(known(self.room:findPlayerByObjectName(name),"WWJZ target"))end
 if row.card then use.card=CardView.new(row.card)end;return use
end
local function dhls_target(self,p)
 local names=ex_context(self).dhls_targets
 if not AIValue.isList(names)then ai_unsupported("exact DHLS target flags missing","EXCard_DHLS")end
 for _,name in ipairs(names)do if name==p:objectName()then return true end end;return false
end
local function set_choice(self,value)
 self.EXCard_ZJZB_choice=value;self:setStrategyMemory("excard2014.zjzb_choice",value or false)
end
local function get_choice(self)
 if self.EXCard_ZJZB_choice then return self.EXCard_ZJZB_choice end
 local value,present=self:getStrategyMemory("excard2014.zjzb_choice")
 if not present or value==false then return nil end
 if value~="ZJZB_showrole"and value~="ZJZB_showhandcards"then ai_unsupported("invalid prior ZJZB choice","EXCard_ZJZB")end;return value
end
if not sgs.ai_nullification then
	sgs.ai_nullification = {}
end

function SmartAIView:useCardEXCard_WWJZ(card, use)
	if self.room:alivePlayerCount() <= 2 or #self.friends == 0 and self.room:getTurnCount() > 1 then
		use.card = card
		if use.to then use.to = sgs.SPlayerList() end
		return
	end
	local n = self:getOverflow()
	if n > 0 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		for i = 1, n do
			if cards[i]:getEffectiveId() == card:getKnownEffectiveId() then
				use.card = card
				if use.to then use.to = sgs.SPlayerList() end
				return
			end
		end
	end
end
ai_skill_use.EXCard_WWJZ = function(self, prompt, request)
	local method = request and request.handling_method
	local use = wwjz_use(self)
	if not use or not use.from then return "." end
	local id = self:getCardId("EXCard_WWJZ")
	if not id then return "." end
	local slash = self:getEvaluationCard("slash")
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
	local use = wwjz_use(self)
	if use then
		for _, to in sgs.qlist(use.to) do
			if to:hasSkill("leiji|nosleiji") then return end
		end
	end
	for _,to in ipairs(tos)do self:updateIntention(from,to,20)end
end


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
-- QVariant:toDamage() returns SWIG userdata in the fixed engine. The donor
-- explicitly requires a Lua table, so its discard body is unreachable.
-- Do not execute that body merely because the isolated DTO is a Lua table.
sgs.ai_skill_discard.EXCard_SJLRD_Skill=function(self,discard_num,min_num,optional,include_equip)return {}end
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


sgs.weapon_range.EXCard_WLJ = 2
sgs.ai_use_priority.EXCard_WLJ = 5.673
function sgs.ai_weapon_value.EXCard_WLJ(self, enemy, player)
	if not self:slashIsAvailable(player) then return 5 end
	if #self:getFriends(player) > 0 then return 2.8 end
end

ai_fill_skill.EXCard_WLJ=function(self, options, request)
    local inclusive = options and options.inclusive

		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(player) then
				if player:getStrategyMark("@EXCard_WLJ") == 0 then return self:legacySkillSeed("EXCard_WLJ", "#EXCard_WLJ_SkillCARD", request) end
			else
				if player:getStrategyMark("@EXCard_WLJ") > 0 then return self:legacySkillSeed("EXCard_WLJ", "#EXCard_WLJ_SkillCARD", request) end
			end
		end
end
ai_card_use["#EXCard_WLJ_SkillCARD"] = function(self, card, use, request)
	for _, friend in ipairs(self.friends) do
		if not use.card then
            local bound=self:bindSkillCard("EXCard_WLJ", {}, request, nil, "#EXCard_WLJ_SkillCARD")
            use.card=self:inheritLegacyCardIdentity(bound, card)
        end
		if use.to then use.to:append(friend) end
	end
end
sgs.ai_use_priority.EXCard_WLJ_SkillCARD = 10
sgs.ai_card_intention.EXCard_WLJ_SkillCARD = -10

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
ai_skill_invoke.EXCard_FLDF_revive = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if not self.player:isLord() and self.player:getKnownRole() == "renegade" then return (false) or false end
	return (true) or false
end
ai_skill_invoke.EXCard_FLDF = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	for _, to in sgs.qlist(use.to) do
		local eff = self:doDisCard(to)
		return (eff and self:isEnemy(to)) or false
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.EXCard_FLDF=function(self,player,promptlist)
    if promptlist[#promptlist]~="yes"then return end
    local names=ex_context(self).fldf_flagged_names
    if not AIValue.isList(names)then ai_unsupported("exact FLDF scoped flag witness missing","EXCard_FLDF")end
    -- Fixed producer raises EXCard_FLDF_revive while this flag exists, not
    -- EXCard_FLDF. Its ordinary source callback therefore sees no such target.
    -- Nonempty injected/extension states need the legacy role-write transaction;
    -- do not silently replace it with intention or mutate shared role globals.
    if #names>0 then ai_unsupported("FLDF legacy role_evaluation write transaction unavailable","EXCard_FLDF")end
end


sgs.ai_slash_prohibit.EXCard_TPYS = function(self, from, enemy, card)
	if enemy:hasArmorEffect("EXCard_TPYS") and card:isKindOf("NatureSlash") then return true end
	return
end
function sgs.ai_armor_value.EXCard_TPYS(player, self)
	if getCardsNum("Peach", player, player) + getCardsNum("Analeptic", player, player) == 0 then return 9 end
	return 3.5
end

sgs.ai_ajustdamage_to.EXCard_TPYS = function(self,from,to,card,nature)
	if nature~="N" and not known(IgnoreArmor(from,to),"IgnoreArmor")
	then return -99 end
end


function SmartAIView:useCardEXCard_YYDL(card, use)
    local recommend = self:targetRecommendScorer(card)
	if recommend(self.player, 0) == nil then return end
	use.card = card
	if use.to then use.to:append(self.player) end
	for _, player in ipairs(self:orderTargetsByRecommend(self.friends_noself, recommend)) do
		if use.to and not player:hasSkill("manjuan") and not player:isKongcheng() then
			use.to:append(player)
		end
	end
	for _, enemy in ipairs(self:orderTargetsByRecommend(self.enemies, recommend)) do
		if use.to and enemy:hasSkill("manjuan") and not enemy:isKongcheng() then
			use.to:append(enemy)
		end
	end
	return
end
sgs.registerSkillCardType("EXCard_YYDL", "draw")
sgs.ai_use_priority.EXCard_YYDL = 2.8
sgs.ai_use_value.EXCard_YYDL = 4
sgs.ai_keep_value.EXCard_YYDL = 1
sgs.ai_card_intention.EXCard_YYDL = function(self, card, from, tos)
	for _, to in ipairs(tos) do
		local intention = to:hasSkill("manjuan") and 10 or -10
		self:updateIntention(from,to,intention)
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

function SmartAIView:useCardEXCard_YJJG(card, use)
    local recommend = self:targetRecommendScorer(card)
	local friend = self:findPlayerToDraw()
	if friend and recommend(friend, 0) ~= nil then
		use.card = card
		if use.to then use.to:append(friend) end
		return
	elseif #self.friends_noself > 0 then
		self:sort(self.friends_noself)
		local candidates = self:orderTargetsByRecommend(self.friends_noself, recommend)
		if #candidates == 0 then return end
		use.card = card
		if use.to then use.to:append(candidates[1]) end
		return
	else
		local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(players)
		players = self:orderTargetsByRecommend(players, recommend)
		if #players == 0 then return end
		use.card = card
		if use.to then use.to:append(players[1]) end
		return
	end
end
sgs.registerSkillCardType("EXCard_YJJG", "draw")
sgs.ai_use_priority.EXCard_YJJG = 9.28
sgs.ai_use_value.EXCard_YJJG = 9
sgs.ai_keep_value.EXCard_YJJG = 3.88
sgs.ai_card_intention.EXCard_YJJG = function(self, card, from, tos)
	if #self:getFriends(from) > 1 or tos[1]:isLord() then
		for _,to in ipairs(tos)do self:updateIntention(from,to,-10)end
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


function SmartAIView:useCardEXCard_ZJZB(card, use)
    local recommend = self:targetRecommendScorer(card)
	set_choice(self,nil)
	if not self:isRolePredictable() and not self:isRolePredictable(true) then
		for _, p in sgs.qlist(self:orderTargetsByRecommend(self.room:getOtherPlayers(self.player), recommend)) do
			if not self:isFriend(p) and not self:isEnemy(p) and not p:isLord() then
				use.card = card
				if use.to then use.to:append(p) end
				set_choice(self,"ZJZB_showrole")
				return
			end
		end
		if self:getRoleCountValue("rebel") == 0 then
			for _, p in sgs.qlist(self:orderTargetsByRecommend(self.room:getOtherPlayers(self.player), recommend)) do
				if not p:isLord() then
					use.card = card
					if use.to then use.to:append(p) end
					set_choice(self,"ZJZB_showrole")
					return
				end
			end
		end
	end
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self:orderTargetsByRecommend(self.enemies, recommend)) do
		if enemy:getHandcardNum() - self:getKnownNum(enemy) > 1 then
			use.card = card
			if use.to then use.to:append(enemy) end
			set_choice(self,"ZJZB_showhandcards")
			return
		end
	end
	use.card = card
	return
end
sgs.registerSkillCardType("EXCard_ZJZB", "debuff")
ai_skill_choice.EXCard_ZJZB = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil

	local choice=get_choice(self);if choice then return ai_choice_result((choice), options) end
	return ai_choice_result(("ZJZB_showhandcards"), options)
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


function SmartAIView:useCardEXCard_DHLS(card, use)
    local recommend = self:targetRecommendScorer(card)
	if #self.friends_noself > 0 then
		local nextp
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isEnemy(p) then nextp = p break end
		end
		if nextp and recommend(nextp, 0) ~= nil then
			self:sort(self.friends_noself, "chaofeng")
			for _, friend in ipairs(self:orderTargetsByRecommend(self.friends_noself, recommend)) do
				if self:playerGetRound(friend) > self:playerGetRound(nextp) then
					local range_fix = 1 + friend:getAttackRange() - nextp:getAttackRange()
					for _, enemy in ipairs(self.enemies) do
						if nextp:distanceTo(enemy) <= range_fix then
							use.card = card
							if use.to then use.to:append(friend) use.to:append(nextp) end
							self:setPriorityValue("EXCard_DHLS",9,"EXCard_DHLS")
							return
						end
					end
				end
			end
			for _, friend in ipairs(self:orderTargetsByRecommend(self.friends_noself, recommend)) do
				if self:playerGetRound(friend) > self:playerGetRound(nextp) and (getCardsNum("Weapon", friend, self.player) or friend:getHandcardNum() - friend:getKnownCard() >= 4) then
					use.card = card
					if use.to then use.to:append(friend) use.to:append(nextp) end
					self:setPriorityValue("EXCard_DHLS",0,"EXCard_DHLS")
					return
				end
			end
		end
	end

	if self.room:alivePlayerCount() <= 2 or #self.friends == 0 and self.room:getTurnCount() > 1 then
		use.card = card
		if use.to then use.to = sgs.SPlayerList() end
		return
	end
	local n = self:getOverflow()
	if n > 0 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		for i = 1, n do
			if cards[i]:getEffectiveId() == card:getKnownEffectiveId() then
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
		if dhls_target(self,p) then table.insert(targets, p) end
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


function SmartAIView:useCardEXCard_TJBZ(card, use)
	local good, bad = 0, 0
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if not hasManjuanEffect(player) and player:getHandcardNum() < 6 then
			local value = 6 - player:getHandcardNum()
			value = value + (self.room:alivePlayerCount() - self:playerGetRound(player)) / 4
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
