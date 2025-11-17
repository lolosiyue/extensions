sgs.ai_card_priority.sfofl_zhonghun = function(self, card, v)
    if card:isRed() then
        return 0.5
    end
end

addAiSkills("sfofl_longyi").getTurnUseCard = function(self)
    for c, pn in sgs.list(RandomList(patterns())) do
        c = dummyCard(pn)
        if c and c:isKindOf("BasicCard") and self:getCardsNum(c) == 0 then
            if c:isKindOf("Analeptic") and self:getCardsNum("TrickCard") == 0 then return end
            c:setSkillName("sfofl_longyi")
            c:addSubcards(self.player:getHandcards())
            if c:isAvailable(self.player)
                and self:aiUseCard(c).card
            then
                return c
            end
        end
    end
end

sgs.ai_guhuo_card.sfofl_longyi = function(self, toname, class_name)
    if class_name and self:getCardsNum(class_name) > 0 then return end
    local c = dummyCard(toname)
    c:setSkillName("sfofl_longyi")
    c:addSubcards(self.player:getHandcards())
    if (not c) or (not c:isKindOf("BasicCard")) then return end
    local cards = sgs.QList2Table(self.player:getHandcards())
    local to_use = {}
    for _, card in ipairs(cards) do
        table.insert(to_use, card:getId())
    end
    if #to_use > 0 then
        return "#sfofl_longyi:"..table.concat(to_use, "+") ..":"..toname
    end
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|sfofl_longyi"

sgs.ai_ajustdamage_from.sfofl_shiyin = function(self, from, to, card, nature)
    if from:hasFlag("sfofl_shiyin_damage")
    then
        return 1
    end
end

sgs.ai_ajustdamage_from["&sfofl_liushang-Clear"] = function(self, from, to, card, nature)
    if to:hasSkill("sfofl_liushang")
    then
        return -99
    end
end

sgs.ai_skill_cardask["@sfofl_liushang"] = function(self, data, pattern, target, target2)	
	local target = data:toPlayer()
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(usable_cards)
	
	if target then 
		if self:isFriend(target) then
			usable_cards = sgs.reverse(usable_cards)
			return usable_cards[1]:toString()
		else
			return usable_cards[1]:toString()
		end
	end
	return "."
end

sgs.ai_skill_invoke.sfofl_qibu = function(self,data)
	local dying = data:toDying()
	local peaches = 1-dying.who:getHp()

	return self:getCardsNum("Peach")+self:getCardsNum("Analeptic")<peaches
end

sgs.ai_skill_invoke.sfofl_liushang = function(self, data)
	for _, p in sgs.qlist(self.room:findPlayersBySkillName("sfofl_liushang")) do
        if not self:isEnemy(p) then
            return true
        end
    end
	return false
end


sgs.ai_skill_discard.sfofl_qizuo           = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	local damage = self.room:getTag("sfofl_qizuo"):toDamage()
    local list = self.room:getAlivePlayers()
	local target
	for _, p in sgs.qlist(list) do
		if p:hasFlag("sfofl_qizuo_target") then
			target = p
		end
	end
	if not target then return {} end
        if damage.to and self:isFriend(damage.to) then
            if self:needToLoseHp(damage.to,damage.from,damage.card) then
                return {}
            end
        else
            if self:cantDamageMore(damage.from, damage.to) then
                return {}
            end
        end
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, card:getEffectiveId())
        break
	end
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end
sgs.ai_skill_choice.sfofl_qizuo = function(self, choices, data)
	local damage = data:toDamage()
	if self:isFriend(damage.to) and not self:needToLoseHp(damage.to,damage.from,damage.card) then return "minus" end
	return "add"
end
sgs.ai_skill_cardask["@sfofl_quanmou"] = function(self, data, pattern, target)
	local use = data:toCardUse()
    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
    for _, card in ipairs(cards) do
        if self:getKeepValue(card) < self:getKeepValue(use.card) and use.card:sameColorWith(card) then
            return "$" .. card:getEffectiveId()
        end
    end
	return "."
end

sgs.ai_skill_invoke.sfofl_qijin = true


function sgs.ai_cardsview_valuable.sfofl_qichu(self,class_name,player)
	if class_name=="Slash"
	then return "#sfofl_qichuCard:.:slash"
	elseif class_name=="Peach" or class_name=="Analeptic"
	then
		local dying = self.room:getCurrentDyingPlayer()
		if dying and dying:objectName()==player:objectName()
		then
			local user_string = "peach+analeptic"
			if player:getMark("Global_PreventPeach")>0 then user_string = "analeptic" end
			return "#sfofl_qichuCard:.:"..user_string
		else
			local user_string
			if class_name=="Analeptic" then user_string = "analeptic" else user_string = "peach" end
			return "#sfofl_qichuCard:.:"..user_string
		end
	end
end

sgs.ai_skill_invoke.sfofl_qichu = function(self,data)
	local asked = data:toStringList()
	local pattern = asked[1]
	local prompt = asked[2]
	return self:askForCard(pattern,prompt,1)~="."
end

sgs.ai_skill_askforag.sfofl_qichu = function(self,card_ids)
	local card = sgs.Sanguosha:getCard(card_ids[1])
	if card:isKindOf("Jink") and self.player:hasFlag("dahe") then
		for _,id in ipairs(card_ids)do
			if sgs.Sanguosha:getCard(id):getSuit()==sgs.Card_Heart then return id end
		end
		return -1
	end
	return card_ids[1]
end


sgs.ai_skill_use["@@sfofl_longxin"] = function(self,prompt)
	local disaster,indulgence,supply_shortage = -1,-1,-1
	for _,card in sgs.list(self.player:getJudgingArea())do
		if card:isKindOf("Disaster") then disaster = card:getId() end
		if card:isKindOf("Indulgence") then indulgence = card:getId() end
		if card:isKindOf("SupplyShortage") then supply_shortage = card:getId() end
	end
	local use_card
	for _,c in sgs.list(self.player:getCards("he"))do
		if self.player:canDiscard(self.player,c:getEffectiveId()) and c:isKindOf("EquipCard") then
			use_card = c
            break
		end
	end
    if not use_card then return "." end
	
	local discard = {}
    table.insert(discard,use_card:getId())
	if disaster>-1 and self:hasSkills(sgs.wizard_skill,self.enemies) then
		table.insert(discard,disaster)
		return "#sfofl_longxinCard:"..table.concat(discard,"+") ..":"
	end
	
	if indulgence>-1 and self.player:hasSkill("keji") and supply_shortage>-1 then
		table.insert(discard,supply_shortage)
		return "#sfofl_longxinCard:"..table.concat(discard,"+") ..":"
	end
	
	if indulgence>-1 and self:getCardsNum("Peach")>1 and self:isWeak() then
		table.insert(discard,indulgence)
		return "#sfofl_longxinCard:"..table.concat(discard,"+") ..":"
	end
    if not self:isWeak()  then
		table.insert(discard,self.player:getJudgingAreaID():first())
		return "#sfofl_longxinCard:"..table.concat(discard,"+") ..":"
	end
		
	return "."
end



sfofl_sheji_skill = { name = "sfofl_sheji" }
table.insert(sgs.ai_skills, sfofl_sheji_skill)
sfofl_sheji_skill.getTurnUseCard = function(self)
	self:updatePlayers()
	local has_weak_enemy = false
	for _, enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) then
			has_weak_enemy = true
		end
	end
	if (self.player:isKongcheng()) then return end
	if not has_weak_enemy then
		if self:getCardsNum("Peach") > 0 or self:getCardsNum("Duel") > 0
			or (self:getCardsNum("Analeptic") > 0 and self:isWeak())
			or (self:getCardsNum("Jink") > 0 and self:isWeak())
			or self:getCardsNum("SupplyShortage") > 0 or self:getCardsNum("Indulgence") > 0
			or self:getCardsNum("ArcheryAttack") > 0 or self:getCardsNum("SavageAssault") > 0
		then
			return
		end
	end

	if self.player:getHandcardNum() > 1 then
		for _, c in sgs.qlist(self.player:getHandcards()) do
			if not c:isKindOf("Analeptic") then
				if self:willUse(self.player, c) or c:isAvailable(self.player) then return end
			end
		end
	end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	slash:addSubcards(self.player:getHandcards())
	slash:setSkillName("sfofl_sheji")
	return slash
end

sgs.ai_card_priority.sfofl_sheji = function(self, card)
	if card:isKindOf("Slash") and self.player:getHandcardNum() < 4 and card:getSkillName() == "sfofl_sheji"
	then
		return 1
	end
end

sgs.ai_skill_invoke.sfofl_sheji = function(self,data)
	local target = data:toDamage().to
	if not self:doDisCard(target, "e", true) then
		return false
	end
	return true
end
sgs.need_kongcheng = sgs.need_kongcheng .. "|sfofl_hengzheng"


sgs.ai_skill_playerschosen.sijyuoffline_huyi = function(self, targets, max, min)
	local enemy = sgs.SPlayerList()
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) and not p:isChained() then
			enemy:append(p)
			if enemy:length() > min then break end
		end
	end
	return enemy
end


sgs.ai_skill_invoke.sfofl_yice = true
sgs.ai_skill_askforag.sfofl_yice = function(self,card_ids)
	return card_ids[1]
end
sgs.ai_skill_playerchosen.sfofl_yice_damage = function(self, targets)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
			return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		return enemy
	end
	return targets:first()
end


sgs.ai_skill_invoke.sfofl_young_ganglie = function(self,data)
	local mode = self.room:getMode()
	if mode:find("_mini_41") or mode:find("_mini_46") then return true end
	local damage = data:toDamage()
	return not self:isFriend(damage.from) and self:doDisCard(damage.from, "h")
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_young_ganglie = function(self,player,promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist]=="yes" then
			if not self:doDisCard(damage.from, "h") then
				sgs.updateIntention(damage.to,damage.from,40)
			end
		end
	end
end
local sfofl_young_zhiheng_skill = {}
sfofl_young_zhiheng_skill.name = "sfofl_young_zhiheng"
table.insert(sgs.ai_skills, sfofl_young_zhiheng_skill)
sfofl_young_zhiheng_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local card
	self:sortByUseValue(cards, true)
	for _, acard in ipairs(cards) do
		if self:getUseValue(acard) < 6 then
			card = acard
			break
		end
	end
	if not card then return nil end

	local card_id = card:getEffectiveId()
	local card_str = "#sfofl_young_zhiheng:" .. card_id .. ":"
	local skillcard = sgs.Card_Parse(card_str)

	return skillcard
end
sgs.ai_skill_use_func["#sfofl_young_zhiheng"]=function(card,use,self)
	use.card = card
	return
end
sgs.ai_use_priority["sfofl_young_zhiheng"] = 2.61

sgs.hit_skill = sgs.hit_skill .. "|sfofl_young_wushuang"
sgs.ai_cardneed.sfofl_young_wushuang = sgs.ai_cardneed.slash

sgs.ai_skill_invoke.sfofl_young_eight_diagram =sgs.ai_skill_invoke.eight_diagram

local sfofl_quanyi_skill = {}
sfofl_quanyi_skill.name = "sfofl_quanyi"
table.insert(sgs.ai_skills, sfofl_quanyi_skill)
sfofl_quanyi_skill.getTurnUseCard = function(self, inclusive)
	if self:needBear() then return end
	local card_str = "#sfofl_quanyi:.:"
	local skillcard = sgs.Card_Parse(card_str)

	return skillcard
end
sgs.ai_skill_use_func["#sfofl_quanyi"]=function(card,use,self)
	self:sort(self.enemies,"handcard")
	local cards = sgs.CardList()
	local peach = 0
	for _,c in sgs.qlist(self.player:getHandcards())do
		if isCard("Peach",c,self.player) and peach<2 then
			peach = peach+1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player,cards)
	if max_card and max_card:isRed() and max_card:getNumber() >= 10  then
		for _,enemy in sgs.list(self.enemies)do
			if self.player:canPindian(enemy) and self:doDisCard(enemy,"he") then
				sgs.ai_use_priority["sfofl_quanyi"] = 1.2
				self.sfofl_quanyi_card = max_card:getId()
				self.room:addPlayerMark(self.player, "ai_sfofl_quanyi-PlayClear")
				use.card = sgs.Card_Parse("#sfofl_quanyi:.:")
				use.to:append(enemy)
				return
			end
		end
	end
	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")

	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum()==1
		and zhugeliang:objectName()~=self.player:objectName() and self:getEnemyNumBySeat(self.player,zhugeliang)>=1 and self.player:canPindian(zhugeliang) then
		if isCard("Jink",cards[1],self.player) and self:getCardsNum("Jink")==1 then return end
		self.sfofl_quanyi_card = cards[1]:getId()
		use.card = sgs.Card_Parse("#sfofl_quanyi:.:")
		use.to:append(zhugeliang)
		return
	end
	if cards[1]:getNumber() < 7 and cards[1]:isBlack() then
		for _,enemy in sgs.list(self.enemies)do
			if self:doDisCard(enemy,"h") and self.player:canPindian(enemy) and not hasZhaxiangEffect(enemy) then
				self.room:addPlayerMark(self.player, "ai_sfofl_quanyi-PlayClear")
				self.sfofl_quanyi_card = cards[1]:getId()
				use.card = sgs.Card_Parse("#sfofl_quanyi:.:")
				use.to:append(enemy)
				return
			end
		end
	end

	for _,enemy in sgs.list(self.enemies)do
		if self:doDisCard(enemy,"h") and self.player:canPindian(enemy) then
			use.card = sgs.Card_Parse("#sfofl_quanyi:.:")
			use.to:append(enemy)
			return
		end
	end
	return nil
end
sgs.ai_card_intention["sfofl_quanyi"] = 80

sgs.ai_skill_invoke.sfofl_quanyi = function(self,data)
	if self.player:getMark("ai_sfofl_quanyi-PlayClear") > 0 then return false end
	return true
end
sgs.ai_skill_use["@@sfofl_qupo"] = function(self,prompt,method)
	--if sgs.turncount<=1 then return "." end
	if not self.room:hasCurrent() then return "." end
	local current = self.room:getCurrent()
	if current:isDead() then return "." end
	if self:isEnemy(current) and self:willSkipPlayPhase(current) and current:getHandcardNum() <= 2 then return "." end
	if self:isFriend(current) and (not self:willSkipPlayPhase(current) or not hasZhaxiangEffect(current)) then return "." end
	local target
		
	local give = {}
	if self:needToThrowArmor() then table.insert(give,self.player:getArmor():getEffectiveId()) end
	if #give<1 then
		local allcards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(allcards)
		table.insert(give,allcards[1]:getEffectiveId())
	end
	if #give>0 then
		local card = give[1]
		if sgs.Sanguosha:getCard(card):isRed() then
			for _, friend in ipairs(self.friends_noself) do
				if current:inMyAttackRange(friend) then
					target = friend
					break
				end
			end
		else
			for _, friend in ipairs(self.friends_noself) do
				if current:inMyAttackRange(friend) then
					for _, enemy in ipairs(self.enemies) do
						if current:inMyAttackRange(enemy) then
							target = enemy
							break
						end
					end
				end
			end
		end
	end
	if #give>0 and target then
		return "#sfofl_qupo:"..give[1]..":->"..target:objectName()
	end
	return "."
end


sgs.ai_skill_cardask["@sfofl_baoquan"] = function(self,data,pattern)
	local damage = data:toDamage()
	if self:needToLoseHp(self.player, damage.from, damage.card) then return "." end
	local player = self.player
	local cards = player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
   	for _,c in sgs.list(cards)do
    	if sgs.Sanguosha:matchExpPattern(pattern,player,c)
		then return c:getEffectiveId() end
	end
    return "."
end

function sgs.ai_cardneed.sfofl_baoquan(to,card)
	return card:isKindOf("TrickCard")
end

sgs.sfofl_baoquan_keep_value = sgs.jizhi_keep_value

local sfofl_horsetailwhisk_skill = {}
sfofl_horsetailwhisk_skill.name = "sfofl_horsetailwhisk"
table.insert(sgs.ai_skills,sfofl_horsetailwhisk_skill)
sfofl_horsetailwhisk_skill.getTurnUseCard = function(self)
	local cards = self.player:getHandcards()
	cards = self:sortByUseValue(cards,true)
	if #cards>0 and (self:getOverflow()>0 or self:needKongcheng() and #cards<2) then
		self:sortByKeepValue(cards)
		local card = cards[math.max(1,math.min(self.player:getMaxCards(),#cards))]
		return sgs.Card_Parse("#sfofl_horsetailwhisk:"..card:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#sfofl_horsetailwhisk"] = function(card,use,self)
	use.card = card
end

sgs.ai_view_as.sfofl_horsetailwhisk = function(card,player,card_place,class_name)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceSpecial and player:getPile("sfofl_horsetailwhisk"):contains(card:getEffectiveId()) and not card:hasFlag("using") and player:getPile("sfofl_horsetailwhisk"):length() >= 2 then
		if class_name=="Nullification" and player:getPile("sfofl_horsetailwhisk"):length() >= 3 then
			return ("nullification:sfofl_horsetailwhisk[%s:%s]=%d"):format(suit,number,card_id)
		elseif class_name=="Jink" and player:getPile("sfofl_horsetailwhisk"):length() ~= 3 then
			return ("jink:sfofl_horsetailwhisk[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

sgs.ai_target_revises.sfofl_plainclothes = function(to,card, self)
	if card:isKindOf("Slash") and to:getMark("sfofl_plainclothes-Clear") == 0 and not self:hasCrossbowEffect()
	then return true end
end

sgs.ai_skill_discard.sfofl_2_shiyin = function(self)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		table.insert(to_discard, card:getEffectiveId())
		return to_discard
	end
	return {}
end
sgs.ai_target_revises.sfofl_quwu = function(to,card)
	if not to:getPile("sfofl_noise"):isEmpty() then 
        for _, id in sgs.qlist(to:getPile("sfofl_noise")) do
			local c = sgs.Sanguosha:getCard(id)
			if card:getSuit() == c:getSuit()
			then return true end
		end
	end
end
local sfofl_liaozou_skill = {}
sfofl_liaozou_skill.name = "sfofl_liaozou"
table.insert(sgs.ai_skills, sfofl_liaozou_skill)
sfofl_liaozou_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getPile("sfofl_noise"):isEmpty() then return end
	for _, id in sgs.qlist(self.player:getPile("sfofl_noise")) do
		local c = sgs.Sanguosha:getCard(id)
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:getSuit() == c:getSuit() then
				return 
			end
		end
	end
	return sgs.Card_Parse("#sfofl_liaozou:.:")
end

sgs.ai_skill_use_func["#sfofl_liaozou"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_priority["sfofl_liaozou"] = 7
sgs.ai_use_value["sfofl_liaozou"] = 7

sgs.ai_view_as.sfofl_tigertally = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and card:isRed() and card:isEquipped() and not card:hasFlag("using") then
		return ("slash:sfofl_tigertally[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local sfofl_tigertally_skill = {}
sfofl_tigertally_skill.name = "sfofl_tigertally"
table.insert(sgs.ai_skills,sfofl_tigertally_skill)
sfofl_tigertally_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("e")
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

	local disCrossbow = false
	if self:getCardsNum("Slash")<2
	or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao")
	then disCrossbow = true end

	self:sort(self.enemies,"defense")

	self:sort(self.enemies,"defense")

	for _,card in ipairs(cards)do
		if not isCard("Tigertally",card,self.player) and  (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
		and (not isCard("Crossbow",card,self.player) or disCrossbow)
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard())>0)
		then table.insert(red_card,card) end
	end

	for _,card in ipairs(red_card)do
		local slash = dummyCard("slash")
		slash:addSubcard(card)
		slash:setSkillName("sfofl_tigertally")
		if slash:isAvailable(self.player)
		then return slash end
	end
end

sgs.ai_skill_invoke.sfofl_qixing = function(self,data)
	if self:needKongcheng() then return true end
	if 7 - self.player:getHandcardNum() > math.random(1, 3) then return true end
	return false
end

sgs.ai_card_priority.sfofl_qixing = function(self,card,v)
	if self.player:getMark("sfofl_qixing")>0 then 
		if self.player:getMark("sfofl_qixingCard"..card:getTypeId()) == 0 then
			return 10
		end
	end
end

sgs.ai_skill_invoke.sfofl_lyre = function(self,data)
	local target = data:toDamage().from
	if target and self:doDisCard(target, "he") then return true end
	return false
end
sgs.ai_choicemade_filter.cardChosen.sfofl_lyre = sgs.ai_choicemade_filter.cardChosen.snatch


local sfofl_yijue_skill = {}
sfofl_yijue_skill.name = "sfofl_yijue"
table.insert(sgs.ai_skills,sfofl_yijue_skill)
sfofl_yijue_skill.getTurnUseCard = function(self)
	if self.player:getKingdom() ~= "shu" then return end
	return sgs.Card_Parse("#sfofl_yijue:.:")
end

sgs.ai_skill_use_func["#sfofl_yijue"] = function(card,use,self)
	self:sort(self.enemies,"handcard")
	local max_card = self:getMaxCard()
	if not max_card then return end
	local max_point = max_card:getNumber()
	if self.player:hasSkill("yingyang") then max_point = math.min(max_point+3,13) end
	if self.player:hasSkill("kongcheng") and self.player:getHandcardNum()==1 then
		for _,enemy in ipairs(self.enemies)do
			if self.player:canPindian(enemy) and self:hasLoseHandcardEffective(enemy) and not (enemy:hasSkills("tuntian+zaoxian") and enemy:getHandcardNum()>2) then
				sgs.ai_use_priority["sfofl_yijue"] = 1.2
				self.sfofl_yijue_card = max_card:getId()
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if enemy:hasFlag("AI_HuangtianPindian") and enemy:getHandcardNum()==1 and self.player:canPindian(enemy) then
			sgs.ai_use_priority["sfofl_yijue"] = 7.2
			self.sfofl_yijue_card = max_card:getId()
			use.card = card
			use.to:append(enemy)
			enemy:setFlags("-AI_HuangtianPindian")
			return
		end
	end

	local zhugeliang = self.room:findPlayerBySkillName("kongcheng")

	sgs.ai_use_priority["sfofl_yijue"] = 7.2
	self:sort(self.enemies)
	self.enemies = sgs.reverse(self.enemies)
	for _,enemy in ipairs(self.enemies)do
		if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if enemy_max_card and enemy:hasSkill("yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
			if max_point>enemy_max_point then
				self.sfofl_yijue_card = max_card:getId()
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum()==1) and self.player:canPindian(enemy) then
			if max_point>=10 then
				self.sfofl_yijue_card = max_card:getId()
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end

	sgs.ai_use_priority["sfofl_yijue"] = 1.2
	local min_card = self:getMinCard()
	if not min_card then return end
	local min_point = min_card:getNumber()
	if self.player:hasSkill("yingyang") then min_point = math.max(min_point-3,1) end

	local wounded_friends = self:getWoundedFriend()
	if #wounded_friends>0 then
		for _,wounded in ipairs(wounded_friends)do
			if wounded:getHandcardNum()>1 and wounded:getLostHp()/wounded:getMaxHp()>=0.3 and self.player:canPindian(wounded) then
				local w_max_card = self:getMaxCard(wounded)
				local w_max_number = w_max_card and w_max_card:getNumber() or 0
				if w_max_card and wounded:hasSkill("yingyang") then w_max_number = math.min(w_max_number+3,13) end
				if (w_max_card and w_max_number>=min_point) or min_point<=4 then
					self.sfofl_yijue_card = min_card:getId()
					use.card = card
					use.to:append(wounded)
					return
				end
			end
		end
	end

	if zhugeliang and self:isFriend(zhugeliang) and zhugeliang:getHandcardNum()==1 and zhugeliang:objectName()~=self.player:objectName()
		and self.player:canPindian(zhugeliang) then
		if min_point<=4 then
			self.sfofl_yijue_card = min_card:getId()
			use.card = card
			use.to:append(zhugeliang)
			return
		end
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByUseValue(cards,true)
		if self:getEnemyNumBySeat(self.player,zhugeliang)>=1 then
			if isCard("Jink",cards[1],self.player) and self:getCardsNum("Jink")==1 then return end
			self.sfofl_yijue_card = cards[1]:getId()
			use.card = card
			use.to:append(zhugeliang)
			return
		end
	end
end

sgs.ai_skill_pindian.sfofl_yijue = sgs.ai_skill_pindian.yijue

sgs.ai_cardneed.sfofl_yijue = sgs.ai_cardneed.yijue

sgs.ai_card_intention["sfofl_yijue"] = 0
sgs.ai_use_value["sfofl_yijue"] = 8.5


local sfofl_nuchen_skill = {}
sfofl_nuchen_skill.name = "sfofl_nuchen"
table.insert(sgs.ai_skills,sfofl_nuchen_skill)
sfofl_nuchen_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_nuchen:.:")
end

sgs.ai_skill_use_func["#sfofl_nuchen"] = function(card,use,self)
			
	self:sort(self.enemies,"handcard")
	for _,p in ipairs(self.enemies)do
		if self:damageIsEffective(p, sgs.DamageStruct_Normal) and not self:cantbeHurt(p) and not p:isKongcheng() then
			use.card = sgs.Card_Parse("#sfofl_nuchen:.:")
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_priority["sfofl_nuchen"] = sgs.ai_use_priority.Slash+0.1
sgs.ai_use_value["sfofl_nuchen"] = 8.5
sgs.ai_skill_cardask["@sfofl_nuchen"] = function(self,data,pattern,target)
	local cards = self.player:getCards("h")
	cards = self:sortByUseValue(cards,true)
	for i,c in sgs.list(cards)do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,c) or c:isKindOf(pattern) then
			if self:isFriend(target) then
				if self:needToLoseHp(target,self.player,nil)
				then else break end
			end
			if i>#cards/2 and isCard("Peach",c,self.player) then
				if not self:isWeak(nil,false) or self:ajustDamage(self.player,target,1,nil)>1
				then return c:getId() end
			else
				return c:getId()
			end
		end
	end
	return "."
end

local sfofl_zhiji_skill = {}
sfofl_zhiji_skill.name = "sfofl_zhiji"
table.insert(sgs.ai_skills, sfofl_zhiji_skill)
sfofl_zhiji_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sfofl_zhiji") then return nil end	
	if #self.enemies==0 then return nil end	
	return sgs.Card_Parse("#sfofl_zhiji:.:")
end

sgs.ai_skill_use_func["#sfofl_zhiji"] = function(card, use, self)
	self:sort(self.friends,"defense",false)
	self:sort(self.enemies,"defense")
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_use = {}
	for _, card in ipairs(cards) do
		table.insert(to_use, card:getId())
		if #to_use == 2 then break end
	end
	if #to_use < 2 then
		return
	end
	for _,p in ipairs(self.enemies) do
		for _,q in ipairs(self.enemies) do
			if q:objectName() ~=p:objectName() and p:canSlash(q,false)
				and q:canSlash(p,false) then
				
				use.card = sgs.Card_Parse("#sfofl_zhiji:".. table.concat(to_use, "+") ..":")
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
			if q:objectName() ~=p:objectName()
				and p:canSlash(q,false)
				and q:canSlash(p,false) then
				use.card = sgs.Card_Parse("#sfofl_zhiji:".. table.concat(to_use, "+") ..":")
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


local sfofl_jiefeng_skill = {}
sfofl_jiefeng_skill.name = "sfofl_jiefeng"
table.insert(sgs.ai_skills, sfofl_jiefeng_skill)
sfofl_jiefeng_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies==0 then return nil end	
	return sgs.Card_Parse("#sfofl_jiefeng:.:")
end

sgs.ai_skill_use_func["#sfofl_jiefeng"] = function(card, use, self)
	local archery_attack = sgs.Sanguosha:cloneCard("archery_attack")
	archery_attack:setSkillName("sfofl_jiefeng")
	archery_attack:deleteLater()
	local dummy_use = self:aiUseCard(archery_attack, dummy())
	if dummy_use.card then
		local cards = sgs.QList2Table(self.player:getHandcards())
		local to_use = {}
		for _, card in ipairs(cards) do
			if not isCard("ArcheryAttack",card,self.player) then
				table.insert(to_use, card:getId())
				if #to_use == 2 then break end
			end
		end
		if #to_use == 2 then
			use.card = sgs.Card_Parse("#sfofl_jiefeng:".. table.concat(to_use, "+") ..":")
			return
		end
	end
end
sgs.ai_use_value["sfofl_jiefeng"] =  sgs.ai_use_value.ArcheryAttack
sgs.ai_use_priority["sfofl_jiefeng"] = sgs.ai_use_priority.ArcheryAttack
sgs.dynamic_value.damage_card["sfofl_jiefeng"] = true

sgs.ai_skill_invoke.sfofl_zhonghu = true

sgs.ai_skill_askforag.sfofl_weihou = function(self, card_ids)
	local judge = self.room:getTag("sfofl_weihou"):toJudge()
	local cards = {}
	for card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	local card_id = self:getRetrialCardId(cards, judge)
	if card_id ~= -1 then
		return card_id
	end

	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByUseValue(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_skill_playerchosen.sfofl_jianwei = function(self, targets)
	self:sort(self.enemies, "hp")
	
	local max = 0
	local target
	for _, enemy in ipairs(self.enemies) do
		if enemy:getCards("he"):length() - self.player:getCards("he"):length() > max then
			max = enemy:getCards("he"):length() - self.player:getCards("he"):length()
			target = enemy
		end
	end
	if target and (max + self.player:getJudgingArea():length() - target:getJudgingArea():length() > 2) then
		return target
	end
	return nil
end

sgs.ai_skill_invoke.sfofl_mouchuan = true
sgs.ai_skill_playerchosen.sfofl_mouchuan = function(self, targets)
	self:sort(self.friends_noself, "handcard")
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local c,to = self:getCardNeedPlayer(cards)
	if c and to then
		return to
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend, self.player) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		return friend
	end
	return targets:last()
end

sgs.ai_can_damagehp.sfofl_qingsuan = function(self,from,card,to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
	return from:getKingdom() ~= to:getKingdom() and self:isEnemy(from) and from:getMark("sfofl_qingsuan"..to:objectName()) == 0
	end
end

sgs.ai_skill_discard.sfofl_daohe = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)

	table.insert(to_discard, cards[1]:getEffectiveId())
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end


local sfofl_daohe_skill = {}
sfofl_daohe_skill.name = "sfofl_daohe"
table.insert(sgs.ai_skills,sfofl_daohe_skill)
sfofl_daohe_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_daohe:.:")
end
sgs.ai_skill_use_func["#sfofl_daohe"] = function(card,use,self)
	local arr1,arr2 = self:getWoundedFriend(false,false)
	local target = nil

	if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and arr1[1]:getHp()<getBestHp(arr1[1]) then target = arr1[1] end
	if target and not target:isKongcheng() then
		use.card = card
		use.to:append(target)
		return
	end
	if self:getOverflow()>0 and #arr2>0 then
		for _,friend in ipairs(arr2)do
			if not friend:hasSkills("hunzi|longhun") and not friend:isKongcheng() then
				use.card = card
				use.to:append(friend)
				return
			end
		end
	end
end

sgs.ai_use_priority["sfofl_daohe"] = 4.2
sgs.ai_card_intention["sfofl_daohe"] = -100

sgs.dynamic_value.benefit["sfofl_daohe"] = true

local sfofl_zhiyiz_skill = {}
sfofl_zhiyiz_skill.name = "sfofl_zhiyiz"
table.insert(sgs.ai_skills,sfofl_zhiyiz_skill)
sfofl_zhiyiz_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_zhiyiz:.:")
end

sgs.ai_skill_use_func["#sfofl_zhiyiz"] = function(card,use,self)
	local target
	self:sort(self.enemies,"defense")
	if not target then
		for _,enemy in ipairs(self.enemies)do
			if not (self:hasSkills(sgs.masochism_skill,enemy) and not self.player:hasSkill("jueqing"))
			and self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player)
			and not self:needToLoseHp(enemy)
			then target = enemy end
			if target then break end
		end
		if not target then
			for _,enemy in ipairs(self.enemies)do
				if not (self:hasSkills(sgs.masochism_skill,enemy) and not self.player:hasSkill("jueqing"))
				and not enemy:hasSkills(sgs.cardneed_skill.."|jijiu|tianxiang|buyi")
				and self:damageIsEffective(enemy,sgs.DamageStruct_Normal,self.player) and not self:cantbeHurt(enemy)
				and not self:needToLoseHp(enemy)
				then target = enemy end
				if target then break end
			end
		end
	end

	if target then
		use.card = sgs.Card_Parse("#sfofl_zhiyiz:.:")
		use.to:append(target)
	end
end



local sfofl_huxiao_skill = {}
sfofl_huxiao_skill.name = "sfofl_huxiao"
table.insert(sgs.ai_skills, sfofl_huxiao_skill)
sfofl_huxiao_skill.getTurnUseCard = function(self, inclusive)
	local card = sgs.Sanguosha:getCard(self.player:getMark("sfofl_huxiaoskill-Clear"))
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(usable_cards, true)
	for _,c in ipairs(usable_cards) do
		if c:getSuit() == card:getSuit() or c:getNumber() == card:getNumber() then
			local cardex = sgs.Sanguosha:cloneCard(card:objectName(), c:getSuit(), c:getNumber())
			cardex:setSkillName("sfofl_huxiao")
			cardex:deleteLater()
			if not self.player:isCardLimited(cardex, sgs.Card_MethodUse, true) and cardex:isAvailable(self.player) then
			local name = card:objectName()
			local new_card = sgs.Card_Parse((name..":sfofl_huxiao[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
				assert(new_card) 
				return new_card
			end
		end
	end
end

sgs.ai_view_as.sfofl_huxiao = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getMark("sfofl_huxiaoskill-Clear") == 0 then return nil end
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		local c = sgs.Sanguosha:getCard(player:getMark("sfofl_huxiaoskill-Clear"))
		local name = c:objectName()
		if name and (card:getSuit() == c:getSuit() or card:getNumber() == c:getNumber()) then
			return (name..":sfofl_huxiao[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end


local function fangtongca(tasum, cards)
	local sum = 0
	local usecards = {}
	if #cards > 30 then
		for _,card in sgs.list(cards) do
			if (card:getNumber() + sum) <= tasum then
				table.insert(usecards,card:getEffectiveId())
				sum = sum + card:getNumber()
			end
		end
	else
		local n = #cards
		local allcards = {}
		for _,c in sgs.list(cards) do
			table.insert(allcards, c:getEffectiveId())
		end
		for i = 1, 2^n, 1 do
			sum = 0
			usecards = {}
			for j = 1, n, 1 do
				if bit32.band(i,(2^j)) ~= 0 then
					table.insert(usecards,allcards[j])
				end
			end
			for _,id in ipairs(usecards) do
				sum = sum + sgs.Sanguosha:getCard(id):getNumber()
			end
			if sum == tasum then break end
		end
	end

	if sum == tasum then 
		return usecards
	else
		return {}
	end
end
sgs.ai_guhuo_card.sfofl_longyin = function(self, toname, class_name)
    if class_name and self:getCardsNum(class_name) > 0 then return end
    local c = dummyCard(toname)
    if (not c) then return end
	c:setSkillName("sfofl_longyin")
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local sum = 0
	for _,c in sgs.list(cards) do
		sum = sum + c:getNumber()
	end
	if sum < 13 then return end
	
	local usecards = {}
	for _,card in ipairs(cards) do
		sum = 0
		local tem = 13 - card:getNumber()
		usecards = fangtongca(tem,cards)
		if #usecards > 0 then
			table.insert(usecards,card:getEffectiveId())
		end
		for _,c in ipairs(usecards) do
			sum = sum + sgs.Sanguosha:getCard(c):getNumber()
		end
		if sum == 13 then break end
	end
	if sum ~= 13 then return end
    if #usecards > 0 and (c:isKindOf("BasicCard") or c:isNDTrick()) then
        return "#sfofl_longyin:"..table.concat(usecards, "+") ..":"..toname
    end
end
addAiSkills("sfofl_longyin").getTurnUseCard = function(self)
	if self.player:getMark("sfofl_longyin-Clear") > 0 then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local usecards = {}
	local sum = 0
	for _,card in ipairs(cards) do
		sum = 0
		local tem = 13 - card:getNumber()
		usecards = fangtongca(tem,cards)
		if #usecards > 0 then
			table.insert(usecards,card:getEffectiveId())
		end
		for _,c in ipairs(usecards) do
			sum = sum + sgs.Sanguosha:getCard(c):getNumber()
		end
		if sum == 13 then break end
	end
	if sum ~= 13 then return end
    for c, pn in sgs.list(RandomList(patterns())) do
        c = dummyCard(pn)
        if c and (c:isKindOf("BasicCard") or c:isNDTrick()) and self:getCardsNum(c) == 0 then
            if c:isKindOf("Analeptic") then continue end
            c:setSkillName("sfofl_longyi")
			
            for _,id in ipairs(usecards) do
				c:addSubcard(sgs.Sanguosha:getCard(id))
			end
            if c:isAvailable(self.player)
                and self:aiUseCard(c).card
            then
                return c
            end
        end
    end
end

sgs.ai_ajustdamage_from.sfofl_wushuang = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and from:getMark("sfofl_xiuluo") > 1 and not card:hasFlag("sfofl_wushuang"..to:objectName())
    then
        return 1
    end
end

--sfofl_2_jianshu
local sfofl_2_jianshu_skill = {}
sfofl_2_jianshu_skill.name = "sfofl_2_jianshu"
table.insert(sgs.ai_skills,sfofl_2_jianshu_skill)
sfofl_2_jianshu_skill.getTurnUseCard = function(self,inclusive)
	self:sort(self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if a:canPindian(b) then
				local cards = sgs.QList2Table(self.player:getCards("h"))
				self:sortByKeepValue(cards)
				for _,c in sgs.list(cards)do
					return sgs.Card_Parse("#sfofl_2_jianshu:"..c:getEffectiveId()..":")
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_2_jianshu"] = function(card,use,self)
	self:sort(self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if a:canPindian(b)	then
				use.card = card
				use.to:append(a)
				self.sfofl_2_jianshu = b
				return
			end
		end
	end
end

sgs.ai_use_priority["sfofl_2_jianshu"] = 0
sgs.ai_use_value["sfofl_2_jianshu"] = 2.5
sgs.ai_card_intention["sfofl_2_jianshu"] = 80

sgs.ai_skill_playerchosen.sfofl_2_jianshu = function(self, targets)
	if self.sfofl_2_jianshu then return self.sfofl_2_jianshu end
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "h") and not self:isFriend(target) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "h") then
            return target
        end
    end
    return targets[1]
end

sgs.ai_skill_invoke["sfofl_jiufa"] = function(self,data)
	local card = data:toCard()
	if card:isKindOf("EquipCard") then
		local i = card:getRealCard():toEquipCard():location()
		if self.player:getEquip(i) and self.player:hasEquipArea(i) and not self:doDisCard(self.player, self.player:getEquip(i):getEffectiveId()) then
			return false
		end
	end
	if card:isKindOf("DelayedTrick") then
		return false
	end
	return true
end

sgs.ai_skill_invoke["underhengwu"] = true

sgs.ai_skill_discard.underhengwu = function(self, discard_num, min_num, optional, include_equip, pattern)
	local to_discard = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,c) and self:doDisCard(self.player, c:getEffectiveId())	then
			table.insert(to_discard, c:getEffectiveId())
		end
	end
	for _, c in sgs.qlist(self.player:getCards("h")) do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,c) and not table.contains(to_discard, c:getEffectiveId()) then
			if self:getKeepValue(c) > 18 then continue end
			table.insert(to_discard, c:getEffectiveId())
		end
	end
	return to_discard
end

sgs.ai_card_priority.underhengwu = function(self,card,v)
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getEquips():length() > 0 then
			for _,cc in sgs.qlist(p:getEquips()) do
				if cc:getSuitString() == card:getSuitString() then
					return 10
				end
			end
		end
	end
end

addAiSkills("undershouli").getTurnUseCard = function(self)
	local cards = {}
  	for i,p in sgs.list(self.room:getAlivePlayers())do
		for d,c in sgs.list(p:getCards("ej"))do
			if c:isKindOf("OffensiveHorse")
			then table.insert(cards,c) end
		end
	end
	self:sortByKeepValue(cards,nil,"l")
  	for _,c in sgs.list(cards)do
		local dc = dummyCard()
		dc:setSkillName("undershouli")
		dc:addSubcard(c)
		local d = self:aiUseCard(dc)
		if d.card and d.to
		and dc:isAvailable(self.player)
		then
			self.undershouli_to = d.to
			sgs.ai_use_priority.undershouli = sgs.ai_use_priority.Slash+0.6
			return sgs.Card_Parse("#undershouli:"..c:getEffectiveId()..":slash")
		end
	end
end

sgs.ai_skill_use_func["undershouli"] = function(card,use,self)
	if self.undershouli_to
	then
		use.card = card
		use.to = self.undershouli_to
	end
end

sgs.ai_use_value.undershouli = 5.4
sgs.ai_use_priority.undershouli = 2.8


sgs.ai_card_priority.undershouli = function(self,card)
	if card:getSkillName()=="undershouli"
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_guhuo_card.undershouli = function(self,toname,class_name)
	local cards = {}
  	for _,p in sgs.list(self.room:getAlivePlayers())do
		for _,c in sgs.list(p:getCards("ej"))do
			if c:isKindOf("OffensiveHorse") and class_name=="Slash"
			or c:isKindOf("DefensiveHorse") and class_name=="Jink"
			then table.insert(cards,c) end
		end
	end
	self:sortByKeepValue(cards,nil,"l")
  	for _,c in sgs.list(cards)do
		if self:getCardsNum(class_name)>0 then break end
		return "#undershouli:"..c:getEffectiveId()..":"..toname
	end
end
--change
-- sgs.ai_ajustdamage_to["&undershouli-Clear"] = function(self, from, to, card, nature)
--     return to:getMark("&undershouli-Clear")
-- end


sgs.ai_ajustdamage_from.sfofl_tuodao = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash") and card:isRed()
    then
        return 1
    end
end

function sgs.ai_cardsview.sfofl_baye(self,class_name,player)
	local c = dummyCard()
	c:setSkillName("sfofl_baye")
	local newcards = {}
	for _,c in sgs.list(sgs.ais[player:objectName()]:addHandPile())do
		if isCard("ExNihilo",c,player) and player:getPhase()<=sgs.Player_Play
		or isCard("Peach",c,player) then continue end
		if isCard("Slash",c,player) then return end
		table.insert(newcards,c)
	end
	sgs.ais[player:objectName()]:sortByKeepValue(newcards,nil,true)
	for _,h in sgs.list(newcards)do
		if c:subcardsLength()<2
		then c:addSubcard(h) end
	end
	if c:subcardsLength()>=2
	then c:setSuit(sgs.Card_NoSuitRed) return c:toString() end
end

local sfofl_baye_skill = {}
sfofl_baye_skill.name = "sfofl_baye"
table.insert(sgs.ai_skills,sfofl_baye_skill)
sfofl_baye_skill.getTurnUseCard = function(self,inclusive)
	local newcards = {}
	local cards = self:addHandPile()
	cards = self:sortByUseValue(cards,nil,true)
	for _,card in sgs.list(cards)do
		if isCard("Peach",card,self.player)
		or isCard("ExNihilo",card,self.player) and self.player:getPhase()<=sgs.Player_Play
		then continue end
		table.insert(newcards,card)
	end
	if #newcards<2
	or #cards<self.player:getHp() and self.player:getHp()<5
	and not self:needKongcheng() then return end
	local slashs = {}
	local newcards2 = InsertList({},newcards)
	for _,c1 in sgs.list(newcards)do
		if #slashs>#newcards/2 or #slashs>3 then break end
		table.removeOne(newcards2,c1)
		for _,c2 in sgs.list(newcards2)do
			local dc = sgs.Card_Parse("slash:sfofl_baye[no_suit_red:0]="..c1:getId().."+"..c2:getId())
			if dc:isAvailable(self.player) then table.insert(slashs,dc) end
		end
	end
	return #slashs>0 and slashs
end


sgs.ai_skill_use["@@sfofl_boss_wenjiu"] = function(self,prompt,method)
	if self.player:getPile("sfofl_boss_wuhun"):length() > 0 then
		local red = 0
		local black = 0
		
		for _,id in sgs.qlist(self.player:getPile("sfofl_boss_wuhun")) do
			local c = sgs.Sanguosha:getCard(id)
			if c:isBlack() then
				black = black + 1
			else
				red = red + 1
			end
		end
		local cards = {}
		if red > black then
			for _, id in sgs.qlist(self.player:getPile("sfofl_boss_wuhun")) do
				if sgs.Sanguosha:getCard(id):isBlack() then
					table.insert(cards, sgs.Sanguosha:getCard(id))
				end
			end
		else
			for _, id in sgs.qlist(self.player:getPile("sfofl_boss_wuhun")) do
				if sgs.Sanguosha:getCard(id):isRed() then
					table.insert(cards, sgs.Sanguosha:getCard(id))
				end
			end
		end
		if #cards == 0 then
			local suits = {}
			local maxnum, maxsuit = 0, nil
			for _,id in sgs.qlist(self.player:getPile("sfofl_boss_wuhun")) do
				local c = sgs.Sanguosha:getCard(id)
				if not suits[c:getSuitString()] then suits[c:getSuitString()] = 1 else suits[c:getSuitString()] = suits[c:getSuitString()] + 1 end
				if suits[c:getSuitString()] > maxnum then
					maxnum = suits[c:getSuitString()]
					maxsuit = c:getSuit()
				end
			end
			for _,id in sgs.qlist(self.player:getPile("sfofl_boss_wuhun")) do
				local c = sgs.Sanguosha:getCard(id):getSuit()
				if c ~= maxsuit then
					table.insert(cards, sgs.Sanguosha:getCard(id))
				end
			end
		end
		self:sortByUseValue(cards)
		local give_all_cards = {}
		local max = 3
		for _, c in ipairs(cards) do
			if #give_all_cards < max then
				table.insert(give_all_cards, c:getEffectiveId())
			end
		end
		if #give_all_cards < max then
			for _,id in sgs.qlist(self.player:getPile("sfofl_boss_wuhun")) do
				if #give_all_cards == 0 or not table.contains(give_all_cards, sgs.Sanguosha:getCard(id)) then
					table.insert(give_all_cards, id)
				end
				if #give_all_cards >= max then
					break
				end
			end
		end
		if #give_all_cards > 0 then
			local card_str = string.format("#sfofl_boss_wenjiu:%s:", table.concat(give_all_cards, "+"))
			return card_str
		end
	end

	return "."
end

sgs.ai_view_as.sfofl_boss_wusheng = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local red = 0
	local black = 0
	if not player:getPile("sfofl_boss_wuhun"):isEmpty() then
		for _,id in sgs.qlist(player:getPile("sfofl_boss_wuhun")) do
			local c = sgs.Sanguosha:getCard(id)
			if c:isBlack() then
				black = black + 1
			else
				red = red + 1
			end
		end
		if red > black and card_place~=sgs.Player_PlaceSpecial and card:isRed() and not card:isKindOf("Peach") and not card:hasFlag("using") then
			return ("slash:sfofl_boss_wusheng[%s:%s]=%d"):format(suit,number,card_id)
		end
	end
end

local sfofl_boss_wusheng_skill = {}
sfofl_boss_wusheng_skill.name = "sfofl_boss_wusheng"
table.insert(sgs.ai_skills,sfofl_boss_wusheng_skill)
sfofl_boss_wusheng_skill.getTurnUseCard = function(self,inclusive)
	if self.player:getPile("sfofl_boss_wuhun"):isEmpty() then return end
	local cards = self:addHandPile("he")
	cards = self:sortByUseValue(cards,true)

	local red = 0
	local black = 0
	
	for _,id in sgs.qlist(self.player:getPile("sfofl_boss_wuhun")) do
		local c = sgs.Sanguosha:getCard(id)
		if c:isBlack() then
			black = black + 1
		else
			red = red + 1
		end
	end
	if red > black then
		local red_card = {}
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


		for _,card in ipairs(cards)do
			if card:isRed() and not card:isKindOf("Slash")
			and (not isCard("Peach",card,self.player) and not isCard("ExNihilo",card,self.player) and not useAll)
			and (not isCard("Crossbow",card,self.player) or disCrossbow)
			and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard())>0)
			then table.insert(red_card,card) end
		end


		for _,card in ipairs(red_card)do
			local slash = dummyCard("slash")
			slash:addSubcard(card)
			slash:setSkillName("sfofl_boss_wusheng")
			if slash:isAvailable(self.player)
			then return slash end
		end
	elseif black > red then
		local cards = self:addHandPile("he")
		local black_card
		self:sortByUseValue(cards,true)
		local has_weapon = false
		for _,card in ipairs(cards)  do
			if card:isKindOf("Weapon") and card:isBlack() then has_weapon=true end
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
					local dummy_use = self:aiUseCard(card, dummy())
					if dummy_use.card then shouldUse = false end
				end
				if shouldUse then
					black_card = card
					break
				end
			end
		end
		if black_card then
			local suit = black_card:getSuitString()
			local number = black_card:getNumberString()
			local card_id = black_card:getEffectiveId()
			local card_str = ("dismantlement:sfofl_boss_wusheng[%s:%s]=%d"):format(suit,number,card_id)
			local dismantlement = sgs.Card_Parse(card_str)
			assert(dismantlement)
			return dismantlement
		end
	end
end

function sgs.ai_cardneed.sfofl_boss_wusheng(to,card)
	return to:getHandcardNum()<3
end

sgs.ai_card_priority.sfofl_boss_feijun = function(self,card,v)
	local record = self.player:property("sfofl_boss_feijunRecords"):toString()
	local suit = card:getSuitString()
	local records
	if (record) then
		records = record:split(",")
	end
	if records and (table.contains(records, suit) ) then

	else
		for _, equip in sgs.qlist(self.player:getEquips()) do
			if equip:getSuit() == card:getSuit() then
				return 10
			end
		end
	end
end
sgs.ai_cardneed.sfofl_boss_wushuang = sgs.ai_cardneed.slash
sgs.ai_ajustdamage_from.sfofl_boss_wushuang = function(self, from, to, card, nature)
    if card and card:isKindOf("Slash")
    then
        return 1
    end
end

sgs.hit_skill = sgs.hit_skill .. "|sfofl_boss_wushuang"
sgs.ai_card_priority.sfofl_boss_hanzhan_2 = function(self,card,v)
	for _,id in sgs.qlist(self.player:getPile("sfofl_boss_zhanyi")) do
		if card:getSuit() == sgs.Sanguosha:getCard(id):getSuit() then
			return 10
		end
	end
end

sgs.ai_skill_use["sfofl_boss_wushuang-jink"] = function(self,prompt)
	local data = self.player:getTag("sfofl_boss_wushuang")
	return sgs.ai_skill_cardask["slash-jink"](self,data,"jink",data:toCardEffect().from)
end

local sfofl_boss_xiuluo_skill = {}
sfofl_boss_xiuluo_skill.name = "sfofl_boss_xiuluo"
table.insert(sgs.ai_skills, sfofl_boss_xiuluo_skill)
sfofl_boss_xiuluo_skill.getTurnUseCard = function(self, inclusive)
	local card_str = "#sfofl_boss_xiuluo:.:"
	local skillcard = sgs.Card_Parse(card_str)

	return skillcard
end
sgs.ai_skill_use_func["#sfofl_boss_xiuluo"]=function(card,use,self)
	local useable_cards = {}
	if self.player:getPile("sfofl_boss_zhanyi"):length() >= 3 then
		for _, id in sgs.qlist(self.player:getPile("sfofl_boss_zhanyi")) do
			table.insert(useable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	if #useable_cards == 0 then return end
	local card_str = string.format("#sfofl_boss_xiuluo:%s:", useable_cards[1]:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	return
end
sgs.ai_skill_playerchosen.sfofl_boss_xiuluo = function(self, targets)
    targets = sgs.QList2Table(targets)
	if self.player:hasFlag("sfofl_boss_xiuluo_Discard_handcard") then
		for _, target in ipairs(targets) do
			if self:doDisCard(target, "h") then
				return target
			end
		end
	end
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "e") then
            return target
        end
    end
    return nil
end

sgs.ai_skill_choice["sfofl_boss_xiuluo"] = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "sfofl_boss_xiuluo_Discard_handcard") then
		self.room:setPlayerFlag(self.player, "sfofl_boss_xiuluo_Discard_handcard")
		local targets_3 = sgs.SPlayerList()
        for _,p in sgs.qlist(self.room:getAlivePlayers()) do
            if self.player:canDiscard(p, "h") and not p:isKongcheng() then
                targets_3:append(p)
            end
        end
        if not targets_3:isEmpty() then
			local target = sgs.ai_skill_playerchosen.sfofl_boss_xiuluo(self, targets_3)
			self.room:setPlayerFlag(self.player, "-sfofl_boss_xiuluo_Discard_handcard")
            if target ~= nil then
				return "sfofl_boss_xiuluo_Discard_handcard"
			end
        end
	end
	if table.contains(items, "sfofl_boss_xiuluo_Discard_equip") then
		local targets_3 = sgs.SPlayerList()
        for _,p in sgs.qlist(self.room:getAlivePlayers()) do
            if self.player:canDiscard(p, "h") and not p:isKongcheng() then
                targets_3:append(p)
            end
        end
        if not targets_3:isEmpty() then
			local target = sgs.ai_skill_playerchosen.sfofl_boss_xiuluo(self, targets_3)
			if target ~= nil then
				return "sfofl_boss_xiuluo_Discard_equip"
			end
		end
	end
	return "sfofl_boss_xiuluo_Draw"
end

sgs.ai_cardneed.sfofl_boss_shayi = sgs.ai_cardneed.slash


sgs.ai_skill_use["@@sfofl_boss_shajue"] = function(self,prompt,method)
	if self.player:getPile("sfofl_boss_shayi"):length() > 0 then
		local cards = {}
		for _, id in sgs.qlist(self.player:getPile("sfofl_boss_shayi")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
		self:sortByUseValue(cards)
		local give_all_cards = {}
		local max = 3
		for _, c in ipairs(cards) do
			if #give_all_cards < max then
				table.insert(give_all_cards, c:getEffectiveId())
			end
		end
		if #give_all_cards > 0 then
			local card_str = string.format("#sfofl_boss_shajue:%s:", table.concat(give_all_cards, "+"))
			return card_str
		end
	end

	return "."
end

sgs.ai_skill_invoke.sfofl_boss_numu = true

sgs.ai_skill_playerchosen.sfofl_boss_shajue = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "he", true) then
            return target
        end
    end
    return nil
end
sgs.ai_skill_invoke.sfofl_yanmouz = true
sgs.ai_skill_askforag.sfofl_yanmouz = function(self,card_ids)
	for _,id in sgs.list(card_ids)do
		if #self:poisonCards({id})<1 then
			return id
		end
	end
	return -1
end


local sfofl_zhanyan_skill = {}
sfofl_zhanyan_skill.name = "sfofl_zhanyan"
table.insert(sgs.ai_skills, sfofl_zhanyan_skill)
sfofl_zhanyan_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies==0 then return nil end	
	return sgs.Card_Parse("#sfofl_zhanyan:.:")
end

sgs.ai_skill_use_func["#sfofl_zhanyan"] = function(card, use, self)
	local good = 2
	local x = 0
	for _, id in sgs.qlist(self.room:getDiscardPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf("FireSlash") or sgs.Sanguosha:getCard(id):isKindOf("FireAttack") then
			x = x + 1
		end
	end
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:inMyAttackRange(p) then
			if self:needToLoseHp(p, self.player, nil) and self:canDamageHp(self.player,nil,p) and self:damageIsEffective(p, sgs.DamageStruct_Fire) and not self:cantbeHurt(p) then
				if self:isFriend(p) then
					good = good + 1
				elseif self:isEnemy(p) then
					good = good - 1
				end
			else
				if self:isFriend(p) then
					if x > 0 then
						good = good + 1
						x = x - 1
					else
						good = good - 1
					end
				elseif self:isEnemy(p) then
					if x > 0 then
						good = good - 1
						x = x - 1
					else
						good = good + 1
					end
				end
			end
			
		end
	end
	if good > 0 then
		use.card = sgs.Card_Parse("#sfofl_zhanyan:.:")
		return
	end
end
sgs.ai_skill_cardask["@sfofl_zhanyan"] = function(self,data,pattern)
	local target = data:toPlayer()
	if self:isFriend(target) then
		local x = 0
		for _, id in sgs.qlist(self.room:getDiscardPile()) do
			if sgs.Sanguosha:getCard(id):isKindOf("FireSlash") or sgs.Sanguosha:getCard(id):isKindOf("FireAttack") then
				x = x + 1
			end
		end
		if x > 0 then
			return "."
		end
	end
	if self:needToLoseHp(self.player, target, nil) or not self:damageIsEffective(self.player, sgs.DamageStruct_Fire) then return "." end
	local player = self.player
	local cards = player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
   	for _,c in sgs.list(cards)do
    	if sgs.Sanguosha:matchExpPattern(pattern,player,c)
		then return c:getEffectiveId() end
	end
    return "."
end
sgs.ai_skill_askforag.sfofl_zhanyan = function(self,card_ids)
	local target = self.room:getTag("sfofl_zhanyan"):toPlayer()
	if self:needToLoseHp(self.player, target, nil)  or not self:damageIsEffective(self.player, sgs.DamageStruct_Fire) then return -1 end
	for _,id in sgs.list(card_ids)do
		return id
	end
	return -1
end



sgs.ai_ajustdamage_to.sfofl_yuhuo = function(self,from,to,slash,nature)
	if nature == "F"
	then return -99 end
end
sgs.ai_skill_invoke.sfofl_diwan = true

sgs.ai_cardneed.sfofl_suiluan = sgs.ai_cardneed.slash
sgs.ai_skill_playerschosen.sfofl_suiluan = function(self, targets, max, min)
	local use = self.room:getTag("sfofl_suiluan"):toCardUse()
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


sgs.ai_skill_use["@@sfofl_longsong"] = function(self, prompt)
    if #self.friends_noself <= 0 then return "." end
    self:sort(self.friends_noself, "defense")
	local card
	local can_invoke = false
    local target
    for _,p in ipairs(self.friends_noself) do
        local find = false
        local skills = p:getVisibleSkillList()
        for _,s in sgs.qlist(skills) do
            local skillname = s:objectName()
            if (not s:isAttachedLordSkill()) and (not self.player:hasSkill(skillname)) then
                local translation = sgs.Sanguosha:translate(":"..skillname)
                if string.find(translation,"出牌阶段") then
                    find = true
                    break
                end
            end
        end
        if find then 
            target = p
            break
        end
    end
    if (not target) then return "." end
    if (not target) then target = self.friends_noself[1] end

	if target then
		for _, card in sgs.qlist(target:getCards("he")) do
			if card:isRed() then
				can_invoke = true
			end
		end
	end
	if can_invoke then
		local card_str = string.format("#sfofl_longsong:.:->%s", target:objectName())
    	return card_str
	else
		local cards = sgs.QList2Table(self.player:getCards("he"))
		if #cards <= 0 then return false end
		local card
		self:sortByUseValue(cards, true)
		for _,cc in ipairs(cards) do
			if cc:isRed() then
				card = cc
				break
			end
		end
		if not card then return "." end
		local card_str = string.format("#sfofl_longsong:%s:->%s", card:getEffectiveId(), target:objectName())
    	return card_str
	end
	


    return nil
end

local sfofl_fuli_skill = {}
sfofl_fuli_skill.name = "sfofl_fuli"
table.insert(sgs.ai_skills, sfofl_fuli_skill)
sfofl_fuli_skill.getTurnUseCard = function(self)
    if self.player:isNude() then return end
    if self.player:hasUsed("#sfofl_fuli") then return end
    return sgs.Card_Parse("#sfofl_fuli:.:")
end

sgs.ai_skill_use_func["#sfofl_fuli"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_choice.sfofl_fuli = function(self, choices)
    local items = choices:split("+")
    if #items == 1 then return items[1] end
    table.removeOne(items, "BasicCard")
    return items[math.random(1,#items)]
end

sgs.ai_skill_playerchosen.sfofl_fuli = function(self, targets)
    local target = nil
    local min = 999
    for _,p in sgs.qlist(targets) do
        if self:isEnemy(p) and p:getAttackRange() >= 1 and p:getAttackRange() <= min then
            target = p
            min = p:getAttackRange()
        end
    end
    if not target then
        for _,p in sgs.qlist(targets) do
            if self:isEnemy(p) then
                target = p
            end
        end
    end
    return target
end

sgs.ai_playerchosen_intention.sfofl_fuli = 40

sgs.ai_skill_choice.sfofl_dehua = function(self, choices)
    local items = choices:split("+")
    if #items == 1 then return items[1] end
    table.removeOne(items, "slash")
    for _,item in ipairs(items) do
        local card = sgs.Sanguosha:cloneCard(item, sgs.Card_SuitToBeDecided, -1)
        card:deleteLater()
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        self:useCardByClassName(card, usec)
        if usec.card then
            return item
        end
    end
    return items[math.random(1,#items)]
end

sgs.ai_skill_choice.sfofl_dehua_slash = function(self, choices)
    return "slash"
end

sgs.ai_skill_use["@@sfofl_dehua"] = function(self, prompt)
    local pattern = self.player:property("sfofl_dehua_card"):toString()
	local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
    card:setSkillName("sfofl_dehua")
    card:deleteLater()

    if card:targetFixed() then
        return string.format("#sfofl_dehua:.:%s",pattern)
    end

    local usec = {isDummy=true,to=sgs.SPlayerList()}
    self:useCardByClassName(card, usec)
    if usec.card then
        if usec.to:length() > 0 then
            local tos = {}
            for _,to in sgs.qlist(usec.to) do
                table.insert(tos, to:objectName())
            end
            return string.format("#sfofl_dehua:.:%s->%s",pattern, table.concat(tos, "+"))
        else
            return string.format("#sfofl_dehua:.:%s",pattern)
        end
    end
end






sgs.ai_skill_playerchosen.sfofl_langxi = function(self,targets)
	local tos = self:findPlayerToDamage(2,self.player,nil,targets)
	if #tos>0 then
		for _,p in ipairs(tos)do
			if self:cantDamageMore(self.player,p) or self:isFriend(p) then continue end
			return p
		end
		for _,p in ipairs(tos)do
			if self:isFriend(p) then continue end
			return p
		end
	end
	self:sort(self.enemies,"hp")
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<=self.player:getHp()
		and self:damageIsEffective(enemy)
		and not self:cantDamageMore(self.player,enemy)
		then return enemy end
	end
	for _,enemy in ipairs(self.enemies)do
		if enemy:getHp()<=self.player:getHp()
		and self:damageIsEffective(enemy)
		then return enemy end
	end
end

addAiSkills("sfofl_sancai").getTurnUseCard = function(self)
	sgs.ai_use_priority.sfofl_sancai = 0.8
	self.yjzy_to = nil
	local hand = self.player:getHandcards()
	local can_invoke = true
	for _, card in sgs.qlist(hand) do
		for _, card2 in sgs.qlist(hand) do
			if card ~= card2 and card:getTypeId() ~= card2:getTypeId() then
				can_invoke = false
				break
			end
		end
	end
	if not can_invoke then return end
	return sgs.Card_Parse("#sfofl_sancai:.:")
end

sgs.ai_skill_use_func["#sfofl_sancai"] = function(card,use,self)
	for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
		if c:isKindOf("Slash") then
			if table.contains(self.toUse,c)
			or self:getCardsNum("Slash")<2 and self:getOverflow()<1
			then continue end
			self.yjzy_to = self:AlPresentCardTo(c)
		elseif c:isKindOf("Jink") then
			if self:getCardsNum("Jink","h")<1 then continue end
			self.yjzy_to = self:AlPresentCardTo(c)
		elseif c:isKindOf("Peach") then
			if self:getCardsNum("Peach")<2
			and table.contains(self.toUse,c)
			then continue end
			self.yjzy_to = self:AlPresentCardTo(c)
		elseif c:isKindOf("Poison") then
			local can = self:isWeak() and math.random()<0.97
			local n = self:getOverflow()
			if n>0 then
				n = self:askForDiscard("Poison",n,n,false,false)
				if table.contains(n,c:getId()) then can = false end
			end
			if can then continue end
			if self.player:hasArmorEffect("yj_yinfengyi")
			and (self.player:getHp()<4 or self.player:getMaxCards()>=self.player:getHandcardNum()/2)
			and math.random()<0.9 then continue end
			self.yjzy_to = self:AlPresentCardTo(c,true)
			sgs.ai_use_priority.sfofl_sancai = 0.8
		elseif c:isKindOf("Qixingbaodao")
		then self.yjzy_to = self:AlPresentCardTo(c,true) or self:AlPresentCardTo(c)
		elseif c:isKindOf("EquipCard") then
			if table.contains(self.toUse,c) then continue end
			local enemie = sgs.ai_poison_card[c:objectName()] or self:evaluateArmor(c)<-5
			self.yjzy_to = self:AlPresentCardTo(c,enemie)
			sgs.ai_use_priority.sfofl_sancai = 8
		else
			if table.contains(self.toUse,c) then continue end
			self.yjzy_to = self:AlPresentCardTo(c,sgs.ai_poison_card[c:objectName()])
		end
		if not self.yjzy_to or self.player:hasFlag(self.yjzy_to:objectName().."yj_zhengyuUse"..c:getId()) then continue end
		use.card = card
	end
end

sgs.ai_use_value.sfofl_sancai = 5.4
sgs.ai_use_priority.sfofl_sancai = 0.8

sgs.ai_skill_use["@@sfofl_sancai"] = function(self, prompt)
	if self.yjzy_to then
		for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
			self.player:setFlags(self.yjzy_to:objectName().."yj_zhengyuUse"..c:getEffectiveId())
			return "#yj_zhengyuCard:"..c:getId()..":->"..self.yjzy_to:objectName()
		end
	end
	self:sort(self.friends_noself, "defense", true)
	for _,friend in ipairs(self.friends_noself) do
		for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
			if c:isKindOf("TrickCard") then
				return "#yj_zhengyuCard:"..c:getId()..":->"..friend:objectName()
			end
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) then
			for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
				if c:isKindOf("Weapon") then
					return "#yj_zhengyuCard:"..c:getId()..":->"..enemy:objectName()
				end
			end
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he", true) then
			for _,c in sgs.list(self:sortByKeepValue(self.player:getHandcards()))do
				if c:isKindOf("EquipCard") then
					return "#yj_zhengyuCard:"..c:getId()..":->"..enemy:objectName()
				end
			end
		end
	end
end

sgs.ai_skill_invoke.sfofl_xiandao = function(self, data)
	local move = data:toMoveOneTime()
	local target = self.room:findPlayerByObjectName(move.to:objectName())
	local ids = {}
	for _,id in sgs.list(move.card_ids)do
		if move.to:getTag("PresentCard"):toString()==tostring(id)
		then table.insert(ids,id) end
	end
	if #ids>0 then
		local c = sgs.Sanguosha:getCard(ids[1])
		if c:isKindOf("TrickCard") then
			return true
		elseif c:isKindOf("EquipCard") then
			if c:isKindOf("Weapon") then
				return self:damageIsEffective(target, sgs.DamageStruct_Normal) and ((not self:cantbeHurt(target) and self:isEnemy(target)) or (self:isFriend(target) and self:needToLoseHp(target, self.player)))
			end
			return self:doDisCard(target, "he", true)
		end
	end
    return self:isEnemy(target)
end



sgs.ai_skill_playerchosen.sfofl_yibing = function(self,targets)
	local move = self.room:getTag("sfofl_yibing"):toMoveOneTime()
	local ids = sgs.IntList()
	for _,id in sgs.qlist(move.card_ids) do
		if self.room:getCardOwner(id) == self.player and self.room:getCardPlace(id) == sgs.Player_PlaceHand then
			ids:append(id)
		end
	end
	if ids:length() > 2 then return nil end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	slash:deleteLater()
	slash:setSkillName("sfofl_yibing")
	slash:addSubcards(ids)
	local dummy_use = self:aiUseCard(slash, dummy())
    if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
        for _,to in sgs.qlist(dummy_use.to) do
			return to
		end
	end
	return nil
end
sgs.ai_cardneed.sfofl_shuangren = sgs.ai_cardneed.bignumber
local sfofl_shuangren_skill = {}
sfofl_shuangren_skill.name = "sfofl_shuangren"
table.insert(sgs.ai_skills,sfofl_shuangren_skill)
sfofl_shuangren_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	return sgs.Card_Parse("#sfofl_shuangren:.:")
end

sgs.ai_skill_use_func["#sfofl_shuangren"] = function(card,use,self)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()

	if #self.enemies==0 then return end
	self:sort(self.enemies,"handcard")
	local slash = dummyCard()
	local dummy_use = dummy()
	self.player:setFlags("slashNoDistanceLimit")
	self:useBasicCard(slash,dummy_use)
	self.player:setFlags("-slashNoDistanceLimit")

	if dummy_use.card then
		for _,enemy in sgs.list(self.enemies)do
			if self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local allknown = 0
				if self:getKnownNum(enemy)==enemy:getHandcardNum() then
					allknown = allknown+1
				end
				if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
					or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
					or (not enemy_max_card and max_point>10) then
					self.sfofl_shuangren_card = max_card:getEffectiveId()
					use.card = sgs.Card_Parse("#sfofl_shuangren:.:")
					use.to:append(enemy)
					return
					
				end
			end
		end
	end
end

sgs.ai_skill_playerchosen["sfofl_shuangren"] = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.ai_use_priority.sfofl_shuangren = 3


sgs.ai_view_as.sfofl_lizhen = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place==sgs.Player_PlaceEquip and not card:hasFlag("using") then
		return ("slash:sfofl_lizhen[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local sfofl_lizhen_skill = {}
sfofl_lizhen_skill.name = "sfofl_lizhen"
table.insert(sgs.ai_skills,sfofl_lizhen_skill)
sfofl_lizhen_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("e")
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
		if (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard())>0)
		then table.insert(red_card,card) end
	end


	for _,card in ipairs(red_card)do
		local slash = dummyCard("slash")
		slash:addSubcard(card)
		slash:setSkillName("sfofl_lizhen")
		if slash:isAvailable(self.player)
		then return slash end
	end
end


sgs.ai_skill_invoke.sfofl_qizhen = function(self, data)
   	local use = data:toCardUse()
	if use.card:hasFlag("DamageDone") then return true end
	for _,p in sgs.qlist(use.to) do
		if not self:doDisCard(p, "e") then
			return false
		end
	end
    return true
end


local sfofl_mujun_skill = {}
sfofl_mujun_skill.name = "sfofl_mujun"
table.insert(sgs.ai_skills, sfofl_mujun_skill)
sfofl_mujun_skill.getTurnUseCard = function(self, inclusive)
	if #self.friends_noself==0 then return nil end	
	return sgs.Card_Parse("#sfofl_mujun:.:")
end

sgs.ai_skill_use_func["#sfofl_mujun"] = function(card, use, self)
	local lieges = self.room:getLieges("qun", self.player)
	for _,p in sgs.qlist(lieges) do
		if self:isFriend(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

local sfofl_xuanshi_skill = {}
sfofl_xuanshi_skill.name = "sfofl_xuanshi"
table.insert(sgs.ai_skills, sfofl_xuanshi_skill)
sfofl_xuanshi_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies==0 then return nil end	
	return sgs.Card_Parse("#sfofl_xuanshi:.:")
end


sgs.ai_skill_use_func["#sfofl_xuanshi"] = function(card, use, self)
	self:sort(self.enemies, "defense", true)
	for _,enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he") then
			use.card = card
		 	if use.to then use.to:append(enemy) end
			return
		end
	end
	self:sort(self.friends_noself, "defense", true)
	for _,friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "he") then
			use.card = card
		 	if use.to then use.to:append(friend) end
			return
		end
	end
end
sgs.ai_use_priority.sfofl_xuanshi = 10



local sfofl_xiongye_skill = {}
sfofl_xiongye_skill.name = "sfofl_xiongye"
table.insert(sgs.ai_skills, sfofl_xiongye_skill)
sfofl_xiongye_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies==0 then return nil end	
	return sgs.Card_Parse("#sfofl_xiongye:.:")
end


sgs.ai_skill_use_func["#sfofl_xiongye"] = function(card, use, self)
	self:sort(self.enemies, "defense", true)
	local targets = sgs.SPlayerList()
	for _,enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and enemy:getKingdom() == "qun" then
			targets:append(enemy)
			if targets:length() >= self.player:getHandcardNum() then
				break
			end
		end
	end
	if targets:length() > 0 then
		use.card = card
		use.to = targets
	end
end
sgs.ai_use_priority.sfofl_xiongye = 10


sgs.ai_skill_cardask["@sfofl_xiongye"] = function(self, data, pattern)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
		then return h:getEffectiveId() end
		if h:isKindOf(pattern)
		then return h:getEffectiveId() end
	end
	return self:getCardId(pattern)
end

sgs.ai_skill_invoke.sfofl_mingjian = function(self, data)
	local target = self.room:getCurrent()
    if target and self:isFriend(target) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_mingjian = function(self, player, promptlist)
    local current = self.room:getCurrent()
    if promptlist[#promptlist] == "yes" then
        sgs.updateIntention(player, current, -70)
    end
end

sgs.ai_skill_playerchosen.sfofl_huituo = function(self,targets)
    self:sort(self.friends)
	for _,p in sgs.list(self.friends)do
		if p:isWounded() then
			return p
		end
	end
	for _,p in sgs.list(self.friends)do
		if self:canDraw(p) then
			return p
		end
	end
    return self.friends[1]
end

sgs.ai_playerchosen_intention.sfofl_huituo = -80

sgs.ai_skill_invoke.sfofl_yanggu = true



local sfofl_yanggu_skill = {}
sfofl_yanggu_skill.name = "sfofl_yanggu"
table.insert(sgs.ai_skills,sfofl_yanggu_skill)
sfofl_yanggu_skill.getTurnUseCard = function(self,inclusive)
	if self.player:getChangeSkillState("sfofl_yanggu") == 2 then
		local cards = self:addHandPile("h")
		cards = self:sortByUseValue(cards,true)

		for _,card in ipairs(cards)do
				local slash = dummyCard("zd_shengdongjixi")
				slash:addSubcard(card)
				slash:setSkillName("sfofl_yanggu")
				if slash:isAvailable(self.player)
				then return slash end
		end
	end
end

sgs.ai_skill_invoke.sfofl_zuifu = function(self, data)
	local target = data:toPlayer()
    if target and self:isEnemy(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and not self:cantbeHurt(target) then return true end
	return false
end



sgs.ai_guhuo_card.sfofl_jieqiao_quyi = function(self,toname,class_name)
    if self.player:getMark("&sfofl_jieqiao_quyi") <= 0 then return end
    if class_name and self:getCardsNum(class_name) > 0 then return end

	local card = sgs.Sanguosha:cloneCard(toname, sgs.Card_SuitToBeDecided, -1)
    card:deleteLater()
    if (not card) or (not card:isKindOf("BasicCard")) then return end

    return "#sfofl_jieqiao_quyi:.:"..toname
end

local sfofl_jieqiao_quyi_skill = {}
sfofl_jieqiao_quyi_skill.name = "sfofl_jieqiao_quyi"
table.insert(sgs.ai_skills, sfofl_jieqiao_quyi_skill)
sfofl_jieqiao_quyi_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("&sfofl_jieqiao_quyi") <= 0 then return end

    local basics = {"peach", "analeptic", "thunder_slash", "slash", "fire_slash"}
    for _,name in ipairs(basics) do
        local card = sgs.Sanguosha:cloneCard(name, sgs.Card_SuitToBeDecided, -1)
        card:deleteLater()
        if card and card:isAvailable(self.player) then
            --local dummy = self:aiUseCard(card)
            local dummy = {isDummy=true,to=sgs.SPlayerList()}
            self:useCardByClassName(card, dummy)
            local num = self:getCardsNum(card:getClassName(),"he")
			if dummy.card and dummy.to and ((num < 1) or (self.player:getMark("&sfofl_jieqiao_quyi") >= 3)) then
                self.sfofl_jieqiao_quyito = dummy.to
                return sgs.Card_Parse("#sfofl_jieqiao_quyi:.:"..name)
            end
        end
	end
end

sgs.ai_skill_use_func["#sfofl_jieqiao_quyi"] = function(card, use, self)
    use.card = card
	if use.to
	then
		use.to = self.sfofl_jieqiao_quyito
	end
end


local sfofl_lianhuan_skill = {}
sfofl_lianhuan_skill.name = "sfofl_lianhuan"
table.insert(sgs.ai_skills, sfofl_lianhuan_skill)
sfofl_lianhuan_skill.getTurnUseCard = function(self, inclusive)
	local card = sgs.Sanguosha:cloneCard("iron_chain", sgs.Card_SuitToBeDecided, -1)
	card:deleteLater()
	if card and card:isAvailable(self.player) then
		local dummy_use = self:aiUseCard(card, dummy())
		if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 and self.player:getHp() > 2 then
			return sgs.Card_Parse("#sfofl_lianhuan:.:")
		end
	end
end

sgs.ai_skill_use_func["#sfofl_lianhuan"] = function(card, use, self)
   local c = sgs.Sanguosha:cloneCard("iron_chain", sgs.Card_SuitToBeDecided, -1)
	c:deleteLater()
	c:setSkillName("sfofl_lianhuan")
	if c and c:isAvailable(self.player) then
		local dummy_use = self:aiUseCard(c, dummy())
		if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 and self.player:getHp() > 2 then
			use.card = card
			for _,to in sgs.qlist(dummy_use.to) do
				use.to:append(to)
			end
			return
		end
	end
end
sgs.ai_use_priority["sfofl_lianhuan"] = 2

sgs.ai_skill_invoke.sfofl_suozhou = function(self, data)
	local x = 0
	for _, p in sgs.list(self.room:getAllPlayers()) do
		if p:isChained() and self:canDraw(p, self.player) then
			if self:isFriend(p) then
				x = x + 1
			else
				x = x - 1
			end
		end
	end
	if x < 0 then return false end
	return true
end

sgs.ai_useto_revises.sfofl_yihuo = function(self, card, use, p)
	if card:isKindOf("IronChain")
	then
		if self:isFriend(p) and not p:isChained() then
			use.card = card
			use.to:append(p)
			return
		end
		return false
	end
end

sgs.ai_target_revises.sfofl_yihuo = function(to,card,self,use)
    if card:isKindOf("IronChain") and ((self:isFriend(to) and to:isChained()) or (self:isEnemy(to) and not to:isChained())) then return true end
end

sgs.ai_skill_invoke.sfofl_lijun = function(self, data)
	local target = data:toDamage().to
    if target and self:isFriend(target) and self:canDraw(target, self.player) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_lijun = function(self, player, promptlist)
    local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.to then
    	if promptlist[#promptlist] == "yes" then
        	sgs.updateIntention(player, damage.to, -20)
		else
			sgs.updateIntention(player, damage.to, 20)
		end
    end
end


sgs.ai_skill_invoke.sfofl_tongbei = function(self, data)
	local damage = data:toDamage()
    if damage.to and self:isEnemy(damage.to) then return true end
	return false
end

sgs.ai_skill_cardask["@sfofl_tongbei"] = function(self, data, pattern, target)
	local damage = data:toDamage()
	if self:cantDamageMore(damage.from, self.player) then return "." end
	if not self:damageIsEffective(self.player,damage.card,damage.from) then return "." end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
		then return h:getEffectiveId() end
		if h:isKindOf(pattern)
		then return h:getEffectiveId() end
	end
	return self:getCardId(pattern)
end

sgs.ai_fill_skill.sfofl_beirong = function(self)
	local valid = {}
    local cards = self.player:getCards("h")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	for i,h in sgs.list(cards)do
		if #valid>#cards/2 then break end
		local can = true
		for _,id in sgs.list(valid)do
			if h:getSuit()==sgs.Sanguosha:getCard(id):getSuit()
			then can = false break end
		end
		if can then
			table.insert(valid,h:getEffectiveId())
		end
	end
	local suits = {}
	for _,h in sgs.list(self.player:getCards("h"))do
		if table.contains(valid,h:getEffectiveId()) or table.contains(suits,h:getSuit()) then continue end
		table.insert(suits,h:getSuit())
	end
	return #valid>#suits and sgs.Card_Parse("#sfofl_beirong:"..table.concat(valid,"+")..":")
end

sgs.ai_skill_use_func["#sfofl_beirong"] = function(card,use,self)
	use.card = card
end

sgs.ai_skill_invoke.sfofl_yujun = function(self, data)
	local damage = data:toDamage()
	if self:isWeak() and self:getAllPeachNum() < 1 and damage.damage <= 1 then return false end
    if damage.to and self:isFriend(damage.to) and self:damageIsEffective(damage.to,damage.card,damage.from) and not self:needToLoseHp(damage.to, damage.from, damage.card) then return true end
	return false
end

sgs.ai_useto_revises.sfofl_yujun = function(self, card, use, p)
	if card:isKindOf("IronChain")
	then
		if self:isFriend(p) and not p:isChained() then
			use.card = card
			use.to:append(p)
			return
		end
		return false
	end
end

sgs.ai_target_revises.sfofl_yujun = function(to,card,self,use)
    if card:isKindOf("IronChain") and ((self:isFriend(to) and to:isChained()) or (self:isEnemy(to) and not to:isChained())) then return true end
end

sgs.ai_skill_invoke.sfofl_cailue = function(self, data)
	local target = data:toPlayer()
	if target then return self:doDisCard(target, "he") end
	return false
end

sgs.ai_skill_invoke.sfofl_sashuang = true


local sfofl_huoce_skill = {}
sfofl_huoce_skill.name = "sfofl_huoce"
table.insert(sgs.ai_skills, sfofl_huoce_skill)
sfofl_huoce_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return nil end
	return sgs.Card_Parse("#sfofl_huoce:.:")
end

sgs.ai_skill_use_func["#sfofl_huoce"] = function(card, use, self)
	self:sort(self.enemies)
	for _,enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h") then
			use.card = card
		 	if use.to then use.to:append(enemy) end
			return
		end
	end
	self:sort(self.friends_noself)
	for _,friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "h") then
			use.card = card
		 	if use.to then use.to:append(friend) end
			return
		end
	end
end
sgs.ai_use_priority["sfofl_huoce"] = 2.8

sgs.ai_skill_cardask["@sfofl_huoce"] = function(self, data, pattern, target, target2)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
		then return h:getEffectiveId() end
		if h:isKindOf(pattern)
		then return h:getEffectiveId() end
	end
	return self:getCardId(pattern)
end

sgs.ai_skill_playerchosen["sfofl_huoce"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _,p in ipairs(targets) do
		if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Fire) and not self:cantbeHurt(p) then
			return p
		end
	end
	return nil
end

local sfofl_boyan_skill = {}
sfofl_boyan_skill.name = "sfofl_boyan"
table.insert(sgs.ai_skills, sfofl_boyan_skill)
sfofl_boyan_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return nil end
	return sgs.Card_Parse("#sfofl_boyan:.:")
end

sgs.ai_skill_use_func["#sfofl_boyan"] = function(card, use, self)
	self:sort(self.enemies)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	if self.player:hasSkill("yingyang") then max_point = math.min(max_point+3,13) end
	if max_point >= 13 then sgs.ai_use_priority["sfofl_boyan"] = 3 end
	if self:getOverflow() > 1 and #self.toUse > 1 and math.random() < 0.3 then sgs.ai_use_priority["sfofl_boyan"] = 0 end
	for _,enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy) and enemy:getMark("sfofl_boyan-PlayClear") == 0 then
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if enemy_max_card and enemy:hasSkill("yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
			if max_point>enemy_max_point or max_point>10 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
	for _,enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if enemy_max_card and enemy:hasSkill("yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
			if max_point>enemy_max_point or max_point>10 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
		
	
		
	self:sort(self.friends_noself)
	for _,friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "h") and self.player:canPindian(friend) then
			use.card = card
		 	if use.to then use.to:append(friend) end
			return
		end
	end
end
sgs.ai_use_priority["sfofl_boyan"] = 2.8

function sgs.ai_skill_pindian.sfofl_boyan(minusecard,self,requestor)
	if requestor:getHandcardNum()==1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return cards[1]
	end
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber()<6 and  minusecard or maxcard )
end

sgs.ai_skill_choice["sfofl_mushi"] = function(self, choices, data)
	local skill_items = choices:split("+")
	if #skill_items == 1 then
		return skill_items[1]
	else
		return skill_items[math.random(1,#skill_items)]
	end
	return "cancel"
end

sgs.ai_skill_invoke.sfofl_dimeng = function(self, data)
	local pindian = data:toPindian()
	if pindian.from and pindian.to and self:isFriend(pindian.to) and self:isEnemy(pindian.from) then
		if pindian.to_card:getNumber() < pindian.from_card:getNumber() then
			return true
		end
	end
	if pindian.from and pindian.to and self:isFriend(pindian.from) and self:isEnemy(pindian.to) then
		if pindian.to_card:getNumber() >= pindian.from_card:getNumber() then
			return true
		end
	end
	return false
end

local sfofl_2_zhouji_skill = {}
sfofl_2_zhouji_skill.name = "sfofl_2_zhouji"
table.insert(sgs.ai_skills, sfofl_2_zhouji_skill)
sfofl_2_zhouji_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return nil end
	return sgs.Card_Parse("#sfofl_2_zhouji:.:")
end

sgs.ai_skill_use_func["#sfofl_2_zhouji"] = function(card, use, self)
	self:sort(self.enemies)
	for _,enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy) then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
		
		
	self:sort(self.friends_noself)
	for _,friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "h") and self.player:canPindian(friend) then
			use.card = card
		 	if use.to then use.to:append(friend) end
			return
		end
	end
end

local sfofl_zhaxiong_skill = {}
sfofl_zhaxiong_skill.name = "sfofl_zhaxiong"
table.insert(sgs.ai_skills,sfofl_zhaxiong_skill)
sfofl_zhaxiong_skill.getTurnUseCard = function(self)
	if #self.enemies<=0 then return end
	return sgs.Card_Parse("#sfofl_zhaxiong:.:")
end

sgs.ai_skill_use_func["#sfofl_zhaxiong"] = function(card,use,self)
	for _,enemy in sgs.list(self.enemies)do
		if self:damageMinusHp(enemy,1)>0
		or enemy:getHp()<3 and self:damageMinusHp(enemy,0)>0 and enemy:getHandcardNum()>0
		then
			use.card = card
			return
		end
	end
end

sgs.ai_use_priority["sfofl_zhaxiong"] = 10

sgs.ai_skill_invoke["sfofl_louchuan"] = function(self, data)
	local target = data:toPlayer()
	if self:isEnemy(target) and not(target:isChained() or self:needToLoseHp(target))
		and self:isGoodTarget(target,self.enemies) then return true end
	return false
end

function SmartAI:useCardYiguzuoqi(card,use)
	local slash = self:getCard("Slash")
	if slash and #self:getCards("Slash") > 1 and self.player:getMark("&sfofl_yiguzuoqi-Clear") == 0 then
		local dummy_use = self:aiUseCard(slash, dummy())
		if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
			use.card = card
		end
	end
end
sgs.ai_use_priority.Yiguzuoqi = 7
sgs.ai_keep_value.Yiguzuoqi = 2.2
sgs.ai_use_value.Yiguzuoqi = 4.7




local sfofl_barbs_skill = {}
sfofl_barbs_skill.name = "sfofl_barbs"
table.insert(sgs.ai_skills, sfofl_barbs_skill)
sfofl_barbs_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return nil end
	return sgs.Card_Parse("#sfofl_barbs:.:")
end

sgs.ai_skill_use_func["#sfofl_barbs"] = function(card, use, self)
	self:sort(self.enemies)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()
	for _,enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if enemy_max_card and enemy:hasSkill("yingyang") then enemy_max_point = math.min(enemy_max_point+3,13) end
			if max_point>enemy_max_point or max_point>10 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
		
end
sgs.ai_use_priority["sfofl_barbs"] = 1


--礼赂
sgs.ai_skill_invoke.sfofl_lilu = function(self,data)
	local invoke = false
	for _,p in ipairs(self.friends_noself)do
		if p:isKongcheng() and self:needKongcheng(p,true) then continue end
		invoke = true
		break
	end
	if not invoke then return false end
	return true
end

sgs.ai_skill_use["@@sfofl_lilu!"] = function(self,prompt)
	local mark = self.player:getMark("&sfofl_lilu")
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards,true)
	self:sort(self.friends_noself)
	
	local target
	for _,p in ipairs(self.friends_noself)do
		if self:canDraw(p) and not self:willSkipPlayPhase(p) then
			target = p
			break
		end
	end
	if not target then
		for _,p in ipairs(self.friends_noself)do
			if not (p:isKongcheng() and self:needKongcheng(p,true)) and not self:willSkipPlayPhase(p) then
				target = p
				break
			end
		end
	end
	if not target then
		for _,p in ipairs(self.friends_noself)do
			if self:canDraw(p) then
				target = p
				break
			end
		end
	end
	if not target then
		for _,p in ipairs(self.friends_noself)do
			if not (p:isKongcheng() and self:needKongcheng(p,true)) then
				target = p
				break
			end
		end
	end
	if not target then target = self.friends_noself[1] end
	
	local give,hand_num = {},self.player:getHandcardNum()
	if hand_num<mark+1 and target then
		if self:needToThrowLastHandcard(self.player,hand_num) then
			for _,c in ipairs(cards)do
				table.insert(give,c:getEffectiveId())
			end
			return "#sfofl_lilu:"..table.concat(give,"+")..":->"..target:objectName()
		end
		local card,friend = self:getCardNeedPlayer(cards,false)
		if card and friend then
			return "#sfofl_lilu:"..card:getEffectiveId()..":->"..friend:objectName()
		end
		return "#sfofl_lilu:"..cards[1]:getEffectiveId()..":->"..target:objectName()
	end
	
	for i = 1,mark+1 do
		if #cards<i then break end
		table.insert(give,cards[i]:getEffectiveId())
	end
	if #give>0 and target then
		return "#sfofl_lilu:"..table.concat(give,"+")..":->"..target:objectName()
	end
	return "."
end
sgs.ai_card_intention["sfofl_lilu"] = -80

sgs.ai_skill_discard.sfofl_lilu = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards)do
		if self:getKeepValue(c) > 10 then continue end
		if self:willUse(self.player,c, false,false, true) then continue end
			table.insert(to_discard,c:getEffectiveId())
		end
	for _,c in ipairs(sgs.QList2Table(self.player:getCards("e")))do
		if self:doDisCard(self.player, c:getEffectiveId()) then
			table.insert(to_discard,c:getEffectiveId())
		end
	end
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end


--翊正
sgs.ai_skill_playerchosen.sfofl_yizhengc = function(self,targets)
	if self.player:getMaxHp()<=3 or #self.friends_noself<=0 then return nil end
	local friends = {}
	for _,p in ipairs(self.friends_noself)do
		if p:getMark("&sfofl_yizhengc+to+#"..self.player:objectName())<=0 and not self:willSkipPlayPhase(p) then
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		self:sort(friends,"threat")
		return friends[1]
	end
	
	for _,p in ipairs(self.friends_noself)do
		if not self:willSkipPlayPhase(p) then
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		self:sort(friends,"threat")
		return friends[1]
	end
	
	for _,p in ipairs(self.friends_noself)do
		if p:getMark("&sfofl_yizhengc+to+#"..self.player:objectName())<=0 then
			table.insert(friends,p)
		end
	end
	if #friends>0 then
		self:sort(friends,"threat")
		return friends[1]
	end
	
	for _,p in ipairs(self.friends_noself)do
		table.insert(friends,p)
	end
	if #friends>0 then
		self:sort(friends,"threat")
		return friends[1]
	end
	
	self:sort(self.friends_noself,"threat")
	return self.friends_noself[1]
end
sgs.ai_playerchosen_intention.sfofl_yizhengc = -40

sgs.ai_fill_skill.sfofl_liaofu = function(self)
	local use_card
    local cards = self.player:getCards("h")
    cards = self:sortByUseValue(cards,true) -- 按保留值排序
	for i,h in sgs.list(cards)do
		if h:isKindOf("Slash") and self.player:getMark("sfofl_liaofu"..h:objectName()) == 0 then
			use_card = h
			break
		end
	end
	if use_card then
		return sgs.Card_Parse("#sfofl_liaofu:"..use_card:getEffectiveId()..":")
	end
end

sgs.ai_skill_use_func["#sfofl_liaofu"] = function(card,use,self)
	use.card = card
end

sgs.ai_skill_invoke.sfofl_liaofu = function(self,data)
	local use = data:toCardUse()
	return self:isEnemy(use.from) and not self:cantbeHurt(use.from) and self:canDamage(use.from,self.player,use.card)
end

sgs.ai_skill_invoke.sfofl_jinshou = function(self,data)
	return self:isWeak() and self:getAllPeachNum() + self.player:getHp() - 1 - getCardsNum("Peach,Analeptic",self.player,self.player) > 0
end

sgs.ai_target_revises.sfofl_jinshou = function(to,card,self)
	return card:isDamageCard() and card:isSingleTargetCard() and self.player~=to and to:getMark("&sfofl_jinshou-Self"..sgs.Player_RoundStart.."Clear") > 0
end


sgs.ai_skill_invoke.sfofl_sitong = function(self,data)
	local use = data:toCardUse()
	local target = use.from
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash:setSkillName("sfofl_sitong")
	self.player:setFlags("slashNoDistanceLimit")
	local dummy_use = self:aiUseCard(slash, dummy(true, 99, self.room:getOtherPlayers(target)))
	self.player:setFlags("-slashNoDistanceLimit")
	if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
		return true
	end
	return false
end

sgs.ai_skill_playerchosen.sfofl_jianjing = sgs.ai_skill_playerchosen.damage
local sfofl_jianjing_skill = {}
sfofl_jianjing_skill.name = "sfofl_jianjing"
table.insert(sgs.ai_skills,sfofl_jianjing_skill)
sfofl_jianjing_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	return sgs.Card_Parse("#sfofl_jianjing:.:")
end

sgs.ai_skill_use_func["#sfofl_jianjing"] = function(card,use,self)
	local max_card = self:getMaxCard()
	local max_point = max_card:getNumber()

	if #self.enemies==0 then return end
	self:sort(self.enemies,"handcard")

	for _,enemy in sgs.list(self.enemies)do
		if self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local allknown = 0
			if self:getKnownNum(enemy)==enemy:getHandcardNum() then
				allknown = allknown+1
			end
			if (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown>0)
				or (enemy_max_card and max_point>enemy_max_card:getNumber() and allknown<1 and max_point>10)
				or (not enemy_max_card and max_point>10) then
				for _,enemy2 in sgs.list(self.enemies)do
					if (enemy:objectName()~=enemy2:objectName())
						and self.player:distanceTo(enemy2)<=self.player:getAttackRange() then
						self.sfofl_jianjing_card = max_card:getEffectiveId()
						use.card = sgs.Card_Parse("#sfofl_jianjing:.:")
						use.to:append(enemy)
						return
					end
				end
			end
		end
	end
	local min_card = self:getMinCard()
	local min_point = min_card:getNumber()
	for _,friend in sgs.list(self.friends_noself)do
		if self.player:canPindian(friend) and min_point < 6 then
			for _,enemy2 in sgs.list(self.enemies)do
				if friend:distanceTo(enemy2)<=friend:getAttackRange() then
					self.sfofl_jianjing_card = min_card:getEffectiveId()
					use.card = sgs.Card_Parse("#sfofl_jianjing:.:")
					use.to:append(friend)
					return
				end
			end
			
		end
	end
end

sgs.ai_cardneed.sfofl_jianjing = sgs.ai_cardneed.bignumber

sgs.ai_can_damagehp.sfofl_dishou = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) then
		return self:isEnemy(from)
	end
end

sgs.ai_skill_choice["sfofl_dishou"]    = function(self, choices, data)
	local items = choices:split("+")
	if self.player:getHp() <= 1 and self:getAllPeachNum() > 0 then
		return "losehp"
	end
	if self.player:getHp() > self.player:getHandcardNum() and not self.player:isKongcheng() then
		return "losehp"
	end
	if self:getCardsNum("Peach") > 0 then
		return "losehp"
	end
	return items[math.random(1,#items)]
end

sgs.ai_skill_playerschosen.sfofl_jiaozheng = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	local card = dummyCard()
	card:setSkillName("sfofl_jiaozheng")
	card:deleteLater()
	self.player:setFlags("slashNoDistanceLimit")
	local dummy_use = self:aiUseCard(card, dummy())
	self.player:setFlags("-slashNoDistanceLimit")
	if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do 
			if table.contains(can_choose, p) then
				selected:append(p)
			end
		end
	else
		for _,target in ipairs(can_choose) do
			if self:isEnemy(target) and self.player:canUse(card, target) then
				selected:append(target)
				if selected:length() >= max then break end
			end
		end
	end
    return selected
end

sgs.ai_skill_playerchosen.sfofl_jiaozheng = function(self,targets)
	local slash = dummyCard()
	slash:setSkillName("sfofl_jiaozheng")
	for _,friend in ipairs(sgs.QList2Table(targets))do
		if self:isFriend(friend) then
		for _,enemy in ipairs(self.enemies)do
				if friend:canSlash(enemy, false) and not self:slashProhibit(slash,enemy) and self:getDefenseSlash(enemy)<=2
			and self:slashIsEffective(slash,enemy) and self:isGoodTarget(enemy,self.enemies,slash)
			and enemy:objectName()~=self.player:objectName() then
				return friend
			end
		end
	end
	end
	return nil
end

sgs.ai_playerchosen_intention.sfofl_jiaozheng = -80

sgs.ai_skill_invoke.sfofl_qingjin = function(self,data)
	local target = data:toPlayer()
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash:setSkillName("sfofl_qingjin")
	self.player:setFlags("slashNoDistanceLimit")
	local dummy_use = self:aiUseCard(slash, dummy(true, 99, self.room:getOtherPlayers(target)))
	self.player:setFlags("-slashNoDistanceLimit")
	if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
		if not self:isWeak() or getCardsNum("Jink",target,self.player)==0 then
			return true
		end
	end
	return false
end


sgs.ai_fill_skill.sfofl_fenqi = function(self)
	local Yiguzuoqi = sgs.Sanguosha:cloneCard("sfofl_yiguzuoqi", sgs.Card_NoSuit, 0)
	Yiguzuoqi:deleteLater()
	local dummy_use = self:aiUseCard(Yiguzuoqi, dummy())
	if not dummy_use.card then return end
	return sgs.Card_Parse("#sfofl_fenqi:.::")
end

sgs.ai_skill_use_func["#sfofl_fenqi"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority["sfofl_fenqi"] = 10

sgs.ai_skill_playerchosen.sfofl_mouni = function(self,targets)
	local slash = dummyCard()
	slash:setSkillName("sfofl_mouni")
	self:sort(self.enemies,"handcard",true)
	for _,enemy in ipairs(self.enemies)do
		if self.player:canSlash(enemy, false) and not self:slashProhibit(slash,enemy) and self:slashIsEffective(slash,enemy) and ((self:canHit(enemy, self.player) or (getCardsNum("Jink", enemy, self.player) < getCardsNum("Slash", enemy, self.player))) and (getCardsNum("Slash", enemy, self.player) > 0)) then
			return enemy
		end
	end
	for _,enemy in ipairs(self.enemies)do
		if self.player:canSlash(enemy, false) and not self:slashProhibit(slash,enemy) and self:slashIsEffective(slash,enemy) and (self:isGoodTarget(enemy,self.enemies,slash) and math.random() < 0.4 and enemy:getHandcardNum() > 2) then
			return enemy
		end
	end
		
	return nil
end

sgs.ai_playerchosen_intention.sfofl_mouni = 40

sgs.ai_skill_playerchosen.sfofl_zongfan = function(self,targets)
	for _,p in sgs.list(self.friends_noself)do
		if self:canDraw(p, self.player) then
			return p
		end
	end
	return targets:first()
end
sgs.ai_playerchosen_intention.sfofl_zongfan = -80

sgs.ai_skill_discard.sfofl_zongfan = function(self, discard_num, min_num, optional, include_equip)
	local target = self.player:getTag("sfofl_zongfan"):toPlayer()
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, card:getEffectiveId())
		if #to_discard >= 5 or not self:isFriend(target) then
        	break
		end
	end
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end

function SmartAI:useCardJingxiangGoldenage(card,use)
	local targets = sgs.SPlayerList()
	local value = 1
	local kingdoms = getKingdoms(self.player)
	for _,ff in ipairs(self.friends_noself) do
		if self:canDraw(ff, self.player) and self.player:canUse(card, ff) then
			targets:append(ff)
			value = value + 1
			if targets:length() >= kingdoms then break end
		end
	end
	if targets:length() < kingdoms then
		for _,ff in ipairs(self.friends_noself) do
			if not targets:contains(ff) and self.player:canUse(card, ff) then
				targets:append(ff)
				value = value + 1
				if targets:length() >= kingdoms then break end
			end
		end
	end
	if targets:length() < kingdoms then
		for _,enemy in ipairs(self.enemies) do
			if not self:canDraw(enemy, self.player) and self.player:canUse(card, enemy) then
				targets:append(enemy)
				if targets:length() >= kingdoms then break end
			end
		end
	end
	if targets:length() < kingdoms then
		for _,enemy in ipairs(self.enemies) do
			if self:needKongcheng(enemy) and not targets:contains(enemy) and self.player:canUse(card, enemy) then
				targets:append(enemy)
				value = value - 0.5
				if targets:length() >= kingdoms then break end
			end
		end
	end
	if targets:length() < kingdoms then
		for _,enemy in ipairs(self.enemies) do
			if not targets:contains(enemy) and self.player:canUse(card, enemy) then
				targets:append(enemy)
				value = value - 1
				if targets:length() >= kingdoms then break end
			end
		end
	end
	if targets:length() == kingdoms and value > 0 then
		use.card = card
		use.to = targets
	end
end

sgs.ai_use_value.JingxiangGoldenage = sgs.ai_use_value.ExNihilo
sgs.ai_keep_value.JingxiangGoldenage = sgs.ai_keep_value.ExNihilo
sgs.ai_use_priority.JingxiangGoldenage = sgs.ai_use_priority.ExNihilo
sgs.dynamic_value.benefit.JingxiangGoldenage = true


sgs.ai_skill_playerschosen.sfofl_fujing = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	local card = sgs.Sanguosha:cloneCard("_sfofl_jingxiang_goldenage", sgs.Card_NoSuit, 0)
	card:setSkillName("sfofl_fujing")
	card:deleteLater()
	local dummy_use = self:aiUseCard(card, dummy())
	if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do 
			if table.contains(can_choose, p) then
				selected:append(p)
			end
		end
	else
		local kingdoms = getKingdoms(self.player)
		for _,target in ipairs(can_choose) do
			if self:isFriend(target) and self.player:canUse(card, target) then
				selected:append(target)
				if selected:length() >= kingdoms then break end
			end
		end
		if selected:length() < kingdoms then
			for _,enemy in ipairs(self.enemies) do
				if self.player:canUse(card, enemy) then
					selected:append(enemy)
					if selected:length() >= kingdoms then break end
				end
			end
		end
	end
    return selected
end

sgs.ai_skill_cardask["@sfofl_yongrong_increase"] = function(self,data,pattern,target)
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return "." end
	if self:cantDamageMore(damage.from,target) then return "." end
	return true
end

sgs.ai_skill_cardask["@sfofl_yongrong_decrease"] = function(self,data,pattern,target)
	local damage = data:toDamage()
	if self:damageStruct(damage) and self:needToLoseHp(damage.to, damage.from, damage.card) then
		return "."
	end
	return true
end

function sgs.ai_skill_invoke.sfofl_jushou(self,data)
	local sbdiaochan = self.room:findPlayerBySkillName("lihun")
	if sbdiaochan and sbdiaochan:faceUp() and not self:willSkipPlayPhase(sbdiaochan)
		and (self:isEnemy(sbdiaochan) or (sgs.turncount<=1 and sgs.ai_role[sbdiaochan:objectName()]=="neutral")) then return false end
	if not self.player:faceUp() then return true end
	if self:toTurnOver(self.player,self.room:getAlivePlayers():length(),"sfofl_jushou") then return true end
	for _,friend in ipairs(self.friends)do
		if self:hasSkills("fangzhu|jilve",friend) then return true end
		if friend:faceUp() and friend:hasSkill("junxing") and not self:willSkipPlayPhase(friend)
			and not (friend:isKongcheng() and self:willSkipDrawPhase(friend)) then
			return true
		end
	end
	return self:isWeak()
end
function sgs.ai_skill_invoke.sfofl_jushouTurnOver(self,data)
	if self.player:getHp() < 2 or self.player:getHandcardNum() == 0 then
		return true
	end

	self:sort(self.enemies,"defense")
	if self:getCardsNum("Slash") == 0 then return false end

	local slashs = self:getCards("Slash")
	if #slashs == 0 then return end
	for _, slash in ipairs(slashs) do
		for _,enemy in ipairs(self.enemies) do
			if not self:damageprohibit(enemy) and self:TheWuhun(enemy) >= 0 and self:damageIsEffective(enemy) and self.player:distanceTo(enemy) == 1
				and self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy, self.player)
				and not enemy:hasArmorEffect("SilverLion") and self:hasCrossbowEffect() then
				return true
			end
		end
	end
end

sfofl_tuwei_skill = {}
sfofl_tuwei_skill.name = "sfofl_tuwei"
table.insert(sgs.ai_skills, sfofl_tuwei_skill)
sfofl_tuwei_skill.getTurnUseCard          = function(self, inclusive)
	local ids = sgs.IntList()
	for _, id in sgs.qlist(self.room:getDiscardPile()) do
		if sgs.Sanguosha:getCard(id):isKindOf("EquipCard") then
			ids:append(id)
		end
	end
	if ids:isEmpty() then return end
	for _, p in ipairs(self.friends) do
		if (p:getArmor() and p:getArmor():isKindOf("SilverLion") and p:isWounded()) or (p:getHp() == 1 and self.player:getHandcardNum() > 1) and p:getMark("&sfofl_tuwei+to+#"..self.player:objectName()) == 0 then
			return sgs.Card_Parse("#sfofl_tuwei:.:")
		end
	end
	local handcards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(handcards)
	if handcards[1]:isKindOf("Peach") then return end
	for _, p in ipairs(self.friends) do
		if not p:getArmor() and p:isWounded() and p:getMark("&sfofl_tuwei+to+#"..self.player:objectName()) == 0 then
			return sgs.Card_Parse("#sfofl_tuwei:.:")
		end
	end
	return sgs.Card_Parse("#sfofl_tuwei:.:")
end

sgs.ai_skill_use_func["#sfofl_tuwei"] = function(card, use, self)
	local target
	local card


	if self.player:isKongcheng() then return end

	if not target then
		for _, p in ipairs(self.friends) do
			if (p:getArmor() and p:getArmor():isKindOf("SilverLion")) and p:getMark("&sfofl_tuwei+to+#"..self.player:objectName()) == 0 then
				target = p
				break
			end
		end
	end


	if not target then
		for _, p in ipairs(self.friends) do
			if p:getHp() == 1 and not p:getArmor() and p:getMark("&sfofl_tuwei+to+#"..self.player:objectName()) == 0 then
				target = p
				break
			end
		end
	end

	if not target then
		for _, p in ipairs(self.friends) do
			if not p:getArmor() and p:getMark("&sfofl_tuwei+to+#"..self.player:objectName()) == 0 then
				target = p
				break
			end
		end
	end
	if not target then
		for _, p in ipairs(self.friends) do
			if self:hasSkills(sgs.lose_equip_skill, p) and p:getMark("&sfofl_tuwei+to+#"..self.player:objectName()) == 0 then
				target = p
				break
			end
		end
	end
	if not target then
		for _, p in ipairs(self.enemies) do
			if not self:hasSkills(sgs.lose_equip_skill, p) and p:getMark("&sfofl_tuwei+to+#"..self.player:objectName()) == 0 then
				target = p
				break
			end
		end
	end

	if not target then return end
	if target then
		use.card = sgs.Card_Parse("#sfofl_tuwei:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["sfofl_tuwei"]       = 4
sgs.ai_use_priority["sfofl_tuwei"]    = 4
sgs.ai_card_intention["sfofl_tuwei"]  = -60

sgs.ai_skill_choice["sfofl_tuwei"]    = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items, "draw") and self:isFriend(target) and self:canDraw(target, self.player)  then
		return "draw"
	end
	if table.contains(items, "damage") and self:isFriend(target) and self:needToLoseHp(target, self.player)  then
		return "damage"
	end
	if table.contains(items, "damage") and self:isEnemy(target) and not self:needToLoseHp(target, self.player)  then
		return "damage"
	end

	return "cancel"
end



local sfofl_2_zhanyan_skill = {}
sfofl_2_zhanyan_skill.name = "sfofl_2_zhanyan"
table.insert(sgs.ai_skills, sfofl_2_zhanyan_skill)
sfofl_2_zhanyan_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#sfofl_2_zhanyan") then
		local x = 0
		for _, p in sgs.qlist(self.player:getHandcards()) do
			if p:isRed() then
				x = x + 1
			end
		end
		if x >= 3 then return nil end
		return sgs.Card_Parse("#sfofl_2_zhanyan:.:")
	end
end

sgs.ai_skill_use_func["#sfofl_2_zhanyan"] = function(card, use, self)
	local target = nil
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Fire) and not self:cantbeHurt(enemy) then
            target = enemy
            break
        end
	end
	if target then
	use.card = sgs.Card_Parse("#sfofl_2_zhanyan:%s:")
	if use.to then use.to:append(target) end
	end
end
sgs.ai_card_intention["sfofl_2_zhanyan"] = 80

sgs.ai_skill_choice["sfofl_2_zhanyan"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	local not_red,known, red = 0,0, 0
	local flag = string.format("%s_%s_%s","visible",self.player:objectName(),target:objectName())
	for _,c in sgs.qlist(target:getCards("h"))do
		if self.player:canSeeHandcard(target) or c:hasFlag("visible") or c:hasFlag(flag) then
			known = known+1
			if c:isRed() then
				red = red + 1
			else
				not_red = not_red+1
			end
		end
	end
	if red > 0 then
		return red
	end
	return items[math.random(1, #items)]
end


sgs.ai_fill_skill.sfofl_wusheng = function(self)
	for _,p in sgs.list(patterns())do
		local dc = dummyCard(p)
		if dc and dc:getTypeId()==1 and self:getCardsNum(dc:getClassName())<1
		and self.player:getMark("sfofl_wusheng_guhuo_remove_"..p)<1 then
			local cards = self.player:getCards("h")
			cards = sgs.QList2Table(cards) -- 将列表转换为表
			self:sortByKeepValue(cards) -- 按保留值排序
			dc:setSkillName("sfofl_wusheng")
			for _,h in sgs.list(cards)do
				if h:isRed() then
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

sgs.ai_guhuo_card.sfofl_wusheng = function(self,toname,class_name)
	if self:getCardsNum(class_name)<1 
		and self.player:getMark("sfofl_wusheng_guhuo_remove_"..class_name)<1 then
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards) -- 将列表转换为表
		self:sortByKeepValue(cards) -- 按保留值排序
		local dc = dummyCard(toname)
		if (not dc) then return end
		dc:setSkillName("sfofl_wusheng")
		for _,h in sgs.list(cards)do
			if h:isRed() then
				dc:addSubcard(h)
				if not self.player:isLocked(dc) then
					return dc:toString()
				end
				dc:clearSubcards()
				break
			end
		end
	end
end

sgs.ai_skill_askforyiji.sfofl_yure = function(self,card_ids,tos)
    local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to and id then return to,id end
    for _,target in sgs.list(tos)do
		if self:isFriend(target)
		then return target,card_ids[1] end
	end
    for _,target in sgs.list(tos)do
		return target,card_ids[1]
	end
end
sgs.ai_skill_invoke.sfofl_yure = function(self, data)
	local move = data:toMoveOneTime()
	local card_ids = sgs.IntList()
	for _,card_id in sgs.qlist(move.card_ids) do
		local flag = bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON)
		if flag == sgs.CardMoveReason_S_REASON_DISCARD and self.room:getCardPlace(card_id) == sgs.Player_DiscardPile then
			card_ids:append(card_id)
		end
	end
	if #self.friends_noself == 0 then return false end
	if card_ids:length() > 3 then return true end
	if self:isWeak() and card_ids:length() >= 2 then return true end
	return false
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|sfofl_suiqu"
sgs.ai_skill_choice["sfofl_suiqu"] = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "hp") then
		if (self:hasSkills(sgs.need_maxhp_skill) or self.player:getMaxHp() < 4) and not self:isWeak() then
			return "maxhp"
		end
		return "hp"
	end
	return "maxhp"
end

local sfofl_zainei_skill = {}
sfofl_zainei_skill.name = "sfofl_zainei"
table.insert(sgs.ai_skills, sfofl_zainei_skill)
sfofl_zainei_skill.getTurnUseCard = function(self)
	if #self.friends_noself == 0 then return end
	if not self.player:isKongcheng() and not self.player:hasUsed("#sfofl_zainei") then
		return sgs.Card_Parse("#sfofl_zainei:.:")
	end
end

sgs.ai_skill_use_func["#sfofl_zainei"] = function(card, use, self)
	self:sort(self.friends_noself, "handcard")
	if self.player:hasSkill("sfofl_hanwei") then
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and self.player:distanceTo(friend) > 1 then
				if friend:hasSkills(sgs.cardneed_skill) then
					use.card = sgs.Card_Parse("#sfofl_zainei:.:")
					if use.to then use.to:append(friend) end
					return
				end
				if getCardsNum("Slash", friend, self.player) + self:getCardsNum("Slash") > 1 then
					use.card = sgs.Card_Parse("#sfofl_zainei:.:")
					if use.to then use.to:append(friend) end
					return
				end
			end
		end
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	self:sortByUseValue(cards, true)
	if slashcount > 0 then
		local slash = self:getCard("Slash")
		if slash then
			assert(slash)
			local target
			self.player:setFlags("slashNoDistanceLimit")
			local dummy_use = self:aiUseCard(slash, dummy())
			self.player:setFlags("-slashNoDistanceLimit")
			if dummy_use.card and dummy_use.to then
				if not dummy_use.to:isEmpty() then
					for _, p in sgs.qlist(dummy_use.to) do
						if not self.player:inMyAttackRange(p) then
							target = p
						end
					end
				end
			end
			if target then
				use.card = sgs.Card_Parse("#sfofl_zainei:.:")
				if use.to then use.to:append(target) end
				return
			end
		end
	end
end

sgs.ai_use_priority["sfofl_zainei"] = 10
sgs.ai_use_value["sfofl_zainei"] = 2.45
sgs.ai_card_intention.sfofl_zainei = -80

local sfofl_hanwei_skill = {}
sfofl_hanwei_skill.name = "sfofl_hanwei"
table.insert(sgs.ai_skills, sfofl_hanwei_skill)
sfofl_hanwei_skill.getTurnUseCard = function(self)
	if #self.friends_noself == 0 then return end
	if not self.player:isKongcheng() and not self.player:hasUsed("#sfofl_hanwei") then
		return sgs.Card_Parse("#sfofl_hanwei:.:")
	end
end

sgs.ai_skill_use_func["#sfofl_hanwei"] = function(card, use, self)
	self:sort(self.friends_noself, "handcard")
	local use_cards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, acard in ipairs(cards) do
		if not acard:isDamageCard() then
			table.insert(use_cards, acard:getEffectiveId())
		end
	end
	if #use_cards > 0 then
		for _, friend in ipairs(self.friends_noself) do
			if not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and self.player:distanceTo(friend) <= 1 then
				if friend:hasSkills(sgs.cardneed_skill) then
					use.card = sgs.Card_Parse("#sfofl_hanwei:" .. table.concat(use_cards, "+")..":")
					if use.to then use.to:append(friend) end
					return
				end
				if getCardsNum("Slash", friend, self.player) + self:getCardsNum("Slash") > 1 then
					use.card = sgs.Card_Parse("#sfofl_hanwei:" .. table.concat(use_cards, "+")..":")
					if use.to then use.to:append(friend) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["sfofl_hanwei"] = 10
sgs.ai_use_value["sfofl_hanwei"] = 2.45
sgs.ai_card_intention.sfofl_hanwei = -80




local sfofl_xiongshiAttach_skill = {}
sfofl_xiongshiAttach_skill.name = "sfofl_xiongshiAttach"
table.insert(sgs.ai_skills, sfofl_xiongshiAttach_skill)
sfofl_xiongshiAttach_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasFlag("Forbidsfofl_xiongshi") then return nil end
	
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	if not cards[1] then return nil end
	local card_str = "#sfofl_xiongshi:" .. cards[1]:getEffectiveId() .. ":"
	local skillcard = sgs.Card_Parse(card_str)
	return skillcard
end

sgs.ai_skill_use_func["#sfofl_xiongshi"] = function(card, use, self)
	if self:needBear() or self:getCardsNum("Jink", "h") <= 1 then
		return
	end
	local targets = {}
	for _, friend in ipairs(self.friends) do
		if friend:hasSkill("sfofl_xiongshi") then
			if not friend:hasFlag("sfofl_xiongshiInvoked") then
				table.insert(targets, friend)
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	elseif self:getCardsNum("Slash", "he") >= 2 then --黄天对方
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasSkill("sfofl_xiongshi") then
				if not enemy:hasFlag("sfofl_xiongshiInvoked") then
					if  enemy:hasSkill("sfofl_defeng") then 
						table.insert(targets, enemy)
					end
				end
			end
		end
		if #targets > 0 then
			
			self:sort(targets, "defense", true)
			for _, enemy in ipairs(targets) do
				if self.player:canSlash(enemy, nil, false, 0) and enemy:hasSkill("sfofl_defeng") then
					use.card = card
					if use.to then
						use.to:append(enemy)
					end
					break
				end
			end
			
		end
	end
end

sgs.ai_card_intention.sfofl_xiongshi = function(self, card, from, tos)
	if tos[1]:isKongcheng() and self:needKongcheng(tos[1],true) then
	else
		sgs.updateIntention(from, tos[1], -80)
	end
end

sgs.ai_use_priority.sfofl_xiongshi = 10
sgs.ai_use_value.sfofl_xiongshi = 8.5

sgs.ai_ajustdamage_from.sfofl_defeng = function(self, from, to, card, nature)
	local ids = sgs.IntList()
	for _,key in sgs.list(from:getPileNames())do
		for _,id in sgs.list(from:getPile(key))do
			ids:append(id)
		end
	end
	if not ids:isEmpty() and not beFriend(to, from)
	then
		return 1
	end
end
sgs.ai_ajustdamage_to.sfofl_defeng = function(self, from, to, card, nature)
	local ids = sgs.IntList()
	for _,key in sgs.list(to:getPileNames())do
		for _,id in sgs.list(to:getPile(key))do
			ids:append(id)
		end
	end
	if not ids:isEmpty() and not beFriend(to, from)
	then
		return 1
	end
end
sgs.ai_skill_askforag.sfofl_defeng = function(self,card_ids)
	local damage = self.room:getTag("sfofl_defeng"):toDamage()
	if self.player:hasSkill("sfofl_defeng") then
		if damage.to and self:isFriend(damage.to) then
			if not self:damageStruct(damage) or self:cantDamageMore(self.player, damage.to) then
				for _,id in sgs.list(card_ids)do
					return id
				end
			end
		else
			if self:damageStruct(damage) and not self:cantDamageMore(self.player, damage.to) then
				for _,id in sgs.list(card_ids)do
					return id
				end
			end
		end
	else
		if damage.to and self:isFriend(damage.to) then
			if not self:damageStruct(damage) or self:cantDamageMore(self.player, damage.to) then
				for _,id in sgs.list(card_ids)do
					return id
				end
			end
		else
			if self:damageStruct(damage) and not self:cantDamageMore(self.player, damage.to) then
				for _,id in sgs.list(card_ids)do
					return id
				end
			end
		end
	end
		
	return -1
end

sgs.ai_skill_use["@@sfofl_deshi"]=function(self,prompt)
	self:sort(self.enemies,"defense")
	if self:needBear() then return "." end

	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash:setSkillName("sfofl_deshi")
	slash:addSubcards(self.player:getHandcards())
	local tos = {}
	for _,target in sgs.list(self.enemies)do
		if not self:slashProhibit(slash,target) and
		self:isGoodTarget(target,self.enemies,slash) and
		self:slashIsEffective(slash,target) then
			if self.player:getHandcardNum() >= target:getHp() and not self:cantDamageMore(self.player, target) and self:canHit(target,self.player,true) then
				table.insert(tos,target:objectName())
				if #tos >= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,slash) then
					break
				end
			end
		end
	end
	if #tos > 0 then
		local to_give = {}
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		for _,c in ipairs(handcards) do
			table.insert(to_give, c:getEffectiveId())
		end
		return "#sfofl_deshi:"..table.concat(to_give, "+")..":->"..table.concat(tos,"+")
	end
	

	return "."
end


sgs.ai_ajustdamage_from.sfofl_deshi = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:getSkillName() == "sfofl_deshi"
	then
		return card:subcardsLength() - 1
	end
end

sgs.ai_skill_playerchosen.sfofl_xianjiang = function(self,targets)
	return self:findPlayerToDraw(false,2)
end
sgs.ai_playerchosen_intention.sfofl_xianjiang = -80

sgs.ai_skill_choice["sfofl_tianpan"] = function(self, choices, data)
	local items = choices:split("+")
	local judge = data:toJudge()
	if judge.card:getSuit() == sgs.Card_Spade then
		if table.contains(items, "hp") then
			if (self:hasSkills(sgs.need_maxhp_skill) or self.player:getMaxHp() < 4) and not self:isWeak() then
				return "gainmaxhp"
			end
			return "gainhp"
		end
	else
		return sgs.ai_skill_choice.benghuai(self, choices, data)
	end
	return "maxhp"
end

sgs.ai_skill_invoke.sfofl_gaiming = function(self,data)
	local judge = data:toJudge()
	if not judge:isGood() then
	return true end
	return false
end

sgs.ai_ajustdamage_from.sfofl_tunquan = function(self, from, to, card, nature)
	if from:getMark("sfofl_tunquan-Clear") > 0 and from:getMark("sfofl_tunquan_damage-Clear") == 0 	then
		return 1
	end
end


local sfofl_qianjun_skill = {}
sfofl_qianjun_skill.name = "sfofl_qianjun"
table.insert(sgs.ai_skills,sfofl_qianjun_skill)
sfofl_qianjun_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_qianjun:.:")
end

sgs.ai_skill_use_func["#sfofl_qianjun"] = function(card,use,self)
	if self:isWeak() then
		for _,friend in ipairs(self.friends_noself)do
			if friend:hasSkills(sgs.need_equip_skill) then
				use.card = card
				use.to:append(friend)
				return
			end
		end
		for _,friend in ipairs(self.friends_noself)do
			if not hasManjuanEffect(friend) then
				use.card = card
				use.to:append(friend)
				return
			end
		end
		self:sort(self.friends)
		for _,target in sgs.qlist(self.room:getOtherPlayers(self.player))do
			use.card = card
			use.to:append(target)
			return
		end
	end
	if not self.player:isWounded() then
		local killer
		self:sort(self.friends_noself)
		for _,target in sgs.qlist(self.room:getOtherPlayers(self.player))do
			local canUse = false
			for _,friend in ipairs(self.friends_noself)do
				if friend:inMyAttackRange(target) and self:damageIsEffective(target,nil,friend)
					and not self:needToLoseHp(target,friend) and self:isWeak(target) then
					canUse = true
					killer = friend
					break
				end
			end
			if canUse then
				use.card = card
				use.to:append(killer)
				return
			end
		end
	end

	if #self.friends_noself==0 then return end
	if self.player:getEquips():length()>2 or self.player:getEquips():length()>#self.enemies and sgs.turncount>2 then
		local function cmp_AttackRange(a,b)
			local ar_a = a:getAttackRange()
			local ar_b = b:getAttackRange()
			if ar_a==ar_b then
				return sgs.getDefense(a)>sgs.getDefense(b)
			else
				return ar_a>ar_b
			end
		end
		table.sort(self.friends_noself,cmp_AttackRange)
		use.card = card
		use.to:append(self.friends_noself[1])
	end
end

sgs.ai_use_priority.sfofl_qianjun = 4.9
sgs.ai_card_intention.sfofl_qianjun = function(self,card,from,tos)
	if not from:isWounded() then sgs.updateIntentions(from,tos,-10) end
end



sgs.ai_ajustdamage_from.sfofl_juedian = function(self, from, to, card, nature)
	if card and card:hasFlag("sfofl_juedian") then
		return 1
	end
end


sgs.ai_skill_choice["sfofl_juedian"] = function(self, choices, data)
	local target = data:toDamage().to
	local items = choices:split("+")
	if table.contains(items, "beishui") and self.player:getHp() > 1 and self.player:getMaxHp() > 1 then
		if self:objectiveLevel(target) > 3 and not self:cantbeHurt(target) and not self:cantDamageMore(self.player, target) then
			local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
			duel:deleteLater()
			duel:setSkillName("sfofl_juedian")
			local dummy_use = self:aiUseCard(duel, dummy(true, 0, self.room:getOtherPlayers(target)))
			if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
				return "beishui"
			end
		end
		if self.player:getMark("sfofl_nitian-Clear") > 0 and self:isEnemy(target) and not self:cantDamageMore(self.player, target) then
			return "beishui"
		end
	end
	if table.contains(items, "hp") then
		if (self:hasSkills(sgs.need_maxhp_skill) or self.player:getMaxHp() < 4) and not self:isWeak() then
			return "maxhp"
		end
		return "hp"
	end
	return "maxhp"
end


local sfofl_nitian_skill = {}
sfofl_nitian_skill.name = "sfofl_nitian"
table.insert(sgs.ai_skills,sfofl_nitian_skill)
sfofl_nitian_skill.getTurnUseCard = function(self)
	if #self.enemies<=0 then return end
	if self:needBear() then return end
	for _,enemy in sgs.list(self.enemies)do
		if self:damageMinusHp(enemy,1)>0
		or enemy:getHp()<3 and self:damageMinusHp(enemy,0)>0 and enemy:getHandcardNum()>0
		then
			return sgs.Card_Parse("#sfofl_nitian:.:")
		end
	end
	if self.role=="renegade" or self.role=="lord" then return end
	if (#self.friends>1) or (#self.enemies==1 and sgs.turncount>1) then
		if self:getAllPeachNum()==0 and self.player:getHp()==1 then
			return sgs.Card_Parse("#sfofl_nitian:.:")
		end
		if self:isWeak() and self.role=="rebel" and self.player:inMyAttackRange(self.room:getLord()) and self:hasCrossbowEffect() then
			return sgs.Card_Parse("#sfofl_nitian:.:")
		end
	end
end

sgs.ai_skill_use_func["#sfofl_nitian"] = function(card,use,self)
	use.card = card
	return
end

sgs.ai_use_priority["sfofl_nitian"] = 10

sgs.ai_skill_invoke.sfofl_dafu = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		if target:isKongcheng() then return true end
		if (target:getHandcardNum() >= 3 or self:isWeak(target)) then return false end
		if self:needToLoseHp(target,self.player) then
			return true
		end
	end
	if target:isKongcheng() then return false end
	if self.player:hasSkill("sfofl_jipin") and target:getHandcardNum() + 1 >= self.player:getHandcardNum() then return true end
	if math.random() < 0.5 then return true end
	return false
end

sgs.ai_skill_invoke.sfofl_jipin = function(self, data)
	local damage = data:toDamage()
	return self:doDisCard(damage.to, "h", true)
end
sgs.ai_skill_playerchosen.sfofl_jipin = function(self, targets)
	local cards = {}
	table.insert(cards,sgs.Sanguosha:getCard(self.player:getMark("sfofl_jipin")))
	local card, friend = self:getCardNeedPlayer(cards)
	if card and friend then
		if targets:contains(friend) then 
			return friend
		end
	end
	if self:getOverflow() > 0 then
		return self:findPlayerToDraw(false, 1)
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_jipin = -80

sfofl_jukou_skill = {}
sfofl_jukou_skill.name = "sfofl_jukou"
table.insert(sgs.ai_skills,sfofl_jukou_skill)
sfofl_jukou_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_jukou:.:")
end

sgs.ai_skill_use_func["#sfofl_jukou"] = function(card,use,self)
	for _,p in sgs.list(sgs.QList2Table(self.room:getAllPlayers()))do
		local ids = sgs.IntList()
		for _,key in sgs.list(p:getPileNames())do
			for _,id in sgs.list(p:getPile(key))do
				ids:append(id)
			end
		end
		if not ids:isEmpty() then 
			if self:isFriend(p) and p:hasSkill("sfofl_defeng") or self:isEnemy(p) then
				use.card = card
				use.to:append(p)
				return
			end
		end
	end
	local to = self:findPlayerToDraw(false)
	if to then 
		sgs.ai_use_priority["sfofl_jukou"] = 0
		use.card = card
		use.to:append(to)
		return
	end
end
sgs.ai_use_priority["sfofl_jukou"] = 10

sgs.ai_skill_choice.sfofl_jukou = function(self, choices, data)
	local choice1 = getChoice(choices, "draw")
	local choice2 = getChoice(choices, "obtain")
	if choice2 then return choice2 end
	local items = choices:split("+")
	if choice1 then return choice1 end
	return items[1]
end

local sfofl_shupan_skill = {}
sfofl_shupan_skill.name = "sfofl_shupan"
table.insert(sgs.ai_skills,sfofl_shupan_skill)
sfofl_shupan_skill.getTurnUseCard = function(self)
	if self.room:getAlivePlayers():length()<3 then
		return
	end
	if #self.enemies<1 then	return end
	return sgs.Card_Parse("#sfofl_shupan:.:")
end

sgs.ai_skill_use_func["#sfofl_shupan"] = function(card,use,self)
	local first,second
	local max = 0
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(targets,"handcard", true)
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
			first = p
			break
		end
	end
	if max > 3 then
		self:sort(self.enemies,"defense")
		for _,enemy in sgs.list(self.enemies)do
			if (self:isGoodTarget(enemy,self.enemies) or hasManjuanEffect(enemy)) and first:objectName() ~= enemy:objectName()  then
				second = enemy
				break
			end
		end
	end
	if first and second then
		use.card = card
		use.to:append(second)
		use.to:append(first)
		return
	end
	if self:isWeak() then
		local min = 999
		local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
		self:sort(targets,"handcard")
		for _,p in sgs.list(targets)do
			local x = 0
			local kc = getKnownCards(p,self.player)
			for _,c in sgs.list(kc)do
				if c:isDamageCard() then
					x = x + 1
				end
			end
			x = x + p:getHandcardNum()/3
			if x < min then
				min = x
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
			if x == min then
				first = p
				break
			end
		end
		local to = self:findPlayerToDraw(false, 3)
		if to and first:objectName() ~= to:objectName() then
			use.card = card
			use.to:append(to)
			use.to:append(first)
		end
	end
end

sgs.ai_use_value.sfofl_shupan = 8.5
sgs.ai_use_priority.sfofl_shupan = 4

sgs.ai_ajustdamage_from.sfofl_yingzhan = function(self, from, to, card, nature)
	if nature ~= "N" then
		return 1
	end
end
sgs.ai_ajustdamage_to.sfofl_yingzhan = function(self, from, to, card, nature)
	if nature ~= "N" then
		return 1
	end
end

sgs.ai_skill_use["@@sfofl_cuiji"]=function(self,prompt)
	self:sort(self.enemies,"defense")
	local slash = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash:setSkillName("sfofl_cuiji")
	local current = self.room:getCurrent()
	if not current or current:isDead() then return "." end
	local dummy_use = self:aiUseCard(slash, dummy(true))
	if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(current) then
		local cards = self.player:getCards("h")
		cards = self:sortByKeepValue(cards,nil,true)
		for _,c in sgs.list(cards)do
			if self:getKeepValue(c)>3 then continue end
			if (self.player:hasSkill("sfofl_kunjun") and (#cards - slash:subcardsLength() > current:getHandcardNum())) or (slash:subcardsLength()<#cards/2) then
				slash:addSubcard(c)
			end
		end
		if slash:subcardsLength()<1 and #cards>1	then
			slash:addSubcard(cards[1])
		end
		return slash:toString() ..":->"..current:objectName()
	end
	return "."
end

sgs.ai_ajustdamage_from.sfofl_paoxi = function(self, from, to, card, nature)
	if from:getMark("sfofl_paoxi+2_num-Clear") > 0 then
		return 1
	end
end
sgs.ai_ajustdamage_to.sfofl_paoxi = function(self, from, to, card, nature)
	if to:getMark("sfofl_paoxi+1_num-Clear") > 0 then
		return 1
	end
end

addAiSkills("sfofl_houying").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs = dummyCard()
	fs:setSkillName("sfofl_houying")
  	for _,c in sgs.list(cards)do
		if self:getKeepValue(c)>3 or not c:isBlack()
		or #ids >= 2 then continue end
		table.insert(ids,c:getEffectiveId())
	end
	local dummy_use = self:aiUseCard(fs)
	if fs:isAvailable(self.player)
	and dummy_use.card
	and dummy_use.to
	and #ids>1
  	then
		self.olcb_to = dummy_use.to
		return sgs.Card_Parse("#sfofl_houying:".. table.concat(ids,"+")..":")
	end
end

sgs.ai_skill_use_func["#sfofl_houying"] = function(card,use,self)
	use.card = card
	use.to = self.olcb_to
end

sgs.ai_use_value.sfofl_houying = 9.4
sgs.ai_use_priority.sfofl_houying = 2.8

sgs.ai_ajustdamage_from.sfofl_wuxiao = function(self, from, to, card, nature)
	if from:getMark("sfofl_wuxiao+2_num-Clear") > 0 then
		return 1
	end
end
sgs.ai_ajustdamage_to.sfofl_wuxiao = function(self, from, to, card, nature)
	if to:getMark("sfofl_wuxiao+1_num-Clear") > 0 then
		return 1
	end
end

addAiSkills("sfofl_qianhu").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs = dummyCard("duel")
	fs:setSkillName("sfofl_qianhu")
  	for _,c in sgs.list(cards)do
		if self:getKeepValue(c)>3 or not c:isRed()
		or #ids >= 2 then continue end
		table.insert(ids,c:getEffectiveId())
	end
	local dummy_use = self:aiUseCard(fs)
	if fs:isAvailable(self.player)
	and dummy_use.card
	and dummy_use.to
	and #ids>1
  	then
		self.olcb_to = dummy_use.to
		return sgs.Card_Parse("#sfofl_qianhu:".. table.concat(ids,"+")..":")
	end
end

sgs.ai_skill_use_func["#sfofl_qianhu"] = function(card,use,self)
	use.card = card
	use.to = self.olcb_to
end

sgs.ai_use_value.sfofl_qianhu = 9.4
sgs.ai_use_priority.sfofl_qianhu = 2.8


sgs.ai_use_revises.sfofl_sanshou = function(self,card)
	if self.player:getPhase() < sgs.Player_Finish and self.player:getMark("sfofl_shenzhangliang-Clear") == 0 and self:getOverflow() < 1
	then
		if card:isKindOf("TrickCard") and (card:targetFixed() and not card:isDamageCard() or card:canRecast() or ("snatch|collateral"):match(card:objectName())) or card:isKindOf("Slash")
		then return end
		return false
	end
end

sgs.ai_skill_invoke.sfofl_mingdao = true

sgs.ai_skill_choice.sfofl_YellowTurbanRebels = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1, #items)]
end

sgs.ai_skill_invoke.sfofl_zhongfu = true

sgs.ai_choicemade_filter.cardResponded["@sfofl_zhongfu"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local target = self.room:findPlayerByObjectName(promptlist[4])
		if target then
			sgs.updateIntention(player, target, -40)
		end
	end
end

sgs.ai_skill_cardask["@sfofl_zhongfu"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) and target:hasSkill("sfofl_dangjing") then
		local max = 0
		for _, p in sgs.qlist(self.room:getAllPlayers()) do
			if p:getEquips():length() > max then
				max = p:getEquips():length()
			end
		end
		if target:getEquips():length() >= max then
			local cards = self.player:getCards("he")
			cards = sgs.QList2Table(cards)
			self:sortByKeepValue(cards)
			local suit
			for _, mark in sgs.list(target:getMarkNames()) do
				if string.find(mark, "sfofl_zhongfu") and target:getMark(mark) > 0 then
					suit = mark:split("+")[3]:split("_")[1]
				end
			end
			if suit then
				for _,h in sgs.list(cards)do
					if h:getSuitString() == suit then
						return h:getEffectiveId()
					end
				end
			end
		end
		return true
	end
	if self:doDisCard(self.player, "he", true) then return true end
	return "."
end

sgs.ai_skill_playerchosen.sfofl_dangjing = function(self,targets)
	return self:findPlayerToDamage(1,self.player,sgs.DamageStruct_Thunder,targets,true, 1)[1]
end

sgs.ai_playerchosen_intention.sfofl_dangjing = sgs.ai_playerchosen_intention.leiji
sgs.ai_skill_invoke.sfofl_dangjing = true


sgs.ai_skill_invoke.sfofl_jijun = function(self,data)
	local tr = data:toString()
	if tr == "obtain" and not self.player:hasSkill("sfofl_fangtong") then return false end
	return true
end


local function fangtongca(tasum, card_ids)
	local sum = 0
	local usecards = {}
	if card_ids:length() > 30 then
		for _,id in sgs.qlist(card_ids) do
			local card = sgs.Sanguosha:getCard(id)
			if (card:getNumber() + sum) <= tasum then
				table.insert(usecards,id)
				sum = sum + card:getNumber()
			end
		end
	else
		local n = card_ids:length()
		local allcards = {}
		for _,id in sgs.qlist(card_ids) do
			table.insert(allcards, id)
		end
		for i = 1, 2^n, 1 do
			sum = 0
			usecards = {}
			for j = 1, n, 1 do
				if bit32.band(i,(2^j)) ~= 0 then
					table.insert(usecards,allcards[j])
				end
			end
			for _,id in ipairs(usecards) do
				sum = sum + sgs.Sanguosha:getCard(id):getNumber()
			end
			if sum == tasum then break end
		end
	end

	if sum == tasum then 
		return usecards
	else
		return {}
	end
end

sgs.ai_skill_cardask["@sfofl_fangtong-invoke"] = function(self, data)
	if self.player:isNude() then return "." end
	local card_ids = self.player:getPile("sfofl_fang")
	local allcards = {}
	local sum = 0
	for _,id in sgs.qlist(card_ids) do
		sum = sum + sgs.Sanguosha:getCard(id):getNumber()
		table.insert(allcards,id)
	end
	if sum < 23 then return "." end
	self:sort(self.enemies, "defense")
	local target = nil
	for _,enemy in ipairs(self.enemies) do
		if enemy:isAlive() and not self:cantDamageMore(self.player, enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) then 
			target = enemy
			break
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if enemy:isAlive() and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) then 
				target = enemy
				break
			end
		end
	end
	if not target then
		for _,enemy in ipairs(self.enemies) do
			if enemy:isAlive() then 
				target = enemy
				break
			end
		end
	end

	if not target then return "." end
	self.fangtong_to = target
	local use_card
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local usecards = {}
	for _,card in ipairs(cards) do
		sum = 0
		local tem = 36 - card:getNumber()
		usecards = fangtongca(tem,card_ids)
		if #usecards > 0 then
			table.insert(usecards,card:getEffectiveId())
		end
		for _,c in ipairs(usecards) do
			sum = sum + sgs.Sanguosha:getCard(c):getNumber()
		end
		if sum == 36 then use_card = card break end
	end
	if sum ~= 36 then return "." end
	if use_card then
		return use_card:getEffectiveId()
	end
	return "."
end
sgs.ai_skill_use["@@sfofl_fangtong"] = function(self, prompt)
	local card_ids = self.player:getPile("sfofl_fang")
	local allcards = {}
	local sum = 0
	self:sort(self.enemies, "defense")
	local target = self.fangtong_to
	if not target then return "." end

	local usecards = {}
	local tem = 36 - self.player:property("sfofl_fangtong"):toInt()
	usecards = fangtongca(tem,card_ids)
	for _,c in ipairs(usecards) do
		sum = sum + sgs.Sanguosha:getCard(c):getNumber()
	end
	sum = sum + self.player:property("sfofl_fangtong"):toInt()
	if sum ~= 36 then return "." end
	local card_str = "#sfofl_fangtong:"..table.concat(usecards, "+")..":->"..target:objectName()
	return card_str
end

sgs.ai_use_revises.sfofl_fangtong = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5 and self.player:hasSkill("sfofl_jijun")
	then use.card = card return true end
end

local sfofl_zhouyuan_skill = {}
sfofl_zhouyuan_skill.name = "sfofl_zhouyuan"
table.insert(sgs.ai_skills, sfofl_zhouyuan_skill)
sfofl_zhouyuan_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_zhouyuan:.:")
end

sgs.ai_skill_use_func["#sfofl_zhouyuan"] = function(card, use, self)
	self:sort(self.enemies,"handcard",true)
	local red, black = {}, {}
	local use_cards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, acard in ipairs(cards) do
		if acard:isRed() then
			table.insert(red, acard:getEffectiveId())
		elseif acard:isBlack() then
			table.insert(black, acard:getEffectiveId())
		end
	end
	if #red > #black then
		use_cards = black
	elseif #black > #red then
		use_cards = red
	else
		use_cards = black
	end
	if #use_cards == 0 then
		if #red > #black then
			use_cards = red
		elseif #black > #red then
			use_cards = black
		else
			use_cards = red
		end
	end
	if #use_cards == 0 then return end
	for _,enemy in sgs.list(self.enemies)do
		if not self:needKongcheng(enemy) then
			if self:damageMinusHp(enemy,1)>0
			or enemy:getHp()<3 and self:damageMinusHp(enemy,0)>0 and enemy:getHandcardNum()>0
			or enemy:getHandcardNum()>=enemy:getHp() and enemy:getHp()>2 and self:damageMinusHp(enemy,0)>=-1
			or enemy:getHandcardNum()-enemy:getHp()>2
			then
				use.card = sgs.Card_Parse("#sfofl_zhouyuan:".. table.concat(use_cards, "+")..":")
				use.to:append(enemy)
				return
			end
		end
	end
	for _,enemy in sgs.list(self.enemies)do
		if enemy:getHandcardNum()>=enemy:getHp()
		then
			use.card = sgs.Card_Parse("#sfofl_zhouyuan:".. table.concat(use_cards, "+")..":")
			use.to:append(enemy)
			return
		end
	end
end

sgs.ai_use_value.sfofl_zhouyuan = 9.5
sgs.ai_use_priority.sfofl_zhouyuan = 3.5
sgs.ai_card_intention.sfofl_zhouyuan = 30

local sfofl_zhaobing_skill = {}
sfofl_zhaobing_skill.name = "sfofl_zhaobing"
table.insert(sgs.ai_skills,sfofl_zhaobing_skill)
sfofl_zhaobing_skill.getTurnUseCard = function(self,inclusive)
	local cards = {}
	for _,id in sgs.qlist(self.player:getPile("sfofl_zhoubing")) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	for _,enemy in ipairs(self.enemies)do
		if not enemy:getPile("sfofl_zhoubing"):isEmpty() then
			for _,id in sgs.qlist(enemy:getPile("sfofl_zhoubing")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end
	end
	self:sortByUseValue(cards,true)

	if cards[1] and cards[1]:isAvailable(self.player) then
		local suit = cards[1]:getSuitString()
		local number = cards[1]:getNumberString()
		local card_id = cards[1]:getEffectiveId()
		return sgs.Card_Parse((cards[1]:objectName()..":sfofl_zhaobing[%s:%s]=%d"):format(suit,number,card_id))
	end
end
sgs.ai_use_priority.sfofl_zhaobing = 5
sgs.ai_card_priority.sfofl_zhaobing = function(self,card)
	if card:getSkillName()=="sfofl_zhaobing"
	then return 5 end
end



sgs.ai_ajustdamage_from._sfofl_YellowTurbanRebels0 = function(self, from, to, card, nature)
	if nature == "T" and from:getTag("sfofl_YellowTurbanRebels0"):toBool() then
		return 1
	end
end
sgs.ai_ajustdamage_to._sfofl_YellowTurbanRebels0 = function(self, from, to, card, nature)
	if nature == "T" and to:getTag("sfofl_YellowTurbanRebels0"):toBool()  then
		return 1
	end
end
sgs.ai_can_damagehp.sfofl_YellowTurbanRebels3 = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end

sgs.ai_skill_playerschosen.sfofl_shice = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	local card = sgs.Sanguosha:cloneCard("FireAttack", sgs.Card_NoSuit, 0)
	card:setSkillName("sfofl_shice")
	card:deleteLater()
	local dummy_use = self:aiUseCard(card, dummy())
	if dummy_use.card and dummy_use.to and not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do 
			if table.contains(can_choose, p) then
				selected:append(p)
			end
		end
	else
		for _,target in ipairs(can_choose) do
			if self:isEnemy(target) and self.player:canUse(card, target) then
				selected:append(target)
				if selected:length() >= max then break end
			end
		end
	end
    return selected
end

sgs.ai_skill_invoke.sfofl_shice = function(self,data)
	local use = data:toCardUse()
	local target = use.to:first()
	if target then
		if self:doDisCard(target, "e") then
			local dummy_use = self:aiUseCard(use.card, dummy(true, 0, self.room:getOtherPlayers(target)))
			if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_choice.sfofl_podai = function(self, choices, data)
    local target = data:toPlayer()
    local items = choices:split("+")
	local choice1 = getChoice(choices, "skill")
	local choice2 = getChoice(choices, "damage")
	if choice1 and self:isEnemy(target) then
		return choice1
	end
	if choice2 then
		if self:isFriend(target) and (self:needToLoseHp(target, self.player) or not self:damageIsEffective(target,"F",self.player)) then
			return choice2 
		end
		if self:isEnemy(target) and self:damageIsEffective(target,"F",self.player) and self:isGoodTarget(target,self.enemies) then
			return choice2 
		end
		if target:hasSkill("sfofl_shice") and target:getChangeSkillState("sfofl_shice") <= 1 and target:objectName() == self.player:objectName() then
			return choice2
		end
	end
    return "cancel"
end

sgs.ai_skill_choice.sfofl_podaiskill = function(self,choices)
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

sgs.ai_choicemade_filter.skillChoice["sfofl_podai"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = self.room:getCurrent()
	if choice == "damage" then
		if self:needToLoseHp(current,player) or not self:damageIsEffective(current,"F",player) then return end
		sgs.updateIntention(player, current, 40)
	end
end

sgs.ai_choicemade_filter.skillChoice["sfofl_podaiskill"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = self.room:getCurrent()
	if not string.find(sgs.bad_skills, choice) then
		sgs.updateIntention(player, current, 80)
	end
end





sgs.ai_skill_playerschosen.sfofl_zhengan = function(self, targets, max, min)
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

sgs.ai_skill_choice["sfofl_zhengan_basic"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then return items[1] end
    if self.player:getLostHp() > 1 then return "peach" end
    table.removeOne(items, "cancel")
    for _,pattern in ipairs(items) do
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
		card:deleteLater()
		local dummy_use = self:aiUseCard(card, dummy())
        if dummy_use.to and dummy_use.to:length() > 0 then
            return pattern
        end
    end
    return "cancel"
end

sgs.ai_skill_use["@@sfofl_zhengan"] = function(self, prompt)
	local p_choices = {}
	for _,dc in sgs.list(PatternsCard("BasicCard",true))do
		dc:setSkillName("sfofl_zhengan_basic")
		if dc:isAvailable(self.player)	then table.insert(p_choices,dc:objectName()) end
	end
	if sgs.ai_skill_choice["sfofl_zhengan_basic"](self, table.concat(p_choices,"+")) ~= "cancel" then
		return "#sfofl_zhengan_basicCard:.:"
	end
	return "."
end


sgs.ai_skill_use["@@sfofl_zhengan_basic"] = function(self, prompt)
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	pattern = self.player:getMark("sfofl_zhengan_basic_id")
	pattern = sgs.Sanguosha:getEngineCard(pattern)
	pattern = sgs.Sanguosha:cloneCard(pattern:objectName())
	pattern:deleteLater()
	pattern:setSkillName("sfofl_zhengan_basic")
	
    if pattern:objectName() == "peach" or pattern:objectName() == "analeptic" then
        return pattern:toString().."->"..self.player:objectName()
    end
	local dummy_use = self:aiUseCard(pattern, dummy())
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return pattern:toString().."->"..table.concat(tos, "+")
    end
    return "."
end


local sfofl_weizhu_skill = {}
sfofl_weizhu_skill.name = "sfofl_weizhu"
table.insert(sgs.ai_skills,sfofl_weizhu_skill)
sfofl_weizhu_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_weizhu:.:")
end

sgs.ai_skill_use_func["#sfofl_weizhu"] = function(card,use,self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	if self.player:getHp()<3 then
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _,zcard in sgs.list(self.player:getCards("he"))do
			if not isCard("Peach",zcard,self.player)
			then
				local shouldUse = true
				if isCard("Slash",zcard,self.player)
				and not use_slash
				then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.list(dummy_use.to)do
								if p:getHp()<=1 then
									shouldUse = false
									if self.player:distanceTo(p)>1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length()>1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId()==sgs.Card_TypeTrick then
					if self:aiUseCard(zcard).card then shouldUse = false end
				end
				if zcard:getTypeId()==sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					if self:aiUseCard(zcard).card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId()==keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp()<2 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards,zcard:getId()) end
			end
		end
	end
	if #unpreferedCards<1 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,card)
				then
					if self:aiUseCard(card).card then
						will_use = true
						use_slash_num = use_slash_num+1
					end
				end
				if not will_use then table.insert(unpreferedCards,card:getId()) end
			end
		end
		local num = self:getCardsNum("Jink")-1
		if self.player:getArmor() then num = num+1 end
		if num>0 then
			for _,card in ipairs(cards)do
				if card:isKindOf("Jink") and num>0 then
					table.insert(unpreferedCards,card:getId())
					num = num-1
				end
			end
		end
		for _,card in ipairs(cards)do
			if card:isKindOf("Weapon") and self.player:getHandcardNum()<3
			or self:getSameEquip(card,self.player)
			or card:isKindOf("OffensiveHorse")
			or card:isKindOf("AmazingGrace")
			then table.insert(unpreferedCards,card:getId())
			elseif card:getTypeId()==sgs.Card_TypeTrick then
				if not self:aiUseCard(card).card then table.insert(unpreferedCards,card:getId()) end
			end
		end
	end

	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		use.card = sgs.Card_Parse("#sfofl_weizhu:"..table.concat(use_cards,"+")..":")
	end
end

sgs.ai_use_value.sfofl_weizhu = 9
sgs.ai_use_priority.sfofl_weizhu = 2.61
sgs.dynamic_value.benefit.sfofl_weizhu = true

sgs.ai_skill_playerschosen.sfofl_weizhu = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if self:isFriend(target) and self:canDraw(target, self.player) then
			selected:append(target)
			if selected:length() >= max then break end
		end
	end
    return selected
end


sgs.ai_fill_skill.sfofl_zequan = function(self)
	for _,pn in sgs.list(patterns())do
		if self.player:getMark("sfofl_zequan_guhuo_remove_"..pn)>0 then continue end
		local dc = dummyCard(pn)
		if dc and dc:isNDTrick() and self:getCardsNum(dc:getClassName())<1 then
			local cards = self.player:getCards("h")
			cards = sgs.QList2Table(cards) -- 将列表转换为表
			self:sortByKeepValue(cards) -- 按保留值排序
			dc:setSkillName("sfofl_zequan")
			for _,h in sgs.list(cards)do
				if h:isKindOf("EquipCard") then
					dc:addSubcard(h)
					if dc:isAvailable(self.player) then
						local dummy_use = self:aiUseCard(dc, dummy())
						if dummy_use.card and dummy_use.to and dummy_use.to:length() > 0 then
							local useto = sgs.SPlayerList()
							for _,to in sgs.qlist(dummy_use.to) do
								if to:getHp() >= self.player:getHp() then
									useto:append(to)
								end
							end
							if useto:length() > 0 then
								dummy_use.to = useto
								self.sfofl_zequanUse = dummy_use
								sgs.ai_use_priority.sfofl_zequan = sgs.ai_use_priority[dc:getClassName()]
								return sgs.Card_Parse("#sfofl_zequan:".. h:getEffectiveId() ..":"..pn)
							end
						end
					end
					dc:clearSubcards()
				end
			end
		end
	end
end
sgs.ai_skill_use_func["#sfofl_zequan"] = function(card,use,self)
	local ut = self.sfofl_zequanUse
	if ut.card then
		use.card = card
		use.to = ut.to
	end
end

sgs.ai_use_value.sfofl_zequan = 3.4
sgs.ai_use_priority.sfofl_zequan = 9.2


local sfofl_cheji_skill = {}
sfofl_cheji_skill.name = "sfofl_cheji"
table.insert(sgs.ai_skills,sfofl_cheji_skill)
sfofl_cheji_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_cheji:.:")
end

sgs.ai_skill_use_func["#sfofl_cheji"] = function(card,use,self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	if self.player:getHp()<3 then
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _,zcard in sgs.list(self.player:getCards("he"))do
			if not isCard("Peach",zcard,self.player)
			then
				local shouldUse = true
				if isCard("Slash",zcard,self.player)
				and not use_slash
				then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.list(dummy_use.to)do
								if p:getHp()<=1 then
									shouldUse = false
									if self.player:distanceTo(p)>1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length()>1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId()==sgs.Card_TypeTrick then
					if self:aiUseCard(zcard).card then shouldUse = false end
				end
				if zcard:getTypeId()==sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					if self:aiUseCard(zcard).card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId()==keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp()<2 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards,zcard:getId()) end
			end
		end
	end
	if #unpreferedCards<1 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,card)
				then
					if self:aiUseCard(card).card then
						will_use = true
						use_slash_num = use_slash_num+1
					end
				end
				if not will_use then table.insert(unpreferedCards,card:getId()) end
			end
		end
		local num = self:getCardsNum("Jink")-1
		if self.player:getArmor() then num = num+1 end
		if num>0 then
			for _,card in ipairs(cards)do
				if card:isKindOf("Jink") and num>0 then
					table.insert(unpreferedCards,card:getId())
					num = num-1
				end
			end
		end
		for _,card in ipairs(cards)do
			if card:isKindOf("Weapon") and self.player:getHandcardNum()<3
			or self:getSameEquip(card,self.player)
			or card:isKindOf("OffensiveHorse")
			or card:isKindOf("AmazingGrace")
			then table.insert(unpreferedCards,card:getId())
			elseif card:getTypeId()==sgs.Card_TypeTrick then
				if not self:aiUseCard(card).card then table.insert(unpreferedCards,card:getId()) end
			end
		end
	end

	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		local target 
		for _,friend in ipairs(self.friends_noself)do
			if self:canDraw(friend, self.player) and (self:needToLoseHp(friend,self.player) or not self:damageIsEffective(friend,"F",self.player)) then
				target = friend
				break
			end
		end
		if not target then
			for _,friend in ipairs(self.friends_noself)do
				if self:canDraw(friend, self.player) and not self:isWeak(friend) then
					target = friend
					break
				end
			end
		end
		if not target then
			local dc = dummyCard()
            dc:setSkillName("_sfofl_cheji")
			for _,enemy in ipairs(self.enemies)do
				if not self:canDraw(enemy, self.player) or self:damageIsEffective(target,"F",self.player) or self:isGoodTarget(enemy,self.enemies, dc) then
					target = enemy
					break
				end
			end
		end
		if target then
			use.card = sgs.Card_Parse("#sfofl_cheji:"..table.concat(use_cards,"+")..":")
			use.to:append(target)
		end
	end
end

sgs.ai_use_value.sfofl_cheji = 9
sgs.ai_use_priority.sfofl_cheji = 2.61
sgs.dynamic_value.benefit.sfofl_cheji = true

sgs.ai_skill_playerchosen.sfofl_cheji = function(self,targets)
	local target
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("sfofl_cheji_target") then
			target = p
			break
		end
	end
	local dc = dummyCard()
	dc:setSkillName("_sfofl_cheji")
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) and self:isGoodTarget(p,self.enemies, dc) and not self:needToLoseHp(p, target, dc) and  self:slashIsEffective(dc, p) then
			return p
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) and self:isGoodTarget(p,self.enemies, dc) and  self:slashIsEffective(dc, p) then
			return p
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and self:needToLoseHp(p, target, dc) then
			return p
		end
	end
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self,targets)
end

sgs.ai_skill_invoke.sfofl_kuixiang = function(self, data)
    local target = nil
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("sfofl_kuixiangtarget") then
            target = p
            break
        end
    end
    if not target then return false end
    return self:isEnemy(target)
end


sgs.ai_ajustdamage_from.sfofl_jicui = function(self, from, to, card, nature)
	if card and card:isKindOf("NatureSlash") and from:getPhase() ~= sgs.Player_NotActive and (from:getMark("sfofl_jicui-Clear") > 0 or card:hasFlag("sfofl_jicui")) then
		return 1
	end
end

sgs.ai_skill_invoke.sfofl_cuixi = true

local sfofl_cuixi_skill = {}
sfofl_cuixi_skill.name = "sfofl_cuixi"
table.insert(sgs.ai_skills, sfofl_cuixi_skill)
sfofl_cuixi_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_cuixi:.:")
end

sgs.ai_skill_use_func["#sfofl_cuixi"] = function(card, use, self)
	self:sort(self.enemies,"handcard",true)
	local use_cards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, acard in ipairs(cards) do
		if self:getKeepValue(acard)<6 then
			table.insert(use_cards, acard:getEffectiveId())
		end
	end
	local targets = {}
	for _,enemy in sgs.list(self.enemies)do
		if enemy:getHp()<self.player:getHp() then
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, "N", self.player) and self:canDamage(enemy,self.player,nil) and not self:cantDamageMore(self.player, enemy) then
				table.insert(targets, enemy)
			end
		end
	end
	for _,enemy in sgs.list(self.enemies)do
		if enemy:getHp()<self.player:getHp() then
			if not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, "N", self.player) and self:canDamage(enemy,self.player,nil) and not table.contains(targets, enemy) then
				table.insert(targets, enemy)
			end
		end
	end
	if #targets < 2 then return end
	if #use_cards > 0 then
		use.card = sgs.Card_Parse("#sfofl_cuixi:".. table.concat(use_cards, "+")..":")
	else
		use.card = sgs.Card_Parse("#sfofl_cuixi:.:")
	end
	use.to:append(targets[1])
	use.to:append(targets[2])
	return
end

sgs.ai_use_value.sfofl_cuixi = 9.5
sgs.ai_use_priority.sfofl_cuixi = 3.5
sgs.ai_card_intention.sfofl_cuixi = 70

sgs.ai_use_revises["&sfofl_jujun"] = function(self,card,use)
	if card:isKindOf("Peach") or card:isKindOf("Analeptic") and self.player:getHp()<1 then
		if self.player:getMark("&sfofl_jujun")>0 then
			return false
		end
	end
end

local sfofl_jujun_skill = {}
sfofl_jujun_skill.name = "sfofl_jujun"
table.insert(sgs.ai_skills,sfofl_jujun_skill)
sfofl_jujun_skill.getTurnUseCard = function(self)
	if #self.enemies<=0 then return end
	if not self:isWeak() then return end
	for _,enemy in sgs.list(self.enemies)do
		if self:damageMinusHp(enemy,1)>0
		or enemy:getHp()<3 and self:damageMinusHp(enemy,0)>0 and enemy:getHandcardNum()>0
		then
			return sgs.Card_Parse("#sfofl_jujun:.:")
		end
	end
	if (#self.friends>1) or (#self.enemies==1 and sgs.turncount>1) then
		if self:getAllPeachNum()==0 and self.player:getHp()==1 then
			return sgs.Card_Parse("#sfofl_jujun:.:")
		end
		if self:isWeak() and self.role=="rebel" and self.player:inMyAttackRange(self.room:getLord()) and self:hasCrossbowEffect() then
			return sgs.Card_Parse("#sfofl_jujun:.:")
		end
	end
end

sgs.ai_skill_use_func["#sfofl_jujun"] = function(card,use,self)
	use.card = card
	return
end

sgs.ai_use_priority["sfofl_jujun"] = 10

sgs.ai_skill_invoke.sfofl_sixi = true

sgs.ai_skill_use["@@sfofl_sixi"] = function(self, prompt)
	local pattern = sgs.Sanguosha:cloneCard("yj_stabs_slash")
	pattern:deleteLater()
	pattern:setSkillName("sfofl_sixi")
	local dummy_use = self:aiUseCard(pattern, dummy())
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return pattern:toString().."->"..table.concat(tos, "+")
    end
    return "."
end

local sfofl_sixi_skill = {}
sfofl_sixi_skill.name = "sfofl_sixi"
table.insert(sgs.ai_skills,sfofl_sixi_skill)
sfofl_sixi_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	return sgs.Card_Parse("#sfofl_sixi:.:")
end

sgs.ai_skill_use_func["#sfofl_sixi"] = function(card,use,self)
	self:sort(self.enemies,"handcard")
	local cards = sgs.CardList()
	local peach = 0
	for _,c in sgs.qlist(self.player:getHandcards())do
		if isCard("Peach",c,self.player) and peach<2 then
			peach = peach+1
		else
			cards:append(c)
		end
	end
	local max_card = self:getMaxCard(self.player,cards)
	if not max_card then return end
	local max_point = max_card:getNumber()
	local slashcount = self:getCardsNum("Slash")
	if isCard("Slash",max_card,self.player) then slashcount = slashcount-1 end
	
	local slash = self:getCard("Slash")
	local dummy_use = dummy(true,1)
	self.player:setFlags("slashNoDistanceLimit")
	if slash then self:useBasicCard(slash,dummy_use) end
	self.player:setFlags("-slashNoDistanceLimit")

	sgs.ai_use_priority.sfofl_sixiCard = (slashcount>=1 and dummy_use.card) and 7.2 or 1.2
	if slashcount>=1 and slash and dummy_use.card  then
		if #self.enemies<1 then return end
		if dummy_use.to:length()>1 then
			self:sort(self.friends_noself,"handcard")
			for index = #self.friends_noself,1,-1 do
				local friend = self.friends_noself[index]
				if self.player:canPindian(friend) then
					local friend_min_card = self:getMinCard(friend)
					local friend_min_point = friend_min_card and friend_min_card:getNumber() or 100
					if max_point>friend_min_point then
						self.sfofl_sixi_card = max_card:getId()
						use.card = sgs.Card_Parse("#sfofl_sixi:.:")
						use.to:append(friend)
						return
					end
				end
			end
		end

		if dummy_use.to:length()>1 then
			for index = #self.friends_noself,1,-1 do
				local friend = self.friends_noself[index]
				if self.player:canPindian(friend) then
					if max_point>=7 then
						self.sfofl_sixi_card = max_card:getId()
						use.card = sgs.Card_Parse("#sfofl_sixi:.:")
						use.to:append(friend)
						return
					end
				end
			end
		end
	end

	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)

	if self:getOverflow()>0 then
		for _,enemy in sgs.list(self.enemies)do
			if self:doDisCard(enemy,"h") and self.player:canPindian(enemy) then
				self.sfofl_sixi_card = cards[1]:getId()
				use.card = sgs.Card_Parse("#sfofl_sixi:.:")
				use.to:append(enemy)
				return
			end
		end
	end
	return nil
end

function sgs.ai_skill_pindian.sfofl_sixi(minusecard,self,requestor)
	if requestor:getHandcardNum()==1 then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return cards[1]
	end
	local maxcard = self:getMaxCard()
	return self:isFriend(requestor) and self:getMinCard() or ( maxcard:getNumber()<6 and  minusecard or maxcard )
end

sgs.ai_cardneed.sfofl_sixi = sgs.ai_cardneed.tianyi

sgs.ai_card_intention["sfofl_sixi"] = 0
sgs.dynamic_value.control_card["sfofl_sixi"] = true

sgs.ai_use_value["sfofl_sixi"] = 8.5

sgs.ai_skill_invoke.sfofl_lvedao = function(self, data)
	local damage = data:toDamage()
	if self:isEnemy(damage.to) then
		return true
	end
	return false
end

local sfofl_bixiong_skill = {}
sfofl_bixiong_skill.name = "sfofl_bixiong"
table.insert(sgs.ai_skills,sfofl_bixiong_skill)
sfofl_bixiong_skill.getTurnUseCard = function(self)
	if #self.enemies<=0 then return end
	if self:needBear() then return end
	return sgs.Card_Parse("#sfofl_bixiong:.:")
end

sgs.ai_skill_use_func["#sfofl_bixiong"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_use = {}
	for _, card in ipairs(cards) do
		table.insert(to_use, card:getId())
		if #to_use == 2 then break end
	end
	if #to_use < 2 then
		return
	end
	use.card = sgs.Card_Parse("#sfofl_bixiong:".. table.concat(to_use, "+") ..":")
end

function sgs.ai_cardneed.sfofl_xingwei(to,card)
	return card:isRed()
end
sgs.ai_skill_invoke.sfofl_xingwei = true

addAiSkills("sfofl_qianmu").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for _,pc in sgs.list(patterns())do
		if self:getCardsNum(pc)>0 then continue end
		if self.player:getMark("sfofl_qianmu_guhuo_remove_"..pc.."-Clear")<1 then
			local dc = dummyCard(pc)
			if dc:isKindOf("TrickCard") and self.player:getMark("sfofl_qianmu_trick-Clear") > 0
			then continue end
			if dc:isKindOf("BasicCard") and self.player:getMark("sfofl_qianmu_basic-Clear") > 0
			then continue end
			for _,c in sgs.list(cards)do
				if dc:isKindOf("TrickCard") and c:getSuit() ~= sgs.Card_Heart
				then continue end
				if dc:isKindOf("BasicCard") and c:getSuit() ~= sgs.Card_Diamond
				then continue end
				dc:clearSubcards()
				dc:setSkillName("sfofl_qianmu")
				dc:addSubcard(c:getEffectiveId())
				local dummy_use = self:aiUseCard(dc, dummy())
				if dc:isAvailable(self.player) and dummy_use.card then
					self.sfofl_qianmu_to = dummy_use.to
					sgs.ai_use_priority.sfofl_qianmu = sgs.ai_use_priority[dc:getClassName()]
					return sgs.Card_Parse("#sfofl_qianmu:"..c:getEffectiveId()..":".. pc)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_qianmu"] = function(card,use,self)
	use.card = card
	use.to = self.sfofl_qianmu_to
end

sgs.ai_guhuo_card.sfofl_qianmu = function(self,toname,class_name)
	if self.player:getMark("sfofl_qianmu_guhuo_remove_"..toname.."-Clear")>0
	or self:getCardsNum(class_name)>0 then return end
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	local dc = dummyCard(toname)
	if (not dc) then return end
	dc:setSkillName("sfofl_qianmu")
	if dc:isKindOf("TrickCard") and self.player:getMark("sfofl_qianmu_trick-Clear") > 0 then end
	if dc:isKindOf("BasicCard") and self.player:getMark("sfofl_qianmu_basic-Clear") > 0 then end
	for _,c in sgs.list(cards)do
		if dc:isKindOf("TrickCard") and c:getSuit() ~= sgs.Card_Heart
		then continue end
		if dc:isKindOf("BasicCard") and c:getSuit() ~= sgs.Card_Diamond
		then continue end
		dc:addSubcard(c:getEffectiveId())
		return "#sfofl_qianmu:"..c:getEffectiveId()..":"..toname
	end
end
function sgs.ai_cardneed.sfofl_qianmu(to,card)
	return card:isRed()
end

sgs.ai_skill_playerschosen.sfofl_silve = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if self:doDisCard(target, "he", true) then
			selected:append(target)
			if selected:length() >= max then break end
		end
	end
    return selected
end

sgs.ai_skill_choice.sfofl_suibian = function(self, choices, data)
	local use = data:toCardUse()
	local draw = getChoice(choices, "draw")
	local damage = getChoice(choices, "damage")
	local null = getChoice(choices, "nullified")
	if self:isFriend(use.to:first()) and null then
		local target = use.to:first()
		if not use.from or use.from:isDead() then return draw end
		if self.role == "rebel" and sgs.ai_role[use.from:objectName()] == "rebel" and not hasJueqingEffect(use.from, target, sgs.card_damage_nature[use.card:getClassName()])
			and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then
			return draw
		end
		if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not hasJueqingEffect(use.from, target, sgs.card_damage_nature[use.card:getClassName()]) and use.from:isLord() and self.player:getHp() == 1) then
			if use.card:isKindOf("AOE") then
				local from = use.from
				if use.card:isKindOf("SavageAssault") then
					local menghuo = self.room:findPlayerBySkillName("huoshou")
					if menghuo then from = menghuo end
				end

				local friend_null = 0
				for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
					if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
					if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
				end
				friend_null = friend_null + self:getCardsNum("Nullification")
				local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

				if self:hasTrickEffective(use.card, self.player, from) then
					if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then
						if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then
							return	null
						end
						if sj_num == 0 and friend_null <= 0 then
							if self:isEnemy(from) and hasJueqingEffect(from, target, sgs.card_damage_nature[use.card:getClassName()]) then
								return	null
							end
							if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not hasJueqingEffect(from, target, sgs.card_damage_nature[use.card:getClassName()]) then
								return	null
							end
							if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or hasJueqingEffect(from, target, sgs.card_damage_nature[use.card:getClassName()])) then
								return null
							end
						end
					end
				end
			elseif self:isEnemy(use.from) and self:isFriend(target) then
				if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
					if self:hasTrickEffective(use.card, target, use.from) then
						if self:damageIsEffective(target, sgs.DamageStruct_Fire, use.from) then
							if (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0) and use.from:getHandcardNum() > 3
								and not (use.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
								return null
							elseif target:isChained() and not self:isGoodChainTarget(target, use.from) then
								return null
							end
						end
					end
				elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))  then
					if self:hasTrickEffective(use.card, target, use.from) then
						return null
					end
				elseif use.card:isKindOf("Duel") then
					if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player) then
						if self:hasTrickEffective(use.card, target, use.from) then
							if self:damageIsEffective(target, sgs.DamageStruct_Normal, use.from) then
								return null
							end
						end
					end
				elseif use.card:isKindOf("Slash") then
					if self:ajustDamage(use.from,target,1,use.card)> 1 or self:ajustDamage(use.from,target,1,use.card)> target:getHp() then
						if self.player:getHp() > 1 then
							return null
						end
					end
				end
			end
		end
	end
	if use.from and self:isEnemy(use.from) then
		if self:isWeak(use.from) then
			if self:damageIsEffective(use.from, sgs.DamageStruct_Normal, self.player) then
				return damage
			end
		end
	end
	return draw
end

sgs.ai_skill_playerchosen.sfofl_suibian = function(self,targets)
	local card = sgs.Sanguosha:getCard(self.player:getMark("sfofl_suibian"))
	local c,to = self:getCardNeedPlayer({card},false)
  	if c and to then
		return to
	end
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and self:canDraw(p, self.player) then
			return p
		end
	end
	return targets:first()
end

sgs.ai_playerchosen_intention.sfofl_suibian = -40

sgs.ai_card_priority.sfofl_suibian = function(self,card)
	for _,id in sgs.qlist(self.player:getPile("sfofl_silve_lve")) do
		if card:getSuit() == sgs.Sanguosha:getCard(id):getSuit() then return 5 end
	end
end



local sfofl_lianji_skill = {}
sfofl_lianji_skill.name = "sfofl_lianji"
table.insert(sgs.ai_skills, sfofl_lianji_skill)
sfofl_lianji_skill.getTurnUseCard = function(self)
	if #self.friends_noself == 0 then return end
	if not self.player:hasUsed("#sfofl_lianji") then
		return sgs.Card_Parse("#sfofl_lianji:.:")
	end
end

sgs.ai_skill_use_func["#sfofl_lianji"] = function(card, use, self)
	self:sort(self.friends_noself, "handcard")
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend, self.player) then
			if friend:hasSkills(sgs.cardneed_skill) then
				use.card = sgs.Card_Parse("#sfofl_lianji:.:")
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
	
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend, self.player) then
			use.card = sgs.Card_Parse("#sfofl_lianji:.:")
			if use.to then use.to:append(friend) end
			return
		end
	end
	
end

sgs.ai_use_priority["sfofl_lianji"] = 3
sgs.ai_use_value["sfofl_lianji"] = 2.45
sgs.ai_card_intention.sfofl_lianji = -80

sgs.ai_skill_askforag.sfofl_lianji = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = sgs.Sanguosha:getCard(id)
		local dummy_use = self:aiUseCard(card, dummy())
		if card:isAvailable(self.player) and dummy_use.card then
			return id
		end
	end
end

sgs.ai_skill_use["@@sfofl_lianji!"] = function(self, prompt)
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	pattern = self.player:getMark("sfofl_lianji_id-PlayClear") - 1
	pattern = sgs.Sanguosha:getEngineCard(pattern)
	pattern = sgs.Sanguosha:cloneCard(pattern:objectName())
	pattern:deleteLater()
	pattern:setSkillName("sfofl_lianji")
	local dummy_use = self:aiUseCard(pattern, dummy())
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return pattern:toString().."->"..table.concat(tos, "+")
    end
	if self.room:getCardTargets(self.player, pattern):length() > 0 and pattern:isSingleTargetCard() then
		return pattern:toString().."->"..self.room:getCardTargets(self.player, pattern):first():objectName()
	end
    return pattern:toString()
end

addAiSkills("sfofl_jingongz").getTurnUseCard = function(self)
	if self.player:getMark("sfofl_jingongz-PlayClear") > 0	then return end
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for _,pc in sgs.list(patterns())do
		if self:getCardsNum(pc)>0 then continue end
		local dc = dummyCard(pc)
		if dc:isKindOf("TrickCard") then
			for _,c in sgs.list(cards)do
				if c:isKindOf("Slash") or c:isKindOf("EquipCard") then 
					dc:clearSubcards()
					dc:setSkillName("sfofl_jingongz")
					dc:addSubcard(c:getEffectiveId())
					local dummy_use = self:aiUseCard(dc, dummy())
					if dc:isAvailable(self.player) and dummy_use.card then
						self.sfofl_jingongz_to = dummy_use.to
						sgs.ai_use_priority.sfofl_jingongz = sgs.ai_use_priority[dc:getClassName()]
						return sgs.Card_Parse("#sfofl_jingongz:"..c:getEffectiveId()..":".. pc)
					end
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_jingongz"] = function(card,use,self)
	use.card = card
	use.to = self.sfofl_jingongz_to
end


local sfofl_liyu_skill = {}
sfofl_liyu_skill.name = "sfofl_liyu"
table.insert(sgs.ai_skills,sfofl_liyu_skill)
sfofl_liyu_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_liyu:.:")
end

sgs.ai_skill_use_func["#sfofl_liyu"] = function(card,use,self)
	
	self:sort(self.enemies,"handcard")
	for _,p in ipairs(self.enemies)do
		if self:doDisCard(p, "he", true) then
			use.card = sgs.Card_Parse("#sfofl_liyu:.:")
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_priority.sfofl_liyu = sgs.ai_use_priority.Slash+0.1
sgs.ai_use_value.sfofl_liyu = 8.5

sgs.ai_ajustdamage_from.sfofl_liyu = function(self, from, to, card, nature)
    if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and from:getMark("sfofl_liyu-Clear") > 0
    then
        return 1
    end
end

sgs.ai_skill_invoke.sfofl_sixiong =  function(self, data)
	for _,c in sgs.qlist(self.player:getHandcards())do
		if c:isRed() then 
			local good = 0
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if self.player:inMyAttackRange(p) then
					if self:damageIsEffective(p, nil, self.player) then
						if self:isFriend(p) then
							good = good - 1
						else
							good = good + 1
							if self:isWeak(p) then
								good = good + 1
							end
						end
					end
				end
			end
			if good > 0 then
				return true
			end
			break
		end
	end

	local max = 0
	for _,p in sgs.qlist(self.room:getAllPlayers()) do
		if not p:getPile("sfofl_weiju_ju"):isEmpty() then
			max = max + p:getPile("sfofl_weiju_ju"):length()
		end
	end
	local black = 0
	for _,c in sgs.qlist(self.player:getHandcards())do
		if c:isBlack() then black = black + 1 end
	end
	if max > black then
		return true
	end
	return false
end

sgs.ai_skill_choice.sfofl_sixiong = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "red") then
		local good = 0
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self.player:inMyAttackRange(p) then
				if self:damageIsEffective(p, nil, self.player) then
					if self:isFriend(p) then
						good = good - 1
						if self:isWeak(p) then
							good = good - 1
						end
					else
						good = good + 1
						if self:isWeak(p) then
							good = good + 1
						end
					end
				end
			end
		end
		if good > 0 then
			if table.contains(items, "all") then
				local max = 0
				for _,p in sgs.qlist(self.room:getAllPlayers()) do
					if not p:getPile("sfofl_weiju_ju"):isEmpty() then
						max = max + p:getPile("sfofl_weiju_ju"):length()
					end
				end
				local black = 0
				for _,c in sgs.qlist(self.player:getHandcards())do
					if c:isBlack() then black = black + 1 end
				end
				if max > black then
					return "all"
				end
			end
			return "red"
		end
	end
	if table.contains(items, "black") then
		local max = 0
		for _,p in sgs.qlist(self.room:getAllPlayers()) do
			if not p:getPile("sfofl_weiju_ju"):isEmpty() then
				max = max + p:getPile("sfofl_weiju_ju"):length()
			end
		end
		local black = 0
		for _,c in sgs.qlist(self.player:getHandcards())do
			if c:isBlack() then black = black + 1 end
		end
		if max > black then
			return "black"
		end
	end
	return items[math.random(1, #items)]
end


sgs.ai_skill_use["@@sfofl_sixiong!"] = function(self, prompt)
	local x = self.player:getMark("sfofl_sixiong")
	local use_cards = {}
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) then
			for _,id in sgs.qlist(p:getPile("sfofl_weiju_ju"))do
				table.insert(use_cards, id)
				if #use_cards >= x then
					break
				end
			end
		end
	end
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		for _,id in sgs.qlist(p:getPile("sfofl_weiju_ju"))do
			if not table.contains(use_cards, id) then
				table.insert(use_cards, id)
				if #use_cards >= x then
					break
				end
			end
		end
	end
	if #use_cards > 0 then
		return "#sfofl_sixiong:".. table.concat(use_cards, "+")..":"
	end
end


sgs.ai_skill_playerchosen.sfofl_sangluan = function(self,targets)
	if self.player:hasSkill("sfofl_longmu") then
		for _,p in sgs.qlist(targets) do
			if self:isEnemy(p) and p:getMark("sfofl_longmu"..self.player:objectName()) == 0 then
				return p
			end
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sfofl_sangluan = 20
sgs.ai_skill_playerchosen.sfofl_sangluan_slash = function(self,targets)
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and self:needToLoseHp(p,self.player,nil) then
			return p
		end
	end
	return targets:first()
end

sgs.ai_playerchosen_intention.sfofl_sangluan_slash = 40

addAiSkills("sfofl_chuce").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for _,pc in sgs.list(RandomList(patterns()))do
		local dc = dummyCard(pc)
		if dc:isKindOf("TrickCard") or dc:isKindOf("BasicCard") then
			for _,c in sgs.list(cards)do
				if c:isKindOf("TrickCard") then 
					dc:setSkillName("sfofl_chuce")
					dc:addSubcard(c:getEffectiveId())
					local dummy_use = self:aiUseCard(dc, dummy())
					if dc:isAvailable(self.player) and dummy_use.card then
						self.sfofl_chuce_to = dummy_use.to
						sgs.ai_use_priority.sfofl_chuce = sgs.ai_use_priority[dc:getClassName()]
						return sgs.Card_Parse("#sfofl_chuce:"..c:getEffectiveId()..":".. pc)
					end
					dc:clearSubcards()
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_chuce"] = function(card,use,self)
	use.card = card
	use.to = self.sfofl_chuce_to
end

sgs.ai_guhuo_card.sfofl_chuce = function(self,toname,class_name)
	if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	local dc = dummyCard(toname)
	if (not dc) then return end
	dc:setSkillName("sfofl_chuce")
	for _,c in sgs.list(cards)do
		if not c:isKindOf("TrickCard") then continue end
		dc:addSubcard(c:getEffectiveId())
		return "#sfofl_chuce:"..c:getEffectiveId()..":"..toname
	end
end
sgs.ai_skill_use["@@sfofl_chuce"] = function(self, prompt)
	local pattern = sgs.Sanguosha:getCurrentCardUsePattern()
	pattern = self.player:getMark("sfofl_chuce_id-PlayClear") - 1
	pattern = sgs.Sanguosha:getCard(pattern)
	pattern = sgs.Sanguosha:cloneCard(pattern:objectName())
	pattern:deleteLater()
	pattern:setSkillName("sfofl_chuce")
	local dummy_use = self:aiUseCard(pattern, dummy())
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return pattern:toString().."->"..table.concat(tos, "+")
    end
    return "."
end

sgs.ai_skill_invoke.sfofl_chuce = function(self, data)
	local use = data:toCardUse()
    if use.from and self:isEnemy(use.from) then return true end
	return false
end
sgs.ai_skill_invoke.sfofl_chuceuse = function(self, data)
	local id = self.player:getMark("sfofl_chuce_id-PlayClear") - 1
	local card = sgs.Sanguosha:getCard(id)
	card = sgs.Sanguosha:cloneCard(card:objectName())
	card:setSkillName("sfofl_chuce")
	card:deleteLater()
    local dummy_use = self:aiUseCard(card, dummy())
	if card:isAvailable(self.player) and dummy_use.card then
		return true
	end
	return false
end


sgs.ai_target_revises.sfofl_longmu = function(to,card)
	if card:isKindOf("TrickCard")
	then return true end
end

sgs.ai_event_callback[sgs.BeforeGameOverJudge].sfofl_longmu = function(self, player, data)
    for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
		local target = data:toDeath().who
		if string.find(target:getGeneralName(), "zombie") or string.find(target:getGeneral2Name(), "zombie") then
			continue
		end
		if sb:hasSkill("sfofl_longmu") and target:getMark("sfofl_longmu"..sb:objectName()) > 0 then
            sgs.roleValue[target:objectName()]["renegade"] = 0
            sgs.roleValue[target:objectName()]["loyalist"] = 0
            local role, value = sb:getRole(), 1000
            if role == "rebel" then role = "loyalist" value = -1000 end
            sgs.roleValue[target:objectName()][sb:getRole()] = 1000
            sgs.ai_role[target:objectName()] = target:getRole()
            self:updatePlayers()
        end
    end
end


sgs.ai_skill_playerchosen._sfofl_lianshikui = function(self,targets)
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			return p
		end
	end
	return nil
end

sgs.ai_playerchosen_intention._sfofl_lianshikui = -40

sgs.ai_skill_choice.sfofl_sixiong = function(self, choices, data)
	local current = self.room:getCurrent()
	if current and not current:hasSkill("sfofl_longmu")  then
		return "hp"
	end
	return "gainHujia"
end

addAiSkills("sfofl_dingxi").getTurnUseCard = function(self)
	if self.player:getMark("&sfofl_dingxi_can") < 2 then return end
	for _,pc in sgs.list(RandomList(patterns()))do
		if self:getCardsNum(pc)>0 then continue end
		local dc = dummyCard(pc)
		if dc:isKindOf("TrickCard") or dc:isKindOf("BasicCard") then
			local card_ids = self.room:getNCards(1, false)
			local card = sgs.Sanguosha:getCard(card_ids:first())
			self.room:returnToTopDrawPile(card_ids)
			if card:getTypeId() == dc:getTypeId() or math.random() < 0.3 then
				dc:setSkillName("sfofl_dingxi")
				local dummy_use = self:aiUseCard(dc, dummy())
				if dc:isAvailable(self.player) and dummy_use.card then
					self.sfofl_dingxi_to = dummy_use.to
					sgs.ai_use_priority.sfofl_dingxi = sgs.ai_use_priority[dc:getClassName()]
					return sgs.Card_Parse("#sfofl_dingxi:.:".. pc)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_dingxi"] = function(card,use,self)
	use.card = card
	use.to = self.sfofl_dingxi_to
end

sgs.ai_guhuo_card.sfofl_dingxi = function(self,toname,class_name)
	if self.player:getMark("&sfofl_dingxi_can") < 2 then return end
	if self:getCardsNum(class_name)>0 then return end
	if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
	local dc = dummyCard(toname)
	if (not dc) then return end
	local card_ids = self.room:getNCards(1, false)
	local card = sgs.Sanguosha:getCard(card_ids:first())
	self.room:returnToTopDrawPile(card_ids)
	if card:getTypeId() ~= dc:getTypeId() and math.random() < 0.9 then return end
	dc:setSkillName("sfofl_dingxi")
	return "#sfofl_dingxi:.:"..toname
end


local sfofl_dingluan_skill = {}
sfofl_dingluan_skill.name = "sfofl_dingluan"
table.insert(sgs.ai_skills,sfofl_dingluan_skill)
sfofl_dingluan_skill.getTurnUseCard = function(self)
	if self:isWeak() or self:needBear() then return end
	if #self.enemies == 0 then return end
	return sgs.Card_Parse("#sfofl_dingluan:.:")
end

sgs.ai_skill_use_func["#sfofl_dingluan"] = function(card,use,self)
	local target 
	for _,enemy in ipairs(self.enemies)do
		if self:isGoodTarget(enemy,self.enemies, nil) then
			target = enemy
			break
		end
	end
	if target then
		use.card = sgs.Card_Parse("#sfofl_dingluan:.:")
		use.to:append(target)
	end
end

sgs.ai_use_value.sfofl_dingluan = 9
sgs.ai_use_priority.sfofl_dingluan = 5
sgs.ai_card_intention.sfofl_dingluan = 80
sgs.dynamic_value.benefit.sfofl_dingluan = true


sgs.ai_skill_choice.sfofl_dingluan = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if math.random() < 0.5 or #self.friends_noself < 3 then return "skill" end
	local BearingDownBorder = sgs.Sanguosha:cloneCard("_sfofl_bearing_down_border", sgs.Card_NoSuit, 0)
	BearingDownBorder:setSkillName("sfofl_dingluan")
	BearingDownBorder:deleteLater()
	local dummy_use = self:aiUseCard(BearingDownBorder,dummy(true, 0, self.room:getOtherPlayers(target)))
	if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
		return "BearingDownBorder"
	end
	return "skill"
end


sgs.ai_skill_playerchosen.sfofl_qianjiang = function(self,targets)
	local death = self.room:getTag("sfofl_qianjiang"):toDeath()
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) then
			if self:playerGetRound(p) > self:playerGetRound(death.who) and self:playerGetRound(death.who) > 0 then
				return p
			end
		end
	end
	for _,p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			if self:playerGetRound(p) <= self:playerGetRound(death.who) or self:playerGetRound(death.who) == 0 then
				return p
			end
		end
	end
	return nil
end

function SmartAI:useCardBearingDownBorder(card,use)
	if #self.friends_noself == 0 then return end
	local extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
	slash:setSkillName("BearingDownBorder")
	slash:deleteLater()
	self.player:setFlags("InfinityAttackRange")
	local dummy_use = self:aiUseCard(slash,dummy(true, 99))
	self.player:setFlags("-InfinityAttackRange")
	if dummy_use.card and dummy_use.to then
		if not dummy_use.to:isEmpty() then
			use.card = card
			for _, p in sgs.qlist(dummy_use.to) do
				if self:hasTrickEffective(card,p,self.player) then
					use.to:append(p)
					if use.to:length()>extraTarget then break end
				end
			end
		end
	end
end

sgs.ai_skill_cardask["@sfofl_bearing_down_border"] = function(self, data, pattern, target, target2)	
	local target = data:toPlayer()
	local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do

		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		slash:addSubcard(c)
		slash:setSkillName("BearingDownBorder")
		slash:deleteLater()
		self.player:setFlags("InfinityAttackRange")
		local dummy_use = self:aiUseCard(slash,dummy(true, 0, self.room:getOtherPlayers(target)))
		self.player:setFlags("-InfinityAttackRange")
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
			return "$"..c:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_card_intention.BearingDownBorder = function(self,card,from,tos)
	sgs.updateIntentions(from,tos,80)
end

sgs.ai_skill_invoke.sfofl_jubing = function(self, data)
	local damage = data:toDamage()
    if damage.to and self:isEnemy(damage.to) then 
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		slash:setSkillName("_sfofl_jubing")
		slash:deleteLater()
		self.player:setFlags("InfinityAttackRange")
		local dummy_use = self:aiUseCard(slash,dummy(true, 0, self.room:getOtherPlayers(damage.to)))
		self.player:setFlags("-InfinityAttackRange")
		if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(damage.to) then
			return true
		end
	end
	return false
end


local sfofl_chiyuan_skill = {}
sfofl_chiyuan_skill.name = "sfofl_chiyuan"
table.insert(sgs.ai_skills, sfofl_chiyuan_skill)
sfofl_chiyuan_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_chiyuan:.:")
end

sgs.ai_skill_use_func["#sfofl_chiyuan"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	for _,p in ipairs(self.friends_noself) do
		if targets:length() >= self.player:getMark("&sfofl_zhuying") then
			break
		end
		if p:getMark("&sfofl_zhuying+to+#"..self.player:objectName()) == 0 then targets:append(p) end
	end

	if targets:length()> 0 then
		use.card = sgs.Card_Parse("#sfofl_chiyuan::")
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority["sfofl_chiyuan"] = 4.2
sgs.ai_card_intention["sfofl_chiyuan"] = -100



sgs.ai_skill_discard.sfofl_chiyuan = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	local damage = self.room:getTag("sfofl_chiyuan"):toDamage()
	if damage.to and self:isFriend(damage.to) then
		if self:needToLoseHp(damage.to,damage.from,damage.card) then
			if damage.from and self:isFriend(damage.from) then
				return {}
			end
			if damage.from and self:isEnemy(damage.from) and not self:canDamage(damage.from,self.player,nil) then
				return {}
			end
		end
	end
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, card:getEffectiveId())
        break
	end
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end

sgs.ai_skill_choice.sfofl_chiyuan = function(self, choices, data)
	local items = choices:split("+")
	local damage = data:toDamage()
	local choice = getChoice(choices, "damage")
	if damage.to then
		if self:isFriend(damage.to) then
			if self:isWeak(damage.to) then
				if self:damageStruct(damage) then
					return "prevented"
				end
			end
		end
	end
	if choice then
		if damage.from then
			if self:isEnemy(damage.from) then
				if self:isWeak(damage.from) then
					return choice
				end
				if self:canDamage(damage.from,self.player,nil) then
					return choice
				end
			end
		end
	end
	return "prevented"
end



sgs.ai_skill_use["@@sfofl_qifeng"] = function(self, prompt)
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash:setSkillName("sfofl_qifeng")
	self.player:setFlags("InfinityAttackRange")
	local dummy_use = self:aiUseCard(slash, dummy(true, 0, self.room:getOtherPlayers(self.room:getCurrent())))
	self.player:setFlags("-InfinityAttackRange")
	if dummy_use.to and dummy_use.to:length() > 0 and dummy_use.to:contains(self.room:getCurrent()) then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return slash:toString().."->"..table.concat(tos, "+")
    end
    return "."
end

sgs.ai_ajustdamage_from.sfofl_qifeng = function(self, from, to, card, nature)
    if card and (card:isKindOf("Slash") and card:getSkillName() == "sfofl_qifeng")   then
        return from:getMark("sfofl_qifeng-Clear") - 1
    end
end



addAiSkills("sfofl_dutan").getTurnUseCard = function(self)
	local ids = {}
   	local fs = dummyCard("duel")
	fs:setSkillName("sfofl_dutan")
	local dummy_use = self:aiUseCard(fs, dummy(true, 99))
	if fs:isAvailable(self.player)
	and dummy_use.card
	and dummy_use.to
  	then
		self.sfofl_dutan_to = dummy_use.to
		return sgs.Card_Parse("#sfofl_dutan:.:")
	end
end

sgs.ai_skill_use_func["#sfofl_dutan"] = function(card,use,self)
	use.card = card
	use.to = self.sfofl_dutan_to
end

sgs.ai_use_value.sfofl_dutan = 9.4
sgs.ai_use_priority.sfofl_dutan = sgs.ai_use_priority.Duel


sgs.ai_skill_use["@@sfofl_zhongtao"] = function(self, prompt)
	local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
    for _, c in ipairs(cards) do
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_SuitToBeDecided, -1)
		slash:addSubcard(c)
		slash:setSkillName("sfofl_zhongtao")
		slash:deleteLater()
		local dummy_use = self:aiUseCard(slash,dummy())
		if dummy_use.card and dummy_use and dummy_use.to then
			local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return slash:toString().."->"..table.concat(tos, "+")
		end
	end
    return "."
end


sgs.ai_skill_discard.sfofl_qiaobian = function(self, discard_num, min_num, optional, include_equip)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then return {} end
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)

	table.insert(to_discard, cards[1]:getEffectiveId())
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end



local sfofl_zhanyi_skill = {}
sfofl_zhanyi_skill.name = "sfofl_zhanyi"
table.insert(sgs.ai_skills,sfofl_zhanyi_skill)
sfofl_zhanyi_skill.getTurnUseCard = function(self)
	if self:isWeak() or self:needBear() then return end
	return sgs.Card_Parse("#sfofl_zhanyi:.:")
end

sgs.ai_skill_use_func["#sfofl_zhanyi"] = function(card,use,self)
	local to_discard
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)
	local TrickCards = {}
	for _,card in ipairs(cards)do
		if card:isKindOf("Disaster") or card:isKindOf("GodSalvation") or card:isKindOf("AmazingGrace") or self:getCardsNum("TrickCard")>1 then
			table.insert(TrickCards,card)
		end
	end
	if #TrickCards>0 and (self.player:getHp()>2 or self:getCardsNum("Peach")>0 ) and self.player:getHp()>1 then
		to_discard = TrickCards[1]
	end
	
	local BasicCards = {}
	for _,card in ipairs(cards)do
		if card:isKindOf("BasicCard") then
			table.insert(BasicCards,card)
		end
	end
	if (#BasicCards>3)
	then to_discard = BasicCards[1] end
	if to_discard then
		use.card = sgs.Card_Parse("#sfofl_zhanyi:"..to_discard:getEffectiveId()..":")
		return
	end
end

sgs.ai_use_priority["sfofl_zhanyi"] = 10


local sfofl_jianshu_skill = {}
sfofl_jianshu_skill.name = "sfofl_jianshu"
table.insert(sgs.ai_skills,sfofl_jianshu_skill)
sfofl_jianshu_skill.getTurnUseCard = function(self,inclusive)
	self:sort(self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if a:canPindian(b) then
				local cards = sgs.QList2Table(self.player:getCards("h"))
				self:sortByKeepValue(cards)
				for _,c in sgs.list(cards)do
					return sgs.Card_Parse("#sfofl_jianshu:"..c:getEffectiveId()..":")
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_jianshu"] = function(card,use,self)
	self:sort(self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if a:canPindian(b)	then
				use.card = card
				use.to:append(a)
				self.sfofl_jianshu = b
				return
			end
		end
	end
end

sgs.ai_use_priority["sfofl_jianshu"] = 0
sgs.ai_use_value["sfofl_jianshu"] = 2.5
sgs.ai_card_intention["sfofl_jianshu"] = 80

sgs.ai_skill_playerchosen.sfofl_jianshu = function(self, targets)
	if self.sfofl_jianshu then return self.sfofl_jianshu end
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "h") and not self:isFriend(target) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "h") then
            return target
        end
    end
    return targets[1]
end

sgs.ai_skill_discard.sfofl_zhenlue = function(self, discard_num, min_num, optional, include_equip)
	local use = self.room:getTag("sfofl_zhenlue"):toCardUse()
	if use.from and self:isFriend(use.from) then return {} end
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)

	table.insert(to_discard, cards[1]:getEffectiveId())
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end


sgs.ai_skill_playerchosen.sfofl_yuma = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "h", true) and not self:loseEquipEffect(target) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "h", true) then
            return target
        end
    end
    return nil
end
sgs.ai_playerchosen_intention.sfofl_yuma = 80


sgs.ai_skill_discard.sfofl_qiangshu = function(self, discard_num, min_num, optional, include_equip)
	local damage = self.room:getTag("sfofl_qiangshu"):toDamage()
	if damage.to and self:isFriend(damage.to) then return {} end
	if self:cantDamageMore(damage.from,damage.to)then return {} end
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, card:getEffectiveId())
		if #to_discard == min_num then
        	break
		end
	end
	if #to_discard == min_num then
		return to_discard
	end

	return {}
end


sgs.ai_skill_invoke.sfofl_bozhan = function(self, data)
	local current = self.room:getCurrent()
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	duel:setSkillName("sfofl_bozhan")
	local dummy_use = self:aiUseCard(duel, dummy(true, 99, self.room:getOtherPlayers(current)))
	if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(current) then
		return true
	end
	return false
end

sgs.ai_canliegong_skill.sfofl_tieti = function(self, from, to)
	return from:distanceTo(to) <= 1
end

sgs.ai_skill_invoke.sfofl_guwei = function(self, data)
	local target
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
        if p:hasFlag("sfofl_guwei_target") then
            target = p
            break
        end
    end
	local use = data:toCardUse()
	if target and self:isFriend(target) and self:isWeak(target) and self:slashIsEffective(use.card,target,use.from) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.sfofl_guwei = function(self, player, promptlist)
   	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(player))do
		if p:hasFlag("sfofl_guwei_target") then target = p break end
	end
	if target then
		if promptlist[#promptlist]=="yes" then
        	sgs.updateIntention(player, target, -80)
		end
    end
end


sgs.ai_card_priority.sfofl_zhitong = function(self,card,v)
	if self.player:getChangeSkillState("sfofl_zhitong") <= 1 and card:targetFixed()	then return 10 end
	if self.player:getChangeSkillState("sfofl_zhitong") > 1 and not card:targetFixed()	then return 10 end
end

sgs.ai_used_revises.sfofl_zhitong = function(self,use)
	if use.card:canRecast() then return end
	if not use.card:isKindOf("SkillCard")
	and self.player:getChangeSkillState("sfofl_zhitong") <= 1
	and not self.player:hasFlag("AI_sfofl_zhitong_Fail")
	and not use.isDummy then
		self.room:setPlayerFlag(self.player, "AI_sfofl_zhitong_Fail")
		local use_card
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("EquipCard") then
				use_card = card
			end
		end
		if use_card then
			use.card = use_card
			use.to = sgs.SPlayerList()
			return false
		end
	end
	if self.player:getChangeSkillState("sfofl_zhitong")<=1 then
	else
		local tp = self.player
		if not use.card:isKindOf("SkillCard") and use.to:length()>0 then tp = use.to:at(0) end
		if tp==self.player then
			if self:getCardsNum("Peach,Analeptic")<1 then use.card = nil end
		elseif self:isFriend(tp)
		then use.card = nil end
	end
end


sgs.ai_skill_choice.sfofl_dengtian = function(self, choices, data)
	local items = choices:split("+")
	items = RandomList(items)
	for _,item in sgs.list(items)do
		if self.player:getMark(item) < 2 then
			return item
		end
	end
	return items[math.random(1, #items)]
end


sgs.ai_ajustdamage_from.sfofl_dengtian = function(self, from, to, card, nature)
    if from:getMark("sfofl_dengtian-Clear") == 0
    then
        return from:getMark("sfofl_dengtian_damage")
    end
end

sgs.bad_skills = sgs.bad_skills .. "|sfofl_mingshu"


sgs.ai_skill_invoke.sfofl_juedou = function(self,data)
	local target = data:toPlayer()
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash:setSkillName("sfofl_juedou")
	self.player:setFlags("slashNoDistanceLimit")
	local dummy_use = self:aiUseCard(slash, dummy(true, 0, self.room:getOtherPlayers(target)))
	self.player:setFlags("-slashNoDistanceLimit")
	if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.sfofl_wanwang = function(self,data)
	local current = self.room:getCurrent()
	return self:isEnemy(current)
end

sgs.ai_choicemade_filter.skillInvoke.sfofl_wanwang = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:getCurrent()
		if target then sgs.updateIntention(player,target,50) end
	end
end

sgs.ai_skill_cardask["@sfofl_nagong"] = function(self,data, pattern, target)
	if self:isEnemy(target) and target:hasSkill("sfofl_wanwang") and target:getMark("sfofl_wanwang_lun") == 0 then
		local useds = self:getTurnUse()
		if #useds<1 then return "." end
		return math.random() < 0.7
	elseif self:isFriend(target) then
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		local targets = sgs.SPlayerList()
		targets:append(target)
		local c,to = self:getCardNeedPlayer(cards, false, targets)
		if c and to then
			return "$"..c:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_skill_use["@@sfofl_zongma"] = function(self, prompt)
	local use_card
	local target
	local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
	
    for _, c in ipairs(cards) do
			use_card = c
			break
	end
	if use_card then
		for _, friend in ipairs(self.friends_noself) do
			if friend:hasEquipArea(3) and friend:getEquip(3)==nil then
				target = friend
				self.sfofl_zongma = "OffensiveHorse"
				break
			end
		end
		if not target then
			if self.player:hasEquipArea(3) and self.player:getEquip(3)==nil then
				target = self.player
				self.sfofl_zongma = "OffensiveHorse"
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasEquipArea(2) and enemy:getEquip(2)==nil and not self:loseEquipEffect(enemy) then
					target = enemy
					self.sfofl_zongma = "DefensiveHorse"
					break
				end
			end
		end
		
		
	end
	if use_card and target then
		return "#sfofl_zongma:".. use_card:getEffectiveId()..":->"..target:objectName()
	end
	return "."
end

sgs.ai_skill_choice.sfofl_zongma = function(self, choices, data)
	if self.sfofl_zongma then return self.sfofl_zongma end
end


sgs.ai_skill_playerchosen.sfofl_jiaozi = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local id = self.room:getTag("sfofl_jiaozi"):toInt()
	local card = sgs.Sanguosha:getCard(id)
	if card then
		local c,to = self:getCardNeedPlayer({cards}, false)
		if c and to then
			return to
		end
	end
    for _, target in ipairs(targets) do
        if self:isFriend(target) and self:canDraw(target, self.player) then
            return target
        end
    end
    return nil
end
sgs.ai_playerchosen_intention.sfofl_jiaozi = -40

sgs.ai_skill_playerchosen.sfofl_jieyue = function(self, targets)
    return self.player
end
sgs.ai_skill_choice.sfofl_jieyue = function(self, choices, data)
	if not self:isWeak() then
		return "turn"
	end
	
	return "draw"
end
sgs.ai_skill_playerchosen.sfofl_daidi = function(self, targets)
	local card = sgs.Sanguosha:getCard(self.room:getTag("sfofl_daidi"):toInt())
	if card then
		local c,to = self:getCardNeedPlayer({cards}, true)
		if c and to then
			return to
		end
	end
    return self.player
end

local sfofl_xiaoguo_skill = {}
sfofl_xiaoguo_skill.name = "sfofl_xiaoguo"
table.insert(sgs.ai_skills,sfofl_xiaoguo_skill)
sfofl_xiaoguo_skill.getTurnUseCard = function(self)
	--if self.player:hasUsed("#sfofl_xiaoguo") then return end	
	if #self.enemies == 0 then return end
	return sgs.Card_Parse("#sfofl_xiaoguo:.:")
end


sgs.ai_skill_use_func["#sfofl_xiaoguo"] = function(card, use, self)
	local cmp = function(a, b)
		if a:getHp() < b:getHp() then
			if a:getHp() == 1 and b:getHp() == 2 then return false else return true end
		end
		return false
	end
	local enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy, self.player) and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal,self.player) and self:canDamage(enemy,self.player,nil) then table.insert(enemies, enemy) end
	end
	if #enemies == 0 then return end

	-- find cards
	local card_ids = {}
	local zcards = self.player:getHandcards()
	for _, zcard in sgs.qlist(zcards) do
		if zcard:isKindOf("BasicCard") then
			table.insert(card_ids, zcard:getId()) 
		end
	end
	if #card_ids == 0 then return end
	local hc_num = #card_ids
	for _, enemy in ipairs(enemies) do
		if enemy:getHp() > 1 then
			use.card = sgs.Card_Parse("#sfofl_xiaoguo:.:")
			use.card:addSubcard(card_ids[1])
			if use.to then use.to:append(enemy) end
			return
		else
			if not self:isWeak() or self:getSaveNum(true) >= 1 then
				use.card = sgs.Card_Parse("#sfofl_xiaoguo:.:")
				use.card:addSubcard(card_ids[1])
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end


sgs.ai_skill_playerchosen.sfofl_dizhao = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if self:isFriend(target) and self:canDraw(target, self.player) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if self:isFriend(target) then
            return target
        end
    end
    return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_dizhao = -40

sgs.ai_skill_playerchosen.sfofl_dizhaoheal = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local arr1,arr2 = self:getWoundedFriend(false,false)
	local target = nil

	if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and arr1[1]:getHp()<getBestHp(arr1[1]) then target = arr1[1] end
	if target and table.contains(targets, target) then
		return target
	end
	if #arr2>0 then
		for _,friend in ipairs(arr2)do
			if table.contains(targets, friend) then
				return friend
			end
		end
	end
    return targets[1]
end
sgs.ai_playerchosen_intention.sfofl_dizhaoheal = -40


addAiSkills("sfofl_dizhao").getTurnUseCard = function(self)
	for _,pc in sgs.list(patterns())do
		if self:getCardsNum(pc)>0 then continue end
		if self.player:getMark("sfofl_dizhao_guhuo_remove_"..pc.."_lun")<1 then
			local dc = dummyCard(pc)
			if dc:isKindOf("TrickCard") and self.player:getMark("sfofl_dizhao_trick_lun") > 0
			then continue end
			if dc:isKindOf("BasicCard") and self.player:getMark("sfofl_dizhao_basic_lun") > 0
			then continue end
			dc:setSkillName("sfofl_dizhao")
			local dummy_use = self:aiUseCard(dc, dummy())
			if dc:isAvailable(self.player) and dummy_use.card then
				self.sfofl_dizhao_to = dummy_use.to
				sgs.ai_use_priority.sfofl_dizhao = sgs.ai_use_priority[dc:getClassName()]
				return sgs.Card_Parse("#sfofl_dizhao:.:".. pc)
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_dizhao"] = function(card,use,self)
	use.card = card
	use.to = self.sfofl_dizhao_to
end

sgs.ai_guhuo_card.sfofl_dizhao = function(self,toname,class_name)
	if self.player:getMark("sfofl_dizhao_guhuo_remove_"..toname.."_lun")>0
	or self:getCardsNum(class_name)>0 then return end
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	local dc = dummyCard(toname)
	if (not dc) then return end
	dc:setSkillName("sfofl_dizhao")
	if dc:isKindOf("TrickCard") and self.player:getMark("sfofl_dizhao_trick_lun") > 0 then end
	if dc:isKindOf("BasicCard") and self.player:getMark("sfofl_dizhao_basic_lun") > 0 then end
	return "#sfofl_dizhao:.:"..toname
end

sgs.ai_skill_choice.sfofl_jixi = function(self, choices, data)
	local target = data:toPlayer()
	if self:doDisCard(target, "he", true) then
		return "obtain"
	end
	
	return "draw"
end

local sfofl_batteringram_skill = {}
sfofl_batteringram_skill.name = "sfofl_batteringram"
table.insert(sgs.ai_skills,sfofl_batteringram_skill)
sfofl_batteringram_skill.getTurnUseCard = function(self)
	--if self.player:hasUsed("#sfofl_batteringram") then return end	
	if #self.enemies == 0 then return end
	return sgs.Card_Parse("#sfofl_batteringram:.:")
end


sgs.ai_skill_use_func["#sfofl_batteringram"] = function(card, use, self)
	local cmp = function(a, b)
		if a:getHp() < b:getHp() then
			if a:getHp() == 1 and b:getHp() == 2 then return false else return true end
		end
		return false
	end
	local enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy, self.player) and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal,self.player) and self:canDamage(enemy,self.player,nil) then table.insert(enemies, enemy) end
	end
	if #enemies == 0 then return end

	for _, enemy in ipairs(enemies) do
		if enemy:getHp() > 1 then
			use.card = sgs.Card_Parse("#sfofl_batteringram:.:")
			if use.to then use.to:append(enemy) end
			return
		else
			if not self:isWeak() or self:getSaveNum(true) >= 1 then
				use.card = sgs.Card_Parse("#sfofl_batteringram:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_skill_invoke.sfofl_bladecart = function(self,data)
	local use = data:toCardUse()
	return self:isEnemy(use.from) and not self:cantbeHurt(use.from) and self:damageIsEffective(use.from, sgs.DamageStruct_Normal,self.player) and self:canDamage(use.from,self.player,nil)
end


local sfofl_yufeng_skill = {}
sfofl_yufeng_skill.name = "sfofl_yufeng"
table.insert(sgs.ai_skills,sfofl_yufeng_skill)
sfofl_yufeng_skill.getTurnUseCard = function(self,inclusive)
	if #self.enemies == 0 then return end	
	return sgs.Card_Parse("#sfofl_yufeng:.:")	
end

sgs.ai_skill_use_func["#sfofl_yufeng"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_priority["sfofl_yufeng"] = 0
sgs.ai_use_value["sfofl_yufeng"] = 2.5

sgs.ai_skill_playerchosen.sfofl_yufeng = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if self:isEnemy(target) then
            return target
        end
    end
    return targets[math.random(1, #targets)]
end
sgs.ai_playerchosen_intention.sfofl_yufeng = 80


sgs.ai_skill_discard.sfofl_tianshu = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)

	table.insert(to_discard, cards[1]:getEffectiveId())
	if #to_discard > 0 then
		return to_discard
	end

	return {}
end

sgs.ai_skill_playerchosen.sfofl_tianshu = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if self:isFriend(target) and self:loseEquipEffect(target) then
            return target
        end
    end
    for _, target in ipairs(targets) do
        if self:isFriend(target) then
            return target
        end
    end
    return nil
end
sgs.ai_playerchosen_intention.sfofl_tianshu = -80


local sfofl_zhengjing_skill = {}
sfofl_zhengjing_skill.name = "sfofl_zhengjing"
table.insert(sgs.ai_skills,sfofl_zhengjing_skill)
sfofl_zhengjing_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#sfofl_zhengjing:.:")	
end

sgs.ai_skill_use_func["#sfofl_zhengjing"] = function(card,use,self)
	self:sort(self.friends, "defense")
	for _, target in ipairs(self.friends) do
		if self:canDraw(target, self.player) and target:getJudgingArea():length()>0 then
			use.card = card
			use.to:append(target)
			return
		end
	end
	for _, target in ipairs(self.friends) do
		if target:getJudgingArea():length()>0 then
			use.card = card
			use.to:append(target)
			return
		end
	end
	for _, target in ipairs(self.friends) do
		if self:canDraw(target, self.player) then
			use.card = card
			use.to:append(target)
			return
		end
	end
end



local sfofl_juezhi_skill = {}
sfofl_juezhi_skill.name = "sfofl_juezhi"
table.insert(sgs.ai_skills,sfofl_juezhi_skill)
sfofl_juezhi_skill.getTurnUseCard = function(self)
	sgs.ai_use_priority.sfofl_juezhi = 3
	if self.player:getCardCount(true)<2 then return false end
	if self:getOverflow()<=0 then return false end
	if self:isWeak() and self:getOverflow()<=1 then return false end
	return sgs.Card_Parse("#sfofl_juezhi:.:")
end
sgs.ai_skill_use_func["#sfofl_juezhi"] = function(card,use,self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)

	local red_num,black_num = 0,0
	if self.player:getHp()<3 then
		local zcards = self.player:getCards("he")
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _,zcard in sgs.qlist(zcards)do
			if self.player:isCardLimited(zcard,sgs.Card_MethodDiscard) then continue end
			if not isCard("Peach",zcard,self.player) and not isCard("ExNihilo",zcard,self.player) then
				local shouldUse = true
				if isCard("Slash",zcard,self.player) and not use_slash then
					local dummy_use = dummy()
					self:useBasicCard(zcard,dummy_use)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.qlist(dummy_use.to)do
								if p:getHp()<=1 then
									shouldUse = false
									if self.player:distanceTo(p)>1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length()>1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId()==sgs.Card_TypeTrick then
					local dummy_use = dummy()
					self:useTrickCard(zcard,dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId()==sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = dummy()
					self:useEquipCard(zcard,dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId()==keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasTreasure("wooden_ox") then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp()==1 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then
					if (table.contains(unpreferedCards,zcard:getId())) then continue end
					table.insert(unpreferedCards,zcard:getId())
					if self.room:getCardPlace(zcard:getId())==sgs.Player_PlaceHand then
						if zcard:isRed() then red_num = red_num+1
						else black_num = black_num+1 end
					end
				end
				if #unpreferedCards==2 then
					use.card = sgs.Card_Parse("#sfofl_juezhi:"..table.concat(unpreferedCards,"+")..":")
					return
				end
			end
		end
	end

	local red = self:getSuitNum("red")
	local black = self:getSuitNum("black")
	if red-red_num<=2-#unpreferedCards then
		for _,c in ipairs(cards)do
			if c:isRed() and (not isCard("Peach",c,self.player) or not self:findFriendsByType(sgs.Friend_Weak) and #cards>1) then
				if self.player:isCardLimited(c,sgs.Card_MethodDiscard) then continue end
				if table.contains(unpreferedCards,c:getId()) then continue end
				table.insert(unpreferedCards,c:getId())
			end
		end
	elseif black-black_num<=2-#unpreferedCards then
		for _,c in ipairs(cards)do
			if c:isBlack() and (not isCard("Peach",c,self.player) or not self:findFriendsByType(sgs.Friend_Weak) and #cards>1) then
				if self.player:isCardLimited(c,sgs.Card_MethodDiscard) then continue end
				if table.contains(unpreferedCards,c:getId()) then continue end
				table.insert(unpreferedCards,c:getId())
			end
		end
	end

	if #unpreferedCards<2 then
		for _,c in ipairs(cards)do
			if not self.player:isCardLimited(c,sgs.Card_MethodDiscard) then
				if table.contains(unpreferedCards,c:getId()) then continue end
				table.insert(unpreferedCards,c:getId())
			end
			if #unpreferedCards==2 then break end
		end
	end

	if #unpreferedCards==2 then
		use.card = sgs.Card_Parse("#sfofl_juezhi:"..table.concat(unpreferedCards,"+")..":")
		sgs.ai_use_priority.sfofl_juezhi = 0
		return
	end

end

sgs.ai_use_priority.sfofl_juezhi = 3

sgs.ai_skill_askforag.sfofl_juezhi = function(self,card_ids)
	for _,id in ipairs(card_ids)do
		local card = sgs.Sanguosha:getCard(id)
		if self.player:getMark("&xingtu") == card:getNumber() then
			return id
		end
		if self.player:getMark("&xingtu") % card:getNumber() == 0 then
			return id
		end
	end
end

sgs.ai_skill_invoke.sfofl_xiaofan_damage = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isEnemy(damage.to) then
		if not self:cantbeHurt(damage.to) and self:canDamage(damage.to,self.player,nil) and self:damageIsEffective(damage.to, sgs.DamageStruct_Normal, self.player) then
			return true
		end
	end
	if damage.to:objectName() == self.player:objectName() then
		if not self:damageIsEffective(damage.to, sgs.DamageStruct_Normal, self.player) or self:needToLoseHp(damage.to,self.player,nil) then
			return true
		end
		if not self:isWeak() then
			return math.random() < 0.5
		end
	end
	return false
end

sgs.ai_ajustdamage_from.sfofl_huoluan = function(self, from, to, card, nature)
    if from:getKingdom() == "qun" and to:getKingdom() == "qun"
    then
        return 1
    end
end
sgs.ai_ajustdamage_to.sfofl_huoluan = function(self, from, to, card, nature)
    if from:getKingdom() == "qun" and to:getKingdom() == "qun"
    then
        return 1
    end
end

sgs.ai_skill_playerchosen.sfofl_anmou = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if self:isEnemy(target) then
            return target
        end
    end
    return targets[math.random(1, #targets)]
end

sgs.ai_ajustdamage_from.sfofl_tousuan = function(self, from, to, card, nature)
    if to:getMark("sfofl_anmou"..from:objectName()) > 0
    then
        return 1
    end
end
sgs.ai_ajustdamage_to.sfofl_tousuan = function(self, from, to, card, nature)
    if from:getMark("sfofl_anmou"..to:objectName()) > 0
    then
        return 1
    end
end



addAiSkills("sfofl_qianjing").getTurnUseCard = function(self)
	if self.player:hasSkill("sfofl_bianchi") and self.player:getMark("@sfofl_bianchi") > 0 then return end
	local cards = {}
  	for i,p in sgs.list(self.room:getAlivePlayers())do
		for d,c in sgs.list(p:getCards("ej"))do
			if c:isKindOf("sfofl_xingbian")
			then table.insert(cards,c) end
		end
	end
	self:sortByKeepValue(cards,nil,"l")
  	for _,c in sgs.list(cards)do
		local dc = dummyCard()
		dc:setSkillName("sfofl_qianjing")
		dc:addSubcard(c)
		local d = self:aiUseCard(dc)
		if d.card and d.to
		and dc:isAvailable(self.player)
		then
			self.sfofl_qianjing_to = d.to
			sgs.ai_use_priority.sfofl_qianjing = sgs.ai_use_priority.Slash+0.6
			return sgs.Card_Parse("#sfofl_qianjing:"..c:getEffectiveId()..":slash")
		end
	end
end

sgs.ai_skill_use_func["#sfofl_qianjing"] = function(card,use,self)
	if self.sfofl_qianjing_to
	then
		use.card = card
		use.to = self.sfofl_qianjing_to
	end
end

sgs.ai_use_value.sfofl_qianjing = 5.4
sgs.ai_use_priority.sfofl_qianjing = 2.8


sgs.ai_skill_use["@@sfofl_qianjing"] = function(self, prompt)
	local use_card
	local target
	local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
	
    for _, c in ipairs(cards) do
		if c:isKindOf("sfofl_xingbian") then
			use_card = c
			break
		end
	end
	if use_card then
		local n = use_card:getRealCard():toEquipCard():location()
		if self.player:hasSkill("sfofl_bianchi") and self.player:getMark("@sfofl_bianchi") > 0 then
			self:sort(self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasEquipArea(n) and enemy:getEquip(n)==nil then
					target = enemy
					break
				end
			end
		end
		if not target then
			for _, enemy in ipairs(self.enemies) do
				if enemy:hasEquipArea(n) and enemy:getEquip(n)==nil and not self:loseEquipEffect(enemy) then
					target = enemy
					break
				end
			end
		end
		if not target then
			if self.player:hasEquipArea(n) and self.player:getEquip(n)==nil then
				target = self.player
			end
		end
	end
	if use_card and target then
		return "#sfofl_qianjingEquipCard:".. use_card:getEffectiveId()..":->"..target:objectName()
	end
	return "."
end

sgs.ai_card_priority.sfofl_qianjing = function(self,card)
	if card:getSkillName()=="sfofl_qianjing"
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end


sgs.ai_use_revises.sfofl_qianjing = function(self,card,use)
	if card:isKindOf("sfofl_xingbian") then return false end
	-- if card:isKindOf("sfofl_xingbian") and (self.player:hasSkill("sfofl_huying") or self:getOverflow() == 0) then return false end
end
sgs.ai_skill_invoke.sfofl_bianchi = function(self, data)
	local x = 0
	for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		for _,card in sgs.qlist(p:getCards("e")) do
			if card:isKindOf("sfofl_xingbian") then
				if self:isEnemy(p) and (p:getHandcardNum() > 2 or self:isWeak(p) ) then
					return true
				end
				if self:isEnemy(p)  then
					x = x + 1
				end
			end
		end
	end
	if x >= 2 then
		return true
	end
	return false
end

sgs.ai_skill_choice.sfofl_bianchi = function(self, choices, data)
    local target = data:toPlayer()
	local usecard = getChoice(choices, "usecard")
	if usecard then
		if self.player:getHandcardNum() < 4 then
			return usecard
		end
		if self.player:getHp()+self:getAllPeachNum()-2<=0 then
			return usecard
		end
		return usecard
	end
	
	return "losehp"
end

sgs.ai_skill_use["@@sfofl_bianchi"] = function(self, prompt)
	if self.player:getMark("sfofl_bianchi-Clear") > 0 then return "." end
	local card_ids = self.player:getTag("sfofl_bianchiForAI"):toIntList()
	card_ids = sgs.QList2Table(card_ids)
	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("sfofl_bianchi") then
			target = p
			break
		end
	end
    for _, id in ipairs(card_ids) do
		if self.room:getCardPlace(id)==sgs.Player_PlaceHand then
			local c = sgs.Sanguosha:getCard(id)
			local dummy_use = self:aiUseCard(c,dummy())
			if dummy_use.card and dummy_use and dummy_use.to then
				local tos = {}
				for _,to in sgs.qlist(dummy_use.to) do
					if CanToCard(c,target,to) then
						table.insert(tos, to:objectName())
					end
				end
				return "#sfofl_bianchi:"..id..":->"..table.concat(tos, "+")
			end
		end
	end
    return "."
end

sgs.ai_skill_playerchosen._sfofl_xingbian = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if self:isEnemy(target) then
            return target
        end
    end
    return targets[math.random(1, #targets)]
end

sgs.ai_poison_card._sfofl_xingbian_weapon = function(self,c,player)
	return not player:hasEquip(c) and player:hasEquip() and not player:hasSkill("sfofl_qianjing")
end
sgs.ai_poison_card._sfofl_xingbian_armor = function(self,c,player)
	return not player:hasEquip(c) and player:hasEquip() and not player:hasSkill("sfofl_qianjing")
end
sgs.ai_poison_card._sfofl_xingbian_offensivehorse = function(self,c,player)
	return not player:hasEquip(c) and player:hasEquip() and not player:hasSkill("sfofl_qianjing")
end
sgs.ai_poison_card._sfofl_xingbian_defensivehorse = function(self,c,player)
	return not player:hasEquip(c) and player:hasEquip() and not player:hasSkill("sfofl_qianjing")
end
sgs.ai_poison_card._sfofl_xingbian_treasure = function(self,c,player)
	return not player:hasEquip(c) and player:hasEquip() and not player:hasSkill("sfofl_qianjing")
end

sgs.ai_skill_invoke.sfofl_changshi = true
sgs.ai_skill_playerchosen.sfofl_changshi = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if self:isEnemy(target) then
            return target
        end
    end
    return targets[math.random(1, #targets)]
end

addAiSkills("sfofl_taoluan").getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = self:sortByKeepValue(cards)
	for _,pc in sgs.list(RandomList(patterns()))do
		if self:getCardsNum(pc)>0 then continue end
		for _,c in sgs.list(cards)do
			local dc = dummyCard(pc)
			if dc:isKindOf("TrickCard") or dc:isKindOf("BasicCard") then
				dc:addSubcard(c:getEffectiveId())
				dc:setSkillName("sfofl_taoluan")
				local dummy_use = self:aiUseCard(dc, dummy())
				if dc:isAvailable(self.player) and dummy_use.card then
					local suit = c:getSuitString()
					local number = c:getNumberString()
					local card_id = c:getEffectiveId()
					local card_str = (pc..":sfofl_taoluan[%s:%s]=%d"):format(suit,number,card_id)
					local card = sgs.Card_Parse(card_str)
					assert(card)
					return card
				end
			end
		end
	end
end


sgs.ai_skill_invoke.sfofl_chiyan = function(self, data)
	local target = data:toPlayer()
	if self:isEnemy(target) then
		return true
	end
	return false
end

sgs.ai_ajustdamage_to["&sfofl_chiyan"] = function(self,from,to,card,nature)
	return 1
end

sgs.ai_skill_discard.sfofl_zimou = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	

	if self:needToLoseHp(self.player,nil, nil) then
		return {}
	end
	if not self:damageIsEffective(self.player,"N", nil) and not self:isFriend(self.room:getCurrent()) then
		return {}
	end
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
        table.insert(to_discard, card:getEffectiveId())
        break
	end
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end



local sfofl_picai_skill = {}
sfofl_picai_skill.name = "sfofl_picai"
table.insert(sgs.ai_skills,sfofl_picai_skill)
sfofl_picai_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_picai:.:")
end

sgs.ai_skill_use_func["#sfofl_picai"] = function(card,use,self)
	
	self:sort(self.enemies,"handcard")

	local targets = sgs.SPlayerList()
	for _,enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h") and not enemy:isKongcheng() then
			targets:append(enemy)
			if targets:length() >= self.player:getHp() then
				break
			end
		end
	end
	for _,friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "h") and not friend:isKongcheng() then
			if targets:length() >= self.player:getHp()  then
				break
			end
			targets:append(friend)
		end
	end
	if targets:length() > 0 then
		use.card = card
		use.to = targets
	end

end

sgs.ai_use_priority.sfofl_picai = sgs.ai_use_priority.Slash+0.1
sgs.ai_use_value.sfofl_picai = 8.5



sgs.ai_cardneed.sfofl_yaozhuo = sgs.ai_cardneed.bignumber

addAiSkills("sfofl_yaozhuo").getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_yaozhuo:.:")
end

sgs.ai_skill_use_func["#sfofl_yaozhuo"] = function(card,use,self)
	self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.sfofl_yaozhuo = 1.4
sgs.ai_use_priority.sfofl_yaozhuo = 5.8
sgs.ai_card_intention.sfofl_yaozhuo = 50
sgs.ai_skill_invoke.sfofl_yaozhuo = true

sgs.ai_skill_use["@@sfofl_yaozhuo"] = function(self, prompt)
	self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p) then
            return "#sfofl_yaozhuo:.:->"..p:objectName()
        end
    end
	return "."
end


local sfofl_kuiji_skill = {}
sfofl_kuiji_skill.name = "sfofl_kuiji"
table.insert(sgs.ai_skills,sfofl_kuiji_skill)
sfofl_kuiji_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#sfofl_kuiji:.:")
end

sgs.ai_skill_use_func["#sfofl_kuiji"] = function(card,use,self)
	if #self.enemies<=0 then return end
	local target = nil
	self:sort(self.enemies,"handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _,p in sgs.list(self.enemies)do
		if self:doDisCard(p,"h")
		then target = p	break end
	end
	if not target then return end
	self.sfofl_kuiji_target = nil
	if target:getHandcardNum()>0 then
		use.card = card
		self.sfofl_kuiji_target = target
		use.to:append(target)
	end
end

sgs.ai_skill_use["@@sfofl_kuiji"] = function(self,prompt)
	if self.sfofl_kuiji_target then
		local target_handcards = sgs.QList2Table(self.sfofl_kuiji_target:getCards("h"))
		self:sortByUseValue(target_handcards,inverse)
		local handcards = sgs.QList2Table(self.player:getCards("h"))
		local discard_cards = {}
		local spade_check = true
		local heart_check = true
		local club_check = true
		local diamond_check = true
		local target_discard_count = 0
		
		for _,c in sgs.list(target_handcards)do
			if spade_check and c:getSuit()==sgs.Card_Spade then
				spade_check = false
				table.insert(discard_cards,c:getEffectiveId())
			elseif heart_check and c:getSuit()==sgs.Card_Heart then
				heart_check = false
				table.insert(discard_cards,c:getEffectiveId())
			elseif club_check and c:getSuit()==sgs.Card_Club then
				club_check = false
				table.insert(discard_cards,c:getEffectiveId())
			elseif diamond_check and c:getSuit()==sgs.Card_Diamond then
				diamond_check = false
				table.insert(discard_cards,c:getEffectiveId())
			end
			target_discard_count = #discard_cards
		end
		
		for _,c in sgs.list(handcards)do
			if not c:isKindOf("Peach")
			and not c:isKindOf("Duel")
			and not c:isKindOf("Indulgence")
			and not c:isKindOf("SupplyShortage")
			and not (self:getCardsNum("Jink")==1 and c:isKindOf("Jink"))
			and not (self:getCardsNum("Analeptic")==1 and c:isKindOf("Analeptic")) then
				if spade_check and c:getSuit()==sgs.Card_Spade then
					spade_check = false
					table.insert(discard_cards,c:getEffectiveId())
				elseif heart_check and c:getSuit()==sgs.Card_Heart then
					heart_check = false
					table.insert(discard_cards,c:getEffectiveId())
				elseif club_check and c:getSuit()==sgs.Card_Club then
					club_check = false
					table.insert(discard_cards,c:getEffectiveId())
				elseif diamond_check and c:getSuit()==sgs.Card_Diamond then
					diamond_check = false
					table.insert(discard_cards,c:getEffectiveId())
				end
			end
		end
		if #discard_cards==4 and target_discard_count>1 then
			return "#sfofl_kuijidisCard:"..table.concat(discard_cards,"+")..":"
		end
	end
	return "."
end

sgs.ai_use_priority.sfofl_kuiji = 3
sgs.ai_use_value.sfofl_kuiji = 3
sgs.ai_card_intention.sfofl_kuiji = 50


sgs.ai_ajustdamage_from.sfofl_chihe = function(self,from,to,card,nature)
	if card and card:hasFlag("sfofl_chihe") then
		return 1
	end
end


sgs.ai_skill_invoke.sfofl_chihe = function(self,data)
	local use = data:toCardUse()
	if use.from:objectName() == self.player:objectName() then
		if self:isFriend(use.to:first()) then return false end
		return true
	else
		if use.from and self:isEnemy(use.from) then
			if not self:canLiegong(self.player, use.from) and (self:getCardsNum("Jink")>0 or self:hasEightDiagramEffect()) then
				return true
			end
			if self:ajustDamage(use.from,self.player,1,use.card) <= 0 then
				return true
			end
		end
	end

	return false
end

sgs.ai_skill_invoke.sfofl_niqu = function(self,data)
	local target = data:toPlayer()
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash:setSkillName("sfofl_niqu")
	local dummy_use = self:aiUseCard(slash, dummy(true, 0, self.room:getOtherPlayers(target)))
	if dummy_use.card and dummy_use and dummy_use.to and dummy_use.to:contains(target) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.sfofl_miaoyu = function(self,data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) then
		return true
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_miaoyu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end


local sfofl_xiaoluAttach_skill = {}
sfofl_xiaoluAttach_skill.name = "sfofl_xiaoluAttach"
table.insert(sgs.ai_skills, sfofl_xiaoluAttach_skill)
sfofl_xiaoluAttach_skill.getTurnUseCard = function(self, inclusive)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	if not cards[1] then return nil end
	local card_str = "#sfofl_xiaolu:" .. cards[1]:getEffectiveId() .. ":"
	local skillcard = sgs.Card_Parse(card_str)
	return skillcard
end

sgs.ai_skill_use_func["#sfofl_xiaolu"] = function(card, use, self)
	if self:needBear() then
		return
	end
	local targets = {}
	for _, friend in ipairs(self.friends) do
		if friend:hasSkill("sfofl_xiaolu") then
			if self.player:getMark("sfofl_xiaolu"..friend:objectName().."-PlayClear") == 0 then
				table.insert(targets, friend)
			end
		end
	end
	if #targets > 0 then --黄天己方
		use.card = card
		self:sort(targets, "defense")
		if use.to then
			use.to:append(targets[1])
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if enemy:hasSkill("sfofl_xiaolu") then
				if self.player:getMark("sfofl_xiaolu"..enemy:objectName().."-PlayClear") == 0 then
					table.insert(targets, enemy)
				end
			end
		end
		if #targets > 0 then
			self:sort(targets, "defense", true)
			for _, enemy in ipairs(targets) do
				use.card = card
				if use.to then
					use.to:append(enemy)
				end
				break
			end
			
		end
	end
end

sgs.ai_use_priority.sfofl_xiaolu = 3
sgs.ai_use_value.sfofl_xiaolu = 8.5


sgs.ai_skill_askforag.sfofl_xiaolu = function(self,card_ids)
	for _,id in ipairs(RandomList(card_ids))do
		local card = sgs.Sanguosha:getCard(id)
		local dummy_use = self:aiUseCard(card, dummy())
		if card:isAvailable(self.player) and dummy_use.card then
			return id
		end
	end
end

sgs.ai_skill_playerchosen.sfofl_xiaolu = function(self, targets)
	local card = sgs.Sanguosha:getCard(self.player:getMark("sfofl_xiaolu"))
	local use_card = sgs.Sanguosha:cloneCard(card:objectName(), sgs.Card_NoSuit, 0)
	use_card:setSkillName("sfofl_xiaolu")
	use_card:deleteLater()
	local dummy_use = self:aiUseCard(use_card, dummy())
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if dummy_use.to:contains(target) then
			return target
		end
    end
    return targets[math.random(1, #targets)]
end

sgs.ai_skill_invoke.sfofl_tianzel = function(self,data)
	return sgs.ai_skill_invoke.tianming(self,data)
end
sgs.ai_skill_discard.sfofl_tianzel = function(self,discard_num,min_num,optional,include_equip)
	return sgs.ai_skill_discard.tianming(self,discard_num,min_num,optional,include_equip)
end

sgs.ai_skill_playerchosen.sfofl_tianzel = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if self:isFriend(target) and self:canDraw(target) then
            return target
        end
    end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_tianzel = -40

local sfofl_zhaoyuan_skill = {}
sfofl_zhaoyuan_skill.name = "sfofl_zhaoyuan"
table.insert(sgs.ai_skills,sfofl_zhaoyuan_skill)
sfofl_zhaoyuan_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng()
	or self:needBear() then return end
	return sgs.Card_Parse("#sfofl_zhaoyuan:.:")
end

sgs.ai_skill_use_func["#sfofl_zhaoyuan"] = function(card,use,self)
	local count = 0
	local target
	for _,enemy in sgs.list(self.enemies)do
		if not enemy:isKongcheng() then count = count+1 end
	end
	if not target then
		self:sort(self.friends_noself,"defense")
		self.friends_noself = sgs.reverse(self.friends_noself)
		if count<1 then return end
		for _,friend in sgs.list(self.friends_noself)do
			if hasTuntianEffect(friend) and not hasManjuanEffect(friend) and not self:isWeak(friend) and self:canDraw(friend, self.player)
			then target = friend break end
		end
		if not target then
			for _,friend in sgs.list(self.friends_noself)do
				if self:canDraw(friend, self.player)
				then target = friend break end
			end
		end
	end
	if target then
		for _,c in sgs.list(self:addHandPile())do
			if isCard("Peach",c,self.player) and self.player:getHandcardNum()>1 and self.player:isWounded()
			and not self:needToLoseHp(self.player,nil,c)
			then use.card = c return end
		end
		card:addSubcards(self.player:getHandcards())
		use.card = card
		target:setFlags("AI_sfofl_zhaoyuanTarget")
		use.to:append(target)
	end
end

sgs.ai_use_priority.sfofl_zhaoyuan = 1.5
sgs.ai_card_intention.sfofl_zhaoyuan = 0
sgs.ai_playerchosen_intention.sfofl_zhaoyuan = 10

sgs.ai_skill_playerchosen.sfofl_zhaoyuan = function(self,targets)
	self:sort(self.enemies,"defense")
	local slash = dummyCard()
	for _,to in sgs.list(self.enemies)do
		if targets:contains(to) and self:slashIsEffective(slash,to,self.player) and not self:needToLoseHp(to,self.player,slash) and self.player:canPindian(to)
			and not self:needToLoseHp(to,self.player,slash) and not self:findLeijiTarget(to,50,self.player) then
			return to
		end
	end
	for _,to in sgs.list(self.enemies)do
		if targets:contains(to) and self.player:canPindian(to) then
			return to
		end
	end
end

function sgs.ai_skill_pindian.sfofl_zhaoyuan(minusecard,self,requestor,maxcard)
	local req
	if self.player:objectName()==requestor:objectName() then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if p:hasFlag("sfofl_zhaoyuanPindianTarget") then
				req = p
				break
			end
		end
	else
		req = requestor
	end
	local cards,maxcard = sgs.QList2Table(self.player:getHandcards()),nil
	local max_value = 0
	self:sortByKeepValue(cards)
	max_value = self:getKeepValue(cards[#cards])
	local function compare_func1(a,b)
		return a:getNumber()>b:getNumber()
	end
	local function compare_func2(a,b)
		return a:getNumber()<b:getNumber()
	end
	if self:isFriend(req) and self.player:getHp()>req:getHp() then
		table.sort(cards,compare_func2)
	else
		table.sort(cards,compare_func1)
	end
	for _,card in sgs.list(cards)do
		if max_value>7 or self:getKeepValue(card)<7 or card:isKindOf("EquipCard") then maxcard = card break end
	end
	return maxcard or cards[1]
end

sgs.ai_skill_invoke.sfofl_julian = true

sgs.ai_skill_use["@@sfofl_gezhi"] = function(self,prompt)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local discard = {}
    local types = {}
	for _, card in ipairs(cards) do
        if not table.contains(types,card:getType()) then
		    table.insert(discard, card:getEffectiveId())
		    table.insert(types, card:getType())
        end
	end
    
	if #discard == 3 then
		return "#sfofl_gezhi:".. table.concat(discard, "+") ..":"
	end
    return "."
end


sgs.ai_skill_choice.sfofl_gezhi = function(self, choices, data)
    local items = choices:split("+")
	if table.contains(items, "recover") then
		if self:isWeak() or math.random() < 0.3 then
			return "recover"
		end
	end
	if table.contains(items, "damage") then
		local targets = sgs.SPlayerList()
		for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if p:getMark("sfofl_gezhi"..self.player:objectName()) == 0 then
				targets:append(p)
			end
		end
		if targets:length() > 0 then
			if sgs.ai_skill_playerchosen.sfofl_gezhi(self, targets) ~= nil then
				return "damage"
			end
		end
	end
	
	return "RemoveFromHistory"
end

sgs.ai_skill_playerchosen.sfofl_gezhi = function(self,targets)
	return self:findPlayerToDamage(1,self.player,sgs.DamageStruct_Normal ,targets,true, 1)[1]
end

sgs.ai_card_priority.sfofl_gezhi = function(self,card,v)
	if self.player:hasFlag("sfofl_gezhi") and (card:isKindOf("Slash") or card:isKindOf("Analeptic"))
	then return 10 end
end

addAiSkills("sfofl_hefa").getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = self:sortByKeepValue(cards,nil,true)
	if #cards<1 then return end
	local ids = {}
   	local fs = dummyCard()
	fs:setSkillName("sfofl_hefa")
  	for _,c in sgs.list(cards)do
		if self:getKeepValue(c)>3
		or #ids>=#cards/2 then continue end
		table.insert(ids,c:getEffectiveId())
		fs:addSubcard(c)
	end
	if #ids<1 and #cards>1
	then
		table.insert(ids,cards[1]:getEffectiveId())
		fs:addSubcard(cards[1])
	end
	local dummy = self:aiUseCard(fs)
	if fs:isAvailable(self.player)
	and dummy.card
	and dummy.to
	and #ids>0
  	then
		ids = #ids>0 and table.concat(ids,"+") or "."
		return fs
	end
end


sgs.ai_skill_playerchosen.sfofl_huanlei = function(self,targets)
	return self:findPlayerToDamage(2,self.player,sgs.DamageStruct_Thunder,targets,true, 1)[1]
end

sgs.ai_playerchosen_intention.sfofl_huanlei = sgs.ai_playerchosen_intention.leiji


sgs.ai_skill_cardask["@sfofl_xiandaoz-card"]=function(self,data)
	local all_cards = self:addHandPile("he")
	if #all_cards<1 then return "." end
	local judge = data:toJudge()
	local needTokeep = judge.card:getSuit()~=sgs.Card_Spade and (not self.player:hasSkill("leiji") or judge.card:getSuit()~=sgs.Card_Club)
		and self:findLeijiTarget(self.player,50) and (self:getCardsNum("Jink")>0 or self:hasEightDiagramEffect()) and self:getFinalRetrial()==1
	if not needTokeep and judge.who:getPhase()<=sgs.Player_Judge
	and judge.who:containsTrick("lightning") and judge.reason~="lightning"
	then needTokeep = true end
	local keptspade = 0
	if needTokeep and self.player:hasSkills("nosleiji|tenyearleiji")
	then keptspade = 2 end
	local cards = {}
	for _,card in sgs.list(all_cards)do
		if card:isBlack() and not card:hasFlag("using") then
			if card:getSuit()==sgs.Card_Spade then keptspade = keptspade-1 end
			table.insert(cards,card)
		end
	end
	if #cards<1 or keptspade==1 then return "." end
	local card_id = self:getRetrialCardId(cards,judge,nil,true)
	if card_id<0 then return "." end
	if self:needRetrial(judge)
	or self:getUseValue(judge.card)>self:getUseValue(sgs.Sanguosha:getCard(card_id))
	then return card_id end
	return "."
end

sgs.ai_cardneed.sfofl_xiandaoz = sgs.ai_cardneed.guidao

sgs.ai_use_revises.sfofl_xiandaoz = function(self,card,use)
	if card:isKindOf("EquipCard")
	and card:isBlack()
	then
		local same = self:getSameEquip(card)
		if same and same:isBlack()
		then return false end
	end
end

sgs.ai_suit_priority.sfofl_xiandaoz = sgs.ai_suit_priority.guidao

sgs.ai_useto_revises.sfofl_xiandaoz = function(self,card,use,p)
	if card:isKindOf("Lightning")
	then
		if self:isFriend(p) and p:getCardCount()>2
		then use.card = card return end
		return false
	end
end

local sfofl_shenglv_skill = {}
sfofl_shenglv_skill.name = "sfofl_shenglv"
table.insert(sgs.ai_skills,sfofl_shenglv_skill)
sfofl_shenglv_skill.getTurnUseCard = function(self)
	local x = math.max(self.player:usedTimes("#sfofl_shenglv"), 0)
	if x > 0 and self:getCardsNum("Peach")+self.player:getHp()-x<=0 then return end
	if x > 0 and (self:isWeak() or self:needBear()) then return end
	if x > 0 and self:getOverflow() > 0 then return end
	if x > 1 then return end
	return sgs.Card_Parse("#sfofl_shenglv:.:")
end

sgs.ai_skill_use_func["#sfofl_shenglv"] = function(card,use,self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp()<3 then
		local use_slash,keep_jink,keep_analeptic,keep_weapon = false,false,false,nil
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _,zcard in sgs.list(self.player:getCards("h"))do
			if not isCard("Peach",zcard,self.player)
			then
				local shouldUse = true
				if isCard("Slash",zcard,self.player)
				and not use_slash
				then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _,p in sgs.list(dummy_use.to)do
								if p:getHp()<=1 then
									shouldUse = false
									if self.player:distanceTo(p)>1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length()>1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
						if not shouldUse then use_slash = true end
					end
				end
				if zcard:getTypeId()==sgs.Card_TypeTrick then
					if self:aiUseCard(zcard).card then shouldUse = false end
				end
				if zcard:getTypeId()==sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					if self:aiUseCard(zcard).card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId()==keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then shouldUse = false end
				if isCard("Jink",zcard,self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp()<2 and isCard("Analeptic",zcard,self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards,zcard:getId()) end
			end
		end
	end

	if #unpreferedCards<1 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _,card in ipairs(cards)do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num<=sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,card)
				then
					if self:aiUseCard(card).card then
						will_use = true
						use_slash_num = use_slash_num+1
					end
				end
				if not will_use then table.insert(unpreferedCards,card:getId()) end
			end
			if card:isKindOf("Peach") then
				table.insert(unpreferedCards,card:getId())
			end
		end

		local num = self:getCardsNum("Jink")-1
		if self.player:getArmor() then num = num+1 end
		if num>0 then
			for _,card in ipairs(cards)do
				if card:isKindOf("Jink") and num>0 then
					table.insert(unpreferedCards,card:getId())
					num = num-1
				end
			end
		end
		for _,card in ipairs(cards)do
			if card:isKindOf("Weapon") and self.player:getHandcardNum()<3
			or self:getSameEquip(card,self.player)
			or card:isKindOf("OffensiveHorse")
			or card:isKindOf("AmazingGrace")
			then table.insert(unpreferedCards,card:getId())
			elseif card:getTypeId()==sgs.Card_TypeTrick then
				if not self:aiUseCard(card).card then table.insert(unpreferedCards,card:getId()) end
			end
		end
	end
	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		use.card = sgs.Card_Parse("#sfofl_shenglv:"..table.concat(use_cards,"+")..":")
	end
end

sgs.ai_use_value.sfofl_shenglv = 9
sgs.ai_use_priority.sfofl_shenglv = 2.61
sgs.dynamic_value.benefit.sfofl_shenglv = true


function sgs.ai_cardneed.sfofl_shenglv(to,card)
	return not card:isKindOf("Jink")
end

sgs.ai_use_revises.sfofl_shenglv = function(self,card,use)
	if card:isKindOf("Weapon")
	and not card:isKindOf("Crossbow")
	and self:getSameEquip(card)
	and math.max(self.player:usedTimes("#sfofl_shenglv") - 1, 0) < 2
	then return false end
end



sgs.ai_card_priority.sfofl_jiang = function(self,card)
	if card:isRed()
	then return 1 end
end


sgs.ai_skill_invoke.sfofl_zhiyang = function(self,data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then return false end
	local max_card = self:getMaxCard()
	if max_card and max_card:getNumber() >= 10  then
		return true
	end
	return false
end

sgs.ai_skill_invoke.sfofl_cuanzun = true

sgs.ai_skill_playerchosen.sfofl_liufangc = sgs.ai_skill_playerchosen.fangzhu
sgs.ai_playerchosen_intention.sfofl_liufangc = sgs.ai_playerchosen_intention.fangzhu

sgs.ai_need_damaged.sfofl_liufangc = sgs.ai_need_damaged.fangzhu

local sfofl_liufangc_skill = {}
sfofl_liufangc_skill.name = "sfofl_liufangc"
table.insert(sgs.ai_skills,sfofl_liufangc_skill)
sfofl_liufangc_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_liufangc:.:")
end

sgs.ai_skill_use_func["#sfofl_liufangc"] = function(card,use,self)
	self:sort(self.friends_noself,"handcard")
	for _,friend in ipairs(self.friends_noself)do
		if not friend:faceUp() then
			use.card = card
			use.to:append(friend)
			return
		end
	end
	local n = self.player:getLostHp()
	for _,friend in ipairs(self.friends_noself)do
		if not self:toTurnOver(friend,n,"fangzhu") then
			use.card = card
			use.to:append(friend)
			return
		end
	end
	if n>=3 then
		local target = self:findPlayerToDraw(false,n)
		if target then return target end
		for _,enemy in ipairs(self.enemies)do
			if self:toTurnOver(enemy,n,"fangzhu") and hasManjuanEffect(enemy) then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	else
		self:sort(self.enemies)
		for _,enemy in ipairs(self.enemies)do
			if self:toTurnOver(enemy,n,"fangzhu") and hasManjuanEffect(enemy) then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if self:toTurnOver(enemy,n,"fangzhu") and enemy:hasSkills(sgs.priority_skill) then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
		for _,enemy in ipairs(self.enemies)do
			if self:toTurnOver(enemy,n,"fangzhu") then
				use.card = card
				use.to:append(enemy)
				return
			end
		end
	end
end

sgs.ai_use_priority.sfofl_liufangc = 1.5

sgs.ai_card_intention.sfofl_liufangc = function(self, card, from, tos)
	if hasManjuanEffect(tos[1]) then sgs.updateIntention(from,tos[1],80) end
	local intention = 80/math.max(from:getLostHp(),1)
	if not self:toTurnOver(tos[1],from:getLostHp()) then intention = -intention end
	if from:getLostHp()<3 then
		sgs.updateIntention(from,tos[1],intention)
	else
		sgs.updateIntention(from,tos[1],math.min(intention,-30))
	end
end

sgs.ai_skill_invoke.sfofl_xiongtu = true


sgs.ai_can_damagehp.sfofl_xiongtu = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end

sgs.ai_target_revises.sfofl_xiongtu = sgs.ai_target_revises.jianxiong


sgs.ai_skill_invoke.sfofl_fuxiang = function(self,data)
	if #self.friends==1 then return false end

	local cards = sgs.QList2Table(self.player:getHandcards())
	
	-- Then we need to find the card to be discarded
	local limit = self.player:getMaxCards()
	if self.player:isKongcheng() then return false end
	if self:getCardsNum("Peach")>=limit-2 and self.player:isWounded() then return false end

	local to_discard = nil

	self:sortByKeepValue(cards)
	if sgs.playerRoles.rebel==0 then
		local lord = self.room:getLord()
		if lord and self:isFriend(lord) then
			return true
		end
	end

	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
		return true
	end

	self:sort(self.friends_noself,"handcard")
	self.friends_noself = sgs.reverse(self.friends_noself)
	for _,target in ipairs(self.friends_noself)do
		if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|"..sgs.priority_skill.."|shensu")
			and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) then
			return true
		end
	end

	for _,target in ipairs(self.friends_noself)do
		if target:hasSkill("dawu") then
			local use = true
			for _,p in ipairs(self.friends_noself)do
				if p:getMark("&dawu")>0 then use = false break end
			end
			if use then
				return true
			end
		else
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen.sfofl_fuxiang = function(self,targets)
	local lord = self.room:getLord()
	if lord and self:isFriend(lord) and lord:objectName()~=self.player:objectName() then
		return lord
	end
	local AssistTarget = self:AssistTarget()
	if AssistTarget and not self:willSkipPlayPhase(AssistTarget) then
		return AssistTarget
	end
	self:sort(self.friends_noself,"chaofeng")
	for _,target in ipairs(self.friends_noself)do
		if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|"..sgs.priority_skill.."|shensu")
			and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) then
			return target
		end
	end
	for _,target in ipairs(self.friends_noself)do
		if target:hasSkill("dawu") then
			local use = true
			for _,p in ipairs(self.friends_noself)do
				if p:getMark("&dawu")>0 then use = false break end
			end
			if use then
				return target
			end
		else
			return target
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sfofl_fuxiang = -80


sgs.ai_target_revises.sfofl_lezong = sgs.ai_target_revises.xiangle


sgs.ai_skill_cardask["@sfofl_lezong"] = function(self,data, pattern, target)
	local use = data:toCardUse()
	if use.card:isKindOf("Slash") then
		if self:isFriend(target) and not self:findLeijiTarget(target,50,self.player) then return "." end
		local has_peach,has_analeptic,has_slash,has_jink
		for _,card in sgs.qlist(self.player:getHandcards())do
			if card:isKindOf("Peach") then has_peach = card
			elseif card:isKindOf("Analeptic") then has_analeptic = card
			elseif card:isKindOf("Slash") then has_slash = card
			elseif card:isKindOf("Jink") then has_jink = card
			end
		end

		if has_slash then return "$"..has_slash:getEffectiveId()
		elseif has_jink then return "$"..has_jink:getEffectiveId()
		elseif has_analeptic or has_peach then
			if getCardsNum("Jink",target,self.player)==0 and self.player:getMark("drank")>0 and self:getAllPeachNum(target)==0 then
				if has_analeptic then return "$"..has_analeptic:getEffectiveId()
				else return "$"..has_peach:getEffectiveId()
				end
			end
		else return "."
		end
	else
		if not self:isFriend(target) then
			return true
		end
	end
	return "."
end




local sfofl_renwang_skill = {}
sfofl_renwang_skill.name = "sfofl_renwang"
table.insert(sgs.ai_skills,sfofl_renwang_skill)
sfofl_renwang_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	return sgs.Card_Parse("#sfofl_renwang:.:")
end

sgs.ai_skill_use_func["#sfofl_renwang"] = function(card,use,self)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	local notFound = false
	for i = 1,self.player:getHandcardNum() do
		local h,friend = self:getCardNeedPlayer(cards)
		if h and friend then cards = self:resetCards(cards,h)
		else notFound = true break end
		if friend==self.player or not self.player:handCards():contains(h:getEffectiveId()) then continue end
		local canJijiang = self.player:hasLordSkill("jijiang") and friend:getKingdom()=="shu"
		if h:isAvailable(self.player)
		and (h:isKindOf("Slash") and not canJijiang or h:isKindOf("Duel") or h:isKindOf("Snatch") or h:isKindOf("Dismantlement")) then
			local dummy_use = self:aiUseCard(h)
			if dummy_use.card then
				if h:isKindOf("Slash") or h:isKindOf("Duel") then
					local t1 = dummy_use.to:first()
					if dummy_use.to:length()>1 then continue
					elseif t1:getHp()<2 or getCardsNum("Jink",t1,self.player)<1
					or t1:isCardLimited(dummyCard("jink"),sgs.Card_MethodResponse)
					then continue end
				elseif self:getEnemyNumBySeat(self.player,friend)>0 then
					local hasDelayedTrick
					for _,p in sgs.qlist(dummy_use.to)do
						if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p))
						then hasDelayedTrick = true break end
					end
					if hasDelayedTrick then continue end
				end
			end
		elseif h:isAvailable(self.player)
		and (h:isKindOf("Indulgence") or h:isKindOf("SupplyShortage"))
		and self:getEnemyNumBySeat(self.player,friend)>0
		and self:aiUseCard(h).card then continue end
		if #cards>1 then use.card = sgs.Card_Parse("#sfofl_renwang:"..h:getId().."+"..cards[1]:getId()..":")  end
		use.to:append(friend)
		return
	end
	if notFound and self.player:isWounded() and self:getOverflow()>0 then
		cards = self:sortByUseValue(self.player:getHandcards(),true)
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if not self:isFriend(p) and hasManjuanEffect(p) then
				local to_give = {}
				for _,h in ipairs(cards)do
					if not isCard("Peach,ExNihilo",h,self.player)
					then table.insert(to_give,h:getId()) end
					if #to_give>=2
					then break end
				end
				if #to_give==2 then
					use.card = sgs.Card_Parse("#sfofl_renwang:"..table.concat(to_give,"+")..":")
					use.to:append(p)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.sfofl_renwang = sgs.ai_use_value.RendeCard
sgs.ai_use_priority.sfofl_renwang = sgs.ai_use_priority.RendeCard

sgs.ai_card_intention.sfofl_renwang = sgs.ai_card_intention.RendeCard

sgs.dynamic_value.benefit.sfofl_renwang = true

sgs.ai_use_revises.sfofl_renwang = function(self,card,use)
	if self.player:getLostHp()>1 and self:findFriendsByType(sgs.Friend_Draw)
	and #self.friends_noself>0
	then
		if card:getTypeId()==1
		or card:getTypeId()==3 and self:getSameEquip(card)
		or card:getTypeId()==2 and not (card:targetFixed() and card:isDamageCard())
		then return false end
	end
	local xy = self:hasSkills("jieming|oljieming",self.friends_noself)
	if xy and card:isDamageCard() and self:getOverflow()<0
	and self:hasTrickEffective(card,xy,nil,use.to)
	and self:getAllPeachNum()>1
	then
		use.card = card
		use.to:append(xy)
	end
end

----
sgs.ai_skill_playerchosen.yingzhen = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) then
			return p
		end
	end
    for _,p in sgs.list(destlist)do
		if not self:isEnemy(p) then
			return p
		end
	end
end


sgs.ai_skill_invoke.yuanjue = function(self,data)
	return self:getOverflow()>0
end

sgs.ai_skill_invoke.aoyong = function(self,data)
	return self:canDraw() or self.player:isWounded()
end

sgs.ai_skill_choice.aoyong = function(self,choices,data)
	local items = choices:split("+")
	if table.contains(items,"aoyong2") and self:isWeak() then
		return "aoyong2"
	end
	if table.contains(items,"aoyong3") then
		for _,c in sgs.list(self.player:getHandcards())do
			if self:aiUseCard(c) then
				return "aoyong3"
			end
		end
	end
	if table.contains(items,"aoyong2") then
		return "aoyong2"
	end
	if table.contains(items,"aoyong1") then
		return "aoyong1"
	end
end

sgs.ai_skill_invoke.tongkai = function(self,data)
	local to = data:toPlayer()
	return not self:isEnemy(to)
end


sgs.ai_fill_skill.jiechu = function(self)
	return dummyCard("snatch","jiechu")
end

sgs.ai_skill_cardask["jiechu1"] = function(self,data)
	local use = data:toCardUse()
	if self.player:getMark(use.card:getSuitString().."daojueSuit")<1 then return "." end
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
		return dc:toString()
	end
    return "."
end



sgs.ai_skill_invoke.tuonan = function(self,data)
	return self:getCardsNum("Peach,Analeptic")+self.player:getHp()<1
end



-----------------------


local sfofl_zunwei_skill = {}
sfofl_zunwei_skill.name = "sfofl_zunwei"
table.insert(sgs.ai_skills,sfofl_zunwei_skill)
sfofl_zunwei_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_zunwei:.:")
end

sgs.ai_skill_use_func["#sfofl_zunwei"] = function(card,use,self)
	local recover_t,draw_t,equip_t = {},{},{}
	if self.player:getMark("sfofl_zunwei_handcard") == 0 and self:canDraw() then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if p:getHandcardNum()>self.player:getHandcardNum() then
				table.insert(draw_t,p)
			end
		end
	end
	if self.player:getMark("sfofl_zunwei_hp") == 0 and self.player:getLostHp()>0 then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if p:getHp()>self.player:getHp() then
				table.insert(recover_t,p)
			end
		end
	end
	if self.player:getMark("sfofl_zunwei_equip") == 0 and self.player:hasEquipArea() then
		for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
			if p:getEquips():length()>self.player:getEquips():length() then
				table.insert(equip_t,p)
			end
		end
	end
	if #recover_t==0 and #draw_t==0 and #equip_t==0 then return end
	
	if #recover_t>0 then self:sort(recover_t,"hp") recover_t = sgs.reverse(recover_t) end
	if #draw_t>0 then self:sort(draw_t,"handcard") draw_t = sgs.reverse(draw_t) end
	if #equip_t>0 then self:sort(equip_t,"equip") equip_t = sgs.reverse(equip_t) end
	
	if self:isWeak() then
		if #recover_t>0 then
			sgs.ai_use_priority.sfofl_zunwei = 10
			self.sfofl_zunwei = "recover"
			use.card = card
			use.to:append(recover_t[1])
			return
		end
		
		if #draw_t>0 then
			self.sfofl_zunwei = "draw"
			use.card = card
			use.to:append(draw_t[1])
			return
		end
		
		if #equip_t>0 then
			self.sfofl_zunwei = "equip"
			use.card = card
			use.to:append(equip_t[1])
			return
		end
	end
	
	if #recover_t>0 and recover_t[1]:getHp()-self.player:getHp()>=2 and self.player:getLostHp()>=2 then
		self.sfofl_zunwei = "recover"
		use.card = card
		use.to:append(recover_t[1])
		return
	end
		
	if #draw_t>0 and ((draw_t[1]:getHandcardNum()-self.player:getHandcardNum()>=2 and sgs.Slash_IsAvailable(self.player)) or
	draw_t[1]:getHandcardNum()-self.player:getHandcardNum()>=4) then
		self.sfofl_zunwei = "draw"
		use.card = card
		use.to:append(draw_t[1])
		return
	end
		
	if #equip_t>0 and equip_t[1]:getEquips():length()-self.player:getEquips():length()>=2 then
		self.sfofl_zunwei = "equip"
		use.card = card
		use.to:append(equip_t[1])
		return
	end
end

sgs.ai_use_priority.sfofl_zunwei = 0


sgs.ai_skill_choice.sfofl_zunwei = function(self, choices, data)
	local hp = getChoice(choices, "hp")
	local equip = getChoice(choices, "equip")
	local handcard = getChoice(choices, "handcard")
	local items = choices:split("+")
	if self.sfofl_zunwei then
		if self.sfofl_zunwei == "recover" and hp then
			return hp
		end
		if self.sfofl_zunwei == "draw" and handcard then
			return handcard
		end
		if self.sfofl_zunwei == "equip" and equip then
			return equip
		end
	end
    return items[math.random(1,#items)]
end




local sfofl_chongxu_skill = {}
sfofl_chongxu_skill.name = "sfofl_chongxu"
table.insert(sgs.ai_skills,sfofl_chongxu_skill)
sfofl_chongxu_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_chongxu:.:")
end

sgs.ai_skill_use_func["#sfofl_chongxu"] = function(card,use,self)
	use.card = card
	return
end
sgs.ai_use_priority["sfofl_chongxu"] = 10


local sfofl_miaojing={}
sfofl_miaojing.name="sfofl_miaojing"
table.insert(sgs.ai_skills,sfofl_miaojing)


sfofl_miaojing.getTurnUseCard=function(self)
	if not self.player:hasUsed("#sfofl_miaojing") then
		local player = self.player
		local slash_card ={}--杀
		local ex_card={}--无中生有
		local cards = self:addHandPile("he")
		cards = self:sortByUseValue(cards,true)
		
		local level = player:getMark("sfofl_chongxu_sfofl_miaojing")--根据标记进行分级
		
		if level ~= 2 then
			for _,card in ipairs(cards)do
				if card:isKindOf("Slash") then
					table.insert(slash_card,card)
				else
					if level == 0 then
						if card:isNDTrick() then
							table.insert(ex_card,card)
						end
					else
						if not card:isKindOf("BasicCard") then
							table.insert(ex_card,card)
						end
					end
				end
			end
			local miaojingpatterns = { "yj_stabs_slash", "ex_nihilo"}
			-- 优化卡牌选择逻辑
			if level == 1 then
				-- 当有同类型卡牌时优先选择价值较低的
				if #ex_card > 0 then	
					ex_card = self:sortByUseValue(ex_card, true)
					for c, pn in sgs.list(RandomList(miaojingpatterns)) do
						c = dummyCard(pn)
						c:setSkillName("sfofl_miaojing")
						local dummy_use = self:aiUseCard(c)
						if c:isAvailable(self.player) and dummy_use.card and dummy_use.to then
							self.sfofl_miaojing_to = dummy_use.to
							for _,card in ipairs(ex_card) do
								if not self:isValuableCard(card, self.player) then
									return sgs.Card_Parse("#sfofl_miaojing:"..card:getEffectiveId()..":")
								end
							end
							sgs.ai_use_priority.sfofl_miaojing = sgs.ai_use_priority.ExNihilo
							return sgs.Card_Parse("#sfofl_miaojing:"..ex_card[1]:getEffectiveId()..":")
						end
					end
				end
			else
				if #ex_card > 0 then
					for c, pn in sgs.list(RandomList(miaojingpatterns)) do
						c = dummyCard(pn)
						c:setSkillName("sfofl_miaojing")
						local dummy_use = self:aiUseCard(c)
						if c:isAvailable(self.player) and dummy_use.card and dummy_use.to then
							self.sfofl_miaojing_to = dummy_use.to
							ex_card = self:sortByUseValue(ex_card, true)
							sgs.ai_use_priority.sfofl_miaojing = sgs.ai_use_priority.ExNihilo
							return sgs.Card_Parse("#sfofl_miaojing:"..ex_card[1]:getEffectiveId()..":")
						end
					end
				end
			end
			
			if #slash_card > 0 then
				for c, pn in sgs.list(RandomList(miaojingpatterns)) do
					c = dummyCard(pn)
					c:setSkillName("sfofl_miaojing")
					local dummy_use = self:aiUseCard(c)
					if c:isAvailable(self.player) and dummy_use.card and dummy_use.to then
						self.sfofl_miaojing_to = dummy_use.to
						slash_card = self:sortByUseValue(slash_card, true)
						sgs.ai_use_priority.sfofl_miaojing = 3
						return sgs.Card_Parse("#sfofl_miaojing:"..slash_card[1]:getEffectiveId()..":")
					end
				end
			end
		
		else
			local miaojingpatterns = { "yj_stabs_slash", "ex_nihilo"}
			for c, pn in sgs.list(RandomList(miaojingpatterns)) do
        		c = dummyCard(pn)
				c:setSkillName("sfofl_miaojing")
				sgs.ai_use_priority.sfofl_miaojing = sgs.ai_use_priority[c:getClassName()]
				return c
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_miaojing"] = function(card, use, self)
	local player = self.player
	local level = player:getMark("sfofl_chongxu_sfofl_miaojing")--根据标记进行分级
	local userstring = card:toString()
	local room = self.room

	if level ~= 2 then
		local id = userstring:split(":")[3]
		local kind = sgs.Sanguosha:getCard(id)
		
		if kind:isKindOf("Slash") then
			use.card = card
			use.to = self.sfofl_miaojing_to
			return
		else
			use.card = card
			use.to:append(player)
		end
	end
	return
end

sgs.ai_use_value.sfofl_miaojing = 7
sgs.ai_use_priority.sfofl_miaojing = 4



sgs.ai_target_revises.sfofl_lianhua = function(to,card,self,use)
	if card:isKindOf("Slash") and to:getMark("sfofl_chongxu_sfofl_lianhua") == 2
	and self.player:getHandcardNum()-self:getCardsNum("Peach")<2
	then return true end
end

sgs.ai_skill_cardask["@sfofl_lianhua"] = function(self,data, pattern, target)
	local use = data:toCardUse()
	if self:isFriend(target) and not self:findLeijiTarget(target,50,self.player) then return "." end
	local has_peach,has_analeptic,has_slash,has_jink
	for _,card in sgs.qlist(self.player:getHandcards())do
		if card:isKindOf("Peach") then has_peach = card
		elseif card:isKindOf("Analeptic") then has_analeptic = card
		elseif card:isKindOf("Slash") then has_slash = card
		elseif card:isKindOf("Jink") then has_jink = card
		end
	end

	if has_slash then return "$"..has_slash:getEffectiveId()
	elseif has_jink then return "$"..has_jink:getEffectiveId()
	elseif has_analeptic or has_peach then
		if getCardsNum("Jink",target,self.player)==0 and self.player:getMark("drank")>0 and self:getAllPeachNum(target)==0 then
			if has_analeptic then return "$"..has_analeptic:getEffectiveId()
			else return "$"..has_peach:getEffectiveId()
			end
		end
	else
		for _,card in sgs.qlist(self.player:getHandcards())do
			if not card:isKindOf("BasicCard") then
				return "$"..card:getEffectiveId()
			end
		end
	end
	return "."
end

local sfofl_kannan_skill = {}
sfofl_kannan_skill.name = "sfofl_kannan"
table.insert(sgs.ai_skills,sfofl_kannan_skill)
sfofl_kannan_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#sfofl_kannan:.:")
end

sgs.ai_skill_use_func["#sfofl_kannan"] = function(card,use,self)
	local cards = sgs.CardList()
	local peach = 0
	for _,c in sgs.qlist(self.player:getHandcards())do
		if isCard("Peach",c,self.player) and peach<2 then
			peach = peach+1
		else
			cards:append(c)
		end
	end
	
	local min_card = self:getMinCard(self.player,cards)
	if min_card then
		local min_point = min_card:getNumber()
		if self.player:hasSkill("tianbian") and min_card:getSuit()==sgs.Card_Heart then min_point = 13 end
		if min_point<7 then
			self:sort(self.enemies,"handcard")
			for _,p in ipairs(self.enemies)do
				if p:getMark("sfofl_kannan"..self.player:objectName().."-PlayClear")>0 or not self.player:canPindian(p) then continue end
				self.sfofl_kannan_card = min_card
				use.card = sgs.Card_Parse("#sfofl_kannan:.:")
				use.to:append(p) 
				return
			end
		end
	end
	
	local max_card = self:getMaxCard(self.player,cards)
	if max_card then
		local max_point = max_card:getNumber()
		if self.player:hasSkill("tianbian") and max_card:getSuit()==sgs.Card_Heart then max_point = 13 end
		if max_point>=7 then
			self:sort(self.enemies,"handcard")
			for _,p in ipairs(self.enemies)do
				if p:getMark("sfofl_kannan"..self.player:objectName().."-PlayClear")>0 or not self.player:canPindian(p) or not self:doDisCard(p,"h",true) then continue end
				self.sfofl_kannan_card = max_card
				use.card = sgs.Card_Parse("#sfofl_kannan:.:")
				use.to:append(p) 
				return
			end
		end
		local slashcount = self:getCardsNum("Slash")
		self:sortByUseValue(cards, true)
		if slashcount > 0 and self.player:getMark("drank") == 0 then
			self:sort(self.friends_noself,"handcard")
			self.friends_noself = sgs.reverse(self.friends_noself)
			for _,p in ipairs(self.friends_noself)do
				if p:getMark("sfofl_kannan"..self.player:objectName().."-PlayClear")>0 or not self.player:canPindian(p) then continue end
				self.sfofl_kannan_card = max_card
				use.card = sgs.Card_Parse("#sfofl_kannan:.:")
				use.to:append(p) 
				return
			end
		end
	end
end

sgs.ai_use_priority.sfofl_kannan = 7
sgs.ai_use_value.sfofl_kannan = 7

function sgs.ai_skill_pindian.sfofl_kannan(minusecard,self,requestor)
	return self:isFriend(requestor) and self:getMaxCard() or ( self:getMinCard():getNumber()>6 and  minusecard or self:getMinCard() )
end

sgs.ai_ajustdamage_from.sfofl_kannan = function(self, from, to, card, nature)
    if to:getMark("sfofl_kannanAnaleptic-Clear") > 0 
    then
        return 1
    end
end

sgs.ai_skill_choice.sfofl_kannan = function(self, choices, data)
	local up = getChoice(choices, "up")
	local down = getChoice(choices, "down")
	local items = choices:split("+")
	local pindian = data:toPindian()
	local target
	if pindian.from==self.player then
		target = pindian.to
	elseif pindian.to==self.player then
		target = pindian.from
	end
	if self.player:getPhase() ~= sgs.Player_Play then
		if self:isFriend(target) then
			return down
		end
		return up
	end
	if pindian.reason == "sfofl_kannan" then
		if self:isFriend(target) then
			return up
		end
		if math.random() < 0.5 then
			return down
		end
		
		return up
	end
    return "cancel"
end


local sfofl_jianji_skill = {}
sfofl_jianji_skill.name = "sfofl_jianji"
table.insert(sgs.ai_skills,sfofl_jianji_skill)
sfofl_jianji_skill.getTurnUseCard = function(self,inclusive)
	if #self.friends_noself>0 then
		return sgs.Card_Parse("#sfofl_jianji:.:")
	end
end

sgs.ai_skill_use_func["#sfofl_jianji"] = function(card,use,self)
	self:sort(self.friends_noself,"handcard")
	for _,friend in ipairs(self.friends_noself)do
		if self:canDraw(friend) then
			use.card = card
			use.to:append(friend) 
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if not hasManjuanEffect(friend) then
			use.card = card
			use.to:append(friend) 
			return
		end
	end
	for _,friend in ipairs(self.friends_noself)do
		if not hasManjuanEffect(friend,true) then
			use.card = card
			use.to:append(friend) 
			return
		end
	end
end

sgs.ai_use_priority.sfofl_jianji = 7
sgs.ai_use_value.sfofl_jianji = 7
sgs.ai_card_intention.sfofl_jianji = -20


sgs.ai_skill_playerchosen.sfofl_jianji = function(self, targets)
	local card
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:hasFlag("sfofl_jianji") then
			card = c
			break
		end
	end
	if card then
		local use_card = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		use_card:setSkillName("sfofl_jianji")
		use_card:addSubcard(card)
		use_card:deleteLater()
		local dummy_use = self:aiUseCard(use_card)
		if dummy_use.card then
			for _, p in sgs.qlist(targets) do
				if dummy_use.to:contains(p) then
					return p
				end
			end
		end
	end
	return nil
end


sgs.ai_skill_discard.sfofl_fengpo = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Diamond then
        	table.insert(to_discard, card:getEffectiveId())
        end
	end
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end
sgs.ai_skill_choice.sfofl_fengpo = function(self, choices, data)
	local use = data:toCardUse()
	local draw = getChoice(choices, "sfofl_fengpo1")
	local damage = getChoice(choices, "sfofl_fengpo2")
	local target = use.to:first()
	if self:isEnemy(target) then
		if self:ajustDamage(use.from,target,1,use.card)>0 and not self:cantDamageMore(use.from, target) and not self:cantbeHurt(target) and self:canDamage(target,self.player,use.card) and self:canHit(target,use.from,true) then
			return damage
		end
	end
	return draw
end
sgs.ai_ajustdamage_from.sfofl_fengpo = function(self, from, to, card, nature)
    if card and card:getTag("sfofl_fengpo"):toInt() > 0
    then
        return card:getTag("sfofl_fengpo"):toInt()
    end
end

local sfofl_duliang_skill = {}
sfofl_duliang_skill.name = "sfofl_duliang"
table.insert(sgs.ai_skills,sfofl_duliang_skill)
sfofl_duliang_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_duliang:.:")
end

sgs.ai_skill_use_func["#sfofl_duliang"] = function(card,use,self)
	local friends,enemies,others = {},{},{}
	for _,player in sgs.qlist(self.room:getOtherPlayers(self.player))do		
		if not player:isKongcheng() and self:isFriend(player) then
			table.insert(friends,player)
		elseif self:isEnemy(player) and self:doDisCard(player,"h") then
			table.insert(enemies,player)
		elseif not player:isKongcheng() then
			table.insert(others,player)
		end
	end
	
	if #friends==0 and #enemies==0 and #others==0 then return end
	local target
	self:sort(friends,"handcard")
	friends = sgs.reverse(friends)
	
	for _,friend in ipairs(friends)do
		if self:needToThrowCard(friend,"h") or friend:hasSkill("tuxi") then
			target = friend
			break
		end
	end
	
	if not target then
		self:sort(enemies,"defense")
		for _,enemy in ipairs(enemies)do
			if hasManjuanEffect(enemy) then
				target = enemy
				break
			end
		end
	end
	
	if not target then
		for _,enemy in ipairs(enemies)do
			if enemy:hasSkills(sgs.dont_kongcheng_skill) then
				target = enemy
				break
			end
		end
	end
	
	for _,enemy in ipairs(enemies)do
		if enemy:hasSkills(sgs.notActive_cardneed_skill) or self:isWeak(enemy) then
			target = enemy
			break
		end
	end
	
	if not target then
		for _,enemy in ipairs(enemies)do
			target = enemy
			break
		end
	end
	
	if not target then
		for _,other in ipairs(others)do
			target = other
			break
		end
	end
	
	if not target then
		for _,friend in ipairs(friends)do
			target = friend
			break
		end
	end
	if not target then return end
	use.card = sgs.Card_Parse("#sfofl_duliang:.:")
	use.to:append(target)
end

sgs.ai_use_priority.sfofl_duliang = 7

sgs.ai_skill_playerchosen.sfofl_zhuitao = sgs.ai_skill_playerchosen.zhuitao


sgs.ai_skill_invoke.sfofl_xingshang = sgs.ai_skill_invoke.mobilexingshang

sgs.ai_skill_invoke.sfofl_xingshanglord = function(self,data)
	if sgs.ai_skill_choice.mobilexingshang(self, "get+recover", data) == "recover" then return true end
	return false
end

sgs.ai_skill_playerchosen.sfofl_fangzhu = function(self,targets)
	return sgs.ai_skill_playerchosen.fangzhu(self,targets)
end

sgs.ai_skill_discard.sfofl_fangzhu = function(self,discard_num,min_num,optional,include_equip)
	if not self.player:faceUp() or self:needBear() then return {} end
	if self.player:getCardCount()-discard_num<=2 and self.player:getHp()<=2 then return {} end
	if (self.player:getHp()>1 or hasBuquEffect(self.player) or self:getSaveNum(true)>0) and discard_num <= 2 and math.random() < 0.8 then
		return self:askForDiscard("dummy",discard_num,min_num,false,include_equip)
	end
	return {}
end

sgs.ai_playerchosen_intention.sfofl_fangzhu = function(self,from,to)
	return sgs.ai_playerchosen_intention.fangzhu(self,from,to)
end

sgs.ai_can_damagehp.sfofl_shengshen = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and to:getMark("&ny_10th_xingshen") < 6
end

sgs.ai_need_damaged.sfofl_fangzhu = function (self,attacker,player)
	if not player:hasSkill("sfofl_fangzhu") then return false end
	local enemies = self:getEnemies(player)
	if #enemies<1 then return false end
	self:sort(enemies,"defense")
	for _,enemy in ipairs(enemies)do
		if player:getLostHp()<1 and self:toTurnOver(enemy,player:getLostHp()+1) then
			return true
		end
	end
	local friends = self:getFriends(player,true)
	self:sort(friends,"defense")
	for _,friend in ipairs(friends)do
		if not self:toTurnOver(friend,player:getLostHp()+1) then return true end
	end
	return false
end


addAiSkills("sfofl_zhuren").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if c:getNumber()>6 and self.player:getWeapon()==nil
		then return sgs.Card_Parse("#sfofl_zhuren:"..c:getEffectiveId()..":") end
	end
  	for _,c in sgs.list(cards)do
		if c:getNumber()<6
		and self:getCardsNum("Slash")<1
		and sgs.Slash_IsAvailable(self.player)
		then return sgs.Card_Parse("#sfofl_zhuren:"..c:getEffectiveId()..":") end
	end
end

sgs.ai_skill_use_func["#sfofl_zhuren"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.sfofl_zhuren = 9.4
sgs.ai_use_priority.sfofl_zhuren = 4.8


sgs.ai_skill_cardask["@sfofl_xiying"] = function(self,data,pattern,prompt)
    if #self.enemies>0
	and self.player:getHandcardNum()>3
	then return true end
	return "."
end



local sfofl_miewu = {}
sfofl_miewu.name = "sfofl_miewu"
table.insert(sgs.ai_skills,sfofl_miewu)
sfofl_miewu.getTurnUseCard = function(self)
    for _,name in sgs.list(patterns())do
        local card = dummyCard(name)
        if card and card:isAvailable(self.player)
       	and card:isDamageCard() and (card:isKindOf("BasicCard") or card:isNDTrick()) then
			if self:getCardsNum(card:getClassName())>1 and #cards>1 then continue end
            card:setSkillName("sfofl_miewu")
         	local dummy = self:aiUseCard(card)
			if dummy.card
			then
				self.Miewudummy = dummy
				return sgs.Card_Parse("#sfofl_miewu:.:"..name)
			end
		end
	end
    for _,name in sgs.list(patterns())do
        local card = dummyCard(name)
        if card and card:isAvailable(self.player) then
			if self:getCardsNum(card:getClassName())>1 then continue end
			if (card:isKindOf("BasicCard") or card:isNDTrick()) then
				card:setSkillName("sfofl_miewu")
				local dummy = self:aiUseCard(card)
				if dummy.card then
					self.Miewudummy = dummy
					if card:canRecast() and dummy.to:length()<1 then continue end
					return sgs.Card_Parse("#sfofl_miewu:.:"..name)
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_miewu"] = function(card,use,self)
	use.card = card
	use.to = self.Miewudummy.to
end

sgs.ai_guhuo_card.sfofl_miewu = function(self,toname,class_name)
	if self.player:getMark("sfofl_miewu-Clear")>0 then return end
	if self.player:getMark("&mobilezhiwuku") < 1  then return end
	if self:getCardsNum(class_name)>0 then return end
	local dc = dummyCard(toname)
	if (not dc) then return end
	if dc:isKindOf("BasicCard") or dc:isNDTrick() then
   		return "#sfofl_miewu:.:"..toname
	end
	return
end

sgs.ai_use_revises.sfofl_miewu = function(self,card,use)
	if card:isKindOf("EquipCard")
	and self.player:getMark("&mobilezhiwuku")>2
	and self.player:getMark("sfofl_miewu-Clear")<1
	then return false end
end

sgs.ai_skill_invoke.sfofl_luoyi = sgs.ai_skill_invoke.luoyi

sgs.ai_ajustdamage_from["&sfofl_luoyi"] = function(self,from,to,card,nature)
	if card and (card:isKindOf("Duel") or card:isKindOf("Slash"))
	then return 1 end
end



local sfofl_rengong = {}
sfofl_rengong.name = "sfofl_rengong"
table.insert(sgs.ai_skills,sfofl_rengong)
sfofl_rengong.getTurnUseCard = function(self)
    local cards = sgs.QList2Table(self.player:getHandcards())
	for _, card in ipairs(cards) do
		if self:getUseValue(card) < sgs.ai_use_value.Dismantlement or self:getOverflow() > 0 then
			if not self:isWeak() then
				local same = false
				for _, id in sgs.qlist(self.player:getPile("sfofl_huangjin")) do
					local c = sgs.Sanguosha:getCard(id)
					if card:getNumber() == c:getNumber() then
						same = true
						break
					end
				end
				if not same then
					return sgs.Card_Parse("#sfofl_rengong:"..card:getId()..":")
				end
			else
				return sgs.Card_Parse("#sfofl_rengong:"..card:getId()..":")
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_rengong"] = function(card,use,self)
	use.card = card
end

sgs.ai_skill_playerchosen.sfofl_rengong = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if self:doDisCard(target, "he")  then
            return target
        end
    end
    return nil
end


sgs.ai_skill_playerchosen.sfofl_chedian = function(self,targets)
	return self:findPlayerToDamage(1,self.player,sgs.DamageStruct_Thunder,targets,true, 1)[1]
end

addAiSkills("sfofl_tiangong").getTurnUseCard = function(self)
	local cs = {}
	for _,id in sgs.list(self.player:getPile("sfofl_huangjin"))do
		table.insert(cs,sgs.Sanguosha:getCard(id))
	end
	return cs
end

function sgs.ai_cardsview.sfofl_tiangong(self,class_name,player)
	for _,id in sgs.list(player:getPile("sfofl_huangjin"))do
		if sgs.Sanguosha:getCard(id):isKindOf(class_name)
		then return id end
	end
end
sgs.ai_use_priority.sfofl_tiangong = 5

sgs.ai_target_revises.sfofl_mingshi = function(to,card)
	if card:isKindOf("NatureSlash") and to:getArmor() == nil
	then return true end
end

sgs.ai_skill_playerschosen.sfofl_fubo = function(self, targets, max, min)
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

local sfofl_n_linzhen_skill={}
sfofl_n_linzhen_skill.name="sfofl_n_linzhen"
table.insert(sgs.ai_skills,sfofl_n_linzhen_skill)
sfofl_n_linzhen_skill.getTurnUseCard=function(self,inclusive)
	--一般场景
	sgs.ai_use_priority.sfofl_n_linzhen = 6.8
	local losthp = isLord(self.player) and 0 or 1
	if ((self.player:getHp()>3 and self.player:getLostHp()<=losthp and self.player:getHandcardNum()>self.player:getHp())
		or (self.player:getHp()-self.player:getHandcardNum()>=2)) and not (isLord(self.player) and sgs.turncount<=1) then
		return sgs.Card_Parse("#sfofl_n_linzhen:.:")
	end
	local slash = dummyCard()
	if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")
	or self.player:hasSkill("paoxiao") then
		for _,enemy in ipairs(self.enemies)do
			if self.player:canSlash(enemy,slash,true) and self:slashIsEffective(slash,enemy)
				and not (enemy:hasSkill("kongcheng") and enemy:isKongcheng())
				and not (enemy:hasSkills("fankui|guixin") and not self.player:hasSkill("paoxiao"))
				and not enemy:hasSkills("fenyong|jilei|zhichi")
				and self:isGoodTarget(enemy,self.enemies,slash) and not self:slashProhibit(slash,enemy) and self.player:getHp()>1 then
				return sgs.Card_Parse("#sfofl_n_linzhen:.:")
			end
		end
	end
	if self.player:getHp()==1 and self:getCardsNum("Analeptic")>=1 then
		return sgs.Card_Parse("#sfofl_n_linzhen:.:")
	end

	--Suicide by sfofl_n_linzhen
	local nextplayer = self.player:getNextAlive()
	if self.player:getHp()==1 and self.player:getRole()~="lord" and self.player:getRole()~="renegade" then
		local to_death = false
		if self:isFriend(nextplayer) then
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
				if p:hasSkill("xiaoguo") and not self:isFriend(p) and not p:isKongcheng()
					and self.role=="rebel" and self.player:getEquips():isEmpty() then
					to_death = true
					break
				end
			end
			if not to_death and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkill("jieyin") and self.player:isMale() then return end
				if nextplayer:hasSkill("qingnang") then return end
			end
		end
		if self.player:getRole()=="rebel" and not self:isFriend(nextplayer) then
			if not self:willSkipPlayPhase(nextplayer) or nextplayer:hasSkill("shensu") then
				to_death = true
			end
		end
		local lord = getLord(self.player)
		if self.player:getRole()=="loyalist" then
			if lord and lord:getCards("he"):isEmpty() then return end
			if self:isEnemy(nextplayer) and not self:willSkipPlayPhase(nextplayer) then
				if nextplayer:hasSkills("noslijian|lijian") and self.player:isMale() and lord and lord:isMale() then
					to_death = true
				elseif nextplayer:hasSkill("quhu") and lord and lord:getHp()>nextplayer:getHp() and not lord:isKongcheng()
					and lord:inMyAttackRange(self.player) then
					to_death = true
				end
			end
		end
		if to_death then
			local caopi = self.room:findPlayerBySkillName("xingshang")
			if caopi and self:isEnemy(caopi) then
				if self.player:getRole()=="rebel" and self.player:getHandcardNum()>3 then to_death = false end
				if self.player:getRole()=="loyalist" and lord and lord:getCardCount(true)+2<=self.player:getHandcardNum() then
					to_death = false
				end
			end
			if #self.friends==1 and #self.enemies==1 and self.player:aliveCount()==2 then to_death = false end
		end
		if to_death then
			sgs.ai_use_priority.sfofl_n_linzhen = 0
			return sgs.Card_Parse("#sfofl_n_linzhen:.:")
		end
	end
end

sgs.ai_skill_use_func["#sfofl_n_linzhen"]=function(card,use,self)
	use.card=card
end

sgs.ai_use_priority.sfofl_n_linzhen = 6.8


local sfofl_nujian_skill={}
sfofl_nujian_skill.name="sfofl_nujian"
table.insert(sgs.ai_skills,sfofl_nujian_skill)
sfofl_nujian_skill.getTurnUseCard=function(self,inclusive)
	local cards = sgs.QList2Table(self.player:getHandcards())
	for _, card in ipairs(cards) do
		if card:isKindOf("EquipCard") then
			return sgs.Card_Parse("#sfofl_nujian:"..card:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#sfofl_nujian"]=function(card,use,self)
	use.card=card
end

sgs.ai_skill_playerchosen.sfofl_nujian = function(self, targets)
    targets = sgs.QList2Table(targets)
    for _, target in ipairs(targets) do
        if self:isFriend(target)  then
            return target
        end
    end
    return targets[1]
end

sgs.ai_cardsview["sfofl_nujianAttach"] = function(self,class_name,player)
	if class_name=="Slash" then
		for _, p in sgs.qlist(self.room:findPlayersBySkillName("sfofl_nujian")) do
			if not self:isEnemy(p) and p:getPile("sfofl_nujian_jian"):length() > 0 then
				return "#sfofl_nujianAttach:.:"
			end
		end
	end
end

sgs.ai_skill_invoke.sfofl_nujian = function(self,data)
	local target = data:toPlayer()
	return target and self:isFriend(target)
end
sgs.ai_use_revises.sfofl_nujian = function(self,card,use)
	if card:isKindOf("EquipCard") and card:isRed() then
		local same = self:getSameEquip(card)
		if same then return false end
	end
end
function sgs.ai_cardsview_valuable.sfofl_nujianAttach(self, class_name, player)
	if not class_name=="Slash" then return end
	if player:hasFlag("Global_sfofl_nujian_Failed") then return end
	for _, p in sgs.qlist(self.room:findPlayersBySkillName("sfofl_nujian")) do
	if p:getPile("sfofl_nujian_jian"):length() > 0 and self:isFriend(p) then return "#sfofl_nujianAttach:.:" end
	end
end

addAiSkills("sfofl_nujianAttach").getTurnUseCard = function(self)
	local dc = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	dc:setSkillName("_sfofl_nujian")
	dc:deleteLater()
	local dummy = self:aiUseCard(dc)
	if dummy.card then
		self.sfofl_nujianAttachdummy = dummy
		for _, p in sgs.qlist(self.room:findPlayersBySkillName("sfofl_nujian")) do
			if p:getPile("sfofl_nujian_jian"):length() > 0 and self:isFriend(p) and sgs.Slash_IsAvailable(self.player)	then return sgs.Card_Parse("#sfofl_nujianAttach:.:") 
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_nujianAttach"] = function(card,use,self)
	use.card = card
	use.to = self.sfofl_nujianAttachdummy.to
end

sgs.ai_use_revises.sfofl_2_xuezhan = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end

local sfofl_2_xuezhan_skill = {}
sfofl_2_xuezhan_skill.name = "sfofl_2_xuezhan"
table.insert(sgs.ai_skills,sfofl_2_xuezhan_skill)
sfofl_2_xuezhan_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("h")
	for _,id in sgs.qlist(self.player:getPile("sfofl_2_xuezhan")) do
		table.insert(cards, sgs.Sanguosha:getCard(id))
	end
	cards = self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)do
		if card:isKindOf("EquipCard") then
			local slash = dummyCard("duel")
			slash:addSubcard(card)
			slash:setSkillName("sfofl_2_xuezhan")
			if slash:isAvailable(self.player)
			then return slash end
		end
	end
end

sgs.ai_skill_playerchosen.sfofl_2_qizhen = sgs.ai_skill_playerchosen.zhongyong


sgs.ai_skill_invoke.sfofl_sizhan = function(self,data)
	local target = data:toPlayer()
	return target and self:isEnemy(target) and self:doDisCard(target, "h", true)
end
sgs.ai_skill_invoke.sfofl_huzhu = function(self,data)
	local target = data:toPlayer()
	return self:isFriend(target)
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_huzhu = function(self,player,promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.to then
		if promptlist[#promptlist]=="yes" then
			sgs.updateIntention(player,damage.to,-80)
		end
	end
end



local sfofl_kuishe_skill = {}
sfofl_kuishe_skill.name = "sfofl_kuishe"
table.insert(sgs.ai_skills, sfofl_kuishe_skill)
sfofl_kuishe_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#sfofl_kuishe")  then
		return sgs.Card_Parse("#sfofl_kuishe:.:")
	end
end

sgs.ai_skill_use_func["#sfofl_kuishe"] = function(card, use, self)
	if #self.enemies == 0 then return end
	self:sort(self.enemies, "handcard")
	local target
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he", true) then
			target = enemy
			break
		end
	end
	if target  then
		use.card = sgs.Card_Parse("#sfofl_kuishe:.:")
		if use.to then use.to:append(target) end
	end
end

sgs.ai_skill_playerchosen.sfofl_kuishe = function(self, targets)
	self:sort(self.friends_noself, "hp")
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend, self.player)  then
			return friend
		end
	end
    for _, friend in ipairs(self.friends_noself) do
		return friend
	end
    local targetlist=sgs.QList2Table(targets)
	return targetlist[1]
end
sgs.ai_playerchosen_intention.sfofl_kuishe = function(self, from, to)
	sgs.updateIntention(from, to, -50)
end


sgs.ai_ajustdamage_to.sfofl_liangying = function(self,from,to,slash,nature)
	if nature == "F"
	then return 1 end
end

sgs.ai_skill_playerchosen.sfofl_benxi = function(self, targets)
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if self:doDisCard(p, "ej") then
			return p
		end
	end
	return nil
end

local sfofl_yuanlue_skill = {}
sfofl_yuanlue_skill.name= "sfofl_yuanlue"
table.insert(sgs.ai_skills,sfofl_yuanlue_skill)
sfofl_yuanlue_skill.getTurnUseCard=function(self)
	return sgs.Card_Parse("#sfofl_yuanlue:.:")
end

sgs.ai_skill_use_func["#sfofl_yuanlue"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)
		then
			use.card = sgs.Card_Parse("#sfofl_yuanlue:.:")
			use.to:append(enemy)
			return
		end
	end
	
end

sgs.ai_use_value.sfofl_yuanlue = 2.5
sgs.ai_card_intention.sfofl_yuanlue = 80
sgs.dynamic_value.damage_card.sfofl_yuanlue = true

sgs.ai_skill_use["@@sfofl_wuduan"] = function(self,prompt)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		return "#sfofl_wuduan:"..card:getId()..":"
	end
	return "."
end

addAiSkills("sfofl_juezhan").getTurnUseCard = function(self)
	local cs = {}
	for _,id in sgs.list(self.player:getPile("sfofl_wuchaoliang"))do
		table.insert(cs,sgs.Sanguosha:getCard(id))
	end
	return cs
end

function sgs.ai_cardsview.sfofl_juezhan(self,class_name,player)
	for _,id in sgs.list(player:getPile("sfofl_wuchaoliang"))do
		if sgs.Sanguosha:getCard(id):isKindOf(class_name)
		then return id end
	end
end



local sfofl_rende_skill = {}
sfofl_rende_skill.name = "sfofl_rende"
table.insert(sgs.ai_skills,sfofl_rende_skill)
sfofl_rende_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#sfofl_rende:.:")
end

sgs.ai_skill_use_func["#sfofl_rende"] = function(card,use,self)
    self:sort(self.friends_noself, "defense")
    local need = {}
    for _,p in ipairs(self.friends_noself) do
        table.insert(need, p)
    end

    local give = 0 
    if #need == 0 then return end
    if #need == 1 then give = math.max(2, self.player:getHandcardNum() - self.player:getMaxCards()) end
    if #need > 1 then give = 2 end

    local cards = sgs.QList2Table(self.player:getCards("h"))
    self:sortByKeepValue(cards)
    local usecards = {}
    for _,cc in ipairs(cards) do
		if self:willUse(self.player,cc) then continue end
        table.insert(usecards, cc:getEffectiveId())
        give = give - 1
        if give <= 0 then break end
    end
    if give > 0 then return end
    local card_str = string.format("#sfofl_rende:%s:->%s", table.concat(usecards,"+"), need[1]:objectName())
    use.card = sgs.Card_Parse(card_str)
    if use.to then use.to:append(need[1]) end
end

sgs.ai_skill_choice["sfofl_rende"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then return items[1] end
    if self.player:getLostHp() > 1 then return "peach" end
    table.removeOne(items, "cancel")
    for _,pattern in ipairs(items) do
        local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
        local usec = {isDummy=true,to=sgs.SPlayerList()}
        self:useCardByClassName(card, usec)
        if usec.to and usec.to:length() > 0 then
            return pattern
        end
    end
    return "cancel"
end

sgs.ai_skill_use["@@sfofl_rende"] = function(self, prompt)
    local pattern = self.player:property("sfofl_rende"):toString()

    if pattern == "peach" or pattern == "analeptic" then
        return string.format("#sfofl_rende_basic:.:->%s", self.player:objectName())
    end

	local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
	card:setSkillName("sfofl_rende")
    local card = sgs.Sanguosha:cloneCard(pattern, sgs.Card_SuitToBeDecided, -1)
    local usec = {isDummy=true,to=sgs.SPlayerList()}
    self:useCardByClassName(card, usec)
    if usec.to and usec.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(usec.to) do
            table.insert(tos, to:objectName())
        end
        local card_str = string.format("#sfofl_rende_basic:.:->%s", table.concat(tos, "+"))
        return card_str
    end
    return "."
end

sgs.ai_use_priority.sfofl_rende = 8.8
sgs.ai_use_value.sfofl_rende = 10.8



sgs.ai_skill_cardask["@sfofl_lianzhou"] = function(self,data,pattern,target)
	if target and self:isFriend(target) then return "." end
	local damage = data:toDamage()
	if not self:damageStruct(damage) then
		return "."
	end

	return true
end

sgs.ai_ajustdamage_to.sfofl_lianzhou = function(self,from,to,card,nature)
	if card and card:isBlack() then
		if self:isFriend(to,from) then return -1
		else
			if from:objectName()~=self.player:objectName() then
				if from:getHandcardNum()<=2
				then return -1 end
			else
				if getKnownCard(from,self.player,"red")<1
				then return -1 end
			end
		end
	end
end


sgs.ai_skill_invoke.sfofl_pocheng = function(self,data)
	return sgs.ai_skill_playerchosen.sfofl_pocheng(self, self.room:getOtherPlayers(self.player)) ~= nil and not self.player:isNude()
end
sgs.ai_skill_playerchosen.sfofl_pocheng = function(self, targets)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
			return enemy
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_pocheng = 80

sgs.ai_skill_discard.sfofl_pocheng = function(self)
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
sgs.ai_skill_cardask["@sfofl_pocheng_target"] = function(self, data, pattern, target)
	if not self:damageIsEffective(self.player,nil,target) then return "." end
	if self:needToLoseHp(self.player,target,nil) then return "." end
	return true
end


sgs.ai_skill_use["@@sfofl_shoufan!"] = function(self, prompt, method)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:hasFlag("sfofl_shoufan") and card:isKindOf("EquipCard") then
			return "#sfofl_shoufan:"..card:getId()..":"
		end
	end
	for _, card in ipairs(cards) do
		if card:hasFlag("sfofl_shoufan") then
			return "#sfofl_shoufan:"..card:getId()..":"
		end
	end
	return "."
end
sgs.ai_skill_invoke.sfofl_shoufan = true
sgs.ai_skill_invoke.sfofl_shoufan_equip = function(self,data)
	local card = data:toCard()
	local dummy_use = self:aiUseCard(card)
	if dummy_use.card then
		return true
	end
	return false
end

sgs.ai_skill_use["@@sfofl_dunji"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:setSkillName("_sfofl_dunji")
	slash:deleteLater()
	local dummy_use = self:aiUseCard(slash, dummy())
	if dummy_use.to and dummy_use.to:length() > 0 then
        local tos = {}
        for _,to in sgs.qlist(dummy_use.to) do
            table.insert(tos, to:objectName())
        end
        return slash:toString().."->"..table.concat(tos, "+")
    end
	return "."
end

sgs.ai_ajustdamage_from.sfofl_jiedao = function(self,from,to,card,nature)
	if from:getMark("sfofl_jiedao_damage-Clear") == 0 and not beFriend(to,from)
	then return 1 end
end
sgs.ai_skill_invoke.sfofl_jiedao = function(self,data)
	local to = data:toDamage().to
	return self:isEnemy(to) and not self:cantDamageMore(self.player,to)
end


sgs.ai_skill_playerchosen.sfofl_qukui = function(self, targets)
	if self:isWeak() then return nil end
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if self:doDisCard(p, "hej") then
			return p
		end
	end
	return nil
end

sgs.ai_skill_invoke.sfofl_liefu = function(self,data)
	local target = data:toPlayer()
	if not self:isEnemy(target) then return false end

	if self.player:getHandcardNum()==1 then
		if (self:needKongcheng() or not self:hasLoseHandcardEffective()) and not self:isWeak() then return true end
		local card  = self.player:getHandcards():first()
		if card:isKindOf("Jink") or card:isKindOf("Peach") then return end
	end
	if self:doDisCard(target,"he",true,2) then return true end
end

local sfofl_bingman_skill={}
sfofl_bingman_skill.name="sfofl_bingman"
table.insert(sgs.ai_skills,sfofl_bingman_skill)
sfofl_bingman_skill.getTurnUseCard=function(self,inclusive)
	return sgs.Card_Parse("#sfofl_bingman:.:")
end

sgs.ai_skill_use_func["#sfofl_bingman"]=function(card,use,self)
	use.card=card
end
sgs.ai_use_priority.sfofl_bingman = 6.8

local sfofl_nanbing_skill = {}
sfofl_nanbing_skill.name = "sfofl_nanbing"
table.insert(sgs.ai_skills,sfofl_nanbing_skill)
sfofl_nanbing_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	if #self.toUse>=2 then return end
	local savage_assault = dummyCard("savage_assault")
	savage_assault:addSubcards(self.player:getHandcards())
	savage_assault:setSkillName("sfofl_nanbing")
	if not savage_assault:isAvailable(self.player) or self:getAoeValue(savage_assault)<=0 then return end
	local handcards = sgs.QList2Table(self.player:handCards())
	return savage_assault
end

local sfofl_zaizheng_skill={}
sfofl_zaizheng_skill.name="sfofl_zaizheng"
table.insert(sgs.ai_skills,sfofl_zaizheng_skill)
sfofl_zaizheng_skill.getTurnUseCard=function(self,inclusive)
	return sgs.Card_Parse("#sfofl_zaizheng:.:")
end

sgs.ai_skill_use_func["#sfofl_zaizheng"]=function(card,use,self)
	use.card=card
end

sgs.ai_use_priority.sfofl_zaizheng = 6.8

sgs.ai_skill_playerchosen.sfofl_zaizheng = function(self, targets)
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if self:doDisCard(p, "ej") then
			return p
		end
	end
	return nil
end

local sfofl_zhaoxin_skill={}
sfofl_zhaoxin_skill.name="sfofl_zhaoxin"
table.insert(sgs.ai_skills,sfofl_zhaoxin_skill)
sfofl_zhaoxin_skill.getTurnUseCard=function(self,inclusive)
	return sgs.Card_Parse("#sfofl_zhaoxin:.:")
end

sgs.ai_skill_use_func["#sfofl_zhaoxin"]=function(card,use,self)
	local good = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if self:damageIsEffective(p, nil, self.player) then
			if self:isFriend(p) and p:isKongcheng() then
				good = good - 1
				if self:isWeak(p) then
					good = good - 1
				end
			else
				good = good + 1
				if self:isWeak(p) then
					good = good + 1
				end
			end
		end
	end
	if good > 0 then
		use.card=card
	end
end

sgs.ai_skill_cardask["@sfofl_zhaoxin_target"] = function(self, data, pattern, target)
	if not self:damageIsEffective(self.player,nil,target) then return "." end
	if self:needToLoseHp(self.player,target,nil) then return "." end
	return true
end
sgs.ai_skill_playerchosen.sfofl_shidi = function(self, targets)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
			return enemy
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_shidi = 80

sgs.ai_skill_discard.sfofl_n_rengong = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		local num = {}
		for _,id in sgs.list(self.player:getPile("sfofl_huangjin"))do
			if not table.contains(num, sgs.Sanguosha:getCard(id):getNumber()) then
				table.insert(num, sgs.Sanguosha:getCard(id):getNumber())
			end
		end
		if not table.contains(num, c:getNumber()) then
			table.insert(to_discard, c:getEffectiveId())
			break
		end
	end
	if #to_discard > 0 then
		return to_discard
	end
	if self:isWeak() then
		return {cards[1]:getEffectiveId()}
	end
	return {}
end

sgs.ai_skill_invoke.sfofl_n_chedian = function(self,data)
	local target = data:toPlayer()
	if not self:isEnemy(target) then return false end
	if self:canDamage(target,self.player,nil) and self:damageIsEffective(target, sgs.DamageStruct_Thunder, self.player) then
		return true
	end
	return false
end


addAiSkills("sfofl_n_tiangong").getTurnUseCard = function(self)
	local cs = {}
	for _,id in sgs.list(self.player:getPile("sfofl_huangjin"))do
		table.insert(cs,sgs.Sanguosha:getCard(id))
	end
	return cs
end

function sgs.ai_cardsview.sfofl_n_tiangong(self,class_name,player)
	for _,id in sgs.list(player:getPile("sfofl_huangjin"))do
		if sgs.Sanguosha:getCard(id):isKindOf(class_name)
		then return id end
	end
end
sgs.ai_use_priority.sfofl_n_tiangong = 5

sgs.ai_skill_cardask["@sfofl_n_guishen-card"]=function(self,data)
	local all_cards = self:addHandPile("he")
	if #all_cards<1 then return "." end
	local judge = data:toJudge()
	local needTokeep = judge.card:getSuit()~=sgs.Card_Spade and (not self.player:hasSkill("leiji") or judge.card:getSuit()~=sgs.Card_Club)
		and self:findLeijiTarget(self.player,50) and (self:getCardsNum("Jink")>0 or self:hasEightDiagramEffect()) and self:getFinalRetrial()==1
	if not needTokeep and judge.who:getPhase()<=sgs.Player_Judge
	and judge.who:containsTrick("lightning") and judge.reason~="lightning"
	then needTokeep = true end
	local keptspade = 0
	if needTokeep and self.player:hasSkills("nosleiji|tenyearleiji")
	then keptspade = 2 end
	local cards = {}
	for _,card in sgs.list(all_cards)do
		if not card:hasFlag("using") then
			if card:getSuit()==sgs.Card_Spade then keptspade = keptspade-1 end
			table.insert(cards,card)
		end
	end
	if #cards<1 or keptspade==1 then return "." end
	local card_id = self:getRetrialCardId(cards,judge,nil,true)
	if card_id<0 then return "." end
	if self:needRetrial(judge)
	or self:getUseValue(judge.card)>self:getUseValue(sgs.Sanguosha:getCard(card_id))
	then return card_id end
	return "."
end

sgs.ai_view_as.sfofl_n_leiming = function(card,player,card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place~=sgs.Player_PlaceSpecial and card:getClassName()=="Slash" and not card:hasFlag("using") then
		return ("thunder_slash:sfofl_n_leiming[%s:%s]=%d"):format(suit,number,card_id)
	end
end

local sfofl_n_leiming_skill = {}
sfofl_n_leiming_skill.name = "sfofl_n_leiming"
table.insert(sgs.ai_skills,sfofl_n_leiming_skill)
sfofl_n_leiming_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile()
	local slash
	self:sortByUseValue(cards,true)
	for _,card in ipairs(cards)do
		if card:getClassName()=="Slash" then
			slash = card
			break
		end
	end
	if not slash then return nil end
	local dummy_use = dummy()
	self:useCardThunderSlash(slash,dummy_use)
	if dummy_use.card and dummy_use.to:length()>0 then
	else return nil end
	if slash then
		local suit = slash:getSuitString()
		local number = slash:getNumberString()
		local card_id = slash:getEffectiveId()
		local card_str = ("thunder_slash:sfofl_n_leiming[%s:%s]=%d"):format(suit,number,card_id)
		local mySlash = sgs.Card_Parse(card_str)
		assert(mySlash)
		return mySlash
	end
end
sgs.ai_skill_invoke.sfofl_n_leiming = true

sgs.ai_card_priority.sfofl_n_leiming = function(self,card)
	if card:getSkillName()=="sfofl_n_leiming"
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end


sgs.ai_skill_invoke.sfofl_n_luanjian = function(self,data)
	if self.player:getEquips():length() <= 2 then return true end
	return false
end

local sfofl_n_luanjian_skill = {}
sfofl_n_luanjian_skill.name = "sfofl_n_luanjian"
table.insert(sgs.ai_skills, sfofl_n_luanjian_skill)
sfofl_n_luanjian_skill.getTurnUseCard = function(self)
	local archery = sgs.Sanguosha:cloneCard("archery_attack")
	local first_found, second_found = false, false
	local first_card, second_card
	local x=0
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if  string.find(self.player:property("sfofl_n_luanjian"):toString(),card:getSuitString()) then
			x = x + 1
		end	
	end
	if self.player:getHandcardNum() + self.player:getPile("wooden_ox"):length()-x>1 then
		local cards = self.player:getHandcards()
		local same_suit = false
		cards = sgs.QList2Table(cards)
		
		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards ,sgs.Sanguosha:getCard(id))
			end
		end
		
		self:sortByKeepValue(cards)
		local useAll = false
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and not enemy:hasArmorEffect("vine") and not self:hasEightDiagramEffect(enemy) and self:damageIsEffective(enemy, nil, self.player)
				and self:isWeak(enemy) and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
			end
		end
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player) or isCard("ArcheryAttack", fcard, self.player))
			if useAll then fvalueCard = isCard("ArcheryAttack", fcard, self.player) end
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player) or isCard("ArcheryAttack", scard, self.player))
					if useAll then svalueCard = (isCard("ArcheryAttack", scard, self.player)) end
					if first_card ~= scard and not string.find(self.player:property("sfofl_n_luanjian"):toString(),scard:getSuitString()) and  not string.find(self.player:property("sfofl_n_luanjian"):toString(),first_card:getSuitString())
						and not svalueCard then

						local card_str = ("archery_attack:sfofl_n_luanjian[%s:%s]=%d+%d"):format("to_be_decided", 0, first_card:getId(), scard:getId())
						local archeryattack = sgs.Card_Parse(card_str)

						assert(archeryattack)

						local dummy_use = { isDummy = true }
						self:useTrickCard(archeryattack, dummy_use)
						if dummy_use.card then
							second_card = scard
							second_found = true
							break
						end
					end
				end
				if second_card then break end
			end
		end
	end

	if first_found and second_found then
		local first_id = first_card:getId()
		local second_id = second_card:getId()
		local card_str = ("archery_attack:sfofl_n_luanjian[%s:%s]=%d+%d"):format("to_be_decided", 0, first_id, second_id)
		local archeryattack = sgs.Card_Parse(card_str)
		assert(archeryattack)
		return archeryattack
	end
end

sgs.ai_skill_invoke.sfofl_n_xuezhan = function(self,data)
	if self.player:getEquips():length() <= 2 then return true end
	return false
end
local sfofl_n_xuezhan_skill = {}
sfofl_n_xuezhan_skill.name = "sfofl_n_xuezhan"
table.insert(sgs.ai_skills,sfofl_n_xuezhan_skill)
sfofl_n_xuezhan_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("h")
	cards = self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)do
		if card:isKindOf("EquipCard") then
			local slash = dummyCard("duel")
			slash:addSubcard(card)
			slash:setSkillName("sfofl_n_xuezhan")
			if slash:isAvailable(self.player)
			then return slash end
		end
	end
end

sgs.ai_skill_invoke.sfofl_n_jianbing = function(self,data)
	local damage = data:toDamage()
	if self:doDisCard(damage.to, "he", true) then return true end
	if self:isFriend(damage.to) and self:isWeak(damage.to) and getKnownCard(damage.to,self.player,"heart")>0 then return true end
	return false
end

sgs.ai_target_revises.sfofl_n_bishi = function(to,card)
	if card:isKindOf("Slash")
	then return true end
end


local sfofl_n_yangwu_skill={}
sfofl_n_yangwu_skill.name="sfofl_n_yangwu"
table.insert(sgs.ai_skills,sfofl_n_yangwu_skill)
sfofl_n_yangwu_skill.getTurnUseCard=function(self,inclusive)
	return sgs.Card_Parse("#sfofl_n_yangwu:.:")
end

sgs.ai_skill_use_func["#sfofl_n_yangwu"]=function(card,use,self)
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > self.player:getHandcardNum() and self:doDisCard(enemy, "h", true) then
			use.card=card
			use.to:append(enemy)
			return
		end
	end
	
end
sgs.ai_use_priority.sfofl_n_yangwu = 9.3




sgs.ai_skill_playerchosen.sfofl_n_lianji = function(self, targets)
	self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
		if self:canDraw(friend, self.player) then
			return friend
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_n_lianji = -40
sgs.ai_skill_invoke.sfofl_n_lianji = function(self,data)
	return self.player:getHp() < getBestHp(self.player)
end

sgs.ai_skill_playerchosen.sfofl_n_lianjiphase = function(self, targets)
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if self:getOverflow(enemy) > 0 then
			return enemy
		end
	end
	for _, friend in ipairs(self.friends) do
        for _,s in sgs.qlist(friend:getVisibleSkillList()) do
            local skillname = s:objectName()
            if (not s:isAttachedLordSkill()) and (not self.player:hasSkill(skillname)) then
                local translation = sgs.Sanguosha:translate(":"..skillname)
                if (string.find(translation,"结束阶段") or string.find(translation,"弃牌阶段") ) and string.find(translation,"你可以") then
                    return friend
                end
            end
        end
	end
	for _, friend in ipairs(self.friends) do
		if self:getOverflow(friend) == 0 then
			return friend
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.sfofl_n_lianjiphase = 40

local sfofl_n_moucheng_skill = {}
sfofl_n_moucheng_skill.name = "sfofl_n_moucheng"
table.insert(sgs.ai_skills, sfofl_n_moucheng_skill)

sfofl_n_moucheng_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local subcards = {}
	self:sortByUseValue(cards, true)
	local cardsq = {}
	for _, card in ipairs(cards) do
		if card:isBlack() then table.insert(cardsq, card) end
	end
	if #cardsq == 0 then return end
	if self:getKeepValue(cardsq[1]) > 18 then return end
	if self:getUseValue(cardsq[1]) > 12 then return end
	table.insert(subcards, cardsq[1]:getId())
	local card_str = "Collateral:sfofl_n_moucheng[to_be_decided:0]=" .. table.concat(subcards, "+")
	local AsCard = sgs.Card_Parse(card_str)
	assert(AsCard)
	return AsCard
end



local sfofl_n_duanji_skill = {}
sfofl_n_duanji_skill.name = "sfofl_n_duanji"
table.insert(sgs.ai_skills,sfofl_n_duanji_skill)
sfofl_n_duanji_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("h")
	cards = self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)do
		if card:isKindOf("EquipCard") then
			local slash = dummyCard("duel")
			slash:addSubcard(card)
			slash:setSkillName("sfofl_n_duanji")
			if slash:isAvailable(self.player)
			then return slash end
		end
	end
end

sgs.ai_skill_cardask["@sfofl_n_hujia"] = function(self, data, pattern, target, target2)	
	local target = data:toPlayer()
	if self:isFriend(target) then
		return true
	end
	return "."
end

sgs.ai_cardsview_valuable.sfofl_n_hujia = function(self, class_name, player)
	local current = self.room:getCurrent()
	local handcards = sgs.QList2Table(self.player:getCards("h"))
    local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash",
	}
	local name = classname2objectname[class_name]
    if not name then return end
	local had_card = nil
	for _, c in ipairs(handcards) do
		if c:isKindOf(name) then
			had_card = c
            break
		end
	end

	if name and not player:hasFlag("Global_sfofl_n_hujiaFailed") and had_card == nil  then
		return string.format("#sfofl_n_hujia:.:%s", name)
	end
end

sgs.ai_skill_discard.sfofl_n_liangying = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	table.insert(to_discard, cards[1]:getEffectiveId())
	if #to_discard > 0 then
		return to_discard
	end
	return {}
end
sgs.ai_skill_discard.sfofl_n_yuanlue = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in sgs.list(cards)do
		table.insert(to_discard, c:getEffectiveId())
		if #to_discard == 2 then
			return to_discard
		end
	end
	return {}
end

sgs.ai_skill_invoke.sfofl_n_yuanlue = true


local sfofl_n_yuanlue_skill={}
sfofl_n_yuanlue_skill.name="sfofl_n_yuanlue"
table.insert(sgs.ai_skills,sfofl_n_yuanlue_skill)
sfofl_n_yuanlue_skill.getTurnUseCard=function(self,inclusive)
	--一般场景
	sgs.ai_use_priority.sfofl_n_yuanlue = 6.8
	local losthp = isLord(self.player) and 0 or 1
	if ((self.player:getHp()>3 and self.player:getLostHp()<=losthp and self.player:getHandcardNum()>self.player:getHp())
		or (self.player:getHp()-self.player:getHandcardNum()>=2)) and not (isLord(self.player) and sgs.turncount<=1) then
		return sgs.Card_Parse("#sfofl_n_yuanlue:.:")
	end
	local slash = dummyCard()
	if self.player:getWeapon() and self.player:getWeapon():isKindOf("Crossbow")
	or self.player:hasSkill("paoxiao") then
		for _,enemy in ipairs(self.enemies)do
			if self.player:canSlash(enemy,slash,true) and self:slashIsEffective(slash,enemy)
				and not (enemy:hasSkill("kongcheng") and enemy:isKongcheng())
				and not (enemy:hasSkills("fankui|guixin") and not self.player:hasSkill("paoxiao"))
				and not enemy:hasSkills("fenyong|jilei|zhichi")
				and self:isGoodTarget(enemy,self.enemies,slash) and not self:slashProhibit(slash,enemy) and self.player:getHp()>1 then
				return sgs.Card_Parse("#sfofl_n_yuanlue:.:")
			end
		end
	end
	if self.player:getHp()==1 and self:getCardsNum("Analeptic")>=1 then
		return sgs.Card_Parse("#sfofl_n_yuanlue:.:")
	end

end

sgs.ai_skill_use_func["#sfofl_n_yuanlue"]=function(card,use,self)
	use.card=card
end

sgs.ai_use_priority.sfofl_n_yuanlue = 6.8

sgs.ai_ajustdamage_to.sfofl_n_cangchu = function(self,from,to,slash,nature)
	if nature == "F"
	then return 1 end
end

sgs.ai_skill_playerchosen.sfofl_n_xiying = function(self, targets)
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if self:doDisCard(p, "hej") then
			return p
		end
	end
	return nil
end

addAiSkills("sfofl_n_juezhan").getTurnUseCard = function(self)
	local cs = {}
	for _,id in sgs.list(self.player:getPile("sfofl_wuchaoliang"))do
		table.insert(cs,sgs.Sanguosha:getCard(id))
	end
	return cs
end

function sgs.ai_cardsview.sfofl_n_juezhan(self,class_name,player)
	for _,id in sgs.list(player:getPile("sfofl_wuchaoliang"))do
		if sgs.Sanguosha:getCard(id):isKindOf(class_name)
		then return id end
	end
end


addAiSkills("sfofl_n_juezhanAttach").getTurnUseCard = function(self)
	local cards = sgs.QList2Table(self.player:getPile("sfofl_wuchaoliang"))
	local to_use = {}
	for _, id in ipairs(cards) do
		table.insert(to_use, id)
		if #to_use >= 2 then break end
	end
	if #to_use ~= 2 then return end
	for _, pn in sgs.list(RandomList(patterns())) do
		local dc = dummyCard(pn)
		if (dc:isNDTrick() or dc:isKindOf("BasicCard")) and self.player:getMark("sfofl_n_juezhanAttach_guhuo_remove_"..pn.."-Clear") == 0  then
			dc:setSkillName("sfofl_n_juezhan")
			local dummy_use = self:aiUseCard(dc, dummy())
			if dc:isAvailable(self.player) and dummy_use.card then
				if dc:canRecast() and dummy_use.to:length()<1 then continue end
				self.sfofl_n_juezhan_to = dummy_use.to
				sgs.ai_use_priority.sfofl_n_juezhanAttach = sgs.ai_use_priority[dc:getClassName()]
				local card = sgs.Card_Parse("#sfofl_n_juezhanAttach:"..table.concat(to_use, "+") ..":"..pn)
				assert(card)
				return card
			end
		end
	end
end

sgs.ai_skill_use_func["#sfofl_n_juezhanAttach"] = function(card,use,self)
	if self.sfofl_n_juezhan_to
	then
		use.card = card
		use.to = self.sfofl_n_juezhan_to
	end
end

sgs.ai_use_value.sfofl_n_juezhanAttach = 5.4
sgs.ai_use_priority.sfofl_n_juezhanAttach = 2.8

sgs.ai_guhuo_card.sfofl_n_juezhanAttach = function(self, toname, class_name)
    if sgs.Sanguosha:getCurrentCardUseReason() ~= sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then return end
    if class_name and self:getCardsNum(class_name) > 0 then return end
    if self.player:getMark("sfofl_n_juezhanAttach_guhuo_remove_"..class_name.."-Clear") == 0  then return end
    local c = dummyCard(toname)
    c:setSkillName("sfofl_n_juezhan")
    if (not c) then return end
	if c:isKindOf("BasicCard") or c:isNDTrick() then
		local cards = sgs.QList2Table(self.player:getPile("sfofl_wuchaoliang"))
		local to_use = {}
		for _, id in ipairs(cards) do
			table.insert(to_use, id)
			if #to_use >= 2 then break end
		end
		if #to_use == 2 then
			return "#sfofl_n_juezhanAttach:"..table.concat(to_use, "+") ..":"..toname
		end
	end
end


sgs.ai_ajustdamage_to.sfofl_n_huoshen = function(self,from,to,slash,nature)
	if nature == "F"
	then return -99 end
end


local sfofl_n_zonghuo_skill={}
sfofl_n_zonghuo_skill.name="sfofl_n_zonghuo"
table.insert(sgs.ai_skills,sfofl_n_zonghuo_skill)
sfofl_n_zonghuo_skill.getTurnUseCard=function(self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	local card
	for _,acard in sgs.list(cards)do
		if acard:isRed() and not acard:isKindOf("Peach") and (self:getDynamicUsePriority(acard)<sgs.ai_use_value.FireAttack or self:getOverflow()>0) then
			if acard:isKindOf("Slash") and self:getCardsNum("Slash")==1 then
				local keep
				local dummy_use = dummy()
				self:useBasicCard(acard,dummy_use)
				if dummy_use.card and dummy_use.to and dummy_use.to:length()>0 then
					for _,p in sgs.qlist(dummy_use.to)do
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
	local card_str = ("fire_attack:sfofl_n_zonghuo[%s:%s]=%d"):format(suit,number,card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end
sgs.ai_skill_invoke.sfofl_n_zonghuo = function(self,data)
	local target = data:toPlayer()
	return self:doDisCard(target, "he")
end

local sfofl_n_fenyin_skill={}
sfofl_n_fenyin_skill.name="sfofl_n_fenyin"
table.insert(sgs.ai_skills,sfofl_n_fenyin_skill)
sfofl_n_fenyin_skill.getTurnUseCard=function(self,inclusive)
	return sgs.Card_Parse("#sfofl_n_fenyin:.:")
end

sgs.ai_skill_use_func["#sfofl_n_fenyin"]=function(card,use,self)
	local good = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player))do
		if self:damageIsEffective(p, sgs.DamageStruct_Fire, self.player) then
			if self:isFriend(p) and p:isKongcheng() then
				good = good - 1
				if self:isWeak(p) then
					good = good - 1
				end
			else
				good = good + 1
				if self:isWeak(p) then
					good = good + 1
				end
			end
		end
	end
	if good > 0 then
		use.card=card
	end
end

sgs.ai_ajustdamage_to.sfofl_n_fengshen = function(self,from,to,card,nature)
	if card and (card:isKindOf("Slash") or card:isKindOf("Duel"))
	then return -99 end
end

sgs.ai_skill_invoke.sfofl_n_jifeng = function(self,data)
	local target = data:toPlayer()
	return self:isFriend(target)
end

sgs.ai_choicemade_filter.skillInvoke.sfofl_n_jifeng = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end

local sfofl_n_tongchou_skill={}
sfofl_n_tongchou_skill.name="sfofl_n_tongchou"
table.insert(sgs.ai_skills,sfofl_n_tongchou_skill)
sfofl_n_tongchou_skill.getTurnUseCard=function(self,inclusive)
	return sgs.Card_Parse("#sfofl_n_tongchou:.:")
end

sgs.ai_skill_use_func["#sfofl_n_tongchou"]=function(card,use,self)
	use.card=card
end

sgs.ai_use_priority.sfofl_n_tongchou = 6.8



sgs.ai_skill_invoke.sfofl_n_chongsha = function(self,data)
	local target = data:toPlayer()
	if not self:isFriend(target) then return self:doDisCard(target, "he", true) end
	return false
end

sgs.ai_skill_playerchosen.sfofl_n_tuxi = function(self, targets)
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if self:doDisCard(p, "h") then
			return p
		end
	end
	return nil
end

sgs.ai_skill_playerchosen.sfofl_n_huwei = function(self, targets)
	targets = sgs.QList2Table(targets)
    for _, p in ipairs(targets) do
		if self:doDisCard(p, "e") and self:isEnemy(p) then
			return p
		end
	end
    for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:hasSkills(sgs.need_maxhp_skill, enemy) then
			return p
		end
	end
    for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:isWeak() then
			return p
		end
	end
    for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_cardask["@sfofl_n_baijiang"] = function(self, data, pattern, target, target2)
	return true
end
sgs.ai_skill_invoke.sfofl_n_baijiang = function(self,data)
	local use = data:toCardUse()
	if use.from and self:isFriend(use.from) then
		if self:getOverflow() == 0 and use.from:getMaxCards() - use.from:getHandcardNum() > 2 then
			return true
		end
	end
	if not self:isFriend(use.from) then
		if use.from:getMark("sfofl_n_baijiang-Clear") == 0 then return true end
		if use.from:getMaxCards() > 0 then return true end
	end
	return false
end
sgs.ai_skill_discard.sfofl_n_zhuying = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	local damage = self.room:getTag("sfofl_n_zhuying"):toDamage()
    local list = self.room:getAlivePlayers()
	if self:needToLoseHp(damage.to,damage.from,damage.card) then
		return {}
	end	
	if not self:damageStruct(damage) then
		return {}
	end	
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, c1 in ipairs(cards) do
		for _, c2 in ipairs(cards) do
			if c1 ~= c2 and c1:getType() == c2:getType() then
				table.insert(to_discard, c1:getEffectiveId())
				table.insert(to_discard, c2:getEffectiveId())
				break
			end
		end
		if #to_discard == 2 then
			break
		end
	end
	if #to_discard == 2 then
		return to_discard
	end
	if self:isWeak() then
		return {cards[1]:getEffectiveId(), cards[2]:getEffectiveId()}
	end
	return {}
end


sgs.ai_skill_invoke.sfofl_n_youzhan = function(self,data)
	local target = data:toPlayer()
	return self:doDisCard(target, "he")
end



sgs.ai_skill_use["@@sfofl_n_shiji"] = function(self, prompt, method)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:isKindOf("Jink") then
			self:sort(self.friends_noself, "handcard")
			for _,p in ipairs(self.friends_noself) do
				if self:canDraw(p, self.player) then
					return "#sfofl_n_shiji:"..card:getId()..":->"..p:objectName()
				end
			end
		end
	end
	return "."
end
sgs.ai_card_intention["#sfofl_n_shiji"] = -80
addAiSkills("sfofl_n_zhuifeng").getTurnUseCard = function(self)
	for _,cn in sgs.list(patterns())do
		local fs = dummyCard(cn)
		if fs and self.player:getKingdom()=="wei"
		and fs:isKindOf("Duel")
		and fs:isAvailable(self.player)
		and not self:isWeak() then
			fs:setSkillName("sfofl_n_zhuifeng")
			local d = self:aiUseCard(fs)
			sgs.ai_use_priority.sfofl_n_zhuifeng = sgs.ai_use_priority[fs:getClassName()]
			self.cf_to = d.to
			if d.card and d.to then
				return sgs.Card_Parse("#sfofl_n_zhuifeng:.:"..cn) 
			end
		end	
	end
end

sgs.ai_skill_use_func["#sfofl_n_zhuifeng"] = function(card,use,self)
	use.card = card
	use.to = self.cf_to
end
sgs.ai_use_value.sfofl_n_zhuifeng = 5.4
sgs.ai_use_priority.sfofl_n_zhuifeng = 2.8

addAiSkills("sfofl_n_chongjian").getTurnUseCard = function(self)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if c:isKindOf("EquipCard")
		then table.insert(toids,c) end
	end
	for _,cn in sgs.list(patterns())do
	   	local fs = dummyCard(cn)
		if fs and self.player:getKingdom()=="wu"
		and (fs:isKindOf("Slash") or fs:isKindOf("Analeptic"))
		and #toids>0
		then
			fs:setSkillName("sfofl_n_chongjian")
			fs:addSubcard(toids[1])
			local d = self:aiUseCard(fs)
			if fs:isAvailable(self.player)
			and d.card and d.to
			then return fs end
		end
	end
end

sgs.ai_guhuo_card.sfofl_n_chongjian = function(self,toname,class_name)
	local cards = self:addHandPile("he")
	cards = self:sortByKeepValue(cards,nil,true)
	local toids = {}
  	for _,c in sgs.list(cards)do
		if c:isKindOf("EquipCard")
		then table.insert(toids,c:getEffectiveId()) end
	end
	if #toids>0
	then return "#sfofl_n_chongjian:"..toids[1]..":"..toname end
end

sgs.ai_skill_use["@@sfofl_qinyi"] = function(self,prompt)
	return "#sfofl_qinyi::"
end

sgs.ai_skill_askforag.sfofl_qinyi = function(self,card_ids)
	for _,id in ipairs(RandomList(card_ids))do
		local card = sgs.Sanguosha:getCard(id)
		local dummy_use = self:aiUseCard(card, dummy())
		if card:isAvailable(self.player) and dummy_use.card then
			return id
		end
	end
end

sgs.ai_skill_playerchosen.sfofl_qinyi = function(self, targets)
	local card = sgs.Sanguosha:getCard(self.player:getMark("sfofl_qinyi"))
	local use_card = sgs.Sanguosha:cloneCard(card:objectName(), sgs.Card_NoSuit, 0)
	use_card:setSkillName("sfofl_qinyi")
	use_card:deleteLater()
	local dummy_use = self:aiUseCard(use_card, dummy())
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
    for _, target in ipairs(targets) do
        if dummy_use.to:contains(target) then
			return target
		end
    end
    return targets[math.random(1, #targets)]
end



sgs.ai_skill_playerschosen.sfofl_taoyan = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	for _,target in ipairs(can_choose) do
		if self:isFriend(target) and self:canDraw(target, self.player) then
			selected:append(target)
			if selected:length() >= max then break end
		end
	end
    return selected
end

sgs.ai_skill_invoke.sfofl_yanli = function(self, data)
	local target = data:toDying().who
    if target and self:isFriend(target) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_yanli = function(self, player, promptlist)
    local dying = self.room:getCurrentDyingPlayer()
    if dying and promptlist[#promptlist] == "yes" then
        sgs.updateIntention(player, dying, -70)
    end
end


sgs.ai_skill_cardask["@sfofl_shanwu"] = function(self, data, pattern, target, target2)	
	local use = data:toCardUse()
    if target and not self:isFriend(target) then return "." end
	if use.card and use.card:hasFlag("NosJiefanUsed") then return "." end

	if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
		or use.card:isKindOf("NatureSlash") and self.player:isChained() and self:isGoodChainTarget(target,use.card,use.from)
		or self:needToLoseHp(target,use.from,use.card) and self:ajustDamage(use.from,target,1,use.card)==1 then return "." end
	if self:needToLoseHp(target, use.from,use.card, true, true) then return "." end
	if getCardsNum("Jink", target, self.player) == 0 then return true end
	return true
end

sgs.ai_choicemade_filter.cardResponded["@sfofl_shanwu"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local target = self.room:findPlayerByObjectName(promptlist[2])
		if target then
			sgs.updateIntention(player, target, -40)
		end
	end
end

sgs.ai_skill_invoke.sfofl_xianli = function(self, data)
	local target = data:toPlayer()
    if target and self:doDisCard(target, "he", true) then return true end
	return false
end

sgs.ai_skill_cardask["@sfofl_guisha"] = function(self,data)
	local use = data:toCardUse()
	local slash = use.card
	local slash_num = 0
	if use.from:objectName()==self.player:objectName() then 
		slash_num = self:getCardsNum("Slash") 
	else 
		slash_num = getCardsNum("Slash",use.from,self.player) 
	end
	if self:isEnemy(use.from) then return "." end
	if (use.m_reason==sgs.CardUseStruct_CARD_USE_REASON_PLAY and use.m_addHistory and self:isFriend(use.from) and slash_num>=1) then
		return true
	end
	if self:isFriend(use.from) and (not self:isFriend(use.to:first()) and not self:cantDamageMore(use.from, use.to:first())) then
		return true
	end
	return "."
end

sgs.ai_choicemade_filter.cardResponded["@sfofl_guisha"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		self.room:writeToConsole(promptlist[#promptlist]..": "..promptlist[4])
		local target = self.room:findPlayerByObjectName(promptlist[4])
		if target then
			sgs.updateIntention(player, target, -40)
		end
	end
end

sgs.ai_ajustdamage_from.sfofl_guisha = function(self, from, to, card, nature)
    if card and card:hasFlag("sfofl_guisha")  then
        return 1
    end
end

sgs.ai_skill_invoke.sfofl_shuli = function(self, data)
	local target = data:toPlayer()
    if target and self:isFriend(target) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sfofl_shuli = function(self, player, promptlist)
    local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
	if target then sgs.updateIntention(player,target,-50) end
end


sgs.ai_skill_invoke.sfofl_meiniang = function(self, data)
	local target = self.room:getCurrent()
    if target and self:isFriend(target) then return true end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.sfofl_meiniang = function(self, player, promptlist)
    local target = self.room:getCurrent()
	if target then sgs.updateIntention(player,target,-50) end
end


sgs.ai_skill_invoke.sfofl_yaoli = function(self, data)
	local target = data:toCardUse().from
    if target and self:isFriend(target) then return true end
	return false
end

--canLiegong

sgs.ai_skill_discard.sfofl_leyu = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local current = self.room:getCurrent()
	if not current then return {} end
	if #self.enemies<1 then return {} end
	local getvalue = function(enemy)
		if type(enemy)~="userdata" then return -100 end
		local value = enemy:getHandcardNum()-enemy:getHp()
		for _,sk in sgs.list(sgs.getPlayerSkillList(enemy))do
			local s = sgs.Sanguosha:getViewAsSkill(sk:objectName())
			if s and s:isEnabledAtPlay(enemy) then value = value+6 end
			s = sgs.Sanguosha:getTriggerSkill(sk:objectName())
			if s and s:hasEvent(sgs.EventPhaseStart) then value = value-2 end
			if s and s:hasEvent(sgs.EventPhaseChanging) then value = value-2 end
			if s and s:hasEvent(sgs.FinishJudge) then value = value-2 end
		end
		if self:isWeak(enemy) then value = value+3 end
		if enemy:isLord() then value = value+3 end
		if self:objectiveLevel(enemy)<3 then value = value-6 end
		if enemy:hasSkills("keji|shensu|conghui") then value = value-enemy:getHandcardNum() end
		if self:needBear(enemy) then value = value-20 end
		return value+(enemy:aliveCount()-self:playerGetRound(enemy))/2
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards)do
		if #to_discard>=discard_num then break end
		table.insert(to_discard,c:getEffectiveId())
	end
	local function cmp(a,b)
		return getvalue(a)>getvalue(b)
	end
	table.sort(self.enemies,cmp)
	if self.enemies[1]:objectName() == current:objectName() and getvalue(self.enemies[1]) >-100 then
		if #to_discard == 3 then
			return to_discard
		end
	elseif self.player:getCards("he"):length() - #to_discard > 3 and #to_discard == 3 then
		for _,p in sgs.list(self.enemies)do
			if p:objectName() == current:objectName() then
				return to_discard
			end
		end
	end
	return {}
end

sgs.ai_skill_playerchosen.sfofl_yuanli = function(self, targets)
	self:sort(self.friends_noself, "handcard")
	for _, friend in ipairs(self.friends_noself) do
		if self:canDraw(friend, self.player) then
			return friend
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		return friend
	end
	return targets:last()
end
sgs.ai_playerchosen_intention.sfofl_yuanli = -40






















