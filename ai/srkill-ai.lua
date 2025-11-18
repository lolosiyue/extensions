sgs.ai_skill_choice["lose_a_sk"] = function(self, choices, data)
	local choices1 = choices:split("+")
	return choices1[math.random(1, #choices1)]
	--return "losenone"
end

--仁德
sgs.ai_skill_invoke.sr_rende = function(self,data)
	local current = self.player:getRoom():getCurrent()
	return self:isFriend(current)
end
sgs.ai_choicemade_filter.skillInvoke.sr_rende = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, current, -20)
		end
	end
end


sgs.ai_skill_askforyiji.sr_rende = function(self, card_ids)
	local current = self.player:getRoom():getCurrent()
	if not current or not self:isFriend(current) or current:isDead() then
		return nil,-1
	end
	if self:isWeak(self.player) or self.player:isKongcheng() or 
		self.player:objectName() == current:objectName() then 
		return current,-1
	end
	local slash,peach = {},{}
	for _,id in ipairs(card_ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("Slash") then
			table.insert(slash,id)
		elseif card:isKindOf("Peach") or card:isKindOf("Analeptic") or card:isKindOf("Jink") then
			table.insert(peach,id)
		end
	end
	if #slash~= 0 then
		return current,slash[1]
	end
	if (self:isWeak(current) or current:getHp()<=2 )and #peach ~= 0 then
		return current,peach[1]
	end
	return current,-1
end
--仇袭
local sr_chouxi_skill = {}
sr_chouxi_skill.name = "sr_chouxi"
table.insert(sgs.ai_skills, sr_chouxi_skill)
sr_chouxi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sr_chouxicard") or self.player:isKongcheng() or #self.enemies == 0 then 
		return nil end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	return sgs.Card_Parse("#sr_chouxicard:"..cards[1]:getId()..":")	
end

sgs.ai_skill_use_func["#sr_chouxicard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["sr_chouxicard"] = 8

sgs.ai_skill_playerchosen["sr_chouxi"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	self:sort(enemies,"defense")	
	return enemies[1]
end
sgs.ai_playerchosen_intention.sr_chouxi = 10

sgs.ai_skill_cardask["@srchouxi-discard"] = function(self, data, pattern, target, target2)
	if self.player:isKongcheng() then return "." end
	local types = pattern:split("|")[1]:split(",")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards)
	local cando = false
	local todiscard = {}
	for _, card in ipairs(cards) do
		if not self:isValuableCard(card) then
			for _, classname in ipairs(types) do
				if card:isKindOf(classname) then 
					table.insert(todiscard,card)
				end
			end
		end
	end
	if #todiscard > 0 then cando = true end
	local tag = self.room:getTag("agcards"):toString():split("+")
	for _,id in ipairs(tag) do
		local cd = sgs.Sanguosha:getCard(tonumber(id))
		if cd:isKindOf("Peach") or cd:isKindOf("ExNihilo") and not self:isWeak() then
			cando = false
			break
		end
	end

	if cando then
		return "$"..todiscard[1]:getEffectiveId()
	else
		return "."
	end
end
--拥兵
sgs.ai_skill_playerchosen["sr_yongbing"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	if #friends == 0 then return nil end
	self:sort(friends,"defense")	
	return friends[1]
end
sgs.ai_playerchosen_intention.sr_yongbing = -50
--授计
local sr_shouji_skill = {}
sr_shouji_skill.name = "sr_shouji"
table.insert(sgs.ai_skills, sr_shouji_skill)
sr_shouji_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sr_shoujicard") then return nil end
	if self.player:isKongcheng() then return nil end
	if #self.enemies==0 and #self.friends == 0 then return nil end	
	return sgs.Card_Parse("#sr_shoujicard:.:")
end

sgs.ai_skill_use_func["#sr_shoujicard"] = function(card, use, self)
	self:sort(self.friends,"defense",false)
	self:sort(self.enemies,"defense")	
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	local card = cards[1]
	if card:getSuit() == sgs.Card_Spade then
		local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit,0)
		duel:deleteLater()
		for _,p in ipairs(self.friends) do
			for _,q in ipairs(self.enemies) do
				if not p:isProhibited(q, duel) then
					use.card = sgs.Card_Parse("#sr_shoujicard:"..card:getEffectiveId()..":")
					if use.card and use.to then
						use.to:append(p)
						use.to:append(q)
					end
					return
				end
			end
		end
	elseif card:getSuit() == sgs.Card_Heart then
		local snatch = sgs.Sanguosha:cloneCard("snatch",sgs.Card_NoSuit,0)
		snatch:deleteLater()
		for _,p in ipairs(self.friends) do
			for _,q in ipairs(self.enemies) do
				if not p:isProhibited(q, snatch) and p:distanceTo(q) == 1 and not q:isAllNude() then					
					use.card = sgs.Card_Parse("#sr_shoujicard:"..card:getEffectiveId()..":")
					if use.card and use.to then
						use.to:append(p)
						use.to:append(q)
					end
					return
				end
			end
		end
	elseif card:getSuit() == sgs.Card_Club then
		local co = sgs.Sanguosha:cloneCard("collateral",sgs.Card_NoSuit,0)
		co:deleteLater()
		for _,p in ipairs(self.friends) do
			for _,q in ipairs(self.enemies) do
				if not p:isProhibited(q, co) and q:getWeapon() ~=nil then
					use.card = sgs.Card_Parse("#sr_shoujicard:"..card:getEffectiveId()..":")
					if use.card and use.to then
						use.to:append(p)
						use.to:append(q)
					end
					return
				end
			end
		end
	elseif card:getSuit() == sgs.Card_Diamond then
		local fireattact = sgs.Sanguosha:cloneCard("fire_attack",sgs.Card_NoSuit,0)
		fireattact:deleteLater()
		for _,p in ipairs(self.friends) do
			for _,q in ipairs(self.enemies) do
				if not p:isProhibited(q, fireattact) and not q:isKongcheng() and not p:isKongcheng() and
					not (p:objectName() == self.player:objectName() and self.player:getHandcardNum() ==1) then
					use.card = sgs.Card_Parse("#sr_shoujicard:"..card:getEffectiveId()..":")
					if use.card and use.to then
						use.to:append(p)
						use.to:append(q)
					end
					return
				end
			end
		end
	end
	return 	
end

sgs.ai_use_value["sr_shoujicard"] = 2.3

sgs.ai_skill_playerchosen["sr_shouji"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	self:sort(enemies,"defense")	
	return enemies[1]
end

--合谋
-- sgs.ai_skill_cardask["@srhemou-discard"] = function(self, data, pattern, target, target2)
-- 	local damage = data:toDamage()
-- 	if not damage.from or not self:isFriend(damage.from) then return "." end
-- 	local cards = sgs.QList2Table(self.player:getHandcards())
-- 	self:sortByKeepValue(cards)
-- 	return "$"..cards[1]:getEffectiveId()
-- end
sgs.ai_skill_cardask["@sr_hemou"] = function(self, data, pattern, target, target2)
	local current = self.room:getCurrent()
	if not current or not self:isFriend(current) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	return "$"..cards[1]:getEffectiveId()
end
sgs.ai_choicemade_filter.cardResponded["@sr_hemou"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, -50)
	end
end

local sr_hemouvs_skill = {}
sr_hemouvs_skill.name = "sr_hemouvs"
table.insert(sgs.ai_skills, sr_hemouvs_skill)
sr_hemouvs_skill.getTurnUseCard = function(self,inclusive)
	local n = self.player:getMark("hemousuit")
	if n<=0 then return nil end	
	local cards = {}
	for _,p in sgs.qlist(self.player:getHandcards()) do
		if p:getSuit() == n-1 then
			table.insert(cards,p)
		end
	end
	if #cards == 0 then return nil end
	self:sortByKeepValue(cards)	
	local suit = cards[1]:getSuitString()
	local number = cards[1]:getNumberString()
	local card_id = cards[1]:getEffectiveId()
	local card_str = ""
	if n == 1 then
		card_str = ("duel:sr_hemouvs[%s:%s]=%d"):format(suit, number, card_id)
	elseif n == 2 then
		card_str = ("collateral:sr_hemouvs[%s:%s]=%d"):format(suit, number, card_id)
	elseif n == 3 then
		card_str = ("snatch:sr_hemouvs[%s:%s]=%d"):format(suit, number, card_id)
	elseif n == 4 then
		card_str = ("fire_attack:sr_hemouvs[%s:%s]=%d"):format(suit, number, card_id)
	end
	local hemoucard = sgs.Card_Parse(card_str)
	
	assert(hemoucard)

	return hemoucard
end

--奔袭
sgs.ai_skill_cardask["@srbenxi-discard"] = function(self, data, pattern, target, target2)
	if self.player:isKongcheng() then return "." end
	local use = data:toCardUse()
	local card = use.card
	local hasjink ,equip= false,{}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:isKindOf("EquipCard")  and not (self.player:getEquip(1) and 
			self.player:getEquip(1):objectName() ==c:objectName() 
			and not c:isKindOf("SilverLion")) then
			table.insert(equip,c)			
		end
	end
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:isKindOf("Jink") then
			hasjink = true
			break
		end
		if not use.from:hasWeapon("QinggangSword") and self.player:getMark("Armor_Nullified") ==0 then
			if self.player:getEquip(1) then
				if self.player:getEquip(1):isKindOf("EightDiagram") then
					hasjink = true
					break
				end
				if self.player:getEquip(1):isKindOf("RenwangShield") and card:isBlack() 
					and card:isKindOf("Slash") then
					hasjink = true
					break
				end
				if self.player:getEquip(1):isKindOf("Vine") and card:isKindOf("NormalSlash") then
					hasjink = true
					break
				end
			end
		end
	end
	if #equip == 0 or not hasjink then return "." end
	if self:needToLoseHp(self.player, use.from, use.card) then return "." end
	self:sortByKeepValue(equip)
	return "$"..equip[1]:getEffectiveId()
end
sgs.hit_skill = sgs.hit_skill .. "|sr_benxi"
sgs.ai_cardneed.sr_benxi = sgs.ai_cardneed.slash
--邀战
local sr_yaozhan_skill = {}
sr_yaozhan_skill.name = "sr_yaozhan"
table.insert(sgs.ai_skills, sr_yaozhan_skill)
sr_yaozhan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sr_yaozhancard") then return nil end
	if self.player:isKongcheng() then return nil end
	if #self.enemies==0 then return nil end
	local cando = false
	for _,p in ipairs(self.enemies) do
		if not p:isKongcheng() and p:getHandcardNum() <=3 and self.player:canPindian(p) then
			cando = true
			break
		end
	end
	if not cando then return nil end	
	return sgs.Card_Parse("#sr_yaozhancard:.:")
end

sgs.ai_skill_use_func["#sr_yaozhancard"] = function(card, use, self)
	local maxcard = self.player:getHandcards():first()
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:getNumber() > maxcard:getNumber() then
			maxcard =c 
		end
	end
	if maxcard:getNumber() <=6 then return end	
	local enemies = {}
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("_sr_yaozhan")
	slash:deleteLater()
	for _,p in ipairs(self.enemies) do
		if not p:isKongcheng() and p:getHandcardNum() <=3 and self.player:canPindian(p) and not self:slashProhibit(slash, p) and self:isGoodTarget(p, self.enemies, slash) and self:slashIsEffective(slash, p) then
			table.insert(enemies,p)
		end
	end
	self:sort(enemies,"defense")
	use.card = sgs.Card_Parse("#sr_yaozhancard:"..maxcard:getEffectiveId()..":")
	if use.card and use.to then
		use.to:append(enemies[1])
	end
end
sgs.ai_use_priority["sr_yaozhancard"] =sgs.ai_use_priority.Slash - 0.1

sgs.ai_cardneed.sr_yaozhan = sgs.ai_cardneed.bignumber
--温酒
sgs.ai_cardneed.sr_wenjiu = sgs.ai_cardneed.slash
local sr_wenjiu_skill = {}
sr_wenjiu_skill.name = "sr_wenjiu"
table.insert(sgs.ai_skills, sr_wenjiu_skill)
sr_wenjiu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sr_wenjiucard") then return nil end
	if self.player:isKongcheng() then return nil end
	--if self.player:getHandcardNum() +2 <= self.player:getHp() then return nil end
	if self.player:getPile("@srjiu"):length() >=2 and self.player:getHandcardNum() <= self.player:getHp()  then 
		return nil end
	local black = {}
	for _,p in sgs.qlist(self.player:getHandcards()) do
		if p:isBlack() then
			table.insert(black,p)
		end
	end
	if #black == 0 then return nil end
	self:sortByUseValue(black)
	return sgs.Card_Parse("#sr_wenjiucard:"..black[1]:getEffectiveId()..":")
end

sgs.ai_skill_use_func["#sr_wenjiucard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["sr_wenjiucard"] = 7
sgs.ai_use_priority["sr_wenjiucard"] = 3.5

sgs.ai_skill_invoke["sr_wenjiu"] = function(self,data)
	local use = data:toCardUse()
	for _,p in ipairs(self.friends) do
		if use.to:contains(p) then
			return false
		end
	end
	return true
end
sgs.ai_ajustdamage_from.sr_wenjiu = function(self, from, to, card, nature)
	if (card and (card:isKindOf("Slash") )) and from:getMark("wenjiuslash") > 0
	then
		return 1
	end
end


--水袭
sgs.ai_skill_use["@@sr_shuixi"] = function(self, prompt)
	if self.player:isKongcheng() then return "." end
	local enemy = nil
	self:sort(self.enemies,"defense")
	for _,p in ipairs(self.enemies) do
		if not p:isKongcheng() then
			enemy = p
			break
		end
	end
	if not enemy then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	return "#sr_shuixicard:"..cards[1]:getEffectiveId()..":->"..enemy:objectName()
end

sgs.ai_skill_cardask["@srshuixithrow"] = function(self, data, pattern, target, target2)
	local card = {}
	local suit = data:toString()
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:getSuitString() == suit then
			table.insert(card,c)
		end
	end
	if #card == 0 then return "." end
	local current = self.room:getCurrent()
	if current and self:isEnemy(current) then
		self:sortByKeepValue(card)
		return "$"..card[1]:getEffectiveId()
	end
	return "."
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|sr_shuixi"
sgs.ai_card_intention["sr_shuixicard"] = 70

--三分
local sr_sanfen_skill = {}
sr_sanfen_skill.name = "sr_sanfen"
table.insert(sgs.ai_skills, sr_sanfen_skill)
sr_sanfen_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sr_sanfencard") then return nil end	
	if #self.enemies==0 then return nil end	
	return sgs.Card_Parse("#sr_sanfencard:.:")
end

sgs.ai_skill_use_func["#sr_sanfencard"] = function(card, use, self)
	self:sort(self.friends,"defense",false)
	self:sort(self.enemies,"defense")		
	for _,p in ipairs(self.enemies) do
		for _,q in ipairs(self.enemies) do
			if q:objectName() ~=p:objectName() and not q:isNude() and not p:isNude() and p:canSlash(q,false)
				and q:canSlash(self.player,false) then
				use.card = sgs.Card_Parse("#sr_sanfencard:.:")
				if use.card and use.to then
					use.to:append(p)
					use.to:append(q)
				end
				return
			end
		end
	end	
	local allplayers = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(allplayers,"defense",false)	
	for _,p in ipairs(allplayers) do
		for _,q in ipairs(self.enemies) do
			if q:objectName() ~=p:objectName() and not q:isKongcheng() and not p:isKongcheng() 
				and p:canSlash(q,false)
				and q:canSlash(self.player,false) then
				use.card = sgs.Card_Parse("#sr_sanfencard:.:")
				if use.card and use.to then
					use.to:append(p)
					use.to:append(q)
				end
				return
			end
		end
	end	
	return 	
end


sgs.ai_ajustdamage_to.sr_weiwo = function(self, from, to, card, nature)
	if (nature ~= "N" and not to:isKongcheng()) or (nature == "N" and to:isKongcheng())
	then
		return -99
	end
end

--蓄劲
sgs.ai_skill_invoke["sr_xujin"] = function(self,data)
	return self.player:getHandcardNum() >= 2
end
sgs.ai_skill_playerchosen["sr_xujin"] = function(self, targets)
	return self.player
end
sgs.ai_cardneed.sr_xujin = sgs.ai_cardneed.slash
--咆哮
sgs.ai_skill_invoke["sr_paoxiao"] = function(self,data)	
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("Slash") then
			return true
		end
	end
	return self.player:getHandcardNum() >=2
end
sgs.ai_cardneed.sr_paoxiao = sgs.ai_cardneed.slash
sgs.double_slash_skill = sgs.double_slash_skill .. "|sr_paoxiao"
--救主
sgs.ai_skill_cardask["@sr_jiuzhu"] = function(self, data, pattern, target, target2)
	if self.player:isNude() then return "." end
	local suit = data:toString()
	local candis = {}
	local current = self.room:getCurrent()	
	for _,p in sgs.qlist(self.player:getCards("he")) do
		if not p:isKindOf("Jink") then
			table.insert(candis,p)
		end
	end
	if  #candis == 0 then return "." end
	local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	if not current or self:isFriend(current) or self.player:isProhibited(current,slash) then
		for _,p in sgs.qlist(self.player:getCards("he")) do
			if p:isKindOf("Jink") then
				return "."
			end
		end
	end
	self:sortByKeepValue(candis)
	return "$"..candis[1]:getEffectiveId()
end

sgs.ai_skill_invoke["sr_jiuzhu"] = function(self,data)
	local current = self.room:getCurrent() 
	local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	slash:setSkillName("_sr_jiuzhu")
	slash:deleteLater()
	return current and self:isEnemy(current) and not self:slashProhibit(slash, current) and self:slashIsEffective(slash, current) and self:isGoodTarget(current, self.enemies, slash)
end

--突围
function hasOnlySilverLionEffect(p)
	if not p or not p:isAlive() or not p:isWounded() then return false end
	if not p:isKongcheng() then return false end
	if not p:getEquip(1) or p:getEquip(0) or p:getEquip(2) or p:getEquip(3) then return false end
	return p:getEquip(1):isKindOf("SilverLion")
end
function hasSilverLionEffect(p)
	if not p:isWounded() then return false end	
	if not p:getEquip(1) then return false end
	return p:getEquip(1):isKindOf("SilverLion")
end

sgs.ai_skill_cardask["@sr_tuwei"] = function(self, data, pattern, target, target2)
	local tos = data:toString():split("+")
	local cando = false
	for _,to in ipairs(tos) do
		local p = self.room:findPlayer(to)
		if self:isEnemy(p) and not p:isNude() and not hasOnlySilverLionEffect(p) and 
			self.player:canDiscard(p,"he") then
			cando = true
			break
		end
		if self:isFriend(p) and hasOnlySilverLionEffect(p) and self.player:canDiscard(p,"he") then
			cando = true
			break
		end
	end
	if not cando then return "." end
	local pattern = "Slash,FireAttack,Duel,SavageAssault,ArcheryAttack,Drowning"
	local candis = {}
	for _, pat in ipairs(pattern:split(",")) do
		for _,c in sgs.qlist(self.player:getCards("he")) do
			if c:isKindOf(pat) then
				table.insert(candis,c)
			end
		end
	end
	if #candis == 0 then return "." end
	self:sortByKeepValue(candis)
	return "$"..candis[1]:getEffectiveId()
end



--权衡
function hasNoJinkEffect(who)
	return who:hasSkill("wushuang") or who:hasSkill("sy_wushuang") or who:hasSkill("sy_shisha") or who:hasSkill("sr_benxi") or who:hasSkill("liegong")
	or who:hasSkill("ol_liegong") or who:hasSkill("tieqi")
end
local sr_quanheng_skill = {}
sr_quanheng_skill.name = "sr_quanheng"
table.insert(sgs.ai_skills, sr_quanheng_skill)
sr_quanheng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return nil end
	if self.player:hasFlag("quanheng_used") then return nil end
	return sgs.Card_Parse("#sr_quanhengCard:.:")
end

sgs.ai_skill_use_func["#sr_quanhengCard"] = function(card, use, self)
	local E = 0
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) then E = E + 1 end
	end
	if E == 0 or #self.enemies == 0 or self:isWeak() then
		sgs.ai_use_priority["sr_quanhengCard"] = sgs.ai_use_priority.ExNihilo
	else
		sgs.ai_use_priority["sr_quanhengCard"] = sgs.ai_use_priority.Slash
	end
	use.card = card
end

sgs.ai_skill_use["@@sr_quanheng_slash"] = function(self, prompt)
	local need_ids = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	if not hasNoJinkEffect(self.player) then
		for _, c in ipairs(cards) do
			if not c:isKindOf("Peach") then table.insert(need_ids, c:getEffectiveId()) end
			if #need_ids == math.min(2, #cards) then break end
		end
	else
		for _, c in ipairs(cards) do
			if not c:isKindOf("Peach") then table.insert(need_ids, c:getEffectiveId()) end
			if #need_ids == 1 then break end
		end
	end
	local quanheng_slash = sgs.Sanguosha:cloneCard("slash")
	quanheng_slash:setSkillName("sr_quanheng")
	quanheng_slash:deleteLater()
	local dummy_use = self:aiUseCard(quanheng_slash, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		self:sort(targets, "defense")
		return "#sr_quanheng_slashCard:" .. table.concat(need_ids, "+") .. ":->" .. table.concat(targets, "+")
	end
end

sgs.ai_skill_use["@@sr_quanheng_ex_nihilo"] = function(self, prompt)
	local need_ids = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	if #self.enemies > 0 then
		for _, c in ipairs(cards) do
			if not c:isKindOf("Peach") then table.insert(need_ids, c:getEffectiveId()) end
			if #need_ids == math.min(2, #cards) then break end
		end
	else
		for _, c in ipairs(cards) do
			if not c:isKindOf("Peach") then table.insert(need_ids, c:getEffectiveId()) end
			if #need_ids == 1 then break end
		end
	end
	if #need_ids > 0 then
		return string.format("#sr_quanheng_ex_nihiloCard:%s:", table.concat(need_ids, "+"))
	else
		return nil
	end
end

sgs.ai_skill_choice["sr_quanheng"] = function(self, choices, data)
	if #self.enemies == 0 or self:isWeak() then return "quanheng_vs_exnihilo" end
	local E = 0
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) then E = E + 1 end
	end
	if E == 0 then return "quanheng_vs_exnihilo" end
	local quanheng = choices:split("+")
	return quanheng[math.random(1, #quanheng)]
end

sgs.ai_use_value["sr_quanhengCard"] = 4


--雄略
local sr_xionglve_skill = {}
sr_xionglve_skill.name = "sr_xionglve"
table.insert(sgs.ai_skills, sr_xionglve_skill)
sr_xionglve_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getPile("@srlve"):isEmpty() then return nil end
	if self.player:hasFlag("xionglveused") then return nil end
	if #self.enemies == 0 and #self.friends_noself == 0 then return nil end
	local Analeptic = sgs.Sanguosha:cloneCard("analeptic",sgs.Card_NoSuit,0)
	if not self.player:isWounded() and not sgs.Slash_IsAvailable(self.player) and 
		not Analeptic:isAvailable(self.player) then
		return nil
	end	
	return sgs.Card_Parse("#sr_xionglvecard:.:")	
end

sgs.ai_skill_use_func["#sr_xionglvecard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["sr_xionglvecard"] = sgs.ai_use_value.Analeptic

function shouldUseSlash(player,enemies)
	for _,p in ipairs(enemies) do
		if player:canSlash(p,true) then
			return true
		end
	end
	return false
end

sgs.ai_skill_askforag["sr_xionglvecard"] = function(self,card_ids)
	if self.player:isWounded() or sgs.Slash_IsAvailable(self.player) and 
		shouldUseSlash(self.player,self.enemies) then
		for _,id in ipairs(card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("BasicCard") then
				return id
			end
		end
	else
	 	for _,id in ipairs(card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("TrickCard") then
				return id
			end
		end
		for _,id in ipairs(card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if card:isKindOf("EquipCard") then
				return id
			end
		end
	end
end

sgs.ai_skill_choice["sr_xionglvebasic"] = function(self, choices, data)
	if self.player:isWounded() then return "srcanpeach" end
	if sgs.Slash_IsAvailable(self.player) then
		if shouldUseSlash(self.player,self.enemies) then
			local Analeptic = sgs.Sanguosha:cloneCard("analeptic",sgs.Card_NoSuit,0)
			if self:getCardsNum("Slash") > 0 and Analeptic:isAvailable(self.player) then
				return "srcananaleptic"
			else
				return "srcanslash"
			end
		else
			self.room:setPlayerFlag(self.player,"xionglveused")
			return "cancel"
		end
	end
	self.room:setPlayerFlag(self.player,"xionglveused")
	return "cancel"
end
sgs.ai_skill_playerchosen["sr_xionglveslash"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	self:sort(enemies,"defense")	
	return enemies[1]
end


sgs.ai_skill_choice["sr_xionglvetrick"] = function(self,choices,data)	
	local f,e = 0,0
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if self:isFriend(p) then
			if self:isWeak(p) then
				f = f+1
			else
				if p:getJudgingArea():length()>0 then
					if self.player:distanceTo(p) == 1 then
						return "srcanshunshou"
					else
						return "srcanguohe"
					end
				end
			end
		else
			if self:isWeak(p) then
				e = e + 1
			end
		end
	end
	if f>e and f >=2 then return "srcantaoyuan" end
	if self.player:getHandcardNum() < self.player:getHp() then return "srcanwuzhong" end
	for _,p in ipairs(self.friends) do
		if p:isChained() then
			return "srcantiesuo"
		end
	end
	local canaoe = true
	for _,p in ipairs(self.friends) do		
		if self:isWeak(p) then
			canaoe = false
			break
		end

	end
	if canaoe then
		if self.player:getRole() == "rebel" then
			return "srcanwanjian" 
		else
			return "srcannanman"
		end
	end
	
	for _,p in ipairs(self.enemies) do
		local duel = sgs.Sanguosha:cloneCard("duel",sgs.Card_NoSuit,0)
		if p:getHandcardNum()<=1 and not self.player:isProhibited(p,duel) then
			return "srcanjuedou"
		end
		if not p:isKongcheng() and self.player:getHandcardNum() >=3 then
			return "srcanhuogong"
		end
		if p:getEquip(0) then
			for _,q in ipairs(self.enemies) do
				if p:canSlash(q,true) and p:objectName() ~= q:objectName() then
					return "srcanjiedao"
				end
			end
		end
	end
	return choices[math.random(1, #choices)]
end

sgs.ai_skill_playerchosen["sr_xionglvetiesuo"] = function(self, targets)
	local friends = {}
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:isChained() then
			table.insert(friends,p)
		end
		if self:isEnemy(p) and not p:isChained() then
			table.insert(enemies,p)
		end
	end
	if #friends == 0 and #enemies == 0 then return nil end 
	if #friends == 0 then return enemies[1] end	
	return friends[1]
end

sgs.ai_skill_playerchosen["sr_xionglvejiedao"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	self:sort(enemies,"defense")	
	return enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglvejiedao1"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	self:sort(enemies,"defense")	
	return enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglvehuogong"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
			if p:getEquip(1) and p:getEquip(1):isKindOf("Vine") then return p end
		end
	end
	if #enemies == 0 then return nil end
	self:sort(enemies,"defense")	
	return enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglveshunshou"] = function(self, targets)	
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and (p:getJudgingArea():length()>0 or hasOnlySilverLionEffect(p))then
			return p
		end
		if self:isEnemy(p) and not hasOnlySilverLionEffect(p) then
			return p
		end
	end
	self:sort(self.enemies,"defense")
	return self.enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglveguohe"] = function(self, targets)	
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and (p:getJudgingArea():length()>0 or hasOnlySilverLionEffect(p))then
			return p
		end
		if self:isEnemy(p) and not hasOnlySilverLionEffect(p) then
			return p
		end
	end
	self:sort(self.enemies,"defense")
	return self.enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglvejuedou"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)			
		end
	end
	if #enemies == 0 then return nil end
	self:sort(enemies,"defense")	
	return enemies[1]
end

sgs.ai_skill_playerchosen["sr_xionglveequip"] = function(self, targets)
	local friends = {}	
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end		
	end
	if #friends == 0 then return nil end 
	self:sort(self.friends,"defense")		
	return friends[1]
end

sgs.ai_skill_invoke["sr_xionglve"] = function(self,data)
	return self.player:getPile("@srlve"):length()<=3 and not self.player:isKongcheng()
end

sgs.ai_skill_askforag["sr_xionglve"] =function(self, card_ids)
	local card1 = sgs.Sanguosha:getCard(card_ids[1])
	--local card2 = sgs.Sanguosha:getCard(card_ids[2])
	if self.player:isWounded() then
		if card1:isKindOf("BasicCard") then
			return card_ids[2]
		else
			return card_ids[1]
		end
	else
		if card1:isKindOf("TrickCard") then
			return card_ids[2]
		else
			return card_ids[1]
		end
	end
end
--辅政
sgs.ai_skill_use["@@sr_fuzheng"] = function(self, prompt)	
	self:sort(self.friends_noself,"defense")
	local first,second = nil,nil
	for _,p in ipairs(self.friends_noself) do
		if not p:isKongcheng() and p:getKingdom() == "wu" then
			if not first then
				first = p
			else
				second = p
				break
			end			
		end
	end
	if not first and not second then return "." end
	if not second then
		return "#sr_fuzhengcard:.:->"..first:objectName()
	else
		return "#sr_fuzhengcard:.:->"..first:objectName().."+"..second:objectName()
	end
end

function suitCards(player,suits,include_equip)--返回角色的某种花色的所有牌，不同花色用逗号相隔
	local hearts = {}
	local flag = "h"
	if include_equip then
		flag = flag.."e"
	end
	for _,c in sgs.qlist(player:getCards(flag)) do
		for _,suit in ipairs(suits:split(",")) do 
			if c:getSuitString() == suit then
				table.insert(hearts,c)
			end
		end
	end
	return hearts
end

function reverse(tables)
	local new_table = {}
	for i = #tables,1,-1 do
		table.insert(new_table,tables[i])
	end
end

sgs.ai_skill_discard["sr_fuzheng1"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		local delay = sgs.QList2Table(current:getJudgingArea())
		reverse(delay)
		if #delay>0 then
			if self.room:getTag("fuzheng_num"):toInt() == 2 then
				table.removeOne(delay,delay[1])
			end
			for _, c in ipairs(delay) do
				if c:isKindOf("Indulgence") then
					local cards = suitCards(self.player,"heart",false)
					if #cards > 0 then
						self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				elseif c:isKindOf("SupplyShortage") then
					local cards = suitCards(self.player,"club",false)
					if #cards > 0 then
						self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				elseif c:isKindOf("Lightning") then
					for _,c in sgs.qlist(self.player:getHandcards()) do
						local cards ={}
						if not (c:getNumber()>=2 and c:getNumber()<=9 and c:getSuit() == sgs.Card_Spade) then
							table.insert(cards,c)
						end
					end
					if #cards > 0 then
						self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				end
			end
		end
		if self:isWeak(current) then
			for _,c in sgs.qlist(self.player:getHandcards()) do
				if c:isKindOf("Peach") then
					table.insert(to_discard,c:getId())
					return to_discard
				end
			end
		end
		local handcards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(handcards)
		table.insert(to_discard,handcards[1]:getId())
		return to_discard
	end
	local handcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(handcards)
	table.insert(to_discard,handcards[1]:getId())
	return to_discard
end

sgs.ai_skill_discard["sr_fuzheng2"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		local delay = sgs.QList2Table(current:getJudgingArea())
		reverse(delay)
		if #delay>0 then			
			for _, c in ipairs(delay) do
				if c:isKindOf("Indulgence") then
					local cards = suitCards(self.player,"heart",false)
					if #cards > 0 then
						self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				elseif c:isKindOf("SupplyShortage") then
					local cards = suitCards(self.player,"club",false)
					if #cards > 0 then
						self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				elseif c:isKindOf("Lightning") then
					for _,c in sgs.qlist(self.player:getHandcards()) do
						local cards ={}
						if not (c:getNumber()>=2 and c:getNumber()<=9 and c:getSuit() == sgs.Card_Spade) then
							table.insert(cards,c)
						end
					end
					if #cards > 0 then
						self:sortByKeepValue(cards)
						table.insert(to_discard,cards[1]:getId())
						return to_discard
					end
				end
			end
		end
		if self:isWeak(current) then
			for _,c in sgs.qlist(self.player:getHandcards()) do
				if c:isKindOf("Peach") then
					table.insert(to_discard,c:getId())
					return to_discard
				end
			end
		end
	end
	local handcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(handcards)
	table.insert(to_discard,handcards[1]:getId())
	return to_discard
end


--待劳
local sr_dailao_skill = {}
sr_dailao_skill.name = "sr_dailao"
table.insert(sgs.ai_skills, sr_dailao_skill)
sr_dailao_skill.getTurnUseCard = function(self, inclusive)	
	if self.player:hasUsed("#sr_dailaocard") then return nil end	
	local cando = false
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if p:faceUp() and self:isEnemy(p) then
			cando = true
			break
		elseif not p:faceUp() and self:isFriend(p) then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return sgs.Card_Parse("#sr_dailaocard:.:")	
end

sgs.ai_skill_use_func["#sr_dailaocard"] = function(card, use, self)	
	for _,p in ipairs(self.friends_noself) do
		if not p:faceUp() then
			use.card = card 
			if use.card and use.to then
				use.to:append(p)
				return
			end
		end
	end
	for _,p in ipairs(self.enemies) do
		if p:faceUp() then
			use.card = card 
			if use.card and use.to then
				use.to:append(p)
				return
			end
		end
	end
	return
end

sgs.ai_skill_choice["sr_dailao"] = function(self,choices,data)
	local per = nil
	for _ ,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("dailao_target") then
			self.room:setPlayerFlag(p,"-dailao_target")
			per = p
			break
		end
	end
	if self:isFriend(per) then
		if hasSilverLionEffect(per) then 
			return "srdiscard"
		else
			return "srdraw"
		end
	else 
		if hasSilverLionEffect(per) then
			return "srdraw"
		else
			return "srdiscard"
		end
	end
end

--诱敌
sgs.ai_skill_invoke["sr_youdi"] = function(self,data)
	return true
end
sgs.ai_skill_use["@@sr_youdi"] = function(self, prompt)
	if self.player:isKongcheng() then return "." end
	local per = nil
	for _ ,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("youdisource") then			
			per = p
			break
		end
	end
	if self:isFriend(per) and not hasSilverLionEffect(per) then return "." end
	if self:isEnemy(per) and hasSilverLionEffect(per) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if self:isFriend(per) then
		return "#sr_youdicard:"..cards[1]:getEffectiveId()..":"
	else
		local num = per:getHandcardNum()
		local discard = {}
		if num >= #cards then
			for _,c in sgs.qlist(self.player:getHandcards()) do
				table.insert(discard,c:getEffectiveId())
			end
		else
			for i = 1,num,1 do
				table.insert(discard,cards[i]:getEffectiveId())
			end
		end
		return "#sr_youdicard:"..table.concat(discard,"+")..":"
	end
	return "."		
end
--儒雅
sgs.ai_skill_invoke["sr_ruya"] = function(self,data)
	if self.player:hasSkill("sr_youdi") then return true end
	if self:isWeak() then return true end
	if self.player:getPhase() == sgs.Player_Play and self.player:hasSkill("sr_dailao") 
		and not self.player:hasUsed("#sr_dailaocard") then return true end
	return false
end

--伪报
function sortHandcards(self,typename,smallToBig)
	local cards = sgs.QList2Table(self.player:getHandcards())
	if smallToBig then
		if typename == "keep" then
			self:sortByKeepValue(cards)
		elseif typename == "use" then
			self:sortByUseValue(cards)
		elseif typename == "number" then			
			local final = {}
			while #final < self.player:getHandcardNum() do
				local min = cards[1]
				for _,c in ipairs(cards) do
					if c:getNumber() < min:getNumber() then
						min = c
					end
				end
				table.insert(final,min)
				table.removeOne(cards,min)
			end
			return final
		end
	else
		if typename == "keep" then
			self:sortByKeepValue(cards,false)
		elseif typename == "use" then
			self:sortByUseValue(cards,false)
		elseif typename == "number" then			
			local final = {}
			while #final < self.player:getHandcardNum() do
				local max = cards[1]
				for _,c in ipairs(cards) do
					if c:getNumber() > max:getNumber() then
						max = c
					end
				end
				table.insert(final,max)
				table.removeOne(cards,max)
			end
			return final
		end
	end
	return cards
end

function getPeachNum(player)
	if player:isKongcheng() then return 0 end
	local peach = 0
	for _, c in sgs.qlist(player:getHandcards()) do
		if c:isKindOf("Peach") or c:isKindOf("Analeptic") then
			peach = peach + 1
		end
	end
	return peach
end

local sr_weibao_skill = {}
sr_weibao_skill.name = "sr_weibao"
table.insert(sgs.ai_skills, sr_weibao_skill)
sr_weibao_skill.getTurnUseCard = function(self, inclusive)	
	if self.player:hasUsed("#sr_weibaocard") then return nil end
	if self.player:isKongcheng() then return nil end
	if #self.enemies == 0 then return nil end
	if getPeachNum(self.player) == self.player:getHandcardNum() then return nil end
	local cards = sortHandcards(self,"keep",true)
	return sgs.Card_Parse("#sr_weibaocard:"..cards[1]:getEffectiveId()..":")	
end

sgs.ai_skill_use_func["#sr_weibaocard"] = function(card, use, self)	
	use.card = card
end

sgs.ai_skill_playerchosen["sr_weibao"] = function(self,targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)			
		end
	end
	if #enemies == 0 then return nil end
	self:sort(enemies,"defense")	
	return enemies[1]
end
--筹略
local sr_choulve_skill = {}
sr_choulve_skill.name = "sr_choulve"
table.insert(sgs.ai_skills, sr_choulve_skill)
sr_choulve_skill.getTurnUseCard = function(self, inclusive)	
	if self.player:hasUsed("#sr_choulvecard") then return nil end
	if self.player:getHandcardNum()<2 then return nil end
	if #self.enemies + #self.friends_noself <2 then return nil end
	if self.room:getOtherPlayers(self.player):length()<2 then return nil end
	if getPeachNum(self.player) +2 >= self.player:getHandcardNum() then return nil end	
	return sgs.Card_Parse("#sr_choulvecard:.:")	
end

sgs.ai_skill_use_func["#sr_choulvecard"] = function(card, use, self)
	self:sort(self.enemies,"defense")
	if #self.friends_noself == 0 then
		if self.player:getHandcardNum() <= self.player:getHp() + 1 then return end
		use.card =	card
		if use.to then
			use.to:append(self.enemies[1])
			use.to:append(self.enemies[2])
			return
		end
	else
		self:sort(self.friends_noself,"defense")
		use.card = card 
		if use.to then
			use.to:append(self.friends_noself[1])
			use.to:append(self.enemies[1])
			return
		end
	end
	return
end
sgs.ai_skill_discard["sr_choulve1"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local current = self.room:getCurrent()	
	--if #self.friends_noself >0 then			
		local cards = sortHandcards(self,"number",false)
		table.insert(to_discard,cards[1]:getId())
		return to_discard
	--end	
end
sgs.ai_skill_discard["sr_choulve2"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local current = self.room:getCurrent()	
	--if #self.friends_noself >0 then			
		local cards = sortHandcards(self,"number",true)
		table.insert(to_discard,cards[1]:getId())
		return to_discard
	--end	
end

--誓学
sgs.ai_skill_invoke["sr_shixue"] = function(self,data)	
	-- local tos = data:toCardUse().to
	-- local cando = true
	-- for _,p in sgs.qlist(tos) do
	-- 	if p:getHandcardNum() >= 3 then
	-- 		cando = false
	-- 	end
	-- 	if p:getArmor() and p:getArmor():isKindOf("EightDiagram") then
	-- 		cando = false
	-- 	end
	-- end
	-- return cando
	return true
end
sgs.ai_cardneed.sr_shixue = sgs.ai_cardneed.slash


--国士
sgs.ai_skill_invoke["sr_guoshibegin"] = function(self,data)
	return true
end
sgs.ai_skill_invoke["sr_guoshiend"] = function(self,data)
	local current = self.room:getCurrent()
	if current and current:isAlive() and self:isFriend(current) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke["sr_guoshiend"] = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if current then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, current, -20)
		end
	end
end

--劫袭
function hasOnlyOneHandcardAndHasDelayTrick(player)
	return player:getHandcardNum() == 1 and player:getCards("e"):isEmpty() and player:getCards("j"):length()>0
end

local sr_jiexi_skill = {}
sr_jiexi_skill.name = "sr_jiexi"
table.insert(sgs.ai_skills, sr_jiexi_skill)
sr_jiexi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sr_jiexicard") or self.player:isKongcheng() or #self.enemies == 0 then return nil end
	local cando = false
	for _,p in ipairs(self.enemies) do
		if not hasOnlyOneHandcardAndHasDelayTrick(p) and not p:isKongcheng() and self.player:canPindian(p) then
			cando = true
			break
		end
	end
	if not cando then return nil end
	local cards = sortHandcards(self,"number",false)	
	return sgs.Card_Parse("#sr_jiexicard:"..cards[1]:getId()..":")	
end

sgs.ai_skill_use_func["#sr_jiexicard"] = function(card, use, self)
	local enemies = {}
	for _,p in ipairs(self.enemies) do
		if not hasOnlyOneHandcardAndHasDelayTrick(p) and not p:isKongcheng() and self.player:canPindian(p) then
			table.insert(enemies,p)
		end
	end 
	self:sort(enemies,"defense")
	use.card = card
	if use.to then
		use.to:append(enemies[1])
	end
	return
end

sgs.ai_use_value["sr_jiexicard"] = 5
sgs.ai_cardneed.sr_jiexi = sgs.ai_cardneed.bignumber

sgs.ai_skill_invoke["sr_jiexi"] = function(self,data)
	local target = data:toPlayer()
	return not hasOnlyOneHandcardAndHasDelayTrick(target) and self:isEnemy(target) and not target:isKongcheng()
end
--游侠
local sr_youxia_skill = {}
sr_youxia_skill.name = "sr_youxia"
table.insert(sgs.ai_skills, sr_youxia_skill)
sr_youxia_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:faceUp() then return nil end	
	local cando = false
	for _,p in ipairs(self.enemies) do
		if not p:isNude() then
			cando = true
			break
		end
	end
	if not cando then return nil end	
	return sgs.Card_Parse("#sr_youxiacard:.:")	
end

sgs.ai_skill_use_func["#sr_youxiacard"] = function(card, use, self)
	local enemies = {}
	for _,p in ipairs(self.enemies) do
		if not p:isNude() then
			table.insert(enemies,p)
		end
	end 
	if #enemies == 0 then return end
	if #enemies==1 and #self.friends_noself==0 then return end
	self:sort(enemies,"defense")	
	if #enemies==1 then
		use.card = card
		if use.to then
			use.to:append(enemies[1])
		end
		return
	else
		use.card = card
		if use.to then
			use.to:append(enemies[1])
			use.to:append(enemies[2])
		end
		return
	end
	return
end

sgs.ai_use_priority["sr_youxiacard"] = 6
sgs.ai_use_value["sr_youxiacard"] = 9

--舟焰
local sr_zhouyan_skill = {}
sr_zhouyan_skill.name = "sr_zhouyan"
table.insert(sgs.ai_skills, sr_zhouyan_skill)
sr_zhouyan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("srzhouyannotdo") then return nil end
	if self.player:getHandcardNum()<=2 then return nil end	
	local cando = false
	for _,p in ipairs(self.enemies) do
		if p:getHandcardNum()<=2 then
			cando = true
			break
		end
	end
	if not cando then return nil end	
	return sgs.Card_Parse("#sr_zhouyancard:.:")	
end

sgs.ai_skill_use_func["#sr_zhouyancard"] = function(card, use, self)
	local enemies = {}
	for _,p in ipairs(self.enemies) do
		if p:getHandcardNum()<=2 then
			table.insert(enemies,p)
		end
	end 
	if #enemies == 0 then return end	
	self:sort(enemies,"hp")	
	use.card = card
	if use.to then
		use.to:append(enemies[1])
	end
	return	
end

sgs.ai_use_value["sr_zhouyancard"] = 5

sgs.ai_skill_invoke["sr_zhouyan_draw"] = function(self,data)
	return true
end
sgs.ai_skill_invoke["sr_zhouyan"] = function(self,data)
	local damage= data:toDamage()
	return damage.to:getHandcardNum()<=2
end
--诈降
local sr_zhaxiang_skill = {}
sr_zhaxiang_skill.name = "sr_zhaxiang"
table.insert(sgs.ai_skills, sr_zhaxiang_skill)
sr_zhaxiang_skill.getTurnUseCard = function(self, inclusive)
	if self.player:isKongcheng() then return nil end	
	return sgs.Card_Parse("#sr_zhaxiangcard:.:")	
end

sgs.ai_skill_use_func["#sr_zhaxiangcard"] = function(card, use, self)
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("Slash") then
			if #self.enemies>0 then
				self:sort(self.enemies,"defense")
				use.card = sgs.Card_Parse("#sr_zhaxiangcard:"..c:getEffectiveId()..":")				
				return
			end
		end
	end
	if #self.friends_noself>0 then
		self:sort(self.friends_noself,"defense")
		local cards = sortHandcards(self,"keep",false)
		use.card = sgs.Card_Parse("#sr_zhaxiangcard:"..cards[1]:getEffectiveId()..":")		
		return
	end
	return
end

sgs.ai_use_value["sr_zhaxiangcard"] = 5
sgs.ai_skill_playerchosen["sr_zhaxiang"] = function(self, targets)
	local tag = self.room:getTag("zhaxiang"):toString()
	if tag == "slash" or tag == "Slash" then
		local enemies = {}
		for _,p in sgs.qlist(targets) do
			if not self:isFriend(p) then
				table.insert(enemies,p)
			end
		end
		if #enemies == 0 then return nil end
		self:sort(enemies,"defense")	
		return enemies[1]
	else
		local friends = {}
		for _,p in sgs.qlist(targets) do
			if self:isFriend(p) then
				table.insert(friends,p)
			end
		end
		if #friends == 0 then return nil end
		self:sort(friends,"defense")	
		return friends[1]
	end
end

sgs.ai_skill_choice["sr_zhaxiang"] = function(self, choices, data)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		return "srshow"
	else
		if not self:isWeak() then 
			return "srshow"
		end
	end
	return "srgive"
end

sgs.ai_skill_discard["sr_zhaxiang"] = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	if self.player:getCards("e"):length()>0 then
		table.insert(to_discard,self.player:getCards("e"):first():getId())
	else
		local cards = sortHandcards(self,"keep",true)
		table.insert(to_discard,cards[1]:getId())
	end
	return to_discard
end

--芳馨
local sr_fangxin_skill = {}
sr_fangxin_skill.name = "sr_fangxin"
table.insert(sgs.ai_skills, sr_fangxin_skill)
sr_fangxin_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:isWounded() then return nil end
	local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,0)
	indulgence:deleteLater()
	local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,0)
	supply_shortage:deleteLater()
	if  (self.player:isProhibited(self.player,indulgence) or self.player:containsTrick("indulgence")) and 
	(self.player:isProhibited(self.player,supply_shortage) or self.player:containsTrick("supply_shortage")) then 
		return nil
	elseif  (self.player:isProhibited(self.player,supply_shortage) or 
		self.player:containsTrick("supply_shortage")) then
		local cards = suitCards(self.player,"diamond",true) 
		if #cards == 0 then return nil end
		self:sortByKeepValue(cards)
		return sgs.Card_Parse("#sr_fangxincard:"..cards[1]:getEffectiveId()..":")
	elseif  (self.player:isProhibited(self.player,indulgence) or self.player:containsTrick("indulgence")) then
		local cards = suitCards(self.player,"club",true) 
		if #cards == 0 then return nil end
		self:sortByKeepValue(cards)
		return sgs.Card_Parse("#sr_fangxincard:"..cards[1]:getEffectiveId()..":")
	else
		local cards = suitCards(self.player,"club,diamond",true) 
		if #cards == 0 then return nil end
		self:sortByKeepValue(cards)
		return sgs.Card_Parse("#sr_fangxincard:"..cards[1]:getEffectiveId()..":")
	end
	return nil
end

sgs.ai_skill_use_func["#sr_fangxincard"] = function(card, use, self)
	use.card = card
end

sgs.ai_cardsview_valuable["sr_fangxin"] = function(self, class_name,player)
	if class_name ~= "Peach" or not player:hasSkill("sr_fangxin") then return end
	local dying = player:getRoom():getCurrentDyingPlayer()
	if not dying then return  end
	if player:hasFlag("Global_PreventPeach") then return end
	local indulgence = sgs.Sanguosha:cloneCard("indulgence",sgs.Card_Diamond,0)
	indulgence:deleteLater()
	local supply_shortage = sgs.Sanguosha:cloneCard("supply_shortage",sgs.Card_Club,0)
	supply_shortage:deleteLater()
	if  (player:isProhibited(player,indulgence) or player:containsTrick("indulgence")) and 
	(player:isProhibited(player,supply_shortage) or player:containsTrick("supply_shortage")) then 
		return 
	elseif  (player:isProhibited(player,supply_shortage) or player:containsTrick("supply_shortage")) then
		local cards = suitCards(player,"diamond",true) 
		if #cards == 0 then return end
		self:sortByKeepValue(cards)
		return "#sr_fangxincard:"..cards[1]:getEffectiveId()..":"
	elseif  (player:isProhibited(player,indulgence) or player:containsTrick("indulgence")) then
		local cards = suitCards(player,"club",true) 
		if #cards == 0 then return end
		self:sortByKeepValue(cards)
		return "#sr_fangxincard:"..cards[1]:getEffectiveId()..":"
	else
		local cards = suitCards(player,"club,diamond",true) 
		if #cards == 0 then return end
		self:sortByKeepValue(cards)
		return "#sr_fangxincard:"..cards[1]:getEffectiveId()..":"
	end
	return
end

sgs.ai_card_intention["#sr_fangxincard"] = sgs.ai_card_intention.Peach

sgs.ai_use_priority["#sr_fangxincard"] = sgs.ai_use_priority.Peach

--细语
sgs.ai_skill_invoke["sr_xiyu"] = function(self,data)
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if self:isFriend(p) and p:getHandcardNum()>=3 then
			return true
		end
		if self:isEnemy(p) and p:getHandcardNum()<=2 then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen["sr_xiyu"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and p:getHandcardNum() >=3 then
			table.insert(friends,p)
		end
	end
	if #friends > 0 then 
		self:sort(friends,"defense")	
		return friends[1]
	end
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) and p:getHandcardNum()<=2 then
			table.insert(enemies,p)
		end
	end
	if #enemies>0 then 
		self:sort(enemies,"defense")	
		return enemies[1]
	end
	return targets:first()
end


--婉柔
sgs.ai_skill_invoke["sr_wanrou"] = true

sgs.ai_skill_playerchosen["sr_wanrou"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	if #friends > 0 then 
		self:sort(friends,"defense")	
		return friends[1]
	end	
end

sgs.ai_playerchosen_intention.sr_wanrou = -50
--姻盟
local sr_yinmeng_skill = {}
sr_yinmeng_skill.name = "sr_yinmeng"
table.insert(sgs.ai_skills, sr_yinmeng_skill)
sr_yinmeng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:usedTimes("#sr_yinmengcard") >= math.max(self.player:getLostHp(),1) 
		or self.player:isKongcheng() then return nil end
	local cando = false
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:isMale() and not p:isKongcheng() then
			cando = true
			break
		end
	end
	if not cando then return nil end	
	return sgs.Card_Parse("#sr_yinmengcard:.:")	
end

sgs.ai_skill_use_func["#sr_yinmengcard"] = function(card, use, self)
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:isMale() and not p:isKongcheng() then
			if self:isFriend(p) then
				if self.player:getHandcardNum()>=3 then
					use.card = card
					if use.to then
						use.to:append(p)
						return
					end
				end
			else
				use.card = card
				if use.to then
					use.to:append(p)
					return
				end
			end
		end
	end 
	return
end

sgs.ai_cardshow["sr_yinmeng"] = function(self, requestor)
	local cards = self.player:getCards("h")
	local target = nil 
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("yinmengname") then
			target = p
			break
		end
	end
	local id = self.room:getTag("yinmengid"):toInt()
	local card = sgs.Sanguosha:getCard(id)
	for _,c in sgs.qlist(cards) do
		if self:isFriend(target) then
			if c:getTypeId() == card:getTypeId() then
				return c
			end
		else
			if c:getTypeId() ~= card:getTypeId() then
				return c
			end
		end
	end
	return cards:first()
end
sgs.ai_cardneed.sr_xiwu = sgs.ai_cardneed.slash

--决裂
local sr_juelie_skill = {}
sr_juelie_skill.name = "sr_juelie"
table.insert(sgs.ai_skills, sr_juelie_skill)
sr_juelie_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sr_jueliecard") then return nil end
	local cando = false
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getHandcardNum() ~= self.player:getHandcardNum() then
			cando = true
			break
		end
	end
	if not cando then return nil end	
	return sgs.Card_Parse("#sr_jueliecard:.:")	
end

sgs.ai_skill_use_func["#sr_jueliecard"] = function(card, use, self)
	local friends = {}
	local enemies = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getHandcardNum() < self.player:getHandcardNum() then
			if self:isFriend(p) then
				table.insert(friends,p)			
			end
		end
		if p:getHandcardNum() > self.player:getHandcardNum() then
			if self:isEnemy(p) then
				table.insert(enemies,p)			
			end
		end
	end 
	if #friends>0 then
		self:sort(friends,"defense")
		use.card = card 
		if use.to then
			use.to:append(friends[1])
		end
		return
	end
	if #enemies>0 then
		self:sort(enemies,"defense")
		use.card = card 
		if use.to then
			use.to:append(enemies[1])
		end
		return
	end
	return
end

sgs.ai_skill_choice["sr_juelie"] = function(self, choices, data)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		return "srkeepsame"
	else
		if not self:isWeak() then 
			return "srslash"
		end
	end
	return "srkeepsame"
end

sgs.ai_use_priority["sr_jueliecard"] = sgs.ai_use_priority.ExNihilo - 0.1

--招降
sgs.ai_skill_invoke["sr_zhaoxiang"] = function(self,data)
	local use = data:toCardUse()
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardask["srzhaoxiangdiscard"] = function(self, data, pattern, target, target2)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return "." end
	self:sortByKeepValue(cards)
	return "$"..cards[1]:getEffectiveId()
end

sgs.ai_skill_choice["sr_zhaoxiang"] = function(self, choices, data)
	local use = data:toCardUse()
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			return "srzhaoxiangslashnullified"
		else
			return "srzhaoxianggetcard"
		end
	end	
end
--治世
function needDamaged(self,player)
	local need = false
	if player:getHp() > getBestHp(player) then need = true end
	if not need and not self:isGoodTarget(player, self.friends, nil) then need = true end
	if not need then
		for _, skill in sgs.qlist(player:getVisibleSkillList()) do
			local callback = sgs.ai_need_damaged[skill:objectName()]
			if type(callback) == "function" and callback(self, nil, player) then
				need = true
				break
			end
		end
	end
	return need
end
local sr_zhishi_skill = {}
sr_zhishi_skill.name = "sr_zhishi"
table.insert(sgs.ai_skills, sr_zhishi_skill)
sr_zhishi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sr_zhishicard") then return nil end
	local cando = false	
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		--if self:isFriend(p) and needDamaged(self,p) then
		if self:isFriend(p) and self:needToLoseHp(p, self.player) then
			cando = true
			break
		end	
		if self:isEnemy(p) and p:getHp()<=1 and not (p:hasSkill("buqu") or p:hasSkill("nosbuqu")) 
			and p:isKongcheng() then
			cando = true
			break
		end		 
	end
	if not cando then return nil end	
	return sgs.Card_Parse("#sr_zhishicard:.:")	
end

sgs.ai_skill_use_func["#sr_zhishicard"] = function(card, use, self)
	local friends = {}
	local enemies = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and p:getHp()<=1 and not (p:hasSkill("buqu") or p:hasSkill("nosbuqu")) 
			and p:isKongcheng() then
			table.insert(enemies,p)
		end	
		if self:isFriend(p) and needDamaged(self,p) then
			table.insert(friends,p)
		end	
	end 	
	if #enemies>0 then
		self:sort(enemies,"defense")
		use.card = card 
		if use.to then
			use.to:append(enemies[1])
		end
		return
	end
	if #friends>0 then
		self:sort(friends,"defense",false)
		use.card = card 
		if use.to then
			use.to:append(friends[1])
		end
		return
	end
	return
end
sgs.ai_skill_cardask["#srbasic"] = function(self, data, pattern, target, target2)
	if needDamaged(self,self.player) then return "." end
	local cards = {}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("BasicCard") then
			table.insert(cards,c)
		end
	end
	if #cards == 0 then return "." end
	self:sortByKeepValue(cards)	
	return "$"..cards[1]:getEffectiveId()
end
--奸雄
sgs.ai_skill_playerchosen["sr_jianxiong"] = function(self, targets)
	if self:isWeak() then return nil end
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	if #friends == 0 then return nil end
	self:sort(friends,"defense")	
	return friends[1]
end
sgs.ai_playerchosen_intention.sr_jianxiong = -50

--天殇
sgs.ai_skill_invoke["sr_tianshang"] = function(self,data)
	if #self.friends_noself > 0 then return true end
	return false
end
sgs.ai_skill_playerchosen["sr_tianshang"] = function(self, targets)	
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	if #friends == 0 then return nil end
	self:sort(friends,"defense")	
	return friends[1]
end
sgs.ai_skill_choice["sr_tianshang"] = function(self, choices, data)
	local choices1 = choices:split("+")
	return choices1[math.random(1, #choices1 - 1)]	
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|sr_tianshang"
--遗计
sgs.ai_skill_invoke.sr_yiji = function(self)
	local Shenfen_user
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	if self.player:getHandcardNum() < 2 then return true end
	local invoke
	for _, friend in ipairs(self.friends) do
		if not (friend:hasSkill("manjuan") and friend:getPhase() == sgs.Player_NotActive) and 
			not self:needKongcheng(friend, true) and not self:isLihunTarget(friend) and 
			(not Shenfen_user or Shenfen_user:objectName() == friend:objectName() or 
				friend:getHandcardNum() >= 4) then
				invoke = true
			break
		end
	end
	return invoke
end

sgs.ai_skill_askforyiji.sr_yiji = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	
	local Shenfen_user
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	
	if Shenfen_user then
		if self:isFriend(Shenfen_user) then
			if Shenfen_user:objectName() ~= self.player:objectName() then
				for _, id in ipairs(card_ids) do
					return Shenfen_user, id
				end
			else
				return nil, -1
			end
		else
			if self.player:getHandcardNum() < self:getOverflow(false, true) then
				return nil, -1
			end
			local card, friend = self:getCardNeedPlayer(cards)
			if card and friend and friend:getHandcardNum() >= 4 then
				return friend, card:getId()
			end
		end
	end
	
	if self.player:getHandcardNum() <= 2 and not Shenfen_user then
		return nil, -1
	end
			
	local new_friends = {}
	local CanKeep
	for _, friend in ipairs(self.friends) do
		if not (friend:hasSkill("manjuan") and friend:getPhase() == sgs.Player_NotActive) and 
		not self:needKongcheng(friend, true) and not self:isLihunTarget(friend) and 
		(not Shenfen_user or friend:objectName() == Shenfen_user:objectName() or friend:getHandcardNum() >= 4) then
			if friend:objectName() == self.player:objectName() then CanKeep = true
			else 
				table.insert(new_friends, friend)
			end
		end
	end

	if #new_friends > 0 then
		local card, target = self:getCardNeedPlayer(cards)
		if card and target then
			for _, friend in ipairs(new_friends) do
				if target:objectName() == friend:objectName() then
					return friend, card:getEffectiveId()
				end
			end
		end
		if Shenfen_user and self:isFriend(Shenfen_user) then
			return Shenfen_user, cards[1]:getEffectiveId()
		end
		self:sort(new_friends, "defense")
		self:sortByKeepValue(cards, true)
		return new_friends[1], cards[1]:getEffectiveId()
	elseif CanKeep then
		return nil, -1
	else
		local other = {}
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not (self:isLihunTarget(player) and self:isFriend(player)) and (self:isFriend(player) or 
				not player:hasSkill("lihun")) then
				table.insert(other, player)
			end
		end
		return other[math.random(1, #other)], card_ids[math.random(1, #card_ids)]
	end

end

sgs.ai_need_damaged.sr_yiji = function (self, attacker, player)
	if not player:hasSkill("sr_yiji") then return end
	local need_card = false
	local current = self.room:getCurrent()
	if self:hasCrossbowEffect(current) or current:hasSkill("paoxiao") or current:hasFlag("shuangxiong") then 
		need_card = true 
	end
	if self:hasSkills("jieyin|jijiu",current) and self:getOverflow(current) <= 0 then need_card = true end
	if self:isFriend(current, player) and need_card then return true end
	
	local friends = {}
	for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isFriend(ap, player) then
			table.insert(friends, ap)
		end
	end
	self:sort(friends, "hp")

	if #friends > 0 and friends[1]:objectName() == player:objectName() and self:isWeak(player) and 
	getCardsNum("Peach", player, (attacker or self.player)) == 0 then return false end
	if #friends > 1 and self:isWeak(friends[2]) then return true end	
	
	return player:getHp() > 2 and sgs.turncount > 2 and #friends > 1
end

sgs.ai_chaofeng.sr_guojia = -4
--慧觑
sgs.ai_skill_invoke["sr_huiqu"] = function(self,data)
	return self.player:getHandcardNum()>=2
end
sgs.ai_skill_playerchosen["sr_huiqudamage"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return nil end
	self:sort(enemies,"defense")	
	return enemies[1]
end
local function card_for_qiaobian(self, who, return_prompt)
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) then
							target = enemy
							break
						end
					end
					if target then break end
				end
			end
		end

		local equips = who:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who) then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip break
				elseif equip:isKindOf("Weapon") then card = equip break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then 
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() 
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
							target = friend
							break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end
		end
	else
		local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					card = sgs.Sanguosha:getCard(judge:getEffectiveId())
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and 
						not self.room:isProhibited(self.player, friend, judge) 
							and not friend:getJudgingArea():isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and 
						not self.room:isProhibited(self.player, friend, judge) then
							target = friend
							break
						end
					end
					if target then break end
				end
			end
		end
		if card==nil or target==nil then
			if not who:hasEquip() or self:hasSkills(sgs.lose_equip_skill, who) then return nil end
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(sgs.Sanguosha:getCard(card_id)) then 
				card = sgs.Sanguosha:getCard(card_id) end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then 
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and 
					self:hasSkills(sgs.lose_equip_skill .. "|shensu" , friend) then
						target = friend
						break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() then
						target = friend
						break
					end
				end
			end			
		end
	end

	if return_prompt == "card" then return card
	elseif return_prompt == "target" then return target
	else
		return (card and target)
	end
end

sgs.ai_skill_cardchosen["sr_huiqu"] = function(self, who, flags)
	if flags == "ej" then
		return card_for_qiaobian(self, who, "card")
	end
end

sgs.ai_skill_playerchosen["sr_huiqufirst"] = function(self, targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if not self:isFriend(p) then
			table.insert(enemies,p)
		end
	end
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			table.insert(friends,p)
		end
	end
	self:sort(enemies, "defense")
	for _, friend in ipairs(friends) do
		if not friend:getCards("j"):isEmpty() and not friend:containsTrick("YanxiaoCard") and 
		card_for_qiaobian(self, friend, ".") then			
			return friend
		end
	end
	
	for _, enemy in ipairs(enemies) do
		if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard") and 
			card_for_qiaobian(self, enemy, ".") then
			-- return "@QiaobianCard=" .. card:getEffectiveId() .."->".. friend:objectName()
			return enemy
		end
	end

	for _, friend in ipairs(friends) do
		if not friend:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill, friend) and 
		card_for_qiaobian(self, friend, ".") then
			return friend
		end
	end

	local targets = {}
	for _, enemy in ipairs(enemies) do
		if card_for_qiaobian(self, enemy, ".") then
			table.insert(targets, enemy)
		end
	end
	
	if #targets > 0 then
		self:sort(targets, "defense")
		-- return "@QiaobianCard=" .. card:getEffectiveId() .."->".. targets[#targets]:objectName()
		return targets[#targets]
	end
end

sgs.ai_skill_playerchosen["sr_huiqu"] = function(self, targets)
	local who = self.room:getTag("huiquTarget"):toPlayer()
	if who then
		if not card_for_qiaobian(self, who, "target") then self.room:writeToConsole("NULL") end
		return card_for_qiaobian(self, who, "target")
	end
end

--鏖战
local sr_aozhan_skill = {}
sr_aozhan_skill.name = "sr_aozhan"
table.insert(sgs.ai_skills, sr_aozhan_skill)
sr_aozhan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sr_aozhanCard") then return nil end
	if self.player:getPile("@srzhan"):length() == 0 then return nil end	
	if self.player:getHandcardNum()>(self.player:getHp()+2) then return nil end	
	local card = sgs.Card_Parse("#sr_aozhanCard:.:")
	if not card then return nil end
	return card	
end

sgs.ai_skill_use_func["#sr_aozhanCard"] = function(card, use, self)	
	use.card = card
end


sgs.ai_use_value.sr_aozhanCard = 7

sgs.ai_skill_invoke.sr_aozhan = function(self,data)
	return true
end

sgs.ai_skill_choice["sr_aozhan"] = function(self, choices, data)
	local ids = self.player:getPile("@srzhan")
	for _,id in sgs.qlist(ids) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("ExNihilo") or (card:isKindOf("Peach") and self.player:isWounded()) then
			return "sraozhanget"
		end
	end
	return "sraozhandraw"
end
sgs.ai_cardneed.sr_aozhan = sgs.ai_cardneed.luoyi

--虎啸
sgs.ai_skill_invoke["sr_huxiao"] = function(self,data)
	local damage = data:toDamage()
	return self:isEnemy(damage.to) and not (self:isWeak() and self.player:faceUp())	
end
sgs.ai_ajustdamage_from.sr_huxiao = function(self, from, to, card, nature)
	if (card and card:isKindOf("Slash")) and not beFriend(to, from) and from:getPhase() == sgs.Player_Play and from:faceUp()
	then
		return 1
	end
end
sgs.ai_cardneed.sr_huxiao = sgs.ai_cardneed.slash

--鬼才
sgs.ai_skill_invoke["sr_guicai"] = function(self,data)
	local judge = data:toJudge()
	if judge:isGood() and self:isEnemy(judge.who) then return true end
	if judge:isBad() and self:isFriend(judge.who) then return true end
	return false
end
sgs.ai_skill_choice["sr_guicai"] = function(self, choices, data)
	local judge = data:toJudge()
	local who = judge.who
	local reason = judge.reason
	local card = judge.card
	if reason == "indulgence" and self:isFriend(who) and card:getSuit() ~= sgs.Card_Heart then
		local cards = suitCards(self.player,"heart",false)
		if #cards>0 then return "srguicaidachu" end
	end
	if reason == "supply_shortage" and self:isFriend(who) and card:getSuit() ~= sgs.Card_Club then
		local cards = suitCards(self.player,"club",false)
		if #cards>0 then return "srguicaidachu" end
	end
	if reason == "lightning" and self:isFriend(who) and card:getNumber()>=2 and card:getNumber()<=9 
		and card:getSuit()==sgs.Card_Spade then
		for _,c in sgs.qlist(self.player:getHandcards()) do
			if not(card:getNumber()>=2 and card:getNumber()<=9 and card:getSuit()==sgs.Card_Spade) then
				return "srguicaidachu"
			end
		end
	end
	return "srguicailiangchu"
end
sgs.ai_skill_cardask["@guicai-card"]=function(self, data)
	local judge = data:toJudge()

	if self.room:getMode():find("_mini_46") and not judge:isGood() then 
		return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getHandcards())
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end

	return "."
end
sgs.wizard_skill = sgs.wizard_skill .. "|sr_guicai"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|sr_guicai"
--狼顾
sgs.ai_skill_invoke["sr_langgu"] = function(self,data)
	local damage = data:toDamage()
	if damage.to:objectName() == self.player:objectName() then
		return self:isEnemy(damage.from)
	end
	if damage.from:objectName() == self.player:objectName() then
		return self:isEnemy(damage.to)
	end
	return true
end
--追尊
sgs.ai_skill_invoke["sr_zhuizun"] = function(self,data)
	local peaches = 1 - self.player:getHp()
	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
end

sgs.ai_canNiepan_skill.sr_zhuizun = function(player)
	return player:getMark("@zhuizun") > 0
end

--流云
local sr_liuyun_skill = {}
sr_liuyun_skill.name = "sr_liuyun"
table.insert(sgs.ai_skills, sr_liuyun_skill)
sr_liuyun_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sr_liuyuncard") then return nil end
	if self.player:isChained() then return nil end
	local cards = suitCards(self.player,"spade,club",true)
	if #cards == 0 then return nil end
	self:sortByKeepValue(cards)			
	return sgs.Card_Parse("#sr_liuyuncard:"..cards[1]:getEffectiveId()..":")	
end

sgs.ai_skill_use_func["#sr_liuyuncard"] = function(card, use, self)
	self:sort(self.friends,"defense")
	use.card = card
	if use.to then
		use.to:append(self.friends[1])
	end
	return
end
sgs.ai_card_intention["sr_liuyuncard"] = -80

sgs.ai_skill_choice["sr_liuyun"] = function(self,choices,data)
	if self.player:isWounded() then
		local hp = self.player:getHp()
		local count = self.player:getHandcardNum()
		if hp >= count + 2 then
			return "srliuyundrawcard"
		else
			return "srliuyunrecover"
		end
	end
	return "srliuyundrawcard"
end
--凌波
function enemyChainedWithUs(self,enemy)
	if enemy:isChained() then 
		for _,p in ipairs(self.friends) do
			return p:isChained()
		end
	end
	return false
end
sgs.ai_skill_invoke["sr_lingbo"] = function(self,data)
	local current = self.room:getCurrent()
	if not current or current:isDead() then return false end
	if self:isFriend(current) then
		local delay = sgs.QList2Table(current:getJudgingArea())
		if #delay > 0 then
			reverse(delay)
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if not p:getCards("ej"):isEmpty() then
					for _,c in sgs.qlist(p:getCards("ej")) do
						if delay[1]:isKindOf("Indulgence") and c:getSuit() == sgs.Card_Heart then
							local q1,q2 = sgs.QVariant(),sgs.QVariant()
							q1:setValue(c:getId())
							q2:setValue(p)
							self.room:setTag("lingbocard",q1)
							self.room:setTag("lingboperson",q2)
							return true
						end
						if delay[1]:isKindOf("SupplyShortage") and c:getSuit() == sgs.Card_Club then
							local q1,q2 = sgs.QVariant(),sgs.QVariant()
							q1:setValue(c:getId())
							q2:setValue(p)
							self.room:setTag("lingbocard",q1)
							self.room:setTag("lingboperson",q2)
							return true
						end
						if delay[1]:isKindOf("Lightning") and not (c:getSuit() == sgs.Card_Spade and 
							c:getNumber()<=9 and c:getNumber() >=2) then
							local q1,q2 = sgs.QVariant(),sgs.QVariant()
							q1:setValue(c:getId())
							q2:setValue(p)
							self.room:setTag("lingbocard",q1)
							self.room:setTag("lingboperson",q2)
							return true
						end
					end
				end
			end
		end
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) and not p:getCards("j"):isEmpty() then
				for _,c in sgs.qlist(p:getCards("j")) do
					local q1,q2 = sgs.QVariant(),sgs.QVariant()
					q1:setValue(c:getId())
					q2:setValue(p)
					self.room:setTag("lingbocard",q1)
					self.room:setTag("lingboperson",q2)
					return true
				end
			end
		end
		for _,p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) and not p:getCards("e"):isEmpty() and self:doDisCard(p, "e") then
				for _,c in sgs.qlist(p:getCards("e")) do
					local q1,q2 = sgs.QVariant(),sgs.QVariant()
					q1:setValue(c:getId())
					q2:setValue(p)
					self.room:setTag("lingbocard",q1)
					self.room:setTag("lingboperson",q2)
					return true
				end
			end
		end
	else
		local delay = sgs.QList2Table(current:getJudgingArea())
		if #delay > 0 then
			reverse(delay)
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if not p:getCards("ej"):isEmpty() then
					for _,c in sgs.qlist(p:getCards("ej")) do
						if delay[1]:isKindOf("Indulgence") and c:getSuit() ~= sgs.Card_Heart and delay[1] ~= c then
							local q1,q2 = sgs.QVariant(),sgs.QVariant()
							q1:setValue(c:getId())
							q2:setValue(p)
							self.room:setTag("lingbocard",q1)
							self.room:setTag("lingboperson",q2)
							return true
						end
						if delay[1]:isKindOf("SupplyShortage") and c:getSuit() ~= sgs.Card_Club  and delay[1] ~= c  then
							local q1,q2 = sgs.QVariant(),sgs.QVariant()
							q1:setValue(c:getId())
							q2:setValue(p)
							self.room:setTag("lingbocard",q1)
							self.room:setTag("lingboperson",q2)
							return true
						end
						if delay[1]:isKindOf("Lightning") and (c:getSuit() == sgs.Card_Spade and delay[1] ~= c  and 
							c:getNumber()<=9 and c:getNumber() >=2) and not enemyChainedWithUs(self,p) then
							local q1,q2 = sgs.QVariant(),sgs.QVariant()
							q1:setValue(c:getId())
							q2:setValue(p)
							self.room:setTag("lingbocard",q1)
							self.room:setTag("lingboperson",q2)
							return true
						end
					end
				end
			end
		end
	end
	return false
end

sgs.ai_skill_playerchosen["sr_lingbo"] = function(self,targets)
	local per = self.room:getTag("lingboperson"):toPlayer()
	if per then	return per end
	return targets:first()
end
sgs.ai_skill_cardchosen["sr_lingbo"] = function(self,who,flags)
	local id = self.room:getTag("lingbocard"):toInt()
	--local card = sgs.Sanguosha:getCard(id)
	if flags == "ej" then
		for _,c in sgs.qlist(who:getCards(flags)) do
			if c:getId() == id then
				return c
			end
		end
	end
	return who:getCards(flags):first()
end
--倾城
local sr_qingcheng_skill={}
sr_qingcheng_skill.name="sr_qingcheng"
table.insert(sgs.ai_skills,sr_qingcheng_skill)
sr_qingcheng_skill.getTurnUseCard=function(self)	
	if self.player:isChained() then return nil end
	if not sgs.Slash_IsAvailable(self.player) then return nil end
	return sgs.Card_Parse("#sr_qingchengcard:.:")		
end

sgs.ai_skill_use_func["#sr_qingchengcard"] = function(card, use, self)
	if self.player:isChained() then return end
	local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	local enemies = {}
	for _, p in ipairs(self.enemies) do
		if self.player:canSlash(p,slash,true) then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return end
	use.card = card
	self:sort(enemies,"defense")
	if use.to then
		use.to:append(enemies[1])
	else
		return
	end
end

sgs.ai_cardsview_valuable["sr_qingcheng"] = function(self, class_name,player)
	if not player:hasSkill("sr_qingcheng") then return end
	if class_name == "Slash" and not player:isChained() then
		return "#sr_qingchengcard:.:"
	elseif class_name == "Jink" and player:isChained() then
		return "#sr_qingchengcard:.:"
	end
	return
end

sgs.ai_card_intention["#sr_qingchengcard"] = sgs.ai_card_intention.Slash

sgs.ai_use_priority["#sr_qingchengcard"] = sgs.ai_use_priority.Slash

--忠侯
sgs.ai_skill_choice["sr_xiahouhelp"] = function(self,choices,data)
	if self:isWeak() then return "srcancel" end
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then return "srlosehp" end
	return "srcancel"
end

local sr_xiahou_skill={}
sr_xiahou_skill.name="sr_xiahou"
table.insert(sgs.ai_skills,sr_xiahou_skill)
sr_xiahou_skill.getTurnUseCard=function(self)	
	if self.player:getPhase() ~= sgs.Player_Play then return nil end
	if self.player:hasFlag("xiahouused") then return nil end	
	local Analeptic = sgs.Sanguosha:cloneCard("analeptic",sgs.Card_NoSuit,0)
	Analeptic:deleteLater()
	if not self.player:isWounded() and not sgs.Slash_IsAvailable(self.player) and 
		not Analeptic:isAvailable(self.player) then
		return nil
	end
	local xiahou = self.room:findPlayerBySkillName("sr_zhonghou")	
	if not xiahou then return nil end
	if self:isFriend(xiahou) and self:isWeak(xiahou) then return nil end
	return sgs.Card_Parse("#sr_xiahoucard:.:")
end

sgs.ai_skill_use_func["#sr_xiahoucard"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_choice["sr_xiahou"] = function(self,choices,data)
	if self:isWeak() then return "peach" end
	local Analeptic = sgs.Sanguosha:cloneCard("analeptic",sgs.Card_NoSuit,0)
	Analeptic:deleteLater()
	if sgs.Slash_IsAvailable(self.player) then
		for _,p in ipairs(self.enemies) do
			if self.player:canSlash(p,true) then				
				if p:getMark("@gale")>0 or p:getEquip(1) and p:getEquip(1):isKindOf("Vine") then
					if string.find(choices,"fire_slash") then
						return "fire_slash"
					end
				end
				if p:getMark("@fog")>0 then
					if string.find(choices,"thunder_slash") then
						return "thunder_slash"
					end
				end
				if self:getCardsNum("Slash") > 0 and Analeptic:isAvailable(self.player) then
					if string.find(choices,"analeptic") then
						return "analeptic"
					end
				end
				for _,c in ipairs(choices:split("+")) do
					if string.find(c,"slash") then			
						return c
					end
				end				
			end
		end
	elseif self.player:isWounded() then
		return "peach"
	end
end

sgs.ai_skill_choice["sr_xiahouresponse"] = function(self,choices,data)
	local choices1 = choices:split("+")
	return choices1[math.random(1, #choices1)]	
end

sgs.ai_skill_choice["sr_xiahousave"] = function(self,choices,data)
	local choices1 = choices:split("+")
	return choices1[math.random(1, #choices1)]
end

sgs.ai_cardsview_valuable["sr_xiahou"] = function(self, class_name,player)
	if not player:hasSkill("sr_xiahou") then return end
	if player:getPhase() ~= sgs.Player_Play then return end
	if player:hasFlag("xiahouused") then return nil end
	if class_name == "Slash" then
		return "#sr_xiahoucard:.:"
	elseif class_name == "Jink" then
		return "#sr_xiahoucard:.:"
	elseif class_name == "Peach" or class_name == "Analeptic" then
		if not player:hasFlag("Global_PreventPeach") then
			return "#sr_xiahoucard:.:"
		end
	end
	return
end

sgs.ai_skill_playerchosen["sr_xiahou"] = function(self,targets)
	local enemies = {}
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			table.insert(enemies,p)
		end
	end
	if #enemies==0 then return nil end
	self:sort(enemies,"defense")
	return enemies[1]
end

sgs.ai_card_intention["sr_xiahoucard"] = sgs.ai_card_intention.Slash

sgs.ai_use_priority["sr_xiahoucard"] = sgs.ai_use_priority.Slash



--刚烈
sgs.ai_skill_invoke["sr_ganglie"] = function(self,data)
	if not self:isWeak() and self.player:getHandcardNum() >=2 then
		for _,c in sgs.qlist(self.player:getHandcards()) do
			if c:isKindOf("Slash") then
				for _, p in ipairs(self.enemies) do
					if self.player:canSlash(p,true) then
						if self:isWeak(p) or (p:isKongcheng() and not p:getArmor()) then
							return true
						end
					end
				end
			elseif c:isKindOf("SavageAssault") or c:isKindOf("ArcheryAttack") then
				local nextplayer = self.player:getNextAlive()
				return (self:isFriend(nextplayer) and not self:isWeak(nextplayer))
				   or  (self:isEnemy(nextplayer) and self:isWeak(nextplayer))
			elseif c:isKindOf("Duel") then
				for _, p in ipairs(self.enemies) do					
					if not self.player:isProhibited(p,c) then
						if self:isWeak(p) or p:isKongcheng() then
							return true
						end
					end
				end
			elseif c:isKindOf("FireAttack") then
				for _, p in ipairs(self.enemies) do					
					if not self.player:isProhibited(p,c) then
						if (self:isWeak(p) or p:getArmor() and p:getArmor():isKindOf("Vine")) 
							and not p:isKongcheng() and self.player:getHandcardNum():length()>=4 then
							return true
						end
					end
				end
			end
		end
	end
	return false
end
sgs.ai_ajustdamage_from.sr_ganglie   = function(self, from, to, card, nature)
	if from and not from:hasFlag("damageincreased") and from:hasFlag("srganglieinvoked") then
		return 1
	end
end
--无畏
sgs.ai_skill_playerchosen["sr_wuwei"] = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_invoke["sr_yansha"] = function(self,data)
	if self.player:hasFlag("yansha_draw") then
		return (not self:isWeak()) and (self.player:getHandcardNum() >= 2)
	end
	local use = data:toCardUse()
	local from = use.from
	return self:isEnemy(from) and from:getCards("h"):length()>=2
end
sgs.ai_skill_cardask["#sr_yansha"] = function(self, data, pattern, target, target2)
	if self.player:isKongcheng() then return "." end	
	local cards = sgs.QList2Table(self.player:getHandcards())
	if #cards==1 and (cards[1]:isKindOf("Peach") or cards[1]:isKindOf("Analeptic")) then return "." end
	self:sortByKeepValue(cards)
	return "$"..cards[1]:getEffectiveId()
end


--离间
function getLijianCard(self)
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
	return card_id
end

function findLijianTarget(self,card_name, use)
	local lord = self.room:getLord()
	local duel = sgs.Sanguosha:cloneCard("duel")

	local findFriend_maxSlash = function(self, first)
		self:log("Looking for the friend!")
		local maxSlash = 0
		local friend_maxSlash
		local nos_fazheng, fazheng
		for _, friend in ipairs(self.friends_noself) do
			if friend:isMale() and self:hasTrickEffective(duel, first, friend) then
				if friend:hasSkill("nosenyuan") and friend:getHp() > 1 then nos_fazheng = friend end
				if friend:hasSkill("enyuan") and friend:getHp() > 1 then fazheng = friend end
				if (getCardsNum("Slash", friend) > maxSlash) then
					maxSlash = getCardsNum("Slash", friend)
					friend_maxSlash = friend
				end
			end
		end

		if friend_maxSlash then
			local safe = false
			if self:hasSkills("neoganglie|vsganglie|fankui|enyuan|ganglie|nosenyuan", first) and not 
				self:hasSkills("wuyan|noswuyan", first) then
				if (first:getHp() <= 1 and first:getHandcardNum() == 0) then safe = true end
			elseif (getCardsNum("Slash", friend_maxSlash) >= getCardsNum("Slash", first)) then safe = true end
			if safe then return friend_maxSlash end
		else self:log("unfound")
		end
		if nos_fazheng or fazheng then	return nos_fazheng or fazheng end		--备用友方，各种恶心的法正
		return nil
	end
	
	if self.role == "rebel" or (self.role == "renegade" and 
		sgs.playerRoles["loyalist"]  + 1 > sgs.playerRoles["rebel"]) then		
		
		if lord and lord:isMale() and not lord:isNude() and lord:objectName() ~= self.player:objectName() then		-- 优先离间1血忠和主
			self:sort(self.enemies, "handcard")
			local e_peaches = 0
			local loyalist
			
			for _, enemy in ipairs(self.enemies) do
				e_peaches = e_peaches + getCardsNum("Peach", enemy)
				if enemy:getHp() == 1 and self:hasTrickEffective(duel, enemy, lord) and 
					enemy:objectName() ~= lord:objectName()
				and enemy:isMale() and not loyalist then
					loyalist = enemy
					break
				end
			end

			if loyalist and e_peaches < 1 then return loyalist, lord end
		end
		
		if #self.friends_noself >= 2 and self:getAllPeachNum() < 1 then		--收友方反
			local nextplayerIsEnemy
			local nextp = self.player:getNextAlive()
			for i = 1, self.room:alivePlayerCount() do
				if not self:willSkipPlayPhase(nextp) then
					if not self:isFriend(nextp) then nextplayerIsEnemy = true end
					break
				else
					nextp = nextp:getNextAlive()
				end
			end	
			if nextplayerIsEnemy then
				local round = 50
				local to_die, nextfriend
				self:sort(self.enemies, "hp")
				
				for _, a_friend in ipairs(self.friends_noself) do	-- 目标1：寻找1血友方
					if a_friend:getHp() == 1 and a_friend:isKongcheng() and not 
					self:hasSkills("kongcheng|yuwen", a_friend) and a_friend:isMale() then
						for _, b_friend in ipairs(self.friends_noself) do		
						--目标2：寻找位于我之后，离我最近的友方
							if b_friend:objectName() ~= a_friend:objectName() and b_friend:isMale() and
							 self:playerGetRound(b_friend) < round
							and self:hasTrickEffective(duel, a_friend, b_friend) then
							
								round = self:playerGetRound(b_friend)
								to_die = a_friend
								nextfriend = b_friend
								
							end
						end
						if to_die and nextfriend then break end
					end
				end

				if to_die and nextfriend then return to_die, nextfriend end
			end
		end
	end
	
	if lord and self:isFriend(lord) and lord:hasSkill("hunzi") and lord:getHp() == 2 and 
	lord:getMark("hunzi") == 0	and lord:objectName() ~= self.player:objectName() then
		local enemycount = self:getEnemyNumBySeat(self.player, lord)
		local peaches = self:getAllPeachNum()
		if peaches >= enemycount then
			local f_target, e_target
			for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if ap:objectName() ~= lord:objectName() and ap:isMale() and 
					self:hasTrickEffective(duel, lord, ap) then
					if self:hasSkills("jiang|nosjizhi|jizhi", ap) and self:isFriend(ap) and 
					not ap:isLocked(duel) then
						if not use.isDummy then lord:setFlags("AIGlobal_NeedToWake") end
						return lord, ap
					elseif self:isFriend(ap) then
						f_target = ap
					else
						e_target = ap
					end
				end
			end
			if f_target or e_target then
				local target
				if f_target and not f_target:isLocked(duel) then
					target = f_target
				elseif e_target and not e_target:isLocked(duel) then
					target = e_target
				end
				if target then
					if not use.isDummy then lord:setFlags("AIGlobal_NeedToWake") end
					return lord, target
				end
			end
		end
	end

	local shenguanyu = self.room:findPlayerBySkillName("wuhun")
	if shenguanyu and shenguanyu:isMale() and shenguanyu:objectName() ~= self.player:objectName() then
		if self.role == "rebel" and lord and lord:isMale() and lord:objectName() ~= self.player:objectName() 
			and not lord:hasSkill("jueqing") and self:hasTrickEffective(duel, shenguanyu, lord) then
			return shenguanyu, lord
		elseif self:isEnemy(shenguanyu) and #self.enemies >= 2 then
			for _, enemy in ipairs(self.enemies) do
				if enemy:objectName() ~= shenguanyu:objectName() and enemy:isMale() and not enemy:isLocked(duel)
					and self:hasTrickEffective(duel, shenguanyu, enemy) then
					return shenguanyu, enemy
				end
			end
		end
	end

	if not self.player:hasUsed(card_name) then
		self:sort(self.enemies, "defense")
		local males, others = {}, {}
		local first, second
		local zhugeliang_kongcheng, xunyu

		for _, enemy in ipairs(self.enemies) do
			if enemy:isMale() and not self:hasSkills("wuyan|noswuyan", enemy) then
				if enemy:hasSkill("kongcheng") and enemy:isKongcheng() then zhugeliang_kongcheng = enemy
				elseif enemy:hasSkill("jieming") then xunyu = enemy
				else
					for _, anotherenemy in ipairs(self.enemies) do
						if anotherenemy:isMale() and anotherenemy:objectName() ~= enemy:objectName() then
							if #males == 0 and self:hasTrickEffective(duel, enemy, anotherenemy) then
								if not (enemy:hasSkill("hunzi") and enemy:getMark("hunzi") < 1 and 
									enemy:getHp() == 2) then
									table.insert(males, enemy)
								else
									table.insert(others, enemy)
								end
							end
							if #males == 1 and self:hasTrickEffective(duel, males[1], anotherenemy) then
								if not anotherenemy:hasSkills("nosjizhi|jizhi|jiang") then
									table.insert(males, anotherenemy)
								else
									table.insert(others, anotherenemy)
								end
								if #males >= 2 then break end
							end
						end
					end
				end
				if #males >= 2 then break end
			end
		end
		
		if #males >= 1 and sgs.ai_role[males[1]:objectName()] == "rebel" and males[1]:getHp() == 1 then
			if lord and self:isFriend(lord) and lord:isMale() and lord:objectName() ~= males[1]:objectName() and 
			self:hasTrickEffective(duel, males[1], lord)
				and not lord:isLocked(duel) and lord:objectName() ~= self.player:objectName() and lord:isAlive()
				and (getCardsNum("Slash", males[1]) < 1
					or getCardsNum("Slash", males[1]) < getCardsNum("Slash", lord)
					or self:getKnownNum(males[1]) == males[1]:getHandcardNum() and 
					getKnownCard(males[1], "Slash", true, "he") == 0)
				then
				return males[1], lord
			end
			
			local afriend = findFriend_maxSlash(self, males[1])
			if afriend and afriend:objectName() ~= males[1]:objectName() then
				return males[1], afriend
			end
		end
		
		if #males == 1 then
			if isLord(males[1]) and sgs.turncount <= 1 and self.role == "rebel" and 
				self.player:aliveCount() >= 3 then
				local p_slash, max_p, max_pp = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if p:isMale() and not self:isFriend(p) and p:objectName() ~= males[1]:objectName() 
					and self:hasTrickEffective(duel, males[1], p) and not p:isLocked(duel)
						and p_slash < getCardsNum("Slash", p) then
						if p:getKingdom() == males[1]:getKingdom() then
							max_p = p
							break
						elseif not max_pp then
							max_pp = p
						end
					end
				end
				if max_p then table.insert(males, max_p) end
				if max_pp and #males == 1 then table.insert(males, max_pp) end
			end
		end
		
		if #males == 1 then
			if #others >= 1 and not others[1]:isLocked(duel) then
				table.insert(males, others[1])
			elseif xunyu and not xunyu:isLocked(duel) then
				if getCardsNum("Slash", males[1]) < 1 then
					table.insert(males, xunyu)
				else
					local drawcards = 0
					for _, enemy in ipairs(self.enemies) do
						local x = enemy:getMaxHp() > enemy:getHandcardNum() and
						 math.min(5, enemy:getMaxHp() - enemy:getHandcardNum()) or 0
						if x > drawcards then drawcards = x end
					end
					if drawcards <= 2 then
						table.insert(males, xunyu)
					end
				end
			end
		end
		
		if #males == 1 and #self.friends_noself > 0 then
			self:log("Only 1")
			first = males[1]
			if zhugeliang_kongcheng and self:hasTrickEffective(duel, first, zhugeliang_kongcheng) then
				table.insert(males, zhugeliang_kongcheng)
			else
				local friend_maxSlash = findFriend_maxSlash(self, first)
				if friend_maxSlash then table.insert(males, friend_maxSlash) end
			end
		end
		
		if #males >= 2 then
			first = males[1]
			second = males[2]
			if lord and first:getHp() <= 1 then
				if self.player:isLord() or sgs.isRolePredictable() then 
					local friend_maxSlash = findFriend_maxSlash(self, first)
					if friend_maxSlash then second = friend_maxSlash end
				elseif lord:isMale() and not self:hasSkills("wuyan|noswuyan", lord) then
					if self.role=="rebel" and not first:isLord() and self:hasTrickEffective(duel, first, lord) then
						second = lord
					else
						if ( (self.role == "loyalist" or self.role == "renegade") and 
							not self:hasSkills("ganglie|enyuan|neoganglie|nosenyuan", first) )
							and ( getCardsNum("Slash", first) <= getCardsNum("Slash", second) ) then
							second = lord
						end
					end
				end
			end

			if first and second and first:objectName() ~= second:objectName() and not second:isLocked(duel) then
				return first, second
			end
		end
	end
end

local sr_lijian_skill = {}
sr_lijian_skill.name = "sr_lijian"
table.insert(sgs.ai_skills, sr_lijian_skill)
sr_lijian_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#sr_lijiancard") or self.player:isNude() then
		return
	end
	local card_id = getLijianCard(self)
	if card_id then return sgs.Card_Parse("#sr_lijiancard:" .. card_id..":") end
end

sgs.ai_skill_use_func["#sr_lijiancard"] = function(card, use, self)
	local first, second = findLijianTarget(self,"#sr_lijiancard", use)
	if first and second then
		use.card = card
		if use.to then
			use.to:append(first)
			use.to:append(second)
		end
	end
end

sgs.ai_use_value["#sr_lijiancard"] = 8.5
sgs.ai_use_priority["#sr_lijiancard"] = 4

lijian_filter = function(self, player, carduse)
	if carduse.card:isKindOf("#sr_lijiancard") then
		sgs.ai_lijian_effect = true
	end
end

table.insert(sgs.ai_choicemade_filter.cardUsed, lijian_filter)

sgs.ai_card_intention["#sr_lijiancard"] = function(self, card, from, to)
	if sgs.ai_role[to[1]:objectName()] == sgs.ai_role[to[2]:objectName()] then
		if sgs.ai_role[from:objectName()] == "rebel" and 
			sgs.ai_role[to[1]:objectName()] == sgs.ai_role[from:objectName()] and to[1]:getHp() == 1 then
		elseif to[1]:hasSkill("hunzi") and to[1]:getHp() == 2 and to[1]:getMark("hunzi") == 0 then
		else
			sgs.updateIntentions(from, to, 40)
		end
	elseif sgs.ai_role[to[1]:objectName()] ~= sgs.ai_role[to[2]:objectName()] and not to[1]:hasSkill("wuhun") then
		sgs.updateIntention(from, to[1], 80)
	end
end

sgs.dynamic_value.damage_card["#sr_lijiancard"] = true

--曼舞
local sr_manwu_skill = {}
sr_manwu_skill.name = "sr_manwu"
table.insert(sgs.ai_skills, sr_manwu_skill)
sr_manwu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#sr_manwucard") then return nil end
	local cando = false
	for _, p in ipairs(self.enemies) do
		if p:isMale() and not p:isKongcheng() then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return sgs.Card_Parse("#sr_manwucard:.:") 
end

sgs.ai_skill_use_func["#sr_manwucard"] = function(card, use, self)
	local enemies = {}
	for _, p in ipairs(self.enemies) do
		if p:isMale() and not p:isKongcheng() then
			table.insert(enemies,p)
		end
	end
	if #enemies == 0 then return end
	self:sort(enemies,"defense")
	use.card = card
	if use.to then
		use.to:append(enemies[1])			
	end
end

--行医
local sr_xingyi_skill = {}
sr_xingyi_skill.name = "sr_xingyi"
table.insert(sgs.ai_skills, sr_xingyi_skill)
sr_xingyi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#sr_xingyicard") then return nil end
	local cando = false
	for _, p in ipairs(self.friends_noself) do
		if not p:isKongcheng() and p:isWounded() then
			cando = true
			break
		end
	end
	if not cando then return nil end
	return sgs.Card_Parse("#sr_xingyicard:.:")
end

sgs.ai_skill_use_func["#sr_xingyicard"] = function(card, use, self)
	--local enemies = {}
	local friends = {}
	for _, p in ipairs(self.friends_noself) do		
		if not p:isKongcheng() and p:isWounded() then
			table.insert(friends,p)
		end
	end
	if #friends > 0 then
		self:sort(friends,"defense")
		use.card = card
		if use.to then
			use.to:append(friends[1])
		end
		return
	end	
	return
end
--刮骨
sgs.ai_skill_invoke["sr_guagu"] = function(self,data)
	local dying = data:toDying()
	if self:isFriend(dying.who) then return true end
	if self.player:getRole() == "renegade" and dying.who:isLord() and 
		self.room:getAlivePlayers():length()>2 then return true end
	return false
end

--五禽
sgs.ai_skill_cardask["srwuqindiscard"]=function(self, data, pattern, target, target2)
	local dis = {}
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("BasicCard") then
			table.insert(dis,c)
		end
	end
	if #dis == 0 then return "." end
	if #dis == 1 and (dis[1]:isKindOf("Peach") or dis[1]:isKindOf("Analeptic")) then return "." end
	self:sortByKeepValue(dis)
	return "$"..dis[1]:getEffectiveId()
end
sgs.ai_skill_choice["sr_wuqin"] = function(self,choices,data)
	if self:isWeak() or self.player:getHandcardNum() <=2 then return "srwuqindraw" end
	return "srwuqinplay"
end

--极武
local sr_jiwu_skill = {}
sr_jiwu_skill.name = "sr_jiwu"
table.insert(sgs.ai_skills, sr_jiwu_skill)
sr_jiwu_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#sr_jiwucard") then return nil end
	if not sgs.Slash_IsAvailable(self.player) and self.player:getHandcardNum() > 0 then return nil end
	if #self.enemies==0 and self.player:getHandcardNum() > 0 then return nil end	 	
	return sgs.Card_Parse("#sr_jiwucard:.:")
end

sgs.ai_skill_use_func["#sr_jiwucard"] = function(card, use, self)
	local can_jiwu = self:getCardsNum("Slash") > 0 or self.player:isKongcheng()
	if not can_jiwu then return nil end
	use.card = card
end

sgs.ai_skill_use["@@jiwu_extarget"] = function(self, prompt, method)
	local data = self.room:getTag("jiwudata")
	local use = data:toCardUse()
	local slash = use.card
	self:updatePlayers()
	self:sort(self.enemies, "defenseSlash")
	local targets = {}
	for _, target in ipairs(self.enemies) do
		if (not self:slashProhibit(slash, target)) and self:isGoodTarget(target, self.enemies, nil) and self:slashIsEffective(slash, target) and target:getMark("jiwu_target") == 0 and target:getMark("jiwu_nil") == 0 then
			table.insert(targets, target:objectName())
		end
	end
	if #targets > 0 then
		return "#jiwu_extarget:.:->" .. table.concat(targets, "+")
	else
		return "."
	end
end

sgs.ai_skill_discard.sr_jiwu = function(self, discard_num, min_num, optional, include_equip)
	local slash = nil
	local to_discard = {}
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("Slash") and not slash then
			slash = c			
		else
			table.insert(to_discard,c:getEffectiveId())
			if #to_discard == self.player:getHandcardNum() - 1 then break end
		end
	end
	return to_discard
end


sgs.ai_use_priority["sr_jiwucard"] = sgs.ai_use_priority.Analeptic - 0.1
sgs.ai_use_value["sr_jiwucard"] = 9
sgs.ai_cardneed.sr_jiwu = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.sr_jiwu   = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and from:getMark("jiwu_slashdamage") > 0 then
		return 1
	end
end
sgs.ai_card_priority.sr_jiwu = function(self,card,v)
	if self.useValue
	and card:isKindOf("Weapon")
	then v = 2 end
end


--射戟
sgs.ai_skill_invoke["sr_sheji"] = function(self,data)
	local damage = data:toDamage()
	return self:isEnemy(damage.from)  or hasSilverLionEffect(self.player)
end

local sr_sheji_skill={}
sr_sheji_skill.name="sr_sheji"
table.insert(sgs.ai_skills,sr_sheji_skill)
sr_sheji_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("he")	
	cards=sgs.QList2Table(cards)
	
	local equip_card
	
	self:sortByUseValue(cards,true)
	
	for _,card in ipairs(cards)  do
		if card:isKindOf("Crossbow") and self.room:getCardPlace(card:getId()) ==sgs.Player_PlaceEquip then
			if self.player:canSlashWithoutCrossbow() then
				equip_card = card
				break
			end
		else
			if card:isKindOf("EquipCard") then
				equip_card = card
				break
			end
		end
	end
	
	if not equip_card then return nil end
	local suit = equip_card:getSuitString()
	local number = equip_card:getNumberString()
	local card_id = equip_card:getEffectiveId()
	local card_str = ("slash:sr_sheji[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	
	return slash
		
end

sgs.ai_view_as["sr_sheji"] = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:isKindOf("EquipCard") then
		return ("slash:sr_sheji[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.sr_sheji_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.7,
	Slash = 5.6,
	ThunderSlash = 5.5,
	ExNihilo = 4.7,
	EquipCard = 5.9,
}
sgs.hit_skill = sgs.hit_skill .. "|sr_sheji"

sgs.ai_cardneed.sr_sheji = sgs.ai_cardneed.equip