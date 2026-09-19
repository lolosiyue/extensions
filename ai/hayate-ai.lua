-- 黑
sgs.ai_keep_value.DoubleSword = 8

-- TODO 需要优化
sgs.ai_skill_invoke.diansuo = function(self, data)
	local damage = data:toDamage()
	if damage.from:objectName() == self.player:objectName() then
		if self:isFriend(damage.to) and self.player:getRole() ~= "renegade" then return false end
		return true
	else
		if self:isFriend(damage.to) then return true end
		return false
	end
end


-- TODO 需求更高效率的做法
sgs.ai_skill_playerchosen.diansuo = function(self, targets)
	if self.player:isChained() then
		if self.player:getRole() == "renegade" then
			for _, target in sgs.qlist(targets) do
				if self:isEnemy(target) then return target end
			end
		end
		if self.player:getRole() == "loyalist" then
			for _, target in sgs.qlist(targets) do
				if target:isLord() then return target end
			end
		end
		if self.player:getRole() == "rebel" then
			for _, target in sgs.qlist(targets) do
				if target:getRole() == "loyalist" then return target end
			end
		end
		for _, target in sgs.qlist(targets) do
			if self.player:objectName() ~= target:objectName() then return target end
		end
	else
		return self:findPlayerToDamage(nil, nil, nil, targets)
	end

end

--枪兵
sgs.ai_skill_invoke.bimie = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isEnemy(target) then
		return true
	end
	return false
end

--钢铁
sgs.ai_skill_invoke.gangqu = function(self, data)
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("BasicCard") or card:isKindOf("TrickCard") then
			return true
		end
	end
	return false
end

sgs.ai_skill_invoke.gangquPrevent = function(self, data)
	local effect = data:toCardEffect()
	return not (effect.card:isKindOf("Peach") or effect.card:isKindOf("AmazingGrace") or effect.card:isKindOf("KeyTrick") or effect.card:isKindOf("GodSalvation") or (effect.card:isKindOf("MapoTofu") and effect.from and self:isFriend(effect.from)))
end

sgs.ai_skill_cardchosen.gangqu = function(self, who, flags)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards) do
		if card:isKindOf("BasicCard") then
			return card
		end
		if card:isKindOf("TrickCard") then
			return card
		end
	end
	return cards[1]
end


tiaojiao_skill={}
tiaojiao_skill.name="tiaojiao"
table.insert(sgs.ai_skills,tiaojiao_skill)
tiaojiao_skill.getTurnUseCard=function(self,inclusive)
	if self.player:hasUsed("TiaojiaoCard") then return end
	for _,friend in ipairs(self.friends) do
		if friend:getJudgingArea():length() > 0 then
			return sgs.Card_Parse("@TiaojiaoCard=.")
		end
	end
	if #self.enemies < 1 then return end
	if #self.enemies == 1 and self.enemies[1]:isNude() then return end
	return sgs.Card_Parse("@TiaojiaoCard=.")
end

sgs.ai_skill_use_func.TiaojiaoCard = function(card,use,self)
	local target
	local source = self.player
	for _,enemy in ipairs(self.enemies) do
		if not enemy:isNude() then
			target = enemy
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if enemy:getHp() == 2 and not enemy:isNude() then
			target = enemy
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if enemy:getHp() == 1 and not enemy:isNude() then
			target = enemy
		end
	end
	for _,friend in ipairs(self.friends) do
		if friend:getJudgingArea():length() > 0 then
			target = friend
		end
	end
	if target then
		use.card = sgs.Card_Parse("@TiaojiaoCard=.")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value.TiaojiaoCard = 8
sgs.ai_use_priority.TiaojiaoCard  = 10
sgs.ai_card_intention.TiaojiaoCard = 30


sgs.ai_skill_playerchosen.tiaojiao = function(self, targets)
	local target
	if #self.enemies > 0 then
		local cards = 0
		for _,enemy in ipairs(self.enemies) do
			if enemy:isAlive() then
				target = enemy
			end
		end
		for _,enemy in ipairs(self.enemies) do
			if enemy:isAlive() and enemy:getHandcardNum() == 1 then
				target = enemy
			end
		end
		if target then return target end
	end
end

--女王
sgs.ai_view_as.yaojing = function(card, player, card_place)
	if not player:hasFlag("Yaojing_Active") then return end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id =card:getEffectiveId()
	return ("god_salvation:yaojing[%s:%s]=%d"):format(suit, number, card_id)
end

sgs.ai_skill_invoke.yaojing = function(self, data)
	return true
end

sgs.ai_use_value.yaojing = 9
sgs.ai_use_priority.yaojing  = 6

sgs.ai_skill_choice.gongming = function(self, choices, data)
	-- local selfplayer=self.room:findPlayerBySkillName("gongming")
	-- if not selfplayer then return end
	-- if self:isFriend(selfplayer) and self.player:getHandcardNum() < 6 then return "hedraws" end
	return  "youdraw"
end


--杉崎鍵
sgs.ai_skill_invoke.kurimu = function(self, data)
	return true
end

sgs.ai_skill_invoke.minatsu = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_skill_invoke.chizuru = function(self, data)
	return true
end

sgs.ai_skill_invoke.mafuyu = function(self, data)
	if #self.enemies == 0 then return false end
	return true
end

sgs.ai_skill_playerchosen.kurimu = function(self, targets)
	for _,friend in ipairs(self.friends) do
		if friend:getHandcardNum() < 3 and friend:objectName() ~= self.player:objectName() then
			return friend
		end
	end
	for _,friend in ipairs(self.friends) do
		if friend:objectName() ~= self.player:objectName() then
			return friend
		end
	end
	return targets:at(0)
end

sgs.ai_skill_playerchosen.minatsu = function(self, targets)
	if #self.enemies == 0 then return self.player end
	self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if enemy then
			return enemy
		end
	end
	return self.enemies[1]
end

sgs.ai_skill_playerchosen.chizuru = function(self, targets)
	local minHp = 100
	local target
	for _,friend in ipairs(self.friends) do
		local hp = friend:getHp()
		if friend:getHp()==friend:getMaxHp() then
			hp = 1000
		end
		if self:hasSkills(sgs.masochism_skill, friend) then
			hp = hp - 1
		end
		if friend:isLord() then
			hp = hp - 1
		end
		if hp < minHp then
			minHp = hp
			target = friend
		end
	end
	if target then
		return target
	end
	return self.player
end

sgs.ai_skill_playerchosen.mafuyu = function(self, targets)
	local card_num = 0
	local target
	if #self.enemies == 0 then return self.player end
	for _,enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() - enemy:getHp() > card_num then
			target = enemy
			card_num = enemy:getHandcardNum() - enemy:getHp()
		end
	end
	if target then
		return target
	end
	return self.enemies[1]
end


sgs.ai_skill_use["@@haremu"] = function(self)

	local target = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("haremu_target") then
			target = p
			break
		end
	end
	if not target then return end
	if #self.enemies == 0 then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)

	local damaged = sgs.ai_skill_playerchosen.chizuru(self, self.room:getAlivePlayers()):getLostHp()
	local hurt = damaged > 0
	local need_help = damaged > 1

	local weak = sgs.ai_skill_playerchosen.minatsu(self, self.room:getAlivePlayers()):getHp() == 1

	if self:isEnemy(target) then
		if self:isWeak() then return "." end
		for _,acard in ipairs(cards) do
			if self:getKeepValue(acard)<5 and acard:getSuit() == sgs.Card_Spade then
				return "@HaremuCard="..acard:getEffectiveId().."->"..target:objectName()
			end
			if self:getKeepValue(acard)<5 and acard:getSuit() == sgs.Card_Heart and need_help then
				return "@HaremuCard="..acard:getEffectiveId().."->"..target:objectName()
			end
			if self:getKeepValue(acard)<5 and acard:getSuit() == sgs.Card_Club and weak then
				return "@HaremuCard="..acard:getEffectiveId().."->"..target:objectName()
			end
		end
	else
		for _,acard in ipairs(cards) do
			if acard:getSuit() == sgs.Card_Spade then
				return "@HaremuCard="..acard:getEffectiveId().."->"..target:objectName()
			end
			if acard:getSuit() == sgs.Card_Heart and hurt then
				return "@HaremuCard="..acard:getEffectiveId().."->"..target:objectName()
			end
			if acard:getSuit() == sgs.Card_Club and weak then
				return "@HaremuCard="..acard:getEffectiveId().."->"..target:objectName()
			end
		end
	end
	return "."
end

sgs.ai_skill_choice.haremu = function(self, choices, data)
	local player = data:toPlayer()

	if not self:isEnemy(player) then return "haremu_accept" end
	if self.player:getRole() == "lord" then return "haremu_accept" end
	return "cancel"
end

--雷德
sgs.ai_skill_invoke.gaokang = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		if self.player:getHandcardNum() == 1 and damage.to:objectName() == self.player:objectName() then return true end
		if self:hasSkills(sgs.masochism_skill, damage.to) and damage.to:getHp() > 1 then return false end
		if self.player:getHandcardNum() == 1 and damage.to:getHp() > 2 then return false end
		return true
	end
end

--优吉欧
sgs.ai_skill_choice.rennai = function(self, choices, data)
	choices = choices:split("+")
	local tp = 1
	for _,choice in ipairs(choices) do
		if choice == "rennai_hp" then
			tp = 0
			break
		end
		if choice == "rennai_gain" then
			tp = 2
			break
		end
	end

	-- analysis
	local hp_table = {}
	local hand_table = {}
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if hp_table[p:getHp()] ~= nil then
			self.room:writeToConsole("old")
			if self:isFriend(p) then
				if p:getMark("@Frozen_Eu") > 0 then
				else
					hp_table[p:getHp()] = hp_table[p:getHp()] - 2
				end
			else
				if p:getMark("@Frozen_Eu") > 0 then
					hp_table[p:getHp()] = hp_table[p:getHp()] + 1
				else
					hp_table[p:getHp()] = hp_table[p:getHp()] + 3
				end
			end
		else
			self.room:writeToConsole("new")
			if self:isFriend(p) then
				if p:getMark("@Frozen_Eu") > 0 then
					hp_table[p:getHp()] = 0
				else
					hp_table[p:getHp()] = - 2
				end
			else
				if p:getMark("@Frozen_Eu") > 0 then
					hp_table[p:getHp()] = 1
				else
					hp_table[p:getHp()] = 3
				end
			end
		end
		if hand_table[p:getHandcardNum()] ~= nil then
			if self:isFriend(p) then
				if p:getMark("@Frozen_Eu") > 0 then
				else
					hand_table[p:getHandcardNum()] = hand_table[p:getHandcardNum()] - 2
				end
			else
				if p:getMark("@Frozen_Eu") > 0 then
					hand_table[p:getHandcardNum()] = hand_table[p:getHandcardNum()] + 1
				else
					hand_table[p:getHandcardNum()] = hand_table[p:getHandcardNum()] + 3
				end
			end
		else
			if self:isFriend(p) then
				if p:getMark("@Frozen_Eu") > 0 then
					hand_table[p:getHandcardNum()] = 0
				else
					hand_table[p:getHandcardNum()] = - 2
				end
			else
				if p:getMark("@Frozen_Eu") > 0 then
					hand_table[p:getHandcardNum()] = 1
				else
					hand_table[p:getHandcardNum()] = 3
				end
			end
		end
	end

	local maxValue = -100000
	local hp_or_hand
	local isHp = false
	for k,v in ipairs(hp_table) do
		self.room:writeToConsole(k)
		self.room:writeToConsole(v)
		if v > maxValue then
			maxValue = v
			hp_or_hand = k
			isHp = true
		end
	end

	for k,v in ipairs(hand_table) do
		if v > maxValue then
			maxValue = v
			hp_or_hand = k
			isHp = false
		end
	end

	self.room:writeToConsole(maxValue)
	self.room:writeToConsole(hp_or_hand)

	if tp == 0 then
		-- rennai_hp  rennai_lose
		if isHp then
			return "rennai_hp"
		else
			return "rennai_lose"
		end
	elseif tp == 1 then
		return hp_or_hand
	else
		return "rennai_gain"
	end
end

sgs.ai_skill_invoke.zhanfang = function(self, data)
	-- 绽放吧！
	local use = data:toCardUse()
	if use.card and self:isEnemy(use.to:first()) then return true end
	return false
end

sgs.ai_skill_choice.zhanfang = function(self, choices, data)
	if self.player:getMark("@Frozen_Eu") > 1 then
		return "cancel"
	else
		return "zhanfang_discard"
	end
end

sgs.ai_skill_invoke.huajian = function(self, data)
	if #self.friends > 1 then return true end
	return false
end

sgs.ai_skill_playerchosen.huajian = function(self, targets)
	local bestChoice
	local bestP = 0
	for _,p in ipairs(self.friends_noself) do
		if p:isAlive() and p:objectName() ~= self.player:objectName() then
			local point = 0
			if p:hasSkill("se_erdao") then point = point + 20 end
			if p:hasSkill("Zhena") then point = point + 10 end
			if p:hasSkill("se_xunyu") then point = point + 30 end
			if p:hasSkill("LuaCangshan") then point = point + 9 end
			if p:hasSkill("LuaSaoshe") then point = point + 30 end
			if p:getHp() > 2 then point = point + 3 end
			if p:getHp() <= 1 then point = point - 10 end
			if point > bestP then
				bestP = point
				bestChoice = p
			end
		end
	end
	if bestChoice then return bestChoice end
	return self.friends[1]
end

-- k1
sgs.ai_skill_choice.guiyin = function(self, choices, data)
	local k1 = self.room:findPlayerBySkillName("guiyin")
	if k1 and self:isFriend(k1) then return "guiyin_give" end
	return "cancel"
end

-- 球棒
sgs.ai_skill_invoke.qiubang = function(self, data)
	local use = data:toCardUse()
	if self.player:getTag("QiubangUsed"):toInt() >= 4 then return true end
	if use.card:isKindOf("Duel") then return true end
	if use.from and self:isEnemy(use.from) then
		if use.card:isKindOf("Slash") and self:getCardsNum("Jink") == 0 then return true end
		if use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch") and (self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then return true end
		if self:getCardsNum("Slash") + self.player:getHp() > 3 then
			return true
		end
		if self:isWeak(use.from) and self:getCardsNum("Slash") > 0 then return true end
	end
	return false
end

-- 诱说
sgs.ai_skill_use["@@youshui"] = function(self, prompt, method)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	local target
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("youshui_target") then
			target = p
			break
		end
	end
	if not target then return "." end
	if self:isFriend(target) then
		for _, card in ipairs(cards) do
			if card:isKindOf("Analeptic") then
				return ("@YoushuiCard[%s:%s]=%d"):format(suit, number, card_id) .. "->" .. target:objectName()
			end
		end
	else
		local needed = {}
		for _,acard in ipairs(cards) do
			if #needed < target:getHandcardNum() / 2 and not acard:isKindOf("Peach") and not acard:isKindOf("Analeptic") then
				table.insert(needed, acard:getEffectiveId())
			end
		end
		if #needed > 0 then
			return "@YoushuiCard="..table.concat(needed,"+") .. "->" .. target:objectName()
		end
	end
end



--由理
sgs.ai_skill_invoke["zuozhan"] = true

sgs.ai_skill_choice["zuozhan1"] = function(self, choices, data)
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		return "1_Zuozhan"
	else
		if p:getHandcardNum() <= p:getHp() then return "4_Zuozhan" else return "2_Zuozhan" end
	end
	return "1_Zuozhan"
end

sgs.ai_skill_choice["zuozhan2"] = function(self, choices, data)
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		if p:getHandcardNum() <= 1 and p:getHp() <= 2 then
			return "3_Zuozhan"
		else
			return "2_Zuozhan"
		end
	else
		if p:getHandcardNum() <= p:getHp() then return "2_Zuozhan" else return "3_Zuozhan" end
	end
	return "2_Zuozhan"
end

sgs.ai_skill_choice["zuozhan3"] = function(self, choices, data)
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		if p:getHandcardNum() <= 1 and p:getHp() <= 2 then
			return "2_Zuozhan"
		else
			return "4_Zuozhan"
		end
	else
		if p:getHandcardNum() <= p:getHp() then return "3_Zuozhan" else return "4_Zuozhan" end
	end
	return "3_Zuozhan"
end

sgs.ai_skill_choice["zuozhan4"] = function(self, choices, data)
	local room = self.room
	local p = room:getCurrent()
	if self:isEnemy(p) then
		if p:getHandcardNum() <= 1 and p:getHp() <= 2 then
			return "4_Zuozhan"
		else
			return "3_Zuozhan"
		end
	else
		return "1_Zuozhan"
	end
	return "4_Zuozhan"
end

sgs.ai_skill_invoke.nishen = function(self, data)
	local dying = data:toDying()
	if not self:isEnemy(dying.who) then return true end
	for _,p in ipairs(self.friends) do
		if self:isWeak(p) then return false end
	end
	return true
end

sgs.ai_skill_choice.nishen = function(self, choices, data)
	choices = choices:split("+")
	local on_join = false
	for _,choice in ipairs(choices) do
		if choice == "nishen_accept" then
			on_join = true
		end
	end
	if on_join then
		local yuri = self.room:findPlayerBySkillName("nishen")
		if not yuri then return "cancel" end
		if self.player:getRole() == "renegade" then return "cancel" end
		if not self:isEnemy(yuri) then return "nishen_accept" end
		return "cancel"
	else
		if self.player:getHandcardNum() < self.player:getHp() * 2 then return "draw" end
		return "recover"
	end
end

--春日
sgs.ai_skill_choice["mengxian"] = function(self, choices, data)
	if self.player:getHandcardNum() > self.player:getHp() + 3 then return "equip" end
	return "trick"
end

sgs.ai_skill_choice.yuanwang = function(self, choices, data)
	local haruhi = self.room:findPlayerBySkillName("yuanwang")
	if not haruhi then return "cancel" end
	if self:isFriend(haruhi) then return "yuanwang_accept" end
	return "cancel"
end

sgs.ai_skill_playerchosen.yuanwang = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then return p end
	end
	return
end


sgs.ai_skill_invoke.hayate_jiejie = function(self, targets)
	local hakaze = self.room:findPlayerBySkillName("hayate_jiejie")
	if not hakaze then return false end
	return not self:isEnemy(hakaze)
end

-- moju




sgs.ai_skill_cardask["@vector-discard"] = function(self, data)
	if self.player:isKongcheng() then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	local toUse = "$" .. cards[1]:getEffectiveId()
	local effect = data:toCardEffect()
	local card = effect.card
	local power = self.player:getHp() * 2 + self.player:getHandcardNum()
	local cardN = self.player:getCards("he"):length()
	local hp = self.player:getHp()
	if card:isKindOf("AOE") then
		if power > 9 or cardN > hp or power < 4 or hp == 1 then
			return toUse
		end
		return "."
	elseif card:isKindOf("Snatch") or card:isKindOf("Dismantlement") or card:isKindOf("Collateral") or card:isKindOf("Duel") then return toUse
	elseif card:isKindOf("ex_nihilo") then
		self.room:setPlayerFlag(self.player,"vecter_friend")
		if power > 10 then return toUse end
		return "."
	elseif card:isKindOf("Slash") then
		if self:isFriend(effect.from) then return "." end
		if #self.enemies == 0 then return "." end
		self.room:setPlayerFlag(self.player,"vecter_slash")
		return toUse
	end
	return "."
end

local function doVector(who, self)
	if not who then return false end
	if who:objectName() == self.player:objectName() then return false end
	if not self:isFriend(who) and who:hasSkill("leiji") and (self:hasSuit("spade", true, who) or who:getHandcardNum() >= 3) and (getKnownCard(who, "Jink", true) >= 1 or self:hasEightDiagramEffect(who)) then
		return false
	end

	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if not self.player:isCardLimited(card, method) then
			if self:isFriend(who) then
				return false
			else
				return true
			end
		end
	end

	local cards = self.player:getCards("e")
	cards=sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if not self.player:isCardLimited(card, method) then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.vector = function(self, targets)
	if self.player:hasFlag("vecter_friend") then
		return self:findPlayerToDraw(false, 2)
	elseif self.player:hasFlag("vecter_slash") then
		for _,ememy in ipairs(self.enemies) do
			if doVector(enemy, self) then return enemy end
		end
		for _,ememy in ipairs(self.enemies) do
			return enemy
		end
	else
		return self:findPlayerToDiscard()
	end
end

-- xuli
sgs.ai_skill_invoke.juhe = function(self, data)
	if self.player:getHandcardNum() <= self.player:getHp() then return true end
	return false
end

sgs.ai_skill_choice.juhe = function(self, choices, data)
	if #choices:split("+") == 1 then return "juhe_skip" end
	local pe = self:findPlayerToDamage(self.player:getMark("@xuli"))
	if pe and self:isEnemy(pe) and (pe:getHp() <= self.player:getMark("@xuli") or self:isWeak()) then return "juhe_lose" end
	return "juhe_skip"
end

sgs.ai_skill_playerchosen.juhe = function(self, targets)
	return self:findPlayerToDamage(self.player:getMark("@xuli"))
end

--永瀬伊織
sgs.ai_need_damaged.qifen = function (self, attacker)
	return self.player:getHp() < self.player:getMaxHp()
end

sgs.qifen_keep_value =
{
    Peach 		= 9,
    Analeptic 	= 8,
}

sgs.ai_skill_invoke.qifen = function(self, data)
	if self.player:getHp() < self.player:getMaxHp() then return true end
	if self.player:getHp() == self.player:getMaxHp() then
		if #self.friends >= #self.enemies then return true end
	end
	return false
end

sgs.ai_skill_invoke.mishi = function(self, data)
	local dying_data = data:toDying()
	local source = dying_data.who
	local mygod= self.room:findPlayerBySkillName("mishi")
	local good
	if (self:isFriend(source) and not self:isFriend(mygod)) or (not self:isFriend(source) and self:isFriend(mygod)) then
		good = true
	end
	if not good then return false end
	local peach_num = 0
	local jink_num = 0
	for _,card in sgs.qlist(mygod:getHandcards()) do
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
			peach_num = peach_num + 1
		end
		if card:isKindOf("Jink") then
			jink_num = jink_num + 1
		end
	end
	if good then
		if mygod:getHp() > 0 and peach_num > 2 then return true end
		if mygod:getHp() > 0 and peach_num > 1 and jink_num > 0 then return true end
		if mygod:getHp() > 1 and peach_num > 1 then return true end
		if mygod:getHp() > 1 and peach_num > 0 and jink_num > 0 then return true end
		if mygod:getHp() > 2 and peach_num > 0 then return true end
		if mygod:getHp() > 2 and jink_num > 0 then return true end
	end
	return false
end

-- zhufu
sgs.ai_skill_use["@@hayate_zhufu"] = function(self)
	if self.player:getHandcardNum() < 6 then return "." end
	local targets = {}
	for _,p in ipairs(self.friends_noself) do
		if p:getHandcardNum() < 5 or #targets < 2 then
			table.insert(targets, p:objectName())
		end
	end
	if #targets > 1 then
		return "@ZhufuCard=.->" ..  table.concat(targets, "+")
	end
end
