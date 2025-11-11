--函数定义
--table到playerlist的转换
function Table2Playerlist(thetable)
	assert(type(thetable)=="table")
	local playerlist = sgs.PlayerList()
	for _,player in ipairs(thetable) do
		playerlist:append(player)
	end
	return playerlist
end
--table到serverplayerlist的转换
function Table2SPlayerlist(thetable)
	assert(type(thetable)=="table")
	local playerlist = sgs.SPlayerList()
	for _,player in ipairs(thetable) do
		playerlist:append(player)
	end
	return playerlist
end
--card_ids到cards的转换
function Ids2Cards(thetable)
	local cards = {}
	for _,card_id in ipairs(thetable) do
		table.insert(cards,sgs.Sanguosha:getCard(card_id))
	end
	return cards
end


function Table2IntList(theTable)
	local result = sgs.IntList()
	for i = 1, #theTable, 1 do
		result:append(theTable[i])
	end
	return result
end



--技能AI
--追杀
sgs.ai_cardneed.zhuisha = sgs.ai_cardneed.slash
sgs.ai_skill_invoke.zhuisha = function(self,data)
	local effect = data:toCardEffect()
	if self:isFriend(effect.to,self.player) then return false end
	return true
end
sgs.ai_skill_cardask["@zhuisha_ask"] = function(self,data,pattern,target)
	local card_list = self.player:getHandcards()
	local cards = sgs.QList2Table(card_list)
	self:sortByKeepValue(cards,false)
	return "$"..cards[1]:getEffectiveId()
end
sgs.ai_ajustdamage_from.zhuisha = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") then
		return to:getPile("zhui"):length()
	end
end
sgs.ai_ajustdamage_from.htms_zangsong = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:getSkillName() == "htms_zangsong" then
		return to:getLostHp()
	end
end
--葬送
local htms_zangsong_skill = {}
htms_zangsong_skill.name = "htms_zangsong"
table.insert(sgs.ai_skills, htms_zangsong_skill)

htms_zangsong_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#htms_zangsongCard") then return nil end
	if  (#self.enemies == 0) then return nil end
	return sgs.Card_Parse("#htms_zangsongCard:.:")
end

sgs.ai_skill_use_func["#htms_zangsongCard"] =function(card,use,self)
	self:sort(self.enemies, "defense")
	local use_card
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	for _, card in ipairs(cards) do
		if card:isDamageCard() then
			use_card = card
		end
	end
	if not use_card then return end
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:setSkillName("htms_zangsong")
	slash:addSubcard(use_card)
	slash:deleteLater()

	local dummy = self:aiUseCard(slash, dummy())
	if dummy.card and dummy.to:length() > 0
	then
		use.card = sgs.Card_Parse("#htms_zangsongCard:"..use_card:getEffectiveId() ..":")
		if use.to then use.to = dummy.to end
		return
	end
end

sgs.ai_use_value["htms_zangsongCard"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["htms_zangsongCard"] = sgs.ai_use_priority.Slash - 0.2
-- sgs.ai_ajustdamage_from.ansha = function(self, from, to, card, nature)
-- 	if card and card:isKindOf("Slash") then
-- 		local x = 0 or 1 and to:isWounded()
-- 		return to:getPile("zhui"):length() + x
-- 	end
-- end
--试炼
sgs.ai_skill_invoke.shilian = function(self,data)
	local damage = data:toDamage()
	local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	if self:isFriend(damage.from,self.player) then return false end
	if  damage.from and self:isEnemy(damage.from) and  self:slashIsEffective(slash, damage.from) and not self:slashProhibit(slash, damage.from) and self:isGoodTarget(damage.from, self.enemies, slash) then
	return true
	end
end

sgs.ai_skill_invoke.shilianEX = function(self,data)
	local damage = data:toDamage()
	local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	if self:isFriend(damage.from,self.player) then return false end
	if  damage.from and self:isEnemy(damage.from) and  self:slashIsEffective(slash, damage.from) and not self:slashProhibit(slash, damage.from) and self:isGoodTarget(damage.from, self.enemies, slash) then
	return true
	end
end
sgs.ai_choicemade_filter.skillInvoke.shilianEX = function(self,player,promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and damage.to then
		if promptlist[#promptlist]=="yes" then
			if not self:needToLoseHp(damage.from,player,damage.card) then
				sgs.updateIntention(damage.to,damage.from,40)
			end
		elseif self:canAttack(damage.from) then
			sgs.updateIntention(damage.to,damage.from,-40)
		end
	end
end


--鲜血沸腾
sgs.ai_skill_invoke.xianxuefeiteng = function(self,data)
	if self.player:getLostHp() > self.player:getHp() then
		if self:isWeak() and self:getCardsNum("Slash") < 2 then
			return true
		end
	else
		if self:getCardsNum("Peach") > 0 then
			return true
		end
	end
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|xianxuefeiteng"

--风王
sgs.ai_skill_choice.fengwang = function(self,choices)
	if self:needKongcheng(self.player) or self:isWeak(self.player) then return "fengwang_discard" end
	local card_list = self.player:getHandcards()
	local x = 0
	for _,card in sgs.qlist(card_list) do
		if card:isKindOf("Slash") then x = x + 1 end
	end
	if x > 2 then return "fengwang_equip" end
	return "fengwang_discard"
end
sgs.ai_skill_cardask["@fengwang_askforequip"] = function(self,data,pattern,target)
	local card_list = self.player:getCards("e")
	local cards = sgs.QList2Table(card_list)
	self:sortByKeepValue(cards,false)
	return "$"..cards[1]:getEffectiveId()
end
local fengwang_skill = {}
fengwang_skill.name = "fengwang"
table.insert(sgs.ai_skills,fengwang_skill)
fengwang_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#fengwang") then return end
	return sgs.Card_Parse("#fengwang:.:")
end
sgs.ai_skill_use_func["#fengwang"] = function(card,use,self)
	local player = self.player
	local room = player:getRoom()
	local cards = sgs.QList2Table(player:getHandcards())
	for _,card in ipairs(cards) do
		if not card:isKindOf("BasicCard") then table.removeOne(cards,card) end
	end
	self:sortByKeepValue(cards,false)
	local players = sgs.QList2Table(room:getAlivePlayers())
	local targets = {}
	for _,target in ipairs(players) do
		local can_use = true
		if (self:isFriend(target,self.player)) or (target:isKongcheng()) or (target:getCards("e"):length() == 0) then can_use = false end
		if can_use then table.insert(targets,target) end
	end
	if #targets == 0 then
		use.card = nil
		return
	end
	local cards = sgs.QList2Table(player:getHandcards())
	self:sortByUseValue(cards,true)
	local subcard
	for _,acard in ipairs(cards) do
		if acard:isKindOf("BasicCard") then
			subcard = acard
			break
		end
	end
	if not subcard then
		use.card = nil
		return
	end
	use.card = sgs.Card_Parse("#fengwang:.:")
	use.card:addSubcard(subcard)
	self:sort(targets,"handcard")
	if use.to then use.to:append(targets[#targets]) end
end
sgs.ai_use_value["fengwang"] = 9
sgs.ai_use_priority["fengwang"] = sgs.ai_use_priority.Dismantlement + 0.1
sgs.ai_card_intention["fengwang"] = sgs.ai_card_intention.Dismantlement
sgs.fengwang_keep_value = {
	BasicCard = 6
}

--新风王结界
sgs.ai_skill_choice.newfengwang = function(self,choices, data)
	local target = data:toPlayer()
	if getKnownCard(target,self.player,"Jink")>0 and target:getMark("&newfengwang+to+#".. self.player:objectName().. "-Clear") == 0  then return "newfengwang_discard" end
	if (not self:needToThrowArmor(target) and not target:hasArmorEffect("silver_lion") and not self:hasSkills(sgs.lose_equip_skill, target) or self:doDisCard(target, "e", true)) then return "newfengwang_equip" end
	return "newfengwang_equip"
end

local newfengwang_skill = {}
newfengwang_skill.name = "newfengwang"
table.insert(sgs.ai_skills,newfengwang_skill)
newfengwang_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#newfengwang") then return end
	return sgs.Card_Parse("#newfengwang:.:")
end
sgs.ai_skill_use_func["#newfengwang"] = function(card,use,self)
	local player = self.player
	local room = player:getRoom()
	local cards = sgs.QList2Table(player:getHandcards())
	for _,card in ipairs(cards) do
		if not card:isKindOf("BasicCard") then table.removeOne(cards,card) end
	end
	self:sortByKeepValue(cards,false)
	local players = sgs.QList2Table(room:getAlivePlayers())
	local targets, friends, enemies = {}, {}, {}
	for _, player in sgs.qlist(self.room:getPlayers()) do
        if not player:isKongcheng() then 
            table.insert(targets, player)           
            if self:isFriend(player) then
                table.insert(friends, player)
            elseif self:isEnemy(player) and self:doDisCard(player, "e", true) and not self:needToLoseHp(player) then
                table.insert(enemies, player)
            end
        end
    end
     
    if #targets == 0 then return end    
    local target
	local slashcount = self:getCardsNum("Slash")
	if slashcount > 0 then
		local slashes = self:getCards("Slash")
		for _,slash in sgs.list(slashes)do
			local dummy_use = self:aiUseCard(slash, dummy())
			if dummy_use.card then
				for _,p in sgs.qlist(dummy_use.to)do
					if p and self:isEnemy(p) and p:getMark("&newfengwang+to+#".. self.player:objectName().. "-Clear") == 0 then
						target = p
                        break
					end
				end
			end
		end
	end
	
	 if not target then
        for _, enemy in ipairs(enemies) do
            if enemy:containsTrick("indulgence") then
                target = enemy
                break
            end
        end
    end
	
	if not target then
        for _, enemy in ipairs(enemies) do
            if self:getDangerousCard(enemy) then
                target = enemy
                break
            end
        end
    end
	
	 if not target then
        for _, enemy in ipairs(enemies) do
            if self:getValuableCard(enemy) then
                target = enemy
                break
            end
        end
    end
	
	if not target then
        for _, friend in ipairs(friends) do
            if self:needToThrowArmor(friend) or friend:hasArmorEffect("silver_lion") or friend:hasSkill("yqijiang") then
                target = friend
                break
            end
        end
    end
	if not target then
        for _, enemy in ipairs(enemies) do
            if self:doDisCard(enemy, "e", true) then
                if enemy:getDefensiveHorse() then
                    target = enemy
                    break
                end
                if not target then
                    if enemy:getArmor() and not self:needToThrowArmor(enemy) then
                        target = enemy
                        break   
                    end
                end
            end
        end
    end
	
	local cards = sgs.QList2Table(player:getHandcards())
	self:sortByUseValue(cards,true)
	local subcard
	for _,acard in ipairs(cards) do
		if acard:isKindOf("BasicCard") then
			subcard = acard
			break
		end
	end
	if not subcard then
		use.card = nil
		return
	end
	if not target then
		use.card = nil
		return
	end
	use.card = sgs.Card_Parse("#newfengwang:.:")
	use.card:addSubcard(subcard)
	self:sort(targets,"handcard")
	if use.to then use.to:append(target) end
end

sgs.ai_cardneed.newfengwang = sgs.ai_cardneed.slash
 


sgs.ai_use_value["newfengwang"] = 9
sgs.ai_use_priority["newfengwang"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_card_intention["newfengwang"] = sgs.ai_card_intention.Dismantlement
sgs.fengwang_keep_value = {
	BasicCard = 6
}
sgs.hit_skill = sgs.hit_skill .. "|newfengwang"

--王者
local wangzhe_skill = {}
wangzhe_skill.name = "wangzhe"
table.insert(sgs.ai_skills,wangzhe_skill)
wangzhe_skill.getTurnUseCard = function(self)
	local player = self.player
	local slash = sgs.Sanguosha:cloneCard("Slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	if player:isLocked(slash) or player:getMark("wangzhe_used") > 0 then return end
	local cards = sgs.QList2Table(player:getCards("he"))
	if #cards == 0 then return end
	return sgs.Card_Parse("#wangzhe:.:")
end
sgs.ai_skill_use_func["#wangzhe"] = function(card,use,self)
	local player = self.player
	local cards = sgs.QList2Table(player:getCards("he"))
	self:sortByKeepValue(cards,false,true)
	local enemies = self.enemies
	local targets = {}
	self:sort(enemies)
	local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	slash:setSkillName("wangzhe")
	slash:deleteLater()
	local rangefix = 0
	if player:getWeapon() and player:getWeapon():getId() == cards[1]:getId() then
		local card = player:getWeapon():getRealCard():toWeapon()
		rangefix = card:getRange() - player:getAttackRange(false)
	end
	local dummy_use = self:aiUseCard(slash, dummy(true, 2))
	if slash:isAvailable(self.player) and dummy_use.card and dummy_use.to then
		for _,p in sgs.qlist(dummy_use.to)do
			if player:canSlash(p,slash,true,rangefix,Table2Playerlist(targets)) then
				table.insert(targets,p)
			end
		end
	end
	if #targets == 0 then
		use.card = nil
		return
	end
	self:sort(targets,"hp")
	if not self:hasHeavyDamage(targets[1],use.card,player) and not self:isWeak() and not self:isWeak(targets[1]) then
		use.card = nil
		return
	end
	local card_str = ("#wangzhe:%d:"):format(cards[1]:getId())
	use.card = sgs.Card_Parse(card_str)
	if use.to then
		for _,p in sgs.list(targets)do
			use.to:append(p)
		end
	end

end
sgs.ai_use_priority["wangzhe"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_card_intention["wangzhe"] = sgs.ai_card_intention.Slash

sgs.ai_cardneed.wangzhe = sgs.ai_cardneed.slash

--doubleslash 二刀流
sgs.ai_skill_invoke.doubleslash = function(self)  --必定使用
		return true
end

sgs.ai_skill_cardask["@doubleslash"] = function(self, data, pattern)
	local cards = sgs.CardList()
	local peach = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if isCard("Peach", c, self.player) and peach < 2 then
			peach = peach + 1
		else
			cards:append(c)
		end
	end
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local slashcount = self:getCardsNum("Slash")
	if slashcount == 0 then return "$" .. cards[1]:getEffectiveId() end		--斷殺就隨便棄
	local slash = self:getCard("Slash")
	local dummy_use = { isDummy = true, extra_target = 1, to = sgs.SPlayerList() }
	if slash then self:useBasicCard(slash, dummy_use) end
	if slashcount >= 1 and slash and dummy_use.card  then
		for _, card in ipairs(cards) do
			if card:isRed() and #self.enemies <= 1 then
				return "$" .. card:getEffectiveId() 					--只有一個敵人就盡量棄紅的
			elseif card:isBlack() and #self.enemies > 1 then
				return "$" .. card:getEffectiveId() 
			end
		end
	end
	return "$" .. cards[1]:getEffectiveId() 
end

sgs.ai_cardneed.doubleslash = sgs.ai_cardneed.slash

function sgs.ai_armor_value.doubleslash(player, self, card)
    if card and (card:isKindOf("Elucidator")) then return 4 end
end

--封弊者
sgs.ai_skill_askforag["betacheater"] = function(self,card_ids)
	local cards = Ids2Cards(card_ids)
	self:sortByUseValue(cards,true)
	return cards[1]:getId()
end



--音速手刃
local handsonic_skill = {}
handsonic_skill.name = "handsonic"
table.insert(sgs.ai_skills,handsonic_skill)
handsonic_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#handsonicCard") then return end
	return sgs.Card_Parse("#handsonicCard:.:")
end
sgs.ai_skill_use_func["#handsonicCard"] = function(card,use,self)
	local player = self.player
	local room = player:getRoom()
	local cards = sgs.QList2Table(player:getHandcards())
	for _,card in ipairs(cards) do
		if not card:isKindOf("BasicCard") then table.removeOne(cards,card) end
	end
	self:sortByKeepValue(cards,false)
	local players = sgs.QList2Table(room:getOtherPlayers(player))
	local targets = {}
	local friend = 0
	local enemy = 0
	for _,target in ipairs(players) do
		if  (not target:isNude()) and (not target:getArmor()) then
			table.insert(targets,target)
				if self:isFriend(target,self.player) then
					friend = friend + 1
				else
					enemy = enemy + 1
				end
		end
	end
	if #targets == 0  or friend>=enemy then
		use.card = nil
		return
	end
	local cards = sgs.QList2Table(player:getHandcards())
	self:sortByUseValue(cards,true)
	local subcard
	for _,acard in ipairs(cards) do
		if acard:isKindOf("BasicCard") then
			subcard = acard
			break
		end
	end
	if not subcard then
		use.card = nil
		return
	end
	use.card = sgs.Card_Parse("#handsonicCard:.:")
	use.card:addSubcard(subcard)
	--self:sort(targets,"handcard")
	--if use.to then use.to:append(targets[#targets]) end
end

sgs.ai_use_value["handsonic"] = 9
sgs.ai_use_priority["handsonic"] = sgs.ai_use_priority.Dismantlement + 0.1

sgs.ai_skill_discard.handsonic = function(self, discard_num, min_num, optional, include_equip)

	local user = self.room:getCurrent()
    
	if not user then return {} end
	if  self:isFriend(user) then
	return self:askForDiscard("dummy", discard_num, min_num, false, include_equip, ".")
	end
	return {}
end


--防御结界
sgs.ai_skill_cardask["@defencefieldask"] = function(self, data, pattern, target, target2)
	local isUse = data:toStringList()[3] == "use"
	local use 
	if isUse then
		if data:toStringList()[4] then 
			use = self.room:getTag("UseHistory"..data:toStringList()[4]):toCardUse()
		end
	end
	local dest
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:hasFlag("defencefield_Target") then dest = aplayer break end
	end
	if not self:isFriend(dest) then return "." end
	local card
	local handcards = sgs.QList2Table(self.player:getCards("he"))
	local use_card = {}
	self:sortByKeepValue(handcards)
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach")
		and not c:isKindOf("Analeptic")
		and not c:isKindOf("Nullification")
		and c:isRed()
		and not (c:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0)
		then
			table.insert(use_card, c)
		end
	end
	if #use_card == 0 then return "." end
	
	if dest and dest:hasFlag("dahe") then return "."  end
	if isUse then
		if use.card and use.card:hasFlag("NosJiefanUsed") then return "."  end
		if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
		or use.card:isKindOf("NatureSlash") and dest:isChained() and self:isGoodChainTarget(dest,use.card,use.from)
		or self:needToLoseHp(dest,use.from,use.card) and self:ajustDamage(use.from,dest,1,use.card)==1 then return "." end
	end
	if self:needToLoseHp(dest, nil, nil, true) then return "."  end
	if self:getCardsNum("Jink") == 0 then return use_card[1]:toString() end
	if self:ajustDamage(nil,dest,1,nil)>1 then return use_card[1]:toString() end
	if self.player:getHandcardNum()==1 and self:needKongcheng()
	or not(self:hasLoseHandcardEffective() or self.player:isKongcheng()) then return use_card[1]:toString() end
	
	
	return use_card[1]:toString()
end

sgs.ai_choicemade_filter.cardResponded["@defencefieldask"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
	local dest
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:hasFlag("defencefield_Target") then dest = aplayer break end
	end
	if dest then 
		sgs.updateIntention(player, dest, -80)
		end
	end
end
function sgs.ai_cardneed.defencefield(to, card, self)
	return card:isRed() and to:getCards("he"):length() < 4
end

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|defencefield"

--冰冻傀儡
local frozenpuppet_skill = {}
frozenpuppet_skill.name = "frozenpuppet"
table.insert(sgs.ai_skills,frozenpuppet_skill)
frozenpuppet_skill.getTurnUseCard = function(self)
	local player = self.player
	if player:getHandcardNum() < 3 then return end
	if player:getMark("@frozenpuppet") == 0 then return end
	return sgs.Card_Parse("#frozenpuppetCard:.:")
end


sgs.ai_use_value["frozenpuppetCard"] = 7
sgs.ai_use_priority["frozenpuppetCard"] =sgs.ai_use_priority.Peach - 5

sgs.ai_card_intention["frozenpuppetCard"] = -80


sgs.ai_skill_use_func["#frozenpuppetCard"] = function(card, use, self)
	local player = self.player
	if player:getHandcardNum() < 1 then return end
	if player:getMark("@frozenpuppet") == 0 then return end
	local friends = self.friends
	self:sort(friends, "defense")
	local target
	local use_value = 0
	local max_value = -10000
	
	for _, friend in ipairs(self.friends) do
		use_value = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(friend)) do
				if self:isEnemy(p) then
					use_value = use_value + p:getHandcardNum() / 5
					if p:inMyAttackRange(friend) or self:isWeak(friend) then
						use_value = use_value + 1
					end
				end
		end
		use_value = use_value - self.player:getHandcardNum() / 2
		use_value = use_value - friend:getHandcardNum() / 2
		use_value = use_value + friend:getLostHp() / 2
		if use_value > max_value then
			max_value = use_value
			target = friend
		end
	end
	
	if target and max_value >= self.player:aliveCount() / 2   then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end

	if self:isWeak()  then
		use.card = card
		if use.to then use.to:append(self.player) end
		return
	end
end

sgs.ai_target_revises["@frozenpuppettarg"] = function(to,card,self)
	return card and not card:isKindOf("SkillCard") and self.player:objectName() ~= to:objectName()
end

--初始之音
sgs.ai_skill_discard["chuszy"] = function(self, discard_num, min_num, optional, include_equip)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if not self:isFriend(damage.to) or self.player:getCards("he"):length() < 2  then return {} end
	if self:isWeak(self.player) and damage.to:objectName() ~= self.player:objectName() then return {} end
	if damage.to:getHp() > getBestHp(damage.to) then return {} end
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(usable_cards)
	local to_discard = {}
	for _,c in ipairs(usable_cards) do
		if #to_discard < discard_num  and not c:isKindOf("Peach") then
			table.insert(to_discard, c:getEffectiveId())
		end
	end
	if #to_discard > 0 then
		return to_discard
	end
end
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|chuszy"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|chuszy"
--消失
function sgs.ai_slash_prohibit.htms_xiaoshi(self, from, to)
	if from:hasSkill("jueqing") or (from:hasSkill("nosqianxi") and from:distanceTo(to) == 1) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if self:isFriend(to, from) and self:isWeak(to) then return true end
	return #(self:getEnemies(from)) > 1 and self:isWeak(to) and from:getEquips():length() > 1
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|htms_xiaoshi"

--灭杀

local mie_skill = {}
mie_skill.name = "mie"
table.insert(sgs.ai_skills,mie_skill)
mie_skill.getTurnUseCard = function(self)
if self.player:getMark("@Luazuihou") > 0 then
	if self.player:usedTimes("#mie") == 2 then return end
	return sgs.Card_Parse("#mie:.:")
	else 
	if self.player:hasUsed("#mie") then return end	
	return sgs.Card_Parse("#mie:.:")
	end
end
sgs.ai_skill_use_func["#mie"] = function(card,use,self)
	local player = self.player
	local room = player:getRoom()
	local cards = sgs.QList2Table(player:getCards("he"))
	if self.player:getMark("@Luazuihou") == 0 then
		for _,card in ipairs(cards) do
			if not card:isKindOf("BasicCard") then table.removeOne(cards,card) end
		end
	end
	self:sortByKeepValue(cards)
	local target
	if self.player:getMark("@Luazuihou") > 0 then
		target = self:findPlayerToDiscard("he", false, false)[1]
	else
		target = self:findPlayerToDiscard("he", false, true)[1]
	end
	local players = sgs.QList2Table(room:getOtherPlayers(player))
	-- local targets = {}
	-- for _,target in ipairs(players) do
	-- 	local can_use = true
	-- 	if (self:isFriend(target,self.player))  then can_use = false end
	-- 	if self.player:getMark("@Luazuihou") > 0 then
	-- 		if target:isNude() then can_use = false end
	-- 	else
	-- 	if  not self.player:canDiscard(target, "he") then can_use = false end
	-- 	end
	-- 	if can_use then table.insert(targets,target) end
	-- end
	if not target then
		use.card = nil
		return
	end
	local subcard
	for _,acard in ipairs(cards) do
		if not acard:isKindOf("Peach") then
			subcard = acard
			break
		end
	end
	if not subcard then
		use.card = nil
		return
	end
	use.card = sgs.Card_Parse("#mie:.:")
	use.card:addSubcard(subcard)
	--self:sort(targets,"handcard")
	--if use.to then use.to:append(targets[#targets]) end
	if use.to then use.to:append(target) end
end
sgs.ai_use_value["mie"] = 9
sgs.ai_use_priority["mie"] = sgs.ai_use_priority.Dismantlement + 0.1
sgs.ai_card_intention["mie"] = sgs.ai_card_intention.Dismantlement
sgs.mie_keep_value = {
	BasicCard = 6
}

--电磁炮
local diancp_skill = {}
diancp_skill.name = "diancp"
table.insert(sgs.ai_skills,diancp_skill)
diancp_skill.getTurnUseCard = function(self)
	--if self.player:hasUsed("#diancp") then return end	
	if #self.enemies == 0 then return end
	return sgs.Card_Parse("#diancp:.:")
end


sgs.ai_skill_use_func["#diancp"] = function(card, use, self)
	local cmp = function(a, b)
		if a:getHp() < b:getHp() then
			if a:getHp() == 1 and b:getHp() == 2 then return false else return true end
		end
		return false
	end
	local enemies = {}
	for _, enemy in ipairs(self.enemies) do
		if self:canAttack(enemy, self.player) and self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Thunder,self.player) and self:canDamage(enemy,self.player,nil) then table.insert(enemies, enemy) end
	end
	if #enemies == 0 then return end

	-- find cards
	local card_ids = {}
	local zcards = self.player:getHandcards()
	for _, zcard in sgs.qlist(zcards) do
		if zcard:isKindOf("ThunderSlash") then
			table.insert(card_ids, zcard:getId()) 
		end
	end
	if #card_ids == 0 then return end
	local hc_num = #card_ids
	for _, enemy in ipairs(enemies) do
		if enemy:getHp() > 1 then
				use.card = sgs.Card_Parse("#diancp:.:")
				use.card:addSubcard(card_ids[1])
				if use.to then use.to:append(enemy) end
				return
		else
			if not self:isWeak() or self:getSaveNum(true) >= 1 then
					use.card = sgs.Card_Parse("#diancp:.:")
					use.card:addSubcard(card_ids[1])
					if use.to then use.to:append(enemy) end
					return
			end
		end
	end
end


--雷击
sgs.ai_ajustdamage_to.leij = function(self, from, to, card, nature)
	if nature == sgs.DamageStruct_Thunder
	then
		return -99
	end
end
-- leij_damageeffect = function(self, to, nature, from)
-- 	if to:hasSkill("leij") and nature == sgs.DamageStruct_Thunder then return false end
-- 	return true
-- end


-- table.insert(sgs.ai_damage_effect, leij_damageeffect)


sgs.ai_use_value["diancp"] = 9
sgs.ai_use_priority["diancp"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_card_intention["diancp"] = sgs.ai_card_intention.Slash


--噩梦
sgs.ai_skill_cardask["@emeng"] = function(self, data)
	--local damage = data:toDamage()
	local target = data:toPlayer()
	if not self:isEnemy(target) then return "." end
	if self:cantDamageMore(self.player,target) then return "." end
		
	local cards = sgs.QList2Table(self.player:getCards("eh"))
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if not card:isKindOf("Peach") and self:getUseValue(card) < 7 then return "$" .. card:getEffectiveId() end
	end
	return "."
end


sgs.ai_ajustdamage_from.Luayezhan = function(self, from, to, card, nature)
	if from:hasFlag("Luayezhan") and card and (card:isKindOf("Slash") or card:isKindOf("Duel")) then
		return 1
	end
end

sgs.ai_cardneed.Luayezhan = sgs.ai_cardneed.nosluoyi

--加速告白

sgs.ai_skill_use["@@jiasugaobai"] = function(self, prompt, method)
	local data = self.room:getTag("jiasugaobai")
	local use = data:toCardUse()
	if use.card:isKindOf("Duel") then
		if not self:hasTrickEffective(use.card, self.player) then return "." end
		if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player) then
			local  drawnum =  1
			local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
			local friends = {}
			for _, player in ipairs(players) do
				if self:isFriend(player) and self:needDraw(player, false) and player:isMale() then
					table.insert(friends, player)
				end
			end
			for _, player in ipairs(players) do
				if self:isFriend(player) and self:canDraw(player, self.player) and not table.contains(friends, player) and player:isMale() then
					table.insert(friends, player)
				end
			end
			if #friends == 0 then return "." end

			self:sort(friends, "defense")
			for _, friend in ipairs(friends) do
				if friend:getHandcardNum() < 2 and not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
							return  "#jiasugaobai:.:->" .. friend:objectName()
				end
			end

			local AssistTarget = self:AssistTarget()
			if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and (AssistTarget:getHandcardNum() < AssistTarget:getMaxCards() * 2 or AssistTarget:getHandcardNum() < self.player:getHandcardNum())then
				for _, friend in ipairs(friends) do
					if friend:objectName() == AssistTarget:objectName() and not self:willSkipPlayPhase(friend) then
							return  "#jiasugaobai:.:->" .. friend:objectName()
					end
				end
			end

			for _, friend in ipairs(friends) do
				if self:hasSkills(sgs.dont_kongcheng_skill, friend) and friend:isKongcheng() then
					
						return  "#jiasugaobai:.:->" .. friend:objectName()
					end
			end
			for _, friend in ipairs(friends) do
				if self:hasSkills(sgs.cardneed_skill, friend) and not self:willSkipPlayPhase(friend) then
					
						return  "#jiasugaobai:.:->" .. friend:objectName()
					end
			end

			self:sort(friends, "handcard")
			for _, friend in ipairs(friends) do
				if not self:needKongcheng(friend) and not self:willSkipPlayPhase(friend) then
					
							return  "#jiasugaobai:.:->" .. friend:objectName()
				end
			end
			
		end
	end
	return "."
end
--决斗加速
sgs.ai_skill_invoke.juedoujiasu = function(self,data)
	return true
end

function sgs.ai_cardneed.juedoujiasu(to,card)
	return card:isKindOf("Duel")
end

--加速对决
sgs.ai_skill_invoke.jiasuduijue = function(self,data)
	local use = data:toCardUse()
	local Duel = sgs.Sanguosha:cloneCard("Duel", sgs.Card_SuitToBeDecided, 0)
	Duel:setSkillName("jiasuduijue")
	Duel:deleteLater()
	if use.card:isKindOf("Slash") and use.card:isBlack() then
		if use.from:objectName() == self.player:objectName() then
			local dummy_use = self:aiUseCard(Duel, dummy(true, 99))
			
			if self:hasHeavyDamage(use.from, use.card, self.player) then return false end
			local invoke = true
			for _, player in sgs.qlist(use.to) do 
				if dummy_use.card and dummy_use.to:length() > 0 then
					if not dummy_use.to:contains(player) then
						invoke = false
					end
				end
				if  self:getCardsNum("Slash") < getCardsNum("Slash", player, self.player)  then invoke = false end
				if not self:hasTrickEffective(Duel, player) then invoke = false end
				if self:ajustDamage(self.player,player,1,Duel)==0 then invoke = false end
				if  getCardsNum("Jink", player, use.from) == 0  then invoke = false end
			end
			return invoke
		else
			if self:getCardsNum("Jink") == 0 or self:getCardsNum("Slash") > getCardsNum("Slash", use.from, self.player) or  self:hasHeavyDamage(use.from, use.card, self.player)  then
				return true
			end
		end
	end
	return false
end

--翔翼
sgs.ai_view_as.xiangy = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if  not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0)
	and card:isKindOf("EquipCard")    then
		return ("jink:xiangy[%s:%s]=%d"):format(suit, number, card_id)
	end
end
sgs.ai_skill_playerchosen["xiangy"] = function(self, targets)
	if self:findPlayerToDiscard("ej", true, false, targets) ~= {} then
		return self:findPlayerToDiscard("ej", true, false, targets)[1]
	end
	return nil
end

sgs.ai_skill_choice.xiangy = function(self, choices)
	if self:findPlayerToDiscard("ej", true, false) ~= {} and not self:isWeak() then
		return "dis"
		end
	return "draw1"
end

sgs.use_lion_skill = sgs.use_lion_skill .. "|xiangy"

--救济的祈愿
jiujideqiyuan_skill ={}
jiujideqiyuan_skill.name = "jiujideqiyuan"
table.insert(sgs.ai_skills,jiujideqiyuan_skill)
jiujideqiyuan_skill.getTurnUseCard = function(self,inclusive)
	if not self.player:canDiscard(self.player, "he") then return end
	if self.player:hasUsed("#jiujideqiyuan") then return end
	local hurtF = 0
	if self.player:isWounded() then return sgs.Card_Parse("#jiujideqiyuan:.:") end
	for _,p in ipairs(self.friends_noself) do
		if p:isWounded() then hurtF = hurtF + 1 end
	end
	if hurtF > 0 then return sgs.Card_Parse("#jiujideqiyuan:.:") end
	return 
end
sgs.ai_skill_use_func["#jiujideqiyuan"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	local cards = self.player:getCards("he")
	
	local use_card = {}
	cards = sgs.QList2Table(cards)
	if #cards == 0 then return end
	self:sortByKeepValue(cards)
	local basic, trick,equip = true,true,true
	for _, card in ipairs(cards) do
		if card:isKindOf("BasicCard") and basic then
		basic = false
		table.insert(use_card, card:getId())
		elseif card:isKindOf("TrickCard") and trick then
		trick = false
		table.insert(use_card, card:getId())
		elseif card:isKindOf("EquipCard") and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) and equip then
		equip = false
		table.insert(use_card, card:getId())
		end
	end
	
		for _,p in ipairs(self.friends) do
			if p:getHp() < getBestHp(p) then targets:append(p) end
			if targets:length() >= #use_card then
				break
			end
		end

	if targets:length() < #use_card  then
		table.removeOne(use_card, use_card[#use_card])
	end
	if targets:length() < #use_card  then
		table.removeOne(use_card, use_card[#use_card])
	end
	if targets:length()> 0 then
		if #use_card == 1 then
		use.card = sgs.Card_Parse("#jiujideqiyuan:"..use_card[1] ..":")
		else
		use.card = sgs.Card_Parse("#jiujideqiyuan:".. table.concat(use_card, "+")..":")
		end
		if use.to then use.to = targets end
		return
	end
end



sgs.ai_use_value["jiujideqiyuan"] = 8
sgs.ai_use_priority["jiujideqiyuan"]  = 4.2

sgs.ai_card_intention["jiujideqiyuan"] = -100

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|jiujideqiyuan"

sgs.ai_use_revises.jiujideqiyuan = function(self,card,use)
	if card:isKindOf("Slash") and self:isWeak()
	and self:getOverflow()<=0
	then return false end
end

--法则缔造
sgs.ai_skill_choice["fazededizao"] = function(self, choices, data)
	local items = choices:split("+")
	local value_j = 0
	local value_d = 0
	local value_p = 0
	local value_t = 0
	if table.contains(items, "fzndz_1") then
	local judges = self.player:getJudgingArea()
		if not judges:isEmpty() then
			return "fzndz_1"
		end
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			local judges = p:getJudgingArea()
			if self:isFriend(p) then 
				if not judges:isEmpty() then
				value_j = value_j + 1
				end
			elseif self:isEnemy(p) and not judges:isEmpty() then
			value_j = value_j - 1
			end
		end
	end
	if table.contains(items, "fzndz_2") then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) then 
				if p:getHandcardNum() < 2 then
				value_d = value_d - 1
				end
			elseif self:isEnemy(p)  then
				if p:getHandcardNum() < 2 then
					value_d = value_d + 1
				end
			end
		end
	end
	if table.contains(items, "fzndz_3") then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) then 
				if self:getOverflow(p) > 0 then
				value_p = value_p - 1
				end
			elseif self:isEnemy(p)  then
				if self:getOverflow(p) > 0 then
					value_p = value_p + 1
				end
			end
		end
	end
	if table.contains(items, "fzndz_4") then
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if self:isFriend(p) then 
				if self:getOverflow(p) > 0 then
				value_t = value_t + 1
				end
			elseif self:isEnemy(p)  then
				if self:getOverflow(p) > 0 then
					value_t = value_t - 1
				end
			end
		end
	end
	local temp = value_j
	if value_d > temp then
	temp = value_d
	end
	if value_p > temp then
	temp = value_p
	end
	if value_t > temp then
	temp = value_t
	end
	if temp > 0 then
		if temp == value_j and table.contains(items, "fzndz_1") then
		return "fzndz_1"
		elseif temp == value_p and table.contains(items, "fzndz_3") then
		return "fzndz_3"
		elseif temp == value_t and table.contains(items, "fzndz_4") then
		return "fzndz_4"
		elseif temp == value_d and table.contains(items, "fzndz_2") then
		return "fzndz_2"
		end
	else
		if #items == 2 then
			return items[math.random(1,#items)]
		end
		return "cancel"
	end
	return items[math.random(1,#items)]
end


--攻略之神
sgs.ai_skill_invoke.gonglzs = function(self,data)
	local use = data:toCardUse()
	if not self.player:getJudgingArea():isEmpty() then
	return true
	end
	if self:isFriend(use.from) then
		if self:needToThrowArmor(self.player) and self:needToThrowArmor(use.from) then
			return true
		end
	else
		if self:needToThrowArmor(self.player) and not use.from:hasSkills(sgs.lose_equip_skill)  then
			return use.from:getCards("e"):length() > 0
		end
		if self.player:getCards("e"):length() > 0 and not use.from:hasSkills(sgs.lose_equip_skill) and ( use.from:getWeapon() and  use.from:getWeapon():isKindOf("Crossbow")) then
			return true
		end
		if self:getCardsNum("Jink") == 0 and self.player:getHandcardNum() ~= self:getCardsNum("Peach") then
			return use.from:getCards("h"):length() > 0
		end
		if self:getCardsNum("Jink") > 1   then
			return use.from:getCards("h"):length() > 0
		end
	end
	
	return false
end

sgs.ai_skill_cardchosen["gonglzs"] = function(self, who, flags)
	local cards = sgs.QList2Table(who:getCards(flags))
	self:sortByUseValue(cards, true)
	if self:isFriend(who) then
		if not who:getJudgingArea():isEmpty() then
			for _, judge in sgs.qlist(who:getJudgingArea()) do
				if not judge:isKindOf("YanxiaoCard") then
					return judge
				end
			end
		end
		if self:needToThrowArmor(who) then
			return who:getArmor()
		end
		return cards[1]
	else
		return cards[1]
	end
end
sgs.ai_choicemade_filter.cardChosen.gonglzs = sgs.ai_choicemade_filter.cardChosen.snatch

--神知
sgs.ai_skill_invoke.shens = function(self,data)
	local target = data:toDying().who
	if self:isFriend(target) then
		return true
	end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.shens = function(self,player,promptlist)
	local dying = self.room:getCurrentDyingPlayer()
	if dying then
		if promptlist[#promptlist]=="yes" then
			sgs.updateIntention(player,dying,-10)
		end
	end
end

sgs.save_skill = sgs.save_skill .. "|shens"

--魂曲

sgs.ai_skill_playerchosen["hunq"] = function(self, targets)
	return self:findPlayerToDraw(true, 1)
end

--破军歌姬
local pojgj_skill = {}
pojgj_skill.name = "pojgj"
table.insert(sgs.ai_skills, pojgj_skill)
pojgj_skill.getTurnUseCard = function(self)
	if self:isWeak() then return nil end

	local card_str = ("#pojgjCard:.:")
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#pojgjCard"] = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend(false, false)
	if self:isWeak() then return  end
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_priority["pojgj"] = 4.2
sgs.ai_card_intention["pojgj"] = -100

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|pojgj"

--目观 不完美 要改善

local LuamuguanVS_skill = {}
LuamuguanVS_skill.name = "LuamuguanVS"
table.insert(sgs.ai_skills, LuamuguanVS_skill)
LuamuguanVS_skill.getTurnUseCard = function(self)
	if not self.player:canDiscard(self.player,"he") then return end
	return sgs.Card_Parse("#LuamuguanCard:.:")
end

sgs.ai_skill_use_func["#LuamuguanCard"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	self:sortByUseValue(cards,true)
	if slashcount > 0  then
		for _, card in ipairs(cards) do
				if (not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink")) or self:getOverflow() > 0 then
				local slash = self:getCard("Slash")
					assert(slash)
					local target
					local dummy_use = self:aiUseCard(slash, dummy())
					if not dummy_use.to:isEmpty() then
						for _, p in sgs.qlist(dummy_use.to) do
							if p:getMark("muguan") == 0 then
							target = p
								break
							end
						end
					end
					--[[local dummy_use = {isDummy = true}
					self:useBasicCard(slash, dummy_use)
					local target
					for _, enemy in ipairs(self.enemies) do
						if self:canAttack(enemy, self.player)
							and not self:canLiuli(enemy, self.friends_noself) and not self:findLeijiTarget(enemy, 50, self.player)  then
							if enemy:getMark("muguan") == 0 then
							target = enemy
							else
								return
							end
						end
					end]]
						if target then
						use.card = sgs.Card_Parse("#LuamuguanCard:"..card:getId()..":")
								if use.to then use.to:append(target) end
								return
						end
				end
			end
	end
end

sgs.ai_card_intention["LuamuguanCard"] = 70


sgs.ai_use_value["LuamuguanCard"] = 9.2
sgs.ai_use_priority["LuamuguanCard"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_ajustdamage_from.Luamuguan = function(self, from, to, card, nature)
	if to and from:getMark("muguan") > 0 and to:getMark("muguan") > 0 and from:objectName() ~= to:objectName()
	then
		return 1
	end
end
sgs.ai_ajustdamage_to.Luamuguan = function(self, from, to, card, nature)
	if to and from:getMark("muguan") > 0 and to:getMark("muguan") > 0 and from:objectName() ~= to:objectName()
	then
		return 1
	end
end

--魂火
sgs.ai_view_as.soulfire = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if  not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0)
	and (card:isKindOf("Jink") or card:isKindOf("Slash"))   then
		return ("fire_slash:soulfire[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.ai_skill_invoke.soulfire = function(self,data)
	local target = data:toDamage().to
	if self:isEnemy(target) and self.player:getHp() > target:getHp() and self:objectiveLevel(target) > 3 and not self:cantbeHurt(target) and self:canDamage(target,self.player,nil) and self:damageIsEffective(target) then
	return true
	end
	return false
end

local soulfire_skill = {}
soulfire_skill.name = "soulfire"
table.insert(sgs.ai_skills,soulfire_skill)
soulfire_skill.getTurnUseCard = function(self,inclusive)
	local cards = self:addHandPile("he")
	cards = self:sortByUseValue(cards,true)
	local red_card = {}
	self:sort(self.enemies,"defense")
	for _,card in ipairs(cards)do
		if (card:isKindOf("Slash") or card:isKindOf("Jink"))
		and (self:getUseValue(card)<sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue,self.player,dummyCard("fire_slash"))>0)
		then table.insert(red_card,card) end
	end

	for _,card in ipairs(red_card)do
		local slash = dummyCard("fire_slash")
		slash:addSubcard(card)
		slash:setSkillName("soulfire")
		if slash:isAvailable(self.player)
		then return slash end
	end
end


local jfxl_skill = {}
jfxl_skill.name= "jfxl"
table.insert(sgs.ai_skills,jfxl_skill)
jfxl_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("#jfxl") then
		return sgs.Card_Parse("#jfxl:.:")
	end
end

sgs.ai_skill_use_func["#jfxl"] = function(card, use, self)
local handcards = sgs.QList2Table(self.player:getCards("he"))
	local use_card = {}
	self:sortByUseValue(handcards, true)
	for _,c in ipairs(handcards) do
		if (c:isKindOf("Jink") and self:getCardsNum("Jink") > 1) or not c:isKindOf("Peach") then
			table.insert(use_card, c)
		end
	end
		self:sort(self.enemies, "hp")
		local value = 0
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy,self.player,nil) then
				if enemy:distanceTo(self.player) == 1 and self.player:getHp() > enemy:getHp() and self.player:getHp() > 1 then
				value = value + 3
				end
			end
		end
	for _, friend in ipairs(self.friends_noself) do
		if friend:distanceTo(self.player) == 1 then
			if (not self:cantbeHurt(friend) or self:damageIsEffective(friend)) then
				value = value - 2
			end
		end
	end
	if value > 0 then
	use.card = sgs.Card_Parse("#jfxl:" .. use_card[1]:getEffectiveId()..":")
					
					return
					end
end

sgs.ai_use_value["#jfxl"] = 2.5
sgs.ai_card_intention["#jfxl"] = 80
sgs.dynamic_value.damage_card["#jfxl"] = true

--真红
sgs.ai_view_as.zhenhong = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if  not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) and player:getPhase() == sgs.Player_NotActive   then
		return ("fire_slash:zhenhong[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.hit_skill = sgs.hit_skill .. "|zhenhong"
sgs.ai_skill_invoke.tprs = function(self,data)
	local slash = sgs.Sanguosha:cloneCard("fire_slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	slash:setSkillName("tprs")
	local x = -(self.player:getHp() - 1)
	local targets_list = sgs.SPlayerList()
	for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:distanceTo(target) <= 1 then
			targets_list:append(target)
		end
	end
	if targets_list:length() > 0 then
		for _, target in sgs.qlist(targets_list) do
			if self.player:canSlash(target) and not self:slashProhibit(slash, target) and self:slashIsEffective(slash, target) and self:isGoodTarget(target, self.enemies, slash) then
				if self:isFriend(target) then
					x = x - (self.player:getHp() - 1)
				else
					x = x + (self.player:getHp() - 1)
				end
			end
		end
		for _, target in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if not targets_list:contains(target) and self.player:inMyAttackRange(target) then
				if self:isEnemy(target) then
					if not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) and not self:needToLoseHp(target, self.player) then
						x = x + 1
					else
						x = x - 1
					end
				elseif self:isFriend(target) then
					if self:needToLoseHp(target, self.player) and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) then
						x = x + 1
					else
						x = x - 1
					end
				end
			end
		end
		if x > 0 then
			return true
		end
	end
	return false
end
sgs.ai_ajustdamage_from.tprs = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:getSkillName() == "tprs" then
		return from:getMark("tprs")
	end
end

sgs.ai_skill_invoke.duanzui = function(self,data)
	local target = data:toPlayer()
	if self:isEnemy(target) then
		if not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player) and not self:needToLoseHp(target, self.player) then
			return true
		end
	elseif self:isFriend(target) then
		return self:needToLoseHp(target, self.player) and self:damageIsEffective(target, sgs.DamageStruct_Fire, self.player)
	end
	return false
end

--魅惑
sgs.ai_skill_invoke.meihuomoyan = function(self,data)
	local use = data:toCardUse()
	if self:isFriend(use.to:first()) then
		if self:isEnemy(use.from)
			or (self:isFriend(use.from) and self.role=="loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord()) then
				if use.card:isKindOf("Slash") then
					if not self:slashIsEffective(use.card,use.to:first(),use.from) then return false end
					if self:ajustDamage(use.from,use.to:first(),1,use.card)>1 then return true end
					
					if self:getCardsNum("Jink")<1 then
						if use.card:isKindOf("NatureSlash") and use.to:first():isChained() and not self:isGoodChainTarget(use.to:first(),use.card,use.from) then return true end
						if use.from:hasSkill("nosqianxi") and use.from:distanceTo(use.to:first())==1 then return true end
						if self:isFriend(use.from) and self.role=="loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord() and use.to:first():getHp()<2 then return true end
						if (not (self:hasSkills(sgs.masochism_skill) or (use.to:first():hasSkill("tianxiang") and getKnownCard(use.to:first(),use.to:first(),"heart")>0)) or use.from:hasSkill("jueqing"))  then
							return true
						end
					end
				elseif use.card:isKindOf("AOE") then
					local from = use.from
					if use.card:isKindOf("SavageAssault") then
						local menghuo = self.room:findPlayerBySkillName("huoshou")
						if menghuo then from = menghuo end
					end
		
					local friend_null = 0
					for _,p in sgs.qlist(self.room:getOtherPlayers(use.to:first()))do
						if self:isFriend(p) then friend_null = friend_null+getCardsNum("Nullification",p,use.to:first()) end
						if self:isEnemy(p) then friend_null = friend_null-getCardsNum("Nullification",p,use.to:first()) end
					end
					friend_null = friend_null+self:getCardsNum("Nullification")
					local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")
		
					if not self:hasTrickEffective(use.card,use.to:first(),from) then return false end
					if not self:damageIsEffective(use.to:first(),sgs.DamageStruct_Normal,from) then return false end
					if use.from:hasSkill("drwushuang") and use.to:first():getCardCount()==1 and self:hasLoseHandcardEffective() then return true end
					if sj_num==0 and friend_null<=0 then
						if self:isEnemy(from) and from:hasSkill("jueqing") then return true end
						if self:isFriend(from) and self.role=="loyalist" and from:isLord() and use.to:first():getHp()==1 and not from:hasSkill("jueqing") then return true end
						if (not (self:hasSkills(sgs.masochism_skill) or (use.to:first():hasSkill("tianxiang") and getKnownCard(use.to:first(),use.to:first(),"heart")>0)) or use.from:hasSkill("jueqing"))  then
							return true
						end
					end
				elseif self:isEnemy(use.from) then
					if not self:hasTrickEffective(use.card,use.to:first()) then return false end
					if use.card:isKindOf("FireAttack") and use.from:getHandcardNum()>0 then
						if not self:damageIsEffective(use.to:first(),sgs.DamageStruct_Fire,use.from) then return false end
						if (use.to:first():hasArmorEffect("vine") or use.to:first():getMark("&kuangfeng")>0) and use.from:getHandcardNum()>3
						and not(use.from:hasSkill("hongyan") and getKnownCard(use.to:first(),use.to:first(),"spade")>0)
						then return true
						elseif use.to:first():isChained() and not self:isGoodChainTarget(use.to:first(),nil,use.from)
						then return true end
					elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))
					and self:getCardsNum("Peach")==use.to:first():getHandcardNum() and not use.to:first():isKongcheng()
					then return true
					elseif use.card:isKindOf("Duel") then
						if self:getCardsNum("Slash")<1
						or self:getCardsNum("Slash")<getCardsNum("Slash",use.from,use.to:first()) then
							if not self:damageIsEffective(use.to:first(),sgs.DamageStruct_Normal,use.from) then return false end
							return true
						end
					end
				end
			end
	elseif self:isEnemy(use.to:first()) then
		if use.card:isKindOf("Peach") or use.card:isKindOf("ExNihilo") then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen["meihuomoyan"] = function(self, targets) 
	local targets = sgs.QList2Table(targets)
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	local card = use.card
	local target = use.to:first()
	local dummy_use = self:aiUseCard(card, dummy())
	if dummy_use.card and dummy_use.to:length() > 0 then
		for _,p in sgs.list(dummy_use.to)do
			if table.contains(targets, p) then
				return p
			end
		end
	end
	if card:isKindOf("Peach") then
		local arr1,arr2 = self:getWoundedFriend(false,true)
		local target = nil

		if #arr1>0 and (self:isWeak(arr1[1]) or self:getOverflow()>=1) and arr1[1]:getHp()<getBestHp(arr1[1]) then target = arr1[1] end
		if target and table.contains(targets, target) then
			return target
		end
		if self:getOverflow()>0 and #arr2>0 then
			for _,friend in ipairs(arr2)do
				if table.contains(targets, friend)  then
					return friend
				end
			end
		end
	end
	return nil
end
sgs.ai_skill_playerchosen.kaleidoscope = function(self, targets)
	targets = sgs.QList2Table(targets)
	return targets[math.random(1, #targets)]
end
sgs.ai_skill_cardask["@haniel"] = function(self, data, pattern)
	local hcards = self.player:getCards("he")
	hcards = sgs.QList2Table(hcards)
	self:sortByUseValue(hcards, true)
	for _, hcard in ipairs(hcards) do
		return "$" .. hcard:getEffectiveId()
	end
end

sgs.bad_skills = sgs.bad_skills .. "|haniel"

--观察
guancha_skill={}
guancha_skill.name="guancha"
table.insert(sgs.ai_skills,guancha_skill)
guancha_skill.getTurnUseCard=function(self,inclusive)
	if #self.friends <= 1 then return end
	local source = self.player
	if source:isKongcheng() then return end
	if source:hasUsed("#guancha") then return end
	return sgs.Card_Parse("#guancha:.:")
end

sgs.ai_skill_use_func["#guancha"] = function(card,use,self)
	local target
	local max_num =  math.floor((self.player:getHandcardNum() + 1) / 2)
	local max_x = 0
	for _,friend in ipairs(self.friends_noself) do
		local x = 5 - friend:getHandcardNum()
		if x > max_x and not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and self:canDraw(friend, self.player) then
			max_x = x
			target = friend
		end
	end
	local cards=sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	local needed = {}
	for _,acard in ipairs(cards) do
		if #needed < max_num then
			table.insert(needed, acard:getEffectiveId())
		end
	end
	if target and needed then
		use.card = sgs.Card_Parse("#guancha:"..table.concat(needed,"+")..":")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_use_value["guancha"] = 4
sgs.ai_use_priority["guancha"]  = 1
sgs.ai_card_intention["guancha"]  = -60

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|guancha"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|guancha"

--畸意
sgs.ai_skill_invoke.jiyi = function(self,data)
	local cardstr = sgs.ai_skill_use["@@jiyi"](self, "@jiyi")
    if cardstr:match(":.:") then
        return true
	end
	return false
end


sgs.ai_skill_use["@@jiyi"]=function(self,prompt)
	if self:isWeak() then return "." end
	if self:getOverflow() > 0 and self:getCardsNum("Peach") < 1 then return "." end
	return "#jiyi:.:"
end


sgs.ai_skill_choice.jiyi = function(self, choices)
    return "jiyi_throw"
end

sgs.ai_can_damagehp.jiyi = function(self, from, card, to)
	return to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to) and not self.player:isWounded()
end

--吃撑
sgs.ai_skill_invoke.Luachicheng = function(self, data)
	if self:needBear() then return true end
	if self.player:isSkipped(sgs.Player_Play) then return true end

	local chance_value = 1
	local peach_num = self:getCardsNum("Peach")
	local can_save_card_num = self:getOverflow(self.player, true) - self.player:getHandcardNum()

	if self.player:getHp() <= 2 and self.player:getHp() < getBestHp(self.player) then chance_value = chance_value + 1 end
	return self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) - can_save_card_num + peach_num  <= chance_value
end

sgs.ai_ajustdamage_from.lianjiqudong = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") then
		return from:getMark("@lianjiqudong")
	end
end

--轮回的宿命
sgs.ai_skill_invoke.lunhui1 = function(self, data)
	return true
end

sgs.ai_skill_use["@@lunhui"] = function(self, prompt, method)
	local will_use = self.player:getPile("lunhui")
	if will_use:isEmpty() then return "." end
	for _,id in sgs.qlist(will_use) do
		local card = sgs.Sanguosha:getCard(id)
		local dummy_use = self:aiUseCard(card, dummy())
		if dummy_use.card then
			local targets = {}
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					table.insert(targets, p:objectName())
				end
				if #targets > 0 then
					return card:toString() .. "->" .. table.concat(targets, "+")
				else
					return card:toString()
				end
			end
		end
		if card:isKindOf("EquipCard") then
			local dummy_use = dummy()
			self:useEquipCard(card,dummy_use)
			if dummy_use.card then
				return card:toString()
			end
		end
	end
	return "."
end


--破除的束缚
pocdsf_skill={}
pocdsf_skill.name="pocdsf"
table.insert(sgs.ai_skills,pocdsf_skill)
pocdsf_skill.getTurnUseCard=function(self,inclusive)
	local source = self.player
	if source:hasUsed("#pocdsf") then return end
	return sgs.Card_Parse("#pocdsf:.:")
end

sgs.ai_skill_use_func["#pocdsf"] = function(card,use,self)
	if self:isWeak(self.player) then return nil end 
	local targets = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	local value = 0
	for _, target in ipairs(targets) do
	local count = 0
	if self:isFriend(target) then
		if  target:getWeapon() and self:hasSkills(sgs.lose_equip_skill, target) then
			for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
				if target:inMyAttackRange(p) and self:isEnemy(p) then
					count = count + 1
				end
			end
			value = value - count
			end
		else
			if not target:getWeapon() or self:hasSkills(sgs.lose_equip_skill, target) then continue end
			for _, p in sgs.qlist(self.room:getOtherPlayers(target)) do
				if target:inMyAttackRange(p) and self:isFriend(p) then
					count = count + 1
				end
			end
			value = value + count
		end
	end
	if value >= 1 then 
		use.card = sgs.Card_Parse("#pocdsf:.:")
		return
	end
end
sgs.ai_use_value["pocdsf"] = 5
sgs.ai_use_priority["pocdsf"]  = 7

sgs.ai_can_damagehp.moxing = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and self:getCardsNum("Slash") > 0
	end
end

--祥瑞
sgs.ai_skill_invoke.xiangrui = function(self, data)
	local damage = data:toDamage()
	
	if self:hasHeavyDamage(damage.from, damage.card, self.player) then
		return true
	end
	if self:needToLoseHp(self.player, damage.from) and damage.damage <= 1 then return false end
	return true
end

sgs.ai_skill_use["@@xiangrui"] = function(self, prompt, method)
	self:sort(self.enemies)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local card = cards[1]
	if card then
		for _, enemy in ipairs(self.enemies) do
				if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy,self.player,nil) then
						return "#xiangruiCard:"..card:getEffectiveId() ..":->"..enemy:objectName()
				end
			end
		end
	return "."
end

sgs.ai_can_damagehp.xiangrui = function(self,from,card,to)
	local d = {damage=1}
	d.nature = card and sgs.card_damage_nature[card:getClassName()] or sgs.DamageStruct_Normal
	return sgs.ai_skill_use["@@xiangrui"](self,d,sgs.Card_MethodDiscard)~="." and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|xiangrui"


sgs.ai_ajustdamage_to.wnlz = function(self, from, to, card, nature)
	if not card or card:isVirtualCard() 
	then
		return -2
	end
	if card and card:isKindOf("Slash") then
		return 1
	end
end
--幻想杀手
hxss_skill={}
hxss_skill.name = "hxss"
table.insert(sgs.ai_skills,hxss_skill)
hxss_skill.getTurnUseCard=function(self)
	if self.player:getMark("hxss-PlayClear") > 0 then return end
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if  acard:isKindOf("BasicCard")  and (self:getDynamicUsePriority(acard)<sgs.ai_use_value.mouthgun) then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if not sgs.Sanguosha:getCard(id):isKindOf("Peach") 
			and sgs.Sanguosha:getCard(id):isKindOf("BasicCard") 
			and (self:getDynamicUsePriority(sgs.Sanguosha:getCard(id)) < sgs.ai_use_value.mouthgun)
			then
				card = sgs.Sanguosha:getCard(id)
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("mouthgun:hxss[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end
sgs.ai_cardneed.hxss = sgs.ai_cardneed.bignumber

--厨艺Max
Luachuyi_skill={}
Luachuyi_skill.name = "Luachuyi"
table.insert(sgs.ai_skills,Luachuyi_skill)
Luachuyi_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("he")
	cards=sgs.QList2Table(cards)

	local card

	self:sortByUseValue(cards,true)

	for _,acard in ipairs(cards)  do
		if  acard:isKindOf("EquipCard")  and (self:getDynamicUsePriority(acard)<sgs.ai_use_value.Peach) then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if not sgs.Sanguosha:getCard(id):isKindOf("Peach") 
			and sgs.Sanguosha:getCard(id):isKindOf("EquipCard") 
			and (self:getDynamicUsePriority(sgs.Sanguosha:getCard(id)) < sgs.ai_use_value.Peach)
			then
				card = sgs.Sanguosha:getCard(id)
			end
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("Peach:Luachuyi[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)

	assert(skillcard)

	return skillcard
end
sgs.ai_view_as.Luachuyi = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id))
	and card:isKindOf("EquipCard") and player:getPhase() == sgs.Player_NotActive and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0)
		and player:getMark("Global_PreventPeach") == 0 then
		return ("peach:Luachuyi[%s:%s]=%d"):format(suit, number, card_id)
	end
end
sgs.ai_cardneed.Luachuyi = function(to,card)
	return card:isKindOf("EquipCard")
end

--闪光连击
sgs.ai_skill_invoke.Lualianji = function(self, data)
	return true
end

sgs.ai_cardneed.Lualianji = sgs.ai_cardneed.slash

--geass
geasstarget_skill={}
geasstarget_skill.name="geass"
table.insert(sgs.ai_skills,geasstarget_skill)
geasstarget_skill.getTurnUseCard=function(self,inclusive)
	if #self.enemies < 1 then return end
	local source = self.player
	if source:hasUsed("#geasstarget") then return end
	return sgs.Card_Parse("#geasstarget:.:")
end

sgs.ai_skill_use_func["#geasstarget"] = function(card,use,self)
	local target
    self:sort(self.enemies, "handcard")
	sgs.reverse(self.enemies)
	for _,enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > 0 and enemy:getEquips():length() > 0 then
			target = enemy
			break
		end
	end
	if target  then
		use.card = sgs.Card_Parse("#geasstarget:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_askforag["geass"] = function(self, card_ids)
    local cards = {}
	self.geassTarget = nil
    for _, card_id in ipairs(card_ids) do
        table.insert(cards, sgs.Sanguosha:getCard(card_id))
    end
	self:sortByUseValue(cards)
	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMark("geass_touse") > 0 then
			target = p
		end
	end
    for _, card in ipairs(cards) do
        if card:isKindOf("Slash") then 
			for _,enemy in ipairs(self.enemies) do
				local def = self:getDefenseSlash(enemy)
				local eff = self:slashIsEffective(card, enemy) and self:isGoodTarget(enemy, self.enemies, card)

				if target:canSlash(enemy, card, true) and not self:slashProhibit(card, enemy, target) and eff then
				self.geassTarget = enemy
				return card:getEffectiveId() 
				end
			end
		--return card:getEffectiveId() 
		end
		if card:isKindOf("Analeptic") then 
			return card:getEffectiveId() 
		end
		if card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")  or card:isKindOf("SupplyShortage") or card:isKindOf("Indulgence")  then 
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card and dummy_use and dummy_use.to then
				self.geassTarget = dummy_use.to:first()
				return card:getEffectiveId() 
			end
		end
		
		if  card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") or card:isKindOf("GodSalvation") then 
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return card:getEffectiveId() 
			end
		end
		if card:isKindOf("EquipCard") and not self:hasSkills(sgs.lose_equip_skill, target) then
			if card:isKindOf("Weapon")  and target:getWeapon() and self:evaluateWeapon(card) < self:evaluateWeapon(target:getWeapon()) then return card:getEffectiveId() 
			elseif card:isKindOf("Armor") and target:getArmor() and self:evaluateArmor(card) < self:evaluateArmor(target:getArmor()) then return card:getEffectiveId()
			end
		end
    end
    return -1
end
sgs.ai_skill_use["@@geass"] = function(self, prompt, method)
	self:sort(self.enemies)
	local card = sgs.Sanguosha:getCard(self.player:getMark("geass"))
	if card then
		if card:targetFixed() then
			return "#geass:"..card:getEffectiveId() ..":"
		else
			if self.geassTarget then
			return "#geass:"..card:getEffectiveId()..":->"..self.geassTarget:objectName()
			end
		end
	end
	return "."
end
sgs.ai_card_intention["#geasstarget"] = 60

--智能AI
sgs.ai_skill_invoke.znai = function(self, data)
	local target = data:toPlayer()
	return target and self:isFriend(target)
end

sgs.ai_skill_choice["znai"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	
    if #items == 1 then
        return items[1]
	else
		if  (target:hasSkills(sgs.cardneed_skill) or self:isWeak(target)) then 
			return "znai2"
		end
		if  (target:hasSkills(sgs.need_equip_skill) and not self:isWeak(target)) then 
			for _, enemy in ipairs(self.enemies) do
				if (not enemy:getEquips():isEmpty()) and not enemy:hasSkills(sgs.lose_equip_skill) then
					return "znai1"
				end
			end	
		end
		
    end
    return "znai2"
end

sgs.ai_skill_use["@@znai"] = function(self, prompt, method)
	self:sort(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if (not enemy:getEquips():isEmpty()) and not enemy:hasSkills(sgs.lose_equip_skill) then
			return "#znai:.:->"..enemy:objectName()
		end
	end
	return "."
end
--被改变的命运
sgs.ai_skill_invoke.changedfate = function(self, data)
	local current = self.room:getCurrent()
	return current and self:isFriend(current)
end

--大命诗歌
sgs.ai_skill_invoke.tmsp = function(self, data)
	return self:isWeak() or sgs.ai_skill_invoke["tishen"](self, data)
end


--王之宝库
sgs.ai_skill_invoke.wangzbk = function(self, data)
	return true
end

--兵弑
sgs.ai_skill_cardask["@bings-increase"] = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return "." end
	if target:hasArmorEffect("silver_lion") then return "." end
	

	
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		if card:isKindOf("EquipCard") then return "$" .. card:getEffectiveId() end
	end
	return "."
end

sgs.ai_skill_cardask["@bings-decrease"] = function(self, data)
	local damage = data:toDamage()

	
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if damage.card and damage.card:isKindOf("Slash") then
		if self:hasHeavyDamage(damage.from, damage.card, self.player) then
			
			
			for _,card in ipairs(cards) do
				if card:isKindOf("EquipCard") then return "$" .. card:getEffectiveId() end
			end
		end
	end
	if self:needToLoseHp(self.player, damage.from) and damage.damage <= 1 then return "." end
	
	
	for _,card in ipairs(cards) do
		if card:isKindOf("EquipCard") then return "$" .. card:getEffectiveId() end
	end
	return "."
end

sgs.ai_ajustdamage_to.bings = function(self,from,to,card,nature)
	if to:getEquips():length()>0
	then return -1 end
end
sgs.ai_ajustdamage_from.bings = function(self,from,to,card,nature)
	if from:getEquips():length()>0 and not beFriend(to,from)
	then return 1 end
end

sgs.need_equip_skill = sgs.need_equip_skill .. "|bings"
sgs.ai_cardneed.bings = sgs.ai_cardneed.equip

--乖离剑

sgs.ai_skill_choice.guailj = function(self, choices, data)
	if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, self.player)
		or self:needToLoseHp(self.player, self.player) then return "guailj2" end
	if self:isWeak() and not self:needDeath() then return "guailj1" end

	local value = 0
	for _, equip in sgs.qlist(self.player:getEquips()) do
		if equip:isKindOf("Weapon") then value = value + self:evaluateWeapon(equip)
		elseif equip:isKindOf("Armor") then
			value = value + self:evaluateArmor(equip)
			if self:needToThrowArmor() then value = value - 5 end
		elseif equip:isKindOf("OffensiveHorse") then value = value + 2.5
		elseif equip:isKindOf("DefensiveHorse") then value = value + 5
		end
	end
	if value < 8 then return "guailj1" else return "guailj2" end
end

guailj_skill = {}
guailj_skill.name = "guailj"
table.insert(sgs.ai_skills, guailj_skill)
guailj_skill.getTurnUseCard = function(self)
	if self.player:getMark("@guailj") <= 0 then return end
	if self.room:getMode() == "_mini_13" then return sgs.Card_Parse("#guailj:.:") end
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

		if self:hasSkills(sgs.lose_equip_skill, player) or self:needToThrowArmor(player) then
			if self:isFriend(player) then good = good + 2
			else bad = bad + 2
			end
		end

		if not player:getArmor() then
			local lost_value = 0
			if self:hasSkills(sgs.masochism_skill, player) then lost_value = player:getHp()/2 end
			local hp = math.max(player:getHp(), 1)
			if self:isFriend(player) then bad = bad + (lost_value + 1) / hp
			else good = good + (lost_value + 1) / hp
			end
		end
	end

	if good > bad then return sgs.Card_Parse("#guailj:.:") end
end

sgs.ai_skill_use_func["#guailj"]=function(card,use,self)
	use.card = card
end

sgs.dynamic_value.damage_card["#guailj"] = true


--鬼缠
sgs.ai_skill_invoke.guichan = function(self, data)
	local target = data:toPlayer()
	if target then
		if self:isFriend(target) then
			local can_use = true
			for _, player in sgs.qlist(self.room:getAlivePlayers()) do
				if self:getAllPeachNum()+target:getHp()>0 then
					can_use = false
					break
				end
			end
			if can_use then
				return true
			else 
				return false
			end
		else
			return true
		end
	else
		return true
	end
	return true
end
--打反

sgs.ai_skill_invoke.dafan = function(self, data)
	local damage = data:toDamage()
	if damage and damage.from and self:isEnemy(damage.from) then
	return true
	end
	return false
end
sgs.ai_skill_cardask["@dafanuj-give"] = function(self, data)
	local damage = data:toDamage()
    local cards = sgs.QList2Table(self.player:getHandcards())
    self:sortByKeepValue(cards)
	if damage.to:objectName() == self.player:objectName() then
		local target = damage.from
		if damage.card and damage.card:isKindOf("Slash") then
            if self:hasHeavyDamage(damage.from, damage.card, self.player) then
                for _,card in ipairs(cards) do
                    if card:isKindOf("Slash") then return "$" .. card:getEffectiveId() end
                end
            end
        end
        if (self:needToLoseHp(self.player, damage.from)) and damage.damage <= 1 then 
            for _,card in ipairs(cards) do
                    if card:isKindOf("Slash") then return "$" .. card:getEffectiveId() end
                end
            else
            if damage.from:getHandcardNum() > self.player:getHandcardNum() then
                for _,card in ipairs(cards) do
                    if card:isKindOf("TrickCard") then return "$" .. card:getEffectiveId() end
                end
            end
        end
        return "$" .. cards[1]:getEffectiveId()
	elseif damage.from:objectName() == self.player:objectName() then
		if self.player:getHandcardNum() > damage.to:getHandcardNum() then
			for _,card in ipairs(cards) do
				if not card:isKindOf("TrickCard") then return "$" .. card:getEffectiveId() end
			end
		end
		if  getCardsNum("Slash", damage.to) > 0 then
			for _,card in ipairs(cards) do
				if  card:isKindOf("Slash") then return "$" .. card:getEffectiveId() end
			end
		end
	return "$" .. cards[1]:getEffectiveId()
	end
	return "$" .. cards[1]:getEffectiveId()
end

--绝剑
sgs.ai_skill_choice.juejian = function(self, choices, data)
	local good, bad = 0, 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) then
			if self:isFriend(player) then bad = bad + 1
			else good = good + 1
			end
		end
	end
	--if good == 0 then return end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(player:getHp(), 1)
		if getCardsNum("Analeptic", player) > 0 then
			if self:isFriend(player) then good = good + 1.0 / hp
			else bad = bad + 1.0 / hp
			end
		end

			local lost_value = 0
			if self:needToLoseHp(player, self.player) then lost_value = player:getHp()/2 end
			local hp = math.max(player:getHp(), 1)
			if self:isFriend(player) then bad = bad + (lost_value + 1) / hp
			else good = good + (lost_value + 1) / hp
			end
	end
	local value_lost = 0
	if good > bad then
		value_lost = good - bad
	end
	local value_dis = 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) then value_dis = value_dis - player:getHandcardNum() + 1
			else  value_dis = value_dis + player:getHandcardNum() - 1
			end
	end
	if value_lost > value_dis then
		return "juejian:ls"
	else
		return "juejian:qz"
	end
end

--圣母圣咏
sgs.ai_skill_cardask["@smsy"] = function(self,data)
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return "." end
	if target:hasArmorEffect("silver_lion") then return "." end
	if self:cantDamageMore(self.player, target) then return "." end

	
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,card in ipairs(cards) do
		return "#smsy:"..card:getEffectiveId() ..":"
	end
	return "."
end

sgs.ai_ajustdamage_from.smsy = function(self,from,to,card,nature)
	if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and from:canDiscard(from, "he") and not beFriend(to,from)
	then return 1 end
end
sgs.ai_cardneed.smsy = sgs.ai_cardneed.slash

local jiewq_skill = {}
jiewq_skill.name = "jiewq"
table.insert(sgs.ai_skills,jiewq_skill)
jiewq_skill.getTurnUseCard = function(self)
	if #self.enemies<=0 then return end
	if self:getAllPeachNum()<=0 then return end
	return sgs.Card_Parse("#jiewq:.:")
end

sgs.ai_skill_use_func["#jiewq"] = function(card,use,self)
	self.jiewq_lose = 0
	local slashcount = self:getCardsNum("Slash")-1
	self.jiewq_lose = math.min(slashcount,self.player:getHp())
	if self.jiewq_lose<=0 then return end
	local slash = self:getCard("Slash")
	local dummy_use = dummy()
	if slash then self:useBasicCard(slash,dummy_use) end
	if not dummy_use.card or dummy_use.to:isEmpty() then return end
	use.card = card
end
sgs.ai_use_priority["jiewq"] = sgs.ai_use_priority.TenyearQimouCard

sgs.ai_skill_choice.jiewq = function(self,choices)
	choices = choices:split("+")
	local num = self.jiewq_lose
	for _,choice in ipairs(choices)do
		if tonumber(choice)==num and self:getAllPeachNum() > 0 then return choice end
	end
	return choices[1]
end
sgs.ai_cardneed.jiewq = sgs.ai_cardneed.slash

sgs.ai_ajustdamage_from.jiewq = function(self,from,to,card,nature)
	if card and (card:isKindOf("Slash"))
	then return from:getMark("jiewq-Clear") end
end

sgs.ai_can_damagehp.saiya = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0 and to:getHp()<=1
	and self:canLoseHp(from,card,to)
end



--木偶之眼
sgs.ai_skill_cardask["@muou"] = function(self, data)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local target
	local min_hp = 999
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:getHp() < getBestHp(player) and self:isFriend(player) then
			if player:getHp() < min_hp then
				target = player
				min_hp = player:getHp()
			end
		end
	end
	if not target then
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if player:getHp() < getBestHp(player) and self:isEnemy(player) then
				if getCardsNum("Peach", player, self.player) > 0 then
					for _,card in ipairs(cards) do
						if card:isBlack() then
							return "$" .. card:getEffectiveId()
						end
					end
				end
			end
		end
	end
	if target then
		for _,card in ipairs(cards) do
			if card:isRed() and not card:isKindOf("Peach") then
				self.room:setPlayerMark(self.player, "mozy_red", 1)
				return "$" .. card:getEffectiveId()
			end
		end
	end
	return "."
end
sgs.ai_skill_playerchosen["mozy"] = function(self, targets)
	local target
	if self.player:getMark("mozy_red") > 0 then
		self.room:setPlayerMark(self.player, "mozy_red", 0)
		local min_hp = 999
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if player:getHp() < getBestHp(player) and self:isFriend(player) then
				if player:getHp() < min_hp then
					target = player
					min_hp = player:getHp()
				end
			end
		end
		return target
	else
		for _, player in sgs.qlist(self.room:getAlivePlayers()) do
			if player:getHp() < getBestHp(player) and self:isEnemy(player) then
				if getCardsNum("Peach", player) > 0 then
					target = player
				end
			end
		end
		return target
	end
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|mozy"

--直死魔眼
sgs.ai_skill_invoke.zsmy = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if not self:isEnemy(target) then return false end
	if target:hasArmorEffect("silver_lion") then return false end
	if self:cantDamageMore(self.player, target) then return false end
	if self:isWeak(target) and getCardsNum("Peach", target) < 1 and self:damageIsEffective(target, damage.nature, self.player) then
	return true
	end
	return false
end


--情殇哀逝
qsas_skill={}
qsas_skill.name="qsas"
table.insert(sgs.ai_skills,qsas_skill)
qsas_skill.getTurnUseCard=function(self,inclusive)
	if #self.enemies < 1 then return end
	local source = self.player
	if source:hasUsed("#qsas") then return end
	return sgs.Card_Parse("#qsas:.:")
end

sgs.ai_skill_use_func["#qsas"] = function(card,use,self)
	--local target
    self:sort(self.enemies, "defenseSlash")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local targets = {}
	local use_card
	local card = sgs.Sanguosha:cloneCard("Slash")
	card:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if not self:slashProhibit(card, enemy) and self:isGoodTarget(enemy, self.enemies, card) and card:targetFilter(sgs.PlayerList(), enemy, self.player) then
			if not self:needToLoseHp(enemy,self.player,card) then table.insert(targets, enemy) end
		end
	end
	for _, card in ipairs(cards) do
		if  card:isKindOf("TrickCard") then
			use_card = card
		end
	end
	if #targets > 0 and use_card then
		use.card = sgs.Card_Parse("#qsas:"..use_card:getEffectiveId() ..":")
		if use.to then use.to:append(targets[1]) end
		return
	end
end

sgs.ai_use_value["qsas"] = 5
sgs.ai_use_priority["qsas"]  = 7

sgs.ai_ajustdamage_from.nirendao = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") then
		return 1
	end
end
--逆刀刃
local nidaoren_skill = {}
nidaoren_skill.name = "nidaoren"
table.insert(sgs.ai_skills, nidaoren_skill)
nidaoren_skill.getTurnUseCard = function(self)
	if self.player:getMark("@nidaoren") == 0 or self.player:getHp() < 2 then return end
	return sgs.Card_Parse("#nidaorenCard:.:")
end
sgs.ai_skill_use_func["#nidaorenCard"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies,"defense")
	local acard = sgs.Card_Parse("#nidaorenCard:.:") --根据卡牌构成字符串产生实际将使用的卡牌
	assert(acard)
	local defense = 6
	local selfSub = self.player:getHandcardNum() - self.player:getHp()
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	local best_target, target = nil, nil
	if #self.enemies <= 1 then return "." end
	for _, enemy in ipairs(self.enemies) do
		local def = sgs.getDefense(enemy)
		
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and self.player:distanceTo(enemy) - math.min(self.player:getHp()-1, self:getCardsNum("Slash")) <= 1
	
		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif eff then
			if enemy:getHp() == 1 and getCardsNum("Jink", enemy) == 0 then best_target = enemy break end
			if def < defense then
				best_target = enemy
				defense = def
			end
			target = enemy
		end
		if selfSub < 0 then return "." end
	end

	if self.player:hasSkill("badaozhai") and self.player:getMark("@badaozhai") > 0 then
		local value = 0
		local players = self.room:getOtherPlayers(self.player)
		for _,p in sgs.qlist(players) do
			if p:getHp() < self.player:getMaxHp() - 1 then
				if self:isFriend(p) then
					value = value - 2
				elseif self:isEnemy(p) then
					value = value + 2
				end
			end
		end
		if self.player:getRole() == "loyalist" and self:isWeak(self.room:getLord()) and self:getCardsNum("Peach") < 1 then
			return 
		end

		if value > 0 then
			use.card=acard
		end
	else
		if best_target then
			if self:getCardsNum("Slash") > 1 and self.player:getHp() > 1 then
				use.card=acard
			end
		end
		if target then
			if self:getCardsNum("Slash") > 1 and self.player:getHp() > 2 then
				use.card=acard
			end
		end
		for _, c in sgs.qlist(self.player:getHandcards()) do
			local x = nil
			if isCard("ArcheryAttack", c, self.player) then
				x = sgs.Sanguosha:cloneCard("ArcheryAttack")
			elseif isCard("SavageAssault", c, self.player) then
				x = sgs.Sanguosha:cloneCard("SavageAssault")
			else continue end
	
			local du = { isDummy = true }
			self:useTrickCard(x, du)
			if (du.card) and self.player:getHp() > 1 then use.card=acard end
		end
	end

	
end
sgs.ai_skill_choice.nidaorendraw = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		for _, c in sgs.qlist(self.player:getHandcards()) do
			local x = nil
			if isCard("ArcheryAttack", c, self.player) then
				x = sgs.Sanguosha:cloneCard("ArcheryAttack")
			elseif isCard("SavageAssault", c, self.player) then
				x = sgs.Sanguosha:cloneCard("SavageAssault")
			else continue end
			
			local du = { isDummy = true }
			self:useTrickCard(x, du)
			if (du.card) then return tostring(self.player:getHp()-1) end
		end
		return tostring(math.min(self.player:getHp()-1, self:getCardsNum("Slash")))
    end
    return items[1]
end
sgs.ai_use_value["nidaorenCard"] = 2 --卡牌使用价值
sgs.ai_use_priority["nidaorenCard"] = 3 --卡牌使用优先级


--逆刀刃
local badaozhai_skill = {}
badaozhai_skill.name = "badaozhai"
table.insert(sgs.ai_skills, badaozhai_skill)
badaozhai_skill.getTurnUseCard = function(self)
	if self.player:getMark("@badaozhai") == 0  then return end
	return sgs.Card_Parse("#badaozhaiCard:.:")
end
sgs.ai_skill_use_func["#badaozhaiCard"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies,"defense")
	local acard = sgs.Card_Parse("#badaozhaiCard:.:") --根据卡牌构成字符串产生实际将使用的卡牌
	assert(acard)
	local value = 0
	local players = self.room:getOtherPlayers(self.player)
		for _,p in sgs.qlist(players) do
			if p:getHp() < self.player:getLostHp() then
				if self:isFriend(p) then
					value = value - 2
				elseif self:isEnemy(p) then
					value = value + 2
				end
			end
		end
		if self.player:getRole() == "loyalist" and self:isWeak(self.room:getLord()) and self:getCardsNum("Peach") < 1 then
			return 
		end

		if self.player:getLostHp() > 0 and value > 0 then use.card=acard end
        --if target and (du.card) and self.player:getHp() > 1 then use.card=acard end
end
sgs.ai_use_value["badaozhaiCard"] = 2 --卡牌使用价值
sgs.ai_use_priority["badaozhaiCard"] = 2 --卡牌使用优先级


local feils2_skill = {}
feils2_skill.name = "feils2"
table.insert(sgs.ai_skills, feils2_skill)

feils2_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#feils2") then return nil end
 
		return sgs.Card_Parse("#feils2:.:")
end

sgs.ai_skill_use_func["#feils2"] =function(card,use,self)
	self:sort(self.enemies, "defense")
	self.MingceTarget = nil
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy) 
				and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
				and enemy:objectName() ~= self.player:objectName() then
			self.MingceTarget = enemy
			break
		end
	end
 
	if self.MingceTarget then
	use.card = sgs.Card_Parse("#feils2:.:")
		if use.to then
			use.to:append(self.MingceTarget)
		end
	end
end

sgs.ai_use_value["feils2"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["feils2"] = sgs.ai_use_priority.Slash - 0.2

sgs.double_slash_skill = sgs.double_slash_skill .. "|feils2"

--救赎
sgs.ai_skill_invoke.jiushu = function(self, data)
	return true
end

sgs.ai_skill_use["@@jiushu"] = function(self, prompt, method, data)
	local first_card, second_card
	local first_found, second_found = false, false
	local use_card = {}
	if self.player:getHandcardNum() >= 2 then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		
		
		self:sortByKeepValue(cards)
		local useAll = false
		for _, fcard in ipairs(cards) do
			local fvalueCard = (isCard("Peach", fcard, self.player) or isCard("ExNihilo", fcard, self.player))
			if not fvalueCard then
				first_card = fcard
				first_found = true
				for _, scard in ipairs(cards) do
					local svalueCard = (isCard("Peach", scard, self.player) or isCard("ExNihilo", scard, self.player))
					if first_card ~= scard and (scard:getSuit() == first_card:getSuit() or first_card:getTypeId() == scard:getTypeId()) then
						if not svalueCard then
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
	local target = self.room:getCurrentDyingPlayer()
	if first_found and second_found and target and self:isFriend(target) then
		table.insert(use_card, first_card:getEffectiveId())
		table.insert(use_card, second_card:getEffectiveId())
		return "#jiushu:".. table.concat(use_card, "+") ..":"
	end
	
	return "."
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|jiushu"
sgs.save_skill = sgs.save_skill .. "|jiushu"
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|jiushu"

--协横
sgs.ai_skill_invoke.xieheng = function(self, data)
	return true
end

sgs.ai_skill_playerchosen["xieheng"] = function(self, targets)
	local target
	local cards = self.player:getCards("he")
	local have_red = false
		cards = sgs.QList2Table(cards)
		for _, fcard in ipairs(cards) do
			if fcard:isRed() and not fcard:isKindOf("Peach") then
				have_red = true
			end
		end
		if have_red then
			self:sortByKeepValue(cards)
			local min_hp = 999
			for _, player in sgs.qlist(self.room:getAlivePlayers()) do
				if player:getHp() < getBestHp(player) and self:isFriend(player) then
					if player:getHp() < min_hp then
						target = player
						min_hp = player:getHp()
					end
				end
			end
			return target
		else
		return self:findPlayerToDraw(true, 1)
		end
	return self:findPlayerToDraw(true, 1)
end

sgs.ai_playerchosen_intention.xieheng = -40
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|xieheng"
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|xieheng"

sgs.ai_skill_cardask["@xieheng"] = function(self, data)
	local target = data:toPlayer()
	local cards = self.player:getCards("he")
	if target and self:isFriend(target) and target:getHp() < getBestHp(target) then
		cards = sgs.QList2Table(cards)
		for _,card in ipairs(cards) do
				if card:isRed() and not card:isKindOf("Peach") then
					return "$" .. card:getEffectiveId()
				end
			end
		
	end
	return "."
end

--痛觉的止符
sgs.ai_skill_invoke.tjdzf = function(self, data)
	local damage = data:toDamage()
	if damage.from and damage.nature ~= sgs.DamageStruct_Normal and self:isFriend(damage.from) and self.player:isChained() and self:isGoodChainTarget(self.player, damage.card, damage.from, damage.damage) then return false end

	if self:needToLoseHp(damage.to,damage.from,damage.card) then return false end
	return true
end

--青刃的哀歌
sgs.ai_skill_invoke.qrdag = function(self, data)
	return true
end
sgs.ai_skill_choice["qrdag"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if self.player:getPile("qrdag_yin"):length() < self.player:getHp() and self.player:getHp() > 3  then
			return "qrdag_recover"
		end
    end
    return "qrdag_discard"
end

sgs.ai_cardneed.qrdag = sgs.ai_cardneed.slash

--粉毛
sgs.ai_skill_invoke.fenmao = function(self, data)
	return true
end

sgs.ai_skill_cardask["@fenmao-qp"] = function(self, data)
	local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards)
		for _,card in ipairs(cards) do
				if not card:isKindOf("Peach") then
					return "$" .. card:getEffectiveId()
				end
			end
	return "."
end

--常规
local changgui_skill={}
changgui_skill.name = "changgui"
table.insert(sgs.ai_skills,changgui_skill)
changgui_skill.getTurnUseCard = function(self,inclusive)
	if self.player:hasUsed("#changgui")then return false end
	local card_str = ("#changgui:%d:")
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#changgui"] = function(card, use, self)
	use.card = card
end
sgs.ai_use_priority["changgui"] = 9.4
sgs.ai_use_value["changgui"] = 4.4
--黑化
local heihua_skill = {}
heihua_skill.name = "heihua"
table.insert(sgs.ai_skills, heihua_skill)
heihua_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#heihua") then return false end
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h", true) then
			return sgs.Card_Parse("#heihua:.:")
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (not enemy:isKongcheng()) then
			return sgs.Card_Parse("#heihua:.:")
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "h", true) then
			return sgs.Card_Parse("#heihua:.:")
		end
	end
end
sgs.ai_skill_use_func["#heihua"] = function(card, use, self)
	self:sort(self.enemies, "defense")
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h", true) then
			use.card = sgs.Card_Parse("#heihua:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (not enemy:isKongcheng()) then
			use.card = sgs.Card_Parse("#heihua:.:")
			if use.to then use.to:append(enemy) end
			return
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:doDisCard(friend, "h", true) then
			use.card = sgs.Card_Parse("#heihua:.:")
			if use.to then use.to:append(friend) end
			return
		end
	end
end
sgs.ai_use_value["heihua"] = sgs.ai_use_value.Slash + 1
sgs.ai_use_priority["heihua"] = sgs.ai_use_priority.Slash + 1


--轮回
sgs.ai_skill_use["@@maware"] = function(self, data, method)
	if not method then method = sgs.Card_MethodUse end
	 local pattern = self.player:property("maware_use"):toString():split("+")
	local cards = sgs.QList2Table(self.player:getCards("h"))
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByKeepValue(cards)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	
	local willuse_card = {}
	local class_name = pattern[2]
	local value = 0
	for _,c in ipairs(cards) do 
	--if not c then return "." end
	if c:isKindOf("Peach")
	or (c:isKindOf("Jink") and self:getCardsNum("Jink") == 1)
	or (c:isKindOf("Analeptic") and self:getCardsNum("Analeptic") == 1 and self.player:getHp() <= 1)
	then
		else
		if #willuse_card < tonumber(pattern[1]) then
			table.insert(willuse_card, c:getEffectiveId())
			value = value + self:getKeepValue(c)
			else
				break
		end
	end
	end
	if string.find(class_name, "analeptic") and self.player:getHandcardNum() < 2 then return "." end
	if string.find(class_name, "peach") and not self.player:isWounded() then return "." end
	if #willuse_card < tonumber(pattern[1]) then return "." end
	local card_str = ("%s:samsara[%s:%s]=."):format(class_name, sgs.Card_NoSuit, -1)
	local use_card = sgs.Card_Parse(card_str)
	local card = sgs.Sanguosha:cloneCard(class_name, sgs.Card_NoSuit, -1)
	card:deleteLater()
	use_card:setSkillName("samsara")
	for i = 1, #willuse_card, 1 do
		use_card:addSubcard(willuse_card[i])
	end
	if value > self:getUseValue(use_card) and tonumber(pattern[1]) > 2 then return "." end
	
	if use_card:targetFixed() then
		if use_card:isKindOf("SavageAssault") then
			local savage_assault = sgs.Sanguosha:cloneCard("SavageAssault")
			savage_assault:deleteLater()
			if self:getAoeValue(savage_assault) <= 0 then
				return "."
			end
		end
		if use_card:isKindOf("ArcheryAttack") then
			local archery_attack = sgs.Sanguosha:cloneCard("ArcheryAttack")
			archery_attack:deleteLater()
			if self:getAoeValue(archery_attack) <= 0 then
				return "."
			end
		end
		if not use_card:isKindOf("Analeptic") and not use_card:isKindOf("Nullification") then
			return use_card:toString()
		end
	else
		if string.find(class_name, "slash") then
			local dummy_use = self:aiUseCard(use_card, dummy())
			local targets = {}
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					if self:getDefenseSlash(p) < 6 then
						table.insert(targets, p:objectName())
					end
				end
				if #targets > 0 then
					return use_card:toString() .. "->" .. table.concat(targets, "+")
				end
			end
		end
		if use_card:isNDTrick() then
			local dummy_use = self:aiUseCard(use_card, dummy())
			local targets = {}
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					table.insert(targets, p:objectName())
				end
				if #targets > 0 then
					return use_card:toString() .. "->" .. table.concat(targets, "+")
				end
			end
		end
	end
	return "."
end

sgs.ai_skill_choice["samsara"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if items[1] ~= "cancel"  then
			return  items[1]
		end
    end
    return "cancel"
end


--窥心
sgs.ai_skill_use["@@kuixin"] = function(self, prompt, method, data)
	local target
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if self.player:getHandcardNum() <= enemy:getHandcardNum() then
			target = enemy
			break
		end
	end
	if target then
		return "#kuixin:.:->"..target:objectName()
	end
	if self.player:getHandcardNum() > 3 then
		return "#kuixin:.:->"..target:objectName()
	end
	return "#kuixin:.:"
end



--战线防御二段技能
sgs.ai_skill_invoke.slash_defence = function(self, data)
	local damage = data:toDamage()
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	duel:setSkillName("zhanxianfanyu")
	if damage.to and self:isFriend(damage.to) and  self:needToLoseHp(damage.to, damage.from, damage.card) then
		return false
	end
	if damage.from and self:isFriend(damage.from) and not  self:needToLoseHp(damage.from, self.player, duel) then
		return false
	end
	return true
end
sgs.ai_skill_invoke.zhanxianfanyu = function(self, data)
	local change = data:toPhaseChange()
	self:sort(self.friends, "defenseSlash")
	if change.to == sgs.Player_Draw and self:ImitateResult_DrawNCards(self.player, self.player:getVisibleSkillList(true)) < 4 then
		for _,friend in ipairs(self.friends) do
			if self:isWeak(friend) then
				return true
			end
		end
		return false
	end
	if change.to == sgs.Player_Play and self:getOverflow() < 3 then
		for _,friend in ipairs(self.friends) do
			if self:isWeak(friend) then
				return true
			end
		end
		return false
	end
	return false
end
sgs.ai_skill_playerchosen.zhanxianfanyu = function(self, targets)
	local target
	self:sort(self.friends, "defenseSlash")
	for _,friend in ipairs(self.friends) do
        if self:isWeak(friend) and  friend:getMark("@zhanxianfanyu") == 0 then
            return friend
        end
    end
	return self.player
end
sgs.ai_playerchosen_intention.zhanxianfanyu = -40


--机械公敌
sgs.ai_skill_invoke.jixieshen = function(self, data)
	if self.player:getGeneralName() == "siluokayi" or self.player:getGeneral2Name() == "siluokayi" then
		return true
	end
	if self.player:getGeneralName() == "gaowen" or self.player:getGeneral2Name() == "gaowen" then
		if self:isWeak() then
			return true
		end
		if self:getCardsNum("Slash") > 0 then
			return true
		end
		if self:getCardsNum("Slash") > 0 or self:getCardsNum("Jink") > 0 then
			return true
		end
		return false
	end
	if self.player:getGeneralName() == "gemingji" or self.player:getGeneral2Name() == "gemingji" then
		if self:isWeak() then
			return true
		end
		if self:getCardsNum("Slash") > 0 then
			return false
		end
		if self:getCardsNum("Slash") == 0 or self:getCardsNum("Jink") == 0 then
			return true
		end
		return false
	end
	if self.player:getGeneralName() == "fuxiao" or self.player:getGeneral2Name() == "fuxiao" then
		if self:isWeak() then
			return false
		end
		if self:getCardsNum("Slash") > 0 then
			return true
		end
		if self:getCardsNum("Slash") == 0 or self:getCardsNum("Jink") == 0 then
			return true
		end
		return false
	end
	return false
end

sgs.ai_skill_choice["jixieshen"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if self:isWeak() and table.contains(items, "fuxiao") then
			return "fuxiao"
		end
		if self:getCardsNum("Slash") > 0 and table.contains(items, "gemingji")  then
			return "gemingji"
		end
		if (self:getCardsNum("Slash") == 0 or self:getCardsNum("Jink") == 0) and table.contains(items, "gaowen") then
			return "gaowen"
		end
    end
    return "siluokayi"
end

sgs.ai_skill_playerchosen.jixieshen = function(self, targets)
	local target = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, targets, false,0, false)
	return target
end

sgs.ai_skill_invoke["jixieshen:fixmachine"] = function(self, data)
    return true
end

sgs.ai_skill_choice["jixieshenfixmachine"] = function(self, choices, data)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if self:getMark("@fuxiao") <= 1 and table.contains(items, "fuxiao") then
			return "fuxiao"
		end
		if self:getMark("@gemingji") <= 1 and table.contains(items, "gemingji")  then
			return "gemingji"
		end
		if self:getMark("@gaowen") <= 1 and table.contains(items, "gaowen") then
			return "gaowen"
		end
    end
    return items[1]
end


--高文卡牌变化
local jixieshenchain_skill={}
jixieshenchain_skill.name="jixieshenchain"
table.insert(sgs.ai_skills,jixieshenchain_skill)
jixieshenchain_skill.getTurnUseCard=function(self)
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)

	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(cards, sgs.Sanguosha:getCard(id))
		end
	end

	local jink_card

	self:sortByUseValue(cards,true)

	for _,card in ipairs(cards)  do
		if card:isRed() then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:jixieshenchain[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash

end

sgs.ai_view_as.jixieshenchain = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if card:isRed() then
			return ("slash:jixieshenchain[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isBlack() then
			return ("jink:jixieshenchain[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

--拂晓伤害免疫
sgs.ai_ajustdamage_to.jixieshendefense = function(self, from, to, card, nature)
	if nature~= "N"
	then
		return -99
	end
end


sgs.ai_skill_invoke.jixieshenslash = function(self, data)
	local use = data:toCardUse()
	if self:hasHeavyDamage(self.player) then return false end
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) then
			if getCardsNum("Jink", p, self.player) > 0 and not self:needToLoseHp(p) and self:damageIsEffective(p, sgs.DamageStruct_Fire) then
				return false
			end
		else
			if not self:damageIsEffective(p, sgs.DamageStruct_Fire) then
				return false
			end
		end
	end
	return true
end
sgs.ai_cardneed.jixieshenslash = sgs.ai_cardneed.slash

sgs.ai_skill_playerchosen.loyal_inu = function(self, targets)
	if self.player:getRole() == "loyalist" then
		return self.room:getLord()
	end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:getRole() == "lord" and p:getRole() == "loyalist" then
			return p
		end
	end
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self.player:getRole() == p:getRole() then
			return p
		end
	end
	local player = self:AssistTarget()
	if player then
		return player
	end
	return nil
end
sgs.ai_playerchosen_intention.loyal_inu = -80

sgs.ai_skill_choice["kikann"] = function(self, choices, data)
	local items = choices:split("+")
		local target = self.room:findPlayerBySkillName("loyal_inu")
		if target then
			if target:getHandcardNum() > self.player:getHandcardNum() and table.contains(items, "kikann_2") then
				return "kikann_2"
			end
			if target:getHp() > self.player:getHp() and table.contains(items, "kikann_1") then
				return "kikann_1"
			end
		end
    return "cancel"
end

--绝对压制
sgs.ai_skill_choice.jueduiyazhi = function(self, choices)
	local items = choices:split("+")
	if self.player:getMark("@lanyu") > 4 and table.contains(items, "jueduiyazhi_loseMark") then return "jueduiyazhi_loseMark" end
	if self.player:getHp() + self:getCardsNum("Peach") > 3 then return "jueduiyazhi_losehp"
	else if table.contains(items, "jueduiyazhi_loseMark") then return "jueduiyazhi_loseMark" end
	end
	return "jueduiyazhi_losehp"
end

local jueduiyazhi_skill = {}
jueduiyazhi_skill.name = "jueduiyazhi"
table.insert(sgs.ai_skills,jueduiyazhi_skill)
jueduiyazhi_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#jueduiyazhiCard:.:")
end

sgs.ai_skill_use_func["#jueduiyazhiCard"] = function(card,use,self)
	local slashes = self:getCards("Slash")
	if #slashes<1 then return end
	self:sort(self.enemies,"hp")
	for _,enemy in sgs.list(self.enemies)do
		for _,slash in sgs.list(slashes)do
			local d = self:aiUseCard(slash)
			if d.card and d.to:contains(enemy) then
				use.card = card
				use.to:append(enemy)
				return
				
			end
		end
	end
end

sgs.ai_use_priority["jueduiyazhiCard"] = sgs.ai_use_priority.Slash+0.5
sgs.ai_use_value["jueduiyazhiCard"] = 3



sgs.double_slash_skill = sgs.double_slash_skill .. "|lanyuhua"
sgs.ai_cardneed.lanyuhua = sgs.ai_cardneed.slash

--光子巨炮
local guangzijupao_skill = {}
guangzijupao_skill.name = "guangzijupao"
table.insert(sgs.ai_skills, guangzijupao_skill)

guangzijupao_skill.getTurnUseCard = function(self, inclusive)
	if  self.player:getCards("he"):length() < 1 then return nil end
    if self.player:hasUsed("#guangzijupaoCard") then return nil end
	local card
		if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
				card = hcard
				break
		end
	end
		if card then 
		return sgs.Card_Parse("#guangzijupaoCard:.:")
		end
end

sgs.ai_skill_use_func["#guangzijupaoCard"] =function(card,use,self)
	self:sort(self.enemies, "defense")
	local target = nil
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy) 
						and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and not enemy:isNude()
						and enemy:objectName() ~= self.player:objectName() then
						target = enemy
					break
		end
	end
	local card
		if not card then
		local hcards = self.player:getCards("he")
		hcards = sgs.QList2Table(hcards)
		self:sortByUseValue(hcards, true)

		for _, hcard in ipairs(hcards) do
				card = hcard
				break
		end
	end
    if card then
	if target then
	use.card = sgs.Card_Parse("#guangzijupaoCard:"..card:getId()..":")
		if use.to then
			use.to:append(target)
		end
	end
	end
end

sgs.ai_use_value["guangzijupaoCard"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["guangzijupaoCard"] = sgs.ai_use_priority.Slash - 0.2
sgs.double_slash_skill = sgs.double_slash_skill .. "|guangzijupao"



--掩护


sgs.ai_skill_invoke.Luayanhu = function(self, data)
	local damage = data:toDamage()
	if damage.to and self:isFriend(damage.to) and self:damageIsEffective(damage.to, damage.nature, damage.from) then
		if self:isWeak(damage.to) or (not self:needToLoseHp(damage.to, damage.from, damage.card))  then
			return not self:isWeak()
		end
	end
	return false
end

--心锁
sgs.ai_skill_invoke.xinsuo = function(self, data)
	local target = self.room:getCurrent()
	if  sgs.ai_role[target:objectName()] ~= "neutral" or target:isLord()  then
			return true
	end
	return false
end

sgs.ai_skill_choice["xinsuo"] = function(self, choices, data)
	local target = self.room:getCurrent()
	local items = choices:split("+")
	
	if sgs.ai_role[target:objectName()]== "rebel" and table.contains(items, "rebel")  then
		return "rebel"	
	elseif target:isLord() and table.contains(items, "lord")  then 
		return "lord"	
	elseif sgs.ai_role[target:objectName()]== "loyalist" and table.contains(items, "loyalist")  then
		return "loyalist"	
	elseif sgs.ai_role[target:objectName()]== "renegade" and table.contains(items, "renegade")  then
		return "renegade"	
	end
	return items[1]
end

--凤缚
sgs.ai_skill_cardask["@fengfu-discard"] = function(self, data)
	local target = data:toPlayer()
	if self:isFriend(target) and not self:findLeijiTarget(target, 50, self.player) then return "." end
	local  has_black
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:isBlack() then has_black = card
		end
	end

	if has_black then return "$" .. has_black:getEffectiveId()
	else return "."
	end
end


--夜羽
yohane_skill={}
yohane_skill.name="yohane"
table.insert(sgs.ai_skills,yohane_skill)
yohane_skill.getTurnUseCard=function(self)
	if self.player:hasUsed("#yohane") then return end
	local t=0
	for _,p in ipairs(self.friends_noself) do
	    if p:getHandcardNum()>0 and p:property("xinsuo_set"):toString() ~= "" then t=t+1 end
	end
	for _,q in ipairs(self.enemies) do
	    if q:getHandcardNum()>0 and q:property("xinsuo_set"):toString() ~= "" then t=t+1 end
	end
	if t>1 then
	    return sgs.Card_Parse("#yohane:.:")
	end
end

sgs.ai_skill_use_func["#yohane"]=function(card,use,self)
    use.card=card
	if #self.friends_noself>=1 then
	    local friends={}
		self:sort(self.friends_noself, "handcard")
		self.friends_noself = sgs.reverse(self.friends_noself)
	    for _,friend in ipairs(self.friends_noself) do
		    if not friend:isAllNude() and friend:property("xinsuo_set"):toString() ~= "" then
		        table.insert(friends, friend)
			end
	    end
        if #friends>0 then
	        self:sort(self.enemies,"defense")
		    for _,enemy in ipairs(self.enemies) do
			    if not enemy:isAllNude() and  enemy:property("xinsuo_set"):toString() ~= "" and enemy:property("xinsuo_set"):toString() ~=   friends[1]:property("xinsuo_set"):toString()  then
				    if use.to then
					    use.to:append(enemy)
					    use.to:append(friends[1])
					    return
					end
				end
			end
		end
	end
	return nil 
end

sgs.ai_skill_cardask["#yohane-distribute"] = function(self, data)
	local targetslist = data:toString():split("+")
	local players = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	for _, p in ipairs(players) do
		if self:isEnemy(p)	and table.contains(targetslist, p:objectName())  then
			local handcard = self.player:getHandcards()
			handcard = sgs.QList2Table(handcard)
			self:sortByUseValue(handcard, true)
			for _, card in ipairs(handcard) do
				if card:isKindOf("DelayedTrick")  then 
					self.room:setTag("ai_yohane_card_id", sgs.QVariant(card:getEffectiveId()))
					return "$" .. card:getEffectiveId()
				end
			end
		
			for _, card in ipairs(handcard) do
				self.room:setTag("ai_yohane_card_id", sgs.QVariant(card:getEffectiveId()))
				return "$" .. card:getEffectiveId()
			end
		end
		if self:isFriend(p)	and table.contains(targetslist, p:objectName())  then
			local handcard = self.player:getHandcards()
			handcard = sgs.QList2Table(handcard)
			self:sortByUseValue(handcard)
			for _, card in ipairs(handcard) do
				self.room:setTag("ai_yohane_card_id", sgs.QVariant(card:getEffectiveId()))
				return "$" .. card:getEffectiveId()
			end
		end
	end
	local handcard = self.player:getHandcards()
			handcard = sgs.QList2Table(handcard)
			self:sortByUseValue(handcard, true)
	return "$" .. handcard[1]:getEffectiveId()
end

sgs.ai_skill_playerchosen.yohane = function(self, targets)
	local ai_yohane_card_id = self.room:getTag("ai_yohane_card_id"):toInt()
	self.room:removeTag("ai_yohane_card_id")
	local card = sgs.Sanguosha:getCard(ai_yohane_card_id)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local to_player = sgs.QVariant()
	for _, target in ipairs(targets) do
		if card:isKindOf("DelayedTrick") then 
			if self:isEnemy(target) and  (not self.player:isProhibited(target, card) and not target:containsTrick(card:objectName()) ) then
				to_player:setValue(target)
				self.room:setTag("ai_yohane_player", to_player)
				return target
			end
			if self:isFriend(target) then
				to_player:setValue(target)
				self.room:setTag("ai_yohane_player", to_player)
				return target
			end
		end
		if card:isKindOf("EquipCard") then
			if self:isFriend(target) then
				to_player:setValue(target)
				self.room:setTag("ai_yohane_player", to_player)
				return target
			end
		end
		local handcard = self.player:getHandcards()
			handcard = sgs.QList2Table(handcard)
			self:sortByUseValue(handcard)
		if card:getEffectiveId() == handcard[1]:getEffectiveId() then
			if self:isFriend(target) then
				to_player:setValue(target)
				self.room:setTag("ai_yohane_player", to_player)
				return target
			end
		end
		local handcard = self.player:getHandcards()
			handcard = sgs.QList2Table(handcard)
			self:sortByUseValue(handcard, true)
			if card:getEffectiveId() == handcard[1]:getEffectiveId() then
			if self:isEnemy(target) then
				to_player:setValue(target)
				self.room:setTag("ai_yohane_player", to_player)
				return target
			end
		end
	end
	return targets[1]
end


sgs.ai_skill_choice.yohane = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local target = self.room:getTag("ai_yohane_player"):toPlayer()
		self.room:removeTag("ai_yohane_player")
		if table.contains(items, "pe") and target and self:isFriend(target) then 
			return "pe"
		end
		if table.contains(items, "pj") and target and self:isEnemy(target) then 
			return "pj"
		end
    end
    return "ph"
end





--繁艺
sgs.ai_skill_choice.fanyi = function(self, choices)
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if self:needBear() then
			if table.contains(items, "5draw_ad")  then 
				return "5draw_ad"
			end
			if table.contains(items, "2maxcard_ad")  then 
				return "2maxcard_ad"
			end
			if table.contains(items, "3available_re")  then 
				return "3available_re"
			end
			if table.contains(items, "1range_re")  then 
				return "1range_re"
			end
		end
	if self.player:getAttackRange() >= 3 then
		if table.contains(items, "1range_re")  then 
			return "1range_re"
		end
	else
		if table.contains(items, "1range_ad") and self.player:getSlashCount() > 0 then 
			return "1range_ad"
		end
	end
	
	if self.player:getSlashCount() > 0 then
		if table.contains(items, "4target_ad") and #self.enemies > 1 then
			return "4target_ad"
		end
		if table.contains(items, "3available_ad")  then
			return "3available_ad"
		end
	else
		if table.contains(items, "3available_re")  then
			return "3available_re"
		end	
	end
	
	if table.contains(items, "5draw_ad")  then 
				return "5draw_ad"
	end
	if table.contains(items, "done")  then 
				return "done"
	end
	if table.contains(items, "2maxcard_re") and self:getOverflow() == 0  then 
				return "2maxcard_re"
	end
  end
    return items[1]
end


--疾航
sgs.ai_skill_invoke.jihang = function(self, data)

	return true
end


sgs.ai_skill_playerchosen.jihang = function(self, targets)
	
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isEnemy(target) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target)  then return target end
	end

	return targets[1]
end

--暗逆
sgs.ai_skill_playerchosen.anni = function(self, targets)
	local use = self.room:getTag("CurrentUseStruct"):toCardUse()
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	if not use.to:contains(self.player) then
		return self.player
	end

	for _, target in ipairs(targets) do
		if self:isFriend(target)  then return target end
	end

	return targets[1]
end

sgs.ai_skill_choice.anni = function(self, choices)
	
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		local use = self.room:getTag("CurrentUseStruct"):toCardUse()
		for _, t in sgs.qlist(use.to) do
			if table.contains(items, "anni_hit") and (getCardsNum("Jink", t) == 0 or self:canLiegong(t, use.from) )  then 
						return "anni_hit"
			end
		end
			if table.contains(items, "anni_miss")  then 
						return "anni_miss"
			end
  end
    return items[1]
end

sgs.ai_choicemade_filter.cardChosen.anni = sgs.ai_choicemade_filter.cardChosen.snatch

--娇性
sgs.ai_skill_choice.jiaoxing = function(self, choices)
	local target = self.room:getCurrent()
	local items = choices:split("+")
    if #items == 1 then
        return items[1]
	else
		if target then
			if self:isFriend(target) then
				if target:isSkipped(sgs.Player_Play) and table.contains(items, "indulgence")  then
					return "indulgence"
				end
				if target:isSkipped(sgs.Player_Draw) and table.contains(items, "supply_shortage")  then
					return "supply_shortage"
				end
				if target:getHandcardNum() < 3  and table.contains(items, "indulgence")  then
					return "indulgence"
				elseif target:getHandcardNum() >= 3  and table.contains(items, "supply_shortage")  then
					return "supply_shortage"
				end
			elseif self:isEnemy(target) then
				if target:isSkipped(sgs.Player_Play) and table.contains(items, "supply_shortage")  then
					return "supply_shortage"
				end
				if target:isSkipped(sgs.Player_Draw) and table.contains(items, "indulgence")  then
					return "indulgence"
				end
				if target:getHandcardNum() < 3  and table.contains(items, "supply_shortage")  then
					return "supply_shortage"
				elseif target:getHandcardNum() >= 3  and table.contains(items, "indulgence")  then
					return "indulgence"
				end
			end
		end
		
  end
    return "cancel"
end

sgs.ai_skill_use["@@jiaoxing"] = function(self, prompt, method)
	self:updatePlayers()

	local jiaoxing = self.player:property("jiaoxing"):toString():split("+")
	for _, id in sgs.list(jiaoxing) do
		local rcard = sgs.Sanguosha:getCard(tonumber(id))

		local indulgence = sgs.Sanguosha:cloneCard("Indulgence")
		indulgence:addSubcard(rcard)
		indulgence:setSkillName("jiaoxing")
		if not self.player:isLocked(indulgence) then
			
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useCardIndulgence(indulgence, dummy_use)
			if dummy_use.card and dummy_use.to:length() > 0 then
				return ("indulgence:jiaoxing[%s:%s]=%s->%s"):format(rcard:getSuitString(),rcard:getNumberString(),rcard:getId(),dummy_use.to:first():objectName())
			end
		end
	end
	return "."
end




--伞盾
sgs.ai_skill_choice.sandun = function(self, choices)
	local items = choices:split("+")
    
			
	for _,enemy in ipairs(self.enemies) do
		local def = self:getDefenseSlash(enemy)
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		local eff = self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)

		if not self.player:canSlash(enemy, slash, false) then
		elseif self:slashProhibit(nil, enemy) then
		elseif def < 6 and eff then return "use_slash"
		end
	end
    return "use_blackequip_discard"
end

sgs.ai_skill_playerchosen.sandun = sgs.ai_skill_playerchosen.zero_card_as_slash


sgs.need_equip_skill = sgs.need_equip_skill .. "|sandun"
sgs.ai_cardneed.sandun = sgs.ai_cardneed.equip

local xieyan_skill = {}
xieyan_skill.name = "xieyan"
table.insert(sgs.ai_skills, xieyan_skill)
xieyan_skill.getTurnUseCard = function(self, inclusive)
	self:updatePlayers()
	if self.player:isNude() then return end

	local handcards = sgs.QList2Table(self.player:getCards("h"))
	for _,c in ipairs(handcards) do
		--local poi = sgs.Sanguosha:cloneCard(c, sgs.Card_NoSuit, -1)
		if c:isAvailable(self.player) and not c:isKindOf("EquipCard") then
			return sgs.Card_Parse("#xieyancard:.:")
		end
	end
	

end

sgs.ai_skill_use_func["#xieyancard"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, true)
	local useable_cards = {}
	for _,c in ipairs(handcards) do
		if  not c:isKindOf("Analeptic")
		and not c:isKindOf("Jink") 
		and not c:isKindOf("Nullification")
		and not c:isKindOf("EquipCard")
		then
			table.insert(useable_cards, c)
		end
	end
	if #useable_cards == 0 then return end
	local card_str
	for _,c in ipairs(useable_cards) do
		if c:getTypeId() == sgs.Card_TypeTrick and not c:isKindOf("Nullification") and c:isAvailable(self.player)  then
			local dummy_use = self:aiUseCard(c, dummy())
			if dummy_use.card then 
				card_str = string.format("#xieyancard:%s:", c:getEffectiveId())
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				if not dummy_use.to:isEmpty() then
					for _, p in sgs.qlist(dummy_use.to) do
						if use.to then 
						use.to:append(p) 
						end
					end
					break
				end
				
			end
		elseif c:getTypeId() == sgs.Card_TypeBasic and c:isAvailable(self.player) then
			local dummy_use = self:aiUseCard(c, dummy())
			if dummy_use.card then 
				card_str = string.format("#xieyancard:%s:", c:getEffectiveId())
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				if not dummy_use.to:isEmpty() then
					for _, p in sgs.qlist(dummy_use.to) do
						if use.to then  
						use.to:append(p) 
						end
					end
					break
				end
			end
		end
	end
	return nil
end
sgs.ai_use_value.xieyancard = 8.5
sgs.ai_use_priority.xieyancard = 6.6


--速攻
sgs.ai_skill_invoke.sugong = function(self, data)

	return true
end
sgs.ai_skill_choice.sugong = function(self, choices)
	local items = choices:split("+")
    if self:getCardsNum("Peach") > 1 or self:needToLoseHp(self.player, nil, nil, true) then
		return "sugong:lius"
	end
			
	
    return "sugong:huix"
end

--复奏
sgs.ai_skill_invoke.fuzou = function(self, data)
	local use = data:toCardUse()
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) and p:getHandcardNum() >= 2 and p:getPhase() == sgs.Player_NotActive then
			return true
		end
	end
	return false
end


sgs.ai_skill_playerchosen.fuzou = function(self, targets)
	
	targets = sgs.QList2Table(targets)

	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:getHandcardNum() >= 2 and target:getPhase() == sgs.Player_NotActive then return target end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target) and target:getPhase() == sgs.Player_NotActive  then return target end
	end
	return targets[1]
end

function NextSuit(x)
	if (x == 0) then
		return 2
	elseif (x == 1) then
		return 3
	elseif (x == 2) then
		return 1
	elseif (x == 3) then
		return 0
	else
		return -1
	end
end
sgs.ai_card_priority.haiyin = function(self,card,v)
	if self.player:getPile("yun"):length() > 0 and NextSuit(sgs.Sanguosha:getCard(self.player:getPile("yun"):first()):getSuit())==card:getSuit()
	then return 10 end
end


--雨
sgs.ai_skill_invoke.tianqu = function(self, data)
	if self:isWeak() then
		if self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player, true) > self.player:getHp() and self:getCardsNum("Peach") > 0 then
			return false
		end
	end
	return true
end
sgs.ai_skill_playerchosen.tianqu_from = function(self, targets)
	
	self:sort(self.enemies,"handcard")
	local friends = {}
	for _, player in ipairs(self.friends_noself) do
		if not hasManjuanEffect(player) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return targets[1] end
	
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
				if (e_hand > f_hand - 1) and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
					return friend
				end
			end
		end
	end
	
	return targets[1]
end

sgs.ai_skill_playerchosen.tianqu_to = function(self, targets)
	
	self:sort(self.enemies,"handcard")
	local friends = {}
	for _, player in ipairs(self.friends_noself) do
		if not hasManjuanEffect(player) then
			table.insert(friends, player)
		end
	end
	if #friends == 0 then return targets[1] end
	
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
				if (e_hand > f_hand - 1) and (f_hand > 0 or e_hand > 0) and f_peach <= 2 then
					return enemy
				end
			end
		end
	end
	
	return targets[1]
end

sgs.ai_can_damagehp.tianqu = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and card and card:isKindOf("Slash") and not card:isKindOf("NatureSlash") and sgs.ai_skill_invoke.tianqu(self, sgs.QVariant())
end

--挽澜
sgs.ai_skill_invoke.htms_wanlan = function(self, data)
	if #self.enemies > 0 then
		for _, enemy in ipairs(self.enemies) do
			if  not enemy:isKongcheng() and self:objectiveLevel(enemy) > 3 and 
			not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and self:canDamage(enemy,self.player,nil)  then
			return self:doDisCard(enemy, "he")
			end
		end
	end
	return false
end
sgs.ai_skill_playerchosen.htms_wanlan = function(self, targets)
	
	targets = sgs.QList2Table(targets)

	for _, target in ipairs(targets) do
		if self:isEnemy(target) and not target:isKongcheng() and self:objectiveLevel(target) > 3 and 
			not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and not self:doDisCard(target, "he") and self:canDamage(target,self.player,nil) then 
			return target 
		end
	end
	
	return targets[1]
end
sgs.ai_skill_discard["htms_wanlan"] = function(self, discard_num, min_num, optional, include_equip)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByCardNeed(cards)
	local to_discard = {}
	for _, card in ipairs(cards) do
		if not card:isKindOf("Peach") and card:getNumber() > 8 then
			if #to_discard >= 2 then break end
				table.insert(to_discard, card:getEffectiveId())
			end
		end
	

	return to_discard
end



sgs.ai_skill_choice.htms_wanlan = function(self, choices)
    return "draw_one_card"
end



--煌轨
sgs.ai_skill_playerchosen["huanggui"] = function(self, targets) 
	local targets = sgs.QList2Table(targets)
	local use = self.room:getTag("huanggui"):toCardUse()
	local card = use.card
	local target
	if card:isKindOf("AmazingGrace") or card:isKindOf("ExNihilo") or card:isKindOf("EXCard_YJJG") then
		for _, friend in ipairs(self.friends) do
			if friend:hasSkills(sgs.cardneed_skill) and not self:needKongcheng(friend, true) and not hasManjuanEffect(friend) and self:hasTrickEffective(card, use.from, friend) 
			and self.player:getHandcardNum() > 	friend:getHandcardNum()	and table.contains(targets, friend)	then
				return friend
			end
		end
		return nil
	elseif  card:isKindOf("EXCard_TJBZ") then
		return nil
	elseif card:isKindOf("EXCard_YYDL")  then
		for _, friend in ipairs(self.friends) do
			if (self:hasSkills(sgs.lose_equip_skill, friend) or self:needToThrowArmor(friend)) and not hasManjuanEffect(friend) and self:hasTrickEffective(card, use.from, friend) and table.contains(targets, friend) 	then
				return friend
			end
		end
		return nil
	elseif card:isKindOf("GodSalvation") then
		local lord = self.room:getLord()
		if self:isWeak(lord) and self.player:getRole() == "loyalist" and self:hasTrickEffective(card, use.from, lord)  and table.contains(targets, lord) then
			return lord
		end
		self:sort(self.friends, "hp")
		if self:isWeak() and self:hasTrickEffective(card, use.from, self.player)  then
			return nil
		else
			for _, target in sgs.qlist(self.friends) do
				if self:hasTrickEffective(card, use.from, target) and target:getHp() < getBestHp(target)   and table.contains(targets, target) then
					return target
				end
			end
		end
		return nil
	elseif  card:isKindOf("Duel") or card:isKindOf("FireAttack") or card:isKindOf("EXCard_WWJZ") then
		local nature = sgs.DamageStruct_Normal
		if card:isKindOf("FireAttack") then
			nature = sgs.DamageStruct_Fire
		end
		self:sort(self.enemies, "hp")
		self:sort(self.friends, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, use.from, enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nature) and  table.contains(targets, enemy) and self:canDamage(enemy,self.player,nil)	then
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, use.from, enemy) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
		for _, friend in ipairs(self.friends) do
			if ((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, use.from, card)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, use.from, friend) or not self:damageIsEffective(friend, nature)  and  table.contains(targets, friend) then
				return friend
			end
		end
		return targets[1]
	elseif  card:isKindOf("ArcheryAttack") or card:isKindOf("SavageAssault") then
		local nature = sgs.DamageStruct_Normal
		if card:isKindOf("FireAttack") then
			nature = sgs.DamageStruct_Fire
		end
		self:sort(self.enemies, "hp")
		self:sort(self.friends, "hp")
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, use.from, enemy) and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, nature) and self:canDamage(enemy,self.player,nil) and not enemy:hasArmorEffect("vine") and  table.contains(targets, enemy) 	then
				return enemy
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:hasSkills(sgs.masochism_skill) and self:hasTrickEffective(card, use.from, enemy) and not self:cantbeHurt(enemy)  and not enemy:hasArmorEffect("vine") and self:canDamage(enemy,self.player,nil)	and  table.contains(targets, enemy) then
				return enemy
			end
		end
		for _, friend in ipairs(self.friends) do
			if (((friend:hasSkills(sgs.masochism_skill) or self:needToLoseHp(friend, use.from, card)) and not self:isWeak(friend)) or not self:hasTrickEffective(card, use.from, friend) or not self:damageIsEffective(friend, nature) or  friend:hasArmorEffect("vine")) and  table.contains(targets, friend) then
				return friend
			end
		end
		return targets[1]
	elseif card:isKindOf("Collateral") then
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if not (self:hasSkills(sgs.lose_equip_skill, enemy) and enemy:getWeapon()) and self:hasTrickEffective(card, use.from, enemy) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif card:isKindOf("Dismantlement")  or card:isKindOf("Snatch") then
		if self:isFriend(use.from) and (self.player:getJudgingArea():length() > 0 or self:hasSkills(sgs.lose_equip_skill, self.player)) and self:hasTrickEffective(card, use.from, self.player) then
			return nil
		end
			if card:isKindOf("Dismantlement") then
				self:sort(self.enemies, "handcard")
				for _, enemy in ipairs(self.enemies) do
					if self:doDisCard(enemy, "hej") and self:hasTrickEffective(card, use.from, enemy) and  table.contains(targets, enemy)	then
						return enemy
					end
				end
				for _, enemy in ipairs(self.enemies) do
					if  self:hasTrickEffective(card, use.from, enemy) and  table.contains(targets, enemy)	then
						return enemy
					end
				end
			end
	elseif card:isKindOf("GodFlower") or card:isKindOf("Snatch") then
		self:sort(self.enemies, "handcard")
		for _, enemy in ipairs(self.enemies) do
			if self:isEnemy(use.from) and self:hasTrickEffective(card, use.from, enemy) and (enemy:getJudgingArea():length() < 1 or not self:hasSkills(sgs.lose_equip_skill, enemy)) and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif card:isKindOf("IronChain") then
		for _, friend in ipairs(self.friends) do
			if self:hasTrickEffective(card, use.from, friend) and friend:isChained()  and  table.contains(targets, friend) then
				return friend
			end
		end
		
		for _, enemy in ipairs(self.enemies) do
			if  self:hasTrickEffective(card, use.from, enemy)  and  table.contains(targets, enemy) and not enemy:isChained()	then
				return enemy
			end
		end
	elseif card:isKindOf("DelayedTrick") then

		for _, enemy in ipairs(self.enemies) do
			if  not self.player:isProhibited(enemy, card) and not enemy:containsTrick(card:objectName())   and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	elseif card:isKindOf("Slash") then

		for _, enemy in ipairs(self.enemies) do
			if  not self:slashProhibit(card, enemy) 
				and self:slashIsEffective(card, enemy) 
				and  table.contains(targets, enemy)	then
				return enemy
			end
		end
	end
	
	return nil
end

sgs.ai_skill_invoke.fuqian = function(self, data)
	return self:isEnemy(self.room:getCurrent():getNextAlive())
end


--葬送
local zangsong_skill = {}
zangsong_skill.name = "zangsong"
table.insert(sgs.ai_skills, zangsong_skill)

zangsong_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#zangsongCard") then return nil end
	if  (#self.enemies == 0) then return nil end
		return sgs.Card_Parse("#zangsongCard:.:")
end

sgs.ai_skill_use_func["#zangsongCard"] =function(card,use,self)
	self:sort(self.enemies, "defense")
	local target
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy) 
						and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)
						and enemy:objectName() ~= self.player:objectName() and not enemy:isKongcheng() then
					target = enemy
					break
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
				if  not enemy:isKongcheng() then
					target = enemy
					break
		end
		end
	end
	if target then
	use.card = sgs.Card_Parse("#zangsongCard:.:")
		if use.to then
			use.to:append(target)
	end
	end
end

sgs.ai_use_value["zangsongCard"] = sgs.ai_use_value.Slash - 0.2
sgs.ai_use_priority["zangsongCard"] = sgs.ai_use_priority.Slash - 0.2

--剑武术
sgs.ai_skill_invoke.jianwushu = function(self, data)
	local target = data:toPlayer()
	return self:doDisCard(target, "he")
end

sgs.ai_choicemade_filter.cardChosen.jianwushu = sgs.ai_choicemade_filter.cardChosen.dismantlement

--C级佣兵
sgs.ai_event_callback[sgs.GameStart].Cjiyongbing = function(self, player, data)
		for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
			if sb:hasSkill("Cjiyongbing") then
				-- sgs.role_evaluation[sb:objectName()]["renegade"] = 0
				-- sgs.role_evaluation[sb:objectName()]["loyalist"] = 0
				sgs.roleValue[sb:objectName()]["renegade"] = 0
				sgs.roleValue[sb:objectName()]["loyalist"] = 0
				--local role, value = sb:getRole(), 1000
				--if role == "rebel" then role = "loyalist" value = -1000 end
				--sgs.role_evaluation[sb:objectName()]["renegade"] = 1000
				sgs.roleValue[sb:objectName()][sb:getRole()] = 1000
				sgs.ai_role[sb:objectName()] = sb:getRole()
				self:updatePlayers()
			end
		end
end

sgs.ai_event_callback[sgs.Death].Cjiyongbing = function(self, player, data)
		for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
			if sb:hasSkill("Cjiyongbing") then
				-- sgs.role_evaluation[sb:objectName()]["renegade"] = 0
				-- sgs.role_evaluation[sb:objectName()]["loyalist"] = 0
				sgs.roleValue[sb:objectName()]["renegade"] = 0
				sgs.roleValue[sb:objectName()]["loyalist"] = 0
				local role, value = sb:getRole(), 1000
				if role == "rebel" then role = "loyalist" value = -1000 end
				--sgs.role_evaluation[sb:objectName()][sb:getRole()] = 1000
				sgs.roleValue[sb:objectName()][sb:getRole()] = 1000
				sgs.ai_role[sb:objectName()] = sb:getRole()
				self:updatePlayers()
			end
		end
end
sgs.ai_event_callback[sgs.TurnStart].Cjiyongbing = function(self, player, data)
		for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
			if sb:hasSkill("Cjiyongbing") then
				-- sgs.role_evaluation[sb:objectName()]["renegade"] = 0
				-- sgs.role_evaluation[sb:objectName()]["loyalist"] = 0
				sgs.roleValue[sb:objectName()]["renegade"] = 0
				sgs.roleValue[sb:objectName()]["loyalist"] = 0
				local role, value = sb:getRole(), 1000
				if role == "rebel" then role = "loyalist" value = -1000 end
				--sgs.role_evaluation[sb:objectName()][sb:getRole()] = 1000
				sgs.roleValue[sb:objectName()][sb:getRole()] = 1000
				sgs.ai_role[sb:objectName()] = sb:getRole()
				self:updatePlayers()
			end
		end
end


--火力全开
sgs.ai_skill_invoke.huoliquankai = function(self, data)
	if #self.enemies > 0 then
		for _, enemy in ipairs(self.enemies) do
			if  self:objectiveLevel(enemy) > 3 and 
			not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and self:canDamage(enemy,self.player,nil)  then
			return self.player:getCards("he"):length() < 4
			end
		end
	end
	return false
end
sgs.ai_skill_playerchosen.huoliquankai = function(self, targets)
	
	targets = sgs.QList2Table(targets)

	for _, target in ipairs(targets) do
		if self:isEnemy(target)  and self:objectiveLevel(target) > 3 and 
			not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and self:canDamage(target,self.player,nil) then 
			return target 
		end
	end
	
	return targets[1]
end
--觉醒魔神
sgs.ai_skill_playerchosen.juexingmoshen = function(self, targets)
	
	targets = sgs.QList2Table(targets)

	for _, target in ipairs(targets) do
		if self:isEnemy(target)  and self:objectiveLevel(target) > 3 and 
			not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and self:canDamage(target,self.player,nil) then 
			return target 
		end
	end
	
	return nil
end



--无尽之书

sgs.ai_skill_invoke.wujinzhishu = function(self, data)
	return true
end



local chunrijilu_skill = {}
chunrijilu_skill.name = "chunrijilu"
table.insert(sgs.ai_skills, chunrijilu_skill)
chunrijilu_skill.getTurnUseCard = function(self, inclusive)
	self:updatePlayers()
	local choices = {}
	for _,id in sgs.qlist(self.player:getPile("s_ye")) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isAvailable(self.player) and self:getCardsNum(card:getClassName()) == 0 then
			table.insert(choices, card)
		end
	end

	if next(choices) then
		return sgs.Card_Parse("#chunrijilu:.:")
	end
end

sgs.ai_skill_use_func["#chunrijilu"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, true)
	local useable_cards = {}
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach")
		and not c:isKindOf("Analeptic")
		and not (c:isKindOf("Analeptic") and self:getCardsNum("Analeptic") == 1 and self.player:getHp() <= 1)
		and not (c:isKindOf("Jink") and self:getCardsNum("Jink") == 1)
		and not c:isKindOf("Nullification")
		and not c:isKindOf("SavageAssault")
		and not c:isKindOf("ArcheryAttack")
		and not c:isKindOf("Duel")
		and not c:isKindOf("Armor")
		and not c:isKindOf("DefensiveHorse")
		then
			table.insert(useable_cards, c)
		end
	end
	if #useable_cards == 0 then return end
	local card_str = string.format("#chunrijilu:%s:", useable_cards[1]:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
end

sgs.ai_use_priority["chunrijilu"] = 1
sgs.ai_use_value["chunrijilu"] = 3


sgs.ai_skill_use["@@chunrijilu!"] = function(self, prompt, method)
	for _,id in sgs.qlist(self.player:getPile("s_ye")) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isAvailable(self.player) and self:getCardsNum(card:getClassName()) == 0 then
			local dummy_use = self:aiUseCard(card, dummy())
			local targets = {}
			if not dummy_use.to:isEmpty() then
				for _, p in sgs.qlist(dummy_use.to) do
					table.insert(targets, p:objectName())
				end
				if #targets > 0 then
					card:setSkillName("chunrijilu")
					return card:toString() .. "->" .. table.concat(targets, "+")
				end
			end
		end
	end
	return "."
end

sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|chunrijilu"

sgs.ai_skill_use["@@haite"] = function(self, prompt, method)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) then
			table.insert(targets, enemy:objectName())
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:damageIsEffective(friend, sgs.DamageStruct_Normal) and self:needToLoseHp(friend, self.player, nil) then
			table.insert(targets, friend:objectName())
		end
	end
	if #targets > 0 then
		return "#haite:.:->" .. table.concat(targets, "+")
	end
end

local yueying_skill = {}
yueying_skill.name = "yueying"
table.insert(sgs.ai_skills,yueying_skill)
yueying_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#yueying:.:")
end

sgs.ai_skill_use_func["#yueying"] = function(card,use,self)
	sgs.ai_skill_use_func.ZhihengCard(card,use,self)
	if use.card then
		local str = use.card:toString()
		str = string.gsub(str,"@ZhihengCard","#yueying")
		str = string.gsub(str,"=",":")
		use.card = sgs.Card_Parse(str..":")
	end
end

sgs.ai_use_value["yueying"] = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority["yueying"] = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit["yueying"] = sgs.dynamic_value.benefit.ZhihengCard

function sgs.ai_cardneed.yueying(to,card)
	return not card:isKindOf("Jink")
end

sgs.ai_ajustdamage_to.hmrleiji = function(self, from, to, card, nature)
	local names = to:property("SkillDescriptionRecord_hmrleiji"):toString():split("+")
	if card then
		local name = card:objectName()
		if card:isKindOf("Slash") then name = "hmrleijiSlash" end
		if not table.contains(names, name) then
			return 1
		end
	end
end
sgs.ai_skill_invoke.jiyidiejia = function(self, data)
	local damage = data:toDamage()
	local names, name = damage.from:property("SkillDescriptionRecord_hmrleiji"):toString():split("+"), damage.card:objectName()
	if damage.card:isKindOf("Slash") then name = "hmrleijiSlash" end
	if self:isFriend(damage.to) then
		if not table.contains(names, name) and (not self:needToLoseHp(damage.to, damage.from, damage.card)) then
			return true
		end
	elseif self:isEnemy(damage.to) then
		if not table.contains(names, name) and self:cantbeHurt(damage.to,damage.from) and self:canDamage(damage.to,damage.from,nil) then
			return true
		end
		if table.contains(names, name) and not self:cantDamageMore(damage.from, damage.to) and self:ajustDamage(damage.from,damage.to, 1, damage.card) > 0 then
			return true
		end
	else
		return true
	end
	
	return false
end




--毒舌
sgs.ai_skill_invoke.dushe = function(self, data)
	local judge = data:toJudge()
	if self:needRetrial(judge) then
			return true
	end
	return false
end




--诅咒
local zuzhou_skill = {}
zuzhou_skill.name = "zuzhou"
table.insert(sgs.ai_skills, zuzhou_skill)
zuzhou_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getMark("@zuzhou") <= 0 then return end
	return sgs.Card_Parse("#zuzhouCard:.:")
end

sgs.ai_skill_use_func["#zuzhouCard"] = function(card, use, self)
	local weak_target = nil
	local target = nil
	self:updatePlayers()
	self:sort(self.enemies, "hp")
	self.enemies = sgs.reverse(self.enemies)
	
	for _, enemy in ipairs(self.enemies) do
		if self:objectiveLevel(enemy) > 3 and 
			not self:cantbeHurt(enemy) and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and self:canDamage(enemy,self.player,nil) and enemy:getHp() + self:getAllPeachNum(enemy) <= 2 then
		weak_target = enemy
		end
	end
	if weak_target == nil then return end
	use.card = card
	if use.to then use.to:append(weak_target) end
end

sgs.ai_use_priority["zuzhouCard"] = 0.5
sgs.ai_use_value["zuzhouCard"] = 0.5




--向阳使
sgs.ai_skill_use["@@xiangyangshi"] = function(self, prompt)
	self:updatePlayers()
	local targets = {}
	for _,p in ipairs(self.friends) do
			if ((p:getHp() < getBestHp(p)) or (p:getHp() < p:getMaxHp() * 2 and self.player:hasSkill("zhiyujz_jx"))) then table.insert(targets, p:objectName()) end
			if #targets >= self.player:getMark("@yanliao") then
				break
			end
		end
	if #targets > 0 then
		return "#xiangyangshi:.:->"..table.concat(targets, "+")
	end
	return "."
end


sgs.recover_hp_skill = sgs.recover_hp_skill .. "|xiangyangshi"

function sgs.ai_cardneed.xiangyangshi(to, card, self)
	return to:getHandcardNum() < 3
end


--圣诞暖阳
local shengdanny_skill = {}
shengdanny_skill.name = "shengdanny"
table.insert(sgs.ai_skills, shengdanny_skill)
shengdanny_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return nil end
	 if self.player:hasUsed("#shengdanny") then return nil end

	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)

	local compare_func = function(a, b)
		local v1 = self:getKeepValue(a) + ( a:isRed() and 50 or 0 ) + ( a:isKindOf("Peach") and 50 or 0 )
		local v2 = self:getKeepValue(b) + ( b:isRed() and 50 or 0 ) + ( b:isKindOf("Peach") and 50 or 0 )
		return v1 < v2
	end
	table.sort(cards, compare_func)

	local card_str = ("#shengdanny:%d:"):format(cards[1]:getId())
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#shengdanny"] = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target and self:getAllPeachNum(self.player) + target:getHp() > 0 then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
	if self:getOverflow() > 0 and #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if self:needToLoseHp(self.player, friend, nil) and self:damageIsEffective(friend, sgs.DamageStruct_Fire, self.player) and not self:cantbeHurt(friend) then
			use.card = card
			if use.to then use.to:append(friend) end
			return
		end
	end
end

sgs.ai_use_priority["shengdanny"] = 4.2
sgs.ai_card_intention["shengdanny"] = -100

sgs.dynamic_value.benefit["shengdanny"] = true

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|shengdanny"
function sgs.ai_cardneed.shengdanny(to, card, self)
	return to:getHandcardNum() < 3
end


--经验累积
sgs.ai_skill_invoke.leijijingyan = function(self, data)
	return true
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|leijijingyan"
function sgs.ai_cardneed.leijijingyan(to, card, self)
	return card:isKindOf("Peach")
end


--索尔斯
sgs.ai_skill_invoke.suoersiman = function(self, data)
	if #self.enemies > 0 and self:getCardsNum("Peach") == 0 then
		local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
		slash:deleteLater()
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy, slash) and not self:slashProhibit(slash, enemy) 
				and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash)  then
				return true
		end
	end
	end
	return false
end

sgs.ai_skill_playerchosen.suoersiman = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end

--隐蔽
sgs.ai_skill_invoke.yinbiman = function(self, data)
	if  #self.enemies > 0 and self:getCardsNum("Peach") + self.player:getHp() > 1 and self:getCardsNum("Jink") == 0 then
				return true
	end
	if self.player:getHp()  > getBestHp(self.player) then return true end
	if self.player:getMark("@jujiman") > 0 and self:getCardsNum("Peach") + self.player:getHp() > 0 then return true end
	return false
end
--狙击
sgs.ai_skill_invoke.jujiman = function(self, data)
	local selfSub = self:getOverflow()
	if selfSub > 2 then return false end
	for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy)  and self:canDamage(enemy,self.player,nil)
			and self:isGoodTarget(enemy, self.enemies, nil)  then
				return true
		end
		end
	return false
end
sgs.ai_skill_playerchosen.jujiman = function(self, targets)
	for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and not self:cantDamageMore(self.player, enemy) and self:canDamage(enemy,self.player,nil)
			and self:isGoodTarget(enemy, self.enemies, nil)  then
				return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
			if not self:cantbeHurt(enemy) and self:canDamage(enemy,self.player,nil) and self:damageIsEffective(enemy) and not self:cantDamageMore(self.player, enemy)  then
				return enemy
		end
	end
end



--明断
sgs.ai_skill_playerchosen.mingduan_put = function(self, targets)
	if self.player:isKongcheng() then
		for _, friend in ipairs(self.friends_noself) do
			if not friend:isKongcheng() then
				return friend
			end
		end
	end
	return self.player
end

sgs.ai_skill_cardask["@mingduanqiuh"] = function(self, data)
	local card = data:toCard()
	local handcards = sgs.QList2Table(self.player:getHandcards())
	if self.player:getPhase() ~= sgs.Player_Play then
		if hasManjuanEffect(self.player) then return "." end
		self:sortByKeepValue(handcards)
		for _, card_ex in ipairs(handcards) do
			if self:getKeepValue(card_ex) < self:getKeepValue(card) and not self:isValuableCard(card_ex) then
				return "$" .. card_ex:getEffectiveId()
			end
		end
	else
		if card:isKindOf("Slash") and not self:slashIsAvailable() then return "." end
		self:sortByUseValue(handcards)
		for _, card_ex in ipairs(handcards) do
			if self:getUseValue(card_ex) < self:getUseValue(card) and not self:isValuableCard(card_ex) then
				return "$" .. card_ex:getEffectiveId()
			end
		end
	end
	return "."
	
end



local yushicp_skill = {}
yushicp_skill.name = "yushicp"
table.insert(sgs.ai_skills, yushicp_skill)
yushicp_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:isWounded() then return end
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, true)
	local use_cards = {}
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") then
				table.insert(use_cards, c:getEffectiveId())
		end
	end
	if self:getOverflow() <= 0 then return end
	if #use_cards == 0 then return end
	for _, enemy in ipairs(self.enemies) do
			if self.player:isWounded() and getCardsNum("Peach", enemy, self.player) > 0  and not enemy:hasFlag("yushiflag") then
				return sgs.Card_Parse("#yushicp:" .. use_cards[1] .. ":" .. "peach")
			end
			if  getCardsNum("FireSlash", enemy, self.player) > 0 and not enemy:hasFlag("yushiflag") then
				return sgs.Card_Parse("#yushicp:" .. use_cards[1] .. ":" .. "fire_slash")
			end
			if getCardsNum("ThunderSlash", enemy, self.player) > 0 and not enemy:hasFlag("yushiflag") then
				return sgs.Card_Parse("#yushicp:" .. use_cards[1] .. ":" .. "thunder_slash")
			end
			if getCardsNum("NatureSlash", enemy, self.player) > 0 and not enemy:hasFlag("yushiflag") then
				return sgs.Card_Parse("#yushicp:" .. use_cards[1] .. ":" .. "slash")
			end
	end
end

sgs.ai_skill_use_func["#yushicp"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	self.room:writeToConsole(userstring)
	local use_cards = {}
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(handcards, true)
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") then
			table.insert(use_cards, c:getEffectiveId())
		end
	end
	card:addSubcard(use_cards[1])
	for _, enemy in ipairs(self.enemies) do
		if  getCardsNum(userstring, enemy, self.player) > 0  and not enemy:hasFlag("yushiflag") then
			use.card = card
			if use.to then use.to:append(enemy) end
		end
	end
end

sgs.ai_guhuo_card.yushicp = function(self,toname,class_name)
	local cards = {}
  	for i,p in sgs.list(self.room:getOtherPlayers(self.player))do
		for d,c in sgs.list(p:getCards("h"))do
			if c:isKindOf(class_name) and class_name=="Slash"
			then table.insert(cards,c) end
		end
	end
	self:sortByKeepValue(cards,nil,"l")
  	for d,c in sgs.list(cards)do
		if self:getCardsNum(class_name)>0 then break end
		return "#yushicp:.:"..toname
	end
end


--无视特性
sgs.ai_skill_invoke.wushitexing = function(self, data)
	local use = data:toCardUse()
	local good = 0
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal) then
			good = good - 1
		elseif self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal) then
			good = good + 1
		end
	end
	return good > 0
end

sgs.ai_cardneed.wushitexing = sgs.ai_cardneed.slash

--闪耀
sgs.ai_skill_invoke.shanyao = function(self,data)
	local effect = data:toCardEffect()
	local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	if self:isFriend(effect.to,self.player) then return false end
	if  effect.to and self:isEnemy(effect.to) and  self:slashIsEffective(slash, effect.to) and not self:slashProhibit(slash, effect.to) and self:isGoodTarget(effect.to, self.enemies, slash) then
	return true
	end
end
sgs.ai_card_priority.shanyao = function(self,card)
	if card:isKindOf("Slash") and card:isRed()
	then return 0.05 end
end

--剑速
sgs.ai_skill_playerchosen["jiansu"] = function(self, targets)
	local target = self.room:getCurrent()
	for _, enemy in ipairs(self.enemies) do
		if target and self:isFriend(target) and target:canSlash(enemy) and not self:slashProhibit(nil, enemy) and self:getDefenseSlash(enemy) <= 2 and self:isGoodTarget(enemy, self.enemies, nil)
				and enemy:objectName() ~= self.player:objectName() then
			return enemy
		end
	end
	return nil
end
sgs.ai_cardneed.shanyao = sgs.ai_cardneed.jiang
sgs.ai_cardneed.jiansu = sgs.ai_cardneed.slash

--预告
local yugao_skill = {}
yugao_skill.name = "yugao"
table.insert(sgs.ai_skills, yugao_skill)
yugao_skill.getTurnUseCard = function(self)
	 --if self.player:usedTimes("#yugao") < 2 then return nil end
	 if #self.enemies == 0 then return nil end
	 local id = self.room:getTag("yugao_card"):toInt()
	 if id ~= 0 then return nil end
	 if (self.player:getMark("@yugao") == 0) then return nil end

	local card_str = ("#yugao:.:")
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#yugao"] = function(card, use, self)
	
		self:sort(self.enemies, "handcard")
		self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end

end

sgs.ai_skill_use["@@yugao"] = function(self, prompt, method)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
		self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				return "#yugao:.:->"..enemy:objectName()
			end
		end
	for _, player in ipairs(sgs.QList2Table(self.room:getOtherPlayers(self.player))) do
		if not player:isKongcheng() then
			return "#yugao:->"..player:objectName()
		end
	end
	return "."
end

sgs.ai_skill_invoke.yugao = function(self,data)
	local target = data:toPlayer()
	if target then
		local cards = sgs.QList2Table(target:getCards("h"))
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if self:getUseValue(card) >= 6 then
				return true
			end
		end
		local id = self.room:getTag("yugao_card"):toInt()
		return id == 0 
	end
end

sgs.ai_skill_askforag["yugao"] = function(self, card_ids)
	local cards = {}
	for _, card_id in ipairs(card_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByUseValue(cards)
	if #cards > 0 then
		return cards[1]:getEffectiveId()
	end
end

sgs.ai_card_priority.guaidao = function(self,card)
	if card and card:hasFlag("cardTip:yugao")
	then return 1 end
end



--委托
sgs.ai_skill_invoke.weituo = function(self,data)
	local damage = data:toDamage()
	if damage.to and self:isFriend(damage.to) and damage.from and self:isEnemy(damage.from) then
		return true
	end
	if damage.to and self:isEnemy(damage.to) and damage.from and self:isEnemy(damage.from) then
		return true
	end
	return false
end

sgs.ai_skill_invoke.weituo11 = function(self,data)
	local damage = data:toDamage()
	if  damage.from and self:isEnemy(damage.from) then
		return true
	end
	return false
end

sgs.exclusive_skill = sgs.exclusive_skill .. "|yuanhuo"




--滞后
sgs.ai_skill_playerchosen["zhihouz"] = function(self, targets)
self:sort(self.enemies, "handcard")
			for _, enemy in ipairs(self.enemies) do
				if enemy:getHp() >= self.player:getHp() and not enemy:isKongcheng() then
					return enemy
				end
			end
	return nil
end
--争导
sgs.ai_skill_invoke.zhengdao = function(self,data)
	local use = data:toCardUse()
	
	if use.card then
	self:sort(self.enemies, "handcard")
		if use.card:getNumber() > 10 and self.player:getMark("@zhengdao") == 0 then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isKongcheng() then
					return true
				end
			end
		elseif use.card:getNumber() < 8 and self.player:getMark("@zhengdao") ~= 0 then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isKongcheng() then
					return true
				end
			end
		end
		if self:getUseValue(use.card) < 5.6 then
			for _, enemy in ipairs(self.enemies) do
				if not enemy:isKongcheng() then
					return true
				end
			end
		end
	end
	return false
end
sgs.ai_skill_playerchosen["zhengdao"] = function(self, targets)
	self:sort(self.enemies, "handcard")
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h", true) and self:hasSkills(sgs.dont_kongcheng_skill, enemy) then
			return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h", true) and self:hasSkills(sgs.cardneed_skill, enemy) then
			return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "h", true) then
			return enemy
		end
	end
	return nil
end



--机枪模式

sgs.ai_skill_invoke.jiqiangs = function(self,data)
	local use = data:toCardUse()
	local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
	slash:deleteLater()
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p,self.player) then return false end
		if  p and self:isEnemy(p) and  
		self:slashIsEffective(slash, p) and 
		not self:slashProhibit(slash, p) and 
		self:isGoodTarget(p, self.enemies, slash) then
		return true
		end
	end
end


sgs.ai_cardneed.jiqiangs = sgs.ai_cardneed.slash

function sgs.ai_cardneed.lanyushanbi(to,card,self)
	if not self:willSkipPlayPhase(to) then
		return (isCard("Jink", card, to) and getKnownCard(to, "Jink", true) == 0)
	end
end


--羁绊
local jibanvs_skill = {}
jibanvs_skill.name = "jibanvs"
table.insert(sgs.ai_skills, jibanvs_skill)
jibanvs_skill.getTurnUseCard = function(self, inclusive)

if not self.player:hasUsed("#jibanhyCard") then 
	local target 
	local players =  self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		--if p:hasSkill("slyanhuo") and not p:getPile("confuse"):isEmpty() and self:isEnemy(p) then
		if  p:hasSkill("jibanhy") and (self:isFriend(p) or sgs.ai_role[p:objectName()]=="neutral") then
			target = p
			break
		end
	end
	if target then
		return sgs.Card_Parse("#jibanhyCard:.:")
		end
	end
end


sgs.ai_skill_use_func["#jibanhyCard"] = function(card,use,self)
	local target
	local players = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		if p:hasSkill("jibanhy") and (self:isFriend(p) or sgs.ai_role[p:objectName()]=="neutral") then
			target = p
			break
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_event_callback[sgs.GameStart].chenmohy = function(self, player, data)
	for _, sb in sgs.qlist(self.room:getOtherPlayers(player)) do
		if sb:hasSkill("chenmohy") then
			-- sgs.role_evaluation[sb:objectName()]["renegade"] = 0
			-- sgs.role_evaluation[sb:objectName()]["loyalist"] = 0
			sgs.roleValue[sb:objectName()]["renegade"] = 0
			sgs.roleValue[sb:objectName()]["loyalist"] = 0
			local role, value = sb:getRole(), 1000
			if role == "rebel" then role = "loyalist" value = -1000 end
			--sgs.role_evaluation[sb:objectName()][role] = value
			sgs.roleValue[sb:objectName()][role] = 0
			sgs.ai_role[sb:objectName()] = sb:getRole()
			self:updatePlayers()
		end
	end
end



--微笑
sgs.ai_skill_playerchosen["weixiaojn"] = function(self, targets)
self:sort(self.enemies, "handcard")
self.enemies = sgs.reverse(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if  not enemy:isKongcheng() then
					return enemy
				end
			end
	return nil
end

--女子道
sgs.ai_skill_playerchosen["nvzidao"] = function(self, targets)
self:sort(self.enemies, "handcard")
self.enemies = sgs.reverse(self.enemies)
			for _, enemy in ipairs(self.enemies) do
				if  not enemy:isKongcheng() then
					return enemy
				end
			end
	return nil
end
local function card_for_nvzidao(self, who, return_prompt)
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (enemy:hasSkill("hongyan") or judge:isKindOf("Lightning")) then
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
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge)
							and not friend:getJudgingArea():isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge) then
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
			if card_id >= 0 and who:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and self:hasSkills(sgs.lose_equip_skill .. "|shensu" , friend) then
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

sgs.ai_skill_use["@@nvzidao"] = function(self, prompt)
	self:updatePlayers()
		self:sort(self.enemies, "defense")
		for _, friend in ipairs(self.friends) do
			if not friend:getCards("j"):isEmpty() and not friend:containsTrick("YanxiaoCard") and card_for_nvzidao(self, friend, ".") then
				-- return "@QiaobianCard=" .. card:getEffectiveId() .."->".. friend:objectName()
				return "#nvzidaoCard:.:->".. friend:objectName()
			end
		end

		for _, enemy in ipairs(self.enemies) do
			if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard") and card_for_nvzidao(self, enemy, ".") then
				-- return "@QiaobianCard=" .. card:getEffectiveId() .."->".. friend:objectName()
				return "#nvzidaoCard:.:->".. enemy:objectName()
			end
		end

		for _, friend in ipairs(self.friends_noself) do
			if not friend:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill, friend) and card_for_nvzidao(self, friend, ".") then
				return "#nvzidaoCard:.:->".. friend:objectName()
			end
		end

		local targets = {}
		for _, enemy in ipairs(self.enemies) do
			if card_for_nvzidao(self, enemy, ".") then
				table.insert(targets, enemy)
			end
		end

		if #targets > 0 then
			self:sort(targets, "defense")
			-- return "@QiaobianCard=" .. card:getEffectiveId() .."->".. targets[#targets]:objectName()
			return "#nvzidaoCard:.:->".. targets[#targets]:objectName()
		end
	return "."
end

sgs.ai_skill_cardchosen["nvzidaoCard"] = function(self, who, flags)
	if flags == "ej" then
		return card_for_nvzidao(self, who, "card")
	end
end
sgs.ai_skill_playerchosen["nvzidaoCard"] = function(self, targets)
	local who = self.room:getTag("nvzidaoTarget"):toPlayer()
	if who then
		if not card_for_nvzidao(self, who, "target") then self.room:writeToConsole("NULL") end
		return card_for_nvzidao(self, who, "target")
	end
end

sgs.ai_card_priority.nvzidao = function(self,card,v)
	if self.player:getMark("@weixiao")+card:getNumber() == 25
	then return 10 end
end
sgs.ai_card_priority.weixiaojn = function(self,card,v)
	if self.player:getMark("@weixiao")+card:getNumber() == 25
	then return 10 end
end


--传笑
sgs.ai_skill_invoke.chuanxiao = function(self,data)
	local damage = data:toDamage()
	if self:needToLoseHp(self.player, damage.from, damage.card) then return false end
	return true
end

sgs.ai_cardneed.yijizho = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|yijizho"

--缎带
duandai_skill = {}
duandai_skill.name = "duandai"
table.insert(sgs.ai_skills, duandai_skill)
duandai_skill.getTurnUseCard = function(self)
	if (self.player:hasFlag("duandai_e") and self.player:hasFlag("duandai_h") and self.player:hasFlag("duandai_j")	) then return end
	local card, target
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(player) then
		local judges = player:getJudgingArea()
		if not judges:isEmpty() and not self.player:hasFlag("duandai_j")  then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
							target = player
							break
				end
			end
		end

		local equips = player:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, player) and not self.player:hasFlag("duandai_e") then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip  target = player break
				elseif equip:isKindOf("Weapon") then card = equip  target = player break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(player) then
					card = equip
					target = player
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(player) or self:needToThrowArmor(player)) then
					card = equip
					target = player
					break
				end
			end

		end
	else
		local judges = player:getJudgingArea()
		if player:containsTrick("YanxiaoCard") and not self.player:hasFlag("duandai_j") then
			for _, judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					card = sgs.Sanguosha:getCard(judge:getEffectiveId())
							target = player
							break
				end
			end
		end
		if card==nil or target==nil then
			if  player:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, player) and not self.player:hasFlag("duandai_e") then 
			local card_id = self:askForCardChosen(player, "e", "snatch")
			if card_id >= 0 and player:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				
						target = player
						break
			end
			end
		end
		if card==nil or target==nil then
			if  not player:isKongcheng() and self:doDisCard(player, "hej") and not self.player:hasFlag("duandai_h") then 
			local card_id = self:askForCardChosen(player, "h", "snatch")
			if card_id >= 0 then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				
						target = player
						break
			end
			end
		end
	end
	end
	if card  and target then return sgs.Card_Parse("#duandai:.:") end
end

sgs.ai_skill_use_func["#duandai"]=function(card,use,self)
	local card, target
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(player) then
		local judges = player:getJudgingArea()
		if not judges:isEmpty() and not self.player:hasFlag("duandai_j")  then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
							target = player
							break
				end
			end
		end

		local equips = player:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, player) and not self.player:hasFlag("duandai_e") then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip  target = player break
				elseif equip:isKindOf("Weapon") then card = equip  target = player break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(player) then
					card = equip
					target = player
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(player) or self:needToThrowArmor(player)) then
					card = equip
					target = player
					break
				end
			end

		end
	else
		local judges = player:getJudgingArea()
		if player:containsTrick("YanxiaoCard") and not self.player:hasFlag("duandai_j") then
			for _, judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					card = sgs.Sanguosha:getCard(judge:getEffectiveId())
							target = player
							break
				end
			end
		end
		if card==nil or target==nil then
			if  player:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, player) and not self.player:hasFlag("duandai_e") then 
			local card_id = self:askForCardChosen(player, "e", "snatch")
			if card_id >= 0 and player:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				
						target = player
						break
			end
			end
		end
		if card==nil or target==nil then
			if  not player:isKongcheng() and self:doDisCard(player, "hej") and not self.player:hasFlag("duandai_h") then 
			local card_id = self:askForCardChosen(player, "h", "snatch")
			if card_id >= 0 then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				
						target = player
						break
			end
			end
		end
	end
	end
	if card  and target then
		use.card = sgs.Card_Parse("#duandai:.:") 
		if use.to then
			use.to:append(target)
		end
	end
end

sgs.ai_skill_cardask["@duandai"]=function(self, data, pattern, target)
	local dest = data:toPlayer()
	if dest and self:isFriend(dest) then return "." end
	local color = "red"
	if string.find(pattern, color) then
	else
		color = "black"
	end
	local all_cards = self.player:getCards("he")
	if all_cards:isEmpty() then return "." end
	local cards = {}
	for _, card in sgs.qlist(all_cards) do
		if not card:hasFlag("using") and card:isRed() and  color == "red" and not card:isKindOf("Peach")  then
			table.insert(cards, card)
			break
		end
		if not card:hasFlag("using") and card:isBlack() and  color == "black"  then
			table.insert(cards, card)
			break
		end
	end

	if #cards == 0 then return "." end
	if #cards > 0 then
		return "$" .. cards[1]:getId()
	end
	return "."
end

sgs.ai_skill_choice["duandai"] = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	local card
	if self:isFriend(target) then
		local judges = target:getJudgingArea()
		if not judges:isEmpty() and not self.player:hasFlag("duandai_j")  then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not card:isKindOf("YanxiaoCard") then
					return "duandai_j"
				end
			end
		end

		local equips = target:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, target) and not self.player:hasFlag("duandai_e") then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip   break
				elseif equip:isKindOf("Weapon") then card = equip   break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(target) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(target) or self:needToThrowArmor(target)) then
					card = equip
					break
				end
			end
			if card then
				return "duandai_e"
			end
		end
	else
		local judges = target:getJudgingArea()
		if target:containsTrick("YanxiaoCard") and not self.player:hasFlag("duandai_j") then
			for _, judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					card = sgs.Sanguosha:getCard(judge:getEffectiveId())
					return "duandai_j"
				end
			end
		end
		
			if  target:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, target) and not self.player:hasFlag("duandai_e") then 
			local card_id = self:askForCardChosen(target, "e", "snatch")
			if card_id >= 0 and target:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				return "duandai_e"
			end
			end
		
			if  not target:isKongcheng() and self:doDisCard(target, "hej") and not self.player:hasFlag("duandai_h") then 
			local card_id = self:askForCardChosen(target, "h", "snatch")
			if card_id >= 0 then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				return "duandai_h"
			end
			end
	end
	return items[1]
end

sgs.ai_skill_cardchosen["duandai"] = function(self, who, flags)
	local card
	if flags == "j" then
		if self:isFriend(who) then
			local judges = who:getJudgingArea()
		if not judges:isEmpty()   then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
							return card
						end
					end
				end
		elseif self:isEnemy(who) then
			local judges = who:getJudgingArea()
		if not judges:isEmpty()   then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if judge:isKindOf("YanxiaoCard") then
							return card
						end
					end
				end
		end
	end
	if flags == "e" then
	if self:isFriend(who) then
		local equips = who:getEquips()
		if not who and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, who)  then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip   break
				elseif equip:isKindOf("Weapon") then card = equip   break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(who) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(who) or self:needToThrowArmor(who)) then
					card = equip
					break
				end
			end
			if card then
				return card
			end
		end
		elseif self:isEnemy(who) then
			if  who:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, who)  then 
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				return card
			end
			end
		end
	end
	if flags == "h" then
		local cards = sgs.QList2Table(who:getHandcards())
		return cards[1]
	end
end

sgs.ai_cardneed.duandai = sgs.ai_cardneed.slash

--吐槽
sgs.ai_view_as.tucao = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place == sgs.Player_PlaceHand or player:getPile("wooden_ox"):contains(card_id) then
		if card:isKindOf("BasicCard") and not player:hasFlag("tucaoks") then
			return ("nullification:tucao[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end
sgs.ai_skill_playerchosen["tucao"] = function(self, targets)
	return self:findPlayerToDiscard("ej", true, false, targets, false)[1]
end

sgs.ai_skill_choice["#tucaoxx"] = function(self, choices)
	if self:getCardsNum("BasicCard") <= 1 then return "tucao:mp" end
	if self:findPlayerToDiscard("ej", true, false, nil, false) ~= {} and not self:isWeak() then
		return "tucao:qp"
		end
	return "tucao:mp"
end

sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|tucao"

function sgs.ai_cardneed.tucao(to,card,self)
	if not self:willSkipPlayPhase(to) then
		return (isCard("BasicCard", card, to) and getKnownCard(to, "BasicCard", true) == 0)
	end
end


--王位

local wangwei_skill = {}
wangwei_skill.name = "wangwei"
table.insert(sgs.ai_skills, wangwei_skill)
wangwei_skill.getTurnUseCard = function(self)
	if self.player:getHandcardNum() < 1 then return nil end
	if self.player:hasUsed("#wangwei") then return nil end
	
	return sgs.Card_Parse("#wangwei:.:")
end

sgs.ai_skill_use_func["#wangwei"] = function(card, use, self)
	local targets = sgs.SPlayerList()
	local cards = self.player:getCards("h")
	
	local use_card = {}
	cards = sgs.QList2Table(cards)
	if #cards == 0 then return end
	self:sortByKeepValue(cards)
	local color = cards[1]:isRed()
	for _, card in ipairs(cards) do
		if (card:isRed() and color) or (card:isBlack() and not color)  and not card:isKindOf("Peach") then
			table.insert(use_card, card:getId())
		end
	end
		if self.player:getMark("@wangquan") == 0 and #use_card > 0 then
			targets:append(self.player)
		end
		for _,p in ipairs(self.friends) do
			if targets:length() >= #use_card then
				break
			end
			if p:getMark("@wangquan") == 0 and not targets:contains(p) then targets:append(p) end
			
		end

	if targets:length() < #use_card  then
		table.removeOne(use_card, use_card[#use_card])
	end
	if targets:length() < #use_card  then
		table.removeOne(use_card, use_card[#use_card])
	end
	if targets:length()> 0 then
		if #use_card == 1 then
		use.card = sgs.Card_Parse("#wangwei:"..use_card[1] ..":")
		else
		use.card = sgs.Card_Parse("#wangwei:".. table.concat(use_card, "+")..":")
		end
		if use.to then use.to = targets end
		return
	end
end

sgs.ai_use_priority["wangwei"] = 4.2
sgs.ai_card_intention["wangwei"] = -100


--祈祷
sgs.ai_skill_choice["qidao"] = function(self, choices, data)
	local move = data:toMoveOneTime()
	local target = move.to
	local items = choices:split("+")
	local card_ids = sgs.IntList()
	for _, card_id in sgs.qlist(move.card_ids) do
					if (move.to_place == sgs.Player_PlaceHand) then
						card_ids:append(card_id)
					end
				end
	if target then
		if self:isFriend(target) then
			if self.player:getLostHp() > card_ids:length() then
				return "qidao_draw"
			end
		elseif self:isEnemy(target) then
			if target:canDiscard(target, "he") and table.contains(items, "qidao_dis") and self:doDisCard(target, "he") then
				return "qidao_dis"
			end
		end
	end
	return "cancel"
end

sgs.ai_choicemade_filter.skillChoice["qidao"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:hasFlag("qidao_target") then
			if choice == "qidao_draw" then
				sgs.updateIntention(player, p, -80)
			elseif choice == "qidao_dis" then
				sgs.updateIntention(player, p, 80)
			end
		end
	end
end

--祈愿
sgs.ai_skill_playerchosen["qiyuan"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	targets = sgs.reverse(targets)
	for _, target in ipairs(targets) do
		if self:isFriend(target) and  target:getMaxCards() < 4 then
			return target
		end
	end
end
local qiyuan_skill = {}
qiyuan_skill.name = "qiyuan"
table.insert(sgs.ai_skills, qiyuan_skill)
qiyuan_skill.getTurnUseCard = function(self)
	if self.player:getMark("qidao_lun") == 0 then return end
	if self.player:hasUsed("#qiyuan") or (self.player:getMark("@qiyuan") + self.player:getMaxCards() < 4) then return end
	return sgs.Card_Parse("#qiyuan:.:")
end

sgs.ai_skill_use_func["#qiyuan"] = function(wuqiancard, use, self)
	use.card = wuqiancard
end

--雷矢
sgs.ai_view_as.LuaLeishi = function(card, player, card_place)
    local suit = card:getSuitString()
    local number = card:getNumberString()
    local card_id = card:getEffectiveId()
    if (card_place ~= sgs.Player_PlaceSpecial or player:getPile("wooden_ox"):contains(card_id)) 
	and card_place == sgs.Player_PlaceHand and not card:hasFlag("using") and not player:hasFlag("LuaLeishi_used") then
        return ("thunder_slash:LuaLeishi[%s:%s]=%d"):format(suit, number, card_id)
    end
end

--元兴
local LuaLeishi_skill = {}
LuaLeishi_skill.name = "LuaLeishi"
table.insert(sgs.ai_skills, LuaLeishi_skill)
LuaLeishi_skill.getTurnUseCard = function(self, inclusive)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards)

		if self.player:getPile("wooden_ox"):length() > 0 then
			for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
				table.insert(cards, sgs.Sanguosha:getCard(id))
			end
		end

    local slash
    self:sortByUseValue(cards, true)
    for _, card in ipairs(cards) do
            slash = card
            break
    end

    if not slash then return nil end
    if self.player:hasFlag("LuaLeishi_used") then return nil end
		local card = sgs.Sanguosha:cloneCard("thunder_slash", sgs.Card_NoSuit, 0)
		card:addSubcard(slash)
		card:deleteLater()
	local dummy_use = self:aiUseCard(card, dummy())
    --self:useCardThunderSlash(slash, dummy_use)
    if dummy_use.card and dummy_use.to:length() > 0 then
        local use = sgs.CardUseStruct()
        use.from = self.player
        use.to = dummy_use.to
        use.card = slash
        local data = sgs.QVariant()
        data:setValue(use)
        if not sgs.ai_skill_invoke.fulu(self, data) then return nil end
    else return nil end

    if slash then
        local suit = slash:getSuitString()
        local number = slash:getNumberString()
        local card_id = slash:getEffectiveId()
        local card_str = ("thunder_slash:LuaLeishi[%s:%s]=%d"):format(suit, number, card_id)
        local mySlash = sgs.Card_Parse(card_str)

        assert(mySlash)
        return mySlash
    end
end


sgs.ai_skill_invoke.Luayuanxing = function(self, data)
    local damage = data:toDamage()
	if self:cantDamageMore(self.player,damage.to) then return false end
    if not self:isFriend(damage.to) then return true end
    return false
end

--怨灵
sgs.ai_skill_use["@@Luayuanling"]=function(self,prompt)
	self:updatePlayers()
	self:sort(self.enemies,"defense")
	local targets = {}
	if self.player:hasSkill("lianhuo") then
		if self.player:getHp() > 1 and not self.player:isChained() then table.insert(targets, self.player:objectName()) end
	end
	local x = math.max(self.player:getMark("Luayuanling"), 1) 
	for _, enemy in ipairs(self.enemies) do
		if #targets < x then
			if self:damageIsEffective(enemy, sgs.DamageStruct_Thunder) and not enemy:isChained() then
				table.insert(targets, enemy:objectName())
			end
		else break end	
	end
	if #targets > 0 then
	return "#Luayuanling:.:->"..table.concat(targets, "+")
	end
	return "."
end

--神裔
sgs.ai_skill_invoke.Luashenyi = function(self, data)
		if #self.enemies == 0 then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) then
				return true
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget  then
			return true
		end

		self:sort(self.friends, "handcard")
		self.friends = sgs.reverse(self.friends)
		for _, target in ipairs(self.friends) do
			if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
				and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) then
				return true
			end
		end

		for _, target in ipairs(self.friends) do
			if target:hasSkill("dawu") then
				local use = true
				for _, p in ipairs(self.friends) do
					if p:getMark("@fog") > 0 then use = false break end
				end
				if use then
					return true
				end
			else
				return true
			end
		end
	return sgs.ai_skill_playerchosen["Luashenyi"](self, self.room:getAlivePlayers()) ~= nil
end
sgs.ai_skill_playerchosen["Luashenyi"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	targets = sgs.reverse(targets)
	if #self.enemies == 0 then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) then
				return lord
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget  then
			return AssistTarget
		end

		self:sort(self.friends, "handcard")
		self.friends = sgs.reverse(self.friends)
		for _, target in ipairs(self.friends) do
			if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
				and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) then
				return target
			end
		end

		for _, target in ipairs(self.friends) do
			if target:hasSkill("dawu") then
				local use = true
				for _, p in ipairs(self.friends) do
					if p:getMark("@fog") > 0 then use = false break end
				end
				if use then
					return target
				end
			else
				return target
			end
		end
		return self.player
end

--结界
sgs.ai_skill_invoke.luajiejie = function(self, data)
    local target = data:toPlayer()
    if not self:isFriend(target) then return true end
    return false
end




--快晴
local luakuaiqing_skill = {}
luakuaiqing_skill.name = "luakuaiqing"
table.insert(sgs.ai_skills, luakuaiqing_skill)
luakuaiqing_skill.getTurnUseCard = function(self)
	sgs.ai_use_priority["#luakuaiqing"] = 3
	if self.player:getCardCount(true) < 2 then return false end
	if self:getOverflow() <= 0 then return false end
	if self:isWeak() and self:getOverflow() <= 1 then return false end
	return sgs.Card_Parse("#luakuaiqing:.:")
end
sgs.ai_skill_use_func["#luakuaiqing"] = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	local x = self.player:usedTimes("#luakuaiqing") + 1
	if x == 2 then
		if self.player:getArmor() and self.player:hasArmorEffect("silver_lion") and self.player:isWounded() then
			table.insert(unpreferedCards, self.player:getArmor():getEffectiveId())
		end
		if self.player:getHp() < 3 then
			local zcards = self.player:getCards("he")
			local  keep_jink, keep_analeptic, keep_weapon =  false, false
			local keep_slash = self.player:getTag("JilveWansha"):toBool()
			for _, zcard in sgs.qlist(zcards) do
				if self.player:isCardLimited(zcard, sgs.Card_MethodDiscard) then continue end
				if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
					local shouldUse = true
					if isCard("Slash", zcard, self.player)  then
						local dummy_use = self:aiUseCard(zcard, dummy())
						if dummy_use.card then
							if keep_slash then shouldUse = false end
							if dummy_use.to then
								for _, p in sgs.qlist(dummy_use.to) do
									if p:getHp() <= 1 then
										shouldUse = false
										if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
										break
									end
								end
								if dummy_use.to:length() > 1 then shouldUse = false end
							end
							if not self:isWeak() then shouldUse = false end
						end
					end
					if zcard:getTypeId() == sgs.Card_TypeTrick then
						local dummy_use = self:aiUseCard(zcard, dummy())
						if dummy_use.card then shouldUse = false end
					end
					if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
						local dummy_use = self:aiUseCard(zcard, dummy())
						if dummy_use.card then shouldUse = false end
						if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
					end
					if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
					if self.player:hasTreasure("wooden_ox") then shouldUse = false end
					if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
					if isCard("Jink", zcard, self.player) and not keep_jink then
						keep_jink = true
						shouldUse = false
					end
					if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
						keep_analeptic = true
						shouldUse = false
					end
					if shouldUse then
						if (table.contains(unpreferedCards, zcard:getId())) then continue end
						table.insert(unpreferedCards, zcard:getId())
					end
					if #unpreferedCards == 2 then
						use.card = sgs.Card_Parse("#luakuaiqing:" .. table.concat(unpreferedCards, "+")..":")
						return
					end
				end
			end
		end



		if #unpreferedCards < 2 then
			for _, c in ipairs(cards) do
				if not self.player:isCardLimited(c, sgs.Card_MethodDiscard) then
					if table.contains(unpreferedCards, c:getId()) then continue end
					table.insert(unpreferedCards, c:getId())
				end
				if #unpreferedCards == 2 then break end
			end
		end

		if #unpreferedCards == 2 then
			use.card = sgs.Card_Parse("#luakuaiqing:" .. table.concat(unpreferedCards, "+")..":")
			sgs.ai_use_priority["#luakuaiqing"] = 0
			return
		end
	elseif x == 1 then
		local  keep_jink  =  false
		local keep_weapon
		for _, c in ipairs(cards) do
			if not isCard("Peach", c, self.player) and not isCard("ExNihilo", c, self.player) then
				local shouldUse = true
				if isCard("Slash", c, self.player)  then
					local dummy_use = self:aiUseCard(c, dummy())
					if dummy_use.card then
						if dummy_use.to then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:getHp() <= 1 then
									shouldUse = false
									if self.player:distanceTo(p) > 1 then keep_weapon = self.player:getWeapon() end
									break
								end
							end
							if dummy_use.to:length() > 1 then shouldUse = false end
						end
						if not self:isWeak() then shouldUse = false end
					end
				end
				if c:getTypeId() == sgs.Card_TypeTrick then
					local dummy_use = self:aiUseCard(c, dummy())
						if dummy_use.card then shouldUse = false end
					end
					if c:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(c) then
						local dummy_use = self:aiUseCard(c, dummy())
						if dummy_use.card then shouldUse = false end
						if keep_weapon and c:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
					end
				if isCard("Jink", c, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:hasEquip(c) and c:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(c) and c:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if shouldUse then
						if (table.contains(unpreferedCards, c:getId())) then continue end
						table.insert(unpreferedCards, c:getId())
					end
					if #unpreferedCards == x then
						use.card = sgs.Card_Parse("#luakuaiqing:" .. table.concat(unpreferedCards, "+")..":")
						return
					end
			end
		end	
	end
end

sgs.ai_use_priority["#luakuaiqing"] = 3


--桀骜

luajieao_skill = {}
luajieao_skill.name = "luajieao"
table.insert(sgs.ai_skills, luajieao_skill)
luajieao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#luajieao") then return nil end
	
	self:sort(self.enemies, "handcard")
	return sgs.Card_Parse("#luajieao:.:")
end

sgs.ai_skill_use_func["#luajieao"] = function(card, use, self)

	local max_card = self:getMaxCard()
	
	if not max_card then return end
	if max_card:isKindOf("Jink") and self:getCardsNum("Jink") <= 1 then return end
	
	local max_point = max_card:getNumber()

	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self:damageIsEffective(enemy, nil, self.player) and self.player:canPindian(enemy) then
			local enemy_max_card = self:getMaxCard(enemy)
			local enemy_max_point = enemy_max_card and enemy_max_card:getNumber() or 100
			if (max_point > enemy_max_point) or (max_point > 9) then
				local card_str = string.format("#luajieao:%s:", max_card:getEffectiveId())
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				--use.card = card
				
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end
sgs.ai_cardneed.luajieao = sgs.ai_cardneed.bignumber




--经纶
sgs.ai_skill_invoke.luajinlun = function(self, data)

	
	
		if #self.enemies == 0 then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) and lord:getHandcardNum() < 3 then
				return true
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget and not self:willSkipPlayPhase(AssistTarget) and AssistTarget:getHandcardNum() < 3 then
			return true
		end

		self:sort(self.friends, "handcard")
		for _, target in ipairs(self.friends) do
			if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
				and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) and target:getHandcardNum() < 3  then
				return true
			end
		end

		for _, target in ipairs(self.friends) do
			if target:hasSkill("dawu") and target:getHandcardNum() < 3  then
				local use = true
				for _, p in ipairs(self.friends_noself) do
					if p:getMark("@fog") > 0 then use = false break end
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

sgs.ai_skill_playerchosen["luajinlun"] = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "handcard")
	targets = sgs.reverse(targets)
	if #self.enemies == 0  then
			local lord = self.room:getLord()
			if lord and self:isFriend(lord) and lord:getHandcardNum() < 3 then
				return lord
			end
		end

		local AssistTarget = self:AssistTarget()
		if AssistTarget and AssistTarget:getHandcardNum() < 3  then
			return AssistTarget
		end

		self:sort(self.friends, "handcard")
		for _, target in ipairs(self.friends) do
			if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|" .. sgs.priority_skill .. "|shensu")
				and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) and target:getHandcardNum() < 3 then
				return target
			end
		end

		for _, target in ipairs(self.friends) do
			if  target:getHandcardNum() < 3 then
				if target:hasSkill("dawu") then
					local use = true
					for _, p in ipairs(self.friends) do
						if p:getMark("@fog") > 0 then use = false break end
					end
					if use then
						return target
					end
				else
					return target
				end
			end
		end
		return self.player
end


--噩梦派对
sgs.ai_skill_invoke.empaidui = function(self, data)
	
	local empaidui_string = sgs.ai_skill_use["@@empaidui"](self, prompt, method)
	if empaidui_string == "." then
		return false
	end
	return true
end
sgs.ai_skill_use["@@empaidui"]=function(self,prompt)
	self:updatePlayers()
	self:sort(self.enemies,"defense")
	local targets = {}
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if #targets < self.player:getLostHp() + 1 then
			if self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, slash) and not self:slashProhibit(slash, enemy, self.player) then
				table.insert(targets, enemy:objectName())
			end
		else break end	
	end
	if #targets < self.player:getLostHp() + 1 then
		for _, enemy in ipairs(self.enemies) do
			if #targets < self.player:getLostHp() + 1 then
				if self:slashIsEffective(slash, enemy) and not self:slashProhibit(slash, enemy, self.player) and not table.contains(targets, enemy:objectName()) then
					table.insert(targets, enemy:objectName())
				end
			else break end	
		end
	end
	if #targets == 0 then return "." end
	return "#empaidui:.:->"..table.concat(targets, "+")
end

sgs.hit_skill = sgs.hit_skill .. "|empaidui"
sgs.ai_cardneed.empaidui = sgs.ai_cardneed.slash

--扬帆突击

sgs.ai_skill_invoke.yftuji = function(self, data)
	local damage = data:toDamage()
	if #self.enemies > 0 then
		if self:needToLoseHp(self.player, damage.to) then
			return true
		end
		if sgs.ai_can_damagehp.yiji(self,damage.to,nil, self.player) then
			return true
		end
	end
	return false
end

sgs.ai_can_damagehp.zhongerhx = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end
sgs.ai_skill_invoke.zhongerhx = function(self)
	return true
end

sgs.ai_skill_askforag.zhongerhx = function(self,card_ids)
	local cards = {}
	for d,id in ipairs(card_ids)do
		local card = sgs.Sanguosha:getEngineCard(id)
		if card:isKindOf("Analeptic") and self:getCardsNum("Slash")<1 then continue end  --这里应该判断会不会使用【杀】，偷懒一下
		if card:targetFixed() then table.insert(cards,card)
		else
			d = dummyCard(card:objectName())
			d:setSkillName("_zhongerhx")
			if self:aiUseCard(d).card then
				table.insert(cards,card)
			end
		end
	end
	if #cards>0 then
		self:sortByUseValue(cards,false)
		return cards[1]:getEffectiveId()
	end
	for _,id in ipairs(card_ids)do
		if sgs.Sanguosha:getEngineCard(id):isKindOf("Analeptic") then return id end
	end
	return -1
end
sgs.ai_skill_use["@@zhongerhx"] = function(self,prompt)
	local card = sgs.Sanguosha:getCard(self.player:getMark("zhongerhuan") - 1)
	card:setSkillName("zhongerhx")
	local dummy = self:aiUseCard(card)
	if dummy.card
	and dummy.to
	then
		local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return card:toString().."->"..table.concat(tos,"+")
	end
	return "."
end

--寒刃
sgs.ai_skill_invoke.hanrenzd = function(self, data)
	local damage = data:toDamage()
	if damage.to then
		if self:isEnemy(damage.to) and (not damage.to:getWeapon() or (damage.to:getWeapon() and self:doDisCard(damage.to, damage.to:getWeapon():getEffectiveId()) )) then
			return true
		end
	end
	return false
end
sgs.ai_cardneed.hanrenzd = sgs.ai_cardneed.slash

--冰封
sgs.ai_skill_invoke.bingfengzd = function(self, data)
	local damage = data:toDamage()
	if damage.from  then
		if self:isEnemy(damage.from)  then
			return true
		end
	end
	return false
end

sgs.ai_can_damagehp.bingfengzd = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and self:isWeak(from) and from:getCardCount()>0
	end
end

--赫子暴走
sgs.ai_skill_choice["hezibz"] = function(self, choices, data)
	local items = choices:split("+")
	local good, bad = 0, 0
	local lord = self.room:getLord()
	if lord and self.role ~= "rebel" and self:isWeak(lord) then return "hezibz:huif" end
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isWeak(player) and self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			if self:isFriend(player) then bad = bad + 1
			else good = good + 1
			end
		end
	end
	if good == 0 then return  "hezibz:huif" end

	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		local hp = math.max(player:getHp(), 1)
		if  self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			if getCardsNum("Analeptic", player) > 0 then
				if self:isFriend(player) then good = good + 1.0 / hp
				else bad = bad + 1.0 / hp
				end
			end


				local lost_value = 0
				if self:hasSkills(sgs.masochism_skill, player) then lost_value = player:getHp()/2 end
				local hp = math.max(player:getHp(), 1)
				if self:isFriend(player) then bad = bad + (lost_value + 1) / hp
				else good = good + (lost_value + 1) / hp
				end
		end
	end
	if good > bad then return "hezibz:shangh" end
	return "hezibz:huif"
end


--断裁
sgs.ai_skill_cardask["@duancai"] = function(self, data, pattern, target, target2)
	local use = data:toCardUse()	
	local target = use.from
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(usable_cards)
	local give_card = {}
	
	if target and self:isEnemy(target) then
		for _,c in ipairs(usable_cards) do
			if c:getNumber() < 8 and  self:getKeepValue(c)  < 6 and not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and self:canDamage(target,self.player,nil)  then
				table.insert(give_card, c)
			end
		end
		if #give_card > 0 then
			return give_card[1]:toString()
		end
	end
	return "."
end
sgs.ai_skill_cardask["@duancaiex"] = function(self, data, pattern, target, target2)
	local use = data:toCardUse()	
	local target = use.from
	local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(usable_cards)
	local give_card = {}
	
	if target and self:isEnemy(target) then
		for _,c in ipairs(usable_cards) do
			if c:getNumber() > 7 and  self:getKeepValue(c)  < 6 and not self:cantbeHurt(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and self:canDamage(target,self.player,nil)  then
				table.insert(give_card, c)
			end
		end
		if #give_card > 0 then
			return give_card[1]:toString()
		end
	end
	return "."
end
sgs.ai_cardneed.duancaiex = sgs.ai_cardneed.bignumber

--迷迭
sgs.ai_skill_invoke.midie = function(self, data)
	if self:getCardsNum("Peach") >= 1 - self.player:getHp() then
		return false
	end
	return true
end

--同舟
sgs.ai_skill_invoke.tongzhouqg = function(self, data)
	if #self.friends + 1 >= #self.enemies  then
		return true
	end
	return false
end

sgs.ai_skill_cardask["@tongzhouqg"] = function(self, data, pattern, target, target2)	
	local target = data:toPlayer()
	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
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


sgs.ai_skill_use["@@qgjiesi"] = function(self, prompt)
	self:updatePlayers()
	self:sort(self.enemies, "defense")
	local targets = {}
	local x = self.player:getMark("qgjiesi")
	for _, enemy in ipairs(self.enemies) do
		if  enemy:canDiscard(enemy, "he") and  self:doDisCard(enemy, "he") then
			if #targets >= x then
				break
			end
			table.insert(targets, enemy:objectName())
		end
	end
		if #targets > 0 then
			return ("#qgjiesi:.:->" .. table.concat(targets, "+"))
		end
	return "."
end


local zjyizhen_skill = {}
zjyizhen_skill.name = "zjyizhen"
table.insert(sgs.ai_skills, zjyizhen_skill)
zjyizhen_skill.getTurnUseCard = function(self)
	if self.player:isNude() then return nil end
	
	local card_str = "#zjyizhenCard:.:"
	return sgs.Card_Parse(card_str)
end

sgs.ai_skill_use_func["#zjyizhenCard"] = function(card, use, self)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = nil

	if #arr1 > 0 and (self:isWeak(arr1[1]) or self:getOverflow() >= 1) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		local to_use = {}
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards)
		for _,c in ipairs(cards) do
			if #to_use < target:getLostHp() then
				table.insert(to_use, c:getEffectiveId())
			end
		end
		if #to_use ==  target:getLostHp() then
			local card_str = string.format("#zjyizhenCard:" .. table.concat(to_use, "+")..":")
			local acard = sgs.Card_Parse(card_str)
			use.card = acard
			if use.to then use.to:append(target) end
			return
		end
	end
	if self:getOverflow() > 0 and #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				local to_use = {}
				local cards = self.player:getCards("he")
				cards = sgs.QList2Table(cards)
				self:sortByKeepValue(cards)
				for _,c in ipairs(cards) do
					if #to_use < target:getLostHp() then
						table.insert(to_use, c)
					end
				end
				if #to_use ==  target:getLostHp() then
					local card_str = string.format("#zjyizhenCard:" .. table.concat(to_use, "+")..":")
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					if use.to then use.to:append(target) end
					return
				end
			end
		end
	end
end

sgs.ai_use_priority["zjyizhenCard"] = 4.2
sgs.ai_card_intention["zjyizhenCard"] = -100

sgs.dynamic_value.benefit["zjyizhenCard"] = true
sgs.ai_use_revises.zjyizhen = function(self,card,use)
	if card:isKindOf("Slash") and self:isWeak()
	and self:getOverflow()<=0
	then return false end
end


sgs.recover_hp_skill = sgs.recover_hp_skill .. "|zjyizhen"
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|zjyizhen"
function sgs.ai_cardneed.zjyizhen(to,card)
	return not card:isKindOf("Jink")
end

--魔术戏法
sgs.ai_skill_invoke.zjmoshuxif = function(self, data)
		return true
end
sgs.ai_skill_cardask["@zjmoshuxif"] = function(self, data, pattern, target)
	if self:needToThrowArmor() then
		return "$" .. self.player:getArmor():getEffectiveId()
	end
	local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if not card:isKindOf("Peach") then
				return "$" .. card:getEffectiveId()
			end
		end
	return "$" .. cards[1]:getEffectiveId()
end
sgs.need_equip_skill = sgs.need_equip_skill .. "|zjmoshuxif"



--高岭之花
sgs.ai_skill_invoke.zjruoshi = function(self, data)
		return true
end

sgs.ai_skill_choice["zjruoshi"] = function(self, choices, data)
	local items = choices:split("+")
	return items[math.random(1,#items)]
end



--傲娇
sgs.ai_skill_choice["zjaojiaol"] = function(self, choices, data)
	if self:isWeak() and self.player:isWounded() then return "zjaojiaol:red" end
	return "zjaojiaol:black"
end
sgs.ai_skill_cardchosen["zjaojiaol"] = function(self, who, flags)
	local card
	local handcards = sgs.QList2Table(who:getHandcards())
	self:sortByKeepValue(handcards)
	
	if self:isFriend(who) then
		if who:getMark("zjaojiaolred") == 1 then
			for _, card in ipairs(handcards) do
				if card:isRed() then
					return card
				end
			end
		elseif who:getMark("zjaojiaolblack") == 1 then
			for _, card in ipairs(handcards) do
				if card:isBlack() then
					return card
				end
			end
		end
		if not who:isKongcheng() then return handcards[1] end
	else
		handcards = sgs.reverse(handcards)
		 return handcards[1]
	end
	return nil
end


zjaojiaol_skill = {}
zjaojiaol_skill.name = "zjaojiaol"
table.insert(sgs.ai_skills, zjaojiaol_skill)
zjaojiaol_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#zjaojiaol") then return nil end
	if #self.friends_noself == 0 then return nil end
	if self.player:isKongcheng() then return nil end
	return sgs.Card_Parse("#zjaojiaol:.:")
end

sgs.ai_skill_use_func["#zjaojiaol"] = function(card, use, self)

	for _, friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			local card_str = "#zjaojiaol:.:"
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				
				if use.to then use.to:append(friend) end
				return
		end
	end
	local AssistTarget = self:AssistTarget()
	local friend
	if AssistTarget and AssistTarget:isWounded() and not self:needToLoseHp(AssistTarget, nil, nil, nil, true) then
		friend = AssistTarget
	elseif AssistTarget and not hasManjuanEffect(AssistTarget) and not self:needKongcheng(AssistTarget, true) then
		friend = AssistTarget
	else
		friend = self.friends_noself[1]
	end
		if friend then
				local card_str = "#zjaojiaol:.:"
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				
				if use.to then use.to:append(friend) end
				return
	end
end

sgs.ai_use_priority["#zjaojiaol"] = 4.2
sgs.ai_card_intention["#zjaojiaol"] = -100

sgs.dynamic_value.benefit["#zjaojiaol"] = true

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|zjaojiaol"

--谱奏
sgs.ai_skill_choice["puzou"] = function(self, choices, data)
	self:sort(self.friends, "hp")
	self:sort(self.enemies, "hp")
	local up = 0
	local down = 0

	for _, friend in ipairs(self.friends) do
		down = down - 10
		up = up + (friend:isWounded() and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, friend) then
			down = down - 5
			if friend:isWounded() then up = up + 5 end
		end
		if self:needToLoseHp(friend, nil, nil, true) then down = down + 5 end
		if self:needToLoseHp(friend, nil, nil, true, true) and friend:isWounded() then up = up - 5 end

		if self:isWeak(friend) then
			if friend:isWounded() then up = up + 10 + (friend:isLord() and 20 or 0) end
			down = down - 10 - (friend:isLord() and 40 or 0)
			if friend:getHp() <= 1 and not friend:hasSkill("buqu") or friend:getPile("trauma"):length() > 4 then
				down = down - 20 - (friend:isLord() and 40 or 0)
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		down = down + 10
		up = up - (enemy:isWounded() and 10 or 0)
		if self:hasSkills(sgs.masochism_skill, enemy) then
			down = down + 10
			if enemy:isWounded() then up = up - 10 end
		end
		if self:needToLoseHp(enemy, nil, nil, true) then down = down - 5 end
		if self:needToLoseHp(enemy, nil, nil, true, true) and enemy:isWounded() then up = up - 5 end

		if self:isWeak(enemy) then
			if enemy:isWounded() then up = up - 10 end
			down = down + 10
			if enemy:getHp() <= 1 and not enemy:hasSkill("buqu") then
				down = down + 10 + ((enemy:isLord() and #self.enemies > 1) and 20 or 0)
			end
		end
	end

	if down > 0 then
		return "puzou_losehp"
	elseif up > 0 then
		return "puzou_heal"
	end
	return "cancel"
end

sgs.bad_skills = sgs.bad_skills .."|bieniu"

sgs.ai_skill_choice.htms_weiyi = function(self,choices,data)
	local target = data:toDamage().from
	if self:isEnemy(target) and self:doDisCard(target, "he") and self.player:getMark("@wysh") > 0 then
		return "htms_weiyi:qp"
	end
	if self:isEnemy(target) and self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) and not self:cantbeHurt(target) and self.player:getMark("@wyqp") > 0 and self:canDamage(target,self.player,nil) then
		return "htms_weiyi:sh"
	end
	if self:isEnemy(target) and self:doDisCard(target, "he") then
		return "htms_weiyi:qp"
	end
	if self:isFriend(target) and self:doDisCard(target, "he") and self.player:getMark("@wysh") == 0 then
		return "htms_weiyi:qp"
	end
	if self:isFriend(target) and ((self:needToLoseHp(target, self.player, nil) and self.player:getMark("@wyqp") > 0) or self.player:getMark("@wyqp")==0) then
		return "htms_weiyi:sh"
	end
	return "cancel"
end



--辘首
sgs.ai_skill_cardask["lualushouC"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if self:needToThrowArmor() then return "$" .. self.player:getArmor():getEffectiveId() end
	
	local effective = false
	local hit = false
	for _,p in sgs.qlist(use.to) do
		if  self:slashIsEffective(data:toCardUse().card, p)  then effective = true end
		if getCardsNum("Jink", p, self.player) > 0 then hit = true end
		if p:isKongcheng() or self:canLiegong(p, self.player) then hit = true  end
		
	end
	
	if  self.player:getHp() >= getBestHp(self.player) then return "." end
	if hit and effective then
		for _, c in ipairs(cards) do
			if c:isKindOf("EquipCard") then
				return "$" .. c:getEffectiveId()
			end
		end
	end
	return "."
end
sgs.ai_skill_cardask["lualushouB"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local should = false
	local available_targets = sgs.SPlayerList()
		for _, p in sgs.qlist(self.room:getAlivePlayers()) do
			if (use.to:contains(p) or self.room:isProhibited(self.player, p, use.card)) then continue end
			if (use.card:targetFilter(sgs.PlayerList(), p, self.player)) then
				available_targets:append(p)
			end
		end
	if sgs.ai_skill_playerchosen.zero_card_as_slash(self, available_targets) ~= nil then
		should = true
	end
	if  should then
		for _, c in ipairs(cards) do
			if c:isKindOf("TrickCard") then
				return "$" .. c:getEffectiveId()
			end
		end
	end
	return "."
end

sgs.ai_skill_playerchosen.lualushou = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end
sgs.ai_skill_cardask["lualushouA"] = function(self, data, pattern, target)
	local use = data:toCardUse()
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	
	local effective = false
	local should = false
	for _,p in sgs.qlist(use.to) do
		if  self:slashIsEffective(data:toCardUse().card, p)  then effective = true end
		if getCardsNum("Jink", p, self.player) > 0 and getCardsNum("Jink", p, self.player) < 2 then should = true end
	end
	
	if should and effective then
		for _, c in ipairs(cards) do
			if c:isKindOf("BasicCard") and not c:isKindOf("Peach") then
				return "$" .. c:getEffectiveId()
			end
		end
	end
	return "."
end
sgs.hit_skill = sgs.hit_skill .. "|lualushou"
sgs.ai_cardneed.lualushou = sgs.ai_cardneed.slash


--花葬

sgs.ai_skill_invoke.huazang = function(self, data)
	local use = data:toCardUse()
	for _,p in sgs.qlist(use.to) do
		if self:isFriend(p) and not p:faceUp() then
			return true
		end
		if not self:toTurnOver(p, p:getLostHp(), "huazang") then
			return true
		end
		if self:isEnemy(p) and self:toTurnOver(p, p:getLostHp(), "huazang") then
			return true
		end
	end
	return false
end

sgs.ai_cardneed.huazang = sgs.ai_cardneed.slash





--直斥
local zchize_skill={}
zchize_skill.name="zchize"
table.insert(sgs.ai_skills,zchize_skill)
zchize_skill.getTurnUseCard=function(self,inclusive)
	self:sort(self.enemies, "handcard")
	if self.player:getHandcardNum() < 2  then return false end
	for _, enemy in ipairs(self.enemies) do
	    if not enemy:isKongcheng() then
			return sgs.Card_Parse("#zchizeCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#zchizeCard"]=function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards,true)
	self:sort(self.enemies, "handcard")
	local target
	for _, enemy in ipairs(self.enemies) do
		if self.player:canPindian(enemy) and not (enemy:getEquips():length() > 0 and enemy:hasSkills(sgs.lose_equip_skill)) 
		and not (enemy:getJudgingArea():length() > 0 and enemy:getEquips():length() == 0) then
			target = enemy 
			break
		end
	end
	if not target then
		for _, enemy in ipairs(self.enemies) do
			if self.player:canPindian(enemy) then
				target = enemy 
				break
			end
		end
	end
	self:sortByKeepValue(cards)
	if not target then return end
	for _, card in ipairs(cards) do
		if not card:isKindOf("Peach") and not card:isKindOf("ExNihilo") and not card:isKindOf("Jink") and self:getKeepValue(card) < 6 then
			use.card = sgs.Card_Parse("#zchizeCard:"..card:getId()..":")
			if use.to and target then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_card_intention["zchizeCard"] = 80




--高岭
sgs.ai_skill_invoke.gaoling = function(self, data)
	local effect = data:toCardEffect()
	
		if self:isEnemy(effect.from) or (self:isFriend(effect.from) and self.role == "loyalist" and not effect.from:hasSkill("jueqing") and effect.from:isLord() and self.player:getHp() == 1) then
			if effect.card:isKindOf("AOE") then
				local from = effect.from
				if effect.card:isKindOf("SavageAssault") then
					local menghuo = self.room:findPlayerBySkillName("huoshou")
					if menghuo then from = menghuo end
				end

				if self:hasTrickEffective(effect.card, self.player, from) then 
				if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then 
				if effect.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then return true end
				
					if self:isEnemy(from) and from:hasSkill("jueqing") then return true end
					if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not from:hasSkill("jueqing") then return true end
					if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or effect.from:hasSkill("jueqing"))  then
						return true
					end
					end
				end	
			elseif self:isEnemy(effect.from) then
				if effect.card:isKindOf("FireAttack")  then
						if  self:hasTrickEffective(effect.card, self.player) then 
					if  self:damageIsEffective(self.player, sgs.DamageStruct_Fire, effect.from) then 
					if (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0) and effect.from:getHandcardNum() > 3
						and not (effect.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
						return true
					elseif self.player:isChained() and not self:isGoodChainTarget(self.player, effect.from) then
						return true
					end
					end
					end
				elseif (effect.card:isKindOf("Snatch") or effect.card:isKindOf("Dismantlement"))
						 and not self.player:isKongcheng() then
					if  self:hasTrickEffective(effect.card, self.player) then
					return true
					end
				elseif effect.card:isKindOf("Duel") then
					if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", effect.from, self.player) then
						if self:hasTrickEffective(effect.card, self.player) then
						if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, effect.from) then
						return true
						end
						end
					end
				end
			end
	end
	return false
end
sgs.ai_target_revises.gaoling = function(to,card,self)
	return card:isNDTrick() and self.player:getHandcardNum() <= to:getHandcardNum() and not beFriend(to, self.player)
end

--拯救
sgs.ai_skill_invoke.zhengjiu = function(self, data)
	local use = data:toCardUse()
	if use and use.card then
		return true
	end
	return sgs.ai_skill_playerchosen.zhengjiu(self, self.room:getOtherPlayers(self.player)) ~= nil
end
sgs.ai_skill_playerchosen.zhengjiu = function(self, targets)
	self:sort(self.friends_noself, "defense")
	for _,friend in ipairs(self.friends_noself) do
		if self:isWeak(friend) then
			return friend
		end
	end
	for _,friend in ipairs(self.friends_noself) do
		return friend
	end
	return nil
end




--魔力外放
local molwf_skill = {}
molwf_skill.name= "molwf"
table.insert(sgs.ai_skills,molwf_skill)
molwf_skill.getTurnUseCard=function(self)
	if self:needBear() then return end
	if not self.player:hasUsed("#molwf")  then
		return sgs.Card_Parse("#molwf:.:")
	end
end

sgs.ai_skill_use_func["#molwf"] = function(card, use, self)
	self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	local use_cards
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if  card:isRed() and  not card:isKindOf("Slash") 	and not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) 
			and (self:getUseValue(card) < sgs.ai_use_value.Slash  or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0)
			and not (card:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0) then
			use_cards = card
			break
		end
	end
	if slashcount > 0 and use_cards  then
		local slash = self:getCard("Slash")
		assert(slash)
		local dummy_use = self:aiUseCard(slash, dummy())
		if not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				if not (p:hasSkill("kongcheng") and p:getHandcardNum() == 0) and  (getCardsNum("Peach", p, self.player) == 0  or self:canLiegong(p, self.player)) 
				and self:canAttack(p, self.player) 
				and not self:canLiuli(p, self.friends_noself) and not self:findLeijiTarget(p, 50, self.player) then
					use.card = sgs.Card_Parse("#molwf:"..use_cards:getEffectiveId()..":")
					return
					
				end
			end
		end
	end

end

sgs.ai_use_priority["molwf"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_ajustdamage_from.molwf = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and from:hasFlag("moli")
	then
		return 1
	end
end
sgs.ai_cardneed.molwf = sgs.ai_cardneed.slash

--誓胜

local html_shisheng_skill = {}
html_shisheng_skill.name= "html_shisheng"
table.insert(sgs.ai_skills,html_shisheng_skill)
html_shisheng_skill.getTurnUseCard=function(self)
	if self.player:getMark("@shisheng") > 0 then
		return sgs.Card_Parse("#html_shishengCard:.:")
	end
end

sgs.ai_skill_use_func["#html_shishengCard"] = function(card, use, self)
		self:sort(self.enemies, "hp")
		for _, enemy in ipairs(self.enemies) do
			if self:objectiveLevel(enemy) > 3 and not self:cantbeHurt(enemy) and self:damageIsEffective(enemy) and self:canDamage(enemy,self.player,nil) then
				if enemy:getHp() == 1 and getCardsNum("Peach", enemy, self.player) == 0 then
					use.card = sgs.Card_Parse("#html_shishengCard:.:")
					if use.to then
						use.to:append(enemy)
					end
					return
				end
			end
		end
end

sgs.ai_use_value["#html_shishengCard"] = 2.5
sgs.ai_card_intention["#html_shishengCard"] = 80
sgs.dynamic_value.damage_card["#html_shishengCard"] = true

sgs.straight_damage_skill = sgs.straight_damage_skill .. "|html_shisheng"



--邀战
local ujyaozhan_skill = {}
ujyaozhan_skill.name = "ujyaozhan"
table.insert(sgs.ai_skills, ujyaozhan_skill)
ujyaozhan_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#ujyaozhanCard") then return end
	return sgs.Card_Parse("#ujyaozhanCard:.:")
end

sgs.ai_skill_use_func["#ujyaozhanCard"] = function(card, use, self)

	local canleiji
	if self:findLeijiTarget(self.player, 50)
		and ((self.player:hasSkill("leiji") and self:hasSuit("spade", true))
			or (self.player:hasSkill("nosleiji") and self:hasSuit("black", true))) then
		canleiji = true
		self:sort(self.friends_noself, "handcard")
		self.friends_noself = sgs.reverse(self.friends_noself)
		for _, friend in ipairs(self.friends_noself) do
			if not friend:isKongcheng() and (self:getCardsNum("Jink") > 0 or (not friend:hasWeapon("qinggang_sword") and not self:isWeak() and self:hasEightDiagramEffect())) then
				use.card = card
				if use.to then use.to:append(friend) end
				return
			end
		end
	end

	for _, enemy in ipairs(self.enemies) do
		if  (self:needToLoseHp(self.player, enemy)) then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end

	local second, third, fourth
	local slash = self:getCard("Slash")
	local slash_nosuit = sgs.Sanguosha:cloneCard("slash")
	slash_nosuit:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if enemy:getHandcardNum() > 0 then
			if not self:slashIsEffective(slash_nosuit, self.player, enemy) and self:getCardsNum("Slash") > getCardsNum("Slash", enemy) and not second then
				second = enemy
			elseif not enemy:hasSkills("wushuang|mengjin|tieji|nostieji")
				and not ((enemy:hasSkill("roulin") or enemy:hasWeapon("double_sword")) and enemy:getGender() ~= self.player:getGender()) then

				if slash and not third and self.player:inMyAttackRange(enemy)
					and (self:hasHeavyDamage(self.player, slash, enemy) or self.player:hasWeapon("guding_blade") and not self:needKongcheng(enemy))
					and (not self:isWeak() or self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0) then
					third = enemy
				elseif self:getCardsNum("Jink") > 0 and self:getCardsNum("Slash") > getCardsNum("Slash", enemy) and not fourth then
					fourth = enemy
				end
			end
		end
	end

	local target
	if canleiji then
		target = fourth and third or second
	else
		target = second or third or fourth
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end

end

sgs.ai_use_priority["ujyaozhanCard"] = sgs.ai_use_priority.Slash + 0.1
sgs.ai_cardneed.ujyaozhan = sgs.ai_cardneed.slash
sgs.ai_cardneed.ujzhongshi = sgs.ai_cardneed.slash
sgs.ai_cardneed.ujlianji = sgs.ai_cardneed.slash
sgs.ai_cardneed.ujlianjig = sgs.ai_cardneed.slash



--扶危

sgs.ai_skill_choice.Sdorica_FuWei = function(self, choices)
local items = choices:split("+")
	if self.room:getCurrent() and self:isFriend(self.room:getCurrent()) and  self.room:getCurrent():getJudgingArea():length() > 0 and not self.room:getCurrent():containsTrick("YanxiaoCard")
	and table.contains(items, "fwdiscard&put") then
		return "fwdiscard&put"
	end
	return "cancel"
end

sgs.ai_skill_discard.Sdorica_FuWei = function(self, discard_num, min_num, optional, include_equip)
	local to_discard = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local stealer
	for _, ap in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if ap:hasSkills("tuxi|nostuxi") and self:isEnemy(ap) then stealer = ap end
	end
	local card
	for i=1, #cards, 1 do
		local isPeach = cards[i]:isKindOf("Peach")
		if isPeach then
			if stealer and self:isEnemy(stealer) and self.player:getHandcardNum()<=2 and self.player:getHp() > 2
			and (not stealer:containsTrick("supply_shortage") or stealer:containsTrick("YanxiaoCard")) then
				card = cards[i]
				break
			end
			local to_discard_peach = true
			for _,fd in ipairs(self.friends) do
				if fd:getHp()<=2 and not fd:hasSkill("niepan") then
					to_discard_peach = false
				end
			end
			if to_discard_peach then
				card = cards[i]
				break
			end
		else
			card = cards[i]
			break
		end
	end
	if card == nil then return {} end
	table.insert(to_discard, card:getEffectiveId())
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		if not current:containsTrick("YanxiaoCard") then
			if (current:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
				or (current:containsTrick("lightning") and #self.friends > #self.enemies) then
				return to_discard
			elseif current:containsTrick("supply_shortage") then
				if self.player:getHp() > self.player:getHandcardNum() then return to_discard end
			elseif current:containsTrick("indulgence") then
				if self.player:getHandcardNum() > 3 or self.player:getHandcardNum() > self.player:getHp() - 1 then return to_discard end
				for _, friend in ipairs(self.friends_noself) do
					if not friend:containsTrick("YanxiaoCard") and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
						return to_discard
					end
				end
			end
		end
	end
	return {}
end


--辉煌
Sdorica_MiLing_skill = {}
Sdorica_MiLing_skill.name = "Sdorica_MiLing"
table.insert(sgs.ai_skills, Sdorica_MiLing_skill)
Sdorica_MiLing_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#Sdorica_MiLingCard") then return nil end
	if self.player:isKongcheng() then return nil end
	return sgs.Card_Parse("#Sdorica_MiLingCard:.:")
end

sgs.ai_skill_use_func["#Sdorica_MiLingCard"] = function(card, use, self)

	for _, friend in ipairs(self.friends) do
		if self:isWeak(friend) and friend:getMark("@Immunity") == 0 then
			local card_str = "#Sdorica_MiLingCard:.:"
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				
				if use.to then use.to:append(friend) end
				return
		end
	end
	local AssistTarget = self:AssistTarget()
	local friend
	if AssistTarget and AssistTarget:getMark("@Immunity") == 0  then
		friend = AssistTarget
	else
		friend = self.friends_noself[1]
	end
		if friend then
				local card_str = "#Sdorica_MiLingCard:.:"
				local acard = sgs.Card_Parse(card_str)
				use.card = acard
				
				if use.to then use.to:append(friend) end
				return
	end
end

sgs.ai_use_priority["#Sdorica_MiLingCard"] = 4.2
sgs.ai_card_intention["#Sdorica_MiLingCard"] = -100

sgs.dynamic_value.benefit["#Sdorica_MiLingCard"] = true

--虚空
void_skill = {}
void_skill.name = "void"
table.insert(sgs.ai_skills, void_skill)
void_skill.getTurnUseCard = function(self)
	if self.player:getMark("voidcanuse")- self.player:getMark("voidused") >= 0 then
		return sgs.Card_Parse("#void:.:")
	end
end

sgs.ai_skill_use_func["#void"] = function(card, use, self)
	local names = self.room:getTag(self.player:objectName().."voidtarget"):toString():split("+")
	self:sort(self.friends_noself, "handcard")
	self:sort(self.enemies, "handcard")
	local targets = {}
	local voidfriend, voidenemey = 0,0
		for i=1, #names, 1 do
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:objectName()==names[i] then 
					table.insert(targets, p)
					if self:isFriend(p) then
						voidfriend = voidfriend + 1
					end
					if self:isEnemy(p) then
						voidenemey = voidenemey + 1
					end
				end
			end
		end
	if (voidenemey >= voidfriend) then
		for _, friend in ipairs(self.friends_noself) do
			if not friend:isKongcheng() and not table.contains(targets, friend) then
				local card_str = "#void:.:"
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					
					if use.to then use.to:append(friend) end
					return
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and not table.contains(targets, enemy) then
				local card_str = "#void:.:"
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					
					if use.to then use.to:append(enemy) end
					return
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and not table.contains(targets, enemy) then
				local card_str = "#void:.:"
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					
					if use.to then use.to:append(enemy) end
					return
			end
		end
	end
end

sgs.ai_use_priority["void"] = 7

sgs.ai_card_priority.void = function(self,card)
	if card and card:hasFlag("void-Clear") then 
		local idlist = self.room:getTag(self.player:objectName().."voidid"):toString():split("+")
		local names = self.room:getTag(self.player:objectName().."voidtarget"):toString():split("+")
		for i=1, #idlist, 1 do
			local target
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:objectName()==names[i] then target = p end
			end
			if target and sgs.Sanguosha:getCard(tonumber(idlist[i])) == card then
				if self:isFriend(target) then
                    return -5
                else
                    return 10
                end
			end
		end
		return 0 
	end
end

--王国
sgs.ai_skill_choice.wangguo = function(self, choices)
local items = choices:split("+")
local current = self.room:getCurrent()
	if current then
		if self:isFriend(current) and table.contains(items, "oumashu_recover") then
			return "oumashu_recover"
		elseif  table.contains(items, "oumashu_lose") then
			return "oumashu_lose"
		end
	end
	return items[math.random(1,#items)]
end

--零式驱动
sgs.ai_skill_invoke.lsqd = function(self, data)
	return true
end

sgs.ai_skill_choice.lsqd = function(self, choices)
local items = choices:split("+")
		if not self.player:getWeapon() and table.contains(items, "lsqd:qp") then
			local list=sgs.IntList()
			for _,id in sgs.qlist(self.room:getDiscardPile()) do
				if  sgs.Sanguosha:getCard(id):isKindOf("Weapon") then
					list:append(id)		   
				end
			end
		   if list:length()>0 then 
			return "lsqd:qp"
			end
		end
		if  self.player:getWeapon() and table.contains(items, "lsqd:kd") then
			return "lsqd:kd"
		end
	return "lsqd:kd"
end
sgs.ai_skill_cardask["@lsqd"] = function(self,data)
	local id,cards = nil,{}
	if self:needToThrowArmor() and self.player:canDiscard(self.player,self.player:getArmor():getEffectiveId()) then
		id = self.player:getArmor():getEffectiveId()
	else
		for _,c in sgs.qlist(self.player:getCards("he"))do
			if self.player:canDiscard(self.player,c:getEffectiveId()) then
				table.insert(cards,c)
			end
		end
		if #cards<=0 then return "." end
		self:sortByKeepValue(cards)
		id = cards[1]:getEffectiveId()
	end
	
	if not id then return "." end
end


--天使重构
sgs.ai_skill_playerchosen.tscg = function(self, targets)
	return sgs.ai_skill_playerchosen.damage(self, targets)
end

--武装构造
local wzgz_skill = {}
wzgz_skill.name= "wzgz"
table.insert(sgs.ai_skills,wzgz_skill)
wzgz_skill.getTurnUseCard=function(self)
	if not self.player:hasUsed("#wzgzcard") then
		return sgs.Card_Parse("#wzgzcard:.:")
	end
end

sgs.ai_skill_use_func["#wzgzcard"] = function(card, use, self)

		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if  self:doDisCard(enemy, "e") and enemy:getWeapon() then
				
					use.card = sgs.Card_Parse("#wzgzcard:.:")
					if use.to then
						use.to:append(enemy)
					end
					return
				
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if   self:doDisCard(enemy, "e") and enemy:getEquips():length() > 0 then
				
					use.card = sgs.Card_Parse("#wzgzcard:.:")
					if use.to then
						use.to:append(enemy)
					end
					return
				
			end
		end
		for _, friend in ipairs(self.friends) do
			if self:isFriend(friend) and ((friend:hasSkills(sgs.lose_equip_skill) and friend:getEquips():length() > 0) or self:needToThrowArmor(friend)) then
					use.card = sgs.Card_Parse("#wzgzcard:.:")
					if use.to then
						use.to:append(friend)
					end
					return end
		end
end

sgs.ai_use_value["#wzgzcard"] = 2.5
sgs.ai_card_intention["#wzgzcard"] = 80




sgs.ai_ajustdamage_from.tcmfs = function(self, from, to, card, nature)
	if card and card:isKindOf("TrickCard") and card:isRed() and from:getMark("@tcmfs") == 1 and not beFriend(to, from)
	then
		return 1
	end
end

sgs.ai_skill_discard.tcmfs = function(self,max, min,optional,include_equip)
	local damage = self.room:getTag("tcmfs"):toDamage()
	if not damage.to or damage.to:isDead() or not self:isEnemy(damage.to) or self:cantDamageMore(self.player,damage.to) then return {} end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local to_discard = {}
	local compare_func = function(a,b)
		return self:getKeepValue(a)<self:getKeepValue(b)
	end
	table.sort(cards,compare_func)
	for _,card in sgs.list(cards)do
		if #to_discard>=min then break end
		table.insert(to_discard,card:getId())
	end
	return to_discard
end

sgs.ai_cardneed.blmf = function(to,card,self)
	return card:isKindOf("BasicCard") and card:isRed()
end
sgs.ai_cardneed.tcmfs = function(to,card,self)
	return card:isKindOf("TrickCard") and card:isRed() and card:isDamageCard()
end

--爆裂魔法

local blmf_skill={}
blmf_skill.name="blmf"
table.insert(sgs.ai_skills,blmf_skill)
blmf_skill.getTurnUseCard=function(self)
   if #self.enemies < 1 then return end
	self:sort(self.enemies, "hp")
	
	local card

	local cards = self.player:getHandcards()
    cards=sgs.QList2Table(cards)
    self:sortByKeepValue(cards)

	for _,acard in ipairs(cards)  do
		if (acard:isKindOf("BasicCard") and not acard:isKindOf("Peach")	 )  then
			card = acard
			break
		end
	end
	
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			if sgs.Sanguosha:getCard(id):isKindOf("BasicCard")  and not sgs.Sanguosha:getCard(id):isKindOf("Peach")	then
				card = sgs.Sanguosha:getCard(id)
			end
		end
	end

	if not card then return nil end
	
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("fire_attack:blmf[%s:%s]=%d"):format(suit, number, card_id)
	return sgs.Card_Parse(card_str)
end

sgs.ai_ajustdamage_from.blmf = function(self, from, to, card, nature)
	if card and card:getSkillName() == "blmf"
	then
		return 1
	end
end


--莫止
--貌似有BUG
-- local htms_mozhi_skill = {}
-- htms_mozhi_skill.name = "htms_mozhi"
-- table.insert(sgs.ai_skills, htms_mozhi_skill)
-- htms_mozhi_skill.getTurnUseCard = function(self)
-- 	local has_Crossbow = false
-- 	for _,c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
-- 		if c:isKindOf("Crossbow") then
-- 			has_Crossbow = true
-- 		end
-- 	end
-- 	if has_Crossbow or self:hasCrossbowEffect() then
-- 		for _, slash in ipairs(self:getCards("Slash")) do
-- 			local dummy_use = self:aiUseCard(slash, dummy())
-- 			if not dummy_use.to:isEmpty() then return end
-- 		end
-- 	end
-- 		return sgs.Card_Parse("#htms_mozhi:.:")
-- end

-- sgs.ai_skill_use_func["#htms_mozhi"] = function(card, use, self)
-- 	local unpreferedCards = {}
-- 	local cards = sgs.QList2Table(self.player:getHandcards())

-- 	if self.player:getHp() < 3 then
-- 		local zcards = self.player:getCards("he")
-- 		local use_slash, keep_jink, keep_analeptic = false, false, false
-- 		local keep_slash = self.player:getTag("JilveWansha"):toBool()
-- 		for _, zcard in sgs.qlist(zcards) do
-- 			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) and not zcard:isAvailable(self.player) then
-- 				local shouldUse = true
-- 				if isCard("Slash", zcard, self.player) and not use_slash then
-- 					local dummy_use = self:aiUseCard(zcard, dummy())
-- 					if dummy_use.card then
-- 						if keep_slash then shouldUse = false end
-- 						if dummy_use.to then
-- 							for _, p in sgs.qlist(dummy_use.to) do
-- 								if p:getHp() <= 1 then
-- 									shouldUse = false
-- 									break
-- 								end
-- 							end
-- 							if dummy_use.to:length() > 1 then shouldUse = false end
-- 						end
-- 						if not self:isWeak() then shouldUse = false end
-- 						if not shouldUse then use_slash = true end
-- 					end
-- 				end
-- 				if zcard:getTypeId() == sgs.Card_TypeTrick then
-- 					local dummy_use = self:aiUseCard(zcard, dummy())
-- 					if dummy_use.card then shouldUse = false end
-- 				end
				
				
-- 				if isCard("Jink", zcard, self.player) and not keep_jink then
-- 					keep_jink = true
-- 					shouldUse = false
-- 				end
-- 				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
-- 					keep_analeptic = true
-- 					shouldUse = false
-- 				end
-- 				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
-- 			end
-- 		end
-- 	end

-- 	if #unpreferedCards == 0 then
-- 		local use_slash_num = 0
-- 		self:sortByKeepValue(cards)
		
-- 		local num = self:getCardsNum("Jink") - 1
-- 		if self.player:getArmor() then num = num + 1 end
-- 		if num > 0 then
-- 			for _, card in ipairs(cards) do
-- 				if card:isKindOf("Jink") and num > 0 then
-- 					table.insert(unpreferedCards, card:getId())
-- 					num = num - 1
-- 				end
-- 			end
-- 		end
-- 		for _, card in ipairs(cards) do
-- 			if not card:isAvailable(self.player) then
-- 				if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
-- 					or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
-- 					table.insert(unpreferedCards, card:getId())
-- 				elseif card:getTypeId() == sgs.Card_TypeTrick then
-- 					local dummy_use = self:aiUseCard(card, dummy())
-- 					if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
-- 				end
-- 			end
-- 		end

-- 		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
-- 			table.insert(unpreferedCards, self.player:getWeapon():getId())
-- 		end

-- 		if self:needToThrowArmor() then
-- 			table.insert(unpreferedCards, self.player:getArmor():getId())
-- 		end

-- 		if self.player:getOffensiveHorse() and self.player:getWeapon() then
-- 			table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
-- 		end
-- 	end

-- 	for index = #unpreferedCards, 1, -1 do
-- 		if sgs.Sanguosha:getCard(unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 0 then
-- 			table.removeOne(unpreferedCards, unpreferedCards[index])
-- 		end
-- 	end

-- 	local use_cards = {}
-- 	for index = #unpreferedCards, 1, -1 do
-- 		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) and not sgs.Sanguosha:getCard(unpreferedCards[index]):isAvailable(self.player) then 
-- 			table.insert(use_cards, unpreferedCards[index])
-- 			if #use_cards > self.player:getMark("&htms_mozhi")  then
-- 				break
-- 			end
-- 		end
-- 	end

-- 	if #use_cards == self.player:getMark("&htms_mozhi") + 1 then
-- 		use.card = sgs.Card_Parse("#htms_mozhi:" .. table.concat(use_cards, "+")..":")
-- 		return
-- 	end
-- 	use.card = nil
-- 	return
-- end

-- sgs.ai_use_value["#htms_mozhi"] = 9
-- sgs.ai_use_priority["#htms_mozhi"] = 2.61
-- sgs.dynamic_value.benefit["#htms_mozhi"] = true



--破灭回避
sgs.ai_skill_playerchosen.pomiehb = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, target in ipairs(targets) do
		if self:isFriend(target) and not  hasManjuanEffect(target) and self:canDraw(target, self.player) then
			return target
		end
	end
	for _, target in ipairs(targets) do
		if self:isFriend(target)  and self:canDraw(target, self.player) then return target end
	end
	return nil
end
sgs.ai_playerchosen_intention.pomiehb = function(self, from, to)
		sgs.updateIntention(from, to, -50)
end

--依伴
sgs.ai_skill_invoke.yiban = function(self, data)
	local yiban_string = sgs.ai_skill_use["@@yiban"](self, prompt, method)
	if yiban_string == "." then
		return false
	end
	return true
end

function SmartAI:shouldUseYiban()
	if (self:hasCrossbowEffect() or self:getCardsNum("Crossbow") > 0) and self:getCardsNum("Slash") > 0 then
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			local inAttackRange = self.player:distanceTo(enemy) == 1 or self.player:distanceTo(enemy) == 2
									and self:getCardsNum("OffensiveHorse") > 0 and not self.player:getOffensiveHorse()
			if inAttackRange and self:isGoodTarget(enemy, self.enemies, nil) then
				local slashs = self:getCards("Slash")
				local slash_count = 0
				for _, slash in ipairs(slashs) do
					if not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) then
						slash_count = slash_count + 1
					end
				end
				if slash_count >= enemy:getHp() then return false end
			end
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if enemy:canSlash(self.player) and not self:slashProhibit(nil, self.player, enemy) then
			if enemy:hasWeapon("guding_blade") and self.player:getHandcardNum() == 1 and getCardsNum("Slash", enemy) >= 1 then
				return false
			elseif self:hasCrossbowEffect(enemy) and getCardsNum("Slash", enemy) > 1 and self:getOverflow() <= 0 then
				return false
			end
		end
	end
	for _, player in ipairs(self.friends_noself) do
		if (player:hasSkill("haoshi") and not player:containsTrick("supply_shortage")) or player:hasSkill("jijiu") then
			return true
		end
	end
	local keepNum = 1
	
	if self.player:hasSkill("kongcheng") then
		keepNum = 0
	end
	if self:getOverflow() > 0 then
		return true
	end
	if self.player:getHandcardNum() > keepNum  then
		return true
	end
end

sgs.ai_skill_use["@@yiban"]=function(self,prompt)
	
	if self:getOverflow() <= 0 then return "." end

	if self:shouldUseYiban() then
		local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByUseValue(cards, true)

		local notFound
		for i = 1, #cards do
			local card, friend = self:getCardNeedPlayer(cards)
			if card and friend then
				cards = self:resetCards(cards, card)
			else
				notFound = true
				break
			end

			if friend:objectName() == self.player:objectName() or not self.player:getHandcards():contains(card) then continue end
			if card:isAvailable(self.player) and ((card:isKindOf("Slash")) or card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card and dummy_use.to:length() > 0 then
					if card:isKindOf("Slash") or card:isKindOf("Duel") then
						local t1 = dummy_use.to:first()
						if dummy_use.to:length() > 1 then continue
						elseif t1:getHp() == 1 or getCardsNum("Jink", t1, self.player) < 1
								or t1:isCardLimited(sgs.Sanguosha:cloneCard("jink"), sgs.Card_MethodResponse) then continue
						end
					elseif (card:isKindOf("Snatch") or card:isKindOf("Dismantlement")) and self:getEnemyNumBySeat(self.player, friend) > 0 then
						local hasDelayedTrick
						for _, p in sgs.qlist(dummy_use.to) do
							if self:isFriend(p) and (self:willSkipDrawPhase(p) or self:willSkipPlayPhase(p)) then hasDelayedTrick = true break end
						end
						if hasDelayedTrick then continue end
					end
				end
			elseif card:isAvailable(self.player) and self:getEnemyNumBySeat(self.player, friend) > 0 and (card:isKindOf("Indulgence") or card:isKindOf("SupplyShortage")) then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then continue end
			end

			if  #cards >= 1  then
				return  "#yiban:" .. card:getId() .. "+" .. cards[1]:getId()..":->".. friend:objectName()
			else
				return "#yiban:" .. card:getId()..":->".. friend:objectName() 
			end
		end

	end
	return "."
end
sgs.ai_card_intention["#yiban"] = function(self,card, from, tos)
	local to = tos[1]
	local intention = -70
	if hasManjuanEffect(to) then
		intention = 0
	elseif to:hasSkill("kongcheng") and to:isKongcheng() then
		intention = 30
	end
	sgs.updateIntention(from, to, intention)
end





--同好
sgs.ai_skill_playerchosen.tonghh = function(self, targets)
	if self.player:getRole() == "loyalist" then
		return self.room:getLord()
	end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:getRole() == "lord" and p:getRole() == "loyalist" then
			return p
		end
	end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:getRole() == p:getRole() then
			return p
		end
	end
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		return p
	end
	targets = sgs.QList2Table(targets)
	return targets[1]
end
sgs.ai_card_priority.zhumyb = function(self,card,v)
	if card:getNumber() > self.player:getMark("mengyb") and not self.player:hasFlag("zhumyb1")
	then return 10 end
end


--收获
sgs.ai_skill_playerchosen.luashouhuo = function(self, targets)
	local friends = {}
	for _, player in ipairs(self.friends) do
		if player:isAlive() and not hasManjuanEffect(player) then
			table.insert(friends, player)
		end
	end
	self:sort(friends)

	local max_x = 0
	local target
	local Shenfen_user
	for _, player in sgs.qlist(self.room:getAlivePlayers()) do
		if player:hasFlag("ShenfenUsing") then
			Shenfen_user = player
			break
		end
	end
	if Shenfen_user then
		local y, weak_friend = 3
		for _, friend in ipairs(friends) do
			local x = friend:getMaxCards() - friend:getHandcardNum()
			if hasManjuanEffect(friend) and x > 0 then x = x + 1 end
			if x > max_x and friend:isAlive() then
				max_x = x
				target = friend
			end

			if self:playerGetRound(friend, Shenfen_user) > self:playerGetRound(self.player, Shenfen_user) and x >= y
				and friend:getHp() == 1 and getCardsNum("Peach", friend, self.player) < 1 then
				y = x
				weak_friend = friend
			end
		end

		if weak_friend and ((getCardsNum("Peach", Shenfen_user, self.player) < 1) or (math.min(Shenfen_user:getMaxHp(), 5) - Shenfen_user:getHandcardNum() <= 1)) then
			return weak_friend
		end
		if self:isFriend(Shenfen_user) and math.min(Shenfen_user:getMaxHp(), 5) > Shenfen_user:getHandcardNum() then
			return Shenfen_user
		end
		if target then return target end
	end

	local CP = self.room:getCurrent()
	local max_x = 0
	local AssistTarget = self:AssistTarget()
	for _, friend in ipairs(friends) do
		local x = friend:getMaxCards() - friend:getHandcardNum()
		if hasManjuanEffect(friend) then x = x + 1 end
		if self:hasCrossbowEffect(CP) then x = x + 1 end
		if AssistTarget and friend:objectName() == AssistTarget:objectName() then x = x + 0.5 end

		if x > max_x and friend:isAlive() then
			max_x = x
			target = friend
		end
	end
	if max_x > 1 then
	return target
	end
	return nil
end

sgs.ai_playerchosen_intention.luashouhuo = function(self, from, to)
	if to:getHandcardNum() < to:getMaxCards() then
		sgs.updateIntention(from, to, -80)
	end
end





--红芋
sgs.ai_skill_playerchosen.luahongyu = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _,target in sgs.list(targets)do
		if target:isAlive() and not self:isFriend(target) and self:canDraw(target, self.player) then
			return target
		end
	end
	return targets[1]
end 

sgs.ai_playerchosen_intention.luahongyu = function(self, from, to)
	if not hasManjuanEffect(to) then
		sgs.updateIntention(from, to, -80)
	end
end

--粉红恶魔
sgs.ai_skill_invoke.pinkdevil = function(self, data)
	local targets=sgs.SPlayerList()
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
    for _,p in sgs.qlist(self.room:getAlivePlayers()) do
		if not self.player:isProhibited(p,slash) and self.player:canSlash(p,slash, false)  then
			targets:append(p)
        end
    end
	if targets:length()==0 then return false end	   
	
	local pinkdevil = sgs.ai_skill_playerchosen.pinkdevil(self, targets)
	if pinkdevil == nil then
		return false
	end
	return true
end
sgs.ai_skill_playerchosen.pinkdevil = function(self, targets)
	return sgs.ai_skill_playerchosen.zero_card_as_slash(self, targets)
end 
sgs.ai_ajustdamage_from.khztbuff = function(self, from, to, card, nature)
	if card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and (from:getLostHp() >  0) and  (from:getEquips():length() > 0) 
	then
		return 1
	end
end

sgs.ai_cardneed.khztbuff = sgs.ai_cardneed.slash


--高效治疗

sgs.ai_skill_playerchosen.gxzhiliao = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return	target
	end
	if  #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				return friend
			end
		end
	end
	for _, friend in ipairs(self.friends) do
		if friend:getMark("@hurt") > 0  then
			return friend
		end
	end
	
	return nil 
end 

sgs.ai_playerchosen_intention.gxzhiliao = function(self, from, to)
	if to:getHp() < getBestHp(to) then
		sgs.updateIntention(from, to, -80)
	end
end
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|gxzhiliao"

--审判
sgs.ai_skill_playerchosen.shenpan = function(self, targets)
	local target = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, targets, false,0)[1]
	return target
end 

sgs.ai_skill_invoke.shenpan = function(self, data)
	local target = self:findPlayerToDamage(1, self.player, sgs.DamageStruct_Normal, nil, false,0)[1]
	if target then return true end
	return false
end
sgs.straight_damage_skill = sgs.straight_damage_skill .. "|shenpan"

--耐心的猎人
sgs.ai_skill_invoke.nxlieren = function(self, data)
	-- First we'll judge whether it's worth skipping the Play Phase
	local cards = sgs.QList2Table(self.player:getHandcards())
	local shouldUse, range_fix = 0, 0
	local hasCrossbow, slashTo = false, false
	for _, card in ipairs(cards) do
		if card:isKindOf("TrickCard") and self:getUseValue(card) > 3.69 then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then shouldUse = shouldUse + (card:isKindOf("ExNihilo") and 2 or 1) end
		end
		if card:isKindOf("Weapon") then
			local new_range = sgs.weapon_range[card:getClassName()] or 0
			local current_range = self.player:getAttackRange()
			range_fix = math.min(current_range - new_range, 0)
		end
		if card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then range_fix = range_fix - 1 end
		if card:isKindOf("DefensiveHorse") or card:isKindOf("Armor") and not self:getSameEquip(card) and (self:isWeak() or self:getCardsNum("Jink") == 0) then shouldUse = shouldUse + 1 end
		if card:isKindOf("Crossbow") or self:hasCrossbowEffect() then hasCrossbow = true end
	end

	local slashs = self:getCards("Slash")
	for _, enemy in ipairs(self.enemies) do
		for _, slash in ipairs(slashs) do
			if hasCrossbow and self:getCardsNum("Slash") > 1 and self:slashIsEffective(slash, enemy)
				and self.player:canSlash(enemy, slash, true, range_fix) then
				shouldUse = shouldUse + 2
				hasCrossbow = false
				break
			elseif not slashTo and self:slashIsAvailable() and self:slashIsEffective(slash, enemy)
				and self.player:canSlash(enemy, slash, true, range_fix) and getCardsNum("Jink", enemy) < 1 then
				shouldUse = shouldUse + 1
				slashTo = true
			end
		end
	end
	if shouldUse >= 2 then return false end
	
	
	return true
end
sgs.ai_skill_invoke.nxlieren_damage = function(self, data)
	local target = data:toPlayer()
	if target and self:isEnemy(target) and not self:cantbeHurt(target) and self:canDamage(target,self.player,nil) and self:damageIsEffective(target, sgs.DamageStruct_Normal, self.player) then
		return true
	end
	
	return false
end


sgs.ai_skill_choice.nxlieren = function(self, choices)
	if self.player:getMark("slash") == 0 then
		return "slash"
		else
			if self.player:getMark("jink") == 0 then
				return "jink"
			else
				if self.player:getMark("peach") == 0 then
					return "peach"
				else
					if self.player:getMark("analeptic") == 0 then
						return "analeptic"
					end
				end
			end
	end
	return "slash"
end

--布局
sgs.ai_skill_invoke.zhanshubuju = function(self, data)
	local dest
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:hasFlag("zhanshubuju_Target") then dest = aplayer break end
	end
	if not self:isFriend(dest) then return false end
	local isUse = data:toStringList()[3] == "use"
	local use 
	if isUse then
		if data:toStringList()[4] then 
			use = self.room:getTag("UseHistory"..data:toStringList()[4]):toCardUse()
		end
	end
	
	if dest and dest:hasFlag("dahe") then return false  end
	if isUse then
		if use.card and use.card:hasFlag("NosJiefanUsed") then return false  end
		if not use.from or sgs.ai_skill_cardask.nullfilter(self,data,pattern,use.from)
		or use.card:isKindOf("NatureSlash") and dest:isChained() and self:isGoodChainTarget(dest,use.card,use.from)
		or self:needToLoseHp(dest,use.from,use.card) and self:ajustDamage(use.from,dest,1,use.card)==1 then return false end
	end
	if self:needToLoseHp(dest, nil, nil, true) then return false end
	if self:getCardsNum("Jink") == 0 then return true end
	if self:ajustDamage(nil,dest,1,nil)>1 then return true end
	return true
end


sgs.ai_choicemade_filter.skillInvoke.zhanshubuju = function(self, player, promptlist)
	local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(player)) do
		if p:hasFlag("zhanshubuju_Target") then
			target = p
			break
		end
	end
	if target then
		local intention = 60
		if promptlist[#promptlist] == "yes" then
			sgs.updateIntention(player, target, -intention)
		end
	end
end

--炸场
local function getzhachangUseValueOfHECards(self, to)
	local value = 0
	-- value of handcards
	local value_h = 0
	local hcard = to:getHandcardNum()
	if to:hasSkill("lianying") then
		hcard = hcard - 0.9
	elseif to:hasSkills("shangshi|nosshangshi") then
		hcard = hcard - 0.9 * to:getLostHp()
	else
		local jwfy = self.room:findPlayerBySkillName("shoucheng")
		if jwfy and self:isFriend(jwfy, to) and (not self:isWeak(jwfy) or jwfy:getHp() > 1) then hcard = hcard - 0.9 end
	end
	value_h = (hcard > 4) and 16 / hcard or hcard
	if to:hasSkills("tuntian+zaoxian") then value = value * 0.95 end
	if (to:hasSkill("kongcheng") or (to:hasSkill("zhiji") and to:getHp() > 2 and to:getMark("zhiji") == 0)) and not to:isKongcheng() then value_h = value_h * 0.7 end
	if to:hasSkills("jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|new_longhun|xuanfeng|tianxiang|ol_tianxiang|noslijian|lijian") then value_h = value_h * 0.95 end
	value = value + value_h

	-- value of equips
	local value_e = 0
	local equip_num = to:getEquips():length()
	if to:hasArmorEffect("silver_lion") and to:isWounded() then equip_num = equip_num - 1.1 end
	value_e = equip_num * 1.1
	if to:hasSkills("kofxiaoji|xiaoji") then value_e = value_e * 0.7 end
	if to:hasSkill("nosxuanfeng") then value_e = value_e * 0.85 end
	if to:hasSkills("bazhen|yizhong") and to:getArmor() then value_e = value_e - 1 end
	value = value + value_e

	return value
end
local zhachang_skill = {}
zhachang_skill.name = "zhachang"
table.insert(sgs.ai_skills, zhachang_skill)
zhachang_skill.getTurnUseCard = function(self)
	local list=sgs.IntList()
	for _,id in sgs.qlist(self.room:getDrawPile()) do					 
		if  sgs.Sanguosha:getCard(id):isKindOf("Jink") and list:length() ~= 1 then
			list:append(id)		   
		end
	end
	if list:length() == 0 then 
		return sgs.Card_Parse("#zhachang:.:")
	end
end

sgs.ai_skill_use_func["#zhachang"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		local willUse
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then	
			 willUse = card
			 break
			end
		end
		local benefit = 0
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) then benefit = benefit - getzhachangUseValueOfHECards(self, player) end
			if self:isEnemy(player) then benefit = benefit + getzhachangUseValueOfHECards(self, player) end
		end
		if willUse and benefit > 0 then
			use.card = sgs.Card_Parse("#zhachang:" .. willUse:getEffectiveId()..":")
			
		end
end


sgs.ai_use_priority["#zhachang"] = sgs.ai_use_priority.Slash + 0.1


--洪水
sgs.ai_skill_invoke.hongshui = function(self, data)
local benefit = 0
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) then benefit = benefit - getzhachangUseValueOfHECards(self, player) end
			if self:isEnemy(player) then benefit = benefit + getzhachangUseValueOfHECards(self, player) end
		end
		if  benefit > 0 then
			return true
			
		end
	return false
end

--祝福
local zhufu_skill = {}
zhufu_skill.name = "zhufu"
table.insert(sgs.ai_skills, zhufu_skill)
zhufu_skill.getTurnUseCard = function(self)
	
	if self.player:getMark("@zfu") > 0 then 
		return sgs.Card_Parse("#zhufu:.:")
	end
end

sgs.ai_skill_use_func["#zhufu"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		local benefit = 0
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) and player:isWounded() and player:getEquips():length() > 0 then benefit = benefit + 1 end
			if self:isEnemy(player) and player:isWounded() and player:getEquips():length() > 0 then benefit = benefit - 1 end
		end
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) and self:isWeak(player) and player:getEquips():length() > 0 then benefit = benefit + 2 end
			if self:isEnemy(player) and self:isWeak(player) and player:getEquips():length() > 0  then benefit = benefit - 2 end
		end
		if benefit > 0 then
			use.card = sgs.Card_Parse("#zhufu:.:")
			
		end
end



--复活
sgs.ai_skill_invoke.afuhuo = function(self, data)
	local dying = data:toDying()
	local lord = self.room:getLord()
	if self:isFriend(dying.who) and dying.who:objectName() ~= self.player:objectName() then
		if dying.who:objectName() == lord:objectName() then return true end
		if self:isFriend(lord) and not canNiepan(lord) and lord:getHp() == 1 then return end
		if self.player:getRole() == "renegade" and #self.friends >= #self.enemies then return end
		return true
	end
	if dying.who:hasSkill("wuhun") and self:TheWuhun(dying.who, true) == -2  then return true end
	if self.player:objectName() == dying.who:objectName() then return true end
	return false
end


sgs.ai_skill_choice.afuhuo = function(self, choices)
	local items = choices:split("+")
	
				if table.contains(items, "fuhuo_j") then
					return "fuhuo_j"
				end
		if table.contains(items, "fuhuo_e") then
					return "fuhuo_e"
				end
				if table.contains(items, "fuhuo_h") then
					return "fuhuo_h"
				end
	return items[1]
end


--童话
sgs.ai_skill_invoke.tonghua = function(self, data)
	 return true
end

sgs.ai_skill_playerchosen.tonghua = function(self, targets)
	return self.player
end
sgs.ai_playerchosen_intention.tonghua = function(self, from, to)
		sgs.updateIntention(from, to, -50)
end





--灵波

sgs.ai_skill_playerchosen.lingbo = function(self, targets)
local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target then
		return	target
	end
	if  #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun") then
				return	friend
			end
		end
	end


	return nil
end
sgs.ai_playerchosen_intention.lingbo = function(self, from, to)
		sgs.updateIntention(from, to, -50)
end

sgs.recover_hp_skill = sgs.recover_hp_skill .. "|lingbo"

function sgs.ai_cardneed.lingbo(to, card, self)
	return to:getHandcardNum() < 3 and card:getSuit() == sgs.Card_Heart
end

sgs.ai_cardneed.chaogz = sgs.ai_cardneed.slash
sgs.double_slash_skill = sgs.double_slash_skill .. "|chaogz"
sgs.ai_ajustdamage_from.chaogz = function(self, from, to, card, nature)
	if from and from:getMark("chaogz") > 0 and card and card:isKindOf("Slash")
	then
		return 1
	end
end

--
sgs.ai_cardneed.shengqiang = sgs.ai_cardneed.slash
sgs.hit_skill = sgs.hit_skill .. "|shengqiang"
sgs.double_slash_skill = sgs.double_slash_skill .. "|shengqiang"

function SmartAI:UseAoeSkillValue_paojixj(element, players, card)
	element = element or sgs.DamageStruct_Normal
	local friends = {}
	local enemies = {}
	local good = 0

	players = players or sgs.QList2Table(self.room:getOtherPlayers(self.player))

	for _, ap in ipairs(players) do
		if self:isFriend(ap) then table.insert(friends, ap)
		else table.insert(enemies, ap) end
	end

	good = (#enemies - #friends) * 2
	if #enemies == 0 then return -100 end
	if element == sgs.DamageStruct_Thunder then
		for _, ap in sgs.qlist(self.room:getAlivePlayers()) do
			if ap:hasSkill("TH_yuyiruokong") then
				if self:isFriend(ap) then good = good + ap:getCardCount(true)
				else good = good - ap:getCardCount(true)
				end
			end
		end
	end
	if element == sgs.DamageStruct_Fire then
		for _,ap in sgs.qlist(self.room:getAlivePlayers()) do
			if ap:hasSkill("TH_Meltdown") then
				for _, friend in ipairs(friends) do
					if friend:getHandcardNum() > 0 then good = good - 0.5 end
				end
				for _, enemy in ipairs(enemies) do
					if enemy:getHandcardNum() > 0 then good = good + 0.5 end
				end
			end
		end
	end




	if self.player:hasSkill("TH_hongsehuanxiangxiang") then good = good + 1 end

	if self.player:getRole() == "renegade" then good = good + 0.5 end
	if self.player:getRole() == "rebel" then good = good + 0.8 end

	local who
	for _, player in ipairs(players) do
		if player:isChained() and self:damageIsEffective(player, element) and not who then who = player end
		local value = 0
		if player:getRole() == "lord" then value = value - 0.5 end
		if not self:damageIsEffective(player, element) then
			value = value + 1
			if self:isEnemy(player) and #enemies == 1 or self:isFriend(player) and #friends == 1 then value = value + 100 end
		end
		if player:getHp() == 1 and self:getAllPeachNum() == 0 then
			if player:getRole() == "lord" then value = value - 100 else value = value - 2 end
		end
		if self:needToLoseHp(player, self.player, card) then value = value + 0.5 end
		if canNiepan(player) then value = value + 0.5 end
		if self:hasSkills(sgs.save_skill ,player) then value = value + 0.5 end

		if self:isFriend(player) then good = good + value else good = good - value end
	end





--	if who and not self.player:hasSkill("jueqing") and (element == sgs.DamageStruct_Thunder or element == sgs.DamageStruct_Fire) then
		-- local damage = {}
		-- damage.from = self.player
		-- damage.to = who
		-- damage.nature = element
		-- damage.card = card
		-- damage.damage = 1
		-- good = good + self:isGoodChain(damage)
	--	good = good + self:isGoodChainTarget(who, self.player, element, 1, nil, true)
--	end
	return good
end

local paojixj_skill = {}
paojixj_skill.name = "paojixj"
table.insert(sgs.ai_skills, paojixj_skill)
paojixj_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#paojixj") and (self.player:getMark("@xjpaoj") > 0 ) then
		if self.player:getHandcardNum() >= 4 then
		local spade, club, heart, diamond
		local suit = 0
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade then spade = true
			elseif card:getSuit() == sgs.Card_Club then club = true
			elseif card:getSuit() == sgs.Card_Heart then heart = true
			elseif card:getSuit() == sgs.Card_Diamond then diamond = true
			end
		end
		if spade then
			suit = suit + 1
		end
		if club then
			suit = suit + 1
		end
		if heart then
			suit = suit + 1
		end
		if diamond then
			suit = suit + 1
		end
		if suit > 0 then
			local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			slash:deleteLater()
			self:sort(self.enemies, "hp")
			local target_num = 0
			for _, enemy in ipairs(self.enemies) do
				if self:slashIsEffective(slash, enemy) and not self:slashProhibit(slash, enemy)
				and self:isGoodTarget(enemy, self.enemies, slash) then
					target_num = target_num + 1
				end
			end

			if target_num >= 1 then
				return sgs.Card_Parse("#paojixj:.:")
			end
		end
	end
	end
end
sgs.ai_skill_use_func["#paojixj"] = function(card, use, self)--凤翼天翔
	local jiu
	if not self.player:hasUsed("Analeptic") and self:getCard("Analeptic") then
		jiu = self:getCard("Analeptic")
	end
	local s = self:getCard("Slash")
	if self:UseAoeSkillValue_paojixj(sgs.DamageStruct_Normal, nil, s) > 0 then
		if jiu and not use.isDummy then use.card = jiu return end
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByUseValue(cards, true)
		local need_cards = {}
		local spade, club, heart, diamond
		for _, card in ipairs(cards) do
			if card:getSuit() == sgs.Card_Spade and not spade then spade = true table.insert(need_cards, card:getId())
			elseif card:getSuit() == sgs.Card_Club and not club then club = true table.insert(need_cards, card:getId())
			elseif card:getSuit() == sgs.Card_Heart and not heart then heart = true table.insert(need_cards, card:getId())
			elseif card:getSuit() == sgs.Card_Diamond and not diamond then diamond = true table.insert(need_cards, card:getId())
			end
		end
		local paojixj = sgs.Card_Parse("#paojixj:" .. table.concat(need_cards, "+")..":")
		use.card = paojixj
		if use.to then
			local slash = sgs.Sanguosha:cloneCard("slash",sgs.Card_NoSuit,0)
			slash:deleteLater()
			self:sort(self.enemies, "hp")
			local target_num = 0
			for _, enemy in ipairs(self.enemies) do
				if self:slashIsEffective(slash, enemy) and not self:slashProhibit(slash, enemy)
				and self:isGoodTarget(enemy,self.enemies, slash) and target_num < #need_cards then
					target_num = target_num + 1
					use.to:append(enemy)
				end
			end
		end
		return
	end
end

sgs.ai_use_priority["paojixj"] = 3

sgs.drawpeach_skill = sgs.drawpeach_skill .. "|dqjt"

sgs.ai_skill_invoke.dqjt = function(self,data)
	local change = data:toPhaseChange()
	if change.to==sgs.Player_Draw and not self.player:isSkipped(sgs.Player_Draw) and not self.player:hasSkills("tuxi|nostuxi") then
		local cardstr = sgs.ai_skill_use["@@nostuxi"](self,"@nostuxi")
		if cardstr:match("->") then
			local targetstr = cardstr:split("->")[2]
			local targets = targetstr:split("+")
			if #targets>0 then
				return true
			end
		end
		return false
	elseif change.to==sgs.Player_Play then
		local cards = sgs.QList2Table(self.player:getHandcards())
		local shouldUse,range_fix = 0,0
		local hasCrossbow,slashTo = false,false
		for _,card in ipairs(cards)do
			if card:isKindOf("TrickCard") and self:getUseValue(card)>3.69 then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then shouldUse = shouldUse+(card:isKindOf("ExNihilo") and 2 or 1) end
			end
			if card:isKindOf("Weapon") then
				local new_range = sgs.weapon_range[card:getClassName()] or 0
				local current_range = self.player:getAttackRange()
				range_fix = math.min(current_range-new_range,0)
			end
			if card:isKindOf("OffensiveHorse") and not self.player:getOffensiveHorse() then range_fix = range_fix-1 end
			if card:isKindOf("DefensiveHorse") or card:isKindOf("Armor") and not self:getSameEquip(card) and (self:isWeak() or self:getCardsNum("Jink")==0) then shouldUse = shouldUse+1 end
			if card:isKindOf("Crossbow") or self:hasCrossbowEffect() then hasCrossbow = true end
		end

		local slashs = self:getCards("Slash")
		for _,enemy in ipairs(self.enemies)do
			for _,slash in ipairs(slashs)do
				if hasCrossbow and self:getCardsNum("Slash")>1 and self:slashIsEffective(slash,enemy)
					and self.player:canSlash(enemy,slash,true,range_fix) then
					shouldUse = shouldUse+2
					hasCrossbow = false
					break
				elseif not slashTo and self:slashIsAvailable() and self:slashIsEffective(slash,enemy)
					and self.player:canSlash(enemy,slash,true,range_fix) and getCardsNum("Jink",enemy)<1 then
					shouldUse = shouldUse+1
					slashTo = true
				end
			end
		end
		if shouldUse>=2 then return false end
		return true
	end
	
end
sgs.ai_skill_playerchosen.dqjt = function(self,targets)
	if self.player:hasFlag("dqjt") then
		local cardstr = sgs.ai_skill_use["@@nostuxi"](self,"@nostuxi")
		if cardstr:match("->") then
			local targetstr = cardstr:split("->")[2]
			local targets = targetstr:split("+")
			
			if #targets>0 then
				local to = self.room:findPlayerByObjectName(targets[1])
				if to then return to end
			end
		end
		for _,target in sgs.list(targets)do
			if self:doDisCard(target, "he") then return target end
		end
	else
		targets = sgs.QList2Table(targets)
		self:sort(targets,"defense")
		for _,target in sgs.list(targets)do
			if self:isFriend(target) and self:canDraw(target, self.player) then return target end
		end
	end
	return self.player
end

--连携
sgs.ai_skill_invoke.lianxie = function(self, data)
	 return true
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|lianxie"
sgs.ai_cardneed.lianxie = sgs.ai_cardneed.paoxiao

--换装
sgs.ai_skill_invoke.huanzhaung = function(self, data)
	 return true
end

sgs.ai_skill_cardchosen["huanzhaung"] = function(self, who, flags)
	local card
	local cards = sgs.QList2Table(who:getEquips())
	local handcards = sgs.QList2Table(who:getHandcards())
	if self:isFriend(who) then
		if self:needToThrowArmor(who) then
			return who:getArmor()
		end
		if who:hasSkills(sgs.lose_equip_skill) then
			for _, card in ipairs(cards) do
				if card:isKindOf("Weapon") then
					if card:isKindOf("Crossbow") or card:isKindOf("Blade") then continue end
					if card:isKindOf("Axe") or card:isKindOf("GudingBlade") then continue end
				elseif card:isKindOf("Armor") then
					if not self:hasSkills("bazhen|yizhong|linglong") and self:isWeak(who) then
						continue
					end
				elseif card:isKindOf("DefensiveHorse") then
					if self:isWeak(who) then continue end
				end
				return card
			end
		end
		if not who:isKongcheng() then return handcards[1] end
		return cards[1]
	end
	return nil
end


--新生
sgs.ai_skill_invoke.xinshengll = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then
		return true
	end
	return false
end

xinshengll_skill={}
xinshengll_skill.name="xinshengll"
table.insert(sgs.ai_skills,xinshengll_skill)
xinshengll_skill.getTurnUseCard=function(self,inclusive)
	if #self.enemies < 1 then return end
	local source = self.player
	if source:hasUsed("#xinshengll") then return end
	return sgs.Card_Parse("#xinshengll:.:")
end

sgs.ai_skill_use_func["#xinshengll"] = function(card,use,self)
	local target
    self:sort(self.friends_noself, "handcard")
	--sgs.reverse(self.friends_noself)
	for _,friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() > 0  then
			target = friend
			break
		end
	end
	if target  then
		use.card = sgs.Card_Parse("#xinshengll:.:")
		if use.to then use.to:append(target) end
		return
	end
end

sgs.ai_skill_askforag["xinshengll"] = function(self, card_ids)
    local cards = {}
	self.geassTarget = nil
    for _, card_id in ipairs(card_ids) do
        table.insert(cards, sgs.Sanguosha:getCard(card_id))
    end
	self:sortByUseValue(cards)
	local target
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMark("geass_touse") > 0 then
			target = p
		end
	end
    for _, card in ipairs(cards) do
        if card:isKindOf("Slash") then 
			for _,enemy in ipairs(self.enemies) do
				local def = self:getDefenseSlash(enemy)
				local eff = self:slashIsEffective(card, enemy) and self:isGoodTarget(enemy, self.enemies, card)

				if target:canSlash(enemy, slash, true) and not self:slashProhibit(card, enemy, target) and eff then
				self.geassTarget = enemy
				return card:getEffectiveId() 
				end
			end
		--return card:getEffectiveId() 
		end
		if card:isKindOf("Analeptic") then 
				return card:getEffectiveId() 
		end
		if card:isKindOf("Duel") or card:isKindOf("Snatch") or card:isKindOf("Dismantlement")  or card:isKindOf("SupplyShortage") or card:isKindOf("Indulgence")  then 
			local dummy_use = self:aiUseCard(card, dummy())
					local targets = {}
					if not dummy_use.to:isEmpty() then
						self.geassTarget = dummy_use.to:first()
						return card:getEffectiveId() 
					end
		end
		
		if  card:isKindOf("SavageAssault") or card:isKindOf("ArcheryAttack") or card:isKindOf("GodSalvation") then 
			local dummy_use = self:aiUseCard(card, dummy())
					if  dummy_use.card then
						return card:getEffectiveId() 
					end
		end
		if card:isKindOf("EquipCard") and not self:hasSkills(sgs.lose_equip_skill, target) then
			if card:isKindOf("Weapon")  and target:getWeapon() and self:evaluateWeapon(card) < self:evaluateWeapon(target:getWeapon()) then return card:getEffectiveId() 
			elseif card:isKindOf("Armor") and target:getArmor() and self:evaluateArmor(card) < self:evaluateArmor(target:getArmor()) then return card:getEffectiveId()
			end
		end
    end
    return -1
end



--破局
sgs.ai_skill_invoke.llpj = function(self, data)
local benefit = 0
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if self:isFriend(player) then benefit = benefit - player:getHp() end
			if self:isEnemy(player) then benefit = benefit + player:getHp() end
		end
		if  benefit > 0 then
			return true
			
		end
	return false
end


--社交
shejiao_skill={}
shejiao_skill.name="shejiao"
table.insert(sgs.ai_skills,shejiao_skill)
shejiao_skill.getTurnUseCard=function(self,inclusive)
	if #self.friends_noself < 1 then return end
	local source = self.player
	if source:hasUsed("#shejiao") then return end
	return sgs.Card_Parse("#shejiao:.:")
end

sgs.ai_skill_use_func["#shejiao"] = function(card,use,self)
	local target
    self:sort(self.friends_noself, "hp")
    
	sgs.reverse(self.friends_noself)
	for _,friend in ipairs(self.friends_noself) do
		if friend:isFemale() and friend:isWounded() then
			target = friend
			break
		end
		if friend:getHandcardNum() > 0 and friend:isMale() and friend:isWounded() then
			target = friend
			break
		end
	end
	if target  then
		use.card = sgs.Card_Parse("#shejiao:.:")
		if use.to then use.to:append(target) end
		return
	end
	self:sort(self.enemies, "hp")
	for _,enemy in sgs.list(self.enemies)do
		if self:objectiveLevel(enemy)>3 and enemy:isFemale() and not hasZhaxiangEffect(enemy) and self.player:getMark("@hurt") > 0 and self.player:getHp()>enemy:getHp() and self.player:getHp()>1 then
			use.card = sgs.Card_Parse("#shejiao:.:")
			if use.to then use.to:append(target) end
			return
		end
	end
end

sgs.ai_skill_choice.shejiao = function(self, choices, data)
	local target = data:toPlayer()
	local items = choices:split("+")
	if table.contains(items, "shejiao_hf") and self:isFriend(target) then
		return "shejiao_hf"
	end
	if table.contains(items, "shejiao_sq") and self:isEnemy(target) and not hasZhaxiangEffect(target) then
		return "shejiao_sq"
	end
	
	return items[1]
end

sgs.ai_skill_use["@@shejiaofuka"]=function(self,prompt)
	self:updatePlayers()
	local current = self.room:getCurrent()
	local to_give = {}
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	for _,c in ipairs(handcards) do
		if not c:isKindOf("Peach") and not c:isKindOf("Analeptic") and not c:isKindOf("Jink") and not c:isKindOf("Nullification") then
			table.insert(to_give, c:getEffectiveId())
		end
	end
	
	if #to_give == 0 then return end
	
	return "#shejiaofuka:"..table.concat(to_give, "+")..":->"..current:objectName()
end

--婉弦
sgs.ai_skill_invoke.wanxian = function(self, data)
	return true
end
sgs.ai_skill_playerchosen.wanxian = function(self, targets)
	local arr1, arr2 = self:getWoundedFriend(false, true)
	local target = self.player

	if #arr1 > 0 and (self:isWeak(arr1[1])) and arr1[1]:getHp() < getBestHp(arr1[1]) then target = arr1[1] end
	if target and target:getEquips():length() < self.player:getEquips():length() then
		return	target
	end
	if  #arr2 > 0 then
		for _, friend in ipairs(arr2) do
			if not friend:hasSkills("hunzi|longhun")  and friend:getEquips():length() < self.player:getEquips():length() then
				return	friend
			end
		end
	end
	
	for _,enemy in ipairs(self.enemies) do
		if self:isWeak(enemy) and enemy:getEquips():length() >  self.player:getEquips():length()  then
			return	enemy
		end
	end
	

	return self.player
end

--连弹
sgs.ai_skill_invoke.liantan = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.liantan = function(self, targets)
local target
    self:sort(self.friends_noself, "handcard")
	--sgs.reverse(self.friends_noself)
	for _,friend in ipairs(self.friends_noself) do
		if friend:getHandcardNum() > 0  then
			target = friend
			break
		end
	end
	if target then
		return target
	end

	return nil
end
sgs.ai_playerchosen_intention.liantan = function(self, from, to)
		sgs.updateIntention(from, to, -50)
end


sgs.ai_skill_choice.liantan = function(self, choices)
	local items = choices:split("+")
	
	if table.contains(items, "liantan_hd") then
					return "liantan_hd"
				end
	return items[1]
end



--炎魔降临
function sgs.ai_cardneed.s_yanyu(to,card)
	return to:getHandcardNum() < to:getHp()
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|s_yanyu"
sgs.ai_can_damagehp.s_yanyu = function(self,from,card,to)
	return (to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)and math.min(to:getHandcardNum(), to:getMaxHp())-to:getHp()>2)
end
s_yanmojianglin_skill={}
s_yanmojianglin_skill.name="s_yanmojianglin"
table.insert(sgs.ai_skills,s_yanmojianglin_skill)
s_yanmojianglin_skill.getTurnUseCard=function(self,inclusive)
	if #self.enemies < 1 then return end
	local source = self.player
	if source:hasUsed("#s_yanmojianglin") or source:getHandcardNum() < 3 then return end
	return sgs.Card_Parse("#s_yanmojianglin:.:")
end

sgs.ai_skill_use_func["#s_yanmojianglin"] = function(card,use,self)
	local target
	local allcard = {}
	local benefit = 0
	local players = self.room:getOtherPlayers(self.player)
		local max_distance = 0 
		local min_distance = 999
		for _, q in sgs.qlist(players) do
			max_distance = math.max(max_distance, self.player:distanceTo(q))
			min_distance = math.min(min_distance, self.player:distanceTo(q))
		end
		for _,p in sgs.qlist(players) do
			if p:isAlive() then 
				if self.player:distanceTo(p) == max_distance then
					if self:isFriend(p) then
						benefit = benefit - 1
					else
						benefit = benefit + 1
					end
				end
				if self.player:distanceTo(p) == min_distance then
					if self:isFriend(p) then
						benefit = benefit - 1
					else
						benefit = benefit + 1
					end
				end
			end
		end
		for _, card in ipairs(sgs.QList2Table(self.player:getHandcards())) do
		table.insert(allcard, card:getId())
	end
	if benefit > 0 and self.player:getHandcardNum() < 5  then
		use.card = sgs.Card_Parse("#s_yanmojianglin:".. table.concat(allcard, "+") .. ":")
		return
	end
end


sgs.ai_skill_choice.s_yanmojianglin = function(self, choices)
	local items = choices:split("+")
	local current = self.room:getCurrent()
	if self:willSkipPlayPhase() and table.contains(items, "s_yanmojianglin_skipplay") then
		return "s_yanmojianglin_skipplay"
	end
	if self:damageIsEffective(self.player, sgs.DamageStruct_Normal, current) 
			and  self:needToLoseHp(self.player, current) and table.contains(items, "s_yanmojianglin_damage") then
					return "s_yanmojianglin_damage"
	end
	if ((not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, current)) or  
	not self:isWeak())
	and table.contains(items, "s_yanmojianglin_damage") then
					return "s_yanmojianglin_damage"
	end
	if self.player:getHandcardNum() <= 3 and  table.contains(items, "s_yanmojianglin_throwcard") then
					return "s_yanmojianglin_throwcard"
				end
	return items[1]
end




--连结
s_lianjie_skill = {}
s_lianjie_skill.name = "s_lianjie"
table.insert(sgs.ai_skills, s_lianjie_skill)
s_lianjie_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#s_lianjie") then
		return sgs.Card_Parse("#s_lianjie:.:")
	end
end

sgs.ai_skill_use_func["#s_lianjie"] = function(card, use, self)
	
	self:sort(self.friends_noself, "handcard")
	self:sort(self.enemies, "handcard")
	local targets = {}
	local voidfriend, voidenemey = 0,0
		
			for _,p in sgs.qlist(self.room:getAlivePlayers()) do
				if p:hasSkill("s_lianjie") then 
					table.insert(targets, p:objectName())
					if self:isFriend(p) then
						voidfriend = voidfriend + 1
					end
					if self:isEnemy(p) then
						voidenemey = voidenemey + 1
					end
				end
			end
		
	if (voidfriend <= #self.friends_noself) then
		for _, friend in ipairs(self.friends_noself) do
			if  not table.contains(targets, friend:objectName()) and self:canDraw(friend, self.player) then
				local card_str = "#s_lianjie:.:"
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					
					if use.to then use.to:append(friend) end
					return
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if not table.contains(targets, enemy:objectName()) then
				local card_str = "#s_lianjie:.:"
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					
					if use.to then use.to:append(enemy) end
					return
			end
		end
	end
end

--破裂
s_polie_skill = {}
s_polie_skill.name = "s_polie"
table.insert(sgs.ai_skills, s_polie_skill)
s_polie_skill.getTurnUseCard = function(self)
	if #self.enemies == 0 then return end 
	if not self.player:hasUsed("#s_polie") then
		return sgs.Card_Parse("#s_polie:.:")
	end
end

sgs.ai_skill_use_func["#s_polie"] = function(card, use, self)
	
	self:sort(self.friends_noself, "handcard")
	self:sort(self.enemies, "handcard")
	local targets = {}
	local voidfriend, voidenemey = 0,0
		
			for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:hasSkill("s_lianjie") then 
					table.insert(targets, p)
					if self:isFriend(p) then
						voidfriend = voidfriend + 1
					end
					if self:isEnemy(p) then
						voidenemey = voidenemey + 1
					end
				end
			end
		
	if (voidenemey + voidfriend >= 3 or voidenemey + voidfriend == self.room:getAlivePlayers():length()) and voidenemey > 0 then
		
				local card_str = "#s_polie:.:" 
					local acard = sgs.Card_Parse(card_str)
					use.card = acard
					if use.to then
						for i = 1, #targets, 1 do
							use.to:append(targets[i])
						end
					end
					return
	end
end



sgs.ai_skill_playerchosen.s_polie = function(self, targets)
	local targetlist=sgs.QList2Table(targets)
	local enemieslist = {}
	for _, enemy in ipairs(targetlist) do
		if self:isEnemy(enemy) and not enemy:hasArmorEffect("silver_lion") and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) then
			table.insert(enemieslist, enemy)
		end
	end
    local getCmpValue = function(enemy)
        local value = 0
        if self:damageIsEffective(enemy) then
            local dmg = enemy:hasArmorEffect("silver_lion") and 1 or 2
            if enemy:getHp() <= dmg then value = 5 else value = value + enemy:getHp() / (enemy:getHp() - dmg) end
            if not self:isGoodTarget(enemy, self.enemies, nil) then value = value - 2 end
            if self:cantbeHurt(enemy, self.player, dmg) then value = value - 5 end
            if enemy:isLord() then value = value + 2 end
            if enemy:hasArmorEffect("silver_lion") then value = value - 1.5 end
            if self:hasSkills(sgs.exclusive_skill, enemy) then value = value - 1 end
            if self:hasSkills(sgs.masochism_skill, enemy) then value = value - 0.5 end
        end
        if not enemy:getEquips():isEmpty() then
            local len = enemy:getEquips():length()
            if enemy:hasSkills(sgs.lose_equip_skill) then value = value - 0.6 * len end
            if enemy:getArmor() and self:needToThrowArmor() then value = value - 1.5 end
            if enemy:hasArmorEffect("silver_lion") then value = value - 0.5 end

            if enemy:getWeapon() then value = value + 0.8 end
            if enemy:getArmor() then value = value + 1 end
            if enemy:getDefensiveHorse() then value = value + 0.9 end
            if enemy:getOffensiveHorse() then value = value + 0.7 end
            if self:getDangerousCard(enemy) then value = value + 0.3 end
            if self:getValuableCard(enemy) then value = value + 0.15 end
        end
        return value
    end

    local cmp = function(a, b)
        return getCmpValue(a) > getCmpValue(b)
    end
    table.sort(enemieslist, cmp)
    return enemieslist[1]
end


--睡眠
sgs.ai_skill_choice.s_shuimian = function(self, choices)
	local items = choices:split("+")
	
	if self:isWeak() and not self:getOverflow() > 2 and table.contains(items, "s_shuimian_recover") then
		return "s_shuimian_recover"
	end
	if self:getOverflow() > 0 and table.contains(items, "s_shuimian_skipdiscard") then
		return "s_shuimian_skipdiscard"
	end
	if self.player:isWounded() and table.contains(items, "s_shuimian_recover") then
		return "s_shuimian_recover"
	end
	
	return items[1]
end

--借宿
sgs.ai_skill_playerchosen.s_jieshu = function(self, targets)
	
	local max_card = self:getMaxCard(self.player)
	local max_point = max_card:getNumber()
	
	if self.player:hasSkill("kongcheng") and self.player:getHandcardNum() == 1 then
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() and self.player:canPindian(enemy) then
				return enemy
			end
		end
	end
	
		for _, enemy in ipairs(self.enemies) do
			if not (enemy:hasSkill("kongcheng") and enemy:getHandcardNum() == 1 and enemy:getHp() > self.player:getHp())
				and not enemy:isKongcheng() and self.player:canSlash(enemy, nil, true) and self.player:canPindian(enemy) then
				local enemy_max_card = self:getMaxCard(enemy)
				local allknown = 0
				if self:getKnownNum(enemy) == enemy:getHandcardNum() then
					allknown = allknown + 1
				end
				if (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown > 0)
					or (enemy_max_card and max_point > enemy_max_card:getNumber() and allknown < 1 and max_point > 10)
					or (not enemy_max_card and max_point > 10) then
					--self.dahe_card = max_card:getId()
					return enemy
				end
			end
		
		end
		
	for _, friend in ipairs(self.friends_noself) do
		if not friend:hasSkill("s_fudao") then
			if not self:willSkipPlayPhase(friend) then
				return friend
			end
		end
	end
    return nil
end
sgs.ai_skill_choice.s_jieshu = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target and self:isFriend(target) and table.contains(items, "s_jieshu_skill") then
		return "s_jieshu_skill"
	end
	if target and self:isEnemy(target) and table.contains(items, "s_jieshu_pindian") then
		return "s_jieshu_pindian"
	end
	
	return items[1]
end
sgs.ai_cardneed.s_jieshu = sgs.ai_cardneed.bignumber

--辅导
sgs.ai_skill_choice.s_fudao = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if target and self:isFriend(target) and table.contains(items, "s_fudao_play") then
		return "s_fudao_play"
	end
	if target and self:isEnemy(target) and table.contains(items, "s_fudao_discard") then
		return "s_fudao_discard"
	end
	
	return items[1]
end

local s_fudao_skill = {}
s_fudao_skill.name = "s_fudao"
table.insert(sgs.ai_skills, s_fudao_skill)
s_fudao_skill.getTurnUseCard = function(self, inclusive)

if not self.player:hasUsed("#s_fudao") then 
	local target 
	local players =  self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		--if p:hasSkill("slyanhuo") and not p:getPile("confuse"):isEmpty() and self:isEnemy(p) then
		if (string.find(p:getGeneralName(), "htms_bifang") or string.find(p:getGeneral2Name(), "htms_bifang")) then
			target = p
			break
		end
	end
	if target then
		return sgs.Card_Parse("#s_fudao:.:")
		end
	end
end


sgs.ai_skill_use_func["#s_fudao"] = function(card,use,self)
	local target
	local players = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		if (string.find(p:getGeneralName(), "htms_bifang") or string.find(p:getGeneral2Name(), "htms_bifang")) and 
		(self:isFriend(p) or (self:isEnemy(p) and self:doDisCard(p, "he") ))
		then
		
			target = p
			break
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
end

--抖M
sgs.ai_skill_invoke.s_douM = function(self, data)
	return true
end




--空移

sgs.ai_skill_choice.s_kongyi = function(self, choices, data)
	local items = choices:split("+")
	local target = data:toPlayer()
	if table.contains(items, "s_kongyi_damage") then
		if self:damageIsEffective(self.player, sgs.DamageStruct_Normal) and  
		self:needToLoseHp(self.player, target) then 
		return "s_kongyi_damage"
		end
		if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal) then
			return  "s_kongyi_damage"
		end
	end
	if table.contains(items, "s_kongyi_movefield") then
		local targetc
		local judges = self.player:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (enemy:hasSkill("hongyan") or judge:isKindOf("Lightning")) then
							targetc = enemy
							break
						end
					end
					if targetc then 
						return true
					end
				end
			end
		end
	
	
	
		local equips = self.player:getCards("e")
		local weak
		if not targetc and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, self.player)  then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip break
				elseif equip:isKindOf("Weapon") then card = equip break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(self.player) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(self.player) or self:needToThrowArmor(self.player)) then
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
					if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
							targetc = friend
							break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName() then
						targetc = friend
						break
					end
				end
				if targetc then 
						return "s_kongyi_movefield"
					end
				end
			end
	end
	if table.contains(items, "s_kongyi_handcard") then
		if self.player:getMark("s_kongyi_num") <= 2 then
			return "s_kongyi_handcard"
		end
	end
	
	return "s_kongyi_damage"
end

sgs.ai_skill_cardchosen.s_kongyi = function(self, who, flags)
local card
local target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (enemy:hasSkill("hongyan") or judge:isKindOf("Lightning")) then
							target = enemy
							break
						end
					end
					if target then 
						return card
					end
				end
			end
		end
	end
	if self:isEnemy(who) then
	local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					card = sgs.Sanguosha:getCard(judge:getEffectiveId())
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge)
							and not friend:getJudgingArea():isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge) then
							target = friend
							break
						end
					end
					if target then 
						return card
						end
				end
			end
		end
	end
	if self:isEnemy(who) then
		if  who:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, who) then 
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and self:hasSkills(sgs.lose_equip_skill .. "|shensu" , friend) then
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
				if target then 
						return card
					end
					end
			end
		end
	if self:isFriend(who) then
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
				if target then
						return card
					end
			end
		end
	end
end


sgs.ai_skill_playerchosen.s_kongyi_getfield = function(self, targets)
	local who = self.room:getTag("s_kongyiTarget"):toPlayer()
local card
local target
	if who then
		if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (enemy:hasSkill("hongyan") or judge:isKindOf("Lightning")) then
							target = enemy
							break
						end
					end
					if target then 
						return target
					end
				end
			end
		end
	end
	if self:isEnemy(who) then
	local judges = who:getJudgingArea()
		if who:containsTrick("YanxiaoCard") then
			for _, judge in sgs.qlist(judges) do
				if judge:isKindOf("YanxiaoCard") then
					card = sgs.Sanguosha:getCard(judge:getEffectiveId())
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge)
							and not friend:getJudgingArea():isEmpty() then
							target = friend
							break
						end
					end
					if target then break end
					for _, friend in ipairs(self.friends) do
						if not friend:containsTrick(judge:objectName()) and not self.room:isProhibited(self.player, friend, judge) then
							target = friend
							break
						end
					end
					if target then 
						return target
						end
				end
			end
		end
	end
	if self:isEnemy(who) then
		if  who:hasEquip() and not self:hasSkills(sgs.lose_equip_skill, who) then 
			local card_id = self:askForCardChosen(who, "e", "snatch")
			if card_id >= 0 and who:hasEquip(sgs.Sanguosha:getCard(card_id)) then card = sgs.Sanguosha:getCard(card_id) end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sort(self.friends, "defense")
				else
					self:sort(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and self:hasSkills(sgs.lose_equip_skill .. "|shensu" , friend) then
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
				if target then 
						return target
					end
					end
			end
		end
	if self:isFriend(who) then
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
				if target then
						return target
					end
			end
		end
	end
	end
	
end

local s_kongyi_skill = {}
s_kongyi_skill.name = "s_kongyi"
table.insert(sgs.ai_skills, s_kongyi_skill)
s_kongyi_skill.getTurnUseCard = function(self)
	if not self.player:isNude() and not self.player:hasUsed("#s_kongyi") then
        return sgs.Card_Parse("#s_kongyi:.:")
    end
end

sgs.ai_skill_use_func["#s_kongyi"] = function(card,use,self)
	self:sort(self.friends_noself, "handcard")
	local cards=sgs.QList2Table(self.player:getCards("he"))
	local needed = {}
	if self.player:isWounded() then
		for _,acard in ipairs(cards) do
			if #needed < 3 and not acard:isKindOf("Peach") then
				table.insert(needed, acard:getEffectiveId())
			end
		end
	else
		if (self:getOverflow() > 0) then
			for _,acard in ipairs(cards) do
				if #needed < self:getOverflow() and not acard:isKindOf("Peach") then
					table.insert(needed, acard:getEffectiveId())
				end
			end
		end
	end
	local target
	local players = self.room:getOtherPlayers(self.player)
	for _,p in sgs.qlist(players) do
		if p and self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal) and not self:cantbeHurt(p) and self:canDamage(p,self.player,nil)
		and not  (self:hasSkills(sgs.lose_equip_skill, p) and p:getEquips():length() > 0)
		then
		
			target = p
			break
		end
	end

	if #needed > 0 and target then
		
					use.card = sgs.Card_Parse("#s_kongyi:"..table.concat(needed,"+")..":")
					if use.to then
						use.to:append(target)
					end
					return
	end
end



--跃迁
sgs.ai_skill_invoke.s_yueqian = function(self, data)
	local source = self.player
	local card
	local target
	local damage = data:toDamage()
	if self:ajustDamage(damage.from,damage.to,damage.damage,damage.card) > 0 and self:needToLoseHp(damage.to, damage.from) then return false end
	if self:ajustDamage(damage.from,damage.to,damage.damage,damage.card) == 0 then
		return false
	end
		local judges = source:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (enemy:hasSkill("hongyan") or judge:isKindOf("Lightning")) then
							target = enemy
							break
						end
					end
					if target then 
						return true
					end
				end
			end
		end
	
	
	
		local equips = source:getCards("e")
		local weak
		if not target and not equips:isEmpty()  then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip break
				elseif equip:isKindOf("Weapon") then card = equip break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(source) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(source) or self:needToThrowArmor(source)) then
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
					if not self:getSameEquip(card, friend) and friend:objectName() ~= source:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
							target = friend
							break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= source:objectName() then
						target = friend
						break
					end
				end
				if target then 
						return true
					end
			end
		end
	return false
end

sgs.ai_skill_cardchosen.s_yueqian = function(self, who, flags)
local card
local target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (enemy:hasSkill("hongyan") or judge:isKindOf("Lightning")) then
							target = enemy
							break
						end
					end
					if target then 
						return card
					end
				end
			end
		end
	end
	if self:isFriend(who) then
		local equips = who:getCards("e")
		local weak
		if not target and not equips:isEmpty() then
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
				if target then
						return card
					end
			end
		end
	end
end
--sgs.ai_choicemade_filter.cardChosen.Zhudao = sgs.ai_choicemade_filter.cardChosen.snatch


sgs.ai_skill_playerchosen.s_yueqian = function(self, targets)
		local card
		local target
		if self:isFriend(self.player) then
		local judges = self.player:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = sgs.Sanguosha:getCard(judge:getEffectiveId())
				if not judge:isKindOf("YanxiaoCard") then
					for _, enemy in ipairs(self.enemies) do
						if not enemy:containsTrick(judge:objectName()) and not enemy:containsTrick("YanxiaoCard")
							and not self.room:isProhibited(self.player, enemy, judge) and not (enemy:hasSkill("hongyan") or judge:isKindOf("Lightning")) then
							target = enemy
							break
						end
					end
					if target then 
						return target
					end
				end
			end
		end
	end
	if self:isFriend(self.player) then
		local equips = self.player:getCards("e")
		local weak
		if not target and not equips:isEmpty() and self:hasSkills(sgs.lose_equip_skill, self.player) then
			for _, equip in sgs.qlist(equips) do
				if equip:isKindOf("OffensiveHorse") then card = equip break
				elseif equip:isKindOf("Weapon") then card = equip break
				elseif equip:isKindOf("DefensiveHorse") and not self:isWeak(self.player) then
					card = equip
					break
				elseif equip:isKindOf("Armor") and (not self:isWeak(self.player) or self:needToThrowArmor(self.player)) then
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
					if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName()
						and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
							target = friend
							break
					end
				end
				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= self.player:objectName() then
						target = friend
						break
					end
				end
				if target then
						return target
					end
			end
		end
	end
	
end

sgs.need_equip_skill = sgs.need_equip_skill .. "|s_yueqian"
sgs.use_lion_skill = sgs.use_lion_skill .. "|s_yueqian"

--新人类

sgs.ai_skill_invoke.s_newtype = function(self, data)
	local target = data:toPlayer()
	if target then
		if self:isFriend(target)  and target:getHandcardNum() < 3  then
			return true
		end
		if self:isEnemy(target) and target:getHandcardNum() > 3 then
			return true
		end
	end
	return false
end

sgs.ai_skill_use["@@s_newtype"] = function(self, prompt, method)
	return "#s_newtype:.:"
end

sgs.ai_skill_choice["s_newtype"] = function(self, choices, data)
	self:updatePlayers()
	

	local taoluan_vs_card = {}
	local types = {"BasicCard", "TrickCard", "EquipCard"}
	
	local items = choices:split("+")
	for _,card_name in ipairs(items) do
		if card_name ~= "cancel" then
			local use_card = sgs.Sanguosha:cloneCard(card_name, sgs.Card_NoSuit, -1)
			use_card:deleteLater()
			local _type = types[use_card:getTypeId()]
			if not table.contains(taoluan_vs_card, use_card) then
				table.insert(taoluan_vs_card, use_card)
			end
		end
	end
	self:sortByUsePriority(taoluan_vs_card)
	for _,c in ipairs(taoluan_vs_card) do
		if table.contains(items, c:objectName()) then
			if c:targetFixed() then
				if c:isKindOf("Peach") and self.player:isWounded() and self.player:getHp() <= 2 then
					return c:objectName()
				end
				if c:isKindOf("ExNihilo") and self.player:getHandcardNum() <= 2 then
					return c:objectName()
				end
				if c:isKindOf("SavageAssault") then
					if self:getAoeValue(c) > 0 then
						return c:objectName()
					end
				end
				if c:isKindOf("ArcheryAttack") then
					if self:getAoeValue(c) > 0 then
						return c:objectName()
					end
				end
				if c:isKindOf("AmazingGrace") then
					local low_handcard_friend = false
					for _, friend in ipairs(self.friends_noself) do
						if friend:getHandcardNum() <= 4 then
							low_handcard_friend = true
						end
					end
					if low_handcard_friend then
						return c:objectName()
					end
				end
				if c:isKindOf("GodSalvation") then
					if self:willUseGodSalvation(c) then
						return c:objectName()
					end
				end
				if c:isKindOf("Analeptic") then
					for _, slash in ipairs(self:getCards("Slash")) do
						if slash:isKindOf("NatureSlash") and slash:isAvailable(self.player) then
							local dummy_use = self:aiUseCard(slash, dummy())
							if not dummy_use.to:isEmpty() then
								for _, p in sgs.qlist(dummy_use.to) do
									if self:shouldUseAnaleptic(p, slash) then
										return c:objectName()
									end
								end
							end
						end
					end
				end
			else
				if c:isKindOf("NatureSlash") and self:getCardsNum("NatureSlash") == 0 then
					if c:isKindOf("FireSlash") or c:isKindOf("ThunderSlash") then
						local dummy_use = self:aiUseCard(c, dummy())
						local targets = {}
						if not dummy_use.to:isEmpty() then
							for _, p in sgs.qlist(dummy_use.to) do
								if p:isChained() then
									self.room:setTag("ai_taoluan_card_name", sgs.QVariant(c:objectName()))
	
									return c:objectName()
								end
							end
						end
					end
				end
				--if use_card:isNDTrick() then
				if c:isKindOf("TrickCard") and not c:isKindOf("Collateral") then
					local dummy_use = self:aiUseCard(c, dummy())
					local targets = {}
					if not dummy_use.to:isEmpty() then
						for _, p in sgs.qlist(dummy_use.to) do
							if p:getHp() <= 2 and p:getCards("he"):length() <= 2 and p:getHandcardNum() <= 1 then
								self.room:setTag("ai_taoluan_card_name", sgs.QVariant(c:objectName()))

								return c:objectName()
							end
						end
					end
				end
			end
		end
	end
	return "cancel"
end

sgs.ai_skill_use["@@s_newtypeOther"] = function(self, prompt, method)
	local card
	for _, amuro in sgs.qlist(self.room:findPlayersBySkillName("s_newtype")) do
		if self.player:getMark("s_newtype"..amuro:objectName().."-Clear") > 0 then
			card = amuro:property("s_newtype"):toString()
		end
	end
	if not card then
        return "."
    end


	local use_card = sgs.Sanguosha:cloneCard(card, sgs.Card_NoSuit, -1)
	use_card:setSkillName("s_newtype")
	
	
	local dummy_use = self:aiUseCard(use_card, dummy())
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return use_card:toString() .. "->" .. table.concat(targets, "+")
		end
	end
	return "."
end

sgs.ai_skill_invoke.htms_diwu = true

sgs.ai_skill_use["@@htms_nisheng"]=function(self,prompt)
	self:updatePlayers()
	local tos = {}
	local x = math.max(1, self.player:getMark("htms_sanqi"))
	for _,enemy in sgs.list(self.enemies)do
		if self:damageIsEffective(enemy) and not self:cantbeHurt(enemy) then
			table.insert(tos,enemy:objectName())
			if #tos >= x then
				break
			end
		end
	end
	local to_give = {}
	local handcards = sgs.QList2Table(self.player:getCards("eh"))
	for _,c in ipairs(handcards) do
		table.insert(to_give, c:getEffectiveId())
		if #to_give >= #tos then
			break
		end
	end
	if #tos== 0 or #to_give == 0 then return end
	if #tos > #to_give then
		table.removeOne(tos, tos[#tos])
	end
	if #tos > #to_give then
		table.removeOne(tos, tos[#tos])
	end
	return "#htms_nishengCard:"..table.concat(to_give, "+")..":->"..table.concat(tos, "+")
end

sgs.ai_skill_choice.htms_sanqi = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "equip") then
		return "equip"
	end
	if table.contains(items, "trick") then
		return "trick"
	end
	if table.contains(items, "basic") then
		return "basic"
	end
	
	return items[1]
end
sgs.ai_skill_invoke.htms_ranxin = function(self, data)
	if self.player:getPile("htms_mo"):length() < 2 then return true end
	if self:isWeak(self.player) and self:getAllPeachNum() <= 1 then return true end
	if not self.player:hasSkill("htms_chiyi") then return true end
	if math.random(1, 2) == 1 then
		return true
	end
	return false
end
sgs.ai_cardneed.htms_ranxin = sgs.ai_cardneed.slash

sgs.ai_target_revises.htms_coffee = function(to,card)
	if card:getSuit() == sgs.Card_Spade or (card:getSuit() == sgs.Card_Heart and to:hasSkill("htms_godot"))
	then return true end
end


sgs.ai_skill_discard.htms_lunbian = function(self,max,min,optional,equiped)
	local use = self.room:getTag("htms_lunbian"):toCardUse()
	if use.from and self:isFriend(use.from) then return {} end
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
	local color = false
	local type = false
	for _,c in sgs.list(cards)do
		if (c:sameColorWith(use.card) and not color) or (c:getType() == use.card:getType() and not type) then
			if c:sameColorWith(use.card) and not color then
				color = true
			end
			if c:getType() == use.card:getType() and not type then
				type = true
			end
			table.insert(to_cards,c:getEffectiveId())
		end
	end
	if color and type and #to_cards > 0 then 
		for _, p in sgs.qlist(use.to) do
			if self:isFriend(p) and self:isWeak(p) then
				return to_cards 
			end
		end
		for _, p in sgs.qlist(use.to) do
			if self:isEnemy(p) then
				return {}
			end
		end
		return to_cards 
	end
	return {}
end


sgs.ai_skill_playerchosen.htms_godot = function(self, targets)
	for _, p in sgs.qlist(targets) do
		if self:isFriend(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player)
			and self:needToLoseHp(p,self.player,nil) then
			return p
		end
	end
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return end
	self:sort(enemies, "hp")
	for _, enemy in ipairs(enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player)
			and not self:needToLoseHp(enemy,self.player,nil) then
			return enemy
		end
	end
	

	for _, enemy in ipairs(enemies) do
		if self:damageIsEffective(enemy, sgs.DamageStruct_Normal, self.player) then
			return enemy
		end
	end

	for _, enemy in ipairs(enemies) do
		return enemy
	end
	return targets:first()
end
