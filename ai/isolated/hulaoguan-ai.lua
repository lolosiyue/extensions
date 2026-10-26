-- Source: b6025acc ai/hulaoguan-ai.lua.


ai_skill_invoke["weapon_recast"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	if self:hasSkills(sgs.lose_equip_skill, self.player) then return (false) or false end
	if self.player:isLord() then
		local card_use = data:toCardUse()
		if card_use.card:objectName()~="Crossbow" then return (true) or false end
	else
		if self.player:getWeapon() then return (true) or false end
	end
	return false

end

ai_skill_invoke["draw_1v3"] = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	return (not self:needKongcheng(self.player, true)) or false
end

ai_skill_choice.Hulaopass = "recover"

sgs.ai_skill_cardask["@xiuluo"] = function(self,data,pattern)
	if self.player:containsTrick("YanxiaoCard") then return "." end
	if not self.player:containsTrick("indulgence") and not self.player:containsTrick("supply_shortage")
		and not (self.player:containsTrick("lightning") and not self:hasWizard(self.enemies)) then return "." end
	local indul_suit,ss_suit,lightning_suit = nil,nil,nil
	for _,card in sgs.qlist(self.player:getJudgingArea())do
		if card:isKindOf("Indulgence") then indul_suit = card:getSuit() end
		if card:isKindOf("SupplyShortage") then ss_suit = card:getSuit() end
		if card:isKindOf("Lightning") then ss_suit = card:getSuit() end
	end
	if ss_suit then
		for _,card in sgs.qlist(self.player:getHandcards())do
			if card:getSuit()==ss_suit then return "$"..card:getKnownEffectiveId() end
		end
	elseif indul_suit then
		for _,card in sgs.qlist(self.player:getHandcards())do
			if card:getSuit()==indul_suit and not isCard("Peach",self.player,card) then return "$"..card:getKnownEffectiveId() end
		end
	elseif lightning_suit then
		for _,card in sgs.qlist(self.player:getHandcards())do
			if card:getSuit()==lightning_suit and not isCard("Peach",self.player,card) then return "$"..card:getKnownEffectiveId() end
		end
	end
	return "."
end

sgs.ai_skill_askforag.xiuluo = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = self:getChoiceCard(id)
		if card:isKindOf("SupplyShortage") then return id end
	end
	for _,id in ipairs(card_ids)do
		local card = self:getChoiceCard(id)
		if card:isKindOf("Indulgence") then return id end
	end
	if self:hasWizard(self.enemies) and self.player:containsTrick("lightning") then
		for _,id in ipairs(card_ids)do
			local card = self:getChoiceCard(id)
			if card:isKindOf("Lightning") then return id end
		end
	end
	return card_ids[1]
end

ai_skill_choice.hulaopass_shenlvbu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil
  --待补充
	local lvbus = choices:split("+")
	return ai_choice_result((lvbus[math.random(1,#lvbus)]), options)
end


--神躯
ai_skill_choice.shenqu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	return ai_choice_result((true), options)
end

--极武
local function CanUsejiwu(self)
	if self:needBear() and self.player:getHandcardNum()>self.player:getMaxCards() then return false end
	
	if not self.player:hasSkill("xuanfeng", true) and self.player:getEquips():length()>0 then return true end
	if not self.player:hasSkill("lieren", true) and self:getCardsNum("Slash")>0 and
		(self.player:getHandcardNum()-self:getCardsNum("Peach")-self:getCardsNum("Slash")>0) then return true end
	local candis = false
	for _,c in sgs.list(self.player:getCards("he"))do
		if c:isKindOf("Weapon") and self.player:canDiscard(self.player, c:getKnownEffectiveId()) then
			candis = true
			break
		end
	end
	if not self.player:hasSkill("qiangxi", true) and (self.player:getHp()>3 or self:getCardsNum("Peach")>0 or candis) then return true end
	self:sort(self.enemies, "hp")
	if not self.player:hasSkill("wansha", true) then
		for _,enemy in sgs.list(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:isKongcheng()) and self:isWeak(enemy) and self:damageMinusHp(enemy, 1)>0 and #self.enemies>1 then
				return true
			end
			if self.player:hasSkill("qiangxi") and self:isWeak(enemy) and self:damageMinusHp(enemy, 1)>0 then
				return true
			end
		end
	end
	
	if self:needToThrowArmor() and self.player:canDiscard(self.player, self.player:getArmor():getEffectiveId()) then return true end
	
	local num = 0
	if not self.player:hasSkill("xuanfeng", true) then num = num+1 end
	if not self.player:hasSkill("lieren", true) then num = num+1 end
	if not self.player:hasSkill("qiangxi", true) then num = num+1 end
	if not self.player:hasSkill("wansha", true) then num = num+1 end
	if self:needKongcheng(self.player, true) and self.player:getHandcardNum()<=num and num>0 then return true end
	
	return false
end

ai_fill_skill.jiwu = function(self, options, request)
    local inclusive = options and options.inclusive

	if not CanUsejiwu(self) then return end
	return self:legacySkillSeed("jiwu", "JiwuCard", request)
end

ai_card_use.JiwuCard = function(self, card, use, request)
	local usable_cards = self.player:getCards("h")
	local use_card = {}
	for _,c in sgs.list(usable_cards)do
		if not c:isKindOf("Peach") and not c:isKindOf("ExNihilo") then
			table.insert(use_card,c)
		end
	end
	if #use_card==0 then return end
	self:sortByKeepValue(use_card)
	use.card = self:bindSkillCard("jiwu", {use_card[1]:getKnownEffectiveId()}, request, nil, "JiwuCard")
end

ai_skill_choice.jiwu = function(self, options, request)
    local choices = options and options.choices ~= nil and table.concat(options.choices, "+") or options and (options.inquiry_scope == "ordinary_top_level" or options.inquiry_scope == "original_top_level") and "" or nil
    local data = request and self:getDecisionData(request) or nil

	if self.player:getHandcardNum()-self:getCardsNum("Peach")>0 then
		if not self.player:hasSkill("xuanfeng", true) and self.player:getEquips():length()>0 then
			return ai_choice_result(("xuanfeng"), options)
		end
		if not self.player:hasSkill("lieren", true) and self:getCardsNum("Slash")>0 and (self.player:getHandcardNum()-self:getCardsNum("Peach")-self:getCardsNum("Slash")>0) then
			return ai_choice_result(("lieren"), options)
		end
		
		local candis = false
		for _,c in sgs.list(self.player:getCards("he"))do
			if c:isKindOf("Weapon") and self.player:canDiscard(self.player, c:getKnownEffectiveId()) then
				candis = true
				break
			end
		end
		if not self.player:hasSkill("qiangxi", true) and (self.player:getHp()>3 or self:getCardsNum("Peach")>0 or candis) then
			return ai_choice_result(("qiangxi"), options)
		end
		
		self:sort(self.enemies, "hp")
		if not self.player:hasSkill("wansha", true) then
			for _,enemy in sgs.list(self.enemies)do
				if not (enemy:hasSkill("kongcheng") and enemy:isKongcheng()) and self:isWeak(enemy) and self:damageMinusHp(enemy, 1)>0 and #self.enemies>1 then
					return ai_choice_result(("wansha"), options)
				end
				if self.player:hasSkill("qiangxi") and self:isWeak(enemy) and self:damageMinusHp(enemy, 1)>0 then
					return ai_choice_result(("wansha"), options)
				end
			end
		end
	else
		if not self.player:hasSkill("xuanfeng", true) then
			return ai_choice_result(("xuanfeng"), options)
		end
		if not self.player:hasSkill("lieren", true) then
			return ai_choice_result(("lieren"), options)
		end
		if not self.player:hasSkill("qiangxi", true) then
			return ai_choice_result(("qiangxi"), options)
		end
		if not self.player:hasSkill("wansha", true) then
			return ai_choice_result(("wansha"), options)
		end
	end
	return ai_choice_result((choices:split("+")[1]), options)
end

sgs.ai_use_priority.JiwuCard = sgs.ai_use_priority.Slash+0.1
sgs.ai_use_value.JiwuCard = 3

ai_skill_invoke.wushuangji = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local target = data:toPlayer()
	if target then
		return (self:doDisCard(target, "he") or self:canDraw()) or false
	end
	return false

end

sgs.ai_skill_cardchosen.wushuangji = function(self,who,flags,method)
	if self:doDisCard(who, "he")
	then return end
    return -1
end

sgs.ai_use_value.Wushuangji = 3
sgs.ai_keep_value.Wushuangji = 3.9

ai_skill_invoke.shimandai = function(self, options, request)
	local data = request and self:getDecisionData(request) or nil
	local use = data:toCardUse()
	if use.card:isDamageCard() then
		if self:canDamageHp(use.from, use.card) then
			return (false) or false
		end
	end
	return (not self:isFriend(use.from)) or false
end

sgs.ai_use_value.Shimandai = 4.4
sgs.ai_keep_value.Shimandai = 3.9

sgs.ai_target_revises.baihuapao = function(to,card,self)
    if card:isKindOf("NatureSlash") then
		return not self:hasJueqingEffect(self.player, to)
	end
end

sgs.ai_ajustdamage_to.baihuapao = function(self,from,to,card,nature)
	if nature~="N" and not self:hasJueqingEffect(from, to) then
		return -99
	end
end

sgs.ai_use_value.Baohuapao = 5.4
sgs.ai_keep_value.Baohuapao = 3.9

sgs.ai_skill_playerchosen.zijinguan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		and self:damageIsEffective(p, "N")
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		and self:damageIsEffective(p, "N")
		then return p end
	end
end

sgs.ai_use_value.Zijinguan = 5.4
sgs.ai_keep_value.Zijinguan = 3.9

function SmartAIView:useCardLianjunshengyan(card,use)
	local n = 0
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if self.player:canUse(card, p) then
			if self:isEnemy(p) then
				n = n-1
				if self:isWeak(p) then
					n = n-1
				end
			else
				n = n+1
				if self:isFriend(p) and self:isWeak(p) then
					n = n+1
				end
			end
		end
	end
	if n>=0 then
		use.card = card
	end
end
sgs.ai_use_priority.Lianjunshengyan = 1.4
sgs.ai_keep_value.Lianjunshengyan = 4
sgs.ai_use_value.Lianjunshengyan = 2.7





