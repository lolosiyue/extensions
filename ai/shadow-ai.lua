--����
--�ʵ�
local y_rende_skill = {}
y_rende_skill.name = "y_rende"
table.insert(sgs.ai_skills, y_rende_skill)
y_rende_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() <= 1 then return end
	for _, player in ipairs(self.friends_noself) do
		if ((player:hasSkill("haoshi") and not player:containsTrick("supply_shortage"))
				or player:hasSkill("longluo") or (not player:containsTrick("indulgence") and player:hasSkill("yishe"))
				and player:faceUp()) or player:hasSkill("jijiu") then
			return sgs.Card_Parse("#y_rendecard:.:")
		end
	end
	if self.player:usedTimes("#y_rendecard") < 2 or self:getOverflow() > 0 then
		return sgs.Card_Parse("#y_rendecard:.:")
	end
	if self.player:getLostHp() > 0 then
		return sgs.Card_Parse("#y_rendecard:.:")
	end
end

sgs.ai_skill_use_func["#y_rendecard"] = function(card, use, self)
	local rd_card = {}
	local x = self.player:getHandcardNum()
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	self:sort(self.friends_noself, "defense")
	if x > 2 then
		for _, friend in ipairs(self.friends_noself) do
			for _, card in ipairs(cards) do
				use.card = sgs.Card_Parse("#y_rendecard:" .. card:getId() .. ":")
				if use.to then use.to:append(friend) end
				return
			end
		end
	elseif x == 2 then
		for _, friend in ipairs(self.friends_noself) do
			local i = 0
			for _, acard in ipairs(cards) do
				table.insert(rd_card, acard:getId())
				i = i + 1
				if i == 2 then
					use.card = sgs.Card_Parse("#y_rendecard:" .. table.concat(rd_card, "+") .. ":")
					if use.to then use.to:append(friend) end
					return
				end
			end
		end
	end
end
sgs.ai_use_value.y_rendecard = 8.5
sgs.ai_use_priority.y_rendecard = 8.8
sgs.need_kongcheng = sgs.need_kongcheng .. "|y_lianying"

sgs.ai_getLeastHandcardNum_skill.y_lianying = function(self, player, least)
	if least < 1 then
		return 1
	end
end

--����ʦ
--����
local y_anxu_skill = {}
y_anxu_skill.name = "y_anxu"
table.insert(sgs.ai_skills, y_anxu_skill)
y_anxu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#y_anxucard") then return end
	return sgs.Card_Parse("#y_anxucard:.:")
end

sgs.ai_skill_use_func["#y_anxucard"] = function(card, use, self)
	self:sort(self.friends, "hp")
	local target
	for _, friend in ipairs(self.friends) do
		if self:canDraw(friend, self.player) then
			if hasTuntianEffect( friend) then
				target = friend
                break
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends) do
			if self:canDraw(friend, self.player) then
				if self:doDisCard(friend, "he") then
					target = friend
					break
				end
			end
		end
	end
	if not target then
		for _, friend in ipairs(self.friends) do
			if self:canDraw(friend, self.player) then
				target = friend
				break
			end
		end
	end
	if target then
		use.card = sgs.Card_Parse("#y_anxucard:.:")
		if use.to then
			use.to:append(target)
		end
		return
	end
end

sgs.ai_skill_discard.y_anxu = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getCards("he")
	local x = self.player:getCardCount(true)
	cards = sgs.QList2Table(cards)
	self:sortByDynamicUsePriority(cards, true)
	local i
	for _, card in ipairs(cards) do
		table.insert(to_discard, card:getId())
		i = i + 1
		if i == discard_num then break end
	end
	return to_discard
end
sgs.ai_use_value.y_anxucard = 9
sgs.ai_use_priority.y_anxucard = 4.2
sgs.dynamic_value.benefit.y_anxucard = true

sgs.ai_skill_playerchosen.y_anxu = function(self,targets)
	local to = self:findPlayerToDiscard("hej",true,false,targets)[1]
	if to then return to end
	for _,to in sgs.qlist(targets)do
		if self:doDisCard(to,"hej") then return to end
	end
	return targets[1]
end

--������
--��װ
local y_rongzhuang_skill = {}
y_rongzhuang_skill.name = "y_rongzhuang"
table.insert(sgs.ai_skills, y_rongzhuang_skill)
y_rongzhuang_skill.getTurnUseCard = function(self)
	local hcards = self.player:getCards("h")
	local ecards = self.player:getCards("e")
	ecards = sgs.QList2Table(ecards)
	hcards = sgs.QList2Table(hcards)
	local x = self.player:getEquips():length()
	if x ~= 0 then
		local slashcard
		self:sortByUseValue(hcards, true)
		for _, hcard in ipairs(hcards) do
			for _, ecard in ipairs(ecards) do
				if ecard:getSuit() == hcard:getSuit() then
					slashcard = hcard
					break
				end
			end
			if slashcard then break end
		end
		if slashcard then
			local card_str = ("slash:y_rongzhuang[%s:%s]=%d"):format(slashcard:getSuitString(),
				slashcard:getNumberString(), slashcard:getEffectiveId())
			local slash = sgs.Card_Parse(card_str)
			assert(slash)
			return slash
		end
	end
end

function sgs.ai_cardsview.y_rongzhuang(self, class_name, player)
	local hcards = player:getCards("h")
	local ecards = player:getCards("e")
	local i = 0
	if class_name == "Jink" then
		for _, hcard in sgs.qlist(hcards) do
			i = 0
			for _, ecard in sgs.qlist(ecards) do
				if ecard:getSuit() == hcard:getSuit() then
					i = 1
					break
				end
			end
			if i == 0 then
				return ("jink:y_rongzhuang[%s:%s]=%d"):format(hcard:getSuitString(), hcard:getNumberString(),
					hcard:getEffectiveId())
			end
		end
	elseif class_name == "Slash" then
		for _, acard in sgs.qlist(hcards) do
			for _, bcard in sgs.qlist(ecards) do
				if bcard:getSuit() == acard:getSuit() then
					return ("slash:y_rongzhuang[%s:%s]=%d"):format(acard:getSuitString(), acard:getNumberString(),
						acard:getEffectiveId())
				end
			end
		end
	end
end

--����
sgs.ai_skill_invoke.y_chongqi = function(self, data)
	local p = data:toPlayer()
	return self:isEnemy(p) and self:doDisCard(p, "he")
end

sgs.y_mayunlu_keep_value =
{
	Peach = 6,
	Analeptic = 5.4,
	ExNihilo = 5.9,
	snatch = 5.3,
	EightDiagram = 5.7,
	RenwangShield = 5.8,
	OffensiveHorse = 5.1,
	DefensiveHorse = 5.2,
	Indulgence = 5.6,
	Nullification = 5.5,
	Dismantlement = 5.1,
	Crossbow = 5.0,
	Jink = 4,
	Slash = 4.1,
	ThunderSlash = 4.5,
	FireSlash = 4.9,

}

--��ά	
--־��		
sgs.ai_skill_invoke.y_zhiji = function(self, data)
	return true
end

--����	
local y_tiaoxin_skill = {}
y_tiaoxin_skill.name = "y_tiaoxin"
table.insert(sgs.ai_skills, y_tiaoxin_skill)
y_tiaoxin_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#y_tiaoxincard") then return end
	for _, enemy in ipairs(self.enemies) do
		if enemy:distanceTo(self.player) <= enemy:getAttackRange() then
			return sgs.Card_Parse("#y_tiaoxincard:.:")
		end
	end
end

sgs.ai_skill_use_func["#y_tiaoxincard"] = function(card, use, self)
	self:sort(self.enemies, "threat")
	for _, enemy in ipairs(self.enemies) do
		if enemy:distanceTo(self.player) <= enemy:getAttackRange() and
			(self:getCardsNum("Slash", enemy) == 0 or self:getCardsNum("Jink") > 0 or self.player:getHp() >= 2) and not enemy:isNude() then
			use.card = card
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end

--����
--�¾�
sgs.ai_skill_invoke.y_yongjue = function(self, data)
	local p = data:toPlayer()
	if self:isFriend(p) then
		return true
	else
		return false
	end
end

sgs.ai_skill_invoke.y_yjtargetmove = function(self, data)
	local use = data:toCardUse()
	if use.card:isKindOf("AmazingGrace") or use.card:isKindOf("ExNihilo") then return false end
	if use.card:isKindOf("GodSalvation") and self.player:isWounded() then return false end
	return true
end


--����
sgs.ai_skill_invoke.y_cunsi = function(self, data)
	if self.player:getRole() == "lord" then return false end
	if #self.friends_noself < 1 then return false end
	local x = self.player:getHandcardNum()
	if x == 1 then return true end
	local i = 0
	for _, card in sgs.qlist(self.player:getCards("h")) do
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
			i = i + 1
		end
	end
	if i > 0 then return false end
	return true
end

sgs.ai_skill_playerchosen.y_cunsi = function(self, targets)
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("longdan") then
			return friend
		end
	end
	for _, tar in sgs.qlist(targets) do
		if self:isFriend(tar) then
			return tar
		end
	end
end

sgs.ai_skill_cardchosen.y_cunsi = function(self, who, flags)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card then
			self:setCardFlag(card:getId(), "tjcard")
			break
		end
	end
	return card_for_y_toujing(self, who, "tjcard")
end

--��ٻ
--����
local y_shenzhi_skill = {}
y_shenzhi_skill.name = "y_shenzhi"
table.insert(sgs.ai_skills, y_shenzhi_skill)
y_shenzhi_skill.getTurnUseCard = function(self)
	if self.player:getHp() >= self.player:getHandcardNum() then return end
	if self.player:isWounded() then
		local card_str = ("peach:y_shenzhi[no_suit:0]=.")
		local peach = sgs.Card_Parse(card_str)
		assert(peach)
		return peach
	end
end

function sgs.ai_cardsview.y_shenzhi(self, class_name, player)
	if class_name == "Peach" then
		local x = player:getHp()
		local y = player:getHandcardNum()
		if x < 0 then x = 0 end
		if y > x then
			return ("peach:y_shenzhi[no_suit:0]=.")
		end
	end
end

function sgs.ai_cardneed.y_shenzhi(to,card)
	return to:getHandcardNum()<to:getHp()
end

--����
sgs.ai_skill_invoke.y_shushen = function(self, data)
	if #self.friends_noself > 0 then
		return true
	else
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_playerchosen.y_shushen = function(self, targets)
	self:sort(self.friends_noself, "defense")
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend, self.player) and not (friend:hasSkill("kongcheng") and friend:isKongcheng()) then
			return friend
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then
			return enemy
		end
	end
end

--����
--����
sgs.ai_skill_invoke.y_baiyi = function(self, data)
	if self.player:isNude() then return false end
	return true
end

sgs.ai_skill_invoke.y_baiyier = function(self, data)
	local players = self:findPlayerToDiscard("hej",true,false, nil, true)
	return #players > 0
end

sgs.ai_skill_playerchosen.y_baiyi = function(self, targets)
	local players = self:findPlayerToDiscard("hej",true,false, nil, true)
	for _,player in ipairs(players)do
		return player
	end
	for _, friend in ipairs(self.friends) do
		if friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage") then
			return friend
		end
		if friend:containsTrick("lightning") then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasSkill("guicai") or enemy:hasSkill("guidao") or enemy:hasSkill("guanxing") then
					return friend
				end
			end
		end
	end
	self:sort(self.enemies, "defense")
	for _, en in ipairs(self.enemies) do
		if not en:isNude() then
			return en
		end
	end
end
sgs.ai_skill_invoke.y_yuanjiu = function(self, data)
	for _, acard in sgs.qlist(self.player:getPile("y_yuanjiuPile")) do
		for _, bcard in sgs.qlist(self.player:getPile("y_yuanjiuPile")) do
			if acard ~= bcard and sgs.Sanguosha:getCard(acard):getNumber() == sgs.Sanguosha:getCard(bcard):getNumber() then
				return true
			end
		end
	end
	local dying = data:toDying()
	if self:askForSinglePeach(dying.who) and self:isFriend(dying.who) then return true end
	return false
end

local y_jiefan_skill = {}
y_jiefan_skill.name = "y_jiefan"
table.insert(sgs.ai_skills, y_jiefan_skill)
y_jiefan_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#y_jiefancard") then return nil end
	return sgs.Card_Parse("#y_jiefancard:.:")
end

sgs.ai_skill_use_func["#y_jiefancard"] = function(card, use, self)
	
	for _, friend in ipairs(self.friends) do
		if self:doDisCard(friend, "he") and self:canDraw(friend, self.player) then
			use.card = card
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end
	for _, friend in ipairs(self.friends) do
		if hasTuntianEffect(friend) and self:canDraw(friend, self.player) then
			use.card = card
			if use.to then
				use.to:append(friend)
			end
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:getEquips():length() > 0 then
			if self:doDisCard(enemy, "e") then
				use.card = card
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	end
	if self.player:canDiscard(self.player, "he") then
		use.card = card
		if use.to then
			use.to:append(self.player)
		end
	end
	return
end

sgs.ai_skill_choice.y_jiefan = function(self, choices)
	return "draw"
end

--����
--����		
y_huanshi_skill = {}
y_huanshi_skill.name = "y_huanshi"
table.insert(sgs.ai_skills, y_huanshi_skill)
y_huanshi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#y_huanshicard") then return end
	local t = 0
	for _, p in ipairs(self.friends_noself) do
		if p:getHandcardNum() > 0 then t = t + 1 end
	end
	for _, q in ipairs(self.enemies) do
		if q:getHandcardNum() > 0 then t = t + 1 end
	end
	if t > 1 then
		return sgs.Card_Parse("#y_huanshicard:.:")
	end
end

sgs.ai_skill_use_func["#y_huanshicard"] = function(card, use, self)
	if #self.friends_noself >= 1 then
		local friends = {}
		for _, friend in ipairs(self.friends_noself) do
			if not friend:isKongcheng() then
				table.insert(friends, friend)
			end
		end
		if #friends >= 2 then
			use.card = card
			if use.to then
				use.to:append(friends[1])
				use.to:append(friends[2])
				return
			end
		elseif #friends == 1 then
			self:sort(self.enemies, "defense")
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isKongcheng() then
					use.card = card
					if use.to then
						use.to:append(enemy)
						use.to:append(friends[1])
						return
					end
				end
			end
		end
	end
	return nil
end

--��Ԯ
sgs.ai_skill_use["@@y_hongyuan"] = function(self, prompt)
	local targets = {}
	for _, friend in ipairs(self.friends) do
		if self.player:inMyAttackRange(friend) or self.player:getSeat() == friend:getSeat() then
			table.insert(targets, friend:objectName())
		end
	end
	return "#y_hongyuancard:.:->" .. table.concat(targets, "+")
end

--����
--����
sgs.ai_skill_invoke.y_zishou = function(self, data)
	local x = self.player:getLostHp()
	local y = self.player:getHp()
	local j, s, p, n = 0, 0, 0, 0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Jink") then
			j = j + 1
		elseif card:isKindOf("Slash") then
			s = s + 1
		elseif card:isKindOf("Nullification") then
			n = n + 1
		elseif card:isKindOf("Peach") then
			p = p + 1
		end
	end
	if x >= 2 then
		return true
	elseif x == 1 then
		-- if s > 0 and self.player:canSlash() then
		if s > 0 then
			if y >= (j + s + n) then
				return true
			end
		elseif y > (j + s + n) then
			return true
		end
	elseif x < 1 then
		-- if s > 0 and self.player:canSlash() then
		if s > 0 then
			if (y - (j + s + n + p)) >= 2 then
				return true
			end
		elseif (y - (j + s + n + p)) > 2 then
			return true
		end
	end
	return false
end

--����

sgs.ai_skill_use["@@y_yangzheng"] = function(self, prompt)
	if self.player:getMark("y_yzRec") == 1 then return end
	if #self.friends_noself < 1 then return end
	local x = self.player:getHandcardNum()
	local y = self.player:getHp()
	if x < y then return end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	self:sort(self.friends_noself, "defense")
	local h,friend = self:getCardNeedPlayer(cards)
	if h and friend then return "#y_yangzhengcard:" .. h:getId() .. ":->" .. friend:objectName() end
	for _, friend in ipairs(self.friends_noself) do
		if not self:willSkipPlayPhase(friend) and self:canDraw(friend, self.player) then
			for _, card in ipairs(cards) do
				return "#y_yangzhengcard:" .. card:getId() .. ":->" .. friend:objectName()
			end
		end
	end
end
sgs.ai_card_intention.y_yangzhengcard = -60
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|y_yangzheng"
--½ѷ
--��Ӫ
y_fenying_skill = {}
y_fenying_skill.name = "y_fenying"
table.insert(sgs.ai_skills, y_fenying_skill)
y_fenying_skill.getTurnUseCard = function(self)
	for _, en in ipairs(self.enemies) do
		if not en:isKongcheng() and en:getHandcardNum() < self.player:getHandcardNum() and self.player:canPindian(en)
			and (en:getHandcardNum() < 3 or ((self.player:getHandcardNum() - self.player:getHp()) - en:getHandcardNum()) > -1) then
			return sgs.Card_Parse("#y_fenyingcard:.:")
		end
	end
	return
end

sgs.ai_skill_use_func["#y_fenyingcard"] = function(card, use, self)
	local tar
	self:sort(self.enemies, "defense")
	for _, en in ipairs(self.enemies) do
		if not en:isKongcheng() and en:getHandcardNum() < self.player:getHandcardNum() and self.player:canPindian(en) and self:damageIsEffective(en, sgs.DamageStruct_Fire, self.player) and not self:cantbeHurt(en) then
			tar = en
			break
		end
	end
	if tar then
		local x = tar:getHandcardNum()
		local fy_card = {}
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByDynamicUsePriority(cards, true)
		local i = 0
		for _, acard in ipairs(cards) do
			table.insert(fy_card, acard:getId())
			i = i + 1
			if i == x then break end
		end
		use.card = sgs.Card_Parse("#y_fenyingcard:" .. table.concat(fy_card, "+") .. ":")
		if use.to then
			use.to:append(tar)
		end
		return
	end
end

sgs.ai_skill_invoke.y_fenying = function(self, data)
	return true
end

--����
sgs.ai_skill_invoke.y_dushi = function(self, data)
	if self.player:getHandcardNum() < self.player:getHp() then
		return true
	else
		local players = self:findPlayerToDiscard("hej",true,false, nil, true)
		for _,player in ipairs(players)do
			return player
		end
		for _, en in ipairs(self.enemies) do
			if not en:isNude() then
				return true
			end
		end
		for _, fr in ipairs(self.friends) do
			if self:isFriend(fr) then
				if fr:containsTrick("indulgence") or fr:containsTrick("supply_shortage") then
					return true
				elseif fr:containsTrick("lightning") then
					for _, fr in ipairs(self.friends) do
						if fr:hasSkill("guicai") or fr:hasSkill("guidao") or fr:hasSkill("guanxing") then
							return false
						end
					end
					return true
				end
			end
		end
	end
	return false
end

function sgs.ai_slash_prohibit.y_dushi(self, to)
	if to:getHandcardNum() == to:getHp() then return false end
	if to:getHandcardNum() > to:getHp() then
		if to:getHp() > 1 then return true end
	end
end

sgs.ai_skill_playerchosen.y_dushi = function(self, targets)
	for _, t in sgs.qlist(targets) do
		if self:isFriend(t) then
			if t:containsTrick("indulgence") or t:containsTrick("supply_shortage") then
				return t
			elseif t:containsTrick("lightning") then
				local target = true
				for _, fr in ipairs(self.friends) do
					if fr:hasSkill("guicai") or fr:hasSkill("guidao") or fr:hasSkill("guanxing") then
						target = false
					end
				end
				if target == true then return t end
			end
		elseif self:isEnemy(t) then
			if t:getHandcardNum() == 1 and self.player:isWounded() then
				return t
			end
		end
	end
	self:sort(self.enemies, "defense")
	for _, en in ipairs(self.enemies) do
		if not en:isNude() then
			return en
		end
	end
end

--����
--�ɱ
sgs.ai_skill_invoke.y_zhensha = function(self, data)
	local player = data:toPlayer()
	return self:isEnemy(player)
end

--ʶ��
sgs.ai_skill_invoke.y_shipo = function(self, data)
	for _, p in ipairs(self.enemies) do
		if not p:isKongcheng() then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.y_shipo = function(self, targets)
	self:sort(self.enemies, "defense")
	local pattern
	if self.room:getCurrentDyingPlayer() then
		if self.room:getCurrentDyingPlayer():objectName() == self.player:objectName() then
			pattern = "peach+analeptic"
		else
			pattern = "peach"
		end
	else
		pattern = self.room:getTag("y_shipo"):toStringList()[1]
	end
	if pattern then
		for _, p in ipairs(self.enemies) do
			if not p:isKongcheng() and getKnownCard(p, self.player, pattern) > 0 then
				return p
			end
		end
	end
	for _, p in ipairs(self.enemies) do
		if not p:isKongcheng() then
			return p
		end
	end
end

function sgs.ai_slash_prohibit.y_shipo(self, to)
	if to:getHp() == 1 then
		return self:getCardsNum("Analpetic") + self:getCardsNum("Peach") > 0
	end
	return self:getCardsNum("Jink") > 0 and (self.player:getHandcardNum() - self:getCardsNum("Jink")) < 2
end

--�����
--���
local y_wuji_skill = {}
y_wuji_skill.name = "y_wuji"
table.insert(sgs.ai_skills, y_wuji_skill)
y_wuji_skill.getTurnUseCard = function(self)
	if self.player:hasFlag("addjink") and self.player:hasFlag("addtar") and self.player:hasFlag("addrange") then return end
	-- if not self.player:canSlashWithoutCrossbow() and not (self.player:getWeapon() and self.player:getWeapon():getClassName() == "Crossbow") then return end
	return sgs.Card_Parse("#y_wujicard:.:")
end

sgs.ai_skill_use_func["#y_wujicard"] = function(card, use, self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local slashcount = self:getCardsNum("Slash")
	if slashcount>0 then
		local slash = self:getCard("Slash")
		if slash then
			self.player:setFlags("slashNoDistanceLimit")
			local dummy_use = self:aiUseCard(slash, dummy(true, 1))
			self.player:setFlags("-slashNoDistanceLimit")
			self.Y_wuji = ""
			if not dummy_use.to:isEmpty() then
				if dummy_use.to:length() > 1 and not self.player:hasFlag("addtar") then
					self.Y_wuji = "addtar"
				end
				for _, p in sgs.qlist(dummy_use.to) do
					if not self.player:hasFlag("addrange") and not self.player:inMyAttackRange(p) and self.player:inMyAttackRange(p, 1) then
						self.Y_wuji = "addrange"
					end
				end
				if self.Y_wuji == "" and not self.player:hasFlag("addjink") then
					self.Y_wuji = "addjink"
				end
				if self.Y_wuji ~= "" then
					for _, card in ipairs(cards) do
						if not card:isKindOf("Peach") then
							if self:getCardsNum("Slash") > 1 then
								use.card = sgs.Card_Parse("#y_wujicard:" .. card:getId() .. ":")
								return
							elseif not card:isKindOf("Slash") then
								use.card = sgs.Card_Parse("#y_wujicard:" .. card:getId() .. ":")
								return
							end
						end
					end
				end
			end
		end
	end
end

sgs.ai_skill_choice.y_wujicard = function(self, choices)
	return self.Y_wuji
end

--����
sgs.ai_skill_invoke.y_laoyue = true

sgs.ai_use_value.y_wujicard = 4
sgs.ai_use_priority.y_wujicard = sgs.ai_use_priority.Slash + 1
sgs.hit_skill = sgs.hit_skill .. "|y_wuji"

sgs.ai_cardneed.y_wuji = sgs.ai_cardneed.slash

--��Ԫ
--����
local y_shenzhu_skill = {}
y_shenzhu_skill.name = "y_shenzhu"
table.insert(sgs.ai_skills, y_shenzhu_skill)
y_shenzhu_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	if self.player:hasUsed("#y_shenzhucard") then return end
	--if self.player:hasFlag("y_szempty") then return end
	local sz = false
	for _, card in sgs.qlist(self.player:getCards("h")) do
		if card:isKindOf("Slash") then
			sz = true
			break
		end
	end
	if sz == true then
		return sgs.Card_Parse("#y_shenzhucard:.:")
	end
end

sgs.ai_skill_use_func["#y_shenzhucard"] = function(card, use, self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then
			use.card = sgs.Card_Parse("#y_shenzhucard:" .. card:getId() .. ":")
			return
		end
	end
end

sgs.ai_skill_askforag.y_shenzhu = function(self, card_ids)
	--self:sortByUseValue(card_ids)
	local pc = self:poisonCards(card_ids)
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if not table.contains(pc,card) then
			if card:isKindOf("EquipCard") then
				local i = card:getRealCard():toEquipCard():location()
				for _, p in ipairs(self.friends) do
					if p:hasEquipArea(i) and not p:getEquip(i) and (self:loseEquipEffect(p) or self:hasSkills(sgs.need_equip_skill, p)) then
						return id
					end
				end
				for _, p in ipairs(self.friends) do
					if p:hasEquipArea(i) and not p:getEquip(i) then
						return id
					end
				end
			end
		end
	end
	local cid
	for _, id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("FireSlash") then
			cid = id
			break
		elseif card:isKindOf("ThunderSlash") then
			cid = id
		elseif sgs.Sanguosha:getCard(id):isKindOf("Slash") and not card:isKindOf("ThunderSlash") then
			cid = id
		end
	end
	if cid ~= nil then return cid end
end
sgs.ai_cardneed.y_shenzhu = sgs.ai_cardneed.slash

sgs.ai_skill_playerchosen.y_shenzhu = function(self, targets)
	for _, tar in sgs.qlist(targets) do
		if self:isFriend(tar) and (self:loseEquipEffect(tar) or self:hasSkills(sgs.need_equip_skill, tar)) then
			return tar
		end
	end
	for _, tar in sgs.qlist(targets) do
		if self:isFriend(tar) then
			return tar
		end
	end
end

--����
sgs.ai_skill_invoke.y_bailian = function(self, data)
	return true
end


sgs.ai_skill_playerchosen.y_bailian = function(self, targets)
	for _, tar in sgs.qlist(targets) do
		if self:isFriend(tar) and (self:loseEquipEffect(tar)) then
			return tar
		end
	end
	for _, tar in sgs.qlist(targets) do
		if self:isFriend(tar) and self:doDisCard(tar, "e") then
			return tar
		end
	end
	for _, tar in sgs.qlist(targets) do
		if self:isEnemy(tar) and self:doDisCard(tar, "e") then
			return tar
		end
	end
end

--�Ƴ���
--����
sgs.ai_skill_invoke.y_caipei = function(self, data)
	for _, fr in ipairs(self.friends) do
		if not fr:isKongcheng() then
			return self:getCardsNum("Peach") < self.player:getHandcardNum()
		end
	end
end

sgs.ai_skill_playerchosen.y_caipei = function(self, targets)
	local cur = self.room:getCurrent()
	if self:isFriend(cur) and self:canDraw(cur, self.player) then
		return cur
	else
		local to = self:findPlayerToDraw(true,1)
		if to then
			return to
		end
		return self.player
	end
end
sgs.ai_playerchosen_intention.y_caipei = -80

function sgs.ai_cardneed.y_caipei(to, card)
	return card:getTypeId() == sgs.Card_TypeTrick
end

sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|y_caipei"

--����
sgs.ai_skill_invoke.y_kongzhen = function(self, data)
	local player = data:toPlayer()
	return self:isFriend(player)
end


--½��
--����
sgs.ai_skill_invoke.y_huaiju = function(self, data)
	local move = data:toMoveOneTime()
	if move.from:getSeat() ~= self.player:getSeat() then
		return true
	elseif move.from:getSeat() == self.player:getSeat() then
		if #self.friends_noself > 0 then return true end
	end
	return false
end

sgs.ai_skill_playerchosen.y_huaiju = function(self, targets)
	self:sort(self.friends_noself, "defense")
	local card = sgs.Sanguosha:getCard(self.player:getMark("y_huaiju"))
	local cards = { card }
	local h,friend = self:getCardNeedPlayer(cards, false)
	if h and friend then
		return friend
	end
	for _, fr in ipairs(self.friends_noself) do
		if self:canDraw(fr, self.player) then
			return fr
		end
	end
	for _, fr in ipairs(self.friends_noself) do
		return fr
	end
	return targets:first()
end
sgs.ai_playerchosen_intention.y_huaiju = -80

--����
sgs.ai_skill_use["@@y_huntian"] = function(self, prompt)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local htcard
	local nextplayer = self.player:getNextAlive()
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if (self.player:containsTrick("supply_shortage") and card:getSuit() == sgs.Card_Club)
			or (self.player:containsTrick("indulgence") and card:getSuit() == sgs.Card_Heart)
			or (self.player:containsTrick("lightning") and card:getSuit() ~= sgs.Card_Spade) then
			htcard = card
			break
		end
	end
	if not htcard then
		for _, acard in ipairs(cards) do
			if self:isFriend(nextplayer) then
				if (nextplayer:containsTrick("supply_shortage") and acard:getSuit() == sgs.Card_Club)
					or (nextplayer:containsTrick("indulgence") and acard:getSuit() == sgs.Card_Heart)
					or (nextplayer:containsTrick("lightning") and acard:getSuit() ~= sgs.Card_Spade) then
					htcard = acard
					break
				end
			elseif self:isEnemy(nextplayer) then
				if (nextplayer:containsTrick("lightning") and acard:getSuit() == sgs.Card_Spade) then
					htcard = acard
					break
				end
			end
		end
	end
	if not htcard then
		for _, c in ipairs(cards) do
			if c then
				htcard = c
				break
			end
		end
	end
	return "#y_huntiancard:" .. htcard:getId() .. ":"
end

sgs.ai_skill_choice.y_huntian = function(self, choices)
	local heart, spade, club, spade, notspade
	local peach = 0
	for _, c in sgs.qlist(self.player:getCards("h")) do
		if c:getSuit() == sgs.Card_Heart then
			heart = true
		elseif c:getSuit() == sgs.Card_Spade then
			spade = true
		elseif c:getSuit() == sgs.Card_Club then
			club = true
		end
		if c:getSuit() ~= sgs.Card_Spade then
			notspade = true
		elseif c:getSuit() == sgs.Card_Spade then
			spade = true
		end
		if c:isKindOf("Peach") then
			peach = peach + 1
		end
	end
	local nextplayer = self.player:getNextAlive()
	if (self.player:containsTrick("supply_shortage") and club == true)
		or (self.player:containsTrick("indulgence") and heart == true)
		or (self.player:containsTrick("lightning") and notspade == true) then
		return "1"
	elseif self.player:getHandcardNum() == peach then
		if self.player:isWounded() then
			return "2"
		elseif self:isFriend(nextplayer) and nextplayer:isWounded() and not nextplayer:containsTrick("supply_shortage") and not nextplayer:containsTrick("indulgence") then
			return "4"
		else
			return "2"
		end
	elseif self:isFriend(nextplayer) then
		if nextplayer:containsTrick("supply_shortage") then
			if club == true then
				return "3"
			else
				return "5"
			end
		elseif nextplayer:containsTrick("indulgence") then
			if heart == true then
				return "3"
			else
				return "2"
			end
		elseif nextplayer:containsTrick("lightning") then
			if notspade == true then
				return "3"
			else
				return "5"
			end
		else
			return "5"
		end
	elseif self:isEnemy(nextplayer) then
		if nextplayer:containsTrick("lightning") then
			if spade == true then
				return "3"
			else
				return "5"
			end
		else
			return "4"
		end
	else
		return "4"
	end
end

sgs.ai_skill_invoke.y_huntian2 = true

sgs.ai_skill_choice.y_huntian2 = function(self, choices, data)
	local p = data:toPlayer()
	local items = choices:split("+")
	if self:isFriend(p) then
		return "htdraw"
	else
		return "htdiscard"
	end
	return items[1]
end

--����
--δ��
sgs.ai_skill_invoke.y_weiji = function(self, data)
	if self.player:getMaxHp() == 1 then
		if self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0 then
			return true
		end
	elseif self.player:getMaxHp() > 1 then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.y_weiji = function(self, targets)
	self:sort(self.friends, "defense")
	local to = self:findPlayerToDraw(true, self.player:getHp())
	if to then return to end
	local minhp = 9
	local minhcards = 99
	local tar = self.player
	for _, fr in ipairs(self.friends) do
		if fr:getHp() < minhp and (not fr:containsTrick("indulgence")) and not ((fr:hasSkill("kongcheng") or fr:hasSkill("kongzhen")) and fr:isKongcheng()) then
			minhp = fr:getHp()
			tar = fr
		elseif fr:getHandcardNum() == minhcards and (not fr:containsTrick("indulgence")) and not ((fr:hasSkill("kongcheng") or fr:hasSkill("kongzhen")) and fr:isKongcheng()) then
			minhcards = fr:getHandcardNum()
			tar = fr
		end
	end
	return tar
end
sgs.ai_playerchosen_intention.y_weiji = -80

--����
function sgs.ai_cardsview.y_jiushang(self, class_name, player)
	if class_name == "Analeptic" then
		if player:getMaxHp() > 1 and player:getLostHp() > 0 then
			return ("analeptic:y_jiushang[no_suit:0]=.")
		end
	end
end

--½��
--��ϧ
y_xiangxi_skill = {}
y_xiangxi_skill.name = "y_xiangxi"
table.insert(sgs.ai_skills, y_xiangxi_skill)
y_xiangxi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#y_xiangxicard") then return end
	if #self.friends_noself > 0 then
		return sgs.Card_Parse("#y_xiangxicard:.:")
	end
end

sgs.ai_skill_use_func["#y_xiangxicard"] = function(card, use, self)
	self:sort(self.friends_noself,"handcard")
	local target
	local tarA, tarB, tarC, tarD, tarE
	for _, f in ipairs(self.friends_noself) do
		if (f:containsTrick("supply_shortage") or f:containsTrick("indulgence")) and (self.player:getHandcardNum() - self.player:getHp()) < 2 then
			tarA = f
		elseif f:getEquips():length() > 0 then
			if self:loseEquipEffect(f) then
				tarC = f
			end
		elseif (self.player:getMark("y_kegou") ~= 1 and self.player:getHandcardNum() - self.player:getHp() > 1 and f:getHandcardNum() < self.player:getHandcardNum()) then
			tarC = f
		elseif self.player:isWounded() then
			tarD = f
		else
			tarE = f
		end
	end
	if tarE then target = tarE end
	if tarD then target = tarD end
	if tarC then target = tarC end
	if tarA then target = tarA end
	if not target and self:getOverflow() > 0 then
		for _, f in ipairs(self.friends_noself) do
			if f:getHandcardNum() < self.player:getHandcardNum() then
				target = f
				break
			end
		end
	end
	if target ~= nil then
		use.card = card
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_choice.y_xiangxi = function(self, choices, data)
	local lk = data:toPlayer()
	if self:isFriend(lk) and self.player:isWounded() and math.abs(lk:getHandcardNum() - self.player:getHandcardNum()) < 2 then
		return "j"
	elseif lk:getHandcardNum() - self.player:getHandcardNum() > 1 then
		return "h"
	elseif self.player:containsTrick("supply_shortage") or self.player:containsTrick("indulgence") then
		return "j"
	elseif self:isFriend(lk) and (lk:containsTrick("supply_shortage") or lk:containsTrick("indulgence")) then
		return "j"
	elseif (self:loseEquipEffect(self.player) and self.player:getEquips():length()>0) or (self:isFriend(lk) and self:loseEquipEffect(lk)and lk:getEquips():length()>0) then
		return "e"
	elseif self:isWeak() then
		return "j"
	else
		return "h"
	end
end

--�˹�
sgs.ai_skill_invoke.y_kegou = true
sgs.ai_target_revises.y_kegou = function(to, card)
	if card:isKindOf("Indulgence")
	then
		return true
	end
end

--���
sgs.ai_skill_invoke.y_yingzi = true

--��³��
--�ؾ�
sgs.ai_skill_invoke.y_shouju = function(self, data)
	local id = data:toInt()
	local card = sgs.Sanguosha:getCard(id)
	local sj = false
	self:sort(self.friends, "defense")
	if card:isKindOf("EquipCard") then
		local i = card:getRealCard():toEquipCard():location()
		for _, p in ipairs(self.friends) do
			if p:hasEquipArea(i) and not p:getEquip(i) then
				sj = true
				break
			end
		end
	end
	if sj == false then return false end
	for _, c in sgs.qlist(self.player:getCards("h")) do
		if c:isKindOf("Basic") and not c:isKindOf("Peach") then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.y_shouju = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local card = sgs.Sanguosha:getCard(self.room:getTag("y_shouju"):toInt())
	if card and card:isKindOf("EquipCard") then
		local i = card:getRealCard():toEquipCard():location()
		for _, t in ipairs(targets) do
			if self:isFriend(t) then
				if t:hasEquipArea(i) and not t:getEquip(i) and (self:loseEquipEffect(t) or self:hasSkills(sgs.need_equip_skill, t)) then
					return t
				end
			end
		end
		for _, t in ipairs(targets) do
			if self:isFriend(t) then
				if t:hasEquipArea(i) and not t:getEquip(i) then
					return t
				end
			end
		end
	end
	if card and card:isKindOf("DelayedTrick") then
		for _, t in ipairs(targets) do
			if self:isEnemy(t) and (not self.player:isProhibited(t, card) and t:hasJudgeArea() and not t:containsTrick(card:objectName())) then
				return t
			end
		end
	end
	return nil
end
sgs.ai_skill_cardask["y_shouju"] = function(self, data, pattern)
	local hcards = self.player:getCards("h")
	hcards = sgs.QList2Table(hcards)
	self:sortByUseValue(hcards, true)
	local card
	for _, hcard in ipairs(hcards) do
		if hcard:isKindOf("BasicCard") then
			card = hcard
		end
	end
	local targets = sgs.SPlayerList()
	local use_card = sgs.Sanguosha:getCard(data:toInt())
	if use_card:isKindOf("EquipCard") then
		local i = use_card:getRealCard():toEquipCard():location()
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:hasEquipArea(i) and not p:getEquip(i) then
				targets:append(p)
			end
		end
	elseif use_card:isKindOf("DelayedTrick") then
		local no = true
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			for _, c in sgs.qlist(p:getJudgingArea()) do
				if c:objectName() == use_card:objectName() then
					no = false
					break
				end
			end
			if no == true then
				targets:append(p)
			end
		end
	end
	self.room:setTag("y_shouju", data)
	if card and sgs.ai_skill_playerchosen.y_shouju(self, targets) ~= nil then
		self.room:removeTag("y_shouju")
		return "$" .. card:getEffectiveId()
	end
	self.room:removeTag("y_shouju")
end



--����
sgs.ai_skill_invoke.y_wenliang = function(self, data)
	local p = data:toPlayer()
	if self:isFriend(p) then
		if p:getArmor() and p:getArmor():objectName() == "silverlion" and p:isWounded() then return true end
		if not (p:getArmor() and p:getArmor():isKindOf("EightDiagram")) then
			if p:getHandcardNum() < 2 and p:getHp() == 1 then return true end
			for _, c in sgs.qlist(self.player:getCards("h")) do
				if not c:isKindOf("Peach") then
					return true
				end
			end
		else
			return p:isKongcheng() and p:getHp() == 1
		end
	elseif self:isEnemy(p) then
		if p:getHp() == 1 or p:getHandcardNum() <= 1 then
			return false
		elseif (p:getArmor() and (p:getArmor():isKindOf("EightDiagram") or p:getArmor():isKindOf("RenwangShield")))
			or (p:getDefensiveHorse() or p:getWeapon() or p:getOffensiveHorse()) then
			return true
		end
	end
	return false
end

--����
sgs.ai_skill_invoke.y_duoqi = function(self, data)
	return true
end


sgs.ai_skill_invoke.y_youfang = function(self, data)
	local move = data:toMoveOneTime()
	if not move.from or not move.from:isAlive() then return false end
	if move.from and self:isFriend(move.from) then
		return true
	end
	return false
end

sgs.ai_skill_choice.y_youfang = function(self, choices, data)
	local move = data:toMoveOneTime()
	local target = move.from
	choices = choices:split("+")
	if self:isFriend(target) then
		if table.contains(choices, "recover") and target:getLostHp() > 0 and self:isWeak(target) then
			return "recover"
		end
		if table.contains(choices, "draw") and self:needBear(target) then
			return "draw"
		end
		if table.contains(choices, "recover") and target:getLostHp() > 0 then
			return "recover"
		end
	end
	return "draw"
end


sgs.ai_skill_invoke.y_zhixi = function(self, data)
	local move = data:toMoveOneTime()
	if not move.to or not move.to:isAlive() then return false end
	if move.to and self:isFriend(move.to) then
		return false
	end
	return true
end


sgs.ai_skill_invoke.y_xiaoyi = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.y_xiaoyi = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local card = self.player:getTag("y_xiaoyi"):toCard()
	local cards = sgs.CardList()
	cards:append(card)
	local cards = sgs.QList2Table(cards)
	local c, friend = self:getCardNeedPlayer(cards)
	if c and friend then
		return friend
	end
	return self.player
end
sgs.lose_equip_skill = sgs.lose_equip_skill .. "|y_xiaoyi"

local y_lianzhu_skill = {}
y_lianzhu_skill.name = "y_lianzhu"
table.insert(sgs.ai_skills, y_lianzhu_skill)
y_lianzhu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#y_lianzhucard") then
		return sgs.Card_Parse("#y_lianzhucard:.:")
	end
end

sgs.ai_skill_use_func["#y_lianzhucard"] = function(card, use, self)
	self:updatePlayers()
	local targets = {}


	for _, friend in ipairs(self.friends) do
		table.insert(targets, friend:objectName())
	end


	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local discard_cards = {}

	for _, c in ipairs(handcards) do
		if not c:isKindOf("Peach")
			and not c:isKindOf("Duel")
			and not c:isKindOf("Indulgence")
			and not c:isKindOf("SupplyShortage")
			and not (self:getCardsNum("Jink") == 1 and c:isKindOf("Jink"))
			and not (self:getCardsNum("Analeptic") == 1 and c:isKindOf("Analeptic"))
		then
			table.insert(discard_cards, c:getEffectiveId())
			if (#discard_cards >= #targets) then break end
		end
	end
	if #discard_cards > 0 and #discard_cards == #targets then
		use.card = sgs.Card_Parse(string.format("#y_lianzhucard:%s:", table.concat(discard_cards, "+")))
		if use.to then
			for _, friend in ipairs(self.friends) do
				if use.to:length() < #discard_cards then
					use.to:append(friend)
				else
					break
				end
			end
		end
	end
end

sgs.ai_skill_invoke.y_fanjin = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.y_fanjin = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")

	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not p:isKongcheng() then
			local list = self.player:property("y_fanjin"):toString():split("+")
			if #list > 0 then
				local allhas = true
				for _, l in pairs(list) do
					local handcards = sgs.QList2Table(p:getCards("h"))
					local has = false
					for _, c in ipairs(handcards) do
						if c:getEffectiveId() == tonumber(l) then
							has = true
						end
						if not has then
							allhas = false
						end
					end
				end
				if not allhas then
					return p
				end
			end
		end
	end
	for _, p in ipairs(targets) do
		if not self:isFriend(p) and not p:isKongcheng() then
			local list = self.player:property("y_fanjin"):toString():split("+")
			if #list > 0 then
				local allhas = true
				for _, l in pairs(list) do
					local handcards = sgs.QList2Table(p:getCards("h"))
					local has = false
					for _, c in ipairs(handcards) do
						if c:getEffectiveId() == tonumber(l) then
							has = true
						end
						if not has then
							allhas = false
						end
					end
				end
				if not allhas then
					return p
				end
			end
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and not p:isKongcheng() then
			local list = self.player:property("y_fanjin"):toString():split("+")
			if #list > 0 then
				local allhas = true
				for _, l in pairs(list) do
					local handcards = sgs.QList2Table(p:getCards("h"))
					local has = false
					for _, c in ipairs(handcards) do
						if c:getEffectiveId() == tonumber(l) then
							has = true
						end
						if not has then
							allhas = false
						end
					end
				end
				if not allhas then
					return p
				end
			end
		end
	end
	return targets[1]
end

sgs.ai_skill_cardchosen.y_fanjin = function(self, who, flags)
	local handcards = sgs.QList2Table(who:getHandcards())
	local list = self.player:property("y_fanjin"):toString():split("+")
	if #list > 0 then
		for _, l in pairs(list) do
			for _, c in ipairs(handcards) do
				if c:getEffectiveId() == tonumber(l) then
					return c:getEffectiveId()
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_use["@@y_xianzhou"] = function(self, prompt)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local to_discard = {}
	self:sortByKeepValue(cards)

	local damage = self.room:getTag("y_xianzhou"):toDamage()
	local from = damage.from
	if not from or from:isDead() then return "." end
	local to = self.player
	local n = damage.damage
	local nature = damage.nature
	if self:needToLoseHp(to, from, damage.card) or not self:damageIsEffective(to, nature, from) then return "." end
	if self:isFriend(from) then
		for _, card in ipairs(cards) do
			table.insert(to_discard, card:getEffectiveId())
			if #to_discard == self.player:getHp() then
				break
			end
		end
		if #to_discard == self.player:getHp() then
			return "#y_xianzhoucard:" .. table.concat(to_discard, "+") .. ":"
		end
	else
		if n > 1 or self:hasHeavyDamage(from, damage.card, to) or self:needToThrowCard(from) or self.player:getHp() <= 1 then
			for _, card in ipairs(cards) do
				if not card:isKindOf("Peach") then
					table.insert(to_discard, card:getEffectiveId())
					if #to_discard == self.player:getHp() then
						break
					end
				end
			end
			if #to_discard == self.player:getHp() then
				return "#y_xianzhoucard:" .. table.concat(to_discard, "+") .. ":"
			end
		else
			for _, card in ipairs(cards) do
				if #to_discard == self.player:getHp() then
					break
				end
				if not self:keepCard(card) then
					table.insert(to_discard, card:getEffectiveId())
				end
			end
			if #to_discard == self.player:getHp() then
				return "#y_xianzhoucard:" .. table.concat(to_discard, "+") .. ":"
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.y_huiyu = function(self, data)
	local use = data:toCardUse()
	local slash = sgs.Sanguosha:cloneCard("slash", use.card:getSuit(), use.card:getNumber())
	slash:deleteLater()
	local targets = sgs.QList2Table(use.to)
	if self.player:objectName() == use.from:objectName() then
		for _, p in ipairs(targets) do
			if self:isFriend(p) and self.player:canSlash(p) and not self:slashProhibit(slash, p)
				and self:slashIsEffective(slash, p) and self:dontHurt(p, self.player)
			then
				return false
			end
		end
		for _, p in ipairs(targets) do
			if self:isEnemy(p) and self.player:canSlash(p) and not self:slashProhibit(slash, p)
				and self:slashIsEffective(slash, p) and self:isGoodTarget(p, self.enemies, slash)
			then
				return true
			end
		end
		return true
	else
		if self:needToLoseHp(self.player, use.from, use.card) then
			return true
		end
		for _, p in ipairs(targets) do
			if self:isEnemy(p) and self.player:canSlash(p) and not self:slashProhibit(slash, p)
				and self:slashIsEffective(slash, p) and self:isGoodTarget(p, self.enemies, slash)
			then
				return true
			end
		end
	end
	return false
end
