--孙策
local kechengduxing_skill = {}
kechengduxing_skill.name = "kechengduxing"
table.insert(sgs.ai_skills, kechengduxing_skill)
kechengduxing_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("kechengduxingCard") then return end
	return sgs.Card_Parse("#kechengduxingCard:.:")
end

sgs.ai_skill_use_func["#kechengduxingCard"] = function(card, use, self)
    if not self.player:hasUsed("#kechengduxingCard") then
		local duel = dummyCard("duel")
		duel:setSkillName("kechengduxing")
		local dummy_use = self:aiUseCard(duel, dummy(true, 99))
		if dummy_use.card and dummy_use.to:length() > 0 then
			for _, p in sgs.qlist(dummy_use.to) do
				if self:isEnemy(p) then
					if p:isKongcheng() 
					or ((p:getHp()+p:getHp()+p:getHandcardNum()) < (self.player:getHp()+self.player:getHp()+self.player:getHandcardNum())) then
					use.card = card
						if use.to then
							use.to:append(p)
						end
					end		
				end
			end
		end
	end
end

sgs.ai_use_value.kechengduxingCard = 8.5
sgs.ai_use_priority.kechengduxingCard = 9.5
sgs.ai_card_intention.kechengduxingCard = 66

sgs.ai_ajustdamage_from.kechengzhiheng = function(self, from, to, card, nature)
	if from and card and to:getMark("&kechengzhiheng+#"..from:objectName().."-Clear")>0
	then
		return 1
	end
end

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
	local max_value = 0
	local target
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
		local x = mp-qp
		if self:isEnemy() then
			x = -x
		end
		if x > max_value then
			if (self:isFriend(one) and (mp>=qp) and self:canDraw(one)) or (self:isEnemy(one) and ((mp<qp) or not self:canDraw(one))) then
				max_value = x
            	target = one
			end
        end
	end
	if target then
        use.card = card
        if use.to then
            use.to:append(target)
        end
    end
end

sgs.ai_use_value.kechenglunshiCard = 8.5
sgs.ai_use_priority.kechenglunshiCard = 9.5

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
		if self:isFriend(p) and self:hasSkills(sgs.lose_equip_skill) then
			for _, p2 in ipairs(targets) do
				table.insert(tos, p)
				table.insert(tos, p2)
				return tos
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
	local lord = self.room:getLord()
	if lord and self:isEnemy(lord) then return lord end
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
		if self:isEnemy(p) then
		    return p 
		end
	end
	return nil
end
sgs.exclusive_skill = sgs.exclusive_skill .."|kechengyechou"
sgs.ai_ajustdamage_to.kechengbiaozhao = function(self,from,to,card,nature)
	if from and from:getMark("&kechengbiaozhaoto+#"..to:objectName())>0 and card
	then return 1 end
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

sgs.ai_cardneed.kechengbiaozhao = sgs.ai_cardneed.paoxiao

--吕布
sgs.ai_ajustdamage_from.kechengwuchang = function(self,from,to,card,nature)
	if from and card and (card:isKindOf("Slash") or card:isKindOf("Duel")) and from:getKingdom() == to:getKingdom()
	then return 1 end
end

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
			local chdj = sgs.Sanguosha:cloneCard("_kecheng_chenhuodajie")
			chdj:setSkillName("kechengqingjiao") 
			chdj:addSubcard(card:getEffectiveId())
			chdj:deleteLater()
			for _, enemy in sgs.qlist(enys) do
				if self.player:isProhibited(enemy,chdj) then continue end
				if enemy:isKongcheng() then continue end
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
					--and (self.player:distanceTo(p)<=1)
					and (self.player:getMark("&useqingjiaotxzf-Clear")<1) then
						enys:append(p)
					end
				end
			end
			--挑选最强大的敌人
			local pre = sgs.SPlayerList()
			local txzf = sgs.Sanguosha:cloneCard("_kecheng_tuixinzhifu")
			txzf:setSkillName("kechengqingjiao") 
			txzf:addSubcard(card:getEffectiveId())
			txzf:deleteLater()
			for _, enemy in sgs.qlist(enys) do
				if self.player:isProhibited(enemy,txzf) then continue end
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
		or self:getKeepValue(c,self.kept,true)>5.3
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
	local dc = dummyCard()
	dc:setSkillName("kechengqingxi")
	self.player:setFlags("InfinityAttackRange")
	local d = self:aiUseCard(dc,dummy(true,99))
	self.player:setFlags("-InfinityAttackRange")
	if d.card then
		local cards = self.player:getHandcards()
		cards = sgs.QList2Table(cards)
		self:sortByKeepValue(cards,nil,"j")
		for _,p in sgs.qlist(d.to) do
			if p:getHandcardNum() < self.player:getHandcardNum() and p:getMark("beusekechengqingxi-PlayClear")==0 then
			local n = self.player:getHandcardNum()-p:getHandcardNum()
			if n>0 and #cards>=n then
				local enys = {}
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
		self.player:setFlags("InfinityAttackRange")
		local dc = dummyCard("fire_slash")
		dc:setSkillName("kechengjinmie")
		local d = self:aiUseCard(dc,dummy(true,99))
		self.player:setFlags("-InfinityAttackRange")
		if d.card then
			for _,p in sgs.qlist(d.to) do
				if p:getHandcardNum() > self.player:getHandcardNum() and self:doDisCard(p, "h", false, p:getHandcardNum() - self.player:getHandcardNum()) then
				use.card = card
				if use.to then use.to:append(p) end
				break
				end
			end
		end
	end
end

sgs.ai_use_value.kechengjinmieCard = 8.5
sgs.ai_use_priority.kechengjinmieCard = 2.5
sgs.ai_card_intention.kechengjinmieCard = 80

--张郃
sgs.ai_cardneed.kechengqongtu = function(to,card,self)
	return to:getKingdom() == "qun" and not card:isKindOf("BasicCard")
end

sgs.notActive_cardneed_skill =  sgs.notActive_cardneed_skill .. "|kechengqongtu"

sgs.use_lion_skill = sgs.use_lion_skill.."|kechengqongtu"

sgs.ai_guhuo_card.kechengqongtu = function(self,cname,class_name)
    --if self:getCardsNum(class_name)>0 then return end
	local handcards = self.player:getCards("he")
    handcards = self:sortByKeepValue(handcards) -- 按保留值排序
	for _, h in ipairs(handcards) do
    	if h:getTypeId()~=1 then
			return "#kechengqongtuCard:"..handcards[1]:getEffectiveId()..":"..cname
		end
	end
end

sgs.ai_card_priority.kechengqongtu = function(self,card,v)
	if self.player:getKingdom() == "qun" and card:getSkillName() == "kechengqongtu"
	then return 10 end
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
			if card:isNDTrick() and not (nuzhan_trick)
				and (not isCard("Peach", card, self.player) and not isCard("ExNihilo", card, self.player) and not useAll)
				and (not isCard("Crossbow", card, self.player) or disCrossbow)
				and (self:getUseValue(card) < sgs.ai_use_value.Slash or inclusive or sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, sgs.Sanguosha:cloneCard("slash")) > 0) then
				red_card = card
				break
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

sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .."|kechengxianzhu"

function sgs.ai_cardneed.kechengxianzhu(to, card)
	return to:getKingdom() == "wei" and card:isNDTrick()
end
sgs.ai_card_priority.kechengxianzhu = function(self,card,v)
	if self.player:getKingdom() == "wei" and card:getSkillName() == "kechengxianzhu"
	then return 10 end
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
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .."|kechengnianen"


sgs.hit_skill = sgs.hit_skill.."|kechengguanjue"

--张辽
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill.."|kechengzhengbing"
sgs.use_lion_skill = sgs.use_lion_skill .."|kechengzhengbing"
local kechengzhengbing_skill = {}
kechengzhengbing_skill.name = "kechengzhengbing"
table.insert(sgs.ai_skills, kechengzhengbing_skill)
kechengzhengbing_skill.getTurnUseCard = function(self)
	if (self.player:usedTimes("#kechengzhengbingCard") >= 3) or (self.player:getKingdom() ~= "qun") or (self.player:isKongcheng()) then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	if (self.player:usedTimes("#kechengzhengbingCard") <= 1) then
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
	elseif (self.player:usedTimes("#kechengzhengbingCard") <= 2) then
		if not self:isWeak() and sgs.turncount >= 3 then
			for _, acard in ipairs(cards) do
				if acard:isKindOf("Peach") then
					return sgs.Card_Parse("#kechengzhengbingCard:"..acard:getEffectiveId()..":")
				end
			end
		end
	end
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

sgs.ai_skill_use_func["#kechengzhengbingCard"] = function(card, use, self)
    if (self.player:usedTimes("#kechengzhengbingCard") < 3) then 
        use.card = card
	    return
	end
end

function sgs.ai_cardneed.kechengzhengbing(to, card, self)
	return to:getHandcardNum() <= 3
end

sgs.ai_use_value.kechengzhengbingCard = 8.5
sgs.ai_use_priority.kechengzhengbingCard = 9.5

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
sgs.drawpeach_skill = sgs.drawpeach_skill .. "|kechengtuwei"



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
		if self:isFriend(p) and p:getMaxHp()>=self.player:getMaxHp() and self:canDraw(p) then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if not self:isEnemy(p) and p:getMaxHp()>=self.player:getMaxHp() then
			return p
		end
	end
	for _, p in ipairs(targets) do
		if hasManjuanEffect(p) and p:getMaxHp()>=self.player:getMaxHp() then
			return p
		end
	end
end
sgs.ai_playerchosen_intention["kechengyirang"] = -40

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
sgs.Active_cardneed_skill = sgs.Active_cardneed_skill .."|kechengjixiang"

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
		if self:isFriend(p) and #tos<x and not hasManjuanEffect(p) then
			table.insert(tos, p)
		end
	end
	return tos
end
sgs.notActive_cardneed_skill = sgs.notActive_cardneed_skill .."|kechengcangchu"


sgs.ai_use_revises.kechengshishou = function(self,card,use)
	if card:isKindOf("Analeptic") and self.player:getPhase()==sgs.Player_Play and self.player:hasSkill("kechengshishou") then
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
