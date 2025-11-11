--皇威
sgs.ai_skill_playerchosen.ms_huangwei = function(self, targets)
	if #self.enemies == 0 then return nil end
	local ts = {}
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isNude() then table.insert(ts, enemy) end
	end
	if #ts > 0 then
		self:sort(ts, "defense")
		return ts[1]
	end
end


--縻谋
local ms_mimou_skill = {}
ms_mimou_skill.name = "ms_mimou"
table.insert(sgs.ai_skills, ms_mimou_skill)
ms_mimou_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#ms_mimou") then
		return sgs.Card_Parse("#ms_mimou:.:")
	end
end

sgs.ai_skill_use_func["#ms_mimou"] = function(card, use, self)
    if #self.enemies <= 0 and self.player:hasSkill("sy_canlue") then return nil end
    local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local target
	if self.player:hasSkill("sy_canlue") then
		self:sort(self.enemies, "hp")
		target = self.enemies[1]
		if target then
			local will_use
			if self:isEnemy(target) then
				for _, card in ipairs(cards) do
					if (not card:isKindOf("Peach")) and (not card:isKindOf("Analeptic")) and (not card:isKindOf("Nullification")) then
						will_use = card
						break
					end
				end
			end
			if will_use then
				use.card = sgs.Card_Parse("#ms_mimou:" .. will_use:getEffectiveId() .. ":")
				if use.to then use.to:append(target) end
			end
			return
		end
	else
		target = self.friends_noself[1]
		if target then
			local will_use
			if self:isFriend(target) then
				for _, card in ipairs(cards) do
					if (not card:isKindOf("Peach")) and (not card:isKindOf("Analeptic")) and (not card:isKindOf("Nullification")) then
						will_use = card
						break
					end
				end
			end
			if will_use then
				use.card = sgs.Card_Parse("#ms_mimou:" .. will_use:getEffectiveId() .. ":")
				if use.to then use.to:append(target) end
			end
			return
		end
	end
	if not target then
		self:sort(self.enemies, "hp")
		target = self.enemies[1]
		if target then
			local will_use
			if self:isEnemy(target) then
				for _, card in ipairs(cards) do
					if (not card:isKindOf("Peach")) and (not card:isKindOf("Analeptic")) and (not card:isKindOf("Nullification")) then
						will_use = card
						break
					end
				end
			end
			if will_use then
				use.card = sgs.Card_Parse("#ms_mimou:" .. will_use:getEffectiveId() .. ":")
				if use.to then use.to:append(target) end
			end
			return
		end
	end
end


sgs.ai_skill_choice["ms_mimou"] = function(self, choices, data)
    local simazhao = data:toPlayer()
	if not simazhao:hasSkill("sy_canlue") then
		if self:isFriend(simazhao) then return "selfdraw3" end
	end
	local chs = choices:split("+")
	return chs[math.random(1, #chs)]
end


sgs.ai_use_value["ms_mimou"] = 6
sgs.ai_use_priority["ms_mimou"] = 0


--杀威
sgs.ai_skill_invoke.ms_shawei = function(self, data)
	local use = data:toCardUse()
	if use.from then
		return self:isEnemy(use.from)
	end
end

--永恒
local ms_yongheng_skill = {}
ms_yongheng_skill.name = "ms_yongheng"
table.insert(sgs.ai_skills, ms_yongheng_skill)
ms_yongheng_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#ms_yonghengCard") then
		return sgs.Card_Parse("#ms_yonghengCard:.:")
	end
end

sgs.ai_skill_use_func["#ms_yonghengCard"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends, "hp")
	self.friends = sgs.reverse(self.friends)
	local target = nil
	for _, friend in ipairs(self.friends) do
		--if friend:isWounded() and friend:getHp() < 3 then		--隨機技能不限制
			target = friend
		--end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end


sgs.ai_use_priority["ms_yonghengCard"] = 10
sgs.ai_use_value["ms_yonghengCard"] = 10
sgs.ai_card_intention["ms_yonghengCard"] = -100

--乐动
sgs.ai_skill_invoke.ms_yuedong = true


--鬼谋（照着通天写就行了）
local ms_guimou_skill = {}
ms_guimou_skill.name = "ms_guimou"
table.insert(sgs.ai_skills, ms_guimou_skill)
ms_guimou_skill.getTurnUseCard = function(self, inclusive)
    if self.player:isKongcheng() then return nil end
	if self.player:getMark("@guimou") <= 0 then return nil end
	local suits = {}
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Spade then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Heart then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Club then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Diamond then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	if #suits > 3 then
	    return sgs.Card_Parse("#ms_guimou:.:")
	end
end

sgs.ai_skill_use_func["#ms_guimou"] = function(card, use, self)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards, false, true)
	local need_cards = {}
	local spade, club, heart, diamond
	for _, card in ipairs(cards) do
	    if card:getSuit() == sgs.Card_Spade then
		    if (not self.player:hasSkill("sy_renji")) and (not spade) then
			    spade = true
				table.insert(need_cards, card:getId())
			end
		elseif card:getSuit() == sgs.Card_Heart then
		    if (not self.player:hasSkill("sy_bolue")) and (not heart) then
			    heart = true
				table.insert(need_cards, card:getId())
			end
		elseif card:getSuit() == sgs.Card_Club then
		    if (not self.player:hasSkills("wansha|tongtian_wansha")) and (not club) then
			    club = true
				table.insert(need_cards, card:getId())
			end
		elseif card:getSuit() == sgs.Card_Diamond then
		    if (not self.player:hasSkill("sy_shisha")) and (not diamond) then
			    diamond = true
				table.insert(need_cards, card:getId())
			end
		end
	end
	if #need_cards < 4 then return nil end
	local tongtian_cards = sgs.Card_Parse("#ms_guimou:" .. table.concat(need_cards, "+") .. ":")
	assert(tongtian_cards)
	use.card = tongtian_cards
end


sgs.ai_use_value["ms_guimou"] = 10
sgs.ai_use_priority["ms_guimou"] = 9  --强行改动：没有四张花色，就打死不【通(gui)天(mou)】。