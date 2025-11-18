

sgs.ai_skill_use["@@luaRshiji"]=function(self,prompt)
	self:updatePlayers()
	self:sort(self.enemies,"defense")
	
	if self:needBear() then return "." end

	local selfSub = self.player:getHp() - self.player:getHandcardNum()
	local selfDef = sgs.getDefense(self.player)

	for _,enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
        slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
        if not self.player:canSlash(enemy, slash, true) then
        elseif self:slashProhibit(nil, enemy) then
        elseif def < 6 and eff then return "#luaRshiji:.:->"..enemy:objectName()

        elseif selfSub >= 2 then return "."
        elseif selfDef < 6 then return "." end
	end

	for _,enemy in ipairs(self.enemies) do
		local def=sgs.getDefense(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
        slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
		if not self.player:canSlash(enemy, slash, true) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff and def < 8 then return "#luaRshiji:.:->"..enemy:objectName()
		else return "." end
	end
	return "."
end


sgs.ai_event_callback[sgs.Death].luaRquanxiang = function(self, player, data)
    for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
        if sb:hasSkill("luaRquanxiang") then
            local target = data:toDeath().who
            -- sgs.role_evaluation[sb:objectName()]["renegade"] = 0
            -- sgs.role_evaluation[sb:objectName()]["loyalist"] = 0
            sgs.roleValue[target:objectName()]["renegade"] = 0
            sgs.roleValue[target:objectName()]["loyalist"] = 0
            local role, value = sb:getRole(), 1000
            if role == "rebel" then role = "loyalist" value = -1000 end
            --sgs.role_evaluation[sb:objectName()][sb:getRole()] = 1000
            sgs.roleValue[target:objectName()][sb:getRole()] = 1000
            sgs.ai_role[target:objectName()] = target:getRole()
            self:updatePlayers()
        end
    end
end
sgs.ai_skill_invoke.luaRquanxiang = function(self, data)
	return true
end


sgs.ai_choicemade_filter.skillInvoke.luaRquanxiang = function(self, player, promptlist)
    if promptlist[#promptlist]=="yes" then
        local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
        local target = damage.to
        if target then 
            -- sgs.role_evaluation[sb:objectName()]["renegade"] = 0
            -- sgs.role_evaluation[sb:objectName()]["loyalist"] = 0
            sgs.roleValue[target:objectName()]["renegade"] = 0
            sgs.roleValue[target:objectName()]["loyalist"] = 0
            local role, value = player:getRole(), 1000
            if role == "rebel" then role = "loyalist" value = -1000 end
            --sgs.role_evaluation[sb:objectName()][sb:getRole()] = 1000
            sgs.roleValue[target:objectName()][player:getRole()] = 1000
            sgs.ai_role[target:objectName()] = target:getRole()
            self:updatePlayers()
        end
    end
end

sgs.ai_useto_revises.luaRduxian = function(self,card,use,p)
	if self.player:getMark("luaRduxian-PlayClear") >= p:getHp() and not self:needToLoseHp(self.player, p) and self.player:objectName() ~= p:objectName()
	then
        if not card:isKindOf("SkillCard") then
            return false
        end
	end
end

sgs.ai_damage_reason_suppress_intention["luaRduxian"] = true

sgs.ai_skill_playerchosen.luaRcaiyi = function(self,targets)
	self:sort(self.enemies,"handcard")
	self:sort(self.friends_noself,"defense")
	self.luaRcaiyi_target = nil
	if (self.player:getHandcardNum()<3 and self:getCardsNum("Peach")==0 and self:getCardsNum("Jink")==0 and self:getCardsNum("Analeptic")==0) or
		(self.player:getHandcardNum()<=1 and self:getCardsNum("Peach")==0 and self:getCardsNum("Analeptic")==0) then
		local max_card_num = 0
		for _,enemy in ipairs(self.enemies)do
			max_card_num = math.max(max_card_num,enemy:getHandcardNum())
		end
		for _,enemy in ipairs(self.enemies)do
			if enemy:getHandcardNum()==max_card_num and enemy:getHandcardNum()>0 then
				self.luaRcaiyi_target = enemy
				return enemy
			end
		end
	else
		for _,friend in ipairs(self.friends_noself)do
			if not hasManjuanEffect(friend) and not self:needKongcheng(friend,true) then
				self.luaRcaiyi_target = friend
				return friend
			end
		end
	end
	return nil
end

sgs.ai_skill_discard.luaRcaiyi = function(self,discard_num,min_num,optional,include_equip)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByCardNeed(cards,true)
	local to_discard = {}
	local half_all_card_num = math.max(1,math.floor(self.player:getHandcardNum()/2))
	for i = 1,half_all_card_num,1 do
		table.insert(to_discard,cards[i]:getEffectiveId())
	end
	return to_discard
end

sgs.ai_skill_choice.luaRcaiyi = function(self,choices,data)
	local items = choices:split("+")
	if not self.luaRcaiyi_target then
		local items = choices:split("+")
		return items[math.random(1,#items)]
	end
	local ids = data:toIntList()
	local show_need,notshow_need = 0,0
	for _,id in sgs.qlist(ids)do
		show_need = show_need+self:cardNeed(sgs.Sanguosha:getCard(id))
	end
	local flag = string.format("%s_%s_%s","visible",self.player:objectName(),self.luaRcaiyi_target:objectName())
	for _,c in sgs.qlist(self.luaRcaiyi_target:getHandcards())do
		if ids:contains(c:getEffectiveId()) then continue end
		if c:hasFlag("visible") or c:hasFlag(flag) then
			notshow_need = notshow_need+self:cardNeed(c)
		else
			notshow_need = notshow_need+0.5
		end
	end
	if show_need>notshow_need then return "luaRcaiyi1" end
	if show_need<=notshow_need then return "luaRcaiyi2" end
	return items[math.random(1,#items)]
end
function sgs.ai_skill_invoke.luaRhuogen(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return not self:isWeak()
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.luaRhuogen = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-80) end
	end
end

luaRsihu_skill = {}
luaRsihu_skill.name = "luaRsihu"
table.insert(sgs.ai_skills,luaRsihu_skill)
luaRsihu_skill.getTurnUseCard = function(self)
	local card
	if self:needToThrowArmor() then
		card = self.player:getArmor()
	end
	if not card then
		local hcards = self.player:getCards("h")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards,true)

		for _,hcard in ipairs(hcards)do
			if hcard:isKindOf("Slash") then
				if self:getCardsNum("Slash")>1
				then
					card = hcard
					break
				else
					local dummy_use = self:aiUseCard(hcard, dummy())
					if dummy_use and dummy_use.to and (dummy_use.to:length()==0
					or dummy_use.to:length()==1 and self:ajustDamage(self.player,dummy_use.to:first(),1,hcard)<2)
					then
						card = hcard
						break
					end
				end
			elseif hcard:isKindOf("EquipCard")
			then
				card = hcard
				break
			end
		end
	end
	if not card then
		local ecards = self.player:getCards("e")
		ecards = sgs.QList2Table(ecards)

		for _,ecard in ipairs(ecards)do
			if ecard:isKindOf("Weapon") or ecard:isKindOf("OffensiveHorse") then
				card = ecard
				break
			end
		end
	end
	if card then
		return sgs.Card_Parse("#luaRsihuCard:"..card:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#luaRsihuCard"] = function(card,use,self)
	local target
	local friends = self.friends_noself
	local slash = dummyCard()
	self.luaRsihuTarget = nil

	local canluaRsihuTo = function(player)
		local canGive = not self:needKongcheng(player,true)
		return canGive or (not canGive and self:getEnemyNumBySeat(self.player,player)==0)
	end

	self:sort(self.enemies,"defense")
	for _,friend in ipairs(friends)do
		if canluaRsihuTo(friend) then
			for _,enemy in ipairs(self.enemies)do
				if friend:canSlash(enemy, nil, false) and not self:slashProhibit(slash,enemy) and self:getDefenseSlash(enemy)<=2
				and self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash)
				and enemy:objectName()~=self.player:objectName() then
					target = friend
					self.luaRsihuTarget = enemy
					break
				end
			end
		end
		if target then break end
	end

	if not target then
		self:sort(friends,"defense")
		for _,friend in ipairs(friends)do
			if canluaRsihuTo(friend) then
				target = friend
				break
			end
		end
	end

	if target then
		use.card = card
		use.to:append(target)
	end
end

sgs.ai_skill_playerchosen.luaRsihu = function(self,targets)
	if self.luaRsihuTarget then return self.luaRsihuTarget end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self,targets)
end

-- sgs.ai_playerchosen_intention.luaRsihu = 80

sgs.ai_use_value["luaRsihuCard"] = 5.9
sgs.ai_use_priority["luaRsihuCard"] = 4

sgs.ai_card_intention["luaRsihuCard"] = -70

sgs.ai_cardneed.luaRsihu = sgs.ai_cardneed.equip

sgs.ai_skill_cardask["@luaRsihu"] = function(self, data, pattern)
    local target = data:toPlayer()
    local slash = dummyCard()
    local handcards = sgs.QList2Table(self.player:getCards("he"))
	local use_card = {}
	self:sortByKeepValue(handcards)
    if self:needToLoseHp(self.player, target, slash, true) then return "."  end
	for _,c in ipairs(handcards) do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,c)
		then
			table.insert(use_card, c)
		end
	end
	if #use_card == 0 then return "." end
   
    if self:getCardsNum("Jink") == 0 then return use_card[1]:toString() end
    if self:ajustDamage(target,self.player,1,slash)>1 then return use_card[1]:toString() end
    if self.player:getHandcardNum()==1 and self:needKongcheng()
    or not(self:hasLoseHandcardEffective() or self.player:isKongcheng()) then return use_card[1]:toString() end
    return "."
end

sgs.ai_skill_cardask["@luaRjianxiong"] = function(self,data,pattern,target)
    local target = data:toPlayer()
	local card_list = self.player:getHandcards()
	local cards = sgs.QList2Table(card_list)
	self:sortByKeepValue(cards,false)
    for _,c in ipairs(cards) do
        if c:hasFlag("luaRjianxiong") then
            if not c:targetFixed() and not c:isKindOf("EquipCard")  then
                local dummy_use = self:aiUseCard(c, dummy(true, 0, self.room:getOtherPlayers(target)))
                if dummy_use.card and dummy_use.to and dummy_use.to:contains(target) then
                    return "$"..c:getEffectiveId()
                end
            else
                if target:objectName() == self.player:objectName() then
                    local dummy_use = self:aiUseCard(c, dummy())
                    if dummy_use.card then
                        return "$"..c:getEffectiveId()
                    end
                end
            end
        end
    end
	return "."
end

sgs.ai_cardneed.luaRyaowu = sgs.ai_cardneed.slash

sgs.ai_can_damagehp.luaRzhiyu = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and from and from:getHandcardNum() - self.player:getHandcardNum() >= 2
end

sgs.ai_skill_invoke.luaRqice = function(self, data)
    local use = data:toCardUse()
    if self.player:getPhase() == sgs.Player_Play and not self.player:isKongcheng() then 
        local cards = sgs.QList2Table(self.player:getCards("h"))
	    for _,c in sgs.list(cards)do
            if self:willUse(self.player,c) then
                return false
            end
        end
    end
    if use.from and self:isFriend(use.from) then
        if self.player:isKongcheng() and self:isWeak() then return false end
        if use.card:isDamageCard() or use.card:isKindOf("SingleTargetTrick") then
            for _,to in sgs.list(use.to)do
                if self:isFriend(to)
                then return false end
            end
            if not self.player:isKongcheng() then
                local cards = sgs.QList2Table(self.player:getCards("h"))
                for _,c in sgs.list(cards)do
                    if self:getUseValue(c) > self:getUseValue(use.card) then
                        return false
                    end
                end
            end
            return true
        end
        local dummy_use = self:aiUseCard(use.card, dummy())
        if dummy_use.card and dummy_use.to then
            for _, p in sgs.qlist(dummy_use.to) do
                if use.to:contains(p) then
                    return true
                end
            end
        end
    end
	return false
end

local luaRziao_skill = {}
luaRziao_skill.name = "luaRziao"
table.insert(sgs.ai_skills, luaRziao_skill)
luaRziao_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	if #self.enemies < 1 or self.player:isKongcheng() then return end
	if not self.player:isKongcheng() then
		return sgs.Card_Parse("#luaRziao:.:")
	end
end

sgs.ai_skill_use_func["#luaRziao"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local cards = sgs.CardList()
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player, cards)
	if not max_card then return end
	local max_point = max_card:getNumber()
	local card_str = "#luaRziao:.:"
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy) == enemy:getHandcardNum() then
				allknown = allknown + 1
			end
			if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
				or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10)
				or (not enemy_max_card and max_point > 10) then
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				self.zhijian_card = max_card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	if self.player:getHandcardNum() >= 2 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and self.player:canPindian(enemy) then
				local cardsq = self.player:getHandcards()
				cardsq = sgs.QList2Table(cardsq)
				self:sortByUseValue(cardsq, true)

				local min_card = self:getMinCard()
				local enemy_min_card = self:getMinCard(enemy)
				if enemy_min_card and min_card:getNumber() < enemy_min_card:getNumber() then
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					self.zhijian_card = max_card
					if use.to then use.to:append(enemy) end
					return
				end
			end
		end
	end

	if self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and not self:doDisCard(enemy, "h") and self.player:canPindian(enemy) then
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum() == 1 and self.player:canPindian(zhugeliang)
		and zhugeliang:objectName() ~= self.player:objectName() and self:getEnemyNumBySeat(self.player, zhugeliang) >= 1 then
		if isCard("Jink", cards[1], self.player) and self:getCardsNum("Jink") == 1 then return end
		local acard = sgs.Card_Parse(card_str)
		use.card = acard
		if use.to then use.to:append(zhugeliang) end
		return
	end

	if self:getOverflow() > 0 then
		for _, enemy in ipairs(self.enemies) do
			if not self:doDisCard(enemy, "h", true) and not enemy:isKongcheng() and self.player:canPindian(enemy) then
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				self.luaRziao_card = max_card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.luaRziao(minusecard, self, requestor)
	if requestor:getHandcardNum() == 1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return cards[1]
	end
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or (maxcard:getNumber() < 6 and minusecard or maxcard)
end
sgs.ai_use_priority["luaRziao"]   = 5
sgs.ai_card_intention["luaRziao"] = 10
sgs.ai_cardneed.luaRziao = sgs.ai_cardneed.bignumber
sgs.ai_cardneed.luaRshicai = sgs.ai_cardneed.bignumber


sgs.ai_skill_playerchosen.luaRyaoyan = function(self,targets)
	targets = sgs.QList2Table(targets)
	for _,target in ipairs(targets)do
		if self:isFriend(target) and target:isAlive() then
			if target:isWounded() then
				return target
			end
			local zhangjiao = self.room:findPlayerBySkillName("guidao")
			if zhangjiao and self:isFriend(zhangjiao) then
				return target
			end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.luaRyaoyan = -40

luaRzhangshi_skill = {}
luaRzhangshi_skill.name = "luaRzhangshi"
table.insert(sgs.ai_skills, luaRzhangshi_skill)
luaRzhangshi_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies < 1 or self.player:hasUsed("#luaRzhangshicard") then return end
    if self.room:getLieges("qun", self.player):length() < 1 then return end
	return sgs.Card_Parse("#luaRzhangshicard:.:")
end


sgs.ai_skill_use_func["#luaRzhangshicard"] = function(card, use, self)
	local target
	self:sort(self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if enemy then
            target = enemy
        end
    end
	if target then
		use.card = sgs.Card_Parse("#luaRzhangshicard:.:")
		if use.to then use.to:append(target) end
		return
	end
end
sgs.ai_use_value["luaRzhangshicard"]       = 8
sgs.ai_use_priority["luaRzhangshicard"]    = 8
sgs.ai_card_intention["luaRzhangshicard"]  = 50
sgs.ai_skill_choice["luaRzhangshi"] = function(self, choices, data)
	local items = choices:split("+")
    if self.room:getLieges("qun", self.player):length() < 1 then return "slash" end
	return items[math.random(1,#items)]
end

