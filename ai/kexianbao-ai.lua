--change

sgs.ai_skill_invoke.xianchangetupo = function(self, data)
	--[[local num = math.random(0,1)
	if (num == 0) then
	    return true
	else
		return false
	end]]
	return false
end

--南华老仙

sgs.ai_skill_invoke.kexianhuoqi = function(self, data)
	return sgs.ai_skill_choice.kexianhuoqi(self, "recover+pindian+cancel", data) ~= "cancel"
end

sgs.ai_skill_choice.kexianhuoqi = function(self, choices, data)
	if self:isWeak() then return "recover" end
	local players = sgs.SPlayerList()
	for _, pp in sgs.qlist(self.room:getAllPlayers()) do
		if pp:canPindian() then
			players:append(pp)
		end
	end
	if players:length() >= 2 and sgs.ai_skill_playerschosen.kexianhuoqi(self, players, 2, 2) ~= {} then
		return "pindian"
	end
	return "cancel"
end

function kexianhuoqi_discard(self, discard_num, min_num, optional, include_equip)
	local xiahou
	for _, p in sgs.qlist(self.room:getAlivePlayers()) do
		if p:hasFlag("kexianhuoqi_winner") then
			xiahou = p
			break
		end
	end
	if xiahou and (not self:damageIsEffective(self.player, sgs.DamageStruct_Normal, xiahou) or self:needToLoseHp(self.player, xiahou)) then return {} end
	if xiahou and self:needToLoseHp(self.player, xiahou) then return {} end
	local to_discard = {}
	local cards = sgs.QList2Table(self.player:getHandcards())
	local index = 0
	local all_peaches = 0
	for _, card in ipairs(cards) do
		if isCard("Peach", card, self.player) then
			all_peaches = all_peaches + 1
		end
	end
	if all_peaches >= 2 and self:getOverflow() <= 0 then return {} end
	self:sortByKeepValue(cards)
	cards = sgs.reverse(cards)

	for i = #cards, 1, -1 do
		local card = cards[i]
		if not isCard("Peach", card, self.player) and not self.player:isJilei(card) then
			table.insert(to_discard, card:getEffectiveId())
			table.remove(cards, i)
			index = index + 1
			if index == 2 then break end
		end
	end
	if #to_discard < 2 then
		return {}
	else
		return to_discard
	end
end

sgs.ai_skill_discard.kexianhuoqi = function(self, discard_num, min_num, optional, include_equip)
	return kexianhuoqi_discard(self, discard_num, min_num, optional, include_equip)
end


sgs.ai_skill_playerschosen.kexianhuoqi = function(self, players, x, n)
	local destlist = sgs.QList2Table(players)
	self:sort(destlist, "hp")
	local tos = {}
	for _, a in sgs.list(destlist) do
		for _, b in sgs.list(destlist) do
			if #tos >= x then break end
			if self:isEnemy(a) and self:isEnemy(b) and not table.contains(tos, b) and a:canPindian(b) and b:objectName() ~= a:objectName() then
				table.insert(tos, b)
			end
		end
	end
	return tos
end

sgs.ai_damage_reason_suppress_intention["kexianhuoqi"] = true


sgs.ai_skill_use["@kexiantianbian"] = function(self, prompt)
	local targets = sgs.QList2Table(self.room:getAllPlayers())
	local pindian = self.room:getTag("CurrentPindianStruct"):toPindian()
	local from, to
	for _, p in ipairs(targets) do
		if p:hasFlag("kexiantianbian_Source") then
			from = p
		end
		if p:hasFlag("kexiantianbian_Target") then
			to = p
		end
	end
	if from and to and self:isFriend(to) and self:isEnemy(from) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() < pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if acard:getNumber() < pindian.to_card:getNumber() then
						table.insert(min_card, acard:getEffectiveId())
					elseif acard:getNumber() >= pindian.from_card:getNumber() then
						table.insert(max_card, acard:getEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#kexiantianbian_Card:" .. max_card[1] .. ":->" .. to:objectName()
			end
			if #min_card > 0 then
				return "#kexiantianbian_Card:" .. min_card[1] .. ":->" .. from:objectName()
			end
		end
	end
	if from and to and self:isFriend(from) and self:isEnemy(to) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() >= pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if acard:getNumber() > pindian.to_card:getNumber() then
						table.insert(max_card, acard:getEffectiveId())
					elseif acard:getNumber() < pindian.from_card:getNumber() then
						table.insert(min_card, acard:getEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#kexiantianbian_Card:" .. max_card[1] .. ":->" .. from:objectName()
			end
			if #min_card > 0 then
				return "#kexiantianbian_Card:" .. min_card[1] .. ":->" .. to:objectName()
			end
		end
	end

	return "."
end



sgs.ai_skill_invoke.kexianyuli = function(self, data)
	return true
end


--界南华老仙

sgs.ai_skill_invoke.kejiexianhuoqi = function(self, data)
	return sgs.ai_skill_choice.kejiexianhuoqi(self, "recover+pindian+cancel") ~= "cancel"
end

sgs.ai_skill_choice.kejiexianhuoqi = function(self, choices, data)
	if self:isWeak() then return "recover" end
	local players = sgs.SPlayerList()
	for _, pp in sgs.qlist(self.room:getAllPlayers()) do
		if pp:canPindian() then
			players:append(pp)
		end
	end
	if players:length() >= 2 and sgs.ai_skill_playerschosen.kejiexianhuoqi(self, players, 2, 2) ~= {} then
		return "pindian"
	end
	return "cancel"
end
sgs.ai_skill_choice.jienhlxloser = function(self, choices, data)
	local pindian = data:toPindian()
	if pindian.to and pindian.from then
		if self:isFriend(pindian.to) and self:needToLoseHp(pindian.to, pindian.from, nil) then
			return "damage"
		elseif self:isEnemy(pindian.to) and not self:needToLoseHp(pindian.to, pindian.from, nil) then
			return "damage"
		end
	end
	return "qipai"
end

sgs.ai_skill_playerschosen.kejiexianhuoqi = function(self, players, x, n)
	local destlist = sgs.QList2Table(players)
	self:sort(destlist, "hp")
	local tos = {}
	for _, a in sgs.list(destlist) do
		for _, b in sgs.list(destlist) do
			if #tos >= x then break end
			if self:isEnemy(a) and self:isEnemy(b) and not table.contains(tos, b) and a:canPindian(b) and b:objectName() ~= a:objectName() then
				table.insert(tos, b)
			end
		end
	end
	if #tos < 2 then
		for _, a in sgs.list(destlist) do
			for _, b in sgs.list(destlist) do
				if #tos >= x then break end
				if self:isEnemy(a) and self:isFriend(b) and not table.contains(tos, b) and a:canPindian(b) and b:objectName() ~= a:objectName() then
					table.insert(tos, b)
				end
			end
		end
	end
	if #tos < 2 then return {} end
	return tos
end

sgs.ai_damage_reason_suppress_intention["kejiexianhuoqi"] = true

sgs.ai_skill_use["@kejiexiantianbian"] = function(self, prompt)
	local targets = sgs.QList2Table(self.room:getAllPlayers())
	local pindian = self.room:getTag("CurrentPindianStruct"):toPindian()
	local from, to
	for _, p in ipairs(targets) do
		if p:hasFlag("kejiexiantianbian_Source") then
			from = p
		end
		if p:hasFlag("kejiexiantianbian_Target") then
			to = p
		end
	end
	if from and to and self:isFriend(to) and self:isEnemy(from) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() < pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if acard:getNumber() < pindian.to_card:getNumber() then
						table.insert(min_card, acard:getEffectiveId())
					elseif acard:getNumber() >= pindian.from_card:getNumber() then
						table.insert(max_card, acard:getEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#kejiexiantianbian_Card:" .. max_card[1] .. ":->" .. to:objectName()
			end
			if #min_card > 0 then
				return "#kejiexiantianbian_Card:" .. min_card[1] .. ":->" .. from:objectName()
			end
		end
	end
	if from and to and self:isFriend(from) and self:isEnemy(to) then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() >= pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if acard:getNumber() > pindian.to_card:getNumber() then
						table.insert(max_card, acard:getEffectiveId())
					elseif acard:getNumber() < pindian.from_card:getNumber() then
						table.insert(min_card, acard:getEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#kejiexiantianbian_Card:" .. max_card[1] .. ":->" .. from:objectName()
			end
			if #min_card > 0 then
				return "#kejiexiantianbian_Card:" .. min_card[1] .. ":->" .. to:objectName()
			end
		end
	end
	if from and to and math.random()<0.5 then
		local cards = sgs.QList2Table(self.player:getCards("h"))
		local max_card = {}
		local min_card = {}
		self:sortByKeepValue(cards)
		if pindian.to_card:getNumber() >= pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if acard:getNumber() > pindian.to_card:getNumber() then
						table.insert(max_card, acard:getEffectiveId())
					elseif acard:getNumber() < pindian.from_card:getNumber() then
						table.insert(min_card, acard:getEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#kejiexiantianbian_Card:" .. max_card[1] .. ":->" .. from:objectName()
			end
			if #min_card > 0 then
				return "#kejiexiantianbian_Card:" .. min_card[1] .. ":->" .. to:objectName()
			end
		end
		if pindian.to_card:getNumber() < pindian.from_card:getNumber() then
			for _, acard in ipairs(cards) do
				if not acard:isKindOf("Peach") then
					if acard:getNumber() < pindian.to_card:getNumber() then
						table.insert(min_card, acard:getEffectiveId())
					elseif acard:getNumber() >= pindian.from_card:getNumber() then
						table.insert(max_card, acard:getEffectiveId())
					end
				end
			end
			if #max_card > 0 then
				return "#kejiexiantianbian_Card:" .. max_card[1] .. ":->" .. to:objectName()
			end
			if #min_card > 0 then
				return "#kejiexiantianbian_Card:" .. min_card[1] .. ":->" .. from:objectName()
			end
		end
	end

	return "."
end



--普净

local kexianchanxin_skill = {}
kexianchanxin_skill.name = "kexianchanxin"
table.insert(sgs.ai_skills, kexianchanxin_skill)
kexianchanxin_skill.getTurnUseCard = function(self)
	if (self.player:hasUsed("#kexianchanxinCard"))
		or (sgs.Slash_IsAvailable(self.player)) then
		return
	end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = sgs.IntList()
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Slash") then
			to_throw:append(acard:getEffectiveId())
		end
	end
	card_id = to_throw:at(0) --(to_throw:length()-1)
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("#kexianchanxinCard:" .. card_id .. ":")
	end
end

sgs.ai_skill_use_func["#kexianchanxinCard"] = function(card, use, self)
	if not (self.player:hasUsed("#kexianchanxinCard")) then
		use.card = card
		return
	end
end

function sgs.ai_cardneed.kexianchanxin(to, card, self)
	if (self.player:hasUsed("#kexianchanxinCard")) then return false end
	return true
end

sgs.ai_skill_invoke.xianhuiyanfadong = function(self, data)
	return true
end

sgs.wizard_skill = sgs.wizard_skill .. "|kexianhuiyan"

sgs.ai_skill_askforag.kexianhuiyan = function(self, card_ids)
	local cards = {}
	local cards_ids = sgs.QList2Table(card_ids)                  -- 获得手牌的表
	for _,card_id in ipairs(cards_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	local judge = self.room:getTag("kexianhuiyan"):toJudge() -- 获得判定结构体
	local card_id = self:getRetrialCardId(cards, judge)     -- 从所有手牌中寻找可供改判的牌
	if card_id ~= -1 then
		return card_id                                      -- 若找到则改判
	end

	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByUseValue(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end

sgs.ai_skill_invoke.kexianguiyi = function(self, data)
	local players = sgs.SPlayerList()
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if self.player:canPindian(p) then
			players:append(p)
		end
	end
	return sgs.ai_skill_playerchosen.kexianguiyi(self, players) ~= nil
end
sgs.ai_skill_playerchosen.kexianguiyi = function(self, targets)
	targets = sgs.QList2Table(targets)
	local max_card = self:getMaxCard()
	if not max_card then return nil end
	local point = max_card:getNumber()
	if self.player:hasSkill("tianbian") and max_card:getSuit() == sgs.Card_Heart then point = 13 end
	if point >= 7 then
		self:sort(targets, "handcard")
		for _, p in ipairs(targets) do
			if not self:isEnemy(p) then continue end
			if not self.player:canPindian(p) then continue end
			local maxcard = self:getMaxCard(p)
			if maxcard then
				local number = maxcard:getNumber()
				if p:hasSkill("tianbian") and maxcard:getSuit() == sgs.Card_Heart then number = 13 end
				if number < point then
					return p
				end
			end
		end
	end
	if point >= 10 then
		self:sort(targets, "handcard")
		for _, p in ipairs(targets) do
			if not self:isEnemy(p) then continue end
			if not self.player:canPindian(p) then continue end
			return p
		end
	end
	return nil
end
sgs.ai_cardneed.kexianguiyi = sgs.ai_cardneed.bignumber

sgs.ai_skill_invoke.kejiexianhuiyan = function(self, data)
	return true
end
sgs.ai_skill_askforag.kejiexianhuiyan = function(self, card_ids)
	local cards = {}
	local judge = self.room:getTag("kejiexianhuiyan"):toJudge() -- 获得判定结构体
	local cards_ids = sgs.QList2Table(card_ids)                  -- 获得手牌的表
	for _,card_id in ipairs(cards_ids) do
		table.insert(cards, sgs.Sanguosha:getCard(card_id))
	end
	local card_id = self:getRetrialCardId(cards, judge)      -- 从所有手牌中寻找可供改判的牌
	if card_id ~= -1 then
		return card_id                                       -- 若找到则改判
	end

	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, sgs.Sanguosha:getCard(card_id))
	end
	self:sortByUseValue(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end
sgs.wizard_skill = sgs.wizard_skill .. "|kejiexianhuiyan"
sgs.wizard_harm_skill = sgs.wizard_harm_skill .. "|kejiexianhuiyan"


local kejiexianchanxin_skill = {}
kejiexianchanxin_skill.name = "kejiexianchanxin"
table.insert(sgs.ai_skills, kejiexianchanxin_skill)
kejiexianchanxin_skill.getTurnUseCard = function(self)
	return sgs.Card_Parse("#kejiexianchanxinCard:.:")
end

sgs.ai_skill_use_func["#kejiexianchanxinCard"] = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp() < 3 then
		local use_slash, keep_weapon = false, nil
		local keep_slash = self.player:getTag("JilveWansha"):toBool()
		for _, zcard in sgs.list(self.player:getCards("he")) do
			if zcard:isDamageCard() or zcard:isKindOf("Weapon")
			then
				local shouldUse = true
				if isCard("Slash", zcard, self.player)
					and not use_slash
				then
					local dummy_use = self:aiUseCard(zcard)
					if dummy_use.card then
						if keep_slash then shouldUse = false end
						if dummy_use.to then
							for _, p in sgs.list(dummy_use.to) do
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
					if self:aiUseCard(zcard).card then shouldUse = false end
				end
				if zcard:getTypeId() == sgs.Card_TypeEquip and not self.player:hasEquip(zcard) then
					if self:aiUseCard(zcard).card then shouldUse = false end
					if keep_weapon and zcard:getEffectiveId() == keep_weapon:getEffectiveId() then shouldUse = false end
				end
				if shouldUse then table.insert(unpreferedCards, zcard:getId()) end
			end
		end
	end

	if #unpreferedCards < 1 then
		local use_slash_num = 0
		self:sortByKeepValue(cards)
		for _, card in ipairs(cards) do
			if card:isKindOf("Slash") then
				local will_use = false
				if use_slash_num <= sgs.Sanguosha:correctCardTarget(sgs.TargetModSkill_Residue, self.player, card)
				then
					if self:aiUseCard(card).card then
						will_use = true
						use_slash_num = use_slash_num + 1
					end
				end
				if not will_use then table.insert(unpreferedCards, card:getId()) end
			end
		end

		for _, card in ipairs(cards) do
			if card:isKindOf("Weapon") and self.player:getHandcardNum() < 3
			then
				table.insert(unpreferedCards, card:getId())
			elseif card:getTypeId() == sgs.Card_TypeTrick and card:isDamageCard() then
				if not self:aiUseCard(card).card then table.insert(unpreferedCards, card:getId()) end
			end
		end

		if self.player:getWeapon() and self.player:getHandcardNum() < 3 then
			table.insert(unpreferedCards, self.player:getWeapon():getId())
		end
	end

	local use_cards = {}
	for i = #unpreferedCards, 1, -1 do
		if not self.player:isJilei(sgs.Sanguosha:getCard(unpreferedCards[i])) then
			table.insert(use_cards,
				unpreferedCards[i])
		end
	end

	if #use_cards > 0 then
		use.card = sgs.Card_Parse("#kejiexianchanxinCard:" .. table.concat(use_cards, "+") .. ":")
	end
end

sgs.ai_use_value["#kejiexianchanxinCard"] = 9
sgs.ai_use_priority["#kejiexianchanxinCard"] = 2.61
sgs.dynamic_value.benefit["#kejiexianchanxinCard"] = true


sgs.ai_skill_playerchosen.kejiexianchanxinCard = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, enemy in ipairs(self.enemies) do
		if (self:doDisCard(enemy, "he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() then
			return enemy
		end
	end
	for _, enemy in ipairs(self.enemies) do
		if (self:doDisCard(enemy, "he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() then
			return enemy
		end
	end
	return nil
end

function sgs.ai_cardneed.kejiexianchanxin(to, card)
	return card:isKindOf("Weapon") or card:isDamageCard()
end

sgs.ai_skill_invoke.kejiexianguiyi = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then return false end
	return true
end

sgs.ai_skill_choice.kejiexianguiyi = function(self, choices, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then return "have" end
	local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
	for _, card in sgs.qlist(target:getHandcards()) do
		if card:hasFlag("visible") or card:hasFlag(flag) then
			if card:isDamageCard() then
				return "have"
			end
		end
	end
	return "nothave"
end




--左慈

sgs.ai_skill_invoke.kexianlunhui = function(self, data)
	return true
end

local kexianfenshen_skill = {}
kexianfenshen_skill.name = "kexianfenshen"
table.insert(sgs.ai_skills, kexianfenshen_skill)
kexianfenshen_skill.getTurnUseCard = function(self)
	if (self.player:hasUsed("#kexianfenshenCard")) or (self.player:getMark("&xianzuociji") == 0) then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = sgs.IntList()
	for _, acard in ipairs(cards) do
		to_throw:append(acard:getEffectiveId())
	end
	card_id = to_throw:at(0) --(to_throw:length()-1)
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("#kexianfenshenCard:" .. card_id .. ":")
	end
end

sgs.ai_skill_use_func["#kexianfenshenCard"] = function(card, use, self)
	if (self.player:getMark("&xianzuociji") > 0) and not (self.player:hasUsed("#kexianfenshenCard")) then
		use.card = card
		return
	end
end

sgs.ai_use_value.kexianfenshenCard = 8.5
sgs.ai_use_priority.kexianfenshenCard = 9.5
sgs.ai_card_intention.kexianfenshenCard = -80

sgs.double_slash_skill = sgs.double_slash_skill .. "|kexianfeijian"

sgs.ai_skill_invoke.kejiexianlunhui = function(self, data)
	return true
end

local kejiexianfenshen_skill = {}
kejiexianfenshen_skill.name = "kejiexianfenshen"
table.insert(sgs.ai_skills, kejiexianfenshen_skill)
kejiexianfenshen_skill.getTurnUseCard = function(self)
	if (self.player:hasUsed("#kejiexianfenshenCard"))
		or (self.player:getMark("&kexianfenshen") >= 3)
		or (self.player:getMark("&jiexianzuociji") == 0) then
		return
	end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = sgs.IntList()
	for _, acard in ipairs(cards) do
		to_throw:append(acard:getEffectiveId())
	end
	card_id = to_throw:at(0) --(to_throw:length()-1)
	if not card_id then
		return nil
	else
		return sgs.Card_Parse("#kejiexianfenshenCard:" .. card_id .. ":")
	end
end

sgs.ai_skill_use_func["#kejiexianfenshenCard"] = function(card, use, self)
	if (self.player:getMark("&kexianfenshen") < 3) and (self.player:getMark("&jiexianzuociji") > 0) and not (self.player:hasUsed("#kejiexianfenshenCard")) then
		use.card = card
		return
	end
end

function sgs.ai_cardneed.kejiexianfenshen(to, card, self)
	if (not (self.player:getMark("&kexianfenshen") < 3)) and (self.player:hasUsed("#kejiexianfenshenCard")) or (self.player:getMark("&jiexianzuociji") == 0) then return false end
	return true
end

sgs.ai_use_value.kejiexianfenshenCard = 8.5
sgs.ai_use_priority.kejiexianfenshenCard = 9.5
sgs.ai_card_intention.kejiexianfenshenCard = -80

sgs.ai_skill_invoke.kejiexianfeijian = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kejiexianfeijian = sgs.ai_skill_playerchosen.zero_card_as_slash

sgs.double_slash_skill = sgs.double_slash_skill .. "|kejiexianfeijian"


--于吉
sgs.ai_skill_invoke.kexianmabi = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if target:getMark("&kexianmabimopai") > 0 then return false end
	if self:isFriend(target)
	then
		if self:needToLoseHp(target, self.player, damage.card) then
			return false
		elseif target:isChained() and self:isGoodChainTarget(target, damage.card) then
			return false
		elseif self:isWeak(target) or damage.damage > 1 then
			return true
		elseif target:getLostHp() < 1 then
			return false
		end
		return true
	else
		if self:isWeak(target) then return false end
		if damage.damage > 1 or self:ajustDamage(self.player, target, 1, damage.card) > 1 then return false end
		if target:hasSkill("lirang") and #self:getFriends(target, true) > 0 then return false end
		if target:getArmor() and self:evaluateArmor(target:getArmor(), target) > 3 and not (target:hasArmorEffect("silver_lion") and target:isWounded()) then return true end
		if self.player:hasSkill("tieji") or self:canLiegong(target, self.player) then return false end
		if target:getCards("he"):length() < 4 and target:getCards("he"):length() > 1 then return true end
		return false
	end
end
sgs.ai_skill_invoke.kexianxiuzhen = function(self, data)
	local target = data:toDamage().from
	if target and self:isFriend(target) and self:isWeak(target) then return false end
	return true
end
sgs.ai_can_damagehp.kexianxiuzhen = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from)
	end
end


sgs.ai_skill_invoke.kejiexianmabi = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if target:getMark("&kejiexianmabimp") > 0 then return false end
	if target:getMark("&kejiexianmabicp") > 0 then return false end
	if self:isFriend(target)
	then
		if self:needToLoseHp(target, self.player, damage.card) then
			return false
		elseif target:isChained() and self:isGoodChainTarget(target, damage.card) then
			return false
		elseif self:isWeak(target) or damage.damage > 1 then
			return true
		elseif target:getLostHp() < 1 then
			return false
		end
		return true
	else
		if self:isWeak(target) then return false end
		if damage.damage > 1 or self:ajustDamage(self.player, target, 1, damage.card) > 1 then return false end
		if target:hasSkill("lirang") and #self:getFriends(target, true) > 0 then return false end
		if target:getArmor() and self:evaluateArmor(target:getArmor(), target) > 3 and not (target:hasArmorEffect("silver_lion") and target:isWounded()) then return true end
		if self.player:hasSkill("tieji") or self:canLiegong(target, self.player) then return false end
		if target:getCards("he"):length() < 4 and target:getCards("he"):length() > 1 then return true end
		return false
	end
end

sgs.ai_skill_invoke.kejiexianxiuzhenpd = function(self, data)
	return true
end

sgs.ai_skill_playerchosen.kejiexianxiuzhen = function(self, targets)
	self:updatePlayers()
	local function getCmpValue(enemy)
		local value = 0
		if not self:damageIsEffective(enemy, sgs.DamageStruct_Thunder, self.player) then return 99 end
		if self:cantbeHurt(enemy, self.player, 1)
			or self:objectiveLevel(enemy) < 3
			or (enemy:isChained() and not self:isGoodChainTarget(enemy, sgs.DamageStruct_Thunder, self.player, 1))
		then
			return 100
		end
		if enemy:hasSkills(sgs.exclusive_skill) then value = value + 10 end
		if enemy:hasSkills(sgs.masochism_skill) then value = value + 5 end
		if enemy:isChained() and self:isGoodChainTarget(enemy, sgs.DamageStruct_Thunder, self.player, 1) and #(self:getChainedEnemies(self.player)) > 1 then
			value =
				value - 25
		end
		if enemy:isLord() then value = value - 5 end
		value = value + enemy:getHp() + self:getDefenseSlash(enemy) * 0.01
		return value
	end
	local bcv = {}
	local enemies = self:getEnemies(self.player)
	for _, enemy in ipairs(enemies) do
		bcv[enemy:objectName()] = getCmpValue(enemy)
	end
	local function cmp(a, b)
		return bcv[a:objectName()] < bcv[b:objectName()]
	end
	table.sort(enemies, cmp)
	for _, enemy in ipairs(enemies) do
		if getCmpValue(enemy) > 0 then return enemy end
	end
	return nil
end

sgs.ai_skill_playerchosen.kejiexianxiuzhendis = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, enemy in ipairs(self.enemies) do
		if (self:doDisCard(enemy, "he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() then
			return enemy
		end
	end
end

sgs.ai_can_damagehp.kejiexianxiuzhen = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return true
	end
end

sgs.ai_skill_choice.kejiexianxiuzhen = function(self, choices)
	if self.room:getLord() and self.player:isYourFriend(self.room:getLord()) then return self.room:getLord():getKingdom() end
	choices = choices:split(":")
	return choices[math.random(1, #choices)]
end


--马谡
sgs.ai_skill_playerchosen.kexianhanyan = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, enemy in ipairs(self.enemies) do
		if (self:doDisCard(enemy, "he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() then
			return enemy
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
			or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend, "he") then
			return friend
		end
	end
end


sgs.ai_skill_invoke.kexianxiaocai = function(self, data)
	return true
end


sgs.ai_skill_playerchosen.kejiexianliwei = function(self, targets)
	targets = sgs.QList2Table(targets)
	self:sort(targets, "defense")
	for _, enemy in ipairs(self.enemies) do
		if (self:doDisCard(enemy, "he") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and not enemy:isNude() then
			return enemy
		end
	end
	for _, friend in ipairs(self.friends_noself) do
		if (self:hasSkills(sgs.lose_equip_skill, friend) and not friend:getEquips():isEmpty())
			or (self:needToThrowArmor(friend) and friend:getArmor()) or self:doDisCard(friend, "he") then
			return friend
		end
	end
	return nil
end

sgs.ai_skill_cardchosen.kejiexianliwei = function(self, who, flags)
	local cards = sgs.QList2Table(who:getEquips())
	local handcards = sgs.QList2Table(who:getHandcards())
	if #handcards < 3 or handcards[1]:hasFlag("visible") then table.insert(cards, handcards[1]) end

	for i = 1, #cards, 1 do
		return cards[i]
	end
	return nil
end
sgs.ai_choicemade_filter.cardChosen.kejiexianliwei = sgs.ai_choicemade_filter.cardChosen.dismantlement


sgs.ai_skill_invoke.kejiexianaoce = function(self, data)
	local target = data:toCardUse().from
	if not target then return false end
	if self:isFriend(target) then return false end
	if self.player:getHp() > 1 and not self:canHit(self.player, target)
		and not (target:hasWeapon("double_sword") and self.player:getGender() ~= target:getGender())
	then
		return true
	end
	if getCardsNum("Slash", target, self.player) < 1
		or self:needLeiji(self.player, target)
		or self:needToLoseHp(self.player, target, dummyCard())
	then
		return true
	end
	if self:getOverflow() and self:getCardsNum("Jink") > 1 then return true end

	for _, c in sgs.qlist(self.player:getCards("h")) do
		if c:isKindOf("Jink") then
			return true
		end
	end
	return false
end

sgs.ai_suppress_intention["kejiexianaoce"] = true


--张郃
sgs.ai_skill_invoke.kexianbenxi = function(self, data)
	if self.player:isSkipped(sgs.Player_Play) then return false end
	if self:needBear() then return false end
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	local slashtarget = 0
	self:sort(self.enemies, "hp")
	for _, card in ipairs(cards) do
		if card:isKindOf("Slash") then
			for _, enemy in ipairs(self.enemies) do
				if self.player:canSlash(enemy, card, true) and self:slashIsEffective(card, enemy) and self:objectiveLevel(enemy) > 3 and self:isGoodTarget(enemy, self.enemies, card) then
					if getCardsNum("Jink", enemy) < 1 or (self.player:hasWeapon("axe") and self.player:getCards("he"):length() > 4) then
						slashtarget = slashtarget + 1
					end
				end
			end
		end
	end
	if (slashtarget) > 0 then
		return true
	end
	return false
end
sgs.ai_skill_playerchosen.kexianbenxi = function(self, targets)
	self:sort(self.enemies, "handcard")
	self.enemies = sgs.reverse(self.enemies)

	for _, enemy in sgs.list(self.enemies) do
		if not enemy:isKongcheng() and self:objectiveLevel(enemy) > 0 then
			return enemy
		end
	end
	return nil
end

sgs.ai_ajustdamage_from.kexianbenxi = function(self, from, to, card, nature)
	if from:getMark("&kexianbenxi-PlayClear") > 0 and card and card:isKindOf("Slash")
	then
		return 1
	end
end

function sgs.ai_cardneed.kexianbenxi(to, card, self)
	local slash_num = 0
	local target
	local slash = dummyCard()

	local cards = to:getHandcards()
	local need_slash = true
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if c:hasFlag("visible") or c:hasFlag(flag) then
			if isCard("Slash", c, to) then
				need_slash = false
				break
			end
		end
	end

	self:sort(self.enemies, "defenseSlash")
	for _, enemy in ipairs(self.enemies) do
		if to:canSlash(enemy) and not self:slashProhibit(slash, enemy) and self:slashIsEffective(slash, enemy) and self:getDefenseSlash(enemy) <= 2 then
			target = enemy
			break
		end
	end

	if need_slash and target and isCard("Slash", card, to) then return true end
end

sgs.kexianbenxi_keep_value = {
	Peach          = 6,
	Analeptic      = 5.8,
	Jink           = 5.2,
	Duel           = 5.5,
	FireSlash      = 5.6,
	Slash          = 5.4,
	ThunderSlash   = 5.5,
	Axe            = 5,
	Blade          = 4.9,
	spear          = 4.9,
	fan            = 4.8,
	KylinBow       = 4.7,
	Halberd        = 4.6,
	MoonSpear      = 4.5,
	SPMoonSpear    = 4.5,
	DefensiveHorse = 4
}

sgs.ai_cardneed.kejiexianjibian = sgs.ai_cardneed.slash
sgs.ai_skill_invoke.kejiexianjibian = function(self, data)
	return true
end

sgs.ai_skill_choice.kejiexianjibian = function(self, choices, data)
	local items = choices:split("+")
	if table.contains(items, "benxione") then return "benxione" end
	if table.contains(items, "benxitwo") then
		if sgs.ai_skill_playerchosen.kejiexianjibian(self, self.room:getOtherPlayers(self.player)) ~= nil then
			return "benxitwo"
		end
	end
	if table.contains(items, "benxithree") then
		if sgs.ai_skill_invoke.kexianbenxi(self, sgs.QVariant()) then
			return "benxithree"
		end
	end
	return items[1]
end

sgs.ai_skill_playerchosen.kejiexianjibian = function(self, targets)
	targets = sgs.QList2Table(targets)
	for _, enemy in ipairs(self.enemies) do
		if (self:doDisCard(enemy, "h") or self:getDangerousCard(enemy) or self:getValuableCard(enemy)) and self.player:canDiscard(enemy, "h") then
			return enemy
		end
	end
	return nil
end

sgs.ai_ajustdamage_from.kejiexianjibian = function(self, from, to, card, nature)
	if from:getMark("&kejiexianjibianda-PlayClear") > 0 and card and card:isKindOf("Slash")
	then
		return 1
	end
end


--仙华佗

sgs.ai_skill_invoke.kexianwuqin = function(self, data)
	return true
end

local kexianjishi_skill = {}
kexianjishi_skill.name = "kexianjishi"
table.insert(sgs.ai_skills, kexianjishi_skill)
kexianjishi_skill.getTurnUseCard = function(self)
	if self.player:getMark("@xianjishi") == 0 then return end
	local deathplayer = {}
	for _, p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and ((p:getRole() == self.player:getRole())
				or (p:getRole() == "loyalist" and self.player:isLord())) then
			table.insert(deathplayer, p:getGeneralName())
		end
	end
	if #deathplayer == 0 then return end
	if self.player:getHandcardNum() >= 4 then
		local spade, club, heart, diamond
		for _, card in sgs.list(self.player:getHandcards()) do
			if card:getSuit() == sgs.Card_Spade then
				spade = true
			elseif card:getSuit() == sgs.Card_Club then
				club = true
			elseif card:getSuit() == sgs.Card_Heart then
				heart = true
			elseif card:getSuit() == sgs.Card_Diamond then
				diamond = true
			end
		end
		if spade and club and diamond and heart then
			return sgs.Card_Parse("#kexianjishiCard:.:")
		end
	end
end

sgs.ai_skill_use_func["#kexianjishiCard"] = function(card, use, self)
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByUseValue(cards, true)
	local need_cards = {}
	local spade, club, heart, diamond
	for _, card in sgs.list(cards) do
		if card:getSuit() == sgs.Card_Spade and not spade then
			spade = true
			table.insert(need_cards, card:getId())
		elseif card:getSuit() == sgs.Card_Club and not club then
			club = true
			table.insert(need_cards, card:getId())
		elseif card:getSuit() == sgs.Card_Heart and not heart then
			heart = true
			table.insert(need_cards, card:getId())
		elseif card:getSuit() == sgs.Card_Diamond and not diamond then
			diamond = true
			table.insert(need_cards, card:getId())
		end
	end
	if #need_cards < 4 then return end
	local greatyeyan = sgs.Card_Parse("#kexianjishiCard:" .. table.concat(need_cards, "+") .. ":")
	assert(greatyeyan)
	use.card = greatyeyan
end

sgs.ai_use_value["#kexianjishiCard"] = 8
sgs.ai_use_priority["#kexianjishiCard"] = 9.5
sgs.ai_use_priority.kexianjishiCard = 9.5
