sgs.ai_ajustdamage_to.ckleiti = function(self,from,to,card,nature)
	if nature == sgs.DamageStruct_Thunder
	then return -99 end
end

sgs.ai_can_damagehp.ckleiti = function(self,from,card,to)
    if card then
        local nature = sgs.card_damage_nature[card:getClassName()] or sgs.DamageStruct_Normal
        if nature == sgs.DamageStruct_Thunder
        then
            return true
        end
    end
end

local ckdianji_skill = {}
ckdianji_skill.name= "ckdianji"
table.insert(sgs.ai_skills,ckdianji_skill)
ckdianji_skill.getTurnUseCard=function(self)
    if not self.player:canDiscard(self.player, "he") then return end
	return sgs.Card_Parse("#ckdianjicard:.:")
end

sgs.ai_skill_use_func["#ckdianjicard"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
    self:sort(self.enemies)
    for _,enemy in sgs.list(self.enemies)do
        if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player) and self:canDamage(enemy,self.player,nil) then
            use.card = sgs.Card_Parse("#ckdianjicard:"..cards[1]:getEffectiveId()..":")
            use.to:append(enemy)
            return
        end
    end
    if self.player:getHp()<getBestHp(self.player) and self.player:hasSkill("ckleiti") then
        use.card = sgs.Card_Parse("#ckdianjicard:"..cards[1]:getEffectiveId()..":")
        use.to:append(self.player)
        return
    end
    local target = self:findPlayerToDamage(1,self.player, sgs.DamageStruct_Thunder,nil,true)[1]
    if target then
        use.card = sgs.Card_Parse("#ckdianjicard:"..cards[1]:getEffectiveId()..":")
        use.to:append(target)
        return
    end
end

sgs.ai_use_value["ckdianjicard"] = 2.5
sgs.ai_card_intention["ckdianjicard"] = 80
sgs.dynamic_value.damage_card["ckdianjicard"] = true


ckluolei_skill = {}
ckluolei_skill.name = "ckluolei"
table.insert(sgs.ai_skills, ckluolei_skill)
ckluolei_skill.getTurnUseCard = function(self)
	if self.player:getMark("@thunder") <= 0 then return end
	if self.room:getMode() == "_mini_13" then return sgs.Card_Parse("#ckluolei:.:") end
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) then
			if self:isFriend(player) then bad = bad + 1
			else good = good + 1
			end
		end
	end
	if good == 0 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(player:getHp(), 1)
		if getCardsNum("Analeptic", player) > 0 then
			if self:isFriend(player) then good = good + 1.0 / hp
			else bad = bad + 1.0 / hp
			end
		end

		if self:damageIsEffective(player, sgs.DamageStruct_Thunder, self.player) then
			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill, player) then lost_value = player:getHp()/2 end
			local hp = math.max(player:getHp(), 1)
			if self:isFriend(player) then bad = bad + (lost_value + 1) / hp
			else good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad and self:isWeak() and self:getHandcardNum() < 4 then return sgs.Card_Parse("#ckluoleicard:.:") end
end

sgs.ai_skill_use_func["#ckluoleicard"]=function(card,use,self)
	use.card = card
end

sgs.dynamic_value.damage_card["#ckluoleicard"] = true

local cksilie_skill = {}
cksilie_skill.name = "cksilie"
table.insert(sgs.ai_skills,cksilie_skill)
cksilie_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return nil end
	return sgs.Card_Parse("#cksiliecard:.:")
end

sgs.ai_skill_use_func["#cksiliecard"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	self:sort(self.enemies,"defense")
	if self:getOverflow()<=0 then return end
	sgs.ai_use_priority["cksiliecard"] = 0.2
	local suit_table = { "spade","club","heart","diamond" }
	local equip_val_table = { 1.2,1.5,0.5,1,1.3 }
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHandcardNum()>2 and self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and self:canDamage(enemy,self.player,nil) then
			local max_suit_num,max_suit = 0,{}
			for i = 0,3,1 do
				local suit_num = getKnownCard(enemy,self.player,suit_table[i+1])
				for j = 0,4,1 do
					if enemy:getEquip(j) and enemy:getEquip(j):getSuit()==i then
						local val = equip_val_table[j+1]
						if j==1 and self:needToThrowArmor(enemy) then val = -0.5
						else
							if enemy:hasSkills(sgs.lose_equip_skill) then val = val/8 end
							if enemy:getEquip(j):getEffectiveId()==self:getValuableCard(enemy) then val = val*1.1 end
							if enemy:getEquip(j):getEffectiveId()==self:getDangerousCard(enemy) then val = val*1.1 end
						end
						suit_num = suit_num+j
					end
				end
				if suit_num>max_suit_num then
					max_suit_num = suit_num
					max_suit = { i }
				elseif suit_num==max_suit_num then
					table.insert(max_suit,i)
				end
			end
			if max_suit_num==0 then
				max_suit = {}
				local suit_value = { 1,1,1.3,1.5 }
				for _,skill in ipairs(sgs.getPlayerSkillList(enemy))do
					if sgs[skill:objectName().."_suit_value"] then
						for i = 1,4,1 do
							local v = sgs[skill:objectName().."_suit_value"][suit_table[i]]
							if v then suit_value[i] = suit_value[i]+v end
						end
					end
				end
				local max_suit_val = 0
				for i = 0,3,1 do
					local suit_val = suit_value[i+1]
					if suit_val>max_suit_val then
						max_suit_val = suit_val
						max_suit = { i }
					elseif suit_val==max_suit_val then
						table.insert(max_suit,i)
					end
				end
			end
			for _,card in ipairs(cards)do
				if self:getUseValue(card)<6 and table.contains(max_suit,card:getSuit()) then
					use.card = sgs.Card_Parse("#cksiliecard:"..card:getEffectiveId()..":")
					use.to:append(enemy)
					return
				end
			end
			if getCardsNum("Peach",enemy,self.player)<2 then
				for _,card in ipairs(cards)do
					if self:getUseValue(card)<6 and not self:isValuableCard(card) then
						use.card = sgs.Card_Parse("#cksiliecard:"..card:getEffectiveId()..":")
						use.to:append(enemy)
						return
					end
				end
			end
		end
	end
end

sgs.ai_card_intention["cksiliecard"] = 60

sgs.ai_use_priority["cksiliecard"] = 0.2

sgs.ai_skill_use["@@ckbaihe"] = function(self,prompt)
    self:sort(self.friends,"defense")
    for _,friend in ipairs(self.friends)do
        if self:doDisCard(friend, "e") then
            return "#ckbaihecard:.:->"..friend:objectName()
        end
    end
    for _,friend in ipairs(self.friends)do
        if friend:hasEquip() and self.player:canDiscard(friend, "e") and self:isWeak(friend) then
            return "#ckbaihecard:.:->"..friend:objectName()
        end
    end
	return "."
end

sgs.ai_ajustdamage_from.ckdalian = function(self,from,to,card,nature)
	if from and from:distanceTo(to)<=1 and not beFriend(to,from)
	then return 1 end
end

sgs.ai_skill_invoke.ckdalian = function(self, data)
    local target = data:toPlayer()
    if target and self:isFriend(target) then return false end
	return true
end

sgs.ai_target_revises.ckhuansha = function(to,card)
	if card:getTypeId()==sgs.Card_TypeSkill or card:getSkillName()~="" or card:isVirtualCard() or card:isKindOf("SkillCard")
	then return true end
end
sgs.ai_target_revises.ckshiliang = function(to,card)
	if to:getMark("ckshiliang-Clear") == 0
	then return true end
end

sgs.ai_skill_use["@@ckshiliang"] = function(self,prompt)
    local parsed = prompt:split(":")
    local use = self.room:getTag("ckshiliang"):toCardUse()
    if parsed[1]=="@ckshiliangCard" then
        if use then
            local card = use.card
            local dummy_use = self:aiUseCard(card, dummy(true, 0, use.to))
			if dummy_use.card and dummy_use.to then
                for _,p in sgs.qlist(dummy_use.to)do
                    return "#ckshiliangcard:.:->"..p:objectName()
                end
            end
        end
    else
        if use.from and self:isEnemy(use.from) then
            for _, enemy in ipairs(self.enemies) do
                return "#ckshiliangcard:.:->"..enemy:objectName()
            end
        end
	end
	return "."
end

sgs.ai_skill_invoke.ckxueni = function(self, data)
    local target = data:toPlayer()
    if target  then 
        if self:isEnemy(target) then
			return true
		end
        if self:isFriend(target) and target:getRole() == "rebel" then
			for _, friend in ipairs(self.friends) do
				if getKnownCard(friend, self.player, "Peach", true, "h") > 0 then return false end
				if friend:getHandcardNum() > 3 then return false end
			end
            return true
		end
    end
    return false
end

sgs.ai_skill_invoke.ckyongchang = function(self, data)
	local effect = self.room:getTag("ckyongchang"):toCardEffect()
    local dest = effect.to
    if dest and self:isEnemy(dest) then return false end
	if effect.card and effect.card:hasFlag("NosJiefanUsed") then return false  end

	if not effect.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,effect.from)
		or effect.card:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(dest,effect.card,effect.from)
		or self:needToLoseHp(dest,effect.from,effect.card) and self:ajustDamage(effect.from,dest,1,effect.card)==1 then return false end
	if self:needToLoseHp(dest, effect.from,effect.card, true, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end
	
	return true
end

sgs.ai_choicemade_filter.skillInvoke.ckyongchang = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end

local cklongxi_skill = {}
cklongxi_skill.name= "cklongxi"
table.insert(sgs.ai_skills,cklongxi_skill)
cklongxi_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#cklongxicard:.:")
end

sgs.ai_skill_use_func["#cklongxicard"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
    self:sort(self.enemies)
    for _,enemy in sgs.list(self.enemies)do
        if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and not self:cantDamageMore(self.player, enemy) and (enemy:getHp() <= 3 or self:isWeak()) and self:canDamage(enemy,self.player,nil) then
            use.card = sgs.Card_Parse("#cklongxicard:.:")
            use.to:append(enemy)
            return
        end
    end
    local target = self:findPlayerToDamage(3,self.player, sgs.DamageStruct_Normal,nil,true)[1]
    if target then
        use.card = sgs.Card_Parse("#cklongxicard:.:")
        use.to:append(target)
        return
    end
end

sgs.ai_use_value["cklongxicard"] = 2.5
sgs.ai_card_intention["cklongxicard"] = 80
sgs.dynamic_value.damage_card["cklongxicard"] = true

sgs.ai_cardneed.ckqishan = sgs.ai_cardneed.slash

sgs.ai_canliegong_skill.ckqishan = function(self, from, to)
	return true
end

local ckweishan_skill = {}
ckweishan_skill.name= "ckweishan"
table.insert(sgs.ai_skills,ckweishan_skill)
ckweishan_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#ckweishancard:.:")
end

sgs.ai_skill_use_func["#ckweishancard"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
    self:sort(self.enemies)
    local use_cards = {}
    local types = {}
    
	for _,c in ipairs(cards) do
		if not table.contains(types, c:getTypeId())  then
            table.insert(types, c:getTypeId())
            table.insert(use_cards, c:getEffectiveId())
		end
	end
    if #use_cards < 3 then return end
    for _,enemy in sgs.list(self.enemies)do
        if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) and not self:cantDamageMore(self.player, enemy) and (enemy:isWounded() or self:isWeak()) then
            use.card = sgs.Card_Parse("#ckweishancard:".. table.concat(use_cards, "+")..":")
            use.to:append(enemy)
            return
        end
    end
    local target = self:findPlayerToDamage(3,self.player, sgs.DamageStruct_Normal,nil,true)[1]
    if target then
        use.card = sgs.Card_Parse("#ckweishancard:".. table.concat(use_cards, "+")..":")
        use.to:append(target)
        return
    end
end

sgs.ai_use_value["ckweishancard"] = 2.5
sgs.ai_card_intention["ckweishancard"] = 80
sgs.dynamic_value.damage_card["ckweishancard"] = true

sgs.ai_skill_use["@@ckjinjie"] = function(self,prompt)
    local targets = {}
    table.insert(targets, self.player:objectName())
    self:sort(self.friends_noself, "handcard")
    for _, friend in ipairs(self.friends_noself) do
        if #targets < 3 then
            table.insert(targets, friend:objectName())
            break
        end
    end
    self:sort(self.enemies, "defense")
    for _, enemy in ipairs(self.enemies) do
        if #targets < 3 and not self.player:inMyAttackRange(enemy) then
            table.insert(targets, enemy:objectName())
        end
    end
    for _, enemy in ipairs(self.enemies) do
        if #targets < 3 then
            table.insert(targets, enemy:objectName())
        end
    end
    if #targets > 0 then
        return "#ckjinjieCard:.:->".. table.concat(targets, "+")
    end
    return "."
end