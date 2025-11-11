--雷祭！
sgs.ai_skill_invoke.sk_leiji = true

sgs.ai_skill_playerchosen.sk_leiji = function(self, targets)
    local lightning_targets = {}
	for _, e in ipairs(self.enemies) do
	    if not e:hasSkill("hongyan|wuyan") and e:getArmor() ~= "SilverLion" then
		    table.insert(lightning_targets, e)
		end
	end
	return lightning_targets[math.random(1, #lightning_targets)]
end


--权略
sgs.ai_skill_invoke.sk_quanlue = true


--伏射
sgs.ai_skill_invoke.sk_fushe = function(self, data)
    local current = self.room:getCurrent()
	return self:isEnemy(current)
end
sgs.ai_choicemade_filter.skillInvoke.sk_fushe = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local current = self.room:getCurrent()
		sgs.updateIntention(player, current, 50)
	end
end

--暴征
sgs.ai_skill_choice["sk_baozheng"] = function(self, choices, data)
    local dongzhuo = self.room:findPlayerBySkillName("sk_baozheng")
	if self:isEnemy(dongzhuo) then
	    return "discardtwocards"
	end
	return "giveonecard"
end


--资国
local sk_ziguo_skill = {}
sk_ziguo_skill.name = "sk_ziguo"
table.insert(sgs.ai_skills, sk_ziguo_skill)
sk_ziguo_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sk_ziguoCard") then return nil end
	return sgs.Card_Parse("#sk_ziguoCard:.:")
end

sgs.ai_skill_use_func["#sk_ziguoCard"] = function(card, use, self)
    local targets = {}
	for _, player in ipairs(self.friends) do
	    if player:isWounded() then
		    table.insert(targets, player)
		end
	end
	if #targets == 0 then return nil end
	self:sort(targets, "hp")
	use.card = card
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_value["sk_ziguoCard"] = 100
sgs.ai_use_priority["sk_ziguoCard"] = 7
sgs.ai_card_intention["sk_ziguoCard"] = -90

--义舍
local sk_yishe_skill = {}
sk_yishe_skill.name = "sk_yishe"
table.insert(sgs.ai_skills, sk_yishe_skill)
sk_yishe_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sk_yisheCard") then return nil end
	if self:getOverflow() <= 0 then return nil end
	return sgs.Card_Parse("#sk_yisheCard:.:")
end

sgs.ai_skill_use_func["#sk_yisheCard"] = function(card, use, self)
    local targets = {}
	for _, player in ipairs(self.friends_noself) do
	    if player:getHandcardNum() < self.player:getHandcardNum() then
		    table.insert(targets, player)
		end
	end
	if #targets == 0 then return nil end
	self:sort(targets, "hp")
	use.card = card
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_value["sk_yisheCard"] = 100
sgs.ai_use_priority["sk_yisheCard"] = 2
sgs.ai_card_intention["sk_yisheCard"] = -90

--米道
local sk_midao_skill = {}
sk_midao_skill.name = "sk_midao"
table.insert(sgs.ai_skills, sk_midao_skill)
sk_midao_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sk_midaoCard") then return nil end
	return sgs.Card_Parse("#sk_midaoCard:.:")
end

sgs.ai_skill_use_func["#sk_midaoCard"] = function(card, use, self)
	local friend, enemy = 0,0
	for _, player in ipairs(self.friends_noself) do
	    if player:getHandcardNum() > self.player:getHandcardNum() then
			friend = friend + 1
		end
	end
	for _, player in ipairs(self.enemies) do
	    if player:getHandcardNum() > self.player:getHandcardNum() then
			enemy = enemy + 1
		end
	end
	if enemy < friend then return nil end
	use.card = card
end

sgs.ai_use_value["sk_midaoCard"] = 100
sgs.ai_use_priority["sk_midaoCard"] = 4
sgs.ai_card_intention["sk_midaoCard"] = -90

local sk_pudu_skill = {}
sk_pudu_skill.name = "sk_pudu"
table.insert(sgs.ai_skills, sk_pudu_skill)
sk_pudu_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sk_puduCard") then return nil end
	return sgs.Card_Parse("#sk_puduCard:.:")
end

sgs.ai_skill_use_func["#sk_puduCard"] = function(card, use, self)
    local targets = {}
	local friend, enemy = 0,0
	for _, player in ipairs(self.friends_noself) do
	    if player:getHandcardNum() > 0 then
		    table.insert(targets, player)
			friend = friend + player:getHandcardNum()
		end
	end
	for _, player in ipairs(self.enemies) do
	    if player:getHandcardNum() > 0 then
		    table.insert(targets, player)
			enemy = enemy + player:getHandcardNum()
		end
	end
	if enemy < friend then return nil end
	self:sort(targets, "hp")
	use.card = card
end

sgs.ai_use_value["sk_puduCard"] = 100
sgs.ai_use_priority["sk_puduCard"] = 5
sgs.ai_card_intention["sk_puduCard"] = -90

sgs.ai_skill_cardchosen.sk_pudu = function(self, who,flags,reason,method)
	local list = self.room:getAlivePlayers()
	local target
	for _, player in sgs.qlist(list) do
		if player:hasFlag("sk_pudu_target") then
			target = player
            break
		end
	end

	local usable_cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(usable_cards)
	
	if target then 
		if self:isFriend(target) then
			usable_cards = sgs.reverse(usable_cards)
			return usable_cards[1]:getEffectiveId()
		else
			return usable_cards[1]:getEffectiveId()
		end
	end
    return usable_cards[1]:getEffectiveId()
end


--昭心
sgs.ai_skill_invoke.sk_zhaoxin = function(self, data)
    local suits = {"spade", "heart", "club", "diamond"}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if table.contains(suits, c:getSuitString()) then
		    table.removeOne(suits, c:getSuitString())
		end
	end
	return #suits > 0
end


--制合
local sk_zhihe_skill = {}
sk_zhihe_skill.name = "sk_zhihe"
table.insert(sgs.ai_skills, sk_zhihe_skill)
sk_zhihe_skill.getTurnUseCard = function(self)
    if self.player:isKongcheng() then return nil end
	local suits = {}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if not table.contains(suits, c:getSuitString()) then
		    table.insert(suits, c:getSuitString())
		end
	end
	local S = #suits
	if self.player:getHandcardNum() > 2*S then return nil end
	if self.player:hasUsed("#sk_zhiheCard") then return nil end
	return sgs.Card_Parse("#sk_zhiheCard:.:")
end

sgs.ai_skill_use_func["#sk_zhiheCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_value["sk_zhiheCard"] = 100
sgs.ai_use_priority["sk_zhiheCard"] = 4.5


--暴戾
local sk_baoli_skill = {}
sk_baoli_skill.name = "sk_baoli"
table.insert(sgs.ai_skills, sk_baoli_skill)
sk_baoli_skill.getTurnUseCard = function(self, inclusive)
    if #self.enemies == 0 then return nil end
	if self.player:hasUsed("#sk_baoliCard") then return nil end
	return sgs.Card_Parse("#sk_baoliCard:.:")
end

sgs.ai_skill_use_func["#sk_baoliCard"] = function(card, use, self)
    local target
	local targets = {}
	for _, p in ipairs(self.enemies) do
	    if (p:getEquips():isEmpty() or (not p:getJudgingArea():isEmpty())) and self:damageIsEffective(p, sgs.DamageStruct_Normal) and not self:cantbeHurt(p) and self:canDamage(p,self.player,nil)  then
		    table.insert(targets, p)
		end
	end
	if #targets > 0 then
	    self:sort(targets, "hp")
		use.card = card
		target = targets[1]
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_value["sk_baoliCard"] = 100
sgs.ai_use_priority["sk_baoliCard"] = 5
sgs.ai_card_intention["sk_baoliCard"] = 95


--夜袭
sgs.ai_skill_invoke.sk_yexi = function(self, data)
    if self.player:isKongcheng() then return false end
    local targets = self.room:getOtherPlayers(self.player)
	local s = 0
	local k = 0
	for _, t in sgs.qlist(targets) do
	    if self:isFriend(t) then
		    if self.role == "renegade" then k = k + 1 end
		    if sgs.ai_role[t:objectName()]=="renegade" then k = k + 1 end
		    for _, enemy in ipairs(self.enemies) do
			    if self:isWeak(enemy) and enemy:getHp() == 1 and not self:slashProhibit(nil, enemy, t)
				    and (getCardsNum("Jink", enemy, self.player) == 0)
				    and (getCardsNum("Slash", t, self.player) >= 1 or self:getCardsNum("Slash") > 0) then
				    s = s + 1
			    end
			end
		end
		if not self.player:isWounded() and self:isWeak(t) then s = s + 1 end
	end
	return s > 0
end

sgs.ai_skill_playerchosen.sk_yexi = function(self, targets)
    local target
	local tos = {}
	local players = sgs.QList2Table(targets)
	for _, p in ipairs(players) do
	    if self:isFriend(p) then
		    local k = 0
		    for _, enemy in ipairs(self.enemies) do
			    if self:isWeak(enemy) and enemy:getHp() == 1 and not self:slashProhibit(nil, enemy, p)
				    and (not sgs.isJinkAvailable(p, enemy) or getCardsNum("Jink", enemy, self.player) == 0)
				    and (getCardsNum("Slash", p, self.player) >= 1 or self:getCardsNum("Slash") > 0) then
				    k = k + 1
			    end
			end
			if k > 0 then table.insert(tos, p) end
		end
	end
	for _, p in ipairs(players) do
	    if self:isFriend(p) then
		   if (getCardsNum("Slash", p, self.player) >= 1 or self:getCardsNum("Slash") > 0)   then
		   table.insert(tos, p) end
		end
	end
	self:sort(tos, "defense")
	targets = tos[1]
	return target
end
sgs.ai_use_revises["&sk_yexi"] = function(self,card,use)
	if card:isBlack() and card:isKindOf("Slash") and self.player:hasFlag("yexi_blackslash_buff") then
		card:setFlags("Qinggang")
	end
end
sgs.ai_playerchosen_intention.sk_yexi = -40

--花枪
local sk_huaqiang_skill = {}
sk_huaqiang_skill.name = "sk_huaqiang"
table.insert(sgs.ai_skills, sk_huaqiang_skill)
sk_huaqiang_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sk_huaqiangCard") then return nil end
	if #self.enemies == 0 then return nil end
	if self.player:isKongcheng() then return nil end
	return sgs.Card_Parse("#sk_huaqiangCard:.:")
end

sgs.ai_skill_use_func["#sk_huaqiangCard"] = function(card, use, self)
    if #self.enemies == 0 then return nil end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	self:sort(self.enemies, "hp")
	local huaqiang_need = {}
	for _, c in ipairs(cards) do
	    if #huaqiang_need == 0 then
		    table.insert(huaqiang_need, c:getEffectiveId())
		else
		    local can_do = true
			for _, p in ipairs(huaqiang_need) do
			    if c:getSuit() == sgs.Sanguosha:getCard(p):getSuit() then
				    can_do = false
					break
				end
			end
			if can_do then
			    table.insert(huaqiang_need, c:getEffectiveId())
			end
		end
		if #huaqiang_need == math.max(1, self.player:getHp()) then break end
	end
	if #huaqiang_need == math.max(1, self.player:getHp()) then
	    use.card = sgs.Card_Parse("#sk_huaqiangCard:" .. table.concat(huaqiang_need, "+") .. ":")
		if use.to then use.to:append(self.enemies[1]) end
	end
end

sgs.ai_use_value["sk_huaqiangCard"] = 80
sgs.ai_use_priority["sk_huaqiangCard"] = 3.5
sgs.ai_card_intention["sk_huaqiangCard"] = 95


--朝凰
local sk_chaohuang_skill = {}
sk_chaohuang_skill.name = "sk_chaohuang",
table.insert(sgs.ai_skills, sk_chaohuang_skill)
sk_chaohuang_skill.getTurnUseCard = function(self, inclusive)
    local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
    if self.player:isJilei(slash, true) then return nil end
    if #self.enemies == 0 then return nil end
    if self:isWeak() then return nil end
    if self.player:getHp() <= 1 and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") == 0 then return nil end
	if self.player:hasUsed("#sk_chaohuangCard") then return nil end
    return sgs.Card_Parse("#sk_chaohuangCard:.:")
end

sgs.ai_skill_use_func["#sk_chaohuangCard"] = function(card, use, self)
    if #self.enemies <= 0 then return nil end
	local E = 0
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) then E = E + 1 end
	end
	if E == 0 then return nil end
	self:sort(self.enemies, "defense")
	use.card = card
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	if use.to then
		if self.player:getHp() > 1 or (self.player:getHp() == 1 and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 1) then
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, slash, true) and self:slashIsEffective(slash, enemy) and self:objectiveLevel(enemy) > 3 and self:isGoodTarget(enemy, self.enemies, slash) then use.to:append(enemy) end
			end
			assert(use.to:length() > 0)
		end
	end
end

sgs.ai_use_value["sk_chaohuangCard"] = 100
sgs.ai_use_priority["sk_chaohuangCard"] = sgs.ai_use_priority.Slash + 2
sgs.ai_card_intention["sk_chaohuangCard"] = 95


--死谏
sgs.ai_skill_invoke.sk_sijian = function(self, data)
    return self:findPlayerToDiscard()[1]
end

sgs.ai_skill_playerchosen.sk_sijian = function(self, targets)
    local enemies = {}
	local target
	for _, t in sgs.qlist(targets) do
	    if self:isEnemy(t) then table.insert(enemies, t) end
	end
	if #enemies > 0 then
	    self:sort(enemies, "defense")
		target = enemies[1]
	end
	return target
end
sgs.need_kongcheng = sgs.need_kongcheng .. "|sk_sijian"
sgs.ai_playerchosen_intention["sk_sijian"] = 50

--刚直
sgs.ai_skill_invoke.sk_gangzhi = function(self, data)
    if self.player:isKongcheng() then
	    return true
	else
	    if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then return false else return true end
	end
	return false
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|sk_gangzhi"

--忠勇
sgs.ai_skill_invoke.sk_zhongyong = function(self, data)
	if self:isWeak(self.player) then return false end
	if self:willSkipPlayPhase(self.player) then return false end
	for _,card in sgs.qlist(self.player:getHandcards()) do
		if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
			return true
		end
	end
	return false
end

sgs.ai_skill_playerchosen["sk_zhongyong"] = function(self, targets)
	local friends = {}
	for _,p in sgs.qlist(targets) do
		if self:isFriend(p) and self:canDraw(p, self.player) then
			table.insert(friends,p)
		end
	end
	if #friends == 0 then return nil end
	self:sort(friends,"defense")
	return friends[1]
end

sgs.ai_playerchosen_intention["sk_zhongyong"] = -50
--雄异
sgs.ai_skill_invoke.sk_xiongyi = function(self, data)
    if self.player:hasSkill("zhiji") and self.player:isKongcheng() and self.player:getMark("@waked") == 0 then return false end  --没手牌，有【志继】就不要发动
	if self.player:hasSkill("hunzi") and self.player:getHp() == 1 and self.player:getMark("@waked") == 0 then return false end  --体力为1，是孙笨，也别发动
	return true
end


--朝臣
local sk_chaochen_skill = {}
sk_chaochen_skill.name = "sk_chaochen"
table.insert(sgs.ai_skills, sk_chaochen_skill)
sk_chaochen_skill.getTurnUseCard = function(self, inclusive)
    if self.player:isKongcheng() then return nil end
	if self:isWeak() then return nil end
	if #self.enemies == 0 then return nil end
	if self.player:hasUsed("#sk_chaochenCard") then return nil end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if (not cards[1]:isKindOf("Peach")) and (not cards[1]:isKindOf("Analeptic")) then
	    return sgs.Card_Parse("#sk_chaochenCard:"..cards[1]:getEffectiveId()..":")
	else
	    return nil
	end
end

sgs.ai_skill_use_func["#sk_chaochenCard"] = function(card, use, self)
    local target
	for _, enemy in ipairs(self.enemies) do
	    if self:isWeak(enemy) and self:objectiveLevel(enemy) >= 3 and enemy:getHandcardNum() > enemy:getHp() then
		    target = enemy
			break
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if self:willSkipPlayPhase(enemy) and enemy:getHandcardNum() > enemy:getHp() then
			    target = enemy
				break
			end
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if self:isWeak(enemy) and enemy:getHandcardNum() > enemy:getHp() and enemy:getHp() <= 1 and enemy:hasSkills("wansha|tongtian_wansha") then
			    target = enemy
				break
			end
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if enemy:getHandcardNum() > enemy:getHp() and self:damageIsEffective(enemy, sgs.DamageStruct_Normal) and not self:cantbeHurt(enemy) then
			    target = enemy
				break
			end
		end
	end
	if target then
	    if use.to then use.to:append(target) end
		use.card = card
	end
end


sgs.ai_use_value["sk_chaochenCard"] = 70
sgs.ai_use_priority["sk_chaochenCard"] = 3
sgs.ai_card_intention["sk_chaochenCard"] = 80


--全政
sgs.ai_skill_invoke.sk_quanzheng = function(self, data)
    return not self:needKongcheng(self.player, true)
end


--邀名
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

sgs.ai_skill_invoke.sk_yaoming = function(self, data)
    local others = self.room:getOtherPlayers(self.player)
	local players = self.room:getAlivePlayers()
	if self.player:getMark("yaoming") == 1 then return true
	elseif self.player:getMark("yaoming") == 2 then
	    local targets = {}
		for _, _player in sgs.qlist(others) do
		    if self:isEnemy(_player) and (not _player:isNude()) then table.insert(targets, _player) end
		end
		if #targets > 0 then return true end
		return false
	elseif self.player:getMark("yaoming") == 3 then
	    local qiaobian_targets = {}
		for _, target in sgs.qlist(others) do
		    if self:isFriend(target) then
			    if not target:getCards("j"):isEmpty() and not target:containsTrick("YanxiaoCard") and  card_for_qiaobian(self, target, ".") then
				    table.insert(qiaobian_targets, target)
				end
				if not target:getCards("e"):isEmpty() and self:hasSkills(sgs.lose_equip_skill, target) and card_for_qiaobian(self, target, ".") then
				    table.insert(qiaobian_targets, target)
				end
			elseif self:isEnemy(target) then
			    if not target:getCards("j"):isEmpty() and target:containsTrick("YanxiaoCard") and card_for_qiaobian(self, target, ".") then
				    table.insert(qiaobian_targets, target)
				end
				if card_for_qiaobian(self, target, ".") then table.insert(qiaobian_targets, target) end
			end
		end
		if #qiaobian_targets <= 0 then return false else return true end
	elseif self.player:getMark("yaoming") == 4 then
	    local enemies = {}
		for _, t in sgs.qlist(others) do
		    if self:isEnemy(t) then table.insert(enemies, t) end
		end
		return #enemies > 0
	end
end

sgs.ai_skill_playerchosen["yaoming_first"] = function(self, targets)
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

sgs.ai_skill_playerchosen["yaoming_second"] = function(self, targets)
	local who = self.room:getTag("yaomingTarget"):toPlayer()
	if who then
		if not card_for_qiaobian(self, who, "target") then self.room:writeToConsole("NULL") end
		return card_for_qiaobian(self, who, "target")
	end
end


sgs.ai_skill_playerchosen["yaoming_damage"] = function(self, targets)
	local players = {}
	for _, t in sgs.qlist(targets) do
	    if self:isEnemy(t) then table.insert(players, t) end
	end
	if #players > 0 then
	    self:sort(players, "hp")
		return players[1]
	end
end

sgs.ai_skill_playerchosen.sk_yaoming = function(self, targets)
	return self:findPlayerToDiscard()[1]
end
sgs.ai_playerchosen_intention["sk_yaoming"] = 50



--迭嶂
sgs.ai_skill_invoke.sk_diezhang = true

sgs.ai_card_priority.sk_diezhang = function(self,card,v)
	if self.player:getTag("diezhang_point"):toInt()<card:getNumber()
	then return 10 end
end

--捧日
local sk_pengri_skill = {}
sk_pengri_skill.name = "sk_pengri"
table.insert(sgs.ai_skills, sk_pengri_skill)
sk_pengri_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sk_pengriCard") then return nil end
	return sgs.Card_Parse("#sk_pengriCard:.:")
end

-- function SmartAI:isTiaoxinTarget(enemy)
-- 	if not enemy then self.room:writeToConsole(debug.traceback()) return end
-- 	if getCardsNum("Slash", enemy) < 1 and self.player:getHp() > 1 and not self:canHit(self.player, enemy)
-- 		and not (enemy:hasWeapon("double_sword") and self.player:getGender() ~= enemy:getGender())
-- 		then return true end
-- 	if sgs.card_lack[enemy:objectName()]["Slash"] == 1
-- 		or self:needLeiji(self.player, enemy)
-- 		or self:needToLoseHp(self.player, enemy, true)
-- 		then return true end
-- 	if self:getOverflow() and self:getCardsNum("Jink") > 1 then return true end
-- 	return false
-- end

sgs.ai_skill_use_func["#sk_pengriCard"] = function(card, use, self)
    local others = self.room:getOtherPlayers(self.player)
	local distance = use.DefHorse and 1 or 0
	local canslash_count = 0
	local enemy_slash = 0
	local enemy_slashfrom = 0
	for _, t in sgs.qlist(others) do
	    if t:canSlash(self.player, nil, true) then
		    canslash_count = canslash_count + 1
		end
		if self:isEnemy(t) and t:canSlash(self.player, nil, true) then
		    enemy_slash = enemy_slash + 1
		end
		if self:isEnemy(t) and t:distanceTo(self.player, distance) <= t:getAttackRange() then
		    enemy_slashfrom = enemy_slashfrom + 1
		end
	end
	if canslash_count == 0 then  --没有人能砍得到你的话，直接捧日就行了，白摸两张牌何乐而不为？
	    use.card = card
	else
	    if enemy_slash == 0 then  --能砍得到你的都是队友的话，那也可以白摸两张牌
		    use.card = card
		else
		    if self:getCardsNum("Jink") >= enemy_slashfrom then
			    use.card = card
			end
		end
	end
	if math.random(1, 100) >= 40 then use.card = card end  --老子就是喜欢浪，你来砍我啊
end


sgs.ai_use_value["sk_pengriCard"] = 80
sgs.ai_use_priority["sk_pengriCard"] = 7

sgs.ai_skill_cardask["@pengri-slash"] = function(self, data, pattern, target)
	if target then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:isFriend(target) then
				return "."
			end
			if not self:isFriend(target) and self:slashIsEffective(slash, target)
				 and not self:needLeiji(target, self.player) then
					return slash:toString()
			end
		end
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:isFriend(target) then
				if not self:needLeiji(target, self.player) then return slash:toString() end
				if not self:slashIsEffective(slash, target) then return slash:toString() end
			end
		end
	end
	return "."
end


--胆谋
sgs.ai_skill_invoke.sk_danmou = function(self, data)
    local damage = data:toDamage()
	if damage.from:getHandcardNum() < self.player:getHandcardNum() then return false end
	if self:isFriend(damage.from) then return false end
	if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then return false end
	if damage.from:isKongcheng() then return false end
	return damage.from:getHandcardNum() >= self.player:getHandcardNum()
end

sgs.ai_can_damagehp.sk_danmou = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from) and (from:getHandcardNum() - self.player:getHandcardNum() > 2)
	end
end

--恭慎
local sk_gongshen_skill = {}
sk_gongshen_skill.name = "sk_gongshen"
table.insert(sgs.ai_skills, sk_gongshen_skill)
sk_gongshen_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getCards("he"):length() < 3 then return nil end
	return sgs.Card_Parse("#sk_gongshenCard:.:")
end


sgs.ai_skill_use_func["#sk_gongshenCard"] = function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local gongshen = {}
	for _, c in ipairs(cards) do
	    table.insert(gongshen, c:getEffectiveId())
		if #gongshen == 3 then break end
	end
	if #gongshen < 3 then return nil end
	use.card = sgs.Card_Parse("#sk_gongshenCard:" .. table.concat(gongshen, "+") .. ":")
end


sgs.ai_use_value["sk_gongshenCard"] = 6.5
sgs.ai_use_priority["sk_gongshenCard"] = sgs.ai_use_priority.Peach - 1


--俭约
sgs.ai_skill_invoke.sk_jianyue = function(self, data)
    local current = self.room:getCurrent()
	return self:isFriend(current)
end
sgs.ai_choicemade_filter.skillInvoke.sk_jianyue = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if promptlist[#promptlist] == "yes" and current and current:isAlive() then
		sgs.updateIntention(player, current, -50)
	end
end

--随骥
sgs.ai_skill_use["@@sk_suiji"] = function(self, prompt)
    local current = self.room:getCurrent()
	if current:getHandcardNum() <= current:getHp() then return "." end
	if self.player:isKongcheng() then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if current:getHandcardNum() >= current:getHp() + 1 then
	    return "#sk_suijiCard:" .. cards[1]:getEffectiveId() .. ":" .. "->" .. "."
	end
end


--凤仪
sgs.ai_skill_invoke.sk_fengyi = true


--裨补
sgs.ai_skill_invoke.sk_bibu = function(self, data)
    if self.player:getHandcardNum() <= math.max(1, self.player:getHp()) then return true end
	local current = self.room:getCurrent()
	if self.player:getHandcardNum() > math.max(1, self.player:getHp()) and self:isFriend(current) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sk_bibu = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if promptlist[#promptlist] == "yes" and current and current:isAlive() then
		sgs.updateIntention(player, current, -50)
	end
end

--匡正
function canKuangzhengFriend(target)
    if target:isChained() then return true end
	if target:isAlive() and not target:faceUp() then return true end
	if target:getMark("@duanchang") > 0 then return true end
	return false
end

sgs.ai_skill_invoke.sk_kuangzheng = function(self, data)
    local x = 0
	for _, t in sgs.qlist(self.room:getAlivePlayers()) do
	    if self:isFriend(t) and canKuangzhengFriend(t) then x = x + 1 end
	end
	return x > 0
end

sgs.ai_skill_playerchosen.sk_kuangzheng = function(self, targets)
    local kuangzheng = {}
	for _, t in sgs.qlist(targets) do
	    if self:isFriend(t) and canKuangzhengFriend(t) then table.insert(kuangzheng, t) end
	end
	if #kuangzheng > 0 then
	    return kuangzheng[math.random(1, #kuangzheng)]
	end
	return
end
sgs.ai_playerchosen_intention["sk_kuangzheng"] = -50

--舌剑
local sk_shejian_skill = {}
sk_shejian_skill.name = "sk_shejian"
table.insert(sgs.ai_skills, sk_shejian_skill)
sk_shejian_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getArmor() ~= nil then return nil end
	if self.player:isNude() then return nil end
	if self:isWeak() then return nil end
	return sgs.Card_Parse("#sk_shejianCard:.:")
end


sgs.ai_skill_use_func["#sk_shejianCard"] = function(card, use, self)
    local target
	if #self.enemies > 0 then
	    for _, enemy in ipairs(self.enemies) do
		    if self:isTiaoxinTarget(enemy) and not enemy:hasFlag("shejian_used") and not enemy:isNude() then
			    target = enemy
				break
			end
		end
		if not target then
		    for _, enemy in ipairs(self.enemies) do
		        if not enemy:canSlash(self.player, false) and not enemy:hasFlag("shejian_used") and not enemy:isNude() then
			        target = enemy
				    break
			    end
		    end
		end
		if not target then
		    for _, enemy in ipairs(self.enemies) do
		        if self:objectiveLevel(enemy) > 3 and not enemy:hasFlag("shejian_used") and enemy:getHandcardNum() >= 2*self.player:getHandcardNum() + 1 then
			        target = enemy
				    break
			    end
		    end
		end
	end
	if not target and #self.friends_noself > 0 then
	    local max_x = 0
	    local AssistTarget = self:AssistTarget()
		for _, friend in ipairs(self.friends_noself) do
		    if not friend:hasFlag("shejian_used") and not friend:isNude()then
			    local x = math.min(friend:getMaxHp(), 5) - friend:getHandcardNum()
		        if friend:hasSkill("manjuan") then x = x + 1 end
		        if AssistTarget and friend:objectName() == AssistTarget:objectName() then x = x + 0.5 end
		        if x > max_x and friend:isAlive() then
		            max_x = x
				    target = friend
				end
	        end
	    end
	end
	if target then
	    use.card = card
		if use.to then use.to:append(target) end
	end
end


sgs.ai_use_value["sy_shejianCard"] = 75
sgs.ai_use_priority["sy_shejianCard"] = 5.2


sgs.ai_skill_choice.sk_shejian = function(self, choices, data)
    local miheng = self.room:findPlayerBySkillName("sk_shejian")
	if self:isFriend(miheng) then return "useslashtomiheng" end
	if self:isEnemy(miheng) then
	    if self.player:getHandcardNum() >= 2*miheng:getHandcardNum() then
		    if self:objectiveLevel(miheng) > 3 then return "useslashtomiheng" else return "cancel" end
		end
	end
	if not self:isFriend(miheng) then return "useslashtomiheng" end
	return "useslashtomiheng"
end


--狂傲
sgs.ai_skill_invoke.sk_kuangao = function(self, data)
	local slasher = data:toPlayer()
    if self:isFriend(slasher) then return true end
	if self:isEnemy(slasher) then
		if self.player:isNude() then return false end
	    if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 0 and slasher:getCards("he"):length() >= 2*self.player:getCards("he"):length() then return true end
		if slasher:getCards("he"):length() >= 2.5*self.player:getCards("he"):length() then return true end
	end
	return false
end

sgs.ai_skill_choice.sk_kuangao = function(self, choices, data)
    local slasher = data:toPlayer()
	if slasher and self:isFriend(slasher) then return "kuangao_draw" end
	if slasher and self:isEnemy(slasher) then return "kuangao_discard" end
end

sgs.ai_choicemade_filter.skillChoice["sk_kuangao"] = function(self, player, promptlist)
	local choice = promptlist[#promptlist]
	local target
	local list = self.room:getAlivePlayers()
	for _, p in sgs.qlist(list) do
		if p:hasFlag("kuangao_target") then
			target = p
		end
	end
	if choice == "kuangao_draw" and target then
		sgs.updateIntention(player, target, -80)
	end
	if choice == "kuangao_discard" and target then
		sgs.updateIntention(player, target, 80)
	end
end



--奋威
sgs.ai_skill_invoke.sk_fenwei = function(self, data)
    local damage = data:toDamage()
	local nature = damage.nature
	if not damage.to:getArmor() ~= "SilverLion" and self:isEnemy(damage.to) and self:damageIsEffective(damage.to, nature) then
	    return true
	end
	return false
end
sgs.ai_cardneed.sk_fenwei = sgs.ai_cardneed.slash

sgs.bad_skills = sgs.bad_skills .. "|sk_shiyong"


sgs.ai_skill_cardask["@cangshu-give"] = function(self, data, pattern, target, target2)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	if self:isFriend(target) then return "." end
		local use = data:toCardUse()
		if use.card and use.card:isVirtualCard() then return "." end
	self:sortByKeepValue(handcards)
	local give_cards = {}
	for _, c in ipairs(handcards) do
		if c:isKindOf("BasicCard") then
			table.insert(give_cards, c)
			break
		end
	end
	if #give_cards > 0 then
		return give_cards[1]:toString()
	end
	return "."
end

sgs.ai_guhuo_card.sk_kanwu = function(self,toname,class_name)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValue(cards) -- 按保留值排序
   	for d,c in sgs.list(cards)do
       	d = dummyCard(toname)
        if c:getTypeId()~=1
       	and d:isKindOf("BasicCard") and self:getCardsNum(class_name)<1
		and (sgs.Sanguosha:getCurrentCardUseReason()==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or sgs.Sanguosha:getCurrentCardUseReason()== sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
      	then return "#sk_kanwu:"..c:getEffectiveId()..":"..toname end
   	end
end

--引兵
function CountSuit(zumao, suit)
	local cards = zumao:getHandcards()
	local x = 0
	for _, c in sgs.qlist(cards) do
		if c:getSuit() == suit then
			x = x + 1
		end
	end
	return x
end

function SmartAI:getYinbingValue(zumao)
	local n = 0
	if zumao:isNude() then return 0 end
	if not zumao:isWounded() then return 0 end
	if zumao:hasSkill("manjuan") and zumao:getPhase() == sgs.Player_NotActive then return -1 end
	n = n + math.max(zumao:getHandcardNum()-1, 0) + zumao:getLostHp()
	if zumao:hasSkill("jiuchi") then
		if CountSuit(zumao, sgs.Card_Spade) > 1 then
			n = n + math.max(zumao:getHandcardNum()-1, 0) + zumao:getLostHp()
		end
	end
	if zumao:hasSkill("jijiu") and zumao:getPhase() == sgs.Player_NotActive then
		if CountSuit(zumao, sgs.Card_Heart) + CountSuit(zumao, sgs.Card_Diamond) > 1 then
			n = n + math.max(zumao:getHandcardNum()-1, 0) + zumao:getLostHp()
		end
	end
	if zumao:hasSkill("jiushi") and zumao:faceUp() then
		n = n + math.max(zumao:getHandcardNum()-1, 0) + zumao:getLostHp()
	end
	if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 1 then
		n = n + math.max(zumao:getHandcardNum()-1, 0) + zumao:getLostHp()
	end
	if zumao:hasSkill("chunlao") and zumao:getPile("wine"):length() > 0 then
		n = n + math.max(zumao:getHandcardNum()-1, 0) + zumao:getLostHp()
	end
	if zumao:hasSkills("longhun|sgkgodlonghun") and CountSuit(zumao, sgs.Card_Heart) > 1 then
		n = n + math.max(zumao:getHandcardNum()-1, 0) + zumao:getLostHp()
	end
	return n
end

sgs.ai_skill_invoke.sk_yinbing = function(self, data)
	local t = data:toPlayer()
	if self.player:inMyAttackRange(t) and (not t:getEquips():isEmpty()) and (not self:isEnemy(t)) then
		if self:getYinbingValue(self.player) >= 2 then return true else return false end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sk_yinbing = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end
sgs.ai_skill_invoke.sk_yinbing_draw = true

--衡势
sgs.ai_skill_invoke.sk_hengshi = true


--至交
sgs.ai_skill_playerchosen.sk_zhijiao = function(self, targets)
	local room = self.room
	if self.player:getMark("@zhijiao") == 0 then return nil end
	local target
	if #self.friends_noself == 0 then return nil end
	local tag = self.player:getMark("zhijiao_count")
	local n = tag
	if n >= 8 then
		for _, p in sgs.qlist(targets) do
			if self:isFriend(p) then
				if p:hasSkills("shuangxiong|sgkgodshayi|paoxiao|fuhun|huoji|yeyan|sgkgodyeyan|sgkgodtongtian|sk_quanlue|sgkgodwushen|longhun|sgkgodlonghun|sgkgodjilue") and not p:hasSkill("manjuan") then
					target = p
					break
				end
			end
		end
		if not target then
			for _, p in sgs.qlist(targets) do
				if self:isWeak(p) and p:getJudgingArea():isEmpty() and self:isFriend(p) then
					target = p
					break
				end
			end
		end
		if not target then
			for _, p in sgs.qlist(targets) do
				if self:hasCrossbowEffect(p) and self:isFriend(p) then
					target = p
					break
				end
			end
		end
		if not target then
			for _, p in sgs.qlist(targets) do
				if self:isFriend(p) then
					target = p
					break
				end
			end
		end
	end
	if target then
		return target
	else
		return nil
	end
end


--刀侍
sgs.ai_skill_invoke.sk_daoshi = function(self, data)
	local zhoucang = data:toPlayer()
	return self:isFriend(zhoucang)
end


--狂斧
sgs.ai_skill_invoke.sk_kuangfu = function(self, data)
	local to = data:toPlayer()
	return self:isEnemy(to)
end
sgs.ai_cardneed.sk_kuangfu = sgs.ai_cardneed.slash

--虎步
sgs.ai_skill_playerchosen.sk_hubu = function(self, targets)
	local room = self.room
    local duel = sgs.Sanguosha:cloneCard("duel", sgs.Card_NoSuit, 0)
	duel:deleteLater()
	if self.player:hasSkill("wuyan") and not self.player:hasSkill("jueqing") then return end
	if self.player:hasSkill("noswuyan") then return end
	local enemies = self:exclude(self.enemies, duel)
	local friends = self:exclude(self.friends_noself, duel)
	duel:setFlags("AI_Using")
	local n1 = self:getCardsNum("Slash")
	duel:setFlags("-AI_Using")
	if self.player:hasSkill("wushuang") then
		n1 = n1 * 2
	end
	local targets = {}
	local canUseDuelTo = function(target)
		return self:hasTrickEffective(duel, target) and self:damageIsEffective(target,sgs.DamageStruct_Normal) and not self.room:isProhibited(self.player, target, duel)
		--排除神曹操
		and not (target:hasSkill("guixin") and target:getHp() > 1 and sgs.turncount <= 1 and not self.player:hasSkill("jueqing"))
	end
	for _, enemy in ipairs(enemies) do
		if canUseDuelTo(enemy) then
			table.insert(targets, enemy)
		end
	end
	local cmp = function(a, b)
		local v1 = getCardsNum("Slash", a) + a:getHp()
		local v2 = getCardsNum("Slash", b) + b:getHp()

		if a:isKongcheng() then v1 = v1 - 20 end
		if b:isKongcheng() then v2 = v2 - 20 end

		if not self:isWeak(a) and a:hasSkill("jianxiong") and not self.player:hasSkill("jueqing") then v1 = v1 + 10 end
		if not self:isWeak(b) and b:hasSkill("jianxiong") and not self.player:hasSkill("jueqing") then v2 = v2 + 10 end

		if self:needToLoseHp(a) then v1 = v1 + 5 end
		if self:needToLoseHp(b) then v2 = v2 + 5 end

		if self:hasSkills(sgs.masochism_skill, a) then v1 = v1 + 5 end
		if self:hasSkills(sgs.masochism_skill, b) then v2 = v2 + 5 end

		if not self:isWeak(a) and a:hasSkill("jiang") then v1 = v1 + 5 end
		if not self:isWeak(b) and b:hasSkill("jiang") then v2 = v2 + 5 end

		if a:hasLordSkill("jijiang") then v1 = v1 + self:JijiangSlash(a) * 2 end
		if b:hasLordSkill("jijiang") then v2 = v2 + self:JijiangSlash(b) * 2 end

		if v1 == v2 then return self:getDefenseSlash(a) < self:getDefenseSlash(b) end

		return v1 < v2
	end
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		local useduel
		local n2 = getCardsNum("Slash", enemy)
		if enemy:hasSkill("wushuang") then n2 = n2 * 2 end
		useduel = n1 >= n2 or self:needToLoseHp(self.player, nil, nil, true)  or (n2 < 1 and sgs.isGoodHp(self.player))
		if self:objectiveLevel(enemy) >= 3 and canUseDuelTo(enemy) and not self:cantbeHurt(enemy) and useduel and self:isGoodTarget(enemy, enemies, nil) then
			if not table.contains(targets, enemy) then table.insert(targets, enemy) end
		end
	end
	for _, enemy in ipairs(enemies) do
		if self.player:getHandcardNum() >= 1.5 * enemy:getHandcardNum() or enemy:isKongcheng() then
			if canUseDuelTo(enemy) and not table.contains(targets, enemy) then table.insert(targets, enemy) end
		end
	end
	if #targets > 0 then
		return targets[1]
	else
	    return nil
	end
end


--惠敛
local sk_huilian_skill = {}
sk_huilian_skill.name = "sk_huilian"
table.insert(sgs.ai_skills, sk_huilian_skill)
sk_huilian_skill.getTurnUseCard = function(self, inclusive)
	if not self.player:hasUsed("#sk_huilian") then
		return sgs.Card_Parse("#sk_huilian:.:")
	end
end

sgs.ai_skill_use_func["#sk_huilian"] = function(card, use, self)
	self:updatePlayers()
	self:sort(self.friends_noself, "hp")
	self.friends = sgs.reverse(self.friends_noself)
	local target = nil
	for _, friend in ipairs(self.friends_noself) do
		if friend:isWounded() or friend:getHp() <= 3 then
			target = friend
		end
	end
	if target == nil then return end
	use.card = card
	if use.to then use.to:append(target) end
end


sgs.ai_use_priority["sk_huilian"] = 7.2
sgs.ai_use_value["sk_huilian"] = 7.2
sgs.ai_card_intention["sk_huilian"] = -50


--礼让
local sk_lirang_skill = {}
sk_lirang_skill.name = "sk_lirang"
table.insert(sgs.ai_skills, sk_lirang_skill)
sk_lirang_skill.getTurnUseCard = function(self)
	local gift = self.player:getPile("gift")
	local giftids = {}
	for _, id in sgs.qlist(gift) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(giftids, card:getEffectiveId())
		if #giftids == 2 then break end
	end
	if #giftids < 2 or (not self.player:isWounded()) then return nil end
	local lirang_peach = sgs.Card_Parse("#sk_lirang:" .. table.concat(giftids, "+") .. ":" .. "peach")
	return lirang_peach
end

sgs.ai_skill_use_func["#sk_lirang"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local lirang_peach = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	lirang_peach:setSkillName("sk_lirang")
	self:useBasicCard(lirang_peach, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_view_as["sk_lirang"] = function(card, player, card_place)
	local gift = player:getPile("gift")
	local giftids = {}
	for _, id in sgs.qlist(gift) do
		local card = sgs.Sanguosha:getCard(id)
		table.insert(giftids, card:getEffectiveId())
		if #giftids == 2 then break end
	end
	if #giftids >= 2 then return ("peach:sk_lirang[%s:%s]=%d+%d"):format(sgs.Card_NoSuit, 0, giftids[1], giftids[2]) end
end

sgs.ai_skill_cardask["@lirang_to"] = function(self, data, pattern)
	local kongrong = data:toPlayer()
	if not self:isFriend(kongrong) then return "." end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
		then return h:getEffectiveId() end
		if h:isKindOf(pattern)
		then return h:getEffectiveId() end
	end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@lirang_to"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
	local dest
	for _, aplayer in sgs.qlist(self.room:getAlivePlayers()) do
		if aplayer:hasFlag("lirang_Target") then dest = aplayer break end
	end
	if dest then 
		sgs.updateIntention(player, dest, -40)
		end
	end
end

--贤士
sgs.ai_skill_invoke.sk_xianshi = function(self, data)
	local damage = data:toDamage()
	if damage.from and self:isFriend(damage.from) and self:isWeak() then return true end
	if not self:needToLoseHp(damage.from, self.player) then return true end
	return true
end

sgs.ai_skill_cardask["@xianshi-discard"] = function(self, data, pattern)
	local damage = data:toDamage()
	if self:isFriend(damage.to) then
		return "."
	else
		local cards = sgs.QList2Table(self.player:getCards("h"))
		self:sortByKeepValue(cards)
		local acard
		for _, c in ipairs(cards) do
			if not c:isKindOf("Peach") then
				acard = c
				break
			end
		end
		if acard then
			return "$" .. acard:getEffectiveId()
		else
			return "."
		end
	end
end


--义谏
sgs.ai_skill_playerchosen.sk_yijian = function(self, targets)
	if self.player:isWounded() then
		local who = {}
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() + 1 >= self.player:getHandcardNum() then table.insert(who, friend) end
		end
		if #who > 0 then
			self:sort(who, "hp")
			who = sgs.reverse(who)
			return who[1]
		else
			return nil
		end
	else
		return nil
	end
end
sgs.ai_playerchosen_intention.sk_yijian = -20
sgs.double_slash_skill = sgs.double_slash_skill .. "|sk_feijun"
sgs.ai_cardneed.sk_feijun = sgs.ai_cardneed.slash
--延粮
sgs.ai_skill_cardask["@yanliang_card"] = function(self, data, pattern, target, target2)
	if self.player:isNude() then return "." end
	if self:isWeak(self.player) then return "." end
	local room = self.player:getRoom()
	local player = data:toPlayer()
	if not player or player:isDead() then return false end
	if player:containsTrick("supply_shortage") then return "." end
	local black,red = {},{}
	for _,c in sgs.qlist(self.player:getCards("he")) do
		if c:isRed() then
			table.insert(red,c)
		elseif c:isBlack() then
			table.insert(black,c)
		end
	end
	if self:isFriend(player) then
		if #black == 0 then return "." end
		self:sortByKeepValue(black)
		if player:getHandcardNum() - player:getHp() >= 2 then
			return black[1]:toString()
		end
		return "."
	else
		if #red == 0 then return "." end
		if player:getHp()< 2 or player:getHandcardNum()<= 1 then
			return red[1]:toString()
		end
	end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@yanliang_card"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, 80)
	end
end

--才捷
sgs.ai_skill_invoke.sk_caijie = function(self, data)
	local player = data:toPlayer()
	local max_card = self:getMaxCard()
	if max_card then
		local max_point = max_card:getNumber()
		if max_point >= 10 and self:isFriend(player) then return true end
		if self:getCardsNum("Analeptic") + self:getCardsNum("Peach") >= 2 and self:isEnemy(player) and player:getHandcardNum() >= 1.5*self.player:getHandcardNum() then
			return true
		end
		if max_point >= 12 and self:isEnemy(player) then
			return true
		end
		if max_point == 13 then return true end
	end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sk_caijie = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if promptlist[#promptlist] == "yes" then
		if current then
			sgs.updateIntention(player, current, 40)
		end
	end
end
sgs.ai_cardneed.sk_caijie = sgs.ai_cardneed.bignumber

--鸡肋
sgs.ai_skill_invoke.sk_jilei = function(self, data)
	local who = data:toPlayer()
	return self:isEnemy(who)
end
sgs.ai_choicemade_filter.skillInvoke.sk_jilei = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,50) end
	end
end

--整毅
function can_zhengyi_inturn(player)
	if player:getPhase() ~= sgs.Player_NotActive then
		return player:getHandcardNum() - (math.max(0, player:getHp())) == 1 or (player:getHandcardNum() == math.max(0, player:getHp()) and player:getEquips():length() > 0)
	end
end

function can_zhengyi_outturn(player)
	if player:getPhase() == sgs.Player_NotActive then
		return math.max(0, player:getHp()) - player:getHandcardNum() == 1
	end
end

local sk_zhengyi_skill = {}
sk_zhengyi_skill.name = "sk_zhengyi"
table.insert(sgs.ai_skills, sk_zhengyi_skill)
sk_zhengyi_skill.getTurnUseCard = function(self)
	self:updatePlayers()
	if can_zhengyi_inturn(self.player) then
		if self.player:isWounded() then
			return sgs.Card_Parse("#sk_zhengyi:.:" .. "peach")
		end
		local slash = sgs.Sanguosha:cloneCard("slash")
		slash:deleteLater()
		if self:getCardsNum("Slash") > 1 and not slash:isAvailable(self.player) then
			for _, enemy in ipairs(self.enemies) do
				if ((enemy:getHp() < 3 and enemy:getHandcardNum() < 3) or (enemy:getHandcardNum() < 2)) and self.player:canSlash(enemy) and not self:slashProhibit(slash, enemy, self.player)
					and self:slashIsEffective(slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, nil) then
					return sgs.Card_Parse("#sk_zhengyi:.:" .. "analeptic")
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and self:isGoodTarget(enemy, self.enemies, nil) then
				local thunder_slash = sgs.Sanguosha:cloneCard("thunder_slash")
				thunder_slash:deleteLater()
				local fire_slash = sgs.Sanguosha:cloneCard("fire_slash")
				fire_slash:deleteLater()
				if  not self:slashProhibit(fire_slash, enemy, self.player)and self:slashIsEffective(fire_slash, enemy, self.player) then
					return sgs.Card_Parse("#sk_zhengyi:.:" .. "fire_slash")
				end
				if not self:slashProhibit(thunder_slash, enemy, self.player)and self:slashIsEffective(thunder_slash, enemy, self.player) then
					return sgs.Card_Parse("#sk_zhengyi:.:" .. "thunder_slash")
				end
				if not self:slashProhibit(slash, enemy, self.player)and self:slashIsEffective(slash, enemy, self.player) then
					return sgs.Card_Parse("#sk_zhengyi:.:" .. "slash")
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#sk_zhengyi"] = function(card, use, self)
	local userstring = card:toString()
	userstring = (userstring:split(":"))[4]
	local zhengyi_card = sgs.Sanguosha:cloneCard(userstring, card:getSuit(), card:getNumber())
	zhengyi_card:setSkillName("sk_zhengyi")
	self:useBasicCard(zhengyi_card, use)
	if not use.card then return end
	use.card = card
end


sgs.ai_use_priority["sk_zhengyi"] = 8
sgs.ai_use_value["sk_zhengyi"] = 8


sgs.ai_view_as["sk_zhengyi"] = function(card, player, card_place, class_name)
	if sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and can_zhengyi_outturn(player) then
		local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash"
		}
		local name = classname2objectname[class_name]
		if not name then return end
		return string.format(name..":sk_zhengyi[%s:%s]=.", sgs.Card_NoSuit, 0)
	end
end

sgs.ai_cardneed.sk_jiwu = sgs.ai_cardneed.slash

sgs.ai_skill_use["@@sk_jiwu"] = function(self, prompt)
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if c:isKindOf("Slash") then
			return "#sk_jiwu:" .. c:getEffectiveId().. ":"
		end
	end
		
	return "."
end
sgs.ai_ajustdamage_from.sk_jiwu = function(self, from, to, card, nature)
	if card and card:isKindOf("Slash") and card:hasFlag("llq_jiwu_damage")
	then
		return 1
	end
end



--贞烈
sgs.ai_skill_invoke.sk_zhenlie = function(self, data)
	local use = data:toCardUse()
	if not use.from or use.from:isDead() then return false end
	if self.role == "rebel" and sgs.ai_role[use.from:objectName()] == "rebel" and not use.from:hasSkill("jueqing")
		and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then return false end
	if self:isEnemy(use.from) or (self:isFriend(use.from) and self.role == "loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord() and self.player:getHp() == 1) then
		if use.card:isKindOf("Slash") then
			if not self:slashIsEffective(use.card, self.player, use.from) then return false end
			if self:hasHeavyDamage(use.from, use.card, self.player) then return true end
			local jink_num = self:getExpectedJinkNum(use)
			local hasHeart = false
			for _, card in ipairs(self:getCards("Jink")) do
				if card:getSuit() == sgs.Card_Heart then
					hasHeart = true
					break
				end
			end
			if self:getCardsNum("Jink") == 0
				or jink_num == 0
				or self:getCardsNum("Jink") < jink_num
				or (use.from:hasSkill("dahe") and self.player:hasFlag("dahe") and not hasHeart) then

				if use.card:isKindOf("NatureSlash") and self.player:isChained() and not self:isGoodChainTarget(self.player, use.from, nil, nil, use.card) then return true end
				if use.from:hasSkill("nosqianxi") and use.from:distanceTo(self.player) == 1 then return true end
				if self:isFriend(use.from) and self.role == "loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord() and self.player:getHp() == 1 then return true end
				if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or use.from:hasSkill("jueqing"))
					and self:doDisCard(use.from) then
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
			for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
				if self:isFriend(p) then friend_null = friend_null + getCardsNum("Nullification", p, self.player) end
				if self:isEnemy(p) then friend_null = friend_null - getCardsNum("Nullification", p, self.player) end
			end
			friend_null = friend_null + self:getCardsNum("Nullification")
			local sj_num = self:getCardsNum(use.card:isKindOf("SavageAssault") and "Slash" or "Jink")

			if not self:hasTrickEffective(use.card, self.player, from) then return false end
			if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, from) then return false end
			if use.from:hasSkill("drwushuang") and self.player:getCardCount() == 1 and self:hasLoseHandcardEffective() then return true end
			if sj_num == 0 and friend_null <= 0 then
				if self:isEnemy(from) and from:hasSkill("jueqing") then return self:doDisCard(from) end
				if self:isFriend(from) and self.role == "loyalist" and from:isLord() and self.player:getHp() == 1 and not from:hasSkill("jueqing") then return true end
				if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or use.from:hasSkill("jueqing"))
					and self:doDisCard(use.from) then
					return true
				end
			end
		elseif self:isEnemy(use.from) then
			if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
					if not self:hasTrickEffective(use.card, self.player) then return false end
				if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, use.from) then return false end
				if (self.player:hasArmorEffect("vine") or self.player:getMark("@gale") > 0) and use.from:getHandcardNum() > 3
					and not (use.from:hasSkill("hongyan") and getKnownCard(self.player, self.player, "spade") > 0) then
					return self:doDisCard(use.from)
				elseif self.player:isChained() and not self:isGoodChainTarget(self.player, use.from) then
					return self:doDisCard(use.from)
				end
			elseif (use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement"))
					and self:getCardsNum("Peach") == self.player:getHandcardNum() and not self.player:isKongcheng() then
				if not self:hasTrickEffective(use.card, self.player) then return false end
				return self:doDisCard(use.from)
			elseif use.card:isKindOf("Duel") then
				if self:getCardsNum("Slash") == 0 or self:getCardsNum("Slash") < getCardsNum("Slash", use.from, self.player) then
					if not self:hasTrickEffective(use.card, self.player) then return false end
					if not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, use.from) then return false end
					return self:doDisCard(use.from)
				end
			elseif use.card:isKindOf("TrickCard") and not use.card:isKindOf("AmazingGrace") then
				if self:doDisCard(use.from) and self:needToLoseHp(self.player) then
					return true
				end
			end
		end
	end
	return false
end

sgs.ai_skill_cardask["@zhenlie-discard"] = function(self, data)
	local who = data:toPlayer()
	if not self:isEnemy(who) then return "." end
	local cards = self.player:getCards("he")
	self:sortByKeepValue(cards)
	for _, c in sgs.qlist(cards) do
		if not c:isKindOf("Peach") and (not c:isKindOf("Analeptic")) then
			return "$" .. c:getEffectiveId()
		end
	end
end


--秘计
sgs.ai_skill_invoke.sk_miji = true

sgs.ai_skill_playerchosen["sk_miji"] = function(self, targets)
	self:updatePlayers()
	self:sort(self.friends, "handcard")
	local can_give_friend = {}
	for _, friend in ipairs(self.friends) do
		if not hasManjuanEffect(friend) and not self:isLihunTarget(friend) then
			table.insert(can_give_friend, friend)
		end
	end
	if #can_give_friend > 0 then return can_give_friend[1] end
end
sgs.ai_playerchosen_intention.sk_miji = -50

--咒缚
sgs.ai_skill_cardask["@zhoufu"] = function(self, data)
	local current = self.room:getCurrent()
	if self:isEnemy(current) then
		local cards = self.player:getCards("h")
		self:sortByKeepValue(cards)
		for _, c in sgs.qlist(cards) do
			if not c:isKindOf("Peach") and (not c:isKindOf("Analeptic")) then
				return "$" .. c:getEffectiveId()
			end
		end
	end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@zhoufu"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		sgs.updateIntention(player, current, 80)
	end
end

--影兵
sgs.ai_skill_invoke["sk_yingbing"] = function(self, data)
	local player = data:toPlayer()
	return self:isEnemy(player)
end