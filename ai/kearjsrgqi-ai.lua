--曹操
sgs.ai_skill_invoke.keqizhenglue = function(self, data)
	return true
end
sgs.ai_skill_invoke.keqizhengluegaincard = function(self, data)
	return true
end

sgs.ai_skill_playerschosen.keqizhenglue = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local n = max
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	--优先敌人
    for _,target in ipairs(can_choose) do
        if self:isEnemy(target) and not selected:contains(target) then
            selected:append(target)
            n = n - 1
        end
        if n <= 0 then break end
    end
	--没选满，任何人都可以
	if (n > 0) then
		for _,target in ipairs(can_choose) do
			if not selected:contains(target) then
				selected:append(target)
				n = n - 1
			end
			if n <= 0 then break end
		end
	end
    return selected
end

sgs.ai_skill_playerchosen.keqizhenglue = function(self, targets)
	targets = sgs.QList2Table(targets)
	local num = 1
	for _, p in ipairs(targets) do
		if not (p:objectName() == self.player:objectName()) then
			num = 0
			return p
		end
	end
	if num == 1 then
		return self
	end
	return nil
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|keqizhenglue"
--[[
sgs.ai_skill_playerschosen.keqizhenglue = function(self,players,x,n)
	local destlist = players
    destlist = sgs.QList2Table(destlist) -- 将列表转换为表
	--self:sort(destlist,"hp")
	local tos = {}
	for _,to in sgs.list(destlist)do
        table.insert(tos,to) end
	return tos
end
]]
sgs.ai_skill_playerchosen.keqipingrong = function(self, targets)
	for _, p in ipairs(sgs.QList2Table(targets)) do
		if self:isFriend(p) then
			return p
		end
	end
	for _, p in ipairs(sgs.QList2Table(targets)) do
		if not self:isEnemy(p) then
			return p
		end
	end
end


--刘备
sgs.recover_hp_skill = sgs.recover_hp_skill .. "|keqijishan"
sgs.ai_skill_playerchosen.keqijishan = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getHp() < getBestHp(p) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_invoke.keqijishan = function(self, data)
	local damage = data:toDamage()
	--对自己无脑用
	if (damage.to:objectName() == self.player:objectName()) then
		return true
	elseif self:isFriend(damage.to) and (not self:isWeak() or (damage.to:isLord() and self:isWeak(damage.to))) then
		return not self:needToLoseHp(damage.to, damage.from, damage.card)
	end
end

sgs.ai_choicemade_filter.skillInvoke.keqijishan = function(self,player,promptlist)
	local damage = self.room:getTag("keqijishan"):toDamage()
	if damage.to and promptlist[3]=="yes" then
		sgs.updateIntention(player,damage.to,-80)
	end
end

sgs.ai_use_revises.keqizhenqiao = function(self,card,use)
	if card:isKindOf("Weapon") then
		for _, p in ipairs(self.enemies)do
			if self.player:inMyAttackRange(p) then
				return false
			end
		end
		if #self.enemies<1 then
			return false
		end
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|keqizhenqiao"

--孙坚

sgs.ai_skill_discard.keqijuelietwo = function(self, discard_num, min_num, optional, include_equip) 
	local slashone = self.room:getTag("keqijuelietwoFrom"):toPlayer()
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards, true)
	if self:isEnemy(slashone) and (self.player:getCardCount() > 0) then
		local min = 999
		for _,p in sgs.qlist(self.room:getAllPlayers()) do
			if (p:getHandcardNum() < 999) then
				min = p:getHandcardNum()
			end
		end
		local x = self.player:getHandcardNum() - min
		
		--if self:isWeak() then
			for i = 1, x do
				table.insert(to_discard, cards[i]:getEffectiveId())
			end
		-- else
		-- 	table.insert(to_discard, cards[1]:getEffectiveId())
		-- 	if (self:getOverflow() > 1) then
		-- 		table.insert(to_discard, cards[2]:getEffectiveId())
		-- 	end
		-- end
	    
		return to_discard
	else
	    return self:askForDiscard("dummyreason", discard_num, discard_num, true, true)
	end
end
sgs.hit_skill = sgs.hit_skill .. "|keqijuelietwo"

sgs.ai_skill_discard.keqipingtao = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local room = self.player:getRoom()
	local sj = self.room:getTag("keqipingtaoFrom"):toPlayer()
	if self:isFriend(sj) then
	    table.insert(to_discard, cards[#cards]:getEffectiveId())
		return to_discard
	elseif self:isWeak() 
	and (self.player:getCardCount() > 0)
	and (self:getCardsNum("Peach") + self:getCardsNum("Analeptic") == 0) then
	    table.insert(to_discard, cards[1]:getEffectiveId())
		return to_discard
	else
		return self:askForDiscard("dummyreason", discard_num, discard_num, true, true)
	end
end

local keqipingtao_skill = {}
keqipingtao_skill.name = "keqipingtao"
table.insert(sgs.ai_skills, keqipingtao_skill)
keqipingtao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("keqipingtaoCard") then return end
	return sgs.Card_Parse("#keqipingtaoCard:.:")
end

sgs.ai_skill_use_func["#keqipingtaoCard"] = function(card, use, self)
	self:sort(self.enemies)
	local enys = sgs.SPlayerList()
	for _, enemy in ipairs(sgs.reverse(self.enemies)) do
		if enys:isEmpty() then
			enys:append(enemy)
		else
			local yes = 1
			for _,p in sgs.qlist(enys) do
				if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) >= (p:getHp()+p:getHp()+p:getHandcardNum()) then
					yes = 0
				end
			end
			if (yes == 1) then
				enys:removeOne(enys:at(0))
				enys:append(enemy)
			end
		end
	end
	for _,enemy in sgs.qlist(enys) do
		if self:objectiveLevel(enemy) > 0 then
			use.card = card
			if use.to then use.to:append(enemy) end
			return
		end
	end
end

sgs.ai_use_value.keqipingtaoCard = 8.5
sgs.ai_use_priority.keqipingtaoCard = 9.5
sgs.ai_card_intention.keqipingtaoCard = 80
sgs.double_slash_skill = sgs.double_slash_skill.."|keqipingtao"

--董白
sgs.ai_skill_invoke.keqishichong = function(self, data)
	local to = data:toPlayer()
	return self:doDisCard(to, "h", true)
end

sgs.ai_skill_discard.keqishichong = function(self, discard_num, min_num, optional, include_equip) 
	local db = self.room:getTag("keqishichongFrom"):toPlayer()
	local to_discard = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:isFriend(db) and (self.player:getCardCount() > 0) then
	    table.insert(to_discard, cards[1]:getEffectiveId())
		sgs.updateIntention(self.player,db ,-20)
		return to_discard
	else
	    return self:askForDiscard("dummyreason", discard_num, discard_num, true, true)
	end
end
sgs.drawpeach_skill = sgs.drawpeach_skill .."|keqishichong"


local keqilianzhu = {}
keqilianzhu.name = "keqilianzhu"
table.insert(sgs.ai_skills, keqilianzhu)
keqilianzhu.getTurnUseCard = function(self)
	if self.player:hasUsed("#keqilianzhuCard") then return end
	return sgs.Card_Parse("#keqilianzhuCard:.:")
end

sgs.ai_skill_use_func["#keqilianzhuCard"] = function(card, use, self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	if #cards<2 then return end
	self:sortByKeepValue(cards)
	self:sort(self.enemies,nil,true)
	local ks = {}
	local dismantlement = sgs.Sanguosha:cloneCard("dismantlement")
	dismantlement:setSkillName("_keqilianzhu")
	dismantlement:deleteLater()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isEnemy(p) and p:getCardCount()>0 and self:hasTrickEffective(dismantlement,p,self.player) then
			ks[p:getKingdom()] = (ks[p:getKingdom()] or 0)+1
		end
	end
	local x = 0
	for k,n in pairs(ks)do
		if n>x then x = n end
	end
	for k,n in pairs(ks)do
		if n>=x then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:getKingdom() == k and self:isFriend(p) and hasTuntianEffect(p) then
					use.card = sgs.Card_Parse("#keqilianzhuCard:"..cards[1]:getId()..":")
					use.to:append(p)
					return
				end
			end
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:getKingdom() == k and self:isFriend(p) and  self:doDisCard(p, "hej") then
					use.card = sgs.Card_Parse("#keqilianzhuCard:"..cards[1]:getId()..":")
					use.to:append(p)
					return
				end
			end
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:getKingdom() == k and self:isFriend(p) and p:getCardCount()>0 then
					use.card = sgs.Card_Parse("#keqilianzhuCard:"..cards[1]:getId()..":")
					use.to:append(p)
					return
				end
			end
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:getKingdom() == k and not self:isEnemy(p) and p:getCardCount()>0 then
					use.card = sgs.Card_Parse("#keqilianzhuCard:"..cards[1]:getId()..":")
					use.to:append(p)
					return
				end
			end
		end
	end
	for k, n in pairs(ks) do
		if n>=x then
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if p:getKingdom() == k then
					use.card = sgs.Card_Parse("#keqilianzhuCard:"..cards[1]:getId()..":")
					use.to:append(p)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.keqilianzhuCard = 8.5
sgs.ai_use_priority.keqilianzhuCard = 6.5
--sgs.ai_card_intention.keqilianzhuCard = 33


--何进

sgs.ai_skill_playerschosen.keqizhaobing = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local n = max
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
	--优先敌人
    for _,target in ipairs(can_choose) do
        if self:isEnemy(target) and not selected:contains(target) and not hasZhaxiangEffect(target) then
            selected:append(target)
            n = n - 1
        end
        if n <= 0 then break end
    end
    return selected
end

sgs.ai_skill_discard.keqizhaobing = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local room = self.player:getRoom()
	local hj = room:getCurrent()
	local cards = self.player:getCards("he")
	for _,c in sgs.qlist(cards) do 
		if  c:isKindOf("Slash") then
			table.insert(to_discard, c:getEffectiveId())
			break
		end
	end
	if (self:isFriend(hj) or self:isWeak()) and (#to_discard > 0) then
		return to_discard
	else
	    return self:askForDiscard("dummyreason", discard_num, discard_num, true, true)
	end
end



sgs.ai_skill_invoke.keqizhaobing = function(self, data)
	if self.player:getHandcardNum() < 3 then
	    return not sgs.ai_skill_playerschosen.keqizhaobing(self,  self.room:getOtherPlayers(self.player), self.player:getHandcardNum(), 0):isEmpty()
	end
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill.."|keqizhaobing"

sgs.ai_skill_invoke.keqizhuhuan = function(self, data)
	return sgs.ai_skill_playerchosen.keqizhuhuan(self, self.room:getOtherPlayers(self.player)) ~= nil
end

sgs.ai_skill_playerchosen.keqizhuhuan = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	local x = self.player:getMark("keqizhuhuan")
	for _, p in ipairs(targets) do
		if self:isWeak() and self:isFriend(p) then
			return p
		elseif self:isEnemy(p) and self:canDamage(p, self.player) and self:doDisCard(p,"he", false, x) then
			return p
		end
	end
	return nil
end

sgs.ai_skill_choice.keqizhuhuan = function(self, choices, data)
	local items = choices:split("+")
	local hj = self.room:getCurrent()
	if (self:isWeak() or self:isFriend(hj)) or (self:isEnemy(hj) and not hj:isWounded()) then
		return items[2]
	else
		return items[1]
	end
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill.."|keqizhuhuan"

sgs.recover_hp_skill = sgs.recover_hp_skill.."|keqizhuhuan"

--皇甫嵩
local keqiguanhuo_skill = {}
keqiguanhuo_skill.name = "keqiguanhuo"
table.insert(sgs.ai_skills, keqiguanhuo_skill)
keqiguanhuo_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("keqiguanhuoCard") and (self.player:getMark("aiguanhuo-PlayClear") == 0) then return end
	local fa = sgs.Sanguosha:cloneCard("fire_attack")
	fa:setSkillName("keqiguanhuo")
	fa:setFlags("keqiguanhuo")
	fa:deleteLater()
	if self.player:getMark("usekeqiguanhuo-PlayClear")>0 then
		local d = self:aiUseCard(fa)
		if d.card then
			local cards = self.player:getCards("h")
			for _,p in sgs.qlist(d.to) do
				local n = 0
				for _,c in sgs.list(cards) do
					if #getKnownCards(p,self.player,"h",c:getSuit())>0 then
						n = n+1
					end
				end
				if n>cards:length()/2 then
					return fa
				end
			end
		end
	else
		return fa
	end
--	return sgs.Card_Parse("#keqiguanhuoCard:.:")
end

--原版索敌
--[[
sgs.ai_skill_use_func["#keqiguanhuoCard"] = function(card, use, self)
    if (not self.player:hasUsed("#keqiguanhuoCard")) or (self.player:getMark("aiguanhuo-PlayClear") > 0) then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if self:objectiveLevel(enemy) > 0 then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end
]]
sgs.ai_skill_use_func["#keqiguanhuoCard"] = function(card, use, self)
    if (not self.player:hasUsed("#keqiguanhuoCard")) or (self.player:getMark("aiguanhuo-PlayClear") > 0) then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if not enemy:isKongcheng() then
				if enys:isEmpty() then
					enys:append(enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) >= (p:getHp()+p:getHp()+p:getHandcardNum()) then
							yes = 0
						end
					end
					if (yes == 1) then
						enys:removeOne(enys:at(0))
						enys:append(enemy)
					end
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			if self:objectiveLevel(enemy) > 0 then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end
sgs.ai_use_value.keqiguanhuoCard = 8.5
sgs.ai_use_priority.keqiguanhuoCard = 9.5
sgs.ai_card_intention.keqiguanhuoCard = 80

sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .. "|keqiguanhuo"
sgs.ai_ajustdamage_from.keqiguanhuo = function(self,from,to,card,nature)
	if card and card:isKindOf("FireAttack") and from:getMark("&usekeqiguanhuoda-PlayClear")>0
	then return 1 end
end

sgs.ai_skill_invoke.keqijuxia = function(self, data)
	local to = data:toPlayer()
	local use = self.room:getTag("keqijuxiaData"):toCardUse()
	return self:isFriend(to) and (use.card:isDamageCard() or use.to:length()>1)
end
sgs.ai_choicemade_filter.skillInvoke.keqijuxia = function(self,player,promptlist)
	local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
	if not target then return end
	if promptlist[#promptlist]=="yes" then
		sgs.updateIntention(player,target, -10)
	end
end

--孔融

sgs.ai_skill_invoke.keqimingshi = function(self, data)
	-- local to = data:toPlayer()
	-- if self:isFriend(to) and not self:isWeak() then
	--     return true
	-- end
	local dmg = data:toDamage()
	if dmg.to and not self:isFriend(dmg.to) then return false end
	if self.player:isChained() and dmg.nature~=sgs.DamageStruct_Normal
	and not self:isGoodChainTarget(self.player,dmg.card or dmg.nature,dmg.from,dmg.damage)
	then
	elseif self.player:getHp()>=2 and dmg.damage<2
	and (self.player:hasSkills(sgs.recover_skill)
		or self:needToLoseHp(self.player, dmg.from, dmg.card)
		or (self.player:getHandcardNum()<3 and (self.player:hasSkill("nosrende") or (self.player:hasSkill("rende") and not self.player:hasUsed("RendeCard")))))
	then return true
	elseif dmg.card and dmg.card:getTypeId()==sgs.Card_TypeTrick
	and self.player:hasSkill("wuyan")
	then return true
	elseif hasBuquEffect(self.player)
	then return true end
	if self:isWeak(dmg.to) then return true end
	return false	
end

sgs.ai_skill_invoke.keqilirang_use = function(self, data)
	if self.player:hasFlag("aiuselirang") then
	    return true
	end
end
sgs.ai_skill_discard.keqilirang = function(self) --给牌
	local to = self.player:getTag("keqilirangTo"):toPlayer()
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	if (self:isFriend(to) or not self:isEnemy(to) and #self.friends<#self.enemies)
	and (not self:isWeak() or #cards>3) then
		self:sortByKeepValue(cards)
		for _, c in sgs.list(cards) do
			if c:isAvailable(to) then
				table.insert(to_discard, c:getEffectiveId())
				if #to_discard>1 then break end
			end
		end
		for _, c in sgs.list(cards) do
			if #to_discard>1 then break end
			if #to_discard>0 and not table.contains(to_discard, c:getEffectiveId()) then
				table.insert(to_discard, c:getEffectiveId())
			end
		end
	end
	return to_discard
end
sgs.ai_skill_invoke.keqilirang_get = function(self, data)
	return true
end
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .. "|keqilirang"

--刘宏
sgs.ai_skill_invoke.keqichaozheng = function(self, data)
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) then
			return true
		end
	end
	return false
end


local keqishenchong_skill = {}
keqishenchong_skill.name = "keqishenchong"
table.insert(sgs.ai_skills, keqishenchong_skill)
keqishenchong_skill.getTurnUseCard = function(self)
	if self.player:getMark("@keqishenchong") == 0 then return end
	return sgs.Card_Parse("#keqishenchongCard:.:")
end

sgs.ai_skill_use_func["#keqishenchongCard"] = function(card, use, self)
	self:sort(self.friends,"defense",true)
	local player = self:AssistTarget()
	if player then
		use.card = card
		if use.to then use.to:append(player) end
		return
	end
	for _, fri in ipairs(self.friends) do
		if (fri:objectName() ~= self.player:objectName()) then
			use.card = card
			if use.to then use.to:append(fri) end
			return
		end
	end
end

sgs.ai_use_value["#keqishenchongCard"] = 8.5
sgs.ai_use_priority["#keqishenchongCard"] = 9.5
sgs.ai_card_intention["#keqishenchongCard"] = -80


--[[sgs.ai_skill_cardchosen.keqichaozheng_yishi = function(self,who)
	local player = self.player
	for _,c in sgs.qlist(who:getCards("h")) do
		if c:hasFlag("chaozhengred") or c:hasFlag("chaozhengblack") then
			return c:getId()
		end
	end
	return -1
end]]

sgs.ai_skill_discard.keqichaozheng = function(self)
	local to_discard = {}
	local from = self.room:getCurrent()
	local n = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(from)) do
		if p:isWounded() then
			n = n+1
			if not self:isEnemy() then
				n = n+1
			end
		else
			n = n-1
		end
	end
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if n >1 and c:isRed() then
			table.insert(to_discard, c:getEffectiveId())
			break
		end
	end
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if #to_discard<1 and not c:isRed() then
			table.insert(to_discard, c:getEffectiveId())
			break
		end
	end
	if #to_discard<1 then
		for i,c in sgs.qlist(self.player:getCards("h")) do
			table.insert(to_discard, c:getEffectiveId())
			break
		end
	end
	return to_discard
end


local keqitongjue = {}
keqitongjue.name = "keqitongjue"
table.insert(sgs.ai_skills, keqitongjue)
keqitongjue.getTurnUseCard = function(self)
	for i,uc in ipairs(self.toUse)do
		if i>1 then
			if uc:isKindOf("AOE") or uc:isKindOf("GlobalEffect") then
				local ids = {}
				for _, c in sgs.qlist(self.player:getCards("h")) do
					if c:isKindOf("BasicCard")
					and c:getEffectiveId()~=uc:getEffectiveId() then
						table.insert(ids, c:getEffectiveId())
					end
				end
				if #ids<1 then continue end
				return sgs.Card_Parse("#keqitongjueCard:"..table.concat(ids,"+")..":")
			else
				local d = self:aiUseCard(uc)
				if d.card and d.to:length()>1 then
					local ids = {}
					for _, c in sgs.qlist(self.player:getCards("h")) do
						if c:isKindOf("BasicCard")
						and c:getEffectiveId()~=uc:getEffectiveId() then
							table.insert(ids, c:getEffectiveId())
						end
					end
					if #ids<1 then continue end
					return sgs.Card_Parse("#keqitongjueCard:"..table.concat(ids,"+")..":")
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#keqitongjueCard"] = function(card, use, self)
	self:sort(self.friends_noself,"defense")
	for _, fri in ipairs(self.friends_noself) do
		if fri:getKingdom()=="qun" then
			use.card = card
			if use.to then use.to:append(fri) end
			break
		end
	end
end

sgs.ai_use_value.keqitongjueCard = 8.5
sgs.ai_use_priority.keqitongjueCard = 9.5
sgs.ai_card_intention.keqitongjueCard = -80


--[[sgs.ai_skill_cardchosen.keqichaozheng_yishi = function(self,who)
	local player = self.player
	for _,c in sgs.qlist(who:getCards("h")) do
		if c:hasFlag("chaozhengred") or c:hasFlag("chaozhengblack") then
			return c:getId()
		end
	end
	return -1
end]]

sgs.ai_skill_discard.keqichaozheng = function(self)
	local to_discard = {}
	local from = self.room:getCurrent()
	local n = 0
	for _,p in sgs.qlist(self.room:getOtherPlayers(from)) do
		if p:isWounded() then
			n = n+1
			if not self:isEnemy(p) then
				n = n+1
			end
		else
			n = n-1
		end
	end
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if n >1 and c:isRed() then
			table.insert(to_discard, c:getEffectiveId())
			break
		end
	end
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if #to_discard<1 and not c:isRed() then
			table.insert(to_discard, c:getEffectiveId())
			break
		end
	end
	if #to_discard<1 then
		for i,c in sgs.qlist(self.player:getCards("h")) do
			table.insert(to_discard, c:getEffectiveId())
			break
		end
	end
	return to_discard
end

sgs.ai_skill_invoke.keqijulian = function(self,data)
    return true
end

sgs.ai_skill_invoke.keqitushe = function(self,data)
	for _, c in sgs.qlist(self.player:getCards("h")) do
		if c:isKindOf("BasicCard") then return false end
	end
    return true
end

--南华老仙
sgs.ai_armor_value._keqi_taipingyaoshu = 6
sgs.ai_ajustdamage_to._keqi_taipingyaoshu = function(self,from,to,card,nature)
	if nature~="N" then return -99 end
end

sgs.ai_skill_playerchosen.keqishoushu = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if (self.player:objectName() == p:objectName()) then
		    return p 
		end
	end
	return nil
end

sgs.ai_skill_playerchosen.keqishoushutwo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if (self.player:objectName() == p:objectName()) then
		    return p 
		end
	end
	return nil
end

sgs.ai_skill_playerschosen.keqiwendao = function(self, targets,x,n)
	targets = sgs.QList2Table(targets)
	self:sort(targets,"defense",true)
	local tos = {}
	local judge = self.room:getTag("keqiwendaoJudge"):toJudge()
	if not judge:isGood() then
		for _, p in ipairs(targets) do
			if self:isFriend(p) and #tos<1 then
				for _, c in ipairs(getKnownCards(p,self.player,"he")) do
					if p:isJilei(c) then continue end
					if judge:isGood(c) then
						table.insert(tos, p)
						break
					end
				end
			end
		end
		for _, p in ipairs(targets) do
			if #tos==1 and self:isEnemy(p) then
				table.insert(tos, p)
			end
		end
		for _, p in ipairs(targets) do
			if #tos==1 and not self:isFriend(p) then
				table.insert(tos, p)
			end
		end
		for _, p in ipairs(targets) do
			if #tos==1 and tos[1]~=p then
				table.insert(tos, p)
			end
		end
	end
	return tos
end

sgs.ai_skill_discard.keqiwendao = function(self)
	local judge = self.room:getTag("keqiwendaoJudge"):toJudge()
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:isFriend(judge.who) then
		for _, c in ipairs(cards) do
			if self.player:isJilei(c) then continue end
			if judge:isGood(c) then
				return {c:getEffectiveId()}
			end
		end
	else
		for _, c in ipairs(cards) do
			if self.player:isJilei(c) then continue end
			return {c:getEffectiveId()}
		end
	end
end

sgs.ai_skill_askforag.keqiwendao = function(self,card_ids)
	local judge = self.room:getTag("keqiwendaoJudge"):toJudge()
	for _,id in sgs.list(card_ids) do
		if judge:isGood(sgs.Sanguosha:getCard(id)) then
			return id
		end
	end
end

sgs.ai_skill_invoke.keqixuanhua = function(self,data)
	if self.player:getPhase() == sgs.Player_Start then
		return not self:damageIsEffective(self.player,"T")
		or self:getFinalRetrial(nil,"lightning")<2
	end
	return (not self:damageIsEffective(self.player,"T") or self:getFinalRetrial(nil,"lightning")==1)
	and #self.enemies>0
end

sgs.ai_skill_playerchosen.keqixuanhua = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self.player:getPhase() == sgs.Player_Start and self:isFriend(p) and p:isWounded() then
		    return p 
		end
	end
	for _, p in ipairs(targets) do
		if self.player:getPhase() == sgs.Player_Finish and self:isEnemy(p) then
		    return p 
		end
	end
end

--桥玄

function sgs.ai_cardneed.keqijuezhi(to,card,self)
	for i=0,4 do
		if (to:hasEquipArea(i) and not to:getEquip(i)) then 
			return card:isKindOf("EquipCard") and card:getRealCard():toEquipCard():location() == i
		end
	end
end
sgs.ai_skill_invoke.keqijuezhi_wq = function(self,data)
    return true
end
sgs.ai_skill_invoke.keqijuezhi_fj = function(self,data)
    return true
end
sgs.ai_skill_invoke.keqijuezhi_fy = function(self,data)
    return true
end
sgs.ai_skill_invoke.keqijuezhi_jg = function(self,data)
    return true
end
sgs.ai_skill_invoke.keqijuezhi_bw = function(self,data)
    return true
end

sgs.ai_ajustdamage_from.keqijuezhi = function(self, from, to, card, nature)
	if (card) and from:getMark("canusekeqijuezhi")>0 then
		local x = 0
		for i,e in sgs.list(to:getEquips()) do
			local index = e:getRealCard():toEquipCard():location()
			if not from:hasEquipArea(index) then x = x+1 end
		end
		return x 
	end
end

sgs.ai_skill_invoke.keqijuezhi = function(self,data)
    return true
end
sgs.ai_skill_playerchosen.keqijizhao = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets,nil,true)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getJudgingArea():length() > 0 then
		    return p 
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getHandcardNum()>2 then
		    return p 
		end
	end
	sgs.ai_skill_invoke.peiqi(self,ToData())
	for _, p in ipairs(targets) do
		if p:getHandcardNum() < 3 and self:doDisCard(p,"hej",true) and self.peiqiData.from==p then
		    return p 
		end
	end
	for _, p in ipairs(targets) do
		if p:getHandcardNum() < 3 and self:doDisCard(p,"hej",true) then
		    return p 
		end
	end
	return nil
end
sgs.ai_skill_playerchosen.keqijizhao_from = function(self, targets)
	sgs.ai_skill_invoke.peiqi(self)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self.peiqiData.from==p then
		    return p 
		end
	end
	return targets[1]
end
sgs.ai_skill_playerchosen.keqijizhao_to = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self.peiqiData.to==p then
		    return p 
		end
	end
end
sgs.ai_skill_cardchosen.keqijizhao = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		if id==self.peiqiData.cid
		then return id end
	end
end



--王允

local keqishelun_skill = {}
keqishelun_skill.name = "keqishelun"
table.insert(sgs.ai_skills, keqishelun_skill)
keqishelun_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("keqishelunCard") then return end
	return sgs.Card_Parse("#keqishelunCard:.:")
end

sgs.ai_skill_use_func["#keqishelunCard"] = function(card, use, self)
    if not self.player:hasUsed("#keqishelunCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if self.player:inMyAttackRange(enemy) then
				if enys:isEmpty() then
					enys:append(enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) >= (p:getHp()+p:getHp()+p:getHandcardNum()) then
							yes = 0
						end
					end
					if (yes == 1) then
						enys:removeOne(enys:at(0))
						enys:append(enemy)
					end
				end
			end
		end
		if (enys:length() > 0) then
			for _,enemy in sgs.qlist(enys) do
				if self:objectiveLevel(enemy) > 0 then
				use.card = card
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end
end

sgs.ai_use_value.keqishelunCard = 8.5
sgs.ai_use_priority.keqishelunCard = 9.5
sgs.ai_card_intention.keqishelunCard = 80

sgs.ai_skill_playerchosen.keqifayi = sgs.ai_skill_playerchosen.damage 

sgs.ai_skill_discard.keqishelun = function(self)
	local to = self.room:getTag("keqishelunTo"):toPlayer()
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:isFriend(to) or not self:isEnemy(to) and #self.enemies>#self.friends then
		for _,c in sgs.list(cards) do
			if c:isRed() then
				return {c:getEffectiveId()}
			end
		end
	elseif self:isEnemy(to) and self:canDamage(to, self.player) then
		for _,c in sgs.list(cards) do
			if c:isBlack() then
				return {c:getEffectiveId()}
			end
		end
	end
	return {cards[1]:getEffectiveId()}
end


local keqipingjian = {}
keqipingjian.name = "keqipingjian"
table.insert(sgs.ai_skills, keqipingjian)
keqipingjian.getTurnUseCard = function(self,ex)
	for _,s in sgs.list(qiPingSkills(self.player))do
		if s:inherits("FilterSkill") then continue end
		if s:inherits("ViewAsSkill")
		and sgs.Sanguosha:getViewAsSkill(s:objectName()):isEnabledAtPlay(self.player) then
			local sk = sgs.ai_fill_skill[s:objectName()]
			if sk then
				sk = sk(self,ex)
				if sk then
					local d = self:aiUseCard(sk)
					if d.card then
						self.keqipingjianUse = d
						sgs.ai_skill_choice.keqipingjian = s:objectName()
						sgs.ai_use_priority.keqipingjianCard = sgs.ai_use_priority[sk:getClassName()]
						return sgs.Card_Parse("#keqipingjianCard:.:")
					end
				end
			end
		elseif s:inherits("TriggerSkill") then
			local ts = sgs.Sanguosha:getTriggerSkill(s:objectName())
			ts = ts:getViewAsSkill()
			if ts and ts:isEnabledAtPlay(self.player) then
				local sk = sgs.ai_fill_skill[ts:objectName()]
				if sk then
					sk = sk(self,ex)
					if sk then
						local d = self:aiUseCard(sk)
						if d.card then
							self.keqipingjianUse = d
							sgs.ai_skill_choice.keqipingjian = ts:objectName()
							sgs.ai_use_priority.keqipingjianCard = sgs.ai_use_priority[sk:getClassName()]
							return sgs.Card_Parse("#keqipingjianCard:.:")
						end
					end
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#keqipingjianCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value.keqipingjianCard = 8.5
sgs.ai_use_priority.keqipingjianCard = 9.5

sgs.ai_skill_use["@@keqipingjian"] = function(self,prompt)
    local dummy = self.keqipingjianUse
   	if dummy.card then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

--杨彪
local keqiyizheng_skill = {}
keqiyizheng_skill.name = "keqiyizheng"
table.insert(sgs.ai_skills, keqiyizheng_skill)
keqiyizheng_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("keqiyizhengCard") then return end
	return sgs.Card_Parse("#keqiyizhengCard:.:")
end

sgs.ai_skill_use_func["#keqiyizhengCard"] = function(card, use, self)
    self:sort(self.enemies,nil,true)
	local mc = self:getMaxCard()
	if not mc or mc:getNumber()<11 then return end
	for _, enemy in ipairs(self.enemies) do
		if not self.player:canPindian(enemy) or not self:doDisCard(enemy,"h") then continue end
		if self.player:getHandcardNum()<enemy:getHandcardNum() then
			local maxcard = self:getMaxCard(enemy)
			if maxcard then
				local number = maxcard:getNumber()
				if enemy:hasSkill("tianbian") and maxcard:getSuit()==sgs.Card_Heart then number = 13 end
				if number<mc:getNumber() then
					use.card = card
					self.keqiyizheng_card = mc:getEffectiveId()
					use.to:append(enemy) 
					return
				end
			end
		end
	end
end

sgs.ai_use_value.keqiyizhengCard = 8.5
sgs.ai_use_priority.keqiyizhengCard = 3.5
sgs.ai_card_intention.keqiyizhengCard = 80

sgs.ai_skill_choice.keqiyizheng = function(self,choices,data)
	local from = data:toPlayer()
	local items = choices:split("+")
	if self:isFriend(from) then
		if self:isWeak(from) then
			return items[1]
		end
	elseif self:isEnemy(from) then
		if self:isWeak(from) then
			return items[3]
		end
	end
	return items[2]
end
sgs.ai_cardneed.keqiyizheng = sgs.ai_cardneed.bignumber

sgs.ai_can_damagehp.keqirangjie = function(self,from,card,to)
	return not(self:isWeak(to) or (to:hasSkill("keqizhaohan") and self.room:getTag("keqizhaohan"):toInt() ~= 1))
	and self:ajustDamage(from,to,1,card)>0 and self:canLoseHp(from,card,to)
end

sgs.ai_skill_invoke.keqirangjie = function(self,data)
    return sgs.ai_skill_invoke.peiqi(self,data)
end

sgs.ai_skill_playerchosen["keqirangjie_from"] = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==self.peiqiData.from:objectName()
		then return target end
	end
end

sgs.ai_skill_playerchosen["keqirangjie_to"] = function(self,players)
	for _,target in sgs.list(players)do
		if target:objectName()==self.peiqiData.to:objectName()
		then return target end
	end
end

sgs.ai_skill_cardchosen.keqirangjie = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		if id==self.peiqiData.cid
		then return id end
	end
end

--朱儁
sgs.ai_skill_invoke.keqifendi = function(self,data)
    local target = data:toPlayer()
	if not self:isFriend(target) then return true end
	return false
end

sgs.ai_skill_invoke.keqijuxiang = function(self,data)
	local cp = self.room:getCurrent()
	local move = data:toMoveOneTime()
    if self:isFriend(cp) and cp:getPhase()<=sgs.Player_Play and getCardsNum("Slash",cp,self.player)>0
	and not self.player:hasFlag("keqijuxiang") and move.card_ids:length()<=2 then
		self.player:setFlags("keqijuxiang")
		return #self.enemies>0
	end
end

sgs.ai_skill_cardchosen.keqifendi = function(self,who,flags,method)
	if self.disabled_ids:length()>=who:getHandcardNum()/2
	or self.disabled_ids:length()>=math.random(1,who:getHandcardNum())
	then return -1 end
end
sgs.ai_cardneed.keqifendi = sgs.ai_cardneed.paoxiao
sgs.hit_skill = sgs.hit_skill .. "|keqifendi"

--王荣
sgs.ai_skill_invoke.keqijizhanw = function(self,data)
    return true
end

sgs.ai_skill_choice.keqijizhanw = function(self,choices,data)
	local n = data:toInt()
	local player = self.player
	local items = choices:split("+")
	if n>6 then return items[2] end
	if n<7 then return items[1] end
	return items[2]
end


sgs.ai_skill_playerchosen.keqifusong = function(self,players)
	local player = self.player
	players = self:sort(players,"card",true)
    for _,target in sgs.list(players)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(players)do
		if not self:isEnemy(target)
		then return target end
	end
end








--孙策
local kechengduxing_skill = {}
kechengduxing_skill.name = "kechengduxing"
table.insert(sgs.ai_skills, kechengduxing_skill)
kechengduxing_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kechengduxingCard") then return end
	return sgs.Card_Parse("#kechengduxingCard:.:")
end

sgs.ai_skill_use_func["#kechengduxingCard"] = function(card, use, self)
	local dc = dummyCard("duel")
	dc:setSkillName("kechengduxing")
	local d = self:aiUseCard(dc,dummy(false,99))
	if d.card then
		local n = self:getCardsNum("Slash")
		for _, p in sgs.list(d.to) do
			if n>=p:getHandcardNum() or p:isKongcheng() then
				n = n-p:getHandcardNum()
				use.card = card	
				if use.to then
					use.to:append(p)
				end
			end
		end
	end
end

sgs.ai_use_value.kechengduxingCard = 8.5
sgs.ai_use_priority.kechengduxingCard = 4.5
sgs.ai_card_intention.kechengduxingCard = 66

sgs.ai_skill_invoke.kechengzhasi = function(self, data)
	return true
end

sgs.ai_skill_invoke.kechengbashi = function(self, data)
	return #self.friends_noself>0
end

sgs.ai_skill_cardask["kechengbashi_ask"] = function(self,data,pattern)
	local from = data:toPlayer()
	local ct = "."
	if self:isFriend(from) then
		if pattern=="jink" then
			ct = self:getCardId("Jink")
		else
			ct = self:getCardId("Slash")
		end
	end
    return ct or "."
end

--陈登
local kechenglunshi_skill = {}
kechenglunshi_skill.name = "kechenglunshi"
table.insert(sgs.ai_skills, kechenglunshi_skill)
kechenglunshi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kechenglunshiCard") then return end
	return sgs.Card_Parse("#kechenglunshiCard:.:")
end

sgs.ai_skill_use_func["#kechenglunshiCard"] = function(card, use, self)
	local mp = 0
	local qp = 0
	for _,one in sgs.qlist(self.room:getAllPlayers()) do
		mp = 0
		qp = 0
		for _, p in sgs.qlist(self.room:getOtherPlayers(one)) do
			if one:inMyAttackRange(p) then
				mp = mp + 1
			end
		end
		for _, p in sgs.qlist(self.room:getOtherPlayers(one)) do
			if p:inMyAttackRange(one) then
				qp = qp + 1
			end
		end
		if (one:getHandcardNum() >= 5) then mp = 0 end
		if (one:getHandcardNum() < 5) then mp = math.min(5-one:getHandcardNum(),mp) end
		if (self:isFriend(one) and (mp>=qp)) or (self:isEnemy(one) and (mp<qp)) then
			use.card = card
			if use.to then use.to:append(one) end
			break
		end
	end
end

sgs.ai_use_value.kechenglunshiCard = 8.5
sgs.ai_use_priority.kechenglunshiCard = 9.5
sgs.ai_card_intention.kechenglunshiCard = 80

sgs.ai_skill_playerschosen.kechengguitu = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	local tos = {}
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:isWounded() then
			local pw = p:getWeapon():getRealCard():toWeapon():getRange()
			for _, p2 in ipairs(targets) do
				if not self:isFriend(p2) then
					local p2w = p2:getWeapon():getRealCard():toWeapon():getRange()
					if p2w>pw then
						table.insert(tos, p)
						table.insert(tos, p2)
						return tos
					end
				end
			end
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:isWounded() then
			local pw = p:getWeapon():getRealCard():toWeapon():getRange()
			for _, p2 in ipairs(targets) do
				local p2w = p2:getWeapon():getRealCard():toWeapon():getRange()
				if p2w>pw then
					table.insert(tos, p)
					table.insert(tos, p2)
					return tos
				end
			end
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			local w = p:getWeapon()
			for _, p2 in ipairs(targets) do
				if not self:isFriend(p2) and not p2:isWounded() then
					local w2 = p2:getWeapon()
					if self:evaluateWeapon(w,p)<self:evaluateWeapon(w2,p) then
						table.insert(tos, p)
						table.insert(tos, p2)
						return tos
					end
				end
			end
		end
	end
	return tos
end

--许贡
sgs.ai_skill_playerchosen.kechengyechou = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
		    return p 
		end
	end
	return nil
end

sgs.ai_skill_playerschosen.kechengbiaozhao = function(self, targets)
	targets = sgs.QList2Table(targets)
	local tos = {}
	self:sort(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			for _, p2 in ipairs(sgs.reverse(targets)) do
				if self:isFriend(p2) then
					table.insert(tos, p2)
					table.insert(tos, p)
					return tos
				end
			end
		end
	end
	return tos
end

--吕布

local kechengqingjiao_skill = {}
kechengqingjiao_skill.name = "kechengqingjiao"
table.insert(sgs.ai_skills, kechengqingjiao_skill)
kechengqingjiao_skill.getTurnUseCard = function(self)
	if ((self.player:getMark("&useqingjiaochdj-Clear")>0) and (self.player:getMark("&useqingjiaotxzf-Clear")>0))
	--if self.player:hasUsed("kechengqingjiaoCard") 
	or self.player:isNude() 
	or #self.enemies == 0
	or (self.player:getKingdom() ~= "qun")  then return end
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
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#kechengqingjiaoCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#kechengqingjiaoCard"] = function(card, use, self)
    if (self.player:getKingdom() == "qun") then
		if self.player:getMark("&useqingjiaochdj-Clear")<1 then
			local room = self.room
			local all = room:getOtherPlayers(self.player)
			local enys = sgs.SPlayerList()
			for _, p in sgs.qlist(all) do
				if self:isEnemy(p) then
					if (p:getHandcardNum() < self.player:getHandcardNum()) 
					and (self.player:getMark("&useqingjiaochdj-Clear")<1) then
						enys:append(p)
					end
				end
			end
			--挑选最脆弱的敌人
			local pre = sgs.SPlayerList()
			local chdj = sgs.Sanguosha:cloneCard("yj_chenhuodajie")
			chdj:setSkillName("kechengqingjiao") 
			chdj:addSubcard(card:getEffectiveId())
			chdj:deleteLater()
			for _, enemy in sgs.qlist(enys) do
				if self.player:isProhibited(enemy,chdj) then continue end
				if pre:isEmpty() then
					pre:append(enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(pre) do
						if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) >= (p:getHp()+p:getHp()+p:getHandcardNum()) then
							yes = 0
						end
					end
					if (yes == 1) then
						pre:removeOne(pre:at(0))
						pre:append(enemy)
					end
				end
			end
			for _, p in sgs.qlist(pre) do
				use.card = card
				if use.to then
					use.to:append(p)
				end
				return
			end
		end
		if self.player:getMark("&useqingjiaotxzf-Clear")<1 then
			local all = self.room:getOtherPlayers(self.player)
			local enys = sgs.SPlayerList()
			for _, p in sgs.qlist(all) do
				if self:isEnemy(p) then
					if (p:getHandcardNum() > self.player:getHandcardNum()) 
					and (self.player:distanceTo(p)<=1)
					and (self.player:getMark("&useqingjiaotxzf-Clear")<1) then
						enys:append(p)
					end
				end
			end
			--挑选最强大的敌人
			local pre = sgs.SPlayerList()
			local txzf = sgs.Sanguosha:cloneCard("yj_tuixinzhifu")
			txzf:setSkillName("kechengqingjiao") 
			txzf:addSubcard(card:getEffectiveId())
			txzf:deleteLater()
			for _, enemy in sgs.qlist(enys) do
				if not self.player:canUse(txzf,enemy) then continue end
				if pre:isEmpty() then
					pre:append(enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(pre) do
						if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) < (p:getHp()+p:getHp()+p:getHandcardNum()) then
							yes = 0
						end
					end
					if (yes == 1) then
						pre:removeOne(pre:at(0))
						pre:append(enemy)
					end
				end
			end
			for _, p in sgs.qlist(pre) do
				use.card = card
				if use.to then
					use.to:append(p)
				end
				return
			end
		end
	end
end

sgs.ai_use_value.kechengqingjiaoCard = 8.5
sgs.ai_use_priority.kechengqingjiaoCard = 9.5
sgs.ai_card_intention.kechengqingjiaoCard = 80

sgs.ai_skill_cardask["_kecheng_chenhuodajie0"] = function(self,data,pattern,prompt)
	local c = sgs.Sanguosha:getCard(pattern)
	if c then
		if self:isWeak() and c:isKindOf("Analeptic")
		or self:getKeepValue(c)>5.3
		then return "." end
		return c:getEffectiveId()
	end
end

sgs.ai_cardneed.kechengqingjiao = function(to, card, self)
	return true
end







--许攸
sgs.ai_skill_choice.kechenglipan = function(self, choices)
	local items = choices:split("+")
	local ks = {}
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		ks[p:getKingdom()] = (ks[p:getKingdom()] or 0)+1
	end
	local x = 0
	for k, n in pairs(ks) do
		if n>x then x = n end
	end
	for k, n in pairs(ks) do
		if n>=x and table.contains(items, k) and self.player:getKingdom() ~= k then
			if k=="qun" or k == "wei" then
				return k
			end
		end
	end
	for k, n in pairs(ks) do
		if n>=x and table.contains(items, k) and self.player:getKingdom() ~= k then
			return k
		end
	end
	if self.player:getKingdom() ~= "qun" then
	    return "qun"
	elseif self.player:getKingdom() ~= "wei" then
	    return "wei"
	end
end

sgs.ai_skill_invoke.lipanuseduel = function(self, data)
	return (self.player:getMark("wantuselipan-Clear") > 0)
end

sgs.ai_skill_invoke.kechenglipan = function(self, data)
	return true
end

sgs.ai_skill_discard.kechenglipan = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local from = self.room:getCurrent()
	if self:isEnemy(from) then
		return {cards[1]:getEffectiveId()}
	end
	return to_discard
end

local kechengqingxi_skill = {}
kechengqingxi_skill.name = "kechengqingxi"
table.insert(sgs.ai_skills, kechengqingxi_skill)
kechengqingxi_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#kechengqingxiCard:.:")
end

sgs.ai_skill_use_func["#kechengqingxiCard"] = function(card, use, self)
	local enys = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getMark("beusekechengqingxi-PlayClear")>0
		then enys:append(p) end
	end
	local dc = dummyCard("yj_stabs_slash")
	dc:setSkillName("kechengqingxi")
	local d = self:aiUseCard(dc,dummy(nil,99,enys))
	if d.card then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards,nil,"j")
		for _,p in sgs.qlist(d.to) do
			local n = self.player:getHandcardNum()-p:getHandcardNum()
			if n>0 and #cards>=n then
				enys = {}
				for _,c in sgs.list(cards) do
					table.insert(enys, c:getId())
					if #cards>=n then break end
				end
				use.card = sgs.Card_Parse("#kechengqingxiCard:"..table.concat(enys,"+")..":")
				use.to:append(p)
				break
			end
		end
	end
end

sgs.ai_use_value.kechengqingxiCard = 8.5
sgs.ai_use_priority.kechengqingxiCard = 2.5
sgs.ai_card_intention.kechengqingxiCard = 66


local kechengjinmie_skill = {}
kechengjinmie_skill.name = "kechengjinmie"
table.insert(sgs.ai_skills, kechengjinmie_skill)
kechengjinmie_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kechengjinmieCard") then return end
	return sgs.Card_Parse("#kechengjinmieCard:.:")
end

sgs.ai_skill_use_func["#kechengjinmieCard"] = function(card, use, self)
    if (not self.player:hasUsed("#kechengjinmieCard")) and (self.player:getKingdom() == "wei") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if (enemy:getHandcardNum() > self.player:getHandcardNum()) then
				if self:isEnemy(enemy) then
					enys:append(enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) >= (p:getHp()+p:getHp()+p:getHandcardNum()) then
							yes = 0
						end
					end
					if (yes == 1) then
						enys:removeOne(enys:at(0))
						enys:append(enemy)
					end
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			if self:objectiveLevel(enemy) > 0 then
				use.card = card
				if use.to then use.to:append(enemy) end
				break
			end
		end
	end
end

sgs.ai_use_value.kechengjinmieCard = 8.5
sgs.ai_use_priority.kechengjinmieCard = 2.5
sgs.ai_card_intention.kechengjinmieCard = 80

--张郃

sgs.ai_guhuo_card.kechengqongtu = function(self,cname,class_name)
    if self:getCardsNum(class_name)>0 then return end
	local handcards = self.player:getCards("he")
    handcards = self:sortByKeepValue(handcards) -- 按保留值排序
	for _, h in ipairs(handcards) do
    	if h:getTypeId()~=1 then
			return "#kechengqongtuCard:"..handcards[1]:getEffectiveId()..":"..cname
		end
	end
end

sgs.ai_skill_choice.kechengzhanghe_ChooseKingdom = function(self, choices)
	local items = choices:split("+")
	return "wei"
end

sgs.ai_view_as.kechengxianzhu = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceSpecial and (player:getKingdom() == "wei") and card:isNDTrick() and not card:hasFlag("using") then
		return ("slash:kechengxianzhu[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local kechengxianzhu_skill = {}
kechengxianzhu_skill.name = "kechengxianzhu"
table.insert(sgs.ai_skills, kechengxianzhu_skill)
kechengxianzhu_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getKingdom() == "wei" then 
		local cards = self.player:getCards("h")
		cards = sgs.QList2Table(cards)
		local red_card
		self:sortByUseValue(cards, true)
	
		local useAll = false
		self:sort(self.enemies, "defense")
		for _, enemy in ipairs(self.enemies) do
			if enemy:getHp() == 1 and not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() and self:isWeak(enemy)
				and getCardsNum("Jink", enemy, self.player) + getCardsNum("Peach", enemy, self.player) + getCardsNum("Analeptic", enemy, self.player) == 0 then
				useAll = true
				break
			end
		end
	
		local disCrossbow = false
		if self:getCardsNum("Slash") < 2 or self.player:hasSkills("paoxiao|tenyearpaoxiao|olpaoxiao") then
			disCrossbow = true
		end
	
		local nuzhan_equip = false
		local nuzhan_equip_e = false
		self:sort(self.enemies, "defense")
		if self.player:hasSkill("nuzhan") then
			for _, enemy in ipairs(self.enemies) do
				if  not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange()
				and getCardsNum("Jink", enemy) < 1 then
					nuzhan_equip_e = true
					break
				end
			end
			for _, card in ipairs(cards) do
				if card:isNDTrick() and nuzhan_equip_e then
					nuzhan_equip = true
					break
				end
			end
		end
	
		local nuzhan_trick = false
		local nuzhan_trick_e = false
		self:sort(self.enemies, "defense")
		if self.player:hasSkill("nuzhan") and not self.player:hasFlag("hasUsedSlash") and self:getCardsNum("Slash") > 1 then
			for _, enemy in ipairs(self.enemies) do
				if  not enemy:hasArmorEffect("EightDiagram") and self.player:distanceTo(enemy) <= self.player:getAttackRange() then
					nuzhan_trick_e = true
					break
				end
			end
			for _, card in ipairs(cards) do
				if card:isNDTrick() and nuzhan_trick_e then
					nuzhan_trick = true
					break
				end
			end
		end
	
		for _, card in ipairs(cards) do
			if card:isNDTrick() and not (nuzhan_equip or nuzhan_trick)
				and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
				and (not isCard("Crossbow", card, self.player) or disCrossbow)
				and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0) then
				red_card = card
				break
			end
		end
	
		if nuzhan_equip then
			for _, card in ipairs(cards) do
				if card:isNDTrick() and card:isKindOf("EquipCard") then
					red_card = card
					break
				end
			end
		end
	
		if nuzhan_trick then
			for _, card in ipairs(cards) do
				if card:isNDTrick() and card:isKindOf("TrickCard")then
					red_card = card
					break
				end
			end
		end
	
		if red_card then
			local suit = red_card:getSuitString()
			local number = red_card:getNumberString()
			local card_id = red_card:getEffectiveId()
			local card_str = ("slash:kechengxianzhu[%s:%s]=%d"):format(suit, number, card_id)
			local slash = sgs.Card_Parse(card_str)
	
			assert(slash)
			return slash
		end
	end
end

function sgs.ai_cardneed.kechengxianzhu(to, card)
	return card:isNDTrick()
end

sgs.ai_use_priority["kechengxianzhu"] = 9

--关羽

local kechengnianen_skill = {}
kechengnianen_skill.name = "kechengnianen"
table.insert(sgs.ai_skills, kechengnianen_skill)
kechengnianen_skill.getTurnUseCard = function(self, inclusive)
	local handcards = self:addHandPile("he")
	self:sortByKeepValue(handcards)
	local dc = dummyCard()
	if dc and dc:isKindOf("BasicCard") then
		dc:setSkillName("kechengnianen")
		for _, h in ipairs(handcards)do
			if not h:isRed() then continue end
			dc:addSubcard(h)
			if dc:isAvailable(self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					return dc--sgs.Card_Parse("#kechengnianenCard:"..h:getId()..":"..pn)
				end
			end
			dc:clearSubcards()
		end
	end
	for _,pn in ipairs(patterns())do
		local dc = dummyCard(pn)
		if dc and dc:isKindOf("BasicCard") then
			dc:setSkillName("kechengnianen")
			for _, h in ipairs(handcards)do
				dc:addSubcard(h)
				if dc:isAvailable(self.player) then
					local d = self:aiUseCard(dc)
					if d.card then
						return dc--sgs.Card_Parse("#kechengnianenCard:"..h:getId()..":"..pn)
					end
				end
				dc:clearSubcards()
			end
		end
	end
end

sgs.ai_skill_use_func["#kechengnianenCard"] = function(card, use, self)
	if (self.player:getMark("&bannianen-Clear") == 0) then
		local userstring = card:toString()
		userstring = (userstring:split(":"))[4]
		local kechengnianencard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
		kechengnianencard:setSkillName("kechengnianen")
		self:useBasicCard(kechengnianencard, use)
		if not use.card then return end
		use.card = card
	end
end

sgs.ai_use_priority["kechengnianenCard"] = 9
sgs.ai_use_value["kechengnianenCard"] = 9

sgs.ai_cardsview["kechengnianen"] = function(self,class_name,player)
	local handcards = self:addHandPile("he")
	for _, c in sgs.list(handcards) do
		if c:isKindOf(class_name)
		then return end
	end
	self:sortByKeepValue(handcards)
	if class_name=="Slash" then
		for _, c in ipairs(handcards) do
			if c:isRed() then
				local dc = dummyCard()
				dc:setSkillName("kechengnianen")
				dc:addSubcard(c)
				if not player:isLocked(dc) then
					return dc:toString()
				end
			end
		end
	end
	local cn = patterns(class_name)
	for _, c in ipairs(handcards) do
		local dc = dummyCard(cn)
		dc:setSkillName("kechengnianen")
		dc:addSubcard(c)
		if not player:isLocked(dc) then
			return dc:toString()
		end
	end
end

function sgs.ai_cardneed.kechengnianen(to, card, self)
	if (to:getMark("&bannianen-Clear") > 0) then return false end
	return true
end

--张辽

local kechengzhengbing_skill = {}
kechengzhengbing_skill.name = "kechengzhengbing"
table.insert(sgs.ai_skills, kechengzhengbing_skill)
kechengzhengbing_skill.getTurnUseCard = function(self)
	if (self.player:getMark("kechengzhengbing-Clear") >= 3) or (self.player:getKingdom() ~= "qun") or (self.player:isKongcheng()) then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if (self.player:getMark("kechengzhengbing-Clear") <= 1) then
		local yes = 0
		local to_throw = sgs.IntList()
		for _, acard in ipairs(cards) do
			if acard:isKindOf("Jink") then
				card_id = acard:getEffectiveId()
				yes = 1
				break
			end
		end
		if yes == 0 then
			for _, acard in ipairs(cards) do
				to_throw:append(acard:getEffectiveId())
			end
			card_id = to_throw:at(0)--(to_throw:length()-1)
		end
		if not card_id then
			return nil
		else
			return sgs.Card_Parse("#kechengzhengbingCard:"..card_id..":")
		end
	else
		local to_throw = sgs.IntList()
		for _, acard in ipairs(cards) do
			to_throw:append(acard:getEffectiveId())
		end
		card_id = to_throw:at(0)--(to_throw:length()-1)
		if not card_id then
			return nil
		else
			return sgs.Card_Parse("#kechengzhengbingCard:"..card_id..":")
		end
	end
end

sgs.ai_skill_use_func["#kechengzhengbingCard"] = function(card, use, self)
    if (self.player:getMark("kechengzhengbing-Clear") < 3) then 
        use.card = card
	    return
	end
end

function sgs.ai_cardneed.kechengzhengbing(to, card, self)
	if (self.player:getMark("kechengzhengbing-Clear") >= 3) then return false end
	return true
end

sgs.ai_use_value.kechengzhengbingCard = 8.5
sgs.ai_use_priority.kechengzhengbingCard = 9.5
sgs.ai_card_intention.kechengzhengbingCard = -80

sgs.ai_skill_playerschosen.kechengtuwei = function(self, targets)
	targets = sgs.QList2Table(targets)
	local tos = {}
	self:sort(targets)
	for _, p in ipairs(targets) do
		if self:doDisCard(p,"he",true) then
			table.insert(tos, p)
		end
	end
	return tos
end


--邹氏
sgs.ai_skill_invoke.kechengguyin = function(self, data)
	return math.random(0,self.player:getMark("&kechengguyinmale"))>1
	or self:isWeak()
end

sgs.ai_skill_invoke.kechengguyinturnover = function(self, data)
	return math.random(0,1)>0 and self.player:getHandcardNum()<3
	or self:isWeak()
end

local kechengzhangdengex = {}
kechengzhangdengex.name = "kechengzhangdengex"
table.insert(sgs.ai_skills, kechengzhangdengex)
kechengzhangdengex.getTurnUseCard = function(self)
	local dc = dummyCard("analeptic")
	dc:setSkillName("_kechengzhangdeng")
	local d = self:aiUseCard(dc)
	if d.card then
		return sgs.Card_Parse("#kechengzhangdengCard:.:")
	end
end

sgs.ai_skill_use_func["#kechengzhangdengCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_value.kechengzhangdengCard = 8.5
sgs.ai_use_priority.kechengzhangdengCard = sgs.ai_use_priority.Analeptic

sgs.ai_cardsview.kechengzhangdengex = function(self,class_name,player)
	return "#kechengzhangdengCard:.:"
end

--陶谦
sgs.ai_skill_invoke.kechengyirang = function(self, data)
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(p) and p:getMaxHp()>self.player:getMaxHp() then
			return true
		end
	end
	for _,p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if not self:isEnemy(p) and p:getMaxHp()>=self.player:getMaxHp() and self:isWeak() then
			return true
		end
	end
end

sgs.ai_skill_playerchosen.kechengyirang = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets,"maxhp",true)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getMaxHp()>=self.player:getMaxHp() then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if not self:isEnemy(p) and p:getMaxHp()>=self.player:getMaxHp() then
			return p
		end
	end
end

--甄宓
sgs.ai_skill_discard.kechengjixiang = function(self)
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to = self.player:getTag("kechengjixiangTo"):toPlayer()
	if self:isFriend(to) then
		return {cards[1]:getEffectiveId()}
	end
	return to_discard
end

sgs.ai_cardsview["kechengjixiangex"] = function(self,class_name,player)
	local cp = self.room:getCurrent()
	local pn = patterns(class_name)
	if not self:isEnemy(cp) and cp:getMark(pn.."kechengjixiang-Clear")<1 then
		return "#kechengjixiangCard:.:"..pn
	end
end

local kechengchengxian = {}
kechengchengxian.name = "kechengchengxian"
table.insert(sgs.ai_skills, kechengchengxian)
kechengchengxian.getTurnUseCard = function(self)
	local cans = {}
	for _,h in sgs.qlist(self.player:getHandcards()) do
		if h:isAvailable(self.player) then
			table.insert(cans, h)
		end
	end
	self:sortByKeepValue(cans)
	for _, h in ipairs(cans) do
		local trannum = self.room:getCardTargets(self.player,h):length()
		if h:isKindOf("AOE") or h:isKindOf("GlobalEffect") then
		elseif h:targetFixed() then trannum = 1 end
		if trannum<1 then continue end
	for _, pn in ipairs(patterns()) do
		local dc = dummyCard(pn)
		if dc and self.player:getMark(pn.."kechengchengxian-Clear")<1 and dc:isNDTrick()
		and dc:isDamageCard() and self:getCardsNum(dc:getClassName())<1 then
			dc:setSkillName("kechengchengxian")
				dc:addSubcard(h)
					local orinum = self.room:getCardTargets(self.player,dc):length()
					if dc:isKindOf("AOE") or dc:isKindOf("GlobalEffect") then
					elseif dc:targetFixed() then orinum = 1 end
				if trannum==orinum and dc:isAvailable(self.player) then
						local d = self:aiUseCard(dc)
						if d.card then
							self.kechengchengxianUse = d
							sgs.ai_skill_choice.kechengchengxian = pn
							if dc:canRecast() and d.to:isEmpty() then continue end
							sgs.ai_use_priority.kechengchengxianCard = sgs.ai_use_priority[dc:getClassName()]
							return sgs.Card_Parse("#kechengchengxianCard:"..h:getId()..":")
						end
					end
				end
	end
	for _, pn in ipairs(patterns()) do
		local dc = dummyCard(pn)
		if dc and self.player:getMark(pn.."kechengchengxian-Clear")<1 
		and dc:isNDTrick() and self:getCardsNum(dc:getClassName())<1 then
			dc:setSkillName("kechengchengxian")
				dc:addSubcard(h)
					local orinum = self.room:getCardTargets(self.player,dc):length()
					if dc:isKindOf("AOE") or dc:isKindOf("GlobalEffect") then
					elseif dc:targetFixed() then orinum = 1 end
				if trannum==orinum and dc:isAvailable(self.player) then
						local d = self:aiUseCard(dc)
						if d.card then
							self.kechengchengxianUse = d
							sgs.ai_skill_choice.kechengchengxian = pn
							if dc:canRecast() and d.to:isEmpty() then continue end
							sgs.ai_use_priority.kechengchengxianCard = sgs.ai_use_priority[dc:getClassName()]
							return sgs.Card_Parse("#kechengchengxianCard:"..h:getId()..":")
						end
					end
				end
		end
	end
end

sgs.ai_skill_use_func["#kechengchengxianCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_value.kechengchengxianCard = 8.5
sgs.ai_use_priority.kechengchengxianCard = 6.6

sgs.ai_skill_use["@@kechengchengxian"] = function(self,prompt)
    local dummy = self.kechengchengxianUse
   	if dummy.card and dummy.to then
      	local tos = {}
       	for _,p in sgs.list(dummy.to)do
       		table.insert(tos,p:objectName())
       	end
       	return dummy.card:toString().."->"..table.concat(tos,"+")
    end
end

--二次元

sgs.ai_skill_invoke.kechengneifa = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kechengneifa = function(self, targets)
	targets = sgs.QList2Table(targets)
	local data = self.room:getTag("kechengneifa")
	if sgs.ai_skill_choice.sheyan(self,"remove", data) == "remove" then
		if self.sheyan_remove_target then
			return self.sheyan_remove_target
		end
	end
	return nil
end

sgs.ai_skill_discard.kechengneifa = function(self)
	local to_discard = {}
	local slashnum = 0
	local ndnum = 0
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if c:isKindOf("Slash") then
			slashnum = slashnum + 1
		elseif c:isNDTrick() then
			ndnum = ndnum + 1
		end
	end
	if (slashnum > ndnum) then
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if c:isKindOf("Slash") then
				if (#to_discard == 0) then
				    table.insert(to_discard, c:getEffectiveId())
				end
			end
		end
	elseif (slashnum < ndnum) then
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if c:isNDTrick() then
				if (#to_discard == 0) then
				    table.insert(to_discard, c:getEffectiveId())
				end
			end
		end
	end
	if (#to_discard == 0) then
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if (#to_discard == 0) then
			    table.insert(to_discard, c:getEffectiveId())
			end
		end
	end
	return to_discard
end


sgs.ai_skill_playerschosen.kechengcangchu = function(self, targets,x,n)
	targets = sgs.QList2Table(targets)
	local tos = {}
	self:sort(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and #tos<x then
			table.insert(tos, p)
		end
	end
	return tos
end


sgs.ai_use_revises.kechengshishou = function(self,card,use)
	if card:isKindOf("Analeptic") and self.player:getPhase()==sgs.Player_Play then
		return #self.toUse<2
	end
end


function SmartAI:useCardKCTuixinzhifu(card,use)
	self:sort(self.friends_noself,"hp")
	local extraTarget = sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_ExtraTarget,self.player,card)
	if use.extra_target then extraTarget = extraTarget+use.extra_target end
	for _,ep in sgs.list(self.friends_noself)do
		if isCurrent(use,ep) then continue end
		if CanToCard(card,self.player,ep)
		and self:doDisCard(ep,"ej")
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	self:sort(self.enemies,"hp")
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if CanToCard(card,self.player,ep)
		and self:doDisCard(ep,"ej")
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	for _,ep in sgs.list(self.enemies)do
		if isCurrent(use,ep) then continue end
		if CanToCard(card,self.player,ep)
		and self:doDisCard(ep,"hej")
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
	local tos = self.room:getAlivePlayers()
	tos = self:sort(tos,"card",true)
	for _,ep in sgs.list(tos)do
		if isCurrent(use,ep) then continue end
		if CanToCard(card,self.player,ep)
		and ep:getCardCount()>1
		then
	    	use.card = card
			use.to:append(ep)
	    	if use.to:length()>extraTarget
			then return end
		end
	end
end
sgs.ai_use_priority.KCTuixinzhifu = 5.4
sgs.ai_keep_value.KCTuixinzhifu = 2.2
sgs.ai_use_value.KCTuixinzhifu = 4.7

sgs.ai_skill_cardchosen._kecheng_tuixinzhifu = function(self,who)
	for i,c in sgs.list(who:getCards("ej"))do
		i = c:getEffectiveId()
		if self:doDisCard(who,i,true)
		then return i end
	end
	for i=1,who:getHandcardNum()do
		i = who:getRandomHandCardId()
		if self.disabled_ids:contains(i)
		then continue end
		return i
	end
	for i=1,99 do
		i = self:getCardRandomly(who,"hej")
		if self:doDisCard(who,i,true)
		then return i end
	end
	return -1
end

sgs.ai_skill_discard._kecheng_tuixinzhifu = function(self,x,n)
	local to_cards = {}
	local target = self.player:getTag("_kecheng_tuixinzhifu"):toPlayer()
	local cards = self.player:getHandcards()
	cards = self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if #to_cards>=n then return to_cards end
		if table.contains(self:poisonCards(),h) and not self:isFriend(target)
		then table.insert(to_cards,h:getEffectiveId()) end
	end
   	for i,h in sgs.list(cards)do
   		if #to_cards>=n then return to_cards end
		if table.contains(to_cards,h:getEffectiveId()) then continue end
		if i>=#cards/2 and self:isFriend(target)
		then table.insert(to_cards,h:getEffectiveId()) end
	end
   	for _,h in sgs.list(cards)do
   		if #to_cards>=n then return to_cards end
		if table.contains(to_cards,h:getEffectiveId()) then continue end
       	table.insert(to_cards,h:getEffectiveId())
	end
end

sgs.ai_nullification.KCTuixinzhifu = function(self,trick,from,to,positive)
    local n = self:getCardsNum("Nullification")
	if n>1
	and (to:hasEquip() or to:getJudgingArea():length()>0)
	then
		if positive 
		then
			return self:isFriend(to)
			and self:isEnemy(from)
		else
			return self:isEnemy(to)
			and self:isEnemy(from)
		end
	elseif to:getCardCount(true,true)>0
	and (to:getArmor() or to:getDefensiveHorse() or to:getHandcardNum()<2 or to:getJudgingArea():length()>0)
	then
		if positive 
		then
			return self:isFriend(to)
			and self:isEnemy(from)
		else
			return self:isEnemy(to)
			and self:isEnemy(from)
		end
	end
end





--郭嘉
sgs.ai_skill_playerschosen.kezhuanqingzi = function(self, targets)
	targets = sgs.QList2Table(targets)
	local tos = {}
	for _, p in ipairs(targets) do
		if self:doDisCard(p,"e") then
			table.insert(tos,p)
		end
	end
	return tos
end

sgs.ai_skill_invoke.kezhuandingce = function(self, data)
	local from = data:toPlayer()
	if from==self.player then
		return from:getHandcardNum() >= 4
	elseif self:isFriend(from) then
		return from:getHandcardNum()>from:getHp()
	else
		return true
	end
end

sgs.ai_skill_cardchosen.kezhuandingce = function(self,who)
	local player = self.player
	if who:hasFlag("bestdingcered") then
		for _,c in sgs.qlist(who:getCards("h")) do
			if c:isRed() then
				return c:getId()
			end
		end
	else
		for _,c in sgs.qlist(who:getCards("h")) do
			if c:isBlack() then
				return c:getId()
			end
		end
	end
	return -1
end

local kezhuanzhenfeng={}
kezhuanzhenfeng.name="kezhuanzhenfeng"
table.insert(sgs.ai_skills,kezhuanzhenfeng)
kezhuanzhenfeng.getTurnUseCard = function(self)
	for _,p in sgs.list(zhuanJfNames(self.player))do
		local dc = zhuandummyCard(p)
		dc:setSkillName("kezhuanzhenfeng")
		if dc:isKindOf("Dongzhuxianji") and self.player:hasSkill("kezhuandingce",true)
		and self:isWeak() or not dc:isAvailable(self.player) then continue end
		local dummy = self:aiUseCard(dc)
		if dummy.card and dummy.to then
			self.kezhuanzhenfengData = dummy
			sgs.ai_skill_choice.kezhuanzhenfeng = choice
			if (dummy.to:isEmpty() and dc:canRecast())  then continue end
			sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
			return sgs.Card_Parse("#kezhuanzhenfengCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#kezhuanzhenfengCard"] = function(card,use,self)
   	use.card = card
end

sgs.ai_use_value.kezhuanzhenfengCard = 6.4
sgs.ai_use_priority.kezhuanzhenfengCard = 6.4

sgs.ai_skill_use["@@kezhuanzhenfeng"] = function(self,prompt)
	local dummy = self.kezhuanzhenfengData
	if dummy.card and dummy.to then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return dummy.card:toString().."->"..table.concat(tos,"+")
	end
end


--张任
sgs.ai_skill_askforyiji.kezhuanfuni = function(self,card_ids,tos)
	local to,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if to and id then return to,id end
	for _,p in sgs.list(tos)do
		if not self:isFriend(p)
		and not p:hasFlag("kezhuanfuniAi") then
			p:setFlags("kezhuanfuniAi")
			return p,card_ids[1]
		end
	end
	return tos:first(),card_ids[1]
end

sgs.ai_skill_use["@@kezhuanchuanxin"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
    	local c = zhuandummyCard()
		c:setSkillName("kezhuanchuanxin")
		c:addSubcard(h)
		if self.player:isLocked(c) then continue end
		local dummy = self:aiUseCard(c)
		if dummy.card then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			return c:toString().."->"..table.concat(tos,"+")
			--return "#kezhuanchuanxinCard:"..h:getId()..":->"..table.concat(tos,"+")
		end
	end
end

--马超

sgs.ai_skill_invoke.kezhuanzhuiming = function(self, data)
	local to = data:toPlayer()
	return self:isEnemy(to)
	or not self:isFriend(to) and #self.enemies>0
end

sgs.ai_skill_choice.kezhuanzhuiming = function(self, choices, data)
	local items = choices:split("+")
	local to = data:toPlayer()
	kezhuanzhuimingColor = items[1]
	for _,h in sgs.list(getKnownCards(to,self.player,"he"))do
		if choices:contains(h:getColorString()) then
			kezhuanzhuimingColor = h:getColorString()
			return h:getColorString()
		end
	end
	return items[1]
end


sgs.ai_skill_cardchosen.kezhuanzhuiming = function(self,who)
	for _,h in sgs.list(getKnownCards(who,self.player,"he"))do
		if h:getColorString()==kezhuanzhuimingColor then
			return h:getId()
		end
	end
end

sgs.ai_skill_discard.kezhuanzhuiming = function(self) 
	local to_discard = {}	
	if self.player:getHp()+self:getCardsNum("Peach,Analeptic")<3 then
		local from = self.player:getTag("kezhuanzhuimingFrom"):toPlayer()
		for _,h in sgs.list(getKnownCards(self.player,from,"he"))do
			if h:getColorString()==kezhuanzhuimingColor then
				table.insert(to_discard, h:getEffectiveId())
			end
		end
	end
	return to_discard
end

--张飞

sgs.ai_skill_discard.kezhuanbaohe = function(self) 
	local to_discard = {}
	local who = self.player:getTag("kezhuanbaoheWho"):toPlayer()
	local slash = sgs.Sanguosha:cloneCard("slash")
	slash:setSkillName("kezhuanbaohe")
	slash:deleteLater()
	local x = 0
	for _, pp in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if pp:inMyAttackRange(who) and self.player:canSlash(pp,slash,false) then
			if self:isFriend(pp) then
				x = x-1
				if self:isWeak(pp) then
					x = x-1
				end
			else
				x = x+1
				if self:isEnemy(pp) and self:isWeak(pp) then
					x = x+1
				end
			end
		end	
	end
	if x>1 then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards,nil,"j")
		if #cards<2 then return to_discard end
		table.insert(to_discard, cards[1]:getEffectiveId())
		table.insert(to_discard, cards[2]:getEffectiveId())
	end
	return to_discard
end

local kezhuanxushi_skill = {}
kezhuanxushi_skill.name = "kezhuanxushi"
table.insert(sgs.ai_skills, kezhuanxushi_skill)
kezhuanxushi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kezhuanxushiCard") then return end
	return sgs.Card_Parse("#kezhuanxushiCard:.:")
end

sgs.ai_skill_use_func["#kezhuanxushiCard"] = function(card, use, self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, c in ipairs(self.toUse) do
		table.removeOne(cards, c)
	end
	local ids = {}
	for _,c in ipairs(self:poisonCards(cards))do
		if c:getTypeId()>2 then
			for _,p in ipairs(self.friends_noself)do
				if use.to:contains(p) then continue end
				table.insert(ids, c:getId())
				use.to:append(p)
				break
			end
		else
			for _,p in ipairs(self.enemies)do
				if use.to:contains(p) then continue end
				table.insert(ids, c:getId())
				use.to:append(p)
				break
			end
		end
	end
	if #ids<#self.friends_noself then
		for _,c in ipairs(cards)do
			for _,p in ipairs(self.friends_noself)do
				if use.to:contains(p) or #ids>#cards/2 or table.contains(ids, c:getId()) then continue end
				table.insert(ids, c:getId())
				use.to:append(p)
				break
			end
		end
	end
	if #ids>0 then
		use.card = sgs.Card_Parse("#kezhuanxushiCard:"..table.concat(ids,"+")..":")
	end
end

--夏侯荣

sgs.ai_skill_invoke.kezhuanfenjian = function(self, data)
	local to = data:toPlayer()
	return self:isFriend(to)
end

local kezhuanfenjian_skill = {}
kezhuanfenjian_skill.name = "kezhuanfenjian"
table.insert(sgs.ai_skills, kezhuanfenjian_skill)
kezhuanfenjian_skill.getTurnUseCard = function(self)
	--if self.player:hasUsed("kezhuanfenjianCard") then return end
	local duel = sgs.Sanguosha:cloneCard("duel")
	duel:setSkillName("kezhuanfenjian")
	duel:deleteLater()
	return duel--sgs.Card_Parse("#kezhuanfenjianCard:.:")
end

sgs.ai_skill_use_func["#kezhuanfenjianCard"] = function(card, use, self)
    if not self.player:hasUsed("#kezhuanfenjianCard") then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if enys:isEmpty() then
				enys:append(enemy)
			else
				local yes = 1
				for _,p in sgs.qlist(enys) do
					if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) >= (p:getHp()+p:getHp()+p:getHandcardNum()) then
						yes = 0
					end
				end
				if (yes == 1) then
					enys:removeOne(enys:at(0))
					enys:append(enemy)
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			local yes = 1
			if (self.player:getHp() <= 2) and (self.player:getHandcardNum() < 2) 
			and (enemy:getHp() > 1) and (enemy:getHandcardNum() > 2) then
				yes = 0
			end
			if (self:objectiveLevel(enemy) > 0) and (yes == 1) then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.kezhuanfenjianCard = 8.5
sgs.ai_use_priority.kezhuanfenjianCard = 9.5
sgs.ai_card_intention.kezhuanfenjianCard = 80


local kezhuanguiji_skill = {}
kezhuanguiji_skill.name = "kezhuanguiji"
table.insert(sgs.ai_skills, kezhuanguiji_skill)
kezhuanguiji_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#kezhuanguijiCard") or self.player:getMark("usekezhuanguiji") > 0 then return end
	return sgs.Card_Parse("#kezhuanguijiCard:.:")
end

sgs.ai_skill_use_func["#kezhuanguijiCard"] = function(card, use, self)
    self:sort(self.friends_noself,nil,true)
	local x = self:getCardsNum("Ying")
	for _, p in ipairs(self.friends_noself) do
		if p:getHandcardNum()<self.player:getHandcardNum()
		and p:getHandcardNum()<=self.player:getHandcardNum()-x and p:getHandcardNum()>1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	for _, p in ipairs(self.friends_noself) do
		if p:getHandcardNum()<self.player:getHandcardNum() and p:getHandcardNum()>1 then
			use.card = card
			use.to:append(p)
			return
		end
	end
	self:sort(self.enemies,nil,true)
	for _, p in ipairs(self.enemies) do
		if p:getHandcardNum()<self.player:getHandcardNum() and p:getHandcardNum()>=x then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_skill_invoke.kezhuanguiji = function(self, data)
	local to = data:toPlayer()
	return to:getHandcardNum()>self.player:getHandcardNum()
	or self:isFriend(to) and self:isWeak(to)
end

local kezhuanjiaohaoex = {}
kezhuanjiaohaoex.name = "kezhuanjiaohaoex"
table.insert(sgs.ai_skills, kezhuanjiaohaoex)
kezhuanjiaohaoex.getTurnUseCard = function(self)
	return sgs.Card_Parse("#kezhuanjiaohaoCard:.:")
end

sgs.ai_skill_use_func["#kezhuanjiaohaoCard"] = function(card, use, self)
    self:sort(self.friends_noself)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _, p in ipairs(self.friends_noself) do
		if (#cards>self.player:getHp() or self:isWeak(p)) and p:hasSkill("kezhuanjiaohao") then
			for _, h in ipairs(cards) do
				if h:getTypeId()<3 or #self:poisonCards({h},p)>0 then
					continue
				end
				local equip = h:getRealCard():toEquipCard()
				local equip_index = equip:location()
				if p:getEquip(equip_index) == nil then
					use.card = sgs.Card_Parse("#kezhuanjiaohaoCard:"..h:getId()..":")
					use.to:append(p)
					return
				end
			end
		end
	end
	for _, p in ipairs(self.enemies) do
		if (#cards>=self.player:getHp() or self:isWeak(p)) and p:hasSkill("kezhuanjiaohao") then
			for _, h in ipairs(cards) do
				if h:getTypeId()<3 or #self:poisonCards({h},p)<1 then
					continue
				end
				local equip = h:getRealCard():toEquipCard()
				local equip_index = equip:location()
				if p:getEquip(equip_index) == nil then
					use.card = sgs.Card_Parse("#kezhuanjiaohaoCard:"..h:getId()..":")
					use.to:append(p)
					return
				end
			end
		end
	end
end


--[[local kezhuanjiaohaoex_skill = {}
kezhuanjiaohaoex_skill.name = "kezhuanjiaohaoex"
table.insert(sgs.ai_skills, kezhuanjiaohaoex_skill)
kezhuanjiaohaoex_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kezhuanjiaohaoCard") then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = sgs.IntList()
	for _, acard in ipairs(cards) do
		if acard:isKindOf("EquipCard") then
			to_throw:append(acard:getEffectiveId())
		end
	end
	card_id = to_throw:at(0)
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("#kezhuanjiaohaoCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#kezhuanjiaohaoCard"] = function(card, use, self)
    if (not self.player:hasUsed("#kezhuanjiaohaoCard")) then
		self:sort(self.friends)
		local num = 0
		for _, friend in ipairs(self.friends) do
			if self:isFriend(friend) and (friend:objectName() ~= self.player:objectName()) and ((num <= 1) or (num < self.player:getOverflow())) then
				use.card = card
				if use.to then use.to:append(friend) end
				num = num + 1
			end
		end
		return
	end
end]]



--[[local kezhuanjiaohaoex_skill = {}
kezhuanjiaohaoex_skill.name = "kezhuanjiaohaoex"
table.insert(sgs.ai_skills, kezhuanjiaohaoex_skill)
kezhuanjiaohaoex_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#kezhuanjiaohaoCard") then return end
	local equips = {}
	for _, card in sgs.qlist(self.player:getHandcards()) do
		if card:getTypeId() == sgs.Card_TypeEquip then
			table.insert(equips, card)
		end
	end
	if #equips == 0 then return end
	--return sgs.Card_Parse("#kezhuanjiaohaoCard:.:")
	return sgs.Card_Parse("@kezhuanjiaohaoCard=.")
end

sgs.ai_skill_use_func.kezhuanjiaohaoCard = function(card, use, self)
	if not self.player:hasUsed("#kezhuanjiaohaoCard") then
		local equips = {}
		for _, card in sgs.qlist(self.player:getHandcards()) do
			if card:isKindOf("Armor") or card:isKindOf("Weapon") then
				if not self:getSameEquip(card) then
				elseif card:isKindOf("GudingBlade") and self:getCardsNum("Slash") > 0 then
					local HeavyDamage
					local slash = self:getCard("Slash")
					for _, enemy in ipairs(self.enemies) do
						if self.player:canSlash(enemy, slash, true) and not self:slashProhibit(slash, enemy) and
							self:slashIsEffective(slash, enemy) and not hasJueqingEffect(self.player, enemy) and enemy:isKongcheng() then
								HeavyDamage = true
								break
						end
					end
					if not HeavyDamage then table.insert(equips, card) end
				else
					table.insert(equips, card)
				end
			elseif card:getTypeId() == sgs.Card_TypeEquip then
				table.insert(equips, card)
			end
		end
	
		if #equips == 0 then return end
	
		local select_equip, target
		for _, friend in ipairs(self.friends_noself) do
			for _, equip in ipairs(equips) do
				local index = equip:getRealCard():toEquipCard():location()
				if not friend:hasEquipArea(index) then continue end
				if not self:getSameEquip(equip, friend) and self:hasSkills(sgs.need_equip_skill .. "|" .. sgs.lose_equip_skill, friend) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
			for _, equip in ipairs(equips) do
				local index = equip:getRealCard():toEquipCard():location()
				if not friend:hasEquipArea(index) then continue end
				if not self:getSameEquip(equip, friend) then
					target = friend
					select_equip = equip
					break
				end
			end
			if target then break end
		end
	
		if not target then return end
		if use.to then
			use.to:append(target)
		end
		local kezhuanjiaohaoex = sgs.Card_Parse("@kezhuanjiaohaoCard=" .. select_equip:getId())
		--local kezhuanjiaohaoex = sgs.Card_Parse("#kezhuanjiaohaoCard:".. select_equip:getId())
		use.card = kezhuanjiaohaoex
	end
end

sgs.ai_card_intention.kezhuanjiaohaoCard = -80
sgs.ai_use_priority.kezhuanjiaohaoCard = sgs.ai_use_priority.RendeCard + 0.1  
sgs.ai_cardneed.kezhuanjiaohaoCard = sgs.ai_cardneed.equip]]

--黄忠

local kezhuancuifeng={}
kezhuancuifeng.name="kezhuancuifeng"
table.insert(sgs.ai_skills,kezhuancuifeng)
kezhuancuifeng.getTurnUseCard = function(self)
	local ss = {}
	for _,c in sgs.qlist(self.player:getCards("h")) do
		if table.contains(ss,c:getSuit()) then continue end
		table.insert(ss,c:getSuit())
	end
	if #ss>2 then
		local dc = zhuandummyCard("fire_attack")
		dc:setSkillName("kezhuancuifeng")
		local d = self:aiUseCard(dc)
		if d.card and dc:isAvailable(self.player) then
			for _,to in sgs.list(d.to)do
				if to:isChained() then
					self.kezhuancuifengData = d
					sgs.ai_skill_choice.kezhuancuifeng = "fire_attack"
					sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
					return sgs.Card_Parse("#kezhuancuifengCard:.:")
				end
			end
		end
	end
	for _,pn in sgs.list(patterns())do
		local dc = zhuandummyCard(pn)
		if dc:isDamageCard() and dc:isSingleTargetCard()
		and self:getCardsNum(dc:getClassName())<1 then
			dc:setSkillName("kezhuancuifeng")
			if dc:isAvailable(self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					for _,to in sgs.list(d.to)do
						if self:ajustDamage(self.player,to,1,dc)>1 then
							self.kezhuancuifengData = d
							sgs.ai_skill_choice.kezhuancuifeng = pn
							sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
							return sgs.Card_Parse("#kezhuancuifengCard:.:")
						end
					end
				end
			end
		end
	end
	for _,pn in sgs.list(patterns())do
		local dc = zhuandummyCard(pn)
		if dc:isDamageCard() and dc:isSingleTargetCard()
		and self:getCardsNum(dc:getClassName())<1 then
			dc:setSkillName("kezhuancuifeng")
			if dc:isAvailable(self.player) then
				local d = self:aiUseCard(dc)
				if d.card then
					for _,to in sgs.list(d.to)do
						if to:getHp()<2 and self:isWeak(to) then
							self.kezhuancuifengData = d
							sgs.ai_skill_choice.kezhuancuifeng = pn
							sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
							return sgs.Card_Parse("#kezhuancuifengCard:.:")
						end
					end
				end
			end
		end
	end	
end

sgs.ai_skill_use_func["#kezhuancuifengCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.kezhuancuifengCard = 6.4
sgs.ai_use_priority.kezhuancuifengCard = 6.4

sgs.ai_skill_use["@@kezhuancuifeng"] = function(self,prompt)
	local dummy = self.kezhuancuifengData
	if dummy.card and dummy.to then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return dummy.card:toString().."->"..table.concat(tos,"+")
	end
end

local kezhuandengnan={}
kezhuandengnan.name="kezhuandengnan"
table.insert(sgs.ai_skills,kezhuandengnan)
kezhuandengnan.getTurnUseCard = function(self)
	if self.player:getMark("@kezhuancuifeng")>0 and #self.enemies>1 then
		local dc = zhuandummyCard("iron_chain")
		dc:setSkillName("kezhuandengnan")
		local d = self:aiUseCard(dc)
		if d.card and dc:isAvailable(self.player) then
			local x = 0
			for _,to in sgs.list(d.to)do
				if not to:isChained()
				then x = x+1 end
			end
			if x>1 then
				self.kezhuandengnanData = d
				sgs.ai_skill_choice.kezhuandengnan = "iron_chain"
				sgs.ai_use_priority.kezhuandengnanCard = sgs.ai_use_priority[dc:getClassName()]
				return sgs.Card_Parse("#kezhuandengnanCard:.:")
			end
		end
	end
	local choices = {}
	for _,pn in sgs.list(patterns()) do
		local dc = zhuandummyCard(pn)
		if not dc:isDamageCard() and dc:isNDTrick()
		and self:getCardsNum(dc:getClassName())<1 then
			dc:setSkillName("kezhuandengnan")
			if dc:isAvailable(self.player) then
				table.insert(choices,dc)
			end
		end
	end
	if #choices<1 then return end
	self:getUseValue(choices)
	for _,dc in sgs.list(choices)do
		local dummy = self:aiUseCard(dc)
		if dummy.card then
			local can = dummy.to:length()>0
			for _,to in sgs.list(dummy.to)do
				if to:getMark("&kezhuandengnanda")<1 then
					can = false
					break
				end
			end
			if can then
				self.kezhuandengnanData = dummy
				sgs.ai_skill_choice.kezhuandengnan = dc:objectName()
				sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
				return sgs.Card_Parse("#kezhuandengnanCard:.:")
			end
		end
	end
	if self:isWeak() then
		for _,dc in sgs.list(choices)do
			local dummy = self:aiUseCard(dc)
			if dummy.card then
				self.kezhuandengnanData = dummy
				sgs.ai_skill_choice.kezhuandengnan = dc:objectName()
				if dummy.to:isEmpty() and dc:canRecast() then continue end
				sgs.ai_use_priority.kezhuancuifengCard = sgs.ai_use_priority[dc:getClassName()]
				return sgs.Card_Parse("#kezhuandengnanCard:.:")
			end
		end
	end
end

sgs.ai_skill_use_func["#kezhuandengnanCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.kezhuandengnanCard = 6.4
sgs.ai_use_priority.kezhuandengnanCard = 6.4

sgs.ai_skill_use["@@kezhuandengnan"] = function(self,prompt)
	local dummy = self.kezhuandengnanData
	if dummy.card then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return dummy.card:toString().."->"..table.concat(tos,"+")
	end
end




--娄圭

sgs.ai_skill_playerchosen.kezhuanshacheng = function(self, targets)
	targets = sgs.QList2Table(targets)
    self:sort(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getMark("kezhuanshachenglose-Clear")>1 then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getMark("kezhuanshachenglose-Clear")>0 and self:isWeak(p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.kezhuanshacheng = function(self, data)
	if self.player:hasFlag("wantuseshacheng") then
		return true
	end
end

sgs.ai_skill_invoke.kezhuanninghan = function(self, data)
	return true
end

--张楚
local kezhuanhuozhong={}
kezhuanhuozhong.name="kezhuanhuozhong"
table.insert(sgs.ai_skills,kezhuanhuozhong)
kezhuanhuozhong.getTurnUseCard = function(self)
	return sgs.Card_Parse("#kezhuanhuozhongCard:.:")
end
local kezhuanhuozhongex={}
kezhuanhuozhongex.name="kezhuanhuozhongex"
table.insert(sgs.ai_skills,kezhuanhuozhongex)
kezhuanhuozhongex.getTurnUseCard = function(self)
	return sgs.Card_Parse("#kezhuanhuozhongCard:.:")
end

sgs.ai_skill_use_func["#kezhuanhuozhongCard"] = function(card,use,self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,c in ipairs(self.toUse)do
		table.removeOne(cards,c)
	end
	for _,c in ipairs(cards)do
		if not c:isBlack() or c:getTypeId()==2 then continue end
		local dc = zhuandummyCard("supply_shortage")
		dc:setSkillName("kezhuanhuozhong")
		dc:addSubcard(c)
		if not self.player:containsTrick("supply_shortage") and self.player:hasJudgeArea()
		and not self.player:isProhibited(self.player, dc) then
			for _,p in sgs.list(self.room:findPlayersBySkillName("kezhuanhuozhong"))do
				if self:isFriend(p) and (self:isWeak(p) or #cards>3) then
					use.card = sgs.Card_Parse("#kezhuanhuozhongCard:"..c:getId()..":")
					use.to:append(self.player)
					return
				end
			end
		end
	end
end

sgs.ai_use_value.kezhuanhuozhongCard = 6.4
sgs.ai_use_priority.kezhuanhuozhongCard = 4.4

sgs.ai_skill_playerchosen.kezhuanhuozhong = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			return p
		end
	end
end

sgs.ai_skill_invoke.kezhuanrihui = function(self, data)
	local n = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if p:getJudgingArea():length()>0 then
			if self:isEnemy(p) then
				n = n-1
			else
				n = n+1
			end
		end
	end
	return n>0
end

--夏侯恩

sgs.ai_skill_invoke.kezhuanhujian = function(self, data)
	return true
end

local kezhuanshili_skill={}
kezhuanshili_skill.name="kezhuanshili"
table.insert(sgs.ai_skills,kezhuanshili_skill)
kezhuanshili_skill.getTurnUseCard=function(self)
	if (self.player:getMark("usekezhuanshili-PlayClear") > 0)
	or (self.player:hasFlag("usekezhuanshili")) then return nil end
	local cards = self.player:getCards("h")
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards,true)

	local card
	for _,acard in ipairs(cards)  do
		if (acard:isKindOf("EquipCard")) then
			card = acard
			break
		end
	end

	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("duel:kezhuanshili[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

sgs.weapon_range.Kezhuan_chixueqingfeng = 2
sgs.ai_use_priority.Kezhuan_chixueqingfeng = 3


--庞统

local kezhuanyangming_skill = {}
kezhuanyangming_skill.name = "kezhuanyangming"
table.insert(sgs.ai_skills, kezhuanyangming_skill)
kezhuanyangming_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kezhuanyangmingCard") or (not self.player:canPindian()) then return end
	return sgs.Card_Parse("#kezhuanyangmingCard:.:")
end

sgs.ai_skill_use_func["#kezhuanyangmingCard"] = function(card, use, self)
    if (not self.player:hasUsed("#kezhuanyangmingCard"))
	and (not self.player:isKongcheng()) then
        self:sort(self.enemies)
	    self.enemies = sgs.reverse(self.enemies)
		local enys = sgs.SPlayerList()
		for _, enemy in ipairs(self.enemies) do
			if (self.player:canPindian(enemy, true)) then
				if enys:isEmpty() then
					enys:append(enemy)
				else
					local yes = 1
					for _,p in sgs.qlist(enys) do
						if (enemy:getHp()+enemy:getHp()+enemy:getHandcardNum()) >= (p:getHp()+p:getHp()+p:getHandcardNum()) then
							yes = 0
						end
					end
					if (yes == 1) then
						enys:removeOne(enys:at(0))
						enys:append(enemy)
					end
				end
			end
		end
		for _,enemy in sgs.qlist(enys) do
			if (self:objectiveLevel(enemy) > 0) then
			    use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
		end
	end
end

sgs.ai_use_value.kezhuanyangmingCard = 8.5
sgs.ai_use_priority.kezhuanyangmingCard = 9.5
sgs.ai_card_intention.kezhuanyangmingCard = 80

sgs.ai_skill_invoke.kezhuanyangming = function(self, data)
	return true
end

local kezhuanmanjuan={}
kezhuanmanjuan.name="kezhuanmanjuan"
table.insert(sgs.ai_skills,kezhuanmanjuan)
kezhuanmanjuan.getTurnUseCard = function(self)
	local choices = {}
	for i=0,sgs.Sanguosha:getCardCount()-1 do
		local c = sgs.Sanguosha:getEngineCard(i)
		if self.player:getMark(i.."manjuanPile-Clear")>0
		and self.player:getMark(c:getNumber().."manjuanNumber-Clear")<1
		and c:isAvailable(self.player)
		then table.insert(choices,c) end
	end
	if #choices<1 then return end
	self:getUseValue(choices)
	for _,dc in sgs.list(choices)do
		local dummy = self:aiUseCard(dc)
		if dummy.card then
			self.kezhuanmanjuanData = dummy
			if dummy.to:isEmpty() and dc:canRecast() then continue end
			sgs.ai_use_priority.kezhuanmanjuanCard = sgs.ai_use_priority[dc:getClassName()]
			return sgs.Card_Parse("#kezhuanmanjuanCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#kezhuanmanjuanCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.kezhuanmanjuanCard = 6.4
sgs.ai_use_priority.kezhuanmanjuanCard = 6.4

sgs.ai_skill_use["@@kezhuanmanjuan"] = function(self,prompt)
	local dummy = self.kezhuanmanjuanData
	if dummy.card then
	    local tos = {}
		for _,p in sgs.list(dummy.to)do
			table.insert(tos,p:objectName())
		end
		return "#kezhuanmanjuanVsCard:.:@@kezhuanmanjuan->"..table.concat(tos,"+")
	end
end

function sgs.ai_cardsview.kezhuanmanjuan(self,class_name,player)
	if self.player:isKongcheng() then
		for i=0,sgs.Sanguosha:getCardCount()-1 do
			local c = sgs.Sanguosha:getCard(i)
			if player:getMark(i.."manjuanPile-Clear")>0
			and player:getMark(c:getNumber().."manjuanNumber-Clear")<1
			and not player:isLocked(c) and c:isKindOf(class_name)
			then return "#kezhuanmanjuanVsCard:.:"..c:objectName() end
		end
	end
end


--范疆张达

sgs.ai_skill_discard.kezhuanfushan = function(self, discard_num, min_num, optional, include_equip) 
	if not (self.player:hasFlag("wantusefushan")) then
		return self:askForDiscard("dummyreason", discard_num, discard_num, true, true)
	else
		local to_discard = {}
		local yes = 0
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if (c:isKindOf("Slash")) then
				table.insert(to_discard, c:getEffectiveId())
				yes = 1
				break
			end
		end
		if yes == 1 then
			return to_discard
		else
			return self:askForDiscard("dummyreason", discard_num, discard_num, true, true)
		end
	end
end

sgs.ai_skill_use["@@kezhuanniluan"] = function(self,prompt)
	self:sort(self.enemies)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards,nil,"j")
	for _,p in sgs.list(self.enemies)do
		if #cards>0 and p:getMark("kezhuanniluan"..self.player:objectName())<1 and self:isWeak(p) then
			return "#kezhuanniluanCard:"..cards[1]:getId()..":->"..p:objectName()
		end
	end
	self:sort(self.friends)
	for _,p in sgs.list(self.friends)do
		if p:getMark("kezhuanniluan"..self.player:objectName())>0 and self:isWeak(p) then
			return "#kezhuanniluanCard:.:->"..p:objectName()
		end
	end
	for _,p in sgs.list(self.friends)do
		if p:getMark("kezhuanniluan"..self.player:objectName())>0 then
			return "#kezhuanniluanCard:.:->"..p:objectName()
		end
	end
	for _,p in sgs.list(self.friends)do
		if #cards>1 and p:getMark("kezhuanniluan"..self.player:objectName())<1 and not self:isWeak(p) then
			return "#kezhuanniluanCard:"..cards[1]:getId()..":->"..p:objectName()
		end
	end
end





sgs.ai_skill_use["@@kehexumouuse"] = function(self, prompt)
	local id = self.player:getTag("kehexumouForAI"):toIntList():first()
	local card = sgs.Sanguosha:getEngineCard(id)
	local d = self:aiUseCard(card)
	if d.card then
		local targets = {}
		for _, p in sgs.qlist(d.to)do
			table.insert(targets, p:objectName())
		end
		if card:canRecast() and #targets<1 then return "." end
		return id.."->"..table.concat(targets, "+")
	end
	return "."
end

--郭循

sgs.ai_skill_choice.keheeqian = function(self, choices, data)
	return "add"
end

sgs.ai_skill_invoke.keheeqian = function(self, data)
	local to = data:toPlayer()
	return self:isEnemy(to) or not self:isFriend(to) and #self.enemies<1
end

sgs.ai_skill_discard.keheeqian = function(self) 
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local cns = {}
	for _,c in sgs.qlist(self.player:getCards("j"))do
		if string.find(c:objectName(),"kehexumou")
		then table.insert(cns, sgs.Sanguosha:getEngineCard(c:getEffectiveId()):objectName()) end
	end
	for _, c in ipairs(cards)do 
		if not table.contains(cns, c:objectName()) and c:isAvailable(self.player) then
			return {c:getEffectiveId()}
		end
	end
	if #cns>0 then return {} end
	return self:askForDiscard("dummyreason", 1, 1, true, true)
end

local kehefusha_skill = {}
kehefusha_skill.name = "kehefusha"
table.insert(sgs.ai_skills, kehefusha_skill)
kehefusha_skill.getTurnUseCard = function(self)
	if (self.player:getMark("@kehefusha") <= 0) then return end
	return sgs.Card_Parse("#kehefushaCard:.:")
end

sgs.ai_skill_use_func["#kehefushaCard"] = function(card, use, self)
	self:sort(self.enemies)
	local n = math.min(self.player:getAttackRange(),self.room:getPlayers():length())
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) and enemy:getHp()<=n and (#self.enemies<2 or enemy:getHp()>1)
		and self:damageIsEffective(enemy,"N",self.player) then
			use.card = card
			use.to:append(enemy)
			break
		end
	end
end

sgs.ai_use_value.kehefushaCard = 8.5
sgs.ai_use_priority.kehefushaCard = 3.5
sgs.ai_card_intention.kehefushaCard = 80



--诸葛亮

sgs.ai_skill_invoke.kehewentian = function(self, data)
	if self.player:getMark("@usekehewentian")<2 and #self.friends_noself<1
	then return end
	if self.player:getPhase()==sgs.Player_Judge then
		return self.player:getJudgingArea():length()>0
	end
	return self.player:getPhase()>=sgs.Player_Play
	and #self.friends_noself>0
end

sgs.ai_skill_playerchosen.kehewentian = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = sgs.SPlayerList()
	local theweaktwo = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if self:isFriend(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if (qq:getRole() == "lord") then
			for _,oo in sgs.qlist(theweak) do
				theweaktwo:removeOne(oo)
			end
			theweaktwo:append(qq)
			break
		end
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	--[[for _,zg in sgs.qlist(self.player:getAliveSiblings()) do
		if self:isFriend(zg) and (zg:getRole() == "lord") then
			return zg
		end
	end]]
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end


local kehewentian_skill={}
kehewentian_skill.name="kehewentian"
table.insert(sgs.ai_skills,kehewentian_skill)
kehewentian_skill.getTurnUseCard=function(self)
	local id = self.player:getMark("kehewentianId")
	local dc = dummyCard("fire_attack")
	dc:addSubcard(id)
	dc:setSkillName("kehewentian")
	if not dc:isAvailable(self.player) then return end
	if self.player:getMark("usedkehewentian-Clear")>0 and sgs.Sanguosha:getCard(id):isRed() then
		return dc
	end
	local d = self:aiUseCard(dc)
	if d.card then
		for _,p in sgs.qlist(d.to) do
			if (self:isEnemy(p) or p:isChained()) and self:isWeak(p)  then
				return dc
			end
		end
	end
end

--[[sgs.ai_view_as.kehewentian = function(card, player, card_place)
	local pdcard = sgs.Sanguosha:getCard(player:getMark("kehewentianId"))
	local suit = pdcard:getSuitString()
	local number = pdcard:getNumberString()
	local card_id = player:getMark("kehewentianId")
	if (pdcard:isBlack() or (math.random(1,10) >=7)) and (player:getMark("&bankehewentian_lun") == 0) then
		return ("nullification:kehewentian[%s:%s]=%d"):format(suit, number, card_id)
	end	
end]]

function sgs.ai_cardsview.kehewentian(self, class_name, player)
	if class_name == "Nullification" then
		local id = player:getMark("kehewentianId")
		local dc = dummyCard("nullification")
		dc:addSubcard(id)
		dc:setSkillName("kehewentian")
		if self.player:getMark("usedkehewentian-Clear")>0 then
			return sgs.Sanguosha:getCard(id):isBlack() and dc
		end
		return dc:toString()
	end
end

sgs.ai_skill_discard.keheyinlue = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local cards = self.player:getCards("he")
	local to = self.player:getTag("keheyinlueTo"):toPlayer()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if self:isFriend(to) then
	    table.insert(to_discard, cards[1]:getEffectiveId())
		return to_discard
	elseif not self:isEnemy(to) then
	    return self:askForDiscard("dummyreason", 1, 1, true, true)
	end
	return {}
end

local kehechushi_skill = {}
kehechushi_skill.name = "kehechushi"
table.insert(sgs.ai_skills, kehechushi_skill)
kehechushi_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehechushiCard") then return end
	return sgs.Card_Parse("#kehechushiCard:.:")
end

sgs.ai_skill_use_func["#kehechushiCard"] = function(card, use, self)
    if not self.player:hasUsed("#kehechushiCard") then
        use.card = card
	    return
	end
end

sgs.ai_skill_invoke.keheyinlue = function(self, data)
	if self.player:hasFlag("wantuseyinlue") then
	    return true
	end
end

sgs.ai_skill_discard.kehechushi = function(self)
	local to_discard = {}
	table.insert(to_discard, self.player:getCards("h"):last():getId())
	return to_discard
end

sgs.ai_use_value.kehechushiCard = 8.5
sgs.ai_use_priority.kehechushiCard = 7.5

--二虎

sgs.ai_skill_invoke.kehedaimou = function(self, data)
	return true
end

sgs.ai_skill_invoke.kehefangjie = function(self, data)
	local hasxm,nouse,cns = 0,0,{}
	for _,c in sgs.qlist(self.player:getJudgingArea()) do
		if string.find(c:objectName(),"kehexumou") then
			local ec = sgs.Sanguosha:getEngineCard(c:getEffectiveId())
			if table.contains(cns, ec:objectName()) then nouse = nouse+1 break end
			table.insert(cns, ec:objectName())
			if ec:isAvailable(self.player) then
				local d = self:aiUseCard(ec)
				if d.card then
					hasxm = hasxm+1
				else
					nouse = nouse+1
				end
			else
				nouse = nouse+1
			end
		end
	end
	return hasxm>nouse and nouse>1
end

sgs.ai_skill_cardchosen.kehefangjie = function(self,who,flags,method)
	local cns = {}
	for _,c in sgs.qlist(self.player:getJudgingArea()) do
		if string.find(c:objectName(),"kehexumou") then
			local id = c:getEffectiveId()
			if self.disabled_ids:contains(id) then continue end
			local ec = sgs.Sanguosha:getEngineCard(id)
			if table.contains(cns, ec:objectName()) then return id end
			table.insert(cns, ec:objectName())
			if ec:isAvailable(self.player) then
				local d = self:aiUseCard(ec)
				if d.card then
					
				else
					return id
				end
			else
				return id
			end
		end
	end
end

--卫温诸葛直

local kehefuhai_skill = {}
kehefuhai_skill.name = "kehefuhai"
table.insert(sgs.ai_skills, kehefuhai_skill)
kehefuhai_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehefuhaiCard") then return end
	return sgs.Card_Parse("#kehefuhaiCard:.:")
end

sgs.ai_skill_use_func["#kehefuhaiCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_value.kehefuhaiCard = 8.5
sgs.ai_use_priority.kehefuhaiCard = 9.5
sgs.ai_card_intention.kehefuhaiCard = 33

--郭照

sgs.ai_skill_invoke.kehepianchong = function(self, data)
	return true
end

--姜维

local kehejinfa_skill = {}
kehejinfa_skill.name = "kehejinfa"
table.insert(sgs.ai_skills, kehejinfa_skill)
kehejinfa_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehejinfaCard") then return end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if #cards>0 then
		return sgs.Card_Parse("#kehejinfaCard:"..cards[1]:getId()..":")
	end
end

sgs.ai_skill_use_func["#kehejinfaCard"] = function(card, use, self)
    use.card = card
	kehejinfaColor = card:getColor()
end

function sgs.ai_cardneed.kehejinfaCard(to, card, self)
	if self.player:hasUsed("#kehejinfaCard") then return false end
	return true
end

sgs.ai_use_value.kehejinfaCard = 8.5
sgs.ai_use_priority.kehejinfaCard = 9.5
sgs.ai_card_intention.kehejinfaCard = 80

sgs.ai_skill_playerschosen.kehejinfa = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if self:isFriend(target) then
            selected:append(target)
			if selected:length()>=max then break end
        end
    end
    return selected
end

sgs.ai_skill_choice.kehejinfa = function(self, choices)
	local items = choices:split("+")
	--[[if (self.player:getKingdom() == "shu") then
	    return "wei"
	else]]
		return "shu"
	--end
end

sgs.ai_skill_discard.kehejinfa = function(self)
	local from = self.room:getTag("kehejinfaFrom"):toPlayer()
	if self:isFriend(from) then
		for _,c in sgs.qlist(self.player:getCards("h")) do
			if (c:getColor()==kehejinfaColor) then
				return {c:getId()}
			end
		end
	end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	return {cards[1]:getId()}
end

sgs.ai_skill_use["@@kehefumou"] = function(self,prompt)
    local cards = self.player:getCards("he")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	for _,h in sgs.list(cards)do
    	local c = dummyCard("chuqibuyi")
		c:setSkillName("kehefumou")
		c:addSubcard(h)
		if self.player:isLocked(c) or not c:isKindOf("Ying") then continue end
		local dummy = self:aiUseCard(c)
		if dummy.card then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			return c:toString().."->"..table.concat(tos,"+")
		end
	end
end

sgs.ai_view_as.kehexuanfeng = function(card, player, card_place)
	if (player:getKingdom() == "shu") and card_place ~= sgs.Player_PlaceSpecial and card:isKindOf("Ying") then
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		return ("yj_stabs_slash:kehexuanfeng[%s:%s]=%d"):format(suit, number, card_id)
	end
end

local kehexuanfeng_skill = {}
kehexuanfeng_skill.name = "kehexuanfeng"
table.insert(sgs.ai_skills, kehexuanfeng_skill)
kehexuanfeng_skill.getTurnUseCard = function(self, inclusive)
	if (self.player:getKingdom() ~= "shu") then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	for _, card in ipairs(cards) do
		if card:isKindOf("Ying") then
			local dc = dummyCard("yj_stabs_slash")
			dc:setSkillName("kehexuanfeng")
			dc:addSubcard(card)
			return dc
		end
	end
end

function sgs.ai_cardneed.kehexuanfeng(to, card)
	return card:isKindOf("Ying") 
end


--赵云
sgs.ai_skill_invoke.kehelonglinjuedou = function(self, data)
	local from = data:toPlayer()
	return self:isEnemy(from)
end

sgs.ai_skill_discard.kehelonglin = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards,nil,"j")
	local use = self.player:getTag("kehelonglinData"):toCardUse()
	if self:isFriend(use.to:first()) then
	    if not self:isFriend(use.from) then
			table.insert(to_discard, cards[1]:getEffectiveId())
		end
	elseif not self:isEnemy(use.to:first()) then
	    to_discard = self:askForDiscard("dummyreason", 1, 1, true, true)
	end
	return to_discard
end

local kehezhendan_skill = {}
kehezhendan_skill.name = "kehezhendan"
table.insert(sgs.ai_skills, kehezhendan_skill)
kehezhendan_skill.getTurnUseCard = function(self, inclusive)
	local handcards = self:addHandPile("h")
	self:sortByUseValue(handcards, true)
	for _, pn in ipairs(patterns())do
		local dc = dummyCard(pn)
		dc:setSkillName("kehezhendan")
		if dc:getTypeId()==1 then
			for _, h in ipairs(handcards)do
				if h:getTypeId()>1 and self:getUseValue(h)<self:getUseValue(dc) then
					dc:addSubcard(h)
					if dc:isAvailable(self.player) then
						local d = self:aiUseCard(dc)
						if d.card then
							return dc
						end
					end
					dc:clearSubcards()
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#kehezhendan"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local kehezhendancard = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	kehezhendancard:setSkillName("kehezhendan")
	self:useBasicCard(kehezhendancard, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["kehezhendan"] = 3
sgs.ai_use_value["kehezhendan"] = 3

function sgs.ai_cardsview.kehezhendan(self,class_name,player)
	local handcards = self:addHandPile("h")
	self:sortByKeepValue(handcards)
	for _, h in ipairs(handcards)do
		if h:getTypeId()>1 then
			local dc = dummyCard(class_name)
			dc:setSkillName("kehezhendan")
			dc:addSubcard(h)
			return dc:toString()
		end
	end
end

function sgs.ai_cardneed.kehezhendan(to, card, self)
	return (not card:isKindOf("BasicCard")) and (not card:isEquipped())
end


--司马懿

sgs.ai_skill_invoke.keheyingshi = function(self, data)
	return true
end

sgs.ai_skill_invoke.kehetuigu = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kehetuigu = function(self, targets)
	if self:isWeak() and (self.player:getEquipsId():length() > 0) then
		return self.player
	end
	targets = sgs.QList2Table(targets)
	local theweak = sgs.SPlayerList()
	local theweaktwo = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getEquips():length() > qq:getEquips():length()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:removeOne(theweaktwo:at(0))
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end

sgs.ai_skill_use["@@kehetuigu"] = function(self,prompt)
	local dc = dummyCard("zl_jiejiaguitian")
	dc:setSkillName("kehetuigu")
	if dc:isAvailable(self.player) then
		local dummy = self:aiUseCard(dc)
		if dummy.card and dummy.to then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			return dc:toString().."->"..table.concat(tos,"+")
		end
	end
end


--曹芳
local kehezhaotu_skill={}
kehezhaotu_skill.name="kehezhaotu"
table.insert(sgs.ai_skills,kehezhaotu_skill)
kehezhaotu_skill.getTurnUseCard=function(self,inclusive)
	if (self.player:getMark("kehezhaotuuse_lun") ~= 0) then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	self:sortByUseValue(cards,true)

	local has_weapon, has_armor = false, false

	for _,acard in ipairs(cards)  do
		if acard:isKindOf("Armor") then has_armor=true end
		if acard:isKindOf("Weapon") then has_weapon=true end
	end

	for _,acard in ipairs(cards)  do
		if acard:isRed() and acard:getTypeId()~=2 and (inclusive or self:getUseValue(acard)<sgs.ai_use_value.Indulgence) then
			if acard:isKindOf("Armor") then
				if not self.player:getArmor() then continue
				elseif self.player:hasEquip(acard) and not has_armor and self:evaluateArmor()>0
				then continue end
			end
			if acard:isKindOf("Weapon") then
				if not self.player:getWeapon() then continue
				elseif self.player:hasEquip(acard) and not has_weapon
				then continue end
			end
			local dc = dummyCard("indulgence")
			dc:setSkillName("kehezhaotu")
			dc:addSubcard(acard)
			return dc
		end
	end
end

function sgs.ai_cardneed.kehezhaotu(to, card)
	return card:isRed() and (not card:isKindOf("TrickCard"))
end

local kehejingju_skill={}
kehejingju_skill.name="kehejingju"
table.insert(sgs.ai_skills,kehejingju_skill)
kehejingju_skill.getTurnUseCard = function(self)
	for _,p in sgs.list(self.player:getAliveSiblings())do
		for _,j in sgs.list(p:getJudgingArea())do
			if self.player:containsTrick(j:objectName())
			or self:isEnemy(p) then continue end
			return sgs.Card_Parse("#kehejingjuCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#kehejingjuCard"] = function(card,use,self)
	for _,p in sgs.list(patterns())do
		local dc = dummyCard(p)
		if dc and dc:getTypeId()==1 then
			if self:getCardsNum(dc:getClassName())>0 then continue end
			dc:setSkillName("kehejingju")
			if dc:isAvailable(self.player) then
				local dummy = self:aiUseCard(dc)
				if dummy.card then
					use.card = sgs.Card_Parse("#kehejingjuCard:.:"..dc:objectName())
					if use.to then use.to = dummy.to end
					break
				end
			end
		end
	end
end

sgs.ai_use_value.kehejingjuCard = 4.4
sgs.ai_use_priority.kehejingjuCard = 3

function sgs.ai_cardsview.kehejingju(self,class_name,player)
	if sgs.Sanguosha:getCurrentCardUseReason()~=sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE
	then return end
	for _,h in sgs.list(player:getHandcards())do
		if h:isKindOf(class_name) then
			return
		end
	end
	local dc = dummyCard(class_name)
	if dc and dc:getTypeId()==1 then
		for _,p in sgs.list(player:getAliveSiblings())do
			for _,j in sgs.list(p:getJudgingArea())do
				if player:containsTrick(j:objectName()) then continue end
				return ("#kehejingjuCard:.:"..dc:objectName())
			end
		end
	end
end

sgs.ai_skill_playerchosen.kehejingju = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"card")
    for _,target in sgs.list(destlist)do
		if self:isFriend(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isEnemy(target)
		then return target end
	end
	return destlist[1]
end

sgs.ai_skill_discard.keheweizhui = function(self, discard_num, min_num, optional, include_equip) 
	local to_discard = {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local from = self.player:getTag("keheweizhuiFrom"):toPlayer()
	if self:doDisCard(from,"hej") then
		if cards[1]:isBlack() then
			table.insert(to_discard, cards[1]:getEffectiveId())
			return to_discard
		end
	end
	return self:askForDiscard("dummyreason", 1, 1, true, true)
end

--陆逊

sgs.ai_skill_playerchosen.keheyoujin = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and p:getHandcardNum()<self.player:getHandcardNum() then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and self:isWeak(p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and not self:isWeak() then
			return p
		end
	end
end


local kehedailao_skill = {}
kehedailao_skill.name = "kehedailao"
table.insert(sgs.ai_skills, kehedailao_skill)
kehedailao_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehedailaoCard") then return end
	for _,c in sgs.qlist(self.player:getHandcards()) do
		if c:isAvailable(self.player) then
			return
		end
	end
	return sgs.Card_Parse("#kehedailaoCard:.:")
end

sgs.ai_skill_use_func["#kehedailaoCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value.kehedailaoCard = 8.5
sgs.ai_use_priority.kehedailaoCard = 9.5
sgs.ai_card_intention.kehedailaoCard = 80

--孙峻

sgs.ai_skill_invoke.keheyaoyan = function(self, data)
	return true
end

sgs.ai_skill_choice.keheyaoyan = function(self, choices, data)
	local sj = self.room:getCurrent()
	if (self.player == sj) then
		return "join"
	else
		if self:isFriend(sj) then
			if math.random(0,5) > 1 then
				return "join"
			end
		else
			if math.random(0,2)>1 then
				return "join"
			end
		end
	end
	return "notjoin"
end

sgs.ai_skill_playerschosen.keheyaoyan = function(self, targets, max, min)
    local selected = sgs.SPlayerList()
    local can_choose = sgs.QList2Table(targets)
    self:sort(can_choose, "defense")
    for _,target in ipairs(can_choose) do
        if self:isEnemy(target)
		or self:getOverflow(target) > 1 then
            selected:append(target)
            if selected:length()>=max then break end
        end
    end
    return selected
end

sgs.ai_skill_playerchosen.keheyaoyan = function(self, targets)
	targets = sgs.QList2Table(targets)
	local theweak = sgs.SPlayerList()
	local theweaktwo = sgs.SPlayerList()
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
			theweak:append(p)
		end
	end
	for _,qq in sgs.qlist(theweak) do
		if theweaktwo:isEmpty() then
			theweaktwo:append(qq)
		else
			local inin = 1
			for _,pp in sgs.qlist(theweaktwo) do
				if (pp:getHp() < qq:getHp()) then
					inin = 0
				end
			end
			if (inin == 1) then
				theweaktwo:append(qq)
			end
		end
	end
	if theweaktwo:length() > 0 then
	    return theweaktwo:at(0)
	end
	return nil
end

local kehechiying_skill = {}
kehechiying_skill.name = "kehechiying"
table.insert(sgs.ai_skills, kehechiying_skill)
kehechiying_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kehechiyingCard") then return end
	return sgs.Card_Parse("#kehechiyingCard:.:")
end

sgs.ai_skill_use_func["#kehechiyingCard"] = function(card, use, self)
	self:sort(self.friends)
	for _, friend in ipairs(self.friends) do
		use.card = card
		if use.to then use.to:append(friend) end
		break
	end
end

sgs.ai_use_value.kehechiyingCard = 8.5
sgs.ai_use_priority.kehechiyingCard = 9.5
sgs.ai_card_intention.kehechiyingCard = 80

--[[sgs.ai_skill_use_func["#kehechiyingCard"] = function(card, use, self)
	if not self.player:hasUsed("#kehechiyingCard") then
		self:updatePlayers()
		local room = self.room
		local can_dis = 0
		local target = nil
	
		for _,friend in ipairs(self.friends) do
			if friend:getHp() <= self.player:getHp() then
				local dis = 0
				for _,other in sgs.qlist(room:getOtherPlayers(friend)) do
					if friend:inMyAttackRange(other) and other:objectName() ~= self.player:objectName() then
						if not self:isFriend(other) then
							if friend:objectName() == self.player:objectName() then
								dis = dis + 1
							else
								dis = dis + 1.5
							end
						end
					end
				end
				if dis > can_dis then
					target = friend
					can_dis = dis
				end
			end
		end
	
		if not target then return end
		if target then
			local card_str = "#kehechiying:.:->"..target:objectName()
			local acard = sgs.Card_Parse(card_str)
			assert(acard)
			use.card = acard
			if use.to then
				use.to:append(target)
			end
		end
	end
end

sgs.ai_use_priority.kehechiying = 6]]


local kehedanxin = {}
kehedanxin.name = "kehedanxin"
table.insert(sgs.ai_skills, kehedanxin)
kehedanxin.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)

	self:sortByUseValue(cards,true)
	if #cards<1 then return end
	local acard = sgs.Sanguosha:cloneCard("yj_tuixinzhifu")
	acard:setSkillName("kehedanxin")
	acard:addSubcard(cards[1])
	acard:deleteLater()
	return acard
end

sgs.ai_skill_playerchosen.kehefengxiang = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) and p:getEquips():length()>=self.player:getEquips():length() then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if self:isFriend(p) and p:getEquips():length()>0 and self.player:getEquips():length()>0 then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if p:getEquips():length()>0 then
			return p
		end
	end
end








sgs.ai_skill_invoke.keshuaizhimeng = function(self,data)
	return true
end

sgs.ai_skill_invoke.keshuaitianyu = function(self,data)
	return true
end

sgs.ai_fill_skill.keshuaizhuni = function(self)
    return sgs.Card_Parse("#keshuaizhuniCard:.:")
end

sgs.ai_skill_use_func["#keshuaizhuniCard"] = function(card,use,self)
	use.card = card
end

sgs.ai_use_value.keshuaizhuniCard = 3.4
sgs.ai_use_priority.keshuaizhuniCard = 8.2

sgs.ai_skill_playerchosen.keshuaizhuni = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		then return target end
	end
end

sgs.ai_skill_discard.keshuaixiangru = function(self,max,min,optional)
	local to_cards = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
   	for _,hcard in sgs.list(cards)do
   		if #to_cards>=min then break end
     	table.insert(to_cards,hcard:getEffectiveId())
	end
	local to = self.player:getTag("keshuaixiangruTo"):toPlayer()
	if self:isFriend(to) then return to_cards end
	return {}
end

sgs.ai_skill_playerchosen.keshuaijinglei = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard",true)
    for _,target in sgs.list(destlist)do
		if self:isEnemy(target)
		then return target end
	end
    for _,target in sgs.list(destlist)do
		if not self:isFriend(target)
		and #self.enemies<1
		then return target end
	end
end

sgs.ai_skill_use["@@keshuaijinglei"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAlivePlayers()
    destlist = self:sort(destlist,"handcard")
	local n = 0
	for _,to in sgs.list(destlist)do
		if n+to:getHandcardNum()<self.player:getMark("keshuaijinglei") then
			table.insert(valid,to:objectName())
			n = n+to:getHandcardNum()
		end
	end
	if #valid>1 then
    	return string.format("#keshuaijingleiCard:.:->%s",table.concat(valid,"+"))
	end
end

sgs.ai_skill_playerschosen.keshuaiyansha = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:isWeak(p)
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and not self:isWeak(p) and #destlist/2>#tos
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and #self.friends>1
		and not table.contains(tos,p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_use["@@keshuaiyansha"] = function(self,prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
   	for _,c in sgs.list(cards)do
		if c:getTypeId()<3 then continue end
		local dc = dummyCard()
		dc:setSkillName("_keshuaiyansha")
		dc:addSubcard(c)
		if not dc:isAvailable(self.player) then continue end
		local dummy = self:aiUseCard(dc)
		if dummy.card and dummy.to then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			return dc:toString().."->"..table.concat(tos,"+")
		end
	end
end

sgs.ai_skill_playerchosen.keshuaizhushou = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		and #self.enemies<1
		then return p end
	end
end

local keshuaiyanggeex={}
keshuaiyanggeex.name="keshuaiyanggeex"
table.insert(sgs.ai_skills,keshuaiyanggeex)
keshuaiyanggeex.getTurnUseCard = function(self)
    return sgs.Card_Parse("#keshuaiyanggeCard:.:")
end

sgs.ai_skill_use_func["#keshuaiyanggeCard"] = function(card,use,self)
	local dc = sgs.Card_Parse("@MizhaoCard=.")
	local d = self:aiUseCard(dc)
	if d.card then
		for _,p in sgs.list(d.to)do
			if p:hasSkill("keshuaiyangge") then
				use.card = card
				use.to:append(p)
				return
			end
		end
	end
	if #self.toUse<2 then
		for _,p in sgs.list(self.friends_noself)do
			if not p:hasSkill("keshuaiyangge") then continue end
			for _,e in sgs.list(self.enemies)do
				if self:slashIsEffective(dummyCard(),e,p) then
					use.card = card
					use.to:append(p)
					return
				end
			end
		end
		if self.player:getHandcardNum()/2<=#self:poisonCards("h") then
			for _,p in sgs.list(self.enemies)do
				if not p:hasSkill("keshuaiyangge") then continue end
				for _,e in sgs.list(self.enemies)do
					if p~=e and self:slashIsEffective(dummyCard(),e,p) then
						use.card = card
						use.to:append(p)
						return
					end
				end
			end
		end
		if self.player:getHandcardNum()<2 then
			for _,p in sgs.list(self.enemies)do
				if not p:hasSkill("keshuaiyangge") then continue end
				for _,e in sgs.list(self.enemies)do
					if p~=e and self:slashIsEffective(dummyCard(),e,p) then
						use.card = card
						use.to:append(p)
						return
					end
				end
			end
		end
	end
end

sgs.ai_use_value.keshuaiyanggeCard = 6.4
sgs.ai_use_priority.keshuaiyanggeCard = 1.4

local keshuaisaojian={}
keshuaisaojian.name="keshuaisaojian"
table.insert(sgs.ai_skills,keshuaisaojian)
keshuaisaojian.getTurnUseCard = function(self)
	return sgs.Card_Parse("#keshuaisaojianCard:.:")
end

sgs.ai_skill_use_func["#keshuaisaojianCard"] = function(card,use,self)
	self:sort(self.enemies,"handcard",true)
	for _,to in sgs.list(self.enemies)do
     	if to:getHandcardNum()>0 then
			use.card = card
			use.to:append(to)
			break
		end
   	end
end

sgs.ai_use_value.keshuaisaojianCard = 6.4
sgs.ai_use_priority.keshuaisaojianCard = 8.4

local keshuaiguanshi={}
keshuaiguanshi.name="keshuaiguanshi"
table.insert(sgs.ai_skills,keshuaiguanshi)
keshuaiguanshi.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
   	for _,h in sgs.list(cards)do
   		if h:isKindOf("Slash") then
			local dc = dummyCard("FireAttack")
			dc:setSkillName("keshuaiguanshi")
			dc:addSubcard(h)
			if dc:isAvailable(self.player) then
				return dc
			end
		end
	end
end

sgs.ai_skill_invoke.keshuaicangxiong = function(self,data)
	local id = self.player:getTag("keshuaicangxiongId"):toInt()
	local to = self.room:getCardOwner(id)
	return not(to and self:isFriend(to))
	and (not self.player:hasSkill("keshuaibaowei",true) or sgs.Sanguosha:getCard(id):isAvailable(self.player))
end

sgs.ai_use_revises.keshuaibaowei = function(self,card,use)
	local n = 0
	local to = nil
	for _, dmd in sgs.qlist(self.room:getOtherPlayers(self.player)) do   
		if dmd:getMark("&keshuaibaowei-Clear")>0 then
			n = n+1
			to = dmd
		end
	end
	if n==1 and self:isEnemy(to) then
		if card:getTypeId()==3 or card:getTypeId()==0
		then return end
		if card:getTypeId()==1 and card:targetFixed()
		then return end
		return false
	end
end

sgs.ai_skill_playerschosen.keshuairuzong = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) or not self:isEnemy(p) and #self.enemies>0
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_invoke.keshuairuzong = function(self,data)
	return true
end

local keshuaidaoren={}
keshuaidaoren.name="keshuaidaoren"
table.insert(sgs.ai_skills,keshuaidaoren)
keshuaidaoren.getTurnUseCard = function(self)
    local cards = self.player:getCards("h")
    cards = sgs.QList2Table(cards) -- 将列表转换为表
    self:sortByKeepValue(cards) -- 按保留值排序
	if #cards<2 then return end
	for _,h in sgs.list(cards)do
		return sgs.Card_Parse("#keshuaidaorenCard:"..h:getId()..":")
	end
end

sgs.ai_skill_use_func["#keshuaidaorenCard"] = function(card,use,self)
	local destlist = sgs.QList2Table(self.room:getOtherPlayers(self.player))
	self:sort(destlist)
	for _,p in sgs.list(self.friends_noself)do
		for _,to in sgs.list(destlist)do
			if self.player:inMyAttackRange(to) and p:inMyAttackRange(to) and self:isEnemy(to) then
				use.to:append(p)
				use.card = card
				return
			end
		end
	end
	for _,p in sgs.list(destlist)do
     	if self:isEnemy(to) then continue end
		for _,to in sgs.list(destlist)do
			if self.player:inMyAttackRange(to) and p:inMyAttackRange(to) and self:isEnemy(to) then
				use.to:append(p)
				use.card = card
				return
			end
		end
   	end
	for _,p in sgs.list(destlist)do
		for _,to in sgs.list(destlist)do
			if self.player:inMyAttackRange(to) and p:inMyAttackRange(to) and self:isEnemy(to) and self:isWeak(to) then
				use.to:append(p)
				use.card = card
				return
			end
		end
   	end
end

sgs.ai_use_value.keshuaidaorenCard = 3.4
sgs.ai_use_priority.keshuaidaorenCard = 2.4

sgs.ai_skill_invoke.keshuaixuchong = function(self,data)
	return true
end

sgs.ai_skill_choice.keshuaixuchong = function(self,choices)
	local items = choices:split("+")
	local to = self.room:getCurrent()
	if to==self.player then
		if self:getOverflow()>1 then
			return items[2]
		end
	elseif self:isFriend(to) and self:isWeak(to) then
		if self:getOverflow()>0 then
			return items[2]
		end
	end
	return items[1]
end

sgs.ai_skill_invoke.keshuaigangfen = function(self,data)
	local str = data:toString()
	local use = self.room:getTag("keshuaigangfenData"):toCardUse()
	if str:contains("ask2") then
		if self:isFriend(use.to:at(0)) then
			return true
		end
	else
		if self:isEnemy(use.from) and self:isFriend(use.to:at(0)) then
			return #self.friends>use.from:getHandcardNum()/2
		end
	end
end

sgs.ai_skill_invoke.keshuaidangren = function(self,data)
	return true
end


local keshuaidangren={}
keshuaidangren.name="keshuaidangren"
table.insert(sgs.ai_skills,keshuaidangren)
keshuaidangren.getTurnUseCard = function(self)
	local dc = dummyCard("Peach")
	dc:setSkillName("keshuaidangren")
	return dc
end

local keshuaiqiluan={}
keshuaiqiluan.name="keshuaiqiluan"
table.insert(sgs.ai_skills,keshuaiqiluan)
keshuaiqiluan.getTurnUseCard = function(self)
    local dc = dummyCard()
	dc:setSkillName("keshuaiqiluan")
	local d = self:aiUseCard(dc)
	if d.card then
		local cards = self.player:getCards("he")
		cards = sgs.QList2Table(cards) -- 将列表转换为表
		local tos = sgs.ai_skill_playerschosen.keshuaiqiluan(self,self.room:getOtherPlayers(self.player),#cards,1)
		self:sortByKeepValue(cards) -- 按保留值排序
		local ids = {}
		for _,c1 in sgs.list(cards)do
			if #ids>=#tos then break end
			table.insert(ids,c1:getId())
		end
		if #ids<1 then return end
		self.keshuaiqiluanTo = d.to
		return sgs.Card_Parse("#keshuaiqiluanCard:"..table.concat(ids,"+")..":slash")
	end
end

sgs.ai_skill_use_func["#keshuaiqiluanCard"] = function(card,use,self)
	use.card = card
	use.to = self.keshuaiqiluanTo
end

sgs.ai_use_value.keshuaiqiluanCard = 6.4
sgs.ai_use_priority.keshuaiqiluanCard = 2.4

sgs.ai_skill_playerschosen.keshuaiqiluan = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,"handcard",true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isFriend(p) then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if table.contains(tos,p) then continue end
		if #tos<=x/2 and not self:isEnemy(p) then table.insert(tos,p) end
	end
    return tos
end

sgs.ai_guhuo_card.keshuaiqiluan = function(self,toname,class_name)
	if self:getCardsNum(class_name)>0 then return end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards) -- 将列表转换为表
	local tos = sgs.ai_skill_playerschosen.keshuaiqiluan(self,self.room:getOtherPlayers(self.player),#cards,1)
	self:sortByKeepValue(cards) -- 按保留值排序
	local ids = {}
	for _,c1 in sgs.list(cards)do
		if #ids>=#tos then break end
		table.insert(ids,c1:getId())
	end
	if #ids<1 then return end
	return "#keshuaiqiluanCard:"..table.concat(ids,"+")..":"..toname
end

sgs.ai_skill_cardask.keshuaiqiluan = function(self,data,pattern,prompt)
    local parsed = data:toPlayer()
    if self:isFriend(parsed)
	then return true end
	return "."
end

local keshuaixiangjia={}
keshuaixiangjia.name="keshuaixiangjia"
table.insert(sgs.ai_skills,keshuaixiangjia)
keshuaixiangjia.getTurnUseCard = function(self)
	local dc = dummyCard("Collateral")
	dc:setSkillName("keshuaixiangjia")
	return dc
end

sgs.ai_skill_invoke.keshuaixiangjia = function(self,data)
	return true
end

sgs.ai_skill_invoke.keshuaijueyin = function(self,data)
	return true
end

sgs.ai_skill_invoke.keshuaizonghai = function(self,data)
	local to = data:toPlayer()
	return self:isEnemy(to) or not self:isFriend(to) and #self.enemies<1
end

sgs.ai_skill_playerschosen.keshuaizonghai = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isFriend(p) and getCardsNum("Peach",p,self.player)>0
		and p:getHp()>1 then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isEnemy(p) and p:getHp()<2
		then table.insert(tos,p) end
	end
	return tos
end


sgs.ai_skill_discard.keshuaisaojian = function(self,max,min,optional)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	return {cards[math.random(1,#cards)]}
end





local xingqiantun={}
xingqiantun.name="xingqiantun"
table.insert(sgs.ai_skills,xingqiantun)
xingqiantun.getTurnUseCard = function(self)
    return sgs.Card_Parse("#xingqiantunCard:.:")
end

sgs.ai_skill_use_func["#xingqiantunCard"] = function(card,use,self)
	self:sort(self.enemies)
    for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p)
		and self.player:inMyAttackRange(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
    for _,p in sgs.list(self.enemies)do
		if self.player:canPindian(p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.xingqiantunCard = 3.4
sgs.ai_use_priority.xingqiantunCard = 6.4

sgs.ai_skill_discard.xingqiantun = function(self,max,min,optional)
	local ids = {}
	local mc = self:getMaxCard()
	if mc then table.insert(ids,mc:getId()) end
	local xc = self:getMinCard()
	if xc and xc~=mc then table.insert(ids,xc:getId()) end
	return ids
end

sgs.ai_skill_discard.xingqiantun_pd = function(self,max,min,optional)
	local dc = sgs.QList2Table(self.player:getTag("xingqiantunIds"):toIntList())
	return {dc[math.random(1,#dc)]}
end

sgs.ai_skill_playerschosen.xingxiezheng = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isFriend(p) and getCardsNum("Slash",p,self.player)>0
		and p:getHp()>1 then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and not self:isFriend(p)
		and p:getHandcardNum()>0
		then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self.player:canUse(dummyCard("_ov_binglinchengxia"),p)
		then return tos end
	end
	return {}
end

sgs.ai_skill_discard.xingxiezheng = function(self,max,min,optional)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
	if self:isFriend(self.room:getCurrent()) then
		for _,c in sgs.list(cards)do
			if c:isKindOf("Slash") then return {c} end
		end
	end
	return {cards[1]}
end

sgs.ai_skill_use["@@xingxiezheng!"] = function(self,prompt)
	local dc = dummyCard("_ov_binglinchengxia")
	dc:setSkillName("_xingxiezheng")
	if dc:isAvailable(self.player) then
		local dummy = self:aiUseCard(dc)
		if dummy.card and dummy.to then
			local tos = {}
			for _,p in sgs.list(dummy.to)do
				table.insert(tos,p:objectName())
			end
			return dc:toString().."->"..table.concat(tos,"+")
		end
	end
end

sgs.ai_skill_invoke.xingzhaoxiong = function(self,data)
	return self.player:getLostHp()>#self.enemies/2
end

local xingweisi={}
xingweisi.name="xingweisi"
table.insert(sgs.ai_skills,xingweisi)
xingweisi.getTurnUseCard = function(self)
    return sgs.Card_Parse("#xingweisiCard:.:")
end

sgs.ai_skill_use_func["#xingweisiCard"] = function(card,use,self)
	local dc = dummyCard("duel")
	local d = self:aiUseCard(dc)
    for _,p in sgs.list(d.to)do
		if self:isEnemy(p) and self.player:canUse(dc,p) then
			use.card = card
			use.to:append(p)
			return
		end
	end
end

sgs.ai_use_value.xingweisiCard = 2.4
sgs.ai_use_priority.xingweisiCard = 2.4

sgs.ai_skill_discard.xingweisi = function(self,max,min,optional)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
	local ids = {}
	local has = true
	for _,c in sgs.list(cards)do
		if c:isKindOf("Slash") or c:isKindOf("Nullification") then continue end
		if c:isKindOf("Jink") and has and #ids>0 and dummyCard():isAvailable(self.room:getCurrent())
		and self.room:getCurrent():inMyAttackRange(self.player) then
			has = false
			continue
		end
		table.insert(ids,c)
	end
	return ids
end

sgs.ai_skill_invoke.xingdangyi = function(self,data)
	local srt = data:toString():split(":")
	for _,p in sgs.list(self.enemies)do
		if p:objectName()==srt[2] then
			return self:isWeak() or self:isWeak(p)
		end
	end
end

sgs.ai_target_revises.xingsheju = function(to,card,self,use)
    if card:isKindOf("Slash") and use.to:length()==1 then
		for _,h in sgs.list(self.player:getHandcards())do
			if not h:isBlack() and card:getEffectiveId()~=h:getEffectiveId()
			then return end
		end
		return true
	end
end

sgs.ai_skill_playerchosen.xingchengliu = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p) and self:damageIsEffective(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p) and #self.enemies<1
		and self:damageIsEffective(p)
		then return p end
	end
end

sgs.ai_skill_cardask.xingchengliu1 = function(self,data,pattern,prompt)
	for _, p in sgs.list(self.enemies) do
		if p:getMark("xingchengliuTo-Clear")<1 and self:damageIsEffective(p)
		and self.player:getEquips():length()-p:getEquips():length()>1
		and (self:isWeak(p) or not self:isWeak()) then
			return true
		end
	end
	return "."
end

sgs.ai_skill_cardask.xingjianchuan0 = function(self,data,pattern,prompt)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
	for _, id in sgs.list(data:toIntList()) do
		local c = sgs.Sanguosha:getCard(id)
		local k = self:getUseValue(c)
		for _, h in sgs.list(cards) do
			if k>self:getUseValue(h) then
				return h:toString()
			end
		end
	end
	return "."
end

local xingfennan={}
xingfennan.name="xingfennan"
table.insert(sgs.ai_skills,xingfennan)
xingfennan.getTurnUseCard = function(self)
    return sgs.Card_Parse("#xingfennanCard:.:")
end

sgs.ai_skill_use_func["#xingfennanCard"] = function(card,use,self)
	if self.player:faceUp() then
		self:sort(self.enemies,nil,true)
		for _,p in sgs.list(self.enemies)do
			if p:getCardCount()>0 then
				use.card = card
				use.to:append(p)
				return
			end
		end
	else
		self:sort(self.friends,nil,true)
		for _,p in sgs.list(self.friends)do
			if #self:poisonCards("ej",p)>0 then
				use.card = card
				use.to:append(p)
				return
			end
		end
		for _,p in sgs.list(self.friends)do
			if p:getCardCount()>0 then
				use.card = card
				use.to:append(p)
				return
			end
		end
	end
end

sgs.ai_use_value.xingfennanCard = 2.4
sgs.ai_use_priority.xingfennanCard = 2.4

sgs.ai_skill_choice.xingfennan = function(self,choices,data)
	local items = choices:split("+")
	local to = data:toPlayer()
	if self:isFriend(to) then
		if not to:faceUp() or #self:poisonCards("ej")>0 then
			return items[1]
		end
		return items[2]
	else
		if self:getOverflow()>0 then
			return items[2]
		end
	end
	return items[1]
end

sgs.ai_skill_use["@@xingxunji"] = function(self,prompt)
	local valid = {}
	local destlist = self.room:getAlivePlayers()
    destlist = self:sort(destlist)
	local ids = {}
	local cards = {}
	for _,id in sgs.list(self.player:getTag("xingxunjiForAI"):toIntList())do
		table.insert(cards,sgs.Sanguosha:getCard(id))
	end
	for i=0,9 do
		local c,p = self:getCardNeedPlayer(cards,nil,destlist)
		if c and p then
			table.insert(ids,c:getId())
			table.insert(valid,p:objectName())
			table.removeOne(cards,c)
			table.removeOne(destlist,p)
			if #cards<1 or #destlist<1 then break end
		end
	end
	if #valid>0 then
    	return "#xingxunjiCard:"..table.concat(ids,"+")..":->"..table.concat(valid,"+")
	end
end

local xingshanzheng={}
xingshanzheng.name="xingshanzheng"
table.insert(sgs.ai_skills,xingshanzheng)
xingshanzheng.getTurnUseCard = function(self)
    return sgs.Card_Parse("#xingshanzhengCard:.:")
end

sgs.ai_skill_use_func["#xingshanzhengCard"] = function(card,use,self)
	self:sort(self.friends_noself)
	for i,p in sgs.list(self.friends_noself)do
		if i<#self.friends_noself and p:getHandcardNum()>0 then
			use.card = card
			use.to:append(p)
		end
	end
	self:sort(self.enemies)
	for i,p in sgs.list(self.enemies)do
		if i<#self.enemies and p:getHandcardNum()>0 then
			use.card = card
			use.to:append(p)
		end
	end
end

sgs.ai_use_value.xingshanzhengCard = 3.4
sgs.ai_use_priority.xingshanzhengCard = 6.4

sgs.ai_skill_invoke.xingxiongbao = function(self,data)
	return #self.enemies>=#self.friends_noself
end

sgs.ai_skill_invoke.xingfuran = function(self,data)
	return self.player:getLostHp()>0
end

sgs.ai_skill_discard.xingqinrao = function(self,max,min,optional,equiped,pattern)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
	local ids = pattern:split(",")
	local has = true
	for _,c in sgs.list(cards)do
		if table.contains(ids,c:toString()) then
			local dc = dummyCard("duel")
			dc:addSubcard(c)
			local d = self:aiUseCard(dc,dummy(nil,99))
			if d.to:contains(self.room:getCurrent()) then
				return {c:getId()}
			end
		end
	end
	return {}
end

local xingciying={}
xingciying.name="xingciying"
table.insert(sgs.ai_skills,xingciying)
xingciying.getTurnUseCard = function(self)
	local n = 4
	for _,m in ipairs(self.player:getMarkNames()) do
		if m:startsWith("&xingciying+") and self.player:getMark(m)>0 then
			n = 1+n-#m:split("+")
			break
		end
	end
	n = math.max(1,n)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
	for _,pn in sgs.list(patterns())do
		local dc = dummyCard(pn)
		if dc and dc:isKindOf("BasicCard") then
			dc:setSkillName("xingciying")
			local ids = sgs.IntList()
			for _,c in ipairs(cards) do
				dc:addSubcards(ids)
				dc:addSubcard(c)
				if dc:isAvailable(self.player) then
					if dc:subcardsLength()>=n and self:aiUseCard(dc).card then
						return dc
					end
					ids:append(c:getId())
				end
				dc:clearSubcards()
			end
		end
	end
end

function sgs.ai_cardsview.xingciying(self,class_name,player)
   	local cards = sgs.QList2Table(player:getCards("he"))
    self:sortByKeepValue(cards)
	local dc = dummyCard(class_name)
	dc:setSkillName("xingciying")
	local n = 4
	for _,m in ipairs(player:getMarkNames()) do
		if m:startsWith("&xingciying+") and player:getMark(m)>0 then
			n = 1+n-#m:split("+")
			break
		end
	end
	n = math.max(1,n)
	local ids = sgs.IntList()
	for _,c in ipairs(cards) do
		dc:addSubcards(ids)
		dc:addSubcard(c)
		if not player:isLocked(dc) then
			if dc:subcardsLength()>=n then
				return dc:toString()
			end
			ids:append(c:getId())
		end
		dc:clearSubcards()
	end
end

sgs.ai_skill_askforyiji.xingchendu = function(self,card_ids,tos)
    local p,id = sgs.ai_skill_askforyiji.nosyiji(self,card_ids,tos)
	if p and id then return p,id end
	for _,p in sgs.list(tos)do
		if self:isFriend(p) and self:canDraw(p) then
			return p,card_ids[1]
		end
	end
	for _,p in sgs.list(tos)do
		if self:isFriend(p) then
			return p,card_ids[1]
		end
	end
	return tos:first(),card_ids[1]
end

local xingpiqi={}
xingpiqi.name="xingpiqi"
table.insert(sgs.ai_skills,xingpiqi)
xingpiqi.getTurnUseCard = function(self)
    return sgs.Card_Parse("#xingpiqiCard:.:")
end

sgs.ai_skill_use_func["#xingpiqiCard"] = function(card,use,self)
	local dc = dummyCard("snatch")
	dc:setSkillName("kehexuanfeng")
	for _,p in sgs.list(self:aiUseCard(dc,dummy(nil,99)).to)do
		if p:getMark("&xingpiqiUse-PlayClear")<1 then
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.xingpiqiCard = 4.4
sgs.ai_use_priority.xingpiqiCard = 9.4

function sgs.ai_cardsview.xingpiqivs(self,class_name,player)
   	local cards = sgs.QList2Table(player:getCards("he"))
    self:sortByKeepValue(cards)
	local dc = dummyCard("nullification")
	dc:setSkillName("_xingpiqi")
	for _,c in ipairs(cards) do
		if c:isKindOf("Jink") then
			dc:addSubcard(c)
			if self.player:isLocked(dc) then
				dc:clearSubcards()
				continue
			end
			return dc:toString()
		end
	end
end

sgs.ai_skill_playerschosen.xingzuodan = function(self,players,x,n)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local tos = {}
    for _,p in sgs.list(destlist)do
		if #tos<x and self:isFriend(p)
		and p:getHp()>1 then table.insert(tos,p) end
	end
    for _,p in sgs.list(destlist)do
		if #tos<x and not self:isEnemy(p)
		then table.insert(tos,p) end
	end
	return tos
end

sgs.ai_skill_playerchosen.xingzuodan = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isFriend(p) and self:canDraw(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isEnemy(p) and #self.enemies<1
		and self:canDraw(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:isFriend(p)
		then return p end
	end
end

sgs.ai_skill_playerchosen.xingcuibing = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist,nil,true)
	local n = self.player:getMark("xingcuibing0")
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"he",n)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if self:doDisCard(p,"he")
		then return p end
	end
end

sgs.ai_skill_playerschosen.xingfuzhen = function(self,players,x,n)
	if self.player:getHp()<2 then return {} end
	local tos = {}
    local dc = dummyCard("thunder_slash")
	dc:setSkillName("kehexuanfeng")
	local d = self:aiUseCard(dc,dummy(nil,2))
	for _,p in sgs.list(players)do
		if #tos<x and d.to:contains(p) then table.insert(tos,p) end
	end
	return tos
end

local xingzhuwei={}
xingzhuwei.name="xingzhuwei"
table.insert(sgs.ai_skills,xingzhuwei)
xingzhuwei.getTurnUseCard = function(self)
    return sgs.Card_Parse("#xingzhuweiCard:.:")
end

sgs.ai_skill_use_func["#xingzhuweiCard"] = function(card,use,self)
	sgs.ai_skill_invoke.peiqi(self)
	for _,p in sgs.list(self.room:getAlivePlayers())do
		if p==self.peiqiData.from then 
			use.card = card
			use.to:append(p)
			break
		end
	end
end

sgs.ai_use_value.xingzhuweiCard = 4.4
sgs.ai_use_priority.xingzhuweiCard = 9.4

sgs.ai_skill_playerchosen["xingzhuwei"] = function(self,players)
	for _,p in sgs.list(players)do
		if p==self.peiqiData.to
		then return p end
	end
end

sgs.ai_skill_cardchosen.xingzhuwei = function(self,who,flags,method)
	for _,e in sgs.list(who:getCards(flags))do
		local id = e:getEffectiveId()
		if id==self.peiqiData.cid
		then return id end
	end
end

sgs.ai_skill_playerchosen.xingzhuwei1 = function(self,players)
	local destlist = sgs.QList2Table(players) -- 将列表转换为表
	self:sort(destlist)
    for _,p in sgs.list(destlist)do
		if self:isEnemy(p)
		then return p end
	end
    for _,p in sgs.list(destlist)do
		if not self:isFriend(p)
		then return p end
	end
end

local xingkuangjian={}
xingkuangjian.name="xingkuangjian"
table.insert(sgs.ai_skills,xingkuangjian)
xingkuangjian.getTurnUseCard = function(self)
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards) -- 按保留值排序
	for _,pn in sgs.list(patterns())do
		local dc = dummyCard(pn)
		if dc and dc:isKindOf("BasicCard") then
			dc:setSkillName("xingkuangjian")
			for _,c in ipairs(cards) do
				if c:isKindOf("EquipCard") then
					dc:addSubcard(c)
					if dc:isAvailable(self.player) then
						if self:aiUseCard(dc).card then
							return dc
						end
					else
						dc:clearSubcards()
					end
				end
			end
		end
	end
end

function sgs.ai_cardsview.xingkuangjian(self,class_name,player)
   	local cards = sgs.QList2Table(player:getCards("he"))
    self:sortByKeepValue(cards)
	local dc = dummyCard(class_name)
	dc:setSkillName("xingkuangjian")
	for _,c in ipairs(cards) do
		if c:isKindOf("EquipCard") then
			dc:addSubcard(c)
			if self.player:isLocked(dc) then
				dc:clearSubcards()
			else
				return dc:toString()
			end
		end
	end
end





