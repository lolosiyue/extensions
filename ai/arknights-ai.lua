--过载

local ark_guozai_skill = {}
ark_guozai_skill.name = "ark_guozai"
table.insert(sgs.ai_skills, ark_guozai_skill)
ark_guozai_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("&ark_guozai-PlayClear") >= self.player:getMaxHp() then return end
	local card = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	card:setSkillName("ark_guozai")
	card:deleteLater()
	local d = self:aiUseCard(card)
	self.ark_guozai_to = d.to
	if d.card and d.to
		and card:isAvailable(self.player)
	then
		return sgs.Card_Parse("#ark_guozai:.:")
	end
end

sgs.ai_skill_use_func["#ark_guozai"] = function(card, use, self)
	if self.ark_guozai_to
	then
		use.card = card
		if use.to then use.to = self.ark_guozai_to end
	end
end

sgs.ai_use_priority.ark_guozai = 8


sgs.ai_ajustdamage_from.ark_douzheng = function(self, from, to, card, nature)
	if to:objectName() ~= from:objectName()
	then
		return 1
	end
end


--共振

sgs.ai_skill_playerchosen.ark_gongzhen = function(self, targets)
	local en = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			table.insert(en, p)
		end
	end
	if #en == 0 then return nil end
	self:sort(en, "defense")
	if self.player:hasFlag("ark_gongzhenBasicCard") then
		for _, p in ipairs(en) do
			if p:getMark("&ark_gongzhen_recordtypeBasicCard") == 0 or p:getHandcardNum() >= 3 then return p end
		end
	elseif self.player:hasFlag("ark_gongzhenTrickCard") then
		sgs.reverse(en)
		for _, p in ipairs(en) do
			if p:getMark("&ark_gongzhen_recordtypeTrickCard") == 0 then return p end
		end
	elseif self.player:hasFlag("ark_gongzhenEquipCard") then
		for _, p in ipairs(en) do
			if p:getMark("&ark_gongzhen_recordtypeTrickCard") == 0 then return p end
		end
	end
	return en[math.random(1, #en)]
end

--缄默

sgs.ai_skill_invoke.ark_jianmo = function(self, data)
	local target
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("ark_jianmotarget") then
			target = p
			break
		end
	end
	return target and self:isEnemy(target)
end

sgs.ai_skill_playerschosen.ark_jianmo = function(self, targets, max, min)
	local enemy = sgs.SPlayerList()
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			enemy:append(p)
		end
	end
	return enemy
end

--剑雨

sgs.ai_skill_playerschosen.ark_jianyu = function(self, targets, max, min)
	local enemy = sgs.SPlayerList()
	for _, p in sgs.qlist(targets) do
		if not self:isEnemy(p) then
			enemy:append(p)
		end
	end
	return enemy
end

sgs.ai_ajustdamage_from.ark_chujue = function(self, from, to, card, nature)
	if to:objectName() ~= from:objectName()
	then
		return to:getLostHp() - 1
	end
end

--追猎

local ark_zhuilie_skill = {}
ark_zhuilie_skill.name = "ark_zhuilie"
table.insert(sgs.ai_skills, ark_zhuilie_skill)
ark_zhuilie_skill.getTurnUseCard = function(self, inclusive)
	return sgs.Card_Parse("#ark_zhuilie:.:")
end

sgs.ai_skill_use_func["#ark_zhuilie"] = function(card, use, self)
	local target
	self:sort(self.enemies, "hp")
	if #self.enemies == 0 then return "." end
	for _, enemy in ipairs(self.enemies) do
		if self.player:getHp() > 1
			or (not enemy:canSlash(self.player, true, 0))
			or (self:getCardsNum("Peach") + self:getCardsNum("Analpetic") + self:getCardsNum("Jink") > 0)
			or enemy:getHandcardNum() == 0
			or enemy:getMark("&ark_guodu_cant") > 0 then
			target = enemy
			break
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
	end
end

--坍缩

sgs.ai_skill_playerschosen.ark_tanshuo = function(self, targets, max, min)
	local enemy = sgs.SPlayerList()
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			enemy:append(p)
		end
	end
	if enemy:length() <= 0 then
		for _, p in sgs.qlist(targets) do
			if not self:isFriend(p) then
				enemy:append(p)
			end
		end
	end
	if enemy:length() <= 0 then
		targets = sgs.QList2Table(targets)
		enemy:append(targets[math.random(1, #targets)])
	end
	return enemy
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|ark_tanshuo"

--止戈

sgs.ai_skill_invoke.ark_zhige = function(self, data)
	local target = data:toPlayer()
	return target and self:isEnemy(target)
end

--万象

sgs.ai_skill_choice["ark_wanxiang"] = function(self, choices, data)
	local items = choices:split("+")
	if self.player:getMark("&ark_chongying") > 0 then table.removeOne(items, "ark_chongying") end
	if self.player:getMark("&ark_fuchen") > 0 then table.removeOne(items, "ark_fuchen") end
	if math.random(1, 2) == 1 then return "ark_wowu" end
	return items[math.random(1, #items)]
end

sgs.ai_ajustdamage_from["&ark_chongying"] = function(self, from, to, card, nature)
	if to:objectName() ~= from:objectName()
	then
		return math.min(to:getMark("&ark_chongying"), 3)
	end
end


--逐夜

sgs.ai_skill_invoke.ark_zhuye = function(self, data)
	local n = 1 - self.player:getHp()
	return (self:getCardsNum("Peach") + self:getCardsNum("Analeptic")) < n
end

--破晓

sgs.ai_skill_playerchosen.ark_poxiao = function(self, targets)
	local selected = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			table.insert(selected, p)
		end
	end
	if #selected == 0 then return nil end
	self:sort(selected, "hp")
	return selected[1]
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|ark_yaoyang"

sgs.ai_use_revises.ark_yaoyang = function(self,card,use)
	if card:isKindOf("Slash") then
		card:setFlags("Qinggang")
	end
end

sgs.ai_ajustdamage_from.ark_zhuye = function(self, from, to, card, nature)
	if from:getMark("&ark_zhuye") > 0
	then
		return 1
	end
end

sgs.ai_canNiepan_skill.ark_zhuye = function(player)
	return player:getMark("@ark_zhuye_mark") > 0
end
