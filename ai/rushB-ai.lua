
--成略
local rushB_chenglve_skill = {}
rushB_chenglve_skill.name = "rushB_chenglve"
table.insert(sgs.ai_skills,rushB_chenglve_skill)
rushB_chenglve_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#rushB_chenglve:.:")
end

sgs.ai_skill_use_func["#rushB_chenglve"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority.rushB_chenglve = 3
sgs.ai_use_value.rushB_chenglve = 7

sgs.ai_skill_discard.rushB_chenglve = function(self,discard_num,min_num,optional,include_equip)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local slashs = self:getCards("Slash")
	if #slashs>0 then self:sortByUseValue(handcards,true)
	else self:sortByKeepValue(handcards) end
	local to_discard = {}
	local suits = {}
	for s,sl in ipairs(slashs)do
		s = sl:getSuitString()
		if suits[s] then suits[s] = suits[s]+1
		else suits[s] = 1 end
	end
	local func = function(a,b)
		return a>b
	end
	table.sort(suits,func)
	for i,c in ipairs(handcards)do
		i = c:getEffectiveId()
		if table.contains(slashs,c)
		or #to_discard>=discard_num
		or #self.enemies<1
		then continue end
		if suits[c:getSuitString()]
		and suits[c:getSuitString()]>0
		then table.insert(to_discard,i) end
	end
	for i,c in ipairs(handcards)do
		i = c:getEffectiveId()
		if table.contains(to_discard,i)
		or #to_discard>=discard_num
		then continue end
		table.insert(to_discard,i)
	end
	return to_discard
end

sgs.ai_card_priority.rushB_chenglve = function(self,card)
	if self.player:getMark("chenglve"..card:getSuitString().."-Clear")>0
	and card:getTypeId()>0
	then return -1 end
end



sgs.ai_card_priority.rushB_jianying = function(self,card,v)
	if (card:isRed() and self.player:getMark("&jianyingcolorred") > 0) or
	(card:isBlack() and self.player:getMark("&jianyingcolorblack") > 0)
	or self.player:getMark("&jianyingnumber")==card:getNumber()
	then return 10 end
end





local rushB_zhiheng_skill={}
rushB_zhiheng_skill.name="rushB_zhiheng"
table.insert(sgs.ai_skills,rushB_zhiheng_skill)
rushB_zhiheng_skill.getTurnUseCard = function(self)
	local cards = self:addHandPile()
	self:sortByUseValue(cards,true)
	local card
	for _,acard in sgs.list(cards)do
		local shouldUse = true
		if self:getUseValue(acard)>sgs.ai_use_value.IronChain then
			local dummy_use = self:aiUseCard(acard, dummy())
			if dummy_use.card and acard:isAvailable(self.player) then shouldUse = false end
		end
		if acard:getTypeId()==sgs.Card_TypeEquip then
			local dummy_use = dummy()
			self:useEquipCard(acard,dummy_use)
			if dummy_use.card then shouldUse = false end
		end
		if shouldUse then
			card = acard
			break
		end
	end
	if self.player:getHandcardNum() == 1 and self.player:getMark("zhiheng".."-Clear") == 0 then
		card = cards[1]
	end
	if math.random() < 0.7 and ((self:getOverflow()==0 and not self.player:getHandcardNum() == 1) or #self.enemies == 0) then return nil end
	if not card then return nil end
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("iron_chain:rushB_zhiheng[%s:%s]=%d"):format(number, card:getSuitString(),card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.ai_hasTuntianEffect_skill.rushB_tuntian = function(to, need_zaoxian)
	return to:getPhase() == sgs.Player_NotActive
end

sgs.ai_skill_invoke.rushB_jiuyuan = function(self,data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.rushB_jiuyuan = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end

sgs.ai_can_damagehp.rushB_quanji = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>1
	and self:canLoseHp(from,card,to)
end


local rushB_paiyi_skill = {}
rushB_paiyi_skill.name = "rushB_paiyi"
table.insert(sgs.ai_skills,rushB_paiyi_skill)
rushB_paiyi_skill.getTurnUseCard = function(self)
	if self.player:getPile("power"):length()>0 then
		return sgs.Card_Parse("#rushB_paiyi:"..self.player:getPile("power"):first()..":")
	end
end

sgs.ai_skill_use_func["#rushB_paiyi"] = function(card,use,self)
	local target
	self:sort(self.friends_noself,"defense")
	for _,friend in ipairs(self.friends_noself)do
		if friend:getHandcardNum()<2 and friend:getHandcardNum()+1<self.player:getHandcardNum()
		  and not self:needKongcheng(friend,true) and not friend:hasSkill("manjuan") then
			target = friend
		end
		if target then break end
	end
	if not target then
		if self.player:getHandcardNum()<self.player:getHp()+self.player:getPile("power"):length()-1 then
			target = self.player
		end
	end
	self:sort(self.friends_noself,"hp")
	self.friends_noself = sgs.reverse(self.friends_noself)
	if not target then
		for _,friend in ipairs(self.friends_noself)do
			if friend:getHandcardNum()+2>self.player:getHandcardNum()
			and self:needToLoseHp(friend,self.player,nil,true)
			and not friend:hasSkill("manjuan") then
				target = friend
			end
			if target then break end
		end
	end
	self:sort(self.enemies,"defense")
	if not target then
		for _,enemy in ipairs(self.enemies)do
			if hasManjuanEffect(enemy)
			and self:canDamage(enemy, self.player)
			and (self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player) 
				or self:damageIsEffective(enemy,sgs.DamageStruct_Thunder,self.player)
				or self:damageIsEffective(enemy,sgs.DamageStruct_Fire,self.player)
				or self:damageIsEffective(enemy,sgs.DamageStruct_Ice,self.player)
				)
			and enemy:getHandcardNum()>self.player:getHandcardNum() 
			then target = enemy end
			if target then break end
		end
		if not target then
			for _,enemy in ipairs(self.enemies)do
				if self:canDamage(enemy, self.player)
				and not enemy:hasSkills(sgs.cardneed_skill.."|jijiu|tianxiang|buyi")
				and (self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player) 
				or self:damageIsEffective(enemy,sgs.DamageStruct_Thunder,self.player)
				or self:damageIsEffective(enemy,sgs.DamageStruct_Fire,self.player)
				or self:damageIsEffective(enemy,sgs.DamageStruct_Ice,self.player)
				)
				and not self:cantbeHurt(enemy)
				and not self:needToLoseHp(enemy)
				and enemy:getHandcardNum()+2>self.player:getHandcardNum()
				then target = enemy end
				if target then break end
			end
		end
	end

	if target then
		use.card = sgs.Card_Parse("#rushB_paiyi:"..self.player:getPile("power"):first()..":")
		use.to:append(target)
	end
end

sgs.ai_skill_askforag.rushB_paiyi = function(self,card_ids)
	return card_ids[math.random(1,#card_ids)]
end

sgs.ai_card_intention.rushB_paiyi = function(self,card,from,tos)
	local to = tos[1]
	if to:objectName()==from:objectName() then return end
	if not to:hasSkill("manjuan")
	and ((to:getHandcardNum()<2 and to:getHandcardNum()+1<from:getHandcardNum() and not self:needKongcheng(to,true))
	or (to:getHandcardNum()+2>from:getHandcardNum() and self:needToLoseHp(to,from)))
	then
	else
		sgs.updateIntention(from,to,60)
	end
end

sgs.ai_skill_cardask["@diy_f_pojun"] = function(self, data, pattern, target)
	local target = self.room:getCurrent()
	if self:needBear() then return "." end
	if target and self:isEnemy(target) and self:objectiveLevel(target) > 3 and not self:willSkipPlayPhase(target) then
		return true
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@diy_f_pojun"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, 80)
	end
end


addAiSkills("diy_f_pojun").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		return sgs.Card_Parse("#diy_f_pojun:"..c:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#diy_f_pojun"] = function(card,use,self)
	
	self:sort(self.enemies,"defense")
	local slashcount = self:getCardsNum("Slash")
	if slashcount > 0 then
		local slash = self:getCard("Slash")
		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card and dummy_use.to then
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					if self:doDisCard(p, "he", true) then
						use.card = card
						use.to:append(p)
						return
					end
				end
			end
		end
	end
	for _,p in ipairs(self.enemies)do
		if self:doDisCard(p, "he", true) then
			use.card = sgs.Card_Parse("#diy_f_pojun:.:")
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_priority.diy_f_pojun = 6
sgs.ai_use_value.diy_f_pojun = 8.5

sgs.ai_ajustdamage_from.diy_f_pojun = function(self,from,to,card,nature)
	local n = 0
	if to:getHandcardNum() <= from:getHandcardNum() then n = n + 1 end
	if to:getEquips():length() <= from:getEquips():length() then n = n + 1 end
	if to:getJudgingArea():length() >= from:getJudgingArea():length() then n = n + 1 end
	return n
end


local diy_k_qixi_skill = {}
diy_k_qixi_skill.name = "diy_k_qixi"
table.insert(sgs.ai_skills,diy_k_qixi_skill)
diy_k_qixi_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("he")
	local black_card
	local red_card
	self:sortByUseValue(cards,true)
	local has_weapon = false
	for _,card in ipairs(cards)  do
		if card:isKindOf("Weapon") then has_weapon=true end
	end
	for _,card in ipairs(cards)  do
		if card:isBlack() and ((self:getUseValue(card)<sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow()>0) then
			local shouldUse = true
			if card:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(card) and not self:needToThrowArmor() then shouldUse = false
				end
			end
			if card:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then shouldUse = false
				end
			end
			if card:isKindOf("Slash") then
				local dummy_use = dummy()
				if self:getCardsNum("Slash")==1 then
					self:useBasicCard(card,dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end
			if self:getUseValue(card)>sgs.ai_use_value.Dismantlement and card:isKindOf("TrickCard") then
				local dummy_use = dummy()
				self:useTrickCard(card,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse then
				black_card = card
				break
			end
		end
	end
	for _,card in ipairs(cards)  do
		if (card:isRed() and card:isKindOf("EquipCard")) and ((self:getUseValue(card)<sgs.ai_use_value.Dismantlement) or inclusive or self:getOverflow()>0) then
			local shouldUse = true
			if card:isKindOf("Armor") then
				if not self.player:getArmor() then shouldUse = false
				elseif self.player:hasEquip(card) and not self:needToThrowArmor() then shouldUse = false
				end
			end
			if card:isKindOf("Weapon") then
				if not self.player:getWeapon() then shouldUse = false
				elseif self.player:hasEquip(card) and not has_weapon then shouldUse = false
				end
			end
			if card:isKindOf("Slash") then
				local dummy_use = dummy()
				if self:getCardsNum("Slash")==1 then
					self:useBasicCard(card,dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end
			if self:getUseValue(card)>sgs.ai_use_value.Dismantlement and card:isKindOf("TrickCard") then
				local dummy_use = dummy()
				self:useTrickCard(card,dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse then
				red_card = card
				break
			end
		end
	end
	if red_card then
		return sgs.Card_Parse("#diy_qixi:"..red_card:getEffectiveId()..":")
	end
	if black_card then
		local suit = black_card:getSuitString()
		local number = black_card:getNumberString()
		local card_id = black_card:getEffectiveId()
		local card_str = ("dismantlement:diy_k_qixi[%s:%s]=%d"):format(suit,number,card_id)
		local dismantlement = sgs.Card_Parse(card_str)
		assert(dismantlement)
		return dismantlement
	end
end

sgs.ai_skill_use_func["#diy_qixi"]=function(card,use,self)
	self:sort(self.enemies, "handcard", true)
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he", true) then
			use.card=card
			use.to:append(enemy)
			return
		end
	end
end
sgs.ai_use_priority.diy_qixi = sgs.ai_use_priority.Dismantlement + 0.2

sgs.ai_skill_use["@@diy_k_qixi"] = function(self,prompt)
	local cards = self:addHandPile("he")
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards)  do
		if card:isBlack() then
			local dismantlement = sgs.Sanguosha:cloneCard("dismantlement", sgs.Card_NoSuit, 0)
			dismantlement:setSkillName("_diy_k_qixi")
			dismantlement:addSubcard(card)
			dismantlement:deleteLater()
			local dummy_use = self:aiUseCard(dismantlement, dummy())
			if dummy_use.to and dummy_use.to:length() > 0 then
				local tos = {}
				for _,to in sgs.qlist(dummy_use.to) do
					table.insert(tos, to:objectName())
				end
				return dismantlement:toString().."->"..table.concat(tos, "+")
			end
		end
	end
	for _,card in ipairs(cards)  do
		if (card:isRed() and card:isKindOf("EquipCard")) then
			
			for _,to in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if not to:isNude() and self:doDisCard(to, "he", true) then
					return "#diy_qixi:"..card:getEffectiveId()..":->"..to:objectName()
				end
			end
		end
	end
	return "."
end

local function getFenweiValue(self,who,card,from)
	if not self:hasTrickEffective(card,who,from) then return 0 end
	if card:isKindOf("AOE") then
		if not self:isFriend(who) then return 0 end
		local value = self:getAoeValueTo(card,who,from)
		if value<0 then return -value/30 end
	elseif card:isKindOf("GodSalvation") then
		if not self:isEnemy(who) or not who:isWounded() or who:getHp()>=getBestHp(who) then return 0 end
		if self:isWeak(who) then return 1.2 end
		if who:hasSkills(sgs.masochism_skill) then return 1.0 end
		return 0.9
	elseif card:isKindOf("AmazingGrace") then
		if not self:isEnemy(who) or hasManjuanEffect(who) then return 0 end
		local v = 1.2
		local p = self.room:getCurrent()
		while p:objectName()~=who:objectName()do
			v = v*0.9
			p = p:getNextAlive()
		end
		return v
	end
	return 0
end
sgs.ai_skill_playerschosen.diy_k_fenwei = function(self, targets, max, min)
	local fenwei = sgs.ai_skill_use["@@fenwei"](self,"")
    local selected = sgs.SPlayerList()
	
	if fenwei ~= "." then
		local targets = fenwei:split(">")[2]:split("+")
		local can_choose = sgs.QList2Table(targets)
		self:sort(can_choose, "defense")
		for _,target in ipairs(can_choose) do
			if self:isFriend(target) and table.contains(targets, target:objectName()) then
				selected:append(target)
			end
		end
	elseif math.random() < 0.8 then
		local card = self.player:getTag("fenwei"):toCardUse().card
		local from = self.player:getTag("fenwei"):toCardUse().from
		local can_choose = sgs.QList2Table(targets)
		self:sort(can_choose, "defense")
		for _,target in ipairs(can_choose) do
			local val = getFenweiValue(self,target,card,from)
			if val>0 then
				selected:append(target)
			end
		end
	end
    return selected
end
sgs.ai_skill_invoke.wen_jingtian = true


sgs.ai_skill_invoke.wen_jtweidi = function(self,data)
	local damage = data:toDamage()
	return not self:needToLoseHp(self.player, damage.from, damage.card)
end

sgs.ai_skill_invoke.wen_zemin = function(self,data)
	local damage = data:toDamage()
	return damage.to and self:isFriend(damage.to) and not self:needToLoseHp(damage.to, damage.from, damage.card)
end


addAiSkills("wen_jtweidi").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getPile("chushibiao"))
  	for _,id in sgs.list(cards)do
		return sgs.Card_Parse("#wen_jtweidi:"..id..":") 
	end
end

sgs.ai_skill_use_func["#wen_jtweidi"] = function(card,use,self)
	for _,enemy in ipairs(self.enemies)do
		if self:canDamage(enemy, self.player, nil) and self:damageIsEffective(enemy,sgs.DamageStruct_Fire,self.player) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if self:canDraw(friend, self.player)  then
			use.card = card
			use.to:append(friend)
			return
		end
	end
end

sgs.ai_use_value.wen_jtweidi = 9.4
sgs.ai_use_priority.wen_jtweidi = 4.8

sgs.ai_skill_choice["wen_jtweidi"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if self:isFriend(target) then
		if table.contains(items, "3") then
			return "3"
		end
		if table.contains(items, "4") then
			return "4"
		end
	end
	if table.contains(items, "1") then
		if self:canDamage(target, self.player, nil) and self:damageIsEffective(target,sgs.DamageStruct_Fire,self.player) then
			if math.random() < 0.8 then
				return "1"
			end
		end
	end
	if table.contains(items, "3") then
		if math.random() < 0.5 then
			return "3"
		end
	end
	if table.contains(items, "2") then
		if not self:damageIsEffective(self.player,sgs.DamageStruct_Fire,target) then
			return "2"
		end
		if math.random() < 0.5 then
			return "2"
		end
	end
	if table.contains(items, "4") then
		if math.random() < 0.5 then
			return "4"
		end
	end
end

sgs.ai_can_damagehp.diy_k_zhongzuo = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and to:getMark("damaged_round-Clear") == 0
end
sgs.ai_skill_playerchosen.diy_k_zhongzuo = function(self,targets)
	self:sort(self.friends_noself,"defense")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,friend in ipairs(self.friends_noself)do
		if not self:canDraw(friend) then continue end
		if (friend:getHandcardNum()+(friend:isWounded() and -2 or 1))<(self.player:getHandcardNum()+(self.player:isWounded() and -2 or 0)) then
			return friend
		end
	end
	if self:canDraw(self.player) then return self.player end
	return nil
end
sgs.ai_playerchosen_intention.diy_k_zhongzuo = -40

sgs.ai_skill_invoke.diy_k_tongqu = false


sgs.ai_skill_discard.diy_k_wanlan = function(self)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and self.player:objectName() == damage.from:objectName() then
		if not self:canDamage(damage.to, self.player, nil) then
			return {}
		end
	elseif damage.from then
		if not self:canDamage(damage.from, self.player, nil) then
			return {}
		end
	end
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, card:getEffectiveId())
		if #to_discard == 2 then
        	break
		end
	end
	if #to_discard == 2 then
		return to_discard
	end
	return {}
end


local rushB_lihun_skill = {}
rushB_lihun_skill.name = "rushB_lihun"
table.insert(sgs.ai_skills,rushB_lihun_skill)
rushB_lihun_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if #cards<1 then return end
	return sgs.Card_Parse("#rushB_lihun:"..cards[1]:getId()..":")
end

sgs.ai_skill_use_func["#rushB_lihun"] = function(card,use,self)
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
	if not self.player:faceUp()
	then
		for _,enemy in sgs.list(self.enemies)do
			if enemy:getHandcardNum()>=enemy:getHp()
			then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
	if self:hasCrossbowEffect()
	or self:getCardsNum("Crossbow")>0
	then
		local slash = self:getCard("Slash") or dummyCard()
		for _,enemy in sgs.list(self.enemies)do
			if not enemy:isKongcheng()
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


sgs.ai_skill_discard.rushB_lihun = function(self,discard_num,min_num,optional,include_equip)
	local to_discard = {}

	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local card_ids = {}
	for _,card in sgs.list(cards)do
		table.insert(card_ids,card:getEffectiveId())
	end

	local temp = table.copyFrom(card_ids)
	for i = 1,#temp,1 do
		local card = sgs.Sanguosha:getCard(temp[i])
		if self.player:getArmor() and temp[i]==self.player:getArmor():getEffectiveId() and self:needToThrowArmor() then
			table.insert(to_discard,temp[i])
			table.removeOne(card_ids,temp[i])
			if #to_discard==discard_num then
				return to_discard
			end
		end
	end

	temp = table.copyFrom(card_ids)

	for i = 1,#card_ids,1 do
		local card = sgs.Sanguosha:getCard(card_ids[i])
		table.insert(to_discard,card_ids[i])
		if #to_discard==discard_num then
			return to_discard
		end
	end

	if #to_discard<discard_num then return {} end
end

sgs.ai_use_value.rushB_lihun = 8.5
sgs.ai_use_priority.rushB_lihun = 6
sgs.ai_card_intention.rushB_lihun = 80


local rushB_fanjian_skill = {}
rushB_fanjian_skill.name = "rushB_fanjian"
table.insert(sgs.ai_skills,rushB_fanjian_skill)
rushB_fanjian_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return nil end
	return sgs.Card_Parse("#rushB_fanjian:.:")
end

sgs.ai_skill_use_func["#rushB_fanjian"]=function(card,use,self)

	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	if #cards==1 and cards[1]:getSuit()==sgs.Card_Diamond then return end
	if #cards<=4 and (self:getCardsNum("Peach")>0 or self:getCardsNum("Analeptic")>0) then return end
	self:sort(self.enemies,"hp")

	local suits = {}
	local suits_num = 0
	for _,c in ipairs(cards)do
		if not suits[c:getSuitString()] then
			suits[c:getSuitString()] = true
			suits_num = suits_num+1
		end
	end

	local wgt = self.room:findPlayerBySkillName("buyi")
	if wgt and self:isFriend(wgt) then wgt = nil end

	for _,enemy in ipairs(self.enemies)do
		local visible = 0
		for _,card in ipairs(cards)do
			local flag = string.format("%s_%s_%s","visible",enemy:objectName(),self.player:objectName())
			if card:hasFlag("visible") or card:hasFlag(flag) then visible = visible+1 end
		end
		if visible>0 and (#cards<=2 or suits_num<=2) then continue end
		if self:canAttack(enemy) and not enemy:hasSkills("qingnang|jijiu|tianxiang")
		and not (wgt and card:getTypeId()~=sgs.Card_Basic and (enemy:isKongcheng() or enemy:objectName()==wgt:objectName()))
		and self:damageIsEffective(enemy,card)
		then
			use.card = sgs.Card_Parse("#rushB_fanjian:.:")
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_card_intention.rushB_fanjian = 70


sgs.ai_skill_use["@@rushB_xiongyi"] = function(self, prompt)
	self:sort(self.friends_noself, "defense", true)
	local targets = {}
	local to_use = {}
	for _,friend in ipairs(self.friends_noself) do
		for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
			if not table.contains(to_use, c:getId()) then
				table.insert(to_use, c:getId())
				table.insert(targets, friend:objectName())
				break
			end
		end
	end
	if (#targets == #to_use and #targets > 0) then
		return "#rushB_xiongyi:".. table.concat(to_use, "+") ..":->".. table.concat(targets, "+")
	end
	return "."
end
sgs.ai_card_intention.rushB_xiongyi = -70

local diy_f_zhuiji_skill = {}
diy_f_zhuiji_skill.name = "diy_f_zhuiji"
table.insert(sgs.ai_skills, diy_f_zhuiji_skill)
diy_f_zhuiji_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies==0 then return nil end	
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if #cards<1 then return end
	return sgs.Card_Parse("#diy_f_zhuiji:"..cards[1]:getEffectiveId()..":")
end

sgs.ai_skill_use_func["#diy_f_zhuiji"] = function(card, use, self)
	self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end

local diy_f_xionglie_skill = {}
diy_f_xionglie_skill.name = "diy_f_xionglie"
table.insert(sgs.ai_skills, diy_f_xionglie_skill)
diy_f_xionglie_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies==0 then return nil end	
	return sgs.Card_Parse("#diy_f_xionglie:.:")
end

sgs.ai_skill_use_func["#diy_f_xionglie"] = function(card, use, self)
	self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if (self:canDamage(self.player,enemy,nil) or not self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player)) and self:doDisCard(enemy, "he", true) then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end


sgs.ai_skill_playerchosen.diy_k_qizhi = sgs.ai_skill_playerchosen.qizhi 
sgs.ai_skill_invoke.diy_k_jinqu = function(self)
	if self.room:getCurrent() and self.room:getCurrent():objectName() ~= self.player:objectName() then return true end
	if self.player:getMark("&qizhi-Clear")>=self.player:getHandcardNum() then return true end
	return false
end

local diy_k_fanghun_skill = {}
diy_k_fanghun_skill.name = "diy_k_fanghun"
table.insert(sgs.ai_skills,diy_k_fanghun_skill)
diy_k_fanghun_skill.getTurnUseCard = function(self)
	local handcards = self:addHandPile()
	if #handcards<1 then return end
	handcards = self:sortByUseValue(handcards,true)
	for _,c in sgs.list(handcards)do
		local slash = dummyCard()
		slash:setSkillName("diy_k_fanghun")
		slash:addSubcard(c)
		if c:isKindOf("Jink")
		and slash:isAvailable(self.player)
		then
			return slash
		elseif c:isKindOf("Analeptic") then
			return sgs.Card_Parse(("peach:diy_k_fanghun[%s:%s]=%d"):format(c:getSuitString(),c:getNumberString(),c:getEffectiveId()))
		end
	end
end

function sgs.ai_cardsview.diy_k_fanghun(self,class_name,player)
   	local cards = sgs.QList2Table(player:getCards("h"))
    self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if class_name=="Slash" and c:isKindOf("Jink")
		then return ("slash:diy_k_fanghun[no_suit:0]="..c:getEffectiveId())
		elseif class_name=="Jink" and c:isKindOf("Slash")
		then return ("jink:diy_k_fanghun[no_suit:0]="..c:getEffectiveId()) 
		elseif c:isKindOf("Analeptic") then
			return ("peach:diy_k_fanghun[no_suit:0]="..c:getEffectiveId())
		end
	end
end



sgs.ai_skill_invoke.diy_k_fuhan = function(self,data)
	local meiying = self.player:getMark("&diy_k_meiying")
	if self.player:getLostHp()>0 then
		return meiying>self.player:getHp() and self.player:isLowestHpPlayer() and self:getCardsNum("Peach")==0 and self:isWeak()
	else
		return meiying>self.player:getMaxHp()
	end
	return false
end



local diy_k_qice_skill = {}
diy_k_qice_skill.name = "diy_k_qice"
table.insert(sgs.ai_skills,diy_k_qice_skill)
diy_k_qice_skill.getTurnUseCard = function(self,inclusive)
	if #self.toUse>2 then return end
	local ids = self.player:handCards()
	local canCs = {}
	for _,pn in ipairs(patterns())do
		local dc = dummyCard(pn)
		if dc and dc:isNDTrick() then
			dc:addSubcards(ids)
			dc:setSkillName("diy_k_qice")
			if dc:isAvailable(self.player)
			then table.insert(canCs,dc) end
		end
	end
	ids = sgs.QList2Table(ids)
	self:sortByUseValue(canCs)
	sgs.ai_use_priority.diy_k_qice = 4-#ids
	if #ids<3 then
		for _,c in ipairs(canCs)do
			if c:isKindOf("AOE") then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return sgs.Card_Parse("#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if c:targetFixed() and not c:isDamageCard()
			and self:getCardsNum("Jink,Peach")<1 then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return sgs.Card_Parse("#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
	end
	if #ids==3 then
		for _,c in ipairs(canCs)do
			if c:isKindOf("AOE") then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return sgs.Card_Parse("#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if c:isKindOf("GlobalEffect")
			and self.player:isWounded() then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return sgs.Card_Parse("#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if c:targetFixed() and not c:isDamageCard()
			and self:getCardsNum("Jink,Peach,Analeptic,Nullification")<1 then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return sgs.Card_Parse("#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
	end
	local caocao = self.room:findPlayerBySkillName("jianxiong")
	for _,c in ipairs(canCs)do
		if c:isKindOf("AOE")
		and caocao and caocao:getHp()>1
		and self:getAoeValue(c)>-5 and self:isFriend(caocao) and not self:willSkipPlayPhase(caocao)
		and not self.player:hasSkill("jueqing") and self:aoeIsEffective(c,caocao,self.player) then
			local d = self:aiUseCard(c)
			if d.card then
				self.qice_to = d.to
				return sgs.Card_Parse("#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
			end
		end
	end
	if #ids<=3
	and self:getCardsNum("Jink,Peach,Analeptic,Nullification")<1 then
		for _,c in ipairs(canCs)do
			if c:isKindOf("GlobalEffect")
			and self.player:isWounded() then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return sgs.Card_Parse("#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
		for _,c in ipairs(canCs)do
			if c:targetFixed() and not c:isDamageCard() then
				local d = self:aiUseCard(c)
				if d.card then
					self.qice_to = d.to
					return sgs.Card_Parse("#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
				end
			end
		end
	end
	for _,c in ipairs(canCs)do
		local d = self:aiUseCard(c)
		if d.card and c:isDamageCard()
		and self:getUseValue(c)>#ids*2.1 then
			self.qice_to = d.to
			return sgs.Card_Parse("#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
		end
	end
	for _,c in ipairs(canCs)do
		local d = self:aiUseCard(c)
		if d.card and self:getUseValue(c)>#ids*2.6 then
			self.qice_to = d.to
			return sgs.Card_Parse("#diy_k_qice:"..table.concat(ids,"+")..":"..c:objectName())
		end
	end
end

sgs.ai_skill_use_func["#diy_k_qice"] = function(card,use,self)
	return sgs.ai_skill_use_func.QiceCard(card,use,self)
end

sgs.ai_use_priority.diy_k_qice = sgs.ai_use_priority.QiceCard 

sgs.ai_ajustdamage_to.diy_f_mingshi = function(self,from,to,slash,nature)
	if (from:faceUp() and not to:faceUp()) or (not from:faceUp() and to:faceUp())
	then return -1 end
end



sgs.ai_skill_playerchosen.diy_f_lirang = function(self,targets)
	self:sort(self.enemies)
	for _,enemy in ipairs(self.enemies)do
		if self:toTurnOver(enemy,1,"diy_f_lirang") and hasManjuanEffect(enemy) then
			return enemy
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if self:toTurnOver(enemy,1,"diy_f_lirang") and enemy:hasSkills(sgs.priority_skill) then
			return enemy
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if self:toTurnOver(enemy,1,"diy_f_lirang") then
			return enemy
		end
	end
end
sgs.ai_skill_choice["diy_f_lirang"] = function(self, choices, data)
    return "1"
end
sgs.ai_skill_choice["@lirangobtain"] = function(self, choices, data)
    return "yes"
end

sgs.ai_playerchosen_intention.diy_f_lirang = function(self,from,to)
	if hasManjuanEffect(to) then sgs.updateIntention(from,to,80) end
	local intention = 80
	if not self:toTurnOver(to,1) then intention = -intention end
	sgs.updateIntention(from,to,intention)
end



sgs.ai_card_priority.diy_k_fenyin = function(self,card,v)
	if ((self.player:getMark("&".."fenyin".."colorred".."-Clear")> 0 and card:isBlack()) or
	(self.player:getMark("&".."fenyin".."colorblack".."-Clear")> 0 and card:isRed())
	) or self.player:getMark("&fenyinnumber-Clear")==card:getNumber()
	then return 10 end
end



addAiSkills("diy_m_chuifeng").getTurnUseCard = function(self)
	local ts = {"slash","duel", "thunder_slash", "ice_slash", "fire_slash"}
	local cn = ts[math.random(1,2)]
	local dc = dummyCard(cn)
	dc:setSkillName("diy_m_chuifeng")
	sgs.ai_use_priority.diy_m_chuifeng = sgs.ai_use_priority[dc:getClassName()]
	local d = self:aiUseCard(dc)
	if d.card and d.to and not self:isWeak() then
		self.cf_to = d.to
		self.diy_m_chuifengChoice = cn
		return sgs.Card_Parse("#diy_m_chuifeng:.:"..cn) 
	end
end

sgs.ai_skill_use_func["#diy_m_chuifeng"] = function(card,use,self)
	use.card = card
	use.to = self.cf_to
end
sgs.ai_use_value.diy_m_chuifeng = 5.4
sgs.ai_use_priority.diy_m_chuifeng = 2.8

sgs.ai_skill_choice.diy_m_chuifeng = function(self, choices, data)
	return self.diy_m_chuifengChoice
end

sgs.ai_use_revises.diy_m_quedi = function(self,card,use)
	if table.contains(card:getSkillNames(), "diy_m_chuifengg") or table.contains(card:getSkillNames(), "diy_m_chongjian") or table.contains(card:getSkillNames(), "diy_m_choujue") then
		card:setFlags("Qinggang")
	end
end

local diy_m_chongjian_skill={}
diy_m_chongjian_skill.name="diy_m_chongjian"
table.insert(sgs.ai_skills,diy_m_chongjian_skill)
diy_m_chongjian_skill.getTurnUseCard = function(self)
	local cards = self:addHandPile("he")
	self:sortByUseValue(cards,true)
	for _,card in sgs.list(cards)do
		if card:isKindOf("OffensiveHorse") and self:slashIsAvailable() then
			return sgs.Card_Parse(("fire_slash:diy_m_chongjian[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getId()))
		elseif card:isKindOf("Treasure") and self:slashIsAvailable() then
			return sgs.Card_Parse(("ice_slash:diy_m_chongjian[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getId()))
		elseif card:isKindOf("DefensiveHorse") and self:slashIsAvailable() then
			return sgs.Card_Parse(("thunder_slash:diy_m_chongjian[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getId()))
		elseif card:isKindOf("Weapon") and self:slashIsAvailable() then
			return sgs.Card_Parse(("slash:diy_m_chongjian[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getId()))
		elseif card:isKindOf("Armor") and self:slashIsAvailable() then
			return sgs.Card_Parse(("analeptic:diy_m_chongjian[%s:%s]=%d"):format(card:getSuitString(),card:getNumberString(),card:getId()))
		end
	end
end
sgs.ai_card_priority.diy_m_chongjian = function(self,card,v)
	if table.contains(card:getSkillNames(), "diy_m_chongjian")
	then return 5 end
end

sgs.ai_view_as.diy_m_chongjian = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceSpecial then return end
	if card:isKindOf("OffensiveHorse") then
		return ("fire_slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id)
	elseif card:isKindOf("DefensiveHorse") then
		return ("thunder_slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id)
	elseif card:isKindOf("Treasure") then
		return ("ice_slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id)
	elseif card:isKindOf("Weapon") then
		return ("slash:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id)
	elseif card:isKindOf("Armor") then
		return ("analeptic:diy_m_chongjian[%s:%s]=%d"):format(suit,number,card_id)
	end
end


addAiSkills("diy_m_jichou").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if self.player:getMark("diy_m_jichou"..c:objectName().."-Clear")>0 then continue end
		if c and c:isNDTrick() and c:isAvailable(self.player) then
			c:setSkillName("diy_m_jichou")
			local d = self:aiUseCard(c)
			if d.card then
				if c:canRecast() and d.to:length()<1 then continue end
				return c:toString()
			end
		end
	end
end
sgs.ai_card_priority.diy_m_jichou = function(self,card,v)
	if table.contains(card:getSkillNames(), "diy_m_jichou")
	then return 5 end
end
sgs.ai_guhuo_card.diy_m_jichou = function(self,toname,class_name)
	if self.player:getMark("diy_m_jichou"..toname.."-Clear")<1 then
		local cards = self.player:getCards("he")
		cards = self:sortByKeepValue(cards)
        for _,c in sgs.list(cards)do
			if c and c:isNDTrick() and c:isKindOf(class_name) then 
				c:setSkillName("diy_m_jichou")
				return c:toString()
			end
		end
	end
end


addAiSkills("diy_m_jilun").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
  	for _,c in sgs.list(cards)do
		if self.player:getMark("diy_m_jilun"..c:objectName().."-Clear")>0 then continue end
		if self.player:getMark("diy_m_jichou"..c:objectName().."-Clear")>0 then
			if c and c:isNDTrick() and c:isAvailable(self.player) then
				c:setSkillName("diy_m_jilun")
				local d = self:aiUseCard(c)
				if d.card then
					if c:canRecast() and d.to:length()<1 then continue end
					return c:toString()
				end
			end
		end
	end
end
sgs.ai_card_priority.diy_m_jilun = function(self,card,v)
	if table.contains(card:getSkillNames(), "diy_m_jilun")
	then return 4 end
end

sgs.ai_guhuo_card.diy_m_jilun = function(self,toname,class_name)
	if self.player:getMark("diy_m_jichou"..toname.."-Clear")>0 and self.player:getMark("diy_m_jilun"..toname.."-Clear")<1 then
		local cards = self.player:getCards("he")
		cards = self:sortByKeepValue(cards)
        for _,c in sgs.list(cards)do
			if c and c:isNDTrick() and c:isKindOf(class_name) then 
				c:setSkillName("diy_m_jilun")
				return c:toString()
			end
		end
	end
end

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



local diy_zuguangu_skill = {}
diy_zuguangu_skill.name = "diy_zuguangu"
table.insert(sgs.ai_skills, diy_zuguangu_skill)
diy_zuguangu_skill.getTurnUseCard = function(self, inclusive)
    return sgs.Card_Parse("#diy_zuguangu:.:")
end

sgs.ai_skill_use_func["#diy_zuguangu"] = function(card,use,self)
	if self.player:getChangeSkillState("diy_zuguangu") == 1 then
		local max = math.min(4, self.room:getDrawPile():length())
    	if max <= 0 then return end
		for i = 1, max, 1 do
			local cards = {}
			for j = 0, i - 1, 1 do
				local cc = sgs.Sanguosha:getCard(self.room:getDrawPile():at(j))
				local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
				if cc:isKindOf("Slash") then num = 1 end
				if num == i then
					table.insert(cards, cc)
				end
			end
			if #cards > 0 then
				self:sortByUseValue(cards)
				for _,cc in ipairs(cards) do
					if cc:isKindOf("BasicCard") or cc:isNDTrick() then
						local dummy_use = self:aiUseCard(cc, dummy(true))
						if dummy_use.card then
							use.card = card
							return 
						end
					end
				end
			end
		end
	else
		local all = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(all, "defense")
		for _,p in ipairs(all) do
			if (not self:isFriend(p)) and (not p:isKongcheng()) then
				local cards = sgs.QList2Table(p:getHandcards())
				self:sortByUseValue(cards)
				local max = p:getHandcardNum()
				for _,cc in ipairs(cards) do
					local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
					if cc:isKindOf("Slash") then num = 1 end
					if num > 4 or num > max then continue end
					if cc:isKindOf("BasicCard") or cc:isNDTrick() then
						local dummy_use = self:aiUseCard(cc, dummy(true))
						if dummy_use.card then
							use.card = card
							self.diy_zuguangu = p
							--if use.to then use.to:append(p) end
							return 
						end
					end
				end
			end
		end
	end
end

sgs.ai_use_priority.diy_zuguangu = 8
sgs.ai_use_value.diy_zuguangu = 8


sgs.ai_skill_playerchosen.diy_zuguangu = function(self,targets)
	if self.diy_zuguangu then return self.diy_zuguangu end
	targets = sgs.QList2Table(targets)
	for _,p in ipairs(targets) do
		if (not self:isFriend(p)) and (not p:isKongcheng()) then
			local cards = sgs.QList2Table(p:getHandcards())
			self:sortByUseValue(cards)
			local max = p:getHandcardNum()
			for _,cc in ipairs(cards) do
				local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
				if cc:isKindOf("Slash") then num = 1 end
				if num > 4 or num > max then continue end
				if cc:isKindOf("BasicCard") or cc:isNDTrick() then
					local dummy_use = self:aiUseCard(cc, dummy(true))
					if dummy_use.card then
						return p
					end
				end
			end
		end
	end
	for _,p in ipairs(targets) do
		if not p:isKongcheng() and self:isEnemy(p) then
			return p
		end
	end
end

sgs.ai_skill_choice.diy_zuguangunum = function(self, choices)
    if not self.diy_zuguangu then
        if self.player:getHp() == 1 and self.player:isWounded() then
            local card = sgs.Sanguosha:getCard(self.room:getDrawPile():at(0))
            if card:isKindOf("Peach") then return tostring(1) end
            return tostring(4)
        end
        local max = math.min(4, self.room:getDrawPile():length())
        if max <= 0 then return end
    
        for i = 1, max, 1 do
            local cards = {}
            for j = 0, i - 1, 1 do
                local cc = sgs.Sanguosha:getCard(self.room:getDrawPile():at(j))
                local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
                if cc:isKindOf("Slash") then num = 1 end
				if self.player:getMark("diy_zuxiaoyong-"..num.."-Clear") > 0 then continue end
                if num == i then
                    table.insert(cards, cc)
                end
            end
            if #cards > 0 then
                self:sortByUseValue(cards)
                for _,cc in ipairs(cards) do
					if cc:isKindOf("BasicCard") or cc:isNDTrick() then
						local dummy_use = self:aiUseCard(cc, dummy(true))
						if dummy_use.card then
							return tostring(i)
						end
					end
                end
            end
        end
    else
		local target = self.diy_zuguangu
        local cards = sgs.QList2Table(target:getHandcards())
        self:sortByUseValue(cards)
        local max = target:getHandcardNum()
        for _,cc in ipairs(cards) do
            local num = utf8len(sgs.Sanguosha:translate(cc:objectName()))
            if cc:isKindOf("Slash") then num = 1 end
            if num > 4 or num > max then continue end
            if self.player:getMark("diy_zuxiaoyong-"..num.."-Clear") > 0 then continue end
			if cc:isKindOf("BasicCard") or cc:isNDTrick() then
				local dummy_use = self:aiUseCard(cc, dummy(true))
				if dummy_use.card then
					return tostring(num)
				end
			end
        end
    end
    return tostring(4)
end

sgs.ai_skill_askforag.diy_zuguangu = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("BasicCard") or card:isNDTrick() then
			local num = utf8len(sgs.Sanguosha:translate(card:objectName()))
			if card:isKindOf("Slash") then num = 1 end
			if self.player:getMark("diy_zuxiaoyong-"..num.."-Clear") == 0 and num == self.player:getMark("&diy_zuguangu") then
				local dummy_use = self:aiUseCard(card, dummy())
				if card:isAvailable(self.player) and dummy_use.card then
					if card:canRecast() and dummy_use.to:length()<1 then continue end
					return id
				end
			end
		end
	end
	for _,id in ipairs(card_ids)do
		local card = sgs.Sanguosha:getCard(id)
		if card:isKindOf("BasicCard") or card:isNDTrick() then
			local dummy_use = self:aiUseCard(card, dummy())
			if card:isAvailable(self.player) and dummy_use.card then
				if card:canRecast() and dummy_use.to:length()<1 then continue end
				return id
			end
		end
	end
end

sgs.ai_skill_use["@@diy_zuguangu"] = function(self, prompt)
	local pattern = self.player:property("diy_zuguangu"):toString()
	local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
    card:setSkillName("diy_zuguangu")
    card:deleteLater()
    local dummy_use = self:aiUseCard(card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, to:objectName())
            end
            return card:toString()..":->"..table.concat(tos, "+")
        else
            return card:toString()
        end
    end
end

sgs.ai_card_priority.diy_zuxiaoyong = function(self,card,v)
	local n, m = utf8len(sgs.Sanguosha:translate(card:objectName())), self.player:getMark("&diy_zuguangu")
	if self.player:getMark("diy_zuxiaoyong-"..m.."-Clear") < 1 and n == m
	then return 10 end
end

sgs.ai_skill_playerchosen.mjin_buchen = function(self,targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			return p
		end
	end
	return targets:first()
end
sgs.ai_playerchosen_intention.mjin_buchen = -40


local mjin_xiongzhi_skill = {}
mjin_xiongzhi_skill.name = "mjin_xiongzhi"
table.insert(sgs.ai_skills,mjin_xiongzhi_skill)
mjin_xiongzhi_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#mjin_xiongzhi:.:")
end

sgs.ai_skill_use_func["#mjin_xiongzhi"] = function(card,use,self)
	if self.player:getMark("&mjin_quanbian-PlayClear") + 1 >= self.player:getMaxHp() then 
		sgs.ai_use_priority.mjin_xiongzhi = 10
		use.card = card
	end
	local list = self.room:getNCards(1,false)
	self.room:returnToTopDrawPile(list)
	local use_num = 0
	for _,id in sgs.qlist(list)do
		local card = sgs.Sanguosha:getCard(id)
		if not self.player:canUse(card) then break end
		if self:willUse(self.player,card)
		then use_num = use_num+1
		else break end
	end
	if use_num>0 then
		use.card = card
	end
end

sgs.ai_use_priority.mjin_xiongzhi = 0

sgs.ai_card_priority.mjin_xiongzhi = function(self,card,v)
	if self.player:getMark("&mjin_quanbian-PlayClear") + 1 >= self.player:getMaxHp() then 
		sgs.ai_use_priority.mjin_xiongzhi = 10
		if table.contains(card:getSkillNames(), "mjin_xiongzhi") then
			return 10 
		end
	end
end


sgs.ai_skill_use["@@mjin_xiongzhi"] = function(self,prompt,method)
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, card in ipairs(cards) do
		if card:hasFlag("mjin_xiongzhi") then
			local dummy = self:aiUseCard(card)
			if dummy.card and dummy.to then
				local tos = {}
				for _,p in sgs.qlist(dummy.to)do
					table.insert(tos,p:objectName())
				end
				return card:toString().."->"..table.concat(tos,"+")
			end
		end
	end
	return "."
end
sgs.ai_skill_invoke.mjin_quanbian = true


sgs.ai_skill_use["@@rushB_baobian_shensu1"] = function(self,prompt)
	local card_str = sgs.ai_skill_use["@@shensu1"](self,prompt)
	if not card_str or card_str=="." then return "." end
	return string.gsub(card_str,"@ShensuCard=","#rushB_baobian_shensu:") ..":"
end

sgs.ai_skill_use["@@rushB_baobian_shensu2"] = function(self,prompt)
	local card_str = sgs.ai_skill_use["@@shensu2"](self,prompt,method)
	if not card_str or card_str=="." then return "." end
	return string.gsub(card_str,"@ShensuCard=","#rushB_baobian_shensu:") ..":"
end

sgs.ai_skill_use["@@rushB_baobian_shensu3"] = function(self,prompt)
	self:sort(self.enemies,"defense")
	if self:needBear() then return "." end
	local selfSub = self:getOverflow()
	local selfDef = sgs.getDefense(self.player)
	for _,enemy in ipairs(self.enemies)do
		local def = self:getDefenseSlash(enemy)
		local slash = dummyCard()
		slash:setSkillName("_rushB_baobian_shensu")
		local eff = self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash)

		if not self.player:canSlash(enemy,slash,false) then
		elseif self:slashProhibit(nil,enemy) then
		elseif def<6 and eff then return "#rushB_baobian_shensu:.:->"..enemy:objectName()

		elseif selfSub>=2 then return "#rushB_baobian_shensu:.:->"..enemy:objectName()
		elseif selfDef<6 then return "." end
	end

	for _,enemy in ipairs(self.enemies)do
		local def=sgs.getDefense(enemy)
		local slash = dummyCard()
		slash:setSkillName("_rushB_baobian_shensu")
		local eff = self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash)

		if not self.player:canSlash(enemy,slash,false) then
		elseif self:slashProhibit(nil,enemy) then
		elseif eff and def<8 then return "#rushB_baobian_shensu:.:->"..enemy:objectName()
		else return "." end
	end
	return "."
end

sgs.ai_skill_use_func["#rushB_baobian_tiaoxin"] = function(card,use,self)
	local distance = use.DefHorse and 1 or 0
	local targets = {}
	for _,enemy in ipairs(self.enemies)do
		if self:doDisCard(enemy,"he") and self:isTiaoxinTarget(enemy)
		then table.insert(targets,enemy) end
	end

	if #targets==0 then return end

	sgs.ai_use_priority.rushB_baobian_tiaoxin = 8
	if not self.player:getArmor() and not self.player:isKongcheng() then
		for _,c in sgs.qlist(self.player:getCards("h"))do
			if c:isKindOf("Armor") and self:evaluateArmor(c)>3 then
				sgs.ai_use_priority.rushB_baobian_tiaoxin = 5.9
				break
			end
		end
	end

	self:sort(targets,"defenseSlash")
	use.to:append(targets[1])
	use.card = card
end

sgs.ai_card_intention.rushB_baobian_tiaoxin = sgs.ai_card_intention.TiaoxinCard
sgs.ai_use_priority.rushB_baobian_tiaoxin = sgs.ai_use_priority.TiaoxinCard

addAiSkills("rushB_baobian").getTurnUseCard = function(self)

  	if self.player:getHp() > getBestHp(self.player) then
		return sgs.Card_Parse("#rushB_baobian:.:")
	end
	if self.player:getHp() <= 3 then
		local cards = self.player:getCards("h")
		cards = self:sortByKeepValue(cards)
		if #cards>0 then
			return sgs.Card_Parse("#rushB_baobian_tiaoxin:"..cards[1]:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#rushB_baobian"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.rushB_baobian = 9.4
sgs.ai_use_priority.rushB_baobian = 0.8

sgs.ai_getBestHp_skill.rushB_baobian = function(owner)
	return math.max(1, owner:getMaxHp() - 3)
end


local rushB_dimeng_skill = {}
rushB_dimeng_skill.name = "rushB_dimeng"
table.insert(sgs.ai_skills, rushB_dimeng_skill)
rushB_dimeng_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	return sgs.Card_Parse("#rushB_dimeng:.:")
end
function DimengIsWorth(self, friend, enemy, mycards, myequips)
	local e_hand1, e_hand2 = enemy:getHandcardNum(), enemy:getHandcardNum() - self:getLeastHandcardNum(enemy)
	local f_hand1, f_hand2 = friend:getHandcardNum(), friend:getHandcardNum() - self:getLeastHandcardNum(friend)
	local e_peach, f_peach = getCardsNum("Peach", enemy), getCardsNum("Peach", friend)
	if e_hand1 < f_hand1 then
		return false
	elseif e_hand2 <= f_hand2 and e_peach <= f_peach then
		return false
	elseif e_peach < f_peach and e_peach < 1 then
		return false
	elseif e_hand1 == f_hand1 and e_hand1 > 0 then
		return hasTuntianEffect(friend, true)
	end
	local cardNum = #mycards
	local delt = e_hand1 - f_hand1 --assert: delt>0
	if delt > cardNum then
		return false
	end
	local equipNum = #myequips
	if equipNum > 0 then
		if self.player:hasSkills("xuanfeng|xiaoji|nosxuanfeng") then
			return true
		end
	end
	--now e_hand1>f_hand1 and delt<=cardNum
	local soKeep = 0
	local soUse = 0
	local marker = math.ceil(delt / 2)
	for i=1, delt, 1 do
		local card = mycards[i]
		local keepValue = self:getKeepValue(card)
		if keepValue > 4 then
			soKeep = soKeep + 1
		end
		local useValue = self:getUseValue(card)
		if useValue >= 6 then
			soUse = soUse + 1
		end
	end
	if soKeep > marker then
		return false
	end
	if soUse > marker then
		return false
	end
	return true
end

local dimeng_discard = function(self, discard_num, mycards)
	local cards = mycards
	local to_discard = {}

	local aux_func = function(card)
		local place = self.room:getCardPlace(card:getEffectiveId())
		if place == sgs.Player_PlaceEquip then
			if card:isKindOf("SilverLion") and self.player:isWounded() then return -2
			elseif card:isKindOf("OffensiveHorse") then return 1
			elseif card:isKindOf("Weapon") then return 2
			elseif card:isKindOf("DefensiveHorse") then return 3
			elseif card:isKindOf("Armor") then return 4
			end
		elseif self:getUseValue(card) >= 6 then return 3
		elseif self:hasSkills(sgs.lose_equip_skill) then return 5
		else return 0
		end
		return 0
	end

	local compare_func = function(a, b)
		if aux_func(a) ~= aux_func(b) then
			return aux_func(a) < aux_func(b)
		end
		return self:getKeepValue(a) < self:getKeepValue(b)
	end

	table.sort(cards, compare_func)
	for _, card in ipairs(cards) do
		if not self.player:isJilei(card) then table.insert(to_discard, card:getId()) end
		if #to_discard >= discard_num then break end
	end
	if #to_discard ~= discard_num then return {} end
	return to_discard
end

sgs.ai_skill_use_func["#rushB_dimeng"] = function(card,use,self)
	local mycards = {}
	local myequips = {}
	local keepaslash
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if not self.player:isJilei(c) then
			local shouldUse
			if not keepaslash and isCard("Slash", c, self.player) then
				local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
				self:useBasicCard(c, dummy_use)
				if dummy_use.card and not dummy_use.to:isEmpty() and (dummy_use.to:length() > 1 or dummy_use.to:first():getHp() <= 1) then
					shouldUse = true
				end
			end
			if not shouldUse then table.insert(mycards, c) end
		end
	end
	for _, c in sgs.qlist(self.player:getEquips()) do
		if not self.player:isJilei(c) then
			table.insert(mycards, c)
			table.insert(myequips, c)
		end
	end
	if #mycards == 0 then return end
	self:sortByKeepValue(mycards) --�ҵ�keepValue��5��useValue��6��˳��ǣ���keepValue��1.9��useValue��9

	self:sort(self.enemies,"handcard")
	local friends = {}
	for _, player in ipairs(self.friends_noself) do
		if not hasManjuanEffect(player) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return end

	self:sort(friends, "defense")
	local function cmp_HandcardNum(a, b)
		local x = a:getHandcardNum() - self:getLeastHandcardNum(a)
		local y = b:getHandcardNum() - self:getLeastHandcardNum(b)
		return x < y
	end
	table.sort(friends, cmp_HandcardNum)

	self:sort(self.enemies, "defense")
	for _,enemy in ipairs(self.enemies) do
		if hasManjuanEffect(enemy) then
			local e_hand = enemy:getHandcardNum()
			for _, friend in ipairs(friends) do
				local f_peach, f_hand = getCardsNum("Peach", friend), friend:getHandcardNum()
				if (e_hand > f_hand - 1) and (e_hand - f_hand) <= #mycards and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
					if e_hand == f_hand then
						use.card = card
					else
						local discard_num = e_hand - f_hand
						local discards = dimeng_discard(self, discard_num, mycards)
						if #discards > 0 then use.card = sgs.Card_Parse("#rushB_dimeng:.:") end
					end
					if use.card and use.to then
						use.to:append(enemy)
						use.to:append(friend)
					end
					return
				end
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		local e_hand = enemy:getHandcardNum()
		for _, friend in ipairs(friends) do
			local f_hand = friend:getHandcardNum()
			if DimengIsWorth(self, friend, enemy, mycards, myequips) and (e_hand > 0 or f_hand > 0) then
				if e_hand == f_hand then
					use.card = card
				else
					local discard_num = math.abs(e_hand - f_hand)
					local discards = dimeng_discard(self, discard_num, mycards)
					if #discards > 0 then use.card = sgs.Card_Parse("#rushB_dimeng:.:") end
				end
				if use.to then
					use.to:append(enemy)
					use.to:append(friend)
					end
				return
			end
		end
	end
end

sgs.ai_card_intention["#rushB_dimeng"] = function(self,card, from, to)
	local compare_func = function(a, b)
		return a:getHandcardNum() < b:getHandcardNum()
	end
	table.sort(to, compare_func)
	if to[1]:getHandcardNum() < to[2]:getHandcardNum() then
		sgs.updateIntention(from, to[1], -80)
	end
end

sgs.ai_use_value["#rushB_dimeng"] = 3.5
sgs.ai_use_priority["#rushB_dimeng"] = 2.8

sgs.dynamic_value.control_card["#rushB_dimeng"] = true

addAiSkills("rushB_diaogui").getTurnUseCard = function(self)

	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		if c:isKindOf("EquipCard") then
			return sgs.Card_Parse("#rushB_diaogui:"..c:getEffectiveId()..":")
		end
	end
end
sgs.ai_skill_use_func["#rushB_diaogui"] = function(card,use,self)
	local max_friends = 0
    local best_target = nil
    
    -- 遍历所有其他玩家
    for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
        local temp_friends = 0
        
        -- 模拟交换位置后的情况
        local simulated_next = p:getNextAlive()
        local simulated_prev = p:getNextAlive(self.room:alivePlayerCount() - 1)
        
        -- 检查交换后的上家是否为队友
        if self.player:isYourFriend(simulated_prev) then
            temp_friends = temp_friends + 1
        end
        
        -- 检查交换后的下家是否为队友
        if self.player:isYourFriend(simulated_next) then
            temp_friends = temp_friends + 1
        end
        
        -- 更新最大值
        if temp_friends > max_friends then
            max_friends = temp_friends
            best_target = p
        end
    end
	if best_target then
		use.card = card
		use.to:append(best_target)
	end
end

sgs.ai_use_priority["#rushB_diaogui"] = 5

addAiSkills("mmou_leiji").getTurnUseCard = function(self)
	return sgs.Card_Parse("#mmou_leiji:.:")
end

sgs.ai_skill_use_func["#mmou_leiji"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if self:damageIsEffective(ep, sgs.DamageStruct_Thunder, self.player) and self:canDamage(ep,self.player,nil) then 
			use.card = card
			use.to:append(ep)
			return
		end
	end
end

addAiSkills("mmou_guidao").getTurnUseCard = function(self)
	return sgs.Card_Parse("#mmou_guidao:.:")
end

sgs.ai_skill_use_func["#mmou_guidao"] = function(card,use,self)
	use.card = card
end

sgs.ai_skill_cardask["@rushB_wushuang-slash"] = function(self,data,pattern,target)
	local use = data:toCardUse()
	local effect = sgs.CardEffectStruct()
	effect.card = use.card
	effect.from = use.from
	effect.to = self.player
	local _data = sgs.QVariant()
	_data:setValue(effect)
	if sgs.ai_skill_cardask["duel-slash"](self,_data,pattern,use.from) == "." then return "." end
	if self:getCardsNum("Slash")<3 then
		return "."
	end
	return true
end


sgs.ai_skill_cardask["@rushB_wushuang-jink"] = function(self,data,pattern,target)
	local use = data:toCardUse()
	local effect = sgs.CardEffectStruct()
	effect.card = use.card
	effect.from = use.from
	effect.to = self.player
	local _data = sgs.QVariant()
	_data:setValue(effect)
	local slash = self.room:getTag("SlashData"):toCardEffect()
	if slash and slash.offset_num > 1 then
		if sgs.ai_skill_cardask["@multi-jink-start"](self,data,"jink",data:toCardEffect().from, nil, slash.offset_num) == "." then return "." end
	end
	return sgs.ai_skill_cardask["slash-jink"](self,data,"jink",data:toCardEffect().from)
end


sgs.ai_skill_use["@rushB_huace"] = function(self, prompt)
	local c = sgs.Sanguosha:getEngineCard(self.player:getMark("rushB_huaceName"))
	local card = sgs.Sanguosha:cloneCard(c:objectName())
    card:setSkillName("rushB_huace")
    local dummy_use = self:aiUseCard(card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, to:objectName())
            end
            return dummy_use.card:toString()..":->"..table.concat(tos, "+")
        else
            return dummy_use.card:toString()
        end
    end
	return "."
end


addAiSkills("rushB_huace").getTurnUseCard = function(self)
	self.rushB_huace = nil
	local huaces = {}
	for _, id in sgs.qlist(self.room:getDiscardPile()) do
		local c = sgs.Sanguosha:getEngineCard(id)
		if (c:isKindOf("BasicCard") or c:isNDTrick()) and not (c:isKindOf("Suijiyingbian") or c:isKindOf("Jink") or c:isKindOf("Nullification") or c:isKindOf("FczhizheBasic") or c:isKindOf("FczhizheTrick") or c:isKindOf("KezhuanYing") or c:isKindOf("BigJoker") or c:isKindOf("SmallJoker")) then
			if not table.contains(huaces, c:objectName()) and self.player:getMark("rushB_huace"..c:objectName().."-PlayClear") < 1 then table.insert(huaces, c:objectName()) end
		end
	end
	if #huaces > 0 then
		for _, pn in sgs.list(RandomList(huaces)) do
			local dc = dummyCard(pn)
			dc:setSkillName("rushB_huace")
			local dummy_use = self:aiUseCard(dc, dummy())
			if dc:isAvailable(self.player) and dummy_use.card then
				if dc:canRecast() and dummy_use.to:length()<1 then continue end
				self.rushB_huace = pn
				sgs.ai_use_priority.rushB_huace = sgs.ai_use_priority[dc:getClassName()]
				local card = sgs.Card_Parse("#rushB_huace:.:")
				assert(card)
				return card
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local huaces = {}
	for _, id in sgs.qlist(self.room:getDrawPile()) do
		local c = sgs.Sanguosha:getEngineCard(id)
		if (c:isKindOf("BasicCard") or c:isNDTrick()) and not (c:isKindOf("Suijiyingbian") or c:isKindOf("Jink") or c:isKindOf("Nullification") or c:isKindOf("FczhizheBasic") or c:isKindOf("FczhizheTrick") or c:isKindOf("KezhuanYing") or c:isKindOf("BigJoker") or c:isKindOf("SmallJoker")) then
			if not table.contains(huaces, c:objectName()) and self.player:getMark("rushB_huace"..c:objectName().."-PlayClear") < 1 then table.insert(huaces, c:objectName()) end
		end
	end
	for _,c in sgs.list(cards)do
		for _, pn in sgs.list(RandomList(huaces)) do
			local dc = dummyCard(pn)
			dc:setSkillName("rushB_huace")
			dc:addSubcard(c)
			local dummy_use = self:aiUseCard(dc, dummy())
			if dc:isAvailable(self.player) and dummy_use.card then
				if dc:canRecast() and dummy_use.to:length()<1 then continue end
				self.rushB_huace = pn
				sgs.ai_use_priority.rushB_huace = sgs.ai_use_priority[dc:getClassName()]
				local card = sgs.Card_Parse("#rushB_huace:"..c:getEffectiveId() ..":")
				assert(card)
				return card
			end
		end
	end
end

sgs.ai_skill_use_func["#rushB_huace"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.rushB_huace = 5.4
sgs.ai_use_priority.rushB_huace = 2.8

sgs.ai_skill_choice.rushB_huace = function(self, choices, data)
	if self.rushB_huace then return self.rushB_huace end
	local items = choices:split("+")
	for _, pn in sgs.list(RandomList(items)) do
		local dc = dummyCard(pn)
		dc:setSkillName("rushB_huace")
		local dummy_use = self:aiUseCard(dc, dummy())
		if dc:isAvailable(self.player) and dummy_use.card then
			if dc:canRecast() and dummy_use.to:length()<1 then continue end
			return pn
		end
	end
end

addAiSkills("rushB_pizhuan").getTurnUseCard = function(self)
	return sgs.Card_Parse("#rushB_pizhuan:.:")
end

sgs.ai_skill_use_func["#rushB_pizhuan"] = function(card,use,self)
	use.card = card
end


sgs.ai_skill_use["@@rushB_tongbo"] = function(self, prompt)
	local c = sgs.Sanguosha:getEngineCard(self.player:getMark("rushB_tongboName"))
	local card = sgs.Sanguosha:cloneCard(c:objectName())
	card:deleteLater()
    card:setSkillName("_rushB_tongbo")
	--card:addSubcard(self.player:getPile("bookpile"):first())
    local dummy_use = self:aiUseCard(card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, to:objectName())
            end
            return card:toString()..":->"..table.concat(tos, "+")
        else
            return card:toString()
        end
    end
	return "."
end

sgs.ai_skill_choice.rushB_tongbo = function(self, choices, data)
	if self.rushB_tongbo then return self.rushB_tongbo end
	local items = choices:split("+")
	for _, pn in sgs.list(RandomList(items)) do
		local dc = dummyCard(pn)
		dc:setSkillName("rushB_tongbo")
		local dummy_use = self:aiUseCard(dc, dummy())
		if dc:isAvailable(self.player) and dummy_use.card then
			if dc:canRecast() and dummy_use.to:length()<1 then continue end
			return pn
		end
	end
end

addAiSkills("rushB_tongbo").getTurnUseCard = function(self)
	self.rushB_tongbo = nil
	local to_use = {}
	local suits = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	for _, card in ipairs(cards) do
		if not table.contains(suits, card:getSuitString()) then
			table.insert(to_use, card:getId())
			table.insert(suits, card:getSuitString())
			if #to_use == self.player:getPile("bookpile"):length() then break end
		end
	end
	if #to_use < self.player:getPile("bookpile"):length() then
		return
	end
	local choices = {}
	for _,id in sgs.qlist(self.room:getDrawPile()) do
		    local card = sgs.Sanguosha:getEngineCard(id)
			if card:isNDTrick() or card:isKindOf("BasicCard") then
				if table.contains(choices, card:objectName()) or card:isKindOf("Jink") or card:isKindOf("Nullification") then continue end
				local transcard = sgs.Sanguosha:cloneCard(card:objectName())
				transcard:setSkillName("rushB_tongbo")
				transcard:deleteLater()
				if not transcard:isAvailable(self.player) then continue end
				if self.player:getMark("rushB_tongbo".."+"..card:objectName().."-Clear") < 1 then table.insert(choices, card:objectName()) end
			end
			if not self.player:isWounded() then
				table.removeOne(choices, "peach")
			end
			if not sgs.Slash_IsAvailable(self.player) then
				table.removeOne(choices, "slash")
				table.removeOne(choices, "ice_slash")
				table.removeOne(choices, "thunder_slash")
				table.removeOne(choices, "fire_slash")
			end
			if not sgs.Analeptic_IsAvailable(self.player) then
				table.removeOne(choices, "analeptic")
			end
		end
		for _,id in sgs.qlist(self.room:getDiscardPile()) do
		    local card = sgs.Sanguosha:getEngineCard(id)
			if card:isNDTrick() or card:isKindOf("BasicCard") then
				if table.contains(choices, card:objectName()) or card:isKindOf("Jink") or card:isKindOf("Nullification") then continue end
				local transcard = sgs.Sanguosha:cloneCard(card:objectName())
				transcard:setSkillName("rushB_tongbo")
				transcard:deleteLater()
				if not transcard:isAvailable(self.player) then continue end
				if self.player:getMark("rushB_tongbo".."+"..card:objectName().."-Clear") < 1 then table.insert(choices, card:objectName()) end
			end
			if not self.player:isWounded() then
				table.removeOne(choices, "peach")
			end
			if not sgs.Slash_IsAvailable(self.player) then
				table.removeOne(choices, "slash")
				table.removeOne(choices, "ice_slash")
				table.removeOne(choices, "thunder_slash")
				table.removeOne(choices, "fire_slash")
			end
			if not sgs.Analeptic_IsAvailable(self.player) then
				table.removeOne(choices, "analeptic")
			end
		end
	for _, pn in sgs.list(RandomList(choices)) do
		local dc = dummyCard(pn)
		dc:setSkillName("rushB_tongbo")
		dc:addSubcard(self.player:getPile("bookpile"):first())
		local dummy_use = self:aiUseCard(dc, dummy())
		if dc:isAvailable(self.player) and dummy_use.card then
			if dc:canRecast() and dummy_use.to:length()<1 then continue end
			self.rushB_tongbo = pn
			sgs.ai_use_priority.rushB_tongbo = sgs.ai_use_priority[dc:getClassName()]
			local card = sgs.Card_Parse("#rushB_tongbo:".. table.concat(to_use, "+") ..":")
			assert(card)
			return card
		end
	end
	
end

sgs.ai_skill_use_func["#rushB_tongbo"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.rushB_tongbo = 5.4
sgs.ai_use_priority.rushB_tongbo = 2.8


sgs.ai_skill_use["@@rushB_xiongsuan"] = function(self, prompt)
	local c = sgs.Sanguosha:getEngineCard(self.player:getMark("rushB_xiongsuanName"))
	local card = sgs.Sanguosha:cloneCard(c:objectName())
	card:deleteLater()
    card:setSkillName("_rushB_xiongsuan")
    local dummy_use = self:aiUseCard(card, dummy(true))
    if dummy_use.card then
        if dummy_use.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(dummy_use.to) do
                table.insert(tos, to:objectName())
            end
            return card:toString()..":->"..table.concat(tos, "+")
        else
            return card:toString()
        end
    end
	return "."
end
sgs.ai_skill_choice.rushB_xiongsuan = function(self, choices, data)
	local choices = {}
	for _,id in sgs.qlist(sgs.Sanguosha:getRandomCards()) do
		local card = sgs.Sanguosha:getEngineCard(id)
		if card:isKindOf("BasicCard") or card:isNDTrick() then
			if table.contains(choices, card:objectName()) then continue end
			local transcard = sgs.Sanguosha:cloneCard(card:objectName())
			transcard:deleteLater()
			transcard:setSkillName("rushB_xiongsuan")
			if not transcard:isAvailable(self.player) then continue end
			if self.player:getMark("rushB_xiongsuan+"..card:objectName().."-Clear") < 1 then table.insert(choices, card:objectName()) end
		end
	end
	if sgs.ai_skill_choice.rushB_xiongsuanUse(self, table.concat(choices, "+")) ~= "cancel" then
		return "yes"
	end
	return "no"
end
sgs.ai_skill_choice.rushB_xiongsuanUse = function(self, choices, data)
	local items = choices:split("+")
	for _, pn in sgs.list(RandomList(items)) do
		local dc = dummyCard(pn)
		dc:setSkillName("_rushB_xiongsuan")
		local dummy_use = self:aiUseCard(dc, dummy())
		if dc:isAvailable(self.player) and dummy_use.card then
			if dc:canRecast() and dummy_use.to:length()<1 then continue end
			return pn
		end
	end
	return "cancel"
end


addAiSkills("rushB_moutongye").getTurnUseCard = function(self)
	local n = self.player:getChangeSkillState("rushB_moutongye")
	if n == 1 then
		if self:getCardsNum("BasicCard")>self:getCardsNum("TrickCard")+self:getCardsNum("EquipCard") then
			return sgs.Card_Parse("#rushB_moutongye:.:")
		end
	elseif n == 2 then
		if self:getCardsNum("TrickCard")>self:getCardsNum("EquipCard")+self:getCardsNum("BasicCard") then
			return sgs.Card_Parse("#rushB_moutongye:.:")
		end
	elseif n == 3 then
		if self:getCardsNum("EquipCard")>self:getCardsNum("TrickCard")+self:getCardsNum("BasicCard") then
			return sgs.Card_Parse("#rushB_moutongye:.:")
		end
	end
end

sgs.ai_skill_use_func["#rushB_moutongye"] = function(card,use,self)
	use.card = card
end
sgs.ai_use_priority.rushB_moutongye = 10

sgs.ai_card_priority.rushB_xingtu = function(self,card,v)
	if self.player:getMark("&rushB_xingtunum") % card:getNumber() == 0 or card:getNumber() % self.player:getMark("&rushB_xingtunum") == 0
	then return 10 end
end


local rushB_juezhi_skill = {}
rushB_juezhi_skill.name = "rushB_juezhi"
table.insert(sgs.ai_skills,rushB_juezhi_skill)
rushB_juezhi_skill.getTurnUseCard = function(self)
	sgs.ai_use_priority.rushB_juezhi = 3
	if self.player:getCardCount(true)<2 then return false end
	if self:getOverflow()<=0 then return false end
	if self:isWeak() and self:getOverflow()<=1 then return false end
	return sgs.Card_Parse("#rushB_juezhi:.:")
end
sgs.ai_skill_use_func["#rushB_juezhi"] = function(card,use,self)
	local num = self.player:getMark("&rushB_xingtunum")
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)

	for _,c1 in ipairs(cards)do
		local temp = 0
		temp = temp + c1:getNumber()
		for _,c in ipairs(cards)do
			if c1 ~= c then
				if not self.player:isCardLimited(c,sgs.Card_MethodDiscard) and not self.player:isCardLimited(c1,sgs.Card_MethodDiscard) and c1:getNumber() % c:getNumber() == 0 then
					if table.contains(unpreferedCards,c:getId()) then continue end
					if (((temp + c:getNumber()) % num) == 0) then
						temp = temp + c:getNumber()
						table.insert(unpreferedCards,c:getId())
						table.insert(unpreferedCards,c1:getId())
						break
					end
					
				end
				if #unpreferedCards==2 then break end
			end
		end
		if #unpreferedCards==2 then break end
	end

	if #unpreferedCards==2 then
		use.card = sgs.Card_Parse("#rushB_juezhi:"..table.concat(unpreferedCards,"+")..":")
		sgs.ai_use_priority.rushB_juezhi = 0
		return
	end
	for _,c1 in ipairs(cards)do
		for _,c in ipairs(cards)do
			if c1 ~= c then
				if not self.player:isCardLimited(c,sgs.Card_MethodDiscard) and not self.player:isCardLimited(c1,sgs.Card_MethodDiscard) and c1:getNumber() % c:getNumber() == 0 then
					if table.contains(unpreferedCards,c:getId()) then continue end
					table.insert(unpreferedCards,c:getId())
					table.insert(unpreferedCards,c1:getId())
					break
				end
				if #unpreferedCards==2 then break end
			end
		end
		if #unpreferedCards==2 then break end
	end
	use.card = sgs.Card_Parse("#rushB_juezhi:"..table.concat(unpreferedCards,"+")..":")
	sgs.ai_use_priority.rushB_juezhi = 0
	return
end

sgs.ai_use_priority.rushB_juezhi = 3

addAiSkills("sgskanxue").getTurnUseCard = function(self)
	return sgs.Card_Parse("#sgskanxue:.:")
end
sgs.ai_skill_use_func["#sgskanxue"] = function(card,use,self)
	use.card = card
end
sgs.ai_use_priority.sgskanxue = 10

sgs.ai_skill_choice.sgskanxue = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "throwsame") then
		return "throwsame"
	end
	return items[math.random(1, #items)]
end

addAiSkills("sgszhenhua").getTurnUseCard = function(self)
	return sgs.Card_Parse("#sgszhenhua:.:")
end
sgs.ai_skill_use_func["#sgszhenhua"] = function(card,use,self)
	for _,enemy in ipairs(self.enemies)do
		if self:doDisCard(enemy, "he") and enemy:getMark("sgszhenhua-Clear") == 0 then
			use.card = card
			use.to:append(enemy)
			return
		end
	end
end
sgs.ai_use_priority.sgszhenhua = sgs.ai_use_priority.Dismantlement
sgs.ai_skill_playerchosen["sgszhenhua"] = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_invoke.rushB_kanxue = function(self, data)
	return self.player:getHujia() < 5 and self.player:getHp() + self:getAllPeachNum() - 1 > 0
end


sgs.ai_view_as.rushB_kanxue = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
		return ("slash:rushB_kanxue[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local rushB_kanxue_skill = {}
rushB_kanxue_skill.name = "rushB_kanxue"
table.insert(sgs.ai_skills,rushB_kanxue_skill)
rushB_kanxue_skill.getTurnUseCard = function(self,inclusive)
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
	self:sort(self.enemies,"defense")

	for _,card in ipairs(cards)do
		if card:isRed() and not card:isKindOf("Slash") 	and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard())>0)
		then table.insert(red_card,card) end
	end


	for _,card in ipairs(red_card)do
		local slash = dummyCard("slash")
		slash:addSubcard(card)
		slash:setSkillName("rushB_kanxue")
		if slash:isAvailable(self.player)
		then return slash end
	end
end

sgs.ai_skill_invoke.rushB_kanxue_yuqi = true

sgs.ai_skill_use["@@DIT_qianxun!"] = function(self, prompt)
	return "#DIT_qianxun:.:"
end

sgs.ai_skill_choice["@DIT_qianxun"] = function(self, choices, data)
	return "yes"
end


sgs.ai_view_as.DIT_duoshi = function(card, player, card_place)
	local usable_cards = sgs.QList2Table(player:getCards("h"))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(usable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	local two_cards = {}
	for _, c in ipairs(usable_cards) do
		if #two_cards < 2 then
			table.insert(two_cards, c:getEffectiveId())
		end
	end
	if #two_cards == 2 and not card:isKindOf("Jink") then
		return ("jink:DIT_duoshi[%s:%s]=%d+%d"):format("to_be_decided", 0, two_cards[1], two_cards[2])
	end
	if #two_cards == 2 and not card:isKindOf("Slash") then
		return ("slash:DIT_duoshi[%s:%s]=%d+%d"):format("to_be_decided", 0, two_cards[1], two_cards[2])
	end
end


local DIT_duoshi_skill = {}
DIT_duoshi_skill.name = "DIT_duoshi"
table.insert(sgs.ai_skills,DIT_duoshi_skill)
DIT_duoshi_skill.getTurnUseCard = function(self)
	return turnUse_spear(self,"DIT_duoshi")
end

local DIT_if_mouhuoji_skill={}
DIT_if_mouhuoji_skill.name="DIT_if_mouhuoji"
table.insert(sgs.ai_skills,DIT_if_mouhuoji_skill)
DIT_if_mouhuoji_skill.getTurnUseCard=function(self)
	local cards = self:addHandPile("he")
	local card
	self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)do
		if acard:isRed() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard)<sgs.ai_use_value.FireAttack or self:getOverflow()>0) then
			if acard:isKindOf("Slash") and self:getCardsNum("Slash")==1 then
				local keep
				local dummy_use = dummy()
				self:useBasicCard(acard,dummy_use)
				if dummy_use.card and dummy_use.to and dummy_use.to:length()>0 then
					for _,p in sgs.list(dummy_use.to)do
						if p:getHp()<=1 then keep = true break end
					end
					if dummy_use.to:length()>1 then keep = true end
				end
				if keep then sgs.ai_use_priority.Slash = sgs.ai_use_priority.FireAttack+0.1
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
	return sgs.Card_Parse(("fire_attack:DIT_if_mouhuoji[%s:%s]=%d"):format(suit,number,card_id))
end

sgs.ai_skill_cardask["@DIT_if_mouhuoji"] = function(self,data,pattern, target, target2)
	local use = data:toCardUse()
	if (not self:isFriend(target2) or target2:isChained())
		and self:damageIsEffective(target2,use.card) then
		return true
	end
    return "."
end

sgs.ai_skill_choice.DIT_if_mouhuoji = function(self, choices, data)
	return "1"
end

sgs.ai_skill_askforag.DIT_if_mouhuoji = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = sgs.Sanguosha:getCard(id)
		if getCardsNum(card:getSuitString(),self.player,self.player)> 0 then
			return id
		end
	end
end
sgs.ai_cardneed.DIT_if_mouhuoji = function(to,card,self)
	return sgs.ai_cardneed.huoji(to,card,self)
end

sgs.ai_view_as.DIT_if_moukanpo = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceHand or card_place==sgs.Player_PlaceEquip then
		if card:isBlack() then
			return ("nullification:DIT_if_moukanpo[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

sgs.ai_skill_choice.DIT_if_moukanpo = function(self, choices, data)
	return "1"
end

sgs.ai_cardneed.DIT_if_moukanpo = function(to,card,self)
	return sgs.ai_cardneed.kanpo(to,card,self)
end


sgs.ai_skill_invoke.mk_danlveYY = function(self, data)
   	local use = data:toCardUse()
	if use.card:isKindOf("DelayedTrick") or use.card:isKindOf("EquipCard") then return false end
    return true
end
sgs.ai_skill_invoke.mk_danlveQG = function(self, data)
   	local use = data:toCardUse()
	if use.card:isKindOf("DelayedTrick") or use.card:isKindOf("EquipCard") then return false end
    return true
end


addAiSkills("mk_danlve_yinyue").getTurnUseCard = function(self)
	local cs = {}
	for _,id in sgs.list(self.player:getPile("mk_danlve_yinyue"))do
		local card = sgs.Sanguosha:getCard(id)
		card:setSkillName("mk_danlve_yinyue")
		table.insert(cs,card)
	end
	return cs
end

function sgs.ai_cardsview.mk_danlve_yinyue(self,class_name,player)
	for _,id in sgs.list(player:getPile("mk_danlve_yinyue"))do
		if sgs.Sanguosha:getCard(id):isKindOf(class_name) then 
			local card = sgs.Sanguosha:getCard(id)
			card:setSkillName("mk_danlve_yinyue")
			return card:toString() 
		end
	end
end
addAiSkills("mk_danlve_qinggang").getTurnUseCard = function(self)
	local cs = {}
	for _,id in sgs.list(self.player:getPile("mk_danlve_qinggang"))do
		local card = sgs.Sanguosha:getCard(id)
		card:setSkillName("mk_danlve_qinggang")
		table.insert(cs,card)
	end
	return cs
end

function sgs.ai_cardsview.mk_danlve_qinggang(self,class_name,player)
	for _,id in sgs.list(player:getPile("mk_danlve_qinggang"))do
		if sgs.Sanguosha:getCard(id):isKindOf(class_name) then 
			local card = sgs.Sanguosha:getCard(id)
			card:setSkillName("mk_danlve_qinggang")
			return card:toString() 
		end
	end
end

sgs.ai_skill_invoke.mk_kongying = true

sgs.ai_ajustdamage_from.mk_kongying = function(self,from,to,card,nature)
	if card and from:getMark("mk_kongyingJS") == card:getEffectiveId()
	then return 1 end
end

sgs.ai_card_priority.mk_kongying = function(self,card,v)
	if self.player:getMark("&mk_kongying")==1
	and table.contains(card:getSkillNames(), "mk_danlve_qinggang")
	then return 10 end
	if self.player:getMark("&mk_kongying")==0
	and table.contains(card:getSkillNames(), "mk_danlve_yinyue") and self.player:getPile("mk_danlve_qinggang"):length() > 0
	then return 10 end
end

