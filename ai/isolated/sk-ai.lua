-- sk fixed b6025acc. Preserve source policy quirks and ordered material selection.
local function known(v,k)if AIUnsupported.is(v)then error(v,0)end;if v==nil then ai_unsupported('sk input unknown',k)end;return v end
local nullable={toPlayer=true,getLord=true,getCurrent=true,getArmor=true,getWeapon=true,getMaxCard=true,getSameEquip=true,findPlayerBySkillName=true,findPlayerByObjectName=true,AssistTarget=true,useBasicCard=true,updatePlayers=true,updateIntention=true,setStrategyCardFlag=true,writeToConsole=true}

local function own_ai(p)local a=p._room and p._room._ai;if not a or p~=a.player then ai_unsupported('sk view-as material is not owner-authorized','sk.view_as')end;return a end
local function face(self,id)return self:getKnownCardById(id)end
local function seed(self,wire)
 local cls,raw,user=wire:match('^#(sk_[%w_]+):([^:]*):(.*)$')
 local skill=cls and cls:gsub('Card$','');if not skill then ai_unsupported('invalid sk source selector',wire)end
 local ids={};if raw~='.'and raw~=''then for id in raw:gmatch('[^+]+')do ids[#ids+1]=known(tonumber(id),'source cost')end end
 if #ids==0 and user==''then return self:legacySkillSeed(skill, '#'..cls, self.request)end
 return self:evaluateTurnSkillCard(skill, '#'..cls, ids, self.request, user~=''and user or nil)
end
local function response(self,skill,cls,ids,targets)
 local card=self:bindSkillCard(skill, ids, self.request, nil, cls)
 return{kind='use_card',card_spec=card:toCardSpec(),targets=targets or{}}
end
local function evaluation(self,name)return self:getEvaluationCard(name or'slash')end
local function declared(self,skill,card,name)
 local value=self:evaluateSkillCard(skill, name, {})
 if value:getSuit()~=card:getSuit()or value:getNumber()~=card:getNumber()then ai_unsupported('sk declared clone does not preserve prototype face',skill)end
 return value
end
local function hand_count(p)return p:getHandcardNum()+#p:getEquips()end
local function reason(player)
 local self=own_ai(player);return known(self.request and self.request.reason,'response reason')
end
local function card_answer(c)
 if AIValue.isCard(c)or AIValue.isConversion(c)then return c end
 ai_unsupported('selected response is not a pure card','sk.response')
end


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

sgs.ai_skill_invoke.sk_quanlue = true

sgs.ai_skill_invoke.sk_fushe = function(self, data)
    local current = self.room:getCurrent()
	return self:isEnemy(current)
end
sgs.ai_choicemade_filter.skillInvoke.sk_fushe = function(self, player, promptlist)
	if promptlist[#promptlist] == "yes" then
		local current = self.room:getCurrent()
		self:updateIntention(player, current, 50)
	end
end

sgs.ai_skill_choice["sk_baozheng"] = function(self, choices, data)
    local dongzhuo = self.room:findPlayerBySkillName("sk_baozheng")
	if self:isEnemy(dongzhuo) then
	    return "discardtwocards"
	end
	return "giveonecard"
end

sgs.ai_fill_skill.sk_ziguo=function(self,inclusive,request)
    if self.player:getStrategyHasUsed("#sk_ziguoCard") then return nil end
	return seed(self,"#sk_ziguoCard:.:")
end

sgs.ai_skill_use_func["#sk_ziguoCard"] = function(card, use, self)
    local targets = {}
	for _, player in ipairs(self.friends) do
	    if player:isWounded() then
		    table.insert(targets, player)
		end
	end
	if #targets == 0 then return nil end
	self:sortInPlace(targets, "hp")
	use.card = card
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_value["sk_ziguoCard"] = 100
sgs.ai_use_priority["sk_ziguoCard"] = 7
sgs.ai_card_intention["sk_ziguoCard"] = -90

sgs.ai_fill_skill.sk_yishe=function(self,inclusive,request)
    if self.player:getStrategyHasUsed("#sk_yisheCard") then return nil end
	if self:getOverflow() <= 0 then return nil end
	return seed(self,"#sk_yisheCard:.:")
end

sgs.ai_skill_use_func["#sk_yisheCard"] = function(card, use, self)
    local targets = {}
	for _, player in ipairs(self.friends_noself) do
	    if player:getHandcardNum() < self.player:getHandcardNum() then
		    table.insert(targets, player)
		end
	end
	if #targets == 0 then return nil end
	self:sortInPlace(targets, "hp")
	use.card = card
	if use.to then use.to:append(targets[1]) end
end

sgs.ai_use_value["sk_yisheCard"] = 100
sgs.ai_use_priority["sk_yisheCard"] = 2
sgs.ai_card_intention["sk_yisheCard"] = -90

sgs.ai_fill_skill.sk_midao=function(self,inclusive,request)
    if self.player:getStrategyHasUsed("#sk_midaoCard") then return nil end
	return seed(self,"#sk_midaoCard:.:")
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

sgs.ai_fill_skill.sk_pudu=function(self,inclusive,request)
    if self.player:getStrategyHasUsed("#sk_puduCard") then return nil end
	return seed(self,"#sk_puduCard:.:")
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
	self:sortInPlace(targets, "hp")
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
	self:sortByKeepValueInPlace(usable_cards)
	
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

sgs.ai_skill_invoke.sk_zhaoxin = function(self, data)
    local suits = {"spade", "heart", "club", "diamond"}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if table.contains(suits, c:getSuitString()) then
		    table.removeOne(suits, c:getSuitString())
		end
	end
	return #suits > 0
end

sgs.ai_fill_skill.sk_zhihe=function(self,inclusive,request)
    if self.player:isKongcheng() then return nil end
	local suits = {}
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if not table.contains(suits, c:getSuitString()) then
		    table.insert(suits, c:getSuitString())
		end
	end
	local S = #suits
	if self.player:getHandcardNum() > 2*S then return nil end
	if self.player:getStrategyHasUsed("#sk_zhiheCard") then return nil end
	return seed(self,"#sk_zhiheCard:.:")
end

sgs.ai_skill_use_func["#sk_zhiheCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_value["sk_zhiheCard"] = 100
sgs.ai_use_priority["sk_zhiheCard"] = 4.5

sgs.ai_fill_skill.sk_baoli=function(self,inclusive,request)
    if #self.enemies == 0 then return nil end
	if self.player:getStrategyHasUsed("#sk_baoliCard") then return nil end
	return seed(self,"#sk_baoliCard:.:")
end

sgs.ai_skill_use_func["#sk_baoliCard"] = function(card, use, self)
    local target
	local targets = {}
	for _, p in ipairs(self.enemies) do
	    if (p:getEquips():isEmpty() or (not p:getJudgingArea():isEmpty())) and self:damageIsEffective(p, sgs.DamageStruct_Normal) and not self:cantbeHurt(p) and self:canDamage(p, self.player, nil)  then
		    table.insert(targets, p)
		end
	end
	if #targets > 0 then
	    self:sortInPlace(targets, "hp")
		use.card = card
		target = targets[1]
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_value["sk_baoliCard"] = 100
sgs.ai_use_priority["sk_baoliCard"] = 5
sgs.ai_card_intention["sk_baoliCard"] = 95

sgs.ai_skill_invoke.sk_yexi = function(self, data)
    if self.player:isKongcheng() then return false end
    local targets = self.room:getOtherPlayers(self.player)
	local s = 0
	local k = 0
	for _, t in sgs.qlist(targets) do
	    if self:isFriend(t) then
		    if self.player:getKnownRole() == "renegade" then k = k + 1 end
		    if self:getRoleEstimate(t)=="renegade" then k = k + 1 end
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
	self:sortInPlace(tos, "defense")
	targets = tos[1]
	return target
end
sgs.ai_use_revises["&sk_yexi"] = function(self,card,use)
	if card:isBlack() and card:isKindOf("Slash") and self.player:hasFlag("yexi_blackslash_buff") then
		self:setStrategyCardFlag(card, "Qinggang", true)
	end
end
sgs.ai_playerchosen_intention.sk_yexi = -40

sgs.ai_fill_skill.sk_huaqiang=function(self,inclusive,request)
    if self.player:getStrategyHasUsed("#sk_huaqiangCard") then return nil end
	if #self.enemies == 0 then return nil end
	if self.player:isKongcheng() then return nil end
	return seed(self,"#sk_huaqiangCard:.:")
end

sgs.ai_skill_use_func["#sk_huaqiangCard"] = function(card, use, self)
    if #self.enemies == 0 then return nil end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	self:sortInPlace(self.enemies, "hp")
	local huaqiang_need = {}
	for _, c in ipairs(cards) do
	    if #huaqiang_need == 0 then
		    table.insert(huaqiang_need, c:getKnownEffectiveId())
		else
		    local can_do = true
			for _, p in ipairs(huaqiang_need) do
			    if c:getSuit() == face(self,p):getSuit() then
				    can_do = false
					break
				end
			end
			if can_do then
			    table.insert(huaqiang_need, c:getKnownEffectiveId())
			end
		end
		if #huaqiang_need == math.max(1, self.player:getHp()) then break end
	end
	if #huaqiang_need == math.max(1, self.player:getHp()) then
	    use.card = seed(self,"#sk_huaqiangCard:" .. table.concat(huaqiang_need, "+") .. ":")
		if use.to then use.to:append(self.enemies[1]) end
	end
end

sgs.ai_use_value["sk_huaqiangCard"] = 80
sgs.ai_use_priority["sk_huaqiangCard"] = 3.5
sgs.ai_card_intention["sk_huaqiangCard"] = 95

sgs.ai_fill_skill.sk_chaohuang=function(self,inclusive,request)
    local slash = evaluation(self,"slash")
    if self.player:isJilei(slash, true) then return nil end
    if #self.enemies == 0 then return nil end
    if self:isWeak() then return nil end
    if self.player:getHp() <= 1 and self:getCardsNum("Peach") + self:getCardsNum("Analeptic") == 0 then return nil end
	if self.player:getStrategyHasUsed("#sk_chaohuangCard") then return nil end
    return seed(self,"#sk_chaohuangCard:.:")
end

sgs.ai_skill_use_func["#sk_chaohuangCard"] = function(card, use, self)
    if #self.enemies <= 0 then return nil end
	local E = 0
	for _, enemy in ipairs(self.enemies) do
		if self.player:inMyAttackRange(enemy) then E = E + 1 end
	end
	if E == 0 then return nil end
	self:sortInPlace(self.enemies, "defense")
	use.card = card
	local slash = evaluation(self,"slash")
	
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
	    self:sortInPlace(enemies, "defense")
		target = enemies[1]
	end
	return target
end
sgs.need_kongcheng = sgs.need_kongcheng .. "|sk_sijian"
sgs.ai_playerchosen_intention["sk_sijian"] = 50

sgs.ai_skill_invoke.sk_gangzhi = function(self, data)
    if self.player:isKongcheng() then
	    return true
	else
	    if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then return false else return true end
	end
	return false
end
sgs.dont_kongcheng_skill = sgs.dont_kongcheng_skill .. "|sk_gangzhi"

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
	self:sortInPlace(friends, "defense")
	return friends[1]
end

sgs.ai_playerchosen_intention["sk_zhongyong"] = -50

sgs.ai_skill_invoke.sk_xiongyi = function(self, data)
    if self.player:hasSkill("zhiji") and self.player:isKongcheng() and self.player:getStrategyMark("@waked") == 0 then return false end  --没手牌，有【志继】就不要发动
	if self.player:hasSkill("hunzi") and self.player:getHp() == 1 and self.player:getStrategyMark("@waked") == 0 then return false end  --体力为1，是孙笨，也别发动
	return true
end

sgs.ai_fill_skill.sk_chaochen=function(self,inclusive,request)
    if self.player:isKongcheng() then return nil end
	if self:isWeak() then return nil end
	if #self.enemies == 0 then return nil end
	if self.player:getStrategyHasUsed("#sk_chaochenCard") then return nil end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	if (not cards[1]:isKindOf("Peach")) and (not cards[1]:isKindOf("Analeptic")) then
	    return seed(self,"#sk_chaochenCard:"..cards[1]:getEffectiveId()..":")
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

sgs.ai_skill_invoke.sk_quanzheng = function(self, data)
    return not self:needKongcheng(self.player, true)
end

local function card_for_qiaobian(self, who, return_prompt)
	local card, target
	if self:isFriend(who) then
		local judges = who:getJudgingArea()
		if not judges:isEmpty() then
			for _, judge in sgs.qlist(judges) do
				card = face(self,judge:getKnownEffectiveId())
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
					self:sortInPlace(self.friends, "defense")
				else
					self:sortInPlace(self.friends, "handcard")
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
					card = face(self,judge:getKnownEffectiveId())
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
			if card_id >= 0 and who:hasEquip(face(self,card_id)) then
				card = face(self,card_id) end

			if card then
				if card:isKindOf("Armor") or card:isKindOf("DefensiveHorse") then
					self:sortInPlace(self.friends, "defense")
				else
					self:sortInPlace(self.friends, "handcard")
					self.friends = sgs.reverse(self.friends)
				end

				for _, friend in ipairs(self.friends) do
					if not self:getSameEquip(card, friend) and friend:objectName() ~= who:objectName() and
					self:hasSkills(sgs.lose_equip_skill .. "|shensu", friend) then
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
	if self.player:getStrategyMark("yaoming") == 1 then return true
	elseif self.player:getStrategyMark("yaoming") == 2 then
	    local targets = {}
		for _, _player in sgs.qlist(others) do
		    if self:isEnemy(_player) and (not _player:isNude()) then table.insert(targets, _player) end
		end
		if #targets > 0 then return true end
		return false
	elseif self.player:getStrategyMark("yaoming") == 3 then
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
	elseif self.player:getStrategyMark("yaoming") == 4 then
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
	self:sortInPlace(enemies, "defense")
	for _, friend in ipairs(friends) do
		if not friend:getCards("j"):isEmpty() and not friend:containsTrick("YanxiaoCard") and
		card_for_qiaobian(self, friend, ".") then			
			return friend
		end
	end
	
	for _, enemy in ipairs(enemies) do
		if not enemy:getCards("j"):isEmpty() and enemy:containsTrick("YanxiaoCard") and
			card_for_qiaobian(self, enemy, ".") then

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
		self:sortInPlace(targets, "defense")

		return targets[#targets]
	end
end

sgs.ai_skill_playerchosen["yaoming_second"] = function(self, targets)
	local context=self:getDecisionContext()
	if context.sk_yaoming_known~=true then ai_unsupported("sk current public target unknown","yaomingTarget")end
	local name=context.sk_yaoming_target
	local who = name and known(self.room:findPlayerByObjectName(name,true),"yaomingTarget")
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
	    self:sortInPlace(players, "hp")
		return players[1]
	end
end

sgs.ai_skill_playerchosen.sk_yaoming = function(self, targets)
	return self:findPlayerToDiscard()[1]
end
sgs.ai_playerchosen_intention["sk_yaoming"] = 50

sgs.ai_skill_invoke.sk_diezhang = true

sgs.ai_card_priority.sk_diezhang = function(self,card,v)
	-- Own tag; QVariant::toInt reads absent as 0.
	if (tonumber(self.player:getTag("diezhang_point")) or 0)<card:getNumber()
	then return 10 end
end

sgs.ai_fill_skill.sk_pengri=function(self,inclusive,request)
	if self.player:getStrategyHasUsed("#sk_pengriCard") then return nil end
	return seed(self,"#sk_pengriCard:.:")
end













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
					return card_answer(slash)
			end
		end
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:isFriend(target) then
				if not self:needLeiji(target, self.player) then return card_answer(slash) end
				if not self:slashIsEffective(slash, target) then return card_answer(slash) end
			end
		end
	end
	return "."
end

sgs.ai_skill_invoke.sk_danmou = function(self, data)
    local damage = data:toDamage()
	if damage.from:getHandcardNum() < self.player:getHandcardNum() then return false end
	if self:isFriend(damage.from) then return false end
	if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then return false end
	if damage.from:isKongcheng() then return false end
	return damage.from:getHandcardNum() >= self.player:getHandcardNum()
end

sgs.ai_can_damagehp.sk_danmou = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from, to, 1, card)>0
	and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from) and (from:getHandcardNum() - self.player:getHandcardNum() > 2)
	end
end

sgs.ai_fill_skill.sk_gongshen=function(self,inclusive,request)
	if self.player:getCards("he"):length() < 3 then return nil end
	return seed(self,"#sk_gongshenCard:.:")
end


sgs.ai_skill_use_func["#sk_gongshenCard"] = function(card, use, self)
    local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValueInPlace(cards)
	local gongshen = {}
	for _, c in ipairs(cards) do
	    table.insert(gongshen, c:getKnownEffectiveId())
		if #gongshen == 3 then break end
	end
	if #gongshen < 3 then return nil end
	use.card = seed(self,"#sk_gongshenCard:" .. table.concat(gongshen, "+") .. ":")
end


sgs.ai_use_value["sk_gongshenCard"] = 6.5
sgs.ai_use_priority["sk_gongshenCard"] = sgs.ai_use_priority.Peach - 1

sgs.ai_skill_invoke.sk_jianyue = function(self, data)
    local current = self.room:getCurrent()
	return self:isFriend(current)
end
sgs.ai_choicemade_filter.skillInvoke.sk_jianyue = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if promptlist[#promptlist] == "yes" and current and current:isAlive() then
		self:updateIntention(player, current, -50)
	end
end

sgs.ai_skill_use["@@sk_suiji"] = function(self, prompt)
    local current = self.room:getCurrent()
	if current:getHandcardNum() <= current:getHp() then return "." end
	if self.player:isKongcheng() then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValueInPlace(cards)
	if current:getHandcardNum() >= current:getHp() + 1 then
	    return response(self,"sk_suiji","#sk_suijiCard",{cards[1]:getEffectiveId()},{"."})
	end
end

sgs.ai_skill_invoke.sk_fengyi = true

sgs.ai_skill_invoke.sk_bibu = function(self, data)
    if self.player:getHandcardNum() <= math.max(1, self.player:getHp()) then return true end
	local current = self.room:getCurrent()
	if self.player:getHandcardNum() > math.max(1, self.player:getHp()) and self:isFriend(current) then return true end
	return false
end
sgs.ai_choicemade_filter.skillInvoke.sk_bibu = function(self, player, promptlist)
	local current = self.room:getCurrent()
	if promptlist[#promptlist] == "yes" and current and current:isAlive() then
		self:updateIntention(player, current, -50)
	end
end

function canKuangzhengFriend(target)
    if target:isChained() then return true end
	if target:isAlive() and not target:faceUp() then return true end
	if target:getStrategyMark("@duanchang") > 0 then return true end
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

sgs.ai_fill_skill.sk_shejian=function(self,inclusive,request)
    if self.player:getArmor() ~= nil then return nil end
	if self.player:isNude() then return nil end
	if self:isWeak() then return nil end
	return seed(self,"#sk_shejianCard:.:")
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

sgs.ai_skill_invoke.sk_kuangao = function(self, data)
	local slasher = data:toPlayer()
    if self:isFriend(slasher) then return true end
	if self:isEnemy(slasher) then
		if self.player:isNude() then return false end
	    if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") <= 0 and hand_count(slasher) >= 2*self.player:getCards("he"):length() then return true end
		if hand_count(slasher) >= 2.5*self.player:getCards("he"):length() then return true end
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
		self:updateIntention(player, target, -80)
	end
	if choice == "kuangao_discard" and target then
		self:updateIntention(player, target, 80)
	end
end

sgs.ai_skill_invoke.sk_fenwei = function(self, data)
    local damage = data:toDamage()
	local nature = damage.nature
	if not damage.to:getArmor() ~= "SilverLion" and self:isEnemy(damage.to) and self:damageIsEffective(damage.to, nature) then
	    return true
	end
	return false
end
-- audited alias ai_cardneed.sk_fenwei
sgs.bad_skills = sgs.bad_skills .. "|sk_shiyong"


sgs.ai_skill_cardask["@cangshu-give"] = function(self, data, pattern, target, target2)
	local handcards = sgs.QList2Table(self.player:getCards("h"))
	if self:isFriend(target) then return "." end
		local use = data:toCardUse()
		if use.card and use.card:isVirtualCard() then return "." end
	self:sortByKeepValueInPlace(handcards)
	local give_cards = {}
	for _, c in ipairs(handcards) do
		if c:isKindOf("BasicCard") then
			table.insert(give_cards, c)
			break
		end
	end
	if #give_cards > 0 then
		return card_answer(give_cards[1])
	end
	return "."
end

sgs.ai_guhuo_card.sk_kanwu = function(self,toname,class_name)
    local cards = self.player:getCards("he")
    cards = self:sortByKeepValueInPlace(cards) -- 按保留值排序
   	for d,c in sgs.list(cards)do
       	d = evaluation(self,toname)
        if c:getTypeId()~=1
        and d:isKindOf("BasicCard") and self:getCardsNum(class_name)<1
		and (reason(self.player)==sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE or reason(self.player)== sgs.CardUseStruct_CARD_USE_REASON_RESPONSE)
        then return {skill="sk_kanwu",legacy_class="#sk_kanwu",subcards={c:getKnownEffectiveId()},user_string=toname} end
   	end
end

function CountSuit(zumao, suit)
	local cards = zumao:getHandcards();if #cards~=zumao:getHandcardNum()then ai_unsupported("CountSuit requires complete lawful hand","sk.CountSuit")end
	local x = 0
	for _, c in sgs.qlist(cards) do
		if c:getSuit() == suit then
			x = x + 1
		end
	end
	return x
end

function SmartAIView:getYinbingValue(zumao)
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
		if target then self:updateIntention(player, target, -50) end
	end
end
sgs.ai_skill_invoke.sk_yinbing_draw = true

sgs.ai_skill_invoke.sk_hengshi = true

sgs.ai_skill_playerchosen.sk_zhijiao = function(self, targets)
	local room = self.room
	if self.player:getStrategyMark("@zhijiao") == 0 then return nil end
	local target
	if #self.friends_noself == 0 then return nil end
	local tag = self.player:getStrategyMark("zhijiao_count")
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

sgs.ai_skill_invoke.sk_daoshi = function(self, data)
	local zhoucang = data:toPlayer()
	return self:isFriend(zhoucang)
end

sgs.ai_skill_invoke.sk_kuangfu = function(self, data)
	local to = data:toPlayer()
	return self:isEnemy(to)
end
-- audited alias ai_cardneed.sk_kuangfu
sgs.ai_skill_playerchosen.sk_hubu = function(self, targets)
	local room = self.room
    local duel = evaluation(self,"duel")
	
	if self.player:hasSkill("wuyan") and not self.player:hasSkill("jueqing") then return end
	if self.player:hasSkill("noswuyan") then return end
	local enemies = self:exclude(self.enemies, duel)
	local friends = self:exclude(self.friends_noself, duel)
	self:setStrategyCardFlag(duel, "AI_Using", true)
	local n1 = self:getCardsNum("Slash")
	self:setStrategyCardFlag(duel, "AI_Using", false)
	if self.player:hasSkill("wushuang") then
		n1 = n1 * 2
	end
	local targets = {}
	local canUseDuelTo = function(target)
		return self:hasTrickEffective(duel, target) and self:damageIsEffective(target, sgs.DamageStruct_Normal) and not self.room:isProhibited(self.player, target, duel)

		and not (target:hasSkill("guixin") and target:getHp() > 1 and known(self.world.turn_count,"turn_count") <= 1 and not self.player:hasSkill("jueqing"))
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

sgs.ai_fill_skill.sk_huilian=function(self,inclusive,request)
	if not self.player:getStrategyHasUsed("#sk_huilian") then
		return seed(self,"#sk_huilian:.:")
	end
end

sgs.ai_skill_use_func["#sk_huilian"] = function(card, use, self)
	self:updatePlayers()
	self:sortInPlace(self.friends_noself, "hp")
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

sgs.ai_fill_skill.sk_lirang=function(self,inclusive,request)
	local gift = self.player:getPile("gift")
	local giftids = {}
	for _, id in sgs.qlist(gift) do
		local card = face(self,id)
		table.insert(giftids, card:getKnownEffectiveId())
		if #giftids == 2 then break end
	end
	if #giftids < 2 or (not self.player:isWounded()) then return nil end
	local lirang_peach = seed(self,"#sk_lirang:" .. table.concat(giftids, "+") .. ":" .. "peach")
	return lirang_peach
end

sgs.ai_skill_use_func["#sk_lirang"] = function(card, use, self)
	local userstring = card:getLegacyStringKey()
	userstring = (userstring:split(":"))[4]
	local lirang_peach = declared(self,"sk_lirang",card,userstring)
	self:useBasicCard(lirang_peach, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_view_as["sk_lirang"] = function(card, player, card_place)
	local gift = player:getPile("gift")
	local giftids = {}
	for _, id in sgs.qlist(gift) do
		local card = face(own_ai(player),id)
		table.insert(giftids, card:getKnownEffectiveId())
		if #giftids == 2 then break end
	end
	if #giftids >= 2 then return {name="peach",skill="sk_lirang",suit=sgs.Card_NoSuit,number=0,subcards={giftids[1],giftids[2]}} end
end

sgs.ai_skill_cardask["@lirang_to"] = function(self, data, pattern)
	local kongrong = data:toPlayer()
	if not self:isFriend(kongrong) then return "." end
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValueInPlace(cards)
	for _,h in sgs.list(cards)do
		if self:matchesDiscardPattern(pattern, h)
		then return h:getKnownEffectiveId() end
		if h:isKindOf(pattern)
		then return h:getKnownEffectiveId() end
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
		self:updateIntention(player, dest, -40)
		end
	end
end

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
		self:sortByKeepValueInPlace(cards)
		local acard
		for _, c in ipairs(cards) do
			if not c:isKindOf("Peach") then
				acard = c
				break
			end
		end
		if acard then
			return "$" .. acard:getKnownEffectiveId()
		else
			return "."
		end
	end
end

sgs.ai_skill_playerchosen.sk_yijian = function(self, targets)
	if self.player:isWounded() then
		local who = {}
		for _, friend in ipairs(self.friends_noself) do
			if friend:getHandcardNum() + 1 >= self.player:getHandcardNum() then table.insert(who, friend) end
		end
		if #who > 0 then
			self:sortInPlace(who, "hp")
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
-- audited alias ai_cardneed.sk_feijun
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
		self:sortByKeepValueInPlace(black)
		if player:getHandcardNum() - player:getHp() >= 2 then
			return card_answer(black[1])
		end
		return "."
	else
		if #red == 0 then return "." end
		if player:getHp()< 2 or player:getHandcardNum()<= 1 then
			return card_answer(red[1])
		end
	end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@yanliang_card"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		self:updateIntention(player, current, 80)
	end
end

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
			self:updateIntention(player, current, 40)
		end
	end
end
-- audited alias ai_cardneed.sk_caijie
sgs.ai_skill_invoke.sk_jilei = function(self, data)
	local who = data:toPlayer()
	return self:isEnemy(who)
end
sgs.ai_choicemade_filter.skillInvoke.sk_jilei = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then self:updateIntention(player, target, 50) end
	end
end

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

sgs.ai_fill_skill.sk_zhengyi=function(self,inclusive,request)
	self:updatePlayers()
	if can_zhengyi_inturn(self.player) then
		if self.player:isWounded() then
			return seed(self,"#sk_zhengyi:.:" .. "peach")
		end
		local slash = evaluation(self,"slash")
		
		if self:getCardsNum("Slash") > 1 and not slash:isAvailable(self.player) then
			for _, enemy in ipairs(self.enemies) do
				if ((enemy:getHp() < 3 and enemy:getHandcardNum() < 3) or (enemy:getHandcardNum() < 2)) and self.player:canSlash(enemy) and not self:slashProhibit(slash, enemy, self.player)
					and self:slashIsEffective(slash, enemy, self.player) and self:isGoodTarget(enemy, self.enemies, nil) then
					return seed(self,"#sk_zhengyi:.:" .. "analeptic")
				end
			end
		end
		for _, enemy in ipairs(self.enemies) do
			if self.player:canSlash(enemy) and self:isGoodTarget(enemy, self.enemies, nil) then
				local thunder_slash = evaluation(self,"thunder_slash")
				
				local fire_slash = evaluation(self,"fire_slash")
				
				if  not self:slashProhibit(fire_slash, enemy, self.player)and self:slashIsEffective(fire_slash, enemy, self.player) then
					return seed(self,"#sk_zhengyi:.:" .. "fire_slash")
				end
				if not self:slashProhibit(thunder_slash, enemy, self.player)and self:slashIsEffective(thunder_slash, enemy, self.player) then
					return seed(self,"#sk_zhengyi:.:" .. "thunder_slash")
				end
				if not self:slashProhibit(slash, enemy, self.player)and self:slashIsEffective(slash, enemy, self.player) then
					return seed(self,"#sk_zhengyi:.:" .. "slash")
				end
			end
		end
	end
end

sgs.ai_skill_use_func["#sk_zhengyi"] = function(card, use, self)
	local userstring = card:getLegacyStringKey()
	userstring = (userstring:split(":"))[4]
	local zhengyi_card = declared(self,"sk_zhengyi",card,userstring)
	self:useBasicCard(zhengyi_card, use)
	if not use.card then return end
	use.card = card
end


sgs.ai_use_priority["sk_zhengyi"] = 8
sgs.ai_use_value["sk_zhengyi"] = 8


sgs.ai_view_as["sk_zhengyi"] = function(card, player, card_place, class_name)
	if reason(player) == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE and can_zhengyi_outturn(player) then
		local classname2objectname = {
		["Slash"] = "slash", ["Jink"] = "jink",
		["Peach"] = "peach", ["Analeptic"] = "analeptic",
		["FireSlash"] = "fire_slash", ["ThunderSlash"] = "thunder_slash"
		}
		local name = classname2objectname[class_name]
		if not name then return end
		return {name=name,skill="sk_zhengyi",suit=sgs.Card_NoSuit,number=0,subcards={}}
	end
end

-- audited alias ai_cardneed.sk_jiwu
sgs.ai_skill_use["@@sk_jiwu"] = function(self, prompt)
	for _, c in ipairs(sgs.QList2Table(self.player:getCards("h"))) do
		if c:isKindOf("Slash") then
			return response(self,"sk_jiwu","#sk_jiwu",{c:getKnownEffectiveId()})
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

sgs.ai_skill_invoke.sk_zhenlie = function(self, data)
	local use = data:toCardUse()
	if not use.from or use.from:isDead() then return false end
	if self.player:getKnownRole() == "rebel" and self:getRoleEstimate(use.from) == "rebel" and not use.from:hasSkill("jueqing")
		and self.player:getHp() == 1 and self:getAllPeachNum() < 1 then return false end
	if self:isEnemy(use.from) or (self:isFriend(use.from) and self.player:getKnownRole() == "loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord() and self.player:getHp() == 1) then
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
				if self:isFriend(use.from) and self.player:getKnownRole() == "loyalist" and not use.from:hasSkill("jueqing") and use.from:isLord() and self.player:getHp() == 1 then return true end
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
				if self:isFriend(from) and self.player:getKnownRole() == "loyalist" and from:isLord() and self.player:getHp() == 1 and not from:hasSkill("jueqing") then return true end
				if (not (self:hasSkills(sgs.masochism_skill) or (self.player:hasSkills("tianxiang|ol_tianxiang") and getKnownCard(self.player, self.player, "heart") > 0)) or use.from:hasSkill("jueqing"))
					and self:doDisCard(use.from) then
					return true
				end
			end
		elseif self:isEnemy(use.from) then
			if use.card:isKindOf("FireAttack") and use.from:getHandcardNum() > 0 then
					if not self:hasTrickEffective(use.card, self.player) then return false end
				if not self:damageIsEffective(self.player, sgs.DamageStruct_Fire, use.from) then return false end
				if (self.player:hasArmorEffect("vine") or self.player:getStrategyMark("@gale") > 0) and use.from:getHandcardNum() > 3
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
	self:sortByKeepValueInPlace(cards)
	for _, c in sgs.qlist(cards) do
		if not c:isKindOf("Peach") and (not c:isKindOf("Analeptic")) then
			return "$" .. c:getKnownEffectiveId()
		end
	end
end

sgs.ai_skill_invoke.sk_miji = true

sgs.ai_skill_playerchosen["sk_miji"] = function(self, targets)
	self:updatePlayers()
	self:sortInPlace(self.friends, "handcard")
	local can_give_friend = {}
	for _, friend in ipairs(self.friends) do
		if not self:hasManjuanEffect(friend) and not self:isLihunTarget(friend) then
			table.insert(can_give_friend, friend)
		end
	end
	if #can_give_friend > 0 then return can_give_friend[1] end
end
sgs.ai_playerchosen_intention.sk_miji = -50

sgs.ai_getBestHp_skill.sk_miji = function(owner)
	return owner:getMaxHp() - 1
end

sgs.ai_skill_cardask["@zhoufu"] = function(self, data)
	local current = self.room:getCurrent()
	if self:isEnemy(current) then
		local cards = self.player:getCards("h")
		self:sortByKeepValueInPlace(cards)
		for _, c in sgs.qlist(cards) do
			if not c:isKindOf("Peach") and (not c:isKindOf("Analeptic")) then
				return "$" .. c:getKnownEffectiveId()
			end
		end
	end
	return "."
end
sgs.ai_choicemade_filter.cardResponded["@zhoufu"] = function(self, player, promptlist)
	if promptlist[#promptlist] ~= "" then
		local current = self.room:getCurrent()
		if not current then return end
		self:updateIntention(player, current, 80)
	end
end

sgs.ai_skill_invoke["sk_yingbing"] = function(self, data)
	local player = data:toPlayer()
	return self:isEnemy(player)
end
ai_audited_aliases.register({id="ai_cardneed.sk_fenwei",registry="ai_cardneed",path={"sk_fenwei"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.sk_kuangfu",registry="ai_cardneed",path={"sk_kuangfu"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.sk_feijun",registry="ai_cardneed",path={"sk_feijun"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.sk_caijie",registry="ai_cardneed",path={"sk_caijie"},canonical_registry="ai_cardneed",canonical_path={"bignumber"},self_index=3,defer_canonical=true})

ai_audited_aliases.register({id="ai_cardneed.sk_jiwu",registry="ai_cardneed",path={"sk_jiwu"},canonical_registry="ai_cardneed",canonical_path={"slash"},self_index=3,defer_canonical=true})

--邓芝：和盟/素检
sgs.ai_fill_skill.sk_hemeng=function(self,inclusive,request)
    if self.player:isKongcheng() then return nil end
	return seed(self,"#sk_hemengCard:.:")
end

sgs.ai_skill_use_func["#sk_hemengCard"] = function(card, use, self)
    local target
	for _, p in ipairs(self.enemies) do
	    if not p:isKongcheng() and p:getHandcardNum() > self.player:getHandcardNum() then
		    if not target or p:getHandcardNum() > target:getHandcardNum() then target = p end
		end
	end
	if target then
	    use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_value["sk_hemengCard"] = 60
sgs.ai_use_priority["sk_hemengCard"] = 2
sgs.ai_card_intention["sk_hemengCard"] = 30

sgs.ai_skill_cardchosen.sk_hemeng = function(self, who, flags, reason, method)
    local cards = sgs.QList2Table(who:getCards("h"))
	if #cards == 0 then return -1 end
	self:sortByKeepValueInPlace(cards)
	return cards[#cards]:getEffectiveId()
end

sgs.ai_skill_playerchosen.sk_sujian = function(self, targets)
    local friends = {}
	for _, t in sgs.qlist(targets) do
	    if self:isFriend(t) and not t:isNude() then table.insert(friends, t) end
	end
	if #friends > 0 then return friends[1] end
	if self.player:getHandcardNum() >= 3 then
	    local enemies = {}
		for _, t in sgs.qlist(targets) do
		    if self:isEnemy(t) and not t:isNude() then table.insert(enemies, t) end
		end
		if #enemies > 0 then return enemies[1] end
	end
	return nil
end

sgs.ai_skill_cardchosen.sk_sujian = function(self, who, flags, reason, method)
    local cards = sgs.QList2Table(who:getCards("he"))
	if #cards == 0 then return -1 end
	self:sortByKeepValueInPlace(cards)
	if self:isFriend(who) then
	    return cards[1]:getEffectiveId()
	end
	return cards[#cards]:getEffectiveId()
end
sgs.ai_playerchosen_intention.sk_sujian = 30

--陈式：擎北
sgs.ai_skill_invoke.sk_qingbei = true

sgs.ai_skill_choice.sk_qingbei = function(self, choices)
    local count = {spade = 0, heart = 0, club = 0, diamond = 0}
	for _, c in sgs.qlist(self.player:getHandcards()) do
	    local s = c:getSuitString()
		if count[s] ~= nil then count[s] = count[s] + 1 end
	end
	local best, n = "spade", -1
	for k, v in pairs(count) do
	    if v > n then best, n = k, v end
	end
	return best
end

--马良：雅虑/协穆
sgs.ai_skill_invoke.sk_yalv = true

sgs.ai_skill_cardask["@xiemu-put"] = function(self, data)
    if self.player:isKongcheng() then return "." end
	local current = self.room:getCurrent()
	if not current then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	if #cards == 0 then return "." end
	self:sortByKeepValueInPlace(cards)
	if self:isFriend(current) then
	    if current:isWounded() then
		    for _, c in ipairs(cards) do
			    if c:isKindOf("Peach") then return card_answer(c) end
			end
		end
		for i = #cards, 1, -1 do
		    if cards[i]:isKindOf("BasicCard") then return card_answer(cards[i]) end
		end
	end
	return card_answer(cards[1])
end

sgs.ai_skill_invoke.sk_xiemu = function(self, data)
    local current = self.room:getCurrent()
	return current and self:isFriend(current)
end

--费祎：衍息/止戈
sgs.ai_skill_invoke.sk_yanxi = true

sgs.ai_skill_invoke.sk_zhige = function(self, data)
    if self.player:getEquips():isEmpty() then return false end
	local asked = data:toStringList()
	local pattern = asked and asked[1]
	if pattern == "jink" then
	    return self:getCardsNum("Jink") == 0
	elseif pattern == "slash" then
	    return self:getCardsNum("Slash") == 0
	end
	return true
end

--甘夫人：淑慎/神智
sgs.ai_skill_playerchosen.sk_shushen = function(self, targets)
    local friends = {}
	for _, t in sgs.qlist(targets) do
	    if self:isFriend(t) then table.insert(friends, t) end
	end
	if #friends == 0 then return nil end
	local wounded = {}
	for _, t in ipairs(friends) do
	    if t:isWounded() then table.insert(wounded, t) end
	end
	if #wounded > 0 then
	    self:sortInPlace(wounded, "hp")
		return wounded[1]
	end
	self:sortInPlace(friends, "hp")
	return friends[1]
end
sgs.ai_playerchosen_intention.sk_shushen = -50

sgs.ai_skill_choice.sk_shushen = function(self, choices)
    if self.player:isWounded() and self.player:getHp() <= 2 then
	    return "shushen_recover"
	end
	return "shushen_draw"
end

sgs.ai_skill_invoke.sk_shenzhi = function(self, data)
    if not self.player:isWounded() then return false end
	local h = self.player:getHandcardNum()
	local hp = math.max(1, self.player:getHp())
	if h < hp then return false end
	if self:isWeak() then return true end
	if h <= hp then return true end
	return self.player:getLostHp() >= 3
end

--糜夫人：闺秀/存嗣
sgs.ai_skill_invoke.sk_guixiu = true

sgs.ai_skill_playerchosen.sk_cunsi = function(self, targets)
    local friends = {}
	for _, t in sgs.qlist(targets) do
	    if self:isFriend(t) then table.insert(friends, t) end
	end
	if #friends == 0 then return nil end
	self:sortInPlace(friends, "defense")
	return friends[#friends]
end
sgs.ai_playerchosen_intention.sk_cunsi = -80

--刘谌：战绝
sgs.ai_skill_playerchosen.sk_zhanjue = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return nil end
	self:sortInPlace(enemies, "hp")
	return enemies[1]
end
sgs.ai_playerchosen_intention.sk_zhanjue = 80

--诸葛果：羽化/登仙
sgs.ai_skill_invoke.sk_yuhua = function(self, data)
	local damage = data:toDamage()
	if damage.to and damage.to:objectName() == self.player:objectName() then return true end
	if damage.from and damage.from:objectName() == self.player:objectName()
		and damage.to and self:isFriend(damage.to) then return true end
	return false
end

sgs.ai_skill_choice.sk_dengxian = function(self, choices)
	if self.player:getHandcardNum() > 0 then return "dengxian_play" end
	return "dengxian_draw"
end

--夏侯氏：拾樵/莺歌
sgs.ai_skill_invoke.sk_shiqiao = true

sgs.ai_skill_cardask["@sk_yingge-discard"] = function(self, data)
	local current = self.room:getCurrent()
	if not (current and self:isFriend(current)) then return "." end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return "." end
	self:sortByKeepValueInPlace(cards)
	local best
	for _, c in ipairs(cards) do
		if not best or c:getNumber() < best:getNumber() then best = c end
	end
	return card_answer(best)
end

--吴苋：贺春/怠宴
sgs.ai_fill_skill.sk_hechun=function(self,inclusive,request)
    if self.player:getStrategyHasUsed("#sk_hechunCard") then return nil end
	return seed(self,"#sk_hechunCard:.:")
end

sgs.ai_skill_use_func["#sk_hechunCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["sk_hechunCard"] = 60
sgs.ai_use_priority["sk_hechunCard"] = 6
sgs.ai_card_intention["sk_hechunCard"] = 30

sgs.ai_skill_invoke.sk_hechun_recover = function(self, data)
	local who = data:toPlayer()
	return who and self:isFriend(who)
end

sgs.ai_skill_invoke.sk_hechun_lose = function(self, data)
	local who = data:toPlayer()
	return who and self:isEnemy(who)
end

sgs.ai_skill_cardchosen.sk_hechun = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(who:getCards("he"))
	if #cards == 0 then return -1 end
	self:sortByKeepValueInPlace(cards)
	for _, c in ipairs(cards) do
		if c:isRed() then return c:getKnownEffectiveId() end
	end
	return cards[1]:getKnownEffectiveId()
end

sgs.ai_skill_playerchosen.sk_daiyan = function(self, targets)
	local mine = self.player:objectName()
	local best, bestcnt
	for _, t in sgs.qlist(targets) do
		local cnt = t:getStrategyMark("&sk_daiyan+#"..mine)
		if self:isFriend(t) and (not bestcnt or cnt < bestcnt) then
			best, bestcnt = t, cnt
		end
	end
	if best then return best end
	for _, t in sgs.qlist(targets) do
		if t:objectName() == mine and t:getStrategyMark("&sk_daiyan+#"..mine) < 2 then return t end
	end
	return nil
end

sgs.ai_playerchosen_intention.sk_daiyan = -60

--花鬘：蛮裔/薮影
sgs.ai_skill_invoke.sk_manyi = function(self, data)
	local use = data:toCardUse()
	local card, from = use.card, use.from
	if not (card and from) then return false end
	local is_self = from:objectName() == self.player:objectName()
	if card:isKindOf("SavageAssault") then return is_self end
	if is_self then return #self.enemies >= #self.friends_noself end
	return self.player:getArmor() == "Vine" or #self.enemies > #self.friends
end

sgs.ai_skill_playerchosen.sk_souying_dmg = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return nil end
	self:sortInPlace(enemies, "hp")
	return enemies[1]
end

sgs.ai_playerchosen_intention.sk_souying_dmg = 80

sgs.ai_skill_playerchosen.sk_souying_heal = function(self, targets)
	local wounded = {}
	for _, t in sgs.qlist(targets) do
		if self:isFriend(t) and t:isWounded() then table.insert(wounded, t) end
	end
	if #wounded == 0 then return nil end
	self:sortInPlace(wounded, "hp")
	return wounded[1]
end

sgs.ai_playerchosen_intention.sk_souying_heal = -50


--关索：征南/同心
local sk_zhengnan_skill = {}
sk_zhengnan_skill.name = "sk_zhengnan"
table.insert(sgs.ai_skills, sk_zhengnan_skill)
sk_zhengnan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getStrategyHasUsed("#sk_zhengnanCard") then return nil end
	return sgs.Card_Parse("#sk_zhengnanCard:.:")
end
sgs.ai_skill_use_func["#sk_zhengnanCard"] = function(card, use, self)
	if #self.enemies <= #self.friends_noself then return end
	use.card = card
	if use.to then use.to:append(self.player) end
end
sgs.ai_use_value["sk_zhengnanCard"] = 6
sgs.ai_use_priority["sk_zhengnanCard"] = 4

sgs.ai_skill_invoke.sk_tongxin = true


--鲍三娘：镇南（剑舞为被动技）
sgs.ai_skill_playerchosen.sk_zhennan = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return nil end
	self:sortInPlace(enemies, "hp")
	return enemies[1]
end
sgs.ai_playerchosen_intention.sk_zhennan = 80


--谯周：识命/星卜
sgs.ai_skill_invoke.sk_shiming = function(self, data)
	local move = data:toMoveOneTime()
	if move.to then return self:isEnemy(move.to) end
	return false
end
sgs.ai_skill_choice["sk_shiming"] = function(self, choices, data)
	return "sk_shiming_obtain"
end

sgs.ai_skill_invoke.sk_xingbu = true
sgs.ai_skill_playerchosen.sk_xingbu = function(self, targets)
	local friends = {}
	for _, t in sgs.qlist(targets) do
		if self:isFriend(t) then table.insert(friends, t) end
	end
	if #friends == 0 then return nil end
	self:sortInPlace(friends, "handcard")
	return friends[1]
end
sgs.ai_playerchosen_intention.sk_xingbu = -60


--孙策：昂扬/威风
sgs.ai_skill_invoke.sk_angyang = true

sgs.ai_skill_playerchosen.sk_weifeng = function(self, targets)
	targets = sgs.QList2Table(targets)
	local max_card = self:getMaxCard()
	local max_point = max_card and max_card:getNumber() or 0
	if max_point >= 10 then
		local enemies = {}
		for _, t in ipairs(targets) do
			if self:isEnemy(t) then table.insert(enemies, t) end
		end
		if #enemies > 0 then
			self:sortInPlace(enemies, "handcard")
			return enemies[1]
		end
	end
	local friends = {}
	for _, t in ipairs(targets) do
		if self:isFriend(t) and t:getHandcardNum() <= 1 then table.insert(friends, t) end
	end
	if #friends > 0 then
		self:sortInPlace(friends, "handcard")
		return friends[1]
	end
	return nil
end


--步骘：折节/风雅
sgs.ai_skill_cardask["@sk_zhejie-discard"] = function(self, data)
	local current = self.room:getCurrent()
	if not current then return "." end
	if not (self:isEnemy(current) and not current:isNude()) then return "." end
	local cards = sgs.QList2Table(self.player:getHandcards())
	if #cards == 0 then return "." end
	self:sortByKeepValueInPlace(cards)
	return card_answer(cards[1])
end

sgs.ai_skill_cardchosen.sk_zhejie = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(who:getCards("he"))
	if #cards == 0 then return -1 end
	self:sortByKeepValueInPlace(cards)
	if self:isFriend(who) then
		return cards[1]:getKnownEffectiveId()
	end
	for i = #cards, 1, -1 do
		if cards[i]:isKindOf("EquipCard") then return cards[i]:getKnownEffectiveId() end
	end
	return cards[#cards]:getKnownEffectiveId()
end

sgs.ai_skill_playerchosen.sk_zhejie = function(self, targets)
	for _, t in sgs.qlist(targets) do
		if t:objectName() == self.player:objectName() then return t end
	end
	for _, t in sgs.qlist(targets) do
		if self:isFriend(t) then return t end
	end
	return nil
end

sgs.ai_skill_invoke.sk_fengya = true

sgs.ai_skill_invoke.sk_fengya_reduce = function(self, data)
	local who = data:toPlayer()
	return who and self:isFriend(who)
end


--董袭：断缆
local sk_duanlan_skill = {}
sk_duanlan_skill.name = "sk_duanlan"
table.insert(sgs.ai_skills, sk_duanlan_skill)
sk_duanlan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getStrategyHasUsed("#sk_duanlanCard") then return nil end
	return sgs.Card_Parse("#sk_duanlanCard:.:")
end

sgs.ai_skill_use_func["#sk_duanlanCard"] = function(card, use, self)
	local has_victim = false
	for _, p in ipairs(self.enemies) do
		if not (p:isNude() and p:getJudgingArea():isEmpty()) then has_victim = true break end
	end
	if not has_victim then return end
	local max_point, total = 0, self.player:getCards("he"):length()
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if c:getNumber() > max_point then max_point = c:getNumber() end
	end
	if max_point <= 10 and not (self.player:getHp() > 2 and total >= 3) then return end
	use.card = card
end
sgs.ai_use_value["sk_duanlanCard"] = 6
sgs.ai_use_priority["sk_duanlanCard"] = 5

sgs.ai_skill_playerchosen.sk_duanlan = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then table.insert(enemies, t) end
	end
	if #enemies == 0 then return nil end
	local best, best_n
	for _, t in ipairs(enemies) do
		local n = t:getEquips():length()
		if not best_n or n > best_n then best, best_n = t, n end
	end
	return best or enemies[1]
end

sgs.ai_skill_cardchosen.sk_duanlan = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(who:getCards("hej"))
	if #cards == 0 then return -1 end
	self:sortByKeepValueInPlace(cards)
	if self:isFriend(who) then
		return cards[1]:getKnownEffectiveId()
	end
	return cards[#cards]:getKnownEffectiveId()
end

sgs.ai_skill_cardask["@sk_duanlan-pay"] = function(self, data, pattern)
	local need = 14
	if type(pattern) == "string" then
		need = tonumber(pattern:match("%d+")) or 14
	end
	local best
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if c:getNumber() >= need then
			if not best or c:getNumber() < best:getNumber() then best = c end
		end
	end
	if best then return card_answer(best) end
	return "."
end


--朱然：胆守（锁定技）/勇烈
sgs.ai_skill_invoke.sk_yonglie = function(self, data)
	local damage = data:toDamage()
	if not (damage.from and damage.from:isAlive()) then return false end
	return self:isEnemy(damage.from) and self.player:getHp() > 1
end


--丁奉：搏战/轻袭（锁定技）
sgs.ai_skill_cardask["@sk_bozhan-slash"] = sgs.ai_skill_cardask["@pengri-slash"]


--蒋钦：尚义/忘私
local sk_shangyi_skill = {}
sk_shangyi_skill.name = "sk_shangyi"
table.insert(sgs.ai_skills, sk_shangyi_skill)
sk_shangyi_skill.getTurnUseCard = function(self, inclusive)
	if self.player:getStrategyHasUsed("#sk_shangyiCard") then return nil end
	return sgs.Card_Parse("#sk_shangyiCard:.:")
end

sgs.ai_skill_use_func["#sk_shangyiCard"] = function(card, use, self)
	local targets = {}
	for _, p in ipairs(self.enemies) do
		if not p:isKongcheng() then table.insert(targets, p) end
	end
	if #targets == 0 then
		for _, p in ipairs(self.friends_noself) do table.insert(targets, p) end
	end
	if #targets == 0 then return nil end
	self:sortInPlace(targets, "handcard")
	use.card = card
	if use.to then use.to:append(targets[#targets]) end
end
sgs.ai_use_value["sk_shangyiCard"] = 5
sgs.ai_use_priority["sk_shangyiCard"] = 6

sgs.ai_skill_choice["sk_shangyi"] = function(self, choices, data)
	return "shangyi_hand"
end

sgs.ai_skill_invoke.sk_wangsi = function(self, data)
	local damage = data:toDamage()
	return damage.from and self:isEnemy(damage.from) and not damage.from:isKongcheng()
end


--周泰：不屈（锁定技）/奋激
sgs.ai_skill_invoke.sk_fenji = function(self, data)
	local target = data:toPlayer()
	if not target then return false end
	if self.player:getHp() <= 1 then return false end
	return self:isFriend(target)
end


--陆绩：怀橘/浑天
sgs.ai_skill_invoke.sk_huaiju = true

sgs.ai_skill_choice.sk_huaiju = function(self, choices)
	if self:getOverflow() > 0 then return "huaiju_discard" end
	return "huaiju_draw"
end

sgs.ai_skill_invoke.sk_huntian = true

sgs.ai_skill_askforag.sk_huntian = function(self, card_ids)
	local cards = {}
	for _, id in sgs.list(card_ids) do
		table.insert(cards, face(self, id))
	end
	if #cards == 0 then return -1 end
	self:sortByKeepValueInPlace(cards)
	return cards[1]:getKnownEffectiveId()
end

sgs.ai_skill_askforag.sk_huntian_more = function(self, card_ids)
	return -1
end


--诸葛瑾：缓兵（锁定技）/弘援
sgs.ai_fill_skill.sk_hongyuan = function(self, inclusive, request)
	if self.player:getLostHp() <= 0 then return nil end
	if self.player:getStrategyHasUsed("#sk_hongyuanCard") then return nil end
	local field = 0
	for _, p in sgs.qlist(self.room:getAllPlayers()) do
		field = field + p:getCards("ej"):length()
	end
	if field <= 0 then return nil end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return nil end
	self:sortByKeepValueInPlace(cards)
	local n = math.min(self.player:getLostHp(), #cards, field)
	local ids = {}
	for i = 1, n do
		table.insert(ids, cards[i]:getKnownEffectiveId())
	end
	return seed(self,"#sk_hongyuanCard:" .. table.concat(ids, "+") .. ":")
end

sgs.ai_skill_use_func["#sk_hongyuanCard"] = function(card, use, self)
	local target = self.player
	for _, p in ipairs(self.friends) do
		if not p:getJudgingArea():isEmpty() then
			target = p
			break
		end
	end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_value["sk_hongyuanCard"] = 60
sgs.ai_use_priority["sk_hongyuanCard"] = 4
sgs.ai_card_intention["sk_hongyuanCard"] = -80

--徐氏：问卦/伏诛
sgs.ai_skill_exchange = sgs.ai_skill_exchange or {}
sgs.ai_skill_exchange["sk_wengua"] = function(self, pattern, max_num, min_num, expand_pile)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return nil end
	self:sortByKeepValueInPlace(cards)
	if pattern and string.find(pattern,"@sk_wengua%-give") then
		local promptlist = pattern:split(":")
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist])
		if not (target and self:isFriend(target)) then return nil end
	end
	return { cards[1]:getKnownEffectiveId() }
end

sgs.ai_fill_skill.sk_fuzhu = function(self, inclusive, request)
	if self.player:getStrategyHasUsed("#sk_fuzhuCard") then return nil end
	return seed(self,"#sk_fuzhuCard:.:")
end

sgs.ai_skill_use_func["#sk_fuzhuCard"] = function(card, use, self)
	local target
	for _, p in ipairs(self.enemies) do
		if not target or p:getHp() < target:getHp()
			or (p:getHp() == target:getHp() and p:getHandcardNum() < target:getHandcardNum()) then
			target = p
		end
	end
	if not target then return end
	use.card = card
	if use.to then use.to:append(target) end
end

sgs.ai_use_value["sk_fuzhuCard"] = 60
sgs.ai_use_priority["sk_fuzhuCard"] = 4
sgs.ai_card_intention["sk_fuzhuCard"] = 120


--周妃：姻缘/箜篌
sgs.ai_skill_playerchosen.sk_yinyuan = function(self, targets)
	local best
	for _, t in sgs.qlist(targets) do
		if self:isFriend(t) and (not best or t:getHandcardNum() < best:getHandcardNum()) then
			best = t
		end
	end
	if best then return best end
	for _, t in sgs.qlist(targets) do
		if t:objectName() == self.player:objectName() then return t end
	end
	return nil
end

sgs.ai_playerchosen_intention.sk_yinyuan = -60

sgs.ai_skill_cardask["@sk_konghou-discard"] = function(self, data)
	local use = data:toCardUse()
	if not (use and use.from) then return "." end
	if not self:isEnemy(use.from) then return "." end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if #cards == 0 then return "." end
	self:sortByKeepValueInPlace(cards)
	return card_answer(cards[1])
end


--潘淑：锦织/鱼忧
sgs.ai_fill_skill.sk_jinzhi = function(self, inclusive, request)
	if self.player:isKongcheng() then return nil end
	if self.player:isWounded() then
		return seed(self,"#sk_jinzhi:.:peach")
	end
	local slash = evaluation(self,"slash")
	for _, enemy in ipairs(self.enemies) do
		if self.player:canSlash(enemy) and not self:slashProhibit(slash, enemy, self.player)
			and self:slashIsEffective(slash, enemy, self.player)
			and self:isGoodTarget(enemy, self.enemies, nil) then
			return seed(self,"#sk_jinzhi:.:slash")
		end
	end
	return nil
end

sgs.ai_skill_use_func["#sk_jinzhi"] = function(card, use, self)
	local userstring = card:getLegacyStringKey()
	local name
	for _, p in ipairs(userstring:split(":")) do
		if p == "peach" or p == "analeptic" or p == "slash" or p == "fire_slash" or p == "thunder_slash" then
			name = p
		end
	end
	if not name then return end
	local jinzhi_card = declared(self,"sk_jinzhi",card,name)
	self:useBasicCard(jinzhi_card, use)
	if not use.card then return end
	use.card = card
end

sgs.ai_use_priority["sk_jinzhi"] = 8
sgs.ai_use_value["sk_jinzhi"] = 8

sgs.ai_skill_askforag["@sk_yuyou-keep"] = function(self, card_ids)
	local cards = {}
	for _, id in sgs.list(card_ids) do
		table.insert(cards, face(self, id))
	end
	if #cards == 0 then return -1 end
	self:sortByKeepValueInPlace(cards)
	return cards[1]:getKnownEffectiveId()
end

sgs.ai_skill_playerchosen.sk_yuyou = function(self, targets)
	local best
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then
			if not best or t:getHp() < best:getHp()
				or (t:getHp() == best:getHp() and t:getHandcardNum() < best:getHandcardNum()) then
				best = t
			end
		end
	end
	return best
end

sgs.ai_playerchosen_intention.sk_yuyou = 60

sgs.ai_skill_choice["sk_yuyou"] = function(self, choices, data)
	local n = 1
	if data then n = data:toInt() or 1 end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	if self.player:getHp() <= 1 then return "yuyou_discard" end
	if n <= #cards and n <= 2 then return "yuyou_discard" end
	if n > #cards then return "yuyou_discard" end
	return "yuyou_losehp"
end


--孙休：宴诛/兴学
sgs.ai_fill_skill.sk_yanzhu = function(self, inclusive, request)
	if self.player:getStrategyHasUsed("#sk_yanzhuCard") then return nil end
	return seed(self,"#sk_yanzhuCard:.:")
end

sgs.ai_skill_use_func["#sk_yanzhuCard"] = function(card, use, self)
	local target
	for _, e in ipairs(self.enemies) do
		local m = e:getStrategyMark("@sk_yanzhu")
		if m == 2 and self:damageIsEffective(e, sgs.DamageStruct_Normal)
			and self:canDamage(e, self.player, nil) and not self:cantbeHurt(e) then
			target = e
			break
		end
	end
	if not target then
		for _, e in ipairs(self.enemies) do
			if e:getStrategyMark("@sk_yanzhu") == 1 and not e:isKongcheng() then
				target = e
				break
			end
		end
	end
	if not target then
		for _, f in ipairs(self.friends) do
			if f:getStrategyMark("@sk_yanzhu") == 0 then
				target = f
				break
			end
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_use_value["sk_yanzhuCard"] = 70
sgs.ai_use_priority["sk_yanzhuCard"] = 4
sgs.ai_card_intention["sk_yanzhuCard"] = function(self, card, from, tos)
	local to = tos[1]
	if to and to:getStrategyMark("@sk_yanzhu") > 0 then return 60 end
	return -30
end

sgs.ai_skill_playerchosen.sk_xingxue = function(self, targets)
	local selfname = self.player:objectName()
	for _, t in sgs.qlist(targets) do
		if t:objectName() == selfname and t:getStrategyMark("@sk_yanzhu") > 0 then return t end
	end
	local best, best_m = nil, 0
	for _, t in sgs.qlist(targets) do
		local m = t:getStrategyMark("@sk_yanzhu")
		if self:isFriend(t) and m > best_m then
			best = t
			best_m = m
		end
	end
	if best then return best end
	for _, t in sgs.qlist(targets) do
		local m = t:getStrategyMark("@sk_yanzhu")
		if self:isEnemy(t) and t:getHandcardNum() + m > t:getMaxHp() then
			return t
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sk_xingxue = -40


--孙登：匡弼
sgs.ai_skill_invoke.sk_kuangbi = function(self, data)
	local use = data:toCardUse()
	if not (use and use.from and use.card and use.to) then return false end
	if not self:isEnemy(use.from) then return false end
	local harmful = use.card:isKindOf("Slash") or use.card:isKindOf("Duel")
		or use.card:isKindOf("SavageAssault") or use.card:isKindOf("ArcheryAttack")
		or use.card:isKindOf("Dismantlement") or use.card:isKindOf("Snatch")
		or use.card:isKindOf("FireAttack")
	if harmful then
		for _, t in sgs.qlist(use.to) do
			if self:isFriend(t) then return true end
		end
		return false
	end
	for _, t in sgs.qlist(use.to) do
		if self:isFriend(t) then return false end
	end
	return #self.friends > 0
end

sgs.ai_skill_playerschosen.sk_kuangbi = function(self, targets, max_num, min_num)
	local chosen = {}
	if self.player:getStrategyMark("sk_kuangbi_harm-Clear") > 0 then
		for _, p in sgs.qlist(targets) do
			if self:isEnemy(p) then table.insert(chosen, p) end
		end
	else
		for _, p in sgs.qlist(targets) do
			if self:isFriend(p) then table.insert(chosen, p) end
		end
	end
	return chosen
end


--朱治：安国
sgs.ai_skill_playerchosen.sk_anguo = function(self, targets)
	local wounded = {}
	for _, t in sgs.qlist(targets) do
		if self:isFriend(t) and t:isWounded() then table.insert(wounded, t) end
	end
	if #wounded > 0 then
		self:sortInPlace(wounded, "hp")
		return wounded[1]
	end
	local selfname = self.player:objectName()
	for _, t in sgs.qlist(targets) do
		if t:objectName() == selfname then return t end
	end
	for _, t in sgs.qlist(targets) do
		if self:isFriend(t) then return t end
	end
	return nil
end

sgs.ai_playerchosen_intention.sk_anguo = -50


--孙亮：溃诛
sgs.ai_skill_playerchosen.sk_kuizhu = function(self, targets)
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if t:objectName() == e:objectName() then return t end
		end
	end
	return nil
end

sgs.ai_playerchosen_intention.sk_kuizhu = 60


--孙亮：掣政
local function sk_chezheng_pick(self, targets)
	local rich_enemy, friend = nil, nil
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) and t:getHandcardNum() >= 3 then
			if not rich_enemy or t:getHandcardNum() > rich_enemy:getHandcardNum() then
				rich_enemy = t
			end
		elseif self:isFriend(t) and not friend then
			friend = t
		end
	end
	return rich_enemy, friend
end

sgs.ai_skill_invoke.sk_chezheng = function(self, data)
	local rich_enemy, friend = sk_chezheng_pick(self, self.room:getAlivePlayers())
	return rich_enemy ~= nil or friend ~= nil
end

sgs.ai_skill_playerschosen.sk_chezheng = function(self, targets, max_num, min_num)
	local rich_enemy, friend = sk_chezheng_pick(self, targets)
	local chosen = {}
	if rich_enemy then
		for _, t in sgs.qlist(targets) do
			if self:isEnemy(t) and t:getHandcardNum() >= 3 then table.insert(chosen, t) end
		end
	elseif friend then
		for _, t in sgs.qlist(targets) do
			if self:isFriend(t) then table.insert(chosen, t) end
		end
	end
	return chosen
end

sgs.ai_skill_choice["sk_chezheng"] = function(self, choices)
	for _, t in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isEnemy(t) and t:getHandcardNum() >= 3 then
			return "sk_chezheng_discard"
		end
	end
	return "sk_chezheng_play"
end


--葛玄：炼化
sgs.ai_skill_invoke.sk_lianhua = function(self, data)
	local current = self.room:getCurrent()
	if not current then return false end
	if self:isFriend(current) then return true end
	return self:isEnemy(current) and current:getHandcardNum() <= 2
end

sgs.ai_skill_cardchosen.sk_lianhua = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(who:getCards("h"))
	if #cards == 0 then return nil end
	self:sortByKeepValueInPlace(cards)
	if self:isFriend(who) then
		return cards[1]:getEffectiveId()
	end
	return cards[#cards]:getEffectiveId()
end


--臧霸：横江
sgs.ai_skill_choice["sk_hengjiang"] = function(self, choices)
	local field_enemy = false
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if self:isEnemy(p) and (p:hasEquip() or p:getJudgingArea():length() > 0) then
			field_enemy = true
			break
		end
	end
	if field_enemy and self.player:getHandcardNum() > self.player:getHp() then
		return "hengjiang_minus"
	end
	return "hengjiang_plus"
end

sgs.ai_skill_playerchosen.sk_hengjiang = function(self, targets)
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if t:objectName() == e:objectName() then return t end
		end
	end
	return nil
end

sgs.ai_skill_cardchosen.sk_hengjiang = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(who:getCards("ej"))
	if #cards == 0 then return -1 end
	self:sortByKeepValueInPlace(cards)
	if self:isFriend(who) then return cards[1]:getEffectiveId() end
	return cards[#cards]:getEffectiveId()
end
sgs.ai_playerchosen_intention.sk_hengjiang = 60


--卞夫人：化戈
sgs.ai_fill_skill.sk_huage = function(self, inclusive, request)
	if self.player:getStrategyHasUsed("#sk_huageCard") then return nil end
	return seed(self,"#sk_huageCard:.:")
end

sgs.ai_skill_use_func["#sk_huageCard"] = function(card, use, self)
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:isKindOf("Slash") then use.card = card return end
	end
	if #self.enemies > #self.friends_noself then use.card = card end
end

sgs.ai_use_value["sk_huageCard"] = 6
sgs.ai_use_priority["sk_huageCard"] = 5

sgs.ai_skill_exchange["sk_huage"] = function(self, pattern, max_num, min_num, expand_pile)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	if #cards == 0 then return nil end
	self:sortByKeepValueInPlace(cards)
	for _, c in ipairs(cards) do
		if c:isKindOf("Slash") then return { c:getKnownEffectiveId() } end
	end
	return { cards[1]:getKnownEffectiveId() }
end


--卞夫人：母仪
sgs.ai_skill_exchange["sk_muyi"] = function(self, pattern, max_num, min_num, expand_pile)
	local cards = sgs.QList2Table(self.player:getCards("h"))
	if #cards == 0 then return nil end
	self:sortByKeepValueInPlace(cards)
	if pattern and string.find(pattern,"@muyi%-give") then
		local promptlist = pattern:split(":")
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist])
		if not (target and self:isFriend(target)) then return nil end
		return { cards[1]:getKnownEffectiveId() }
	elseif pattern and string.find(pattern,"@muyi%-back") then
		local ids = {}
		for i = 1, math.min(min_num, #cards) do
			table.insert(ids, cards[i]:getKnownEffectiveId())
		end
		return ids
	end
	return nil
end


--戏志才：天策/竭心
sgs.ai_skill_playerchosen.sk_tiance = function(self, targets)
	for _, t in sgs.qlist(targets) do
		if t:objectName() == self.player:objectName() then return t end
	end
	for _, t in sgs.qlist(targets) do
		if self:isFriend(t) then return t end
	end
	return nil
end
sgs.ai_playerchosen_intention.sk_tiance = -40

sgs.ai_skill_choice["sk_tiance"] = function(self, choices, data)
	local list = type(choices) == "table" and choices or choices:split("+")
	for _, c in ipairs(list) do
		if c == "tiance_others" and #self.enemies > #self.friends_noself then return c end
	end
	for _, c in ipairs(list) do
		if c == "tiance_drawpile" then return c end
	end
	for _, c in ipairs(list) do
		if c ~= "cancel" then return c end
	end
	return "cancel"
end


--曹睿：恢拓/兴衰
sgs.ai_skill_playerchosen.sk_huituo = function(self, targets)
	local friends = {}
	for _, t in sgs.qlist(targets) do
		if self:isFriend(t) then table.insert(friends, t) end
	end
	if #friends == 0 then return nil end
	self:sortInPlace(friends, "hp")
	self.sk_huituo_target = friends[1]
	return friends[1]
end
sgs.ai_playerchosen_intention.sk_huituo = -60

sgs.ai_skill_choice["sk_huituo"] = function(self, choices, data)
	local list = type(choices) == "table" and choices or choices:split("+")
	local target = self.sk_huituo_target
	local has = {}
	for _, c in ipairs(list) do has[c] = true end
	if target and target:isWounded() and target:getHp() <= 2 and has["huituo_recover"] then return "huituo_recover" end
	if has["huituo_draw"] then return "huituo_draw" end
	if has["huituo_equip"] then return "huituo_equip" end
	if has["huituo_recover"] and target and target:isWounded() then return "huituo_recover" end
	if has["huituo_acquire"] and target and target:objectName() ~= self.player:objectName() then return "huituo_acquire" end
	return "cancel"
end

sgs.ai_skill_playerchosen.sk_xingshuai = function(self, targets)
	for _, t in sgs.qlist(targets) do
		if self:isFriend(t) and not t:faceUp() then return t end
	end
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) and t:faceUp() then return t end
	end
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then return t end
	end
	return nil
end
sgs.ai_playerchosen_intention.sk_xingshuai = 40

sgs.ai_skill_choice["sk_xingshuai"] = function(self, choices, data)
	local caorui = self.room:findPlayerBySkillName("sk_xingshuai")
	if not self.player:faceUp() then return "xingshuai_turnover" end
	if caorui and self:isFriend(caorui) then return "xingshuai_extraturn" end
	return "xingshuai_turnover"
end


--曹休：讨袭
sgs.ai_fill_skill.sk_taoxi = function(self, inclusive, request)
	if self.player:getStrategyHasUsed("#sk_taoxiCard") then return nil end
	return seed(self,"#sk_taoxiCard:.:")
end

sgs.ai_skill_use_func["#sk_taoxiCard"] = function(card, use, self)
	local n = 0
	for _, e in ipairs(self.enemies) do
		if not e:isKongcheng() then n = n + 1 end
	end
	if n == 0 then return nil end
	use.card = card
end

sgs.ai_use_value["sk_taoxiCard"] = 6
sgs.ai_use_priority["sk_taoxiCard"] = 9


--关羽：拖刀
sgs.ai_skill_cardask["@sk_tuodao"] = function(self, data, pattern, target)
	if target then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:isFriend(target) then
				return "."
			end
			if self:slashIsEffective(slash, target) then
				return card_answer(slash)
			end
		end
		for _, slash in ipairs(self:getCards("Slash")) do
			if not self:isFriend(target) then return card_answer(slash) end
		end
	end
	return "."
end


--辛宪英：才鉴
sgs.ai_fill_skill.sk_caijian = function(self, inclusive, request)
	if self.player:getStrategyHasUsed("#sk_caijianCard") then return nil end
	return seed(self,"#sk_caijianCard:.:")
end

sgs.ai_skill_use_func["#sk_caijianCard"] = function(card, use, self)
	for _, e in ipairs(self.enemies) do
		if not e:isNude() and e:faceUp() then
			use.card = card
			if use.to then use.to:append(e) end
			return
		end
	end
	for _, e in ipairs(self.enemies) do
		if not e:isNude() then
			use.card = card
			if use.to then use.to:append(e) end
			return
		end
	end
end

sgs.ai_use_value["sk_caijianCard"] = 6
sgs.ai_use_priority["sk_caijianCard"] = 6
sgs.ai_card_intention["sk_caijianCard"] = 60

sgs.ai_skill_playerchosen.sk_caijian = function(self, targets)
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if t:objectName() == e:objectName() and t:faceUp() then return t end
		end
	end
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if t:objectName() == e:objectName() then return t end
		end
	end
	return nil
end
sgs.ai_playerchosen_intention.sk_caijian = 60

sgs.ai_skill_cardchosen.sk_caijian = function(self, who, flags, reason, method)
	local cards = sgs.QList2Table(who:getCards("he"))
	if #cards == 0 then return -1 end
	local suits = {}
	for _, id in sgs.qlist(self.player:getPile("sk_jian")) do
		suits[(face(self,id)):getSuit()] = true
	end
	self:sortByKeepValueInPlace(cards)
	for i = #cards, 1, -1 do
		local c = cards[i]
		if c:isKindOf("EquipCard") and c:isBlack() and not suits[c:getSuit()] then
			return c:getKnownEffectiveId()
		end
	end
	return cards[#cards]:getKnownEffectiveId()
end


--辛宪英：智识
sgs.ai_fill_skill.sk_zhishi = function(self, inclusive, request)
	local suits = {}
	for _, id in sgs.qlist(self.player:getPile("sk_jian")) do
		suits[(face(self,id)):getSuit()] = id
	end
	local picked = {}
	for _, id in pairs(suits) do
		table.insert(picked, id)
		if #picked == 3 then break end
	end
	if #picked < 3 then return nil end
	return seed(self,"#sk_zhishiCard:" .. table.concat(picked, "+") .. ":")
end

sgs.ai_skill_use_func["#sk_zhishiCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_use_value["sk_zhishiCard"] = 8
sgs.ai_use_priority["sk_zhishiCard"] = 9


--王朗：劝降
sgs.ai_fill_skill.sk_quanxiang = function(self, inclusive, request)
	if self.player:isKongcheng() then return nil end
	return seed(self,"#sk_quanxiangCard:.:")
end

sgs.ai_skill_use_func["#sk_quanxiangCard"] = function(card, use, self)
	if self.player:getStrategyMark("@sk_raoshe") > 4 then return nil end
	local max_num = 0
	for _, c in sgs.qlist(self.player:getHandcards()) do
		max_num = math.max(max_num, c:getNumber())
	end
	if max_num + self.player:getStrategyMark("@sk_raoshe") < 10 then return nil end
	for _, e in ipairs(self.enemies) do
		if not e:isKongcheng() then
			use.card = card
			if use.to then use.to:append(e) end
			return
		end
	end
end

sgs.ai_use_value["sk_quanxiangCard"] = 6
sgs.ai_use_priority["sk_quanxiangCard"] = 5
sgs.ai_card_intention["sk_quanxiangCard"] = 80


--王朗：激词
sgs.ai_skill_invoke.sk_jici = function(self, data)
	if self.player:getStrategyMark("@sk_raoshe") > 5 then return false end
	local damage = data:toDamage()
	local n = (damage and damage.damage) or 1
	for _, c in sgs.qlist(self.player:getHandcards()) do
		if c:getNumber() >= 10 then return true end
	end
	return n >= 2 or self.player:getHp() <= n
end


--sp姜维：才遇
sgs.ai_skill_invoke.sk_caiyu = function(self, data)
	local maxhp = self.player:getMaxHp()
	if maxhp <= 1 then return false end
	if maxhp <= 2 and self.player:getHp() <= 1 then return false end
	return true
end


--左慈：千幻
sgs.ai_skill_choice.sk_qianhuan = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "cancel") then return "cancel" end
	return items[math.random(1, #items)]
end


--吉平：毒治
sgs.ai_skill_invoke.sk_duzhi = function(self, data)
	for _, e in ipairs(self.enemies) do
		if e:getHp() <= 2 or e:isKongcheng() then return true end
	end
	return #self.enemies > 0 and self.player:getHp() > 1
end

sgs.ai_skill_playerchosen.sk_duzhi = function(self, targets)
	local best = nil
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if t:objectName() == e:objectName() then
				if not best or t:getHp() < best:getHp() or (t:getHp() == best:getHp() and t:isKongcheng()) then
					best = t
				end
			end
		end
	end
	return best
end
sgs.ai_playerchosen_intention.sk_duzhi = 80

sgs.ai_skill_cardask["@sk_duzhi-slash"] = function(self, data, pattern, target)
	if target and not self:isFriend(target) then
		for _, slash in ipairs(self:getCards("Slash")) do
			if self:slashIsEffective(slash, target) then
				return card_answer(slash)
			end
		end
	end
	return "."
end


--何进：专擅
sgs.ai_skill_invoke.sk_zhuanshan = true

sgs.ai_skill_playerchosen.sk_zhuanshan = function(self, targets)
	for _, e in ipairs(self.enemies) do
		for _, t in sgs.qlist(targets) do
			if t:objectName() == e:objectName() and #t:getEquips() > 0 then return t end
		end
	end
	for _, t in sgs.qlist(targets) do
		if t:objectName() == self.player:objectName() then return t end
	end
	return nil
end

sgs.ai_skill_cardchosen.sk_zhuanshan = function(self, who, flags, reason, method)
	if self:isEnemy(who) then
		local armor = who:getArmor()
		if armor then return armor:getKnownEffectiveId() end
		local equips = sgs.QList2Table(who:getCards("e"))
		if #equips > 0 then return equips[1]:getKnownEffectiveId() end
	end
	local cards = sgs.QList2Table(who:getCards("h"))
	if #cards == 0 then cards = sgs.QList2Table(who:getCards("he")) end
	if #cards == 0 then return -1 end
	self:sortByKeepValueInPlace(cards)
	return cards[1]:getKnownEffectiveId()
end


--蒯越：异度/诛暴
sgs.ai_skill_invoke.sk_yidu = true

sgs.ai_skill_invoke.sk_zhubao = true


--卢植：经纶/儒宗
sgs.ai_skill_invoke.sk_jinglun = true

sgs.ai_view_as["sk_ruzong"] = function(card, player, card_place, class_name)
	if card_place ~= sgs.Player_PlaceHand then return end
	local card_id = card:getKnownEffectiveId()
	if class_name == "Jink" and card:isKindOf("Nullification") then
		return {name="jink",skill="sk_ruzong",suit=card:getSuit(),number=card:getNumber(),subcards={card_id}}
	elseif class_name == "Nullification" and card:isKindOf("Jink") then
		return {name="nullification",skill="sk_ruzong",suit=card:getSuit(),number=card:getNumber(),subcards={card_id}}
	end
end


--于吉：蛊惑/符箓
sgs.ai_skill_invoke.sk_guhuo = function(self, data)
	local player = data:toPlayer()
	if not player then return false end
	local max_card = self:getMaxCard()
	if not max_card then return false end
	if max_card:getNumber() >= 10 and self:isEnemy(player) then return true end
	return max_card:getNumber() >= 12
end

sgs.ai_skill_choice["sk_guhuo"] = function(self, choices, data)
	local list = type(choices) == "table" and choices or choices:split("+")
	for _, c in ipairs({"duel","dismantlement","snatch","fire_attack","slash"}) do
		for _, v in ipairs(list) do
			if v == c then return v end
		end
	end
	return list[1]
end

sgs.ai_skill_choice["sk_guhuo_slash"] = function(self, choices, data)
	local list = type(choices) == "table" and choices or choices:split("+")
	for _, c in ipairs({"fire_slash","thunder_slash","slash","normal_slash"}) do
		for _, v in ipairs(list) do
			if v == c then return v end
		end
	end
	return list[1]
end

sgs.ai_skill_playerchosen.sk_guhuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, t in ipairs(targets) do
		if self:isEnemy(t) then return t end
	end
	return targets[1]
end

sgs.ai_skill_invoke.sk_fulu = true

--SP马超：雄烈
sgs.ai_skill_invoke.sk_xionglie = true
sgs.ai_skill_choice.sk_xionglie = function(self, choices, data)
 local use = data:toCardUse()
 if use then
  for _, p in sgs.qlist(use.to) do
   if self:isEnemy(p) and self:getCardsNum("Jink", p) > 0 then return "no_response" end
  end
 end
 return "damage"
end

--董白：奢靡/狡慧
sgs.ai_skill_exchange.sk_shemi = function(self, pattern, max_num, min_num, expand_pile) return {} end
sgs.ai_skill_invoke.sk_jiaohui = true
sgs.ai_skill_choice.sk_jiaohui = function(self, choices, data)
 if self.player:getHandcardNum() == self.player:getHp() + 1 then return "discard" end
 return "draw"
end

--张梁：集军及主动衍生技能
sgs.ai_fill_skill.sk_jijun = function(self, inclusive, request)
 if self.player:getStrategyHasUsed("#sk_jijunCard") then return nil end
 local cards = sgs.QList2Table(self.player:getHandcards())
 table.sort(cards, function(a,b) return a:getNumber() > b:getNumber() end)
 local suits, ids = {}, {}
 for _, c in ipairs(cards) do
  local suit = c:getSuit()
  if not suits[suit] and #ids < 4 and not c:isKindOf("Peach") then
   suits[suit] = true; table.insert(ids, c:getKnownEffectiveId())
  end
 end
 return seed(self,"#sk_jijunCard:" .. (#ids > 0 and table.concat(ids,"+") or ".") .. ":")
end
sgs.ai_skill_use_func["#sk_jijunCard"] = function(card, use, self) use.card = card end
sgs.ai_skill_choice.sk_jijun = function(self, choices, data)
 local list = type(choices) == "table" and choices or choices:split("+")
 for _, c in ipairs(list) do if c == "put" then return c end end
 return list[1]
end
sgs.ai_skill_choice.sk_jijun_basic = function(self, choices, data)
 local list = type(choices) == "table" and choices or choices:split("+")
 if self.player:isWounded() then
  for _, c in ipairs(list) do if c == "peach" then return c end end
 end
 for _, wanted in ipairs({"slash","fire_slash","thunder_slash","normal_slash","analeptic"}) do
  for _, c in ipairs(list) do if c == wanted then return c end end
 end
 return list[1]
end
sgs.ai_skill_playerchosen.sk_jijun = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
 return nil
end
sgs.ai_skill_playerchosen.sk_zhangliang_leiji = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
 return nil
end
sgs.ai_skill_cardask["@sk_zhangliang_zhoufu"] = function(self, data)
 local current = self.room:getCurrent()
 if current and self:isEnemy(current) then
  local cards = sgs.QList2Table(self.player:getHandcards())
  self:sortByKeepValueInPlace(cards)
  for _, c in ipairs(cards) do if not c:isKindOf("Peach") then return card_answer(c) end end
 end
 return "."
end
sgs.ai_skill_invoke.sk_zhangliang_shendao = function(self, data)
 self.sk_zhangliang_shendao_judge = data:toJudge()
 return self:needRetrial(self.sk_zhangliang_shendao_judge)
end
sgs.ai_skill_askforag.sk_zhangliang_shendao = function(self, card_ids)
 local cards = {}
 for _, id in ipairs(card_ids) do table.insert(cards,face(self,id)) end
 local judge = self.sk_zhangliang_shendao_judge
 if judge then
  local id = self:getRetrialCardId(cards, judge)
  if id and id >= 0 then return id end
 end
 return -1
end
sgs.ai_skill_askforag.sk_jijun = function(self, card_ids) return card_ids[1] end

--曹节：掷玺
sgs.ai_fill_skill.sk_zhixi = function(self, inclusive, request)
 if self.player:getStrategyHasUsed("#sk_zhixiCard") or (self.player:getPile("sk_xi")):isEmpty() then return nil end
 return seed(self,"#sk_zhixiCard:.:")
end
sgs.ai_skill_use_func["#sk_zhixiCard"] = function(card, use, self)
 for _, p in ipairs(self.enemies) do
  if p:isAlive() then use.card = card; if use.to then use.to:append(p) end; return end
 end
end

--沮授：渐营/矢北
sgs.ai_skill_invoke.sk_jianying = true
sgs.ai_skill_invoke.sk_shibei = true
sgs.ai_skill_use["@@sk_shibei"] = function(self, prompt)
 local cards = sgs.QList2Table(self.player:getCards("he"))
 self:sortByKeepValueInPlace(cards)
 for _, material in ipairs(cards) do
  local card = self:evaluateSkillCard("sk_shibei", nil, {material:getKnownEffectiveId()})
  local use = {isDummy = true, to = sgs.SPlayerList()}
  self:useCardByClassName(card, use)
  if use.card then
   local targets = {}
   for _, p in sgs.qlist(use.to) do table.insert(targets,p:objectName()) end
   return {kind="use_card",card_spec=card:toCardSpec(),targets=targets}
  end
 end
 return "."
end

--严颜：拒战
sgs.ai_skill_invoke.sk_juzhan = function(self, data)
 return self.player:getLostHp() > 0 or self:getCardsNum("Jink") > 0
end
sgs.ai_skill_choice.sk_juzhan = function(self, choices, data)
 local x = data:toInt()
 if x == 0 then return "discard" end
 local count = hand_count(self.player)
 if count >= x and (x <= 1 or count - x >= 3) then return "discard" end
 return "end"
end

--诸葛瞻：妖智
sgs.ai_skill_invoke.sk_yaozhi = true
sgs.ai_fill_skill.sk_yaozhi = function(self, inclusive, request)
 if not self.player:getStrategyHasUsed("#sk_yaozhiCard") then return seed(self,"#sk_yaozhiCard:.:" ) end
end
sgs.ai_skill_use_func["#sk_yaozhiCard"] = function(card, use, self) use.card = card end

--潘璋：截军
sgs.ai_skill_cardask["@sk_jiejun"] = function(self, data, pattern, target)
 if target and self:isEnemy(target) then
  for _, card in ipairs(sgs.QList2Table(self.player:getHandcards())) do
   if card:isKindOf("Slash") and self:slashIsEffective(card, target) then return card_answer(card) end
  end
 end
 return "."
end

--孙茹：撷翠/忧恤
sgs.ai_skill_use["@@sk_xiecui"] = function(self, prompt)
 local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValueInPlace(cards)
 for i, a in ipairs(cards) do
  for j = i + 1, #cards do
   local b = cards[j]
   if a:getSuit() ~= b:getSuit() and not self.player:isJilei(a) and not self.player:isJilei(b) then
    return {kind="use_card",card_spec="#sk_xiecuiCard:" .. a:getKnownEffectiveId() .. "+" .. b:getKnownEffectiveId() .. ":",targets={}}
   end
  end
 end
 return "."
end
sgs.ai_skill_choice.sk_xiecui = function(self, choices, data)
 local damage = data:toDamage()
 return damage and self:isEnemy(damage.to) and "increase" or "decrease"
end
sgs.ai_skill_invoke.sk_youxu = true
sgs.ai_skill_choice.sk_youxu = function(self, choices, data)
 local target = data:toPlayer()
 return target and target:isWounded() and self:isFriend(target) and "peach" or "amazing_grace"
end

--岑昏：极奢
sgs.ai_fill_skill.sk_jishe = function(self, inclusive, request)
 if self.player:getStrategyMark("sk_jishe_count") >= self.player:getMaxHp() then return end
 for _, name in ipairs({"ex_nihilo", "snatch", "dismantlement", "iron_chain", "god_salvation", "amazing_grace", "fire_attack"}) do
  local card = self:evaluateSkillCard("sk_jishe", name, {})
  local use = {isDummy = true, to = sgs.SPlayerList()}
  self:useCardByClassName(card, use)
  if use.card then return card end
 end
end

--刘焉：逐鹿/立牧
sgs.ai_skill_invoke.sk_zhulu = function(self, data)
 return self:isEnemy(data:toDamage().to)
end
sgs.ai_fill_skill.sk_limu = function(self, inclusive, request)
 if self.player:getStrategyHasUsed("#sk_limuCard") or self.player:containsTrick("indulgence") then return end
 local cards = sgs.QList2Table(self.player:getCards("he"))
 local best
 for _, card in ipairs(cards) do
  if card:getSuit() == sgs.Card_Diamond and (not best or card:getNumber() > best:getNumber()) then best = card end
 end
 if best then return seed(self,"#sk_limuCard:" .. best:getKnownEffectiveId() .. ":") end
end
sgs.ai_skill_use_func["#sk_limuCard"] = function(card, use, self) use.card = card end

--公孙渊：怀异
sgs.ai_fill_skill.sk_huaiyi = function(self, inclusive, request)
 if not self.player:getStrategyHasUsed("#sk_huaiyiCard") then return seed(self,"#sk_huaiyiCard:.:") end
end
sgs.ai_skill_use_func["#sk_huaiyiCard"] = function(card, use, self)
 local enemies = self.enemies
 self:sortInPlace(enemies, "defense")
 for _, target in ipairs(enemies) do
  if target:getCardCount(true) > 0 then use.card = card; use.to:append(target); return end
 end
end

--南华老仙：仙授；天道为锁定技，保留其必要的目标选择。
sgs.ai_skill_invoke.sk_xianshou = true
sgs.ai_skill_playerchosen.sk_xianshou = function(self, targets)
 for _, target in sgs.qlist(targets) do
  if self:isFriend(target) and not target:hasSkill("sk_tiandao") then return target end
 end
 for _, target in sgs.qlist(targets) do if self:isFriend(target) then return target end end
 return targets:first()
end
sgs.ai_skill_playerchosen.sk_tiandao = function(self, targets)
 for _, target in sgs.qlist(targets) do if self:isEnemy(target) then return target end end
 return targets:first()
end

sgs.ai_skill_invoke.sk_jueyong = true
sgs.ai_fill_skill.sk_choujue = function(self)
 if not self.player:getStrategyHasUsed("#sk_choujueCard") and self.player:getMaxHp() > 1 then return seed(self,"#sk_choujueCard:.:") end
end
sgs.ai_skill_use_func["#sk_choujueCard"] = function(card, use, self)
 for _, target in ipairs(self.enemies) do
  if not self.player:isProhibited(target, evaluation(self,"slash")) then use.card = card; use.to:append(target); return end
 end
end

sgs.ai_skill_invoke.sk_danxin = true
sgs.ai_fill_skill.sk_jiaozhao = function(self)
 if self.player:getStrategyMark("sk_jiaozhao_used") > 0 then return end
 local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValueInPlace(cards)
 for _, material in ipairs(cards) do
  for _, name in ipairs({"snatch", "dismantlement", "slash", "duel"}) do
   local card = self:evaluateSkillCard("sk_jiaozhao", name, {material:getKnownEffectiveId()})
   local use = {isDummy = true, to = sgs.SPlayerList()}; self:useCardByClassName(card, use)
   if use.card and not use.to:isEmpty() then return card end
  end
 end
end

sgs.ai_skill_invoke.sk_dingguan = function(self, data)
 for _, p in sgs.qlist(data:toCardUse().to) do if self:isFriend(p) then return true end end
 return false
end
sgs.ai_skill_choice.sk_dingguan = function(self, choices, data) return self:isFriend(data:toPlayer()) and "draw" or "cancel" end
sgs.ai_fill_skill.sk_huomo = function(self)
 local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValueInPlace(cards)
 for _, material in ipairs(cards) do
  if material:isBlack() then
   for _, name in ipairs({"peach", "fire_slash", "thunder_slash", "slash", "analeptic"}) do
    if self.player:getStrategyMark("sk_huomo_" .. name) == 0 then
     local card = self:evaluateSkillCard("sk_huomo", name, {material:getKnownEffectiveId()})
     local use = {isDummy = true, to = sgs.SPlayerList()}; self:useCardByClassName(card, use)
     if use.card then return card end
    end
   end
  end
 end
end
sgs.ai_view_as.sk_huomo = function(card, player, place, class_name)
 local name = ({Slash="slash", Jink="jink", Peach="peach", Analeptic="analeptic"})[class_name]
 if name and card:isBlack() and player:getStrategyMark("sk_huomo_" .. name) == 0 then
  return (own_ai(player)):evaluateSkillCard("sk_huomo", name, {card:getKnownEffectiveId()})
 end
end

sgs.ai_skill_invoke.sk_fuhan = true
sgs.ai_skill_invoke.sk_fanghun = function(self, data) return self:isEnemy(data:toPlayer()) end
sgs.ai_fill_skill.sk_fanghun = function(self)
 for _, c in sgs.qlist(self.player:getCards("he")) do
  if c:isKindOf("Jink") then return self:evaluateSkillCard("sk_fanghun", "slash", {c:getKnownEffectiveId()}) end
 end
end
sgs.ai_view_as.sk_fanghun = function(card, player, place, class_name)
 local name = class_name == "Slash" and card:isKindOf("Jink") and "slash" or class_name == "Jink" and card:isKindOf("Slash") and "jink"
 if name then return (own_ai(player)):evaluateSkillCard("sk_fanghun", name, {card:getKnownEffectiveId()}) end
end

sgs.ai_fill_skill.sk_wurong = function(self)
 if not self.player:getStrategyHasUsed("#sk_wurongCard") then return seed(self,"#sk_wurongCard:.:" ) end
end
sgs.ai_skill_use_func["#sk_wurongCard"] = function(card, use, self)
 for _, p in ipairs(self.enemies) do
  if not p:isKongcheng() then use.card = card; if use.to then use.to:append(p) end; return end
 end
end
sgs.ai_skill_invoke.sk_wurong = true
sgs.ai_skill_cardask["@sk_wurong-discard"] = function(self)
 local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValueInPlace(cards)
 if #cards > 0 then return "$" .. cards[1]:getKnownEffectiveId() end
 return "."
end
sgs.ai_skill_choice.sk_wurong = function(self, choices) return choices:split("+")[1] end
sgs.ai_use_value.sk_wurongCard = 5
sgs.ai_use_priority.sk_wurongCard = 4

sgs.ai_fill_skill.sk_dingpin = function(self)
 local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValueInPlace(cards)
 for _, c in ipairs(cards) do if not self.player:isJilei(c) then return seed(self,"#sk_dingpinCard:" .. c:getKnownEffectiveId() .. ":") end end
end
sgs.ai_skill_use_func["#sk_dingpinCard"] = function(card, use, self)
 for _, p in ipairs(self.friends_noself) do
  if p:getStrategyMark("sk_dingpin_" .. self.player:objectName()) == 0 then use.card = card; if use.to then use.to:append(p) end; return end
 end
 for _, p in ipairs(self.enemies) do
  if p:getStrategyMark("sk_dingpin_" .. self.player:objectName()) == 0 then use.card = card; if use.to then use.to:append(p) end; return end
 end
end
sgs.ai_skill_choice.sk_dingpin = function(self, choices, data) return self:isFriend(data:toPlayer()) and "draw" or "discard" end
sgs.ai_skill_invoke.sk_faen = function(self, data) return self:isFriend(data:toPlayer()) end
sgs.ai_use_value.sk_dingpinCard = 6
sgs.ai_use_priority.sk_dingpinCard = 4

sgs.ai_fill_skill.sk_sanjue = function(self)
 if not self.player:getStrategyHasUsed("#sk_sanjueCard") then return seed(self,"#sk_sanjueCard:.:") end
end
sgs.ai_skill_use_func["#sk_sanjueCard"] = function(card, use, self)
 use.card = card
 if use.to then use.to:append(self.player) end
end
sgs.ai_skill_choice.sk_sanjue = function(self, choices, data)
 local target = data:toPlayer()
 for _, name in ipairs(choices:split("+")) do
  if target and not target:hasSkill(name) then return name end
 end
 return choices:split("+")[1]
end
sgs.ai_use_value.sk_sanjueCard = 8
sgs.ai_use_priority.sk_sanjueCard = 7

sgs.ai_skill_invoke.sk_zhendu = function(self, data)
 local target = data:toPlayer()
 return target == self.player or self:isEnemy(target) or (self:isFriend(target) and target:getHp() > 2)
end
sgs.ai_skill_playerchosen.sk_qiluan = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
 if self.room:getTag("sk_qiluan_changes"):toInt() > 0 then return targets:first() end
end

sgs.ai_skill_invoke.sk_canshi = true
sgs.ai_skill_playerchosen.sk_xianji = function(self, targets)
 local best, count
 for _, p in sgs.qlist(targets) do
  local n = p:getSkillList(false, false):length()
  if self:isEnemy(p) and (not count or n > count) then best = p; count = n end
 end
 return best
end

sgs.ai_skill_invoke.sk_xuxie_draw = function(self, data) return data:toCardUse().to:length() > 0 end

sgs.ai_skill_invoke.sk_jili = function(self)
 local score = 0
 for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
  if self.player:inMyAttackRange(p) and not p:isNude() then
   score = score + (self:isEnemy(p) and 1 or -1)
  end
 end
 return score > 0
end

sgs.ai_skill_invoke.sk_fengyin = function(self, data)
 return self:isEnemy(data:toDamage().to)
end

sgs.ai_skill_playerchosen.sk_qinqing = function(self, targets)
 local best, score
 for _, p in sgs.qlist(targets) do
  if self:isFriend(p) then
   local n = p:isWounded() and 1 or 0
   for _, other in sgs.qlist(self.room:getAlivePlayers()) do
    if other:inMyAttackRange(p) and not other:isNude() then n = n + (self:isEnemy(other) and 2 or 1) end
   end
   if not score or n > score then best = p; score = n end
  end
 end
 return best
end
sgs.ai_skill_invoke.sk_qinqing_recover = function(self, data) return self:isFriend(data:toPlayer()) end
sgs.ai_skill_exchange.sk_qinqing = function(self)
 local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValueInPlace(cards)
 return #cards > 0 and {cards[1]:getKnownEffectiveId()} or {}
end
sgs.ai_skill_exchange.sk_huisheng = function(self)
 local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValueInPlace(cards)
 local ids = {}
 for i = 1, math.min(3,#cards) do table.insert(ids,cards[i]:getKnownEffectiveId()) end
 return ids
end
sgs.ai_skill_choice.sk_huisheng = function(self, choices, data)
 if self:isFriend(data:toPlayer()) or self.player:getCardCount(true) < 3 then return "obtain" end
 return "discard"
end
sgs.ai_skill_askforag.sk_huisheng = function(self, ids)
 local best, value
 for _, id in ipairs(ids) do
  local c = face(self,id); local v = self:getUseValue(c)
  if not value or v > value then best = id; value = v end
 end
 return best
end

sgs.ai_skill_playerchosen.sk_qianchong = function(self, targets)
 local red = (self.request.prompt or ""):find("sk_qianchong-red", 1, true) ~= nil
 local best, score
 for _, p in sgs.qlist(targets) do
  if (red and self:isFriend(p)) or (not red and self:isEnemy(p)) then
   local n = red and (p:isWounded() and 10 or p:getMaxHp()) or (10 - p:getHp())
   if not score or n > score then best = p; score = n end
  end
 end
 return best
end
sgs.ai_skill_choice.sk_qianchong = function(self, choices, data)
 local p = data:toPlayer()
 if choices:find("recover") then
  return p:getLostHp() >= 2 and "recover" or "draw"
 end
 return (p:getHp() <= 2 or p:getCardCount(true) < p:getMaxHp()) and "losehp" or "discard"
end
sgs.ai_skill_exchange.sk_shangjian = function(self, pattern, max_num)
 local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValueInPlace(cards)
 local ids = {}
 for i = 1, math.min(max_num,#cards) do table.insert(ids,cards[i]:getKnownEffectiveId()) end
 return ids
end
sgs.ai_skill_askforyiji.sk_shangjian = function(self, ids)
 for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
  if self:isFriend(p) then return p, ids[1] end
 end
 local others = self.room:getOtherPlayers(self.player)
 if not others:isEmpty() then return others:first(), ids[1] end
end
sgs.ai_skill_playerchosen.sk_shangjian = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
 return targets:first()
end

sgs.ai_skill_playerchosen.sk_guolun = function(self, targets)
 local prompt = self.request.prompt or ""
 local benefit = prompt:find("draw", 1, true) or prompt:find("recover", 1, true)
 for _, p in sgs.qlist(targets) do
  if benefit and self:isFriend(p) or not benefit and self:isEnemy(p) then return p end
 end
end

sgs.ai_skill_invoke.sk_qinguo = true
sgs.ai_skill_playerchosen.sk_qinguo = function(self, targets)
 for _, p in sgs.qlist(targets) do if p == self.player then return p end end
end
sgs.ai_skill_choice.sk_qinguo = function(self, choices)
 local options = choices:split("+")
 if self.player:isWounded() then for _, name in ipairs(options) do if name == "peach" then return name end end end
 for _, name in ipairs(options) do if name == "slash" then return name end end
 return "cancel"
end
sgs.ai_skill_use["@@sk_qinguo"] = function(self)
 local name = (self.player:getTag("sk_qinguo_card")):toString()
 local card = self:evaluateSkillCard("sk_qinguo", name, {})
 local use = {isDummy=true, to=sgs.SPlayerList()}
 self:useBasicCard(card, use)
 if not use.card then return "." end
 local targets = {}
 for _, p in sgs.qlist(use.to) do table.insert(targets,p:objectName()) end
 return {kind="use_card",card_spec=card:toCardSpec(),targets=targets}
end

sgs.ai_skill_playerchosen.sk_zhukou = function(self, targets)
 local best
 for _, p in sgs.qlist(targets) do
  if self:isEnemy(p) and (not best or p:getHp() < best:getHp()) then best = p end
 end
 return best
end
sgs.ai_skill_choice.sk_zhukou = function(self, choices, data)
 return self:isEnemy(data:toPlayer()) and "repeat" or "done"
end
sgs.ai_skill_invoke.sk_duannian = function(self)
 if self.player:isWounded() then return true end
 local cards = sgs.QList2Table(self.player:getHandcards())
 local value = 0
 for _, card in ipairs(cards) do value = value + self:getKeepValue(card) end
 return #cards == 0 or value / #cards < 4
end
sgs.ai_skill_choice.sk_duannian = function(self)
 return self.player:isWounded() and "recover" or "use"
end

sgs.ai_skill_use["@@sk_duannian"] = function(self)
 local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByUseValueInPlace(cards)
 for _, material in ipairs(cards) do
  local card = self:evaluateSkillCard("sk_duannian", nil, {material:getKnownEffectiveId()})
  local use = {isDummy=true,to=sgs.SPlayerList()}
  self:useCardByClassName(card, use)
  if use.card then
   local targets = {}
   for _, p in sgs.qlist(use.to) do table.insert(targets,p:objectName()) end
   return {kind="use_card",card_spec=card:toCardSpec(),targets=targets}
  end
 end
 return "."
end

local sk_yanjiao_skill = {name = "sk_yanjiao"}
table.insert(sgs.ai_skills, sk_yanjiao_skill)
sk_yanjiao_skill.getTurnUseCard = function(self)
 if self.player:getStrategyMark("sk_yanjiao_1") > 0 then return end
 local best
 for _, c in sgs.qlist(self.player:getHandcards()) do
  if not best or c:getNumber() > best:getNumber() then best = c end
 end
 if best then return seed(self,"#sk_yanjiaoCard:" .. best:getKnownEffectiveId() .. ":") end
end
sgs.ai_skill_use_func["#sk_yanjiaoCard"] = function(card, use, self)
 local targets = self.player:getStrategyMark("&sk_xingshen") > 0 and self.enemies or self.friends_noself
 if #targets > 0 then use.card = card; if use.to then use.to:append(targets[1]) end end
end
sgs.ai_skill_invoke.sk_yanjiao = function(self, data) return self:isEnemy(data:toPlayer()) end

sgs.ai_skill_invoke.sk_jingce = true
sgs.ai_skill_choice.sk_jingce = function(self, choices)
 local options = choices:split("+")
 for _, choice in ipairs(options) do if choice == "draw" then return choice end end
 for _, choice in ipairs(options) do if choice == "maxhp" then return choice end end
 return options[1]
end

sgs.ai_skill_invoke.sk_juyi = function(self) return self.player:getMaxHp() > 2 end

sgs.ai_skill_playerchosen.sk_yuqi = function(self, targets)
 local best
 for _, p in sgs.qlist(targets) do
  if self:isEnemy(p) and (not best or p:getHp() < best:getHp()) then best = p end
 end
 if self.player:getHp() <= 1 and self.player:getPhase() ~= sgs.Player_NotActive then return nil end
 return best
end

sgs.ai_skill_invoke.sk_tianbian = true
sgs.ai_skill_askforag.sk_tianbian = function(self, ids)
 local best, value
 for _, id in ipairs(ids) do
  local c = sgs.Sanguosha:getCard(id)
  local v = self.player:getPhase() == sgs.Player_NotActive and self:getUseValue(c) or c:getNumber()
  if not value or v > value then best, value = id, v end
 end
 return best or -1
end
sgs.ai_skill_invoke.sk_jianzheng = function(self, data)
 local use = data:toCardUse()
 return use and self:isEnemy(use.from)
end
sgs.ai_skill_invoke.sk_jianzheng_reselect = true
sgs.ai_skill_playerchosen.sk_jianzheng = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
 return nil
end

sgs.ai_skill_invoke.sk_tunan = function(self, data)
 local source = data:toPlayer()
 local target = source and source:getNextAlive()
 return source and target and self:isFriend(source) and self:isEnemy(target)
end
sgs.ai_skill_choice.sk_tunan = function(self, choices, data)
 local source = data:toPlayer()
 local target = source and source:getNextAlive()
 if choices:find("snatch") and target and not target:isNude() then return "snatch" end
 return choices:split("+")[1]
end
sgs.ai_skill_invoke.sk_bijing = function(self, data)
 local use = data:toCardUse()
 return use and self:isEnemy(use.from)
end

sgs.ai_skill_playerchosen.sk_youyan = function(self, targets)
 local best
 for _, p in sgs.qlist(targets) do
  if self:isFriend(p) then best = p; break end
 end
 return best or targets:first()
end
sgs.ai_skill_invoke.sk_zhuihuan = function(self)
 local score = 0
 for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
  if p:getStrategyMark("sk_zhuihuan_pending_" .. self.player:objectName()) > 0 then
   score = score + (self:isEnemy(p) and 2 or -2)
  end
 end
 return score > 0
end

sgs.ai_skill_invoke.sk_ciwei = function(self, data)
 local use = data:toCardUse()
 if not use or not use.card then return false end
 local changed = (use.card:getTag("sk_ciwei_changed")):toBool()
 return changed and self:isEnemy(use.from) or not changed and self:isFriend(use.from)
end
sgs.ai_skill_invoke.sk_caiyuan = true
sgs.ai_skill_playerchosen.sk_caiyuan = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
 return targets:first()
end

sgs.ai_skill_invoke.sk_luanzhan = function(self, data)
 local use = data:toCardUse()
 if not use or not use.card then return false end
 local card = use.card
 if card:isKindOf("ExNihilo") or card:isKindOf("GodSalvation") or card:isKindOf("AmazingGrace") then return true end
 if card:isKindOf("Slash") or card:isKindOf("Duel") or card:isKindOf("AOE") or card:isKindOf("FireAttack") then
  return self:isEnemy(use.from) and self.player:getHp() > 2
 end
 return self.player:getHp() > 1
end

sgs.ai_skill_invoke.sk_jixu = true
sgs.ai_skill_playerchosen.sk_jixu_slash = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
 return nil
end
sgs.ai_skill_playerchosen.sk_jixu_transfer = sgs.ai_skill_playerchosen.sk_jixu_slash

sgs.ai_skill_playerchosen.sk_zhengu = function(self, targets)
 local x = self.player:getHandcardNum(); local delta = self.player:isWounded() and 2 or 1
 local best, score = nil, 0
 for _, p in sgs.qlist(targets) do
  local n = p:getHandcardNum()
  local value = self:isFriend(p) and x + delta - n or self:isEnemy(p) and n - math.max(0,x-delta) or 0
  if value > score then best, score = p, value end
 end
 return best
end
sgs.ai_skill_choice.sk_zhengu = function(self, choices, data)
 return self:isFriend(data:toPlayer()) and "increase" or "decrease"
end

sgs.ai_skill_invoke.sk_sanchen = true
sgs.ai_skill_invoke.sk_sanchen_draw = function(self, data) return self:isFriend(data:toPlayer()) end
sgs.ai_fill_skill.sk_pozhu = function(self)
 if self.player:usedTimes("#sk_pozhuCard") >= 3 then return end
 local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValueInPlace(cards)
 for _, c in ipairs(cards) do
  if c:isKindOf("TrickCard") and not self.player:isJilei(c) then return seed(self,"#sk_pozhuCard:" .. c:getKnownEffectiveId() .. ":") end
 end
end
sgs.ai_skill_use_func["#sk_pozhuCard"] = function(card, use, self)
 for _, p in ipairs(self.enemies) do
  if self.player:inMyAttackRange(p) and (p:getStrategyMark("sk_pozhu_damage_" .. self.player:objectName()) > 0 or self:getKnownCard(p, self.player, "TrickCard", false, "h") > 0) then
   use.card = card; if use.to then use.to:append(p) end; return
  end
 end
end
sgs.ai_use_value.sk_pozhuCard = 5
sgs.ai_use_priority.sk_pozhuCard = 3

sgs.ai_fill_skill.sk_junbing = function(self)
 if self.player:getStrategyHasUsed("#sk_junbingCard") then return end
 local cards = sgs.QList2Table(self.player:getHandcards()); self:sortByKeepValueInPlace(cards)
 for _, c in ipairs(cards) do
  if c:isKindOf("Slash") and not self.player:isJilei(c) then return seed(self,"#sk_junbingCard:" .. c:getKnownEffectiveId() .. ":") end
 end
end
sgs.ai_skill_playerchosen.sk_junbing = function(self, targets)
 local best = self.player
 for _, p in sgs.qlist(targets) do if self:isFriend(p) and p:getKnownKingdom() == "wei" then best = p; break end end
 return best
end
sgs.ai_skill_use_func["#sk_junbingCard"] = function(card, use, self)
 use.card = card
 if use.to then use.to:append(sgs.ai_skill_playerchosen.sk_junbing(self,self.room:getAlivePlayers())) end
end
sgs.ai_skill_cardask["@sk_junbing"] = function(self)
 for _, c in sgs.qlist(self.player:getHandcards()) do
  if c:isKindOf("Slash") and not self.player:isJilei(c) then return "$" .. c:getKnownEffectiveId() end
 end
 return "."
end
sgs.ai_skill_cardask["@sk_quji"] = function(self, data)
 if not self:isFriend(data:toDamage().to) then return "." end
 for _, c in sgs.qlist(self.player:getHandcards()) do
  if c:isKindOf("Jink") and not self.player:isJilei(c) then return "$" .. c:getKnownEffectiveId() end
 end
 return "."
end
sgs.ai_skill_choice.sk_quji = function(self, choices)
 if choices:find("draw") then return "draw" end
 return choices:split("+")[1]
end
sgs.ai_use_value.sk_junbingCard = 7
sgs.ai_use_priority.sk_junbingCard = 5

sgs.ai_skill_invoke.sk_caiyi = function(self)
 return self.player:getHandcardNum() < 4
end
sgs.ai_skill_playerchosen.sk_caiyi = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) and p:faceUp() then return p end end
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
 return targets:first()
end

sgs.ai_skill_playerchosen.sk_xunxian = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
end
sgs.ai_skill_cardask["@sk_xunxian-give"] = function(self, data)
 local use = data:toCardUse(); local cards = sgs.QList2Table(self.player:getCards("he"))
 self:sortByKeepValueInPlace(cards)
 for _, c in ipairs(cards) do
  if c:getNumber() ~= use.card:getNumber() then return "$" .. c:getKnownEffectiveId() end
 end
 return "."
end

sgs.ai_skill_playerchosen.sk_fenyin = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) and self:damageIsEffective(p, sgs.DamageStruct_Normal, self.player) then return p end end
end

sgs.ai_skill_playerchosen.sk_qingyuan = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
 return targets:first()
end
sgs.ai_skill_playerchosen.sk_zhongshen = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
end
sgs.ai_view_as.sk_zhongshen = function(card, player, place, class_name)
 if class_name == "Peach" and card:isRed() then return (own_ai(player)):evaluateSkillCard("sk_zhongshen", "peach", {card:getKnownEffectiveId()}) end
end
sgs.ai_fill_skill.sk_zhongshen = function(self)
 if not self.player:isWounded() then return end
 local cards = sgs.QList2Table(self.player:getCards("he")); self:sortByKeepValueInPlace(cards)
 for _, c in ipairs(cards) do if c:isRed() then return self:evaluateSkillCard("sk_zhongshen", "peach", {c:getKnownEffectiveId()}) end end
end

local sk_qianxi_ai = {name = "sk_qianxi"}
table.insert(sgs.ai_skills, sk_qianxi_ai)
sk_qianxi_ai.getTurnUseCard = function(self)
 if self.player:getStrategyMark("sk_qianxi_phase_used") == 0 then return seed(self, "#sk_qianxiCard:.:" ) end
end
sgs.ai_skill_use_func["#sk_qianxiCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.sk_qianxiCard = 9
sgs.ai_skill_cardask["@sk_qianxi"] = function(self)
 local cards = sgs.QList2Table(self.player:getHandcards())
 self:sortByUseValueInPlace(cards)
 for _, c in ipairs(cards) do if c:isKindOf("Slash") then return "$" .. c:getKnownEffectiveId() end end
 if #cards > 0 then return "$" .. cards[1]:getKnownEffectiveId() end
 return "."
end

sgs.ai_skill_cardask["@sk_biluan"] = function(self)
 local cards = sgs.QList2Table(self.player:getCards("he"))
 self:sortByKeepValueInPlace(cards)
 for _, c in ipairs(cards) do
  if not self.player:isJilei(c) then return "$" .. c:getKnownEffectiveId() end
 end
 return "."
end
sgs.ai_skill_invoke.sk_lixia = function(self, data) return self:isFriend(data:toPlayer()) end
sgs.ai_skill_choice.sk_lixia = function(self, choices)
 local names = choices:split("+")
 for _, name in ipairs(names) do if name == "sk_biluan" then return name end end
 return names[1]
end

sgs.ai_skill_cardask["@sk_zhenyi"] = function(self, data)
 local d = data:toDamage()
 if d.damage == 1 and self.player:getHp() > 2 then return "." end
 local cards = sgs.QList2Table(self.player:getHandcards())
 self:sortByKeepValueInPlace(cards)
 for _, c in ipairs(cards) do if not self.player:isJilei(c) then return "$" .. c:getKnownEffectiveId() end end
 return "."
end
sgs.ai_skill_invoke.sk_zhenyi_remove = function(self, data) return self:isEnemy(data:toPlayer()) end
sgs.ai_skill_cardask["@sk_dianhua"] = function(self, data, pattern, target)
 if not target or not self:isFriend(target) then return "." end
 local cards = sgs.QList2Table(self.player:getHandcards())
 self:sortByKeepValueInPlace(cards)
 for _, c in ipairs(cards) do if c:getSuit() == sgs.Card_Heart and not self.player:isJilei(c) then return "$" .. c:getKnownEffectiveId() end end
 return "."
end
sgs.ai_skill_choice.sk_dianhua_count = function(self, choices) local names = choices:split("+"); return names[#names] end
local function sk_ch4_skill_choice(self, choices)
 local names = choices:split("+")
 for _, wanted in ipairs({"sk_jizhi", "jizhi", "sk_yingzi", "yingzi", "rende", "zhiheng"}) do if table.contains(names, wanted) then return wanted end end
 return names[1]
end
sgs.ai_skill_choice.sk_falu_reserve = sk_ch4_skill_choice
sgs.ai_skill_choice.sk_falu_give = sk_ch4_skill_choice
sgs.ai_skill_choice.sk_dianhua = sk_ch4_skill_choice
sgs.ai_skill_playerchosen.sk_falu_damage = function(self, targets)
 local list = sgs.QList2Table(targets); self:sortInPlace(list, "hp")
 for _, p in ipairs(list) do if self:isEnemy(p) then return p end end
 return list[1]
end
sgs.ai_skill_playerchosen.sk_falu_give = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isFriend(p) then return p end end
 return targets:first()
end

-- 极略67 周鲂
sgs.ai_skill_invoke.sk_duanfa = true
local sk_duanfa_ai = {name = "sk_duanfa"}
table.insert(sgs.ai_skills, sk_duanfa_ai)
sk_duanfa_ai.getTurnUseCard = function(self)
 if self.player:getStrategyMark("sk_duanfa_phase_used") == 0 then return seed(self, "#sk_duanfaCard:.:") end
end
sgs.ai_skill_use_func["#sk_duanfaCard"] = function(card, use, self) use.card = card end
sgs.ai_use_priority.sk_duanfaCard = 9
sgs.ai_skill_playerchosen.sk_youdi = function(self, targets)
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) and not p:isNude() then return p end end
 for _, p in sgs.qlist(targets) do if self:isEnemy(p) then return p end end
end
