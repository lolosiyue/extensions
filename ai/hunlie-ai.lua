--知命
sgs.ai_skill_cardask["@sgkgodzhiming"] = function(self, data, pattern, target)
    local current = self.room:getCurrent()
	if self:isEnemy(current) and not self.player:isKongcheng() then
	    local cards = sgs.QList2Table(self.player:getHandcards())
		self:sortByKeepValue(cards)
		return "$" .. cards[1]:getId()
	else
		return "."
	end
end

sgs.ai_skill_choice["sgkgodzhiming"] = function(self, choices, data)
	local room = self.room
	local current = room:getCurrent()
	if current:getHandcardNum() >= current:getHp() then
	    return "sgkgodzhimingplay"
	end
	if (current:hasSkills("yongsi|haoshi|juejing|yingzi|nosyingzi|tuxi|nostuxi") and current:getHandcardNum() <= 2) or current:isKongcheng() 
	        or current:getHp() > current:getHandcardNum() then
		return "sgkgodzhimingdraw"
	end
	return "sgkgodzhimingplay"
end


--夙隐
sgs.ai_skill_playerchosen.sgkgodsuyin = function(self, targets)
    local target = {}
	for _, t in sgs.qlist(targets) do
	    if self:isEnemy(t) and t:faceUp() then
		    table.insert(target, t)
		end
		if self:isFriend(t) and (not t:faceUp()) then
		    table.insert(target, t)
		end
	end
	if #target > 0 then
	    self:sort(target, "defense")
		return target[1]
	end
end

sgs.ai_skill_invoke.sgkgodsuyin = function(self, data)
    local a = 0
	for _, t in ipairs(self.enemies) do
	    if t:faceUp() then a = a + 1 end
	end
	for _, p in ipairs(self.friends_noself) do
	    if not p:faceUp() then a = a + 1 end
	end
	if a > 0 then return true end
	return false
end


--虎踞
sgs.ai_skill_choice["sgkgodhuju"] = function(self, choices, data)
    local huju = choices:split("+")
	if self:getCardsNum("Peach") >= self.player:getLostHp() or self.player:getLostHp() == 1 then
	    return huju[1]
	end
	return huju[2]
end


--虎缚
sgkgodhufu_skill={}
sgkgodhufu_skill.name="sgkgodhufu"
table.insert(sgs.ai_skills, sgkgodhufu_skill)
sgkgodhufu_skill.getTurnUseCard=function(self, inclusive)
    if self.player:hasUsed("#sgkgodhufuCard") then return end
	if #self.enemies <= 0 then return end 
	return sgs.Card_Parse("#sgkgodhufuCard:.:")
end

sgs.ai_skill_use_func["#sgkgodhufuCard"] = function(card, use, self)
    local targets = {}
	for _, p in ipairs(self.enemies) do
	    if p:getEquips():length() >= 1 then
	        table.insert(targets, p)
		end
	end
	if #targets == 0 then return nil end
	local target = targets[math.random(1, #targets)]
	use.card = card
	if use.to then use.to:append(target) end
	return
end

sgs.ai_use_value["sgkgodhufuCard"] = 8
sgs.ai_use_priority["sgkgodhufuCard"] = 8
sgs.ai_card_intention["sgkgodhufuCard"]  = 80


--制衡（虎踞）
local hujuzhiheng_skill = {}
hujuzhiheng_skill.name = "hujuzhiheng"
table.insert(sgs.ai_skills, hujuzhiheng_skill)
hujuzhiheng_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#hujuzhihengCard") then
		return sgs.Card_Parse("#hujuzhihengCard:.:")
	end
end

sgs.ai_skill_use_func["#hujuzhihengCard"] = function(card, use, self)
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

		if self.player:getWeapon() and self.player:getHandcardNum()<3 then
			table.insert(unpreferedCards,self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards,self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards,self.player:getOffensiveHorse():getId())
		end
	end

	for i = #unpreferedCards,1,-1 do
		if sgs.Sanguosha:getCard(unpreferedCards[i]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then
			table.removeOne(unpreferedCards,unpreferedCards[i])
		end
	end

	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		if self.room:getMode()=="02_1v1" and sgs.GetConfig("1v1/Rule","Classical")~="Classical" then
			local use_cards_kof = {use_cards[1]}
			if #use_cards>1 then table.insert(use_cards_kof,use_cards[2]) end
			use.card = sgs.Card_Parse("#hujuzhihengCard:"..table.concat(use_cards_kof,"+")..":")
		else
			use.card = sgs.Card_Parse("#hujuzhihengCard:"..table.concat(use_cards,"+")..":")
		end
	end
end

sgs.ai_use_value["hujuzhihengCard"] = 9
sgs.ai_use_priority["hujuzhihengCard"] = 2.61
sgs.dynamic_value.benefit["hujuzhihengCard"] = true


function sgs.ai_cardneed.hujuzhiheng(to, card)
	return not card:isKindOf("Jink")
end


--魅心
local sgkgodmeixin_skill = {}
sgkgodmeixin_skill.name = "sgkgodmeixin"
table.insert(sgs.ai_skills, sgkgodmeixin_skill)
sgkgodmeixin_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return nil end
	local a = 0
	for _, p in ipairs(self.enemies) do
	    if p:isMale() and p:getMark("&sgkgodmeixin") == 0 then a = a+1 end
	end
	if a <= 0 then return nil end
	return sgs.Card_Parse("#sgkgodmeixinCard:.:")
end

sgs.ai_skill_use_func["#sgkgodmeixinCard"] = function(card, use, self)
	self:sort(self.enemies, "threat")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local need_num = 1
	for _, man in sgs.qlist(self.room:getAlivePlayers()) do
		if man:getMark("&sgkgodmeixin") > 0 then need_num = need_num + 1 end
	end
	if self:isWeak() and #cards - need_num <= 1 then return nil end
	local meixin_ids = {}
	local target
	for _, enemy in ipairs(self.enemies) do
	    if enemy:isMale() and enemy:getMark("&sgkgodmeixin") == 0 then
		    target = enemy
			break
		end
	end
	if not target then return nil end
	if target then
		for _, c in sgs.list(cards) do
			table.insert(meixin_ids, c:getEffectiveId())
			if #meixin_ids == need_num then break end
		end
		if #meixin_ids == need_num then
			use.card = sgs.Card_Parse("#sgkgodmeixinCard:" .. table.concat(meixin_ids, "+") .. ":")
			if use.to then use.to:append(target) end
		end
	end
end

sgs.ai_use_value["sgkgodmeixinCard"] = 10
sgs.ai_use_priority["sgkgodmeixinCard"] = 10
sgs.ai_card_intention["sgkgodmeixinCard"]  = 80


--电界
sgs.ai_skill_invoke.sgkgoddianjie = function(self, data)
    local a = math.abs(self.player:getHandcardNum()-self.player:getHp())
	if #self.enemies == 0 then
	    if self.player:hasSkill("sgkgodleihun") and not self.player:hasSkill("jueqing") then
	        if not self.player:isWounded() then
		        return false
	        else
	            if a <= 2 then return true end
		    end
		end
	else
	    if self.player:getHp() <= 1 then return true end
		if a <= 1 then return true end
	end
end

sgs.ai_skill_playerchosen.sgkgoddianjie = function(self, targets)
	local target = nil
	for _, t in sgs.qlist(targets) do
		if t:hasSkill("sgkgodleihun") and (not t:hasSkill("jueqing")) and t:objectName() == self.player:objectName() and self.player:getHp() <= 1 then
			target = t
			break
		end
	end
	if not target then
		local leihun = {}
		for _, _player in sgs.qlist(targets) do
			if self:isEnemy(_player) and self:damageIsEffective(_player, sgs.DamageStruct_Thunder, self.player) and self:isGoodTarget(_player,targets) then
				table.insert(leihun, _player)
			end
		end
		if #leihun == 0 then return nil end
		self:sort(leihun, "hp")
		target = leihun[1]
	end
	return target
end

sgs.ai_skill_use["@@sgkgoddianjie"] = function(self, prompt)
    if #self.enemies <= 0 then return "." end
    local tos = {}
	for _, enemy in ipairs(self.enemies) do
	    if not enemy:isChained() then table.insert(tos, enemy:objectName()) end
	end
	if not self.player:isChained() and not self.player:hasSkill("jueqing") and self.player:hasSkill("sgkgodleihun") then table.insert(self.player:objectName()) end
	if #tos > 1 then return "#sgkgoddianjieCard:.:->" .. table.concat(tos, "+") else return "." end
end

--神道
sgs.ai_skill_invoke.sgkgodshendao = function(self, data)
    local judge = data:toJudge()
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getCards("ej"):length() > 0 then  --场上有牌的角色
			targets:append(p)
		end
	end
	local judge_fromhandcardmyself = false
	local to = {}
	if self:needRetrial(judge) then
	    for _, t in sgs.qlist(targets) do
	        if self.player:objectName() == t:objectName() and self:getRetrialCardId(sgs.QList2Table(t:getCards("ej")), judge) ~= -1 then table.insert(to, t) end
		    if self:isEnemy(t) then
		        if self:getRetrialCardId(sgs.QList2Table(t:getCards("e")), judge) ~= -1 then table.insert(to, t) end
		    else
		        if self:getRetrialCardId(sgs.QList2Table(t:getCards("ej")), judge) ~= -1 then table.insert(to, t) end
			end
		end
		if self:getRetrialCardId(sgs.QList2Table(self.player:getHandcards()), judge) ~= -1 then judge_fromhandcardmyself = true end
	end
	if judge_fromhandcardmyself or #to > 0 then
	    if judge:isGood() and self:isEnemy(judge.who) then return true end
	    if judge:isBad() and self:isFriend(judge.who) then return true end
	end
	return false
end

sgs.ai_skill_choice["sgkgodshendao"] = function(self, choices, data)
	local judge = data:toJudge()
	local targets = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:getCards("ej"):length() > 0 then  --场上有牌的角色
			targets:append(p)
		end
	end
	local judge_fromhandcardmyself = false
	local to = {}
	if self:needRetrial(judge) then
	    for _, t in sgs.qlist(targets) do
	        if self.player:objectName() == t:objectName() and self:getRetrialCardId(sgs.QList2Table(t:getCards("ej")), judge) ~= -1 then table.insert(to, t) end
		    if self:isEnemy(t) then
		        if self:getRetrialCardId(sgs.QList2Table(t:getCards("e")), judge) ~= -1 then table.insert(to, t) end
		    else
		        if self:getRetrialCardId(sgs.QList2Table(t:getCards("ej")), judge) ~= -1 then table.insert(to, t) end
			end
		end
		if self:getRetrialCardId(sgs.QList2Table(self.player:getHandcards()), judge) ~= -1 then judge_fromhandcardmyself = true end
		if #to > 0 and (not judge_fromhandcardmyself) then return "shendao_wholearea" end
		if #to <= 0 and judge_fromhandcardmyself then return "shendao_selfhandcard" end
		if #to > 0 and judge_fromhandcardmyself then
		    local shendao = choices:split("+")
			return shendao[math.random(1, #shendao)]
		end
	end
end

sgs.ai_skill_cardask["@shendao-card"]=function(self, data)
	local judge = data:toJudge()
	if self.room:getMode():find("_mini_46") and not judge:isGood() then 
		return "$" .. self.player:handCards():first() end
	if self:needRetrial(judge) then
		local cards = sgs.QList2Table(self.player:getHandcards())
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then
			return "$" .. card_id
		end
	end
	return "."
end

sgs.ai_skill_cardchosen.sgkgodshendao = function(self, who, flags)
	local cards = {}
	local judge = self.player:getTag("shendao_judge"):toJudge()
	local to = judge.who
	local card = judge.card
	local reason = judge.reason
	if self:needRetrial(judge) then
		if self:isFriend(who) then
		    if who:getCards("j"):length() > 0 then
			    cards = sgs.QList2Table(who:getCards("j"))
			else
			    cards = sgs.QList2Table(who:getCards("ej"))
			end
		elseif self:isEnemy(who) then
		    if who:getCards("e"):length() > 0 then
			    cards = sgs.QList2Table(who:getCards("e"))
			end
			if who:hasSkills("guidao|guicai|sr_guicai|hongyan|wuyan|nosguicai|huanshi") then  --如果有能改判的技能或者是不怕闪电的敌人挂了闪电，那么条件允许的情况下，拿闪电改判
			    if who:getCards("e") > 0 then
				    for _, icard in sgs.qlist(who:getCards("e")) do
					    table.insert(cards, icard)
					end
				end
				if who:getCards("j") > 0 then
				    for _, c in sgs.qlist(who:getCards("j")) do
					    if c:isKindOf("Lightning") then table.insert(cards, c) end
					end
				end
			end
		end
		self:sortByKeepValue(cards)
		local card_id = self:getRetrialCardId(cards, judge)
		if card_id ~= -1 then return card_id end
	end
end

sgs.ai_skill_playerchosen.sgkgodshendao = function(self, targets)
    local judge = self.player:getTag("shendao_judge"):toJudge()
	local who = judge.who
	local card = judge.card
	local to = {}
	if self:needRetrial(judge) then
	    for _, t in sgs.qlist(targets) do
	        if self.player:objectName() == t:objectName() then table.insert(to, t) end
		    if self:isEnemy(t) then
		        if self:getRetrialCardId(sgs.QList2Table(t:getCards("e")), judge) ~= -1 then table.insert(to, t) end
		    else
		        if self:getRetrialCardId(sgs.QList2Table(t:getCards("ej")), judge) ~= -1 then table.insert(to, t) end
			end
		end
		if #to > 0 then
	        self:sort(to, "value")
		    return to[1]
	    end
	end
	return
end
sgs.wizard_skill = sgs.wizard_skill .. "|sgkgodshendao"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|sgkgodshendao"

--雷魂
sgs.ai_slash_prohibit.sgkgodleihun = function(self, from, to, card)
	if to:hasSkill("sgkgodleihun") and card:isKindOf("ThunderSlash") then 
	    if not from:hasSkill("jueqing") then 
		    return true 
		else
		    return false
		end
	end
end


--摧锋
local sgkgodcuifeng_skill = {}
sgkgodcuifeng_skill.name = "sgkgodcuifeng"
table.insert(sgs.ai_skills, sgkgodcuifeng_skill)
sgkgodcuifeng_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sgkgodcuifengCard") then return nil end
	if #self.enemies == 0 then return nil end
	return sgs.Card_Parse("#sgkgodcuifengCard:.:")
end

sgs.ai_skill_use_func["#sgkgodcuifengCard"] = function(card, use, self)
    local target
	self:sort(self.friends, "defense")
	for _, friend in ipairs(self.friends) do
	    if friend:getMark("&nizhan") > 0 then
		    target = friend
			break
		end
	end
	if not target then
		self:sort(self.enemies)
		for _, enemy in ipairs(self.enemies) do
			if enemy:getMark("&nizhan") > 0 then
				target = enemy
				break
			end
		end
	end
	if target then
	    use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_skill_playerchosen["sgkgodcuifeng"] = function(self, targets)
	local players = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then table.insert(players, p) end
	end
	if #players > 0 then
	    self:sort(players, "hp")
		return players[1]
	else
	    self:sort(self.enemies, "hp")
		return self.enemies[1]
	end
end

sgs.ai_use_value["sgkgodcuifengCard"] = 8
sgs.ai_use_priority["sgkgodcuifengCard"] = 6
sgs.ai_ajustdamage_from.sgkgodweizhen = function(self, from, to, card, nature)
	if to:getMark("&nizhan") >= 3 then
		return 1
	end
end

--君望
sgs.ai_skill_cardask["@junwang"] = function(self, data, pattern)
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	local liubei = self.room:findPlayerBySkillName("sgkgodjunwang")
	local junwangcard
	if self:isEnemy(liubei) or (not self:isFriend(liubei))then
		if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") == #cards then
			junwangcard = cards[math.random(1, #cards)]
		else
			local bc
			for _, card in ipairs(cards) do
				if (not card:isKindOf("Peach")) and (not card:isKindOf("Analeptic")) then
					bc = card
					break
				end
			end
			junwangcard = bc
		end
	else
		if self:isFriend(liubei) then
			if (liubei:containsTrick("SupplyShortage") or liubei:containsTrick("Indulgence")) and self:getCardsNum("Nullification") > 0 then
				for _, card in ipairs(cards) do
					if card:isKindOf("Nullification") then
						junwangcard = card
						break
					end
				end
			end
			if not junwangcard then
				if self:isWeak(liubei) and (self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
					for _, card in ipairs(cards) do
						if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
							junwangcard = card
							break
						end
					end
				end
			end
			if not junwangcard then
				if liubei:hasSkills("jizhi|nosjizhi") then
					for _, card in ipairs(cards) do
						if card:isNDTrick() then
							junwangcard = card
							break
						end
					end
				end
			end
			if not junwangcard then
				if liubei:hasSkills("qiangxi|sgkgodzhiji") then
					for _, card in ipairs(cards) do
						if card:isKindOf("Weapon") then
							junwangcard = card
							break
						end
					end
				end
			end
			if not junwangcard then
				junwangcard = cards[math.random(1, #cards)]
			end
		end
	end
	if not junwangcard then
		junwangcard = cards[math.random(1, #cards)]
	end
	return "$" .. junwangcard:getEffectiveId()
end


--激诏
local sgkgodjizhao_skill = {}
sgkgodjizhao_skill.name = "sgkgodjizhao"
table.insert(sgs.ai_skills, sgkgodjizhao_skill)
sgkgodjizhao_skill.getTurnUseCard = function(self, inclusive)
    if self.player:isKongcheng() then return false end
	if #self.enemies <= 0 then return nil end
	if self.player:getHandcardNum() - self:getCardsNum("Peach") - self:getCardsNum("Analeptic") <= 0 then return nil end
	if self.player:getHandcardNum() <= 2 and self.player:getHp() <= 2 then return nil end
	return sgs.Card_Parse("#sgkgodjizhaoCard:.:")
end

sgs.ai_skill_use_func["#sgkgodjizhaoCard"] = function(card, use, self)
    if #self.enemies == 0 then return nil end
    local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local targets = {}
	for _, p in ipairs(self.enemies) do
	    if p:getMark("&zhao") <= 0 and (not self:isWeak(self.player)) then
		    table.insert(targets, p)
		end
	end
	if #targets == 0 then return nil end
	self:sort(targets, "defense")
	local target = targets[1]
	if target then
	    local jizhao_card
		if self:isEnemy(target) then
		    for _, card in ipairs(cards) do
			    if (not card:isKindOf("Peach")) and (not card:isKindOf("Analeptic")) then
				    jizhao_card = card
					break
				end
			end
		end
		if jizhao_card then
	        use.card = sgs.Card_Parse("#sgkgodjizhaoCard:" .. jizhao_card:getEffectiveId() .. ":")
		    if use.to then use.to:append(target) end
		end
		return
	end
end

sgs.ai_use_value["sgkgodjizhaoCard"] = 9
sgs.ai_use_priority["sgkgodjizhaoCard"] = 3


--杀意
local sgkgodshayi_skill = {}
sgkgodshayi_skill.name = "sgkgodshayi"
table.insert(sgs.ai_skills, sgkgodshayi_skill)
sgkgodshayi_skill.getTurnUseCard = function(self)
    --if self.player:getMark("shayi") <= 0 then return nil end
	local cards = self.player:getCards("he")	
	cards=sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local shayi_slash
	for _, card in ipairs(cards) do
	    if card:hasTip("sgkgodshayi") then
		    shayi_slash = card
			break
		end
	end
	if not shayi_slash then return nil end
	local suit = shayi_slash:getSuitString()
	local number = shayi_slash:getNumberString()
	local card_id = shayi_slash:getEffectiveId()
	local card_str = ("slash:sgkgodshayi[%s:%s]=%d"):format(suit, number, card_id)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash
end

sgs.ai_view_as["sgkgodshayi"] = function(card, player, card_place)
    local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if card:hasTip("sgkgodshayi") then
		return ("slash:sgkgodshayi[%s:%s]=%d"):format(suit, number, card_id)
	end
end
sgs.double_slash_skill = sgs.double_slash_skill .. "|sgkgodshayi"

--震魂
local sgkgodzhenhun_skill = {}
sgkgodzhenhun_skill.name = "sgkgodzhenhun"
table.insert(sgs.ai_skills, sgkgodzhenhun_skill)
sgkgodzhenhun_skill.getTurnUseCard = function(self, inclusive)
    if #self.enemies == 0 then return nil end
	if self.player:hasUsed("#sgkgodzhenhunCard") then return nil end
	return sgs.Card_Parse("#sgkgodzhenhunCard:.:")
end

sgs.ai_skill_use_func["#sgkgodzhenhunCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_use_value["sgkgodzhenhunCard"] = 10
sgs.ai_use_priority["sgkgodzhenhunCard"] = sgs.ai_use_priority.ExNihilo + 2


--掠阵
sgs.ai_skill_invoke.sgkgodluezhen = function(self, data)
    local use = data:toCardUse()
	local ganning = self.room:findPlayerBySkillName("sgkgodluezhen")
	if use.card:isKindOf("Slash") and use.from:objectName() == ganning:objectName() and not use.to:contains(ganning) then
	    for _, t in sgs.qlist(use.to) do
		    if self:isEnemy(t) then
			    return true
			end
		end
	end
	return false
end

sgs.ai_cardneed.sgkgodluezhen = sgs.ai_cardneed.slash
--游龙
local sgkgodyoulong_skill = {}
sgkgodyoulong_skill.name = "sgkgodyoulong"
table.insert(sgs.ai_skills, sgkgodyoulong_skill)
sgkgodyoulong_skill.getTurnUseCard = function(self, inclusive)
    if self.player:getMark("youlong") == 0 then return nil end
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards,true)
	local youlong_black
	for _, card in ipairs(cards) do
	    if card:isBlack() and ((self:getUseValue(card) < sgs.ai_use_value.Snatch) or inclusive) then
		    local shouldUse = true
			if card:isKindOf("Slash") then
				local dummy_use = {isDummy = true}
				if self:getCardsNum("Slash") == 1 then
					self:useBasicCard(card, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
			end
			if self:getUseValue(card) > sgs.ai_use_value.Snatch and card:isKindOf("TrickCard") then
				local dummy_use = {isDummy = true}
				self:useTrickCard(card, dummy_use)
				if dummy_use.card then shouldUse = false end
			end
			if shouldUse then
				youlong_black = card
				break
			end
		end
	end
	if youlong_black then
		local suit = youlong_black:getSuitString()
		local number = youlong_black:getNumberString()
		local card_id = youlong_black:getEffectiveId()
		local card_str = ("snatch:sgkgodyoulong[%s:%s]=%d"):format(suit, number, card_id)
		local youlong_snatch = sgs.Card_Parse(card_str)
		assert(youlong_snatch)
		return youlong_snatch
	end
end

sgs.sgkgodyoulong_suit_value = {
	spade = 3.9,
	club = 3.9
}

function sgs.ai_cardneed.sgkgodyoulong(to, card)
	return card:isBlack() and not card:isEquipped()
end


--通天
local sgkgodtongtian_skill = {}
sgkgodtongtian_skill.name = "sgkgodtongtian"
table.insert(sgs.ai_skills, sgkgodtongtian_skill)
sgkgodtongtian_skill.getTurnUseCard = function(self, inclusive)
    if self.player:isKongcheng() then return nil end
	if self.player:getMark("@tian") <= 0 then return nil end
	local suits = {}
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Spade then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Heart then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Club then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Diamond then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	if #suits >= 3 then
	    return sgs.Card_Parse("#sgkgodtongtianCard:.:")
	end
end

sgs.ai_skill_use_func["#sgkgodtongtianCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_skill_use["@@sgkgodtongtian!"] = function(self, prompt)
	local valid = {}
	local ids = {}
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
    self:sortByKeepValue(cards) -- 按保留值排序
   	for _,c in sgs.list(cards)do
		if table.contains(ids, c:getSuit()) then continue end
		table.insert(valid, c:getEffectiveId())
		table.insert(ids, c:getSuit())
	end
	if #valid<1 then return end
   	return "#sgkgodtongtianCard:"..table.concat(valid, "+")..":"
end

sgs.ai_use_value["sgkgodtongtianCard"] = 10
sgs.ai_use_priority["sgkgodtongtianCard"] = 9


--制衡（通天）
local tongtian_zhiheng_skill = {}
tongtian_zhiheng_skill.name = "tongtian_zhiheng"
table.insert(sgs.ai_skills, tongtian_zhiheng_skill)
tongtian_zhiheng_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#tongtian_zhihengCard") then
		return sgs.Card_Parse("#tongtian_zhihengCard:.:")
	end
end

sgs.ai_skill_use_func["#tongtian_zhihengCard"] = function(card, use, self)
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

		if self.player:getWeapon() and self.player:getHandcardNum()<3 then
			table.insert(unpreferedCards,self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards,self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards,self.player:getOffensiveHorse():getId())
		end
	end

	for i = #unpreferedCards,1,-1 do
		if sgs.Sanguosha:getCard(unpreferedCards[i]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length()>1 then
			table.removeOne(unpreferedCards,unpreferedCards[i])
		end
	end

	local use_cards = {}
	for i = #unpreferedCards,1,-1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[i])) then table.insert(use_cards,unpreferedCards[i]) end
	end

	if #use_cards>0 then
		if self.room:getMode()=="02_1v1" and sgs.GetConfig("1v1/Rule","Classical")~="Classical" then
			local use_cards_kof = {use_cards[1]}
			if #use_cards>1 then table.insert(use_cards_kof,use_cards[2]) end
			use.card = sgs.Card_Parse("#tongtian_zhihengCard:"..table.concat(use_cards_kof,"+")..":")
		else
			use.card = sgs.Card_Parse("#tongtian_zhihengCard:"..table.concat(use_cards,"+")..":")
		end
	end
end

sgs.ai_use_value["tongtian_zhihengCard"] = 9
sgs.ai_use_priority["tongtian_zhihengCard"] = 2.61
sgs.dynamic_value.benefit["tongtian_zhihengCard"] = true


function sgs.ai_cardneed.tongtian_zhiheng(to, card)
	return not card:isKindOf("Jink")
end


--反馈
sgs.ai_skill_invoke.tongtian_fankui = function(self, data)
    local damage = data:toDamage()
	if self:isEnemy(damage.from) then
	    return true
	end
	return false
end


--观星
dofile "lua/ai/guanxing-ai.lua"


--极略
local sgkgodjilue_skill = {}
sgkgodjilue_skill.name = "sgkgodjilue"
table.insert(sgs.ai_skills, sgkgodjilue_skill)
sgkgodjilue_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasFlag("jiluefailed") then return nil end
	return sgs.Card_Parse("#sgkgodjilueCard:.:")
end

sgs.ai_skill_use_func["#sgkgodjilueCard"] = function(card, use, self)
    if self.player:hasFlag("jiluefailed") then return nil end
	use.card = card
end

sgs.ai_use_value["sgkgodjilueCard"] = 10
sgs.ai_use_priority["sgkgodjilueCard"] = 8
sgs.dynamic_value.benefit["sgkgodjilueCard"] = true


--第一部分：含有锦囊牌的pattern
--1-1：锦囊牌、杀
sgs.ai_skill_use["TrickCard+^Nullification,Slash,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--1-2：锦囊牌、杀、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Slash,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--1-3：锦囊牌、杀、酒
sgs.ai_skill_use["TrickCard+^Nullification,Slash,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-4：锦囊牌、杀、酒、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Slash,Analeptic,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-5：锦囊牌、桃
sgs.ai_skill_use["TrickCard+^Nullification,Peach,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			end
		end
	end
	return "."
end

--1-6：锦囊牌、桃、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Peach,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			end
		end
	end
	return "."
end

--1-7：锦囊牌、桃、酒
sgs.ai_skill_use["TrickCard+^Nullification,EquipCard,Slash,Peach,Analeptic|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-8：锦囊牌、桃、酒、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Peach,Analeptic,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-9：锦囊牌、桃、杀
sgs.ai_skill_use["TrickCard+^Nullification,Peach,Slash,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--1-10：锦囊牌、桃、杀、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Peach,Slash,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--1-11：锦囊牌、基本牌（除闪）
sgs.ai_skill_use["TrickCard+^Nullification,Peach,Slash,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-12：锦囊牌、基本牌（除闪）、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Peach,Slash,Analeptic,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-13：锦囊牌、酒
sgs.ai_skill_use["TrickCard+^Nullification,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-14：锦囊牌、酒、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Analeptic,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-15：锦囊牌、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		end
	end
	return "."
end

--1-16：锦囊牌
sgs.ai_skill_use["TrickCard+^Nullification,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		end
	end
	return "."
end

--第二部分：无锦囊牌的pattern
--2-1：杀
sgs.ai_skill_use["Slash,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--2-2：杀、装备牌
sgs.ai_skill_use["Slash,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--2-3：杀，酒
sgs.ai_skill_use["Slash,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-4：杀、酒、装备牌
sgs.ai_skill_use[" Slash,Analeptic,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-5：桃
sgs.ai_skill_use["Peach,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			end
		end
	end
	return "."
end

--2-6：桃、装备牌
sgs.ai_skill_use["Peach,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			end
		end
	end
	return "."
end

--2-7：桃、酒
sgs.ai_skill_use["Peach,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-8：桃、酒、装备牌
sgs.ai_skill_use["Peach,Analeptic,EquipCard|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-9：桃、杀
sgs.ai_skill_use["Peach,Slash,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--2-10：桃、杀、装备牌
sgs.ai_skill_use["Peach,Slash,EquipCard|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true, to = sgs.SPlayerList() }
			self:useTrickCard(card, dummy_use)
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-11：除了闪的基本牌
sgs.ai_skill_use["Peach,Slash,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-12：基本牌（除闪）、装备牌
sgs.ai_skill_use["Peach,Slash,Analeptic,EquipCard|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = { isDummy = true }
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
				self:useBasicCard(card, dummy_use)
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-13：酒
sgs.ai_skill_use[" Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-14：酒、装备牌
sgs.ai_skill_use["Analeptic,EquipCard|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = { isDummy = true }
				                self:useBasicCard(card, dummy_use)
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-15：装备牌
sgs.ai_skill_use["EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = { isDummy = true }
			self:useEquipCard(card, dummy_use)
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		end
	end
	return "."
end


--湮灭
local sgkgodyanmie_skill = {}
sgkgodyanmie_skill.name = "sgkgodyanmie"
table.insert(sgs.ai_skills, sgkgodyanmie_skill)
sgkgodyanmie_skill.getTurnUseCard = function(self, inclusive)
    if #self.enemies == 0 then return nil end
	if self.player:isKongcheng() then return nil end
	return sgs.Card_Parse("#sgkgodyanmieCard:.:")
end

sgs.ai_skill_use_func["#sgkgodyanmieCard"] = function(card, use, self)
    if #self.enemies == 0 then return nil end
	if self.player:isKongcheng() then return nil end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local target
	for _, enemy in ipairs(self.enemies) do
	    if (not enemy:hasSkills("manjuan|sgkgodfengying")) and (not enemy:isNude()) and enemy:getCards("he"):length() - 3*enemy:getHp() >= 0 then
		    target = enemy
			break
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if (not enemy:hasSkills("manjuan|sgkgodfengying")) and (not enemy:isNude()) and enemy:getCards("he"):length() > enemy:getHp() then
			    target = enemy
				break
			end
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if (not enemy:hasSkills("manjuan|sgkgodfengying")) and (not enemy:isNude()) and enemy:getCards("he"):length() >= 3 then
			    target = enemy
				break
			end
		end
	end
	if not target then return nil end
	if target then
	    local yanmie_use
		for _, _card in ipairs(cards) do
		    if _card:getSuit() == sgs.Card_Spade then
			    yanmie_use = _card
				break
			end
		end
		if yanmie_use then
		    use.card = sgs.Card_Parse("#sgkgodyanmieCard:" .. yanmie_use:getEffectiveId() .. ":")
			if use.to then use.to:append(target) end
		end
	end
end

sgs.sgkgodyanmie_suit_value = {
	spade = 4
}

sgs.ai_skill_choice["sgkgodyanmie"] = function(self, choices, data)
    return "dis-yanmie"
end


sgs.ai_use_value["sgkgodyanmieCard"] = 10
sgs.ai_use_priority["sgkgodyanmieCard"] = 7.5
sgs.ai_card_intention["sgkgodyanmieCard"] = 300


--顺世
sgs.ai_skill_playerschosen.sgkgodshunshi = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets)
	local tos = {}
	local use = self.player:getTag("shunshi_data"):toCardUse()
	if use.card:isKindOf("ExNihilo") or use.card:isKindOf("Peach") or use.card:isKindOf("Analeptic") or use.card:isKindOf("Dongzhuxianji") then
		for _, p in ipairs(targets) do
			if self:isFriend(p) then table.insert(tos, p) end
			if #tos == 3 then break end
		end
		return tos
	else
		for _, p in ipairs(targets) do
			if self:isEnemy(p) then table.insert(tos, p) end
			if #tos == 3 then break end
		end
		return tos
	end
	return {}
end

function sgs.ai_slash_prohibit.sgkgodshunshi(self,from,to,card)
	if self:isFriend(to,from) then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	if to:isNude() then return false end
	for _,friend in ipairs(self:getFriends(from,true))do
		if to:canSlash(friend,card) and self:slashIsEffective(card,friend,from) then return true end
	end
end


--归心
function sgkgodguixinValue(self, player)
	if player:isAllNude() then return 0 end
	local card_id = self:askForCardChosen(player, "hej", "dummy")
	if self:isEnemy(player) then
		for _, card in sgs.qlist(player:getJudgingArea()) do
			if card:getEffectiveId() == card_id then
				if card:isKindOf("YanxiaoCard") then return 0
				elseif card:isKindOf("Lightning") then
					if self:hasWizard(self.enemies, true) then return 0.8
					elseif self:hasWizard(self.friends, true) then return 0.4
					else return 0.5 * (#self.friends) / (#self.friends + #self.enemies) end
				else
					return -0.2
				end
			end
		end
		for i = 0, 3 do
			local card = player:getEquip(i)
			if card and card:getEffectiveId() == card_id then
				if card:isKindOf("Armor") and self:needToThrowArmor(player) then return 0 end
				local value = 0
				if self:getDangerousCard(player) == card_id then value = 1.5
				elseif self:getValuableCard(player) == card_id then value = 1.1
				elseif i == 1 then value = 1
				elseif i == 2 then value = 0.8
				elseif i == 0 then value = 0.7
				elseif i == 3 then value = 0.5
				end
				if player:hasSkills(sgs.lose_equip_skill) or not self:doDisCard(player, "e", true) then value = value - 0.2 end
				return value
			end
		end
		if self:needKongcheng(player) and player:getHandcardNum() == 1 then return 0 end
		if not self:hasLoseHandcardEffective() then return 0.1
		else
			local index = player:hasSkills("jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") and 0.7 or 0.6
			local value = 0.2 + index / (player:getHandcardNum() + 1)
			if not self:doDisCard(player, "h", true) then value = value - 0.1 end
			return value
		end
	elseif self:isFriend(player) then
		for _, card in sgs.qlist(player:getJudgingArea()) do
			if card:getEffectiveId() == card_id then
				if card:isKindOf("YanxiaoCard") then return 0
				elseif card:isKindOf("Lightning") then
					if self:hasWizard(self.enemies, true) then return 1
					elseif self:hasWizard(self.friends, true) then return 0.8
					else return 0.4 * (#self.enemies) / (#self.friends + #self.enemies) end
				else
					return 1.5
				end
			end
		end
		for i = 0, 3 do
			local card = player:getEquip(i)
			if card and card:getEffectiveId() == card_id then
				if card:isKindOf("Armor") and self:needToThrowArmor(player) then return 0.9 end
				local value = 0
				if i == 1 then value = 0.1
				elseif i == 2 then value = 0.2
				elseif i == 0 then value = 0.25
				elseif i == 3 then value = 0.25
				end
				if player:hasSkills(sgs.lose_equip_skill) then value = value + 0.1 end
				if hasTuntianEffect(player, true) then value = value + 0.1 end
				return value
			end
		end
		if self:needKongcheng(player, true) and player:getHandcardNum() == 1 then return 0.5
		elseif self:needKongcheng(player) and player:getHandcardNum() == 1 then return 0.3 end
		if not self:hasLoseHandcardEffective() then return 0.2
		else
			local index = player:hasSkills("jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") and 0.5 or 0.4
			local value = 0.2 - index / (player:getHandcardNum() + 1)
			if hasTuntianEffect(player, true) then value = value + 0.1 end
			return value
		end
	end
	return 0.3
end

sgs.ai_skill_invoke.sgkgodguixin = function(self, data)
	local damage = data:toDamage()
	local diaochan = self.room:findPlayerBySkillName("lihun")
	local lihun_eff = (diaochan and self:isEnemy(diaochan))
	local manjuan_eff = hasManjuanEffect(self.player)
	if lihun_eff and not manjuan_eff then return false end
	local players = self.room:getPlayers()
	local t = 0
	for _, _player in sgs.qlist(players) do
	    if _player:objectName() ~= self.player:objectName() and _player:getCards("hej"):length() > 0 then t = t + 1 end
		if _player:isDead() then t = t + 1 end
	end
	if not self.player:faceUp() then return true
	else
		if manjuan_eff then return false end
		if t >= 3 then return true end
		local value = 0
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			value = value + sgkgodguixinValue(self, player)
		end
		local left_num = damage.damage - self.player:getMark("guixin_times")
		return value >= 1.3 or left_num > 0
	end
end

sgs.ai_need_damaged.sgkgodguixin = function(self, attacker, player)
	if self.room:alivePlayerCount() <= 3 or player:hasSkill("manjuan") then return false end
	local diaochan = self.room:findPlayerBySkillName("lihun")
	local drawcards = 0
	for _, aplayer in sgs.qlist(self.room:getOtherPlayers(player)) do
		if aplayer:getCards("hej"):length() > 0 then drawcards = drawcards + 1 end
	end
	for _, aaplayer in sgs.qlist(self.room:getPlayers()) do
	    if aaplayer:isDead() then drawcards = drawcards + 1 end
	end
	return not self:isLihunTarget(player, drawcards)
end


--知天
sgs.ai_skill_playerchosen.sgkgodzhitian = function(self, targets)
	local zhitian = {}
	for _, _player in sgs.qlist(targets) do
	    if self:isFriend(_player) then table.insert(zhitian, _player) end
	end
	self:sort(zhitian, "value")
	if #zhitian > 0 then
	    self:sort(zhitian, "value")
	    return zhitian[1]
	end
end
sgs.ai_playerchosen_intention.sgkgodzhitian = -80

--掷戟
local sgkgodzhiji_skill = {}
sgkgodzhiji_skill.name = "sgkgodzhiji"
table.insert(sgs.ai_skills, sgkgodzhiji_skill)
sgkgodzhiji_skill.getTurnUseCard = function(self, inclusive)
    if #self.enemies == 0 then return nil end
	if self.player:hasUsed("#sgkgodzhijiCard") then return nil end
	if self.player:isNude() then return nil end
	return sgs.Card_Parse("#sgkgodzhijiCard:.:")
end

sgs.ai_skill_use_func["#sgkgodzhijiCard"] = function(card, use, self)
    if #self.enemies == 0 then return nil end
	if self.player:isNude() then return nil end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local zhiji_weapons = {}
	for _, c in ipairs(cards) do
	    if c:isKindOf("Weapon") then table.insert(zhiji_weapons, c:getEffectiveId()) end
	end
	if #zhiji_weapons > 0 then
		use.card = sgs.Card_Parse("#sgkgodzhijiCard:" .. table.concat(zhiji_weapons, "+") .. ":")
		if use.to then
			for _, enemy in ipairs(self.enemies) do
				if self:damageIsEffective(enemy) then
					if #zhiji_weapons > 1 and not enemy:hasArmorEffect("silver_lion") then
						use.to:append(enemy)
						if use.to:length() == #zhiji_weapons then break end
					elseif #zhiji_weapons == 1 then
						use.to:append(enemy)
						if use.to:length() == #zhiji_weapons then break end
					end
				end
			end
			assert(use.to:length() > 0)
		end
	end
end


sgs.ai_use_value["sgkgodzhijiCard"] = 5
sgs.ai_use_priority["sgkgodzhijiCard"] = sgs.ai_use_priority.Slash - 0.1
sgs.ai_card_intention["sgkgodzhijiCard"] = 200
sgs.ai_cardneed.sgkgodzhiji = sgs.ai_cardneed.weapon

sgs.ai_skill_invoke.sgkgodzhiji = true

sgs.sgkgodzhiji_keep_value = {
    weapon = 5.5
}


--涉猎
sgs.ai_skill_choice.sgkgodshelie = function(self, choices)
    local shelie = choices:split("+")
	return shelie[math.random(1, #shelie)]
end


--攻心
local sgkgodgongxin_skill= {}
sgkgodgongxin_skill.name = "sgkgodgongxin"
table.insert(sgs.ai_skills, sgkgodgongxin_skill)
sgkgodgongxin_skill.getTurnUseCard = function(self)
    if #self.enemies == 0 then return nil end
	if self.player:hasUsed("#sgkgodgongxinCard") then return nil end
	local sgkgodgongxin_card = sgs.Card_Parse("#sgkgodgongxinCard:.:")
	assert(sgkgodgongxin_card)
	return sgkgodgongxin_card
end

sgs.ai_skill_use_func["#sgkgodgongxinCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self:objectiveLevel(enemy) > 0
			and (self:hasSuit("heart", false, enemy) or self:getKnownNum(eneny) ~= enemy:getHandcardNum()) then
			use.card = card
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end

sgs.ai_use_value["sgkgodgongxinCard"] = 8.5
sgs.ai_use_priority["sgkgodgongxinCard"] = 9.5
sgs.ai_card_intention["sgkgodgongxinCard"] = 80


--啖睛
sgs.ai_skill_playerchosen["sgkgoddanjing_damage"] = function(self, targets)
    local damage = self.player:getTag("danjing_damage"):toDamage()
	local players = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) and self:damageIsEffective(t, damage.nature) then
		    table.insert(players, t)
		end
	end
	if #players > 0 then
		self:sort(players, "threat")
		return players[1]
	end
	return nil
end

sgs.ai_skill_playerchosen["sgkgoddanjing_lose"] = function(self, targets)
    local damage = self.player:getTag("danjing_damage"):toDamage()
	local players = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) and self:damageIsEffective(t, damage.nature) then
		    table.insert(players, t)
		end
	end
	if #players > 0 then
		self:sort(players, "threat")
		return players[1]
	end
	return nil
end

sgs.ai_skill_playerchosen["sgkgoddanjing_lose"] = function(self, targets)
	local players = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then
		    table.insert(players, t)
		end
	end
	if #players > 0 then
		self:sort(players, "threat")
		return players[1]
	end
	return nil
end

sgs.ai_skill_playerchosen["sgkgoddanjing_discard"] = function(self, targets)
	local players = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then
		    table.insert(players, t)
		end
	end
	if #players > 0 then
		self:sort(players, "defense")
		players = sgs.reverse(players)
		return players[1]
	end
	return nil
end

sgs.ai_skill_playerchosen["sgkgoddanjing_maxhp"] = function(self, targets)
	local players = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then
		    table.insert(players, t)
		end
	end
	if #players > 0 then
		self:sort(players, "threat")
		return players[1]
	end
	return nil
end


--忠魂
local sgkgodzhonghun_skill = {}
sgkgodzhonghun_skill.name = "sgkgodzhonghun"
table.insert(sgs.ai_skills, sgkgodzhonghun_skill)
sgkgodzhonghun_skill.getTurnUseCard = function(self)
    if #self.friends_noself == 0 then return nil end
	if self.player:getMark("sgkgodzhonghun") > 0 then return nil end
	return sgs.Card_Parse("#sgkgodzhonghunCard:.:")
end

sgs.ai_skill_use_func["#sgkgodzhonghunCard"] = function(card, use, self)
	local target
	for _, friend in ipairs(self.friends_noself) do
		if self.player:getRole() == "loyalist" and friend:isLord() and friend:getMark("&sgkgodzhonghun") == 0 then
			target = friend
			break
		end
	end
	if not target then
		self:sort(self.friends_noself, "chaofeng")
		for _, friend in pairs(self.friends_noself) do
			if friend:getMark("&sgkgodzhonghun") == 0 then
				target = friend
				break
			end
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_skill_use["@@sgkgodzhonghun"] = function(self, prompt)
	if #self.friends_noself == 0 then return "." end
	if self.player:getMark("sgkgodzhonghun") > 0 then return "." end
	local target
	for _, friend in ipairs(self.friends_noself) do
		if self.player:getRole() == "loyalist" and friend:isLord() and friend:getMark("&sgkgodzhonghun") == 0 then
			target = friend
			break
		end
	end
	if not target then
		self:sort(self.friends_noself, "chaofeng")
		for _, friend in pairs(self.friends_noself) do
			if friend:getMark("&sgkgodzhonghun") == 0 then
				target = friend
				break
			end
		end
	end
	if target then return "#sgkgodzhonghunCard:.:->" .. target:objectName() else return "." end
end


sgs.ai_use_value["sgkgodzhonghunCard"] = 10
sgs.ai_use_priority["sgkgodzhonghunCard"] = 10
sgs.ai_card_intention["sgkgodzhonghunCard"]  = -100


--龙魂
local sgkgodlonghun_skill = {}
sgkgodlonghun_skill.name = "sgkgodlonghun"
table.insert(sgs.ai_skills, sgkgodlonghun_skill)
sgkgodlonghun_skill.getTurnUseCard = function(self)
    local usable_cards = sgs.QList2Table(self.player:getCards("h"))
	local equips = sgs.QList2Table(self.player:getCards("e"))
	for _,e in ipairs(equips) do
		if e:isKindOf("DefensiveHorse") or e:isKindOf("OffensiveHorse") then
			table.insert(usable_cards, e)
		end
	end
	if self.player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(self.player:getPile("wooden_ox")) do
			table.insert(usable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	self:sortByUseValue(usable_cards, true)
	for _,c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Diamond and self:slashIsAvailable() and not c:isKindOf("Peach") then	--yun
			return sgs.Card_Parse(("fire_slash:sgkgodlonghunC[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
		end
	end
end

sgs.ai_view_as["sgkgodlonghun"] = function(card, player, card_place)
    local usable_cards = sgs.QList2Table(player:getCards("he"))
	if player:getPile("wooden_ox"):length() > 0 then
		for _, id in sgs.qlist(player:getPile("wooden_ox")) do
			table.insert(usable_cards, sgs.Sanguosha:getCard(id))
		end
	end
	local two_club_cards = {}
	local two_heart_cards = {}
	local two_diamond_cards = {}
	local two_spade_cards = {}
	local spade_num, club_num, heart_num, diamond_num = 0, 0, 0, 0
	for _,c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Club and #two_club_cards < 2 then
			table.insert(two_club_cards, c:getEffectiveId())
		elseif c:getSuit() == sgs.Card_Heart and #two_heart_cards < 2 then
			table.insert(two_heart_cards, c:getEffectiveId())
		elseif c:getSuit() == sgs.Card_Diamond and #two_diamond_cards < 2 then
			table.insert(two_diamond_cards, c:getEffectiveId())
		elseif c:getSuit() == sgs.Card_Spade and #two_spade_cards < 2 then
			table.insert(two_spade_cards, c:getEffectiveId())
		end
	end
	
	for _,c in ipairs(usable_cards) do
		if c:getSuit() == sgs.Card_Club then
			club_num = club_num + 1
		elseif c:getSuit() == sgs.Card_Spade then
			spade_num = spade_num + 1
		elseif c:getSuit() == sgs.Card_Heart then
			heart_num = heart_num + 1
		elseif c:getSuit() == sgs.Card_Diamond then
			diamond_num = diamond_num + 1
		end
	end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if #two_club_cards == 2 and club_num >= 3 then
		return ("jink:sgkgodlonghunBuff[%s:%s]=%d+%d"):format(sgs.Card_Club, 0, two_club_cards[1], two_club_cards[2])
	else
		if card:getSuit() == sgs.Card_Club then
			return ("jink:sgkgodlonghunC[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
	if #two_heart_cards == 2 and player:getMark("Global_PreventPeach") == 0 and heart_num >= 3 and player:getMaxHp() <= 5 then
		return ("peach:sgkgodlonghunBuff[%s:%s]=%d+%d"):format(sgs.Card_Heart, 0, two_heart_cards[1], two_heart_cards[2])
	else
		if card:getSuit() == sgs.Card_Heart and player:getMark("Global_PreventPeach") == 0 then
			return ("peach:sgkgodlonghunC[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
	if #two_diamond_cards == 2 and diamond_num >= 3 then
		return ("fire_slash:sgkgodlonghunBuff[%s:%s]=%d+%d"):format(sgs.Card_Diamond, 0, two_diamond_cards[1], two_diamond_cards[2])
	else
		if card:getSuit() == sgs.Card_Diamond and not (card:isKindOf("WoodenOx") and player:getPile("wooden_ox"):length() > 0) then
			return ("fire_slash:sgkgodlonghunC[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
	if #two_spade_cards == 2 and spade_num >= 3 then
		return ("nullification:sgkgodlonghunBuff[%s:%s]=%d+%d"):format(sgs.Card_Spade, 0, two_spade_cards[1], two_spade_cards[2])
	else
		if card:getSuit() == sgs.Card_Spade then
			return ("nullification:sgkgodlonghunC[%s:%s]=%d"):format(suit, number, card_id)
		end
	end
end

sgs.sgkgodlonghun_suit_value = sgs.longhun_suit_value

function sgs.ai_cardneed.sgkgodlonghun(to, card, self)
	if to:getCardCount() > 3 then return false end
	if to:isNude() then return true end
	return card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Spade
end


--七星
sgs.ai_skill_use["@@sgkgodqixing"] = function(self, prompt)
	local pile = self.player:getPile("xing")
	local piles = {}
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local max_num = math.max(pile:length(), #cards)
	if pile:isEmpty() or (#cards == 0) then
		return "."
	end
	for _, card_id in sgs.qlist(pile) do
		table.insert(piles, sgs.Sanguosha:getCard(card_id))
	end
	local exchange_to_pile = {}
	local exchange_to_handcard = {}
	self:sortByCardNeed(cards)
	self:sortByCardNeed(piles)
	for i = 1 , max_num, 1 do
		if self:cardNeed(piles[#piles]) > self:cardNeed(cards[1]) then
			table.insert(exchange_to_handcard, piles[#piles])
			table.insert(exchange_to_pile, cards[1])
			table.removeOne(piles, piles[#piles])
			table.removeOne(cards, cards[1])
		else
			break
		end
	end
	if #exchange_to_handcard == 0 then return "." end
	local exchange = {}
	for _, id in sgs.qlist(pile) do
		table.insert(exchange, id)
	end
	
	for _, c in ipairs(exchange_to_handcard) do
		table.removeOne(exchange, c:getId())
	end
	
	for _, c in ipairs(exchange_to_pile) do
		table.insert(exchange, c:getId())
	end
	
	return "#sgkgodqixingCard:" .. table.concat(exchange, "+") .. ":"
end


--狂风
sgs.ai_skill_use["@@sgkgodkuangfeng"] = function(self,prompt)
	if #self.enemies == 0 then return "." end
	local friendly_fire
	for _, friend in ipairs(self.friends_noself) do
		if friend:getMark("&gale") == 0 and self:damageIsEffective(friend, sgs.DamageStruct_Fire) and friend:faceUp() and not self:willSkipPlayPhase(friend)
			and (friend:hasSkill("huoji") or friend:hasWeapon("fan") or (friend:hasSkill("yeyan") and friend:getMark("@flame") > 0)) then
			friendly_fire = true
			break
		end
	end
	local is_chained = 0
	local target = {}
	for _, enemy in ipairs(self.enemies) do
		if enemy:getMark("&gale") == 0 and self:damageIsEffective(enemy, sgs.DamageStruct_Fire) then
			if enemy:isChained() then
				is_chained = is_chained + 1
				table.insert(target, enemy)
			elseif enemy:hasArmorEffect("vine") then
				table.insert(target, 1, enemy)
				break
			end
		end
		if self:isWeak(enemy) or self:damageIsEffective(enemy) then table.insert(target, enemy) end
	end
	local usecard = false
	if (friendly_fire and is_chained > 1) or #target > 0 then usecard = true end
	self:sort(self.friends, "hp")
	self:sort(self.enemies, "defense")
	if usecard then
		if not target[1] then table.insert(target, self.enemies[1]) end
		if target[1] then return "#sgkgodkuangfengCard:" .. self.player:getPile("xing"):first() .. ":->" .. target[1]:objectName() else return "." end
	else
		return "."
	end
end


sgs.ai_card_intention["#sgkgodkuangfengCard"] = 120


--大雾
sgs.ai_skill_use["@@sgkgoddawu"] = function(self, prompt)
	if #self.friends == 0 then return "." end
	self:sort(self.friends_noself, "hp")
	local targets = {}
	local lord = self.room:getLord()
	self:sort(self.friends_noself, "defense")
	if lord and lord:getMark("&fog") == 0 and self:isFriend(lord) and not sgs.isLordHealthy() and not self.player:isLord() and not lord:hasSkill("buqu")
		and not (lord:hasSkill("hunzi") and lord:getMark("hunzi") == 0 and lord:getHp() > 1) then
			table.insert(targets, lord:objectName())
	else
		for _, friend in ipairs(self.friends_noself) do
			if friend:getMark("&fog") == 0 and self:isWeak(friend) and not friend:hasSkill("buqu")
				and not (friend:hasSkill("hunzi") and friend:getMark("hunzi") == 0 and friend:getHp() > 1) then
					table.insert(targets, friend:objectName())
					break
			end
		end
	end
	if self.player:getPile("xing"):length() > #targets and self:isWeak() then table.insert(targets, self.player:objectName()) end
	if #targets > 0 then
		local s = sgs.QList2Table(self.player:getPile("xing"))
		local length = #targets
		for i = 1, #s - length do
			table.remove(s, #s)
		end
		return "#sgkgoddawuCard:" .. table.concat(s, "+") .. ":" .. "->" .. table.concat(targets, "+")
	end
	return "."
end


sgs.ai_card_intention["#sgkgoddawuCard"] = -100


--无谋
sgs.ai_skill_choice.sgkgodwumou = function(self, choices)
	if self.player:getMark("&fierce") > 6 then
	    if self:isWeak() then return "loseonemark" else return "getdamaged" end
	end
	if self.player:getHp() + self:getCardsNum("Peach") > 3 then return "getdamaged" else return "loseonemark" end
	if self.player:hasSkill("sgkgodyinshi") and not self.player:hasSkill("jueqing") then return "getdamaged" end
end


--神愤
local sgkgodshenfen_skill = {}
sgkgodshenfen_skill.name = "sgkgodshenfen"
table.insert(sgs.ai_skills, sgkgodshenfen_skill)
sgkgodshenfen_skill.getTurnUseCard = function(self)
	if #self.enemies == 0 then return nil end
	if self.player:hasUsed("#sgkgodshenfenCard") or self.player:getMark("&fierce") < 6 then return nil end
	return sgs.Card_Parse("#sgkgodshenfenCard:.:")
end

function SmartAI:getSaveNum(isFriend)
	local num = 0
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		if (isFriend and self:isFriend(player)) or (not isFriend and self:isEnemy(player)) then
			if not self.player:hasSkill("wansha") or player:objectName() == self.player:objectName() then
				if player:hasSkill("jijiu") then
					num = num + self:getSuitNum("heart", true, player)
					num = num + self:getSuitNum("diamond", true, player)
					num = num + player:getHandcardNum() * 0.4
				end
				if player:hasSkill("nosjiefan") and getCardsNum("Slash", player, self.player) > 0 then
					if self:isFriend(player) or self:getCardsNum("Jink") == 0 then num = num + getCardsNum("Slash", player, self.player) end
				end
				num = num + getCardsNum("Peach", player, self.player)
			end
			if player:hasSkill("buyi") and not player:isKongcheng() then num = num + 0.3 end
			if player:hasSkill("chunlao") and not player:getPile("wine"):isEmpty() then num = num + player:getPile("wine"):length() end
			if player:hasSkill("jiuzhu") and player:getHp() > 1 and not player:isNude() then
				num = num + 0.9 * math.max(0, math.min(player:getHp() - 1, player:getCardCount()))
			end
			if player:hasSkill("renxin") and player:objectName() ~= self.player:objectName() and not player:isKongcheng() then num = num + 1 end
		end
	end
	return num
end

function SmartAI:canSaveSelf(player)
	if hasBuquEffect(player) then return true end
	if getCardsNum("Analeptic", player, self.player) > 0 then return true end
	if player:hasSkill("jiushi") and player:faceUp() then return true end
	if player:hasSkill("jiuchi") then
		for _, c in sgs.qlist(player:getHandcards()) do
			if c:getSuit() == sgs.Card_Spade then return true end
		end
	end
	return false
end

local function getShenfenUseValueOfHECards(self, to)
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
	if hasTuntianEffect(to, true) then value = value * 0.95 end
	if (to:hasSkill("kongcheng") or (to:hasSkill("zhiji") and to:getHp() > 2 and to:getMark("zhiji") == 0)) and not to:isKongcheng() then value_h = value_h * 0.7 end
	if to:hasSkills("jijiu|qingnang|leiji|nosleiji|jieyin|beige|kanpo|liuli|qiaobian|zhiheng|guidao|longhun|xuanfeng|tianxiang|noslijian|lijian") then value_h = value_h * 0.95 end
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

local function getDangerousShenGuanYu(self)
	local most = -100
	local target
	for _, player in sgs.qlist(self.room:getAllPlayers()) do
		local nm_mark = player:getMark("&nightmare")
		if player:objectName() == self.player:objectName() then nm_mark = nm_mark + 1 end
		if nm_mark > 0 and nm_mark > most or (nm_mark == most and self:isEnemy(player)) then
			most = nm_mark
			target = player
		end
	end
	if target and self:isEnemy(target) then return true end
	return false
end

sgs.ai_skill_use_func["#sgkgodshenfenCard"] = function(card, use, self)
	if (self.role == "loyalist" or self.role == "renegade") and self.room:getLord() and self:isWeak(self.room:getLord()) and not self.player:isLord() then return end
	local benefit = 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:isFriend(player) then benefit = benefit - getShenfenUseValueOfHECards(self, player) end
		if self:isFriend(player) then benefit = benefit + getShenfenUseValueOfHECards(self, player) end
	end
	local friend_save_num = self:getSaveNum(true)
	local enemy_save_num = self:getSaveNum(false)
	local others = 0
	for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self:damageIsEffective(player, sgs.DamageStruct_Normal) then
			others = others + 1
			local value_d = 3.5 / math.max(player:getHp(), 1)
			if player:getHp() <= 1 then
				if player:hasSkill("wuhun") then
					local can_use = getDangerousShenGuanYu(self)
					if not can_use then return else value_d = value_d * 0.1 end
				end
				if self:canSaveSelf(player) then
					value_d = value_d * 0.9
				elseif self:isFriend(player) and friend_save_num > 0 then
					friend_save_num = friend_save_num - 1
					value_d = value_d * 0.9
				elseif self:isEnemy(player) and enemy_save_num > 0 then
					enemy_save_num = enemy_save_num - 1
					value_d = value_d * 0.9
				end
			end
			if player:hasSkill("fankui") then value_d = value_d * 0.8 end
			if player:hasSkill("guixin") then
				if not player:faceUp() then
					value_d = value_d * 0.4
				else
					value_d = value_d * 0.8 * (1.05 - self.room:alivePlayerCount() / 15)
				end
			end
			if getBestHp(player) == player:getHp() - 1 then value_d = value_d * 0.8 end
			if self:isFriend(player) then benefit = benefit - value_d end
			if self:isEnemy(player) then benefit = benefit + value_d end
		end
	end
	if not self.player:faceUp() or self.player:hasSkills("jushou|nosjushou|neojushou|kuiwei") then
		benefit = benefit + 1
	else
		local help_friend = false
		for _, friend in ipairs(self.friends_noself) do
			if self:hasSkills("fangzhu|jilve", friend) then
				help_friend = true
				benefit = benefit + 1
				break
			end
		end
		if not help_friend then benefit = benefit - 0.5 end
	end
	if self.player:getKingdom() == "qun" then
		for _, player in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if player:hasLordSkill("baonue") and self:isFriend(player) then
				benefit = benefit + 0.2 * self.room:alivePlayerCount()
				break
			end
		end
	end
	benefit = benefit + (others - 7) * 0.05
	if benefit > 0 then
		use.card = card
	end
end

sgs.ai_use_value["sgkgodshenfenCard"] = 8
sgs.ai_use_priority["sgkgodshenfenCard"] = 5.3

sgs.dynamic_value.damage_card["sgkgodshenfenCard"] = true
sgs.dynamic_value.control_card["sgkgodshenfenCard"] = true

sgs.ai_ajustdamage_from.sgkgodwushen = function(self, from, to, card, nature)
	if from and string.find(sgs.Sanguosha:translate(to:objectName()), "神") or string.find(sgs.Sanguosha:translate(to:objectName()), "SP神") or string.find(sgs.Sanguosha:translate(to:objectName()), "魔") then
		return 1
	end
end
sgs.exclusive_skill = sgs.exclusive_skill .. "|sgkgodsuohun"
function sgs.ai_slash_prohibit.sgkgodsuohun(self,from,to)
	if from:hasSkill("jueqing") then return false end
	if from:hasFlag("NosJiefanUsed") then return false end
	local damageNum = self:ajustDamage(from,to,1,dummyCard())

	local maxfriendmark = 0
	local maxenemymark = 0
	for _,friend in sgs.list(self:getFriends(from))do
		local friendmark = friend:getMark("&sk_soul")
		if friendmark>maxfriendmark then maxfriendmark = friendmark end
	end
	for _,enemy in sgs.list(self:getEnemies(from))do
		local enemymark = enemy:getMark("&sk_soul")
		if enemymark>maxenemymark and enemy~=to then maxenemymark = enemymark end
	end
	if self:isEnemy(to,from) and not (to:isLord() and from:getRole()=="rebel") then
		if (maxfriendmark+damageNum>=maxenemymark) and not (#(self:getEnemies(from))==1 and #(self:getFriends(from))+#(self:getEnemies(from))==self.room:alivePlayerCount()) then
			if not(from:getMark("&sk_soul")==maxfriendmark and from:getRole()=="loyalist")
			then return true end
		end
	end
end


--劫焰
sgs.ai_skill_invoke.sgkgodjieyan = function(self, data)
    local use = data:toCardUse()
	if use.to:length() ~= 1 then return false end
	local to = use.to:at(0)
	if self:isFriend(to) then return false end
	if self.player:isKongcheng() then return false end
	if use.card and use.card:isRed() and (use.card:isKindOf("Slash") or use.card:isNDTrick()) then
	    if self:damageIsEffective(to, sgs.DamageStruct_Fire) and self:objectiveLevel(to) >= 3 then return true else return false end
	end
	return false
end

sgs.ai_skill_cardask["@sgkgodjieyan"] = function(self, data, pattern)
    local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByKeepValue(cards)
	local c
	for _, card in ipairs(cards) do
	    if not card:isKindOf("Peach") then
		    c = card
			break
		end
	end
	if c then
	    return "$"..c:getEffectiveId()
	else
	    return "$"..cards[math.random(1,#cards)]:getEffectiveId()
	end
end


--焚营
sgs.ai_skill_invoke.sgkgodfenying = function(self, data)
    return (not self:needKongcheng(self.player))
end

sgs.ai_skill_discard.sgkgodfenying = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
	local x = self.player:getMark("&sgkgodfenying-Clear")
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local index = 0
	for i = #cards, 1, -1 do
	    local card = cards[i]
		if (not self.player:isJilei(card)) then
		    table.insert(to_discard, card:getEffectiveId())
	        table.remove(cards, i)
	        index = index + 1
	        if index == x then break end
	       end
	end
	if #to_discard < x then return {} else return to_discard end
end

sgs.ai_skill_playerchosen.sgkgodfenying = function(self, targets)
    local fenying = {}
	for _, t in sgs.qlist(targets) do
	    if self:isEnemy(t) and self:damageIsEffective(t, sgs.DamageStruct_Fire) then
		    table.insert(fenying, t)
		end
		if self:isEnemy(t) and t:hasArmorEffect("vine") or (t:getMark("&kuangfeng") > 0 and t:getMark("&dawu") == 0) or (t:isKongcheng() and t:hasSkill("chouhai")) then
		    table.insert(fenying, 1, t)
		end
	end
	return fenying[1]
end


--天机
sgs.ai_skill_invoke.sgkgodtianji = true


--天启
local sgkgodtianqi_skill = {}
sgkgodtianqi_skill.name = "sgkgodtianqi"
table.insert(sgs.ai_skills, sgkgodtianqi_skill)
sgkgodtianqi_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasFlag("tianqi_used") then return nil end
    if self.player:hasFlag("Global_Dying") then return nil end
	if not self.player:isAlive() then return nil end
	local tianqiTrickCard_str = {}
	local tianqiBasicCard_str = {}
	local top = self.player:getTag("top_card"):toString()
	if #self.enemies == 0 then
		if top == "TrickCard" then
			return sgs.Card_Parse("#sgkgodtianqi:.:" .. "dongzhuxianji")
		else
			if self:getCardsNum("Peach") > 0 then
				return sgs.Card_Parse("#sgkgodtianqi:.:" .. "dongzhuxianji")
			end
		end
	end
	if self.player:isWounded() and self:getCardsNum("Peach") == 0 then
		if top == "BasicCard" then
			local card = sgs.Card_Parse("#sgkgodtianqi:.:" .. "peach")
			local peach = sgs.Sanguosha:cloneCard("peach")
			local dummyuse = { isDummy = true }
			self:useBasicCard(peach, dummyuse)
			if dummyuse.card then return card end
		end
	end
	local tricks ={"zhujinqiyuan", "amazing_grace", "archery_attack", "savage_assault", "iron_chain", "dongzhuxianji"}
	local names = {}
	if top ~= nil then
		if top == "TrickCard" then
			for _, name in ipairs(tricks) do
				local drawpile = sgs.QList2Table(self.room:getDrawPile())
				if #drawpile > 0 then
					local c = sgs.Sanguosha:getCard(drawpile[1])
					local card = sgs.Sanguosha:cloneCard(name, c:getSuit(), c:getNumber())
					local dummyuse = { isDummy = true }
					self:useTrickCard(card, dummyuse)
					if dummyuse.card then
						table.insert(tianqiTrickCard_str, "#sgkgodtianqi:.:" .. card:objectName())
						if not table.contains(names, name) then table.insert(names, name) end
					end
				end
			end
		end
		if top == "BasicCard" then
			if self.player:isWounded() then
				local peach_str = "#sgkgodtianqi:.:" .. "peach"
				table.insert(tianqiBasicCard_str, peach_str)
				if not table.contains(names, "peach") then table.insert(names, "peach") end
			end
		end
	end
	local function filter_tianqi(objectName)
		local fakeCard
		local tianqi = "peach|dongzhuxianji|zhujinqiyuan|amazing_grace|archery_attack|savage_assault"
		local ban = table.concat(sgs.Sanguosha:getBanPackages(), "|")
		if not ban:match("maneuvering") then tianqi = tianqi .. "|fire_attack" end
		local tianqis = tianqi:split("|")
		for i = 1, #tianqis do
			local forbidden = tianqis[i]
			local forbid = sgs.Sanguosha:cloneCard(forbidden)
			if self.player:isLocked(forbid) then
				table.remove(tianqis, i)
				i = i - 1
			end
		end
		for i=1, 20 do
			local newtianqi = objectName or tianqis[math.random(1, #tianqis)]
			local tianqicard = sgs.Sanguosha:cloneCard(newtianqi)
			if tianqicard:isKindOf(top) or top == nil or (not tianqicard:isKindOf(top) and (not self:isWeak()) and math.random(1, 4) == 1) then
				local dummyuse = {isDummy = true}
				if newtianqi == "peach" then self:useBasicCard(tianqicard, dummyuse) else self:useTrickCard(tianqicard, dummyuse) end
				if dummyuse.card then
					fakeCard = sgs.Card_Parse("#sgkgodtianqi:.:" .. newtianqi)
					break
				end
			end
		end
		return fakeCard
	end
	if #tianqiTrickCard_str > 0 and not self:isWeak() then
		local tianqi_trickstr = tianqiTrickCard_str[math.random(1, #tianqiTrickCard_str)]
		if top and top == "TrickCard" then
			if #self.enemies == 0 then
				local fake_exnihilo = filter_tianqi("dongzhuxianji")
				if fake_exnihilo then return fake_exnihilo end
			end
			return sgs.Card_Parse(tianqi_trickstr)
		end
	else
		if #tianqiBasicCard_str > 0 then
			if top == "BasicCard" and self.player:isWounded() then
				local card = sgs.Card_Parse("#sgkgodtianqi:.:" .. "peach")
				local peach = sgs.Sanguosha:cloneCard("peach")
				local dummyuse = { isDummy = true }
				self:useBasicCard(peach, dummyuse)
				if dummyuse.card then return card end
			end
		end
	end
	if top == nil and self.player:isWounded() then
		local card = sgs.Card_Parse("#sgkgodtianqi:.:" .. "peach")
		local peach = sgs.Sanguosha:cloneCard("peach")
		local dummyuse = { isDummy = true }
		self:useBasicCard(peach, dummyuse)
		if dummyuse.card then return card end
	end
	local can_slash = (top and top == "BasicCard" and self:getCardsNum("Slash") == 0) or
		(not top and self.player:getHp() >= 2 and self:getCardsNum("Slash") == 0 and math.random(1, 300) <= 108)
	if can_slash and self:slashIsAvailable() then
		local card = sgs.Card_Parse("#sgkgodtianqi:.:" .. "slash")
		local slash = sgs.Sanguosha:cloneCard("slash")
		local dummyuse = { isDummy = true }
		self:useBasicCard(slash, dummyuse)
		if dummyuse.card then return card end
	end
end

sgs.ai_skill_use_func["#sgkgodtianqi"] = function(card, use, self)
    if self.player:hasFlag("tianqi_used") then return nil end
	if self.player:hasFlag("Global_Dying") then return nil end
	if self.player:getMark("Global_Dying") > 0 then return nil end
	local userstring=card:toString()
	userstring=(userstring:split(":.:"))[2]
	local tianqicard=sgs.Sanguosha:cloneCard(userstring)
	tianqicard:setSkillName("sgkgodtianqi")
	if tianqicard:getTypeId() == sgs.Card_TypeBasic then
		if not use.isDummy and use.card and tianqicard:isKindOf("Slash") and ((not use.to) or (use.to:isEmpty())) then return end
		self:useBasicCard(tianqicard, use)
	else
		assert(tianqicard)
		self:useTrickCard(tianqicard, use)
	end
	if not use.card then return end
	use.card=card
end

function sgs.ai_cardsview_valuable.sgkgodtianqi(self, class_name, player)
	if player:hasFlag("Global_Dying") then return end
	if player:hasFlag("tianqi_used") then return end
	if player:getMark("Global_Dying") > 0 then return nil end
	if not player:isAlive() then return end
	local top = player:getTag("top_card"):toString()
	if class_name == "Slash" and top == "BasicCard" and sgs.Sanguosha:getCurrentCardUseReason() == sgs.CardUseStruct_CARD_USE_REASON_RESPONSE_USE then
		return "#sgkgodtianqi:.:slash"
	elseif (class_name == "Peach" and player:getMark("Global_PreventPeach") == 0) or class_name == "Analeptic" and top == "BasicCard" then
		local dying = self.room:getCurrentDyingPlayer()
		if dying and dying:objectName() ~= player:objectName() and player:getMark("Global_PreventPeach") == 0 then
			return "#sgkgodtianqi:.:peach"
		else
			local user_string
			if class_name == "Analeptic" then user_string = "analeptic" else user_string = "peach" end
			return "#sgkgodtianqi:.:" .. user_string
		end
	end
	if math.random(1, 3) <= 1 and self:getCardsNum(class_name) == 0 then return "#sgkgodtianqi:.:" .. class_name end
end

sgs.ai_use_priority["sgkgodtianqi"] = sgs.ai_use_priority.ExNihilo - 0.1


--天机
sgs.ai_skill_choice["sgkgodtianji"] = function(self, choices, data)
    local tianji = choices:split("+")
	local ids = self.room:getNCards(1, true)
	local card = sgs.Sanguosha:getCard(ids:first())
	local canget = self.player:getTag("tianji_canget"):toBool()
	if not self:needKongcheng(self.player) then return "tianji_obtain" end
	if card:isKindOf("Peach") or card:isKindOf("ExNihilo") or card:isKindOf("Jink") or card:isKindOf("Slash") or card:isKindOf("Nullification") then
	    if canget then return "tianji_obtain" else return "tianji_exchange" end
	end
	if card:isKindOf("Analeptic") then
	    if self:isWeak() then
		    if canget then return "tianji_obtain" else return "tianji_exchange" end
		else
		    if canget then return tianji[math.random(1, 2)] else return "tianji_obtain" end
		end
	end
	if canget then return tianji[math.random(1, 2)] end
	return tianji[math.random(1, #tianji)]
end

sgs.ai_skill_cardask["@tianji_exchange"] = function(self, data, pattern)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByKeepValue(cards)
	if self.room:getCurrent():getSeat() == self.player:getSeat() then
		if self:getCardsNum("Peach") == 0 and self.player:isWounded() then
			local card
			for _, c in ipairs(cards) do
				if c:isKindOf("BasicCard") then
					card = c
					break
				end
			end
			return "$" .. card:getEffectiveId()
		end
		if #self.enemies == 0 then
			local card
			for _, c in ipairs(cards) do
				if c:isKindOf("TrickCard") and not c:isKindOf("ExNihilo") then
					card = c
					break
				end
			end
			return "$" .. card:getEffectiveId()
		end
	end
	return "$"..cards[1]:getEffectiveId()
end


--琴音
sgs.ai_skill_invoke.sgkgodqinyin = function(self, data)
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
			if friend:getHp() <= 1 and not friend:hasSkill("buqu") or friend:getPile("buqu"):length() > 4 then
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
	if self:isWeak() and self.player:getCards("he"):length() >= 2 then
	    sgs.ai_skill_choice.sgkgodqinyin = "qinyin_allrecover"
		return true
	end
	if down > 0 then
		sgs.ai_skill_choice.sgkgodqinyin = "qinyin_alllose"
		return true
	elseif up > 0 then
		sgs.ai_skill_choice.sgkgodqinyin = "qinyin_allrecover"
		return true
	else
	    if not self:isWeak() then
	        sgs.ai_skill_choice.sgkgodqinyin = "qinyin_alllose" --报复社会
		    return true
		end
	end
	return false
end


--业炎
local sgkgodyeyan_skill = {}
sgkgodyeyan_skill.name = "sgkgodyeyan"
table.insert(sgs.ai_skills, sgkgodyeyan_skill)
sgkgodyeyan_skill.getTurnUseCard = function(self, inclusive)
    if self.player:isKongcheng() then return nil end
	if self.player:getMark("@sk_fire") <= 0 then return nil end
	local can_do = false
	for _, card in sgs.qlist(self.player:getCards("h")) do
	    if card:isRed() then
			can_do = true
			break
		end
	end
	if can_do then
	    return sgs.Card_Parse("#sgkgodyeyanCard:.:")
	end
end

sgs.ai_skill_use_func["#sgkgodyeyanCard"] = function(card, use, self)
	local red_cards, black_cards = {}, {}
	local cards = self.player:getCards("h")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards, false, true)
	for _, card in ipairs(cards) do
		if card:isRed() then
			table.insert(red_cards, card:getId())
		elseif card:isBlack() then
			table.insert(black_cards, card:getId())
		end
	end
	local can_yeyan = {}
	local to_use = false
	for _, enemy in ipairs(self.enemies) do
	    if not enemy:hasArmorEffect("silver_lion") and self:objectiveLevel(enemy) > 3 and self:damageIsEffective(enemy, sgs.DamageStruct_Fire)
        and not (enemy:hasSkill("tianxiang") and enemy:getHandcardNum() > 0) then
		    if enemy:isChained() then
                if enemy:hasArmorEffect("vine") or enemy:getMark("&kuangfeng") > 0 then
			        table.insert(can_yeyan, enemy)
				end
			else
				if enemy then table.insert(can_yeyan, enemy) end
			end
		end
		if #black_cards <= 1 then
		    if self:damageIsEffective(enemy, sgs.DamageStruct_Fire) and not enemy:hasSkill("tianxiang") and self:objectiveLevel(enemy) > 3 then
			    if enemy:getHp() <= math.min(3, #red_cards) then table.insert(can_yeyan, enemy) end
				if self:isWeak(enemy) then table.insert(can_yeyan, enemy) end
			end
		end
	end
	if #can_yeyan > 0 then to_use = true end
	self:sort(can_yeyan, "hp")
    local need_ids, to_yeyan = {}, {}
	if #black_cards > 0 then
		for i = 1, #black_cards, 1 do
			table.insert(need_ids, black_cards[i])
			if i == math.min(2, #black_cards, #can_yeyan - 1) then break end
		end
	end
	if #can_yeyan > 0 then
		for i = 1, #need_ids + 1, 1 do
			table.insert(to_yeyan, can_yeyan[i])
		end
	end
	for _, id in ipairs(red_cards) do
		table.insert(need_ids, id)
		if #need_ids == 4 then break end
	end
	if to_use then
	    use.card = sgs.Card_Parse("#sgkgodyeyanCard:" .. table.concat(need_ids, "+") .. ":")
		if use.to then
		    for _, enemy in ipairs(to_yeyan) do
			    use.to:append(enemy)
			end
			assert(use.to:length() > 0)
		end
	end
end


sgs.ai_use_value["sgkgodyeyanCard"] = 8
sgs.ai_use_priority["sgkgodyeyanCard"] = sgs.ai_use_priority.ExNihilo - 0.1
sgs.ai_card_intention["sgkgodyeyanCard"] = 300


--贤助
sgs.ai_skill_invoke.sgkgodxianzhu = function(self, data)
	local player = data:toPlayer()
	return self:isFriend(player)
end

sgs.ai_choicemade_filter.skillInvoke.sgkgodxianzhu = function(self,player,promptlist)
	if promptlist[#promptlist]=="yes" then
		local target = self.room:findPlayerByObjectName(promptlist[#promptlist-1])
		if target then sgs.updateIntention(player,target,-50) end
	end
end

sgs.lose_equip_skill = sgs.lose_equip_skill .. "|sgkgodxianzhu"
sgs.ai_use_revises.sgkgodxianzhu = function(self,card,use)
	if card:isKindOf("EquipCard") and self:evaluateArmor(card)>-5
	then use.card = card return true end
end
sgs.ai_cardneed.sgkgodxianzhu = sgs.ai_cardneed.equip

--良缘
local sgkgodliangyuan_skill = {}
sgkgodliangyuan_skill.name = "sgkgodliangyuan"
table.insert(sgs.ai_skills, sgkgodliangyuan_skill)
sgkgodliangyuan_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sgkgodliangyuanCard") then return nil end
	if self.player:getMark("@liangyuan") == 0 then return nil end
	if #self.friends_noself == 0 then return nil end
	local a = 0
	for _, p in ipairs(self.friends_noself) do
	    if p:isMale() then a = a+1 end
	end
	if a <= 0 then return nil end
	return sgs.Card_Parse("#sgkgodliangyuanCard:.:")
end

sgs.ai_skill_use_func["#sgkgodliangyuanCard"] = function(card, use, self)
    local liangyuan_male
	--优先确保男性主公
	local lord = self.room:getLord()
	if self.player:isFemale() and lord:isMale() and self.player:getRole() == "loyalist" then liangyuan_male = lord end
	if not liangyuan_male then
		self:sort(self.friends_noself, "chaofeng")
		for _, target in ipairs(self.friends_noself) do
			if not target:hasSkill("dawu") and target:hasSkills("yongsi|zhiheng|sgkgodjilue|sk_diezhang|sk_yaoming" .. sgs.priority_skill .. "|shensu")
				and (not self:willSkipPlayPhase(target) or target:hasSkill("shensu")) and target:isMale() then
				liangyuan_male = target
				break
			end
		end
	end
	if not liangyuan_male then
		self:sort(self.friends_noself, "chaofeng")
		for _, target in ipairs(self.friends_noself) do
			liangyuan_male = target
			break
		end
	end
	if liangyuan_male then
	    use.card = card
		if use.to then use.to:append(liangyuan_male) end
	end
end

sgs.ai_use_value["sgkgodliangyuan"] = 10
sgs.ai_use_priority["sgkgodliangyuan"] = 10
sgs.ai_card_intention["sgkgodliangyuan"]  = -100


--望月
sgs.ai_skill_playerchosen.sgkgodwangyue = function(self, targets)
	local move = self.player:getTag("wangyue_draw_AI"):toMoveOneTime()
	if move ~= nil then
		local x = move.card_ids:length()
		local players = sgs.QList2Table(targets)
		self:sort(players, "defense")
		if x >= 2 then
			local target
			if self:isWeak() then target = self.player end
			if not target then
				for _, pe in ipairs(players) do
					if self:isWeak(target) and self:isFriend(target) then
						target = pe
						break
					end
				end
			end
			return target
		end
	end
	local lose = self.player:getTag("wangyue_rec_AI"):toHpLost()
	if lose ~= nil then
		local x = lose.lose
		local players = sgs.QList2Table(targets)
		self:sort(players, "hp")
		if x > 0 then
			local target
			if self:isWeak() and self.player:isWounded() then target = self.player end
			for _, pe in ipairs(players) do
				if pe:hasSkill("hunzi") and pe:getHp() <= 1 and pe:getMark("@waked") == 0 and (not self:isWeak()) then
					target = pe
					break
				end
			end
			if not target then
				for _, pe in ipairs(players) do
					if self:isWeak(target) and self:isFriend(target) then
						target = pe
						break
					end
				end
			end
			return target
		end
	end
	local mhp = self.player:getTag("wangyue_maxhp_AI"):toMaxHp()
	if mhp ~= nil and mhp < 0 then
		local x = 0 - mhp.change
		local players = sgs.QList2Table(targets)
		self:sort(players)
		local target
		--优先选择技能与体力上限有关的友方角色
		for _, pe in ipairs(targets) do
			if self:isFriend(pe) and pe:hasSkills("f_pinghe|sgkgodyinyang|quedi|zaiqi|fangzhu|jilve|yinghun|shangshi|weizhong|yizheng|poxi|hunzi|jintairan|yingzi|miji|sgkgodxingyun") then
				target = pe
				break
			end
		end
		--其次选择友方不多于3体力上限的脆皮角色
		if not target then
			for _, pe in ipairs(targets) do
				if self:isFriend(pe) and pe:getMaxHp() <= 3 then
					target = pe
					break
				end
			end
		end
		--再其次选择友方状态良好但需要扩容的角色
		if not target then
			for _, pe in ipairs(targets) do
				if self:isFriend(pe) and pe:getLostHp() <= 2 then
					target = pe
					break
				end
			end
		end
		--最后，无脑选大乔自己，给自己蓄爆
		if not target then
			target = self.player
		end
	end
	return self.player
end
sgs.ai_playerchosen_intention.sgkgodwangyue = -80

--落雁
function isDangerousCaopi(enemy)
	return (enemy:hasSkills("fangzhu|jilve|sy_old_renji|new_jilve")) and enemy:getMaxHp() <= 4
end

function canUseMoreCards(target)
	return target:hasSkills("fenyin|sgkgodjilue|tyyizhao|jieyingg|dl_quandao|jizhi|nosjizhi|sr_qicai|tenyearzhiheng|zhiheng|f_lingce|pianchong|f_huishi|sgkgodguixin")
end

sgs.ai_skill_invoke.sgkgodluoyan = function(self, data)
	if #self.enemies == 0 then return false end
	if #self.enemies == 1 and self.room:getAlivePlayers():length() > 2 and isDangerousCaopi(self.enemies[1]) then return false end
	return true
end

sgs.ai_skill_playerchosen.sgkgodluoyan = function(self, targets)
	targets = sgs.QList2Table(targets)
	local target
	--优先选1体力上限神将
	for _, pe in ipairs(targets) do
		if self:isEnemy(pe) and pe:getMaxHp() <= 2 then
			target = pe
			break
		end
	end
	--次选2体力上限但有减1体力上限觉醒技的神将
	if not target then
		for _, pe in ipairs(targets) do
			if self:isEnemy(pe) and pe:getMaxHp() <= 2 and pe:hasSkills("zaoxian|zili|hunzi|zhiji|yizheng") then
				target = pe
				break
			end
		end
	end
	--再考虑有大过牌技能的敌人
	if not target then 
		for _, pe in ipairs(targets) do
			if self:isEnemy(pe) and (not pe:containsTrick("indulgence")) and pe:getHandcardNum() >= 2 and (not isDangerousCaopi(pe)) then
				if canUseMoreCards(pe) then 
					target = pe
					break
				end
			end
		end
	end
	--最后考虑一般情况下的敌人
	if not target then
		self:sort(targets, "defense")
		for _, pe in ipairs(targets) do
			if self:isEnemy(pe) and (not pe:containsTrick("indulgence")) and pe:getHandcardNum() >= 2 then
				target = pe
				break
			end
		end
	end
	return target
end
sgs.ai_playerchosen_intention.sgkgodluoyan = 80


local sgkgodliegong_skill = {}
sgkgodliegong_skill.name = "sgkgodliegong"
table.insert(sgs.ai_skills, sgkgodliegong_skill)
sgkgodliegong_skill.getTurnUseCard = function(self, inclusive)
	local x = 1
	if self.player:isWounded() then x = 2 end
	if self.player:getMark("lg_fire_time") >= x then return end
	if #self.enemies == 0 then return end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	self:sortByUseValue(cards, true)
	local need_ids = {}
	for _, c in ipairs(cards) do
		if c:getSuit() == sgs.Card_Spade and not c:isKindOf("Analeptic") then
			table.insert(need_ids, c:getEffectiveId())
			break
		end
	end
	for _, c in ipairs(cards) do
		if c:getSuit() == sgs.Card_Heart and not c:isKindOf("ExNihilo") then
			table.insert(need_ids, c:getEffectiveId())
			break
		end
	end
	for _, c in ipairs(cards) do
		if c:getSuit() == sgs.Card_Club then
			table.insert(need_ids, c:getEffectiveId())
			break
		end
	end
	for _, c in ipairs(cards) do
		if c:getSuit() == sgs.Card_Diamond and not c:isKindOf("Analeptic") then
			table.insert(need_ids, c:getEffectiveId())
			break
		end
	end
	if #need_ids > 0 then
		if #need_ids == 1 then
			local c = sgs.Sanguosha:getCard(need_ids[1])
			return sgs.Card_Parse(("fire_slash:sgkgodliegong[%s:%s]=%d"):format(c:getSuitString(), c:getNumberString(), c:getEffectiveId()))
		end
		if #need_ids == 2 then return sgs.Card_Parse(("fire_slash:sgkgodliegong[%s:%s]=%d+%d"):format("to_be_decided", 0, need_ids[1], need_ids[2])) end
		if #need_ids == 3 then return sgs.Card_Parse(("fire_slash:sgkgodliegong[%s:%s]=%d+%d+%d"):format("to_be_decided", 0, need_ids[1], need_ids[2], need_ids[3])) end
		if #need_ids == 4 then return sgs.Card_Parse(("fire_slash:sgkgodliegong[%s:%s]=%d+%d+%d+%d"):format("to_be_decided", 0, need_ids[1], need_ids[2], need_ids[3], need_ids[4])) end
	end
end

sgs.ai_view_as["sgkgodliegong"] = function(card, player, card_place, class_name)
	local cards = sgs.QList2Table(player:getCards("h"))
	local x = 1
	if player:isWounded() then x = 2 end
	if player:getMark("lg_fire_time") >= x then return end
	local need_ids = {}
	for _, c in ipairs(cards) do
		if c:getSuit() == sgs.Card_Spade and not c:isKindOf("Analeptic") then
			table.insert(need_ids, c:getEffectiveId())
			break
		end
	end
	for _, c in ipairs(cards) do
		if c:getSuit() == sgs.Card_Heart and not c:isKindOf("ExNihilo") then
			table.insert(need_ids, c:getEffectiveId())
			break
		end
	end
	for _, c in ipairs(cards) do
		if c:getSuit() == sgs.Card_Club then
			table.insert(need_ids, c:getEffectiveId())
			break
		end
	end
	for _, c in ipairs(cards) do
		if c:getSuit() == sgs.Card_Diamond and not c:isKindOf("Analeptic") then
			table.insert(need_ids, c:getEffectiveId())
			break
		end
	end
	if #need_ids >= 2 then
		if #need_ids == 2 then
			return ("fire_slash:sgkgodliegong[%s:%s]=%d+%d"):format("to_be_decided", 0, need_ids[1], need_ids[2])
		elseif #need_ids == 3 then
			return ("fire_slash:sgkgodliegong[%s:%s]=%d+%d+%d"):format("to_be_decided", 0, need_ids[1], need_ids[2], need_ids[3])
		elseif #need_ids == 4 then
			return ("fire_slash:sgkgodliegong[%s:%s]=%d+%d+%d+%d"):format("to_be_decided", 0, need_ids[1], need_ids[2], need_ids[3], need_ids[4])
		end
	else
		local suit = card:getSuitString()
		local number = card:getNumberString()
		local card_id = card:getEffectiveId()
		return ("fire_slash:sgkgodliegong[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.double_slash_skill = sgs.double_slash_skill .. "|sgkgodliegong"
sgs.ai_ajustdamage_from.sgkgodliegong = function(self, from, to, card, nature)
	if (card and (card:isKindOf("Slash") and card:subcardsLength() >= 3 )) and table.contains(card:getSkillNames(), "sgkgodliegong")
	then
		return 1
	end
end

sgs.ai_skill_playerchosen.sgkgodbamen = function(self, targets)
	local room = self.room
	local tos = {}
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			if self:damageIsEffective(p, sgs.DamageStruct_Thunder) then table.insert(tos, p) end
		end
	end
	if #tos > 0 then
		self:sort(tos, "hp")
		return tos[1]
	else
	    return nil
	end
	return nil
end

sgs.ai_target_revises.sgkgodgucheng = function(to,card,self)
	local gc = to:property("SkillDescriptionRecord_sgkgodgucheng"):toString():split("+")
	if not table.contains(gc, card:objectName()) and self.player:objectName() ~= to:objectName() then
	return true end
end

sgs.ai_skill_invoke.sgkgodxingwu = function(self, data)
	if self.player:getRole() == "rebel" then
		if self.room:findPlayerBySkillName("sgkgodluocha") or self.room:findPlayerBySkillName("sgkgodguoqu") then return false end
		return true
	end
	if math.random(1, 100) <= 50 then
		return self.player:getMark("&sgkgodxingwu") < 1
	end
	return false
end


sgs.ai_skill_cardask["@xingwu_heart"] = function(self, data, pattern)
	local target = data:toPlayer()
	if self:isFriend(target) or (self:isEnemy(target) and target:getMark("&sgkgodxingwu") > 0) then
		local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards)
		local h = {}
		for _, c in ipairs(cards) do
			if c:getSuit() == sgs.Card_Heart then table.insert(h, c) end
		end
		if #h > 0 then
			self:sortByKeepValue(h)
			return "$"..h[1]:getEffectiveId()
		end
	end
	return "."
end

sgs.ai_skill_choice["sgkgodxingwu"] = function(self, choices, data)
	local target = data:toPlayer()
	if self:isFriend(target) then
		return "addxingwumark"
	elseif self:isEnemy(target) then
		return "transferxingwumark"
	end
end

sgs.ai_skill_playerchosen.sgkgodxingwu = function(self, targets)
	local friends = {}
	for _, pe in sgs.qlist(targets) do
		if self:isFriend(pe) then table.insert(friends, pe) end
	end
	self:sort(friends, "hp")
	return friends[1]
end

sgs.ai_skill_choice["xingwu_zhiheng_skills"] = function(self, choices, data)
	local target = data:toPlayer()
	local xingwu_rec = target:getTag("xingwu_rec"):toString():split("+")
	local can_do = false
	if self:isFriend(target) then
		for _, _sk in ipairs(xingwu_rec) do
			if string.find(sgs.bad_skills, _sk) then
				can_do = true
				break
			end
		end
		if can_do then return "xingwu_exchange_skills" end
	end
	if can_do == false and target:objectName() == self.player:objectName() then
		if #xingwu_rec <= 4 then
			if math.random(1, 1000) <= 300 then return "xingwu_exchange_skills" else return "cancel" end
		end
	end
	return "cancel"
end


--神赋
sgs.ai_skill_playerchosen.sgkgodshenfu = function(self, targets)
	local enemies = {}
	for _, t in sgs.qlist(targets) do
		if self:isEnemy(t) then 
			if self:damageIsEffective(t, sgs.DamageStruct_Thunder) or self.player:hasSkill("jueqing") then
				table.insert(enemies, t)
			end
		end
	end
	self:sort(enemies, "hp")
	if #enemies > 0 then
		return enemies[1]
	else
		return nil
	end
end

sgs.ai_getLeastHandcardNum_skill.sgkgodshenfu = function(self, player, least)
	if least < 4 then
		return 4
	end
end


--千骑
local sgkgodqianqi_skill = {}
sgkgodqianqi_skill.name = "sgkgodqianqi"
table.insert(sgs.ai_skills, sgkgodqianqi_skill)
sgkgodqianqi_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return end
	if self.player:getMark("&sgkgodqianqi") == 0 then return end
	local card_str = string.format("slash:qianqi_slash[%s:%s]=.","no_suit",0)
	local slash = sgs.Card_Parse(card_str)
	assert(slash)
	return slash
end

sgs.ai_cardsview_valuable["sgkgodqianqi"] = function(self,class_name,player)
	if class_name == "Slash" and self.player:getMark("&sgkgodqianqi") > 0 then
		return string.format("slash:qianqi_slash[%s:%s]=.","no_suit",0)
	end
end

sgs.ai_card_intention["#sgkgodqianqiCard"] = sgs.ai_card_intention.Slash
sgs.ai_use_priority["#sgkgodqianqiCard"] = sgs.ai_use_priority.Slash - 0.1
sgs.double_slash_skill = sgs.double_slash_skill .. "|sgkgodqianqi"
sgs.ai_cardneed.sgkgodqianqi = sgs.ai_cardneed.slash

--绝尘
sgs.ai_skill_invoke.sgkgodjuechen = function(self, data)
	local to = data:toPlayer()
	if self:isEnemy(to) then
		if to:hasSkills(sgs.masochism_skill.."|"..sgs.recover_skill.."|longhun|buqu|nosbuqu") then return true end
		if to:hasSkills("wuhun|sgkgodsuohun|duanchang|sgkgodshenyin|sgkgodguiqu|sgkgodfangu|sgkgodlonghun|sgkgodchenyu") then return true end
		return to:getLostHp() <= 1
	elseif self:isFriend(to) then
		if to:hasSkills("zhaxiang|mouzhaxiang") then return true end
	end
end

sgs.ai_skill_choice.sgkgodjuechen = function(self, choices, data)
	local juechen = choices:split("+")
	local target = data:toPlayer()
	if self:isEnemy(target) then
		if target:hasSkills(sgs.masochism_skill.."|"..sgs.recover_skill.."|longhun|buqu|nosbuqu") then return juechen[1] end
		if target:hasSkills("wuhun|sgkgodsuohun|duanchang|sgkgodshenyin|sgkgodguiqu|sgkgodfangu|sgkgodlonghun|sgkgodchenyu") then return juechen[1] end
		if target:hasSkills("sgkgodyinyang|sgkgodjiyin|sgkgodjiyang|sgkgodxiangsheng|sgkgoddingming") then return juechen[1] end
	elseif self:isFriend(target) then
		if target:hasSkills("zhaxiang|mouzhaxiang") then return juechen[2] end
	end
	local x = math.random(1, 100)
	if x <= 90 then
		return juechen[1]
	else
		return juechen[2]
	end
end
sgs.ai_cardneed.sgkgodjuechen = sgs.ai_cardneed.slash

--虎痴
local sgkgodhuchi_skill = {}
sgkgodhuchi_skill.name = "sgkgodhuchi"
table.insert(sgs.ai_skills, sgkgodhuchi_skill)
sgkgodhuchi_skill.getTurnUseCard = function(self, inclusive)
	if #self.enemies == 0 then return end
	if self.player:getMark("sgkgodhuchi_duel_forbidden-Clear") > 0 then return end
	local card_str = string.format("duel:sgkgodhuchi[%s:%s]=.","no_suit",0)
	local duel = sgs.Card_Parse(card_str)
	assert(duel)
	return duel
end

sgs.ai_cardsview_valuable["sgkgodhuchi"] = function(self,class_name,player)
	if class_name == "Duel" and self.player:getMark("sgkgodhuchi_duel_forbidden-Clear") == 0 then
		return string.format("duel:sgkgodhuchi[%s:%s]=.","no_suit",0)
	end
end

sgs.ai_card_intention["#sgkgodhuchiCard"] = sgs.ai_card_intention.Duel
sgs.ai_use_priority["#sgkgodhuchiCard"] = sgs.ai_use_priority.Duel

sgs.ai_ajustdamage_from.sgkgodxiejia = function(self, from, to, card, nature)
	if (card and (card:isKindOf("Slash") or card:isKindOf("Duel"))) and (from:getArmor() == nil) and to:getSeat() ~= from:getSeat()
	then
		return 1 + from:getMark("&sgkgodxiejia")
	end
end

--储元
sgs.ai_skill_cardask["@sgkgodchuyuan-black"] = function(self, data, pattern, target)
	local chuyuan, r, b = -1, 0, 0
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, id in sgs.qlist(self.player:getPile("sgkgodchu")) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isBlack() then
			b = b + 1
		elseif card:isRed() then
			r = r + 1
		end
	end
	for _, c in ipairs(cards) do
		if c:isBlack() then
			chuyuan = c
			break
		end
	end
	if chuyuan ~= -1 then
		if r + b < 5 then
			if r > b then
				return "$"..chuyuan:getEffectiveId()
			else
				--return "."
			end
		else
			if (r + b) % 2 == 1 then
				if self:isWeak() and math.min(r, b) >= 2 then
					--return "."
				end
			elseif (r + b) % 2 == 0 then
				if r >= b then return "$"..chuyuan:getEffectiveId() else return "." end
			end
		end
		return "$"..chuyuan:getEffectiveId()
	else
		return "."
	end
end

sgs.ai_skill_cardask["@sgkgodchuyuan-red"] = function(self, data, pattern, target)
	local chuyuan, r, b = -1, 0, 0
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _, id in sgs.qlist(self.player:getPile("sgkgodchu")) do
		local card = sgs.Sanguosha:getCard(id)
		if card:isBlack() then
			b = b + 1
		elseif card:isRed() then
			r = r + 1
		end
	end
	for _, c in ipairs(cards) do
		if c:isRed() then
			chuyuan = c
			break
		end
	end
	if chuyuan ~= -1 then
		if r + b < 5 then
			if r < b then
				return "$"..chuyuan:getEffectiveId()
			else
				--return "."
			end
		else
			if (r + b) % 2 == 1 then
				if self:isWeak() and math.min(r, b) >= 2 then
					--return "."
				end
			elseif (r + b) % 2 == 0 then
				if r < b then return "$"..chuyuan:getEffectiveId() else return "." end
			end
		end
		return "$"..chuyuan:getEffectiveId()
	else
		return "."
	end
	
end
sgs.ai_skill_invoke["sgkgodchuyuan"] = true

--极权
local sgkgodjiquan_skill = {}
sgkgodjiquan_skill.name = "sgkgodjiquan"
table.insert(sgs.ai_skills, sgkgodjiquan_skill)
sgkgodjiquan_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sgkgodjiquanCard") then return nil end
	if #self.friends_noself == 0 or #self.enemies > 0 then
		return sgs.Card_Parse("#sgkgodjiquanCard:.:")
	end
end

sgs.ai_skill_use_func["#sgkgodjiquanCard"] = function(card, use, self)
	local can_jiquan = {}
	local to_use = false
	for _, tar in sgs.list(self.player:getRoom():getOtherPlayers(self.player)) do
		if not self:isFriend(tar) and not tar:hasSkills(sgs.bad_skills) then
			table.insert(can_jiquan, tar)
		end
	end
	if #can_jiquan > 0 then to_use = true end
	self:sort(can_jiquan, "hp")
	if to_use then
	    use.card = card
		if use.to then
		    for _, enemy in ipairs(can_jiquan) do
			    use.to:append(enemy)
			end
			assert(use.to:length() > 0)
		end
	end
end

sgs.ai_use_value["sgkgodjiquanCard"] = 10
sgs.ai_use_priority["sgkgodjiquanCard"] = 10

sgs.ai_skill_choice.sgkgodjiquan = function(self, choices, data)
	choices = choices:split("+")
	local caopi = data:toPlayer()
	if self:isEnemy(caopi) then
		if self.player:hasSkills(sgs.bad_skills) then  --如果有“缠怨”“恃勇”这类负面技能
			return choices[2]  --丢给神曹丕
		else
			if self:isWeak() and self.player:getMark("sgkgodjiquan_times") >= 3 and self.player:getCards("he"):length() - self.player:getMark("sgkgodjiquan_times") <= 2 then
				return choices[2]
			end
		end
		return choices[1]
	else
		return choices[1]
	end
end


--仁政
local sgkgodrenzheng_skill = {}
sgkgodrenzheng_skill.name = "sgkgodrenzheng"
table.insert(sgs.ai_skills, sgkgodrenzheng_skill)
sgkgodrenzheng_skill.getTurnUseCard = function(self, inclusive)
	if self.player:hasUsed("#sgkgodrenzhengCard") then return nil end
	if #self.friends_noself == 0 then return nil end
	return sgs.Card_Parse("#sgkgodrenzhengCard:.:")
end

sgs.ai_skill_use_func["#sgkgodrenzhengCard"] = function(card, use, self)
	local can_renzheng = {}
	local to_use = false
	for _, tar in sgs.list(self.player:getRoom():getOtherPlayers(self.player)) do
		if self:isFriend(tar) or (self:isEnemy(tar) and self.player:hasSkills(sgs.bad_skills)) then
			table.insert(can_renzheng, tar)
		end
	end
	if #can_renzheng > 0 then to_use = true end
	self:sort(can_renzheng, "defense")
	if to_use then
		local target = nil
	    use.card = card
		if use.to then
		    if self.player:hasSkills(sgs.bad_skills) then
				for _, t in ipairs(can_renzheng) do
					if self:isEnemy(t) then
						target = t
						break
					end
				end
			else
				target = can_renzheng[1]
			end
			if target then use.to:append(target) end
			return
		end
	end
end

sgs.ai_use_value["sgkgodrenzhengCard"] = 10
sgs.ai_use_priority["sgkgodrenzhengCard"] = sgs.ai_use_priority.ExNihilo - 1

sgs.ai_skill_choice.sgkgodrenzheng = function(self, choices, data)
	choices = choices:split("+")  --1号：给牌；2号：给技能
	local to = data:toPlayer()
	if self:isEnemy(to) then
		if self.player:hasSkills(sgs.bad_skills) then  --如果有“缠怨”“恃勇”这类负面技能
			return choices[2]  --“赏赐”给敌人
		else
			if not self.player:isKongcheng() and ((to:hasSkill("kongcheng") and to:isKongcheng()) or to:hasSkill("shangshi") and to:getHandcardNum() >= to:getLostHp() and to:isWounded()) then
				return choices[1]
			end
		end
	else
		return choices[math.random(1, 2)]
	end
end

sgs.ai_skill_choice["renzheng_giveskill"] = function(self, choices, data)
	choices = choices:split("+")
	local result = nil
	local to = data:toPlayer()
	if self:isEnemy(to) then
		for _, name in ipairs(choices) do
			if string.find(sgs.bad_skills, name) then
				result = name
				break
			end
		end
		if not result then
			if table.contains(choices, "cancel") then
				result = "cancel"
			else
				for _, name in ipairs(choices) do
					if string.find(sgs.bad_skills, name) then
						result = name
						break
					end
				end
			end
		end
	elseif self:isFriend(to) then
		if self.player:getHp() <= 1 and self:isWeak() then  --如果自己觉得打不下去了，那就把一切身家托付给队友
			if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") == 0 then
				if not table.contains(choices, "cancel") then
					result = choices[#choices]
				else
					if #choices == 1 then result = "cancel" end
				end
			end
		else
			if table.contains(choices, "cancel") then
				result = "cancel"
			else
				for _, name in ipairs(choices) do
					if not string.find(sgs.bad_skills, name) then
						if name == "sgkgodchuyuan" or name == "sgkgoddengji" then
							result = name
							break
						else
							if #choices > 2 and name ~= "sgkgodrenzheng" and name ~= "cancel" then
								result = name
								break
							end
						end
					end
				end
				if #choices <= 2 and table.contains(choices, "sgkgodrenzheng") then
					result = choices[math.random(1, #choices)]
				end
			end
		end
	end
	return result or "cancel"
end

sgs.ai_skill_choice["sgkgodrenzheng_buff"] = function(self, choices, data)
	choices = choices:split("+")
	local result = nil
	local to = data:toPlayer()
	if self:isFriend(to) then
		return "yes"
	end
	return "no"
end


--论策
sgs.ai_skill_playerchosen.sgkgodlunce = function(self, targets)
	local target
	if #self.enemies > 0 then
		for _, t in sgs.qlist(targets) do
			if t:hasSkills("sgkgodtongtian|sy_bolue|sy_old_bolue|sgkgodluocha|sgkgodzhitian|sgkgodzhiti|sgkgodyaozhi|sgkgodjieying|jinghe") then
				target = t
				break
			end
		end
		if not target then
			for _, t in sgs.qlist(targets) do
				if t:hasSkills("jinqu|shelie|sgkgodshelie|sgkgodbamen|yongsi|mobilemouyangwei|zishu|sgkgodhuju|hengwu|qingshi|ny_zhangcai|ny_10th_zhangcai|ny_10th_qingbei|ny_10th_sujun") then
					target = t
					break
				end
			end
		end
		if not target then
			for _, t in sgs.qlist(targets) do
				if t:hasSkills("ny_tenth_pingliao|sgkgodjilue|lingce|sgkgodhualong|guixin|jianying|sgkgodyingshi|shenwei|shezang|zhouxuanz|mouwusheng|zhaxiang|sgkgodshajue") then
					target = t
					break
				end
			end
		end
		if not target then
			for _, t in sgs.qlist(targets) do
				if t:hasSkills("luanji|sgkgodhuchi|sy_mojian|sy_shiao|yingjian|qiangxi|jieyin|qingnang|shushen|jinquanbian|longhun|sgkgodlonghun|sr_shixue") then
					target = t
					break
				end
			end
		end
	end
	if not target then
		for _, t in sgs.qlist(targets) do
			if self:isFriend(t) and self:isWeak(t) then
				target = t
				break
			end
		end
	end
	if not target then
		target = self.player
	end
	return target
end

sgs.ai_skill_choice.sgkgodlunce = function(self, choices, data)
	local t = data:toPlayer()
	local lunce = choices:split("+")
	if self:isEnemy(t) then
		if string.find(choices, "sgkgodshangce") then
			if t:hasSkills("sgkgodtongtian|sy_bolue|sy_old_bolue|sgkgodluocha|sgkgodzhitian|sgkgodzhiti|sgkgodyaozhi|sgkgodjieying|jinghe|zhengnan") then
				return "sgkgodshangce"
			end
			if t:hasSkills("jinqu|shelie|sgkgodshelie|sgkgodbamen|yongsi|mobilemouyangwei|zishu|sgkgodhuju|hengwu|qingshi|ny_zhangcai|ny_10th_zhangcai|ny_10th_qingbei|ny_10th_sujun") then
				return "sgkgodshangce"
			end
			if t:hasSkills("ny_tenth_pingliao|sgkgodjilue|lingce|sgkgodhualong|guixin|jianying|sgkgodyingshi|shenwei|shezang|zhouxuanz|mouwusheng|zhaxiang|sgkgodshajue") then
				return "sgkgodshangce"
			end
			if t:hasSkills("luanji|sgkgodhuchi|sy_mojian|sy_shiao|yingjian|qiangxi|jieyin|qingnang|shushen|jinquanbian|longhun|sgkgodlonghun|sr_shixue") then
				return "sgkgodshangce"
			end
		end
	elseif self:isFriend(t) then
		if string.find(choices, "sgkgodshangce") then
			if t:hasSkills("sgkgodtongtian|sy_bolue|sy_old_bolue|sgkgodluocha|sgkgodzhitian|sgkgodzhiti|sgkgodyaozhi|sgkgodjieying|jinghe") then
				return "sgkgodshangce"
			end
			if t:hasSkills("jinqu|shelie|sgkgodshelie|sgkgodbamen|yongsi|mobilemouyangwei|zishu|sgkgodhuju|hengwu|qingshi|ny_zhangcai|ny_10th_zhangcai|ny_10th_qingbei|ny_10th_sujun") then
				return "sgkgodshangce"
			end
			if t:hasSkills("ny_tenth_pingliao|sgkgodjilue|lingce|sgkgodhualong|guixin|jianying|sgkgodyingshi|shenwei|shezang|zhouxuanz|mouwusheng|zhaxiang|sgkgodshajue|xinghan") then
				return "sgkgodshangce"
			end
			if t:hasSkills("luanji|sgkgodhuchi|sy_mojian|sy_shiao|yingjian|qiangxi|jieyin|qingnang|shushen|jinquanbian|longhun|sgkgodlonghun|sr_shixue|xingtu") then
				return "sgkgodshangce"
			end
		end
	end
	if t:objectName() ~= self.player:objectName() then
		for _, lc in ipairs(lunce) do
			if lc ~= "sgkgodshangce" then return lc end
		end
	else
		return lunce[math.random(1, #lunce)]
	end
end

sgs.ai_skill_choice["lunce_condition"] = function(self, choices, data)
	local t = data:toPlayer()
	local cd = choices:split("+")
	local st = self.player:getTag("st_AI"):toString()
	if st == "sgkgodshangce" then
		if t:hasSkills("sgkgodshelie|shelie|sgkgodjilue|sgkgodyingshi|yongsi|tenyearzhiheng|sgkgodtianzi|ny_10th_sujun|ny_10th_qingbei|ny_10th_zhangcai|sgkgodluocha|sgkgodhuju") then
			if table.contains(cd, "lunce_shang_suit") then return "lunce_shang_suit" end
			if table.contains(cd, "lunce_shang_type") then return "lunce_shang_type" end
		end
		if t:hasSkills("mobilemouyangwei|zishu|hengwu|qingshi|jinqu|lingce|xingtu|sy_longbian|sy_yinzi|shezang|shanjia|olshanjia|xinghan|jianying|sgkgodyingshi") then
			if table.contains(cd, "lunce_shang_suit") then return "lunce_shang_suit" end
			if table.contains(cd, "lunce_shang_type") then return "lunce_shang_type" end
		end
		if t:hasSkills("ny_tenth_pingliao|sgkgodjilue|lingce|sgkgodhualong|sgkgodshayi|sgkgodyingshi|shenwei|shezang|zhouxuanz|mouwusheng|zhaxiang|sgkgodshajue|xinghan|sy_shiao") then
			if table.contains(cd, "lunce_shang_causedying") then return "lunce_shang_causedying" end
		end
		if self:isWeak(t) or t:hasSkills("sgkgodjuejing|newjuejing|zhaohuo|buqu|nosbuqu") then
			if table.contains(cd, "lunce_shang_dying") then return "lunce_shang_dying" end
		end
		if t:hasSkills("sgkgodtongtian|sy_bolue|sy_old_bolue|sgkgodluocha|sgkgodzhitian|sgkgodzhiti|sgkgodyaozhi|sgkgodjieying|jinghe|zhengnan") then
			if table.contains(cd, "lunce_shang_acquireskill") then return "lunce_shang_acquireskill" end
		end
		if t:hasSkills("sgkgodguiqu|sy_bolue|sy_old_bolue|sgkgodqianyuan") then
			if table.contains(cd, "lunce_shang_loseskill") then return "lunce_shang_loseskill" end
		end
	elseif st == "sgkgodzhongce" then
		if t:hasSkills("jiuchi|duanliang|qingguo|kanpo|olkanpo|oljiuchi|longhun|newlonghun|sgkgodlonghun|mouwusheng|sgkgodshajue") then
			if table.contains(cd, "lunce_zhong_2spade") then return "lunce_zhong_2spade" end
		end
		if t:hasSkills("wushen|wusheng|mouwusheng|sgkgodshajue|jijiu|nosenyuan|moujizhi|lingce") then
			if table.contains(cd, "lunce_zhong_2heart") then return "lunce_zhong_2heart" end
		end
		if t:hasSkills("huoshou|luanji|olluanji|shizhan|sgkgodhuchi|xingxiezheng|chuifeng|quedi|huoji|guanbian|sy_mojian") then
			if table.contains(cd, "lunce_zhong_trick2dmg") then return "lunce_zhong_trick2dmg" end
		end
		if t:hasSkills("sgkgodshajue|sgkgodshayi|paixiao|mouliegongg|moupaoxiao|mobilepojun|sgkgodyeyan|shajue|yanru|qingshi|zhangcai|shensu|sy_shiao|sy_shenji|wushuang|jieyingg") then
			if table.contains(cd, "lunce_zhong_slash2dmg") then return "lunce_zhong_slash2dmg" end
		end
	end
	return cd[math.random(1, #cd)]
end

sgs.ai_skill_choice["lunce_effect"] = function(self, choices, data)
	local t = data:toPlayer()
	local ef = choices:split("+")
	local cd = self.player:getTag("lunce_condition_AI"):toString()
	if cd:startsWith("lunce_shang_") then
		if self:isEnemy(t) then
			if table.contains(ef, "lunce_shang_loserandomskill") then return "lunce_shang_loserandomskill" end
			if table.contains(ef, "lunce_shang_throwallcards") and not t:isNude() then return "lunce_shang_throwallcards" end
		elseif self:isFriend(t) then
			if table.contains(ef, "lunce_shang_gainsamekingdomskill") then return "lunce_shang_gainsamekingdomskill" end
			if table.contains(ef, "lunce_shang_1maxhp1recover") then return "lunce_shang_1maxhp1recover" end
			if table.contains(ef, "lunce_shang_gainsamekingdomskill") and table.contains(ef, "lunce_shang_1maxhp1recover") then
				return ef[math.random(1, 2)]
			end
		end
	elseif cd:startsWith("lunce_zhong_") then
		if self:isEnemy(t) then
			if table.contains(ef, "lunce_zhong_turnover") and t:faceUp() and (not t:hasSkills("jushou|kuiwei|faen|moujushou")) then return "lunce_zhong_turnover" end
			if table.contains(ef, "lunce_zhong_losemaxhp") and not t:hasSkill("sgkgodwangyue|sgkgoddanjing") then return "lunce_zhong_losemaxhp" end
		elseif self:isFriend(t) then
			if table.contains(ef, "lunce_zhong_drawphase") then return "lunce_zhong_drawphase" end
			if table.contains(ef, "lunce_zhong_slashtime") then return "lunce_zhong_slashtime" end
			if table.contains(ef, "lunce_zhong_drawphase") and table.contains(ef, "lunce_zhong_slashtime") then
				return ef[math.random(1, 2)]
			end
		end
	elseif cd:startsWith("lunce_xia_") then
		if self:isEnemy(t) then
			if table.contains(ef, "lunce_xia_throw2") and not t:isNude() then return "lunce_xia_throw2" end
			if table.contains(ef, "lunce_xia_firedamage") and not t:hasSkills("shixin|sr_weiwo|sgkgodyinshi") then return "lunce_xia_firedamage" end
		elseif self:isFriend(t) then
			if table.contains(ef, "lunce_xia_draw2") then return "lunce_xia_draw2" end
			if table.contains(ef, "lunce_xia_recover1") and t:isWounded() then return "lunce_xia_recover1" end
			if table.contains(ef, "lunce_xia_draw2") and table.contains(ef, "lunce_xia_recover1") and t:isWounded() then
				return ef[math.random(1, 2)]
			end
		end
	end
end


--寒霜
sgs.ai_skill_choice.sgkgodhanshuang = function(self, choices, data)
	local t = data:toPlayer()
	local hs = choices:split("+")
	local damage = self.player:getTag("hanshuang_AI_data"):toDamage()
	if #hs == 3 then  --可弃牌减伤（1-摸牌加伤；2-弃牌减伤；3-不发动）
		if self:isFriend(t) then
			if self:isWeak(t) and damage.damage >= t:getHp() then return hs[2] end
			if t:hasArmorEffect("silver_lion") then  --如果友方有“白银狮子”或者视为装备了白银狮子
				if t:hasSkills(sgs.masochism_skill) and t:getHp() >= 2 then return hs[1] end  --有卖血技就摸牌卖血，因为溢出的伤害都会被抵消掉
				if t:hasSkill("sy_fangu") and t:getHp() >= 2 then return hs[1] end  --如果队友有极略魔魏延的“反骨”，那就让他摸牌并直接抢额外回合
			end
			if t:hasSkill("sgkgodyinshi") and damage.nature and damage.nature ~= sgs.DamageStruct_Thunder then return hs[1] end  --如果队友有极略神司马徽的“隐世”且是非雷电伤害，白嫖摸牌
			if t:hasSkill("sgkgodleihun") and damage.nature and damage.nature == sgs.DamageStruct_Thunder then return hs[1] end  --如果队友有极略神张角的“雷魂”且是雷电伤害，白嫖摸牌和回血
		elseif self:isEnemy(t) then
			if t:hasSkill("sgkgodleihun") and damage.nature and damage.nature == sgs.DamageStruct_Thunder then return hs[2] end
			if self.player:getMark("sgkgodliluan-Clear") == 0 then
				if not t:hasSkills(sgs.masochism_skill) and (not t:hasSkill("sgkgodyinshi")) and (not t:hasArmorEffect("silver_lion")) then return hs[1] end
			end
			if t:getMark("&sgkgodhanshuang_times_lun") == 0 then
				if not t:hasSkills(sgs.masochism_skill) and (not t:hasSkill("sgkgodyinshi")) and (not t:hasArmorEffect("silver_lion")) then return hs[1] end
			elseif t:getMark("&sgkgodhanshuang_times_lun") >= 1 then
				if (not t:hasSkill("sgkgodyinshi")) and (not t:hasArmorEffect("silver_lion")) then return hs[1] end
				if not self:isWeak(t) then
					if t:hasSkills(sgs.masochism_skill) or t:hasSkill("sgkgodyinshi") then
						if t:getCards("he"):length() >= t:getMark("&sgkgodhanshuang_times_lun") + 1 + damage.damage then
							return hs[2]
						end
					end
				end
			end
		end
		return "cancel"
	elseif #hs == 2 then  --无法弃牌减伤（1-摸牌加伤；2-不发动）
		if self:isFriend(t) then
			if t:hasSkill("sgkgodleihun") and damage.nature and damage.nature == sgs.DamageStruct_Thunder then return "cancel" end
			if self:isWeak(t) and damage.damage >= t:getHp() then return "cancel" end
			if t:hasArmorEffect("silver_lion") then  --如果友方有“白银狮子”或者视为装备了白银狮子
				if t:hasSkills(sgs.masochism_skill) and t:getHp() >= 2 then return hs[1] end  --有卖血技就摸牌卖血，因为溢出的伤害都会被抵消掉
				if t:hasSkill("sy_fangu") and t:getHp() >= 2 then return hs[1] end  --如果队友有极略魔魏延的“反骨”，那就让他摸牌并直接抢额外回合
			end
			if t:hasSkill("sgkgodyinshi") and damage.nature and damage.nature ~= sgs.DamageStruct_Thunder then return hs[1] end  --如果队友有极略神司马徽的“隐世”且是非雷电伤害，白嫖摸牌
			if t:hasSkill("sgkgodleihun") and damage.nature and damage.nature == sgs.DamageStruct_Thunder then return hs[1] end  --如果队友有极略神张角的“雷魂”且是雷电伤害，白嫖摸牌和回血
		elseif self:isEnemy(t) then
			if t:hasSkill("sgkgodleihun") and damage.nature and damage.nature == sgs.DamageStruct_Thunder then return "cancel" end
			if self.player:getMark("sgkgodliluan-Clear") == 0 then
				if not t:hasSkills(sgs.masochism_skill) and (not t:hasSkill("sgkgodyinshi")) and (not t:hasArmorEffect("silver_lion")) then return hs[1] end
			end
			if t:getMark("&sgkgodhanshuang_times_lun") == 0 then
				if not t:hasSkills(sgs.masochism_skill) and (not t:hasSkill("sgkgodyinshi")) and (not t:hasArmorEffect("silver_lion")) then return hs[1] end
			elseif t:getMark("&sgkgodhanshuang_times_lun") >= 1 then
				if (not t:hasSkill("sgkgodyinshi")) and (not t:hasArmorEffect("silver_lion")) then return hs[1] end
				if not self:isWeak(t) then
					if t:hasSkills(sgs.masochism_skill) or t:hasSkill("sgkgodyinshi") then
						if t:getCards("he"):length() >= t:getMark("&sgkgodhanshuang_times_lun") + 1 + damage.damage then
							return "cancel"
						end
					end
				end
			end
		end
		return "cancel"
	end
end


--离乱
sgs.ai_skill_invoke.sgkgodliluan = function(self, data)
	local move = self.player:getTag("liluan_AI_movedata"):toMoveOneTime()
	local target = data:toPlayer()
	--弃牌
	if move.to_place == sgs.Player_DiscardPile and (move.from_places:contains(sgs.Player_PlaceHand)
	or move.from_places:contains(sgs.Player_PlaceEquip)) and not move.from_places:contains(sgs.Player_PlaceDelayedTrick) and 
	bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DISCARD then
		if move.card_ids:length() >= 2 and self:isFriend(target) then return true end
	end
	--摸牌
	if move.to_place == sgs.Player_PlaceHand and move.to and (bit32.band(move.reason.m_reason, sgs.CardMoveReason_S_MASK_BASIC_REASON) == sgs.CardMoveReason_S_REASON_DRAW 
	or move.reason.m_reason == sgs.CardMoveReason_S_REASON_DRAW) then
		if move.card_ids:length() >= 2 and self:isEnemy(target) then return true end
	end
end

sgs.ai_ajustdamage_to["sgkgodyinshi"] = function(self,from,to,card,nature)
	if natrue~="T" then return -99 end
end

sgs.ai_ajustdamage_to["sgkgodleihun"] = function(self,from,to,card,nature)
	if natrue=="T" then return -99 end
end

--涉猎
sgs.ai_skill_choice.nos_sgkgodshelie = function(self, choices)
    local shelie = choices:split("+")
	return shelie[math.random(1, #shelie)]
end


--攻心
local nos_sgkgodgongxin_skill= {}
nos_sgkgodgongxin_skill.name = "nos_sgkgodgongxin"
table.insert(sgs.ai_skills, nos_sgkgodgongxin_skill)
nos_sgkgodgongxin_skill.getTurnUseCard = function(self)
    if #self.enemies == 0 then return nil end
	if self.player:hasUsed("#nos_sgkgodgongxinCard") then return nil end
	local sgkgodgongxin_card = sgs.Card_Parse("#nos_sgkgodgongxinCard:.:")
	assert(sgkgodgongxin_card)
	return sgkgodgongxin_card
end

sgs.ai_skill_use_func["#nos_sgkgodgongxinCard"] = function(card, use, self)
    self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	for _, enemy in ipairs(self.enemies) do
		if not enemy:isKongcheng() and self:objectiveLevel(enemy) > 0
			and (self:hasSuit("heart", false, enemy) or self:getKnownNum(enemy) ~= enemy:getHandcardNum()) then
			use.card = card
			if use.to then
				use.to:append(enemy)
			end
			return
		end
	end
end

sgs.ai_use_value["nos_sgkgodgongxinCard"] = 8.5
sgs.ai_use_priority["nos_sgkgodgongxinCard"] = 9.5
sgs.ai_card_intention["nos_sgkgodgongxinCard"] = 80



--龙魂
local nos_sgkgodlonghun_skill = {}
nos_sgkgodlonghun_skill.name = "nos_sgkgodlonghun"
table.insert(sgs.ai_skills, nos_sgkgodlonghun_skill)
nos_sgkgodlonghun_skill.getTurnUseCard = function(self)
    if self.player:getHp()>1 then return end
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByUseValue(cards,true)
	for _, card in ipairs(cards) do
		if card:getSuit() == sgs.Card_Diamond and self:slashIsAvailable() then
			return sgs.Card_Parse(("fire_slash:nos_sgkgodlonghun[%s:%s]=%d"):format(card:getSuitString(), card:getNumberString(), card:getId()))
		end
	end
end

sgs.ai_view_as["nos_sgkgodlonghun"] = function(card, player, card_place)
    local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	if player:getHp() > 1 or card_place == sgs.Player_PlaceSpecial then return end
	if card:getSuit() == sgs.Card_Diamond then
		return ("fire_slash:nos_sgkgodlonghun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Club then
		return ("jink:nos_sgkgodlonghun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Heart and player:getMark("Global_PreventPeach") == 0 then
		return ("peach:nos_sgkgodlonghun[%s:%s]=%d"):format(suit, number, card_id)
	elseif card:getSuit() == sgs.Card_Spade then
		return ("nullification:nos_sgkgodlonghun[%s:%s]=%d"):format(suit, number, card_id)
	end
end

sgs.nos_sgkgodlonghun_suit_value = {
    heart = 6.7,
	spade = 5,
	club = 4.2,
	diamond = 3.9,
}

function sgs.ai_cardneed.nos_sgkgodlonghun(to, card, self)
	if to:getCardCount() > 3 then return false end
	if to:isNude() then return true end
	return card:getSuit() == sgs.Card_Heart or card:getSuit() == sgs.Card_Spade
end

--逆战
sgs.ai_skill_playerchosen.nos_sgkgodnizhan = function(self, targets)
    local to = sgs.QList2Table(targets)
	if self:isFriend(to[1]) and self:isEnemy(to[2]) then
	    return to[2]
	elseif self:isEnemy(to[1]) and self:isFriend(to[2]) then
	    return to[1]
	elseif self:isEnemy(to[1]) and self:isEnemy(to[2]) then
	    return to[math.random(1, 2)]
	end
end

sgs.ai_skill_invoke.nos_sgkgodnizhan = function(self, data)
    local damage = data:toDamage()
	if self:isFriend(damage.from) and (not self:isFriend(damage.to)) then return true end
	if self:isFriend(damage.to) and (not self:isFriend(damage.from)) then return true end
	if self:isEnemy(damage.from) and self:isEnemy(damage.to) then return true end
	return false
end


--威震
sgs.ai_skill_invoke.nos_sgkgodweizhen = function(self, data)
    local s = 0
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
	    s = s + p:getMark("@xi")
	end
	return self.player:getHp() <= 1 and s >= 2 and self.player:getJudgingArea():length() > 0
end


--通天
local nos_sgkgodtongxian_skill = {}
nos_sgkgodtongxian_skill.name = "nos_sgkgodtongtian"
table.insert(sgs.ai_skills, nos_sgkgodtongxian_skill)
nos_sgkgodtongxian_skill.getTurnUseCard = function(self, inclusive)
    if self.player:isKongcheng() then return nil end
	if self.player:getMark("@tian") <= 0 then return nil end
	local suits = {}
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Spade then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Heart then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Club then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	for _, card in sgs.qlist(self.player:getCards("he")) do
	    if card:getSuit() == sgs.Card_Diamond then
		    table.insert(suits, card:getSuitString())
			break
		end
	end
	if #suits > 3 then
	    return sgs.Card_Parse("#nos_sgkgodtongtianCard:.:")
	end
end

sgs.ai_skill_use_func["#nos_sgkgodtongtianCard"] = function(card, use, self)
    local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards, false, true)
	local need_cards = {}
	local spade, club, heart, diamond
	for _, card in ipairs(cards) do
	    if card:getSuit() == sgs.Card_Spade then
		    if (not self.player:hasSkills("fankui|nosfankui")) and (not spade) then
			    spade = true
				table.insert(need_cards, card:getId())
			end
		elseif card:getSuit() == sgs.Card_Heart then
		    if (not self.player:hasSkill("guanxing")) and (not heart) then
			    heart = true
				table.insert(need_cards, card:getId())
			end
		elseif card:getSuit() == sgs.Card_Club then
		    if (not self.player:hasSkill("wansha")) and (not club) then
			    club = true
				table.insert(need_cards, card:getId())
			end
		elseif card:getSuit() == sgs.Card_Diamond then
		    if (not self.player:hasSkills("zhiheng|hujuzhiheng")) and (not diamond) then
			    diamond = true
				table.insert(need_cards, card:getId())
			end
		end
	end
	if #need_cards < 4 then return nil end
	local tongtian_cards = sgs.Card_Parse("#nos_sgkgodtongtianCard:" .. table.concat(need_cards, "+") .. ":")
	assert(tongtian_cards)
	use.card = tongtian_cards
end


sgs.ai_use_value["nos_sgkgodtongtianCard"] = 10
sgs.ai_use_priority["nos_sgkgodtongtianCard"] = 9  --强行改动：没有四张花色，打死不【通天】。


--制衡（通天）
local tongtian_zhiheng_skill = {}
tongtian_zhiheng_skill.name = "tongtian_zhiheng"
table.insert(sgs.ai_skills, tongtian_zhiheng_skill)
tongtian_zhiheng_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#tongtian_zhihengCard") then
		return sgs.Card_Parse("#tongtian_zhihengCard:.:")
	end
end

sgs.ai_skill_use_func["#tongtian_zhihengCard"] = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp() < 3 then
		local zcards = self.player:getCards("he")
		local use_slash, keep_jink, keep_analeptic, keep_weapon = false, false, false
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _, zcard in sgs.qlist(zcards) do
			if not isCard("Peach", zcard, self.player) and not isCard("ExNihilo", zcard, self.player) then
				local shouldUse = true
				if isCard("Slash", zcard, self.player) and not use_slash then
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
						if not shouldUse then use_slash = true end
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
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if isCard("Jink", zcard, self.player) and not keep_jink then
					keep_jink = true
					shouldUse = false
				end
				if self.player:getHp() == 1 and isCard("Analeptic", zcard, self.player) and not keep_analeptic then
					keep_analeptic = true
					shouldUse = false
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
			end
		end
	end

	if #unpreferedCards == 0 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card) then
					local dummy_use = self:aiUseCard(card, dummy())
					if dummy_use.card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getId()) end
			end
		end

		local num = self:getCardsNum("Jink") - 1
		if self.player:getArmor() then num = num + 1 end
		if num > 0 then
			for _, card in ipairs(cards) do
				if card:isKindOf("Jink") and num > 0 then
					table.insert(unpreferedCards, card:getId())
					num = num - 1
				end
			end
		end
		for _, card in ipairs(cards) do
			if (card:isKindOf("Weapon") and self.player:getHandcardNum() < 3) or card:isKindOf("OffensiveHorse")
				or self:getSameEquip(card, self.player) or card:isKindOf("AmazingGrace") then
				table.insert(unpreferedCards, card:getId())
			elseif card:getTypeId() == sgs.Card_TypeTrick then
				local dummy_use = self:aiUseCard(card, dummy())
				if not dummy_use.card then table.insert(unpreferedCards, card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
			table.insert(unpreferedCards, self.player:getWeapon():getId())
		end

		if self:needToThrowArmor() then
			table.insert(unpreferedCards, self.player:getArmor():getId())
		end

		if self.player:getOffensiveHorse() and self.player:getWeapon() then
			table.insert(unpreferedCards, self.player:getOffensiveHorse():getId())
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then table.insert(use_cards, unpreferedCards[index]) end
	end

	if #use_cards > 0 then
		if self.room:getMode() == "02_1v1" and sgs.GetConfig("1v1/Rule", "Classical") ~= "Classical" then
			local use_cards_kof = { use_cards[1] }
			if #use_cards > 1 then table.insert(use_cards_kof, use_cards[2]) end
			use.card = sgs.Card_Parse("#tongtian_zhihengCard:" .. table.concat(use_cards_kof, "+") .. ":")
			return
		else
			use.card = sgs.Card_Parse("#tongtian_zhihengCard:" .. table.concat(use_cards, "+") .. ":")
			return
		end
	end
end

sgs.ai_use_value["tongtian_zhihengCard"] = 9
sgs.ai_use_priority["tongtian_zhihengCard"] = 2.61
sgs.dynamic_value.benefit["tongtian_zhihengCard"] = true


function sgs.ai_cardneed.tongtian_zhiheng(to, card)
	return not card:isKindOf("Jink")
end


--反馈
sgs.ai_skill_invoke.tongtian_fankui = function(self, data)
    local damage = data:toDamage()
	if self:isEnemy(damage.from) then
	    return true
	end
	return false
end

--极略
local nos_sgkgodjilue_skill = {}
nos_sgkgodjilue_skill.name = "nos_sgkgodjilue"
table.insert(sgs.ai_skills, nos_sgkgodjilue_skill)
nos_sgkgodjilue_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasFlag("jiluefailed") then return end
	return sgs.Card_Parse("#nos_sgkgodjilueCard:.:")
end

sgs.ai_skill_use_func["#nos_sgkgodjilueCard"] = function(card, use, self)
    if self.player:hasFlag("jiluefailed") then return end
	use.card = card
end

sgs.ai_use_value["nos_sgkgodjilueCard"] = 10
sgs.ai_use_priority["nos_sgkgodjilueCard"] = 8
sgs.dynamic_value.benefit["nos_sgkgodjilueCard"] = true


--第一部分：含有锦囊牌的pattern
--1-1：锦囊牌、杀
sgs.ai_skill_use["TrickCard+^Nullification,Slash,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--1-2：锦囊牌、杀、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Slash,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--1-3：锦囊牌、杀、酒
sgs.ai_skill_use["TrickCard+^Nullification,Slash,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-4：锦囊牌、杀、酒、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Slash,Analeptic,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-5：锦囊牌、桃
sgs.ai_skill_use["TrickCard+^Nullification,Peach,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			end
		end
	end
	return "."
end

--1-6：锦囊牌、桃、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Peach,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			end
		end
	end
	return "."
end

--1-7：锦囊牌、桃、酒
sgs.ai_skill_use["TrickCard+^Nullification,EquipCard,Slash,Peach,Analeptic|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
							local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-8：锦囊牌、桃、酒、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Peach,Analeptic,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic then
		    if card:isKindOf("Peach") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-9：锦囊牌、桃、杀
sgs.ai_skill_use["TrickCard+^Nullification,Peach,Slash,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--1-10：锦囊牌、桃、杀、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Peach,Slash,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--1-11：锦囊牌、基本牌（除闪）
sgs.ai_skill_use["TrickCard+^Nullification,Peach,Slash,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-12：锦囊牌、基本牌（除闪）、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Peach,Slash,Analeptic,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-13：锦囊牌、酒
sgs.ai_skill_use["TrickCard+^Nullification,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-14：锦囊牌、酒、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,Analeptic,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
							local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--1-15：锦囊牌、装备牌
sgs.ai_skill_use["TrickCard+^Nullification,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		end
	end
	return "."
end

--1-16：锦囊牌
sgs.ai_skill_use["TrickCard+^Nullification,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		end
	end
	return "."
end

--第二部分：无锦囊牌的pattern
--2-1：杀
sgs.ai_skill_use["Slash,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--2-2：杀、装备牌
sgs.ai_skill_use["Slash,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--2-3：杀，酒
sgs.ai_skill_use["Slash,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-4：杀、酒、装备牌
sgs.ai_skill_use[" Slash,Analeptic,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Slash") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
							local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-5：桃
sgs.ai_skill_use["Peach,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			end
		end
	end
	return "."
end

--2-6：桃、装备牌
sgs.ai_skill_use["Peach,EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			end
		end
	end
	return "."
end

--2-7：桃、酒
sgs.ai_skill_use["Peach,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
							local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-8：桃、酒、装备牌
sgs.ai_skill_use["Peach,Analeptic,EquipCard|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
							local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-9：桃、杀
sgs.ai_skill_use["Peach,Slash,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			end
		end
	end
	return "."
end

--2-10：桃、杀、装备牌
sgs.ai_skill_use["Peach,Slash,EquipCard|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeTrick and not card:isKindOf("Nullification") and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				if dummy_use.to:isEmpty() then
					return dummy_use.card:toString()
				else
					local target_objectname = {}
					for _, p in sgs.qlist(dummy_use.to) do
						table.insert(target_objectname, p:objectName())
					end
					return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
				end
			end
		elseif card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
							local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-11：除了闪的基本牌
sgs.ai_skill_use["Peach,Slash,Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
							local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-12：基本牌（除闪）、装备牌
sgs.ai_skill_use["Peach,Slash,Analeptic,EquipCard|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Peach") then
				local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    return dummy_use.card:toString()
				end
			elseif card:isKindOf("Slash") then
			    local dummy_use = self:aiUseCard(card, dummy())
				if dummy_use.card then
				    if not dummy_use.to:isEmpty() then
				        local target_objectname = {}
					    for _, p in sgs.qlist(dummy_use.to) do
						    table.insert(target_objectname, p:objectName())
					    end
					    return dummy_use.card:toString() .. "->" .. table.concat(target_objectname, "+")
					end
				end
			elseif card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
						    local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-13：酒
sgs.ai_skill_use[" Analeptic,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
							local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-14：酒、装备牌
sgs.ai_skill_use["Analeptic,EquipCard|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		elseif card:getTypeId() == sgs.Card_TypeBasic and not self.player:isLocked(card) then
		    if card:isKindOf("Analeptic") then
			    local ana = sgs.Sanguosha:cloneCard("analeptic", sgs.Card_NoSuit, 0)
				if not self.player:isCardLimited(ana, sgs.Card_MethodUse) and not self.player:isProhibited(self.player, ana) then
				    if self.player:usedTimes("Analeptic") <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, ana) then
					    if sgs.Analeptic_IsAvailable(self.player) then
							local dummy_use = self:aiUseCard(card, dummy())
				            if dummy_use.card then
				                return dummy_use.card:toString()
				            end
						end
					end
				end
			end
		end
	end
	return "."
end

--2-15：装备牌
sgs.ai_skill_use["EquipCard,|.|.|.|."] = function(self, prompt, method)
    local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards)
	for _, card in ipairs(cards) do
		if card:getTypeId() == sgs.Card_TypeEquip and not self.player:isLocked(card) then
			local dummy_use = self:aiUseCard(card, dummy())
			if dummy_use.card then
				return dummy_use.card:toString()
			end
		end
	end
	return "."
end


--啖睛
local nos_sgkgoddanjing_skill = {}
nos_sgkgoddanjing_skill.name = "nos_sgkgoddanjing",
table.insert(sgs.ai_skills, nos_sgkgoddanjing_skill)
nos_sgkgoddanjing_skill.getTurnUseCard = function(self, inclusive)
    if #self.enemies == 0 and #self.friends_noself == 0 then return nil end
	if self.player:getHp() <= 2 then return nil end
    if self.player:hasUsed("#nos_sgkgoddanjingCard") then return nil end
	return sgs.Card_Parse("#nos_sgkgoddanjingCard:.:")
end

sgs.ai_skill_use_func["#nos_sgkgoddanjingCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_playerchosen["nos_sgkgoddanjing"] = function(self, targets)
    local players = {}
	for _, t in sgs.qlist(targets) do
	    if self:isFriend(t) then
		    table.insert(players, t)
		else
		    if self:isEnemy(t) and t:getHandcardNum() >= 1 and (not t:hasSkill("kongcheng")) then
			    table.insert(players, t)
			end
		end
	end
	self:sort(players, "defense")
	return players[1]
end

sgs.ai_skill_choice["nos_sgkgoddanjing"] = function(self, choices, data)
    local room = self.room
	local target
	for _, t in sgs.qlist(room:getOtherPlayers(self.player)) do
	    if t:getMark("danjing_AI") > 0 then
		    target = t
			break
		end
	end
	if self:isFriend(target) then
	    return "drawthree"
	else
	    return "throwthree"
	end
end

sgs.ai_use_value["nos_sgkgoddanjingCard"] = 8
sgs.ai_use_priority["nos_sgkgoddanjingCard"] = 8


--忠魂
sgs.ai_skill_playerchosen.nos_sgkgodzhonghun = function(self, targets)
    local zhonghun = {}
	for _, _target in sgs.qlist(targets) do
	    if self:isFriend(_target) then
		    table.insert(zhonghun, _target)
		end
	end
	if #zhonghun > 0 then
	    self:sort(zhonghun, "threat")
		return zhonghun[1]
	end
end

sgs.ai_skill_invoke["nos_sgkgodzhonghun"] = function(self, data)
    return #self.friends_noself > 0
end

local jlsgyanlie_skill = {}
jlsgyanlie_skill.name = "jlsgyanlie"
table.insert(sgs.ai_skills,jlsgyanlie_skill)
jlsgyanlie_skill.getTurnUseCard = function(self,inclusive)
	return sgs.Card_Parse("#jlsgyanlieCard:.:")
end

sgs.ai_skill_use_func["#jlsgyanlieCard"] = function(card,use,self)
	self:sort(self.enemies,"hp")
	local targets = {}
	local use_card = {}
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	for _,c in ipairs(cards)do
		if not c:isKindOf("Peach") and self.player:canDiscard(self.player,c:getEffectiveId()) and #use_card < #self.enemies then
			table.insert(use_card, c:getEffectiveId())
		end
	end
	if #use_card > 0 then
		local iron_chain = sgs.Sanguosha:cloneCard("iron_chain", sgs.Card_NoSuit, 0)
		iron_chain:setSkillName("jlsgyanlie")
		iron_chain:deleteLater()
		local dummy_use = self:aiUseCard(iron_chain, dummy(true, #use_card))
		if not dummy_use.to:isEmpty() then
			for _, p in sgs.qlist(dummy_use.to) do
				table.insert(targets,p)
			end
		end
		if #targets==0 then return end
		if #use_card > 0 then
			if #targets < #use_card then
				for _,enemy in ipairs(self.enemies)do
					if not enemy:isChained() and not enemy:hasSkill("qianjie") and self:isWeak(enemy) and self:damageIsEffective(enemy,sgs.DamageStruct_Fire) and not table.contains(targets, enemy) then
						table.insert(targets,enemy)
					end
				end
			end
			if #targets < #use_card then
				for _,enemy in ipairs(self.enemies)do
					if #targets>=#use_card then break end
					if self:isWeak(enemy) and self:damageIsEffective(enemy,sgs.DamageStruct_Fire) and not table.contains(targets, enemy) then
						table.insert(targets,enemy)
					end
				end
			end
			if #targets < #use_card then
				for _,enemy in ipairs(self.enemies)do
					if #targets>=#use_card then break end
					if self:damageIsEffective(enemy,sgs.DamageStruct_Fire) and not self:cantbeHurt(enemy) and not self:needToLoseHp(enemy) and not table.contains(targets, enemy) then
						table.insert(targets,enemy)
					end
				end
			end
			if #targets < #use_card then
				for i = 1,#use_card - #targets,1 do
					table.removeOne(use_card, use_card[#use_card])
				end
			end
			use.card = sgs.Card_Parse(string.format("#jlsgyanlieCard:%s:", table.concat(use_card, "+")))
			for i = 1,#targets,1 do
				use.to:append(targets[i])
				if use.to:length() >= #use_card then
					break
				end
			end
			return
		end
	end
end

sgs.ai_use_priority.jlsgyanlieCard = 3
sgs.ai_use_value.jlsgyanlieCard = 2.35
sgs.ai_card_intention.jlsgyanlieCard = 20

sgs.ai_skill_playerchosen.jlsgyanlie = function(self,targets)
	local to = self:findPlayerToDamage(1,self.player,"F",targets)[1]
	if to then return to end
	targets = sgs.QList2Table(targets)
	self:sort(targets,"hp")
	for _,p in ipairs(targets)do
		if not self:isEnemy(p) or not self:damageIsEffective(p,sgs.DamageStruct_Fire) then continue end
		return p
	end
	for _,p in ipairs(targets)do
		if self:isFriend(p) or not self:damageIsEffective(p,sgs.DamageStruct_Fire) then continue end
		return p
	end
	return targets[math.random(1,#targets)]
end


sgs.ai_target_revises.jlsglianti = function(to,card,self,use)
    if card:isKindOf("IronChain") then return true end
end
--神华佗
  --“归元”AI
local jlsgguiyuan_skill = {}
jlsgguiyuan_skill.name = "jlsgguiyuan"
table.insert(sgs.ai_skills, jlsgguiyuan_skill)
jlsgguiyuan_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#jlsgguiyuanCard") then return end
	return sgs.Card_Parse("#jlsgguiyuanCard:.:")
end

sgs.ai_skill_use_func["#jlsgguiyuanCard"] = function(card, use, self)
    if not self.player:hasUsed("#jlsgguiyuanCard") then
		local cansave = 1 - self.player:getHp()
		local mark = self.player:getMark("@jlsgchongsheng")
		if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") + mark >= cansave then
			use.card = card
			return
		end
	end
end

sgs.ai_use_value.jlsgguiyuanCard = 8.5
sgs.ai_use_priority.jlsgguiyuanCard = 9.5
sgs.ai_card_intention.jlsgguiyuanCard = -80

  --“重生”AI
sgs.ai_skill_invoke.jlsgchongsheng = function(self, data)
	local dying = data:toDying()
	if dying.who:objectName() == self.player:objectName() then
		local peaches = 1 - dying.who:getHp()
		return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
	else
		if self.player:getPile("jlsgyuanhua"):length() < 3 then return false end --无脑发动容易让别人变成1血魔将，直接帮倒忙
		return self:isFriend(dying.who)
	end
end

sgs.ai_skill_invoke["@jlsgchongsheng-generalChanged"] = true

sgs.ai_skill_invoke.new_sgkgodluezhen = function(self, data)
	local target = data:toCardUse().to:first()
	if target and self:isFriend(target) and not self:doDisCard(target, "he", true) then return false end
	return true
end
