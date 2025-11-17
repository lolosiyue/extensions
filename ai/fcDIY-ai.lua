--DIY扩展包武将AI

--1 神貂蝉-自改版
  --“魅魂”AI
sgs.ai_skill_invoke.f_meihun = true

sgs.ai_skill_playerchosen.f_meihun = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and not p:isAllNude() then
		    return p 
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.f_meihun = 50

sgs.ai_skill_cardask["@f_meihun-suit"] = function(self,data, pattern)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
		then return h:getEffectiveId() end
		if h:getSuitString() == pattern:split("|")[2]
		then return h:getEffectiveId() end
	end
	return self:getCardId(pattern)
end
local f_huoxin_skill = {
	name = "f_huoxin",
	getTurnUseCard = function(self, inclusive)
		if self.player:hasUsed("#f_huoxinCard") then return end
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
			return sgs.Card_Parse("#f_huoxinCard:.:")
		end
	end,
}
table.insert(sgs.ai_skills, f_huoxin_skill) --加入AI可用技能表
sgs.ai_skill_use_func["#f_huoxinCard"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("he"))
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	if #handcards == 0 then return end
	self:sortByUseValue(handcards, true) --对可用手牌按使用价值从小到大排序
	local slasher, target
	self:sort(self.enemies, "defense")
	for _, enemy_a in ipairs(self.enemies) do
		for _, enemy_b in ipairs(self.enemies) do
			if enemy_b:canPindian(enemy_a) and enemy_a:objectName() ~= enemy_b:objectName() and enemy_a:getMark("&f_meihuo") > 0  then
				slasher = enemy_b
				target = enemy_a
				break
			end
		end
	end
	if not slasher then
		for _, enemy_a in ipairs(self.enemies) do
			for _, enemy_b in ipairs(self.enemies) do
				if enemy_b:canPindian(enemy_a) and enemy_a:objectName() ~= enemy_b:objectName() then
					slasher = enemy_b
					target = enemy_a
					break
				end
			end
		end
	end

	if slasher and target then
		for _, c in ipairs(handcards) do
			for _, c2 in ipairs(handcards) do
				if c:getEffectiveId() ~= c2:getEffectiveId() and c:getSuit() == c2:getSuit() then
					local card_str = string.format("#f_huoxinCard:%s+%s:", c:getEffectiveId(), c2:getEffectiveId())
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					if use.to then
						use.to:append(slasher)
						use.to:append(target)
						return
					end
				end
			end
		end
	end
end
sgs.ai_playerchosen_intention["f_huoxinCard"] = 80
sgs.ai_use_priority["f_huoxinCard"] = 2.3

sgs.ai_skill_use["@@f_huoxin!"] = function(self,prompt)
	local min = 999
	if self.player:getPile("f_huoxinPindianCard"):length() > 1 then
		for _, id in sgs.qlist(self.player:getPile("f_huoxinPindianCard")) do
			if sgs.Sanguosha:getCard(id):getNumber() < min then
				min = sgs.Sanguosha:getCard(id):getNumber()
			end
		end
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:hasFlag("f_huoxin_pindiantargets") and p:getMark("&f_meihuo") > 0 then
				for _, id in sgs.qlist(self.player:getPile("f_huoxinPindianCard")) do
					if sgs.Sanguosha:getCard(id):getNumber() == min then
						return "#f_huoxinGPCCard:".. id..":->"..p:objectName()
					end
				end
			end
		end
	end
	if self.player:getPile("f_huoxinPindianCard"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("f_huoxinPindianCard")) do
			for _, p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:hasFlag("f_huoxin_pindiantargets") then
					return "#f_huoxinGPCCard:".. id..":->"..p:objectName()
				end
			end
		end
	end
	
end
sgs.ai_skill_invoke.f_huoxin = true




--

--2 神张角
  --“太平”AI（仅包括横置角色）
sgs.ai_skill_invoke.f_taiping = function(self, data)
    self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if not self:needToLoseHp(enemy) and not enemy:isChained() and (self:damageIsEffective(enemy,"T") or self:damageIsEffective(enemy,"F")) then
		    return true
		end
	end
	for _, friend in ipairs(self.friends) do
		if not self:needToLoseHp(friend) and friend:isChained() then
		    return true
		end
	end
	for _, friend in ipairs(self.friends) do
		if self:needToLoseHp(friend) and not friend:isChained() then
		    return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.f_taiping = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets) do
		if self:isEnemy(p) then
			if not self:needToLoseHp(p) and not p:isChained() and (self:damageIsEffective(p,"T") or self:damageIsEffective(p,"F")) then
				return p
			end
		end
		if self:isFriend(p) then
			if not self:needToLoseHp(p) and p:isChained() then
				return p
			end
			if self:needToLoseHp(p) and not p:isChained() then
				return p
			end
		end
	end
end

sgs.ai_skill_choice.f_taiping = function(self, choices, data)
	local target = data:toPlayer()
	if self:isEnemy(target) then
		if not self:needToLoseHp(target) and not target:isChained() and (self:damageIsEffective(target,"T") or self:damageIsEffective(target,"F")) then
			return "tpChain"
		end
	end
	if self:isFriend(target) then
		if not self:needToLoseHp(target) and target:isChained() then
			return "tpRestore"
		end
		if self:needToLoseHp(target) and not target:isChained() then
			return "tpChain"
		end
	end
    return "tpChain"
end

  --“妖术”AI
    --不写。

f_yaoshu_skill = {}
f_yaoshu_skill.name = "f_yaoshu"
table.insert(sgs.ai_skills, f_yaoshu_skill)
f_yaoshu_skill.getTurnUseCard          = function(self, inclusive)
	local source = self.player
	return sgs.Card_Parse("#f_yaoshuCard:.:")
end

sgs.ai_skill_use_func["#f_yaoshuCard"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy and targets:length() < 3 and enemy:faceUp() then
			targets:append(enemy)
		end
	end
	if targets:length() >= 1 and sgs.turncount > 0 then
		use.card = sgs.Card_Parse("#f_yaoshuCard:.:")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority["f_yaoshuCard"]    = 6
sgs.ai_card_intention["f_yaoshuCard"]  = 100
  --“落雷”AI
local f_luolei_skill = {}
f_luolei_skill.name = "f_luolei"
table.insert(sgs.ai_skills, f_luolei_skill)
f_luolei_skill.getTurnUseCard = function(self)
	if self.player:getMark("@f_luolei") == 0 then return end
	return sgs.Card_Parse("#f_luoleiCard:.:")
end

sgs.ai_skill_use_func["#f_luoleiCard"] = function(card, use, self)
    if self.player:getMark("@f_luolei") > 0 then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy,"T") then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.f_luoleiCard = 8.5
sgs.ai_use_priority.f_luoleiCard = 9.5
sgs.ai_card_intention.f_luoleiCard = 80

--3 神张飞
  --“斗神”AI
local f_doushen_skill = {}
f_doushen_skill.name = "f_doushen"
table.insert(sgs.ai_skills, f_doushen_skill)
f_doushen_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#f_doushenCard:.:")
end

sgs.ai_skill_use_func["#f_doushenCard"] = function(card, use, self)
	local slashcount = self:getCardsNum("Slash")
	if slashcount >= 2 or (self:getOverflow() > 0 and slashcount > 0) then

		local slash = self:getCard("Slash")
		if not slash then return end		
		local dummy_use = dummy()
		if slash then self:useBasicCard(slash,dummy_use) end
		if dummy_use.card then
			use.card = card
			return
		end
	end
end

sgs.ai_use_value["f_doushenCard"] = 9.7
sgs.ai_use_priority["f_doushenCard"] = 7
sgs.f_doushen_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.3,
	FireSlash = 5.6,
	Slash = 5.4,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}
  --“酒威”AI
sgs.ai_view_as.f_jiuwei = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
	and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
		return ("analeptic:f_jiuwei[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_cardneed.f_jiuwei = sgs.ai_cardneed.slash

sgs.ai_ajustdamage_from.f_jiuwei = function(self,from,to,slash,nature)
	if slash and slash:isKindOf("Slash") and slash:hasFlag("drank")
	then return 1 end
end

sgs.ai_used_revises.f_jiuwei = function(self, use)
	if use.card:isKindOf("Slash")
		and self.player:hasFlag("f_doushenBuff")
		and self.player:getMark("drank") == 0
		and not use.isDummy
	then
		for _, to in sgs.list(use.to) do
			if self:isEnemy(to) then
				local handcards = sgs.QList2Table(self.player:getCards("h"))
				local card_str =("analeptic:f_jiuwei[%s:%s]=%d"):format(handcards[1]:getSuitString(), handcards[1]:getNumberString(), handcards[1]:getEffectiveId())
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				use.to = sgs.SPlayerList()
				return false
			end
		end
	end
end



--

--4 神马超
  --“神临”AI
local f_shenlin_skill = {}
f_shenlin_skill.name = "f_shenlin"
table.insert(sgs.ai_skills, f_shenlin_skill)
f_shenlin_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#f_shenlinCard") or self.player:getHandcardNum() < 3 or (self:getCardsNum("TrickCard") == 0 and self:getCardsNum("EquipCard") == 0) or #self.enemies == 0 then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")
	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#f_shenlinCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#f_shenlinCard"] = function(card, use, self)
    if not self.player:hasUsed("#f_shenlinCard") and self.player:getHandcardNum() > 2 then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.f_shenlinCard = 9
sgs.ai_use_priority.f_shenlinCard = 9.7
sgs.ai_card_intention.f_shenlinCard = 90

  --“神怒”AI
local f_shennu_skill = {}
f_shennu_skill.name = "f_shennu"
table.insert(sgs.ai_skills, f_shennu_skill)
f_shennu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#f_shennuCard") or self.player:getHp() < 2 or self:getCardsNum("Slash") == 0 then return end
	return sgs.Card_Parse("#f_shennuCard:.:")
end

sgs.ai_skill_use_func["#f_shennuCard"] = function(card, use, self)
    if not self.player:hasFlag("shenzhinuhuo") then
        use.card = card
	    return
	end
end

sgs.ai_use_value.f_shennuCard = 8.5
sgs.ai_use_priority.f_shennuCard = 9.5
sgs.ai_card_intention.f_shennuCard = -80

sgs.double_slash_skill = sgs.double_slash_skill .. "|f_shennu"
sgs.ai_cardneed.f_shennu = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.f_shennu = function(self,from,to,slash,nature)
	if slash and slash:isKindOf("Slash") and from:hasFlag("shenzhinuhuo") then
		local x = 0
		if slash:isRed() then
			x = x + 1
		end
		if to:hasFlag("suodingcaozei") then
			x = x + 1
		end
		return x 
	end
end

sgs.ai_canliegong_skill.f_shennu = function(self, from, to)
	return from:hasFlag("shenzhinuhuo")
end

local function isSpecialOne(player, name)
	local g_name = sgs.Sanguosha:translate(player:getGeneralName())
	if string.find(g_name, name) then return true end
	if player:getGeneral2() then
		g_name = sgs.Sanguosha:translate(player:getGeneral2Name())
		if string.find(g_name, name) then return true end
	end
	return false
end
sgs.ai_ajustdamage_from.f_caohen = function(self,from,to,slash,nature)
	if isSpecialOne(to, "曹操") or (to:getKingdom() == "wei" and to:isLord())
	then return 1 end
end

--5 神姜维
  --“北伐!”AI
local f_beifa_skill = {}
f_beifa_skill.name = "f_beifa"
table.insert(sgs.ai_skills, f_beifa_skill)
f_beifa_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#f_beifaCard") or self.player:isNude() or #self.enemies == 0 then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")
	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _, acard in ipairs(cards) do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				  and not acard:isKindOf("Peach") then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#f_beifaCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#f_beifaCard"] = function(card, use, self)
    if not self.player:hasUsed("#f_beifaCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.f_beifaCard = 8.5
sgs.ai_use_priority.f_beifaCard = 9.5
sgs.ai_card_intention.f_beifaCard = 80

local mx_xinghan_skill = {}
mx_xinghan_skill.name = "mx_xinghan"
table.insert(sgs.ai_skills, mx_xinghan_skill)
mx_xinghan_skill.getTurnUseCard = function(self)
	local choices = {}
	if not self.player:hasSkill("kongcheng") then
		table.insert(choices, "addskill_kongcheng")
	end
	if not self.player:hasSkill("tenyearwusheng") then
		table.insert(choices, "addskill_wusheng")
	end
	if not self.player:hasSkill("olpaoxiao") then
		table.insert(choices, "addskill_paoxiao")
	end
	if not self.player:hasSkill("olyajiao") then
		table.insert(choices, "addskill_yajiao")
	end
	if not self.player:hasSkill("tenyearliegong") then
		table.insert(choices, "addskill_liegong")
	end
	if not self.player:hasSkill("tieji") then
		table.insert(choices, "addskill_tieqi")
	end
	if #choices > 0 then
		return sgs.Card_Parse("#mx_xinghanCard:.:")
	end
end

sgs.ai_skill_use_func["#mx_xinghanCard"] = function(card, use, self)
	use.card = card
	return
end

sgs.ai_use_value.mx_xinghanCard = 8.5
sgs.ai_use_priority.mx_xinghanCard = 9.5
sgs.ai_skill_choice["mx_xinghan"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1, #items)]
end


local mx_hanhun_skill = {}
mx_hanhun_skill.name = "mx_hanhun"
table.insert(sgs.ai_skills, mx_hanhun_skill)
mx_hanhun_skill.getTurnUseCard = function(self)
	local use_cards = {}
	local type = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, acard in ipairs(cards) do
		if not table.contains(type, acard:getTypeId()) then
			table.insert(type, acard:getTypeId())
			table.insert(use_cards, acard:getEffectiveId())
		end
	end
	
	if #use_cards == 3 then
	    return sgs.Card_Parse("#mx_hanhunCard:" .. table.concat(use_cards, "+") .. ":")
	end
end

sgs.ai_skill_use_func["#mx_hanhunCard"] = function(card, use, self)
	use.card = card
	if use.to then use.to:append(self.player) end
	return
end

sgs.ai_use_value.mx_hanhunCard = 8.5
sgs.ai_use_priority.mx_hanhunCard = 9.5
sgs.ai_card_intention.mx_hanhunCard = -80







--6 神邓艾
  --“毡衫”AI（不包括主动给别人标记）
sgs.ai_skill_invoke.f_zhanshan = function(self, data)
    if self.player:getMaxHp() <= 2 then return false end
	return true
end

local f_zhanshan_skill = {}
f_zhanshan_skill.name = "f_zhanshan"
table.insert(sgs.ai_skills, f_zhanshan_skill)
f_zhanshan_skill.getTurnUseCard = function(self)
	if self.player:getMark("&mark_zhanshan")<2 and self:getCardsNum("Peach")<=self.player:getLostHp() then return nil end
	for _,who in ipairs(self.friends_noself)do
		if who:getMark("&mark_zhanshan")<1 then
			return sgs.Card_Parse("#f_zhanshanCard:.:")
		end
	end
	
end

sgs.ai_skill_use_func["#f_zhanshanCard"] = function(card, use, self)
	for _,who in ipairs(self.friends_noself)do
		if who:getMark("&mark_zhanshan")<1 then
			use.card = card
			if use.to then 
				use.to:append(who)
				return
			end 
		end
	end
	
	return
end

sgs.ai_use_value.f_zhanshanCard = 8.5
sgs.ai_use_priority.f_zhanshanCard = 9.5
sgs.ai_card_intention.f_zhanshanCard = -80







--

--7 汉中王神刘备
  --“结义”AI
local f_jieyi_skill = {}
f_jieyi_skill.name = "f_jieyi"
table.insert(sgs.ai_skills, f_jieyi_skill)
f_jieyi_skill.getTurnUseCard = function(self)
	if #self.friends_noself < 1 then return end	
	return sgs.Card_Parse("#f_jieyiCard:.:")
end

sgs.ai_skill_use_func["#f_jieyiCard"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	for _,friend in ipairs(self.friends_noself)do
		targets:append(friend)
		if targets:length() >= 2 then break end
	end
    if targets:length() == 2 then
        use.card = card
		use.to = targets
	    return
	end
end
sgs.ai_card_intention.f_jieyiCard = -100
sgs.ai_use_priority.f_jieyiCard = 9.6
sgs.ai_skill_use["@@yizhiLoyal"] = function(self,prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMark("&XD") > 0 then
			targets:append(p)
		end
	end
	if targets:length() == 0 then return "." end
	local c,to = self:getCardNeedPlayer(cards, false, targets)
	if c and to then return "#yizhiLoyalCard:"..c:getEffectiveId()..":->"..to:objectName() end
	return "."
end

--“仁义”AI
local f_renyi_skill = {}
f_renyi_skill.name = "f_renyi"
table.insert(sgs.ai_skills, f_renyi_skill)
f_renyi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#f_renyiCard") then return end
	return sgs.Card_Parse("#f_renyiCard:.:")
end

sgs.ai_skill_use_func["#f_renyiCard"] = function(card, use, self)
    if not self.player:hasUsed("#f_renyiCard") then
        use.card = card
	    return
	end
end
sgs.ai_use_value.f_renyiCard = 8.5
sgs.ai_use_priority.f_renyiCard = 9.5
sgs.ai_card_intention.f_renyiCard = -80

sgs.ai_ajustdamage_from.f_renyi = function(self,from,to,card,nature)
	if card and card:isDamageCard() and from:getMark("f_renyiBUFF") > 0
	then return 1 end
end
sgs.ai_skill_use["@@f_renyiX!"] = function(self,prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMark("&XD") > 0 then
			targets:append(p)
		end
	end
	if targets:length() == 0 then
		local c,to = self:getCardNeedPlayer(cards, false)
		if c and to then return "#f_renyiXCard:"..c:getEffectiveId()..":->"..to:objectName() end
	end
	local c,to = self:getCardNeedPlayer(cards, false, targets)
	if c and to then return "#f_renyiXCard:"..c:getEffectiveId()..":->"..to:objectName() end
	for _, friend in ipairs(self.friends_noself) do
		if friend:getMark("&XD") > 0 then
			for _,h in sgs.list(self.player:getHandcards())do
				if self:willUse(self.player, h) and h:isAvailable(self.player) then continue end
				return "#f_renyiXCard:"..h:getEffectiveId()..":->"..friend:objectName()
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		for _,h in sgs.list(self.player:getHandcards())do
			if self:willUse(self.player, h) and h:isAvailable(self.player) then continue end
			return "#f_renyiXCard:"..h:getEffectiveId()..":->"..friend:objectName()
		end
	end
	
	return "."
end

sgs.ai_skill_playerchosen["f_hanzhongwang"] = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if friend:getKingdom() ~= "shu" then
			return friend
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getKingdom() ~= "shu" then
			return enemy
		end
	end

	return nil
end
sgs.ai_ajustdamage_from["&f_hanzhongwang"] = function(self,from,to,card,nature)
	if from:getPhase() ~= sgs.Player_NotActive
	then return 1 end
end
sgs.ai_skill_use["@@f_hanzhongwang"] = function(self,prompt)
	local targets = {}
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getKingdom() == "shu" and not p:isAllNude() then
			table.insert(targets, p:objectName())
		end
	end
	if #targets > 0 then
		return "#f_hanzhongwangCard:.:->".. table.concat(targets, "+")
	end
	return "."
end



--8 神黄忠
sgs.ai_ajustdamage_from.f_shengong = function(self,from,to,card,nature)
	if from:getPile("ShenJian"):length() >= 12 and card and card:isKindOf("Slash")
	then return 1 end
end
sgs.ai_cardneed.f_shengong = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|f_shengong"

sgs.ai_canliegong_skill.f_shengong = function(self, from, to)
	return from:getPile("ShenJian"):length() >= 8
end

  --“定军”AI（不智能）
local f_dingjun_skill = {}
f_dingjun_skill.name = "f_dingjun"
table.insert(sgs.ai_skills, f_dingjun_skill)
f_dingjun_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#f_dingjunCard") and self.player:getPile("ShenJian"):length() >= 16 and self.player:getHandcardNum() <= 6 then return end
	return sgs.Card_Parse("#f_dingjunCard:.:")
end

sgs.ai_skill_use_func["#f_dingjunCard"] = function(card, use, self)
    if not self.player:hasUsed("#f_dingjunCard") and self.player:getPile("ShenJian"):length() < 16 and self.player:getHandcardNum() > 6 then
        use.card = card
	    return
	end
end

sgs.ai_skill_choice.f_dingjun = function(self, choices, data)
	if self.player:getMark("DJSZhanGong") == 0 and self.player:getHandcardNum() >= 4 then return "add4ShenJian" end
	if self.player:getMark("DJSZhanGong") == 0 and self.player:getPile("ShenJian"):length() >= 4 and self.player:getHp() <= 2 and self.player:isKongcheng() then return "get4ShenJian" end
end

sgs.ai_use_value.f_dingjunCard = 8.5
sgs.ai_use_priority.f_dingjunCard = 9.5
sgs.ai_card_intention.f_dingjunCard = -80


local f_luanshe_skill = {}
f_luanshe_skill.name = "f_luanshe"
table.insert(sgs.ai_skills, f_luanshe_skill)
f_luanshe_skill.getTurnUseCard = function(self)
	if self.player:getPile("ShenJian"):length()  <= 6 then return end
	local useAll = false
	for _,enemy in sgs.list(self.enemies)do
		if enemy:getHp()==1 and not enemy:hasArmorEffect("Vine")
		and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy,nil,self.player) and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true end
	end
	if (self.player:aliveCount() - self.player:getHp() * 2) < 0 and not useAll then return end
	local use_cards = {}
	for _, id in sgs.qlist(self.player:getPile("ShenJian")) do
		table.insert(use_cards, sgs.Sanguosha:getCard(id))
		if #use_cards >= self.player:getHp() * 2 then break end
	end
	local archery_attack =  sgs.Sanguosha:cloneCard("archery_attack", sgs.Card_NoSuit, 0)
	archery_attack:deleteLater()
	archery_attack:setSkillName("f_luanshe")
	for _,c in ipairs(use_cards)do
		archery_attack:addSubcard(c)
	end
	assert(archery_attack)

	local dummy_use = dummy()
	self:useTrickCard(archery_attack,dummy_use)
	if dummy_use.card then
		return archery_attack
	end
	
end



local f_newdingjun_skill = {}
f_newdingjun_skill.name = "f_newdingjun"
table.insert(sgs.ai_skills, f_newdingjun_skill)
f_newdingjun_skill.getTurnUseCard = function(self)
	if self.player:getPile("ShenJian"):length() >= 16 and self.player:getHandcardNum() <= 3 then return end
	return sgs.Card_Parse("#f_newdingjunCard:.:")
end

sgs.ai_skill_use_func["#f_newdingjunCard"] = function(card, use, self)
    if self.player:getPile("ShenJian"):length() < 16 and self.player:getHandcardNum() > 3 then
        use.card = card
	    return
	end
    if self.player:getPile("ShenJian"):length() > 0 and not self.player:hasSkill("tenyearliegong")  then
        use.card = card
	    return
	end
end

sgs.ai_skill_choice.f_newdingjun = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "add1to4ShenJian") and self.player:getMark("DJSZhanGong") > 0 and not self.player:isKongcheng() then return "add1to4ShenJian" end
	if table.contains(items, "get1to4ShenJian") and self.player:getMark("DJSZhanGong") > 0 and self.player:getPile("ShenJian"):length() > 0 and not self.player:hasSkill("tenyearliegong") then return "get1to4ShenJian" end
end

sgs.ai_use_value.f_newdingjunCard = 8.5
sgs.ai_use_priority.f_newdingjunCard = 9.5
sgs.ai_card_intention.f_newdingjunCard = -80

sgs.ai_skill_use["@@getFShenJianSkill"] = function(self, prompt)
	local card = sgs.Card_Parse("#getFShenJianSkillCard:.:")
	local dummy_use = {isDummy = true}
	self:useSkillCard(card, dummy_use)
	if dummy_use.card then return (dummy_use.card):toString() .. "->." end
	return "."
end

sgs.ai_skill_use["@@getOTFShenJianSkill"] = function(self, prompt)
	local use_cards = {}
	for _, id in sgs.qlist(self.player:getPile("ShenJian")) do
		table.insert(use_cards, id)
		if #use_cards >= 1 then break end
	end
	if #use_cards > 0 then return "#getOTFShenJianSkillCard:" .. table.concat(use_cards, "+") .. ":" end
	return "."
end

--

--9 神项羽
  --“霸王”AI
local f_bawang_skill = {}
f_bawang_skill.name = "f_bawang"
table.insert(sgs.ai_skills, f_bawang_skill)
f_bawang_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#f_bawangCard") or (self:getCardsNum("Slash") == 0 and self:getCardsNum("Jink") == 0 and self:getCardsNum("Analeptic") == 0) or #self.enemies == 0 then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("BasicCard") and not acard:isKindOf("Peach") then
			card_id = acard:getEffectiveId()
			break
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#f_bawangCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#f_bawangCard"] = function(card, use, self)
    if not self.player:hasUsed("#f_bawangCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.f_bawangCard = 8.5
sgs.ai_use_priority.f_bawangCard = 9.5
sgs.ai_card_intention.f_bawangCard = 80

sgs.ai_cardneed.f_zhuifeng = sgs.ai_cardneed.slash

sgs.ai_skill_playerchosen.f_pofuchenzhou = sgs.ai_skill_playerchosen.damage


--10 神孙悟空（无）

local f_doufa_skill = {}
f_doufa_skill.name = "f_doufa"
table.insert(sgs.ai_skills, f_doufa_skill)
f_doufa_skill.getTurnUseCard = function(self)
	if self.player:getHp() >= 4 then return end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local use_cards = {}
	for _, acard in ipairs(cards) do
		if acard:isKindOf("BasicCard") and not acard:isKindOf("Peach") then
			table.insert(use_cards, acard:getEffectiveId())
			if #use_cards >= self.player:getHp() then break end
		end
	end
	if #use_cards > 0 then
	    return sgs.Card_Parse("#f_doufaCard:".. table.concat(use_cards, "+") .. ":")
	end
end

sgs.ai_skill_use_func["#f_doufaCard"] = function(card, use, self)
    if not self.player:hasUsed("#f_doufaCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 and not self:cantbeHurt(enemy) then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.f_doufaCard = 8.5
sgs.ai_use_priority.f_doufaCard = 9.5
sgs.ai_card_intention.f_doufaCard = 80



--

--11 [神]君王霸王龙
  --“地狱溪”AI
local f_diyuxi_skill = {}
f_diyuxi_skill.name = "f_diyuxi"
table.insert(sgs.ai_skills, f_diyuxi_skill)
f_diyuxi_skill.getTurnUseCard = function(self)
	if self.player:getHp() <= 1 and self.player:getMaxHp() <= 1 then return end
	return sgs.Card_Parse("#f_diyuxiCard:.:")
end

sgs.ai_skill_use_func["#f_diyuxiCard"] = function(card, use, self)
    if not self.player:hasUsed("#f_diyuxiCard") then --保证（非特殊情况）每回合必选一项且仅选一项，避免结束阶段失去体力
        use.card = card
	    return
	end
	if math.random() < 0.5 and #self.toUse > 0 and #self.enemies > 0 then
		use.card = card
	    return
	end
end

sgs.ai_skill_choice.f_diyuxi = function(self, choices, data)
	if self.player:getHp() - self.player:getMaxHp() < 0 and self.player:getMaxHp() > 1 and (self:getCardsNum("Duel") > 0 or self:getCardsNum("SavageAssault") > 0 or self:getCardsNum("ArcheryAttack") > 0 or self:getCardsNum("FireAttack") > 0 or self:getCardsNum("Drowning") > 0 or self:getCardsNum("Chuqibuyi") > 0 or self:getCardsNum("Qizhengxiangsheng") > 0) then return "LM1D2D1" end
	--if self.player:isRebel() and self.player:getHp() <= 1 and self.player:getMaxHp() <= 1 then return "LM1D2D1" end --自我物理完杀，防止敌方收头拿牌&给农民队友补牌
		for _,h in sgs.list(self.player:getHandcards())do
			if h:isDamageCard() and not h:isKindOf("Slash") and self.player:getMaxHp() > 1 and self.player:isWounded() then
				return "LM1D2D1"
			end
		end
	if self.player:getHp() <= 1 and self.player:getMaxHp() > 1 then return "LM1D2D1" end
	if self.player:getHp() <= 1 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0 and (self:getCardsNum("Duel") == 0 and self:getCardsNum("SavageAssault") == 0 and self:getCardsNum("ArcheryAttack") == 0 and self:getCardsNum("FireAttack") == 0 and self:getCardsNum("Drowning") == 0 and self:getCardsNum("Chuqibuyi") == 0 and self:getCardsNum("Qizhengxiangsheng") == 0) then return "cancel" end
	return "L1D1SD1"
end

sgs.ai_use_value.f_diyuxiCard = 10
sgs.ai_use_priority.f_diyuxiCard = 10
sgs.ai_card_intention.f_diyuxiCard = -100


sgs.ai_ajustdamage_from.f_diyuxi = function(self,from,to,card,nature)
	local x = 0
	if from:hasFlag("LM1D2D1_BUFF")
	then x = x + 1 end
	if from:hasFlag("L1D1SD1_BUFF") and card and card:isKindOf("Slash")
	then x = x + 1 end
	return x
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|f_kuanglong"
sgs.ai_cardneed.f_kuanglong = sgs.ai_cardneed.slash

--


--12 [神]鲲鹏
  --“九天”AI
sgs.ai_skill_use["@@f_juxing"] = function(self,prompt)
	for _, friend in ipairs(self.friends_noself) do
		if friend:getMark("&KunPeng") == 0 then
			return "#f_juxingCard:.:->"..friend:objectName()
		end
	end
	return "."
end
sgs.ai_card_intention["f_juxingCard"]    = -80
local f_jiutian_skill = {}
f_jiutian_skill.name = "f_jiutian"
table.insert(sgs.ai_skills, f_jiutian_skill)
f_jiutian_skill.getTurnUseCard = function(self)
	if self.player:getMark("&f_juxing_trigger") == 0 and self.player:getMaxHp() <= 1 then return end
	return sgs.Card_Parse("#f_jiutianCard:.:")
end

sgs.ai_skill_use_func["#f_jiutianCard"] = function(card, use, self)
    if self.player:getMark("&f_juxing_trigger") > 0 and self.player:getMaxHp() > 1 then
        use.card = card
	    return
	end
end

sgs.ai_skill_playerchosen["#f_jiutianContinue"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isFriend(p) and (p:getHandcardNum() < p:getHp() or p:isWounded()) then
		    return p 
		end
	end
	return self.player
end
sgs.ai_playerchosen_intention["#f_jiutianContinue"] = -70

sgs.ai_use_value.f_jiutianCard = 10
sgs.ai_use_priority.f_jiutianCard = 10
sgs.ai_card_intention.f_jiutianCard = -87
--

--13 FC神吕蒙
sgs.ai_skill_invoke.fcshelie = true
sgs.ai_skill_invoke["@fcshelieGC"] = function(self, data)
	if sgs.ai_skill_playerchosen.fcshelie(self, self.room:getOtherPlayers(self.player)) then
		return true
	end
	return false
end
sgs.ai_skill_playerchosen.fcshelie = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend, self.player) then
			return friend
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.fcshelie = -40

local fcgongxin_skill = {}
fcgongxin_skill.name = "fcgongxin"
table.insert(sgs.ai_skills, fcgongxin_skill)
fcgongxin_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#fcgongxinCard") then return end
	local fcgongxin_card = sgs.Card_Parse("#fcgongxinCard:.:")
	assert(fcgongxin_card)
	return fcgongxin_card
end

sgs.ai_skill_use_func["#fcgongxinCard"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)

	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self:objectiveLevel(enemy) > 0 and self:getKnownNum(enemy) ~= enemy:getHandcardNum() then
			use.card = card
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end

sgs.ai_skill_askforag.fcgongxin = function(self, card_ids)
	self.fcgongxinchoice = nil
	local target = self.player:getTag("fcgongxin"):toPlayer()
	if not target or self:isFriend(target) then return -1 end
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
	until nextAlive:faceUp()

	local peach, ex_nihilo, jink, nullification, slash
	local valuable
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Peach") then peach = id end
		if card:isKindOf("ExNihilo") then ex_nihilo = id end
		if card:isKindOf("Jink") then jink = id end
		if card:isKindOf("Nullification") then nullification = id end
		if card:isKindOf("Slash") then slash = id end
	end
	valuable = peach or ex_nihilo or jink or nullification or slash or card_ids[1]
	local card = sgs.Sanguosha:getCard(valuable)
	if self:isEnemy(target) and target:hasSkill("tuntian") then
		local zhangjiao = self.room:findPlayerBySkillName("guidao")
		if zhangjiao and self:isFriend(zhangjiao, target) and self:canRetrial(zhangjiao, target) and self:isValuableCard(card, zhangjiao) then
			self.fcgongxinchoice = "discard"
		else
			self.fcgongxinchoice = "put"
		end
		return valuable
	end

	local willUseExNihilo, willRecast
	if self:getCardsNum("ExNihilo") > 0 then
		local ex_nihilo = self:getCard("ExNihilo")
		if ex_nihilo then
			local dummy_use = { isDummy = true }
			self:useTrickCard(ex_nihilo, dummy_use)
			if dummy_use.card then willUseExNihilo = true end
		end
	elseif self:getCardsNum("IronChain") > 0 then
		local iron_chain = self:getCard("IronChain")
		if iron_chain then
			local dummy_use = { to = sgs.SPlayerList(), isDummy = true }
			self:useTrickCard(iron_chain, dummy_use)
			if dummy_use.card and dummy_use.to:isEmpty() then willRecast = true end
		end
	end
	if willUseExNihilo or willRecast then
		local card = sgs.Sanguosha:getCard(valuable)
		if card:isKindOf("Peach") then
			self.fcgongxinchoice = "put"
			return valuable
		end
		if card:isKindOf("TrickCard") or card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage") then
			local dummy_use = { isDummy = true }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				self.fcgongxinchoice = "put"
				return valuable
			end
		end
		if card:isKindOf("Jink") and self:getCardsNum("Jink") == 0 then
			self.fcgongxinchoice = "put"
			return valuable
		end
		if card:isKindOf("Nullification") and self:getCardsNum("Nullification") == 0 then
			self.fcgongxinchoice = "put"
			return valuable
		end
		if card:isKindOf("Slash") and self:slashIsAvailable() then
			local dummy_use = { isDummy = true }
			self:useBasicCard(card, dummy_use)
			if dummy_use.card then
				self.fcgongxinchoice = "put"
				return valuable
			end
		end
		self.fcgongxinchoice = "discard"
		return valuable
	end

	local hasLightning, hasIndulgence, hasSupplyShortage
	local tricks = nextAlive:getJudgingArea()
	if not tricks:isEmpty() and not nextAlive:containsTrick("YanxiaoCard") then
		local trick = tricks:at(tricks:length() - 1)
		if self:hasTrickEffective(trick, nextAlive) then
			if trick:isKindOf("Lightning") then hasLightning = true
			elseif trick:isKindOf("Indulgence") then hasIndulgence = true
			elseif trick:isKindOf("SupplyShortage") then hasSupplyShortage = true
			end
		end
	end

	if self:isEnemy(nextAlive) and nextAlive:hasSkill("luoshen") and valuable then
		self.fcgongxinchoice = "put"
		return valuable
	end
	if nextAlive:hasSkill("yinghun") and nextAlive:isWounded() then
		self.fcgongxinchoice = self:isFriend(nextAlive) and "put" or "discard"
		return valuable
	end
	if target:hasSkill("hongyan") and hasLightning and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		for _, id in ipairs(card_ids) do
			local card = sgs.Sanguosha:getEngineCard(id)
			if card:getSuit() == sgs.Card_Spade and card:getNumber() >= 2 and card:getNumber() <= 9 then
				self.fcgongxinchoice = "put"
				return id
			end
		end
	end
	if hasIndulgence and self:isFriend(nextAlive) then
		self.fcgongxinchoice = "put"
		return valuable
	end
	if hasSupplyShortage and self:isEnemy(nextAlive) and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		local enemy_null = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(p) then enemy_null = enemy_null - getCardsNum("Nullification", p) end
			if self:isEnemy(p) then enemy_null = enemy_null + getCardsNum("Nullification", p) end
		end
		enemy_null = enemy_null - self:getCardsNum("Nullification")
		if enemy_null < 0.8 then
			self.fcgongxinchoice = "put"
			return valuable
		end
	end

	if self:isFriend(nextAlive) and not self:willSkipDrawPhase(nextAlive) and not self:willSkipPlayPhase(nextAlive)
		and not nextAlive:hasSkill("luoshen")
		and not nextAlive:hasSkill("tuxi") and not (nextAlive:hasSkill("qiaobian") and nextAlive:getHandcardNum() > 0) then
		if (peach and valuable == peach) or (ex_nihilo and valuable == ex_nihilo) then
			self.fcgongxinchoice = "put"
			return valuable
		end
		if jink and valuable == jink and getCardsNum("Jink", nextAlive) < 1 then
			self.fcgongxinchoice = "put"
			return valuable
		end
		if nullification and valuable == nullification and getCardsNum("Nullification", nextAlive) < 1 then
			self.fcgongxinchoice = "put"
			return valuable
		end
		if slash and valuable == slash and self:hasCrossbowEffect(nextAlive) then
			self.fcgongxinchoice = "put"
			return valuable
		end
	end

	local card = sgs.Sanguosha:getCard(valuable)
	local keep = false
	if card:isKindOf("Slash") or card:isKindOf("Jink")
		or card:isKindOf("EquipCard")
		or card:isKindOf("Disaster") or card:isKindOf("GlobalEffect") or card:isKindOf("Nullification")
		or target:isLocked(card) then
		keep = true
	end
	self.fcgongxinchoice = (target:objectName() == nextAlive:objectName() and keep) and "put" or "discard"
	return valuable
end

sgs.ai_skill_choice.fcgongxin = function(self, choices)
	return self.fcgongxinchoice or "discard"
end

sgs.ai_use_value.fcgongxinCard = 8.5
sgs.ai_use_priority.fcgongxinCard = 9.5
sgs.ai_card_intention.fcgongxinCard = 80

--

--14 FC神赵云（不加AI）

sgs.ai_ajustdamage_from.fclongming = function(self,from,to,card,nature)
	if card and card:isBlack() and card:getSkillName() == "fclongmingBuff" then
		if from:hasFlag("fclongmingANA_Buff") then
			return 2
		else
			return 1
		end
	elseif card and card:isKindOf("Slash") then
		if from:hasFlag("fclongmingANA_Buff") then
			return 1
		end
	end
end
local fclongming_skill = {}
fclongming_skill.name = "fclongming"
table.insert(sgs.ai_skills,fclongming_skill)
fclongming_skill.getTurnUseCard = function(self,inclusive)
	local usable_cards = self:addHandPile()
	local equips = sgs.QList2Table(self.player:getCards("e"))
	for _,e in sgs.list(equips)do
		if e:isKindOf("DefensiveHorse") or e:isKindOf("OffensiveHorse") then
			table.insert(usable_cards,e)
		end
	end
	self:sortByUseValue(usable_cards,true)
	local two_spade_cards = {}
	for _,c in sgs.list(usable_cards)do
		if c:getSuit()==sgs.Card_Spade and #two_spade_cards<2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>0) then
			table.insert(two_spade_cards,c:getEffectiveId())
		end
	end
	if #two_spade_cards==2 and self:slashIsAvailable() and self:getOverflow()>1 then
		return sgs.Card_Parse(("analeptic:fclongmingBuff[%s:%s]=%d+%d"):format("to_be_decided",0,two_spade_cards[1],two_spade_cards[2]))
	end
	for _,c in sgs.list(usable_cards)do
		if c:getSuit()==sgs.Card_Spade and self:slashIsAvailable() and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink")<3) and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>0) then
			return sgs.Card_Parse(("analeptic:fclongming[%s:%s]=%d"):format(c:getSuitString(),c:getNumberString(),c:getEffectiveId()))
		end
	end
	local two_club_cards = {}
	for _,c in sgs.list(usable_cards)do
		if c:getSuit()==sgs.Card_Club and #two_club_cards<2 and not c:isKindOf("Peach") and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>0) then
			table.insert(two_club_cards,c:getEffectiveId())
		end
	end
	if #two_club_cards==2 and self:slashIsAvailable() and self:getOverflow()>1 then
		return sgs.Card_Parse(("thunder_slash:fclongmingBuff[%s:%s]=%d+%d"):format("to_be_decided",0,two_club_cards[1],two_club_cards[2]))
	end
	for _,c in sgs.list(usable_cards)do
		if c:getSuit()==sgs.Card_Club and self:slashIsAvailable() and not c:isKindOf("Peach") and not (c:isKindOf("Jink") and self:getCardsNum("Jink")<3) and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>0) then
			return sgs.Card_Parse(("thunder_slash:fclongming[%s:%s]=%d"):format(c:getSuitString(),c:getNumberString(),c:getEffectiveId()))
		end
	end
	for _,c in sgs.list(usable_cards)do
		if c:getSuit()==sgs.Card_Heart and self.player:getMark("Global_PreventPeach")==0 and not c:isKindOf("Peach") then
			return sgs.Card_Parse(("peach:fclongming[%s:%s]=%d"):format(c:getSuitString(),c:getNumberString(),c:getEffectiveId()))
		end
	end
end

sgs.ai_view_as.fclongming = function(card,player,card_place,class_name)
	if card_place==sgs.Player_PlaceSpecial then return end
	local current = player:getRoom():getCurrent()
	local usable_cards = sgs.QList2Table(player:getCards("he"))
	for _,id in sgs.list(player:getHandPile())do
		table.insert(usable_cards,sgs.Sanguosha:getCard(id))
	end
	local two_diamond_cards = {}
	local two_heart_cards = {}
	for _,c in sgs.list(usable_cards)do
		if c:getSuit()==sgs.Card_Diamond and #two_diamond_cards<2 then
			table.insert(two_diamond_cards,c:getEffectiveId())
		elseif c:getSuit()==sgs.Card_Heart and #two_heart_cards<2 then
			table.insert(two_heart_cards,c:getEffectiveId())
		end
	end
	
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	
	if #two_diamond_cards==2 and current and not current:isNude() and current:getWeapon() and current:getWeapon():isKindOf("Crossbow") then
		return ("jink:fclongmingBuff[%s:%s]=%d+%d"):format("to_be_decided",0,two_diamond_cards[1],two_diamond_cards[2])
	elseif card:getSuit()==sgs.Card_Club then
		return ("jink:fclongming[%s:%s]=%d"):format(suit,number,card_id)
	end
	
	local dying = player:getRoom():getCurrentDyingPlayer()
	if #two_heart_cards==2 and dying and not dying:hasSkill("fcweijing") then
		return ("peach:fclongmingBuff[%s:%s]=%d+%d"):format("to_be_decided",0,two_heart_cards[1],two_heart_cards[2])
	elseif card:getSuit()==sgs.Card_Heart and player:getMark("Global_PreventPeach")==0 then
		return ("peach:fclongming[%s:%s]=%d"):format(suit,number,card_id)
	end
	
	if card:getSuit()==sgs.Card_Club and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length()>0) then
		return ("thunder_slash:fclongming[%s:%s]=%d"):format(suit,number,card_id)
	elseif card:getSuit()==sgs.Card_Spade then
		return ("analeptic:fclongming[%s:%s]=%d"):format(suit,number,card_id)
	end
end

sgs.fclongming_suit_value = sgs.longhun_suit_value

function sgs.ai_cardneed.fclongming(to,card,self)
	if to:getCardCount()>3 then return false end
	if to:isNude() then return true end
	return card:getSuit()==sgs.Card_Heart or card:getSuit()==sgs.Card_Spade
end

sgs.ai_need_damaged.fclongming = function(self,attacker,player)
	if player:getHp()>1 and player:hasSkill("fcweijing") then return true end
end




--15 FC神刘备
  --“结营”AI
sgs.ai_skill_invoke.fcjieying = function(self, data)
    self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 0 then
		    return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.fcjieying = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not p:hasSkill("jieying") and not p:hasSkill("fcjieying") and not p:hasSkill("faen") and not p:hasSkill("qianjie") and not p:hasSkills("chenghao+yinshi") then
			return p
		end
	end
	for _, p in ipairs(targets) do
		return p
	end
end

sgs.ai_playerchosen_intention.fcjieying = 10

sgs.ai_target_revises.fcjieying = function(to,card)
	if card:isKindOf("IronChain")
	then return true end
end

--16 FC神张辽
  --“夺锐”AI（无脑）

sgs.ai_skill_invoke.fcduorui = function(self,data)
	local target = data:toDamage().to
	return self:doDisCard(target, "he")
end

sgs.ai_skill_choice.fcduorui = function(self, choices, data)
	local target = data:toDamage().to
	if #self.toUse == 0 and self:isEnemy(target) and target:getEquips():length() > 0 then return "CleanUpEquipArea" end
	if not self.player:faceUp() and self:isEnemy(target) and self:doDisCard(target, "h") and not target:isKongcheng()  then return "CleanUpHandArea" end
    if not "obtain1card" then return "cancel" end
	return "obtain1card"
end
--

--17 地主
  --“飞扬”AI
sgs.ai_skill_use["@@f_feiyang"] = function(self,prompt)
	local disaster,indulgence,supply_shortage = -1,-1,-1
	for _,card in sgs.list(self.player:getJudgingArea())do
		if card:isKindOf("Disaster") then disaster = card:getId() end
		if card:isKindOf("Indulgence") then indulgence = card:getId() end
		if card:isKindOf("SupplyShortage") then supply_shortage = card:getId() end
	end
	
	local handcards = {}
	for _,id in sgs.list(self.player:handCards())do
		if self.player:canDiscard(self.player,id) then
			table.insert(handcards,sgs.Sanguosha:getCard(id))
		end
	end
	if #handcards<2 then return "." end
	self:sortByKeepValue(handcards)
	
	local discard = {}
	table.insert(discard,handcards[1]:getId())
	table.insert(discard,handcards[2]:getId())
	if #discard == 2 then
	
	return "#f_feiyang:"..table.concat(discard,"+")..":"
	end
	
	return "."
end



--

--18 农民
  --“耕种”AI
local f_gengzhong_skill = {}
f_gengzhong_skill.name = "f_gengzhong"
table.insert(sgs.ai_skills, f_gengzhong_skill)
f_gengzhong_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#f_gengzhongCard") or (self:getCardsNum("BasicCard") == 0 and self:getCardsNum("Nullification") == 0) or self:getCardsNum("Slash") <= 1 or self.player:getHandcardNum() - self.player:getHp() < 2 or self.player:isNude() then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("BasicCard") or acard:isKindOf("Nullification") then
			card_id = acard:getEffectiveId()
			break
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#f_gengzhongCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#f_gengzhongCard"] = function(card, use, self)
    if not self.player:hasUsed("#f_gengzhongCard") and not self.player:isNude() then
        use.card = card
	    return
	end
end

sgs.ai_use_value.f_gengzhongCard = 8.5
sgs.ai_use_priority.f_gengzhongCard = 9.5
sgs.ai_card_intention.f_gengzhongCard = -80

sgs.ai_skill_invoke["@f_gengzhongNTGet"] = function(self, data)
    if self.player:getPile("NT"):length() == 0 then return false end
	if self.player:getHp() <= 1 then return true end
	if self.player:getHandcardNum() <= 2 or self.player:getPile("NT"):length() >= 3 then return true end
	return false
end

  --“共抗”AI
local f_gongkang_skill = {}
f_gongkang_skill.name = "f_gongkang"
table.insert(sgs.ai_skills, f_gongkang_skill)
f_gongkang_skill.getTurnUseCard = function(self)
	if self.player:getMark("@f_gongkang") == 0 then return end
	return sgs.Card_Parse("#f_gongkangCard:.:")
end

sgs.ai_skill_use_func["#f_gongkangCard"] = function(card, use, self)
    if self.player:getMark("@f_gongkang") > 0 then
		self:sort(self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do
		    if self:isFriend(friend) then
			    use.card = card
			    if use.to then use.to:append(friend) end
		        return
			end
		end
		return
	end
end

sgs.ai_use_value.f_gongkangCard = 8.5
sgs.ai_use_priority.f_gongkangCard = 9.5
sgs.ai_card_intention.f_gongkangCard = -80

  --“同心”AI
sgs.ai_skill_invoke.f_tongxin = true

sgs.ai_skill_choice.f_tongxin = function(self, choices, data)
	if self.player:getHp() <= 1 and not self.player:isKongcheng() then return "2" end
	return "1"
end


--

--19 武神·关羽

local sp_taoyuanyi_skill = {}
sp_taoyuanyi_skill.name = "sp_taoyuanyi"
table.insert(sgs.ai_skills, sp_taoyuanyi_skill)
sp_taoyuanyi_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	
	for _, acard in ipairs(cards) do
		if acard:getSuit() == sgs.Card_Heart then
			card = acard
			break
		end
	end
	if card and self:willUseGodSalvation(card) then
		local card_str = string.format("god_salvation:sp_taoyuanyi[%s:%s]=.", sgs.Card_NoSuit, 0)
		local god_salvation = sgs.Card_Parse(card_str)
		god_salvation:addSubcard(card)
		assert(god_salvation)
		return god_salvation
	end
end

sgs.ai_card_priority.sp_taoyuanyi = function(self,card,v)
	if card:isKindOf("GodSalvation")
	then return 3 end
end


  --“威震”AI
local sp_weizhen_skill = {}
sp_weizhen_skill.name = "sp_weizhen"
table.insert(sgs.ai_skills, sp_weizhen_skill)
sp_weizhen_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	local useAll = false
	self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<2 and not enemy:hasArmorEffect("EightDiagram")
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end
	if self.player:getMark("sp_weizhen_used") >= 3 then
		if self.player:getMaxHp() <= 3 then
			return
		end
		if not useAll then
			return
		end
	end
	
	
	for _, acard in ipairs(cards) do
		if acard:isBlack() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.Drowning or self:getOverflow() > 0) then
			if acard:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then
				local keep
				local dummy_use = { isDummy = true , to = sgs.SPlayerList() }
				self:useBasicCard(acard, dummy_use)
				if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if p:getHp() <= 1 then keep = true break end
					end
					if dummy_use.to:length() > 1 then keep = true end
				end
				if keep then sgs.ai_use_priority.Slash = sgs.ai_use_priority.Drowning + 0.1
				else
					sgs.ai_use_priority.Slash = 2.6
					card = acard
					break
				end
			else
				card = acard
				break
			end
		end
	end
	if not card then return nil end
	if self.player:hasSkill("sp_qianlixing") then
		sgs.ai_use_priority.Drowning = 2.4
	end
	
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("drowning:sp_weizhen[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end
sgs.ai_event_callback[sgs.PreCardUsed].sp_weizhen = function(self,player,data)
	local use = data:toCardUse()
	if use.card and use.card:getSkillName() == "sp_weizhen" then
		sgs.ai_use_priority.Drowning = 7
	end
end

sgs.ai_cardneed.sp_weizhen = function(to, card, self)
	return card:isBlack() and (card:isKindOf("BasicCard") or card:isKindOf("TrickCard"))
end

sgs.ai_skill_use_func.sp_weizhen = function(card, use, self)
    if self.player:getMark("sp_weizhen_used") < 3 then
        use.card = card
	    return
	end
end

sgs.ai_view_as.sp_qianlixing = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:sp_qianlixing[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local sp_qianlixing_skill = {}
sp_qianlixing_skill.name = "sp_qianlixing"
table.insert(sgs.ai_skills,sp_qianlixing_skill)
sp_qianlixing_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("he")
	cards = self:sortByUseValue(cards,true)
	local red_card = {}
	local useAll = false
	self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<2 and not enemy:hasArmorEffect("EightDiagram")
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end
	for _,card in ipairs(cards)do
		if card:isRed() and not card:isKindOf("TrickCard")
		and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard())>0)
		then table.insert(red_card,card) end
	end

	for _,card in ipairs(red_card)do
		local slash = dummyCard("slash")
		slash:addSubcard(card)
		slash:setSkillName("sp_qianlixing")
		if slash:isAvailable(self.player)
		then return slash end
	end
end

function sgs.ai_cardneed.sp_qianlixing(to,card)
	return to:getHandcardNum()<3 and card:isRed()
end
sgs.ai_use_revises.sp_qianlixing = function(self,card,use)
	if card:isKindOf("Slash") and card:getSkillName() == "sp_qianlixing" and self.player:getPhase() == sgs.Player_Play then
		card:setFlags("Qinggang")
	end
end

sgs.ai_skill_use["@@sp_xiansheng"] = function(self, prompt)
	local targets = {}
	self:sort(self.friends_noself, "hp")
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() < getBestHp(friend) then
			table.insert(targets, friend:objectName())
			if #targets >= 3 then break end
		end
	end
	if #targets > 0 then
		return "#sp_xianshengCard:.:->" .. table.concat(targets, "+")
	end
	return "."
end
sgs.ai_use_revises.sp_guoguanzhanjiang = function(self,card,use)
	if card:isKindOf("Drowning") then 
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:getMark("&LeVeL") > 0 and CanToCard(card,self.player,p) and self:damageIsEffective(p,card,self.player) then
				use.card = card
				local targets = sgs.SPlayerList()
				targets:append(p) 
				use.to = targets
				return
			end
		end
	end
end





--

--20 风神·吕蒙
  --“刮目”AI
local sp_guamu_skill = {}
sp_guamu_skill.name = "sp_guamu"
table.insert(sgs.ai_skills, sp_guamu_skill)
sp_guamu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#sp_guamuCard") then return end
	return sgs.Card_Parse("#sp_guamuCard:.:")
end

sgs.ai_skill_use_func["#sp_guamuCard"] = function(card, use, self)
    if not self.player:hasUsed("#sp_guamuCard") then
        use.card = card
		if use.to then use.to:append(self.player) end
	    return
	end
end

sgs.ai_skill_choice["sp_guamuONE"] = function(self, choices, data)
	return "sp_guamuONEthrow"
end

sgs.ai_use_value.sp_guamuCard = 8.5
sgs.ai_use_priority.sp_guamuCard = 9.5
sgs.ai_card_intention.sp_guamuCard = -80

local sp_dujiang_skill = {}
sp_dujiang_skill.name = "sp_dujiang"
table.insert(sgs.ai_skills,sp_dujiang_skill)
sp_dujiang_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#sp_dujiangCard:.:")
end

sgs.ai_skill_use_func["#sp_dujiangCard"] = function(card,use,self)
	local slashes = self:getCards("Slash")
	if #slashes<1 then return end
	self:sort(self.enemies,"hp")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)

	for _,enemy in sgs.list(self.enemies)do
		for _,slash in sgs.list(slashes)do
			local d = self:aiUseCard(slash)
			if d.card and d.to:contains(enemy) then
				for _, c in ipairs(cards) do
					if c:isKindOf("EquipCard") then
						use.card = sgs.Card_Parse("#sp_dujiangCard:" .. c:getEffectiveId() .. ":")
						use.to:append(enemy)
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_priority.sp_dujiangCard = sgs.ai_use_priority.Slash+0.5
sgs.ai_use_value.sp_dujiangCard = 3


--

--21 火神·周瑜
  --“赤壁”AI
local sp_chibi_skill = {}
sp_chibi_skill.name = "sp_chibi"
table.insert(sgs.ai_skills, sp_chibi_skill)
sp_chibi_skill.getTurnUseCard = function(self)
	if self.player:getMark("@sp_chibi") == 0 then return end
	return sgs.Card_Parse("#sp_chibiCard:.:")
end

sgs.ai_skill_use_func["#sp_chibiCard"] = function(card, use, self)
	local good = 0
	for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
		if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Fire) and not self:cantbeHurt(p) and not self:needToLoseHp(p,self.player,nil) then
			good = good + 1
			if self:isWeak(p) then
				good = good + 2
			end
			if not self:cantDamageMore(p, self.player) and self.player:hasSkill("sp_huoshen") and self.player:inMyAttackRange(p) then
				good = good + 1
			end
		end
		if self:isFriend(p) and self:damageIsEffective(p, sgs.DamageStruct_Fire) and not self:needToLoseHp(p,self.player,nil) then
			good = good - 1
			if self:isWeak(p) then
				good = good - 2
			end
			if not self:cantDamageMore(p, self.player) and self.player:hasSkill("sp_huoshen") and self.player:inMyAttackRange(p) then
				good = good - 1
			end
		end
	end
	if not self.player:hasSkill("sp_shenzi") and self.player:hasSkill("sp_qiangu") then good = good + 3 end
	if good > 0 then
		use.card = card
		return
	end
end

sgs.ai_use_value.sp_chibiCard = 8.5
sgs.ai_use_priority.sp_chibiCard = 9.5
sgs.ai_card_intention.sp_chibiCard = 80

sgs.ai_ajustdamage_from.sp_huoshen         = function(self, from, to, card, nature)
	if from:inMyAttackRange(to) and nature == "F" then
		return 1
	end
end
sgs.ai_skill_invoke.sp_qinmo = function(self, data)
	if #self.toUse<2 and self:getOverflow() <= 0 then
		return sgs.ai_skill_choice.sp_qinmo(self, "sp_qinmoloseHp+sp_qinmoaddHp") ~= "cancel"
	end
	return false
end


sgs.ai_skill_choice.sp_qinmo = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "sp_qinmoaddHp") then
		local arr1, arr2 = self:getWoundedFriend(false, true)
		local target = nil

		if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
		if target then
			self.sp_qinmo = target
			return "sp_qinmoaddHp"
		end
	end
	if table.contains(items, "sp_qinmoloseHp") then
		
		local target = nil
		self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not hasZhaxiangEffect(enemy) then
				target = enemy
				break
			end
		end
		
		if target then
			self.sp_qinmo = target
			return "sp_qinmoloseHp"
		end
	end
	return "cancel"
end
sgs.ai_skill_playerchosen.sp_qinmo = function(self, targets)
	if self.sp_qinmo then return self.sp_qinmo end
	if self.player:hasFlag("sp_qinmoloseHp") then
		self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not hasZhaxiangEffect(enemy) then
				return enemy
			end
		end
	end
	local arr1, arr2 = self:getWoundedFriend(false, true)
	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then return arr1[1] end
	return targets[1]
end


  --“神姿”AI
sgs.ai_skill_choice.sp_shenzi = function(self, choices, data)
	local target = sgs.ai_skill_playerchosen.sp_shenzi(self, self.room:getOtherPlayers(self.player))
	if target ~= nil and self.player:inMyAttackRange(target) and not self:cantDamageMore(self.player,target) and self.player:hasSkill("sp_huoshen") then return "sp_shenzi0card" end
    if (self.player:isKongcheng() or self.player:getHp() - self.player:getHandcardNum() > 1) and self.player:getHp() > 1 then return "sp_shenzi4cards" end
	if self:getOverflow() > 2 then return "sp_shenzi1card" end
	return "sp_shenzi3cards"
end
sgs.ai_skill_playerchosen.sp_shenzi = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Fire) and not self:cantbeHurt(p) and self:isWeak(p) and self.player:inMyAttackRange(p) then
		    return p 
		end
	end
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Fire) and not self:cantbeHurt(p) and self:isWeak(p) then
		    return p 
		end
	end
	return nil
end

--

--22 天神·诸葛
  --“祈天”AI
sgs.ai_skill_invoke.sp_zhengshen = true
sgs.ai_skill_invoke["@sp_zhengshenGC"] = function(self, data)
	if sgs.ai_skill_use["@@sp_zhengshenGC!"] == "." then return false end
	return true
end
sgs.ai_skill_use["@@sp_zhengshenGC!"] = function(self,prompt)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local targets = self.room:getOtherPlayers(self.player)
	local c,to = self:getCardNeedPlayer(cards, false, targets)
	if c and to then return "#sp_zhengshenGCCard:"..c:getEffectiveId()..":->"..to:objectName() end
	for _, friend in ipairs(self.friends_noself) do
		for _,h in sgs.list(self.player:getHandcards())do
			if self:willUse(self.player, h) and h:isAvailable(self.player) then continue end
			return "#sp_zhengshenGCCard:"..h:getEffectiveId()..":->"..friend:objectName()
		end
	end
	
	return "."
end
function sgs.ai_cardneed.sp_zhishen(to,card)
	return card:isNDTrick()
end
sgs.ai_card_priority.sp_zhishen = function(self,card,v)
	if self.useValue
	and card:isNDTrick()
	then v = v+3 end
end

sgs.ai_ajustdamage_to["@sp_crazywind"] = function(self,from,to,card,nature)
	if nature=="F"
	then return 1 end
end
sgs.ai_ajustdamage_to["@sp_fog"] = function(self,from,to,card,nature)
	if nature~="T"
	then return -99 end
end

sgs.ai_skill_invoke.sp_qitian = true

sgs.ai_skill_choice.sp_qitian = function(self, choices, data)
    if self.player:getMark("&ShenZhi") < 4 then return "1" end
	return "4"
end

sgs.ai_skill_playerchosen.sp_qitian = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and (((self.player:hasFlag("sp_qitian_Club") and self:damageIsEffective(p, sgs.DamageStruct_Fire))) or (self:damageIsEffective(p, sgs.DamageStruct_Thunder) and self:doDisCard(p, "he") )) and not self:cantbeHurt(p) then
		    return p 
		end
	end
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and self:doDisCard(p, "he") and not self:cantbeHurt(p) then
		    return p 
		end
	end
	return nil
end

local sp_guimen_skill = {}
sp_guimen_skill.name = "sp_guimen"
table.insert(sgs.ai_skills, sp_guimen_skill)
sp_guimen_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sp_guimenCard:.:")
end

sgs.ai_skill_use_func["#sp_guimenCard"] = function(card, use, self)
	local good = 0
	for _, p in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
		if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Thunder) and not self:cantbeHurt(p) and not self:needToLoseHp(p,self.player,nil) then
			good = good + 1
			if self:isWeak(p) then
				good = good + 2
			end
		end
		if self:isFriend(p) and self:damageIsEffective(p, sgs.DamageStruct_Thunder) and not self:needToLoseHp(p,self.player,nil) then
			good = good - 1
			if self:isWeak(p) then
				good = good - 2
			end
		end
	end
	if good > 0 then
		use.card = card
		return
	end
end

sgs.ai_use_value.sp_guimenCard = 8.5
sgs.ai_use_priority.sp_guimenCard = 9.5



--

--23 君神·曹操
  --“煮酒”AI
sgs.ai_skill_invoke.sp_zhujiu = true

sgs.ai_skill_playerchosen.sp_zhujiu = function(self, targets)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")

	for _,enemy in sgs.list(targets)do
		if self:isEnemy(enemy) and self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy)==enemy:getHandcardNum() then
				allknown = allknown+1
			end
			if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
				or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
				or (not enemy_max_card and max_point>10) then
				return enemy
			end
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self.player:canPindian(p) then return p end
	end
end
sgs.ai_cardneed.sp_zhujiu = sgs.ai_cardneed.bignumber

local sp_zhujiu_skill = {}
sp_zhujiu_skill.name = "sp_zhujiu"
table.insert(sgs.ai_skills, sp_zhujiu_skill)
sp_zhujiu_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sp_zhujiuCard:.:")
end

sgs.ai_skill_use_func["#sp_zhujiuCard"] = function(card, use, self)
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	self:sort(self.enemies, "handcard")

	for _, enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy) and enemy:getMark("&qingmei_zhujiu-PlayClear") > 0 then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy)==enemy:getHandcardNum() then
				allknown = allknown+1
			end
			if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
				or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
				or (not enemy_max_card and max_point>10) then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if self.player:hasSkill("sp_gexing") and self.player:getMark("@duangexing") > 0 and self.player:getMark("sp_zhujiuFQC") < 10 then
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 0 and self.player:canPindian(enemy) and enemy:getMark("&qingmei_zhujiu-PlayClear") > 0 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.sp_zhujiuCard = 8.5
sgs.ai_use_priority.sp_zhujiuCard = 9.5
sgs.ai_card_intention.sp_zhujiuCard = 80

sgs.ai_skill_invoke["@sp_zhujiugetPindianCards"] = true

sgs.ai_skill_invoke.sp_gexing = true

local sp_tianxia_skill = {}
sp_tianxia_skill.name = "sp_tianxia"
table.insert(sgs.ai_skills, sp_tianxia_skill)
sp_tianxia_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#sp_tianxiaCard") then
		return sgs.Card_Parse("#sp_tianxiaCard:.:")
	end
end

sgs.ai_skill_use_func["#sp_tianxiaCard"] = function(card, use, self)
	use.card = card
	return
end

sgs.ai_use_value["sp_tianxiaCard"] = sgs.ai_use_value.ExNihilo - 0.1
sgs.ai_use_priority["sp_tianxiaCard"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_skill_choice["sp_tianxia"] = function(self, choices, data)
	if self.player:getMaxHp() >= 4 then return "3" end
	if self.player:getLostHp() >= 2 and self:isWeak() then return "3" end
	if self.player:getHp() + self:getAllPeachNum() > 0 then return "1" end
	return "2"
end
sgs.ai_skill_choice["sp_tianxiaOther"] = function(self, choices, data)
	local items = choices:split("+")
	local current = self.room:getCurrent()
	if self:needToLoseHp(self.player, current) then return "2" end
	if table.contains(items, "1") then return "1" end
	return "2"
end
sgs.ai_skill_choice["sp_tianxiaSelf"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:damageIsEffective(target, sgs.DamageStruct_Normal) and not self:cantbeHurt(target) and self:canDamage(target, self.player) then return "2" end
	if table.contains(items, "1") then return "1" end
	return "2"
end

--24 战神·吕布
  --“武极”AI
sgs.ai_skill_invoke["sp_wuji"] = true

sgs.ai_skill_choice["sp_wuji"] = function(self, choices, data)
    if self.player:getMaxHp() <= 3 then return "cancel" end
	if self.player:getHandcardNum() <= 3 then return "1" end
	return "2"
end


local sp_feijiang_skill = {}
sp_feijiang_skill.name = "sp_feijiang"
table.insert(sgs.ai_skills, sp_feijiang_skill)
sp_feijiang_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sp_feijiangCard:.:")
end

sgs.ai_skill_use_func["#sp_feijiangCard"] = function(card, use, self)
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	self:sort(self.enemies, "handcard")
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, false) and not self:slashProhibit(slash, enemy) and self:getDefenseSlash(enemy) <= 2
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
			and enemy:objectName() ~= self.player:objectName() and self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy)==enemy:getHandcardNum() then
				allknown = allknown+1
			end
			if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
				or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
				or (not enemy_max_card and max_point>10) then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
    end
end

sgs.ai_use_value.sp_feijiangCard = 8.5
sgs.ai_use_priority.sp_feijiangCard = 2.4
sgs.ai_card_intention.sp_feijiangCard = 80


  --“猛冠”AI
local sp_mengguan_skill = {}
sp_mengguan_skill.name = "sp_mengguan"
table.insert(sgs.ai_skills, sp_mengguan_skill)
sp_mengguan_skill.getTurnUseCard = function(self)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	for _, c in ipairs(cards) do
	    if c:isKindOf("Weapon") then
		    card = c
			break
		end
	end
	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("duel:sp_mengguan[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

  --“独勇”AI
sgs.ai_skill_invoke.sp_duyong = function(self, data)
    if self.player:isNude() then return false end
	local target = data:toDamage().to
	return not self:isFriend(target) and not self:cantDamageMore(target, self.player) and self:damageIsEffective(target, data:toDamage().card, self.player)
end

sgs.ai_ajustdamage_from.sp_duyong = function(self,from,to,card,nature)
	if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and not beFriend(to,from) and from:canDiscard(from, "he")
	then return 1 end
end


local sp_hengsaoqianjun_skill = {}
sp_hengsaoqianjun_skill.name = "sp_hengsaoqianjun"
table.insert(sgs.ai_skills,sp_hengsaoqianjun_skill)
sp_hengsaoqianjun_skill.getTurnUseCard = function(self)
	local newcards = {}
	local cards = self:addHandPile()
	local color = {}
	cards = self:sortByUseValue(cards,nil,true)
	for _,card in sgs.list(cards)do
		if isCard("Peach",card,self.player)
		or isCard("ExNihilo",card,self.player) and self.player:getPhase()<=sgs.Player_Play
		then continue end
		if table.contains(color, card:getColorString()) then continue end
		table.insert(newcards,card)
		table.insert(color,card:getColorString())
	end
	if #newcards<2
	or #cards<self.player:getHp() and self.player:getHp()<5
	and not self:needKongcheng() then return end
	local slashs = {}
	local newcards2 = InsertList({},newcards)
	for _,c1 in sgs.list(newcards)do
		if #slashs>#newcards/2 or #slashs>3 then break end
		table.removeOne(newcards2,c1)
		for _,c2 in sgs.list(newcards2)do
			local dc = sgs.Card_Parse("slash:sp_hengsaoqianjun[no_suit:0]="..c1:getId().."+"..c2:getId())
			if dc:isAvailable(self.player) then table.insert(slashs,dc) end
		end
	end
	return #slashs>0 and slashs
end

sgs.ai_ajustdamage_from.sp_hengsaoqianjun = function(self,from,to,card,nature)
	if card and card:isKindOf("Slash") and from:hasFlag("sp_hengsaoqianjunDMGbuff") and card:getSkillName() == "sp_hengsaoqianjun"
	then return 1 end
end

sgs.ai_skill_playerschosen.sp_hengsaoqianjun = function(self, targets, max, min)
	targets = sgs.QList2Table(targets)
	local tos = {}
	local use = self.room:getTag("sp_hengsaoqianjun"):toCardUse()
	local dummy_use = self:aiUseCard(use.card, dummy(true, 99, use.to))
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			if table.contains(targets,p) and #tos<max then
				table.insert(tos,p)
			end
		end
	end
    return tos
end
sgs.ai_skill_choice["sp_hengsaoqianjun"] = function(self, choices, data)
	local use = self.room:getTag("sp_hengsaoqianjun"):toCardUse()
	local extra_targets = self.room:getCardTargets(self.player, use.card, use.to)
	if sgs.ai_skill_playerschosen.sp_hengsaoqianjun(self, extra_targets, 2, 0) ~= {} then
		if self.player:getMaxHp() >= 4 then return "3" end
		return "2"
	end
	return "1"
end
sgs.ai_card_priority.sp_hengsaoqianjun = function(self,card)
	if card:getSkillName()=="sp_hengsaoqianjun"
	then
		if self.useValue
		then return 1 end
		return -1
	end
end



--25 枪神·赵云（这玩意还需要AI！？）
  --“孤胆”AI

sgs.ai_guhuo_card.sp_qijin = function(self,toname,class_name)
	if self:getCardsNum(class_name)<1 and self.player:getMark("&canuse_qijin") > 0 and self.player:getMaxHp() > 1
	then return "#sp_qijinCard:.:"..toname end
end


sp_lingyun_skill = {}
sp_lingyun_skill.name = "sp_lingyun"
table.insert(sgs.ai_skills, sp_lingyun_skill)
sp_lingyun_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#sp_lingyunCard") then return end
	if self.player:getMark("@sp_lingyunAI") == 1 then return end
	local card = sgs.Card_Parse("#sp_lingyunCard:.:")
	

	return card
end

sgs.ai_skill_use_func["#sp_lingyunCard"] = function(card, use, self)
		use.card = card
end
sgs.ai_use_priority["sp_lingyunCard"] = sgs.ai_use_priority.Slash + 5.1

sgs.ai_skill_choice["sp_gudan"] = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "2and0") and self.player:getLostHp() > 2 then
		return "2and0"
	end
	return "1and0"
end

local sp_danqi_skill={}
sp_danqi_skill.name="sp_danqi"
table.insert(sgs.ai_skills,sp_danqi_skill)
sp_danqi_skill.getTurnUseCard=function(self)
	local cards = self:addHandPile()
	self:sortByUseValue(cards,true)
	if self.player:getMark("&canuse_danqi") > 0 then
		local usable_cards = sgs.QList2Table(self.player:getCards("he"))
		for _,id in sgs.list(self.player:getHandPile())do
			table.insert(usable_cards,sgs.Sanguosha:getCard(id))
		end
		local two_analeptic_cards = {}
		local two_peach_cards = {}
		for _,c in sgs.list(usable_cards)do
			if c:isKindOf("Analeptic") and #two_analeptic_cards<2 then
				table.insert(two_analeptic_cards,c:getEffectiveId())
			elseif c:isKindOf("Peach") and #two_peach_cards<2 then
				table.insert(two_peach_cards,c:getEffectiveId())
			end
		end
		if #two_analeptic_cards==2 and self:slashIsAvailable() and self:getOverflow()>1 then
			return sgs.Card_Parse(("slash:sp_danqi_buffs[%s:%s]=%d+%d"):format("to_be_decided",0,two_analeptic_cards[1],two_analeptic_cards[2]))
		end
		if #two_peach_cards==2 and sgs.Analeptic_IsAvailable(self.player) and self:getOverflow()>1 then
			return sgs.Card_Parse(("analeptic:sp_danqi_buffs[%s:%s]=%d+%d"):format("to_be_decided",0,two_peach_cards[1],two_peach_cards[2]))
		end

	end

	if (self.player:getMark("&canuse_danqi") > 0 or self.player:getLostHp() > 0) then
		for _,c in ipairs(cards)do
			if c:isKindOf("Analeptic") then
				return sgs.Card_Parse(("slash:sp_danqi[%s:%s]=%d"):format(c:getSuitString(),c:getNumberString(),c:getEffectiveId()))
			end
		end
		for _,c in ipairs(cards)do
			if c:isKindOf("Peach") then
				return sgs.Analeptic_IsAvailable(self.player) and sgs.Card_Parse(("analeptic:sp_danqi[%s:%s]=%d"):format(c:getSuitString(),c:getNumberString(),c:getEffectiveId()))
			end
		end
		for _,c in ipairs(cards)do
			if c:isKindOf("Jink") and (self.player:getLostHp() > 1 or self.player:getMark("&canuse_danqi") > 0) then
				return sgs.Card_Parse(("peach:sp_danqi[%s:%s]=%d"):format(c:getSuitString(),c:getNumberString(),c:getEffectiveId()))
			end
		end
	end
end

sgs.ai_view_as.sp_danqi = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceHand and (player:getMark("&canuse_danqi") > 0 or player:getLostHp() > 0) then
		if card:isKindOf("Jink") then
			return ("peach:sp_danqi[%s:%s]=%d"):format(suit,number,card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:sp_danqi[%s:%s]=%d"):format(suit,number,card_id)
		elseif card:isKindOf("Peach") then
			return ("analeptic:sp_danqi[%s:%s]=%d"):format(suit,number,card_id)
		elseif card:isKindOf("Analeptic") and (player:getMark("&canuse_danqi") > 0 or player:getLostHp() > 0) then
			return ("slash:sp_danqi[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

sgs.sp_danqi_keep_value = sgs.longdan_keep_value

sgs.ai_ajustdamage_from.sp_danqi = function(self,from,to,slash,nature)
	if slash and slash:isKindOf("Slash") then 
		local x = 0
		if slash:hasFlag("drank") then
			x = x + from:getMark("sp_danqi_AnalepticBuff")
		end
		if slash:hasFlag("sp_danqi") then
			x = x + from:getMark("sp_danqi_SlashBuff")
		end
		return x
	end
end
sgs.ai_use_revises.sp_danqi = function(self,card,use)
	if card:isKindOf("Slash") and (card:getSkillName() == "sp_danqi" or card:getSkillName() == "sp_danqi_buffs") then
		card:setFlags("Qinggang")
	end
end

sgs.ai_skill_choice["sp_danqi"] = function(self, choices, data)
	local items = choices:split("+")
	local use = data:toCardUse()
	local buff = true
	if use.card:getSkillName() == "sp_danqi" then
		buff = false
	end
	if use.card:isKindOf("Slash") then
		for _, p in sgs.qlist(use.to) do
			if self:isFriend(p) or self:cantDamageMore(p, self.player) then return "cancel" end
		end
		for _, p in sgs.qlist(use.to) do
			if getCardsNum("Jink",p,self.player) < 1 or self:canLiegong(p, self.player) then
				if table.contains(items, "slash2") and self.player:getLostHp() > 1  then
					return "slash2"
				end
			end
		end
		for _, p in sgs.qlist(use.to) do
			if getCardsNum("Jink",p,self.player) < 1 or self:canLiegong(p, self.player) then
				if table.contains(items, "slash1") and (buff or self.player:getLostHp() > 1) then
					return "slash1"
				end
			end
		end
	elseif use.card:isKindOf("Peach") then
		for _, p in sgs.qlist(use.to) do
			if self:isFriend(p) and self:canDraw(p, self.player) then
				if table.contains(items, "peach2") and buff then
					return "peach2"
				end
			end
		end
		for _, p in sgs.qlist(use.to) do
			if self:isFriend(p) and self:canDraw(p, self.player) then
				if table.contains(items, "peach1") then
					return "peach1"
				end
			end
		end
	elseif use.card:isKindOf("Analeptic") then
		if table.contains(items, "analeptic2") and (buff and self.player:getLostHp() >= 1)  then
			return "analeptic2"
		end
		if table.contains(items, "analeptic1") and (buff or self.player:getLostHp() > 1)  then
			return "analeptic1"
		end
	end
	return "cancel"
end


sgs.ai_card_priority.sp_danqi = function(self,card)
	if (card:getSkillName() == "sp_danqi" or card:getSkillName() == "sp_danqi_buffs")
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_skill_invoke["sp_danqi_jink"] = function(self, data)
	local target = data:toPlayer()
	return target and self:doDisCard(target, "he")
end

sgs.ai_skill_cardchosen.sp_lingyun = function(self,who,flags)
	return -1
end


--

--26 暗神·司马
  --“装病”AI
sgs.ai_can_damagehp.sp_zhuangbing = function(self,from,card,to)
	return to:inYinniState() and sgs.ai_skill_invoke.sp_zhuangbing(self)
end
sgs.ai_skill_invoke.sp_zhuangbing = function(self, data)
	local target = self.room:getCurrent()
	return not self:isFriend(target)
end

sgs.ai_ajustdamage_to.sp_zhuangbing   = function(self, from, to, card, nature)
	if not to:faceUp()then
		return -99
	end
end
sgs.ai_skill_invoke.sp_yinren = function(self, data)
	return (self:isWeak()and self.player:getPile("sp_yinren"):length() < 2) or (self.player:hasSkill("sp_zhengbian") and self.player:getMark("@sp_zhengbian") > 0 and self.player:getPile("sp_yinren"):length() < 2 and not self.player:isKongcheng())
end
sgs.ai_skill_discard.sp_yinren = function(self,max,min)
	local to_cards = {}
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards)
	local x = self:getOverflow()
	if not self.player:faceUp() then x = self.player:getHandcardNum() end
   	for _,h in sgs.list(cards)do
   		if #to_cards>=min then break end
		table.insert(to_cards,h:getEffectiveId())
	end
	return to_cards
end

local sp_shenmou_skill = {}
sp_shenmou_skill.name = "sp_shenmou"
table.insert(sgs.ai_skills, sp_shenmou_skill)
sp_shenmou_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sp_shenmouCard:.:")
end

sgs.ai_skill_use_func["#sp_shenmouCard"] = function(card, use, self)
	use.card = card
	return
end
sgs.ai_use_priority.sp_shenmouCard = 9.5

  --AI获得“死士”牌：
local sp_sishi_skill = {}
sp_sishi_skill.name = "sp_sishi"
table.insert(sgs.ai_skills, sp_sishi_skill)
sp_sishi_skill.getTurnUseCard = function(self)
	if self.player:getPile("sp_ss"):length() < 2 then return end
	return sgs.Card_Parse("#sp_sishiCard:.:")
end

sgs.ai_skill_use_func["#sp_sishiCard"] = function(card, use, self)
    if self.player:getPile("sp_ss"):length() >= 2 and self.player:getHp() > 1 then --上古经典一血两牌理念
        use.card = card
	    return
	end
end

sgs.ai_use_value.sp_sishiCard = 8.5
sgs.ai_use_priority.sp_sishiCard = 9.5
sgs.ai_card_intention.sp_sishiCard = -80

sgs.ai_skill_invoke.sp_yinyang = function(self, data)
	return #self.enemies > 0
end
sgs.ai_skill_playerchosen.sp_yinyang = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if self:needToLoseHp(friend) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "he") then
			return friend
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he") then
			return enemy
		end
	end
	return targets:first()
end


local sp_zhengbian_skill = {}
sp_zhengbian_skill.name = "sp_zhengbian"
table.insert(sgs.ai_skills,sp_zhengbian_skill)
sp_zhengbian_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#sp_zhengbianCard:.:")
end

sgs.ai_skill_use_func["#sp_zhengbianCard"] = function(card,use,self)
	local slashes = self:getCards("Slash")
	for _,e in sgs.list(self.player:getEquips())do
		for _,slash in sgs.list(table.copyFrom(slashes))do
			if slash:getEffectiveId()==e:getId()
			or slash:getSkillName()==e:objectName()
			or not slash:isAvailable(self.player)
			then table.removeOne(slashes,slash) end
		end
	end
	if #slashes+self.player:getPile("sp_ss"):length()<1 then return end
	self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		local n = 0
		for _,slash in sgs.list(slashes)do
			local d = self:aiUseCard(slash)
			if d.card and d.to:contains(enemy) then
				n = n+1
				if n>=enemy:getHp() then
					use.card = card
					use.to:append(enemy)
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["sp_zhengbianCard"] = sgs.ai_use_priority.Slash+0.5
sgs.ai_use_value["sp_zhengbianCard"] = 3

local sp_kongju_skill = {}
sp_kongju_skill.name = "sp_kongju"
table.insert(sgs.ai_skills,sp_kongju_skill)
sp_kongju_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#sp_kongjuCard:.:")
end

sgs.ai_skill_use_func["#sp_kongjuCard"] = function(card,use,self)
	use.card = card
	return
end
sgs.ai_skill_choice["sp_kongju"] = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "lose1MaxHptochosetodo") and self.player:getMaxHp() >= 4 and self.player:isWounded() then
		return "lose1MaxHptochosetodo"
	end
	if table.contains(items, "randomtodo") then
		return "randomtodo"
	end
	if table.contains(items, "one") then
		if sgs.ai_skill_invoke.peiqi(self,ToData())	then
			return "one"
		end
	end
	if table.contains(items, "two") then
		for _, p in ipairs(self.enemies) do
			if self:doDisCard(p, "h", true) then
				return "two"
			end
		end
	end
	return items[#items]
end

sgs.ai_skill_playerchosen.sp_kongju = function(self,players)
	local choice = self.room:getTag("sp_kongju_choose"):toString()
	if choice == "one" then
		local from = self.room:getTag("sp_kongjuOneTarget"):toPlayer()
		if from then
			for _,target in sgs.list(players)do
				if target:objectName()==self.peiqiData.to:objectName()
				then return target end
			end
		else
			if sgs.ai_skill_invoke.peiqi(self,ToData())
			then
				for _,target in sgs.list(players)do
					if target:objectName()==self.peiqiData.from:objectName()
					then return target end
				end
			end
		end
	elseif choice == "two" then
		local from = self.room:getTag("sp_kongjuOneTarget"):toPlayer()
		if from then
			return self.player
		else
			for _,target in sgs.list(players)do
				if self:doDisCard(target,"h", true) then
					return target
				end
			end
		end
	elseif choice == "three" then
		for _,target in sgs.list(players)do
			if self:isEnemy(target) and target:getMarkNames():length() > 0 then
				return target
			end
		end
	end
end


--

--27 剑神·刘备
  --“英杰”AI
sgs.ai_skill_invoke["@sp_yingjie_xingxia"] = true
sgs.ai_skill_playerchosen["sp_yingjie"] = function(self, targets)
    targets = sgs.QList2Table(targets)
	if self.player:hasSkill("sp_rongma") and self.player:getMark("&sp_rongma") < 40 then
		return self.player
	end
	if self:findPlayerToDraw(true,1,false) then return self:findPlayerToDraw(true,1,false) end
	for _, p in ipairs(targets) do
	    if self:isFriend(p) and self:canDraw(p, self.player) then
		    return p
		end
	end
    return self.player
end
sgs.ai_playerchosen_intention["sp_yingjie"] = -50

sgs.ai_skill_use["@@sp_yingjie!"] = function(self,prompt)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local targets = self.room:getOtherPlayers(self.player)
	local c,to = self:getCardNeedPlayer(cards, false, targets)
	if c and to then return "#sp_yingjieCard:"..c:getEffectiveId()..":->"..to:objectName() end
	for _, friend in ipairs(self.friends_noself) do
		for _,h in sgs.list(self.player:getHandcards())do
			if self:willUse(self.player, h) and h:isAvailable(self.player) then continue end
			return "#sp_yingjieCard:"..h:getEffectiveId()..":->"..friend:objectName()
		end
	end
	
	return "."
end
sgs.ai_card_intention.sp_yingjieCard     = -50

sgs.ai_skill_invoke["@sp_yingjie_zhangyi"] = true




  --“远志”AI
sgs.ai_skill_playerchosen.sp_yuanzhi = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not p:isKongcheng() then
			return p
		end
	end
end

local sp_yuanzhi_skill = {}
sp_yuanzhi_skill.name = "sp_yuanzhi"
table.insert(sgs.ai_skills, sp_yuanzhi_skill)
sp_yuanzhi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#sp_yuanzhiCard") or self.player:isKongcheng() and self.player:getMark("&sp_yuanzhiFQC") <= self.player:getMark("sp_yuanzhiUF") then return end
	return sgs.Card_Parse("#sp_yuanzhiCard:.:")
end

sgs.ai_skill_use_func["#sp_yuanzhiCard"] = function(card, use, self)
    if not self.player:hasUsed("#sp_yuanzhiCard") and not self.player:isKongcheng() and self.player:getMark("&sp_yuanzhiFQC") > self.player:getMark("sp_yuanzhiUF") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 and self.player:canPindian(enemy) then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.sp_yuanzhiCard = 8.5
sgs.ai_use_priority.sp_yuanzhiCard = 9.5
sgs.ai_card_intention.sp_yuanzhiCard = 80

sgs.ai_skill_choice.sp_yuanzhi = function(self, choices, data)
return "2" end

sgs.ai_cardneed.sp_yuanzhi = sgs.ai_cardneed.bignumber

--28 军神·陆逊
  --待补充（可以写，但会添乱）

sgs.ai_skill_invoke["@sp_zaoyan_yang"] = function(self, data)
	if sgs.ai_skill_cardask["@sp_zaoyan-red"](self,data, ".|red|.|.") ~= "." then
		return true
	end
	return false
end
sgs.ai_skill_invoke["@sp_zaoyan_yin"] = function(self, data)
	if sgs.ai_skill_cardask["@sp_zaoyan-black"](self,data, ".|black|.|.") ~= "." then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@sp_zaoyan-red"] = function(self,data,pattern,target)
	local use = data:toCardUse()
	local target = use.to:first()
	local cards = sgs.QList2Table(self.player:getCards("eh"))
	self:sortByKeepValue(cards)
	if self:damageIsEffective(target, sgs.DamageStruct_Fire) then
		if (self:isFriend(target) and self:needToLoseHp(target, use.from)) or (self:isEnemy(target) and not self:cantbeHurt(target)) then
			for _,h in sgs.list(cards)do
				if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
				then return h:getEffectiveId() end
				if h:isRed()
				then return h:getEffectiveId() end
			end
			return self:getCardId(pattern)
		end
	end	
	return "."
end
sgs.ai_skill_cardask["@sp_zaoyan-black"] = function(self,data,pattern,target)
	local use = data:toCardUse()
	local target = use.to:first()
	local cards = sgs.QList2Table(self.player:getCards("eh"))
	self:sortByKeepValue(cards)
	if (self:isFriend(target) and (self:needToLoseHp(target, use.from) or hasZhaxiangEffect(target))) or (self:isEnemy(target) and not hasZhaxiangEffect(target)) then
		for _,h in sgs.list(cards)do
			if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
			then return h:getEffectiveId() end
			if h:isBlack()
			then return h:getEffectiveId() end
		end
		return self:getCardId(pattern)
	end
	return "."
end
sgs.ai_skill_use["@@sp_fenying"] = function(self, prompt, method)
	local damage = self.room:getTag("sp_fenying"):toDamage()
	if self:isFriend(damage.to) then return "." end
	if not self:damageIsEffective(damage.to, sgs.DamageStruct_Fire) then return "." end
	if not self:damageIsEffective(damage.to, damage.card, damage.from) then return "." end
	if self:cantDamageMore(damage.to, damage.from) then return "." end
	if damage.damage <= 1 and damage.to:getHp() > damage.damage * 2 and not self:isWeak()  then return "." end
	if self.player:getEquips():length() < damage.damage * 2 and not self:isWeak()  then return "." end
	local targets = {}

	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Fire) and not self:cantbeHurt(enemy) and not enemy:isChained() then
			table.insert(targets, enemy:objectName())
		end
	end
	for _, friend in ipairs(self.friends) do
		if self:damageIsEffective(friend, sgs.DamageStruct_Fire) and friend:isChained() and not self:needToLoseHp(friend) then
			table.insert(targets, friend:objectName())
		end
	end
	local give_all_cards = {}
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if #give_all_cards < #targets then
			table.insert(give_all_cards, c:getEffectiveId())
		end
	end
	if #give_all_cards < #targets then
		while #give_all_cards < #targets do
			table.removeOne(targets,targets[#targets])
		end
	end
	if #targets < #give_all_cards then
		while #targets < #give_all_cards do
			table.removeOne(give_all_cards,give_all_cards[#give_all_cards])
		end
	end
	if #targets > 0 and #give_all_cards == #targets then
		return "#sp_fenyingCard:" .. table.concat(give_all_cards, "+") .. ":->" .. table.concat(targets, "+")
	end
	return "."
end

--

--29 孤神·张辽
  --......


sgs.ai_skill_use["@@sp_qiangxi"] = function(self,prompt)
	self:sort(self.enemies,"handcard_defense")
	local sp_qiangxi_mark = self.player:getMark("sp_qiangxi")
	local targets = {}

	local add_player = function (player,isfriend)
		if player:getHandcardNum()==0 or player:objectName()==self.player:objectName() then return #targets end
		if self:objectiveLevel(player)==0 and player:isLord() and sgs.playerRoles["rebel"]>1 then return #targets end

		local f = false
		for _,c in ipairs(targets)do
			if c==player:objectName() then
				f = true
				break
			end
		end

		if not f then table.insert(targets,player:objectName()) end

		if isfriend and isfriend==1 then
			self.player:setFlags("sp_qiangxi_isfriend_"..player:objectName())
		end
		return #targets
	end

	local parsesp_qiangxiCard = function()
		if #targets==0 then return "." end
		local s = table.concat(targets,"+")
		return "#sp_qiangxiCard:.:->"..s
	end

	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) and sgs.turncount<=1 and not lord:isKongcheng() then
		if add_player(lord)==sp_qiangxi_mark then return parsesp_qiangxiCard() end
	end


	for i = 1,#self.enemies,1 do
		local p = self.enemies[i]
		local cards = sgs.QList2Table(p:getHandcards())
		local flag = string.format("%s_%s_%s","visible",self.player:objectName(),p:objectName())
		for _,card in ipairs(cards)do
			if (card:hasFlag("visible") or card:hasFlag(flag)) and (card:isKindOf("Peach") or card:isKindOf("Nullification") or card:isKindOf("Analeptic") ) then
				if add_player(p)==sp_qiangxi_mark  then return parsesp_qiangxiCard() end
			end
		end
	end

	for i = 1,#self.enemies,1 do
		local p = self.enemies[i]
		if p:hasSkills("jijiu|qingnang|xinzhan|leiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then
			if add_player(p)==sp_qiangxi_mark  then return parsesp_qiangxiCard() end
		end
	end

	for i = 1,#self.enemies,1 do
		local p = self.enemies[i]
		local x = p:getHandcardNum()
		local good_target = true
		if x==1 and self:needKongcheng(p) then good_target = false end
		if x>=2 and p:hasSkill("tuntian") and p:hasSkill("zaoxian",true) then good_target = false end
		if good_target and add_player(p)==sp_qiangxi_mark then return parsesp_qiangxiCard() end
	end


	local others = self.room:getOtherPlayers(self.player)
	for _,other in sgs.list(others)do
		if self:objectiveLevel(other)>=0 and not (other:hasSkill("tuntian") and other:hasSkill("zaoxian",true)) and add_player(other)==sp_qiangxi_mark then
			return parsesp_qiangxiCard()
		end
	end

	for _,other in sgs.list(others)do
		if self:objectiveLevel(other)>=0 and not (other:hasSkill("tuntian") and other:hasSkill("zaoxian",true)) and math.random(0,5)<=1 and not self:hasSkills("qiaobian") then
			add_player(other)
		end
	end

	return parsesp_qiangxiCard()
end

sgs.ai_card_intention.sp_qiangxiCard = function(self,card,from,tos)
	local lord = getLord(self.player)
	local sp_qiangxi_lord = false
	if sgs.ai_role[from:objectName()]=="neutral" and sgs.ai_role[tos[1]:objectName()]=="neutral" and
		(not tos[2] or sgs.ai_role[tos[2]:objectName()]=="neutral") and lord and not lord:isKongcheng() and
		not (self:needKongcheng(lord) and lord:getHandcardNum()==1 ) and
		self:hasLoseHandcardEffective(lord) and not (lord:hasSkill("tuntian") and lord:hasSkill("zaoxian",true)) and from:aliveCount()>=4 then
			sgs.updateIntention(from,lord,-80)
		return
	end
	if from:getState()=="online" then
		for _,to in ipairs(tos)do
			if to:hasSkill("kongcheng") or to:hasSkill("lianying") or to:hasSkill("zhiji")
				or (to:hasSkill("tuntian") and to:hasSkill("zaoxian")) then
			else
				sgs.updateIntention(from,to,80)
			end
		end
	else
		for _,to in ipairs(tos)do
			if lord and to:objectName()==lord:objectName() then sp_qiangxi_lord = true end
			local intention = from:hasFlag("sp_qiangxi_isfriend_"..to:objectName()) and -5 or 80
			sgs.updateIntention(from,to,intention)
		end
		if sgs.turncount<=1 and not sp_qiangxi_lord and lord and not lord:isKongcheng() and from:getRoom():alivePlayerCount()>2 then
			sgs.updateIntention(from,lord,-80)
		end
	end
end

sgs.ai_ajustdamage_from.sp_liaolai = function(self,from,to,card,nature)
	if to and to:getKingdom() == "wu" then 
		local n = 0
		if from:getHp() < to:getHp() then n = n + 1 end
		if from:getHandcardNum() < to:getHandcardNum() then n = n + 1 end
		return n
	end
end



--

--30 奇神·甘宁
  --“袭营”AI
sgs.ai_skill_playerchosen.sp_lvezhen = function(self, targets)
	targets = sgs.QList2Table(targets)
	local use = self.room:getTag("sp_lvezhen"):toCardUse()
	local dummy_use = self:aiUseCard(use.card, dummy(true, 1, use.to))
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			return p
		end
	end
    return nil
end
sgs.ai_skill_use["@@sp_lvezhen_SSQY"] = function(self, prompt)
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if c:isRed() then
			local acard = sgs.Sanguosha:cloneCard("snatch", sgs.Card_SuitToBeDecided, -1)
			acard:addSubcard(c)
			acard:deleteLater()
			acard:setSkillName("sp_lvezhen")
			local d = self:aiUseCard(acard, dummy())
			if d.card then
				local tos = {}
				for _,p in sgs.list(d.to)do
					table.insert(tos,p:objectName())
				end
				return acard:toString().."->"..table.concat(tos,"+")
			end
		end
	end
	return "."
end
sgs.ai_skill_use["@@sp_lvezhen_GHCQ"] = function(self, prompt)
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if c:isBlack() then
			local acard = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_SuitToBeDecided, -1)
			acard:deleteLater()
			acard:addSubcard(c)
			acard:setSkillName("sp_lvezhen")
			local d = self:aiUseCard(acard, dummy())
			if d.card then
				local tos = {}
				for _,p in sgs.list(d.to)do
					table.insert(tos,p:objectName())
				end
				return acard:toString().."->"..table.concat(tos,"+")
			end
		end
	end
	return "."
end

local sp_lvezhen_skill = {}
sp_lvezhen_skill.name = "sp_lvezhen"
table.insert(sgs.ai_skills,sp_lvezhen_skill)
sp_lvezhen_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sp_lvezhenCard:.:")
end

sgs.ai_skill_use_func["#sp_lvezhenCard"] = function(card,use,self)
	local n = self.player:getChangeSkillState("sp_lvezhen")
	if n == 1 then
		if sgs.ai_skill_use["@@sp_lvezhen_SSQY"](self, "")~= "." then
			use.card = card
			return
		end
	else
		if sgs.ai_skill_use["@@sp_lvezhen_GHCQ"](self, "")~= "." then
			use.card = card
			return
		end
	end
end
sgs.ai_use_priority.sp_lvezhenCard = sgs.ai_use_priority.Dismantlement

local sp_xiying_skill = {}
sp_xiying_skill.name = "sp_xiying"
table.insert(sgs.ai_skills, sp_xiying_skill)
sp_xiying_skill.getTurnUseCard = function(self)
	if self.player:getMark("@sp_xiying") == 0 then return end
	return sgs.Card_Parse("#sp_xiyingCard:.:")
end

sgs.ai_skill_use_func["#sp_xiyingCard"] = function(card, use, self)
    if self.player:getMark("@sp_xiying") > 0 and self.player:getHandcardNum() <= 3 then
        self:sort(self.enemies,"handcard",true)
		local jwfy = self.room:findPlayerBySkillName("shoucheng")
		for _,enemy in sgs.list(self.enemies)do
			if not enemy:hasSkill("kongcheng")
			then
				if (enemy:hasSkill("lianying") or jwfy and self:isFriend(jwfy,enemy)) and self:damageMinusHp(enemy,1)>0
				or enemy:getHp()<3 and self:damageMinusHp(enemy,0)>0 and enemy:getHandcardNum()>0
				or enemy:getHandcardNum()>=enemy:getHp() and enemy:getHp()>2 and self:damageMinusHp(enemy,0)>=-1
				or enemy:getHandcardNum()-enemy:getHp()>2
				then
					use.card = card
					use.to:append(enemy)
					return
				end
			end
		end
		for _,enemy in sgs.list(self.enemies)do
			if enemy:getHandcardNum()>=enemy:getHp()
			then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
		if self:hasCrossbowEffect()
	or self:getCardsNum("Crossbow")>0
	then
		local slash = self:getCard("Slash") or dummyCard()
		for _,enemy in sgs.list(self.enemies)do
			if enemy:isMale()
			and not enemy:isKongcheng()
			and self:slashIsEffective(slash,enemy)
			and self.player:distanceTo(enemy)==1
			and not enemy:hasSkills("fenyong|zhichi|fankui|vsganglie|ganglie|neoganglie|enyuan|nosenyuan|langgu|guixin|kongcheng")
			and self:getCardsNum("Slash")+getKnownCard(enemy,self.player,"Slash")>=3
			then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
	end
end

sgs.ai_use_value.sp_xiyingCard = 9.5
sgs.ai_use_priority.sp_xiyingCard = 3.5
sgs.ai_card_intention.sp_xiyingCard = 30

--
--31 界刘繇
  --“戡难”AI
local fcj_kannan_skill = {}
fcj_kannan_skill.name = "fcj_kannan"
table.insert(sgs.ai_skills, fcj_kannan_skill)
fcj_kannan_skill.getTurnUseCard = function(self)
	if self.player:getMark("fcj_kannanUsed") >= self.player:getHp() or self.player:isKongcheng() then return end
	return sgs.Card_Parse("#fcj_kannanCard:.:")
end

sgs.ai_skill_use_func["#fcj_kannanCard"] = function(card, use, self)
    local cards = sgs.CardList()
	local peach = 0
	for _,c in sgs.qlist(self.player:getHandcards())do
		if isCard("Peach",c,self.player) and peach<2 then
			peach = peach+1
		else
			cards:append(c)
		end
	end
	
	local min_card = self:getMinCard(self.player,cards)
	if min_card then
		local min_point = min_card:getNumber()
		if self.player:hasSkill("tianbian") and min_card:getSuit()==sgs.Card_Heart then min_point = 13 end
		if min_point<7 then
			self:sort(self.friends_noself,"handcard")
			self.friends_noself = sgs.reverse(self.friends_noself)
			for _,p in ipairs(self.friends_noself)do
				if p:hasFlag("fcj_kannanSelected") or not self.player:canPindian(p) then continue end
				if not self:needToThrowLastHandcard(p) then continue end
				self.kannan_card = min_card
				use.card = sgs.Card_Parse("#fcj_kannanCard:.:")
				use.to:append(p) 
				return
			end
			for _,p in ipairs(self.friends_noself)do
				if p:hasFlag("fcj_kannanSelected") or not self.player:canPindian(p) then continue end
				self.kannan_card = min_card
				use.card = sgs.Card_Parse("#fcj_kannanCard:.:")
				use.to:append(p) 
				return
			end
		end
	end
	
	local max_card = self:getMaxCard(self.player,cards)
	if max_card then
		local max_point = max_card:getNumber()
		if self.player:hasSkill("tianbian") and max_card:getSuit()==sgs.Card_Heart then max_point = 13 end
		if max_point>=7 then
			self:sort(self.enemies,"handcard")
			for _,p in ipairs(self.enemies)do
				if p:hasFlag("fcj_kannanSelected") or not self.player:canPindian(p) or not self:doDisCard(p,"h",true) then continue end
				self.kannan_card = max_card
				use.card = sgs.Card_Parse("#fcj_kannanCard:.:")
				use.to:append(p) 
				return
			end
		end
	end
end

sgs.ai_use_value.fcj_kannanCard = 8.5
sgs.ai_use_priority.fcj_kannanCard = 9.5


sgs.ai_skill_choice.fcj_kannan = function(self, choices, data)
	return "1"
end
function sgs.ai_skill_pindian.fcj_kannan(minusecard,self,requestor)
	return self:isFriend(requestor) and self:getMaxCard() or ( self:getMinCard():getNumber()>6 and  minusecard or self:getMinCard() )
end

sgs.ai_ajustdamage_from["&fcj_kannan"] = function(self,from,to,slash,nature)
	if slash and slash:isKindOf("Slash")
	then return from:getMark("&fcj_kannan") end
end


--32 界庞德公
  --“评才”AI（无脑玄剑）
local fcj_pingcai_skill = {}
fcj_pingcai_skill.name = "fcj_pingcai"
table.insert(sgs.ai_skills, fcj_pingcai_skill)
fcj_pingcai_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("fcj_pingcaiCard") then return end
	return sgs.Card_Parse("#fcj_pingcaiCard:.:")
end

sgs.ai_skill_use_func["#fcj_pingcaiCard"] = function(card, use, self)
    if not self.player:hasUsed("#fcj_pingcaiCard") then
        use.card = card
	    return
	end
end

sgs.ai_use_value.fcj_pingcaiCard = 8.5
sgs.ai_use_priority.fcj_pingcaiCard = 9.5
sgs.ai_card_intention.fcj_pingcaiCard = -80

sgs.ai_skill_choice["@fcj_pingcai-ChooseTreasure"] = function(self, choices, data)
	choices = choices:split("+")
	if table.contains(choices,"xuanjian") then
		for _,p in ipairs(self.friends)do
			if self:isWeak(p) and p:getLostHp()>0
			and not self:needKongcheng(p,true)
			then return "xuanjian" end
		end
	end
	if table.contains(choices,"wolong") then
		for _,p in ipairs(self.enemies)do
			if self:damageIsEffective(p,sgs.DamageStruct_Fire,self.player)
			and self:hasHeavyDamage(self.player,nil,p,"F")
			then return "wolong" end
		end
	end
	if table.contains(choices,"xuanjian") then
		for _,p in ipairs(self.enemies)do
			if p:getLostHp()>0
			and self:needKongcheng(p,true)
			and not hasManjuanEffect(p)
			and self:getEnemyNumBySeat(self.player,p,p)>0
			then return "xuanjian" end
		end
	end
	if table.contains(choices,"fengchu")
	and #choices>1 then
		local fengchu = 0
		for _,p in ipairs(self.enemies)do
			if not p:isChained()
			and not p:hasSkill("qianjie")
			then fengchu = fengchu+1 end
		end
		if fengchu<2 then table.removeOne(choices,"fengchu") end
	end
	if table.contains(choices,"shuijing")
	and #choices>1 then
		local shuijing = false
		for _,p in sgs.qlist(self.room:getAlivePlayers())do
			if string.find(sgs.Sanguosha:translate(p:getGeneralName()),"司马徽")
			or string.find(sgs.Sanguosha:translate(p:getGeneral2Name()),"司马徽")
			then shuijing = true break end
		end
		if shuijing then
			local from,card,to = self:moveField(nil,"e")
			if not from or not card or not to then
				table.removeOne(choices,"shuijing")
			end
		else
			if #pingcaiMoveArmor(self)==0 then
				table.removeOne(choices,"shuijing")
			end
		end
	end
	return choices[math.random(1,#choices)]
end

sgs.ai_skill_use["@@fcj_pingcaiFengchu"] = function(self, prompt, method)
	local tos = {}
	self:sort(self.enemies)
	for _,p in ipairs(self.enemies)do
		if not p:isChained() and #tos<4 and not p:hasSkill("qianjie")
		then table.insert(tos,p:objectName()) end
	end
	if #tos > 0 then
		return "#fcj_pingcaiFengchuCard:.:->" ..  table.concat(tos, "+") 
	end
	return "."
end

sgs.ai_skill_use["@@fcj_pingcaiWolong"] = function(self, prompt, method)
	local tos = self:findPlayerToDamage(1,self.player,sgs.DamageStruct_Fire,self.room:getAlivePlayers())
	self:sort(tos)
	local tos2 = {}
	for _,p in ipairs(tos)do
		if #tos2<2 and not self:isFriend(p)
		then table.insert(tos2,p:objectName()) end
	end
	self:sort(self.enemies)
	for _,p in ipairs(self.enemies)do
		if #tos2<2 and not table.contains(tos2,p:objectName())
		then table.insert(tos2,p:objectName()) end
	end
	if #tos2 > 0 then
		return "#fcj_pingcaiWolongCard:.:->" ..  table.concat(tos2, "+") 
	end
	return "."
end
sgs.ai_skill_use["@@fcj_pingcaiShuijing"] = function(self, prompt, method)
	local from,card,to = self:moveField(nil,"e")
	if from then return  "#fcj_pingcaiShuijingCard:.:->" .. from:objectName()  end
	return "."
end
sgs.ai_skill_cardchosen.fcj_pingcaiShuijing = function(self,who,flags)
	local from,card,to = self:moveField(nil,"e")
	if card then return card end
end
sgs.ai_skill_playerchosen.fcj_pingcaiShuijing = function(self,targets)
	local from,card,to = self:moveField(nil,"e")
	if to then return to end
end


sgs.ai_skill_use["@@fcj_pingcaiXuanjian"] = function(self, prompt, method)
	local target
	for _, p in ipairs(self.friends) do --先找体力值过低的队友
	    if self:isFriend(p) and p:getMaxHp() > 2 and p:getHp() == 1 then --不写<=1，跳过周泰这个体力值不与生命危险程度挂钩的
		    target = p
			break
		end
	end
	for _, p in ipairs(self.friends) do --再找受伤队友
	    if self:isFriend(p) and p:isWounded() then
		    target = p
			break
		end
	end
	for _, p in ipairs(self.friends) do --再找健康但手牌过少的队友
	    if self:isFriend(p) and p:getHandcardNum() < 2 then
		    target = p
			break
		end
	end
	for _, p in ipairs(self.friends) do --再找一般健康队友
	    if self:isFriend(p) then
		    target = p
			break
		end
	end
	if target then
		return "#fcj_pingcaiXuanjianCard:.:->" .. target:objectName()
	end
	return "#fcj_pingcaiXuanjianCard:.:->" .. self.player:objectName()
end
sgs.ai_card_intention.fcj_pingcaiXuanjianCard = -80

--33 界陈到
  --“往烈”AI
sgs.ai_skill_invoke.fcj_wanglie = function(self, data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(use.to) do
		if p and self:isFriend(p) then
			return false
		end
	end
	return use.card:isDamageCard()
end

sgs.ai_skill_choice.fcj_wanglie = function(self, choices, data)
	local items = choices:split("+")
	-- if self.player:hasFlag("fcj_wanglie_cantchooseHit") and self.player:hasFlag("fcj_wanglie_cantchooseDamage") then
	-- return "Beishui" end
	if #self.toUse<2 and table.contains(items, "Beishui") then return "Beishui" end
	return "Hit" or "Damage"
end
sgs.ai_ajustdamage_from.fcj_wanglie = function(self, from, to, card, nature)
	if (card and card:hasFlag("fcj_wanglieDamage")) then
		return 1
	end
end


--

--34 界赵统赵广（加强部分为自动发动，无需写ai）

--35 界于禁-旧
  --“毅重”AI
    --给技能就不写了，怕ex到玩家......⁄(⁄ ⁄•⁄ω⁄•⁄ ⁄)⁄

sgs.ai_target_revises.fcj_yizhong = function(to,card,self)
	if card:isBlack() and card:isKindOf("Slash")
	then return true end
end
sgs.ai_skill_invoke.fcj_yizhong = function(self, data)
	return sgs.ai_skill_playerchosen.fcj_yizhong(self, self.room:getOtherPlayers(self.player)) ~= nil
end

sgs.ai_skill_cardask["@fcj_yizhong-invoke"] = function(self,data,pattern)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
		then return h:getEffectiveId() end
		if h:isBlack()
		then return h:getEffectiveId() end
	end
    return "."
end
sgs.ai_skill_playerchosen.fcj_yizhong = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, friend in ipairs(targets) do
		if self:isFriend(friend) and not friend:hasSkill("fcj_yizhong") then
			return friend
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.fcj_yizhong = -50
--

--36 界曹昂
  --“慷慨”AI
local function getKangkaiCard(self,target,data)
	local use = data:toCardUse()
	local weapon,armor,def_horse,off_horse = {},{},{},{}
	for _,card in sgs.qlist(self.player:getHandcards())do
		if card:isKindOf("Weapon") then table.insert(weapon,card)
		elseif card:isKindOf("Armor") then table.insert(armor,card)
		elseif card:isKindOf("DefensiveHorse") then table.insert(def_horse,card)
		elseif card:isKindOf("OffensiveHorse") then table.insert(off_horse,card)
		end
	end
	if #armor>0 then
		for _,card in ipairs(armor)do
			if ((not target:getArmor() and not target:hasSkills("bazhen|yizhong"))
				or (target:getArmor() and self:evaluateArmor(card,target)>=self:evaluateArmor(target:getArmor(),target)))
				and not (card:isKindOf("Vine") and use.card:isKindOf("FireSlash") and self:slashIsEffective(use.card,target,use.from)) then
				return card:getEffectiveId()
			end
		end
	end
	if self:needToThrowArmor()
		and ((not target:getArmor() and not target:hasSkills("bazhen|yizhong"))
			or (target:getArmor() and self:evaluateArmor(self.player:getArmor(),target)>=self:evaluateArmor(target:getArmor(),target)))
		and not (self.player:getArmor():isKindOf("Vine") and use.card:isKindOf("FireSlash") and self:slashIsEffective(use.card,target,use.from)) then
		return self.player:getArmor():getEffectiveId()
	end
	if #def_horse>0 then return def_horse[1]:getEffectiveId() end
	if #weapon>0 then
		for _,card in ipairs(weapon)do
			if not target:getWeapon()
				or (self:evaluateArmor(card,target)>=self:evaluateArmor(target:getWeapon(),target)) then
				return card:getEffectiveId()
			end
		end
	end
	if self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon())<5
		and (not target:getArmor()
			or (self:evaluateArmor(self.player:getWeapon(),target)>=self:evaluateArmor(target:getWeapon(),target))) then
		return self.player:getWeapon():getEffectiveId()
	end
	if #off_horse>0 then return off_horse[1]:getEffectiveId() end
	if self.player:getOffensiveHorse()
		and ((self.player:getWeapon() and not self.player:getWeapon():isKindOf("Crossbow")) or self.player:hasSkills("mashu|tuntian")) then
		return self.player:getOffensiveHorse():getEffectiveId()
	end
end
sgs.ai_skill_invoke.fcj_kangkai = function(self, data)
	self.fcj_kangkai_give_id = nil
	if hasManjuanEffect(self.player) then return false end
	local target = data:toPlayer()
	if not target then return false end
	if target:objectName() == self.player:objectName() then return true
	elseif not self:isFriend(target) then
		return hasManjuanEffect(target)
	else
		local id = getKangkaiCard(self, target, self.player:getTag("fcj_kangkaiSlash"))
		if id then return true else return not self:needKongcheng(target, true) end
	end
end

sgs.ai_skill_cardask["@fcj_kangkai_give"] = function(self, data, pattern, target)
	if self:isFriend(target) then
		local id = getKangkaiCard(self, target, data)
		if id then return "$" .. id end
		if self:getCardsNum("Jink") > 1 then
			for _, card in sgs.qlist(self.player:getHandcards()) do
				if isCard("Jink", card, target) then return "$" .. card:getEffectiveId() end
			end
		end
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if not self:isValuableCard(card) then return "$" .. card:getEffectiveId() end
		end
	else
		local to_discard = self:askForDiscard("dummyreason", 1, 1, false, true)
		if #to_discard > 0 then return "$" .. to_discard[1] end
	end
end

sgs.ai_skill_invoke["fcj_kangkai_hedraw"] = true

sgs.ai_skill_invoke["fcj_kangkai_use"] = function(self, data)
	local use = self.player:getTag("fcj_kangkaiSlash"):toCardUse()
	local card = self.player:getTag("fcj_kangkaiGivenCard"):toCard()
	if not use.card or not card then return false end
	if card:isKindOf("Vine") and use.card:isKindOf("FireSlash") and self:slashIsEffective(use.card, self.player, use.from) then return false end
	if ((card:isKindOf("DefensiveHorse") and self.player:getDefensiveHorse())
		or (card:isKindOf("OffensiveHorse") and (self.player:getOffensiveHorse() or (self.player:hasSkill("drmashu") and self.player:getDefensiveHorse()))))
		and not self.player:hasSkills(sgs.lose_equip_skill) then
		return false
	end
	if card:isKindOf("Armor") and ((self.player:hasSkills("bazhen|yizhong") and not self.player:getArmor())
		or (self.player:getArmor() and self:evaluateArmor(card) < self:evaluateArmor(self.player:getArmor()))) then return false end
	if card:isKindOf("Weanpon") and (self.player:getWeapon() and self:evaluateArmor(card) < self:evaluateArmor(self.player:getWeapon())) then return false end
	return true
end

--37 界吕岱
  --“勤国”AI
sgs.ai_skill_use["@@fcj_qinguo"] = function(self, prompt, method)
	local slash = dummyCard()
    slash:setSkillName("fcj_qinguo")
	local dummy_use = dummy()
	self:useCardSlash(slash,dummy_use)
	if dummy_use.card and dummy_use.to:length()>0 then
		local tos = {}
		for _,p in sgs.qlist(dummy_use.to)do
			table.insert(tos,p:objectName())
		end
		return "#fcj_qinguoCard:.:->"..table.concat(tos,"+")
	end
	return "."
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|fcj_qinguo"
sgs.ai_cardneed.fcj_qinguo = sgs.ai_cardneed.equip
--

--38 界陆抗
  --“决堰”AI
local fcj_jueyan_skill = {}
fcj_jueyan_skill.name = "fcj_jueyan"
table.insert(sgs.ai_skills, fcj_jueyan_skill)
fcj_jueyan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasEquipArea() then
		return sgs.Card_Parse("#fcj_jueyan:.:")
	end
end

sgs.ai_skill_use_func["#fcj_jueyan"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_choice["fcj_jueyan"] = function(self, choices, data)
	local has_fcj_jueyan_slash_target = false
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) == 1 and not enemy:hasArmorEffect("vine") then
			has_fcj_jueyan_slash_target = true
		end
	end
	local items = choices:split("+")
	if self.player:hasEquipArea(0) and self:getCardsNum("Slash") > 2 and has_fcj_jueyan_slash_target then
		return "fcj_jueyan0"
	elseif self.player:hasEquipArea(4) and self:getCardsNum("ExNihilo") > 0 then
		return "fcj_jueyan4"
	elseif self.player:hasEquipArea(2) and self.player:hasEquipArea(3) and not has_fcj_jueyan_slash_target and self:getCardsNum("Slash") > 0 then
		return "fcj_jueyan2"
	elseif self.player:hasEquipArea(1) then
		return "fcj_jueyan1"
	else
		return items[1]
	end
end

sgs.ai_use_value.fcj_jueyan = 10
sgs.ai_use_priority.fcj_jueyan = 10
sgs.ai_card_intention.fcj_jueyan = -100

  --“怀柔”AI
local ps_huairou_skill = {}
ps_huairou_skill.name = "ps_huairou"
table.insert(sgs.ai_skills, ps_huairou_skill)
ps_huairou_skill.getTurnUseCard = function(self, inclusive)
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	for _, c in ipairs(usable_cards) do
		if self.player:hasArmorEffect("silver_lion") and c:isKindOf("SilverLion")
		and self.player:isWounded() then
			return sgs.Card_Parse(string.format("#ps_huairou:%s:", c:getEffectiveId()))
		elseif not self.player:hasEquipArea(0) and c:isKindOf("Weapon") then
			return sgs.Card_Parse(string.format("#ps_huairou:%s:", c:getEffectiveId()))
		elseif not self.player:hasEquipArea(1) and c:isKindOf("Armor") then
			return sgs.Card_Parse(string.format("#ps_huairou:%s:", c:getEffectiveId()))
		elseif not self.player:hasEquipArea(2) and c:isKindOf("DefensiveHorse") then
			return sgs.Card_Parse(string.format("#ps_huairou:%s:", c:getEffectiveId()))
		elseif not self.player:hasEquipArea(3) and c:isKindOf("OffensiveHorse") then
			return sgs.Card_Parse(string.format("#ps_huairou:%s:", c:getEffectiveId()))
		elseif not self.player:hasEquipArea(4) and c:isKindOf("Treasure") then
			return sgs.Card_Parse(string.format("#ps_huairou:%s:", c:getEffectiveId()))
		end
	end
end

sgs.ai_skill_use_func["#ps_huairou"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value.ps_huairou = 10
sgs.ai_use_priority.ps_huairou = 10
sgs.ai_card_intention.ps_huairou = -100





--

--39 界麹义（全自动）
sgs.ai_ajustdamage_from.fcj_jiaozi = function(self,from,to,card,nature)
	for _,p in sgs.qlist(from:getAliveSiblings())do
		if p:getHandcardNum()>=from:getHandcardNum() then return 0 end
	end
	return 1
end
sgs.ai_ajustdamage_to.fcj_jiaozi = function(self,from,to,card,nature)
	for _,p in sgs.qlist(to:getAliveSiblings())do
		if p:getHandcardNum()>=to:getHandcardNum() then return 0 end
	end
	return 1
end



--40 界司马徽
  --“荐杰”AI
sgs.ai_skill_playerchosen.fcj_jianjie = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isFriend(p) and (p:getMark("&fcj_Loong") > 0 or p:getMark("&fcj_Phoenix") > 0) then
		    return p
		end
	end
	for _, p in ipairs(targets) do --优先
	    if self:isFriend(p) then
		    return p
		end
	end
	return self.player
end

sgs.ai_skill_playerchosen["fcj_jianjied"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do --优先真人队友
	    if self:isFriend(p) and p:getState() == "online" then
		    return p
		end
	end
	for _, p in ipairs(targets) do
	    if self:isFriend(p) then
		    return p
		end
	end
	return self.player
end

local fcj_jianjie_skill = {}
fcj_jianjie_skill.name = "fcj_jianjie"
table.insert(sgs.ai_skills, fcj_jianjie_skill)
fcj_jianjie_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#fcj_jianjieCard") >= 2 then return end
	return sgs.Card_Parse("#fcj_jianjieCard:.:")
end

sgs.ai_skill_use_func["#fcj_jianjieCard"] = function(card, use, self)
    if self.player:usedTimes("#fcj_jianjieCard") < 2 then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 and (enemy:getMark("&fcj_Loong") > 0 or enemy:getMark("&fcj_Phoenix") > 0) then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
		self:sort(self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do
			 if (friend:getMark("&fcj_Loong") > 0 or friend:getMark("&fcj_Phoenix") > 0) then
			    use.card = card
			    if use.to then use.to:append(friend) end
		        return
			end
		end
	end
	return nil
end

sgs.ai_use_value.fcj_jianjieCard = 8.5
sgs.ai_use_priority.fcj_jianjieCard = 9.5


   --衍生技能：
    --“界火计”AI
local fcjiehuoji_skill = {}
fcjiehuoji_skill.name = "fcjiehuoji"
table.insert(sgs.ai_skills, fcjiehuoji_skill)
fcjiehuoji_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	for _, acard in sgs.list(cards) do
		if acard:isRed() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.FireAttack or self:getOverflow() > 0) then
			if acard:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then
				local keep
				local dummy_use = self:aiUseCard(acard, dummy())
				if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if p:getHp() <= 1 then keep = true break end
					end
					if dummy_use.to:length() > 1 then keep = true end
				end
				if keep then sgs.ai_use_priority.Slash = sgs.ai_use_priority.FireAttack + 0.1
				else
					sgs.ai_use_priority.Slash = 2.6
					card = acard
					break
				end
			else
				card = acard
				break
			end
		end
	end
	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("fire_attack:fcjiehuoji[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_cardneed.fcjiehuoji = function(to, card, self)
	return card:isRed()
end

    --“界连环”AI
local fcjielianhuan_skill = {}
fcjielianhuan_skill.name = "fcjielianhuan"
table.insert(sgs.ai_skills, fcjielianhuan_skill)
fcjielianhuan_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	local slash = self:getCard("FireSlash") or self:getCard("ThunderSlash") or self:getCard("Slash")
	if slash then
		local dummy_use = self:aiUseCard(slash, dummy())
		if not dummy_use.card then slash = nil end
	end
	for _, acard in sgs.list(cards) do
		if acard:getSuit() == sgs.Card_Club then
			local shouldUse = true
			if self:getUseValue(acard) > sgs.ai_use_value.IronChain and acard:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = self:aiUseCard(acard, dummy())
				if dummy_use.card then shouldUse = false end
			end
			if acard:getTypeId() == sgs.Card_TypeEquip then
				local dummy_use = self:aiUseCard(acard, dummy())
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse and (not slash or slash:getEffectiveId() ~= acard:getEffectiveId()) then
				card = acard
				break
			end
		end
	end
	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("iron_chain:fcjielianhuan[club:%s]=%d"):format(number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_skill_playerchosen.fcjielianhuan = function(self, targets)
	targets = sgs.QList2Table(targets)
	local use = self.room:getTag("fcjielianhuan"):toCardUse()
	local dummy_use = self:aiUseCard(use.card, dummy(true, 99, use.to))
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			if table.contains(targets,p) then
				return p
			end
		end
	end
    return nil
end

sgs.ai_cardneed.fcjielianhuan = function(to, card, self)
	return card:getSuit() == sgs.Card_Club
end

    --“智哲牌”AI（避免AI拿到这些牌直接不会出牌）
sgs.ai_fill_skill.fczhizhe = function(self)
	local cs = {}
	for _,h in sgs.list(self:sortByUseValue(self.player:getCards("h")))do
		if h:getTypeId()<3 and not h:isKindOf("DelayedTrick")
		then table.insert(cs,h) end
	end
	if #cs<4 or self:getUseValue(cs[1])<8 then return end
	return sgs.Card_Parse("#fczhizheCard:"..cs[1]:getEffectiveId()..":")
end

sgs.ai_skill_use_func["#fczhizheCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.fczhizheCard = 5.4
sgs.ai_use_priority.fczhizheCard = 13.8
sgs.ai_card_priority.fczhizhe = function(self,card)
	if card:getSkillName() == "fczhizhe"
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

  --基本牌

  --锦囊牌

    --“界涅槃”AI
sgs.ai_skill_invoke.fcjieniepan = function(self, data)
	local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()
	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
end

    --“鸾凤”AI
sgs.ai_skill_invoke.fcluanfeng = function(self, data)
	local dying = data:toDying()
	if dying.who:objectName() == self.player:objectName() then
		return true
	else
		return self:isFriend(dying.who)
	end
end

sgs.ai_use_revises.fcj_yinshi = function(self,card,use)
	if self.player:getMark("&fcj_Loong")+self.player:getMark("&fcj_Phoenix")<1
	and card:isKindOf("Armor")
	then return false end
end

sgs.ai_target_revises.fcj_yinshi = function(to,card)
	if not to:getArmor()
	and to:getMark("&fcj_Loong")+to:getMark("&fcj_Phoenix")<1
	and card:isDamageCard()
	then
    	if card:isKindOf("NatureSlash")
		or card:isKindOf("TrickCard")
		then return true end
	end
end


--41 界马良（全自动）





--

--42 界马忠
  --“抚蛮”AI
local fcj_fuman_skill = {}
fcj_fuman_skill.name = "fcj_fuman"
table.insert(sgs.ai_skills, fcj_fuman_skill)
fcj_fuman_skill.getTurnUseCard = function(self)
	if self.player:isNude() or #self.enemies == 0 or #self.friends_noself == 0 then return end
	local card_id
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, acard in ipairs(cards) do
		if acard:isDamageCard() or acard:isKindOf("Weanpon") then
			card_id = acard:getEffectiveId()
			break
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#fcj_fumanCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#fcj_fumanCard"] = function(card, use, self)
    if not self.player:isNude() then
        self:sort(self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do
		    if friend and not self:needKongcheng(friend, true) and friend:getMark("fcj_fuman-PlayClear") == 0 then
				use.card = card
			    if use.to then use.to:append(friend) end
		        return
			end
	    end
	end
	return nil
end

sgs.ai_use_value.fcj_fumanCard = 8.5
sgs.ai_use_priority.fcj_fumanCard = 9.5
sgs.ai_card_intention.fcj_fumanCard = -80

--43 界乐进
  --“骁果”AI
sgs.ai_skill_invoke.fcj_xiaoguo = function(self, data)
	local current = self.room:getCurrent()
	return self:isEnemy(current)
end

sgs.ai_skill_playerchosen.fcj_xiaoguo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and self:damageIsEffective(p) and not self:cantbeHurt(p) and not self:needToLoseHp(p, self.player) then
		    return p 
		end
	end
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and self:damageIsEffective(p) and not self:cantbeHurt(p) then
		    return p 
		end
	end
	--return nil
end
sgs.ai_choicemade_filter.skillInvoke.fcj_xiaoguo = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local current = self.room:getCurrent()
		sgs.updateIntention(player,current,50)
	end
end
sgs.ai_playerchosen_intention.fcj_xiaoguo = 50

sgs.ai_skill_cardask["@fcj_xiaoguo-disBasic"] = function(self, data, pattern)
	local target = data:toPlayer()
	if self:needToLoseHp(self.player,target, nil) then return "." end
	if not self:damageIsEffective(self.player) then return "." end
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
sgs.ai_skill_cardask["@fcj_xiaoguo-disEquip"] = function(self, data, pattern)
	local target = data:toPlayer()
	if self:needToLoseHp(self.player,target, nil) then return "." end
	if not self:damageIsEffective(self.player) then return "." end
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
sgs.ai_skill_cardask["@fcj_xiaoguo-disTrick"] = function(self, data, pattern)
	local target = data:toPlayer()
	if self:needToLoseHp(self.player,target, nil) then return "." end
	if not self:damageIsEffective(self.player) then return "." end
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


--

--44 界文聘
  --“金汤”AI
sgs.ai_skill_use["@@fcj_jintang"] = function(self, prompt)
	local targets = {}
	if self.player:hasFlag("fcj_jintang") then
		if #self.enemies == 0 then return "." end
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if enemy and enemy:getMark("&fcj_jintang_Friends") == 0 and not table.contains(targets, enemy:objectName()) then
				table.insert(targets, enemy:objectName())
			end
		end
	else
		table.insert(targets, self.player:objectName())
		if #self.friends_noself > 0 then
			self:sort(self.friends_noself, "defense")
			for _, friend in ipairs(self.friends_noself) do
				if friend and not table.contains(targets, friend:objectName()) then
					table.insert(targets, friend:objectName())
				end
			end
		end
	end
	if #targets > 0 then
		return "#fcj_jintangCard:.:->" .. table.concat(targets, "+")
	end
	return "."
end
sgs.ai_skill_invoke.fcj_jintang = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end
sgs.ai_card_intention["fcj_jintangCard"] = function(self,card,from,tos,source)
	for _,to in ipairs(tos)do
		sgs.updateIntention(from,to,from:hasFlag("fcj_jintang") and 50 or -50)
	end
end

  --“镇卫”AI
sgs.ai_skill_invoke.fcj_zhenwei = function(self, data)
	local use = data:toCardUse()
	if use.to:length()~=1 or not use.from or not use.card then return false end
	if not self:isFriend(use.to:at(0)) or self:isFriend(use.from) then return false end
	if use.to:at(0):hasSkills("liuli|tianxiang") and use.card:isKindOf("Slash") and use.to:at(0):getHandcardNum()>1 then return false end
	if use.card:isKindOf("Slash") and not self:slashIsEffective(use.card,use.to:at(0),use.from) then return false end
	if use.to:at(0):hasSkills(sgs.masochism_skill) and not self:isWeak(use.to:at(0)) then return false end
	if self.player:getHandcardNum()+self.player:getEquips():length()<2 and not self:isWeak(use.to:at(0)) then return false end
	local to_discard = self:askForDiscard("sp_zhenwei",1,1,false,true)
	if #to_discard>0 then
		if not (use.card:isKindOf("Slash") and  self:isWeak(use.to:at(0))) and sgs.Sanguosha:getCard(to_discard[1]):isKindOf("Peach") then return false end
		return true
	else
		return false
	end
end

sgs.ai_skill_choice.fcj_zhenwei = function(self, choices, data)
	local use = data:toCardUse()
	if self:isWeak() or self.player:getHandcardNum()<2 then return "2" end
	if use.card:isKindOf("TrickCard") and use.from:hasSkill("jizhi") then return "1" end
	if use.card:isKindOf("Slash") and (use.from:hasSkills("paoxiao|tianyi|xianzhen|jiangchi|fuhun|qiangwu")
		or (use.from:getWeapon() and use.from:getWeapon():isKindOf("Crossbow"))) and self:getCardsNum("Jink")==0 then return "2" end
	if use.card:isKindOf("SupplyShortage") then return "2" end
	if use.card:isKindOf("Slash") and self:getCardsNum("Jink")==0 and self.player:getLostHp()>0 then return "2" end
	if use.card:isKindOf("Indulgence") and self.player:getHandcardNum()+1>self.player:getHp() then return "2" end
	if use.card:isKindOf("Slash") and use.from:hasSkills("tieqi|wushuang|yijue|liegong|mengjin|qianxi") and not (use.from:getWeapon() and use.from:getWeapon():isKindOf("Crossbow")) then return "2" end
	return "1"
end

--45 界诸葛瑾
  --“缓释”AI（水平不够，还是算了）
sgs.ai_skill_invoke.fcj_huanshi = function(self,data)
	local judge = data:toJudge()
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if self:isFriend(judge.who) then
		local card_id = self:getRetrialCardId(cards,judge)
		if card_id~=-1 then return true end
		local card_id = self:getRetrialCardId(cards,judge,nil,true)
		if card_id<0 then return false end
		if self:needRetrial(judge) or self:getUseValue(judge.card)>self:getUseValue(sgs.Sanguosha:getCard(card_id))then 
			return true
		end
	elseif self:isEnemy(judge.who) and self:needRetrial(judge) then
		for _,card in sgs.list(cards)do
			if judge:isGood(card) or self:isValuableCard(card) then return false end
		end
		return true
	end
	return false
end

sgs.ai_skill_askforag.fcj_huanshi = function(self,card_ids)
	local cards = {}
	for _,id in sgs.list(card_ids)do
		table.insert(cards,sgs.Sanguosha:getCard(id))
	end
	local judge = self.player:getTag("fcj_huanshiJudge"):toJudge()
	local zhugejin = self.player:getTag("fcj_huanshiFrom"):toPlayer()

	local cmp = function(a,b)
		local a_keep_value,b_keep_value = sgs.ai_keep_value[a:getClassName()] or 0,sgs.ai_keep_value[b:getClassName()] or 0
		a_keep_value = a_keep_value+a:getNumber()/100
		b_keep_value = b_keep_value+b:getNumber()/100
		if zhugejin and zhugejin:hasSkill("fcj_mingzhe") then
			if a:isRed() then a_keep_value = a_keep_value-0.3 end
			if b:isRed() then b_keep_value = b_keep_value-0.3 end
		end
		return a_keep_value<b_keep_value
	end

	local card_id = self:getRetrialCardId(cards,judge,false)
	if card_id~=-1 then return card_id end
	if zhugejin and not self:isEnemy(zhugejin) then
		local valueless = {}
		for _,card in sgs.list(cards)do
			if not self:isValuableCard(card,zhugejin) then table.insert(valueless,card) end
		end
		if #valueless==0 then valueless = cards end
		table.sort(valueless,cmp)
		return valueless[1]:getEffectiveId()
	else
		for _,card in sgs.list(cards)do
			if judge:isGood(card) then return card:getEffectiveId() end
		end
		local valuable = {}
		for _,card in sgs.list(cards)do
			if self:isValuableCard(card,zhugejin) then table.insert(valuable,card) end
		end
		if #valuable==0 then valuable = cards end
		table.sort(valuable,cmp)
		return valuable[#valuable]:getEffectiveId()
	end
	return -1
end

function sgs.ai_cardneed.fcj_huanshi(to,card,self)
	for _,player in sgs.list(self.friends)do
		if self:getFinalRetrial(to)==1 then
			if self:willSkipDrawPhase(player) then
				return card:getSuit()==sgs.Card_Club and not self:hasSuit("club",true,to)
			end
			if self:willSkipPlayPhase(player) then
				return card:getSuit()==sgs.Card_Heart and not self:hasSuit("heart",true,to)
			end
		end
	end
end

  --“弘援”AI
sgs.ai_skill_invoke["@fcj_hongyuanDC"] = true
sgs.ai_skill_invoke["@fcj_hongyuanGC"] = true

sgs.ai_skill_use["@@fcj_hongyuan"] = function(self, prompt)
	if self.player:getMark("fcj_hongyuan") < 1 then
		local targets = {}
		if #self.friends_noself == 0 then return "." end
		self:sort(self.friends_noself, "hp")
		for _, friend in ipairs(self.friends_noself) do
			if friend and not table.contains(targets, friend:objectName()) then
				table.insert(targets, friend:objectName())
			end
		end
		if #targets > 0 then
			return "#fcj_hongyuanCard:.:->" .. table.concat(targets, "+")
		end
	else
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local targets = self.room:getOtherPlayers(self.player)
		local c,to = self:getCardNeedPlayer(cards, false, targets)
		if c and to then return "#fcj_hongyuanCard:.:->"..to:objectName() end
		for _, friend in ipairs(self.friends_noself) do
			for _,h in sgs.list(self.player:getHandcards())do
				if self:willUse(self.player, h) and h:isAvailable(self.player) then continue end
				return "#fcj_hongyuanCard:.:->"..friend:objectName()
			end
		end
	end
	return "."
end
sgs.ai_card_intention["#fcj_hongyuanCard"] = -80

  --“明哲”AI
sgs.ai_skill_invoke["@fcj_mingzheGC"] = true
sgs.ai_skill_invoke["@fcj_mingzheLC"] = true

--46 界贺齐
  --“绮胄-我的装备”AI
    --我的武器
sgs.weapon_range.FcjhqWeapon = 4
sgs.ai_use_priority.FcjhqWeapon = 2.78
    --我的防具
sgs.ai_use_priority.FcjhqArmor = 0.99

sgs.need_equip_skill = sgs.need_equip_skill .. "|fcj_qizhou"
sgs.ai_cardneed.fcj_qizhou = sgs.ai_cardneed.equip
  --“闪袭”AI（仅真·[闪]袭部分） --考虑到贺齐大部分时间都是有“破军”的，偷懒了。
local fcj_shanxi_skill = {}
fcj_shanxi_skill.name = "fcj_shanxi"
table.insert(sgs.ai_skills, fcj_shanxi_skill)
fcj_shanxi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#fcj_shanxiCard") or self.player:isNude() or #self.enemies == 0 then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self.player:getHandcardNum() > self.player:getHp() then
		for _, acard in ipairs(cards) do
			if acard:isKindOf("BasicCard") and acard:isRed() and not acard:isKindOf("Peach") then
				card_id = acard:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#fcj_shanxiCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#fcj_shanxiCard"] = function(card, use, self)
    if not self.player:hasUsed("#fcj_shanxiCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 and not enemy:isNude() then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		    return end
		end
	end
end

sgs.ai_use_value.fcj_shanxiCard = 8.5
sgs.ai_use_priority.fcj_shanxiCard = 9.5
sgs.ai_card_intention.fcj_shanxiCard = 80

--界·晋司马师
  --“夷灭”AI
sgs.ai_skill_invoke.fcj_yimie = function(self, data)
	local target = data:toDamage().to
	if self:cantDamageMore(self.player,target) then return false end
	if target:getHp()<1 then return false end
	return not self:isFriend(target)
end

sgs.ai_card_priority.fcj_tairan = function(self,card)
	if card:hasFlag("fcj_tairanD")
	then
		return 1
	end
end
--

--界·晋杜预
  --“三陈”AI
local fcj_sanchen_skill = {}
fcj_sanchen_skill.name = "fcj_sanchen"
table.insert(sgs.ai_skills, fcj_sanchen_skill)
fcj_sanchen_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#fcj_sanchenCard") >= 3 or self.player:getMark("fcj_sanchenBan-SelfClear") > 0 then return end
	return sgs.Card_Parse("#fcj_sanchenCard:.:")
end

sgs.ai_skill_use_func["#fcj_sanchenCard"] = function(card, use, self)
    if self.player:usedTimes("#fcj_sanchenCard") < 3 and self.player:getMark("fcj_sanchenBan-SelfClear") == 0 then
        if self.player:getMark("&fcj_sanchenThree-Clear") == 0 then
			use.card = card
			if use.to then use.to:append(self.player) end
			return
		end
		self:sort(self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do
		    if friend and friend:getMark("&fcj_sanchenThree-Clear") == 0 and self:canDraw(friend, self.player) then
				use.card = card
			    if use.to then use.to:append(friend) end
		        return
			end
	    end
	end
end

sgs.ai_use_value.fcj_sanchenCard = 8.5
sgs.ai_use_priority.fcj_sanchenCard = 9.5
sgs.ai_card_intention.fcj_sanchenCard = -80

--界·神刘备
  --“结营”AI
sgs.ai_skill_playerchosen.fcj_jieying = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) then
		return p end
	end
	for _, p in ipairs(targets) do
	    if self:isFriend(p) and self:needToLoseHp(p) then
		return p end
	end
end
sgs.ai_target_revises.fcj_jieying = function(to,card)
	if card:isKindOf("IronChain")
	then return true end
end

--界·神张辽
  --“雷袭”AI
    --黑牌印雷杀（略）
sgs.ai_skill_use["@@fcj_leixiSlash"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local ts = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_SuitToBeDecided, -1)
	ts:setSkillName("fcj_leixi")
	ts:deleteLater()
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if c:isBlack() then
			ts:clearSubcards()
			ts:addSubcard(c)
			local dummy_use = self:aiUseCard(ts, dummy())
			local targets = {}
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					table.insert(targets, p:objectName())
				end
			end
			if #targets > 0 then
				return ts:toString().."->"..table.concat(targets,"+")
			end
		end
	end
	return "."
end
    --虚空印决斗
sgs.ai_skill_use["@@fcj_leixiDuel"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	duel:setSkillName("fcj_leixi")
	local dummy_use = self:aiUseCard(duel, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
	end
	if #targets > 0 then
		return duel:toString().."->"..table.concat(targets,"+")
	end
	return "."
end

    --选目标
sgs.ai_skill_playerchosen.fcj_leixi = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "hp")
	if self.player:getMark("fcj_leixi") == 3 then
		local max_card = self:getMaxCard()
		local max_point = max_card:getNumber()

		if #self.enemies==0 then return end
		self:sort(self.enemies,"handcard")

		for _,enemy in sgs.list(self.enemies)do
			if self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:cantbeHurt(enemy) and self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local allknown = 0
				if self:getKnownNum(enemy)==enemy:getHandcardNum() then
					allknown = allknown+1
				end
				if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
					or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
					or (not enemy_max_card and max_point>10) then
					return enemy
				end
			end
		end
	end
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Thunder) and not self:cantbeHurt(p) then
			return p
		end
	end
end
sgs.ai_cardneed.fcj_leixi = sgs.ai_cardneed.bignumber
sgs.ai_ajustdamage_from.fcj_leixi = function(self,from,to,card,nature)
	if nature == "T"
	then return from:getMark("&fcj_leixi") end
end
--
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|fcbyajiao"
sgs.ai_skill_invoke.fcbyajiao = true

sgs.ai_card_intention["fcbyajiaoCard"] = 50
sgs.ai_skill_use["@@fcbyajiao"] = function(self,prompt)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local c,to = self:getCardNeedPlayer(cards)
	if c and to then return "#fcbyajiaoCard:"..c:getEffectiveId()..":->"..to:objectName() end
	for _,friend in ipairs(self.friends_noself)do
		if self:getCardsNum("Jink")>1 then
			for _,card in sgs.qlist(self.player:getHandcards())do
				if isCard("Jink",card,friend) then return "#fcbyajiaoCard:"..card:getEffectiveId()..":->"..friend:objectName() end
			end
		end
		for _,card in sgs.qlist(self.player:getHandcards())do
			if not self:isValuableCard(card) then return "#fcbyajiaoCard:"..card:getEffectiveId()..":->"..friend:objectName() end
		end
	end
	return "."
end
sgs.ai_skill_playerchosen.fcbyajiao = function(self,targets)
	return self:findPlayerToDiscard("hej",false,true,targets)[1]
end
sgs.ai_skill_playerchosen.fcbyajiaoequip = function(self,targets)
	local card = self.player:getTag("fcbyajiaoCard"):toCard()
	if not card then return false end
	local index = card:getRealCard():toEquipCard():location()
	for _,friend in ipairs(self.friends)do
		if not friend:hasEquipArea(index) then continue end
		if self:loseEquipEffect(friend) then
			return friend
		end
	end
	local target
	for _,friend in ipairs(self.friends)do
		if not friend:hasEquipArea(index) then continue end
		if not self:getSameEquip(card,friend) and self:hasSkills(sgs.need_equip_skill.."|"..sgs.lose_equip_skill,friend) then
			return target
		end
		if not friend:hasEquipArea(index) then continue end
		if not self:getSameEquip(card,friend) then
			return target
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if ((card:isKindOf("DefensiveHorse") and friend:getDefensiveHorse())
			or (card:isKindOf("OffensiveHorse") and (friend:getOffensiveHorse() or (friend:hasSkill("drmashu") and friend:getDefensiveHorse()))))
			and not friend:hasSkills(sgs.lose_equip_skill) then
			continue
		end
		if card:isKindOf("Armor") and ((friend:hasSkills("bazhen|yizhong") and not friend:getArmor())
		or (friend:getArmor() and self:evaluateArmor(card)<self:evaluateArmor(friend:getArmor()))) then continue end
		if card:isKindOf("Weapon") and (friend:getWeapon() and self:evaluateArmor(card)<self:evaluateArmor(friend:getWeapon())) then continue end
		return friend
	end
	
	return nil
end
sgs.ai_playerchosen_intention["fcbyajiaoequip"] = -50

sgs.ai_skill_invoke.fcbpozhen = true

sgs.ai_card_priority.fcbpozhen = function(self,card)
	if card:getSkillName()=="longdan"
	then
		if self.useValue
		then return 2 end
		return 0.08
	end
end


sgs.ai_skill_cardchosen.fcbpozhen = function(self,who,flags,method)
	if who and self:isFriend(who) then return -1 end
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		return id
	end
end


local fcbshenwuVS_skill = {}
fcbshenwuVS_skill.name = "fcbshenwuVS"
table.insert(sgs.ai_skills, fcbshenwuVS_skill)
fcbshenwuVS_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("Forbidfcbshenwu") then return nil end
	if self.player:getKingdom() ~= "qun" then return nil end

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Slash") or acard:isKindOf("Duel") or acard:isKindOf("Weapon") then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = card:getEffectiveId()
	local card_str = "#fcbshenwuCard:" .. card_id .. ":"
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)
	return skillcard
end

sgs.ai_skill_use_func["#fcbshenwuCard"] = function(card, use, self)
	if self:needBear() or self:getCardsNum("Slash", "h") <= 1 then
		return
	end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasLordSkill("fcbshenwu") then
			if not friend:hasFlag("fcbshenwuInvoked") then
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
	end
end

sgs.ai_card_intention.fcbshenwuCard = function(self, card, from, tos)
	if tos[1]:isKongcheng() and ((from:hasSkill("tianyi") and not from:hasUsed("TianyiCard"))
			or (from:hasSkill("xianzhen") and not from:hasUsed("XianzhenCard"))) then
	else
		sgs.updateIntention(from, tos[1], -80)
	end
end

sgs.ai_use_priority.fcbshenwuCard = 10
sgs.ai_use_value.fcbshenwuCard = 8.5

sgs.ai_use_revises.fcbgaolou = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end



--FC·SP神诸葛亮--
--妖智
sgs.ai_skill_invoke["sp_yaozhi_ub"] = true

local sp_yaozhi_ub_skill = {}
sp_yaozhi_ub_skill.name = "sp_yaozhi_ub"
table.insert(sgs.ai_skills, sp_yaozhi_ub_skill)
sp_yaozhi_ub_skill.getTurnUseCard = function(self)
	if self.player:getMark("sp_yaozhi_ubUsed") >= 3 + self.player:getMark("&sp_yaozhi_ubAdd") then return end
	return sgs.Card_Parse("#sp_yaozhi_ubCard:.:")
end

sgs.ai_skill_use_func["#sp_yaozhi_ubCard"] = function(card, use, self)
    if self.player:getMark("sp_yaozhi_ubUsed") < 3 + self.player:getMark("&sp_yaozhi_ubAdd") then
        use.card = card
	return end
end

sgs.ai_use_value.sp_yaozhi_ubCard = 8.5
sgs.ai_use_priority.sp_yaozhi_ubCard = 9.5
sgs.ai_card_intention.sp_yaozhi_ubCard = -80



sgs.ai_skill_playerchosen.sp_yaozhi_ub = function(self,targets)
	if self.player:getMark("@sp_shenqi_ub") > 0 and self.player:hasSkill("sp_shenqi_ub") then
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and not self:cantDamageMore(self.player, p) and not p:getPile("GodIncantation_ub"):isEmpty() then
				return p
			end
		end
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and not self:cantDamageMore(self.player, p) then
				return p
			end
		end
	end
	return nil
end
sgs.ai_skill_playerchosen.sp_yaozhi_ubX = function(self,targets)
	return targets:first()
end

local sp_shenqi_ub_skill = {}
sp_shenqi_ub_skill.name = "sp_shenqi_ub"
table.insert(sgs.ai_skills, sp_shenqi_ub_skill)
sp_shenqi_ub_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sp_shenqi_ubCard:.:")
end

sgs.ai_skill_use_func["#sp_shenqi_ubCard"] = function(card, use, self)
	self:sort(self.enemies,"defense")
	local target
	for _,enemy in sgs.list(self.enemies)do
		if not enemy:getPile("GodIncantation_ub"):isEmpty() and enemy:getPile("GodIncantation_ub"):length() > enemy:getHp() and self.player:getMaxHp() > enemy:getPile("GodIncantation_ub"):length() then
			if not self:cantbeHurt(enemy) and ((self:damageIsEffective(enemy, "N", self.player)) or (self:damageIsEffective(enemy, "F", self.player)) or (self:damageIsEffective(enemy, "T", self.player)))  and self:canDamage(enemy,self.player,nil) and not self:cantDamageMore(self.player, enemy) then
				target = enemy
				break
			end
		end
	end
	if target then
		use.card = sgs.Card_Parse("#sp_shenqi_ubCard:.:")
		use.to:append(target)
		return
	end
end

sgs.ai_use_value.sp_shenqi_ubCard = 9.5
sgs.ai_use_priority.sp_shenqi_ubCard = 3.5
sgs.ai_card_intention.sp_shenqi_ubCard = 70


sgs.ai_skill_choice.sp_shenqi_ub = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target then
		if self:isEnemy(target) then
			return "2"
		end
		if self:isFriend(target) then
			return "1"
		end
	end
	return "2"
end

sgs.ai_skill_choice.sp_shenqi_ub_zhuxie = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target then
		if self:isEnemy(target) then
			if (self:damageIsEffective(target, "F", self.player)) then
				return "fire"
			end
			if (self:damageIsEffective(target, "N", self.player)) then
				return "normal"
			end
			
			if (self:damageIsEffective(target, "T", self.player)) then
				return "thunder"
			end
		end
	end
	return "normal"
end



addAiSkills("f_huishi").getTurnUseCard = function(self)
    return sgs.Card_Parse("#f_huishiCard:.:")
end

sgs.ai_skill_use_func["#f_huishiCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.f_huishiCard = 8.4
sgs.ai_use_priority.f_huishiCard = 8.4

sgs.ai_skill_invoke["@f_huishi_continue"] = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.f_huishi = function(self,players)
	players = self:sort(players,"handcard")
    for _,target in sgs.list(players)do
    	if self:isFriend(target)
		then
            return target
		end
	end
end


sgs.ai_skill_choice["@f_huishiAdd"] = function(self, choices, data)
	local items = choices:split("+")
	if self.player:isWounded() then
		return "hp"
	end
	return "mhp"
end
sgs.ai_skill_choice["@f_huishiLose"] = function(self, choices, data)
	if sgs.ai_skill_choice.benghuai == "maxhp" then
		return "mhp"
	end
	return "hp"
end
sgs.ai_skill_invoke.f_tianzuo = true


local imba_skill = {}
imba_skill.name = "imba"
table.insert(sgs.ai_skills, imba_skill)
imba_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#imbaCard") and self.player:getMaxHp() <= 2 then return end
	return sgs.Card_Parse("#imbaCard:.:")
end

sgs.ai_skill_use_func["#imbaCard"] = function(card, use, self)
    self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if ep:isWounded()
		or ep:getMaxHp()<2
		then continue end
		use.card = card
		use.to:append(ep)
		return
	end
	self:sort(self.enemies,"hp",true)
	for _,ep in sgs.list(self.enemies)do
		if ep:getMaxHp()<2
		then continue end
		use.card = card
		use.to:append(ep)
		return
	end
end

sgs.ai_use_value.imbaCard = 8.5
sgs.ai_use_priority.imbaCard = 9.5
sgs.ai_card_intention.imbaCard = 80


addAiSkills("tyshouli").getTurnUseCard = function(self)
	local cards = {}
  	for i,p in sgs.list(self.room:getAlivePlayers())do
		for d,c in sgs.list(p:getCards("ej"))do
			if c:isKindOf("OffensiveHorse")
			then table.insert(cards,c) end
		end
	end
	self:sortByKeepValue(cards,nil,"l")
  	for _,c in sgs.list(cards)do
		local dc = dummyCard()
		dc:setSkillName("tyshouli")
		dc:addSubcard(c)
		local d = self:aiUseCard(dc)
		if d.card and d.to
		and dc:isAvailable(self.player)
		then
			self.tyshouli_to = d.to
			sgs.ai_use_priority.tyshouli = sgs.ai_use_priority.Slash+0.6
			return sgs.Card_Parse("#tyshouli:"..c:getEffectiveId()..":slash")
		end
	end
end

sgs.ai_skill_use_func["tyshouli"] = function(card,use,self)
	if self.tyshouli_to
	then
		use.card = card
		use.to = self.tyshouli_to
	end
end

sgs.ai_use_value.tyshouli = 5.4
sgs.ai_use_priority.tyshouli = 2.8


sgs.ai_card_priority.tyshouli = function(self,card)
	if card:getSkillName()=="tyshouli"
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_guhuo_card.tyshouli = function(self,toname,class_name)
	local cards = {}
  	for _,p in sgs.list(self.room:getAlivePlayers())do
		for _,c in sgs.list(p:getCards("ej"))do
			if c:isKindOf("OffensiveHorse") and class_name=="Slash"
			or c:isKindOf("DefensiveHorse") and class_name=="Jink"
			then table.insert(cards,c) end
		end
	end
	self:sortByKeepValue(cards,nil,"l")
  	for _,c in sgs.list(cards)do
		if self:getCardsNum(class_name)>0 then break end
		return "#tyshouli:"..c:getEffectiveId()..":"..toname
	end
end




local tycuijue_skill = {}
tycuijue_skill.name = "tycuijue"
table.insert(sgs.ai_skills, tycuijue_skill)
tycuijue_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	if not cards[1] then return nil end
	return sgs.Card_Parse("#tycuijueCard:" .. cards[1]:getEffectiveId() .. ":")
end

sgs.ai_skill_use_func["#tycuijueCard"] = function(card, use, self)
	local target = nil
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	local distance = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do 
		if self.player:inMyAttackRange(p) then
			if self.player:distanceTo(p) > distance then 
				distance = self.player:distanceTo(p)
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:canDamage(enemy, self.player, nil) and self.player:distanceTo(enemy) == distance and enemy:getMark("tycuijueTarget-Clear") == 0 then
            target = enemy
            break
        end
	end
	if target then
	use.card = card
	if use.to then use.to:append(target) end
	end
end
sgs.ai_card_intention["tycuijueCard"] = 80


sgs.ai_skill_invoke.wxqixingEX = true

  --“祭风”AI
local wxjifengEX_skill = {}
wxjifengEX_skill.name = "wxjifengEX"
table.insert(sgs.ai_skills, wxjifengEX_skill)
wxjifengEX_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, acard in ipairs(cards) do
		if (not acard:isKindOf("TrickCard") and not acard:isKindOf("Peach")) or acard:isKindOf("Nullification") then
			card_id = acard:getEffectiveId()
			break
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#wxjifengEXCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#wxjifengEXCard"] = function(card, use, self)
	use.card = card
	return
end

sgs.ai_use_value.wxjifengEXCard = 8.5
sgs.ai_use_priority.wxjifengEXCard = 9.5

  --“天罪”AI
sgs.ai_skill_use["@@wxtianzuiEX"] = function(self, prompt)
	local targets, exZUI = {}, self.player:getMark("&exZUI")
	if exZUI == 0 then return "." end
	--先帮判定区有牌的队友
	self:sort(self.friends_noself)
	for _, friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "hej") then
			table.insert(targets, friend:objectName())
			if #targets >= exZUI then
				break
			end
		end
	end
	if #self.enemies > 0 then --再拆对手
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if self:doDisCard(enemy, "hej")  then
				table.insert(targets, enemy:objectName())
				if #targets >= exZUI then
					break
				end
			end
		end
	end
	if #targets > 0 then
		return "#wxtianzuiEXCard:.:->" .. table.concat(targets, "+")
	end
	return "."
end

  --“天罚”AI
sgs.ai_skill_use["@@wxtianfaEX"] = function(self, prompt)
	local targets, exFA = {}, self.player:getMark("&exFA")
	if #self.enemies == 0 or exFA == 0 then return "." end
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 0 and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil)  then 
			table.insert(targets, enemy:objectName())
			if #targets >= exFA then
				break
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if #targets >= exFA then
			break
		end
		if self:damageIsEffective(friend, sgs.DamageStruct_Thunder) and self:canDamage(friend,self.player,nil)  then 
			table.insert(targets, friend:objectName())
		end
	end
	if #targets > 0 then
		return "#wxtianfaEXCard:.:->" .. table.concat(targets, "+")
	end
	return "."
end

sgs.ai_ajustdamage_from.fcmouliegong = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") then
		local record = from:property("fcmouliegongRecords"):toString()
		local records = {}
		if (record) then
			records = record:split(",")
		end
		if #records >= 3 then
			return 1
		end
	end
end

sgs.ai_canliegong_skill.fcmouliegong = function(self, from, to)
	local record = from:property("fcmouliegongRecords"):toString()
	local records = {}
	if record then
		records = record:split(",")
	end
	return #records >= 2
end

--FC谋关羽
  --“武圣”AI
sgs.ai_view_as.fcmouwusheng = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:fcmouwusheng[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local fcmouwusheng_skill = {}
fcmouwusheng_skill.name = "fcmouwusheng"
table.insert(sgs.ai_skills, fcmouwusheng_skill)
fcmouwusheng_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	local red_card
	self:sortByUseValue(cards, true)
	local useAll = false
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
			and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
			useAll = true
			break
		end
	end
	local disCrossbow = false
	if self:getCardsNum("Slash") < 2 or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then
		disCrossbow = true
	end
	local nuzhan_equip = false
	local nuzhan_equip_e = false
	self:sort(self.enemies, "defense")
	if self.player:hasSkill("nuzhan") then
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange()
			and getCardsNum("Jink", enemy) < 1 then
				nuzhan_equip_e = true
				break
			end
		end
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard") and nuzhan_equip_e then
				nuzhan_equip = true
				break
			end
		end
	end
	local nuzhan_trick = false
	local nuzhan_trick_e = false
	self:sort(self.enemies, "defense")
	if self.player:hasSkill("nuzhan") and not self.player:hasFlag("hasUsedSlash") and self:getCardsNum("Slash") > 1 then
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() then
				nuzhan_trick_e = true
				break
			end
		end
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard") and nuzhan_trick_e then
				nuzhan_trick = true
				break
			end
		end
	end
	for _, card in ipairs(cards) do
		if card:isRed() and not card:isKindOf("Slash") and not (nuzhan_equip or nuzhan_trick)
			and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
			and (not isCard("Crossbow", card, self.player) or disCrossbow)
			and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0) then
			red_card = card
			break
		end
	end
	if nuzhan_equip then
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("EquipCard") then
				red_card = card
				break
			end
		end
	end
	if nuzhan_trick then
		for _, card in ipairs(cards) do
			if card:isRed() and card:isKindOf("TrickCard") then
				red_card = card
				break
			end
		end
	end
	if red_card then
		local suit = red_card:getSuitString()
		local number = red_card:getNumberString()
		local card_id = red_card:getEffectiveId()
		local card_str = ("slash:fcmouwusheng[%s:%s]=%d"):format(suit, number, card_id)
		local slash = sgs.Card_Parse(card_str)
		assert(slash)
		return slash
	end
end

function sgs.ai_cardneed.fcmouwusheng(to, card)
	return card:isRed() --鼓励使用，因为都有加成效果
end

  --“义绝”AI
local fcmouyijue_skill = {}
fcmouyijue_skill.name = "fcmouyijue"
table.insert(sgs.ai_skills, fcmouyijue_skill)
fcmouyijue_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#fcmouyijueCard") or self.player:isNude() or #self.enemies == 0 then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		for _, acard in ipairs(cards) do
			if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				and not acard:isKindOf("Peach") then
				card_id = acard:getEffectiveId()
				break
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		for _, acard in ipairs(cards) do
			if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
				and not acard:isKindOf("Peach") then
				card_id = acard:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#fcmouyijueCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#fcmouyijueCard"] = function(card, use, self)
    if not self.player:hasUsed("#fcmouyijueCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.fcmouyijueCard = 8.5
sgs.ai_use_priority.fcmouyijueCard = 9.5
sgs.ai_card_intention.fcmouyijueCard = 80


sgs.ai_ajustdamage_from.fcmouwusheng = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:getSuit() == sgs.Card_Heart then
		return 1
	end
end

sgs.ai_ajustdamage_from.fcmouyijue = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and to:getMark("&fcmouyijue") > 0 and card:isRed() then
		return 1
	end
end

sgs.ai_skill_invoke.fcmoutieqii = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end

sgs.ai_ajustdamage_from.fcmoutieqii = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:hasFlag("fcmoutieqii_successDMG") then
		return 1
	end
end




--谋徐晃-威力加强版
  --“断粮”AI
local mouduanliangg_skill = {}
mouduanliangg_skill.name = "mouduanliangg"
table.insert(sgs.ai_skills, mouduanliangg_skill)
mouduanliangg_skill.getTurnUseCard = function(self)
	if self.player:usedTimes("#mouduanlianggCard") >= 2 then return end
	return sgs.Card_Parse("#mouduanlianggCard:.:")
end

sgs.ai_skill_use_func["#mouduanlianggCard"] = function(card, use, self)
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	local shortage = sgs.Sanguosha:cloneCard("supply_shortage", card:getSuit(), card:getNumber())
	shortage:setSkillName("mouduanliangv")
	shortage:deleteLater()
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:setSkillName("mouduanliangv")
	duel:deleteLater()
	local dummy_use = self:aiUseCard(shortage, dummy())
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            use.card = card
			if use.to then use.to:append(to) end
			return
        end
	end
	local dummy_use = self:aiUseCard(duel, dummy())
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            use.card = card
			if use.to then use.to:append(to) end
			return
        end
	end
	
	
end

sgs.ai_use_value.mouduanlianggCard = 8.5
sgs.ai_use_priority.mouduanlianggCard = 9.5
sgs.ai_card_intention.mouduanlianggCard = 80

  --“势迫”AI
sgs.ai_skill_invoke.moushipoo = true

sgs.ai_skill_playerchosen.moushipoo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) then
		    return p
		end
	end
end

    --目标选择
sgs.ai_skill_choice.moushipoo = function(self, choices, data)
    if self.player:isKongcheng() then return "3" end
	if self.player:getHp() <= 1 and self.player:getHandcardNum() <= 1
	and (self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0)
	then return "4" end
	if self.player:getHp() <= 1 then return "3" end
	return "4"
end

sgs.ai_skill_discard.moushipoo = function(self) --给牌
	local to_discard = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	table.insert(to_discard, cards[1]:getEffectiveId())
	return to_discard
end


--

--KJ谋夏侯霸
  --“试锋”AI
sgs.ai_skill_invoke.kjmoushifeng = true
sgs.ai_skill_invoke.kjmoulijin = true

sgs.ai_skill_use["@@kjmoushifeng"] = function(self, prompt)
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash:setSkillName("kjmoushifeng")
	local dummy_use = self:aiUseCard(slash, dummy(true))
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return slash:toString().."->"..table.concat(tos, "+")
    end
    return "."
end


  --“绝辗”AI
sgs.ai_skill_choice.kjmoujuezhan = function(self, choices, data)
	if self.player:isWounded() and self.player:getHp() <= 1 and self.player:getHandcardNum() > 1 then return "1" end
	return "2"
end

  --“励进”AI
sgs.ai_skill_choice.kjmoulijin = function(self, choices, data)
	if self.player:isWounded() and self.player:getHp() <= 1 and self.player:getHujia() == 0
	and self.player:getHandcardNum() - self.player:getHp() <= 1 then return "discard" end
	if self.player:getHandcardNum() <= 2 then return "draw" end
	return "play"
end

sgs.ai_skill_playerchosen.kjmoulijin = function(self, targets)
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he") then
			return enemy
		end
	end
	return targets:first()
end


--

--FC谋姜维
  --“挑衅”AI
addAiSkills("fcmoutiaoxin").getTurnUseCard = function(self)
	return sgs.Card_Parse("#fcmoutiaoxinCard:.:")
end

sgs.ai_skill_use_func["#fcmoutiaoxinCard"] = function(card,use,self)
	local distance = use.DefHorse and 1 or 0
	local targets = {}
	for _,enemy in ipairs(self.enemies)do
		if self:doDisCard(enemy,"he", true) and self:isTiaoxinTarget(enemy)
		then table.insert(targets,enemy)
			if #targets>=self.player:getMark("&charge_num") then
				break
			end
		end
	end

	if #targets==0 then return end

	sgs.ai_use_priority.fcmoutiaoxinCard = 8
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _,card in sgs.qlist(self.player:getCards("h"))do
			if card:isKindOf("Armor") and self:evaluateArmor(card)>3 then
				sgs.ai_use_priority.fcmoutiaoxinCard = 5.9
				break
			end
		end
	end
	if #targets>0 then
		self:sort(targets,"defenseSlash")
		for i = 1, #targets, 1 do
			use.to:append(targets[i])
		end
		use.card = sgs.Card_Parse("#fcmoutiaoxinCard:.:")
	end
end

sgs.ai_card_intention.fcmoutiaoxinCard = sgs.ai_card_intention.TiaoxinCard
sgs.ai_use_priority.fcmoutiaoxinCard = sgs.ai_use_priority.TiaoxinCard


  --“志继”->“妖智”AI
sgs.ai_skill_invoke.fcmzj_yaozhi = true

  --“志继”->“界妆神”AI
sgs.ai_skill_invoke.fcmzj_jiezhuangshen = true

sgs.ai_skill_playerchosen.fcmzj_jiezhuangshen = function(self, targets)
	targets = sgs.QList2Table(targets)
	return targets[math.random(1, #targets)]
end

sgs.ai_skill_choice.fcmzj_jiezhuangshen = function(self,choices,data)
	local player = data:toPlayer()
	local skills = choices:split("+")
	--[[if self:isFriend(player) then
		for _,sk in sgs.list(skills)do
			if string.find(sgs.bad_skills,sk) and player:hasSkill(sk) then return sk end
		end
		return skills[1]
	end]]
	
	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player,true) then
			return sk
		end
	end
	
	for _,sk in sgs.list(skills)do
		if self:isValueSkill(sk,player) then
			return sk
		end
	end
	
	local not_bad_skills = {}
	for _,sk in sgs.list(skills)do
		if string.find(sgs.bad_skills,sk) then continue end
		table.insert(not_bad_skills,sk)
	end
	if #not_bad_skills>0 then
		return not_bad_skills[math.random(1,#not_bad_skills)]
	end
	
	return skills[math.random(1,#skills)]
end

sgs.ai_skill_playerchosen.fcmzj_jiezhuangshenbuff = function(self, targets)
	local cardstr = sgs.ai_skill_use["@@dawu"](self, "@dawu")
	if cardstr:match("->") then
		local targetstr = cardstr:split("->")[2]:split("+")
		if #targetstr > 0 then
			local target = self.room:findPlayerByObjectName(targetstr[1])
			return target
		end
	end
	local cardstr = sgs.ai_skill_use["@@kuangfeng"](self, "@kuangfeng")
	if cardstr:match("->") then
		local targetstr = cardstr:split("->")[2]:split("+")
		if #targetstr > 0 then
			local target = self.room:findPlayerByObjectName(targetstr[1])
			return target
		end
	end
	return self.player
end

sgs.ai_skill_choice.fcmzj_jiezhuangshenbuff = function(self,choices,data)
	local player = data:toPlayer()
	if self:isFriend(player) then
		return "dwg"
	else
		return "kfc"
	end
	
	return "kfc"
end


sgs.ai_skill_playerschosen.fcmoujiang = function(self, targets)
	if self.player:getHp() + self:getAllPeachNum() - 1 <= 0 then
		return {}
	end
	targets = sgs.QList2Table(targets)
	local tos = {}
	local use = self.room:getTag("fcmoujiang"):toCardUse()
	local dummy_use = self:aiUseCard(use.card, dummy(true, math.min(self.player:getHp()-1, 2), use.to))
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			if table.contains(targets,p) then
				table.insert(tos,p)
			end
		end
	end
    return tos
end

sgs.ai_card_priority.fcmoujiang = function(self,card)
	if card:isKindOf("Slash") and card:isRed()
	then return 0.05 end
end

--FC谋孙策
  --“制霸”AI
local fcmouzhiba_skill = {}
fcmouzhiba_skill.name = "fcmouzhiba"
table.insert(sgs.ai_skills, fcmouzhiba_skill)
fcmouzhiba_skill.getTurnUseCard = function(self)
	if self:getOverflow() > 0 then
		return sgs.Card_Parse("#fcmouzhibaCard:.:")
	end
end

sgs.ai_skill_use_func["#fcmouzhibaCard"] = function(card, use, self)
	
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do --先找体力值和手牌数都只有1的
		if not enemy:isKongcheng() and self:objectiveLevel(enemy) > 0 and enemy:getHp() == 1 and enemy:getHandcardNum() == 1 and self.player:canPindian(enemy) then
			use.card = card
			if use.to then
			use.to:append(enemy) end
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self:objectiveLevel(enemy) > 0 and self.player:canPindian(enemy) then
			use.card = card
			if use.to then
			use.to:append(enemy) end
			return
		end
	end
	
end

sgs.ai_use_value.fcmouzhibaCard = 8.5
sgs.ai_use_priority.fcmouzhibaCard = sgs.ai_use_priority.Dismantlement
sgs.ai_card_intention.fcmouzhibaCard = 80



sgs.ai_skill_invoke.fcmhz_yinhun = function(self,data)
    return true
end

sgs.ai_skill_playerchosen.fcmhz_yinhun = function(self, targets)
	for _, enemy in ipairs(self.enemies) do
		if (enemy:isLord() and self.player:getJudgingArea():length() >= 2) or not enemy:isLord() then
			return enemy
		end
	end
	return targets:first()
end
sgs.ai_playerchosen_intention.fcmhz_yinhun = 80


--

--AH谋诸葛亮
  --“匡辅”AI
sgs.ai_skill_invoke.ahmoukuangfu = true


sgs.ai_skill_playerchosen.ahmoukuangfu = function(self, targets)
	local targets = sgs.QList2Table(targets)
	self:sort(self.friends_noself)
	for _, p in ipairs(self.friends_noself) do
		if self:isFriend(p) and p:getHandcardNum() < p:getHp() and (p:hasSkill("olwushen") or p:hasSkill("tyshencai") or p:hasSkill("tyxunshi")
		or p:hasSkill("newlonghun") or p:hasSkill("mrds_longhun") or p:hasSkill("gdlonghun") or p:hasSkill("xj_longhun")
		or p:hasSkill("mouliegongg") or p:hasSkill("jlsgliegong") or p:hasSkill("f_kaigong") or p:hasSkill("f_gonghun")
		or p:hasSkill("tyshouli") or p:hasSkill("tyhengwu") or p:hasSkill("shouli") or p:hasSkill("hengwu")) then -- 六 星 耀 帝 ！
			return p
		end
	end
	return self.player
end

  --“识治”AI-识
sgs.ai_skill_invoke["@ahmoushizhi_ZHI"] = function(self,data)
	return sgs.ai_skill_use["@@ahmoushizhi_zhi"](self, "") ~= "."
end
sgs.ai_skill_invoke["@ahmoushizhi_SHI"] = function(self,data)
	return sgs.ai_skill_use["@@ahmoushizhi_shi"](self, "") ~= "."
end
sgs.ai_skill_use["@@ahmoushizhi_zhi"] = function(self, prompt)
	local targets = {}
	self:sort(self.enemies,"handcard", true)
	for _,enemy in ipairs(self.enemies)do
		table.insert(targets, enemy:objectName())
		if #targets >= 2 then break end
	end
	if #targets > 0 then
		return "#ahmoushizhi_zhiCard:.:->" .. table.concat(targets, "+")
	end
	return "."
end
sgs.ai_card_intention["#ahmoushizhi_zhiCard"] = 100
sgs.ai_skill_use["@@ahmoushizhi_shi"] = function(self, prompt)
	local targets, xingfu, hanshi = {}, #self.friends_noself, 0
	if #self.friends_noself < 2 then return "." end
	self:sort(self.friends_noself)
	for _, friend in ipairs(self.friends_noself) do
		if xingfu > 0 and hanshi < 4 and not self:needKongcheng(friend, true) then
			table.insert(targets, friend:objectName())
			xingfu = xingfu - 1
			hanshi = hanshi + 1
		end
	end
	if #targets > 0 then
		return "#ahmoushizhi_shiCard:.:->" .. table.concat(targets, "+")
	end
	return "."
end

sgs.ai_card_intention["#ahmoushizhi_shiCard"] = -100

sgs.ai_skill_use["@@ahmoutaozei_tm"] = function(self, prompt)
	local pattern = self.player:property("ahmoutaozei_tm"):toString()
	local cd = sgs.Sanguosha:cloneCard(pattern, sgs.Card_NoSuit, 0)
	cd:setSkillName("ahmoutaozei")
	cd:deleteLater()
	local dummy_use = self:aiUseCard(cd, dummy())
	if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return cd:toString().."->"..table.concat(tos, "+")
	elseif dummy_use.card then
		return cd:toString()
    end
    return "."
end
sgs.ai_skill_use["@@ahmoutaozei"] = function(self, prompt)
	local use = self.room:getTag("ahmoutaozei"):toCardUse()
	if use.from and self:isEnemy(use.from) then return "#ahmoutaozeiCard:.:" end
	return "."
end







--

--FC谋诸葛亮
  --“观星”AI
sgs.ai_skill_invoke.fcmouguanxing = function(self, data)
	local current = self.room:getCurrent()
	if self.player:getMark("&fcmouguanxing") <= 1 and current:objectName() ~= self.player:objectName() then return false end --要是自己还剩1个标记还在别人回合观星，技能就直接废了
	if (self:isFriend(current) or self:isEnemy(current)) and current:getJudgingAreaID():length() > 0 then return true end
	if math.random() > 0.9 and self.player:getMark("&fcmouguanxing") < 5 then return true end
	if math.random() > 0.5 then return true end
	return current:objectName() == self.player:objectName() --还是偏无脑
end

  --“空城”AI
sgs.ai_skill_invoke["fcmoukongchengMY"] = function(self, data)
	local target = data:toCardUse().from
	return not self:isFriend(target)
end
sgs.ai_ajustdamage_to.fcmoukongcheng = function(self, from, to, card, nature)
    if to:isKongcheng() and card and (card:isKindOf("Slash") or card:isKindOf("Duel"))
    then
        return -99
    end
end




--FC谋陈宫
  --“明策”AI
local fcmoumingce_skill = {}
fcmoumingce_skill.name = "fcmoumingce"
table.insert(sgs.ai_skills, fcmoumingce_skill)
fcmoumingce_skill.getTurnUseCard = function(self)
	if self.player:isNude() or #self.enemies == 0 then return end
	local can_use = false
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) and not p:hasFlag("fcmoumingced") then
			can_use = true
		end
	end
	if not can_use then return end
	local card_id
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum() > self.player:getHp() then
		for _, acard in ipairs(cards) do
			if acard:isKindOf("EquipCard") or acard:isKindOf("Peach") or acard:isKindOf("Analeptic") then
				card_id = acard:getEffectiveId()
				break
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		local player = self.player
		if player:getWeapon() then card_id = player:getWeapon():getId()
		elseif player:getOffensiveHorse() then card_id = player:getOffensiveHorse():getId()
		elseif player:getDefensiveHorse() then card_id = player:getDefensiveHorse():getId()
		elseif player:getArmor() and player:getHandcardNum() <= 1 then card_id = player:getArmor():getId()
		end
	end
	if not card_id then
		for _, acard in ipairs(cards) do
			if acard:isKindOf("EquipCard") or acard:isKindOf("Peach") or acard:isKindOf("Analeptic") then
				card_id = acard:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
		for _, acard in ipairs(cards) do
			if acard:isKindOf("BasicCard") then
				card_id = acard:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#fcmoumingceCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#fcmoumingceCard"] = function(card, use, self)
    if not self.player:hasUsed("#fcmoumingceCard") and not self.player:isNude() then
        self:sort(self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do --优先考虑手牌少的
		    if friend and friend:getHandcardNum() < 2 and not self:needKongcheng(friend, true) and not friend:hasFlag("fcmoumingced") then
				use.card = card
			    if use.to then use.to:append(friend) end
		        return
			end
	    end
		for _, friend in ipairs(self.friends_noself) do
		    if friend and not self:needKongcheng(friend, true) and not friend:hasFlag("fcmoumingced") then
				use.card = card
			    if use.to then use.to:append(friend) end
		        return
			end
	    end
	end
	return nil
end

sgs.ai_skill_choice["fcmoumingce"] = function(self, choices, data)
	local current = self.room:getCurrent()
	if self:isEnemy(current) then return "2" end
	if self.player:getHp() <= 1 and not self.player:hasSkill("buqu") then return "2" end
	return "1"
end

sgs.ai_use_value.fcmoumingceCard = 8.5
sgs.ai_use_priority.fcmoumingceCard = 9.5
sgs.ai_card_intention.fcmoumingceCard = -80

    --砸人
sgs.ai_skill_invoke["fcmoumingce"] = true

sgs.ai_skill_playerchosen["fcmoumingce"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) and self.player:getMark("&fcmCe") >= p:getHp() + p:getHujia() and not self:cantDamageMore(self.player, p) and not self:cantbeHurt(p) and self:canDamage(p,self.player,nil) then --优先考虑有机会斩杀的
		    return p 
		end
	end
	for _, p in ipairs(targets) do
	    if self:isEnemy(p)  and self:canDamage(p,self.player,nil) then
		    return p 
		end
	end
	return nil
end

sgs.ai_ajustdamage_to["&fcmouzhichi"] = function(self,from,to,card,nature)
	return -99
end

--

--AH谋吕布
  --“拜父”AI
sgs.ai_skill_invoke.ahmoubaifu = true

sgs.ai_ajustdamage_from.ahmouwushuang = function(self, from, to, card, nature)
    if card and card:isDamageCard() and not card:hasFlag("ahmouwushuang"..to:objectName())
    then
        return 1
    end
end


--

----

addAiSkills("f_kuzha").getTurnUseCard = function(self)
	if self.player:getMaxHp() <= 2 then return end
    return sgs.Card_Parse("#f_kuzhaCard:.:")
end

sgs.ai_skill_use_func["#f_kuzhaCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.f_kuzhaCard = 8.4
sgs.ai_use_priority.f_kuzhaCard = 8.4


sgs.ai_ajustdamage_from.f_shenxianshizu = function(self,from,to,card,nature)
	if nature == "F" and to:getMark("zbkcTarget+to+"..from:objectName().."-Clear") > 0 then
		return 1
	end
end

local f_shenxianshizu_skill = {}
f_shenxianshizu_skill.name = "f_shenxianshizu"
table.insert(sgs.ai_skills,f_shenxianshizu_skill)
f_shenxianshizu_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() > 3 then return end
	if #self.enemies<=0 then return end
	for _,enemy in sgs.list(self.enemies)do
		if self:damageMinusHp(enemy,1)>0
		or enemy:getHp()<3 and self:damageMinusHp(enemy,0)>0 and enemy:getHandcardNum()>0
		then
			return sgs.Card_Parse("#f_shenxianshizuCard:.:")
		end
	end
	if (#self.friends>1) or (#self.enemies==1 and sgs.turncount>1) then
		if self.role=="rebel" then
			return sgs.Card_Parse("#f_shenxianshizuCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#f_shenxianshizuCard"] = function(card,use,self)
	self:sort(self.enemies,"defenseSlash")
	for _,enemy in sgs.list(self.enemies)do
		if self:damageMinusHp(enemy,1)>0
		or enemy:getHp()<3 and self:damageMinusHp(enemy,0)>0 and enemy:getHandcardNum()>0
		then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_priority["f_shenxianshizuCard"] = 10


local f_liaodu_skill = {}
f_liaodu_skill.name = "f_liaodu"
table.insert(sgs.ai_skills,f_liaodu_skill)
f_liaodu_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum()<1 then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local use_cards = {}
	local compare_func = function(a,b)
		local v1 = self:getKeepValue(a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
		return v1<v2
	end
	table.sort(cards,compare_func)
	for _,c in ipairs(cards)do
		if c:isKindOf("EquipCard") then
			table.insert(use_cards, c)
		end
	end
	if #use_cards > 0 then
		return sgs.Card_Parse("#f_liaoduCard:"..use_cards[1]:getId()..":")
	end
end

sgs.ai_skill_use_func["#f_liaoduCard"] = function(card,use,self)
	local arr1,arr2 = self:getWoundedFriend(false,true)
	local target = nil

	if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and arr1[1]:getHp()<getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		use.card = card
		use.to:append(target)
		return
	end
	if self:getOverflow()>0 and #arr2>0 then
		for _,friend in ipairs(arr2)do
			if not friend:hasSkills("hunzi|longhun") then
				use.card = card
				use.to:append(friend)
				return
			end
		end
	end
end

sgs.ai_use_priority.f_liaoduCard = 4.2
sgs.ai_card_intention.f_liaoduCard = -100

sgs.dynamic_value.benefit.f_liaoduCard = true


local f_mafei_skill = {}
f_mafei_skill.name = "f_mafei"
table.insert(sgs.ai_skills,f_mafei_skill)
f_mafei_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum()<1 then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local use_cards = {}
	local compare_func = function(a,b)
		local v1 = self:getKeepValue(a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
		return v1<v2
	end
	table.sort(cards,compare_func)
	for _,c in ipairs(cards)do
		if c:isKindOf("TrickCard") then
			table.insert(use_cards, c)
		end
	end
	if #use_cards > 0 then
		return sgs.Card_Parse("#f_mafeiCard:"..use_cards[1]:getId()..":")
	end
end
sgs.ai_skill_use_func["#f_mafeiCard"] = function(card,use,self)
	local previousAlive = self.player:getNextAlive(self.player:aliveCount()-1)
	if previousAlive and self:isFriend(previousAlive) and self:isWeak(previousAlive) then
		use.card = card
		use.to:append(previousAlive)
		return
	end
	local nextAlive = self.player
	repeat
		nextAlive = nextAlive:getNextAlive()
	until nextAlive:faceUp()
	if nextAlive and self:isEnemy(nextAlive) then
		use.card = card
		use.to:append(nextAlive)
		return
	end
	for _,friend in ipairs(self.friends_noself)do
		if not self:toTurnOver(friend,0,"f_mafei") then
			use.card = card
			use.to:append(friend)
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if self:isWeak(friend) then
			use.card = card
			use.to:append(friend)
			return
		end
	end
end

local f_wuqin_skill = {}
f_wuqin_skill.name = "f_wuqin"
table.insert(sgs.ai_skills,f_wuqin_skill)
f_wuqin_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum()<1 then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local use_cards = {}
	local compare_func = function(a,b)
		local v1 = self:getKeepValue(a)+( a:isRed() and 50 or 0 )+( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b)+( b:isRed() and 50 or 0 )+( b:isKindOf("Peach") and 50 or 0 )
		return v1<v2
	end
	table.sort(cards,compare_func)
	for _,c in ipairs(cards)do
		if c:isKindOf("BasicCard") then
			table.insert(use_cards, c)
		end
	end
	if #use_cards > 0 then
		return sgs.Card_Parse("#f_wuqinCard:"..use_cards[1]:getId()..":")
	end
end
sgs.ai_skill_use_func["#f_wuqinCard"] = function(card,use,self)
	for _,friend in ipairs(self.friends_noself)do
		use.card = card
		use.to:append(friend)
		return
	end
	for _,friend in ipairs(self.friends)do
		use.card = card
		use.to:append(friend)
		return
	end
end
sgs.ai_use_priority.f_wuqinCard = 5
sgs.ai_card_intention.f_wuqinCard = -100

sgs.ai_ajustdamage_from["&f_wuqin_tiger"] = function(self, from, to, card, nature)
    if card and (card:isKindOf("Slash") or card:isKindOf("Duel"))  then
        return 1
    end
end

sgs.ai_skill_playerchosen.f_chongzhen = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "hej")  then
            return target
        end
    end
    return nil
end

sgs.ai_skill_invoke.f_chongzhen = function(self,data)
	local target = data:toPlayer()
	self.f_chongzhenTarget = target
	return self:doDisCard(target, "hej")
end
sgs.ai_choicemade_filter.cardChosen.f_chongzhen = sgs.ai_choicemade_filter.cardChosen.snatch



--(神徐盛/神黄忠)一定概率更换皮肤
sgs.ai_skill_invoke["@f_forSXSandSHZ_changeSkin"] = function(self, data)
    if math.random() > 0.5 then return true end
	return false
end

--神徐盛
  --“魄君”AI
sgs.ai_skill_invoke["f_pojun"] = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then return true end
    return false
end

  --“怡娍”AI
sgs.ai_skill_invoke.f_yicheng = function(self, data)
	local target = data:toPlayer()
	return self:isFriend(target)
end
sgs.ai_choicemade_filter.skillInvoke.f_yicheng = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end
sgs.ai_skill_invoke.f_haishiSM = true

  --“搭妆”AI

sgs.ai_skill_invoke.f_dazhuang = true


--神黄忠
  --“开弓”AI
sgs.ai_skill_invoke.f_kaigong = function(self, data)
	local target = self.room:getTag("f_kaigong"):toPlayer()
	return not self:isFriend(target)
end

sgs.ai_ajustdamage_from.f_kaigong = function(self, from, to, card, nature)
    if card and card:hasFlag("f_kaigong")
    then
        return to:getMark("f_kaigong")
    end
end


  --“弓魂”AI
sgs.ai_skill_invoke["#f_gonghunMission"] = true


sgs.ai_card_priority.f_gonghun = function(self,card,v)
	if self.player:getMark("&f_gonghun")==2 and card:isKindOf("Slash") and ((card:isRed() and self.player:getMark("f_gonghun_2to3_red") == 0) or (card:isBlack() and self.player:getMark("f_gonghun_2to3_black") == 0))
	then return 10 end
	if self.player:getMark("&f_gonghun")==3 and card:isKindOf("Slash") and 
	((self.player:getMark("f_gonghun_3to4_"..card:getSuitString()) == 0) 
	)
	then return 10 end
	if self.player:getMark("&f_gonghun")==4 and card:isKindOf("Slash") and 
	card:isVirtualCard() and (card:subcardsLength() == 0 or card:subcardsLength() >= 4)
	then return 10 end
end

sgs.ai_ajustdamage_from.f_gonghun = function(self, from, to, card, nature)
    if from:getMark("&f_gonghun") > 1 and card and card:isKindOf("Slash")
    then
        return from:getMark("&f_gonghun") - 1
    end
end

sgs.ai_skill_invoke.Fchixieren = function(self, data)
	return self.player:getHp() < getBestHp(self.player)
end
sgs.ai_skill_invoke.Fmorigong = function(self, data)
	local damage = data:toDamage()
	return not self:isFriend(damage.to)
end

sgs.ai_ajustdamage_from.f_shanmengHS = function(self, from, to, card, nature)
    if isSpecialOne(from, "神黄忠") and isSpecialOne(from, "神徐盛")
    then
        return 1
    end
end



f_shanmengHS_skill = {}
f_shanmengHS_skill.name = "f_shanmengHS"
table.insert(sgs.ai_skills, f_shanmengHS_skill)
f_shanmengHS_skill.getTurnUseCard = function(self, inclusive)
	local deathplayer = {}
	for _, p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and p:getMaxHp() >= 2 and self:isFriend(p) then
			table.insert(deathplayer, p:getGeneralName())
		end
	end
	if #deathplayer == 0 then return end
	if not self:isWeak() and self.player:hasSkill("f_gonghun") and self.player:getMark("&f_gonghun") < 5 then return end
	if #deathplayer > 0 then
		return sgs.Card_Parse("#f_shanmengHSCard:.:")
	end
end

sgs.ai_skill_use_func["#f_shanmengHScard"] = function(card, use, self)
	use.card = sgs.Card_Parse("#f_shanmengHScard:.:")
	return
end

sgs.ai_use_value["f_shanmengHScard"] = 8
sgs.ai_use_priority["f_shanmengHScard"] = 7

