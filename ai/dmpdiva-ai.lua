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

--[[
sgs.ai_skill_invoke.se_nitian = function(self, data)
	if self.player:getHandcardNum() == 0 then return false end
	local judge = data:toJudge()
	if self:isFriend(judge.who) then return true end
	return false
end
]]

sgs.ai_skill_discard.se_nitian = function(self, discard_num, min_num, optional, include_equip)
	local data = self.room:getTag("se_nitian_judge")
	local judge = data:toJudge()
	if self.player:getHandcardNum() == 0 then return {} end
	if not judge.who:isWounded() then return {} end
	if judge.who:getLostHp() == 1 and judge.card:isRed() and judge.reason == "se_guwu" then return {} end
	if not self:isFriend(judge.who) then return {} end
	local to_discard = {}

	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	if cards[1]:isKindOf("Peach") then
		return {}
	end
	table.insert(to_discard, cards[1]:getEffectiveId())
	sgs.updateIntention(self.player, judge.who, -80)
	return to_discard
end

--sgs.ai_skill_choice.se_nitian = "se_nitian_gain"

sgs.ai_skill_choice["se_nitian"] = function(self, choices, data)
	local data = self.room:getTag("se_nitian_move")
	local move = data:toMoveOneTime()
	local lightonly = true
	for _, id in sgs.qlist(move.card_ids) do
		if sgs.Sanguosha:getCard(id):isKindOf("DelayedTrick") and not sgs.Sanguosha:getCard(id):isKindOf("Lightning") then
			lightonly = false
			break
		end
	end
	if lightonly then
		return "se_nitian_draw"
	end
	return "se_nitian_gain"
end

sgs.save_skill = sgs.save_skill .. "|se_guwu"

sgs.ai_skill_invoke.se_guwu = function(self, data)
	--local dying_data = data:toDying()
	local target = data:toPlayer()
	if self:isFriend(target) then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.se_guwu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end


--鸟神
se_zhifu_skill = {}
se_zhifu_skill.name = "se_zhifu"
table.insert(sgs.ai_skills, se_zhifu_skill)
se_zhifu_skill.getTurnUseCard          = function(self, inclusive)
	if self.player:isKongcheng() then return end
	for _, p in ipairs(self.friends) do
		if (p:getArmor() and p:getArmor():isKindOf("SilverLion") and p:isWounded()) or (p:getHp() == 1 and self.player:getHandcardNum() > 1) then
			return sgs.Card_Parse("#se_zhifucard:.:")
		end
	end
	if self:getCardsNum("BasicCard") + self:getCardsNum("Nullification") == self.player:getHandcardNum() and self.player:getHandcardNum() <= self.player:getHp() then return end
	local handcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(handcards)
	if handcards[1]:isKindOf("Peach") then return end
	for _, p in ipairs(self.friends) do
		if not p:getArmor() and p:isWounded() then
			return sgs.Card_Parse("#se_zhifucard:.:")
		end
	end
	return sgs.Card_Parse("#se_zhifucard:.:")
end

sgs.ai_skill_use_func["#se_zhifucard"] = function(card, use, self)
	local target
	local card


	if self.player:isKongcheng() then return end

	if not target then
		for _, p in ipairs(self.friends) do
			if (p:getArmor() and p:getArmor():isKindOf("SilverLion")) then
				target = p
				break
			end
		end
	end


	if not target then
		for _, p in ipairs(self.friends) do
			if p:getHp() == 1 and self.player:getHandcardNum() > 1 and not p:getArmor() then
				target = p
				break
			end
		end
	end

	if not target then
		for _, p in ipairs(self.friends) do
			if not p:getArmor() then
				target = p
				break
			end
		end
	end
	if not target then
		for _, p in ipairs(self.friends) do
			if self:hasSkills(sgs.lose_equip_skill, p) then
				target = p
				break
			end
		end
	end

	if not target then return end
	local handcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(handcards)

	if not handcards[1]:isKindOf("Peach") then
		card = handcards[1]
	end
	if card and target then
		use.card = sgs.Card_Parse("#se_zhifucard:" .. card:getEffectiveId() .. ":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["se_zhifucard"]       = 4
sgs.ai_use_priority["se_zhifucard"]    = 4
sgs.ai_card_intention["se_zhifucard"]  = -60

sgs.ai_skill_choice["se_zhifucard"]    = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	for i = 0, 10000 do
		local card = sgs.Sanguosha:getEngineCard(i)
		if card == nil then break end
		if card:isKindOf("Armor") and table.contains(items, card:objectName()) then
			if target then
				if self:isFriend(target) and self:evaluateArmor(card, target) > 3 and not (target:hasArmorEffect("silver_lion") and target:isWounded()) then
					return card:objectName()
				elseif self:isEnemy(target) and self:evaluateArmor(card, target) < -5 then
					return card:objectName()
				end
			end
		end
	end
	-- if table.contains(items, "silver_lion") then return "silver_lion" end
	if target and self:isFriend(target) and getBestHp(target) > target:getHp() and table.contains(items, "SilverLion") then
		return
		"SilverLion"
	end

	return items[math.random(1, #items)]
end

--妮可
se_nike_skill                          = {}
se_nike_skill.name                     = "se_nike"
table.insert(sgs.ai_skills, se_nike_skill)
se_nike_skill.getTurnUseCard          = function(self, inclusive)
	if self.player:isNude() then return end
	if self.player:hasUsed("#se_nikecard") then return end
	local hurtF = 0
	local notHurtE = 0
	if self.player:getHp() < self.player:getMaxHp() then return sgs.Card_Parse("#se_nikecard:.:") end
	for _, p in ipairs(self.friends_noself) do
		if p:getHp() < p:getMaxHp() then hurtF = hurtF + 1 end
	end
	for _, p in ipairs(self.enemies) do
		if p:getHp() == p:getMaxHp() and not p:isNude() then notHurtE = notHurtE + 1 end
	end
	if hurtF > 0 then return sgs.Card_Parse("#se_nikecard:.:") end
	if notHurtE > 0 then return sgs.Card_Parse("#se_nikecard:.:") end
	return
end

sgs.ai_skill_use_func["#se_nikecard"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	local numMax = (self.player:getHandcardNum() + self.player:getEquips():length()) * 2

	local notHurtE = 0
	for _, p in ipairs(self.enemies) do
		if p:getHp() == p:getMaxHp() then notHurtE = notHurtE + 1 end
	end
	if notHurtE > 2 then
		notHurtE = 0
		for _, p in ipairs(self.enemies) do
			if p:getHp() == p:getMaxHp() then notHurtE = notHurtE + 1 end
			if p:getHp() == p:getMaxHp() and notHurtE <= numMax then targets:append(p) end
		end
	else
		local hurtF = 0
		for _, p in ipairs(self.friends_noself) do
			if p:getHp() < p:getMaxHp() then hurtF = hurtF + 1 end
			if p:getHp() < p:getMaxHp() and hurtF <= 2 then targets:append(p) end
		end
		if hurtF < 2 then
			for _, p in ipairs(self.enemies) do
				if p:getHp() == p:getMaxHp() then hurtF = hurtF + 1 end
				if p:getHp() == p:getMaxHp() and hurtF <= 2 then targets:append(p) end
			end
		end
	end

	if targets:length() == 0 then
		notHurtE = 0
		for _, p in ipairs(self.enemies) do
			if p:getHp() == p:getMaxHp() then notHurtE = notHurtE + 1 end
			if p:getHp() == p:getMaxHp() and notHurtE <= numMax then targets:append(p) end
		end
		if notHurtE == 2 then
			for _, p in ipairs(self.enemies) do
				if p:getHp() < p:getMaxHp() and not self:hasSkills(sgs.masochism_skill, p) then
					targets:append(p)
					break
				end
			end
		end
	end

	if targets:length() == 0 then return end

	if targets:length() > 0 then
		use.card = sgs.Card_Parse("#se_nikecard:.:")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_value["se_nikecard"]       = 8
sgs.ai_use_priority["se_nikecard"]    = 0.4

--
sgs.ai_skill_choice.se_yanyi          = function(self, choices, data)
	local choice_table = choices:split("+")
	for _, choice in ipairs(choice_table) do
		if choice == "LLJ_reality" or choice == "shouji" or choice == "LuaLiansuo" or choice == "LuaLuoshen" or choice == "SE_Lingshang" or choice == "SE_Guanli" or choice == "SE_Nagong" or choice == "SE_Weigong" or choice == "se_zhuren" or choice == "Yuyue" or choice == "Yingbi" or choice == "se_qiangjing" then
			return "se_yanyi"
		end
	end
	for _, choice in ipairs(choice_table) do
		if choice ~= "se_yanyi" and choice ~= "se_nike" then return choice end
	end
	return "se_yanyi"
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|se_nike"