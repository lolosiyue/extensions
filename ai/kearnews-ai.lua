--曹操

sgs.ai_skill_invoke.kejianxiong = function(self, data)
	return true
end

sgs.ai_skill_use["@@kejianxiong"] = function(self, prompt)
	local id = self.player:getMark("kejianxiong-PlayClear") - 1
	if id < 0 then return "." end
	local card = sgs.Sanguosha:getEngineCard(id)
	if card:targetFixed() then
		if card:isKindOf("Peach") then
			if self:isWeak() then
				return card:toString()
			end
			if self:isWeak(self.friends_noself) then
				return "."
			end
			return card:toString()
		end
		if card:isKindOf("EquipCard") then
			local equip_index = card:getRealCard():toEquipCard():location()
			if self.player:getEquip(equip_index) == nil then
				return card:toString()
			end
		end
		if card:isKindOf("AOE") then
			if self:getAoeValue(card) > 0 then
				return card:toString()
			end
		end
		if card:isKindOf("Analeptic") then
			return "."
		end
		if card:isKindOf("ExNihilo") then
			return card:toString()
		end
	else
		local dummy_use = self:aiUseCard(card, dummy())
		if dummy_use.card and not dummy_use.to:isEmpty() then
			local targets = {}
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets, p:objectName())
			end
			if #targets > 0 then
				return card:toString() .. "->" .. table.concat(targets, "+")
			end
		end
	end
	return "."
end

sgs.ai_skill_use["@@newhujiaa"] = function(self, prompt)
	local players = self.room:getLieges("wei", self.player)
	if players:length() == 0 then return "." end
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"hp")
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target) and self:isWeak(target)
		then return "#newhujiaaCard:.:->"..target:objectName() end
	end
	local damage = self.player:getTag("newhujiaaDamage"):toDamage()
    for _,target in sgs.list(sgs.reverse(destlist))do
		if self:isFriend(target) and not self:isWeak(target)
		and self:needToLoseHp(target, damage.from, damage.card)
		then return "#newhujiaaCard:.:->"..target:objectName() end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target) and self:isWeak()
		then return "#newhujiaaCard:.:->"..target:objectName() end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target) and damage.damage > 1
		then return "#newhujiaaCard:.:->"..target:objectName() end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target) and self:isWeak()
		then return "#newhujiaaCard:.:->"..target:objectName() end
	end
    for _,target in sgs.list(destlist)do
		if self:isWeak()
		then return "#newhujiaaCard:.:->"..target:objectName() end
	end
	return "."
end

sgs.ai_can_damagehp.newhujiaa = function(self,from,card,to)
	local d = {damage=1}
	d.nature = card and sgs.card_damage_nature[card:getClassName()] or sgs.DamageStruct_Normal
	return sgs.ai_skill_use["@@newhujiaa"](self,d,sgs.Card_MethodDiscard)~="."
end


--赵云
local kexianglong_skill = {}
kexianglong_skill.name = "kexianglong"
table.insert(sgs.ai_skills, kexianglong_skill)
kexianglong_skill.getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	for _, id in sgs.qlist(self.player:getHandPile()) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	self:sortByUseValue(cards, true)

	for _, c in ipairs(cards) do
		if c:isKindOf("Analeptic") then
			return sgs.Card_Parse(("peach:kexianglong[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(),
				c:getEffectiveId()))
		end
	end

	for _, c in ipairs(cards) do
		if c:isKindOf("Peach") then
			return sgs.Analeptic_IsAvailable(self.player) and
				sgs.Card_Parse(("analeptic:kexianglong[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(),
					c:getEffectiveId()))
		end
	end

	for _, c in ipairs(cards) do
		if c:isKindOf("Jink") then
			return sgs.Card_Parse(("slash:kexianglong[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(),
				c:getEffectiveId()))
		end
	end
end

sgs.ai_view_as.kexianglong = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand then
		if card:isKindOf("Jink") then
			return ("slash:kexianglong[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:kexianglong[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Peach") then
			return ("analeptic:kexianglong[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Analeptic") then
			return ("peach:kexianglong[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end
sgs.ai_card_priority.kexianglong = function(self,card)
	if table.contains(card:getSkillNames(), "kexianglong") 
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|kexianglong"

sgs.kexianglong_keep_value = sgs.longdan_keep_value

local keliezhen_skill = {}
keliezhen_skill.name = "keliezhen"
table.insert(sgs.ai_skills, keliezhen_skill)
keliezhen_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("keliezhenCard") then return end
	return sgs.Card_Parse("#keliezhenCard:.:")
end

sgs.ai_skill_use_func["#keliezhenCard"] = function(card, use, self)
	if not self.player:hasUsed("#keliezhenCard") then
		self:sort(self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if enys:isEmpty() then
				enys:append(enemy)
			else
				local yes = 1
				for _, p in sgs.qlist(enys) do
					if (enemy:getHp() + enemy:getHp() + enemy:getHandcardNum()) >= (p:getHp() + p:getHp() + p:getHandcardNum()) then
						yes = 0
					end
				end
				if (yes == 1) then
					enys:removeOne(enys:at(0))
					enys:append(enemy)
				end
			end
		end
		for _, enemy in sgs.qlist(enys) do
			if self:objectiveLevel(enemy) > 0 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.keliezhenCard = 8.5
sgs.ai_use_priority.keliezhenCard = 9.5
sgs.ai_card_intention.keliezhenCard = 80

sgs.ai_skill_playerschosen.keliezhen = function(self, targets, max, min)
	local enemy = sgs.SPlayerList()
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			enemy:append(p)
		end
	end
	return enemy
end

sgs.ai_skill_playerchosen.kelongxiang = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and self:isWeak(p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["kelongxiang"] = -80


kechenniang_skill={}
kechenniang_skill.name="kechenniang"
table.insert(sgs.ai_skills,kechenniang_skill)
kechenniang_skill.getTurnUseCard=function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local card
	self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if acard:isKindOf("Jink") or acard:isKindOf("EquipCard")  then
			card = acard
			break
		end
	end
	if not card then return nil end
	local analeptic = sgs.Card_Parse(("analeptic:kechenniang[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getEffectiveId()))
	assert(analeptic)
	if sgs.Analeptic_IsAvailable(self.player,analeptic)
	then return analeptic end
end

sgs.ai_view_as.kechenniang = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("Jink") or card:isKindOf("EquipCard") then
		return ("analeptic:kechenniang[%s:%s]=%d"):format(suit,number,card_id)
	end
end

function sgs.ai_cardneed.kechenniang(to,card,self)
	return card:isKindOf("Jink") or card:isKindOf("EquipCard") 
end
sgs.ai_ajustdamage_from.kechenniang = function(self, from, to, card, nature)
	return from:getMark("&kechenniang-Clear")
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|kenewpaoxiao"

sgs.ai_use_revises.kenewpaoxiao = sgs.ai_use_revises.paoxiao

sgs.ai_cardneed.kenewpaoxiao = sgs.ai_cardneed.paoxiao
sgs.kenewpaoxiao_keep_value = sgs.paoxiao_keep_value


--孙尚香
sgs.ai_skill_use["@@kerongchang"] = function(self, prompt)
    self:sort(self.enemies,"defense")
	local slash = dummyCard()
	slash:setSkillName("kerongchang")
	local dummy = self:aiUseCard(slash)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return slash:toString().."->"..table.concat(tos,"+")
	end
	return "."
end
sgs.ai_skill_playerchosen["kerongchang"] = function(self, targets)
	if self:findPlayerToDiscard("eh", true, false, targets) ~= {} then
		return self:findPlayerToDiscard("eh", true, false, targets)[1]
	end
	return nil
end

sgs.ai_cardneed.kerongchang = sgs.ai_cardneed.equip
sgs.ai_use_revises.kerongchang = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end
sgs.ai_skill_playerchosen.kexiaoji = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and self:isWeak(p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getHp() < getBestHp(p) then
			return p
		end
	end
	return nil
end
sgs.ai_skill_playerchosen.kexiaojiobtain = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "he", true) and p:getEquips():length() > 0 then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "he", true) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:doDisCard(p, "he", true) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	return targets[1]
end
sgs.ai_playerchosen_intention["kexiaoji"] = -80
sgs.ai_playerchosen_intention.kexiaojiobtain = function(self, from, to)
	if self:doDisCard(to, "he", true) and self:isFriend(to) then
		sgs.updateIntention(from, to, -50)
	else
		sgs.updateIntention(from, to, 50)
	end
end
sgs.ai_skill_choice.kexiaoji = function(self, choices, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) and target:getHp() < getBestHp(target) then return "huixue" end
	return "shouhui"
end

--曹婴

sgs.ai_skill_discard.ketwopaomu = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if ((self:isFriend(damage.from) and self:needToLoseHp(damage.from, self.player, nil)) or (not self:cantbeHurt(damage.from) and self:damageIsEffective(damage.from, sgs.DamageStruct_Fire) and self:canDamage(damage.from,self.player,nil))) and ((self:isFriend(damage.to) and self:needToLoseHp(damage.to, self.player, nil)) or (not self:cantbeHurt(damage.to) and self:damageIsEffective(damage.to, sgs.DamageStruct_Fire) and self:canDamage(damage.to,self.player,nil))) then
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		end
	end
	return to_discard
end


local kequshang_skill = {}
kequshang_skill.name = "kequshang"
table.insert(sgs.ai_skills, kequshang_skill)
kequshang_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kequshangCard") then return end
	return sgs.Card_Parse("#kequshangCard:.:")
end

sgs.ai_skill_use_func["#kequshangCard"] = function(card, use, self)
	if not self.player:hasUsed("#kequshangCard") then
		self:sort(self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if enys:isEmpty() then
				enys:append(enemy)
			else
				local yes = 1
				for _, p in sgs.qlist(enys) do
					if (enemy:getHp() + enemy:getHp() + enemy:getHandcardNum()) >= (p:getHp() + p:getHp() + p:getHandcardNum()) then
						yes = 0
					end
				end
				if (yes == 1) then
					enys:removeOne(enys:at(0))
					enys:append(enemy)
				end
			end
		end
		for _, enemy in sgs.qlist(enys) do
			if self:objectiveLevel(enemy) > 0 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.kequshangCard = 8.5
sgs.ai_use_priority.kequshangCard = 9.5
sgs.ai_card_intention.kequshangCard = 80

sgs.ai_skill_invoke.kenewfengming = function(self, data)
	local target = self.room:findPlayerByObjectName(data:toString():split(":")[2])
	if target and self:isFriend(target) then return false end
	return true
end


--徐庶

sgs.ai_skill_playerchosen.kexiajue = sgs.ai_skill_playerchosen.zero_card_as_slash


local kexiajuetwo_skill = {}
kexiajuetwo_skill.name = "kexiajuetwo"
table.insert(sgs.ai_skills, kexiajuetwo_skill)
kexiajuetwo_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kexiajuetwoCard") then return end
	return sgs.Card_Parse("#kexiajuetwoCard:.:")
end

sgs.ai_skill_use_func["#kexiajuetwoCard"] = function(card, use, self)
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_kedianzhen")
	slash:setFlags("Qinggang")
	slash:deleteLater()
	local dummy_use = self:aiUseCard(slash, dummy())
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			use.card = card
			if use.to then use.to:append(p) end
			return
		end
	end
end

sgs.ai_use_value.kexiajuetwoCard = 8.5
sgs.ai_use_priority.kexiajuetwoCard = 9.5
sgs.ai_card_intention.kexiajuetwoCard = 80

sgs.ai_skill_playerchosen.kedianzhen = function(self, targets)
	targets = sgs.QList2Table(targets)
	return self:findPlayerToDiscard("he", false, false, targets, false)[1]
end

--大乔
sgs.ai_skill_invoke["keliuliqp"] = function(self, data)
	local use = data:toCardUse()
	if use.from and self:doDisCard(use.from, "he") then return true end
	return false
end
local keguose_skill = {}
keguose_skill.name = "keguose"
table.insert(sgs.ai_skills, keguose_skill)
keguose_skill.getTurnUseCard = function(self)
	if ((self.player:getMark("useliulilbss-Clear") > 0) and (self.player:getMark("useliuliqzpdq-Clear") > 0)) then return end
	if (self.player:getMark("useliulilbss-Clear") == 0) then
		local cards = self.player:getCards("he")
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			local c = sgs.Sanguosha:getCard(id)
			cards:prepend(c)
		end
		cards = sgs.QList2Table(cards)

		self:sortByUseValue(cards, true)
		local card = nil
		local has_weapon, has_armor = false, false

		for _, acard in ipairs(cards) do
			if acard:isKindOf("Weapon") and not (acard:getSuit() == sgs.Card_Diamond) then has_weapon = true end
		end

		for _, acard in ipairs(cards) do
			if acard:isKindOf("Armor") and not (acard:getSuit() == sgs.Card_Diamond) then has_armor = true end
		end

		for _, acard in ipairs(cards) do
			if (acard:getSuit() == sgs.Card_Diamond) and ((self:getUseValue(acard) < sgs.ai_use_value.Indulgence)) then
				local shouldUse = true

				if acard:isKindOf("Armor") then
					if not self.player:getArmor() then
						shouldUse = false
					elseif self.player:hasEquip(acard) and not has_armor and self:evaluateArmor() > 0 then
						shouldUse = false
					end
				end

				if acard:isKindOf("Weapon") then
					if not self.player:getWeapon() then
						shouldUse = false
					elseif self.player:hasEquip(acard) and not has_weapon then
						shouldUse = false
					end
				end

				if shouldUse then
					card = acard
					break
				end
			end
		end

		if not card then return nil end
		return sgs.Card_Parse("#keguoseCard:" .. card:getEffectiveId() .. ":")
	end
	if (self.player:getMark("useliuliqzpdq-Clear") == 0) then
		return sgs.Card_Parse("#keguoseCard:.:")
	end
end


sgs.ai_skill_use_func["#keguoseCard"] = function(card, use, self)
	
	if (self.player:getMark("useliulilbss-Clear") == 0) and card then
		local id = card:getEffectiveId()
		local indulgence = sgs.Sanguosha:cloneCard("Indulgence")
		indulgence:addSubcard(id)
		if not self.player:isLocked(indulgence) then
			sgs.ai_use_priority.keguoseCard = sgs.ai_use_priority.Indulgence
			
			local dummy_use = self:aiUseCard(indulgence, dummy())
			if dummy_use.card and dummy_use.to:length() > 0 then
				use.card = card
				if use.to then use.to:append(dummy_use.to:first()) end
				return
			end
		end
	elseif (self.player:getMark("useliuliqzpdq-Clear") == 0) then
		for _, friend in ipairs(self.friends_noself) do
			if self:isFriend(friend) then
				if (friend:getJudgingArea():length() > 0) then
					use.card = card
					if use.to then use.to:append(friend) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority.keguoseCard = 5.5
sgs.ai_use_value.keguoseCard = 5
sgs.ai_card_intention.keguoseCard = -60

function sgs.ai_cardneed.keguose(to, card)
	return card:getSuit() == sgs.Card_Diamond
end

sgs.keguose_suit_value = {
	diamond = 3.9
}


sgs.ai_skill_playerschosen.kekaojun = function(self, targets, max, min)
	local friend = sgs.SPlayerList()
	for _, p in sgs.qlist(targets) do
		if self:isFriend(p) and self:canDraw(p, self.player) and friend:length() < max then
			friend:append(p)
		end
	end
	return friend
end



--刘谌

sgs.ai_skill_choice.kenewwenxiang = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then return items[1] end
	return items[math.random(1, #items)]
end

local kenewwenxiang_skill = {}
kenewwenxiang_skill.name = "kenewwenxiang"
table.insert(sgs.ai_skills, kenewwenxiang_skill)
kenewwenxiang_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kenewwenxiangCard") then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = sgs.IntList()
	for _, acard in ipairs(cards) do
		if acard:isRed() then
			to_throw:append(acard:getEffectiveId())
		end
	end
	card_id = to_throw:at(0)
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("#kenewwenxiangCard:" .. card_id .. ":")
	end
end


sgs.ai_skill_use_func["#kenewwenxiangCard"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 0 and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and enemy:getMark("usedkenewwenxiang-PlayClear") == 0 then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_value.kenewwenxiangCard = 8.5
sgs.ai_use_priority.kenewwenxiangCard = 9.5
sgs.ai_card_intention.kenewwenxiangCard = 80

function sgs.ai_cardneed.kenewwenxiang(to, card)
	return card:isRed()
end




--曹睿

sgs.ai_skill_playerchosen.kehuituo = sgs.ai_skill_playerchosen.huituo
sgs.ai_playerchosen_intention.kehuituo = sgs.ai_playerchosen_intention.huituo

sgs.ai_skill_use["@@kemingjianusevs"] = function(self, prompt)
	local id = self.player:getMark("kemingjianusevs-PlayClear") - 1
	if id < 0 then return "." end
	local card = sgs.Sanguosha:getEngineCard(id)
	if card:targetFixed() then
		if card:isKindOf("Peach") then
			if self:isWeak() then
				return card:toString()
			end
			if self:isWeak(self.friends_noself) then
				return "."
			end
			return card:toString()
		end
		if card:isKindOf("EquipCard") then
			local equip_index = card:getRealCard():toEquipCard():location()
			if self.player:getEquip(equip_index) == nil then
				return card:toString()
			end
		end
		if card:isKindOf("AOE") then
			if self:getAoeValue(card) > 0 then
				return card:toString()
			end
		end
		if card:isKindOf("Analeptic") then
			return "."
		end
		if card:isKindOf("ExNihilo") then
			return card:toString()
		end
	else
		local dummy_use = self:aiUseCard(card, dummy())
		if dummy_use.card and not dummy_use.to:isEmpty() then
			local targets = {}
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets, p:objectName())
			end
			if #targets > 0 then
				return card:toString() .. "->" .. table.concat(targets, "+")
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.kexingshuai = function(self, data)
	return true
end

sgs.ai_skill_choice.xingshuai_choice = function(self, choices, data)
	if self.player:hasFlag("helpcaorui") then
		return "huifu"
	else
		return "no"
	end
end

local kemingjian_skill = {}
kemingjian_skill.name = "kemingjian"
table.insert(sgs.ai_skills,kemingjian_skill)
kemingjian_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#kemingjianCard:.:")
end

sgs.ai_skill_use_func["#kemingjianCard"] = function(card,use,self)
	local give_all_cards = {}
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if c:isAvailable(self.player) and ((self.player:getMark("mingjianjbp-Clear") == 0 and c:isKindOf("BasicCard"))
		or (self.player:getMark("mingjianzbp-Clear") == 0 and c:isKindOf("EquipCard"))
		or (self.player:getMark("mingjianjnp-Clear") == 0 and c:isKindOf("TrickCard"))) then
			table.insert(give_all_cards, c:getEffectiveId())
			break
		end
	end
	if #give_all_cards == 0 then return end
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and sgs.Sanguosha:getCard(give_all_cards[1]):isAvailable(friend) then
			table.insert(targets, friend)
		end
	end
	if #targets > 0 and #give_all_cards > 0 then
		local card_str = string.format("#kemingjianCard:" .. give_all_cards[1] .. ":")
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then
			use.to:append(targets[1])
		end
		return
	end
end

sgs.ai_use_value.kemingjianCard = 8.5
sgs.ai_use_priority.kemingjianCard = 8.8

sgs.ai_card_intention.kemingjianCard = function(self,card,from,tos)
	local to = tos[1]
	local intention = -70
	if hasManjuanEffect(to) then
		intention = 0
	elseif to:hasSkill("kongcheng") and to:isKongcheng() then
		intention = 30
	end
	sgs.updateIntention(from,to,intention)
end


--王基
sgs.ai_skill_playerchosen.kenewqizhi = function(self, targets)
	self:updatePlayers()
	local targets = sgs.QList2Table(targets)
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and hasManjuanEffect(target) and not target:isNude() then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and not hasManjuanEffect(target) and self:needToThrowCard(target, "he", false, false, true) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isEnemy(target) and (self:getDangerousCard(target) or self:keepWoodenOx(target)) then return target end
		if self:isEnemy(target) and self:getValuableCard(target) and self:doDisCard(target, "e")
			and not target:hasSkills(sgs.notActive_cardneed_skill) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if target:objectName() == self.player:objectName() then
			local cards = sgs.QList2Table(self.player:getCards("he"))
			for _, c in ipairs(cards) do
				if not self:keepCard(c, self.player) then return target end
			end
		end
	end
	return nil
end

sgs.ai_skill_invoke.kenewqizhi = function(self, data)
	local target = self.room:findPlayerByObjectName(data:toString():split(":")[2])
	if target then
		if self:isFriend(target) then
			return true
		end
	end
	return false
end

local keyanzhu_skill = {}
keyanzhu_skill.name = "keyanzhu"
table.insert(sgs.ai_skills, keyanzhu_skill)
keyanzhu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("keyanzhuCard") then return end
	return sgs.Card_Parse("#keyanzhuCard:.:")
end

sgs.ai_skill_use_func["#keyanzhuCard"] = function(card, use, self)
	if not self.player:hasUsed("#keyanzhuCard") then
		self:sort(self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		local x = math.max(self.player:getLostHp(), 1)
		for _, enemy in ipairs(self.enemies) do
			if self:doDisCard(enemy, "he", true) or (self.player:getMark("changekexingxue") == 0 and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil)) then
				enys:append(enemy)
				if enys:length() >= x then
					break
				end
			end
		end

		if (enys:length() > 0) then
			for _, p in sgs.qlist(enys) do
				use.card = card
				if use.to then
					use.to:append(p)
				end
			end
		end
		return
	end
end

sgs.ai_use_value.keyanzhuCard = 8.5
sgs.ai_use_priority.keyanzhuCard = 9.5
sgs.ai_card_intention.keyanzhuCard = 80

sgs.ai_skill_cardchosen.keyanzhutishi = function(self,who,flags)
	if (self:isEnemy(who) and self:damageIsEffective(who, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(who) and self:canDamage(who,self.player,nil) and self.player:getMark("changekexingxue") == 0) or (self:isFriend(who) and self:needToLoseHp(who, self.player)) then
		return -1
	end 

	return sgs.ai_skill_cardchosen.fankui(self,who,flags)
end

local kezhaofu_skill = {}
kezhaofu_skill.name = "kezhaofu"
table.insert(sgs.ai_skills, kezhaofu_skill)
kezhaofu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kezhaofuCard") then return end
	return sgs.Card_Parse("#kezhaofuCard:.:")
end

sgs.ai_skill_use_func["#kezhaofuCard"] = function(card, use, self)
	if (self.player:getMark("@kezhaofu") > 0) and (self:getCardsNum("Slash") > 0) and not self.player:hasUsed("#kezhaofuCard") then
		self:sort(self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		for _, enemy in ipairs(self.enemies) do
			if self:getDefenseSlash(enemy) <= 2
			and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
			end
		end
	end
end

sgs.ai_skill_playerschosen.kexingxue = function(self, targets, max, min)
	local friend = sgs.SPlayerList()
	for _, p in sgs.qlist(targets) do
		if self:isFriend(p) and self:canDraw(p, self.player) then
			friend:append(p)
			if friend:length() >= max then
                break
            end
		end
	end
	return friend
end


--钟会

sgs.ai_skill_invoke.kezhenggong = function(self, data)
	return true
end

local kesuni_skill = {}
kesuni_skill.name = "kesuni"
table.insert(sgs.ai_skills, kesuni_skill)
kesuni_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kesuniCard") then return end
	return sgs.Card_Parse("#kesuniCard:.:")
end

sgs.ai_skill_use_func["#kesuniCard"] = function(card, use, self)
	if (self.player:getMark("&kegong") > 0) and not self.player:hasUsed("#kesuniCard") then
		self:sort(self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if enys:isEmpty() then
				enys:append(enemy)
			else
				local yes = 1
				for _, p in sgs.qlist(enys) do
					if (enemy:getHp() + enemy:getHp() + enemy:getHandcardNum()) >= (p:getHp() + p:getHp() + p:getHandcardNum()) then
						yes = 0
					end
				end
				if (yes == 1) then
					enys:removeOne(enys:at(0))
					enys:append(enemy)
				end
			end
		end
		for _, enemy in sgs.qlist(enys) do
			if self:objectiveLevel(enemy) > 0 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.kesuniCard = 8.5
sgs.ai_use_priority.kesuniCard = 9.5
sgs.ai_card_intention.kesuniCard = 80


--曹冲
local kenewchengxiang_skill = {}
kenewchengxiang_skill.name = "kenewchengxiang"
table.insert(sgs.ai_skills, kenewchengxiang_skill)
kenewchengxiang_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kenewchengxiangCard") then return end
	return sgs.Card_Parse("#kenewchengxiangCard:.:")
end

sgs.ai_skill_use_func["#kenewchengxiangCard"] = function(card, use, self)
	if not self.player:hasUsed("#kenewchengxiangCard") then
		local room = self.room
		local all = room:getOtherPlayers(self.player)
		local enys = sgs.SPlayerList()
		for _, p in sgs.qlist(all) do
			if self:isEnemy(p) then
				if (not p:isKongcheng()) and ((p:getHp() >= self.player:getHp()) or (p:getHandcardNum() >= self.player:getHandcardNum())) then
					enys:append(p)
				end
			end
		end
		if (enys:length() > 0) then
			for _, p in sgs.qlist(enys) do
				use.card = card
				if use.to then
					use.to:append(p)
				end
			end
		end
		return
	end
end

sgs.ai_use_value.kenewchengxiangCard = 8.5
sgs.ai_use_priority.kenewchengxiangCard = 9.5
sgs.ai_card_intention.kenewchengxiangCard = 80

sgs.ai_skill_invoke.keceyin = function(self, data)
	local damage = self.room:getTag("keceyin"):toDamage()
	if damage.to and self:isFriend(damage.to) then
		if not self:needToLoseHp(damage.to, damage.from, damage.card) then
			return true
		end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.keceyin = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end


sgs.ai_skill_discard.keceyin = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	table.insert(to_discard, cards[1]:getEffectiveId())
	return to_discard
end

--孙鲁育

sgs.ai_skill_invoke.keraoxi = function(self, data)
	local target = data:toPlayer()
	if self:isEnemy(target) and self:getOverflow(target) > 0 then
		return true
	end
	return false
end

sgs.ai_skill_discard.keceyin = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if (self.player:getCardCount() > 1) and (self.player:getMark("useraoxi_lun") < 2)  then
		table.insert(to_discard, cards[1]:getEffectiveId())
		return to_discard
	end
	return to_discard
end


sgs.ai_skill_choice.keraoxi = function(self, choices, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) and target:getHandcardNum() <= 1 then
		return "skipmp"
	else
		return "skipcp"
	end
end
sgs.ai_choicemade_filter.skillChoice["keraoxi"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = self.room:getCurrent()
	if choice == "skipmp" and self:getOverflow(current) > 0 then
		sgs.updateIntention(player, current, 60)
	end
end


local kemumu_skill = {}
kemumu_skill.name = "kemumu"
table.insert(sgs.ai_skills, kemumu_skill)
kemumu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kemumuCard") then return end
	return sgs.Card_Parse("#kemumuCard:.:")
end

sgs.ai_skill_use_func["#kemumuCard"] = function(card, use, self)
	
	self:sort(self.friends, "defense")
	self.friends = sgs.reverse(self.friends)
	for _, fri in ipairs(self.friends) do
		if self:doDisCard(fri, "hej") then
			use.card = card
			if use.to then use.to:append(fri) end
			return
		end
	end
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 0 and self:doDisCard(enemy, "hej") then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end


sgs.ai_use_value.kemumuCard = 8.5
sgs.ai_use_priority.kemumuCard = 9.5
sgs.ai_choicemade_filter.cardChosen.kemumu = sgs.ai_choicemade_filter.cardChosen.snatch


--张星彩
local keqiangwu_skill = {}
keqiangwu_skill.name = "keqiangwu"
table.insert(sgs.ai_skills, keqiangwu_skill)
keqiangwu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("keqiangwuCard") then return end
	return sgs.Card_Parse("#keqiangwuCard:.:")
end

sgs.ai_skill_use_func["#keqiangwuCard"] = function(card, use, self)
	if not self.player:hasUsed("#keqiangwuCard") then
		use.card = card
		return
	end
end

sgs.ai_use_value.keqiangwuCard = 8.5
sgs.ai_use_priority.keqiangwuCard = 9.5
sgs.ai_card_intention.keqiangwuCard = 80

sgs.ai_skill_invoke.kexianjie = function(self, data)
	local target = self.room:findPlayerByObjectName(data:toString():split(":")[2])
	if target and self:isFriend(target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.kexianjie = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|kexianjie"
sgs.ai_cardneed.kexianjie = sgs.ai_cardneed.slash

sgs.ai_skill_playerchosen.keqiangwu = function(self, targets)
	targets = sgs.QList2Table(targets)
	if self.player:hasFlag("keqiangwu_throw") then
		for _, p in ipairs(targets) do
			if self:isEnemy(p) and self:doDisCard(p, "he") then
				return p
			end
		end
	else
		for _, p in ipairs(targets) do
			if self:isEnemy(p) and self:objectiveLevel(p)>3 and not self:cantbeHurt(p) and self:damageIsEffective(p) then
				return p
			end
		end
	end
		
	return nil
end
sgs.ai_playerchosen_intention.keqiangwu = 70
sgs.ai_card_priority.keqiangwu = function(self,card,v)
	if self.player:getMark("keqiangwu-PlayClear") > 0 then
		local qiangwu = sgs.Sanguosha:getCard(self.player:getMark("keqiangwu-PlayClear"))
		if qiangwu and (qiangwu:getSuit() ==card:getSuit()
		or qiangwu:getNumber()==card:getNumber())
		then return 10 end
	end
end


--曹仁
sgs.ai_view_as.keyanzheng = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand then
		if card:isBlack() or card:isRed() then
			return ("nullification:keyanzheng[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.ai_cardneed.keyanzheng = function(to, card, self)
	return card:isBlack() or card:isRed()
end

local keyugong_skill = {}
keyugong_skill.name = "keyugong"
table.insert(sgs.ai_skills, keyugong_skill)
keyugong_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#keyugongCard") then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if (self.player:getChangeSkillState("keyugong") == 2) then
		local yes = 0
		local to_throw = sgs.IntList()
		for _, acard in ipairs(cards) do
			if acard:isDamageCard() then
				to_throw:append(acard:getEffectiveId())
			end
		end
		card_id = to_throw:at(0)
		if not card_id then
			return nil
		else
			return sgs.Card_Parse("#keyugongCard:" .. card_id .. ":")
		end
	elseif (self.player:getChangeSkillState("keyugong") == 1) then
		local to_throw = sgs.IntList()
		for _, acard in ipairs(cards) do
			if not acard:isDamageCard() then
				to_throw:append(acard:getEffectiveId())
			end
		end
		card_id = to_throw:at(0) --(to_throw:length()-1)
		if not card_id then
			return nil
		else
			return sgs.Card_Parse("#keyugongCard:" .. card_id .. ":")
		end
	end
end

sgs.ai_skill_use_func["#keyugongCard"] = function(card, use, self)
	if not self.player:hasUsed("#keyugongCard") then
		use.card = card
		return
	end
end

function sgs.ai_cardneed.keyugongCard(to, card, self)
	if self.player:hasUsed("#keyugongCard") then return false end
	return true
end

sgs.ai_use_value.keyugongCard = 8.5
sgs.ai_use_priority.keyugongCard = 9.5
sgs.ai_card_intention.keyugongCard = 80

--邓艾
sgs.ai_use_revises.kepihuang = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5 and self.player:getMark("&keppihuangbozhong") > 0 and self.player:hasSkill("kezhuxian")
	then use.card = card return true end
end
sgs.ai_skill_choice.kepihuang = function(self, choices, data)
	if (self.player:getMark("&ketian") <= 2) or (not self.player:hasSkill("kezhuxian")) then
		return "bozhong"
	else
		return "fengshou"
	end
end

sgs.ai_skill_choice.kezaoxian = function(self, choices, data)
	if (self:isWeak() and self.player:isWounded()) then
		return "recover"
	else
		return "draw"
	end
end

sgs.ai_skill_playerchosen.kezhuxian = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "he", true) then
			return p
		end
	end
	return nil
end

--姜维

local ketiaoxin_skill = {}
ketiaoxin_skill.name = "ketiaoxin"
table.insert(sgs.ai_skills, ketiaoxin_skill)
ketiaoxin_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("ketiaoxinCard") then return end
	return sgs.Card_Parse("#ketiaoxinCard:.:")
end

sgs.ai_skill_use_func["#ketiaoxinCard"] = function(card, use, self)
	if not self.player:hasUsed("#ketiaoxinCard") then
		self:sort(self.enemies)
		self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isNude() then
				if enys:isEmpty() then
					enys:append(enemy)
				else
					local yes = 1
					for _, p in sgs.qlist(enys) do
						if (enemy:getHp() + enemy:getHp() + enemy:getHandcardNum()) >= (p:getHp() + p:getHp() + p:getHandcardNum()) then
							yes = 0
						end
					end
					if (yes == 1) then
						enys:removeOne(enys:at(0))
						enys:append(enemy)
					end
				end
			end
		end
		for _, enemy in sgs.qlist(enys) do
			if self:objectiveLevel(enemy) > 0 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_value.ketiaoxinCard = 8.5
sgs.ai_use_priority.ketiaoxinCard = 9.5
sgs.ai_card_intention.ketiaoxinCard = 80

sgs.ai_skill_choice.kezhiji = function(self, choices, data)
	if (self:isWeak() and self.player:isWounded()) then
		return "recover"
	else
		return "draw"
	end
end

sgs.ai_skill_choice.kejwkuitian = function(self, choices, data)
	return "fromass"
end
sgs.ai_skill_playerchosen["kejwkuitian"] = function(self, targets)
	self:sort(self.enemies, "handcard", true)
	for _, p in ipairs(self.enemies) do
		if not p:isKongcheng() then return p end
	end
	return nil
end

sgs.ai_playerchosen_intention["kejwkuitian"] = 50

local function chsize(tmp)
	if not tmp then
		return 0
    elseif tmp > 240 then
        return 4
    elseif tmp > 225 then
        return 3
    elseif tmp > 192 then
        return 2
    else
        return 1
    end
end
local function utf8len(str)
	local length = 0
	local currentIndex = 1
	while currentIndex <= #str do
		local tmp = string.byte(str, currentIndex)
		currentIndex  = currentIndex + chsize(tmp)
		length = length + 1
	end
	return length
end
sgs.ai_card_priority.kemingding = function(self,card,v)
	if (self.player:getMark("&kemingding-Clear") + 1 == utf8len(sgs.Sanguosha:translate(card:objectName()))) then return 10 end
end

sgs.ai_skill_invoke.kenewgonghuan = function(self, data)
	local use = data:toCardUse()
	local target = use.to:first()
	if target and self:isFriend(target) then
		if not self:isFriend(use.from) then
			return not self:isWeak()
		end
	end
	return false
end


sgs.ai_skill_choice.kenewgonghuan = function(self, choices, data)
	local target = data:toPlayer()
	if getBestHp(target) > target:getHp() then
		return "recover"
	else
		return "mopai"
	end
end

local kenewsangzhi_skill = {}
kenewsangzhi_skill.name = "kenewsangzhi"
table.insert(sgs.ai_skills, kenewsangzhi_skill)
kenewsangzhi_skill.getTurnUseCard = function(self)
	--if self.player:hasUsed("kenewsangzhiCard") then return end
	return sgs.Card_Parse("#kenewsangzhiCard:.:")
end

sgs.ai_skill_use_func["#kenewsangzhiCard"] = function(card, use, self)
	--if not self.player:hasUsed("#kenewsangzhiCard") then
	local room = self.player:getRoom()
	local hpones = sgs.SPlayerList()
	local spones = sgs.SPlayerList()
	local ones = room:getOtherPlayers(self.player)
	for _, one in sgs.qlist(ones) do
		if (math.min(one:getHp(), self.player:getMaxHp()) > self.player:getHp()) and (one:getMark("beselectsangzhi") == 0) then
			if hpones:isEmpty() then
				hpones:append(one)
			else
				local yes = 1
				for _, p in sgs.qlist(hpones) do
					if (math.min(p:getHp(), self.player:getMaxHp()) >= math.min(one:getHp(), self.player:getMaxHp())) then
						yes = 0
						break
					end
				end
				if (yes == 1) then
					hpones:removeOne(hpones:at(0))
					hpones:append(one)
				end
			end
		end
		if (one:getHandcardNum() > self.player:getHandcardNum()) and (one:getMark("beselectsangzhi") == 0) then
			if spones:isEmpty() then
				spones:append(one)
			else
				local yes = 1
				for _, p in sgs.qlist(spones) do
					if (p:getHandcardNum() >= one:getHandcardNum()) then
						yes = 0
						break
					end
				end
				if (yes == 1) then
					spones:removeOne(spones:at(0))
					spones:append(one)
				end
			end
		end
	end
	if not hpones:isEmpty() then
		use.card = card
		if use.to then use.to:append(hpones:at(0)) end
		return
	end
	if not spones:isEmpty() then
		use.card = card
		if use.to then use.to:append(spones:at(0)) end
		return
	end
	--end
end

sgs.ai_use_value.kenewsangzhiCard = 8.5
sgs.ai_use_priority.kenewsangzhiCard = 9.5
sgs.ai_card_intention.kenewsangzhiCard = 80

local kenewzahuo_skill = {}
kenewzahuo_skill.name = "kenewzahuo"
table.insert(sgs.ai_skills, kenewzahuo_skill)
kenewzahuo_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kenewzahuoCard") or (self.player:getMark("@kecaoxie") < 3) then return end
	return sgs.Card_Parse("#kenewzahuoCard:.:")
end

sgs.ai_skill_use_func["#kenewzahuoCard"] = function(card, use, self)
	if (self.player:getMark("@kecaoxie") >= 3) and not self.player:hasUsed("#kenewzahuoCard") then
		use.card = card
		return
	end
end

sgs.ai_use_value.kenewzahuoCard = 8.5
sgs.ai_use_priority.kenewzahuoCard = 9.5
sgs.ai_card_intention.kenewzahuoCard = 80


sgs.ai_skill_choice.goodsclass = function(self, choices, data)
	local room = self.player:getRoom()
	local yes = 0
	for _, p in sgs.qlist(room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and self.player:inMyAttackRange(p)
			and (self:getCardsNum("Slash") > 0) then
			yes = 1
		end
	end
	if (self:isWeak() and self.player:isWounded() and (self.player:getMark("@kecaoxie") >= 5))
		or ((self.player:getMark("@kecaoxie") >= 3) and (sgs.Slash_IsAvailable(self.player)) and (self:getCardsNum("Slash") == 0)) then
		return "basiccard"
	elseif (yes == 0) and (self.player:getMark("@kecaoxie") >= 4) then
		return "equip"
	elseif (self.player:getMark("@kecaoxie") >= 4) and (not sgs.Slash_IsAvailable(self.player)) and (self:getCardsNum("Slash") > 0)
		or (self.player:getMark("@kecaoxie") >= 3) and (self.player:getHandcardNum() > self.player:getMaxCards() + 2) then
		return "effect"
	end
end

sgs.ai_skill_choice.liubeijibenpai = function(self, choices, data)
	local room = self.player:getRoom()
	if self:isWeak() and self.player:isWounded() and (self.player:getMark("@kecaoxie") >= 5) then
		return "peach"
	elseif (self.player:getMark("@kecaoxie") >= 3) and (sgs.Slash_IsAvailable(self.player)) and (self:getCardsNum("Slash") == 0) then
		return "slash"
	end
end

sgs.ai_skill_choice.liubeizhuangbei = function(self, choices, data)
	return "weapon"
end

sgs.ai_skill_choice.liubeitexiao = function(self, choices, data)
	local room = self.player:getRoom()
	if (self.player:getMark("@kecaoxie") >= 4) and (not sgs.Slash_IsAvailable(self.player)) and (self:getCardsNum("Slash") > 0) then
		return "addslash"
	elseif (self.player:getMark("@kecaoxie") >= 3) and (self.player:getHandcardNum() > self.player:getMaxCards() + 2) then
		return "maxhand"
	end
end

--孙权

sgs.ai_skill_choice.kezhiheng = function(self, choices, data)
	if (self:getEnemyNumBySeat(self.room:getCurrent(),self.player,self.player,true) == 0) or (self:getEnemyNumBySeat(self.room:getCurrent(),self.player,self.player,true)>self.room:getAlivePlayers():length()/2) then
		return "xiaomo"
	end
	return "damo"
end

--卧龙诸葛亮

sgs.ai_skill_discard.kenewhuoji = function(self, discard_num, min_num, optional, include_equip, pattern)
	local to_discard = {}
	for _, c in sgs.qlist(self.player:getCards("h")) do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,c)
			then
			table.insert(to_discard, c:getEffectiveId())
			return to_discard
		end
	end
	return to_discard
end


local kenewhuoji_skill = {}
kenewhuoji_skill.name = "kenewhuoji"
table.insert(sgs.ai_skills, kenewhuoji_skill)
kenewhuoji_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	local card

	self:sortByUseValue(cards, true)

	for _, acard in ipairs(cards) do
		if acard:isRed() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard) < sgs.ai_use_value.FireAttack or self:getOverflow() > 0) then
			if acard:isKindOf("Slash") and self:getCardsNum("Slash") == 1 then
				local keep
				local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
				self:useBasicCard(acard, dummy_use)
				if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
					for _, p in sgs.qlist(dummy_use.to) do
						if p:getHp() <= 1 then
							keep = true
							break
						end
					end
					if dummy_use.to:length() > 1 then keep = true end
				end
				if keep then
					sgs.ai_use_priority.Slash = sgs.ai_use_priority.FireAttack + 0.1
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
	local card_str = ("fire_attack:kenewhuoji[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end

sgs.ai_cardneed.kenewhuoji = function(to, card, self)
	return to:getHandcardNum() >= 2 and card:isRed()
end

sgs.ai_view_as.kenewkanpo = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isBlack() then
		return ("nullification:kenewkanpo[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_cardneed.kenewkanpo = function(to, card, self)
	return card:isBlack()
end
sgs.ai_skill_playerschosen.kenewkanpo = function(self, targets, max, min)
	local friend = sgs.SPlayerList()
	for _, p in sgs.qlist(targets) do
		if self:isFriend(p) then
			friend:append(p)
		end
	end
	return friend
end


sgs.ai_skill_invoke.kenewbazhen = sgs.ai_skill_invoke.eight_diagram

sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|kewulie"
sgs.ai_ajustdamage_from.kewulie = function(self,from,to,slash,nature)
	if from:getMark("&kewulie") > 0 and to:isKongcheng() and from:objectName() ~= to:objectName()
	then return 1 end
end

sgs.ai_skill_playerschosen.kewulie = function(self, targets, max, min)
	targets = sgs.QList2Table(targets)
	local tos = {}
	self:sort(targets)
	for _, p in ipairs(targets) do
		if self:doDisCard(p,"hej") and #tos < max then
			table.insert(tos, p)
		end
	end
	return tos
end

sgs.ai_getBestHp_skill.kewulie = function(owner)
	return owner:getMaxHp() - 2
end

local kexihuo_skill = {}
kexihuo_skill.name = "kexihuo"
table.insert(sgs.ai_skills, kexihuo_skill)
kexihuo_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kexihuoCard") or (self.player:getMark("@kexihuo") < 1) then return end
	if not getYongdiTarget(self,self.room:getOtherPlayers(self.player)) then return end
	return sgs.Card_Parse("#kexihuoCard:.:")
end

sgs.ai_skill_use_func["#kexihuoCard"] = function(card, use, self)
	local target = getYongdiTarget(self,self.room:getOtherPlayers(self.player))
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end








--十常侍

--赵忠
sgs.ai_skill_invoke.kenewshiren = function(self, data)
	local current = self.room:getCurrent()
	if current and self:isEnemy(current) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.kenewshiren = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local current = self.room:getCurrent()
		if current then sgs.updateIntention(player,current,50) end
	end
end

--孙璋
local kenewqieshui_skill = {}
kenewqieshui_skill.name = "kenewqieshui"
table.insert(sgs.ai_skills, kenewqieshui_skill)
kenewqieshui_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kenewqieshuiCard") then return end
	return sgs.Card_Parse("#kenewqieshuiCard:.:")
end

sgs.ai_skill_use_func["#kenewqieshuiCard"] = function(card, use, self)
	if not self.player:hasUsed("#kenewqieshuiCard") then
		local room = self.room
		local all = room:getOtherPlayers(self.player)
		local enys = sgs.SPlayerList()
		for _, p in sgs.qlist(all) do
			if self:isEnemy(p) then
				enys:append(p)
			end
		end
		if (enys:length() > 0) then
			for _, p in sgs.qlist(enys) do
				use.card = card
				if use.to and (use.to:length() < self.player:getMark("sunzhanglunci")) then
					use.to:append(p)
				end
			end
		end
		return
	end
end

sgs.ai_use_value.kenewqieshuiCard = 8.5
sgs.ai_use_priority.kenewqieshuiCard = 9.5
sgs.ai_card_intention.kenewqieshuiCard = 80

sgs.ai_skill_askforyiji.kenewqieshui = function(self, card_ids)
	return sgs.ai_skill_askforyiji.nosyiji(self, card_ids)
end


sgs.ai_skill_choice.kenewrongyuan = function(self, choices, data)
	local num = math.random(0, 1)
	if num == 0 then
		return "dis"
	else
		return "mopai"
	end
end

sgs.ai_skill_playerschosen.kenewrongyuan = function(self, targets, max, min)
	if self.player:hasFlag("kenewrongyuan_draw") then
		local friend = sgs.SPlayerList()
		for _, p in sgs.qlist(targets) do
			if self:isFriend(p) and self:canDraw(p, self.player) and friend:length() < max then
				friend:append(p)
			end
		end
		return friend
	end
	local enemy = sgs.SPlayerList()
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "he") and enemy:length() < max then
			enemy:append(p)
		end
	end
	return enemy
end


--夏恽
sgs.ai_skill_invoke.kenewbiting = function(self, data)
	local current = self.room:getCurrent()
	if current and self:isEnemy(current) and current:isLord() then
		return true
	end
	if current and self:isEnemy(current) then
        for _,sk in ipairs(sgs.getPlayerSkillList(current))do
			local dp = sk:getDescription()
			if string.find(dp,"摸牌阶段") and string.find(dp,"额外") then
				local t = sgs.Sanguosha:getTriggerSkill(sk:objectName())
				if t and t:hasEvent(sgs.DrawNCards)
				then return true end
			end
		end
    end
	if current and self:isFriend(current) then
		for _,sk in ipairs(sgs.getPlayerSkillList(current))do
			local dp = sk:getDescription()
			if string.find(dp,"摸牌阶段") and string.find(dp,"额外") then
				local t = sgs.Sanguosha:getTriggerSkill(sk:objectName())
				if t and t:hasEvent(sgs.DrawNCards)
				then return false end
			end
		end
		return #self.enemies>0
	end
    return false
end

sgs.ai_skill_discard.kenewbiting = function(self)
	local to_discard = {}
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		for _, c in sgs.qlist(self.player:getCards("he")) do
			table.insert(to_discard, c:getEffectiveId())
		end
	else
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		table.insert(to_discard, cards[1]:getEffectiveId())
	end
	return to_discard
end

--栗嵩
sgs.ai_skill_invoke.kenewmieyao = function(self, data)
	local target = self.room:findPlayerByObjectName(data:toString():split(":")[2])
	if target then
		if self:isEnemy(target) then
			local use = self.room:getTag("kenewmieyao"):toCardUse()
			for _, p in sgs.qlist(use.to) do
				if self:isFriend(p) then
					return false
				end
			end
			return true
		end
	end
	return false
end

sgs.ai_ajustdamage_from.kenewjueling = function(self,from,to,card,nature)
	if (to:isKongcheng() or (to:getEquips():length() == 0) or (to:getJudgingArea():length() > 0))
		and (from:getMark("juelingadd-Clear") == 0)
	then return 1 end
end


--郭胜
sgs.ai_skill_playerchosen.kenewyuanli = function(self, targets)
	targets = sgs.QList2Table(targets)
	local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
	slash:setSkillName(self:objectName())
	slash:deleteLater()
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			if self.player:canSlash(p, slash, false) and not self:slashProhibit(slash, p) and self:getDefenseSlash(p) <= 6
				and self:slashIsEffective(slash, p) and self:isGoodTarget(p, self.enemies, slash)
				and p:objectName() ~= self.player:objectName() then
				return p
			end
		end
	end
	return nil
end

--高望

sgs.ai_skill_invoke.kenewsiji = function(self, data)
	local target = self.room:findPlayerByObjectName(data:toString():split(":")[2])
	if target then
		if self:isEnemy(target) then
			if not self.player:hasFlag("kenewsiji_damage") then
				return true
			end
		elseif self:isFriend(target) and not self:needToLoseHp(target) then
			if self.player:hasFlag("kenewsiji_damage") then
				return true
			end
		end
	end
	return false
end

--张让

local kenewwangmiu_skill = {}
kenewwangmiu_skill.name = "kenewwangmiu"
table.insert(sgs.ai_skills, kenewwangmiu_skill)
kenewwangmiu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kenewwangmiuCard") then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = sgs.IntList()
	for _, acard in ipairs(cards) do
		if acard:isKindOf("BasicCard") or acard:isNDTrick() then
			to_throw:append(acard:getEffectiveId())
		end
	end
	card_id = to_throw:at(0)
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("#kenewwangmiuCard:" .. card_id .. ":")
	end
end


sgs.ai_skill_use_func["#kenewwangmiuCard"] = function(card, use, self)
	if not self.player:hasUsed("#kenewwangmiuCard") then
		self:sort(self.friends)
		for _, friend in ipairs(self.friends_noself) do
			if self:isFriend(friend) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
end

sgs.ai_use_value.kenewwangmiuCard = 8.5
sgs.ai_use_priority.kenewwangmiuCard = 9.5
sgs.ai_card_intention.kenewwangmiuCard = 80

sgs.ai_skill_playerschosen.kenewwangmiu = function(self, targets, max, min)
	local tos = {}
	if self.player:getMark("kenewwangmiu") > 0 then
		local card = sgs.Sanguosha:getCard(self.player:getMark("kenewwangmiu"))
		if card then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to then
					for _, p in sgs.qlist(dummy_use.to) do
						if #tos < max then
							table.insert(tos,p) end
						end
					end
				end
			end
		end
    return tos
end



function sgs.ai_cardneed.kenewwangmiuCard(to, card)
	return card:isKindOf("BasicCard") or card:isNDTrick()
end

--夏侯紫萼
sgs.double_slash_skill = sgs.double_slash_skill .. "|kenewqingran"
sgs.ai_cardneed.kenewqingran = sgs.ai_cardneed.slash
sgs.ai_skill_invoke.kenewlvefeng = function(self, data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end
sgs.ai_can_damagehp.kenewlvefeng = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and self:isWeak(from) and from:getHandcardNum()>0
	end
end


--王异

sgs.ai_skill_invoke.kenewzhenlietwo = function(self, data)
	if self:isWeak() then return false end
	local use = data:toCardUse()
	for _, szm in sgs.qlist(use.to) do
		if self:isFriend(szm) then
			return false
		end
	end
	return true
end

sgs.ai_skill_invoke.kenewzhenlie = sgs.ai_skill_invoke.zhenlie

sgs.ai_skill_invoke.kenewmiji = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kenewmiji = function(self, targets)
	if (self.player:getHandcardNum() > 3) then
		targets = sgs.QList2Table(targets)
		local theweak = sgs.SPlayerList()
		local theweaktwo = sgs.SPlayerList()
		for _, p in ipairs(targets) do
			if self:isFriend(p) then
				theweak:append(p)
			end
		end
		for _, qq in sgs.qlist(theweak) do
			if theweaktwo:isEmpty() then
				theweaktwo:append(qq)
			else
				local inin = 1
				for _, pp in sgs.qlist(theweaktwo) do
					if (pp:getHp() < qq:getHp()) then
						inin = 0
					end
				end
				if (inin == 1) then
					theweaktwo:append(qq)
				end
			end
		end
		if theweaktwo:length() > 0 then
			return theweaktwo:at(0)
		end
	end
	return nil
end

sgs.ai_skill_discard.kenewmiji = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	--[[local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)]]
	if (self.player:getHandcardNum() <= 3) then
		return self:askForDiscard("dummyreason", 999, 999, true, true)
	else
		local dd = self.player:getHandcardNum()
		while (dd > 3)
		do
			dd = dd - 1
			local cards = self.player:getCards("h")
			cards = sgs.QList2Table(cards)
			self:sortByKeepValue(cards)
			table.insert(to_discard, cards[1]:getEffectiveId())
		end
		return to_discard
	end
end

sgs.ai_getBestHp_skill.kenewmiji = function(owner)
	return owner:getMaxHp() - 1
end

