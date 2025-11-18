--修罗
sgs.ai_skill_invoke.sy_xiuluo = function(self, data)
    local use = data:toCardUse()
	if not use.from then return false end
	if self:isFriend(use.from) then return false end
	if use.card:isKindOf("Duel") then return true end
	if use.card:isKindOf("Slash") or use.card:isNDTrick() then
		if use.from:hasSkills("tieji|liegong|mouliegongf|liegong|sr_benxi|fuqi|jiaozi|luoyi|wushuang") then return true end
		if self:getCardsNum("Slash") >= 2 or self.player:getHandcardNum() >= use.from:getHandcardNum() or use.from:getHandcardNum() - self.player:getHandcardNum() <= 2 then return true end
		if use.from:hasWeapon("axe") or use.card:hasFlag("drank") then return true end
	end
end

function sgs.ai_cardneed.sy_wushuang(to,card,self)
	if not self:willSkipPlayPhase(to) then
		return card:isDamageCard() and math.fmod(card:getNumber(), 2) ~= 0
	end
end

sgs.ai_ajustdamage_from.sy_hengxing = function(self,from,to,card,nature)
	if from:getPhase() ~= sgs.Player_Play
	then return 1 end
end

--凌虐
sgs.ai_skill_invoke.sy_lingnue = true
sgs.ai_suppress_intention["sy_baozheng"] = true

--忍忌
sgs.ai_skill_invoke.sy_renji = function(self, data)
	if self:needKongcheng(self.player, true) then return false end
	return true
end

--sgs.ai_skillInvoke_intention.sy_renji = 80
sgs.ai_can_damagehp.sy_renji = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end


--归命
sgs.ai_skill_invoke.sy_guiming = function(self, data)
	local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()
	return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
end

sgs.ai_canNiepan_skill.sy_guiming = function(player)
	return player:getMark("@guiming") > 0
end

sgs.ai_can_damagehp.sy_fangu = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to) and from and not self:isFriend(from)
end

--残掠
sgs.ai_skill_invoke.sy_canlue = function(self, data)
    local move = data:toMoveOneTime()
	if move and move.from and move.card_ids and move.card_ids:length() > 0 then
	    local from = self.room:findPlayerByObjectName(move.from:objectName())
		if from then return self:isEnemy(from) end
	end
	return
end


--乱政
sgs.ai_skill_playerchosen.sy_luanzheng = function(self, targets)
	local room = self.room
	local use = self.player:getTag("luanzheng_data"):toCardUse()
	if not use.from then return nil end
	local to = use.to:at(0)
	if use.card:isKindOf("Peach") then
		local friends = {}
		for _, t in sgs.qlist(targets) do
			if self:isFriend(t) and t:isWounded() then table.insert(friends, t) end
		end
		self:sort(friends, "chaofeng")
		return friends[1]
	elseif use.card:isKindOf("ExNihilo") then
		local tos = {}
		for _, t in sgs.qlist(targets) do
			if self:isFriend(t) and not self:needKongcheng(t, true) then
				table.insert(tos, t)
			end
		end
		self:sort(tos, "chaofeng")
		return tos[1]
	elseif use.card:isKindOf("Slash") then
		local tos = {}
		for _, t in sgs.qlist(targets) do
			if self:isEnemy(t) and (not to:hasSkills("leiji|guixin|sgkgodguixin|sgkgodyinshi")) then
				table.insert(tos, t)
			end
		end
		self:sort(tos, "chaofeng")
		return tos[1]
	else
		local tos = {}
		for _, t in sgs.qlist(targets) do
			if self:isEnemy(t) then
				table.insert(tos, t)
			end
		end
		self:sort(tos, "chaofeng")
		return tos[1]
	end
end

--恃傲
sgs.ai_skill_playerchosen.sy_shiao = function(self, targets)
	local tos = {}
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, p in sgs.qlist(targets) do
		if self:isEnemy(p) then
			if not sgs.Sanguosha:isProhibited(self.player, p, slash) and self:slashIsEffective(slash, p) and self:isGoodTarget(p, self.enemies, slash) then table.insert(tos, p) end
		end
	end
	if #tos > 0 then
		self:sort(tos, "defenseSlash")
		return tos[1]
	else
	    return nil
	end
	return nil
end

--狂袭
sgs.ai_skill_invoke.sy_kuangxi = function(self, data)
    local room = self.room
	local use = data:toCardUse()
	if not use.card then return false end
	if not use.card:isKindOf("TrickCard") then return false end
	local F = 0
	local E = 0
	if use.card:isKindOf("AmazingGrace") or use.card:isKindOf("GodSalvation") then
	    for _, p in sgs.qlist(use.to) do
		    if self:isFriend(p) then
			    F = F + 1
			end
			if self:isEnemy(p) then
			    E = E + 1
			end
		end
		if ((E - F >= 2) or (E > 0 and F <= 1)) and not self:isWeak() then return true else return false end
	end
	F = 0
	E = 0
	if use.card:isKindOf("IronChain") then
	    for _, p in sgs.qlist(use.to) do
		    if self:isFriend(p) then
			    F = F + 1
			end
			if self:isEnemy(p) then
			    E = E + 1
			end
		end
		if F == 0 and E > 0 then
		    if math.random(1, 5) > 3 then return true else return false end
		end
	end
	F = 0
	E = 0
	for _, p in sgs.qlist(use.to) do
		if self:isFriend(p) then
		    F = F + 1
		end
		if self:isEnemy(p) then
		    E = E + 1
		end
	end
	if F == 0 and E > 0 then
		if math.random(1, 100) >= 50 then return true else return false end
	end
	return false
end


-- -- --布教（旧）
-- -- sgs.ai_skill_cardask["@bujiao"] = function(self, data, pattern)
-- -- 	local cards = sgs.QList2Table(self.player:getHandcards())
-- -- 	self:sortByKeepValue(cards)
-- -- 	local zhangjiao = data:toPlayer()
-- -- 	local bujiaocard
-- -- 	if self:isEnemy(zhangjiao) or (not self:isFriend(zhangjiao))then
-- -- 		if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") == #cards then
-- -- 			bujiaocard = cards[math.random(1, #cards)]
-- -- 		else
-- -- 			local bc
-- -- 			for _, card in ipairs(cards) do
-- -- 				if (not card:isKindOf("Peach")) and (not card:isKindOf("Analeptic")) then
-- -- 					bc = card
-- -- 					break
-- -- 				end
-- -- 			end
-- -- 			bujiaocard = bc
-- -- 		end
-- -- 	else
-- -- 		if self:isFriend(zhangjiao) then
-- -- 			if (zhangjiao:containsTrick("SupplyShortage") or zhangjiao:containsTrick("Indulgence")) and self:getCardsNum("Nullification") > 0 then
-- -- 				for _, card in ipairs(cards) do
-- -- 					if card:isKindOf("Nullification") then
-- -- 						bujiaocard = card
-- -- 						break
-- -- 					end
-- -- 				end
-- -- 			end
-- -- 			if not bujiaocard then
-- -- 				if self:isWeak(zhangjiao) and (self:getCardsNum("Peach") > 0 or self:getCardsNum("Analeptic") > 0) then
-- -- 					for _, card in ipairs(cards) do
-- -- 						if card:isKindOf("Peach") or card:isKindOf("Analeptic") then
-- -- 							bujiaocard = card
-- -- 							break
-- -- 						end
-- -- 					end
-- -- 				end
-- -- 			end
-- -- 			if not bujiaocard then
-- -- 				if zhangjiao:hasSkills("jizhi|nosjizhi") then
-- -- 					for _, card in ipairs(cards) do
-- -- 						if card:isNDTrick() then
-- -- 							bujiaocard = card
-- -- 							break
-- -- 						end
-- -- 					end
-- -- 				end
-- -- 			end
-- -- 			if not bujiaocard then
-- -- 				if zhangjiao:hasSkills("qiangxi|sgkgodzhiji") then
-- -- 					for _, card in ipairs(cards) do
-- -- 						if card:isKindOf("Weapon") then
-- -- 							bujiaocard = card
-- -- 							break
-- -- 						end
-- -- 					end
-- -- 				end
-- -- 			end
-- -- 			if not bujiaocard then
-- -- 				bujiaocard = cards[math.random(1, #cards)]
-- -- 			end
-- -- 		end
-- -- 	end
-- -- 	if not bujiaocard then
-- -- 		bujiaocard = cards[math.random(1, #cards)]
-- -- 	end
-- -- 	return "$" .. bujiaocard:getEffectiveId()
-- -- end


--布教（新）
sgs.ai_skill_invoke.sy_bujiao = function(self, data)
	local to = data:toPlayer()
	if not self:isFriend(to) then return true end
	if self:isEnemy(to) and (not self:isWeak()) and self:objectiveLevel(to) >= 3 then
		return true
	end
	return false
end

--太平
sgs.ai_skill_invoke.sy_taiping = true


--妖惑
local sy_yaohuo_skill = {}
sy_yaohuo_skill.name = "sy_yaohuo"
table.insert(sgs.ai_skills, sy_yaohuo_skill)
sy_yaohuo_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sy_yaohuoCard") then return nil end
	if #self.enemies <= 0 then return nil end
	if self.player:isKongcheng() then return nil end
	return sgs.Card_Parse("#sy_yaohuoCard:.:")
end

sgs.ai_skill_use_func["#sy_yaohuoCard"] = function(card, use, self)
	if self.player:hasUsed("#sy_yaohuoCard") then return nil end
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)
	local target
	local a = self.player:getHandcardNum() + self.player:getEquips():length()
	local b = -999
	local less = {}
	for _, k in ipairs(self.enemies) do
	    if k:getHandcardNum() <= a and not k:isKongcheng() then table.insert(less, k) end
	end
	for _, m in ipairs(less) do
		b = math.max(b, m:getHandcardNum())
	end
	for _, enemy in ipairs(self.enemies) do
	    if enemy:getHandcardNum() == b then
		    target = enemy
		    break
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if a < b then
			    if a > enemy:getHandcardNum() and (not enemy:isKongcheng()) and a - enemy:getHandcardNum() <= 2 then
				    target = enemy
					break
				end
			end
		end
	end
	if not target then
		local c = -999
		local less_skill_num = {}
		for _, enemy in ipairs(self.enemies) do
			if enemy:getVisibleSkillList():length() <= a then
				local has_bad = false
				for _, sk in sgs.qlist(enemy:getVisibleSkillList()) do
					if string.find(sgs.bad_skills, sk:objectName()) then
						has_bad = true
						break
					end
				end
				if not has_bad then table.insert(less_skill_num, enemy) end
			end
		end
		for _, m in ipairs(less_skill_num) do
			c = math.max(c, m:getVisibleSkillList():length())
		end
		for _, enemy in ipairs(self.enemies) do
			if enemy:getVisibleSkillList():length() == c then
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


sgs.ai_skill_choice.sy_yaohuo = function(self, choices, data)
    local n = math.random(1, 100)
	local yaohuo = choices:split("+")
	if n >= 1 and n <= 50 then
	    return yaohuo[1]
	else
	    return yaohuo[2]
	end
end

sgs.ai_use_value["sy_yaohuoCard"] = 10
sgs.ai_use_priority["sy_yaohuoCard"] = 9.3
sgs.ai_card_intention["sy_yaohuoCard"] = 90


--三治
sgs.ai_skill_invoke.sy_sanzhi = true



--醉酒
local sy_zuijiu_skill = {}
sy_zuijiu_skill.name = "sy_zuijiu"
table.insert(sgs.ai_skills, sy_zuijiu_skill)
sy_zuijiu_skill.getTurnUseCard = function(self, inclusive)
	if self:isWeak() then return nil end
	if #self.enemies == 0 then return nil end
	local E = 0
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	for _, enemy in ipairs(self.enemies) do
		if not sgs.Sanguosha:isProhibited(self.player, enemy, slash) then E = E + 1 end
	end
	if E == 0 then return nil end
	if self.player:getHandcardNum() - self.player:getMark("&sy_zuijiu") <= 2 then return nil end
	return sgs.Card_Parse("#sy_zuijiuCard:.:")
end

sgs.ai_skill_use_func["#sy_zuijiuCard"] = function(card, use, self)
	use.card = card
end

sgs.ai_skill_use["@@sy_zuijiuNormalSlash"] = function(self, prompt)
	if #self.enemies == 0 then return "." end
	self:sort(self.enemies, "defense")
	local slash = sgs.Sanguosha:cloneCard("slash", sgs.Card_NoSuit, 0)
	slash:deleteLater()
	local target
	for _, enemy in ipairs(self.enemies) do
		if not sgs.Sanguosha:isProhibited(self.player, enemy, slash) and self:slashIsEffective(slash, enemy) and self:isGoodTarget(enemy, self.enemies, nil) then
			target = enemy
			break
		end
	end
	if not target then target = self:findPlayerToSlash(false) end
	return "#sy_zuijiuNormalSlashCard:.:->" .. target:objectName()
end


--荒淫
sgs.ai_skill_invoke.sy_huangyin = function(self, data)
    if self:needKongcheng(self.player, true) then return false end
	return true
end


--乱嗣
local sy_luansi_skill = {}
sy_luansi_skill.name = "sy_luansi"
table.insert(sgs.ai_skills, sy_luansi_skill)
sy_luansi_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sy_luansiCard") then return nil end
	if #self.enemies == 0 then return nil end
	local j = 0
	for _, p in ipairs(self.enemies) do
	    if (not p:isKongcheng()) then j = j + 1 end
	end
	if j < 1 then return nil end
	return sgs.Card_Parse("#sy_luansiCard:.:")
end

sgs.ai_skill_use_func["#sy_luansiCard"] = function(card, use, self)
    if self.player:hasUsed("#sy_luansiCard") then return nil end
	self:sort(self.enemies, "defense")
	local tar1, tar2
	for _, p in ipairs(self.enemies) do
	    if not p:isKongcheng() then
		    tar1 = p
			break
		end
	end
	if not tar2 then
		for _, m in ipairs(self.enemies) do
			if m:objectName() ~= tar1:objectName() and (not m:isKongcheng()) then
				tar2 = m
				break
			end
		end
	end
	if not tar2 then
		tar2 = self.player
	end
	if tar1 and tar2 then
	    use.card = card
		if use.to then
		    use.to:append(tar1)
			use.to:append(tar2)
		end
	else
	    return nil
	end
end

sgs.ai_use_value["sy_luansiCard"] = 10
sgs.ai_use_priority["sy_luansiCard"] = 8.5
sgs.ai_card_intention["sy_luansiCard"] = 0



--诋毁
local sy_dihui_skill = {}
sy_dihui_skill.name = "sy_dihui"
table.insert(sgs.ai_skills, sy_dihui_skill)
sy_dihui_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sy_dihuiCard") then return nil end
	if #self.enemies <= 0 then return nil end
	if self.player:getHp() <= 0 then return nil end
	return sgs.Card_Parse("#sy_dihuiCard:.:")
end

sgs.ai_skill_use_func["#sy_dihuiCard"] = function(card, use, self)
	if self.player:hasUsed("#sy_dihuiCard") then return nil end
	local room = self.room
	local no_min_hp = {}
	local _minhp = 99999
	local players = room:getOtherPlayers(self.player)
	for _, p in sgs.qlist(room:getOtherPlayers(self.player)) do
	    _minhp = math.min(_minhp, p:getHp())
	end
	for _, t in sgs.qlist(room:getOtherPlayers(self.player)) do
	    if t:getHp() > _minhp then
		    table.insert(no_min_hp, t)
		end
	end
	local target1
	if #no_min_hp == 0 then return nil end
	self:sort(no_min_hp, "chaofeng")
	for _, _min in ipairs(no_min_hp) do
		if self:isFriend(_min) then
			target1 = _min
			break
		end
	end
	if not target1 then
		for _, _to in ipairs(no_min_hp) do
			if self:isEnemy(_to) then
				target1 = _to
				break
			end
		end
	end
	if not target1 then
		target1 = self.player
	end
	if target1 then
	    use.card = card
		if use.to then
		    use.to:append(target1)
		end
	end
end

sgs.ai_skill_playerchosen.sy_dihui = function(self, targets)
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


sgs.ai_use_value["sy_dihuiCard"] = 9
sgs.ai_use_priority["sy_dihuiCard"] = 7

sgs.ai_damage_reason_suppress_intention["sy_dihui"] = true


--谗陷
function canMoveCard(target)
	if not target:isKongcheng() then return true end
	local others = target:getAliveSiblings()
	local tos = sgs.PlayerList()
	if target:getJudgingArea():length() > 0 then
		for _, card in sgs.qlist(target:getJudgingArea()) do
			for _, pe in sgs.qlist(others) do
				if not target:isProhibited(pe, card) and not pe:containsTrick(card:objectName()) and (not tos:contains(pe)) then
					tos:append(pe)
				end
			end
		end
	end
	if target:hasEquip() then
		for _, card in sgs.qlist(target:getEquips()) do
			local equip = card:getRealCard():toEquipCard()
			local index = equip:location()
			for _, pe in sgs.qlist(others) do
				if pe:getEquip(index) == nil and pe:hasEquipArea(index) and (not tos:contains(pe)) then
					tos:append(pe)
				end
			end
		end
	end
	if tos:isEmpty() then return false else return true end
end

local sy_chanxian_skill = {}
sy_chanxian_skill.name = "sy_chanxian"
table.insert(sgs.ai_skills, sy_chanxian_skill)
sy_chanxian_skill.getTurnUseCard = function(self, inclusive)
    if self.player:hasUsed("#sy_chanxianCard") then return nil end
	local can_move = {}
	for _, pe in sgs.qlist(self.room:getAlivePlayers()) do
		if canMoveCard(pe) then table.insert(can_move, pe) end
	end
	if #can_move == 0 or #self.enemies == 0 then return nil end
	return sgs.Card_Parse("#sy_chanxianCard:.:")
end

sgs.ai_skill_use_func["#sy_chanxianCard"] = function(card, use, self)
	local target
	local can_move = {}
	for _, pe in sgs.qlist(self.room:getAlivePlayers()) do
		if canMoveCard(pe) then table.insert(can_move, pe) end
	end
	if #can_move == 0 then return nil end
	self:sort(can_move, "defenseSlash")
	for _, pe in ipairs(can_move) do
		if self:isEnemy(pe) then
			target = pe
			break
		end
	end
	if not target then
		target = can_move[1]
	end
	if target then
	    use.card = card
		if use.to then use.to:append(target) end
	end
end

sgs.ai_skill_playerchosen.sy_chanxian = function(self, targets)
    local move_to = {}
	for _, ap in sgs.qlist(targets) do
	    if self:isEnemy(ap) or self.player:getSeat() == ap:getSeat() then
			table.insert(move_to, ap)
		end
	end
	self:sort(move_to, "hp")
	local target
	for _, to in ipairs(move_to) do
		if self:isEnemy(to) then
			target = to
			break
		end
	end
	if not target then
		for _, to in ipairs(move_to) do
			if self.player:getSeat() == to:getSeat() then
				target = to
				break
			end
		end
	end
	if not target then
		target = move_to[1]
	end
	return target
end


sgs.ai_use_value["sy_chanxianCard"] = 6
sgs.ai_use_priority["sy_chanxianCard"] = 0

sgs.ai_suppress_intention["sy_chanxian"] = true

--吕布重铸武器
function canShenji(lvbu)
    if lvbu:getGeneral() and lvbu:getGeneralName() == "sy_lvbu1" then return true end
    if lvbu:getGeneral() and lvbu:getGeneralName() == "sy_lvbu2" then return true end
    if lvbu:getGeneral2() and lvbu:getGeneral2Name() == "sy_lvbu1" then return true end
    if lvbu:getGeneral2() and lvbu:getGeneral2Name() == "sy_lvbu2" then return true end
	if lvbu:hasSkills("shenji|sy_shenji") then return true end
	return false
end


sgs.ai_skill_invoke["#W_recast"] = function(self, data)
	for _, skill in sgs.qlist(self.player:getVisibleSkillList()) do
		if string.find(skill:objectName(), "xuanfeng") then return false end
	end
	local card_use = data:toCardUse()
	local card = card_use.card
	if card and card:isKindOf("DefensiveHorse") then
		if not self.player:getDefensiveHorse() then
			return false
		else
			if math.random(1, 100) <= 50 then return true else return false end
		end
	end
	if card and card:isKindOf("OffensiveHorse") then
		if not self.player:getOffensiveHorse() then
			return false
		else
			if math.random(1, 100) <= 50 then return true else return false end
		end
	end
	if not self.player:getWeapon() then
		if canShenji(self.player) then
			if not card:isKindOf("Crossbow") then
				return true
			else
				return false
			end
		else
			return false
		end
	else
		if self:doDisCard(self.player, self.player:getWeapon():getEffectiveId()) then return false end
		if not card:isKindOf("Crossbow") then
			if canShenji(self.player) then
				return true
			else
				if math.random(1, 100) <= 75 then return true else return false end
			end
		else
			return false
		end
	end
	return false
end


-- --嗜杀
-- sgs.ai_skill_discard.sy_shisha = function(self, discard_num, min_num, optional, include_equip)
--     local to_discard = {}
-- 	local sunhao
-- 	if self.room:findPlayerBySkillName("sy_shisha") then sunhao = self.room:findPlayerBySkillName("sy_shisha") end
-- 	if sunhao and self:needToLoseHp(self.player, sunhao) then return to_discard end
-- 	local n = math.random(1, 100)
-- 	if self.player:getHp() >= 3 or self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then
-- 	    if n <= 95 then
-- 		    return to_discard
-- 		else
-- 		    local cards = sgs.QList2Table(self.player:getCards("he"))
-- 			self:sortByKeepValue(cards)
-- 			local index = 0
-- 			for i = #cards, 1, -1 do
-- 			    local card = cards[i]
-- 				if (not isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and (not self.player:isJilei(card)) then
-- 				    table.insert(to_discard, card:getEffectiveId())
-- 			        table.remove(cards, i)
-- 			        index = index + 1
-- 			        if index == 2 then break end
-- 		        end
-- 			end
-- 			if #to_discard < 2 then return {}
-- 			else return to_discard end
-- 		end
-- 	else
-- 	    local cards = sgs.QList2Table(self.player:getCards("he"))
-- 		self:sortByKeepValue(cards, true)
-- 		local index = 0
-- 		for i = #cards, 1, -1 do
-- 		    local card = cards[i]
-- 			if not (isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and not self.player:isJilei(card) then
-- 			    table.insert(to_discard, card:getEffectiveId())
-- 		        table.remove(cards, i)
-- 		        index = index + 1
-- 		        if index == 2 then break end
-- 	        end
-- 		end
-- 		if #to_discard < 2 then return {}
-- 		else return to_discard end
-- 	end
-- end


--祸心
sgs.ai_skill_choice["sy_huoxin"] = function(self, choices, data)
    local huoxin = choices:split("+")
	local caifuren = self.room:findPlayerBySkillName("sy_huoxin")
	if self:isFriend(caifuren) then
	    return huoxin[1]
	else
	    return huoxin[math.random(1, #huoxin)]
	end
end

sgs.ai_ajustdamage_from.sy_zhuzai = function(self,from,to,card,nature)
	if card and card:isKindOf("TrickCard")
	then return 1 end
end

sgs.ai_ajustdamage_to.sy_zhuzai = function(self,from,to,card,nature)
	if card and card:isKindOf("TrickCard")
	then return -1 end
end

--制衡
local sy_zhiheng_skill = {}
sy_zhiheng_skill.name = "sy_zhiheng"
table.insert(sgs.ai_skills, sy_zhiheng_skill)
sy_zhiheng_skill.getTurnUseCard = function(self)
	if not self.player:hasUsed("#sy_zhiheng") then
		return sgs.Card_Parse("#sy_zhiheng:.:")
	end
end

sgs.ai_skill_use_func["#sy_zhiheng"] = function(card, use, self)
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
					local dummy_use = { isDummy = true , to = sgs.SPlayerList()}
					self:useBasicCard(zcard, dummy_use)
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
					local dummy_use = { isDummy = true }
					self:useTrickCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					local dummy_use = { isDummy = true }
					self:useEquipCard(zcard, dummy_use)
					if dummy_use.card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if self.player:hasEquip(zcard) and zcard:isKindOf("Armor") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("DefensiveHorse") and not self:needToThrowArmor() then shouldUse = false end
				if self.player:hasEquip(zcard) and zcard:isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then shouldUse = false end
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
					local dummy_use = { isDummy = true }
					self:useBasicCard(card, dummy_use)
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
				local dummy_use = { isDummy = true }
				self:useTrickCard(card, dummy_use)
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

	for index = #unpreferedCards, 1, -1 do
		if sgs.Sanguosha:getCard(unpreferedCards[index]):isKindOf("WoodenOx") and self.player:getPile("wooden_ox"):length() > 1 then
			table.removeOne(unpreferedCards, unpreferedCards[index])
		end
	end

	local use_cards = {}
	for index = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[index])) then table.insert(use_cards, unpreferedCards[index]) end
	end

	if #use_cards > 0 then
		use.card = sgs.Card_Parse("#sy_zhiheng:" .. table.concat(use_cards, "+") .. ":")
		return
	end
end

sgs.ai_use_value["sy_zhiheng"] = sgs.ai_use_value.ZhihengCard
sgs.ai_use_priority["sy_zhiheng"] = sgs.ai_use_priority.ZhihengCard
sgs.dynamic_value.benefit["sy_zhiheng"] = sgs.dynamic_value.benefit.ZhihengCard

function sgs.ai_cardneed.sy_zhiheng(to, card)
	return not card:isKindOf("Jink")
end


--终章
function countJuewangSkills(target)
	local n = 0
	if target:hasSkill("jw_chunbai") then n = n + 1 end
	if target:hasSkill("jw_heiyang") then n = n + 1 end
	if target:hasSkill("jw_shenchao") then n = n + 1 end
	if target:hasSkill("jw_shenglang") then n = n + 1 end
	if target:hasSkill("jw_ruanruo") then n = n + 1 end
	if target:hasSkill("jw_canmeng") then n = n + 1 end
	return n
end

local sy_zhongzhang_skill = {}
sy_zhongzhang_skill.name = "sy_zhongzhang"
table.insert(sgs.ai_skills, sy_zhongzhang_skill)
sy_zhongzhang_skill.getTurnUseCard = function(self)
    if self.player:hasUsed("#sy_zhongzhang") then return nil end
	return sgs.Card_Parse("#sy_zhongzhang:.:")
end

sgs.ai_skill_use_func["#sy_zhongzhang"] = function(card, use, self)
    self:sort(self.enemies, "defense")
	local target
	for _, enemy in ipairs(self.enemies) do
	    if self:objectiveLevel(enemy) >= 3 and countJuewangSkills(enemy) < 3 then
		    target = enemy
			break
		end
	end
	if not target then
	    for _, enemy in ipairs(self.enemies) do
		    if countJuewangSkills(enemy) == 0 and (not self:isWeak()) then
			    target = enemy
				break
			end
		end
	end
	if not target then
		target = self.player
	end
	if target then
	    use.card = card
		if use.to then use.to:append(target) end
	end
end


sgs.ai_use_value["sy_zhongzhang"] = 10
sgs.ai_use_priority["sy_zhongzhang"] = sgs.ai_use_priority.ExNihilo - 0.2
sgs.ai_card_intention["sy_zhongzhang"] = 100


--消失
sgs.ai_skill_invoke.sy_xiaoshi = function(self, data)
	local dying = data:toDying()
	local peaches = 1 - dying.who:getHp()
	if self.player:getMark("@xiaoshi") > 0 then
		return self:getCardsNum("Peach") + self:getCardsNum("Analeptic") < peaches
	end
	return false
end

sgs.ai_canNiepan_skill.sy_xiaoshi = function(player)
	return player:getMark("@xiaoshi") > 0
end

sgs.ai_skill_cardask["@xiaoshiask"] = function(self, data)
	local miku = data:toPlayer()
	if self:isFriend(miku) then return "." end
end

sgs.ai_skill_invoke.sy_beiyuan = function(self, data)
	local damage = data:toDamage()
	if self:isFriend(damage.from) then
		return false
	end
	return true
end

sgs.ai_can_damagehp.sy_beiyuan = function(self,from,card,to)
	if from and to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
	then
		return self:isEnemy(from)
	end
end

sgs.ai_skill_invoke.sy_jiancheng = true


sgs.ai_skill_cardask["@jiancheng-discard"] = function(self,data, pattern)
	local target = data:toPlayer()
	if self:isFriend(target) then return "." end
	local cards = self.player:getCards("he")
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	for _,h in sgs.list(cards)do
		if sgs.Sanguosha:matchExpPattern(pattern,self.player,h)
		then return h:getEffectiveId() end
		if h:getSuitString() == pattern:split("|")[2]
		then return h:getEffectiveId() end
	end
	return "."
end

sgs.ai_ajustdamage_from.sy_baodao = function(self,from,to,slash,nature)
	if slash and slash:isKindOf("Slash") and to:isKongcheng()
	then return 1 end
end


--虚数
sgs.ai_skill_playerchosen.sy_xushu = function(self, targets)
    self:sort(self.enemies, "defense") 
	for _,enemy in ipairs(self.enemies) do
		if enemy then
			return enemy
		end
	end
	return self.enemies[1]
end


--吸收
sgs.ai_skill_invoke.sy_xishou = true


--操影
sgs.ai_skill_invoke.sy_caoying = function(self, data)
    local target
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
	    if p:getMark("caoying_AI") > 0 then
		    target = p
			break
		end
	end
	return self:isEnemy(target) and self:doDisCard(target, "he")
end


--黑·约束胜利之剑
sgs.ai_skill_invoke.sy_shengjian_black = function(self, data)
    return #self.enemies > 0
end

sgs.ai_skill_playerchosen.sy_shengjian_black = function(self, targets)
    self:sort(self.enemies, "defense")
	local enemies = {}
	for _, enemy in ipairs(self.enemies) do
	    if math.abs(self.player:getEquips():length() - enemy:getEquips():length()) > 0 then
		    table.insert(enemies, enemy)
		end
	end
	if #enemies > 0 then
	    return enemies[1]
	else
	    return self.enemies[1]
	end
end


--风斩
sgs.ai_skill_invoke.sy_fengzhan = function(self, data)
    return #self.enemies > 0
end

sgs.ai_skill_playerchosen.sy_fengzhan = function(self, targets)
    self:updatePlayers()
	self:sort(self.enemies)
	local target
	for _, enemy in ipairs(self.enemies) do
	    if enemy then
		    target = enemy
		    break
		end
	end
	if target then
	    return target
	else
	    return nil
	end
end

sgs.ai_skill_use["@@sy_baofeng"] = function(self, prompt)
	local cardToUse
	for _,card in sgs.list(self.player:getHandcards()) do
		if card:isKindOf("Slash") then
			cardToUse = card
		end
	end
	if cardToUse then
		local enemytargets = {}
		for _, enemy in ipairs(self.enemies) do
			if  (self:objectiveLevel(enemy) >= 3) 
				and not self:needToLoseHp(enemy) and self:isGoodTarget(enemy, self.enemies, nil) 
				and #enemytargets < 2  then
				table.insert(enemytargets, enemy:objectName())
			end
		end
		if #enemytargets > 1 then
			return "#sy_baofengCard:".. cardToUse:getEffectiveId() ..":->" .. table.concat(enemytargets, "+")
		end
	end
end



--无鞘
sgs.ai_skill_invoke.sy_wuqiao = function(self, data)
    local use = data:toCardUse()
	if use.to:contains(self.player) and use.from then
	    return self:isEnemy(use.from)
	end
	local damage = data:toDamage()
	if damage.from:objectName() == self.player:objectName() then
	    return self:isEnemy(damage.to)
	end
end


--风影
sgs.ai_skill_invoke.sy_fengying = true

sgs.ai_ajustdamage_to.sy_fengying = function(self, from, to, card, nature)
	if from and from:distanceTo(to) > 1
	then
		return -99
	end
end

--真·狂风绝息斩
sgs.ai_skill_invoke.sy_juexi = function(self, data)
    local targets = {}
	for _, enemy in ipairs(self.enemies) do
	    if (not enemy:faceUp()) and enemy:getMark("@fiercewind") > 0 then
		    table.insert(targets, enemy)
		end
	end
	return #targets > 0
end


--青钢
sgs.ai_skill_invoke.sy_qinggang = function(self, data)
	local damage = data:toDamage()
	return self:isEnemy(damage.to)
end

sgs.ai_skill_discard.sy_qinggang = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
	local zhaoyun
	if self.room:findPlayerBySkillName("sy_qinggang") then zhaoyun = self.room:findPlayerBySkillName("sy_qinggang") end
	if zhaoyun and self:needToLoseHp(self.player, zhaoyun) then return to_discard end
	local n = math.random(1, 100)
	if self.player:hasFlag("qinggang_AI") then
		if self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then
			if n <= 95 then
				return to_discard
			else
				local cards = sgs.QList2Table(self.player:getCards("h"))
				self:sortByKeepValue(cards)
				local index = 0
				for i = #cards, 1, -1 do
					local card = cards[i]
					if (not isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and (not self.player:isJilei(card)) then
						table.insert(to_discard, card:getEffectiveId())
						table.remove(cards, i)
						index = index + 1
						if index == 1 then break end
					end
				end
				if #to_discard < 1 then return {}
				else return to_discard end
			end
		else
			if math.random(1, 100) <= 30 then return to_discard end
			local cards = sgs.QList2Table(self.player:getCards("h"))
			self:sortByKeepValue(cards, true)
			local index = 0
			for i = #cards, 1, -1 do
				local card = cards[i]
				if not (isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and not self.player:isJilei(card) then
					table.insert(to_discard, card:getEffectiveId())
					table.remove(cards, i)
					index = index + 1
					if index == 1 then break end
				end
			end
			if #to_discard < 1 then return {}
			else return to_discard end
		end
	end
end


--龙怒
local sy_longnu_skill = {}
sy_longnu_skill.name = "sy_longnu"
table.insert(sgs.ai_skills, sy_longnu_skill)
sy_longnu_skill.getTurnUseCard = function(self, inclusive)
	local angers = self.player:getPile("Angers")
	local first_found, second_found = false, false
	local first_card, second_card
	if angers:length() >= 2 then
		--local same_suit = false
		for _, id1 in sgs.qlist(angers) do
			local cd1 = sgs.Sanguosha:getCard(id1)
			if cd1:isBlack() then
				first_card = cd1
				first_found = true
				for _, id2 in sgs.qlist(angers) do
					local cd2 = sgs.Sanguosha:getCard(id2)
					if first_card:getEffectiveId() ~= cd2:getEffectiveId() and cd2:getSuitString() == first_card:getSuitString() then
						second_card = cd2
						second_found = true
						break
					end
				end
				if second_card then break end
			end
		end
	end
	if first_found and second_found and (self:getCardsNum("Slash") > 0 or self:getCardsNum("Jink") > 0) and (not self.player:hasUsed("Slash")) and (not self.player:hasUsed("#sy_longnuCard")) then
		local first_id = first_card:getEffectiveId()
		local second_id = second_card:getEffectiveId()
		return sgs.Card_Parse("#sy_longnuCard:" .. first_id .. "+" .. second_id .. ":")
	end
end

sgs.ai_skill_use_func["#sy_longnuCard"] = function(card, use, self)
	use.card = card
end


sgs.ai_use_value["sy_longnuCard"] = 5.98
sgs.ai_use_priority["sy_longnuCard"] = 2.7

sgs.ai_canliegong_skill.sy_longnu = function(self, from, to)
	return from:getMark("longnu_nojink") > 0
end

--浴血
local sy_yuxue_skill = {}
sy_yuxue_skill.name = "sy_yuxue"
table.insert(sgs.ai_skills, sy_yuxue_skill)
sy_yuxue_skill.getTurnUseCard = function(self)
	local angers = self.player:getPile("Angers")
	local redangers = sgs.IntList()
	for _,id in sgs.qlist(angers) do
		local cd = sgs.Sanguosha:getCard(id)
		if cd:isRed() then
			redangers:append(id)
		end
	end
	if redangers:isEmpty() or (not self.player:isWounded()) then return nil end
	local card = sgs.Sanguosha:getCard(redangers:first())
	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("peach:sy_yuxue[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

function sgs.ai_cardsview.sy_yuxue(class_name, player)
	if class_name == "Peach" then
		if player:hasSkill("sy_yuxue") and not player:getPile("Angers"):isEmpty() then
			return sy_yuxue_skill.getTurnUseCard
		end
	end
end

sgs.ai_view_as.sy_yuxue = function(card, player, card_place)
	local angers = player:getPile("Angers")
	local redangers = sgs.IntList()
	for _,id in sgs.qlist(angers) do
		local cd = sgs.Sanguosha:getCard(id)
		if cd:isRed() then
			redangers:append(id)
		end
	end
	if redangers:isEmpty() then return nil end
	
	local card = sgs.Sanguosha:getCard(redangers:first())
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	return ("peach:sy_yuxue[%s:%s]=%d"):format(suit, number, card_id)
end


--龙吟
sgs.ai_skill_invoke.sy_longyin = true

sgs.ai_skill_askforag.sy_longyin = function(self, card_ids)
	local angers = self.player:getPile("Angers")
	local redAngers, blackAngers = sgs.IntList(), sgs.IntList()
	for _, id in sgs.list(card_ids) do
		local cd = sgs.Sanguosha:getCard(id)
		if cd:isRed() then
			redAngers:append(id)
		else
			blackAngers:append(id)
		end
	end
	local has_redAngers, has_blackAngers = sgs.IntList(), sgs.IntList()
	for _, id in sgs.list(angers) do
		local cd = sgs.Sanguosha:getCard(id)
		if cd:isRed() and not (cd:inherits("Peach") and cd:inherits("ExNihilo")) then
			has_redAngers:append(id)
		elseif cd:isBlack() and not cd:inherits("Analeptic") then
			has_blackAngers:append(id)
		end
	end
	if has_redAngers:length() >= has_blackAngers:length() then
		self.sy_longyin = redAngers:first()
	else
		self.sy_longyin = blackAngers:first()
	end
	
	return self.sy_longyin
end

--备粮
sgs.ai_skill_invoke.sy_beiliang = function(self, data)
	if self.player:getCards("h"):length() <= 2 then
		return true
	end
	return false
end

--聚武
local sy_juwu_skill = {}
sy_juwu_skill.name = "sy_juwu"
table.insert(sgs.ai_skills, sy_juwu_skill)
sy_juwu_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return nil end
	local sy_zhaoyun = false
	for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if (string.find(t:getGeneralName(), "sy_zhaoyun1") or string.find(t:getGeneral2Name(), "sy_zhaoyun1")) and self:isFriend(t) then
			sy_zhaoyun = t
			break
		end
	end
	if not sy_zhaoyun then
		for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if (string.find(t:getGeneralName(), "sy_zhaoyun2") or string.find(t:getGeneral2Name(), "sy_zhaoyun2")) and self:isFriend(t) then
				sy_zhaoyun = t
				break
			end
		end
	end
	if not sy_zhaoyun then return nil end
	if (not sy_zhaoyun:containsTrick("supply_shortage") or not sy_zhaoyun:containsTrick("indulgence")) and sy_zhaoyun:faceUp() then
		return sgs.Card_Parse("#sy_juwuCard:.:")
	end
	if (self.player:usedTimes("#sy_juwuCard") < 1 or self:getOverflow() > 0) and (not self:isWeak()) and self.player:getMark("juwu_given") < self.player:getHp() then
		return sgs.Card_Parse("#sy_juwuCard:.:")
	end	
end

sgs.ai_skill_use_func["#sy_juwuCard"] = function(card, use, self)
	local danger = false
	if self.player:getHandcardNum() == 1 then
		for _, enemy in ipairs(self.enemies) do
			if enemy:getWeapon() == "guding_blade" and enemy:canSlash(self.player, true) then
				danger = true
				break
			end
		end
	end
	if danger then return nil end
	local cards = sgs.QList2Table(self.player:getHandcards())
	self:sortByUseValue(cards, true)
	local sy_zhaoyun = false
	for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if (string.find(t:getGeneralName(), "sy_zhaoyun1") or string.find(t:getGeneral2Name(), "sy_zhaoyun1")) and self:isFriend(t) then
			sy_zhaoyun = t
			break
		end
	end
	if not sy_zhaoyun then
		for _, t in sgs.qlist(self.room:getOtherPlayers(self.player)) do
			if (string.find(t:getGeneralName(), "sy_zhaoyun2") or string.find(t:getGeneral2Name(), "sy_zhaoyun2")) and self:isFriend(t) then
				sy_zhaoyun = t
				break
			end
		end
	end
	local card = self:getCardNeedPlayer(cards)
	if card and sy_zhaoyun then
		use.card = sgs.Card_Parse("#sy_juwuCard:" .. card:getId())
		if use.to then use.to:append(sy_zhaoyun) end
		return
	end
	if self:getOverflow()>0 then
		local card_id = self:getCardRandomly(self.player, "h")
		use.card = sgs.Card_Parse("#sy_juwuCard:" .. card_id)
		if use.to then use.to:append(sy_zhaoyun) end
		return
	end
end


sgs.ai_use_value["sy_juwuCard"] = 8.5
sgs.ai_use_priority["sy_juwuCard"] = 5.8
sgs.ai_card_intention["sy_juwuCard"] = -70
sgs.dynamic_value.benefit["sy_juwuCard"] = true


--弑神
local sy_shishen_skill = {}
sy_shishen_skill.name = "sy_shishen"
table.insert(sgs.ai_skills, sy_shishen_skill)
sy_shishen_skill.getTurnUseCard = function(self)
	local angers = self.player:getPile("Angers")
	local first_found, second_found = false, false
	local first_card, second_card
	if angers:length() >= 2 then
		local same_color = false
		for _, id1 in sgs.qlist(angers) do
			local cd1 = sgs.Sanguosha:getCard(id1)
			if cd1:isBlack() then
				first_card = cd1
				first_found = true
				for _, id2 in sgs.qlist(angers) do
					local cd2 = sgs.Sanguosha:getCard(id2)
					if first_card:getEffectiveId() ~= cd2:getEffectiveId() and first_card:sameColorWith(cd2) then
						second_card = cd2
						second_found = true
						break
					end
				end
				if second_card then break end
			end
		end
	end
	if first_found and second_found then
		local sy_shishenCard = {}
		local first_id = first_card:getEffectiveId()
		local second_id = second_card:getEffectiveId()
		return sgs.Card_Parse("#sy_shishenCard:" .. first_id .. "+" .. second_id .. ":")
	end
end

sgs.ai_skill_use_func["#sy_shishenCard"] = function(card, use, self)
	self:sort(self.enemies, "hp")
	for _, enemy in ipairs(self.enemies) do
		use.card = card
		if use.to then use.to:append(enemy) end
		return
	end
end


--缠蛇
local sy_chanshe_skill = {}
sy_chanshe_skill.name = "sy_chanshe"
table.insert(sgs.ai_skills, sy_chanshe_skill)
sy_chanshe_skill.getTurnUseCard = function(self)
	local angers = self.player:getPile("Angers")
	local redangers = sgs.IntList()
	for _,id in sgs.qlist(angers) do
		local cd = sgs.Sanguosha:getCard(id)
		if cd:getSuit() == sgs.Card_Diamond then
			redangers:append(id)
		end
	end
	if redangers:isEmpty() then return nil end
	local card = sgs.Sanguosha:getCard(redangers:first())
	if not card then return nil end
	local suit = card:getSuitString()
	local number = card:getNumberString()
	local card_id = card:getEffectiveId()
	local card_str = ("indulgence:sy_chanshe[%s:%s]=%d"):format(suit, number, card_id)
	local skillcard = sgs.Card_Parse(card_str)
	assert(skillcard)
	return skillcard
end

--鬼刃
sgs.ai_skill_invoke.sy_guiren = true


--阴兵
sgs.ai_skill_invoke.sy_yinbing = true