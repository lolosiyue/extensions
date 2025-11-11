--装备
local function isEquip(name, player)
	for _, e in sgs.qlist(player:getEquips()) do
		if e:isKindOf(name) then
			return true
		end
	end
	return false
end

--获取场上最——角色
local function mostPlayer(self, isFriend, kind)
	local num = 0
	local target
	if kind == 1 then --手牌最少
		num = 100
		if isFriend then
			for _, p in ipairs(self.friends) do
				if p:getHandcardNum() < num then
					target = p
					num = p:getHandcardNum()
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if p:getHandcardNum() < num then
					target = p
					num = p:getHandcardNum()
				end
			end
			if not target then target = self.enemies[1] end
		end
	elseif kind == 2 then --手牌最多
		num = 0
		if isFriend then
			for _, p in ipairs(self.friends) do
				if p:getHandcardNum() > num then
					target = p
					num = p:getHandcardNum()
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if p:getHandcardNum() > num then
					target = p
					num = p:getHandcardNum()
				end
			end
			if not target then target = self.enemies[1] end
		end
	elseif kind == 3 then --体力最小
		num = 100
		if isFriend then
			for _, p in ipairs(self.friends) do
				if p:getHp() < num then
					target = p
					num = p:getHp()
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if p:getHp() < num then
					target = p
					num = p:getHp()
				end
			end
			if not target then target = self.enemies[1] end
		end
	elseif kind == 4 then --体力最大
		num = 0
		if isFriend then
			for _, p in ipairs(self.friends) do
				if p:getHp() > num then
					target = p
					num = p:getHp()
				end
			end
			if not target then target = self.friends[1] end
		else
			for _, p in ipairs(self.enemies) do
				if p:getHp() > num then
					target = p
					num = p:getHp()
				end
			end
			if not target then target = self.enemies[1] end
		end
	end
	if target then return target end
	return nil
end

sgs.ai_choicemade_filter.cardChosen.se_mingqie = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_invoke.se_mingqie = function(self, data)
	local use = data:toCardUse()
	if self:isEnemy(use.to:at(0)) and not use.to:at(0):hasSkills(sgs.lose_equip_skill) then return true end
	if self:isFriend(use.to:at(0)) and use.to:at(0):hasSkills(sgs.lose_equip_skill) then return true end
	return false
end

sgs.ai_cardneed.se_mingqie = function(to, card, self)
	return card:isKindOf("Dismantlement") or card:isKindOf("Snatch")
end




se_mopao_skill = {}
se_mopao_skill.name = "se_mopao"
table.insert(sgs.ai_skills, se_mopao_skill)
se_mopao_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#se_mopaocard") then return end
	if #self.enemies < 1 then return end
	if self.player:getMark("@p_point") < 4 then return end
	for _, enemy in ipairs(self.enemies) do
		if enemy then
			if enemy:getEquips():length() < 2 and not self:cantDamageMore(self.player, enemy) then
				return sgs.Card_Parse("#se_mopaocard:.:")
			end
		end
	end
	return
end

sgs.se_mopaoDir = "left"
sgs.ai_skill_use_func["#se_mopaocard"] = function(card, use, self)
	local target
	self:updatePlayers()
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantDamageMore(self.player, enemy) then
			target = enemy
			break
		end
	end
	if not target then return end

	local next_man = self.player:getNextAlive()
	local friend_enemy = 0
	while (next_man:objectName() ~= target:objectName()) do
		if self:isFriend(next_man) and self:damageIsEffective(next_man, sgs.DamageStruct_Normal) then
			friend_enemy = friend_enemy + 1
		elseif self:isEnemy(next_man) and self:damageIsEffective(next_man, sgs.DamageStruct_Normal) then
			friend_enemy = friend_enemy - 1
		end
		next_man = next_man:getNextAlive()
	end
	if friend_enemy < 0 then
		sgs.se_mopaoDir = "right"
	else
		sgs.se_mopaoDir = "left"
	end
	if target then
		use.card = sgs.Card_Parse("#se_mopaocard:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_choice["se_mopaocard"] = function(self, choices)
	return sgs.se_mopaoDir
end



sgs.ai_use_value["se_mopaocard"]      = 8
sgs.ai_use_priority["se_mopaocard"]   = 2
sgs.ai_card_intention["se_mopaocard"] = 100



sgs.ai_skill_playerchosen.se_wuyi_losehp = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not hasZhaxiangEffect(p) then
			return p
		end
	end
	return targets[1]
end


sgs.ai_playerchosen_intention.se_wuyi_losehp = 40

sgs.ai_skill_playerchosen.se_wuyi_draw = function(self, targets)
	local n = self.player:getMark("se_wuyi-draw")
	return self:findPlayerToDraw(true, n) --mostPlayer(self, true, 1)
end

sgs.ai_playerchosen_intention.se_wuyi_draw = -40

sgs.ai_skill_playerchosen.se_wuyi_recover = function(self, targets)
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


	return target --mostPlayer(self, true, 3)
end


sgs.ai_playerchosen_intention.se_wuyi_recover = -40

--小五
se_kuixin_skill = {}
se_kuixin_skill.name = "se_kuixin"
table.insert(sgs.ai_skills, se_kuixin_skill)
se_kuixin_skill.getTurnUseCard = function(self, inclusive)
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:distanceTo(p) == 1 and not p:hasFlag("se_kuixin_used") and p:getHandcardNum() > 0 then
			if math.random(1, 5) > 1 then
				return sgs.Card_Parse("#se_kuixincard:.:")
			end
		end
	end
	return
end
sgs.ai_skill_use_func["#se_kuixincard"] = function(card, use, self)
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:distanceTo(p) == 1 and not p:hasFlag("se_kuixin_used") and p:getHandcardNum() > 0 then
			use.card = card
			if use.to then use.to:append(p) end
			return
		end
	end
end

sgs.ai_use_value["se_kuixincard"] = 5
sgs.ai_use_priority["se_kuixincard"] = 10

sgs.ai_skill_askforag["se_huixiang"] = function(self, card_ids)
	if self.player:getJudgingArea():length() > 0 then
		local hasNull = false
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Nullification") then hasNull = true end
		end
		if not hasNull then
			for _, card_id in ipairs(card_ids) do
				if sgs.Sanguosha:getCard(card_id):isKindOf("Nullification") then return card_id end
			end
		end
	end
	if self:isWeak() then
		for _, card_id in ipairs(card_ids) do
			if sgs.Sanguosha:getCard(card_id):isKindOf("Peach") then return card_id end
		end
	end
	local weakF = 0
	for _, p in ipairs(self.friends) do
		if self:isWeak(p) then
			weakF = weakF + 1
		end
	end
	for _, card_id in ipairs(card_ids) do
		if sgs.Sanguosha:getCard(card_id):isKindOf("ExNihilo") then return card_id end
	end
	if weakF > 1 then
		for _, card_id in ipairs(card_ids) do
			if sgs.Sanguosha:getCard(card_id):isKindOf("GodSalvation") then return card_id end
		end
	end
	if #self.enemies - #self.friends > 1 then
		for _, card_id in ipairs(card_ids) do
			if sgs.Sanguosha:getCard(card_id):isKindOf("AOE") then return card_id end
		end
	end
	return
end


sgs.ai_skill_use["@@se_huixiang"] = function(self, prompt, method)
	local cards = {}
	if self.player:getPile("satori_memory"):length() < 1 then return "." end
	for _, id in sgs.qlist(self.player:getPile("satori_memory")) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(cards)
	--local card_str = string.format("#LuaMeilingCard:%d:->%s", card:getId(), target:objectName())
	local give_all_cards = {}
	local max = math.ceil(self.player:getHp() / 2)
	for _, c in ipairs(cards) do
		if #give_all_cards < max then
			table.insert(give_all_cards, c:getEffectiveId())
		end
	end
	local card_str = string.format("#se_huixiang:%s:", table.concat(give_all_cards, "+"))
	--local card_str = "#se_huixiang:"..cardx:getId()..":"
	return card_str
end


--fuzhi

--[[
sgs.se_fuzhi_target_objectName = ""
sgs.ai_skill_invoke.se_fuzhi = function(self, data)
	local lieges = self.room:getLieges("touhou", self.player)
	if lieges:length() == 0 then return end
	for _,p in sgs.qlist(lieges) do
		if self:isFriend(p) and not p:hasSkill("se_wushi") then
			if self:isWeak(p) and self.player:getHandcardNum() > self.player:getHp() then
				sgs.se_fuzhi_target_objectName = p:objectName()
				return true
			end
			if p:getHandcardNum() > p:getHp() then
				sgs.se_fuzhi_target_objectName = p:objectName()
				return true
			end
		end
	end
	return false
end]]
--[[
sgs.ai_skill_playerchosen.se_fuzhi = function(self, targets)
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:objectName() == sgs.se_fuzhi_target_objectName then return p end
	end
	local lieges = self.room:getLieges("touhou", self.player)
	for _,p in sgs.qlist(lieges) do
		if self:isFriend(p) and not p:hasSkill("se_wushi") then
			if self:isWeak(p) and self.player:getHandcardNum() > self.player:getHp() then
				return p
			end
			if p:getHandcardNum() > p:getHp() then
				return p
			end
		end
	end
end
]]

sgs.ai_skill_playerchosen.se_fuzhi = function(self, targets)
	if (sgs.ai_skill_invoke.fangquan(self)) then
		local AssistTarget = self:AssistTarget()
		if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and not hasManjuanEffect(AssistTarget) and AssistTarget:getKingdom() == "touhou" then
			return AssistTarget
		end
		for _, friend in ipairs(self.friends_noself) do
			if not hasManjuanEffect(friend) and friend:hasSkills(sgs.cardneed_skill) and friend:getKingdom() == "touhou" then
				return friend
			end
		end

		self:sort(self.friends_noself, "chaofeng")
		for _, friend in ipairs(self.friends_noself) do
			if not hasManjuanEffect(friend) and friend:getKingdom() == "touhou" then
				return friend
			end
		end
		--return self.friends_noself[1]
	end
	return nil
end

sgs.ai_playerchosen_intention.se_fuzhi = -80


sgs.ai_skill_discard["se_fuzhi"] = function(self, discard_num, min_num, optional, include_equip)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, true)
	local x = self.player:getHandcardNum() - self.player:getHp()
	local cards = {}
	for _, c in ipairs(handcards) do
		if #cards < x then
			table.insert(cards, c:getEffectiveId())
		end
	end
	if #cards > 0 then
		return cards
	end
	return {}
end
