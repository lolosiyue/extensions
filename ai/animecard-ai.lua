if not sgs.ai_nullification then
	sgs.ai_nullification = {}
end
-----------------------------武器
--青蔷薇
sgs.weapon_range.GreenRose = 2
function sgs.ai_weapon_value.GreenRose(self, enemy, player)
	if not enemy then return 5
		--装备武器就能摸2张牌，不管场上有没有敌人该武器都有价值
	elseif not enemy:hasArmorEffect("SilverLion") and enemy:getArmor() then return 6 end
		--敌人有装备，且没有狮子时，价值6
	return 6
end

function sgs.ai_slash_weaponfilter.GreenRose(self, to)
	return to:getArmor() and not to:hasArmorEffect("SilverLion")
end

--阐释者
sgs.weapon_range.Elucidator = 2
function sgs.ai_weapon_value.Elucidator(self, enemy, player)
	if not enemy then return 0
	elseif enemy:getHandcardNum() < 3 and player:getHandcardNum() > 2 then return 4
	elseif player:hasSkill("se_erdao") or player:hasSkill("LuaChanshi") then return 6 end
	return 3
end

function sgs.ai_slash_weaponfilter.Elucidator(self, to)
	return to:getHandcardNum() < 3
end

sgs.ai_skill_invoke["Se_Elucidator"] = function(self, data)
	local effect = data:toCardEffect()
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	duel:setSkillName("Se_Elucidator")
	local dummy_use = self:aiUseCard(duel, dummy(true, 0, self.room:getOtherPlayers(effect.to)))
	if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(effect.to) then
		return true
	end
	return false
end

--令咒
------------
function SmartAI:useCardreijyuu(card, use) --need help 这个锦囊太复杂了。。。。。
	if #self.enemies == 0 and #self.friends_noself == 0 then return false end
	local weak
	for _,p in ipairs(self.enemies) do
		if self:isWeak(p) then
			weak = p
		end
	end
	if weak then
		for _,v in ipairs(self.enemies) do
			if v:objectName() ~= weak:objectName() then
				use.card = card
				--if use.to and not (self.room:isProhibited(self.player, v, card) or self.room:isAkarin(self.player, v)) then use.to:append(v) end
				if use.to and not (self.room:isProhibited(self.player, v, card)) then use.to:append(v) end
				return
			end
		end
	else
		for _,v in ipairs(self.enemies) do
			use.card = card
			--if use.to and not (self.room:isProhibited(self.player, v, card) or self.room:isAkarin(self.player, v)) then use.to:append(v) end
			if use.to and not (self.room:isProhibited(self.player, v, card) ) then use.to:append(v) end
			return
		end
	end
end
sgs.ai_use_priority.reijyuu = 4.55
sgs.ai_use_value.reijyuu = 9
sgs.ai_keep_value.reijyuu = 1.0
sgs.ai_card_intention.reijyuu = 40

sgs.ai_nullification.reijyuu = function(self, card, from, to, positive)
	if positive then
		if self:isFriend(to) and self:isEnemy(from) then return true end
	else
		if self:isEnemy(to) and self:isFriend(from) then return true end
	end
	return
end
--mubiao->weak
sgs.ai_skill_playerchosen.reijyuu = function(self, targets)
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) and self:isWeak(p) then return p end
	end
	return self.player
end

sgs.ai_skill_choice.reijyuu = function(self, choices, data)
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("reijyuuT") then
			if self:isFriend(p) then
				return "reijyuuMove"
			else
				return "reijyuuDamage"
			end
		end
	end
	return "reijyuuMove"
end

function SmartAI:useCardtacos(card, use)
	for _,p in ipairs(self.enemies) do
		if p:hasSkill("eastfast") then return end
	end
	for _,p in ipairs(self.friends) do
		if p:hasSkill("SE_Jiawu") then return end
	end
	use.card = card
end

sgs.ai_card_intention.tacos = -40

sgs.ai_keep_value.tacos = 2.5
sgs.ai_use_value.tacos = 8
sgs.ai_use_priority.tacos = 4

sgs.dynamic_value.benefit.tacos = true