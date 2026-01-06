
local guandu_shicai_skill = {}
guandu_shicai_skill.name = "guandu_shicai"
table.insert(sgs.ai_skills, guandu_shicai_skill)
guandu_shicai_skill.getTurnUseCard = function(self, inclusive)
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:hasFlag("guandu_shicai") then return end
	end
	local id = self.room:getDrawPile():first()
	if self.player:canDiscard(self.player, "he") and self:getUseValue(sgs.Sanguosha:getCard(id)) >= 5 then
		return sgs.Card_Parse("#guandu_shicai:.:")
	end
end

sgs.ai_skill_use_func["#guandu_shicai"] = function(card, use, self)
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(usable_cards)
	local use_card = {}
	for _,c in ipairs(usable_cards) do
		if self:getUseValue(c) < 5 then
			table.insert(use_card, c)
		end
	end
	if #use_card == 0 then return end
	local card_str = string.format("#guandu_shicai:%s:", use_card[1]:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
end

sgs.ai_use_priority["guandu_shicai"] = 7
sgs.ai_use_value["guandu_shicai"] = 7

sgs.ai_card_priority.guandu_shicai = function(self,card,v)
	if card:hasFlag("guandu_shicai")
	then return 10 end
end

sgs.ai_skill_invoke["chenggong"] = function(self, data)
	local target_name = data:toString():split(":")[2]
	local target = nil
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:objectName() == target_name then
			target = p
		end
	end
	return target and self:isFriend(target)
end

sgs.ai_choicemade_filter.skillInvoke["chenggong"] = function(self, player, promptlist)
    local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1]:split(":")[2]) 
	if target then
		if promptlist[#promptlist] == "yes" then
            
			sgs.updateIntention(player, target, -20)
		else
			sgs.updateIntention(player, target, 20)
		end
	end
end

local gd_zezhu_skill = {}
gd_zezhu_skill.name = "gd_zezhu"
table.insert(sgs.ai_skills, gd_zezhu_skill)
gd_zezhu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#gd_zezhu") then
		return sgs.Card_Parse("#gd_zezhu:.:")
	end
end

sgs.ai_skill_use_func["#gd_zezhu"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local targets = {}
	if self.player:isLord() then
		for _, enemy in ipairs(self.enemies) do
			if (enemy:getEquips():length() > 0 or enemy:getHandcardNum() == 1) and #targets < 2 then
				table.insert(targets, enemy)
			end
		end
	else
		table.insert(targets, self.room:getLord())
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isLord() and (enemy:getEquips():length() > 0 or enemy:getHandcardNum() == 1) and #targets < 2 then
				table.insert(targets, enemy)
			end
		end
	end
	local use_checker = true
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	for _,c in ipairs(handcards) do
		if self:getUseValue(c) < 2 then
			use_checker = false
		end
	end
	if #handcards == 0 then return end
	if #targets == 0 then return end
	if use_checker then return end
	use.card = card
	if use.to then
		for i = 1, #targets, 1 do
			use.to:append(targets[i])
		end
	end
end

sgs.ai_use_priority["gd_zezhu"] = 7
sgs.ai_use_value["gd_zezhu"] = 7

sgs.ai_skill_cardask["@gd_zezhu-give"] = function(self, data, pattern, target, target2)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, true)
	for _,c in ipairs(handcards) do
		return c:toString()
	end
end

sgs.ai_skill_invoke.guandu_hengjiang = sgs.ai_skill_invoke.hengjiang
sgs.ai_choicemade_filter.skillInvoke.guandu_hengjiang = sgs.ai_choicemade_filter.skillInvoke.hengjiang

local guandu_yuanlue_skill = {}
guandu_yuanlue_skill.name = "guandu_yuanlue"
table.insert(sgs.ai_skills, guandu_yuanlue_skill)
guandu_yuanlue_skill.getTurnUseCard = function(self)
	if self.player:isNude() or #self.enemies == 0 or #self.friends_noself == 0 then return end
	local card_id
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, acard in ipairs(cards) do
		if not acard:isKindOf("EquipCard") then
			card_id = acard:getEffectiveId()
			break
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#guandu_yuanlue:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#guandu_yuanlue"] = function(card, use, self)
    if not self.player:isNude() then
        self:sort(self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do
		    if friend and not self:needKongcheng(friend, true) then
				use.card = card
			    if use.to then use.to:append(friend) end
		        return
			end
	    end
	end
	return nil
end

sgs.ai_use_value.guandu_yuanlue = 8.5
sgs.ai_use_priority.guandu_yuanlue = 9.5
sgs.ai_card_intention.guandu_yuanlue = -80
sgs.ai_skill_invoke.guandu_fuyuan = function(self, data)
    local current = self.room:getCurrent()
    if current then
        if current:getHandcardNum() <= self.player:getHandcardNum() then
            return self:canDraw(current, self.player) and self:isFriend(current)
        end
    end
    return true
end
sgs.ai_choicemade_filter.skillInvoke.guandu_fuyuan = function(self, player, promptlist)
    local current = self.room:getCurrent()
    if promptlist[#promptlist] == "yes" then
        if current and current:getHandcardNum() < self.player:getHandcardNum() then
            sgs.updateIntention(player, current, -40)
        end
    end
end

sgs.ai_skill_playerchosen.guandu_zhongjie = function(self,targets)
	local first,second
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense")
	for _,friend in ipairs(targets)do
		if self:isFriend(friend) and friend:isAlive() and self:canDraw(friend, self.player) then
			if isLord(friend) and self:isWeak(friend) then return friend end
			if sgs.ai_role[friend:objectName()]=="renegade" then second = friend
			elseif sgs.ai_role[friend:objectName()]~="renegade" and not first then first = friend
			end
		end
	end
	return first or second
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|guandu_zhongjie"




sgs.ai_skill_cardask["@guandu_jieliang"] = function(self, data, pattern, target)
	local current = self.room:getCurrent()
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(usable_cards)
	if current and self:isEnemy(current) then
		for _, c in ipairs(usable_cards) do
				return c:toString()
		end
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@guandu_jieliang"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, 80)
	end
end
sgs.ai_skill_invoke.guandu_jieliang = true


function SmartAI:useCardYuanjun(card,use)
	self:sort(self.friends,"hp")
	local extraTarget = 1 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.friends_noself)do
		if isCurrent(use,ep) then continue end
		if self.player:canUse(card,ep) then
	    	use.card = card
	    	use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end
sgs.ai_use_priority.Yuanjun = 2.4
sgs.ai_keep_value.Yuanjun = 2.2
sgs.ai_use_value.Yuanjun = 4.7
sgs.ai_card_intention.Yuanjun = -33



function SmartAI:useCardTunliang(card,use)
	self:sort(self.friends,"hp")
	local extraTarget = 2 + sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.friends)do
		if isCurrent(use,ep) then continue end
		if self.player:canUse(card,ep) and self:canDraw(ep, self.player) then
	    	use.card = card
	    	use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end
sgs.ai_use_priority.Tunliang = 2.4
sgs.ai_keep_value.Tunliang = 2.2
sgs.ai_use_value.Tunliang = 4.7
sgs.ai_card_intention.Tunliang = -33



function SmartAI:useCardXujiu(card,use)
	local extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	if card:subcardsLength()+self:getOverflow()>1 and not(self.player:hasEquip(card) or self:isWeak() or self:hasLoseHandcardEffective())
	or card:getEffectiveId()>=0 and self.room:getCardOwner(card:getEffectiveId())~=self.player then 
		for _, enemy in ipairs(self.enemies) do
			if CanToCard(card,self.player,enemy) then
				use.card = card
				if use.to then
					use.to:append(enemy)
				end
				return
			end
		end
	elseif sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_PLAY then
		if sgs.turncount<=1 and self.role=="renegade" and sgs.isLordHealthy() and self:getOverflow()<2
		or self.player:hasFlag("canshi") and self.player:getHandcardNum()<3
		then return end
		local n,cs = 0,{}
		for _,c in ipairs(self:sortByDynamicUsePriority(self:getCards("Slash")))do
			if c:getSubcards():contains(card:getEffectiveId()) then continue end
			self.player:addHistory("Slash",n)
			local can = c:isAvailable(self.player)
			self.player:addHistory("Slash",-n)
			can = can and self:aiUseCard(c)
			if can and can.card then
				table.insert(cs,can)
				n = n+1
			end
		end
		if #cs<1 then return end
		for i,d in ipairs(cs)do
			for _,to in sgs.qlist(d.to)do
				if self:isFriend(to)
				or to:getHandcardNum()>0 and self:getOverflow()<0 and to:hasSkill("anxian")
				or to:hasSkills("zhenlie|mobilejxtpjinjiu")
				then continue end
				if d.card:hasFlag("Qinggang") and to:hasArmorEffect("silver_lion") then
				else
					local da = self:ajustDamage(self.player,to,2,d.card)
					--if da==0 or da==1 then return end
				end
				n = getKnownCard(to,self.player,"Jink",true,"he")
				if n>0 and self:getOverflow()<2
				then continue end
			
				if isCurrent(use,to) then continue end
				if self.player:canUse(card,to) then
					use.card = card
					use.to:append(to)
					if use.to:length()>extraTarget
					then return end
				end
			end
		end
	end
end

sgs.ai_use_value.Xujiu = 5.98
sgs.ai_keep_value.Xujiu = 2.1
sgs.ai_use_priority.Xujiu = 10

sgs.ai_ajustdamage_to["&gd_xujiu"] = function(self,from,to,card,nature)
	return 1
end


sgs.ai_skill_playerchosen.gd_zhanyanliangzhuwenchou = function(self,targets)
	local card = sgs.Sanguosha:cloneCard("Duel", sgs.Card_NoSuit, 0)
	card:setSkillName("gd_zhanyanliangzhuwenchou")
	card:deleteLater()
	if hasZhaxiangEffect(self.player) and not self:isWeak() then return nil end
	targets = sgs.QList2Table(targets)
	local dummy_use = self:aiUseCard(card, dummy())
    if dummy_use.card and dummy_use and dummy_use.to then
		for _,p in sgs.list(dummy_use.to)do
			if table.contains(targets, p) then
				return p
			end
		end
	end
	return targets[1]
end






--英魂
sgs.ai_skill_choice["yinghun_po"] = function(self, choices)
	return self.yinghun_pochoice
end
sgs.ai_skill_playerchosen.yinghun_po = function(self, targets)
	if self.player:hasFlag("AI_doNotInvoke_yinghun") then
		self.player:setFlags("-AI_doNotInvoke_yinghun")
		return
	end
	local x = self.player:getLostHp()
	if self.player:getCards("e"):length() >= self.player:getHp() then x = self.player:getMaxHp()end
	local n = x - 1
	self:updatePlayers()
	if x == 1 and #self.friends == 1 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasSkill("manjuan") then
				return enemy
			end
		end
		return nil
	end

	self.yinghun_po = nil
	local player = self:AssistTarget()

	if x == 1 then
		self:sort(self.friends_noself, "handcard")
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do
			if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards("e"):length() > 0
			  and not friend:hasSkill("manjuan") then
				self.yinghun_po = friend
				break
			end
		end
		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if hasTuntianEffect(friend, true) and not friend:hasSkill("manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if self:needToThrowArmor(friend) and not friend:hasSkill("manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
		if not self.yinghun_po then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasSkill("manjuan") then
					return enemy
				end
			end
		end

		if not self.yinghun_po and player and not player:hasSkill("manjuan") and player:getCardCount(true) > 0 and not self:needKongcheng(player, true) then
			self.yinghun_po = player
		end

		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if friend:getCards("he"):length() > 0 and not friend:hasSkill("manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end

		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:hasSkill("manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
	elseif #self.friends > 1 then
		self:sort(self.friends_noself, "chaofeng")
		for _, friend in ipairs(self.friends_noself) do
			if self:hasSkills(sgs.lose_equip_skill, friend) and friend:getCards("e"):length() > 0
			  and not friend:hasSkill("manjuan") then
				self.yinghun_po = friend
				break
			end
		end
		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if hasTuntianEffect(friend, true) and not friend:hasSkill("manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if self:needToThrowArmor(friend) and not friend:hasSkill("manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
		if not self.yinghun_po and #self.enemies > 0 then
			local wf
			if self.player:isLord() then
				if self:isWeak() and (self.player:getHp() < 2 and self:getCardsNum("Peach") < 1) then
					wf = true
				end
			end
			if not wf then
				for _, friend in ipairs(self.friends_noself) do
					if self:isWeak(friend) then
						wf = true
						break
					end
				end
			end

			if not wf then
				self:sort(self.enemies, "chaofeng")
				for _, enemy in ipairs(self.enemies) do
					if enemy:getCards("he"):length() == n
						and self:doDisCard(enemy, "he", false, n) then
						self.yinghun_pochoice = "yinghun1"
						return enemy
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if enemy:getCards("he"):length() >= n
						and  self:doDisCard(enemy, "he", false, n)
						and self:hasSkills(sgs.cardneed_skill, enemy) then
						self.yinghun_pochoice = "yinghun1"
						return enemy
					end
				end
			end
		end

		if not self.yinghun_po and player and not player:hasSkill("manjuan") and not self:needKongcheng(player, true) then
			self.yinghun_po = player
		end

		if not self.yinghun_po then
			self.yinghun_po = self:findPlayerToDraw(false, n)
		end
		if not self.yinghun_po then
			for _, friend in ipairs(self.friends_noself) do
				if not friend:hasSkill("manjuan") then
					self.yinghun_po = friend
					break
				end
			end
		end
		if self.yinghun_po then self.yinghun_pochoice = "yinghun2" end
	end
	if not self.yinghun_po and x > 1 and #self.enemies > 0 then
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if enemy:getCards("he"):length() >= n
				and self:doDisCard(enemy, "he", false, n) then
				self.yinghun_pochoice = "yinghun1"
				return enemy
			end
		end
		self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isNude()
				and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
				and not self:needToThrowArmor(enemy)
				and not hasTuntianEffect(enemy, true) then
				self.yinghun_pochoice = "yinghun1"
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isNude()
				and not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getCards("e"):length() > 0)
				and not self:needToThrowArmor(enemy)
				and not (hasTuntianEffect(enemy, true) and x < 3 and enemy:getCards("he"):length() < 2) then
				self.yinghun_pochoice = "yinghun1"
				return enemy
			end
		end
	end

	return self.yinghun_po
end

sgs.ai_cardneed.yinghun_po = sgs.ai_cardneed.equip
sgs.need_maxhp_skill = sgs.need_maxhp_skill .. "|yinghun_po"
sgs.need_equip_skill = sgs.need_equip_skill .. "|yinghun_po"

sgs.ai_playerchosen_intention.yinghun_po = function(self,from,to)
	if from:getLostHp()>1 or from:getEquips():length() >= from:getHp() then return end
	local intention = -80
	if to:hasSkill("manjuan") then intention = -intention end
	sgs.updateIntention(from,to,intention)
end

sgs.ai_choicemade_filter.skillChoice.yinghun_po = function(self,player,promptlist)
	local to
	for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
		if p:hasFlag("yinghun_poTarget") then
			to = p
			break
		end
	end
	local choice = promptlist[#promptlist]
	local intention = (choice=="yinghun2") and -80 or 80
	sgs.updateIntention(player,to,intention)
end

sgs.ai_getBestHp_skill.yinghun_po = function(owner)
	return owner:getMaxHp() - 2
end

sgs.ai_fill_skill.heg_xianqu = function(self)
	if #self.enemies == 0 then return nil end
	if self.player:getHandcardNum() < 4 then 
		return sgs.Card_Parse("#heg_xianqu:.::")
	end
	return nil
end

sgs.ai_skill_use_func["#heg_xianqu"] = function(card,use,self)
	self:sort(self.enemies, "handcard")
	for _,enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() then
			use.card = card
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end

sgs.ai_fill_skill.heg_yinyangyu = function(self)
	if self:needBear() then return nil end
	if self:isWeak() and self:getOverflow() <= 0 then 
		return sgs.Card_Parse("#heg_yinyangyu:.::")
	end
	return nil
end

sgs.ai_skill_use_func["#heg_yinyangyu"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority["heg_yinyangyu"] = 10

sgs.ai_skill_invoke.heg_yinyangyu = function(self, data)
	if self:getOverflow() > 1 then
		return true
	end
	return false
end

--已下複製OL解圍並做技能卡修改(去掉棄牌)
sgs.ai_skill_use["@heg_mouduan"] = function(self, prompt, method)
	self:updatePlayers()
	local selectset = {}
	for _,friend in ipairs(self.friends) do
		if friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage") then
			for _,enemy in ipairs(self.enemies) do
				if #selectset == 0 and enemy:getJudgingArea():isEmpty() then
					table.insert(selectset, friend:objectName())
				end
			end
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if not enemy:getEquips():isEmpty() then
			for _, e in ipairs(sgs.QList2Table(enemy:getCards("e"))) do
				local equip_index = e:getRealCard():toEquipCard():location()
				for _,friend in ipairs(self.friends) do
					if #selectset == 0 and friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
						table.insert(selectset, enemy:objectName())
					end
				end
			end
		end
	end
	if #selectset > 0 then
		return "#heg_mouduan:.:->" .. selectset[1]
	end
	return "."
end

sgs.ai_skill_cardchosen["heg_mouduan"] = function(self, who, flags)
	self:updatePlayers()
	if self:isEnemy(who) and flags:match("e") then
		for _, e in ipairs(sgs.QList2Table(who:getCards(flags))) do
			local equip_index = e:getRealCard():toEquipCard():location()
			for _,friend in ipairs(self.friends) do
				if friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
					return e:getEffectiveId()
				end
			end
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.heg_mouduan = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_playerchosen["heg_mouduan"] = function(self, targets)
	local ol_jiewei_target = self.room:getTag("heg_mouduanTarget"):toPlayer()
	local targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	if self:isFriend(ol_jiewei_target) then
		for _,p in ipairs(targets) do
			if self:isEnemy(p) then
				return p
			end
		end
	else
		for _,p in ipairs(targets) do
			if self:isFriend(p) then
				return p
			end
		end
	end
	for _,p in ipairs(targets) do
		return p
	end
end


sgs.double_slash_skill = sgs.double_slash_skill .. "|heg_paoxiao"

sgs.ai_use_revises.heg_paoxiao = function(self,card,use)
	if card:isKindOf("Crossbow")
	then return false end
end
sgs.ai_cardneed.heg_paoxiao = sgs.ai_cardneed.paoxiao

sgs.ai_target_revises.heg_kongcheng = function(to,card)
	if card:isKindOf("Slash") and to:isKongcheng()
	then return true end
end

sgs.need_kongcheng = sgs.need_kongcheng .. "|heg_kongcheng"


local heg_longdan_skill={}
heg_longdan_skill.name="heg_longdan"
table.insert(sgs.ai_skills,heg_longdan_skill)
heg_longdan_skill.getTurnUseCard=function(self)
	local cards = self:addHandPile()
	local jink_card
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards)  do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end
	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:heg_longdan[%s:%s]=%d"):format(suit,number,card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash

end

sgs.ai_view_as.heg_longdan = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceHand then
		if card:isKindOf("Jink") then
			return ("slash:heg_longdan[%s:%s]=%d"):format(suit,number,card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:heg_longdan[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

sgs.heg_longdan_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.7,
	Slash = 5.6,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}

sgs.ai_card_priority.heg_longdan = function(self,card)
	if table.contains(card:getSkillNames(), "heg_longdan")
	then
		return 1
	end
end
sgs.ai_skill_playerchosen.heg_longdan = function(self, targets)
	return self:findBestDamageTarget(1, "N", 0, nil)[1]
end
sgs.ai_skill_playerchosen["heg_longdan_recover"] = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return target
	end
	if #arr2>0 then
		for _,friend in ipairs(arr2)do
			return friend
		end
	end
	for _,friend in ipairs(self.friends) do
		if friend:getHp() < getBestHp(friend) then
			return friend
		end
	end
	return nil
end

sgs.ai_skill_invoke.heg_jushou = function(self,data)
	local draw = getKingdoms(self.player)
	if draw <= 2 then
		return true
	end
	return sgs.ai_skill_invoke.tenyearjushou(self, data)
end


heg_duanliang_skill={}
heg_duanliang_skill.name="heg_duanliang"
table.insert(sgs.ai_skills,heg_duanliang_skill)
heg_duanliang_skill.getTurnUseCard=function(self)
	local cards = self:addHandPile("he")
	local card
	self:sortByUseValue(cards,true)
	for _,acard in ipairs(cards)  do
		if (acard:isBlack()) and (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard")) and (self:getDynamicUsePriority(acard)<sgs.ai_use_value.SupplyShortage)then
			card = acard
			break
		end
	end
	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	return sgs.Card_Parse(("supply_shortage:heg_duanliang[%s:%s]=%d"):format(suit,number,card_id))
end

sgs.ai_cardneed.heg_duanliang = function(to,card,self)
	return card:isBlack() and card:getTypeId()~=sgs.Card_TypeTrick and getKnownCard(to,self.player,"black",false)<2
end

sgs.heg_duanliang_suit_value = {
	spade = 3.9,
	club = 3.9
}


local function getKurouCard(self,not_slash)
	local card_id
	local hold_crossbow = (self:getCardsNum("Slash")>1)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")

	if self:needToThrowArmor() then
		card_id = self.player:getArmor():getId()
	elseif self.player:getHandcardNum()>self.player:getHp() then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _,acard in ipairs(cards)do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not self:isValuableCard(acard) and not (acard:isKindOf("Crossbow") and hold_crossbow)
					and not (acard:isKindOf("Slash") and not_slash) then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	elseif not self.player:getEquips():isEmpty() then
		if self.player:getOffensiveHorse() then card_id = self.player:getOffensiveHorse():getId()
		elseif self.player:getWeapon() and self:evaluateWeapon(self.player:getWeapon())<3
				and not (self.player:getWeapon():isKindOf("Crossbow") and hold_crossbow) then card_id = self.player:getWeapon():getId()
		elseif self.player:getArmor() and self:evaluateArmor(self.player:getArmor())<2 then card_id = self.player:getArmor():getId()
		end
	end
	if not card_id then
		if lightning and not self:willUseLightning(lightning) then
			card_id = lightning:getEffectiveId()
		else
			for _,acard in ipairs(cards)do
				if (acard:isKindOf("BasicCard") or acard:isKindOf("EquipCard") or acard:isKindOf("AmazingGrace"))
					and not self:isValuableCard(acard) and not (acard:isKindOf("Crossbow") and hold_crossbow)
					and not (acard:isKindOf("Slash") and not_slash) then
					card_id = acard:getEffectiveId()
					break
				end
			end
		end
	end
	return card_id
end
local heg_kurou_skill = {}
heg_kurou_skill.name = "heg_kurou"
table.insert(sgs.ai_skills,heg_kurou_skill)
heg_kurou_skill.getTurnUseCard = function(self,inclusive)
	if (self.player:getHp()==2 and self.player:hasSkill("chanyuan")) then return end
	if (self.player:getHp()>3 and self.player:getHandcardNum()>self.player:getHp())
	or (self.player:getHp()-self.player:getHandcardNum()>=2)
	then
		local id = getKurouCard(self)
		if id then return sgs.Card_Parse("#heg_kurou:"..id..":") end
	end

	local function can_heg_kurou_with_cb(self)
		if self.player:getHp()>1 then return true end
		local has_save = false
		local huatuo = self.room:findPlayerBySkillName("jijiu")
		if huatuo and self:isFriend(huatuo) then
			for _,equip in sgs.list(huatuo:getEquips())do
				if equip:isRed() then has_save = true break end
			end
			if not has_save then has_save = (huatuo:getHandcardNum()>3) end
		end
		if has_save then return true end
		local handang = self.room:findPlayerBySkillName("nosjiefan")
		if handang and self:isFriend(handang) and getCardsNum("Slash",handang,self.player)>=1 then return true end
		return false
	end

	if (self.player:hasWeapon("crossbow") or self:getCardsNum("Crossbow")>0) or self:getCardsNum("Slash")>1 then
		local slash = dummyCard()
		for _,enemy in ipairs(self.enemies)do
			if self.player:canSlash(enemy) and self:slashIsEffective(slash,enemy)
				and self:isGoodTarget(enemy,self.enemies,slash) and not self:slashProhibit(slash,enemy) and can_heg_kurou_with_cb(self) then
				local id = getKurouCard(self,true)
				if id then return sgs.Card_Parse("#heg_kurou:"..id..":") end
			end
		end
	end
end

sgs.ai_skill_use_func["#heg_kurou"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority["heg_kurou"] = 6.8

sgs.double_slash_skill = sgs.double_slash_skill .. "|heg_kurou"

local heg_qingcheng_skill = {}
heg_qingcheng_skill.name = "heg_qingcheng"
table.insert(sgs.ai_skills,heg_qingcheng_skill)
heg_qingcheng_skill.getTurnUseCard = function(self,inclusive)
	local equipcard
	if self:needBear() then return end
	if self:needToThrowArmor() and self.player:getArmor():isBlack() then
		equipcard = self.player:getArmor()
	else
		for _,card in sgs.qlist(self.player:getHandcards())do
			if card:isKindOf("EquipCard") and card:isBlack() then
				equipcard = card
				break
			end
		end
		if not equipcard then
			for _,card in sgs.qlist(self.player:getCards("he"))do
				if card:isKindOf("EquipCard") and not card:isKindOf("Armor") and not card:isKindOf("DefensiveHorse") and card:isBlack() then
					equipcard = card
				end
			end
		end
		if not equipcard then
			for _,card in sgs.qlist(self.player:getCards("he"))do
				if card:isBlack() then
					equipcard = card
				end
			end
		end
	end

	if equipcard then
		return sgs.Card_Parse("#heg_qingcheng:"..equipcard:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#heg_qingcheng"] = function(card,use,self)
	if self.room:alivePlayerCount()==2 then
		local only_enemy = self.room:getOtherPlayers(self.player):first()
		if only_enemy:getLostHp()<3 then return end
	end
	local target
	self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies)do
		if self:getFriendNumBySeat(self.player,enemy)>1 then
			if enemy:getHp()<1 and enemy:hasSkill("nosbuqu",true) and enemy:getMark("Qingchengnosbuqu")==0 then
				target = enemy
				break
			end
			if self:isWeak(enemy) then
				for _,askill in ipairs((sgs.exclusive_skill.."|"..sgs.save_skill):split("|"))do
					if enemy:hasSkill(askill,true) and enemy:getMark("Qingcheng"..askill)==0 then
						target = enemy
						break
					end
				end
				if target then break end
			end
			for _,askill in ipairs(("noswuyan|weimu|wuyan|guixin|fenyong|liuli|yiji|jieming|neoganglie|fankui|fangzhu|enyuan|nosenyuan|"..
						"vsganglie|ganglie|langgu|qingguo|luoying|guzheng|jianxiong|longdan|xiangle|renwang|huangen|tianming|yizhong|bazhen|jijiu|"..
						"beige|longhun|gushou|buyi|mingzhe|danlao|qianxun|jiang|yanzheng|juxiang|huoshou|anxian|zhichi|feiying|"..
						"tianxiang|xiaoji|xuanfeng|nosxuanfeng|xiaoguo|guhuo|guidao|guicai|nosshangshi|lianying|sijian|mingshi|"..
						"yicong|zhiyu|lirang|xingshang|shushen|shangshi|leiji|nosleiji|wusheng|wushuang|tuntian|quanji|kongcheng|jieyuan|"..
						"jilve|wuhun|kuangbao|tongxin|shenjun|ytchengxiang|sizhan|toudu|xiliang|tanlan|shien"):split("|"))do
				if enemy:hasSkill(askill,true) and enemy:getMark("Qingcheng"..askill)==0 then
					target = enemy
					break
				end
			end
			if target then break end
		end
	end
	if not target then
		for _,friend in ipairs(self.friends_noself)do
			if friend:hasSkill("shiyong",true) and friend:getMark("Qingchengshiyong")==0 then
				target = friend
				break
			end
		end
	end
	if not target and self:getOverflow() > 0 then
		for _,enemy in ipairs(self.enemies)do
			for _,skill in sgs.qlist(enemy:getVisibleSkillList()) do
				if not skill:isAttachedLordSkill() then
					if enemy:hasSkill(skill,true) and enemy:getMark("Qingcheng"..skill:objectName())==0 then
						target = enemy
						break
					end
				end
			end
		end
	end

	if not target then return end
	use.card = card
	use.to:append(target)
end

sgs.ai_skill_choice.heg_qingcheng = sgs.ai_skill_choice.qingcheng


sgs.ai_use_value["heg_qingcheng"] = 2
sgs.ai_use_priority["heg_qingcheng"] = 7.2
sgs.ai_card_intention["heg_qingcheng"] = 0

sgs.ai_choicemade_filter.skillChoice.heg_qingcheng = function(self,player,promptlist)
	local choice = promptlist[#promptlist]
	local target = nil
	for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
		if p:hasSkill(choice,true) then
			target = p
			break
		end
	end
	if not target then return end
	if choice=="shiyong" then sgs.updateIntention(player,target,-10) else sgs.updateIntention(player,target,10) end
end
sgs.ai_skill_playerchosen.heg_qingcheng     = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(self.friends, "hp")
	for _, enemy in ipairs(targets) do
		if self:isEnemy(enemy) then
			return enemy
		end
	end
	return nil
end

sgs.ai_skill_use["@@heg_shensu1"] = function(self,prompt)
	self:sort(self.enemies,"defense")
	if self.player:containsTrick("lightning") and self.player:getCards("j"):length()==1
	and self:hasWizard(self.friends) and not self:hasWizard(self.enemies,true)
	then return "." end

	if self:needBear() then return "." end

	local selfSub = self.player:getHp()-self.player:getHandcardNum()
	local selfDef = sgs.getDefense(self.player)

	local slash = dummyCard()
	slash:setSkillName("heg_shensu")
	local dummy = self:aiUseCard(slash)
	if dummy.card then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return "#heg_shensu:.:->"..table.concat(tos,"+")
	end
	return "."
end

sgs.ai_skill_use["@@heg_shensu2"] = function(self,prompt,method)
	local card_str = sgs.ai_skill_use["@@shensu2"](self,prompt,method)
	if not card_str or card_str=="." then return "." end
	local new_str = string.gsub(card_str,"@ShensuCard=","#heg_shensu:")
	new_str = string.gsub(card_str,"->",":->")
	return new_str
end

sgs.ai_skill_use["@@heg_shensu3"] = function(self,prompt)
	self:sort(self.enemies,"defense")
	if self:needBear() then return "." end
	local selfSub = self:getOverflow()
	local selfDef = sgs.getDefense(self.player)
	for _,enemy in ipairs(self.enemies)do
		local def = self:getDefenseSlash(enemy)
		local slash = dummyCard()
		slash:setSkillName("_heg_shensu")
		local eff = self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash)

		if not self.player:canSlash(enemy,slash,false) then
		elseif self:slashProhibit(nil,enemy) then
		elseif def<6 and eff then return "#heg_shensu:.:->"..enemy:objectName()

		elseif selfSub>=2 then return "#heg_shensu:.:->"..enemy:objectName()
		elseif selfDef<6 then return "." end
	end

	for _,enemy in ipairs(self.enemies)do
		local def=sgs.getDefense(enemy)
		local slash = dummyCard()
		slash:setSkillName("_heg_shensu")
		local eff = self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash)

		if not self.player:canSlash(enemy,slash,false) then
		elseif self:slashProhibit(nil,enemy) then
		elseif eff and def<8 then return "#heg_shensu:.:->"..enemy:objectName()
		else return "." end
	end
	return "."
end

sgs.ai_cardneed.heg_shensu = function(to,card,self)
	return sgs.ai_cardneed.shensu(to,card,self)
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|heg_shensu"

sgs.ai_card_intention.heg_shensuCard = sgs.ai_card_intention.ShensuCard
sgs.heg_shensu_keep_value = sgs.shensu_keep_value
sgs.ai_skill_cardask["@heg_luoyi"] = function(self,data)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	if sgs.ai_skill_invoke.nosluoyi(self, data) then
		return "$"..cards[1]:getEffectiveId()
	end
	return "."
end


sgs.ai_cardneed.heg_luoyi = sgs.ai_cardneed.nosluoyi


local heg_qiangxi_skill = {}
heg_qiangxi_skill.name= "heg_qiangxi"
table.insert(sgs.ai_skills,heg_qiangxi_skill)
heg_qiangxi_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#heg_qiangxi:.:")
end

sgs.ai_skill_use_func["#heg_qiangxi"] = function(card,use,self)
	local weapon = self.player:getWeapon()
	if weapon then
		local hand_weapon,cards
		cards = self.player:getHandcards()
		for _,card in sgs.qlist(cards)do
			if card:isKindOf("Weapon") then
				hand_weapon = card
				break
			end
		end
		self:sort(self.enemies)
		self.equipsToDec = hand_weapon and 0 or 1
		for _,enemy in sgs.list(self.enemies)do
			if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
			then
				if hand_weapon then
					use.card = sgs.Card_Parse("#heg_qiangxi:"..hand_weapon:getId()..":")
					use.to:append(enemy)
					break
				end
				use.card = sgs.Card_Parse("#heg_qiangxi:"..weapon:getId()..":")
				use.to:append(enemy)
				return
			end
		end
		self.equipsToDec = 0
	else
		self:sort(self.enemies,"hp")
		for _,enemy in sgs.list(self.enemies)do
			if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
			and self.player:getHp()>enemy:getHp() and self.player:getHp()>1
			then
				use.card = sgs.Card_Parse("#heg_qiangxi:.:")
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_use_value.heg_qiangxi = 2.5
sgs.ai_card_intention.heg_qiangxi = 80
sgs.dynamic_value.damage_card.heg_qiangxi = true
sgs.ai_cardneed.heg_qiangxi = sgs.ai_cardneed.weapon

sgs.heg_qiangxi_keep_value = {
	Peach = 6,
	Jink = 5.1,
	Weapon = 5
}
sgs.straight_damage_skill = sgs.straight_damage_skill .. "|heg_qiangxi"

sgs.ai_skill_choice["heg_liegong"] = function(self, choices, data)
	local target = data:toPlayer()
	if self:isEnemy(target) and not self:cantDamageMore(self.player, target) and getCardsNum("Jink", target, self.player) < 1 then
		return "heg_liegong_addDamage"
	end
	if not self:isFriend(target) then
		return "heg_liegong_cantjink"
	end
	return "cancel"
end
sgs.ai_cardneed.heg_liegong = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|heg_liegong"

sgs.ai_skill_playerchosen.heg_yinghun = function(self,targets)
	if self.player:isWounded() then
		return sgs.ai_skill_playerchosen.yinghun(self, targets)
	else
		for _,friend in ipairs(self.friends_noself)do
			if self:canDraw(friend, self.player) then
				return friend
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if self:doDisCard(enemy, "he") then
				return enemy
			end
		end
	end

end
sgs.ai_skill_choice.heg_yinghun = function(self,choices, data)
	if self.player:isWounded() then
		return self.yinghunchoice
	else
		local target = data:toPlayer()
		if self:isFriend(target) then
			return "d1tx"
		end
		if self:isEnemy(target) then
			return "dxt1"
		end
	end
	return "d1tx"
end

sgs.ai_getBestHp_skill.heg_yinghun = function(owner)
	return owner:getMaxHp() - 2
end

sgs.ai_cardneed.heg_xiaoji = sgs.ai_cardneed.equip
sgs.lose_equip_skill = sgs.lose_equip_skill .. "|heg_xiaoji"
sgs.ai_use_revises.heg_xiaoji = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end


sgs.ai_skill_use["@@heg_tianxiang"] = function(self, prompt, method)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(handcards, true)
	local use_card = nil
	local target = nil
	self:updatePlayers()
	self:sort(self.enemies, "hp")
	self:sort(self.friends_noself, "hp")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,c in ipairs(handcards) do
		if c:getSuit() == sgs.Card_Heart and not c:isKindOf("Peach") then
			use_card = c
		end
	end
	if use_card == nil then return "." end
	for _, enemy in ipairs(self.enemies) do
		if self.player:getMark("heg_tianxiang_two-Clear") == 0 then
			sgs.ai_skill_choice.heg_tianxiang = "heg_tianxiang2"
			return "#heg_tianxiang:" .. use_card:getEffectiveId() .. ":->" .. enemy:objectName()
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self.player:getMark("heg_tianxiang_one-Clear") == 0 then
			sgs.ai_skill_choice.heg_tianxiang = "heg_tianxiang1"
			return "#heg_tianxiang:" .. use_card:getEffectiveId() .. ":->" .. friend:objectName()
		end
	end
	return "."
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|heg_shuangren"


sgs.ai_skill_use["@@heg_shuangren"] = function(self,prompt)
	if not self.player:canPindian() then return "." end
	self:sort(self.enemies,"handcard")
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()

	local slash = dummyCard()
	self.player:setFlags("slashNoDistanceLimit")
	local dummy_use = self:aiUseCard(slash, dummy())
	self.player:setFlags("-slashNoDistanceLimit")

	if dummy_use.card then
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
				if max_point>enemy_max_point then
					self.heg_shuangren_card = max_card:getEffectiveId()
					return "#heg_shuangren:.:->"..enemy:objectName()
				end
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) then
				if max_point>=10 then
					self.heg_shuangren_card = max_card:getEffectiveId()
					return "#heg_shuangren:.:->"..enemy:objectName()
				end
			end
		end
		if #self.enemies<1 then return end
		self:sort(self.friends_noself,"handcard")
		for index = #self.friends_noself,1,-1 do
			local friend = self.friends_noself[index]
			if self.player:canPindian(friend) then
				local friend_min_card = self:getMinCard(friend)
				local friend_min_point = friend_min_card and friend_min_card:getNumber() or 100
				if max_point>friend_min_point then
					self.heg_shuangren_card = max_card:getEffectiveId()
					return "#heg_shuangren:.:->"..friend:objectName()
				end
			end
		end

		local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
		if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum()==1 and zhugeliang:objectName()~=self.player:objectName()
			and self.player:canPindian(zhugeliang) then
			if max_point>=7 then
				self.heg_shuangren_card = max_card:getEffectiveId()
				return "#heg_shuangren:.:->"..zhugeliang:objectName()
			end
		end

		for index = #self.friends_noself,1,-1 do
			local friend = self.friends_noself[index]
			if self.player:canPindian(friend) then
				if max_point>=7 then
					self.heg_shuangren_card = max_card:getEffectiveId()
					return "#heg_shuangren:.:->"..friend:objectName()
				end
			end
		end
	end
	return "."
end

function sgs.ai_skill_pindian.heg_shuangren(minusecard,self,requestor)
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or (maxcard:getNumber()<6 and minusecard or maxcard)
end


sgs.ai_skill_playerchosen.heg_shuangren = sgs.ai_skill_playerchosen.zero_card_as_slash
sgs.ai_card_intention["heg_shuangren"] = sgs.ai_card_intention.TianyiCard
sgs.ai_cardneed.heg_shuangren = sgs.ai_cardneed.bignumber

sgs.ai_skill_invoke.heg_kuangfu = function(self,data)
	local target = data:toPlayer()
	return not self:isFriend(target) and self:doDisCard(target, "e", true)
end
sgs.ai_cardneed.heg_kuangfu = sgs.ai_cardneed.slash


sgs.ai_skill_playerchosen.heg_shushen = function(self,targets)
	if #self.friends_noself==0 then return nil end
	return self:findPlayerToDraw(false,2)
end
sgs.ai_playerchosen_intention.heg_shushen = -80

sgs.ai_skill_invoke.heg_yicheng = sgs.ai_skill_invoke.yicheng

sgs.ai_skill_discard.heg_yicheng = sgs.ai_skill_discard.yicheng

sgs.ai_choicemade_filter.skillInvoke.heg_yicheng = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-20) end
	end
end

function sgs.ai_skill_invoke.heg_hengjiang(self,data)
	local target = data:toPlayer()
	if self:isEnemy(target) then
		return true
	else
		if hasManjuanEffect(self.player) then return false end
		if target:getPhase()>sgs.Player_Discard then return true end
		if target:hasSkill("yongsi") then return false end
		if target:hasSkill("keji") and not target:hasFlag("KejiSlashInPlayPhase") then return true end
		return target:getHandcardNum()<=target:getMaxCards()-2
	end
end

sgs.ai_choicemade_filter.skillInvoke.heg_hengjiang = function(self,player,promptlist)
	if promptlist[3]=="yes" then
		local current = self.room:getCurrent()
		if current and current:getPhase()<=sgs.Player_Discard
			and not (current:hasSkill("keji") and not current:hasFlag("KejiSlashInPlayPhase")) and current:getHandcardNum()>current:getMaxCards()-2 then
			sgs.updateIntention(player,current,50)
		end
	end
end

sgs.ai_skill_playerschosen.heg_duoshi = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if self:isFriend(target) then
            selected:append(target)
        end
    end
    return selected
end

local function heg_huyuan_validate(self,equip_type,is_handcard)
	local targets
	if is_handcard then targets = self.friends else targets = self.friends_noself end
	if equip_type=="SilverLion" then
		for _,enemy in sgs.list(self.enemies)do
			if enemy:hasSkills("yizhong|bazhen") then table.insert(targets,enemy) end
		end
	end
	for _,friend in sgs.list(targets)do
		local has_equip = false
		for _,equip in sgs.list(friend:getEquips())do
			if equip:isKindOf(equip_type) then
				has_equip = true
				break
			end
		end
		if not has_equip and not ((equip_type=="Armor" or equip_type=="SilverLion") and friend:hasSkills("yizhong|bazhen")) then
			self:sort(self.enemies,"defense")
			for _,enemy in sgs.list(self.enemies)do
				if friend:distanceTo(enemy)==1 and self.player:canDiscard(enemy,"he") then
					enemy:setFlags("AI_heg_huyuanToChoose")
					return friend
				end
			end
		end
	end
	return nil
end

sgs.ai_skill_use["@@heg_huyuan"] = function(self,prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self.player:hasArmorEffect("SilverLion") then
		local player = heg_huyuan_validate(self,"SilverLion",false)
		if player then return "#heg_huyuan:"..self.player:getArmor():getEffectiveId()..":->"..player:objectName() end
	end
	if self.player:getOffensiveHorse() then
		local player = heg_huyuan_validate(self,"OffensiveHorse",false)
		if player then return "#heg_huyuan:"..self.player:getOffensiveHorse():getEffectiveId()..":->"..player:objectName() end
	end
	if self.player:getWeapon() then
		local player = heg_huyuan_validate(self,"Weapon",false)
		if player then return "#heg_huyuan:"..self.player:getWeapon():getEffectiveId()..":->"..player:objectName() end
	end
	if self.player:getArmor() and self.player:getLostHp()<=1 and self.player:getHandcardNum()>=3 then
		local player = heg_huyuan_validate(self,"Armor",false)
		if player then return "#heg_huyuan:"..self.player:getArmor():getEffectiveId()..":->"..player:objectName() end
	end
	for _,card in sgs.list(cards)do
		if card:isKindOf("DefensiveHorse") then
			local player = heg_huyuan_validate(self,"DefensiveHorse",true)
			if player then return "#heg_huyuan:"..card:getEffectiveId()..":->"..player:objectName() end
		end
	end
	for _,card in sgs.list(cards)do
		if card:isKindOf("OffensiveHorse") then
			local player = heg_huyuan_validate(self,"OffensiveHorse",true)
			if player then return "#heg_huyuan:"..card:getEffectiveId()..":->"..player:objectName() end
		end
	end
	for _,card in sgs.list(cards)do
		if card:isKindOf("Weapon") then
			local player = heg_huyuan_validate(self,"Weapon",true)
			if player then return "#heg_huyuan:"..card:getEffectiveId()..":->"..player:objectName() end
		end
	end
	for _,card in sgs.list(cards)do
		if card:isKindOf("SilverLion") then
			local player = heg_huyuan_validate(self,"SilverLion",true)
			if player then return "#heg_huyuan:"..card:getEffectiveId()..":->"..player:objectName() end
		end
		if card:isKindOf("Armor") and heg_huyuan_validate(self,"Armor",true) then
			local player = heg_huyuan_validate(self,"Armor",true)
			if player then return "#heg_huyuan:"..card:getEffectiveId()..":->"..player:objectName() end
		end
	end
	local c,to = self:getCardNeedPlayer(cards)
	if c and to then return "#heg_huyuan:"..c:getEffectiveId()..":->"..to:objectName() end
end

sgs.ai_skill_playerchosen.heg_huyuan = function(self,targets)
	targets = sgs.QList2Table(targets)
	for _,p in sgs.list(targets)do
		if p:hasFlag("AI_heg_huyuanToChoose") then
			p:setFlags("-AI_heg_huyuanToChoose")
			return p
		end
	end
	for _,p in sgs.list(targets)do
		if self:doDisCard(p, "ej") then
			return p
		end
	end
	return targets[1]
end

sgs.ai_card_intention["heg_huyuan"] = function(self,card,from,to)
	if to[1]:hasSkills("bazhen|yizhong") then
		if sgs.Sanguosha:getCard(card:getEffectiveId()):isKindOf("SilverLion") then
			sgs.updateIntention(from,to[1],10)
			return
		end
	end
	sgs.updateIntention(from,to[1],-50)
end

sgs.ai_cardneed.heg_huyuan = sgs.ai_cardneed.equip

sgs.heg_huyuan_keep_value = {
	Peach = 6,
	Jink = 5.1,
	EquipCard = 4.8
}


local heg_duanxie_skill = {}
heg_duanxie_skill.name = "heg_duanxie"
table.insert(sgs.ai_skills,heg_duanxie_skill)
heg_duanxie_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#heg_duanxie:.:")
end
sgs.ai_skill_use_func["#heg_duanxie"] = function(card,use,self)
	local x = math.max(self.player:getLostHp(), 1)
	self:sort(self.enemies,"handcard")
	local targets = sgs.SPlayerList()

	for _,enemy in sgs.list(self.enemies)do
		if not enemy:isChained() and enemy:isKongcheng() then
			if targets:length() >= x then break end
			targets:append(enemy)
		end
	end

	for _,enemy in sgs.list(self.enemies)do
		if not enemy:isChained() and not targets:contains(enemy) then
			if targets:length() >= x then break end
			targets:append(enemy)
		end
	end
	if targets:length() > 0 then
		use.card = card
		if use.to then
			for _,enemy in sgs.list(targets)do
				use.to:append(enemy)
			end
		end
		return
	end

end

sgs.ai_card_intention["heg_duanxie"] = 50
sgs.ai_use_priority["heg_duanxie"] = 0

local heg_nos_guishu_skill = {}
heg_nos_guishu_skill.name = "heg_nos_guishu"
table.insert(sgs.ai_skills,heg_nos_guishu_skill)
heg_nos_guishu_skill.getTurnUseCard = function(self)
	local cards = self:addHandPile()
	self:sortByUseValue(cards,true)
	for _,acard in sgs.list(cards)do
		if acard:getSuit() == sgs.Card_Spade then
			local c 
			if self.player:getMark("heg_nos_guishu") == 1 then
				c = sgs.Card_Parse("EXCard_YJJG:heg_nos_guishu[no_suit:0]="..acard:getEffectiveId())
			elseif self.player:getMark("heg_nos_guishu") == 2 then
				c = sgs.Card_Parse("EXCard_ZJZB:heg_nos_guishu[no_suit:0]="..acard:getEffectiveId())
			else
				c = sgs.Card_Parse("EXCard_YJJG:heg_nos_guishu[no_suit:0]="..acard:getEffectiveId())
			end
			if c and c:isAvailable(self.player) then return c end
		end
	end
end

sgs.ai_view_as.heg_nos_guishu = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceHand and suit == "spade" then
		if player:getMark("heg_nos_guishu") == 1 then
			return ("EXCard_YJJG:heg_nos_guishu[%s:%s]=%d"):format(suit,number,card_id)
		elseif player:getMark("heg_nos_guishu") == 2 then
			return ("EXCard_ZJZB:heg_nos_guishu[%s:%s]=%d"):format(suit,number,card_id)
		else
			return ("EXCard_YJJG:heg_nos_guishu[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end
sgs.ai_card_priority.heg_nos_guishu = function(self,card)
	if table.contains(card:getSkillNames(), "heg_nos_guishu") and card:isKindOf("EXCard_ZJZB")
	then return 5 end
end

sgs.ai_ajustdamage_to.heg_nos_yuanyu   = function(self, from, to, card, nature)
	if from and not (from:getNextAlive():objectName() == self.player:objectName() or from:getNextAlive(self.room:alivePlayerCount() - 1):objectName() == self.player:objectName() )  then
		return -99
	end
end


local heg_guishu_skill = {}
heg_guishu_skill.name = "heg_guishu"
table.insert(sgs.ai_skills,heg_guishu_skill)
heg_guishu_skill.getTurnUseCard = function(self)
	local cards = self:addHandPile()
	self:sortByUseValue(cards,true)
	for _,acard in sgs.list(cards)do
		if acard:getSuit() == sgs.Card_Spade then
			local c 
			if self.player:getMark("heg_guishu-Clear") == 1 then
				c = sgs.Card_Parse("EXCard_YJJG:heg_guishu[no_suit:0]="..acard:getEffectiveId())
			elseif self.player:getMark("heg_guishu-Clear") == 2 then
				c = sgs.Card_Parse("EXCard_ZJZB:heg_guishu[no_suit:0]="..acard:getEffectiveId())
			else
				c = sgs.Card_Parse("EXCard_YJJG:heg_guishu[no_suit:0]="..acard:getEffectiveId())
			end
			if c and c:isAvailable(self.player) then return c end
		end
	end
end

sgs.ai_view_as.heg_guishu = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceHand and suit == "spade" then
		if player:getMark("heg_guishu-Clear") == 1 then
			return ("EXCard_YJJG:heg_guishu[%s:%s]=%d"):format(suit,number,card_id)
		elseif player:getMark("heg_guishu") == 2 then
			return ("EXCard_ZJZB:heg_guishu[%s:%s]=%d"):format(suit,number,card_id)
		else
			return ("EXCard_YJJG:heg_guishu[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end
sgs.ai_card_priority.heg_guishu = function(self,card)
	if table.contains(card:getSkillNames(), "heg_guishu") and card:isKindOf("EXCard_ZJZB")
	then return 5 end
end

sgs.ai_ajustdamage_to.heg_yuanyu   = function(self, from, to, card, nature)
	if from and not (from:inMyAttackRange(to))  then
		return -1
	end
end

sgs.ai_skill_playerschosen.heg_zhuihuan = function(self, targets, max, min)
	local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if self:isFriend(target) and selected:length() < max then
            selected:append(target)
        end
    end
    return selected
end

sgs.ai_playerschosen_intention.heg_zhuihuan = function(self, from, prompt)
    local intention = -60
    local tolist = prompt:split("+")
    for _, dest in ipairs(tolist) do
        local to = self.room:findPlayerByObjectName(dest)
        sgs.updateIntention(from, to, intention)
    end
end

sgs.ai_skill_invoke.heg_qiao = function(self,data)
	local target = data:toPlayer()
	if self:isEnemy(target) then
		return self:doDisCard(target, "he")
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_qiao = function(self,player,promptlist)
	if promptlist[3]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,40) end
	end
end

sgs.ai_skill_playerchosen.heg_chengshang = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	for _,p in sgs.list(targets)do
		if self:isEnemy(p) and self:doDisCard(p, "he", true) and p:getHandcardNum() < 4 then
			return p
		end
	end
	return nil
end

sgs.ai_skill_cardask["heg_chengshang"] = function(self, data)
	local use = data:toCardUse()
	local target = use.from
	if self:isEnemy(target) then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		for _,card in ipairs(cards) do
			if card:getSuit() == use.card:getSuit() or card:getNumber() == use.card:getNumber() then
				return "$"..card:getEffectiveId()
			end
		end
	end
	return true
end

sgs.ai_playerchosen_intention.heg_chengshang = 40

sgs.ai_skill_invoke.heg_guowu = sgs.ai_skill_invoke.guowu

sgs.ai_skill_playerschosen.heg_guowu = function(self, targets, max, min)
	local use = self.room:getTag("heg_guowu"):toCardUse()
	local dummy_use = self:aiUseCard(use.card, dummy(true, 2, use.to))
	local enemy = sgs.SPlayerList()
	if dummy_use.card and dummy_use.to:length() > 0 then
		for _, p in sgs.qlist(dummy_use.to) do
			if self:isEnemy(p) and targets:contains(p) then
				enemy:append(p)
				if enemy:length() >= max then
					break
				end
			end
		end
	end
	return enemy
end

sgs.ai_fill_skill.heg_zhuangrong = function(self)
	local use_card
    local cards = self.player:getCards("h")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	for i,h in sgs.list(cards)do
		if h:isKindOf("TrickCard") then
			use_card = h
			break
		end
	end
	if use_card then
		return sgs.Card_Parse("#heg_zhuangrong:"..use_card:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#heg_zhuangrong"] = function(card,use,self)
	if self:getCardsNum("Slash") > 0 and not self.player:hasSkill("wushuang") then
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if isCard("Slash", c, self.player) then
				local dummy_use = self:aiUseCard(c, dummy())
				if dummy_use.card and dummy_use.to:length() > 0 then
					use.card = card
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["heg_zhuangrong"] = 5

sgs.ai_skill_invoke.heg_duannian = function(self, data)
	if self.player:getHandcardNum() > self.player:getMaxHp() and self.player:getMaxCards() > self.player:getMaxHp() then
		return false
	end
	return true
end

sgs.ai_skill_playerchosen.heg_lianyou = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in sgs.list(targets)do
		if self:isFriend(p) then
			return p
		end
	end
	return nil
end

sgs.ai_ajustdamage_from.heg_xinghuo = function(self, from, to, card, nature)
	if nature == "F" then
		return 1
	end
end

sgs.ai_skill_invoke.heg_gongxiu = function(self, data)
	if sgs.ai_skill_playerschosen.heg_gongxiu(self, self.room:getAlivePlayers(), self.player:getMaxHp()):length() > 0 then
		return true
	end
	return false
end

sgs.ai_skill_playerschosen.heg_gongxiu = function(self, targets, max, min)
	local selected = sgs.SPlayerList()
	local can_choose = sgs.QList2Table(targets)
	self:sort(can_choose, "defense")
	local choicelist = {}
	if self.player:getMark("heg_gongxiu_draw") == 0 then
		table.insert(choicelist, "draw")
	end
	if self.player:getMark("heg_gongxiu_discard") == 0 then
		table.insert(choicelist, "discard")
	end
	local choice
	if self.heg_gongxiu then
		choice = self.heg_gongxiu
		self.heg_gongxiu = nil
	else
		choice = choicelist[math.random(1, #choicelist)]
		self.heg_gongxiu = choice
	end
	if choice == "draw" then
		for _,target in ipairs(can_choose) do
			if self:isFriend(target) and selected:length() < max and self:canDraw(target) then
				selected:append(target)
			end
		end
	elseif choice == "discard" then
		for _,target in ipairs(can_choose) do
			if self:isEnemy(target) and selected:length() < max and self:doDisCard(target, "he") then
				selected:append(target)
			end
		end
	end
	return selected
end

sgs.ai_skill_choice.heg_gongxiu = function(self, choices, data)
	if self.heg_gongxiu then
		return self.heg_gongxiu
	end
	local items = choices:split("+")
	return items[1]
end

sgs.ai_playerschosen_intention.heg_gongxiu = function(self, from, prompt)
	local intention = 0
	local tolist = prompt:split("+")
	local choice = ""
	if from:getMark("heg_gongxiu_draw") == 0 then
		choice = "draw"
	else
		choice = "discard"
	end
	if choice == "draw" then
		intention = -30
	else
		intention = 30
	end
	for _, dest in ipairs(tolist) do
		local to = self.room:findPlayerByObjectName(dest)
		sgs.updateIntention(from, to, intention)
	end
end

sgs.ai_fill_skill.heg_jinghe = function(self)
	if self.player:hasUsed("#heg_jinghe") then
		return nil
	end
	return sgs.Card_Parse("#heg_jinghe:.:")
end

sgs.ai_skill_use_func["#heg_jinghe"] = function(card,use,self)
	use.card = card
	use.to:append(self.player)
end

sgs.ai_use_priority["heg_jinghe"] = 10

sgs.ai_skill_invoke.heg_ol_liegong = function(self,data)
	local target = data:toPlayer()
	return not self:isFriend(target)
end
sgs.hit_skill = sgs.hit_skill .. "|heg_ol_liegong"

sgs.ai_canliegong_skill.heg_ol_liegong = function(self, from, to)
	return from:getPhase() == sgs.Player_Play and (to:getHandcardNum() >= from:getHp() or to:getHandcardNum() <= from:getAttackRange())
end

sgs.ai_cardneed.heg_ol_liegong = sgs.ai_cardneed.slash

sgs.ai_skill_invoke["ChangeGeneral"] = function(self, data)
	self:updatePlayers()
	if self.player:hasSkill("bf_nos_diancai") then return true end
	if self.player:hasSkill("bf_qice") then
		if #self.enemies > #self.friends then
			return true
		end
	end
	for _,p in sgs.qlist(self.room:findPlayersBySkillName("bf_zhiman")) do
		if p then
			return false
--			if #self.enemies > #self.friends then
--				return true
--			end
		end
	end
	return true
end

local bf_qice_skill = {}
bf_qice_skill.name = "bf_qice"
table.insert(sgs.ai_skills, bf_qice_skill)
bf_qice_skill.getTurnUseCard = function(self, inclusive)
	sgs.ai_use_priority["bf_qice"] = 1.5
	if self.player:hasUsed("#bf_qice") or self.player:isKongcheng() then return end
	local cards = self.player:getHandcards()
	local allcard = {}
	cards = sgs.QList2Table(cards)
	
	local function get_handcard_suit(cards)
		if #cards == 0 then return sgs.Card_NoSuit end
		if #cards == 1 then return cards[1]:getSuit() end
		local black = false
		if cards[1]:isBlack() then black = true end
		for _, c in ipairs(cards) do
			if black ~= c:isBlack() then return sgs.Card_NoSuit end
		end
		return black and sgs.Card_NoSuitBlack or sgs.Card_NoSuitRed
	end
	
	local suit = get_handcard_suit(cards)
	local aoename = "savage_assault|archery_attack"
	local aoenames = aoename:split("|")
	local aoe
	local i
--	local good, bad = 0, 0
	local caocao = self.room:findPlayerBySkillName("jianxiong")
	local qicetrick = "savage_assault|archery_attack|ex_nihilo|god_salvation"
	local qicetricks = qicetrick:split("|")
	local aoe_available, ge_available, ex_available = true, true, true
	
	--目標數不大於X的非延時類錦囊牌使用(X為你的手牌數)
	local target_count = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		target_count = target_count + 1
	end
	for i = 1, #qicetricks do
		local qice_card_name = qicetricks[i]
		qice_card_name = sgs.Sanguosha:cloneCard(qice_card_name, suit)
		if qice_card_name:isKindOf("AOE") and target_count - 1 > #cards then aoe_available = false end
		if qice_card_name:isKindOf("GlobalEffect") and target_count > #cards then ge_available = false end
	end
	
	for i = 1, #qicetricks do
		local forbiden = qicetricks[i]
		forbid = sgs.Sanguosha:cloneCard(forbiden, suit)
		if self.player:isCardLimited(forbid, sgs.Card_MethodUse, true) or not forbid:isAvailable(self.player) then
			if forbid:isKindOf("AOE") then aoe_available = false end
			if forbid:isKindOf("GlobalEffect") then ge_available = false end
			if forbid:isKindOf("ExNihilo") then ex_available = false end
		end
	end
	if self.player:hasUsed("#bf_qice") then return end
--	for _, friend in ipairs(self.friends) do
--		if friend:isWounded() then
--			good = good + 10 / friend:getHp()
--			if friend:isLord() then good = good + 10 / friend:getHp() end
--		end
--	end
--
--	for _, enemy in ipairs(self.enemies) do
--		if enemy:isWounded() then
--			bad = bad + 10 / enemy:getHp()
--			if enemy:isLord() then
--				bad = bad + 10 / enemy:getHp()
--			end
--		end
--	end

	for _, card in ipairs(cards) do
		if card:hasFlag("xiahui") then return end
	end

	for _, card in ipairs(cards) do
		table.insert(allcard, card:getEffectiveId())
	end

	if #allcard > 1 then sgs.ai_use_priority["bf_qice"] = 0 end
	
	if #self.friends > #self.enemies and #self.friends + #self.enemies == self.room:getAlivePlayers():length() and self.player:getHandcardNum() < 4 and self:getCardsNum("Peach") == 0 and self.player:getHp() >= 2 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() <= 1 and enemy:isKongcheng() then
				local parsed_card = sgs.Card_Parse("#bf_qice:" .. table.concat(allcard, "+") .. ":duel")
				return parsed_card
			end
		end
	end
	
	local godsalvation = sgs.Sanguosha:cloneCard("god_salvation", suit, 0)
	--if self.player:getHandcardNum() < 3 then
		if aoe_available then
			for i = 1, #aoenames do
				local newqice = aoenames[i]
				aoe = sgs.Sanguosha:cloneCard(newqice)
				if self:getAoeValue(aoe) > 0 then
					local parsed_card = sgs.Card_Parse("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. newqice)
					return parsed_card
				end
			end
		end
		if ge_available and self:willUseGodSalvation(godsalvation) then
			local parsed_card = sgs.Card_Parse("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. "god_salvation")
			return parsed_card
		end
		if ex_available and self:getCardsNum("Jink") == 0 and self:getCardsNum("Peach") == 0 then
			local parsed_card = sgs.Card_Parse("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. "ex_nihilo")
			return parsed_card
		end
	--end

	if aoe_available then
		for i = 1, #aoenames do
			local newqice = aoenames[i]
			aoe = sgs.Sanguosha:cloneCard(newqice)
			if self:getAoeValue(aoe) > -5 and caocao and self:isFriend(caocao) and caocao:getHp() > 1 and not self:willSkipPlayPhase(caocao)
				and not self.player:hasSkill("jueqing") and self:aoeIsEffective(aoe, caocao, self.player) then
				local parsed_card = sgs.Card_Parse("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. newqice)
				return parsed_card
			end
		end
	end
	if self:getCardsNum("Jink") == 0 and self:getCardsNum("Peach") == 0 and self:getCardsNum("Analeptic") == 0
		and self:getCardsNum("Nullification") == 0 and self.player:getHandcardNum() <= 3 then
		if ge_available and self:willUseGodSalvation(godsalvation) and self.player:isWounded() then
			local parsed_card = sgs.Card_Parse("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. "god_salvation")
			return parsed_card
		end
		if ex_available then
			local parsed_card = sgs.Card_Parse("#bf_qice:" .. table.concat(allcard, "+") .. ":" .. "ex_nihilo")
			return parsed_card
		end
	end
end

sgs.ai_skill_use_func["#bf_qice"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local qicecard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	qicecard:setSkillName("bf_qice")
	self:useTrickCard(qicecard, use)
	if use.card then
		for _, acard in sgs.qlist(self.player:getHandcards()) do
			if isCard("Peach", acard, self.player) and self.player:getHandcardNum() > 1 and self.player:isWounded()
				and not self:needToLoseHp(self.player) then
					use.card = acard
					return
			end
		end
		use.card = card
	end
end


sgs.ai_skill_discard["bf_wanwei"] = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(usable_cards)
	local to_discard = {}
	local count = 0
	for _,c in ipairs(usable_cards) do
		if count < discard_num then
			count = count + 1
			table.insert(to_discard, c:getEffectiveId())
		end
	end
	return to_discard
end
sgs.ai_skill_invoke.bf_yuejian = function(self, data)
	local target = self.room:getCurrent()
	if target and self:isFriend(target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.bf_yuejian = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:getCurrent()
		if target then sgs.updateIntention(player,target,-50) end
	end
end


sgs.ai_skill_invoke["bf_zhiman"] = sgs.ai_skill_invoke["yishihz"]

sgs.ai_choicemade_filter.cardChosen.bf_zhiman = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.lose_equip_skill = sgs.lose_equip_skill .. "|bf_xuanlve"
sgs.ai_cardneed.bf_xuanlve = sgs.ai_cardneed.equip
sgs.ai_skill_playerchosen["bf_xuanlve"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	return nil
end

sgs.ai_choicemade_filter.cardChosen.bf_xuanlve = sgs.ai_choicemade_filter.cardChosen.snatch

local bf_yongjin_skill = {}
bf_yongjin_skill.name = "bf_yongjin"
table.insert(sgs.ai_skills, bf_yongjin_skill)
bf_yongjin_skill.getTurnUseCard = function(self, inclusive)
	local equip_num = 0
	if self.player:getMark("@bf_yongjin") > 0 then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isEnemy(p) then
				equip_num = equip_num + p:getEquips():length()
			end
		end
	end
	if equip_num > 2 then
		return sgs.Card_Parse("#bf_yongjin:.:")
	end
end

sgs.ai_skill_use_func["#bf_yongjin"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority["bf_yongjin"] = 7
sgs.ai_use_value["bf_yongjin"] = 7

sgs.ai_skill_askforag["bf_yongjin"] = function(self, card_ids)
	for i = 1, #card_ids, 1 do
		local equip_card_owner = self.room:getCardOwner(card_ids[i])
		if self:isEnemy(equip_card_owner) then
			return card_ids[i]
		end
	end
	return -1
end

sgs.ai_skill_use["@@bf_yongjin!"] = function(self, prompt, method)
	local equip_cards = sgs.QList2Table(self.player:getCards("h"))
	self:updatePlayers()
	self:sort(self.friends, "defense")
	for _, e in ipairs(equip_cards) do
		if e:hasFlag("bf_yongjin") then
			local equip_index = e:getRealCard():toEquipCard():location()
			for _, friend in ipairs(self.friends) do
				if friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
					return string.format("#bf_yongjin:%d:->%s", e:getEffectiveId(), friend:objectName())
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.bf_tiaodu = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) and self:canDraw(target, self.player) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.bf_tiaodu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end
sgs.ai_skill_playerchosen["bf_tiaodu"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets) do
		if self:isFriend(p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["bf_tiaodu"] = -50


local bf_nos_tiaodu_skill = {}
bf_nos_tiaodu_skill.name = "bf_nos_tiaodu"
table.insert(sgs.ai_skills, bf_nos_tiaodu_skill)
bf_nos_tiaodu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#bf_nos_tiaodu") then
		return sgs.Card_Parse("#bf_nos_tiaodu:.:")
	end
end

sgs.ai_skill_use_func["#bf_nos_tiaodu"] = function(card, use, self)
	local targets = {}
	self:updatePlayers()
	self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		table.insert(targets, friend)
	end
	use.card = card
	if use.to then
		for i = 1, #targets, 1 do
			use.to:append(targets[i])
		end
	end
end

sgs.ai_use_priority["bf_nos_tiaodu"] = 3
sgs.ai_use_value["bf_nos_tiaodu"] = 3
sgs.ai_card_intention["bf_nos_tiaodu"] = -50

sgs.ai_skill_cardask["@bf_nos_tiaodu"] = function(self, data, pattern, target, target2)
	local handcards = self.player:getCards("h")
	local equip_cards = self.player:getCards("e")
	
	if self.player:hasArmorEffect("silver_lion") and self.player:isWounded() then
		for _, c in sgs.qlist(equip_cards) do
			if c:isKindOf("SilverLion") then
				return c:toString()
			end
		end
	end
	
	if self.player:hasSkill("bf_nos_tiaodu") and self.room:getCurrent():objectName() == self.player:objectName() then
		for _,c in sgs.qlist(handcards) do
			if self.player:getArmor() and c:isKindOf("Armor") then
				return self.player:getArmor():toString()
			elseif self.player:getDefensiveHorse() and c:isKindOf("DefensiveHorse") then
				return self.player:getDefensiveHorse():toString()
			elseif self.player:getWeapon() and c:isKindOf("Weapon") then
				return self.player:getWeapon():toString()
			elseif self.player:getOffensiveHorse() and c:isKindOf("OffensiveHorse") then
				return self.player:getOffensiveHorse():toString()
			end
		end
	else
		for _,c in sgs.qlist(handcards) do
			if not self.player:getArmor() and c:isKindOf("Armor") then
				local dummyuse = { isDummy = true }
				self:useEquipCard(c, dummyuse)
				if dummyuse.card then
					return c:toString()
				end
			elseif not self.player:getDefensiveHorse() and c:isKindOf("DefensiveHorse") then
				return c:toString()
			end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen["bf_nos_tiaodu"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets) do
		if self:isFriend(p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["bf_nos_tiaodu"] = -50

sgs.ai_skill_invoke.bf_sec_tiaodu = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) and self:canDraw(target, self.player) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.bf_sec_tiaodu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end
sgs.ai_skill_playerchosen["bf_sec_tiaodu"] = sgs.ai_skill_playerchosen["bf_tiaodu"]

sgs.ai_playerchosen_intention["bf_sec_tiaodu"] = sgs.ai_playerchosen_intention["bf_tiaodu"]

sgs.ai_skill_invoke.bf_third_tiaodu = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) and self:canDraw(target, self.player) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.bf_third_tiaodu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end

sgs.ai_skill_playerchosen["bf_third_tiaodu"] = sgs.ai_skill_playerchosen["bf_tiaodu"]

sgs.ai_playerchosen_intention["bf_third_tiaodu"] = sgs.ai_playerchosen_intention["bf_tiaodu"]



local bf_xiongsuan_skill = {}
bf_xiongsuan_skill.name = "bf_xiongsuan"
table.insert(sgs.ai_skills, bf_xiongsuan_skill)
bf_xiongsuan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@scary") > 0 and self.player:getHandcardNum() < 3 then
		return sgs.Card_Parse("#bf_xiongsuan:.:")
	end
end

sgs.ai_skill_use_func["#bf_xiongsuan"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	local use_card = {}
	local target = {}
	self:sortByUseValue(usable_cards, true)
	for _,c in ipairs(usable_cards) do
		if not c:isKindOf("Peach") then
			table.insert(use_card, c)
		end
	end
	for _, enemy in ipairs(self.enemies) do
		local has_limit_skill = false
		for _,skill in sgs.qlist(enemy:getVisibleSkillList()) do
			if not skill:inherits("SPConvertSkill") and not skill:isAttachedLordSkill() and skill:getFrequency() == sgs.Skill_Limited then
				has_limit_skill = true
			end
		end
		if not has_limit_skill and enemy:getHp() <= 2 then
			table.insert(target, enemy)
		end
	end
	if #use_card == 0 or #target == 0 then return end
	local card_str = string.format("#bf_xiongsuan:%s:", use_card[1]:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	if use.to then use.to:append(target[1]) end
end

sgs.ai_skill_choice["bf_xiongsuan"] = function(self, choices, data)
	local skill_items = choices:split("+")
	if #skill_items == 1 then
		return skill_items[1]
	else
		return skill_items[math.random(1,#skill_items)]
	end
end

sgs.ai_use_priority["bf_xiongsuan"] = 3
sgs.ai_use_value["bf_xiongsuan"] = 3

sgs.ai_skill_choice.bf_nos_huashen = sgs.ai_skill_choice.huashen







sgs.need_kongcheng = sgs.need_kongcheng .. "|twyj_baimei"

sgs.ai_ajustdamage_to.twyj_baimei = function(self, from, to, card, nature)
	if to:isKongcheng() and (nature ~= "N" or (card and card:isKindOf("TrickCard"))) then
		return -99
	end
end



local twyj_rangyi_skill = {}
twyj_rangyi_skill.name = "twyj_rangyi"
table.insert(sgs.ai_skills, twyj_rangyi_skill)
twyj_rangyi_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#twyj_rangyi") and not self.player:isKongcheng() then
		return sgs.Card_Parse("#twyj_rangyi:.:")
	end
end

sgs.ai_skill_use_func["#twyj_rangyi"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends_noself, "hp")
	self:sort(self.enemies, "hp")
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getWeapon() then
		for _,c in ipairs(handcards) do
			if c:isKindOf("Weapon") then
				for _, friend in ipairs(self.friends_noself) do
					local equip_index = c:getRealCard():toEquipCard():location()
					if friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
						use.card = card
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end
	if self.player:getArmor() then
		for _,c in ipairs(handcards) do
			if c:isKindOf("Armor") then
				for _, friend in ipairs(self.friends_noself) do
					local equip_index = c:getRealCard():toEquipCard():location()
					if friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
						use.card = card
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end
	if self.player:getDefensiveHorse() then
		for _,c in ipairs(handcards) do
			if c:isKindOf("DefensiveHorse") then
				for _, friend in ipairs(self.friends_noself) do
					local equip_index = c:getRealCard():toEquipCard():location()
					if friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
						use.card = card
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end
	if self.player:getOffensiveHorse() then
		for _,c in ipairs(handcards) do
			if c:isKindOf("OffensiveHorse") then
				for _, friend in ipairs(self.friends_noself) do
					local equip_index = c:getRealCard():toEquipCard():location()
					if friend:getEquip(equip_index) == nil and friend:hasEquipArea(equip_index) then
						use.card = card
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end
	if self.player:getHp() >= 2 and self:getCardsNum("Peach") > 0 then
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHp() <= 2 and friend:isWounded() then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
	if not self:slashIsAvailable() and self:getCardsNum("Slash") > 0 then
		for _, friend in ipairs(self.friends_noself) do
			for _, enemy in ipairs(self.enemies) do
				for _, slash in ipairs(self:getCards("Slash")) do
					if friend:canSlash(enemy, slash, false) and not self:slashProhibit(slash, enemy) and friend:inMyAttackRange(enemy)
					and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) then
						use.card = card
						if use.to then use.to:append(friend) end
						return
					end
				end
			end
		end
	end
	if self:getCardsNum("Jink") == #handcards and #handcards <= 2 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() <= 1 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_use_priority["twyj_rangyi"] = 0
sgs.ai_use_value["twyj_rangyi"] = 0

sgs.ai_skill_use["@@twyj_rangyi"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.friends_noself, "hp")
	self:sort(self.enemies, "hp")
	local current = self.room:getCurrent()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local useable_cards = {}
	for _,c in ipairs(handcards) do
		if c:hasFlag("twyj_rangyi") and c:isAvailable(self.player) then
			table.insert(useable_cards, c)
		end
	end
	self:sortByUseValue(useable_cards, false)
	if #useable_cards > 0 then
		
		local use_card = useable_cards[1]
		if current and self:isFriend(current) and useable_cards[1]:isKindOf("Analeptic") then
			for _,c in ipairs(handcards) do
				if c:hasFlag("twyj_rangyi") and c:isAvailable(self.player) and not c:isKindOf("Analeptic") then
					use_card = c
				end
			end
		end
		
		local skillcard = twyj_rangyiUseCard:clone()
		skillcard:addSubcard(use_card)
		if use_card:targetFixed() then
			return skillcard:toString()
		else
			if use_card:isKindOf("Slash") then
				local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
				self:useBasicCard(use_card, dummyuse)
				local targets = {}
				if not dummyuse.to:isEmpty() then
					for _, p in sgs.qlist(dummyuse.to) do
						table.insert(targets, p:objectName())
					end
					if #targets > 0 then
						return skillcard:toString() .. "->" .. table.concat(targets, "+")
					end
				end
			end
			local dummyuse = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(use_card, dummyuse)
			local targets = {}
			if not dummyuse.to:isEmpty() then
				for _, p in sgs.qlist(dummyuse.to) do
					table.insert(targets, p:objectName())
				end
				if #targets > 0 then
					return skillcard:toString() .. "->" .. table.concat(targets, "+")
				end
			end
		end
	end
	return "."
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|twyj_qijia"
sgs.need_equip_skill = sgs.need_equip_skill .. "|twyj_qijia"
sgs.ai_cardneed.twyj_qijia = sgs.ai_cardneed.equip
local twyj_qijia_skill = {}
twyj_qijia_skill.name = "twyj_qijia"
table.insert(sgs.ai_skills, twyj_qijia_skill)
twyj_qijia_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getEquips():length() > 0 and self.player:canDiscard(self.player, "e") then
		return sgs.Card_Parse("#twyj_qijia:.:")
	end
end

sgs.ai_skill_use_func["#twyj_qijia"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "hp")
	local equipments = sgs.QList2Table(self.player:getCards("e"))
	local targets = {}
	local use_cards = {}
	for _,e in ipairs(equipments) do
		local equip_index = e:getRealCard():toEquipCard():location()
		if self.player:getMark("twyj_qijia_"..equip_index.."-Clear") == 0 and not (e:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			table.insert(use_cards, e)
		end
	end
	self:sortByKeepValue(use_cards)
	local rangefix = 0
	if #use_cards > 0 then
		if use_cards[1]:isKindOf("Weapon") then
			local card = use_cards[1]:getRealCard():toWeapon()
			rangefix = rangefix + card:getRange() - self.player:getAttackRange(false)
		end
		if use_cards[1]:isKindOf("OffensiveHorse") then
			rangefix = rangefix + 1
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) and self.player:canSlash(enemy, slash, false)
		and self.player:canSlash(enemy, true, rangefix) and not self:slashProhibit(slash, enemy)
		--不限制，能用就用
		--and not enemy:getArmor() and enemy:getHp() <= 2 and enemy:getHandcardNum() <= 2
		then
			table.insert(targets, enemy)
		end
	end
	if self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:isWounded() then
		local equip_index = self.player:getArmor():getRealCard():toEquipCard():location()
		for _, enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) and self.player:canSlash(enemy, slash, false)
			and not self:slashProhibit(slash, enemy) and self.player:getMark("twyj_qijia_"..equip_index.."-Clear") == 0
			then
				local card_str = string.format("#twyj_qijia:%s:", self.player:getArmor():getEffectiveId())
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if #targets == 0 or #use_cards == 0 then return end
	local card_str = string.format("#twyj_qijia:%s:", use_cards[1]:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_priority["twyj_qijia"] = 0
sgs.ai_use_value["twyj_qijia"] = 0
sgs.ai_card_intention["twyj_qijia"] = 80

local twyj_zhuchen_skill = {}
twyj_zhuchen_skill.name = "twyj_zhuchen"
table.insert(sgs.ai_skills, twyj_zhuchen_skill)
twyj_zhuchen_skill.getTurnUseCard = function(self, inclusive)
	if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then
		return sgs.Card_Parse("#twyj_zhuchen:.:")
	end
end

sgs.ai_skill_use_func["#twyj_zhuchen"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "hp")
	local targets = {}
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local use_cards = {}
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if not self.player:inMyAttackRange(enemy) and self.player:canSlash(enemy, slash, false)
		and not self:slashProhibit(slash, enemy) and not enemy:getArmor()
		and enemy:getHp() <= 2 and enemy:getHandcardNum() == 0
		then
			table.insert(targets, enemy)
		end
	end
	for _,c in ipairs(handcards) do
		if c:isKindOf("Analeptic") then
			table.insert(use_cards, c)
		end
	end
	if #targets == 0 or #use_cards == 0 or self.player:getEquips():length() < 2 or self:getCardsNum("Analeptic") < 2 then return end
	local card_str = string.format("#twyj_zhuchen:%s:", use_cards[1]:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_priority["twyj_zhuchen"] = 0
sgs.ai_use_value["twyj_zhuchen"] = 0
sgs.ai_card_intention["twyj_zhuchen"] = 80

sgs.need_equip_skill = sgs.need_equip_skill .. "|twyj_huzhu"
sgs.ai_cardneed.twyj_huzhu = sgs.ai_cardneed.equip
local twyj_huzhu_skill = {}
twyj_huzhu_skill.name = "twyj_huzhu"
table.insert(sgs.ai_skills, twyj_huzhu_skill)
twyj_huzhu_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#twyj_huzhu") and not self.player:getEquips():isEmpty() then
		return sgs.Card_Parse("#twyj_huzhu:.:")
	end
end

sgs.ai_skill_use_func["#twyj_huzhu"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends_noself, "hp")
	local targets = {}
	for _, friend in ipairs(self.friends_noself) do
		if friend:getHp() <= self.player:getHp() and friend:getHp() < 3 and friend:getHandcardNum() > 1 and friend:isWounded() then
			table.insert(targets, friend)
		end
	end
	if #targets == 0 then return end
	use.card = card
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_priority["twyj_huzhu"] = 3
sgs.ai_use_value["twyj_huzhu"] = 3

sgs.ai_card_intention["twyj_huzhu"] = function(self, card, from, tos)
	for _,to in ipairs(tos) do
		if to:getHp() > from:getHp() or not to:isWounded() then
			sgs.updateIntention(from, to, 20)
		end
	end
end

sgs.ai_skill_invoke["twyj_huzhu"] = function(self, data)
	local player = data:toPlayer()
	return player and self:isFriend(player)
end

sgs.ai_choicemade_filter.skillInvoke.twyj_huzhu = function(self, player, promptlist)
	local target = self.room:findPlayerByObjectName(promptlist[#promptlist - 1])
	if target then
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, target, -80)
		else
			sgs.updateIntention(player, target, 80)
		end
	end
end

sgs.ai_skill_cardask["@twyj_huzhu"] = function(self, data, pattern, target, target2)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(handcards)
	for _,c in ipairs(handcards) do
		return c:toString()
	end
end

sgs.ai_skill_invoke["twyj_liancai"] = function(self, data)
	local has_enemy_equips = false
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isEnemy(p) and p:getEquips():length() > 0 then
			has_enemy_equips = true
		end
	end
	
	local has_equip_enemy = 0
	local only_one_silver = false
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isEnemy(p) and p:getEquips():length() > 0 then
			has_equip_enemy = has_equip_enemy + 1
		end
		if p:getEquips():length() == 1 and p:hasArmorEffect("silver_lion") and p:isWounded() then
			only_one_silver = true
		end
	end
	if has_equip_enemy == 1 and only_one_silver then return false end
	
	if self.player:getHp() - self.player:getHandcardNum() > 0 and has_enemy_equips then
		return true
	end
	return false
end

sgs.ai_skill_askforag["twyj_liancai"] = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		local equip_card_owner = self.room:getCardOwner(card_id)
		if self:isFriend(equip_card_owner) and sgs.Sanguosha:getCard(card_id):isKindOf("SilverLion") and equip_card_owner:isWounded() and not table.contains(cards, sgs.Sanguosha:getCard(card_id)) then
			table.insert(cards, sgs.Sanguosha:getCard(card_id))
		elseif self:isEnemy(equip_card_owner) then
			if not (sgs.Sanguosha:getCard(card_id):isKindOf("SilverLion") and equip_card_owner:isWounded()) and not table.contains(cards, sgs.Sanguosha:getCard(card_id)) then
				table.insert(cards, sgs.Sanguosha:getCard(card_id))
			end
		end
	end
	self:sortByUseValue(cards, true)
	if #cards > 0 then
		return cards[1]:getEffectiveId()
	end
end

sgs.ai_skill_invoke["twyj_liancai_turnover"] = true

sgs.ai_skill_discard["command"] = function(self, discard_num, min_num, optional, include_equip)
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(usable_cards)
	local to_discard = {}
	for _,c in ipairs(usable_cards) do
		if #to_discard < discard_num then
			table.insert(to_discard, c:getEffectiveId())
		end
	end
	return to_discard
end

sgs.ai_skill_choice.do_command = function(self, choices, data)
	local from = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items, "command1") and math.random() < 0.5 then
		if self:isFriend(from) then
			return "command1"
		end
		if self.friends_noself and #self.friends_noself > 0 and self:getAllPeachNum() <= 0 then
			return "cancel"
		end
		return "command1"
	end
	if table.contains(items, "command2") then
		if self:doDisCard(self.player, "he", true) then
			return "command2"
		end
		if self:isFriend(from) then
			return "command2"
		end
	end
	if table.contains(items, "command3") then
		if hasZhaxiangEffect(self.player) and self.player:getHp() + self:getAllPeachNum() - 1 > 0 then
			return "command3"
		end
		if math.random() < 0.5 and self.player:getHp() + self:getAllPeachNum() - 1 > 0 then
			return "command3"
		end
	end
	if table.contains(items, "command4") then
		if math.random() < 0.5 then
			return "command4"
		end
	end
	if table.contains(items, "command5") then
		if not self:isWeak() and self.player:faceUp() then
			return "command5"
		end
	end
	if table.contains(items, "command6") then
		local hand_discard = self.player:getHandcardNum() - 1
		local equip_discard = self.player:getEquips():length() - 1
		if hand_discard + equip_discard <= 2 then
			return "command6"
		end
	end
	return "cancel"
end

sgs.ai_skill_playerchosen.command1 = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_use["@@command6!"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local ids = {}
	local hand_discard = self.player:getHandcardNum() - 1
	local equip_discard = self.player:getEquips():length() - 1
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards) do
		if c:isEquipped() then
			if equip_discard > 0 then
				equip_discard = equip_discard - 1
				table.insert(ids, c:getEffectiveId())
			end
		else
			if hand_discard > 0 then
				hand_discard = hand_discard - 1
				table.insert(ids, c:getEffectiveId())
			end
		end
	end
	if #ids == 0 then return "." end
	return DummyCard:clone():objectName() .. ":"..table.concat(ids,"+") ..":"
end

sgs.ai_skill_cardask["@heg_jieyue-give"] = function(self, data, pattern, target, target2)
	if sgs.ai_skill_playerchosen.heg_jieyue(self, self.room:getOtherPlayers(self.player)) ~= nil then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.heg_jieyue = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention["heg_jieyue"] = 40

sgs.ai_skill_playerschosen.heg_fengying = function(self, targets, max, min)
	local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if self:isFriend(target) and self:canDraw(target) then
			selected:append(target)
			if selected:length() >= max then break end
		end
	end
	return selected
end

sgs.ai_playerschosen_intention.heg_fengying = function(self, from, prompt)
    local intention = -60
    local tolist = prompt:split("+")
    for _, dest in ipairs(tolist) do
        local to = self.room:findPlayerByObjectName(dest)
        sgs.updateIntention(from, to, intention)
    end
end


sgs.ai_fill_skill.heg_jianglue = function(self)
	if (sgs.turncount>1) or (self:isWeak()) then
		return sgs.Card_Parse("#heg_jianglue:.:")
	end
end

sgs.ai_skill_use_func["#heg_jianglue"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority["heg_jianglue"] = 9.31

sgs.ai_skill_playerschosen.heg_jianglue = function(self, targets, max, min)
	local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if self:isFriend(target) then
			selected:append(target)
			if selected:length() >= max then break end
		end
	end
	return selected
end

sgs.ai_playerschosen_intention.heg_jianglue = function(self, from, prompt)
    local intention = -60
    local tolist = prompt:split("+")
    for _, dest in ipairs(tolist) do
        local to = self.room:findPlayerByObjectName(dest)
        sgs.updateIntention(from, to, intention)
    end
end

sgs.ai_skill_choice.start_command_heg_jianglue = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "command1") then
		return "command1"
	end
	if table.contains(items, "command2") then
		return "command2"
	end
	if table.contains(items, "command4") then
		return "command4"
	end
	return items[math.random(1,#items)]
end

sgs.ai_fill_skill.heg_xuanhuoAttach = function(self)
	if self:isWeak() or self.player:isKongcheng() or self:needBear() then return end
	return sgs.Card_Parse("#heg_xuanhuo:.:")
end

sgs.ai_skill_use_func["#heg_xuanhuo"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _, friend in ipairs(self.friends_noself) do
		if friend:hasSkill("heg_xuanhuo") and self:canDraw(friend, self.player) and friend:getMark("heg_xuanhuo"..self.player:objectName().."-PlayClear") == 0 then
			use.card = sgs.Card_Parse("#heg_xuanhuo:"..cards[1]:getEffectiveId()..":")
			use.to:append(friend)
			return
		end
	end
	
end

sgs.ai_use_value.heg_xuanhuo = 4.4
sgs.ai_use_priority.heg_xuanhuo = 5.2

sgs.ai_skill_discard.heg_enyuan = sgs.ai_skill_discard.enyuan

sgs.ai_skill_use["@@heg_keshou"] = function(self,prompt,method)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local damage = self.room:getTag("heg_keshou"):toDamage()
	if self:needToLoseHp(self.player,damage.from,damage.card) then
		return "."
	end
	local use_cards = {}
	for _,c in ipairs(cards)do
		if self:getKeepValue(c) <= 6 then
			for _,c2 in ipairs(cards)do
				if c ~= c2 and c:getColor() == c2:getColor() then
					table.insert(use_cards,c2)
					table.insert(use_cards,c)
					break
				end
			end
			if #use_cards >= 2 then break end
		end
	end
	if #use_cards < 2 then return "." end
	local card_str = "#heg_keshou:"..use_cards[1]:getEffectiveId().."+"..use_cards[2]:getEffectiveId()..":"
	return card_str
end

sgs.ai_skill_invoke.heg_zhuwei = function(self, data)
	if data:toCard() then
		return true
	end
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.heg_buyi = function(self, data)
	local target = data:toDying().who
	if target and self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_can_damagehp.heg_fudi = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		local targets = sgs.SPlayerList()
		local max = 0
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getHp() > max then
				max = p:getHp()
			end
		end
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if p:getHp() == max and p:getHp() >= to:getHp() then
				targets:append(p)
			end
		end
		if not targets:isEmpty() then
			for _, p in sgs.qlist(targets) do
				if self:isEnemy(p) and self:canDamage(p, to, nil) then
					return self:isFriend(from) and not to:isKongcheng()
				end
			end
		end
	end
end

sgs.ai_skill_cardask["@heg_fudi-give"] = function(self, data, pattern, target, target2)
	local damage = data:toDamage()
	local targets = sgs.SPlayerList()
	local max = 0
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() > max then
			max = p:getHp()
		end
	end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getHp() == max and p:getHp() >= self.player:getHp() then
			targets:append(p)
		end
	end
	if not targets:isEmpty() then
		for _, p in sgs.qlist(targets) do
			if self:isEnemy(p) and self:canDamage(p, self.player, nil) then
				return true
			end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.heg_fudi = sgs.ai_skill_playerchosen.damage

sgs.ai_skill_invoke.heg_liangfan = function(self, data)
	local target = data:toPlayer()
	if target then
		return self:doDisCard(target, "he", true)
	end
	return false
end

sgs.ai_ajustdamage_from.heg_congjian = function(self, from, to, damage)
	if from and from:getPhase() == sgs.Player_NotActive then
		return 1
	end
end
sgs.ai_ajustdamage_to.heg_congjian = function(self, from, to, damage)
	if to:getPhase() ~= sgs.Player_NotActive then
		return 1
	end
end

sgs.ai_skill_invoke.heg_qiuan = function(self, data)
	local damage = data:toDamage()
	if self:needToLoseHp(damage.to, damage.from, damage.card) then
		return false
	end
	return true
end

sgs.ai_skill_invoke.heg_liangfan = function(self, data)
	local target = data:toDamage().to
	if target and self:doDisCard(target,"he",true) then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.heg_wenji = function(self,targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets,"handcard")
	
	targets = sgs.reverse(targets)
	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:doDisCard(p,"he",true) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:isFriend(p) and p:hasSkills(sgs.lose_equip_skill) and (p:getEquips():length()>1 or p:getPile("wooden_ox"):isEmpty()) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:isEnemy(p) and self:doDisCard(p,"he",true) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:getOverflow(p)>0 then
			return p
		end
	end
	return nil
end

sgs.ai_skill_invoke.heg_wenji = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@heg_fengshih"] = function(self, data, pattern, target, target2)
	local use = data:toCardUse()
	local target
	if use.from:objectName() == self.player:objectName() then
		target = use.to:first()
	else
		target = use.from
	end
	if target then
		if self:doDisCard(target, "he") then
			return true
		end
	end
end

sgs.ai_ajustdamage_from.heg_fengshih = function(self, from, to, damage)
	if card and card:hasFlag("heg_fengshih") then
		return 1
	end
end
sgs.ai_ajustdamage_to.heg_fengshih = function(self, from, to, damage)
	if card and card:hasFlag("heg_fengshih") then
		return 1
	end
end

sgs.ai_skill_playerchosen.heg_bushi = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	return self:findPlayerToDraw(true, 1)
end

sgs.ai_playerchosen_intention.heg_bushi = -50

sgs.ai_skill_cardask["@heg_midao-give"] = function(self, data, pattern, target, target2)
	if target and self:isFriend(target) and self:canDraw(target, self.player) and self:getOverflow() > 0 then
		return true
	end
end

sgs.ai_skill_choice.heg_lixia = function(self, choices, data)
	local draw = getChoice(choices, "draw")
	local discard = getChoice(choices, "discard")
	if discard then
		local target = data:toPlayer()
		if self:doDisCard(target, "e") and self:isEnemy(target) and (self:getAllPeachNum() + self.player:getHp() - 1 > 0) and (hasZhaxiangEffect(self.player) or math.random() < 0.5) then
			return discard
		end
	end
	return draw
end

sgs.ai_skill_invoke.heg_nos_lixia = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) and self:canDraw(target, self.player) and self:doDisCard(target, "e") then
		return true
	end
	if target and self:isEnemy(target) and self:doDisCard(target, "e") then
		if self:getAllPeachNum() + self.player:getHp() - 1 > 0 and (hasZhaxiangEffect(self.player) or math.random() < 0.5) and not self:isWeak() then
			return true
		end
		if self:needToThrowCard(self.player,"h",true,false,false) then
			return true
		end
	end
	return false
end

sgs.ai_skill_choice.heg_nos_lixia = function(self, choices, data)
	local draw = getChoice(choices, "draw")
	local items = choices:split("+")
	local target = data:toPlayer()
	if draw then
		if self:isFriend(target) and self:canDraw(target) then
			return draw
		end
	end
	if table.contains(items, "discard") then
		if self:needToThrowCard(self.player,"h",true,false,false) then
			return "discard"
		end
	end
	if table.contains(items, "loseHp") then
		if self.player:getHp() + self:getAllPeachNum() - 1 > 0 and (hasZhaxiangEffect(self.player) or math.random() < 0.5) and not self:isWeak() then
			return "loseHp"
		end
	end

	return draw
end

sgs.ai_fill_skill.heg_quanjin = function(self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
        return sgs.Card_Parse("#heg_quanjin:" .. card:getEffectiveId() .. ":")
    end
end

sgs.ai_skill_use_func["#heg_quanjin"] = function(card,use,self)
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("heg_quanjin-PlayClear") > 0 then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_fill_skill.heg_zaoyun = function(self)
	if self:isWeak() or self.player:isKongcheng() or self:needBear() then return end
	return sgs.Card_Parse("#heg_zaoyun:.:")
end

sgs.ai_skill_use_func["#heg_zaoyun"] = function(card,use,self)
	self:sort(self.enemies, "hp")
	local targets = sgs.SPlayerList()
	for _, enemy in ipairs(self.enemies) do
		if self.player:distanceTo(enemy) > 1 then
			targets:append(enemy)
		end
	end
	if targets:isEmpty() then return end
	local target = self:findPlayerToDamage(1,self.player,sgs.DamageStruct_Normal,targets,3,nil)[1]
	if not target then return end
	local use_cards = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards)do
		if self:getKeepValue(c) <= 6 then
			table.insert(use_cards,c:getEffectiveId())
			if #use_cards >= self.player:distanceTo(target) - 1 then break end
		end
	end
	if #use_cards == self.player:distanceTo(target) - 1 then
		use.card = sgs.Card_Parse("#heg_zaoyun:"..table.concat(use_cards, "+")..":")
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_priority["heg_zaoyun"] = sgs.ai_use_priority.QiangxiCard

sgs.ai_skill_invoke.heg_qiance = function(self, data)
	local use = data:toCardUse()
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(use.to) do
		if IsBigKingdomPlayer(p) then
			targets:append(p)
		end
	end
	if not targets:isEmpty() then
		for _, p in sgs.qlist(targets) do
			if self:isFriend(p) then
				return false
			end
		end
		if use.card and use.card:isDamageCard() then
			for _, p in sgs.qlist(targets) do
				if self:isEnemy(p) and self:canDamage(p,use.from,use.card) then
					return true
				end
			end
		else
			if math.random() < 0.5 then
				for _, p in sgs.qlist(targets) do
					if self:isEnemy(p) then
						return true
					end
				end
			end
		end
	end
	return false
end

sgs.ai_skill_invoke.heg_jujian = function(self, data)
	local target = data:toDying().who
	if target and self:isFriend(target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.heg_jujian = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:getCurrentDyingPlayer()
		if target then sgs.updateIntention(player,target,-80) end
	end
end

sgs.ai_skill_playerchosen.heg_zhidao = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	self:getTurnUse()
	if #self.toUse > 1 then
		for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
			if table.contains(self.toUse,c) then
				self.player:setFlags("InfinityAttackRange")
				local dummy_use = self:aiUseCard(c, dummy())
				self.player:setFlags("-InfinityAttackRange")
				if dummy_use and dummy_use.card and not dummy_use.to:isEmpty() then
					for _,p in sgs.qlist(dummy_use.to)do
						if self:isEnemy(p) and self:canDamage(p,self.player) and table.contains(targets, p) then
							return p
						end
					end
				end
			end
		end
	end
	for _,p in ipairs(targets)do
		if self:isEnemy(p) and self:canDamage(p,self.player) then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:isEnemy(p) then
			return p
		end
	end
	return targets[1]
end

sgs.ai_playerchosen_intention.heg_zhidao = 80


sgs.ai_fill_skill.heg_jinfa = function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		return sgs.Card_Parse("#heg_jinfa:" .. card:getEffectiveId() .. ":")
	end
end

sgs.ai_skill_use_func["#heg_jinfa"] = function(card,use,self)
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
	slash:setSkillName("heg_jinfa")
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isNude() and self:doDisCard(enemy, "he", true) and (not self:isWeak() or not self:slashIsEffective(slash, self.player,enemy) or not self:canHit(self.player,enemy)) then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if not friend:isNude() and self:doDisCard(friend, "he", true) then
			use.card = card
			if use.to then use.to:append(friensd) end
			return
		end
	end
end

sgs.ai_choicemade_filter.cardChosen.heg_jinfa = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_cardask["@heg_jinfa"] = function(self, data, pattern, target, target2)
	if target then
		if self:isFriend(target) then
			return "."
		end
		if self:isEnemy(target) then
			local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, -1)
			slash:setSkillName("heg_jinfa")
			slash:deleteLater()
			if self:slashIsEffective(slash, target,self.player) then
				for _,c in ipairs(self:sortByKeepValue(sgs.QList2Table(self.player:getCards("he"))))do
					if sgs.Sanguosha:matchPattern(pattern,self.player,c)
					and c:getSuit() == sgs.Card_Spade
					then return c:toString() end
				end
			end
		end
	end
	return true
end

sgs.ai_skill_playerschosen.heg_baolie = function(self, targets, max, min)
	local selected = sgs.SPlayerList()
	local can_choose = sgs.QList2Table(targets)
	self:sort(can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if self:isEnemy(target) and self:doDisCard(target, "he") and self:isTiaoxinTarget(target) then
			selected:append(target)
		end
	end
	if selected:isEmpty() then
		for _,target in ipairs(can_choose) do
			if self:isEnemy(target) and self:isTiaoxinTarget(target) then
				selected:append(target)
				if selected:length() >= min then break end
			end
		end
	end
	if selected:isEmpty() then
		for _,target in ipairs(can_choose) do
			if self:isEnemy(target) then
				selected:append(target)
				if selected:length() >= min then break end
			end
		end
	end
	return selected
end

sgs.ai_playerschosen_intention.heg_baolie = function(self, from, prompt)
    local intention = 20
    local tolist = prompt:split("+")
    for _, dest in ipairs(tolist) do
        local to = self.room:findPlayerByObjectName(dest)
        sgs.updateIntention(from, to, intention)
    end
end

sgs.ai_skill_invoke.heg_chenglue = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) and self:canDraw(target) then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.heg_chenglue = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local to  = self:findPlayerToDraw(true,1)
	if to then return to end
	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:getOverflow(p) > 0 then
			return p
		end
	end
	for _,p in ipairs(targets)do
		if self:isFriend(p) then
			return p
		end
	end
	return nil 
end

sgs.ai_choicemade_filter.skillInvoke.heg_chenglue = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end

sgs.ai_playerchosen_intention.heg_chenglue = -50

sgs.ai_skill_playerchosen.heg_lianpian = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:canDraw(p) then
			return p
		end
	end
	return nil 
end

sgs.ai_playerchosen_intention.heg_lianpian = -50

sgs.ai_skill_choice.heg_lianpian = function(self, choices, data)
	local discard = getChoice(choices, "discard")
	local recover = getChoice(choices, "recover")
	local target = data:toPlayer()
	if self:isFriend(target) then
		if target:getHp() < getBestHp(target) then
			return recover
		end
	end
	if discard and self:doDisCard(target, "he") then
		return discard
	end
	return "cancel"
end

sgs.ai_choicemade_filter.skillChoice.heg_lianpian = function(self,player,promptlist)
	local choice = promptlist[#promptlist]
	local target = nil
	for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
		if p:hasFlag("heg_lianpianTarget") then
			target = p
			break
		end
	end
	if not target then return end
	if choice=="recover" then sgs.updateIntention(player,target,-60) end
end

sgs.ai_choicemade_filter.cardChosen.heg_lianpian = sgs.ai_choicemade_filter.cardChosen.snatch

sgs.ai_skill_invoke.heg_congcha = true

sgs.ai_skill_playerchosen.heg_congcha = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets)do
		if self:isFriend(p) and self:canDraw(p) then
			return p
		end
	end
	return nil 
end

sgs.ai_playerchosen_intention.heg_congcha = -50

sgs.ai_skill_invoke.heg_jinxian = function(self, data)
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:distanceTo(p) <= 1 then
			targets:append(p)
		end
	end
	if targets:isEmpty() then return false end
	local good = 0
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) and self:doDisCard(p, "he") then
			good = good + 2
		elseif self:isFriend(p) and not self:doDisCard(p, "he") then
			good = good - 2
		end
	end
	if good > 0 then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.heg_tongling = function(self, targets)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if not damage then return nil end
	if damage.to and damage.to:isAlive() and self:isFriend(damage.to) then
		return nil
	end
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard", true)
	for _,p in sgs.list(targets)do
		local x = 0
		local kc = getKnownCards(p,self.player)
		for _,c in sgs.list(kc)do
			if c:isDamageCard() then
				x = x + 1
			end
		end
		x = x + p:getHandcardNum()/3
		if x > max then
			max = x
		end
	end
	for _,p in sgs.list(targets)do
		local x = 0
		local kc = getKnownCards(p,self.player)
		for _,c in sgs.list(kc)do
			if c:isDamageCard() then
				x = x + 1
			end
		end
		x = x + p:getHandcardNum()/3
		if x == max then
			return p
		end
	end
	return nil 
end

sgs.ai_playerchosen_intention.heg_tongling = -20

sgs.ai_skill_cardask["@heg_nos_daming"] = function(self, data, pattern, target, target2)
	local current = self.room:getCurrent()
	if not current or not current:isAlive() then return "." end
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if not p:isChained() then
			targets:append(p)
		end
	end
	if targets:isEmpty() then return "." end
	if self:isFriend(current) then
		if current:getHp() < getBestHp(current) then
			self.heg_nos_daming = "peach"
			return true
		end
	end
	local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
	thunder_slash:setSkillName("heg_nos_daming")
	thunder_slash:deleteLater()
	self.player:setFlags("InfinityAttackRange")
	local dummy_use = self:aiUseCard(thunder_slash, dummy())
	self.player:setFlags("-InfinityAttackRange")
	if dummy_use and dummy_use.card and not dummy_use.to:isEmpty() then
		self.heg_nos_daming = "thunder_slash"
		return true
	end
	return "."
end

sgs.ai_skill_playerchosen.heg_nos_daming = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets)do
		if self:isEnemy(p) and not p:isChained() then
			return p
		end
	end
	return targets[1] 
end

sgs.ai_skill_playerchosen.heg_nos_daming_slash = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
	thunder_slash:setSkillName("heg_nos_daming")
	thunder_slash:deleteLater()
	self.player:setFlags("InfinityAttackRange")
	local dummy_use = self:aiUseCard(thunder_slash, dummy())
	self.player:setFlags("-InfinityAttackRange")
	if dummy_use and dummy_use.card and not dummy_use.to:isEmpty() then
		for _,p in sgs.qlist(dummy_use.to)do
			if self:isEnemy(p) and table.contains(targets, p) then
				return p
			end
		end
	end
	return targets[1] 
end

sgs.ai_playerchosen_intention.heg_nos_daming = 30

sgs.ai_playerchosen_intention.heg_nos_daming_slash = function(self,from,to)
	local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
	thunder_slash:setSkillName("heg_nos_daming")
	thunder_slash:deleteLater()
	local callback = sgs.ai_card_intention.Slash(self, thunder_slash, from, {to})
	sgs.updateIntentions(from,to,callback) 
end

sgs.ai_skill_choice.heg_nos_daming = function(self, choices, data)
	local items = choices:split("+")
	if self.heg_nos_daming then return self.heg_nos_daming end
	return items[math.random(1,#items)]
end

sgs.ai_choicemade_filter.skillChoice.heg_nos_daming = function(self,player,promptlist)
	local choice = promptlist[#promptlist]
	local target = self.room:getCurrent()
	if not target then return end
	if choice=="peach" then sgs.updateIntention(player,target,-40) end
end

sgs.ai_suppress_intention["heg_nos_daming"] = true

sgs.ai_canliegong_skill.heg_nos_xiaoni = function(self, from, to)
	local same_faction = true
	local x = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(from)) do
		if p:getKingdom() == from:getKingdom() then
			x = x + 1
			if p:getHandcardNum() > from:getHandcardNum() then
				same_faction = false
				break
			end
		end
	end
	if same_faction and x > 0 then
		return true
	end
end

sgs.ai_skill_invoke.heg_juejue = function(self, data)
	if self.player:getHp() + self:getAllPeachNum() - 1 > 0 then
		return (math.random() < 0.5 or hasZhaxiangEffect(self.player)) and not self:isWeak() and self:getOverflow() > 0
	end
	return false
end

sgs.ai_skill_discard.heg_juejue = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local to_discard = {}
	local current = self.room:getCurrent()
	if not current or not current:isAlive() then
		return to_discard
	end
	if self:needToLoseHp(self.player, current, nil) or not self:damageIsEffective(self.player,nil,current) then
		return to_discard
	end
	if not self:isWeak() and min_num > 2 then
		return to_discard
	end
	if self:getCardsNum("Peach") > 0 and discard_num > 2 then
		return to_discard
	end
	for _,c in ipairs(cards)do
		if self:getKeepValue(c) <= 6 then
			table.insert(to_discard,c:getEffectiveId())
			if #to_discard >= discard_num then break end
		end
	end
	if #to_discard < min_num then
		return {}
	end
	return to_discard
end

sgs.ai_skill_playerchosen.heg_fangyuan = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_skill_invoke.heg_tongdu = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) and self:canDraw(target, self.player) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_tongdu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-80) end
	end
end

sgs.ai_fill_skill.heg_qingyin = function(self)
	if (#self.friends<=#self.enemies and sgs.turncount>2 and self.player:getLostHp()>0) or (sgs.turncount>1 and self:isWeak()) then
		return sgs.Card_Parse("#heg_qingyin:.:")
	end
end

sgs.ai_skill_use_func["#heg_qingyin"] = function(card,use,self)
	use.card = card
	for i = 1,#self.friends do
		use.to:append(self.friends[i])
	end
end

sgs.ai_card_intention["heg_qingyin"] = -80
sgs.ai_use_priority["heg_qingyin"] = 9.31

sgs.ai_fill_skill.heg_duwu = function(self)
	if #self.enemies == 0 then return end
	if (#self.friends<=#self.enemies and sgs.turncount>2 and self.player:getLostHp()>0) or (sgs.turncount>1 and self:isWeak()) then
		return sgs.Card_Parse("#heg_duwu:.:")
	end
end

sgs.ai_skill_use_func["#heg_duwu"] = function(card,use,self)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if self:canDamage(enemy) and self.player:inMyAttackRange(enemy) then
			table.insert(targets, enemy)
		end
	end
	if #targets == 0 then return end
	self:sort(targets, "defense")
	use.card = card
	for i = 1, #targets do
		use.to:append(targets[i])
	end
end

sgs.ai_card_intention["heg_duwu"] = 80
sgs.ai_use_priority["heg_duwu"] = sgs.ai_use_priority.DuwuCard

sgs.ai_skill_use["@@heg_fk_bushi"] = function(self, prompt, method)
	local ids = self.player:getPile("heg_fk_rice")
    local cards = {}
    for _,id in sgs.list(ids)do
        table.insert(cards,sgs.Sanguosha:getCard(id))
    end
	local targets = {}
	for _, friend in ipairs(self.friends) do
		if self:canDraw(friend, self.player) then
			table.insert(targets, friend:objectName())
		end
	end
	if #targets == 0 or #cards == 0 then return "." end
	return "#heg_fk_bushi:"..cards[1]:getEffectiveId()..":->"..table.concat(targets,"+")
end


sgs.ai_card_intention["heg_fk_bushi"] = -50

sgs.ai_skill_cardask["@heg_fk_bushi-put"] = function(self, data, pattern, target, target2)
	if self:isFriend(target) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		for _,c in ipairs(cards)do
			if self:getKeepValue(c) > 6 then continue end
			return "$"..c:getEffectiveId()
		end
		if self.player:objectName() == target:objectName() then
			return "$"..cards[1]:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_skill_cardask["@heg_fk_midao-card"] = function(self, data, pattern, target, target2)
    local judge = self.player:getTag("judgeData"):toJudge()
    local ids = self.player:getPile("heg_fk_rice")
    local cards = {}
    for _,id in sgs.list(ids)do
        table.insert(cards,sgs.Sanguosha:getCard(id))
    end
    if self:needRetrial(judge) then
        local id = self:getRetrialCardId(cards,judge)
        if id~=-1 then return "$"..id end
    end
    return "."    
end

sgs.ai_skill_invoke.heg_true_pozhen = function(self, data)
	local target = self.room:getCurrent()
	if not target or not target:isAlive() or not self:isEnemy(target) then 
		return false 
	end
	
	-- Safety check: need at least 3 players for encirclement/queue mechanics
	local aliveCount = self.room:alivePlayerCount()
	if aliveCount < 2 then
		return (target:getHandcardNum() > 3 and not self:willSkipPlayPhase(target)) or self:isWeak()
	end
	
	local x = 0
	
	-- Check encirclement with safety
	if aliveCount >= 3 and IsEncircled and type(IsEncircled) == "function" then
		local success, isEncircled = pcall(IsEncircled, target)
		if success and isEncircled then
			local success2, encirclers = pcall(GetEncirclers, target)
			if success2 and encirclers and type(encirclers) == "table" and #encirclers > 0 and #encirclers <= aliveCount then
				local processed = {}
				for _, q in ipairs(encirclers) do
					if q and q:isAlive() and not processed[q:objectName()] then
						processed[q:objectName()] = true
						if self:doDisCard(q, "he") then
							x = x + 1
						end
					end
				end
			end
		end
	end
	
	-- Check queue with safety  
	if aliveCount >= 2 and IsInQueue and type(IsInQueue) == "function" then
		local success, inQueue = pcall(IsInQueue, target)
		if success and inQueue then
			local success2, queuers = pcall(GetQueueMembers, target)
			if success2 and queuers and type(queuers) == "table" and #queuers > 0 and #queuers <= aliveCount then
				local processed = {}
				for _, q in ipairs(queuers) do
					if q and q:isAlive() and not processed[q:objectName()] then
						processed[q:objectName()] = true
						if self:doDisCard(q, "he") then
							x = x + 1
						end
					end
				end
			end
		end
	end
	
	return (((x >= 2) or (target:getHandcardNum() > 3)) and not self:willSkipPlayPhase(target)) or self:isWeak()
end

sgs.ai_choicemade_filter.skillInvoke.heg_true_pozhen = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:getCurrent()
		if target then sgs.updateIntention(player,target,80) end
	end
end

sgs.ai_skill_invoke.heg_true_jiancai_change = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end
sgs.ai_skill_invoke.heg_true_jiancai = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isFriend(damage.to) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.heg_true_jiancai = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:getCurrentDyingPlayer()
		if target then sgs.updateIntention(player,target,-50) end
	end
end

sgs.ai_skill_invoke.DragonPhoenix = function(self, data)
	local target = data:toPlayer()
	if self.room:getCurrentDyingPlayer() and self.room:getCurrentDyingPlayer():objectName() == target:objectName() then
		return self:doDisCard(target, "he", true)
	end
	if target then
		return self:doDisCard(target, "he")
	end
	return false
end

sgs.ai_view_as.heg_lord_shouyue_wusheng = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and not card:isKindOf("Peach") and not card:hasFlag("using") and player:getKingdom() == "shu" then
		local skill_name = ""
		for _,sk in sgs.list(player:getVisibleSkillList())do
			if sk:isAttachedLordSkill() then continue end
			if string.find(sk:objectName(), "wusheng") then
				skill_name = sk:objectName()
				break
			end
		end
		if skill_name== "" then return nil end
		local can_invoke = false
		for _, p in sgs.qlist(player:getAliveSiblings()) do
			if p:hasSkill("heg_lord_shouyue") then
				can_invoke = true
				break
			end
		end
		if not can_invoke then return nil end
		return ("slash:%s[%s:%s]=%d"):format(skill_name, suit,number,card_id)
	end
end

sgs.ai_fill_skill.heg_lord_shouyue_wusheng = function(self)
	local cards = self:addHandPile("he")
	cards = self:sortByUseValue(cards,true)
	if self.player:getKingdom() ~= "shu" then return nil end
	local skill_name = ""
	for _,sk in sgs.list(self.player:getVisibleSkillList())do
		if sk:isAttachedLordSkill() then continue end
		if string.find(sk:objectName(), "wusheng") then
			skill_name = sk:objectName()
			break
		end
	end
	if skill_name== "" then return nil end
	local can_invoke = false
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasSkill("heg_lord_shouyue") then
			can_invoke = true
			break
		end
	end
	if not can_invoke then return nil end
	local use_card = {}
	local useAll = false
	self:sort(self.enemies,"defense")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<2 and not enemy:hasArmorEffect("EightDiagram")
		and self.player:distanceTo(enemy)<=self.player:getAttackRange() and self:isWeak(enemy)
		and getCardsNum("Jink",enemy,self.player)+getCardsNum("Peach",enemy,self.player)+getCardsNum("Analeptic",enemy,self.player)<1
		then useAll = true break end
	end
	local disCrossbow = false
	if self:getCardsNum("Slash")<2
	or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao")
	then disCrossbow = true end
	self:sort(self.enemies,"defense")

	for _,card in ipairs(cards)do
		if (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (not isCard("Crossbow",card,self.player) or disCrossbow)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard())>0)
		then table.insert(use_card,card) end
	end

	for _,card in ipairs(use_card)do
		local slash = dummyCard("slash")
		slash:addSubcard(card)
		slash:setSkillName(skill_name)
		if slash:isAvailable(self.player)
		then return slash end
	end
end

sgs.ai_skill_invoke.heg_lord_jizhao = sgs.ai_skill_invoke.niepan

sgs.ai_canNiepan_skill.heg_lord_jizhao = function(player)
	return player:getMark("heg_lord_jizhao_used") == 0
end

sgs.ai_ajustdamage_from.PeaceSpell = function(self, from, to, card, nature)
	if nature ~= "N" and not IgnoreArmor(from,to) then
		return -99
	end
end

sgs.ai_skill_invoke.heg_lord_hongfa = true

sgs.ai_cardsview["heg_lord_hongfa_Attach"] = function(self,class_name,player)
	if class_name=="Slash" then
		for _, p in sgs.qlist(self.room:findPlayersBySkillName("heg_lord_hongfa")) do
			if p:getPile("heg_lord_hongfa"):length() > 0 and p:getKingdom() == player:getKingdom() then
				for _,id in sgs.list(p:getPile("heg_lord_hongfa"))do
					local c = dummyCard()
					c:setSkillName("heg_lord_hongfa")
					c:addSubcard(id)
					return c:toString()
				end
			end
		end
		
	end
end

addAiSkills("heg_lord_hongfa_Attach").getTurnUseCard = function(self)
	local dc = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	dc:setSkillName("_heg_lord_hongfa")
	dc:deleteLater()
	local dummy = self:aiUseCard(dc)
	if dummy.card then
		for _, p in sgs.qlist(self.room:findPlayersBySkillName("heg_lord_hongfa")) do
			if p:getPile("heg_lord_hongfa"):length() > 0 and sgs.Slash_IsAvailable(self.player) and p:getKingdom() == self.player:getKingdom() then 
				local cards = sgs.CardList()
				for _,id in sgs.list(p:getPile("heg_lord_hongfa")) do
					cards:append(sgs.Sanguosha:getCard(id))
				end
				cards = sgs.QList2Table(cards) -- 将列表转换为表
				self:sortByKeepValue(cards) -- 按保留值排序
				for _,h in sgs.list(cards)do
					dc:addSubcard(h)
					if dc:isAvailable(self.player) then
						local d = self:aiUseCard(dc)
						if d.card then
							return dc
						end
					end
					dc:clearSubcards()
					break
				end
			end
		end
	end
end

sgs.ai_fill_skill.heg_lord_wendao = function(self)
	local to_get
	for _, id in sgs.qlist(self.room:getDiscardPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf("PeaceSpell") then
			to_get = sgs.Sanguosha:getCard(id)
			break
		end
	end
	if not to_get then
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			for _, c in sgs.qlist(p:getCards("ej")) do
				if c:isKindOf("PeaceSpell") then
					to_get = c
					break
				end
			end
			if to_get then break end
		end
	end
	if not to_get then return nil end
	local use_card
    local cards = self.player:getCards("h")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	if self.player:hasSkill("heg_lord_hongfa") and self.player:getPile("heg_lord_hongfa"):length() > 0 then
		for i,h in sgs.list(cards)do
			if h:isKindOf("PeaceSpell") then
				use_card = h
				break
			end
		end
	end
	if not use_card then
		for i,h in sgs.list(cards)do
			if h:isRed() then
				use_card = h
				break
			end
		end
	end
	if use_card then
		return sgs.Card_Parse("#heg_lord_wendao:"..use_card:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#heg_lord_wendao"] = function(card,use,self)
	use.card = card
	use.to:append(self.player)
end

sgs.ai_use_priority["heg_lord_wendao"] = 3

function sgs.ai_armor_value.heg_lord_hongfa(player, self, card)
    if card and card:isKindOf("PeaceSpell") then return 4 end
end
function sgs.ai_armor_value.heg_lord_wendao(player, self, card)
    if card and card:isKindOf("PeaceSpell") then return 4 end
end


sgs.ai_fill_skill.heg_lord_jiahe_Attach = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByUseValue(cards,true)
	local use_card = nil
	for _,c in ipairs(cards)do
		if c:isKindOf("EquipCard") then
			use_card = c
			break
		end
	end
	if use_card then
		return sgs.Card_Parse("#heg_lord_jiahe_Attach:"..use_card:getEffectiveId()..":")
	end
	return nil
end

sgs.ai_skill_use_func["#heg_lord_jiahe_Attach"] = function(card,use,self)
	for _, p in sgs.qlist(self.room:findPlayersBySkillName("heg_lord_jiahe")) do
		if self:isFriend(p) then
			use.card = card
			if use.to then use.to:append(p) end
			return
		end
	end
end

sgs.ai_use_priority["heg_lord_jiahe_Attach"] = sgs.ai_use_priority.ZhihengCard + 1

sgs.ai_skill_invoke.heg_lord_jiahe = true

sgs.ai_fill_skill.heg_zhiheng = function(self)
	return sgs.Card_Parse("#heg_zhiheng:.:")
end

sgs.ai_skill_use_func["#heg_zhiheng"] = function(card,use,self)
	local card = sgs.Card_Parse("@ZhihengCard=.")
	local dummy_use = dummy()
	self:useSkillCard(card,dummy_use)
	if dummy_use.card then 
		local str = dummy_use.card:toString()
		str = string.gsub(str,"@ZhihengCard=","#heg_zhiheng:")
		if self.player:getMark("LuminousPearl_zhiheng") == 0 then
			str = "#heg_zhiheng:"
			local use_cards = dummy_use.card:getSubcards()
			local x = 0
			for _,id in sgs.list(use_cards) do
				str = str..id.."+"
				x = x + 1
				if x >= self.player:getMaxHp() then break end
			end
		end
		str = str..":"
		use.card = sgs.Card_Parse(str)
	end
end

sgs.ai_use_priority["heg_zhiheng"] = sgs.ai_use_priority.ZhihengCard

sgs.ai_fill_skill.heg_lord_lianzi = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByUseValue(cards,true)
	if #cards > 0 then
		return sgs.Card_Parse("#heg_lord_lianzi:"..cards[1]:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#heg_lord_lianzi"] = function(card,use,self)
	use.card = card
end
sgs.ai_use_priority["heg_lord_lianzi"] = sgs.ai_use_priority.ZhihengCard + 1


sgs.ai_skill_discard.heg_lord_jianan = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local to_discard = {}
	if self.player:hasSkills(sgs.bad_skills) or math.random() < 0.3 then
		for _,c in ipairs(cards) do
			if #to_discard < discard_num then
				table.insert(to_discard, c:getEffectiveId())
			end
		end
		if #to_discard < min_num then
			for _,c in ipairs(cards) do
				if not table.contains(to_discard, c:getEffectiveId()) then
					table.insert(to_discard, c:getEffectiveId())
					if #to_discard >= min_num then break end
				end
			end
		end
	end
	return to_discard
end

sgs.ai_skill_choice.heg_lord_jianan = function(self,choices)
	choices = choices:split("+")
	for _,choice in sgs.list(choices)do
		if string.find(sgs.bad_skills,choice) then
			return choice
		end
	end
	return choices[math.random(1,#choices)]
end


sgs.ai_fill_skill.heg_lord_huibian = function(self)
    return sgs.Card_Parse("#heg_lord_huibian:.:")
end

sgs.ai_skill_use_func["#heg_lord_huibian"] = function(card,use,self)
    self:sort(self.friends_noself, "hp")
    local target1, target2
    for _, friend in ipairs(self.friends_noself) do
        if friend:getHp() > 1 and self:canDamage(friend,self.player, nil) and self:canDraw(friend) and friend:getKingdom() == "wei" then
            target1 = friend
            break
        end
    end
    if not target1 then
        for _, enemy in ipairs(self.enemies) do
            if enemy:getHp() > 1 and self:canDamage(enemy,self.player, nil) and enemy:getKingdom() == "wei" then
                target1 = enemy
                break
            end
        end
    end
    if not target1 then return end
    for i = #self.friends_noself, 1, -1 do
        local friend = self.friends_noself[i]
        if friend:isWounded() and friend:objectName() ~= target1:objectName() and friend:getKingdom() == "wei" then
            target2 = friend
            break
        end
    end
    if target1 and target2 then
        use.card = sgs.Card_Parse("#heg_lord_huibian:.:")
        use.to:append(target1)
        use.to:append(target2)
        return
    end
end

function sgs.ai_armor_value.heg_lord_zongyu(player, self, card)
    if card and card:isKindOf("SixDragons") then return 4 end
end

sgs.ai_skill_invoke.heg_lord_zongyu = true

sgs.ai_fill_skill.heg_guikuang = function(self)
	return sgs.Card_Parse("#heg_guikuang:.:")
end

sgs.ai_skill_use_func["#heg_guikuang"] = function(card,use,self)
	self:sort(self.enemies,"handcard")
	local target
	local target2
	for _,enemy in sgs.list(self.enemies)do
		for _,enemy2 in sgs.list(self.enemies)do
			if enemy:canPindian(enemy2) and enemy:objectName()~=enemy2:objectName() and enemy:getKingdom() ~= enemy2:getKingdom() and self:canDamage(enemy,enemy2,nil) and self:canDamage(enemy2,enemy,nil)
			then target = enemy target2 = enemy2 break end
		end
	end
	if target and target2 then
		use.card = sgs.Card_Parse("#heg_guikuang:.:")
		use.to:append(target)
		use.to:append(target2)
		return
	end
end

sgs.ai_skill_invoke.heg_ov_zhenxi = function(self, data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return true
	end
	return self:doDisCard(target, "he")
end

sgs.ai_skill_choice.heg_ov_zhenxi = function(self, choices, data)
	choices = choices:split("+")
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		if table.contains(choices, "use") then
			local acard = sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuitRed, 0)
			acard:deleteLater()
			acard:setSkillName("heg_ov_zhenxi")
			local bcard = sgs.Sanguosha:cloneCard("supply_shortage", sgs.Card_NoSuitRed, 0)
			bcard:setSkillName("heg_ov_zhenxi")
			bcard:deleteLater()
			local suits = {}
			if not self.player:isProhibited(target, acard) and acard:targetFilter(sgs.PlayerList(), target, self.player) then
				table.insert(suits, "diamond")
			end
			if not self.player:isProhibited(target, bcard) and bcard:targetFilter(sgs.PlayerList(), target, self.player) then
				table.insert(suits, "club")
			end
			if #suits > 0 then
				for _, c in sgs.qlist(self.player:getCards("he")) do
					if table.contains(suits, c:getSuitString()) and not c:isKindOf("TrickCard") then
						return "use"
					end
				end
			end
		end
	end
	if table.contains(choices, "discard") and self:doDisCard(target, "he") then
		return "discard"
	end
	return "cancel"
end

sgs.ai_skill_cardask["@heg_ov_zhenxi"] = function(self, data, pattern, target, target2)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards) -- 按保留值排序
		local acard = sgs.Sanguosha:cloneCard("indulgence", sgs.Card_NoSuitRed, 0)
		acard:deleteLater()
		acard:setSkillName("heg_ov_zhenxi")
		local bcard = sgs.Sanguosha:cloneCard("supply_shortage", sgs.Card_NoSuitRed, 0)
		bcard:setSkillName("heg_ov_zhenxi")
		bcard:deleteLater()
		for _,c in sgs.list(cards)do
			if sgs.Sanguosha:matchExpPattern(pattern,self.player,c) then 
				if c:getSuit() == sgs.Card_Diamond then
					local dummy_use = self:aiUseCard(acard, dummy(true, 99, self.room:getOtherPlayers(target)))
					if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
						return c:getEffectiveId() 
					end
				end
				if c:getSuit() == sgs.Card_Club then
					local dummy_use = self:aiUseCard(bcard, dummy(true, 99, self.room:getOtherPlayers(target)))
					if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
						return c:getEffectiveId() 
					end
				end
				
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.heg_ov_jiansu = function(self, data)
	return math.random() < 0.6
end

sgs.ai_skill_use["@@heg_ov_jiansu"] = function(self, prompt, method)
	for _, friend in ipairs(self.friends) do
		if friend:getHp() <= 2 then
			local use_cards = {}
			for _, c in sgs.qlist(self.player:getCards("h")) do
				if c:hasTip("heg_ov_jiansu") and #use_cards < friend:getHp() then
					table.insert(use_cards, c:getEffectiveId())
				end
			end
			if #use_cards == friend:getHp() then
				return "#heg_ov_jiansu:"..table.concat(use_cards, "+")..":->"..friend:objectName()
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.heg_ov_zhuidu = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isEnemy(damage.to) then
		if self:doDisCard(damage.to, "e") then
			return true
		end
		if not self:cantDamageMore(self.player, damage.to) and self:canDamage(damage.to, self.player, damage.card) then
			return true
		end
	end
	return false
end

sgs.ai_skill_cardask["@heg_ov_zhuidu-beishui"] = function(self, data, pattern, target, target2)
	local damage = data:toDamage()
	if damage.to and self:isEnemy(damage.to) then
		if self:doDisCard(damage.to, "e") and not self:cantDamageMore(self.player, damage.to) and self:canDamage(damage.to, self.player, damage.card) then
			return true
		end
	end
	return "."
end

sgs.ai_skill_choice.heg_ov_zhuidu = function(self, choices, data)
	local damage = data:toDamage()
	choices = choices:split("+")
	if self:doDisCard(self.player, "e") and table.contains(choices, "discard") then
		return "discard"
	end
	return "damage"
end

sgs.ai_canNiepan_skill.heg_ov_shigong = function(player)
	return player:getGeneral2() and player:getMark("@heg_ov_shigong") > 0
end

sgs.ai_skill_invoke.heg_ov_shigong = sgs.ai_skill_invoke.niepan
sgs.ai_skill_invoke.heg_ov_shigong_gain = function(self, data)
	local target = data:toPlayer()
	for _,sk in sgs.list(self.player:getVisibleSkillList())do
		if sk:isAttachedLordSkill() then continue end
		if not string.find(sgs.bad_skills,choice) then
			return true
		end
	end
	return false
end

sgs.ai_skill_choice.heg_ov_shigong = function(self,choices)
	choices = choices:split("+")
	for _,choice in sgs.list(choices)do
		if self:isValueSkill(choice,self.player,true) then
			return choice
		end
	end
	for _,choice in sgs.list(choices)do
		if self:isValueSkill(choice,self.player) then
			return choice
		end
	end
	for _,choice in sgs.list(choices)do
		if string.find(sgs.bad_skills,choice) then continue end
		return choice
	end
	return choices[math.random(1,#choices)]
end
