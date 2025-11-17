local luajuao_skill = {}
luajuao_skill.name = "luajuao"
table.insert(sgs.ai_skills, luajuao_skill)
luajuao_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#luajuaocard") and not self.player:isKongcheng() then return sgs.Card_Parse(
		"#luajuaocard:.:") end
end

sgs.ai_skill_use_func["#luajuaocard"] = function(card, use, self)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	local use_card = nil
	self:sortByCardNeed(handcards, true)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local target = nil
	for _, c in ipairs(handcards) do
		if c:isKindOf("Slash") then
			use_card = c
		end
	end
	if use_card == nil then return end
	local red = 0
	for _, c in ipairs(handcards) do
		if c:isAvailable(self.player) then
			if c:isRed() and not c:isKindOf("Slash") then
				red = red + 1
			end
		end
	end
	local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	for _, enemy in ipairs(self.enemies) do
		if self:hasTrickEffective(duel, enemy, self.player) then
			if self.player:getHp() <= enemy:getHp() then
				red = red + 0.5
			end
			--if self:getCardsNum("Slash") + red > enemy:getHandcardNum() / 2 then
			if self:getCardsNum("Slash") + red > getCardsNum("Slash", enemy) then
				target = enemy
			end
			if self.player:getHp() <= enemy:getHp() then
				red = red - 0.5
			end
		end
	end
	if target == nil then return end
	local card_str = string.format("#luajuaocard:%s:", use_card:getEffectiveId())
	local acard = sgs.Card_Parse(card_str)
	use.card = acard
	duel:deleteLater()
	if use.to then use.to:append(target) end
end
--sgs.ai_use_priority["#luajuaocard"] = sgs.ai_use_value.XiechanCard
sgs.ai_use_priority.luajuaocard = sgs.ai_use_priority.XiechanCard
--sgs.ai_use_value.luajuaocard = sgs.ai_use_value.XiechanCard
sgs.ai_use_value.luajuaocard = sgs.ai_use_value.XiechanCard
sgs.ai_card_intention.luajuaocard = sgs.ai_card_intention.XiechanCard

sgs.ai_cardneed.luajuao = function(to, card, self)
	return isCard("Slash", card, to) and getKnownCard(to, self.player, "Slash", true) == 0
end

local zfduanhe_skill = {}
zfduanhe_skill.name = "zfduanhe"
table.insert(sgs.ai_skills, zfduanhe_skill)
zfduanhe_skill.getTurnUseCard = function(self)
	if self:needBear() then return end
	if not self.player:hasUsed("#zfduanhe") then return sgs.Card_Parse("#zfduanhe:.:") end
end

sgs.ai_skill_use_func["#zfduanhe"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if #targets < 2 and self.player:canSlash(enemy, nil, true) and enemy:getMark("@zfduanhe-Clear") == 0 then
			table.insert(targets, enemy)
		else
			break
		end
	end
	if #targets < 2 then
		for _, enemy in ipairs(self.enemies) do
			if #targets < 2 and not table.contains(targets, enemy) and enemy:getMark("@zfduanhe-Clear") == 0 then
				table.insert(targets, enemy)
			else
				break
			end
		end
	end
	local slashcount = self:getCardsNum("Slash")
	if #targets > 0 and slashcount > 0 then
		use.card = sgs.Card_Parse("#zfduanhe:.:")
		if use.to then
			for i = 1, #targets, 1 do
				use.to:append(targets[i])
			end
		end
		return
	end
end
sgs.ai_use_priority["zfduanhe"] = 7
sgs.ai_use_value["zfduanhe"] = 7
sgs.ai_card_intention["zfduanhe"] = 80

sgs.ai_cardneed.zfduanhe = sgs.ai_cardneed.slash


sgs.ai_cardneed.spwushen = function(to,card,self)
	return isCard("BasicCard",card,to) or card:getSuit() == sgs.Card_Heart
end

sgs.ai_skill_playerchosen["spwushen"] = function(self, targets)
    targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	local card=sgs.Sanguosha:cloneCard("fire_slash",sgs.Card_Heart,0)
    card:deleteLater()
    card:setSkillName("spwushen")
    local dummy_use = self:aiUseCard(card, dummy())
    if dummy_use.card and not dummy_use.to:isEmpty() then
        for _, p in sgs.qlist(dummy_use.to) do
            if table.contains(targets, p) then
                return p
            end
        end
    end
    local targetlist = sgs.QList2Table(targets)
	local arrBestHp,canAvoidSlash,forbidden = {},{},{}
	self:sort(targetlist,"defenseSlash")
	for _,target in sgs.list(targetlist)do
		if self:isEnemy(target)
		and not self:slashProhibit(card,target)
		and self:isGoodTarget(target,targetlist) then
			if self:slashIsEffective(card,target) then
				if self:needToLoseHp(target,self.player,card) 
				or self:needLeiji(target,self.player)
				then table.insert(forbidden,target)
				elseif self:needToLoseHp(target,self.player,card,true)
				then table.insert(arrBestHp,target)
				else return target end
			else
				table.insert(canAvoidSlash,target)
			end
		end
	end
	targetlist = sgs.reverse(targetlist)
	for _,target in sgs.list(targetlist)do
		if not self:slashProhibit(card,target) then
			if self:slashIsEffective(card,target) then
				if self:isFriend(target)
				and (self:needToLoseHp(target,self.player,card,true) or self:needLeiji(target,self.player))
				then return target end
			else
				table.insert(canAvoidSlash,target)
			end
		end
	end
	if #canAvoidSlash>0 then return canAvoidSlash[1] end
	if #arrBestHp>0 then return arrBestHp[1] end
	for _,target in sgs.list(targetlist)do
		if target:objectName()~=self.player:objectName()
		and not self:isFriend(target) and not table.contains(forbidden,target)
		then return target end
	end
	return nil
end

sgs.exclusive_skill = sgs.exclusive_skill .."|spwuhun"
sgs.ai_skill_playerchosen.spwuhun = function(self,targets)
	local targetlist=self:sort(targets,"hp")
	local target
	local lord
	for _,player in sgs.list(targetlist)do
		if player:isLord() then lord = player end
		if self:isEnemy(player) and (not target or target:getHp()<player:getHp()) then
			target = player
		end
	end
	if self.role=="rebel" and lord then return lord end
	if target then return target end
	
	if self.player:getRole()=="loyalist" and targetlist[1]:isLord() then return targetlist[2] end
	return targetlist[1]
end

function SmartAI:getSpWuhunRevengeTargets()
	local targets = {}
	local maxcount = 0
	for _,p in sgs.list(self.room:getAlivePlayers())do
		local count = p:getMark("@spnightmare")
		if count>maxcount then
			targets = { p }
			maxcount = count
		elseif count==maxcount and maxcount>0 then
			table.insert(targets,p)
		end
	end
	return targets
end


function sgs.ai_slash_prohibit.spwuhun(self,from,to)
	if from:hasSkill("jueqing") then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	local damageNum = self:ajustDamage(from,to,1,dummyCard())

	local maxfriendmark = 0
	local maxenemymark = 0
	for _,friend in sgs.list(self:getFriends(from))do
		local friendmark = friend:getMark("@spnightmare")
		if friendmark>maxfriendmark then maxfriendmark = friendmark end
	end
	for _,enemy in sgs.list(self:getEnemies(from))do
		local enemymark = enemy:getMark("@spnightmare")
		if enemymark>maxenemymark and enemy:objectName()~=to:objectName() then maxenemymark = enemymark end
	end
	if self:isEnemy(to,from) and not (to:isLord() and from:getRole()=="rebel") then
		if (maxfriendmark+damageNum>=maxenemymark) and not (#(self:getEnemies(from))==1 and #(self:getFriends(from))+#(self:getEnemies(from))==self.room:alivePlayerCount()) then
			if not (from:getMark("@spnightmare")==maxfriendmark and from:getRole()=="loyalist") then
				return true
			end
		end
	end
end




function sgs.ai_cardneed.lyduji(to, card)
	return card:getSuit() == sgs.Card_Spade
end

local lyduji_skill = {}
lyduji_skill.name = "lyduji"
table.insert(sgs.ai_skills,lyduji_skill)
lyduji_skill.getTurnUseCard = function(self,inclusive)
	local can_use = false
	self:sort(self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if a:canPindian(b) then can_use = true end
		end
	end
	if can_use
	then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValue(cards)
		for _,c in sgs.list(cards)do
			if not c:getSuit() == sgs.Card_Spade then continue end
			return sgs.Card_Parse("#lyduji:"..c:getEffectiveId()..":")
		end
	end
end

sgs.ai_skill_use_func["#lyduji"] = function(card,use,self)
	self:sort(self.enemies,"chaofeng")
	for _,a in ipairs(self.enemies)do
		for _,b in ipairs(self.enemies)do
			if a:canPindian(b)
			then
				use.card = card
				use.to:append(a)
				--use.to:append(b)
                self.lydujiTarget = b
				return
			end
		end
	end
end
sgs.ai_skill_playerchosen.lyduji = function(self,targets)
	local enemies = self:sort(targets,"hp")
  	if self.lydujiTarget then
        return self.lydujiTarget
    end
  	for i,p in sgs.list(enemies)do
		if not self:isFriend(p)
		then return p end
	end
	return enemies[1]
end

sgs.ai_use_priority["lyduji"] = 2
sgs.ai_use_value["lyduji"] = 2.5
sgs.ai_card_intention["lyduji"] = 80

local lyxiance_skill = {}
lyxiance_skill.name = "lyxiance"
table.insert(sgs.ai_skills, lyxiance_skill)
lyxiance_skill.getTurnUseCard = function(self)
	if #self.friends_noself == 0 then return end
    if self.player:getRole() == "lord" then return end
	if not self.player:isKongcheng() and self:getOverflow() > 0 then
		return sgs.Card_Parse("#lyxiance:.:")
	end
end

sgs.ai_skill_use_func["#lyxiance"] = function(card, use, self)
    local lord = self.room:getLord()
    if lord and self:isFriend(lord) and self:canDraw(lord, self.player) then
        local use_card = false
        local cards = sgs.QList2Table(self.player:getHandcards())
        for _, acard in ipairs(cards) do
            if acard:isKindOf("TrickCard") then
                use_card = acard
                break
            end
        end
        if use_card then
            use.card = sgs.Card_Parse("#lyxiance:".. use_card:getEffectiveId()..":")
            if use.to then use.to:append(lord) end
            return
        end
	end
end

sgs.ai_card_intention["lyxiance"] = -80


sgs.ai_can_damagehp.lybeixi = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and card and card:isKindOf("Slash")
	then
		return self:isEnemy(from) and self:toTurnOver(from,from:getLostHp(),"lybeixi")
	end
end
sgs.ai_skill_invoke.lybeixi = function(self, data)
    local target = data:toDamage().from
	if self:toTurnOver(target,target:getLostHp(),"lybeixi") then
        return true
    end
	return false
end

sgs.ai_choicemade_filter.skillInvoke.lybeixi = function(self, player, promptlist)
	local damage = self.room:getTag("CurrentDamageStruct"):toDamage()
	if damage.from and promptlist[3]=="yes" then
		local intention = 80/math.max(player:getLostHp(),1)
        if not self:toTurnOver(damage.from,player:getLostHp()) then intention = -intention end
        if damage.from:getLostHp()<3 then
            sgs.updateIntention(player,damage.from,intention)
        else
            sgs.updateIntention(player,damage.from,math.min(intention,-30))
        end
	end
end


sgs.ai_getBestHp_skill.dj = function(owner)
	return owner:getMaxHp() - 1
end

sgs.ai_getBestHp_skill.pj = function(owner)
	return owner:getMaxHp() - 1
end

sgs.ai_skill_invoke.fjsp_youlong = function(self, data)
	local damage = data:toDamage()
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	if not self.player:faceUp() then
		if self.player:canSlash(damage.from, slash, false) then
			if self:isEnemy(damage.from) and self:isGoodTarget(damage.from, self.enemies, slash) and self:slashIsEffective(slash, damage.from, self.player) then
				return true
			end
		end
		if self.player:canSlash(damage.to, slash, false) then
			if self:isEnemy(damage.to) and self:isGoodTarget(damage.to, self.enemies, slash) and self:slashIsEffective(slash, damage.to, self.player) then
				return true
			end
		end
	else
		if self:getEnemyNumBySeat(self.room:getCurrent(), self.player, self.player, true) >= 2 then
			if self.player:canSlash(damage.from, slash, false) then
				if self:isEnemy(damage.from) and self:isGoodTarget(damage.from, self.enemies, slash) and self:slashIsEffective(slash, damage.from, self.player) then
					return true
				end
			end
		end
		if self.player:canSlash(damage.to, slash, false) then
			if self:isEnemy(damage.to) and self:isGoodTarget(damage.to, self.enemies, slash) and self:slashIsEffective(slash, damage.to, self.player) then
				return true
			end
		end
	end
	return false
end

sgs.ai_skill_playerchosen.fjsp_youlong = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|fjsp_youlong"

sgs.ai_skill_use["@@dangqian"] = function(self)
	self:sort(self.enemies)
	local targets = {}
	for _, enemy in ipairs(self.enemies) do
		if self:doDisCard(enemy, "he") then
			table.insert(targets, enemy:objectName())
		end
		if #targets == self.player:getHp() then break end
	end

	if #targets < self.player:getHp() then
		for _, friend in ipairs(self.friends) do
			if self:doDisCard(friend, "he") then
				table.insert(targets, friend:objectName())
			end
			if #targets == self.player:getHp() then break end
		end
	end

	if #targets > 0 then
		return "#dangqianCard:.:->" .. table.concat(targets, "+")
	end
	return "."
end

sgs.ai_card_priority.dangqian = function(self, card)
	if card:getSkillName() == "longdan"
	then
		return 1
	end
end


sgs.ai_skill_invoke.LuaJuecaiA = function(self,data)
	return  not self:needKongcheng(self.player, true) and not hasManjuanEffect(self.player) 
end
sgs.ai_skill_invoke.LuaJuecaiB = function(self,data)
	local dest = data:toPlayer()
	return self:doDisCard(dest, "he")
end

sgs.ai_skill_invoke.cuoyong = function(self, data)
	if self.player:hasSkill("haoshi") then
		local num = self.player:getHandcardNum()
		local skills = self.player:getVisibleSkillList(true)
		local count = self:ImitateResult_DrawNCards(self.player, skills)
		if num + count > 5 then
			local others = self.room:getOtherPlayers(self.player)
			local least = 999
			local target = nil
			for _,p in sgs.qlist(others) do
				local handcardnum = p:getHandcardNum()
				if handcardnum < least then
					least = handcardnum
					target = p
				end
			end
			if target then
				if self:isFriend(target) then
					return not target:hasSkill("manjuan")
				end
			end
		end
	end
	return true
end


LuaFangxian_skill={}
LuaFangxian_skill.name = "LuaFangxian"
table.insert(sgs.ai_skills, LuaFangxian_skill)

LuaFangxian_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#LuaFangxianCard") or self.player:isKongcheng() then return end
	local cards = sgs.QList2Table(self.player:getHandcards())
	local card = cards[1]
	for _,c in ipairs(cards) do if c:getSuit() == sgs.Card_Diamond then card = c end end
	for _,c in ipairs(cards) do if c:getSuit() == sgs.Card_Heart then card = c end end
	return sgs.Card_Parse("#LuaFangxianCard:"..card:getEffectiveId()..":")
end

sgs.ai_skill_use_func["#LuaFangxianCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_askforag["LuaFangxian"] = function(self, card_ids)
	local card_id = -1
	local re_id
	local re_n = 0
	local jink_id, peach_id, analeptic_id, ex_nihilo_id, nullification_id
	for _, id in ipairs(card_ids) do
		local target = self.room:getCardOwner(id)
		local card = sgs.Sanguosha:getCard(id)
		if self:isFriend(target) then
			local n = target:getHandcardNum() - target:getHp()
			if target:getHp() > 1 and n > 2 and card:isKindOf("Jink") then
				if re_n > n then re_n = n re_id = id end
			end 
			continue
		end
		card_id = id
		if card:isKindOf("Jink") then jink_id = id end
		if card:isKindOf("Analeptic") then analeptic_id = id end
		if card:isKindOf("ExNihilo") then ex_nihilo_id = id end
		if card:isKindOf("Nullification") then nullification_id = id end
		if card:isKindOf("Peach") then peach_id = id end
	end
	if jink_id then card_id = jink_id end
	if analeptic_id then card_id = analeptic_id end
	if ex_nihilo_id then card_id = ex_nihilo_id end
	if nullification_id then card_id = nullification_id end
	if peach_id then card_id = peach_id end
	if card_id == -1 and re_id and self:getCardsNum("Jink") < 1 and self.player:getHp() < 2 then card_id = re_id end
	return card_id
end

sgs.ai_use_value["LuaFangxianCard"] = 9
sgs.ai_use_priority["LuaFangxianCard"] = 9.2

sgs.ai_skill_playerchosen["LuaGaobi"] = function(self, targets)
	if #self.friends_noself < 1 then return self.player end
	local keepsNum = self:getCardsNum("Jink") + self:getCardsNum("Nullification") + self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + self:getCardsNum("Slash")
	if self:getCardsNum("Slash") > 0 and sgs.Slash_IsAvailable(self.player) then keepsNum = keepsNum -1 end
	if self:getCardsNum("Peach") > 0 and self.player:isWounded() then keepsNum = keepsNum -1 end
	if self.player:getMaxCards() < keepsNum then return self.player end
	local target
	local t_num = - 10086
	for _, friend in ipairs(self.friends_noself) do
		local n = friend:getHandcardNum() - friend:getMaxCards()
		if n > t_num then
			t_num = n
			target = friend
		end
		if n > 0 and friend:getHp() < 2 then return friend end
	end
	return target or self.player
end

function sgs.ai_cardneed.LuaChuanyun(to, card, self)
	local cards = to:getHandcards()
	local has_weapon = to:getWeapon() and not to:getWeapon():isKindOf("Crossbow")
	local slash_num = 0
	for _, c in sgs.qlist(cards) do
		local flag=string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isKindOf("Weapon") and not c:isKindOf("Crossbow") then
				has_weapon=true
			end
			if c:isKindOf("Slash") then slash_num = slash_num +1 end
		end
	end

	if not has_weapon then
		return card:isKindOf("Weapon") and not card:isKindOf("Crossbow")
	else
		return to:hasWeapon("spear") or card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic"))
	end
end

sgs.LuaChuanyun_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.6,
	Slash = 5.4,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}

function sgs.ai_cardneed.LuaPaoxiaoC(to, card, self)
	local cards = to:getHandcards()
	local has_weapon = to:getWeapon() and not to:getWeapon():isKindOf("Crossbow")
	local slash_num = 0
	for _, c in sgs.qlist(cards) do
		local flag=string.format("%s_%s_%s","visible",self.room:getCurrent():objectName(),to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if c:isKindOf("Weapon") and not c:isKindOf("Crossbow") then
				has_weapon=true
			end
			if c:isKindOf("Slash") then slash_num = slash_num +1 end
		end
	end

	if not has_weapon then
		return card:isKindOf("Weapon") and not card:isKindOf("Crossbow")
	else
		return to:hasWeapon("spear") or card:isKindOf("Slash") or (slash_num > 1 and card:isKindOf("Analeptic"))
	end
end

sgs.LuaPaoxiaoC_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.7,
	FireSlash = 5.6,
	Slash = 5.4,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}





sgs.ai_skill_invoke.LuaLongya = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if self:isEnemy(target) then
		if self.player:getMark("&zhican") < 6 then return false end
		if self:isWeak(target) then return false end
		if hasZhaxiangEffect(target) then return false end
		return true
	end
	return false
end


sgs.ai_skill_invoke["#LuaLongyaT"] = function(self, data)
	local target = data:toPlayer()
	if self:isEnemy(target) then
		if self.player:getMark("&zhican") < 6 then return false end
		if self:isWeak(target) then return false end
		if hasZhaxiangEffect(target) then return false end
		return true
	end
	return false
end




local krskitgjiamian_skill = {}
krskitgjiamian_skill.name = "krskitgjiamian"
table.insert(sgs.ai_skills, krskitgjiamian_skill)
krskitgjiamian_skill.getTurnUseCard = function(self)
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	local jink_card

	self:sortByUseValue(cards, true)

	for _, card in ipairs(cards) do
		if card:isKindOf("Jink") then
			jink_card = card
			break
		end
	end

	if not jink_card then return nil end
	local suit = jink_card:getSuitString()
	local number = jink_card:getNumberString()
	local card_id = jink_card:getEffectiveId()
	local card_str = ("slash:krskitgjiamian[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)

	return slash
end

sgs.ai_view_as.krskitgjiamian = function(card, player, card_place)
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card_place ~= sgs.Player_PlaceEquip then
		if card:isKindOf("Jink") then
			return ("slash:krskitgjiamian[%s:%s]=%d"):format(suit, number, card_id)
		elseif card:isKindOf("Slash") then
			return ("jink:krskitgjiamian[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

--sgs.ai_use_priority.krskitgjiamian = 9

sgs.krskitgjiamian_keep_value = {
	Peach = 6,
	Analeptic = 5.8,
	Jink = 5.8,
	FireSlash = 5.7,
	Slash = 5.9,
	ThunderSlash = 5.5,
	ExNihilo = 4.7
}

sgs.ai_card_priority.krskitgjiamian = function(self,card)
	if card:getSkillName()=="krskitgjiamian" and self.player:getHandcardNum() <= 1
	then
		if self.useValue
		then return 1 end
		return 0.08
	end
end

sgs.ai_skill_invoke.krskitgjiamian = true
sgs.ai_skill_playerchosen.krskitgjiamian = function(self, targets)
	self:sort(targets, "handcard")
	for _, enemy in ipairs(targets) do
		if not self:isFriend(enemy) and self:doDisCard(enemy, "h", true) then
			return enemy
		end
	end
end
sgs.ai_playerchosen_intention.krskitgjiamian = function(from, to)
	local intention = 50
	sgs.updateIntention(from, to, intention)
end


sgs.ai_skill_invoke.qingyue = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if target  then
		if self:isFriend(target) then
			if(target:hasSkill("kongcheng") or target:hasSkill("lianying") or target:hasSkill("tuntian")) and target:getHandcardNum() == 1 then 
			return true 
			end
		else
	return not target:hasSkill("kongcheng") 
		end
	end
	return false
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|xhjtangqiang"

sgs.ai_ajustdamage_from.bu_s2_jiashe = function(self,from,to,slash,nature)
	if to:getMark("&bu_s2_jiashe+#"..from:objectName()) > 0 then
		return -99
	end
end
sgs.ai_ajustdamage_from.bu_s2_benxi = function(self,from,to,slash,nature)
	return to:getMark("&bu_s2_benxi+#"..from:objectName().."-Clear")
end


local bu_s2_benxi_skill = {}
bu_s2_benxi_skill.name = "bu_s2_benxi"
table.insert(sgs.ai_skills, bu_s2_benxi_skill)
bu_s2_benxi_skill.getTurnUseCard = function(self)
	if not self.player:canDiscard(self.player,"he") then return end
	return sgs.Card_Parse("#bu_s2_benxi:.:")
end

sgs.ai_skill_use_func["#bu_s2_benxi"] = function(card, use, self)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sort(self.enemies, "handcard")
	local slashcount = self:getCardsNum("Slash")
	self:sortByUseValue(cards,true)
	if slashcount > 0  then
		local slash = self:getCard("Slash")
		assert(slash)
		self.player:setFlags("InfinityAttackRange")
		local dummy_use = self:aiUseCard(slash,dummy(true))
		self.player:setFlags("-InfinityAttackRange")
		if dummy_use.card and dummy_use.to:length() > 0 then
			local target
			for _,p in sgs.list(dummy_use.to)do
				if not self.player:inMyAttackRange(p) or self:doDisCard(p, "he", true) then
					target = p
				end
			end
			if target then
			use.card = sgs.Card_Parse("#bu_s2_benxi:.:")
					if use.to then use.to:append(target) end
					return
			end
		end
	else
		for _, enemy in ipairs(self.enemies) do
			if self:doDisCard(enemy, "he", true) then
				use.card = sgs.Card_Parse("#bu_s2_benxi:.:")
				if use.to then use.to:append(enemy) end
				return
			end
		end
	end
end

sgs.ai_card_intention["bu_s2_benxi"] = 70


sgs.ai_use_value["bu_s2_benxi"] = 9.2
sgs.ai_use_priority["bu_s2_benxi"] = sgs.ai_use_priority.Slash + 0.1

sgs.ai_skill_invoke.bu_stwo_guicai = true
sgs.ai_skill_discard.bu_stwo_guicai = function(self, discard_num, min_num, optional, include_equip)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		if not current:containsTrick("YanxiaoCard") then
			if (current:containsTrick("lightning") and not self:hasWizard(self.friends) and self:hasWizard(self.enemies))
				or (current:containsTrick("lightning") and #self.friends > #self.enemies) then
				return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
			elseif current:containsTrick("supply_shortage") then
				--if self.player:getHp() > self.player:getHandcardNum() then return true end
				return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
			elseif current:containsTrick("indulgence") then
				if self.player:getHandcardNum() > 3 or self.player:getHandcardNum() > self.player:getHp() - 1 then return self:askForDiscard("dummyreason", discard_num, min_num, false, true) end
				for _, friend in ipairs(self.friends_noself) do
					if not friend:containsTrick("YanxiaoCard") and (friend:containsTrick("indulgence") or friend:containsTrick("supply_shortage")) then
						return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
					end
				end
			end
		end
	elseif current and self:isEnemy(current) then
		return self:askForDiscard("dummyreason", discard_num, min_num, false, true)
	end
	return false
end
sgs.ai_skill_choice.bu_stwo_guicai = function(self,choices,data)
	local current = self.room:getCurrent()
	if current and self:isFriend(current) then
		return "skip"
	end
	return "effect"
end

sgs.ai_choicemade_filter.skillChoice["bu_stwo_guicai"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local current = self.room:getCurrent()
	if choice == "effect" then
		sgs.updateIntention(player, current, 60)
	else
		sgs.updateIntention(player, current, -60)
	end
end

sgs.ai_skill_use["@@bu_stwo_guicai"] = function(self, prompt, method)
	local card = sgs.Sanguosha:getCard(self.player:getMark("bu_stwo_guicai"))
	card:setSkillName("bu_stwo_guicai")

	local dummy_use = self:aiUseCard(card)
	local targets = {}
	if not dummy_use.to:isEmpty() then
		for _, p in sgs.qlist(dummy_use.to) do
			table.insert(targets, p:objectName())
		end
		if #targets > 0 then
			return card:toString() .. "->" .. table.concat(targets, "+")
		end
	end
	return "."
end
sgs.ai_can_damagehp.bu_stwo_guicai = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and #self.enemies > 0
end
