-- 仙包隔離 AI。決策順序沿用 lua/ai/kexianbao-ai.lua。
-- 共用函式在 smart-ai-functions.lua；本檔只擴充技能名單與各技能 handler。
-- 快照沒有的旗標、拼點點數或忌雷回 unsupported，不把未知當成安全或敵人。

sgs.append_skill_list("wizard_skill", "kexianhuiyan")
sgs.append_skill_list("wizard_skill", "kejiexianhuiyan")
sgs.append_skill_list("wizard_harm_skill", "kejiexianhuiyan")
sgs.append_skill_list("double_slash_skill", "kexianfeijian")
sgs.append_skill_list("double_slash_skill", "kejiexianfeijian")

sgs.ai_cardneed = sgs.ai_cardneed or {}
sgs.ai_ajustdamage_from = sgs.ai_ajustdamage_from or {}
sgs.ai_use_value = sgs.ai_use_value or {}
sgs.ai_use_priority = sgs.ai_use_priority or {}
sgs.ai_card_intention = sgs.ai_card_intention or {}
sgs.ai_damage_reason_suppress_intention = sgs.ai_damage_reason_suppress_intention or {}
sgs.ai_suppress_intention = sgs.ai_suppress_intention or {}
sgs.ai_can_damagehp = sgs.ai_can_damagehp or {}
sgs.dynamic_value = sgs.dynamic_value or {}
sgs.dynamic_value.benefit = sgs.dynamic_value.benefit or {}

sgs.ai_damage_reason_suppress_intention.kexianhuoqi = true
sgs.ai_damage_reason_suppress_intention.kejiexianhuoqi = true
sgs.ai_suppress_intention.kejiexianaoce = true
sgs.ai_cardneed.kexianguiyi = sgs.ai_cardneed.bignumber
sgs.ai_cardneed.kejiexianjibian = sgs.ai_cardneed.slash
sgs.ai_use_value.kejiexianchanxinCard = 9
sgs.ai_use_priority.kejiexianchanxinCard = 2.61
sgs.dynamic_value.benefit.kejiexianchanxinCard = true
sgs.ai_use_value.kexianfenshenCard = 8.5
sgs.ai_use_priority.kexianfenshenCard = 9.5
sgs.ai_card_intention.kexianfenshenCard = -80
sgs.ai_use_value.kejiexianfenshenCard = 8.5
sgs.ai_use_priority.kejiexianfenshenCard = 9.5
sgs.ai_card_intention.kejiexianfenshenCard = -80
sgs.ai_use_value.kexianjishiCard = 8
sgs.ai_use_priority.kexianjishiCard = 9.5

local known = AIValue.requireKnown

local function relation_friend(self, player, key)
    return known(self:isFriend(player), key, key .. " relation is unknown")
end

local function relation_enemy(self, player, key)
    return known(self:isEnemy(player), key, key .. " relation is unknown")
end

local function choice_items(options, key)
    local items = type(options) == "table" and options.choices or nil
    if type(items) ~= "table" or #items == 0 then
        ai_unsupported(key .. " choices are missing", key)
    end
    local offered = {}
    for _, item in ipairs(items) do offered[item] = true end
    return items, offered
end

local function offered_players(self, options, key)
    if type(options) ~= "table" or options.candidates_complete ~= true or not AIValue.isList(options.players) then
        ai_unsupported(key .. " requires complete candidates", key)
    end
    local list = AIList.new({})
    for _, name in ipairs(options.players) do
        local player = self.room:findPlayerByObjectName(name, true)
        if not player then ai_unsupported(key .. " candidate is missing", key) end
        list:append(player)
    end
    return list
end

local function decline_player(options)
    if options and options.optional then return {kind = "pass"} end
    return nil
end

local function skill_use(self, skill, cards, targets)
    local action = self:getSkillAction(skill)
    if not action or not action:isValid() then return nil end
    local answer = {kind = "use_card", skill_action = action:toAnswer(), cards = cards}
    if targets then answer.targets = targets end
    return answer
end

-- 出牌候選有忌雷旗標才排除。棄牌題通常已經濾過，沒有候選就當可棄。
local function not_jilei(self, card, key)
    local candidate = self:getCardCandidate(card:getEffectiveId())
    if not candidate or type(candidate.isJilei) ~= "function" then return true end
    local banned = candidate:isJilei()
    if banned == nil then ai_unsupported(key .. " jilei state is unknown", key) end
    return not banned
end

ai_skill_invoke.xianchangetupo = function()
    return false
end

-- Original callbacks, including the otherwise redundant playerschosen call:
-- it performs sorting and relationship observations before the table comparison.
rawset(ai_skill_choice, "kexianhuoqi", nil)
rawset(ai_skill_invoke, "kexianhuoqi", nil)
rawset(ai_skill_playerschosen, "kexianhuoqi", nil)
sgs.ai_skill_invoke.kexianhuoqi = function(self, data)
    return sgs.ai_skill_choice.kexianhuoqi(self, "recover+pindian+cancel", data) ~= "cancel"
end
sgs.ai_skill_choice.kexianhuoqi = function(self, choices, data)
    if known(self:isWeak(), "kexianhuoqi") then return "recover" end
    local players = AIList.new({})
    for _, pp in ipairs(known(self.room:getAllPlayers(), "kexianhuoqi.roster")) do
        -- The common adapter preserves owner exact capabilities and records
        -- the existing lawful foreign-pair estimate, rather than private rules.
        if known(self:canPindian(pp), "kexianhuoqi.ready") then players:append(pp) end
    end
    if players:length() >= 2 and sgs.ai_skill_playerschosen.kexianhuoqi(self, players, 2, 2) ~= {} then
        return "pindian"
    end
    return "cancel"
end
sgs.ai_skill_playerschosen.kexianhuoqi = function(self, players, x, n)
    local destlist = sgs.QList2Table(players)
    self:sort(destlist, "hp")
    local tos = {}
    for _, a in ipairs(destlist) do
        for _, b in ipairs(destlist) do
            if #tos >= x then break end
            if known(self:isEnemy(a), "kexianhuoqi.relation")
                and known(self:isEnemy(b), "kexianhuoqi.relation")
                and not table.contains(tos, b)
                and known(self:canPindian(a, b), "kexianhuoqi.pair")
                and b:objectName() ~= a:objectName() then
                table.insert(tos, b)
            end
        end
    end
    return tos
end

-- Disclosed winner flags are exact; an unobserved foreign flag uses the
-- common explicit inactive prior, never a private winner-flag native query.
sgs.ai_skill_discard.kexianhuoqi = function(self, discard_num, min_num, optional, include_equip)
    local key, winner = "kexianhuoqi"
    for _, player in ipairs(known(self.room:getAlivePlayers(), key)) do
        if known(player:getStrategyFlag("kexianhuoqi_winner"), key) then winner = player; break end
    end
    if winner and (not known(self:damageIsEffective(self.player, sgs.DamageStruct_Normal, winner), key)
        or known(self:needToLoseHp(self.player, winner), key)) then return {} end
    if winner and known(self:needToLoseHp(self.player, winner), key) then return {} end
    local result, cards, peaches = {}, sgs.QList2Table(known(self.player:getHandcards(), key)), 0
    for _, card in ipairs(cards) do
        if isCard("Peach", card, self.player) then peaches = peaches + 1 end
    end
    if peaches >= 2 and known(self:getOverflow(), key) <= 0 then return {} end
    local sorted = self:sortByKeepValue(cards)
    if AIUnsupported.is(sorted) then error(sorted, 0) end
    -- Source sort is in-place; preserve its reverse/backwards-removal traversal.
    cards = sgs.reverse(cards)
    for i = #cards, 1, -1 do
        local card = cards[i]
        if not isCard("Peach", card, self.player) and not known(self.player:isJilei(card), key) then
            result[#result + 1] = card:getEffectiveId()
            table.remove(cards, i)
            if #result == 2 then break end
        end
    end
    if #result < 2 then return {} else return result end
end

local function pindian_numbers(self, key)
    local context = self:getDecisionContext()
    local pindian = type(context) == "table" and context.pindian or nil
    if type(pindian) ~= "table" then
        ai_unsupported(key .. " pindian is not projected", key)
    end
    local from, to = pindian.from, pindian.to
    if type(from) == "string" then from = self.room:findPlayerByObjectName(from, true) end
    if type(to) == "string" then to = self.room:findPlayerByObjectName(to, true) end
    if not from or not to or type(pindian.from_number) ~= "number" or type(pindian.to_number) ~= "number" then
        ai_unsupported(key .. " pindian cards are not projected", key)
    end
    return from, to, pindian.from_number, pindian.to_number
end

ai_skill_invoke.kexianyuli = function()
    return true
end

-- Full fixed source166-218; preserve callback evaluation and partial target order.
rawset(ai_skill_invoke, "kejiexianhuoqi", nil)
sgs.ai_skill_invoke.kejiexianhuoqi = function(self, data)
	return sgs.ai_skill_choice.kejiexianhuoqi(self, "recover+pindian+cancel") ~= "cancel"
end
rawset(ai_skill_choice, "kejiexianhuoqi", nil)
sgs.ai_skill_choice.kejiexianhuoqi = function(self, choices, data)
	if known(self:isWeak(), "kejiexianhuoqi.weak") then return "recover" end
	local players = AIList.new({})
	for _, pp in ipairs(known(self.room:getAllPlayers(), "kejiexianhuoqi.roster")) do
		if known(self:canPindian(pp), "kejiexianhuoqi.ready") then
			players:append(pp)
		end
	end
	if players:length() >= 2 and sgs.ai_skill_playerschosen.kejiexianhuoqi(self, players, 2, 2) ~= {} then
		return "pindian"
	end
	return "cancel"
end
rawset(ai_skill_playerschosen, "kejiexianhuoqi", nil)
sgs.ai_skill_playerschosen.kejiexianhuoqi = function(self, players, x, n)
	local destlist = sgs.QList2Table(players)
	self:sort(destlist, "hp")
	local tos = {}
	for _, a in ipairs(destlist) do
		for _, b in ipairs(destlist) do
			if #tos >= x then break end
			if known(self:isEnemy(a), "kejiexianhuoqi.relation") and known(self:isEnemy(b), "kejiexianhuoqi.relation") and not table.contains(tos, b) and known(self:canPindian(a,b), "kejiexianhuoqi.pair") and b:objectName() ~= a:objectName() then
				table.insert(tos, b)
			end
		end
	end
	if #tos < 2 then
		for _, a in ipairs(destlist) do
			for _, b in ipairs(destlist) do
				if #tos >= x then break end
				if known(self:isEnemy(a), "kejiexianhuoqi.relation") and known(self:isFriend(b), "kejiexianhuoqi.relation") and not table.contains(tos, b) and known(self:canPindian(a,b), "kejiexianhuoqi.pair") and b:objectName() ~= a:objectName() then
					table.insert(tos, b)
				end
			end
		end
	end
	if #tos < 2 then return {} end
	return tos
end

rawset(ai_skill_choice,"jienhlxloser",nil)
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


local function chanxin_slash_available(self)
    local context=self:getDecisionContext()
    local row=context and context.round22_choice
    local value
    if type(row)=="table" then value=row.chanxin_slash_available end
    if type(value)~="boolean" then ai_unsupported("source static Slash availability is not projected","kexianchanxin") end
    return value
end
rawset(ai_skill_activate,"kexianchanxin",nil)
sgs.ai_fill_skill.kexianchanxin = function(self,inclusive,request)
	if (self.player:hasUsed("#kexianchanxinCard"))
		or (chanxin_slash_available(self)) then
		return
	end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = AIList.new({})
	for _, acard in ipairs(cards) do
		if acard:isKindOf("Slash") then
			to_throw:append(acard:getEffectiveId())
		end
	end
	card_id = to_throw:at(0) --(to_throw:length()-1)
	if not card_id then
		return nil
	else
		return self:evaluateTurnSkillCard("kexianchanxin","#kexianchanxinCard",{card_id},request)
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

ai_skill_invoke.xianhuiyanfadong = function()
    return true
end

ai_skill_invoke.kejiexianhuiyan = function()
    return true
end



rawset(ai_skill_invoke,"kexianguiyi",nil)
rawset(ai_skill_playerchosen,"kexianguiyi",nil)
sgs.ai_skill_invoke.kexianguiyi = function(self, data)
	local players = AIList.new({})
	for _, p in sgs.qlist(self.room:getOtherPlayers(self.player)) do
		if known(self:canPindian(self.player,p),"kexianguiyi.canPindian") then
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
			if self:isEnemy(p) and known(self:canPindian(self.player,p),"kexianguiyi.canPindian") then
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
	end
	if point >= 10 then
		self:sort(targets, "handcard")
		for _, p in ipairs(targets) do
			if self:isEnemy(p) and known(self:canPindian(self.player,p),"kexianguiyi.canPindian") then
			return p
            end
		end
	end
	return nil
end
local function chanxin_wansha(self)
    -- Own tag holds the granted skill name; QVariant::toBool reads absent as false.
    local value=self.player:getTag("JilveWansha")
    if value==nil then return false end
    if type(value)=="boolean" then return value end
    if type(value)~="string" then ai_unsupported("owner JilveWansha is unknown","kejiexianchanxin") end
    return value~="" and value~="0" and value:lower()~="false"
end
rawset(ai_skill_activate,"kejiexianchanxin",nil)
sgs.ai_fill_skill.kejiexianchanxin=function(self,inclusive,request)
    return self:evaluateTurnSkillCard("kejiexianchanxin","#kejiexianchanxinCard",{},request)
end
sgs.ai_skill_use_func["#kejiexianchanxinCard"] = function(card, use, self)
	local unpreferedCards = {}
	local cards = sgs.QList2Table(self.player:getHandcards())

	if self.player:getHp() < 3 then
		local use_slash, keep_weapon = false, nil
		local keep_slash = chanxin_wansha(self)
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
				if use_slash_num <= known(card:getTargetModResidue(self.player),"kejiexianchanxin.residue")
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
		if not self.player:isJilei(known(self:getKnownCardById(unpreferedCards[i]),"kejiexianchanxin.material")) then
			table.insert(use_cards,
				unpreferedCards[i])
		end
	end

	if #use_cards > 0 then
		use.card = self:evaluateTurnSkillCard("kejiexianchanxin","#kejiexianchanxinCard",use_cards)
	end
end

sgs.ai_use_value["#kejiexianchanxinCard"]=9
sgs.ai_use_priority["#kejiexianchanxinCard"]=2.61
sgs.dynamic_value.benefit["#kejiexianchanxinCard"]=true

sgs.ai_cardneed.kejiexianchanxin = function(_, card)
    return card:isKindOf("Weapon") or card:isDamageCard()
end

local function discard_enemy(self, key, flags)
    if not self.enemies then ai_unsupported(key .. " enemies are unknown", key) end
    local ordered = known(self:sort(self.enemies, "defense"), key, key .. " defense order is unknown")
    for _, enemy in ipairs(ordered) do
        local nude = enemy:isNude()
        if nude == nil then ai_unsupported(key .. " nude state is unknown", key) end
        if not nude then
            local discard = self:doDisCard(enemy, flags or "he")
            if discard == nil then ai_unsupported(key .. " discard value is unknown", key) end
            local dangerous = self:getDangerousCard(enemy)
            local valuable = self:getValuableCard(enemy)
            if discard or dangerous or valuable then return enemy:objectName() end
        end
    end
    return nil
end

rawset(ai_skill_playerchosen,"kejiexianchanxinCard",nil)
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



rawset(ai_skill_invoke,"kejiexianguiyi",nil)
rawset(ai_skill_choice,"kejiexianguiyi",nil)
sgs.ai_skill_invoke.kejiexianguiyi = function(self, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then return false end
	return true
end

sgs.ai_skill_choice.kejiexianguiyi = function(self, choices, data)
	local target = data:toPlayer()
	if target and self:isFriend(target) then return "have" end
	local flag = string.format("%s_%s_%s", "visible", self.player:objectName(), target:objectName())
	for _, card in sgs.qlist(known(target:getKnownCards(),"kejiexianguiyi.known_hand")) do
		if known(card:hasFlag("visible"),"kejiexianguiyi.visibility") or known(card:hasFlag(flag),"kejiexianguiyi.visibility") then
			if card:isDamageCard() then
				return "have"
			end
		end
	end
	return "nothave"
end





ai_skill_invoke.kexianlunhui = function()
    return true
end

rawset(ai_skill_activate,"kexianfenshen",nil)
sgs.ai_fill_skill.kexianfenshen = function(self,inclusive,request)
	if (self.player:hasUsed("#kexianfenshenCard")) or (self.player:getMark("&xianzuociji") == 0) then return end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = AIList.new({})
	for _, acard in ipairs(cards) do
		to_throw:append(acard:getEffectiveId())
	end
	card_id = to_throw:at(0) --(to_throw:length()-1)
	if not card_id then
		return nil
	else
		return self:evaluateTurnSkillCard("kexianfenshen","#kexianfenshenCard",{card_id},request)
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

-- kexianfeijian category registered once at module entry.

ai_skill_invoke.kejiexianlunhui = function(self, data)
	return true
end

rawset(ai_skill_activate,"kejiexianfenshen",nil)
sgs.ai_fill_skill.kejiexianfenshen = function(self,inclusive,request)
	if (self.player:hasUsed("#kejiexianfenshenCard"))
		or (self.player:getMark("&kexianfenshen") >= 3)
		or (self.player:getMark("&jiexianzuociji") == 0) then
		return
	end
	local card_id
	local cards = self.player:getHandcards()
	cards = sgs.QList2Table(cards)
	self:sortByKeepValue(cards)
	local to_throw = AIList.new({})
	for _, acard in ipairs(cards) do
		to_throw:append(acard:getEffectiveId())
	end
	card_id = to_throw:at(0) --(to_throw:length()-1)
	if not card_id then
		return nil
	else
		return self:evaluateTurnSkillCard("kejiexianfenshen","#kejiexianfenshenCard",{card_id},request)
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

ai_skill_invoke.kejiexianfeijian = function()
    return true
end

ai_skill_playerchosen.kejiexianfeijian = function(self, options)
    local targets = offered_players(self, options, "kejiexianfeijian")
    local target = self:zeroCardSlashTarget(targets)
    if target == nil then ai_unsupported("kejiexianfeijian slash target is unknown", "kejiexianfeijian") end
    if target then return target:objectName() end
    return decline_player(options)
end

-- Source only asks for he length. This public count equals that native list
-- length without enumerating foreign hidden hand identities; keep both calls.
local function mabi_he_count(target)
    return known(target:getCardCount(),"mabi.he_count")
end
rawset(ai_skill_invoke,"kexianmabi",nil)
sgs.ai_skill_invoke.kexianmabi = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if known(target:getStrategyMark("&kexianmabimopai"),"kexianmabi.mark") > 0 then return false end
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
		if mabi_he_count(target) < 4 and mabi_he_count(target) > 1 then return true end
		return false
	end
end
ai_skill_invoke.kexianxiuzhen = function(self)
    local damage = self:getDecisionContext().damage
    local target = type(damage) == "table" and damage.from or nil
    if target and relation_friend(self, target, "kexianxiuzhen") and known(self:isWeak(target), "kexianxiuzhen") then
        return false
    end
    return true
end

sgs.ai_can_damagehp.kexianxiuzhen = function(self, from, card, to)
	if from and to:getHp() + self:getAllPeachNum() - self:ajustDamage(from, to, 1, card) > 0
		and self:canLoseHp(from, card, to)
	then
		return self:isEnemy(from)
	end
end

rawset(ai_skill_invoke,"kejiexianmabi",nil)
sgs.ai_skill_invoke.kejiexianmabi = function(self, data)
	local damage = data:toDamage()
	local target = damage.to
	if known(target:getStrategyMark("&kejiexianmabimp"),"kejiexianmabi.mark") > 0 then return false end
	if known(target:getStrategyMark("&kejiexianmabicp"),"kejiexianmabi.mark") > 0 then return false end
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
		if mabi_he_count(target) < 4 and mabi_he_count(target) > 1 then return true end
		return false
	end
end

ai_skill_invoke.kejiexianxiuzhenpd = function()
    return true
end

rawset(ai_skill_playerchosen,"kejiexianxiuzhen",nil)
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

rawset(ai_skill_playerchosen,"kejiexianxiuzhendis",nil)
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

rawset(ai_skill_choice,"kejiexianxiuzhen",nil)
sgs.ai_skill_choice.kejiexianxiuzhen = function(self, choices)
	if self.room:getLord() and known(self.player:isYourFriend(self.room:getLord()),"kejiexianxiuzhen.public_role_relation") then return self.room:getLord():getKingdom() end
	choices = choices:split(":")
	return choices[math.random(1, #choices)]
end


local function give_or_throw(self, options, key)
    local enemy = discard_enemy(self, key)
    if enemy then return enemy end
    if not self.friends_noself then ai_unsupported(key .. " friends are unknown", key) end
    for _, friend in ipairs(self.friends_noself) do
        local equips = friend:getEquips()
        if not equips then ai_unsupported(key .. " equips are unknown", key) end
        local lose = type(sgs.lose_equip_skill) == "string" and friend:hasSkills(sgs.lose_equip_skill) or false
        local armor = self:needToThrowArmor(friend)
        local discard = self:doDisCard(friend, "he")
        if armor == nil or discard == nil then ai_unsupported(key .. " friend discard is unknown", key) end
        if (lose and #equips > 0) or (armor and friend:getArmor()) or discard then
            return friend:objectName()
        end
    end
    return decline_player(options)
end

rawset(ai_skill_playerchosen,"kexianhanyan",nil)
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


ai_skill_invoke.kexianxiaocai = function()
    return true
end

rawset(ai_skill_playerchosen,"kejiexianliwei",nil)
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

rawset(ai_skill_cardchosen,"kejiexianliwei",nil)
sgs.ai_skill_cardchosen.kejiexianliwei=function(self,who,flags)
    local cards=sgs.QList2Table(known(who:getEquips(),"kejiexianliwei.equips"))
    -- The donor always returns the first equipment if one exists. Appending a
    -- hand card cannot change that prefix; no private hand/flag oracle needed.
    if #cards>0 then return cards[1] end
    local count=known(who:getHandcardNum(),"kejiexianliwei.hand_count")
    if count==0 then return nil end
    local hand=known(who:getKnownCards(),"kejiexianliwei.known_hand")
    if #hand~=count then
        if count>=3 then ai_unsupported("source first hidden hand visibility is not disclosed","kejiexianliwei.first_visible") end
        local context=self:getDecisionContext()
        local row=known(context.random_card_choices and context.random_card_choices.kejiexianliwei_first_hand,"kejiexianliwei.opaque_hand")
        if type(row)~="table" or row.source_first~=true or row.count~=count or type(row.token)~="string" or row.token=="" then
            ai_unsupported("original first hand ordinal is not authorized","kejiexianliwei.first_hand")
        end
        return {kind="answer",random_card_choice={token=row.token,index=1,avoid_wounded_enemy_silver_lion=false}}
    end
    if #hand<3 or known(hand[1]:hasFlag("visible"),"kejiexianliwei.first_visible") then table.insert(cards,hand[1]) end
    for i=1,#cards do return cards[i] end
    return nil
end

rawset(ai_skill_invoke,"kejiexianaoce",nil)
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


-- Missing foreign hidden flags remain unknown; disclosed identities alone do
-- not assert legacy visibility flags. No fabricated hidden cards are inserted.
local function benxi_visible_hand(self,player)
    local cards=known(player:getKnownCards(),"kexianbenxi.known_hand")
    -- Source uses the current player's visibility, which need not be ours.
    -- Do not silently treat another observer's private known hand as empty.
    local current=known(self.room:getCurrent(),"kexianbenxi.current_observer")
    if current:objectName()~=self.player:objectName()
        and #cards<known(player:getHandcardNum(),"kexianbenxi.hand_count") then
        ai_unsupported("source current-player visibility includes an unavailable observer domain","kexianbenxi.observer_hand")
    end
    return cards
end
local function benxi_visible_flag(card,flag)
    return known(card:hasFlag(flag),"kexianbenxi.visibility")
end
rawset(ai_skill_invoke,"kexianbenxi",nil)
rawset(ai_skill_playerchosen,"kexianbenxi",nil)
rawset(ai_skill_invoke,"kejiexianjibian",nil)
rawset(ai_skill_playerchosen,"kejiexianjibian",nil)
rawset(ai_skill_choice,"kejiexianjibian",nil)
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
	if known(from:getStrategyMark("&kexianbenxi-PlayClear"),"kexianbenxi.mark") > 0 and card and card:isKindOf("Slash")
	then
		return 1
	end
end

function sgs.ai_cardneed.kexianbenxi(to, card, self)
	local slash_num = 0
	local target
	local slash = dummyCard()

	local cards = benxi_visible_hand(self,to)
	local need_slash = true
	for _, c in sgs.qlist(cards) do
		local flag = string.format("%s_%s_%s", "visible", self.room:getCurrent():objectName(), to:objectName())
		if benxi_visible_flag(c,"visible") or benxi_visible_flag(c,flag) then
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
		if sgs.ai_skill_invoke.kexianbenxi(self, nil --[[source empty QVariant unused by kexianbenxi body]]) then
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
	if known(from:getStrategyMark("&kejiexianjibianda-PlayClear"),"kejiexianjibian.mark") > 0 and card and card:isKindOf("Slash")
	then
		return 1
	end
end


ai_skill_invoke.kexianwuqin = function()
    return true
end

rawset(ai_skill_activate,"kexianjishi",nil)
sgs.ai_fill_skill.kexianjishi = function(self,inclusive,request)
	if self.player:getMark("@xianjishi") == 0 then return end
	local deathplayer = {}
	for _, p in sgs.qlist(self.room:getPlayers()) do
		if p:isDead() and ((known(p:getRole(),"kexianjishi.dead_role") == self.player:getRole())
				or (known(p:getRole(),"kexianjishi.dead_role") == "loyalist" and self.player:isLord())) then
			table.insert(deathplayer, p:objectName()) -- Only cardinality is consumed; no hidden general identity needed.
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
			return self:evaluateTurnSkillCard("kexianjishi","#kexianjishiCard",{},request)
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
	local greatyeyan = self:evaluateTurnSkillCard("kexianjishi","#kexianjishiCard",need_cards)
	assert(greatyeyan)
	use.card = greatyeyan
end

sgs.ai_use_value["#kexianjishiCard"] = 8
sgs.ai_use_priority["#kexianjishiCard"] = 9.5
sgs.ai_use_priority.kexianjishiCard = 9.5

-- Exact owner inquiry context; source CurrentPindianStruct never grants private
-- face access. The producer only includes faces already lawful to this viewer.
local function tianbian_context(self,key)
    local context=self:getDecisionContext()
    local row=context and context.round21_choice
    if type(row)~="table" or row.tianbian_skill~=key or row.tianbian_pindian==nil or type(row.tianbian_flags)~="table" then
        ai_unsupported("Tianbian public inquiry context is incomplete",key)
    end
    return row
end
local function tianbian_pindian(self,key)
    local row=tianbian_context(self,key).tianbian_pindian
    if row==false then return nil end
    return {from_card=row.from_card and CardView.new(row.from_card) or nil,
        to_card=row.to_card and CardView.new(row.to_card) or nil}
end
local function tianbian_flag(self,player,key,suffix)
    local row=tianbian_context(self,key).tianbian_flags[player:objectName()]
    local value
    if type(row)=="table" then value=row[suffix] end
    if type(value)~="boolean" then ai_unsupported("Tianbian public flag is unknown",key..suffix) end
    return value
end
local function tianbian_selected(self,key,wire)
    if wire=="." then return wire end
    local id,target=wire:match("^#"..key.."_Card:(%d+):%->(.+)$")
    if not id then ai_unsupported("unexpected source Tianbian response",key) end
    local card=self:bindSkillCard(key,{tonumber(id)},nil,nil,"#"..key.."_Card")
    return {kind="use_card",card_spec=card:toCardSpec(),targets={target}}
end
local function kexiantianbian_policy(self, prompt)
	local targets = sgs.QList2Table(self.room:getAllPlayers())
	local pindian = tianbian_pindian(self,"kexiantianbian")
	local from, to
	for _, p in ipairs(targets) do
		if tianbian_flag(self,p,"kexiantianbian","Source") then
			from = p
		end
		if tianbian_flag(self,p,"kexiantianbian","Target") then
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
rawset(ai_skill_use,"@kexiantianbian",nil)
sgs.ai_skill_use["@kexiantianbian"] = function(self,prompt)
    return tianbian_selected(self,"kexiantianbian",kexiantianbian_policy(self,prompt))
end

local function kejiexiantianbian_policy(self, prompt)
	local targets = sgs.QList2Table(self.room:getAllPlayers())
	local pindian = tianbian_pindian(self,"kejiexiantianbian")
	local from, to
	for _, p in ipairs(targets) do
		if tianbian_flag(self,p,"kejiexiantianbian","Source") then
			from = p
		end
		if tianbian_flag(self,p,"kejiexiantianbian","Target") then
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
rawset(ai_skill_use,"@kejiexiantianbian",nil)
sgs.ai_skill_use["@kejiexiantianbian"] = function(self,prompt)
    return tianbian_selected(self,"kejiexiantianbian",kejiexiantianbian_policy(self,prompt))
end

local function huiyan_context(self,key)
    local context=self:getDecisionContext()
    local row=context and context.round22_choice and context.round22_choice.huiyan
    if type(row)~="table" or row.skill~=key then ai_unsupported("Huiyan inquiry context is unknown",key) end
    return row
end
local function huiyan_judge(self,key)
    local row=huiyan_context(self,key).judge
    if row==false then return nil end
    if type(row)~="table" then ai_unsupported("Huiyan named judge is not projected",key) end
    local judge={};for k,v in pairs(row) do judge[k]=v end
    judge.who=known(self.room:findPlayerByObjectName(row.who,true),key)
    judge.card=row.card and CardView.new(row.card) or nil
    return judge
end
local function huiyan_card(self,key,id,fallback)
    if not fallback then return known(self:getChoiceCard(id),key) end
    local rows=huiyan_context(self,key).index_cards
    local row
    if type(rows)=="table" then row=rows[tostring(id)] end
    if row==false then return nil end
    if type(row)~="table" then ai_unsupported("source Huiyan fallback index names an undisclosed card",key..":"..tostring(id)) end
    return CardView.new(row)
end
rawset(ai_skill_askforag,"kexianhuiyan",nil)
sgs.ai_skill_askforag.kexianhuiyan = function(self, card_ids)
	local cards = {}
	local cards_ids = sgs.QList2Table(card_ids)                  -- 获得手牌的表
	for _,card_id in ipairs(cards_ids) do
		table.insert(cards, huiyan_card(self,"kexianhuiyan",card_id,false))
	end
	local judge = huiyan_judge(self,"kexianhuiyan") -- 获得判定结构体
	local card_id = self:getRetrialCardId(cards, judge)     -- 从所有手牌中寻找可供改判的牌
	if card_id ~= -1 then
		return card_id                                      -- 若找到则改判
	end

	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, huiyan_card(self,"kexianhuiyan",card_id,true))
	end
	self:sortByUseValue(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end


rawset(ai_skill_askforag,"kejiexianhuiyan",nil)
sgs.ai_skill_askforag.kejiexianhuiyan = function(self, card_ids)
	local cards = {}
	local judge = huiyan_judge(self,"kejiexianhuiyan") -- 获得判定结构体
	local cards_ids = sgs.QList2Table(card_ids)                  -- 获得手牌的表
	for _,card_id in ipairs(cards_ids) do
		table.insert(cards, huiyan_card(self,"kejiexianhuiyan",card_id,false))
	end
	local card_id = self:getRetrialCardId(cards, judge)      -- 从所有手牌中寻找可供改判的牌
	if card_id ~= -1 then
		return card_id                                       -- 若找到则改判
	end

	local to_obtain = {}
	for card_id in ipairs(card_ids) do
		table.insert(to_obtain, huiyan_card(self,"kejiexianhuiyan",card_id,true))
	end
	self:sortByUseValue(to_obtain, true)
	return to_obtain[1]:getEffectiveId()
end
