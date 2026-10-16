-- Fixed dmpdiva-ai.lua policy. Source bugs and first-result ordering are retained.
-- Only scoped disclosed question data and current native-issued skill authority are consumed.

local function context(self,key)
    local data=self:getDecisionContext()
    local row=type(data.dmpdiva)=="table" and data.dmpdiva[key]
    if row==nil then ai_unsupported("Dmpdiva question data missing: "..key,"dmpdiva") end
    return row
end
local function nitian_judge(self)
    local row=context(self,"nitian_judge")
    if type(row)~="table" or type(row.who)~="string" or type(row.card)~="table" or type(row.reason)~="string" then
        ai_unsupported("Nitian judgement data malformed","se_nitian")
    end
    local who=self.room:findPlayerByObjectName(row.who)
    if not who then ai_unsupported("Nitian judged player missing","se_nitian") end
    return {who=who,card=CardView.new(row.card),reason=row.reason}
end

sgs.ai_skill_discard.se_nitian = function(self, discard_num, min_num, optional, include_equip)
	local judge = nitian_judge(self)
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
	table.insert(to_discard, cards[1]:getKnownEffectiveId())
	self:updateIntention(self.player, judge.who, -80)
	return to_discard
end

--sgs.ai_skill_choice.se_nitian = "se_nitian_gain"

sgs.ai_skill_choice["se_nitian"] = function(self, choices, data)
	local cards = context(self, "nitian_move_cards")
	if not AIValue.isList(cards) then ai_unsupported("Nitian discarded faces are unavailable", "se_nitian") end
	local lightonly = true
	for _, face in ipairs(cards) do
        local card = CardView.new(face)
		if card:isKindOf("DelayedTrick") and not card:isKindOf("Lightning") then
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
		if target then self:updateIntention(player,target,-50) end
	end
end


--鸟神
sgs.ai_fill_skill.se_zhifu = function(self, inclusive, request)
	if self.player:isKongcheng() then return end
	for _, p in ipairs(self.friends) do
		if (p:getArmor() and p:getArmor():isKindOf("SilverLion") and p:isWounded()) or (p:getHp() == 1 and self.player:getHandcardNum() > 1) then
			return self:legacySkillSeed("se_zhifu", "#se_zhifucard", request)
		end
	end
	if self:getCardsNum("BasicCard") + self:getCardsNum("Nullification") == self.player:getHandcardNum() and self.player:getHandcardNum() <= self.player:getHp() then return end
	local handcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(handcards)
	if handcards[1]:isKindOf("Peach") then return end
	for _, p in ipairs(self.friends) do
		if not p:getArmor() and p:isWounded() then
			return self:legacySkillSeed("se_zhifu", "#se_zhifucard", request)
		end
	end
	return self:legacySkillSeed("se_zhifu", "#se_zhifucard", request)
end

sgs.ai_skill_use_func["#se_zhifucard"] = function(card, use, self, request)
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
		use.card = self:bindSkillCard("se_zhifu", {card:getKnownEffectiveId()}, request, nil, "#se_zhifucard")
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
	local catalog = context(self, "armor_catalog")
    if not AIValue.isList(catalog) then ai_unsupported("ordered printed armor catalog is unavailable", "se_zhifucard") end
    for _, face in ipairs(catalog) do
        local card = CardView.new(face)
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
sgs.ai_fill_skill.se_nike = function(self, inclusive, request)
	if self.player:isNude() then return end
	if self.player:getStrategyHasUsed("#se_nikecard") then return end
	local hurtF = 0
	local notHurtE = 0
	if self.player:getHp() < self.player:getMaxHp() then return self:legacySkillSeed("se_nike", "#se_nikecard", request) end
	for _, p in ipairs(self.friends_noself) do
		if p:getHp() < p:getMaxHp() then hurtF = hurtF + 1 end
	end
	for _, p in ipairs(self.enemies) do
		if p:getHp() == p:getMaxHp() and not p:isNude() then notHurtE = notHurtE + 1 end
	end
	if hurtF > 0 then return self:legacySkillSeed("se_nike", "#se_nikecard", request) end
	if notHurtE > 0 then return self:legacySkillSeed("se_nike", "#se_nikecard", request) end
	return
end

sgs.ai_skill_use_func["#se_nikecard"] = function(card, use, self, request)
	local targets = AIList.new({})
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
		use.card = self:bindSkillCard("se_nike", {}, request, nil, "#se_nikecard")
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
