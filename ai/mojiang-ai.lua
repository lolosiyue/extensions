
--嗜杀
sgs.ai_skill_discard.sy_old_shisha = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
	local sunhao
	if self.room:findPlayerBySkillName("sy_shisha") then sunhao = self.room:findPlayerBySkillName("sy_shisha") end
	if sunhao and self:needToLoseHp(self.player, sunhao) then return to_discard end
	local n = math.random(1, 100)
	if self.player:getHp() >= 3 or self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then
	    if n <= 95 then
		    return to_discard
		else
		    local cards = sgs.QList2Table(self.player:getCards("he"))
			self:sortByKeepValue(cards)
			local index = 0
			for i = #cards, 1, -1 do
			    local card = cards[i]
				if (not isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and (not self.player:isJilei(card)) then
				    table.insert(to_discard, card:getEffectiveId())
			        table.remove(cards, i)
			        index = index + 1
			        if index == 2 then break end
		        end
			end
			if #to_discard < 2 then return {}
			else return to_discard end
		end
	else
	    local cards = sgs.QList2Table(self.player:getCards("he"))
		self:sortByKeepValue(cards, true)
		local index = 0
		for i = #cards, 1, -1 do
		    local card = cards[i]
			if not (isCard("Peach", card, self.player)) and (not isCard("Analeptic", card, self.player)) and not self.player:isJilei(card) then
			    table.insert(to_discard, card:getEffectiveId())
		        table.remove(cards, i)
		        index = index + 1
		        if index == 2 then break end
	        end
		end
		if #to_discard < 2 then return {}
		else return to_discard end
	end
end




--魏武
sgs.ai_skill_invoke.sy_weiwu = function(self, data)
	if self:needKongcheng(self.player, true) then return false end
	return true
end

sgs.ai_can_damagehp.sy_weiwu = function(self,from,card,to)
	return to:getHp()+self:getAllPeachNum()-self:ajustDamage(from,to,1,card)>0
	and self:canLoseHp(from,card,to)
end


--龙变
sgs.ai_skill_invoke.sy_longbian = function(self, data)
	local x = 0 --【杀】可用次数
	local y = 0  --摸牌阶段摸牌数
	if (not self.player:getTag("mcc_phasedraw_count"):toInt()) or self.player:getTag("mcc_phasedraw_count"):toInt() == 0 then
		if Nil2Int(self.player:getTag("mcc_phasedraw_num"):toInt()) == 0 then y = y + 2 else y = y + self.player:getTag("mcc_phasedraw_num"):toInt() end
	else
		if self.player:getTag("mcc_phasedraw_count"):toInt() then y = y + self.player:getTag("mcc_phasedraw_count"):toInt() end
	end
	local z = self.player:getMaxHp()  --体力上限
	if Nil2Int(self.player:getTag("mcc_defaultslash_num"):toInt()) == 0 then x = x + 1 else x = x + self.player:getTag("mcc_defaultslash_num"):toInt() end
	if math.min(x, y, z) <= 2 then return true end
	if x == y and y == z then return true end
	if math.max(x, y, z) ~= math.min(x, y, z) then return true end
end

sgs.ai_skill_choice["sy_longbian"] = function(self, choices, data)
	local longbian = choices:split("+")
	local x = 0 --【杀】可用次数
	local y = 0  --摸牌阶段摸牌数
	if (not self.player:getTag("mcc_phasedraw_count"):toInt()) or self.player:getTag("mcc_phasedraw_count"):toInt() == 0 then
		if Nil2Int(self.player:getTag("mcc_phasedraw_num"):toInt()) == 0 then y = y + 2 else y = y + self.player:getTag("mcc_phasedraw_num"):toInt() end
	else
		if self.player:getTag("mcc_phasedraw_count"):toInt() then y = y + self.player:getTag("mcc_phasedraw_count"):toInt() end
	end
	local z = self.player:getMaxHp()  --体力上限
	if Nil2Int(self.player:getTag("mcc_defaultslash_num"):toInt()) == 0 then x = x + 1 else x = x + self.player:getTag("mcc_defaultslash_num"):toInt() end
	if x ~= y and y ~= z and x ~= z then
		if math.min(x, y, z) == x then
			return longbian[1]
		elseif math.min(x, y, z) == y then
			return longbian[2]
		elseif math.min(x, y, z) == z then
			return longbian[3]
		end
	else
		return longbian[math.random(1, #longbian)]
	end
end


--魔舞
sgs.ai_skill_invoke.sy_mowu = function(self, data)
	local use = data:toCardUse()
	if (use.card:isDamageCard() or use.card:isKindOf("Snatch") or use.card:isKindOf("Dismantlement")) and use.from and use.from:objectName() == self.player:objectName() then
		local enemies = {}
		for _, pe in sgs.qlist(use.to) do
			if self:isEnemy(pe) then table.insert(enemies, pe) end
		end
		if #enemies > 0 and use.to:length() - #enemies <= 1 then return true end
	end
	if not use.card:isDamageCard() and use.from and use.from:objectName() ~= self.player:objectName() then
		if self:isFriend(use.from) then return true end
		if self:isEnemy(use.from) and not use.to:contains(use.from) then return true end
	end
	if use.card:isKindOf("Peach") and self.player:isWounded() then return true end
	if use.card:isKindOf("Analeptic") then return true end
	return false
end


--权倾
local sy_quanqing_skill = {}
sy_quanqing_skill.name = "sy_quanqing"
table.insert(sgs.ai_skills, sy_quanqing_skill)
sy_quanqing_skill.getTurnUseCard = function(self)
	if self.player:isKongcheng() then return end
	local cards = sgs.QList2Table(self.player:getCards("h"))
	local to_show = {}
	for _, c in ipairs(cards) do
		local cid = c:getEffectiveId()
		if self.player:getMark("sy_quanqing"..cid.."-PlayClear") == 0 then table.insert(to_show, c) end
	end
	local _max = -999
	if #to_show > 0 then
		for _, c in ipairs(to_show) do
			_max = math.max(_max, c:getNumber())
		end
	end
	local max_card
	for _, c in ipairs(to_show) do
		if c:getNumber() == _max then
			max_card = c
			break
		end
	end
	if max_card then
		return sgs.Card_Parse("#sy_quanqingCard:"..max_card:getEffectiveId()..":")
	else
		return nil
	end
end

sgs.ai_skill_use_func["#sy_quanqingCard"] = function(card,use,self)
	local target = nil
	if #self.enemies > 0 then
		self:sort(self.enemies, "chaofeng")
		for _, enemy in ipairs(self.enemies) do
			if enemy:getMark("sy_quanqingTarget-PlayClear") == 0 then
				target = enemy
				break
			end
		end
	else
		if #self.friends_noself > 0 then
			self:sort(self.friends_noself)
			for _, friend in ipairs(self.friends_noself) do
				if friend:getMark("sy_quanqingTarget-PlayClear") == 0 then
					target = friend
					break
				end
			end
		end
	end
	if target then
		use.card = card
		if use.to then use.to:append(target) end
		return
	end
	return
end

sgs.ai_use_value["sy_quanqingCard"] = 10
sgs.ai_use_priority["sy_quanqingCard"] = sgs.ai_use_priority.ExNihilo - 0.1

sgs.ai_skill_cardask["@sy_quanqing"] = function(self, data, pattern)
	local cards = sgs.QList2Table(self.player:getCards("he"))
	self:sortByKeepValue(cards)
	local num = data:toInt()
	local sunluban = self.room:findPlayerBySkillName("sy_quanqing")
	local qqcard
	if not self:isFriend(sunluban) then
		for _, card in ipairs(cards) do
			if card:getNumber() > num then
				qqcard = card
				break
			end
		end
	else
		return "."
	end
	if qqcard then
		return "$" .. qqcard:getEffectiveId()
	end
	return "."
end

function canQuanqingSlashHit(slash, from, to)
	if from:hasWeapon("QinggangSword") then return true end
	if slash:isKindOf("NormalSlash") and to:getArmor() == "vine" then
		if from:hasWeapon("Fan") then return true else return false end
	end
	if slash:isKindOf("FireSlash") or slash:isKindOf("ThunderSlash") or slash:isKindOf("IceSlash") then return true end
end

sgs.ai_skill_askforag.sy_quanqing = function(self, card_ids)
	local result_id = -1
	local from = self.player:getTag("sy_quanqing_target"):toPlayer()
	if self:isEnemy(from) then
		for _,id in sgs.list(card_ids)do
			local qq_card = sgs.Sanguosha:getCard(id)
			if not from:isProhibited(self.player, qq_card) then
				if qq_card:isKindOf("Duel") then
					result_id = id
					break
				end
			end
		end
		if result_id == -1 then
			for _,id in sgs.list(card_ids)do
				if qq_card:isKindOf("Slash") then
					if canQuanqingSlashHit(card, from, self.player) then
						result_id = id
						break
					end
				end
			end
		end
	elseif self:isFriend(from) then
		for _,id in sgs.list(card_ids)do
			local qq_card = sgs.Sanguosha:getCard(id)
			if self:isWeak(from) then
				if from:hasSkills("hunzi|mobilehunzi|olhunzi") then
					if qq_card:isKindOf("ExNihilo") then
						result_id = id
						break
					end
				else
					if from:isWounded() and qq_card:isKindOf("Peach") then
						result_id = id
						break
					end
				end
			else
				local has_sunce = false
				for _, t in sgs.qlist(self.room:getOtherPlayers(from)) do
					if self:isFriend(t) and t:hasSkills("hunzi|mobilehunzi|olhunzi") and t:getHp() <= 2 then
						has_sunce = true
						break
					end
				end
				if has_sunce then
					if qq_card:isKindOf("ExNihilo") then
						result_id = id
						break
					end
				else
					if qq_card:isKindOf("GodSalvation") then
						result_id = id
						break
					end
				end
			end
		end
	end
	if result_id ~= -1 then return result_id end
end

function hasDeathSkills(who)
	return who:hasSkills("wuhun|sgkgodsuohun|duanchang") and not who:hasSkills("sy_fangu|sy_guiming")
end

sgs.ai_skill_playerchosen.sy_quanqing = function(self, targets)
	local qq_from = self.player:getTag("sy_quanqing_target"):toPlayer()
	local to = nil
	if self:isEnemy(qq_from) then
		for _, t in sgs.qlist(targets) do
			if self:isEnemy(t) and hasDeathSkills(t) then
				to = t
				break
			end
		end
		if not to then
			if self.player:getHp() >= 2 or self:getCardsNum("Peach") + self:getCardsNum("Analeptic") > 0 then
				to = self.player
			end
		end
	end
	return to
end

sgs.ai_need_damaged.sy_quanqing = function(self, attacker, player)
	if self:isEnemy(attacker, player) then
		if (not self:isWeak(player)) or (getCardsNum("Peach", player, self.player) + getCardsNum("Analeptic", player, self.player)) > 0 then
			return true
		end
		if attacker:hasSkill("sgkgodxiejia") and attacker:getArmor() == nil and player:getArmor() ~= "silver_lion" then return false end
		if attacker:hasSkill("luoyi") and attacker:getMark("&luoyi") > 0 and player:getArmor() ~= "silver_lion" then return false end
		if attacker:hasSkill("mobilepojun|mouliegong") then return false end
	end
	if self:isEnemy(attacker, player) and not (self:needToLoseHp(attacker) and not self:hasSkills(sgs.masochism_skill, attacker)) then return true end
	return false
end

--永劫
function hasResistLoseMaxHpSkill(player)
	return player:hasSkills("sgkgodyinyang|sgkgodlinglong|sgkgodqianyuan|sgkgoddanjing|sgkgodwangyue|huishi") or player:getMaxHp() >= 8
end

sgs.ai_skill_invoke.sy_yongjie = function(self, data)
	local can_do = false
	local room = self.player:getRoom()
	for _, t in sgs.qlist(room:getAlivePlayers()) do
		if t:getMark("sy_yongjie_DamageTimes") > 0 and self:isEnemy(t) then
			can_do = true
			break
		end
	end
	return can_do
end

sgs.ai_skill_playerschosen.sy_yongjie = function(self, targets)
	targets = sgs.QList2Table(targets)
	local nuls = {}
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) then
		   table.insert(nuls, p)
		end
	end
	return nuls
end

sgs.ai_skill_discard.sy_yongjie = function(self, discard_num, min_num, optional, include_equip)
    local to_discard = {}
	local sunluban
	if self.room:findPlayerBySkillName("sy_yongjie") then sunluban = self.room:findPlayerBySkillName("sy_yongjie") end
	if sunluban and hasResistLoseMaxHpSkill(self.player) then return to_discard end
	local n = math.random(1, 100)
	local x = self.player:getMark("sy_yongjie_DamageTimes")
	if n <= 95 then
	    return to_discard
	else
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
end


--凋零
sgs.ai_skill_invoke.sy_diaoling = function(self, data)
	local to = self.player:getTag("sy_diaoling_target"):toPlayer()
	local move = self.player:getTag("sy_diaoling_move"):toMoveOneTime()
	local x = move.card_ids:length()
	if self:isEnemy(to) then
		if to:getHp() - x <= 2 then return true end
		if x <= 1 then
			if to:getHp() > 1 and to:hasSkill("zhaxiang") then return false end
		end
		return true
	elseif self:isFriend(to) then
		if to:hasSkill("zhaxiang") and to:getHp() > 2 and x <= 2 then return true end
	end
end

--扼绝
local sy_ejue_skill = {}
sy_ejue_skill.name = "sy_ejue"
table.insert(sgs.ai_skills, sy_ejue_skill)
sy_ejue_skill.getTurnUseCard = function(self, inclusive)
    if #self.enemies == 0 then return nil end
	return sgs.Card_Parse("#sy_ejueCard:.:")
end

sgs.ai_skill_use_func["#sy_ejueCard"] = function(card, use, self)
    use.card = card
end

sgs.ai_skill_invoke.sy_ejue = function(self, data)
	return #self.enemies > 0
end

sgs.ai_skill_use["@@sy_ejue!"] = function(self, prompt)
    local to_select = {}
	for _, c in sgs.qlist(self.player:getCards("he")) do
		if c:hasFlag("sy_ejue_draw") then table.insert(to_select, c) end
	end
	local _max = 0
	local ejue_id
	for _, c in ipairs(to_select) do
		_max = math.max(_max, c:getNumber())
	end
	for _, c in ipairs(to_select) do
		if c:getNumber() >= _max then
			if (not c:isKindOf("Peach")) and (not c:isKindOf("Analeptic")) then
				ejue_id = c:getEffectiveId()
				break
			end
		end
	end
	if not ejue_id then
		for _, c in ipairs(to_select) do
			if c:getNumber() >= _max then
				ejue_id = c:getEffectiveId()
				break
			end
		end
	end
	if not ejue_id then
		ejue_id = to_select[math.random(1, #to_select)]:getEffectiveId()
	end
	return "#sy_ejueCard:"..ejue_id..":"
end


--魔貂蝉--（“迷乱”纯礁石棍，容易把顺风送翻盘，不写）
--魅惑（只给一张，就是这么抠（）
local fcmk_jlsg_meihuo_skill = {}
fcmk_jlsg_meihuo_skill.name = "fcmk_jlsg_meihuo"
table.insert(sgs.ai_skills, fcmk_jlsg_meihuo_skill)
fcmk_jlsg_meihuo_skill.getTurnUseCard = function(self)
	if self.player:hasUsed("#fcmk_jlsg_meihuoCard") or self.player:isKongcheng() or #self.enemies < 2 then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local lightning = self:getCard("Lightning")
	if lightning and (lightning:isRed() or (lightning:getSuit() == sgs.Card_Spade and self.player:hasSkill("mouhongyann")))
	and not self:willUseLightning(lightning) then --优先给最废牌闪电
		card_id = lightning:getEffectiveId()
	else
		for _, acard in ipairs(cards) do
			if acard:isKindOf("Slash") or (acard:isNDTrick() and acard:isDamageCard()) then --先给【杀】和伤害类普通锦囊
				card_id = acard:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
		for _, acard in ipairs(cards) do
			if acard:isNDTrick() and not acard:isKindOf("GlobalEffect") and not acard:isKindOf("ExNihilo") and not acard:isKindOf("Dongzhuxianji")
			and not acard:isKindOf("Snatch") and not acard:isKindOf("TlxyYanhua") then --再给其他的普通锦囊，但增益类锦囊和【顺手牵羊】这种拉不了敌我牌差的坚决不给
				card_id = acard:getEffectiveId()
				break
			end
		end
	end
	if not card_id then
	    return nil
	else
	    return sgs.Card_Parse("#fcmk_jlsg_meihuoCard:"..card_id..":")
	end
end

sgs.ai_skill_use_func["#fcmk_jlsg_meihuoCard"] = function(card, use, self)
    if not self.player:hasUsed("#fcmk_jlsg_meihuoCard") and not self.player:isKongcheng() and #self.enemies >= 2 then
        self:sort(self.enemies)
		for _, enemy in ipairs(self.enemies) do
		    if enemy and enemy:isMale() and enemy:getHandcardNum() > 3 then --先找手牌多的
				use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
	    end
		for _, enemy in ipairs(self.enemies) do
		    if enemy and enemy:isMale() then
				use.card = card
			    if use.to then use.to:append(enemy) end
		        return
			end
	    end
	end
	return nil
end

sgs.ai_use_value.fcmk_jlsg_meihuoCard = 8.5
sgs.ai_use_priority.fcmk_jlsg_meihuoCard = 9.5
sgs.ai_card_intention.fcmk_jlsg_meihuoCard = 80

sgs.ai_skill_playerchosen.fcmk_jlsg_meihuo = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, p in ipairs(targets) do
	    if self:isEnemy(p) then
		    return p
		end
	end
	for _, p in ipairs(targets) do
	    if not self:isFriend(p) then
		    return p
		end
	end
	return nil
end

sgs.ai_skill_invoke.fcmk_jlsg_miluan = true